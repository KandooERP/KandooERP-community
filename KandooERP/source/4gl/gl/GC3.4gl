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
{! PRAGMA EMULATE INSERT CURSOR FOR c_ins_recon !}  #huho ???????? what ????

############################################################
# MODULE DESRIPTION GC3 - Cash Book Reconciliation
############################################################
# This program allows the user TO reconcile bank statements against
# cashbook AND cheque transactions
############################################################


###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC3_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_recon RECORD 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit decimal(14,2), 
		re_cred decimal(14,2) 
	END RECORD 
	DEFINE glob_arr_rec_recon DYNAMIC ARRAY OF RECORD #array[10000] OF RECORD 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit decimal(14,2), 
		re_cred decimal(14,2) 
	END RECORD 
	DEFINE glob_arr_rowid DYNAMIC ARRAY OF INTEGER #array[10000] OF INTEGER 
	DEFINE glob_rec_bank RECORD LIKE bank.* 

	DEFINE glob_insert_text char(200) 
	DEFINE glob_max_no INTEGER 
	DEFINE glob_rowid INTEGER 
	DEFINE glob_recon_cnt INTEGER 
	DEFINE glob_next_seq_no INTEGER 
	DEFINE glob_o_seq_no INTEGER 
	DEFINE i INTEGER 
	DEFINE glob_recon_cshbk INTEGER 
	DEFINE glob_cheque_curr_code LIKE cheque.currency_code 
	DEFINE glob_cheque_conv_qty LIKE cheque.conv_qty 
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_bal_amt decimal(14,2) 
	DEFINE glob_op_bal_amt decimal(14,2) 
	DEFINE glob_clo_base_bal_amt decimal(14,2) 
	DEFINE glob_op_base_bal_amt decimal(14,2) 
	DEFINE glob_dr_tot_amt decimal(14,2) 
	DEFINE glob_cr_tot_amt decimal(14,2) 
	DEFINE glob_bal_tot_amt decimal(14,2) 
	DEFINE glob_cb_start DATE 
	DEFINE glob_cb_stop DATE 
	DEFINE glob_continue char(1) 
	DEFINE glob_err_message char(40) 
	DEFINE glob_close_date BOOLEAN #IF closing date should be used (true) or ignored(false)
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################


###########################################################################
# MAIN
#
#
###########################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GC3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--	SELECT glparms.*
	--	INTO glob_rec_glparms.*
	--	FROM glparms
	--	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND glparms.key_code = "1"
	--
	--	IF glob_rec_glparms.cash_book_flag != "Y" THEN
	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		#LET l_msgresp = kandoomsg("G",9502,"") 
		CALL msgcontinue("",kandoomsg2("G",9502,""))
		EXIT PROGRAM 
	END IF 

	CREATE temp TABLE t_recon ( 
	re_rowid INTEGER, 
	re_seq_no SMALLINT, 
	re_date DATE, 
	re_type char(2), 
	re_ref INTEGER, 
	re_desc char(30), 
	re_debit decimal(14,2), 
	re_cred decimal(14,2)) with no LOG 
	--	LET glob_insert_text = "INSERT INTO t_recon VALUES (?,?,?,?,?,?,?,?)"  # albo KD-1452
	--	PREPARE s_ins_recon FROM glob_insert_text
	--	DECLARE c_ins_recon cursor FOR s_ins_recon
	DECLARE c_ins_recon CURSOR FOR 
	INSERT INTO t_recon VALUES (glob_rowid,glob_rec_recon.re_seq_no,glob_rec_recon.re_date,glob_rec_recon.re_type,glob_rec_recon.re_ref,glob_rec_recon.re_desc,glob_rec_recon.re_debit,glob_rec_recon.re_cred) # albo kd-1452 

	OPEN WINDOW g136 with FORM "G136" 
	CALL windecoration_g("G136") 

	WHILE get_bank() 
		CALL recon_cashbk() 
	END WHILE 

	CLOSE WINDOW g136 
END MAIN 



############################################################
# FUNCTION get_bank()
#
#
############################################################
FUNCTION get_bank() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_cb_start = "1/1/2000" 
	LET glob_cb_stop = TODAY --"1/1/2020" 
	LET glob_bal_amt = 0 
	LET glob_max_no = 999 
	CLEAR FORM 

	INPUT glob_rec_bank.bank_code, glob_bal_amt, glob_cb_stop WITHOUT DEFAULTS 
	FROM bank_code, clo_bal,cb_stop ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC3","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_bank.bank_code, 
			glob_rec_bank.acct_code 
			DISPLAY glob_rec_bank.bank_code TO bank_code 

			NEXT FIELD bank_code 

		ON CHANGE bank_code 
			DISPLAY db_bank_get_name_acct_text(UI_OFF,glob_rec_bank.bank_code) TO bank.name_acct_text
			DISPLAY db_bank_get_iban(UI_OFF,glob_rec_bank.bank_code) TO bank.iban
			DISPLAY db_bank_get_bic_code(UI_OFF,glob_rec_bank.bank_code) TO bank.bic_code
			--NEXT FIELD bank_code 

		AFTER FIELD bank_code 
			SELECT bank.* 
			INTO glob_rec_bank.* 
			FROM bank 
			WHERE bank.bank_code = glob_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				#LET l_msgresp = kandoomsg("A",9132,"") 
				#9132 "Bank code IS NOT found - Try Window"
				ERROR kandoomsg2("A",9132,"")
				NEXT FIELD bank_code 
			END IF 
			SELECT count(*) INTO glob_cnt FROM bankstatement 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = glob_rec_bank.bank_code 
			IF glob_cnt > 0 THEN 
				#LET l_msgresp = kandoomsg("G",9004,"") 
				CALL msgcontinue("",kandoomsg2("G",9004,""))
				EXIT PROGRAM 
			END IF 
			LET glob_rec_bank.sheet_num = glob_rec_bank.sheet_num + 1 
			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY glob_rec_bank.iban TO iban 
			DISPLAY glob_rec_bank.state_bal_amt TO state_bal_amt 
			DISPLAY glob_rec_bank.sheet_num TO sheet_num 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 


