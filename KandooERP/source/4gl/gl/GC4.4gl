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
#This program allows the user TO examine old bank statements
{! PRAGMA EMULATE INSERT CURSOR FOR curs_ins_recon !}

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC4_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_recon 
	RECORD 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit money(12,2), 
		re_cred money(12,2) 
	END RECORD 
	DEFINE glob_arr_rec_recon DYNAMIC ARRAY OF RECORD #array[500] OF RECORD 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type char(2), 
		re_ref INTEGER, 
		re_desc char(30), 
		re_debit money(12,2), 
		re_cred money(12,2) 
	END RECORD 
	DEFINE glob_sql_stmt char(200) 
	DEFINE glob_rowid INTEGER 
	DEFINE glob_max_no INTEGER #huho scrn 
	DEFINE glob_idx INTEGER #huho scrn 
	DEFINE glob_next_seq_no INTEGER 
	DEFINE i INTEGER 
	DEFINE glob_re_do INTEGER 
	DEFINE glob_arr_rowid DYNAMIC ARRAY OF INTEGER #array[500] OF INTEGER 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
	DEFINE glob_cheque_curr_code LIKE cheque.currency_code 
	DEFINE glob_cheque_conv_qty LIKE cheque.conv_qty 
	DEFINE glob_added SMALLINT 
	DEFINE glob_cnt SMALLINT 
	DEFINE glob_clo_bal_amt money(12,2) 
	DEFINE glob_op_bal_amt money(12,2) 
	DEFINE glob_dr_tot_amt money(12,2) 
	DEFINE glob_cr_tot_amt money(12,2) 
	DEFINE glob_bal_tot_amt money(12,2) 

	DEFINE glob_sheet_num SMALLINT 
	DEFINE glob_valid_sheet_flag char(1) 
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

	CALL setModuleId("GC4") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	--	SELECT glparms.* INTO glob_rec_glparms.* FROM glparms
	--	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	--	AND glparms.key_code = "1"

	--	IF glob_rec_glparms.cash_book_flag != "Y" THEN

	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		LET l_msgresp = kandoomsg("G",9502,"") 
		#9502 Cashbook NOT installed;  See your System Administrator.
		EXIT PROGRAM 
	END IF 

	CREATE temp TABLE t_recon ( 
	re_rowid INTEGER, 
	re_seq_no SMALLINT, 
	re_date DATE, 
	re_type char(2), 
	re_ref INTEGER, 
	re_desc char(30), 
	re_debit money(12,2), 
	re_cred money(12,2) 
	) with no LOG 
	LET glob_added = 0 

	OPEN WINDOW g136 with FORM "G136" 
	CALL windecoration_g("G136") 

	WHILE true 
		IF NOT doit() THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW g136 
END MAIN 


############################################################
# FUNCTION doit()
#
#
############################################################
FUNCTION doit() 
	DEFINE l_str STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_max_no = 999 

	INPUT BY NAME glob_rec_bank.bank_code, glob_rec_bank.sheet_num WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC4","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_bank.bank_code, 
			glob_rec_bank.acct_code 
			DISPLAY glob_rec_bank.bank_code TO bank_code 
			NEXT FIELD bank_code 

		AFTER FIELD bank_code 
			SELECT bank.* INTO glob_rec_bank.* FROM bank 
			WHERE bank.bank_code = glob_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("I",9226,"") 
				#9226 RECORD NOT found.
				NEXT FIELD bank_code 
			END IF 

			DISPLAY glob_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY glob_rec_bank.iban TO iban 

			LET glob_sheet_num = glob_rec_bank.sheet_num 

			#AFTER FIELD sheet_num --huho 25.10 NOT sure.. added because this will be used in SQL query later WITHOUT checking IF it's NULL
			#	IF glob_rec_bank.sheet_num IS NULL THEN
			#		NEXT FIELD sheet_num
			#	END IF
			#

			#   ON KEY (control-w)
			#      CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	--	LET glob_sql_stmt = "INSERT INTO t_recon VALUES (?,?,?,?,?,?,?,?)"  #currently 8 values (1+7)  # albo
	--	PREPARE sql_line FROM glob_sql_stmt                                                          # albo
	--	DECLARE curs_ins_recon CURSOR FOR sql_line                                                   # albo

	DECLARE curs_ins_recon CURSOR with HOLD FOR # albo 
	INSERT INTO t_recon VALUES 
	(glob_rowid, 
	glob_rec_recon.re_seq_no, 
	glob_rec_recon.re_date, 
	glob_rec_recon.re_type, 
	glob_rec_recon.re_ref, 
	glob_rec_recon.re_desc, 
	glob_rec_recon.re_debit, 
	glob_rec_recon.re_cred 
	) 

	LET glob_clo_bal_amt = 0 

	OPEN WINDOW g137 with FORM "G137" 
	CALL windecoration_g("G137") 

	LET glob_re_do = true 
	LET glob_valid_sheet_flag = "Y" 
	WHILE glob_re_do 
		IF glob_valid_sheet_flag = "Y" THEN 
			{loop FOR option TO SELECT next/previous sheet no in ON KEY F9, F10}
			LET glob_re_do = false 
			{first load cheques FROM cheque accounts payable AP}
			DELETE FROM t_recon 
			WHERE 1 = 1 
			BEGIN WORK 
				OPEN curs_ins_recon #huho.. there IS a mess, something FOR you eric - ON second iteration, CURSOR was closed in original sources 

				#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER"
				#DISPLAY "see gl/GC4.4gl"
				#EXIT PROGRAM (1)



				LET l_str = 
				" SELECT C.rowid, ", 
				" rec_line_num, ", 
				" cheq_date, ", 
				" cheq_code, ", 
				" name_text, ", 
				" net_pay_amt, ", 
				" C.currency_code, ", 
				" C.conv_qty ", 
				" FROM cheque C, outer vendor V ", 
				" WHERE C.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				" AND C.bank_acct_code = '", trim(glob_rec_bank.acct_code), "' " 

				--HuHo added this because if sheet_num was not a required field / was NULL
				IF glob_rec_bank.sheet_num IS NOT NULL THEN 
					LET l_str = trim(l_str), " AND rec_state_num = ", trim(glob_rec_bank.sheet_num), "" 
				END IF 

				LET l_str = trim(l_str), 
				" AND part_recon_flag IS NULL ", 
				" AND V.cmpy_code = C.cmpy_code ", 
				" AND V.vend_code = C.vend_code " 


				PREPARE wwe FROM l_str 
				DECLARE cb_2 CURSOR FOR wwe 

				OPEN cb_2 
				LET glob_cnt = 0 
				INITIALIZE glob_rec_recon.* TO NULL 

				FOREACH cb_2 INTO glob_rowid, 
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
					LET glob_cnt = glob_cnt + 1 
					LET glob_rec_recon.re_type = "AP" 
					PUT curs_ins_recon FROM glob_rowid, glob_rec_recon.* #currently 8 VALUES (1+7) 
				END FOREACH 


				{now load banking details FROM banking, CD deposits credit, BC Bank Charges debit}
				DECLARE cb_3 CURSOR FOR 
				SELECT rowid, bk_seq_no, bk_bankdt, bk_type, bk_desc, bk_debit, bk_cred 
				FROM banking 
				WHERE bk_cmpy = glob_rec_kandoouser.cmpy_code 
				AND bk_acct = glob_rec_bank.acct_code 
				AND bk_sh_no = glob_rec_bank.sheet_num 
				AND bk_rec_part IS NULL 
				OPEN cb_3 
				INITIALIZE glob_rec_recon.* TO NULL 

				FOREACH cb_3 INTO glob_rowid, glob_rec_recon.re_seq_no, glob_rec_recon.re_date, 
					glob_rec_recon.re_type, glob_rec_recon.re_desc, glob_rec_recon.re_debit, glob_rec_recon.re_cred 
					LET glob_cnt = glob_cnt + 1 
					PUT curs_ins_recon FROM glob_rowid, glob_rec_recon.* #currently 8 VALUES (1+7) 
				END FOREACH 

				CLOSE curs_ins_recon 
			COMMIT WORK 

			DECLARE cb_4 CURSOR FOR 
			SELECT * FROM t_recon 
			ORDER BY re_seq_no, re_type, re_date 
			LET glob_op_bal_amt = 0 
			LET glob_clo_bal_amt = 0 
			CALL load_array() 
			DISPLAY glob_op_bal_amt TO op_bal_amt 
			DISPLAY glob_clo_bal_amt TO clo_bal_amt 

			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			CALL set_count(glob_cnt) 
			DISPLAY glob_rec_bank TO sheet_num 
			DISPLAY glob_rec_bank.bank_code TO bank_code 
			DISPLAY glob_rec_bank.iban TO iban 

		END IF 
		LET glob_valid_sheet_flag = "Y" 
		LET l_msgresp = kandoomsg("G",1016,"") 

		#1016 F9 Previous statement;  F10 Next statement.
		--		INPUT ARRAY glob_arr_rec_recon WITHOUT DEFAULTS FROM sr_recon.* attributes(unbuffered)
		DISPLAY ARRAY glob_arr_rec_recon TO sr_recon.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","GC4","inp-arr-recon") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET glob_idx = arr_curr() 

				--			BEFORE FIELD re_seq_no
				--				LET glob_idx = arr_curr()
				--				#LET scrn = scr_line()
				--				#DISPLAY glob_arr_rec_recon[glob_idx].* TO sr_recon[scrn].*

				--			AFTER FIELD re_seq_no
				--				IF fgl_lastkey() = fgl_keyval("accept") THEN
				--					EXIT INPUT
				--				END IF
				--				IF (fgl_lastkey() = fgl_keyval("down")
				--				OR fgl_lastkey() = fgl_keyval("right")
				--				OR fgl_lastkey() = fgl_keyval("tab")
				--				OR fgl_lastkey() = fgl_keyval("RETURN"))
				--				AND arr_curr() = arr_count() THEN
				--					LET l_msgresp = kandoomsg("U",9001,"")
				--					#9001 There are no more rows in the direction you are going.
				--					NEXT FIELD re_seq_no
				--				END IF

				--				#AFTER ROW
				--				#   DISPLAY glob_arr_rec_recon[glob_idx].* TO sr_recon[scrn].*

			ON ACTION ("PREVIOUS SHEET") --ON KEY (f9) 
				LET l_msgresp = kandoomsg("G",1015,"") 
				#1015 Getting previous sheet.
				IF glob_rec_bank.sheet_num <= 1 THEN 
					LET glob_valid_sheet_flag = "N" 
					LET l_msgresp = kandoomsg("G",9065,"") 
					#9065 Cannot go past sheet number 1.
					LET l_msgresp = kandoomsg("G",1016,"") 
					#1016 F9 Previous statement;  F10 Next statement.
				ELSE 
					LET glob_valid_sheet_flag = "Y" 
					LET glob_rec_bank.sheet_num = glob_rec_bank.sheet_num - 1 
					LET glob_re_do = true 
					--					EXIT INPUT
					EXIT DISPLAY 
				END IF 

			ON ACTION ("NEXT SHEET") --ON KEY (f10) 
				LET l_msgresp = kandoomsg("G",1014,"") 
				#1014 Getting next sheet.
				IF (glob_rec_bank.sheet_num + 1) > glob_sheet_num THEN 
					LET glob_valid_sheet_flag = "N" 
					LET l_msgresp = kandoomsg("G",9066,glob_sheet_num) 
					#9066 No further statements issued last statement page:
					LET l_msgresp = kandoomsg("G",1016,"") 
					#1016 F9 Previous statement;  F10 Next statement.
				ELSE 
					LET glob_valid_sheet_flag = "Y" 
					LET glob_rec_bank.sheet_num = glob_rec_bank.sheet_num + 1 
					LET glob_re_do = true 
					--					EXIT INPUT
					EXIT DISPLAY 

				END IF 

			AFTER DISPLAY 
				IF int_flag OR quit_flag THEN 
					LET glob_re_do = false 
					LET int_flag = false 
					LET quit_flag = false 
				END IF 
				EXIT DISPLAY 
				--			ON KEY (control-w)
				--				CALL kandoohelp("")
		END DISPLAY 

	END WHILE 

	CLOSE WINDOW g137 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION load_array()
#
#
############################################################
FUNCTION load_array() 
	LET glob_dr_tot_amt = 0 
	LET glob_cr_tot_amt = 0 
	LET glob_bal_tot_amt = 0 
	{loads the arrays glob_arr_rowid AND glob_arr_rec_recon FROM the temporary table t_recon}
	OPEN cb_4 
	LET glob_idx = 0 

	FOREACH cb_4 INTO glob_rowid, glob_rec_recon.* 
		IF glob_rec_recon.re_type = "XO" THEN # opening balance row, don't PUT 
			# it INTO the array
			LET glob_op_bal_amt = glob_rec_recon.re_cred 
			LET glob_cnt = glob_cnt - 1 #glob_cnt has no OF ROWS in ARRAY 
			CONTINUE FOREACH 
		END IF 
		IF glob_rec_recon.re_type = "XC" THEN # closing balance row, don't PUT it INTO 
			# the array
			LET glob_clo_bal_amt = glob_rec_recon.re_debit 
			LET glob_cnt = glob_cnt - 1 
			CONTINUE FOREACH 
		END IF 

		LET glob_idx = glob_idx + 1 
		LET glob_arr_rowid[glob_idx] = glob_rowid 
		LET glob_arr_rec_recon[glob_idx].re_seq_no = glob_rec_recon.re_seq_no 
		LET glob_arr_rec_recon[glob_idx].re_date = glob_rec_recon.re_date 
		LET glob_arr_rec_recon[glob_idx].re_type = glob_rec_recon.re_type 
		LET glob_arr_rec_recon[glob_idx].re_ref = glob_rec_recon.re_ref 
		LET glob_arr_rec_recon[glob_idx].re_desc = glob_rec_recon.re_desc 
		LET glob_arr_rec_recon[glob_idx].re_debit = glob_rec_recon.re_debit 
		LET glob_arr_rec_recon[glob_idx].re_cred = glob_rec_recon.re_cred 
		IF glob_arr_rec_recon[glob_idx].re_seq_no <> glob_max_no THEN 
			LET glob_next_seq_no = glob_arr_rec_recon[glob_idx].re_seq_no 
			IF glob_arr_rec_recon[glob_idx].re_debit IS NOT NULL THEN 
				LET glob_dr_tot_amt = glob_dr_tot_amt + glob_arr_rec_recon[glob_idx].re_debit 
			END IF 
			IF glob_arr_rec_recon[glob_idx].re_cred IS NOT NULL THEN 
				LET glob_cr_tot_amt = glob_cr_tot_amt + glob_arr_rec_recon[glob_idx].re_cred 
			END IF 
		END IF 
	END FOREACH 

	LET glob_bal_tot_amt = 
	glob_op_bal_amt + glob_cr_tot_amt - (glob_dr_tot_amt + glob_clo_bal_amt) 
	DISPLAY glob_bal_tot_amt TO bal_tot_amt 
	DISPLAY glob_cr_tot_amt TO cr_tot_amt 
	DISPLAY glob_dr_tot_amt TO dr_tot_amt 

	LET glob_next_seq_no = glob_next_seq_no + 1 

	CLOSE cb_4 

END FUNCTION 
