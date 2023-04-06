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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION PCA_main()
# RETURN VOID
#
# PCA - Debits Report
############################################################
FUNCTION PCA_main()

	CALL setModuleId("PCA") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P112 WITH FORM "P112" 
			CALL windecoration_p("P112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Debits" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCA","menu-cheque-1") 
					CALL PCA_rpt_process(PCA_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL PCA_rpt_process(PCA_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P112 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCA_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P112 WITH FORM "P112" 
			CALL windecoration_p("P112") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCA_rpt_query()
			CALL set_url_sel_text(PCA_rpt_query()) #save where clause in env 
			CLOSE WINDOW P112 

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCA_rpt_process(get_url_sel_text())
	END CASE
 
END FUNCTION 
############################################################
# END FUNCTION PCA_main()
############################################################


############################################################
# FUNCTION PCA_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCA_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.

	CONSTRUCT BY NAME l_ret_sql_sel_text ON debithead.vend_code, 
	vendor.name_text, 
	debithead.debit_num, 
	debithead.batch_num, 
	vendor.currency_code, 
	debithead.total_amt, 
	debithead.dist_amt, 
	debithead.apply_amt, 
	debithead.disc_amt, 
	debithead.year_num, 
	debithead.period_num, 
	debithead.post_flag, 
	debithead.jour_num, 
	debithead.conv_qty, 
	debithead.debit_date, 
	debithead.debit_text, 
	debithead.entry_code, 
	debithead.entry_date, 
	debithead.com1_text, 
	debithead.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCA","construct-debithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_ret_sql_sel_text = NULL
	END IF 

	RETURN l_ret_sql_sel_text
END FUNCTION 
############################################################
# END FUNCTION PCA_rpt_query() 
############################################################

############################################################
# FUNCTION PCA_rpt_process()
# RETURN rpt_finish("PCA_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_num LIKE debithead.debit_num, 
		debit_text LIKE debithead.debit_text, 
		debit_date LIKE debithead.debit_date, 
		entry_date LIKE debithead.entry_date, 
		year_num LIKE debithead.year_num, 
		period_num LIKE debithead.period_num, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		post_flag LIKE debithead.post_flag, 
		conv_qty LIKE debithead.conv_qty 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCA_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT debithead.vend_code,", 
	"vendor.name_text,", 
	"vendor.currency_code,", 
	"debithead.debit_num,", 
	"debithead.debit_text,", 
	"debithead.debit_date,", 
	"debithead.entry_date,", 
	"debithead.year_num,", 
	"debithead.period_num,", 
	"debithead.total_amt,", 
	"debithead.apply_amt,", 
	"debithead.post_flag,", 
	"debithead.conv_qty ", 
	"FROM debithead, vendor ", 
	"WHERE debithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = debithead.cmpy_code ", 
	"AND vendor.vend_code = debithead.vend_code ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY debithead.vend_code,", 
	"debithead.debit_num" 
	
	PREPARE s_debithead FROM l_query_text 
	DECLARE c_debithead CURSOR FOR s_debithead 
	
	FOREACH c_debithead INTO l_rec_debithead.* 

		#------------------------------------------------------------
		OUTPUT TO REPORT PCA_rpt_list(rpt_rmsreps_idx_get_idx("PCA_rpt_list"), l_rec_debithead.*) 
		IF NOT rpt_int_flag_handler2("Debit: ", l_rec_debithead.vend_code, l_rec_debithead.debit_num ,rpt_rmsreps_idx_get_idx("PCA_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PCA_rpt_list
	RETURN rpt_finish("PCA_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCA_rpt_process()
############################################################

############################################################
# REPORT PCA_rpt_list(p_rpt_idx, p_rec_debithead)
#
# Report Definition/Layout
############################################################
REPORT PCA_rpt_list(p_rpt_idx, p_rec_debithead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_debithead RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_num LIKE debithead.debit_num, 
		debit_text LIKE debithead.debit_text, 
		debit_date LIKE debithead.debit_date, 
		entry_date LIKE debithead.entry_date, 
		year_num LIKE debithead.year_num, 
		period_num LIKE debithead.period_num, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		post_flag LIKE debithead.post_flag, 
		conv_qty LIKE debithead.conv_qty 
	END RECORD 
	DEFINE l_vend_total DECIMAL(16,2)
	DEFINE l_vend_applied DECIMAL(16,2)
	DEFINE l_conv_total DECIMAL(16,2)
	DEFINE l_conv_applied DECIMAL(16,2) 
	DEFINE l_vendor_curr_code LIKE vendor.currency_code 

	OUTPUT 
		ORDER external BY p_rec_debithead.vend_code, p_rec_debithead.debit_num 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_rec_debithead.vend_code 
			SKIP 1 line 
			LET l_vend_total = 0 
			LET l_vend_applied = 0 
			PRINT COLUMN 001,"Vendor : ",p_rec_debithead.vend_code, " ",p_rec_debithead.name_text 
			PRINT COLUMN 001,"Currency: ",p_rec_debithead.currency_code 
			LET l_vendor_curr_code = p_rec_debithead.currency_code 
			SKIP 1 line 
			
		ON EVERY ROW 
			LET l_conv_total = 0 
			LET l_conv_applied = 0 
			IF l_vendor_curr_code != glob_rec_glparms.base_currency_code THEN 
				LET l_conv_total = p_rec_debithead.total_amt / p_rec_debithead.conv_qty 
				LET l_conv_applied = p_rec_debithead.apply_amt / p_rec_debithead.conv_qty 
				LET l_vend_total = l_vend_total + l_conv_total 
				LET l_vend_applied = l_vend_applied + l_conv_applied 
			END IF 
			PRINT COLUMN 001, p_rec_debithead.debit_num USING "########", 
			COLUMN 012, p_rec_debithead.debit_text, 
			COLUMN 035, p_rec_debithead.debit_date USING "dd/mm/yyyy", 
			COLUMN 047, p_rec_debithead.year_num USING "####", 
			COLUMN 053, p_rec_debithead.period_num USING "##", 
			COLUMN 056, p_rec_debithead.total_amt USING "-,---,---,--&.&&", 
			COLUMN 071, p_rec_debithead.apply_amt USING "-,---,---,--&.&&", 
			COLUMN 086, l_conv_total USING "-,---,---,--&.&&", 
			COLUMN 102, l_conv_applied USING "-,---,---,--&.&&", 
			COLUMN 130, p_rec_debithead.post_flag 
			
		AFTER GROUP OF p_rec_debithead.vend_code 
			PRINT COLUMN 015,"----------------------------------------", 
			"----------------------------------------", 
			"-------------------------" 
			PRINT COLUMN 001, "Debits: ",group count(*) USING "<<<<<", 
			COLUMN 015, "Avg: ", GROUP avg(p_rec_debithead.total_amt) USING "-,---,---,--&.&&", 
			COLUMN 056, GROUP sum(p_rec_debithead.total_amt) USING "-,---,---,--&.&&", 
			COLUMN 071, GROUP sum(p_rec_debithead.apply_amt) USING "-,---,---,--&.&&", 
			COLUMN 086, l_vend_total USING "-,---,---,--&.&&", 
			COLUMN 102, l_vend_applied USING "-,---,---,--&.&&" 
			
		ON LAST ROW 
			SKIP 2 LINE 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT