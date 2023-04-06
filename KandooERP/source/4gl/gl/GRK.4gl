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
GLOBALS "../gl/GRK_GLOBALS.4gl" 
############################################################
# MODULEL Scope Variables
############################################################
DEFINE modu_rec_structure RECORD LIKE structure.* 
DEFINE modu_rec_consoldetl RECORD LIKE consoldetl.* 
############################################################
# FUNCTION GRK_main()
#
# GRK Consolidated Summary Trial Balance  -  (Clone GRG)
############################################################
FUNCTION GRK_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRK") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode
			OPEN WINDOW G457 with FORM "G457" 
			CALL windecoration_g("G457") 
		
			SELECT * INTO modu_rec_structure.* FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_ind = "L" 
			IF status = NOTFOUND THEN 
				CALL fgl_winmessage("Ledger Segments",kandoomsg2("G",5019,""),"ERROR") #5019 Ledger Segments Not Set Up
				EXIT PROGRAM 
			END IF 
		
			MENU " Consol Summary Trial Balance" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GRK","menu-consol-summar-trial-balance") 
					CALL GRK_rpt_process(GRK_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 	#COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL GRK_rpt_process(GRK_rpt_query()) 
					CALL rpt_rmsreps_reset(NULL)
		
				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "Exit" 	#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
			END MENU 
		
			CLOSE WINDOW G457 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GRK_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G146 with FORM "G146" 
			CALL windecoration_g("G146") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GRK_rpt_query()) #save where clause in env 
			CLOSE WINDOW G146 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GRK_rpt_process(get_url_sel_text())
	END CASE 		
END FUNCTION 


