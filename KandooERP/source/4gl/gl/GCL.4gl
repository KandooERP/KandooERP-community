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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCL_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
############################################################
# FUNCTION GCL_main()
#
# GCL  Loads bank statement details directly FROM an interface
#              file provided by banking groups. Transactions will also
#              be reconciled WHERE sufficient information exists.
############################################################
FUNCTION GCL_main() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GCL") 

	CREATE temp TABLE t_stmtload(stmt_line char(512)) with no LOG 
	CALL create_tables() 
	CALL create_table("bankstatement","t_stmthead","","Y") 

	OPEN WINDOW G419 with FORM "G419" 
	CALL windecoration_g("G419") 
	
	MENU " Bank Statement load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GCL","menu-bank-statement-load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Load"		#COMMAND "Load" " SELECT Bank AND Interface file details"
			CALL enter_bankgroup() RETURNING l_rec_banktype.* 
			IF l_rec_banktype.type_code IS NOT NULL THEN 
				IF load_statement(l_rec_banktype.*) THEN 
					CASE l_rec_banktype.stmt_format_ind 
						WHEN 1 
							CALL anz_stmt_load(l_rec_banktype.type_code) 
						WHEN 2 
							MESSAGE kandoomsg2("G",9152,"") 								#9152 Check file FORMAT ..
						WHEN 3 
							MESSAGE kandoomsg2("G",9152,"") 								#9152 Check file FORMAT ..
						WHEN 4 
							MESSAGE kandoomsg2("G",9152,"") 								#9152 Check file FORMAT ..
						WHEN 5 
							CALL nab_stmt_load(l_rec_banktype.type_code) 
						WHEN 6 
							MESSAGE kandoomsg2("G",9152,"") 								#9152 Check file FORMAT ..
						WHEN 7 
							CALL westpac_stmt_load(l_rec_banktype.type_code) 
						OTHERWISE 
							ERROR kandoomsg2("G",5003,"")	#5003" Bank Type Statement Load Format Not SetUp - GZT"
							SLEEP 3 #?? should we not exit here ?
					END CASE 
					
					CALL upd_stmts() 
					
					UPDATE banktype 
					SET stmt_path_text = l_rec_banktype.stmt_path_text, 
					stmt_file_text = l_rec_banktype.stmt_file_text 
					WHERE type_code = l_rec_banktype.type_code 
					
					HIDE option "Load" 

				END IF 
			END IF 


		ON ACTION "Reconcile" 				#COMMAND "Reconcile" " Reconcile bank statement"
			CALL run_prog("GCE","","","","") 

		ON ACTION "PRINT MANAGER" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" 				#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G419 
END FUNCTION 
############################################################
# END FUNCTION GCL_main()
############################################################


