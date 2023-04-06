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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
-- GLOBALS 
-- 	DEFINE glob_temp_start_num LIKE cheque.cheq_code --ref1_num
-- 	DEFINE glob_temp_end_num LIKE cheque.cheq_code --ref2_num
-- 	DEFINE glob_temp_bank_code LIKE bank.bank_code --ref1_code
-- END GLOBALS 
############################################################
# FUNCTION PCH_main()
# RETURN VOID
#
# PCH - Missing Cheque Numbers Report
############################################################
FUNCTION PCH_main()

	CALL setModuleId("PCH") 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode
				
			OPEN WINDOW P161 with FORM "P161" 
			CALL windecoration_p("P161") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Missing Cheque Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PCH","menu-missing_cheque-1") 
					CALL PCH_rpt_process(PCH_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run" " SELECT criteria AND PRINT REPORT"
					CALL PCH_rpt_process(PCH_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P161 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PCH_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P161 with FORM "P161" 
			CALL windecoration_p("P161") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PCH_rpt_query()
			CALL set_url_sel_text(PCH_rpt_query()) #save where clause in env 
			CLOSE WINDOW P161

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PCH_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PCH_main()
############################################################


############################################################
# FUNCTION PCH_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PCH_rpt_query() 
	DEFINE l_where_text STRING

	-- DEFINE l_rec_cheque RECORD 
	-- 	cheq_code LIKE cheque.cheq_code, 
	-- 	bank_code LIKE bank.bank_code, 
	-- 	bank_acct_code LIKE cheque.bank_acct_code 
	-- END RECORD

	DEFINE l_temp_start_num LIKE cheque.cheq_code --ref1_num
	DEFINE l_temp_end_num LIKE cheque.cheq_code --ref2_num
	DEFINE l_temp_bank_code LIKE bank.bank_code --ref1_code

	DEFINE l_temp_acct_code LIKE bank.acct_code 
	-- DEFINE l_temp_cheq_num LIKE cheque.cheq_code 
	-- DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM
	MESSAGE kandoomsg2("A",1036,"") #1036 Enter Banking Details - ESC TO Continue

	INPUT l_temp_bank_code, 
		l_temp_start_num, 
		l_temp_end_num 
		WITHOUT DEFAULTS 
	FROM bank.bank_code, 
		temp_start_num, 
		temp_end_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PCH","inp-bank-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING l_temp_bank_code, l_temp_acct_code 
			DISPLAY l_temp_bank_code, l_temp_acct_code 
			TO bank.bank_code, bank.acct_code 

			NEXT FIELD bank.bank_code 

		AFTER FIELD bank_code 
			SELECT unique bank_code, acct_code 
				INTO l_temp_bank_code, l_temp_acct_code 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_temp_bank_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR "Bank Code NOT found" 
				NEXT FIELD bank.bank_code 
			ELSE 
				SELECT max(cheq_code) 
					INTO l_temp_end_num 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_acct_code = l_temp_acct_code 
						AND pay_meth_ind = "1" 
				DISPLAY l_temp_bank_code, l_temp_acct_code, l_temp_end_num 
				TO bank.bank_code, bank.acct_code, temp_end_num 
			END IF 

		AFTER FIELD temp_start_num 
			IF l_temp_start_num IS NULL THEN 
				SELECT min(cheq_code) 
					INTO l_temp_start_num 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_acct_code = l_temp_acct_code 
						AND pay_meth_ind = "1" 
			END IF 

		AFTER FIELD temp_end_num 
			IF l_temp_end_num IS NULL THEN 
				SELECT max(cheq_code) 
					INTO l_temp_end_num 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_acct_code = l_temp_acct_code 
						AND pay_meth_ind = "1" 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			SELECT unique bank_acct_code 
				INTO l_temp_acct_code 
				FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_temp_bank_code 
					AND pay_meth_ind = "1" 

			IF status = NOTFOUND THEN 
				ERROR "Bank Account Code NOT found" 
				NEXT FIELD bank_code 
			END IF 

			IF l_temp_start_num IS NULL THEN 
				SELECT min(cheq_code) 
					INTO l_temp_start_num 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_acct_code = l_temp_acct_code 
						AND pay_meth_ind = "1" 
			END IF 
			IF l_temp_end_num IS NULL THEN 
				SELECT max(cheq_code) 
					INTO l_temp_end_num 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND bank_acct_code = l_temp_acct_code 
						AND pay_meth_ind = "1" 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL
	ELSE
		IF l_temp_bank_code IS NOT NULL THEN
			LET l_where_text = " l_temp_bank_code=",l_temp_bank_code," AND "
		END IF
		IF l_temp_start_num IS NOT NULL THEN 
			LET l_where_text = l_where_text, " l_temp_start_num=", l_temp_start_num, " AND "
		END IF
		IF l_temp_end_num IS NOT NULL THEN
			LET l_where_text = l_where_text, " l_temp_end_num=", l_temp_end_num 
		END IF 
	
		LET glob_rec_rpt_selector.ref1_num = l_temp_start_num
		LET glob_rec_rpt_selector.ref2_num = l_temp_end_num
		LET glob_rec_rpt_selector.ref1_code = l_temp_bank_code
		LET glob_rec_rpt_selector.ref1_text = l_temp_acct_code

		RETURN l_where_text

	END IF 

END FUNCTION 
############################################################
# END FUNCTION PCH_rpt_query() 
############################################################

############################################################
# FUNCTION PCH_rpt_process()
# RETURN rpt_finish("PCH_rpt_list")
# 
# The report driver
############################################################
FUNCTION PCH_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_temp_start_num LIKE cheque.cheq_code --ref1_num
	DEFINE l_temp_end_num LIKE cheque.cheq_code --ref2_num
	DEFINE l_temp_bank_code LIKE bank.bank_code --ref1_code
	DEFINE l_temp_acct_code LIKE bank.acct_code --ref1_text
	DEFINE l_temp_cheq_num LIKE cheque.cheq_code 

	DEFINE l_rec_cheque RECORD 
		cheq_code LIKE cheque.cheq_code, 
		bank_code LIKE bank.bank_code, 
		bank_acct_code LIKE cheque.bank_acct_code 
	END RECORD

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PCH_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PCH_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCH_rpt_list")].sel_text
	#------------------------------------------------------------
	LET l_temp_start_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCH_rpt_list")].ref1_num	
	LET l_temp_end_num = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCH_rpt_list")].ref2_num
	LET l_temp_bank_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCH_rpt_list")].ref1_code
	LET l_temp_acct_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PCH_rpt_list")].ref1_text

	LET l_temp_cheq_num = l_temp_start_num 

	WHILE l_temp_cheq_num >= l_temp_start_num AND 
		l_temp_cheq_num <= l_temp_end_num 

		SELECT cheque.cheq_code 
		INTO l_rec_cheque.cheq_code 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_acct_code = l_temp_acct_code 
		AND cheq_code = l_temp_cheq_num 
		AND pay_meth_ind = "1" 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_cheque.cheq_code = l_temp_cheq_num 
			LET l_rec_cheque.bank_code = l_temp_bank_code 
			LET l_rec_cheque.bank_acct_code = l_temp_acct_code 

			#------------------------------------------------------------
			OUTPUT TO REPORT PCH_rpt_list(rpt_rmsreps_idx_get_idx("PCH_rpt_list"), l_rec_cheque.*) 
			IF NOT rpt_int_flag_handler2("Cheque no: ",l_rec_cheque.cheq_code, NULL ,rpt_rmsreps_idx_get_idx("PCH_rpt_list")) THEN
				EXIT WHILE 
			END IF 
			#------------------------------------------------------------

		END IF 

		LET l_temp_cheq_num = l_temp_cheq_num + 1 

	END WHILE 

	#------------------------------------------------------------
	FINISH REPORT PCH_rpt_list
	RETURN rpt_finish("PCH_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION PCH_rpt_process()
############################################################

############################################################
# REPORT PCH_rpt_list(p_rpt_idx, p_rec_cheque)
#
# Report Definition/Layout
############################################################
REPORT PCH_rpt_list(p_rpt_idx, p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD 
		cheq_code LIKE cheque.cheq_code, 
		bank_code LIKE bank.bank_code, 
		bank_acct_code LIKE cheque.bank_acct_code 
	END RECORD 

	OUTPUT 
		ORDER external BY p_rec_cheque.bank_acct_code, p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Bank", 
			COLUMN 15, "Bank GL", 
			COLUMN 42, "Cheque" 
			PRINT COLUMN 2, "ID", 
			COLUMN 15, "Account Code", 
			COLUMN 42, "Number" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		BEFORE GROUP OF p_rec_cheque.bank_acct_code 
			NEED 3 LINES 
			PRINT COLUMN 1, p_rec_cheque.bank_code, 
			COLUMN 15, p_rec_cheque.bank_acct_code; 

		ON EVERY ROW 
			PRINT COLUMN 35, p_rec_cheque.cheq_code USING "#########" 

		AFTER GROUP OF p_rec_cheque.bank_acct_code 
			SKIP 1 LINES 

		ON LAST ROW 
			NEED 7 LINES 
			SKIP 2 LINES 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
				PRINT COLUMN 1, "FROM - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_num clipped USING "<<<<<<<<<" , 
								" TO - ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref2_num clipped USING "<<<<<<<<<" 
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 



