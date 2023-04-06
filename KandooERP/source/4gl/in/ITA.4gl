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

	Source code beautified by beautify.pl on 2020-01-03 09:12:45	$Id: $
}


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module ITA - Load IN UNIX Files (stocktake figures).
#                This program accepts data FROM UNIX files that contain
#                stocktake figures TO create stocktake cycles which can
#                THEN be manipulated via the IT* series programs.
########################################################################
# Functions inside this module are:
# - enter_load_details     - In verbose mode, enter load details
# - valid_load             - Verifies the load path AND file
# - move_processed_file    - Once the file IS processed move TO tmp file
# - is_path_valid             - Validation routine FOR Stocktake File path
# - make_prompt            - Makes the prompts FOR the reference fields
# - update_load_parameters - Updates the Stocktake Parameters (seq_num,load_num)
# - load_stocktake_files   - Routine TO load the Stocktake Files
# - process_variable       - Special routine TO load var length IN load files
# - list_files_to_process  - Routine TO list files in a directory FOR processing
# - process_stocktake      - Create the stocktake cycles FROM Stocktake Files
# - set_defaults           - Set Default REPORT names AND parameters
########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_arg1, pr_arg2 CHAR(50), 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_path_text LIKE loadparms.path_text, 
	pr_file_text LIKE loadparms.file_text, 
	pr_load_ind LIKE loadparms.load_ind, 
	pr_format_ind LIKE loadparms.format_ind, 
	pr_seq_num LIKE loadparms.seq_num, 
	pr_loadparms RECORD LIKE loadparms.*, 
	pr_err_message CHAR(120), 
	rpt_pageno LIKE rmsreps.page_num, 
	rpt_note CHAR(132), 
	err_message CHAR(70) , 
	pr_output CHAR(80), 
	pr_load_file CHAR(100), 
	pr_file_count, 
	pr_sql_error, 
	pr_file_error INTEGER, 
	pr_cycle_num, 
	pr_new_load, 
	pr_verbose_ind SMALLINT 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("ITA") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET pr_sql_error = 0 
	WHENEVER ERROR CONTINUE 
	CREATE temp TABLE t_fixed (fixed_record CHAR(80)) with no LOG 
	CREATE temp TABLE t_cycle (cycle_num smallint) with no LOG 
	CREATE temp TABLE t_stktakeload (ware_code CHAR(3), 
	part_code CHAR(15), 
	onhand_qty float) with no LOG 
	CREATE temp TABLE t_tempload(file_record CHAR(80)) with no LOG 
	WHENEVER ERROR stop 
	IF num_args() > 0 THEN 
		# ITA invoked with command line arguments #
		LET pr_verbose_ind = false 
		LET glob_rec_kandoouser.cmpy_code = arg_val(1) #cmpy_code 
		LET pr_load_ind = arg_val(2) #load_ind 
		IF load_stocktake_files() THEN 
		END IF 
		CALL update_load_parameters() 
		DECLARE c_cycle CURSOR FOR 
		SELECT * FROM t_cycle 
		FOREACH c_cycle INTO pr_cycle_num 
			CALL run_prog("IT6",pr_cycle_num, glob_rec_kandoouser.cmpy_code,"","") 
		END FOREACH 
	ELSE 
		LET pr_verbose_ind = true 
		OPEN WINDOW i693 with FORM "I693" 
		 CALL windecoration_i("I693") -- albo kd-758 

		MENU " External Stocktake Load" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","ITA","menu-External_Stocktake-1") -- albo kd-505 
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Load" " Commence load process" 
				IF enter_load_details() THEN 
					IF load_stocktake_files() THEN 
						CALL update_load_parameters() 
						DISPLAY BY NAME pr_loadparms.seq_num, 
						pr_loadparms.load_date, 
						pr_loadparms.load_num 

						NEXT option "Print Manager" 
					END IF 
				END IF 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
				LET quit_flag = true 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW i693 
	END IF 
END MAIN 
#
#
FUNCTION enter_load_details() 
	DEFINE 
	ps_load_ind LIKE loadparms.load_ind, 
	save_ind LIKE loadparms.load_ind, 
	pr_prmpt1_text, 
	pr_prmpt2_text, 
	pr_prmpt3_text LIKE loadparms.prmpt1_text, 
	pr_lastkey INTEGER 

	DECLARE c_loadparms CURSOR FOR 
	SELECT * INTO pr_loadparms.* FROM loadparms 
	WHERE module_code = TRAN_TYPE_INVOICE_IN 
	AND format_ind = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN c_loadparms 
	FETCH c_loadparms INTO pr_loadparms.* 
	LET pr_prmpt1_text = make_prompt(pr_loadparms.prmpt1_text) 
	LET pr_prmpt2_text = make_prompt(pr_loadparms.prmpt2_text) 
	LET pr_prmpt3_text = make_prompt(pr_loadparms.prmpt3_text) 
	DISPLAY pr_prmpt1_text, pr_prmpt2_text, pr_prmpt3_text 
	TO loadparms.prmpt1_text, loadparms.prmpt2_text, loadparms.prmpt3_text 
	attribute(white) 
	DISPLAY BY NAME pr_loadparms.load_ind, 
	pr_loadparms.desc_text, 
	pr_loadparms.seq_num, 
	pr_loadparms.load_date, 
	pr_loadparms.load_num, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text, 
	pr_loadparms.ref1_text, 
	pr_loadparms.ref2_text, 
	pr_loadparms.ref3_text 

	CLOSE c_loadparms 
	INPUT BY NAME pr_loadparms.load_ind, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ITA","input-pr_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD load_ind 
			LET save_ind = pr_loadparms.load_ind 
		AFTER FIELD load_ind 
			IF pr_loadparms.load_ind IS NULL THEN 
				LET msgresp = kandoomsg("A",9208,"") 
				#9208 Load indicator must be entered
				LET pr_loadparms.load_ind = save_ind 
				NEXT FIELD load_ind 
			ELSE 
				IF pr_loadparms.load_ind != save_ind THEN 
					SELECT * INTO pr_loadparms.* FROM loadparms 
					WHERE load_ind = pr_loadparms.load_ind 
					AND module_code = TRAN_TYPE_INVOICE_IN 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp = kandoomsg("A",9206,"") 
						#9206 Invalid Load indicator
						NEXT FIELD load_ind 
					END IF 
				END IF 
			END IF 
		AFTER FIELD file_text 
			IF pr_loadparms.file_text IS NOT NULL 
			AND pr_loadparms.file_text[1,1] != " " THEN 
				LET pr_file_text = pr_loadparms.file_text 
			ELSE 
				LET pr_loadparms.file_text = NULL 
				LET pr_file_text = NULL 
			END IF 
			LET pr_lastkey = fgl_lastkey() 
		AFTER FIELD path_text 
			IF pr_loadparms.path_text IS NULL THEN 
				LET msgresp = kandoomsg("U",9129,"") 
				#U9129 Path name must be entered
				NEXT FIELD path_text 
			ELSE 
				LET pr_path_text = pr_loadparms.path_text clipped 
			END IF 
			LET pr_lastkey = fgl_lastkey() 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_loadparms.load_ind IS NULL THEN 
					LET msgresp = kandoomsg("A",9208,"") 
					#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				ELSE 
					LET pr_load_ind = pr_loadparms.load_ind 
					LET pr_format_ind = pr_loadparms.format_ind 
				END IF 
				IF pr_loadparms.path_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9129,"") 
					#U9129 Path name must be entered
					NEXT FIELD path_text 
				ELSE 
					LET pr_path_text = pr_loadparms.path_text clipped 
				END IF 
				IF NOT is_path_valid(pr_path_text) THEN 
					LET msgresp=kandoomsg("U",9107,"") 
					NEXT FIELD path_text 
				END IF 
				IF pr_file_text IS NOT NULL THEN 
					IF NOT valid_load(pr_path_text, pr_file_text) THEN 
						NEXT FIELD file_text 
					END IF 
				END IF 
				IF list_files_to_process() THEN 
					IF NOT pr_file_count THEN 
						LET msgresp=kandoomsg("I",9268,"") 
						#I9268 There are no Stocktake files TO ...
						NEXT FIELD file_text 
					END IF 
				END IF 
				IF pr_loadparms.path_text IS NULL 
				OR length(pr_loadparms.path_text) = 0 THEN 
					LET pr_loadparms.path_text = "." 
				END IF 
				LET pr_path_text = pr_loadparms.path_text clipped 
				IF NOT is_path_valid(pr_path_text) THEN 
					LET msgresp=kandoomsg("U",9107,"") 
					NEXT FIELD path_text 
				END IF 
				IF pr_loadparms.file_text IS NOT NULL AND 
				pr_loadparms.file_text[1,1] != " " 
				THEN 
					LET pr_file_text = pr_loadparms.file_text 
					IF NOT valid_load(pr_loadparms.path_text, pr_loadparms.file_text) 
					THEN 
						NEXT FIELD file_text 
					END IF 
				ELSE 
					LET pr_loadparms.file_text = NULL 
					LET pr_file_text = NULL 
				END IF 
				IF list_files_to_process() THEN 
					IF NOT pr_file_count THEN 
						LET msgresp=kandoomsg("I",9268,"") 
						#I9268 There are no Stocktake files TO ...
						NEXT FIELD file_text 
					END IF 
				END IF 
				LET msgresp = kandoomsg("U",8028,"") 
				#8028 Begin Processing Load File records ? (Y/N)
				IF msgresp = "N" THEN 
					NEXT FIELD load_ind 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
#
#
FUNCTION valid_load(pr_path_name, pr_file_name) 
	DEFINE 
	runner, 
	pr_file_name CHAR(100), 
	pr_path_name CHAR(100), 
	pr_load_file CHAR(200), 
	ret_code INTEGER 

	LET pr_load_file = pr_path_name clipped, 
	"/",pr_file_name clipped 

	LET ret_code = os.path.exists(pr_load_file) --huho changed TO os.path() method 
	#LET runner = " [ -f ",pr_load_file clipped," ] 2>>",trim(get_settings_logFile())
	#run runner returning ret_code
	IF ret_code THEN 
		LET msgresp=kandoomsg("A",9160,"") 
		#9160 Load file does NOT exist - check path AND filename
		RETURN false 
	END IF 

	LET ret_code = os.path.writable(pr_load_file) --huho changed TO os.path() method 
	#LET runner = " [ -r ",pr_load_file clipped," ] 2>>",trim(get_settings_logFile())
	#run runner returning ret_code
	IF ret_code THEN 
		IF pr_verbose_ind THEN 
			LET msgresp = kandoomsg("A",9162,'') 
			#9162 Unable TO read load file
		END IF 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
#
#   Move Processed Files
#
FUNCTION move_processed_file(pr_file_name) 
	DEFINE 
	pr_file_name CHAR(100), 
	runner CHAR(400), 
	ret_code INTEGER 

	LET runner = " mv -f ", pr_file_name clipped, " ", 
	pr_file_name clipped, ".tmp 2>> ",trim(get_settings_logFile()) 
	RUN runner RETURNING ret_code 
	IF ret_code THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION make_prompt(pr_ref_text) 
	DEFINE 
	pr_ref_text, 
	pr_temp_text LIKE loadparms.ref1_text 

	IF pr_ref_text IS NOT NULL THEN 
		RETURN pr_ref_text 
	ELSE 
		LET pr_temp_text = pr_ref_text clipped,"..............." 
		RETURN pr_temp_text 
	END IF 
END FUNCTION 
#
#
FUNCTION update_load_parameters() 
	SELECT * INTO pr_loadparms.* FROM loadparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND load_ind = pr_load_ind 
	AND module_code = 'IN' 
	UPDATE loadparms 
	SET load_date = today, 
	seq_num = seq_num + 1, 
	load_num = pr_file_count 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND load_ind = pr_load_ind 
	AND module_code = 'IN' 
END FUNCTION 
#
#
FUNCTION load_stocktake_files() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_status INTEGER, 
	pr_count_file SMALLINT, 
	pr_file_name CHAR(100) 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"ITA_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT ITA_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	LET pr_err_message = "Starting Load: ", pr_seq_num USING "<<<<<"
	 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
	#------------------------------------------------------------


	IF NOT pr_verbose_ind THEN 
		SELECT * INTO pr_loadparms.* FROM loadparms 
		WHERE load_ind = pr_load_ind 
		AND module_code = 'IN' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_err_message = "Stocktake Parameters do NOT exist." 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
			#------------------------------------------------------------

			#------------------------------------------------------------
			FINISH REPORT ITA_rpt_list_exception
			CALL rpt_finish("ITA_rpt_list_exception")
			#------------------------------------------------------------ 
			RETURN false 
		END IF 
		LET pr_format_ind = pr_loadparms.format_ind 
		LET pr_path_text = pr_loadparms.path_text 
		LET pr_file_text = pr_loadparms.file_text 
	END IF 
	### PREPARE list of files TO process ###
	DELETE FROM t_stktakeload WHERE 1=1 
	IF status <> 0 THEN 
		LET pr_err_message = "Problems clearing temporary tables. " 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

		IF pr_verbose_ind THEN 
			LET msgresp=kandoomsg("I",9269,"") 
			#I9269 An error has occured in processing...
		END IF 
		RETURN false 
	END IF 
	IF pr_format_ind = "1" THEN 
		DELETE FROM t_tempload WHERE 1=1 
		IF status <> 0 THEN 
			LET pr_err_message = "Problems clearing temporary tables. " 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

			IF pr_verbose_ind THEN 
				LET msgresp=kandoomsg("I",7070,"") 
				#I7070 An error has occured...
			END IF 
			RETURN false 
		END IF 
	END IF 
	### PREPARE list of files TO process ###
	IF list_files_to_process() THEN 
		IF NOT pr_file_count THEN 
			LET pr_err_message = "No stocktake files TO load in ", 
			pr_loadparms.path_text clipped 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
			#------------------------------------------------------------
		
			#------------------------------------------------------------
			FINISH REPORT ITA_rpt_list_exception
			CALL rpt_finish("ITA_rpt_list_exception")
			#------------------------------------------------------------

			IF pr_verbose_ind THEN 
				LET msgresp=kandoomsg("I",9268,"") 
				#I9268 An error has occured...
			END IF 
			RETURN false 
		END IF 
		IF pr_verbose_ind THEN 
			LET msgresp=kandoomsg("I",1005,"") 
			#I1002 Updating database please wait
			--         OPEN WINDOW w1_ITA AT 16,15 with 1 rows,50 columns  -- albo  KD-758
			--            ATTRIBUTE(border)
		END IF 
		### Process list of files collected ###
		DECLARE c_filelist CURSOR with HOLD FOR 
		SELECT * FROM t_filelist 
		WHERE file_name NOT matches "*.tmp" 
		LET pr_file_error = 0 
		LET pr_count_file = 0 
		FOREACH c_filelist INTO pr_file_name 
			LET pr_count_file = pr_count_file + 1 
			IF pr_verbose_ind THEN 
				LET pr_err_message = "File: ", pr_count_file USING "##&", " of ", 
				pr_file_count USING "##&" 
				DISPLAY pr_err_message clipped at 1,1 

			END IF 
			### Determine which Load Format TO use ###
			CASE pr_format_ind 
				WHEN "1" CALL process_variable(l_rpt_idx,pr_file_name)### generic FORMAT ### 
					RETURNING pr_status 
			END CASE 
			### IF file loaded AOK THEN process ###
			IF pr_status THEN 
				IF NOT process_stocktake(l_rpt_idx,pr_file_name) THEN 
					LET pr_file_error = pr_file_error + 1 
				ELSE 
					IF NOT move_processed_file(pr_file_name) THEN 
					END IF 
				END IF 
			ELSE 
				LET pr_file_error = pr_file_error + 1 
			END IF 
		END FOREACH 
		LET pr_err_message = "END of Stocktake Load" 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

		IF pr_verbose_ind THEN 
			--         CLOSE WINDOW w1_ITA  -- albo  KD-758
			IF (pr_file_error) OR (pr_file_count = 0) THEN 
				LET msgresp = kandoomsg("I",7068,"") 
				#I7068 External Stocktake Load completed with exceptions
			ELSE 
				LET msgresp = kandoomsg("I",7069,"") 
				#I7069 External Stocktake Load Completed Successfully
			END IF 
		END IF 
		#------------------------------------------------------------
		FINISH REPORT ITA_rpt_list_exception
		CALL rpt_finish("ITA_rpt_list_exception")
		#------------------------------------------------------------ 
		RETURN true 
	ELSE 
		LET pr_err_message = "Error listing files TO process in ", 
		pr_path_text clipped 
		#------------------------------------------------------------
		OUTPUT TO REPORT ITA_rpt_list_exception(l_rpt_idx,pr_err_message) 
		#------------------------------------------------------------

			#------------------------------------------------------------
			FINISH REPORT ITA_rpt_list_exception
			CALL rpt_finish("ITA_rpt_list_exception")
			#------------------------------------------------------------
		IF pr_verbose_ind THEN 
			LET msgresp = kandoomsg("I",7068,"") 
			#I7068 External Stocktake Load completed with exceptions
		END IF 
		RETURN false 
	END IF 
END FUNCTION 
#
#
FUNCTION process_variable(p_rpt_idx,pr_file_name)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pr_file_name CHAR(100), 
	pr_stk_count INTEGER, 
	pr_stktakeload 
	RECORD 
		ware_code LIKE prodstatus.ware_code, 
		part_code LIKE prodstatus.part_code, 
		count_qty FLOAT 
	END RECORD, 
	pr_error_true SMALLINT 

	WHENEVER ERROR CONTINUE 
	DELETE FROM t_stktakeload WHERE 1=1 
	IF status <> 0 THEN 
		LET pr_err_message = "Error in processing file: ", pr_file_name clipped 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

		RETURN false 
	END IF 
	LOAD FROM pr_file_name delimiter "," INSERT INTO t_stktakeload 
	IF status <> 0 THEN 
		LET pr_err_message = "Error in loading file:", pr_file_name clipped 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

	END IF 
	WHENEVER ERROR stop 
	SELECT count(*) INTO pr_stk_count FROM t_stktakeload 
	IF pr_stk_count = 0 
	OR pr_stk_count IS NULL THEN 
		LET pr_err_message = "File: ", pr_file_name clipped," IS empty" 
	#------------------------------------------------------------
	OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
	#------------------------------------------------------------

		RETURN false 
	END IF 
	DECLARE c_stkcheck1 CURSOR FOR 
	SELECT * FROM t_stktakeload 
	FOREACH c_stkcheck1 INTO pr_stktakeload.* 
		SELECT unique 1 FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_stktakeload.ware_code 
		AND part_code = pr_stktakeload.part_code 
		AND stocked_flag="Y" 
		AND status_ind != "3" 
		IF status = notfound THEN 
			LET pr_err_message = pr_stktakeload.part_code clipped, "/", 
			pr_stktakeload.ware_code, 
			" do NOT exist. ", 
			"File: ", pr_file_name clipped 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
			#------------------------------------------------------------

			LET pr_error_true = true 
		END IF 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_stktakeload.part_code 
		AND serial_flag = 'Y' 
		IF status <> notfound THEN 
			LET pr_err_message = "Serial Items can NOT be bulk loaded. ", 
			pr_stktakeload.part_code clipped, 
			" in File: ", pr_file_name clipped 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
			#------------------------------------------------------------

			LET pr_error_true = true 
		END IF 
	END FOREACH 
	IF pr_error_true THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#
#
FUNCTION list_files_to_process() 

	DEFINE 
	pr_runner CHAR(150) 

	WHENEVER ERROR CONTINUE 
	DROP TABLE t_filelist 
	CREATE temp TABLE t_filelist(file_name CHAR(200)) with no LOG 
	IF status <> 0 THEN 
		RETURN false 
	END IF 
	IF pr_file_text IS NULL THEN 
		LET pr_runner = "ls -1 ", pr_path_text clipped, "/\*[!tmp] > allfiles ", " 2>>",trim(get_settings_logFile()) 
	ELSE 
		LET pr_runner = "ls -1 ", pr_path_text clipped, "/", pr_file_text clipped, " > allfiles 2>>",trim(get_settings_logFile()) 
	END IF 
	RUN pr_runner 
	LOAD FROM "allfiles" INSERT INTO t_filelist 
	WHENEVER ERROR stop 
	IF status <> 0 THEN 
		RETURN false 
	ELSE 
		LET pr_file_count = sqlca.sqlerrd[3] 
		RETURN true 
	END IF 
END FUNCTION 
#
#
FUNCTION process_stocktake(p_rpt_idx,pr_file_name) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	pr_stktake RECORD LIKE stktake.*, 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr2_prodstatus, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_stktakeload 
	RECORD 
		ware_code LIKE prodstatus.ware_code, 
		part_code LIKE prodstatus.part_code, 
		count_qty FLOAT 
	END RECORD, 
	pr_record_count INTEGER, 
	pr_count_qty LIKE stktake.total_count_qty, 
	pr_phys_count_qty LIKE prodstatus.phys_count_qty, 
	pr_file_name CHAR(100), 
	query_text CHAR(1000), 
	pr_error_found SMALLINT 


	GOTO bypass1 
	LABEL recovery1: 
	IF NOT pr_verbose_ind THEN 
		LET pr_sql_error = pr_sql_error + 1 
		ROLLBACK WORK 
		#------------------------------------------------------------
		OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
		#------------------------------------------------------------
		#------------------------------------------------------------
		OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
		#------------------------------------------------------------

		#------------------------------------------------------------
		FINISH REPORT ITA_rpt_list_exception
		CALL rpt_finish("ITA_rpt_list_exception")
		#------------------------------------------------------------ 
		EXIT program 
	ELSE 
		IF error_recover(pr_err_message,status) != "Y" THEN 
			LET pr_sql_error = pr_sql_error + 1 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
			#------------------------------------------------------------
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
			#------------------------------------------------------------
 
			#------------------------------------------------------------
			FINISH REPORT ITA_rpt_list_exception
			CALL rpt_finish("ITA_rpt_list_exception")
			#------------------------------------------------------------
			EXIT program 
		END IF 
	END IF 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 
	BEGIN WORK 
		LET query_text = "SELECT t.*, ps.*, pd.* ", 
		"FROM t_stktakeload t, prodstatus ps, product pd ", 
		"WHERE ps.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND pd.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ps.part_code = pd.part_code ", 
		"AND t.ware_code = ps.ware_code ", 
		"AND t.part_code = ps.part_code ", 
		"AND ps.stocked_flag='Y' ", 
		"AND ps.ware_code IS NOT NULL ", 
		"AND ps.status_ind != '3' " 
		LET pr_err_message = "Problem Preparing Products" 
		PREPARE s_prodstatus FROM query_text 
		DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
		DECLARE c_inparms CURSOR FOR 
		SELECT * INTO pr_inparms.* FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_inparms 
		FETCH c_inparms 
		LET pr_err_message = "Problem Updating Inventory Parameters" 
		UPDATE inparms 
		SET cycle_num = cycle_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_phys_count_qty = 0 
		LET pr_count_qty = 0 
		LET pr_record_count = 0 
		LET pr_error_found = false 
		LET pr_stktake.cycle_num = pr_inparms.cycle_num + 1 
		INSERT INTO t_cycle VALUES (pr_stktake.cycle_num) 
		FOREACH c_prodstatus INTO pr_stktakeload.*, 
			pr_prodstatus.*, 
			pr_product.* 
			SELECT unique 1 FROM stktakedetl 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND ware_code = pr_prodstatus.ware_code 
			AND part_code = pr_prodstatus.part_code 
			IF status = 0 THEN 
				LET pr_error_found = true 
				LET pr_err_message = "Stocktake entries already exist. File: ", 
				pr_file_name clipped, " was NOT processed" 
				EXIT FOREACH 
			END IF 
			LET pr_record_count = pr_record_count + 1 
			IF pr_verbose_ind THEN 
				IF int_flag OR quit_flag THEN 
					#8023 Continue Processing(Y/N)
					IF kandoomsg("U",8023,"") = "N" THEN 
						LET pr_error_found = true 
						LET pr_err_message = "User ", glob_rec_kandoouser.sign_on_code clipped, " Cancelled Load." 
						EXIT FOREACH 
					END IF 
				END IF 
			END IF 
			LET pr_stktakedetl.cmpy_code = pr_prodstatus.cmpy_code 
			LET pr_stktakedetl.cycle_num = pr_stktake.cycle_num 
			LET pr_stktakedetl.part_code = pr_prodstatus.part_code 
			LET pr_stktakedetl.ware_code = pr_prodstatus.ware_code 
			LET pr_stktakedetl.maingrp_code = pr_product.maingrp_code 
			LET pr_stktakedetl.prodgrp_code = pr_product.prodgrp_code 
			IF pr_prodstatus.onhand_qty IS NULL THEN 
				LET pr_prodstatus.onhand_qty = 0 
			END IF 
			LET pr_stktakedetl.onhand_qty = pr_prodstatus.onhand_qty 
			LET pr_stktakedetl.count_qty = pr_stktakeload.count_qty 
			LET pr_stktakedetl.posted_flag = "N" 
			LET pr_stktakedetl.entry_person = glob_rec_kandoouser.sign_on_code 
			LET pr_stktakedetl.entered_date = today 
			LET pr_stktakedetl.posted_date = NULL 
			LET pr_err_message = "Error Inserting Stocktake Details Record" 
			INSERT INTO stktakedetl VALUES (pr_stktakedetl.*) 
			LET pr_stktakedetl.onhand_qty = 0 
			LET pr_prodstatus.phys_count_qty = pr_prodstatus.onhand_qty 
			LET pr_phys_count_qty = pr_phys_count_qty + pr_prodstatus.onhand_qty 
			LET pr_count_qty = pr_count_qty + pr_stktakedetl.count_qty 
			DECLARE c_prodstat CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			FOR UPDATE 
			OPEN c_prodstat 
			FETCH c_prodstat INTO pr2_prodstatus.* 
			LET pr_err_message = "Error Updating Product Status Record" 
			UPDATE prodstatus 
			SET phys_count_qty = pr_prodstatus.phys_count_qty 
			WHERE cmpy_code = pr_prodstatus.cmpy_code 
			AND part_code = pr_prodstatus.part_code 
			AND ware_code = pr_prodstatus.ware_code 
			CLOSE c_prodstat 
			FREE c_prodstat 
		END FOREACH 
		IF pr_error_found THEN 
			ROLLBACK WORK 
			#------------------------------------------------------------
			OUTPUT TO REPORT ITA_rpt_list_exception(p_rpt_idx,pr_err_message) 
			#------------------------------------------------------------

			RETURN false 
		ELSE 
			LET pr_stktake.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_stktake.desc_text = "ITA Load ", 
			pr_seq_num USING "<<<<" 
			LET pr_stktake.start_date = today 
			LET pr_stktake.total_parts_num = pr_record_count 
			LET pr_stktake.total_onhand_qty = pr_phys_count_qty 
			LET pr_stktake.total_count_qty = pr_count_qty 
			LET pr_stktake.status_ind = "1" 
			LET pr_err_message = "Problem Inserting Stocktake Header" 
			INSERT INTO stktake VALUES (pr_stktake.*) 
		COMMIT WORK 
		RETURN true 
	END IF 
	WHENEVER ERROR stop 
