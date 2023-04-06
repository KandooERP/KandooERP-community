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
GLOBALS "../eo/EU_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EU2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_rec_criteria RECORD 
	part_ind char(1), 
	pgrp_ind char(1), 
	mgrp_ind char(1) 
END RECORD 
DEFINE modu_order_ind char(1) 
DEFINE modu_temp_text STRING 
###########################################################################
# FUNCTION EU2_main()
#
# EU2 Inventory/Customer Turnover Report
###########################################################################
FUNCTION EU2_main() 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EU2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		 
			OPEN WINDOW E289 with FORM "E289" 
			 CALL windecoration_e("E289") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text 
			
			MENU " Inventory/Customer turnover" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EU2","menu-Inventory-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EU2_rpt_process(EU2_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
					
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report"
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EU2_rpt_process(EU2_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
			CLOSE WINDOW E289 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EU2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E289 with FORM "E289" 
			 CALL windecoration_e("E289") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EU2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E289 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EU2_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 


###########################################################################
# FUNCTION EU2_rpt_query() 
#
# EU2 Inventory/Customer Turnover Report
###########################################################################
FUNCTION EU2_rpt_query() 
	DEFINE l_where_text STRING


	IF NOT EU2_rpt_year_entry() OR int_flag = TRUE THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF 

	MESSAGE kandoomsg("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON part_code, 
	prodgrp_code, 
	maingrp_code, 
	cust_code, 
	sale_code, 
	mgr_code, 
	terr_code, 
	area_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EU2","construct-part_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD part_code 
			IF modu_order_ind > 1 THEN 
				NEXT FIELD prodgrp_code 
			END IF 
			
		BEFORE FIELD prodgrp_code 
			IF modu_order_ind > 2 THEN 
				NEXT FIELD maingrp_code 
			END IF 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref3_ind = modu_order_ind	

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

############################################################
# FUNCTION EU2_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EU2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_cur_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_prv_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_cy_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_py_statsale RECORD LIKE statsale.* 
	DEFINE l_year_num LIKE statint.year_num 
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_where2_text,l_where3_text char(100) 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EU2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EU2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref3_ind

	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	CASE modu_order_ind 
		WHEN "1" 
			LET l_where2_text = "part_code IS NOT NULL AND ", 
			"prodgrp_code IS NOT null" 
		WHEN "2" 
			LET l_where2_text = "part_code IS NULL AND ", 
			"prodgrp_code IS NOT null" 
		WHEN "3" 
			LET l_where2_text = "part_code IS NULL AND ", 
			"prodgrp_code IS null" 
	END CASE 
	
	LET l_query_text = "SELECT * FROM statsale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND type_code = '",glob_rec_statparms.mth_type_code,"' ", 
	"AND year_num = ? ", 
	"AND int_num between ? AND ? ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EU2_rpt_list")].sel_text clipped," ",
	"AND ",l_where2_text clipped 
	
	#Note: There IS no ORDER BY clause because data IS sent TO the REPORT
	#      in blocks. An ORDER internal IS executed in the REPORT section.
	
	PREPARE s_statsale FROM l_query_text 
	DECLARE c_statsale cursor FOR s_statsale 

	#
	# The following section IS coded this way TO cater FOR the following:
	#    Customers NOT in current period but have YTD
	#    Customers NOT in current period OR YTD but have activity last year..
	#
	
	OPEN c_statsale USING modu_rec_statint.year_num, 
	modu_rec_statint.int_num, 
	modu_rec_statint.int_num 
	
	FOREACH c_statsale INTO l_rec_cur_statsale.* 

		SELECT name_text INTO l_name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_cur_statsale.cust_code 

		LET l_rec_prv_statsale.* = l_rec_cur_statsale.* 
		LET l_rec_prv_statsale.gross_amt = 0 
		LET l_rec_prv_statsale.net_amt = 0 
		LET l_rec_prv_statsale.sales_qty = 0 
		#
		LET l_rec_cy_statsale.* = l_rec_cur_statsale.* 
		LET l_rec_cy_statsale.gross_amt = 0 
		LET l_rec_cy_statsale.net_amt = 0 
		LET l_rec_cy_statsale.sales_qty = 0 
		#
		LET l_rec_py_statsale.* = l_rec_cur_statsale.* 
		LET l_rec_py_statsale.gross_amt = 0 
		LET l_rec_py_statsale.net_amt = 0 
		LET l_rec_py_statsale.sales_qty = 0 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU2_rpt_list(l_rpt_idx,
		l_rec_cur_statsale.*, 
		l_rec_prv_statsale.*, 
		l_rec_cy_statsale.*, 
		l_rec_py_statsale.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_name_text,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 
	
	LET l_year_num = modu_rec_statint.year_num - 1 
	OPEN c_statsale USING l_year_num, 
	modu_rec_statint.int_num, 
	modu_rec_statint.int_num 
	
	FOREACH c_statsale INTO l_rec_prv_statsale.* 
		LET l_rec_cur_statsale.* = l_rec_prv_statsale.* 
		LET l_rec_cur_statsale.net_amt = 0 
		LET l_rec_cur_statsale.gross_amt = 0 
		LET l_rec_cur_statsale.sales_qty = 0 
		#
		LET l_rec_cy_statsale.* = l_rec_prv_statsale.* 
		LET l_rec_cy_statsale.net_amt = 0 
		LET l_rec_cy_statsale.gross_amt = 0 
		LET l_rec_cy_statsale.sales_qty = 0 
		#
		LET l_rec_py_statsale.* = l_rec_prv_statsale.* 
		LET l_rec_py_statsale.net_amt = 0 
		LET l_rec_py_statsale.gross_amt = 0 
		LET l_rec_py_statsale.sales_qty = 0 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU2_rpt_list(l_rpt_idx,
		l_rec_cur_statsale.*, 
		l_rec_prv_statsale.*, 
		l_rec_cy_statsale.*, 
		l_rec_py_statsale.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_cur_statsale.cust_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------


	END FOREACH 
	
	LET l_int_num = 1 
	
	OPEN c_statsale USING modu_rec_statint.year_num, 
	l_int_num, 
	modu_rec_statint.int_num 
	
	FOREACH c_statsale INTO l_rec_cy_statsale.* 
		LET l_rec_cur_statsale.* = l_rec_cy_statsale.* 
		LET l_rec_cur_statsale.net_amt = 0 
		LET l_rec_cur_statsale.gross_amt = 0 
		LET l_rec_cur_statsale.sales_qty = 0 
		#
		LET l_rec_prv_statsale.* = l_rec_cy_statsale.* 
		LET l_rec_prv_statsale.net_amt = 0 
		LET l_rec_prv_statsale.gross_amt = 0 
		LET l_rec_prv_statsale.sales_qty = 0 
		#
		LET l_rec_py_statsale.* = l_rec_cy_statsale.* 
		LET l_rec_py_statsale.net_amt = 0 
		LET l_rec_py_statsale.gross_amt = 0 
		LET l_rec_py_statsale.sales_qty = 0 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU2_rpt_list(l_rpt_idx,
		l_rec_cur_statsale.*, 
		l_rec_prv_statsale.*, 
		l_rec_cy_statsale.*, 
		l_rec_py_statsale.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_cy_statsale.cust_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

	END FOREACH 
	
	OPEN c_statsale USING l_year_num, 
	l_int_num, 
	modu_rec_statint.int_num 
	
	FOREACH c_statsale INTO l_rec_py_statsale.* 
		LET l_rec_cur_statsale.* = l_rec_py_statsale.* 
		LET l_rec_cur_statsale.net_amt = 0 
		LET l_rec_cur_statsale.gross_amt = 0 
		LET l_rec_cur_statsale.sales_qty = 0 
		#
		LET l_rec_prv_statsale.* = l_rec_py_statsale.* 
		LET l_rec_prv_statsale.net_amt = 0 
		LET l_rec_prv_statsale.gross_amt = 0 
		LET l_rec_prv_statsale.sales_qty = 0 
		#
		LET l_rec_cy_statsale.* = l_rec_py_statsale.* 
		LET l_rec_cy_statsale.net_amt = 0 
		LET l_rec_cy_statsale.gross_amt = 0 
		LET l_rec_cy_statsale.sales_qty = 0 

		#---------------------------------------------------------
		OUTPUT TO REPORT EU2_rpt_list(l_rpt_idx,
		l_rec_cur_statsale.*, 
		l_rec_prv_statsale.*, 
		l_rec_cy_statsale.*, 
		l_rec_py_statsale.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_py_statsale.cust_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT EU2_rpt_list
	CALL rpt_finish("EU2_rpt_list")
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
# FUNCTION EU2_rpt_year_entry()  
#
# 
###########################################################################
FUNCTION EU2_rpt_year_entry() 

	LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
	LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 
	LET modu_order_ind = "3"
	 
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_order_ind WITHOUT DEFAULTS 
	FROM
		year_num, 
		int_text, 
		order_ind ATTRIBUTE(UNBUFFERED)
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EU2","input-year_num-1") -- albo kd-502 

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

		BEFORE FIELD year_num 
			SELECT * INTO modu_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = modu_rec_statint.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			AND int_num = modu_rec_statint.int_num 
			DISPLAY BY NAME modu_rec_statint.int_text, 
			modu_rec_statint.start_date, 
			modu_rec_statint.end_date 

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
				ERROR kandoomsg2("E",9222,"") 			#9222 Interval must be entered"
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
					ERROR kandoomsg2("E",9223,"") 				#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF
			 
			DISPLAY BY NAME modu_rec_statint.start_date, 
			modu_rec_statint.end_date 

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
# REPORT EU2_rpt_list(p_rec_cur_statsale,  
#
# 
###########################################################################
REPORT EU2_rpt_list(p_rpt_idx,
	p_rec_cur_statsale, 
	p_rec_prv_statsale, 
	p_rec_cy_statsale, 
	p_rec_py_statsale)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_cur_statsale RECORD LIKE statsale.* 
	DEFINE p_rec_prv_statsale RECORD LIKE statsale.* 
	DEFINE p_rec_cy_statsale RECORD LIKE statsale.* 
	DEFINE p_rec_py_statsale RECORD LIKE statsale.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_name_text LIKE customer.name_text 
	DEFINE l_city_text LIKE customer.name_text 
	DEFINE l_addr_text LIKE customer.name_text 	
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_disc1_per FLOAT
	DEFINE l_disc2_per FLOAT
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE l_year_num SMALLINT 
	DEFINE x SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 

	OUTPUT 

	ORDER BY p_rec_cur_statsale.cmpy_code, 
	p_rec_cur_statsale.maingrp_code, 
	p_rec_cur_statsale.prodgrp_code, 
	p_rec_cur_statsale.part_code, 
	p_rec_cur_statsale.cust_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[1]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_rec_cur_statsale.part_code 
			IF modu_order_ind = "1" THEN 
				SKIP 1 line 
				NEED 8 LINES 
				SELECT desc_text INTO l_desc_text FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_cur_statsale.part_code 
				PRINT COLUMN 01,"Product:", 
				COLUMN 10,p_rec_cur_statsale.part_code, 
				COLUMN 26,l_desc_text 
				SKIP 1 line 
			END IF 
			
		BEFORE GROUP OF p_rec_cur_statsale.prodgrp_code 
			IF modu_order_ind = "2" THEN 
				SKIP 1 line 
				NEED 8 LINES 
				SELECT desc_text INTO l_desc_text FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_cur_statsale.prodgrp_code 
				PRINT COLUMN 01,"Product group:", 
				COLUMN 16,p_rec_cur_statsale.prodgrp_code, 
				COLUMN 20,l_desc_text 
				SKIP 1 line 
			END IF 
			
		BEFORE GROUP OF p_rec_cur_statsale.maingrp_code 
			IF modu_order_ind = "3" THEN 
				SKIP 1 line 
				NEED 8 LINES 
				SELECT desc_text INTO l_desc_text FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_cur_statsale.maingrp_code 
				PRINT COLUMN 01,"Main group:", 
				COLUMN 13,p_rec_cur_statsale.maingrp_code, 
				COLUMN 17,l_desc_text 
				SKIP 1 line 
			END IF 
			
		AFTER GROUP OF p_rec_cur_statsale.cust_code 
			NEED 4 LINES 
			SELECT name_text,city_text,addr2_text 
			INTO l_name_text,l_city_text,l_addr_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_cur_statsale.cust_code
			 
			IF l_city_text IS NULL THEN 
				LET l_city_text = l_addr_text 
			END IF
			 
			IF GROUP sum(p_rec_cur_statsale.gross_amt) = 0 THEN 
				LET l_disc1_per = 0 
			ELSE 
				LET l_disc1_per = 100 * 
				(1-(group sum(p_rec_cur_statsale.net_amt)/ 
				GROUP sum(p_rec_cur_statsale.gross_amt))) 
			END IF
			 
			IF GROUP sum(p_rec_cy_statsale.gross_amt) = 0 THEN 
				LET l_disc2_per = 0 
			ELSE 
				LET l_disc2_per = 100 * 
				(1-(group sum(p_rec_cy_statsale.net_amt)/ 
				GROUP sum(p_rec_cy_statsale.gross_amt))) 
			END IF
			 
			PRINT COLUMN 06,p_rec_cur_statsale.cust_code, 
			COLUMN 15,l_name_text, 
			COLUMN 53,modu_rec_statint.year_num USING "####", 
			COLUMN 59,group sum(p_rec_cur_statsale.sales_qty) USING "------&", 
			COLUMN 67,group sum(p_rec_cur_statsale.gross_amt) USING "--,---,--&", 
			COLUMN 78,group sum(p_rec_cur_statsale.net_amt) USING "--,---,--&", 
			COLUMN 89,l_disc1_per USING "---&.&", 
			COLUMN 97,group sum(p_rec_cy_statsale.sales_qty) USING "------&", 
			COLUMN 105,group sum(p_rec_cy_statsale.gross_amt) USING "--,---,--&", 
			COLUMN 116,group sum(p_rec_cy_statsale.net_amt) USING "--,---,--&", 
			COLUMN 127,l_disc2_per USING "---&.&" 
			IF GROUP sum(p_rec_prv_statsale.gross_amt) = 0 THEN 
				LET l_disc1_per = 0 
			ELSE 
				LET l_disc1_per = 100 * 
				(1-(group sum(p_rec_prv_statsale.net_amt)/ 
				GROUP sum(p_rec_prv_statsale.gross_amt))) 
			END IF 
			IF GROUP sum(p_rec_py_statsale.gross_amt) = 0 THEN 
				LET l_disc2_per = 0 
			ELSE 
				LET l_disc2_per = 100 * 
				(1-(group sum(p_rec_py_statsale.net_amt)/ 
				GROUP sum(p_rec_py_statsale.gross_amt))) 
			END IF 
			
			PRINT COLUMN 15,l_city_text,			 
			COLUMN 53,(modu_rec_statint.year_num-1) USING "####", 
			COLUMN 59,group sum(p_rec_prv_statsale.sales_qty) USING "------&", 
			COLUMN 67,group sum(p_rec_prv_statsale.gross_amt) USING "--,---,--&", 
			COLUMN 78,group sum(p_rec_prv_statsale.net_amt) USING "--,---,--&", 
			COLUMN 89,l_disc1_per USING "---&.&", 
			COLUMN 97,group sum(p_rec_py_statsale.sales_qty) USING "------&", 
			COLUMN 105,group sum(p_rec_py_statsale.gross_amt) USING "--,---,--&", 
			COLUMN 116,group sum(p_rec_py_statsale.net_amt) USING "--,---,--&", 
			COLUMN 127,l_disc2_per USING "---&.&" 
			SKIP 1 line 
			
		ON LAST ROW 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 