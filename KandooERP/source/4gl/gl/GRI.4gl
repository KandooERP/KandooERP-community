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
GLOBALS "../gl/GRI_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_rec_structure RECORD LIKE structure.* 
	DEFINE modu_where_text CHAR(400) 
	DEFINE modu_temp_text CHAR(20) 
############################################################
# FUNCTION GRI_main()
#
# GRI - Multi-Ledger Relationships Report
############################################################
FUNCTION GRI_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRI") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G450 with FORM "G450" 
			CALL windecoration_g("G450") 
		
			SELECT * INTO modu_rec_structure.* FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "L"
			IF status = NOTFOUND THEN 
				CALL fgl_winmessage("Ledger Segment Error",kandoomsg2("G",5019,""),"ERROR") #5019 Ledger Segment Not Set Up
			ELSE
			 
				MENU " Multi-Ledger Relationships" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","GRI","menu-multi-ledger-relationships") 
						CALL GRI_rpt_process(GRI_rpt_query())
						CALL rpt_rmsreps_reset(NULL)
						
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
		
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
		
					ON ACTION "Report" 	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
						CALL GRI_rpt_process(GRI_rpt_query()) 
						CALL rpt_rmsreps_reset(NULL)
		
					ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
						CALL run_prog("URS","","","","") 
		
					ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
						EXIT MENU 
		
				END MENU 
		
			END IF 
		
			CLOSE WINDOW G450 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRI_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G450 with FORM "G450" 
			CALL windecoration_g("G450") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRI_rpt_query()) #save where clause in env 
			CLOSE WINDOW G450 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRI_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 


############################################################
# FUNCTION GRI_rpt_query()
#
#
############################################################
FUNCTION GRI_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"")
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON flex1_code, 
	acct1_code, 
	flex2_code, 
	acct2_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GRI","construct-flex") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE
		RETURN l_where_text
	END IF 
END FUNCTION


############################################################
# FUNCTION GRI_rpt_process()
#
#
############################################################
FUNCTION GRI_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING  
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.*
	DEFINE l_flex_desc LIKE validflex.desc_text
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GRI_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GRI_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRI_rpt_list")].sel_text
	#------------------------------------------------------------


	LET l_query_text = "SELECT * FROM ledgerreln ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRI_rpt_list")].sel_text clipped," ", 
	"ORDER BY 2,3" 
	
	PREPARE s_ledgerreln FROM l_query_text 
	DECLARE c_ledgerreln CURSOR FOR s_ledgerreln 

	FOREACH c_ledgerreln INTO l_rec_ledgerreln.* 
		SELECT desc_text INTO l_flex_desc FROM validflex 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num = modu_rec_structure.start_num 
		AND flex_code = l_rec_ledgerreln.flex1_code 

	
		#---------------------------------------------------------
		OUTPUT TO REPORT GRI_rpt_list(l_rpt_idx,l_rec_ledgerreln.*)  
		IF NOT rpt_int_flag_handler2("Flex Desc.:",l_flex_desc, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT GRI_rpt_list
	CALL rpt_finish("GRI_rpt_list")
	#------------------------------------------------------------
	
	IF int_flag THEN
		MESSAGE "Report Generation Canceled..."
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 


############################################################
# REPORT GRI_rpt_list(p_rpt_idx,p_rec_ledgerreln) 
#
#
############################################################
REPORT GRI_rpt_list(p_rpt_idx,p_rec_ledgerreln) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_acct_desc LIKE coa.desc_text
	DEFINE l_flex_desc LIKE validflex.desc_text 
	DEFINE l_cmpy_head CHAR(132)
	DEFINE l_i SMALLINT 
	DEFINE l_x SMALLINT 
	DEFINE l_y SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
--	left margin 0 
	ORDER external BY p_rec_ledgerreln.flex1_code, 
	p_rec_ledgerreln.flex2_code 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Ledger", 
			COLUMN 20,"Description", 
			COLUMN 61,"Account", 
			COLUMN 80,"Description" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			NEED 4 LINES 
			LET l_flex_desc = NULL 
			LET l_acct_desc = NULL 
			SELECT desc_text INTO l_flex_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = modu_rec_structure.start_num 
			AND flex_code = p_rec_ledgerreln.flex1_code 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_ledgerreln.acct1_code 
			PRINT COLUMN 01, p_rec_ledgerreln.flex1_code, 
			COLUMN 20, l_flex_desc, 
			COLUMN 61, p_rec_ledgerreln.acct1_code, 
			COLUMN 80, l_acct_desc 
			LET l_flex_desc = NULL 
			LET l_acct_desc = NULL 
			SELECT desc_text INTO l_flex_desc FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = modu_rec_structure.start_num 
			AND flex_code = p_rec_ledgerreln.flex2_code 
			SELECT desc_text INTO l_acct_desc FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_ledgerreln.acct2_code 
			PRINT COLUMN 01, p_rec_ledgerreln.flex2_code, 
			COLUMN 20, l_flex_desc, 
			COLUMN 61, p_rec_ledgerreln.acct2_code, 
			COLUMN 80, l_acct_desc 
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