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
GLOBALS 
	DEFINE glob_import_filename CHAR(50) #global so it can default EVERY time 
	DEFINE glob_export_filename CHAR(50) #global so it can default EVERY time 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_kandoo_periods SMALLINT 
############################################################
# FUNCTION GSJ_main()
#
# GSJ.4gl - Allows import of budget information created in spread sheet,
#           export existing budget/Account information FOR use in spread
#           sheets OR TO simply initialise budgets TO an initial value.
############################################################
FUNCTION GSJ_main() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GSJ") 

	CREATE temp TABLE t_temptabl(bdgt_line CHAR(1000)) with no LOG 

	OPEN WINDOW G400 with FORM "G400" 
	CALL windecoration_g("G400") 

	MENU " Budget Interface" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","GSJ","menu-budget-interface") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Unload"	#COMMAND "Unload" " Export existing Budget/Account Information"
			IF GSJ_rpt_query() THEN 
			END IF 

		ON ACTION "Load"	#COMMAND "Load" " Import Budget Information FROM import file"
			IF import_bdgts() THEN 
			END IF 

		ON ACTION "Initialise"	#COMMAND "Initialise" " Set nominated Budgets TO an initial value"
			IF init_bdgts() THEN 
			END IF 

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"	#COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW G400 

END FUNCTION 


