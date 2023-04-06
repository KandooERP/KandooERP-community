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

# ISC.4gl -  Loads the product table with tariff information AND the
# tariff table with the current tariff rates.

GLOBALS 
	DEFINE 
	pr_company RECORD LIKE company.*, 
	pr_loadparms RECORD LIKE loadparms.*, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_width LIKE rmsreps.report_width_num, 
	rpt_length LIKE rmsreps.page_length_num, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_load_ind LIKE loadparms.load_ind, 
	pr_path_text LIKE loadparms.path_text, 
	pr_file_text LIKE loadparms.file_text, 
	pr_file_count INTEGER, 
	rpt_date DATE, 
	pr_output CHAR(20), 
	line1, line2 CHAR(80), 
	pr_verbose_ind SMALLINT, 
	offset1, offset2 SMALLINT 
END GLOBALS 



####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE 
	rpt_wid LIKE rmsreps.report_width_num, 
	pr_directory CHAR(60), 
	runner CHAR(300), 
	argnum SMALLINT 
	#Initial UI Init
	CALL setModuleId("ISC") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET rpt_wid = 80 
	LET rpt_length = 66 
	LET glob_rec_kandooreport.report_code = "ISC" 
	CALL kandooreport(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.report_code) 
	RETURNING glob_rec_kandooreport.* 
	IF glob_rec_kandooreport.header_text IS NULL THEN 
		CALL set_defaults() 
	END IF 

	CREATE temp TABLE t_loadtariff(part_code CHAR(15), 
	tariff_code CHAR(8), 
	trt_code CHAR(3), 
	tc_code CHAR(7), 
	duty DECIMAL(4,1)) 
	LET argnum = num_args() 
	IF argnum > 0 THEN 
		LET pr_verbose_ind = false 
		LET glob_rec_kandoouser.cmpy_code = arg_val(1) #cmpy_code 
		LET pr_load_ind = arg_val(2) #load_ind 
		CALL load_tariff_files() 
		CALL update_load_parameters() 
	ELSE 
		LET pr_verbose_ind = true 
		OPEN WINDOW i687 with FORM "I687" 
		 CALL windecoration_i("I687") -- albo kd-758 
		MENU " Tariff Load " 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","ISC","menu-Tariff_Load-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Load" " SELECT details TO load" 
				IF enter_load_details() THEN 
					CALL load_tariff_files() 
					CALL update_load_parameters() 
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
				PROMPT "Enter UNIX Pathname: " FOR pr_directory 
				IF int_flag OR quit_flag 
				OR pr_directory IS NULL THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET pr_directory = NULL 
				ELSE 
					LET runner = "ls -f ",pr_directory clipped,"|sort|pg" 
					RUN runner 
				END IF 
				NEXT option "Load" 
			COMMAND KEY(interrupt,"E")"Exit" " RETURN TO menus" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CLOSE WINDOW i687 
	END IF 
END MAIN 



FUNCTION enter_load_details() 
	DEFINE 
	ps_load_ind LIKE loadparms.load_ind, 
	pr_lastkey INTEGER 

	IF pr_loadparms.load_ind IS NULL THEN 
		DECLARE c_loadparms CURSOR FOR 
		SELECT * INTO pr_loadparms.* FROM loadparms 
		WHERE module_code = TRAN_TYPE_INVOICE_IN 
		AND format_ind = "3" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		OPEN c_loadparms 
		FETCH c_loadparms INTO pr_loadparms.* 
		CLOSE c_loadparms 
		LET pr_path_text = pr_loadparms.path_text 
		LET pr_file_text = pr_loadparms.file_text 
	END IF 
	DISPLAY BY NAME pr_loadparms.load_ind, 
	pr_loadparms.desc_text, 
	pr_loadparms.seq_num, 
	pr_loadparms.load_date, 
	pr_loadparms.load_num, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text 

	INPUT BY NAME pr_loadparms.load_ind, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ISC","input-pr_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

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
			RETURN true 
		END IF 
	END IF 
END FUNCTION 


