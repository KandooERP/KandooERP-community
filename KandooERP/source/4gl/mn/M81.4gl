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

	Source code beautified by beautify.pl on 2020-01-02 17:31:35	$Id: $
}


# Purpose - Export TO Planning Tool

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	fv_type_text CHAR(3), 
	formname CHAR(10), 
	gl_job_filename CHAR(255), 
	gl_ass_filename CHAR(255), 
	gl_dep_filename CHAR(255), 
	gl_res_filename CHAR(255), 
	gl_tsk_filename CHAR(255), 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 

DEFINE 
mv_first_line SMALLINT, 
mv_where_part CHAR(1000), 
mv_where_part2 CHAR(1000) 

MAIN 

	#Initial UI Init
	CALL setModuleId("M81") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL export_main() 

END MAIN 

#-------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY the SCREEN AND drive the program via a menu        #
#-------------------------------------------------------------------------#

FUNCTION export_main() 
	DEFINE 
	fr_parameter RECORD LIKE mnparms.* 

	OPEN WINDOW w0_export_orders with FORM "M128" 
	CALL  windecoration_m("M128") -- albo kd-762 

	SELECT mnparms.* 
	INTO fr_parameter.* 
	FROM mnparms 
	WHERE mnparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND mnparms.param_code = "1" -- albo 

	CALL kandoomenu("M", 137) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 
		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			CALL query_orders() 
			IF mv_where_part IS NOT NULL THEN 
				CASE 
					WHEN fr_parameter.plan_type_ind = "P" 
						IF get_filenames(fr_parameter.*) THEN 
							{
							                            OPEN WINDOW w0_working AT 2,8 with 3 rows,56 columns      -- albo  KD-762
							                                ATTRIBUTE(white,border)
							}
							CALL planner(mv_where_part, mv_where_part2) 
							IF fr_parameter.disk_fmt_flag<>"A" THEN 
								CALL select_unix(fr_parameter.*) 
							END IF 
							--                            CLOSE WINDOW w0_working    -- albo  KD-762
						END IF 

					WHEN fr_parameter.plan_type_ind = "T" 
						IF get_filenames(fr_parameter.*) THEN 
							{
							                            OPEN WINDOW w0_working AT 2,8 with 3 rows,56 columns   -- albo  KD-762
							                                ATTRIBUTE(white,border)
							}
							CALL resource_csv(fr_parameter.*) 
							CALL task_csv(fr_parameter.*) 
							CALL assignment_csv(fr_parameter.*) 
							CALL dependency_csv(fr_parameter.*) 
							IF fr_parameter.disk_fmt_flag<>"A" THEN 
								CALL select_unix(fr_parameter.*) 
							END IF 
							--                            CLOSE WINDOW w0_working      -- albo  KD-762
						END IF 
				END CASE 
			END IF 
		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			EXIT MENU 
		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 
	CLOSE WINDOW w0_export_orders 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO query what shop orders are TO be exported                  #
#-------------------------------------------------------------------------#

FUNCTION query_orders() 

	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "esc TO accept del TO EXIT"

	CONSTRUCT mv_where_part 
	ON shopordhead.shop_order_num, 
	shopordhead.cust_code,shopordhead.part_code, 
	shopordhead.status_ind,shopordhead.order_qty, 
	shopordhead.uom_code,shopordhead.start_date, 
	shopordhead.release_date,shopordhead.end_date 
	FROM shop_order_num,cust_code,part_code,status_ind, 
	order_qty,uom_code,start_date,release_date, 
	end_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET mv_where_part = NULL 
		LET msgresp = kandoomsg("M",9555,"") 
		# ERROR "Query Aborted"
	ELSE 
		LET mv_where_part=mv_where_part clipped," AND ", "shopordhead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"'" 
		OPEN WINDOW wm148 with FORM "M148" 
		CALL  windecoration_m("M148") -- albo kd-762 

		LET fv_type_text = "RO" 

		LET msgresp = kandoomsg("M",1505,"") # MESSAGE "ESC TO Accept - DEL TO Exit"

		CONSTRUCT mv_where_part2 
		ON mpsdemand.part_code, 
		mpsdemand.plan_code, 
		mpsdemand.start_date, 
		mpsdemand.due_date 
		FROM mpsdemand.part_code, 
		mpsdemand.plan_code, 
		mpsdemand.start_date, 
		mpsdemand.due_date 

		LET mv_where_part2 = mv_where_part2 clipped," AND ", 
		"mpsdemand.cmpy_code='",glob_rec_kandoouser.cmpy_code,"'" 

		CLOSE WINDOW wm148 

	END IF 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load in the resources AND put them INTO a CSV file         #
#-------------------------------------------------------------------------#

FUNCTION resource_csv(fp_parameter) 
	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_which CHAR(1), 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(7), 
	fv_field4 DATE, 
	fv_field5 CHAR(8), 
	fv_field6 FLOAT, 
	fv_field7 CHAR(15), 
	fv_field8 CHAR(10), 
	fv_field9 CHAR(10), 
	fv_field10 CHAR(30), 
	fv_field11 CHAR(9), 
	fv_select_text CHAR(2000), 
	fv_select_text2 CHAR(2000), 
	fv_filename CHAR(255) 

	INITIALIZE fv_field1,fv_field2,fv_field3,fv_field4,fv_field5,fv_field6, 
	fv_field7,fv_field8,fv_field9,fv_field10,fv_field11 
	TO NULL 

	LET fv_which = "R" 
	LET fv_field9 = "Hours" 
	LET mv_first_line = true 
	LET fv_filename = gl_res_filename clipped,".CSV" 

	START REPORT csv_report TO fv_filename 

	LET fv_select_text="SELECT unique shoporddetl.work_centre_code ", 
	"FROM shopordhead,shoporddetl ", 
	"WHERE ",mv_where_part clipped," AND ", 
	"shopordhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND shopordhead.cmpy_code = shoporddetl.cmpy_code ", 
	" AND shoporddetl.shop_order_num=shopordhead.shop_order_num ", 
	" AND shoporddetl.type_ind='W' ", 
	"ORDER BY shoporddetl.work_centre_code" 

	PREPARE statement1 FROM fv_select_text 
	DECLARE sresrc_cursor CURSOR FOR statement1 

	FOREACH sresrc_cursor INTO fv_field8 
		CALL working("Resource",fv_field8) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
		fv_field5,fv_field6,fv_field7,fv_field8, 
		fv_field9,fv_field10,fv_field11,fv_which, 
		fp_parameter.*) 
		LET mv_first_line=false 
	END FOREACH 
	FINISH REPORT csv_report 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the tasks AND put them INTO a CSV file                #
