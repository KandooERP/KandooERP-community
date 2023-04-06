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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASL_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
####################################################################
# FUNCTION ASL_main()
#
# ASL - Invoice / Credit Import
#
# Really strange mixed handling with program arguments without any real code comments....
####################################################################
FUNCTION ASL_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler  
	
	CALL setModuleId("ASL") 
#	LET glob_rec_rpt_selector.ref2_text = trim(glob_rec_kandooreport.header_text), " - (Load No:", glob_rec_loadparms.seq_num USING "<<<<<",")"
#	LET glob_rec_kandooreport.header_text = trim(glob_rec_kandooreport.header_text), " - (Load No:", glob_rec_loadparms.seq_num USING "<<<<<",")"

#####################

	#CALL fgl_winmessage("In development???","This module is currently in development and not available for use","error") 
	#EXIT PROGRAM 

	CASE get_url_file_list_count() 
		WHEN 0 
			LET glob_verbose_indv = true 
			LET glob_update_ind = true 
		WHEN 1 
			#
			# fglgo ASL <test-only>
			#
			LET glob_verbose_indv = true 
			--         IF argX_val(1) = "T" THEN
			IF get_url_char() = "T" THEN #needs commenting in url arg handler same argument can be single CHAR OR company_code ???? what a xxxxx 

				LET glob_update_ind = false 
			ELSE 
				LET glob_update_ind = true 
			END IF 
		WHEN 2 
			#
			# fglgo ASL <glob_rec_kandoouser.cmpy_code-code> <load-ind>
			#
			LET glob_verbose_indv = false 
			LET glob_update_ind = true 
			LET glob_rec_kandoouser.cmpy_code = get_url_company_code() 
			LET glob_rec_loadparms.load_ind = get_url_load_ind() 
		WHEN 3 
			#
			# fglgo ASL <glob_rec_kandoouser.cmpy_code-code> <load-ind> <test-only>
			#
			LET glob_verbose_indv = false 
			LET glob_update_ind = false 
			LET glob_rec_kandoouser.cmpy_code = get_url_company_code() 
			LET glob_rec_loadparms.load_ind = get_url_load_ind() 
		OTHERWISE 
			LET glob_verbose_indv = true 
			LET glob_update_ind = true 
	END CASE 

	IF NOT glob_verbose_indv THEN 
		SELECT * INTO glob_rec_loadparms.* 
		FROM loadparms 
		WHERE load_ind = glob_rec_loadparms.load_ind 
		AND module_code = 'AR' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		CALL ASL_load_routine() 
	ELSE 
		DECLARE c_loadparms CURSOR FOR 
		SELECT * FROM loadparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND module_code = 'AR' 
		OPEN c_loadparms 
		FETCH c_loadparms INTO glob_rec_loadparms.* 

		OPEN WINDOW A629 with FORM "A629" 
		CALL windecoration_a("A629") 

		CALL display_parms() 

		MENU " Invoice Load" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","ASL","menu-invoice-load") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Load" #COMMAND "Load" " Commence load process"
				IF ASL_import_invoice() THEN 
					CALL ASL_load_routine() 
					NEXT option "Print Manager" 
				END IF
				CALL rpt_rmsreps_reset(NULL) 

			ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 

			ON ACTION "Directory" 	#COMMAND "Directory" " List entries in a specified directory"
				CALL show_directory() 

			ON ACTION "Exit" #COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
				LET quit_flag = true 
				EXIT MENU 
		END MENU 

		CLOSE WINDOW A629 
	END IF 

	EXIT PROGRAM(glob_err_cnt) 
END FUNCTION 



