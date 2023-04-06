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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ES4_GLOBALS.4gl" 
###########################################################################
# FUNCTION ES4_main()  
#
# 
###########################################################################
FUNCTION ES4_main() 
	DEFINE l_verbose_ind SMALLINT 
	DEFINE l_arg_verbose BOOLEAN #from URL
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ES4") -- albo 

	IF fgl_find_table("t_profit") THEN
		DELETE FROM t_profit
	ELSE
		CREATE temp TABLE t_profit (dept_code char(1), 
		cust_code char(8), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3)) with no LOG
	END IF
	
	LET l_arg_verbose = get_url_verbose()	 
	IF l_arg_verbose IS NOT NULL THEN 
		# WHEN called with arguements, it means it IS run in background
		LET glob_rec_kandoouser.cmpy_code = l_arg_verbose
		LET l_verbose_ind = FALSE 
		CALL ES4_unload_orderdetlog(l_verbose_ind) 
	ELSE 
		LET l_verbose_ind = TRUE
		 
		OPEN WINDOW E452 with FORM "E452" 
		 CALL windecoration_e("E452") 

		MENU " Order Log unload" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","ES4","menu-Order_Log-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
			COMMAND "Unload" " Commence unload process" 
				CALL ES4_unload_orderdetlog(l_verbose_ind) 
				NEXT option "PRINT MANAGER" 

			ON ACTION "Print" #COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog ("URS","","","","") 

			COMMAND "Directory" " List entries in a specified directory" 
				CALL show_directory() 
				NEXT option "Unload" 

			ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit Order load" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 
		CLOSE WINDOW E452 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ES4_main()  
###########################################################################


###########################################################################
# FUNCTION ES4_unload_orderdetlog(l_verbose_ind)   
#
# 
###########################################################################
FUNCTION ES4_unload_orderdetlog(l_verbose_ind) 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index		
	DEFINE l_verbose_ind SMALLINT 
	DEFINE l_rec_profit RECORD 
		dept_code char(1), 
		cust_code char(8), 
		part_code char(15), 
		soh char(8), 
		suggested_stock char(8), 
		maxstk char(8), 
		previous_stock char(8), 
		actual_stock char(8), 
		order_ref char(10), 
		sales1 char(8), 
		sales2 char(8), 
		sales3 char(8), 
		sales4 char(8), 
		ware_code char(3) 
	END RECORD 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_orderdetlog RECORD LIKE orderdetlog.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_load_file_tmp char(80) 
	DEFINE l_load_file char(80)	 
	DEFINE l_runner char(400) 
	DEFINE l_err_text char(200) 
	DEFINE l_unloaded INTEGER 
	DEFINE l_rowid INTEGER 
	DEFINE l_ret_code INTEGER 
	DEFINE l_time char(8) 

	DECLARE c_loadparms cursor FOR 
	SELECT * FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = 'EO' 
	AND format_ind = '1' 
	ORDER BY load_ind 
	OPEN c_loadparms 

	FETCH c_loadparms INTO l_rec_loadparms.* 
	LET l_time = time 
	LET l_time = l_time[1,2],l_time[4,5],l_time[7,8] 
	LET l_rec_loadparms.file_text = "MXO", today USING "yyyymmdd", l_time clipped 

	IF l_verbose_ind THEN 
		DISPLAY BY NAME l_rec_loadparms.file_text,l_rec_loadparms.path_text 

		WHILE TRUE 
			MESSAGE kandoomsg2("U",1020,"File/Path") 	#1020 Enter File/Path Details; OK TO Continue.
			INPUT BY NAME l_rec_loadparms.file_text, l_rec_loadparms.path_text WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","ES4","input-l_rec_loadparms-1") -- albo kd-502 

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				AFTER FIELD file_text 
					IF l_rec_loadparms.file_text IS NULL THEN 
						ERROR kandoomsg2("A",9166,"") 	#9166 File name must be entered
						NEXT FIELD file_text 
					END IF 
					
				AFTER FIELD path_text 
					IF l_rec_loadparms.path_text IS NULL THEN 
						MESSAGE kandoomsg2("A",8015,"") 	#8015 Current UNIX path will be defaulted
					END IF
					 
				AFTER INPUT 
					IF NOT (int_flag OR quit_flag) THEN 
						IF l_rec_loadparms.path_text IS NULL 
						OR length(l_rec_loadparms.path_text) = 0 THEN 
							LET l_rec_loadparms.path_text = "." 
						END IF 
						LET l_load_file = l_rec_loadparms.path_text clipped, 
						"/",l_rec_loadparms.file_text clipped 
						IF NOT is_path_valid(l_rec_loadparms.path_text) THEN 
							ERROR kandoomsg2("U",9128,"") 
							NEXT FIELD path_text 
						END IF 
					END IF 

			END INPUT
			 
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				RETURN 
			END IF
			 
			MESSAGE kandoomsg2("U",1001,"") #1001 Enter Selection Criteria; OK TO Continue

			CONSTRUCT BY NAME l_where_text ON orderdetlog.order_num, 
			orderhead.cust_code, 
			orderdetlog.part_code, 
			orderdetlog.ammend_date 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","ES4","construct-orderdetlog-1") -- albo kd-502 

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				CONTINUE WHILE 
			END IF 
			EXIT WHILE 

		END WHILE 

		MESSAGE kandoomsg2("U",1002,"") 	#1002 Searching Database; Please Wait.

	ELSE 
		LET l_load_file = l_rec_loadparms.path_text clipped, 
		"/",l_rec_loadparms.file_text clipped 
		IF NOT is_path_valid(l_rec_loadparms.path_text) THEN 
			LET l_err_text = 'es4 - invalid filename:', 
			l_load_file clipped 
			CALL errorlog(l_err_text) 
			RETURN 
		END IF 
		LET l_where_text = '1=1' 
	END IF 
	
	LET l_query_text = "SELECT orderdetlog.rowid, orderdetlog.* ", 
	" FROM orderdetlog, orderhead ", 
	" WHERE orderdetlog.order_num = orderhead.order_num ", 
	" AND orderdetlog.cmpy_code = orderhead.cmpy_code ", 
	" AND ",l_where_text clipped," ", 
	" AND update_ind != 'C'", 
	" AND orderhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'" 
	PREPARE s_orderdetlog FROM l_query_text 
	DECLARE c_orderdetlog cursor FOR s_orderdetlog
	 
	DELETE FROM t_profit 
	WHERE 1=1
	 
	INITIALIZE l_rec_orderdetlog.* TO NULL 
	INITIALIZE l_rec_orderhead.* TO NULL 
	LET l_unloaded = 0 

	IF l_verbose_ind THEN 
		--      OPEN WINDOW w1 AT 11,20 with 1 rows, 30 columns  -- albo  KD-755
		--         ATTRIBUTE(border)
		 CALL windecoration_e("E452") -- albo kd-755 
		DISPLAY "Unloading Order: " at 1,2 

	END IF 

	FOREACH c_orderdetlog INTO l_rowid, l_rec_orderdetlog.* 
		SELECT * INTO l_rec_orderhead.* FROM orderhead 
		WHERE order_num = l_rec_orderdetlog.order_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF l_verbose_ind THEN 
			DISPLAY l_rec_orderhead.order_num at 1,19 

		END IF 
		LET l_rec_profit.dept_code = NULL 
		LET l_rec_profit.cust_code = l_rec_orderhead.cust_code 
		LET l_rec_profit.part_code = l_rec_orderdetlog.part_code 
		LET l_rec_profit.soh = NULL 
		LET l_rec_profit.suggested_stock = NULL 
		LET l_rec_profit.maxstk = NULL 
		LET l_rec_profit.previous_stock = l_rec_orderdetlog.pre_qty 
		LET l_rec_profit.actual_stock = l_rec_orderdetlog.post_qty 
		LET l_rec_profit.order_ref = NULL 
		LET l_rec_profit.sales1 = NULL 
		LET l_rec_profit.sales2 = NULL 
		LET l_rec_profit.sales3 = NULL 
		LET l_rec_profit.sales4 = NULL 
		LET l_rec_profit.ware_code = l_rec_orderhead.ware_code 

		INSERT INTO t_profit VALUES (l_rec_profit.*) 
		UPDATE orderdetlog 
		SET update_ind = "C" 
		WHERE rowid = l_rowid 
		#       WHERE cmpy_code = l_rec_orderdetlog.cmpy_code
		#         AND order_num = l_rec_orderdetlog.order_num
		#         AND line_num = l_rec_orderdetlog.line_num
		#         AND part_code = l_rec_orderdetlog.part_code
		#         AND pre_qty = l_rec_orderdetlog.pre_qty
		#         AND post_qty = l_rec_orderdetlog.post_qty
		#         AND pre_price_amt = l_rec_orderdetlog.pre_price_amt
		#         AND pre_tax_amt = l_rec_orderdetlog.pre_tax_amt
		#         AND post_tax_amt = l_rec_orderdetlog.post_tax_amt
		#         AND ammend_date = l_rec_orderdetlog.ammend_date
		#         AND ammend_time = l_rec_orderdetlog.ammend_time
		#         AND ammend_code = l_rec_orderdetlog.ammend_code
		#         AND update_ind = l_rec_orderdetlog.update_ind
		LET l_unloaded = l_unloaded + 1 
	END FOREACH 

	LET l_load_file_tmp = l_load_file clipped, '.tmp' 
	UNLOAD TO l_load_file_tmp SELECT * FROM t_profit 
	
	#Needs addressing !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	LET l_runner = " mv ", l_load_file_tmp clipped," ", 
	l_load_file clipped," 2>> ", trim(get_settings_logFile()) 
	--RUN l_runner RETURNING l_ret_code 
	CALL fgl_winmessage("l_runner stuff needs adopting/migrating",l_runner,"info")
	#Needs addressing !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	IF l_unloaded <> 0 THEN 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"ES4_rpt_list_unload_summary","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ES4_rpt_list_unload_summary TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	#---------------------------------------------------------
	OUTPUT TO REPORT ES4_rpt_list_unload_summary(l_rpt_idx,
	l_unloaded) 
	#---------------------------------------------------------		
	#------------------------------------------------------------
	FINISH REPORT ES4_rpt_list_unload_summary
	CALL rpt_finish("ES4_rpt_list_unload_summary")
	#------------------------------------------------------------
	END IF 
	IF l_verbose_ind THEN 
		--      CLOSE WINDOW w1  -- albo  KD-755
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ES4_unload_orderdetlog(l_verbose_ind)   
###########################################################################


###########################################################################
# REPORT ES4_rpt_list_unload_summary(p_what_record_unloaded)   
#
# 
###########################################################################
REPORT ES4_rpt_list_unload_summary(p_rpt_idx,p_what_record_unloaded) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_what_record_unloaded INTEGER 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
		ON EVERY ROW 
			PRINT COLUMN 01, " Total Order Lines Unloaded: ", p_what_record_unloaded USING "#######&" 

		ON LAST ROW 
			SKIP 4 LINES 
			PRINT COLUMN 01, 23 spaces,"***** END OF REPORT - ES4 *****" 
END REPORT 
###########################################################################
# END REPORT ES4_rpt_list_unload_summary(p_what_record_unloaded)   
###########################################################################