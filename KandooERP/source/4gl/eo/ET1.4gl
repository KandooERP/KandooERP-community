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
GLOBALS "../eo/ET1_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_print_targ_flag char(1) 
###########################################################################
# FUNCTION ET1_main()
#
# ET1 Sales Person Weekly Activity
###########################################################################
FUNCTION ET1_main() 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET1") 

	CREATE temp TABLE t_salescomm( 
		sale_code char(8), 
		cust_code char(8), 
		inv_num INTEGER, 
		inv_date DATE, 
		total_amt DECIMAL (16,2), 
		currency_code char(3), 
		paid_amt decimal(16,2), 
		share_per decimal(4,1), 
		comm_amt decimal(16,2) ) 


	#Statistic Parameters Configuration -> U63 - Statistic Parameters Maintenance
	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 		
			OPEN WINDOW E292 with FORM "E292" 
			 CALL windecoration_e("E292") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
			
			MENU " Salesperson Weekly turnover" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET1","menu-Salesperson_Weekly-1") -- albo kd-502
						CALL rpt_rmsreps_reset(NULL)
						CALL ET1_rpt_process(ET1_rpt_query())
								 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null)
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										 
					ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
						CALL rpt_rmsreps_reset(NULL)
						CALL ET1_rpt_process(ET1_rpt_query())
		
				ON ACTION "PRINT MANAGER" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
			
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
			
			END MENU 
			CLOSE WINDOW E292 	

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E292 with FORM "E292" 
			 CALL windecoration_e("E292") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET1_rpt_query()) #save where clause in env 
			CLOSE WINDOW E292 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET1_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 
###########################################################################
# END FUNCTION ET1_main()
###########################################################################


###########################################################################
# FUNCTION ET1_rpt_query() 
#
# 
###########################################################################
FUNCTION ET1_rpt_query() 
	DEFINE l_where_text STRING

	IF (NOT ET1_enter_interval()) OR (int_flag = TRUE) THEN
		LET int_flag = FALSE
		RETURN NULL
	END IF
	
	MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON sale_code, 
	name_text, 
	mgr_code, 
	terri_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET1","construct-sale_code-1") -- albo kd-502 

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
# END FUNCTION ET1_rpt_query() 
###########################################################################


###########################################################################
# FUNCTION ET1_enter_interval() 
#
# 
###########################################################################
FUNCTION ET1_enter_interval() 
	DEFINE l_temp_text STRING 

	LET modu_print_targ_flag = xlate_to("Y") 
	LET modu_rec_statint.year_num = modu_rec_statparms.year_num 
	LET modu_rec_statint.int_num = modu_rec_statparms.week_num 
	LET modu_print_targ_flag = "N"
	
	MESSAGE kandoomsg2("E",1157,"")	#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		modu_rec_statint.year_num, 
		modu_rec_statint.int_text, 
		modu_print_targ_flag 
	WITHOUT DEFAULTS
	FROM
		year_num, 
		int_text, 
		print_targ_flag 
	ATTRIBUTE(UNBUFFERED)
 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET1","input-modu_rec_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		ON ACTION "LOOKUP" infield(int_text)  
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
				ERROR kandoomsg2("E",9222,"") 			#9222 Interval must be entered"
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
					ERROR kandoomsg2("E",9223,"") 				#9223 Interval does NOT exist - Try Window"
					LET modu_rec_statint.int_num = modu_rec_statparms.week_num 
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
# END FUNCTION ET1_enter_interval() 
###########################################################################


