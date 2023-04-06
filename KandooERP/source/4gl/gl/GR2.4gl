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
GLOBALS "../gl/GR2_GLOBALS.4gl"
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_coa RECORD LIKE coa.* 
--	DEFINE modu_line1 CHAR(130)
--	DEFINE modu_line2 CHAR(130) 
############################################################
# FUNCTION GR2_main()
#
#
############################################################
FUNCTION GR2_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GR2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G120 with FORM "G120" 
			CALL windecoration_g("G120") 
		
		
			MENU " Report Instructions" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GR2","menu-REPORT-instruction") 
					CALL GR2_rpt_process(GR2_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Report" " SELECT Criteria AND Print Report"
					CALL GR2_rpt_process(GR2_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"			#COMMAND "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G120


		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GR2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G120 with FORM "G120" 
			CALL windecoration_g("G120") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GR2_rpt_query()) #save where clause in env 
			CLOSE WINDOW G120 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GR2_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 


############################################################
# FUNCTION GR2_rpt_query()
#
#
############################################################
FUNCTION GR2_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT l_where_text ON reporthead.report_code, 
	reporthead.desc_text, 
	reportdetl.line_num 
	FROM reportdetl.report_code, 
	reporthead.desc_text, 
	reportdetl.line_num 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GR2","construct-reporthead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		RETURN l_where_text
	END IF
END FUNCTION


############################################################
# FUNCTION GR2_rpt_process()
#
#
############################################################
FUNCTION GR2_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE l_rec_reportdetl RECORD LIKE reportdetl.* 



	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GR2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GR2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR2_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = 
	"SELECT reporthead.*, reportdetl.* ", 
	"FROM reporthead, outer reportdetl ", 
	"WHERE reporthead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND reportdetl.cmpy_code = reporthead.cmpy_code ", 
	"AND reportdetl.report_code = reporthead.report_code AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR2_rpt_list")].sel_text clipped, " ",
	"ORDER BY reporthead.report_code, reportdetl.line_num " 


	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice
	 
	FOREACH selcurs INTO l_rec_reporthead.*, l_rec_reportdetl.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GR2_rpt_list(l_rpt_idx,l_rec_reporthead.*, l_rec_reportdetl.*)  
		IF NOT rpt_int_flag_handler2("COA:",l_rec_reporthead.report_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GR2_rpt_list
	CALL rpt_finish("GR2_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 



############################################################
# REPORT GR2_rpt_list(p_rpt_idx,p_rec_reporthead, p_rec_reportdetl)
#
#
############################################################
REPORT GR2_rpt_list(p_rpt_idx,p_rec_reporthead, p_rec_reportdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE p_rec_reportdetl RECORD LIKE reportdetl.* 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_reportdetl.report_code, p_rec_reportdetl.line_num 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Line", 
			COLUMN 8, "Column", 
			COLUMN 17, "Sign", 
			COLUMN 24, "Label", 
			COLUMN 42, "Segment", 
			COLUMN 66, "Begin", 
			COLUMN 86, " End", 
			COLUMN 105, "Drop", 
			COLUMN 115, "Save" 

			PRINT COLUMN 13, "Command", 
			COLUMN 66, "Account", 
			COLUMN 86, "Account", 
			COLUMN 104, "Lines" , 
			COLUMN 115, " In " 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 

			PRINT COLUMN 1, p_rec_reportdetl.line_num USING "###.##", 
			COLUMN 10, p_rec_reportdetl.col_num USING "-#", 
			COLUMN 15, p_rec_reportdetl.command_code, 
			COLUMN 18, p_rec_reportdetl.sign_change_ind, 
			COLUMN 20, p_rec_reportdetl.label_text, 
			COLUMN 44, p_rec_reportdetl.flex_code, 
			COLUMN 66, p_rec_reportdetl.start_acct_code , 
			COLUMN 86, p_rec_reportdetl.end_acct_code , 
			COLUMN 106, p_rec_reportdetl.skip_num USING "##", 
			COLUMN 110, p_rec_reportdetl.ref_num USING "--------" 

		BEFORE GROUP OF p_rec_reportdetl.report_code 
			SKIP 2 LINES 
			PRINT COLUMN 1, p_rec_reportdetl.report_code, 2 spaces, p_rec_reporthead.desc_text 

		ON LAST ROW 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT