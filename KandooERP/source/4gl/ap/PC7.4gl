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
# FUNCTION PC7_main()
# RETURN VOID
#
# PC7 - Treasury Report
############################################################
FUNCTION PC7_main()

	CALL setModuleId("PC7") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P132 with FORM "P132" 
			CALL windecoration_p("P132") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Treasury Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC7","menu-treasury_rep-1") 
					CALL PC7_rpt_process(PC7_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL PC7_rpt_process(PC7_rpt_query()) 

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P132

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC7_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN "3" 
			OPEN WINDOW P132 with FORM "P132" 
			CALL windecoration_p("P132") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC7_rpt_query()
			CALL set_url_sel_text(PC7_rpt_query()) #save where clause in env 
			CLOSE WINDOW P132

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC7_rpt_process(get_url_sel_text())

	END CASE 

END FUNCTION
############################################################
# END FUNCTION PC7_main()
############################################################


############################################################
# FUNCTION PC7_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC7_rpt_query()
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	CLEAR FORM 
	MESSAGE kandoomsg2("P",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO Continue
	CONSTRUCT BY NAME l_ret_sql_sel_text ON cheque.vend_code , 
	vendor.name_text, 
	bank.bank_code, 
	bank.name_acct_text, 
	cheque.cheq_code, 
	cheque.pay_meth_ind, 
	vendor.currency_code, 
	cheque.pay_amt, 
	cheque.tax_amt, 
	cheque.contra_amt, 
	cheque.net_pay_amt, 
	cheque.apply_amt, 
	cheque.disc_amt , 
	cheque.tax_code, 
	cheque.tax_per, 
	cheque.cheq_date, 
	cheque.com3_text, 
	cheque.entry_code, 
	cheque.entry_date, 
	cheque.post_flag , 
	cheque.year_num, 
	cheque.period_num, 
	cheque.bank_acct_code, 
	cheque.rec_state_num, 
	cheque.rec_line_num, 
	cheque.com1_text, 
	cheque.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PC7","construct-cheque-1") 

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
# END FUNCTION PC7_rpt_query() 
############################################################

############################################################
# FUNCTION PC7_rpt_process()
# RETURN rpt_finish("PC7_rpt_list_treasury")
# 
# The report driver
############################################################
FUNCTION PC7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		cheq_code LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_acct_code LIKE cheque.bank_acct_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		rec_state_num LIKE cheque.rec_state_num, 
		rec_line_num LIKE cheque.rec_line_num, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text, 
		currency_code LIKE cheque.currency_code, 
		conv_qty LIKE cheque.conv_qty 
	END RECORD 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.*
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_vouch_number INTEGER
	
	DEFINE l_tot_int, l_tot_in DECIMAL(15,2)
	DEFINE l_dist_offset DECIMAL(15,2)
	DEFINE l_rem_paid DECIMAL(15,2)

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start("PC7-TRSR","PC7_rpt_list_treasury",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC7_rpt_list_treasury TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC7_rpt_list_treasury")].sel_text
	#------------------------------------------------------------

	LET l_query_text = 
	"SELECT cheque.vend_code, ", 
	"vendor.name_text, ", 
	"cheque.cheq_code, ", 
	"cheque.pay_meth_ind, ", 
	"cheque.entry_code, ", 
	"cheque.entry_date, ", 
	"cheque.bank_acct_code, ", 
	"cheque.com3_text, ", 
	"cheque.cheq_date, ", 
	"cheque.pay_amt, ", 
	"cheque.net_pay_amt, ", 
	"cheque.year_num, ", 
	"cheque.period_num, ", 
	"cheque.post_flag, ", 
	"cheque.apply_amt, ", 
	"cheque.disc_amt, ", 
	"cheque.rec_state_num, ", 
	"cheque.rec_line_num, ", 
	"cheque.com1_text, ", 
	"cheque.com2_text, ", 
	"cheque.currency_code, ", 
	"cheque.conv_qty ", 
	"FROM cheque, vendor, bank ", 
	" WHERE cheque.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND vendor.vend_code = cheque.vend_code ", 
	" AND vendor.cmpy_code = cheque.cmpy_code ", 
	" AND bank.cmpy_code = cheque.cmpy_code ", 
	" AND bank.bank_code = cheque.bank_code ", 
	" AND ", p_where_text clipped, 
	"ORDER BY cheque.pay_meth_ind,cheque.cheq_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

--	LET glob_rpt_note = "Treasury Report" 
 
	FOREACH selcurs INTO l_rec_cheque.* 

		LET l_rec_cheque.pay_amt = l_rec_cheque.pay_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt / l_rec_cheque.conv_qty 
		LET l_rec_cheque.net_pay_amt = l_rec_cheque.net_pay_amt / l_rec_cheque.conv_qty
		
		#------------------------------------------------------------
		OUTPUT TO REPORT PC7_rpt_list_treasury(rpt_rmsreps_idx_get_idx("PC7_rpt_list_treasury"),l_rec_cheque.*) 
		IF NOT rpt_int_flag_handler2("Cheque: ",l_rec_cheque.cheq_code, "" ,rpt_rmsreps_idx_get_idx("PC7_rpt_list_treasury")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC7_rpt_list_treasury
	CALL rpt_finish("PC7_rpt_list_treasury")
	#------------------------------------------------------------
 
--	LET glob_rpt_note = "Distribution by Account (Menu-PC7)" 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PC7-DISTR","PC7_rpt_list_distr",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC7_rpt_list_distr TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	OPEN selcurs ## this OPEN IS TO re OPEN - don't DELETE 
	FOREACH selcurs INTO l_rec_cheque.* 

		DECLARE vos_curs CURSOR FOR 
		SELECT unique vouch_code INTO l_vouch_number FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pay_type_code = "CH" 
		AND pay_num = l_rec_cheque.cheq_code 
		AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
		AND rev_flag IS NULL 

		FOREACH vos_curs 

			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_vouch_number 
			AND vend_code = l_rec_cheque.vend_code 
			LET l_dist_offset = 0 
			DECLARE vallcurs CURSOR FOR 
			SELECT * INTO l_rec_voucherpays.* FROM voucherpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_vouch_number 
			AND rev_flag IS NULL 
			ORDER BY apply_num 

			FOREACH vallcurs 

				LET l_rec_voucherpays.apply_amt = l_rec_voucherpays.apply_amt / 
				l_rec_voucher.conv_qty 
				IF l_rec_voucherpays.vouch_code != l_vouch_number THEN 
					LET l_dist_offset = l_dist_offset + l_rec_voucherpays.apply_amt 
				ELSE 
					LET l_rem_paid = l_rec_voucherpays.apply_amt 
					EXIT FOREACH 
				END IF 

			END FOREACH 

			LET l_tot_in = 0 
			DECLARE vd_curs CURSOR FOR 
			SELECT * INTO l_rec_voucherdist.* FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_vouch_number 
			AND vend_code = l_rec_cheque.vend_code 
			ORDER BY line_num 

			FOREACH vd_curs 

				LET l_rec_voucherdist.dist_amt = l_rec_voucherdist.dist_amt / 
				l_rec_voucher.conv_qty 
				LET l_tot_int = l_tot_in + l_rec_voucherdist.dist_amt 
				IF l_tot_int > l_dist_offset THEN 
					IF l_rec_voucherdist.dist_amt >= l_rem_paid 
					THEN 
						LET l_rec_voucherdist.dist_amt = l_rem_paid 
						LET l_rem_paid = 0 
					ELSE 
						LET l_rem_paid = l_rem_paid - l_rec_voucherdist.dist_amt 
					END IF 

					#------------------------------------------------------------
					OUTPUT TO REPORT PC7_rpt_list_distr(rpt_rmsreps_idx_get_idx("PC7_rpt_list_distr"),l_rec_voucherdist.*) 
					#------------------------------------------------------------

				END IF 
				LET l_tot_in = l_tot_int 

			END FOREACH 

		END FOREACH 
		#------------------------------------------------------------
		IF NOT rpt_int_flag_handler2("Voucher: ",l_rec_voucherdist.vouch_code , "" ,rpt_rmsreps_idx_get_idx("PC7_rpt_list_distr")) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PC7_rpt_list_distr
	CALL  rpt_finish("PC7_rpt_list_distr")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 


REPORT PC7_rpt_list_treasury(p_rpt_idx,p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		cheq_code LIKE cheque.cheq_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_acct_code LIKE cheque.bank_acct_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		rec_state_num LIKE cheque.rec_state_num, 
		rec_line_num LIKE cheque.rec_line_num, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text, 
		currency_code LIKE cheque.currency_code, 
		conv_qty LIKE cheque.conv_qty 
	END RECORD 
	DEFINE l_pay_text CHAR(3) 

	OUTPUT 
		ORDER external BY p_rec_cheque.pay_meth_ind,p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, "Cheque", 
			COLUMN 15, "Cheque ", 
			COLUMN 37, "Date", 
			COLUMN 43, "Period", 
			COLUMN 57, "Gross", 
			COLUMN 70, "Amount", 
			COLUMN 88, "Net", 
			COLUMN 93, "Post", 
			COLUMN 98, "Vendor " 
			PRINT COLUMN 1, "Number", 
			COLUMN 15, "Reference", 
			COLUMN 56, "Amount", 
			COLUMN 70, "Applied", 
			COLUMN 86, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			LET l_pay_text = NULL 
			IF p_rec_cheque.pay_meth_ind = "3" THEN 
				LET l_pay_text = "EFT" 
			END IF 
			PRINT COLUMN 01, p_rec_cheque.cheq_code USING "#########", 
			COLUMN 11, l_pay_text, 
			COLUMN 15, p_rec_cheque.com3_text[1,19], 
			COLUMN 35, p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 44, p_rec_cheque.period_num USING "##", 
			COLUMN 48, p_rec_cheque.pay_amt USING "---,---,--&.&&", 
			COLUMN 63, p_rec_cheque.apply_amt USING "---,---,--&.&&", 
			COLUMN 78, p_rec_cheque.net_pay_amt USING "---,---,--&.&&", 
			COLUMN 95, p_rec_cheque.post_flag, 
			COLUMN 98, p_rec_cheque.vend_code, 
			COLUMN 107,p_rec_cheque.name_text[1,26] 

		ON LAST ROW 
			NEED 12 LINES 
			SKIP 2 line 
			PRINT COLUMN 1, "All VALUES in Base Currency" 
			PRINT COLUMN 1, "Cheques: ", count(*) USING "####", 
			COLUMN 20,"Avg: ",avg(p_rec_cheque.pay_amt) 
			USING "---,---,--&.&&", 
			COLUMN 48, sum(p_rec_cheque.pay_amt) 
			USING "---,---,--&.&&", 
			COLUMN 63, sum(p_rec_cheque.apply_amt) 
			USING "---,---,--&.&&", 
			COLUMN 78, sum(p_rec_cheque.net_pay_amt) 
			USING "---,---,--&.&&" 
			SKIP 2 line 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


REPORT PC7_rpt_list_distr(p_rpt_idx, p_rec_voucherdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_coa RECORD LIKE coa.*

	OUTPUT 
		ORDER BY p_rec_voucherdist.acct_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01,"Account", 
			COLUMN 20,"Description", 
			COLUMN 71,"Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_voucherdist.acct_code 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_voucherdist.acct_code 

		AFTER GROUP OF p_rec_voucherdist.acct_code 
			PRINT COLUMN 01, l_rec_coa.acct_code, 
			COLUMN 20, l_rec_coa.desc_text, 
			COLUMN 61, GROUP sum(p_rec_voucherdist.dist_amt) 
			USING "-----,---,--&.&&" 

		ON LAST ROW 
			NEED 12 LINES 
			SKIP 2 line 
			PRINT COLUMN 1, "All VALUES in Base Currency", 
			COLUMN 60, sum(p_rec_voucherdist.dist_amt) 
			USING "------,---,--&.&&" 
			SKIP 2 line 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 


