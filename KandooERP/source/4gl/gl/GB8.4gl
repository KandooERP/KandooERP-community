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
GLOBALS 
	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_page_break CHAR(1) 
	DEFINE glob_where_text CHAR(900) 
	DEFINE glob_temp_text CHAR(100) 
	DEFINE glob_start_num SMALLINT
	DEFINE glob_length_num SMALLINT	
END GLOBALS 
############################################################
# FUNCTION GB8_main() 
#
#  GB8 - Trial Multi-Ledger Posting Report
############################################################
FUNCTION GB8_main() 
	DEFER quit 
	DEFER interrupt  

	CALL setModuleId("GB8") 

	CREATE temp TABLE t_multiledg(flex_code CHAR(18), 
	debit_amt DECIMAL(16,2), 
	credit_amt DECIMAL(16,2), 
	for_debit_amt DECIMAL(16,2), 
	for_credit_amt DECIMAL(16,2)) with no LOG 

	SELECT * INTO glob_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("Ledger Segment Not Set up",kandoomsg2("G",5019,""),"ERROR")	#5019 Ledger Segment Not Set up - Refer Menu GZ3
		EXIT PROGRAM
	END IF

	LET glob_start_num = glob_rec_structure.start_num 
	LET glob_length_num = glob_rec_structure.start_num 	+ glob_rec_structure.length_num - 1

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G157 with FORM "G157" 
			CALL windecoration_g("G157") 
	
		 
			MENU " Trial Multi-Ledger Posting" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GB8","menu-trial-multi-ledger-post") 
					CALL GB8_rpt_process(GB8_rpt_query())
	
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
	
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
	
				ON ACTION "Report" 		#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL GB8_rpt_process(GB8_rpt_query())
	
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
	
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 
	
			END MENU 
			CLOSE WINDOW G157 
 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GB8_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G157 with FORM "G157" 
			CALL windecoration_g("G157") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GB8_rpt_query()) #save where clause in env 
			CLOSE WINDOW G157 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GB8_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 


############################################################
# FUNCTION GB8_rpt_query()
#
#
############################################################
FUNCTION GB8_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue "

	CONSTRUCT BY NAME l_where_text ON batchdetl.jour_code, 
	batchhead.jour_num, 
	batchhead.jour_date, 
	batchdetl.acct_code, 
	batchdetl.analysis_text, 
	batchdetl.desc_text, 
	batchdetl.for_debit_amt, 
	batchdetl.for_credit_amt, 
	batchdetl.stats_qty, 
	batchdetl.ref_text, 
	batchhead.year_num, 
	batchhead.period_num, 
	batchhead.currency_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GB8","construct-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	CALL segment_con(glob_rec_kandoouser.cmpy_code, "batchdetl") 
	RETURNING glob_temp_text 
	IF glob_temp_text IS NULL THEN 
		RETURN false 
	END IF 

	LET l_where_text = l_where_text clipped, " ", glob_temp_text 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Generation aborted"
		RETURN NULL
	ELSE
		LET l_msgresp = kandoomsg("G",3510,"") 
		LET glob_page_break = upshift(l_msgresp) 
		IF glob_page_break IS NULL THEN 
			LET glob_page_break = "Y" 
		END IF 
		LET glob_rec_rpt_selector.ref3_ind = glob_page_break
		RETURN l_where_text
	END IF 
END FUNCTION

