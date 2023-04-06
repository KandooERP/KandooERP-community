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
# FUNCTION PC5_main()
# RETURN VOID
#
# PC5 - Cheque Application Report
############################################################
FUNCTION PC5_main()

	CALL setModuleId("PC5") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P150 with FORM "P150" 
			CALL windecoration_p("P150") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Cheque Applications " 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC5","menu-cheque_app-1") 
					CALL PC5_rpt_process(PC5_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PC5_rpt_process(PC5_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P150 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC5_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P150 with FORM "P150" 
			CALL windecoration_p("P150") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC5_rpt_query()
			CALL set_url_sel_text(PC5_rpt_query()) #save where clause in env 
			CLOSE WINDOW P150

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC5_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PC5_main()
############################################################


############################################################
# FUNCTION PC5_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC5_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT l_ret_sql_sel_text ON voucherpays.vend_code, 
	bank.bank_code, 
	voucherpays.pay_num, 
	voucherpays.pay_meth_ind, 
	vendor.currency_code, 
	cheque.pay_amt, 
	cheque.tax_amt, 
	cheque.contra_amt, 
	cheque.net_pay_amt, 
	cheque.apply_amt, 
	cheque.cheq_date, 
	cheque.com3_text, 
	voucherpays.vouch_code, 
	voucherpays.apply_num, 
	voucherpays.pay_date, 
	voucherpays.apply_amt, 
	voucherpays.disc_amt 
	FROM voucherpays.vend_code, 
	bank.bank_code, 
	voucherpays.pay_num, 
	voucherpays.pay_meth_ind, 
	vendor.currency_code, 
	cheque.pay_amt, 
	cheque.tax_amt, 
	cheque.contra_amt, 
	cheque.net_pay_amt, 
	cheque.apply_amt, 
	cheque.cheq_date, 
	cheque.com3_text, 
	voucherpays.vouch_code, 
	voucherpays.apply_num, 
	voucherpays.pay_date, 
	voucherpays.apply_amt, 
	voucherpays.disc_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PC5","construct-voucherpays-1") 

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
# END FUNCTION PC5_rpt_query() 
############################################################

############################################################
# FUNCTION PC5_rpt_process()
# RETURN rpt_finish("PC5_rpt_list")
# 
# The report driver
############################################################
FUNCTION PC5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_cheque RECORD 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		cheq_date LIKE cheque.cheq_date 
	END RECORD 
	DEFINE l_rec_voucherpays RECORD 
		vend_code LIKE voucherpays.vend_code, 
		bank_code LIKE bank.bank_code, 
		currency_code LIKE bank.currency_code, 
		vouch_code LIKE voucherpays.vouch_code, 
		seq_num LIKE voucherpays.seq_num, 
		pay_date LIKE voucherpays.pay_date, 
		pay_meth_ind LIKE voucherpays.pay_meth_ind, 
		pay_num LIKE voucherpays.pay_num, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt 
	END RECORD 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PC5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT cheque.pay_amt, cheque.net_pay_amt, voucherpays.pay_date, ", 
	"voucherpays.vend_code, bank.bank_code, vendor.currency_code, ", 
	"voucherpays.vouch_code, voucherpays.seq_num, voucherpays.pay_date, ", 
	"voucherpays.pay_meth_ind, ", 
	"voucherpays.pay_num, voucherpays.apply_amt, voucherpays.disc_amt ", 
	"FROM cheque, voucherpays, vendor, bank WHERE ", 
	"voucherpays.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	"voucherpays.cmpy_code = cheque.cmpy_code AND ", 
	"bank.cmpy_code = cheque.cmpy_code AND ", 
	"bank.acct_code = cheque.bank_acct_code AND ", 
	"vendor.cmpy_code = cheque.cmpy_code AND ", 
	"vendor.vend_code = cheque.vend_code AND ", 
	"voucherpays.vend_code = cheque.vend_code AND ", 
	"voucherpays.pay_meth_ind = cheque.pay_meth_ind AND ", 
	"voucherpays.pay_num = cheque.cheq_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC5_rpt_list")].sel_text clipped, 
	" ORDER BY voucherpays.vend_code, voucherpays.pay_meth_ind, ", 
	"voucherpays.pay_num, voucherpays.seq_num" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	FOREACH selcurs INTO l_rec_cheque.*,l_rec_voucherpays.* 

		#------------------------------------------------------------
		OUTPUT TO REPORT PC5_rpt_list(rpt_rmsreps_idx_get_idx("PC5_rpt_list"),l_rec_cheque.*, l_rec_voucherpays.*) 
		IF NOT rpt_int_flag_handler2("Voucher",l_rec_voucherpays.pay_num, l_rec_cheque.pay_amt ,rpt_rmsreps_idx_get_idx("PC5_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC5_rpt_list
	RETURN rpt_finish("PC5_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PC5_rpt_process()
############################################################

############################################################
# REPORT PC5_rpt_list(p_rec_cheque,p_rec_voucherpays)
#
# Report Definition/Layout
############################################################
REPORT PC5_rpt_list(p_rpt_idx,p_rec_cheque,p_rec_voucherpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		cheq_date LIKE cheque.cheq_date 
	END RECORD 
	DEFINE p_rec_voucherpays RECORD 
		vend_code LIKE voucherpays.vend_code, 
		bank_code LIKE bank.bank_code, 
		currency_code LIKE bank.currency_code, 
		vouch_code LIKE voucherpays.vouch_code, 
		seq_num LIKE voucherpays.seq_num, 
		pay_date LIKE voucherpays.pay_date, 
		pay_meth_ind LIKE voucherpays.pay_meth_ind, 
		pay_num LIKE voucherpays.pay_num, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_source_ind LIKE voucher.source_ind 
	DEFINE l_source_text LIKE voucher.source_text 
	DEFINE l_vname_text LIKE vendor.name_text 

	OUTPUT 
		ORDER external BY p_rec_voucherpays.vend_code, 
			p_rec_voucherpays.pay_meth_ind, 
			p_rec_voucherpays.pay_num, 
			p_rec_voucherpays.seq_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, "Application", 
			COLUMN 15, "Date", 
			COLUMN 25, "Voucher", 
			COLUMN 52, "Amount ", 
			COLUMN 66, "Discount" 
			PRINT COLUMN 1, " Number", 
			COLUMN 15, "Applied", 
			COLUMN 25, "Number", 
			COLUMN 52, "Applied", 
			COLUMN 66, "Taken" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
		BEFORE GROUP OF p_rec_voucherpays.vend_code 
			NEED 4 LINES 
			SKIP 1 LINES 
			SELECT name_text INTO l_vname_text FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			vend_code = p_rec_voucherpays.vend_code 
			PRINT COLUMN 1, "Vendor: ", p_rec_voucherpays.vend_code, 
			COLUMN 20, l_vname_text 
			PRINT COLUMN 1, "Currency: ", p_rec_voucherpays.currency_code 
		BEFORE GROUP OF p_rec_voucherpays.pay_num 
			NEED 4 LINES 
			SKIP 1 line 
			IF p_rec_voucherpays.pay_meth_ind = "1" THEN 
				PRINT COLUMN 1, "Bank:" , p_rec_voucherpays.bank_code, 
				COLUMN 20, "Cheque: ", p_rec_voucherpays.pay_num USING "#########" 
			ELSE 
				PRINT COLUMN 1, "Bank:" , p_rec_voucherpays.bank_code, 
				COLUMN 20, "EFT: ", p_rec_voucherpays.pay_num USING "#########" 
			END IF 
			PRINT COLUMN 1, "Date: ", p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 20, "Gross Amount: ", 
			p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 51, "Net Amount: ", 
			p_rec_cheque.net_pay_amt USING "---,---,--&.&&" 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_voucherpays.seq_num USING "######", 
			COLUMN 15, p_rec_voucherpays.pay_date USING "dd/mm/yy", 
			COLUMN 25, p_rec_voucherpays.vouch_code USING "########", 
			COLUMN 45, p_rec_voucherpays.apply_amt USING "---,---,--&.&&", 
			COLUMN 60, p_rec_voucherpays.disc_amt USING "---,---,--&.&&" 
			SELECT voucher.source_ind, voucher.source_text 
			INTO l_source_ind, l_source_text FROM voucher 
			WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucher.vend_code = p_rec_voucherpays.vend_code 
			AND voucher.vouch_code = p_rec_voucherpays.vouch_code 
			IF l_source_ind = "8" THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_source_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				PRINT COLUMN 25, "** Refund ", l_rec_customer.cust_code, 2 spaces, 
				l_rec_customer.name_text 
			END IF 
		AFTER GROUP OF p_rec_voucherpays.vend_code 
			NEED 5 LINES 
			PRINT COLUMN 45, "============== ==============" 
			PRINT COLUMN 45, GROUP sum(p_rec_voucherpays.apply_amt) 
			USING "---,---,--&.&&", 
			COLUMN 60, GROUP sum(p_rec_voucherpays.disc_amt) 
			USING "---,---,--&.&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 9 LINES 
			SKIP 2 line 
			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