############################################################
# FUNCTION GSJ_rpt_query()
#
#
############################################################
FUNCTION GSJ_rpt_query() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_acct_type CHAR(1) 
	DEFINE l_year_num SMALLINT
	DEFINE l_export_basis CHAR(3)
	DEFINE l_budget_amt LIKE accounthist.budg1_amt 
	DEFINE l_seg_text,l_query_text CHAR(400) 
	DEFINE j INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("G",1037,"") 

	#1037 " Enter Account Information - ESC TO Continue"
	LET l_year_num = NULL 
	LET l_rec_company.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT
	l_rec_company.cmpy_code, 
	l_acct_type, 
	l_year_num, 
	l_export_basis, 
	glob_export_filename WITHOUT DEFAULTS 
	FROM
	cmpy_code, 
	acct_type, 
	year_num, 
	export_basis, 
	export_filename  
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSJ","inp-company1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD cmpy_code 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9003,"") #9003 " Company does NOT exist - See System Administrator"
				LET l_rec_company.name_text = NULL 
				NEXT FIELD cmpy_code 
			END IF 
			DISPLAY l_rec_company.name_text TO name_text 

		AFTER FIELD acct_type 
			IF l_acct_type IS NOT NULL THEN 
				IF l_acct_type matches "[IEALN]" THEN 
				ELSE 
					ERROR kandoomsg2("G",9147,"") 			#9147 " Account type does NOT exist"
					NEXT FIELD acct_type 
				END IF 
			END IF 
			
		AFTER FIELD year_num 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF 
			SELECT unique 1 FROM period 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			AND year_num = l_year_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9150,"") #9150 " No account information exists FOR this year"
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD export_basis 
			IF l_export_basis IS NULL 
			OR (l_export_basis != "1" 
			AND l_export_basis != "2" 
			AND l_export_basis != "3" 
			AND l_export_basis != "4" 
			AND l_export_basis != "5" 
			AND l_export_basis != "6" 
			AND l_export_basis != "AP" 
			AND l_export_basis != "ACB") THEN 
				ERROR kandoomsg2("G",9149,"") 		#9149 " Basis type does NOT exist"
				NEXT FIELD export_basis 
			END IF 

		AFTER FIELD export_filename 
			IF glob_export_filename IS NULL THEN 
				ERROR kandoomsg2("G",9144,"") 	#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD export_filename 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF 
			IF l_export_basis IS NULL THEN 
				ERROR kandoomsg2("G",9149,"") 	#9149 " Basis type does NOT exist"
				NEXT FIELD export_basis 
			END IF 
			IF glob_export_filename IS NULL THEN 
				ERROR kandoomsg2("G",9144,"") 	#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD export_filename 
			END IF 
			IF NOT create_table(l_rec_company.cmpy_code,l_year_num) THEN 
				ERROR kandoomsg2("G",9150,"") 		#9150 " No account information exists FOR this year"
				NEXT FIELD year_num 
			END IF 

			WHENEVER ERROR CONTINUE 

			# Check IF file exists by inserting INTO temporary temp table
			DELETE FROM t_temptabl 
			LOAD FROM glob_export_filename 
			INSERT INTO t_temptabl 
			IF status = 0 THEN 
				LET l_msgresp = kandoomsg("G",8017,"") 
				#8017 "Interface file already exists. Overwrite? (Y/N)"
				IF l_msgresp = "N" 
				OR l_msgresp = "n" THEN 
					IF fgl_find_table("t_bdgthead") THEN
						DROP TABLE t_bdgthead 
					END IF					
					WHENEVER ERROR stop 
					NEXT FIELD export_filename 
				END IF 
			END IF 

			WHENEVER ERROR CONTINUE 

			UNLOAD TO glob_export_filename delimiter "," 
			SELECT * FROM t_bdgthead 
			IF status = -806 THEN 
				ERROR kandoomsg2("G",9140,"") 	#9140 " Directory NOT found - Check AND re-enter"
				IF fgl_find_table("t_bdgthead") THEN
					DROP TABLE t_bdgthead 
				END IF					
				WHENEVER ERROR stop 
				NEXT FIELD export_filename 
			END IF 

			WHENEVER ERROR stop 

			CALL segment_con(glob_rec_kandoouser.cmpy_code,"coa") RETURNING l_seg_text 
			IF l_seg_text IS NULL THEN 
				IF fgl_find_table("t_bdgthead") THEN
					DROP TABLE t_bdgthead 
				END IF					

				NEXT FIELD cmpy_code 
			END IF 

			LET l_query_text = "SELECT * FROM accounthist ", 
			"WHERE cmpy_code = ? ", 
			"AND acct_code = ? ", 
			"AND year_num = ? " 
			PREPARE s_accounthist FROM l_query_text 
			DECLARE c_accounthist CURSOR FOR s_accounthist 
			
			LET l_query_text = "SELECT acct_code FROM coa ", 
			"WHERE cmpy_code = '",l_rec_company.cmpy_code,"' ", 
			" AND end_year_num >= ", l_year_num, " ", 
			" AND start_year_num <= ", l_year_num, " ", 
			l_seg_text, " " 
			IF l_acct_type IS NOT NULL THEN 
				LET l_query_text = l_query_text clipped, 
				" AND type_ind = '",l_acct_type,"' " 
			END IF 
			LET l_query_text = l_query_text clipped, " ORDER BY acct_code" 



	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GSJ_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT GSJ_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

			#DISPLAY "Unloading Account - " TO lblabel1 -- 1,2 

			PREPARE s_coa FROM l_query_text 
			DECLARE c_coa CURSOR FOR s_coa 

			FOREACH c_coa INTO l_rec_accounthist.acct_code 
				CALL ins_account(l_rec_accounthist.acct_code) 
				DISPLAY l_rec_accounthist.acct_code TO lblabel1b -- 1,22 

				OPEN c_accounthist USING l_rec_company.cmpy_code, 
				l_rec_accounthist.acct_code, 
				l_year_num 
				
				FOREACH c_accounthist INTO l_rec_accounthist.* 
				
					CASE l_export_basis 
						WHEN "1" 
							LET l_budget_amt = l_rec_accounthist.budg1_amt 
						WHEN "2" 
							LET l_budget_amt = l_rec_accounthist.budg2_amt 
						WHEN "3" 
							LET l_budget_amt = l_rec_accounthist.budg3_amt 
						WHEN "4" 
							LET l_budget_amt = l_rec_accounthist.budg4_amt 
						WHEN "5" 
							LET l_budget_amt = l_rec_accounthist.budg5_amt 
						WHEN "6" 
							LET l_budget_amt = l_rec_accounthist.budg6_amt 
						WHEN "AP" 
							LET l_budget_amt = l_rec_accounthist.pre_close_amt 
						WHEN "ACB" 
							LET l_budget_amt = l_rec_accounthist.open_amt 
					END CASE 
					
					CALL upd_account(l_rec_accounthist.acct_code, 
					l_rec_accounthist.period_num, 
					l_budget_amt) 

				END FOREACH 

				IF int_flag OR quit_flag THEN 
					#8018 Extract Interrupted - Continue? (Y/N)
					IF kandoomsg("G",8018,"") = "N" THEN 
						DELETE FROM t_bdgthead WHERE 1=1 
						EXIT FOREACH 
					END IF 
				END IF 

			END FOREACH 


			SELECT count(*) INTO j FROM t_bdgthead 
			IF j > 0 THEN 
				MESSAGE kandoomsg2("G",1019,"") 	#1019 " Creating extract file  - Please wait"

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
				--IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
				--	LET int_flag = false 
				--	LET quit_flag = false
				--
				--		RETURN FALSE
				--END IF
			
				LET l_rpt_idx = rpt_start("GSJ-EXP","GSJ_rpt_list_exp","N/A", RPT_SHOW_RMS_DIALOG)
				IF l_rpt_idx = 0 THEN #User pressed CANCEL
					RETURN FALSE
				END IF	
				START REPORT GSJ_rpt_list_exp TO rpt_get_report_file_with_path2(l_rpt_idx)
				WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
				#------------------------------------------------------------


				#---------------------------------------------------------
				OUTPUT TO REPORT GSJ_rpt_list_exp(l_rpt_idx,
				l_rec_company.*)  
				#---------------------------------------------------------					

				#------------------------------------------------------------
				FINISH REPORT GSJ_rpt_list_exp
				CALL rpt_finish("GSJ_rpt_list_exp")
				#------------------------------------------------------------


 
				DELETE FROM t_bdgthead WHERE 1=1 
				MESSAGE kandoomsg2("G",7017,j)		#7017" n rows extracted
			ELSE 
				# menu control - ie stay on Unload
				LET int_flag = true 
			END IF 

			IF fgl_find_table("t_bdgthead") THEN
				DROP TABLE t_bdgthead 
			END IF					


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION create_table(p_cmpy_code,p_year_num) 
#
#
############################################################
FUNCTION create_table(p_cmpy_code,p_year_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_year_num LIKE accounthist.year_num 
	DEFINE l_create_text CHAR(2400) 
	DEFINE i SMALLINT 

	LET modu_kandoo_periods = NULL 
	SELECT max(period_num) INTO modu_kandoo_periods FROM period 
	WHERE cmpy_code = p_cmpy_code 
	AND year_num = p_year_num 
	IF modu_kandoo_periods IS NULL 
	OR modu_kandoo_periods = 0 THEN 
		RETURN false 
	END IF 
	LET l_create_text = "CREATE TEMP TABLE t_bdgthead(acct_code CHAR(18)" 

	FOR i = 1 TO modu_kandoo_periods 
		LET l_create_text = l_create_text clipped, 
		",period", 
		i USING "<<<", 
		" DECIMAL(16,2)" 
	END FOR 

	LET l_create_text = l_create_text clipped, 
	",total_amt DECIMAL(16,2)) with no log" 
	PREPARE s_bdgthead FROM l_create_text 
	EXECUTE s_bdgthead 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION ins_account(p_acct_code)  
#
#
############################################################
FUNCTION ins_account(p_acct_code) 
	DEFINE p_acct_code LIKE accounthist.acct_code 
	DEFINE l_insert_text CHAR(2400) 
	DEFINE i SMALLINT 

	LET l_insert_text = "INSERT INTO t_bdgthead VALUES ('",p_acct_code,"'" 

	FOR i = 1 TO modu_kandoo_periods 
		LET l_insert_text = l_insert_text clipped, ",0" 
	END FOR 

	LET l_insert_text = l_insert_text clipped, ",0)" 
	PREPARE s_insert FROM l_insert_text 
	EXECUTE s_insert 

END FUNCTION 


############################################################
# FUNCTION upd_account(p_acct_code,p_period_num,p_bdgt_amt)
#
#
############################################################
FUNCTION upd_account(p_acct_code,p_period_num,p_bdgt_amt) 
	DEFINE p_acct_code LIKE accounthist.acct_code
	DEFINE p_period_num LIKE accounthist.period_num 
	DEFINE p_bdgt_amt LIKE accounthist.budg1_amt 
	DEFINE l_update_text CHAR(2400) 

	LET l_update_text = "UPDATE t_bdgthead SET period", 
	p_period_num USING "<<<", "=period", 
	p_period_num USING "<<<", "+ ", p_bdgt_amt, ",", 
	"total_amt = total_amt + ", p_bdgt_amt, 
	" WHERE acct_code = '",p_acct_code,"'" 
	PREPARE s_update FROM l_update_text 
	EXECUTE s_update 

END FUNCTION 

############################################################
# FUNCTION get_init_amt(p_cmpy_code, p_acct_code, p_period_num, 
#	p_init_basis, p_init_year, p_change_per) 
#
#
############################################################
FUNCTION get_init_amt(p_cmpy_code, p_acct_code, p_period_num, 
	p_init_basis, p_init_year, p_change_per) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_acct_code LIKE accounthist.acct_code
	DEFINE p_period_num LIKE accounthist.period_num 
	DEFINE p_init_basis CHAR(4)
	DEFINE p_init_year LIKE accounthist.year_num 
	DEFINE p_change_per FLOAT
	DEFINE l_budget_amt LIKE accounthist.budg1_amt 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 

	SELECT * INTO l_rec_accounthist.* FROM accounthist 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = p_acct_code 
	AND year_num = p_init_year 
	AND period_num = p_period_num 
	IF status = NOTFOUND THEN 
		LET l_budget_amt = 0 
	ELSE 
		CASE p_init_basis 
			WHEN "1" 
				LET l_budget_amt = l_rec_accounthist.budg1_amt 
			WHEN "2" 
				LET l_budget_amt = l_rec_accounthist.budg2_amt 
			WHEN "3" 
				LET l_budget_amt = l_rec_accounthist.budg3_amt 
			WHEN "4" 
				LET l_budget_amt = l_rec_accounthist.budg4_amt 
			WHEN "5" 
				LET l_budget_amt = l_rec_accounthist.budg5_amt 
			WHEN "6" 
				LET l_budget_amt = l_rec_accounthist.budg6_amt 
			WHEN "AP" 
				LET l_budget_amt = l_rec_accounthist.pre_close_amt 
			WHEN "ACB" 
				LET l_budget_amt = l_rec_accounthist.open_amt 
		END CASE 
	END IF 

	IF p_change_per IS NOT NULL 
	AND p_change_per != 0 THEN 
		LET l_budget_amt = l_budget_amt + (l_budget_amt * (p_change_per/100)) 
	END IF 
	IF l_budget_amt IS NULL THEN 
		LET l_budget_amt = 0 
	END IF 

	RETURN l_budget_amt 
END FUNCTION 


############################################################
# FUNCTION import_bdgts()  
#
#
############################################################
FUNCTION import_bdgts() 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*
	DEFINE l_rec_account RECORD LIKE account.*
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_acct_type CHAR(1)
	DEFINE i SMALLINT
	DEFINE l_year_num SMALLINT
	DEFINE l_start_chart SMALLINT
	DEFINE l_end_chart SMALLINT	 
	DEFINE l_init_budgets CHAR(1)
	DEFINE l_import_budget_no CHAR(1)	
	DEFINE l_tot_amt LIKE accounthist.budg1_amt 
	DEFINE l_budget_amt LIKE accounthist.budg1_amt 
	DEFINE l_acct_bal LIKE accounthist.open_amt
	DEFINE l_acct_code LIKE accounthist.acct_code 
	DEFINE l_coa_type LIKE coa.type_ind
	DEFINE l_seg_text CHAR(400) 
	DEFINE l_query_text CHAR(400) 
	DEFINE l_err_message CHAR(40)
	DEFINE l_rpt_output CHAR(50)
	DEFINE j INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("G",1037,"") 	#1037 " Enter Account Information - ESC TO Continue"
	LET l_rec_company.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_year_num = NULL 
	LET l_init_budgets = "N" 

	INPUT BY NAME l_rec_company.cmpy_code, 
	l_acct_type, 
	l_year_num, 
	l_import_budget_no, 
	l_init_budgets, 
	glob_import_filename WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSJ","inp-company2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD cmpy_code 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9003,"") 	#9003 " Company does NOT exist - See System Administrator"
				LET l_rec_company.name_text = NULL 
				NEXT FIELD cmpy_code 
			END IF 
			DISPLAY l_rec_company.name_text TO name_text  

		AFTER FIELD acct_type 
			IF l_acct_type IS NOT NULL THEN 
				IF l_acct_type matches "[IEALN]" THEN 
				ELSE 
					ERROR kandoomsg2("G",9147,"") 			#9147 " Account type does NOT exist"
					NEXT FIELD acct_type 
				END IF 
			END IF 
			
		AFTER FIELD year_num 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 			#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF 
			SELECT unique 1 FROM period 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			AND year_num = l_year_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9150,"") 		#9150 " No account information exists FOR this year"
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD import_budget_no 
			IF l_import_budget_no matches "[123456]" THEN 
			ELSE 
				ERROR kandoomsg2("G",9151,"") 		#9151 " Budget Number does NOT exist
				NEXT FIELD import_budget_no 
			END IF 
			
			CASE l_import_budget_no 
				WHEN "1" 
					IF glob_rec_glparms.budg1_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 					#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
				WHEN "2" 
					IF glob_rec_glparms.budg2_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
				WHEN "3" 
					IF glob_rec_glparms.budg3_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
				WHEN "4" 
					IF glob_rec_glparms.budg4_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 			#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
				WHEN "5" 
					IF glob_rec_glparms.budg5_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
				WHEN "6" 
					IF glob_rec_glparms.budg6_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD import_budget_no 
					END IF 
			END CASE 
			
		AFTER FIELD import_filename 
			IF glob_import_filename IS NULL THEN 
				ERROR kandoomsg2("G",9144,"") 		#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD import_filename 
			END IF 
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 			#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF 
			IF l_import_budget_no IS NULL THEN 
				ERROR kandoomsg2("G",9151,"") 			#9151 " Budget number does NOT exist
				NEXT FIELD import_budget_no 
			END IF 
			IF glob_import_filename IS NULL THEN 
				ERROR kandoomsg2("G",9144,"") 		#9144 " Interface file does NOT exist - Check path AND file name"
				NEXT FIELD import_filename 
			END IF 
			IF NOT create_table(l_rec_company.cmpy_code,l_year_num) THEN 
				ERROR kandoomsg2("G",9150,"") 			#9150 " No account information exists FOR this year"
				NEXT FIELD year_num 
			END IF 
			WHENEVER ERROR CONTINUE 
			# Check IF file exists by inserting INTO temporary temp table
			DELETE FROM t_temptabl 
			LOAD FROM glob_import_filename 
			INSERT INTO t_temptabl 
			IF status != 0 THEN 
				IF status = -846 THEN 
					LET l_msgresp = kandoomsg("G",9154,"") 			#9154 "Interface files must NOT contain blank lines"
				ELSE 
					LET l_msgresp = kandoomsg("G",9144,"") 			#9144 "Interface file does not_exist - Check path AND file name"
				END IF 
				IF fgl_find_table("t_bdgthead") THEN
					DROP TABLE t_bdgthead 
				END IF					

				WHENEVER ERROR stop 
				NEXT FIELD import_filename 
			END IF
			 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"coa") RETURNING l_seg_text
			 
			IF l_seg_text IS NULL THEN 
				IF fgl_find_table("t_bdgthead") THEN
					DROP TABLE t_bdgthead 
				END IF					

				NEXT FIELD cmpy_code 
			END IF
			 
			ERROR kandoomsg2("G",1005,"") 		#1005 " Updating Database - Please wait"

			WHENEVER ERROR CONTINUE
			 
			LOAD FROM glob_import_filename delimiter "," 
			INSERT INTO t_bdgthead 
			IF status != 0 THEN 
				ERROR kandoomsg2("G",9152,"") 		#9152 Unable TO load budgets - Check file FORMAT
				IF fgl_find_table("t_bdgthead") THEN
					DROP TABLE t_bdgthead 
				END IF					

				LET int_flag = true 
				WHENEVER ERROR stop 
				# ***Serious error*** -  delimiter OR no. of columns error etc
				EXIT INPUT 
			END IF
			 
			WHENEVER ERROR stop
			 

			START REPORT GSJ_rpt_list TO l_rpt_output 

			DISPLAY "Loading Account - " TO lblabel1 -- 1,2 

			SELECT * INTO l_rec_structure.* FROM structure 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			AND type_ind = "C" 
			LET l_start_chart = l_rec_structure.start_num 
			LET l_end_chart = l_rec_structure.start_num 
			+ l_rec_structure.length_num 
			- 1 
			LET l_query_text = 
			"SELECT unique t_bdgthead.acct_code, coa.type_ind ", 
			"FROM t_bdgthead, outer coa ", 
			"WHERE coa.cmpy_code = '",l_rec_company.cmpy_code,"' ", 
			" AND coa.acct_code = t_bdgthead.acct_code ", 
			l_seg_text, " " 
			IF l_acct_type IS NOT NULL THEN 
				LET l_query_text = l_query_text clipped, 
				" AND coa.type_ind = '",l_acct_type,"' " 
			END IF 

			PREPARE s_t_bdgthead FROM l_query_text 
			DECLARE c_t_bdgthead CURSOR with HOLD FOR s_t_bdgthead 

			FOREACH c_t_bdgthead INTO l_acct_code,l_coa_type 
				GOTO bypass 
				LABEL recovery: 
				LET l_msgresp = error_recover (l_err_message, status) 
				IF l_msgresp != "Y" THEN 
					EXIT PROGRAM 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				LET j = 0 
				BEGIN WORK 
					LET l_tot_amt = 0 
					DISPLAY "" at 1,20 
					DISPLAY l_acct_code TO lblabel1 -- 1,20 

					LET j = j + 1 
					IF l_coa_type IS NULL THEN #no matching coa 
						ERROR kandoomsg2("G",9158,"") 				#9158 Errors Detected "
					ELSE 
						LET l_acct_bal = NULL 
						IF l_coa_type matches "[AL]" THEN 
							SELECT bal_amt INTO l_acct_bal FROM account 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num - 1 
						END IF 
						IF l_acct_bal IS NULL THEN 
							LET l_acct_bal = 0 
						END IF 
						SELECT unique 1 FROM account 
						WHERE cmpy_code = l_rec_company.cmpy_code 
						AND acct_code = l_acct_code 
						AND year_num = l_year_num 
						IF status = NOTFOUND THEN 
							INITIALIZE l_rec_account.* TO NULL 
							LET l_rec_account.cmpy_code = l_rec_company.cmpy_code 
							LET l_rec_account.acct_code = l_acct_code 
							LET l_rec_account.year_num = l_year_num 
							LET l_rec_account.chart_code = 
							l_acct_code[l_start_chart,l_end_chart] 
							LET l_rec_account.debit_amt = 0 
							LET l_rec_account.credit_amt = 0 
							LET l_rec_account.stats_qty = 0 
							LET l_rec_account.ytd_pre_close_amt = 0 
							LET l_rec_account.budg1_amt = 0 
							LET l_rec_account.budg2_amt = 0 
							LET l_rec_account.budg3_amt = 0 
							LET l_rec_account.budg4_amt = 0 
							LET l_rec_account.budg5_amt = 0 
							LET l_rec_account.budg6_amt = 0 
							LET l_rec_account.open_amt = l_acct_bal 
							LET l_rec_account.bal_amt = l_acct_bal 
							INSERT INTO account VALUES (l_rec_account.*) 
						END IF 

						FOR i = 1 TO modu_kandoo_periods 
							# Retrieve each COLUMN FROM temporary table
							LET l_query_text = 
							"SELECT sum(period",i using "<<<", ") FROM t_bdgthead ", 
							"WHERE acct_code = ?" 
							PREPARE s_t_bdgtper FROM l_query_text 
							DECLARE c_t_bdgtper CURSOR FOR s_t_bdgtper 
							OPEN c_t_bdgtper USING l_acct_code 
							FETCH c_t_bdgtper INTO l_budget_amt 
							IF l_budget_amt IS NULL THEN 
								LET l_budget_amt = 0 
							END IF 
							LET l_tot_amt = l_tot_amt + l_budget_amt 
							IF l_coa_type IS NOT NULL THEN 
								SELECT unique 1 FROM accounthist 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
								IF status = NOTFOUND THEN 
									INITIALIZE l_rec_accounthist.* TO NULL 
									LET l_rec_accounthist.cmpy_code = l_rec_company.cmpy_code 
									LET l_rec_accounthist.acct_code = l_acct_code 
									LET l_rec_accounthist.year_num = l_year_num 
									LET l_rec_accounthist.period_num = i 
									LET l_rec_accounthist.open_amt = 0 
									LET l_rec_accounthist.debit_amt = 0 
									LET l_rec_accounthist.credit_amt = 0 
									LET l_rec_accounthist.close_amt = 0 
									LET l_rec_accounthist.stats_qty = 0 
									LET l_rec_accounthist.pre_close_amt = 0 
									LET l_rec_accounthist.ytd_pre_close_amt = 0 
									LET l_rec_accounthist.hist_flag = "N" 
									LET l_rec_accounthist.budg1_amt = 0 
									LET l_rec_accounthist.budg2_amt = 0 
									LET l_rec_accounthist.budg3_amt = 0 
									LET l_rec_accounthist.budg4_amt = 0 
									LET l_rec_accounthist.budg5_amt = 0 
									LET l_rec_accounthist.budg6_amt = 0 
									LET l_rec_accounthist.ytd_budg1_amt = 0 
									LET l_rec_accounthist.ytd_budg2_amt = 0 
									LET l_rec_accounthist.ytd_budg3_amt = 0 
									LET l_rec_accounthist.ytd_budg4_amt = 0 
									LET l_rec_accounthist.ytd_budg5_amt = 0 
									LET l_rec_accounthist.ytd_budg6_amt = 0 

									INSERT INTO accounthist VALUES (l_rec_accounthist.*) 

								END IF 

								CASE l_import_budget_no 
									WHEN "1" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg1_amt = l_budget_amt, 
											ytd_budg1_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg1_amt = budg1_amt + l_budget_amt, 
											ytd_budg1_amt = ytd_budg1_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 
									WHEN "2" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg2_amt = l_budget_amt, 
											ytd_budg2_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg2_amt = budg2_amt + l_budget_amt, 
											ytd_budg2_amt = ytd_budg2_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 

									WHEN "3" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg3_amt = l_budget_amt, 
											ytd_budg3_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg3_amt = budg3_amt + l_budget_amt, 
											ytd_budg3_amt = ytd_budg3_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 

									WHEN "4" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg4_amt = l_budget_amt, 
											ytd_budg4_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg4_amt = budg4_amt + l_budget_amt, 
											ytd_budg4_amt = ytd_budg4_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 

									WHEN "5" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg5_amt = l_budget_amt, 
											ytd_budg5_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg5_amt = budg5_amt + l_budget_amt, 
											ytd_budg5_amt = ytd_budg5_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 

									WHEN "6" 
										IF l_init_budgets = "Y" THEN 
											UPDATE accounthist 
											SET budg6_amt = l_budget_amt, 
											ytd_budg6_amt = l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										ELSE 
											UPDATE accounthist 
											SET budg6_amt = budg6_amt + l_budget_amt, 
											ytd_budg6_amt = ytd_budg6_amt + l_tot_amt 
											WHERE cmpy_code = l_rec_company.cmpy_code 
											AND acct_code = l_acct_code 
											AND year_num = l_year_num 
											AND period_num = i 
										END IF 
								END CASE 
							END IF 
						END FOR 
					END IF 

					# Retrieve each COLUMN FROM temporary table
					LET l_query_text = "SELECT sum(total_amt) FROM t_bdgthead ", 
					"WHERE acct_code = ?" 
					PREPARE s_t_bdgttot FROM l_query_text 
					DECLARE c_t_bdgttot CURSOR FOR s_t_bdgttot 
					OPEN c_t_bdgttot USING l_acct_code 
					FETCH c_t_bdgttot INTO l_budget_amt 

					IF l_budget_amt IS NULL THEN 
						LET l_budget_amt = 0 
					END IF 

					#---------------------------------------------------------
					OUTPUT TO REPORT GSJ_rpt_list(l_rpt_idx,l_rec_company.cmpy_code, 
					l_year_num, 
					l_import_budget_no, 
					l_acct_code, 
					l_coa_type, 
					l_tot_amt, 
					l_budget_amt) 
					#---------------------------------------------------------	

					IF l_coa_type IS NOT NULL THEN 

						CASE l_import_budget_no 
							WHEN "1" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg1_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg1_amt = budg1_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 

							WHEN "2" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg2_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg2_amt = budg2_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 

							WHEN "3" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg3_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg3_amt = budg3_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 

							WHEN "4" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg4_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg4_amt = budg4_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 

							WHEN "5" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg5_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg5_amt = budg5_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 

							WHEN "6" 
								IF l_init_budgets = "Y" THEN 
									UPDATE account 
									SET budg6_amt = l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								ELSE 
									UPDATE account 
									SET budg6_amt = budg6_amt + l_tot_amt 
									WHERE cmpy_code = l_rec_company.cmpy_code 
									AND acct_code = l_acct_code 
									AND year_num = l_year_num 
								END IF 
						END CASE 

					END IF 

				COMMIT WORK 

				IF int_flag OR quit_flag THEN 
					#8018 Extract Interrupted - Continue? (Y/N)
					IF kandoomsg("G",8018,"") = "N" THEN 
						DELETE FROM t_bdgthead WHERE 1=1 
						EXIT FOREACH 
					END IF 
				END IF 

			END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AB5_rpt_list
	CALL rpt_finish("AB5_rpt_list")
	#------------------------------------------------------------

			SELECT count(*) INTO j FROM t_bdgthead 
			MESSAGE kandoomsg2("U",8025,j) 		#7017" n rows extracted
			IF j = 0 THEN 
				# menu control - ie stay on Load
				LET int_flag = true 
			END IF 

			IF fgl_find_table("t_bdgthead") THEN
				DROP TABLE t_bdgthead 
			END IF					


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION init_bdgts()   
#
#
############################################################
FUNCTION init_bdgts() 
	DEFINE l_rec_accounthist RECORD LIKE accounthist.*
	DEFINE l_rec_account RECORD LIKE account.*
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_acct_type CHAR(1)
	DEFINE l_year_num SMALLINT
	DEFINE l_init_budget_no CHAR(1)
	DEFINE l_init_basis CHAR(4)
	DEFINE l_init_year SMALLINT
	DEFINE l_change_per FLOAT
	DEFINE l_acct_code LIKE accounthist.acct_code
	DEFINE l_budget_amt LIKE accounthist.budg1_amt
	DEFINE l_acct_bal LIKE accounthist.open_amt
	DEFINE l_tot_amt LIKE accounthist.budg1_amt
	DEFINE l_coa_type LIKE coa.type_ind
	DEFINE l_seg_text CHAR(400)
	DEFINE l_query_text CHAR(400)
	DEFINE l_err_message CHAR(40)
	DEFINE j INTEGER
	DEFINE i SMALLINT
	DEFINE l_start_chart SMALLINT
	DEFINE l_end_chart SMALLINT
	 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	MESSAGE kandoomsg2("G",1037,"") #1037 " Enter Account Information - ESC TO Continue"
	LET l_year_num = NULL 
	LET l_init_year = NULL 
	LET l_change_per = NULL 
	LET l_rec_company.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT 
		l_rec_company.cmpy_code, 
		l_acct_type, 
		l_year_num, 
		l_init_budget_no, 
		l_init_basis, 
		l_init_year, 
		l_change_per WITHOUT DEFAULTS 
	FROM
		cmpy_code, 
		acct_type, 
		year_num, 
		init_budget_no, 
		init_basis, 
		init_year, 
		change_per ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GSJ","inp-company3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD cmpy_code 
			SELECT * INTO l_rec_company.* FROM company 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9003,"") 		#9003 " Company does NOT exist - See System Administrator"
				LET l_rec_company.name_text = NULL 
				NEXT FIELD cmpy_code 
			END IF 
			DISPLAY BY NAME l_rec_company.name_text 

		AFTER FIELD acct_type 
			IF l_acct_type IS NOT NULL THEN 
				IF l_acct_type matches "[IEALN]" THEN 
				ELSE 
					ERROR kandoomsg2("G",9147,"") 			#9147 " Account type does NOT exist"
					NEXT FIELD acct_type 
				END IF 
			END IF
			 
		AFTER FIELD year_num 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF 
			SELECT unique 1 FROM period 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			AND year_num = l_year_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9150,"") 		#9150 " No account information exists FOR this year"
				NEXT FIELD year_num 
			END IF 
			
		AFTER FIELD init_budget_no 
			IF l_init_budget_no matches "[123456]" THEN 
			ELSE 
				ERROR kandoomsg2("G",9151,"") 		#9151 " Budget Number does NOT exist
				NEXT FIELD init_budget_no 
			END IF 
			CASE l_init_budget_no 
				WHEN "1" 
					IF glob_rec_glparms.budg1_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 			#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
				WHEN "2" 
					IF glob_rec_glparms.budg2_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
				WHEN "3" 
					IF glob_rec_glparms.budg3_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 			#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
				WHEN "4" 
					IF glob_rec_glparms.budg4_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
				WHEN "5" 
					IF glob_rec_glparms.budg5_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
				WHEN "6" 
					IF glob_rec_glparms.budg6_close_flag = "Y" THEN 
						ERROR kandoomsg2("G",9153,"") 				#9153 " Budget IS locked - Use GZP TO unlock"
						NEXT FIELD init_budget_no 
					END IF 
			END CASE 
			
		AFTER FIELD init_basis 
			IF l_init_basis IS NULL 
			OR (l_init_basis != "1" 
			AND l_init_basis != "2" 
			AND l_init_basis != "3" 
			AND l_init_basis != "4" 
			AND l_init_basis != "5" 
			AND l_init_basis != "6" 
			AND l_init_basis != "AP" 
			AND l_init_basis != "ACB" 
			AND l_init_basis != "ZERO") THEN 
				ERROR kandoomsg2("G",9149,"") 		#9149 " Basis type does NOT exist"
				NEXT FIELD init_basis 
			END IF 
			
		AFTER FIELD init_year 
			IF l_init_basis != "ZERO" THEN 
				IF l_init_year IS NULL THEN 
					ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
					NEXT FIELD init_year 
				END IF 
				SELECT unique 1 FROM period 
				WHERE cmpy_code = l_rec_company.cmpy_code 
				AND year_num = l_init_year 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9150,"") 			#9150 " No account information exists FOR this year"
					NEXT FIELD init_year 
				END IF 
			END IF 
			
		AFTER FIELD change_per 
			IF l_change_per IS NULL THEN 
				LET l_change_per = 0 
			END IF 
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF l_year_num IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
				NEXT FIELD year_num 
			END IF
			 
			IF l_init_budget_no IS NULL THEN 
				ERROR kandoomsg2("G",9151,"") 		#9151 " Budget number does NOT exist
				NEXT FIELD init_budget_no 
			END IF
			 
			IF l_init_basis IS NULL THEN 
				ERROR kandoomsg2("G",9149,"") 		#9149 " Basis type does NOT exist"
				NEXT FIELD init_basis 
			END IF
			 
			IF l_init_basis != "ZERO" 
			AND l_init_year IS NULL THEN 
				ERROR kandoomsg2("G",9148,"") 		#9148 " Fiscal year must be entered "
				NEXT FIELD init_year 
			END IF
			 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"coa") RETURNING l_seg_text
			 
			IF l_seg_text IS NULL THEN 
				NEXT FIELD cmpy_code 
			END IF 
			MESSAGE kandoomsg2("G",1005,"") 	#1005 " Updating Database - Please wait"
			SELECT * INTO l_rec_structure.* FROM structure 
			WHERE cmpy_code = l_rec_company.cmpy_code 
			AND type_ind = "C" 
			LET l_start_chart = l_rec_structure.start_num 
			LET l_end_chart = l_rec_structure.start_num 
			+ l_rec_structure.length_num 
			- 1 
			LET l_query_text = "SELECT * FROM accounthist ", 
			"WHERE cmpy_code = ? ", 
			"AND acct_code = ? ", 
			"AND year_num = ? ", 
			"AND period_num = ? " 
			PREPARE s1_accounthist FROM l_query_text 
			DECLARE c1_accounthist CURSOR FOR s1_accounthist 
			LET l_query_text = "SELECT acct_code,type_ind FROM coa ", 
			"WHERE cmpy_code = '",l_rec_company.cmpy_code,"' ", 
			" AND end_year_num >= ", l_year_num, " ", 
			" AND start_year_num <= ", l_year_num, " ", 
			l_seg_text, " " 
			IF l_acct_type IS NOT NULL THEN 
				LET l_query_text = l_query_text clipped, 
				" AND type_ind = '",l_acct_type,"' " 
			END IF 
			PREPARE s1_coa FROM l_query_text 
			DECLARE c1_coa CURSOR FOR s1_coa 
			GOTO bypass 
			LABEL recovery: 
			LET l_msgresp = error_recover (l_err_message, status) 
			IF l_msgresp != "Y" THEN 
				EXIT PROGRAM 
			END IF 
			
			LABEL bypass: 
			WHENEVER ERROR 
			GOTO recovery 
			
			BEGIN WORK 
				LET j = 0 
				FOREACH c1_coa INTO l_acct_code, l_coa_type 
					LET j = j + 1 
					LET l_acct_bal = NULL 
					IF l_coa_type matches "[AL]" THEN 
						SELECT bal_amt INTO l_acct_bal FROM account 
						WHERE cmpy_code = l_rec_company.cmpy_code 
						AND acct_code = l_acct_code 
						AND year_num = l_year_num - 1 
					END IF 
					IF l_acct_bal IS NULL THEN 
						LET l_acct_bal = 0 
					END IF 
					SELECT unique 1 FROM account 
					WHERE cmpy_code = l_rec_company.cmpy_code 
					AND acct_code = l_acct_code 
					AND year_num = l_year_num 
					IF status = NOTFOUND THEN 
						INITIALIZE l_rec_account.* TO NULL 
						LET l_rec_account.cmpy_code = l_rec_company.cmpy_code 
						LET l_rec_account.acct_code = l_acct_code 
						LET l_rec_account.year_num = l_year_num 
						LET l_rec_account.chart_code = 
						l_acct_code[l_start_chart,l_end_chart] 
						LET l_rec_account.debit_amt = 0 
						LET l_rec_account.credit_amt = 0 
						LET l_rec_account.stats_qty = 0 
						LET l_rec_account.ytd_pre_close_amt = 0 
						LET l_rec_account.budg1_amt = 0 
						LET l_rec_account.budg2_amt = 0 
						LET l_rec_account.budg3_amt = 0 
						LET l_rec_account.budg4_amt = 0 
						LET l_rec_account.budg5_amt = 0 
						LET l_rec_account.budg6_amt = 0 
						LET l_rec_account.open_amt = l_acct_bal 
						LET l_rec_account.bal_amt = l_acct_bal 
						INSERT INTO account VALUES (l_rec_account.*) 
					END IF 
					
					LET l_tot_amt = 0 
					LET modu_kandoo_periods = 0 
					SELECT max(period_num) INTO modu_kandoo_periods FROM period 
					WHERE cmpy_code = l_rec_company.cmpy_code 
					AND year_num = l_year_num 
					
					FOR i = 1 TO modu_kandoo_periods 
						OPEN c1_accounthist USING l_rec_company.cmpy_code, 
						l_acct_code, 
						l_year_num, 
						i 
						FETCH c1_accounthist INTO l_rec_accounthist.* 
						IF status = NOTFOUND THEN 
							INITIALIZE l_rec_accounthist.* TO NULL 
							LET l_rec_accounthist.cmpy_code = l_rec_company.cmpy_code 
							LET l_rec_accounthist.acct_code = l_acct_code 
							LET l_rec_accounthist.year_num = l_year_num 
							LET l_rec_accounthist.period_num = i 
							LET l_rec_accounthist.open_amt = 0 
							LET l_rec_accounthist.debit_amt = 0 
							LET l_rec_accounthist.credit_amt = 0 
							LET l_rec_accounthist.close_amt = 0 
							LET l_rec_accounthist.stats_qty = 0 
							LET l_rec_accounthist.pre_close_amt = 0 
							LET l_rec_accounthist.ytd_pre_close_amt = 0 
							LET l_rec_accounthist.hist_flag = "N" 
							LET l_rec_accounthist.budg1_amt = 0 
							LET l_rec_accounthist.budg2_amt = 0 
							LET l_rec_accounthist.budg3_amt = 0 
							LET l_rec_accounthist.budg4_amt = 0 
							LET l_rec_accounthist.budg5_amt = 0 
							LET l_rec_accounthist.budg6_amt = 0 
							LET l_rec_accounthist.ytd_budg1_amt = 0 
							LET l_rec_accounthist.ytd_budg2_amt = 0 
							LET l_rec_accounthist.ytd_budg3_amt = 0 
							LET l_rec_accounthist.ytd_budg4_amt = 0 
							LET l_rec_accounthist.ytd_budg5_amt = 0 
							LET l_rec_accounthist.ytd_budg6_amt = 0 

							INSERT INTO accounthist VALUES (l_rec_accounthist.*) 

						END IF 

						IF l_init_basis = "ZERO" THEN 
							LET l_budget_amt = 0 
						ELSE 
							LET l_budget_amt = get_init_amt(l_rec_company.cmpy_code, 
							l_acct_code, 
							i, 
							l_init_basis, 
							l_init_year, 
							l_change_per) 
						END IF 
						
						LET l_tot_amt = l_tot_amt + l_budget_amt 
						
						CASE l_init_budget_no 
							WHEN "1" 
								UPDATE accounthist 
								SET budg1_amt = l_budget_amt, 
								ytd_budg1_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
							WHEN "2" 
								UPDATE accounthist 
								SET budg2_amt = l_budget_amt, 
								ytd_budg2_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
							WHEN "3" 
								UPDATE accounthist 
								SET budg3_amt = l_budget_amt, 
								ytd_budg3_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
							WHEN "4" 
								UPDATE accounthist 
								SET budg4_amt = l_budget_amt, 
								ytd_budg4_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
							WHEN "5" 
								UPDATE accounthist 
								SET budg5_amt = l_budget_amt, 
								ytd_budg5_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
							WHEN "6" 
								UPDATE accounthist 
								SET budg6_amt = l_budget_amt, 
								ytd_budg6_amt = l_tot_amt 
								WHERE cmpy_code = l_rec_company.cmpy_code 
								AND acct_code = l_acct_code 
								AND year_num = l_year_num 
								AND period_num = i 
						END CASE 
					END FOR 
					
					CASE l_init_budget_no 
						WHEN "1" 
							UPDATE account 
							SET budg1_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
						WHEN "2" 
							UPDATE account 
							SET budg2_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
							
						WHEN "3" 
							UPDATE account 
							SET budg3_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
							
						WHEN "4" 
							UPDATE account 
							SET budg4_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
							
						WHEN "5" 
							UPDATE account 
							SET budg5_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
							
						WHEN "6" 
							UPDATE account 
							SET budg6_amt = l_tot_amt 
							WHERE cmpy_code = l_rec_company.cmpy_code 
							AND acct_code = l_acct_code 
							AND year_num = l_year_num 
					END CASE 
					
					IF int_flag OR quit_flag THEN 
						#8018 Extract Interrupted - Continue? (Y/N)
						IF kandoomsg("G",8018,"") = "N" THEN 
							LET int_flag = true 
							EXIT FOREACH 
						END IF 
					END IF 
				END FOREACH 
				
				IF int_flag OR quit_flag THEN 
					LET j = 0 
					ROLLBACK WORK 
				ELSE 
				COMMIT WORK 
			END IF 
			
			MESSAGE kandoomsg2("G",7018,j) 		#7018" n rows initialised
 
	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION



############################################################
# REPORT GSJ_rpt_list(p_cmpy_code,p_year_num,p_import_budget_no, 
#	p_acct_code,p_coa_type,p_accum_tot,p_file_tot) 
#
#
############################################################
REPORT GSJ_rpt_list(p_rpt_idx,p_cmpy_code,p_year_num,p_import_budget_no, 
	p_acct_code,p_coa_type,p_accum_tot,p_file_tot) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]		
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_year_num LIKE accounthist.year_num
	DEFINE p_import_budget_no CHAR(1)
	DEFINE p_acct_code LIKE accounthist.acct_code
	DEFINE p_coa_type LIKE coa.type_ind
	DEFINE p_accum_tot LIKE accounthist.budg1_amt
	DEFINE p_file_tot LIKE accounthist.budg1_amt
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_msg CHAR(3)
	DEFINE l_budget_text CHAR(80)
	DEFINE l_cmpy_head CHAR(80)
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 03,"Account Code", 
			COLUMN 22,"Description", 
			COLUMN 62,"Budget Total", 
			COLUMN 87,"File Total" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF p_year_num 
			#Will only ever be one year...
			SKIP 1 line 
			LET l_budget_text = NULL 
			CASE p_import_budget_no 
				WHEN "1" 
					LET l_budget_text = glob_rec_glparms.budg1_text 
				WHEN "2" 
					LET l_budget_text = glob_rec_glparms.budg2_text 
				WHEN "3" 
					LET l_budget_text = glob_rec_glparms.budg3_text 
				WHEN "4" 
					LET l_budget_text = glob_rec_glparms.budg4_text 
				WHEN "5" 
					LET l_budget_text = glob_rec_glparms.budg5_text 
				WHEN "6" 
					LET l_budget_text = glob_rec_glparms.budg6_text 
			END CASE 

			PRINT COLUMN 01,"Year: ", 
			COLUMN 07, p_year_num USING "###&", 
			COLUMN 13,"Budget: ", 
			COLUMN 21, p_import_budget_no, 
			COLUMN 23, l_budget_text 
			SKIP 1 line 

		ON EVERY ROW 
			LET l_rec_coa.desc_text = NULL 
			SELECT desc_text INTO l_rec_coa.desc_text FROM coa 
			WHERE cmpy_code = p_cmpy_code 
			AND acct_code = p_acct_code 
			IF l_rec_coa.desc_text IS NULL THEN 
				LET l_rec_coa.desc_text = "COA NOT found" 
			END IF 
			LET l_msg = NULL 
			IF p_accum_tot != p_file_tot 
			OR p_coa_type IS NULL THEN 
				LET l_msg = "***" 
			END IF 
			PRINT COLUMN 03, p_acct_code, 
			COLUMN 22, l_rec_coa.desc_text[1,37], 
			COLUMN 60, p_accum_tot USING "---,---,---,--&.&&", 
			COLUMN 79, p_file_tot USING "---,---,---,--&.&&", 
			COLUMN 98, l_msg 

		ON LAST ROW 
			NEED 7 LINES 
			PRINT COLUMN 60, "==================", 
			COLUMN 79, "==================" 
			PRINT COLUMN 03, "Report Total:", 
			COLUMN 60, sum(p_accum_tot) USING "---,---,---,--&.&&", 
			COLUMN 79, sum(p_file_tot) USING "---,---,---,--&.&&" 
			SKIP 3 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT 


