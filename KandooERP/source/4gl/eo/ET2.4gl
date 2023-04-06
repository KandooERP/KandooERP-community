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
DEFINE modu_arr_total array[2] OF RECORD 
	grs_amt LIKE statsper.grs_amt, 
	net_amt LIKE statsper.net_amt, 
	bdgt_amt LIKE stattarget.bdgt_amt, 
	orders_num LIKE statsper.orders_num, 
	credits_num LIKE statsper.credits_num 
END RECORD 
DEFINE modu_print_targ_flag char(1) 
###########################################################################
# MAIN
#
# ET2 Sales Manager/Person Monthly Turnover
###########################################################################
FUNCTION ET2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET2") 

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E277 with FORM "E277" 
			 CALL windecoration_e("E277") -- albo kd-755 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
			MENU " Sales Manager Weekly turnover" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET2","menu-Sales_Manager-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET2_rpt_process(ET2_rpt_query())
								
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET2_rpt_process(ET2_rpt_query())
		
				ON ACTION "PRINT MANAGER"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY("E",INTERRUPT)"Exit" " Exit TO menus" 
					EXIT MENU 
			END MENU 
			CLOSE WINDOW E277 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E277 with FORM "E277" 
			 CALL windecoration_e("E277") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E277 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET2_rpt_process(get_url_sel_text())
	END CASE 	
				
END FUNCTION
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION ET2_rpt_query()
#
# CONSTRUCT where clause for report data
# RETURN NULL or l_where_text
###########################################################################
FUNCTION ET2_rpt_query() 
	DEFINE l_where_text STRING

	IF (NOT ET2_enter_interval()) OR (int_flag = TRUE) THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF
		 

	MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON mgr_code, 
	name_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET2","construct-mgr_code-1") -- albo kd-502 

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
# END FUNCTION ET2_rpt_query()
###########################################################################


###########################################################################
# FUNCTION ET2_enter_interval() 
#
#
###########################################################################
FUNCTION ET2_enter_interval()
--	DEFINE modu_rec_statint RECORD LIKE statint.*	
	DEFINE l_temp_text char(100) 

	LET modu_print_targ_flag = xlate_to("Y") 
	LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
	LET modu_rec_statint.int_num = modu_rec_statparms.week_num
	 
	MESSAGE kandoomsg("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue
	INPUT 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_print_targ_flag WITHOUT DEFAULTS
	FROM 
		year_num, 
		int_text, 
		print_targ_flag
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET2","input-l_rec_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" INFIELD (int_text)  
				LET l_temp_text = "year_num = '",modu_rec_statint.year_num,"' ", 
				"AND type_code = '",modu_rec_statparms.week_type_code,"'" 
				LET l_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,l_temp_text) 
				IF l_temp_text IS NOT NULL THEN 
					LET modu_rec_statint.int_num = l_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num - 1 
			NEXT FIELD year_num 
			
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
			NEXT FIELD year_num 
			
		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_statint.* FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.week_type_code 
			AND int_num = modu_rec_statint.int_num 
			DISPLAY BY NAME modu_rec_statint.int_text, 
			modu_rec_statint.start_date, 
			modu_rec_statint.end_date 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 
			
		BEFORE FIELD int_text 
			SELECT int_text INTO modu_rec_statint.int_text FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = modu_rec_statparms.week_type_code 
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
				AND type_code = modu_rec_statparms.week_type_code 
				AND int_text = modu_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"")		#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = modu_rec_statparms.week_num 
					NEXT FIELD int_text 
				END IF 
			END IF 
			DISPLAY BY NAME modu_rec_statint.start_date, modu_rec_statint.end_date 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET glob_rec_rpt_selector.ref1_num = modu_rec_statint.year_num
		LET glob_rec_rpt_selector.ref1_code = modu_rec_statint.type_code
		LET glob_rec_rpt_selector.ref1_date = modu_rec_statint.start_date
		LET glob_rec_rpt_selector.ref1_ind = modu_rec_statint.dist_flag

		LET glob_rec_rpt_selector.ref2_num = modu_rec_statint.int_num
		LET glob_rec_rpt_selector.ref2_date = modu_rec_statint.end_date
		LET glob_rec_rpt_selector.ref2_code = modu_rec_statint.int_text
		LET glob_rec_rpt_selector.ref2_ind = modu_rec_statint.updreq_flag

		RETURN TRUE 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION ET2_enter_interval() 
###########################################################################


###########################################################################
# FUNCTION ET2_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_rec_statint RECORD LIKE statint.*
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	#get additional rms_reps values for query
	LET l_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_num 
	LET l_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_code
	LET l_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_date			
	LET l_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref1_ind	
		
	LET l_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_num			
	LET l_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_date
	LET l_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_code
	LET l_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	LET l_query_text = "SELECT * FROM salesmgr ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET2_rpt_list")].sel_text clipped," ",		 
	"ORDER BY 1,2" 
	PREPARE s_salesmgr FROM l_query_text 
	DECLARE c_salesmgr cursor FOR s_salesmgr
	 
	LET l_query_text = "SELECT * FROM statsper ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = '",l_rec_statint.year_num,"' ", 
	"AND type_code = '",l_rec_statint.type_code,"' ", 
	"AND int_num = '",l_rec_statint.int_num,"' ", 
	"AND mgr_code = ? ", 
	"AND sale_code IS NOT NULL " 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 

	--MESSAGE kandoomsg2("E",1158,"") 	#1045 Reporting on Manager...
	LET modu_arr_total[2].grs_amt = 0 
	LET modu_arr_total[2].net_amt = 0 
	LET modu_arr_total[2].orders_num = 0 
	LET modu_arr_total[2].bdgt_amt = 0 
	LET modu_arr_total[2].credits_num = 0
	 
	FOREACH c_salesmgr INTO l_rec_salesmgr.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT ET2_rpt_list(l_rpt_idx,
			l_rec_salesmgr.*)  
			IF NOT rpt_int_flag_handler2("Sales Manager:",l_rec_salesmgr.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ET2_rpt_list
	CALL rpt_finish("ET2_rpt_list")
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
# END FUNCTION ET2_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ET2_rpt_list(p_rpt_idx,p_rec_salesmgr) 
#
#
###########################################################################
REPORT ET2_rpt_list(p_rpt_idx,p_rec_salesmgr) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_salesmgr RECORD LIKE salesmgr.*
	DEFINE l_rec_statsper RECORD LIKE statsper.*
	DEFINE l_disc_per FLOAT
	DEFINE l_achieve_per FLOAT
	DEFINE l_bdgt_amt LIKE stattarget.bdgt_amt
	DEFINE l_avg_ord_val LIKE statsper.net_amt
	DEFINE l_name_text LIKE salesperson.name_text
	DEFINE l_sales_ind SMALLINT 
	DEFINE i SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_salesmgr.cmpy_code, p_rec_salesmgr.mgr_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text	
 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		BEFORE GROUP OF p_rec_salesmgr.mgr_code 
			NEED 5 LINES 
			PRINT COLUMN 01,"Manager:", 
			COLUMN 09,p_rec_salesmgr.mgr_code, 
			COLUMN 18,p_rec_salesmgr.name_text 
			LET modu_arr_total[1].grs_amt = 0 
			LET modu_arr_total[1].net_amt = 0 
			LET modu_arr_total[1].orders_num = 0 
			LET modu_arr_total[1].credits_num = 0 
			LET l_sales_ind = TRUE 
			
			OPEN c_statsper USING p_rec_salesmgr.mgr_code 
			FOREACH c_statsper INTO l_rec_statsper.* 
				IF l_rec_statsper.grs_amt = 0 THEN 
					LET l_disc_per = 0 
				ELSE 
					LET l_disc_per = 100 * 
					(1-(l_rec_statsper.net_amt/l_rec_statsper.grs_amt)) 
				END IF 
				IF l_rec_statsper.orders_num - l_rec_statsper.credits_num = 0 THEN 
					LET l_avg_ord_val = 0 
				ELSE 
					LET l_avg_ord_val = l_rec_statsper.net_amt / 
					(l_rec_statsper.orders_num - l_rec_statsper.credits_num) 
				END IF 
				IF modu_print_targ_flag = "Y" THEN 
					SELECT bdgt_amt INTO l_bdgt_amt FROM stattarget 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bdgt_type_ind = "4" 
					AND bdgt_type_code = l_rec_statsper.sale_code 
					AND bdgt_ind = "1" 
					AND year_num = modu_rec_statint.year_num 
					AND type_code = modu_rec_statint.type_code 
					AND int_num = modu_rec_statint.int_num 
					IF status = NOTFOUND THEN 
						LET l_bdgt_amt = 0 
					END IF 
					IF l_bdgt_amt = 0 THEN 
						LET l_achieve_per = 0 
					ELSE 
						LET l_achieve_per = 100 * (l_rec_statsper.net_amt/l_bdgt_amt) 
					END IF 
				ELSE 
					LET l_bdgt_amt = NULL 
					LET l_achieve_per = NULL 
				END IF 
				SELECT name_text INTO l_name_text FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_rec_statsper.sale_code 
				IF l_sales_ind THEN 
					LET l_sales_ind = FALSE 
					PRINT COLUMN 13,"Salespersons:" 
				END IF 
				PRINT COLUMN 15, l_rec_statsper.sale_code, 
				COLUMN 24, l_name_text, 
				COLUMN 55, l_rec_statsper.grs_amt USING "---,---,--&", 
				COLUMN 67, l_rec_statsper.net_amt USING "---,---,--&", 
				COLUMN 79, l_disc_per USING "---&.&", 
				COLUMN 87, l_bdgt_amt USING "---,---,--&", 
				COLUMN 99, l_achieve_per USING "---&.&", 
				COLUMN 106, l_rec_statsper.orders_num USING "---,--&", 
				COLUMN 114, l_rec_statsper.credits_num USING "---,--&", 
				COLUMN 122, l_avg_ord_val USING "---,---,--&" 
				LET modu_arr_total[1].grs_amt = modu_arr_total[1].grs_amt 
				+ l_rec_statsper.grs_amt 
				LET modu_arr_total[1].net_amt = modu_arr_total[1].net_amt 
				+ l_rec_statsper.net_amt 
				LET modu_arr_total[1].credits_num = modu_arr_total[1].credits_num 
				+ l_rec_statsper.credits_num 
				LET modu_arr_total[1].orders_num = modu_arr_total[1].orders_num 
				+ l_rec_statsper.orders_num 
			END FOREACH 
			# PRINT totals
			IF modu_arr_total[1].grs_amt = 0 THEN 
				LET l_disc_per = 0 
			ELSE 
				LET l_disc_per = 100 * 
				(1-(modu_arr_total[1].net_amt/modu_arr_total[1].grs_amt)) 
			END IF 
			IF modu_arr_total[1].orders_num - modu_arr_total[1].credits_num = 0 THEN 
				LET l_avg_ord_val = 0 
			ELSE 
				LET l_avg_ord_val = modu_arr_total[1].net_amt / 
				(modu_arr_total[1].orders_num - modu_arr_total[1].credits_num) 
			END IF 
			IF modu_print_targ_flag = "Y" THEN 
				SELECT bdgt_amt 
				INTO l_bdgt_amt 
				FROM stattarget 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bdgt_type_ind = "3" 
				AND bdgt_type_code = p_rec_salesmgr.mgr_code 
				AND bdgt_ind = "1" 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statint.type_code 
				AND int_num = modu_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_bdgt_amt = 0 
				END IF 
				IF l_bdgt_amt = 0 THEN 
					LET l_achieve_per = 0 
				ELSE 
					LET l_achieve_per = 100 * (modu_arr_total[1].net_amt/l_bdgt_amt) 
				END IF 
			ELSE 
				LET l_bdgt_amt = NULL 
				LET l_achieve_per = NULL 
			END IF 
			NEED 4 LINES 
			PRINT COLUMN 03, "Total:", 
			COLUMN 55, modu_arr_total[1].grs_amt USING "---,---,--&", 
			COLUMN 67, modu_arr_total[1].net_amt USING "---,---,--&", 
			COLUMN 79, l_disc_per USING "---&.&", 
			COLUMN 87, l_bdgt_amt USING "---,---,--&", 
			COLUMN 99, l_achieve_per USING "---&.&", 
			COLUMN 106, modu_arr_total[1].orders_num USING "---,--&", 
			COLUMN 114, modu_arr_total[1].credits_num USING "---,--&", 
			COLUMN 122, l_avg_ord_val USING "---,---,--&" 
			SKIP 2 LINES 
			LET modu_arr_total[2].grs_amt = modu_arr_total[2].grs_amt + modu_arr_total[1].grs_amt 
			LET modu_arr_total[2].net_amt = modu_arr_total[2].net_amt + modu_arr_total[1].net_amt 
			LET modu_arr_total[2].bdgt_amt = modu_arr_total[2].bdgt_amt + l_bdgt_amt 
			LET modu_arr_total[2].credits_num = modu_arr_total[2].credits_num 
			+ modu_arr_total[1].credits_num 
			LET modu_arr_total[2].orders_num = modu_arr_total[2].orders_num 
			+ modu_arr_total[1].orders_num 
		ON LAST ROW 
			# PRINT REPORT totals
			IF modu_arr_total[2].grs_amt = 0 THEN 
				LET l_disc_per = 0 
			ELSE 
				LET l_disc_per = 100 * 
				(1-(modu_arr_total[2].net_amt/modu_arr_total[2].grs_amt)) 
			END IF 
			IF modu_arr_total[2].orders_num - modu_arr_total[2].credits_num = 0 THEN 
				LET l_avg_ord_val = 0 
			ELSE 
				LET l_avg_ord_val = modu_arr_total[2].net_amt / 
				(modu_arr_total[2].orders_num - modu_arr_total[2].credits_num) 
			END IF 
			#will always be NULL IF NOT printing targets
			IF modu_arr_total[2].bdgt_amt = 0 THEN 
				LET l_achieve_per = 0 
			ELSE 
				LET l_achieve_per = 100 * (modu_arr_total[1].net_amt/modu_arr_total[2].bdgt_amt) 
			END IF 
			NEED 4 LINES 
			PRINT COLUMN 03, "Report total:", 
			COLUMN 55, modu_arr_total[2].grs_amt USING "---,---,--&", 
			COLUMN 67, modu_arr_total[2].net_amt USING "---,---,--&", 
			COLUMN 79, l_disc_per USING "---&.&", 
			COLUMN 87, modu_arr_total[2].bdgt_amt USING "---,---,--&", 
			COLUMN 99, l_achieve_per USING "---&.&", 
			COLUMN 106, modu_arr_total[2].orders_num USING "---,--&", 
			COLUMN 114, modu_arr_total[2].credits_num USING "---,--&", 
			COLUMN 122, l_avg_ord_val USING "---,---,--&" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT
###########################################################################
# END REPORT ET2_rpt_list(p_rpt_idx,p_rec_salesmgr) 
###########################################################################