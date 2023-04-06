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
GLOBALS "../gl/GR9_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
--DEFINE modu_line1 CHAR(130)
--DEFINE modu_line2 CHAR(130)
--DEFINE modu_where_part CHAR(800) 
--DEFINE modu_query_text CHAR(890) 
#############################################################
# FUNCTION GR9_main()
#
# GR9  Group Code Report
############################################################
FUNCTION GR9_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GR9") 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW G169 with FORM "G169" 
			CALL windecoration_g("G169") 
		
			MENU " Group Code" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GR9","menu-group-code") 
					CALL GR9_rpt_process(GR9_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL GR9_rpt_process(GR9_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G169

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GR9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G169 with FORM "G169" 
			CALL windecoration_g("G169") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GR9_rpt_query()) #save where clause in env 
			CLOSE WINDOW G169 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GR9_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION 


#############################################################
# FUNCTION GR9_rpt_query()
#
#
############################################################
FUNCTION GR9_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_groupinfo RECORD LIKE groupinfo.* 

	MESSAGE kandoomsg2("U",1001,"") 	

	CONSTRUCT BY NAME l_where_text ON group_code,	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GR9","construct-group") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		MESSAGE "Report Query aborted"
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF
END FUNCTION


#############################################################
# FUNCTION GR9_rpt_process() 
#
#
############################################################
FUNCTION GR9_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_groupinfo RECORD LIKE groupinfo.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GR9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GR9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR9_rpt_list")].sel_text
	#------------------------------------------------------------
		
	LET l_query_text = 
	"SELECT * ", 
	"FROM groupinfo ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR9_rpt_list")].sel_text clipped, " ", 
	"ORDER BY group_code " 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_groupinfo.*
		#---------------------------------------------------------
		OUTPUT TO REPORT GR9_rpt_list(l_rpt_idx,l_rec_groupinfo.*) 
		IF NOT rpt_int_flag_handler2("Code:",l_rec_groupinfo.group_code , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GR9_rpt_list
	CALL rpt_finish("GR9_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	 
END FUNCTION 


#############################################################
# REPORT GR9_rpt_list(p_rec_groupinfo)
#
#
############################################################
REPORT GR9_rpt_list(p_rpt_idx,p_rec_groupinfo) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_groupinfo RECORD LIKE groupinfo.* 

	OUTPUT 

	--left margin 0 
	#right margin
	#top margin
	#page length

	ORDER external BY p_rec_groupinfo.group_code 

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

			PRINT COLUMN 1, p_rec_groupinfo.group_code , 
			COLUMN 20, p_rec_groupinfo.desc_text 

		ON LAST ROW 
			SKIP 1 line 

			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


END REPORT