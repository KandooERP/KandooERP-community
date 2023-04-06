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
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GR_GROUP_GLOBALS.4gl"
GLOBALS "../gl/GRH_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
	DEFINE modu_arr_rec_exchangevar DYNAMIC ARRAY OF RECORD --array[50] OF RECORD 
		currency_code LIKE accountcur.currency_code, 
		desc_text LIKE currency.desc_text, 
		conv_qty LIKE rate_exchange.conv_sell_qty 
	END RECORD
	DEFINE modu_valid_currencies STRING #CHAR(350)
	DEFINE modu_currencies_list_str STRING #CHAR(350)


#	DEFINE modu_line1 CHAR(130)
#	DEFINE modu_line2 CHAR(130)
#DEFINE modu_line3 CHAR(130)
	
	DEFINE modu_grand_total DECIMAL(16,2)
	DEFINE modu_summ_potential DECIMAL(16,2)
	DEFINE modu_detl_potential DECIMAL(16,2)

	DEFINE modu_pv_date DATE
	DEFINE modu_year_num SMALLINT
	DEFINE modu_period_num SMALLINT
	DEFINE modu_rec_period RECORD LIKE period.*
	DEFINE modu_idx SMALLINT
	
############################################################
# FUNCTION GRH_main()
#
# GRH  l_potential Unrealised Exchange Rate Losses/Gains Report
############################################################
FUNCTION GRH_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRH") 


	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G204 with FORM "G204" 
			CALL windecoration_g("G204") 
		
			MENU " Unrealised Exchange" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRH","menu-unrealised-exchange") 
					CALL GRH_rpt_process(GRH_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Report" " SELECT Criteria AND Print Report"
					CALL GRH_rpt_process(GRH_rpt_query())
					CALL rpt_rmsreps_reset(NULL) 
		
				ON ACTION "Print Manager" 	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW G204

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRH_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G204 with FORM "G204" 
			CALL windecoration_g("G204") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRH_rpt_query()) #save where clause in env 
			CLOSE WINDOW G204 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRH_rpt_process(get_url_sel_text())
	END CASE 		
				 
END FUNCTION 


############################################################
# FUNCTION GRH_rpt_query()
#
#
############################################################
FUNCTION GRH_rpt_query() 
	DEFINE l_where_text STRING #dummy NULL=Exit
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_orig_curr_code LIKE currency.currency_code 
	DEFINE l_detl_ind CHAR(1) 
	DEFINE l_sum_ind CHAR(1)
	DEFINE l_fisc_year SMALLINT
	DEFINE l_per_num SMALLINT
	DEFINE l_i SMALLINT

	LET modu_detl_potential = 0 
	LET modu_summ_potential = 0 
	LET modu_grand_total = 0 

	IF glob_rec_glparms.use_currency_flag != "Y" THEN 
		#" l_foreign currency NOT in use"
		CALL fgl_winmessage("Currency Error",kandoomsg2("G",9504,""),"ERROR") 
		EXIT PROGRAM 
	END IF 

	#get period based on date
	LET modu_pv_date = today 
	LET l_detl_ind = "Y" 
	LET l_sum_ind = "N" 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) RETURNING l_fisc_year, l_per_num 
	CALL change_period(glob_rec_kandoouser.cmpy_code,l_fisc_year,l_per_num,-1) 
	RETURNING l_fisc_year, l_per_num 
	
	DISPLAY l_fisc_year,l_per_num TO year_num, period_num 
	LET modu_year_num = l_fisc_year 
	LET modu_period_num = l_per_num 

	INPUT l_detl_ind, l_sum_ind, modu_year_num, modu_period_num, modu_pv_date WITHOUT DEFAULTS
	FROM detl_ind, sum_ind,year_num,period_num, pv_date
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GRH","inp-detl-period") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD period_num 
			LET l_fisc_year = modu_year_num 
			LET l_per_num = modu_period_num 
			SELECT * INTO modu_rec_period.* FROM period 
			WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND period.year_num = l_fisc_year 
			AND period.period_num = l_per_num 
			IF status = NOTFOUND 
			THEN 
				ERROR kandoomsg2("U",3512,"") 
				NEXT FIELD pv_date --huho fix NEXT FIELD fisc_year 
			END IF 

	END INPUT 

	IF int_flag THEN 
		RETURN NULL
	END IF
	
	#" Enter currency details - Press ESC "
	MESSAGE kandoomsg2("G",3513,"") 
	#Get the corresponding currencies 1 to many - list is required as where string AND array list
	CALL modu_arr_rec_exchangevar.clear()
	INPUT ARRAY modu_arr_rec_exchangevar FROM sr_exchangevar.* attributes(UNBUFFERED, append row = true, insert row = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GRH","inp-arr-exchangevar") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield(currency_code) 
			LET modu_arr_rec_exchangevar[modu_idx].currency_code = show_curr(glob_rec_kandoouser.cmpy_code) 
			#DISPLAY modu_arr_rec_exchangevar[modu_idx].currency_code
			#   TO sr_exchangevar[scrn].currency_code
			NEXT FIELD currency_code 

		BEFORE ROW 
			LET modu_idx = arr_curr() 
			#LET scrn = scr_line()

		BEFORE FIELD currency_code 
			LET l_orig_curr_code = modu_arr_rec_exchangevar[modu_idx].currency_code 

		BEFORE FIELD conv_qty 
			FOR l_i = 1 TO arr_count() 
				IF l_i != modu_idx AND modu_arr_rec_exchangevar[modu_idx].currency_code 
				= modu_arr_rec_exchangevar[l_i].currency_code THEN 
					ERROR kandoomsg2("G",9506,"") 
					#9506 " Currency code has already been entered"
					NEXT FIELD currency_code 
				END IF 
			END FOR 
			SELECT desc_text 
			INTO modu_arr_rec_exchangevar[modu_idx].desc_text 
			FROM currency 
			WHERE currency_code = modu_arr_rec_exchangevar[modu_idx].currency_code 
			IF status = NOTFOUND THEN 
				#" Currency NOT found, try window"
				ERROR kandoomsg2("G",9505,"") 
				NEXT FIELD currency_code 
			ELSE 
				#DISPLAY modu_arr_rec_exchangevar[modu_idx].desc_text TO sr_exchangevar[scrn].desc_text

			END IF 
			IF modu_arr_rec_exchangevar[modu_idx].currency_code != l_orig_curr_code 
			OR modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL THEN 
				CALL get_conv_rate(
					glob_rec_kandoouser.cmpy_code, 
					modu_arr_rec_exchangevar[modu_idx].currency_code, 
					modu_pv_date, 
					CASH_EXCHANGE_SELL) 
				RETURNING modu_arr_rec_exchangevar[modu_idx].conv_qty 
				
				IF modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[modu_idx].conv_qty = "" THEN 
					LET modu_arr_rec_exchangevar[modu_idx].conv_qty = 0 
				END IF 
				#DISPLAY modu_arr_rec_exchangevar[modu_idx].conv_qty TO sr_exchangevar[scrn].conv_qty

				LET l_orig_curr_code = modu_arr_rec_exchangevar[modu_idx].currency_code 
			END IF 

		AFTER FIELD conv_qty 
			IF modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[modu_idx].conv_qty <= 0 THEN 
				#" Exchange Rate must have a value greater than zero"
				ERROR kandoomsg2("E",9061,"") 
				NEXT FIELD conv_qty 
			END IF
			
		AFTER ROW
			IF (modu_arr_rec_exchangevar.getSize() > 1) AND modu_arr_rec_exchangevar[modu_idx].currency_code IS NULL THEN
				CALL modu_arr_rec_exchangevar.delete(modu_idx)
			ELSE
				IF modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL 
				OR modu_arr_rec_exchangevar[modu_idx].conv_qty <= 0 THEN 
					#" Exchange Rate must have a value greater than zero"
					ERROR kandoomsg2("E",9061,"") 
					NEXT FIELD conv_qty  
				END IF
			END IF
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT PROGRAM 
			END IF 
			
			IF modu_arr_rec_exchangevar[1].currency_code IS NULL THEN 
				#"At least one currency code must be entered  -  try window"
				ERROR kandoomsg2("G",9507,"") 
				NEXT FIELD currency_code 
			END IF 
			IF modu_arr_rec_exchangevar[modu_idx].currency_code IS NOT NULL 
			OR modu_arr_rec_exchangevar[modu_idx].conv_qty IS NOT NULL THEN 
				FOR l_i = 1 TO arr_count() 
					IF l_i != modu_idx AND modu_arr_rec_exchangevar[modu_idx].currency_code 
					= modu_arr_rec_exchangevar[l_i].currency_code THEN 
						#" Currency code has already been entered"
						ERROR kandoomsg2("G",9506,"") 
						NEXT FIELD currency_code 
					END IF 
				END FOR 

				#get currency description text (name)
				SELECT desc_text 
				INTO modu_arr_rec_exchangevar[modu_idx].desc_text 
				FROM currency 
				WHERE currency_code = modu_arr_rec_exchangevar[modu_idx].currency_code 
				IF status = NOTFOUND THEN 
					#" Currency NOT found, try window"
					ERROR kandoomsg2("G",9505,"") 
					NEXT FIELD currency_code 
				ELSE 
					#DISPLAY modu_arr_rec_exchangevar[modu_idx].desc_text
					#     TO sr_exchangevar[scrn].desc_text
				END IF 
				
				IF modu_arr_rec_exchangevar[modu_idx].currency_code != l_orig_curr_code 
				OR modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL THEN 
					
					CALL get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						modu_arr_rec_exchangevar[modu_idx].currency_code, 
						modu_pv_date, 
						CASH_EXCHANGE_SELL) 
					RETURNING modu_arr_rec_exchangevar[modu_idx].conv_qty 
					
					IF modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[modu_idx].conv_qty = "" THEN 
						LET modu_arr_rec_exchangevar[modu_idx].conv_qty = 0 
					END IF 
					
					#DISPLAY modu_arr_rec_exchangevar[modu_idx].conv_qty
					#   TO sr_exchangevar[scrn].conv_qty

					LET l_orig_curr_code = modu_arr_rec_exchangevar[modu_idx].currency_code 
				END IF 
				IF modu_arr_rec_exchangevar[modu_idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[modu_idx].conv_qty <= 0 THEN 
					#" Exchange Rate must have a value"
					ERROR kandoomsg2("E",9061,"") 
					NEXT FIELD conv_qty 
				END IF 
			END IF 

	END INPUT 


	IF int_flag OR quit_flag THEN 
		RETURN NULL
	ELSE
		FOR l_i = 1 TO modu_arr_rec_exchangevar.getSize()
			 
			IF l_i = modu_arr_rec_exchangevar.getSize() THEN
				LET modu_currencies_list_str = modu_currencies_list_str, trim(modu_arr_rec_exchangevar[l_i].currency_code)
				LET modu_valid_currencies = modu_valid_currencies clipped, "\"", 
				modu_arr_rec_exchangevar[l_i].currency_code, "\"" 
			ELSE 
				LET modu_currencies_list_str = modu_currencies_list_str, trim(modu_arr_rec_exchangevar[l_i].currency_code), ","
				LET modu_valid_currencies = modu_valid_currencies clipped, "\"", 
				modu_arr_rec_exchangevar[l_i].currency_code, "\"," 
			END IF 
		END FOR 
	
		#LET modu_valid_currencies = "(", modu_valid_currencies clipped, ")" 

		LET glob_rec_rpt_selector.sel_option1 = modu_currencies_list_str
		LET glob_rec_rpt_selector.sel_option2 = modu_valid_currencies
		
		LET glob_rec_rpt_selector.ref1_ind = l_detl_ind
		LET glob_rec_rpt_selector.ref2_ind = l_sum_ind

		LET glob_rec_rpt_selector.ref1_num = l_fisc_year
		LET glob_rec_rpt_selector.ref2_num = l_per_num

		LET glob_rec_rpt_selector.ref4_num = modu_year_num
		LET glob_rec_rpt_selector.ref5_num = modu_period_num
		LET glob_rec_rpt_selector.ref1_date = modu_pv_date
		
		LET modu_valid_currencies = "(",trim(modu_valid_currencies),")" #used for 	" AND accounthistcur.currency_code in ", modu_valid_currencies clipped,
		RETURN modu_valid_currencies 	
	END IF 
END FUNCTION


############################################################
# FUNCTION GRH_rpt_process(p_where_text)
# p_where_text = dummy (NULL is exit)
#
############################################################
FUNCTION GRH_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING
	DEFINE l_report_code LIKE rmsreps.report_code 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_orig_curr_code LIKE currency.currency_code 
--	DEFINE modu_arr_rec_exchangevar DYNAMIC ARRAY OF RECORD --array[50] OF RECORD 
--		currency_code LIKE accountcur.currency_code, 
--		desc_text LIKE currency.desc_text, 
--		conv_qty LIKE rate_exchange.conv_sell_qty 
--	END RECORD
	DEFINE modu_valid_currencies STRING 
	DEFINE l_detl_ind CHAR(1) 
	DEFINE l_sum_ind CHAR(1)
	DEFINE l_fisc_year SMALLINT
	DEFINE l_per_num SMALLINT
	DEFINE l_i SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_st_obj base.StringTokenizer
	DEFINE l_rec_currency RECORD LIKE currency.*
	DEFINE l_currency_code LIKE currency.currency_code
	#DEFINE modu_currencies_list_str STRING #comma separated currency list
	DEFINE idx SMALLINT
		
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	#We need to query the URL/arguments for possible report code (background process)
	LET l_report_code = get_url_report_code()
	IF (l_report_code IS NOT NULL) AND (l_report_code != 0) THEN 
		LET l_detl_ind = db_rmsreps_get_ref1_ind(UI_OFF,l_report_code)
		LET l_sum_ind = db_rmsreps_get_ref2_ind(UI_OFF,l_report_code)
	ELSE
		LET l_detl_ind = glob_rec_rpt_selector.ref1_ind
		LET l_sum_ind = glob_rec_rpt_selector.ref2_ind 
	END IF

	#DETAILED REPORT
	IF l_detl_ind = "Y" THEN 
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("GRH-D","GRH_rpt_list_detail",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRH_rpt_list_detail TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRH_rpt_list_detail")].sel_text
		#------------------------------------------------------------
	END IF 

	#Summary Report
	IF l_sum_ind = "Y" THEN 
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("GRH-S","GRH_rpt_list_summary",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRH_rpt_list_summary TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRH_rpt_list_summary")].sel_text
		#------------------------------------------------------------
		
	END IF 

	#------------------------------------------------------------
	LET modu_valid_currencies = p_where_text #special case

	#get selectors from remsreps

	LET l_detl_ind = glob_arr_rec_rpt_rmsreps[1].ref1_ind
	LET l_sum_ind = glob_arr_rec_rpt_rmsreps[1].ref2_ind	

	LET l_fisc_year = glob_arr_rec_rpt_rmsreps[1].ref1_num
	LET l_per_num = glob_arr_rec_rpt_rmsreps[1].ref2_num

	IF (l_report_code IS NOT NULL) AND (l_report_code != 0) THEN
		LET modu_valid_currencies = glob_arr_rec_rpt_rmsreps[1].sel_option2
		LET modu_year_num = glob_arr_rec_rpt_rmsreps[1].ref4_num
		LET modu_period_num = glob_arr_rec_rpt_rmsreps[1].ref5_num
		LET modu_pv_date = glob_arr_rec_rpt_rmsreps[1].ref1_date
		LET modu_currencies_list_str = glob_arr_rec_rpt_rmsreps[1].sel_option1 
			
		LET l_st_obj = base.StringTokenizer.Create(modu_currencies_list_str, ",")
		LET idx = 0
		WHILE l_st_obj.hasMoreTokens()
			LET idx = idx+1
			#LET l_currency_code = l_st_obj.nextToken()
			
			#Code
			CALL db_currency_get_rec(l_st_obj.nextToken()) RETURNING l_rec_currency.*
			
			#Text
			LET modu_arr_rec_exchangevar[idx].desc_text = l_rec_currency.desc_text
			
			#Exchange Rate / Factor based on date and currency
			CALL get_conv_rate(
				glob_rec_kandoouser.cmpy_code,	
				l_rec_currency.currency_code, 
				modu_pv_date, 
				CASH_EXCHANGE_SELL) 
			RETURNING modu_arr_rec_exchangevar[idx].conv_qty 
			
			IF modu_arr_rec_exchangevar[idx].conv_qty IS NULL OR modu_arr_rec_exchangevar[idx].conv_qty = "" THEN 
				LET modu_arr_rec_exchangevar[modu_idx].conv_qty = 0 
			END IF 
			
		END WHILE
	
	
		END IF
	
	#------------------------------------------------------------
		
	LET l_query_text = 
	" SELECT accounthistcur.* ", 
	" FROM accounthistcur, coa ", 
	" WHERE accounthistcur.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\"", 
	" AND accounthistcur.year_num = ", l_fisc_year, 
	" AND accounthistcur.period_num = ", l_per_num , 
	" AND coa.acct_code = accounthistcur.acct_code", 
	" AND coa.cmpy_code = accounthistcur.cmpy_code", 
	" AND coa.type_ind in (\"A\",\"L\")", 
	" AND accounthistcur.currency_code != \"", 
	glob_rec_glparms.base_currency_code, "\"", 
	" AND accounthistcur.currency_code in ", modu_valid_currencies clipped, 
	" ORDER BY accounthistcur.currency_code,accounthistcur.acct_code" 

	PREPARE acctset FROM l_query_text 
	DECLARE acctcurr CURSOR FOR acctset 

	FOREACH acctcurr INTO l_rec_accounthistcur.* 

		#DISPLAY " Account: ", l_rec_accounthistcur.acct_code TO lbLabel1  -- 1,10
		MESSAGE "Account: ", l_rec_accounthistcur.acct_code 
		FOR l_i = 1 TO arr_count() 
			IF modu_arr_rec_exchangevar[l_i].currency_code = l_rec_accounthistcur.currency_code THEN 
				LET modu_idx = l_i 
				EXIT FOR 
			END IF 
		END FOR 
		IF l_detl_ind = "Y" THEN #DETAILED REPORT
			#---------------------------------------------------------
			OUTPUT TO REPORT GRH_rpt_list_detail(l_rpt_idx,l_rec_accounthistcur.*, modu_arr_rec_exchangevar[modu_idx].*) 
			IF NOT rpt_int_flag_handler2("GL-Account:",l_rec_accounthistcur.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------
		END IF 

		IF l_sum_ind = "Y" THEN #SUMMARAY REPORT
			#---------------------------------------------------------
			OUTPUT TO REPORT GRH_rpt_list_summary(l_rpt_idx,l_rec_accounthistcur.*, modu_arr_rec_exchangevar[modu_idx].*)  
			IF NOT rpt_int_flag_handler2("GL-Account:",l_rec_accounthistcur.acct_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END IF 
	END FOREACH 

	IF l_detl_ind = "Y" THEN 
		#------------------------------------------------------------
		FINISH REPORT GRH_rpt_list_detail
		CALL rpt_finish("GRH_rpt_list_detail")
		#------------------------------------------------------------	
	END IF 

	IF l_sum_ind = "Y" THEN 
		#------------------------------------------------------------
		FINISH REPORT GRH_rpt_list_summary
		CALL rpt_finish("GRH_rpt_list_summary")
		#------------------------------------------------------------	
	END IF 

END FUNCTION 


############################################################
# REPORT GRH_rpt_list_detail(p_rec_accounthistcur, p_rec_exchangevar)  
#
#
############################################################
REPORT GRH_rpt_list_detail(p_rpt_idx,p_rec_accounthistcur, p_rec_exchangevar) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE p_rec_exchangevar RECORD 
		currency_code LIKE accountcur.currency_code, 
		desc_text LIKE currency.desc_text, 
		conv_qty LIKE rate_exchange.conv_sell_qty 
	END RECORD 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_foreign CHAR(20) 
	DEFINE l_base CHAR(20)
	DEFINE l_potential CHAR(20)
	DEFINE l_variance CHAR(20)			
	DEFINE l_potential_amt DECIMAL(16,2) 
	DEFINE l_variance_amt DECIMAL(16,2) 
	
	OUTPUT 
	left margin 0 
	ORDER BY p_rec_accounthistcur.currency_code, p_rec_accounthistcur.acct_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 01, "Potential Unrealised Exchange Rate Losses/Gains"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Account", 
			COLUMN 21, "Description", 
			COLUMN 53, "Currency", 
			COLUMN 75, "Current", 
			COLUMN 97, "l_potential" 
			PRINT COLUMN 1, "Number", 
			COLUMN 53, "Balances", 
			COLUMN 75, "l_base Value", 
			COLUMN 97, "l_base Value", 
			COLUMN 121, "l_variance" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Period selected : ", modu_year_num, "/" , 
			modu_period_num USING "<<<<<" 
			SKIP 1 line 

		ON EVERY ROW 
			SELECT * 
			INTO l_rec_coa.* 
			FROM coa 
			WHERE coa.acct_code = p_rec_accounthistcur.acct_code 
			AND coa.cmpy_code = p_rec_accounthistcur.cmpy_code 
			LET l_foreign = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthistcur.close_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_base = ac_form(glob_rec_kandoouser.cmpy_code, p_rec_accounthistcur.base_close_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_potential_amt = p_rec_accounthistcur.close_amt/p_rec_exchangevar.conv_qty 
			LET l_variance_amt = l_potential_amt - p_rec_accounthistcur.base_close_amt 
			LET l_potential = ac_form(glob_rec_kandoouser.cmpy_code, l_potential_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_variance = ac_form(glob_rec_kandoouser.cmpy_code, l_variance_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET modu_detl_potential = modu_detl_potential + l_potential_amt 
			PRINT COLUMN 1, p_rec_accounthistcur.acct_code , 
			COLUMN 21, l_rec_coa.desc_text[1,23], 
			COLUMN 46, l_foreign, 
			COLUMN 68, l_base, 
			COLUMN 90, l_potential, 
			COLUMN 112, l_variance 
			LET l_rec_coa.desc_text = NULL 

		BEFORE GROUP OF p_rec_accounthistcur.currency_code 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Currency: ", 
			COLUMN 11, p_rec_exchangevar.currency_code, 
			COLUMN 16, p_rec_exchangevar.desc_text 
			PRINT COLUMN 1, "Exchange Rate Used: ", 
			COLUMN 21, p_rec_exchangevar.conv_qty USING "####&.&&&&" 
			SKIP 1 line 

		AFTER GROUP OF p_rec_accounthistcur.currency_code 
			SKIP 1 line 
			LET l_foreign = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.close_amt), 	l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			
			LET l_base = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.base_close_amt), l_rec_coa.type_ind, glob_rec_glparms.style_ind)
			 
			LET l_variance_amt = modu_detl_potential - GROUP sum(p_rec_accounthistcur.base_close_amt) 
			LET l_potential = ac_form(glob_rec_kandoouser.cmpy_code, modu_detl_potential,	l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_variance = ac_form(glob_rec_kandoouser.cmpy_code, l_variance_amt,	l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET modu_detl_potential = 0
			 
			PRINT COLUMN 1, "Totals FOR ", 
			COLUMN 12, p_rec_exchangevar.currency_code, 
			COLUMN 16, "currency", 
			COLUMN 46, l_foreign, 
			COLUMN 68, l_base, 
			COLUMN 90, l_potential, 
			COLUMN 112, l_variance 

		ON LAST ROW 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 


END REPORT 


############################################################
# REPORT GRH_rpt_list_summary(p_rpt_idx,p_rec_accounthistcur, p_rec_exchangevar)   
#
#
############################################################
REPORT GRH_rpt_list_summary(p_rpt_idx,p_rec_accounthistcur, p_rec_exchangevar) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE p_rec_exchangevar RECORD 
		currency_code LIKE accountcur.currency_code, 
		desc_text LIKE currency.desc_text, 
		conv_qty LIKE rate_exchange.conv_sell_qty 
	END RECORD 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_foreign CHAR(20)
	DEFINE l_base CHAR(20)
	DEFINE l_potential CHAR(20)
	DEFINE l_variance CHAR(20)
	 
	DEFINE l_potential_amt, l_variance_amt DECIMAL(16,2) 

	OUTPUT 
--	left margin 0 
	ORDER BY p_rec_accounthistcur.currency_code, p_rec_accounthistcur.acct_code 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2]
			PRINT COLUMN 01, "Potential Unrealised Exchange Rate Losses/Gains"
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Currency", 
			COLUMN 35, "Exchange", 
			COLUMN 53, "Currency", 
			COLUMN 75, "Current", 
			COLUMN 97, "l_potential" 
			PRINT COLUMN 1, "Code", 
			COLUMN 7, "Description", 
			COLUMN 35, "Rate Used", 
			COLUMN 53, "Balances", 
			COLUMN 75, "l_base Value", 
			COLUMN 97, "l_base Value", 
			COLUMN 121, "l_variance" 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1, "Period selected : ", modu_year_num, "/" , 
			modu_period_num USING "<<<<<" 
			SKIP 1 line 

		ON EVERY ROW 
			LET l_potential_amt = p_rec_accounthistcur.close_amt/p_rec_exchangevar.conv_qty 
			LET modu_summ_potential = modu_summ_potential + l_potential_amt 

		AFTER GROUP OF p_rec_accounthistcur.currency_code 
			LET l_foreign = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.close_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_base = ac_form(glob_rec_kandoouser.cmpy_code, 
			GROUP sum(p_rec_accounthistcur.base_close_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_variance_amt = modu_summ_potential - GROUP sum(p_rec_accounthistcur.base_close_amt) 
			LET l_potential = ac_form(glob_rec_kandoouser.cmpy_code, modu_summ_potential, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_variance = ac_form(glob_rec_kandoouser.cmpy_code, l_variance_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET modu_grand_total = modu_grand_total + modu_summ_potential 
			LET modu_summ_potential = 0 
			PRINT COLUMN 2, p_rec_exchangevar.currency_code, 
			COLUMN 7, p_rec_exchangevar.desc_text, 
			COLUMN 35, p_rec_exchangevar.conv_qty USING "####&.&&&&", 
			COLUMN 46, l_foreign, 
			COLUMN 68, l_base, 
			COLUMN 90, l_potential, 
			COLUMN 112, l_variance 

		ON LAST ROW 
			SKIP 1 line 
			LET l_base = ac_form(glob_rec_kandoouser.cmpy_code, sum(p_rec_accounthistcur.base_close_amt), 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_potential = ac_form(glob_rec_kandoouser.cmpy_code, modu_grand_total, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			LET l_variance_amt = modu_grand_total - sum(p_rec_accounthistcur.base_close_amt) 
			LET l_variance = ac_form(glob_rec_kandoouser.cmpy_code, l_variance_amt, 
			l_rec_coa.type_ind, glob_rec_glparms.style_ind) 
			PRINT COLUMN 1, "Grand Total", 
			COLUMN 68, l_base, 
			COLUMN 90, l_potential, 
			COLUMN 112, l_variance 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 

END REPORT