{
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:50	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl"


############################################################
# Module Scope Variables
############################################################
DEFINE modu_output CHAR(50) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_kandoo_ap_cnt INTEGER 
DEFINE modu_kandoo_vo_cnt INTEGER 
DEFINE modu_kandoo_cq_cnt INTEGER 
DEFINE modu_load_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_loadfile_ind SMALLINT 
DEFINE modu_cleared_ind SMALLINT 
DEFINE modu_unload_ind SMALLINT 
DEFINE modu_verbose_ind SMALLINT 
DEFINE modu_total_vouch_amt LIKE voucher.total_amt 
DEFINE modu_total_cheq_amt LIKE voucher.total_amt 
DEFINE modu_load_ap_cnt INTEGER 
DEFINE modu_load_cq_cnt INTEGER 
DEFINE modu_load_vo_cnt INTEGER 
DEFINE modu_tot_ap_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_ap_per DECIMAL(6,3) 
DEFINE modu_path_text LIKE loadparms.file_text 
DEFINE modu_load_ind LIKE loadparms.load_ind 

############################################################
# MAIN
#
#   PSW - External AP Voucher Load
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PSW") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	#huho 14.03.2019    This was done twice
	#   SELECT * INTO pr_rec_kandoouser.* FROM kandoouser
	#    WHERE cmpy_code    = glob_rec_kandoouser.cmpy_code
	#      AND sign_on_code = glob_rec_kandoouser.sign_on_code
	#now done it CALL init_p_ap() #init P/AP module
	#   SELECT * INTO pr_apparms.* FROM apparms
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   IF STATUS = NOTFOUND THEN
	#      LET l_msgresp=kandoomsg("P",5016,"")
	#      EXIT PROGRAM
	#   END IF
	LET modu_cleared_ind = false 
	### Create temp tables reqd. FOR calls TO update_database ###
	CALL create_table("voucherdist","t_voucherdist","","N") 
	IF get_url_file_path() IS NOT NULL THEN  -- num_args() > 0 THEN 
		### run  PSW <glob_rec_kandoouser.cmpy_code> <load-file> ###
		LET modu_verbose_ind = false 
		LET modu_loadfile_ind = true 
		IF start_load(false) THEN 
			CALL move_load_file() 
		END IF 
		EXIT PROGRAM( modu_err_cnt + modu_err2_cnt ) 
	ELSE 
		LET modu_verbose_ind = true 

		OPEN WINDOW p228 with FORM "P228" 
		CALL windecoration_p("P228") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		MENU " AP Load" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","PSW","menu-ap_load-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "actToolbarManager" 
				# COMMAND "Load" " Commence Voucher/Cheque load process"
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = true 
				IF start_load(false) THEN 
					CALL move_load_file() 
				END IF 
				NEXT option "Print Manager" 

			ON ACTION "Rerun" 
				#COMMAND "Rerun" " Commence Voucher/Cheque load FROM interim table"
				LET modu_unload_ind = false 
				LET modu_loadfile_ind = false 
				IF start_load(true) THEN END IF 
					NEXT option "Print Manager" 

			ON ACTION "Unload" 
				#COMMAND "Unload" " Unload contents of interim table"
				LET modu_loadfile_ind = false 
				LET modu_unload_ind = true 
				IF f_unload(1) THEN END IF 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			ON ACTION "CANCEL" 
				#COMMAND KEY(interrupt,"E")"Exit" " Exit AP Load" 
				LET int_flag = true 
				LET quit_flag = true 
				EXIT MENU 



		END MENU 

		CLOSE WINDOW p228 
	END IF 
END MAIN 
#
#
#


############################################################
# FUNCTION import_vouchcheq(p_mode)
#
# Import the Voucher/Cheque File
############################################################
FUNCTION import_vouchcheq(p_mode) 
	DEFINE p_mode SMALLINT
	DEFINE l_rec_s_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_r_loadparms RECORD LIKE loadparms.* 
	DEFINE l_lastkey INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	### Collect AND DISPLAY the default load details ###
	SELECT * INTO l_rec_r_loadparms.* 
	FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = 'AP' 
	AND load_ind = "WHI" 
	CALL display_parms(l_rec_r_loadparms.*) 
	IF p_mode THEN 
		LET l_msgresp = kandoomsg("U",1020,"Load File") 
		#U1020 Enter Load Details; OK TO Continue
	ELSE 
		LET l_msgresp = kandoomsg("U",1020,"Unload File") 
		#U1020 Enter Unload Details; OK TO Continue
	END IF 

	INPUT BY NAME l_rec_r_loadparms.load_ind, 
	l_rec_r_loadparms.file_text, 
	l_rec_r_loadparms.path_text, 
	l_rec_r_loadparms.ref1_text, 
	l_rec_r_loadparms.ref2_text, 
	l_rec_r_loadparms.ref3_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PSW","inp-loadparms-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD load_ind 
			IF l_rec_r_loadparms.load_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9122,"") 
				#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT * INTO l_rec_s_loadparms.* 
				FROM loadparms 
				WHERE load_ind = l_rec_r_loadparms.load_ind 
				AND module_code = 'AP' 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9123,"") 
					#U9116 Invalid Load indicator
					NEXT FIELD load_ind 
				ELSE 
					CALL display_parms(l_rec_r_loadparms.*) 
				END IF 
			END IF 
		AFTER FIELD file_text 
			IF l_rec_r_loadparms.file_text IS NULL THEN 
				LET l_rec_r_loadparms.file_text = l_rec_s_loadparms.file_text 
				LET l_msgresp = kandoomsg("U",9115,"") 
				#9166 File name must be entered
				NEXT FIELD file_text 
			END IF 

		AFTER FIELD path_text 
			IF l_rec_r_loadparms.path_text IS NULL THEN 
				LET l_rec_r_loadparms.path_text = l_rec_s_loadparms.path_text 
				LET l_msgresp = kandoomsg("U",9117,"") 
				#8015 Warning: Current directory will be defaulted
			END IF 
			LET l_lastkey = fgl_lastkey() 

		BEFORE FIELD ref1_text 
			IF l_rec_r_loadparms.entry1_flag = 'N' THEN 
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
			IF l_rec_r_loadparms.entry1_flag = 'Y' THEN 
				IF l_rec_r_loadparms.ref1_text IS NULL THEN 
					LET l_rec_r_loadparms.ref1_text = l_rec_s_loadparms.ref1_text 
					LET l_msgresp = kandoomsg("A",9164,"") 
					#9164 Invoice load reference must be entered
					NEXT FIELD ref1_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 

		BEFORE FIELD ref2_text 
			IF l_rec_r_loadparms.entry2_flag = 'N' THEN 
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
			IF l_rec_r_loadparms.entry2_flag = 'Y' THEN 
				IF l_rec_r_loadparms.ref2_text IS NULL THEN 
					LET l_rec_r_loadparms.ref2_text = l_rec_s_loadparms.ref2_text 
					LET l_msgresp = kandoomsg("A",9164,"") 
					#9164 Invoice load reference must be entered
					NEXT FIELD ref2_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 
		BEFORE FIELD ref3_text 
			IF l_rec_r_loadparms.entry3_flag = 'N' THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD ref3_text 
			IF l_rec_r_loadparms.entry3_flag = 'Y' THEN 
				IF l_rec_r_loadparms.ref3_text IS NULL THEN 
					LET l_rec_r_loadparms.ref3_text = l_rec_s_loadparms.ref3_text 
					LET l_msgresp = kandoomsg("A",9164,"") 
					#9164 Invoice load reference must be entered
					NEXT FIELD ref3_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_r_loadparms.load_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9208,"") 
					#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				IF l_rec_r_loadparms.file_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9166,"") 
					#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF l_rec_r_loadparms.entry1_flag = 'Y' THEN 
					IF l_rec_r_loadparms.ref1_text IS NULL THEN 
						LET l_rec_r_loadparms.ref1_text = l_rec_s_loadparms.ref1_text 
						LET l_msgresp = kandoomsg("A",9164,"") 
						#9164 Invoice load reference must be entered
						NEXT FIELD ref1_text 
					END IF 
				END IF 
				IF l_rec_r_loadparms.entry2_flag = 'Y' THEN 
					IF l_rec_r_loadparms.ref2_text IS NULL THEN 
						LET l_rec_r_loadparms.ref2_text = l_rec_s_loadparms.ref2_text 
						LET l_msgresp = kandoomsg("A",9164,"") 
						#9164 Invoice load reference must be entered
						NEXT FIELD ref2_text 
					END IF 
				END IF 
				IF l_rec_r_loadparms.entry3_flag = 'Y' THEN 
					IF l_rec_r_loadparms.ref3_text IS NULL THEN 
						LET l_rec_r_loadparms.ref3_text = l_rec_s_loadparms.ref3_text 
						LET l_msgresp = kandoomsg("A",9164,"") 
						#9164 Invoice load reference must be entered
						NEXT FIELD ref3_text 
					END IF 
				END IF 
				IF l_rec_r_loadparms.path_text IS NULL 
				OR length(l_rec_r_loadparms.path_text) = 0 THEN 
					LET l_rec_r_loadparms.path_text = "." 
				END IF 
				IF modu_loadfile_ind OR modu_unload_ind THEN 
					IF l_rec_r_loadparms.file_text IS NULL THEN 
						LET l_rec_r_loadparms.file_text = l_rec_s_loadparms.file_text 
						LET l_msgresp = kandoomsg("A",9166,"") 
						#9166 File name must be entered
						NEXT FIELD file_text 
					END IF 
				END IF 
				IF l_rec_r_loadparms.path_text IS NULL OR 
				length(l_rec_r_loadparms.path_text) = 0 THEN 
					LET l_rec_r_loadparms.path_text = "." 
				END IF 
				CALL valid_load(l_rec_r_loadparms.path_text,l_rec_r_loadparms.file_text) 
				RETURNING modu_load_file 
				IF modu_load_file IS NULL THEN 
					NEXT FIELD file_text 
				END IF 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET modu_load_ind = l_rec_r_loadparms.load_ind 
		LET modu_path_text = l_rec_r_loadparms.path_text 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION display_parms(p_rec_loadparms)
