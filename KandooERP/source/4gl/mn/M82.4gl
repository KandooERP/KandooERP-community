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

#	 $Id: $

# Purpose - Import FROM Planning Tool

# ericv 20170319: does NOT compile, gives place holders miscount. check create tables AND load statements
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	pv_found_error SMALLINT, 
	gl_replaced INTEGER, 
	gl_not_replaced INTEGER, 
	gl_old_part LIKE bor.parent_part_code, 
	gl_new_part LIKE bor.parent_part_code, 
	gl_deleted INTEGER, 
	gl_not_deleted INTEGER, 
	gl_part_code LIKE bor.part_code, 
	gl_effective LIKE bor.end_date, 
	gl_job_filename CHAR(255), 
	gl_ass_filename CHAR(255), 
	gl_dep_filename CHAR(255), 
	gl_res_filename CHAR(255), 
	gl_tsk_filename CHAR(255), 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 


MAIN 

	CALL setModuleId("M82") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL import_main() 

END MAIN 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the SCREEN AND drive the program via a menu        #
#-------------------------------------------------------------------------#

FUNCTION import_main() 

	DEFINE 
	fr_parameter RECORD LIKE mnparms.* 


	SELECT * 
	INTO fr_parameter.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND param_code = "1" -- albo 

	CASE 
		WHEN fr_parameter.plan_type_ind = "T" 
			CALL get_filenames(fr_parameter.*) RETURNING pv_found_error 
			IF pv_found_error = true THEN 
				CALL select_unix(fr_parameter.*) 
				CALL resource_csv(fr_parameter.*) 
				CALL task_csv(fr_parameter.*) 
				CALL assignment_csv(fr_parameter.*) 
				CALL dependency_csv(fr_parameter.*) 
			END IF 

		WHEN fr_parameter.plan_type_ind = "P" 
			CALL get_filenames(fr_parameter.*) RETURNING pv_found_error 
			IF pv_found_error = true THEN 
				CALL select_unix(fr_parameter.*) 
				CALL job_txt(fr_parameter.*) 
			END IF 
	END CASE 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO create a tempory table FOR the REPORT                      #
#-------------------------------------------------------------------------#

FUNCTION drop_resource() 
	WHENEVER ERROR CONTINUE 
	DROP TABLE resource 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION create_resource() 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE resource 
	(fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30)) 
	WHENEVER ERROR stop 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load in the resources AND put them INTO a CSV file         #
#-------------------------------------------------------------------------#

FUNCTION resource_csv(fp_parameter) 

	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field6 FLOAT, 
	fv_filename CHAR(255) 

	CALL drop_resource() 
	CALL create_resource() 

	INITIALIZE fv_field1,fv_field2 
	TO NULL 

	LET fv_filename=gl_res_filename clipped,".CSX" 

	LOAD FROM fv_filename delimiter "," 
	INSERT INTO resource (fv_field6, 
	fv_field1, 
	fv_field2) 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO create a tempory table FOR the REPORT                      #
#-------------------------------------------------------------------------#

FUNCTION drop_tasks() 
	WHENEVER ERROR CONTINUE 
	DROP TABLE tasks 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION create_tasks() 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE tasks 
	(fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30), 
	fv_field4 SMALLINT, 
	fv_field5 SMALLINT, 
	fv_field7 SMALLINT, 
	fv_field8 SMALLINT, 
	fv_field9 SMALLINT, 
	fv_field10 CHAR(30), 
	fv_field12 FLOAT, 
	fv_field13 CHAR(30)) 
	WHENEVER ERROR stop 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the tasks AND put them INTO a CSV file                #
#-------------------------------------------------------------------------#

FUNCTION job_txt(fp_parameter) 

	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(3), 
	fv_field10 CHAR(13), 
	fv_field11 CHAR(41), 
	fv_field4 CHAR(15), 
	fv_field3 CHAR(15), 
	fv_field5 CHAR(10), 
	fv_field6 DATE, 
	fv_field7 SMALLINT, 
	fv_field8 DATE, 
	fv_field9 SMALLINT, 
	fv_field12 DATE, 
	fv_field13 SMALLINT, 
	fv_field14 DATE, 
	fv_field15 SMALLINT, 
	fv_filename CHAR(255) 

	WHENEVER ERROR CONTINUE 
	DROP TABLE planner 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE planner 
	(shop_order_num CHAR(15), 
	suffix_num CHAR(3), 
	cust_code CHAR(13), 
	desc_text CHAR(41), 
	due_date CHAR(8), 
	due_time CHAR(5), 
	start_date CHAR(8), 
	start_time CHAR(5), 
	part_code CHAR(15), 
	seq_num CHAR(15), 
	work_centre_code CHAR(10), 
	op_start_date CHAR(8), 
	op_start_time CHAR(5), 
	op_due_date CHAR(8), 
	op_due_time CHAR(5)) 
	WHENEVER ERROR stop 

	LET gl_job_filename = "UPDATE.new" 
	LET gl_job_filename = fp_parameter.file_dir_text clipped,"/", 
	gl_job_filename clipped 

	LOAD FROM gl_job_filename delimiter "|" 
	INSERT INTO planner(shop_order_num,suffix_num,cust_code,desc_text, 
	due_date,due_time,start_date,start_time, 
	part_code,seq_num,work_centre_code, 
	op_start_date,op_start_time,op_due_date,op_due_time) 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the tasks AND put them INTO a CSV file                #
#-------------------------------------------------------------------------#

FUNCTION task_csv(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30), 
	fv_field4 SMALLINT, 
	fv_field5 SMALLINT, 
	fv_field7 SMALLINT, 
	fv_field8 SMALLINT, 
	fv_field9 SMALLINT, 
	fv_field10 CHAR(30), 
	fv_field12 FLOAT, 
	fv_field13 CHAR(30), 
	fv_filename CHAR(255) 

	CALL drop_tasks() 
	CALL create_tasks() 

	LET fv_filename = gl_tsk_filename clipped,".CSX" 

	LOAD FROM fv_filename delimiter "," 
	INSERT INTO tasks(fv_field6,fv_field1,fv_field2,fv_field3, 
	fv_field4,fv_field5,fv_field7, 
	fv_field8,fv_field9,fv_field10, 
	fv_field12,fv_field13) 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO create a tempory table FOR the REPORT                      #
#-------------------------------------------------------------------------#

FUNCTION drop_assignment() 
	WHENEVER ERROR CONTINUE 
	DROP TABLE assignmnt 

END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION create_assignment() 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE assignmnt 
	(fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30)) 
	WHENEVER ERROR stop 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the assignments AND put them INTO a CSV file          #
#-------------------------------------------------------------------------#

FUNCTION assignment_csv(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30), 
	fv_filename CHAR(255) 

	CALL drop_assignment() 

	CALL create_assignment() 

	LET fv_filename=gl_ass_filename clipped,".CSX" 

	LOAD FROM fv_filename delimiter "," 
	INSERT INTO assignmnt(fv_field6,fv_field1,fv_field2,fv_field3) 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO create a tempory table FOR the REPORT                      #
#-------------------------------------------------------------------------#

FUNCTION drop_dependency() 
	WHENEVER ERROR CONTINUE 
	DROP TABLE depend 

END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION create_dependency() 
	WHENEVER ERROR CONTINUE 
	CREATE TABLE depend 
	(fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30), 
	fv_field4 CHAR(30)) 
	WHENEVER ERROR stop 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the dependencies AND put them in a CSV file           #
#-------------------------------------------------------------------------#

FUNCTION dependency_csv(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_field6 FLOAT, 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(30), 
	fv_field4 CHAR(30), 
	fv_filename CHAR(255) 

	CALL drop_dependency() 
	CALL create_dependency() 

	LET fv_filename = gl_dep_filename clipped,".CSX" 

	LOAD FROM fv_filename delimiter "," 
	INSERT INTO depend(fv_field6,fv_field1,fv_field2, 
	fv_field3,fv_field4) 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the names of the files TO transfer the data in         #
#-------------------------------------------------------------------------#

FUNCTION get_filenames(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_input_ok SMALLINT, 
	fv_tsk_filename CHAR(8), 
	fv_ass_filename CHAR(8), 
	fv_res_filename CHAR(8), 
	fv_dep_filename CHAR(8), 
	fv_job_filename CHAR(8) 

	LET fv_input_ok = true 

	CASE 
		WHEN fp_parameter.plan_type_ind = "P" 
			OPEN WINDOW w1_filenames with FORM "M189" 
			CALL  windecoration_m("M189") -- albo kd-762 

			LET msgresp = kandoomsg("M",1505,"") 			# MESSAGE "esc TO accept del TO EXIT"

			LET fv_job_filename="UPDATE" 

			INPUT fv_job_filename 
			WITHOUT DEFAULTS 
			FROM job_filename 

				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

			END INPUT 

			IF (int_flag 
			OR quit_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET fv_input_ok = false 
				LET msgresp = kandoomsg("M",9680,"") 		# ERROR "Import Aborted"
			ELSE 
				LET gl_job_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_job_filename clipped 
			END IF 
			CLOSE WINDOW w1_filenames 

		WHEN fp_parameter.plan_type_ind = "T" 
			OPEN WINDOW w0_filenames with FORM "M145" 
			CALL  windecoration_m("M145") -- albo kd-762 

			LET msgresp = kandoomsg("M",1505,"") 		# MESSAGE "del TO EXIT esc TO accept"

			LET fv_tsk_filename = "TASKS" 
			LET fv_ass_filename = "ASSIGNMT" 
			LET fv_res_filename = "RESOURCE" 
			LET fv_dep_filename = "DEPEND" 

			INPUT fv_tsk_filename,fv_ass_filename, 
			fv_res_filename,fv_dep_filename 
			WITHOUT DEFAULTS 
			FROM tsk_filename,ass_filename,res_filename,dep_filename 

				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

			END INPUT 

			IF (int_flag 
			OR quit_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET fv_input_ok = false 
				LET msgresp = kandoomsg("M",9680,"") 				# ERROR "Import Aborted"
			ELSE 
				LET gl_tsk_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_tsk_filename clipped 
				LET gl_ass_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_ass_filename clipped 
				LET gl_res_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_res_filename clipped 
				LET gl_dep_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_dep_filename clipped 
			END IF 
			CLOSE WINDOW w0_filenames 
	END CASE 
	RETURN fv_input_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO SELECT unix type                                           #
#-------------------------------------------------------------------------#

FUNCTION select_unix(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fa_unix array[10] OF RECORD 
		blank_field CHAR(1), 
		unix_name CHAR(20) 
	END RECORD, 
	fv_curr_row SMALLINT, 
	fv_parameters CHAR(1500), 
	fv_command CHAR(1600) 

	OPEN WINDOW w0_unix_window with FORM "M146" 
	CALL  windecoration_m("M146") -- albo kd-762 

	LET msgresp = kandoomsg("M",1524,"") # MESSAGE "SELECT Unix Version AND press ESC TO continue"

	FOR fv_curr_row = 1 TO 10 
		INITIALIZE fa_unix[fv_curr_row].* TO NULL 
	END FOR 

	LET fa_unix[1].unix_name = "AIX Unix" 
	LET fa_unix[2].unix_name = "SCO Unix" 

	WHILE true 
		CALL set_count(2) 
		INPUT ARRAY fa_unix WITHOUT DEFAULTS FROM unix_array.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE INSERT 
				LET msgresp = kandoomsg("M",9530,"") # ERROR "There are no more rows in this direction"
				EXIT INPUT 
			BEFORE ROW 
				LET fv_curr_row = arr_curr() 
				DISPLAY fa_unix[fv_curr_row].unix_name 
				TO unix_array[fv_curr_row].unix_name 
				attribute(white,reverse) 
			AFTER ROW 
				LET fv_curr_row = arr_curr() 
				DISPLAY fa_unix[fv_curr_row].unix_name 
				TO unix_array[fv_curr_row].unix_name 
				attribute(white,normal) 
			ON KEY (interrupt) 
				EXIT INPUT 
			ON KEY (accept) 
				EXIT INPUT 
		END INPUT 
		EXIT WHILE 
	END WHILE 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M",9678,"") 
		# ERROR "Export Aborted"
	ELSE 
		CASE 
			WHEN fp_parameter.plan_type_ind = "P" 
				LET fv_parameters = fp_parameter.plan_type_ind clipped," ", 
				gl_job_filename clipped," ", 
				fp_parameter.disk_fmt_flag clipped 
			WHEN fp_parameter.plan_type_ind = "T" 
				LET fv_parameters = fp_parameter.plan_type_ind clipped," ", 
				gl_ass_filename clipped," ", 
				gl_dep_filename clipped," ", 
				gl_res_filename clipped," ", 
				gl_tsk_filename clipped," ", 
				fp_parameter.disk_fmt_flag clipped 
		END CASE 

		CASE 
			WHEN fv_curr_row = 1 
				LET fv_command = "mfgimport.aix ",fv_parameters clipped 
				RUN fv_command 
			WHEN fv_curr_row = 2 
				LET fv_command = "mfgimport.sco ",fv_parameters clipped 
				RUN fv_command 
			OTHERWISE 
				LET msgresp = kandoomsg("M",9679,"") 
				# ERROR "This version of UNIX has NOT been supported"
		END CASE 
	END IF 
	CLOSE WINDOW w0_unix_window 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO UPDATE orders                                              #
#-------------------------------------------------------------------------#

FUNCTION update_orders(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fp_planner RECORD 
		shop_order_num CHAR(15), 
		suffix_num CHAR(3), 
		cust_code CHAR(13), 
		desc_text CHAR(41), 
		due_date CHAR(8), 
		due_time CHAR(5), 
		start_date CHAR(8), 
		start_time CHAR(5), 
		part_code CHAR(15), 
		seq_num CHAR(15), 
		work_centre_code CHAR(10), 
		op_start_date CHAR(8), 
		op_start_time CHAR(5), 
		op_due_date CHAR(8), 
		op_due_time CHAR(5) 
	END RECORD, 
	fv_filename CHAR(255), 
	fv_curr_row SMALLINT, 
	fv_parameters CHAR(1500), 
	fv_command CHAR(1600) 

	DECLARE rep_curs CURSOR FOR 
	SELECT * 
	FROM planner 
	ORDER BY shop_order_num,suffix_num,part_code,seq_num,work_centre_code 

	FOREACH rep_curs INTO fp_planner.* 

		IF fp_planner.desc_text = "MPS" THEN 

			SELECT * 
			FROM mpsdemand 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = fp_planner.cust_code 
			AND part_code = fp_planner.part_code 
			AND reference_num = fp_planner.shop_order_num 
			AND type_text = "RO" 

			IF status = 0 THEN 

				UPDATE mpsdemand 
				SET mpsdemand.due_date = fp_planner.due_date, 
				mpddemand.start_date = fp_planner.start_date 
				WHERE part_code = fp_planner.part_code 
				AND plan_code = fp_planner.cust_code 
				AND reference_num = fp_planner.shop_order_num 
				AND type_text = "RO" 

			END IF 

		ELSE 

			SELECT * 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = fp_planner.shop_order_num 
			AND suffix_num = fp_planner.suffix_num 
			AND part_code = fp_planner.part_code 
			AND status_ind matches "[HR]" 

			IF status = 0 THEN 

				UPDATE shopordhead 
				SET shopordhead.due_date = fp_planner.due_date, 
				shopordhead.start_date = fp_planner.start_date 
				WHERE shop_order_num = fp_planner.shop_order_num 
				AND suffix_num = fp_planner.suffix_num 
				AND part_code = fp_planner.part_code 

				IF fp_planner.seq_num > 0 THEN 

					SELECT * 
					FROM shoporddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = shopordhead.shop_order_num 
					AND suffix_num = shopordhead.suffix_num 
					AND seq_num = fp_planner.seq_num 
					AND work_centre_code = fp_planner.work_centre_code 
					AND type_ind = "W" 

					IF status = 0 THEN 
						UPDATE shoporddetl 
						SET shoporddetl.due_date = shopordhead.due_date, 
						shoporddetl.start_date = shopordhead.start_date 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND shop_order_num = shopordhead.shop_order_num 
						AND suffix_num = shopordhead.suffix_num 
						AND seq_num = fp_planner.seq_num 
						AND work_centre_code = fp_planner.work_centre_code 
						AND type_ind = "W" 
					END IF 

				END IF 

			END IF 

		END IF 

	END FOREACH 

END FUNCTION 

