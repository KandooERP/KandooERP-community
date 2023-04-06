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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
# \brief module : GCE
# Purpose  : European Cash Book Entry & Reconciliation
#            Main Entry Module
#
###########################################################################
MAIN 
	DEFINE l_title_text char(36) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GCE") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	SELECT * INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF glob_rec_glparms.cash_book_flag != "Y" THEN 
		LET l_msgresp=kandoomsg("G",9502,"") 
		#G9502" Cash Book Facility IS NOT Available "
		EXIT PROGRAM 
	END IF 

	CALL create_table("bankstatement","t_bkstate","","N") 

	CREATE temp TABLE t_bkdetl ( 
	seq_num SMALLINT, 
	ref_code char(8), 
	ref_num INTEGER, 
	ref_text char(16), 
	tran_amt money(12,2), 
	disc_amt money(12,2), 
	acct_code char(18), 
	desc_text char(30), 
	conv_qty FLOAT ) with no LOG 
	CREATE INDEX i_bkdetl ON t_bkdetl(seq_num,ref_num) 

	OPEN WINDOW g408 with FORM "G408" 
	CALL windecoration_g("G408") 

	WHILE get_bank() 

		OPEN WINDOW g401 with FORM "G401" 
		CALL windecoration_g("G401") 

		DISPLAY BY NAME glob_rec_bank.bank_code, 
		glob_rec_bank.iban, 
		glob_rec_bank.sheet_num, 
		glob_rec_trans_head.open_bal_amt, 
		glob_rec_trans_head.close_bal_amt 

		DISPLAY glob_rec_bank.currency_code, 
		glob_rec_bank.currency_code 
		TO currency_code1, 
		currency_code2 

		WHILE scan_cashbk() 
			LET l_title_text = sheet_status() 

			MENU " reconciliation" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GCE","menu-reconciliation") 
					IF l_title_text != "Sheet in balance" THEN 
						HIDE option "Close" 
					END IF 
					CALL dialog.setActionHidden("ACCEPT",TRUE)  #we work with SAVE
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "SAVE" 
				--COMMAND "Close" " Close this Sheet " 
					IF hold_sheet() THEN
						CALL close_sheet()
					END IF 
					EXIT MENU 

				ON ACTION "Hold" 
				--COMMAND "Hold" " Save Changes FOR later editing" 
					IF hold_sheet() THEN 
					END IF 
					EXIT MENU 

				ON ACTION "Discard" 
				--COMMAND "Discard" " Discard Changes & EXIT PROGRAM" 
					EXIT MENU 

				ON ACTION "CANCEL" 
				--COMMAND KEY(interrupt,"E")"Exit" " RETURN TO edit current sheet" 
					LET quit_flag = true 
					EXIT MENU 

			END MENU 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		CLOSE WINDOW g401 
	END WHILE 

	CLOSE WINDOW g408 

END MAIN 


######################################################################
# FUNCTION get_bank()
#
#
######################################################################
FUNCTION get_bank() 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_temp_date LIKE bankstatement.tran_date 
	DEFINE l_next_sheet_num LIKE bank.sheet_num 
	DEFINE l_temp_sheet LIKE bank.sheet_num 
	DEFINE l_last_field char(4) 
	DEFINE l_stmt_type char(13) 
	DEFINE l_next_text char(16) 
	DEFINE l_next_date DATE 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_rec_bankstatement.tran_amt = NULL 
	LET l_rec_bankstatement.tran_date = NULL 
	LET l_next_date = NULL 
	LET l_next_text = NULL 

	--INITIALIZE glob_rec_bank.* TO NULL #may be we can comment this if user goes back and only wants to change one field... 

	CLEAR FORM 

	LET l_msgresp=kandoomsg("G",1050,"") 

	#G1050 Enter Bank Details - ESC TO Continue
	INPUT 
	glob_rec_bank.bank_code, 
	glob_rec_bank.sheet_num, 
	l_rec_bankstatement.tran_date, 
	glob_rec_bank.state_bal_amt, 
	l_rec_bankstatement.tran_amt, 
	l_next_date WITHOUT DEFAULTS 
	FROM 
	bank.bank_code, 
	bank.sheet_num, 
	tran_date, 
	state_bal_amt, 
	tran_amt, 
	next_date 
	ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCE","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_bank.bank_code, 
			glob_rec_bank.acct_code 
			NEXT FIELD bank_code 

		ON CHANGE bank_code
