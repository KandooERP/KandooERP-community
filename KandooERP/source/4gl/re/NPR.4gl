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
GLOBALS "../re/NP_GROUP_GLOBALS.4gl"
GLOBALS "../re/NPR_GLOBALS.4gl"  
GLOBALS 
	DEFINE pr_reqperson RECORD LIKE reqperson.* 
	DEFINE pr_country RECORD LIKE country.* 
	DEFINE rpt_note LIKE rmsreps.report_text 
	DEFINE where_text STRING 
	DEFINE query_text STRING 
 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
############################################################
# MAIN
#
# \brief module NPR - Internal Requisition Person Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("NPR") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_n_re() #init n/re module 

	OPEN WINDOW n102 with FORM "N102" 
	CALL windecoration_n("N102") -- albo kd-763 

	MENU " Requisition Persons" 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " SELECT Criteria AND Print Report" 
			CALL NPR_rpt_query() 

		ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO the menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW N102 
END MAIN 


FUNCTION NPR_rpt_query() 
	DEFINE l_rpt_idx SMALLINT  #report array index

	LET msgresp=kandoomsg("U",1001,"")	#1001 Enter Selection Criteria - OK TO Continue "
	CONSTRUCT BY NAME where_text ON person_code, 
	name_text, 
	ware_code, 
	dept_text, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
	ware_oride_flag, 
	loadfile_text, 
	po_low_limit_amt, 
	po_up_limit_amt, 
	po_start_date, 
	po_exp_date, 
	stock_limit_amt, 
	sl_start_date, 
	sl_exp_date, 
	dr_limit_amt, 
	dr_start_date, 
	dr_exp_date 

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

	LET l_rpt_idx = rpt_start(getmoduleid(),"NPR_rpt_list",where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT NPR_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET query_text = "SELECT * FROM reqperson ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_text clipped," ", 
	"ORDER BY person_code" 
	PREPARE s_reqperson FROM query_text 
	DECLARE c_reqperson CURSOR FOR s_reqperson 

	FOREACH c_reqperson INTO pr_reqperson.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT NPR_rpt_list(l_rpt_idx,
		pr_reqperson.*) 

		IF NOT rpt_int_flag_handler2("Person:",pr_reqperson.person_code, pr_reqperson.name_text,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT NPR_rpt_list
	CALL rpt_finish("NPR_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


REPORT NPR_rpt_list(p_rpt_idx,pr_reqperson)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	pr_reqperson RECORD LIKE reqperson.*, 
	pa_address array[7] OF CHAR(40), 
	i,j, col SMALLINT
	
	OUTPUT 
 
	ORDER external BY pr_reqperson.person_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 1, "Person", 
			COLUMN 10, "Name", 
			COLUMN 51, "Ware", 
			COLUMN 62, "Loadfile Name", 
			COLUMN 82, "---------- Limits -----------", 
			COLUMN 112, "------- Dates -------" 
			PRINT COLUMN 2, "Code", 
			COLUMN 10, "Address", 
			COLUMN 51, "Code Oride", 
			COLUMN 114, "Start", 
			COLUMN 125,"Expiry" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			LET pa_address[1] = pr_reqperson.name_text 
			LET pa_address[2] = pr_reqperson.dept_text 
			LET pa_address[3] = pr_reqperson.addr1_text 
			LET pa_address[4] = pr_reqperson.addr2_text 
			LET pa_address[5] = pr_reqperson.addr3_text 
			LET pa_address[6] = pr_reqperson.city_text," ", 
			pr_reqperson.state_code," ", 
			pr_reqperson.post_code 

			SELECT country_text INTO pa_address[7] FROM country 
			WHERE country_code = pr_reqperson.country_code 
			FOR i = 1 TO 6 
				LET j = i 
				WHILE pa_address[i] IS NULL 
					LET j = j + 1 
					LET pa_address[i] = pa_address[j] 
					LET pa_address[j] = NULL 
					IF j = 7 THEN 
						EXIT FOR 
					END IF 
				END WHILE 
			END FOR
			 
			NEED 5 LINES 
			PRINT COLUMN 1, pr_reqperson.person_code, 
			COLUMN 10, pa_address[1], 
			COLUMN 51, pr_reqperson.ware_code, 
			COLUMN 58, pr_reqperson.ware_oride_flag, 
			COLUMN 61, pr_reqperson.loadfile_text, 
			COLUMN 82, "Stocked Items:", 
			COLUMN 97, pr_reqperson.stock_limit_amt USING "###,###,##&.&&", 
			COLUMN 112, pr_reqperson.sl_start_date USING "dd/mm/yyyy", 
			COLUMN 123, pr_reqperson.sl_exp_date USING "dd/mm/yyyy" 
			PRINT COLUMN 10, pa_address[2], 
			COLUMN 82, "Direct Receipt:", 
			COLUMN 97, pr_reqperson.dr_limit_amt USING "###,###,##&.&&", 
			COLUMN 112, pr_reqperson.dr_start_date USING "dd/mm/yyyy", 
			COLUMN 123, pr_reqperson.dr_exp_date USING "dd/mm/yyyy" 
			PRINT COLUMN 10, pa_address[3], 
			COLUMN 82, "PO Auth Lower:", 
			COLUMN 97, pr_reqperson.po_low_limit_amt USING "###,###,##&.&&", 
			COLUMN 112, pr_reqperson.po_start_date USING "dd/mm/yyyy", 
			COLUMN 123, pr_reqperson.po_exp_date USING "dd/mm/yyyy" 
			PRINT COLUMN 10, pa_address[4], 
			COLUMN 82, "PO Auth Upper:", 
			COLUMN 97, pr_reqperson.po_up_limit_amt USING "###,###,##&.&&" 
			LET i = 5 

			WHILE pa_address[i] IS NOT NULL 
				PRINT COLUMN 10, pa_address[i] 
				LET i = i + 1 
				IF i = 7 THEN 
					EXIT WHILE 
				END IF 
			END WHILE 
			SKIP 1 line 

		ON LAST ROW 
			NEED 11 LINES 
			SKIP 3 LINES

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4]
 							 
END REPORT 
