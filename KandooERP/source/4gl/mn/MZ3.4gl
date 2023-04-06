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

	Source code beautified by beautify.pl on 2020-01-02 17:31:36	$Id: $
}


# Purpose - Work Centre Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	pa_centre array[500] OF RECORD 
		work_centre_code LIKE workcentre.work_centre_code, 
		desc_text LIKE workcentre.desc_text, 
		processing_ind LIKE workcentre.processing_ind, 
		time_qty LIKE workcentre.time_qty, 
		time_unit_ind LIKE workcentre.time_unit_ind, 
		unit_uom_code LIKE workcentre.unit_uom_code 
	END RECORD, 

	pa_workctrrate array[500] OF RECORD 
		desc_text LIKE workctrrate.desc_text, 
		rate_amt LIKE workctrrate.rate_amt, 
		rate_ind LIKE workctrrate.rate_ind, 
		type_desc CHAR(8) 
	END RECORD, 

	formname CHAR(15), 
	err_continue CHAR(1), 
	err_message CHAR(50), 
	pv_cnt SMALLINT, 
	pr_workcentre RECORD LIKE workcentre.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("MZ3") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL query_centre() 

END MAIN 



FUNCTION query_centre() 

	DEFINE fv_where_part CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT 

	OPEN WINDOW w1_m119 with FORM "M119" 
	CALL  windecoration_m("M119") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		DISPLAY "Maintenance" TO heading_text 

		LET msgresp = kandoomsg("M", 1500, "") 	# MESSAGE " Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_part 
		ON work_centre_code, desc_text, processing_ind, time_qty, 
		time_unit_ind, unit_uom_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET fv_query_text = "SELECT work_centre_code, desc_text, ", 
		"processing_ind, time_qty, time_unit_ind, ", 
		"unit_uom_code ", 
		"FROM workcentre ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", fv_where_part clipped, " ", 
		"ORDER BY work_centre_code" 

		INITIALIZE pa_centre TO NULL 
		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_centre CURSOR FOR sl_stmt1 

		LET fv_idx = 1 

		FOREACH c_centre INTO pa_centre[fv_idx].* 
			LET fv_idx = fv_idx + 1 

			IF fv_idx > 500 THEN 
				LET msgresp = kandoomsg("M", 9697, "") 
				# ERROR "Only the first 500 Work Centres have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET fv_idx = fv_idx - 1 

		IF fv_idx = 0 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		CALL set_count(fv_idx) 

		LET msgresp = kandoomsg("M", 1511, "") 
		# MESSAGE "RETURN on line TO Edit, F3 Fwd, F4 Bwd - DEL Exit"

		DISPLAY ARRAY pa_centre TO sr_centre.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","MZ3","display-arr-centre") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 
				CALL input_centre(pa_centre[fv_idx].work_centre_code) 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 

	CLOSE WINDOW w1_m119 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO INPUT the data FROM the SCREEN AND save it                 #
#-------------------------------------------------------------------------#

