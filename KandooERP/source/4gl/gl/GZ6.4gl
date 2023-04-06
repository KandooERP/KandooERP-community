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
###########################################################################
# Bank Account Details Setup G134
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_rec_currency RECORD LIKE currency.* 
	DEFINE glob_rec_s_bank RECORD LIKE bank.* 
	#DEFINE glob_rec_t_bank RECORD LIKE bank.* #not used ?
	DEFINE glob_rec_banktype RECORD LIKE banktype.* 
	DEFINE glob_rec_bic RECORD LIKE bic.* 
	DEFINE glob_arr_rec_bank DYNAMIC ARRAY OF RECORD #array[150] OF 
		bank_code LIKE bank.bank_code, 
		name_acct_text LIKE bank.name_acct_text, 
		acct_code LIKE bank.acct_code 
	END RECORD 
	DEFINE glob_counter SMALLINT 
	DEFINE glob_idx SMALLINT 
	--DEFINE glob_id_flag SMALLINT 
	--DEFINE glob_cnt SMALLINT 
	--DEFINE glob_err_flag SMALLINT 

	--DEFINE glob_ans CHAR(2) 
	DEFINE glob_domore CHAR(1) 

END GLOBALS 

##############################################################
# MAIN
#
# \file
# \brief module - GZ6
# Purpose - Adds bank accounts TO the system
#
# WOW ! 1400 lines of code without a single function parameter or return... everything global.. I'm sooo impressed xxx
##############################################################
MAIN 

	CALL setModuleId("GZ6") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPTIONS DELETE KEY f36 

	LET glob_domore = "Y" --what the f... great WHILE control done BY a xxxx 

	WHILE glob_domore = "Y" 
		CALL doit() 
		CLOSE WINDOW G135 
	END WHILE 

END MAIN 
##############################################################
# END MAIN
##############################################################


