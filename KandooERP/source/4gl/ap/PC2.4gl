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
GLOBALS 
	DEFINE glob_base_currency LIKE glparms.base_currency_code 
	DEFINE glob_rec_bank RECORD LIKE bank.* 
--	DEFINE glob_where_part STRING -- CHAR(2048) 
END GLOBALS 

############################################################
# FUNCTION PC2_main()
#
# PC2 Cheques By Number
############################################################
FUNCTION PC2_main() 

	CALL setModuleId("PC2")
	

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW p149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Cheque by Number" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC2","menu-cheque-1") 
					CALL PC2_rpt_process(PC2_rpt_query())
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"					
					CALL publish_toolbar("kandoo","PC2","menu-cheque-1") 
					CALL PC2_rpt_process(PC2_rpt_query())
		
--			IF pc2_query() THEN 
--				LET glob_rpt_note = NULL 
-- 
--			END IF 
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
--				ON ACTION "Message" #COMMAND "Message" " Enter heading MESSAGE FOR REPORT"
--					LET glob_rpt_note = fgl_winprompt(5,5, "Enter Message TO Appear on each Page", "", 50, 0) 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW p120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PC2_rpt_query()) #save where clause in env 
			CLOSE WINDOW p120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC2_rpt_process(get_url_sel_text())
	END CASE 
	CLOSE WINDOW p149 
END FUNCTION 