FUNCTION input_centre(fv_wc_code) 

	DEFINE fv_wc_code LIKE workcentre.work_centre_code, 
	fv_dept_code LIKE workcentre.dept_code, 
	fv_uom_code LIKE workcentre.unit_uom_code, 
	fv_desc_text LIKE workcentre.desc_text 

	OPEN WINDOW w2_m115 with FORM "M115" 
	CALL  windecoration_m("M115") -- albo kd-762 

	SELECT * 
	INTO pr_workcentre.* 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fv_wc_code 

	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	INPUT BY NAME pr_workcentre.desc_text, 
	pr_workcentre.dept_code, 
	pr_workcentre.alternate_wc_code, 
	pr_workcentre.processing_ind, 
	pr_workcentre.time_unit_ind, 
	pr_workcentre.time_qty, 
	pr_workcentre.unit_uom_code, 
	pr_workcentre.work_station_num, 
	pr_workcentre.utilization_rate, 
	pr_workcentre.efficiency_rate, 
	pr_workcentre.oper_start_time, 
	pr_workcentre.oper_end_time, 
	pr_workcentre.cost_markup_per, 
	pr_workcentre.count_centre_ind 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			DISPLAY BY NAME pr_workcentre.work_centre_code 

			SELECT desc_text 
			INTO fv_desc_text 
			FROM mfgdept 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND dept_code = pr_workcentre.dept_code 

			DISPLAY fv_desc_text TO dept_desc 

			SELECT desc_text 
			INTO fv_desc_text 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_workcentre.alternate_wc_code 

			DISPLAY fv_desc_text TO alternate_desc 

			CALL get_rates() 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(dept_code) 
					CALL show_mfg_dept(glob_rec_kandoouser.cmpy_code) RETURNING fv_dept_code 

					IF fv_dept_code IS NOT NULL THEN 
						LET pr_workcentre.dept_code = fv_dept_code 
						DISPLAY BY NAME pr_workcentre.dept_code 
					END IF 

				WHEN infield(alternate_wc_code) 
					CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

					IF fv_wc_code IS NOT NULL THEN 
						LET pr_workcentre.alternate_wc_code = fv_wc_code 
						DISPLAY BY NAME pr_workcentre.alternate_wc_code 
					END IF 

				WHEN infield(unit_uom_code) 
					CALL show_uom(glob_rec_kandoouser.cmpy_code) RETURNING fv_uom_code 

					IF fv_uom_code IS NOT NULL THEN 
						LET pr_workcentre.unit_uom_code = fv_uom_code 
						DISPLAY BY NAME pr_workcentre.unit_uom_code 
					END IF 
			END CASE 

		AFTER FIELD desc_text 
			IF pr_workcentre.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD dept_code 
			IF pr_workcentre.dept_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9682,"") 
				# ERROR "Department code must be entered"
				NEXT FIELD dept_code 
			END IF 

			SELECT desc_text 
			INTO fv_desc_text 
			FROM mfgdept 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND dept_code = pr_workcentre.dept_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9683,"") 
				# ERROR "This Department code does NOT exist in the db -Try Win"
				NEXT FIELD dept_code 
			END IF 

			DISPLAY fv_desc_text TO dept_desc 

		AFTER FIELD alternate_wc_code 
			IF pr_workcentre.alternate_wc_code IS NOT NULL THEN 
				IF pr_workcentre.alternate_wc_code = 
				pr_workcentre.work_centre_code THEN 
					LET msgresp = kandoomsg("M", 9684, "") 
					#error"Alternate work centre must be different FROM main wc"
					NEXT FIELD alternate_wc_code 
				END IF 

				SELECT desc_text 
				INTO fv_desc_text 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_workcentre.alternate_wc_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9527,"") 
					#ERROR "Work centre does NOT exists in the database-Try Win"
					NEXT FIELD alternate_wc_code 
				ELSE 
					DISPLAY fv_desc_text TO alternate_desc 
				END IF 
			ELSE 
				DISPLAY "" TO alternate_desc 
			END IF 

		AFTER FIELD processing_ind 
			IF pr_workcentre.processing_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9793, "") 
				# ERROR "Processing type must be entered"
				NEXT FIELD processing_ind 
			END IF 

			IF pr_workcentre.processing_ind NOT matches "[QT]" THEN 
				LET msgresp = kandoomsg("M", 9685, "") 
				# ERROR "Processing type must be either 'Q' OR 'T'"
				NEXT FIELD processing_ind 
			END IF 

		AFTER FIELD time_unit_ind 
			IF pr_workcentre.time_unit_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9601, "") 
				# ERROR "Unit of time must be entered"
				NEXT FIELD time_unit_ind 
			END IF 

			IF pr_workcentre.time_unit_ind NOT matches "[DHM]" THEN 
				LET msgresp = kandoomsg("M", 9686, "") 
				# ERROR "Unit of time must be 'D', 'H' OR 'M'"
				NEXT FIELD time_unit_ind 
			END IF 

		AFTER FIELD time_qty 
			IF pr_workcentre.time_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9794, "") 
				# ERROR "Time quantity must be entered"
				NEXT FIELD time_qty 
			END IF 

			IF pr_workcentre.time_qty <= 0 THEN 
				LET msgresp = kandoomsg("M", 9687, "") 
				# ERROR "Time quantity must be greater than zero"
				NEXT FIELD time_qty 
			END IF 

		AFTER FIELD unit_uom_code 
			IF pr_workcentre.unit_uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9547, "") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD unit_uom_code 
			END IF 

			SELECT * 
			FROM uom 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND uom_code = pr_workcentre.unit_uom_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9548, "") 
				# ERROR "Unit of measure code does NOT exist in the db -Try Win"
				NEXT FIELD unit_uom_code 
			END IF 

		AFTER FIELD work_station_num 
			IF pr_workcentre.work_station_num <= 0 THEN 
				LET msgresp = kandoomsg("M", 9795, "") 
				# ERROR "Number of work stations must be greater than zero"
				NEXT FIELD work_station_num 
			END IF 

		BEFORE FIELD utilization_rate 
			IF pr_workcentre.utilization_rate IS NULL THEN 
				LET pr_workcentre.utilization_rate = 1 
				DISPLAY BY NAME pr_workcentre.utilization_rate 
			END IF 

		AFTER FIELD utilization_rate 
			IF pr_workcentre.utilization_rate IS NULL THEN 
				LET msgresp = kandoomsg("M", 9796, "") 
				# ERROR "Utilization factor must be entered"
				NEXT FIELD utilization_rate 
			END IF 

			IF pr_workcentre.utilization_rate <= 0 THEN 
				LET msgresp = kandoomsg("M", 9688, "") 
				# ERROR "Utilization factor must be greater than zero"
				NEXT FIELD utilization_rate 
			END IF 

			IF pr_workcentre.utilization_rate > 1 THEN 
				LET msgresp = kandoomsg("M", 9689, "") 
				# ERROR "Utilization factor cannot be greater than 1.0"
				NEXT FIELD utilization_rate 
			END IF 

		BEFORE FIELD efficiency_rate 
			IF pr_workcentre.efficiency_rate IS NULL THEN 
				LET pr_workcentre.efficiency_rate = 1 
				DISPLAY BY NAME pr_workcentre.efficiency_rate 
			END IF 

		AFTER FIELD efficiency_rate 
			IF pr_workcentre.efficiency_rate IS NULL THEN 
				LET msgresp = kandoomsg("M", 9802, "") 
				# ERROR "Efficiency factor must be entered"
				NEXT FIELD efficiency_rate 
			END IF 

			IF pr_workcentre.efficiency_rate <= 0 THEN 
				LET msgresp = kandoomsg("M", 9801, "") 
				# ERROR "Efficiency factor must be greater than zero"
				NEXT FIELD efficiency_rate 
			END IF 

		AFTER FIELD oper_start_time 
			IF pr_workcentre.oper_start_time IS NULL THEN 
				LET msgresp = kandoomsg("M", 9797, "") 
				# ERROR "Operation start time must be entered"
				NEXT FIELD oper_start_time 
			END IF 

		AFTER FIELD oper_end_time 
			IF pr_workcentre.oper_end_time IS NULL THEN 
				LET msgresp = kandoomsg("M", 9798, "") 
				# ERROR "Operation END time must be entered"
				NEXT FIELD oper_end_time 
			END IF 

			IF pr_workcentre.oper_end_time <= pr_workcentre.oper_start_time THEN 
				LET msgresp = kandoomsg("M", 9692, "") 
				# ERROR "Operation END time must be later than oper start time"
				NEXT FIELD oper_start_time 
			END IF 

		AFTER FIELD cost_markup_per 
			IF pr_workcentre.cost_markup_per IS NULL THEN 
				LET msgresp = kandoomsg("M", 9800, "") 
				# ERROR "Cost markup percentage must be entered"
				NEXT FIELD cost_markup_per 
			END IF 

			IF pr_workcentre.cost_markup_per < 0 THEN 
				LET msgresp = kandoomsg("M", 9690, "") 
				# ERROR "Cost markup percentage cannot be less than zero"
				NEXT FIELD cost_markup_per 
			END IF 

		AFTER FIELD count_centre_ind 
			IF pr_workcentre.count_centre_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9799, "") 
				# ERROR "Count centre type must be entered"
				NEXT FIELD count_centre_ind 
			END IF 

			IF pr_workcentre.count_centre_ind NOT matches "[PTBNO]" THEN 
				LET msgresp = kandoomsg("M", 9691, "") 
				# ERROR "Invalid count centre type"
				NEXT FIELD count_centre_ind 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_workcentre.oper_end_time <= pr_workcentre.oper_start_time THEN 
				LET msgresp = kandoomsg("M", 9692, "") 
				# ERROR "Operation END time must be later than the start time"
				NEXT FIELD oper_start_time 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M", 9562, "") 
		# ERROR "Update Aborted"
	ELSE 
		CALL input_rates() 
	END IF 

	CLOSE WINDOW w2_m115 

