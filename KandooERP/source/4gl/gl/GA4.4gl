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
DEFINE modu_report_type CHAR(1) 
DEFINE modu_year_num LIKE accounthist.year_num
DEFINE modu_period_num LIKE accounthist.year_num 
DEFINE modu_start_num_1 LIKE structure.start_num
DEFINE modu_start_num_2 LIKE structure.start_num 
DEFINE modu_start_num_3 LIKE structure.start_num
DEFINE modu_end_pos_1 LIKE structure.length_num 
DEFINE modu_end_pos_2 LIKE structure.length_num 
DEFINE modu_end_pos_3 LIKE structure.length_num 
############################################################
# FUNCTION GA4_main()
#
# Purpose - Financial Work Sheet Report
# This REPORT shows total debits AND credits FROM accounthist FOR the
# selected year, period AND accounts with up TO three control breaks
# based on the nominated account segments.
############################################################
FUNCTION GA4_main() 
	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("GA4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW G551 with FORM "G551" 
			CALL windecoration_g("G551") 

			MENU " Financial Work Sheet Report " 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GA4","menu-financial-work-sheet") 
					CALL GA4_rpt_process(GA4_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Run" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL GA4_rpt_process(GA4_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" 	#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 

			CLOSE WINDOW G551 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GA4_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G551 with FORM "G551" 
			CALL windecoration_g("G551") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GA4_rpt_query()) #save where clause in env 
			CLOSE WINDOW G551 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GA4_rpt_process(get_url_sel_text())
	END CASE  
END FUNCTION 


############################################################
# FUNCTION GA4_rpt_query()
#
#
############################################################
FUNCTION GA4_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_desc_text_1 LIKE structure.desc_text
	DEFINE l_desc_text_2 LIKE structure.desc_text
	DEFINE l_desc_text_3 LIKE structure.desc_text 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria
	CALL get_fiscal_year_period_for_date(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING modu_year_num, modu_period_num 
	LET modu_report_type = "1" 
	LET modu_start_num_1 = 0 
	LET modu_start_num_2 = 0 
	LET modu_start_num_3 = 0 
	LET l_desc_text_1 = NULL 
	LET l_desc_text_2 = NULL 
	LET l_desc_text_3 = NULL 
	DISPLAY l_desc_text_1 TO desc_text_1 
	DISPLAY l_desc_text_2 TO desc_text_2 
	DISPLAY l_desc_text_3 TO desc_text_3 


	INPUT 
	modu_report_type, 
	modu_start_num_1, 
	modu_start_num_2, 
	modu_start_num_3, 
	modu_year_num, 
	modu_period_num 
	WITHOUT DEFAULTS 
	FROM
	report_type, 
	start_num_1, 
	start_num_2, 
	start_num_3, 
	year_num, 
	period_num 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GA4","inp-REPORT") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD start_num_1 
			IF modu_start_num_1 <> 0 THEN 
				SELECT desc_text INTO l_desc_text_1 FROM structure 
				WHERE start_num = modu_start_num_1 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_1 = NULL 
					DISPLAY l_desc_text_1 TO desc_text_1

					NEXT FIELD start_num_1 
				END IF 
			ELSE 
				LET l_desc_text_1 = NULL 
			END IF 
			DISPLAY l_desc_text_1 TO desc_text_1  

		AFTER FIELD start_num_2 
			IF modu_start_num_2 <> 0 THEN 
				SELECT desc_text INTO l_desc_text_2 
				FROM structure 
				WHERE start_num = modu_start_num_2 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_2 = NULL 
					DISPLAY l_desc_text_2 TO desc_text_2

					NEXT FIELD start_num_2 
				END IF 
			ELSE 
				LET l_desc_text_2 = NULL 
			END IF 
			DISPLAY l_desc_text_2 TO desc_text_2

		AFTER FIELD start_num_3 
			IF modu_start_num_3 <> 0 THEN 
				SELECT desc_text INTO l_desc_text_3 
				FROM structure 
				WHERE start_num = modu_start_num_3 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_3 = NULL 
					DISPLAY l_desc_text_3 TO desc_text_3 

					NEXT FIELD start_num_3 
				END IF 
			ELSE 
				LET l_desc_text_3 = NULL 
			END IF 
			DISPLAY l_desc_text_3 TO desc_text_3

		AFTER FIELD period_num 
			SELECT unique 1 FROM period 
			WHERE year_num = modu_year_num 
			AND period_num = modu_period_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9012,"") 
				#9012 Fiscal year AND period are invalidare invalid
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF modu_start_num_1 <> 0 THEN 
				SELECT (start_num + length_num - 1), desc_text 
				INTO modu_end_pos_1, l_desc_text_1 
				FROM structure 
				WHERE start_num = modu_start_num_1 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_1 = NULL 
					DISPLAY l_desc_text_1 TO desc_text_1 

					NEXT FIELD start_num_1 
				END IF 
			END IF 

			IF modu_start_num_2 <> 0 THEN 
				SELECT (start_num + length_num - 1), desc_text 
				INTO modu_end_pos_2, l_desc_text_2 FROM structure 
				WHERE start_num = modu_start_num_2 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_2 = NULL 
					DISPLAY l_desc_text_2 TO desc_text_2

					NEXT FIELD start_num_2 
				END IF 
			END IF 

			IF modu_start_num_3 <> 0 THEN 
				SELECT (start_num + length_num - 1), desc_text 
				INTO modu_end_pos_3, l_desc_text_3 FROM structure 
				WHERE start_num = modu_start_num_3 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_ind NOT in ("F", "C") 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9014,"") 
					#9014 No GL Account segments exist with this starting pos
					LET l_desc_text_3 = NULL 
					DISPLAY l_desc_text_3 TO desc_text_3 

					NEXT FIELD start_num_3 
				END IF 
			END IF 

			# Must be in sequential ORDER FOR control breaks
			CASE 
				WHEN (modu_start_num_1 = 0) 
					IF modu_start_num_2 <> 0 OR modu_start_num_3 <> 0 THEN 
						ERROR kandoomsg2("G",9215,"") 
						#9215 Segment sub-totals must be sequential
						NEXT FIELD start_num_1 
					END IF 

				WHEN (modu_start_num_2 = 0) 
					IF modu_start_num_3 <> 0 THEN 
						ERROR kandoomsg2("G",9215,"") 						#9215 Segment sub-totals must be sequential
						NEXT FIELD start_num_1 
					END IF 
			END CASE 

			# Sub-total breaks must be unique
			IF (modu_start_num_1 + modu_start_num_2 + modu_start_num_3) <> 0 THEN 
				IF (modu_start_num_1 = modu_start_num_2) OR 
				(modu_start_num_2 = modu_start_num_3) OR 
				(modu_start_num_1 = modu_start_num_3) THEN 
					ERROR kandoomsg2("G",9216,"") 					#9215 Segment sub-total breaks must be unique
					NEXT FIELD start_num_1 
				END IF 
			END IF 

			SELECT unique 1 FROM period 
			WHERE year_num = modu_year_num 
			AND period_num = modu_period_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9012,"") 				#9012 Fiscal year AND period are invalid
				NEXT FIELD year_num 
			END IF 

			CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") 
			RETURNING l_where_text 

			IF l_where_text IS NULL THEN 
				NEXT FIELD start_num_1 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		# Need TO store the parameter VALUES in character fields in the
		# rmsreps table FOR unattended processing.  Start numbers AND lengths
		# are packed INTO one field, because we have 8 parameters AND only
		# 4 fields.
		LET glob_rec_rpt_selector.ref1_ind = modu_report_type 
		LET glob_rec_rpt_selector.ref1_code = modu_year_num USING "&&&&" 
		LET glob_rec_rpt_selector.ref2_code = modu_period_num USING "&&&&" 
		LET glob_rec_rpt_selector.ref3_code = 
			modu_start_num_1 USING "&&", 
			modu_start_num_2 USING "&&", 
			modu_start_num_3 USING "&&" 
		LET glob_rec_rpt_selector.ref4_code = 
			modu_end_pos_1 USING "&&", 
			modu_end_pos_2 USING "&&", 
			modu_end_pos_3 USING "&&"
			
		LET glob_rec_rpt_selector.ref1_num = 	modu_start_num_1
		LET glob_rec_rpt_selector.ref2_num = 	modu_end_pos_1
		LET glob_rec_rpt_selector.ref3_num = 	modu_start_num_2
		LET glob_rec_rpt_selector.ref4_num = 	modu_end_pos_2
		LET glob_rec_rpt_selector.ref5_num = 	modu_start_num_3
		LET glob_rec_rpt_selector.ref6_num = 	modu_end_pos_3
			
		RETURN l_where_text 
	END IF

