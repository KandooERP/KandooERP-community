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

	Source code beautified by beautify.pl on 2020-01-03 09:12:42	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_prodgrp RECORD LIKE prodgrp.*, 
	pr_path_text LIKE loadparms.path_text, 
	pr_file_text LIKE loadparms.file_text, 
	pr_load_ind LIKE loadparms.load_ind, 
	pr_format_ind LIKE loadparms.format_ind, 
	pr_seq_num LIKE loadparms.seq_num, 
	pr_loadparms RECORD LIKE loadparms.*, 
	rpt_wid LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	directory, loadfile CHAR(60), 
	runner CHAR(300), 
	pr_filename, 
	pr_filename2 CHAR(100), 
	pr_verbose_ind SMALLINT, 
	pr_file_count,pr_file_error INTEGER, 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD, 
	argnum SMALLINT, 
	pr_sale_tax_code LIKE prodstatus.sale_tax_code, 
	pr_purch_tax_code LIKE prodstatus.purch_tax_code 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("ISA") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET rpt_wid = 132 
	LET rpt_length = 66 
	LET glob_rec_kandooreport.report_code = "ISA" 
	CALL kandooreport(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.report_code) 
	RETURNING glob_rec_kandooreport.* 
	IF glob_rec_kandooreport.header_text IS NULL THEN 
		CALL set_defaults() 
	END IF 
	CREATE temp TABLE t_rates(part_code CHAR(15), 
	desc_text CHAR(30), 
	desc2_text CHAR(30), 
	short_desc_text CHAR(15), 
	pur_uom_code CHAR(4), 
	stock_uom_code CHAR(4), 
	sell_uom_code CHAR(4), 
	price_uom_code CHAR(4), 
	ref1_code CHAR(10), 
	ref2_code CHAR(10), 
	ref3_code CHAR(10), 
	weight_qty FLOAT, 
	cubic_qty FLOAT, 
	area_qty FLOAT, 
	length_qty FLOAT, 
	prodgrp_code CHAR(3), 
	cat_code CHAR(3), 
	class_code CHAR(8), 
	maingrp_code CHAR(3), 
	ware_code CHAR(3), 
	vend_code CHAR(8) 
	) with no LOG 
	CREATE temp TABLE t_quaderr(line_num SMALLINT, 
	error_text CHAR(100)) 
	LET argnum = num_args() 
	IF argnum > 0 THEN 
		LET pr_verbose_ind = false 
		LET glob_rec_kandoouser.cmpy_code = arg_val(1) #cmpy_code 
		LET pr_load_ind = arg_val(2) #load_ind 
		CALL load_product_files() 
		CALL report_errors() 
		CALL update_load_parameters() 
	ELSE 
		LET pr_verbose_ind = true 
		OPEN WINDOW i672 with FORM "I672" 
		 CALL windecoration_i("I672") -- albo kd-758 
		DISPLAY " Product Load " at 3,25 
		attribute(white) 
		MENU " Product Load " 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ISA","menu-Product_Load-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Load" " SELECT details TO load" 
				IF enter_load_details() THEN 
					CALL load_product_files() 
					CALL report_errors() 
					NEXT option "Print Manager" 
				ELSE 
					NEXT option "Exit" 
				END IF 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			COMMAND "Directory" " List entries in specified directory" 
				DISPLAY "" at 2,1 
				PROMPT "Enter UNIX Pathname: " FOR directory 
				IF int_flag OR quit_flag 
				OR directory IS NULL THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET directory = NULL 
				ELSE 
					LET runner = "ls -f ",directory clipped,"|pg" 
					RUN runner 
				END IF 
				NEXT option "Load" 
			COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW i672 
	END IF 
END MAIN 


FUNCTION enter_load_details() 
	DEFINE 
	ps_load_ind LIKE loadparms.load_ind, 
	pr_lastkey INTEGER, 
	pr_sale_desc_text, 
	pr_purch_desc_text LIKE tax.desc_text, 
	pr_temp_text CHAR(30) 

	DECLARE c_loadparms CURSOR FOR 
	SELECT * INTO pr_loadparms.* FROM loadparms 
	WHERE module_code = TRAN_TYPE_INVOICE_IN 
	AND format_ind = "2" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN c_loadparms 
	FETCH c_loadparms INTO pr_loadparms.* 
	CALL display_parms(pr_loadparms.*) 
	CLOSE c_loadparms 
	OPTIONS INPUT wrap 
	INPUT BY NAME pr_loadparms.load_ind, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text, 
	pr_prodstatus.sale_tax_code, 
	pr_prodstatus.purch_tax_code, 
	pr_loadparms.ref1_text, 
	pr_loadparms.ref2_text, 
	pr_loadparms.ref3_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISA","input-pr_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(sale_tax_code) 
					LET pr_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_prodstatus.sale_tax_code = pr_temp_text 
					END IF 
					NEXT FIELD sale_tax_code 
				WHEN infield(purch_tax_code) 
					LET pr_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pr_prodstatus.purch_tax_code = pr_temp_text 
					END IF 
					NEXT FIELD purch_tax_code 
			END CASE 
		AFTER FIELD load_ind 
			IF pr_loadparms.load_ind IS NULL THEN 
				LET msgresp = kandoomsg("A",9208,"") 
				#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT * INTO pr_loadparms.* FROM loadparms 
				WHERE load_ind = pr_loadparms.load_ind 
				AND module_code = TRAN_TYPE_INVOICE_IN 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("A",9206,"") 
					#9206 Invalid Load indicator
					NEXT FIELD load_ind 
				ELSE 
					LET pr_load_ind = pr_loadparms.load_ind 
					LET pr_format_ind = pr_loadparms.format_ind 
					CALL display_parms(pr_loadparms.*) 
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
		AFTER FIELD sale_tax_code 
			IF pr_prodstatus.sale_tax_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD sale_tax_code 
			END IF 
			SELECT desc_text INTO pr_sale_desc_text 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_prodstatus.sale_tax_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9076,"") 
				#9076 Taxation code IS NOT found; Try Window.
				NEXT FIELD sale_tax_code 
			END IF 
			DISPLAY pr_sale_desc_text 
			TO sale_desc_text 

		AFTER FIELD purch_tax_code 
			IF pr_prodstatus.purch_tax_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD purch_tax_code 
			END IF 
			SELECT desc_text INTO pr_purch_desc_text 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_prodstatus.purch_tax_code 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9076,"") 
				#9076 Taxation code IS NOT found; Try Window.
				NEXT FIELD purch_tax_code 
			END IF 
			DISPLAY pr_purch_desc_text 
			TO purch_desc_text 

		BEFORE FIELD ref1_text 
			IF pr_loadparms.entry1_flag = 'N' THEN 
				CASE 
					WHEN pr_lastkey = fgl_keyval("RETURN") 
						OR pr_lastkey = fgl_keyval("right") 
						OR pr_lastkey = fgl_keyval("tab") 
						OR pr_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN pr_lastkey = fgl_keyval("left") 
						OR pr_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF 
		AFTER FIELD ref1_text 
			IF pr_loadparms.entry1_flag = 'Y' THEN 
				IF pr_loadparms.ref1_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9122,"") 
					#9122 load reference must be entered
					NEXT FIELD ref1_text 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
			END IF 
		BEFORE FIELD ref2_text 
			IF pr_loadparms.entry2_flag = 'N' THEN 
				CASE 
					WHEN pr_lastkey = fgl_keyval("RETURN") 
						OR pr_lastkey = fgl_keyval("right") 
						OR pr_lastkey = fgl_keyval("tab") 
						OR pr_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN pr_lastkey = fgl_keyval("left") 
						OR pr_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF 
		AFTER FIELD ref2_text 
			IF pr_loadparms.entry2_flag = 'Y' THEN 
				IF pr_loadparms.ref2_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9122,"") 
					#9122 load reference must be entered
					NEXT FIELD ref2_text 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
			END IF 
		BEFORE FIELD ref3_text 
			IF pr_loadparms.entry3_flag = 'N' THEN 
				EXIT INPUT 
			END IF 
		AFTER FIELD ref3_text 
			IF pr_loadparms.entry3_flag = 'Y' THEN 
				IF pr_loadparms.ref3_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9122,"") 
					#9122 load reference must be entered
					NEXT FIELD ref3_text 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
			END IF 
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
						#I9268 There are no load files TO process in the spec
						NEXT FIELD file_text 
					END IF 
				END IF 
				IF pr_prodstatus.sale_tax_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD sale_tax_code 
				END IF 
				SELECT desc_text INTO pr_sale_desc_text 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = pr_prodstatus.sale_tax_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9076,"") 
					#9076 Taxation code IS NOT found; Try Window.
					NEXT FIELD sale_tax_code 
				END IF 
				IF pr_prodstatus.purch_tax_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD purch_tax_code 
				END IF 
				SELECT desc_text INTO pr_purch_desc_text 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = pr_prodstatus.purch_tax_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9076,"") 
					#9076 Taxation code IS NOT found; Try Window.
					NEXT FIELD purch_tax_code 
				END IF 
				IF pr_loadparms.entry1_flag = 'Y' THEN 
					IF pr_loadparms.ref1_text IS NULL THEN 
						LET msgresp = kandoomsg("U",9122,"") 
						#9122 load reference must be entered
						NEXT FIELD ref1_text 
					END IF 
				END IF 
				IF pr_loadparms.entry2_flag = 'Y' THEN 
					IF pr_loadparms.ref2_text IS NULL THEN 
						LET msgresp = kandoomsg("U",9122,"") 
						#9122 load reference must be entered
						NEXT FIELD ref2_text 
					END IF 
				END IF 
				IF pr_loadparms.entry3_flag = 'Y' THEN 
					IF pr_loadparms.ref3_text IS NULL THEN 
						LET msgresp = kandoomsg("U",9122,"") 
						#9122 load reference must be entered
						NEXT FIELD ref3_text 
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
				IF pr_loadparms.file_text IS NOT NULL 
				AND pr_loadparms.file_text[1,1] != " " THEN 
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
						#I9268 There are no load files TO process in the spec
						NEXT FIELD file_text 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("U",8028,"") 
		#8028 Begin Processing Load File records ? (Y/N)
		IF msgresp = "N" THEN 
			RETURN false 
		ELSE 
			LET pr_sale_tax_code = pr_prodstatus.sale_tax_code 
			LET pr_purch_tax_code = pr_prodstatus.purch_tax_code 
			RETURN true 
		END IF 
	END IF 