FUNCTION process_file(pr_filename) 
	DEFINE 
	pr_filename CHAR(200), 
	pr_loadtariff RECORD 
		part_code LIKE product.part_code, 
		tariff_code LIKE tariff.tariff_code, 
		trt_code CHAR(3), 
		tc_code CHAR(7), 
		duty_rate DECIMAL(4,1) 
	END RECORD, 
	pr_isam, pr_code,pr_stat, pr_count1 INTEGER, 
	pr_duty_per DECIMAL(6,3), 
	pr_new_code CHAR(12), 
	query_text CHAR(100) 

	LET query_text = "SELECT * FROM t_loadtariff" 
	PREPARE s_loadtariff FROM query_text 
	DECLARE c_loadtariff CURSOR FOR s_loadtariff 
	BEGIN WORK 
		LOCK TABLE product in exclusive MODE 
		LOCK TABLE tariff in exclusive MODE 
		SELECT * INTO pr_company.* 
		FROM company 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_count1 = 0 
		FOREACH c_loadtariff INTO pr_loadtariff.* 
			LET pr_count1 = pr_count1 + 1 
			LET pr_duty_per = pr_loadtariff.duty_rate 
			IF pr_duty_per IS NULL THEN 
				LET pr_duty_per = 0 
			END IF 
			LET pr_new_code = pr_loadtariff.tariff_code clipped, pr_loadtariff.trt_code 
			UPDATE product SET tariff_code = pr_new_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_loadtariff.part_code 
			LET pr_stat = sqlca.sqlerrd[3] 
			LET pr_isam = sqlca.sqlerrd[2] 
			LET pr_code = sqlca.sqlcode 
			OUTPUT TO REPORT isc_list(pr_loadtariff.*,pr_stat,pr_isam, 
			pr_code, '') 
			UPDATE tariff 
			SET duty_per = pr_duty_per 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tariff_code = pr_new_code 
			IF sqlca.sqlerrd[3] = 0 THEN { no ROWS found} 
				INSERT INTO tariff VALUES ( glob_rec_kandoouser.cmpy_code, 
				pr_new_code, 
				pr_duty_per, 
				" ") 
			END IF 
		END FOREACH 
		MESSAGE " Loaded ",pr_count1," Quotes Successfully" 
		attribute(yellow) 
	COMMIT WORK 
END FUNCTION 