#-------------------------------------------------------------------------#

FUNCTION task_csv(fp_parameter) 

	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_which CHAR(1), 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(7), 
	fv_field4 DATE, 
	fv_field5 CHAR(8), 
	fv_field6 FLOAT, 
	fv_field7 CHAR(15), 
	fv_field8 CHAR(10), 
	fv_field9 CHAR(10), 
	fv_field10 CHAR(30), 
	fv_field11 CHAR(9), 
	fv_shop_order LIKE shoporddetl.shop_order_num, 
	fv_old_order LIKE shoporddetl.shop_order_num, 
	fv_suffix_num LIKE shoporddetl.suffix_num, 
	fv_old_suffix LIKE shoporddetl.suffix_num, 
	fv_sequence LIKE shoporddetl.sequence_num, 
	fv_work_centre LIKE shoporddetl.work_centre_code, 
	fv_oper_factor LIKE shoporddetl.oper_factor_amt, 
	fv_quantity LIKE shoporddetl.required_qty, 
	fv_start_date LIKE shoporddetl.start_date, 
	fv_end_date LIKE shoporddetl.end_date, 
	fv_order_qty LIKE shopordhead.order_qty, 
	fv_time_qty LIKE workcentre.time_qty, 
	fv_time_unit LIKE workcentre.time_unit_ind, 
	fv_processing LIKE workcentre.processing_ind, 
	fv_select_text CHAR(2000), 
	fv_select_text2 CHAR(2000), 
	fv_filename CHAR(255) 

	INITIALIZE fv_field1,fv_field2,fv_field3,fv_field4,fv_field5,fv_field6, 
	fv_field7,fv_field8,fv_field9,fv_field10,fv_field11 
	TO NULL 

	LET fv_which = "T" 
	LET fv_field5 = "Effort" 
	LET fv_old_order = 0 
	LET mv_first_line = true 
	LET fv_filename = gl_tsk_filename clipped,".CSV" 

	START REPORT csv_report TO fv_filename 

	LET fv_select_text="SELECT shoporddetl.shop_order_num,", 
	"shoporddetl.suffix_num,", 
	"shoporddetl.sequence_num,", 
	"shoporddetl.work_centre_code,", 
	"shoporddetl.required_qty,", 
	"shoporddetl.oper_factor_amt,", 
	"shoporddetl.start_date,", 
	"shoporddetl.end_date ", 
	"FROM shopordhead,shoporddetl ", 
	"WHERE ",mv_where_part clipped," AND ", 
	"shopordhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND shoporddetl.cmpy_code = shopordhead.cmpy_code ", 
	" AND shoporddetl.shop_order_num=shopordhead.shop_order_num ", 
	" AND shoporddetl.type_ind='W' ", 
	"ORDER BY shoporddetl.shop_order_num,shoporddetl.sequence_num" 

	PREPARE statement2 FROM fv_select_text 
	DECLARE stask_cursor CURSOR FOR statement2 

	FOREACH stask_cursor 
		INTO fv_shop_order,fv_suffix_num,fv_sequence, 
		fv_work_centre, fv_order_qty, fv_oper_factor, 
		fv_start_date, fv_end_date 

		IF fv_shop_order <> fv_old_order THEN 
			IF fv_old_order > 0 THEN 
				LET fv_field1 = fv_old_order USING "&&&&&&",".999999" 
				LET fv_field2 = "Planned Completion - S/O#", 
				fv_old_order USING "<<<<<&" 
				CASE 
					WHEN fp_parameter.schedule_flag = "B" 
						LET fv_field3 = "Fixed" 
					WHEN fp_parameter.schedule_flag = "F" 
						LET fv_field3 = "ASAP" 
				END CASE 

				SELECT shopordhead.end_date,shopordhead.order_qty 
				INTO fv_field4,fv_order_qty 
				FROM shopordhead 
				WHERE shopordhead.shop_order_num = fv_old_order 
				AND shopordhead.suffix_num = fv_old_suffix 
				AND shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET fv_field6 = 0 
				LET fv_field7 = fv_old_order USING "&&&&&&" 
				LET fv_field11 = "No Later" 

				CALL working("Shop Order",fv_shop_order) 
				OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3, 
				fv_field4,fv_field5,fv_field6, 
				fv_field7,fv_field8,fv_field9, 
				fv_field10,fv_field11,fv_which, 
				fp_parameter.*) 
			END IF 

			LET fv_field1 = fv_shop_order USING "&&&&&&" 
			LET fv_field2 = "Shop Order #",fv_shop_order USING "<<<<<&" 
			LET fv_field3 = "Fixed" 
			LET fv_field4 = fv_start_date 
			LET fv_field6 = NULL 
			LET fv_field7 = NULL 
			LET fv_field11 = "No Sooner" 

			CALL working("Shop Order",fv_shop_order) 
			OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
			fv_field5,fv_field6,fv_field7,fv_field8, 
			fv_field9,fv_field10,fv_field11, 
			fv_which,fp_parameter.*) 

			LET mv_first_line = false 
			LET fv_field1 = fv_shop_order USING "&&&&&&",".000000" 
			LET fv_field2 = "Planned Release - S/O#", 
			fv_shop_order USING "<<<<<&" 

			CASE 
				WHEN fp_parameter.schedule_flag = "B" 
					LET fv_field3 = "ALAP" 
				WHEN fp_parameter.schedule_flag = "F" 
					LET fv_field3 = "Fixed" 
			END CASE 

			LET fv_field6 = 0 
			LET fv_field7 = fv_shop_order USING "&&&&&&" 
			LET fv_field11 = "No Sooner" 
			LET fv_old_order = fv_shop_order 
			LET fv_old_suffix = fv_suffix_num 

			CALL working("Start Date",fv_field4) 
			OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
			fv_field5,fv_field6,fv_field7,fv_field8, 
			fv_field9,fv_field10,fv_field11, 
			fv_which,fp_parameter.*) 
		END IF 

		IF fv_old_order>0 THEN 
			SELECT shopordhead.order_qty 
			INTO fv_order_qty 
			FROM shopordhead 
			WHERE shopordhead.shop_order_num = fv_old_order 
			AND shopordhead.suffix_num = fv_old_suffix 
			AND shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 

		LET fv_field1=fv_shop_order USING "&&&&&&","." 

		SELECT workcentre.desc_text, workcentre.time_qty, 
		workcentre.processing_ind, workcentre.time_unit_ind 
		INTO fv_field2, fv_time_qty, fv_processing, fv_time_unit 
		FROM workcentre 
		WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND workcentre.work_centre_code = fv_work_centre 

		CASE 
			WHEN fp_parameter.schedule_flag = "B" 
				LET fv_field3 = "ALAP" 
			WHEN fp_parameter.schedule_flag = "F" 
				LET fv_field3 = "ASAP" 
		END CASE 

		LET fv_field4 = NULL 

		IF fv_processing = "Q" THEN 
			LET fv_field6 = (fv_order_qty * fv_oper_factor) / fv_time_qty 
		ELSE 
			LET fv_field6 = (fv_order_qty * fv_oper_factor) * fv_time_qty 
		END IF 

		LET fv_field7 = fv_shop_order USING "&&&&&&" 
		LET fv_field11 = NULL 

		CALL working("Task",fv_field1) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
		fv_field5,fv_field6,fv_field7,fv_field8, 
		fv_field9,fv_field10,fv_field11,fv_which, 
		fp_parameter.*) 
	END FOREACH 

	IF fv_old_order > 0 THEN 
		LET fv_field1 = fv_old_order USING "&&&&&&",".999999" 
		LET fv_field2 = "Planned Completion - S/O#", fv_old_order USING "<<<<<&" 

		CASE 
			WHEN fp_parameter.schedule_flag = "B" 
				LET fv_field3 = "Fixed" 
			WHEN fp_parameter.schedule_flag = "F" 
				LET fv_field3 = "ASAP" 
		END CASE 

		LET fv_field4 = fv_end_date 

		SELECT shopordhead.end_date,shopordhead.order_qty 
		INTO fv_field4,fv_order_qty 
		FROM shopordhead 
		WHERE shopordhead.shop_order_num = fv_old_order 
		AND shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET fv_field6 = 0 
		LET fv_field7 = fv_old_order USING "&&&&&&" 
		LET fv_field11 = "No Later" 

		CALL working("Shop Order",fv_shop_order) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3, 
		fv_field4,fv_field5,fv_field6, 
		fv_field7,fv_field8,fv_field9, 
		fv_field10,fv_field11,fv_which, 
		fp_parameter.*) 
	END IF 
	FINISH REPORT csv_report 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the assignments AND put them INTO a CSV file          #
#-------------------------------------------------------------------------#

FUNCTION assignment_csv(fp_parameter) 

	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_which CHAR(1), 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(7), 
	fv_field4 DATE, 
	fv_field5 CHAR(8), 
	fv_field6 FLOAT, 
	fv_field7 CHAR(15), 
	fv_field8 CHAR(10), 
	fv_field9 CHAR(10), 
	fv_field10 CHAR(30), 
	fv_field11 CHAR(9), 
	fv_suffix_num LIKE shoporddetl.suffix_num, 
	fv_shop_order LIKE shoporddetl.shop_order_num, 
	fv_old_order LIKE shoporddetl.shop_order_num, 
	fv_work_centre LIKE shoporddetl.work_centre_code, 
	fv_oper_factor LIKE shoporddetl.oper_factor_amt, 
	fv_select_text CHAR(2000), 
	fv_select_text2 CHAR(2000), 
	fv_filename CHAR(255) 

	INITIALIZE fv_field1,fv_field2,fv_field3,fv_field4,fv_field5,fv_field6, 
	fv_field7,fv_field8,fv_field9,fv_field10,fv_field11 
	TO NULL 

	LET fv_which = "A" 
	LET mv_first_line = true 
	LET fv_filename = gl_ass_filename clipped,".CSV" 

	START REPORT csv_report TO fv_filename 
	LET fv_select_text= 
	"SELECT shoporddetl.shop_order_num, shoporddetl.suffix_num, ", 
	"shoporddetl.work_centre_code, shoporddetl.oper_factor_amt ", 
	"FROM shopordhead,shoporddetl ", 
	"WHERE ",mv_where_part clipped," AND ", 
	" shopordhead.cmpy_code = shoporddetl.cmpy_code ", 
	" AND shoporddetl.shop_order_num=shopordhead.shop_order_num ", 
	" AND shoporddetl.suffix_num=shopordhead.suffix_num ", 
	" AND shoporddetl.type_ind='W' ", 
	"ORDER BY shoporddetl.shop_order_num, ", 
	"shoporddetl.suffix_num" 

	PREPARE statement3 FROM fv_select_text 
	DECLARE sassmt_cursor CURSOR FOR statement3 

	FOREACH sassmt_cursor 
		INTO fv_shop_order, fv_suffix_num, 
		fv_work_centre, fv_oper_factor 

		LET fv_field1 = fv_shop_order USING "&&&&&&" 

		SELECT workcentre.desc_text 
		INTO fv_field2 
		FROM workcentre 
		WHERE workcentre.cmpy_code=glob_rec_kandoouser.cmpy_code 
		AND workcentre.work_centre_code=fv_work_centre 

		LET fv_field8 = fv_work_centre 
		CALL working("Assignment",fv_field8) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
		fv_field5,fv_field6,fv_field7,fv_field8, 
		fv_field9,fv_field10,fv_field11,fv_which, 
		fp_parameter.*) 
		LET mv_first_line = false 
	END FOREACH 
	FINISH REPORT csv_report 
END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO load the dependencies AND put them in a CSV file           #
#-------------------------------------------------------------------------#

FUNCTION dependency_csv(fp_parameter) 

	DEFINE 
	fp_parameter RECORD LIKE mnparms.*, 
	fv_which CHAR(1), 
	fv_field1 CHAR(15), 
	fv_field2 CHAR(30), 
	fv_field3 CHAR(7), 
	fv_field4 DATE, 
	fv_field5 CHAR(8), 
	fv_field6 FLOAT, 
	fv_field7 CHAR(15), 
	fv_field8 CHAR(10), 
	fv_field9 CHAR(10), 
	fv_field10 CHAR(30), 
	fv_field11 CHAR(9), 
	fv_suffix_num LIKE shoporddetl.suffix_num, 
	fv_shop_order LIKE shoporddetl.work_centre_code, 
	fv_old_order LIKE shoporddetl.work_centre_code, 
	fv_work_centre LIKE shoporddetl.work_centre_code, 
	fv_old_centre LIKE shoporddetl.work_centre_code, 
	fv_start_date LIKE shopordhead.start_date, 
	fv_dependency CHAR(30), 
	fv_select_text CHAR(2000), 
	fv_select_text2 CHAR(2000), 
	fv_filename CHAR(255) 

	INITIALIZE fv_field1,fv_field2,fv_field3,fv_field4,fv_field5,fv_field6, 
	fv_field7,fv_field8,fv_field9,fv_field10,fv_field11 
	TO NULL 

	LET fv_which = "D" 
	LET fv_old_order = 0 
	LET fv_old_centre = NULL 
	LET mv_first_line = true 
	LET fv_filename = gl_dep_filename clipped,".CSV" 

	START REPORT csv_report TO fv_filename 

	LET fv_select_text= 
	"SELECT shoporddetl.shop_order_num, shoporddetl.suffix_num, ", 
	"shoporddetl.work_centre_code ", 
	"FROM shopordhead,shoporddetl ", 
	"WHERE ",mv_where_part clipped," AND ", 
	" shopordhead.cmpy_code = shoporddetl.cmpy_code ", 
	" AND shoporddetl.shop_order_num=shopordhead.shop_order_num ", 
	" AND shoporddetl.type_ind='W' ", 
	"ORDER BY shoporddetl.shop_order_num " 

	PREPARE statement4 FROM fv_select_text 
	DECLARE sdepnd_cursor CURSOR FOR statement4 

	FOREACH sdepnd_cursor INTO fv_shop_order,fv_suffix_num,fv_work_centre 
		IF fv_shop_order <> fv_old_order THEN 
			IF fv_old_order > 0 THEN 
				LET fv_field1 = fv_old_order USING "&&&&&&" 

				SELECT workcentre.desc_text 
				INTO fv_field2 
				FROM workcentre 
				WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND workcentre.work_centre_code = fv_old_centre 

				LET fv_field7 = fv_old_order USING "&&&&&&",".999999" 
				LET fv_field10 = "Planned Completion - S/O#", 
				fv_old_order USING "<<<<<&" 
				LET fv_dependency = fv_field1 clipped," -> ",fv_field7 clipped 

				CALL working("Dependency",fv_dependency) 
				OUTPUT TO REPORT csv_report 
				(fv_field1,fv_field2,fv_field3,fv_field4, 
				fv_field5,fv_field6,fv_field7,fv_field8, 
				fv_field9,fv_field10,fv_field11, 
				fv_which,fp_parameter.*) 

				LET mv_first_line = false 
				LET fv_old_order = fv_shop_order 
				LET fv_old_centre = fv_work_centre 
			END IF 

			LET fv_field1 = fv_shop_order USING "&&&&&&",".000000" 
			LET fv_field2 = "Planned Release - S/O#", 
			fv_shop_order USING "<<<<<&" 
			LET fv_field7 = fv_shop_order USING "&&&&&&","." 

			SELECT workcentre.desc_text 
			INTO fv_field10 
			FROM workcentre 
			WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND workcentre.work_centre_code = fv_work_centre 

			LET fv_dependency = fv_field1 clipped," -> ",fv_field7 clipped 

			CALL working("Dependency",fv_dependency) 
			OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
			fv_field5,fv_field6,fv_field7,fv_field8, 
			fv_field9,fv_field10,fv_field11, 
			fv_which,fp_parameter.*) 
			LET mv_first_line = false 
			LET fv_old_order = fv_shop_order 
			LET fv_old_centre = fv_work_centre 
			CONTINUE FOREACH 
		END IF 

		LET fv_field1 = fv_old_order USING "&&&&&&" 

		SELECT workcentre.desc_text 
		INTO fv_field2 
		FROM workcentre 
		WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND workcentre.work_centre_code = fv_old_centre 

		LET fv_field7 = fv_shop_order USING "&&&&&&" 

		SELECT workcentre.desc_text 
		INTO fv_field10 
		FROM workcentre 
		WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND workcentre.work_centre_code = fv_work_centre 

		LET fv_dependency = fv_field1 clipped," -> ",fv_field7 clipped 
		CALL working("Dependency",fv_dependency) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
		fv_field5,fv_field6,fv_field7,fv_field8, 
		fv_field9,fv_field10,fv_field11,fv_which, 
		fp_parameter.*) 

		LET fv_old_centre = fv_work_centre 
		LET mv_first_line = false 
	END FOREACH 

	IF fv_old_order > 0 THEN 
		LET fv_field1 = fv_old_order USING "&&&&&&" 

		SELECT workcentre.desc_text 
		INTO fv_field2 
		FROM workcentre 
		WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND workcentre.work_centre_code = fv_old_centre 

		LET fv_field7 = fv_old_order USING "&&&&&&",".999999" 
		LET fv_field10 = "Planned Completion - S/O#", 
		fv_old_order USING "<<<<<&" 
		LET fv_dependency = fv_field1 clipped," -> ",fv_field7 clipped 

		CALL working("Dependency",fv_dependency) 
		OUTPUT TO REPORT csv_report(fv_field1,fv_field2,fv_field3,fv_field4, 
		fv_field5,fv_field6,fv_field7,fv_field8, 
		fv_field9,fv_field10,fv_field11, 
		fv_which,fp_parameter.*) 

		LET mv_first_line = false 
		LET fv_old_order = fv_shop_order 
		LET fv_old_centre = fv_work_centre 
	END IF 
	FINISH REPORT csv_report 
END FUNCTION 

#-------------------------------------------------------------------------#
#  REPORT TO produce a CSV file                                           #
#-------------------------------------------------------------------------#

REPORT csv_report(rp_field1,rp_field2,rp_field3,rp_field4,rp_field5,rp_field6, 
	rp_field7,rp_field8,rp_field9,rp_field10,rp_field11,rp_which, 
	rp_parameter) 

	DEFINE 
	rp_which CHAR(1), 
	rp_field1 CHAR(15), 
	rp_field2 CHAR(30), 
	rp_field3 CHAR(7), 
	rp_field4 DATE, 
	rp_field5 CHAR(8), 
	rp_field6 FLOAT, 
	rp_field7 CHAR(15), 
	rp_field8 CHAR(10), 
	rp_field9 CHAR(10), 
	rp_field10 CHAR(30), 
	rp_field11 CHAR(9), 
	rp_parameter RECORD LIKE mnparms.*, 
	rv_year SMALLINT, 
	rv_month SMALLINT, 
	rv_day SMALLINT 

	OUTPUT 
	PAGE length 1 
	top margin 0 
	left margin 0 
	bottom margin 0 
	right margin 250 

	FORMAT 
		ON EVERY ROW 
			IF mv_first_line THEN 
				PRINT "-105,44" 
				IF rp_which="A" THEN 
					PRINT "-110,3" 
					PRINT "-120,\"WBS\",\"TASKNAME\",\"RSRCNAME\"" 
					PRINT "-130,1,1,1" 
				ELSE 
					IF rp_which="D" THEN 
						PRINT "-110,4" 
						PRINT 
						"-120,\"FROMWBS\",\"FROMNAME\",\"TOWBS\", \"TONAME\"" 
						PRINT "-130,1,1,1,1" 
					ELSE 
						IF rp_which="R" THEN 
							PRINT "-110,2" 
							PRINT "-120,\"RSRCNAME\",\"UNITOFMEASURE\"" 
							PRINT "-130,1,1" 
						ELSE 
							IF rp_which="T" THEN 
								CASE 
									WHEN rp_parameter.plan_ver_num=4 
										PRINT "-110,7" 
										PRINT "-120,\"WBS\",\"TASKNAME\",", 
										"\"TASKTYPE\",\"FIXEDSTART\",", 
										"\"DURMETHOD\",\"EFFORTHOUR\",", 
										"\"PARENTWBS\"" 
										PRINT "-130,1,1,6,9,6,2,1" 
									WHEN rp_parameter.plan_ver_num=5 
										PRINT "-110,8" 
										PRINT "-120,\"WBS\",\"TASKNAME\",", 
										"\"TASKTYPE\",\"STARTDATE\",", 
										"\"STARTRESTR\",\"DURMETHOD\",", 
										"\"EFFORTHOUR\",\"PARENTWBS\"" 
										PRINT "-130,1,1,6,9,6,6,2,1" 
								END CASE 
							ELSE 
								PRINT 
								PRINT 
								PRINT 
							END IF 
						END IF 
					END IF 
				END IF 
			END IF 
			PRINT "-900,"; 
			IF rp_which="A" THEN 
				PRINT "\"",rp_field1 clipped,"\",", 
				"\"",rp_field2 clipped,"\",", 
				"\"",rp_field8 clipped,"\"" 
			ELSE 
				IF rp_which="D" THEN 
					PRINT "\"",rp_field1 clipped,"\",", 
					"\"",rp_field2 clipped,"\",", 
					"\"",rp_field7 clipped,"\",", 
					"\"",rp_field10 clipped,"\"" 
				ELSE 
					IF rp_which="R" THEN 
						PRINT "\"",rp_field8 clipped,"\",", 
						"\"",rp_field9 clipped,"\"" 
					ELSE 
						IF rp_which="T" THEN 
							LET rv_year=year(rp_field4) 
							LET rv_month=month(rp_field4) 
							LET rv_day=day(rp_field4) 
							PRINT "\"",rp_field1 clipped,"\",", 
							"\"",rp_field2 clipped,"\",", 
							"\"",rp_field3 clipped,"\","; 
							IF rp_field4 IS NULL THEN 
								PRINT ",,,,,"; 
							ELSE 
								PRINT rv_year USING "&&&&",",", 
								rv_month USING "&&",",", 
								rv_day USING "&&",",","00,00,"; 
							END IF 
							IF rp_parameter.plan_ver_num=5 THEN 
								IF rp_field11 IS NULL THEN 
									PRINT "\" \","; 
								ELSE 
									PRINT "\"",rp_field11 clipped,"\","; 
								END IF 
							END IF 
							PRINT "\"",rp_field5 clipped,"\","; 
							IF rp_field6 IS NULL THEN 
								PRINT ","; 
							ELSE 
								PRINT rp_field6 USING "<<<<<<<<<<&.&&",","; 
							END IF 
							PRINT "\"",rp_field7 clipped,"\"" 
						END IF 
					END IF 
				END IF 
			END IF 
