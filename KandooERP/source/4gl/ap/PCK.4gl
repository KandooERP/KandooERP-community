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
# FUNCTION PCK_main()
# RETURN VOID
#
# PCK  -  Prescribed Payment Tax Report
############################################################
FUNCTION PCK_main()

	CALL setModuleId("PCK") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " PPT Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCK","menu-ppt_report-1") 
					CALL PCK_rpt_process(PCK_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PCK_rpt_process(PCK_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P149

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCK_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCK_rpt_query()
			CALL set_url_sel_text(PCK_rpt_query()) #save where clause in env 
			CLOSE WINDOW P149

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCK_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCK_main()
############################################################


############################################################
# FUNCTION PCK_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCK_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") #1001 Enter selection criteria - ESC TO Continue

	CONSTRUCT BY NAME l_ret_sql_sel_text ON cheque.vend_code, 
	bank.bank_code, 
	cheque.cheq_code, 
	cheque.pay_meth_ind, 
	cheque.cheq_date, 
	vendor.type_code, 
	bank.currency_code, 
	cheque.entry_code, 
	cheque.entry_date, 
	cheque.year_num, 
	cheque.period_num, 
	cheque.pay_amt, 
	cheque.tax_amt, 
	cheque.contra_amt, 
	cheque.net_pay_amt, 
	cheque.post_flag, 
	cheque.recon_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCK","construct-cheque-1") 

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
# END FUNCTION PCK_rpt_query() 
############################################################

############################################################
# FUNCTION PCK_rpt_process()
# RETURN rpt_finish("PCK_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCK_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_pay_amt LIKE cheque.pay_amt
	DEFINE l_pptax LIKE cheque.pay_amt 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCK_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCK_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCK_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT vendor.*, cheque.pay_amt, ", 
	" cheque.tax_amt ", 
	" FROM vendor, cheque, bank ", 
	" WHERE cheque.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" cheque.bank_acct_code = bank.acct_code AND ", 
	" cheque.cmpy_code = bank.cmpy_code AND ", 
	" cheque.cmpy_code = vendor.cmpy_code AND ", 
	" cheque.vend_code = vendor.vend_code ", 
	" AND ", p_where_text clipped, 
	" ORDER BY vendor.vend_code " 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_vendor.*, l_pay_amt, l_pptax 

		#------------------------------------------------------------
		OUTPUT TO REPORT PCK_rpt_list(rpt_rmsreps_idx_get_idx("PCK_rpt_list"), l_rec_vendor.*, l_pay_amt, l_pptax) 
		IF NOT rpt_int_flag_handler2("Vendor: ",l_rec_vendor.vend_code, l_pay_amt ,rpt_rmsreps_idx_get_idx("PCK_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PCK_rpt_list
	RETURN rpt_finish("PCK_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCK_rpt_process()
############################################################

############################################################
# REPORT PCK_rpt_list(p_rpt_idx, p_rec_vendor,p_pay_amt,p_pptax
#
# Report Definition/Layout
############################################################
REPORT PCK_rpt_list(p_rpt_idx, p_rec_vendor,p_pay_amt,p_pptax) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_vendor RECORD LIKE vendor.*
	DEFINE p_pay_amt LIKE cheque.pay_amt
	DEFINE p_pptax LIKE cheque.pay_amt
	-- DEFINE l_cmpy_head CHAR(132)
	-- DEFINE col2, col, len, s SMALLINT 

	OUTPUT 
		ORDER external BY p_rec_vendor.vend_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01, "Vendor", 
			COLUMN 10, "Vendor", 
			COLUMN 41, "Address", 
			COLUMN 100, "Taxable", 
			COLUMN 120, "PP Tax" 
			PRINT COLUMN 10, "Name", 
			COLUMN 101, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_vendor.vend_code 
			SKIP 1 line 

		AFTER GROUP OF p_rec_vendor.vend_code 
			NEED 4 LINES 
			PRINT COLUMN 01, p_rec_vendor.vend_code, 
			COLUMN 10, p_rec_vendor.name_text, 
			COLUMN 41, p_rec_vendor.addr1_text, 
			COLUMN 92, GROUP sum(p_pay_amt) USING "----,---,--&.&&", 
			COLUMN 111, GROUP sum(p_pptax) USING "----,---,--&.&&" 
			IF p_rec_vendor.addr2_text IS NOT NULL THEN 
				PRINT COLUMN 41, p_rec_vendor.addr2_text 
			END IF 
			IF p_rec_vendor.addr3_text IS NOT NULL THEN 
				PRINT COLUMN 41, p_rec_vendor.addr3_text 
			END IF 
			PRINT COLUMN 41, p_rec_vendor.city_text, 
			COLUMN 60, p_rec_vendor.state_code, 
			COLUMN 67, p_rec_vendor.post_code 

		ON LAST ROW 
			PRINT COLUMN 93, "=================================" 
			PRINT COLUMN 01, "PPT Summary:", 
			COLUMN 90,sum(p_pay_amt) USING "--,---,---,--&.&&", 
			COLUMN 109,sum(p_pptax) USING "--,---,---,--&.&&" 
			SKIP 2 LINES 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


