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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
GLOBALS "../pu/RA_GROUP_GLOBALS.4gl"
GLOBALS "../pu/RAB_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RAB_main() 
#
# RAB Goods Receipt Report by Product
########################################################################### 
FUNCTION RAB_main() 
 	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("RAB") -- albo

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
	 
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
			MENU " Purchase Order Detail by Product" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RAB","menu-purch_order_det-1") 
					CALL RAB_rpt_process(RAB_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL RAB_rpt_process(RAB_rpt_query()) 
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R124

		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAB_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAB_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAB_rpt_process(get_url_sel_text())
	END CASE			 
END FUNCTION 
###########################################################################
# END FUNCTION RAB_main() 
########################################################################### 


###########################################################################
# FUNCTION RAB_rpt_query()
#
# 
########################################################################### 
FUNCTION RAB_rpt_query()
	DEFINE l_where_text STRING 	 

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON purchdetl.vend_code, 
	purchdetl.order_num, 
	purchhead.curr_code, 
	purchdetl.type_ind, 
	purchdetl.ref_text, 
	purchdetl.job_code, 
	purchhead.status_ind, 
	purchdetl.activity_code, 
	purchdetl.acct_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RAB","construct-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION RAB_rpt_query()
########################################################################### 


###########################################################################
# FUNCTION RAB_rpt_process(p_where_text)
#
# 
########################################################################### 
FUNCTION RAB_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE exist SMALLINT 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_order_date LIKE purchhead.order_date 
	DEFINE pr_curr_code LIKE purchhead.curr_code 
	DEFINE pr_ware_code LIKE purchhead.ware_code 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RAB_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RAB_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET modu_start_flg = 0 
	 
	LET l_query_text = 
	"SELECT purchdetl.*,purchhead.curr_code, purchhead.order_date, ", 
	" purchhead.ware_code ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND purchdetl.cmpy_code = purchhead.cmpy_code AND purchdetl.vend_code = purchhead.vend_code AND purchdetl.order_num = purchhead.order_num AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAB_rpt_list")].sel_text clipped," ", 
	" ORDER BY purchdetl.ref_text, purchdetl.order_num" 

	PREPARE choice FROM query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.*, 
		pr_curr_code, 
		pr_order_date, 
		pr_ware_code 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT RAB_rpt_list(l_rpt_idx,pr_purchdetl.*, pr_curr_code, 
		pr_order_date, pr_ware_code) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------		

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RAB_rpt_list
	CALL rpt_finish("RAB_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION RAB_rpt_process(p_where_text)
########################################################################### 


###########################################################################
# REPORT RAB_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date,pr_ware_code)
#
# 
########################################################################### 
REPORT RAB_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date,pr_ware_code) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_curr_code LIKE purchhead.curr_code 
	DEFINE pr_order_date LIKE purchhead.order_date 
	DEFINE pr_ware_code LIKE purchhead.ware_code
	DEFINE ps_poaudit RECORD 
		tran_code LIKE poaudit.tran_code, 
		tran_num LIKE poaudit.tran_num, 
		tran_date LIKE poaudit.tran_date, 
		received_qty LIKE poaudit.received_qty 
	END RECORD 
	DEFINE ord_total, rec_total, out_total INTEGER 
	DEFINE gr_ord_total, gr_rec_total, gr_out_total INTEGER
		 
	OUTPUT 
	--left margin 0 
	ORDER external BY pr_purchdetl.ref_text, pr_purchdetl.order_num 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET ord_total = 0 
				LET rec_total = 0 
				LET out_total = 0 
				LET gr_ord_total = 0 
				LET gr_rec_total = 0 
				LET gr_out_total = 0 
			END IF 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			

			PRINT COLUMN 1, "Product", 
			COLUMN 11, "Vendor", 
			COLUMN 20, "Ware", 
			COLUMN 26, "Order", 
			COLUMN 49, "Date", 
			COLUMN 61, "Order", 
			COLUMN 76, "Received", 
			COLUMN 92, "Outstanding" 

			PRINT COLUMN 1, "Code", 
			COLUMN 20, "Code", 
			COLUMN 61, "Quantity", 
			COLUMN 76, "Quantity", 
			COLUMN 92, "Quantity" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		BEFORE GROUP OF pr_purchdetl.ref_text 
			SKIP 1 line 
			PRINT COLUMN 1, pr_purchdetl.ref_text[1,15], 
			COLUMN 20, pr_purchdetl.desc_text 
			SKIP 1 line 

		ON EVERY ROW 
			INITIALIZE pr_poaudit.* TO NULL 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 

			PRINT COLUMN 11, pr_purchdetl.vend_code, 
			COLUMN 20, pr_ware_code, 
			COLUMN 26, pr_purchdetl.order_num USING "<<<<<<<", 
			COLUMN 49, pr_order_date USING "dd/mm/yy", 
			COLUMN 58, pr_poaudit.order_qty USING "--,---,--&.&&", 
			#         COLUMN 73, pr_poaudit.received_qty using "--,---,--&.&&",
			COLUMN 89, (pr_poaudit.order_qty - pr_poaudit.received_qty) 
			USING "--,---,--&.&&" 

			LET gr_ord_total = gr_ord_total + pr_poaudit.order_qty 
			LET gr_rec_total = gr_rec_total + pr_poaudit.received_qty 
			LET gr_out_total = gr_out_total + (pr_poaudit.order_qty - 
			pr_poaudit.received_qty) 


			DECLARE audcurs CURSOR FOR 
			SELECT tran_code, tran_num, 
			tran_date, received_qty 
			INTO ps_poaudit.* FROM poaudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			po_num = pr_purchdetl.order_num AND 
			line_num = pr_purchdetl.line_num AND 
			(tran_code = "GR" OR tran_code = "GA") 
			ORDER BY tran_date,tran_num 

			FOREACH audcurs 
				PRINT COLUMN 36, ps_poaudit.tran_code, 
				COLUMN 38, ps_poaudit.tran_num USING "<<<<<<<", 
				COLUMN 49, ps_poaudit.tran_date USING "dd/mm/yy", 
				COLUMN 73, ps_poaudit.received_qty USING "--,---,--&.&&" 
			END FOREACH 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Totals:", 
			COLUMN 58, "-------------", 
			COLUMN 73, "-------------", 
			COLUMN 89, "-------------" 

			PRINT COLUMN 58, ord_total USING "--,---,--&.&&", 
			COLUMN 73, rec_total USING "--,---,--&.&&", 
			COLUMN 89, out_total USING "--,---,--&.&&" 
			SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


		AFTER GROUP OF pr_purchdetl.ref_text 

			PRINT COLUMN 58, "-------------", 
			COLUMN 73, "-------------", 
			COLUMN 89, "-------------" 

			PRINT COLUMN 58, gr_ord_total USING "--,---,--&.&&", 
			COLUMN 73, gr_rec_total USING "--,---,--&.&&", 
			COLUMN 89, gr_out_total USING "--,---,--&.&&" 
			LET ord_total = ord_total + gr_ord_total 
			LET rec_total = rec_total + gr_rec_total 
			LET out_total = out_total + gr_out_total 
			LET gr_ord_total = 0 
			LET gr_rec_total = 0 
			LET gr_out_total = 0 
			SKIP 1 LINES 

END REPORT 
###########################################################################
# END REPORT RAB_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date,pr_ware_code)
###########################################################################