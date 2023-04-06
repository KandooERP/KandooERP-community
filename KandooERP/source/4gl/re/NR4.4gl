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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/NR_GROUP_GLOBALS.4gl"
GLOBALS "../re/NR4_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_reqperson RECORD LIKE reqperson.* 
	DEFINE pr_reqhead RECORD LIKE reqhead.* 
	DEFINE pr_reqdetl RECORD LIKE reqdetl.* 
	DEFINE pr_product RECORD LIKE product.* 
	DEFINE where_text STRING 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module NR4 - Requisition Back Order Detail List Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NR4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N125 with FORM "N125" 
	CALL windecoration_n("N125") -- albo kd-763 

	MENU "Requisition Back Order Detail List" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL NR4_rpt_query() 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW N125 
END MAIN 


FUNCTION NR4_rpt_query() 
	DEFINE query_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index

	MESSAGE" Enter Selection Criteria - ESC TO Continue "	attribute(yellow) 
	CONSTRUCT BY NAME where_text ON reqhead.person_code, 
	name_text, 
	req_num, 
	stock_ind, 
	ware_code, 
	ref_text, 
	last_del_no, 
	req_date, 
	year_num, 
	period_num, 
	status_ind, 
	part_code, 
	vend_code, 
	desc_text, 
	unit_sales_amt, 
	acct_code, 
	req_qty, 
	reserved_qty, 
	back_qty, 
	picked_qty, 
	confirmed_qty, 
	com1_text, 
	com2_text 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"NR4_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT NR4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	
	LET query_text = "SELECT reqhead.*, reqdetl.* ", 
	" FROM reqhead, reqdetl ", 
	"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqdetl.cmpy_code = reqhead.cmpy_code ", 
	"AND reqdetl.req_num = reqhead.req_num ", 
	"AND reqdetl.back_qty > 0 ", 
	"AND reqdetl.po_qty < reqdetl.back_qty ", 
	"AND ", where_text clipped," ", 
	"ORDER BY reqhead.cmpy_code, ", 
	"reqdetl.part_code,", 
	"reqhead.req_date,", 
	"reqhead.person_code" 
	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead CURSOR FOR s_reqhead 

	FOREACH c_reqhead INTO pr_reqhead.*, pr_reqdetl.*
		#---------------------------------------------------------
		OUTPUT TO REPORT NR4_rpt_list(l_rpt_idx,	 
		pr_reqhead.*, pr_reqdetl.*)
		IF NOT rpt_int_flag_handler2("Requisition Details:",pr_reqhead.req_num, pr_reqdetl.part_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#--------------------------------------------------------- 
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT NR4_rpt_list
	CALL rpt_finish("NR4_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 	
END FUNCTION 


REPORT NR4_rpt_list(p_rpt_idx,pr_reqhead, pr_reqdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_ext_price LIKE reqdetl.unit_sales_amt, 
	pr_tot_ext_price LIKE reqdetl.unit_sales_amt, 
	pr_gtot_ext_price LIKE reqdetl.unit_sales_amt, 
	i,j, col SMALLINT

	OUTPUT 
 
	ORDER external BY pr_reqhead.cmpy_code, 
	pr_reqdetl.part_code, 
	pr_reqhead.req_date, 
	pr_reqhead.person_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 02, "Date", 
			COLUMN 10, "Person", 
			COLUMN 21, "Req", 
			COLUMN 35, "Req", 
			COLUMN 42, "Delivered", 
			COLUMN 54, "Backorder", 
			COLUMN 69, "Description", 
			COLUMN 101, "Unit", 
			COLUMN 109, "Unit Price", 
			COLUMN 125, "Extended" 
			PRINT COLUMN 11, "Code", 
			COLUMN 20, "Number", 
			COLUMN 35, "Qty", 
			COLUMN 45, "Qty", 
			COLUMN 57, "Qty", 
			COLUMN 127, "Price" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_reqdetl.part_code 
			NEED 3 LINES 
			SELECT desc_text INTO pr_product.desc_text FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_reqdetl.part_code 
			SELECT onhand_qty INTO pr_prodstatus.onhand_qty FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_reqdetl.part_code 
			AND ware_code = pr_reqhead.ware_code 
			PRINT COLUMN 01, "ID: ", 
			COLUMN 06, pr_reqdetl.part_code, 
			COLUMN 22, pr_product.desc_text, 
			COLUMN 61, "Available: ", 
			COLUMN 72, pr_prodstatus.onhand_qty USING "#######&.&&" 
			SKIP 1 line 

		ON EVERY ROW 
			LET pr_ext_price = pr_reqdetl.req_qty * pr_reqdetl.unit_sales_amt 
			IF pr_ext_price IS NULL THEN 
				LET pr_ext_price = 0 
			END IF 
			PRINT COLUMN 01, pr_reqhead.req_date USING "dd/mm/yy", 
			COLUMN 10, pr_reqhead.person_code, 
			COLUMN 19, pr_reqdetl.req_num USING "###<<<<<", 
			COLUMN 28, pr_reqdetl.req_qty USING "#######&.&&", 
			COLUMN 40, pr_reqdetl.confirmed_qty USING "#######&.&&", 
			COLUMN 52, pr_reqdetl.back_qty USING "#######&.&&", 
			COLUMN 64, pr_reqdetl.desc_text[1,36], 
			COLUMN 102, pr_reqdetl.uom_code, 
			COLUMN 107, pr_reqdetl.unit_sales_amt USING "$,$$$,$$$.##", 
			COLUMN 120, pr_ext_price USING "$$,$$$,$$$.##" 
			IF pr_tot_ext_price IS NULL THEN 
				LET pr_tot_ext_price = 0 
			END IF 
			IF pr_gtot_ext_price IS NULL THEN 
				LET pr_gtot_ext_price = 0 
			END IF 
			LET pr_tot_ext_price = pr_tot_ext_price + pr_ext_price 
			LET pr_gtot_ext_price = pr_gtot_ext_price + pr_ext_price 


		AFTER GROUP OF pr_reqdetl.part_code 
			PRINT COLUMN 52, "===========", 
			COLUMN 120, "=============" 
			PRINT COLUMN 21, "Item Total: ", 
			COLUMN 52, GROUP sum(pr_reqdetl.back_qty) USING "#######&.&&", 
			COLUMN 119, pr_tot_ext_price USING "$$$,$$$,$$$.##" 
			LET pr_tot_ext_price = 0 
			SKIP 1 line 

		ON LAST ROW 
			NEED 3 LINES 
			SKIP 1 line 
			PRINT COLUMN 03, "Total Lines: ", 
			COLUMN 16, count(*) USING "<<<", 
			COLUMN 119, pr_gtot_ext_price USING "$$$,$$$,$$$.##" 
			NEED 10 LINES 
			SKIP 2 line 
			SKIP 3 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT 
