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
GLOBALS "../eo/ET4_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_rec_criteria RECORD 
	part_ind char(1), 
	pgrp_ind char(1), 
	mgrp_ind char(1) 
END RECORD 
###########################################################################
# FUNCTION ET4_main()
#
# ET4 Customer / Inventory Turnover Report
###########################################################################
FUNCTION ET4_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("ET4")  

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = RPT_OP_MENU 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN "1" #UI/MENU Mode 	
			OPEN WINDOW E275 with FORM "E275" 
			 CALL windecoration_e("E275")  
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 

			
			MENU " Inventory turnover" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET4","menu-Inventory-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET4_rpt_process(ET4_rpt_query())
					
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 										
					
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET4_rpt_process(ET4_rpt_query())
		
				ON ACTION "PRINT MANAGER" 			#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		 
			END MENU 
			CLOSE WINDOW E275 


		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET4_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E275 with FORM "E275" 
			 CALL windecoration_e("E275") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET4_rpt_query()) #save where clause in env 
			CLOSE WINDOW E275 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET4_rpt_process(get_url_sel_text())
	END CASE 	
	
END FUNCTION 
###########################################################################
# END FUNCTION ET4_main()
###########################################################################


###########################################################################
# FUNCTION ET4_rpt_query() 
#
# 
###########################################################################
FUNCTION ET4_rpt_query() 
	DEFINE l_where_text STRING

	IF (NOT ET4_enter_year()) OR (int_flag = TRUE) THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF
	
	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	sale_type_ind, 
	terri_code, 
	mgr_code, 
	city_text, 
	state_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET4","construct-sale_code-1") -- albo kd-502 

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
# END FUNCTION ET4_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ET4_enter_year()  
#
#
###########################################################################
FUNCTION ET4_enter_year() 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_temp_text STRING
--	DEFINE query_text STRING 
--	DEFINE order_text char(10) 

	LET modu_rec_criteria.part_ind = xlate_to("Y") 
	LET modu_rec_criteria.pgrp_ind = xlate_to("Y") 
	LET modu_rec_criteria.mgrp_ind = xlate_to("Y") 
	
	LET l_rec_statint.year_num = modu_rec_statparms.year_num 
	LET l_rec_statint.int_num = modu_rec_statparms.mth_num 
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		l_rec_statint.year_num, 
		l_rec_statint.int_text, 
		modu_rec_criteria.part_ind, 
		modu_rec_criteria.pgrp_ind, 
		modu_rec_criteria.mgrp_ind 
	WITHOUT DEFAULTS
	FROM
		year_num, 
		int_text, 
		part_ind, 
		pgrp_ind, 
		mgrp_ind 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET4","input-pr_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text)  
				LET l_temp_text = "year_num = '",l_rec_statint.year_num,"' ", 
				"AND type_code = '",modu_rec_statparms.mth_type_code,"'" 
				LET l_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,l_temp_text) 
				IF l_temp_text IS NOT NULL THEN 
					LET l_rec_statint.int_num = l_temp_text 
					NEXT FIELD int_text 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET l_rec_statint.year_num = l_rec_statint.year_num - 1 
			NEXT FIELD year_num 
			
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET l_rec_statint.year_num = l_rec_statint.year_num + 1 
			NEXT FIELD year_num
			 
		BEFORE FIELD year_num 
			SELECT * INTO l_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = l_rec_statint.year_num 
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = l_rec_statint.int_num 
			DISPLAY BY NAME l_rec_statint.int_text, 
			l_rec_statint.start_date, 
			l_rec_statint.end_date 

		AFTER FIELD year_num 
			IF l_rec_statint.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 			#9210 Year number must be entered
				LET l_rec_statint.year_num = modu_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 
			
		BEFORE FIELD int_text 
			SELECT int_text INTO l_rec_statint.int_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = l_rec_statint.year_num 
			AND type_code = modu_rec_statparms.mth_type_code 
			AND int_num = l_rec_statint.int_num 
			
		AFTER FIELD int_text 
			IF l_rec_statint.int_text IS NULL THEN 
				ERROR kandoomsg2("E",9222,"") 			#9222 Interval must be entered"
				NEXT FIELD int_text 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = modu_rec_statparms.mth_type_code 
				AND int_text = l_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO l_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") #9223 Interval does NOT exist - Try Window"
					LET l_rec_statint.int_num = modu_rec_statparms.mth_num 
					NEXT FIELD int_text 
				END IF 
			END IF
			 
			DISPLAY l_rec_statint.start_date TO start_date 
			DISPLAY l_rec_statint.end_date TO end_date
 
	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET modu_rec_statparms.year_num = year(today) 
		RETURN FALSE 
	ELSE 
		LET modu_rec_statparms.year_num = l_rec_statint.year_num 
		LET modu_rec_statparms.mth_num = l_rec_statint.int_num		
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET4_enter_year()  
###########################################################################