###########################################################################
# FUNCTION ET1_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET1_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_salesmgr_name_text LIKE salesmgr.name_text 
	DEFINE l_territory_desc_text LIKE territory.desc_text 

	MESSAGE kandoomsg2("E",1002,"")	#1002 Searching database - please wait

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].ref2_ind
	#------------------------------------------------------------	

	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET1_rpt_list")].sel_text clipped," ",
	"ORDER BY 1,2" 
	
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson
	 
	LET l_query_text = "SELECT * FROM statsper ", 
	"WHERE cmpy_code = ? ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND int_num = ? ", 
	"AND mgr_code = ? ", 
	"AND sale_code = ? ", 
	"ORDER BY 1,2" 
	PREPARE s_statsper FROM l_query_text 
	DECLARE c_statsper cursor FOR s_statsper 
	
	LET l_query_text ="SELECT * FROM offersale ", 
	"WHERE cmpy_code = ? ", 
	"AND end_date >= ? ", 
	"AND start_date <= ? ", 
	"ORDER BY 1,2" 
	PREPARE s_offersale FROM l_query_text 
	DECLARE c_offersale cursor FOR s_offersale 
	
	LET l_query_text = "SELECT sum(gross_amt),", 
	"sum(net_amt),", 
	"sum(sales_qty),", 
	"count(*) ", 
	"FROM statoffer ", 
	"WHERE cmpy_code = ? ", 
	"AND sale_code = ? ", 
	"AND offer_code = ? ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND int_num = ? ", 
	"group by cmpy_code,", 
	"offer_code,", 
	"sale_code,", 
	"year_num,", 
	"type_code,", 
	"int_num" 
	PREPARE s_statoffer FROM l_query_text 
	DECLARE c_statoffer cursor FOR s_statoffer 
	
	LET l_query_text = "SELECT * FROM statint", 
	" WHERE cmpy_code = ?", 
	" AND year_num = ?", 
	" AND type_code = ?", 
	" AND (( ? >= start_date AND ? <= end_date )", 
	" OR ( ? >= start_date AND ? <= end_date ))", 
	" ORDER BY int_num " 
	PREPARE s2_statint FROM l_query_text 
	DECLARE c2_statint cursor FOR s2_statint 
	
	--MESSAGE kandoomsg2("E",1045,"") 	#1045 Reporting on Salesperson
	FOREACH c_salesperson INTO l_rec_salesperson.* 

		SELECT name_text INTO l_salesmgr_name_text 
		FROM salesmgr 
		WHERE cmpy_code = l_rec_salesperson.cmpy_code 
		AND mgr_code = l_rec_salesperson.mgr_code
		 
		SELECT desc_text INTO l_territory_desc_text 
		FROM territory 
		WHERE cmpy_code = l_rec_salesperson.cmpy_code 
		AND terr_code = l_rec_salesperson.terri_code

		#---------------------------------------------------------
		OUTPUT TO REPORT ET1_rpt_list(l_rpt_idx,
		l_rec_salesperson.*, l_salesmgr_name_text, l_territory_desc_text ) 
		IF NOT rpt_int_flag_handler2("Salesperson:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT ET1_rpt_list
	CALL rpt_finish("ET1_rpt_list")
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
# END FUNCTION ET1_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ET1_rpt_list( p_rec_salesperson, p_salesmgr_name_text, p_territory_desc_text )
#
# 
###########################################################################
REPORT ET1_rpt_list(p_rpt_idx, p_rec_salesperson, p_salesmgr_name_text, p_territory_desc_text ) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE p_salesmgr_name_text LIKE salesmgr.name_text 
	DEFINE p_territory_desc_text LIKE territory.desc_text #not used ?????

	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_disc_per FLOAT
	DEFINE l_achieve_per FLOAT 
	DEFINE l_bdgt_amt LIKE stattarget.bdgt_amt 
	DEFINE l_avg_ord_val LIKE statsper.net_amt 
	DEFINE l_desc_text LIKE territory.desc_text
	DEFINE l_sales_ind SMALLINT
 
	DEFINE l_rec_t_salescomm RECORD 
		sale_code LIKE salesperson.sale_code, 
		cust_code LIKE customer.cust_code, 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		total_amt LIKE invoicehead.total_amt, 
		currency_code LIKE invoicehead.currency_code, 
		paid_amt LIKE invoicehead.paid_amt, 
		share_per LIKE saleshare.share_per, 
		comm_amt LIKE invoicedetl.comm_amt 
	END RECORD 

	DEFINE l_curr_code LIKE invoicehead.currency_code
	DEFINE idx SMALLINT
	DEFINE l_comm_cnt SMALLINT	
	DEFINE l_total_amt LIKE invoicehead.total_amt
	DEFINE l_paid_amt LIKE invoicehead.paid_amt
	DEFINE l_comm_amt LIKE invoicedetl.comm_amt
	DEFINE l_gross_amt LIKE statoffer.gross_amt
	DEFINE l_net_amt LIKE statoffer.net_amt
	DEFINE l_sales_qty LIKE statoffer.sales_qty
	DEFINE l_cust_num INTEGER 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_start1_date LIKE statint.start_date 
	DEFINE l_start2_date LIKE statint.start_date
	DEFINE l_end1_date LIKE statint.end_date  
	DEFINE l_end2_date LIKE statint.end_date 

	OUTPUT 

	ORDER external BY p_rec_salesperson.cmpy_code, p_rec_salesperson.sale_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Salesperson:", 
			COLUMN 16, p_rec_salesperson.sale_code, 
			COLUMN 25, p_rec_salesperson.name_text, 
			COLUMN 79, "Week Beginning :", modu_rec_statint.start_date 
			USING "dd-mm-yy" 

			PRINT COLUMN 1, "Sales manager:", 
			COLUMN 16, p_rec_salesperson.mgr_code, 
			COLUMN 25, p_salesmgr_name_text clipped, 
			COLUMN 79, " Ending :", modu_rec_statint.end_date 
			USING "dd-mm-yy" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
 
			SKIP 2 LINES 


		BEFORE GROUP OF p_rec_salesperson.sale_code 
			SKIP TO top OF PAGE 
			--LET i = glob_rec_kandooreport.width_num 
			PRINT COLUMN 14, "-- TURNOVER FIGURES -----------------------", 
			"-------------------------------------------", 
			"---------------------------------" 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			PRINT COLUMN 14, "-------------------------------------------", 
			"-------------------------------------------", 
			"---------------------------------" 
			NEED 5 LINES 
			FOR idx = 1 TO 3 
				CASE idx 
					WHEN 1 
						LET l_rec_statint.* = modu_rec_statint.* 
					WHEN 2 
						LET l_start1_date = dmy_date( 1, 
						month(modu_rec_statint.start_date), 
						year(modu_rec_statint.start_date)) 
						LET l_start2_date = dmy_date( 1, 
						month(modu_rec_statint.start_date), 
						year(modu_rec_statint.start_date)) 
						LET l_end1_date = dmy_date(31, 
						month(modu_rec_statint.start_date), 
						year(modu_rec_statint.start_date)) 
						LET l_end2_date = dmy_date(31, 
						month(modu_rec_statint.start_date), 
						year(modu_rec_statint.start_date)) 
						OPEN c2_statint USING p_rec_salesperson.cmpy_code, 
						modu_rec_statint.year_num, 
						modu_rec_statparms.mth_type_code, 
						l_start1_date, 
						l_end1_date, 
						l_start2_date, 
						l_end2_date 
						FETCH c2_statint INTO l_rec_statint.* 
					WHEN 3 
						OPEN c2_statint USING p_rec_salesperson.cmpy_code, 
						modu_rec_statint.year_num, 
						modu_rec_statparms.year_type_code, 
						l_start1_date, 
						l_end1_date, 
						l_start2_date, 
						l_end2_date 
						FETCH c2_statint INTO l_rec_statint.* 
				END CASE 
				
				OPEN c_statsper USING p_rec_salesperson.cmpy_code, 
				l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num, 
				p_rec_salesperson.mgr_code, 
				p_rec_salesperson.sale_code 
				FETCH c_statsper INTO l_rec_statsper.* 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_rec_statsper.grs_amt = 0 
					LET l_rec_statsper.net_amt = 0 
					LET l_rec_statsper.orders_num = 0 
					LET l_rec_statsper.credits_num = 0 
				END IF 
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
					AND year_num = l_rec_statint.year_num 
					AND type_code = l_rec_statint.type_code 
					AND int_num = l_rec_statint.int_num 
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
				PRINT COLUMN 14, l_rec_statint.type_code; 
				IF idx = 1 THEN 
					PRINT COLUMN 24, l_rec_statint.int_num USING "<<<<"; 
				ELSE 
					PRINT COLUMN 24, l_rec_statint.int_text[1,5]; 
				END IF 
				PRINT COLUMN 35, l_rec_statint.start_date USING "dd-mm-yy", 
				COLUMN 45, l_rec_statint.end_date USING "dd-mm-yy", 
				COLUMN 55, l_rec_statsper.grs_amt USING "-------&.&&", 
				COLUMN 67, l_rec_statsper.net_amt USING "-------&.&&", 
				COLUMN 79, l_disc_per USING "---&.&", 
				COLUMN 87, l_bdgt_amt USING "---,---,--&", 
				COLUMN 99, l_achieve_per USING "---&.&", 
				COLUMN 106, l_rec_statsper.orders_num USING "---,--&", 
				COLUMN 114, l_rec_statsper.credits_num USING "---,--&", 
				COLUMN 122, l_avg_ord_val USING "---,---,--&" 
			END FOR 

		AFTER GROUP OF p_rec_salesperson.sale_code 
			CALL ET1_rpt_print_comm( p_rec_salesperson.sale_code ) 
			DECLARE c_t_salescomm cursor FOR 
			SELECT * FROM t_salescomm 
			ORDER BY currency_code, inv_date, inv_num 
			NEED 30 LINES 
			LET l_curr_code = NULL 

			FOREACH c_t_salescomm INTO l_rec_t_salescomm.* 
				IF l_curr_code IS NULL THEN 
					LET l_curr_code = l_rec_t_salescomm.currency_code 
					LET l_total_amt = 0 
					LET l_paid_amt = 0 
					LET l_comm_amt = 0 
					SKIP 2 LINES 
					PRINT COLUMN 14, "-- COMMISSION DETAILS ---------------------", 
					"-------------------------------------------", 
					"---------------------------------" 
					PRINT COLUMN 14, "Invoice date", 
					COLUMN 28, "Invoice no.", 
					COLUMN 41, "Territory", 
					COLUMN 73, "Customer", 
					COLUMN 93, "Total", 
					COLUMN 109, "Paid", 
					COLUMN 114, "Share %", 
					COLUMN 123, "Commission" 
					PRINT COLUMN 14, "-------------------------------------------", 
					"-------------------------------------------", 
					"---------------------------------" 
				END IF 

				SELECT territory.desc_text INTO l_desc_text 
				FROM territory, invoicehead 
				WHERE inv_num = l_rec_t_salescomm.inv_num 
				AND cust_code = l_rec_t_salescomm.cust_code 
				AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND territory.terr_code = invoicehead.territory_code 
				AND territory.cmpy_code = invoicehead.cmpy_code 

				PRINT COLUMN 14, l_rec_t_salescomm.inv_date USING "dd/mm/yy", 
				COLUMN 28, l_rec_t_salescomm.inv_num USING "#######&", 
				COLUMN 41, l_desc_text, 
				COLUMN 73, l_rec_t_salescomm.cust_code, 
				COLUMN 84, l_rec_t_salescomm.total_amt USING "---,---,--&.&&", 
				COLUMN 99, l_rec_t_salescomm.paid_amt USING "---,---,--&.&&", 
				COLUMN 114, l_rec_t_salescomm.share_per USING "##&.&", 
				COLUMN 121, l_rec_t_salescomm.comm_amt USING "-,---,--&.&&" 
				IF l_rec_t_salescomm.currency_code = l_curr_code THEN 
					IF l_rec_t_salescomm.total_amt IS NOT NULL THEN 
						LET l_total_amt = l_total_amt + l_rec_t_salescomm.total_amt 
					END IF 
					IF l_rec_t_salescomm.paid_amt IS NOT NULL THEN 
						LET l_paid_amt = l_paid_amt + l_rec_t_salescomm.paid_amt 
					END IF 
					IF l_rec_t_salescomm.comm_amt IS NOT NULL THEN 
						LET l_comm_amt = l_comm_amt + l_rec_t_salescomm.comm_amt 
					END IF 
				ELSE 
					PRINT COLUMN 84, "-------------- --------------", 
					COLUMN 120, "-------------" 
					PRINT COLUMN 72, "Total ", l_rec_t_salescomm.currency_code, " :", 
					COLUMN 84, l_total_amt USING "---,---,--&.&&", 
					COLUMN 99, l_paid_amt USING "---,---,--&.&&", 
					COLUMN 120, l_comm_amt USING "--,---,--&.&&" 
					PRINT COLUMN 84, "-------------- --------------", 
					COLUMN 120, "-------------" 
					LET l_curr_code = l_rec_t_salescomm.currency_code 
					IF l_rec_t_salescomm.total_amt IS NULL THEN 
						LET l_total_amt = 0 
					ELSE 
						LET l_total_amt = l_rec_t_salescomm.total_amt 
					END IF 
					IF l_rec_t_salescomm.paid_amt IS NULL THEN 
						LET l_paid_amt = 0 
					ELSE 
						LET l_paid_amt = l_rec_t_salescomm.paid_amt 
					END IF 
					IF l_rec_t_salescomm.comm_amt IS NULL THEN 
						LET l_comm_amt = 0 
					ELSE 
						LET l_comm_amt = l_rec_t_salescomm.comm_amt 
					END IF 
				END IF 

			END FOREACH 

			IF l_curr_code IS NOT NULL THEN 
				PRINT COLUMN 84, "-------------- --------------", 
				COLUMN 120, "-------------" 
				PRINT COLUMN 72, "Total ", l_rec_t_salescomm.currency_code, " :", 
				COLUMN 84, l_total_amt USING "---,---,--&.&&", 
				COLUMN 99, l_paid_amt USING "---,---,--&.&&", 
				COLUMN 120, l_comm_amt USING "--,---,--&.&&" 
				PRINT COLUMN 84, "-------------- --------------", 
				COLUMN 120, "-------------" 
			END IF 

			DELETE FROM t_salescomm WHERE 1=1 

			NEED 15 LINES 
			LET idx = 0 
			OPEN c_offersale USING p_rec_salesperson.cmpy_code, 
			modu_rec_statint.start_date, 
			modu_rec_statint.end_date 

			FOREACH c_offersale INTO l_rec_offersale.* 
				IF idx = 0 THEN 
					SKIP 2 LINES 
					PRINT COLUMN 14, "-- SPECIAL OFFER DETAILS ------------------", 
					"-------------------------------------------", 
					"---------------------------------" 
					PRINT COLUMN 48, "----------- Week ",modu_rec_statint.int_text[1,4], 
					" -----------", 
					COLUMN 95, "----------- Year TO Date -----------" 
					PRINT COLUMN 14, "Offer", 
					COLUMN 21, "Description", 
					COLUMN 48, "Sold", 
					COLUMN 53, "No. cust", 
					COLUMN 64, "Nett turnover", 
					COLUMN 80, "Disc %", 
					COLUMN 95, "Sold", 
					COLUMN 100, "No. cust", 
					COLUMN 111, "Nett turnover", 
					COLUMN 127, "Disc %" 
					PRINT COLUMN 14, "-------------------------------------------", 
					"-------------------------------------------", 
					"---------------------------------" 
				END IF 
				LET idx = idx + 1 
				OPEN c_statoffer USING p_rec_salesperson.cmpy_code, 
				p_rec_salesperson.sale_code, 
				l_rec_offersale.offer_code, 
				modu_rec_statint.year_num, 
				modu_rec_statint.type_code, 
				modu_rec_statint.int_num 
				FETCH c_statoffer INTO l_gross_amt, 
				l_net_amt, 
				l_sales_qty, 
				l_cust_num 
				IF status = NOTFOUND THEN 
					LET l_gross_amt = 0 
					LET l_net_amt = 0 
					LET l_sales_qty = 0 
					LET l_cust_num = 0 
				END IF 
				IF l_gross_amt = 0 THEN 
					LET l_disc_per = 0 
				ELSE 
					LET l_disc_per = 100 * (1-(l_net_amt/l_gross_amt)) 
				END IF 
				PRINT COLUMN 14, l_rec_offersale.offer_code, 
				COLUMN 21, l_rec_offersale.desc_text[1,20], 
				COLUMN 42, l_sales_qty USING "------&.&&", 
				COLUMN 55, l_cust_num USING "#####&", 
				COLUMN 64, l_net_amt USING "---------&.&&", 
				COLUMN 80, l_disc_per USING "##&.&&"; 

				OPEN c_statoffer USING p_rec_salesperson.cmpy_code, 
				p_rec_salesperson.sale_code, 
				l_rec_offersale.offer_code, 
				modu_rec_statint.year_num, 
				modu_rec_statparms.year_type_code, 
				modu_rec_statparms.parm_code 

				FETCH c_statoffer INTO l_gross_amt, 
				l_net_amt, 
				l_sales_qty, 
				l_cust_num 
				IF status = NOTFOUND THEN 
					LET l_gross_amt = 0 
					LET l_net_amt = 0 
					LET l_sales_qty = 0 
					LET l_cust_num = 0 
				END IF 

				IF l_gross_amt = 0 THEN 
					LET l_disc_per = 0 
				ELSE 
					LET l_disc_per = 100 * (1-(l_net_amt/l_gross_amt)) 
				END IF 
				PRINT COLUMN 89, l_sales_qty USING "------&.&&", 
				COLUMN 102, l_cust_num USING "#####&", 
				COLUMN 111, l_net_amt USING "---------&.&&", 
				COLUMN 127, l_disc_per USING "##&.&&" 
			END FOREACH 

		ON LAST ROW 
			SKIP 3 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT 
###########################################################################
# END REPORT ET1_rpt_list( p_rec_salesperson, p_salesmgr_name_text, p_territory_desc_text )
###########################################################################


###########################################################################
# FUNCTION ET1_rpt_print_comm(p_sale_code)
#
# #Called by the REPORT function
###########################################################################
FUNCTION ET1_rpt_print_comm(p_sale_code) 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_saleshare RECORD LIKE saleshare.* 
	DEFINE l_comm_amt LIKE invoicedetl.comm_amt 
	DEFINE l_query_text STRING

	LET l_query_text = "SELECT invoicehead.* ", 
	"FROM invoicehead,", 
	"salesperson ", 
	"WHERE invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND invoicehead.sale_code = '",p_sale_code,"' ", 
	"AND invoicehead.inv_date between '", 
	modu_rec_statint.start_date, "' ", 
	"AND '", modu_rec_statint.end_date, "' ", 
	"AND invoicehead.posted_flag NOT in ('V', 'H') ", 
	"AND salesperson.cmpy_code = invoicehead.cmpy_code ", 
	"AND salesperson.sale_code = invoicehead.sale_code ", 
	"ORDER BY invoicehead.sale_code" 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead cursor FOR s_invoicehead 
	
	FOREACH c_invoicehead INTO l_rec_invoicehead.* 
		DECLARE c_invoicedetl cursor FOR 
		SELECT * 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = l_rec_invoicehead.inv_num 
		
		FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
			SELECT unique 1 
			FROM saleshare 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = l_rec_invoicedetl.order_num 
			IF status = NOTFOUND THEN 
				UPDATE t_salescomm 
				SET comm_amt = comm_amt + l_rec_invoicedetl.comm_amt 
				WHERE sale_code = l_rec_invoicehead.sale_code 
				AND inv_num = l_rec_invoicehead.inv_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO t_salescomm VALUES (l_rec_invoicehead.sale_code, 
					l_rec_invoicehead.cust_code, 
					l_rec_invoicehead.inv_num, 
					l_rec_invoicehead.inv_date, 
					l_rec_invoicehead.total_amt, 
					l_rec_invoicehead.currency_code, 
					l_rec_invoicehead.paid_amt, 
					100.0, 
					l_rec_invoicedetl.comm_amt) 
				END IF 
			ELSE 
				DECLARE c_saleshare cursor FOR 
				SELECT * 
				FROM saleshare 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rec_invoicedetl.order_num 
				FOREACH c_saleshare INTO l_rec_saleshare.* 
					IF l_rec_saleshare.share_per > 0 THEN 
						UPDATE t_salescomm 
						SET comm_amt = comm_amt + (l_rec_invoicedetl.comm_amt * 
						(l_rec_saleshare.share_per/100)) 
						WHERE sale_code = l_rec_saleshare.sale_code 
						AND inv_num = l_rec_invoicehead.inv_num 
						IF sqlca.sqlerrd[3] = 0 THEN 
							LET l_comm_amt = l_rec_invoicedetl.comm_amt * 
							(l_rec_saleshare.share_per/100) 
							INSERT INTO t_salescomm 
							VALUES (l_rec_saleshare.sale_code, 
							l_rec_invoicehead.cust_code, 
							l_rec_invoicehead.inv_num, 
							l_rec_invoicehead.inv_date, 
							l_rec_invoicehead.total_amt, 
							l_rec_invoicehead.currency_code, 
							l_rec_invoicehead.paid_amt, 
							l_rec_saleshare.share_per, 
							l_comm_amt) 
						END IF 
					END IF 
				END FOREACH 
			END IF 
		END FOREACH 
	END FOREACH 
	
	LET l_query_text = "SELECT credithead.* ", 
	"FROM credithead,", 
	"salesperson ", 
	"WHERE credithead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND credithead.sale_code = '",p_sale_code,"' ", 
	"AND credithead.cred_date between '", 
	modu_rec_statint.start_date, "' ", 
	"AND '", modu_rec_statint.end_date, "' ", 
	"AND credithead.posted_flag NOT in ('V', 'H') ", 
	"AND salesperson.cmpy_code = credithead.cmpy_code ", 
	"AND salesperson.sale_code = credithead.sale_code ", 
	"ORDER BY credithead.sale_code" 
	PREPARE s_credithead FROM l_query_text 
	DECLARE c_credithead cursor FOR s_credithead
	 
	FOREACH c_credithead INTO l_rec_credithead.* 
		DECLARE c_creditdetl cursor FOR 
		SELECT * 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = l_rec_credithead.cred_num 

		FOREACH c_creditdetl INTO l_rec_creditdetl.* 
			UPDATE t_salescomm 
			SET comm_amt = comm_amt + l_rec_creditdetl.comm_amt 
			WHERE sale_code = l_rec_credithead.sale_code 
			AND inv_num = l_rec_credithead.cred_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				INSERT INTO t_salescomm VALUES (l_rec_credithead.sale_code, 
				l_rec_credithead.cust_code, 
				l_rec_credithead.cred_num, 
				l_rec_credithead.cred_date, 
				l_rec_credithead.total_amt, 
				l_rec_credithead.currency_code, 
				0.00, 
				100.0, 
				l_rec_creditdetl.comm_amt) 
			END IF 
		END FOREACH 
		
	END FOREACH 
END FUNCTION
###########################################################################
# END FUNCTION ET1_rpt_print_comm(p_sale_code)
###########################################################################