--			DISPLAY db_bank_get_name_acct_text(UI_OFF,glob_rec_bank.bank_code) TO bank.name_acct_text
--			DISPLAY db_bank_get_iban(UI_OFF,glob_rec_bank.bank_code) TO bank.iban
--			DISPLAY db_bank_get_bic_code(UI_OFF,glob_rec_bank.bank_code) TO bank.bic_code	
			SELECT * INTO glob_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9143,"") 
				#9143 Bank code does NOT exist
				NEXT FIELD bank_code 
			END IF 

			LET l_next_sheet_num = glob_rec_bank.sheet_num + 1 
			LET glob_rec_bank.sheet_num = l_next_sheet_num 
			LET l_rec_bankstatement.type_code = NULL 
			LET l_rec_bankstatement.tran_date = NULL 
			LET l_rec_bankstatement.tran_amt = NULL 
			LET l_next_date = NULL 

			SELECT tran_date, 
			tran_amt, 
			type_code, 
			ref_text 
			INTO l_rec_bankstatement.tran_date, 
			l_rec_bankstatement.tran_amt, 
			l_rec_bankstatement.type_code, 
			l_next_text 
			FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND sheet_num = l_next_sheet_num 
			AND seq_num = 0 
			AND entry_type_code = "SH" 

			IF l_next_text IS NOT NULL THEN 
				LET l_next_date = l_next_text 
			END IF 

			IF l_rec_bankstatement.tran_amt IS NULL THEN 
				LET l_rec_bankstatement.tran_amt = 0 
			END IF 

			LET l_stmt_type = NULL 

			IF l_rec_bankstatement.type_code = "1" THEN 
				LET l_stmt_type = "* Bank Load *" 
			END IF 

			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY glob_rec_bank.iban TO iban 
			DISPLAY glob_rec_bank.state_bal_amt TO state_bal_amt 
			DISPLAY glob_rec_bank.sheet_num TO sheet_num 
			DISPLAY l_rec_bankstatement.tran_date TO tran_date 
			DISPLAY l_rec_bankstatement.tran_amt TO tran_amt 
			DISPLAY l_next_date TO next_date 
			DISPLAY l_stmt_type TO stmt_type 

		AFTER FIELD bank_code 
			IF NOT db_bank_pk_exists(UI_FK,MODE_UPDATE,glob_rec_bank.bank_code) THEN
				NEXT FIELD bank_code
			END IF

		ON CHANGE sheet_num
			IF glob_rec_bank.sheet_num IS NULL THEN 
				LET glob_rec_bank.sheet_num = l_next_sheet_num 
				NEXT FIELD sheet_num 
			END IF 

			IF glob_rec_bank.sheet_num < l_next_sheet_num THEN 
				LET l_msgresp = kandoomsg("G",9214,"") 
				# Statement IS closed
				LET glob_rec_bank.sheet_num = l_next_sheet_num 
				NEXT FIELD sheet_num 
			END IF 

			IF glob_rec_bank.sheet_num != l_next_sheet_num THEN 
				LET glob_rec_bank.state_bal_amt = 0 
			ELSE 
				SELECT state_bal_amt INTO glob_rec_bank.state_bal_amt FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_bank.bank_code 
			END IF 

			LET l_rec_bankstatement.tran_amt = NULL 
			LET l_rec_bankstatement.tran_date = NULL 
			LET l_rec_bankstatement.type_code = NULL 
			LET l_next_date = NULL 
			LET l_next_text = NULL 

			SELECT tran_date, 
			tran_amt, 
			type_code, 
			ref_text 
			INTO l_rec_bankstatement.tran_date, 
			l_rec_bankstatement.tran_amt, 
			l_rec_bankstatement.type_code, 
			l_next_text 
			FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND sheet_num = glob_rec_bank.sheet_num 
			AND seq_num = 0 
			AND entry_type_code = "SH" 

			IF status = NOTFOUND THEN 
				LET l_rec_bankstatement.tran_amt = 0 
			END IF 

			IF l_next_text IS NOT NULL THEN 
				LET l_next_date = l_next_text 
			END IF 

			LET l_stmt_type = NULL 

			IF l_rec_bankstatement.type_code = "1" THEN 
				LET l_stmt_type = "* Bank Load *" 
			END IF 

			DISPLAY glob_rec_bank.state_bal_amt TO state_bal_amt 
			DISPLAY l_rec_bankstatement.tran_date TO tran_date 
			DISPLAY l_rec_bankstatement.tran_amt TO tran_amt 
			DISPLAY l_next_date TO next_date 
			DISPLAY l_stmt_type TO stmt_type 

		AFTER FIELD sheet_num 
			IF glob_rec_bank.sheet_num IS NULL THEN 
				LET glob_rec_bank.sheet_num = l_next_sheet_num 
				NEXT FIELD sheet_num 
			END IF 

			IF glob_rec_bank.sheet_num < l_next_sheet_num THEN 
				LET l_msgresp = kandoomsg("G",9214,"") 
				# Statement IS closed
				LET glob_rec_bank.sheet_num = l_next_sheet_num 
				NEXT FIELD sheet_num 
			END IF 


		BEFORE FIELD tran_date 
			LET l_temp_date = l_rec_bankstatement.tran_date 

		AFTER FIELD tran_date 
			IF l_rec_bankstatement.tran_date IS NULL THEN 
				LET l_msgresp = kandoomsg("J",9505,"") 
				LET l_rec_bankstatement.tran_date = l_temp_date 
				NEXT FIELD tran_date 
			END IF 

			IF l_rec_bankstatement.type_code = "1" 
			AND l_rec_bankstatement.tran_date != l_temp_date THEN 
				LET l_msgresp = kandoomsg("G",9074,"") 
				LET l_rec_bankstatement.tran_date = l_temp_date 
				NEXT FIELD tran_date 
			END IF 

			LET l_last_field = "fwrd" 


		BEFORE FIELD state_bal_amt 
			IF glob_rec_bank.sheet_num = l_next_sheet_num THEN 
				IF l_last_field = "fwrd" THEN 
					NEXT FIELD tran_amt 
				ELSE 
					NEXT FIELD tran_date 
				END IF 
			END IF 

		BEFORE FIELD tran_amt 
			#Bank Load Statement sheets - cant change closing balance...
			IF l_rec_bankstatement.type_code = "1" THEN 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD next_date 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD tran_date 
				END CASE 
			END IF 

		AFTER FIELD tran_amt 
			IF l_rec_bankstatement.tran_amt IS NULL THEN 
				LET l_rec_bankstatement.tran_amt = 0 
				NEXT FIELD tran_amt 
			END IF 
			LET l_last_field = "bwrd" 

		AFTER FIELD next_date 
			IF l_next_date IS NOT NULL THEN 
				IF l_rec_bankstatement.type_code = "1" THEN 
					IF l_next_date < l_rec_bankstatement.tran_date THEN 
						LET l_msgresp = kandoomsg("G",9536,"") 
						#9536 Next statement date must be > than the statement date.
						NEXT FIELD next_date 
					END IF 
				END IF 
			END IF 

			--		ON KEY (control-w)
			--			CALL kandoohelp("")

	END INPUT 
	##################################################


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET glob_rec_trans_head.open_bal_amt = glob_rec_bank.state_bal_amt 
		LET glob_rec_trans_head.close_bal_amt = l_rec_bankstatement.tran_amt 
		LET glob_rec_trans_head.tran_date = l_rec_bankstatement.tran_date 
		LET glob_rec_trans_head.ref_text = l_next_date 
		RETURN true 
	END IF 
END FUNCTION 


