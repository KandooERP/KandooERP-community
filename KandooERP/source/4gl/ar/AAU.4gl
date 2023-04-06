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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AA_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AAU_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_new_note CHAR(70) 
DEFINE modu_add_cnt INTEGER 
DEFINE modu_upd_cnt INTEGER 
DEFINE modu_del_cnt INTEGER 
DEFINE modu_heading CHAR(10) 
--DEFINE modu_log_date DATE 
#####################################################################
# FUNCTION AAU_main()
#
#
#####################################################################
FUNCTION AAU_main()
	DEFINE i INTEGER 

	CALL setModuleId("AAU")

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW U507 with FORM "U507" 
			CALL windecoration_u("U507") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title
		
			LET modu_heading = " Customer" 
		
			DISPLAY modu_heading TO heading	 
		
			MENU " Customer Audit" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AAU","menu-customer-audit") 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAU_rpt_process(AAU_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				COMMAND "Report" " SELECT Criteria AND PRINT REPORT" 
					CALL rpt_rmsreps_reset(NULL)
					CALL AAU_rpt_process(AAU_rpt_query())
		
--				COMMAND "Duplicate" " Re-PRINT previously printed information" 
--					CALL reprint() #not sure if we replace this xxxx fully
--					--LET glob_rec_rmsreps.report_text = NULL 
 
		
				COMMAND "Clear" " Clear out previously printed information" 
					SELECT count(*) INTO i FROM customeraudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND print_date IS NOT NULL 

					IF i != 0 THEN 
						#8012 Confirm TO delete i rows (Y/N)
						IF kandoomsg("U",8012,i) = "Y" THEN 
							WHENEVER ERROR CONTINUE 
							DELETE FROM customeraudit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND print_date IS NOT NULL 

							LET i = sqlca.sqlerrd[3] 
							IF status = -274 THEN 
								MESSAGE kandoomsg2("P",9049,"") 
								#9049 i audit rows deleted
							END IF 
							WHENEVER ERROR stop 
							WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

							MESSAGE kandoomsg2("U",7013,i) 
							#7013 i audit rows deleted
							NEXT option "Exit" 
						END IF 
					END IF 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
					EXIT MENU 
		
			END MENU 
	
			CLOSE WINDOW U507 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AAU_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW U507 with FORM "U507" 
			CALL windecoration_u("U507") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AAU_rpt_query()) #save where clause in env 
			CLOSE WINDOW U507 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AAU_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
#####################################################################
# END FUNCTION AAU_main()
#####################################################################


#####################################################################
# FUNCTION AAU_rpt_query()
#
#
#####################################################################
FUNCTION AAU_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_rec_customeraudit RECORD LIKE customeraudit.*
	DEFINE l_exp_date DATETIME year TO second
	DEFINE l_report_num LIKE nextnumber.next_num
	DEFINE l_log_date DATE
	--DEFINE l_rpt_output CHAR(50) 
	
	CLEAR FORM 
	LET l_log_date = today 

	INPUT l_log_date WITHOUT DEFAULTS FROM log_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AAU","inp-log_date") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_log_date IS NULL THEN 
					MESSAGE kandoomsg2("P",9048,"") 
					#9048 "Log Date must be entered"
					LET l_log_date = today 
					NEXT FIELD log_date 
				END IF 
			END IF 
			LET glob_rec_rpt_selector.ref1_date = l_log_date
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		RETURN l_log_date 
	END IF 
	
END FUNCTION
#####################################################################
# END FUNCTION AAU_rpt_query()
#####################################################################

	
#####################################################################
# FUNCTION AAU_rpt_process()
#
#
#####################################################################
FUNCTION AAU_rpt_process(p_log_date) 
	DEFINE p_log_date DATE
	DEFINE l_rpt_idx SMALLINT	
	--DEFINE l_where_text STRING
	DEFINE l_rec_customeraudit RECORD LIKE customeraudit.*
	DEFINE l_exp_date DATETIME year TO second
	DEFINE l_report_num LIKE nextnumber.next_num

	--DEFINE l_rpt_output CHAR(50) 


	#------------------------------------------------------------
	#### First Report - Additions ###

	IF (p_log_date IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_add",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_add TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET l_exp_date = p_log_date 
	LET l_exp_date = l_exp_date + 1 units day - 1 units second 
	SELECT next_num INTO l_report_num FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = "AAU" 

	#------------------------------------------------------------
	#### First Report - Additions ###

	LET modu_new_note = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped, " - Additions" 
	LET modu_new_note = modu_new_note clipped, " (Menu-AAU) Report No: ", 
	l_report_num USING "<<<&" 
	#------------------------------------------------------------


	LET modu_add_cnt = 0 

	SELECT unique 1 FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "1" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 

	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Inserted Customer:",NULL,NULL,l_rpt_idx) THEN
			RETURN FALSE 
		END IF 
		#---------------------------------------------------------
	ELSE 
		--DISPLAY "Inserted Customer." at 1,2 
		DECLARE add_curs CURSOR FOR 
		SELECT * FROM customeraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "1" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY cust_code 

		FOREACH add_curs INTO l_rec_customeraudit.* 
			LET modu_add_cnt = modu_add_cnt + 1 
--			DISPLAY l_rec_customeraudit.cust_code at 1,20 
			#---------------------------------------------------------
			OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
			IF NOT rpt_int_flag_handler2("Inserted Customer:",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
				RETURN FALSE 
			END IF 
			#---------------------------------------------------------			
			UPDATE customeraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_customeraudit.cmpy_code 
			AND cust_code = l_rec_customeraudit.cust_code 
			AND audit_ind = l_rec_customeraudit.audit_ind 
			AND audit_date = l_rec_customeraudit.audit_date 
		END FOREACH 

	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_add
	CALL rpt_finish("AAU_rpt_list_add")
	#------------------------------------------------------------

	#### Second Report - Alterations ###
	# AAU_rpt_list_upd
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_upd",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_upd TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET modu_new_note = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped, " - Alterations" 
	LET modu_new_note = modu_new_note clipped, " (Menu-AAU) Report No: ", 
	l_report_num USING "<<<&" 
		
	LET modu_upd_cnt = 0 

	SELECT unique 1 FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "2" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 

	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Modified Customer",NULL,NULL,l_rpt_idx) THEN
			RETURN FALSE 
		END IF 
		#---------------------------------------------------------		
	ELSE 
		DISPLAY "Modified Customer." at 1,2 
		DECLARE upd_curs CURSOR FOR 
		SELECT * FROM customeraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "2" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY cust_code, audit_date 
		FOREACH upd_curs INTO l_rec_customeraudit.* 
			LET modu_upd_cnt = modu_upd_cnt + 1 
--			DISPLAY l_rec_customeraudit.cust_code at 1,20 

			#---------------------------------------------------------
			OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
			IF NOT rpt_int_flag_handler2("Modified Customer",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
				RETURN FALSE 
			END IF 
			#---------------------------------------------------------		

			UPDATE customeraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_customeraudit.cmpy_code 
			AND cust_code = l_rec_customeraudit.cust_code 
			AND audit_ind = l_rec_customeraudit.audit_ind 
			AND audit_date = l_rec_customeraudit.audit_date 
		END FOREACH 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_upd
	CALL rpt_finish("AAU_rpt_list_upd")
	#------------------------------------------------------------
	  
	#### Third Report - Deletions ###
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_del",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_del TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	
	LET modu_new_note = modu_new_note clipped, " (Menu-AAU) Report No: ", 
	l_report_num USING "<<<&" 

	LET modu_del_cnt = 0 

	SELECT unique 1 FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "3" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 
	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_del(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Deleted Customer",NULL,NULL,l_rpt_idx) THEN
			RETURN FALSE 
		END IF 
		#---------------------------------------------------------	
 
	ELSE 
		--DISPLAY "Deleted Customer.." at 1,2 
		DECLARE del_curs CURSOR FOR 
		SELECT * FROM customeraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "3" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY cust_code 
		FOREACH del_curs INTO l_rec_customeraudit.* 
			LET modu_del_cnt = modu_del_cnt + 1 
--			DISPLAY l_rec_customeraudit.cust_code at 1,20 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_del(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Deleted Customer",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
			RETURN FALSE 
		END IF 
		#---------------------------------------------------------	
			UPDATE customeraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_customeraudit.cmpy_code 
			AND cust_code = l_rec_customeraudit.cust_code 
			AND audit_ind = l_rec_customeraudit.audit_ind 
			AND audit_date = l_rec_customeraudit.audit_date 
		END FOREACH 

	END IF 


	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_del
	CALL rpt_finish("AAU_rpt_list_del")
	#------------------------------------------------------------

	UPDATE nextnumber 
	SET next_num = l_report_num + 1 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = "AAU" 
	RETURN true 
END FUNCTION 
#####################################################################
# END FUNCTION AAU_rpt_process()
#####################################################################


#####################################################################
# FUNCTION reprint()
#
#
#####################################################################
FUNCTION reprint(p_log_date) 
	DEFINE p_log_date DATE
	DEFINE l_rpt_idx SMALLINT	
	DEFINE l_rec_customeraudit RECORD LIKE customeraudit.* 
	--DEFINE glob_rec_rmsreps.file_text CHAR(50) 

	#------------------------------------------------------------
	IF (p_log_date IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_add",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_add TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

 
	#### First Report - Additions ###
--	LET modu_new_note = glob_rec_rmsreps.report_text clipped, " - Additions REPRINT" 

	DECLARE add_rp_curs CURSOR FOR 
	SELECT * FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "1" 
	AND print_date IS NOT NULL 
	ORDER BY cust_code 



--	DISPLAY " Customer.." at 1,2 
	LET modu_add_cnt = 0 

	FOREACH add_rp_curs INTO l_rec_customeraudit.* 
		LET modu_add_cnt = modu_add_cnt + 1 
		DISPLAY l_rec_customeraudit.cust_code at 1,20 

		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
			
	END FOREACH 

	IF modu_add_cnt = 0 THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_add(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
			RETURN FALSE
		END IF 
		#--------------------------------------------------------- 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_add
	CALL rpt_finish("AAU_rpt_list_add")
	#------------------------------------------------------------
	
	
	#### Second Report - Alterations ###

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_upd",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_upd TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	LET modu_new_note = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_text clipped, " - Alterations REPRINT" 

	DECLARE upd_rp_curs CURSOR FOR 
	SELECT * FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "2" 
	AND print_date IS NOT NULL 
	ORDER BY cust_code, audit_date 
	LET modu_upd_cnt = 0 

	FOREACH upd_rp_curs INTO l_rec_customeraudit.* 
		LET modu_upd_cnt = modu_upd_cnt + 1 
--		DISPLAY l_rec_customeraudit.cust_code at 1,20 

		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_upd(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
			EXIT FOREACH
		END IF 
		#--------------------------------------------------------- 
		
	END FOREACH 

	IF modu_upd_cnt = 0 THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_upd(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customeraudit.cust_code,NULL,l_rpt_idx) THEN
			RETURN FALSE
		END IF 
		#--------------------------------------------------------- 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_upd
	CALL rpt_finish("AAU_rpt_list_upd")
	#------------------------------------------------------------

	#
	#### Third Report - Deletions ###
--	LET modu_new_note = glob_rec_rmsreps.report_text clipped, " - Deletions REPRINT" 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"AAU_rpt_list_del",p_log_date, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AAU_rpt_list_del TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE del_rp_curs CURSOR FOR 
	SELECT * FROM customeraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "3" 
	AND print_date IS NOT NULL 
	ORDER BY cust_code 
	LET modu_del_cnt = 0 
	FOREACH del_rp_curs INTO l_rec_customeraudit.* 
		LET modu_del_cnt = modu_del_cnt + 1 
--		DISPLAY l_rec_customeraudit.cust_code at 1,20 

		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_del(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Deleted Customer",NULL,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------			
	END FOREACH 

	IF modu_del_cnt = 0 THEN 
		INITIALIZE l_rec_customeraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT AAU_rpt_list_del(l_rpt_idx,l_rec_customeraudit.*) 
		IF NOT rpt_int_flag_handler2("Deleted Customer",NULL,NULL,l_rpt_idx) THEN
			RETURN FALSE 
		END IF 
		#---------------------------------------------------------		 
	END IF 

	#------------------------------------------------------------
	FINISH REPORT AAU_rpt_list_del
	CALL rpt_finish("AAU_rpt_list_del")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 	
END FUNCTION 
#####################################################################
# END FUNCTION reprint()
#####################################################################


#####################################################################
# REPORT AAU_rpt_list_add(p_rec_customeraudit)
#
#
#####################################################################
REPORT AAU_rpt_list_add(p_rpt_idx,p_rec_customeraudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customeraudit RECORD LIKE customeraudit.*
	DEFINE l_cmpy_head CHAR(132)
	DEFINE l_i SMALLINT 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_customeraudit.cust_code, p_rec_customeraudit.audit_date 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Customer", 
			COLUMN 10, "Name/Contact Details", 
			COLUMN 41, "Address", 
			COLUMN 71, "Type Term Terr. Salesper", 
			COLUMN 96, "Lang Stm Ord Inv Stmt Tax Details" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			NEED 7 LINES 
			IF p_rec_customeraudit.cust_code IS NOT NULL THEN 
				PRINT COLUMN 01, p_rec_customeraudit.cust_code, 
				COLUMN 10, p_rec_customeraudit.name_text, 
				COLUMN 41, p_rec_customeraudit.addr1_text, 
				COLUMN 72, p_rec_customeraudit.type_code, 
				COLUMN 77, p_rec_customeraudit.term_code, 
				COLUMN 81, p_rec_customeraudit.territory_code, 
				COLUMN 87, p_rec_customeraudit.sale_code, 
				COLUMN 97, p_rec_customeraudit.language_code, 
				COLUMN 101, p_rec_customeraudit.dun_code, 
				COLUMN 106, p_rec_customeraudit.ord_text_ind, 
				COLUMN 110, p_rec_customeraudit.inv_level_ind, 
				COLUMN 114, p_rec_customeraudit.stmnt_ind, 
				COLUMN 118, p_rec_customeraudit.tax_code, 
				COLUMN 120, p_rec_customeraudit.tax_num_text[1,11] 
				IF p_rec_customeraudit.addr2_text IS NULL THEN 
					LET p_rec_customeraudit.addr2_text = p_rec_customeraudit.city_text 
					LET p_rec_customeraudit.city_text = NULL 
				END IF 
				PRINT COLUMN 05, "Att:", 
				COLUMN 10, p_rec_customeraudit.contact_text; 
				IF p_rec_customeraudit.addr2_text IS NOT NULL THEN 
					PRINT COLUMN 41, p_rec_customeraudit.addr2_text 
				ELSE 
					PRINT COLUMN 41, p_rec_customeraudit.state_code clipped, " ", 
					p_rec_customeraudit.post_code clipped, " ", 
					p_rec_customeraudit.country_code clipped --@db-patch_2020_10_04 report--
					LET p_rec_customeraudit.state_code = NULL 
					LET p_rec_customeraudit.post_code = NULL 
					LET p_rec_customeraudit.country_code = NULL --@db-patch_2020_10_04 report-- 
				END IF 
				PRINT COLUMN 05, "Ph: ", 
				COLUMN 10, p_rec_customeraudit.tele_text; 

				IF p_rec_customeraudit.city_text IS NOT NULL THEN 
					PRINT COLUMN 41, p_rec_customeraudit.city_text; 
				ELSE 
					PRINT COLUMN 41, p_rec_customeraudit.state_code clipped, " ", 
					p_rec_customeraudit.post_code clipped, " ", 
					p_rec_customeraudit.country_code clipped; --@db-patch_2020_10_04 report--
					LET p_rec_customeraudit.state_code = NULL 
					LET p_rec_customeraudit.post_code = NULL 
					LET p_rec_customeraudit.country_code = NULL --@db-patch_2020_10_04 report-- 
				END IF 

				PRINT COLUMN 82, "Bank Account: ", 
				COLUMN 96, p_rec_customeraudit.bank_acct_code 
				PRINT COLUMN 05, "Mob:", 
				COLUMN 10, p_rec_customeraudit.mobile_phone, 
				COLUMN 41, p_rec_customeraudit.state_code clipped, " ", 
				p_rec_customeraudit.post_code clipped, " ", 
				p_rec_customeraudit.country_code clipped, --@db-patch_2020_10_04 report--
				COLUMN 82, "Credit Limit:", 
				COLUMN 96, p_rec_customeraudit.cred_limit_amt 
				USING "<<<<<<<<<<<<<&.&&", 
				COLUMN 116,"ABN: ",p_rec_customeraudit.vat_code 
				IF glob_rec_arparms.ref1_ind matches "[1-4]" 
				OR glob_rec_arparms.ref2_ind matches "[1-4]" 
				OR glob_rec_arparms.ref3_ind matches "[1-4]" 
				OR glob_rec_arparms.ref4_ind matches "[1-4]" 
				OR glob_rec_arparms.ref5_ind matches "[1-4]" 
				OR glob_rec_arparms.ref6_ind matches "[1-4]" 
				OR glob_rec_arparms.ref7_ind matches "[1-4]" 
				OR glob_rec_arparms.ref8_ind matches "[1-4]" THEN 
					PRINT COLUMN 05, "Reporting Codes: "; 
				END IF 
				IF glob_rec_arparms.ref1_ind matches "[1-4]" THEN 
					PRINT COLUMN 22, "(1)", 
					COLUMN 25, p_rec_customeraudit.ref1_code; 
				END IF 
				IF glob_rec_arparms.ref2_ind matches "[1-4]" THEN 
					PRINT COLUMN 36, "(2)", 
					COLUMN 39, p_rec_customeraudit.ref2_code; 
				END IF 
				IF glob_rec_arparms.ref3_ind matches "[1-4]" THEN 
					PRINT COLUMN 50, "(3)", 
					COLUMN 53, p_rec_customeraudit.ref3_code; 
				END IF 
				IF glob_rec_arparms.ref4_ind matches "[1-4]" THEN 
					PRINT COLUMN 64, "(4)", 
					COLUMN 67, p_rec_customeraudit.ref4_code; 
				END IF 
				PRINT COLUMN 82, "User: ", 
				COLUMN 96, p_rec_customeraudit.user_code, 
				COLUMN 105, p_rec_customeraudit.audit_date 
				IF glob_rec_arparms.ref5_ind matches "[1-4]" THEN 
					PRINT COLUMN 22, "(5)", 
					COLUMN 25, p_rec_customeraudit.ref5_code; 
				END IF 
				IF glob_rec_arparms.ref6_ind matches "[1-4]" THEN 
					PRINT COLUMN 36, "(6)", 
					COLUMN 39, p_rec_customeraudit.ref6_code; 
				END IF 
				IF glob_rec_arparms.ref7_ind matches "[1-4]" THEN 
					PRINT COLUMN 50, "(7)", 
					COLUMN 53, p_rec_customeraudit.ref7_code; 
				END IF 
				IF glob_rec_arparms.ref8_ind matches "[1-4]" THEN 
					PRINT COLUMN 64, "(8)", 
					COLUMN 67, p_rec_customeraudit.ref8_code; 
				END IF 
				PRINT COLUMN 132, " " 
			END IF 
			SKIP 1 line 

		ON LAST ROW 
			NEED 9 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 15, "Total Customer Additions: ", 
			COLUMN 39, modu_add_cnt USING "<<<<&" 
			SKIP 3 line 
			PRINT COLUMN 1, "Selection Criteria : ", glob_arr_rec_rpt_rmsreps[p_rpt_idx].ref1_date USING "dd/mm/yy" 
			SKIP 1 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT 
#####################################################################
# END REPORT AAU_rpt_list_add(p_rec_customeraudit)
#####################################################################


#####################################################################
# REPORT AAU_rpt_list_upd(p_rec_customeraudit)
#
#
#####################################################################
REPORT AAU_rpt_list_upd(p_rpt_idx,p_rec_customeraudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_customeraudit RECORD LIKE customeraudit.*
	DEFINE l_rec_s_customeraudit RECORD LIKE customeraudit.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_cmpy_head CHAR(132)
	DEFINE l_col2 SMALLINT
	DEFINE l_col SMALLINT 
	DEFINE l_table CHAR(13)
	 
	OUTPUT 
 
	ORDER external BY p_rec_customeraudit.cust_code,	p_rec_customeraudit.audit_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 01, "Customer", COLUMN 21, 
			"Old Values", COLUMN 62, 
			"New Values", COLUMN 103, 
			"User", COLUMN 112, 
			"Date", COLUMN 123, 
			"Time" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW NEED 10 LINES 
			DECLARE c_vaudit CURSOR FOR 
			SELECT * 
			FROM customeraudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = p_rec_customeraudit.cust_code 
			AND audit_date > p_rec_customeraudit.audit_date 
			ORDER BY audit_date 
			OPEN c_vaudit 
			FETCH c_vaudit INTO l_rec_s_customeraudit.* 

			IF status = NOTFOUND THEN 
				LET l_table = "Customer"
				CALL db_customer_get_rec(UI_OFF,p_rec_customeraudit.cust_code) RETURNING l_rec_customer.*	 
--				SELECT * INTO l_rec_customer.* 
--				FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = p_rec_customeraudit.cust_code 
		IF l_rec_customer.cust_code IS NULL THEN			
--		IF status = NOTFOUND THEN 
					INITIALIZE l_rec_customer.* TO NULL 
				END IF 
			ELSE 
				LET l_table = "Customeraudit" 
			END IF 

			IF l_table = "Customeraudit" THEN 
				#Check TO see IF printout IS required. This problem IS caused by
				#the ' UPDATE customer SET * = l_rec_customer.* ' all over the code
				IF NOT table1_mods(l_rec_s_customeraudit.*, p_rec_customeraudit.*) THEN 
					IF modu_upd_cnt > 0 THEN 
						LET modu_upd_cnt = modu_upd_cnt - 1 
					END IF 
				ELSE 
					PRINT COLUMN 01, 
					p_rec_customeraudit.cust_code, COLUMN 103, 
					p_rec_customeraudit.user_code, COLUMN 112, 
					p_rec_customeraudit.audit_date 
					IF (l_rec_s_customeraudit.name_text IS NULL 
					AND p_rec_customeraudit.name_text IS NOT null) 
					OR (p_rec_customeraudit.name_text IS NULL 
					AND l_rec_s_customeraudit.name_text IS NOT null) 
					OR (l_rec_s_customeraudit.name_text != p_rec_customeraudit.name_text) THEN 
						PRINT COLUMN 04, 
						"Name:", COLUMN 21, 
						p_rec_customeraudit.name_text, COLUMN 62, 
						l_rec_s_customeraudit.name_text 
					END IF 
					IF (l_rec_s_customeraudit.addr1_text IS NULL 
					AND p_rec_customeraudit.addr1_text IS NOT null) 
					OR (p_rec_customeraudit.addr1_text IS NULL 
					AND l_rec_s_customeraudit.addr1_text IS NOT null) 
					OR (l_rec_s_customeraudit.addr1_text != p_rec_customeraudit.addr1_text) 
					THEN 
						PRINT COLUMN 04, "Address Line 1:", COLUMN 21, 
						p_rec_customeraudit.addr1_text, COLUMN 62, 
						l_rec_s_customeraudit.addr1_text 
					END IF 
					IF (l_rec_s_customeraudit.addr2_text IS NULL 
					AND p_rec_customeraudit.addr2_text IS NOT null) 
					OR (p_rec_customeraudit.addr2_text IS NULL 
					AND l_rec_s_customeraudit.addr2_text IS NOT null) 
					OR (l_rec_s_customeraudit.addr2_text != p_rec_customeraudit.addr2_text) 
					THEN 
						PRINT COLUMN 04, "Address Line 2:", COLUMN 21, 
						p_rec_customeraudit.addr2_text, COLUMN 62, 
						l_rec_s_customeraudit.addr2_text 
					END IF 
					IF (l_rec_s_customeraudit.city_text IS NULL 
					AND p_rec_customeraudit.city_text IS NOT null) 
					OR (p_rec_customeraudit.city_text IS NULL 
					AND l_rec_s_customeraudit.city_text IS NOT null) 
					OR (l_rec_s_customeraudit.city_text != p_rec_customeraudit.city_text) THEN 
						PRINT COLUMN 04, "City:", COLUMN 21, 
						p_rec_customeraudit.city_text, COLUMN 62, 
						l_rec_s_customeraudit.city_text 
					END IF 
					IF (l_rec_s_customeraudit.state_code IS NULL 
					AND p_rec_customeraudit.state_code IS NOT null) 
					OR (p_rec_customeraudit.state_code IS NULL 
					AND l_rec_s_customeraudit.state_code IS NOT null) 
					OR (l_rec_s_customeraudit.state_code != p_rec_customeraudit.state_code) 
					THEN 
						PRINT COLUMN 04, "State:", COLUMN 21, 
						p_rec_customeraudit.state_code, COLUMN 62, 
						l_rec_s_customeraudit.state_code 
					END IF 
					IF (l_rec_s_customeraudit.post_code IS NULL 
					AND p_rec_customeraudit.post_code IS NOT null) 
					OR (p_rec_customeraudit.post_code IS NULL 
					AND l_rec_s_customeraudit.post_code IS NOT null) 
					OR (l_rec_s_customeraudit.post_code != p_rec_customeraudit.post_code) THEN 
						PRINT COLUMN 04, "Post Code:", COLUMN 21, 
						p_rec_customeraudit.post_code, COLUMN 62, 
						l_rec_s_customeraudit.post_code 
					END IF 
					IF (l_rec_s_customeraudit.country_code IS NULL 
					AND p_rec_customeraudit.country_code IS NOT null) 
					OR (p_rec_customeraudit.country_code IS NULL 
					AND l_rec_s_customeraudit.country_code IS NOT null) 
					OR (l_rec_s_customeraudit.country_code != p_rec_customeraudit.country_code) 
					THEN 
						PRINT COLUMN 04, "Country Code:", COLUMN 21, 
						p_rec_customeraudit.country_code, COLUMN 62, 
						l_rec_s_customeraudit.country_code 
					END IF 
					IF (l_rec_s_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
					AND p_rec_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
					OR (p_rec_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
					AND l_rec_s_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
					OR (l_rec_s_customeraudit.country_code != p_rec_customeraudit.country_code) --@db-patch_2020_10_04 report--
					THEN 
						PRINT COLUMN 04, "Country Text:", COLUMN 21, 
						p_rec_customeraudit.country_code, COLUMN 62, --@db-patch_2020_10_04 report--
						l_rec_s_customeraudit.country_code --@db-patch_2020_10_04 report--
					END IF 
					IF (l_rec_s_customeraudit.language_code IS NULL 
					AND p_rec_customeraudit.language_code IS NOT null) 
					OR (p_rec_customeraudit.language_code IS NULL 
					AND l_rec_s_customeraudit.language_code IS NOT null) 
					OR (l_rec_s_customeraudit.language_code != 
					p_rec_customeraudit.language_code ) THEN 
						PRINT COLUMN 04, "Language Code:", COLUMN 21, 
						p_rec_customeraudit.language_code, COLUMN 62, 
						l_rec_s_customeraudit.language_code 
					END IF 
					IF (l_rec_s_customeraudit.type_code IS NULL 
					AND p_rec_customeraudit.type_code IS NOT null) 
					OR (p_rec_customeraudit.type_code IS NULL 
					AND l_rec_s_customeraudit.type_code IS NOT null) 
					OR (l_rec_s_customeraudit.type_code != p_rec_customeraudit.type_code) THEN 
						PRINT COLUMN 04, "Customer Type Code:", COLUMN 21, 
						p_rec_customeraudit.type_code, COLUMN 62, 
						l_rec_s_customeraudit.type_code 
					END IF 
					IF (l_rec_s_customeraudit.sale_code IS NULL 
					AND p_rec_customeraudit.sale_code IS NOT null) 
					OR (p_rec_customeraudit.sale_code IS NULL 
					AND l_rec_s_customeraudit.sale_code IS NOT null) 
					OR (l_rec_s_customeraudit.sale_code != p_rec_customeraudit.sale_code) THEN 
						PRINT COLUMN 04, "Customer Sale Code:", COLUMN 21, 
						p_rec_customeraudit.sale_code, COLUMN 62, 
						l_rec_s_customeraudit.sale_code 
					END IF 
					IF (l_rec_s_customeraudit.term_code IS NULL 
					AND p_rec_customeraudit.term_code IS NOT null) 
					OR (p_rec_customeraudit.term_code IS NULL 
					AND l_rec_s_customeraudit.term_code IS NOT null) 
					OR (l_rec_s_customeraudit.term_code != p_rec_customeraudit.term_code) THEN 
						PRINT COLUMN 04, "Customer Term Code:", COLUMN 21, 
						p_rec_customeraudit.term_code, COLUMN 62, 
						l_rec_s_customeraudit.term_code 
					END IF 
					IF (l_rec_s_customeraudit.tax_code IS NULL 
					AND p_rec_customeraudit.tax_code IS NOT null) 
					OR (p_rec_customeraudit.tax_code IS NULL 
					AND l_rec_s_customeraudit.tax_code IS NOT null) 
					OR (l_rec_s_customeraudit.tax_code != p_rec_customeraudit.tax_code) THEN 
						PRINT COLUMN 04, "Customer Tax Code:", COLUMN 21, 
						p_rec_customeraudit.tax_code, COLUMN 62, 
						l_rec_s_customeraudit.tax_code 
					END IF 
					IF (l_rec_s_customeraudit.tax_num_text IS NULL 
					AND p_rec_customeraudit.tax_num_text IS NOT null) 
					OR (p_rec_customeraudit.tax_num_text IS NULL 
					AND l_rec_s_customeraudit.tax_num_text IS NOT null) 
					OR (l_rec_s_customeraudit.tax_num_text != p_rec_customeraudit.tax_num_text) 
					THEN 
						PRINT COLUMN 04, "Tax Number:", COLUMN 21, 
						p_rec_customeraudit.tax_num_text, COLUMN 62, 
						l_rec_s_customeraudit.tax_num_text 
					END IF 
					IF (l_rec_s_customeraudit.contact_text IS NULL 
					AND p_rec_customeraudit.contact_text IS NOT null) 
					OR (p_rec_customeraudit.contact_text IS NULL 
					AND l_rec_s_customeraudit.contact_text IS NOT null) 
					OR (l_rec_s_customeraudit.contact_text != p_rec_customeraudit.contact_text) 
					THEN 
						PRINT COLUMN 04, "Contact:", COLUMN 21, 
						p_rec_customeraudit.contact_text, COLUMN 62, 
						l_rec_s_customeraudit.contact_text 
					END IF 
					IF (l_rec_s_customeraudit.tele_text IS NULL 
					AND p_rec_customeraudit.tele_text IS NOT null) 
					OR (p_rec_customeraudit.tele_text IS NULL 
					AND l_rec_s_customeraudit.tele_text IS NOT null) 
					OR (l_rec_s_customeraudit.tele_text != p_rec_customeraudit.tele_text) THEN 
						PRINT COLUMN 04, "Telephone:", COLUMN 21, 
						p_rec_customeraudit.tele_text, COLUMN 62, 
						l_rec_s_customeraudit.tele_text 
					END IF 
					IF (l_rec_s_customeraudit.cred_limit_amt IS NULL 
					AND p_rec_customeraudit.cred_limit_amt IS NOT null) 
					OR (p_rec_customeraudit.cred_limit_amt IS NULL 
					AND l_rec_s_customeraudit.cred_limit_amt IS NOT null) 
					OR (l_rec_s_customeraudit.cred_limit_amt != 
					p_rec_customeraudit.cred_limit_amt ) THEN 
						PRINT COLUMN 04, "Credit Limit:", COLUMN 21, 
						p_rec_customeraudit.cred_limit_amt USING "<<<<<<<<<<<<<&.&&", COLUMN 62, 
						l_rec_s_customeraudit.cred_limit_amt USING "<<<<<<<<<<<<<&.&&" 
					END IF 
					IF (l_rec_s_customeraudit.hold_code IS NULL 
					AND p_rec_customeraudit.hold_code IS NOT null) 
					OR (p_rec_customeraudit.hold_code IS NULL 
					AND l_rec_s_customeraudit.hold_code IS NOT null) 
					OR (l_rec_s_customeraudit.hold_code != p_rec_customeraudit.hold_code) THEN 
						PRINT COLUMN 04, "Hold Code:", COLUMN 21, 
						p_rec_customeraudit.hold_code, COLUMN 62, 
						l_rec_s_customeraudit.hold_code 
					END IF 
					IF (l_rec_s_customeraudit.inv_level_ind IS NULL 
					AND p_rec_customeraudit.inv_level_ind IS NOT null) 
					OR (p_rec_customeraudit.inv_level_ind IS NULL 
					AND l_rec_s_customeraudit.inv_level_ind IS NOT null) 
					OR (l_rec_s_customeraudit.inv_level_ind != 
					p_rec_customeraudit.inv_level_ind ) THEN 
						PRINT COLUMN 04, "Level Indicator:", COLUMN 21, 
						p_rec_customeraudit.inv_level_ind, COLUMN 62, 
						l_rec_s_customeraudit.inv_level_ind 
					END IF 
					IF (l_rec_s_customeraudit.dun_code IS NULL 
					AND p_rec_customeraudit.dun_code IS NOT null) 
					OR (p_rec_customeraudit.dun_code IS NULL 
					AND l_rec_s_customeraudit.dun_code IS NOT null) 
					OR (l_rec_s_customeraudit.dun_code != p_rec_customeraudit.dun_code) THEN 
						PRINT COLUMN 04, "Statement Code:", COLUMN 21, 
						p_rec_customeraudit.dun_code, COLUMN 62, 
						l_rec_s_customeraudit.dun_code 
					END IF 
					IF (l_rec_s_customeraudit.stmnt_ind IS NULL 
					AND p_rec_customeraudit.stmnt_ind IS NOT null) 
					OR (p_rec_customeraudit.stmnt_ind IS NULL 
					AND l_rec_s_customeraudit.stmnt_ind IS NOT null) 
					OR (l_rec_s_customeraudit.stmnt_ind != p_rec_customeraudit.stmnt_ind) THEN 
						PRINT COLUMN 04, "Statement Ind:", COLUMN 21, 
						p_rec_customeraudit.stmnt_ind, COLUMN 62, 
						l_rec_s_customeraudit.stmnt_ind 
					END IF 
					IF (l_rec_s_customeraudit.bank_acct_code IS NULL 
					AND p_rec_customeraudit.bank_acct_code IS NOT null) 
					OR (p_rec_customeraudit.bank_acct_code IS NULL 
					AND l_rec_s_customeraudit.bank_acct_code IS NOT null) 
					OR (l_rec_s_customeraudit.bank_acct_code != 
					p_rec_customeraudit.bank_acct_code ) THEN 
						PRINT COLUMN 04, "Bank Code:", COLUMN 21, 
						p_rec_customeraudit.bank_acct_code, COLUMN 62, 
						l_rec_s_customeraudit.bank_acct_code 
					END IF 
					IF (l_rec_s_customeraudit.territory_code IS NULL 
					AND p_rec_customeraudit.territory_code IS NOT null) 
					OR (p_rec_customeraudit.territory_code IS NULL 
					AND l_rec_s_customeraudit.territory_code IS NOT null) 
					OR (l_rec_s_customeraudit.territory_code != 
					p_rec_customeraudit.territory_code ) THEN 
						PRINT COLUMN 04, "Territory Code:", COLUMN 21, 
						p_rec_customeraudit.territory_code, COLUMN 62, 
						l_rec_s_customeraudit.territory_code 
					END IF 
					IF (l_rec_s_customeraudit.delete_flag IS NULL 
					AND p_rec_customeraudit.delete_flag IS NOT null) 
					OR (p_rec_customeraudit.delete_flag IS NULL 
					AND l_rec_s_customeraudit.delete_flag IS NOT null) 
					OR (l_rec_s_customeraudit.delete_flag != p_rec_customeraudit.delete_flag) 
					THEN 
						PRINT COLUMN 04, "Delete Flag:", COLUMN 21, 
						p_rec_customeraudit.delete_flag, COLUMN 62, 
						l_rec_s_customeraudit.delete_flag 
					END IF 
					IF (l_rec_s_customeraudit.delete_date IS NULL 
					AND p_rec_customeraudit.delete_date IS NOT null) 
					OR (p_rec_customeraudit.delete_date IS NULL 
					AND l_rec_s_customeraudit.delete_date IS NOT null) 
					OR (l_rec_s_customeraudit.delete_date != p_rec_customeraudit.delete_date) 
					THEN 
						PRINT COLUMN 04, "Delete Date:", COLUMN 21, 
						p_rec_customeraudit.delete_date, COLUMN 62, 
						l_rec_s_customeraudit.delete_date 
					END IF 
					IF (l_rec_s_customeraudit.ref1_code IS NULL 
					AND p_rec_customeraudit.ref1_code IS NOT null) 
					OR (p_rec_customeraudit.ref1_code IS NULL 
					AND l_rec_s_customeraudit.ref1_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref1_code != p_rec_customeraudit.ref1_code) THEN 
						PRINT COLUMN 04, "Reference 1:", COLUMN 21, 
						p_rec_customeraudit.ref1_code, COLUMN 62, 
						l_rec_s_customeraudit.ref1_code 
					END IF 
					IF (l_rec_s_customeraudit.ref2_code IS NULL 
					AND p_rec_customeraudit.ref2_code IS NOT null) 
					OR (p_rec_customeraudit.ref2_code IS NULL 
					AND l_rec_s_customeraudit.ref2_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref2_code != p_rec_customeraudit.ref2_code) THEN 
						PRINT COLUMN 04, "Reference 2:", COLUMN 21, 
						p_rec_customeraudit.ref2_code, COLUMN 62, 
						l_rec_s_customeraudit.ref2_code 
					END IF 
					IF (l_rec_s_customeraudit.ref3_code IS NULL 
					AND p_rec_customeraudit.ref3_code IS NOT null) 
					OR (p_rec_customeraudit.ref3_code IS NULL 
					AND l_rec_s_customeraudit.ref3_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref3_code != p_rec_customeraudit.ref3_code) THEN 
						PRINT COLUMN 04, "Reference 3:", COLUMN 21, 
						p_rec_customeraudit.ref3_code, COLUMN 62, 
						l_rec_s_customeraudit.ref3_code 
					END IF 
					IF (l_rec_s_customeraudit.ref4_code IS NULL 
					AND p_rec_customeraudit.ref4_code IS NOT null) 
					OR (p_rec_customeraudit.ref4_code IS NULL 
					AND l_rec_s_customeraudit.ref4_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref4_code != p_rec_customeraudit.ref4_code) THEN 
						PRINT COLUMN 04, "Reference 4:", COLUMN 21, 
						p_rec_customeraudit.ref4_code, COLUMN 62, 
						l_rec_s_customeraudit.ref4_code 
					END IF 
					IF (l_rec_s_customeraudit.ref5_code IS NULL 
					AND p_rec_customeraudit.ref5_code IS NOT null) 
					OR (p_rec_customeraudit.ref5_code IS NULL 
					AND l_rec_s_customeraudit.ref5_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref5_code != p_rec_customeraudit.ref5_code) THEN 
						PRINT COLUMN 04, "Reference 5:", COLUMN 21, 
						p_rec_customeraudit.ref5_code, COLUMN 62, 
						l_rec_s_customeraudit.ref5_code 
					END IF 
					IF (l_rec_s_customeraudit.ref6_code IS NULL 
					AND p_rec_customeraudit.ref6_code IS NOT null) 
					OR (p_rec_customeraudit.ref6_code IS NULL 
					AND l_rec_s_customeraudit.ref6_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref6_code != p_rec_customeraudit.ref6_code) THEN 
						PRINT COLUMN 04, "Reference 6:", COLUMN 21, 
						p_rec_customeraudit.ref6_code, COLUMN 62, 
						l_rec_s_customeraudit.ref6_code 
					END IF 
					IF (l_rec_s_customeraudit.ref7_code IS NULL 
					AND p_rec_customeraudit.ref7_code IS NOT null) 
					OR (p_rec_customeraudit.ref7_code IS NULL 
					AND l_rec_s_customeraudit.ref7_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref7_code != p_rec_customeraudit.ref7_code) THEN 
						PRINT COLUMN 04, "Reference 7:", COLUMN 21, 
						p_rec_customeraudit.ref7_code, COLUMN 62, 
						l_rec_s_customeraudit.ref7_code 
					END IF 
					IF (l_rec_s_customeraudit.ref8_code IS NULL 
					AND p_rec_customeraudit.ref8_code IS NOT null) 
					OR (p_rec_customeraudit.ref8_code IS NULL 
					AND l_rec_s_customeraudit.ref8_code IS NOT null) 
					OR (l_rec_s_customeraudit.ref8_code != p_rec_customeraudit.ref8_code) THEN 
						PRINT COLUMN 04, "Reference 8:", COLUMN 21, 
						p_rec_customeraudit.ref8_code, COLUMN 62, 
						l_rec_s_customeraudit.ref8_code 
					END IF 
					IF (l_rec_s_customeraudit.mobile_phone IS NULL 
					AND p_rec_customeraudit.mobile_phone IS NOT null) 
					OR (p_rec_customeraudit.mobile_phone IS NULL 
					AND l_rec_s_customeraudit.mobile_phone IS NOT null) 
					OR (l_rec_s_customeraudit.mobile_phone != p_rec_customeraudit.mobile_phone) 
					THEN 
						PRINT COLUMN 04, "Mobile No. :", COLUMN 21, 
						p_rec_customeraudit.mobile_phone, COLUMN 62, 
						l_rec_s_customeraudit.mobile_phone 
					END IF 
					IF (l_rec_s_customeraudit.ord_text_ind IS NULL 
					AND p_rec_customeraudit.ord_text_ind IS NOT null) 
					OR (p_rec_customeraudit.ord_text_ind IS NULL 
					AND l_rec_s_customeraudit.ord_text_ind IS NOT null) 
					OR (l_rec_s_customeraudit.ord_text_ind != p_rec_customeraudit.ord_text_ind) 
					THEN 
						PRINT COLUMN 04, "Order Text Ind:", COLUMN 21, 
						p_rec_customeraudit.ord_text_ind, COLUMN 62, 
						l_rec_s_customeraudit.ord_text_ind 
					END IF 
					IF (l_rec_s_customeraudit.vat_code IS NULL 
					AND p_rec_customeraudit.vat_code IS NOT null) 
					OR (p_rec_customeraudit.vat_code IS NULL 
					AND l_rec_s_customeraudit.vat_code IS NOT null) 
					OR (l_rec_s_customeraudit.vat_code != p_rec_customeraudit.vat_code) 
					THEN 
						PRINT COLUMN 04, "Customer ABN:", COLUMN 21, 
						p_rec_customeraudit.vat_code, COLUMN 62, 
						l_rec_s_customeraudit.vat_code 
					END IF 
					SKIP 1 line 
				END IF 

			END IF 

			IF l_table = "Customer" THEN 
				#Check TO see IF printout IS required. This problem IS caused by
				#the ' UPDATE customer SET * = l_rec_customer.* ' all over the code
				IF NOT table2_mods(p_rec_customeraudit.*, l_rec_customer.*) THEN 
					IF modu_upd_cnt > 0 THEN 
						LET modu_upd_cnt = modu_upd_cnt - 1 
					END IF 
				ELSE 
					PRINT COLUMN 01, p_rec_customeraudit.cust_code, COLUMN 103, 
					p_rec_customeraudit.user_code, COLUMN 112, 
					p_rec_customeraudit.audit_date 
					IF (l_rec_customer.name_text IS NULL 
					AND p_rec_customeraudit.name_text IS NOT null) 
					OR (p_rec_customeraudit.name_text IS NULL 
					AND l_rec_customer.name_text IS NOT null) 
					OR (l_rec_customer.name_text != p_rec_customeraudit.name_text) THEN 
						PRINT COLUMN 04, "Name:", COLUMN 21, 
						p_rec_customeraudit.name_text, COLUMN 62, 
						l_rec_customer.name_text 
					END IF 
					IF (l_rec_customer.addr1_text IS NULL 
					AND p_rec_customeraudit.addr1_text IS NOT null) 
					OR (p_rec_customeraudit.addr1_text IS NULL 
					AND l_rec_customer.addr1_text IS NOT null) 
					OR (l_rec_customer.addr1_text != p_rec_customeraudit.addr1_text) THEN 
						PRINT COLUMN 04, "Address Line 1:", COLUMN 21, 
						p_rec_customeraudit.addr1_text, COLUMN 62, 
						l_rec_customer.addr1_text 
					END IF 
					IF (l_rec_customer.addr2_text IS NULL 
					AND p_rec_customeraudit.addr2_text IS NOT null) 
					OR (p_rec_customeraudit.addr2_text IS NULL 
					AND l_rec_customer.addr2_text IS NOT null) 
					OR (l_rec_customer.addr2_text != p_rec_customeraudit.addr2_text) THEN 
						PRINT COLUMN 04, "Address Line 2:", COLUMN 21, 
						p_rec_customeraudit.addr2_text, COLUMN 62, 
						l_rec_customer.addr2_text 
					END IF 
					IF (l_rec_customer.city_text IS NULL 
					AND p_rec_customeraudit.city_text IS NOT null) 
					OR (p_rec_customeraudit.city_text IS NULL 
					AND l_rec_customer.city_text IS NOT null) 
					OR (l_rec_customer.city_text != p_rec_customeraudit.city_text) THEN 
						PRINT COLUMN 04, "City:", COLUMN 21, 
						p_rec_customeraudit.city_text, COLUMN 62, 
						l_rec_customer.city_text 
					END IF 
					IF (l_rec_customer.state_code IS NULL 
					AND p_rec_customeraudit.state_code IS NOT null) 
					OR (p_rec_customeraudit.state_code IS NULL 
					AND l_rec_customer.state_code IS NOT null) 
					OR (l_rec_customer.state_code != p_rec_customeraudit.state_code) THEN 
						PRINT COLUMN 04, "State:", COLUMN 21, 
						p_rec_customeraudit.state_code, COLUMN 62, 
						l_rec_customer.state_code 
					END IF 
					IF (l_rec_customer.post_code IS NULL 
					AND p_rec_customeraudit.post_code IS NOT null) 
					OR (p_rec_customeraudit.post_code IS NULL 
					AND l_rec_customer.post_code IS NOT null) 
					OR (l_rec_customer.post_code != p_rec_customeraudit.post_code) THEN 
						PRINT COLUMN 04, "Post Code:", COLUMN 21, 
						p_rec_customeraudit.post_code, COLUMN 62, 
						l_rec_customer.post_code 
					END IF 
					IF (l_rec_customer.country_code IS NULL 
					AND p_rec_customeraudit.country_code IS NOT null) 
					OR (p_rec_customeraudit.country_code IS NULL 
					AND l_rec_customer.country_code IS NOT null) 
					OR (l_rec_customer.country_code != p_rec_customeraudit.country_code) THEN 
						PRINT COLUMN 04, "Country Code:", COLUMN 21, 
						p_rec_customeraudit.country_code, COLUMN 62, 
						l_rec_customer.country_code 
					END IF 
					IF (l_rec_customer.country_code IS NULL --@db-patch_2020_10_04 report--
					AND p_rec_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
					OR (p_rec_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
					AND l_rec_customer.country_code IS NOT null) --@db-patch_2020_10_04 report--
					OR (l_rec_customer.country_code != p_rec_customeraudit.country_code) THEN --@db-patch_2020_10_04 report--
						PRINT COLUMN 04, "Country Text:", COLUMN 21, 
						p_rec_customeraudit.country_code, COLUMN 62, --@db-patch_2020_10_04 report--
						l_rec_customer.country_code --@db-patch_2020_10_04 report--
					END IF 
					IF (l_rec_customer.language_code IS NULL 
					AND p_rec_customeraudit.language_code IS NOT null) 
					OR (p_rec_customeraudit.language_code IS NULL 
					AND l_rec_customer.language_code IS NOT null) 
					OR (l_rec_customer.language_code != p_rec_customeraudit.language_code) 
					THEN 
						PRINT COLUMN 04, "Language Code:", COLUMN 21, 
						p_rec_customeraudit.language_code, COLUMN 62, 
						l_rec_customer.language_code 
					END IF 
					IF (l_rec_customer.type_code IS NULL 
					AND p_rec_customeraudit.type_code IS NOT null) 
					OR (p_rec_customeraudit.type_code IS NULL 
					AND l_rec_customer.type_code IS NOT null) 
					OR (l_rec_customer.type_code != p_rec_customeraudit.type_code) THEN 
						PRINT COLUMN 04, "Customer Type Code:", COLUMN 21, 
						p_rec_customeraudit.type_code, COLUMN 62, 
						l_rec_customer.type_code 
					END IF 
					IF (l_rec_customer.sale_code IS NULL 
					AND p_rec_customeraudit.sale_code IS NOT null) 
					OR (p_rec_customeraudit.sale_code IS NULL 
					AND l_rec_customer.sale_code IS NOT null) 
					OR (l_rec_customer.sale_code != p_rec_customeraudit.sale_code) THEN 
						PRINT COLUMN 04, "Customer Sale Code:", COLUMN 21, 
						p_rec_customeraudit.sale_code, COLUMN 62, 
						l_rec_customer.sale_code 
					END IF 
					IF (l_rec_customer.term_code IS NULL 
					AND p_rec_customeraudit.term_code IS NOT null) 
					OR (p_rec_customeraudit.term_code IS NULL 
					AND l_rec_customer.term_code IS NOT null) 
					OR (l_rec_customer.term_code != p_rec_customeraudit.term_code) THEN 
						PRINT COLUMN 04, "Customer Term Code:", COLUMN 21, 
						p_rec_customeraudit.term_code, COLUMN 62, 
						l_rec_customer.term_code 
					END IF 
					IF (l_rec_customer.tax_code IS NULL 
					AND p_rec_customeraudit.tax_code IS NOT null) 
					OR (p_rec_customeraudit.tax_code IS NULL 
					AND l_rec_customer.tax_code IS NOT null) 
					OR (l_rec_customer.tax_code != p_rec_customeraudit.tax_code) THEN 
						PRINT COLUMN 04, "Customer Tax Code:", COLUMN 21, 
						p_rec_customeraudit.tax_code, COLUMN 62, 
						l_rec_customer.tax_code 
					END IF 
					IF (l_rec_customer.tax_num_text IS NULL 
					AND p_rec_customeraudit.tax_num_text IS NOT null) 
					OR (p_rec_customeraudit.tax_num_text IS NULL 
					AND l_rec_customer.tax_num_text IS NOT null) 
					OR (l_rec_customer.tax_num_text != p_rec_customeraudit.tax_num_text) THEN 
						PRINT COLUMN 04, "Tax Number:", COLUMN 21, 
						p_rec_customeraudit.tax_num_text, COLUMN 62, 
						l_rec_customer.tax_num_text 
					END IF 
					IF (l_rec_customer.contact_text IS NULL 
					AND p_rec_customeraudit.contact_text IS NOT null) 
					OR (p_rec_customeraudit.contact_text IS NULL 
					AND l_rec_customer.contact_text IS NOT null) 
					OR (l_rec_customer.contact_text != p_rec_customeraudit.contact_text) THEN 
						PRINT COLUMN 04, "Contact:", COLUMN 21, 
						p_rec_customeraudit.contact_text, COLUMN 62, 
						l_rec_customer.contact_text 
					END IF 
					IF (l_rec_customer.tele_text IS NULL 
					AND p_rec_customeraudit.tele_text IS NOT null) 
					OR (p_rec_customeraudit.tele_text IS NULL 
					AND l_rec_customer.tele_text IS NOT null) 
					OR (l_rec_customer.tele_text != p_rec_customeraudit.tele_text) THEN 
						PRINT COLUMN 04, "Telephone:", COLUMN 21, 
						p_rec_customeraudit.tele_text, COLUMN 62, 
						l_rec_customer.tele_text 
					END IF 
					IF (l_rec_customer.cred_limit_amt IS NULL 
					AND p_rec_customeraudit.cred_limit_amt IS NOT null) 
					OR (p_rec_customeraudit.cred_limit_amt IS NULL 
					AND l_rec_customer.cred_limit_amt IS NOT null) 
					OR (l_rec_customer.cred_limit_amt != p_rec_customeraudit.cred_limit_amt) 
					THEN 
						PRINT COLUMN 04, "Credit Limit:", COLUMN 21, 
						p_rec_customeraudit.cred_limit_amt USING "<<<<<<<<<<<<<&.&&", COLUMN 62, 
						l_rec_customer.cred_limit_amt USING "<<<<<<<<<<<<<&.&&" 
					END IF 
					IF (l_rec_customer.hold_code IS NULL 
					AND p_rec_customeraudit.hold_code IS NOT null) 
					OR (p_rec_customeraudit.hold_code IS NULL 
					AND l_rec_customer.hold_code IS NOT null) 
					OR (l_rec_customer.hold_code != p_rec_customeraudit.hold_code) THEN 
						PRINT COLUMN 04, "Hold Code:", COLUMN 21, 
						p_rec_customeraudit.hold_code, COLUMN 62, 
						l_rec_customer.hold_code 
					END IF 
					IF (l_rec_customer.inv_level_ind IS NULL 
					AND p_rec_customeraudit.inv_level_ind IS NOT null) 
					OR (p_rec_customeraudit.inv_level_ind IS NULL 
					AND l_rec_customer.inv_level_ind IS NOT null) 
					OR (l_rec_customer.inv_level_ind != p_rec_customeraudit.inv_level_ind) 
					THEN 
						PRINT COLUMN 04, "Level Indicator:", COLUMN 21, 
						p_rec_customeraudit.inv_level_ind, COLUMN 62, 
						l_rec_customer.inv_level_ind 
					END IF 
					IF (l_rec_customer.dun_code IS NULL 
					AND p_rec_customeraudit.dun_code IS NOT null) 
					OR (p_rec_customeraudit.dun_code IS NULL 
					AND l_rec_customer.dun_code IS NOT null) 
					OR (l_rec_customer.dun_code != p_rec_customeraudit.dun_code) THEN 
						PRINT COLUMN 04, "Statement Code:", COLUMN 21, 
						p_rec_customeraudit.dun_code, COLUMN 62, 
						l_rec_customer.dun_code 
					END IF 
					IF (l_rec_customer.stmnt_ind IS NULL 
					AND p_rec_customeraudit.stmnt_ind IS NOT null) 
					OR (p_rec_customeraudit.stmnt_ind IS NULL 
					AND l_rec_customer.stmnt_ind IS NOT null) 
					OR (l_rec_customer.stmnt_ind != p_rec_customeraudit.stmnt_ind) THEN 
						PRINT COLUMN 04, "Statement Ind:", COLUMN 21, 
						p_rec_customeraudit.stmnt_ind, COLUMN 62, 
						l_rec_customer.stmnt_ind 
					END IF 
					IF (l_rec_customer.bank_acct_code IS NULL 
					AND p_rec_customeraudit.bank_acct_code IS NOT null) 
					OR (p_rec_customeraudit.bank_acct_code IS NULL 
					AND l_rec_customer.bank_acct_code IS NOT null) 
					OR (l_rec_customer.bank_acct_code != p_rec_customeraudit.bank_acct_code) 
					THEN 
						PRINT COLUMN 04, "Bank Code:", COLUMN 21, 
						p_rec_customeraudit.bank_acct_code, COLUMN 62, 
						l_rec_customer.bank_acct_code 
					END IF 
					IF (l_rec_customer.territory_code IS NULL 
					AND p_rec_customeraudit.territory_code IS NOT null) 
					OR (p_rec_customeraudit.territory_code IS NULL 
					AND l_rec_customer.territory_code IS NOT null) 
					OR (l_rec_customer.territory_code != p_rec_customeraudit.territory_code) 
					THEN 
						PRINT COLUMN 04, "Territory Code:", COLUMN 21, 
						p_rec_customeraudit.territory_code, COLUMN 62, 
						l_rec_customer.territory_code 
					END IF 
					IF (l_rec_customer.delete_flag IS NULL 
					AND p_rec_customeraudit.delete_flag IS NOT null) 
					OR (p_rec_customeraudit.delete_flag IS NULL 
					AND l_rec_customer.delete_flag IS NOT null) 
					OR (l_rec_customer.delete_flag != p_rec_customeraudit.delete_flag) THEN 
						PRINT COLUMN 04, "Delete Flag:", COLUMN 21, 
						p_rec_customeraudit.delete_flag, COLUMN 62, 
						l_rec_customer.delete_flag 
					END IF 
					IF (l_rec_customer.delete_date IS NULL 
					AND p_rec_customeraudit.delete_date IS NOT null) 
					OR (p_rec_customeraudit.delete_date IS NULL 
					AND l_rec_customer.delete_date IS NOT null) 
					OR (l_rec_customer.delete_date != p_rec_customeraudit.delete_date) THEN 
						PRINT COLUMN 04, "Delete Date:", COLUMN 21, 
						p_rec_customeraudit.delete_date, COLUMN 62, 
						l_rec_customer.delete_date 
					END IF 
					IF (l_rec_customer.ref1_code IS NULL 
					AND p_rec_customeraudit.ref1_code IS NOT null) 
					OR (p_rec_customeraudit.ref1_code IS NULL 
					AND l_rec_customer.ref1_code IS NOT null) 
					OR (l_rec_customer.ref1_code != p_rec_customeraudit.ref1_code) THEN 
						PRINT COLUMN 04, "Reference 1:", COLUMN 21, 
						p_rec_customeraudit.ref1_code, COLUMN 62, 
						l_rec_customer.ref1_code 
					END IF 
					IF (l_rec_customer.ref2_code IS NULL 
					AND p_rec_customeraudit.ref2_code IS NOT null) 
					OR (p_rec_customeraudit.ref2_code IS NULL 
					AND l_rec_customer.ref2_code IS NOT null) 
					OR (l_rec_customer.ref2_code != p_rec_customeraudit.ref2_code) THEN 
						PRINT COLUMN 04, "Reference 2:", COLUMN 21, 
						p_rec_customeraudit.ref2_code, COLUMN 62, 
						l_rec_customer.ref2_code 
					END IF 
					IF (l_rec_customer.ref3_code IS NULL 
					AND p_rec_customeraudit.ref3_code IS NOT null) 
					OR (p_rec_customeraudit.ref3_code IS NULL 
					AND l_rec_customer.ref3_code IS NOT null) 
					OR (l_rec_customer.ref3_code != p_rec_customeraudit.ref3_code) THEN 
						PRINT COLUMN 04, "Reference 3:", COLUMN 21, 
						p_rec_customeraudit.ref3_code, COLUMN 62, 
						l_rec_customer.ref3_code 
					END IF 
					IF (l_rec_customer.ref4_code IS NULL 
					AND p_rec_customeraudit.ref4_code IS NOT null) 
					OR (p_rec_customeraudit.ref4_code IS NULL 
					AND l_rec_customer.ref4_code IS NOT null) 
					OR (l_rec_customer.ref4_code != p_rec_customeraudit.ref4_code) THEN 
						PRINT COLUMN 04, "Reference 4:", COLUMN 21, 
						p_rec_customeraudit.ref4_code, COLUMN 62, 
						l_rec_customer.ref4_code 
					END IF 
					IF (l_rec_customer.ref5_code IS NULL 
					AND p_rec_customeraudit.ref5_code IS NOT null) 
					OR (p_rec_customeraudit.ref5_code IS NULL 
					AND l_rec_customer.ref5_code IS NOT null) 
					OR (l_rec_customer.ref5_code != p_rec_customeraudit.ref5_code) THEN 
						PRINT COLUMN 04, "Reference 5:", COLUMN 21, 
						p_rec_customeraudit.ref5_code, COLUMN 62, 
						l_rec_customer.ref5_code 
					END IF 
					IF (l_rec_customer.ref6_code IS NULL 
					AND p_rec_customeraudit.ref6_code IS NOT null) 
					OR (p_rec_customeraudit.ref6_code IS NULL 
					AND l_rec_customer.ref6_code IS NOT null) 
					OR (l_rec_customer.ref6_code != p_rec_customeraudit.ref6_code) THEN 
						PRINT COLUMN 04, "Reference 6:", COLUMN 21, 
						p_rec_customeraudit.ref6_code, COLUMN 62, 
						l_rec_customer.ref6_code 
					END IF 
					IF (l_rec_customer.ref7_code IS NULL 
					AND p_rec_customeraudit.ref7_code IS NOT null) 
					OR (p_rec_customeraudit.ref7_code IS NULL 
					AND l_rec_customer.ref7_code IS NOT null) 
					OR (l_rec_customer.ref7_code != p_rec_customeraudit.ref7_code) THEN 
						PRINT COLUMN 04, "Reference 7:", COLUMN 21, 
						p_rec_customeraudit.ref7_code, COLUMN 62, 
						l_rec_customer.ref7_code 
					END IF 
					IF (l_rec_customer.ref8_code IS NULL 
					AND p_rec_customeraudit.ref8_code IS NOT null) 
					OR (p_rec_customeraudit.ref8_code IS NULL 
					AND l_rec_customer.ref8_code IS NOT null) 
					OR (l_rec_customer.ref8_code != p_rec_customeraudit.ref8_code) THEN 
						PRINT COLUMN 04, "Reference 8:", COLUMN 21, 
						p_rec_customeraudit.ref8_code, COLUMN 62, 
						l_rec_customer.ref8_code 
					END IF 
					IF (l_rec_customer.mobile_phone IS NULL 
					AND p_rec_customeraudit.mobile_phone IS NOT null) 
					OR (p_rec_customeraudit.mobile_phone IS NULL 
					AND l_rec_customer.mobile_phone IS NOT null) 
					OR (l_rec_customer.mobile_phone != p_rec_customeraudit.mobile_phone) THEN 
						PRINT COLUMN 04, "Mobile No. :", COLUMN 21, 
						p_rec_customeraudit.mobile_phone, COLUMN 62, 
						l_rec_customer.mobile_phone 
					END IF 
					IF (l_rec_customer.ord_text_ind IS NULL 
					AND p_rec_customeraudit.ord_text_ind IS NOT null) 
					OR (p_rec_customeraudit.ord_text_ind IS NULL 
					AND l_rec_customer.ord_text_ind IS NOT null) 
					OR (l_rec_customer.ord_text_ind != p_rec_customeraudit.ord_text_ind) THEN 
						PRINT COLUMN 04, "Order Text Ind:", COLUMN 21, 
						p_rec_customeraudit.ord_text_ind, COLUMN 62, 
						l_rec_customer.ord_text_ind 
					END IF 
					IF (l_rec_customer.vat_code IS NULL 
					AND p_rec_customeraudit.vat_code IS NOT null) 
					OR (p_rec_customeraudit.vat_code IS NULL 
					AND l_rec_customer.vat_code IS NOT null) 
					OR (l_rec_customer.vat_code != p_rec_customeraudit.vat_code) THEN 
						PRINT COLUMN 04, "Customer ABN:", COLUMN 21, 
						p_rec_customeraudit.vat_code, COLUMN 62, 
						l_rec_customer.vat_code 
					END IF 
					SKIP 1 line 
				END IF 
			END IF 
		ON LAST ROW NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 15, "Total Customer Alterations: ", COLUMN 41, 
			modu_upd_cnt USING "<<<<&" 
			SKIP 3 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT 
#####################################################################
# REPORT AAU_rpt_list_upd(p_rec_customeraudit)
#
#
#####################################################################


#####################################################################
# REPORT AAU_rpt_list_del(p_rec_customeraudit)
#
#
#####################################################################
REPORT AAU_rpt_list_del(p_rpt_idx,p_rec_customeraudit)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_customeraudit RECORD LIKE customeraudit.* 
	DEFINE l_cmpy_head CHAR(78) 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 
	
	OUTPUT 
 
	ORDER external BY p_rec_customeraudit.cust_code, p_rec_customeraudit.audit_date 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, time, COLUMN l_col2, 	modu_new_note clipped 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, 
			"Customer", COLUMN 10, 
			"Name", COLUMN 45, 
			"User", COLUMN 54, 
			"Date", COLUMN 65, 
			"Time" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 01, 
			p_rec_customeraudit.cust_code, COLUMN 10, 
			p_rec_customeraudit.name_text, COLUMN 45, 
			p_rec_customeraudit.user_code, COLUMN 54, 
			p_rec_customeraudit.audit_date 
		ON LAST ROW NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 15, 
			"Total Customer Deletions: ", COLUMN 39, 
			modu_del_cnt USING "<<<<&" 
			SKIP 3 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
			
END REPORT 
#####################################################################
# END REPORT AAU_rpt_list_del(p_rec_customeraudit)
#####################################################################


#####################################################################
# FUNCTION table1_mods(p_rec_s_customeraudit, p_rec_customeraudit)
#
#
#####################################################################
FUNCTION table1_mods(p_rec_s_customeraudit, p_rec_customeraudit) 
	DEFINE p_rec_s_customeraudit RECORD LIKE customeraudit.* 
	DEFINE p_rec_customeraudit RECORD LIKE customeraudit.* 
	
	IF (p_rec_s_customeraudit.name_text IS NULL 
	AND p_rec_customeraudit.name_text IS NOT null) 
	OR (p_rec_customeraudit.name_text IS NULL 
	AND p_rec_s_customeraudit.name_text IS NOT null) 
	OR (p_rec_s_customeraudit.name_text != p_rec_customeraudit.name_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.addr1_text IS NULL 
	AND p_rec_customeraudit.addr1_text IS NOT null) 
	OR (p_rec_customeraudit.addr1_text IS NULL 
	AND p_rec_s_customeraudit.addr1_text IS NOT null) 
	OR (p_rec_s_customeraudit.addr1_text != p_rec_customeraudit.addr1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.addr2_text IS NULL 
	AND p_rec_customeraudit.addr2_text IS NOT null) 
	OR (p_rec_customeraudit.addr2_text IS NULL 
	AND p_rec_s_customeraudit.addr2_text IS NOT null) 
	OR (p_rec_s_customeraudit.addr2_text != p_rec_customeraudit.addr2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.city_text IS NULL 
	AND p_rec_customeraudit.city_text IS NOT null) 
	OR (p_rec_customeraudit.city_text IS NULL 
	AND p_rec_s_customeraudit.city_text IS NOT null) 
	OR (p_rec_s_customeraudit.city_text != p_rec_customeraudit.city_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.state_code IS NULL 
	AND p_rec_customeraudit.state_code IS NOT null) 
	OR (p_rec_customeraudit.state_code IS NULL 
	AND p_rec_s_customeraudit.state_code IS NOT null) 
	OR (p_rec_s_customeraudit.state_code != p_rec_customeraudit.state_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.post_code IS NULL 
	AND p_rec_customeraudit.post_code IS NOT null) 
	OR (p_rec_customeraudit.post_code IS NULL 
	AND p_rec_s_customeraudit.post_code IS NOT null) 
	OR (p_rec_s_customeraudit.post_code != p_rec_customeraudit.post_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.country_code IS NULL 
	AND p_rec_customeraudit.country_code IS NOT null) 
	OR (p_rec_customeraudit.country_code IS NULL 
	AND p_rec_s_customeraudit.country_code IS NOT null) 
	OR (p_rec_s_customeraudit.country_code != p_rec_customeraudit.country_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
	AND p_rec_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
	OR (p_rec_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
	AND p_rec_s_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
	OR (p_rec_s_customeraudit.country_code != p_rec_customeraudit.country_code) THEN --@db-patch_2020_10_04 report--
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.language_code IS NULL 
	AND p_rec_customeraudit.language_code IS NOT null) 
	OR (p_rec_customeraudit.language_code IS NULL 
	AND p_rec_s_customeraudit.language_code IS NOT null) 
	OR (p_rec_s_customeraudit.language_code != p_rec_customeraudit.language_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.type_code IS NULL 
	AND p_rec_customeraudit.type_code IS NOT null) 
	OR (p_rec_customeraudit.type_code IS NULL 
	AND p_rec_s_customeraudit.type_code IS NOT null) 
	OR (p_rec_s_customeraudit.type_code != p_rec_customeraudit.type_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.sale_code IS NULL 
	AND p_rec_customeraudit.sale_code IS NOT null) 
	OR (p_rec_customeraudit.sale_code IS NULL 
	AND p_rec_s_customeraudit.sale_code IS NOT null) 
	OR (p_rec_s_customeraudit.sale_code != p_rec_customeraudit.sale_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.term_code IS NULL 
	AND p_rec_customeraudit.term_code IS NOT null) 
	OR (p_rec_customeraudit.term_code IS NULL 
	AND p_rec_s_customeraudit.term_code IS NOT null) 
	OR (p_rec_s_customeraudit.term_code != p_rec_customeraudit.term_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.tax_code IS NULL 
	AND p_rec_customeraudit.tax_code IS NOT null) 
	OR (p_rec_customeraudit.tax_code IS NULL 
	AND p_rec_s_customeraudit.tax_code IS NOT null) 
	OR (p_rec_s_customeraudit.tax_code != p_rec_customeraudit.tax_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.tax_num_text IS NULL 
	AND p_rec_customeraudit.tax_num_text IS NOT null) 
	OR (p_rec_customeraudit.tax_num_text IS NULL 
	AND p_rec_s_customeraudit.tax_num_text IS NOT null) 
	OR (p_rec_s_customeraudit.tax_num_text != p_rec_customeraudit.tax_num_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.contact_text IS NULL 
	AND p_rec_customeraudit.contact_text IS NOT null) 
	OR (p_rec_customeraudit.contact_text IS NULL 
	AND p_rec_s_customeraudit.contact_text IS NOT null) 
	OR (p_rec_s_customeraudit.contact_text != p_rec_customeraudit.contact_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.tele_text IS NULL 
	AND p_rec_customeraudit.tele_text IS NOT null) 
	OR (p_rec_customeraudit.tele_text IS NULL 
	AND p_rec_s_customeraudit.tele_text IS NOT null) 
	OR (p_rec_s_customeraudit.tele_text != p_rec_customeraudit.tele_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.cred_limit_amt IS NULL 
	AND p_rec_customeraudit.cred_limit_amt IS NOT null) 
	OR (p_rec_customeraudit.cred_limit_amt IS NULL 
	AND p_rec_s_customeraudit.cred_limit_amt IS NOT null) 
	OR (p_rec_s_customeraudit.cred_limit_amt != p_rec_customeraudit.cred_limit_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.hold_code IS NULL 
	AND p_rec_customeraudit.hold_code IS NOT null) 
	OR (p_rec_customeraudit.hold_code IS NULL 
	AND p_rec_s_customeraudit.hold_code IS NOT null) 
	OR (p_rec_s_customeraudit.hold_code != p_rec_customeraudit.hold_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.inv_level_ind IS NULL 
	AND p_rec_customeraudit.inv_level_ind IS NOT null) 
	OR (p_rec_customeraudit.inv_level_ind IS NULL 
	AND p_rec_s_customeraudit.inv_level_ind IS NOT null) 
	OR (p_rec_s_customeraudit.inv_level_ind != p_rec_customeraudit.inv_level_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.dun_code IS NULL 
	AND p_rec_customeraudit.dun_code IS NOT null) 
	OR (p_rec_customeraudit.dun_code IS NULL 
	AND p_rec_s_customeraudit.dun_code IS NOT null) 
	OR (p_rec_s_customeraudit.dun_code != p_rec_customeraudit.dun_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.stmnt_ind IS NULL 
	AND p_rec_customeraudit.stmnt_ind IS NOT null) 
	OR (p_rec_customeraudit.stmnt_ind IS NULL 
	AND p_rec_s_customeraudit.stmnt_ind IS NOT null) 
	OR (p_rec_s_customeraudit.stmnt_ind != p_rec_customeraudit.stmnt_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.territory_code IS NULL 
	AND p_rec_customeraudit.territory_code IS NOT null) 
	OR (p_rec_customeraudit.territory_code IS NULL 
	AND p_rec_s_customeraudit.territory_code IS NOT null) 
	OR (p_rec_s_customeraudit.territory_code != p_rec_customeraudit.territory_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.bank_acct_code IS NULL 
	AND p_rec_customeraudit.bank_acct_code IS NOT null) 
	OR (p_rec_customeraudit.bank_acct_code IS NULL 
	AND p_rec_s_customeraudit.bank_acct_code IS NOT null) 
	OR (p_rec_s_customeraudit.bank_acct_code != p_rec_customeraudit.bank_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.delete_flag IS NULL 
	AND p_rec_customeraudit.delete_flag IS NOT null) 
	OR (p_rec_customeraudit.delete_flag IS NULL 
	AND p_rec_s_customeraudit.delete_flag IS NOT null) 
	OR (p_rec_s_customeraudit.delete_flag != p_rec_customeraudit.delete_flag) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.delete_date IS NULL 
	AND p_rec_customeraudit.delete_date IS NOT null) 
	OR (p_rec_customeraudit.delete_date IS NULL 
	AND p_rec_s_customeraudit.delete_date IS NOT null) 
	OR (p_rec_s_customeraudit.delete_date != p_rec_customeraudit.delete_date) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref1_code IS NULL 
	AND p_rec_customeraudit.ref1_code IS NOT null) 
	OR (p_rec_customeraudit.ref1_code IS NULL 
	AND p_rec_s_customeraudit.ref1_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref1_code != p_rec_customeraudit.ref1_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref2_code IS NULL 
	AND p_rec_customeraudit.ref2_code IS NOT null) 
	OR (p_rec_customeraudit.ref2_code IS NULL 
	AND p_rec_s_customeraudit.ref2_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref2_code != p_rec_customeraudit.ref2_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref3_code IS NULL 
	AND p_rec_customeraudit.ref3_code IS NOT null) 
	OR (p_rec_customeraudit.ref3_code IS NULL 
	AND p_rec_s_customeraudit.ref3_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref3_code != p_rec_customeraudit.ref3_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref4_code IS NULL 
	AND p_rec_customeraudit.ref4_code IS NOT null) 
	OR (p_rec_customeraudit.ref4_code IS NULL 
	AND p_rec_s_customeraudit.ref4_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref4_code != p_rec_customeraudit.ref4_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref5_code IS NULL 
	AND p_rec_customeraudit.ref5_code IS NOT null) 
	OR (p_rec_customeraudit.ref5_code IS NULL 
	AND p_rec_s_customeraudit.ref5_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref5_code != p_rec_customeraudit.ref5_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref6_code IS NULL 
	AND p_rec_customeraudit.ref6_code IS NOT null) 
	OR (p_rec_customeraudit.ref6_code IS NULL 
	AND p_rec_s_customeraudit.ref6_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref6_code != p_rec_customeraudit.ref6_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref7_code IS NULL 
	AND p_rec_customeraudit.ref7_code IS NOT null) 
	OR (p_rec_customeraudit.ref7_code IS NULL 
	AND p_rec_s_customeraudit.ref7_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref7_code != p_rec_customeraudit.ref7_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ref8_code IS NULL 
	AND p_rec_customeraudit.ref8_code IS NOT null) 
	OR (p_rec_customeraudit.ref8_code IS NULL 
	AND p_rec_s_customeraudit.ref8_code IS NOT null) 
	OR (p_rec_s_customeraudit.ref8_code != p_rec_customeraudit.ref8_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.mobile_phone IS NULL 
	AND p_rec_customeraudit.mobile_phone IS NOT null) 
	OR (p_rec_customeraudit.mobile_phone IS NULL 
	AND p_rec_s_customeraudit.mobile_phone IS NOT null) 
	OR (p_rec_s_customeraudit.mobile_phone != p_rec_customeraudit.mobile_phone) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.ord_text_ind IS NULL 
	AND p_rec_customeraudit.ord_text_ind IS NOT null) 
	OR (p_rec_customeraudit.ord_text_ind IS NULL 
	AND p_rec_s_customeraudit.ord_text_ind IS NOT null) 
	OR (p_rec_s_customeraudit.ord_text_ind != p_rec_customeraudit.ord_text_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_customeraudit.vat_code IS NULL 
	AND p_rec_customeraudit.vat_code IS NOT null) 
	OR (p_rec_customeraudit.vat_code IS NULL 
	AND p_rec_s_customeraudit.vat_code IS NOT null) 
	OR (p_rec_s_customeraudit.vat_code != p_rec_customeraudit.vat_code) THEN 
		RETURN true 
	END IF 
	
	RETURN false 
END FUNCTION 
#####################################################################
# END FUNCTION table1_mods(p_rec_s_customeraudit, p_rec_customeraudit)
#####################################################################


#####################################################################
# FUNCTION table2_mods(p_rec_customeraudit, p_rec_customer)
#
#
#####################################################################
FUNCTION table2_mods(p_rec_customeraudit, p_rec_customer) 
	DEFINE p_rec_customeraudit RECORD LIKE customeraudit.* 
	DEFINE p_rec_customer RECORD LIKE customer.*
	 
	IF (p_rec_customer.name_text IS NULL 
	AND p_rec_customeraudit.name_text IS NOT null) 
	OR (p_rec_customeraudit.name_text IS NULL 
	AND p_rec_customer.name_text IS NOT null) 
	OR (p_rec_customer.name_text != p_rec_customeraudit.name_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.addr1_text IS NULL 
	AND p_rec_customeraudit.addr1_text IS NOT null) 
	OR (p_rec_customeraudit.addr1_text IS NULL 
	AND p_rec_customer.addr1_text IS NOT null) 
	OR (p_rec_customer.addr1_text != p_rec_customeraudit.addr1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.addr2_text IS NULL 
	AND p_rec_customeraudit.addr2_text IS NOT null) 
	OR (p_rec_customeraudit.addr2_text IS NULL 
	AND p_rec_customer.addr2_text IS NOT null) 
	OR (p_rec_customer.addr2_text != p_rec_customeraudit.addr2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.city_text IS NULL 
	AND p_rec_customeraudit.city_text IS NOT null) 
	OR (p_rec_customeraudit.city_text IS NULL 
	AND p_rec_customer.city_text IS NOT null) 
	OR (p_rec_customer.city_text != p_rec_customeraudit.city_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.state_code IS NULL 
	AND p_rec_customeraudit.state_code IS NOT null) 
	OR (p_rec_customeraudit.state_code IS NULL 
	AND p_rec_customer.state_code IS NOT null) 
	OR (p_rec_customer.state_code != p_rec_customeraudit.state_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.post_code IS NULL 
	AND p_rec_customeraudit.post_code IS NOT null) 
	OR (p_rec_customeraudit.post_code IS NULL 
	AND p_rec_customer.post_code IS NOT null) 
	OR (p_rec_customer.post_code != p_rec_customeraudit.post_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.country_code IS NULL 
	AND p_rec_customeraudit.country_code IS NOT null) 
	OR (p_rec_customeraudit.country_code IS NULL 
	AND p_rec_customer.country_code IS NOT null) 
	OR (p_rec_customer.country_code != p_rec_customeraudit.country_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.country_code IS NULL --@db-patch_2020_10_04 report--
	AND p_rec_customeraudit.country_code IS NOT null) --@db-patch_2020_10_04 report--
	OR (p_rec_customeraudit.country_code IS NULL --@db-patch_2020_10_04 report--
	AND p_rec_customer.country_code IS NOT null) --@db-patch_2020_10_04 report--
	OR (p_rec_customer.country_code != p_rec_customeraudit.country_code) THEN --@db-patch_2020_10_04 report--
		RETURN true 
	END IF 
	IF (p_rec_customer.language_code IS NULL 
	AND p_rec_customeraudit.language_code IS NOT null) 
	OR (p_rec_customeraudit.language_code IS NULL 
	AND p_rec_customer.language_code IS NOT null) 
	OR (p_rec_customer.language_code != p_rec_customeraudit.language_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.type_code IS NULL 
	AND p_rec_customeraudit.type_code IS NOT null) 
	OR (p_rec_customeraudit.type_code IS NULL 
	AND p_rec_customer.type_code IS NOT null) 
	OR (p_rec_customer.type_code != p_rec_customeraudit.type_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.sale_code IS NULL 
	AND p_rec_customeraudit.sale_code IS NOT null) 
	OR (p_rec_customeraudit.sale_code IS NULL 
	AND p_rec_customer.sale_code IS NOT null) 
	OR (p_rec_customer.sale_code != p_rec_customeraudit.sale_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.term_code IS NULL 
	AND p_rec_customeraudit.term_code IS NOT null) 
	OR (p_rec_customeraudit.term_code IS NULL 
	AND p_rec_customer.term_code IS NOT null) 
	OR (p_rec_customer.term_code != p_rec_customeraudit.term_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.tax_code IS NULL 
	AND p_rec_customeraudit.tax_code IS NOT null) 
	OR (p_rec_customeraudit.tax_code IS NULL 
	AND p_rec_customer.tax_code IS NOT null) 
	OR (p_rec_customer.tax_code != p_rec_customeraudit.tax_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.tax_num_text IS NULL 
	AND p_rec_customeraudit.tax_num_text IS NOT null) 
	OR (p_rec_customeraudit.tax_num_text IS NULL 
	AND p_rec_customer.tax_num_text IS NOT null) 
	OR (p_rec_customer.tax_num_text != p_rec_customeraudit.tax_num_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.contact_text IS NULL 
	AND p_rec_customeraudit.contact_text IS NOT null) 
	OR (p_rec_customeraudit.contact_text IS NULL 
	AND p_rec_customer.contact_text IS NOT null) 
	OR (p_rec_customer.contact_text != p_rec_customeraudit.contact_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.tele_text IS NULL 
	AND p_rec_customeraudit.tele_text IS NOT null) 
	OR (p_rec_customeraudit.tele_text IS NULL 
	AND p_rec_customer.tele_text IS NOT null) 
	OR (p_rec_customer.tele_text != p_rec_customeraudit.tele_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.cred_limit_amt IS NULL 
	AND p_rec_customeraudit.cred_limit_amt IS NOT null) 
	OR (p_rec_customeraudit.cred_limit_amt IS NULL 
	AND p_rec_customer.cred_limit_amt IS NOT null) 
	OR (p_rec_customer.cred_limit_amt != p_rec_customeraudit.cred_limit_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.hold_code IS NULL 
	AND p_rec_customeraudit.hold_code IS NOT null) 
	OR (p_rec_customeraudit.hold_code IS NULL 
	AND p_rec_customer.hold_code IS NOT null) 
	OR (p_rec_customer.hold_code != p_rec_customeraudit.hold_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.inv_level_ind IS NULL 
	AND p_rec_customeraudit.inv_level_ind IS NOT null) 
	OR (p_rec_customeraudit.inv_level_ind IS NULL 
	AND p_rec_customer.inv_level_ind IS NOT null) 
	OR (p_rec_customer.inv_level_ind != p_rec_customeraudit.inv_level_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.dun_code IS NULL 
	AND p_rec_customeraudit.dun_code IS NOT null) 
	OR (p_rec_customeraudit.dun_code IS NULL 
	AND p_rec_customer.dun_code IS NOT null) 
	OR (p_rec_customer.dun_code != p_rec_customeraudit.dun_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.stmnt_ind IS NULL 
	AND p_rec_customeraudit.stmnt_ind IS NOT null) 
	OR (p_rec_customeraudit.stmnt_ind IS NULL 
	AND p_rec_customer.stmnt_ind IS NOT null) 
	OR (p_rec_customer.stmnt_ind != p_rec_customeraudit.stmnt_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.territory_code IS NULL 
	AND p_rec_customeraudit.territory_code IS NOT null) 
	OR (p_rec_customeraudit.territory_code IS NULL 
	AND p_rec_customer.territory_code IS NOT null) 
	OR (p_rec_customer.territory_code != p_rec_customeraudit.territory_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.bank_acct_code IS NULL 
	AND p_rec_customeraudit.bank_acct_code IS NOT null) 
	OR (p_rec_customeraudit.bank_acct_code IS NULL 
	AND p_rec_customer.bank_acct_code IS NOT null) 
	OR (p_rec_customer.bank_acct_code != p_rec_customeraudit.bank_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.delete_flag IS NULL 
	AND p_rec_customeraudit.delete_flag IS NOT null) 
	OR (p_rec_customeraudit.delete_flag IS NULL 
	AND p_rec_customer.delete_flag IS NOT null) 
	OR (p_rec_customer.delete_flag != p_rec_customeraudit.delete_flag) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.delete_date IS NULL 
	AND p_rec_customeraudit.delete_date IS NOT null) 
	OR (p_rec_customeraudit.delete_date IS NULL 
	AND p_rec_customer.delete_date IS NOT null) 
	OR (p_rec_customer.delete_date != p_rec_customeraudit.delete_date) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref1_code IS NULL 
	AND p_rec_customeraudit.ref1_code IS NOT null) 
	OR (p_rec_customeraudit.ref1_code IS NULL 
	AND p_rec_customer.ref1_code IS NOT null) 
	OR (p_rec_customer.ref1_code != p_rec_customeraudit.ref1_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref2_code IS NULL 
	AND p_rec_customeraudit.ref2_code IS NOT null) 
	OR (p_rec_customeraudit.ref2_code IS NULL 
	AND p_rec_customer.ref2_code IS NOT null) 
	OR (p_rec_customer.ref2_code != p_rec_customeraudit.ref2_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref3_code IS NULL 
	AND p_rec_customeraudit.ref3_code IS NOT null) 
	OR (p_rec_customeraudit.ref3_code IS NULL 
	AND p_rec_customer.ref3_code IS NOT null) 
	OR (p_rec_customer.ref3_code != p_rec_customeraudit.ref3_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref4_code IS NULL 
	AND p_rec_customeraudit.ref4_code IS NOT null) 
	OR (p_rec_customeraudit.ref4_code IS NULL 
	AND p_rec_customer.ref4_code IS NOT null) 
	OR (p_rec_customer.ref4_code != p_rec_customeraudit.ref4_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref5_code IS NULL 
	AND p_rec_customeraudit.ref5_code IS NOT null) 
	OR (p_rec_customeraudit.ref5_code IS NULL 
	AND p_rec_customer.ref5_code IS NOT null) 
	OR (p_rec_customer.ref5_code != p_rec_customeraudit.ref5_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref6_code IS NULL 
	AND p_rec_customeraudit.ref6_code IS NOT null) 
	OR (p_rec_customeraudit.ref6_code IS NULL 
	AND p_rec_customer.ref6_code IS NOT null) 
	OR (p_rec_customer.ref6_code != p_rec_customeraudit.ref6_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref7_code IS NULL 
	AND p_rec_customeraudit.ref7_code IS NOT null) 
	OR (p_rec_customeraudit.ref7_code IS NULL 
	AND p_rec_customer.ref7_code IS NOT null) 
	OR (p_rec_customer.ref7_code != p_rec_customeraudit.ref7_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ref8_code IS NULL 
	AND p_rec_customeraudit.ref8_code IS NOT null) 
	OR (p_rec_customeraudit.ref8_code IS NULL 
	AND p_rec_customer.ref8_code IS NOT null) 
	OR (p_rec_customer.ref8_code != p_rec_customeraudit.ref8_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.mobile_phone IS NULL 
	AND p_rec_customeraudit.mobile_phone IS NOT null) 
	OR (p_rec_customeraudit.mobile_phone IS NULL 
	AND p_rec_customer.mobile_phone IS NOT null) 
	OR (p_rec_customer.mobile_phone != p_rec_customeraudit.mobile_phone) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.ord_text_ind IS NULL 
	AND p_rec_customeraudit.ord_text_ind IS NOT null) 
	OR (p_rec_customeraudit.ord_text_ind IS NULL 
	AND p_rec_customer.ord_text_ind IS NOT null) 
	OR (p_rec_customer.ord_text_ind != p_rec_customeraudit.ord_text_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_customer.vat_code IS NULL 
	AND p_rec_customeraudit.vat_code IS NOT null) 
	OR (p_rec_customeraudit.vat_code IS NULL 
	AND p_rec_customer.vat_code IS NOT null) 
	OR (p_rec_customer.vat_code != p_rec_customeraudit.vat_code) THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 
#####################################################################
# END FUNCTION table2_mods(p_rec_customeraudit, p_rec_customer)
#####################################################################