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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PA0_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_pr_add_cnt SMALLINT 
	DEFINE glob_upd_cnt SMALLINT 
	DEFINE glob_del_cnt SMALLINT 
	DEFINE glob_heading CHAR(10) 
	DEFINE glob_log_date DATE 
END GLOBALS 

############################################################
# FUNCTION PAA_main()
#
# Vendor Audit Report
############################################################
FUNCTION PAA_main() 
	DEFINE l_cnt_del_row SMALLINT 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("PAA") 	#Initial UI Init 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW U507 with FORM "U507" 
			CALL winDecoration_u("U507") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			LET glob_heading = " Vendor" 
			DISPLAY glob_heading TO heading attribute(white) 
		
			MENU " Vendor Audit" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PAA","menu-vendor-1") 
					CALL rpt_rmsreps_reset(NULL)
					CALL PAA_rpt_process(PAA_rpt_query()) 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report"	#COMMAND "Report" " SELECT Criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PAA_rpt_process(PAA_rpt_query()) 
		
				ON ACTION "Duplicate"		#COMMAND "Duplicate" " Re-PRINT previously printed information"
					CALL PAA_reprint() 
		
				ON ACTION "Clear" 	#COMMAND "Clear" " Clear out previously printed information"
					SELECT count(*) INTO l_cnt_del_row FROM vendoraudit 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND print_date IS NOT NULL 
					IF l_cnt_del_row != 0 THEN 
						
						IF kandoomsg("U",8012,l_cnt_del_row) = "Y" THEN #8012 Confirm TO delete l_cnt_del_row rows (Y/N) 
							WHENEVER ERROR CONTINUE 
							DELETE FROM vendoraudit 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND print_date IS NOT NULL 
							LET l_cnt_del_row = sqlca.sqlerrd[3] 
							IF status = -274 THEN 
								CALL kandoomsg2("P",9049,"") #9049 l_cnt_del_row audit rows deleted						
							END IF 
							
							WHENEVER ERROR stop
							 
							CALL kandoomsg2("U",7013,l_cnt_del_row)#7013 l_cnt_del_row audit rows deleted
							NEXT option "Exit" 
						END IF 
					END IF 
		
				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL"			#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW U507 
			
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			IF db_rmsreps_get_ref1_ind(UI_OFF,get_url_report_code()) = "N" THEN #normal #from db
				CALL rpt_rmsreps_reset(NULL)
				CALL PAA_rpt_process(NULL)
			ELSE #Duplicate/Reprint
				CALL rpt_rmsreps_reset(NULL)
				CALL PAA_reprint()
			END IF  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P105 with FORM "P105" 
			CALL windecoration_p("P105") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PAA_rpt_query()) #save where clause in env 
			CLOSE WINDOW P105 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL rpt_rmsreps_reset(NULL)
			CALL PAA_rpt_process(get_url_sel_text())
	END CASE
	
END FUNCTION 
############################################################
# END FUNCTION PAA_main()
############################################################


############################################################
# FUNCTION PAA_rpt_query()
#
#
############################################################
FUNCTION PAA_rpt_query() 
	DEFINE l_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_exp_date DATETIME year TO second #timestamp for report driver
	DEFINE l_report_num LIKE nextnumber.next_num
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING #used for report header appendix	 
--	DEFINE l_rpt_output CHAR(50) 
--	DEFINE l_msgresp LIKE language.yes_flag 
--	DEFINE l_output STRING #report output file name inc. path

	CLEAR FORM 
	LET glob_log_date = today 

	INPUT glob_log_date WITHOUT DEFAULTS FROM log_date 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PAA","inp-log_date-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_log_date IS NULL THEN 
					ERROR kandoomsg2("P",9048,"")	#9048 "Log Date must be entered"
					LET glob_log_date = today 
					NEXT FIELD log_date 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
	 
	LET l_exp_date = glob_log_date 
	LET l_exp_date = l_exp_date + 1 units day - 1 units second
	 
	LET glob_rec_rpt_selector.ref1_date = glob_log_date
	LET glob_rec_rpt_selector.ref2_date = l_exp_date
	LET glob_rec_rpt_selector.ref1_ind = "N"
	RETURN "N/A"
END FUNCTION
############################################################
# END FUNCTION PAA_rpt_query()
############################################################


############################################################
# FUNCTION PAA_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PAA_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_exp_date DATETIME year TO second #timestamp for report driver
	DEFINE l_report_num LIKE nextnumber.next_num
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING #used for report header appendix	 
--	DEFINE l_rpt_output CHAR(50) 
--	DEFINE l_msgresp LIKE language.yes_flag 
--	DEFINE l_output STRING #report output file name inc. path

	SELECT next_num INTO l_report_num FROM nextnumber 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = "UAP" 
	LET glob_rec_rpt_selector.ref1_num = l_report_num	

	#######################################################################################################
	# 1st Report                                                                                          #
	#######################################################################################################

	#------------------------------------------------------------
	#### First Report - Additions ###

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-1-ADD","PAA_rpt_list_add","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Additions", " (Menu-PAA) Report No: ", l_report_num USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_add TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	LET glob_pr_add_cnt = 0 
	SELECT unique 1 FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "1" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 
	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_add(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN --EXIT FOREACH 
		END IF 
		#---------------------------------------------------------				
	ELSE 
		DISPLAY "Inserted Vendor..." at 1,2 
		DECLARE add_curs CURSOR FOR 
		SELECT * FROM vendoraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "1" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY vend_code 
		FOREACH add_curs INTO l_rec_vendoraudit.* 
			LET glob_pr_add_cnt = glob_pr_add_cnt + 1 

			#---------------------------------------------------------
			OUTPUT TO REPORT PAA_rpt_list_add(l_rpt_idx,
			l_rec_vendoraudit.*) 
			IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
			
			UPDATE vendoraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_vendoraudit.cmpy_code 
			AND vend_code = l_rec_vendoraudit.vend_code 
			AND audit_ind = l_rec_vendoraudit.audit_ind 
			AND audit_date = l_rec_vendoraudit.audit_date 
		END FOREACH 
	END IF 


	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_add
	CALL rpt_finish("PAA_rpt_list_add")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true

	#######################################################################################################
	# 2nd Report - Alterations - REPORT PAA_rpt_list_upd                                                                                         #
	#######################################################################################################

	#------------------------------------------------------------
	# Second Report - Alterations ###
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-2-ALT","PAA_rpt_list_upd","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Alterations", " (Menu-PAA) Report No: ", l_report_num USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_upd TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
 
	LET glob_upd_cnt = 0 
	SELECT unique 1 FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "2" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 
	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_upd(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN 
		END IF 
		#---------------------------------------------------------	
		 
	ELSE 
		DISPLAY "Modified Vendor..." at 1,2 
		DECLARE upd_curs CURSOR FOR 
		SELECT * FROM vendoraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "2" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY vend_code, audit_date 

		FOREACH upd_curs INTO l_rec_vendoraudit.* 
			LET glob_upd_cnt = glob_upd_cnt + 1 

			#---------------------------------------------------------
			OUTPUT TO REPORT PAA_rpt_list_upd(l_rpt_idx,
			l_rec_vendoraudit.*) 
			IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
			 
			UPDATE vendoraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_vendoraudit.cmpy_code 
			AND vend_code = l_rec_vendoraudit.vend_code 
			AND audit_ind = l_rec_vendoraudit.audit_ind 
			AND audit_date = l_rec_vendoraudit.audit_date 
		END FOREACH 

	END IF 
	

	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_upd
	CALL rpt_finish("PAA_rpt_list_upd")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	  
	#######################################################################################################
	# 3rd Report  - Deletions - REPORT PAA_rpt_list_del                                                   #
	#######################################################################################################
	#------------------------------------------------------------	
	# Third Report - Deletions ###
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-3-DEL","PAA_rpt_list_del","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Deletions", " (Menu-PAA) Report No: ", l_report_num USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_del TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------

	 
	LET glob_del_cnt = 0 
	SELECT unique 1 FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "3" 
	AND print_date IS NULL 
	AND audit_date <= l_exp_date 
	IF status = NOTFOUND THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 

		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_del(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN 
		END IF 
		#---------------------------------------------------------	
		
	ELSE 
		DISPLAY "Deleted Vendor...." at 1,2 
		DECLARE del_curs CURSOR FOR 
		SELECT * FROM vendoraudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND audit_ind = "3" 
		AND print_date IS NULL 
		AND audit_date <= l_exp_date 
		ORDER BY vend_code 
		FOREACH del_curs INTO l_rec_vendoraudit.* 
			LET glob_del_cnt = glob_del_cnt + 1 

			#---------------------------------------------------------
			OUTPUT TO REPORT PAA_rpt_list_del(l_rpt_idx,
			l_rec_vendoraudit.*) 
			IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------	
			
			UPDATE vendoraudit 
			SET print_date = today 
			WHERE cmpy_code = l_rec_vendoraudit.cmpy_code 
			AND vend_code = l_rec_vendoraudit.vend_code 
			AND audit_ind = l_rec_vendoraudit.audit_ind 
			AND audit_date = l_rec_vendoraudit.audit_date 
		END FOREACH 
	END IF 
	

	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_del
	CALL rpt_finish("PAA_rpt_list_del")
	#------------------------------------------------------------

	UPDATE nextnumber #???
	SET next_num = l_report_num + 1 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tran_type_ind = "UAP" 
	RETURN true 
		 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION PAA_rpt_process(p_where_text)
############################################################


############################################################
# FUNCTION PAA_reprint()
#
#
############################################################
FUNCTION PAA_reprint() 
	DEFINE l_rec_vendoraudit RECORD LIKE vendoraudit.*
	DEFINE l_rpt_idx SMALLINT  #report array index	
	DEFINE l_tmp_str STRING #report header appendix string 
--	DEFINE l_rpt_output CHAR(50) 
--	DEFINE l_output STRING #report output file name inc. path

	#######################################################################################################
	# REPRINT - 1st Report  - Additions - REPORT PAA_rpt_list_add                                                   #
	#######################################################################################################
	#------------------------------------------------------------
	# REPRINT - First Report - Additions ###
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-1-ADD","PAA_rpt_list_add","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Additions REPRINT", " (Menu-PAA) Report No: ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_add TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
	 
	DECLARE add_rp_curs CURSOR FOR 
	SELECT * FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "1" 
	AND print_date IS NOT NULL 
	ORDER BY vend_code 

	 
	LET glob_pr_add_cnt = 0 
	FOREACH add_rp_curs INTO l_rec_vendoraudit.* 
		LET glob_pr_add_cnt = glob_pr_add_cnt + 1 

		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_add(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		 
	END FOREACH 
	
	IF glob_pr_add_cnt = 0 THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 

		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_add(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN 
		END IF 
		#---------------------------------------------------------	

	END IF 

	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_add
	CALL rpt_finish("PAA_rpt_list_add")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 



	#######################################################################################################
	# REPRINT - 2nd Report  - Alterations - REPORT PAA_rpt_list_upd                                                  #
	#######################################################################################################
	#------------------------------------------------------------
	# REPRINT - 2nd Report - Alterations - REPORT PAA_rpt_list_upd 
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-2-ALT","PAA_rpt_list_upd","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Alterations REPRINT", " (Menu-PAA) Report No: ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_upd TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	
		
	 
	DECLARE upd_rp_curs CURSOR FOR 
	SELECT * FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "2" 
	AND print_date IS NOT NULL 
	ORDER BY vend_code, audit_date 
	LET glob_upd_cnt = 0 
	
	FOREACH upd_rp_curs INTO l_rec_vendoraudit.* 
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_upd(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	
		LET glob_upd_cnt = glob_upd_cnt + 1 
	END FOREACH 
	
	IF glob_upd_cnt = 0 THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_upd(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN
		END IF 
		#---------------------------------------------------------			
	END IF 

	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_upd
	CALL rpt_finish("PAA_rpt_list_upd")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 
 	
	#######################################################################################################
	# REPRINT - 3rd Report  - Deletions - REPORT PAA_rpt_list_del                                                 #
	#######################################################################################################
	#------------------------------------------------------------
	# REPRINT - 3rd Report - Deletions - REPORT PAA_rpt_list_del
	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
--	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
--		LET int_flag = false 
--		LET quit_flag = false
--
--		RETURN FALSE
--	END IF

	LET l_rpt_idx = rpt_start("PAA-3-DEL","PAA_rpt_list_del","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	#------------------------------------------------------------
	LET l_tmp_str = " - Deletions REPRINT", " (Menu-PAA) Report No: ", glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_code USING "<<<&"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL,l_tmp_str)
	#------------------------------------------------------------

	START REPORT PAA_rpt_list_del TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
			
	DECLARE del_rp_curs CURSOR FOR 
	SELECT * FROM vendoraudit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND audit_ind = "3" 
	AND print_date IS NOT NULL 
	ORDER BY vend_code 
	LET glob_del_cnt = 0 
	FOREACH del_rp_curs INTO l_rec_vendoraudit.* 
		LET glob_del_cnt = glob_del_cnt + 1 
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_del(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
		
	END FOREACH 
	IF glob_del_cnt = 0 THEN 
		INITIALIZE l_rec_vendoraudit.* TO NULL 
		#---------------------------------------------------------
		OUTPUT TO REPORT PAA_rpt_list_del(l_rpt_idx,
		l_rec_vendoraudit.*) 
		IF NOT rpt_int_flag_handler2("Vendor:",l_rec_vendoraudit.vend_code, NULL,l_rpt_idx) THEN
			RETURN
		END IF 
		#---------------------------------------------------------			
	END IF 

	#------------------------------------------------------------
	FINISH REPORT PAA_rpt_list_del
	CALL rpt_finish("PAA_rpt_list_del")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
	RETURN true 
END FUNCTION 



############################################################
# REPORT PAA_rpt_list_add(p_rpt_idx,p_rec_vendoraudit)
#
#
############################################################
REPORT PAA_rpt_list_add(p_rpt_idx,p_rec_vendoraudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_cmpy_head CHAR(132)
	DEFINE i SMALLINT 
--	DEFINE i, col2, col SMALLINT 

	OUTPUT 
 
	ORDER external BY p_rec_vendoraudit.vend_code,p_rec_vendoraudit.audit_date
	 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Vendor", 
			COLUMN 10, "Name/Contact Details", 
			COLUMN 46, "Address", 
			COLUMN 82, "Curr Type Term Tax", 
			COLUMN 111,"Hold Sub Lang Pay" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			NEED 6 LINES 
			IF p_rec_vendoraudit.vend_code IS NOT NULL THEN 
				PRINT COLUMN 01, p_rec_vendoraudit.vend_code, 
				COLUMN 10, p_rec_vendoraudit.name_text, 
				COLUMN 46, p_rec_vendoraudit.addr1_text[1,30], 
				COLUMN 82, p_rec_vendoraudit.currency_code, 
				COLUMN 87, p_rec_vendoraudit.type_code, 
				COLUMN 92, p_rec_vendoraudit.term_code, 
				COLUMN 97, p_rec_vendoraudit.tax_code, 
				COLUMN 101, p_rec_vendoraudit.tax_text, 
				COLUMN 112, p_rec_vendoraudit.hold_code, 
				COLUMN 117, p_rec_vendoraudit.drop_flag, 
				COLUMN 121, p_rec_vendoraudit.language_code, 
				COLUMN 126, p_rec_vendoraudit.pay_meth_ind
				 
				FOR i = 1 TO 2 
					IF p_rec_vendoraudit.addr2_text IS NULL THEN 
						LET p_rec_vendoraudit.addr2_text = p_rec_vendoraudit.addr3_text 
						LET p_rec_vendoraudit.addr3_text = p_rec_vendoraudit.city_text 
						LET p_rec_vendoraudit.city_text = NULL 
					END IF 
				END FOR 
				
				IF p_rec_vendoraudit.addr3_text IS NULL THEN 
					LET p_rec_vendoraudit.addr3_text = p_rec_vendoraudit.city_text 
					LET p_rec_vendoraudit.city_text = NULL 
				END IF 
				PRINT COLUMN 10, "Att: ", 
				COLUMN 15, p_rec_vendoraudit.contact_text;
				 
				IF p_rec_vendoraudit.addr2_text IS NOT NULL THEN 
					PRINT COLUMN 46, p_rec_vendoraudit.addr2_text[1,30]; 
				ELSE 
					PRINT COLUMN 46, p_rec_vendoraudit.state_code clipped, " ", 
					p_rec_vendoraudit.post_code clipped, " ", 
					p_rec_vendoraudit.country_code clipped; --@db-patch_2020_10_04 report--
 
					LET p_rec_vendoraudit.state_code = NULL 
					LET p_rec_vendoraudit.post_code = NULL 
					LET p_rec_vendoraudit.country_code = NULL  --@db-patch_2020_10_04 report--
				END IF
				 
				PRINT COLUMN 82, "Our Account: ", 
				COLUMN 96, p_rec_vendoraudit.our_acct_code 
				PRINT COLUMN 10, "Ph: ", 
				COLUMN 15, p_rec_vendoraudit.tele_text, 
				COLUMN 36, p_rec_vendoraudit.extension_text;
				 
				IF p_rec_vendoraudit.addr3_text IS NOT NULL THEN 
					PRINT COLUMN 46, p_rec_vendoraudit.addr3_text[1,30]; 
				ELSE 
					PRINT COLUMN 46, p_rec_vendoraudit.state_code clipped, " ", 
					p_rec_vendoraudit.post_code clipped, " ", 
					p_rec_vendoraudit.country_code clipped; --@d--@db-patch_2020_10_04 report--					LET p_rec_vendoraudit.state_code = NULL 
					LET p_rec_vendoraudit.post_code = NULL					 
					LET p_rec_vendoraudit.country_code = NULL --@db-patch_2020_10_04 report-- 
				END IF 
				
				PRINT COLUMN 82, "Bank Account: ", 
				COLUMN 96, p_rec_vendoraudit.bank_acct_code 
				PRINT COLUMN 10, "Fax: ", 
				COLUMN 15, p_rec_vendoraudit.fax_text; 
				IF p_rec_vendoraudit.city_text IS NOT NULL THEN 
					PRINT COLUMN 46, p_rec_vendoraudit.city_text[1,30]; 
				ELSE 
					PRINT COLUMN 46, p_rec_vendoraudit.state_code clipped, " ", 
					p_rec_vendoraudit.post_code clipped, " ", 
					p_rec_vendoraudit.country_code clipped; --@db-patch_2020_10_04 report--

					LET p_rec_vendoraudit.state_code = NULL 
					LET p_rec_vendoraudit.post_code = NULL 
					LET p_rec_vendoraudit.country_code = NULL --@db-patch_2020_10_04 report--
				END IF
				 
				PRINT COLUMN 82, "Credit Limit:", 
				COLUMN 96, p_rec_vendoraudit.limit_amt USING "<<<<<<<<<<<<<&.&&" 
				IF p_rec_vendoraudit.city_text IS NOT NULL THEN 
					PRINT COLUMN 10,"ABN:",p_rec_vendoraudit.vat_code, 
					COLUMN 46, p_rec_vendoraudit.state_code clipped, " ", 
					p_rec_vendoraudit.post_code clipped, " ", 
					p_rec_vendoraudit.country_code clipped; --@db-patch_2020_10_04 report 
					
				ELSE 
					PRINT COLUMN 10,"ABN:",p_rec_vendoraudit.vat_code; 
				END IF 
				PRINT COLUMN 82, "User: ", 
				COLUMN 96, p_rec_vendoraudit.user_code, 
				COLUMN 105, p_rec_vendoraudit.audit_date 
			END IF 
			SKIP 1 line
			 
		ON LAST ROW 
			NEED 9 LINES 
			SKIP 1 LINES 
			PRINT COLUMN 15, "Total Vendor Additions: ", 
			COLUMN 39, glob_pr_add_cnt USING "<<<<&" 
			SKIP 3 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# REPORT PAA_rpt_list_add(p_rpt_idx,p_rec_vendoraudit)
############################################################


############################################################
# REPORT PAA_rpt_list_upd(p_rpt_idx,p_rec_vendoraudit)
#
#
############################################################
REPORT PAA_rpt_list_upd(p_rpt_idx,p_rec_vendoraudit)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_cmpy_head CHAR(132) 
	DEFINE l_table CHAR(11) 
	DEFINE l_col2, l_col SMALLINT

	OUTPUT 

	ORDER external BY p_rec_vendoraudit.vend_code,p_rec_vendoraudit.audit_date 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Vendor", 
			COLUMN 21, "Old Values", 
			COLUMN 62, "New Values", 
			COLUMN 103,"User", 
			COLUMN 112,"Date", 
			COLUMN 123,"Time" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			NEED 10 LINES 
			DECLARE c_vaudit CURSOR FOR 
			SELECT * FROM vendoraudit 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_vendoraudit.vend_code 
			AND audit_date > p_rec_vendoraudit.audit_date 
			OPEN c_vaudit 
			FETCH c_vaudit INTO l_rec_vendoraudit.* 
			IF status = NOTFOUND THEN 
				LET l_table = "Vendor" 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = p_rec_vendoraudit.vend_code 
				IF status = NOTFOUND THEN 
					INITIALIZE l_rec_vendor.* TO NULL 
				END IF 
			ELSE 
				LET l_table = "Vendoraudit" 
			END IF 
			
			IF l_table = "Vendoraudit" THEN 
				#Check TO see IF printout IS required. This problem IS caused by
				#the ' UPDATE vendor SET * = l_rec_vendor.* ' all over the code
				IF NOT table1_mods(l_rec_vendoraudit.*,p_rec_vendoraudit.*) THEN 
					LET glob_upd_cnt = glob_upd_cnt - 1 
				ELSE 
					PRINT COLUMN 01, p_rec_vendoraudit.vend_code, 
					COLUMN 103, p_rec_vendoraudit.user_code, 
					COLUMN 112, p_rec_vendoraudit.audit_date 
					IF (l_rec_vendoraudit.name_text IS NULL AND 
					p_rec_vendoraudit.name_text IS NOT null) 
					OR (p_rec_vendoraudit.name_text IS NULL AND 
					l_rec_vendoraudit.name_text IS NOT null) 
					OR (l_rec_vendoraudit.name_text != p_rec_vendoraudit.name_text) THEN 
						PRINT COLUMN 04, "Name:", 
						COLUMN 21, p_rec_vendoraudit.name_text, 
						COLUMN 62, l_rec_vendoraudit.name_text 
					END IF 
					
					IF (l_rec_vendoraudit.addr1_text IS NULL AND 
					p_rec_vendoraudit.addr1_text IS NOT null) 
					OR (p_rec_vendoraudit.addr1_text IS NULL AND 
					l_rec_vendoraudit.addr1_text IS NOT null) 
					OR (l_rec_vendoraudit.addr1_text != p_rec_vendoraudit.addr1_text) THEN 
						PRINT COLUMN 04, "Address Line 1:", 
						COLUMN 21, p_rec_vendoraudit.addr1_text, 
						COLUMN 62, l_rec_vendoraudit.addr1_text 
					END IF 
					
					IF (l_rec_vendoraudit.addr2_text IS NULL AND 
					p_rec_vendoraudit.addr2_text IS NOT null) 
					OR (p_rec_vendoraudit.addr2_text IS NULL AND 
					l_rec_vendoraudit.addr2_text IS NOT null) 
					OR (l_rec_vendoraudit.addr2_text != p_rec_vendoraudit.addr2_text) THEN 
						PRINT COLUMN 04, "Address Line 2:", 
						COLUMN 21, p_rec_vendoraudit.addr2_text, 
						COLUMN 62, l_rec_vendoraudit.addr2_text 
					END IF 
					
					IF (l_rec_vendoraudit.addr3_text IS NULL AND 
					p_rec_vendoraudit.addr3_text IS NOT null) 
					OR (p_rec_vendoraudit.addr3_text IS NULL AND 
					l_rec_vendoraudit.addr3_text IS NOT null) 
					OR (l_rec_vendoraudit.addr3_text != p_rec_vendoraudit.addr3_text) THEN 
						PRINT COLUMN 04, "Address Line 3:", 
						COLUMN 21, p_rec_vendoraudit.addr3_text, 
						COLUMN 62, l_rec_vendoraudit.addr3_text 
					END IF 
					
					IF (l_rec_vendoraudit.city_text IS NULL AND 
					p_rec_vendoraudit.city_text IS NOT null) 
					OR (p_rec_vendoraudit.city_text IS NULL AND 
					l_rec_vendoraudit.city_text IS NOT null) 
					OR (l_rec_vendoraudit.city_text != p_rec_vendoraudit.city_text) THEN 
						PRINT COLUMN 04, "City:", 
						COLUMN 21, p_rec_vendoraudit.city_text, 
						COLUMN 62, l_rec_vendoraudit.city_text 
					END IF 
					
					IF (l_rec_vendoraudit.state_code IS NULL AND 
					p_rec_vendoraudit.state_code IS NOT null) 
					OR (p_rec_vendoraudit.state_code IS NULL AND 
					l_rec_vendoraudit.state_code IS NOT null) 
					OR (l_rec_vendoraudit.state_code != p_rec_vendoraudit.state_code) THEN 
						PRINT COLUMN 04, "State:", 
						COLUMN 21, p_rec_vendoraudit.state_code, 
						COLUMN 62, l_rec_vendoraudit.state_code 
					END IF 
					
					IF (l_rec_vendoraudit.post_code IS NULL AND 
					p_rec_vendoraudit.post_code IS NOT null) 
					OR (p_rec_vendoraudit.post_code IS NULL AND 
					l_rec_vendoraudit.post_code IS NOT null) 
					OR (l_rec_vendoraudit.post_code != p_rec_vendoraudit.post_code) THEN 
						PRINT COLUMN 04, "Post Code:", 
						COLUMN 21, p_rec_vendoraudit.post_code, 
						COLUMN 62, l_rec_vendoraudit.post_code 
					END IF 
					
					IF (l_rec_vendoraudit.country_code IS NULL AND 
					p_rec_vendoraudit.country_code IS NOT null) 
					OR (p_rec_vendoraudit.country_code IS NULL AND 
					l_rec_vendoraudit.country_code IS NOT null) 
					OR (l_rec_vendoraudit.country_code != p_rec_vendoraudit.country_code) THEN 
						PRINT COLUMN 04, "Country Code:", 
						COLUMN 21, p_rec_vendoraudit.country_code, 
						COLUMN 62, l_rec_vendoraudit.country_code 
					END IF 
					
					IF (l_rec_vendoraudit.language_code IS NULL AND 
					p_rec_vendoraudit.language_code IS NOT null) 
					OR (p_rec_vendoraudit.language_code IS NULL AND 
					l_rec_vendoraudit.language_code IS NOT null) 
					OR (l_rec_vendoraudit.language_code != 
					p_rec_vendoraudit.language_code) THEN 
						PRINT COLUMN 04, "Language Code:", 
						COLUMN 21, p_rec_vendoraudit.language_code, 
						COLUMN 62, l_rec_vendoraudit.language_code 
					END IF 
					
					IF (l_rec_vendoraudit.type_code IS NULL AND 
					p_rec_vendoraudit.type_code IS NOT null) 
					OR (p_rec_vendoraudit.type_code IS NULL AND 
					l_rec_vendoraudit.type_code IS NOT null) 
					OR (l_rec_vendoraudit.type_code != p_rec_vendoraudit.type_code) THEN 
						PRINT COLUMN 04, "Vendor Type Code:", 
						COLUMN 21, p_rec_vendoraudit.type_code, 
						COLUMN 62, l_rec_vendoraudit.type_code 
					END IF 
					
					IF (l_rec_vendoraudit.term_code IS NULL AND 
					p_rec_vendoraudit.term_code IS NOT null) 
					OR (p_rec_vendoraudit.term_code IS NULL AND 
					l_rec_vendoraudit.term_code IS NOT null) 
					OR (l_rec_vendoraudit.term_code != p_rec_vendoraudit.term_code) THEN 
						PRINT COLUMN 04, "Vendor Term Code:", 
						COLUMN 21, p_rec_vendoraudit.term_code, 
						COLUMN 62, l_rec_vendoraudit.term_code 
					END IF 
					
					IF (l_rec_vendoraudit.tax_code IS NULL AND 
					p_rec_vendoraudit.tax_code IS NOT null) 
					OR (p_rec_vendoraudit.tax_code IS NULL AND 
					l_rec_vendoraudit.tax_code IS NOT null) 
					OR (l_rec_vendoraudit.tax_code != p_rec_vendoraudit.tax_code) THEN 
						PRINT COLUMN 04, "Vendor Tax Code:", 
						COLUMN 21, p_rec_vendoraudit.tax_code, 
						COLUMN 62, l_rec_vendoraudit.tax_code 
					END IF 
					
					IF (l_rec_vendoraudit.tax_text IS NULL AND 
					p_rec_vendoraudit.tax_text IS NOT null) 
					OR (p_rec_vendoraudit.tax_text IS NULL AND 
					l_rec_vendoraudit.tax_text IS NOT null) 
					OR (l_rec_vendoraudit.tax_text != p_rec_vendoraudit.tax_text) THEN 
						PRINT COLUMN 04, "Tax Number:", 
						COLUMN 21, p_rec_vendoraudit.tax_text, 
						COLUMN 62, l_rec_vendoraudit.tax_text 
					END IF 
					
					IF (l_rec_vendoraudit.our_acct_code IS NULL AND 
					p_rec_vendoraudit.our_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.our_acct_code IS NULL AND 
					l_rec_vendoraudit.our_acct_code IS NOT null) 
					OR (l_rec_vendoraudit.our_acct_code != 
					p_rec_vendoraudit.our_acct_code) THEN 
						PRINT COLUMN 04, "Our Account Code:", 
						COLUMN 21, p_rec_vendoraudit.our_acct_code, 
						COLUMN 62, l_rec_vendoraudit.our_acct_code 
					END IF 
					
					IF (l_rec_vendoraudit.usual_acct_code IS NULL AND 
					p_rec_vendoraudit.usual_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.usual_acct_code IS NULL AND 
					l_rec_vendoraudit.usual_acct_code IS NOT null) 
					OR (l_rec_vendoraudit.usual_acct_code != 
					p_rec_vendoraudit.usual_acct_code) THEN 
						PRINT COLUMN 04, "Purchases Acct:", 
						COLUMN 21, p_rec_vendoraudit.usual_acct_code, 
						COLUMN 62, l_rec_vendoraudit.usual_acct_code 
					END IF 
					
					IF (l_rec_vendoraudit.contact_text IS NULL AND 
					p_rec_vendoraudit.contact_text IS NOT null) 
					OR (p_rec_vendoraudit.contact_text IS NULL AND 
					l_rec_vendoraudit.contact_text IS NOT null) 
					OR (l_rec_vendoraudit.contact_text != p_rec_vendoraudit.contact_text) THEN 
						PRINT COLUMN 04, "Contact:", 
						COLUMN 21, p_rec_vendoraudit.contact_text, 
						COLUMN 62, l_rec_vendoraudit.contact_text 
					END IF 
					
					IF (l_rec_vendoraudit.tele_text IS NULL AND 
					p_rec_vendoraudit.tele_text IS NOT null) 
					OR (p_rec_vendoraudit.tele_text IS NULL AND 
					l_rec_vendoraudit.tele_text IS NOT null) 
					OR (l_rec_vendoraudit.tele_text != p_rec_vendoraudit.tele_text) THEN 
						PRINT COLUMN 04, "Telephone:", 
						COLUMN 21, p_rec_vendoraudit.tele_text, 
						COLUMN 62, l_rec_vendoraudit.tele_text 
					END IF 
					
					IF (l_rec_vendoraudit.extension_text IS NULL AND 
					p_rec_vendoraudit.extension_text IS NOT null) 
					OR (p_rec_vendoraudit.extension_text IS NULL AND 
					l_rec_vendoraudit.extension_text IS NOT null) 
					OR (l_rec_vendoraudit.extension_text != 
					p_rec_vendoraudit.extension_text) THEN 
						PRINT COLUMN 04, "Telephone Ext:", 
						COLUMN 21, p_rec_vendoraudit.extension_text, 
						COLUMN 62, l_rec_vendoraudit.extension_text 
					END IF 
					
					IF (l_rec_vendoraudit.fax_text IS NULL AND 
					p_rec_vendoraudit.fax_text IS NOT null) 
					OR (p_rec_vendoraudit.fax_text IS NULL AND 
					l_rec_vendoraudit.fax_text IS NOT null) 
					OR (l_rec_vendoraudit.fax_text != p_rec_vendoraudit.fax_text) THEN 
						PRINT COLUMN 04, "Fax Number:", 
						COLUMN 21, p_rec_vendoraudit.fax_text, 
						COLUMN 62, l_rec_vendoraudit.fax_text 
					END IF 
					
					IF (l_rec_vendoraudit.limit_amt IS NULL AND 
					p_rec_vendoraudit.limit_amt IS NOT null) 
					OR (p_rec_vendoraudit.limit_amt IS NULL AND 
					l_rec_vendoraudit.limit_amt IS NOT null) 
					OR (l_rec_vendoraudit.limit_amt != p_rec_vendoraudit.limit_amt) THEN 
						PRINT COLUMN 04, "Credit Limit:", 
						COLUMN 21, p_rec_vendoraudit.limit_amt 
						USING "<<<<<<<<<<<<<&.&&", 
						COLUMN 62, l_rec_vendoraudit.limit_amt 
						USING "<<<<<<<<<<<<<&.&&" 
					END IF 
					
					IF (l_rec_vendoraudit.hold_code IS NULL AND 
					p_rec_vendoraudit.hold_code IS NOT null) 
					OR (p_rec_vendoraudit.hold_code IS NULL AND 
					l_rec_vendoraudit.hold_code IS NOT null) 
					OR (l_rec_vendoraudit.hold_code != p_rec_vendoraudit.hold_code) THEN 
						PRINT COLUMN 04, "Hold Code:", 
						COLUMN 21, p_rec_vendoraudit.hold_code, 
						COLUMN 62, l_rec_vendoraudit.hold_code 
					END IF 
					
					IF (l_rec_vendoraudit.drop_flag IS NULL AND 
					p_rec_vendoraudit.drop_flag IS NOT null) 
					OR (p_rec_vendoraudit.drop_flag IS NULL AND 
					l_rec_vendoraudit.drop_flag IS NOT null) 
					OR (l_rec_vendoraudit.drop_flag != p_rec_vendoraudit.drop_flag) THEN 
						PRINT COLUMN 04, "Subcontractor:", 
						COLUMN 21, p_rec_vendoraudit.drop_flag, 
						COLUMN 62, l_rec_vendoraudit.drop_flag 
					END IF 
					
					IF (l_rec_vendoraudit.finance_per IS NULL AND 
					p_rec_vendoraudit.finance_per IS NOT null) 
					OR (p_rec_vendoraudit.finance_per IS NULL AND 
					l_rec_vendoraudit.finance_per IS NOT null) 
					OR (l_rec_vendoraudit.finance_per != p_rec_vendoraudit.finance_per) THEN 
						PRINT COLUMN 04, "Fianance Charge:", 
						COLUMN 21, p_rec_vendoraudit.finance_per, 
						COLUMN 62, l_rec_vendoraudit.finance_per 
					END IF 
					IF (l_rec_vendoraudit.currency_code IS NULL AND 
					p_rec_vendoraudit.currency_code IS NOT null) 
					OR (p_rec_vendoraudit.currency_code IS NULL AND 
					l_rec_vendoraudit.currency_code IS NOT null) 
					OR (l_rec_vendoraudit.currency_code != 
					p_rec_vendoraudit.currency_code) THEN 
						PRINT COLUMN 04, "Currency Code:", 
						COLUMN 21, p_rec_vendoraudit.currency_code, 
						COLUMN 62, l_rec_vendoraudit.currency_code 
					END IF
					 
					IF (l_rec_vendoraudit.bank_acct_code IS NULL AND 
					p_rec_vendoraudit.bank_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.bank_acct_code IS NULL AND 
					l_rec_vendoraudit.bank_acct_code IS NOT null) 
					OR (l_rec_vendoraudit.bank_acct_code != 
					p_rec_vendoraudit.bank_acct_code) THEN 
						PRINT COLUMN 04, "Bank Code:", 
						COLUMN 21, p_rec_vendoraudit.bank_acct_code, 
						COLUMN 62, l_rec_vendoraudit.bank_acct_code 
					END IF
					 
					IF (l_rec_vendoraudit.pay_meth_ind IS NULL AND 
					p_rec_vendoraudit.pay_meth_ind IS NOT null) 
					OR (p_rec_vendoraudit.pay_meth_ind IS NULL AND 
					l_rec_vendoraudit.pay_meth_ind IS NOT null) 
					OR (l_rec_vendoraudit.pay_meth_ind != 
					p_rec_vendoraudit.pay_meth_ind) THEN 
						PRINT COLUMN 04, "Payment Method:", 
						COLUMN 21, p_rec_vendoraudit.pay_meth_ind, 
						COLUMN 62, l_rec_vendoraudit.pay_meth_ind 
					END IF
					 
					IF (l_rec_vendoraudit.vat_code IS NULL AND 
					p_rec_vendoraudit.vat_code IS NOT null) 
					OR (p_rec_vendoraudit.vat_code IS NULL AND 
					l_rec_vendoraudit.vat_code IS NOT null) 
					OR (l_rec_vendoraudit.vat_code != 
					p_rec_vendoraudit.vat_code) THEN 
						PRINT COLUMN 04, "ABN:", 
						COLUMN 21, p_rec_vendoraudit.vat_code, 
						COLUMN 62, l_rec_vendoraudit.vat_code 
					END IF 
					SKIP 1 line 
				END IF 
			END IF 
			
			IF l_table = "Vendor" THEN 
				#Check TO see IF printout IS required. This problem IS caused by
				#the ' UPDATE vendor SET * = l_rec_vendor.* ' all over the code
				IF NOT table2_mods(p_rec_vendoraudit.*,l_rec_vendor.*) THEN 
					LET glob_upd_cnt = glob_upd_cnt - 1 
				ELSE 
					PRINT COLUMN 01, p_rec_vendoraudit.vend_code, 
					COLUMN 103, p_rec_vendoraudit.user_code, 
					COLUMN 112, p_rec_vendoraudit.audit_date 
					
					IF (l_rec_vendor.name_text IS NULL AND 
					p_rec_vendoraudit.name_text IS NOT null) 
					OR (p_rec_vendoraudit.name_text IS NULL AND 
					l_rec_vendor.name_text IS NOT null) 
					OR (l_rec_vendor.name_text != p_rec_vendoraudit.name_text) THEN 
						PRINT COLUMN 04, "Name:", 
						COLUMN 21, p_rec_vendoraudit.name_text, 
						COLUMN 62, l_rec_vendor.name_text 
					END IF 
					
					IF (l_rec_vendor.addr1_text IS NULL AND 
					p_rec_vendoraudit.addr1_text IS NOT null) 
					OR (p_rec_vendoraudit.addr1_text IS NULL AND 
					l_rec_vendor.addr1_text IS NOT null) 
					OR (l_rec_vendor.addr1_text != p_rec_vendoraudit.addr1_text) THEN 
						PRINT COLUMN 04, "Address Line 1:", 
						COLUMN 21, p_rec_vendoraudit.addr1_text, 
						COLUMN 62, l_rec_vendor.addr1_text 
					END IF 
					
					IF (l_rec_vendor.addr2_text IS NULL AND 
					p_rec_vendoraudit.addr2_text IS NOT null) 
					OR (p_rec_vendoraudit.addr2_text IS NULL AND 
					l_rec_vendor.addr2_text IS NOT null) 
					OR (l_rec_vendor.addr2_text != p_rec_vendoraudit.addr2_text) THEN 
						PRINT COLUMN 04, "Address Line 2:", 
						COLUMN 21, p_rec_vendoraudit.addr2_text, 
						COLUMN 62, l_rec_vendor.addr2_text 
					END IF 
					
					IF (l_rec_vendor.addr3_text IS NULL AND 
					p_rec_vendoraudit.addr3_text IS NOT null) 
					OR (p_rec_vendoraudit.addr3_text IS NULL AND 
					l_rec_vendor.addr3_text IS NOT null) 
					OR (l_rec_vendor.addr3_text != p_rec_vendoraudit.addr3_text) THEN 
						PRINT COLUMN 04, "Address Line 3:", 
						COLUMN 21, p_rec_vendoraudit.addr3_text, 
						COLUMN 62, l_rec_vendor.addr3_text 
					END IF 
					
					IF (l_rec_vendor.city_text IS NULL AND 
					p_rec_vendoraudit.city_text IS NOT null) 
					OR (p_rec_vendoraudit.city_text IS NULL AND 
					l_rec_vendor.city_text IS NOT null) 
					OR (l_rec_vendor.city_text != p_rec_vendoraudit.city_text) THEN 
						PRINT COLUMN 04, "City:", 
						COLUMN 21, p_rec_vendoraudit.city_text, 
						COLUMN 62, l_rec_vendor.city_text 
					END IF 
					
					IF (l_rec_vendor.state_code IS NULL AND 
					p_rec_vendoraudit.state_code IS NOT null) 
					OR (p_rec_vendoraudit.state_code IS NULL AND 
					l_rec_vendor.state_code IS NOT null) 
					OR (l_rec_vendor.state_code != p_rec_vendoraudit.state_code) THEN 
						PRINT COLUMN 04, "State:", 
						COLUMN 21, p_rec_vendoraudit.state_code, 
						COLUMN 62, l_rec_vendor.state_code 
					END IF
					 
					IF (l_rec_vendor.post_code IS NULL AND 
					p_rec_vendoraudit.post_code IS NOT null) 
					OR (p_rec_vendoraudit.post_code IS NULL AND 
					l_rec_vendor.post_code IS NOT null) 
					OR (l_rec_vendor.post_code != p_rec_vendoraudit.post_code) THEN 
						PRINT COLUMN 04, "Post Code:", 
						COLUMN 21, p_rec_vendoraudit.post_code, 
						COLUMN 62, l_rec_vendor.post_code 
					END IF 
					
					IF (l_rec_vendor.country_code IS NULL AND 
					p_rec_vendoraudit.country_code IS NOT null) 
					OR (p_rec_vendoraudit.country_code IS NULL AND 
					l_rec_vendor.country_code IS NOT null) 
					OR (l_rec_vendor.country_code != p_rec_vendoraudit.country_code) THEN 
						PRINT COLUMN 04, "Country Code:", 
						COLUMN 21, p_rec_vendoraudit.country_code, 
						COLUMN 62, l_rec_vendor.country_code 
					END IF 
					
					IF (l_rec_vendor.language_code IS NULL AND 
					p_rec_vendoraudit.language_code IS NOT null) 
					OR (p_rec_vendoraudit.language_code IS NULL AND 
					l_rec_vendor.language_code IS NOT null) 
					OR (l_rec_vendor.language_code != p_rec_vendoraudit.language_code) THEN 
						PRINT COLUMN 04, "Language Code:", 
						COLUMN 21, p_rec_vendoraudit.language_code, 
						COLUMN 62, l_rec_vendor.language_code 
					END IF 
					
					IF (l_rec_vendor.type_code IS NULL AND 
					p_rec_vendoraudit.type_code IS NOT null) 
					OR (p_rec_vendoraudit.type_code IS NULL AND 
					l_rec_vendor.type_code IS NOT null) 
					OR (l_rec_vendor.type_code != p_rec_vendoraudit.type_code) THEN 
						PRINT COLUMN 04, "Vendor Type Code:", 
						COLUMN 21, p_rec_vendoraudit.type_code, 
						COLUMN 62, l_rec_vendor.type_code 
					END IF 
					
					IF (l_rec_vendor.term_code IS NULL AND 
					p_rec_vendoraudit.term_code IS NOT null) 
					OR (p_rec_vendoraudit.term_code IS NULL AND 
					l_rec_vendor.term_code IS NOT null) 
					OR (l_rec_vendor.term_code != p_rec_vendoraudit.term_code) THEN 
						PRINT COLUMN 04, "Vendor Term Code:", 
						COLUMN 21, p_rec_vendoraudit.term_code, 
						COLUMN 62, l_rec_vendor.term_code 
					END IF 
					
					IF (l_rec_vendor.tax_code IS NULL AND 
					p_rec_vendoraudit.tax_code IS NOT null) 
					OR (p_rec_vendoraudit.tax_code IS NULL AND 
					l_rec_vendor.tax_code IS NOT null) 
					OR (l_rec_vendor.tax_code != p_rec_vendoraudit.tax_code) THEN 
						PRINT COLUMN 04, "Vendor Tax Code:", 
						COLUMN 21, p_rec_vendoraudit.tax_code, 
						COLUMN 62, l_rec_vendor.tax_code 
					END IF 
					
					IF (l_rec_vendor.tax_text IS NULL AND 
					p_rec_vendoraudit.tax_text IS NOT null) 
					OR (p_rec_vendoraudit.tax_text IS NULL AND 
					l_rec_vendor.tax_text IS NOT null) 
					OR (l_rec_vendor.tax_text != p_rec_vendoraudit.tax_text) THEN 
						PRINT COLUMN 04, "Tax Number:", 
						COLUMN 21, p_rec_vendoraudit.tax_text, 
						COLUMN 62, l_rec_vendor.tax_text 
					END IF 
					
					IF (l_rec_vendor.our_acct_code IS NULL AND 
					p_rec_vendoraudit.our_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.our_acct_code IS NULL AND 
					l_rec_vendor.our_acct_code IS NOT null) 
					OR (l_rec_vendor.our_acct_code != p_rec_vendoraudit.our_acct_code) THEN 
						PRINT COLUMN 04, "Our Account Code:", 
						COLUMN 21, p_rec_vendoraudit.our_acct_code, 
						COLUMN 62, l_rec_vendor.our_acct_code 
					END IF 
					
					IF (l_rec_vendor.usual_acct_code IS NULL AND 
					p_rec_vendoraudit.usual_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.usual_acct_code IS NULL AND 
					l_rec_vendor.usual_acct_code IS NOT null) 
					OR (l_rec_vendor.usual_acct_code != 
					p_rec_vendoraudit.usual_acct_code) THEN 
						PRINT COLUMN 04, "Purchases Acct:", 
						COLUMN 21, p_rec_vendoraudit.usual_acct_code, 
						COLUMN 62, l_rec_vendor.usual_acct_code 
					END IF 
					
					IF (l_rec_vendor.contact_text IS NULL AND 
					p_rec_vendoraudit.contact_text IS NOT null) 
					OR (p_rec_vendoraudit.contact_text IS NULL AND 
					l_rec_vendor.contact_text IS NOT null) 
					OR (l_rec_vendor.contact_text != p_rec_vendoraudit.contact_text) THEN 
						PRINT COLUMN 04, "Contact:", 
						COLUMN 21, p_rec_vendoraudit.contact_text, 
						COLUMN 62, l_rec_vendor.contact_text 
					END IF					
					 
					IF (l_rec_vendor.tele_text IS NULL AND 
					p_rec_vendoraudit.tele_text IS NOT null) 
					OR (p_rec_vendoraudit.tele_text IS NULL AND 
					l_rec_vendor.tele_text IS NOT null) 
					OR (l_rec_vendor.tele_text != p_rec_vendoraudit.tele_text) THEN 
						PRINT COLUMN 04, "Telephone:", 
						COLUMN 21, p_rec_vendoraudit.tele_text, 
						COLUMN 62, l_rec_vendor.tele_text 
					END IF 
					
					IF (l_rec_vendor.extension_text IS NULL AND 
					p_rec_vendoraudit.extension_text IS NOT null) 
					OR (p_rec_vendoraudit.extension_text IS NULL AND 
					l_rec_vendor.extension_text IS NOT null) 
					OR (l_rec_vendor.extension_text != p_rec_vendoraudit.extension_text) THEN 
						PRINT COLUMN 04, "Telephone Ext:", 
						COLUMN 21, p_rec_vendoraudit.extension_text, 
						COLUMN 62, l_rec_vendor.extension_text 
					END IF 
					
					IF (l_rec_vendor.fax_text IS NULL AND 
					p_rec_vendoraudit.fax_text IS NOT null) 
					OR (p_rec_vendoraudit.fax_text IS NULL AND 
					l_rec_vendor.fax_text IS NOT null) 
					OR (l_rec_vendor.fax_text != p_rec_vendoraudit.fax_text) THEN 
						PRINT COLUMN 04, "Fax Number:", 
						COLUMN 21, p_rec_vendoraudit.fax_text, 
						COLUMN 62, l_rec_vendor.fax_text 
					END IF 
					
					IF (l_rec_vendor.limit_amt IS NULL AND 
					p_rec_vendoraudit.limit_amt IS NOT null) 
					OR (p_rec_vendoraudit.limit_amt IS NULL AND 
					l_rec_vendor.limit_amt IS NOT null) 
					OR (l_rec_vendor.limit_amt != p_rec_vendoraudit.limit_amt) THEN 
						PRINT COLUMN 04, "Credit Limit:", 
						COLUMN 21, p_rec_vendoraudit.limit_amt 
						USING "<<<<<<<<<<<<<&.&&", 
						COLUMN 62, l_rec_vendor.limit_amt USING "<<<<<<<<<<<<<&.&&" 
					END IF 
					
					IF (l_rec_vendor.hold_code IS NULL AND 
					p_rec_vendoraudit.hold_code IS NOT null) 
					OR (p_rec_vendoraudit.hold_code IS NULL AND 
					l_rec_vendor.hold_code IS NOT null) 
					OR (l_rec_vendor.hold_code != p_rec_vendoraudit.hold_code) THEN 
						PRINT COLUMN 04, "Hold Code:", 
						COLUMN 21, p_rec_vendoraudit.hold_code, 
						COLUMN 62, l_rec_vendor.hold_code 
					END IF 
					
					
					IF (l_rec_vendor.drop_flag IS NULL AND 
					p_rec_vendoraudit.drop_flag IS NOT null) 
					OR (p_rec_vendoraudit.drop_flag IS NULL AND 
					l_rec_vendor.drop_flag IS NOT null) 
					OR (l_rec_vendor.drop_flag != p_rec_vendoraudit.drop_flag) THEN 
						PRINT COLUMN 04, "Subcontractor:", 
						COLUMN 21, p_rec_vendoraudit.drop_flag, 
						COLUMN 62, l_rec_vendor.drop_flag 
					END IF 
					
					IF (l_rec_vendor.finance_per IS NULL AND 
					p_rec_vendoraudit.finance_per IS NOT null) 
					OR (p_rec_vendoraudit.finance_per IS NULL AND 
					l_rec_vendor.finance_per IS NOT null) 
					OR (l_rec_vendor.finance_per != p_rec_vendoraudit.finance_per) THEN 
						PRINT COLUMN 04, "Fianance Charge:", 
						COLUMN 21, p_rec_vendoraudit.finance_per, 
						COLUMN 62, l_rec_vendor.finance_per 
					END IF 
					
					IF (l_rec_vendor.currency_code IS NULL AND 
					p_rec_vendoraudit.currency_code IS NOT null) 
					OR (p_rec_vendoraudit.currency_code IS NULL AND 
					l_rec_vendor.currency_code IS NOT null) 
					OR (l_rec_vendor.currency_code != p_rec_vendoraudit.currency_code) THEN 
						PRINT COLUMN 04, "Currency Code:", 
						COLUMN 21, p_rec_vendoraudit.currency_code, 
						COLUMN 62, l_rec_vendor.currency_code 
					END IF 
			
					IF (l_rec_vendor.bank_acct_code IS NULL AND 
					p_rec_vendoraudit.bank_acct_code IS NOT null) 
					OR (p_rec_vendoraudit.bank_acct_code IS NULL AND 
					l_rec_vendor.bank_acct_code IS NOT null) 
					OR (l_rec_vendor.bank_acct_code != p_rec_vendoraudit.bank_acct_code) THEN 
						PRINT COLUMN 04, "Bank Code:", 
						COLUMN 21, p_rec_vendoraudit.bank_acct_code, 
						COLUMN 62, l_rec_vendor.bank_acct_code 
					END IF 
					
					IF (l_rec_vendor.pay_meth_ind IS NULL AND 
					p_rec_vendoraudit.pay_meth_ind IS NOT null) 
					OR (p_rec_vendoraudit.pay_meth_ind IS NULL AND 
					l_rec_vendor.pay_meth_ind IS NOT null) 
					OR (l_rec_vendor.pay_meth_ind != p_rec_vendoraudit.pay_meth_ind) THEN 
						PRINT COLUMN 04, "Payment Method:", 
						COLUMN 21, p_rec_vendoraudit.pay_meth_ind, 
						COLUMN 62, l_rec_vendor.pay_meth_ind 
					END IF 
					
					IF (l_rec_vendor.vat_code IS NULL AND 
					p_rec_vendoraudit.vat_code IS NOT null) 
					OR (p_rec_vendoraudit.vat_code IS NULL AND 
					l_rec_vendor.vat_code IS NOT null) 
					OR (l_rec_vendor.vat_code != p_rec_vendoraudit.vat_code) THEN 
						PRINT COLUMN 04, "ABN:", 
						COLUMN 21, p_rec_vendoraudit.vat_code, 
						COLUMN 62, l_rec_vendor.vat_code 
					END IF 
					SKIP 1 line 
				END IF 
			END IF 
			
		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 15, "Total Vendor Alterations: ", 
			COLUMN 41, glob_upd_cnt USING "<<<<&" 
			SKIP 3 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
############################################################
# END REPORT PAA_rpt_list_upd(p_rpt_idx,p_rec_vendoraudit)
############################################################


############################################################
# REPORT PAA_rpt_list_del(p_rpt_idx,p_rec_vendoraudit)
#
#
############################################################
REPORT PAA_rpt_list_del(p_rpt_idx,p_rec_vendoraudit) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE l_cmpy_head CHAR(78) 
	DEFINE l_col2 SMALLINT 
	DEFINE l_col SMALLINT 

	OUTPUT 

	ORDER external BY p_rec_vendoraudit.vend_code,	p_rec_vendoraudit.audit_date
	 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, "Vendor", 
			COLUMN 10, "Name", 
			COLUMN 45, "User", 
			COLUMN 54, "Date", 
			COLUMN 65, "Time" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		ON EVERY ROW 
			PRINT COLUMN 01, p_rec_vendoraudit.vend_code, 
			COLUMN 10, p_rec_vendoraudit.name_text, 
			COLUMN 45, p_rec_vendoraudit.user_code, 
			COLUMN 54, p_rec_vendoraudit.audit_date 

		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 15, "Total Vendor Deletions: ", 
			COLUMN 39, glob_del_cnt USING "<<<<&" 
			SKIP 3 line 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			

END REPORT 
############################################################
# END REPORT PAA_rpt_list_del(p_rpt_idx,p_rec_vendoraudit)
############################################################


############################################################
# FUNCTION table1_mods(p_rec_s_vendoraudit,p_rec_vendoraudit)
#
#
############################################################
FUNCTION table1_mods(p_rec_s_vendoraudit,p_rec_vendoraudit) 
	DEFINE p_rec_s_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE p_rec_vendoraudit RECORD LIKE vendoraudit.* 

	IF (p_rec_s_vendoraudit.name_text IS NULL AND 
	p_rec_vendoraudit.name_text IS NOT null) 
	OR (p_rec_vendoraudit.name_text IS NULL AND 
	p_rec_s_vendoraudit.name_text IS NOT null) 
	OR (p_rec_s_vendoraudit.name_text != p_rec_vendoraudit.name_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.addr1_text IS NULL AND 
	p_rec_vendoraudit.addr1_text IS NOT null) 
	OR (p_rec_vendoraudit.addr1_text IS NULL AND 
	p_rec_s_vendoraudit.addr1_text IS NOT null) 
	OR (p_rec_s_vendoraudit.addr1_text != p_rec_vendoraudit.addr1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.addr2_text IS NULL AND 
	p_rec_vendoraudit.addr2_text IS NOT null) 
	OR (p_rec_vendoraudit.addr2_text IS NULL AND 
	p_rec_s_vendoraudit.addr2_text IS NOT null) 
	OR (p_rec_s_vendoraudit.addr2_text != p_rec_vendoraudit.addr2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.addr3_text IS NULL AND 
	p_rec_vendoraudit.addr3_text IS NOT null) 
	OR (p_rec_vendoraudit.addr3_text IS NULL AND 
	p_rec_s_vendoraudit.addr3_text IS NOT null) 
	OR (p_rec_s_vendoraudit.addr3_text != p_rec_vendoraudit.addr3_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.city_text IS NULL AND 
	p_rec_vendoraudit.city_text IS NOT null) 
	OR (p_rec_vendoraudit.city_text IS NULL AND 
	p_rec_s_vendoraudit.city_text IS NOT null) 
	OR (p_rec_s_vendoraudit.city_text != p_rec_vendoraudit.city_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.state_code IS NULL AND 
	p_rec_vendoraudit.state_code IS NOT null) 
	OR (p_rec_vendoraudit.state_code IS NULL AND 
	p_rec_s_vendoraudit.state_code IS NOT null) 
	OR (p_rec_s_vendoraudit.state_code != p_rec_vendoraudit.state_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.post_code IS NULL AND 
	p_rec_vendoraudit.post_code IS NOT null) 
	OR (p_rec_vendoraudit.post_code IS NULL AND 
	p_rec_s_vendoraudit.post_code IS NOT null) 
	OR (p_rec_s_vendoraudit.post_code != p_rec_vendoraudit.post_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.country_code IS NULL AND 
	p_rec_vendoraudit.country_code IS NOT null) 
	OR (p_rec_vendoraudit.country_code IS NULL AND 
	p_rec_s_vendoraudit.country_code IS NOT null) 
	OR (p_rec_s_vendoraudit.country_code != p_rec_vendoraudit.country_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.language_code IS NULL AND 
	p_rec_vendoraudit.language_code IS NOT null) 
	OR (p_rec_vendoraudit.language_code IS NULL AND 
	p_rec_s_vendoraudit.language_code IS NOT null) 
	OR (p_rec_s_vendoraudit.language_code != p_rec_vendoraudit.language_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.type_code IS NULL AND 
	p_rec_vendoraudit.type_code IS NOT null) 
	OR (p_rec_vendoraudit.type_code IS NULL AND 
	p_rec_s_vendoraudit.type_code IS NOT null) 
	OR (p_rec_s_vendoraudit.type_code != p_rec_vendoraudit.type_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.term_code IS NULL AND 
	p_rec_vendoraudit.term_code IS NOT null) 
	OR (p_rec_vendoraudit.term_code IS NULL AND 
	p_rec_s_vendoraudit.term_code IS NOT null) 
	OR (p_rec_s_vendoraudit.term_code != p_rec_vendoraudit.term_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.tax_code IS NULL AND 
	p_rec_vendoraudit.tax_code IS NOT null) 
	OR (p_rec_vendoraudit.tax_code IS NULL AND 
	p_rec_s_vendoraudit.tax_code IS NOT null) 
	OR (p_rec_s_vendoraudit.tax_code != p_rec_vendoraudit.tax_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.tax_text IS NULL AND 
	p_rec_vendoraudit.tax_text IS NOT null) 
	OR (p_rec_vendoraudit.tax_text IS NULL AND 
	p_rec_s_vendoraudit.tax_text IS NOT null) 
	OR (p_rec_s_vendoraudit.tax_text != p_rec_vendoraudit.tax_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.our_acct_code IS NULL AND 
	p_rec_vendoraudit.our_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.our_acct_code IS NULL AND 
	p_rec_s_vendoraudit.our_acct_code IS NOT null) 
	OR (p_rec_s_vendoraudit.our_acct_code != p_rec_vendoraudit.our_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.usual_acct_code IS NULL AND 
	p_rec_vendoraudit.usual_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.usual_acct_code IS NULL AND 
	p_rec_s_vendoraudit.usual_acct_code IS NOT null) 
	OR (p_rec_s_vendoraudit.usual_acct_code != 
	p_rec_vendoraudit.usual_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.contact_text IS NULL AND 
	p_rec_vendoraudit.contact_text IS NOT null) 
	OR (p_rec_vendoraudit.contact_text IS NULL AND 
	p_rec_s_vendoraudit.contact_text IS NOT null) 
	OR (p_rec_s_vendoraudit.contact_text != p_rec_vendoraudit.contact_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.tele_text IS NULL AND 
	p_rec_vendoraudit.tele_text IS NOT null) 
	OR (p_rec_vendoraudit.tele_text IS NULL AND 
	p_rec_s_vendoraudit.tele_text IS NOT null) 
	OR (p_rec_s_vendoraudit.tele_text != p_rec_vendoraudit.tele_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.extension_text IS NULL AND 
	p_rec_vendoraudit.extension_text IS NOT null) 
	OR (p_rec_vendoraudit.extension_text IS NULL AND 
	p_rec_s_vendoraudit.extension_text IS NOT null) 
	OR (p_rec_s_vendoraudit.extension_text != p_rec_vendoraudit.extension_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.fax_text IS NULL AND 
	p_rec_vendoraudit.fax_text IS NOT null) 
	OR (p_rec_vendoraudit.fax_text IS NULL AND 
	p_rec_s_vendoraudit.fax_text IS NOT null) 
	OR (p_rec_s_vendoraudit.fax_text != p_rec_vendoraudit.fax_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.limit_amt IS NULL AND 
	p_rec_vendoraudit.limit_amt IS NOT null) 
	OR (p_rec_vendoraudit.limit_amt IS NULL AND 
	p_rec_s_vendoraudit.limit_amt IS NOT null) 
	OR (p_rec_s_vendoraudit.limit_amt != p_rec_vendoraudit.limit_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.hold_code IS NULL AND 
	p_rec_vendoraudit.hold_code IS NOT null) 
	OR (p_rec_vendoraudit.hold_code IS NULL AND 
	p_rec_s_vendoraudit.hold_code IS NOT null) 
	OR (p_rec_s_vendoraudit.hold_code != p_rec_vendoraudit.hold_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.drop_flag IS NULL AND 
	p_rec_vendoraudit.drop_flag IS NOT null) 
	OR (p_rec_vendoraudit.drop_flag IS NULL AND 
	p_rec_s_vendoraudit.drop_flag IS NOT null) 
	OR (p_rec_s_vendoraudit.drop_flag != p_rec_vendoraudit.drop_flag) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.finance_per IS NULL AND 
	p_rec_vendoraudit.finance_per IS NOT null) 
	OR (p_rec_vendoraudit.finance_per IS NULL AND 
	p_rec_s_vendoraudit.finance_per IS NOT null) 
	OR (p_rec_s_vendoraudit.finance_per != p_rec_vendoraudit.finance_per) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.currency_code IS NULL AND 
	p_rec_vendoraudit.currency_code IS NOT null) 
	OR (p_rec_vendoraudit.currency_code IS NULL AND 
	p_rec_s_vendoraudit.currency_code IS NOT null) 
	OR (p_rec_s_vendoraudit.currency_code != p_rec_vendoraudit.currency_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.bank_acct_code IS NULL AND 
	p_rec_vendoraudit.bank_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.bank_acct_code IS NULL AND 
	p_rec_s_vendoraudit.bank_acct_code IS NOT null) 
	OR (p_rec_s_vendoraudit.bank_acct_code != p_rec_vendoraudit.bank_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.pay_meth_ind IS NULL AND 
	p_rec_vendoraudit.pay_meth_ind IS NOT null) 
	OR (p_rec_vendoraudit.pay_meth_ind IS NULL AND 
	p_rec_s_vendoraudit.pay_meth_ind IS NOT null) 
	OR (p_rec_s_vendoraudit.pay_meth_ind != p_rec_vendoraudit.pay_meth_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_s_vendoraudit.vat_code IS NULL AND 
	p_rec_vendoraudit.vat_code IS NOT null) 
	OR (p_rec_vendoraudit.vat_code IS NULL AND 
	p_rec_s_vendoraudit.vat_code IS NOT null) 
	OR (p_rec_s_vendoraudit.vat_code != p_rec_vendoraudit.vat_code) THEN 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 



############################################################
# FUNCTION table1_mods(p_rec_s_vendoraudit,p_rec_vendoraudit)
#
#
############################################################
FUNCTION table2_mods(p_rec_vendoraudit,p_rec_vendor) 
	DEFINE p_rec_vendoraudit RECORD LIKE vendoraudit.* 
	DEFINE p_rec_vendor RECORD LIKE vendor.* 

	IF (p_rec_vendor.name_text IS NULL AND 
	p_rec_vendoraudit.name_text IS NOT null) 
	OR (p_rec_vendoraudit.name_text IS NULL AND 
	p_rec_vendor.name_text IS NOT null) 
	OR (p_rec_vendor.name_text != p_rec_vendoraudit.name_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.addr1_text IS NULL AND 
	p_rec_vendoraudit.addr1_text IS NOT null) 
	OR (p_rec_vendoraudit.addr1_text IS NULL AND 
	p_rec_vendor.addr1_text IS NOT null) 
	OR (p_rec_vendor.addr1_text != p_rec_vendoraudit.addr1_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.addr2_text IS NULL AND 
	p_rec_vendoraudit.addr2_text IS NOT null) 
	OR (p_rec_vendoraudit.addr2_text IS NULL AND 
	p_rec_vendor.addr2_text IS NOT null) 
	OR (p_rec_vendor.addr2_text != p_rec_vendoraudit.addr2_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.addr3_text IS NULL AND 
	p_rec_vendoraudit.addr3_text IS NOT null) 
	OR (p_rec_vendoraudit.addr3_text IS NULL AND 
	p_rec_vendor.addr3_text IS NOT null) 
	OR (p_rec_vendor.addr3_text != p_rec_vendoraudit.addr3_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.city_text IS NULL AND 
	p_rec_vendoraudit.city_text IS NOT null) 
	OR (p_rec_vendoraudit.city_text IS NULL AND 
	p_rec_vendor.city_text IS NOT null) 
	OR (p_rec_vendor.city_text != p_rec_vendoraudit.city_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.state_code IS NULL AND 
	p_rec_vendoraudit.state_code IS NOT null) 
	OR (p_rec_vendoraudit.state_code IS NULL AND 
	p_rec_vendor.state_code IS NOT null) 
	OR (p_rec_vendor.state_code != p_rec_vendoraudit.state_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.post_code IS NULL AND 
	p_rec_vendoraudit.post_code IS NOT null) 
	OR (p_rec_vendoraudit.post_code IS NULL AND 
	p_rec_vendor.post_code IS NOT null) 
	OR (p_rec_vendor.post_code != p_rec_vendoraudit.post_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.country_code IS NULL AND 
	p_rec_vendoraudit.country_code IS NOT null) 
	OR (p_rec_vendoraudit.country_code IS NULL AND 
	p_rec_vendor.country_code IS NOT null) 
	OR (p_rec_vendor.country_code != p_rec_vendoraudit.country_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.language_code IS NULL AND 
	p_rec_vendoraudit.language_code IS NOT null) 
	OR (p_rec_vendoraudit.language_code IS NULL AND 
	p_rec_vendor.language_code IS NOT null) 
	OR (p_rec_vendor.language_code != p_rec_vendoraudit.language_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.type_code IS NULL AND 
	p_rec_vendoraudit.type_code IS NOT null) 
	OR (p_rec_vendoraudit.type_code IS NULL AND 
	p_rec_vendor.type_code IS NOT null) 
	OR (p_rec_vendor.type_code != p_rec_vendoraudit.type_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.term_code IS NULL AND 
	p_rec_vendoraudit.term_code IS NOT null) 
	OR (p_rec_vendoraudit.term_code IS NULL AND 
	p_rec_vendor.term_code IS NOT null) 
	OR (p_rec_vendor.term_code != p_rec_vendoraudit.term_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.tax_code IS NULL AND 
	p_rec_vendoraudit.tax_code IS NOT null) 
	OR (p_rec_vendoraudit.tax_code IS NULL AND 
	p_rec_vendor.tax_code IS NOT null) 
	OR (p_rec_vendor.tax_code != p_rec_vendoraudit.tax_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.tax_text IS NULL AND 
	p_rec_vendoraudit.tax_text IS NOT null) 
	OR (p_rec_vendoraudit.tax_text IS NULL AND 
	p_rec_vendor.tax_text IS NOT null) 
	OR (p_rec_vendor.tax_text != p_rec_vendoraudit.tax_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.our_acct_code IS NULL AND 
	p_rec_vendoraudit.our_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.our_acct_code IS NULL AND 
	p_rec_vendor.our_acct_code IS NOT null) 
	OR (p_rec_vendor.our_acct_code != p_rec_vendoraudit.our_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.usual_acct_code IS NULL AND 
	p_rec_vendoraudit.usual_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.usual_acct_code IS NULL AND 
	p_rec_vendor.usual_acct_code IS NOT null) 
	OR (p_rec_vendor.usual_acct_code != p_rec_vendoraudit.usual_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.contact_text IS NULL AND 
	p_rec_vendoraudit.contact_text IS NOT null) 
	OR (p_rec_vendoraudit.contact_text IS NULL AND 
	p_rec_vendor.contact_text IS NOT null) 
	OR (p_rec_vendor.contact_text != p_rec_vendoraudit.contact_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.tele_text IS NULL AND 
	p_rec_vendoraudit.tele_text IS NOT null) 
	OR (p_rec_vendoraudit.tele_text IS NULL AND 
	p_rec_vendor.tele_text IS NOT null) 
	OR (p_rec_vendor.tele_text != p_rec_vendoraudit.tele_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.extension_text IS NULL AND 
	p_rec_vendoraudit.extension_text IS NOT null) 
	OR (p_rec_vendoraudit.extension_text IS NULL AND 
	p_rec_vendor.extension_text IS NOT null) 
	OR (p_rec_vendor.extension_text != p_rec_vendoraudit.extension_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.fax_text IS NULL AND 
	p_rec_vendoraudit.fax_text IS NOT null) 
	OR (p_rec_vendoraudit.fax_text IS NULL AND 
	p_rec_vendor.fax_text IS NOT null) 
	OR (p_rec_vendor.fax_text != p_rec_vendoraudit.fax_text) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.limit_amt IS NULL AND 
	p_rec_vendoraudit.limit_amt IS NOT null) 
	OR (p_rec_vendoraudit.limit_amt IS NULL AND 
	p_rec_vendor.limit_amt IS NOT null) 
	OR (p_rec_vendor.limit_amt != p_rec_vendoraudit.limit_amt) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.hold_code IS NULL AND 
	p_rec_vendoraudit.hold_code IS NOT null) 
	OR (p_rec_vendoraudit.hold_code IS NULL AND 
	p_rec_vendor.hold_code IS NOT null) 
	OR (p_rec_vendor.hold_code != p_rec_vendoraudit.hold_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.drop_flag IS NULL AND 
	p_rec_vendoraudit.drop_flag IS NOT null) 
	OR (p_rec_vendoraudit.drop_flag IS NULL AND 
	p_rec_vendor.drop_flag IS NOT null) 
	OR (p_rec_vendor.drop_flag != p_rec_vendoraudit.drop_flag) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.finance_per IS NULL AND 
	p_rec_vendoraudit.finance_per IS NOT null) 
	OR (p_rec_vendoraudit.finance_per IS NULL AND 
	p_rec_vendor.finance_per IS NOT null) 
	OR (p_rec_vendor.finance_per != p_rec_vendoraudit.finance_per) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.currency_code IS NULL AND 
	p_rec_vendoraudit.currency_code IS NOT null) 
	OR (p_rec_vendoraudit.currency_code IS NULL AND 
	p_rec_vendor.currency_code IS NOT null) 
	OR (p_rec_vendor.currency_code != p_rec_vendoraudit.currency_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.bank_acct_code IS NULL AND 
	p_rec_vendoraudit.bank_acct_code IS NOT null) 
	OR (p_rec_vendoraudit.bank_acct_code IS NULL AND 
	p_rec_vendor.bank_acct_code IS NOT null) 
	OR (p_rec_vendor.bank_acct_code != p_rec_vendoraudit.bank_acct_code) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.pay_meth_ind IS NULL AND 
	p_rec_vendoraudit.pay_meth_ind IS NOT null) 
	OR (p_rec_vendoraudit.pay_meth_ind IS NULL AND 
	p_rec_vendor.pay_meth_ind IS NOT null) 
	OR (p_rec_vendor.pay_meth_ind != p_rec_vendoraudit.pay_meth_ind) THEN 
		RETURN true 
	END IF 
	IF (p_rec_vendor.vat_code IS NULL AND 
	p_rec_vendoraudit.vat_code IS NOT null) 
	OR (p_rec_vendoraudit.vat_code IS NULL AND 
	p_rec_vendor.vat_code IS NOT null) 
	OR (p_rec_vendor.vat_code != p_rec_vendoraudit.vat_code) THEN 
		RETURN true 
	END IF 

	RETURN false 
END FUNCTION 
############################################################
# END FUNCTION table1_mods(p_rec_s_vendoraudit,p_rec_vendoraudit)
############################################################