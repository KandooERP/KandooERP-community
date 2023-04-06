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
GLOBALS "../eo/EY1_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_rec_criteria RECORD 
		part_ind char(1), 
		pgrp_ind char(1), 
		mgrp_ind char(1) 
	END RECORD 
DEFINE modu_sper_where_text char(50) 
DEFINE modu_temp_text STRING 
 

###########################################################################
# FUNCTION EY1_main()
#
# EY1 - Company Distribution Report
###########################################################################
FUNCTION EY1_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EY1") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 

			OPEN WINDOW E286 with FORM "E286" 
			 CALL windecoration_e("E286") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
			MENU " Company distribution" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EY1","menu-Company-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL EY1_rpt_process(EY1_rpt_query()) 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
				
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
							
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL EY1_rpt_process(EY1_rpt_query()) 
		
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW E286

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EY1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E286 with FORM "E286" 
			 CALL windecoration_e("E286") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EY1_rpt_query()) #save where clause in env 
			CLOSE WINDOW E286 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EY1_rpt_process(get_url_sel_text())
	END CASE 
	 
END FUNCTION 
###########################################################################
# END FUNCTION EY1_main()
###########################################################################


###########################################################################
# FUNCTION EY1_rpt_query() 
#
# 
###########################################################################
FUNCTION EY1_rpt_query()
	#Note: This report does not use any construct 
	IF EY1_enter_year() = FALSE THEN
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
# END FUNCTION EY1_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION EY1_rpt_process(p_where_text)
#
# 
###########################################################################
FUNCTION EY1_rpt_process(p_where_text) 
	DEFINE p_where_text CHAR(50)
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_cur_distsper RECORD LIKE distsper.* 
	DEFINE l_rec_prv_distsper RECORD LIKE distsper.* 
	DEFINE l_rec_cy_distsper RECORD LIKE distsper.* 
	DEFINE l_rec_py_distsper RECORD LIKE distsper.* 
	DEFINE l_year_num LIKE statint.year_num 
	DEFINE l_int_num LIKE statint.int_num 

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


	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",p_where_text clipped 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 

	LET l_query_text = "SELECT * FROM distsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sale_code = ?", 
	"AND part_code IS NOT NULL ", 
	"AND year_num = ? ", 
	"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
	"AND int_num between ? AND ? ", 
	"ORDER BY cmpy_code,maingrp_code,prodgrp_code,part_code" 
	PREPARE s_distsper FROM l_query_text 
	DECLARE c_distsper cursor FOR s_distsper 

	LET l_query_text = 
	"SELECT sum(net_amt),sum(sales_qty),sum(orders_num),sum(offers_num), ", 
	"sum(credits_num),sum(poss_cust_num),sum(buy_cust_num), ", 
	"sum(new_cust_num), sum(lost_cust_num) ", 
	"FROM statsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sale_code IS NOT NULL ", 
	"AND year_num = '",modu_rec_statint.year_num,"' ", 
	"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
	"AND int_num between ? AND ? " 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 

	MESSAGE kandoomsg2("E",1045,"")	#1045 Reporting on Salesperson...

	FOREACH c_salesperson INTO l_rec_salesperson.* 

		#
		# The following section IS coded this way TO cater FOR the following:
		#    Products NOT in current period but have YTD
		#    Products NOT in current period OR YTD but have activity last year..
		#
		OPEN c_distsper USING l_rec_salesperson.sale_code, 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_num, 
		modu_rec_statint.int_num 

		FOREACH c_distsper INTO l_rec_cur_distsper.* 
			LET l_rec_prv_distsper.* = l_rec_cur_distsper.* 
			LET l_rec_prv_distsper.mth_net_amt = 0 
			LET l_rec_prv_distsper.mth_cust_num = 0 
			LET l_rec_prv_distsper.mth_sales_qty = 0 
			#
			LET l_rec_cy_distsper.* = l_rec_cur_distsper.* 
			LET l_rec_cy_distsper.mth_net_amt = 0 
			LET l_rec_cy_distsper.mth_cust_num = 0 
			LET l_rec_cy_distsper.mth_sales_qty = 0 
			#
			LET l_rec_py_distsper.* = l_rec_cur_distsper.* 
			LET l_rec_py_distsper.mth_net_amt = 0 
			LET l_rec_py_distsper.mth_cust_num = 0 
			LET l_rec_py_distsper.mth_sales_qty = 0 
			#---------------------------------------------------------
			OUTPUT TO REPORT EY1_rpt_list_product(l_rpt_idx,
			l_rec_cur_distsper.*, 
			l_rec_prv_distsper.*, 
			l_rec_cy_distsper.*, 
			l_rec_py_distsper.*) 
			IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 

		LET l_year_num = modu_rec_statint.year_num - 1 

		OPEN c_distsper USING l_rec_salesperson.sale_code, 
		l_year_num, 
		modu_rec_statint.int_num, 
		modu_rec_statint.int_num 

		FOREACH c_distsper INTO l_rec_prv_distsper.* 
			LET l_rec_cur_distsper.* = l_rec_prv_distsper.* 
			LET l_rec_cur_distsper.mth_net_amt = 0 
			LET l_rec_cur_distsper.mth_cust_num = 0 
			LET l_rec_cur_distsper.mth_sales_qty = 0 
			#
			LET l_rec_cy_distsper.* = l_rec_prv_distsper.* 
			LET l_rec_cy_distsper.mth_net_amt = 0 
			LET l_rec_cy_distsper.mth_cust_num = 0 
			LET l_rec_cy_distsper.mth_sales_qty = 0 
			#
			LET l_rec_py_distsper.* = l_rec_prv_distsper.* 
			LET l_rec_py_distsper.mth_net_amt = 0 
			LET l_rec_py_distsper.mth_cust_num = 0 
			LET l_rec_py_distsper.mth_sales_qty = 0 

			#---------------------------------------------------------
			OUTPUT TO REPORT EY1_rpt_list_product(l_rpt_idx,
			l_rec_cur_distsper.*, 
			l_rec_prv_distsper.*, 
			l_rec_cy_distsper.*, 
			l_rec_py_distsper.*) 
			IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------


		END FOREACH 

		LET l_int_num = 1 

		OPEN c_distsper USING l_rec_salesperson.sale_code, 
		modu_rec_statint.year_num, 
		l_int_num, 
		modu_rec_statint.int_num 

		FOREACH c_distsper INTO l_rec_cy_distsper.* 
			LET l_rec_cur_distsper.* = l_rec_cy_distsper.* 
			LET l_rec_cur_distsper.mth_net_amt = 0 
			LET l_rec_cur_distsper.mth_cust_num = 0 
			LET l_rec_cur_distsper.mth_sales_qty = 0 
			#
			LET l_rec_prv_distsper.* = l_rec_cy_distsper.* 
			LET l_rec_prv_distsper.mth_net_amt = 0 
			LET l_rec_prv_distsper.mth_cust_num = 0 
			LET l_rec_prv_distsper.mth_sales_qty = 0 
			#
			LET l_rec_py_distsper.* = l_rec_cy_distsper.* 
			LET l_rec_py_distsper.mth_net_amt = 0 
			LET l_rec_py_distsper.mth_cust_num = 0 
			LET l_rec_py_distsper.mth_sales_qty = 0 
			OUTPUT TO REPORT EY1_rpt_list(l_rec_cur_distsper.*, 
			l_rec_prv_distsper.*, 
			l_rec_cy_distsper.*, 
			l_rec_py_distsper.*) 
		END FOREACH 

		OPEN c_distsper USING l_rec_salesperson.sale_code, 
		l_year_num, 
		l_int_num, 
		modu_rec_statint.int_num 

		FOREACH c_distsper INTO l_rec_py_distsper.* 
			LET l_rec_cur_distsper.* = l_rec_py_distsper.* 
			LET l_rec_cur_distsper.mth_net_amt = 0 
			LET l_rec_cur_distsper.mth_cust_num = 0 
			LET l_rec_cur_distsper.mth_sales_qty = 0 
			#
			LET l_rec_prv_distsper.* = l_rec_py_distsper.* 
			LET l_rec_prv_distsper.mth_net_amt = 0 
			LET l_rec_prv_distsper.mth_cust_num = 0 
			LET l_rec_prv_distsper.mth_sales_qty = 0 
			#
			LET l_rec_cy_distsper.* = l_rec_py_distsper.* 
			LET l_rec_cy_distsper.mth_net_amt = 0 
			LET l_rec_cy_distsper.mth_cust_num = 0 
			LET l_rec_cy_distsper.mth_sales_qty = 0 

			#---------------------------------------------------------
			OUTPUT TO REPORT EY1_rpt_list_product(l_rpt_idx,
			l_rec_cur_distsper.*, 
			l_rec_prv_distsper.*, 
			l_rec_cy_distsper.*, 
			l_rec_py_distsper.*) 
			IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------


		END FOREACH 


	END FOREACH 

	FINISH REPORT EY1_rpt_list_product
	CALL rpt_finish("EY1_rpt_list_product")
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
# END FUNCTION EY1_rpt_process(p_where_text)
###########################################################################