############################################################
# FUNCTION upd_stmts()
#
#
############################################################
FUNCTION upd_stmts() 
	DEFINE l_rec_bankstatement RECORD LIKE bankstatement.*
	DEFINE l_rec_banking RECORD LIKE banking.*
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_sheet_num LIKE bankstatement.sheet_num
	DEFINE l_line_cnt INTEGER
	DEFINE l_line_tot INTEGER
	DEFINE l_err_message char(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_line_cnt = 0 
	LET l_line_tot = 0 
	SELECT count(*) INTO l_line_tot FROM t_stmthead 
	IF l_line_tot = 0 THEN 
		RETURN 
	END IF 

	OPEN WINDOW w1_gcl with FORM "U999" attributes(border) 
	CALL windecoration_u("U999") 

	LET l_msgresp = kandoomsg("U",1005,"") 
	#1005 " Updating Database - Please wait"
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status)!= "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_line_cnt = 0 
		LET l_err_message = "Locking Banking tables" 
		LOCK TABLE bankstatement in share MODE 
		DECLARE stmt_curs CURSOR FOR 
		SELECT * FROM t_stmthead 
		ORDER BY bank_code,sheet_num,seq_num 
		FOREACH stmt_curs INTO l_rec_bankstatement.* 
			LET l_line_cnt = l_line_cnt + 1 
			DISPLAY " Updating Line ",l_line_cnt," OF ",l_line_tot TO lblabel2 

			IF l_rec_bankstatement.entry_type_code = "SH" THEN 
				##
				## Need TO re-allocate the sheet number AT the database UPDATE stage
				## AND NOT AT load time TO handle the CASE WHERE one account
				## may have multiple sheets in one file.
				##
				LET l_sheet_num = NULL 
				SELECT (max(sheet_num)+1) INTO l_sheet_num FROM bankstatement 
				WHERE cmpy_code = l_rec_bankstatement.cmpy_code 
				AND bank_code = l_rec_bankstatement.bank_code 
				IF l_sheet_num IS NULL THEN 
					LET l_sheet_num = 1 
				END IF 
				LET l_rec_bankstatement.recon_ind = "1" 
			END IF 
			LET l_rec_bankstatement.sheet_num = l_sheet_num 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_bankstatement.tran_date) 
			RETURNING l_rec_bankstatement.year_num, 
			l_rec_bankstatement.period_num 
			
			LET l_rec_bankstatement.conv_qty = get_conv_rate(
				l_rec_bankstatement.cmpy_code, 
				l_rec_bankstatement.bank_currency_code, 
				l_rec_bankstatement.tran_date,
				CASH_EXCHANGE_BUY) 
			
			LET l_rec_bankstatement.entry_code = "GCL" 
			LET l_rec_bankstatement.type_code = "1" 
			LET l_rec_bankstatement.entry_date = today 
			LET l_rec_bankstatement.other_amt = 0 
			LET l_rec_bankstatement.applied_amt = 0 
			LET l_rec_bankstatement.disc_amt = 0 
			LET l_rec_bankstatement.doc_num = 0 
			
			CASE l_rec_bankstatement.entry_type_code 
				WHEN "BC" ## bank charges 
					DECLARE c1_banking CURSOR FOR 
					SELECT doc_num FROM banking 
					WHERE bk_cmpy = l_rec_bankstatement.cmpy_code 
					AND bk_acct = l_rec_bankstatement.acct_code 
					AND bk_type = "BC" 
					AND bk_debit = l_rec_bankstatement.tran_amt 
					AND bk_sh_no IS NULL 
					OPEN c1_banking 
					FETCH c1_banking INTO l_rec_banking.doc_num 
					IF status = 0 THEN 
						LET l_rec_bankstatement.doc_num = l_rec_banking.doc_num 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = l_rec_bankstatement.sheet_num, 
						bk_seq_no = l_rec_bankstatement.seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 
					END IF 
				WHEN "BD" ## bank deposit 
					DECLARE c2_banking CURSOR FOR 
					SELECT doc_num FROM banking 
					WHERE bk_cmpy = l_rec_bankstatement.cmpy_code 
					AND bk_acct = l_rec_bankstatement.acct_code 
					AND bk_type in ("CD","DP") 
					AND bk_cred = l_rec_bankstatement.tran_amt 
					AND bk_sh_no IS NULL 
					OPEN c2_banking 
					FETCH c2_banking INTO l_rec_banking.doc_num 
					IF status = 0 THEN 
						LET l_rec_bankstatement.doc_num = l_rec_banking.doc_num 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = l_rec_bankstatement.sheet_num, 
						bk_seq_no = l_rec_bankstatement.seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 
					END IF 
				WHEN "CH" ## ap cheques 
					SELECT * INTO l_rec_cheque.* FROM cheque 
					WHERE cmpy_code = l_rec_bankstatement.cmpy_code 
					AND cheq_code = l_rec_bankstatement.ref_code 
					AND bank_code = l_rec_bankstatement.bank_code 
					AND pay_meth_ind in ("1","2") 
					CASE 
						WHEN status = NOTFOUND 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.currency_code != l_rec_bankstatement.bank_currency_code 
							AND l_rec_bankstatement.bank_currency_code != glob_rec_glparms.base_currency_code 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.currency_code = l_rec_bankstatement.bank_currency_code 
							AND l_rec_cheque.net_pay_amt != l_rec_bankstatement.tran_amt 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.cheq_date > l_rec_bankstatement.tran_date 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.recon_flag = "Y" 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.part_recon_flag = "Y" 
							LET l_rec_bankstatement.doc_num = 0 
						WHEN l_rec_cheque.currency_code != 
							l_rec_bankstatement.bank_currency_code 
							AND l_rec_bankstatement.bank_currency_code = 
							glob_rec_glparms.base_currency_code 
							LET l_rec_cheque.net_pay_amt = l_rec_cheque.net_pay_amt 
							/ l_rec_cheque.conv_qty 
							IF l_rec_bankstatement.tran_amt != l_rec_cheque.net_pay_amt THEN 
								LET l_err_message="Cheque Amount IS Invalid FOR this bank" 
								LET l_rec_bankstatement.doc_num = 0 
							ELSE 
								LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
							END IF 
						OTHERWISE 
							LET l_rec_bankstatement.doc_num = l_rec_cheque.doc_num 
							UPDATE cheque 
							SET part_recon_flag = "Y", 
							rec_state_num = l_rec_bankstatement.sheet_num, 
							rec_line_num = l_rec_bankstatement.seq_num 
							WHERE doc_num = l_rec_bankstatement.doc_num 
					END CASE 
				WHEN "SC" ## sundry credits (interest/reversals etc) 
					DECLARE c3_banking CURSOR FOR 
					SELECT doc_num FROM banking 
					WHERE bk_cmpy = l_rec_bankstatement.cmpy_code 
					AND bk_acct = l_rec_bankstatement.acct_code 
					AND bk_type in ("SC", "DP") 
					AND bk_cred = l_rec_bankstatement.tran_amt 
					AND bk_sh_no IS NULL 
					OPEN c3_banking 
					FETCH c3_banking INTO l_rec_banking.doc_num 
					IF status = 0 THEN 
						LET l_rec_bankstatement.doc_num = l_rec_banking.doc_num 
						UPDATE banking 
						SET bk_rec_part = "Y", 
						bk_sh_no = l_rec_bankstatement.sheet_num, 
						bk_seq_no = l_rec_bankstatement.seq_num 
						WHERE doc_num = l_rec_bankstatement.doc_num 
					END IF 
			END CASE 
			IF l_rec_bankstatement.entry_type_code <> 'SH' THEN 
				IF l_rec_bankstatement.doc_num > 0 THEN 
					LET l_rec_bankstatement.recon_ind = "1" 
				ELSE 
					LET l_rec_bankstatement.recon_ind = "0" 
				END IF 
			END IF 
			INSERT INTO bankstatement VALUES (l_rec_bankstatement.*) 
		END FOREACH 
	COMMIT WORK 
	CLOSE WINDOW w1_gcl 
	WHENEVER ERROR stop 