######################################################################
# FUNCTION scan_cashbk()
#
#
######################################################################
FUNCTION scan_cashbk() 
	DEFINE l_arr_rec_bankstate DYNAMIC ARRAY OF RECORD --array[1200] OF RECORD ### MAIN screen program ARRAY 
		scroll_flag char(1), 
		seq_num LIKE bankstatement.seq_num, 
		entry_type_code LIKE bankstatement.entry_type_code, 
		tran_date LIKE bankstatement.tran_date, 
		ref_code LIKE bankstatement.ref_code, 
		ref_text LIKE bankstatement.ref_text, 
		dr_tran_amt LIKE bankstatement.tran_amt, 
		cr_tran_amt LIKE bankstatement.tran_amt, 
		recon_flag LIKE bankstatement.recon_ind 
	END RECORD 
	DEFINE l_rec_orig_stat RECORD ### holds each original line 
		scroll_flag char(1), 
		seq_num LIKE bankstatement.seq_num, 
		entry_type_code LIKE bankstatement.entry_type_code, 
		tran_date LIKE bankstatement.tran_date, 
		ref_code LIKE bankstatement.ref_code, 
		ref_text LIKE bankstatement.ref_text, 
		dr_tran_amt LIKE bankstatement.tran_amt, 
		cr_tran_amt LIKE bankstatement.tran_amt, 
		recon_flag LIKE bankstatement.recon_ind 
	END RECORD 
	DEFINE l_rec_ret_values RECORD ### holds VALUES returned FROM search 
		doc_num INTEGER, 
		tran_date DATE, 
		ref_code LIKE bankstatement.ref_code, 
		dr_tran_amt LIKE bankstatement.tran_amt, 
		cr_tran_amt LIKE bankstatement.tran_amt 
	END RECORD 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_s_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_bankdetails RECORD LIKE bankdetails.* 
	DEFINE l_save_code LIKE bankstatement.entry_type_code 
	DEFINE l_ret_ref_code LIKE bankstatement.ref_code 
	DEFINE l_num_ref_code LIKE cheque.eft_run_num 
	--DEFINE l_ret_ref_text LIKE bankstatement.ref_text
	--DEFINE l_ret_tran_amt LIKE bankstatement.tran_amt
	--DEFINE l_ret_disc_amt LIKE bankstatement.tran_amt
	DEFINE l_temp_tran_amt LIKE bankstatement.tran_amt 
	DEFINE l_last_sheet_num LIKE bank.sheet_num 
	--DEFINE l_acct_mask_code LIKE customertype.acct_mask_code
	DEFINE l_new_rec SMALLINT 
	DEFINE l_header_count SMALLINT 

	DEFINE l_err_message char(60) 
	--DEFINE l_err_continue CHAR(1)
	--DEFINE l_sheet_num CHAR(5)
	--DEFINE l_option CHAR(1)
	--DEFINE l_cnt INTEGER
	--DEFINE l_exit_flag SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_temp_text char(100) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_row_valid BOOLEAN #Is row valid

	LET l_msgresp = kandoomsg("G",1002,"") 

	#1002 Searching database - please wait
	DECLARE c_bkstatement CURSOR FOR 
	SELECT * FROM bankstatement 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num = glob_rec_bank.sheet_num 
	ORDER BY bank_code, 
	sheet_num, 
	seq_num 
	LET l_idx = 0 

	DELETE FROM t_bkstate WHERE 1=1 
	DELETE FROM t_bkdetl WHERE 1=1 

	FOREACH c_bkstatement INTO l_rec_bankstatement.* 
		IF l_rec_bankstatement.entry_type_code = "SH" THEN 
			LET l_rec_bankstatement.tran_amt = glob_rec_trans_head.close_bal_amt 
			LET l_rec_bankstatement.tran_date = glob_rec_trans_head.tran_date 
			LET l_rec_bankstatement.ref_text = glob_rec_trans_head.ref_text 
			LET l_rec_bankstatement.seq_num = 0 
			INSERT INTO t_bkstate VALUES (l_rec_bankstatement.*) 
		ELSE 
			INSERT INTO t_bkstate VALUES (l_rec_bankstatement.*) 
			
			LET l_idx = l_idx + 1 
			LET l_arr_rec_bankstate[l_idx].seq_num=l_rec_bankstatement.seq_num 
			LET l_arr_rec_bankstate[l_idx].entry_type_code=l_rec_bankstatement.entry_type_code 
			LET l_arr_rec_bankstate[l_idx].tran_date = l_rec_bankstatement.tran_date 
			LET l_arr_rec_bankstate[l_idx].ref_code = l_rec_bankstatement.ref_code 
			LET l_arr_rec_bankstate[l_idx].ref_text = l_rec_bankstatement.ref_text 
			IF l_rec_bankstatement.entry_type_code = "CH" 
			OR l_rec_bankstatement.entry_type_code = "BC" 
			OR l_rec_bankstatement.entry_type_code = "PA" 
			OR l_rec_bankstatement.entry_type_code = "TO" 
			OR l_rec_bankstatement.entry_type_code = "DC" 
			OR l_rec_bankstatement.entry_type_code = "EF" THEN 
				LET l_arr_rec_bankstate[l_idx].dr_tran_amt = l_rec_bankstatement.tran_amt 
			ELSE 
				LET l_arr_rec_bankstate[l_idx].cr_tran_amt = l_rec_bankstatement.tran_amt 
			END IF 

			IF l_rec_bankstatement.recon_ind != "1" THEN 
				LET l_arr_rec_bankstate[l_idx].recon_flag = "*" 
			END IF 

			IF l_rec_bankstatement.doc_num IS NULL THEN 
				LET l_rec_bankstatement.doc_num = 0 
			END IF 

			DECLARE c1_bkdetl CURSOR FOR 
			SELECT * FROM bankdetails 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			AND sheet_num = glob_rec_bank.sheet_num 
			AND seq_num = l_rec_bankstatement.seq_num 

			FOREACH c1_bkdetl INTO l_rec_bankdetails.* 
				INSERT INTO t_bkdetl VALUES (l_rec_bankstatement.seq_num, 
				l_rec_bankdetails.ref_code, 
				l_rec_bankdetails.ref_num, 
				l_rec_bankdetails.ref_text, 
				l_rec_bankdetails.tran_amt, 
				l_rec_bankdetails.disc_amt, 
				l_rec_bankdetails.acct_code, 
				l_rec_bankdetails.desc_text, 
				l_rec_bankdetails.conv_qty) 
			END FOREACH 

		END IF 

		IF l_idx = 1200 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			EXIT FOREACH 
		END IF 

	END FOREACH 

	SELECT count(*) 
	INTO l_header_count 
	FROM t_bkstate 

	IF l_header_count = 0 THEN 
		INITIALIZE l_rec_bankstatement.* TO NULL 
		LET l_rec_bankstatement.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_bankstatement.bank_code = glob_rec_bank.bank_code 
		LET l_rec_bankstatement.sheet_num = glob_rec_bank.sheet_num 
		LET l_rec_bankstatement.seq_num = 0 
		LET l_rec_bankstatement.recon_ind = "1" 
		LET l_rec_bankstatement.entry_type_code = "SH" 
		LET l_rec_bankstatement.tran_date = glob_rec_trans_head.tran_date 
		LET l_rec_bankstatement.tran_amt = glob_rec_trans_head.close_bal_amt 
		LET l_rec_bankstatement.ref_text = glob_rec_trans_head.ref_text 
		LET l_rec_bankstatement.bank_currency_code = glob_rec_bank.currency_code 
		LET l_rec_bankstatement.conv_qty = 1.0 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,glob_rec_trans_head.tran_date) 
		RETURNING l_rec_bankstatement.year_num, 
		l_rec_bankstatement.period_num 

		LET l_rec_bankstatement.acct_code = glob_rec_bank.iban 
		LET l_rec_bankstatement.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_bankstatement.entry_date = today 
		LET l_rec_bankstatement.type_code = "0" 
		LET l_rec_bankstatement.desc_text = "Statement header" 
		LET l_rec_bankstatement.other_amt = 0 
		LET l_rec_bankstatement.applied_amt = 0 
		LET l_rec_bankstatement.disc_amt = 0 
		LET l_rec_bankstatement.ref_num = 0 
		LET l_rec_bankstatement.doc_num = 0 
		
		IF (l_rec_bankstatement.seq_num != 0) AND (l_rec_bankstatement.seq_num IS NOT NULL) THEN
			INSERT INTO t_bkstate VALUES (l_rec_bankstatement.*) 
		END IF
		
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	CALL set_count(l_idx) 

	LET glob_temp_amt = calc_totals() 
	LET l_msgresp=kandoomsg("G",1052,"") 

	#G1052 F1 Add F2 Delete etc
	INPUT ARRAY l_arr_rec_bankstate WITHOUT DEFAULTS FROM sr_bankstate.* attributes(unbuffered, INSERT ROW = FALSE) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCE","inp-arr-bank") 
			CALL show_balance_state()
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr()
			NEXT FIELD scroll_flag 

		AFTER ROW
			IF l_arr_rec_bankstate.getLength() >= l_idx THEN
				SELECT unique 1 FROM t_bkstate 
				WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num
				IF status = NOTFOUND THEN 
					--INITIALIZE l_arr_rec_bankstate[l_idx].* TO NULL
					LET l_row_valid = FALSE
				ELSE
					LET l_row_valid = TRUE
				END IF
	
	
				IF (l_arr_rec_bankstate[l_idx].entry_type_code IS NULL) OR (l_row_valid = FALSE) THEN
					CALL l_arr_rec_bankstate.deleteElement(l_idx)
				END IF			
			END IF
			CALL show_balance_state()
			
		BEFORE FIELD scroll_flag 
			SELECT * INTO l_rec_bankstatement.* FROM t_bkstate 
			WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 

			IF status = NOTFOUND THEN 
				## Blank line
				INITIALIZE l_rec_bankstatement.* TO NULL 
				LET l_rec_bankstatement.doc_num = 0 
				LET l_arr_rec_bankstate[l_idx].seq_num=null ## avoid 0 
				LET l_arr_rec_bankstate[l_idx].entry_type_code=null 
				LET l_arr_rec_bankstate[l_idx].tran_date = NULL ## avoid 31/12/1899 
				LET l_arr_rec_bankstate[l_idx].dr_tran_amt = NULL ## avoid 0 
				LET l_arr_rec_bankstate[l_idx].cr_tran_amt = NULL ## avoid 0 
			END IF 


			#DISPLAY l_arr_rec_bankstate[l_idx].* TO sr_bankstate[scrn].*

			LET l_rec_s_bankstatement.* = l_rec_bankstatement.* 

		BEFORE INSERT 
			INITIALIZE l_rec_bankstatement.* TO NULL 
			INITIALIZE l_rec_s_bankstatement.* TO NULL 
			INITIALIZE l_arr_rec_bankstate[l_idx].* TO NULL 
			##
			## A minor Informix problem exists WHERE WHEN pressing delete
			## on last line actually performs a delete AND an INSERT. To
			## avoid this the following check IS included.
			##
			IF fgl_lastkey() = fgl_keyval("delete") 
			OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
				INITIALIZE l_arr_rec_bankstate[l_idx].* TO NULL 
				NEXT FIELD scroll_flag 
			ELSE 
				IF l_rec_bankstatement.doc_num IS NULL THEN 
					LET l_rec_bankstatement.doc_num = 0 
				END IF 
				NEXT FIELD entry_type_code 
			END IF 

		ON ACTION "LOOKUP" infield(entry_type_code)  
				LET l_arr_rec_bankstate[l_idx].entry_type_code = show_type() 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f2 
				NEXT FIELD entry_type_code 
				
		ON ACTION "LOOKUP" 
				CASE l_arr_rec_bankstate[l_idx].entry_type_code 
					WHEN "BC" 
						CALL show_bdep("BC") RETURNING l_rec_ret_values.* 
						LET l_rec_ret_values.ref_code = l_arr_rec_bankstate[l_idx].ref_code 
					WHEN "CH" 
						CALL show_cheq() RETURNING l_rec_ret_values.* 
					WHEN "PA" 
						CALL show_vend_voucher() RETURNING l_rec_ret_values.* #note, this was show_vend() ??? duplicated FUNCTION NAME 
					WHEN "BD" 
						CALL show_bdep("CD") RETURNING l_rec_ret_values.* 
						LET l_rec_ret_values.ref_code = l_arr_rec_bankstate[l_idx].ref_code 
					WHEN "RE" 
						CALL show_cust() RETURNING l_rec_ret_values.* 
					WHEN "SC" 
						CALL show_bdep("SC") RETURNING l_rec_ret_values.* 
						LET l_rec_ret_values.ref_code = l_arr_rec_bankstate[l_idx].ref_code 
					WHEN "TO" 
						CALL show_transfer("TO") RETURNING l_rec_ret_values.* 
					WHEN "TI" 
						CALL show_transfer("TI") RETURNING l_rec_ret_values.* 
					WHEN "DC" 
						CALL show_dischq() RETURNING l_rec_ret_values.* 
					WHEN "EF" 
						CALL show_eft() RETURNING l_rec_ret_values.* 
					WHEN "ER" 
						CALL show_eft_for_rej() RETURNING l_rec_ret_values.* 
					OTHERWISE 
						INITIALIZE l_rec_ret_values.* TO NULL 
						EXIT CASE 
				END CASE 

				IF l_rec_ret_values.doc_num != 0 THEN 
					##
					## Transaction information returned FROM lookup window
					##
					LET l_rec_bankstatement.doc_num = l_rec_ret_values.doc_num 
					IF l_arr_rec_bankstate[l_idx].tran_date IS NULL THEN 
						LET l_arr_rec_bankstate[l_idx].tran_date = l_rec_ret_values.tran_date 
					END IF 
					LET l_arr_rec_bankstate[l_idx].ref_code = l_rec_ret_values.ref_code 
					LET l_arr_rec_bankstate[l_idx].dr_tran_amt = l_rec_ret_values.dr_tran_amt 
					LET l_arr_rec_bankstate[l_idx].cr_tran_amt = l_rec_ret_values.cr_tran_amt 
					#DISPLAY l_arr_rec_bankstate[l_idx].* TO sr_bankstate[scrn].*

				END IF 

--			END IF 

			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			##
			## Informix 4.12 AND later needs TO perform a NEXT FIELD
			## in ORDER TO redisplay new program variable VALUES TO
			## the SCREEN. Removing this blanks out current field variable
			--NEXT FIELD tran_date 
			##

		BEFORE DELETE 
			SELECT * INTO l_rec_s_bankstatement.* FROM t_bkstate 
			WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 

			DELETE FROM t_bkstate WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 
			DELETE FROM t_bkdetl WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 

			INITIALIZE l_arr_rec_bankstate[l_idx].* TO NULL 
			LET glob_temp_amt = calc_totals() 

			NEXT FIELD scroll_flag 


		BEFORE FIELD entry_type_code 
			IF l_arr_rec_bankstate[l_idx].seq_num IS NULL 
			OR l_arr_rec_bankstate[l_idx].seq_num = 0 THEN 

				SELECT max(seq_num) INTO l_arr_rec_bankstate[l_idx].seq_num 
				FROM t_bkstate 
				IF l_arr_rec_bankstate[l_idx].seq_num IS NULL THEN 
					LET l_arr_rec_bankstate[l_idx].seq_num = 1 
				ELSE 
					LET l_arr_rec_bankstate[l_idx].seq_num = l_arr_rec_bankstate[l_idx].seq_num + 1 
				END IF 

				LET l_rec_bankstatement.seq_num = l_arr_rec_bankstate[l_idx].seq_num 
				#DISPLAY l_arr_rec_bankstate[l_idx].seq_num TO sr_bankstate[scrn].seq_num

			END IF 

			LET l_save_code =l_arr_rec_bankstate[l_idx].entry_type_code 


		AFTER FIELD entry_type_code 
			CASE 
				WHEN get_is_screen_navigation_forward()

					IF l_arr_rec_bankstate[l_idx].entry_type_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD entry_type_code 
					END IF 

					IF l_save_code IS NOT NULL 
					AND l_save_code != l_arr_rec_bankstate[l_idx].entry_type_code THEN 
						### Changing of transaction types IS permissible FOR
						### the following combinations only.
						IF (l_save_code="CH" AND 
						l_arr_rec_bankstate[l_idx].entry_type_code="BC") 
						OR (l_save_code="PA" AND 
						l_arr_rec_bankstate[l_idx].entry_type_code="BC") 
						OR (l_save_code="DC" AND 
						l_arr_rec_bankstate[l_idx].entry_type_code="BC") 
						OR (l_save_code="BC" AND 
						l_arr_rec_bankstate[l_idx].entry_type_code="EF") 
						OR (l_save_code="BD" AND 
						l_arr_rec_bankstate[l_idx].entry_type_code="SC") THEN 
							LET l_err_message = NULL 
						ELSE 
							LET l_arr_rec_bankstate[l_idx].entry_type_code = l_save_code 
							LET l_msgresp = kandoomsg("G",9075,"") 
							#9075 Cannot change - Delete AND Re-enter.
							NEXT FIELD entry_type_code 
						END IF 

					END IF 

					NEXT FIELD NEXT 

				WHEN NOT get_is_screen_navigation_forward() 
					--NEXT FIELD previous 

				OTHERWISE 
					--NEXT FIELD entry_type_code 

			END CASE 


		BEFORE FIELD tran_date 
			#DISPLAY " CTRL-B FOR Transaction Info" TO lbLabel2b  --2,47
			MESSAGE "Use Lookup for Transation info" 

		AFTER FIELD tran_date 
			CASE 
				WHEN get_is_screen_navigation_forward() 

					IF l_arr_rec_bankstate[l_idx].tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						NEXT FIELD tran_date 
					ELSE 
						IF l_arr_rec_bankstate[l_idx].tran_date>(glob_rec_trans_head.tran_date+30) 
						OR l_arr_rec_bankstate[l_idx].tran_date<(glob_rec_trans_head.tran_date-120) THEN 
							IF promptTF("",kandoomsg2("A",8017,""),1)	THEN 		#A8017 Date out of range.  Do you wish TO re-enter?
								NEXT FIELD tran_date 
							END IF 
						END IF 

					END IF 

				WHEN NOT get_is_screen_navigation_forward() 
					--NEXT FIELD previous 

				OTHERWISE 
					--NEXT FIELD tran_date 

			END CASE 


		AFTER FIELD ref_code 
			CASE get_is_screen_navigation_forward() 
					--NEXT FIELD NEXT 
				WHEN NOT get_is_screen_navigation_forward()
					--NEXT FIELD previous 
			END CASE 


		BEFORE FIELD dr_tran_amt 
			CASE 
				WHEN NOT get_is_screen_navigation_forward() 
					--NEXT FIELD previous 
				OTHERWISE 
					IF l_arr_rec_bankstate[l_idx].entry_type_code != "BC" 
					AND l_arr_rec_bankstate[l_idx].entry_type_code != "CH" 
					AND l_arr_rec_bankstate[l_idx].entry_type_code != "PA" 
					AND l_arr_rec_bankstate[l_idx].entry_type_code != "TO" 
					AND l_arr_rec_bankstate[l_idx].entry_type_code != "DC" 
					AND l_arr_rec_bankstate[l_idx].entry_type_code != "EF" THEN 
						NEXT FIELD cr_tran_amt 
					END IF 
			END CASE 


		AFTER FIELD dr_tran_amt 
			IF l_arr_rec_bankstate[l_idx].dr_tran_amt IS NULL THEN 
				LET l_arr_rec_bankstate[l_idx].dr_tran_amt = 0 
				NEXT FIELD dr_tran_amt 
			END IF 

			IF not(l_arr_rec_bankstate[l_idx].dr_tran_amt > 0) THEN 
				LET l_msgresp = kandoomsg("G",9174,"") 
				#9174 Invalid Amount
				NEXT FIELD dr_tran_amt 
			END IF 

			CASE 
				WHEN NOT get_is_screen_navigation_forward()
					--NEXT FIELD previous 
				WHEN get_is_screen_navigation_forward() 
					--NEXT FIELD NEXT 
				OTHERWISE 
					CONTINUE INPUT 
			END CASE 


		BEFORE FIELD cr_tran_amt 
			IF l_arr_rec_bankstate[l_idx].entry_type_code != "BD" 
			AND l_arr_rec_bankstate[l_idx].entry_type_code != "SC" 
			AND l_arr_rec_bankstate[l_idx].entry_type_code != "RE" 
			AND l_arr_rec_bankstate[l_idx].entry_type_code != "ER" 
			AND l_arr_rec_bankstate[l_idx].entry_type_code != "TI" THEN 
				NEXT FIELD recon_flag 
			END IF 


		AFTER FIELD cr_tran_amt 
			IF l_arr_rec_bankstate[l_idx].cr_tran_amt IS NULL THEN 
				LET l_arr_rec_bankstate[l_idx].cr_tran_amt = 0 
				NEXT FIELD cr_tran_amt 
			END IF 

			CASE 
				WHEN NOT get_is_screen_navigation_forward() 
					--NEXT FIELD previous 
				WHEN get_is_screen_navigation_forward() 
					--NEXT FIELD NEXT 
			END CASE 

		BEFORE FIELD recon_flag 
			#DISPLAY "" AT 1,1
			#DISPLAY l_arr_rec_bankstate[l_idx].* TO sr_bankstate[scrn].*

			IF l_arr_rec_bankstate[l_idx].cr_tran_amt IS NULL THEN 
				LET l_temp_tran_amt = l_arr_rec_bankstate[l_idx].dr_tran_amt 
			ELSE 
				LET l_temp_tran_amt = l_arr_rec_bankstate[l_idx].cr_tran_amt 
			END IF 
			##
			SELECT * INTO l_rec_s_bankstatement.* 
			FROM t_bkstate 
			WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 

			IF status = 0 THEN 
				UPDATE t_bkstate 
				SET entry_type_code = l_arr_rec_bankstate[l_idx].entry_type_code, 
				tran_date = l_arr_rec_bankstate[l_idx].tran_date, 
				ref_code = l_arr_rec_bankstate[l_idx].ref_code, 
				ref_text = l_arr_rec_bankstate[l_idx].ref_text, 
				tran_amt = l_temp_tran_amt, 
				doc_num = l_rec_bankstatement.doc_num 
				WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 
			ELSE 
				LET l_rec_bankstatement.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_bankstatement.bank_code = glob_rec_bank.bank_code 
				LET l_rec_bankstatement.sheet_num = glob_rec_bank.sheet_num 
				LET l_rec_bankstatement.seq_num = l_arr_rec_bankstate[l_idx].seq_num 
				LET l_rec_bankstatement.recon_ind = "0" 
				LET l_rec_bankstatement.ref_text = l_arr_rec_bankstate[l_idx].ref_text 
				LET l_rec_bankstatement.entry_type_code = 
				l_arr_rec_bankstate[l_idx].entry_type_code 
				LET l_rec_bankstatement.tran_date = l_arr_rec_bankstate[l_idx].tran_date 
				LET l_rec_bankstatement.tran_amt = l_temp_tran_amt 
				LET l_rec_bankstatement.ref_code = l_arr_rec_bankstate[l_idx].ref_code 
				LET l_rec_bankstatement.bank_currency_code = glob_rec_bank.currency_code 
				LET l_rec_bankstatement.acct_code = glob_rec_bank.acct_code 
				LET l_rec_bankstatement.ref_num = NULL 
				LET l_rec_bankstatement.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_bankstatement.entry_date = today
	 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_bankstatement.tran_date) 
				RETURNING l_rec_bankstatement.year_num, 
				l_rec_bankstatement.period_num

				INSERT INTO t_bkstate VALUES (l_rec_bankstatement.*)
				 
			END IF 

			IF reconcile(l_arr_rec_bankstate[l_idx].seq_num) THEN 
				LET l_arr_rec_bankstate[l_idx].recon_flag = NULL 
				LET l_rec_bankstatement.recon_ind = 1 
			ELSE 
				LET l_arr_rec_bankstate[l_idx].recon_flag = "*" 
				LET l_rec_bankstatement.recon_ind = "0" 
			END IF 

			#DISPLAY l_arr_rec_bankstate[l_idx].* TO sr_bankstate[scrn].*
			UPDATE t_bkstate 
			SET recon_ind = l_rec_bankstatement.recon_ind 
			WHERE seq_num = l_arr_rec_bankstate[l_idx].seq_num 

			LET l_msgresp=kandoomsg("G",1052,"") 
			#G1052 F1 Add F2 Delete etc
			LET glob_temp_amt = calc_totals() 



		AFTER INPUT 
			IF int_flag OR quit_flag THEN 

				IF NOT infield(scroll_flag) THEN 
					LET quit_flag = false 
					LET int_flag = false 
					## User has DEL during line entry

					IF l_rec_s_bankstatement.seq_num IS NULL 
					OR l_rec_s_bankstatement.seq_num = 0 THEN 
						## New Line Being Aborted
						INITIALIZE l_arr_rec_bankstate[l_idx].* TO NULL 
					ELSE 
						## Existing Line Being Aborted
						LET l_arr_rec_bankstate[l_idx].seq_num=l_rec_s_bankstatement.seq_num 
						LET l_arr_rec_bankstate[l_idx].tran_date=l_rec_s_bankstatement.tran_date 
						LET l_arr_rec_bankstate[l_idx].ref_code=l_rec_s_bankstatement.ref_code 

						IF l_arr_rec_bankstate[l_idx].entry_type_code != "BD" 
						AND l_arr_rec_bankstate[l_idx].entry_type_code != "SC" 
						AND l_arr_rec_bankstate[l_idx].entry_type_code != "RE" 
						AND l_arr_rec_bankstate[l_idx].entry_type_code != "TI" THEN 
							LET l_arr_rec_bankstate[l_idx].dr_tran_amt=l_rec_s_bankstatement.tran_amt 
						ELSE 
							LET l_arr_rec_bankstate[l_idx].cr_tran_amt=l_rec_s_bankstatement.tran_amt 
						END IF 

					END IF 

					NEXT FIELD scroll_flag 
				END IF 

			END IF
			
	END INPUT 
	#############################################################

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


######################################################################
# FUNCTION hold_sheet()
#
#
######################################################################
FUNCTION hold_sheet() 
	#
	# This FUNCTION updates all lines in the bank sheet TO have
	# tentative reconciliations.  These tentative reconciliations
	# are changed TO permenent WHEN the sheet IS closed.
	# The tentative reconcilation IS acheived by
	#   a) removing all partial allocations
	#   b) creating FROM scratch new tentative allocations
	# Tentative reconciliations are only made TO tick-off type
	# transactions.  The following relationship IS used TO identify
	# these transactions:
	#
	#  bankstatement.doc_num = cheque.doc_num  (FOR Cheques)
	#  bankstatement.doc_num = banking.doc_num (FOR Bank Xfers, Deposits)
	#  bankstatement.doc_num = cashreceipt.cash_num (FOR Dishonoured Cheques)
	#
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_rec_bankdetails RECORD LIKE bankdetails.* 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_err_message char(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",1005,"") 
	#1002 Searching database - please wait

	GOTO bypass 

	LABEL recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "Hold: Resetting Bank Statement table" 
		DELETE FROM bankstatement 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_bank.bank_code 
		AND sheet_num = glob_rec_bank.sheet_num 

		LET l_err_message = "Hold: Resetting Bank Statement Details table" 
		DELETE FROM bankdetails 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_bank.bank_code 
		AND sheet_num = glob_rec_bank.sheet_num 

		LET l_err_message = "Hold: Resetting Cheques table" 
		UPDATE cheque 
		SET part_recon_flag = "N", 
		rec_state_num = null, 
		rec_line_num = NULL 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_bank.bank_code 
		AND rec_state_num = glob_rec_bank.sheet_num 

		LET l_err_message = "Hold: Resetting Banking table" 
		UPDATE banking 
		SET bk_rec_part = "N", 
		bk_sh_no = null, 
		bk_seq_no = NULL 
		WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
		AND bk_acct = glob_rec_bank.acct_code 
		AND bk_sh_no = glob_rec_bank.sheet_num 
		##
		## Now move through the temporary table updating cross-referenced
		## transactions TO be partially reconciled.
		##
		## Very important TO only UPDATE lines which successfully
		## reconciled as the reason it did NOT reconcile maybe
		## that the transaction IS reconciled on another sheet.
		##
		DECLARE c_t_bkstate CURSOR FOR 
		SELECT * FROM t_bkstate 
		ORDER BY seq_num 

		LET l_seq_num = 0 

		FOREACH c_t_bkstate INTO l_rec_bankstatement.* 
			IF l_rec_bankstatement.recon_ind = "1" THEN 

				CASE 
					WHEN l_rec_bankstatement.entry_type_code = "BC" 
						IF l_rec_bankstatement.doc_num > 0 THEN 
							## Xrefs a BC created in GC2
							UPDATE banking SET bk_rec_part = "Y", 
							bk_sh_no = glob_rec_bank.sheet_num, 
							bk_seq_no = l_seq_num 
							WHERE doc_num = l_rec_bankstatement.doc_num 
						END IF 

					WHEN l_rec_bankstatement.entry_type_code = "BD" 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = glob_rec_bank.sheet_num, 
						bk_seq_no = l_seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 

					WHEN l_rec_bankstatement.entry_type_code = "CH" 
						UPDATE cheque 
						SET part_recon_flag = "Y", 
						rec_state_num = glob_rec_bank.sheet_num, 
						rec_line_num = l_seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 

					WHEN l_rec_bankstatement.entry_type_code = "EF" 
						UPDATE cheque 
						SET part_recon_flag = "Y", 
						rec_state_num = glob_rec_bank.sheet_num, 
						rec_line_num = l_seq_num 
						WHERE eft_run_num = l_rec_bankstatement.ref_code 
						AND pay_meth_ind = "3" 
						AND bank_code = glob_rec_bank.bank_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 

					WHEN l_rec_bankstatement.entry_type_code = "SC" 
						IF l_rec_bankstatement.doc_num > 0 THEN 
							## Xrefs a SC created in GC1
							UPDATE banking SET bk_rec_part = "Y", 
							bk_sh_no = glob_rec_bank.sheet_num, 
							bk_seq_no = l_seq_num 
							WHERE doc_num = l_rec_bankstatement.doc_num 
						END IF 

					WHEN l_rec_bankstatement.entry_type_code = "TI" 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = glob_rec_bank.sheet_num, 
						bk_seq_no = l_seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 

					WHEN l_rec_bankstatement.entry_type_code = "TO" 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = glob_rec_bank.sheet_num, 
						bk_seq_no = l_seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 

					OTHERWISE 
						EXIT CASE 

				END CASE 

			END IF 

			LET l_err_message = "Inserting New Bank Details row" 
			DECLARE c2_bkdetl CURSOR FOR 
			SELECT ref_code, 
			ref_num, 
			ref_text, 
			tran_amt, 
			disc_amt, 
			acct_code, 
			desc_text, 
			conv_qty 
			FROM t_bkdetl 
			WHERE seq_num = l_rec_bankstatement.seq_num 

			FOREACH c2_bkdetl INTO l_rec_bankdetails.ref_code, 
				l_rec_bankdetails.ref_num, 
				l_rec_bankdetails.ref_text, 
				l_rec_bankdetails.tran_amt, 
				l_rec_bankdetails.disc_amt, 
				l_rec_bankdetails.acct_code, 
				l_rec_bankdetails.desc_text, 
				l_rec_bankdetails.conv_qty 
				LET l_rec_bankdetails.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_bankdetails.bank_code = glob_rec_bank.bank_code 
				LET l_rec_bankdetails.sheet_num = glob_rec_bank.sheet_num 
				LET l_rec_bankdetails.seq_num = l_seq_num 
				INSERT INTO bankdetails VALUES (l_rec_bankdetails.*) 
			END FOREACH 

			FREE c2_bkdetl 
			LET l_err_message = "Inserting New Bank Statement row" 
			LET l_rec_bankstatement.seq_num = l_seq_num 

			INSERT INTO bankstatement VALUES (l_rec_bankstatement.*) 
			LET l_seq_num = l_seq_num + 1 
		END FOREACH 


	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 

END FUNCTION 


######################################################################
# FUNCTION calc_totals()
#
#
######################################################################
FUNCTION calc_totals() 
	DEFINE l_dr_tot_amt LIKE bankstatement.tran_amt 
	DEFINE l_cr_tot_amt LIKE bankstatement.tran_amt 
	DEFINE l_bal_tot_amt LIKE bankstatement.tran_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT sum(tran_amt) INTO l_dr_tot_amt FROM t_bkstate 
	WHERE entry_type_code in ("CH","BC","PA","TO","DC","EF") 

	IF l_dr_tot_amt IS NULL THEN 
		LET l_dr_tot_amt = 0 
	END IF 

	SELECT sum(tran_amt) INTO l_cr_tot_amt FROM t_bkstate 
	WHERE entry_type_code in ("BD","SC","RE","TI","ER") 

	IF l_cr_tot_amt IS NULL THEN 
		LET l_cr_tot_amt = 0 
	END IF 

	LET l_bal_tot_amt = glob_rec_trans_head.open_bal_amt 
	+ l_cr_tot_amt 
	- l_dr_tot_amt 
	- glob_rec_trans_head.close_bal_amt 
	DISPLAY l_dr_tot_amt, 
	l_cr_tot_amt, 
	l_bal_tot_amt 
	TO dr_tot_amt, 
	cr_tot_amt, 
	bal_tot_amt 

	RETURN l_bal_tot_amt 

END FUNCTION 


######################################################################
# FUNCTION sheet_status()
#
#
######################################################################
FUNCTION sheet_status() 
	##
	## This FUNCTION contains the rules of why a bank sheet can OR
	## cannot be closed.  This FUNCTION returns a descriptive MESSAGE
	## as TO why the sheet cannot be closed OR returns the string
	## "Sheet Balanced".
	##
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_temp_text STRING 
	##
	## Sheet cannot be closed IF items within sheet are unreconciled
	##
	SELECT count(*) INTO l_idx 
	FROM t_bkstate 
	WHERE recon_ind != "1" 
	AND entry_type_code != "SH" 

	IF l_idx > 0 THEN 
		LET l_temp_text = " Unreconciled Items: ",l_idx USING "<<<" 
		RETURN l_temp_text 
	END IF 
	##
	## Sheet cannot be closed even IF it balances IF an unreconciled header
	## exists with a lower sheet number
	##
	SELECT count(*) INTO l_cnt FROM bankstatement 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND entry_type_code = 'SH' 
	AND recon_ind != '2' 
	AND sheet_num < glob_rec_bank.sheet_num 

	IF l_cnt > 0 THEN 
		LET l_temp_text = " Previous sheet unreconciled" 
		RETURN l_temp_text 
	END IF 
	##
	## Sheet cannot be closed IF opening bal. + movement != closing bal.
	##
	LET glob_temp_amt = calc_totals() 
	SELECT sheet_num INTO l_idx FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 

	CASE 
		WHEN glob_temp_amt < 0 
			LET glob_temp_amt = 0 - glob_temp_amt 
			LET l_temp_text = " Sheet Out of Balance: cr:", 
			glob_temp_amt USING "$<<<<<<.&&" 
		WHEN glob_temp_amt > 0 
			LET l_temp_text = " Sheet Out of Balance: dr:", 
			glob_temp_amt USING "$<<<<<<.&&" 
		WHEN glob_rec_bank.sheet_num != (l_idx+1) 
			LET l_temp_text = "Sheet Not Most current" 
		OTHERWISE 
			LET l_temp_text = "Sheet in balance" 
	END CASE 
	CALL show_balance_state()
	
	RETURN l_temp_text 

END FUNCTION


######################################################################
# FUNCTION show_balance_state()
#
# Informs user, if the sheet is in balance
######################################################################
FUNCTION show_balance_state()
	DEFINE l_idx SMALLINT
	DEFINE l_temp_text STRING
	
	LET glob_temp_amt = calc_totals() 
	SELECT sheet_num INTO l_idx FROM bank 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 

	CASE 
		WHEN glob_temp_amt < 0 
			LET glob_temp_amt = 0 - glob_temp_amt 
			LET l_temp_text = " Sheet Out of Balance: cr:", 
			glob_temp_amt USING "$<<<<<<.&&" 
			DISPLAY l_temp_text TO balance_state ATTRIBUTE(RED,REVERSE)
			
		WHEN glob_temp_amt > 0 
			LET l_temp_text = " Sheet Out of Balance: dr:", 
			glob_temp_amt USING "$<<<<<<.&&"
			DISPLAY l_temp_text TO balance_state ATTRIBUTE(RED,REVERSE)
			 
		WHEN glob_rec_bank.sheet_num != (l_idx+1) 
			LET l_temp_text = "Sheet Not Most current"
			DISPLAY l_temp_text TO balance_state ATTRIBUTE(RED,REVERSE)
			 
		OTHERWISE 
			LET l_temp_text = "Sheet in balance"
			DISPLAY l_temp_text TO balance_state ATTRIBUTE(GREEN,REVERSE) 
	END CASE 

END FUNCTION

FUNCTION gce_debug_temp_table()
	DEFINE l_count SMALLINT

		DISPLAY "@debug: #############################", time
		
		SELECT count(*) INTO l_count FROM t_bkstate
		DISPLAY "Count=", l_count
		DECLARE debug_c_t_bkstate CURSOR FOR 
		SELECT * FROM t_bkstate 
		ORDER BY seq_num 

		
		FOREACH debug_c_t_bkstate INTO glob_debug_rec_bankstatement.* 
			DISPLAY "@debug: ", "glob_debug_rec_bankstatement.seq_num =", glob_debug_rec_bankstatement.seq_num
			DISPLAY "@debug: ", "glob_debug_rec_bankstatement.sheet_num =", glob_debug_rec_bankstatement.sheet_num
			DISPLAY "-----------------------------------------"		
		END FOREACH
		FREE debug_c_t_bkstate
END FUNCTION		