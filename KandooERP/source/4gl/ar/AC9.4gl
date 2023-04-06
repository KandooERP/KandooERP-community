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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AC_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AC9_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"

#####################################################################
# FUNCTION AC9_main()
#
# Purpose - AC9 Cash Receipts By Number
#####################################################################
FUNCTION AC9_main() 

	CALL setModuleId("AC9") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW A219 with FORM "A219" 
			CALL windecoration_a("A219") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			MENU " Cash Receipts by Number" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AC9","menu-cash-receipts-number") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AC9_rpt_process(AC9_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" #COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL AC9_rpt_process(AC9_rpt_query())
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
				
			END MENU 
			CLOSE WINDOW A219
 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AC9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A219 with FORM "A219" 
			CALL windecoration_a("A219") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AC9_rpt_query()) #save where clause in env 
			CLOSE WINDOW A219 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AC9_rpt_process(get_url_sel_text())
	END CASE			
			 
END FUNCTION 
#####################################################################
# FUNCTION AC9_main()
#####################################################################


#####################################################################
# FUNCTION AC9_rpt_query()
# RETURN 	l_where_text STRING
# cashreceipt query
#####################################################################
FUNCTION AC9_rpt_query() 
	DEFINE r_where_text STRING

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME r_where_text ON 
	cashreceipt.cust_code, 
	customer.name_text, 
	cashreceipt.cash_num, 
	cashreceipt.order_num,
	cashreceipt.cash_date, 
	cashreceipt.cash_type_ind, 
	customer.currency_code, 
	cashreceipt.cash_amt, 
	cashreceipt.applied_amt, 
	cashreceipt.locn_code,
	cashreceipt.disc_amt, 
 	cashreceipt.on_state_flag, 
	cashreceipt.year_num, 
	cashreceipt.period_num, 
	cashreceipt.cash_acct_code, 
	cashreceipt.posted_flag, 
	cashreceipt.cheque_text, 
	cashreceipt.bank_text, 
	cashreceipt.chq_date, 
	cashreceipt.banked_flag, 
	cashreceipt.drawer_text, 
	cashreceipt.branch_text, 
	cashreceipt.banked_date, 
	cashreceipt.bank_dep_num, 
	cashreceipt.com1_text, 
	cashreceipt.com2_text, 
	cashreceipt.entry_code, 
	cashreceipt.entry_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AC9","construct-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		RETURN r_where_text
	END IF

END FUNCTION
#####################################################################
# END FUNCTION AC9_rpt_query()
#####################################################################