#
# DISPLAY the Load Parameter Values
############################################################
FUNCTION display_parms(p_rec_loadparms) 
	DEFINE p_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_prmpt1_text LIKE loadparms.prmpt1_text 
	DEFINE l_prmpt2_text LIKE loadparms.prmpt1_text 
	DEFINE l_prmpt3_text LIKE loadparms.prmpt1_text 

	LET l_prmpt1_text = make_prompt(p_rec_loadparms.prmpt1_text) 
	LET l_prmpt2_text = make_prompt(p_rec_loadparms.prmpt2_text) 
	LET l_prmpt3_text = make_prompt(p_rec_loadparms.prmpt3_text) 
	DISPLAY l_prmpt1_text, 
	l_prmpt2_text, 
	l_prmpt3_text 
	TO loadparms.prmpt1_text, 
	loadparms.prmpt2_text, 
	loadparms.prmpt3_text 
	attribute(white) 
	DISPLAY BY NAME p_rec_loadparms.load_ind, 
	p_rec_loadparms.desc_text, 
	p_rec_loadparms.seq_num, 
	p_rec_loadparms.load_date, 
	p_rec_loadparms.load_num, 
	p_rec_loadparms.seq_num, 
	p_rec_loadparms.load_date, 
	p_rec_loadparms.load_num, 
	p_rec_loadparms.file_text, 
	p_rec_loadparms.path_text, 
	p_rec_loadparms.ref1_text, 
	p_rec_loadparms.ref2_text, 
	p_rec_loadparms.ref3_text 

END FUNCTION 


############################################################
# FUNCTION make_prompt(p_ref_text)
#
# Make the Load Parameter - ask user
############################################################
FUNCTION make_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE loadparms.ref1_text 
	DEFINE r_temp_text LIKE loadparms.ref1_text 

	IF p_ref_text IS NOT NULL THEN 
		RETURN p_ref_text 
	ELSE 
		LET r_temp_text = p_ref_text clipped,"..............." 
		RETURN r_temp_text 
	END IF 
END FUNCTION 

############################################################
# FUNCTION valid_load(p_path_name, p_file_name)
#
# Valid Load File
############################################################
##################################
# Test's performed :             #
#        1. File NOT found       #
#        2. No read permission   #
#        3. File IS Empty        #
#        4. OTHERWISE            #
##################################
FUNCTION valid_load(p_path_name,p_file_name) 
	DEFINE p_path_name CHAR(100)
	DEFINE p_file_name CHAR(100) 
	DEFINE l_runner CHAR(100) 
	DEFINE l_load_file CHAR(100) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_load_file = p_path_name clipped, 
	"/",p_file_name clipped 
	LET l_runner = " [ -f ",l_load_file clipped," ] 2>>", trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_ret_code 
	IF l_ret_code THEN 
		IF modu_unload_ind THEN 
			### IF file does NOT exist FOR Unload THEN check directory ###
			IF p_path_name = "." THEN 
				RETURN l_load_file 
			ELSE 
				LET l_runner = " [ -d ",p_path_name clipped," ] 2>>", trim(get_settings_logFile()) 
				RUN l_runner RETURNING l_ret_code 
				IF l_ret_code THEN 
					IF modu_verbose_ind THEN 
						LET l_msgresp = kandoomsg("U",9107,'') 
						#9107 Unload directory does NOT exist - check path
					END IF 
					RETURN "" 
				ELSE 
					RETURN l_load_file 
				END IF 
			END IF 
		END IF 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9160,'') 
			#9160 Load file does NOT exist - check path AND filename
		END IF 
		RETURN "" 
	ELSE 
		IF modu_unload_ind THEN 
			### IF file exists THEN don't overwrite
			LET l_msgresp = kandoomsg("P",9178,"") 
			#P9178 Unload file already exists in nominated directory.
			RETURN "" 
		END IF 
	END IF 
	LET l_runner = " [ -r ",l_load_file clipped," ] 2>>", trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_ret_code 
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		RETURN "" 
	END IF 
	LET l_runner = " [ -s ",l_load_file clipped," ] 2>>", trim(get_settings_logFile()) 
	RUN l_runner RETURNING l_ret_code 
	IF l_ret_code THEN 
		IF modu_verbose_ind THEN 
			LET l_msgresp = kandoomsg("A",9161,'') 
			#9161 Load file IS empty
		END IF 
		RETURN "" 
	ELSE 
		RETURN l_load_file 
	END IF 
END FUNCTION 


############################################################
# FUNCTION verify_acct( p_cmpy, p_account_code, p_year_num, p_period_num )
#
# - FUNCTION verify_acct() IS a clone of vacctfunc.4gl
# - changes reqd. b/c need TO remove user interaction
# - returns STATUS ( ie. error OR acct_code )
############################################################
FUNCTION verify_acct(p_cmpy,p_account_code,p_year_num,p_period_num ) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code 
	DEFINE p_year_num LIKE coa.start_year_num 
	DEFINE p_period_num LIKE coa.start_period_num 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_err_message CHAR(50) 

	SELECT * INTO l_rec_coa.* 
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 
	IF status = NOTFOUND THEN 
		LET l_err_message = "Account: ",p_account_code clipped," NOT SET up ", 
		"FOR ", p_year_num USING "####", 
		"/", p_period_num USING "###" 
		RETURN ( l_err_message clipped ) 
	ELSE 
		CASE 
			WHEN ( l_rec_coa.start_year_num > p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num < p_year_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.start_year_num = p_year_num AND 
				l_rec_coa.start_period_num > p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," NOT OPEN ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			WHEN ( l_rec_coa.end_year_num = p_year_num AND 
				l_rec_coa.end_period_num < p_period_num ) 
				LET l_err_message = "Account: ",p_account_code clipped," closed ", 
				"FOR ", p_year_num USING "####", 
				"/", p_period_num USING "###" 
				RETURN ( l_err_message clipped ) 
			OTHERWISE 
				RETURN l_rec_coa.acct_code 
		END CASE 
	END IF 
END FUNCTION 

############################################################
# FUNCTION start_ex_rep()
#
# Start Exception Report
############################################################
FUNCTION start_ex_rep() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PSW-1","PSW_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSW_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	RETURN l_rpt_idx  
END FUNCTION 

############################################################
# FUNCTION finish_ex_rep()
#
# Finish the Exception Report
############################################################
FUNCTION finish_ex_rep() 
	#------------------------------------------------------------
	FINISH REPORT PSW_rpt_list_exception
	CALL rpt_finish("PSW_rpt_list_exception")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

