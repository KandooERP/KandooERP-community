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
GLOBALS "../re/NR3_GLOBALS.4gl"  
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
# NR3 - Requisitions History by Product Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NR3") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N125 with FORM "N125" 
	CALL windecoration_n("N125") -- albo kd-763 

	MENU "Requisitions History By Product" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL NR3_rpt_query() 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW N125 
END MAIN 


FUNCTION NR3_rpt_query()
	DEFINE l_rpt_idx SMALLINT  #report array index 
	DEFINE query_text STRING

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"")	#1001" Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME where_text ON reqhead.person_code, 
	name_text, 
	reqhead.req_num, 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"NR3_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT NR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = "SELECT reqhead.*, reqdetl.* ", 
	" FROM reqhead, reqdetl, reqperson ", 
	"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqperson.cmpy_code = reqhead.cmpy_code ", 
	"AND reqdetl.cmpy_code = reqhead.cmpy_code ", 
	"AND reqdetl.req_num = reqhead.req_num ", 
	"AND reqperson.person_code = reqhead.person_code ", 
	"AND ", where_text clipped," ", 
	"ORDER BY reqhead.cmpy_code, ", 
	"reqdetl.part_code, ", 
	"reqhead.req_num" 
	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead CURSOR FOR s_reqhead 
 
	FOREACH c_reqhead INTO pr_reqhead.*, pr_reqdetl.*

		#---------------------------------------------------------
		OUTPUT TO REPORT NR3_rpt_list(l_rpt_idx,	 
		pr_reqhead.*, pr_reqdetl.*) 
		IF NOT rpt_int_flag_handler2("Requ./Part:",pr_reqhead.req_num, pr_reqdetl.part_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 
	

	#------------------------------------------------------------
	FINISH REPORT NR3_rpt_list
	CALL rpt_finish("NR3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT NR3_rpt_list(p_rpt_idx,pr_reqhead, pr_reqdetl)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pr_ext_price LIKE reqdetl.unit_sales_amt, 
	pr_tot_ext_price LIKE reqdetl.unit_sales_amt, 
	pr_gtot_ext_price LIKE reqdetl.unit_sales_amt, 
	i,j, col SMALLINT

	OUTPUT 
 
	ORDER external BY pr_reqhead.cmpy_code, 
	pr_reqdetl.part_code, 
	pr_reqhead.req_num 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 03, "Req", 
			COLUMN 11, "Person", 
			COLUMN 22, "Date", 
			COLUMN 34, "Req", 
			COLUMN 53, "Unit", 
			COLUMN 70, "Extended", 
			COLUMN 83, "Account" 
			PRINT COLUMN 02, "Number", 
			COLUMN 12, "Code", 
			COLUMN 32, "Quantity", 
			COLUMN 53, "Price", 
			COLUMN 72, "Price", 
			COLUMN 84, "Code" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_reqdetl.part_code 
			SKIP 1 line 
			NEED 5 LINES 
			SELECT desc_text, desc2_text 
			INTO pr_product.desc_text, pr_product.desc2_text FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_reqdetl.part_code 
			PRINT COLUMN 02, "Product: ", 
			COLUMN 11, pr_reqdetl.part_code, 
			COLUMN 28, pr_product.desc_text 
			PRINT COLUMN 28, pr_product.desc2_text 

		ON EVERY ROW 
			LET pr_ext_price = pr_reqdetl.req_qty * pr_reqdetl.unit_sales_amt 
			IF pr_ext_price IS NULL THEN 
				LET pr_ext_price = 0 
			END IF 
			PRINT COLUMN 01, pr_reqhead.req_num USING "###<<<<<", 
			COLUMN 11, pr_reqhead.person_code, 
			COLUMN 21, pr_reqhead.req_date USING "dd/mm/yy", 
			COLUMN 30, pr_reqdetl.req_qty USING "#######&.&&", 
			COLUMN 44, pr_reqdetl.unit_sales_amt USING "$,$$$,$$$,$$$.##", 
			COLUMN 63, pr_ext_price USING "$$,$$$,$$$,$$$.##", 
			COLUMN 83, pr_reqdetl.acct_code 
			IF pr_tot_ext_price IS NULL THEN 
				LET pr_tot_ext_price = 0 
			END IF 
			IF pr_gtot_ext_price IS NULL THEN 
				LET pr_gtot_ext_price = 0 
			END IF 
			LET pr_tot_ext_price = pr_tot_ext_price + pr_ext_price 
			LET pr_gtot_ext_price = pr_gtot_ext_price + pr_ext_price 


		AFTER GROUP OF pr_reqdetl.part_code 
			PRINT COLUMN 30, "-----------", 
			COLUMN 62, "------------------" 
			PRINT COLUMN 02, "Totals: ", 
			COLUMN 30, GROUP sum(pr_reqdetl.req_qty) USING "#######&.&&", 
			COLUMN 63, pr_tot_ext_price USING "$$,$$$,$$$,$$$.##" 
			SKIP 1 line 
			PRINT COLUMN 02, "Reqs:", 
			COLUMN 08, GROUP count(*) USING "<<<", 
			COLUMN 12, "Avg:", 
			COLUMN 30, GROUP sum(pr_reqdetl.req_qty) / GROUP count(*) 
			USING "#######&.&&", 
			COLUMN 64, pr_tot_ext_price / GROUP count(*) 
			USING "$,$$$,$$$,$$$.##" 
			PRINT COLUMN 1,"--------------------------------------------", 
			"-----------------------------------" 
			LET pr_tot_ext_price = 0 
			SKIP 1 line 

		ON LAST ROW 
			NEED 8 LINES 
			SKIP 4 LINES 
			PRINT COLUMN 02, "Report Totals: ", 
			COLUMN 30, sum(pr_reqdetl.req_qty) USING "#######&.&&", 
			COLUMN 63, pr_gtot_ext_price USING "$$,$$$,$$$,$$$.##" 

			SKIP 1 line 

			PRINT COLUMN 02, "Reqs:", 
			COLUMN 08, count(*) USING "<<<", 
			COLUMN 12, "Avg:", 
			COLUMN 30, sum(pr_reqdetl.req_qty) / count(*) USING "#######&.&&", 
			COLUMN 64, pr_gtot_ext_price / count(*) USING "$,$$$,$$$,$$$.##" 

			NEED 10 LINES 
			SKIP 2 line 
			SKIP 5 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 
END REPORT