#####################################################################
# FUNCTION GB8_rpt_process(p_where_text) 
#
#
#####################################################################
FUNCTION GB8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_batchdetl RECORD LIKE batchdetl.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GB8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GB8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB8_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_page_break = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB8_rpt_list")].ref3_ind
	
	LET l_query_text = "SELECT unique batchdetl.* FROM batchdetl, batchhead ", 
	"WHERE batchdetl.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
	"AND batchhead.jour_num = batchdetl.jour_num ", 
	"AND batchhead.jour_code = batchdetl.jour_code ", 
	"AND batchhead.post_flag = 'N' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GB8_rpt_list")].sel_text clipped, " ", 
	"ORDER BY batchdetl.jour_num " 
	PREPARE s_batchdetl FROM l_query_text 
	DECLARE c_batchdetl CURSOR FOR s_batchdetl 

	LET l_query_text = "SELECT note_text, note_num FROM notes ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code,"' ", 
	"AND note_code = ? ", 
	"ORDER BY note_num" 
	PREPARE s_notes FROM l_query_text 
	DECLARE c_notes CURSOR FOR s_notes 

	FOREACH c_batchdetl INTO l_rec_batchdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GB8_rpt_list(l_rpt_idx,l_rec_batchdetl.*) 
		IF NOT rpt_int_flag_handler2("Batch:",l_rec_batchdetl.jour_num , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GB8_rpt_list
	CALL rpt_finish("GB8_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


############################################################
# REPORT GB8_rpt_list(p_rec_batchdetl)
#
#
############################################################
REPORT GB8_rpt_list(p_rec_batchdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.*
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_deb_amt LIKE batchdetl.debit_amt
	DEFINE l_cred_amt LIKE batchdetl.debit_amt
	DEFINE l_for_deb_amt LIKE batchdetl.for_debit_amt
	DEFINE l_for_cred_amt LIKE batchdetl.for_debit_amt
	DEFINE l_grp_debit LIKE batchdetl.debit_amt
	DEFINE l_grp_credit LIKE batchdetl.debit_amt
	DEFINE l_grp_for_debit LIKE batchdetl.for_debit_amt
	DEFINE l_grp_for_credit LIKE batchdetl.for_debit_amt
	DEFINE l_flex1_code LIKE validflex.flex_code 
	DEFINE l_flex2_code LIKE validflex.flex_code 
	DEFINE l_acct_code LIKE ledgerreln.acct1_code 
	DEFINE l_note_mark1 CHAR(3) 
	DEFINE l_note_mark2 CHAR(3) 
	DEFINE l_note_info CHAR(70) 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE i SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	DEFINE l_post_err SMALLINT 
	DEFINE l_status_ind SMALLINT 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_batchdetl.jour_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 002,"Seq", 
			COLUMN 007,"Type", 
			COLUMN 014,"Account", 
			COLUMN 046,"Curr", 
			COLUMN 052,"Exch", 
			COLUMN 058,"------------ BASE VALUES ------------", 
			COLUMN 096,"---------- FOREIGN VALUES -----------" 
			PRINT COLUMN 014,"Description", 
			COLUMN 046,"Code", 
			COLUMN 052,"Rate", 
			COLUMN 070,"Debit", 
			COLUMN 088,"Credit", 
			COLUMN 108,"Debit", 
			COLUMN 126,"Credit" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

		ON EVERY ROW 
			NEED 3 LINES 
			PRINT COLUMN 001,p_rec_batchdetl.seq_num USING "####&", 
			COLUMN 007,p_rec_batchdetl.tran_type_ind, 
			COLUMN 012,p_rec_batchdetl.acct_code, 
			COLUMN 046,p_rec_batchdetl.currency_code, 
			COLUMN 050,p_rec_batchdetl.conv_qty USING "##&.&&&", 
			COLUMN 059,p_rec_batchdetl.debit_amt USING "--,---,---,--&.&&", 
			COLUMN 078,p_rec_batchdetl.credit_amt USING "--,---,---,--&.&&", 
			COLUMN 097,p_rec_batchdetl.for_debit_amt USING "--,---,---,--&.&&", 
			COLUMN 116,p_rec_batchdetl.for_credit_amt USING "--,---,---,--&.&&" 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_batchdetl.acct_code 
			IF status = NOTFOUND THEN 
				LET p_rec_batchdetl.desc_text = "***** Account Not Found *****" 
				LET l_post_err = 1 
			ELSE 
				IF open_acct(l_rec_coa.*,l_rec_batchhead.*) THEN 
					LET p_rec_batchdetl.desc_text = "****** Account Not Open ******" 
					LET l_post_err = 1 
				END IF 
			END IF 
			PRINT COLUMN 012,p_rec_batchdetl.desc_text 
			LET l_note_mark1 = p_rec_batchdetl.desc_text[1,3] 
			LET l_note_mark2 = p_rec_batchdetl.desc_text[14,17] 
			IF l_note_mark1 = "###" 
			AND l_note_mark2 = "###" THEN 
				LET glob_temp_text = p_rec_batchdetl.desc_text[4,14] 
				OPEN c_notes USING glob_temp_text 
				FOREACH c_notes INTO l_note_info,l_cnt 
					PRINT COLUMN 22, l_note_info 
				END FOREACH 
			END IF 
			
			LET l_flex1_code = p_rec_batchdetl.acct_code[glob_start_num,glob_length_num] 
			SELECT unique 1 FROM t_multiledg 
			WHERE flex_code = l_flex1_code 
			IF status = NOTFOUND THEN 
				INSERT INTO t_multiledg VALUES (l_flex1_code, 
				p_rec_batchdetl.debit_amt, 
				p_rec_batchdetl.credit_amt, 
				p_rec_batchdetl.for_debit_amt, 
				p_rec_batchdetl.for_credit_amt) 
			ELSE 
				UPDATE t_multiledg 
				SET debit_amt = debit_amt + p_rec_batchdetl.debit_amt, 
				credit_amt = credit_amt + p_rec_batchdetl.credit_amt, 
				for_debit_amt = for_debit_amt + p_rec_batchdetl.for_debit_amt, 
				for_credit_amt = for_credit_amt + p_rec_batchdetl.for_credit_amt 
				WHERE flex_code = l_flex1_code 
			END IF 

		BEFORE GROUP OF p_rec_batchdetl.jour_num 
			NEED 6 LINES 
			DELETE FROM t_multiledg WHERE 1=1 
			LET l_post_err = 0 
			IF glob_page_break = "Y" THEN 
				SKIP TO top OF PAGE 
			END IF 
			SELECT * INTO l_rec_batchhead.* FROM batchhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jour_num = p_rec_batchdetl.jour_num 
			AND jour_code = p_rec_batchdetl.jour_code 
			PRINT COLUMN 01,"Batch: ", p_rec_batchdetl.jour_num 
			PRINT COLUMN 05,"Date: ", l_rec_batchhead.jour_date, 
			COLUMN 25,"Posting Period: ", l_rec_batchhead.year_num, "/", 
			l_rec_batchhead.period_num USING "<<<<<", 
			COLUMN 55,"Entered By: ", l_rec_batchhead.entry_code 
			PRINT COLUMN 05,"Cleared : ", l_rec_batchhead.cleared_flag, 
			COLUMN 25,"Posting Run: ", l_rec_batchhead.post_run_num USING "#######" 
			IF l_rec_batchhead.com1_text IS NOT NULL THEN 
				PRINT COLUMN 05,"Comments:", 
				COLUMN 16,l_rec_batchhead.com1_text 
			END IF 
			IF l_rec_batchhead.com2_text IS NOT NULL THEN 
				PRINT COLUMN 05,"Comments :", 
				COLUMN 16,l_rec_batchhead.com2_text 
			END IF 

		AFTER GROUP OF p_rec_batchdetl.jour_num 
			NEED 3 LINES 
			LET l_grp_debit = GROUP sum(p_rec_batchdetl.debit_amt) 
			LET l_grp_credit = GROUP sum(p_rec_batchdetl.credit_amt) 
			LET l_grp_for_debit = GROUP sum(p_rec_batchdetl.for_debit_amt) 
			LET l_grp_for_credit = GROUP sum(p_rec_batchdetl.for_credit_amt) 
			LET l_status_ind = ledg_status() 
			IF l_status_ind = 2 THEN 
				PRINT COLUMN 01, "Unable TO resolve Multiple Relationships" 
			END IF 
			#-------------------------------------------------------------
			IF l_status_ind = 8 THEN #working with d e b i t s 
				#
				SELECT flex_code INTO l_flex1_code FROM t_multiledg 
				WHERE debit_amt > 0 
				DECLARE cred_curs CURSOR FOR 
				SELECT flex_code FROM t_multiledg 
				WHERE credit_amt > 0 
				FOREACH cred_curs INTO l_flex2_code 
					IF l_flex1_code = l_flex2_code THEN 
						CONTINUE FOREACH 
						#loop around TO get others
					END IF 
					SELECT * INTO l_rec_ledgerreln.* FROM ledgerreln 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND flex1_code = l_flex1_code 
					AND flex2_code = l_flex2_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_ledgerreln.* FROM ledgerreln 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND flex1_code = l_flex2_code 
						AND flex2_code = l_flex1_code 
						IF status = NOTFOUND THEN 
							PRINT COLUMN 01, "Undefined relationships between Ledgers ", 
							l_flex1_code clipped, " AND ", 
							l_flex2_code clipped 
							# missing relationships   ==> REJECT the Batch
							LET l_status_ind = 3 
							CONTINUE FOREACH 
							#loop around TO get others
						END IF 
					END IF 
					#IF we found missing relationships THEN skip printing, do valid ones
					IF l_status_ind != 3 THEN 
						IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
							LET l_acct_code = l_rec_ledgerreln.acct1_code 
						ELSE 
							LET l_acct_code = l_rec_ledgerreln.acct2_code 
						END IF 
						LET l_deb_amt = 0 
						LET l_for_deb_amt = 0 
						SELECT sum(credit_amt) INTO l_cred_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						SELECT sum(for_credit_amt) INTO l_for_cred_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						LET p_rec_batchdetl.seq_num = p_rec_batchdetl.seq_num + 1 
						PRINT COLUMN 001,p_rec_batchdetl.seq_num USING "####&", 
						COLUMN 007,"ML", 
						COLUMN 011,"*", 
						COLUMN 012,l_acct_code, 
						COLUMN 046,p_rec_batchdetl.currency_code, 
						COLUMN 050,p_rec_batchdetl.conv_qty USING "##&.&&&", 
						COLUMN 059,l_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 078,l_deb_amt USING "--,---,---,--&.&&", 
						COLUMN 097,l_for_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 116,l_for_deb_amt USING "--,---,---,--&.&&" 
						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = l_acct_code 
						IF status = NOTFOUND THEN 
							LET l_rec_coa.desc_text = "***** Account Not Found *****" 
							LET l_post_err = 1 
						ELSE 
							IF open_acct(l_rec_coa.*,l_rec_batchhead.*) THEN 
								LET l_rec_coa.desc_text = "****** Account Not Open ******" 
								LET l_post_err = 1 
							END IF 
						END IF 
						PRINT COLUMN 012,l_rec_coa.desc_text 
						LET l_grp_debit = l_grp_debit + l_deb_amt 
						LET l_grp_credit = l_grp_credit + l_cred_amt 
						LET l_grp_for_debit = l_grp_for_debit + l_for_deb_amt 
						LET l_grp_for_credit = l_grp_for_credit + l_for_cred_amt 
						# now do the other side of the entry
						IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
							LET l_acct_code = l_rec_ledgerreln.acct2_code 
						ELSE 
							LET l_acct_code = l_rec_ledgerreln.acct1_code 
						END IF 
						LET l_cred_amt = 0 
						LET l_for_cred_amt = 0 
						SELECT sum(credit_amt) INTO l_deb_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						SELECT sum(for_credit_amt) INTO l_for_deb_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						LET p_rec_batchdetl.seq_num = p_rec_batchdetl.seq_num + 1 
						PRINT COLUMN 001,p_rec_batchdetl.seq_num USING "####&", 
						COLUMN 007,"ML", 
						COLUMN 011,"*", 
						COLUMN 012,l_acct_code, 
						COLUMN 046,p_rec_batchdetl.currency_code, 
						COLUMN 050,p_rec_batchdetl.conv_qty USING "##&.&&&", 
						COLUMN 059,l_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 078,l_deb_amt USING "--,---,---,--&.&&", 
						COLUMN 097,l_for_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 116,l_for_deb_amt USING "--,---,---,--&.&&" 
						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = l_acct_code 
						IF status = NOTFOUND THEN 
							LET l_rec_coa.desc_text = "***** Account Not Found *****" 
							LET l_post_err = 1 
						ELSE 
							IF open_acct(l_rec_coa.*,l_rec_batchhead.*) THEN 
								LET l_rec_coa.desc_text = "****** Account Not Open ******" 
								LET l_post_err = 1 
							END IF 
						END IF 
						PRINT COLUMN 012,l_rec_coa.desc_text 
						LET l_grp_debit = l_grp_debit + l_deb_amt 
						LET l_grp_credit = l_grp_credit + l_cred_amt 
						LET l_grp_for_debit = l_grp_for_debit + l_for_deb_amt 
						LET l_grp_for_credit = l_grp_for_credit + l_for_cred_amt 
					END IF 
				END FOREACH 
			END IF 

			#---------------------------------------------------------------

			IF l_status_ind = 9 THEN #working with c r e d i t s 
				#
				SELECT flex_code INTO l_flex1_code FROM t_multiledg 
				WHERE credit_amt > 0 
				DECLARE deb_curs CURSOR FOR 
				SELECT flex_code FROM t_multiledg 
				WHERE debit_amt > 0 
				FOREACH deb_curs INTO l_flex2_code 
					IF l_flex1_code = l_flex2_code THEN 
						CONTINUE FOREACH 
						#loop around TO get others
					END IF 
					SELECT * INTO l_rec_ledgerreln.* FROM ledgerreln 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND flex1_code = l_flex1_code 
					AND flex2_code = l_flex2_code 
					IF status = NOTFOUND THEN 
						SELECT * INTO l_rec_ledgerreln.* FROM ledgerreln 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND flex1_code = l_flex2_code 
						AND flex2_code = l_flex1_code 
						IF status = NOTFOUND THEN 
							PRINT COLUMN 01, "Undefined relationships between Ledgers ", 
							l_flex1_code clipped, " AND ", 
							l_flex2_code clipped 
							# missing relationships   ==> REJECT the Batch
							LET l_status_ind = 3 
							CONTINUE FOREACH 
							#loop around TO get others
						END IF 
					END IF 
					#IF we found missing relationships THEN skip printing valid ones
					IF l_status_ind != 3 THEN 
						IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
							LET l_acct_code = l_rec_ledgerreln.acct1_code 
						ELSE 
							LET l_acct_code = l_rec_ledgerreln.acct2_code 
						END IF 
						LET l_cred_amt = 0 
						LET l_for_cred_amt = 0 
						SELECT sum(debit_amt) INTO l_deb_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						SELECT sum(for_debit_amt) INTO l_for_deb_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						LET p_rec_batchdetl.seq_num = p_rec_batchdetl.seq_num + 1 
						PRINT COLUMN 001,p_rec_batchdetl.seq_num USING "####&", 
						COLUMN 007,"ML", 
						COLUMN 011,"*", 
						COLUMN 012,l_acct_code, 
						COLUMN 046,p_rec_batchdetl.currency_code, 
						COLUMN 050,p_rec_batchdetl.conv_qty USING "##&.&&&", 
						COLUMN 059,l_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 078,l_deb_amt USING "--,---,---,--&.&&", 
						COLUMN 097,l_for_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 116,l_for_deb_amt USING "--,---,---,--&.&&" 

						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = l_acct_code 
						IF status = NOTFOUND THEN 
							LET l_rec_coa.desc_text = "***** Account Not Found *****" 
							LET l_post_err = 1 
						ELSE 
							IF open_acct(l_rec_coa.*,l_rec_batchhead.*) THEN 
								LET l_rec_coa.desc_text = "****** Account Not Open ******" 
								LET l_post_err = 1 
							END IF 
						END IF 

						PRINT COLUMN 012,l_rec_coa.desc_text 
						LET l_grp_debit = l_grp_debit + l_deb_amt 
						LET l_grp_credit = l_grp_credit + l_cred_amt 
						LET l_grp_for_debit = l_grp_for_debit + l_for_deb_amt 
						LET l_grp_for_credit = l_grp_for_credit + l_for_cred_amt 
						# now do the other side
						IF l_flex2_code = l_rec_ledgerreln.flex1_code THEN 
							LET l_acct_code = l_rec_ledgerreln.acct2_code 
						ELSE 
							LET l_acct_code = l_rec_ledgerreln.acct1_code 
						END IF 
						LET l_deb_amt = 0 
						LET l_for_deb_amt = 0 
						SELECT sum(debit_amt) INTO l_cred_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						SELECT sum(for_debit_amt) INTO l_for_cred_amt FROM t_multiledg 
						WHERE flex_code = l_flex2_code 
						LET p_rec_batchdetl.seq_num = p_rec_batchdetl.seq_num + 1 
						PRINT COLUMN 001,p_rec_batchdetl.seq_num USING "####&", 
						COLUMN 007,"ML", 
						COLUMN 011,"*", 
						COLUMN 012,l_acct_code, 
						COLUMN 046,p_rec_batchdetl.currency_code, 
						COLUMN 050,p_rec_batchdetl.conv_qty USING "##&.&&&", 
						COLUMN 059,l_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 078,l_deb_amt USING "--,---,---,--&.&&", 
						COLUMN 097,l_for_cred_amt USING "--,---,---,--&.&&", 
						COLUMN 116,l_for_deb_amt USING "--,---,---,--&.&&" 
						SELECT * INTO l_rec_coa.* FROM coa 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND acct_code = l_acct_code 
						IF status = NOTFOUND THEN 
							LET l_rec_coa.desc_text = "***** Account Not Found *****" 
							LET l_post_err = 1 
						ELSE 
							IF open_acct(l_rec_coa.*,l_rec_batchhead.*) THEN 
								LET l_rec_coa.desc_text = "****** Account Not Open ******" 
								LET l_post_err = 1 
							END IF 
						END IF 

						PRINT COLUMN 012,l_rec_coa.desc_text 
						LET l_grp_debit = l_grp_debit + l_deb_amt 
						LET l_grp_credit = l_grp_credit + l_cred_amt 
						LET l_grp_for_debit = l_grp_for_debit + l_for_deb_amt 
						LET l_grp_for_credit = l_grp_for_credit + l_for_cred_amt 
					END IF 

				END FOREACH 

			END IF 

			CASE l_status_ind 
				WHEN 2 
					NEED 4 LINES 
					PRINT COLUMN 01, "*******************************" 
					PRINT COLUMN 01, "** BATCH WOULD BE REJECTED **" 
					PRINT COLUMN 01, "*******************************" 
				WHEN 3 
					NEED 4 LINES 
					PRINT COLUMN 01, "*******************************" 
					PRINT COLUMN 01, "** BATCH WOULD BE REJECTED **" 
					PRINT COLUMN 01, "*******************************" 
				OTHERWISE 
					IF l_post_err THEN 
						NEED 4 LINES 
						PRINT COLUMN 01, "*******************************" 
						PRINT COLUMN 01, "** BATCH WOULD BE REJECTED **" 
						PRINT COLUMN 01, "*******************************" 
					ELSE 
						####l_status_ind = 1(cont'd) OR 8(Debits) OR 9(Credits)
						PRINT COLUMN 001,"Control Total: ",l_rec_batchhead.control_amt USING 
						"----,---,---,--&.&&"," Batch Total : "; 
						PRINT COLUMN 058,l_grp_debit USING "---,---,---,--&.&&", 
						COLUMN 077,l_grp_credit USING "---,---,---,--&.&&", 
						COLUMN 096,l_grp_for_debit USING "---,---,---,--&.&&", 
						COLUMN 115,l_grp_for_credit USING "---,---,---,--&.&&" 
					END IF 
			END CASE 

			SKIP 3 LINES 

		ON LAST ROW 
			NEED 6 LINES 
			PRINT COLUMN 11," * indicates Multi-Ledger balancing entries" 
			SKIP 2 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 


############################################################
# FUNCTION ledg_status()
#
#
############################################################
FUNCTION ledg_status() 
	DEFINE l_deb_amt LIKE batchdetl.debit_amt 
	DEFINE l_cred_amt LIKE batchdetl.debit_amt
	DEFINE l_row_cnt SMALLINT
	DEFINE l_debit_cnt SMALLINT
	DEFINE l_credit_cnt SMALLINT
	DEFINE l_status_ind SMALLINT	 
	DEFINE l_flex_code LIKE validflex.flex_code
	DEFINE l_ledg_debit LIKE batchdetl.debit_amt 
	DEFINE l_ledg_credit LIKE batchdetl.debit_amt 

	SELECT unique 1 FROM t_multiledg 
	IF status = NOTFOUND THEN 
		LET l_status_ind = 1 
		#no batchdetl's                      ==> PRINT group totals only
	ELSE 
		SELECT count(*) INTO l_row_cnt FROM t_multiledg 
		IF l_row_cnt = 1 THEN 
			LET l_status_ind = 1 
			#only one unique flex_code        ==> ie NOT Multi-Ledger
		ELSE 
			SELECT sum(debit_amt) INTO l_deb_amt FROM t_multiledg 
			SELECT sum(credit_amt) INTO l_cred_amt FROM t_multiledg 
			IF l_deb_amt IS NULL THEN 
				LET l_deb_amt = 0 
			END IF 
			IF l_cred_amt IS NULL THEN 
				LET l_cred_amt = 0 
			END IF 
			IF l_deb_amt = 0 
			AND l_cred_amt = 0 THEN 
				LET l_status_ind = 1 
				#debits AND credits = zero     ==> PRINT group totals only
			ELSE 
				SELECT count(*) INTO l_debit_cnt FROM t_multiledg 
				WHERE debit_amt > 0 
				SELECT count(*) INTO l_credit_cnt FROM t_multiledg 
				WHERE credit_amt > 0 
				IF l_debit_cnt > 1 
				AND l_credit_cnt > 1 THEN 
					# IF debits equal credits FOR each ledger, no
					# relationships need TO be resolved
					DECLARE c_multiledg CURSOR FOR 
					SELECT flex_code, sum(debit_amt), sum(credit_amt) 
					FROM t_multiledg 
					GROUP BY 1 
					having sum(debit_amt) <> sum(credit_amt) 
					OPEN c_multiledg 
					FETCH c_multiledg INTO l_flex_code, 
					l_ledg_debit, l_ledg_credit 
					IF status = NOTFOUND THEN 
						LET l_status_ind = 1 
					ELSE 
						LET l_status_ind = 2 
						#Too many relationships    ==> REJECT the Batch
					END IF 
					CLOSE c_multiledg 
				ELSE 
					IF l_debit_cnt = 1 THEN 
						LET l_status_ind = 8 
					ELSE 
						LET l_status_ind = 9 
					END IF 
				END IF 
			END IF 
		END IF 
	END IF 
	RETURN l_status_ind 
END FUNCTION 


############################################################
# FUNCTION ledg_status()
#
#
############################################################
FUNCTION open_acct(p_rec_coa,p_rec_batchhead) 
	DEFINE p_rec_coa RECORD LIKE coa.* 
	DEFINE p_rec_batchhead RECORD LIKE batchhead.* 

	IF ((( p_rec_coa.end_year_num < p_rec_batchhead.year_num) OR 
	(p_rec_coa.end_year_num = p_rec_batchhead.year_num AND 
	p_rec_coa.end_period_num < p_rec_batchhead.period_num)) OR 
	((p_rec_coa.start_year_num > p_rec_batchhead.year_num) OR 
	(p_rec_coa.start_year_num = p_rec_batchhead.year_num AND 
	p_rec_coa.start_period_num > p_rec_batchhead.period_num))) THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION