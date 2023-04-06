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
GLOBALS "../eo/EW_GROUP_GLOBALS.4gl"
GLOBALS "../eo/EW2_GLOBALS.4gl"  
###########################################################################
# MODULAR Scope Variables
###########################################################################
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_rec_criteria RECORD 
	part_ind char(1), 
	pgrp_ind char(1), 
	mgrp_ind char(1) 
END RECORD 
DEFINE modu_rec_interval array[15] OF RECORD 
	int_text char(7), 
	year_num LIKE statint.year_num, 
	int_num LIKE statint.int_num 
END RECORD 
DEFINE modu_temp_text STRING 
###########################################################################
# FUNCTION EW2_main()
#
# EW2 - Sales Area Distribution Trends Report
###########################################################################
FUNCTION EW2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EW2") 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		
		
			OPEN WINDOW E285 with FORM "E285" 
			 CALL windecoration_e("E285") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text 
			 
			MENU " Distribution trends" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EW2","menu-Distribution-1") -- albo kd-502 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EW2_rpt_process(EW2_rpt_query())
		
				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 		
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW E285
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EW2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E285 with FORM "E285" 
			 CALL windecoration_e("E285") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EW2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E285 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EW2_rpt_process(get_url_sel_text())
	END CASE 			 
END FUNCTION
###########################################################################
# END FUNCTION EW2_main()
###########################################################################


###########################################################################
# FUNCTION EW2_rpt_query()
#
# 
###########################################################################
FUNCTION EW2_rpt_query() 
	DEFINE l_where_text STRING

	IF NOT EW2_enter_year() THEN
		MESSAGE "Report aborted by user"
		RETURN NULL
	END IF 

	MESSAGE kandoomsg2("E",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT l_where_text ON salearea.area_code, 
	salearea.desc_text, 
	territory.terr_code, 
	territory.desc_text 
	FROM salearea.area_code, 
	salearea.desc_text, 
	territory.terr_code, 
	territory.desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EW2","construct-area_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		CALL EW2_build_interval(modu_rec_statint.*) 

		LET glob_rec_rpt_selector.ref1_num = modu_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date
		LET glob_rec_rpt_selector.ref1_ind = modu_rec_statint.dist_flag

		LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date
		LET glob_rec_rpt_selector.ref2_code = modu_rec_statint.int_text
		LET glob_rec_rpt_selector.ref2_ind = modu_rec_statint.updreq_flag	

		LET glob_rec_rpt_selector.ref4_ind = modu_rec_criteria.part_ind
		LET glob_rec_rpt_selector.ref5_ind = modu_rec_criteria.pgrp_ind
		LET glob_rec_rpt_selector.ref6_ind = modu_rec_criteria.mgrp_ind
			
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION EW2_rpt_query()
###########################################################################


############################################################
# FUNCTION EW2_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EW2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_rec_rep_distterr RECORD 
		area_code LIKE distterr.area_code, 
		maingrp_code LIKE distterr.maingrp_code, 
		prodgrp_code LIKE distterr.prodgrp_code, 
		part_code LIKE distterr.part_code, 
		qtr_net_amt LIKE distterr.qtr_net_amt, 
		net_amt1 LIKE distterr.qtr_net_amt, 
		net_amt2 LIKE distterr.qtr_net_amt, 
		net_amt3 LIKE distterr.qtr_net_amt, 
		net_amt4 LIKE distterr.qtr_net_amt, 
		net_amt5 LIKE distterr.qtr_net_amt, 
		net_amt6 LIKE distterr.qtr_net_amt, 
		net_amt7 LIKE distterr.qtr_net_amt, 
		net_amt8 LIKE distterr.qtr_net_amt, 
		net_amt9 LIKE distterr.qtr_net_amt, 
		net_amt10 LIKE distterr.qtr_net_amt, 
		net_amt11 LIKE distterr.qtr_net_amt, 
		net_amt12 LIKE distterr.qtr_net_amt, 
		net_amt13 LIKE distterr.qtr_net_amt 
	END RECORD 
	DEFINE i SMALLINT 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EW2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT EW2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
		
	LET glob_rec_rpt_selector.ref1_num = modu_rec_statint.year_num
	LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
	LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date
	LET glob_rec_rpt_selector.ref1_ind = modu_rec_statint.dist_flag

	LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
	LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date
	LET glob_rec_rpt_selector.ref2_code = modu_rec_statint.int_text
	LET glob_rec_rpt_selector.ref2_ind = modu_rec_statint.updreq_flag	

	LET glob_rec_rpt_selector.ref4_ind = modu_rec_criteria.part_ind
	LET glob_rec_rpt_selector.ref5_ind = modu_rec_criteria.pgrp_ind
	LET glob_rec_rpt_selector.ref6_ind = modu_rec_criteria.mgrp_ind		
	#------------------------------------------------------------	


	LET l_query_text = 
		"SELECT salearea.* FROM salearea,territory ", 
		"WHERE salearea.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND territory.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND territory.area_code = salearea.area_code ", 
		"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EW2_rpt_list")].sel_text clipped," ",
		"ORDER BY 1,2" 

	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea cursor FOR s_salearea 

	LET l_query_text = 
		"SELECT area_code,maingrp_code,prodgrp_code, ", 
		"part_code,qtr_net_amt FROM distterr ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND area_code = ? ", 
		"AND terr_code IS NULL ", 
		"AND part_code IS NOT NULL ", 
		"AND year_num = ? ", 
		"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
		"AND int_num = ? ", 
		"ORDER BY area_code,maingrp_code,prodgrp_code,part_code" 

	PREPARE s_distterr FROM l_query_text 
	DECLARE c_distterr cursor FOR s_distterr 

	MESSAGE kandoomsg2("E",1162,"") 	#1045 Reporting on Sales Areas...

	FOREACH c_salearea INTO l_rec_salearea.* 

		DISPLAY l_rec_salearea.desc_text at 1,30 

		#This loop represents the 13 net amounts across the REPORT
		FOR i = 1 TO 13 
			OPEN c_distterr USING l_rec_salearea.area_code, 
			modu_rec_interval[i+2].year_num, 
			modu_rec_interval[i+2].int_num 

			FOREACH c_distterr INTO l_rec_rep_distterr.* 
				#init all - so that group sum will NOT RETURN NULL
				LET l_rec_rep_distterr.net_amt1 = 0 
				LET l_rec_rep_distterr.net_amt2 = 0 
				LET l_rec_rep_distterr.net_amt3 = 0 
				LET l_rec_rep_distterr.net_amt4 = 0 
				LET l_rec_rep_distterr.net_amt5 = 0 
				LET l_rec_rep_distterr.net_amt6 = 0 
				LET l_rec_rep_distterr.net_amt7 = 0 
				LET l_rec_rep_distterr.net_amt8 = 0 
				LET l_rec_rep_distterr.net_amt9 = 0 
				LET l_rec_rep_distterr.net_amt10 = 0 
				LET l_rec_rep_distterr.net_amt11 = 0 
				LET l_rec_rep_distterr.net_amt12 = 0 
				LET l_rec_rep_distterr.net_amt13 = 0 

				CASE i 
					WHEN 1 
						LET l_rec_rep_distterr.net_amt1 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 2 
						LET l_rec_rep_distterr.net_amt2 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 3 
						LET l_rec_rep_distterr.net_amt3 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 4 
						LET l_rec_rep_distterr.net_amt4 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 5 
						LET l_rec_rep_distterr.net_amt5 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 6 
						LET l_rec_rep_distterr.net_amt6 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 7 
						LET l_rec_rep_distterr.net_amt7 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 8 
						LET l_rec_rep_distterr.net_amt8 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 9 
						LET l_rec_rep_distterr.net_amt9 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 10 
						LET l_rec_rep_distterr.net_amt10 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 11 
						LET l_rec_rep_distterr.net_amt11 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 12 
						LET l_rec_rep_distterr.net_amt12 = l_rec_rep_distterr.qtr_net_amt 
					WHEN 13 
						LET l_rec_rep_distterr.net_amt13 = l_rec_rep_distterr.qtr_net_amt 
				END CASE 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT EW2_rpt_list(l_rpt_idx,
				l_rec_rep_distterr.*)
				IF NOT rpt_int_flag_handler2("Sale Area:",l_rec_salearea.desc_text,NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------

			END FOREACH 
		END FOR 
		IF int_flag OR quit_flag THEN 
			#8503 Continue Report(Y/N)
			IF kandoomsg("U",8503,"") = "N" THEN 
				
				ERROR kandoomsg2("U",9501,"") #9501 Report Terminated
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT EW2_rpt_list
	CALL rpt_finish("EW2_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF
END FUNCTION 
############################################################
# END FUNCTION EW2_rpt_process(p_where_text) 
############################################################
 


###########################################################################
# FUNCTION EW2_enter_year()
#
# 
###########################################################################
FUNCTION EW2_enter_year() 

	LET modu_rec_criteria.part_ind = xlate_to("Y") 
	LET modu_rec_criteria.pgrp_ind = xlate_to("Y") 
	LET modu_rec_criteria.mgrp_ind = xlate_to("Y") 
	LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
	LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 

	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT BY NAME 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_rec_criteria.part_ind, 
		modu_rec_criteria.pgrp_ind, 
		modu_rec_criteria.mgrp_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EW2","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = 
					"year_num = '",modu_rec_statint.year_num,"' ", 
					"AND type_code = '",glob_rec_statparms.mth_type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_rec_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
			NEXT FIELD year_num 

		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 
			
			DISPLAY BY NAME 
				modu_rec_statint.int_text, 
				modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 		#9210 Year number must be entered
				LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD int_text 
			SELECT int_text INTO modu_rec_statint.int_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 

		AFTER FIELD int_text 
			IF modu_rec_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 				#9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = glob_rec_statparms.mth_type_code 
				AND int_text = modu_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") #9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			
			DISPLAY modu_rec_statint.start_date TO start_date
			DISPLAY modu_rec_statint.end_date TO end_date

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EW2_enter_year()
###########################################################################


###########################################################################
# FUNCTION EW2_build_interval(p_rec_statint) 
#
# 
###########################################################################
FUNCTION EW2_build_interval(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE i SMALLINT 

	#position [15] represents current interval
	#position [1] AND [2] are only used FOR DISPLAY of int_text in PAGE HEADER
	#Therefore positions [3] -> [15] represent the intervals req'd FOR extraction
	#                                                              TO the REPORT.
	LET modu_rec_interval[15].int_text = p_rec_statint.int_text 
	LET modu_rec_interval[15].year_num = p_rec_statint.year_num 
	LET modu_rec_interval[15].int_num = p_rec_statint.int_num 
	FOR i = 14 TO 1 step -1 
		SELECT * INTO l_rec_statint.* FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = glob_rec_statparms.mth_type_code 
		AND end_date = p_rec_statint.start_date - 1 
		IF status = NOTFOUND THEN 
			LET modu_rec_interval[i].int_text = " n/a" 
			LET modu_rec_interval[i].year_num = 0 
			LET modu_rec_interval[i].int_num = 0 
		ELSE 
			LET modu_rec_interval[i].int_text = l_rec_statint.int_text 
			LET modu_rec_interval[i].year_num = l_rec_statint.year_num 
			LET modu_rec_interval[i].int_num = l_rec_statint.int_num 
			LET p_rec_statint.start_date = l_rec_statint.start_date 
		END IF 
	END FOR 
END FUNCTION 
###########################################################################
# END FUNCTION EW2_build_interval(p_rec_statint) 
###########################################################################


###########################################################################
# REPORT EW2_rpt_list(p_rec_rep_distterr) 
#
# 
###########################################################################
REPORT EW2_rpt_list(p_rpt_idx,p_rec_rep_distterr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_rep_distterr RECORD 
		area_code LIKE distterr.area_code, 
		maingrp_code LIKE distterr.maingrp_code, 
		prodgrp_code LIKE distterr.prodgrp_code, 
		part_code LIKE distterr.part_code, 
		qtr_net_amt LIKE distterr.qtr_net_amt, 
		net_amt1 LIKE distterr.qtr_net_amt, 
		net_amt2 LIKE distterr.qtr_net_amt, 
		net_amt3 LIKE distterr.qtr_net_amt, 
		net_amt4 LIKE distterr.qtr_net_amt, 
		net_amt5 LIKE distterr.qtr_net_amt, 
		net_amt6 LIKE distterr.qtr_net_amt, 
		net_amt7 LIKE distterr.qtr_net_amt, 
		net_amt8 LIKE distterr.qtr_net_amt, 
		net_amt9 LIKE distterr.qtr_net_amt, 
		net_amt10 LIKE distterr.qtr_net_amt, 
		net_amt11 LIKE distterr.qtr_net_amt, 
		net_amt12 LIKE distterr.qtr_net_amt, 
		net_amt13 LIKE distterr.qtr_net_amt 
	END RECORD 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	OUTPUT 

	ORDER BY 
		p_rec_rep_distterr.area_code, 
		p_rec_rep_distterr.maingrp_code, 
		p_rec_rep_distterr.prodgrp_code, 
		p_rec_rep_distterr.part_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[1,43]; 
			FOR j = 1 TO 12 
				PRINT modu_rec_interval[j].int_text; 
			END FOR 
			PRINT COLUMN 128,modu_rec_interval[13].int_text 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text[1,43]; 
			FOR j = 3 TO 14 
				PRINT modu_rec_interval[j].int_text; 
			END FOR 
			PRINT COLUMN 128,modu_rec_interval[15].int_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			SELECT desc_text INTO l_desc_text FROM salearea 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND area_code = p_rec_rep_distterr.area_code 

			PRINT COLUMN 01,"Sales Area: ", 
			COLUMN 13,p_rec_rep_distterr.area_code, 
			COLUMN 19,l_desc_text 
			SKIP 1 line 
			
		BEFORE GROUP OF p_rec_rep_distterr.area_code 
			SKIP TO top OF PAGE 
			
		AFTER GROUP OF p_rec_rep_distterr.part_code 
			NEED 3 LINES 
			IF modu_rec_criteria.part_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_rep_distterr.part_code 
				PRINT COLUMN 07,p_rec_rep_distterr.part_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distterr.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distterr.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distterr.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distterr.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distterr.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distterr.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distterr.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distterr.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distterr.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distterr.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distterr.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distterr.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distterr.net_amt13) USING "------&" 
			END IF 
			
		AFTER GROUP OF p_rec_rep_distterr.prodgrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.pgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_rep_distterr.prodgrp_code 
				PRINT COLUMN 05,"Prod group:", 
				COLUMN 16,p_rec_rep_distterr.prodgrp_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distterr.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distterr.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distterr.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distterr.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distterr.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distterr.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distterr.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distterr.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distterr.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distterr.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distterr.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distterr.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distterr.net_amt13) USING "------&" 
				SKIP 1 line 
			END IF
			 
		AFTER GROUP OF p_rec_rep_distterr.maingrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.mgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_rep_distterr.maingrp_code 
				PRINT COLUMN 03,"Main group:", 
				COLUMN 14,p_rec_rep_distterr.maingrp_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distterr.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distterr.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distterr.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distterr.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distterr.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distterr.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distterr.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distterr.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distterr.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distterr.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distterr.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distterr.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distterr.net_amt13) USING "------&" 
				SKIP 1 line 
			END IF 
		AFTER GROUP OF p_rec_rep_distterr.area_code 
			NEED 4 LINES 
			PRINT COLUMN 01,"Area summary:", 
			COLUMN 42,group sum(p_rec_rep_distterr.net_amt1) USING "------&", 
			COLUMN 49,group sum(p_rec_rep_distterr.net_amt2) USING "------&", 
			COLUMN 56,group sum(p_rec_rep_distterr.net_amt3) USING "------&", 
			COLUMN 63,group sum(p_rec_rep_distterr.net_amt4) USING "------&", 
			COLUMN 70,group sum(p_rec_rep_distterr.net_amt5) USING "------&", 
			COLUMN 77,group sum(p_rec_rep_distterr.net_amt6) USING "------&", 
			COLUMN 84,group sum(p_rec_rep_distterr.net_amt7) USING "------&", 
			COLUMN 91,group sum(p_rec_rep_distterr.net_amt8) USING "------&", 
			COLUMN 98,group sum(p_rec_rep_distterr.net_amt9) USING "------&", 
			COLUMN 105,group sum(p_rec_rep_distterr.net_amt10) USING "------&", 
			COLUMN 112,group sum(p_rec_rep_distterr.net_amt11) USING "------&", 
			COLUMN 119,group sum(p_rec_rep_distterr.net_amt12) USING "------&", 
			COLUMN 126,group sum(p_rec_rep_distterr.net_amt13) USING "------&" 
			SKIP 1 line 
			
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
# END REPORT EW2_rpt_list(p_rec_rep_distterr) 
###########################################################################