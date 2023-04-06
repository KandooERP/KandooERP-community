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
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N4R_GLOBALS.4gl"  

GLOBALS 
	DEFINE where_text STRING 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module N4R - Internal Requisition Pending Purchase Order Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("N4R") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 


	OPEN WINDOW N118 with FORM "N118" 
	CALL windecoration_n("N118") -- albo kd-763 

	MENU "Pending Purchase Orders" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL N4R_rpt_query() 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW N118 
END MAIN 


FUNCTION N4R_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE pr_penddetl RECORD LIKE penddetl.* 
	DEFINE pr_auth_ind CHAR(1) 
	DEFINE query_text CHAR(600) 


	CLEAR FORM 
	
	MESSAGE" Enter Selection Criteria - ESC TO Continue " 	attribute(yellow) 
	LET pr_auth_ind = NULL 
	
	INPUT BY NAME pr_auth_ind WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	CONSTRUCT BY NAME where_text ON pendhead.vend_code, 
	pendhead.pend_num, 
	penddetl.req_num, 
	pendhead.ware_code, 
	penddetl.part_code, 
	pendhead.order_date, 
	pendhead.year_num, 
	pendhead.period_num 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		MESSAGE " Searching database - please wait " 
		attribute(yellow) 
		CASE pr_auth_ind 
			WHEN "1" 
				LET where_text = where_text clipped, 
				" AND pendhead.auth_code IS NOT NULL " 
			WHEN "2" 
				LET where_text = where_text clipped, 
				" AND pendhead.auth_code IS NULL " 
		END CASE 
	END IF 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"N4R_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT N4R_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	LET query_text = "SELECT penddetl.* ", 
	"FROM penddetl,", 
	"pendhead ", 
	"WHERE pendhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND pendhead.cmpy_code = penddetl.cmpy_code ", 
	"AND pendhead.pend_num = penddetl.pend_num ", 
	"AND ",where_text clipped," ", 
	"ORDER BY penddetl.cmpy_code,", 
	"penddetl.pend_num,", 
	"penddetl.line_num" 
	PREPARE s_penddetl FROM query_text 
	DECLARE c_penddetl CURSOR FOR s_penddetl 

	FOREACH c_penddetl INTO pr_penddetl.* 
	
		#---------------------------------------------------------
		OUTPUT TO REPORT N4R_rpt_list(l_rpt_idx,
		pr_penddetl.*)
		IF NOT rpt_int_flag_handler2("Pending PO:",pr_penddetl.pend_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
		 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT N4R_rpt_list
	CALL rpt_finish("N4R_rpt_list")
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
# 
###########################################################################

###########################################################################
# REPORT N4R_rpt_list(pr_penddetl) 
#
#
###########################################################################
REPORT N4R_rpt_list(p_rpt_idx,pr_penddetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_pendhead RECORD LIKE pendhead.*, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_person_code LIKE reqhead.person_code, 
	pr_order_tot_amt LIKE reqhead.total_cost_amt, 
	pr_report_tot_amt LIKE reqhead.total_cost_amt, 
	cnt, i,j, col SMALLINT 
--	line1 CHAR(80) 
--	line2 CHAR(80) 

	OUTPUT 

	ORDER external BY pr_penddetl.cmpy_code, 
	pr_penddetl.pend_num, 
	pr_penddetl.line_num 
	FORMAT 
		PAGE HEADER
		 
			IF pageno = 1 THEN 
				LET pr_order_tot_amt = 0 
				LET pr_report_tot_amt = 0 
				LET cnt = 0 
			END IF

			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 17, "Req.", 
			COLUMN 24, "Line", 
			COLUMN 29, "Person", 
			COLUMN 38, "Product Code", 
			COLUMN 56, "Account Code", 
			COLUMN 78, "Quantity UOM", 
			COLUMN 96, "Unit Cost", 
			COLUMN 110, "Unit Tax", 
			COLUMN 122, "Total Cost" 
			PRINT COLUMN 16, "Number", 
			COLUMN 25, "No.", 
			COLUMN 30, "Code", 
			COLUMN 40, "Description", 
			COLUMN 97, "Amount", 
			COLUMN 111,"Amount", 
			COLUMN 124,"Amount" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_penddetl.pend_num 
			NEED 5 LINES 
			SELECT pendhead.* 
			INTO pr_pendhead.* 
			FROM pendhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pend_num = pr_penddetl.pend_num 
			SELECT vendor.* 
			INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_pendhead.vend_code 
			PRINT COLUMN 1, "Order No.", 
			COLUMN 11, pr_penddetl.pend_num USING "<<<<<<<<", 
			COLUMN 20, "Vendor: ", 
			COLUMN 28, pr_vendor.vend_code, 
			COLUMN 36, pr_vendor.name_text; 
			IF pr_pendhead.po_num IS NOT NULL 
			AND pr_pendhead.po_num > 0 THEN 
				PRINT COLUMN 66,"** Authorised **" 
			END IF 
			SKIP 1 line 

		ON EVERY ROW 
			NEED 2 LINES 
			SELECT person_code 
			INTO pr_person_code 
			FROM reqhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_penddetl.req_num 
			SELECT reqdetl.* 
			INTO pr_reqdetl.* 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_penddetl.req_num 
			AND line_num = pr_penddetl.req_line_num 
			LET pr_order_tot_amt = pr_order_tot_amt + (pr_penddetl.po_qty 
			* (pr_reqdetl.unit_tax_amt + pr_reqdetl.unit_cost_amt)) 
			PRINT COLUMN 14, pr_penddetl.req_num USING "###<<<<<", 
			COLUMN 24, pr_penddetl.req_line_num USING "#<<", 
			COLUMN 29, pr_person_code, 
			COLUMN 38, pr_penddetl.part_code, 
			COLUMN 56, pr_penddetl.acct_code, 
			COLUMN 74, pr_penddetl.po_qty USING "##,###,###.##", 
			COLUMN 88, pr_reqdetl.uom_code, 
			COLUMN 92, pr_reqdetl.unit_cost_amt USING "$$,$$$,$$$.##", 
			COLUMN 105,pr_reqdetl.unit_tax_amt USING "$$,$$$,$$$.##", 
			COLUMN 118,(pr_penddetl.po_qty *(pr_reqdetl.unit_tax_amt + 
			pr_reqdetl.unit_cost_amt)) 
			USING "$$$,$$$,$$$.##" 
			PRINT COLUMN 38, pr_reqdetl.desc_text 

		AFTER GROUP OF pr_penddetl.pend_num 
			LET cnt = cnt + 1 
			PRINT COLUMN 106, "--------------------------" 
			PRINT COLUMN 106, "Order Total:", 
			COLUMN 118, pr_order_tot_amt USING "$$$,$$$,$$$.##" 
			SKIP 2 line 
			LET pr_report_tot_amt = pr_report_tot_amt + pr_order_tot_amt 
			LET pr_order_tot_amt = 0 

		ON LAST ROW 
			IF pr_report_tot_amt = 0 THEN 
				PRINT COLUMN 40, 
				"** No Pending Purchase Orders Selected FOR Printing **" 
			ELSE 
				NEED 15 LINES 
				PRINT COLUMN 1,"--------------------------------------------", 
				"--------------------------------------------", 
				"--------------------------------------------" 
				PRINT COLUMN 2, "Report Statistics:" 
				PRINT COLUMN 30, "No.of Orders: ",cnt USING "<<<<<<", 
				COLUMN 55, "Average Order:", 
				COLUMN 69, (pr_report_tot_amt/cnt) USING "$$,$$$,$$$.##", 
				COLUMN 105,"Total Orders:", 
				COLUMN 118, pr_report_tot_amt USING "$$$,$$$,$$$.##" 
				SKIP 5 LINES 
			END IF 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
 
			LET pr_order_tot_amt = 0 
			LET pr_report_tot_amt = 0 
			LET cnt = 0 

END REPORT