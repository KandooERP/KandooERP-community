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
# \brief module PRA Audit Trail
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS 
#	DEFINE glob_where_part STRING -- CHAR(2048)
	DEFINE glob_start_date LIKE period.start_date 
	DEFINE glob_end_date LIKE period.end_date 
	DEFINE glob_start_year LIKE period.year_num
	DEFINE glob_start_period LIKE period.period_num 
	DEFINE glob_end_year LIKE period.year_num
	DEFINE glob_end_period LIKE period.period_num
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt
	
	#Initial UI Init
	CALL setModuleId("PRA") 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P109 with FORM "P109" 
			CALL windecoration_p("P109") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Audit Trail" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PRA","menu-audit_trail-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PRA_rpt_process(PRA_rpt_query()) 
							
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PRA_rpt_process(PRA_rpt_query()) 
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 		
		
			END MENU 
		
			CLOSE WINDOW P109

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PRA_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P109 with FORM "P109" 
			CALL windecoration_p("P109") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PRA_rpt_query()) #save where clause in env 
			CLOSE WINDOW P109 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PRA_rpt_process(get_url_sel_text())
	END CASE
	
END MAIN 


############################################################
# FUNCTION PRA_rpt_query()
#
#
############################################################
FUNCTION PRA_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_start_date LIKE period.start_date
	DEFINE l_end_date LIKE period.end_date
	DEFINE l_year_num LIKE period.year_num
	DEFINE l_period_num LIKE period.period_num
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_valid_period1 DATE 
	DEFINE l_valid_period2 DATE
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 	#1001 Enter criteria FOR selection - press ESC TO begin REPORT"
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING l_year_num, l_period_num 
	SELECT period.start_date, 
	period.end_date 
	INTO l_start_date, 
	l_end_date 
	FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = l_year_num 
	AND period_num = l_period_num 
	LET glob_start_date = l_start_date 
	LET glob_end_date = l_end_date 

	INPUT glob_start_date, glob_end_date WITHOUT DEFAULTS FROM start_date, end_date  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PRA","inp-date-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD end_date 
			IF glob_end_date < glob_start_date THEN 
				ERROR " END date must be greater OR equal TO start date " 
				NEXT FIELD start_date 
			END IF 
			IF glob_end_date IS NULL THEN 
				LET glob_end_date = "31/12/2999" 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	CONSTRUCT BY NAME l_where_text ON apaudit.tran_date, 
	apaudit.vend_code, 
	apaudit.currency_code, 
	apaudit.seq_num, 
	apaudit.trantype_ind, 
	apaudit.source_num, 
	apaudit.tran_text, 
	apaudit.tran_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PRA","construct-apaudit-1") 

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
	
	IF glob_start_date != glob_end_date THEN 
		OPEN WINDOW wp109a with FORM "P109a" 
		CALL windecoration_p("P109a") 

		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter criteria - press ESC TO begin "
		INPUT glob_start_year, 
		glob_start_period, 
		glob_end_year, 
		glob_end_period 
		FROM start_year, 
		start_period, 
		end_year, 
		end_period 

			BEFORE FIELD start_year 
				LET glob_start_year = l_year_num 
				LET glob_start_period = l_period_num 
				LET glob_end_year = l_year_num 
				LET glob_end_period = l_period_num 
				DISPLAY glob_start_year TO start_year 

				DISPLAY glob_start_period TO start_period 

				DISPLAY glob_end_year TO end_year 

				DISPLAY glob_end_period TO end_period 

			AFTER FIELD start_year 
				IF glob_start_year != l_year_num THEN 
					LET glob_end_year = glob_start_year 
					DISPLAY glob_end_year TO end_year 

				END IF 
			AFTER FIELD start_period 
				SELECT period.start_date INTO l_valid_period1 FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_start_year 
				AND period_num = glob_start_period 
				IF status = NOTFOUND THEN 
					ERROR " Not a valid period" 
					NEXT FIELD start_year 
				END IF 
			AFTER FIELD end_year 
				IF glob_end_year < glob_start_year THEN 
					ERROR " Invalid year - Must be the same OR Greater" 
					NEXT FIELD end_year 
				END IF 
			AFTER FIELD end_period 
				SELECT period.start_date INTO l_valid_period2 FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_end_year 
				AND period_num = glob_end_period 
				IF status = NOTFOUND THEN 
					ERROR " Not a valid period" 
					NEXT FIELD end_year 
				END IF 
				IF l_valid_period2 < l_valid_period1 THEN 
					ERROR " Invalid period - Must be the same OR Greater" 
					NEXT FIELD end_period 
				END IF 
			AFTER INPUT 
				SELECT * FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_start_year 
				AND period_num = glob_start_period 
				IF status = NOTFOUND THEN 
					ERROR " Not a valid period" 
					NEXT FIELD start_year 
				END IF 
				SELECT * FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_end_year 
				AND period_num = glob_end_period 
				IF status = NOTFOUND THEN 
					ERROR " Not a valid period" 
					NEXT FIELD end_year 
				END IF 
				IF glob_start_year IS NULL OR glob_start_period IS NULL 
				OR glob_end_year IS NULL OR glob_end_period IS NULL THEN 
					ERROR " Invalid year & period" 
					NEXT FIELD start_year 
				END IF 

		END INPUT 

		CLOSE WINDOW wp109a 

	ELSE 
		SELECT year_num, 
		period_num 
		INTO l_year_num, 
		l_period_num 
		FROM period 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND (period.start_date < today OR period.start_date = today) 
		AND (period.end_date > today OR period.end_date = today) 
		LET glob_start_year = l_year_num 
		LET glob_start_period = 1 
		LET glob_end_year = l_year_num 
		LET glob_end_period = l_period_num 
	END IF 



	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = glob_start_year
		LET glob_rec_rpt_selector.ref2_num = glob_start_period
		LET glob_rec_rpt_selector.ref3_num = glob_end_year
		LET glob_rec_rpt_selector.ref4_num = glob_end_period

		LET glob_rec_rpt_selector.ref1_date = glob_start_date
		LET glob_rec_rpt_selector.ref2_date = glob_end_date
		
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PRA_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PRA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_apaudit RECORD 
		year_num LIKE apaudit.year_num, 
		period_num LIKE apaudit.period_num, 
		tran_date LIKE apaudit.tran_date, 
		entry_date LIKE apaudit.entry_date, 
		vend_code LIKE apaudit.vend_code, 
		currency_code LIKE apaudit.currency_code, 
		conv_qty LIKE apaudit.conv_qty, 
		trantype_ind LIKE apaudit.trantype_ind, 
		source_num LIKE apaudit.source_num, 
		tran_text LIKE apaudit.tran_text, 
		tran_amt LIKE apaudit.tran_amt, 
		dp_vouch LIKE apaudit.tran_amt, 
		dp_cheque LIKE apaudit.tran_amt, 
		dp_debit LIKE apaudit.tran_amt 
	END RECORD 
	DEFINE l_start_date LIKE period.start_date
	DEFINE l_end_date LIKE period.end_date
	DEFINE l_year_num LIKE period.year_num
	DEFINE l_period_num LIKE period.period_num
	DEFINE l_query_text STRING
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...

	LET glob_start_year =  glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET glob_start_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET glob_end_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET glob_end_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 

	LET glob_start_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 
	LET glob_end_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date 

	LET l_year_num =  glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET glob_start_period = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num 
	LET l_year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_num 
	LET l_period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_num 
	#------------------------------------------------------------


	LET l_query_text = "SELECT apaudit.year_num, apaudit.period_num, ", 
	" apaudit.tran_date, apaudit.entry_date, ", 
	" apaudit.vend_code, ", 
	" apaudit.currency_code, apaudit.conv_qty, ", 
	" apaudit.trantype_ind, apaudit.source_num, ", 
	" apaudit.tran_text, apaudit.tran_amt ", 
	"FROM apaudit ", 
	"WHERE apaudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" apaudit.entry_date >= \"",glob_start_date,"\" AND ", 
	" apaudit.entry_date <= \"",glob_end_date,"\" AND ", 
	" ( (( apaudit.year_num = ", glob_start_year, " AND ", 
	" apaudit.period_num >= ", glob_start_period, ")", 
	" OR (apaudit.year_num > ", glob_start_year, ")", 
	" )", 
	" AND ", 
	" (( apaudit.year_num = ", glob_end_year, " AND ", 
	" apaudit.period_num <= ", glob_end_period, ")", 
	" OR (apaudit.year_num < ", glob_end_year, ")", 
	" )", 
	" ) AND ", p_where_text clipped, 
	"ORDER BY apaudit.year_num, ", 
	" apaudit.period_num ,", 
	" apaudit.entry_date,", 
	" apaudit.tran_date,", 
	" apaudit.vend_code" 
