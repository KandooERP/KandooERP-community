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
GLOBALS "../eo/EV6_GLOBALS.4gl"  
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_statint RECORD LIKE statint.* 
DEFINE modu_accum_net LIKE statcust.net_amt 
DEFINE modu_top_customers SMALLINT 
DEFINE modu_temp_text char(50) 
###########################################################################
# FUNCTION EV6_main()
#
# EV6 Top Customers Turnover
###########################################################################
FUNCTION EV6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EV6") 
	 
	CREATE temp TABLE t_statcust(
		rank_no SMALLINT, 
		cust_code char(8), 
		name_text char(30), 
		city_text char(30), 
		gross_amt decimal(16,2), 
		net_amt decimal(16,2)) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW E282 with FORM "E282" 
			 CALL windecoration_e("E282")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			DISPLAY getmenuitemlabel(NULL) TO header_text 
		
			MENU " Top Customers report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","EV6","menu-modu_top_customers-1") -- albo kd-502 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV6_rpt_process(EV6_rpt_query())
							
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "REPORT" #COMMAND "Report" " SELECT criteria AND PRINT report" 
					CALL rpt_rmsreps_reset(NULL)					 
					CALL EV6_rpt_process(EV6_rpt_query())
					
				ON ACTION "PRINT MANAGER"		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " RETURN TO menus" 
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW E282 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL EV6_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW E282 with FORM "E282" 
			 CALL windecoration_e("E282") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(EV6_rpt_query()) #save where clause in env 
			CLOSE WINDOW E282 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL EV6_rpt_process(get_url_sel_text())
	END CASE
				
END FUNCTION 
###########################################################################
# END FUNCTION EV6_main()
###########################################################################


###########################################################################
# FUNCTION EV6_rpt_query()
#
# 
###########################################################################
FUNCTION EV6_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("E",1001,"") #1001 Enter Selection Criteria - ESC TO Continue

	CONSTRUCT l_where_text ON customer.cust_code, 
	name_text, 
	customer.type_code, 
	sale_code, 
	territory_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code 
	FROM customer.cust_code, 
	name_text, 
	customer.type_code, 
	sale_code, 
	territory_code, 
	addr1_text, 
	addr2_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EV6","construct-cust_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL
	ELSE
--		LET glob_rec_rpt_selector.ref5_ind = modu_order_ind	
--		LET glob_rec_rpt_selector.ref6_ind = modu_zero_stats_flag	
		LET glob_rec_rpt_selector.ref5_num = glob_rec_statparms.year_num

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
# END FUNCTION EV6_rpt_query()
###########################################################################


############################################################
# FUNCTION EV6_rpt_process(p_where_text) 
#
#
############################################################
FUNCTION EV6_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT  #report array index

	DEFINE l_rec_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		city_text LIKE customer.city_text, 
		addr2_text LIKE customer.addr2_text, 
		gross_amt LIKE statcust.gross_amt, 
		net_amt LIKE statcust.net_amt 
	END RECORD 
	DEFINE l_rec_statcust RECORD LIKE statcust.* 
	DEFINE l_rank_no SMALLINT 
 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"EV6_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT EV6_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#get additional rms_reps values for query
--	LET modu_order_ind = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref3_ind

	LET modu_rec_statint.year_num =  glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref1_num 
	LET modu_rec_statint.type_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref1_code
	LET modu_rec_statint.start_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref1_date			
	LET modu_rec_statint.dist_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref1_ind	
		
	LET modu_rec_statint.int_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref2_num			
	LET modu_rec_statint.end_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref2_date
	LET modu_rec_statint.int_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref2_code
	LET modu_rec_statint.updreq_flag = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].ref2_ind
	#------------------------------------------------------------	
