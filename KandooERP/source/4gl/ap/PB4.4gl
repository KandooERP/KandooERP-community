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
# FUNCTION PB4()
#
# PB4 Voucher Listing By Vendor Invoice
############################################################
FUNCTION PB4_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
		
	CALL setModuleId("PB4") 	 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
		
			MENU "Voucher by Vendor Invoice" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB4","menu-voucher-1") 
					CALL PB4_rpt_process(PB4_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL PB4_rpt_process(PB4_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW P120 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB4_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB4_rpt_query()) #save where clause in env 
			CLOSE WINDOW P120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB4_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 
############################################################
# END FUNCTION PB4()
############################################################


############################################################
# FUNCTION PB4_rpt_query()
#
#
############################################################
FUNCTION PB4_rpt_query() 
	DEFINE l_where_text STRING 


	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON voucher.vend_code, 
	vendor.name_text, 
	voucher.vouch_code, 
	voucher.batch_num, 
	vendor.currency_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.due_date, 
	voucher.conv_qty, 
	voucher.withhold_tax_ind, 
	voucher.total_amt, 
	voucher.dist_amt, 
	voucher.paid_amt, 
	voucher.paid_date, 
	voucher.term_code, 
	voucher.tax_code, 
	voucher.hold_code, 
	voucher.disc_date, 
	voucher.taken_disc_amt, 
	voucher.poss_disc_amt, 
	voucher.post_flag, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.entry_code, 
	voucher.entry_date, 
	voucher.com1_text, 
	voucher.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PB4","construct-voucher-1") 

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
# END FUNCTION PB4_rpt_query()
############################################################


############################################################
# FUNCTION PB4_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PB4_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT  #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text STRING 
	DEFINE l_rec_voucher RECORD 
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
		post_flag LIKE voucher.post_flag, 
		conv_qty LIKE voucher.conv_qty, 
		base_total_amt LIKE voucher.total_amt, 
		base_disc_amt LIKE voucher.poss_disc_amt, 
		base_paid_amt LIKE voucher.paid_amt 
	END RECORD 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PB4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PB4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
		
	LET l_query_text = "SELECT voucher.vend_code,", 
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
	"voucher.post_flag, ", 
	"voucher.conv_qty ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE voucher.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB4_rpt_list")].sel_text clipped," ",
	"ORDER BY voucher.vend_code,", 
	"voucher.inv_text" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	

	FOREACH c_voucher INTO l_rec_voucher.* 
		###-IF there are conv_qty in the system with NULL OR 0 THEN
		###-   change the conv_qty TO equal 1 as default
		IF l_rec_voucher.conv_qty IS NULL OR 
		l_rec_voucher.conv_qty = 0 
		THEN 
			LET l_rec_voucher.conv_qty = 1 
		END IF 
		LET l_rec_voucher.base_paid_amt = l_rec_voucher.paid_amt / l_rec_voucher.conv_qty 
		LET l_rec_voucher.base_disc_amt = l_rec_voucher.poss_disc_amt / l_rec_voucher.conv_qty 
		LET l_rec_voucher.base_total_amt = l_rec_voucher.total_amt / l_rec_voucher.conv_qty 

		#---------------------------------------------------------
		OUTPUT TO REPORT PB4_rpt_list(l_rpt_idx,
		l_rec_voucher.*)
		IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PB4_rpt_list
	CALL rpt_finish("PB4_rpt_list")
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
# END FUNCTION PB4_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PB4_rpt_list(p_rec_voucher)
#
#
############################################################
REPORT PB4_rpt_list(p_rpt_idx,p_rec_voucher)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_voucher RECORD 
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
		post_flag LIKE voucher.post_flag, 
		conv_qty LIKE voucher.conv_qty, 
		base_total_amt LIKE voucher.total_amt, 
		base_disc_amt LIKE voucher.poss_disc_amt, 
		base_paid_amt LIKE voucher.paid_amt 
	END RECORD 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_voucher.vend_code,p_rec_voucher.inv_text
	 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1,"Report Totals in base currency" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 1, "Voucher", 
			COLUMN 10, "Invoice", 
			COLUMN 56, "Curr", 
			COLUMN 61, "Date", 
			COLUMN 70, "Period", 
			COLUMN 85, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 115,"Paid", 
			COLUMN 125,"Posted" 
			PRINT COLUMN 1, "Number", 
			COLUMN 10, "Number", 
			COLUMN 56, "Code", 
			COLUMN 85, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 115,"Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_voucher.vend_code 
			SKIP 2 LINES 
			PRINT COLUMN 2, "Vendor: ", p_rec_voucher.vend_code, 
			COLUMN 20, p_rec_voucher.name_text 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_voucher.vouch_code USING "########", 
			COLUMN 10, p_rec_voucher.inv_text, 
			COLUMN 56, p_rec_voucher.currency_code, 
			COLUMN 61, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 70, p_rec_voucher.period_num USING "###", 
			COLUMN 80, p_rec_voucher.total_amt USING "---,---,--&.&&", 
			COLUMN 95, p_rec_voucher.poss_disc_amt USING "---,---,--&.&&", 
			COLUMN 110, p_rec_voucher.paid_amt USING "---,---,--&.&&", 
			COLUMN 129, p_rec_voucher.post_flag 

		AFTER GROUP OF p_rec_voucher.vend_code 
			SKIP 1 line 
			PRINT COLUMN 1, "Invs:", GROUP count(*) USING "####", 
			COLUMN 11,"Avg: ", GROUP avg(p_rec_voucher.total_amt) 
			USING "---,---,--&.&&", 
			COLUMN 80, GROUP sum(p_rec_voucher.total_amt) 
			USING "---,---,--&.&&", 
			COLUMN 95, GROUP sum(p_rec_voucher.poss_disc_amt) 
			USING "---,---,--&.&&", 
			COLUMN 110,group sum(p_rec_voucher.paid_amt) 
			USING "---,---,--&.&&" 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 

		ON LAST ROW 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
			PRINT COLUMN 1, "Vouchers:", count(*) USING "####", 
			COLUMN 18,"Average: ", avg(p_rec_voucher.base_total_amt) 
			USING "---,---,--&.&&", 
			COLUMN 80, sum(p_rec_voucher.base_total_amt) 
			USING "---,---,--&.&&", 
			COLUMN 95, sum(p_rec_voucher.base_disc_amt) 
			USING "---,---,--&.&&", 
			COLUMN 110, sum(p_rec_voucher.base_paid_amt) 
			USING "---,---,--&.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PB4_rpt_list(p_rec_voucher)
############################################################