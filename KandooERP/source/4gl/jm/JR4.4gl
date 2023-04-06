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
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/JR_GROUP_GLOBALS.4gl"  
GLOBALS "../jm/JR4_GLOBALS.4gl"

GLOBALS 
	DEFINE 
	formname CHAR(15), 

	pr_menunames RECORD LIKE menunames.*, 
	pr_company RECORD LIKE company.*, 
	pr_jmresource RECORD LIKE jmresource.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	where_part, query_text CHAR(3400), 
	err_message CHAR(40), 

	rpt_pageno LIKE rmsreps.page_num, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_date DATE, 
	pr_output CHAR(60) 
END GLOBALS 

#      JR4 - Resource Report
MAIN 
	#Initial UI Init
	CALL setModuleId("JR4") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 

	SELECT * 
	INTO pr_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
 
	OPEN WINDOW J151 with FORM "J151" -- alch kd-747 
	CALL winDecoration_j("J151") -- alch kd-747
 
	MENU " Resources" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JR4","menu-resources-1") -- alch kd-506 
			CALL rpt_rmsreps_reset(NULL) 
			CALL JR4_rpt_process(JR4_rpt_query()) 
			
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "REPORT" --COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
			CALL rpt_rmsreps_reset(NULL) 
			CALL JR4_rpt_process(JR4_rpt_query()) 
			
		ON ACTION "Print Manager" 	#COMMAND "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			
		ON ACTION "CANCEL" --COMMAND KEY(interrupt, "E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW J151 
END MAIN 

FUNCTION JR4_rpt_query() 
	DEFINE l_where_text STRING
	LET msgresp = kandoomsg("U",1001,"") #1001 Enter criteria FOR selection - ESC TO begin search"

	CONSTRUCT BY NAME l_where_text ON 
	jmresource.res_code, 
	jmresource.desc_text, 
	jmresource.resgrp_code, 
	jmresource.acct_code, 
	jmresource.exp_acct_code, 
	jmresource.unit_code, 
	jmresource.unit_cost_amt, 
	jmresource.unit_bill_amt, 
	jmresource.tax_code, 
	jmresource.tax_amt, 
	jmresource.total_tax_flag 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JR4","const-res_code-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
		RETURN l_where_text
	END IF 

END FUNCTION 

FUNCTION JR4_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"JR4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT JR4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("JR4_rpt_list")].sel_text
	#------------------------------------------------------------
	
	LET query_text = "SELECT * FROM jmresource ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code, "\" AND ", 
	p_where_text clipped, 
	" ORDER BY res_code" 

	PREPARE choice FROM query_text 
	DECLARE res_curs CURSOR FOR choice 

	OPEN res_curs 

 
	WHILE true 
		FETCH res_curs INTO pr_jmresource.* 
		IF status = notfound THEN 
			EXIT WHILE 
		END IF 
		IF int_flag OR quit_flag THEN 
			IF kandoomsg("U",8503,"") = "N" THEN			#8503 Continue Report (Y/N)
				LET msgresp=kandoomsg("U",9501,"")				#9501 Printing was aborted.
				LET int_flag = false 
				LET quit_flag = false 
				EXIT WHILE 
			END IF 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT JR4_rpt_list(l_rpt_idx,
		pr_jmresource.*) 
		IF NOT rpt_int_flag_handler2("Resource:",pr_jmresource.desc_text, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------	

	END WHILE 
	 
	#------------------------------------------------------------
	FINISH REPORT JR4_rpt_list
	CALL rpt_finish("JR4_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT JR4_rpt_list(p_rpt_idx,pr_jmresource) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE pr_jmresource RECORD LIKE jmresource.* , 
	line1, line2 CHAR(80), 
	offset1, offset2 SMALLINT 


	OUTPUT 

	left margin 0 
	ORDER external BY pr_jmresource.res_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Resource", 
			COLUMN 11, "Description", 
			COLUMN 51, "Resource", 
			COLUMN 60, "Recovery/Expense", 
			COLUMN 78, "Tax", 
			COLUMN 82, "Tax Amount", 
			COLUMN 94, "Incl", 
			COLUMN 99, "Unit", 
			COLUMN 107, "Unit Cost", 
			COLUMN 122, "Unit Bill" 

			PRINT COLUMN 1, "Code", 
			COLUMN 52, "Group", 
			COLUMN 60, "Account Codes", 
			COLUMN 78, "Code", 
			COLUMN 108, "Amount", 
			COLUMN 123, "Amount" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			SKIP 1 LINES 

		ON EVERY ROW 

			PRINT COLUMN 1, pr_jmresource.res_code, 
			COLUMN 11, pr_jmresource.desc_text, 
			COLUMN 52, pr_jmresource.resgrp_code, 
			COLUMN 60, pr_jmresource.acct_code, 
			COLUMN 78, pr_jmresource.tax_code, 
			COLUMN 82, pr_jmresource.tax_amt USING "---,---.&&&&", 
			COLUMN 95, pr_jmresource.total_tax_flag, 
			COLUMN 99, pr_jmresource.unit_code, 
			COLUMN 102, pr_jmresource.unit_cost_amt USING "-----,---.&&&&", 
			COLUMN 117, pr_jmresource.unit_bill_amt USING "-----,---.&&&&" 

			PRINT COLUMN 60, pr_jmresource.exp_acct_code 
			SKIP 1 line 

		ON LAST ROW 

			SKIP 1 LINES 
			PRINT COLUMN 1, "Report Totals: ", 
			COLUMN 102, sum(pr_jmresource.unit_cost_amt) 
			USING "-----,---.&&&&", 
			COLUMN 117, sum(pr_jmresource.unit_bill_amt) 
			USING "-----,---.&&&&" 
			SKIP 1 LINES 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
		

END REPORT