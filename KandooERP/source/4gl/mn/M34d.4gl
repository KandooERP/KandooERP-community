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
# Purpose - Shop Order Maintenance - Cost details entry SCREEN &
#                                    Work Centre details entry SCREEN
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M34.4gl" 


FUNCTION cost_input() 

	DEFINE fv_ref_code LIKE userref.ref_code, 
	dummy CHAR(1) 

	OPEN WINDOW w1_m141 with FORM "M141" 
	CALL  windecoration_m("M141") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	DISPLAY BY NAME pr_shoporddetl.act_act_cost_amt, 
	pr_shoporddetl.act_price_amt 

	INPUT BY NAME pr_shoporddetl.desc_text, 
	pr_shoporddetl.std_est_cost_amt, 
	pr_shoporddetl.std_price_amt, 
	pr_shoporddetl.cost_type_ind, 
	pr_shoporddetl.user1_text, 
	pr_shoporddetl.user2_text, 
	pr_shoporddetl.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.desc_text) 
				RETURNING pr_shoporddetl.desc_text 
				DISPLAY BY NAME pr_shoporddetl.desc_text 


		ON KEY (control-b) 
			CASE 
				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 
			END CASE 

		AFTER FIELD desc_text 
			IF pr_shoporddetl.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD std_est_cost_amt 
			IF pr_shoporddetl.std_est_cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9581, "") 
				# ERROR "Cost amount must be entered"
				NEXT FIELD std_est_cost_amt 
			END IF 

			IF pr_shoporddetl.std_est_cost_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9582, "") 
				# ERROR "Cost amount must be greater than zero"
				NEXT FIELD std_est_cost_amt 
			END IF 

		AFTER FIELD std_price_amt 
			IF pr_shoporddetl.std_price_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9592, "") 
				# ERROR "Price amount must be greater than zero"
				NEXT FIELD std_price_amt 
			END IF 

		AFTER FIELD cost_type_ind 
			IF pr_shoporddetl.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9615, "") 
				# ERROR "Cost type must be entered"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_shoporddetl.cost_type_ind NOT matches "[FV]" THEN 
				LET msgresp = kandoomsg("M", 9616, "") 
				# ERROR "Invalid cost type"
				NEXT FIELD cost_type_ind 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_shoporddetl.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref1_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "1" 
					AND ref_code = pr_shoporddetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_mnparms.ref2_ind NOT matches "[1234]" 
			OR pr_mnparms.ref2_ind IS NULL THEN 
				NEXT FIELD user3_text 
			END IF 

		AFTER FIELD user2_text 
			IF pr_shoporddetl.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref2_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "2" 
					AND ref_code = pr_shoporddetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user3_text 
			IF pr_mnparms.ref3_ind NOT matches "[1234]" 
			OR pr_mnparms.ref3_ind IS NULL THEN 
				NEXT FIELD dummy 
			END IF 

		AFTER FIELD user3_text 
			IF pr_shoporddetl.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user3_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref3_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "3" 
					AND ref_code = pr_shoporddetl.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_shoporddetl.std_est_cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9581, "") 
				# ERROR "Cost amount must be entered"
				NEXT FIELD std_est_cost_amt 
			END IF 

			IF pr_shoporddetl.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9615, "") 
				# ERROR "Cost type must be entered"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_shoporddetl.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_shoporddetl.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_shoporddetl.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 

	END INPUT 

	CLOSE WINDOW w1_m141 

END FUNCTION 