############################################################
# FUNCTION show_sheet_balanced_state()
#
# Visual indication if sheet is balanced or not
############################################################
FUNCTION show_sheet_balanced_state()
	
	CASE 
		WHEN glob_bal_tot_amt IS NULL 
			DISPLAY "Total Balance IS NULL" TO lb_sheet_balanced_state ATTRIBUTE(REVERSE,YELLOW)
		WHEN glob_bal_tot_amt = 0 
			DISPLAY "Sheet balanced" TO lb_sheet_balanced_state ATTRIBUTE(REVERSE,GREEN)
		WHEN glob_bal_tot_amt != 0
			DISPLAY "Sheet unbalanced" TO lb_sheet_balanced_state ATTRIBUTE(REVERSE,RED)
	END CASE

END FUNCTION


############################################################
# FUNCTION recon_cashbk()
#
#
############################################################
FUNCTION recon_cashbk() 
	--DEFINE l_ans char(1) 
	DEFINE l_idx SMALLINT --, scrn 
	DEFINE l_sql_str STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_next_seq_no = 0 
	GOTO bypass 
	LABEL recovery: 
	LET glob_continue = error_recover(glob_err_message, status) 
	IF glob_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET glob_err_message = " Inserting Rows INTO temp table t_recon" 
	WHILE true 
		BEGIN WORK 
			DELETE FROM t_recon 
			OPEN c_ins_recon 


			#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER"
			#DISPLAY "see gl/GC3.4gl"
			#EXIT PROGRAM (1)

			LET l_sql_str = 
			" SELECT C.rowid, ", 
			" rec_line_num, ", 
			" cheq_date, ", 
			" cheq_code, ", 
			" name_text, ", 
			" net_pay_amt, ", 
			" C.currency_code, ", 
			" C.conv_qty ", 
			" FROM cheque C, ", 
			" outer vendor V ", 
			" WHERE C.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
			" AND V.cmpy_code = \"", trim(glob_rec_kandoouser.cmpy_code), "\" ", 
			" AND C.bank_acct_code = \"", trim(glob_rec_bank.acct_code), "\" ", 
			" AND C.pay_meth_ind = '1' ", 
			" AND (rec_state_num IS NULL OR part_recon_flag = 'Y') ", 
			" AND V.vend_code = C.vend_code ", 
			" AND ( ", 
			
			" cheq_date IS NULL ", 
			" OR ",
			" (cheq_date >= '", trim(glob_cb_start), "' ", 
			" AND cheq_date < '", trim(glob_cb_stop), "' ) ",
			 
			" ) " 

			PREPARE ert FROM l_sql_str 
			DECLARE c_cheque CURSOR FOR ert 


			LET glob_cnt = 0 
			INITIALIZE glob_rec_recon.* TO NULL 
			FOREACH c_cheque INTO glob_rowid, 
				glob_rec_recon.re_seq_no, 
				glob_rec_recon.re_date, 
				glob_rec_recon.re_ref, 
				glob_rec_recon.re_desc, 
				glob_rec_recon.re_debit, 
				glob_cheque_curr_code, 
				glob_cheque_conv_qty 
				IF glob_cheque_curr_code != glob_rec_bank.currency_code THEN 
					LET glob_rec_recon.re_debit = glob_rec_recon.re_debit / glob_cheque_conv_qty 
				END IF 
				IF glob_cnt = 10000 THEN 
					EXIT FOREACH 
				END IF 
				LET glob_cnt = glob_cnt + 1 
				LET glob_rec_recon.re_type = "AP" 
				IF glob_rec_recon.re_seq_no IS NULL THEN 
					LET glob_rec_recon.re_seq_no = glob_max_no 
				END IF 
				PUT c_ins_recon FROM glob_rowid, 
				glob_rec_recon.* 
			END FOREACH
			 
			DECLARE c2_cheque CURSOR FOR			 
			SELECT 0, 
			"", 
			cheq_date, 
			eft_run_num, 
			"", 
			sum(net_pay_amt) 
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_acct_code = glob_rec_bank.acct_code 
			AND pay_meth_ind = "3" 
			AND recon_flag != "Y" 
			AND (cheq_date IS NULL 
			OR (cheq_date >= glob_cb_start AND cheq_date < glob_cb_stop ))
			GROUP BY eft_run_num, cheq_date 
			ORDER BY eft_run_num 

			LET glob_cnt = 0 

			INITIALIZE glob_rec_recon.* TO NULL 
			FOREACH c2_cheque INTO glob_rowid, 
				glob_rec_recon.re_seq_no, 
				glob_rec_recon.re_date, 
				glob_rec_recon.re_ref, 
				glob_rec_recon.re_desc, 
				glob_rec_recon.re_debit 
				IF glob_cnt = 10000 THEN 
					EXIT FOREACH 
				END IF 
				LET glob_cnt = glob_cnt + 1 
				LET glob_rec_recon.re_type = "EF" 
				IF glob_rec_recon.re_seq_no IS NULL THEN 
					LET glob_rec_recon.re_seq_no = glob_max_no 
				END IF 
				PUT c_ins_recon FROM glob_rowid, 
				glob_rec_recon.* 
			END FOREACH 

			LET l_sql_str = 
			--"DECLARE c_banking CURSOR FOR ", 
			"SELECT rowid, ", 
			"bk_seq_no, ",
			"bk_bankdt, ",
			"bk_type, ",
			"bk_desc, ",
			"bk_debit, ",
			"bk_cred ",
			"FROM banking ",
			"WHERE bk_cmpy = \"" , glob_rec_kandoouser.cmpy_code CLIPPED, "\" ",
			"AND bk_acct = \"", glob_rec_bank.acct_code CLIPPED, "\" ",
			"AND (bk_sh_no IS NULL OR bk_rec_part = \"Y\") ", 
			"AND ( (bk_bankdt IS NULL) ",
			"OR (bk_bankdt >= \"", glob_cb_start CLIPPED, "\" AND bk_bankdt < \"", glob_cb_stop CLIPPED, "\" ))" 

			PREPARE pc_banking FROM l_sql_str
			DECLARE c_banking CURSOR FOR pc_banking
--			SELECT rowid, 
--			bk_seq_no, 
--			bk_bankdt, 
--			bk_type, 
--			bk_desc, 
--			bk_debit, 
--			bk_cred 
--			FROM banking 
--			WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
--			AND bk_acct = glob_rec_bank.acct_code 
--			AND (bk_sh_no IS NULL OR bk_rec_part = "Y") 
--			AND ( (bk_bankdt IS NULL) 
--			OR (bk_bankdt >= glob_cb_start AND bk_bankdt < glob_cb_stop )) 

			INITIALIZE glob_rec_recon.* TO NULL 
			FOREACH c_banking INTO glob_rowid, 
				glob_rec_recon.re_seq_no, 
				glob_rec_recon.re_date, 
				glob_rec_recon.re_type, 
				glob_rec_recon.re_desc, 
				glob_rec_recon.re_debit, 
				glob_rec_recon.re_cred 
				IF glob_cnt = 10000 THEN 
					EXIT FOREACH 
				END IF 
				LET glob_cnt = glob_cnt + 1 
				IF glob_rec_recon.re_seq_no IS NULL THEN 
					LET glob_rec_recon.re_seq_no = glob_max_no 
				END IF 
				PUT c_ins_recon FROM glob_rowid, 
				glob_rec_recon.* 
			END FOREACH
			 
		COMMIT WORK 

		IF glob_cnt = 10000 THEN 
			OPEN WINDOW g206 with FORM "G206" 
			CALL windecoration_g("G206") 

			INPUT glob_cb_start, glob_cb_stop FROM cb_start,cb_stop ATTRIBUTE(UNBUFFERED) 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","GC3","inp-start-stop") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END INPUT 

			CLOSE WINDOW g206 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN 
			END IF 
		ELSE 
			IF glob_cnt = 0 THEN 
				#LET l_msgresp = kandoomsg("G",9090,"") 
				CALL msgcontinue("",kandoomsg2("G",9090,""))
				RETURN 
			ELSE 
				EXIT WHILE 
			END IF 
		END IF 

	END WHILE 

	WHENEVER ERROR stop 

	OPEN WINDOW g137 with FORM "G137" 
	CALL windecoration_g("G137") 

	LET glob_op_bal_amt = glob_rec_bank.state_bal_amt 

	LET glob_op_base_bal_amt = glob_rec_bank.state_base_bal_amt 

	# these two lines inserted TO force a calculation of the
	# balance the first time through WHEN there are no
	# (part-)reconciled items TO trigger upd_bal()
	LET glob_recon_cnt = load_array() 
	LET glob_bal_tot_amt = glob_op_bal_amt 
	+ glob_cr_tot_amt 
	- (glob_dr_tot_amt + glob_bal_amt) 

	DISPLAY glob_bal_tot_amt TO bal_tot_amt 
	DISPLAY glob_cr_tot_amt TO cr_tot_amt 
	DISPLAY glob_dr_tot_amt TO dr_tot_amt 
	DISPLAY glob_cb_stop TO cb_stop  
	--	WHENEVER ERROR CONTINUE  #makes no sense..
	--	OPTIONS INSERT KEY f36,
	--	DELETE KEY f36
	--	WHENEVER ERROR stop  #makes no sense..

	DISPLAY glob_rec_bank.bank_code TO bank_code
	DISPLAY db_bank_get_name_acct_text(UI_OFF,glob_rec_bank.bank_code) TO bank.name_acct_text	 
	DISPLAY glob_rec_bank.iban TO bank.iban 
	DISPLAY glob_rec_bank.bic_code TO bank.bic_code 
	DISPLAY glob_op_bal_amt TO op_bal_amt 
	DISPLAY glob_bal_amt TO clo_bal_amt 

	DISPLAY glob_rec_bank.sheet_num TO sheet_num 

	DISPLAY glob_bal_tot_amt TO bal_tot_amt 
	DISPLAY glob_dr_tot_amt TO dr_tot_amt 
	DISPLAY glob_cr_tot_amt TO cr_tot_amt

	LET glob_recon_cshbk = true 
	WHILE glob_recon_cshbk 
		--		CALL set_count(glob_recon_cnt)

		--		INPUT ARRAY glob_arr_rec_recon WITHOUT DEFAULTS FROM sr_recon.* attributes(unbuffered)
		DISPLAY ARRAY glob_arr_rec_recon TO sr_recon.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","GC3","inp-arr-recon") 
				DISPLAY glob_bal_tot_amt TO bal_tot_amt 
				DISPLAY glob_dr_tot_amt TO dr_tot_amt 
				DISPLAY glob_cr_tot_amt TO cr_tot_amt
				CALL show_sheet_balanced_state() #IF glob_bal_tot_amt = 0 = balanced

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET glob_o_seq_no = glob_arr_rec_recon[l_idx].re_seq_no
				IF glob_arr_rec_recon[l_idx].re_type = "CD" THEN 
					CALL dialog.setActionHidden("F10-Split",FALSE)
				ELSE
					CALL dialog.setActionHidden("F10-Split",TRUE)
				END IF

				#LET scrn = scr_line()
				IF l_idx > glob_recon_cnt THEN 
					#LET l_msgresp = kandoomsg("G",9001,"") 
					ERROR kandoomsg2("G",9001,"")
				ELSE 
					IF glob_arr_rec_recon[l_idx].re_type = "CD" THEN 
						#LET l_msgresp = kandoomsg("G",1059,"") 
						MESSAGE kandoomsg2("G",1059,"")
					ELSE 
						#LET l_msgresp = kandoomsg("G",1060,"") 
						MESSAGE kandoomsg2("G",1060,"")
					END IF 
				END IF 
				#DISPLAY glob_arr_rec_recon[l_idx].*
				#     TO sr_recon[scrn].*

				#AFTER ROW
				#   DISPLAY glob_arr_rec_recon[l_idx].*
				#        TO sr_recon[scrn].*

			ON ACTION "F1-Upd.Balance" 
				--ON key(f1)
				IF glob_arr_rec_recon[l_idx].re_seq_no = glob_max_no THEN 
					IF glob_next_seq_no = glob_max_no THEN 
						#LET l_msgresp = kandoomsg("G",9063,"") 
						ERROR kandoomsg2("G",9063,"")
					ELSE 
						LET glob_arr_rec_recon[l_idx].re_seq_no = glob_next_seq_no 
						LET glob_next_seq_no = glob_next_seq_no + 1 
						#DISPLAY glob_arr_rec_recon[l_idx].re_seq_no
						#     TO sr_recon[scrn].re_seq_no

						CALL upd_bal(l_idx) 
					END IF 
					DISPLAY glob_op_bal_amt TO op_bal_amt 
				END IF 

				LET glob_o_seq_no = glob_arr_rec_recon[l_idx].re_seq_no 
				CALL show_sheet_balanced_state() #IF glob_bal_tot_amt = 0 = balanced

			ON ACTION "F2-Res Bal" 
				--			ON key(f2)
				IF glob_arr_rec_recon[l_idx].re_seq_no != glob_max_no THEN 
					LET glob_arr_rec_recon[l_idx].re_seq_no = glob_max_no 
					#DISPLAY glob_max_no
					#     TO sr_recon[scrn].re_seq_no

					CALL res_bal(l_idx) 
					DISPLAY glob_op_bal_amt TO op_bal_amt 
				END IF 
				LET glob_o_seq_no = glob_arr_rec_recon[l_idx].re_seq_no 
				CALL show_sheet_balanced_state() #IF glob_bal_tot_amt = 0 = balanced

			ON ACTION "F5-Direct In." 
				--			ON key(f5)
				CALL direct_in()  #Direct Cheque input /reconzilation
				DISPLAY glob_bal_tot_amt TO bal_tot_amt 
				DISPLAY glob_dr_tot_amt TO dr_tot_amt 
				DISPLAY glob_cr_tot_amt TO cr_tot_amt
				CALL show_sheet_balanced_state() #IF glob_bal_tot_amt = 0 = balanced
				EXIT DISPLAY --input 

			ON ACTION "F9-Unload" 
				--			ON key(f9)
				#LET l_msgresp = kandoomsg("G",1012,"") 
				MESSAGE kandoomsg2("G",1012,"")
				CALL unload_array() 
				LET glob_recon_cnt = load_array() 
				EXIT DISPLAY --input 

			ON ACTION "F10-Split" 
				--			ON key(f10)
				IF glob_arr_rec_recon[l_idx].re_type = "CD" THEN 
					LET glob_cnt = arr_curr() 
					#CALL fgl_winmessage("this needs checking", "CALL split(glob_arr_rowid[l_idx],glob_arr_rec_recon[l_idx].*,l_idx,scrn)", "info")
					CALL split(glob_arr_rowid[l_idx],glob_arr_rec_recon[l_idx].*,l_idx,null) --huho original: CALL split(glob_arr_rowid[l_idx],glob_arr_rec_recon[l_idx].*,l_idx,scrn) 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
				CALL show_sheet_balanced_state() #IF glob_bal_tot_amt = 0 = balanced

				--			BEFORE FIELD re_seq_no
				--				LET glob_o_seq_no = glob_arr_rec_recon[l_idx].re_seq_no

				--			AFTER FIELD re_seq_no
				--				LET glob_arr_rec_recon[l_idx].re_seq_no = glob_o_seq_no
				--				#DISPLAY glob_o_seq_no TO sr_recon[scrn].re_seq_no

			AFTER DISPLAY #input 
				LET quit_flag = true 

				#         ON KEY (control-w)
				#            CALL kandoohelp("")
		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
		ELSE 
			CONTINUE WHILE 
		END IF 

