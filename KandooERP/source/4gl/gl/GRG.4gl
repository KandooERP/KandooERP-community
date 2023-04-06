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
#Thsi file IS used FROM GRGa.4gl as GLOBALS file
#GLOBALS "../common/glob_GLOBALS.4gl"
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRG_GLOBALS.4gl"  
############################################################
# FUNCTION GRG_main()
#
# Summary Trial Balance
# 2 Reports
# 1 query
# 4 report data driver for each report (8 in total)
############################################################
FUNCTION GRG_main() 
--	DEFINE l_where_text STRING
	
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRG") 
	CALL rpt_rmsreps_reset(NULL)
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G213 with FORM "G213" 
			CALL windecoration_g("G213") 
			#CALL displaymoduletitle(NULL) #Initial Main Window get's application title
		
			MENU " Trial Balance Report" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRG","menu-trial-balance-REPORT") 
					--CALL rpt_rmsreps_reset(NULL)
					CALL GRG_rpt_process(GRG_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 		#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL GRG_rpt_process(GRG_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G213 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRG_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G213 with FORM "G213" 
			CALL windecoration_g("G213") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRG_rpt_query()) #save where clause in env 
			CLOSE WINDOW G213 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRG_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
############################################################
# FUNCTION GRG_rpt_query()
#
#
############################################################
FUNCTION GRG_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_rec_currency RECORD LIKE currency.*	
	DEFINE l_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE l_totals_ind CHAR(1) 
	DEFINE l_timing_ind CHAR(1) 
	DEFINE l_zero_ind CHAR(1) 
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency
	
	CLEAR FORM 
	LET l_totals_ind = "Y" 
	LET l_timing_ind = "A" 
	LET l_zero_ind = "Y"
	 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING l_rec_period.year_num,l_rec_period.period_num 

	INPUT l_totals_ind, 
	l_timing_ind, 
	l_zero_ind, 
	l_rec_period.year_num, 
	l_rec_period.period_num, 
	l_rec_currency.currency_code 
	WITHOUT DEFAULTS 
	FROM totals_ind, 
	timing_ind, 
	zero_ind, 
	year_num, 
	period_num, 
	currency_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RG","inp-totals") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT * INTO l_rec_period.* 
				FROM period 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND year_num = l_rec_period.year_num 
				AND period_num = l_rec_period.period_num 
				IF status = NOTFOUND THEN 
					#" Year & Period Not Found"
					ERROR kandoomsg2("U",3512,"") 
					NEXT FIELD year_num 
				END IF
				 
				IF l_rec_currency.currency_code IS NOT NULL THEN 
					SELECT * INTO l_rec_currency.* 
					FROM currency 
					WHERE currency_code = l_rec_currency.currency_code 
					IF status = NOTFOUND THEN 
						#" Currency code NOT found    "
						ERROR kandoomsg2("G",9503,"") 
						NEXT FIELD currency_code 
					END IF 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--        CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE 
		IF l_rec_currency.currency_code IS NULL THEN 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"account") 
			RETURNING l_where_text 
		ELSE 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"accountcur") 
			RETURNING l_where_text 
		END IF 

		# add multi_currency bit
		LET l_rept_curr_code = glob_rec_glparms.base_currency_code 
		LET l_conv_qty = 1.0 

{

	
		#with currency code	
		IF glob_rec_currency.currency_code IS NULL THEN 
			LET l_query_text = "SELECT * ", 
			"FROM account ", 
			"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
			"AND year_num = \"",l_rec_period.year_num,"\" ", 
			l_where_text clipped," ", 
			"ORDER BY cmpy_code,", 
			"chart_code" 
		ELSE #without multi-currency code
			LET l_query_text = "SELECT * ", 
			"FROM accountcur ", 
			"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
			"AND year_num = \"",l_rec_period.year_num,"\" ", 
			"AND currency_code = \"",glob_rec_currency.currency_code,"\" ", 
			l_where_text clipped," ", 
			"ORDER BY cmpy_code,", 
			"currency_code,", 
			"chart_code" 
		END IF 
}


		LET glob_rec_rpt_selector.ref1_num = l_rec_period.year_num		
		LET glob_rec_rpt_selector.ref2_num = l_rec_period.period_num		
		LET glob_rec_rpt_selector.ref1_code = l_rept_curr_code		#base currency
		LET glob_rec_rpt_selector.ref2_code = l_rec_currency.currency_code #can not follow why we have 2 currency codes		
		LET glob_rec_rpt_selector.ref1_factor = l_conv_qty
		
		LET glob_rec_rpt_selector.ref1_ind = l_totals_ind
		LET glob_rec_rpt_selector.ref2_ind = l_timing_ind
		LET glob_rec_rpt_selector.ref3_ind = l_zero_ind
		RETURN l_where_text 
	END IF
	 
END FUNCTION 