############################################################
# REPORT PSW_rpt_list_exception(p_cmpy_code,
#                      p_anal_text,
#                      p_ref_text,
#                      p_ref_num,
#                      p_status)
#
############################################################
REPORT PSW_rpt_list_exception(p_rpt_idx,p_cmpy_code,p_anal_text,p_ref_text,p_ref_num,p_status)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_anal_text LIKE asg_vouchcheq.analysis_text 
	DEFINE p_ref_text LIKE asg_vouchcheq.ref_text 
	DEFINE p_ref_num LIKE asg_vouchcheq.ref_num 
	DEFINE p_status CHAR(110) 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132)

	OUTPUT 
	left margin 0 
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
			COLUMN 06, p_anal_text, 
			COLUMN 20, p_ref_text clipped, 
			COLUMN 25, p_ref_num USING "############", 
			COLUMN 40, p_status clipped 
		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total records TO be processed : ", 
			modu_loadfile_cnt 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records with validation errors : ",modu_err_cnt 
			PRINT COLUMN 10, "Total records with SQL/File errors : ",modu_err2_cnt 
			PRINT COLUMN 10, "Total records successfully processed : ", 
			modu_load_cnt 
			PRINT COLUMN 10, "( total no. OF Vouchers:", 
			COLUMN 39, modu_kandoo_vo_cnt USING "###########&", " )" 
			PRINT COLUMN 10, "( total no. OF cheques :", 
			COLUMN 39, modu_kandoo_cq_cnt USING "###########&", " )" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_err_cnt + modu_err2_cnt + modu_load_cnt ) USING "###########&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total voucher amounts :", 
			COLUMN 55, modu_total_vouch_amt USING "--------&.&&" 
			PRINT COLUMN 10, "Total cheque amounts :", 
			COLUMN 55, modu_total_cheq_amt USING "--------&.&&" 
			PRINT COLUMN 55, "-------------" 
			PRINT COLUMN 55, ( modu_total_vouch_amt + modu_total_cheq_amt) 
			USING "--------&.&&" 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 





############################################################
# FUNCTION load_routine()
#
# Load Routine
############################################################
FUNCTION load_routine() 
	DEFINE l_error_text CHAR(50) 
	DEFINE l_seq_num LIKE loadparms.seq_num 
	DEFINE l_today DATE 

	LET modu_rerun_cnt = 0 
	LET l_error_text = NULL 
	LET modu_loadfile_cnt = 0 
	### Delete any info FROM temporary tables ###
	DELETE FROM t_voucherdist WHERE 1=1 
	IF chk_tables() THEN 
		IF modu_loadfile_ind THEN 
			IF NOT perform_load() THEN 
				LET l_error_text = "Transaction Load Problems" 
				RETURN l_error_text 
			END IF 
		END IF 
		IF setup_counts() THEN 
			CALL null_tests() 
			CALL chk_balance() 
			IF (modu_load_ind IS NOT null) THEN 
				### Initial Update of Load Parameter Table ###
				SELECT (seq_num+1) INTO l_seq_num FROM loadparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = 'AP' 
				AND load_ind = modu_load_ind 
				WHENEVER ERROR CONTINUE 
				LET l_today = today 
				UPDATE loadparms 
				SET seq_num = l_seq_num, 
				load_date = l_today 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = 'AP' 
				AND load_ind = modu_load_ind 
				WHENEVER ERROR stop 
				DISPLAY l_seq_num,l_today TO loadparms.seq_num,loadparms.load_date 

			END IF 
			### Create the appropriate documents ###
			CALL create_ap_entry() 
			LET modu_load_cnt = modu_kandoo_ap_cnt 
			IF (modu_load_ind IS NOT null) THEN 
				### Final Update of Load Parameter Table ###
				WHENEVER ERROR CONTINUE 
				LET l_today = today 
				UPDATE loadparms 
				SET load_date = l_today, 
				load_num = modu_load_cnt ### successful records ### 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND load_ind = modu_load_ind 
				AND module_code = 'AP' 
				AND seq_num = l_seq_num 
				WHENEVER ERROR stop 
				DISPLAY modu_load_cnt,l_today TO 
				loadparms.load_num,loadparms.load_date 

			END IF 
			IF modu_kandoo_ap_cnt > 0 THEN 
				IF NOT ( modu_err_cnt + modu_err2_cnt ) THEN 
				
					OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
					 '', '', '', 
					'', 'ap LOAD completed successfully' ) 
				END IF 
			ELSE 
				### Dummy line in REPORT TO force DISPLAY of Control Totals
				OUTPUT TO REPORT PSW_rpt_list(rpt_rmsreps_idx_get_idx("PSW_rpt_list"),
				 '', '', '', '', '', '', '','') 
			END IF 
		END IF 
	ELSE 
		LET l_error_text = "ASG SQL Tables do NOT exist." 
	END IF 
	RETURN l_error_text 
END FUNCTION 


############################################################
# FUNCTION perform_load()
#
# Perform the Loading Routine
############################################################
FUNCTION perform_load() 
	DEFINE l_runner CHAR(200) 
	DEFINE l_rowid INTEGER 
	DEFINE l_status INTEGER
	DEFINE l_cheq_code9 CHAR(9) 
	DEFINE l_asg_vouchcheq RECORD LIKE asg_vouchcheq.* 
	DEFINE l_err_message CHAR(110)
	DEFINE l_err_text CHAR(250)

	IF NOT modu_verbose_ind THEN 
		LET glob_rec_kandoouser.cmpy_code = get_url_company_code()  #arg_val(1) 
		CALL valid_load(get_url_file_path(),get_url_file_name())   #(arg_val(2), arg_val(3)) ### 2=path 3=file ### 
		RETURNING modu_load_file 
	END IF 
	IF modu_load_file IS NOT NULL THEN 
		### Commence LOAD ###
		LET modu_load_file = modu_load_file clipped 
		WHENEVER ERROR CONTINUE 
		LOAD FROM modu_load_file INSERT INTO asg_vouchcheq 
		WHENEVER ERROR stop 
		IF sqlca.sqlcode != 0 THEN 
			LET l_status = sqlca.sqlcode 
			### Dummy line in REPORT TO force DISPLAY of Control Totals ###
			OUTPUT TO REPORT PSW_rpt_list(rpt_rmsreps_idx_get_idx("PSW_rpt_list"),
				  '', '', '', '', '', '', '','') 
			### count total no. of vouchers/cheques TO be generated ###
			CALL count_records() 
			RETURNING modu_process_cnt 
			LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
			### REPORT error ###
			LET modu_err2_cnt = modu_err2_cnt + 1 
			LET l_err_message = "Refer to ", trim(get_settings_logFile()), " FOR SQL Error: ", l_status, " ", 
			"in Load File:",modu_load_file clipped 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 '', '', '', '', l_err_message ) 
			LET l_err_text = "PSW - ",err_get(l_status) 
			CALL errorlog( l_err_text ) 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 '', '', '', '', l_err_text ) 
			### FOR reporting purposes SET no. records processed ###
			LET modu_load_cnt = 0 
			RETURN false 
		ELSE 
			IF NOT modu_cleared_ind THEN 
				DECLARE c_asg_vouchcheq CURSOR FOR 
				SELECT rowid, ref_num FROM asg_vouchcheq 
				FOREACH c_asg_vouchcheq INTO l_rowid,l_cheq_code9 
					LET l_asg_vouchcheq.ref_num = l_cheq_code9[2,9] 
					UPDATE asg_vouchcheq 
					SET ref_num = l_asg_vouchcheq.ref_num 
					WHERE rowid = l_rowid 
				END FOREACH 
			END IF 
			LET modu_cleared_ind = false 
			RETURN true 
		END IF 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 


############################################################
# FUNCTION count_records()
#
# Count how many asg_vouchcheq records TO process
############################################################
FUNCTION count_records() 
	DEFINE r_cnt INTEGER 

	SELECT count(*) INTO r_cnt 
	FROM asg_vouchcheq 
	IF r_cnt IS NULL THEN 
		LET r_cnt = 0 
	END IF 
	RETURN r_cnt 
END FUNCTION 