####################################################################
# FUNCTION ASL_import_invoice()
#
#
####################################################################
FUNCTION ASL_import_invoice() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_load_ind LIKE loadparms.load_ind 
	DEFINE l_lastkey INTEGER 


	INPUT BY NAME glob_rec_loadparms.load_ind, 
	glob_rec_loadparms.file_text, 
	glob_rec_loadparms.path_text, 
	glob_rec_loadparms.ref1_text, 
	glob_rec_loadparms.ref2_text, 
	glob_rec_loadparms.ref3_text WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASL","inp-loadparms") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD load_ind 
			IF glob_rec_loadparms.load_ind IS NULL THEN 
				ERROR kandoomsg2("A",9208,"") #9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT * INTO glob_rec_loadparms.* 
				FROM loadparms 
				WHERE load_ind = glob_rec_loadparms.load_ind 
				AND module_code = 'AR' 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					ERROR kandoomsg2("A",9206,"") #9206 Invalid Load indicator
					NEXT FIELD load_ind 
				ELSE 
					CALL display_parms() 
				END IF 
			END IF 

		AFTER FIELD file_text 
			IF glob_rec_loadparms.file_text IS NULL THEN 
				ERROR kandoomsg2("A",9166,"") #9166 File name must be entered
				NEXT FIELD file_text 
			END IF 

		AFTER FIELD path_text 
			IF glob_rec_loadparms.path_text IS NULL THEN 
				ERROR kandoomsg2("A",8015,"") 	#8015 Warning: Current directory will be defaulted
			END IF 
			LET l_lastkey = fgl_lastkey() 

		BEFORE FIELD ref1_text 
			IF glob_rec_loadparms.entry1_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF 

		AFTER FIELD ref1_text 
			IF glob_rec_loadparms.entry1_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref1_text IS NULL THEN 
					ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
					NEXT FIELD ref1_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 

		BEFORE FIELD ref2_text 
			IF glob_rec_loadparms.entry2_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF 

		AFTER FIELD ref2_text 
			IF glob_rec_loadparms.entry2_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref2_text IS NULL THEN 
					ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
					NEXT FIELD ref2_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 

		BEFORE FIELD ref3_text 
			IF glob_rec_loadparms.entry3_flag = 'N' THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD ref3_text 
			IF glob_rec_loadparms.entry3_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref3_text IS NULL THEN 
					ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
					NEXT FIELD ref3_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_loadparms.load_ind IS NULL THEN 
					ERROR kandoomsg2("A",9208,"") #9208 Load indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				IF glob_rec_loadparms.file_text IS NULL THEN 
					ERROR kandoomsg2("A",9166,"") 	#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF glob_rec_loadparms.entry1_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref1_text IS NULL THEN 
						ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
						NEXT FIELD ref1_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.entry2_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref2_text IS NULL THEN 
						ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
						NEXT FIELD ref2_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.entry3_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref3_text IS NULL THEN 
						ERROR kandoomsg2("A",9164,"") #9164 Invoice load reference must be entered
						NEXT FIELD ref3_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.path_text IS NULL 
				OR length(glob_rec_loadparms.path_text) = 0 THEN 
					LET glob_rec_loadparms.path_text = "." 
				END IF 
				LET glob_load_file = glob_rec_loadparms.path_text clipped, 
				"/",glob_rec_loadparms.file_text clipped 
				IF NOT file_valid(glob_load_file) THEN 
					LET l_msgresp=kandoomsg("U",9107,"") 
					NEXT FIELD file_text 
				END IF 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	END IF 

	ERROR kandoomsg2("U",8028,"") #8028 Begin Processing Load File records ? (Y/N)
	IF l_msgresp = "N" THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



####################################################################
# FUNCTION ASL_make_prompt( p_ref_text )
#
#
####################################################################
FUNCTION ASL_make_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE loadparms.ref1_text 
	DEFINE l_temp_text LIKE loadparms.ref1_text 

	IF p_ref_text IS NULL THEN 
		RETURN p_ref_text 
	ELSE 
		LET l_temp_text = p_ref_text clipped,"..............." 
		RETURN l_temp_text 
	END IF 
END FUNCTION 



####################################################################
# FUNCTION ASL_load_routine()
#
#
####################################################################
FUNCTION ASL_load_routine() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE l_load_num LIKE loadparms.load_num 
	DEFINE l_load_ind LIKE loadparms.load_ind 
	DEFINE l_msgresp LIKE language.yes_flag 
--	DEFINE l_output STRING #report output file inc. path
	##
	## Retreive the next load number (concurrency issues ignored)
	##
	SELECT (seq_num+1) INTO glob_rec_loadparms.seq_num 
	FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = 'AR' 
	AND load_ind = glob_rec_loadparms.load_ind 
	WHENEVER ERROR CONTINUE 
	UPDATE loadparms SET seq_num = glob_rec_loadparms.seq_num 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND load_ind = glob_rec_loadparms.load_ind 
	AND module_code = 'AR' 
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	##
	## Begin load
	##

	#------------------------------------------------------------
	LET glob_err_cnt = 0 
	#------------------------------------------------------------	


	LET glob_rec_rpt_selector.ref3_text = " - (Load No:", glob_rec_loadparms.seq_num USING "<<<<<",")"

	#------------------------------------------------------------
	# Report for exceptions
	LET l_rpt_idx = rpt_start("ASL-ERROR","ASL_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ASL_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception")].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	#------------------------------------------------------------

	LET glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception")].ref2_text = trim(glob_arr_rec_rpt_kandooreport[rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception")].header_text), " ", 
	trim(glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception")].ref3_text)

--	START REPORT ASL_rpt_list_exception TO glob_rec_rmsreps.file_text 

	#------------------------------------------------------------
	
	IF glob_rec_loadparms.path_text IS NULL 
	OR length(glob_rec_loadparms.path_text) = 0 THEN 
		LET glob_rec_loadparms.path_text = "." 
	END IF 
	LET glob_load_file = glob_rec_loadparms.path_text clipped, 
	"/",glob_rec_loadparms.file_text clipped 

	CASE glob_rec_loadparms.format_ind 
		WHEN '1' 
			#        LET l_load_num = gunns_load()
		WHEN '2' 
			CALL ASL_rpt_start_2_saw()
			LET l_load_num = ASL_sawtrack_load() 
			CALL ASL_rpt_finish_2_saw() 
		WHEN '3' 
			CALL ASL_rpt_start_3_voyg() 
			LET l_load_num = ASL_load_t_voyager() #voyager_load() 
			CALL rpt_aslc_finish_3_voyg() 
		WHEN '4' 
			CALL ASL_rpt_start_4_prof()
			LET l_load_num = ASL_profit_load() 
			CALL ASL_rpt_finish_4_prof() 
		WHEN '5' 
			CALL ASL_rpt_start_5_kao() 
			LET l_load_num = kao_load() 
			CALL ASL_rpt_finish_5_kao() 
		OTHERWISE 
			LET glob_err_cnt = glob_err_cnt + 1 
			LET glob_err_message ="Invoice Load routine does NOT exist FOR ", 
			"Format Ind.:",glob_rec_loadparms.format_ind clipped," ", 
			"glob_rec_kandoouser.cmpy_code:",glob_rec_kandoouser.cmpy_code," ", 
			"Load:",glob_rec_loadparms.load_ind 

			#---------------------------------------------------------
			OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
			'', '', '', glob_err_message )  
			#--------------------------------------------------------- 
					
			IF glob_verbose_indv THEN 
				ERROR kandoomsg2("A",9167,'') #9167 Invoice load routine does NOT exist FOR FORMAT ind.
			END IF 
			RETURN 
	END CASE 

	##
	##
	IF l_load_num < 0 THEN 
		LET glob_err_cnt = glob_err_cnt + 1 
		LET glob_err_message = 
		"Refer ", trim(get_settings_logFile()), " FOR SQL Error: ",l_load_num USING "<<<<<<<<", 
		" in Load File:",glob_load_file clipped 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', glob_err_message )  
		#--------------------------------------------------------- 		
 
		LET glob_err_text = "ASL - ",err_get(l_load_num) 
		CALL errorlog(glob_err_text) 
		LET l_load_num = 0 
	END IF 
	##
	## Update loadparms
	##
	WHENEVER ERROR CONTINUE 
	UPDATE loadparms 
	SET load_date = today, 
	load_num = l_load_num 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND load_ind = glob_rec_loadparms.load_ind 
	AND module_code = 'AR' 
	AND seq_num = glob_rec_loadparms.seq_num 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	IF glob_err_cnt THEN 
		IF glob_verbose_indv THEN 
			CALL display_parms() 
			ERROR kandoomsg2("A",7055,glob_err_cnt) 
			#7055 Inv. Load Completed, Errors Encountered
		END IF 
	ELSE 
		IF glob_verbose_indv THEN 
			CALL display_parms() 
			ERROR kandoomsg2("A",7056,'') 
			#7056 Invoice Load Completed Successfully
		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT ASL_rpt_list_exception(rpt_rmsreps_idx_get_idx("ASL_rpt_list_exception"),
		'', '', '', 'invoice LOAD completed successfully' )  
		#--------------------------------------------------------- 		

	END IF 

	#------------------------------------------------------------
	# ERROR/Exception Report
	FINISH REPORT ASL_rpt_list_exception
	CALL rpt_finish("ASL_rpt_list_exception")
	#------------------------------------------------------------	
		  	 
END FUNCTION 


{
####################################################################
# FUNCTION set1_defaults()
#
#
####################################################################
FUNCTION set1_defaults() 

	LET glob_rec_kandooreport.header_text = 
	"External Invoice Load Exceptions - (Load No:", 
	glob_rec_loadparms.seq_num USING "<<<<<",")" 
	CALL rpt_set_width(132) 
	CALL rpt_set_length(66) 
	LET glob_rec_kandooreport.menupath_text = "ASL" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Company", 3 spaces, 
	"Customer", 3 spaces, 
	"Ext.Ref", 3 spaces, 
	"Status" 
	UPDATE kandooreport 
	SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 

}

####################################################################
# FUNCTION display_parms()
#
#
####################################################################
FUNCTION display_parms() 
	DEFINE l_recr_prmpt1_text LIKE loadparms.prmpt1_text 
	DEFINE l_recr_prmpt2_text LIKE loadparms.prmpt2_text 
	DEFINE l_recr_prmpt3_text LIKE loadparms.prmpt3_text 

	LET l_recr_prmpt1_text = ASL_make_prompt( glob_rec_loadparms.prmpt1_text ) 
	LET l_recr_prmpt2_text = ASL_make_prompt( glob_rec_loadparms.prmpt2_text ) 
	LET l_recr_prmpt3_text = ASL_make_prompt( glob_rec_loadparms.prmpt3_text ) 
	
	DISPLAY l_recr_prmpt1_text TO loadparms.prmpt1_text attribute(white) 
	DISPLAY l_recr_prmpt2_text TO loadparms.prmpt2_text attribute(white) 
	DISPLAY l_recr_prmpt3_text TO loadparms.prmpt3_text attribute(white) 
	
	DISPLAY BY NAME glob_rec_loadparms.load_ind, 
	glob_rec_loadparms.desc_text, 
	glob_rec_loadparms.seq_num, 
	glob_rec_loadparms.load_date, 
	glob_rec_loadparms.load_num, 
	glob_rec_loadparms.seq_num, 
	glob_rec_loadparms.load_date, 
	glob_rec_loadparms.load_num, 
	glob_rec_loadparms.file_text, 
	glob_rec_loadparms.path_text, 
	glob_rec_loadparms.ref1_text, 
	glob_rec_loadparms.ref2_text, 
	glob_rec_loadparms.ref3_text 

END FUNCTION

####################################################################
# REPORT ASL_rpt_list_exception(p_rpt_idx,p_cmpy_code, p_cust_code, p_inv_num, p_status)
#
#
####################################################################
REPORT ASL_rpt_list_exception(p_rpt_idx,p_cmpy_code, p_cust_code, p_inv_num, p_status) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_inv_num CHAR(8) 
	DEFINE p_status CHAR(132) 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	OUTPUT 
--	left margin 0 
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
			SKIP 3 LINES 
		ON EVERY ROW 
			PRINT COLUMN 01, p_cmpy_code, 
			COLUMN 11, p_cust_code, 
			COLUMN 22, p_inv_num, 
			COLUMN 33, p_status[1,132-33] 
		ON LAST ROW 
			NEED 3 LINES 
			SKIP 2 LINES 
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