############################################################
# FUNCTION GRG_rpt_process(p_where_text)
#
#
############################################################
FUNCTION GRG_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
#	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING 
	DEFINE l_conv_qty LIKE rate_exchange.conv_sell_qty
	DEFINE l_timing_ind CHAR(1) 
	DEFINE l_totals_ind CHAR(1)
	DEFINE l_rec_period RECORD LIKE period.*
	DEFINE l_rept_curr_code LIKE currency.currency_code #base currency
	DEFINE l_currency_code LIKE currency.currency_code
		
	# add multi_currency bit
	LET l_rept_curr_code = glob_rec_glparms.base_currency_code 
	LET l_conv_qty = 1.0 
	LET l_currency_code = glob_rec_rpt_selector.ref2_code #can not follow why we have 2 currency codes

	
	IF l_currency_code IS NULL THEN 

		#------------------------------------------------------------
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"GRG_rpt_list_A",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRG_rpt_list_A TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].sel_text
		#------------------------------------------------------------


		LET l_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_num
		LET l_rec_period.period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_num
#		LET glob_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_num
#		LET glob_rec_period.period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_num
				
		LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_code	#can not follow why we have 2 currency codes
		#LET l_currency_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_code #can not follow why we have 2 currency codes
		LET l_currency_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_code #can not follow why we have 2 currency codes
				
#		LET l_conv_qty = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_factor
		LET l_conv_qty = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_factor 
#		LET glob_timing_ind = glob_rec_rpt_selector.ref1_ind

		LET l_totals_ind = glob_rec_rpt_selector.ref1_ind
--		LET glob_totals_ind = glob_rec_rpt_selector.ref1_ind
		LET l_timing_ind = glob_rec_rpt_selector.ref2_ind
--		LET glob_timing_ind = glob_rec_rpt_selector.ref2_ind

		#without currency codeIF glob_rec_currency.currency_code IS NULL THEN 
		LET l_query_text = "SELECT * ", 
		"FROM account ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND year_num = \"",l_rec_period.year_num,"\" ", 
		p_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"chart_code" 
	
		CASE 
			WHEN l_totals_ind = "Y" ## ytd/preclose
				AND l_timing_ind = "P"
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Preclose") 
				CALL GRG_rpt_process_a1(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)  
			
			WHEN l_totals_ind = "Y" ## ytd/actuals 
				AND l_timing_ind = "A" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Actuals")
				CALL GRG_rpt_process_a2(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)  
			
			WHEN l_totals_ind = "P" ## ptd/preclose
				AND l_timing_ind = "P" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Preclose")
				CALL GRG_rpt_process_a3(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)    
			
			WHEN l_totals_ind = "P" ## ptd/actuals 
				AND l_timing_ind = "A" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Actuals")
				CALL GRG_rpt_process_a4(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)  
		END CASE
			
		#------------------------------------------------------------
		FINISH REPORT GRG_rpt_list_A
		CALL rpt_finish("GRG_rpt_list_A")
		#------------------------------------------------------------
				
		IF int_flag THEN
			MESSAGE "Report Generation Canceled..."
			RETURN FALSE
		ELSE
			RETURN TRUE
		END IF 	
						


	#with currency code	
	ELSE #with multi-currency code

		#------------------------------------------------------------
	
		LET l_rpt_idx = rpt_start(getmoduleid(),"GRG_rpt_list_A",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRG_rpt_list_A TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].sel_text
		#------------------------------------------------------------
		# data from rmsreps

		LET l_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_num
		LET l_rec_period.period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_num
#		LET glob_rec_period.year_num	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_num
#		LET glob_rec_period.period_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_num
				
		LET l_rept_curr_code	 = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_code	#can not follow why we have 2 currency codes
		#LET l_currency_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_code #can not follow why we have 2 currency codes
		LET l_currency_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref2_code #can not follow why we have 2 currency codes
		
#		LET glob_conv_qty = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_factor
		LET l_conv_qty = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRG_rpt_list_A")].ref1_factor 
--		LET glob_timing_ind = glob_rec_rpt_selector.ref1_ind

		LET l_totals_ind = glob_rec_rpt_selector.ref1_ind
--		LET glob_totals_ind = glob_rec_rpt_selector.ref1_ind
		LET l_timing_ind = glob_rec_rpt_selector.ref2_ind
--		LET glob_timing_ind = glob_rec_rpt_selector.ref2_ind
		#------------------------------------------------------------
		
		LET l_query_text = "SELECT * ", 
		"FROM accountcur ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND year_num = \"",l_rec_period.year_num,"\" ", 
		"AND currency_code = \"",l_currency_code,"\" ", 
		p_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"currency_code,", 
		"chart_code" 
						 
		CASE 
			WHEN l_totals_ind = "Y" ## ytd/preclose
				AND l_timing_ind = "P" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Preclose") 
				CALL GRG_rpt_process_b1(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)
				    
			WHEN l_totals_ind = "Y" ## ytd/actuals 
				AND l_timing_ind = "A" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Actuals") 
				CALL GRG_rpt_process_b2(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)
				 
			WHEN l_totals_ind = "P"  ## ptd/preclose 
				AND l_timing_ind = "P" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Preclose") 
				CALL GRG_rpt_process_b3(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)
				
			WHEN l_totals_ind = "P" ## ptd/actuals  
				AND l_timing_ind = "A" 
				CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Actuals") 
				CALL GRG_rpt_process_b4(l_rpt_idx,l_query_text,l_conv_qty,l_rec_period.*)
		END CASE 
	END IF 


END FUNCTION	

