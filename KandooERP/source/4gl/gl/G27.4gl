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

	Source code beautified by beautify.pl on 2020-01-03 14:28:30	$Id: $
}



# G27 - allows the user TO create Journal Batches FROM external ASCII files
#     - ( G27 can be called FROM JMJ Invoice Load (ASI_J) AND hence
#         accepts an argument )
#


#This file IS used as GLOBLAS file FROM G27a.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G27_GLOBALS.4gl" 


############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("G27") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	INITIALIZE glob_rec_batchhead.* TO NULL 
	LET glob_rec_batchhead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_batchhead.jour_date = today 
	LET glob_rec_batchhead.com1_text = NULL 
	LET glob_rec_batchhead.com2_text = NULL 


	#Process program arguments
	#
	# G27 invoked FROM ASI_J ( arguments = glob_verbose_ind cmpy_code's )
	#
	IF (get_url_verbose() IS NOT null) 
	OR 
	(get_url_auto_company_code() IS NOT null) 
	OR 
	(get_url_jmj_company_code() IS NOT null) 
	THEN 

		IF get_url_verbose() IS NOT NULL THEN 
			LET glob_verbose_ind = get_url_verbose() 
		END IF 

		IF get_url_auto_company_code() IS NOT NULL THEN 
			LET glob_auto_cmpy_code = get_url_auto_company_code() 
		END IF 

		IF get_url_jmj_company_code() IS NOT NULL THEN 
			LET glob_jmj_cmpy_code = get_url_jmj_company_code() --only used once ???
		END IF 

		LET glob_load_file_ind = false 
		CALL process_batch() 

	ELSE 
		LET glob_verbose_ind = true 
		LET glob_load_file_ind = true 

		OPEN WINDOW g148 with FORM "G148" 
		CALL windecoration_g("G148") 

		MENU " External Batch Load" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","G27","menu-ext-batch-load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "Load" 
				#COMMAND "Load" " Commence load process"
				IF G27_header() THEN 
					CALL process_batch() 
				END IF 
				NEXT option "Print Manager" 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			ON ACTION "Exit" 
				#COMMAND KEY(interrupt,"E")"Exit" " Exit external batch load"
				LET quit_flag = true 
				EXIT MENU 

		END MENU 

		CLOSE WINDOW g148 
	END IF 
END MAIN 


############################################################
# FUNCTION G27_header()
#
#
############################################################
FUNCTION G27_header() 
	DEFINE l_failed SMALLINT 
	DEFINE l_journal RECORD LIKE journal.* 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_file_text CHAR(20) 
	DEFINE l_path_text CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET glob_rec_batchhead.control_amt = NULL 
	LET glob_rec_batchhead.control_qty = 0 
	CALL db_period_what_period( glob_rec_kandoouser.cmpy_code, today ) 
	RETURNING glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num 
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = '1' 
	SELECT * INTO l_journal.* FROM journal 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jour_code = glob_rec_glparms.gj_code 
	LET glob_rec_batchhead.jour_code = glob_rec_glparms.gj_code 
	DISPLAY BY NAME l_journal.desc_text, 
	glob_rec_batchhead.entry_code, 
	glob_rec_batchhead.jour_code, 
	glob_rec_batchhead.jour_date 

	LET l_msgresp = kandoomsg("G",1041,"") 

	#1041 Enter Batch Information - ESC TO Continue
	INPUT l_file_text, 
	l_path_text, 
	glob_rec_batchhead.jour_code, 
	glob_rec_batchhead.year_num, 
	glob_rec_batchhead.period_num, 
	glob_rec_batchhead.control_amt, 
	glob_rec_batchhead.com1_text, 
	glob_rec_batchhead.com2_text WITHOUT DEFAULTS 
	FROM
	file_text, 
	path_text, 
	batchhead.jour_code, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.control_amt, 
	batchhead.com1_text, 
	batchhead.com2_text 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G27","input-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield (jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_batchhead.jour_code = l_temp_text 
			END IF 
			NEXT FIELD jour_code 

		AFTER FIELD jour_code 
			IF glob_rec_batchhead.jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 must be entered
				NEXT FIELD jour_code 
			END IF 
			SELECT * INTO l_journal.* FROM journal 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_code = glob_rec_batchhead.jour_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT exists
				NEXT FIELD jour_code 
			END IF 
			IF l_journal.gl_flag != "Y" THEN 
				LET l_msgresp = kandoomsg("G",7015,"") 
				#7105 journal does NOT allow entry
				NEXT FIELD jour_code 
			END IF 
			DISPLAY BY NAME l_journal.desc_text 

		AFTER FIELD file_text 
			IF l_file_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9166,"") 
				#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 

		AFTER FIELD path_text 
			IF l_path_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",8015,"") 
				#8015 Warning: Current directory will be defaulted
			END IF 

		BEFORE FIELD control_amt 
			IF glob_rec_glparms.control_tot_flag != 'Y' THEN 
				LET glob_rec_batchhead.control_amt = 0 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD control_amt 
			IF glob_rec_batchhead.control_amt < 0 THEN 
				LET l_msgresp = kandoomsg('G',9048,'') 
				#9048 Control Amount must be greater than zero
				NEXT FIELD control_amt 
			END IF 

		AFTER INPUT 
			IF NOT ( int_flag OR quit_flag ) THEN 
				IF glob_rec_batchhead.jour_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 must be entered
					NEXT FIELD jour_code 
				END IF 
				SELECT * INTO l_journal.* FROM journal 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_code = glob_rec_batchhead.jour_code 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT exists
					NEXT FIELD jour_code 
				END IF 
				IF l_journal.gl_flag != "Y" THEN 
					LET l_msgresp = kandoomsg("G",7015,"") 
					#7105 journal does NOT allow entry
					NEXT FIELD jour_code 
				END IF 
				IF glob_rec_batchhead.control_amt < 0 THEN 
					LET l_msgresp = kandoomsg('G',9048,'') 
					#9048 Control Amount must be greater than zero
					NEXT FIELD control_amt 
				END IF 
				CALL valid_period( glob_rec_kandoouser.cmpy_code, 
				glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				'GL') 
				RETURNING glob_rec_batchhead.year_num, 
				glob_rec_batchhead.period_num, 
				l_failed 
				IF l_failed THEN 
					NEXT FIELD year_num 
				END IF 
				IF NOT create_load_file( l_path_text , 
				l_file_text ) THEN 
					NEXT FIELD file_text 
				END IF 
			END IF 
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
# FUNCTION insert_batch( p_where_text, p_load_cmpy )
#
#
############################################################
FUNCTION insert_batch( p_where_text, p_load_cmpy ) 
	DEFINE p_where_text CHAR(400)
	DEFINE p_load_cmpy LIKE company.cmpy_code
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	
	DEFINE l_query_text CHAR(400)
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_period_num LIKE batchhead.period_num
	DEFINE l_year_num LIKE batchhead.year_num
	DEFINE l_tran_qty LIKE batchdetl.debit_amt
	--DEFINE L_temp_text CHAR(80)
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_tran_date LIKE batchdetl.tran_date 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_rpt_idx = glob_rpt_idx #needs changing to local scope
	LET l_tran_date = 0 
	IF p_load_cmpy IS NULL THEN 
		LET p_load_cmpy = glob_rec_kandoouser.cmpy_code 
	ELSE 
		SELECT 1 FROM company 
		WHERE cmpy_code = p_load_cmpy 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			LET glob_err_message = "Company: ",p_load_cmpy clipped, " NOT SET up" 
	
			#---------------------------------------------------------
			OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', '', '', '', glob_err_message,'')  
			#---------------------------------------------------------			
			RETURN false 
		END IF 
	END IF 
	
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(glob_err_message, status) != "Y" THEN 
		LET glob_err2_cnt = glob_err2_cnt + 1 
		#---------------------------------------------------------
		OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', '', '', '', glob_err_message,'')  
		#---------------------------------------------------------			

		RETURN false 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	
	BEGIN WORK 
	
		DECLARE c_glparms CURSOR FOR 
		SELECT * FROM glparms 
		WHERE glparms.cmpy_code = p_load_cmpy 
		AND glparms.key_code = '1' 
		FOR UPDATE 
		OPEN c_glparms 
		FETCH c_glparms INTO glob_rec_glparms.* 
		IF glob_rec_glparms.next_load_num IS NULL THEN 
			LET glob_rec_glparms.next_load_num = 0 
		END IF 
		LET glob_rec_glparms.next_load_num = glob_rec_glparms.next_load_num + 1 
		LET glob_rec_glparms.next_jour_num = glob_rec_glparms.next_jour_num + 1 
		UPDATE glparms 
		SET next_load_num = glob_rec_glparms.next_load_num, 
		next_jour_num = glob_rec_glparms.next_jour_num 
		WHERE glparms.cmpy_code = p_load_cmpy 
		AND glparms.key_code = '1' 
		CLOSE c_glparms 
		# all batch header details SET up outside this
		# FUNCTION are held in the global variable glob_rec_batchhead
		# AND are reset prior TO creating each new batch
		LET l_rec_batchhead.* = glob_rec_batchhead.* 
		LET l_rec_batchhead.cmpy_code = p_load_cmpy 
		LET l_rec_batchhead.jour_num = glob_rec_glparms.next_jour_num 
		LET l_rec_batchhead.debit_amt = 0 
		LET l_rec_batchhead.credit_amt = 0 
		LET l_rec_batchhead.for_debit_amt = 0 
		LET l_rec_batchhead.for_credit_amt = 0 
		LET l_rec_batchhead.stats_qty = 0 
		LET l_rec_batchhead.seq_num = 0 
		LET l_rec_batchhead.rate_type_ind = 'B' 
		LET l_rec_batchhead.source_ind = 'G' 
		LET l_rec_batchhead.post_flag = 'N' 
		
		IF glob_rec_glparms.use_clear_flag = 'Y' THEN 
			LET l_rec_batchhead.cleared_flag = 'N' 
		ELSE 
			LET l_rec_batchhead.cleared_flag = 'Y' 
		END IF 
		
		IF l_rec_batchhead.year_num IS NULL 
		OR l_rec_batchhead.period_num IS NULL THEN 
		
			CALL get_fiscal_year_period_for_date( l_rec_batchhead.cmpy_code, 
			l_rec_batchhead.jour_date ) 
			RETURNING l_year_num, 
			l_period_num 
			IF l_year_num IS NULL 
			OR l_period_num IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = 
				"Fiscal Year/Period NOT SET up ", 
				"at Cmpy: ", l_rec_batchhead.cmpy_code," ", 
				"FOR Journal Date:",l_rec_batchhead.jour_date USING "dd/mm/yy" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', '', '', '', glob_err_message,'')  
				#---------------------------------------------------------			
				
				ROLLBACK WORK 
				RETURN false 
			ELSE 
				LET l_rec_batchhead.year_num = l_year_num 
				LET l_rec_batchhead.period_num = l_period_num 
			END IF 
			
		ELSE 
		
			CALL valid_period( 
				p_load_cmpy, 
				l_rec_batchhead.year_num, 
				l_rec_batchhead.period_num, 
				LEDGER_TYPE_GL ) 
			RETURNING 
				l_rec_batchhead.year_num, 
				l_rec_batchhead.period_num, 
				l_invalid_period 
			
			IF l_invalid_period THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = 
					"Fiscal Year/Period NOT SET up ", 
					"at Cmpy: ", l_rec_batchhead.cmpy_code 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', '', '', '', glob_err_message,'')  
				#---------------------------------------------------------			
				ROLLBACK WORK 
				RETURN false 
			END IF 
		END IF 
		LET l_query_text = "SELECT * FROM ", p_where_text clipped, 
		" ORDER BY seq_num " 
		
		PREPARE s_batchdetl FROM l_query_text 
		DECLARE c_batchdetl CURSOR FOR s_batchdetl 
		OPEN c_batchdetl 
		
		FOREACH c_batchdetl INTO l_rec_batchdetl.* 
			LET l_rec_batchhead.seq_num = l_rec_batchhead.seq_num + 1 
			LET l_rec_batchdetl.seq_num = l_rec_batchhead.seq_num 
			LET l_rec_batchdetl.jour_num = glob_rec_glparms.next_jour_num 
			IF l_rec_batchdetl.cmpy_code IS NULL THEN 
				LET l_rec_batchdetl.cmpy_code = l_rec_batchhead.cmpy_code 
			END IF 
			IF l_rec_batchdetl.jour_code IS NULL THEN 
				LET l_rec_batchdetl.jour_code = glob_rec_batchhead.jour_code 
			END IF 
			LET l_rec_batchhead.jour_code = l_rec_batchdetl.jour_code 
			SELECT unique 1 FROM journal 
			WHERE cmpy_code = l_rec_batchhead.cmpy_code 
			AND jour_code = l_rec_batchhead.jour_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Journal:", l_rec_batchhead.jour_code clipped, 
				" NOT SET up AT Cmpy: ", l_rec_batchhead.cmpy_code 

				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------							

				ROLLBACK WORK 
				RETURN false 
			END IF 
			IF l_rec_batchdetl.tran_type_ind IS NULL THEN 
				LET l_rec_batchdetl.tran_type_ind = 'ADJ' 
			END IF 
			IF l_rec_batchdetl.tran_date IS NULL THEN 
				LET l_rec_batchdetl.tran_date = l_rec_batchhead.jour_date 
			END IF 
			IF l_tran_date = 0 THEN 
				LET l_tran_date = l_rec_batchdetl.tran_date 
			END IF 
			IF l_rec_batchdetl.acct_code IS NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Null account code detected" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------								

				ROLLBACK WORK 
				RETURN false 
			ELSE 
				CALL verify_acct( l_rec_batchhead.cmpy_code , 
				l_rec_batchdetl.acct_code , 
				l_rec_batchhead.year_num , 
				l_rec_batchhead.period_num ) 
				RETURNING l_rec_coa.*, 
				glob_err_message 
				IF glob_err_message IS NOT NULL THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
					ROLLBACK WORK 
					RETURN false 
				END IF 
			END IF 
			IF l_rec_batchdetl.desc_text IS NULL THEN 
				LET l_rec_batchdetl.desc_text = l_rec_coa.desc_text 
			END IF 
			IF l_rec_batchdetl.currency_code IS NULL THEN 
				LET l_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code 
				LET l_rec_batchdetl.conv_qty = 1 
			ELSE 
				SELECT 1 FROM currency 
				WHERE currency_code = l_rec_batchdetl.currency_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Currency:",l_rec_batchdetl.currency_code clipped, 
					" NOT SET up AT Cmpy: ", l_rec_batchhead.cmpy_code 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
					ROLLBACK WORK 
					RETURN false 
				END IF 
				IF l_rec_batchdetl.currency_code = glob_rec_glparms.base_currency_code THEN 
					LET l_rec_batchdetl.conv_qty = 1 
				END IF 
			END IF 
			IF l_rec_batchdetl.conv_qty IS NULL THEN 
				LET l_rec_batchdetl.conv_qty = get_conv_rate( 
				l_rec_batchhead.cmpy_code, 
				l_rec_batchdetl.currency_code, 
				l_rec_batchdetl.tran_date, 
				l_rec_batchhead.rate_type_ind ) 
			END IF 
			LET l_rec_batchhead.conv_qty = l_rec_batchdetl.conv_qty 
			LET l_rec_batchhead.currency_code = l_rec_batchdetl.currency_code 
			IF l_rec_batchdetl.debit_amt IS NULL THEN 
				IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
					LET l_rec_batchdetl.debit_amt = 0 
					LET l_rec_batchdetl.for_debit_amt = 0 
				ELSE 
					LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.for_debit_amt 
					/ l_rec_batchdetl.conv_qty 
				END IF 
			ELSE 
				IF l_rec_batchdetl.debit_amt < 0 THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "DB amount must be positive" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
					ROLLBACK WORK 
					RETURN false 
				END IF 
			END IF 
			IF l_rec_batchdetl.for_debit_amt IS NULL THEN 
				IF l_rec_batchdetl.debit_amt IS NULL THEN 
					LET l_rec_batchdetl.debit_amt = 0 
					LET l_rec_batchdetl.for_debit_amt = 0 
				ELSE 
					LET l_rec_batchdetl.for_debit_amt = l_rec_batchdetl.debit_amt 
					* get_conv_rate( 
					l_rec_batchdetl.cmpy_code, 
					l_rec_batchdetl.currency_code, 
					l_rec_batchdetl.tran_date, 
					l_rec_batchhead.rate_type_ind ) 
				END IF 
			ELSE 
				IF l_rec_batchdetl.for_debit_amt < 0 THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Foreign DB must be positive" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
					ROLLBACK WORK 
					RETURN false 
				END IF 
			END IF 
			IF l_rec_batchdetl.credit_amt IS NULL THEN 
				IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
					LET l_rec_batchdetl.credit_amt = 0 
					LET l_rec_batchdetl.for_credit_amt = 0 
				ELSE 
					LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.for_credit_amt 
					/ l_rec_batchdetl.conv_qty 
				END IF 
			ELSE 
				IF l_rec_batchdetl.credit_amt < 0 THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "CR amount must be positive" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				 
					ROLLBACK WORK 
					RETURN false 
				END IF 
			END IF 
			IF l_rec_batchdetl.for_credit_amt IS NULL THEN 
				IF l_rec_batchdetl.credit_amt IS NULL THEN 
					LET l_rec_batchdetl.credit_amt = 0 
					LET l_rec_batchdetl.for_credit_amt = 0 
				ELSE 
					LET l_rec_batchdetl.for_credit_amt = l_rec_batchdetl.credit_amt 
					* get_conv_rate( 
					l_rec_batchdetl.cmpy_code, 
					l_rec_batchdetl.currency_code, 
					l_rec_batchdetl.tran_date, 
					l_rec_batchhead.rate_type_ind) 
				END IF 
			ELSE 
				IF l_rec_batchdetl.for_credit_amt < 0 THEN 
					LET glob_err_cnt = glob_err_cnt + 1 
					LET glob_err_message = "Foreign CR must be positive" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
					ROLLBACK WORK 
					RETURN false 
				END IF 
			END IF 
			LET l_tran_qty = l_rec_batchdetl.for_debit_amt 
			/ l_rec_batchdetl.conv_qty 
			IF l_rec_batchdetl.debit_amt != l_tran_qty THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Foreign DB conversion error" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
				ROLLBACK WORK 
				RETURN false 
			END IF 
			#
			# credit_amt --- conv_qty ---> for_credit_amt
			#
			LET l_tran_qty = l_rec_batchdetl.for_credit_amt 
			/ l_rec_batchdetl.conv_qty 
			IF l_rec_batchdetl.credit_amt != l_tran_qty THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Foreign CR conversion error" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
				ROLLBACK WORK 
				RETURN false 
			END IF 
			IF l_rec_batchdetl.credit_amt > 0 
			AND l_rec_batchdetl.credit_amt IS NOT NULL 
			AND l_rec_batchdetl.debit_amt > 0 
			AND l_rec_batchdetl.debit_amt IS NOT NULL THEN 
				LET glob_err_cnt = glob_err_cnt + 1 
				LET glob_err_message = "Cannot have both a DB & CR entry" 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				
				ROLLBACK WORK 
				RETURN false 
			END IF 
			LET glob_err_message = "G27 - Detail INSERT failed" 
			INSERT INTO batchdetl VALUES ( l_rec_batchdetl.* ) 
			LET l_rec_batchhead.credit_amt = l_rec_batchhead.credit_amt + l_rec_batchdetl.credit_amt 
			LET l_rec_batchhead.debit_amt = l_rec_batchhead.debit_amt + l_rec_batchdetl.debit_amt 
			LET l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_debit_amt + l_rec_batchdetl.for_debit_amt 
			LET l_rec_batchhead.for_credit_amt = l_rec_batchhead.for_credit_amt + l_rec_batchdetl.for_credit_amt 
			LET l_rec_batchhead.stats_qty = l_rec_batchhead.stats_qty + l_rec_batchdetl.stats_qty 
			
		END FOREACH --------------------------------------------------------------------------------

		LET l_rec_batchhead.control_qty = l_rec_batchhead.stats_qty 
		IF l_rec_batchhead.control_qty IS NULL THEN 
			LET l_rec_batchhead.control_qty = 0 
		END IF 
		#
		# IF INPUT of control totals has been by-passed,
		#    THEN default it TO the total batchhead debit_amt
		#
		IF l_rec_batchhead.control_amt IS NULL THEN 
			IF glob_rec_glparms.control_tot_flag = 'N' THEN 
				LET l_rec_batchhead.control_amt = 0 
			ELSE 
				LET l_rec_batchhead.control_amt = l_rec_batchhead.debit_amt 
			END IF 
		END IF 
		#
		#
		# IF the batch header foreign credits = debits THEN we must ensure
		# that the base credits = debits ( there may be some round off in the
		# currency coversion ).
		# Any difference between base debits & credits IS absorbed by the
		# last line of the batch.
		#
		#
		IF l_rec_batchhead.for_debit_amt = l_rec_batchhead.for_credit_amt 
		AND l_rec_batchhead.debit_amt != l_rec_batchhead.credit_amt THEN 
			IF l_rec_batchdetl.credit_amt != 0 THEN 
				LET l_rec_batchdetl.credit_amt = l_rec_batchdetl.credit_amt 
				+ ( l_rec_batchhead.debit_amt 
				- l_rec_batchhead.credit_amt ) 
				LET l_rec_batchhead.credit_amt = l_rec_batchhead.debit_amt 
			ELSE 
				LET l_rec_batchdetl.debit_amt = l_rec_batchdetl.debit_amt 
				+ ( l_rec_batchhead.credit_amt 
				- l_rec_batchhead.debit_amt ) 
				LET l_rec_batchhead.debit_amt = l_rec_batchhead.credit_amt 
			END IF 
			UPDATE batchdetl 
			SET credit_amt = l_rec_batchdetl.credit_amt, 
			debit_amt = l_rec_batchdetl.debit_amt 
			WHERE cmpy_code = l_rec_batchhead.cmpy_code 
			AND jour_num = l_rec_batchhead.jour_num 
			AND seq_num = l_rec_batchhead.seq_num 
		END IF 
		IF NOT l_rec_batchhead.debit_amt 
		AND NOT l_rec_batchhead.credit_amt THEN 
			LET glob_err_cnt = glob_err_cnt + 1 
			LET glob_err_message = "Zero value batch detected", 
			" FOR Cmpy: ", l_rec_batchhead.cmpy_code 
			INITIALIZE l_rec_batchdetl.* TO NULL 
				#---------------------------------------------------------
				OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,'', 
				l_rec_batchdetl.acct_code, 
				l_rec_batchdetl.debit_amt, 
				l_rec_batchdetl.credit_amt, 
				glob_err_message, 
				'') 
				#---------------------------------------------------------				 
			ROLLBACK WORK 
			RETURN false 
		ELSE 
			INITIALIZE l_rec_batchdetl.* TO NULL 
			LET glob_err_message = "G27 - Header INSERT failed" 

			CALL fgl_winmessage("7 Learning batch head codes - tell Hubert",l_rec_batchhead.source_ind,"info") 
			INSERT INTO batchhead VALUES ( l_rec_batchhead.* ) 
		END IF 
		
	COMMIT WORK 
	
	WHENEVER ERROR stop 
	
	LET glob_kandoo_gl_cnt = glob_kandoo_gl_cnt + 1 
	LET glob_err_message = "Batch successfully added FOR Company: ", l_rec_batchhead.cmpy_code 
	
	IF l_rec_batchhead.debit_amt != l_rec_batchhead.credit_amt THEN 
		LET glob_err_message = glob_err_message clipped, " - Batch out of Balance" 
	END IF 
	
	#---------------------------------------------------------
	OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,
	'', '', 
	l_rec_batchhead.debit_amt, 
	l_rec_batchhead.credit_amt, 
	glob_err_message,l_tran_date)
	#---------------------------------------------------------					
	
	LET glob_jour_num = l_rec_batchhead.jour_num 
	
	RETURN true 
END FUNCTION 



############################################################
# FUNCTION create_load_file( p_path_text, p_file_text )
#
#
############################################################
FUNCTION create_load_file( p_path_text, p_file_text ) 
	DEFINE p_path_text CHAR(60)
	DEFINE p_file_text CHAR(20)
	DEFINE l_slash_text char 
	DEFINE l_len_num INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_len_num = length( p_path_text ) 
	INITIALIZE l_slash_text TO NULL 
	IF l_len_num > 0 THEN 
		IF p_path_text[l_len_num,l_len_num] != "\/" THEN 
			LET l_slash_text = "\/" 
		END IF 
	END IF 
	LET glob_load_file = p_path_text clipped, 
	l_slash_text clipped, 
	p_file_text clipped 
	LET glob_load_file = glob_load_file clipped 
	LET glob_load_file = valid_load_file( glob_load_file ) 
	IF glob_load_file IS NULL THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION valid_load_file( p_file_name ) 
#
#
#        1. File NOT found
#        2. No read permission
#        3. File IS Empty
#        4. OTHERWISE
#
############################################################
FUNCTION valid_load_file( p_file_name ) 
	DEFINE p_file_name CHAR(100) 

	DEFINE l_runner CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_ret_code = os.path.exists(p_file_name) --huho changed TO os.path() method 
	#   LET l_runner = " [ -f ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	# run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9160,'') 
		#9160 Load file does NOT exist - check path AND filename
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.readable(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -r ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9162,'') 
		#9162 Unable TO read load file
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.writable(p_file_name) --huho changed TO os.path() method 
	#LET l_runner = " [ -w ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF NOT l_ret_code THEN 
		LET l_msgresp = kandoomsg("A",9173,'') 
		#9173 Unable TO write TO load file
		RETURN "" 
	END IF 

	LET l_ret_code = os.path.size(p_file_name) --huho changed TO os.path() method 

	#LET l_runner = " [ -s ",p_file_name clipped," ] 2>>",trim(get_settings_logFile())
	#run l_runner returning l_ret_code
	IF l_ret_code = -1 THEN 
		LET l_msgresp = kandoomsg("A",9162,'') 
		#9162 Unable TO read load file
	ELSE
		IF l_ret_code = 0 THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
			RETURN "" 
		ELSE 
			RETURN p_file_name 
		END IF
	END IF 
