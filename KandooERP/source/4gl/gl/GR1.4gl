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
GLOBALS "../gl/GR1_GLOBALS.4gl" 
############################################################
# FUNCTION GR1_main()
#
# COA Report
############################################################
FUNCTION GR1_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GR1") 
		
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G146 with FORM "G146" 
			CALL windecoration_g("G146") --populate WINDOW FORM elements 
		
			MENU " COA" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GR1","menu-coa") 
					CALL GR1_rpt_process(GR1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Run" " Selection criteria AND PRINT REPORT"
					CALL GR1_rpt_process(GR1_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY (interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G146
			

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GR1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G146 with FORM "G146" 
			CALL windecoration_g("G146") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW G146 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GR1_rpt_process(get_url_sel_text())
	END CASE 			 
END FUNCTION 


############################################################
# FUNCTION GR1_rpt_query()
#
#
############################################################
FUNCTION GR1_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON acct_code, 
	desc_text, 
	type_ind, 
	start_year_num, 
	start_period_num, 
	end_year_num, 
	end_period_num, 
	group_code, 
	analy_req_flag, 
	analy_prompt_text, 
	qty_flag, 
	uom_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GR1","construct-query") 

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


############################################################
# FUNCTION GR1_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GR1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_coa RECORD LIKE coa.* 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR1_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT * ", 
	"FROM coa ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GR1_rpt_list")].sel_text clipped, " ", 
	" ORDER BY acct_code " 
	
	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 
	OPEN selcurs 

	FOREACH selcurs INTO l_rec_coa.* 
	
		#---------------------------------------------------------
		OUTPUT TO REPORT GR1_rpt_list(l_rpt_idx,l_rec_coa.*) 
		IF NOT rpt_int_flag_handler2("COA:",l_rec_coa.acct_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GR1_rpt_list
	CALL rpt_finish("GR1_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	  
END FUNCTION 


############################################################
# REPORT GR1_rpt_list(p_rec_coa)
#
#
############################################################
REPORT GR1_rpt_list(p_rpt_idx,p_rec_coa) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_coa RECORD LIKE coa.* 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_coa.acct_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Account", 
			COLUMN 20, "Description", 
			COLUMN 64, "Start", 
			COLUMN 76, "End", 
			COLUMN 83, "Org.", 
			COLUMN 90, "Type" , 
			COLUMN 96, "Qty", 
			COLUMN 102, "Analysis Prompt" 
			PRINT COLUMN 61, "Year", 
			COLUMN 66, "Per.", 
			COLUMN 71, "Year", 
			COLUMN 76, "Per.", 
			COLUMN 96, "UOM" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 1, p_rec_coa.acct_code , 
			COLUMN 20, p_rec_coa.desc_text, 
			COLUMN 61, p_rec_coa.start_year_num USING "####", 
			COLUMN 66, p_rec_coa.start_period_num USING "###", 
			COLUMN 71, p_rec_coa.end_year_num USING "####", 
			COLUMN 76, p_rec_coa.end_period_num USING "###", 
			COLUMN 81, p_rec_coa.group_code, 
			COLUMN 92, p_rec_coa.type_ind, 
			COLUMN 96, p_rec_coa.uom_code, 
			COLUMN 102, p_rec_coa.analy_prompt_text 
		ON LAST ROW 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 