--		CALL show_sheet_balanced_state() #Show balanced/unbalanced state
		IF glob_bal_tot_amt = 0 THEN 

			#         OPEN WINDOW GC3w2 WITH FORM "U999" ATTRIBUTES(BORDER)
			#		CALL windecoration_u("U999")

			MENU "Sheet balanced" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GC3","menu-sheet-balance") 
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "SAVE" 
					#COMMAND "Close" "Close this Sheet "
					CALL update_part(false) 
					LET glob_recon_cshbk = false 
					EXIT MENU 

				ON ACTION "Hold" 
					#COMMAND "Hold " " Save Changes FOR later Editing"
					CALL update_part(true) 
					LET glob_recon_cshbk = false 
					EXIT MENU 

				ON ACTION "ACCEPT" 
					#COMMAND "RETURN " " RETURN TO Edit "
					LET glob_recon_cshbk = true 
					EXIT MENU 

				ON ACTION "CANCEL" 
					#COMMAND KEY(interrupt,"E")"Exit "
					#        " Discard Changes & EXIT PROGRAM"
					LET glob_recon_cshbk = false 
					EXIT MENU 

					--				COMMAND KEY (control-w)
					--					CALL kandoohelp("")

			END MENU 

		ELSE 
			#         OPEN WINDOW GC3w2 WITH FORM "U999" ATTRIBUTES(BORDER)
			#		CALL windecoration_u("U999")


			MENU "Out Of Balance " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GC3","menu-out-of-balance") 
					
				COMMAND "Hold" "Save Changes FOR later editing" 
					CALL update_part(true) 
					LET glob_recon_cshbk = false 
					EXIT MENU 

				COMMAND "ACCEPT" "RETURN TO Edit" 
					LET glob_recon_cshbk = true 
					EXIT MENU 

				COMMAND "CANCEL" "Discard Changes & EXIT PROGRAM" 
					LET glob_recon_cshbk = false 
					EXIT MENU 
					--				COMMAND KEY (control-w)
					--					CALL kandoohelp("")
			END MENU 
		END IF 
		#      CLOSE WINDOW GC3w2
		LET quit_flag = false 
		LET int_flag = false 
	END WHILE 
	#---------------------------------------------------------------------------

	CLOSE WINDOW g137 
	WHENEVER ERROR stop 

END FUNCTION 



############################################################
# FUNCTION load_array()
#
#
############################################################
FUNCTION load_array() 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_dr_tot_amt = 0 
	LET glob_cr_tot_amt = 0 
	LET glob_bal_tot_amt = 0 
	LET l_idx = 0 
	LET glob_op_bal_amt = glob_rec_bank.state_bal_amt 
	DECLARE c_recon CURSOR FOR 
	SELECT * 
	FROM t_recon 
	ORDER BY re_seq_no, 
	re_type, 
	re_ref, 
	re_date 
	FOREACH c_recon INTO glob_rowid,glob_rec_recon.* 
		LET l_idx = l_idx + 1 
		LET glob_arr_rowid[l_idx] = glob_rowid 
		LET glob_arr_rec_recon[l_idx].re_seq_no = glob_rec_recon.re_seq_no 
		LET glob_arr_rec_recon[l_idx].re_date = glob_rec_recon.re_date 
		LET glob_arr_rec_recon[l_idx].re_type = glob_rec_recon.re_type 
		LET glob_arr_rec_recon[l_idx].re_ref = glob_rec_recon.re_ref 
		LET glob_arr_rec_recon[l_idx].re_desc = glob_rec_recon.re_desc 
		LET glob_arr_rec_recon[l_idx].re_debit = glob_rec_recon.re_debit 
		LET glob_arr_rec_recon[l_idx].re_cred = glob_rec_recon.re_cred 
		IF glob_arr_rec_recon[l_idx].re_seq_no != glob_max_no THEN 
			LET glob_next_seq_no = glob_arr_rec_recon[l_idx].re_seq_no 
			CALL upd_bal(l_idx) 
		END IF 
--		IF l_idx = 1200 THEN 
--			LET l_msgresp = kandoomsg("U",6100,l_idx) 
--			EXIT FOREACH 
--		END IF 
	END FOREACH 

	LET glob_next_seq_no = glob_next_seq_no + 1 

	RETURN l_idx 
END FUNCTION 


############################################################
# FUNCTION unload_array()
#
#
############################################################
FUNCTION unload_array() 
	DEFINE i SMALLINT 

	BEGIN WORK 
		DELETE FROM t_recon 
		OPEN c_ins_recon 
		FOR i = 1 TO arr_count() 
			PUT c_ins_recon FROM glob_arr_rowid[i], 
			glob_arr_rec_recon[i].* 
		END FOR 
		CLOSE c_ins_recon 
	COMMIT WORK 
END FUNCTION 


############################################################
# FUNCTION upd_bal(p_idx)
#
#
############################################################
FUNCTION upd_bal(p_idx) 
	DEFINE p_idx SMALLINT 

	IF glob_arr_rec_recon[p_idx].re_debit IS NOT NULL THEN 
		LET glob_dr_tot_amt = glob_dr_tot_amt + glob_arr_rec_recon[p_idx].re_debit 
	END IF 

	IF glob_arr_rec_recon[p_idx].re_cred IS NOT NULL THEN 
		LET glob_cr_tot_amt = glob_cr_tot_amt + glob_arr_rec_recon[p_idx].re_cred 
	END IF 

	LET glob_bal_tot_amt = glob_op_bal_amt 
	+ glob_cr_tot_amt 
	- (glob_dr_tot_amt + glob_bal_amt) 

	DISPLAY 
	glob_bal_tot_amt, 
	glob_cr_tot_amt, 
	glob_dr_tot_amt 
	TO 
	bal_tot_amt, 
	cr_tot_amt, 
	dr_tot_amt 

END FUNCTION 


############################################################
# FUNCTION res_bal(p_idx)
#
#
############################################################
FUNCTION res_bal(p_idx) 
	DEFINE p_idx SMALLINT 

	###  Resets balance AFTER un-ticking a line
	IF glob_arr_rec_recon[p_idx].re_debit IS NOT NULL THEN 
		LET glob_dr_tot_amt = glob_dr_tot_amt - glob_arr_rec_recon[p_idx].re_debit 
	END IF 
	IF glob_arr_rec_recon[p_idx].re_cred IS NOT NULL THEN 
		LET glob_cr_tot_amt = glob_cr_tot_amt - glob_arr_rec_recon[p_idx].re_cred 
	END IF 
	LET glob_bal_tot_amt = glob_op_bal_amt 
	+ glob_cr_tot_amt 
	- (glob_dr_tot_amt + glob_bal_amt) 
	DISPLAY 
	glob_bal_tot_amt, 
	glob_cr_tot_amt, 
	glob_dr_tot_amt 
	TO 
	bal_tot_amt, 
	cr_tot_amt, 
	dr_tot_amt 

END FUNCTION 


############################################################
# FUNCTION update_part(p_hold)
#
# Updates Reconciled columns in the tables Banking AND Cheque
# FROM the rows in the ARRAY glob_arr_rec_recon which have been reconciled.
# IF the parameter p_hold IS SET, sets the cols rec_part TO "Y".
# IF the parameter p_hold IS NOT SET, UPDATE the bank table,
# incrementing the statement number AND replacing the
# closing balance. Also inserts the opening AND closing balance
# rows INTO table banking
############################################################
FUNCTION update_part(p_hold) 
	DEFINE p_hold SMALLINT 
	DEFINE l_status_rec_part char(1) 
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	GOTO bypass 
	LABEL recovery: 
	LET glob_continue = error_recover (glob_err_message, status) 
	IF glob_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LOCK TABLE cheque in share MODE 
		LOCK TABLE banking in share MODE 
		IF p_hold THEN 
			LET l_status_rec_part = "Y" 
		ELSE 
			LET l_status_rec_part = NULL 
		END IF 


		FOR i = 1 TO glob_arr_rec_recon.getSize() 
			IF glob_arr_rec_recon[i].re_type = "EF" THEN 
				IF glob_arr_rec_recon[i].re_seq_no = glob_max_no THEN 
					UPDATE cheque 
					SET rec_state_num = null, 
					rec_line_num = null, 
					part_recon_flag = NULL 
					WHERE eft_run_num = glob_arr_rec_recon[i].re_ref 
				ELSE 
					UPDATE cheque 
					SET rec_state_num = glob_rec_bank.sheet_num, 
					rec_line_num = glob_arr_rec_recon[i].re_seq_no, 
					part_recon_flag = l_status_rec_part 
					WHERE eft_run_num = glob_arr_rec_recon[i].re_ref 
				END IF 
			END IF 
			IF glob_arr_rec_recon[i].re_type = "AP" THEN 
				LET glob_err_message= "Updating cheque" 
				IF glob_arr_rec_recon[i].re_seq_no = glob_max_no THEN 
					UPDATE cheque 
					SET rec_state_num = null, 
					rec_line_num = null, 
					part_recon_flag = NULL 
					WHERE rowid = glob_arr_rowid[i] 
				ELSE 
					UPDATE cheque 
					SET rec_state_num = glob_rec_bank.sheet_num, 
					rec_line_num = glob_arr_rec_recon[i].re_seq_no, 
					part_recon_flag = l_status_rec_part 
					WHERE rowid = glob_arr_rowid[i] 
				END IF 
			ELSE 
				LET glob_err_message= "Updating banking" 
				IF glob_arr_rec_recon[i].re_seq_no = glob_max_no THEN 
					UPDATE banking 
					SET bk_sh_no = null, 
					bk_seq_no = null, 
					bk_rec_part = NULL 
					WHERE rowid = glob_arr_rowid[i] 
				ELSE 
					UPDATE banking 
					SET bk_sh_no = glob_rec_bank.sheet_num, 
					bk_seq_no = glob_arr_rec_recon[i].re_seq_no, 
					bk_rec_part = l_status_rec_part 
					WHERE rowid = glob_arr_rowid[i] 
				END IF 
			END IF 
		END FOR 
		IF NOT p_hold THEN 

			LET glob_clo_base_bal_amt = work_out_base_amts() 

			LET glob_err_message= "Updating bank" 
			UPDATE bank 
			SET sheet_num = glob_rec_bank.sheet_num, 
			state_bal_amt = glob_bal_amt, 
			state_base_bal_amt = glob_clo_base_bal_amt 
			WHERE bank_code = glob_rec_bank.bank_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 



			LET glob_err_message= "Inserting Balance amounts" 

IF get_debug() THEN
	LET l_msg = "INSERT INTO banking ("
	LET l_msg = trim(l_msg), "bk_cmpy," 
	LET l_msg = trim(l_msg), "bk_acct," 
	LET l_msg = trim(l_msg), "bk_type," 
	LET l_msg = trim(l_msg), "bk_desc," 
	LET l_msg = trim(l_msg), "bk_sh_no," 
	LET l_msg = trim(l_msg), "bk_seq_no," 
	LET l_msg = trim(l_msg), "bk_cred," 
	LET l_msg = trim(l_msg), "base_cred_amt," 
	LET l_msg = trim(l_msg), "balance_date," 
	LET l_msg = trim(l_msg), "bk_enter," 
	LET l_msg = trim(l_msg), "doc_num)" 

	LET l_msg = trim(l_msg), " VALUES ("
	LET l_msg = trim(l_msg),	"'",trim(glob_rec_kandoouser.cmpy_code), "'," 
	LET l_msg = trim(l_msg),	"'",trim(glob_rec_bank.acct_code),"'," 
	LET l_msg = trim(l_msg),	"'","XO","'," #opening balance 
	LET l_msg = trim(l_msg),	"'","Opening balance", "'," 
	LET l_msg = trim(l_msg),	glob_rec_bank.sheet_num, "," 
	LET l_msg = trim(l_msg),	0, "," 
	LET l_msg = trim(l_msg),	glob_op_bal_amt, "," 
	LET l_msg = trim(l_msg),	glob_op_base_bal_amt, "," 
	LET l_msg = trim(l_msg),	"'", trim(today), "'"
	LET l_msg = trim(l_msg),	"'", trim(glob_rec_kandoouser.sign_on_code) , "'" 
	LET l_msg = trim(l_msg),	0
	LET l_msg = trim(l_msg),	")" 
	DISPLAY l_msg
END IF

			INSERT INTO banking ( 
			bk_cmpy, 
			bk_acct, 
			bk_type, 
			bk_desc, 
			bk_sh_no, 
			bk_seq_no, 
			bk_cred, 
			base_cred_amt, 
			balance_date, 
			bk_enter, 
			doc_num) 
			VALUES ( 
			glob_rec_kandoouser.cmpy_code, 
			glob_rec_bank.acct_code, 
			"XO", #opening balance 
			"Opening balance", 
			glob_rec_bank.sheet_num, 
			0, 
			glob_op_bal_amt, 
			glob_op_base_bal_amt, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			0) 

			INSERT INTO banking ( bk_cmpy, 
			bk_acct, 
			bk_type, 
			bk_desc, 
			bk_sh_no, 
			bk_seq_no, 
			bk_debit, 
			base_debit_amt, 
			balance_date, 
			bk_enter, 
			doc_num) 
			VALUES ( glob_rec_kandoouser.cmpy_code, 
			glob_rec_bank.acct_code, 
			"XC", #opening balance 
			"Closing balance", 
			glob_rec_bank.sheet_num, 
			0, 
			glob_bal_amt, 
			glob_clo_base_bal_amt, 
			today, 
			glob_rec_kandoouser.sign_on_code, 
			0) 
		END IF 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 


############################################################
# FUNCTION split(p_rowid, p_rec_recon, p_idx1, p_scrn1 )
#
# Special FUNCTION TO split a banking. Used WHEN banking has
# got out of phase, AND WHERE actual banking was NOT done
# according TO the bank deposit slips, usually at
# installation OR WHEN something has gone wrong.
############################################################
FUNCTION split(p_rowid, p_rec_recon, p_idx1, p_scrn1 ) 
	DEFINE p_rowid INTEGER 
	DEFINE p_rec_recon RECORD 
		seq_no SMALLINT, 
		bank_date DATE, 
		type_ind char(2), 
		ref_num INTEGER, 
		desr_text char(30), 
		debit_amt decimal(14,2), 
		cred_amt decimal(14,2) 
	END RECORD 
	DEFINE p_idx1 SMALLINT # the l_idx FROM the prev. ARRAY 
	DEFINE p_scrn1 SMALLINT # the scrn FROM the prev. ARRAY 

	DEFINE l_arr_rec_split ARRAY [10] OF 
	RECORD 
		bank_date DATE, 
		bk_desc char(30), 
		cred_amt decimal(10,2) 
	END RECORD 
	DEFINE l_arr_split_rowid array[10] OF INTEGER 
	DEFINE l_tot_amt decimal(10,2) 
	DEFINE l_remain_amt decimal(10,2) 
	#DEFINE l_ans CHAR(1) #not used
	DEFINE l_split_cnt SMALLINT #huho scrn, 
	DEFINE i SMALLINT #huho scrn, 
	DEFINE l_idx SMALLINT #huho scrn, 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g144 with FORM "G144" 
	CALL windecoration_g("G144") 

	LET l_remain_amt = p_rec_recon.cred_amt 
	DISPLAY p_rec_recon.bank_date, 
	p_rec_recon.cred_amt, 
	l_remain_amt 
	TO orig_date, 
	deposit_amt, 
	l_remain_amt 
	FOR i = 1 TO 10 
		INITIALIZE l_arr_rec_split[i].* TO NULL 
	END FOR 
	LET l_arr_rec_split[1].bank_date = p_rec_recon.bank_date 
	LET l_arr_rec_split[1].bk_desc = p_rec_recon.desr_text 
	LET l_arr_rec_split[1].cred_amt = p_rec_recon.cred_amt 
	CALL set_count(1) 

	INPUT ARRAY l_arr_rec_split WITHOUT DEFAULTS FROM sr_split.* attributes(unbuffered) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC3","inp-arr-split") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

		AFTER FIELD bk_bankdt 
			IF l_idx = 1 THEN 
				LET l_arr_rec_split[1].bank_date = p_rec_recon.bank_date 
				#DISPLAY l_arr_rec_split[1].bank_date
				#     TO sr_split[scrn].bk_bankdt
			END IF 
			IF l_arr_rec_split[l_idx].cred_amt IS NULL THEN 
				LET l_arr_rec_split[l_idx].cred_amt = l_remain_amt 
				#DISPLAY l_remain_amt
				#     TO sr_split[scrn].bk_cred
			END IF 

		BEFORE FIELD bk_desc 
			IF l_idx = 1 THEN 
				NEXT FIELD bk_cred 
			END IF 
			IF l_arr_rec_split[l_idx].bk_desc IS NULL THEN 
				LET l_arr_rec_split[l_idx].bk_desc = "Manually split" 
			END IF 
			#DISPLAY l_arr_rec_split[l_idx].bk_desc
			#     TO sr_split[scrn].bk_desc

		AFTER FIELD bk_cred 
			LET l_tot_amt = 0 
			FOR i = 1 TO arr_count() 
				IF l_arr_rec_split[i].bank_date IS NOT NULL 
				AND l_arr_rec_split[i].cred_amt IS NOT NULL THEN 
					LET l_tot_amt = l_tot_amt + l_arr_rec_split[i].cred_amt 
				END IF 
			END FOR 
			IF l_tot_amt > p_rec_recon.cred_amt THEN 
				#LET l_msgresp = kandoomsg("G",9064,"") 
				ERROR kandoomsg2("G",9064,"")
				NEXT FIELD bk_bankdt 
			END IF 
			LET l_remain_amt = p_rec_recon.cred_amt - l_tot_amt 
			DISPLAY l_remain_amt TO remain_amt 

		AFTER INPUT 
			IF l_remain_amt != 0 THEN 
				#LET l_msgresp = kandoomsg("G",9064,"") 
				ERROR kandoomsg2("G",9064,"")
				NEXT FIELD bk_bankdt 
			END IF 
			LET l_split_cnt = arr_count() 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW g144 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_split_cnt = arr_count() 
	IF glob_recon_cnt + arr_count() > 1200 THEN 
		#LET l_msgresp = kandoomsg("G",9091,"") 
		CALL msgcontinue("",kandoomsg2("G",9091,""))
		RETURN 
	END IF 

	GOTO bypass 
	LABEL recovery: 

	LET glob_continue = error_recover (glob_err_message, status) 
	IF glob_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET glob_err_message=" Updating banking" 

	BEGIN WORK 

		UPDATE banking 
		SET bk_cred = l_arr_rec_split[1].cred_amt 
		WHERE rowid = p_rowid 

		FOR i = 2 TO l_split_cnt 
			IF l_arr_rec_split[i].bank_date IS NOT NULL 
			AND l_arr_rec_split[i].cred_amt IS NOT NULL THEN 

				INSERT INTO banking ( bk_cmpy, 
				bk_acct, 
				bk_type, 
				bk_bankdt, 
				bk_desc, 
				bk_cred, 
				base_cred_amt, 
				balance_date, 
				bk_enter, 
				doc_num) 
				VALUES ( glob_rec_kandoouser.cmpy_code, 
				glob_rec_bank.acct_code, 
				p_rec_recon.type_ind, 
				l_arr_rec_split[i].bank_date, 
				l_arr_rec_split[i].bk_desc, 
				l_arr_rec_split[i].cred_amt, 
				l_arr_rec_split[i].cred_amt, 
				today, 
				p_kandoouser_sign_on_code, 
				0) 

				LET l_arr_split_rowid[i] = 
				sqlca.sqlerrd[6] #### rowid OF inserted ROW 
			END IF 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop ### we only INSERT split_no -1 ROWS 

	LET l_split_cnt = l_split_cnt -1 ### as the initial ROW already 
	### existed in the main Array
	FOR i = glob_recon_cnt TO p_idx1 + 1 step -1 
		LET glob_arr_rec_recon[i + l_split_cnt].* = glob_arr_rec_recon[i].* 
		LET glob_arr_rowid[i + l_split_cnt] = glob_arr_rowid[i] 
	END FOR 

	LET glob_recon_cnt = glob_recon_cnt + l_split_cnt 
	LET glob_arr_rec_recon[p_idx1].re_cred = l_arr_rec_split[1].cred_amt 
	#DISPLAY glob_arr_rec_recon[p_idx1].*
	#     TO sr_recon[p_scrn1].*

	FOR i = 2 TO (l_split_cnt + 1) 
		IF l_arr_rec_split[i].bank_date IS NOT NULL 
		AND l_arr_rec_split[i].cred_amt IS NOT NULL THEN 
			LET p_idx1 = p_idx1 + 1 
			#LET p_scrn1 = p_scrn1 + 1
			LET glob_arr_rec_recon[p_idx1].re_seq_no = glob_max_no 
			LET glob_arr_rec_recon[p_idx1].re_date = l_arr_rec_split[i].bank_date 
			LET glob_arr_rec_recon[p_idx1].re_type = "CD" 
			LET glob_arr_rec_recon[p_idx1].re_ref = NULL 
			LET glob_arr_rec_recon[p_idx1].re_desc = l_arr_rec_split[i].bk_desc 
			LET glob_arr_rec_recon[p_idx1].re_debit = 0 
			LET glob_arr_rec_recon[p_idx1].re_cred = l_arr_rec_split[i].cred_amt 
			LET glob_arr_rowid[p_idx1] = l_arr_split_rowid[i] 
		END IF 
	END FOR 
	CALL set_count(glob_recon_cnt) 
END FUNCTION 



############################################################
# FUNCTION direct_in()
#
#
############################################################
FUNCTION direct_in() 
	DEFINE l_found_it SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g175 with FORM "G175" 
	CALL windecoration_g("G175") 

	DISPLAY 
	glob_bal_tot_amt, 
	glob_cr_tot_amt, 
	glob_dr_tot_amt 
	TO 
	bal_tot_amt, 
	cr_tot_amt, 
	dr_tot_amt 

	WHILE true 
		CLEAR FORM 
		#LET l_msgresp=kandoomsg("G",1064,"Cheque number TO reconcile - del TO RETURN")
		MESSAGE kandoomsg2("G",1064,"Cheque number TO reconcile - del TO RETURN")

		OPTIONS INPUT NO WRAP
		INPUT glob_rec_recon.re_ref WITHOUT DEFAULTS FROM cheq_code 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GC3","inp-recon") 
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END INPUT 
		OPTIONS INPUT WRAP

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		LET l_found_it = false 
		FOR i = 1 TO glob_recon_cnt 
			IF glob_arr_rec_recon[i].re_ref = glob_rec_recon.re_ref 
			AND glob_arr_rec_recon[i].re_type = "AP" THEN 
				LET l_found_it = true 
				EXIT FOR 
			END IF 
		END FOR 

		IF NOT l_found_it THEN 
			ERROR "Could not find cheque with the reference ", trim(glob_rec_recon.re_ref ) 
			SLEEP 3 
			#LET l_msgresp = kandoomsg("P",9130,"") 
			ERROR kandoomsg2("P",9130,"")
			CONTINUE WHILE 
		END IF 

		DISPLAY glob_arr_rec_recon[i].* TO sr_recon.* 

		#LET l_msgresp = kandoomsg("G",1013,"") 
		MESSAGE kandoomsg2("G",1013,"")

		INPUT BY NAME glob_arr_rec_recon[i].re_seq_no WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GC3","inp-recon2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "F1-Upd.Bal." --on KEY (f1) 
				IF glob_arr_rec_recon[i].re_seq_no = glob_max_no THEN 
					LET glob_arr_rec_recon[i].re_seq_no = glob_next_seq_no 
					LET glob_next_seq_no = glob_next_seq_no + 1 
					DISPLAY glob_arr_rec_recon[i].re_seq_no 
					TO sr_recon.re_seq_no 
					CALL upd_bal(i) 
					LET glob_o_seq_no = glob_arr_rec_recon[i].re_seq_no 
				END IF 

			ON ACTION "F2-Res.Bal." --on KEY (f2) 
				IF glob_arr_rec_recon[i].re_seq_no != glob_max_no THEN 
					LET glob_arr_rec_recon[i].re_seq_no = glob_max_no 
					DISPLAY glob_max_no TO sr_recon.re_seq_no 
					CALL res_bal(i) 
				END IF 
				LET glob_o_seq_no = glob_arr_rec_recon[i].re_seq_no 

			BEFORE FIELD re_seq_no 
				LET glob_o_seq_no = glob_arr_rec_recon[i].re_seq_no 

			AFTER FIELD re_seq_no 
				LET glob_arr_rec_recon[i].re_seq_no = glob_o_seq_no 
				DISPLAY glob_o_seq_no TO sr_recon.re_seq_no 
				EXIT INPUT 

				#         ON KEY (control-w)
				#            CALL kandoohelp("")
		END INPUT 

		LET int_flag = false 
		LET quit_flag = false 

	END WHILE 
	#-------------------------------------------- END WHILE
	CLOSE WINDOW g175 
END FUNCTION 


############################################################
# FUNCTION work_out_base_amts()
#
# convert by the originating conversion INTO base currency
# cashreceipts & cheques
############################################################
FUNCTION work_out_base_amts() 
	DEFINE l_amt DECIMAL (16,4) 
	DEFINE l_credit DECIMAL (16,4) 
	DEFINE l_debit DECIMAL (16,4) 
	DEFINE l_tot_amt DECIMAL (16,4) 
	DEFINE l_loop SMALLINT 

	LET l_tot_amt = 0 

	FOR l_loop = 1 TO glob_arr_rec_recon.getSize() --glob_recon_cnt 
		IF glob_arr_rec_recon[l_loop].re_seq_no != glob_max_no THEN 

			LET l_amt = 0 

			IF glob_arr_rec_recon[l_loop].re_type = "AP" THEN 

				LET glob_err_message= "converting cheques" 

				SELECT sum (cheque.net_pay_amt / cheque.conv_qty) 
				INTO l_amt 
				FROM cheque 
				WHERE cheque.rowid = glob_arr_rowid[l_loop] 

				LET l_amt = l_amt * -1 

			ELSE 

				LET glob_err_message= "converting Cashreceipts/direct batches" 


				# base amounts FOR direct batches & cashreceipts
				# will be on the file.

				SELECT base_debit_amt, base_cred_amt 
				INTO l_debit, l_credit 
				FROM banking 
				WHERE banking.rowid = glob_arr_rowid[l_loop] 

				IF l_debit IS NULL THEN 
					LET l_debit = 0 
				END IF 

				IF l_credit IS NULL THEN 
					LET l_credit = 0 
				END IF 

				LET l_amt = l_credit - l_debit 

			END IF 
			IF l_amt IS NOT NULL THEN 
				LET l_tot_amt = l_tot_amt + l_amt 
				LET l_amt = 0 # reinit variable. 
			END IF 
		END IF 
	END FOR 

	LET l_tot_amt = glob_op_base_bal_amt + l_tot_amt 

	RETURN l_tot_amt 
END FUNCTION 
