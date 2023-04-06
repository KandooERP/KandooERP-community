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
GLOBALS "../eo/EY_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EY2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################

DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_rec_criteria RECORD 
		part_ind char(1), 
		pgrp_ind char(1), 
		mgrp_ind char(1) 
	END RECORD 
DEFINE modu_arr_rec_interval array[15] OF RECORD 
		int_text char(7), 
		year_num LIKE statint.year_num, 
		int_num LIKE statint.int_num 
	END RECORD
DEFINE modu_sper_where_text char(50) 
DEFINE modu_temp_text STRING 

###########################################################################
# FUNCTION EY2_main()
#
# EY2 - Company Distribution Report
###########################################################################
FUNCTION EY2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EY2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW E286 with FORM "E286" 
			 CALL windecoration_e("E286") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text 
			
			MENU " Company Distribution trends" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EY2","menu-Company-1") -- albo kd-502 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
				
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL EY2_rpt_process(EY2_rpt_query()) 
		
				ON ACTION "PRINT MANAGER" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E286

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EY2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E286 with FORM "E286" 
			 CALL windecoration_e("E286") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EY2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E286 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EY2_rpt_process(get_url_sel_text())
	END CASE 			
	 
END FUNCTION 
###########################################################################
# END FUNCTION EY2_main()
###########################################################################

###########################################################################
# FUNCTION EY2_rpt_query() 
#
#Note: This report does not use any construct  
###########################################################################
FUNCTION EY2_rpt_query()

	IF EY2_enter_year() = FALSE THEN
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

		LET glob_rec_rpt_selector.ref4_ind = modu_rec_criteria.part_ind
		LET glob_rec_rpt_selector.ref5_ind = modu_rec_criteria.pgrp_ind
		LET glob_rec_rpt_selector.ref6_ind = modu_rec_criteria.mgrp_ind
		
		RETURN modu_sper_where_text
	END IF
END FUNCTION 
###########################################################################
# END FUNCTION EY2_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION EY2_rpt_process(p_where_text)  
#
# 
###########################################################################
FUNCTION EY2_rpt_process(p_where_text) 
	DEFINE p_where_text CHAR(50)
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_rep_distsper RECORD 
		cmpy_code LIKE distsper.cmpy_code, 
		maingrp_code LIKE distsper.maingrp_code, 
		prodgrp_code LIKE distsper.prodgrp_code, 
		part_code LIKE distsper.part_code, 
		qtr_net_amt LIKE distsper.qtr_net_amt, 
		net_amt1 LIKE distsper.qtr_net_amt, 
		net_amt2 LIKE distsper.qtr_net_amt, 
		net_amt3 LIKE distsper.qtr_net_amt, 
		net_amt4 LIKE distsper.qtr_net_amt, 
		net_amt5 LIKE distsper.qtr_net_amt, 
		net_amt6 LIKE distsper.qtr_net_amt, 
		net_amt7 LIKE distsper.qtr_net_amt, 
		net_amt8 LIKE distsper.qtr_net_amt, 
		net_amt9 LIKE distsper.qtr_net_amt, 
		net_amt10 LIKE distsper.qtr_net_amt, 
		net_amt11 LIKE distsper.qtr_net_amt, 
		net_amt12 LIKE distsper.qtr_net_amt, 
		net_amt13 LIKE distsper.qtr_net_amt 
	END RECORD 
	DEFINE i SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EY1_rpt_list_product",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT EY1_rpt_list_product TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text

	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_criteria.part_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_ind
	LET modu_rec_criteria.pgrp_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref5_ind
	LET modu_rec_criteria.mgrp_ind = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref6_ind

	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_ind
	#------------------------------------------------------------		


	CALL EY2_build_interval(modu_rec_statint.*) 

	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",modu_sper_where_text clipped 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 

	LET l_query_text = 
		"SELECT cmpy_code,maingrp_code,prodgrp_code, ", 
		"part_code,qtr_net_amt FROM distsper ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND sale_code = ?", 
		"AND part_code IS NOT NULL ", 
		"AND year_num = ? ", 
		"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
		"AND int_num = ? ", 
		"ORDER BY cmpy_code,maingrp_code,prodgrp_code,part_code" 
	PREPARE s_distsper FROM l_query_text 
	DECLARE c_distsper cursor FOR s_distsper 

	MESSAGE kandoomsg2("E",1045,"") #1045 Reporting on Salesperson...

	FOREACH c_salesperson INTO l_rec_salesperson.* 


		#This loop represents the 13 net amounts across the REPORT
		FOR i = 1 TO 13 
			OPEN c_distsper USING l_rec_salesperson.sale_code, 
			modu_arr_rec_interval[i+2].year_num, 
			modu_arr_rec_interval[i+2].int_num 
			
			FOREACH c_distsper INTO l_rec_rep_distsper.* 
				#init all - so that group sum will NOT RETURN NULL
				LET l_rec_rep_distsper.net_amt1 = 0 
				LET l_rec_rep_distsper.net_amt2 = 0 
				LET l_rec_rep_distsper.net_amt3 = 0 
				LET l_rec_rep_distsper.net_amt4 = 0 
				LET l_rec_rep_distsper.net_amt5 = 0 
				LET l_rec_rep_distsper.net_amt6 = 0 
				LET l_rec_rep_distsper.net_amt7 = 0 
				LET l_rec_rep_distsper.net_amt8 = 0 
				LET l_rec_rep_distsper.net_amt9 = 0 
				LET l_rec_rep_distsper.net_amt10 = 0 
				LET l_rec_rep_distsper.net_amt11 = 0 
				LET l_rec_rep_distsper.net_amt12 = 0 
				LET l_rec_rep_distsper.net_amt13 = 0 
				CASE i 
					WHEN 1 
						LET l_rec_rep_distsper.net_amt1 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 2 
						LET l_rec_rep_distsper.net_amt2 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 3 
						LET l_rec_rep_distsper.net_amt3 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 4 
						LET l_rec_rep_distsper.net_amt4 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 5 
						LET l_rec_rep_distsper.net_amt5 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 6 
						LET l_rec_rep_distsper.net_amt6 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 7 
						LET l_rec_rep_distsper.net_amt7 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 8 
						LET l_rec_rep_distsper.net_amt8 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 9 
						LET l_rec_rep_distsper.net_amt9 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 10 
						LET l_rec_rep_distsper.net_amt10 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 11 
						LET l_rec_rep_distsper.net_amt11 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 12 
						LET l_rec_rep_distsper.net_amt12 = l_rec_rep_distsper.qtr_net_amt 
					WHEN 13 
						LET l_rec_rep_distsper.net_amt13 = l_rec_rep_distsper.qtr_net_amt 
				END CASE 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT EY2_rpt_list_product(l_rpt_idx,
				l_rec_rep_distsper.*)				
				IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------

			END FOREACH 
		END FOR 

	END FOREACH 

	FINISH REPORT EY2_rpt_list_product
	CALL rpt_finish("EY2_rpt_list_product")
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
# END FUNCTION EY2_rpt_process(p_where_text)  
###########################################################################


###########################################################################
# FUNCTION EY2_enter_year() 
#
# 
###########################################################################
FUNCTION EY2_enter_year() 
	DEFINE l_pseudo_flag char(1) 
	DEFINE l_primary_flag char(1) 
	DEFINE l_normal_flag char(1) 

	LET modu_rec_criteria.part_ind = xlate_to("Y") 
	LET modu_rec_criteria.pgrp_ind = xlate_to("Y") 
	LET modu_rec_criteria.mgrp_ind = xlate_to("Y") 
	LET l_pseudo_flag = xlate_to("Y") 
	LET l_primary_flag = xlate_to("Y") 
	LET l_normal_flag = xlate_to("Y") 
	LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
	LET modu_rec_statint.int_num = glob_rec_statparms.mth_num
	 
	DISPLAY glob_rec_company.cmpy_code TO cmpy_code 
	DISPLAY glob_rec_company.name_text TO name_text

	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_rec_criteria.part_ind, 
		modu_rec_criteria.pgrp_ind, 
		modu_rec_criteria.mgrp_ind, 
		l_pseudo_flag, 
		l_primary_flag, 
		l_normal_flag WITHOUT DEFAULTS 
	FROM
		year_num, 
		int_text, 
		part_ind, 
		pgrp_ind, 
		mgrp_ind, 
		pseudo_flag, 
		primary_flag, 
		normal_flag
	ATTRIBUTE(UNBUFFERED)
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EY2","input-year_num-1") -- albo kd-502 

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

		ON ACTION "YEAR+1" ----		ON KEY (f10) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
			NEXT FIELD year_num 

		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 
			
			DISPLAY modu_rec_statint.int_text TO int_text
			DISPLAY modu_rec_statint.start_date TO start_date 
			DISPLAY modu_rec_statint.end_date TO end_date

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 				#9210 Year number must be entered
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
				ERROR kandoomsg2("E",9222,"") 		#9222 Interval must be entered"
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
					ERROR kandoomsg2("E",9223,"") 		#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			
			DISPLAY modu_rec_statint.start_date TO start_date 
			DISPLAY modu_rec_statint.end_date TO end_date 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_primary_flag = "N" 
				AND l_pseudo_flag = "N" 
				AND l_normal_flag = "N" THEN 
					ERROR kandoomsg2("E",1132,"") 	#1132 All Salesperson Types have been excluded "
					NEXT FIELD l_primary_flag 
				END IF 
				IF l_pseudo_flag = "Y" THEN 
					LET modu_sper_where_text = " '1'" 
				END IF 
				IF l_primary_flag = "Y" THEN 
					LET modu_sper_where_text = modu_sper_where_text clipped,",'2'" 
				END IF 
				IF l_normal_flag = "Y" THEN 
					LET modu_sper_where_text = modu_sper_where_text clipped,",'3'" 
				END IF 
				LET modu_sper_where_text[1,1] = " " 
				LET modu_sper_where_text = "salesperson.sale_type_ind in (",	modu_sper_where_text clipped,")" 
			END IF 

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
# END FUNCTION EY2_enter_year() 
###########################################################################


###########################################################################
# FUNCTION EY2_build_interval(p_rec_statint)
#
# 
###########################################################################
FUNCTION EY2_build_interval(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE i SMALLINT 

	#position [15] represents current interval
	#position [1] AND [2] are only used FOR DISPLAY of int_text in PAGE HEADER
	#Therefore positions [3] -> [15] represent the intervals req'd FOR extraction
	#                                                              TO the REPORT.
	LET modu_arr_rec_interval[15].int_text = p_rec_statint.int_text 
	LET modu_arr_rec_interval[15].year_num = p_rec_statint.year_num 
	LET modu_arr_rec_interval[15].int_num = p_rec_statint.int_num 
	
	FOR i = 14 TO 1 step -1 
		SELECT * INTO l_rec_statint.* FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = glob_rec_statparms.mth_type_code 
		AND end_date = p_rec_statint.start_date - 1 

		IF status = NOTFOUND THEN 
			LET modu_arr_rec_interval[i].int_text = " n/a" 
			LET modu_arr_rec_interval[i].year_num = 0 
			LET modu_arr_rec_interval[i].int_num = 0 
		ELSE 
			LET modu_arr_rec_interval[i].int_text = l_rec_statint.int_text 
			LET modu_arr_rec_interval[i].year_num = l_rec_statint.year_num 
			LET modu_arr_rec_interval[i].int_num = l_rec_statint.int_num 
			LET p_rec_statint.start_date = l_rec_statint.start_date 
		END IF 
	END FOR 
END FUNCTION 
###########################################################################
# END FUNCTION EY2_main()
###########################################################################


###########################################################################
# REPORT EY2_rpt_list(p_rpt_idx,p_rec_rep_distsper)
#
# 
###########################################################################
REPORT EY2_rpt_list(p_rpt_idx,p_rec_rep_distsper) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_rep_distsper RECORD 
		cmpy_code LIKE distsper.cmpy_code, 
		maingrp_code LIKE distsper.maingrp_code, 
		prodgrp_code LIKE distsper.prodgrp_code, 
		part_code LIKE distsper.part_code, 
		qtr_net_amt LIKE distsper.qtr_net_amt, 
		net_amt1 LIKE distsper.qtr_net_amt, 
		net_amt2 LIKE distsper.qtr_net_amt, 
		net_amt3 LIKE distsper.qtr_net_amt, 
		net_amt4 LIKE distsper.qtr_net_amt, 
		net_amt5 LIKE distsper.qtr_net_amt, 
		net_amt6 LIKE distsper.qtr_net_amt, 
		net_amt7 LIKE distsper.qtr_net_amt, 
		net_amt8 LIKE distsper.qtr_net_amt, 
		net_amt9 LIKE distsper.qtr_net_amt, 
		net_amt10 LIKE distsper.qtr_net_amt, 
		net_amt11 LIKE distsper.qtr_net_amt, 
		net_amt12 LIKE distsper.qtr_net_amt, 
		net_amt13 LIKE distsper.qtr_net_amt 
	END RECORD 
 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	OUTPUT 
 
	ORDER BY p_rec_rep_distsper.cmpy_code, 
	p_rec_rep_distsper.maingrp_code, 
	p_rec_rep_distsper.prodgrp_code, 
	p_rec_rep_distsper.part_code 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[1,43]; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].int_text; 
			END FOR 
			PRINT COLUMN 128,modu_arr_rec_interval[13].int_text 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text[1,43]; 
			FOR j = 3 TO 14 
				PRINT modu_arr_rec_interval[j].int_text; 
			END FOR 
			PRINT COLUMN 128,modu_arr_rec_interval[15].int_text 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		AFTER GROUP OF p_rec_rep_distsper.part_code 
			NEED 3 LINES 
			IF modu_rec_criteria.part_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_rep_distsper.part_code 
				PRINT COLUMN 07,p_rec_rep_distsper.part_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distsper.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distsper.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distsper.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distsper.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distsper.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distsper.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distsper.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distsper.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distsper.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distsper.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distsper.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distsper.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distsper.net_amt13) USING "------&" 
			END IF 

		AFTER GROUP OF p_rec_rep_distsper.prodgrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.pgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_rep_distsper.prodgrp_code 
				PRINT COLUMN 05,"Prod group:", 
				COLUMN 16,p_rec_rep_distsper.prodgrp_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distsper.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distsper.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distsper.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distsper.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distsper.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distsper.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distsper.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distsper.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distsper.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distsper.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distsper.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distsper.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distsper.net_amt13) USING "------&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_rep_distsper.maingrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.mgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_rep_distsper.maingrp_code 
				PRINT COLUMN 03,"Main group:", 
				COLUMN 10,p_rec_rep_distsper.maingrp_code, 
				COLUMN 23,l_desc_text[1,18], 
				COLUMN 42,group sum(p_rec_rep_distsper.net_amt1) USING "------&", 
				COLUMN 49,group sum(p_rec_rep_distsper.net_amt2) USING "------&", 
				COLUMN 56,group sum(p_rec_rep_distsper.net_amt3) USING "------&", 
				COLUMN 63,group sum(p_rec_rep_distsper.net_amt4) USING "------&", 
				COLUMN 70,group sum(p_rec_rep_distsper.net_amt5) USING "------&", 
				COLUMN 77,group sum(p_rec_rep_distsper.net_amt6) USING "------&", 
				COLUMN 84,group sum(p_rec_rep_distsper.net_amt7) USING "------&", 
				COLUMN 91,group sum(p_rec_rep_distsper.net_amt8) USING "------&", 
				COLUMN 98,group sum(p_rec_rep_distsper.net_amt9) USING "------&", 
				COLUMN 105,group sum(p_rec_rep_distsper.net_amt10) USING "------&", 
				COLUMN 112,group sum(p_rec_rep_distsper.net_amt11) USING "------&", 
				COLUMN 119,group sum(p_rec_rep_distsper.net_amt12) USING "------&", 
				COLUMN 126,group sum(p_rec_rep_distsper.net_amt13) USING "------&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_rep_distsper.cmpy_code 
			NEED 6 LINES 
			SKIP 1 line 
			PRINT COLUMN 01,"Company summary:", 
			COLUMN 42,group sum(p_rec_rep_distsper.net_amt1) USING "------&", 
			COLUMN 49,group sum(p_rec_rep_distsper.net_amt2) USING "------&", 
			COLUMN 56,group sum(p_rec_rep_distsper.net_amt3) USING "------&", 
			COLUMN 63,group sum(p_rec_rep_distsper.net_amt4) USING "------&", 
			COLUMN 70,group sum(p_rec_rep_distsper.net_amt5) USING "------&", 
			COLUMN 77,group sum(p_rec_rep_distsper.net_amt6) USING "------&", 
			COLUMN 84,group sum(p_rec_rep_distsper.net_amt7) USING "------&", 
			COLUMN 91,group sum(p_rec_rep_distsper.net_amt8) USING "------&", 
			COLUMN 98,group sum(p_rec_rep_distsper.net_amt9) USING "------&", 
			COLUMN 105,group sum(p_rec_rep_distsper.net_amt10) USING "------&", 
			COLUMN 112,group sum(p_rec_rep_distsper.net_amt11) USING "------&", 
			COLUMN 119,group sum(p_rec_rep_distsper.net_amt12) USING "------&", 
			COLUMN 126,group sum(p_rec_rep_distsper.net_amt13) USING "------&" 
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
# END REPORT EY2_rpt_list(p_rpt_idx,p_rec_rep_distsper)
###########################################################################