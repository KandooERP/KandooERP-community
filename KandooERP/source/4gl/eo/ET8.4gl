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
GLOBALS "../eo/ET8_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_rec_statparms RECORD LIKE statparms.* 
	DEFINE modu_rec_statint RECORD LIKE statint.* 
	DEFINE modu_arr_rec_interval array[12] OF RECORD 
		int_text char(8), 
		year_num LIKE statint.year_num, 
		int_num LIKE statint.int_num, 
		cust_cnt SMALLINT, 
		sales_qty LIKE statsale.sales_qty, 
		net_amt LIKE statsale.net_amt, 
		sell_cust_cnt SMALLINT, 
		sell_sales_qty LIKE statsale.sales_qty, 
		sell_net_amt LIKE statsale.net_amt, 
		rpt_sales_qty LIKE statsale.sales_qty, 
		rpt_net_amt LIKE statsale.net_amt 
	END RECORD 
	DEFINE modu_temp_text char(500) 
	DEFINE modu_order_ind char(1) 
###########################################################################
# FUNCTION ET8_main()  
#
# ET8 - New Vs Repeat Sales Report
###########################################################################
FUNCTION ET8_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET8")

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	CREATE temp TABLE t_statsale(
		cust_code char(8), 
		sales_qty FLOAT, 
		net_amt decimal(16,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E288 with FORM "E288" 
			 CALL windecoration_e("E288")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
			MENU " New Vs Repeat sales" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET8","menu-New_Vs_Repeat-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET8_rpt_process(ET8_rpt_query())

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 					
												
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET8_rpt_process(ET8_rpt_query())
										
				ON ACTION "PRINT MANAGER" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			END MENU 
			CLOSE WINDOW E288 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET8_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E288 with FORM "E288" 
			 CALL windecoration_e("E288") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET8_rpt_query()) #save where clause in env 
			CLOSE WINDOW E288 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET8_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION ET8_main()  
###########################################################################


###########################################################################
# FUNCTION ET8_rpt_query() 
#
#
###########################################################################
FUNCTION ET8_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg("E",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON part_code, 
	prodgrp_code, 
	maingrp_code, 
	salesperson.sale_code, 
	name_text, 
	sale_type_ind, 
	salesperson.mgr_code, 
	salesperson.terri_code, 
	state_code, 
	country_code, 
	post_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET8","construct-part_code-1") -- albo kd-502 

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
# END FUNCTION ET8_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ET8_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	

	DEFINE l_rec_salesperson RECORD 
		sale_code LIKE salesperson.sale_code, 
		part_code LIKE statsale.part_code, 
		prodgrp_code LIKE statsale.prodgrp_code, 
		maingrp_code LIKE statsale.maingrp_code, 
		name_text LIKE salesperson.name_text 
	END RECORD 
	DEFINE l_order_text STRING 
	DEFINE l_where2_text STRING 
	DEFINE l_where3_text STRING 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF
	
	LET l_rpt_idx = rpt_start(getmoduleid(),"ET8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------	
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].ref2_ind
	#------------------------------------------------------------	
	
	CALL build_interval(modu_rec_statint.*) 
	CASE modu_order_ind 
		WHEN "1" 
			LET l_where2_text = "part_code IS NOT NULL AND ", 
			"prodgrp_code IS NOT null" 
			LET l_where3_text = "prodgrp_code = ? AND ", 
			"part_code = ? " 
			LET l_order_text = " ORDER BY 1,2 " 
		WHEN "2" 
			LET l_where2_text = "part_code IS NULL AND ", 
			"prodgrp_code IS NOT null" 
			LET l_where3_text = "part_code IS NULL AND ", 
			"prodgrp_code = ? " 
			LET l_order_text = " ORDER BY 1,3 " 
		WHEN "3" 
			LET l_where2_text = "part_code IS NULL AND ", 
			"prodgrp_code IS null" 
			LET l_where3_text = "part_code IS NULL AND ", 
			"prodgrp_code IS NULL " 
			LET l_order_text = " ORDER BY 1,4 " 
	END CASE
	 
	LET l_query_text = 
	"SELECT statsale.sale_code,", 
	"part_code,", 
	"prodgrp_code,", 
	"maingrp_code,", 
	"salesperson.name_text", 
	" FROM statsale,salesperson", 
	" WHERE statsale.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND salesperson.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND salesperson.sale_code = statsale.sale_code", 
	" AND ((year_num = '",modu_arr_rec_interval[1].year_num,"' AND", 
	" int_num > '",modu_arr_rec_interval[12].int_num,"') OR", 
	" (year_num = '",modu_arr_rec_interval[12].year_num,"' AND", 
	" int_num < '",modu_arr_rec_interval[1].int_num,"')) ", 
	" AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET8_rpt_list")].sel_text clipped," ",
	" AND ",l_where2_text clipped, 
	" group by 1,2,3,4,5", 
	l_order_text clipped 
	
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	LET l_query_text = "SELECT cust_code,sales_qty,net_amt FROM statsale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	"AND sale_code = ? ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND int_num = ? ", 
	"AND maingrp_code = ? ", 
	"AND ", l_where3_text clipped 
	PREPARE s_statsale FROM l_query_text 
	DECLARE c_statsale cursor FOR s_statsale 

	--MESSAGE kandoomsg2("E",1045,"") #1045 Reporting on Salesperson..
	FOREACH c_salesperson INTO l_rec_salesperson.*
		#---------------------------------------------------------
		OUTPUT TO REPORT ET8_rpt_list(l_rpt_idx,
		l_rec_salesperson.*)  
		IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 

		OUTPUT TO REPORT ET8_rpt_list(l_rec_salesperson.*) 
		IF int_flag OR quit_flag THEN 			
			IF kandoomsg("U",8503,"") = "N" THEN 		#8503 Continue Report(Y/N)		
				ERROR kandoomsg2("U",9501,"") #9501 Report Terminated
				EXIT FOREACH 
			END IF 
		END IF 
	END FOREACH 
	
	#------------------------------------------------------------
	FINISH REPORT ET8_rpt_list
	CALL rpt_finish("ET8_rpt_list")
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
# END FUNCTION ET8_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# FUNCTION ET8_enter_year() 
#
#
###########################################################################
FUNCTION ET8_enter_year() 

	LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
	LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 
	LET modu_order_ind = "3"
	 
	MESSAGE kandoomsg("E",1157,"")	#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_order_ind WITHOUT DEFAULTS 
	FROM
		year_num, 
		int_text, 
		order_ind ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET8","input-modu_rec_statint-1") -- albo kd-502 

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
					ERROR kandoomsg2("E",9223,"") 				#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = modu_rec_statparms.mth_num 
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
# END FUNCTION ET8_enter_year() 
###########################################################################