--

	DELETE FROM t_statcust 
	WHERE 1=1 



	LET l_query_text = "SELECT statcust.cust_code,customer.name_text,", 
	"customer.city_text,customer.addr2_text,", 
	"statcust.gross_amt,statcust.net_amt ", 
	"FROM statcust,customer ", 
	"WHERE statcust.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = '",modu_rec_statint.year_num,"' ", 
	"AND statcust.type_code = '",modu_rec_statint.type_code,"' ", 
	"AND int_num = '",modu_rec_statint.int_num,"' ", 
	"AND statcust.cust_code = customer.cust_code ", 
	"AND delete_flag = 'N' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("EV6_rpt_list")].sel_text clipped," ",
	"ORDER BY statcust.net_amt desc,statcust.cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer 

	LET modu_accum_net = 0 
	LET l_rank_no = 0 

	FOREACH c_customer INTO l_rec_customer.* 
		IF l_rec_customer.city_text IS NULL THEN 
			LET l_rec_customer.city_text = l_rec_customer.addr2_text 
		END IF 
		LET l_rank_no = l_rank_no + 1 
		IF l_rank_no > modu_top_customers THEN 
			EXIT FOREACH 
		ELSE 
			#DISPLAY l_rec_customer.name_text at 1,28 

			INSERT INTO t_statcust VALUES (l_rank_no, 
			l_rec_customer.cust_code, 
			l_rec_customer.name_text, 
			l_rec_customer.city_text, 
			l_rec_customer.gross_amt, 
			l_rec_customer.net_amt) 
		END IF 
	END FOREACH 

	#---------------------------------------------------------
	OUTPUT TO REPORT EV6_rpt_list(l_rpt_idx) 
	#---------------------------------------------------------

	#------------------------------------------------------------
	FINISH REPORT EV6_rpt_list
	CALL rpt_finish("EV6_rpt_list")
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
# END FUNCTION EV6_rpt_process(p_where_text) 
############################################################


###########################################################################
# FUNCTION EV6_enter_year()
#
# 
###########################################################################
FUNCTION EV6_enter_year() 

	LET modu_top_customers = 100 
	LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
	MESSAGE kandoomsg2("E",1157,"") #1157 Enter year FOR REPORT run - ESC TO Continue
	INPUT
	  modu_rec_statint.year_num, 
		modu_rec_statint.type_code, 
		modu_rec_statint.int_text, 
		modu_top_customers WITHOUT DEFAULTS 
	FROM
		year_num, 
		type_code, 
		int_text, 
		top_customers
	ATTRIBUTE(UNBUFFERED)
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EV6","input-modu_rec_statint-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "LOOKUP" infield(int_text)  
				LET modu_temp_text = "year_num = '",modu_rec_statint.year_num,"' ", 
				"AND type_code = '",modu_rec_statint.type_code,"'" 
				LET modu_temp_text = show_interval(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_rec_statint.int_num = modu_temp_text 
					NEXT FIELD int_text 
				END IF 
 
		ON ACTION "LOOKUP" infield(type_code)  
				LET modu_temp_text = show_inttype(glob_rec_kandoouser.cmpy_code,"") 
				IF modu_temp_text IS NOT NULL THEN 
					LET modu_rec_statint.type_code = modu_temp_text 
					NEXT FIELD type_code 
				END IF 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num - 1 
			NEXT FIELD year_num 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET modu_rec_statint.year_num = modu_rec_statint.year_num + 1 
			NEXT FIELD year_num 

		BEFORE FIELD year_num 
			IF modu_rec_statint.type_code IS NULL THEN 
				LET modu_rec_statint.type_code = glob_rec_statparms.mth_type_code 
				LET modu_rec_statint.int_num = glob_rec_statparms.mth_num 
			END IF 
			IF modu_rec_statint.int_num IS NOT NULL THEN 
				SELECT * INTO modu_rec_statint.* 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statint.type_code 
				AND int_num = modu_rec_statint.int_num 
				
				DISPLAY BY NAME 
					modu_rec_statint.int_text, 
					modu_rec_statint.type_code, 
					modu_rec_statint.start_date, 
					modu_rec_statint.end_date 

			END IF 

		AFTER FIELD year_num 
			IF modu_rec_statint.year_num IS NULL THEN 
				MESSAGE kandoomsg2("E",9210,"") 	#9210 Year number must be entered
				LET modu_rec_statint.year_num = glob_rec_statparms.year_num 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD type_code 
			IF modu_rec_statint.type_code IS NULL THEN 
				CLEAR int_text 
				NEXT FIELD year_num 
			ELSE 
				SELECT * FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = modu_rec_statint.type_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9202,"") 		#9202 Interval type does NOT exist - Try Window"
					LET modu_rec_statint.type_code = glob_rec_statparms.mth_type_code 
					NEXT FIELD type_code 
				ELSE 
					SELECT * INTO modu_rec_statint.* 
					FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = modu_rec_statint.year_num 
					AND type_code = modu_rec_statint.type_code 
					AND int_num = modu_rec_statint.int_num 
				END IF 
			END IF 
			
			DISPLAY modu_rec_statint.start_date TO start_date 
			DISPLAY modu_rec_statint.end_date TO end_date 

		BEFORE FIELD int_text 
			IF modu_rec_statint.int_num IS NULL THEN 
				LET modu_rec_statint.int_text = NULL 
			ELSE 
				SELECT * INTO modu_rec_statint.* 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statint.type_code 
				AND int_num = modu_rec_statint.int_num 
				DISPLAY BY NAME modu_rec_statint.start_date, 
				modu_rec_statint.end_date 

			END IF 

		AFTER FIELD int_text 
			IF modu_rec_statint.int_text IS NULL THEN 
				NEXT FIELD year_num 
			ELSE 
				DECLARE c_interval cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = modu_rec_statint.year_num 
				AND type_code = modu_rec_statint.type_code 
				AND int_text = modu_rec_statint.int_text 
				OPEN c_interval 
				FETCH c_interval INTO modu_rec_statint.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9223,"") #9223 Interval does NOT exist - Try Window"
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
# END FUNCTION EV6_enter_year()
###########################################################################


###########################################################################
# REPORT EV6_rpt_list()
#
# 
###########################################################################
REPORT EV6_rpt_list(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE l_rec_statcust RECORD 
		rank_no SMALLINT, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		city_text LIKE customer.city_text, 
		gross_amt LIKE statcust.gross_amt, 
		net_amt LIKE statcust.net_amt 
	END RECORD 
	DEFINE l_tot_net_amt LIKE statcust.net_amt 
	DEFINE l_disc_per FLOAT 
	DEFINE l_tot_per FLOAT 
	DEFINE i SMALLINT 

	OUTPUT 
 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01,"Interval: ", modu_rec_statint.int_text, 
			COLUMN 27,"Top ", modu_top_customers USING "<<<&", " customers" 
			SKIP 1 line 

			PRINT COLUMN 01,glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			#Note: there will only ever be one row...
			#
			# sum the net_amt over the top 'n' customers
			SELECT sum(net_amt) INTO l_tot_net_amt FROM t_statcust 
			IF l_tot_net_amt = 0 THEN 
				LET l_tot_net_amt = NULL 
			END IF 
			DECLARE c_statcust cursor FOR 
			SELECT * FROM t_statcust 
			
			FOREACH c_statcust INTO l_rec_statcust.* 
				NEED 3 LINES 
				LET l_tot_per = (l_rec_statcust.net_amt / l_tot_net_amt) * 100 
				LET modu_accum_net = modu_accum_net + l_rec_statcust.net_amt 
				IF l_rec_statcust.gross_amt = 0 THEN 
					LET l_disc_per = 0 
				ELSE 
					LET l_disc_per = 100 * (1-(l_rec_statcust.net_amt/l_rec_statcust.gross_amt)) 
				END IF 
				PRINT COLUMN 01, l_rec_statcust.rank_no USING "###&", 
				COLUMN 07, l_rec_statcust.cust_code, 
				COLUMN 16, l_rec_statcust.name_text, 
				COLUMN 48, l_rec_statcust.gross_amt USING "---,---,--&", 
				COLUMN 61, l_rec_statcust.net_amt USING "---,---,--&", 
				COLUMN 74, l_tot_per USING "---&.&", 
				COLUMN 82, l_disc_per USING "---&.&", 
				COLUMN 90, modu_accum_net USING "---,---,--&" 
				PRINT COLUMN 16, l_rec_statcust.city_text 
			END FOREACH 
			
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
# END REPORT EV6_rpt_list()
###########################################################################