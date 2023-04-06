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
# FUNCTION PB7()
#
# PB7 Vouchers Approved Listing
############################################################
FUNCTION PB7_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PB7")  

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		
			OPEN WINDOW P121 with FORM "P121" 
			CALL windecoration_p("P121") 
		
			MENU " Approved Voucher Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB7","menu-voucher-1") 
					CALL PB7_rpt_process(PB7_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" 	#COMMAND "Run" " Selection Criteria AND Print Report"
					CALL PB7_rpt_process(PB7_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO Menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P121 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB7_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P121 with FORM "P121" 
			CALL windecoration_p("P121") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB7_rpt_query()) #save where clause in env 
			CLOSE WINDOW P121 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB7_rpt_process(get_url_sel_text())
	END CASE			

END FUNCTION 
############################################################
# END FUNCTION PB7()
############################################################


############################################################
# FUNCTION PB7_rpt_query()
#
#
############################################################
FUNCTION PB7_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON 
		voucher.vend_code, 
		vendor.name_text, 
		vendor.currency_code, 
		voucher.vouch_code, 
		voucher.inv_text, 
		voucher.vouch_date, 
		voucher.year_num, 
		voucher.period_num, 
		voucher.post_flag, 
		voucher.total_amt, 
		voucher.paid_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PB7","construct-voucher-1") 

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
# END FUNCTION PB7_rpt_query()
############################################################


############################################################
# FUNCTION PB7_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PB7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_voucher RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag, 
		approved_by_code LIKE voucher.approved_by_code, 
		approved_code LIKE voucher.approved_code, 
		approved_date LIKE voucher.approved_date, 
		split_from_num LIKE voucher.split_from_num 
	END RECORD 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PB7_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PB7_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
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
	"voucher.year_num,", 
	"voucher.period_num,", 
	"voucher.total_amt,", 
	"voucher.poss_disc_amt,", 
	"voucher.paid_amt,", 
	"voucher.post_flag,", 
	"voucher.approved_by_code,", 
	"voucher.approved_code,", 
	"voucher.approved_date,", 
	"voucher.split_from_num ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE voucher.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND voucher.approved_code = 'Y' ", 
	"AND voucher.approved_date IS NOT NULL ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB7_rpt_list")].sel_text clipped," ", 
	"ORDER BY voucher.vouch_code" 

	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	
	FOREACH c_voucher INTO l_rec_voucher.* 
		LET l_rec_voucher.paid_amt = 
		conv_currency(l_rec_voucher.paid_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_voucher.currency_code, "F", 
		l_rec_voucher.vouch_date, "B") 
		LET l_rec_voucher.total_amt = 
		conv_currency(l_rec_voucher.total_amt, glob_rec_kandoouser.cmpy_code, 
		l_rec_voucher.currency_code, "F", 
		l_rec_voucher.vouch_date, "B") 

		#---------------------------------------------------------
		OUTPUT TO REPORT PB7_rpt_list(l_rpt_idx,
		l_rec_voucher.*)
		IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PB7_rpt_list
	CALL rpt_finish("PB7_rpt_list")
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
# END FUNCTION PB7_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PB7_rpt_list(p_rec_voucher)
#
#
############################################################
REPORT PB7_rpt_list(p_rpt_idx,p_rec_voucher) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucher RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		poss_disc_amt LIKE voucher.poss_disc_amt, 
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag, 
		approved_by_code LIKE voucher.approved_by_code, 
		approved_code LIKE voucher.approved_code, 
		approved_date LIKE voucher.approved_date, 
		split_from_num LIKE voucher.split_from_num 
	END RECORD 

	OUTPUT 
	--left margin 0 
	ORDER external BY p_rec_voucher.vouch_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 1,"All VALUES in base currency" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 2, "Voucher", 
			COLUMN 10, "Vendor", 
			COLUMN 21, "Vendor", 
			COLUMN 39, "Due Date", 
			COLUMN 49, "------Approved------- ", 
			COLUMN 71, "FROM", 
			COLUMN 87, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 117,"Paid", 
			COLUMN 124,"Currency" 
			PRINT COLUMN 2, "Number", 
			COLUMN 11, "Code", 
			COLUMN 18, "Invoice Number", 
			COLUMN 50, "By", 
			COLUMN 57, "Code", 
			COLUMN 63, "Date", 
			COLUMN 70, "Voucher", 
			COLUMN 78, "Period", 
			COLUMN 86, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 116,"Amount", 
			COLUMN 127,"Posted" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_voucher.vouch_code USING "########", 
			COLUMN 10, p_rec_voucher.vend_code, 
			COLUMN 18, p_rec_voucher.inv_text, 
			COLUMN 39, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 50, p_rec_voucher.approved_by_code, 
			COLUMN 59, p_rec_voucher.approved_code, 
			COLUMN 61, p_rec_voucher.approved_date USING "dd/mm/yy", 
			COLUMN 69, p_rec_voucher.split_from_num USING "########", 
			COLUMN 78, p_rec_voucher.period_num USING "###", 
			COLUMN 82, p_rec_voucher.total_amt USING "---,---,--$.&&", 
			COLUMN 96, p_rec_voucher.poss_disc_amt USING "---,---,--$.&&", 
			COLUMN 110,p_rec_voucher.paid_amt USING "---,---,--$.&&", 
			COLUMN 125,p_rec_voucher.currency_code, 
			COLUMN 131,p_rec_voucher.post_flag 
		ON LAST ROW 
			NEED 4 LINES 
			PRINT COLUMN 1,"--------------------------------------------", 
			"--------------------------------------------", 
			"--------------------------------------------" 
			PRINT COLUMN 1, "Vouchers: ",count(*) using "<<<<<", 
			COLUMN 18,"Average: ", avg(p_rec_voucher.total_amt) 
			USING "---,---,--$.&&", 
			COLUMN 82, sum(p_rec_voucher.total_amt) USING "---,---,--$.&&", 
			COLUMN 96, sum(p_rec_voucher.poss_disc_amt) 
			USING "---,---,--$.&&", 
			COLUMN 110,sum(p_rec_voucher.paid_amt) USING "---,---,--$.&&" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
############################################################
# END REPORT PB7_rpt_list(p_rec_voucher)
############################################################