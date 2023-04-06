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


# Purpose - Work Centre Add

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 
	DEFINE formname CHAR(15) 
	DEFINE err_continue CHAR(1) 
	DEFINE err_message CHAR(50) 

	DEFINE pr_workcentre RECORD LIKE workcentre.* 
	DEFINE pr_menunames RECORD LIKE menunames.* 
	DEFINE pr_mnparms RECORD LIKE mnparms.* 

END GLOBALS 


MAIN 
	-- DISPLAY "hlhll" -- albo
	#Initial UI Init
	CALL setModuleId("MZ1") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 
		CALL fgl_winmessage("Error - Manufacturing Setup","Manufacturing parameters are NOT SET up","error") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	OPEN WINDOW w1_m115 with FORM "M115" 
	CALL  windecoration_m("M115") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		INITIALIZE pr_workcentre TO NULL 

		IF NOT input_centre() THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW w1_m115 

END MAIN 



FUNCTION input_centre() 

	DEFINE fv_wc_code LIKE workcentre.work_centre_code, 
	fv_dept_code LIKE workcentre.dept_code, 
	fv_uom_code LIKE workcentre.unit_uom_code, 
	fv_desc_text LIKE workcentre.desc_text, 
	fv_cont SMALLINT, 
	fv_text CHAR(12), 
	fv_text1 CHAR(20) 


	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	INPUT BY NAME pr_workcentre.work_centre_code, 
	pr_workcentre.desc_text, 
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

		AFTER FIELD work_centre_code 
			IF pr_workcentre.work_centre_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9598, "") 
				# ERROR "Work centre code must be entered"
				NEXT FIELD work_centre_code 
			END IF 

			SELECT work_centre_code 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_workcentre.work_centre_code 

			IF status != notfound THEN 
				LET msgresp = kandoomsg("M", 9681, "") 
				# ERROR "This work centre already exists in the database"
				NEXT FIELD work_centre_code 
			END IF 

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

		BEFORE FIELD oper_start_time 
			IF pr_workcentre.oper_start_time IS NULL THEN 
				LET pr_workcentre.oper_start_time = pr_mnparms.oper_start_time 
			END IF 

		AFTER FIELD oper_start_time 
			IF pr_workcentre.oper_start_time IS NULL THEN 
				LET msgresp = kandoomsg("M", 9797, "") 
				# ERROR "Operation start time must be entered"
				NEXT FIELD oper_start_time 
			END IF 

		BEFORE FIELD oper_end_time 
			IF pr_workcentre.oper_end_time IS NULL THEN 
				LET pr_workcentre.oper_end_time = pr_mnparms.oper_end_time 
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

			IF pr_workcentre.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

			IF pr_workcentre.dept_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9682,"") 
				# ERROR "Department code must be entered"
				NEXT FIELD dept_code 
			END IF 

			IF pr_workcentre.processing_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9793, "") 
				# ERROR "Processing type must be entered"
				NEXT FIELD processing_ind 
			END IF 

			IF pr_workcentre.time_unit_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9601, "") 
				# ERROR "Unit of time must be entered"
				NEXT FIELD time_unit_ind 
			END IF 

			IF pr_workcentre.time_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9794, "") 
				# ERROR "Time quantity must be entered"
				NEXT FIELD time_qty 
			END IF 

			IF pr_workcentre.unit_uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9547, "") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD unit_uom_code 
			END IF 

			IF pr_workcentre.utilization_rate IS NULL THEN 
				LET msgresp = kandoomsg("M", 9796, "") 
				# ERROR "Utilization factor must be entered"
				NEXT FIELD utilization_rate 
			END IF 

			IF pr_workcentre.efficiency_rate IS NULL THEN 
				LET msgresp = kandoomsg("M", 9802, "") 
				# ERROR "Efficiency factor must be entered"
				NEXT FIELD efficiency_rate 
			END IF 

			IF pr_workcentre.oper_start_time IS NULL THEN 
				LET msgresp = kandoomsg("M", 9797, "") 
				# ERROR "Operation start time must be entered"
				NEXT FIELD oper_start_time 
			END IF 

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

			IF pr_workcentre.cost_markup_per IS NULL THEN 
				LET msgresp = kandoomsg("M", 9800, "") 
				# ERROR "Cost markup percentage must be entered"
				NEXT FIELD cost_markup_per 
			END IF 

			IF pr_workcentre.count_centre_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9799, "") 
				# ERROR "Count centre type must be entered"
				NEXT FIELD count_centre_ind 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF NOT input_rates() THEN 
		RETURN false 
	END IF 

	LET fv_text = kandooword("Work Centre", "M16") 
	LET fv_text1 = kandooword("Added Success", "M31") 
	{
	    OPEN WINDOW w2_cont AT 8,14 with 5 rows, 51 columns     -- albo  KD-762
	        attributes (white, border)
	}
	DISPLAY fv_text clipped, " ", pr_workcentre.work_centre_code clipped, " ", 
	fv_text1 at 4,2 


	CALL kandoomenu("M", 105) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text # add 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # CONTINUE 
			LET fv_cont = true 
			EXIT MENU 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text # EXIT 
			LET fv_cont = false 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			LET int_flag = false 
			LET quit_flag = false 
			LET fv_cont = false 
			EXIT MENU 
	END MENU 

	--    CLOSE WINDOW w2_cont      -- albo  KD-762
	RETURN fv_cont 