END FUNCTION 


FUNCTION load_product_files() 
	DEFINE 
	pr_status INTEGER, 
	pr_count_file SMALLINT, 
	pr_file_name CHAR(100) 

	IF NOT pr_verbose_ind THEN 
		SELECT * INTO pr_loadparms.* FROM loadparms 
		WHERE load_ind = pr_load_ind 
		AND module_code = 'IN' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_load_ind, " - Incorrect load parameter" 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			RETURN 
		END IF 
		LET pr_format_ind = pr_loadparms.format_ind 
		LET pr_path_text = pr_loadparms.path_text 
		LET pr_file_text = pr_loadparms.file_text 
	END IF 
	### PREPARE list of files TO process ###
	IF list_files_to_process() THEN 
		IF NOT pr_file_count THEN 
			LET pr_quaderr.error_text = "No product files TO load in ", 
			pr_loadparms.path_text clipped 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			IF pr_verbose_ind THEN 
				LET msgresp=kandoomsg("I",9268,"") 
				#I9268 An error has occured...
			END IF 
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
		LET pr_count_file = 0 
		FOREACH c_filelist INTO pr_file_name 
			LET pr_count_file = pr_count_file + 1 
			IF pr_verbose_ind THEN 
				DISPLAY "File: ", pr_count_file USING "##&", " of ", 
				pr_file_count USING "##&" at 1,1 

			END IF 
			CALL insert_tables(pr_file_name) RETURNING pr_status 
			IF pr_status THEN 
				CALL process_file(pr_file_name) 
			END IF 
		END FOREACH 
		IF pr_verbose_ind THEN 
			--         CLOSE WINDOW w1_ITA  -- albo  KD-758
		END IF 
	END IF 
