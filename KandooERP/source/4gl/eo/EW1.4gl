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
GLOBALS "../eo/EW1_GLOBALS.4gl"  
###########################################################################
# MODULE Scope Variables
###########################################################################

DEFINE modu_rec_criteria RECORD 
	part_ind char(1), 
	pgrp_ind char(1), 
	mgrp_ind char(1) 
END RECORD 
DEFINE modu_temp_text STRING 

###########################################################################
# FUNCTION EW1_main()
#
# EW1 - Sales Area Distribution Report
###########################################################################
FUNCTION EW1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EW1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E285 with FORM "E285" 
			 CALL windecoration_e("E285")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY getmenuitemlabel(NULL) TO header_text
			 
			MENU " Sales Area distribution" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EW1","menu-Sales_Area-1") -- albo kd-502 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EW1_rpt_process(EW1_rpt_query())
		
				ON ACTION "PRINT MANAGER" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW E285 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EW1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E285 with FORM "E285" 
			 CALL windecoration_e("E285") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EW1_rpt_query()) #save where clause in env 
			CLOSE WINDOW E285 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EW1_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION EW1_main()
###########################################################################


###########################################################################
# FUNCTION EW1_rpt_query()
#
# 
###########################################################################
FUNCTION EW1_rpt_query() 
	DEFINE l_where_text STRING 

	IF EW1_rpt_query() = FALSE THEN
		MESSAGE "Report generation aborted by the user"
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
			CALL publish_toolbar("kandoo","EW1","construct-area_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref5_code = glob_rec_statparms.mth_type_code

		LET glob_rec_rpt_selector.ref1_num = glob_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = glob_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = glob_rec_statint.start_date
		LET glob_rec_rpt_selector.ref1_ind = glob_rec_statint.dist_flag

		LET glob_rec_rpt_selector.ref2_num = glob_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = glob_rec_statint.end_date
		LET glob_rec_rpt_selector.ref2_code = glob_rec_statint.int_text
		LET glob_rec_rpt_selector.ref2_ind = glob_rec_statint.updreq_flag	

		LET glob_rec_rpt_selector.ref4_ind = modu_rec_criteria.part_ind
		LET glob_rec_rpt_selector.ref5_ind = modu_rec_criteria.pgrp_ind
		LET glob_rec_rpt_selector.ref6_ind = modu_rec_criteria.mgrp_ind
									
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION EW1_rpt_query()
###########################################################################


############################################################
# FUNCTION EW1_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EW1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index
	
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_cur_distterr RECORD LIKE distterr.* 
	DEFINE l_rec_prv_distterr RECORD LIKE distterr.* 
	DEFINE l_rec_cy_distterr RECORD LIKE distterr.* 
	DEFINE l_rec_py_distterr RECORD LIKE distterr.* 
	DEFINE l_year_num LIKE statint.year_num 
	DEFINE l_int_num LIKE statint.int_num 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EW1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EW1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET glob_rec_statparms.mth_type_code = glob_rec_rpt_selector.ref5_code
	 
	LET glob_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref1_num 
	LET glob_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref1_code
	LET glob_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref1_date			
	LET glob_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref1_ind	
		
	LET glob_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref2_num			
	LET glob_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref2_date
	LET glob_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref2_code
	LET glob_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET3_rpt_list")].ref2_ind

	LET modu_rec_criteria.part_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref4_ind
	LET modu_rec_criteria.pgrp_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref5_ind
	LET modu_rec_criteria.mgrp_ind= glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV5_rpt_list")].ref6_ind
	#------------------------------------------------------------

	LET l_query_text = "SELECT salearea.* FROM salearea,territory ", 
	"WHERE salearea.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND territory.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND territory.area_code = salearea.area_code ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY 1,2" 
	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea cursor FOR s_salearea 
	LET l_query_text = "SELECT * FROM distterr ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND area_code = ? ", 
	"AND terr_code IS NULL ", 
	"AND part_code IS NOT NULL ", 
	"AND year_num = ? ", 
	"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
	"AND int_num between ? AND ? ", 
	"ORDER BY cmpy_code,area_code,maingrp_code, ", 
	"prodgrp_code,part_code" 
	PREPARE s_distterr FROM l_query_text 
	DECLARE c_distterr cursor FOR s_distterr 

--	MESSAGE kandoomsg2("E",1162,"") 	#1045 Reporting on Sales Areas...
	FOREACH c_salearea INTO l_rec_salearea.* 
 
		#
		# The following section IS coded this way TO cater FOR the following:
		#    Products NOT in current period but have YTD
		#    Products NOT in current period OR YTD but have activity last year..
		#
		OPEN c_distterr USING l_rec_salearea.area_code, 
		glob_rec_statint.year_num, 
		glob_rec_statint.int_num, 
		glob_rec_statint.int_num 
		FOREACH c_distterr INTO l_cur_distterr.* 
			LET l_rec_prv_distterr.* = l_cur_distterr.* 
			LET l_rec_prv_distterr.mth_net_amt = 0 
			LET l_rec_prv_distterr.mth_cust_num = 0 
			LET l_rec_prv_distterr.mth_sales_qty = 0 
			#
			LET l_rec_cy_distterr.* = l_cur_distterr.* 
			LET l_rec_cy_distterr.mth_net_amt = 0 
			LET l_rec_cy_distterr.mth_cust_num = 0 
			LET l_rec_cy_distterr.mth_sales_qty = 0 
			#
			LET l_rec_py_distterr.* = l_cur_distterr.* 
			LET l_rec_py_distterr.mth_net_amt = 0 
			LET l_rec_py_distterr.mth_cust_num = 0 
			LET l_rec_py_distterr.mth_sales_qty = 0
			#---------------------------------------------------------
			OUTPUT TO REPORT EW1_rpt_list(l_rpt_idx,
				l_cur_distterr.*, 
				l_rec_prv_distterr.*, 
				l_rec_cy_distterr.*, 
				l_rec_py_distterr.*,
				glob_rec_statint.*,
				modu_rec_criteria.*) 
			IF NOT rpt_int_flag_handler2("Sales Area:",l_rec_salearea.desc_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------			
			 
		END FOREACH 
		LET l_year_num = glob_rec_statint.year_num - 1 
		OPEN c_distterr USING l_rec_salearea.area_code, 
		l_year_num, 
		glob_rec_statint.int_num, 
		glob_rec_statint.int_num 
		FOREACH c_distterr INTO l_rec_prv_distterr.* 
			LET l_cur_distterr.* = l_rec_prv_distterr.* 
			LET l_cur_distterr.mth_net_amt = 0 
			LET l_cur_distterr.mth_cust_num = 0 
			LET l_cur_distterr.mth_sales_qty = 0 
			#
			LET l_rec_cy_distterr.* = l_rec_prv_distterr.* 
			LET l_rec_cy_distterr.mth_net_amt = 0 
			LET l_rec_cy_distterr.mth_cust_num = 0 
			LET l_rec_cy_distterr.mth_sales_qty = 0 
			#
			LET l_rec_py_distterr.* = l_rec_prv_distterr.* 
			LET l_rec_py_distterr.mth_net_amt = 0 
			LET l_rec_py_distterr.mth_cust_num = 0 
			LET l_rec_py_distterr.mth_sales_qty = 0 
			#---------------------------------------------------------
			OUTPUT TO REPORT EW1_rpt_list(l_rpt_idx,
				l_cur_distterr.*, 
				l_rec_prv_distterr.*, 
				l_rec_cy_distterr.*, 
				l_rec_py_distterr.*,
				glob_rec_statint.*,
				modu_rec_criteria.*) 
			IF NOT rpt_int_flag_handler2("Sales Area:",l_rec_salearea.desc_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------			
		END FOREACH 

		LET l_int_num = 1 

		OPEN c_distterr USING l_rec_salearea.area_code, 
		glob_rec_statint.year_num, 
		l_int_num, 
		glob_rec_statint.int_num 

		FOREACH c_distterr INTO l_rec_cy_distterr.* 
			LET l_cur_distterr.* = l_rec_cy_distterr.* 
			LET l_cur_distterr.mth_net_amt = 0 
			LET l_cur_distterr.mth_cust_num = 0 
			LET l_cur_distterr.mth_sales_qty = 0 
			#
			LET l_rec_prv_distterr.* = l_rec_cy_distterr.* 
			LET l_rec_prv_distterr.mth_net_amt = 0 
			LET l_rec_prv_distterr.mth_cust_num = 0 
			LET l_rec_prv_distterr.mth_sales_qty = 0 
			#
			LET l_rec_py_distterr.* = l_rec_cy_distterr.* 
			LET l_rec_py_distterr.mth_net_amt = 0 
			LET l_rec_py_distterr.mth_cust_num = 0 
			LET l_rec_py_distterr.mth_sales_qty = 0 
			#---------------------------------------------------------
			OUTPUT TO REPORT EW1_rpt_list(l_rpt_idx,
				l_cur_distterr.*, 
				l_rec_prv_distterr.*, 
				l_rec_cy_distterr.*, 
				l_rec_py_distterr.*,
				glob_rec_statint.*,
				modu_rec_criteria.*) 
			IF NOT rpt_int_flag_handler2("Sales Area:",l_rec_salearea.desc_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------					
		END FOREACH 

		OPEN c_distterr USING l_rec_salearea.area_code, 
		l_year_num, 
		l_int_num, 
		glob_rec_statint.int_num 
		
		FOREACH c_distterr INTO l_rec_py_distterr.* 
			LET l_cur_distterr.* = l_rec_py_distterr.* 
			LET l_cur_distterr.mth_net_amt = 0 
			LET l_cur_distterr.mth_cust_num = 0 
			LET l_cur_distterr.mth_sales_qty = 0 
			#
			LET l_rec_prv_distterr.* = l_rec_py_distterr.* 
			LET l_rec_prv_distterr.mth_net_amt = 0 
			LET l_rec_prv_distterr.mth_cust_num = 0 
			LET l_rec_prv_distterr.mth_sales_qty = 0 
			#
			LET l_rec_cy_distterr.* = l_rec_py_distterr.* 
			LET l_rec_cy_distterr.mth_net_amt = 0 
			LET l_rec_cy_distterr.mth_cust_num = 0 
			LET l_rec_cy_distterr.mth_sales_qty = 0
			#---------------------------------------------------------
			OUTPUT TO REPORT EW1_rpt_list(l_rpt_idx,
				l_cur_distterr.*, 
				l_rec_prv_distterr.*, 
				l_rec_cy_distterr.*, 
				l_rec_py_distterr.*,
				glob_rec_statint.*,
				modu_rec_criteria.*) 
			IF NOT rpt_int_flag_handler2("Sales Area:",l_rec_salearea.desc_text,NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------		
			 

		END FOREACH 
		
	END FOREACH 		
	#------------------------------------------------------------
	FINISH REPORT EW1_rpt_list
	CALL rpt_finish("EW1_rpt_list")
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
# END FUNCTION EW1_rpt_process(p_where_text) 
############################################################


###########################################################################
# FUNCTION EW1_rpt_enter_year() 
#
# 
###########################################################################
FUNCTION EW1_rpt_enter_year() 
	
	LET modu_rec_criteria.part_ind = xlate_to("Y") 
	LET modu_rec_criteria.pgrp_ind = xlate_to("Y") 
	LET modu_rec_criteria.mgrp_ind = xlate_to("Y") 
	LET glob_rec_statint.year_num = glob_rec_statparms.year_num 
	LET glob_rec_statint.int_num = glob_rec_statparms.mth_num
	 
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue
	INPUT BY NAME glob_rec_statint.year_num, 
	glob_rec_statint.int_text, 
	modu_rec_criteria.part_ind, 
	modu_rec_criteria.pgrp_ind, 
	modu_rec_criteria.mgrp_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EW1","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = "year_num = '",glob_rec_statint.year_num,"' ", 
				"AND type_code = '",glob_rec_statparms.mth_type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET glob_rec_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 
 
		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET glob_rec_statint.year_num = glob_rec_statint.year_num - 1 
			NEXT FIELD year_num 
			
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET glob_rec_statint.year_num = glob_rec_statint.year_num + 1 
			NEXT FIELD year_num 
			
		BEFORE FIELD year_num 
			SELECT * INTO glob_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = glob_rec_statint.int_num 
			
			DISPLAY BY NAME 
				glob_rec_statint.int_text, 
				glob_rec_statint.start_date, 
				glob_rec_statint.end_date 

		AFTER FIELD year_num 
			IF glob_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 				#9210 Year number must be entered
				LET glob_rec_statint.year_num = glob_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 
			
		BEFORE FIELD int_text 
			SELECT int_text INTO glob_rec_statint.int_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = glob_rec_statint.int_num 
			
		AFTER FIELD int_text 
			IF glob_rec_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") #9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = glob_rec_statint.year_num 
				AND type_code = glob_rec_statparms.mth_type_code 
				AND int_text = glob_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO glob_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") #9223 Interval does NOT exist - Try Window"
					LET glob_rec_statint.int_num = glob_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			
			DISPLAY glob_rec_statint.start_date TO start_date 
			DISPLAY glob_rec_statint.end_date TO end_date 

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
# END FUNCTION EW1_rpt_enter_year() 
###########################################################################