END FUNCTION 



FUNCTION input_rates() 

	DEFINE fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 

	fr_workctrrate RECORD LIKE workctrrate.*, 

	fa_workctrrate array[500] OF RECORD 
		desc_text LIKE workctrrate.desc_text, 
		rate_amt LIKE workctrrate.rate_amt, 
		rate_ind LIKE workctrrate.rate_ind, 
		type_desc CHAR(8) 
	END RECORD 


	LET msgresp = kandoomsg("M", 1516, "") 
	#MESSAGE"F1 Insert, F2 Delete, F3 Fwd, F4 Back, ESC TO Accept - DEL TO Exit"

	CALL set_count(0) 

	INPUT ARRAY fa_workctrrate WITHOUT DEFAULTS FROM sr_rate.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 
			LET fv_arr_size = arr_count() 

		BEFORE INSERT 
			LET fv_arr_size = arr_count() 

		AFTER FIELD desc_text 
			IF fa_workctrrate[fv_idx].desc_text IS NULL THEN 
				IF (fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("accept")) 
				OR fv_idx < fv_arr_size 
				OR (fv_idx = fv_arr_size 
				AND fa_workctrrate[fv_idx].rate_amt IS NOT null) THEN 
					LET msgresp = kandoomsg("M", 9591, "") 
					# ERROR "Description must be entered"
					NEXT FIELD desc_text 
				END IF 
			ELSE 
				IF fa_workctrrate[fv_idx].rate_amt IS NULL 
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
			IF fa_workctrrate[fv_idx].rate_amt IS NULL THEN 
				#LET msgresp = kandoomsg("M", 9633, "")
				ERROR "Rate amount must be entered" 
				NEXT FIELD rate_amt 
			END IF 

			IF fa_workctrrate[fv_idx].rate_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9695, "") 
				# ERROR "Rate amount must be greater than zero"
				NEXT FIELD rate_amt 
			END IF 

			IF fa_workctrrate[fv_idx].rate_ind IS NULL 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("accept")) THEN 
				LET msgresp = kandoomsg("M", 9805, "") 
				# ERROR "Rate type must be entered"
				NEXT FIELD rate_ind 
			END IF 

		AFTER FIELD rate_ind 
			IF fa_workctrrate[fv_idx].rate_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9805, "") 
				# ERROR "Rate type must be entered"
				NEXT FIELD rate_ind 
			END IF 

			IF fa_workctrrate[fv_idx].rate_ind NOT matches "[FV]" THEN 
				LET msgresp = kandoomsg("M", 9804, "") 
				# ERROR "Invalid rate type"
				NEXT FIELD rate_ind 
			END IF 

			IF fa_workctrrate[fv_idx].rate_ind = "F" THEN 
				LET fa_workctrrate[fv_idx].type_desc = "Fixed" 
			ELSE 
				LET fa_workctrrate[fv_idx].type_desc = "Variable" 
			END IF 

			DISPLAY fa_workctrrate[fv_idx].type_desc 
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
				### Insert workcentre record
				###

				LET pr_workcentre.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_workcentre.last_change_date = today 
				LET pr_workcentre.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET pr_workcentre.last_program_text = "MZ1" 
				LET err_message = "MZ1 - Insert INTO workcentre failed" 

				INSERT INTO workcentre VALUES (pr_workcentre.*) 

				###
				### Insert workctrrate lines
				###

				LET err_message = "MZ1 - Insert INTO workctrrate failed" 
				LET fr_workctrrate.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET fr_workctrrate.work_centre_code = pr_workcentre.work_centre_code 
				LET fr_workctrrate.last_change_date = today 
				LET fr_workctrrate.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_workctrrate.last_program_text = "MZ1" 
				LET fv_cnt1 = 0 

				FOR fv_cnt = 1 TO fv_arr_size 
					IF fa_workctrrate[fv_cnt].desc_text IS NULL THEN 
						CONTINUE FOR 
					END IF 

					LET fv_cnt1 = fv_cnt1 + 1 
					LET fr_workctrrate.sequence_num = fv_cnt1 
					LET fr_workctrrate.desc_text = fa_workctrrate[fv_cnt].desc_text 
					LET fr_workctrrate.rate_amt = fa_workctrrate[fv_cnt].rate_amt 
					LET fr_workctrrate.rate_ind = fa_workctrrate[fv_cnt].rate_ind 

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
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
