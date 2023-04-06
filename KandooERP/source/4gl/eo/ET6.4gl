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
GLOBALS "../eo/ET6_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
########################################################################### 
DEFINE modu_rec_statparms RECORD LIKE statparms.* 
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_temp_text char(20) 
###########################################################################
# FUNCTION ET6_main()
#
# ET6 Customer Ranking Report Ordered by Customer Code
########################################################################### 
FUNCTION ET6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ET6")  

	SELECT * INTO modu_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	
	CREATE temp TABLE t_ranking(
		rank_ind char(1), 
		last_ytd_amt decimal(16,2), 
		curr_ytd_amt decimal(16,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
	
			OPEN WINDOW E274 with FORM "E274" 
			 CALL windecoration_e("E274")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY getmenuitemlabel(NULL) TO header_text 
		 
			MENU " Customer Ranking report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","ET6","menu-Customer_Ranking-1") -- albo kd-502 
		
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
										
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ET6_rpt_process(ET6_rpt_query())
		
				ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E274 
	
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ET6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E274 with FORM "E274" 
			 CALL windecoration_e("E274") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ET6_rpt_query()) #save where clause in env 
			CLOSE WINDOW E274 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ET6_rpt_process(get_url_sel_text())
	END CASE 	
END FUNCTION 
###########################################################################
# END FUNCTION ET6_main()
########################################################################### 


###########################################################################
# FUNCTION ET6_rpt_query() 
#
# 
########################################################################### 
FUNCTION ET6_rpt_query() 
	DEFINE l_where_text STRING

	IF (NOT ET6_enter_year()) OR (int_flag = TRUE) THEN
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
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","ET6","construct-sale_code-1") -- albo kd-502 

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
# END FUNCTION ET6_rpt_query() 
########################################################################### 


###########################################################################
# FUNCTION ET6_enter_year() 
#
# 
########################################################################### 
FUNCTION ET6_enter_year() 
	DEFINE l_order_ind char(1) 
	DEFINE l_query_text STRING 
	DEFINE l_order_text char(20) 

	LET l_order_ind = "1" 
	LET modu_rec_statparms.year_num = year(today) 
	MESSAGE kandoomsg2("E",1157,"")	#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT BY NAME modu_rec_statparms.year_num, l_order_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ET6","input-pr_statparms-1") -- albo kd-502
 
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statparms.year_num = modu_rec_statparms.year_num - 1 
			NEXT FIELD year_num
			 
		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statparms.year_num = modu_rec_statparms.year_num + 1 
			NEXT FIELD year_num
			 
		AFTER FIELD year_num 
			IF modu_rec_statparms.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"")	#9210 Year number must be entered
				LET modu_rec_statparms.year_num = year(today) 
				NEXT FIELD year_num 
			END IF
			 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET modu_rec_statparms.year_num = year(today) 
		RETURN FALSE 
	ELSE 
		CASE l_order_ind 
			WHEN "1" 
				LET l_order_text = "cust_code" 
			WHEN "2" 
				LET l_order_text = "name_text" 
			WHEN "3" 
				LET l_order_text = "post_code,cust_code" 
			WHEN "4" 
				LET l_order_text = "state_code,cust_code" 
		END CASE 

		LET l_query_text = "SELECT * FROM customer ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND sale_code = ? ", 
		"AND delete_flag = 'N' ", 
		"ORDER BY cmpy_code,",l_order_text clipped
		 
		PREPARE s_customer FROM l_query_text 
		DECLARE c_customer cursor FOR s_customer 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ET6_enter_year() 
########################################################################### 


