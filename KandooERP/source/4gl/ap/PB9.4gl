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
GLOBALS "../ap/PB_GROUP_GLOBALS.4gl" 

############################################################
# FUNCTION PB9_main()
#
# Voucher Listing By Year, Period (NOT converted TO local currency)
############################################################
FUNCTION PB9_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PB9")  

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P168 with FORM "P168" 
			CALL windecoration_p("P168") 
		
			MENU " Voucher Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB9","menu-voucher-1") 
					CALL PB9_rpt_process(PB9_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL PB9_rpt_process(PB9_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"	#COMMAND "Report" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P168 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P168 with FORM "P168" 
			CALL windecoration_p("P168") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB9_rpt_query()) #save where clause in env 
			CLOSE WINDOW P168 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB9_rpt_process(get_url_sel_text())
	END CASE					
END FUNCTION 
############################################################
# END FUNCTION PB9_main()
############################################################


############################################################
# FUNCTION PB9_rpt_query()
#
#
############################################################
FUNCTION PB9_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE " Enter Selection Criteria - ESC TO Continue " 

	CONSTRUCT BY NAME l_where_text ON voucher.vend_code, 
	vendor.name_text, 
	vendor.currency_code, 
	voucher.vouch_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.entry_date, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.total_amt, 
	voucher.paid_amt, 
	voucher.post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PB9","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR " Printing was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION PB9_rpt_query()
############################################################


############################################################
# FUNCTION PB9_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PB9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_print RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		entry_date LIKE voucher.entry_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PB9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PB9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	LET l_query_text = 
	"SELECT voucher.vend_code,", 
	"vendor.name_text,", 
	"vendor.currency_code,", 
	"voucher.vouch_code,", 
	"voucher.inv_text,", 
	"voucher.vouch_date,", 
	"voucher.entry_date,", 
	"voucher.year_num,", 
	"voucher.period_num,", 
	"voucher.total_amt,", 
	"voucher.poss_disc_amt,", 
	"voucher.paid_amt,", 
	"voucher.post_flag ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE voucher.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB9_rpt_list")].sel_text clipped," "
	
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	
	FOREACH c_voucher INTO l_rec_print.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PB9_rpt_list(l_rpt_idx,
		l_rec_print.*) 
		IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_print.vouch_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		 	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PB9_rpt_list
	CALL rpt_finish("PB9_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF
END FUNCTION 
############################################################
# END FUNCTION PB9_rpt_process(p_where_text)
###########################################################


############################################################
# REPORT PB9_rpt_list(p_rpt_idx,p_rec_print)
#
#
############################################################
REPORT PB9_rpt_list(p_rpt_idx,p_rec_print) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_print RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		entry_date LIKE voucher.entry_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag 
	END RECORD, 
	tot_total_amt,tot_poss_disc_amt,tot_paid_amt, 
	y_tot_total_amt, y_tot_poss_disc_amt,y_tot_paid_amt, 
	g_tot_total_amt,g_tot_poss_disc_amt,g_tot_paid_amt money(14,2) 

	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_print.year_num, 
	p_rec_print.period_num, 
	p_rec_print.vouch_code 

	FORMAT 
		PAGE HEADER 
			IF pageno = 1 THEN 
				LET tot_total_amt = 0 
				LET tot_poss_disc_amt = 0 
				LET tot_paid_amt = 0 
				LET g_tot_total_amt = 0 
				LET g_tot_poss_disc_amt = 0 
				LET g_tot_paid_amt = 0 
				LET y_tot_total_amt = 0 
				LET y_tot_poss_disc_amt = 0 
				LET y_tot_paid_amt = 0 
			END IF 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 

			PRINT COLUMN 1, "All totals in base currency" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 2, "Voucher", 
			COLUMN 10, "Vendor", 
			COLUMN 20, "Vendor Name", 
			COLUMN 53, "Vendor", 
			COLUMN 73, "Date", 
			COLUMN 79, "Period", 
			COLUMN 91, "Total", 
			COLUMN 103,"Discount", 
			COLUMN 118,"Paid", 
			COLUMN 124,"Currency" 
			PRINT COLUMN 2, "Number", 
			COLUMN 11, "Code", 
			COLUMN 50, "Invoice Number", 
			COLUMN 90, "Voucher", 
			COLUMN 103,"Possible", 
			COLUMN 117,"Amount", 
			COLUMN 127,"Posted" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_print.period_num 
			SKIP TO top OF PAGE 
			PRINT COLUMN 5, "Fiscal Year: ",p_rec_print.year_num USING "####", 
			COLUMN 23,"Period:",p_rec_print.period_num USING "###" 
			SKIP 1 line 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_print.vouch_code USING "########", 
			COLUMN 10, p_rec_print.vend_code, 
			COLUMN 19, p_rec_print.name_text, 
			COLUMN 50, p_rec_print.inv_text, 
			COLUMN 71, p_rec_print.vouch_date USING "dd/mm/yy", 
			COLUMN 80, p_rec_print.period_num USING "###", 
			COLUMN 84, p_rec_print.total_amt USING "---,---,---.&&", 
			COLUMN 98, p_rec_print.poss_disc_amt USING "---,---,---.&&", 
			COLUMN 112,p_rec_print.paid_amt USING "---,---,---.&&", 
			COLUMN 127,p_rec_print.currency_code, 
			COLUMN 131,p_rec_print.post_flag 
			LET p_rec_print.total_amt = 
			conv_currency(p_rec_print.total_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_print.currency_code, "F", 
			p_rec_print.vouch_date, "B") 
			LET p_rec_print.poss_disc_amt = 
			conv_currency(p_rec_print.poss_disc_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_print.currency_code, "F", 
			p_rec_print.vouch_date, "B") 
			LET p_rec_print.paid_amt = 
			conv_currency(p_rec_print.paid_amt, glob_rec_kandoouser.cmpy_code, 
			p_rec_print.currency_code, "F", 
			p_rec_print.vouch_date, "B") 
			LET tot_total_amt = tot_total_amt + p_rec_print.total_amt 
			LET tot_poss_disc_amt = tot_poss_disc_amt 
			+ p_rec_print.poss_disc_amt 
			LET tot_paid_amt = tot_paid_amt + p_rec_print.paid_amt 

		AFTER GROUP OF p_rec_print.period_num 
			SKIP 1 line 
			PRINT COLUMN 2, "Period Totals:", 
			COLUMN 19,"Vouchers: ",group count(*) USING "<<<<", 
			COLUMN 38,"Average: ",tot_total_amt/group count(*) 
			USING "---,---,---.&&", 
			COLUMN 84, tot_total_amt USING "---,---,---.&&", 
			COLUMN 98, tot_poss_disc_amt USING "---,---,---.&&", 
			COLUMN 112,tot_paid_amt USING "---,---,---.&&" 
			LET y_tot_total_amt = y_tot_total_amt + tot_total_amt 
			LET y_tot_poss_disc_amt = y_tot_poss_disc_amt + tot_poss_disc_amt 
			LET y_tot_paid_amt = y_tot_paid_amt + tot_paid_amt 
			LET tot_total_amt = 0 
			LET tot_poss_disc_amt = 0 
			LET tot_paid_amt = 0 

		AFTER GROUP OF p_rec_print.year_num 
			SKIP 1 line 
			PRINT COLUMN 2, "Year Totals:", 
			COLUMN 19,"Vouchers: ",group count(*) USING "<<<<", 
			COLUMN 38,"Average: ",y_tot_total_amt/group count(*) 
			USING "---,---,---.&&", 
			COLUMN 84, y_tot_total_amt USING "---,---,---.&&", 
			COLUMN 98, y_tot_poss_disc_amt USING "---,---,---.&&", 
			COLUMN 112,y_tot_paid_amt USING "---,---,---.&&" 
			LET g_tot_total_amt = g_tot_total_amt + y_tot_total_amt 
			LET g_tot_poss_disc_amt = g_tot_poss_disc_amt 
			+ y_tot_poss_disc_amt 
			LET g_tot_paid_amt = g_tot_paid_amt + y_tot_paid_amt 
			LET y_tot_total_amt = 0 
			LET y_tot_poss_disc_amt = 0 
			LET y_tot_paid_amt = 0 

		ON LAST ROW 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
			PRINT COLUMN 2, "Report Totals:", 
			COLUMN 19,"Vouchers: ",count(*) using "<<<<", 
			COLUMN 38,"Average: ",g_tot_total_amt/count(*) 
			USING "---,---,---.&&", 
			COLUMN 84, g_tot_total_amt USING "---,---,---.&&", 
			COLUMN 98, g_tot_poss_disc_amt USING "---,---,---.&&", 
			COLUMN 112,g_tot_paid_amt USING "---,---,---.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
			LET g_tot_total_amt = 0 
			LET g_tot_poss_disc_amt = 0 
			LET g_tot_paid_amt = 0 
END REPORT 
############################################################
# END REPORT PB9_rpt_list(p_rpt_idx,p_rec_print)
############################################################