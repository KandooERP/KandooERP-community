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
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GR3_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_where_part CHAR(800) 
	
############################################################
# FUNCTION GR3_main()
#
# GR3  Valid Segments Report
############################################################
FUNCTION GR3_main() 
	DEFER quit 
	DEFER interrupt

	CALL setModuleId("GR3") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

		OPEN WINDOW G128 with FORM "G128" 
		CALL windecoration_g("G128") 
	
		MENU " Segments" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","GR3","menu-segments") 
				CALL GR3_rpt_process(GR3_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "Report" 			#COMMAND "Run" " Enter selection criteria AND generate REPORT"
				CALL GR3_rpt_process(GR3_rpt_query())
				CALL rpt_rmsreps_reset(NULL)
	
			ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
	
			ON ACTION "Exit" 	#COMMAND KEY (interrupt,"E")"Exit" " Exit TO Menus"
				EXIT MENU 
	
		END MENU 
	
		CLOSE WINDOW G128 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GR3_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G128 with FORM "G128" 
			CALL windecoration_g("G128") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GR3_rpt_query()) #save where clause in env 
			CLOSE WINDOW G128 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GR3_rpt_process(get_url_sel_text())
	END CASE 			
END FUNCTION 

############################################################
# FUNCTION GR3_rpt_query()
#
#
############################################################
FUNCTION GR3_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_validflex RECORD LIKE validflex.* 

	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT l_where_text ON start_num, 
	flex_code, 
	desc_text, 
	group_code 
	FROM start_num, 
	flex_code, 
	validflex.desc_text, 
	group_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GR3","construct-flex") 

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

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Query aborted"
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF
END FUNCTION


############################################################
# FUNCTION GR3_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GR3_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING  
	DEFINE l_rec_validflex RECORD LIKE validflex.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GR3_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GR3_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR3_rpt_list")].sel_text
	#------------------------------------------------------------

 
	LET l_query_text = "SELECT * ", 
	"FROM validflex ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR3_rpt_list")].sel_text clipped, " ", 
	"ORDER BY start_num,flex_code " 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 
	
	FOREACH selcurs INTO l_rec_validflex.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GR3_rpt_list(l_rpt_idx,l_rec_validflex.*) 
		IF NOT rpt_int_flag_handler2("COA Flexcode:",l_rec_validflex.flex_code , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GR3_rpt_list
	CALL rpt_finish("GR3_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


############################################################
# REPORT GR3_rpt_list(p_rpt_idx,p_rec_validflex)
#
#
############################################################
REPORT GR3_rpt_list(p_rpt_idx,p_rec_validflex) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 

	OUTPUT 
	left margin 0 
	ORDER external BY p_rec_validflex.start_num, p_rec_validflex.flex_code
	 
	FORMAT
	 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Code", 
			COLUMN 20, "Description" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_validflex.flex_code , 
			COLUMN 20, p_rec_validflex.desc_text 
			
		BEFORE GROUP OF p_rec_validflex.start_num 
			SKIP TO top OF PAGE 
			SELECT * INTO l_rec_structure.* FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = p_rec_validflex.start_num 
			PRINT COLUMN 1, "Start Position :", p_rec_validflex.start_num USING "<<<<", 
			COLUMN 20, l_rec_structure.desc_text 
			SKIP 1 line
			 
		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 
END REPORT