END FUNCTION 
############################################################
# END FUNCTION upd_stmts()
############################################################


############################################################
# FUNCTION enter_bankgroup() 
#
#
############################################################
FUNCTION enter_bankgroup() 
	DEFINE l_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 

	INPUT BY NAME l_rec_banktype.type_code, 
	l_rec_banktype.stmt_path_text, 
	l_rec_banktype.stmt_file_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCL","inp-banktype") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (type_code) 
			LET glob_temp_text = show_banktype() 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_banktype.type_code = glob_temp_text 
				NEXT FIELD type_code 
			END IF 

		AFTER FIELD type_code 
			IF l_rec_banktype.type_code IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9164,"") 
				#9164 " Bank Type must NOT be NULL
				NEXT FIELD type_code 
			ELSE 
				SELECT * INTO l_rec_banktype.* 
				FROM banktype 
				WHERE type_code = l_rec_banktype.type_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",9179,"") 
					# 9179 Bank Type NOT found - Try Window
					NEXT FIELD type_code 
				END IF 
			END IF 

			DISPLAY BY NAME l_rec_banktype.type_text, 
			l_rec_banktype.stmt_path_text, 
			l_rec_banktype.stmt_file_text 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				INITIALIZE l_rec_banktype.* TO NULL 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				IF l_rec_banktype.stmt_path_text IS NULL 
				AND l_rec_banktype.stmt_file_text IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9144,"") 
					#9144 " Interface file does NOT exist - Check path AND file name"
					CONTINUE INPUT 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	RETURN l_rec_banktype.* 
END FUNCTION 
############################################################
# END FUNCTION enter_bankgroup() 
############################################################


############################################################
# FUNCTION load_statement(p_rec_banktype)
#
#
############################################################
FUNCTION load_statement(p_rec_banktype) 
	DEFINE p_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_filename char(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("G",1002,"")	#1002 " Searching Database - Please wait"
	LET l_filename = p_rec_banktype.stmt_path_text clipped,"/", 
	p_rec_banktype.stmt_file_text 
	DELETE FROM t_stmthead 
	IF p_rec_banktype.stmt_format_ind = 1 THEN 
		IF anz_bank_load(p_rec_banktype.*,l_filename) THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	ELSE 
		IF other_bank_load(l_filename) THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION load_statement(p_rec_banktype)
############################################################


############################################################
# FUNCTION other_bank_load(p_filename)
#
#
############################################################
FUNCTION other_bank_load(p_filename) 
	DEFINE p_filename STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	DELETE FROM t_stmtload 
	WHENEVER ERROR CONTINUE 
	LOAD FROM p_filename INSERT INTO t_stmtload 
	WHENEVER ERROR stop 
	IF status != 0 THEN 
		LET l_msgresp=kandoomsg("G",9144,"")	#9144 "Interface file does NOT exist - Check path AND file name"
		RETURN false 
	END IF 
	SELECT unique 1 FROM t_stmtload 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("G",9146,"") 	#9146 "Interface file IS empty - Check PC Transfer"
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION other_bank_load(p_filename)
############################################################


############################################################
# FUNCTION anz_bank_load(p_rec_banktype,p_filename)
#
#
############################################################
FUNCTION anz_bank_load(p_rec_banktype,p_filename) 
	DEFINE p_rec_banktype RECORD LIKE banktype.* 
	DEFINE p_filename STRING 
	DEFINE l_filename2 STRING 
	DEFINE l_runner char(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL fgl_winmessage("needs TO change","needs TO change TO os independent\n huho ref 1002","info") 
	LET l_filename2 = p_filename clipped,".tmp" 
	LET l_runner = "../bin/CSV_to_UNL.sh ",p_filename clipped, " ", l_filename2 clipped 
	RUN l_runner RETURNING l_ret_code 
	IF l_ret_code THEN 
		ERROR kandoomsg2("G",9200,"") 		#9200 "ANZ file NOT found"
		RETURN false 
	END IF 
	DELETE FROM t_balance 
	WHENEVER ERROR CONTINUE 
	LOAD FROM l_filename2 INSERT INTO t_balance 
	WHENEVER ERROR stop 
	IF status != 0 THEN 
		ERROR kandoomsg2("G",9199,"") 		#9199 "File unable TO load - please check file FORMAT"
		RETURN false 
	END IF 
	SELECT unique 1 FROM t_balance 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",9146,"") 		#9146 "Interface file IS empty - Check PC Transfer"
		RETURN false 
	END IF 
	IF NOT load_anztrans(p_rec_banktype.*) THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
############################################################
# ENDFUNCTION anz_bank_load(p_rec_banktype,p_filename)
############################################################


############################################################
# FUNCTION load_anztrans(p_rec_banktype)
#
#
############################################################
FUNCTION load_anztrans(p_rec_banktype) 
	DEFINE p_rec_banktype RECORD LIKE banktype.* 
	DEFINE l_filename STRING 
	DEFINE l_filename2 STRING 
	DEFINE l_runner STRING 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g540 with FORM "G540" 
	CALL windecoration_g("G540") 

	CLEAR FORM 
	MESSAGE kandoomsg2("G",1001,"") 	#1001 " Enter selection criteria - ESC TO Continue"
	LET p_rec_banktype.stmt_file_text = NULL 

	INPUT BY NAME p_rec_banktype.stmt_path_text, 
	p_rec_banktype.stmt_file_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCL","inp-bank-statement") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			ELSE 
				IF p_rec_banktype.stmt_path_text IS NULL 
				AND p_rec_banktype.stmt_file_text IS NULL THEN 
					ERROR kandoomsg2("G",9144,"") 			#9144 " Interface file does NOT exist - Check path AND file name"
					CONTINUE INPUT 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g540 
		RETURN false 
	END IF 


	LET l_filename = p_rec_banktype.stmt_path_text clipped,"/", 
	p_rec_banktype.stmt_file_text 
	LET l_filename2 = l_filename clipped,".tmp" 

	DELETE FROM t_transaction 

	CALL fgl_winmessage("needs TO change","needs TO change TO os independent\n huho ref 1003","info") 
	LET l_runner = "../bin/CSV_to_UNL.sh ",l_filename clipped, " ", l_filename2 clipped 
	RUN l_runner RETURNING l_ret_code 

	IF l_ret_code THEN 
		LET l_msgresp=kandoomsg("G",9200,"") 
		#9200 "ANZ file NOT found"
		CLOSE WINDOW g540 
		RETURN false 
	END IF 

	WHENEVER ERROR CONTINUE 

	LOAD FROM l_filename2 INSERT INTO t_transaction 
	WHENEVER ERROR stop 
	IF status != 0 THEN 
		ERROR kandoomsg2("G",9199,"") #9199 "File unable TO load - please check file FORMAT"
		CLOSE WINDOW g540 
		RETURN false 
	END IF 
	SELECT unique 1 FROM t_transaction 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("G",9146,"") #9146 "Interface file IS empty - Check PC Transfer"
		CLOSE WINDOW g540 
		RETURN false 
	END IF 
	CLOSE WINDOW g540 

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION load_anztrans(p_rec_banktype)
############################################################


############################################################
# FUNCTION create_tables()
#
#
############################################################
FUNCTION create_tables() 
	DEFINE l_msg STRING

	IF fgl_find_table("t_balance") THEN #HuHo 8.10.2020
		LET l_msg = "Table ", trim("t_balance"), " already exists!\nTemp table with this name will not be re-created"
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
	END IF
	
	CREATE temp TABLE t_balance(balance_date DATE, 
	acc_num char(40), 
	acc_source char(10), 
	acc_num_format char(1), 
	acc_name char(40), 
	currency_code char(3), 
	open_bal decimal(16,2), 
	close_bal decimal(16,2), 
	dr_movement decimal(16,2), 
	no_debits INTEGER, 
	cr_movement decimal(16,2), 
	no_credits INTEGER, 
	dr_int_rate decimal(16,4), 
	cr_int_rate decimal(16,4), 
	overdraft_lmt decimal(16,2), 
	dr_int_arrd decimal(16,2), 
	cr_int_accrd decimal(16,2), 
	fid_accrd decimal(16,2), 
	badt_accrd decimal(16,2), 
	next_process_date date) with no LOG 

	IF fgl_find_table("t_transaction") THEN #HuHo 8.10.2020
		LET l_msg = "Table ", trim("t_transaction"), " already exists!\nTemp table with this name will not be re-created"
		CALL fgl_winmessage("ERROR",l_msg,"ERROR")
	END IF
	
	#NOTE - COLUMN reference renamed TO the_reference because it IS a reserved word in PG
	CREATE temp TABLE t_transaction(tran_date DATE, 
	acc_num char(40), 
	acc_source char(10), 
	acc_num_format char(1), 
	acc_name char(40), 
	currency_code char(3), 
	subacc_name char(40), 
	trans_type char(10), 
	the_reference char(10), 
	amount decimal(16,2), 
	trans_text char(30), 
	effective_date DATE, 
	trace_id char(12), 
	tran_code char(3), 
	auxdom char(10)) with no LOG 
END FUNCTION 
############################################################
# END FUNCTION create_tables()
############################################################