{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-02 19:48:16	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JA2 - Contract edit
# Purpose - Scan existing contracts - TO edit.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 


MAIN 

	#Initial UI Init
	CALL setModuleId("JA2") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL contractscan() 

END MAIN 


FUNCTION contractscan() 

	DEFINE fv_del_flag SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE scrn SMALLINT 
	OPEN WINDOW wja06 with FORM "JA06" -- alch kd-747 
	CALL winDecoration_j("JA06") -- alch kd-747 

	WHILE true 
		CLEAR FORM 

		LET msgresp = kandoomsg("A",1001,"") 
		# Enter selection - Esc TO search

		CONSTRUCT BY NAME where_part ON 
		contracthead.contract_code, 
		contracthead.cust_code, 
		contracthead.status_code, 
		contracthead.desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","JA2","const-contract_code-3") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET query_text = "SELECT * FROM contracthead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",where_part clipped, " ", 
		"ORDER BY contract_code" 

		PREPARE s_contracthead FROM query_text 

		DECLARE c_contracthead CURSOR FOR s_contracthead 
		LET idx = 0 

		FOREACH c_contracthead INTO pr_contracthead.* 
			LET idx = idx + 1 
			LET pa_contracthead[idx].contract_code = 
			pr_contracthead.contract_code 
			LET pa_contracthead[idx].cust_code = 
			pr_contracthead.cust_code 
			LET pa_contracthead[idx].status_code = 
			pr_contracthead.status_code 
			LET pa_contracthead[idx].desc_text = 
			pr_contracthead.desc_text 

			IF idx = 500 THEN 
				LET msgresp = kandoomsg("A",3511,"500") 
				# First 500 contracts selected only
				EXIT FOREACH 
			END IF 

		END FOREACH 
		CALL set_count(idx) 

		IF idx = 0 THEN 
			LET msgresp = kandoomsg("A",3512,"") 
			# No contracts satisfied the selection criteria
			CONTINUE WHILE 
		END IF 

		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT WHILE 
		END IF 

		WHILE true 
			LET fv_del_flag = true 
			LET msgresp = kandoomsg("A",1010,"") 
			# RETURN on line TO edit - F2 TO delete

			# DISPLAY ARRAY of contracts

			INPUT ARRAY pa_contracthead WITHOUT DEFAULTS FROM sr_contracthead.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","JA2","input-pa_contracthead-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE ROW 
					LET idx = arr_curr() 
					LET scrn = scr_line() 
					IF arr_curr() > arr_count() THEN 
						LET msgresp = kandoomsg("A",9001,"") 
						# There are no more rows in the direction you are going
					END IF 

				BEFORE FIELD cust_code 
					IF pa_contracthead[idx].contract_code IS NULL THEN 
						NEXT FIELD contract_code 
					ELSE 
						LET pr_contracthead.contract_code = 
						pa_contracthead[idx].contract_code 
						LET pr_contracthead.cust_code = 
						pa_contracthead[idx].cust_code 
						LET pv_idx_hold = idx 
						LET pv_add = false 
						CALL contracthead() 

						DISPLAY pa_contracthead[idx].status_code TO 
						sr_contracthead[scrn].status_code 
						DISPLAY pa_contracthead[idx].desc_text TO 
						sr_contracthead[scrn].desc_text 
						NEXT FIELD contract_code 
					END IF 

				BEFORE DELETE 
					SELECT * 
					INTO pr_contracthead.* 
					FROM contracthead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pa_contracthead[idx].contract_code 

					IF pr_contracthead.status_code != "C" THEN 
						LET msgresp = kandoomsg("A",3544,"") 
						# Contract IS NOT Complete - cannot be deleted
						LET fv_del_flag = false 
						EXIT INPUT 
					END IF 

					LET msgresp = kandoomsg("A",3545,"") 
					# Confirmation TO delete all header, invoice, AND
					# detail data FOR contract ? Y/N

					IF msgresp = "N" THEN 
						LET fv_del_flag = false 
						EXIT INPUT 
					END IF 

					IF NOT delete_contract(idx) THEN 
						LET fv_del_flag = false 
						EXIT INPUT 
					END IF 

				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 

			IF NOT fv_del_flag THEN 
				CONTINUE WHILE 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW wja06 
	RETURN 

END FUNCTION 


FUNCTION delete_contract(idx) 

	DEFINE idx SMALLINT 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message,status) 
	IF err_continue != "Y" THEN 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		# delete contracthead

		LET err_message = "JA2 - Contracthead Deletion Failed" 
		DELETE FROM contracthead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pa_contracthead[idx].contract_code 

		# delete invoicedate

		LET err_message = "JA2 - Contractdate Deletion Failed" 
		DELETE FROM contractdate 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pa_contracthead[idx].contract_code 

		# delete contractdetl

		LET err_message = "JA2 - Contractdetl Deletion Failed" 
		DELETE FROM contractdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pa_contracthead[idx].contract_code 

	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 

END FUNCTION 
