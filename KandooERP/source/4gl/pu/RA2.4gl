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
GLOBALS "../pu/RA2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
###########################################################################
# FUNCTION RA2_main()
#
# RA2 Purchase Order Listing By NUMBER
###########################################################################
FUNCTION RA2_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("RA2") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW R107 with FORM "R107" 
			CALL  windecoration_r("R107") 

			MENU " Purchase Orders (by Number)" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","RA2","menu-purchase_orders-1") 
					CALL RA2_rpt_process(RA2_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL RA2_rpt_process(RA2_rpt_query())

				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 

			CLOSE WINDOW R107 

		WHEN "2" #Background Process with rmsreps.report_code
			CALL RA2_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R107 with FORM "R107" 
			CALL  windecoration_r("R107") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RA2_rpt_query()) #save where clause in env 
			CLOSE WINDOW R107 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RA2_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
###########################################################################
# END FUNCTION RA2_main()
###########################################################################


###########################################################################
# FUNCTION RA2_rpt_query()
#
# 
###########################################################################
FUNCTION RA2_rpt_query() 
	DEFINE l_where_text STRING  

	LET msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON vend_code, 
	order_num, 
	order_text, 
	salesperson_text, 
	ware_code, 
	status_ind, 
	printed_flag, 
	confirm_ind, 
	confirm_text, 
	authorise_code, 
	order_date, 
	due_date, 
	confirm_date, 
	cancel_date, 
	curr_code, 
	year_num, 
	period_num, 
	conv_qty, 
	com1_text, 
	com2_text, 
	enter_code, 
	entry_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","RA2","construct-purchhead-1") 

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
# END FUNCTION RA2_rpt_query()
###########################################################################


###########################################################################
# FUNCTION RA2_rpt_process(p_where_text)
#
# 
###########################################################################
FUNCTION RA2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_total_rec RECORD 
		order_amt LIKE poaudit.unit_cost_amt, 
		received_amt LIKE poaudit.unit_cost_amt, 
		voucher_amt LIKE poaudit.unit_cost_amt, 
		tax_amt LIKE poaudit.unit_cost_amt 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RA2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RA2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM purchhead ", 
	"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA2_rpt_list")].sel_text clipped," ", 
	"ORDER BY order_num" 

	PREPARE s_purchhead FROM l_query_text 
	DECLARE c_purchhead CURSOR FOR s_purchhead
	 
	FOREACH c_purchhead INTO pr_purchhead.* 
		CALL po_head_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
		RETURNING pr_total_rec.*

		#---------------------------------------------------------
		OUTPUT TO REPORT RA2_rpt_list(l_rpt_idx,pr_total_rec.*)
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchhead.order_num,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT RA2_rpt_list
	CALL rpt_finish("RA2_rpt_list")
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
# END FUNCTION RA2_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT RA2_rpt_list(p_rpt_idx,pr_purchhead,pr_total_rec)
#
# 
###########################################################################
REPORT RA2_rpt_list(p_rpt_idx,pr_purchhead,pr_total_rec) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_purchhead RECORD LIKE purchhead.* 
	DEFINE pr_total_rec RECORD 
		order_amt LIKE poaudit.unit_cost_amt, 
		received_amt LIKE poaudit.unit_cost_amt, 
		voucher_amt LIKE poaudit.unit_cost_amt, 
		tax_amt LIKE poaudit.unit_cost_amt 
	END RECORD 


	OUTPUT 
--	left margin 0 
	ORDER external BY pr_purchhead.order_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		ON EVERY ROW 
			PRINT COLUMN 01, pr_purchhead.vend_code, 
			COLUMN 10, pr_purchhead.order_num USING "#########", 
			COLUMN 26, pr_purchhead.order_date USING "dd/mm/yy", 
			COLUMN 40, pr_purchhead.due_date USING "dd/mm/yy", 
			COLUMN 60, pr_purchhead.status_ind, 
			COLUMN 72, pr_purchhead.ware_code, 
			COLUMN 82, pr_purchhead.authorise_code, 
			COLUMN 87,(pr_total_rec.order_amt - pr_total_rec.tax_amt) 
			USING "---,---,---.&&", 
			COLUMN 101, pr_total_rec.tax_amt USING "---,---,---.&&", 
			COLUMN 115, pr_total_rec.order_amt USING "---,---,---.&&", 
			COLUMN 130, pr_purchhead.curr_code 

		ON LAST ROW 
			NEED 4 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
			PRINT COLUMN 25, "Report Totals:", 
			COLUMN 40, "Orders:", count(*) USING "<<<<"; 
			PRINT COLUMN 60, "Average: ",avg(pr_total_rec.order_amt) 
			USING "--,---,---.&&", 
			COLUMN 115, sum(pr_total_rec.order_amt) USING "---,---,---.&&" 
			SKIP 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT
###########################################################################
# END REPORT RA2_rpt_list(p_rpt_idx,pr_purchhead,pr_total_rec)
#
# 
###########################################################################