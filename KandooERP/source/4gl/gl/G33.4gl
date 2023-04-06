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
# \file
# \brief module G33 - disbursement detail REPORT
#               - Clone of /usr1/dist/gl/G33_C.4gl with following changes :
#                        - CALL TO RMS FUNCTION reports
#                        - CALL TO kandooreport
#                        - CALL TO enter_MESSAGE
#                        - CALL TO set_defaults
#                        - multi-lingual conversion
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/G33_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
############################################################
# MODULE Scope Variables
############################################################
############################################################
# FUNCTION G33_main()
#
#
############################################################
FUNCTION G33_main() 
	DEFER quit 
	DEFER interrupt 
	CALL setModuleId("G33") 
	CALL rpt_rmsreps_reset(NULL)

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW G467 with FORM "G467" 
			CALL windecoration_g("G467") 
		
		
			MENU " Journal Disbursements" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","G33","menu-journal-disbursements") 
					CALL G33_rpt_process(G33_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Run Report"		#        " Enter selection criteria AND REPORT on disbursements "
					CALL G33_rpt_process(G33_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print"#        " Report Management System"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" #COMMAND KEY(interrupt,"E") "Exit"		#                           " EXIT PROGRAM"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G467
			 
		WHEN "2" #Background Process with rmsreps.report_code
			CALL G33_rpt_process(NULL)  

		WHEN "3" #Only create query-where-part
			OPEN WINDOW G467 with FORM "G467" 
			CALL windecoration_g("G467") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(G33_rpt_query()) #save where clause in env 
			CLOSE WINDOW G467 
			
		WHEN "4" #Background Process with SQL WHERE ARGUMENT
			CALL G33_rpt_process(get_url_sel_text())
	END CASE
END FUNCTION 
############################################################
# END FUNCTION G33_main()
############################################################


############################################################
# FUNCTION G33_rpt_query()
#
#
############################################################
FUNCTION G33_rpt_query() 
	DEFINE l_where_text STRING 

	MESSAGE kandoomsg2("G",1001,"") #G1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		group_code, 
		disb_code, 
		jour_code, 
		acct_code, 
		type_ind, 
		dr_cr_ind, #Disburse Credit,Debit or Both 
		total_qty, 
		disb_qty, 
		uom_code, 
		last_date, 
		last_jour_num, 
		period_num, 
		year_num, 
		com1_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G33","construct-query") 

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
# END FUNCTION G33_rpt_query()
############################################################


############################################################
# FUNCTION G33_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION G33_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE l_temp_text STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"G33_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT G33_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("G33_rpt_list")].sel_text
	#------------------------------------------------------------

	LET l_query_text = "SELECT * ", 
	"FROM disbhead ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("G33_rpt_list")].sel_text clipped," ", 
	"ORDER BY 1, 2" 
	
	PREPARE s_disbhead FROM l_query_text 
	DECLARE c_disbhead CURSOR FOR s_disbhead 

	#LET l_msgresp = kandoomsg("G",1028,"")	##G1028 Reporting on Journal Disbursement

	FOREACH c_disbhead INTO l_rec_disbhead.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT GR1_rpt_list(l_rpt_idx,l_rec_disbhead.*,p_where_text,l_temp_text) 
		IF NOT rpt_int_flag_handler2("Disbursement:",l_rec_disbhead.disb_code , NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT G33_rpt_list
	CALL rpt_finish("G33_rpt_list")
	#------------------------------------------------------------

	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION G33_rpt_process(p_where_text) 
############################################################


############################################################
# REPORT G33_rpt_list(p_rec_disbhead)
#
#
############################################################
REPORT G33_rpt_list(p_rpt_idx,p_rec_disbhead,p_where_text,p_temp_text)
 	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_disbhead RECORD LIKE disbhead.* 
	DEFINE p_where_text STRING
	DEFINE p_temp_text STRING 

	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_line array[4] OF CHAR(132) 
	DEFINE l_line1 CHAR(132) 
	DEFINE l_line2 CHAR(132) 
	DEFINE l_rec_period_text CHAR(7) 
	DEFINE l_x SMALLINT 

	OUTPUT 
--	left margin 0 
--	PAGE length 66 
	ORDER external BY 
		p_rec_disbhead.cmpy_code, 
		p_rec_disbhead.disb_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #line1_text
			PRINT COLUMN 02, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #line1_text

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		

		ON EVERY ROW 
			NEED 8 LINES 
			PRINT COLUMN 4, p_rec_disbhead.disb_code, 
			COLUMN 17, p_rec_disbhead.jour_code; 
			
			IF p_rec_disbhead.last_date IS NOT NULL THEN 
				LET l_rec_period_text = p_rec_disbhead.year_num USING "####","/", 
				p_rec_disbhead.period_num USING "&&" 
				PRINT COLUMN 23, p_rec_disbhead.last_jour_num USING "<<<<<", 
				COLUMN 30, p_rec_disbhead.last_date USING "dd/mm/yy", 
				COLUMN 40, l_rec_period_text clipped; 
			ELSE 
				PRINT COLUMN 23, "*Disbursement Never Posted*"; 
			END IF 
			
			SELECT * INTO l_rec_coa.* 
			FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_disbhead.acct_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				IF p_rec_disbhead.type_ind = "1" 
				OR p_rec_disbhead.type_ind = "2" THEN 
					LET l_rec_coa.desc_text = "** Account Not Found **" 
				END IF 
			END IF 

			PRINT COLUMN 52, p_rec_disbhead.type_ind, 
			COLUMN 56, p_rec_disbhead.acct_code, 
			COLUMN 76, l_rec_coa.desc_text[1,24], 
			COLUMN 102,p_rec_disbhead.total_qty USING "--------&.&&&", 
			COLUMN 122,p_rec_disbhead.uom_code 

			IF p_rec_disbhead.com1_text IS NOT NULL THEN 
				PRINT COLUMN 41, "Comments:", 
				COLUMN 52, p_rec_disbhead.com1_text clipped 
			END IF 
			DECLARE c_disbdetl CURSOR FOR 
			SELECT * 
			FROM disbdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND disb_code = p_rec_disbhead.disb_code 
			ORDER BY cmpy_code, disb_code, line_num 
			FOREACH c_disbdetl INTO l_rec_disbdetl.* 
				PRINT COLUMN 58, l_rec_disbdetl.acct_code, 
				COLUMN 78, l_rec_disbdetl.desc_text[1,24], 
				COLUMN 104,l_rec_disbdetl.disb_qty USING "--------&.&&&", 
				COLUMN 119,l_rec_disbdetl.analysis_text[1,14] 
			END FOREACH 
			PRINT COLUMN 104,"-------------" 
			PRINT COLUMN 86, "Disbursed Total:", 
			COLUMN 104,p_rec_disbhead.disb_qty USING "--------&.&&&" 
			SKIP 2 LINES 

		ON LAST ROW 
			NEED 5 LINES 
			SKIP 1 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT 
############################################################
# END REPORT G33_rpt_list(p_rec_disbhead)
############################################################