############################################################
# FUNCTION GRK_rpt_query()
#
#
############################################################
FUNCTION GRK_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_where2_text STRING
	
	MESSAGE kandoomsg2("U",1001,"")
	#1001 " Enter Selection Criteria - ESC TO Continue
	LET glob_totals_ind = "Y" 
	LET glob_timing_ind = "A" 
	LET glob_zero_ind = "Y" 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING glob_rec_period.year_num, 
	glob_rec_period.period_num 

	WHILE true 

		# INPUT --------------------------------------
		INPUT glob_totals_ind, 
		glob_timing_ind, 
		glob_zero_ind, 
		glob_rec_period.year_num, 
		glob_rec_period.period_num, 
		glob_rec_currency.currency_code WITHOUT DEFAULTS 
		FROM 
		totals_ind, 
		timing_ind, 
		zero_ind, 
		year_num, 
		period_num, 
		currency_code 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GRK","inp-totals-period") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 

					SELECT * INTO glob_rec_period.* FROM period 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = glob_rec_period.year_num 
					AND period_num = glob_rec_period.period_num 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("U",3512,"")#3512 " Year & Period Not Found"
						NEXT FIELD year_num 
					END IF 

					IF glob_rec_currency.currency_code IS NOT NULL THEN 
						SELECT * INTO glob_rec_currency.* FROM currency 
						WHERE currency_code = glob_rec_currency.currency_code 
						IF status = NOTFOUND THEN 
							ERROR kandoomsg2("G",9503,"")		#9503 " Currency code NOT found    "
							NEXT FIELD currency_code 
						END IF 
					END IF 

				END IF 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		#CONSRUCT ------------------------------------------
		CONSTRUCT BY NAME l_where_text ON consol_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GRK","construct-consol") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 

		IF glob_rec_currency.currency_code IS NULL THEN 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"account") 
			RETURNING l_where2_text 
		ELSE 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"accountcur") 
			RETURNING l_where2_text 
		END IF 

		IF l_where2_text IS NULL THEN 
			CONTINUE WHILE 
		ELSE 
			LET glob_rept_curr_code = glob_rec_glparms.base_currency_code 
			LET glob_conv_qty = 1.0 
			EXIT WHILE
		END IF 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		RETURN NULL 
	ELSE 
		LET glob_rec_rpt_selector.sel_option1 = l_where2_text
		LET glob_rec_rpt_selector.ref1_ind = glob_totals_ind
		LET glob_rec_rpt_selector.ref2_ind = glob_timing_ind
		LET glob_rec_rpt_selector.ref3_ind = glob_zero_ind
		LET glob_rec_rpt_selector.ref1_num = glob_rec_period.year_num
		LET glob_rec_rpt_selector.ref2_num = glob_rec_period.period_num
		LET glob_rec_rpt_selector.ref1_code  = glob_rec_currency.currency_code
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION GRK_rpt_process()
#
#
############################################################
FUNCTION GRK_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_where2_text STRING
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_query_text STRING  
	DEFINE l_start_num SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_range CHAR(200) 
	#DEFINE l_report_code LIKE rmsreps.report_code




	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND ((get_url_report_code() IS NULL OR get_url_report_code() = 0) OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	IF get_url_report_code() != 0 THEN
		LET glob_rec_currency.currency_code = db_rmsreps_get_ref1_code(UI_OFF,get_url_report_code())
	ELSE
		LET glob_rec_currency.currency_code = glob_rec_rpt_selector.ref1_code
	END IF

	#GRK_rpt_list_a_sc SINGLE CURRENCY
	IF glob_rec_currency.currency_code IS NULL THEN 
		LET l_rpt_idx = rpt_start("GRK-SC","GRK_rpt_list_a_sc",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRK_rpt_list_a_sc TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc")].sel_text
	ELSE
	#GRK_rpt_process_5_b_mc Multi CURRENCY
		LET l_rpt_idx = rpt_start("GRK-MC","GRK_rpt_list_b_mc",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT GRK_rpt_list_b_mc TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("GRK_rpt_list_b_mc")].sel_text
	
	END IF
	#------------------------------------------------------------
	#Get selector data from rmsreps (in case of background process)
		LET l_where2_text = glob_arr_rec_rpt_rmsreps[1].sel_option1 
		LET glob_totals_ind = glob_arr_rec_rpt_rmsreps[1].ref1_ind 
		LET glob_timing_ind = glob_arr_rec_rpt_rmsreps[1].ref2_ind 
		LET glob_zero_ind = glob_arr_rec_rpt_rmsreps[1].ref3_ind
		LET glob_rec_period.year_num = glob_arr_rec_rpt_rmsreps[1].ref1_num 
		LET glob_rec_period.period_num = glob_arr_rec_rpt_rmsreps[1].ref2_num
		LET glob_rec_currency.currency_code = glob_arr_rec_rpt_rmsreps[1].ref1_code 
	#------------------------------------------------------------

	SELECT * INTO modu_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_ind = "L" 
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("Ledger Segments",kandoomsg2("G",5019,""),"ERROR") #5019 Ledger Segments Not Set Up
		EXIT PROGRAM 
	END IF 

	LET l_start_num = modu_rec_structure.start_num 
	LET l_length = modu_rec_structure.start_num + modu_rec_structure.length_num	- 1
	 
	CASE 
		WHEN glob_totals_ind = "Y" 
			AND glob_timing_ind = "P"
			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Preclose") 			 
		WHEN glob_totals_ind = "Y" 
			AND glob_timing_ind = "A"
 			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Year TO Date Actuals") 			 
		WHEN glob_totals_ind = "P" 
			AND glob_timing_ind = "P"
			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Preclose") 			 
		WHEN glob_totals_ind = "P" 
			AND glob_timing_ind = "A"
			CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, " - Period TO Date Actuals") 			 
	END CASE 


	LET l_query_text = "SELECT * FROM consolhead ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",glob_arr_rec_rpt_rmsreps[1].sel_text clipped," ", 
	"ORDER BY 2" 
	PREPARE s_consolhead FROM l_query_text 
	DECLARE c_consolhead CURSOR FOR s_consolhead
	 
	LET l_query_text = "SELECT * FROM consoldetl ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND consol_code = ? " 

	PREPARE s_consoldetl FROM l_query_text 
	DECLARE c_consoldetl CURSOR FOR s_consoldetl 

	FOREACH c_consolhead INTO glob_rec_consolhead.* 
		OPEN c_consoldetl USING glob_rec_consolhead.consol_code 
		LET l_range = NULL 
		FOREACH c_consoldetl INTO modu_rec_consoldetl.* 
			IF l_range IS NULL THEN 
				LET l_range = "('", modu_rec_consoldetl.flex_code clipped, "'" 
			ELSE 
				LET l_range = l_range clipped, ",'", 
				modu_rec_consoldetl.flex_code clipped, "'" 
			END IF 
		END FOREACH 

		LET l_range = l_range clipped, ")" 
		
		IF glob_rec_currency.currency_code IS NULL THEN 
			LET l_query_text = 
			"SELECT * FROM account ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND year_num = '",glob_rec_period.year_num,"' ", 
			"AND acct_code[",l_start_num USING "&&",",", 
			l_length USING "&&","] in ",l_range clipped," ", 
			l_where2_text clipped," ", 
			"ORDER BY cmpy_code,chart_code" 
		ELSE 
			LET l_query_text = 
			"SELECT * FROM accountcur ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND year_num = '",glob_rec_period.year_num,"' ", 
			"AND acct_code[",l_start_num USING "&&",",", 
			l_length USING "&&","] in ",l_range clipped," ", 
			"AND currency_code = '",glob_rec_currency.currency_code,"' ", 
			l_where2_text clipped," ", 
			"ORDER BY cmpy_code,currency_code,chart_code" 
		END IF 
		#
		IF glob_rec_currency.currency_code IS NULL THEN #Single currency 
			CASE 
				WHEN glob_totals_ind = "Y" ## ytd/preclose 
					AND glob_timing_ind = "P" 
					CALL GRK_rpt_process_1_a_sc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text)  
				WHEN glob_totals_ind = "Y" ## ytd/actuals
					AND glob_timing_ind = "A" 
					CALL GRK_rpt_process_2_a_sc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text)  
				WHEN glob_totals_ind = "P" ## ptd/preclose 
					AND glob_timing_ind = "P" 
					CALL GRK_rpt_process_3_a_sc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text) 
				WHEN glob_totals_ind = "P" ## ptd/actuals
					AND glob_timing_ind = "A" 
					CALL GRK_rpt_process_4_a_sc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text)  
			END CASE 
		ELSE #Multi Currency
			CASE 
				WHEN glob_totals_ind = "Y" ## ytd/preclose 
					AND glob_timing_ind = "P" 
					CALL GRK_rpt_process_1_b_mc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text) 
				WHEN glob_totals_ind = "Y" ## ytd/actuals 
					AND glob_timing_ind = "A" 
					CALL GRK_rpt_process_2_b_mc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text) 
				WHEN glob_totals_ind = "P" ## ptd/preclose
					AND glob_timing_ind = "P" 
					CALL GRK_rpt_process_3_b_mc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text)  
				WHEN glob_totals_ind = "P" ## ptd/actuals
					AND glob_timing_ind = "A" 
					CALL GRK_rpt_process_4_b_mc(rpt_rmsreps_idx_get_idx("GRK_rpt_list_a_sc"),l_query_text)  
			END CASE 
		END IF 
	END FOREACH 

	IF glob_rec_currency.currency_code IS NULL THEN 
		#------------------------------------------------------------
		FINISH REPORT GRK_rpt_list_a_sc
		CALL rpt_finish("GRK_rpt_list_a_sc")
		#------------------------------------------------------------
	ELSE 
		#------------------------------------------------------------
		FINISH REPORT GRK_rpt_list_b_mc
		CALL rpt_finish("GRK_rpt_list_b_mc")
		#------------------------------------------------------------
	END IF 
END FUNCTION 
