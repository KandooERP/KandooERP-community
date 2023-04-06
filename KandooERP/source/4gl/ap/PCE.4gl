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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# FUNCTION PCE_main()
# RETURN VOID
#
# PCE - Debit Detail Report
############################################################
FUNCTION PCE_main()

	CALL setModuleId("PCE") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P153 with FORM "P153" 
			CALL windecoration_p("P153") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Debit Detail" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCE","menu-debit_detail-1") 
					CALL PCE_rpt_process(PCE_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL PCE_rpt_process(PCE_rpt_query()) 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P153

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCE_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P153 with FORM "P153" 
			CALL windecoration_p("P153") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			CALL PCE_rpt_query()
			CALL set_url_sel_text(PCE_rpt_query()) #save where clause in env 
			CLOSE WINDOW P153

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCE_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION PCE_main()
############################################################


############################################################
# FUNCTION PCE_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCE_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") #1001 Enter selection criteria - ESC TO Continue

	CONSTRUCT l_ret_sql_sel_text ON debitdist.vend_code, 
	debitdist.debit_code, 
	debithead.year_num, 
	debithead.period_num, 
	vendor.currency_code, 
	debithead.debit_date, 
	debitdist.acct_code, 
	debitdist.desc_text, 
	debitdist.dist_amt, 
	debitdist.dist_qty 
	FROM debitdist.vend_code, 
	debitdist.debit_code, 
	debithead.year_num, 
	debithead.period_num, 
	vendor.currency_code, 
	debithead.debit_date, 
	debitdist.acct_code, 
	debitdist.desc_text, 
	debitdist.dist_amt, 
	debitdist.dist_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCE","construct-debithead-1") 

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
# END FUNCTION PCE_rpt_query() 
############################################################

############################################################
# FUNCTION PCE_rpt_process()
# RETURN rpt_finish("PCE_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCE_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_debitdist t_rec_debitdist_vc_nt_cc_dc_ln_ac_dt_da_dq_cq_bd

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCE_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCE_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCE_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT debitdist.vend_code, ", 
	"vendor.name_text, ", 
	"vendor.currency_code, ", 
	"debitdist.debit_code, ", 
	"debitdist.line_num, ", 
	"debitdist.acct_code, ", 
	"debitdist.desc_text, ", 
	"debitdist.dist_amt, ", 
	"debitdist.dist_qty, ", 
	"debithead.conv_qty ", 
	"FROM debitdist, vendor, debithead ", 
	"WHERE debitdist.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = debitdist.cmpy_code AND ", 
	"vendor.vend_code = debitdist.vend_code AND ", 
	"debithead.cmpy_code = debitdist.cmpy_code AND ", 
	"debithead.vend_code = debitdist.vend_code AND ", 
	"debithead.debit_num = debitdist.debit_code AND ", 
	p_where_text clipped, 
	"ORDER BY debitdist.vend_code, debitdist.debit_code, debitdist.line_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_debitdist.* 

		LET l_rec_debitdist.base_dist_amt = l_rec_debitdist.dist_amt / 
		l_rec_debitdist.conv_qty 

		#------------------------------------------------------------
		OUTPUT TO REPORT PCE_rpt_list(rpt_rmsreps_idx_get_idx("PCE_rpt_list"), l_rec_debitdist.*) 
		IF NOT rpt_int_flag_handler2("Debit: ",l_rec_debitdist.debit_code, "" ,rpt_rmsreps_idx_get_idx("PCE_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PCE_rpt_list
	RETURN rpt_finish("PCE_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCE_rpt_process()
############################################################

############################################################
# REPORT PCE_rpt_list(p_rpt_idx, p_rec_debitdist)
#
# Report Definition/Layout
############################################################
REPORT PCE_rpt_list(p_rpt_idx, p_rec_debitdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_debitdist t_rec_debitdist_vc_nt_cc_dc_ln_ac_dt_da_dq_cq_bd 
--	DEFINE p_rpt_wid SMALLINT
--	DEFINE p_where_part STRING
  
	#		RECORD
	#         vend_code LIKE debitdist.vend_code,
	#         name_text LIKE vendor.name_text,
	#         currency_code LIKE vendor.currency_code,
	#         debit_code LIKE debitdist.debit_code,
	#         line_num LIKE debitdist.line_num,
	#         acct_code LIKE debitdist.acct_code,
	#         desc_text LIKE debitdist.desc_text,
	#         dist_amt LIKE debitdist.dist_amt,
	#         dist_qty LIKE debitdist.dist_qty,
	#         conv_qty LIKE debithead.conv_qty,
	#         base_dist_amt LIKE debitdist.dist_amt
	#		END RECORD
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_cmpy_head CHAR(132) 
--	DEFINE l_col2 SMALLINT 
--	DEFINE l_col SMALLINT 
--	DEFINE l_cnt SMALLINT 
--	DEFINE i SMALLINT

	OUTPUT 
--	left margin 0 
		ORDER external BY p_rec_debitdist.vend_code, 
			p_rec_debitdist.debit_code, 
			p_rec_debitdist.line_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Line", 
			COLUMN 6, "Account", 
			COLUMN 25, "Description", 
			COLUMN 62,"Currency", 
			COLUMN 81, "Amount" , 
			COLUMN 94, "Base Amount", 
			COLUMN 111,"Quantity", 
			COLUMN 120,"UOM" 
			PRINT COLUMN 1, "No.", 
			COLUMN 6, "Code" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_debitdist.vend_code 
			NEED 3 LINES 
			PRINT COLUMN 1, "Vendor ID: ",p_rec_debitdist.vend_code, 
			COLUMN 21, p_rec_debitdist.name_text 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_debitdist.debit_code 
			NEED 5 LINES 
			PRINT COLUMN 5, "Debit: ", p_rec_debitdist.debit_code USING "#######" 

		ON EVERY ROW 
			LET l_rec_coa.uom_code = NULL 
			SELECT uom_code INTO l_rec_coa.uom_code FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_debitdist.acct_code 
			IF l_rec_coa.uom_code IS NULL THEN 
				LET p_rec_debitdist.dist_qty = NULL 
			END IF 
			PRINT COLUMN 1, p_rec_debitdist.line_num USING "###", 
			COLUMN 5, p_rec_debitdist.acct_code , 
			COLUMN 24, p_rec_debitdist.desc_text, 
			COLUMN 65, p_rec_debitdist.currency_code, 
			COLUMN 71, p_rec_debitdist.dist_amt USING "-----,---,--&.&&", 
			COLUMN 89, p_rec_debitdist.base_dist_amt USING "-----,---,--&.&&", 
			COLUMN 107, p_rec_debitdist.dist_qty USING "---------&.&", 
			COLUMN 120, l_rec_coa.uom_code 

		AFTER GROUP OF p_rec_debitdist.debit_code 
			NEED 3 LINES 
			PRINT COLUMN 71, "----------------", 
			COLUMN 89, "----------------" 
			PRINT COLUMN 71, GROUP sum(p_rec_debitdist.dist_amt) 
			USING "-----,---,---.&&", 
			COLUMN 89, GROUP sum(p_rec_debitdist.base_dist_amt) 
			USING "-----,---,---.&&" 

		AFTER GROUP OF p_rec_debitdist.vend_code 
			NEED 4 LINES 
			SKIP 1 line 
			PRINT COLUMN 71, "================", 
			COLUMN 89, "================" 
			PRINT COLUMN 71, GROUP sum(p_rec_debitdist.dist_amt) 
			USING "-----,---,---.&&", 
			COLUMN 89, GROUP sum(p_rec_debitdist.base_dist_amt) 
			USING "-----,---,---.&&" 

		ON LAST ROW 
			NEED 8 LINES 
			SKIP 1 line 
			PRINT COLUMN 2, "Total Lines: ", count(*) USING "###", 
			COLUMN 75, "Report Total:", 
			COLUMN 89, sum(p_rec_debitdist.base_dist_amt) USING "-----,---,---.&&" 
			SKIP 2 line 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