END FUNCTION 


FUNCTION report_errors() 
	DEFINE 
	pr_output CHAR(50), 
	query_text CHAR(100), 
	pr_err_cnt INTEGER 

	LET query_text = "SELECT * FROM t_quaderr" 
	PREPARE s_quaderr FROM query_text 
	DECLARE c_quaderr CURSOR FOR s_quaderr 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandooreport.header_text) 
	START REPORT quaderrlist TO pr_output 
	FOREACH c_quaderr INTO pr_quaderr.* 
		LET pr_err_cnt = pr_err_cnt + 1 
		OUTPUT TO REPORT quaderrlist(pr_quaderr.*) 
	END FOREACH 
	FINISH REPORT quaderrlist 
	CALL upd_reports(pr_output, rpt_pageno, rpt_wid, rpt_length) 
	DELETE FROM t_quaderr 
	WHERE 1=1 
	DELETE FROM kandooreport 
	WHERE report_code = "ISA" 
	AND language_code = "ENG" 
END FUNCTION 


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
		LET pr_runner = "ls -1 ", pr_path_text clipped, "/\*[!tmp] > allfiles ", 
		" 2>>",trim(get_settings_logFile()) 
	ELSE 
		LET pr_runner = "ls -1 ", pr_path_text clipped, "/", 
		pr_file_text clipped, 
		" > allfiles 2>>",trim(get_settings_logFile()) 
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


FUNCTION insert_tables(pr_filename) 
	DEFINE 
	pr_filename CHAR(200) 

	WHENEVER ERROR CONTINUE 
	DELETE FROM t_rates 
	WHERE 1=1 
	LET pr_filename2 = pr_filename clipped,".tmp" 
	LET runner = " mv -f ", pr_filename clipped, " ", 
	pr_filename2 clipped, " 2>> ",trim(get_settings_logFile()) 
	RUN runner 
	LOAD FROM pr_filename2 delimiter "," INSERT INTO t_rates 
	IF status != 0 THEN 
		IF status = -846 THEN 
			LET pr_quaderr.error_text = pr_filename clipped," Incorrect file FORMAT OR blank lines detected" 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			RETURN false 
		ELSE 
			LET pr_quaderr.error_text = pr_filename clipped,"Interface file does NOT exist - Check path AND file name" 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			RETURN false 
		END IF 
	END IF 
	SELECT unique 1 FROM t_rates 
	IF status = notfound THEN 
		LET pr_quaderr.error_text = pr_filename clipped,"Interface file IS empty - Check PC Transfer was successfull" 
		INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
		INITIALIZE pr_quaderr.* TO NULL 
		RETURN false 
	END IF 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 




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

	LET ret_code = os.path.readable(pr_load_file) --huho changed TO os.path() method 
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


FUNCTION display_parms(pr_loadparms) 
	DEFINE 
	pr_loadparms RECORD LIKE loadparms.*, 
	pr_prmpt1_text, 
	pr_prmpt2_text, 
	pr_prmpt3_text LIKE loadparms.prmpt1_text 

	LET pr_prmpt1_text = make_prompt(pr_loadparms.prmpt1_text) 
	LET pr_prmpt2_text = make_prompt(pr_loadparms.prmpt2_text) 
	LET pr_prmpt3_text = make_prompt(pr_loadparms.prmpt3_text) 
	DISPLAY pr_prmpt1_text, 
	pr_prmpt2_text, 
	pr_prmpt3_text 
	TO loadparms.prmpt1_text, 
	loadparms.prmpt2_text, 
	loadparms.prmpt3_text 
	attribute(white) 
	DISPLAY BY NAME pr_loadparms.load_ind, 
	pr_loadparms.desc_text, 
	pr_loadparms.seq_num, 
	pr_loadparms.load_date, 
	pr_loadparms.load_num, 
	pr_loadparms.seq_num, 
	pr_loadparms.load_date, 
	pr_loadparms.load_num, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text, 
	pr_loadparms.ref1_text, 
	pr_loadparms.ref2_text, 
	pr_loadparms.ref3_text 

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
	IF pr_verbose_ind THEN 
		CALL display_parms(pr_loadparms.*) 
	END IF 
END FUNCTION 


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


FUNCTION process_file(pr_filename) 
	DEFINE 
	pr_filename CHAR(200), 
	pr_rates RECORD 
		part_code CHAR(15), 
		desc_text CHAR(30), 
		desc2_text CHAR(30), 
		short_desc_text CHAR(15), 
		pur_uom_code CHAR(4), 
		stock_uom_code CHAR(4), 
		sell_uom_code CHAR(4), 
		price_uom_code CHAR(4), 
		ref1_code CHAR(10), 
		ref2_code CHAR(10), 
		ref3_code CHAR(10), 
		weight_qty FLOAT, 
		cubic_qty FLOAT, 
		area_qty FLOAT, 
		length_qty FLOAT, 
		prodgrp_code CHAR(3), 
		cat_code CHAR(3), 
		class_code CHAR(8), 
		maingrp_code CHAR(3), 
		ware_code CHAR(3), 
		vend_code CHAR(8) 
	END RECORD, 
	pr_ref_ind CHAR(1), 
	pr_output CHAR(50), 
	pr_err_cnt, pr_inserted_rows, idx SMALLINT, 
	query_text CHAR(100) 

	LET idx = 0 
	LET pr_inserted_rows = 0 
	LET pr_err_cnt = 0 
	INITIALIZE pr_quaderr.* TO NULL 
	INITIALIZE pr_product.* TO NULL 
	LET query_text = "SELECT * FROM t_rates" 
	PREPARE s_rates FROM query_text 
	DECLARE c_rates CURSOR FOR s_rates 
	FOREACH c_rates INTO pr_rates.* 
		INITIALIZE pr_product.* TO NULL 
		LET idx = idx + 1 
		LET pr_product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_product.part_code = pr_rates.part_code 
		IF pr_rates.part_code IS NULL THEN 
			LET pr_quaderr.error_text = "Product Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.desc_text = pr_rates.desc_text 
		LET pr_product.desc2_text = pr_rates.desc2_text 
		LET pr_product.cat_code = pr_rates.cat_code 
		IF pr_rates.desc_text IS NULL THEN 
			LET pr_quaderr.error_text = "Description must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_rates.cat_code IS NULL THEN 
			LET pr_quaderr.error_text = "Category Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM category 
		WHERE cat_code = pr_rates.cat_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.cat_code clipped," This category does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.class_code = pr_rates.class_code 
		IF pr_rates.class_code IS NULL THEN 
			LET pr_quaderr.error_text = "Class Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM class 
		WHERE class_code = pr_rates.class_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.class_code clipped," This class does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.weight_qty = pr_rates.weight_qty 
		IF pr_rates.weight_qty IS NULL THEN 
			LET pr_quaderr.error_text = "Weight Qty must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.cubic_qty = pr_rates.cubic_qty 
		IF pr_rates.cubic_qty IS NULL THEN 
			LET pr_quaderr.error_text = "Cubic Qty must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.setup_date = today 
		LET pr_product.pack_qty = 0 
		LET pr_product.pur_uom_code = pr_rates.pur_uom_code 
		IF pr_rates.pur_uom_code IS NULL THEN 
			LET pr_quaderr.error_text = "Purchase UOM Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM uom 
		WHERE uom_code = pr_rates.pur_uom_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.pur_uom_code clipped," This purchasing uom code does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.stock_uom_code = pr_rates.stock_uom_code 
		IF pr_rates.stock_uom_code IS NULL THEN 
			LET pr_quaderr.error_text = "Stock UOM Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM uom 
		WHERE uom_code = pr_rates.stock_uom_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.stock_uom_code clipped," This stocking uom code does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.sell_uom_code = pr_rates.sell_uom_code 
		IF pr_rates.sell_uom_code IS NULL THEN 
			LET pr_quaderr.error_text = "Sell UOM Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM uom 
		WHERE uom_code = pr_rates.sell_uom_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.sell_uom_code clipped," This selling uom code does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.short_desc_text = pr_rates.short_desc_text 
		IF pr_rates.short_desc_text IS NULL THEN 
			LET pr_quaderr.error_text = "Abbreviated description must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.prodgrp_code = pr_rates.prodgrp_code 
		IF pr_rates.prodgrp_code IS NULL THEN 
			LET pr_quaderr.error_text = "Product Group Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT * INTO pr_prodgrp.* FROM prodgrp 
		WHERE prodgrp_code = pr_rates.prodgrp_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.prodgrp_code clipped," This product group does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		ELSE 
			LET pr_product.maingrp_code = pr_prodgrp.maingrp_code 
		END IF 
		LET pr_product.ref1_code = pr_rates.ref1_code 
		SELECT ref1_ind INTO pr_ref_ind FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		CASE pr_ref_ind 
			WHEN "2" 
				IF pr_rates.ref1_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 1 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
			WHEN "3" 
				IF pr_rates.ref1_code IS NOT NULL THEN 
					SELECT unique 1 FROM userref 
					WHERE ref_ind = "1" 
					AND source_ind = "I" 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ref_code = pr_rates.ref1_code 
					IF status = notfound THEN 
						LET pr_quaderr.error_text = pr_rates.ref1_code clipped, 
						" This reporting code does NOT exist" 
						LET pr_quaderr.line_num = idx 
						INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
						INITIALIZE pr_quaderr.* TO NULL 
						CONTINUE FOREACH 
					END IF 
				END IF 
			WHEN "4" 
				IF pr_rates.ref1_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 1 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
				SELECT unique 1 FROM userref 
				WHERE ref_ind = "1" 
				AND source_ind = "I" 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ref_code = pr_rates.ref1_code 
				IF status = notfound THEN 
					LET pr_quaderr.error_text = pr_rates.ref1_code clipped, 
					" This reporting code does NOT exist" 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
		END CASE 
		LET pr_product.ref2_code = pr_rates.ref2_code 
		SELECT ref2_ind INTO pr_ref_ind FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		CASE pr_ref_ind 
			WHEN "2" 
				IF pr_rates.ref2_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 2 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
			WHEN "3" 
				IF pr_rates.ref2_code IS NOT NULL THEN 
					SELECT unique 1 FROM userref 
					WHERE ref_ind = "2" 
					AND source_ind = "I" 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ref_code = pr_rates.ref2_code 
					IF status = notfound THEN 
						LET pr_quaderr.error_text = pr_rates.ref2_code clipped, 
						" This reporting code does NOT exist" 
						LET pr_quaderr.line_num = idx 
						INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
						INITIALIZE pr_quaderr.* TO NULL 
						CONTINUE FOREACH 
					END IF 
				END IF 
			WHEN "4" 
				IF pr_rates.ref2_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 2 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
				SELECT unique 1 FROM userref 
				WHERE ref_ind = "2" 
				AND source_ind = "I" 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ref_code = pr_rates.ref2_code 
				IF status = notfound THEN 
					LET pr_quaderr.error_text = pr_rates.ref2_code clipped, 
					" This reporting code does NOT exist" 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
		END CASE 
		LET pr_product.ref3_code = pr_rates.ref3_code 
		SELECT ref3_ind INTO pr_ref_ind FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		CASE pr_ref_ind 
			WHEN "2" 
				IF pr_rates.ref3_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 3 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
			WHEN "3" 
				IF pr_rates.ref3_code IS NOT NULL THEN 
					SELECT unique 1 FROM userref 
					WHERE ref_ind = "3" 
					AND source_ind = "I" 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ref_code = pr_rates.ref3_code 
					IF status = notfound THEN 
						LET pr_quaderr.error_text = pr_rates.ref3_code clipped, 
						" This reporting code does NOT exist" 
						LET pr_quaderr.line_num = idx 
						INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
						INITIALIZE pr_quaderr.* TO NULL 
						CONTINUE FOREACH 
					END IF 
				END IF 
			WHEN "4" 
				IF pr_rates.ref3_code IS NULL THEN 
					LET pr_quaderr.error_text = "Report Code 3 must be entered." 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
				SELECT unique 1 FROM userref 
				WHERE ref_ind = "3" 
				AND source_ind = "I" 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ref_code = pr_rates.ref3_code 
				IF status = notfound THEN 
					LET pr_quaderr.error_text = pr_rates.ref3_code clipped, 
					" This reporting code does NOT exist" 
					LET pr_quaderr.line_num = idx 
					INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
					INITIALIZE pr_quaderr.* TO NULL 
					CONTINUE FOREACH 
				END IF 
		END CASE 
		LET pr_product.pur_stk_con_qty = 1 
		LET pr_product.stk_sel_con_qty = 1 
		LET pr_product.price_uom_code = pr_rates.price_uom_code 
		IF pr_rates.price_uom_code IS NULL THEN 
			LET pr_quaderr.error_text = "Price UOM Code must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		SELECT unique 1 FROM uom 
		WHERE uom_code = pr_rates.price_uom_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_quaderr.error_text = pr_rates.price_uom_code clipped," This price uom code does NOT exist" 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.area_qty = pr_rates.area_qty 
		IF pr_rates.area_qty IS NULL THEN 
			LET pr_quaderr.error_text = "Area Qty must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		LET pr_product.length_qty = pr_rates.length_qty 
		IF pr_rates.length_qty IS NULL THEN 
			LET pr_quaderr.error_text = "Length Qty must be entered." 
			LET pr_quaderr.line_num = idx 
			INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
			INITIALIZE pr_quaderr.* TO NULL 
			CONTINUE FOREACH 
		END IF 
		IF pr_rates.vend_code IS NOT NULL THEN 
			SELECT unique 1 FROM vendor 
			WHERE vend_code = pr_rates.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET pr_quaderr.error_text = pr_rates.vend_code clipped," This Vendor code does NOT exist" 
				LET pr_quaderr.line_num = idx 
				INSERT INTO t_quaderr VALUES (pr_quaderr.*) 
				INITIALIZE pr_quaderr.* TO NULL 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LET pr_product.vend_code = pr_rates.vend_code 
		LET pr_product.serial_flag = "N" 
		LET pr_product.target_turn_qty = 0 
		LET pr_product.stock_turn_qty = 0 
		LET pr_product.stock_days_num = 0 
		LET pr_product.outer_qty = 0 
		LET pr_product.outer_sur_per = 0 
		LET pr_product.days_lead_num = 0 
		LET pr_product.min_ord_qty = 0 
		LET pr_product.days_warr_num = 0 
		LET pr_product.total_tax_flag = "Y" 
		LET pr_product.status_ind = "1" 
		LET pr_product.status_date = today 
		LET pr_product.min_month_amt = 0 
		LET pr_product.min_quart_amt = 0 
		LET pr_product.min_year_amt = 0 
		LET pr_product.back_order_flag = "N" 
		LET pr_product.disc_allow_flag = "Y" 
		LET pr_product.bonus_allow_flag = "Y" 
		LET pr_product.trade_in_flag = "N" 
		LET pr_product.price_inv_flag = "Y" 
		SELECT unique 1 FROM product 
		WHERE part_code = pr_rates.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != notfound THEN 
			UPDATE product 
			SET * = pr_product.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_product.part_code 
		ELSE 
			LET pr_inserted_rows = pr_inserted_rows + 1 
			INSERT INTO product VALUES (pr_product.*) 
		END IF 
		SELECT unique 1 FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_product.part_code 
		AND ware_code = pr_rates.ware_code 
		IF status = notfound THEN 
			INITIALIZE pr_prodstatus.* TO NULL 
			LET pr_prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_prodstatus.part_code = pr_product.part_code 
			LET pr_prodstatus.ware_code = pr_rates.ware_code 
			LET pr_prodstatus.onhand_qty = 0 
			LET pr_prodstatus.onord_qty = 0 
			LET pr_prodstatus.reserved_qty = 0 
			LET pr_prodstatus.back_qty = 0 
			LET pr_prodstatus.transit_qty = 0 
			LET pr_prodstatus.forward_qty = 0 
			LET pr_prodstatus.reorder_point_qty = 0 
			LET pr_prodstatus.reorder_qty = 0 
			LET pr_prodstatus.max_qty = 0 
			LET pr_prodstatus.critical_qty = 0 
			LET pr_prodstatus.special_flag = "Y" 
			LET pr_prodstatus.list_amt = 0 
			LET pr_prodstatus.price1_amt = 0 
			LET pr_prodstatus.price2_amt = 0 
			LET pr_prodstatus.price3_amt = 0 
			LET pr_prodstatus.price4_amt = 0 
			LET pr_prodstatus.price5_amt = 0 
			LET pr_prodstatus.price6_amt = 0 
			LET pr_prodstatus.price7_amt = 0 
			LET pr_prodstatus.price8_amt = 0 
			LET pr_prodstatus.price9_amt = 0 
			LET pr_prodstatus.sale_tax_code = pr_sale_tax_code 
			LET pr_prodstatus.purch_tax_code = pr_purch_tax_code 
			LET pr_prodstatus.sale_tax_amt = 0 
			LET pr_prodstatus.purch_tax_amt = 0 
			LET pr_prodstatus.est_cost_amt = 0 
			LET pr_prodstatus.act_cost_amt = 0 
			LET pr_prodstatus.wgted_cost_amt = 0 
			LET pr_prodstatus.for_cost_amt = 0 
			LET pr_prodstatus.for_curr_code = "AUD" 
			LET pr_prodstatus.seq_num = 0 
			LET pr_prodstatus.phys_count_qty = 0 
			LET pr_prodstatus.stocked_flag = "Y" 
			LET pr_prodstatus.stcktake_days = 0 
			LET pr_prodstatus.min_ord_qty = 0 
			LET pr_prodstatus.abc_ind = "A" 
			LET pr_prodstatus.avg_qty = 0 
			LET pr_prodstatus.avg_cost_amt = 0 
			LET pr_prodstatus.stockturn_qty = 0 
			LET pr_prodstatus.status_ind = "1" 
			LET pr_prodstatus.status_date = today 
			LET pr_prodstatus.nonstk_pick_flag = "Y" 
			INSERT INTO prodstatus VALUES (pr_prodstatus.*) 
		END IF 
	END FOREACH 
	DELETE FROM t_rates 
	WHERE 1=1 
END FUNCTION 


REPORT quaderrlist(pr_quaderr) 
	DEFINE 
	pa_line array[4] OF CHAR(132), 
	pr_quaderr RECORD 
		line_num SMALLINT, 
		error_text CHAR(100) 
	END RECORD 
	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL report_header(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.*,pageno) 
			RETURNING pa_line[1], pa_line[2], pa_line[3], pa_line[4] 
			PRINT COLUMN 01, pa_line[1] 
			PRINT COLUMN 01, pa_line[2] 
			PRINT COLUMN 01, pa_line[3] 
			PRINT COLUMN 01, glob_rec_kandooreport.line1_text 
			PRINT COLUMN 01, pa_line[3] 
		ON EVERY ROW 
			PRINT COLUMN 04, pr_quaderr.line_num USING "###&", 
			COLUMN 18, pr_quaderr.error_text 
		ON LAST ROW 
			PRINT COLUMN 01, pa_line[4] 
			LET rpt_pageno = pageno 
END REPORT 


FUNCTION set_defaults() 
	LET glob_rec_kandooreport.header_text = "Product Upload Error Report" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "ISA" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = " Line Number Error Text" 
	UPDATE kandooreport SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 