FUNCTION load_tariff_files() 
	DEFINE 
	pr_loadtariff RECORD 
		part_code LIKE product.part_code, 
		tariff_code LIKE tariff.tariff_code, 
		trt_code CHAR(3), 
		tc_code CHAR(7), 
		duty_rate DECIMAL(4,1) 
	END RECORD, 
	pr_status INTEGER, 
	pr_count_file SMALLINT, 
	pr_error_text CHAR(100), 
	pr_file_name CHAR(100) 

	IF NOT pr_verbose_ind THEN 
		SELECT * INTO pr_loadparms.* FROM loadparms 
		WHERE load_ind = pr_load_ind 
		AND module_code = 'IN' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound THEN 
			LET pr_error_text = pr_load_ind, " - Incorrect load parameter" 
			OUTPUT TO REPORT isc_list(pr_loadtariff.*,'','', '',pr_error_text) 
			RETURN 
		END IF 
		LET pr_path_text = pr_loadparms.path_text 
		LET pr_file_text = pr_loadparms.file_text 
	END IF 
	### PREPARE list of files TO process ###
	IF list_files_to_process() THEN 
		IF NOT pr_file_count THEN 
			LET pr_error_text = "No tariff files TO load in ", 
			pr_loadparms.path_text clipped 
			OUTPUT TO REPORT isc_list(pr_loadtariff.*,'','', '',pr_error_text) 
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
			LET pr_output = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rec_kandooreport.header_text) 
			START REPORT isc_list TO pr_output 
			CALL insert_tables(pr_file_name) RETURNING pr_status 
			IF pr_status THEN 
				CALL process_file(pr_file_name) 
			END IF 
			FINISH REPORT isc_list 
			CALL upd_reports(pr_output, 
			rpt_pageno, 
			rpt_width, 
			rpt_length) 
		END FOREACH 
		IF pr_verbose_ind THEN 
			--         CLOSE WINDOW w1_ITA  -- albo  KD-758
		END IF 
	END IF 
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
		LET pr_runner = "ls -1 ", pr_path_text clipped, "/\*[!tmp] > allfiles ",trim(get_settings_logFile())		 
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
	pr_loadtariff RECORD 
		part_code LIKE product.part_code, 
		tariff_code LIKE tariff.tariff_code, 
		trt_code CHAR(3), 
		tc_code CHAR(7), 
		duty_rate DECIMAL(4,1) 
	END RECORD, 
	runner CHAR(400), 
	pr_error_text CHAR(100), 
	pr_filename CHAR(200), 
	pr_filename2 CHAR(200) 

	WHENEVER ERROR CONTINUE 
	DELETE FROM t_loadtariff 
	WHERE 1=1 
	LET pr_filename2 = pr_filename clipped,".tmp" 
	LET runner = " mv -f ", pr_filename clipped, " ", 
	pr_filename2 clipped, " 2>> ",trim(get_settings_logFile()) 
	RUN runner 
	LOAD FROM pr_filename2 delimiter "|" INSERT INTO t_loadtariff 
	IF status != 0 THEN 
		IF status = -846 
		OR status = -1213 THEN 
			LET pr_error_text = pr_filename clipped," Incorrect file FORMAT OR blank lines detected" 
			OUTPUT TO REPORT isc_list(pr_loadtariff.*, '','', '',pr_error_text) 
			RETURN false 
		ELSE 
			LET pr_error_text = pr_filename clipped,"Interface file does NOT exist - Check path AND file name" 
			OUTPUT TO REPORT isc_list(pr_loadtariff.*, '','', '',pr_error_text) 
			RETURN false 
		END IF 
	END IF 
	SELECT unique 1 FROM t_loadtariff 
	IF status = notfound THEN 
		LET pr_error_text = pr_filename clipped,"Interface file IS empty " 
		OUTPUT TO REPORT isc_list(pr_loadtariff.*, '','', '',pr_error_text) 
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


REPORT isc_list(pr_loadtariff, pr_stat,pr_isam, pr_code, pr_error_text) 
	DEFINE 
	pr_loadtariff RECORD 
		part_code LIKE product.part_code, 
		tariff_code LIKE tariff.tariff_code, 
		trt_code CHAR(3), 
		tc_code CHAR(7), 
		duty_rate DECIMAL(4,1) 
	END RECORD, 
	pr_isam, pr_code,pr_stat INTEGER, 
	pr_error_text CHAR(100), 
	pa_line array[4] OF CHAR(132) 

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
			IF pr_error_text IS NULL THEN 
				PRINT COLUMN 01, pr_loadtariff.part_code, 
				COLUMN 17, pr_loadtariff.tariff_code clipped,pr_loadtariff.trt_code, 
				COLUMN 37, pr_loadtariff.duty_rate; 
				IF pr_stat = 1 THEN 
					PRINT COLUMN 45, "Updated" 
				ELSE 
					IF pr_stat = 0 THEN 
						PRINT COLUMN 45, "Product Not Found" 
					ELSE 
						PRINT COLUMN 45, pr_stat USING "-----&", 
						COLUMN 52, pr_isam USING "------&", 
						COLUMN 60, pr_code USING "------&" 
					END IF 
				END IF 
			ELSE 
				PRINT COLUMN 01, pr_error_text 
			END IF 

		ON LAST ROW 
			PRINT COLUMN 01, pa_line[4] 
			LET rpt_pageno = pageno 
END REPORT 



FUNCTION set_defaults() 
	LET glob_rec_kandooreport.header_text = "Tariff Upload Report" 
	LET glob_rec_kandooreport.width_num = 80 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "ISC" 
	LET glob_rec_kandooreport.selection_flag = "N" 
	LET glob_rec_kandooreport.line1_text = "Product Tariff Code Duty Rate" 
	UPDATE kandooreport SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 