END REPORT 

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

			LET msgresp = kandoomsg("M",1505,"") 		# MESSAGE "esc TO accept del TO EXIT"

			LET fv_job_filename = TRAN_TYPE_JOB_JOB 

			INPUT fv_job_filename WITHOUT DEFAULTS 
			FROM job_filename 

				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

			END INPUT 

			IF (int_flag 
			OR quit_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET fv_input_ok = false 
				LET msgresp = kandoomsg("M",9678,"") 	# ERROR "Export Aborted"
			ELSE 
				LET gl_job_filename=fp_parameter.file_dir_text clipped,"/", 
				fv_job_filename clipped 
			END IF 
			CLOSE WINDOW w1_filenames 

		WHEN fp_parameter.plan_type_ind = "T" 
			OPEN WINDOW w0_filenames with FORM "M145" 
			CALL  windecoration_m("M145") -- albo kd-762 

			LET msgresp = kandoomsg("M",1505,"") 
			# MESSAGE "esc TO accept del TO EXIT"

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
				LET msgresp = kandoomsg("M",9678,"") 
				# ERROR "Export Aborted"
			ELSE 
				LET gl_tsk_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_tsk_filename clipped 
				LET gl_ass_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_ass_filename clipped 
				LET gl_res_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_res_filename clipped 
				LET gl_dep_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_dep_filename clipped 
				LET gl_job_filename = fp_parameter.file_dir_text clipped,"/", 
				fv_job_filename clipped 
			END IF 
			CLOSE WINDOW w0_filenames 
	END CASE 
	RETURN fv_input_ok 
END FUNCTION 

#-------------------------------------------------------------------------#
# FUNCTION TO do something on the SCREEN TO show that a program IS working#
#-------------------------------------------------------------------------#

FUNCTION working(fp_text,fp_value) 
	DEFINE 
	fp_text CHAR(20), 
	fp_value CHAR(30) 

	DISPLAY fp_text clipped,": ",fp_value clipped,"" at 2,2 
	attribute(normal,white) 
END FUNCTION 

#-------------------------------------------------------------------------#

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
				LET msgresp = kandoomsg("M",9530,"") 	# ERROR "There are no more rows in this direction"
				EXIT INPUT 
			BEFORE ROW 
				LET fv_curr_row = arr_curr() 
				DISPLAY fa_unix[fv_curr_row].unix_name 	TO unix_array[fv_curr_row].unix_name 			attribute(white,reverse) 
			AFTER ROW 
				LET fv_curr_row = arr_curr() 
				DISPLAY fa_unix[fv_curr_row].unix_name 		TO unix_array[fv_curr_row].unix_name 		attribute(white,normal) 
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
				LET fv_command = "mfgexport.aix ",fv_parameters clipped 
				RUN fv_command 
			WHEN fv_curr_row = 2 
				LET fv_command = "mfgexport.sco ",fv_parameters clipped 
				RUN fv_command 
			OTHERWISE 
				LET msgresp = kandoomsg("M",9679,"") 
				# ERROR "This version of UNIX has NOT been supported"
		END CASE 
	END IF 
	CLOSE WINDOW w0_unix_window 
END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION planner(mv_where_part, mv_where_part2) 
	DEFINE 
	fv_select_text CHAR(2000), 
	fv_select_text2 CHAR(2000), 
	mv_where_part CHAR(1000), 
	mv_where_part2 CHAR(1000), 
	fp_parameter RECORD LIKE mnparms.*, 
	pr_mpsdemand RECORD LIKE mpsdemand.*, 
	pr_shopordhead RECORD LIKE shopordhead.*, 
	pr_shoporddetl RECORD LIKE shoporddetl.*, 
	ans CHAR(1) 

	SELECT * 
	INTO fp_parameter.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	LET gl_job_filename = gl_job_filename clipped,".txt" 

	START REPORT job TO gl_job_filename 

	LET fv_select_text = "SELECT shopordhead.*, shoporddetl.* ", 
	"FROM shopordhead,shoporddetl ", 
	"WHERE ",mv_where_part clipped," AND ", 
	"shopordhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND shoporddetl.cmpy_code = shopordhead.cmpy_code ", 
	" AND shoporddetl.shop_order_num = shopordhead.shop_order_num ", 
	" AND shoporddetl.type_ind = 'W' ", 
	" AND shopordhead.order_type_ind matches '[SO]' ", 
	"ORDER BY shoporddetl.shop_order_num,shoporddetl.sequence_num" 

	PREPARE statement5 FROM fv_select_text 
	DECLARE c1 CURSOR FOR statement5 

	FOREACH c1 INTO pr_shopordhead.*,pr_shoporddetl.* 
		IF (pr_shoporddetl.required_qty - (pr_shoporddetl.receipted_qty 
		+ pr_shoporddetl.rejected_qty)) > 0 THEN 
			CALL working(pr_shoporddetl.shop_order_num, 
			pr_shoporddetl.work_centre_code) 
			OUTPUT TO REPORT job( pr_shopordhead.*, 
			pr_shoporddetl.*, 
			fp_parameter.*) 
		ELSE 
			CONTINUE FOREACH 
		END IF 

	END FOREACH 

	LET fv_select_text2 = 
	"SELECT mpsdemand.* ", 
	"FROM mpsdemand ", 
	"WHERE ",mv_where_part2 clipped 

	PREPARE statement6 FROM fv_select_text2 
	DECLARE c2 CURSOR FOR statement6 

	FOREACH c2 INTO pr_mpsdemand.* 

		CALL ins_forecast( pr_mpsdemand.*, 
		fp_parameter.*) 

	END FOREACH 

	FINISH REPORT job 

END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

FUNCTION ins_forecast(fr_mpsdemand, fp_parameter) 

	DEFINE 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_runner CHAR(105), 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_desc_text LIKE product.desc_text, 
	fv_num_hrs FLOAT, 
	fv_op_hrs SMALLINT, 
	fv_time_fld CHAR(5), 
	fv_num_days SMALLINT, 
	fv_oper_time INTERVAL hour TO hour, 
	fv_order_num LIKE shopordhead.shop_order_num, 
	fv_order_qty LIKE shopordhead.order_qty, 
	fv_start_date LIKE shopordhead.start_date, 
	fv_end_date LIKE shopordhead.end_date, 
	fv_old_date LIKE shopordhead.end_date, 
	fr_bor RECORD LIKE bor.*, 
	fp_parameter RECORD LIKE mnparms.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_mpsdemand RECORD LIKE mpsdemand.*, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.* 

	LET fr_shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET fr_shopordhead.suffix_num = 0 
	LET fr_shopordhead.order_type_ind = "O" 
	LET fr_shopordhead.status_ind = "H" 
	LET fr_shopordhead.receipted_qty = 0 
	LET fr_shopordhead.rejected_qty = 0 
	LET fr_shopordhead.shop_order_num = fr_mpsdemand.reference_num 
	LET fr_shopordhead.cust_code = fr_mpsdemand.plan_code 
	LET fr_shopordhead.parent_part_code = fr_mpsdemand.parent_part_code 
	LET fr_shopordhead.part_code = fr_mpsdemand.part_code 
	LET fr_shopordhead.start_date = fr_mpsdemand.start_date 
	LET fr_shopordhead.end_date = fr_mpsdemand.due_date 
	LET fr_shopordhead.order_qty = fr_mpsdemand.required_qty 
	LET fr_shopordhead.last_change_date = today 
	LET fr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
	LET fr_shopordhead.last_program_text = "M74" 

	LET fv_parent_part_code = fr_shopordhead.part_code 
	LET fv_order_num = fr_shopordhead.shop_order_num 
	LET fv_order_qty = fr_shopordhead.order_qty 
	LET fv_start_date = fr_shopordhead.start_date 
	LET fv_end_date = fr_shopordhead.end_date 
	LET fv_old_date = fv_end_date 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	AND type_ind = "W" 
	ORDER BY sequence_num 

	LET fv_cnt = 0 

	FOREACH c_child INTO fr_bor.* 
		LET fv_cnt = fv_cnt + 1 
		LET fr_shoporddetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET fr_shoporddetl.shop_order_num = fv_order_num 
		LET fr_shoporddetl.suffix_num = 0 
		LET fr_shoporddetl.parent_part_code = fv_parent_part_code 
		LET fr_shoporddetl.sequence_num = fr_bor.sequence_num 
		LET fr_shoporddetl.type_ind = fr_bor.type_ind 
		LET fr_shoporddetl.part_code = fr_bor.part_code 
		LET fr_shoporddetl.desc_text = fr_bor.desc_text 
		LET fr_shoporddetl.required_qty = fr_bor.required_qty 
		LET fr_shoporddetl.start_date = fv_start_date 
		LET fr_shoporddetl.end_date = fv_end_date 
		LET fr_shoporddetl.work_centre_code = fr_bor.work_centre_code 
		LET fr_shoporddetl.oper_factor_amt = fr_bor.oper_factor_amt 
		LET fr_shoporddetl.overlap_per = fr_bor.overlap_per 
		LET fr_shoporddetl.last_change_date = today 
		LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
		LET fr_shoporddetl.last_program_text = "M81" 

		CASE fr_bor.type_ind 
			WHEN "W" 
				SELECT * 
				INTO fr_workcentre.* 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = fr_bor.work_centre_code 

				LET fr_shoporddetl.work_centre_code = fr_bor.work_centre_code 
				LET fr_shoporddetl.required_qty = fr_bor.oper_factor_amt 
				* fv_order_qty 

				IF fr_workcentre.processing_ind = "Q" THEN 
					LET fv_num_hrs = fr_shoporddetl.required_qty 
					/ fr_workcentre.time_qty 
				ELSE 
					LET fv_num_hrs = fr_shoporddetl.required_qty 
				END IF 
				LET fv_oper_time = fr_workcentre.oper_end_time 
				- fr_workcentre.oper_start_time 
				LET fv_time_fld = fv_oper_time 

				IF fr_workcentre.time_unit_ind = "D" THEN 
					LET fv_num_days = fv_num_hrs 
					LET fv_end_date = fv_start_date + fv_num_days units day 
					LET fr_shoporddetl.end_date = fv_end_date 
					LET fv_start_date = fr_shoporddetl.end_date 
				END IF 

				IF fr_workcentre.time_unit_ind = "H" THEN 
					LET fv_num_days = fv_num_hrs / (fv_time_fld[2,3]) 
					LET fv_end_date = fv_start_date + fv_num_days units day 
					LET fr_shoporddetl.end_date = fv_end_date 
					LET fv_start_date = fr_shoporddetl.end_date 
				END IF 
				IF fr_workcentre.time_unit_ind = "M" THEN 
					LET fv_num_days = (fv_num_hrs / 60) / (fv_time_fld[2,3]) 
					LET fv_end_date = fv_start_date + fv_num_days units day 
					LET fr_shoporddetl.end_date = fv_end_date 
					LET fv_start_date = fr_shoporddetl.end_date 
				END IF 
				IF fr_shoporddetl.work_centre_code IS NOT NULL THEN 
					CALL working(fr_shoporddetl.shop_order_num, 
					fr_shoporddetl.work_centre_code) 
					OUTPUT TO REPORT job( fr_shopordhead.*, 
					fr_shoporddetl.*, 
					fp_parameter.*) 
				END IF 

		END CASE 

	END FOREACH 

	IF fv_old_date > fv_end_date THEN 
		LET fv_end_date = fv_old_date 
	END IF 

END FUNCTION 

#-------------------------------------------------------------------------#

#-------------------------------------------------------------------------#

REPORT job(rr_shopordhead,rr_shoporddetl,fp_parameter) 
	DEFINE 
	fv_work_desc LIKE workcentre.desc_text, 
	fv_time_qty LIKE workcentre.time_qty, 
	fv_time_unit LIKE workcentre.time_unit_ind, 
	fv_processing LIKE workcentre.processing_ind, 
	fv_op_start LIKE workcentre.oper_start_time, 
	fv_op_end LIKE workcentre.oper_end_time, 
	fv_op_hrs INTERVAL hour TO hour, 
	fv_op_hr CHAR(8), 
	fv_num_hrs FLOAT, 
	fv_start SMALLINT, 
	fv_end SMALLINT, 
	fv_cnt SMALLINT, 
	fv_select_text CHAR(2000), 
	fp_parameter RECORD LIKE mnparms.*, 
	rr_shopordhead RECORD LIKE shopordhead.*, 
	rr_shoporddetl RECORD LIKE shoporddetl.*, 
	rr_product RECORD LIKE product.*, 
	rr_customer RECORD LIKE customer.*, 
	rr_sales_code LIKE orderhead.sales_code 

	OUTPUT 
	left margin 0 
	bottom margin 0 
	top margin 0 
	PAGE length 1 

	FORMAT 

		BEFORE GROUP OF rr_shopordhead.shop_order_num 
			IF rr_shopordhead.sales_order_num IS NOT NULL THEN 
				SELECT sales_code 
				INTO rr_sales_code 
				FROM orderhead 
				WHERE rr_shopordhead.cmpy_code = cmpy_code 
				AND rr_shopordhead.sales_order_num = order_num 
			ELSE 
				LET rr_sales_code = "" 
			END IF 

			IF rr_shopordhead.cust_code IS NOT NULL THEN 
				SELECT * 
				INTO rr_customer.* 
				FROM customer 
				WHERE rr_shopordhead.cmpy_code = cmpy_code 
				AND rr_shopordhead.cust_code = cust_code 
			ELSE 
				LET rr_customer.name_text = "" 
			END IF 

			IF status <> 0 THEN 
				LET rr_customer.name_text = "MPS" 
			END IF 

			LET rr_shoporddetl.required_qty = rr_shoporddetl.required_qty - 
			(rr_shoporddetl.receipted_qty + rr_shoporddetl.rejected_qty) 

			IF rr_shopordhead.order_qty > 0 THEN 
				LET fv_op_hr = fp_parameter.oper_end_time 
				LET fv_end = 0 
				LET fv_end = fv_end + ((fv_op_hr[1,2]) * 10) 
				LET fv_end = fv_end + ((fv_op_hr[4,5]) / 6) 

				PRINT 
				rr_shopordhead.shop_order_num USING "<<<<<<<<<", 
				rr_shopordhead.suffix_num USING "<<<",",", 
				rr_sales_code clipped,",", 
				rr_shopordhead.cust_code clipped,",", 
				rr_customer.name_text clipped,",", 
				",", 
				rr_shopordhead.part_code clipped,",", 
				",", 
				",", 
				",", 
				rr_shopordhead.order_qty USING "<<<<<<<<<",",", 
				",", 
				",", 
				",", 
				rr_shopordhead.end_date USING "dd/mm/yy",",", 
				fv_end USING "<<<" 

				SELECT * 
				INTO rr_product.* 
				FROM product 
				WHERE cmpy_code = rr_shopordhead.cmpy_code 
				AND part_code = rr_shopordhead.part_code 

				PRINT 
				".", 
				rr_shopordhead.part_code clipped,",", 
				rr_product.desc_text clipped,",", 
				",", 
				",", 
				rr_shopordhead.order_qty USING "<<<<<<<<<", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				",", 
				"," 
			END IF 

		ON EVERY ROW 
			IF rr_shoporddetl.required_qty > 0 
			AND rr_shoporddetl.type_ind = "W" THEN 
				SELECT workcentre.desc_text, 
				workcentre.time_qty, workcentre.processing_ind, 
				workcentre.time_unit_ind, 
				workcentre.oper_start_time, 
				workcentre.oper_end_time 
				INTO fv_work_desc, fv_time_qty, fv_processing, fv_time_unit, 
				fv_op_start, fv_op_end 
				FROM workcentre 
				WHERE workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND workcentre.work_centre_code = rr_shoporddetl.work_centre_code 

				LET fv_op_hr = fv_op_end 
				LET fv_end = 0 
				LET fv_end = fv_end + ((fv_op_hr[1,2]) * 10) 
				LET fv_end = fv_end + ((fv_op_hr[4,5]) / 6) 

				LET fv_op_hr = fv_op_start 
				LET fv_start = 0 
				LET fv_start = fv_start + ((fv_op_hr[1,2]) * 10) 
				LET fv_start = fv_start + ((fv_op_hr[4,5]) / 6) 

				LET fv_op_hrs = fv_op_end - fv_op_start 
				LET fv_op_hr = fv_op_hrs 

				IF rr_shoporddetl.required_qty IS NULL THEN 
					LET rr_shoporddetl.required_qty = rr_shopordhead.order_qty 
				END IF 
				IF rr_shoporddetl.required_qty IS NULL THEN 
					LET rr_shoporddetl.required_qty = 0 
				END IF 
				IF rr_shoporddetl.receipted_qty IS NULL THEN 
					LET rr_shoporddetl.receipted_qty = 0 
				END IF 
				IF rr_shoporddetl.rejected_qty IS NULL THEN 
					LET rr_shoporddetl.rejected_qty = 0 
				END IF 

				IF fv_processing = "Q" THEN 
					LET fv_num_hrs = (rr_shoporddetl.required_qty 
					* rr_shoporddetl.oper_factor_amt) 
					/ fv_time_qty 
				ELSE 
					LET fv_num_hrs = (rr_shoporddetl.required_qty 
					* rr_shoporddetl.oper_factor_amt) 
					* fv_time_qty 
				END IF 

				CASE 
					WHEN fv_time_unit = "M" 
						LET fv_num_hrs = fv_num_hrs / 6 
					WHEN fv_time_unit = "H" 
						LET fv_num_hrs = fv_num_hrs * 10 
					WHEN fv_time_unit = "D" 
						LET fv_num_hrs = fv_num_hrs * (fv_op_hr[1,2]) * 10 
				END CASE 

				IF fv_num_hrs > 0 
				AND fv_num_hrs < 1 THEN 
					LET fv_num_hrs = 1 
				END IF 

				IF rr_shoporddetl.required_qty > 0 
				AND fv_num_hrs > 0 THEN 
					PRINT 
					"..", 
					rr_shoporddetl.work_centre_code clipped, 
					",,,,,", 
					fv_num_hrs USING "<<<<<", 
					",,,", 
					rr_shoporddetl.overlap_per USING "<<<<<",",", 
					rr_shoporddetl.required_qty USING "<<<<<<<<<", 
					",,0,N,N,N,N,N,", 
					rr_shoporddetl.end_date USING "dd/mm/yy",",", 
					fv_end USING "<<<", 
					",N,", 
					rr_shoporddetl.start_date USING "dd/mm/yy",",", 
					fv_start USING "<<<", 
					",Y,", 
					rr_shoporddetl.end_date USING "dd/mm/yy",",", 
					fv_end USING "<<<",",", 
					rr_shoporddetl.sequence_num USING "<<<<<<<<<", 
					",,," 
				END IF 
			END IF 
END REPORT 
