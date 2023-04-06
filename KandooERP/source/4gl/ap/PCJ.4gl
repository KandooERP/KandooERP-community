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
# FUNCTION PCJ_main()
# RETURN VOID
#
# PCJ - Debit Applications
############################################################
FUNCTION PCJ_main()

	CALL setModuleId("PCJ") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P173 with FORM "P173" 
			CALL windecoration_p("P173") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Debit Applications Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCJ","menu-debits_app-1") 
					CALL PCJ_rpt_process(PCJ_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL PCJ_rpt_process(PCJ_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY (interrupt,"E") "Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P173 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCJ_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P173 with FORM "P173" 
			CALL windecoration_p("P173") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCJ_rpt_query()
			CALL set_url_sel_text(PCJ_rpt_query()) #save where clause in env 
			CLOSE WINDOW P173

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCJ_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCJ_main()
############################################################


############################################################
# FUNCTION PCJ_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCJ_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text
	
	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") #1001 "Enter criteria FOR selection - press ESC TO begin REPORT"

	CONSTRUCT l_ret_sql_sel_text ON debithead.vend_code, 
	vendor.name_text, 
	debithead.debit_num, 
	vendor.currency_code, 
	debithead.total_amt, 
	debithead.debit_date, 
	debithead.apply_amt, 
	voucherpays.seq_num, 
	voucherpays.vouch_code, 
	voucherpays.apply_num, 
	voucherpays.pay_date, 
	voucherpays.apply_amt, 
	voucherpays.disc_amt 
	FROM debithead.vend_code, 
	vendor.name_text, 
	debithead.debit_num, 
	vendor.currency_code, 
	debithead.total_amt, 
	debithead.debit_date, 
	debithead.apply_amt, 
	voucherpays.seq_num, 
	voucherpays.vouch_code, 
	voucherpays.apply_num, 
	voucherpays.pay_date, 
	voucherpays.apply_amt, 
	voucherpays.disc_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PCJ","construct-voucherpays-1") 

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
# END FUNCTION PCJ_rpt_query() 
############################################################

############################################################
# FUNCTION PCJ_rpt_process()
# RETURN rpt_finish("PCJ_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCJ_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_debit RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_num LIKE debithead.debit_num, 
		total_amt LIKE debithead.total_amt, 
		debit_date LIKE debithead.debit_date, 
		seq_num LIKE voucherpays.seq_num, 
		vouch_code LIKE voucherpays.vouch_code, 
		apply_num LIKE voucherpays.apply_num, 
		pay_date LIKE voucherpays.pay_date, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt, 
		conv_qty LIKE debithead.conv_qty, 
		base_apply_amt LIKE voucherpays.apply_amt, 
		base_disc_amt LIKE voucherpays.disc_amt 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCJ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCJ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCJ_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT debithead.vend_code, vendor.name_text, ", 
	" vendor.currency_code, debithead.debit_num, ", 
	" debithead.total_amt, debithead.debit_date, ", 
	" voucherpays.seq_num, voucherpays.vouch_code, ", 
	" voucherpays.apply_num, voucherpays.pay_date, ", 
	" voucherpays.apply_amt, voucherpays.disc_amt, ", 
	" debithead.conv_qty ", 
	" FROM debithead, voucherpays, vendor ", 
	" WHERE debithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" debithead.cmpy_code = voucherpays.cmpy_code AND ", 
	" debithead.cmpy_code = vendor.cmpy_code AND ", 
	" debithead.vend_code = voucherpays.vend_code AND ", 
	" debithead.vend_code = vendor.vend_code AND ", 
	" debithead.debit_num = voucherpays.pay_num AND ", 
	" voucherpays.pay_type_code = ", "\"", "DB", "\"", " AND ", 
	p_where_text clipped, 
	" ORDER BY debithead.vend_code, ", 
	" debithead.debit_num, voucherpays.apply_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_debit.* 

		LET l_rec_debit.base_apply_amt = l_rec_debit.apply_amt / l_rec_debit.conv_qty 
		LET l_rec_debit.base_disc_amt = l_rec_debit.disc_amt / l_rec_debit.conv_qty 

		#------------------------------------------------------------
		OUTPUT TO REPORT PCJ_rpt_list(rpt_rmsreps_idx_get_idx("PCJ_rpt_list"), l_rec_debit.*) 
		IF NOT rpt_int_flag_handler2("Debit: ",l_rec_debit.debit_num, l_rec_debit.base_apply_amt ,rpt_rmsreps_idx_get_idx("PCJ_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#----------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PCJ_rpt_list
	RETURN rpt_finish("PCJ_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCJ_rpt_process()
############################################################

############################################################
# REPORT PCJ_rpt_list(p_rpt_idx,p_rec_cheque,p_rec_vendor)
#
# Report Definition/Layout
############################################################
REPORT PCJ_rpt_list(p_rpt_idx, p_rec_debit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_debit RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		debit_num LIKE debithead.debit_num, 
		total_amt LIKE debithead.total_amt, 
		debit_date LIKE debithead.debit_date, 
		seq_num LIKE voucherpays.seq_num, 
		vouch_code LIKE voucherpays.vouch_code, 
		apply_num LIKE voucherpays.apply_num, 
		pay_date LIKE voucherpays.pay_date, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt, 
		conv_qty LIKE debithead.conv_qty, 
		base_apply_amt LIKE voucherpays.apply_amt, 
		base_disc_amt LIKE voucherpays.disc_amt 
	END RECORD 

	OUTPUT 
		ORDER external BY p_rec_debit.vend_code, 
			p_rec_debit.debit_num, 
			p_rec_debit.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Application", 
			COLUMN 15, "Date", 
			COLUMN 25, "Voucher", 
			COLUMN 35, " Payment", 
			COLUMN 69, "Amount ", 
			COLUMN 84, "Discount" 
			PRINT COLUMN 1, " Number", 
			COLUMN 15, "Applied", 
			COLUMN 25, "Number", 
			COLUMN 35, " Number", 
			COLUMN 69, "Applied", 
			COLUMN 84, "Given" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_debit.seq_num USING "######", 
			COLUMN 15, p_rec_debit.pay_date USING "dd/mm/yy", 
			COLUMN 25, p_rec_debit.vouch_code USING "########", 
			COLUMN 36, p_rec_debit.apply_num USING "####", 
			COLUMN 65, p_rec_debit.apply_amt USING "---,---,--&.&&", 
			COLUMN 80, p_rec_debit.disc_amt USING "---,---,--&.&&" 

		BEFORE GROUP OF p_rec_debit.vend_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Vendor ID: ", p_rec_debit.vend_code, 
			COLUMN 25, p_rec_debit.name_text, " Currency " , 
			p_rec_debit.currency_code 

		BEFORE GROUP OF p_rec_debit.debit_num 
			SKIP 1 line 
			PRINT COLUMN 1, "Debit: ", p_rec_debit.debit_num USING "########", 
			COLUMN 20, "Date: ", p_rec_debit.pay_date USING "dd/mm/yy", 
			COLUMN 37, "Amount: ", p_rec_debit.total_amt USING "---,---,--&.&&" 

		AFTER GROUP OF p_rec_debit.vend_code 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 1 , "Vendor Totals:", 
			COLUMN 65, GROUP sum(p_rec_debit.apply_amt) USING "---,---,--&.&&", 
			COLUMN 80, GROUP sum(p_rec_debit.disc_amt) USING "---,---,--&.&&" 

		AFTER GROUP OF p_rec_debit.debit_num 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 65, GROUP sum(p_rec_debit.apply_amt) USING "---,---,--&.&&", 
			COLUMN 80, GROUP sum(p_rec_debit.disc_amt) USING "---,---,--&.&&" 

		ON LAST ROW 
			SKIP 1 LINES 
			PRINT COLUMN 65, "============== ==============" 
			PRINT COLUMN 1 , "Report Totals in Base Currency :", 
			COLUMN 65, sum(p_rec_debit.base_apply_amt) USING "---,---,--&.&&", 
			COLUMN 80, sum(p_rec_debit.base_disc_amt) USING "---,---,--&.&&" 

			SKIP 2 LINES
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


