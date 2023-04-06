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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"

###########################################################################
# FUNCTION PA3_main()
#
# Vendor Note Report
###########################################################################
FUNCTION PA3_main() 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("PA3") 	#Initial UI Init 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 			
			OPEN WINDOW P110 with FORM "P110" 
			CALL windecoration_p("P110") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " Note Report" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PA3","menu-note-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PA3_rpt_process(PA3_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"			#COMMAND "Report" " Selection Criteria AND Print Report"
					CALL rpt_rmsreps_reset(NULL)
					CALL PA3_rpt_process(PA3_rpt_query()) 
		 
				ON ACTION "Print Manager" 			#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS", "", "", "", "") 
		
				ON ACTION "CANCEL" 			#COMMAND KEY(interrupt, "E") "Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P110 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PA3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P110 with FORM "P110" 
			CALL windecoration_p("P110") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PA3_rpt_query()) #save where clause in env 
			CLOSE WINDOW P110 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PA3_rpt_process(get_url_sel_text())
	END CASE

END FUNCTION
###########################################################################
# END FUNCTION PA3_main()
###########################################################################


############################################################
# FUNCTION PA3_rpt_query()
#
#
############################################################
FUNCTION PA3_rpt_query() 
	DEFINE l_where_text STRING 
	
	MESSAGE kandoomsg2("U", 1001, "") 
	CONSTRUCT BY NAME l_where_text	ON 
		vendornote.vend_code, 
		vendor.name_text, 
		vendornote.note_date, 
		vendornote.note_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PA3","construct-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		ERROR "Report Generation was aborted" 
		RETURN NULL
	ELSE
		RETURN l_where_text
	END IF
END FUNCTION 
############################################################
# END FUNCTION PA3_rpt_query()
############################################################


############################################################
# FUNCTION PA3_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PA3_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_vendornote RECORD 
		vend_code LIKE vendornote.vend_code, 
		name_text LIKE vendor.name_text, 
		note_date LIKE vendornote.note_date, 
		#note_num           LIKE vendornote.note_num, #HuHo dropped by Eric 18.09.2019
		note_text LIKE vendornote.note_text 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PA3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PA3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------


	IF glob_rec_apparms.report_ord_flag = "C" THEN 
		LET l_query_text = "SELECT vendornote.vend_code, vendor.name_text, ", 
		"vendornote.note_date, ", #vendornote.note_num, 
		"vendornote.note_text ", 
		"FROM vendornote, vendor ", 
		"WHERE vendor.vend_code = vendornote.vend_code AND ", 
		"vendornote.cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		"vendor.cmpy_code = vendornote.cmpy_code AND ", 
		p_where_text clipped, 
		" ORDER BY vendornote.vend_code, vendornote.note_date " 
		#"vendornote.note_num"
	ELSE 
		LET l_query_text = "SELECT vendornote.vend_code, vendor.name_text, ", 
		"vendornote.note_date, ", #vendornote.note_num, 
		"vendornote.note_text ", 
		"FROM vendornote, vendor ", 
		"WHERE vendor.vend_code = vendornote.vend_code AND ", 
		"vendornote.cmpy_code = \"", 
		glob_rec_kandoouser.cmpy_code, 
		"\" AND ", 
		"vendor.cmpy_code = vendornote.cmpy_code AND ", 
		p_where_text clipped, 
		" ORDER BY vendor.name_text, vendornote.vend_code, ", 
		" vendornote.note_date " 
		#" vendornote.note_num"
	END IF 
	
	PREPARE choice 
	FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_vendornote.* 

		#---------------------------------------------------------
		OUTPUT TO REPORT PA3_rpt_list(l_rpt_idx,
		l_rec_vendornote.*)
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendornote.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PA3_rpt_list
	CALL rpt_finish("PA3_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 

END FUNCTION 
############################################################
# END FUNCTION PA3_rpt_process(p_where_text)
############################################################


############################################################
# REPORT PA3_rpt_list(p_rpt_idx,p_rec_vendornote)
#
#
############################################################
REPORT PA3_rpt_list(p_rpt_idx,p_rec_vendornote)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_vendornote	RECORD 
		vend_code LIKE vendornote.vend_code, 
		name_text LIKE vendor.name_text, 
		note_date LIKE vendornote.note_date, 
		#note_num           LIKE vendornote.note_num, #HuHo dropped by Eric 18.09.2019
		note_text LIKE vendornote.note_text 
	END RECORD 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 10,		p_rec_vendornote.note_text 
			 
		BEFORE GROUP OF p_rec_vendornote.vend_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 5, 
			"Vendor : ", 
			p_rec_vendornote.vend_code clipped, 
			2 spaces, 
			p_rec_vendornote.name_text 
			SKIP 2 LINES 

		BEFORE GROUP OF p_rec_vendornote.note_date 
			PRINT COLUMN 5, 
			"Date : ", 
			p_rec_vendornote.note_date 
			SKIP 1 line 

		AFTER GROUP OF p_rec_vendornote.note_date 
			SKIP 2 LINES 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, 
			"Total Items: ", 
			count(*) USING "###" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PA3_rpt_list(p_rpt_idx,p_rec_vendornote)
############################################################