############################################################
# FUNCTION PC2_rpt_query()
#
# Construct for report WHERE query
############################################################
FUNCTION PC2_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

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
			CALL publish_toolbar("kandoo","PC2","construct-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF
	 
	RETURN l_ret_sql_sel_text 
END FUNCTION 


############################################################
# FUNCTION PC2_rpt_process() 
#
#
############################################################
FUNCTION PC2_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_rec_cheque RECORD 
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
		source_ind LIKE voucher.source_ind, 
		source_text LIKE voucher.source_text, 
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD 

	#------------------------------------------------------------	
	#User pressed CANCEL = p_where_text IS NULL	
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF
	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PC2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
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
	"cheque.com2_text, cheque.currency_code, cheque.conv_qty,", 
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
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC2_rpt_list")].sel_text clipped, " ", 
	" ORDER BY bank.bank_code, cheque.pay_meth_ind, cheque.cheq_code"
	 
	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque 

	FOREACH c_cheque INTO l_rec_cheque.* 
		LET l_rec_cheque.base_pay_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.base_apply_amt = l_rec_cheque.apply_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.base_net_pay_amt = l_rec_cheque.net_pay_amt/l_rec_cheque.conv_qty 

		OUTPUT TO REPORT PC2_rpt_list(l_rpt_idx,l_rec_cheque.*) 
		IF NOT rpt_int_flag_handler2("Vendor",l_rec_cheque.bank_code, l_rec_cheque.cheq_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC2_rpt_list
	RETURN rpt_finish("PC2_rpt_list")
	#------------------------------------------------------------
END FUNCTION

############################################################
# REPORT PC2_rpt_list(p_rpt_idx,p_rec_cheque)
#
#
############################################################
REPORT PC2_rpt_list(p_rpt_idx,p_rec_cheque) 
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
		source_ind LIKE voucher.source_ind, 
		source_text LIKE voucher.source_text, 
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD 
	DEFINE l_pay_text CHAR(3) 
	DEFINE l_name_text LIKE vouchpayee.name_text 
	DEFINE l_line1, l_line2 CHAR(80)
	DEFINE l_offset1, l_offset2 SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE s, len SMALLINT

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_cheque.bank_code, 
	p_rec_cheque.pay_meth_ind, 
	p_rec_cheque.cheq_code 
	FORMAT 
		PAGE HEADER 
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
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


			PRINT COLUMN 1, "Cheque", 
			COLUMN 15, "Cheque ", 
			COLUMN 35, "Date", 
			COLUMN 43, "Period", 
			COLUMN 51, "Curr", 
			COLUMN 64, "Amount", 
			COLUMN 78, "Amount", 
			COLUMN 96, "Net", 
			COLUMN 102, " Vendor Details" 
			PRINT COLUMN 1, "Number", 
			COLUMN 15, "Reference", 
			COLUMN 51, "Code", 
			COLUMN 78, "Applied", 
			COLUMN 93, "Amount", 
			COLUMN 100, "Post"
			 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
		BEFORE GROUP OF p_rec_cheque.bank_code 
			NEED 5 LINES 
			SKIP 2 LINES 
			SELECT * INTO glob_rec_bank.* FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_code = p_rec_cheque.bank_code 
			PRINT COLUMN 1, "Bank: ", glob_rec_bank.name_acct_text 
			PRINT COLUMN 1, "Currency: ", glob_rec_bank.currency_code
			 
		ON EVERY ROW 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			LET l_pay_text = NULL 
			IF p_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_pay_text = "EFT" 
			END IF 
			PRINT COLUMN 01, p_rec_cheque.cheq_code USING "#########", 
			COLUMN 11, l_pay_text, 
			COLUMN 15, p_rec_cheque.com3_text[1,18], 
			COLUMN 34, p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 43, p_rec_cheque.year_num USING "####", "/", 
			p_rec_cheque.period_num USING "##", 
			COLUMN 51, p_rec_cheque.currency_code, 
			COLUMN 56, p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 71, p_rec_cheque.apply_amt USING "---,---,--&.&&", 
			COLUMN 86, p_rec_cheque.net_pay_amt USING "---,---,--&.&&", 
			COLUMN 101, p_rec_cheque.post_flag, 
			COLUMN 103, p_rec_cheque.vend_code, 
			COLUMN 112, glob_rec_vendor.name_text[1,21] 
			IF p_rec_cheque.source_ind = "S" THEN 
				SELECT name_text INTO l_name_text 
				FROM vouchpayee 
				WHERE vouchpayee.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouchpayee.vend_code = p_rec_cheque.vend_code 
				AND vouchpayee.vouch_code = p_rec_cheque.source_text 
				PRINT COLUMN 11, "Payee name: ", l_name_text 
			END IF 
			
		AFTER GROUP OF p_rec_cheque.bank_code 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 10, "Cheques: ", GROUP count(*) USING "####"; 
			IF glob_rec_bank.currency_code = glob_base_currency THEN 
				PRINT COLUMN 53, GROUP sum(p_rec_cheque.base_pay_amt) 
				USING "------,---,--&.&&", 
				COLUMN 83, GROUP sum(p_rec_cheque.base_net_pay_amt) 
				USING "------,---,--&.&&" 
				PRINT COLUMN 68, GROUP sum(p_rec_cheque.base_apply_amt) 
				USING "------,---,--&.&&" 
			ELSE 
				PRINT COLUMN 53, GROUP sum(p_rec_cheque.pay_amt) 
				USING "------,---,--&.&&", 
				COLUMN 83, GROUP sum(p_rec_cheque.net_pay_amt) 
				USING "------,---,--&.&&" 
				PRINT COLUMN 68, GROUP sum(p_rec_cheque.apply_amt) 
				USING "------,---,--&.&&" 
			END IF 
			SKIP 1 line 

		ON LAST ROW 
			NEED 12 LINES 
			PRINT COLUMN 1, "Report totals in Base Currency" 
			PRINT COLUMN 1, "Cheques: ", count(*) USING "####", 
			COLUMN 53, sum(p_rec_cheque.base_pay_amt) 
			USING "------,---,--&.&&", 
			COLUMN 83, sum(p_rec_cheque.base_net_pay_amt) 
			USING "------,---,--&.&&" 
			PRINT COLUMN 68, sum(p_rec_cheque.base_apply_amt) 
			USING "------,---,--&.&&" 
			SKIP 2 line 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT