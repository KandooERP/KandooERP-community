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
GLOBALS "../eo/ET9_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_temp_text char(20) 
###########################################################################
# FUNCTION ET9_main() 
#
# ET9 Salesperson Performance Report
# Note:       report_header() has been extracted FROM rmsfunc.4gl AND
# ****        renamed local_header() TO accommodate line length of 160
#             TO avoid database changes.
#             DO NOT remove the comment character FROM the UPDATE stmt
#                    in the set_defaults() FUNCTION.....
###########################################################################
FUNCTION ET9_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET9") 

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1"

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
	 
			OPEN WINDOW E287 with FORM "E287" 
			 CALL windecoration_e("E287") -- albo kd-755 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
			 
			MENU " Salesperson performance" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET9","menu-Salesperson-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET9_rpt_process(ET9_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET9_rpt_process(ET9_rpt_query())
		
				ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		 
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E287 
	
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E287 with FORM "E287" 
			 CALL windecoration_e("E287") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET9_rpt_query()) #save where clause in env 
			CLOSE WINDOW E287 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET9_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 
###########################################################################
# END FUNCTION ET9_main() 
###########################################################################


###########################################################################
# FUNCTION ET9_rpt_query() 
#
#
###########################################################################
FUNCTION ET9_rpt_query() 
	DEFINE l_where_text STRING

	IF (NOT ET9_enter_year()) OR (int_flag = TRUE) THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF

	MESSAGE kandoomsg("E",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	sale_type_ind, 
	terri_code, 
	mgr_code, 
	city_text, 
	state_code, 
	post_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET9","construct-sale_code-1") -- albo kd-502 

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
# END FUNCTION ET9_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ET9_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET9_rpt_process(p_where_text) 
	DEFINE p_where_text STRING

	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_sperstat RECORD 
		mgr_code LIKE salesperson.mgr_code, 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		ytd_net_amt LIKE statsper.net_amt, 
		ytd_bdgt_amt LIKE stattarget.bdgt_amt, 
		mtd_net_amt LIKE statsper.net_amt, 
		mtd_bdgt_amt LIKE stattarget.bdgt_amt, 
		back_amt LIKE statsper.net_amt, 
		held_amt LIKE statsper.net_amt, 
		other_amt LIKE statsper.net_amt, 
		mtd_orders_num LIKE statsper.orders_num, 
		mtd_credits_num LIKE statsper.credits_num, 
		yest_net_amt LIKE statsper.net_amt, 
		mtd_cost_amt LIKE statsper.cost_amt 
	END RECORD 
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE l_start_date LIKE statint.start_date 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"ET9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].ref2_ind
	#------------------------------------------------------------	


	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET9_rpt_list")].sel_text clipped," ",
	"ORDER BY cmpy_code,mgr_code,sale_code " 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	LET l_query_text = "SELECT * FROM statsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sale_code = ? ", 
	"AND year_num = '",modu_rec_statint.year_num,"' ", 
	"AND type_code = '",modu_rec_statparms.mth_type_code,"' ", 
	"AND int_num = '",modu_rec_statint.int_num,"'" 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 
	
	#Get the first start_date FOR the selected year
	SELECT start_date INTO l_start_date FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_rec_statint.year_num 
	AND type_code = modu_rec_statparms.year_type_code 
	AND start_date <= modu_rec_statint.start_date 
	AND end_date >= modu_rec_statint.start_date 
	
	
	LET l_query_text = "SELECT * FROM orderhead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sales_code = ? ", 
	"AND (status_ind = 'U' ", 
	"OR status_ind = 'P') ", 
	"AND order_date between '",l_start_date,"' ", 
	"AND '",modu_rec_statint.end_date,"'" 
	PREPARE s_orderhead FROM l_query_text 
	DECLARE c_orderhead cursor FOR s_orderhead 
	
	LET l_query_text = "SELECT * FROM orderdetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND order_num = ? " 
	PREPARE s_orderdetl FROM l_query_text 
	DECLARE c_orderdetl cursor FOR s_orderdetl 
	--   OPEN WINDOW w1_ET9 AT 12,8 with 2 rows, 60 columns     -- albo  KD-755
	--      ATTRIBUTE(border)
	#MESSAGE kandoomsg2("E",1045,"") #1045 Reporting on Salesperson..
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		DISPLAY "" at 1,30 
		DISPLAY l_rec_salesperson.name_text at 1,30 

		#
		#Setup local RECORD l_rec_sperstat.* TO send TO REPORT
		#
		LET l_rec_sperstat.mgr_code = l_rec_salesperson.mgr_code 
		LET l_rec_sperstat.sale_code = l_rec_salesperson.sale_code 
		LET l_rec_sperstat.name_text = l_rec_salesperson.name_text 
		OPEN c_statsper USING l_rec_salesperson.sale_code 
		FETCH c_statsper INTO l_rec_statsper.* 
		IF status = NOTFOUND THEN 
			LET l_rec_sperstat.mtd_net_amt = 0 
			LET l_rec_sperstat.mtd_cost_amt = 0 
			LET l_rec_sperstat.mtd_credits_num = 0 
			LET l_rec_sperstat.mtd_orders_num = 0 
		ELSE 
			LET l_rec_sperstat.mtd_net_amt = l_rec_statsper.net_amt 
			LET l_rec_sperstat.mtd_cost_amt = l_rec_statsper.cost_amt 
			LET l_rec_sperstat.mtd_credits_num = l_rec_statsper.credits_num 
			LET l_rec_sperstat.mtd_orders_num = l_rec_statsper.orders_num 
		END IF 
		SELECT bdgt_amt INTO l_rec_sperstat.mtd_bdgt_amt FROM stattarget 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bdgt_type_ind = "4" 
		AND bdgt_type_code = l_rec_sperstat.sale_code 
		AND bdgt_ind = "1" 
		AND year_num = modu_rec_statint.year_num 
		AND type_code = modu_rec_statint.type_code 
		AND int_num = modu_rec_statint.int_num 
		IF status = NOTFOUND 
		OR l_rec_sperstat.mtd_bdgt_amt IS NULL THEN 
			LET l_rec_sperstat.mtd_bdgt_amt = 0 
		END IF 
		SELECT sum(bdgt_amt) INTO l_rec_sperstat.ytd_bdgt_amt FROM stattarget 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bdgt_type_ind = "4" 
		AND bdgt_type_code = l_rec_sperstat.sale_code 
		AND bdgt_ind = "1" 
		AND year_num = modu_rec_statint.year_num 
		AND type_code = modu_rec_statint.type_code 
		AND int_num between 1 AND modu_rec_statint.int_num 
		IF l_rec_sperstat.ytd_bdgt_amt IS NULL THEN 
			LET l_rec_sperstat.ytd_bdgt_amt = 0 
		END IF 
		SELECT sum(net_amt) INTO l_rec_sperstat.ytd_net_amt FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_rec_sperstat.sale_code 
		AND year_num = modu_rec_statint.year_num 
		AND type_code = modu_rec_statint.type_code 
		AND int_num between 1 AND modu_rec_statint.int_num 
		IF l_rec_sperstat.ytd_net_amt IS NULL THEN 
			LET l_rec_sperstat.ytd_net_amt = 0 
		END IF 
		#
		#IF today NOT in month selected THEN OUTPUT yest_sales as NULL
		#
		LET l_rec_sperstat.yest_net_amt = NULL 
		IF today >= modu_rec_statint.start_date 
		AND today <= modu_rec_statint.end_date THEN 
			#Get last working day
			SELECT max(start_date) INTO l_start_date FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.day_type_code 
			AND salesdays_num = 1 
			AND start_date < today 
			SELECT int_num INTO l_int_num FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.day_type_code 
			AND start_date = l_start_date 
			SELECT net_amt INTO l_rec_sperstat.yest_net_amt FROM statsper 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = l_rec_sperstat.sale_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.day_type_code 
			AND int_num = l_int_num 
			IF status = NOTFOUND 
			OR l_rec_sperstat.yest_net_amt IS NULL THEN 
				LET l_rec_sperstat.yest_net_amt = 0 
			END IF 
		END IF 
		
		LET l_rec_sperstat.back_amt = 0 
		LET l_rec_sperstat.held_amt = 0 
		LET l_rec_sperstat.other_amt = 0 
		OPEN c_orderhead USING l_rec_sperstat.sale_code 
		FOREACH c_orderhead INTO l_rec_orderhead.* 
			OPEN c_orderdetl USING l_rec_orderhead.order_num 
			FOREACH c_orderdetl INTO l_rec_orderdetl.* 
				IF l_rec_orderhead.hold_code IS NOT NULL THEN 
					LET l_rec_sperstat.held_amt = l_rec_sperstat.held_amt + 
					((l_rec_orderdetl.order_qty - l_rec_orderdetl.inv_qty) * 
					l_rec_orderdetl.unit_price_amt) 
				ELSE 
					LET l_rec_sperstat.back_amt = l_rec_sperstat.back_amt + 
					(l_rec_orderdetl.back_qty * l_rec_orderdetl.unit_price_amt) 
					LET l_rec_sperstat.other_amt = l_rec_sperstat.other_amt + 
					((l_rec_orderdetl.order_qty - 
					l_rec_orderdetl.inv_qty - 
					l_rec_orderdetl.back_qty) * l_rec_orderdetl.unit_price_amt) 
				END IF 
			END FOREACH 
		END FOREACH
		
		#---------------------------------------------------------
		OUTPUT TO REPORT ET9_rpt_list(l_rpt_idx,
		l_rec_sperstat.*)  
		IF NOT rpt_int_flag_handler2("Sale Code:",l_rec_sperstat.sale_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
	END FOREACH 

	
	#------------------------------------------------------------
	FINISH REPORT ET9_rpt_list
	CALL rpt_finish("ET9_rpt_list")
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
# END FUNCTION ET9_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# FUNCTION ET9_enter_year()
#
#
###########################################################################
FUNCTION ET9_enter_year() 

	LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
	LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 

	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue
	
	INPUT BY NAME 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET9","input-modu_rec_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text) 
				LET modu_temp_text = "year_num = '",modu_rec_statint.year_num,"' ", 
				"AND type_code = '",modu_rec_statparms.mth_type_code,"'" 
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
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 
			DISPLAY BY NAME 
				modu_rec_statint.int_text, 
				modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 

		BEFORE FIELD int_text 
			SELECT int_text INTO modu_rec_statint.int_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 

		AFTER FIELD int_text 
			IF modu_rec_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 			#9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statparms.mth_type_code 
				AND int_text = modu_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") 			#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF 

			DISPLAY BY NAME 
				modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET glob_rec_rpt_selector.ref1_num =  modu_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date

		LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date		
		
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET9_enter_year()
###########################################################################


###########################################################################
# REPORT ET9_rpt_list(p_rpt_idx.p_rec_sperstat)  
#
#
###########################################################################
REPORT ET9_rpt_list(p_rpt_idx,p_rec_sperstat) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_sperstat RECORD 
		mgr_code LIKE salesperson.mgr_code, 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		ytd_net_amt LIKE statsper.net_amt, 
		ytd_bdgt_amt LIKE stattarget.bdgt_amt, 
		mtd_net_amt LIKE statsper.net_amt, 
		mtd_bdgt_amt LIKE stattarget.bdgt_amt, 
		back_amt LIKE statsper.net_amt, 
		held_amt LIKE statsper.net_amt, 
		other_amt LIKE statsper.net_amt, 
		mtd_orders_num LIKE statsper.orders_num, 
		mtd_credits_num LIKE statsper.credits_num, 
		yest_net_amt LIKE statsper.net_amt, 
		mtd_cost_amt LIKE statsper.cost_amt 
	END RECORD 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.*

	DEFINE l_start_date DATE 
	DEFINE l_name_text LIKE salesmgr.name_text 

	DEFINE l_avg_sales LIKE statsper.net_amt
	DEFINE l_reqd_sales LIKE statsper.net_amt
	 
	DEFINE l_total_amt LIKE statsper.net_amt
	DEFINE l_avg_ord_val LIKE statsper.net_amt
	 
	DEFINE l_mtd_achieve_per FLOAT
	DEFINE l_ytd_achieve_per FLOAT
	DEFINE l_profit_per FLOAT
	 
	DEFINE l_mtd_bdgt_amt LIKE stattarget.bdgt_amt
	DEFINE l_ytd_bdgt_amt LIKE stattarget.bdgt_amt	 
	DEFINE l_sell_days_used SMALLINT 
	DEFINE l_sell_days_tot SMALLINT 
	DEFINE l_sell_days_left SMALLINT 
	DEFINE i SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_sperstat.mgr_code,p_rec_sperstat.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text	
			
			#Get last working day
			SELECT max(start_date) INTO l_start_date FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.day_type_code 
			AND salesdays_num = 1 
			AND start_date < today 

			--PRINT COLUMN 01,l_line1_text 
			--LET l_line2_text[144,151]=l_start_date USING "dd/mm/yy" 
			--LET l_line2_text[26,30]=modu_rec_statint.int_text 
			--PRINT COLUMN 01,l_line2_text 
			--PRINT COLUMN 01,l_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_sperstat.mgr_code 
			SKIP TO top OF PAGE 
			SELECT * INTO l_rec_salesmgr.* FROM salesmgr 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mgr_code = p_rec_sperstat.mgr_code 
			PRINT COLUMN 01,"Manager:", 
			COLUMN 09,p_rec_sperstat.mgr_code, 
			COLUMN 18,l_rec_salesmgr.name_text 
			SKIP 1 line
			 
		ON EVERY ROW 
			IF p_rec_sperstat.ytd_bdgt_amt = 0 THEN 
				LET l_ytd_achieve_per = 0 
			ELSE 
				LET l_ytd_achieve_per = 100 * 
				(p_rec_sperstat.ytd_net_amt/p_rec_sperstat.ytd_bdgt_amt) 
			END IF 
			IF p_rec_sperstat.mtd_bdgt_amt = 0 THEN 
				LET l_mtd_achieve_per = 0 
			ELSE 
				LET l_mtd_achieve_per = 100 * 
				(p_rec_sperstat.mtd_net_amt/p_rec_sperstat.mtd_bdgt_amt) 
			END IF 
			LET l_total_amt = p_rec_sperstat.back_amt			+ p_rec_sperstat.held_amt			+ p_rec_sperstat.other_amt 
			IF p_rec_sperstat.mtd_orders_num - p_rec_sperstat.mtd_credits_num = 0 THEN 
				LET l_avg_ord_val = 0 
			ELSE 
				LET l_avg_ord_val = p_rec_sperstat.mtd_net_amt / 
				(p_rec_sperstat.mtd_orders_num - p_rec_sperstat.mtd_credits_num) 
			END IF 
			IF p_rec_sperstat.mtd_net_amt = 0 THEN 
				LET l_profit_per = 0 
			ELSE 
				LET l_profit_per = 100 * ((p_rec_sperstat.mtd_net_amt - p_rec_sperstat.mtd_cost_amt)/		p_rec_sperstat.mtd_net_amt) 
			END IF 
			PRINT COLUMN 01, p_rec_sperstat.sale_code, 
			COLUMN 10, p_rec_sperstat.name_text, 
			COLUMN 41, p_rec_sperstat.ytd_net_amt USING "--------&", 
			COLUMN 50, p_rec_sperstat.ytd_bdgt_amt USING "--------&", 
			COLUMN 59, l_ytd_achieve_per USING "---&.&", 
			COLUMN 67, p_rec_sperstat.mtd_net_amt USING "-------&", 
			COLUMN 75, p_rec_sperstat.mtd_bdgt_amt USING "-------&", 
			COLUMN 83, l_mtd_achieve_per USING "---&.&", 
			COLUMN 91, p_rec_sperstat.back_amt USING "------&", 
			COLUMN 98, p_rec_sperstat.held_amt USING "------&", 
			COLUMN 105, p_rec_sperstat.other_amt USING "------&", 
			COLUMN 112, l_total_amt USING "------&", 
			COLUMN 121, p_rec_sperstat.mtd_orders_num USING "-----&", 
			COLUMN 128, p_rec_sperstat.mtd_credits_num USING "-----&", 
			COLUMN 134, l_avg_ord_val USING "-------&", 
			COLUMN 144, p_rec_sperstat.yest_net_amt USING "-------&", 
			COLUMN 154, l_profit_per USING "---&.&"
			 
		AFTER GROUP OF p_rec_sperstat.mgr_code 
			NEED 6 LINES 
			SKIP 1 line 
			IF GROUP sum(p_rec_sperstat.ytd_bdgt_amt) = 0 THEN 
				LET l_ytd_achieve_per = 0 
			ELSE 
				LET l_ytd_achieve_per = 100 * 
				(group sum(p_rec_sperstat.ytd_net_amt) / 
				GROUP sum(p_rec_sperstat.ytd_bdgt_amt)) 
			END IF 
			IF GROUP sum(p_rec_sperstat.mtd_bdgt_amt) = 0 THEN 
				LET l_mtd_achieve_per = 0 
			ELSE 
				LET l_mtd_achieve_per = 100 * 
				(group sum(p_rec_sperstat.mtd_net_amt) / 
				GROUP sum(p_rec_sperstat.mtd_bdgt_amt)) 
			END IF 
			LET l_total_amt = GROUP sum(p_rec_sperstat.back_amt) 
			+ GROUP sum(p_rec_sperstat.held_amt) 
			+ GROUP sum(p_rec_sperstat.other_amt) 
			IF GROUP sum(p_rec_sperstat.mtd_orders_num) - 
			GROUP sum(p_rec_sperstat.mtd_credits_num) = 0 THEN 
				LET l_avg_ord_val = 0 
			ELSE 
				LET l_avg_ord_val = GROUP sum(p_rec_sperstat.mtd_net_amt) / 
				(group sum(p_rec_sperstat.mtd_orders_num) - 
				GROUP sum(p_rec_sperstat.mtd_credits_num)) 
			END IF 
			IF GROUP sum(p_rec_sperstat.mtd_net_amt) = 0 THEN 
				LET l_profit_per = 0 
			ELSE 
				LET l_profit_per = 100 * 
				((group sum(p_rec_sperstat.mtd_net_amt) - 
				GROUP sum(p_rec_sperstat.mtd_cost_amt)) / 
				GROUP sum(p_rec_sperstat.mtd_net_amt)) 
			END IF
			 
			PRINT COLUMN 01, "Manager total", 
			COLUMN 41, GROUP sum(p_rec_sperstat.ytd_net_amt) USING "--------&", 
			COLUMN 50, GROUP sum(p_rec_sperstat.ytd_bdgt_amt) USING "--------&", 
			COLUMN 59, l_ytd_achieve_per USING "---&.&", 
			COLUMN 67, GROUP sum(p_rec_sperstat.mtd_net_amt) USING "-------&", 
			COLUMN 75, GROUP sum(p_rec_sperstat.mtd_bdgt_amt) USING "-------&", 
			COLUMN 83, l_mtd_achieve_per USING "---&.&", 
			COLUMN 91, GROUP sum(p_rec_sperstat.back_amt) USING "------&", 
			COLUMN 98, GROUP sum(p_rec_sperstat.held_amt) USING "------&", 
			COLUMN 105, GROUP sum(p_rec_sperstat.other_amt) USING "------&", 
			COLUMN 112, l_total_amt USING "------&", 
			COLUMN 121, GROUP sum(p_rec_sperstat.mtd_orders_num) USING "-----&", 
			COLUMN 128, GROUP sum(p_rec_sperstat.mtd_credits_num) USING "-----&", 
			COLUMN 134, l_avg_ord_val USING "-------&", 
			COLUMN 144, GROUP sum(p_rec_sperstat.yest_net_amt) USING "-------&", 
			COLUMN 154, l_profit_per USING "---&.&" 
			#
			#IF today NOT in month selected THEN do NOT PRINT reqd & avg sales
			#
			IF today >= modu_rec_statint.start_date 
			AND today <= modu_rec_statint.end_date THEN 
				SELECT sum(salesdays_num) INTO l_sell_days_tot FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statparms.day_type_code 
				AND start_date between modu_rec_statint.start_date 
				AND modu_rec_statint.end_date 
				SELECT sum(salesdays_num) INTO l_sell_days_left FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statparms.day_type_code 
				AND start_date between today AND modu_rec_statint.end_date 
				LET l_sell_days_used = l_sell_days_tot - 
				l_sell_days_left 
				IF l_sell_days_left = 0 THEN 
					LET l_reqd_sales = 0 
				ELSE 
					LET l_reqd_sales = (group sum(p_rec_sperstat.mtd_bdgt_amt) - 
					GROUP sum(p_rec_sperstat.mtd_net_amt)) / l_sell_days_left 
				END IF 
				IF l_sell_days_used = 0 THEN 
					LET l_avg_sales = 0 
				ELSE 
					LET l_avg_sales = GROUP sum(p_rec_sperstat.mtd_net_amt) / 
					l_sell_days_used 
				END IF 
				PRINT COLUMN 01, "Required Sales Per day", 
				COLUMN 67, l_reqd_sales USING "-------&" 
				PRINT COLUMN 01, "Current Avg Daily sales", 
				COLUMN 67, l_avg_sales USING "-------&" 
			END IF 
			
		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 line 
			IF sum(p_rec_sperstat.ytd_bdgt_amt) = 0 THEN 
				LET l_ytd_achieve_per = 0 
			ELSE 
				LET l_ytd_achieve_per = 100 * 
				(sum(p_rec_sperstat.ytd_net_amt) / sum(p_rec_sperstat.ytd_bdgt_amt)) 
			END IF 
			IF sum(p_rec_sperstat.mtd_bdgt_amt) = 0 THEN 
				LET l_mtd_achieve_per = 0 
			ELSE 
				LET l_mtd_achieve_per = 100 * 
				(sum(p_rec_sperstat.mtd_net_amt) / sum(p_rec_sperstat.mtd_bdgt_amt)) 
			END IF 
			LET l_total_amt = sum(p_rec_sperstat.back_amt) 
			+ sum(p_rec_sperstat.held_amt) 
			+ sum(p_rec_sperstat.other_amt) 
			IF sum(p_rec_sperstat.mtd_orders_num) - 
			sum(p_rec_sperstat.mtd_credits_num) = 0 THEN 
				LET l_avg_ord_val = 0 
			ELSE 
				LET l_avg_ord_val = sum(p_rec_sperstat.mtd_net_amt) / 
				(sum(p_rec_sperstat.mtd_orders_num) - sum(p_rec_sperstat.mtd_credits_num)) 
			END IF 
			IF sum(p_rec_sperstat.mtd_net_amt) = 0 THEN 
				LET l_profit_per = 0 
			ELSE 
				LET l_profit_per = 100 * 
				((sum(p_rec_sperstat.mtd_net_amt) - sum(p_rec_sperstat.mtd_cost_amt)) / 
				sum(p_rec_sperstat.mtd_net_amt)) 
			END IF 
			PRINT COLUMN 01, "Report totals", 
			COLUMN 41, sum(p_rec_sperstat.ytd_net_amt) USING "--------&", 
			COLUMN 50, sum(p_rec_sperstat.ytd_bdgt_amt) USING "--------&", 
			COLUMN 59, l_ytd_achieve_per USING "---&.&", 
			COLUMN 67, sum(p_rec_sperstat.mtd_net_amt) USING "-------&", 
			COLUMN 75, sum(p_rec_sperstat.mtd_bdgt_amt) USING "-------&", 
			COLUMN 83, l_mtd_achieve_per USING "---&.&", 
			COLUMN 91, sum(p_rec_sperstat.back_amt) USING "------&", 
			COLUMN 98, sum(p_rec_sperstat.held_amt) USING "------&", 
			COLUMN 105, sum(p_rec_sperstat.other_amt) USING "------&", 
			COLUMN 112, l_total_amt USING "------&", 
			COLUMN 121, sum(p_rec_sperstat.mtd_orders_num) USING "-----&", 
			COLUMN 128, sum(p_rec_sperstat.mtd_credits_num) USING "-----&", 
			COLUMN 134, l_avg_ord_val USING "-------&", 
			COLUMN 144, sum(p_rec_sperstat.yest_net_amt) USING "-------&", 
			COLUMN 154, l_profit_per USING "---&.&"
			 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
###########################################################################
# END REPORT ET9_rpt_list(p_rpt_idx.p_rec_sperstat)  
###########################################################################