--	LET l_msgresp=kandoomsg("U",1506,"")	#1506 Searching Database Please Stand By"

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_apaudit.* 
		LET l_rec_apaudit.tran_amt = l_rec_apaudit.tran_amt / l_rec_apaudit.conv_qty 
		IF l_rec_apaudit.trantype_ind = "VO" OR 
		l_rec_apaudit.trantype_ind = "TF" THEN 
			LET l_rec_apaudit.dp_vouch = l_rec_apaudit.tran_amt 
		ELSE 
			LET l_rec_apaudit.dp_vouch = 0 
		END IF 
		IF l_rec_apaudit.trantype_ind = "CH" 
		OR l_rec_apaudit.trantype_ind = "PP" 
		OR l_rec_apaudit.trantype_ind = "CC" THEN 
			LET l_rec_apaudit.dp_cheque = l_rec_apaudit.tran_amt * -1 
		ELSE 
			LET l_rec_apaudit.dp_cheque = 0 
		END IF 
		IF l_rec_apaudit.trantype_ind = "DB" THEN 
			LET l_rec_apaudit.dp_debit = l_rec_apaudit.tran_amt * -1 
		ELSE 
			LET l_rec_apaudit.dp_debit = 0 
		END IF 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT PRA_rpt_list(l_rpt_idx,
		l_rec_apaudit.*)
		IF NOT rpt_int_flag_handler2("Document:",l_rec_apaudit.source_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PRA_rpt_list
	CALL rpt_finish("PRA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 


############################################################
# REPORT PRA_rpt_list(p_rpt_idx,p_rec_apaudit)
#
#
############################################################
REPORT PRA_rpt_list(p_rpt_idx,p_rec_apaudit)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	  
	DEFINE p_rec_apaudit RECORD 
		year_num LIKE apaudit.year_num, 
		period_num LIKE apaudit.period_num, 
		tran_date LIKE apaudit.tran_date, 
		entry_date LIKE apaudit.entry_date, 
		vend_code LIKE apaudit.vend_code, 
		currency_code LIKE apaudit.currency_code, 
		conv_qty LIKE apaudit.conv_qty, 
		trantype_ind LIKE apaudit.trantype_ind, 
		source_num LIKE apaudit.source_num, 
		tran_text LIKE apaudit.tran_text, 
		tran_amt LIKE apaudit.tran_amt, 
		dp_vouch LIKE apaudit.tran_amt, 
		dp_cheque LIKE apaudit.tran_amt, 
		dp_debit LIKE apaudit.tran_amt 
	END RECORD 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132)
	DEFINE len, s INTEGER

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_apaudit.year_num, 
	p_rec_apaudit.period_num, 
	p_rec_apaudit.entry_date, 
	p_rec_apaudit.tran_date, 
	p_rec_apaudit.vend_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_apaudit.period_num 
			PRINT COLUMN 1, "Period ", 
			COLUMN 8, p_rec_apaudit.year_num, 
			COLUMN 13, p_rec_apaudit.period_num 
		BEFORE GROUP OF p_rec_apaudit.entry_date 
			PRINT COLUMN 1, "Entered: ", p_rec_apaudit.entry_date USING "dd/mm/yy" 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_apaudit.vend_code, 
			COLUMN 10, p_rec_apaudit.trantype_ind, " ", 
			p_rec_apaudit.source_num USING "<<<<<<<<", 
			COLUMN 22, p_rec_apaudit.tran_date USING "dd/mm/yy", 
			COLUMN 33, p_rec_apaudit.tran_text, 
			COLUMN 50, p_rec_apaudit.tran_amt USING "----,---,---,---.&&", 
			COLUMN 70, p_rec_apaudit.dp_vouch USING "----,---,---,---.&&", 
			COLUMN 90, p_rec_apaudit.dp_cheque USING "----,---,---,---.&&", 
			COLUMN 110, p_rec_apaudit.dp_debit USING "----,---,---,---.&&" 

		AFTER GROUP OF p_rec_apaudit.entry_date 
			SKIP 1 line 
			PRINT COLUMN 50, "---------------------------------------", 
			"-----------------------------------------" 
			PRINT COLUMN 50, GROUP sum(p_rec_apaudit.tran_amt) 
			USING "----,---,---,---.&&", 
			COLUMN 70, GROUP sum(p_rec_apaudit.dp_vouch) 
			USING "----,---,---,---.&&", 
			COLUMN 90, GROUP sum(p_rec_apaudit.dp_cheque) 
			USING "----,---,---,---.&&", 
			COLUMN 110, GROUP sum(p_rec_apaudit.dp_debit) 
			USING "----,---,---,---.&&" 

		AFTER GROUP OF p_rec_apaudit.period_num 
			SKIP 2 line 
			PRINT COLUMN 50, "---------------------------------------", 
			"-----------------------------------------" 
			PRINT COLUMN 1, "Totals Period ", 
			COLUMN 15, p_rec_apaudit.year_num, 
			COLUMN 20, p_rec_apaudit.period_num, 
			COLUMN 50, GROUP sum(p_rec_apaudit.tran_amt) 
			USING "----,---,---,---.&&", 
			COLUMN 70, GROUP sum(p_rec_apaudit.dp_vouch) 
			USING "----,---,---,---.&&", 
			COLUMN 90, GROUP sum(p_rec_apaudit.dp_cheque) 
			USING "----,---,---,---.&&", 
			COLUMN 110, GROUP sum(p_rec_apaudit.dp_debit) 
			USING "----,---,---,---.&&" 
			PRINT COLUMN 50, "---------------------------------------", 
			"-----------------------------------------" 
			SKIP 1 line 

		ON LAST ROW 
			SKIP 2 line 
			PRINT COLUMN 50, "--------------------", 
			COLUMN 71, "-------------------", 
			COLUMN 91, "-------------------", 
			COLUMN 111, "-------------------" 
			PRINT COLUMN 5, "Report Totals: ", 
			COLUMN 50, sum(p_rec_apaudit.tran_amt) USING "----,---,---,---.&&", 
			COLUMN 90, sum(p_rec_apaudit.dp_cheque) USING "----,---,---,---.&&" 
			PRINT COLUMN 70, sum(p_rec_apaudit.dp_vouch) USING "----,---,---,---.&&", 
			COLUMN 110, sum(p_rec_apaudit.dp_debit) USING "----,---,---,---.&&" 
			SKIP 1 line 
			PRINT COLUMN 1, "Start entry date ", glob_start_date USING "dd/mm/yy" 
			PRINT COLUMN 1, " END entry date ", glob_end_date USING "dd/mm/yy" 
			PRINT COLUMN 1, "Start year/period ", glob_start_year, " ", glob_start_period 
			PRINT COLUMN 1, " END year/period ", glob_end_year, " ", glob_end_period 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT 