END FUNCTION 
#
#
REPORT ITA_rpt_list_exception(p_rpt_idx,pr_comments) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE 
	pa_line array[4] OF CHAR(132), 
	pr_date_time DATETIME year TO second, 
	pr_comments CHAR(120) 

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

		ON EVERY ROW 
			SKIP 1 line 
			LET pr_date_time = CURRENT 
			PRINT COLUMN 001, pr_date_time, 
			COLUMN 022, pr_comments clipped 
		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total Stocktake Load file/s TO be processed : ", 
			pr_file_count USING "####&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total SQL errors : ", 
			pr_sql_error USING "####&" 
			PRINT COLUMN 10, "Total files with errors : ", 
			pr_file_error USING "####&" 
			IF pr_file_count > 0 THEN 
				PRINT COLUMN 10, "Total files successfully processed : ", 
				(pr_file_count - pr_file_error - pr_sql_error) 
				USING "####&" 
			ELSE 
				PRINT COLUMN 10, "Total files successfully processed : ", 
				pr_file_count USING "####&" 
			END IF 
			PRINT COLUMN 54, "-------" 
			PRINT COLUMN 10, "Total Stocktake file/s processed : ", 
			pr_file_count USING "####&" 
			PRINT COLUMN 54, "-------" 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

END REPORT 
