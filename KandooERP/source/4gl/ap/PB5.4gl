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
# FUNCTION PB5()
#
# PB5 Voucher Listing  By Purchase Order
############################################################
FUNCTION PB5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("PB5")  

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
		
			MENU " Voucher by P.O Number" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PB5","menu-voucher-1") 
					CALL PB5_rpt_process(PB5_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL PB5_rpt_process(PB5_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 		
		
			END MENU 
		
			CLOSE WINDOW P120 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PB5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P120 with FORM "P120" 
			CALL windecoration_p("P120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PB5_rpt_query()) #save where clause in env 
			CLOSE WINDOW P120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PB5_rpt_process(get_url_sel_text())
	END CASE					
END FUNCTION 
############################################################
# END FUNCTION PB5()
############################################################


############################################################
# FUNCTION PB5_rpt_query() 
#
#
############################################################
FUNCTION PB5_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("U",1001,"") 
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
			CALL publish_toolbar("kandoo","PB5","construct-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR "Report generation was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
############################################################
# END FUNCTION PB5_rpt_query() 
############################################################


############################################################
# FUNCTION PB5_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PB5_rpt_process(p_where_text) 
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
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_got_po CHAR(1)
	DEFINE l_got_job CHAR(1)
	DEFINE l_got_gl CHAR(1)
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PB5",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	--START REPORT PB5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	--WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	--TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	--BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	--LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	--RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
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
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB5")].sel_text clipped," ",
	--"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PB5_rpt_list")].sel_text clipped," ",
	"ORDER BY voucher.vend_code,", 
	"voucher.vouch_code" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR with HOLD FOR s_voucher 

	--DISPLAY " Reporting on Voucher...." at 1,1 
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
		 
		DECLARE c_poaudit CURSOR with HOLD FOR 
		SELECT poaudit.* 
		INTO l_rec_poaudit.* 
		FROM poaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_code = "VO" 
		AND tran_num = l_rec_voucher.vouch_code 
		
		FOREACH c_poaudit 
			IF l_got_po IS NULL THEN 
	
				#------------------------------------------------------------				
				LET l_rpt_idx = rpt_start("PB5-1-PO","PB5_rpt_list_1_po","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT PB5_rpt_list_1_po TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------		

				LET l_got_po = "Y" 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT PB5_rpt_list_1_po(l_rpt_idx,
			l_rec_voucher.*, l_rec_poaudit.*) 
			IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------				
		END FOREACH
		 
		DECLARE c_jobledg CURSOR with HOLD FOR 
		SELECT jobledger.* 
		INTO l_rec_jobledger.* 
		FROM jobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_type_ind = "VO" 
		AND trans_source_num = l_rec_voucher.vouch_code 
		FOREACH c_jobledg 
			IF l_got_job IS NULL THEN 
				--START REPORT PB5_rpt_list_2_jobs TO l_output_a 
				#Start GL report only once			
				#------------------------------------------------------------				
				LET l_rpt_idx = rpt_start("PB5-2-JOBS","PB5_rpt_list_2_jobs","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT PB5_rpt_list_2_jobs TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------				

				LET l_got_job = "Y" 
			END IF 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT PB5_rpt_list_2_jobs(l_rpt_idx,
			l_rec_voucher.*, l_rec_jobledger.*)  
			IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
		END FOREACH
		 
		DECLARE c_vdist CURSOR with HOLD FOR 
		SELECT voucherdist.* 
		INTO l_rec_voucherdist.* 
		FROM voucherdist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_voucher.vend_code 
		AND vouch_code = l_rec_voucher.vouch_code 
		FOREACH c_vdist 
			IF l_got_gl IS NULL THEN 
				#Start GL report only once			
				#------------------------------------------------------------				
				LET l_rpt_idx = rpt_start("PB5-3-GL","PB5_rpt_list_3_gl","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT PB5_rpt_list_3_gl TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
				TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
				BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
				LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
				RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
				#------------------------------------------------------------				
				 
				LET l_got_gl = "Y" 
			END IF 

			#---------------------------------------------------------
			OUTPUT TO REPORT PB5_rpt_list_3_gl(l_rpt_idx,
			l_rec_voucher.*, l_rec_voucherdist.*) 
			IF NOT rpt_int_flag_handler2("Voucher Code:",l_rec_voucher.vouch_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------			
 
		END FOREACH 

	END FOREACH
	 
	LET int_flag = false 
	LET quit_flag = false 

	#PO
	IF l_got_po = "Y" THEN 
		#------------------------------------------------------------
		FINISH REPORT PB5_rpt_list_1_po
		CALL rpt_finish("PB5_rpt_list_1_po")
		#------------------------------------------------------------
	END IF 

	#JOBS
	IF l_got_job = "Y" THEN 
		#------------------------------------------------------------
		FINISH REPORT PB5_rpt_list_2_jobs
		CALL rpt_finish("PB5_rpt_list_2_jobs")
		#------------------------------------------------------------
	END IF 
	
	#GL Report
	IF l_got_gl = "Y" THEN
		#------------------------------------------------------------
		FINISH REPORT PB5_rpt_list_3_gl
		CALL rpt_finish("PB5_rpt_list_3_gl")
		#------------------------------------------------------------
	END IF 

	LET l_got_po = NULL 
	LET l_got_job = NULL 
	LET l_got_gl = NULL 

	CALL rpt_finish("PB5") #special container for all 3 reports
	
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION PB5_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PB5_rpt_list_1_po(p_rpt_idx,p_rec_voucher, p_rec_poaudit)
#
#
############################################################
REPORT PB5_rpt_list_1_po(p_rpt_idx,p_rec_voucher,p_rec_poaudit) 
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
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 
	
	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_voucher.vouch_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 
			COLUMN 1, "Vendor", 
			COLUMN 15, "Voucher", 
			COLUMN 40, "Vendor", 
			COLUMN 61, "Date", 
			COLUMN 70, "Period", 
			COLUMN 87, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 115,"Paid", 
			COLUMN 125,"Posted" 
			PRINT 
			COLUMN 1, "Code", 
			COLUMN 15, "Number", 
			COLUMN 40, "Invoice", 
			COLUMN 87, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 115,"Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_voucher.vouch_code 
			SKIP 1 line 
			PRINT 
			COLUMN 1, p_rec_voucher.vend_code, 
			COLUMN 15, p_rec_voucher.vouch_code USING "<<<<####", 
			COLUMN 40, p_rec_voucher.inv_text clipped, 
			COLUMN 61, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 70, p_rec_voucher.period_num USING "###", 
			COLUMN 81, p_rec_voucher.total_amt USING "---,---,--&.&&", 
			COLUMN 95,p_rec_voucher.poss_disc_amt USING "---,---,--&.&&", 
			COLUMN 110,p_rec_voucher.paid_amt USING "---,---,--&.&&", 
			COLUMN 129,p_rec_voucher.post_flag 
			PRINT COLUMN 31, "PO Num", 
			COLUMN 40, "Line#", 
			COLUMN 50, "Tran. Date", 
			COLUMN 65, "Voucher Qty", 
			COLUMN 83, "Voucher Amt" 

		ON EVERY ROW 
			PRINT COLUMN 30, p_rec_poaudit.po_num USING "#######", 
			COLUMN 40, p_rec_poaudit.line_num USING "<<<<<", 
			COLUMN 50, p_rec_poaudit.tran_date USING "dd/mm/yy", 
			COLUMN 65, p_rec_poaudit.voucher_qty USING "------&.&&&&", 
			COLUMN 81, p_rec_poaudit.ext_cost_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PB5_rpt_list_1_po(p_rpt_idx,p_rec_voucher, p_rec_poaudit)
############################################################


############################################################
# REPORT PB5_rpt_list_2_jobs(p_rpt_idx,p_rec_voucher, p_rec_jobledger)
#
#
############################################################
REPORT PB5_rpt_list_2_jobs(p_rpt_idx,p_rec_voucher,p_rec_jobledger) 
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
	DEFINE p_rec_jobledger RECORD LIKE jobledger.* 

	
	OUTPUT 

	ORDER external BY p_rec_voucher.vouch_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 
			COLUMN 1, "Vendor", 
			COLUMN 15, "Voucher", 
			COLUMN 40, "Vendor", 
			COLUMN 61, "Date", 
			COLUMN 70, "Period", 
			COLUMN 87, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 115,"Paid", 
			COLUMN 125,"Posted" 
			PRINT 
			COLUMN 1, "Code", 
			COLUMN 15, "Number", 
			COLUMN 40, "Invoice", 
			COLUMN 87, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 115,"Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_voucher.vouch_code 
			SKIP 1 line 
			PRINT 
			COLUMN 1, p_rec_voucher.vend_code, 
			COLUMN 15, p_rec_voucher.vouch_code USING "<<<<####", 
			COLUMN 40, p_rec_voucher.inv_text, 
			COLUMN 61, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 70, p_rec_voucher.period_num USING "###", 
			COLUMN 81, p_rec_voucher.total_amt USING "---,---,--&.&&", 
			COLUMN 95,p_rec_voucher.poss_disc_amt USING "---,---,--&.&&", 
			COLUMN 110,p_rec_voucher.paid_amt USING "---,---,--&.&&", 
			COLUMN 129,p_rec_voucher.post_flag 
			PRINT COLUMN 29, "Job Code", 
			COLUMN 40, "Var", 
			COLUMN 45, "Activity", 
			COLUMN 55, "Tran. Date", 
			COLUMN 67, "Voucher Qty", 
			COLUMN 83, "Voucher Amt" 

		ON EVERY ROW 
			PRINT COLUMN 30, p_rec_jobledger.job_code , 
			COLUMN 40, p_rec_jobledger.var_code USING "<<<##", 
			COLUMN 45, p_rec_jobledger.activity_code, 
			COLUMN 55, p_rec_jobledger.trans_date USING "dd/mm/yy", 
			COLUMN 67, p_rec_jobledger.trans_qty USING "------&.&&&&", 
			COLUMN 81, p_rec_jobledger.trans_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			 
END REPORT 
############################################################
# REPORT PB5_rpt_list_2_jobs(p_rpt_idx,p_rec_voucher, p_rec_jobledger)
############################################################


############################################################
# REPORT PB5_rpt_list_3_gl(p_rec_voucher, p_rec_voucherdist)
#
#
############################################################
REPORT PB5_rpt_list_3_gl(p_rpt_idx,p_rec_voucher,p_rec_voucherdist) 
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
	DEFINE p_rec_voucherdist RECORD LIKE voucherdist.* 
	
	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_voucher.vouch_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT 
			COLUMN 1, "Vendor", 
			COLUMN 15, "Voucher", 
			COLUMN 40, "Vendor", 
			COLUMN 61, "Date", 
			COLUMN 70, "Period", 
			COLUMN 87, "Total", 
			COLUMN 100,"Discount", 
			COLUMN 115,"Paid", 
			COLUMN 125,"Posted" 
			PRINT 
			COLUMN 1, "Code", 
			COLUMN 15, "Number", 
			COLUMN 40, "Invoice", 
			COLUMN 87, "Voucher", 
			COLUMN 100,"Possible", 
			COLUMN 115,"Amount" 
			PRINT COLUMN 1, rpt_get_char_line(p_rpt_idx,NULL,"-")

		BEFORE GROUP OF p_rec_voucher.vouch_code 
			SKIP 1 line 
			PRINT 
			COLUMN 1, p_rec_voucher.vend_code, 
			COLUMN 15, p_rec_voucher.vouch_code USING "<<<<####", 
			COLUMN 40, p_rec_voucher.inv_text, 
			COLUMN 61, p_rec_voucher.vouch_date USING "dd/mm/yy", 
			COLUMN 70, p_rec_voucher.period_num USING "###", 
			COLUMN 81, p_rec_voucher.total_amt USING "---,---,--&.&&", 
			COLUMN 95,p_rec_voucher.poss_disc_amt USING "---,---,--&.&&", 
			COLUMN 110,p_rec_voucher.paid_amt USING "---,---,--&.&&", 
			COLUMN 129,p_rec_voucher.post_flag 
			PRINT COLUMN 20, "Acct Code", 
			COLUMN 40, "Description", 
			COLUMN 83, "Voucher Amt" 

		ON EVERY ROW 
			PRINT COLUMN 20, p_rec_voucherdist.acct_code , 
			COLUMN 40, p_rec_voucherdist.desc_text, 
			COLUMN 81, p_rec_voucherdist.dist_amt USING "---,---,--&.&&" 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PB5_rpt_list_3_gl(p_rec_voucher, p_rec_voucherdist)
############################################################