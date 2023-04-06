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
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 

	DEFINE formname CHAR(15), 
	run_total_amt DECIMAL(16,2), 
	answer CHAR(1), 
	idx SMALLINT, 
	pr_output CHAR(60), 
	where_text CHAR(500), 
	pr_lines RECORD 
		line1_text CHAR(132), 
		line2_text CHAR(132), 
		line3_text CHAR(132), 
		line4_text CHAR(132), 
		line5_text CHAR(132), 
		line6_text CHAR(132), 
		line7_text CHAR(132), 
		line8_text CHAR(132), 
		line9_text CHAR(132), 
		line10_text CHAR(132) 
	END RECORD, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_company RECORD LIKE company.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	pr_tentinvhead RECORD LIKE tentinvhead.*, 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_desc_text LIKE contracthead.desc_text, 
	rpt_pageno LIKE rmsreps.page_num 
END GLOBALS 
############################################################
# MAIN
#
# JA8 Contract Tentative Invoice Reporting
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("JA8") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	SELECT * INTO pr_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW JA11 with FORM "JA11" -- alch kd-747 
	CALL winDecoration_j("JA11") -- alch kd-747 

	MENU "Tentative Invoicing" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JA8","menu-tentative_invoicing-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			IF get_query() THEN 
				NEXT option "Print Manager" 
			END IF 

		ON ACTION "Print Manager"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW JA11 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION get_query()
#
# 
############################################################
FUNCTION get_query() 
	DEFINE cnt SMALLINT 
	DEFINE query_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	CLEAR FORM 
	LET msgresp = kandoomsg("A", 1001, "") 
	# MESSAGE "Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON 
	tentinvhead.inv_num, 
	tentinvhead.contract_code, 
	desc_text, 
	tentinvhead.total_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JA8","const-inv_num-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"JA8_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JA8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JA8_rpt_list")].sel_text
	#------------------------------------------------------------

	LET query_text = "SELECT tentinvhead.*, contracthead.* ", 
	"FROM tentinvhead, contracthead ", 
	"WHERE contracthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND contracthead.cmpy_code = tentinvhead.cmpy_code ", 
	"AND tentinvhead.contract_code = ", 
	"contracthead.contract_code ", 
	"AND ", where_text clipped, " ", 
	"ORDER BY contracthead.contract_code, ", 
	"tentinvhead.inv_num" 

	LET msgresp = kandoomsg("A",1002,"") # MESSAGE "Searching database - please wait"


	PREPARE s_tentinvhead FROM query_text 
	DECLARE c_tentinvhead CURSOR FOR s_tentinvhead 

	LET idx = 0 

	FOREACH c_tentinvhead INTO pr_tentinvhead.*, pr_contracthead.* 

		DECLARE c_tentinvdetl CURSOR with HOLD FOR 
		SELECT * 
		FROM tentinvdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = pr_tentinvhead.inv_num 
		ORDER BY line_num 

		FOREACH c_tentinvdetl INTO pr_tentinvdetl.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT JA8_rpt_list(l_rpt_idx,
			pr_tentinvhead.*,	pr_contracthead.*, pr_tentinvdetl.*) 
			IF NOT rpt_int_flag_handler2("Customer:",pr_tentinvdetl.cust_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
			LET idx = idx + 1 

		END FOREACH 

	END FOREACH 

	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U", 1021, "") 		#"No tentative invoices were selected - Re SELECT"
		RETURN false 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT JA8_rpt_list
	CALL rpt_finish("JA8_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION get_query()
############################################################


############################################################
# REPORT JA8_rpt_list(rr_tentinvhead,	rr_contracthead, rr_tentinvdetl)
#
# 
############################################################
REPORT JA8_rpt_list(p_rpt_idx,rr_tentinvhead,	rr_contracthead, rr_tentinvdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE rr_tentinvdetl RECORD LIKE tentinvdetl.*, 
	rr_tentinvhead RECORD LIKE tentinvhead.*, 
	rr_contracthead RECORD LIKE contracthead.*, 
	rr_contractdate RECORD LIKE contractdate.*, 
	rr_customer RECORD LIKE customer.*, 
	pa_line array[4] OF CHAR(132), 
	rpt_line1 CHAR(132), 
	rpt_line2 CHAR(132), 
	rpt_line3 CHAR(132), 
	rpt_offset SMALLINT, 
	pr_selection_text CHAR(50), 
	pr_eof_text CHAR(50), 
	pr_data_text CHAR(132), 
	rr_temp_text CHAR(20), 
	rr_type_ind_code CHAR(15), 
	rr_ref_desc_text CHAR(30), 
	rv_maxvar CHAR(16), 
	rv_invoice_total_amt, 
	rr_ext_price DECIMAL(16,2), 
	rr_temp_date LIKE contractdate.invoice_date, 
	rr_remaining DECIMAL(16,2) 

	OUTPUT 

	ORDER external BY rr_contracthead.contract_code, 
	rr_tentinvhead.contract_code, 
	rr_tentinvhead.inv_num 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  


		BEFORE GROUP OF rr_contracthead.contract_code # FIRST GROUP 

			NEED 9 LINES 

			SELECT sum(invoice_total_amt) 
			INTO rv_invoice_total_amt 
			FROM contractdate 
			WHERE contractdate.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contractdate.contract_code = 
			rr_contracthead.contract_code 

			IF rv_invoice_total_amt IS NULL THEN 
				LET rv_invoice_total_amt = 0 
			END IF 

			SELECT * 
			INTO rr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = rr_contracthead.cust_code 

			SKIP 1 line 

			PRINT COLUMN 1, "Contract Code :", 
			COLUMN 24, rr_contracthead.contract_code, 
			COLUMN 45, rr_contracthead.desc_text, 
			COLUMN 86, "Billed TO Date :", 
			COLUMN 103, rv_invoice_total_amt 

			LET rr_remaining = rr_contracthead.contract_value_amt 
			- rv_invoice_total_amt 

			PRINT COLUMN 1, "Customer Code :", 
			COLUMN 24, rr_contracthead.cust_code, 
			COLUMN 45, rr_customer.name_text, 
			COLUMN 86, "Remaining :", 
			COLUMN 103, rr_remaining 

			SELECT jmparms.cntrhd_prmpt_text 
			INTO rr_temp_text 
			FROM jmparms 
			WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND jmparms.key_code = "1" 

			SELECT ref_desc_text 
			INTO rr_ref_desc_text 
			FROM userref 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND source_ind = "J" 
			AND ref_ind = "A" 
			AND ref_code = rr_contracthead.user1_text 

			SELECT last_billed_date 
			INTO rr_temp_date 
			FROM contracthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND contract_code = rr_contracthead.contract_code 

			PRINT COLUMN 1, rr_temp_text; 

			IF rr_temp_text IS NOT NULL THEN 
				PRINT COLUMN 22, ":"; 
			END IF 

			PRINT COLUMN 24, rr_contracthead.user1_text, 
			COLUMN 45, rr_ref_desc_text, 
			COLUMN 86, "Last Billed :"; 

			IF rr_temp_date IS NULL THEN 
				PRINT COLUMN 103, "Never" 
			ELSE 
				PRINT COLUMN 103, rr_temp_date 
			END IF 

			SKIP 1 line 
			PRINT pr_lines.line1_text clipped 
			PRINT pr_lines.line2_text clipped 
			PRINT pr_lines.line1_text clipped 
			SKIP 1 line 

			LET run_total_amt = 0 

		ON EVERY ROW 

			NEED 3 LINES 

			IF rr_tentinvhead.inv_ind = "3" THEN 
				LET rr_type_ind_code = rr_tentinvdetl.activity_code 
			ELSE 
				LET rr_type_ind_code = rr_tentinvdetl.part_code 
			END IF 

			LET rr_ext_price = rr_tentinvdetl.unit_sale_amt * 
			rr_tentinvdetl.ship_qty 

			PRINT COLUMN 1, rr_tentinvhead.inv_num USING "#######", 
			COLUMN 10, rr_type_ind_code, 
			COLUMN 26, rr_tentinvdetl.line_text, 
			COLUMN 70, rr_tentinvdetl.ship_qty, 
			COLUMN 84, rr_tentinvdetl.unit_sale_amt, 
			COLUMN 103, rr_ext_price 
			LET run_total_amt = run_total_amt + rr_ext_price 
			
		AFTER GROUP OF rr_tentinvhead.contract_code # FIRST GROUP 
			NEED 3 LINES 
			PRINT COLUMN 104, "-----------------" 
			PRINT COLUMN 88, "Invoice Total :", 
			COLUMN 102, run_total_amt 
			PRINT COLUMN 104, "=================" 
			SKIP 2 LINES 
			
		ON LAST ROW 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				NEED 4 LINES 
			ELSE 
				NEED 2 LINES 
			END IF 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
############################################################
# END REPORT JA8_rpt_list(rr_tentinvhead,	rr_contracthead, rr_tentinvdetl)
#
# 
############################################################