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
DEFINE modu_tot_amt DECIMAL(16,2)
DEFINE modu_tot_disc DECIMAL(16,2)
DEFINE modu_tot_paid DECIMAL(16,2)
############################################################
# FUNCTION PB1_main()
#
# PB1 Voucher Listing By Vendor
############################################################
FUNCTION PB1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
		
	CALL setModuleId("PB1") 	 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Voucher by Vendor" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB1","menu-voucher-1")
					CALL rpt_rmsreps_reset(NULL) 
					CALL PB1_rpt_process(PB1_rpt_query()) 
						
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND generate REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PB1_rpt_process(PB1_rpt_query()) 

				ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",interrupt)"Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW P120 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB1_rpt_query()) #save where clause in env 
			CLOSE WINDOW P120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB1_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PB1_main()
############################################################


############################################################
# FUNCTION PB1_rpt_query() 
# RETURN l_ret_sql_sel_text #sql-where-part
#
# Construct for report WHERE query
############################################################
FUNCTION PB1_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria; OK TO Continue.

	CONSTRUCT BY NAME l_where_text ON 
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
			CALL publish_toolbar("kandoo","PB1","construct-remsreps-1") 

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
# END FUNCTION PB1_rpt_query() 
############################################################


############################################################
# FUNCTION PB1_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PB1_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT  #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_query_text STRING 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PB1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PB1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET modu_tot_amt = 0 
	LET modu_tot_disc = 0 
	LET modu_tot_paid = 0 

	LET l_query_text = "SELECT voucher.* ", 
	"FROM voucher, vendor ", 
	"WHERE voucher.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND vendor.cmpy_code = voucher.cmpy_code ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND ",p_where_text CLIPPED," ", #WHERE clause is stored in corresponding rmsreps record
	"ORDER BY voucher.vend_code,", 
	"voucher.vouch_code" 
	
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	FOREACH c_voucher INTO l_rec_voucher.* 

	#------------------------------------------------------------	
		OUTPUT TO REPORT PB1_rpt_list(l_rpt_idx,l_rec_voucher.*) 
		IF NOT rpt_int_flag_handler2("Vendor",l_rec_voucher.vend_code, l_rec_voucher.vouch_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
	#------------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PB1_rpt_list
	RETURN rpt_finish("PB1_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PB1_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PB1_rpt_list(p_rpt_idx,p_rec_voucher)
# RETURN VOID
#
# PB1 - Voucher by Vendor Report
############################################################
REPORT PB1_rpt_list(p_rpt_idx,p_rec_voucher)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_vendor_text LIKE vendor.name_text 
	DEFINE l_vendor_currency_code LIKE vendor.currency_code 
	DEFINE l_vendor_total LIKE voucher.total_amt
	DEFINE l_vendor_disc LIKE voucher.total_amt
	DEFINE l_vendor_paid LIKE voucher.total_amt
	DEFINE l_conv_total LIKE voucher.total_amt
	DEFINE l_conv_disc LIKE voucher.total_amt
	DEFINE l_conv_paid LIKE voucher.total_amt 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132) 
	DEFINE l_avg_amt DECIMAL(16,2)

	OUTPUT 	 
	ORDER external BY p_rec_voucher.vend_code,p_rec_voucher.vouch_code 

	FORMAT 
		PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_voucher.vend_code 
			NEED 8 LINES 
			SKIP 1 LINES 
			LET l_vendor_total = 0 
			LET l_vendor_disc = 0 
			LET l_vendor_paid = 0 
			INITIALIZE l_vendor_text TO NULL 
			INITIALIZE l_vendor_currency_code TO NULL 
			
			SELECT name_text, 
			currency_code 
			INTO l_vendor_text, 
			l_vendor_currency_code 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_voucher.vend_code 
			
			PRINT COLUMN 1, "Vendor : ",p_rec_voucher.vend_code clipped,2 spaces,	l_vendor_text 
			PRINT COLUMN 1, "Currency: ",l_vendor_currency_code 
			SKIP 1 line 
			
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_voucher.vouch_code USING "########", 
			COLUMN 10, p_rec_voucher.inv_text, 
			COLUMN 31, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 40, p_rec_voucher.year_num USING "####", 
			COLUMN 45, p_rec_voucher.period_num USING "###", 
			COLUMN 49, p_rec_voucher.total_amt USING "---,---,--&.&&", 
			COLUMN 64, p_rec_voucher.poss_disc_amt USING "---,---,--&.&&", 
			COLUMN 79, p_rec_voucher.paid_amt USING "---,---,--&.&&", 
			COLUMN 98, p_rec_voucher.post_flag, 
			COLUMN 104, p_rec_voucher.hold_code 
			###-IF there are conv_qty in the system with NULL OR 0 THEN
			###-   change the conv_qty TO equal 1 as default
			IF p_rec_voucher.conv_qty IS NULL OR 
			p_rec_voucher.conv_qty = 0 
			THEN 
				LET p_rec_voucher.conv_qty = 1 
			END IF 
			IF l_vendor_currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_conv_total = p_rec_voucher.total_amt / p_rec_voucher.conv_qty 
				LET l_conv_disc = p_rec_voucher.poss_disc_amt / p_rec_voucher.conv_qty 
				LET l_conv_paid = p_rec_voucher.paid_amt / p_rec_voucher.conv_qty 
				PRINT COLUMN 51, l_conv_total USING "---,---,--&.&&", 
				COLUMN 66, l_conv_disc USING "---,---,--&.&&", 
				COLUMN 81, l_conv_paid USING "---,---,--&.&&" 
				LET l_vendor_total = l_vendor_total + l_conv_total 
				LET l_vendor_disc = l_vendor_disc + l_conv_disc 
				LET l_vendor_paid = l_vendor_paid + l_conv_paid 
			END IF 
			LET modu_tot_amt = modu_tot_amt + p_rec_voucher.total_amt / p_rec_voucher.conv_qty 
			LET modu_tot_disc = modu_tot_disc + p_rec_voucher.poss_disc_amt / p_rec_voucher.conv_qty 
			LET modu_tot_paid = modu_tot_paid + p_rec_voucher.paid_amt / p_rec_voucher.conv_qty 
			
		AFTER GROUP OF p_rec_voucher.vend_code 
			NEED 2 LINES 
			PRINT COLUMN 1, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text 
			PRINT COLUMN 1, "Vouchers: ",group count(*) USING "<<<<<", 
			COLUMN 18,"Average: ",group avg(p_rec_voucher.total_amt) USING "---,---,--&.&&", 
			COLUMN 49,group sum(p_rec_voucher.total_amt) USING "---,---,--&.&&", 
			COLUMN 64,group sum(p_rec_voucher.poss_disc_amt) USING "---,---,--&.&&", 
			COLUMN 79,group sum(p_rec_voucher.paid_amt) USING "---,---,--&.&&" 
			
			IF l_vendor_currency_code != glob_rec_glparms.base_currency_code THEN 
				PRINT COLUMN 51, l_vendor_total USING "---,---,--&.&&", 
				COLUMN 66, l_vendor_disc USING "---,---,--&.&&", 
				COLUMN 81, l_vendor_paid USING "---,---,--&.&&" 
			END IF 
			
		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			LET l_avg_amt = modu_tot_amt / count(*) 
			PRINT COLUMN 1, "Totals In Base Currency: " 
			PRINT COLUMN 1, "Vouchers:", count(*) USING "####", 
			COLUMN 18,"Average: ", l_avg_amt 
			USING "---,---,--&.&&", 
			COLUMN 49, modu_tot_amt USING "---,---,--&.&&", 
			COLUMN 64, modu_tot_disc USING "---,---,--&.&&", 
			COLUMN 79, modu_tot_paid USING "---,---,--&.&&" 
			SKIP 1 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT
############################################################
# END REPORT PB1_rpt_list(p_rpt_idx,p_rec_voucher)
############################################################