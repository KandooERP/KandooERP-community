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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"

############################################################
# Module Scope Variables
############################################################
DEFINE modu_total_amount DECIMAL(16,2) 
DEFINE modu_report_ord_flag LIKE apparms.report_ord_flag
############################################################
# FUNCTION PA8_main()
#
# Purpose - Vendor Ledger Listing
############################################################
FUNCTION PA8_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PA8") 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P106 with FORM "P106" 
			CALL windecoration_p("P106") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			SELECT report_ord_flag INTO modu_report_ord_flag FROM apparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
			IF status = NOTFOUND THEN 
				CALL fgl_winmessage("Configuration Error", kandoomsg2("U",5116,""),"ERROR") #5116 AP Parameters NOT SET up; Refer Menu PZP.
				EXIT PROGRAM 
			END IF 

			MENU " Ledger Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PA8","menu-ledger-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA8_rpt_process(PA8_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA8_rpt_process(PA8_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW P106 

			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA8_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P106 with FORM "P106"
			CALL windecoration_p("P106") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA8_rpt_query()) #save where clause in env 
			CLOSE WINDOW P106 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA8_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION PA8_main()
############################################################


############################################################
# FUNCTION PA8_rpt_query()
#
#
############################################################
FUNCTION PA8_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("W", 1001, "") #1001 " Enter criteria FOR selection - ESC TO begin search"
	CONSTRUCT BY NAME l_where_text ON 
		apaudit.vend_code, 
		vendor.name_text, 
		vendor.currency_code, 
		apaudit.tran_date, 
		apaudit.seq_num, 
		apaudit.trantype_ind, 
		apaudit.source_num, 
		apaudit.tran_text, 
		apaudit.tran_amt, 
		apaudit.bal_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PA8","construct-apaudit-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	LET glob_rec_rpt_selector.ref1_ind = modu_report_ord_flag 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR "Report generation was aborted"  
		RETURN NULL	 
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION
############################################################
# END FUNCTION PA8_rpt_query()
############################################################


############################################################
# FUNCTION PA8_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PA8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_name_text LIKE vendor.name_text 
	DEFINE l_pr_currency_code LIKE vendor.currency_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	LET modu_report_ord_flag = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_ind 
	#------------------------------------------------------------
		 
	IF modu_report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT apaudit.*,vendor.name_text,vendor.currency_code FROM apaudit, vendor ", 
		" WHERE apaudit.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code = apaudit.vend_code ", 
		"AND vendor.cmpy_code = apaudit.cmpy_code ", 
		"AND ", p_where_text clipped, " ", 
		"ORDER BY apaudit.vend_code, apaudit.seq_num" 
	ELSE 
		LET l_query_text = "SELECT apaudit.*,vendor.name_text,vendor.currency_code ", 
		"FROM apaudit, vendor ", 
		"WHERE apaudit.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code = apaudit.vend_code ", 
		"AND vendor.cmpy_code = apaudit.cmpy_code ", 
		"AND ", p_where_text clipped, " ", 
		"ORDER BY vendor.name_text, apaudit.vend_code, apaudit.seq_num" 
	END IF 
	PREPARE s_apaudit FROM l_query_text 
	DECLARE c_apaudit CURSOR FOR s_apaudit 
	LET modu_total_amount = 0 
	
	FOREACH c_apaudit INTO l_rec_apaudit.*, l_name_text, l_pr_currency_code
		#---------------------------------------------------------
		OUTPUT TO REPORT PA8_rpt_list(l_rpt_idx,
		l_rec_apaudit.*, l_name_text, l_pr_currency_code)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_apaudit.vend_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT PA8_rpt_list
	CALL rpt_finish("PA8_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true
END FUNCTION 
############################################################
# END FUNCTION PA8_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PA8_rpt_list(p_rpt_idx,p_apaudit, p_name_text, p_currency_code)
#
#
############################################################
REPORT PA8_rpt_list(p_rpt_idx,p_apaudit,p_name_text,p_currency_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_apaudit RECORD LIKE apaudit.* 
	DEFINE p_name_text LIKE vendor.name_text 
	DEFINE p_currency_code LIKE vendor.currency_code 

	OUTPUT 
 
	ORDER external BY p_apaudit.vend_code, p_apaudit.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_apaudit.vend_code 
			PRINT 
			PRINT COLUMN 1, "ID: ", p_apaudit.vend_code, 
			COLUMN 15, p_name_text, 
			" Currency ", p_currency_code 
			PRINT 
			
		ON EVERY ROW 
			PRINT COLUMN 02, p_apaudit.tran_date, 
			COLUMN 15, p_apaudit.trantype_ind, 
			COLUMN 20, p_apaudit.source_num USING "########", 
			COLUMN 30, p_apaudit.tran_text, 
			COLUMN 50, p_apaudit.tran_amt USING "---,---,--&.&&", 
			COLUMN 65, p_apaudit.bal_amt USING "---,---,--&.&&" 
			LET modu_total_amount = modu_total_amount 
			+ conv_currency(p_apaudit.tran_amt, glob_rec_kandoouser.cmpy_code, 
			p_currency_code, 
			"F", today, "B") 
			
		AFTER GROUP OF p_apaudit.vend_code 
			PRINT 
			PRINT COLUMN 50, "=============================" 
			PRINT COLUMN 50, GROUP sum(p_apaudit.tran_amt) USING "---,---,--&.&&" 
			
		ON LAST ROW 
			PRINT 
			PRINT COLUMN 10, "Total Items In Base Currency: ", 
			count(*) USING "#####", 
			COLUMN 46, modu_total_amount USING "---,---,---,--&.&&" 
			PRINT 
			PRINT 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
############################################################
# END REPORT PA8_rpt_list(p_rpt_idx,p_apaudit, p_name_text, p_currency_code)
############################################################