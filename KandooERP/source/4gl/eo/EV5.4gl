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
GLOBALS "../eo/EV_GROUP_GLOBALS.4gl"
GLOBALS "../eo/EV5_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
########################################################################### 
DEFINE modu_rec_criteria RECORD 
		part_ind char(1), 
		pgrp_ind char(1), 
		mgrp_ind char(1) 
	END RECORD 
DEFINE modu_start_date1 DATE
DEFINE modu_start_date2 DATE
DEFINE modu_end_date1 DATE
DEFINE modu_end_date2 DATE 
DEFINE modu_int_text1 LIKE statint.int_text 
DEFINE modu_int_text2 LIKE statint.int_text
DEFINE modu_temp_text STRING
###########################################################################
# FUNCTION EV5_main()
#
# EV5 Customer/Inventory Sales by Product OR
#                                         Product Group OR
#                                         Main Group
#  ** There IS also a modified version of EV5_show_interval included in this
#     REPORT returning int_text instead of int_num
###########################################################################
FUNCTION EV5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EV5") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		 
			OPEN WINDOW E284 with FORM "E284" 
			 CALL windecoration_e("E284") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			DISPLAY getmenuitemlabel(NULL) TO header_text
			
			MENU " Customer sales" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EV5","menu-Customer-1") -- albo kd-502
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV5_rpt_process(EV5_rpt_query())
							 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null)
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										 
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV5_rpt_process(EV5_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW E284
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EV5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E284 with FORM "E284" 
			 CALL windecoration_e("E284") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EV5_rpt_query()) #save where clause in env 
			CLOSE WINDOW E284 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EV5_rpt_process(get_url_sel_text())
	END CASE 				 
END FUNCTION 
###########################################################################
# END FUNCTION EV5_main()
###########################################################################


###########################################################################
# FUNCTION EV5_rpt_query() 
#
#
########################################################################### 
FUNCTION EV5_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("E",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	type_code, 
	sale_code, 
	territory_code, 
	cond_code, 
	city_text, 
	state_code, 
	post_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EV5","construct-cust_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
--		LET glob_rec_rpt_selector.ref5_ind = modu_order_ind	
--		LET glob_rec_rpt_selector.ref6_ind = modu_zero_stats_flag	
		LET glob_rec_rpt_selector.ref5_num = glob_rec_statparms.year_num
		
		LET glob_rec_rpt_selector.ref3_date = modu_start_date1
		LET glob_rec_rpt_selector.ref4_date = modu_start_date2 
		LET glob_rec_rpt_selector.ref5_date = modu_end_date1 
		LET glob_rec_rpt_selector.ref6_date = modu_end_date2  
		LET glob_rec_rpt_selector.ref5_code = modu_int_text1 
		LET glob_rec_rpt_selector.ref6_code = modu_int_text2 

		LET glob_rec_rpt_selector.ref4_ind = modu_rec_criteria.part_ind
		LET glob_rec_rpt_selector.ref5_ind = modu_rec_criteria.pgrp_ind
		LET glob_rec_rpt_selector.ref6_ind = modu_rec_criteria.mgrp_ind
			
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION EV5_rpt_query() 
########################################################################### 


############################################################
# FUNCTION EV5_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EV5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_cur_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_prv_statsale RECORD LIKE statsale.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EV5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EV5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
--	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_ind
--	LET modu_zero_stats_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref6_ind
	LET glob_rec_statparms.year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_num 

	LET modu_start_date1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref3_date
	LET modu_start_date2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref4_date
	LET modu_end_date1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_date
	LET modu_end_date2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref6_date
		
	LET modu_int_text1 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_code
	LET modu_int_text2 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref6_code

	LET modu_rec_criteria.part_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref4_ind
	LET modu_rec_criteria.pgrp_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_ind
	LET modu_rec_criteria.mgrp_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref6_ind
	#------------------------------------------------------------

	LET l_query_text = "SELECT * FROM customer", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND delete_flag = 'N' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].sel_text clipped," ",
	"ORDER BY cmpy_code, cond_code, cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer 
	
	LET l_query_text = 
	"SELECT statsale.* FROM statsale,statint ", 
	"WHERE statsale.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND statint.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND statsale.type_code = '",glob_rec_statparms.mth_type_code,"' ", 
	"AND statint.type_code = statsale.type_code ", 
	"AND statint.year_num = statsale.year_num ", 
	"AND statint.int_num = statsale.int_num ", 
	"AND statsale.cust_code = ? ", 
	"AND statint.start_date between ? AND ? ", 
	"AND part_code IS NOT NULL ", 
	"ORDER BY cust_code,maingrp_code,prodgrp_code,part_code" 
	PREPARE s_statsale FROM l_query_text 
	DECLARE c_statsale cursor FOR s_statsale 

	MESSAGE kandoomsg2("E",1160,"") #1160 Reporting on Customer...
	# The DISPLAY statement IS within the FOREACH TO DISPLAY customers that
	# have statistics instead of all

	FOREACH c_customer INTO l_rec_customer.* 
		OPEN c_statsale USING l_rec_customer.cust_code, 
		modu_start_date1, 
		modu_end_date1 
		FOREACH c_statsale INTO l_rec_cur_statsale.* 
			LET l_rec_prv_statsale.* = l_rec_cur_statsale.* 
			LET l_rec_prv_statsale.gross_amt = 0 
			LET l_rec_prv_statsale.net_amt = 0 
			LET l_rec_prv_statsale.cost_amt = 0 
			#---------------------------------------------------------
			OUTPUT TO REPORT EV5_rpt_list(l_rpt_idx,
			l_rec_cur_statsale.*,l_rec_prv_statsale.*) 
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.name_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	

		END FOREACH 

		OPEN c_statsale USING l_rec_customer.cust_code, 
		modu_start_date2, 
		modu_end_date2 
		
		FOREACH c_statsale INTO l_rec_prv_statsale.* 
			LET l_rec_cur_statsale.* = l_rec_prv_statsale.* 
			LET l_rec_cur_statsale.gross_amt = 0 
			LET l_rec_cur_statsale.net_amt = 0 
			LET l_rec_cur_statsale.cost_amt = 0 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT EV5_rpt_list(l_rpt_idx,
			l_rec_cur_statsale.*,l_rec_prv_statsale.*)
			IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.name_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
			 
		END FOREACH 
	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT EV5_rpt_list
	CALL rpt_finish("EV5_rpt_list")
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
# END FUNCTION EV5_rpt_process(p_where_text) 
############################################################


###########################################################################
# FUNCTION EV5_enter_year() 
#
#
########################################################################### 
FUNCTION EV5_enter_year() 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_s_statint RECORD LIKE statint.* 

	LET modu_rec_criteria.part_ind = xlate_to("Y") 
	LET modu_rec_criteria.pgrp_ind = xlate_to("Y") 
	LET modu_rec_criteria.mgrp_ind = xlate_to("Y")
	 
	LET l_rec_statint.year_num = glob_rec_statparms.year_num 
	LET l_rec_statint.int_num = glob_rec_statparms.mth_num
	 
	MESSAGE kandoomsg2("E",1060,"") 	#1060 Enter year FOR REPORT run - ESC TO Continue

	CALL disp_dates(l_rec_statint.*) 
	INPUT
		modu_int_text1, 
		modu_int_text2, 
		modu_rec_criteria.part_ind, 
		modu_rec_criteria.pgrp_ind, 
		modu_rec_criteria.mgrp_ind WITHOUT DEFAULTS 
	FROM
		int_text1, 
		int_text2, 
		part_ind, 
		pgrp_ind, 
		mgrp_ind
	ATTRIBUTE(UNBUFFERED)
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EV5","input-modu_int_text1-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(modu_int_text1)  
				LET modu_temp_text = EV5_show_interval() 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_int_text1 = modu_temp_text 
					NEXT FIELD modu_int_text1 
				END IF 

			IF infield(modu_int_text2) THEN 
				LET modu_temp_text = EV5_show_interval() 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_int_text2 = modu_temp_text 
					NEXT FIELD modu_int_text2 
				END IF 
			END IF 

		AFTER FIELD modu_int_text1 
			IF modu_int_text1 IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 				#9222 Interval must be entered"
				NEXT FIELD modu_int_text1 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_statparms.mth_type_code 
				AND int_text = modu_int_text1 
				OPEN c_interval 
				FETCH c_interval INTO l_rec_statint.* 
				
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 		#9223 Interval does NOT exist - Try Window"
					NEXT FIELD modu_int_text1 
				ELSE 
					LET modu_start_date1 = l_rec_statint.start_date 
					SELECT * INTO l_rec_s_statint.* FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_rec_statint.year_num - 1 
					AND type_code = glob_rec_statparms.mth_type_code 
					AND int_num = l_rec_statint.int_num 
					IF status = NOTFOUND THEN 
						LET modu_start_date2 = l_rec_statint.start_date - 365 
					ELSE 
						LET modu_start_date2 = l_rec_s_statint.start_date 
					END IF 
					DISPLAY BY NAME modu_start_date1, 
					modu_start_date2 

				END IF 
			END IF 

		AFTER FIELD modu_int_text2 
			IF modu_int_text2 IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 		#9222 Interval must be entered"
				NEXT FIELD modu_int_text2 
			ELSE 
				DECLARE c_interval2 cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_statparms.mth_type_code 
				AND int_text = modu_int_text2 
				OPEN c_interval2 
				FETCH c_interval2 INTO l_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 	#9223 Interval does NOT exist - Try Window"
					NEXT FIELD modu_int_text2 
				ELSE 
					LET modu_end_date1 = l_rec_statint.end_date 
					SELECT * INTO l_rec_s_statint.* FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = l_rec_statint.year_num - 1 
					AND type_code = glob_rec_statparms.mth_type_code 
					AND int_num = l_rec_statint.int_num 
					IF status = NOTFOUND THEN 
						LET modu_end_date2 = l_rec_statint.end_date - 365 
					ELSE 
						LET modu_end_date2 = l_rec_s_statint.end_date 
					END IF 
					DISPLAY BY NAME modu_end_date1, 
					modu_end_date2 
				END IF 
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
# END FUNCTION EV5_enter_year() 
########################################################################### 


###########################################################################
# FUNCTION disp_dates(p_rec_statint) 
#
#
########################################################################### 
FUNCTION disp_dates(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_s_statint RECORD LIKE statint.* 

	#SELECT last years interval
	SELECT * INTO p_rec_statint.* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = p_rec_statint.year_num - 1 
	AND type_code = glob_rec_statparms.mth_type_code 
	AND int_num = p_rec_statint.int_num 
	LET modu_end_date2 = p_rec_statint.end_date 
	
	#SELECT last years interval minus one month.... ie JUL93 - JUN94
	SELECT * INTO p_rec_statint.* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = p_rec_statint.year_num 
	AND type_code = p_rec_statint.type_code 
	AND start_date = p_rec_statint.end_date + 1 
	LET modu_int_text1 = p_rec_statint.int_text 
	LET modu_start_date1 = p_rec_statint.start_date 
	#
	#SELECT current interval
	SELECT * INTO l_rec_s_statint.* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = glob_rec_statparms.year_num 
	AND type_code = glob_rec_statparms.mth_type_code 
	AND int_num = glob_rec_statparms.mth_num 
	LET modu_int_text2 = l_rec_s_statint.int_text 
	LET modu_end_date1 = l_rec_s_statint.end_date 
	
	#SELECT last years interval minus One Year FOR comparisons
	SELECT * INTO p_rec_statint.* FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = p_rec_statint.year_num - 1 
	AND type_code = p_rec_statint.type_code 
	AND int_num = p_rec_statint.int_num 
	LET modu_start_date2 = p_rec_statint.start_date 
	DISPLAY BY NAME modu_int_text1, 
	modu_int_text2, 
	modu_start_date1, 
	modu_end_date1, 
	modu_start_date2, 
	modu_end_date2 

END FUNCTION 
###########################################################################
# END FUNCTION disp_dates(p_rec_statint) 
########################################################################### 


###########################################################################
# FUNCTION EV5_show_interval()  
#
#
########################################################################### 
FUNCTION EV5_show_interval() 
	#This FUNCTION has been cloned FROM intvwind.4gl so it can RETURN
	#int_text instead of int_num
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_rec_statint array[100] OF RECORD 
		scroll_flag char(1), 
		int_num LIKE statint.int_num, 
		int_text LIKE statint.int_text, 
		start_date LIKE statint.start_date, 
		end_date LIKE statint.end_date 
	END RECORD 
	--DEFINE scrn SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 

	OPTIONS INSERT KEY F36, 
	DELETE KEY F36 
	OPEN WINDOW E213 with FORM "E213" 

	 CALL windecoration_e("E213") -- albo kd-755 
	WHILE TRUE 
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON int_num, 
		int_text, 
		start_date, 
		end_date 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EV5","construct-int_num-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_statint.int_text = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("E",1002,"") #1002 " Searching database - please wait"

		LET l_query_text = "SELECT * FROM statint ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND type_code = '",glob_rec_statparms.mth_type_code,"'", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"year_num,", 
		"int_num" 

		PREPARE s_statint FROM l_query_text 
		DECLARE c_statint cursor FOR s_statint 
		LET l_idx = 0 
		
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statint[l_idx].int_num = l_rec_statint.int_num 
			LET l_arr_rec_statint[l_idx].int_text = l_rec_statint.int_text 
			LET l_arr_rec_statint[l_idx].start_date = l_rec_statint.start_date 
			LET l_arr_rec_statint[l_idx].end_date = l_rec_statint.end_date 
			IF l_idx = 100 THEN 
				ERROR kandoomsg2("E",9200,"100") 			#9200 First 100 Interval Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF l_idx = 0 THEN 
			ERROR kandoomsg2("E",9201,"") 		#9201" No Interval Satsified Selection Criteria
--			LET l_idx = 1 
--			INITIALIZE l_arr_rec_statint[1].* TO NULL 
		END IF 
		MESSAGE kandoomsg2("E",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"

		CALL set_count(l_idx) 

		--INPUT ARRAY l_arr_rec_statint WITHOUT DEFAULTS FROM sr_statint.* 
		DISPLAY ARRAY l_arr_rec_statint TO sr_statint.* 
			BEFORE DISPLAY
				CALL publish_toolbar("kandoo","EV5","input-arr-l_arr_rec_statint-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr()
				LET l_rec_statint.int_text = l_arr_rec_statint[l_idx].int_text  
	--			LET scrn = scr_line() 
--				IF l_arr_rec_statint[l_idx].int_num IS NOT NULL THEN 
--					DISPLAY l_arr_rec_statint[l_idx].* 
--					TO sr_statint[scrn].* 
--
--				END IF 
--				NEXT FIELD scroll_flag 

			ON KEY (f10) 
				CALL run_prog("U61","","","","") 
				NEXT FIELD scroll_flag 

--			AFTER FIELD scroll_flag 
--				LET l_arr_rec_statint[l_idx].scroll_flag = NULL 
--				IF fgl_lastkey() = fgl_keyval("down") 
--				AND arr_curr() >= arr_count() THEN 
--					ERROR kandoomsg2("E",9001,"") 
--					NEXT FIELD scroll_flag 
--				END IF 

--			BEFORE FIELD int_num 
--				LET l_rec_statint.int_text = l_arr_rec_statint[l_idx].int_text 
--				EXIT INPUT 

--			AFTER ROW 
--				DISPLAY l_arr_rec_statint[l_idx].* 
--				TO sr_statint[scrn].* 

			AFTER DISPLAY 
				LET l_rec_statint.int_text = l_arr_rec_statint[l_idx].int_text 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW E213
	 
	RETURN l_rec_statint.int_text 
END FUNCTION 
###########################################################################
# END FUNCTION EV5_show_interval()  
########################################################################### 


###########################################################################
# REPORT EV5_rpt_list(p_rec_cur_statsale,p_rec_prv_statsale)   
#
#
###########################################################################
REPORT EV5_rpt_list(p_rpt_idx,p_rec_cur_statsale,p_rec_prv_statsale) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_cur_statsale RECORD LIKE statsale.* 
	DEFINE p_rec_prv_statsale RECORD LIKE statsale.* 

	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_sper_name LIKE salesperson.name_text 
	DEFINE l_cond_desc LIKE condsale.desc_text 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_rank char(1) 
	DEFINE l_rank_amt LIKE statsale.net_amt 
	DEFINE l_grs_diff_per FLOAT
	DEFINE l_net_diff_per FLOAT
	DEFINE l_cur_disc_per FLOAT
	DEFINE l_prv_disc_per FLOAT
	 
	DEFINE l_disc_diff_per FLOAT
	DEFINE l_gp_diff_per FLOAT

	DEFINE l_total_grs_diff_per FLOAT
	DEFINE l_total_net_diff_per FLOAT
	DEFINE l_cur_total_disc_per FLOAT

	DEFINE l_prv_total_disc_per FLOAT
	DEFINE l_total_disc_diff_per FLOAT
	DEFINE l_total_gp_diff_per FLOAT

	DEFINE l_prv_gp LIKE statsale.net_amt
	DEFINE l_cur_gp LIKE statsale.net_amt

	DEFINE l_cur_total_gp LIKE statsale.net_amt
	DEFINE l_prv_total_gp LIKE statsale.net_amt

	DEFINE l_cur_total_gross_amt LIKE statsale.gross_amt
	DEFINE l_prv_total_gross_amt LIKE statsale.gross_amt
	DEFINE l_cur_total_net_amt LIKE statsale.net_amt
	DEFINE l_prv_total_net_amt LIKE statsale.net_amt
	DEFINE l_cur_total_cost_amt LIKE statsale.cost_amt
	DEFINE l_prv_total_cost_amt LIKE statsale.cost_amt
	DEFINE x SMALLINT 
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	 
	OUTPUT 
 
	ORDER BY p_rec_cur_statsale.cust_code, 
	p_rec_cur_statsale.maingrp_code, 
	p_rec_cur_statsale.prodgrp_code, 
	p_rec_cur_statsale.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 
			
			SELECT * INTO l_rec_customer.* FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_cur_statsale.cust_code 
			
			SELECT desc_text INTO l_cond_desc FROM condsale 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cond_code = l_rec_customer.cond_code
			 
			SELECT name_text INTO l_sper_name FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = l_rec_customer.sale_code
			 
			PRINT COLUMN 01,"Customer:", 
			COLUMN 11,l_rec_customer.cust_code, 
			COLUMN 20,l_rec_customer.name_text, 
			COLUMN 103," Current: ",modu_start_date1 USING "dd/mm/yy", 
			" TO ",modu_end_date1 USING "dd/mm/yy" 

			PRINT COLUMN 20,l_rec_customer.addr1_text, 
			COLUMN 103,"Previous: ",modu_start_date2 USING "dd/mm/yy", 
			" TO ",modu_end_date2 USING "dd/mm/yy" 

			IF l_rec_customer.addr2_text IS NULL THEN 
				IF l_rec_customer.city_text IS NULL THEN 
					PRINT COLUMN 20, l_rec_customer.state_code[1,3], 
					COLUMN 45, l_rec_customer.post_code[1,4]; 
				ELSE 
					PRINT COLUMN 20, l_rec_customer.city_text clipped," ", 
					l_rec_customer.state_code[1,3], 
					COLUMN 45, l_rec_customer.post_code[1,4]; 
				END IF 
			ELSE 
				PRINT COLUMN 20, l_rec_customer.addr2_text; 
			END IF 

			PRINT COLUMN 53,"Sales condition:", 
			COLUMN 70,l_rec_customer.cond_code, 
			COLUMN 79,l_cond_desc 

			IF l_rec_customer.addr2_text IS NOT NULL THEN 
				IF l_rec_customer.city_text IS NULL THEN 
					PRINT COLUMN 20, l_rec_customer.state_code[1,3], 
					COLUMN 45, l_rec_customer.post_code[1,4]; 
				ELSE 
					PRINT COLUMN 20, l_rec_customer.city_text clipped," ", 
					l_rec_customer.state_code[1,3], 
					COLUMN 45, l_rec_customer.post_code[1,4]; 
				END IF 
			END IF
			 
			PRINT COLUMN 53,"Salesperson:", 
			COLUMN 70,l_rec_customer.sale_code, 
			COLUMN 79,l_sper_name 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

--			PRINT COLUMN 01,pa_line[3] 
--			PRINT COLUMN 01,glob_rec_kandooreport.line1_text 
--			PRINT COLUMN 01,glob_rec_kandooreport.line2_text 
--			PRINT COLUMN 01,pa_line[3]
			 
		BEFORE GROUP OF p_rec_cur_statsale.cust_code 
			SKIP TO top OF PAGE
			 
		AFTER GROUP OF p_rec_cur_statsale.part_code 
			IF modu_rec_criteria.part_ind = "Y" THEN 
				NEED 3 LINES 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_cur_statsale.part_code 
				LET p_rec_cur_statsale.gross_amt = GROUP sum(p_rec_cur_statsale.gross_amt) 
				LET p_rec_cur_statsale.net_amt = GROUP sum(p_rec_cur_statsale.net_amt) 
				LET p_rec_cur_statsale.cost_amt = GROUP sum(p_rec_cur_statsale.cost_amt) 
				LET p_rec_prv_statsale.gross_amt = GROUP sum(p_rec_prv_statsale.gross_amt) 
				LET p_rec_prv_statsale.net_amt = GROUP sum(p_rec_prv_statsale.net_amt) 
				LET p_rec_prv_statsale.cost_amt = GROUP sum(p_rec_prv_statsale.cost_amt) 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_grs_diff_per = 0 
				ELSE 
					LET l_grs_diff_per = 100 * ((p_rec_cur_statsale.gross_amt - p_rec_prv_statsale.gross_amt) / p_rec_prv_statsale.gross_amt) 
				END IF 
				IF p_rec_prv_statsale.net_amt = 0 THEN 
					LET l_net_diff_per = 0 
				ELSE 
					LET l_net_diff_per = 100 * ((p_rec_cur_statsale.net_amt - p_rec_prv_statsale.net_amt) / p_rec_prv_statsale.net_amt) 
				END IF 
				IF p_rec_cur_statsale.gross_amt = 0 THEN 
					LET l_cur_disc_per = 0 
				ELSE 
					LET l_cur_disc_per = 100 * (1-(p_rec_cur_statsale.net_amt/p_rec_cur_statsale.gross_amt)) 
				END IF 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_prv_disc_per = 0 
				ELSE 
					LET l_prv_disc_per = 100 * (1-(p_rec_prv_statsale.net_amt/p_rec_prv_statsale.gross_amt)) 
				END IF 
				IF l_prv_disc_per = 0 THEN 
					LET l_disc_diff_per = 0 
				ELSE 
					LET l_disc_diff_per = 100 * ((l_cur_disc_per - l_prv_disc_per) / l_prv_disc_per) 
				END IF 
				
				LET l_cur_gp = p_rec_cur_statsale.net_amt	- p_rec_cur_statsale.cost_amt 
				LET l_prv_gp = p_rec_prv_statsale.net_amt	- p_rec_prv_statsale.cost_amt 
				IF l_prv_gp = 0 THEN 
					LET l_gp_diff_per = 0 
				ELSE 
					LET l_gp_diff_per = 100 * ((l_cur_gp - l_prv_gp) / l_prv_gp) 
				END IF
				 
				PRINT COLUMN 001,p_rec_cur_statsale.part_code, 
				COLUMN 017,l_desc_text, 
				COLUMN 048,p_rec_cur_statsale.gross_amt USING "------&", 
				COLUMN 056,p_rec_prv_statsale.gross_amt USING "------&", 
				COLUMN 063,l_grs_diff_per USING "----&.&", 
				COLUMN 070,p_rec_cur_statsale.net_amt USING "------&", 
				COLUMN 077,p_rec_prv_statsale.net_amt USING "------&", 
				COLUMN 084,l_net_diff_per USING "----&.&", 
				COLUMN 091,l_cur_disc_per USING "----&.&", 
				COLUMN 098,l_prv_disc_per USING "----&.&", 
				COLUMN 105,l_disc_diff_per USING "----&.&", 
				COLUMN 112,l_cur_gp USING "------&", 
				COLUMN 119,l_prv_gp USING "------&", 
				COLUMN 126,l_gp_diff_per USING "----&.&" 
			END IF
			 
		AFTER GROUP OF p_rec_cur_statsale.prodgrp_code 
			IF modu_rec_criteria.pgrp_ind = "Y" THEN 
				NEED 4 LINES 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_cur_statsale.prodgrp_code 
				LET p_rec_cur_statsale.gross_amt = GROUP sum(p_rec_cur_statsale.gross_amt) 
				LET p_rec_cur_statsale.net_amt = GROUP sum(p_rec_cur_statsale.net_amt) 
				LET p_rec_cur_statsale.cost_amt = GROUP sum(p_rec_cur_statsale.cost_amt) 
				LET p_rec_prv_statsale.gross_amt = GROUP sum(p_rec_prv_statsale.gross_amt) 
				LET p_rec_prv_statsale.net_amt = GROUP sum(p_rec_prv_statsale.net_amt) 
				LET p_rec_prv_statsale.cost_amt = GROUP sum(p_rec_prv_statsale.cost_amt) 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_grs_diff_per = 0 
				ELSE 
					LET l_grs_diff_per = 100 * ((p_rec_cur_statsale.gross_amt - p_rec_prv_statsale.gross_amt) / p_rec_prv_statsale.gross_amt) 
				END IF 
				IF p_rec_prv_statsale.net_amt = 0 THEN 
					LET l_net_diff_per = 0 
				ELSE 
					LET l_net_diff_per = 100 * ((p_rec_cur_statsale.net_amt - p_rec_prv_statsale.net_amt) / p_rec_prv_statsale.net_amt) 
				END IF 
				IF p_rec_cur_statsale.gross_amt = 0 THEN 
					LET l_cur_disc_per = 0 
				ELSE 
					LET l_cur_disc_per = 100 * (1-(p_rec_cur_statsale.net_amt/p_rec_cur_statsale.gross_amt)) 
				END IF 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_prv_disc_per = 0 
				ELSE 
					LET l_prv_disc_per = 100 * (1-(p_rec_prv_statsale.net_amt/p_rec_prv_statsale.gross_amt)) 
				END IF 
				IF l_prv_disc_per = 0 THEN 
					LET l_disc_diff_per = 0 
				ELSE 
					LET l_disc_diff_per = 100 * 
					((l_cur_disc_per - l_prv_disc_per) / l_prv_disc_per) 
				END IF
				 
				LET l_cur_gp = p_rec_cur_statsale.net_amt	- p_rec_cur_statsale.cost_amt 
				LET l_prv_gp = p_rec_prv_statsale.net_amt	- p_rec_prv_statsale.cost_amt 
				IF l_prv_gp = 0 THEN 
					LET l_gp_diff_per = 0 
				ELSE 
					LET l_gp_diff_per = 100 * ((l_cur_gp - l_prv_gp) / l_prv_gp) 
				END IF 
				
				PRINT COLUMN 006,"Product group:", 
				COLUMN 021,p_rec_cur_statsale.prodgrp_code, 
				COLUMN 025,l_desc_text 
				
				PRINT COLUMN 048,p_rec_cur_statsale.gross_amt USING "------&", 
				COLUMN 056,p_rec_prv_statsale.gross_amt USING "------&", 
				COLUMN 063,l_grs_diff_per USING "----&.&", 
				COLUMN 070,p_rec_cur_statsale.net_amt USING "------&", 
				COLUMN 077,p_rec_prv_statsale.net_amt USING "------&", 
				COLUMN 084,l_net_diff_per USING "----&.&", 
				COLUMN 091,l_cur_disc_per USING "----&.&", 
				COLUMN 098,l_prv_disc_per USING "----&.&", 
				COLUMN 105,l_disc_diff_per USING "----&.&", 
				COLUMN 112,l_cur_gp USING "------&", 
				COLUMN 119,l_prv_gp USING "------&", 
				COLUMN 126,l_gp_diff_per USING "----&.&" 
			END IF
			 
		AFTER GROUP OF p_rec_cur_statsale.maingrp_code 
			IF modu_rec_criteria.mgrp_ind = "Y" THEN 
				NEED 4 LINES 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_cur_statsale.maingrp_code 
				LET p_rec_cur_statsale.gross_amt = GROUP sum(p_rec_cur_statsale.gross_amt) 
				LET p_rec_cur_statsale.net_amt = GROUP sum(p_rec_cur_statsale.net_amt) 
				LET p_rec_cur_statsale.cost_amt = GROUP sum(p_rec_cur_statsale.cost_amt) 
				LET p_rec_prv_statsale.gross_amt = GROUP sum(p_rec_prv_statsale.gross_amt) 
				LET p_rec_prv_statsale.net_amt = GROUP sum(p_rec_prv_statsale.net_amt) 
				LET p_rec_prv_statsale.cost_amt = GROUP sum(p_rec_prv_statsale.cost_amt) 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_grs_diff_per = 0 
				ELSE 
					LET l_grs_diff_per = 100 * ((p_rec_cur_statsale.gross_amt - p_rec_prv_statsale.gross_amt) / p_rec_prv_statsale.gross_amt) 
				END IF 
				IF p_rec_prv_statsale.net_amt = 0 THEN 
					LET l_net_diff_per = 0 
				ELSE 
					LET l_net_diff_per = 100 * ((p_rec_cur_statsale.net_amt - p_rec_prv_statsale.net_amt) / p_rec_prv_statsale.net_amt) 
				END IF 
				IF p_rec_cur_statsale.gross_amt = 0 THEN 
					LET l_cur_disc_per = 0 
				ELSE 
					LET l_cur_disc_per = 100 * (1-(p_rec_cur_statsale.net_amt/p_rec_cur_statsale.gross_amt)) 
				END IF 
				IF p_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_prv_disc_per = 0 
				ELSE 
					LET l_prv_disc_per = 100 * (1-(p_rec_prv_statsale.net_amt/p_rec_prv_statsale.gross_amt)) 
				END IF 
				IF l_prv_disc_per = 0 THEN 
					LET l_disc_diff_per = 0 
				ELSE 
					LET l_disc_diff_per = 100 * 
					((l_cur_disc_per - l_prv_disc_per) / l_prv_disc_per) 
				END IF 
				LET l_cur_gp = p_rec_cur_statsale.net_amt - p_rec_cur_statsale.cost_amt 
				LET l_prv_gp = p_rec_prv_statsale.net_amt - p_rec_prv_statsale.cost_amt 
				IF l_prv_gp = 0 THEN 
					LET l_gp_diff_per = 0 
				ELSE 
					LET l_gp_diff_per = 100 * ((l_cur_gp - l_prv_gp) / l_prv_gp) 
				END IF 
				
				PRINT COLUMN 004,"Main group:", 
				COLUMN 016,p_rec_cur_statsale.maingrp_code, 
				COLUMN 020,l_desc_text 
				
				PRINT COLUMN 048,p_rec_cur_statsale.gross_amt USING "------&", 
				COLUMN 056,p_rec_prv_statsale.gross_amt USING "------&", 
				COLUMN 063,l_grs_diff_per USING "----&.&", 
				COLUMN 070,p_rec_cur_statsale.net_amt USING "------&", 
				COLUMN 077,p_rec_prv_statsale.net_amt USING "------&", 
				COLUMN 084,l_net_diff_per USING "----&.&", 
				COLUMN 091,l_cur_disc_per USING "----&.&", 
				COLUMN 098,l_prv_disc_per USING "----&.&", 
				COLUMN 105,l_disc_diff_per USING "----&.&", 
				COLUMN 112,l_cur_gp USING "------&", 
				COLUMN 119,l_prv_gp USING "------&", 
				COLUMN 126,l_gp_diff_per USING "----&.&" 
			END IF 
			
		AFTER GROUP OF p_rec_cur_statsale.cust_code 
			NEED 4 LINES 
			LET p_rec_cur_statsale.gross_amt = GROUP sum(p_rec_cur_statsale.gross_amt) 
			LET p_rec_cur_statsale.net_amt = GROUP sum(p_rec_cur_statsale.net_amt) 
			LET p_rec_cur_statsale.cost_amt = GROUP sum(p_rec_cur_statsale.cost_amt) 
			LET p_rec_prv_statsale.gross_amt = GROUP sum(p_rec_prv_statsale.gross_amt) 
			LET p_rec_prv_statsale.net_amt = GROUP sum(p_rec_prv_statsale.net_amt) 
			LET p_rec_prv_statsale.cost_amt = GROUP sum(p_rec_prv_statsale.cost_amt) 
			IF p_rec_prv_statsale.gross_amt = 0 THEN 
				LET l_grs_diff_per = 0 
			ELSE 
				LET l_grs_diff_per = 100 * ((p_rec_cur_statsale.gross_amt - p_rec_prv_statsale.gross_amt) / p_rec_prv_statsale.gross_amt) 
			END IF 
			IF p_rec_prv_statsale.net_amt = 0 THEN 
				LET l_net_diff_per = 0 
			ELSE 
				LET l_net_diff_per = 100 * ((p_rec_cur_statsale.net_amt - p_rec_prv_statsale.net_amt) 	/ p_rec_prv_statsale.net_amt) 
			END IF 
			IF p_rec_cur_statsale.gross_amt = 0 THEN 
				LET l_cur_disc_per = 0 
			ELSE 
				LET l_cur_disc_per = 100 * (1-(p_rec_cur_statsale.net_amt/p_rec_cur_statsale.gross_amt)) 
			END IF 
			IF p_rec_prv_statsale.gross_amt = 0 THEN 
				LET l_prv_disc_per = 0 
			ELSE 
				LET l_prv_disc_per = 100 * (1-(p_rec_prv_statsale.net_amt/p_rec_prv_statsale.gross_amt)) 
			END IF 
			IF l_prv_disc_per = 0 THEN 
				LET l_disc_diff_per = 0 
			ELSE 
				LET l_disc_diff_per = 100 * ((l_cur_disc_per - l_prv_disc_per) / l_prv_disc_per) 
			END IF 
			LET l_cur_gp = p_rec_cur_statsale.net_amt - p_rec_cur_statsale.cost_amt 
			LET l_prv_gp = p_rec_prv_statsale.net_amt - p_rec_prv_statsale.cost_amt 
			IF l_prv_gp = 0 THEN 
				LET l_gp_diff_per = 0 
			ELSE 
				LET l_gp_diff_per = 100 * ((l_cur_gp - l_prv_gp) / l_prv_gp) 
			END IF 
			LET l_rank_amt = p_rec_cur_statsale.net_amt * (365 / (modu_end_date1-modu_start_date1+1)) 
			
			CASE 
				WHEN l_rank_amt >= glob_rec_statparms.cust_rank1_amt 
					LET l_rank = "A" 
				WHEN l_rank_amt >= glob_rec_statparms.cust_rank2_amt 
					LET l_rank = "B" 
				WHEN l_rank_amt >= glob_rec_statparms.cust_rank3_amt 
					LET l_rank = "C" 
				WHEN l_rank_amt >= glob_rec_statparms.cust_rank4_amt 
					LET l_rank = "D" 
				OTHERWISE 
					LET l_rank = "E" 
			END CASE 
			
			PRINT COLUMN 001,"Customer summary:" 
			
			PRINT COLUMN 001,"================", 
			COLUMN 040,"Rank:", 
			COLUMN 046,l_rank, 
			COLUMN 048,p_rec_cur_statsale.gross_amt USING "------&", 
			COLUMN 056,p_rec_prv_statsale.gross_amt USING "------&", 
			COLUMN 063,l_grs_diff_per USING "----&.&", 

			COLUMN 070,p_rec_cur_statsale.net_amt USING "------&", 
			COLUMN 077,p_rec_prv_statsale.net_amt USING "------&", 

			COLUMN 084,l_net_diff_per USING "----&.&", 
			COLUMN 091,l_cur_disc_per USING "----&.&", 
			COLUMN 098,l_prv_disc_per USING "----&.&", 
			COLUMN 105,l_disc_diff_per USING "----&.&", 
			COLUMN 112,l_cur_gp USING "------&", 
			COLUMN 119,l_prv_gp USING "------&", 
			COLUMN 126,l_gp_diff_per USING "----&.&"
			 
		ON LAST ROW 
			LET l_cur_total_gross_amt = sum(p_rec_cur_statsale.gross_amt) 
			LET l_prv_total_gross_amt = sum(p_rec_prv_statsale.gross_amt) 
			LET l_prv_total_net_amt = sum(p_rec_prv_statsale.net_amt) 
			LET l_cur_total_net_amt = sum(p_rec_cur_statsale.net_amt) 
			LET l_cur_total_cost_amt = sum(p_rec_cur_statsale.cost_amt) 
			LET l_prv_total_cost_amt = sum(p_rec_prv_statsale.cost_amt)
			 
			IF l_prv_total_gross_amt = 0 THEN 
				LET l_total_grs_diff_per = 0 
			ELSE 
				LET l_total_grs_diff_per = 100 * ((l_cur_total_gross_amt - l_prv_total_gross_amt) / l_prv_total_gross_amt) 
			END IF 
			IF l_prv_total_net_amt = 0 THEN 
				LET l_total_net_diff_per = 0 
			ELSE 
				LET l_total_net_diff_per = 100 * ((l_cur_total_net_amt - l_prv_total_net_amt) / l_prv_total_net_amt) 
			END IF 
			IF l_prv_total_net_amt = 0 THEN 
				LET l_total_net_diff_per = 0 
			ELSE 
				LET l_total_net_diff_per = 100 * ((l_cur_total_net_amt - l_prv_total_net_amt) / l_prv_total_net_amt) 
			END IF 
			IF l_cur_total_gross_amt = 0 THEN 
				LET l_cur_total_disc_per = 0 
			ELSE 
				LET l_cur_total_disc_per = 100 * (1-(l_cur_total_net_amt / l_cur_total_gross_amt)) 
			END IF 
			IF l_prv_total_disc_per = 0 THEN 
				LET l_total_disc_diff_per = 0 
			ELSE 
				LET l_total_disc_diff_per = 100 * ((l_cur_total_disc_per - l_prv_total_disc_per) / l_prv_total_disc_per) 
			END IF 
			LET l_cur_total_gp = l_cur_total_net_amt - l_cur_total_cost_amt 
			LET l_prv_total_gp = l_prv_total_net_amt - l_prv_total_cost_amt 
			IF l_prv_total_gp = 0 THEN 
				LET l_total_gp_diff_per = 0 
			ELSE 
				LET l_total_gp_diff_per = 100 *	((l_cur_total_gp - l_prv_total_gp) / l_prv_total_gp) 
			END IF 
			SKIP 1 line 

			PRINT COLUMN 048,"--------", 
			COLUMN 056,"-------", 
			COLUMN 063,"-------", 
			COLUMN 070,"-------", 
			COLUMN 077,"-------", 
			COLUMN 084,"-------", 
			COLUMN 091,"-------", 
			COLUMN 098,"-------", 
			COLUMN 105,"-------", 
			COLUMN 112,"-------", 
			COLUMN 119,"-------", 
			COLUMN 126,"-------" 

			PRINT COLUMN 001,"TOTAL:", 
			COLUMN 048, sum(p_rec_cur_statsale.gross_amt) USING "------&", 
			COLUMN 056,sum(p_rec_prv_statsale.gross_amt) USING "------&", 
			COLUMN 063,l_total_grs_diff_per USING "----&.&", 
			COLUMN 070,sum(p_rec_cur_statsale.net_amt) USING "------&", 
			COLUMN 077,sum(p_rec_prv_statsale.net_amt) USING "------&", 
			COLUMN 084,l_total_net_diff_per USING "----&.&", 
			COLUMN 091,l_cur_total_disc_per USING "----&.&", 
			COLUMN 098,l_prv_total_disc_per USING "----&.&", 
			COLUMN 105,l_total_disc_diff_per USING "----&.&", 
			COLUMN 112,l_cur_total_gp USING "------&", 
			COLUMN 119,l_prv_total_gp USING "------&", 
			COLUMN 126,l_total_gp_diff_per USING "----&.&" 

			PRINT COLUMN 048,"--------", 
			COLUMN 056,"-------", 
			COLUMN 063,"-------", 
			COLUMN 070,"-------", 
			COLUMN 077,"-------", 
			COLUMN 084,"-------", 
			COLUMN 091,"-------", 
			COLUMN 098,"-------", 
			COLUMN 105,"-------", 
			COLUMN 112,"-------", 
			COLUMN 119,"-------", 
			COLUMN 126,"-------" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT EV5_rpt_list(p_rec_cur_statsale,p_rec_prv_statsale)   
###########################################################################