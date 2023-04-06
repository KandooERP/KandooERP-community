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

	Source code beautified by beautify.pl on 2020-01-02 19:48:17	$Id: $
}




# Purpose - Scan existing contracts
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA3_GLOBALS.4gl" 


MAIN 
	#Initial UI Init
	CALL setModuleId("JA4") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL contractscan() 

END MAIN 


FUNCTION contractscan() 
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
				CALL publish_toolbar("kandoo","JA4","const-contract_code-1") -- alch kd-506 
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
			EXIT WHILE 
		END IF 

		# DISPLAY ARRAY of contracts

		LET msgresp = kandoomsg("A",1551,"") 
		# Message "RETURN TO view - DEL TO EXIT"


		DISPLAY ARRAY pa_contracthead TO sr_contracthead.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","JA4","display-arr-contracthead") -- alch kd-506

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET idx = arr_curr() 

				LET pr_contracthead.contract_code = 
				pa_contracthead[idx].contract_code 
				LET pr_contracthead.cust_code = 
				pa_contracthead[idx].cust_code 
				CALL contractdisp(0) 


			ON KEY (control-w) 
				CALL kandoohelp("") 
		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = 0 
			LET quit_flag = 0 
		END IF 
	END WHILE 

	CLOSE WINDOW wja06 

END FUNCTION 