###########################################################################
# FUNCTION build_interval(p_rec_statint) 
#
#
###########################################################################
FUNCTION build_interval(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE i SMALLINT 

	#position [12] represents current interval
	LET modu_arr_rec_interval[12].int_text = p_rec_statint.int_text 
	LET modu_arr_rec_interval[12].year_num = p_rec_statint.year_num 
	LET modu_arr_rec_interval[12].int_num = p_rec_statint.int_num 
	LET modu_arr_rec_interval[12].cust_cnt = 0 
	LET modu_arr_rec_interval[12].sales_qty = 0 
	LET modu_arr_rec_interval[12].net_amt = 0 
	LET modu_arr_rec_interval[12].sell_cust_cnt = 0 
	LET modu_arr_rec_interval[12].sell_sales_qty = 0 
	LET modu_arr_rec_interval[12].sell_net_amt = 0 
	LET modu_arr_rec_interval[12].rpt_sales_qty = 0 
	LET modu_arr_rec_interval[12].rpt_net_amt = 0 
	FOR i = 11 TO 1 step -1 
		SELECT * INTO l_rec_statint.* FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = modu_rec_statparms.mth_type_code 
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
		LET modu_arr_rec_interval[i].cust_cnt = 0 
		LET modu_arr_rec_interval[i].sales_qty = 0 
		LET modu_arr_rec_interval[i].net_amt = 0 
		LET modu_arr_rec_interval[i].sell_cust_cnt = 0 
		LET modu_arr_rec_interval[i].sell_sales_qty = 0 
		LET modu_arr_rec_interval[i].sell_net_amt = 0 
		LET modu_arr_rec_interval[i].rpt_sales_qty = 0 
		LET modu_arr_rec_interval[i].rpt_net_amt = 0 
	END FOR 
END FUNCTION 
###########################################################################
# END FUNCTION build_interval(p_rec_statint) 
###########################################################################


###########################################################################
# REPORT ET8_rpt_list(p_rpt_idx,p_rec_salesperson) 
#
#
###########################################################################
REPORT ET8_rpt_list(p_rpt_idx,p_rec_salesperson) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_statsale RECORD 
		cust_code LIKE statsale.cust_code, 
		sales_qty LIKE statsale.sales_qty, 
		net_amt LIKE statsale.net_amt 
	END RECORD 
	DEFINE p_rec_salesperson RECORD 
		sale_code LIKE salesperson.sale_code, 
		part_code LIKE statsale.part_code, 
		prodgrp_code LIKE statsale.prodgrp_code, 
		maingrp_code LIKE statsale.maingrp_code, 
		name_text LIKE salesperson.name_text 
	END RECORD 
	DEFINE l_inv_item char(25) 
	DEFINE l_desc_text LIKE product.desc_text 
	DEFINE l_row_cnt SMALLINT
	DEFINE l_row_rpt SMALLINT	 
	DEFINE l_row_qty LIKE statsale.sales_qty 
	DEFINE l_row_sell_qty LIKE statsale.sales_qty 
	DEFINE l_row_rpt_qty LIKE statsale.sales_qty 
	
	DEFINE l_row_net LIKE statsale.net_amt 
	DEFINE l_row_sell_net LIKE statsale.net_amt 
	DEFINE l_row_rpt_net LIKE statsale.net_amt 	
	DEFINE l_row_per FLOAT 
	DEFINE x,i,j SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_salesperson.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			PRINT COLUMN 01,"Salesperson:", 
			COLUMN 14, p_rec_salesperson.sale_code, 
			COLUMN 23, p_rec_salesperson.name_text 
			
			CASE modu_order_ind 
				WHEN "1" 
					LET l_inv_item = "Product: ",p_rec_salesperson.part_code 
					SELECT desc_text INTO l_desc_text FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_salesperson.part_code 
				WHEN "2" 
					LET l_inv_item = "Prod Group: ",p_rec_salesperson.prodgrp_code 
					SELECT desc_text INTO l_desc_text FROM prodgrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodgrp_code = p_rec_salesperson.prodgrp_code 
				WHEN "3" 
					LET l_inv_item = "Main Group: ",p_rec_salesperson.maingrp_code 
					SELECT desc_text INTO l_desc_text FROM maingrp 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND maingrp_code = p_rec_salesperson.maingrp_code 
			END CASE 
			PRINT COLUMN 01,l_inv_item clipped," ",l_desc_text 
			SKIP 1 line 
			PRINT COLUMN 20," "; 
			FOR i = 1 TO 12 
				PRINT modu_arr_rec_interval[i].int_text; 
			END FOR 
			PRINT COLUMN 119, "TOTAL", 
			COLUMN 126, "REPEAT" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]   
			
		ON EVERY ROW 
			SKIP TO top OF PAGE 
			FOR i = 1 TO 12 # i = each ROW (month) 
				DELETE FROM t_statsale WHERE 1=1 
				CASE modu_order_ind 
					WHEN "1" 
						OPEN c_statsale USING p_rec_salesperson.sale_code, 
						modu_arr_rec_interval[i].year_num, 
						modu_rec_statparms.mth_type_code, 
						modu_arr_rec_interval[i].int_num, 
						p_rec_salesperson.maingrp_code, 
						p_rec_salesperson.prodgrp_code, 
						p_rec_salesperson.part_code 
					WHEN "2" 
						OPEN c_statsale USING p_rec_salesperson.sale_code, 
						modu_arr_rec_interval[i].year_num, 
						modu_rec_statparms.mth_type_code, 
						modu_arr_rec_interval[i].int_num, 
						p_rec_salesperson.maingrp_code, 
						p_rec_salesperson.prodgrp_code 
					WHEN "3" 
						OPEN c_statsale USING p_rec_salesperson.sale_code, 
						modu_arr_rec_interval[i].year_num, 
						modu_rec_statparms.mth_type_code, 
						modu_arr_rec_interval[i].int_num, 
						p_rec_salesperson.maingrp_code 
				END CASE 
				
				FOREACH c_statsale INTO p_rec_statsale.* 
					INSERT INTO t_statsale VALUES (p_rec_statsale.cust_code, 
					p_rec_statsale.sales_qty, 
					p_rec_statsale.net_amt) 
				END FOREACH 
				
				SELECT count(*), sum(sales_qty),sum(net_amt) 
				INTO modu_arr_rec_interval[i].cust_cnt, 
				modu_arr_rec_interval[i].sales_qty, 
				modu_arr_rec_interval[i].net_amt 
				FROM t_statsale 
				IF modu_arr_rec_interval[i].sales_qty IS NULL THEN 
					LET modu_arr_rec_interval[i].sales_qty = 0 
				END IF 
				
				IF modu_arr_rec_interval[i].net_amt IS NULL THEN 
					LET modu_arr_rec_interval[i].net_amt = 0 
				END IF 
				IF i > 1 THEN 
					#NULL out the left interval TO create a diagonal effect
					LET modu_arr_rec_interval[i-1].cust_cnt = NULL 
					LET modu_arr_rec_interval[i-1].sales_qty = NULL 
					LET modu_arr_rec_interval[i-1].net_amt = NULL 
				ELSE 
					#init total lines AT first row interval... no other choice
					LET l_row_sell_qty = 0 
					LET l_row_sell_net = 0 
					LET l_row_rpt_qty = 0 
					LET l_row_rpt_net = 0 
				END IF 
				#initialise row totals     (RHS of page)
				LET l_row_cnt = modu_arr_rec_interval[i].cust_cnt 
				LET l_row_qty = modu_arr_rec_interval[i].sales_qty 
				LET l_row_net = modu_arr_rec_interval[i].net_amt 
				#initialise COLUMN totals  (BOT of page)
				LET modu_arr_rec_interval[i].sell_cust_cnt = modu_arr_rec_interval[i].cust_cnt 
				LET modu_arr_rec_interval[i].sell_sales_qty = modu_arr_rec_interval[i].sales_qty 
				LET modu_arr_rec_interval[i].sell_net_amt = modu_arr_rec_interval[i].net_amt 
				#accummulate row totals FOR each 'total COLUMN'
				LET l_row_sell_qty = l_row_sell_qty + modu_arr_rec_interval[i].sales_qty 
				LET l_row_sell_net = l_row_sell_net + modu_arr_rec_interval[i].net_amt 
				
				IF i = 12 THEN 
					LET l_row_rpt = 0 #there cant be repeat sales IF mth=12 
				ELSE 
					LET x = i + 1 
					FOR j = x TO 12 # j = each col OF repeat sales 

						CASE modu_order_ind 
							WHEN "1" 
								SELECT count(*), sum(sales_qty),sum(net_amt) 
								INTO modu_arr_rec_interval[j].cust_cnt, 
								modu_arr_rec_interval[j].sales_qty, 
								modu_arr_rec_interval[j].net_amt 
								FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code = p_rec_salesperson.prodgrp_code 
								AND part_code = p_rec_salesperson.part_code 
								AND year_num = modu_arr_rec_interval[j].year_num 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND int_num = modu_arr_rec_interval[j].int_num 
								AND sale_code = p_rec_salesperson.sale_code 
							WHEN "2" 
								SELECT count(*), sum(sales_qty),sum(net_amt) 
								INTO modu_arr_rec_interval[j].cust_cnt, 
								modu_arr_rec_interval[j].sales_qty, 
								modu_arr_rec_interval[j].net_amt 
								FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code = p_rec_salesperson.prodgrp_code 
								AND part_code IS NULL 
								AND year_num = modu_arr_rec_interval[j].year_num 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND int_num = modu_arr_rec_interval[j].int_num 
								AND sale_code = p_rec_salesperson.sale_code 
							WHEN "3" 
								SELECT count(*), sum(sales_qty),sum(net_amt) 
								INTO modu_arr_rec_interval[j].cust_cnt, 
								modu_arr_rec_interval[j].sales_qty, 
								modu_arr_rec_interval[j].net_amt 
								FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code IS NULL 
								AND part_code IS NULL 
								AND year_num = modu_arr_rec_interval[j].year_num 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND int_num = modu_arr_rec_interval[j].int_num 
								AND sale_code = p_rec_salesperson.sale_code 
						END CASE 
						IF modu_arr_rec_interval[j].sales_qty IS NULL THEN 
							LET modu_arr_rec_interval[j].sales_qty = 0 
						END IF 
						IF modu_arr_rec_interval[j].net_amt IS NULL THEN 
							LET modu_arr_rec_interval[j].net_amt = 0 
						END IF 
						#store 'repeat sales' TO PRINT across the page
						LET modu_arr_rec_interval[j].rpt_sales_qty = 
						modu_arr_rec_interval[j].rpt_sales_qty + modu_arr_rec_interval[j].sales_qty 
						LET modu_arr_rec_interval[j].rpt_net_amt = 
						modu_arr_rec_interval[j].rpt_net_amt + modu_arr_rec_interval[j].net_amt 
						#accumulate row totals
						LET l_row_qty = l_row_qty + modu_arr_rec_interval[j].sales_qty 
						LET l_row_net = l_row_net + modu_arr_rec_interval[j].net_amt 
						#accumulate row totals FOR 'repeat total lines'
						LET l_row_rpt_qty = l_row_rpt_qty + modu_arr_rec_interval[j].sales_qty 
						LET l_row_rpt_net = l_row_rpt_net + modu_arr_rec_interval[j].net_amt 
					END FOR 
					
					CASE modu_order_ind 
						WHEN "1" 
							IF modu_arr_rec_interval[x].int_num > modu_arr_rec_interval[12].int_num THEN 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code = p_rec_salesperson.prodgrp_code 
								AND part_code = p_rec_salesperson.part_code 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND ((year_num = modu_arr_rec_interval[1].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 12) 
								and(year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between 1 AND modu_arr_rec_interval[12].int_num)) 
								AND sale_code = p_rec_salesperson.sale_code 
							ELSE 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code IS NULL 
								AND part_code IS NULL 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND (year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 
								modu_arr_rec_interval[12].int_num) 
								AND sale_code = p_rec_salesperson.sale_code 
							END IF 
						WHEN "2" 
							IF modu_arr_rec_interval[x].int_num > modu_arr_rec_interval[12].int_num THEN 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code = p_rec_salesperson.prodgrp_code 
								AND part_code IS NULL 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND ((year_num = modu_arr_rec_interval[1].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 12) 
								and(year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between 1 AND modu_arr_rec_interval[12].int_num)) 
								AND sale_code = p_rec_salesperson.sale_code 
							ELSE 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code IS NULL 
								AND part_code IS NULL 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND (year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 
								modu_arr_rec_interval[12].int_num) 
								AND sale_code = p_rec_salesperson.sale_code 
							END IF 
						WHEN "3" 
							IF modu_arr_rec_interval[x].int_num > modu_arr_rec_interval[12].int_num THEN 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code IS NULL 
								AND part_code IS NULL 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND ((year_num = modu_arr_rec_interval[1].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 12) 
								and(year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between 1 AND modu_arr_rec_interval[12].int_num)) 
								AND sale_code = p_rec_salesperson.sale_code 
							ELSE 
								SELECT count(unique cust_code) INTO l_row_rpt FROM statsale 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND cust_code in (select cust_code FROM t_statsale) 
								AND maingrp_code = p_rec_salesperson.maingrp_code 
								AND prodgrp_code IS NULL 
								AND part_code IS NULL 
								AND type_code = modu_rec_statparms.mth_type_code 
								AND (year_num = modu_arr_rec_interval[12].year_num AND 
								int_num between modu_arr_rec_interval[x].int_num AND 
								modu_arr_rec_interval[12].int_num) 
								AND sale_code = p_rec_salesperson.sale_code 
							END IF 
					END CASE 
				END IF 
				
				PRINT COLUMN 01,modu_arr_rec_interval[i].int_text, 
				COLUMN 09,"Customer "; 
				FOR j = 1 TO 12 
					PRINT modu_arr_rec_interval[j].cust_cnt USING "-------&"; 
				END FOR 
				PRINT l_row_cnt USING "---------&", 
				l_row_rpt USING "-------&" 
				IF l_row_cnt = 0 THEN 
					LET l_row_per = 0 
				ELSE 
					LET l_row_per = 100 * (l_row_rpt/l_row_cnt) 
				END IF 
				PRINT COLUMN 09,"Quantity "; 
				FOR j = 1 TO 12 
					PRINT modu_arr_rec_interval[j].sales_qty USING "-------&"; 
				END FOR 
				PRINT l_row_qty USING "---------&"; 
				PRINT l_row_per USING "-----&.&"; 
				PRINT "%" 
				PRINT COLUMN 09,"Net Amt "; 
				FOR j = 1 TO 12 
					PRINT modu_arr_rec_interval[j].net_amt USING "-------&"; 
				END FOR 
				PRINT l_row_net USING "---------&" 
			END FOR			
			SKIP 2 line
			 
			# PRINT TOTALS
			PRINT COLUMN 01,"Selling", 
			COLUMN 09,"Customer "; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].sell_cust_cnt USING "-------&"; 
			END FOR 
			PRINT " " 
			PRINT COLUMN 09,"Quantity "; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].sell_sales_qty USING "-------&"; 
			END FOR 
			PRINT l_row_sell_qty USING "---------&" 
			PRINT COLUMN 09,"Net Amt "; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].sell_net_amt USING "-------&"; 
			END FOR 
			PRINT l_row_sell_net USING "---------&" 
			SKIP 1 LINES 
			# PRINT REPEAT TOTALS
			PRINT COLUMN 01,"Repeat", 
			COLUMN 09,"Quantity "; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].rpt_sales_qty USING "-------&"; 
			END FOR 
			PRINT l_row_rpt_qty USING "---------&" 
			PRINT COLUMN 09,"Net Amt "; 
			FOR j = 1 TO 12 
				PRINT modu_arr_rec_interval[j].rpt_net_amt USING "-------&"; 
			END FOR 
			PRINT l_row_rpt_net USING "---------&" 
			
		ON LAST ROW 
			SKIP 1 LINES 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT 
###########################################################################
# END REPORT ET8_rpt_list(p_rpt_idx,p_rec_salesperson) 
###########################################################################