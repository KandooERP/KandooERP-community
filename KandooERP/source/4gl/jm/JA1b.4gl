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
# \brief module - JA1b - Contract add
# Purpose - FUNCTION TO Write Contract details TO Tables :
#           Contracthead , Contractdetl , Contractdate
#           FUNCTION TO INITIALIZE program variables.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 


FUNCTION write_contract() 

	DEFINE fv_line_num LIKE contractdetl.line_num, 
	fv_next_num LIKE nextnumber.next_num, 
	pr_position_num LIKE nextnumber.next_num, 
	pr_acct_code LIKE invoicehead.acct_override_code, 
	pr_nextnumber RECORD LIKE nextnumber.*, 
	pr_structure RECORD LIKE structure.*, 
	pr_nextnum_text CHAR(8), 
	pr_flex_code LIKE invoicehead.acct_override_code, 
	prefix LIKE invoicehead.acct_override_code, 
	pa_start_num array[3] OF INTEGER, 
	i,x,y SMALLINT 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message,status) 
	IF err_continue != "Y" THEN 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		# UPDATE contracthead

		LET pr_contracthead.contract_value_amt = pv_contract_total 

		IF pv_add THEN 
			# Check numbering parameters have been SET up
			IF pr_jmparms.nextcontract_num < 1 
			OR pr_jmparms.nextcontract_num > 3 THEN 

				LET msgresp = kandoomsg("A",7511,"") 
				LET pv_finish_add = true 
				RETURN true 
			END IF 
			IF pr_jmparms.nextcontract_num = 1 THEN 
				LET err_message = "JA1 - Nextnumber SELECT Failed" 

				SELECT next_num 
				INTO fv_next_num 
				FROM nextnumber 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_type_ind = TRAN_TYPE_CONTRACT_CON 
				AND flex_code = "NEXTNUMBER" 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("A",7502,"") 
					# MESSAGE "Cannot find next sequential contract code"
					LET pv_finish_add = true 
					RETURN true 
				END IF 

				IF fv_next_num > 2000000000 THEN 
					LET msgresp = kandoomsg("A",7504,"") 
					# MESSAGE "Next sequential contract code exceeds maximum value"
					LET pv_finish_add = true 
					RETURN true 
				ELSE 
					LET pr_contracthead.contract_code = fv_next_num 
				END IF 

				LET err_message = "JA1 - Contracthead SELECT Failed" 

				SELECT contract_code 
				FROM contracthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND contract_code = pr_contracthead.contract_code 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("A",7503,"") 
					# MESSAGE "Next sequential contract code already exists"
					LET pv_finish_add = true 
					RETURN true 
				END IF 

				LET err_message = "JA1 - Nextnumber Update Failed" 
				UPDATE nextnumber 
				SET next_num = pr_contracthead.contract_code + 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_type_ind = TRAN_TYPE_CONTRACT_CON 
				AND flex_code = "NEXTNUMBER" 
			END IF 

			IF pr_jmparms.nextcontract_num = 2 THEN 
				LET err_message = "JA1 - Nextnumber SELECT Failed" 

				SELECT next_num 
				INTO pr_position_num 
				FROM nextnumber 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND flex_code = "POSITIONS" 
				AND tran_type_ind = TRAN_TYPE_CONTRACT_CON 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("A",7502,"") 
					# MESSAGE "Cannot find next sequential contract code"
					LET pv_finish_add = true 
					RETURN true 
				END IF 
				FOR x = 1 TO pv_dtllne_cnt 
					IF pa_contractdetl[x].type_code = "J" THEN 
						LET pr_acct_code = pa_contractdetl[x].revenue_acct_code 
						EXIT FOR 
					END IF 
				END FOR 

				IF pr_acct_code IS NULL THEN 
					FOR x = 1 TO pv_dtllne_cnt 
						CASE pa_contractdetl[x].type_code 
							WHEN "J" 
								CONTINUE FOR 
							WHEN "I" 
								LET pr_acct_code = pa_contractdetl[x].acct_mask 
								EXIT FOR 
							WHEN "G" 
								LET pr_acct_code = 
								pa_contractdetl[x].revenue_acct_code 
								EXIT FOR 
						END CASE 
					END FOR 
				END IF 

				LET idx = 1 
				LET pr_position_num = 0 - pr_position_num 

				FOR i = 2 TO 0 step -1 
					LET pa_start_num[idx] = pr_position_num/(100 ** i) 
					IF pa_start_num[idx] > 0 THEN 
						LET err_message = "JA1 - Structure SELECT Failed" 

						SELECT * 
						INTO pr_structure.* 
						FROM structure 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND start_num = pa_start_num[idx] 
						AND type_ind = "S" 

						IF sqlca.sqlcode = 0 THEN 
							LET x = pr_structure.start_num 
							LET y = pr_structure.length_num 
							LET prefix = prefix clipped, pr_acct_code[x,x+y-1] 
							LET pr_flex_code[x,x+y-1] = pr_acct_code[x,x+y-1] 
							LET idx = idx + 1 
						END IF 
					END IF 

					LET pr_position_num = pr_position_num mod(100 ** i) 
				END FOR 

				LET err_message = "JA1 - Nextnumber SELECT Failed" 

				DECLARE c0_nextnum CURSOR FOR 
				SELECT * 
				FROM nextnumber 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_type_ind = TRAN_TYPE_CONTRACT_CON 
				AND flex_code = pr_flex_code 
				FOR UPDATE 

				OPEN c0_nextnum 
				FETCH c0_nextnum INTO pr_nextnumber.* 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("A",7502,"") 
					# MESSAGE "Cannot find next sequential contract code"
					LET pv_finish_add = true 
					RETURN true 
				END IF 

				LET pr_nextnum_text = pr_nextnumber.next_num USING "<<<<<<<<" 
				LET x = length(prefix) 
				LET y = length(pr_nextnum_text) 
				IF x + y > 8 THEN 
					LET msgresp = kandoomsg("A",7504,"") 
					# MESSAGE "Next sequential contract code exceeds maximum value"
					LET pv_finish_add = true 
					RETURN true 
				END IF 

				LET pr_nextnum_text = pr_nextnumber.next_num USING "&&&&&&&&" 
				LET pr_nextnum_text[1,x] = prefix 
				LET pr_contracthead.contract_code = pr_nextnum_text 

				LET err_message = "JA1 - Contracthead SELECT Failed" 

				SELECT contract_code 
				FROM contracthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND contract_code = pr_contracthead.contract_code 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("A",7503,"") 
					# MESSAGE "Next sequential contract code already exists"
					LET pv_finish_add = true 
					RETURN true 
				END IF 

				LET err_message = "JA1 - Nextnumber Update Failed" 

				UPDATE nextnumber 
				SET next_num = pr_nextnumber.next_num + 1 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tran_type_ind = TRAN_TYPE_CONTRACT_CON 
				AND flex_code = pr_flex_code 
			END IF 

			LET err_message = "JA1 - Contracthead Addition Failed" 
			INSERT INTO contracthead VALUES (pr_contracthead.*) 
		ELSE 
			LET err_message = "JA2 - Contracthead Update Failed" 

			UPDATE contracthead 
			SET * = pr_contracthead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_contracthead.contract_code 
			AND cust_code = pr_contracthead.cust_code 
		END IF 

		# UPDATE invoicedate

		IF NOT pv_add THEN 
			LET err_message = "JA2 - Contractdate Update Failed" 

			DELETE FROM contractdate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_contracthead.contract_code 
		END IF 

		LET err_message = "JA1/2 - Contractdate Addition Failed" 

		FOR idx = 1 TO pv_invdte_cnt 
			IF pa_contractdate[idx].invoice_date IS NOT NULL THEN 
				LET pa_contractdate[idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pa_contractdate[idx].contract_code = 
				pr_contracthead.contract_code 
				IF pa_contractdate[idx].inv_num = 0 THEN 
					LET pa_contractdate[idx].inv_num = NULL 
				END IF 
				INSERT INTO contractdate VALUES (pa_contractdate[idx].*) 
			END IF 
		END FOR 

		# UPDATE contractdetl

		IF NOT pv_add THEN 
			LET err_message = "JA1/2 - Contractdetl Deletion Failed" 

			DELETE FROM contractdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = pr_contracthead.contract_code 
			AND cust_code = pr_contracthead.cust_code 
		END IF 

		LET err_message = "JA1/2 - Contractdetl Addition Failed" 
		LET fv_line_num = 0 

		FOR idx = 1 TO pv_dtllne_cnt 
			IF pv_add AND (pr_jmparms.nextcontract_num = 1 OR 
			pr_jmparms.nextcontract_num = 2) THEN 
				LET pa_contractdetl[idx].contract_code = 
				pr_contracthead.contract_code 
			END IF 
			LET fv_line_num = fv_line_num + 1 
			LET pa_contractdetl[idx].line_num = fv_line_num 
			IF pa_contractdetl[idx].status_code IS NULL THEN 
				LET pa_contractdetl[idx].status_code = "A" 
			END IF 
			INSERT INTO contractdetl VALUES (pa_contractdetl[idx].*) 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 

	IF pv_add AND (pr_jmparms.nextcontract_num = 1 OR 
	pr_jmparms.nextcontract_num = 2) THEN 
		#        OPEN WINDOW w_info AT 10,15 with 5 rows, 49 columns
		#            attribute (border, white)      -- alch KD-747
		DISPLAY " Contract ", pr_contracthead.contract_code clipped, 
		" has been added successfully" at 4,1 
		MENU "Contract Add" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","JA1b","menu-contract_add-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Continue" "Add another contract" 
				EXIT MENU 
			COMMAND "Exit" "Exit FROM this program" 
				LET pv_finish_add = true 
				EXIT MENU 
			COMMAND KEY (interrupt) 
				LET pv_finish_add = true 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 

		#    CLOSE WINDOW w_info      -- alch KD-747
	END IF 

	RETURN true 

END FUNCTION 


FUNCTION init_contract() 

	IF NOT pv_add THEN 
		LET pa_contracthead[pv_idx_hold].status_code = 
		pr_contracthead.status_code 
		LET pa_contracthead[pv_idx_hold].desc_text = 
		pr_contracthead.desc_text 
	END IF 

	INITIALIZE pr_contracthead.* TO NULL 
	INITIALIZE pr_contractdetl.* TO NULL 
	INITIALIZE pr_contractdate.* TO NULL 
	INITIALIZE pr_customer.* TO NULL 
	INITIALIZE pa_dates TO NULL 
	INITIALIZE pa_contractdate TO NULL 
	INITIALIZE pa_details TO NULL 
	INITIALIZE pa_contractdetl TO NULL 

END FUNCTION 
