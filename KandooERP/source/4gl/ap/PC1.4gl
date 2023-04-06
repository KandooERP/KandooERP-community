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
# FUNCTION PC1_main()
# RETURN VOID
#
# PC1 Cheque Reports
############################################################
FUNCTION PC1_main()

	CALL setModuleId("PC1") 	 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW p149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Cheque by Vendor" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC1","menu-cheque-1")
					CALL PC1_rpt_process(PC1_rpt_query())			 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PC1_rpt_process(PC1_rpt_query()) 
		
				ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #  COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
		
			END MENU 
			CLOSE WINDOW p149
				
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC1_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW p149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC1_rpt_query()
			CLOSE WINDOW p149
			CALL set_url_sel_text(PC1_rpt_query()) #save where clause in env 
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC1_rpt_process(get_url_sel_text())
	END CASE
	
 
END FUNCTION


############################################################
# FUNCTION PC1_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
#
# DataSource for the report driver with CONSTRUCT 
############################################################
FUNCTION PC1_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text
	DEFINE l_query_text CHAR(2200)
	--DEFINE l_pr_output CHAR(60)
	--DEFINE l_rpt_length LIKE rmsreps.page_length_num
	--DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue "
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
			CALL publish_toolbar("kandoo","PC1","construct-cheque-1") 

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
# FUNCTION PC1_rpt_process(p_where_text) 
# RETURN rpt_finish("PC1_rpt_list")
# 
# The report driver
############################################################
FUNCTION PC1_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_rec_pr_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		cheq_code LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_code LIKE bank.bank_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		recon_flag LIKE cheque.recon_flag, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text, 
		currency_code LIKE cheque.currency_code, 
		conv_qty LIKE cheque.conv_qty, 
		source_ind LIKE cheque.source_ind, 
		source_text LIKE cheque.source_text, 
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PC1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------
	 
	LET l_query_text = 
	"SELECT cheque.vend_code, cheque.cheq_code, cheque.pay_meth_ind, ", 
	"cheque.entry_code, cheque.entry_date, bank.bank_code, ", 
	"cheque.com3_text, cheque.cheq_date, ", 
	"cheque.pay_amt, cheque.net_pay_amt, cheque.year_num, ", 
	"cheque.period_num, cheque.post_flag, ", 
	"cheque.apply_amt, cheque.disc_amt, ", 
	"cheque.recon_flag, cheque.com1_text, ", 
	"cheque.com2_text, cheque.currency_code, cheque.conv_qty, ", 
	"cheque.source_ind, cheque.source_text" 
	IF p_where_text matches "*bank.bank_code*" THEN 
		LET l_query_text = l_query_text clipped, " FROM cheque, bank, vendor" 
	ELSE 
		LET l_query_text = l_query_text clipped, " FROM cheque, vendor, outer bank" 
	END IF 
	LET l_query_text = l_query_text clipped, 
	" WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND ", 
	"cheque.cmpy_code = vendor.cmpy_code AND ", 
	"cheque.bank_acct_code = bank.acct_code AND ", 
	"cheque.cmpy_code = bank.cmpy_code AND ", 
	"cheque.vend_code = vendor.vend_code ", 
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC1_rpt_list")].sel_text clipped, " ", 
	" ORDER BY bank.bank_code, cheque.vend_code, ", 
	"cheque.pay_meth_ind, cheque.cheq_code"

	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque

	FOREACH c_cheque INTO l_rec_pr_cheque.* 
		OUTPUT TO REPORT PC1_rpt_list(l_rpt_idx,l_rec_pr_cheque.*) 
		IF NOT rpt_int_flag_handler2("Cheque",l_rec_pr_cheque.cheq_code, l_rec_pr_cheque.bank_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC1_rpt_list
	RETURN rpt_finish("PC1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 


############################################################
# REPORT PC1_rpt_list(p_rpt_idx,p_rec_cheque) 
#
# Report Definition/Layout
############################################################
REPORT PC1_rpt_list(p_rpt_idx,p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		cheq_code LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_code LIKE bank.bank_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		recon_flag LIKE cheque.recon_flag, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text, 
		currency_code LIKE cheque.currency_code, 
		conv_qty LIKE cheque.conv_qty, 
		source_ind LIKE cheque.source_ind, 
		source_text LIKE cheque.source_text, 
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD
	DEFINE l_rec_bank RECORD LIKE bank.*	
	DEFINE l_pay_text CHAR(3) 
	DEFINE l_name_text LIKE vouchpayee.name_text
	DEFINE l_cust_name_text LIKE customer.name_text 
	DEFINE s SMALLINT
	DEFINE len SMALLINT

	OUTPUT 
 
	ORDER external BY p_rec_cheque.bank_code, 
	p_rec_cheque.vend_code, 
	p_rec_cheque.pay_meth_ind, 
	p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

{
			LET l_line1 = glob_rec_company.cmpy_code, " ", glob_rec_company.name_text clipped 
			LET l_offset1 = (glob_rpt_width/2) - (length (l_line1) / 2) + 1 
			LET l_offset2 = (glob_rpt_width/2) - (length (glob_rpt_note) / 2) + 1 

			PRINT COLUMN 01, today USING "DD MMM YYYY", 
			COLUMN l_offset1, l_line1 clipped, 
			COLUMN (glob_rpt_width -10), "Page :", 
			COLUMN (glob_rpt_width - 3), pageno USING "###&" 

			PRINT COLUMN 01, time, 
			COLUMN l_offset2, glob_rpt_note 

			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
}
			PRINT COLUMN 1, "Cheque", 
			COLUMN 15, "Receipt ", 
			COLUMN 36, "Date", 
			COLUMN 43, "Period", 
			COLUMN 51, "Curr", 
			COLUMN 64, "Gross", 
			COLUMN 77, "Amount", 
			COLUMN 89, "Base Gross", 
			COLUMN 108, "Base", 
			COLUMN 120, "Base Net", 
			COLUMN 129, "Post" 
			PRINT COLUMN 1, "Number", 
			COLUMN 15, "Reference", 
			COLUMN 51, "Code", 
			COLUMN 63, "Amount", 
			COLUMN 77, "Applied", 
			COLUMN 93, "Amount", 
			COLUMN 107, "Applied", 
			COLUMN 122, "Amount" 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

		BEFORE GROUP OF p_rec_cheque.bank_code 
			SKIP TO top OF PAGE 

			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = p_rec_cheque.bank_code 

			SKIP 1 line 
			PRINT COLUMN 1, "Bank: ", l_rec_bank.bank_code clipped, " ", 
			l_rec_bank.name_acct_text 
			PRINT COLUMN 1, "Currency: ", l_rec_bank.currency_code 
	
		BEFORE GROUP OF p_rec_cheque.vend_code 
			NEED 4 LINES 
			SKIP 2 LINES 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			PRINT COLUMN 1, "Vendor: ", p_rec_cheque.vend_code, 
			COLUMN 18, glob_rec_vendor.name_text 
	
		ON EVERY ROW 
			LET l_pay_text = NULL 
			IF p_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_pay_text = "EFT" 
			END IF 
			PRINT COLUMN 01, p_rec_cheque.cheq_code USING "#########", 
			COLUMN 11, l_pay_text, 
			COLUMN 15, p_rec_cheque.com3_text[1,18], 
			COLUMN 34, p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 43, p_rec_cheque.year_num USING "####", "/",p_rec_cheque.period_num USING "##", 
			COLUMN 51, p_rec_cheque.currency_code, 
			COLUMN 55, p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 70, p_rec_cheque.apply_amt USING "---,---,--&.&&", 
			COLUMN 85, p_rec_cheque.base_pay_amt USING "---,---,--&.&&", 
			COLUMN 100, p_rec_cheque.base_apply_amt USING "---,---,--&.&&", 
			COLUMN 115, p_rec_cheque.base_net_pay_amt USING "---,---,--&.&&", 
			COLUMN 130, p_rec_cheque.post_flag 

			IF p_rec_cheque.source_ind = "8" THEN 
				SELECT name_text INTO l_cust_name_text FROM customer 
				WHERE cust_code = p_rec_cheque.source_text 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				PRINT COLUMN 25, "** Refund ", p_rec_cheque.source_text, 2 spaces, 
				l_cust_name_text 
			ELSE 
				IF p_rec_cheque.source_ind = "S" THEN 
					SELECT name_text INTO l_name_text FROM vouchpayee 
					WHERE vend_code = p_rec_cheque.vend_code 
					AND vouch_code = p_rec_cheque.source_text 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					PRINT COLUMN 11, "Payee name: ", l_name_text 
				END IF 
			END IF 
	
		AFTER GROUP OF p_rec_cheque.bank_code 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 10, "Cheques: ", GROUP count(*) USING "####"; 
			IF l_rec_bank.currency_code = glob_rec_company.curr_code THEN 
				PRINT COLUMN 55, GROUP sum(p_rec_cheque.base_pay_amt) 
				USING "---,---,--&.&&", 
				COLUMN 70, GROUP sum(p_rec_cheque.base_apply_amt) 
				USING "---,---,--&.&&", 
				COLUMN 85, GROUP sum(p_rec_cheque.base_pay_amt) 
				USING "---,---,--&.&&", 
				COLUMN 100, GROUP sum(p_rec_cheque.base_apply_amt) 
				USING "---,---,--&.&&", 
				COLUMN 115, GROUP sum(p_rec_cheque.base_net_pay_amt) 
				USING "---,---,--&.&&" 
			ELSE 
				PRINT COLUMN 55, GROUP sum(p_rec_cheque.pay_amt) 
				USING "---,---,--&.&&", 
				COLUMN 70, GROUP sum(p_rec_cheque.apply_amt) 
				USING "---,---,--&.&&", 
				COLUMN 85, GROUP sum(p_rec_cheque.base_pay_amt) 
				USING "---,---,--&.&&", 
				COLUMN 100, GROUP sum(p_rec_cheque.base_apply_amt) 
				USING "---,---,--&.&&", 
				COLUMN 115, GROUP sum(p_rec_cheque.base_net_pay_amt) 
				USING "---,---,--&.&&" 
			END IF 
			SKIP 1 line 
		AFTER GROUP OF p_rec_cheque.vend_code 
			PRINT COLUMN 55, "===================================", 
			COLUMN 90, "=======================================" 
			PRINT COLUMN 10, "Cheques: ", GROUP count(*) USING "####", 
			COLUMN 55, GROUP sum(p_rec_cheque.pay_amt) 
			USING "---,---,--&.&&", 
			COLUMN 70, GROUP sum(p_rec_cheque.apply_amt) 
			USING "---,---,--&.&&", 
			COLUMN 85, GROUP sum(p_rec_cheque.base_pay_amt) 
			USING "---,---,--&.&&", 
			COLUMN 100, GROUP sum(p_rec_cheque.base_apply_amt) 
			USING "---,---,--&.&&", 
			COLUMN 115, GROUP sum(p_rec_cheque.base_net_pay_amt) 
			USING "---,---,--&.&&" 
	
		ON LAST ROW 
			NEED 12 LINES 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 10, "Cheques: ", count(*) USING "####", 
			10 spaces, "Report totals in Base currency", 
			COLUMN 85, sum(p_rec_cheque.base_pay_amt) 
			USING "---,---,--&.&&", 
			COLUMN 100, sum(p_rec_cheque.base_apply_amt) 
			USING "---,---,--&.&&", 
			COLUMN 115, sum(p_rec_cheque.base_net_pay_amt) 
			USING "---,---,--&.&&" 
			SKIP 2 line 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			SKIP 1 line
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT 