############################################################
# FUNCTION null_tests()
#
# Perform NULL tests AND REPORT errors
############################################################
FUNCTION null_tests() 
	DEFINE l_rec_asgvouchcheq RECORD LIKE asg_vouchcheq.* 
	DEFINE l_err_message CHAR(110)

	### Null Test's on data fields ###
	DECLARE c_asgnullcheck CURSOR FOR 
	SELECT * FROM asg_vouchcheq 
	WHERE cmpy_code IS NULL 
	OR tran_type_ind IS NULL 
	OR analysis_text IS NULL 
	OR tran_date IS NULL 
	OR ref_text IS NULL 
	OR ref_num IS NULL 
	OR acct_code IS NULL 
	OR (for_debit_amt IS NULL AND for_credit_amt IS null) 
	OR cmpy_code = ' ' 
	OR tran_type_ind = ' ' 
	OR analysis_text = ' ' 
	OR ref_text = ' ' 
	OR acct_code = ' ' 
	FOREACH c_asgnullcheck INTO l_rec_asgvouchcheq.* 
		IF l_rec_asgvouchcheq.cmpy_code IS NULL 
		OR l_rec_asgvouchcheq.cmpy_code = ' ' THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Company Code detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF l_rec_asgvouchcheq.tran_date IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Transaction Date Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF l_rec_asgvouchcheq.ref_text IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null WHICS-Open Cheque Type Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF l_rec_asgvouchcheq.ref_num IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Cheque Number Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF (l_rec_asgvouchcheq.acct_code IS null) OR 
		(l_rec_asgvouchcheq.acct_code = ' ') 
		THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Account Code Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF (l_rec_asgvouchcheq.analysis_text IS null) OR 
		(l_rec_asgvouchcheq.analysis_text = ' ') 
		THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Payee Customer Text Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF l_rec_asgvouchcheq.for_debit_amt IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Debit Amount Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
		IF l_rec_asgvouchcheq.for_credit_amt IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 1 
			LET l_err_message = "Null Credit Amount Detected" 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgvouchcheq.cmpy_code, 
			l_rec_asgvouchcheq.analysis_text, 
			l_rec_asgvouchcheq.ref_text, 
			l_rec_asgvouchcheq.ref_num, 
			l_err_message ) 
			CALL show_perc_comp(1) 
			CONTINUE FOREACH 
		END IF 
	END FOREACH 
END FUNCTION 


############################################################
# FUNCTION setup_counts()
#
# Set Up the Load File Count Value
############################################################
FUNCTION setup_counts() 
	DEFINE l_err_message CHAR(110)

	### count total no. of vouchers/cheques TO be generated ###
	CALL count_records() 
	RETURNING modu_process_cnt 
	LET modu_load_cnt = 0 
	LET modu_load_ap_cnt = 0 
	LET modu_load_vo_cnt = 0 
	LET modu_load_cq_cnt = 0 
	LET modu_kandoo_ap_cnt = 0 
	LET modu_kandoo_vo_cnt = 0 
	LET modu_kandoo_cq_cnt = 0 
	LET modu_tot_ap_cnt = modu_process_cnt 
	LET modu_loadfile_cnt = modu_process_cnt - modu_rerun_cnt 
	LET modu_ap_per = 0 
	IF NOT modu_tot_ap_cnt THEN 
		LET l_err_message = "No AP Vouchers/Cheques TO be generated." 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		 '', '', '', '', l_err_message) 
		RETURN false 
	END IF 
	IF modu_verbose_ind THEN 
		DISPLAY modu_load_cq_cnt,modu_load_vo_cnt,modu_kandoo_cq_cnt,modu_kandoo_vo_cnt,modu_tot_ap_cnt,modu_ap_per
		TO load_cq_cnt,load_vo_cnt,max_cq_cnt,max_vo_cnt,tot_ap_cnt,ap_per
	END IF 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION create_ap_entry()
#
# Create AP Entry FOR Voucher AND Cheque
############################################################
FUNCTION create_ap_entry() 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_cheq_code LIKE asg_vouchcheq.ref_num 
	DEFINE l_cmpy_code LIKE asg_vouchcheq.cmpy_code 
	DEFINE l_cust_code LIKE asg_vouchcheq.analysis_text 
	DEFINE l_tran_date LIKE asg_vouchcheq.tran_date 
	DEFINE l_status SMALLINT 
	DEFINE l_count_trans SMALLINT 
	DEFINE l_addcheq SMALLINT 
	DEFINE l_delcheq SMALLINT 
	DEFINE l_trans_type CHAR(2) 
	DEFINE l_err_message CHAR(110)

	#####################################################
	# Process WHICS-Open AP transactions
	#####################################################
	DECLARE c1_asgcheques CURSOR with HOLD FOR 
	SELECT unique ref_num, analysis_text, cmpy_code, count(*), tran_date 
	FROM asg_vouchcheq 
	WHERE cmpy_code IS NOT NULL 
	AND tran_type_ind = "CH" 
	AND analysis_text IS NOT NULL 
	AND tran_date IS NOT NULL 
	AND ref_text IS NOT NULL 
	AND ref_num IS NOT NULL 
	AND acct_code IS NOT NULL 
	AND ((for_debit_amt IS NOT NULL AND for_credit_amt IS null) OR 
	(for_debit_amt IS NULL AND for_credit_amt IS NOT null)) 
	GROUP BY 1,2,3,5 
	ORDER BY 1,2,3 

	FOREACH c1_asgcheques INTO l_cheq_code, 
		l_cust_code, 
		l_cmpy_code, 
		l_count_trans, 
		l_tran_date 
		IF int_flag OR quit_flag THEN 
			IF modu_verbose_ind THEN 
				#8004 Do you wish TO quit (Y/N) ?
				IF kandoomsg("A",8004,"") = 'Y' THEN 
					EXIT FOREACH 
				END IF 
			ELSE 
				EXIT FOREACH 
			END IF 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		### IF there IS NOT an even number counted THEN this transaction ###
		### IS NOT complete                                              ###
		IF (l_count_trans mod 2) > 0 THEN 
			LET modu_err_cnt = modu_err_cnt + l_count_trans 
			LET l_err_message = "Cheque Number:", l_cheq_code, 
			" FROM WHICS-Open Cmpy:", l_cmpy_code, 
			" has an odd number of transactions." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_cmpy_code, 
			l_cust_code, 
			" ", 
			l_cheq_code, 
			l_err_message) 
			LET l_err_message = "Each Cheque Transaction MUST have 2 records.", 
			" A Credit transaction FOR the cheque AND Debit", 
			" transaction FOR the Voucher." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", 
			"", 
			"", 
			"", 
			l_err_message) 
			CALL show_counts(l_count_trans,"LV","") 
			CALL show_counts(l_count_trans,"LC","") 
			CALL show_perc_comp(l_count_trans) 
			CONTINUE FOREACH 
		END IF 
		### Determine the type of transactions TO process FOR this cheque ###
		LET l_addcheq = false 
		LET l_delcheq = false 
		DECLARE c_transtype CURSOR FOR 
		SELECT unique(ref_text) 
		FROM asg_vouchcheq 
		WHERE ref_num = l_cheq_code 
		AND cmpy_code = l_cmpy_code 
		AND analysis_text = l_cust_code 
		FOREACH c_transtype INTO l_trans_type 
			CASE l_trans_type 
				WHEN "B0" 
					LET l_addcheq = true 
				WHEN "B1" 
					LET l_addcheq = true 
				WHEN "BC" 
					LET l_delcheq = true 
			END CASE 
		END FOREACH 
		########################################################
		### Now determine the type of transaction TO process ###
		### IF DELETE THEN IF ADD THEN warn ELSE warn        ###
		### IF ADD only THEN add the Voucher AND Cheque      ###
		########################################################
		### IF DELETE THEN IF ADD THEN warn1 ELSE warn2      ###
		IF (l_delcheq) THEN 
			LET modu_err_cnt = modu_err_cnt + l_count_trans 
			IF (l_addcheq) THEN 
				LET l_err_message = "Cheque Number:", l_cheq_code, 
				" in WHICS-Open Cmpy:", l_cmpy_code, 
				" was NOT added. Has both ADD AND CANCEL", 
				" transactions." 
				OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
				l_cmpy_code, 
				'', 
				'', 
				l_cheq_code, 
				l_err_message) 
				LET l_err_message = " Review the ADD (B0 OR B1) AND CANCEL ", 
				"(BC) transactions FOR further details." 
				OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
				"", "", "", "", l_err_message) 
			ELSE 
				LET l_err_message = "Cancelation of Cheque Number:", l_cheq_code, 
				" FOR WHICS-Open Cmpy:", l_cmpy_code, 
				" NOT processed." 
				OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
				l_cmpy_code, 
				l_cust_code, 
				'BC', 
				l_cheq_code, 
				l_err_message) 
				LET l_err_message = "Manually Cancel WHICS-Open Cheque/Voucher", 
				" transactions." 
				OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
				"", "", "", "", l_err_message) 
			END IF 
			CALL show_counts((l_count_trans/2),"LV","") 
			CALL show_counts((l_count_trans/2),"LC","") 
			### IF ADD          THEN add the Voucher AND Cheque  ###
		ELSE 
			BEGIN WORK 
				CALL process_cheque_voucher(l_cmpy_code, 
				l_cheq_code, 
				l_cust_code) 
				RETURNING l_status, 
				l_rec_cheque.*, 
				l_rec_voucher.* 
				IF l_status THEN 
				COMMIT WORK 
				CALL show_counts(2,"AP","") 
				CALL show_counts(1,"MC",l_rec_cheque.cheq_code) 
				CALL show_counts(1,"MV",l_rec_voucher.vouch_code) 
				OUTPUT TO REPORT PSW_rpt_list(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
				l_rec_cheque.cmpy_code, 
				l_rec_cheque.vend_code , 
				l_rec_voucher.vouch_code, 
				l_rec_cheque.cheq_code, 
				l_rec_voucher.line_num, 
				l_rec_voucher.total_amt, 
				l_rec_cheque.pay_amt, 
				l_tran_date) 
				### Remove the appropriate rows FROM asg_vouchcheq ###
				DELETE FROM asg_vouchcheq 
				WHERE ref_num = l_cheq_code 
				AND analysis_text = l_cust_code 
				AND cmpy_code = l_cmpy_code 
			ELSE 
				ROLLBACK WORK 
			END IF 
		END IF 
		CALL show_perc_comp(l_count_trans) 
	END FOREACH 
END FUNCTION 


############################################################
# FUNCTION process_cheque_voucher(p_cmpy_code,p_cheq_code,p_cust_code)
#
# Process Cheque AND Voucher routine
############################################################
FUNCTION process_cheque_voucher(p_cmpy_code,p_cheq_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE asg_vouchcheq.cmpy_code 
	DEFINE p_cheq_code LIKE asg_vouchcheq.ref_num 
	DEFINE p_cust_code LIKE asg_vouchcheq.analysis_text 
	DEFINE l_rec_s_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_r_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_asgcheque RECORD LIKE asg_vouchcheq.* 
	DEFINE l_return CHAR(40) 
	DEFINE l_error_num CHAR(40) 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_year_num LIKE cheque.year_num 
	DEFINE l_period_num LIKE cheque.period_num 
	DEFINE l_err_message CHAR(110)

	### Increment the process cheque counter here ###
	CALL show_counts(1,"LC",p_cheq_code) 
	### INITIALIZE some VALUES here ###
	INITIALIZE l_rec_r_cheque.* TO NULL 
	INITIALIZE l_rec_vendor.* TO NULL 
	INITIALIZE l_rec_voucher.* TO NULL 
	WHENEVER ERROR CONTINUE 
	SELECT * INTO l_rec_asgcheque.* FROM asg_vouchcheq 
	WHERE cmpy_code IS NOT NULL 
	AND tran_type_ind = "CH" 
	AND cmpy_code = p_cmpy_code 
	AND analysis_text = p_cust_code 
	AND tran_date IS NOT NULL 
	AND ref_text in ("B0","B1") 
	AND ref_num = p_cheq_code 
	AND acct_code IS NOT NULL 
	AND (for_debit_amt IS NULL AND for_credit_amt IS NOT null) 
	IF status <> 0 THEN 
		WHENEVER ERROR stop 
		LET modu_err_cnt = modu_err_cnt + 2 
		LET l_err_message = "Failed TO retrieve details of WHICS-Open Cheque:", 
		p_cheq_code, 
		". A Review of the WHICS-Open Transactions IS needed." 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		p_cmpy_code, 
		'', 
		'', 
		p_cheq_code, 
		l_err_message) 
		CALL show_counts(1,"LV","") 
		RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
	ELSE 
		WHENEVER ERROR stop 
		LET l_rec_r_cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_r_cheque.cheq_date = l_rec_asgcheque.tran_date 
		CALL get_fiscal_year_period_for_date(l_rec_r_cheque.cmpy_code,l_rec_asgcheque.tran_date) 
		RETURNING l_year_num, 
		l_period_num 
		IF l_year_num IS NULL 
		OR l_period_num IS NULL THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "Transaction Date ", l_rec_asgcheque.tran_date, 
			" IS NOT in a valid year/period", 
			" under Cmpy: ", glob_rec_kandoouser.cmpy_code, "." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message ) 
			LET l_err_message = "Review WHICS-Open transaction date AND/OR ", 
			"Year/Period setup." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		END IF 
		### Validate the Account Code ie: Should be in the GL AND Bank Account ##
		IF NOT acct_type(glob_rec_kandoouser.cmpy_code, l_rec_asgcheque.acct_code, COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK,"N") 
		THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "Account Code ", l_rec_asgcheque.acct_code, 
			" IS NOT a Bank Account Code in", 
			" Cmpy: ", glob_rec_kandoouser.cmpy_code, "." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message ) 
			LET l_err_message = "Review WHICS-Open translated Account Code." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		END IF 
		SELECT * INTO l_rec_bank.* FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = l_rec_asgcheque.acct_code 
		IF status = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "The bank FOR account code ", 
			l_rec_asgcheque.acct_code, 
			" IS NOT setup under Cmpy: ", glob_rec_kandoouser.cmpy_code 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message ) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		END IF 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_bank.bank_code 
		IF status = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "The Vendor Code ", l_rec_bank.bank_code, 
			" has NOT been setup", 
			" under Cmpy: ", glob_rec_kandoouser.cmpy_code 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message) 
			LET l_err_message = "Ensure the Vendor ", l_rec_bank.bank_code clipped, 
			" exists before processing WHICS-Open AP", 
			" Transactions." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		END IF 
		### Verify the cheque amount being processed ###
		IF (l_rec_asgcheque.for_credit_amt <= 0) THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "The WHICS-Open transaction cheque amount <=0", 
			" FOR cheque #", l_rec_asgcheque.ref_num clipped, "." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			 l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message) 
			LET l_err_message = "Review the WHICS-Open transaction details." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		END IF 
		##################################################
		###          Setup the cheque details          ###
		##################################################
		CALL cheque_initialize(glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		l_rec_vendor.vend_code, 
		l_rec_bank.bank_code, 
		l_rec_asgcheque.for_credit_amt) 
		RETURNING l_return, l_rec_s_cheque.*, l_error_text 
		IF NOT l_return THEN 
			LET modu_err2_cnt = modu_err2_cnt + 2 
			LET l_err_message = "Error Preparing Cheque:", l_rec_asgcheque.ref_num, 
			" (", l_error_text[1,30] clipped, ")." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_rec_asgcheque.cmpy_code, 
			l_rec_asgcheque.analysis_text, 
			l_rec_asgcheque.ref_text, 
			l_rec_asgcheque.ref_num, 
			l_err_message) 
			LET l_err_message = "Note the error AND contact System Administrator." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			CALL show_counts(1,"LV","") 
			RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
		ELSE 
			### Prepare remaining variables FOR cheque RECORD ###
			LET l_rec_r_cheque.* = l_rec_s_cheque.* 
			LET l_rec_r_cheque.cheq_date = l_rec_asgcheque.tran_date 
			LET l_rec_r_cheque.cheq_code = p_cheq_code ### cheque number ### 
			LET l_rec_r_cheque.com1_text = "WHICS-Open AP Cheque Load" 
			LET l_rec_r_cheque.com2_text = "Payee:",l_rec_asgcheque.analysis_text clipped 
			LET l_rec_r_cheque.year_num = l_year_num 
			LET l_rec_r_cheque.period_num = l_period_num 
			##################################################
			###    Process AND Add the Voucher Details     ###
			##################################################
			CALL process_voucher(p_cmpy_code, 
			p_cheq_code, 
			p_cust_code, 
			l_rec_r_cheque.*) 
			RETURNING l_return, l_rec_voucher.* 
			IF l_return THEN 
				##################################################
				###         Verify the Cheque Details          ###
				##################################################
				CALL cheque_verify(l_rec_r_cheque.*) 
				RETURNING l_return, l_rec_s_cheque.*, l_error_text 
				IF NOT l_return THEN 
					LET modu_err2_cnt = modu_err2_cnt + 2 
					LET l_err_message = "Error Verifying Cheque Details:", 
					l_rec_s_cheque.cheq_code, 
					" (", l_error_text[1,30] clipped, ")" 
					OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
					l_rec_asgcheque.cmpy_code, 
					l_rec_asgcheque.analysis_text, 
					l_rec_asgcheque.ref_text, 
					l_rec_asgcheque.ref_num, 
					l_err_message) 
					RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
				ELSE 
					##################################################
					###          Add the Cheque Details            ###
					##################################################
					CALL cheque_add(l_rec_s_cheque.*,false) 
					RETURNING l_return, l_error_text 
					IF l_return THEN 
						SELECT * INTO l_rec_r_cheque.* FROM cheque 
						WHERE cmpy_code = l_rec_s_cheque.cmpy_code 
						AND cheq_code = l_rec_s_cheque.cheq_code 
						AND bank_code = l_rec_s_cheque.bank_code 
						AND pay_meth_ind = l_rec_s_cheque.pay_meth_ind 
						AND vend_code = l_rec_s_cheque.vend_code 
						##################################################
						###      Apply Cheque TO Voucher Details       ###
						##################################################
						CALL auto_cheq_appl(l_rec_voucher.cmpy_code, 
						l_rec_r_cheque.cheq_code, 
						l_rec_voucher.vouch_code, 
						l_rec_r_cheque.bank_acct_code, 
						l_rec_r_cheque.pay_meth_ind) 
						RETURNING l_return, l_error_num 
						IF NOT l_return THEN 
							LET l_err_message = "Error Applying Cheque ", 
							l_rec_r_cheque.cheq_code, 
							" TO Voucher" 
							OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
							l_rec_asgcheque.cmpy_code, 
							l_rec_asgcheque.analysis_text, 
							l_rec_asgcheque.ref_text, 
							l_rec_asgcheque.ref_num, 
							l_err_message) 
							RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
						ELSE 
							RETURN true, l_rec_r_cheque.*, l_rec_voucher.* 
						END IF 
					ELSE 
						LET modu_err2_cnt = modu_err2_cnt + 2 
						LET l_err_message = "Error Creating Cheque:", 
						l_rec_s_cheque.cheq_code, 
						" (", l_error_text[1,30] clipped, ")" 
						OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
						l_rec_asgcheque.cmpy_code, 
						l_rec_asgcheque.analysis_text, 
						l_rec_asgcheque.ref_text, 
						l_rec_asgcheque.ref_num, 
						l_err_message) 
						RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
					END IF 
				END IF 
			ELSE 
				### Error MESSAGE performed in process_voucher FUNCTION
				RETURN false, l_rec_r_cheque.*, l_rec_voucher.* 
			END IF 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION process_voucher(p_cmpy_code,
#                         p_cheq_code,
#                         p_cust_code,
#                         p_cheque)
#
# Process AP Vouchers
############################################################
FUNCTION process_voucher(p_cmpy_code,p_cheq_code,p_cust_code,p_cheque) 
	DEFINE p_cmpy_code LIKE asg_vouchcheq.cmpy_code 
	DEFINE p_cheq_code LIKE asg_vouchcheq.ref_num 
	DEFINE p_cust_code LIKE asg_vouchcheq.analysis_text 
	DEFINE p_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_asgvoucher RECORD LIKE asg_vouchcheq.* 
	DEFINE l_acct_text CHAR(110) 
	DEFINE l_vouch_code LIKE voucher.vouch_code 
	DEFINE l_err_message CHAR(110)

	### Increment the load voucher counter here ###
	CALL show_counts(1,"LV","") 
	SELECT * INTO l_rec_asgvoucher.* 
	FROM asg_vouchcheq 
	WHERE cmpy_code = p_cmpy_code 
	AND tran_type_ind = "CH" 
	AND analysis_text = p_cust_code 
	AND tran_date IS NOT NULL 
	AND ref_text in ("B0","B1") 
	AND ref_num = p_cheq_code 
	AND acct_code IS NOT NULL 
	AND (for_debit_amt IS NOT NULL AND for_credit_amt IS null) 
	IF status <> 0 THEN 
		LET modu_err_cnt = modu_err_cnt + 2 
		LET l_err_message = "Voucher details could NOT be selected.", 
		" Attempt TO process again via Rerun option" 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		l_rec_asgvoucher.cmpy_code, 
		l_rec_asgvoucher.analysis_text, 
		l_rec_asgvoucher.ref_text, 
		l_rec_asgvoucher.ref_num, 
		l_err_message) 
		LET l_err_message = "OR manually create a Voucher AND Cheque FROM", 
		" WHICS-Open transaction details." 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		"", "", "", "", l_err_message) 
		RETURN false, l_rec_voucher.* 
	ELSE 
		INITIALIZE l_rec_voucher.* TO NULL 
		INITIALIZE l_rec_vendor.* TO NULL 
		INITIALIZE l_rec_voucherdist.* TO NULL 
		### Collect the vendor details ###
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE cmpy_code = p_cheque.cmpy_code 
		AND vend_code = p_cheque.vend_code 
		IF status = NOTFOUND THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "Vendor: ", p_cheque.vend_code clipped, 
			" NOT setup FOR Cmpy:", p_cheque.cmpy_code 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_rec_asgvoucher.cmpy_code, 
			l_rec_asgvoucher.analysis_text, 
			l_rec_asgvoucher.ref_text, 
			l_rec_asgvoucher.ref_num, 
			l_err_message) 
			LET l_err_message = "Verify setup of Vendor." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			RETURN false, l_rec_voucher.* 
		END IF 
		IF (l_rec_asgvoucher.for_debit_amt != p_cheque.pay_amt) THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = "Cheque amount: ", p_cheque.pay_amt clipped, 
			" NOT EQUAL Voucher amount:", 
			l_rec_asgvoucher.for_debit_amt, 
			". Voucher AND Cheque NOT created." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_rec_asgvoucher.cmpy_code, 
			l_rec_asgvoucher.analysis_text, 
			l_rec_asgvoucher.ref_text, 
			l_rec_asgvoucher.ref_num, 
			l_err_message) 
			LET l_err_message = "Review WHICS-Open transaction details." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			"", "", "", "", l_err_message) 
			RETURN false, l_rec_voucher.* 
		END IF 
		### PREPARE voucher RECORD ready TO add ###
		LET l_rec_voucher.cmpy_code = p_cheque.cmpy_code 
		LET l_rec_voucher.vend_code = l_rec_vendor.vend_code 
		LET l_rec_voucher.inv_text = NULL 
		LET l_rec_voucher.po_num = NULL 
		LET l_rec_voucher.vouch_date = l_rec_asgvoucher.tran_date 
		LET l_rec_voucher.entry_code = p_cheque.entry_code 
		LET l_rec_voucher.entry_date = p_cheque.entry_date 
		LET l_rec_voucher.sales_text = l_rec_vendor.contact_text 
		LET l_rec_voucher.term_code = l_rec_vendor.term_code 
		LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
		LET l_rec_voucher.goods_amt = l_rec_asgvoucher.for_debit_amt 
		LET l_rec_voucher.tax_amt = 0 
		LET l_rec_voucher.total_amt = l_rec_asgvoucher.for_debit_amt 
		LET l_rec_voucher.paid_amt = 0 
		LET l_rec_voucher.dist_qty = NULL 
		LET l_rec_voucher.dist_amt = 0 
		LET l_rec_voucher.poss_disc_amt = 0 
		LET l_rec_voucher.taken_disc_amt = 0 
		LET l_rec_voucher.paid_date = NULL 
		LET l_rec_voucher.due_date = today 
		LET l_rec_voucher.disc_date = today 
		LET l_rec_voucher.hist_flag = 'N' 
		LET l_rec_voucher.jour_num = 0 
		LET l_rec_voucher.post_flag = 'N' 
		LET l_rec_voucher.year_num = p_cheque.year_num 
		LET l_rec_voucher.period_num = p_cheque.period_num 
		LET l_rec_voucher.pay_seq_num = 0 
		LET l_rec_voucher.line_num = 0 
		LET l_rec_voucher.com1_text = "WHICS-Open AP Voucher Upload" 
		LET l_rec_voucher.com2_text = "Payee: ", l_rec_asgvoucher.analysis_text 
		LET l_rec_voucher.hold_code = 'NO' 
		LET l_rec_voucher.jm_post_flag = NULL 
		IF glob_rec_apparms.vouch_approve_flag = "Y" THEN 
			LET l_rec_voucher.approved_code = "N" 
		ELSE 
			LET l_rec_voucher.approved_code = "Y" 
		END IF 
		LET l_rec_voucher.approved_by_code = NULL 
		LET l_rec_voucher.approved_date = NULL 
		LET l_rec_voucher.split_from_num = 0 
		LET l_rec_voucher.currency_code = p_cheque.currency_code 
		LET l_rec_voucher.conv_qty = p_cheque.conv_qty 
		LET l_rec_voucher.post_date = NULL 
		LET l_rec_voucher.source_ind = p_cheque.source_ind 
		LET l_rec_voucher.source_text = p_cheque.source_text 
		LET l_rec_voucher.withhold_tax_ind = p_cheque.withhold_tax_ind 
		INITIALIZE l_rec_voucherdist.* TO NULL 
		LET l_rec_voucher.line_num = l_rec_voucher.line_num + 1 
		LET l_rec_voucherdist.cmpy_code = l_rec_voucher.cmpy_code 
		LET l_rec_voucherdist.vend_code = l_rec_voucher.vend_code 
		LET l_rec_voucherdist.vouch_code = l_rec_voucher.vouch_code 
		LET l_rec_voucherdist.line_num = l_rec_voucher.line_num 
		LET l_rec_voucherdist.type_ind = 'G' 
		### Verify the account code FOR voucher distribution acct - exp account###
		LET l_rec_voucherdist.acct_code = l_rec_asgvoucher.acct_code 
		CALL verify_acct(l_rec_voucher.cmpy_code, 
		l_rec_voucherdist.acct_code, 
		l_rec_voucher.year_num, 
		l_rec_voucher.period_num) 
		RETURNING l_acct_text 
		IF l_acct_text != l_rec_voucherdist.acct_code THEN 
			LET modu_err_cnt = modu_err_cnt + 2 
			LET l_err_message = l_acct_text clipped, 
			". Voucher AND Cheque NOT created." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_rec_asgvoucher.cmpy_code, 
			l_rec_asgvoucher.analysis_text, 
			l_rec_asgvoucher.ref_text, 
			l_rec_asgvoucher.ref_num, 
			l_err_message) 
			RETURN false, l_rec_voucher.* 
		END IF 
		LET l_rec_voucherdist.desc_text = 'whics-open ap voucher LOAD ', 
		l_rec_asgvoucher.ref_num 
		LET l_rec_voucherdist.dist_qty = NULL 
		LET l_rec_voucherdist.dist_amt = l_rec_asgvoucher.for_debit_amt 
		LET l_rec_voucherdist.analysis_text = NULL 
		LET l_rec_voucherdist.res_code = NULL 
		LET l_rec_voucherdist.job_code = NULL 
		LET l_rec_voucherdist.var_code = NULL 
		LET l_rec_voucherdist.act_code = NULL 
		LET l_rec_voucherdist.po_num = NULL 
		LET l_rec_voucherdist.po_line_num = NULL 
		LET l_rec_voucherdist.trans_qty = NULL 
		LET l_rec_voucherdist.cost_amt = NULL 
		LET l_rec_voucherdist.charge_amt = NULL 
		INSERT INTO t_voucherdist VALUES ( l_rec_voucherdist.* ) 
		LET l_vouch_code = update_database(l_rec_voucher.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		'1', 
		l_rec_voucher.*) 
		IF l_vouch_code > 0 THEN 
			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE vouch_code = l_vouch_code 
			AND cmpy_code = l_rec_voucher.cmpy_code 
		ELSE 
			LET modu_err2_cnt = modu_err2_cnt + 2 
			LET l_err_message = "Error inserting Voucher in database", 
			" FOR WHICS-Open Payee:", 
			l_rec_asgvoucher.analysis_text, 
			" under WHICS-Open Cmpy:", l_rec_asgvoucher.cmpy_code, 
			". Voucher AND Cheque NOT Created." 
			OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
			l_rec_asgvoucher.cmpy_code, 
			l_rec_asgvoucher.analysis_text, 
			l_rec_asgvoucher.ref_text, 
			l_rec_asgvoucher.ref_num, 
			l_err_message) 
			DELETE FROM t_voucherdist WHERE 1=1 
			RETURN false, l_rec_voucher.* 
		END IF 
	END IF 
	DELETE FROM t_voucherdist WHERE 1=1 
	RETURN true, l_rec_voucher.* 