FUNCTION workcentre_input() 

	DEFINE fv_ref_code LIKE userref.ref_code, 
	fv_work_centre_code LIKE shoporddetl.work_centre_code, 
	fv_wc_code LIKE shoporddetl.work_centre_code, 
	fv_variable_cost LIKE workctrrate.rate_amt, 
	fv_fixed_cost LIKE workctrrate.rate_amt, 
	fv_cost_markup_per LIKE workcentre.cost_markup_per, 
	dummy CHAR(1), 
	fr_workcentre RECORD LIKE workcentre.* 

	OPEN WINDOW w1_m142 with FORM "M142" 
	CALL  windecoration_m("M142") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	DISPLAY BY NAME pr_shoporddetl.act_act_cost_amt, 
	pr_shoporddetl.act_price_amt, 
	pr_shoporddetl.start_date, 
	pr_shoporddetl.start_time, 
	pr_shoporddetl.end_date, 
	pr_shoporddetl.end_time, 
	pr_shoporddetl.actual_start_date, 
	pr_shoporddetl.actual_start_time, 
	pr_shoporddetl.actual_end_date, 
	pr_shoporddetl.actual_end_time 

	INPUT BY NAME pr_shoporddetl.work_centre_code, 
	pr_shoporddetl.desc_text, 
	pr_shoporddetl.oper_factor_amt, 
	pr_shoporddetl.overlap_per, 
	pr_shoporddetl.user1_text, 
	pr_shoporddetl.user2_text, 
	pr_shoporddetl.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			IF pr_shoporddetl.work_centre_code IS NOT NULL THEN 
				SELECT * 
				INTO fr_workcentre.* 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_shoporddetl.work_centre_code 

				CALL display_wcrates(fr_workcentre.*) 
				RETURNING fv_variable_cost, fv_fixed_cost, 
				fv_cost_markup_per 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(work_centre_code) 
					CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

					IF fv_wc_code IS NOT NULL THEN 
						LET pr_shoporddetl.work_centre_code = fv_wc_code 
						DISPLAY BY NAME pr_shoporddetl.work_centre_code 
					END IF 

				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 

			END CASE 

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.desc_text) 
				RETURNING pr_shoporddetl.desc_text 
				DISPLAY BY NAME pr_shoporddetl.desc_text 

		BEFORE FIELD work_centre_code 
			LET fv_work_centre_code = pr_shoporddetl.work_centre_code 

		AFTER FIELD work_centre_code 
			IF pr_shoporddetl.work_centre_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9598, "") 
				# ERROR "Work centre code must be entered"
				NEXT FIELD work_centre_code 
			END IF 

			SELECT * 
			INTO fr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_shoporddetl.work_centre_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9527, "") 
				# ERROR "This work centre does NOT exist - Try Window"
				NEXT FIELD work_centre_code 
			END IF 

			IF pr_shoporddetl.work_centre_code != fv_work_centre_code 
			OR fv_work_centre_code IS NULL THEN 
				LET pr_shoporddetl.desc_text = fr_workcentre.desc_text 
				DISPLAY BY NAME pr_shoporddetl.desc_text 

				CALL display_wcrates(fr_workcentre.*) 
				RETURNING fv_variable_cost, fv_fixed_cost, 
				fv_cost_markup_per 
			END IF 

		AFTER FIELD desc_text 
			IF pr_shoporddetl.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD oper_factor_amt 
			IF pr_shoporddetl.oper_factor_amt IS NULL THEN 
				LET pr_shoporddetl.oper_factor_amt = 1 
				DISPLAY BY NAME pr_shoporddetl.oper_factor_amt 
			END IF 

		AFTER FIELD oper_factor_amt 
			IF pr_shoporddetl.oper_factor_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9594, "") 
				# ERROR "Operation factor must be entered"
				NEXT FIELD oper_factor_amt 
			END IF 

			IF pr_shoporddetl.oper_factor_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9595, "") 
				# ERROR "Operation factor must be greater than 0"
				NEXT FIELD oper_factor_amt 
			END IF 

		BEFORE FIELD overlap_per 
			IF pr_shoporddetl.overlap_per IS NULL THEN 
				LET pr_shoporddetl.overlap_per = 100 
				DISPLAY BY NAME pr_shoporddetl.overlap_per 
			END IF 

		AFTER FIELD overlap_per 
			IF pr_shoporddetl.overlap_per IS NULL THEN 
				LET msgresp = kandoomsg("M", 9596, "") 
				# ERROR "Overlap percentage must be entered"
				NEXT FIELD overlap_per 
			END IF 

			IF pr_shoporddetl.overlap_per < 0 
			OR pr_shoporddetl.overlap_per > 100 THEN 
				LET msgresp = kandoomsg("M", 9761, "") 
				# ERROR "Overlap percentage must be between 0 AND 100"
				NEXT FIELD overlap_per 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_shoporddetl.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref1_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "1" 
					AND ref_code = pr_shoporddetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_mnparms.ref2_ind NOT matches "[1234]" 
			OR pr_mnparms.ref2_ind IS NULL THEN 
				NEXT FIELD user3_text 
			END IF 

		AFTER FIELD user2_text 
			IF pr_shoporddetl.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref2_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "2" 
					AND ref_code = pr_shoporddetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user3_text 
			IF pr_mnparms.ref3_ind NOT matches "[1234]" 
			OR pr_mnparms.ref3_ind IS NULL THEN 
				NEXT FIELD dummy 
			END IF 

		AFTER FIELD user3_text 
			IF pr_shoporddetl.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user3_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref3_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "3" 
					AND ref_code = pr_shoporddetl.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_shoporddetl.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

			IF pr_shoporddetl.oper_factor_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9594, "") 
				# ERROR "Operation Factor must be entered"
				NEXT FIELD oper_factor_amt 
			END IF 

			IF pr_shoporddetl.overlap_per IS NULL THEN 
				LET msgresp = kandoomsg("M", 9596, "") 
				# ERROR "Overlap Percentage must be entered"
				NEXT FIELD overlap_per 
			END IF 

			IF pr_shoporddetl.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_shoporddetl.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_shoporddetl.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 

			LET pr_shoporddetl.required_qty = pr_shopordhead.order_qty * 
			pr_shoporddetl.oper_factor_amt 

			IF fr_workcentre.processing_ind = "Q" THEN 
				LET pr_shoporddetl.std_act_cost_amt = ((fv_variable_cost / 
				fr_workcentre.time_qty) * pr_shoporddetl.required_qty) + 
				fv_fixed_cost 
			ELSE 
				LET pr_shoporddetl.std_act_cost_amt = (fv_variable_cost * 
				pr_shoporddetl.required_qty) + fv_fixed_cost 
			END IF 

			LET pr_shoporddetl.std_price_amt = pr_shoporddetl.std_act_cost_amt * 
			(1 + (fv_cost_markup_per / 100)) 
	END INPUT 

	CLOSE WINDOW w1_m142 