##############################################################
# FUNCTION doit()
#
#
##############################################################
FUNCTION doit() 
	DEFINE l_answer CHAR(1) 
	DEFINE l_count SMALLINT 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DECLARE bank_curs CURSOR FOR 
	SELECT * INTO glob_rec_bank.* FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY bank_code 

	LET glob_idx = 0 
	FOREACH bank_curs 
		LET glob_idx = glob_idx + 1 
		LET glob_arr_rec_bank[glob_idx].bank_code = glob_rec_bank.bank_code 
		LET glob_arr_rec_bank[glob_idx].name_acct_text = glob_rec_bank.name_acct_text 
		LET glob_arr_rec_bank[glob_idx].acct_code = glob_rec_bank.acct_code 
		#      IF glob_idx > 130 THEN
		#         ERROR kandoomsg2("U",6100,glob_idx)
		#         #6100 First glob_idx MESSAGEs selected.
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,glob_idx) #9113 glob_idx records selected
	CALL set_count (glob_idx) 

	OPEN WINDOW G135 with FORM "G135" 
	CALL windecoration_g("G135") 

	ERROR kandoomsg2("U",1003,"") 

	########################
	DISPLAY ARRAY glob_arr_rec_bank TO sr_bank.* ATTRIBUTE(UNBUFFERED) 
	#INPUT ARRAY glob_arr_rec_bank WITHOUT DEFAULTS FROM sr_bank.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","GZ6","bankList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#ON ACTION/KEY
		ON ACTION ("ACCEPT","EDIT") # was BEFORE FIELD name_acct_text 

			IF glob_arr_rec_bank[glob_idx].bank_code IS NOT NULL THEN 
				CALL changor() 
				LET glob_arr_rec_bank[glob_idx].bank_code = glob_rec_bank.bank_code 
				LET glob_arr_rec_bank[glob_idx].name_acct_text = glob_rec_bank.name_acct_text 
				LET glob_arr_rec_bank[glob_idx].acct_code = glob_rec_bank.acct_code 
				#NEXT FIELD bank_code
			END IF 

		ON ACTION "DELETE" --ON KEY (F2) --delete 
			IF glob_arr_rec_bank[glob_idx].bank_code IS NOT NULL THEN 
				--CALL gl_check_del() 
				CALL GZ6_gl_check_del(glob_arr_rec_bank[glob_idx].bank_code, glob_arr_rec_bank[glob_idx].acct_code)
			END IF 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			#LET scrn = scr_line()
			IF glob_arr_rec_bank[glob_idx].bank_code IS NOT NULL THEN 
				LET glob_rec_bank.bank_code = glob_arr_rec_bank[glob_idx].bank_code 
				LET glob_rec_bank.name_acct_text = glob_arr_rec_bank[glob_idx].name_acct_text 
				LET glob_rec_bank.acct_code = glob_arr_rec_bank[glob_idx].acct_code 
			END IF 

		ON ACTION "ADD" 
			CALL addor() 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				LET glob_arr_rec_bank[glob_idx].bank_code = glob_rec_bank.bank_code 
				LET glob_arr_rec_bank[glob_idx].name_acct_text = glob_rec_bank.name_acct_text 
				LET glob_arr_rec_bank[glob_idx].acct_code = glob_rec_bank.acct_code 
				#DISPLAY glob_arr_rec_bank[glob_idx].* TO sr_bank[scrn].*
			END IF 

			#    BEFORE INSERT
			#        LET l_count = arr_count()
			#        CALL addor()
			#        IF int_flag OR quit_flag  THEN
			#           FOR i = glob_idx TO l_count
			#               LET glob_arr_rec_bank[i].* = glob_arr_rec_bank[i+1].*
			#           END FOR
			#           INITIALIZE glob_arr_rec_bank[i+1].* TO NULL
			#           LET j = glob_idx
			#           #FOR i = scrn TO 10
			#           #   DISPLAY glob_arr_rec_bank[j].* TO sr_bank[i].*
			#           #
			#           #   LET j = j + 1
			#           #END FOR
			#           LET int_flag = 0
			#           LET quit_flag = 0
			#        ELSE
			#           LET glob_arr_rec_bank[glob_idx].bank_code = glob_rec_bank.bank_code
			#           LET glob_arr_rec_bank[glob_idx].name_acct_text = glob_rec_bank.name_acct_text
			#           LET glob_arr_rec_bank[glob_idx].acct_code = glob_rec_bank.acct_code
			#           #DISPLAY glob_arr_rec_bank[glob_idx].* TO sr_bank[scrn].*
			#
			#        END IF

			#     AFTER ROW
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF glob_arr_rec_bank[glob_idx+1].bank_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("U",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD bank_code
			#            END IF
			#         END IF
			#        #DISPLAY glob_arr_rec_bank[glob_idx].* TO sr_bank[scrn].*

		AFTER DISPLAY 
			IF int_flag != 0 OR	quit_flag != 0 THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT PROGRAM 
			END IF 

	END DISPLAY 

END FUNCTION 
##############################################################
# END FUNCTION doit()
##############################################################


##############################################################
# FUNCTION addor()
#
#
##############################################################
FUNCTION addor() 
	DEFINE l_next_ref_num LIKE bank.next_eft_ref_num 
	DEFINE l_next_run_num LIKE bank.next_eft_run_num 
	DEFINE l_next_cheq_run_num LIKE bank.next_cheq_run_num 
	DEFINE l_max INTEGER 
	DEFINE l_winds_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW ba_wind with FORM "G134" 
	CALL windecoration_g("G134") 

	MESSAGE kandoomsg2("A",1036,"")	#1036 Enter Banking Details; OK TO Continue.
	
	INITIALIZE glob_rec_bank.* TO NULL 
	INITIALIZE glob_rec_banktype.* TO NULL 
	INITIALIZE glob_rec_bic .* TO NULL 

	LET glob_rec_bank.next_cheque_num = 1 
	LET glob_rec_bank.next_cheq_run_num = 1 
	LET glob_rec_bank.next_eft_ref_num = 1 
	LET glob_rec_bank.next_eft_run_num = 1 
	LET glob_rec_bank.ext_file_ind = "0" 

	DISPLAY BY NAME 
		glob_rec_bank.bank_code, 
		glob_rec_bank.currency_code, 
		glob_rec_bank.name_acct_text, 
		glob_rec_bank.acct_code, 
		glob_rec_bank.type_code, 
		glob_rec_banktype.type_text, 
		glob_rec_bank.remit_text, 
		glob_rec_bank.user_text, 
		glob_rec_bank.eft_rpt_ind, 
		glob_rec_bank.next_eft_run_num, 
		glob_rec_bank.next_eft_ref_num, 
		glob_rec_bank.ext_file_ind, 
		glob_rec_bank.ext_path_text, 
		glob_rec_bank.ext_file_text, 
		glob_rec_bank.bic_code, 
		glob_rec_bic .desc_text, 
		glob_rec_bank.next_cheque_num, 
		glob_rec_bank.iban, 
		glob_rec_bank.sheet_num, 
		glob_rec_bank.state_bal_amt 

	INPUT BY NAME 
		glob_rec_bank.bank_code, 
		glob_rec_bank.currency_code, 
		glob_rec_bank.name_acct_text, 
		glob_rec_bank.acct_code, 
		glob_rec_bank.type_code, 
		glob_rec_bank.remit_text, 
		glob_rec_bank.user_text, 
		glob_rec_bank.eft_rpt_ind, 
		glob_rec_bank.next_cheque_num, 
		glob_rec_bank.next_cheq_run_num, 
		glob_rec_bank.next_eft_ref_num, 
		glob_rec_bank.next_eft_run_num, 
		glob_rec_bank.ext_file_ind, 
		glob_rec_bank.ext_path_text, 
		glob_rec_bank.ext_file_text, 
		glob_rec_bank.bic_code, 
		glob_rec_bank.iban, 
		glob_rec_bank.sheet_num, 
		glob_rec_bank.state_bal_amt WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ6","bankNew") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.acct_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.acct_code 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD acct_code 


		ON ACTION "LOOKUP" infield (currency_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.currency_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.currency_code 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD currency_code 

		ON ACTION "LOOKUP" infield (type_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_banktype() 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.type_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.type_code 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD type_code 

		ON ACTION "LOOKUP" infield (bic_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_bic() 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.bic_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.bic_code 
			END IF 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD bic_code 


			# Bank code must be unique
		AFTER FIELD bank_code 
			IF glob_rec_bank.bank_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD bank_code 
			END IF 

			SELECT count(*) INTO glob_counter FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			IF glob_counter > 0 THEN 
				ERROR kandoomsg2("U",9104,"")	#9104 This RECORD already exists
				NEXT FIELD bank_code 
			END IF 

		AFTER FIELD currency_code 
			IF glob_rec_bank.currency_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD currency_code 
			END IF 
			SELECT * INTO glob_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_bank.currency_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"")#9105 RECORD NOT found; Try Window.
				NEXT FIELD currency_code 
			END IF 

		AFTER FIELD acct_code 
			SELECT count(*) INTO glob_counter FROM bank 
			WHERE acct_code = glob_rec_bank.acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF glob_counter > 0 THEN 
				ERROR kandoomsg2("G",9121,"") #9121 "Bank Account already exists FOR this account "
				NEXT FIELD acct_code 
			END IF 
			
			SELECT count(*) INTO glob_counter FROM coa 
			WHERE acct_code = glob_rec_bank.acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_counter = 0 THEN 
				ERROR kandoomsg2("U",9105,"")#9105 RECORD NOT found; Try Window.
				NEXT FIELD acct_code 
			END IF 
			
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_bank.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK,"Y") THEN 
				NEXT FIELD acct_code 
			END IF 

		AFTER FIELD type_code 
			IF glob_rec_bank.type_code IS NULL THEN 
				ERROR kandoomsg2("G",9164,"")	# 9164 Bank Type must NOT be NULL
				NEXT FIELD type_code 
			END IF 
			
			SELECT * 
			INTO glob_rec_banktype.* 
			FROM banktype 
			WHERE type_code = glob_rec_bank.type_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9179,"") 	# 9179 Bank Type NOT found - Try Window
				NEXT FIELD type_code 
			END IF 
			
			DISPLAY BY NAME glob_rec_banktype.type_text 


		AFTER FIELD eft_rpt_ind 
			IF glob_rec_bank.eft_rpt_ind != 0 
			AND glob_rec_bank.eft_rpt_ind != 1 
			AND glob_rec_bank.eft_rpt_ind != 2 THEN 
				ERROR kandoomsg2("G",9185,"")	#9185 Cleansing Report Indicator must be 0, 1, OR 2
				NEXT FIELD eft_rpt_ind 
			END IF 

		AFTER FIELD next_cheque_num 
			IF glob_rec_bank.next_cheque_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD next_cheque_num 
			END IF 
			
			IF glob_rec_bank.next_cheque_num < 1 THEN 
				ERROR kandoomsg2("U",9907,"1")	#9907 Value must be greater than OR equal TO 1.
				NEXT FIELD next_cheque_num 
			END IF 
			
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			AND cheq_code = glob_rec_bank.next_cheque_num 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("P",9010,glob_rec_bank.next_cheque_num)		#9010 Cheque number already issued
				NEXT FIELD next_cheque_num 
			END IF 

		BEFORE FIELD next_cheq_run_num 
			LET l_next_cheq_run_num = glob_rec_bank.next_cheq_run_num 
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 

		AFTER FIELD next_cheq_run_num 
			IF glob_rec_bank.next_cheq_run_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	# 9102 Value must be entered.
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 
			IF glob_rec_bank.next_cheq_run_num < 1 THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)	#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 
			
			# eft_run_num IS used TO store next cheque run with the pay_meth_ind
			# sorting out WHERE it came FROM
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 
			IF l_max >= glob_rec_bank.next_cheq_run_num THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)		#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 

		BEFORE FIELD next_eft_ref_num 
			LET l_next_ref_num = glob_rec_bank.next_eft_ref_num 

		AFTER FIELD next_eft_ref_num 
			IF glob_rec_bank.next_eft_ref_num IS NULL THEN 
				ERROR kandoomsg2("G",9180,"") 			# 9180 The next EFT payment number must be entered
				LET glob_rec_bank.next_eft_ref_num = l_next_ref_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_ref_num 

				NEXT FIELD next_eft_ref_num 
			END IF 
			IF glob_rec_bank.next_eft_ref_num < 1 THEN 
				ERROR kandoomsg2("U",9907,"1")				#9907 Value must be greater than OR equal TO 1.
				NEXT FIELD next_eft_ref_num 
			END IF 
			
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			AND cheq_code = glob_rec_bank.next_eft_ref_num 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("P",9010,glob_rec_bank.next_eft_ref_num)			#9010 Cheque number already issued
				LET glob_rec_bank.next_eft_ref_num = l_next_ref_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_ref_num 

				NEXT FIELD next_eft_ref_num 
			END IF 

		BEFORE FIELD next_eft_run_num 
			LET l_next_run_num = glob_rec_bank.next_eft_run_num 
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 

		AFTER FIELD next_eft_run_num 
			IF glob_rec_bank.next_eft_run_num IS NULL THEN 
				ERROR kandoomsg2("G",9182,"") 			# 9182 The next EFT payment run number must be entered
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 
			IF glob_rec_bank.next_eft_run_num < 1 THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)			#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 
			
			IF l_max >= glob_rec_bank.next_eft_run_num THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)			# 9907 The next EFT payment run number must greater than older ones
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 

		AFTER FIELD ext_file_text 
			IF glob_rec_bank.ext_path_text IS NOT NULL	OR glob_rec_bank.ext_file_text IS NOT NULL THEN 
				IF glob_rec_bank.ext_file_ind = "0" THEN 
					ERROR kandoomsg2("G",6001,"") 			#6001 " WARNING: External payments NOT selected - file details NOT required"
				END IF 
				
				IF glob_rec_bank.ext_file_ind != "0" AND	(glob_rec_bank.ext_path_text IS NULL 
				OR glob_rec_bank.ext_file_text IS null) THEN 
					ERROR kandoomsg2("G",9537,"") 				#9162 " All OR No External File Details must be entered
					NEXT FIELD ext_file_ind 
				END IF 
			END IF 

		AFTER FIELD bic_code 
			IF glob_rec_bank.bic_code IS NULL THEN 
				ERROR kandoomsg2("G",9178,"")				# 9178 bic must NOT be NULL
				NEXT FIELD bic_code 
			END IF 
			SELECT * 
			INTO glob_rec_bic .* 
			FROM bic 
			WHERE bic_code = glob_rec_bank.bic_code 		# don't insist on a validated bic
			IF status = NOTFOUND THEN 
				LET glob_rec_bic .desc_text = NULL 
			END IF 
			DISPLAY BY NAME glob_rec_bic .desc_text 


		AFTER FIELD iban 
			IF glob_rec_bank.iban IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD iban 
			END IF 

			SELECT count(*) INTO glob_counter FROM bank 
			WHERE iban = glob_rec_bank.iban 
			AND bank_code != glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF glob_counter > 0 THEN 
				ERROR kandoomsg2("G",9121,"") 			#9121 "Bank Account already exists FOR this account "
				NEXT FIELD iban 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR 
			quit_flag != 0 THEN 
			ELSE 
				IF glob_rec_bank.type_code IS NULL THEN 
					ERROR kandoomsg2("G",9164,"")					# 9164 Bank Type must NOT be NULL
					NEXT FIELD type_code 
				END IF 
				IF glob_rec_bank.eft_rpt_ind != 0 
				AND glob_rec_bank.eft_rpt_ind != 1 
				AND glob_rec_bank.eft_rpt_ind != 2 THEN 
					ERROR kandoomsg2("G",9185,"") 				#9185 Cleansing Report Indicator must be 0, 1, OR 2
					NEXT FIELD eft_rpt_ind 
				END IF 
				
				IF glob_rec_bank.next_eft_ref_num IS NULL THEN 
					ERROR kandoomsg2("G",9180,"")		# 9180 The next EFT payment number must be entered
					NEXT FIELD next_eft_ref_num 
				END IF 
				
				IF glob_rec_bank.next_eft_run_num IS NULL THEN 
					ERROR kandoomsg2("G",9182,"")					# 9182 The next EFT payment run number must be entered
					NEXT FIELD next_eft_run_num 
				END IF 
				
				IF glob_rec_bank.bic_code IS NULL THEN 
					ERROR kandoomsg2("G",9178,"")				# 9178 bic must NOT be NULL
					NEXT FIELD bic_code 
				END IF 
				
				SELECT count(*) INTO glob_counter FROM bank 
				WHERE acct_code = glob_rec_bank.acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF glob_counter > 0 THEN 
					ERROR kandoomsg2("G",9121,"") 		#9121 "Bank Account already exists FOR this account "
					NEXT FIELD acct_code 
				END IF 

				SELECT count(*) INTO glob_counter FROM coa 
				WHERE acct_code = glob_rec_bank.acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF glob_counter = 0 THEN 
					ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try Window.
					NEXT FIELD acct_code 
				END IF 
				
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_bank.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
				
				IF glob_rec_bank.currency_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
					NEXT FIELD currency_code 
				END IF
				 
				SELECT * INTO glob_rec_currency.* FROM currency 
				WHERE currency_code = glob_rec_bank.currency_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")		#9105 RECORD NOT found; Try Window.
					NEXT FIELD currency_code 
				END IF 
				
				SELECT count(*) INTO glob_counter FROM bank 
				WHERE iban = glob_rec_bank.iban 
				AND bank_code != glob_rec_bank.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF glob_counter > 0 THEN 
					NEXT FIELD iban 
				END IF 
				IF glob_rec_bank.next_cheque_num < 1 THEN 
					ERROR kandoomsg2("U",9907,"1")			#9907 Value must be greater than OR equal TO 1.
					NEXT FIELD next_cheque_num 
				END IF 
				
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				AND cheq_code = glob_rec_bank.next_cheque_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("P",9010,glob_rec_bank.next_cheque_num)		#9010 Cheque number already issued
					NEXT FIELD next_cheque_num 
				END IF 
				
				# eft_run_num IS used TO store next cheque run with the pay_meth_ind
				# sorting out WHERE it came FROM
				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 
				IF l_max >= glob_rec_bank.next_cheq_run_num THEN 
					ERROR kandoomsg2("U",9907,l_max + 1)			#9907 The next run number must be greater than previous ones
					NEXT FIELD next_cheq_run_num 
				END IF 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				AND cheq_code = glob_rec_bank.next_eft_ref_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("P",9010,glob_rec_bank.next_eft_ref_num)	#9010 Cheque number already issued
					NEXT FIELD next_eft_ref_num 
				END IF 
				
				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 
				
				IF l_max >= glob_rec_bank.next_eft_run_num THEN 
					ERROR kandoomsg2("U",9907,l_max + 1)		# 9907 The next EFT payment run number must greater than older ones
					NEXT FIELD next_eft_run_num 
				END IF 
			END IF 
			IF glob_rec_bank.ext_path_text IS NOT NULL	OR glob_rec_bank.ext_file_text IS NOT NULL THEN 
				IF glob_rec_bank.ext_file_ind = "0" THEN 
					ERROR kandoomsg2("G",6001,"") 	#6001 " WARNING: External payments NOT selected - file details NOT required"
				END IF 
				
				IF glob_rec_bank.ext_path_text IS NULL OR glob_rec_bank.ext_file_text IS NULL THEN 
					ERROR kandoomsg2("G",9537,"") 	#9162 " All OR No External File Details must be entered
					NEXT FIELD ext_file_ind 
				END IF 
			END IF 

	END INPUT 


	IF int_flag != 0 OR quit_flag != 0 THEN 
	
	ELSE 
		LET glob_rec_bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF (glob_rec_bank.bank_code IS NOT null) THEN 
			INSERT INTO bank VALUES (glob_rec_bank.*) 
		END IF 
	END IF 
	
	CLOSE WINDOW ba_wind 
END FUNCTION 
##############################################################
# END FUNCTION addor()
##############################################################


##############################################################
# FUNCTION changor()
#
#
##############################################################
FUNCTION changor() 
	DEFINE l_save_id LIKE bank.bank_code 
	DEFINE l_save_acct_code LIKE bank.acct_code 
	DEFINE l_save_acct_num LIKE bank.iban 
	DEFINE l_save_curr_code LIKE bank.currency_code 
	DEFINE l_next_ref_num LIKE bank.next_eft_ref_num 
	DEFINE l_next_run_num LIKE bank.next_eft_run_num 
	DEFINE l_next_cheq_run_num LIKE bank.next_cheq_run_num 
	DEFINE l_run_num_changed SMALLINT 
	DEFINE l_max INTEGER 
	DEFINE l_err_message CHAR(20) 
	DEFINE l_winds_text CHAR(20) 
	DEFINE l_cheque_count INTEGER 
	DEFINE l_receipt_count INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 


	OPEN WINDOW ba_wind with FORM "G134" 
	CALL windecoration_g("G134") 

	MESSAGE kandoomsg2("A",1036,"") #1036 Enter Banking Details; OK TO Continue.
	SELECT bank.* INTO glob_rec_bank.* FROM bank 
	WHERE bank_code = glob_arr_rec_bank[glob_idx].bank_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	SELECT * 
	INTO glob_rec_banktype.* 
	FROM banktype 
	WHERE type_code = glob_rec_bank.type_code 

	SELECT * 
	INTO glob_rec_bic .* 
	FROM bic 
	WHERE bic_code = glob_rec_bank.bic_code 

	LET l_run_num_changed = 0 
	LET l_cheque_count = 0 
	LET l_receipt_count = 0 
	LET l_save_id = glob_rec_bank.bank_code 
	LET l_save_acct_code = glob_rec_bank.acct_code 
	LET l_save_acct_num = glob_rec_bank.iban 
	LET l_save_curr_code = glob_rec_bank.currency_code 

	SELECT count(*) INTO l_cheque_count FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_acct_code = glob_rec_bank.acct_code 

	SELECT count(*) INTO l_receipt_count FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cash_acct_code = glob_rec_bank.acct_code 

	#sheet_num and state_bal_amt must not be NULL.. we are dealing with decimals/money
	IF glob_rec_bank.sheet_num IS NULL THEN
		LET glob_rec_bank.sheet_num = 0
	END IF
	
	IF glob_rec_bank.state_bal_amt IS NULL THEN
		LET glob_rec_bank.state_bal_amt = 0.00
	END IF


	DISPLAY BY NAME 
		glob_rec_bank.bank_code, 
		glob_rec_bank.currency_code, 
		glob_rec_bank.name_acct_text, 
		glob_rec_bank.acct_code, 
		glob_rec_bank.type_code, 
		glob_rec_banktype.type_text, 
		glob_rec_bank.remit_text, 
		glob_rec_bank.user_text, 
		glob_rec_bank.eft_rpt_ind, 
		glob_rec_bank.next_eft_run_num, 
		glob_rec_bank.next_eft_ref_num, 
		glob_rec_bank.ext_file_ind, 
		glob_rec_bank.ext_path_text, 
		glob_rec_bank.ext_file_text, 
		glob_rec_bank.bic_code, 
		glob_rec_bic .desc_text, 
		glob_rec_bank.next_cheque_num, 
		glob_rec_bank.iban, 
		glob_rec_bank.sheet_num, 
		glob_rec_bank.state_bal_amt 

	############### INPUT Bank Edit
	INPUT BY NAME 
		glob_rec_bank.bank_code, 
		glob_rec_bank.currency_code, 
		glob_rec_bank.name_acct_text, 
		glob_rec_bank.acct_code, 
		glob_rec_bank.type_code, 
		glob_rec_bank.remit_text, 
		glob_rec_bank.user_text, 
		glob_rec_bank.eft_rpt_ind, 
		glob_rec_bank.next_cheque_num, 
		glob_rec_bank.next_cheq_run_num, 
		glob_rec_bank.next_eft_ref_num, 
		glob_rec_bank.next_eft_run_num, 
		glob_rec_bank.ext_file_ind, 
		glob_rec_bank.ext_path_text, 
		glob_rec_bank.ext_file_text, 
		glob_rec_bank.bic_code, 
		glob_rec_bank.iban, 
		glob_rec_bank.sheet_num, 
		glob_rec_bank.state_bal_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ6","bankEdit") 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#ON ACTION/KEY
		ON ACTION "LOOKUP" infield (acct_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 

			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.acct_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.acct_code 
			END IF 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD acct_code 

		ON ACTION "LOOKUP" infield (currency_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.currency_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.currency_code 
			END IF 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD currency_code 

		ON ACTION "LOOKUP" infield (type_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_banktype() 

			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.type_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.type_code 
			END IF 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD type_code 

		ON ACTION "LOOKUP" infield (bic_code) 
			LET l_winds_text = NULL 
			LET l_winds_text = show_bic() 

			IF l_winds_text IS NOT NULL THEN 
				LET glob_rec_bank.bic_code = l_winds_text 
				DISPLAY BY NAME glob_rec_bank.bic_code 
			END IF 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			NEXT FIELD bic_code 


			 {
			   CASE
			      WHEN infield (acct_code)
			         LET l_winds_text = NULL
			         LET l_winds_text = show_acct(glob_rec_kandoouser.cmpy_code)
			         IF l_winds_text IS NOT NULL THEN
			            LET glob_rec_bank.acct_code = l_winds_text
			            DISPLAY BY NAME glob_rec_bank.acct_code
			         END IF
			         OPTIONS INSERT KEY F1,
			                 DELETE KEY F36
			         NEXT FIELD acct_code
			      WHEN infield (currency_code)
			         LET l_winds_text = NULL
			         LET l_winds_text = show_curr(glob_rec_kandoouser.cmpy_code)
			         IF l_winds_text IS NOT NULL THEN
			            LET glob_rec_bank.currency_code = l_winds_text
			            DISPLAY BY NAME glob_rec_bank.currency_code
			         END IF
			         OPTIONS INSERT KEY F1,
			                 DELETE KEY F36
			         NEXT FIELD currency_code
			      WHEN infield (type_code)
			         LET l_winds_text = NULL
			         LET l_winds_text = show_banktype()
			         IF l_winds_text IS NOT NULL THEN
			            LET glob_rec_bank.type_code = l_winds_text
			            DISPLAY BY NAME glob_rec_bank.type_code
			         END IF
			         OPTIONS INSERT KEY F1,
			                 DELETE KEY F36
			         NEXT FIELD type_code
			      WHEN infield (bic_code)
			         LET l_winds_text = NULL
			         LET l_winds_text = show_bic()
			         IF l_winds_text IS NOT NULL THEN
			            LET glob_rec_bank.bic_code = l_winds_text
			            DISPLAY BY NAME glob_rec_bank.bic_code
			         END IF
			         OPTIONS INSERT KEY F1,
			                 DELETE KEY F36
			         NEXT FIELD bic_code
			   END CASE
			}
		BEFORE FIELD bank_code 
			SELECT unique bank_code FROM tenthead 
			WHERE bank_code = glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("P",7006,"") 			#7006 Tentative payment being processed. No UPDATE performed.
			END IF 
			NEXT FIELD currency_code 

		AFTER FIELD currency_code 
			IF glob_rec_bank.currency_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD currency_code 
			END IF 

			SELECT * INTO glob_rec_currency.* FROM currency 
			WHERE currency_code = glob_rec_bank.currency_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 		#9105 RECORD NOT found; Try Window.
				NEXT FIELD currency_code 
			END IF 

			IF l_save_curr_code <> glob_rec_bank.currency_code THEN 
				IF l_cheque_count > 0 OR l_receipt_count > 0 THEN 
					ERROR kandoomsg2("G",9126,"")				#9126 "Transactions have occurred on this account-cannot be altered"
					LET glob_rec_bank.currency_code = l_save_curr_code 
					NEXT FIELD currency_code 
				END IF 
			END IF 

		AFTER FIELD acct_code 
			SELECT count(*) INTO glob_counter FROM bank 
			WHERE acct_code = glob_rec_bank.acct_code 
			AND bank_code != l_save_id 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF glob_counter > 0 THEN 
				ERROR kandoomsg2("G",9121,"") 			#9121 "Bank Account already exists FOR this account "
				LET glob_rec_bank.acct_code = l_save_acct_code 
				NEXT FIELD acct_code 
			END IF 
			
			SELECT count(*) INTO glob_counter FROM coa 
			WHERE acct_code = glob_rec_bank.acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_counter = 0 THEN 
				ERROR kandoomsg2("U",9105,"")			#9105 RECORD NOT found; Try Window.
				LET glob_rec_bank.acct_code = l_save_acct_code 
				NEXT FIELD acct_code 
			END IF 
			
			IF l_save_acct_code <> glob_rec_bank.acct_code THEN 
				IF l_cheque_count > 0 OR l_receipt_count > 0 THEN 
					ERROR kandoomsg2("G",9126,"")			#9126 "Transactions have occurred on this account-cannot be altered"
					LET glob_rec_bank.acct_code = l_save_acct_code 
					NEXT FIELD acct_code 
				END IF 
			END IF 
			
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_bank.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK,"Y") THEN 
				NEXT FIELD acct_code 
			END IF 

		AFTER FIELD type_code 
			IF glob_rec_bank.type_code IS NULL THEN 
				ERROR kandoomsg2("G",9164,"")		# 9164 Bank Type must NOT be NULL
				NEXT FIELD type_code 
			END IF 
			SELECT * 
			INTO glob_rec_banktype.* 
			FROM banktype 
			WHERE type_code = glob_rec_bank.type_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9179,"") 	# 9179 Bank Type NOT found - Try Window
				NEXT FIELD type_code 
			END IF 
			DISPLAY BY NAME glob_rec_banktype.type_text 


		AFTER FIELD eft_rpt_ind 
			IF glob_rec_bank.eft_rpt_ind != 0 
			AND glob_rec_bank.eft_rpt_ind != 1 
			AND glob_rec_bank.eft_rpt_ind != 2 THEN 
				ERROR kandoomsg2("G",9185,"") 	#9185 Cleansing Report Indicator must be 0, 1, OR 2
				NEXT FIELD eft_rpt_ind 
			END IF 

		AFTER FIELD next_cheque_num 
			IF glob_rec_bank.next_cheque_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD next_cheque_num 
			END IF 
			IF glob_rec_bank.next_cheque_num < 1 THEN 
				ERROR kandoomsg2("U",9907,"1")	#9907 Value must be greater than OR equal TO 1.
				NEXT FIELD next_cheque_num 
			END IF 
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			AND cheq_code = glob_rec_bank.next_cheque_num 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("P",9010,glob_rec_bank.next_cheque_num)	#9010 Cheque number already issued
				NEXT FIELD next_cheque_num 
			END IF 

		BEFORE FIELD next_cheq_run_num 
			LET l_next_cheq_run_num = glob_rec_bank.next_cheq_run_num 
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 

		AFTER FIELD next_cheq_run_num 
			IF glob_rec_bank.next_cheq_run_num IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	# 9102 Value must be entered.
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 
			IF glob_rec_bank.next_cheq_run_num < 1 THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)	#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 
			
			# eft_run_num IS used TO store next cheque run with the pay_meth_ind
			# sorting out WHERE it came FROM
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "1" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF
			 
			IF l_max >= glob_rec_bank.next_cheq_run_num THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)		#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_cheq_run_num = l_next_cheq_run_num 
				DISPLAY BY NAME glob_rec_bank.next_cheq_run_num 

				NEXT FIELD next_cheq_run_num 
			END IF 

		BEFORE FIELD next_eft_ref_num 
			LET l_next_ref_num = glob_rec_bank.next_eft_ref_num 

		AFTER FIELD next_eft_ref_num 
			IF glob_rec_bank.next_eft_ref_num IS NULL THEN 
				ERROR kandoomsg2("G",9180,"") 		# 9180 The next EFT payment number must be entered
				LET glob_rec_bank.next_eft_ref_num = l_next_ref_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_ref_num 

				NEXT FIELD next_eft_ref_num 
			END IF 
			
			IF glob_rec_bank.next_eft_ref_num < 1 THEN 
				ERROR kandoomsg2("U",9907,"1") #9907 Value must be greater than OR equal TO 1.
				NEXT FIELD next_eft_ref_num 
			END IF 
			SELECT unique 1 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			AND cheq_code = glob_rec_bank.next_eft_ref_num 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("P",9010,glob_rec_bank.next_eft_ref_num)	#9010 Cheque number already issued
				LET glob_rec_bank.next_eft_ref_num = l_next_ref_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_ref_num 

				NEXT FIELD next_eft_ref_num 
			END IF 

		BEFORE FIELD next_eft_run_num 
			LET l_next_run_num = glob_rec_bank.next_eft_run_num 
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 

		AFTER FIELD next_eft_run_num 
			IF glob_rec_bank.next_eft_run_num IS NULL THEN 
				ERROR kandoomsg2("G",9182,"") 	# 9182 The next EFT payment run number must be entered
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 
			
			IF glob_rec_bank.next_eft_run_num < 1 THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)		#9907 The next run number must be greater than previous ones
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 
			
			SELECT max(eft_run_num) INTO l_max FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND pay_meth_ind = "3" 
			IF l_max IS NULL THEN 
				LET l_max = 0 
			END IF 
			IF l_max >= glob_rec_bank.next_eft_run_num THEN 
				ERROR kandoomsg2("U",9907,l_max + 1)			# 9907 The next EFT payment run number must greater than older ones
				LET glob_rec_bank.next_eft_run_num = l_next_run_num 
				DISPLAY BY NAME glob_rec_bank.next_eft_run_num 

				NEXT FIELD next_eft_run_num 
			END IF 

		AFTER FIELD ext_file_text 
			IF glob_rec_bank.ext_path_text IS NOT NULL 
			OR glob_rec_bank.ext_file_text IS NOT NULL THEN 
				IF glob_rec_bank.ext_file_ind = "0" THEN 
					ERROR kandoomsg2("G",6001,"") 	#6001 " WARNING: External payments NOT selected - file details NOT required"
				END IF 
				IF glob_rec_bank.ext_path_text IS NULL OR glob_rec_bank.ext_file_text IS NULL THEN 
					ERROR kandoomsg2("G",9537,"") 		#9162 " All OR No External File Details must be entered
					NEXT FIELD ext_file_ind 
				END IF 
			END IF 

		AFTER FIELD bic_code 
			IF glob_rec_bank.bic_code IS NULL THEN 
				ERROR kandoomsg2("G",9178,"") # 9178 bic must NOT be NULL
				NEXT FIELD bic_code 
			END IF 
			
			SELECT * INTO glob_rec_bic .* FROM bic 
			WHERE bic_code = glob_rec_bank.bic_code 
			IF status = NOTFOUND THEN 
				LET glob_rec_bic .desc_text = NULL 
			END IF 
			
			DISPLAY BY NAME glob_rec_bic .desc_text 

		AFTER FIELD iban 
			IF glob_rec_bank.iban IS NULL THEN 
				LET glob_rec_bank.iban = l_save_acct_num 
				NEXT FIELD iban 
			END IF 
			
			IF l_save_acct_num != glob_rec_bank.iban THEN 
				SELECT unique 1 FROM bankstatement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_save_id 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",9126,"")	#9126 "Transactions have occurred on this account-cannot be altered"
					LET glob_rec_bank.iban = l_save_acct_num 
					NEXT FIELD iban 
				END IF 

				SELECT count(*) INTO glob_counter FROM bank 
				WHERE iban = glob_rec_bank.iban 
				AND bank_code != l_save_id 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF glob_counter > 0 THEN 
					ERROR kandoomsg2("G",9121,"")			#9121 "Bank Account already exists FOR this account "
					LET glob_rec_bank.iban = l_save_acct_num 
					NEXT FIELD iban 
				END IF 
			END IF 

		BEFORE FIELD state_bal_amt 
			IF glob_rec_bank.state_bal_amt IS NULL THEN
				LET glob_rec_bank.state_bal_amt = 0
			END IF
			
			SELECT unique 1 FROM bankstatement 
			WHERE bank_code = glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				CONTINUE INPUT 
			ELSE 
				NEXT FIELD currency_code 
			END IF 

		AFTER FIELD state_bal_amt
			IF glob_rec_bank.state_bal_amt  IS NULL THEN
				LET glob_rec_bank.state_bal_amt = 0
			END IF
						
		AFTER FIELD sheet_num
			IF (glob_rec_bank.sheet_num IS NULL) OR (glob_rec_bank.sheet_num < 0) THEN
				LET glob_rec_bank.sheet_num = 0
			END IF
		
		#------------------------------------------------------------------
		AFTER INPUT 
			IF int_flag != 0 OR	quit_flag != 0 THEN
			
			ELSE 
				IF glob_rec_bank.type_code IS NULL THEN 
					ERROR kandoomsg2("G",9164,"")		# 9164 Bank Type must NOT be NULL
					NEXT FIELD type_code 
				END IF 
				
				IF glob_rec_bank.next_eft_ref_num IS NULL THEN 
					ERROR kandoomsg2("G",9180,"")		# 9180 The next EFT payment number must be entered
					NEXT FIELD next_eft_ref_num 
				END IF 
				
				IF glob_rec_bank.next_eft_run_num IS NULL THEN 
					ERROR kandoomsg2("G",9182,"")	# 9182 The next EFT payment run number must be entered
					NEXT FIELD next_eft_run_num 
				END IF 
				
				IF glob_rec_bank.eft_rpt_ind != 0 
				AND glob_rec_bank.eft_rpt_ind != 1 
				AND glob_rec_bank.eft_rpt_ind != 2 THEN 
					ERROR kandoomsg2("G",9185,"")	#9185 Cleansing Report Indicator must be 0, 1, OR 2
					NEXT FIELD eft_rpt_ind 
				END IF 
				
				IF glob_rec_bank.bic_code IS NULL THEN 
					ERROR kandoomsg2("G",9178,"")	# 9178 bic must NOT be NULL
					NEXT FIELD bic_code 
				END IF 
				
				SELECT count(*) INTO glob_counter FROM bank 
				WHERE acct_code = glob_rec_bank.acct_code 
				AND bank_code != l_save_id 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF glob_counter > 0 THEN 
					ERROR kandoomsg2("G",9121,"")			#9121 "Bank Account already exists FOR this account "
					LET glob_rec_bank.acct_code = l_save_acct_code 
					NEXT FIELD acct_code 
				END IF 
				
				SELECT count(*) INTO glob_counter FROM coa 
				WHERE acct_code = glob_rec_bank.acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF glob_counter = 0 THEN 
					ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try Window.
					LET glob_rec_bank.acct_code = l_save_acct_code 
					NEXT FIELD acct_code 
				END IF 
				
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_bank.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_BANK,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 

				IF l_save_acct_num != glob_rec_bank.iban THEN 
					SELECT unique 1 FROM bankstatement 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_save_id 
					IF status != NOTFOUND THEN 
						ERROR kandoomsg2("G",9126,"")	#9126 "Transactions have occurred on this account-cannot be altered"
						NEXT FIELD iban 
					END IF 

					SELECT count(*) INTO glob_counter FROM bank 
					WHERE iban = glob_rec_bank.iban 
					AND bank_code != l_save_id 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					IF glob_counter > 0 THEN 
						ERROR kandoomsg2("G",9121,"") 	#9121 "Bank Account already exists FOR this account "
						NEXT FIELD iban 
					END IF 
				END IF 
				
				IF l_save_acct_code <> glob_rec_bank.acct_code THEN 
					IF l_cheque_count > 0 OR l_receipt_count > 0 THEN 
						ERROR kandoomsg2("G",9126,"") 	#9126 "Transactions have occurred on this account-cannot be altered"
						LET glob_rec_bank.acct_code = l_save_acct_code 
						NEXT FIELD acct_code 
					END IF 
				END IF 
				
				IF glob_rec_bank.currency_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
					NEXT FIELD currency_code 
				END IF 
				SELECT * INTO glob_rec_currency.* FROM currency 
				WHERE currency_code = glob_rec_bank.currency_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"")#9105 RECORD NOT found; Try Window.
					NEXT FIELD currency_code 
				END IF 
				
				IF l_save_curr_code <> glob_rec_bank.currency_code THEN 
					IF l_cheque_count > 0 OR l_receipt_count > 0 THEN 
						ERROR kandoomsg2("G",9126,"")		#9126 "Transactions have occurred on this account-cannot be altered"
						LET glob_rec_bank.currency_code = l_save_curr_code 
						NEXT FIELD currency_code 
					END IF 
				END IF 
				
				IF glob_rec_bank.next_cheque_num < 1 THEN 
					ERROR kandoomsg2("U",9907,"1")				#9907 Value must be greater than OR equal TO 1.
					NEXT FIELD next_cheque_num 
				END IF 
				
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				AND cheq_code = glob_rec_bank.next_cheque_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("P",9010,glob_rec_bank.next_cheque_num)		#9010 Cheque number already issued
					NEXT FIELD next_cheque_num 
				END IF 
				
				# eft_run_num IS used TO store next cheque run with the pay_meth_ind
				# sorting out WHERE it came FROM
				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 
				
				IF l_max >= glob_rec_bank.next_cheq_run_num THEN 
					ERROR kandoomsg2("U",9907,l_max + 1)		#9907 The next run number must be greater than previous ones
					NEXT FIELD next_cheq_run_num 
				END IF 
				
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				AND cheq_code = glob_rec_bank.next_eft_ref_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("P",9010,glob_rec_bank.next_eft_ref_num)		#9010 Cheque number already issued
					NEXT FIELD next_eft_ref_num 
				END IF 
				
				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 
				IF l_max >= glob_rec_bank.next_eft_run_num THEN 
					ERROR kandoomsg2("U",9907,l_max + 1)		# 9907 The next EFT payment run number must greater than older ones
					NEXT FIELD next_eft_run_num 
				END IF 
				
				IF glob_rec_bank.ext_path_text IS NOT NULL OR glob_rec_bank.ext_file_text IS NOT NULL THEN 
					IF glob_rec_bank.ext_file_ind = "0" THEN 
						ERROR kandoomsg2("G",6001,"") 			#6001 " WARNING: External payments NOT selected - file details NOT required"
					END IF 
					
					IF glob_rec_bank.ext_path_text IS NULL 	OR glob_rec_bank.ext_file_text IS NULL THEN 
						ERROR kandoomsg2("G",9537,"")		#9162 " All OR No External File Details must be entered
						NEXT FIELD ext_file_ind 
					END IF 
				END IF 
				
				SELECT unique bank_code FROM tenthead 
				WHERE bank_code = glob_rec_bank.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("P",7006,"")		#7006 Tentative payment being processed. No UPDATE performed.
					NEXT FIELD acct_code 
				END IF 
			END IF 


	END INPUT 
	---------------------------------------------------------

	GOTO bypass --huho, i want TO cry 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		CLOSE WINDOW ba_wind 
		RETURN 
	END IF 
	LABEL bypass: 

	IF NOT (int_flag OR quit_flag) THEN 
		IF (glob_rec_bank.bank_code IS NOT null) THEN 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				DECLARE c_bank CURSOR FOR 
				SELECT * FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				FOR UPDATE 
				OPEN c_bank 
				FETCH c_bank INTO glob_rec_s_bank.* 
				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				AND cheq_code = glob_rec_bank.next_cheque_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",7001,"") 	#7001 Another user beat you WHEN changeing this bank account.
					EXIT PROGRAM 
				END IF 
				
				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "1" 
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 

				IF l_max >= glob_rec_bank.next_cheq_run_num THEN 
					ERROR kandoomsg2("G",7001,"")		#7001 Another user beat you WHEN changeing this bank account.
					EXIT PROGRAM 
				END IF 

				SELECT unique 1 FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				AND cheq_code = glob_rec_bank.next_eft_ref_num 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",7001,"")	#7001 Another user beat you WHEN changeing this bank account.
					EXIT PROGRAM 
				END IF 

				SELECT max(eft_run_num) INTO l_max FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
				AND pay_meth_ind = "3" 
				IF l_max IS NULL THEN 
					LET l_max = 0 
				END IF 
				IF l_max >= glob_rec_bank.next_eft_run_num THEN 
					ERROR kandoomsg2("G",7001,"")	#7001 Another user beat you WHEN changeing this bank account.
					EXIT PROGRAM 
				END IF 

				SELECT unique bank_code FROM tenthead 
				WHERE bank_code = glob_rec_bank.bank_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",7001,"")		#7001 Another user beat you WHEN changeing this bank account.
					EXIT PROGRAM 
				END IF 
				SELECT count(*) INTO l_cheque_count FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_acct_code = glob_rec_bank.acct_code 
				SELECT count(*) INTO l_receipt_count FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_acct_code = glob_rec_bank.acct_code 
				
				IF l_save_acct_code <> glob_rec_bank.acct_code OR		l_save_curr_code <> glob_rec_bank.currency_code THEN 
					IF l_cheque_count > 0 OR l_receipt_count > 0 THEN 
						ERROR kandoomsg2("G",7001,"") #7001 Another user beat you WHEN changeing this bank account.
						EXIT PROGRAM 
					END IF 
				END IF 
				
				UPDATE bank SET * = glob_rec_bank.* 
				WHERE bank_code = l_save_id 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			COMMIT WORK 
			WHENEVER ERROR stop 
		END IF 

		LET glob_arr_rec_bank[glob_idx].name_acct_text = glob_rec_bank.name_acct_text 
		LET glob_arr_rec_bank[glob_idx].acct_code = glob_rec_bank.acct_code 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW ba_wind 