END FUNCTION 



FUNCTION input_rates() 

	DEFINE fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 

	fr_workctrrate RECORD LIKE workctrrate.* 


	LET msgresp = kandoomsg("M", 1516, "") 
	#MESSAGE"F1 Insert, F2 Delete, F3 Fwd, F4 Back, ESC TO Accept - DEL TO Exit"

	CALL set_count(pv_cnt) 

	INPUT ARRAY pa_workctrrate WITHOUT DEFAULTS FROM sr_rate.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			LET fv_arr_size = arr_count() 

		BEFORE INSERT 
			LET fv_arr_size = arr_count() 

		AFTER FIELD desc_text 
			IF pa_workctrrate[fv_idx].desc_text IS NULL THEN 
				IF (fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("accept")) 
				OR fv_idx < fv_arr_size 
				OR (fv_idx = fv_arr_size 
				AND pa_workctrrate[fv_idx].rate_amt IS NOT null) THEN 
					LET msgresp = kandoomsg("M", 9591, "") 
					# ERROR "Description must be entered"
					NEXT FIELD desc_text 
				END IF 
			ELSE 
				IF pa_workctrrate[fv_idx].rate_amt IS NULL 
				AND (fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("accept")) THEN 
					#LET msgresp = kandoomsg("M", 9633, "")
					ERROR "Rate amount must be entered" 
					NEXT FIELD rate_amt 
				END IF 
			END IF 

		AFTER FIELD rate_amt 
			IF pa_workctrrate[fv_idx].rate_amt IS NULL THEN 
				#LET msgresp = kandoomsg("M", 9633, "")
				ERROR "Rate amount must be entered" 
				NEXT FIELD rate_amt 
			END IF 

			IF pa_workctrrate[fv_idx].rate_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9695, "") 
				# ERROR "Rate amount must be greater than zero"
				NEXT FIELD rate_amt 
			END IF 

			IF pa_workctrrate[fv_idx].rate_ind IS NULL 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("accept")) THEN 
				LET msgresp = kandoomsg("M", 9805, "") 
				# ERROR "Rate type must be entered"
				NEXT FIELD rate_ind 
			END IF 

		AFTER FIELD rate_ind 
			IF pa_workctrrate[fv_idx].rate_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9805, "") 
				# ERROR "Rate type must be entered"
				NEXT FIELD rate_ind 
			END IF 

			IF pa_workctrrate[fv_idx].rate_ind NOT matches "[FV]" THEN 
				LET msgresp = kandoomsg("M", 9804, "") 
				# ERROR "Invalid rate type"
				NEXT FIELD rate_ind 
			END IF 

			IF pa_workctrrate[fv_idx].rate_ind = "F" THEN 
				LET pa_workctrrate[fv_idx].type_desc = "Fixed" 
			ELSE 
				LET pa_workctrrate[fv_idx].type_desc = "Variable" 
			END IF 

			DISPLAY pa_workctrrate[fv_idx].type_desc 
			TO sr_rate[fv_scrn].rate_desc 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			GOTO bypass 

			LABEL recovery: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 

			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 

				###
				### Update workcentre table
				###

				LET pr_workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_workcentre.last_change_date = today 
				LET pr_workcentre.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET pr_workcentre.last_program_text = "MZ3" 
				LET err_message = "MZ3 - Update of workcentre failed" 

				UPDATE workcentre 
				SET * = pr_workcentre.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_workcentre.work_centre_code 

				###
				### Delete old lines & INSERT new ones INTO workctrrate table
				###

				LET err_message = "MZ3 - DELETE FROM workctrrate failed" 

				DELETE FROM workctrrate 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_workcentre.work_centre_code 

				LET err_message = "MZ3 - Insert INTO workctrrate failed" 
				LET fr_workctrrate.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET fr_workctrrate.work_centre_code = pr_workcentre.work_centre_code 
				LET fr_workctrrate.last_change_date = today 
				LET fr_workctrrate.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_workctrrate.last_program_text = "MZ3" 
				LET fv_cnt1 = 0 

				FOR fv_cnt = 1 TO fv_arr_size 
					IF pa_workctrrate[fv_cnt].desc_text IS NULL THEN 
						CONTINUE FOR 
					END IF 

					LET fv_cnt1 = fv_cnt1 + 1 
					LET fr_workctrrate.sequence_num = fv_cnt1 
					LET fr_workctrrate.desc_text = pa_workctrrate[fv_cnt].desc_text 
					LET fr_workctrrate.rate_amt = pa_workctrrate[fv_cnt].rate_amt 
					LET fr_workctrrate.rate_ind = pa_workctrrate[fv_cnt].rate_ind 

					INSERT INTO workctrrate VALUES (fr_workctrrate.*) 
				END FOR 

				IF fv_cnt1 = 0 THEN 
					ROLLBACK WORK 
					LET msgresp = kandoomsg("M", 9803, "") 
					# ERROR "A rate must be entered"
					NEXT FIELD desc_text 
				END IF 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET msgresp = kandoomsg("M", 9562, "") 
		# ERROR "Update Aborted"
	END IF 

END FUNCTION 

#-------------------------------------------------------------------------#
#  FUNCTION TO get the rates FROM the database                            #
#-------------------------------------------------------------------------#

FUNCTION get_rates() 

	DEFINE fr_workctrrate RECORD LIKE workctrrate.*, 
	fv_cnt SMALLINT 


	INITIALIZE pa_workctrrate TO NULL 

	DECLARE c_wcrate CURSOR FOR 
	SELECT * 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = pr_workcentre.work_centre_code 
	ORDER BY sequence_num 

	LET pv_cnt = 0 

	FOREACH c_wcrate INTO fr_workctrrate.* 
		LET pv_cnt = pv_cnt + 1 
		LET pa_workctrrate[pv_cnt].desc_text = fr_workctrrate.desc_text 
		LET pa_workctrrate[pv_cnt].rate_amt = fr_workctrrate.rate_amt 
		LET pa_workctrrate[pv_cnt].rate_ind = fr_workctrrate.rate_ind 

		IF fr_workctrrate.rate_ind = "F" THEN 
			LET pa_workctrrate[pv_cnt].type_desc = "Fixed" 
		ELSE 
			LET pa_workctrrate[pv_cnt].type_desc = "Variable" 
		END IF 

		IF pv_cnt = 500 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	FOR fv_cnt = 1 TO 4 
		DISPLAY pa_workctrrate[fv_cnt].* TO sr_rate[fv_cnt].* 
	END FOR 

END FUNCTION 