END FUNCTION 


############################################################
# FUNCTION valid_load_file( p_file_name ) 
#
#
#
# - FUNCTION verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
#
############################################################
FUNCTION verify_acct( p_cmpy, p_account_code, p_year_num, p_period_num ) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 
	IF status = NOTFOUND THEN 
		LET l_err_message = "Acct.: ",p_account_code clipped," NOT SET up ", 
		"FOR ", p_year_num USING "####", 
		"/", p_period_num USING "###", 
		" AT Cmpy: ",p_cmpy 
		RETURN l_rec_coa.*, 
		l_err_message clipped 
	ELSE 
		CASE 
			WHEN ( l_rec_coa.start_year_num > p_year_num ) 
				LET l_err_message = "Acct.: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###", 
				" AT Cmpy: ",p_cmpy 
				RETURN l_rec_coa.*, 
				l_err_message clipped 
			WHEN ( l_rec_coa.end_year_num < p_year_num ) 
				LET l_err_message = "Acct.: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###", 
				" AT Cmpy: ",p_cmpy 
				RETURN l_rec_coa.*, 
				l_err_message clipped 
			WHEN ( l_rec_coa.start_year_num = p_year_num AND 
				l_rec_coa.start_period_num > p_period_num ) 
				LET l_err_message = "Acct.: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###", 
				" AT Cmpy: ",p_cmpy 
				RETURN l_rec_coa.*, 
				l_err_message clipped 
			WHEN ( l_rec_coa.end_year_num = p_year_num AND 
				l_rec_coa.end_period_num < p_period_num ) 
				LET l_err_message = "Acct.: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###", 
				" AT Cmpy: ",p_cmpy 
				RETURN l_rec_coa.*, 
				l_err_message clipped 
			OTHERWISE 
				RETURN l_rec_coa.*, 
				'' 
		END CASE 
	END IF 
END FUNCTION 


############################################################
# FUNCTION process_batch() 
#
#
############################################################
FUNCTION process_batch() 
	DEFINE l_text CHAR(100)
	DEFINE l_query_text CHAR(400)
	DEFINE l_where_text CHAR(400) 
	DEFINE l_cmpy_code LIKE company.cmpy_code
	DEFINE l_multiledger_on SMALLINT 
	DEFINE l_multiledger_ind SMALLINT 
	DEFINE l_cmpy_cnt SMALLINT 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_acct_code LIKE validflex.flex_code 
	DEFINE l_currency_code LIKE batchdetl.currency_code 
	DEFINE l_tran_date LIKE batchdetl.tran_date
	DEFINE l_conv_qty LIKE batchdetl.conv_qty
	DEFINE l_start_num,l_length SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE whatsohouldido STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	LET glob_err_cnt = 0 
	LET glob_err2_cnt = 0 
	LET glob_process_cnt = 0 
	LET glob_kandoo_gl_cnt = 0 
	LET glob_total_db_amt = 0 
	LET glob_total_cr_amt = 0
	


	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"G27_rpt_list_bdt","N/A", RPT_SHOW_RMS_DIALOG)
	LET glob_rpt_idx = l_rpt_idx #should all be changed to local scope
	IF glob_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT G27_rpt_list_bdt TO rpt_get_report_file_with_path2(glob_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[glob_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0

	#------------------------------------------------------------
	 

	CALL batch_load()	RETURNING glob_where_text, l_multiledger_ind 
	CASE 
		# KD-1280 put a controlled error message when file does not exist or variable not configured
		# 2020-03-16 ericv
		WHEN l_multiledger_ind = -1
			# value < 0 means file not found (-1) 
			ERROR "Problem with Import batch from file, the parameter glob_load_file is not configured accurately"
			LET whatsohouldido = fgl_winprompt(5,5, "The import file could not be found, please do something", "", 50, 0)
			EXIT PROGRAM
		WHEN l_multiledger_ind = -2
			# glob_load_file not set (-2) in AR parameters
			ERROR "Problem with Import batch from file, the parameter glob_load_file is not configured accurately"
			LET whatsohouldido = fgl_winprompt(5,5, "The load file parameter is not configured, please do something", "", 50, 0)
			EXIT PROGRAM
	END CASE
	IF glob_where_text IS NOT NULL THEN 
		#
		# IF multiple companies exist in batch detail lines THEN
		#    a separate batch will be created FOR each company.
		# OTHERWISE IF detail lines have NOT specified a cmpy_code
		#    THEN cmpy_code will be defaulted TO glob_rec_kandoouser.cmpy_code
		#
		LET l_query_text = " SELECT unique cmpy_code FROM ",glob_where_text clipped 
		PREPARE s_wheretext FROM l_query_text 
		DECLARE c_wheretext CURSOR with HOLD FOR s_wheretext 
		LET l_cmpy_cnt = 0 
		FOREACH c_wheretext INTO l_cmpy_code 
			LET l_cmpy_cnt = l_cmpy_cnt + 1 
			LET l_where_text = glob_where_text clipped, 
			" WHERE cmpy_code = '",l_cmpy_code,"' " 
			LET l_multiledger_on = true 
			SELECT * INTO l_rec_structure.* FROM structure 
			WHERE cmpy_code = l_cmpy_code 
			AND type_ind = "L" 
			IF status = NOTFOUND THEN 
				LET l_multiledger_on = false 
			END IF 
			IF l_multiledger_on 
			AND l_multiledger_ind THEN 
				LET l_start_num = l_rec_structure.start_num 
				LET l_length = l_rec_structure.start_num 
				+ l_rec_structure.length_num 
				- 1 
				LET l_query_text = 
				" SELECT unique acct_code[",l_start_num USING "<<<", 
				",",l_length USING "<<<", "], currency_code,", 
				" tran_date FROM ",glob_where_text clipped 
				PREPARE s2_wheretext FROM l_query_text 
				DECLARE c2_wheretext CURSOR with HOLD FOR s2_wheretext 
				FOREACH c2_wheretext INTO l_acct_code, 
					l_currency_code, 
					l_tran_date 
					LET l_acct_code = l_acct_code clipped,"*" 
					LET l_where_text = glob_where_text clipped, 
					" WHERE cmpy_code = '",l_cmpy_code,"'", 
					" AND acct_code matches '",l_acct_code,"'", 
					" AND currency_code = '",l_currency_code,"'", 
					" AND tran_date = '",l_tran_date,"'" 
					IF insert_batch(l_where_text, l_cmpy_code) THEN 
						CALL del_record(false, l_cmpy_code) 
					END IF 
				END FOREACH 
			ELSE 
				LET l_query_text = 
				" SELECT unique currency_code, tran_date FROM ", 
				glob_where_text clipped 
				PREPARE s3_wheretext FROM l_query_text 
				DECLARE c3_wheretext CURSOR with HOLD FOR s3_wheretext 
				FOREACH c3_wheretext INTO l_currency_code, 
					l_tran_date 
					LET l_where_text = glob_where_text clipped, 
					" WHERE cmpy_code = '",l_cmpy_code,"'", 
					" AND currency_code = '",l_currency_code,"'", 
					" AND tran_date = '",l_tran_date,"'" 
					IF insert_batch(l_where_text, l_cmpy_code) THEN 
						CALL del_record(false, l_cmpy_code) 
					END IF 
				END FOREACH 
			END IF 
		END FOREACH 
		IF l_cmpy_cnt = 0 THEN 
			LET l_multiledger_on = true 
			SELECT * INTO l_rec_structure.* FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "L" 
			IF status = NOTFOUND THEN 
				LET l_multiledger_on = false 
			END IF 
			IF l_multiledger_on 
			AND l_multiledger_ind THEN 
				LET l_start_num = l_rec_structure.start_num 
				LET l_length = l_rec_structure.start_num + l_rec_structure.length_num - 1 
				LET l_query_text = 
				" SELECT unique acct_code[",l_start_num USING "<<<", 
				",",l_length USING "<<<", "], currency_code,", 
				" tran_date FROM ",glob_where_text clipped 
				PREPARE s4_wheretext FROM l_query_text 
				DECLARE c4_wheretext CURSOR with HOLD FOR s4_wheretext 
				FOREACH c4_wheretext INTO l_acct_code, 
					l_currency_code, 
					l_tran_date 
					LET l_acct_code = l_acct_code clipped,"*" 
					LET l_where_text = glob_where_text clipped, 
					" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
					" AND acct_code matches '",l_acct_code,"'", 
					" AND currency_code = '",l_currency_code,"'", 
					" AND tran_date = '",l_tran_date,"'" 
					IF insert_batch(l_where_text, glob_rec_kandoouser.cmpy_code) THEN 
						CALL del_record(false, glob_rec_kandoouser.cmpy_code) 
					END IF 
				END FOREACH 

			ELSE 

				LET l_query_text = 
				" SELECT unique currency_code, tran_date FROM ", 
				glob_where_text clipped 
				PREPARE s5_wheretext FROM l_query_text 
				DECLARE c5_wheretext CURSOR with HOLD FOR s5_wheretext 
				FOREACH c5_wheretext INTO l_currency_code, 
					l_tran_date 
					LET l_where_text = glob_where_text clipped, 
					" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
					" AND currency_code = '",l_currency_code,"'", 
					" AND tran_date = '",l_tran_date,"'" 
					IF insert_batch(l_where_text, glob_rec_kandoouser.cmpy_code) THEN 
						CALL del_record(false, glob_rec_kandoouser.cmpy_code) 
					END IF 
				END FOREACH 
			END IF 
		END IF 

		IF NOT (glob_err_cnt + glob_err2_cnt) THEN 

			#---------------------------------------------------------
			OUTPUT TO REPORT G27_rpt_list_bdt(l_rpt_idx,
			'','','','','gl LOAD completed successfully','') 
			#---------------------------------------------------------					

			
		END IF 
		CALL del_record( true, '' ) 
	END IF 

	IF glob_verbose_ind THEN 
		IF ( glob_err_cnt + glob_err2_cnt ) THEN 
			LET l_msgresp = kandoomsg('G',7022,(glob_err_cnt+glob_err2_cnt)) 
			#7022 Batch Load IS incomplete. <VALUE> errors detected
		ELSE 
			IF glob_kandoo_gl_cnt > 1 THEN 
				LET l_text = glob_jour_num - (glob_kandoo_gl_cnt - 1) USING "<<<<<<<&", 
				" TO ",glob_jour_num USING "<<<<<<<&" 
				LET l_msgresp = kandoomsg('G',7023,l_text) 
				#7023 Batch <VALUE> successfully loaded
			ELSE 
				LET l_msgresp = kandoomsg('G',7023,glob_jour_num) 
				#7023 Batch <VALUE> successfully loaded
			END IF 
		END IF 
	END IF

	#------------------------------------------------------------
	FINISH REPORT G27_rpt_list_bdt
	CALL rpt_finish("G27_rpt_list_bdt")
	#------------------------------------------------------------	 

	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
		 
END FUNCTION



############################################################
# REPORT G27_rpt_list_bdt(p_rpt_idx, p_line_num, p_acct_code, p_debit_amt, p_credit_amt, p_status, p_tran_date)
#
#
############################################################
REPORT G27_rpt_list_bdt(p_rpt_idx, p_line_num, p_acct_code, p_debit_amt, p_credit_amt, p_status, p_tran_date) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_line_num INTEGER
	DEFINE p_acct_code CHAR(18)
	DEFINE p_debit_amt DECIMAL(16,2)
	DEFINE p_credit_amt DECIMAL(16,2) 
	DEFINE p_status CHAR(70)
	DEFINE p_tran_date LIKE batchdetl.tran_date 
	DEFINE l_arr_line array[4] OF CHAR(132) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OUTPUT 
--	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #line1_text

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 

		ON EVERY ROW 
			IF p_acct_code IS NOT NULL THEN 
				IF p_credit_amt IS NULL THEN 
					LET p_credit_amt = 0 
				END IF 
				IF p_debit_amt IS NULL THEN 
					LET p_debit_amt = 0 
				END IF 
			END IF 
			PRINT COLUMN 02, p_line_num USING "###&", 
			COLUMN 10, p_tran_date USING "dd/mm/yyyy", 
			COLUMN 21, p_acct_code, 
			COLUMN 42, p_debit_amt USING "###,###,##&.&&", 
			COLUMN 59, p_credit_amt USING "###,###,##&.&&", 
			COLUMN 76, p_status 
			IF p_debit_amt IS NOT NULL 
			AND p_credit_amt IS NOT NULL THEN 
				LET glob_total_db_amt = glob_total_db_amt + p_debit_amt 
				LET glob_total_cr_amt = glob_total_cr_amt + p_credit_amt 
			END IF 
		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed FROM Batch Load:", 
			COLUMN 56, glob_process_cnt USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 19, "Total records with validation errors:", 
			COLUMN 56, glob_err_cnt USING "###########&", 
			" ( SQL / File errors: ",glob_err2_cnt USING "<<<<&"," )" 
			PRINT COLUMN 16, "Total GL batches successfully processed:", 
			COLUMN 56, glob_kandoo_gl_cnt USING "###########&"; 
			IF glob_kandoo_gl_cnt = 1 THEN 
				PRINT COLUMN 1, " ", 
				"(Batch number: ",glob_jour_num using "<<<<<<<&",")" 
			ELSE 
				IF glob_kandoo_gl_cnt >= 1 THEN 
					PRINT COLUMN 1, " ", "(Batch numbers: ", 
					glob_jour_num - (glob_kandoo_gl_cnt - 1) USING "<<<<<<<&", 
					" TO ",glob_jour_num USING "<<<<<<<&",")" 
				ELSE 
					PRINT COLUMN 1," " 
				END IF 
			END IF 
			PRINT COLUMN 56, "------------" 
			PRINT COLUMN 56, ( glob_err_cnt + glob_kandoo_gl_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 36, "Total debit amounts:", 
			COLUMN 56, glob_total_db_amt USING "--------&.&&" 
			PRINT COLUMN 35, "Total credit amounts:", 
			COLUMN 56, glob_total_cr_amt USING "--------&.&&" 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 