END FUNCTION 
##############################################################
# END FUNCTION changor()
##############################################################


##############################################################
# FUNCTION GZ6_gl_check_del(p_bank_code, p_acct_code)
#
#
##############################################################
FUNCTION GZ6_gl_check_del(p_bank_code, p_acct_code)
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_acct_code LIKE bank.acct_code 

	DEFINE l_answer CHAR(1) 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	ERROR kandoomsg2("G",8009,"") #8009 "Do you wish TO delete this bank account (y/n)? "
	IF l_msgresp = "Y" THEN 
		SELECT count(*) INTO glob_counter FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		bank_acct_code = p_acct_code 
		IF glob_counter > 0 THEN 
			ERROR kandoomsg2("G",9129,"") 		#9129 "Transactions have occurred on this account-cannot be deleted"
		ELSE 
			SELECT count(*) INTO glob_counter FROM cashreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			cash_acct_code = p_acct_code 
			IF glob_counter > 0 THEN 
				ERROR kandoomsg2("G",9129,"") 			#9129 "Transactions have occurred on this account-cannot be del"
			ELSE 
				SELECT unique 1 FROM bankstatement 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = p_bank_code
				IF status != NOTFOUND THEN 
					ERROR kandoomsg2("G",9129,"") 				#9129 "Transaction have occured on this account-cannot be del"
				ELSE 
					DELETE FROM bank 
					WHERE bank_code = p_bank_code
					AND acct_code = p_acct_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					FOR i = glob_idx TO arr_count() 
						LET glob_arr_rec_bank[i].* = glob_arr_rec_bank[i+1].* 
					END FOR 
					INITIALIZE glob_arr_rec_bank[i+1].* TO NULL 
					LET j = glob_idx 
					#FOR i = scrn TO 10
					#   DISPLAY glob_arr_rec_bank[j].* TO sr_bank[i].*
					#   LET j = j + 1
					#END FOR
				END IF 
			END IF 
		END IF 
	END IF 

END FUNCTION 
##############################################################
# END FUNCTION GZ6_gl_check_del(p_bank_code, p_acct_code)
##############################################################