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
# FUNCTION PC3_main()
# RETURN VOID
#
# PC3 - Cheque by Period Report
############################################################
FUNCTION PC3_main()

	CALL setModuleId("PC3") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW p149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Cheque by Period" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC3","menu-cheque-1") 
					CALL PC3_rpt_process(PC3_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL PC3_rpt_process(PC3_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" # COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW p149 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC3_rpt_process(NULL)  #(NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW p149 with FORM "P149" 
			CALL windecoration_p("P149") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC3_rpt_query()
			CALL set_url_sel_text(PC3_rpt_query()) #save where clause in env
			CLOSE WINDOW p149 

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC3_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION 
############################################################
# END FUNCTION PC3_main()
############################################################

############################################################
# FUNCTION PC3_rpt_query() 
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC3_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text
	DEFINE l_query_text STRING
--	DEFINE l_pr_output CHAR(60)
--	DEFINE l_rpt_length LIKE rmsreps.page_length_num
--	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") 
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
			CALL publish_toolbar("kandoo","PC3","construct-cheque-1") 

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
# END FUNCTION PC3_rpt_query() 
############################################################

############################################################
# FUNCTION PC3_rpt_process(p_where_text) 
# RETURN rpt_finish("PC3_rpt_list")
# 
# The report driver
############################################################
FUNCTION PC3_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE l_query_text STRING
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
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD 

--	DEFINE l_pr_output CHAR(60)
--	DEFINE l_rpt_length LIKE rmsreps.page_length_num
--	DEFINE l_msgresp LIKE language.yes_flag

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PC3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
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
	"cheque.com2_text, cheque.currency_code, cheque.conv_qty" 
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
	"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC3_rpt_list")].sel_text clipped, 
	" ORDER BY cheque.year_num, cheque.period_num, ", 
	"cheque.pay_meth_ind, cheque.cheq_code" 

	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque 

	FOREACH c_cheque INTO l_rec_cheque.* 
		LET l_rec_cheque.base_pay_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.base_apply_amt = l_rec_cheque.apply_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.base_net_pay_amt = l_rec_cheque.net_pay_amt/l_rec_cheque.conv_qty 
		IF l_rec_cheque.currency_code IS NULL 
		OR l_rec_cheque.currency_code = " " THEN 
			SELECT currency_code INTO l_rec_cheque.currency_code FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_rec_cheque.vend_code 
		END IF 
--		DISPLAY l_rec_cheque.bank_code at 1,23 

--		DISPLAY "" at 2,23 
--		DISPLAY l_rec_cheque.cheq_code at 2,23 

		OUTPUT TO REPORT PC3_rpt_list(rpt_rmsreps_idx_get_idx("PC3_rpt_list"),l_rec_cheque.*) 
		IF NOT rpt_int_flag_handler2("Cheque",l_rec_cheque.cheq_code, l_rec_cheque.bank_code,rpt_rmsreps_idx_get_idx("PC3_rpt_list")) THEN
			EXIT FOREACH 
		END IF 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC3_rpt_list
	RETURN rpt_finish("PC3_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PC3_rpt_process()
############################################################


############################################################
# REPORT PC3_rpt_list(p_rpt_idx,p_rec_cheque) 
#
# Report Definition/Layout
############################################################
REPORT PC3_rpt_list(p_rpt_idx,p_rec_cheque)
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
		base_pay_amt LIKE cheque.pay_amt, 
		base_apply_amt LIKE cheque.apply_amt, 
		base_net_pay_amt LIKE cheque.net_pay_amt 
	END RECORD 
	DEFINE l_pay_text CHAR(3) 
	DEFINE s SMALLINT
	DEFINE len SMALLINT

	OUTPUT 

	ORDER BY p_rec_cheque.year_num, 
	p_rec_cheque.period_num, 
	p_rec_cheque.pay_meth_ind, 
	p_rec_cheque.cheq_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Cheque", 
			COLUMN 15, "Receipt", 
			COLUMN 38, "Date", 
			COLUMN 46, "Bank", 
			COLUMN 54, "Currency", 
			COLUMN 69, "Amount", 
			COLUMN 88, "Amount", 
			COLUMN 110, "Net", 
			COLUMN 115, "Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 15, "Reference", 
			COLUMN 88, "Applied", 
			COLUMN 108, "Amount" 
			PRINT COLUMN 1, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3
			#PRINT COLUMN 1,"----------------------------------------", 
			#"----------------------------------------", 
			#"----------------------------------------" 

		BEFORE GROUP OF p_rec_cheque.period_num 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Year : ", p_rec_cheque.year_num USING "####", 
			COLUMN 15, "Period: ",p_rec_cheque.period_num USING "###" 
			SKIP 1 line 

		ON EVERY ROW 
			LET l_pay_text = NULL 
			IF p_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_pay_text = "EFT" 
			END IF 
			PRINT COLUMN 01, p_rec_cheque.cheq_code USING "#########", 
			COLUMN 11, l_pay_text, 
			COLUMN 15, p_rec_cheque.com3_text, 
			COLUMN 36, p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 46, p_rec_cheque.bank_code , 
			COLUMN 56, p_rec_cheque.currency_code, 
			COLUMN 61, p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 81, p_rec_cheque.apply_amt USING "---,---,--&.&&", 
			COLUMN 100, p_rec_cheque.net_pay_amt USING "---,---,--&.&&", 
			COLUMN 117, p_rec_cheque.post_flag 

		AFTER GROUP OF p_rec_cheque.period_num 
			SKIP 1 line 
			PRINT COLUMN 1,"----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 14, "Period Totals in Base Currency:", 
			COLUMN 58, GROUP sum(p_rec_cheque.base_pay_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 78, GROUP sum(p_rec_cheque.base_apply_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 97, GROUP sum(p_rec_cheque.base_net_pay_amt) 
			USING "--,---,---,--&.&&" 

		ON LAST ROW 
			NEED 12 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 1, "Totals in base currency" 
			PRINT COLUMN 1, "Cheques: ", count(*) USING "####", 
			COLUMN 58, sum(p_rec_cheque.base_pay_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 78, sum(p_rec_cheque.base_apply_amt) 
			USING "--,---,---,--&.&&", 
			COLUMN 97, sum(p_rec_cheque.base_net_pay_amt) 
			USING "--,---,---,--&.&&" 
			SKIP 2 line 
			
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			
			

END REPORT 
############################################################
# END REPORT PC3_rpt_list(p_rpt_idx,p_rec_cheque) 
############################################################

