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
GLOBALS "../pu/RA7_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################   
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RA7_main()
#
# RA7 Purchase Order Detail Report by Job Code
###########################################################################   
FUNCTION RA7_main() 
 	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("RA7") -- albo

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
		
		
			MENU " Purchase Order Detail by Job Code" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","RA7","menu-purchase_order_det-1") 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
					CALL RA7_rpt_query() 
					NEXT option "Print Manager" 
		
				ON ACTION "Print Manager" 
					#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
					NEXT option "Exit" 
		
				COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW R124
			
		WHEN "2" #Background Process with rmsreps.report_code
			CALL RA7_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW R124 with FORM "R124" 
			CALL  windecoration_r("R124") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(RA7_rpt_query()) #save where clause in env 
			CLOSE WINDOW R124 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL RA7_rpt_process(get_url_sel_text())
	END CASE			
			 
END FUNCTION 
###########################################################################
# END FUNCTION RA7_main()
########################################################################### 


###########################################################################
# FUNCTION RA7_rpt_query() 
#
# 
########################################################################### 
FUNCTION RA7_rpt_query() 
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
			CALL publish_toolbar("kandoo","RA7","construct-purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION RA7_rpt_query() 
########################################################################### 


###########################################################################
# FUNCTION RA7_rpt_process(p_where_text)
#
# 
########################################################################### 
FUNCTION RA7_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE exist SMALLINT, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_order_date LIKE purchhead.order_date, 
	pr_curr_code LIKE purchhead.curr_code, 
	pr_conv_qty LIKE purchhead.conv_qty 

	LET modu_start_flg = 0 


	LET l_query_text = 
	"SELECT purchdetl.*, purchhead.curr_code, purchhead.order_date, ", 
	" purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND purchhead.cmpy_code = purchdetl.cmpy_code AND purchdetl.vend_code = purchhead.vend_code AND purchdetl.order_num = purchhead.order_num AND purchdetl.type_ind = \"J\" OR purchdetl.type_ind = \"J\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA7_rpt_list")].sel_text clipped," ",
	" ORDER BY purchdetl.job_code, purchdetl.var_num, purchdetl.activity_code" 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	
	
	OPEN selcurs 
	--OPEN WINDOW wfPU AT 10,10  -- albo  KD-756
	--   with 1 rows, 50 columns
	--   ATTRIBUTE(border)
 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.*,pr_curr_code,pr_order_date, 
		pr_conv_qty 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Printing was aborted.
				LET msgresp=kandoomsg("U",9501,"") 
				EXIT WHILE 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT RA7_rpt_list(l_rpt_idx,pr_purchdetl.*, pr_curr_code,pr_order_date, 
		pr_conv_qty) 
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------			

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RA7_rpt_list
	CALL rpt_finish("RA7_rpt_list")
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
# END FUNCTION RA7_rpt_process(p_where_text)
########################################################################### 


###########################################################################
# REPORT RA7_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
#
# 
########################################################################### 
REPORT RA7_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
	DEFINE pr_frgn RECORD 
		unit_cost_amt LIKE poaudit.unit_cost_amt, 
		unit_tax_amt LIKE poaudit.unit_tax_amt 
	END RECORD 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE pr_curr_code LIKE purchhead.curr_code 
	DEFINE pr_conv_qty LIKE purchhead.conv_qty 
	DEFINE pr_order_date LIKE purchhead.order_date 
	DEFINE new_j_flg, new_a_flg INTEGER 
	DEFINE activity_total, total_amt, job_total, grand_total LIKE poaudit.unit_cost_amt
	
	OUTPUT 
--	left margin 0 
	ORDER external BY pr_purchdetl.job_code, pr_purchdetl.var_num, pr_purchdetl.activity_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			

			PRINT 
			COLUMN 1, "Vendor ", 
			COLUMN 12, "Order", 
			COLUMN 22, "Curr", 
			COLUMN 27, "Reference", 
			COLUMN 37, "Description", 
			COLUMN 70, "Quantity", 
			COLUMN 80, "UOM", 
			COLUMN 93 , "Cost", 
			COLUMN 107, "Tax", 
			COLUMN 121, "Total" 


			PRINT 
			COLUMN 12, "Number", 
			COLUMN 22, "Code" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			PRINT COLUMN 1, pr_purchdetl.vend_code, 
			COLUMN 9, pr_purchdetl.order_num, 
			COLUMN 22, pr_curr_code, 
			COLUMN 27, pr_purchdetl.res_code, 

			COLUMN 36, pr_purchdetl.desc_text[1,25] ; 
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

			PRINT COLUMN 63 , pr_poaudit.order_qty , 
			COLUMN 80, pr_purchdetl.uom_code ; 
			PRINT COLUMN 84 , pr_poaudit.unit_cost_amt USING "---,---,---.&&" , 
			COLUMN 99, pr_poaudit.unit_tax_amt USING "-,---,---.&&", 

			COLUMN 111,pr_poaudit.line_total_amt USING "--,---,---,---.&&" 

			LET activity_total = activity_total + pr_poaudit.line_total_amt 

		ON LAST ROW 
			NEED 3 LINES 
			SKIP 1 line 
			PRINT COLUMN 1, "Report Total in Base Currency :", 
			COLUMN 111, grand_total USING "--,---,---,---.&&" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	


		BEFORE GROUP OF pr_purchdetl.job_code 
			IF modu_start_flg = 0 THEN 
				LET activity_total = 0 
				LET total_amt = 0 
				LET job_total = 0 
				LET grand_total = 0 
				LET modu_start_flg = 1 
			END IF 

			PRINT COLUMN 1, "Job Code: ", pr_purchdetl.job_code ; 

		BEFORE GROUP OF pr_purchdetl.activity_code 
			PRINT COLUMN 25, "Variation Code: ", pr_purchdetl.var_num, 
			COLUMN 51, "Activity Code: ", pr_purchdetl.activity_code 


		AFTER GROUP OF pr_purchdetl.job_code 
			PRINT COLUMN 113, "===============" 
			PRINT COLUMN 1, "Job Total: ", 
			COLUMN 107, pr_curr_code, " ", job_total USING "--,---,---,---.&&" 

			LET grand_total = grand_total + (job_total / pr_conv_qty) 
			LET job_total = 0 
			SKIP 1 line 

		AFTER GROUP OF pr_purchdetl.activity_code 
			PRINT COLUMN 1, "Activity Total:", 
			COLUMN 113, "---------------" 
			PRINT COLUMN 111, activity_total USING "--,---,---,---.&&" 

			LET job_total = job_total + activity_total 
			LET activity_total = 0 

END REPORT 
###########################################################################
# END REPORT RA7_rpt_list(p_rpt_idx,pr_purchdetl,pr_curr_code,pr_order_date, pr_conv_qty)
########################################################################### 