############################################################
# REPORT GSJ_rpt_list_exp(p_rec_company) 
#
#
############################################################
REPORT GSJ_rpt_list_exp(p_rpt_idx,p_rec_company) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_company RECORD LIKE company.*
	DEFINE l_acct_code LIKE account.acct_code
	DEFINE l_budget_amt LIKE accounthist.budg1_amt 
	DEFINE l_query_text CHAR(150) 
	DEFINE i SMALLINT 

	OUTPUT 
--	left margin 0 
--	top margin 0 
--	bottom margin 0 
--	PAGE length 1 

	FORMAT 

		ON EVERY ROW 
			LET l_query_text = "SELECT total_amt FROM t_bdgthead ", 
			"WHERE acct_code = ?" 
			PREPARE s_t2_bdgttot FROM l_query_text 
			DECLARE c_t2_bdgttot CURSOR FOR s_t2_bdgttot 
			#
			LET l_query_text = "SELECT acct_code FROM t_bdgthead" 
			PREPARE s_t2_bdgthead FROM l_query_text 
			DECLARE c_t2_bdgthead CURSOR FOR s_t2_bdgthead 
			FOREACH c_t2_bdgthead INTO l_acct_code 
				PRINT COLUMN 01, l_acct_code,","; 
				FOR i = 1 TO modu_kandoo_periods 
					# Retrieve each COLUMN FROM temporary table
					LET l_query_text = "SELECT period",i USING "<<<"," FROM t_bdgthead", 
					" WHERE acct_code = ?" 
					PREPARE s_t2_bdgtper FROM l_query_text 
					DECLARE c_t2_bdgtper CURSOR FOR s_t2_bdgtper 
					OPEN c_t2_bdgtper USING l_acct_code 
					FETCH c_t2_bdgtper INTO l_budget_amt 
					IF l_budget_amt IS NULL THEN 
						LET l_budget_amt = 0 
					END IF 
					PRINT l_budget_amt USING "-&&&&&&&&&.&&",","; 
				END FOR 
				OPEN c_t2_bdgttot USING l_acct_code 
				FETCH c_t2_bdgttot INTO l_budget_amt 
				IF l_budget_amt IS NULL THEN 
					LET l_budget_amt = 0 
				END IF 
				PRINT l_budget_amt USING "-&&&&&&&&&.&&","," 
			END FOREACH 

			FREE c_t2_bdgtper 
			FREE c_t2_bdgttot 
			FREE c_t2_bdgthead 

END REPORT 

