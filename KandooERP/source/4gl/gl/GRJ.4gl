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
GLOBALS "../gl/GRJ_GLOBALS.4gl" 
############################################################
# MOPDULE Scope Variables
############################################################
DEFINE modu_rec_structure RECORD LIKE structure.* 
--DEFINE modu_rpt_note LIKE rmsreps.report_text 
--DEFINE glob_rec_rmsreps.report_width_num LIKE rmsreps.report_width_num 
--DEFINE glob_rec_rmsreps.page_length_num LIKE rmsreps.page_length_num 
--DEFINE glob_rec_rmsreps.page_num LIKE rmsreps.page_num 
--DEFINE modu_where_text CHAR(400) 
--DEFINE modu_temp_text CHAR(20) 
############################################################
# FUNCTION GRJ_main()
#
# GRJ - Consolidation Reporting Codes Report
############################################################
FUNCTION GRJ_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRJ") 
	CALL rpt_rmsreps_reset(NULL)

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G452 with FORM "G452" 
			CALL windecoration_g("G452") 
		
			SELECT * INTO modu_rec_structure.* FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "L" 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",5019,"") 
				#5019 Ledger Segments Not Set Up
			ELSE 
				MENU " Consol Reporting Codes" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","GRJ","menu-consol-reporting-codes") 
						CALL GRJ_rpt_process(GRJ_rpt_query())
						CALL rpt_rmsreps_reset(NULL)
						
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
		
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
		
					ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
						CALL GRJ_rpt_process(GRJ_rpt_query())
						CALL rpt_rmsreps_reset(NULL)
		
					ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
						CALL run_prog("URS","","","","") 

		
					ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
						EXIT MENU 
		
				END MENU 
		
			END IF 
			CLOSE WINDOW G452 


		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRJ_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G452 with FORM "G452" 
			CALL windecoration_g("G452") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRJ_rpt_query()) #save where clause in env 
			CLOSE WINDOW G452 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRJ_rpt_process(get_url_sel_text())
	END CASE 
END FUNCTION


############################################################
# FUNCTION GRJ_rpt_query() GRJ_rpt_query()IN
#
#
############################################################
FUNCTION GRJ_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("G",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON consol_code, desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GRJ","construct-consol") 

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
# FUNCTION GRJ_rpt_process()
#
#
############################################################
FUNCTION GRJ_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_rec_consolhead RECORD LIKE consolhead.* 
	DEFINE l_rec_consoldetl RECORD LIKE consoldetl.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GRJ_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GRJ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRJ_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT * FROM consolhead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",	glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRJ_rpt_list")].sel_text clipped, " ", 
	"ORDER BY 2"
	 
	PREPARE s_consolhead FROM l_query_text 
	DECLARE c_consolhead CURSOR FOR s_consolhead
	 
	LET l_query_text = "SELECT * FROM consoldetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND consol_code = ? "
	 
	PREPARE s_consoldetl FROM l_query_text 
	DECLARE c_consoldetl CURSOR FOR s_consoldetl 


	FOREACH c_consolhead INTO l_rec_consolhead.* 
		#DISPLAY l_rec_consolhead.desc_text TO lbLabel1b  -- 1,33
		MESSAGE l_rec_consolhead.desc_text 
		OPEN c_consoldetl USING l_rec_consolhead.consol_code 

		FOREACH c_consoldetl INTO l_rec_consoldetl.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT GRJ_rpt_list(l_rpt_idx,l_rec_consoldetl.*) 
			IF NOT rpt_int_flag_handler2("Consolidated:",l_rec_consolhead.desc_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END FOREACH 

		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				#9501 Report Terminated
				MESSAGE kandoomsg2("U",9501,"") 
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GRJ_rpt_list
	CALL rpt_finish("GRJ_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 


############################################################
# REPORT GRJ_rpt_list(p_rpt_idx,p_rec_consoldetl) 
#
#
############################################################
REPORT GRJ_rpt_list(p_rpt_idx,p_rec_consoldetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_consoldetl RECORD LIKE consoldetl.* 
	DEFINE l_desc_text LIKE consolhead.desc_text 
	DEFINE l_ledg_text CHAR(9) 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_consoldetl.consol_code, 
	p_rec_consoldetl.flex_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01,"Consol Code", 
			COLUMN 20,"Description" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

 
		BEFORE GROUP OF p_rec_consoldetl.consol_code 
			NEED 4 LINES 
			SELECT desc_text INTO l_desc_text FROM consolhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND consol_code = p_rec_consoldetl.consol_code 
			PRINT COLUMN 01, p_rec_consoldetl.consol_code, 
			COLUMN 20, l_desc_text 
			LET l_ledg_text = "Ledgers:" 

		ON EVERY ROW 
			LET l_desc_text = NULL 
			SELECT desc_text INTO l_desc_text FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = modu_rec_structure.start_num 
			AND flex_code = p_rec_consoldetl.flex_code 
			PRINT COLUMN 11, l_ledg_text, 
			COLUMN 22, p_rec_consoldetl.flex_code, 
			COLUMN 41, l_desc_text clipped 
			LET l_ledg_text = NULL 

		AFTER GROUP OF p_rec_consoldetl.consol_code 
			SKIP 1 line 

		ON LAST ROW 
			NEED 6 LINES 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 