###########################################################################
# FUNCTION EY1_enter_year()
#
# 
###########################################################################
FUNCTION EY1_enter_year() 
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

	MESSAGE kandoomsg2("E",1157,"")#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_rec_criteria.part_ind, 
		modu_rec_criteria.pgrp_ind, 
		modu_rec_criteria.mgrp_ind, 
		l_pseudo_flag, 
		l_primary_flag, 
		l_normal_flag 
		WITHOUT DEFAULTS
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
			CALL publish_toolbar("kandoo","EY1","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = "year_num = '",modu_rec_statint.year_num,"' ", 
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
			
			DISPLAY modu_rec_statint.int_text TO int_text 
			DISPLAY modu_rec_statint.start_date TO start_date 
			DISPLAY modu_rec_statint.end_date TO end_date 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
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
				ERROR kandoomsg2("E",9222,"") 	#9222 Interval must be entered"
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
					ERROR kandoomsg2("E",1132,"") 		#1132 All Salesperson Types have been excluded "
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
				LET modu_sper_where_text = "salesperson.sale_type_ind in (", 
				modu_sper_where_text clipped,")" 
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
# END FUNCTION EY1_enter_year()
###########################################################################


###########################################################################
# REPORT EY1_rpt_list(p_rpt_idx, p_rec_cur_distsper,p_rec_prv_distsper,p_rec_cy_distsper,p_rec_py_distsper)
#
# 
###########################################################################
REPORT EY1_rpt_list(p_rpt_idx,p_rec_cur_distsper, 
	p_rec_prv_distsper, 
	p_rec_cy_distsper, 
	p_rec_py_distsper) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE p_rec_cur_distsper RECORD LIKE distsper.* 
	DEFINE p_rec_prv_distsper RECORD LIKE distsper.* 
	DEFINE p_rec_cy_distsper RECORD LIKE distsper.* 
	DEFINE p_rec_py_distsper RECORD LIKE distsper.* 
	
	DEFINE l_rec_cur_statsper RECORD 
		net_amt LIKE statsper.net_amt, 
		sales_qty LIKE statsper.sales_qty, 
		orders_num, 
		offers_num, 
		credits_num, 
		poss_cust_num, 
		buy_cust_num, 
		new_cust_num, 
		lost_cust_num LIKE statsper.lost_cust_num 
	END RECORD 
	DEFINE l_rec_ytd_statsper RECORD 
		net_amt LIKE statsper.net_amt, 
		sales_qty LIKE statsper.sales_qty, 
		orders_num, 
		offers_num, 
		credits_num, 
		poss_cust_num, 
		buy_cust_num, 
		new_cust_num, 
		lost_cust_num LIKE statsper.lost_cust_num 
	END RECORD 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_avg_ord LIKE statsper.orders_num
	DEFINE l_avg_ord_ytd LIKE statsper.orders_num
	DEFINE l_poss_cust_per FLOAT 
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 


	OUTPUT 
 
	ORDER BY p_rec_cur_distsper.cmpy_code, 
	p_rec_cur_distsper.maingrp_code, 
	p_rec_cur_distsper.prodgrp_code, 
	p_rec_cur_distsper.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			LET l_int_num = 1 
			#
			#FETCH year TO date...
			#
			OPEN c_statsper USING l_int_num, 
			modu_rec_statint.int_num 
			FETCH c_statsper INTO l_rec_ytd_statsper.* 
			IF l_rec_ytd_statsper.net_amt IS NULL THEN 
				LET l_rec_ytd_statsper.net_amt = 0 
			END IF 
			IF l_rec_ytd_statsper.sales_qty IS NULL THEN 
				LET l_rec_ytd_statsper.sales_qty = 0 
			END IF 
			IF l_rec_ytd_statsper.orders_num IS NULL THEN 
				LET l_rec_ytd_statsper.orders_num = 0 
			END IF 
			IF l_rec_ytd_statsper.offers_num IS NULL THEN 
				LET l_rec_ytd_statsper.offers_num = 0 
			END IF 
			IF l_rec_ytd_statsper.credits_num IS NULL THEN 
				LET l_rec_ytd_statsper.credits_num = 0 
			END IF 
			IF l_rec_ytd_statsper.poss_cust_num IS NULL THEN 
				LET l_rec_ytd_statsper.poss_cust_num = 0 
			END IF 
			IF l_rec_ytd_statsper.buy_cust_num IS NULL THEN 
				LET l_rec_ytd_statsper.buy_cust_num = 0 
			END IF 
			IF l_rec_ytd_statsper.new_cust_num IS NULL THEN 
				LET l_rec_ytd_statsper.new_cust_num = 0 
			END IF 
			IF l_rec_ytd_statsper.lost_cust_num IS NULL THEN 
				LET l_rec_ytd_statsper.lost_cust_num = 0 
			END IF 
			#
			#FETCH current period...
			#
			OPEN c_statsper USING modu_rec_statint.int_num, 
			modu_rec_statint.int_num 
			FETCH c_statsper INTO l_rec_cur_statsper.* 
			IF l_rec_cur_statsper.net_amt IS NULL THEN 
				LET l_rec_cur_statsper.net_amt = 0 
			END IF 
			IF l_rec_cur_statsper.sales_qty IS NULL THEN 
				LET l_rec_cur_statsper.sales_qty = 0 
			END IF 
			IF l_rec_cur_statsper.orders_num IS NULL THEN 
				LET l_rec_cur_statsper.orders_num = 0 
			END IF 
			IF l_rec_cur_statsper.offers_num IS NULL THEN 
				LET l_rec_cur_statsper.offers_num = 0 
			END IF 
			IF l_rec_cur_statsper.credits_num IS NULL THEN 
				LET l_rec_cur_statsper.credits_num = 0 
			END IF 
			IF l_rec_cur_statsper.poss_cust_num IS NULL THEN 
				LET l_rec_cur_statsper.poss_cust_num = 0 
			END IF 
			IF l_rec_cur_statsper.buy_cust_num IS NULL THEN 
				LET l_rec_cur_statsper.buy_cust_num = 0 
			END IF 
			IF l_rec_cur_statsper.new_cust_num IS NULL THEN 
				LET l_rec_cur_statsper.new_cust_num = 0 
			END IF 
			IF l_rec_cur_statsper.lost_cust_num IS NULL THEN 
				LET l_rec_cur_statsper.lost_cust_num = 0 
			END IF 
			IF (l_rec_cur_statsper.orders_num - l_rec_cur_statsper.credits_num) = 0 THEN 
				LET l_avg_ord = 0 
			ELSE 
				LET l_avg_ord = l_rec_cur_statsper.net_amt / (l_rec_cur_statsper.orders_num - l_rec_cur_statsper.credits_num) 
			END IF 
			IF (l_rec_ytd_statsper.orders_num - l_rec_ytd_statsper.credits_num) = 0 THEN 
				LET l_avg_ord_ytd = 0 
			ELSE 
				LET l_avg_ord_ytd = l_rec_ytd_statsper.net_amt/ (l_rec_ytd_statsper.orders_num - l_rec_ytd_statsper.credits_num) 
			END IF 
			
			PRINT COLUMN 52,"Customers Curr YTD ", 
			COLUMN 88,"Orders Curr ytd" 
			PRINT COLUMN 52,"-----------------------------", 
			COLUMN 88,"----------------------------" 
			
			PRINT COLUMN 52,"Customer count", 
			COLUMN 69,l_rec_cur_statsper.poss_cust_num USING "####&", 
			COLUMN 76,l_rec_cur_statsper.poss_cust_num USING "####&", 
			COLUMN 88,"Orders count", 
			COLUMN 104,l_rec_cur_statsper.orders_num USING "####&", 
			COLUMN 111,l_rec_ytd_statsper.orders_num USING "####&" 
			PRINT COLUMN 52,"Buying customers", 
			COLUMN 69,l_rec_cur_statsper.buy_cust_num USING "####&", 
			COLUMN 76,l_rec_ytd_statsper.buy_cust_num USING "####&", 
			COLUMN 88,"Credits count", 
			COLUMN 104,l_rec_cur_statsper.credits_num USING "####&", 
			COLUMN 111,l_rec_ytd_statsper.credits_num USING "####&" 
			PRINT COLUMN 01,"Start Date: ", modu_rec_statint.start_date USING "dd/mm/yy", 
			COLUMN 52,"New customers", 
			COLUMN 69,l_rec_cur_statsper.new_cust_num USING "####&", 
			COLUMN 76,l_rec_ytd_statsper.new_cust_num USING "####&", 
			COLUMN 88,"Avg ord value", 
			COLUMN 103,l_avg_ord USING "-----&", 
			COLUMN 110,l_avg_ord_ytd USING "-----&" 
			PRINT COLUMN 01," END Date: ", modu_rec_statint.end_date USING "dd/mm/yy", 
			COLUMN 52,"Lost customers", 
			COLUMN 69,l_rec_cur_statsper.lost_cust_num USING "####&", 
			COLUMN 76,l_rec_ytd_statsper.lost_cust_num USING "####&"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		AFTER GROUP OF p_rec_cur_distsper.part_code 
			NEED 3 LINES 
			IF modu_rec_criteria.part_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_cur_distsper.part_code 
				IF l_rec_cur_statsper.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * (group sum(p_rec_cy_distsper.mth_cust_num) / l_rec_cur_statsper.poss_cust_num) 
				END IF 
				PRINT COLUMN 10,p_rec_cur_distsper.part_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,modu_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distsper.mth_cust_num) 
				USING "-----&" 
				PRINT COLUMN 58,(modu_rec_statint.year_num-1) USING "####", 
				COLUMN 75,group sum(p_rec_prv_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distsper.mth_cust_num) 
				USING "-----&" 
			END IF
			 
		AFTER GROUP OF p_rec_cur_distsper.prodgrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.pgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_cur_distsper.prodgrp_code 
				IF l_rec_cur_statsper.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * (group sum(p_rec_cy_distsper.mth_cust_num) / l_rec_cur_statsper.poss_cust_num) 
				END IF 

				PRINT COLUMN 05,"Product group:", 
				COLUMN 20,p_rec_cur_distsper.prodgrp_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,modu_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distsper.mth_cust_num) 
				USING "-----&" 
				PRINT COLUMN 58,(modu_rec_statint.year_num-1) USING "####", 
				COLUMN 75,group sum(p_rec_prv_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distsper.mth_cust_num) 
				USING "-----&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_cur_distsper.maingrp_code 
			NEED 4 LINES 
			IF modu_rec_criteria.mgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_cur_distsper.maingrp_code 
				IF l_rec_cur_statsper.poss_cust_num = 0 THEN 
					LET l_poss_cust_per = 0 
				ELSE 
					LET l_poss_cust_per = 100 * (group sum(p_rec_cy_distsper.mth_cust_num) / l_rec_cur_statsper.poss_cust_num) 
				END IF 
				PRINT COLUMN 03,"Main group:", 
				COLUMN 20,p_rec_cur_distsper.maingrp_code, 
				COLUMN 26,l_desc_text, 
				COLUMN 58,modu_rec_statint.year_num USING "####", 
				COLUMN 64,l_poss_cust_per USING "---&.&", 
				COLUMN 75,group sum(p_rec_cur_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_cur_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 94,group sum(p_rec_cur_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_cy_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_cy_distsper.mth_net_amt) 
				USING "---,---,--&", 
				COLUMN 124,group sum(p_rec_cy_distsper.mth_cust_num) 
				USING "-----&" 
				PRINT COLUMN 58,(modu_rec_statint.year_num-1) USING "####", 
				COLUMN 75,group sum(p_rec_prv_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 82,group sum(p_rec_prv_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 94,group sum(p_rec_prv_distsper.mth_cust_num) 
				USING "-----&", 
				COLUMN 105,group sum(p_rec_py_distsper.mth_sales_qty) 
				USING "-----&", 
				COLUMN 112,group sum(p_rec_py_distsper.mth_net_amt) 
				USING "----------&", 
				COLUMN 124,group sum(p_rec_py_distsper.mth_cust_num) 
				USING "-----&" 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_cur_distsper.cmpy_code 
			NEED 4 LINES 
			IF l_rec_cur_statsper.poss_cust_num = 0 THEN 
				LET l_poss_cust_per = 0 
			ELSE 
				LET l_poss_cust_per = 100 * (group sum(p_rec_cy_distsper.mth_cust_num) 		/ l_rec_cur_statsper.poss_cust_num) 
			END IF 
			PRINT COLUMN 01,"Company summary:", 
			COLUMN 58,modu_rec_statint.year_num USING "####", 
			COLUMN 64,l_poss_cust_per USING "---&.&", 
			COLUMN 75,group sum(p_rec_cur_distsper.mth_sales_qty) 
			USING "-----&", 
			COLUMN 82,group sum(p_rec_cur_distsper.mth_net_amt) 
			USING "---,---,--&", 
			COLUMN 94,group sum(p_rec_cur_distsper.mth_cust_num) 
			USING "-----&", 
			COLUMN 105,group sum(p_rec_cy_distsper.mth_sales_qty) 
			USING "-----&", 
			COLUMN 112,group sum(p_rec_cy_distsper.mth_net_amt) 
			USING "---,---,--&", 
			COLUMN 124,group sum(p_rec_cy_distsper.mth_cust_num) 
			USING "-----&" 
			PRINT COLUMN 58,(modu_rec_statint.year_num-1) USING "####", 
			COLUMN 75,group sum(p_rec_prv_distsper.mth_sales_qty) 
			USING "-----&", 
			COLUMN 82,group sum(p_rec_prv_distsper.mth_net_amt) 
			USING "----------&", 
			COLUMN 94,group sum(p_rec_prv_distsper.mth_cust_num) 
			USING "-----&", 
			COLUMN 105,group sum(p_rec_py_distsper.mth_sales_qty) 
			USING "-----&", 
			COLUMN 112,group sum(p_rec_py_distsper.mth_net_amt) 
			USING "----------&", 
			COLUMN 124,group sum(p_rec_py_distsper.mth_cust_num) 
			USING "-----&" 
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
# END REPORT EY1_rpt_list(p_rpt_idx, p_rec_cur_distsper,p_rec_prv_distsper,p_rec_cy_distsper,p_rec_py_distsper)
###########################################################################