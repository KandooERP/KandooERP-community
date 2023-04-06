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
GLOBALS "../re/NR1_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_reqperson RECORD LIKE reqperson.* 
	DEFINE pr_reqhead RECORD LIKE reqhead.* 
	DEFINE pr_reqdetl RECORD LIKE reqdetl.* 
	DEFINE pr_country RECORD LIKE country.* 
	DEFINE pr_warehouse RECORD LIKE warehouse.* 
	DEFINE where_text STRING 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module NR1 - Internal Requisitions By Person Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NR1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW N126 with FORM "N126" 
	CALL windecoration_n("N126") -- albo kd-763 

	MENU "Requisitions By Person" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Run Report" " SELECT Criteria AND Print Report" 
			CALL NR1_rpt_query() 

		ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW N126 
END MAIN 


FUNCTION NR1_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE query_text STRING 

 
	MESSAGE" Enter Selection Criteria - ESC TO Continue "	attribute(yellow) 
	CONSTRUCT BY NAME where_text ON reqhead.person_code, 
	name_text, 
	req_num, 
	del_name_text, 
	del_dept_text, 
	del_city_text, 
	del_state_code, 
	del_post_code, 
	del_country_code, 
	total_cost_amt, 
	ref_text, 
	last_del_no, 
	last_del_date, 
	ware_code, 
	stock_ind, 
	status_ind, 
	entry_date, 
	com1_text, 
	com2_text, 
	last_mod_date, 
	last_mod_code 
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

	LET l_rpt_idx = rpt_start(getmoduleid(),"NR1_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT NR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET query_text = "SELECT reqhead.* FROM reqhead, reqperson ", 
	"WHERE reqhead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reqperson.cmpy_code = reqhead.cmpy_code ", 
	"AND reqperson.person_code = reqhead.person_code ", 
	"AND ", where_text clipped," ", 
	"ORDER BY cmpy_code,", 
	"person_code,", 
	"req_num" 
	PREPARE s_reqhead FROM query_text 
	DECLARE c_reqhead CURSOR FOR s_reqhead 

	FOREACH c_reqhead INTO pr_reqhead.*
		#---------------------------------------------------------
		OUTPUT TO REPORT NR1_rpt_list(l_rpt_idx,
		pr_reqhead.*) 
		IF NOT rpt_int_flag_handler2("Requ/Person:",pr_reqhead.req_num, pr_reqhead.person_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT NR1_rpt_list
	CALL rpt_finish("NR1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF	
END FUNCTION 


REPORT NR1_rpt_list(p_rpt_idx,pr_reqhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	i,j, col SMALLINT

	OUTPUT 

	ORDER external BY pr_reqhead.cmpy_code, 
	pr_reqhead.person_code, 
	pr_reqhead.req_num 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 05, "Req", 
			COLUMN 15, "Internal", 
			COLUMN 40, "Date", 
			COLUMN 50, "Last", 
			COLUMN 60, "Requisition", 
			COLUMN 79, "Status" 
			PRINT COLUMN 04, "Number", 
			COLUMN 15, "Reference", 
			COLUMN 48, "Delivery", 
			COLUMN 64, "Amount" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF pr_reqhead.person_code 
			SKIP 1 line 
			NEED 3 LINES 
			SELECT name_text INTO pr_reqperson.name_text FROM reqperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND person_code = pr_reqhead.person_code 
			PRINT COLUMN 02, "Code: ", 
			COLUMN 08, pr_reqhead.person_code, 
			COLUMN 18, pr_reqperson.name_text 
			SKIP 1 line 

		ON EVERY ROW 
			PRINT COLUMN 03, pr_reqhead.req_num USING "###<<<<<", 
			COLUMN 15, pr_reqhead.ref_text, 
			COLUMN 38, pr_reqhead.req_date USING "dd/mm/yy", 
			COLUMN 48, pr_reqhead.last_del_no USING "###<<<<<", 
			COLUMN 57, pr_reqhead.total_cost_amt USING "$$$,$$$,$$$.##", 
			COLUMN 78, pr_reqhead.status_ind 

		AFTER GROUP OF pr_reqhead.person_code 
			PRINT COLUMN 1,"--------------------------------------------", 
			"----------------------------------------" 
			PRINT COLUMN 02, "Reqs: ", 
			COLUMN 08, GROUP count(*) USING "<<<", 
			COLUMN 12, "Avg:", 
			COLUMN 25, GROUP avg(pr_reqhead.total_cost_amt) USING 
			"$$$,$$$,$$$.##", 
			COLUMN 57, GROUP sum(pr_reqhead.total_cost_amt) USING 
			"$$$,$$$,$$$.##" 
			SKIP 1 line 

		ON LAST ROW 
			NEED 15 LINES 
			PRINT COLUMN 02, "Reqs: ", 
			COLUMN 08, count(*) USING "<<<", 
			COLUMN 12, "Avg:", 
			COLUMN 25, avg(pr_reqhead.total_cost_amt) USING 
			"$$$,$$$,$$$.##", 
			COLUMN 57, sum(pr_reqhead.total_cost_amt) USING 
			"$$$,$$$,$$$.##" 
			SKIP 5 LINES 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 				
END REPORT 
