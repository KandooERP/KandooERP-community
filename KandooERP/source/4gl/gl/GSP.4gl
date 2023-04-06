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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_batchhead RECORD LIKE batchhead.* 
DEFINE modu_rec_payparms RECORD LIKE payparms.* 
DEFINE modu_default_desc LIKE coa.desc_text 
############################################################
# FUNCTION GSP_main()
#
# GSP.4gl - Allows import of external ascii files INTO General
#           Ledger.
############################################################
FUNCTION GSP_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GSP") 

	SELECT * INTO modu_rec_payparms.* FROM payparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("G",5020,""),"ERROR")	#5020 " Payroll Load Parameters Not Set Up - Refer Menu GZK"
		EXIT PROGRAM 
	END IF 

	IF modu_rec_payparms.source_ind = 1 THEN 
		CREATE temp TABLE t_loadpay(l_pay_line CHAR(512)) with no LOG 
	ELSE 
		CREATE temp TABLE t_loadpay(l_acct_code CHAR(18), 
		curr_amt DECIMAL(16,2), 
		mth_amt DECIMAL(16,2), 
		year_amt DECIMAL(16,2)) with no LOG 
		CREATE temp TABLE t_loaderr(line_num INTEGER, 
		error_text CHAR(65))with no LOG 
	END IF 

	CREATE temp TABLE t_payroll(l_acct_code CHAR(18), 
	tran_amt DECIMAL(16,2), 
	tran_type CHAR(1), 
	batch_type CHAR(18), 
	seq_no integer) with no LOG 

	OPEN WINDOW G421 with FORM "G421" 
	CALL windecoration_g("G421") 

	MENU " Payroll Load " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GSP","menu-payroll-load") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Load" 
			#COMMAND "Load" " Load Payroll File"
			IF get_info() THEN 
				IF modu_rec_payparms.source_ind = "1" THEN 
					IF load_lattice_batches() THEN 
						CALL update_database() 
					ELSE 
						ERROR kandoomsg2("G",9152,"") 
						#9152 " Unable TO Load data FROM Load file - Check file FORMAT"
					END IF 
				ELSE 
					IF load_micropay_batches() THEN 
						CALL update_database() 
					END IF 
				END IF 
			END IF 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	IF fgl_find_table("t_loadpay") THEN
		DROP TABLE t_loadpay 
	END IF					
	IF fgl_find_table("t_payroll") THEN
		DROP TABLE t_payroll 
	END IF					

	CLOSE WINDOW G421
	 
END FUNCTION


############################################################
# FUNCTION get_info()
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_rec_journal RECORD LIKE journal.*
	DEFINE l_path_name LIKE payparms.path_name 
	DEFINE l_temp_text CHAR(20)
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_runner CHAR(100) 
	DEFINE l_path_name2 CHAR(50) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("G",1041,"") 	#1041 " Enter Batch Information - ESC TO Continue"
	INITIALIZE modu_rec_batchhead.* TO NULL 
	LET modu_rec_batchhead.jour_code = modu_rec_payparms.jour_code 
	SELECT * INTO l_rec_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = modu_rec_payparms.jour_code 
	LET modu_rec_batchhead.jour_date = today 
	LET modu_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code
	 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING modu_rec_batchhead.year_num, 
	modu_rec_batchhead.period_num
	 
	DISPLAY BY NAME l_rec_journal.desc_text, 
	modu_rec_batchhead.entry_code, 
	modu_rec_batchhead.jour_date 


	INPUT BY NAME modu_rec_batchhead.jour_code, 
	modu_rec_batchhead.year_num, 
	modu_rec_batchhead.period_num, 
	modu_default_desc, 
	modu_rec_batchhead.com1_text, 
	modu_rec_batchhead.com2_text, 
	modu_rec_payparms.path_name, 
	modu_rec_payparms.file_name WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSP","inp-batch") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET modu_rec_batchhead.jour_code = l_temp_text 
			END IF 
			NEXT FIELD jour_code 

		AFTER FIELD jour_code 
			SELECT * INTO l_rec_journal.* FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = modu_rec_batchhead.jour_code 
			CASE 
				WHEN status = NOTFOUND 
					ERROR kandoomsg2("G",9029,"") 					#9029 " Journal NOT Found - Try Window"
					NEXT FIELD jour_code 
				WHEN l_rec_journal.gl_flag = "N" 
					ERROR kandoomsg2("G",7015,"") 					#7015 " Journal Cannot be Entered - Refer Menu GZ2 "
					NEXT FIELD jour_code 
				OTHERWISE 
					DISPLAY l_rec_journal.desc_text TO journal.desc_text 

			END CASE 
			
		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code,
				modu_rec_batchhead.year_num, 
				modu_rec_batchhead.period_num,
				LEDGER_TYPE_GL) 
			RETURNING 
				modu_rec_batchhead.year_num, 
				modu_rec_batchhead.period_num, 
				l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD path_name 
			IF modu_rec_payparms.path_name IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9034,"") 
				#9034  Directory must be entered
				NEXT FIELD path_name 
			END IF 
			WHENEVER ERROR CONTINUE 
			LET l_path_name = modu_rec_payparms.path_name clipped, "/tempfile" 
			DELETE FROM t_loadpay 
			UNLOAD TO l_path_name 
			SELECT * FROM t_loadpay 
			IF status = -806 THEN 
				ERROR kandoomsg2("G",9140,"") 				#9140 " Directory NOT found - Check UNIX path AND re-enter"
				WHENEVER ERROR stop 
				NEXT FIELD path_name 
			END IF 
			WHENEVER ERROR stop 
			
		AFTER FIELD file_name 
			IF fgl_lastkey() = fgl_keyval("up") THEN 				#Give user the chance TO change path name
				NEXT FIELD path_name 
			END IF 
			IF modu_rec_payparms.file_name IS NULL THEN 
				LET l_msgresp = kandoomsg("G",9144,"") 				#9144  File does NOT exist - Check path AND file name
				NEXT FIELD file_name 
			END IF 
			
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code,
					modu_rec_batchhead.year_num, 
					modu_rec_batchhead.period_num,
					LEDGER_TYPE_GL) 
				RETURNING 
					modu_rec_batchhead.year_num, 
					modu_rec_batchhead.period_num, 
					l_invalid_period 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				
				IF modu_rec_payparms.path_name IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9034,"")		#9034  Directory must be entered
					NEXT FIELD path_name 
				END IF 
				IF modu_rec_payparms.file_name IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9144,"")	#9144  File does NOT exist - Check path AND file name
					NEXT FIELD file_name 
				END IF 
				
				WHENEVER ERROR CONTINUE 
				LET l_path_name = modu_rec_payparms.path_name clipped,"/", 
				modu_rec_payparms.file_name 
				
				DELETE FROM t_loadpay 
				
				IF modu_rec_payparms.source_ind = 1 THEN 
					LOAD FROM l_path_name INSERT INTO t_loadpay 
					IF status != 0 THEN 
						LET l_msgresp = kandoomsg("G",9144,"") 
						#9144  File does NOT exist - Check path AND file name
						NEXT FIELD file_name 
						WHENEVER ERROR stop 
					END IF 
				ELSE 
					LET l_path_name2 = l_path_name clipped,".tmp" 
					LET l_runner = "../bin/NQI_to_MXI.sh ", 
					l_path_name clipped, 
					" ",l_path_name2 
					RUN l_runner 
					WHENEVER ERROR CONTINUE 
					LOAD FROM l_path_name2 INSERT INTO t_loadpay 
					IF status != 0 THEN 
						IF status = -846 THEN 
							ERROR kandoomsg2("G",9152,"") 							#9152 " Unable TO Load data FROM Load file - Check file "
							NEXT FIELD file_name 
							WHENEVER ERROR stop 
						ELSE 
							LET l_msgresp = kandoomsg("G",9144,"") 							#9144  File does NOT exist - Check path AND file name
							NEXT FIELD file_name 
							WHENEVER ERROR stop 
						END IF 
					END IF 
				END IF 
				
				WHENEVER ERROR stop 
				
				IF sqlca.sqlerrd[3] = 0 THEN 
					LET l_msgresp = kandoomsg("G",9146,"") 
					#9146  File IS empty - Check PC transfer
					NEXT FIELD file_name 
				END IF 
			END IF 

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
# FUNCTION load_lattice_batches() 
#
#
############################################################
FUNCTION load_lattice_batches() 
	DEFINE l_pay_line CHAR(512)
	DEFINE l_rec_payroll RECORD 
		acct_code LIKE batchdetl.acct_code, 
		trans_amt LIKE batchdetl.debit_amt, 
		trans_ind CHAR(1), # dr OR cr 
		batch_type LIKE validflex.flex_code, 
		seq_no INTEGER 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_mask_code LIKE coa.acct_code
	DEFINE l_seq_no INTEGER
	DEFINE l_start_num SMALLINT
	DEFINE l_length SMALLINT
	DEFINE l_retcode SMALLINT 
	DEFINE l_multiledg_ind SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 

	OPEN WINDOW w1_gcl with FORM "U999" attributes(BORDER) 
	CALL windecoration_u("U999") 

	DISPLAY "Loading Account - " TO lblabel1 -- 1,2 

	DELETE FROM t_payroll 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET l_multiledg_ind = false 
	ELSE 
		LET l_multiledg_ind = true 
		LET l_start_num = l_rec_structure.start_num 
		LET l_length = l_rec_structure.start_num 
		+ l_rec_structure.length_num 
		- 1 
		CALL get_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
		RETURNING l_mask_code 
	END IF
	 
	LET l_retcode = true 
	DECLARE c_loadpay CURSOR FOR 
	SELECT * FROM t_loadpay 
	
	# Format => "1" "01-ADM-1001" 256.45 0 "C" " "
	#     OR => "1" "01-ADM-1002" 1234256.25 30 "D" " "
	LET l_seq_no = 0 
	FOREACH c_loadpay INTO l_pay_line 
		LET l_seq_no = l_seq_no + 1 
		INITIALIZE l_rec_payroll.* TO NULL 
		LET l_rec_payroll.seq_no = l_seq_no 
		LET l_start_pos = 1 
		LET l_end_pos = unstring(l_start_pos,l_pay_line) 
		# SKIP the first field
		LET l_start_pos = l_end_pos + 3 
		LET l_end_pos = unstring(l_start_pos,l_pay_line) 
		LET l_rec_payroll.acct_code = l_pay_line[l_start_pos,l_end_pos -1] 
		DISPLAY "" at 1,20 
		DISPLAY l_rec_payroll.acct_code TO lblabel1b -- 1,20 

		LET l_start_pos = l_end_pos + 2 
		LET l_end_pos = unstring(l_start_pos,l_pay_line) 

		WHENEVER ERROR GOTO num_error 
		LET l_rec_payroll.trans_amt = l_pay_line[l_start_pos,l_end_pos] 

		WHENEVER ERROR stop 

		GOTO end_error 
		LABEL num_error: 

		WHENEVER ERROR stop 

		LET l_retcode = false 

		EXIT FOREACH 
		LABEL end_error: 

		LET l_start_pos = l_end_pos + 2 
		LET l_end_pos = unstring(l_start_pos,l_pay_line) 
		# SKIP the NEXT FIELD
		LET l_start_pos = l_end_pos + 3 
		LET l_end_pos = unstring(l_start_pos,l_pay_line) 
		LET l_rec_payroll.trans_ind = l_pay_line[l_start_pos,l_end_pos -1] 

		IF l_rec_payroll.trans_ind NOT matches "[CD]" THEN 
			LET l_retcode = false 
			EXIT FOREACH 
		END IF 
		LET l_rec_payroll.batch_type = "ONE" 

		#
		# Create M. L. batches FOR each ledger (Batch Type = Ledger) + 1 batch
		# FOR unmatched mask code accounts (Batch Type = ONE).
		# Create 1 Batch ONLY FOR non M.L companies .... (Batch Type = ONE)
		#
		IF l_multiledg_ind THEN 
			IF l_rec_payroll.acct_code matches l_mask_code THEN 
				LET l_rec_payroll.batch_type = 
				l_rec_payroll.acct_code[l_start_num,l_length] 
			END IF 
		END IF 

		INSERT INTO t_payroll VALUES (l_rec_payroll.*) 

	END FOREACH 

	CLOSE WINDOW w1_gcl 

	RETURN l_retcode 
END FUNCTION 


############################################################
# FUNCTION unstring(p_start_pos,p_pay_line)  
#
#
############################################################
FUNCTION unstring(p_start_pos,p_pay_line) 
	DEFINE p_start_pos SMALLINT 
	DEFINE p_pay_line CHAR(512) 
	DEFINE i SMALLINT 
	DEFINE l_line_length SMALLINT 
	DEFINE l_char_cnt SMALLINT 

	LET l_char_cnt = 0 
	LET l_line_length = length(p_pay_line) 

	FOR i = p_start_pos TO l_line_length 
		IF p_pay_line[i] = " " THEN 
			EXIT FOR 
		ELSE 
			LET l_char_cnt = l_char_cnt + 1 
		END IF 
	END FOR 

	LET l_char_cnt = l_char_cnt 
	+ p_start_pos 
	- 1 

	RETURN l_char_cnt 
END FUNCTION 


############################################################
# FUNCTION get_mask(p_cmpy_code, p_mask, p_override)  
#
#
############################################################
FUNCTION get_mask(p_cmpy_code, p_mask, p_override) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_mask LIKE account.acct_code
	DEFINE p_override LIKE account.acct_code
	DEFINE l_acct_code LIKE account.acct_code
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_mtype SMALLINT
	 

	DECLARE struct_cur CURSOR FOR 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = p_cmpy_code 
	AND start_num > 0 

	FOREACH struct_cur 
		LET i = l_rec_structure.start_num 
		LET j = l_rec_structure.length_num 
		IF i = 6 THEN 
			LET l_acct_code = l_acct_code clipped, "*" 
			EXIT FOREACH 
		END IF 
		CASE 
			WHEN l_rec_structure.type_ind = "F" 
				LET l_acct_code[i,i+j-1] = l_rec_structure.default_text 
			OTHERWISE 
				LET l_mtype = masks(p_mask[i,i+j-1], j) 
				CASE 
					WHEN l_mtype = 1 
						LET l_acct_code[i,i+j-1] = p_mask[i,i+j-1] 
					WHEN l_mtype = 0 
						LET l_acct_code[i,i+j-1] = p_override[i,i+j-1] 
					OTHERWISE 
						LET l_mtype = masks(p_override[i,i+j-1], j) 
						CASE 
							WHEN l_mtype = 1 
								LET l_acct_code[i,i+j-1] = p_override[i,i+j-1] 
							OTHERWISE 
								LET l_acct_code[i,i+j-1] = p_mask[i,i+j-1] 
						END CASE 
				END CASE 
		END CASE 
	END FOREACH 

	RETURN l_acct_code 
END FUNCTION 


############################################################
# FUNCTION masks(p_seg_code, p_len)  
#
#
############################################################
FUNCTION masks(p_seg_code, p_len) 
	DEFINE p_seg_code LIKE account.acct_code 
	DEFINE p_len SMALLINT 
	DEFINE l_blank SMALLINT
	DEFINE l_question_mark SMALLINT
	DEFINE l_idx SMALLINT
	
	LET l_blank = true 
	LET l_question_mark = true
	 
	IF p_seg_code IS NULL THEN 
		RETURN (0) 
	END IF
	 
	FOR l_idx = 1 TO p_len 
		IF p_seg_code[l_idx, l_idx] != " " THEN 
			LET l_blank = false 
		END IF 
		IF p_seg_code[l_idx, l_idx] != "?" THEN 
			LET l_question_mark = false 
		END IF 
	END FOR

	#Return --------------	 
	IF l_blank THEN 
		RETURN (0) 
	END IF
	IF l_question_mark THEN 
		RETURN (2) 
	END IF 
	RETURN (1) 
END FUNCTION 


############################################################
# FUNCTION update_database()  
#
#
############################################################
FUNCTION update_database() 
	DEFINE l_rec_payroll RECORD 
		acct_code LIKE batchdetl.acct_code, 
		trans_amt LIKE batchdetl.debit_amt, 
		trans_ind CHAR(1), # dr OR cr 
		batch_type LIKE validflex.flex_code 
	END RECORD
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_prev_batch_type LIKE validflex.flex_code
	DEFINE l_tot_debits LIKE batchdetl.credit_amt
	DEFINE l_tot_credits LIKE batchdetl.credit_amt
	 
	DEFINE l_first_jour LIKE glparms.next_jour_num 
	DEFINE l_last_jour LIKE glparms.next_jour_num 

	DEFINE l_err_message CHAR(60) 
	DEFINE l_jour_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		DECLARE c_payroll SCROLL CURSOR FOR 
		SELECT * FROM t_payroll 
		ORDER BY batch_type, seq_no 
		OPEN c_payroll 

		LET l_tot_debits = 0 
		LET l_tot_credits = 0 
		LET l_prev_batch_type = " " 

		FETCH NEXT c_payroll INTO l_rec_payroll.* 
		WHILE true 
			IF l_rec_payroll.batch_type != l_prev_batch_type THEN 
				LET l_rec_batchhead.* = modu_rec_batchhead.* 

				DECLARE c_glparms CURSOR FOR 
				SELECT * FROM glparms 
				WHERE cmpy_code = p_cmpy 
				AND key_code = "1" 
				FOR UPDATE 
				OPEN c_glparms 
				FETCH c_glparms INTO glob_rec_glparms.* 
				UPDATE glparms SET next_jour_num = glob_rec_glparms.next_jour_num + 1 
				WHERE cmpy_code = p_cmpy 
				AND key_code = "1" 

				LET l_rec_batchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num + 1 
				IF l_first_jour = 0 THEN 
					LET l_first_jour = l_rec_batchhead.jour_num 
				END IF 
				LET l_last_jour = l_rec_batchhead.jour_num 
				LET l_rec_batchhead.for_debit_amt = 0 
				LET l_rec_batchhead.for_credit_amt = 0 
				LET l_rec_batchhead.debit_amt = 0 
				LET l_rec_batchhead.credit_amt = 0 
				LET l_rec_batchhead.control_amt = 0 
				LET l_rec_batchhead.control_qty = 0 
				LET l_rec_batchhead.stats_qty = 0 
				LET l_rec_batchhead.seq_num = 0 
				LET l_rec_batchhead.source_ind = "G" 
				LET l_rec_batchhead.post_flag = "N" 
				LET l_rec_batchhead.rate_type_ind = "B" 
				LET l_rec_batchhead.currency_code = glob_rec_glparms.base_currency_code 
				LET l_rec_batchhead.conv_qty = 1 
				IF glob_rec_glparms.use_clear_flag = "Y" THEN 
					LET l_rec_batchhead.cleared_flag = "N" 
				ELSE 
					LET l_rec_batchhead.cleared_flag = "Y" 
				END IF 
				LET l_prev_batch_type = l_rec_payroll.batch_type 
			END IF 

			INITIALIZE l_rec_batchdetl.* TO NULL 

			LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_batchdetl.jour_code = l_rec_batchhead.jour_code 
			LET l_rec_batchdetl.jour_num = l_rec_batchhead.jour_num 
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.tran_type_ind = "PAY" 
			LET l_rec_batchdetl.tran_date = l_rec_batchhead.jour_date 
			LET l_rec_batchdetl.acct_code = l_rec_payroll.acct_code 
			LET l_rec_batchdetl.desc_text = modu_default_desc 

			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = p_cmpy 
			AND l_acct_code = l_rec_payroll.acct_code 
			IF status = NOTFOUND THEN 
				LET l_rec_batchdetl.desc_text = "*** Invalid Account Loaded ***" 
			ELSE 
				IF modu_default_desc IS NULL THEN 
					LET l_rec_batchdetl.desc_text = l_rec_coa.desc_text 
				END IF 
			END IF 

			LET l_rec_batchdetl.currency_code = l_rec_batchhead.currency_code 
			LET l_rec_batchdetl.conv_qty = l_rec_batchhead.conv_qty 
			LET l_rec_batchdetl.stats_qty = 0 
			LET l_rec_batchdetl.for_debit_amt = 0 
			LET l_rec_batchdetl.for_credit_amt = 0 
			IF l_rec_payroll.trans_ind = "D" THEN 
				LET l_rec_batchdetl.for_debit_amt = l_rec_payroll.trans_amt 
			ELSE 
				LET l_rec_batchdetl.for_credit_amt = l_rec_payroll.trans_amt 
			END IF 
			LET l_tot_debits = l_tot_debits + l_rec_batchdetl.for_debit_amt 
			LET l_tot_credits = l_tot_credits + l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt /	l_rec_batchdetl.conv_qty 
			LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt / l_rec_batchdetl.conv_qty 

			INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

			LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt	+ l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt	+ l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchhead.stats_qty = l_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
			IF glob_rec_glparms.control_tot_flag = "Y" THEN 
				LET l_rec_batchhead.control_amt = l_rec_batchhead.for_credit_amt 
				LET l_rec_batchhead.control_qty = l_rec_batchhead.stats_qty 
			END IF 
			
			UPDATE batchhead SET * = l_rec_batchhead.* 
			WHERE cmpy_code = p_cmpy 
			AND jour_num = l_rec_batchhead.jour_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				CALL fgl_winmessage("24 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
				INSERT INTO batchhead VALUES (l_rec_batchhead.*) 
			END IF 
			
			#
			FETCH NEXT c_payroll INTO l_rec_payroll.* 
			IF status = NOTFOUND THEN 
				IF l_tot_debits != l_tot_credits THEN 
					CALL ins_clearing_acct(l_rec_batchhead.*,l_tot_debits,l_tot_credits) 
				END IF 
				EXIT WHILE 
			ELSE 
				IF l_rec_payroll.batch_type != l_prev_batch_type THEN 
					IF l_tot_debits != l_tot_credits THEN 
						CALL ins_clearing_acct(l_rec_batchhead.*,l_tot_debits,l_tot_credits) 
					END IF 
					LET l_tot_debits = 0 
					LET l_tot_credits = 0 
				END IF 
			END IF 
		END WHILE
		 
	COMMIT WORK
	 
	IF l_first_jour = l_last_jour THEN 
		LET l_jour_text = l_first_jour USING "<<<<<<<<" 
	ELSE 
		LET l_jour_text = l_first_jour USING "<<<<<<<<", " TO ", l_last_jour USING "<<<<<<<<" 
	END IF 
	LET l_msgresp = kandoomsg("G",7019,l_jour_text) 
	#7019 Payroll file successfully Loaded
	WHENEVER ERROR stop 
	
END FUNCTION 


############################################################
# FUNCTION ins_clearing_acct(p_rec_batchhead,p_tot_debits,p_tot_credits)
#
#
############################################################
FUNCTION ins_clearing_acct(p_rec_batchhead,p_tot_debits,p_tot_credits) 
	DEFINE p_rec_batchhead RECORD LIKE batchhead.*
	DEFINE p_tot_debits LIKE batchdetl.credit_amt
	DEFINE p_tot_credits LIKE batchdetl.credit_amt
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_coa RECORD LIKE coa.* 

	INITIALIZE l_rec_batchdetl.* TO NULL 

	LET l_rec_batchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_batchdetl.jour_code = p_rec_batchhead.jour_code 
	LET l_rec_batchdetl.jour_num = p_rec_batchhead.jour_num 
	LET p_rec_batchhead.seq_num = p_rec_batchhead.seq_num + 1 
	LET l_rec_batchdetl.seq_num = p_rec_batchhead.seq_num 
	LET l_rec_batchdetl.tran_type_ind = "PAY" 
	LET l_rec_batchdetl.tran_date = p_rec_batchhead.jour_date 
	LET l_rec_batchdetl.acct_code = modu_rec_payparms.clear_acct_code 
	LET l_rec_batchdetl.desc_text = modu_default_desc 
	LET l_rec_batchdetl.desc_text = "Payroll Clearing Account" 
	LET l_rec_batchdetl.currency_code = p_rec_batchhead.currency_code 
	LET l_rec_batchdetl.conv_qty = p_rec_batchhead.conv_qty 
	LET l_rec_batchdetl.stats_qty = 0 
	LET l_rec_batchdetl.for_debit_amt = 0 
	LET l_rec_batchdetl.for_credit_amt = 0 
	IF p_tot_debits < p_tot_credits THEN 
		LET l_rec_batchdetl.for_debit_amt = p_tot_credits - p_tot_debits 
	ELSE 
		LET l_rec_batchdetl.for_credit_amt = p_tot_debits - p_tot_credits 
	END IF 
	LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt /	l_rec_batchdetl.conv_qty 
	LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt / l_rec_batchdetl.conv_qty 
	
	INSERT INTO batchdetl VALUES (l_rec_batchdetl.*) 

	LET p_rec_batchhead.credit_amt = p_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
	LET p_rec_batchhead.debit_amt = p_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
	LET p_rec_batchhead.for_debit_amt = p_rec_batchhead.for_debit_amt	+ l_rec_batchdetl.for_debit_amt 
	LET p_rec_batchhead.for_credit_amt = p_rec_batchhead.for_credit_amt	+ l_rec_batchdetl.for_credit_amt 
	LET p_rec_batchhead.stats_qty = p_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
	IF glob_rec_glparms.control_tot_flag = "Y" THEN 
		LET p_rec_batchhead.control_amt = p_rec_batchhead.for_credit_amt 
		LET p_rec_batchhead.control_qty = p_rec_batchhead.stats_qty 
	END IF 

	UPDATE batchhead SET * = p_rec_batchhead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_num = p_rec_batchhead.jour_num 

END FUNCTION 


############################################################
# FUNCTION load_micropay_batches() 
#
#
############################################################
FUNCTION load_micropay_batches() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_micropay RECORD 
		acct_code CHAR(18), 
		curr_amt DECIMAL(16,2), 
		mth_amt DECIMAL(16,2), 
		year_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_payroll RECORD 
		acct_code LIKE batchdetl.acct_code, 
		trans_amt LIKE batchdetl.debit_amt, 
		trans_ind CHAR(1), # dr OR cr 
		batch_type LIKE validflex.flex_code, 
		seq_no INTEGER 
	END RECORD 
	DEFINE l_rec_loaderr RECORD 
		line_num INTEGER, 
		l_err_message CHAR(65) 
	END RECORD 
	DEFINE l_rpt_output CHAR(65)
	DEFINE l_error_text CHAR(65)
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_def_acct LIKE coa.acct_code
	DEFINE l_acct_code LIKE coa.acct_code
	DEFINE l_mask_code LIKE coa.acct_code	
	DEFINE l_err_cnt INTEGER
	DEFINE l_seq_no INTEGER	
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE k SMALLINT
	DEFINE l_start_num SMALLINT
	DEFINE l_length SMALLINT
	DEFINE l_retcode SMALLINT
	DEFINE l_multiledg_ind SMALLINT	 
	DEFINE l_msgresp LIKE language.yes_flag 

	DISPLAY "Loading Account - " TO lblabel1 -- 1,2 

	DELETE FROM t_payroll 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		LET l_multiledg_ind = false 
	ELSE 
		LET l_multiledg_ind = true 
		LET l_start_num = l_rec_structure.start_num 
		LET l_length = l_rec_structure.start_num 
		+ l_rec_structure.length_num 
		- 1 
		CALL get_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
		RETURNING l_mask_code 
	END IF 

	LET l_err_cnt = 0 
	LET l_retcode = true 

	DECLARE c1_loadpay CURSOR FOR 
	SELECT * FROM t_loadpay 
	LET l_seq_no = 0 

	FOREACH c1_loadpay INTO l_rec_micropay.* 
		LET l_seq_no = l_seq_no + 1 

		INITIALIZE l_rec_payroll.* TO NULL 

		LET l_rec_payroll.seq_no = l_seq_no 

		SELECT default_text INTO l_def_acct FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND desc_text = "Default Code" 
		AND start_num = 0 
		AND type_ind = "D" 

		INITIALIZE l_acct_code TO NULL 
		LET j = 0 
		LET k = 0 

		FOR i = 1 TO length(l_rec_micropay.acct_code) 
			LET k = k + 1 
			IF l_def_acct[k] = "-" THEN 
				LET k = k + 1 
				LET j = j + 1 
				LET l_acct_code[j] = "-" 
			END IF 
			LET j = j + 1 
			LET l_acct_code[j] = l_rec_micropay.acct_code[i] 
		END FOR 

		LET l_rec_payroll.acct_code = l_acct_code 

		SELECT unique l_acct_code FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND l_acct_code = l_rec_payroll.acct_code 

		IF status = NOTFOUND THEN 
			LET l_error_text = "Account code \"", 
			l_rec_payroll.acct_code clipped,"\" ", 
			"was NOT found." 
			INSERT INTO t_loaderr VALUES (l_seq_no,l_error_text) 
			LET l_err_cnt = l_err_cnt + 1 
		ELSE 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code, l_rec_payroll.acct_code, COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"N") THEN 
				LET l_error_text = "Account code \"", 
				l_rec_payroll.acct_code clipped,"\" ", 
				"IS a control OR bank account." 
				INSERT INTO t_loaderr VALUES (l_seq_no,l_error_text) 
				LET l_err_cnt = l_err_cnt + 1 
			END IF 
		END IF 

		--DISPLAY "" at 1,20
		--DISPLAY l_rec_payroll.acct_code TO lblabel1b 
		MESSAGE "Payroll GL-Account: ", trim(l_rec_payroll.acct_code)

		CASE 
			WHEN modu_rec_payparms.source_ind = "2" 
				LET l_rec_payroll.trans_amt = l_rec_micropay.curr_amt 
			WHEN modu_rec_payparms.source_ind = "3" 
				LET l_rec_payroll.trans_amt = l_rec_micropay.mth_amt 
			WHEN modu_rec_payparms.source_ind = "4" 
				LET l_rec_payroll.trans_amt = l_rec_micropay.year_amt 
		END CASE 
		IF l_rec_payroll.trans_amt < 0 THEN 
			LET l_rec_payroll.trans_ind = "C" 
			LET l_rec_payroll.trans_amt = l_rec_payroll.trans_amt * -1 
		ELSE 
			LET l_rec_payroll.trans_ind = "D" 
		END IF 
		LET l_rec_payroll.batch_type = "ONE"
		 
		#
		# Create M. L. batches FOR each ledger (Batch Type = Ledger) + 1 batch
		# FOR unmatched mask code accounts (Batch Type = ONE).
		# Create 1 Batch ONLY FOR non M.L companies .... (Batch Type = ONE)
		#
		IF l_multiledg_ind THEN 
			IF l_rec_payroll.acct_code matches l_mask_code THEN 
				LET l_rec_payroll.batch_type = 
				l_rec_payroll.acct_code[l_start_num,l_length] 
			END IF 
		END IF
		 
		INSERT INTO t_payroll VALUES (l_rec_payroll.*)
		 
	END FOREACH
	 
	CLOSE WINDOW w1_gcl
	 
	IF l_err_cnt > 0 THEN 
	
		#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"GSP_rpt_list_loaderror","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GSP_rpt_list_loaderror TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------
		 
		DECLARE c_loaderr CURSOR FOR 
		SELECT * FROM t_loaderr 
		FOREACH c_loaderr INTO l_rec_loaderr.* 

			#---------------------------------------------------------
			OUTPUT TO REPORT GSP_rpt_list_loaderror(l_rpt_idx,l_rec_loaderr.*) 
			#---------------------------------------------------------	

		END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT GSP_rpt_list_loaderror
	CALL rpt_finish("GSP_rpt_list_loaderror")
	#------------------------------------------------------------
		LET l_retcode = false 
	END IF
	 
	RETURN l_retcode 
END FUNCTION 


############################################################
# REPORT GSP_rpt_list_loaderror(p_rec_loaderr) 
#
#
############################################################
REPORT GSP_rpt_list_loaderror(p_rpt_idx,p_rec_loaderr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_loaderr RECORD 
		line_num INTEGER, 
		l_err_message CHAR(65) 
	END RECORD 

	OUTPUT 
	left margin 0
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 04, "Line", 
			COLUMN 11, "Error Message" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 			 

		ON EVERY ROW 
			PRINT COLUMN 03, p_rec_loaderr.line_num USING "#####", 
			COLUMN 11, p_rec_loaderr.l_err_message
			 
		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			 
END REPORT