END FUNCTION 

############################################################
# REPORT PSW_rpt_list(p_cmpy_code, p_vend_code, p_vouch_code, p_cheq_code,
#                p_line_num,  p_debit_amt, p_credit_amt, p_tran_date)
#
#
############################################################
REPORT PSW_rpt_list(p_cmpy_code,p_vend_code,p_vouch_code,p_cheq_code,p_line_num,p_debit_amt,p_credit_amt,p_tran_date)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE customer.cust_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_line_num LIKE voucher.line_num 
	DEFINE p_debit_amt LIKE voucher.total_amt 
	DEFINE p_credit_amt LIKE voucher.total_amt 
	DEFINE p_tran_date LIKE asg_vouchcheq.tran_date 
	DEFINE l_arr_line ARRAY[4] OF CHAR(132)

	OUTPUT 
	left margin 0 
	ORDER external BY p_cmpy_code, 
	p_vend_code, 
	p_vouch_code, 
	p_cheq_code 
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
			PRINT COLUMN 001, p_cmpy_code, 
			COLUMN 010, p_vend_code, 
			COLUMN 020, p_tran_date USING "dd/mm/yyyy", 
			COLUMN 033, p_vouch_code USING "##########", 
			COLUMN 048, p_cheq_code USING "##########", 
			COLUMN 078, p_line_num USING "###", 
			COLUMN 087, p_debit_amt USING "#############&.&&", 
			COLUMN 106, p_credit_amt USING "#############&.&&" 
			IF p_vouch_code IS NOT NULL THEN 
				LET modu_total_vouch_amt = modu_total_vouch_amt + p_debit_amt 
			END IF 
			IF p_cheq_code IS NOT NULL THEN 
				LET modu_total_cheq_amt = modu_total_cheq_amt + p_credit_amt 
			END IF 
		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 LINES 
			PRINT COLUMN 087, "-------------------------------------" 
			PRINT COLUMN 087, modu_total_vouch_amt USING "#############&.&&", 
			COLUMN 106, modu_total_cheq_amt USING "#############&.&&" 
			PRINT COLUMN 087, "-------------------------------------" 
			SKIP 1 line 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 




############################################################
# FUNCTION start_load_rep()
#
# INITIALIZE AND SET defaults FOR the AP Load Report
############################################################
FUNCTION start_load_rep() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("PSW-2","PSW_rpt_list","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PSW_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	RETURN l_rpt_idx
END FUNCTION 


############################################################
# FUNCTION finish_load_rep()
#
# Finish the AP Load Report
############################################################
FUNCTION finish_load_rep() 
	
	#------------------------------------------------------------
	FINISH REPORT PSW_rpt_list
	CALL rpt_finish("PSW_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  	
END FUNCTION 



############################################################
# FUNCTION rerun()
#
# Rerun the AP processing
############################################################
FUNCTION rerun() 
	DEFINE r_rerun_ind SMALLINT 

	LET r_rerun_ind = true 
	CALL count_records() 
	RETURNING modu_rerun_cnt 
	IF modu_verbose_ind THEN 
		IF modu_rerun_cnt > 0 THEN 
			#7060 Warning: X entries detected in holding table. Unload (Y/N)?
			IF kandoomsg("A",7060,modu_rerun_cnt) = 'N' THEN 
				LET r_rerun_ind = false 
			END IF 
		END IF 
	END IF 
	RETURN r_rerun_ind 
END FUNCTION 



############################################################
# FUNCTION init_values()
#
#  INITIALIZE Counters
#
############################################################
FUNCTION init_values() 
	### INITIALIZE default VALUES ###
	LET modu_err_cnt = 0 
	LET modu_err2_cnt = 0 
	LET modu_kandoo_vo_cnt = 0 
	LET modu_kandoo_cq_cnt = 0 
	LET modu_total_vouch_amt = 0 
	LET modu_total_cheq_amt = 0 
	LET modu_rerun_cnt = NULL 
END FUNCTION 



############################################################
# FUNCTION start_load(p_rerun_flag)
#
# Start Load
############################################################
FUNCTION start_load(p_rerun_flag) 
	DEFINE p_rerun_flag SMALLINT 
	DEFINE l_error_text CHAR(50) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL init_values() 
	IF modu_verbose_ind THEN 
		IF NOT p_rerun_flag THEN 
			IF rerun() THEN 
				LET modu_unload_ind = true 
				IF NOT f_unload(0) THEN 
					RETURN false 
				END IF 
				LET modu_unload_ind = false 
			ELSE 
				RETURN false 
			END IF 
			IF NOT import_vouchcheq(true) THEN 
				RETURN false 
			END IF 
		END IF 
		CALL start_ex_rep() 
		CALL start_load_rep() 
		CALL load_routine() RETURNING l_error_text 
		IF (l_error_text IS NOT null) THEN 
			LET l_msgresp = kandoomsg("P",7046,l_error_text) 
			#7046 AP File Load Aborted. ????????
		ELSE 
			IF (modu_err_cnt + modu_err2_cnt) THEN 
				LET l_msgresp = kandoomsg("P",7047,(modu_err_cnt+modu_err2_cnt)) 
				#7047 AP Load Completed, Errors Encountered
			ELSE 
				IF modu_kandoo_ap_cnt > 0 THEN 
					LET l_msgresp = kandoomsg("P",7048,'') 
					#7048 AP Load Completed Successfully
				ELSE 
					LET l_msgresp = kandoomsg("P",7049,'') 
					#7049 There are NO AP transactions TO process
				END IF 
			END IF 
		END IF 
	ELSE 
		#
		# Non-interactive load
		#
		CALL start_ex_rep() 
		CALL start_load_rep() 
		CALL load_routine() RETURNING l_error_text 
	END IF 
	#
	# FINISH REPORT load_list() first b/c we need TO trigger 'ON LAST ROW'
	#        of PSW_rpt_list_exception() REPORT with Control Totals
	#
	CALL finish_load_rep() 
	CALL finish_ex_rep() 
	IF l_error_text THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION chk_tables()
#
# Check the permanent table that are used specifically FOR this routine
############################################################
FUNCTION chk_tables() 
	DEFINE l_err_message CHAR(110)
	
	#
	# ASG specific check's on the permanent tables FOR load routine
	#
	### IF the ASG Voucher/Cheque table does NOT exist abort load ###
	SELECT unique 1 FROM systables 
	WHERE tabname = "asg_vouchcheq" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_err2_cnt = modu_err2_cnt + 1 
		LET l_err_message = "Execute SQL script TO create ASG tables first ", 
		" Load Aborted" 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		 '', '', '', '', l_err_message ) 
		IF modu_verbose_ind THEN 
			ERROR l_err_message 
		END IF 
		#
		# Dummy line in REPORT TO force DISPLAY of Control Totals
		#
		OUTPUT TO REPORT PSW_rpt_list(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		 '', '', '', '', '', '', '','') 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION chk_balance()
#
# Check Balance of Debits versus Credits
############################################################
FUNCTION chk_balance() 
	DEFINE l_err_message CHAR(110)

	#
	# RULE:
	# As stated by WHICS-Open - each transaction will have a debit AND credit
	# entry therefore we should expect sum of all debits = sum of all credits
	#
	DEFINE 
	pr_sum_of_debits, 
	pr_sum_of_credits DECIMAL(16,2) 

	SELECT sum(for_debit_amt), sum(for_credit_amt) 
	INTO pr_sum_of_debits, pr_sum_of_credits 
	FROM asg_vouchcheq 
	IF pr_sum_of_debits IS NULL THEN 
		LET pr_sum_of_debits = 0 
	END IF 
	IF pr_sum_of_credits IS NULL THEN 
		LET pr_sum_of_credits = 0 
	END IF 
	### Verify the Debit versus Credits - But do NOT stop processing ###
	IF (pr_sum_of_debits != pr_sum_of_credits) THEN 
		LET l_err_message = "WARNING: Debits = ", pr_sum_of_debits, 
		" NOT EQUAL Credits = ", pr_sum_of_credits 
		OUTPUT TO REPORT PSW_rpt_list_exception(rpt_rmsreps_idx_get_idx("PSW_rpt_list_exception"),
		 '', '', '', '', l_err_message ) 
	END IF 
END FUNCTION 


############################################################
# FUNCTION f_unload(p_show_message)
#
# Unload the contents of ASG Voucher table AND THEN delete the contents
############################################################
FUNCTION f_unload(p_show_message) 
	DEFINE p_show_message SMALLINT 
	DEFINE l_unload_cnt INTEGER
	DEFINE l_msgresp LIKE language.yes_flag 

	#
	# UNLOAD contents of interim table
	#
	IF count_records() THEN 
		IF import_vouchcheq(false) THEN 
			WHENEVER ERROR CONTINUE 
			UNLOAD TO modu_load_file SELECT * FROM asg_vouchcheq 
			WHENEVER ERROR stop 
			IF sqlca.sqlcode = 0 THEN 
				LET l_unload_cnt = sqlca.sqlerrd[3] 
				IF l_unload_cnt IS NULL THEN 
					LET l_unload_cnt = 0 
				END IF 
				IF kandoomsg("A",8020,l_unload_cnt) = 'Y' THEN 
					#8020 <VALUE> records unloaded FROM table. Confirm TO CLEAR (Y/N)?
					DELETE FROM asg_vouchcheq WHERE 1=1 
					LET modu_cleared_ind = true 
				ELSE 
					RETURN false 
				END IF 
			ELSE 
				RETURN false 
			END IF 
		ELSE 
			RETURN false 
		END IF 
	ELSE 
		IF p_show_message THEN 
			LET l_msgresp = kandoomsg("P",7050,'') 
			#7050 There are NO AP transactions TO process
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION move_load_file()
#
# Move the original Load File TO another filename
############################################################
FUNCTION move_load_file() 
	DEFINE l_move_file CHAR(100) 
	DEFINE l_move_text CHAR(200) 
	DEFINE l_move_path CHAR(100) 
	DEFINE l_runner CHAR(300) 
	DEFINE l_ret_code INTEGER 
	DEFINE l_tmpmsg STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_move_path = modu_path_text 
	LET l_move_text = modu_load_file clipped, ".tmp" 
	WHILE true 
		LET l_runner = " [ -f ",l_move_text clipped," ] 2>>", trim(get_settings_logFile()) 
		RUN l_runner RETURNING l_ret_code 
		IF l_ret_code THEN 
			EXIT WHILE 
		ELSE 
			IF modu_verbose_ind THEN 
				LET l_msgresp=kandoomsg("P",9000,"") --huho NOT sure IF ths l_msgresp IS used somewhere ELSE too.. bloody GLOBALS 
				LET l_tmpmsg = kandoomsg("P",9000,""), "\n", "Enter Move file name" 
				LET l_move_file = fgl_winprompt(5,5, l_tmpmsg, "", 50, 0) 

				#P9179 - Cannot move load file; File already exists
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN 
				ELSE 
					LET l_move_text = modu_path_text clipped, "/", 
					l_move_file clipped 
				END IF 
			ELSE 
				RETURN 
			END IF 
		END IF 
	END WHILE 
	LET l_runner = " mv ", modu_load_file clipped, " ", l_move_text clipped, 
	" 2> /dev/NULL" 
	RUN l_runner 
END FUNCTION 


############################################################
# FUNCTION show_perc_comp(p_count_value)
#
# Show Percentage Complete
############################################################
FUNCTION show_perc_comp(p_count_value) 
	DEFINE p_count_value SMALLINT 

	### Show percentage complete ###
	LET modu_load_ap_cnt = modu_load_ap_cnt + p_count_value 
	LET modu_ap_per = ( modu_load_ap_cnt / modu_tot_ap_cnt ) * 100 
	IF modu_verbose_ind THEN 
		DISPLAY modu_ap_per TO ap_per 
	END IF 
END FUNCTION 

############################################################
# FUNCTION show_counts(p_count,p_which_one,p_entity_value)
#
# Show Counts
############################################################
FUNCTION show_counts(p_count,p_which_one,p_entity_value) 
	DEFINE p_count SMALLINT 
	DEFINE p_which_one CHAR(2) 
	DEFINE p_entity_value CHAR(20) 

	CASE p_which_one 
		WHEN "LV" LET modu_load_vo_cnt = modu_load_vo_cnt + p_count 
		WHEN "LC" LET modu_load_cq_cnt = modu_load_cq_cnt + p_count 
		WHEN "MV" LET modu_kandoo_vo_cnt = modu_kandoo_vo_cnt + p_count 
		WHEN "MC" LET modu_kandoo_cq_cnt = modu_kandoo_cq_cnt + p_count 
		WHEN "AP" LET modu_kandoo_ap_cnt = modu_kandoo_ap_cnt + p_count 
	END CASE 
	IF modu_verbose_ind THEN 
		DISPLAY modu_load_cq_cnt TO load_cq_cnt 
		DISPLAY modu_load_vo_cnt TO load_vo_cnt 
		DISPLAY modu_kandoo_cq_cnt TO max_cq_cnt 
		DISPLAY modu_kandoo_vo_cnt TO max_vo_cnt  
		IF p_entity_value IS NOT NULL AND 
		p_entity_value != " " 
		THEN 
			CASE p_which_one 
				WHEN "LV" DISPLAY p_entity_value TO vouch_code 

				WHEN "LC" DISPLAY p_entity_value TO cheq_code 

				WHEN "MV" DISPLAY p_entity_value TO vouch_code 

				WHEN "MC" DISPLAY p_entity_value TO cheq_code 

			END CASE 
		END IF 
	END IF 
END FUNCTION 
############################# END OF PSW ###################################


