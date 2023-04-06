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
GLOBALS "../eo/EV_GROUP_GLOBALS.4gl"
GLOBALS "../eo/EV2_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_temp_text char(20) 
DEFINE modu_zero_stats_flag char(1) 
###########################################################################
# FUNCTION EV2_main()
#
# EV2 Customer Yearly Turnover by Sales Territory
###########################################################################
FUNCTION EV2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EV2") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	
			OPEN WINDOW E279 with FORM "E279" 
			 CALL windecoration_e("E279") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
			MENU " Customer Turnover report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EV2","menu-Customer-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV2_rpt_process(EV2_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV2_rpt_process(EV2_rpt_query())
		
				ON ACTION "CANCEL" #ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E279
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EV2_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E279 with FORM "E279" 
			 CALL windecoration_e("E279") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EV2_rpt_query()) #save where clause in env 
			CLOSE WINDOW E279 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EV2_rpt_process(get_url_sel_text())
	END CASE 		

END FUNCTION 
###########################################################################
# END FUNCTION EV2_main()
###########################################################################


###########################################################################
# FUNCTION EV2_rpt_query()
#
#
###########################################################################
FUNCTION EV2_rpt_query() 
	DEFINE l_where_text STRING

	IF NOT EV2_enter_year() THEN
		RETURN NULL
	END IF 

	MESSAGE kandoomsg2("E",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON cust_code, 
	name_text, 
	type_code, 
	sale_code, 
	territory_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EV2","construct-cust_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
--		LET glob_rec_rpt_selector.ref5_ind = modu_order_ind	
		LET glob_rec_rpt_selector.ref6_ind = modu_zero_stats_flag	
		LET glob_rec_rpt_selector.ref5_num = glob_rec_statparms.year_num	
		RETURN l_where_text
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION EV2_rpt_query()
###########################################################################


############################################################
# FUNCTION EV2_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EV2_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_order_text char(20) 
	
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EV2_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EV2_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
--	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV2_rpt_list")].ref5_ind
	LET modu_zero_stats_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV2_rpt_list")].ref6_ind
	LET glob_rec_statparms.year_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV2_rpt_list")].ref5_num 
	#------------------------------------------------------------	
	 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND delete_flag = 'N' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV1_rpt_list")].sel_text clipped," ", 
	"ORDER BY cmpy_code,territory_code,cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer
	 
	LET l_query_text = "SELECT * FROM statcust ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = ? ", 
	"AND type_code = '",glob_rec_statparms.year_type_code,"' ", 
	"AND int_num = 1 ", 
	"AND cust_code = ? " 
	PREPARE s_statcust FROM l_query_text 
	DECLARE c_statcust cursor FOR s_statcust 

	MESSAGE kandoomsg2("E",1160,"")	#1160 Reporting on Customer...

	FOREACH c_customer INTO l_rec_customer.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT EV2_rpt_list(l_rpt_idx,
		l_rec_customer.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.name_text,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT EV2_rpt_list
	CALL rpt_finish("EV2_rpt_list")
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
# END FUNCTION EV2_rpt_process(p_where_text) 
############################################################


###########################################################################
# FUNCTION EV2_enter_year()
#
#
###########################################################################
FUNCTION EV2_enter_year() 

	LET modu_zero_stats_flag = xlate_to("Y") 
	LET glob_rec_statparms.year_num = year(today) 

	MESSAGE kandoomsg2("E",1157,"")	#1157 Enter year FOR REPORT run - ESC TO Continue

	INPUT 
		glob_rec_statparms.year_num, 
		modu_zero_stats_flag WITHOUT DEFAULTS 
	FROM
		year_num, 
		zero_stats_flag ATTRIBUTE(UNBUFFERED)
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EV2","input-year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
			NEXT FIELD year_num 

		AFTER FIELD year_num 
			IF glob_rec_statparms.year_num IS NULL THEN 
				ERROR kandoomsg2("E",9210,"") 		#9210 Year number must be entered
				LET glob_rec_statparms.year_num = year(today) 
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_statparms.year_num = year(today) 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EV2_enter_year()
###########################################################################


###########################################################################
# REPORT EV2_rpt_list(p_rec_customer)
#
#
###########################################################################
REPORT EV2_rpt_list(p_rpt_idx,p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_territory RECORD LIKE territory.*
	DEFINE l_rec_cur_statcust RECORD LIKE statcust.*
	DEFINE l_rec_prv_statcust RECORD LIKE statcust.*
	DEFINE l_cur_disc_per FLOAT
	DEFINE l_prv_disc_per FLOAT
	DEFINE l_cust_printed SMALLINT 
	DEFINE i SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_customer.cmpy_code, 
	p_rec_customer.territory_code, 
	p_rec_customer.cust_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 

			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[62,65] = glob_rec_statparms.year_num USING "####" 
			LET glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text[74,77] = glob_rec_statparms.year_num -1 USING "####" 
 
 			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text #wasl_arr_line[2]
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text #wasl_arr_line[2] 

			INITIALIZE l_rec_territory.* TO NULL 
			SELECT * INTO l_rec_territory.* FROM territory 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND terr_code = p_rec_customer.territory_code 

			PRINT COLUMN 01,"Territory: ", 
			COLUMN 12,p_rec_customer.territory_code, 
			COLUMN 18,l_rec_territory.desc_text 
			SKIP 1 line 

		BEFORE GROUP OF p_rec_customer.territory_code 
			SKIP TO top OF PAGE 
			LET l_cust_printed = TRUE 

		AFTER GROUP OF p_rec_customer.territory_code 
			IF l_cust_printed THEN 
				PRINT COLUMN 10, "No customer statistics FOR selected territory" 
			END IF 

		ON EVERY ROW 
			OPEN c_statcust USING glob_rec_statparms.year_num, p_rec_customer.cust_code 
			FETCH c_statcust INTO l_rec_cur_statcust.* 
			IF status = NOTFOUND THEN 
				LET l_rec_cur_statcust.gross_amt = 0 
				LET l_rec_cur_statcust.net_amt = 0 
				LET l_rec_cur_statcust.cost_amt = 0 
			END IF 
			
			LET i = glob_rec_statparms.year_num - 1 
			OPEN c_statcust USING i, 
			p_rec_customer.cust_code 
			FETCH c_statcust INTO l_rec_prv_statcust.* 
			IF status = NOTFOUND THEN 
				LET l_rec_prv_statcust.gross_amt = 0 
				LET l_rec_prv_statcust.net_amt = 0 
				LET l_rec_prv_statcust.cost_amt = 0 
			END IF 
			IF l_rec_cur_statcust.gross_amt = 0 
			AND l_rec_cur_statcust.net_amt = 0 
			AND l_rec_cur_statcust.cost_amt = 0 
			AND l_rec_prv_statcust.gross_amt = 0 
			AND l_rec_prv_statcust.net_amt = 0 
			AND l_rec_prv_statcust.cost_amt = 0 
			AND modu_zero_stats_flag = "N" THEN 
				# Do NOT PRINT zero statistics
			ELSE 
				NEED 6 LINES 
				LET l_cust_printed = FALSE 
				IF l_rec_cur_statcust.gross_amt = 0 THEN 
					LET l_cur_disc_per = 0 
				ELSE 
					LET l_cur_disc_per = 100 * 
					(1-(l_rec_cur_statcust.net_amt/l_rec_cur_statcust.gross_amt)) 
				END IF 
				IF l_rec_prv_statcust.gross_amt = 0 THEN 
					LET l_prv_disc_per = 0 
				ELSE 
					LET l_prv_disc_per = 100 * 
					(1-(l_rec_prv_statcust.net_amt/l_rec_prv_statcust.gross_amt)) 
				END IF 
				PRINT COLUMN 01, p_rec_customer.cust_code, 
				COLUMN 10, p_rec_customer.name_text, 
				COLUMN 43, "Gross turnover", 
				COLUMN 58, l_rec_cur_statcust.gross_amt USING "---,---,--&", 
				COLUMN 70, l_rec_prv_statcust.gross_amt USING "---,---,--&" 
				PRINT COLUMN 10, p_rec_customer.addr1_text, 
				COLUMN 43, "Nett turnover", 
				COLUMN 58, l_rec_cur_statcust.net_amt USING "---,---,--&", 
				COLUMN 70, l_rec_prv_statcust.net_amt USING "---,---,--&" 
				IF p_rec_customer.addr2_text IS NULL THEN 
					IF p_rec_customer.city_text IS NULL THEN 
						PRINT COLUMN 10, p_rec_customer.state_code[1,3], 
						COLUMN 37, p_rec_customer.post_code[1,4]; 
					ELSE 
						PRINT COLUMN 10, p_rec_customer.city_text clipped," ", 
						p_rec_customer.state_code[1,3], 
						COLUMN 37, p_rec_customer.post_code[1,4]; 
					END IF 
				ELSE 
					PRINT COLUMN 10, p_rec_customer.addr2_text; 
				END IF 
				PRINT COLUMN 43, "Profit", 
				COLUMN 58, l_rec_cur_statcust.net_amt - 
				l_rec_cur_statcust.cost_amt USING "---,---,--&", 
				COLUMN 70, l_rec_prv_statcust.net_amt - 
				l_rec_prv_statcust.cost_amt USING "---,---,--&" 
				IF p_rec_customer.addr2_text IS NOT NULL THEN 
					IF p_rec_customer.city_text IS NULL THEN 
						PRINT COLUMN 10, p_rec_customer.state_code[1,3], 
						COLUMN 37, p_rec_customer.post_code[1,4]; 
					ELSE 
						PRINT COLUMN 10, p_rec_customer.city_text clipped," ", 
						p_rec_customer.state_code[1,3], 
						COLUMN 37, p_rec_customer.post_code[1,4]; 
					END IF 
				END IF 
				PRINT COLUMN 43, "Discount %", 
				COLUMN 63, l_cur_disc_per USING "---&.&", 
				COLUMN 75, l_prv_disc_per USING "---&.&" 
				SKIP 1 line 
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
# END REPORT EV2_rpt_list(p_rec_customer)
###########################################################################