#####################################################################
# FUNCTION AC9_rpt_query()
# RETURN 	l_where_text STRING
# cashreceipt query
#####################################################################
FUNCTION AC9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_cust_name_text LIKE customer.name_text
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AC9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT AC9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT cashreceipt.*, customer.name_text ", 
	"FROM cashreceipt, customer ", 
	"WHERE cashreceipt.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND customer.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND customer.cust_code = cashreceipt.cust_code ", 
	"AND ", p_where_text CLIPPED," ",
	"ORDER BY cashreceipt.locn_code,cashreceipt.cash_num" 

	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 

	FOREACH c_cashreceipt INTO l_rec_cashreceipt.*, l_cust_name_text 
		#---------------------------------------------------------
		OUTPUT TO REPORT AC9_rpt_list(l_rpt_idx,l_rec_cashreceipt.*,l_cust_name_text)  
		IF NOT rpt_int_flag_handler2("Receipt:",l_rec_cashreceipt.locn_code, l_rec_cashreceipt.cash_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT AC9_rpt_list
	RETURN rpt_finish("AC9_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
#####################################################################
# END FUNCTION AC9_rpt_query()
#####################################################################


#####################################################################
# REPORT AC9_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_cust_name_text) 
#
# Report Definition/Layout
#####################################################################
REPORT AC9_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_cust_name_text) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE p_cust_name_text LIKE customer.name_text
	DEFINE l_rec_location RECORD LIKE location.*
	DEFINE l_line1 CHAR(80)
	DEFINE l_line2 CHAR(80)
	DEFINE l_offset1 SMALLINT
	DEFINE l_offset2 SMALLINT	
	DEFINE l_v_loc_receipts LIKE cashreceipt.cash_amt
	DEFINE l_v_loc_receipts_curr LIKE cashreceipt.cash_amt
	DEFINE l_v_tot_receipts LIKE cashreceipt.cash_amt
	DEFINE l_v_tot_receipts_curr LIKE cashreceipt.cash_amt 

	ORDER EXTERNAL BY p_rec_cashreceipt.locn_code, p_rec_cashreceipt.cash_num 

	FORMAT 
		FIRST PAGE HEADER 
			LET l_v_tot_receipts = 0
			LET l_v_tot_receipts_curr = 0			
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
		PAGE HEADER 
			SKIP 1 LINE
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	BEFORE GROUP OF p_rec_cashreceipt.locn_code 
		LET l_v_loc_receipts = 0 
		LET l_v_loc_receipts_curr = 0 
		SELECT * INTO l_rec_location.* FROM location 
		WHERE location.locn_code = p_rec_cashreceipt.locn_code 
		AND location.cmpy_code = glob_rec_kandoouser.cmpy_code 
		PRINT COLUMN 01, "Location: ", p_rec_cashreceipt.locn_code CLIPPED,"  ",l_rec_location.desc_text CLIPPED 

	ON EVERY ROW 
		PRINT 
		COLUMN 01, p_rec_cashreceipt.cash_num USING "########", 
		COLUMN 10, p_rec_cashreceipt.cust_code CLIPPED, 
		COLUMN 19, p_cust_name_text CLIPPED 
		PRINT 
		COLUMN 19, p_rec_cashreceipt.cash_date      USING "dd/mm/yy", 
		COLUMN 28, p_rec_cashreceipt.cash_amt       USING "---,---,--&.&&", 
		COLUMN 43, p_rec_cashreceipt.cash_type_ind CLIPPED, 
		COLUMN 47, p_rec_cashreceipt.cheque_text CLIPPED, 
		COLUMN 58, p_rec_cashreceipt.bank_text CLIPPED, 
		COLUMN 74, p_rec_cashreceipt.branch_text CLIPPED, 
		COLUMN 95, p_rec_cashreceipt.drawer_text CLIPPED, 
		COLUMN 116,p_rec_cashreceipt.banked_date    USING "dd/mm/yy", 
		COLUMN 125,p_rec_cashreceipt.bank_dep_num   USING "########" 
		LET l_v_loc_receipts = l_v_loc_receipts + p_rec_cashreceipt.cash_amt 
		LET l_v_loc_receipts_curr = l_v_loc_receipts_curr + (p_rec_cashreceipt.cash_amt / p_rec_cashreceipt.conv_qty) 
		LET l_v_tot_receipts = l_v_tot_receipts + p_rec_cashreceipt.cash_amt 
		LET l_v_tot_receipts_curr = l_v_tot_receipts_curr + (p_rec_cashreceipt.cash_amt / p_rec_cashreceipt.conv_qty) 

	AFTER GROUP OF p_rec_cashreceipt.locn_code 
		PRINT COLUMN 28, "---------------" 
		PRINT COLUMN 28,nvl(l_v_loc_receipts,0)     USING "---,---,--&.&&" 
		PRINT COLUMN 28,nvl(l_v_loc_receipts_curr,0)USING "---,---,--&.&&", 
		COLUMN 43, "(local currency) " 

	ON LAST ROW 
		SKIP 1 LINE 
		PRINT COLUMN 1, "----------------------------------------", 
		"----------------------------------------", 
		"----------------------------------------", 
		"------------" 
		PRINT 
		COLUMN 01, "Total", 
		COLUMN 28, nvl(l_v_tot_receipts,0)          USING "---,---,--&.&&" 
		PRINT 
		COLUMN 01, "Total in local currency", 
		COLUMN 28, nvl(l_v_tot_receipts_curr,0)     USING "---,---,--&.&&" 
		SKIP 4 LINES 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 	
END REPORT
#####################################################################
# END REPORT AC9_rpt_list(p_rpt_idx,p_rec_cashreceipt, p_cust_name_text) 
#####################################################################