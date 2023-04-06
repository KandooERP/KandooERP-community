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
GLOBALS "../eo/E_EO_GLOBALS.4gl" 
GLOBALS "../eo/ET_GROUP_GLOBALS.4gl"
GLOBALS "../eo/ET2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_temp_text char(20) 
###########################################################################
# FUNCTION ET5_main() 
#
# ET5 Sales Person Monthly Turnover Comparison
###########################################################################
FUNCTION ET5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET5")  

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E270 with FORM "E270" 
			 CALL windecoration_e("E270")  
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 

			MENU " Monthly Turnover comparison" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET5","menu-Monthly_Turnover-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET5_rpt_process(ET5_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										
					
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET5_rpt_process(ET5_rpt_query())
		
				ON ACTION "PRINT MANAGER" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 					
				
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E270

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E270 with FORM "E270" 
			 CALL windecoration_e("E270") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET5_rpt_query()) #save where clause in env 
			CLOSE WINDOW E270 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET5_rpt_process(get_url_sel_text())
	END CASE 				
						 
END FUNCTION 
###########################################################################
# END FUNCTION ET5_main() 
###########################################################################


###########################################################################
# FUNCTION ET5_rpt_query() 
#
# 
###########################################################################
FUNCTION ET5_rpt_query() 
	DEFINE l_where_text STRING	

	IF (NOT ET5_enter_year()) OR (int_flag = TRUE) THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF
	
	MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	sale_type_ind, 
	terri_code, 
	mgr_code, 
	city_text, 
	state_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET5","construct-sale_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE 
		LET glob_rec_rpt_selector.ref1_num = modu_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date
		LET glob_rec_rpt_selector.ref1_ind = modu_rec_statint.dist_flag

		LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date
		LET glob_rec_rpt_selector.ref2_code = modu_rec_statint.int_text
		LET glob_rec_rpt_selector.ref2_ind = modu_rec_statint.updreq_flag
			
		RETURN l_where_text
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET5_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ET5_enter_year() 
#
#
###########################################################################
FUNCTION ET5_enter_year() 
	LET modu_rec_statparms.year_num = year(today) 
	MESSAGE kandoomsg2("E",1157,"") 	#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT BY NAME modu_rec_statparms.year_num WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET5","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statparms.year_num = modu_rec_statparms.year_num - 1 
			NEXT FIELD year_num 
			
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statparms.year_num = modu_rec_statparms.year_num + 1 
			NEXT FIELD year_num 
			
		AFTER FIELD year_num 
			IF modu_rec_statparms.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 		#9210 Year number must be entered
				LET modu_rec_statparms.year_num = year(today) 
				NEXT FIELD year_num 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET modu_rec_statparms.year_num = year(today) 
		LET glob_rec_rpt_selector.ref1_num = modu_rec_statparms.year_num	
		RETURN FALSE 
	ELSE 
		LET glob_rec_rpt_selector.ref1_num = modu_rec_statparms.year_num	
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET5_enter_year() 
###########################################################################


###########################################################################
# FUNCTION ET5_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		

	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET5_rpt_list")].sel_text clipped," ",		
	"ORDER BY 1" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	# REPORT requires two dynamic cursors
	# 1. FOR intervals
	DECLARE c_statint cursor FOR 
	SELECT * FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_rec_statparms.year_num 
	AND type_code = modu_rec_statparms.mth_type_code 
	ORDER BY 1,2,3,4 
	
	# 2. FOR sales stats
	LET l_query_text = "SELECT grs_amt,net_amt,comm_amt FROM statsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND int_num = ? ", 
	"AND sale_code = ? " 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 

	#MESSAGE kandoomsg2("E",1045,"") 	#1045 Reporting on Salesperson...
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ET5_rpt_list(l_rpt_idx,
		l_rec_salesperson.*)  
		IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ET5_rpt_list
	CALL rpt_finish("ET5_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET5_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ET5_rpt_list(p_rec_salesperson) 
#
#
###########################################################################
REPORT ET5_rpt_list(p_rpt_idx, p_rec_salesperson) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_rec_statsper array[3] OF RECORD 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		comm_amt LIKE statsper.comm_amt, 
		disc_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_total array[3] OF RECORD 
		year_num INTEGER, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		comm_amt LIKE statsper.comm_amt, 
		disc_per FLOAT 
	END RECORD 
	DEFINE l_turn_per FLOAT 
	DEFINE i,j SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_salesperson.cmpy_code,	p_rec_salesperson.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_salesperson.sale_code 
			NEED 24 LINES 
			FOR i = 1 TO 3 
				LET l_arr_rec_total[i].year_num = modu_rec_statparms.year_num + 1 - i 
				LET l_arr_rec_total[i].net_amt = 0 
				LET l_arr_rec_total[i].grs_amt = 0 
				LET l_arr_rec_total[i].comm_amt = 0 
			END FOR 
			PRINT COLUMN 02,"Salesperson:", 
			COLUMN 14,p_rec_salesperson.sale_code, 
			COLUMN 25,p_rec_salesperson.name_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			LET i = glob_arr_rec_rpt_kandooreport[p_rpt_idx].width_num 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[1,i] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text[1,i]
			PRINT COLUMN 01,"----------", 
			
			COLUMN 12,"------- ",l_arr_rec_total[1].year_num USING "&&&&"," ------", 
			COLUMN 32,"------- ",l_arr_rec_total[2].year_num USING "&&&&"," ------", 
			COLUMN 52,"------- ",l_arr_rec_total[3].year_num USING "&&&&"," ------" 
			
			OPEN c_statint 
			FOREACH c_statint INTO l_rec_statint.* 
				PRINT COLUMN 01, l_rec_statint.int_text; 
				
				FOR i = 1 TO 3 
					OPEN c_statsper USING l_arr_rec_total[i].year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num, 
					p_rec_salesperson.sale_code 
					FETCH c_statsper INTO l_arr_rec_statsper[i].grs_amt, 
					l_arr_rec_statsper[i].net_amt, 
					l_arr_rec_statsper[i].comm_amt 
					
					IF status = NOTFOUND THEN 
						LET l_arr_rec_statsper[i].net_amt = 0 
						LET l_arr_rec_statsper[i].grs_amt = 0 
						LET l_arr_rec_statsper[i].comm_amt = 0 
					ELSE 
						LET l_arr_rec_total[i].net_amt = l_arr_rec_total[i].net_amt + l_arr_rec_statsper[i].net_amt 
						LET l_arr_rec_total[i].grs_amt = l_arr_rec_total[i].grs_amt + l_arr_rec_statsper[i].grs_amt 
						LET l_arr_rec_total[i].comm_amt = l_arr_rec_total[i].comm_amt + l_arr_rec_statsper[i].comm_amt 
					END IF 
					
					IF l_arr_rec_statsper[i].grs_amt = 0 THEN 
						LET l_arr_rec_statsper[i].disc_per = 0 
					ELSE 
						LET l_arr_rec_statsper[i].disc_per = 100 * (1-(l_arr_rec_statsper[i].net_amt/l_arr_rec_statsper[i].grs_amt)) 
					END IF 
					LET j = (i*18) - 6 
					PRINT COLUMN j, l_arr_rec_statsper[i].net_amt USING "---,---,--&"," ", l_arr_rec_statsper[i].disc_per USING "---&.&"; 
				END FOR 
				IF l_arr_rec_statsper[3].net_amt = 0 THEN 
					LET l_turn_per = 0 
				ELSE 
					LET l_turn_per = (l_arr_rec_statsper[1].net_amt-l_arr_rec_statsper[3].net_amt) / l_arr_rec_statsper[3].net_amt 
				END IF 
				PRINT COLUMN 74,l_turn_per USING "---&.&" 
			END FOREACH 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01,"Year total:"; 
			FOR i = 1 TO 3 
				IF l_arr_rec_total[i].grs_amt = 0 THEN 
					LET l_arr_rec_total[i].disc_per = 0 
				ELSE 
					LET l_arr_rec_total[i].disc_per = 100 * (1-(l_arr_rec_total[i].net_amt/l_arr_rec_total[i].grs_amt)) 
				END IF 
				LET j = (i*18) - 6 
				PRINT COLUMN j, l_arr_rec_total[i].net_amt USING "---,---,--&"," ", l_arr_rec_total[i].disc_per USING "---&.&"; 
			END FOR 
			IF l_arr_rec_total[3].net_amt = 0 THEN 
				LET l_turn_per = 0 
			ELSE 
				LET l_turn_per = (l_arr_rec_total[1].net_amt-l_arr_rec_total[3].net_amt) / l_arr_rec_total[3].net_amt 
			END IF 
			PRINT COLUMN 74,l_turn_per USING "---&.&" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 01,"Commission:", 
			COLUMN 12, l_arr_rec_total[1].comm_amt USING "---,---,--&", 
			COLUMN 30, l_arr_rec_total[2].comm_amt USING "---,---,--&", 
			COLUMN 48, l_arr_rec_total[3].comm_amt USING "---,---,--&" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			SKIP 2 LINES 
			
		ON LAST ROW 
			SKIP 1 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT ET5_rpt_list(p_rec_salesperson) 
###########################################################################