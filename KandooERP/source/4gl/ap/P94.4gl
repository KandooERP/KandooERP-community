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
# \brief module P94 Contractor Variations Report
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P9_GROUP_GLOBALS.4gl" 
GLOBALS "../ap/P95_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("P94") 
	CALL ui_init(0) #Initial UI Init

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 
 
	CLEAR screen 

	MENU "Contractor Variations Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P94","menu-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 	#COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
			CALL P94_rpt_query() 
			CLOSE WINDOW P155 
 

		ON ACTION "Print Manager"		#COMMAND "Print" "Print OR view using RMS"
			CALL run_prog("URS","","","","") 


		ON ACTION "CANCEL"			#COMMAND "Exit" " Exit TO menus"
			EXIT MENU

	END MENU 
	CLEAR screen 
END MAIN 


############################################################
# FUNCTION P94_rpt_query()
#
#
############################################################
FUNCTION P94_rpt_query()
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
 	DEFINE l_rec_contractor RECORD LIKE contractor.* 

	CLEAR screen 
	OPEN WINDOW P155 with FORM "P155" 
	CALL windecoration_p("P155") 


	MESSAGE " Enter criteria FOR selection - ESC TO begin search" 

	CONSTRUCT BY NAME l_where_text ON 
		contractor.vend_code, 
		contractor.pager_comp_text, 
		contractor.licence_text, 
		contractor.tax_no_text, 
		contractor.variation_text, 
		contractor.tax_rate_qty, 
		contractor.var_exp_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P94","construct-contractor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	END IF 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (l_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"P94_rpt_list",l_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT P94_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET l_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("P94_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT * ", 
	"FROM ", 
	"contractor WHERE contractor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	l_where_text clipped, 
	" ORDER BY contractor.var_exp_date" 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

	OPEN selcurs 

	CLEAR screen 

	WHILE true 
		FETCH selcurs INTO l_rec_contractor.* 
		IF status = NOTFOUND THEN 
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT P94_rpt_list(l_rpt_idx,
		l_rec_contractor.*)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_contractor.vend_code , NULL,l_rpt_idx) THEN
			EXIT WHILE 
		END IF 
		#---------------------------------------------------------			

	END WHILE 


	#------------------------------------------------------------
	FINISH REPORT P94_rpt_list
	CALL rpt_finish("P94_rpt_list")
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
# REPORT P94_rpt_list(p_contractor)
#
#
############################################################
REPORT P94_rpt_list(p_rpt_idx,p_contractor) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_contractor RECORD LIKE contractor.* 
	DEFINE l_temp_name_text LIKE vendor.name_text 
	DEFINE l_report_total DECIMAL(10,2)
	
	OUTPUT 

	ORDER external BY p_contractor.vend_code 

	FORMAT 

		FIRST PAGE HEADER
			
		PAGE HEADER 

			IF pageno = 1 THEN 
				LET l_report_total = 0 
			END IF 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 1, "Vendor", 
			COLUMN 10, "Vendor", 
			COLUMN 50, "Tax", 
			COLUMN 61, "Variation", 
			COLUMN 77, "Variation" 

			PRINT COLUMN 1 , "Code", 
			COLUMN 10, "Name", 
			COLUMN 50, "Rate", 
			COLUMN 61, "Number", 
			COLUMN 77,"Exp. Date" 

			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------" 
		ON EVERY ROW 
			SELECT name_text 
			INTO l_temp_name_text 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_contractor.vend_code 

			PRINT COLUMN 1, p_contractor.vend_code , 
			COLUMN 10, l_temp_name_text, 
			COLUMN 50, p_contractor.tax_rate_qty USING "#&.&&", 
			COLUMN 61, p_contractor.variation_text, 
			COLUMN 77, p_contractor.var_exp_date USING "dd/mm/yy" 

		ON LAST ROW 
			PRINT 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			

END REPORT 