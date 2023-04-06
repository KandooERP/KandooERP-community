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
# \brief module P93 Contractor Details Report

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P93_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
GLOBALS 
	#DEFINE glob_level CHAR(1)
	#DEFINE glob_msg, glob_prog CHAR(40)
	DEFINE glob_query_text STRING -- CHAR (1900) 
	DEFINE glob_where_part STRING-- (1900) 
	#	DEFINE glob_prs_name CHAR(7)
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("P93") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 


	#   SELECT *
	#   INTO glob_rec_company.*
	#   FROM company
	#   WHERE cmpy_code = glob_rec_kandoouser.cmpy_code

	CALL rpt_rmsreps_set_page_size(132,NULL) 
 
	CLEAR screen 

	#CALL fgl_winmessage("needs some kind of window/form","needs some kind of form/window","info")
	#CALL displaymoduletitle(NULL)  --first form of the module get's the title

	MENU "Contractor Details Report" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","P93","menu-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 
			#COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
			CALL P93_rpt_query() 
			CLOSE WINDOW P155 
			NEXT option "Print Manager" 

		ON ACTION "Print Manager" 
			#COMMAND "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 
			NEXT option "Exit" 

		ON ACTION "CANCEL" 
			#COMMAND "Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 

	CLEAR screen 
END MAIN 


############################################################
# FUNCTION P93_rpt_query()
#
#
############################################################
FUNCTION P93_rpt_query() 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_exist SMALLINT 
	DEFINE l_rec_contractor RECORD LIKE contractor.* 

	CLEAR screen 
	OPEN WINDOW P155 with FORM "P155" 
	CALL windecoration_p("P155") 


	MESSAGE " Enter criteria FOR selection - ESC TO begin search" 

	CONSTRUCT BY NAME glob_where_part ON 
		contractor.vend_code, 
		contractor.pager_comp_text, 
		contractor.licence_text, 
		contractor.tax_no_text, 
		contractor.variation_text, 
		contractor.tax_rate_qty, 
		contractor.var_exp_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P93","construct-contractor-1") 

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

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"P93_rpt_list",glob_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P93_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET glob_where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AP93_rpt_list")].sel_text
	#------------------------------------------------------------


	LET glob_query_text = 
	"SELECT * ", 
	"FROM ", 
	"contractor WHERE contractor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_where_part clipped, 
	" ORDER BY contractor.vend_code" 


	PREPARE choice FROM glob_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

	CLEAR screen 

	WHILE true 
		FETCH selcurs INTO l_rec_contractor.* 
		IF status = NOTFOUND THEN 
			EXIT WHILE 
		END IF 
		
		OUTPUT TO REPORT P93_rpt_list(l_rpt_idx,
		l_rec_contractor.*)  

		IF NOT rpt_int_flag_handler2("Vendor:", l_rec_contractor.vend_code, NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 

		#---------------------------------------------------------	
		
	END WHILE 


	#------------------------------------------------------------
	FINISH REPORT P93_rpt_list
	CALL rpt_finish("P93_rpt_list")
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
# REPORT P93_rpt_list(p_rec_contractor)
#
#
############################################################
REPORT P93_rpt_list(p_rpt_idx,p_rec_contractor) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_contractor RECORD LIKE contractor.* 
	DEFINE l_report_total DECIMAL(10,2) 

	OUTPUT 

	ORDER external BY p_rec_contractor.vend_code 

	FORMAT 

		PAGE HEADER 

			IF pageno = 1 THEN 
				LET l_report_total = 0 
			END IF 
			 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Vendor", 
			COLUMN 10, "Home", 
			COLUMN 23, "Pager", 
			COLUMN 39, "Pager", 
			COLUMN 52, "Start", 
			COLUMN 61, "Licence", 
			COLUMN 74, "Lic. Exp", 
			COLUMN 83, "Tax", 
			COLUMN 94, "Tax", 
			COLUMN 100, "Variation", 
			COLUMN 111, "Variation" 

			PRINT COLUMN 1 , "Code", 
			COLUMN 10, "Phone", 
			COLUMN 23, "Company", 
			COLUMN 39, "Number", 
			COLUMN 52, "Date", 
			COLUMN 61, "Number", 
			COLUMN 74, "Date", 
			COLUMN 83, "Number", 
			COLUMN 94, "Rate", 
			COLUMN 100, "Number", 
			COLUMN 111,"Exp. Date" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------" 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_contractor.vend_code , 
			COLUMN 10, p_rec_contractor.home_phone_text, 
			COLUMN 23, p_rec_contractor.pager_comp_text, 
			COLUMN 39, p_rec_contractor.pager_num_text, 
			COLUMN 52, p_rec_contractor.start_date USING "dd/mm/yy", 
			COLUMN 61, p_rec_contractor.licence_text, 
			COLUMN 74, p_rec_contractor.expiry_date USING "dd/mm/yy", 
			COLUMN 83, p_rec_contractor.tax_no_text, 
			COLUMN 94, p_rec_contractor.tax_rate_qty USING "#&.&&", 
			COLUMN 100, p_rec_contractor.variation_text, 
			COLUMN 111, p_rec_contractor.var_exp_date USING "dd/mm/yy" 

		ON LAST ROW 
			PRINT 
			PRINT COLUMN 50, "**** END OF REPORT P93 ****" 

END REPORT 