###########################################################################
# FUNCTION ET6_rpt_process(p_where_text) 
#
#
###########################################################################
FUNCTION ET6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"ET6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ET6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].ref2_ind
	#------------------------------------------------------------	
	 
	LET l_query_text = "SELECT * FROM salesperson ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ET6_rpt_list")].sel_text clipped," ",	 
	"ORDER BY 1,2" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson 
	
	LET l_query_text = "SELECT sum(net_amt) FROM statsale ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = ? ", 
	"AND type_code = ? ", 
	"AND int_num = ? ", 
	"AND sale_code = ? ", 
	"AND cust_code = ? " 
	PREPARE s_statsale FROM l_query_text 
	DECLARE c_statsale cursor FOR s_statsale 
	MESSAGE kandoomsg("E",1045,"") #1045 Reporting on Salesperson...


	FOREACH c_salesperson INTO l_rec_salesperson.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT ET6_rpt_list(l_rpt_idx,
		l_rec_salesperson.*,modu_rec_statparms.*)  
		IF NOT rpt_int_flag_handler2("Sales Person:",l_rec_salesperson.name_text, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		

	END FOREACH
	 
	#------------------------------------------------------------
	FINISH REPORT ET6_rpt_list
	CALL rpt_finish("ET6_rpt_list")
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
# END FUNCTION ET6_rpt_process(p_where_text) 
###########################################################################


###########################################################################
# REPORT ET6_rpt_list(p_rpt_idx,p_rec_salesperson,p_rec_statparms)
#
# 
########################################################################### 
REPORT ET6_rpt_list(p_rpt_idx,p_rec_salesperson,p_rec_statparms) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_salesperson RECORD LIKE salesperson.*
	DEFINE p_rec_statparms RECORD LIKE statparms.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_net_amt array[3,13] OF LIKE statsale.net_amt
	DEFINE l_tot_net_amt LIKE statsale.net_amt
	DEFINE l_rank_ind char(1) 
	DEFINE x,i,j SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_salesperson.cmpy_code, p_rec_salesperson.sale_code 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Salesperson:", 
			COLUMN 14,p_rec_salesperson.sale_code, 
			COLUMN 25,p_rec_salesperson.name_text 
			SKIP 1 line 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
			
		BEFORE GROUP OF p_rec_salesperson.sale_code 
			NEED 40 LINES 
			SKIP 1 line 
			LET x = 2 
			DELETE FROM t_ranking 
			
			OPEN c_customer USING p_rec_salesperson.sale_code 
			
			FOREACH c_customer INTO l_rec_customer.* 
				PRINT COLUMN 01,l_rec_customer.cust_code, 
				COLUMN 10,l_rec_customer.name_text 
				LET l_tot_net_amt = 0 
				FOR j = 1 TO 3 
					LET l_arr_net_amt[j,13] = 0 
					CASE j 
						WHEN 1 
							PRINT COLUMN 10,l_rec_customer.addr1_text[1,25], 
							COLUMN 36,(p_rec_statparms.year_num-1) USING "####"; 
							
						WHEN 2 
							IF l_rec_customer.city_text IS NULL THEN 
								LET l_rec_customer.city_text = l_rec_customer.addr2_text 
							END IF 
							PRINT COLUMN 10,l_rec_customer.city_text[1,18], 
							COLUMN 28,l_rec_customer.post_code[1,8], 
							COLUMN 36,p_rec_statparms.year_num USING "####"; 
							
						WHEN 3 
							PRINT COLUMN 10,"Ph:",l_rec_customer.tele_text, 
							COLUMN 36,"%diff"; 
							IF l_arr_net_amt[1,13] = 0 THEN 
								LET l_arr_net_amt[3,13] = 0 
							ELSE 
								LET l_arr_net_amt[3,13] = ((l_arr_net_amt[2,13]-l_arr_net_amt[1,13]) /l_arr_net_amt[1,13]) * 100 
							END IF 
							
						WHEN 4 #NOTE: this is was added after introduction of mobile phone - just a copy paste, not tested and not working... must be sorted 
							PRINT COLUMN 10,"Mo:",l_rec_customer.mobile_phone, 
							COLUMN 36,"%diff"; 
							IF l_arr_net_amt[1,13] = 0 THEN 
								LET l_arr_net_amt[3,13] = 0 
							ELSE 
								LET l_arr_net_amt[3,13] = ((l_arr_net_amt[2,13]-l_arr_net_amt[1,13]) /l_arr_net_amt[1,13]) * 100 
							END IF 

						WHEN 5 #NOTE: this is was added after introduction of mobile phone - just a copy paste, not tested and not working... must be sorted 
							PRINT COLUMN 10,"Mo:",l_rec_customer.email, 
							COLUMN 36,"%diff"; 
							IF l_arr_net_amt[1,13] = 0 THEN 
								LET l_arr_net_amt[3,13] = 0 
							ELSE 
								LET l_arr_net_amt[3,13] = ((l_arr_net_amt[2,13]-l_arr_net_amt[1,13]) /l_arr_net_amt[1,13]) * 100 
							END IF 
							
					END CASE 

					FOR i = 1 TO 12 
						IF j = 3 THEN ## %-difference line 
							IF l_arr_net_amt[1,i] = 0 THEN 
								LET l_arr_net_amt[3,i] = 0 
							ELSE 
								LET l_arr_net_amt[3,i] = ((l_arr_net_amt[2,i]-l_arr_net_amt[1,i]) /l_arr_net_amt[1,i])*100 
							END IF 
							LET x = (i*7) + 34 
							PRINT COLUMN x, l_arr_net_amt[j,i] USING " ---&.&"; 
						ELSE 
							LET x = p_rec_statparms.year_num -2 +j 
							OPEN c_statsale USING x, 
							p_rec_statparms.mth_type_code, 
							i, 
							p_rec_salesperson.sale_code, 
							l_rec_customer.cust_code 
							FETCH c_statsale INTO l_arr_net_amt[j,i] 
							IF l_arr_net_amt[j,i] IS NULL THEN 
								LET l_arr_net_amt[j,i] = 0 
							END IF 
							IF i <= p_rec_statparms.mth_num THEN 
								LET l_arr_net_amt[j,13] = l_arr_net_amt[j,13]+l_arr_net_amt[j,i] 
							END IF 
							IF j = 1 THEN ## increment total 
								LET l_tot_net_amt = l_tot_net_amt + l_arr_net_amt[1,i] 
							END IF 
							LET x = (i*7) + 34 
							PRINT COLUMN x, l_arr_net_amt[j,i] USING " -----&"; 
						END IF 
					END FOR 

					IF j = 3 THEN ## %-difference line 
						PRINT COLUMN 125, l_arr_net_amt[j,13] USING " ---&.&" 
					ELSE 
						PRINT COLUMN 125, l_arr_net_amt[j,13] USING " -----&" 
					END IF 
				END FOR 
				
				CASE 
					WHEN l_tot_net_amt >= p_rec_statparms.cust_rank1_amt 
						LET l_rank_ind = "A" 
					WHEN l_tot_net_amt >= p_rec_statparms.cust_rank2_amt 
						LET l_rank_ind = "B" 
					WHEN l_tot_net_amt >= p_rec_statparms.cust_rank3_amt 
						LET l_rank_ind = "C" 
					WHEN l_tot_net_amt >= p_rec_statparms.cust_rank4_amt 
						LET l_rank_ind = "D" 
					OTHERWISE 
						LET l_rank_ind = "E" 
				END CASE 

				PRINT COLUMN 10,"Year",(p_rec_statparms.year_num-1) USING " ####", 
				COLUMN 20,"Total",l_tot_net_amt USING " -----&", 
				COLUMN 36,"Rank: ",l_rank_ind 
				SKIP 1 LINES 
				INSERT INTO t_ranking 
				VALUES (l_rank_ind,l_arr_net_amt[1,13],l_arr_net_amt[2,13]) 

			END FOREACH 
			
			SELECT unique 1 FROM t_ranking 
			IF status = NOTFOUND THEN 
				PRINT COLUMN 10,"No customers nominated FOR this salesperson" 
			ELSE 
				NEED 12 LINES 
				PRINT COLUMN 10, "Salesperson summary" 
				PRINT COLUMN 10, "===================" 
				DECLARE c_ranking cursor FOR 
				SELECT rank_ind, 
				count(*), 
				sum(last_ytd_amt), 
				sum(curr_ytd_amt), 
				avg(last_ytd_amt), 
				avg(curr_ytd_amt) 
				FROM t_ranking 
				GROUP BY rank_ind 
				ORDER BY rank_ind 
				FOREACH c_ranking INTO l_rank_ind, 
					x, 
					l_arr_net_amt[1,1], 
					l_arr_net_amt[2,1], 
					l_arr_net_amt[1,2], 
					l_arr_net_amt[2,2] 
					NEED 9 LINES 
					PRINT COLUMN 05,"Ranking: ",l_rank_ind, 
					COLUMN 30,"No. of customers:",x USING "<<<<<" 
					PRINT COLUMN 30,"Net Amount ytd:" 
					PRINT COLUMN 36,(p_rec_statparms.year_num-1) USING "####", 
					COLUMN 44, l_arr_net_amt[1,1] USING "------&.&&" 
					PRINT COLUMN 36, p_rec_statparms.year_num USING "####", 
					COLUMN 44, l_arr_net_amt[2,1] USING "------&.&&" 
					PRINT COLUMN 30, "Average Customer Amount ytd:" 
					PRINT COLUMN 36, (p_rec_statparms.year_num-1) USING "####", 
					COLUMN 44, l_arr_net_amt[1,2] USING "------&.&&" 
					PRINT COLUMN 36, p_rec_statparms.year_num USING "####", 
					COLUMN 44, l_arr_net_amt[2,2] USING "------&.&&" 
				END FOREACH 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			END IF 
			SKIP 2 LINES 
			
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
# END REPORT ET6_rpt_list(p_rpt_idx,p_rec_salesperson,p_rec_statparms)
#
###########################################################################