END FUNCTION 



FUNCTION display_wcrates(fr_workcentre) 

	DEFINE fr_workcentre RECORD LIKE workcentre.*, 
	fv_time_unit CHAR(7), 
	fv_capacity_text CHAR(16), 
	fv_variable_cost LIKE shoporddetl.std_est_cost_amt, 
	fv_variable_price LIKE shoporddetl.std_est_cost_amt, 
	fv_fixed_cost LIKE shoporddetl.std_est_cost_amt, 
	fv_fixed_price LIKE shoporddetl.std_est_cost_amt 


	SELECT sum(rate_amt) 
	INTO fv_variable_cost 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = pr_shoporddetl.work_centre_code 
	AND rate_ind = "V" 

	IF fv_variable_cost IS NULL THEN 
		LET fv_variable_cost = 0 
	END IF 

	SELECT sum(rate_amt) 
	INTO fv_fixed_cost 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = pr_shoporddetl.work_centre_code 
	AND rate_ind = "F" 

	IF fv_fixed_cost IS NULL THEN 
		LET fv_fixed_cost = 0 
	END IF 

	LET fv_variable_price = fv_variable_cost * (1 + 
	(fr_workcentre.cost_markup_per / 100)) 
	LET fv_fixed_price = fv_fixed_cost * (1 + 
	(fr_workcentre.cost_markup_per / 100)) 

	LET pv_text = kandooword("per", "M18") 

	IF fr_workcentre.processing_ind = "Q" THEN 
		CASE fr_workcentre.time_unit_ind 
			WHEN "D" 
				LET fv_time_unit = kandooword("day", "M19") 
			WHEN "H" 
				LET fv_time_unit = kandooword("hour", "M20") 
			WHEN "M" 
				LET fv_time_unit = kandooword("minute", "M21") 
		END CASE 

		LET fv_capacity_text = fr_workcentre.unit_uom_code clipped, " ", 
		pv_text clipped, " ", fv_time_unit 
	ELSE 
		CASE fr_workcentre.time_unit_ind 
			WHEN "D" 
				LET fv_time_unit = kandooword("days", "M22") 
			WHEN "H" 
				LET fv_time_unit = kandooword("hours", "M23") 
			WHEN "M" 
				LET fv_time_unit = kandooword("minutes", "M24") 
		END CASE 

		LET fv_capacity_text = fv_time_unit clipped, " ", pv_text clipped, " ", 
		fr_workcentre.unit_uom_code 
	END IF 

	DISPLAY BY NAME fr_workcentre.time_qty 
	DISPLAY fv_capacity_text, 
	fv_variable_cost, 
	fv_variable_price, 
	fv_fixed_cost, 
	fv_fixed_price 
	TO capacity_text, 
	variable_cost, 
	variable_price, 
	fixed_cost, 
	fixed_price 

	RETURN fv_variable_cost, fv_fixed_cost, fr_workcentre.cost_markup_per 

END FUNCTION 