###########################################################################
# FUNCTION ET4_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET4_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statsale RECORD LIKE statsale.* 
	DEFINE l_temp_text STRING
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET4_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET4_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET4_rpt_list")].sel_text clipped," ",		 
	"ORDER BY 1" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	######
	## Declare various product cursors reqd by REPORT
	LET l_query_text = "SELECT sum(sales_qty),", 
	"sum(net_amt),", 
	"sum(gross_amt) ", 
	"FROM statsale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND sale_code = ? ", 
	"AND cust_code = ? ", 
	"AND year_num = ? ", 
	"AND type_code = '",modu_rec_statparms.mth_type_code,"' ", 
	"AND int_num between ? AND ? " 
	PREPARE s_custsale FROM l_query_text 
	DECLARE c_custsale cursor FOR s_custsale 
	
	IF modu_rec_criteria.part_ind = "Y" THEN 
		LET l_temp_text = l_query_text clipped," AND maingrp_code = ? ", 
		" AND prodgrp_code = ? ", 
		" AND part_code = ? " 

		PREPARE s_prodsale FROM l_temp_text 
		DECLARE c_prodsale cursor FOR s_prodsale 
	END IF 
	
	IF modu_rec_criteria.pgrp_ind = "Y" THEN 
		LET l_temp_text = l_query_text clipped," AND maingrp_code = ? ", 
		" AND prodgrp_code = ? ", 
		" AND part_code IS null" 
		PREPARE s_pgrpsale FROM l_temp_text 
		DECLARE c_pgrpsale cursor FOR s_pgrpsale 
	END IF 
	
	IF modu_rec_criteria.mgrp_ind = "Y" THEN 
		LET l_temp_text = l_query_text clipped," AND maingrp_code = ? ", 
		" AND prodgrp_code IS NULL ", 
		" AND part_code IS null" 
		PREPARE s_mgrpsale FROM l_temp_text 
		DECLARE c_mgrpsale cursor FOR s_mgrpsale 
	END IF 


	FOREACH c_salesperson INTO l_rec_salesperson.* 

		DECLARE c_statsale cursor FOR 
		SELECT * FROM statsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = modu_rec_statparms.year_num 
		AND type_code = modu_rec_statparms.mth_type_code 
		AND int_num = modu_rec_statparms.mth_num 
		AND sale_code = l_rec_salesperson.sale_code 
		AND part_code IS NOT NULL 
		
		FOREACH c_statsale INTO l_rec_statsale.* 
			#---------------------------------------------------------
			OUTPUT TO REPORT ET4_rpt_list(l_rpt_idx,
			l_rec_statsale.*)  
			IF NOT rpt_int_flag_handler2("Salesperson:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------				

		END FOREACH 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ET4_rpt_list
	CALL rpt_finish("ET4_rpt_list")
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
# END FUNCTION ET4_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ET4_rpt_list(p_rpt_idx,p_rec_statsale) 
#
#
###########################################################################
REPORT ET4_rpt_list(p_rpt_idx,p_rec_statsale)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_statsale RECORD LIKE statsale.* 
	DEFINE l_arr_statsale array[2,2] OF RECORD 
		sales_qty LIKE statsale.sales_qty, 
		net_amt LIKE statsale.net_amt, 
		gross_amt LIKE statsale.gross_amt, 
		disc_per FLOAT 
	END RECORD 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_int_num LIKE statint.int_num 
	DEFINE l_desc_text char(30) 
	DEFINE l_year_num SMALLINT 
	DEFINE x,i,j SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_statsale.cmpy_code, 
	p_rec_statsale.sale_code, 
	p_rec_statsale.cust_code, 
	p_rec_statsale.maingrp_code, 
	p_rec_statsale.prodgrp_code, 
	p_rec_statsale.part_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			
			SELECT int_text INTO l_desc_text 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = p_rec_statsale.year_num 
			AND type_code = p_rec_statsale.type_code 
			AND int_num = p_rec_statsale.int_num 
			
			PRINT COLUMN 01,"Current Month: ",l_desc_text[1,8], 
			COLUMN 25,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[25,132] 
			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			
			SELECT name_text INTO l_desc_text 
			FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = p_rec_statsale.sale_code 
			PRINT COLUMN 01,"Salesperson:", 			
			COLUMN 14, p_rec_statsale.sale_code, 
			COLUMN 24, l_desc_text, 
			COLUMN 54, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text[54,132] 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		BEFORE GROUP OF p_rec_statsale.cust_code 
			NEED 30 LINES 
			SKIP 1 line 
			SELECT * INTO l_rec_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_statsale.cust_code 
			FOR i = 1 TO 2 
				CASE i 
					WHEN "1" 
						PRINT COLUMN 01,"Customer:", 
						COLUMN 10,l_rec_customer.cust_code, 
						COLUMN 20,l_rec_customer.name_text, 
						COLUMN 52,(modu_rec_statparms.year_num-1) USING "####"; 
					WHEN "2" 
						IF l_rec_customer.city_text IS NULL THEN 
							LET l_rec_customer.city_text = l_rec_customer.addr2_text 
						END IF 
						PRINT COLUMN 20,l_rec_customer.city_text, 
						COLUMN 52,modu_rec_statparms.year_num USING "####"; 
				END CASE 
				FOR j = 1 TO 2 
					IF j = 1 THEN 
						LET l_int_num = p_rec_statsale.int_num 
					ELSE 
						LET l_int_num = 1 ## ytd totals 
					END IF 
					LET l_year_num = modu_rec_statparms.year_num - 2 + i 
					OPEN c_custsale USING p_rec_statsale.sale_code, 
					p_rec_statsale.cust_code, 
					l_year_num, 
					l_int_num, 
					p_rec_statsale.int_num 
					FETCH c_custsale INTO l_arr_statsale[i,j].* 
					IF l_arr_statsale[i,j].sales_qty IS NULL THEN 
						LET l_arr_statsale[i,j].sales_qty = 0 
					END IF 
					IF l_arr_statsale[i,j].net_amt IS NULL THEN 
						LET l_arr_statsale[i,j].net_amt = 0 
					END IF 
					IF l_arr_statsale[i,j].gross_amt IS NULL THEN 
						LET l_arr_statsale[i,j].gross_amt = 0 
					END IF 
					IF l_arr_statsale[i,j].gross_amt = 0 THEN 
						LET l_arr_statsale[i,j].disc_per = 0 
					ELSE 
						LET l_arr_statsale[i,j].disc_per = 100 * 
						(1-(l_arr_statsale[i,j].net_amt/l_arr_statsale[i,j].gross_amt)) 
					END IF 
					LET x = (j*41)+15 
					PRINT COLUMN x, l_arr_statsale[i,j].sales_qty USING "-------&", 
					l_arr_statsale[i,j].gross_amt USING " --------&", 
					l_arr_statsale[i,j].net_amt USING " --------&", 
					l_arr_statsale[i,j].disc_per USING " ----&.&"; 
				END FOR 
				PRINT COLUMN 132," " 
			END FOR 

		AFTER GROUP OF p_rec_statsale.part_code 
			IF modu_rec_criteria.part_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_statsale.part_code 
				FOR i = 1 TO 2 
					CASE i 
						WHEN "1" 
							PRINT COLUMN 10,"Product: ", 
							COLUMN 20, p_rec_statsale.part_code, 
							COLUMN 52,(modu_rec_statparms.year_num-1) USING "####"; 
						WHEN "2" 
							PRINT COLUMN 20,l_desc_text, 
							COLUMN 52,modu_rec_statparms.year_num USING "####"; 
					END CASE 
					FOR j = 1 TO 2 
						IF j = 1 THEN 
							LET l_int_num = p_rec_statsale.int_num 
						ELSE 
							LET l_int_num = 1 ## ytd totals 
						END IF 
						LET l_year_num = modu_rec_statparms.year_num - 2 + i 
						OPEN c_prodsale USING p_rec_statsale.sale_code, 
						p_rec_statsale.cust_code, 
						l_year_num, 
						l_int_num, 
						p_rec_statsale.int_num, 
						p_rec_statsale.maingrp_code, 
						p_rec_statsale.prodgrp_code, 
						p_rec_statsale.part_code 
						FETCH c_prodsale INTO l_arr_statsale[i,j].* 
						IF l_arr_statsale[i,j].sales_qty IS NULL THEN 
							LET l_arr_statsale[i,j].sales_qty = 0 
						END IF 
						IF l_arr_statsale[i,j].net_amt IS NULL THEN 
							LET l_arr_statsale[i,j].net_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt IS NULL THEN 
							LET l_arr_statsale[i,j].gross_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt = 0 THEN 
							LET l_arr_statsale[i,j].disc_per = 0 
						ELSE 
							LET l_arr_statsale[i,j].disc_per = 100 * 
							(1-(l_arr_statsale[i,j].net_amt/l_arr_statsale[i,j].gross_amt)) 
						END IF 
						LET x = (j*41)+15 
						PRINT COLUMN x, l_arr_statsale[i,j].sales_qty USING "-------&", 
						l_arr_statsale[i,j].gross_amt USING " --------&", 
						l_arr_statsale[i,j].net_amt USING " --------&", 
						l_arr_statsale[i,j].disc_per USING " ----&.&"; 
					END FOR 
					PRINT COLUMN 132," " 
				END FOR 
			END IF 
			
		AFTER GROUP OF p_rec_statsale.prodgrp_code 
			IF modu_rec_criteria.pgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_statsale.prodgrp_code 
				FOR i = 1 TO 2 
					CASE i 
						WHEN "1" 
							PRINT COLUMN 06,"Product Group: ", 
							COLUMN 20, p_rec_statsale.prodgrp_code, 
							COLUMN 52,(modu_rec_statparms.year_num-1) USING "####"; 
						WHEN "2" 
							PRINT COLUMN 20,l_desc_text, 
							COLUMN 52,modu_rec_statparms.year_num USING "####"; 
					END CASE 
					FOR j = 1 TO 2 
						IF j = 1 THEN 
							LET l_int_num = p_rec_statsale.int_num 
						ELSE 
							LET l_int_num = 1 ## ytd totals 
						END IF 
						LET l_year_num = modu_rec_statparms.year_num - 2 + i 
						OPEN c_pgrpsale USING p_rec_statsale.sale_code, 
						p_rec_statsale.cust_code, 
						l_year_num, 
						l_int_num, 
						p_rec_statsale.int_num, 
						p_rec_statsale.maingrp_code, 
						p_rec_statsale.prodgrp_code 
						FETCH c_pgrpsale INTO l_arr_statsale[i,j].* 
						IF l_arr_statsale[i,j].sales_qty IS NULL THEN 
							LET l_arr_statsale[i,j].sales_qty = 0 
						END IF 
						IF l_arr_statsale[i,j].net_amt IS NULL THEN 
							LET l_arr_statsale[i,j].net_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt IS NULL THEN 
							LET l_arr_statsale[i,j].gross_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt = 0 THEN 
							LET l_arr_statsale[i,j].disc_per = 0 
						ELSE 
							LET l_arr_statsale[i,j].disc_per = 100 * 
							(1-(l_arr_statsale[i,j].net_amt/l_arr_statsale[i,j].gross_amt)) 
						END IF 
						LET x = (j*41)+15 
						PRINT COLUMN x, l_arr_statsale[i,j].sales_qty USING "-------&", 
						l_arr_statsale[i,j].gross_amt USING " --------&", 
						l_arr_statsale[i,j].net_amt USING " --------&", 
						l_arr_statsale[i,j].disc_per USING " ----&.&"; 
					END FOR 
					PRINT COLUMN 132," " 
				END FOR 
			END IF 
			
		AFTER GROUP OF p_rec_statsale.maingrp_code 
			IF modu_rec_criteria.mgrp_ind = "Y" THEN 
				SELECT desc_text INTO l_desc_text 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_statsale.maingrp_code 
				FOR i = 1 TO 2 
					CASE i 
						WHEN "1" 
							PRINT COLUMN 04,"Main Group: ", 
							COLUMN 20, p_rec_statsale.maingrp_code, 
							COLUMN 52,(modu_rec_statparms.year_num-1) USING "####"; 
							
						WHEN "2" 
							PRINT COLUMN 20,l_desc_text, 
							COLUMN 52,modu_rec_statparms.year_num USING "####"; 
					END CASE 
					
					FOR j = 1 TO 2 
						IF j = 1 THEN 
							LET l_int_num = p_rec_statsale.int_num 
						ELSE 
							LET l_int_num = 1 ## ytd totals 
						END IF 
						LET l_year_num = modu_rec_statparms.year_num - 2 + i 
						OPEN c_mgrpsale USING p_rec_statsale.sale_code, 
						p_rec_statsale.cust_code, 
						l_year_num, 
						l_int_num, 
						p_rec_statsale.int_num, 
						p_rec_statsale.maingrp_code 
						FETCH c_mgrpsale INTO l_arr_statsale[i,j].* 
						IF l_arr_statsale[i,j].sales_qty IS NULL THEN 
							LET l_arr_statsale[i,j].sales_qty = 0 
						END IF 
						IF l_arr_statsale[i,j].net_amt IS NULL THEN 
							LET l_arr_statsale[i,j].net_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt IS NULL THEN 
							LET l_arr_statsale[i,j].gross_amt = 0 
						END IF 
						IF l_arr_statsale[i,j].gross_amt = 0 THEN 
							LET l_arr_statsale[i,j].disc_per = 0 
						ELSE 
							LET l_arr_statsale[i,j].disc_per = 100 * 
							(1-(l_arr_statsale[i,j].net_amt/l_arr_statsale[i,j].gross_amt)) 
						END IF 
						LET x = (j*41)+15 
						PRINT COLUMN x, l_arr_statsale[i,j].sales_qty USING "-------&", 
						l_arr_statsale[i,j].gross_amt USING " --------&", 
						l_arr_statsale[i,j].net_amt USING " --------&", 
						l_arr_statsale[i,j].disc_per USING " ----&.&"; 
					END FOR 
					PRINT COLUMN 132," " 
				END FOR 
			END IF 
			
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
# END REPORT ET4_rpt_list(p_rpt_idx,p_rec_statsale) 
###########################################################################