END FUNCTION 


############################################################
# FUNCTION GA4_rpt_process()
#
#
############################################################
FUNCTION GA4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_report_rec RECORD 
		acct_code LIKE accounthist.acct_code, 
		seg1_code LIKE accounthist.acct_code, 
		seg2_code LIKE accounthist.acct_code, 
		seg3_code LIKE accounthist.acct_code, 
		debit_amt LIKE accounthist.debit_amt, 
		credit_amt LIKE accounthist.credit_amt 
	END RECORD 
 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GA4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GA4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA4_rpt_list")].sel_text
	#------------------------------------------------------------

	# Extract the REPORT parameters FROM rmsreps
	LET modu_report_type = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 
	LET modu_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code[1,4] 
	LET modu_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_code[1,4]
	 
	#LET modu_start_num_1 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_code[1,2] 
	#LET modu_end_pos_1 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_code[1,2] 
	#LET modu_start_num_2 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_code[3,4] 
	#LET modu_end_pos_2 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_code[3,4] 
	#LET modu_start_num_3 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_code[5,6] 
	#LET modu_end_pos_3 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_code[5,6] 


	LET modu_start_num_1 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 	
	LET modu_end_pos_1 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 	
	LET modu_start_num_2 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 	
	LET modu_end_pos_2 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 	
	LET modu_start_num_3 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref5_num 	
	LET modu_end_pos_3 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref6_num 	

	#
	# Set up correct query FOR REPORT type
	#
	CASE modu_report_type 
		WHEN "1" 
			LET l_query_text = "SELECT acct_code, ", 
			"close_amt, ", 
			"0 ", 
			"FROM accounthist ", 
			"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			"AND year_num = ", modu_year_num, " ", 
			"AND period_num = ", modu_period_num, " ", 
			glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA4_rpt_list")].sel_text clipped 
			
		WHEN "2" 
			LET l_query_text = "SELECT acct_code, ", 
			"sum(debit_amt), ", 
			"sum(credit_amt) ", 
			"FROM accounthist ", 
			"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			"AND year_num = ", modu_year_num, " ", 
			"AND period_num <= ", modu_period_num, " ", 
			glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GA4_rpt_list")].sel_text clipped," ", 
			"group by acct_code " 
	END CASE 
	
	INITIALIZE l_rec_report_rec.* TO NULL 
	PREPARE s_accounthist FROM l_query_text 
	DECLARE c_accounthist CURSOR FOR s_accounthist 
	
	FOREACH c_accounthist INTO l_rec_report_rec.acct_code, 
		l_rec_report_rec.debit_amt, 
		l_rec_report_rec.credit_amt 
		IF l_rec_report_rec.debit_amt IS NULL THEN 
			LET l_rec_report_rec.debit_amt = 0 
		END IF 
		IF l_rec_report_rec.credit_amt IS NULL THEN 
			LET l_rec_report_rec.credit_amt = 0 
		END IF 
		IF modu_start_num_1 <> 0 THEN 
			LET l_rec_report_rec.seg1_code = 
			l_rec_report_rec.acct_code[modu_start_num_1, modu_end_pos_1] 
		END IF 
		IF modu_start_num_2 <> 0 THEN 
			LET l_rec_report_rec.seg2_code = 
			l_rec_report_rec.acct_code[modu_start_num_2, modu_end_pos_2] 
		END IF 
		IF modu_start_num_3 <> 0 THEN 
			LET l_rec_report_rec.seg3_code = 
			l_rec_report_rec.acct_code[modu_start_num_3, modu_end_pos_3] 
		END IF 
		IF modu_report_type = "1" AND l_rec_report_rec.debit_amt < 0 THEN 
			LET l_rec_report_rec.credit_amt = 0-l_rec_report_rec.debit_amt 
			LET l_rec_report_rec.debit_amt = 0 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT GA4_rpt_list(l_rpt_idx,l_rec_report_rec.*)  
		IF NOT rpt_int_flag_handler2("Account:",l_rec_report_rec.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GA4_rpt_list
	CALL rpt_finish("GA4_rpt_list")
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
# REPORT GA4_rpt_list(p_rec_report_rec)
#
#
############################################################
REPORT GA4_rpt_list(p_rpt_idx,p_rec_report_rec) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_report_rec RECORD 
		acct_code LIKE accounthist.acct_code, 
		seg1_code LIKE accounthist.acct_code, 
		seg2_code LIKE accounthist.acct_code, 
		seg3_code LIKE accounthist.acct_code, 
		debit_amt LIKE accounthist.debit_amt, 
		credit_amt LIKE accounthist.credit_amt 
	END RECORD 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_header_text_text CHAR(40) 


	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_report_rec.seg1_code, 
	p_rec_report_rec.seg2_code, 
	p_rec_report_rec.seg3_code, 
	p_rec_report_rec.acct_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			SKIP 1 line 
			CASE modu_report_type 
				WHEN "1" 
					LET l_header_text_text = "Report Type ", 
					modu_report_type, " : Closing balances FOR" 
				WHEN "2" 
					LET l_header_text_text = "Report Type ", 
					modu_report_type, " : Year TO date totals FOR" 
				OTHERWISE 
					LET l_header_text_text = "Invalid Report Type : ", modu_report_type 
			END CASE 
			PRINT COLUMN 01, l_header_text_text clipped," ", 
			modu_year_num USING "<<<<", "/", 
			modu_period_num USING "<<<<" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			SKIP 1 line 

		BEFORE GROUP OF p_rec_report_rec.seg1_code 
			IF p_rec_report_rec.seg1_code IS NOT NULL THEN 
				SELECT * INTO l_rec_validflex.* FROM validflex 
				WHERE start_num = modu_start_num_1 
				AND flex_code = p_rec_report_rec.seg1_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_rec_validflex.desc_text = "** Not Found **" 
				END IF 
				PRINT COLUMN 1, p_rec_report_rec.seg1_code clipped, 
				2 spaces, l_rec_validflex.desc_text 
				SKIP 1 LINES 
			END IF 

		BEFORE GROUP OF p_rec_report_rec.seg2_code 
			IF p_rec_report_rec.seg2_code IS NOT NULL THEN 
				SELECT * INTO l_rec_validflex.* FROM validflex 
				WHERE start_num = modu_start_num_2 
				AND flex_code = p_rec_report_rec.seg2_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_rec_validflex.desc_text = "** Not Found **" 
				END IF 
				PRINT COLUMN 4, p_rec_report_rec.seg2_code clipped, 
				2 spaces, l_rec_validflex.desc_text 
				SKIP 1 LINES 
			END IF 

		BEFORE GROUP OF p_rec_report_rec.seg3_code 
			IF p_rec_report_rec.seg3_code IS NOT NULL THEN 
				SELECT * INTO l_rec_validflex.* FROM validflex 
				WHERE start_num = modu_start_num_3 
				AND flex_code = p_rec_report_rec.seg3_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					LET l_rec_validflex.desc_text = "** Not Found **" 
				END IF 
				PRINT COLUMN 7, p_rec_report_rec.seg3_code clipped, 
				2 spaces, l_rec_validflex.desc_text 
				SKIP 1 LINES 
			END IF 

		AFTER GROUP OF p_rec_report_rec.seg1_code 
			IF p_rec_report_rec.seg1_code IS NOT NULL THEN 
				NEED 2 LINES 
				PRINT COLUMN 64, "==================", 
				COLUMN 83, "==================" 
				PRINT COLUMN 33, "Totals: ", p_rec_report_rec.seg1_code clipped, 
				COLUMN 64, GROUP sum(p_rec_report_rec.debit_amt) 
				USING "---,---,---,--&.&&", 
				COLUMN 83, GROUP sum(p_rec_report_rec.credit_amt) 
				USING "---,---,---,--&.&&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_report_rec.seg2_code 
			IF p_rec_report_rec.seg2_code IS NOT NULL THEN 
				NEED 2 LINES 
				PRINT COLUMN 64, "------------------", 
				COLUMN 83, "------------------" 
				PRINT COLUMN 27, "Sub-totals: ", p_rec_report_rec.seg2_code clipped, 
				COLUMN 64, GROUP sum(p_rec_report_rec.debit_amt) 
				USING "---,---,---,--&.&&", 
				COLUMN 83, GROUP sum(p_rec_report_rec.credit_amt) 
				USING "---,---,---,--&.&&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_report_rec.seg3_code 
			IF p_rec_report_rec.seg3_code IS NOT NULL THEN 
				NEED 2 LINES 
				PRINT COLUMN 64, "------------------", 
				COLUMN 83, "------------------" 
				PRINT COLUMN 27, "Sub-totals: ", p_rec_report_rec.seg3_code clipped, 
				COLUMN 64, GROUP sum(p_rec_report_rec.debit_amt) 
				USING "---,---,---,--&.&&", 
				COLUMN 83, GROUP sum(p_rec_report_rec.credit_amt) 
				USING "---,---,---,--&.&&" 
				SKIP 1 line 
			END IF 

		ON EVERY ROW 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_report_rec.acct_code 
			IF status = NOTFOUND THEN 
				LET l_rec_coa.desc_text = "** Not Found **" 
			END IF 

			CASE modu_report_type 
				WHEN "1" 
					PRINT COLUMN 10, p_rec_report_rec.acct_code, 
					COLUMN 29, l_rec_coa.type_ind, 
					COLUMN 33, l_rec_coa.desc_text[1,30]; 
					IF p_rec_report_rec.debit_amt = 0 THEN 
						PRINT COLUMN 83, p_rec_report_rec.credit_amt 
						USING "---,---,---,--&.&&" 
					ELSE 
						PRINT COLUMN 64, p_rec_report_rec.debit_amt 
						USING "---,---,---,--&.&&" 
					END IF 

				WHEN "2" 
					PRINT COLUMN 10, p_rec_report_rec.acct_code, 
					COLUMN 29, l_rec_coa.type_ind, 
					COLUMN 33, l_rec_coa.desc_text[1,30], 
					COLUMN 64, p_rec_report_rec.debit_amt 
					USING "---,---,---,--&.&&", 
					COLUMN 83, p_rec_report_rec.credit_amt 
					USING "---,---,---,--&.&&" 

			END CASE 

		ON LAST ROW 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Report Totals:", 
			COLUMN 64,sum(p_rec_report_rec.debit_amt) USING "---,---,---,---.&&", 
			COLUMN 83,sum(p_rec_report_rec.credit_amt) USING "---,---,---,---.&&" 
			SKIP 2 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT
