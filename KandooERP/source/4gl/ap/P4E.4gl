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

	Source code beautified by beautify.pl on 2020-01-03 13:41:30	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_cheque RECORD LIKE cheque.* 
DEFINE modu_rec_bank RECORD LIKE bank.* 

############################################################
# MAIN
#
# \brief module P4E allows the user TO Scan EFT Payments
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P4E") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp503 with FORM "P503" 
	CALL windecoration_p("P503") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_cheques() 
		CALL scan_cheques() 
	END WHILE 
	CLOSE WINDOW wp503 
END MAIN 

FUNCTION select_cheques() 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_winds_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("P", 1051, "") 
	#1051 Enter Bank Code - ESC TO Continue
	INPUT BY NAME modu_rec_bank.bank_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P4E","inp-bank-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield (bank_code) 
					LET l_winds_text = NULL 
					CALL show_bank(glob_rec_kandoouser.cmpy_code) 
					RETURNING l_winds_text, modu_rec_cheque.bank_acct_code 
					IF l_winds_text IS NOT NULL THEN 
						LET modu_rec_bank.bank_code = l_winds_text 
						DISPLAY BY NAME modu_rec_bank.bank_code 

					ELSE 
						LET modu_rec_cheque.bank_acct_code = NULL 
					END IF 
			END CASE 
		AFTER FIELD bank_code 
			SELECT * INTO modu_rec_bank.* FROM bank 
			WHERE bank_code = modu_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P", 9003, "") 
				#9003 Bank Account IS NOT found, use the window "
				NEXT FIELD bank_code 
			END IF 
			DISPLAY BY NAME modu_rec_bank.name_acct_text 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	DISPLAY BY NAME modu_rec_bank.currency_code 

	LET l_msgresp = kandoomsg("P",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON eft_run_num, 
	vend_code, 
	cheq_code, 
	cheq_date, 
	year_num, 
	period_num, 
	pay_amt, 
	apply_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P4E","construct-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("P",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM cheque ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND bank_code = '", modu_rec_bank.bank_code, "' ", 
		"AND pay_meth_ind = '3' ", 
		"AND ", l_where_text clipped, 
		" ORDER BY eft_run_num, vend_code, cheq_code" 
		PREPARE s_cheque FROM l_query_text 
		DECLARE c_cheque CURSOR FOR s_cheque 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION scan_cheques() 
	DEFINE l_arr_ind ARRAY[200] OF RECORD 
		pay_meth_ind LIKE cheque.pay_meth_ind 
	END RECORD 
	DEFINE l_arr_cheque ARRAY[200] OF RECORD 
		scroll_flag CHAR(1), 
		eft_run_num LIKE cheque.eft_run_num, 
		vend_code LIKE cheque.vend_code, 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT

	LET idx = 0 
	FOREACH c_cheque INTO modu_rec_cheque.* 
		LET idx = idx + 1 
		LET l_arr_cheque[idx].eft_run_num = modu_rec_cheque.eft_run_num 
		LET l_arr_cheque[idx].vend_code = modu_rec_cheque.vend_code 
		LET l_arr_cheque[idx].cheq_code = modu_rec_cheque.cheq_code 
		LET l_arr_cheque[idx].cheq_date = modu_rec_cheque.cheq_date 
		LET l_arr_cheque[idx].year_num = modu_rec_cheque.year_num 
		LET l_arr_cheque[idx].period_num = modu_rec_cheque.period_num 
		LET l_arr_cheque[idx].pay_amt = modu_rec_cheque.pay_amt 
		LET l_arr_cheque[idx].apply_amt = modu_rec_cheque.apply_amt 
		LET l_arr_ind[idx].pay_meth_ind = modu_rec_cheque.pay_meth_ind 
		IF idx = 200 THEN 
			LET l_msgresp = kandoomsg("P", 9042, idx) 
			#9042 First 200 entries selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("P", 9044, "") 
		#9044 No entries satisfied selection criteria
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("P", 1007, "") 
	#1007 RETURN on line TO View
	OPTIONS INSERT KEY f36 
	OPTIONS DELETE KEY f36 

	INPUT ARRAY l_arr_cheque WITHOUT DEFAULTS FROM sr_cheque.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P4E","inp-arr-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY l_arr_cheque[idx].* 
			TO sr_cheque[scrn].* 

		AFTER FIELD scroll_flag 
			DISPLAY l_arr_cheque[idx].scroll_flag 
			TO sr_cheque[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_cheque[idx+1].vend_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("P",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD eft_run_num 
			IF l_arr_cheque[idx].eft_run_num IS NOT NULL THEN 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
				l_arr_cheque[idx].vend_code, 
				l_arr_cheque[idx].cheq_code, 
				l_arr_ind[idx].pay_meth_ind, 
				modu_rec_bank.bank_code, 
				0) 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_cheque[idx].* 
			TO sr_cheque[scrn].* 

	END INPUT 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 


