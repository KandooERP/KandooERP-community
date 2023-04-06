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
GLOBALS "../pu/RA6_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################  
DEFINE modu_start_flg INTEGER 
###########################################################################
# FUNCTION RA6_main()
#
# RA6 Purchase Order Detail Report by Product
###########################################################################
FUNCTION RA6_main() 
 	DEFER quit 
	DEFER interrupt
	 
	CALL setModuleId("RA6") -- albo 

	CLEAR screen 
	OPEN WINDOW R124 with FORM "R124" 
	CALL  windecoration_r("R124") 

	MENU " Purchase Order Detail by Product" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","RA6","menu-purchase_order_Det-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL RA6_rpt_query() 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW R124 
	CLEAR screen 
END FUNCTION 
###########################################################################
# END FUNCTION RA6_main()
###########################################################################


###########################################################################
# FUNCTION RA6_rpt_query()
#
#
###########################################################################
FUNCTION RA6_rpt_query() 
	DEFINE l_where_text STRING 
	LET modu_start_flg = 0 

	LET msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria;  OK TO Continue.
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
			CALL publish_toolbar("kandoo","RA6","construct-purchhead-1") 

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
# END FUNCTION RA6_rpt_query()
###########################################################################


###########################################################################
# FUNCTION RA6_rpt_process(p_where_text)
#
#
###########################################################################
FUNCTION RA6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE exist SMALLINT 
	DEFINE pr_purchdetl RECORD 
		cmpy_code LIKE purchdetl.cmpy_code, 
		vend_code LIKE purchdetl.vend_code, 
		order_num LIKE purchdetl.order_num, 
		line_num LIKE purchdetl.line_num, 
		seq_num LIKE purchdetl.seq_num, 
		type_ind LIKE purchdetl.type_ind, 
		ref_text LIKE purchdetl.ref_text, 
		oem_text LIKE purchdetl.oem_text, 
		job_code LIKE purchdetl.job_code, 
		var_num LIKE purchdetl.var_num, 
		activity_code LIKE purchdetl.activity_code, 
		desc_text LIKE purchdetl.desc_text, 
		uom_code LIKE purchdetl.uom_code, 
		acct_code LIKE purchdetl.acct_code, 
		pr_order_date LIKE purchhead.order_date, 
		pr_curr_code LIKE purchhead.curr_code, 
		pr_conv_qty LIKE purchhead.conv_qty 
	END RECORD 
	LET modu_start_flg = 0 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"RA6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT RA6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT purchdetl.*,purchhead.order_date, purchhead.curr_code, ", 
	" purchhead.conv_qty ", 
	"FROM purchdetl, purchhead ", 
	"WHERE purchdetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND purchdetl.cmpy_code = purchhead.cmpy_code AND purchdetl.vend_code = purchhead.vend_code AND purchdetl.order_num = purchhead.order_num AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("RA6_rpt_list")].sel_text clipped," ",

	" ORDER BY purchdetl.ref_text, purchhead.curr_code, purchdetl.order_num" 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 
	--   OPEN WINDOW wfPU AT 10,10  -- albo  KD-756
	--      with 1 rows, 50 columns
	--      ATTRIBUTE(border)
 
	WHILE true 
		FETCH selcurs INTO pr_purchdetl.* 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT RA6_rpt_list(l_rpt_idx,pr_purchdetl.* )
		IF NOT rpt_int_flag_handler2("Purchase Order:",pr_purchdetl.order_num,NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------	


	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT RA6_rpt_list
	CALL rpt_finish("RA6_rpt_list")
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
# END FUNCTION RA6_rpt_process(p_where_text)
###########################################################################


###########################################################################
# REPORT RA6_rpt_list(p_rpt_idx,pr_purchdetl)
#
#
###########################################################################
REPORT RA6_rpt_list(p_rpt_idx,pr_purchdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	  
	DEFINE pr_purchdetl RECORD 
		cmpy_code LIKE purchdetl.cmpy_code, 
		vend_code LIKE purchdetl.vend_code, 
		order_num LIKE purchdetl.order_num, 
		line_num LIKE purchdetl.line_num, 
		seq_num LIKE purchdetl.seq_num, 
		type_ind LIKE purchdetl.type_ind, 
		ref_text LIKE purchdetl.ref_text, 
		oem_text LIKE purchdetl.oem_text, 
		job_code LIKE purchdetl.job_code, 
		var_num LIKE purchdetl.var_num, 
		activity_code LIKE purchdetl.activity_code, 
		desc_text LIKE purchdetl.desc_text, 
		uom_code LIKE purchdetl.uom_code, 
		acct_code LIKE purchdetl.acct_code, 
		pr_order_date LIKE purchhead.order_date, 
		pr_curr_code LIKE purchhead.curr_code, 
		pr_conv_qty LIKE purchhead.conv_qty 
	END RECORD 
	DEFINE pr_poaudit RECORD LIKE poaudit.* 
	DEFINE new_o_flg, new_v_flg, v_order_num, order_count INTEGER 
	DEFINE total_amt, part_total, grand_total LIKE poaudit.unit_cost_amt
		 
	OUTPUT 
--	left margin 0 

	ORDER external BY pr_purchdetl.ref_text, 
	pr_purchdetl.pr_curr_code, 
	pr_purchdetl.order_num 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET part_total = 0 
				LET grand_total = 0 
				LET total_amt = 0 
			END IF
			 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

			PRINT COLUMN 1, "Ref ", 
			COLUMN 27, "Vendor", 
			COLUMN 37, "Order", 
			COLUMN 45, "Curr", 
			COLUMN 52, "Quantity", 
			COLUMN 63, "UOM", 
			COLUMN 76, "Cost", 
			COLUMN 94, "Tax", 
			COLUMN 100 , "Acct", 
			COLUMN 121, "Total" 

			PRINT COLUMN 1, "Code", 
			COLUMN 37, "Number", 
			COLUMN 45, "Code", 
			COLUMN 100, "Code" 


			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 27, pr_purchdetl.vend_code, 
			COLUMN 37, pr_purchdetl.order_num USING "#######", 
			COLUMN 45, pr_purchdetl.pr_curr_code; 
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

			PRINT COLUMN 50, pr_poaudit.order_qty , 
			COLUMN 63, pr_purchdetl.uom_code; 

			PRINT COLUMN 68, pr_poaudit.unit_cost_amt USING "---,---,---.&&" , 
			COLUMN 82, pr_poaudit.unit_tax_amt USING "--,---,---.&&", 
			COLUMN 97, pr_purchdetl.acct_code; 
			PRINT COLUMN 116,pr_poaudit.line_total_amt USING "---,---,---.&&" 

			LET total_amt = total_amt + pr_poaudit.line_total_amt 
			LET part_total = part_total + (pr_poaudit.line_total_amt / 
			pr_purchdetl.pr_conv_qty) 

		ON LAST ROW 

			NEED 5 LINES 
			SKIP 1 line 
			PRINT COLUMN 116, "---------------" 
			PRINT COLUMN 1, "Report Totals in Base Currency :", 
			COLUMN 50, "Orders:", count(*) USING "####", 
			COLUMN 113, grand_total USING "--,---,---,---.&&" 
			SKIP 2 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

		BEFORE GROUP OF pr_purchdetl.ref_text 
			PRINT COLUMN 1, pr_purchdetl.ref_text; 

		AFTER GROUP OF pr_purchdetl.ref_text 
			PRINT COLUMN 116, "---------------" 
			PRINT COLUMN 1, "Product Total in Base Currency ", 
			COLUMN 50, "Orders:", GROUP count(*) USING "####", 
			COLUMN 114, part_total USING "-,---,---,---.&&" 
			SKIP 1 line 
			LET grand_total = grand_total + part_total 
			LET part_total = 0 

		AFTER GROUP OF pr_purchdetl.pr_curr_code 
			PRINT COLUMN 116, "---------------" 
			PRINT COLUMN 1, "Total ", pr_purchdetl.pr_curr_code, 
			COLUMN 114, total_amt USING "-,---,---,---.&&" 
			LET total_amt = 0 
END REPORT 
###########################################################################
# END REPORT RA6_rpt_list(p_rpt_idx,pr_purchdetl)
###########################################################################