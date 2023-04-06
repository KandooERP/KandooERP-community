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
# Module Scope Variables
############################################################

############################################################
# FUNCTION PB6_main()
#
#
############################################################
FUNCTION PB6_main() 
	DEFER quit 
	DEFER interrupt 
		
	CALL setModuleId("PB6") 	#Initial UI Init 
 
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW p120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Voucher by Batch Number" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB6","menu-voucher-1") 
					CALL PB6_rpt_process(PB6_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" 	#COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL PB6_rpt_process(PB6_rpt_query())

				ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL"	#COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW p120 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB6_rpt_process(NULL) 

		WHEN RPT_OP_CONSTRUCT  #Only create query-where-part
			OPEN WINDOW p120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB6_rpt_query()) #save where clause in env 
			CLOSE WINDOW p120 

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB6_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 
############################################################
# END FUNCTION PB6_main()
############################################################


############################################################
# FUNCTION PB6_rpt_process() 
# RETURN l_ret_sql_sel_text #sql-where-part
#
# Construct for report WHERE query
############################################################
FUNCTION PB6_rpt_query() 
	DEFINE l_ret_sql_sel_text LIKE rmsreps.sel_text

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_ret_sql_sel_text ON 
		voucher.vend_code, 
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
			CALL publish_toolbar("kandoo","PB6","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET l_ret_sql_sel_text = NULL
	END IF 
	
	RETURN l_ret_sql_sel_text

END FUNCTION 
############################################################
# END FUNCTION PB6_rpt_process() 
############################################################


############################################################
# FUNCTION PB6_rpt_process(p_where_text) 
# RETURN VOID
#
# Generates the report
############################################################
FUNCTION PB6_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_printrec RECORD 
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
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag, 
		conv_qty LIKE voucher.conv_qty, 
		batch_num LIKE voucher.batch_num, 
		base_total_amt LIKE voucher.total_amt, 
		base_paid_amt LIKE voucher.paid_amt 
	END RECORD 
	DEFINE l_query_text CHAR(2200) 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PB6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PB6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
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
	"voucher.paid_amt,", 
	"voucher.post_flag, ", 
	"voucher.conv_qty, ", 
	"voucher.batch_num ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND voucher.batch_num IS NOT NULL ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB6_rpt_list")].sel_text clipped, " ", 
	"ORDER BY voucher.batch_num, voucher.vouch_code" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher
	 
	FOREACH c_voucher INTO l_rec_printrec.* 
		###-IF there are conv_qty in the system with NULL OR 0 THEN
		###-   change the conv_qty TO equal 1 as default
		IF l_rec_printrec.conv_qty IS NULL OR 
		l_rec_printrec.conv_qty = 0 
		THEN 
			LET l_rec_printrec.conv_qty = 1 
		END IF 
		LET l_rec_printrec.base_paid_amt = l_rec_printrec.paid_amt / l_rec_printrec.conv_qty 
		LET l_rec_printrec.base_total_amt = l_rec_printrec.total_amt / l_rec_printrec.conv_qty 
		OUTPUT TO REPORT PB6_rpt_list(l_rpt_idx,l_rec_printrec.*) 
		IF NOT rpt_int_flag_handler2("Batch Number",l_rec_printrec.batch_num, "",l_rpt_idx) THEN 		
			EXIT FOREACH 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PB6_rpt_list
	CALL rpt_finish("PB6_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PB6_rpt_process(p_where_text) 
############################################################


############################################################
# REPORT PB6_rpt_list(p_rpt_idx,p_rec_printrec) 
# RETURN VOID
#
# PB6 - Unapproved Vouchers by Vendor Report
############################################################
REPORT PB6_rpt_list(p_rpt_idx,p_rec_printrec) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_printrec RECORD 
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
		paid_amt LIKE voucher.paid_amt, 
		post_flag LIKE voucher.post_flag, 
		conv_qty LIKE voucher.conv_qty, 
		batch_num LIKE voucher.batch_num, 
		base_total_amt LIKE voucher.total_amt, 
		base_paid_amt LIKE voucher.paid_amt 
	END RECORD
	DEFINE l_batch_total LIKE voucher.total_amt 
	DEFINE l_batch_disc LIKE voucher.total_amt
	DEFINE l_batch_paid LIKE voucher.total_amt
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 

	OUTPUT 
	ORDER external BY p_rec_printrec.batch_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_printrec.batch_num 
			NEED 2 LINES 
			PRINT "" 
			LET l_batch_total = 0 
			LET l_batch_disc = 0 
			LET l_batch_paid = 0 
			PRINT COLUMN 1, "Batch No: ",p_rec_printrec.batch_num USING "--------" 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_printrec.vouch_code USING "########", 
			COLUMN 10, p_rec_printrec.vend_code, 
			COLUMN 19, p_rec_printrec.name_text, 
			COLUMN 50, p_rec_printrec.inv_text, 
			COLUMN 71, p_rec_printrec.vouch_date USING "dd/mm/yy", 
			COLUMN 80, p_rec_printrec.year_num USING "####", 
			COLUMN 85, p_rec_printrec.period_num USING "###", 
			COLUMN 89, p_rec_printrec.total_amt USING "---,---,--&.&&", 
			COLUMN 111,p_rec_printrec.paid_amt USING "---,---,--&.&&", 
			COLUMN 126,p_rec_printrec.currency_code, 
			COLUMN 131,p_rec_printrec.post_flag 
			
		AFTER GROUP OF p_rec_printrec.batch_num 
			NEED 2 LINES 
			PRINT COLUMN 89,"--------------", 
			COLUMN 111,"--------------" 
			PRINT COLUMN 89, GROUP sum(p_rec_printrec.base_total_amt) 
			USING "---,---,--&.&&", 
			COLUMN 111,group sum(p_rec_printrec.base_paid_amt) 
			USING "---,---,--&.&&" 
			
		ON LAST ROW 
			NEED 9 LINES 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT "" 
			PRINT COLUMN 01, l_arr_line[3] 
			PRINT COLUMN 2, "Report Totals:", 
			COLUMN 19,"Vouchers: ",count(*) using "<<<<<", 
			COLUMN 89, sum(p_rec_printrec.base_total_amt) USING "---,---,--&.&&", 
			COLUMN 111,sum(p_rec_printrec.base_paid_amt) USING "---,---,--&.&&" 
			PRINT "" 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
############################################################
# END REPORT PB6_rpt_list(p_rpt_idx,p_rec_printrec) 
############################################################