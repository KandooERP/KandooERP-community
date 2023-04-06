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
GLOBALS "../pu/RAA_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

#######################################################################
# MAIN
#
# RAA produces a Goods Receipt Report
#######################################################################
FUNCTION RAA_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("RAA") -- albo 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 
			OPEN WINDOW R107 with FORM "R107" 
			CALL  windecoration_r("R107") 

			MENU " Goods Receipt (by Order)" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","RAA","menu-goods_receipt-1") 
					CALL RAA_rpt_process(RAA_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				COMMAND "Run" " Enter selection criteria AND generate REPORT" 
					CALL RAA_rpt_process(RAA_rpt_query()) 

				ON ACTION "Print Manager" 					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				COMMAND KEY("E",interrupt)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 
			CLOSE WINDOW R107
			 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RAA_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R107 with FORM "R107" 
			CALL  windecoration_r("R107") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RAA_rpt_query()) #save where clause in env 
			CLOSE WINDOW R107 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RAA_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
#######################################################################
# END MAIN
#######################################################################


#######################################################################
# FUNCTION RAA_rpt_query()
#
# 
#######################################################################
FUNCTION RAA_rpt_query() 
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
			CALL publish_toolbar("kandoo","RAA","construct-purchhead-1") 

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
#######################################################################
# FUNCTION RAA_rpt_query()
#
# 
#######################################################################


#######################################################################
# FUNCTION RAA_rpt_process(p_where_text)
#
# 
#######################################################################
FUNCTION RAA_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT 
	DEFINE pr_purchhead RECORD LIKE purchhead.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RAA_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RAA_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM purchhead ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RAA_rpt_list")].sel_text clipped," ", 
	"ORDER BY order_num" 
	PREPARE s_purchhead FROM l_query_text 
	DECLARE c_purchhead CURSOR FOR s_purchhead 
	##
	## setup CURSOR TO access line items
	##
	LET l_query_text = "SELECT * FROM purchdetl ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND order_num = ? ", 
	"ORDER BY order_num,line_num" 
	PREPARE s_purchdetl FROM l_query_text 
	DECLARE c_purchdetl CURSOR FOR s_purchdetl 
	##
	## setup CURSOR TO access audit items
	##
	LET l_query_text = "SELECT * FROM poaudit ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND po_num = ? ", 
	"AND line_num = ? ", 
	"AND tran_code in('GR','GA') ", 
	"AND received_qty <> 0 ", 
	"ORDER BY po_num,line_num,seq_num" 
	PREPARE s_poaudit FROM l_query_text 
	DECLARE c_poaudit CURSOR FOR s_poaudit 
	##

	FOREACH c_purchhead INTO pr_purchhead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT RAA_rpt_list(l_rpt_idx,pr_purchhead.*) 
		IF NOT rpt_int_flag_handler2("Order:",pr_purchhead.order_num,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT RAA_rpt_list
	CALL rpt_finish("RAA_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION RAA_rpt_process(p_where_text)
#######################################################################


#######################################################################
# REPORT RAA_rpt_list(p_rpt_idx,pr_purchhead)
#
# 
#######################################################################
REPORT RAA_rpt_list(p_rpt_idx,pr_purchhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE pr_purchhead RECORD LIKE purchhead.* 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.*
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE ps_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_vendor RECORD LIKE vendor.* 
--	pa_line array[4] OF CHAR(132), 
	DEFINE print_subtext SMALLINT 

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
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchhead.vend_code 
			IF status = notfound THEN 
				LET pr_vendor.name_text = "**********" 
			END IF 
			PRINT COLUMN 01, pr_purchhead.order_num USING "########", 
			COLUMN 10, pr_purchhead.order_date USING "dd/mm/yy", 
			COLUMN 19, pr_purchhead.ware_code , 
			COLUMN 23, pr_purchhead.vend_code, 
			COLUMN 32, pr_vendor.name_text 
			OPEN c_purchdetl USING pr_purchhead.order_num 
			
			FOREACH c_purchdetl INTO pr_purchdetl.* 
				INITIALIZE ps_poaudit.* TO NULL 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num,pr_purchdetl.line_num) 
				RETURNING ps_poaudit.order_qty, 
				ps_poaudit.received_qty, 
				ps_poaudit.voucher_qty, 
				ps_poaudit.unit_cost_amt, 
				ps_poaudit.ext_cost_amt, 
				ps_poaudit.unit_tax_amt, 
				ps_poaudit.ext_tax_amt, 
				ps_poaudit.line_total_amt 
				PRINT COLUMN 30, pr_purchdetl.line_num USING "####&", 
				COLUMN 36, pr_purchdetl.ref_text[1,15], 
				COLUMN 52, pr_purchdetl.desc_text[1,30], 
				COLUMN 82, ps_poaudit.order_qty USING "-------&.&&", 
				COLUMN 94, ps_poaudit.received_qty USING "-------&.&&", 
				COLUMN 108,(ps_poaudit.order_qty-ps_poaudit.received_qty) 
				USING "-------&.&&", 
				COLUMN 120,ps_poaudit.line_total_amt USING "---------&.&&" 
				OPEN c_poaudit USING pr_purchhead.order_num, 
				pr_purchdetl.line_num 
				LET print_subtext = true 
				FOREACH c_poaudit INTO pr_poaudit.* 
					IF print_subtext THEN 
						PRINT COLUMN 52,"Receipt No.:"; 
						LET print_subtext = false 
					END IF 
					PRINT COLUMN 65, pr_poaudit.tran_num USING "<<<<<<<<", 
					COLUMN 73, pr_poaudit.tran_date USING "dd/mm/yy", 
					COLUMN 94, pr_poaudit.received_qty USING "-------&.&&", 
					COLUMN 120,pr_poaudit.line_total_amt USING "---------&.&&" 
				END FOREACH 
			END FOREACH 
			SKIP 1 line 
			
		ON LAST ROW 
			SKIP 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT
#######################################################################
# END REPORT RAA_rpt_list(p_rpt_idx,pr_purchhead)
####################################################################### 