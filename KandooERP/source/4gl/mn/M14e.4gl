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

	Source code beautified by beautify.pl on 2020-01-02 17:31:18	$Id: $
}


# Purpose - BOR Add - Work Centre details entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M14_GLOBALS.4gl" 



FUNCTION workcentre_input() 

	DEFINE 
	fv_ref_code LIKE userref.ref_code, 
	fv_work_centre_code LIKE bor.work_centre_code, 
	fv_wc_code LIKE bor.work_centre_code, 
	fv_time_unit CHAR(7), 
	fv_capacity_text CHAR(16), 
	fv_variable_cost LIKE bor.cost_amt, 
	fv_variable_price LIKE bor.cost_amt, 
	fv_fixed_cost LIKE bor.cost_amt, 
	fv_fixed_price LIKE bor.cost_amt, 
	dummy CHAR(1), 
	fr_workcentre RECORD LIKE workcentre.* 

	OPEN WINDOW w1_m110 with FORM "M110" 
	CALL  windecoration_m("M110") -- albo kd-762 

	LET msgresp = kandoomsg("M",1505,"") # MESSAGE "ESC TO Accept - DEL TO Exit"

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	INPUT BY NAME pr_bor.work_centre_code, 
	pr_bor.desc_text, 
	pr_bor.oper_factor_amt, 
	pr_bor.overlap_per, 
	pr_bor.start_date, 
	pr_bor.end_date, 
	pr_bor.user1_text, 
	pr_bor.user2_text, 
	pr_bor.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(work_centre_code) 
					CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

					IF fv_wc_code IS NOT NULL THEN 
						LET pr_bor.work_centre_code = fv_wc_code 
						DISPLAY BY NAME pr_bor.work_centre_code 
					END IF 

				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 
			END CASE 

		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_bor.desc_text) 
				RETURNING pr_bor.desc_text 
				DISPLAY BY NAME pr_bor.desc_text 

		BEFORE FIELD work_centre_code 
			LET fv_work_centre_code = pr_bor.work_centre_code 

		AFTER FIELD work_centre_code 
			IF pr_bor.work_centre_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9598,"") 
				# ERROR "Work Centre code must be entered"
				NEXT FIELD work_centre_code 
			END IF 

			SELECT * 
			INTO fr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_bor.work_centre_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9527,"") 
				# ERROR "This Work Centre does NOT exist - Try Window"
				NEXT FIELD work_centre_code 
			END IF 

			IF pr_bor.work_centre_code != fv_work_centre_code 
			OR fv_work_centre_code IS NULL THEN 
				LET pr_bor.desc_text = fr_workcentre.desc_text 
				DISPLAY BY NAME pr_bor.desc_text 
			END IF 

			SELECT sum(rate_amt) 
			INTO fv_variable_cost 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_bor.work_centre_code 
			AND rate_ind = "V" 

			IF fv_variable_cost IS NULL THEN 
				LET fv_variable_cost = 0 
			END IF 

			SELECT sum(rate_amt) 
			INTO fv_fixed_cost 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = pr_bor.work_centre_code 
			AND rate_ind = "F" 

			IF fv_fixed_cost IS NULL THEN 
				LET fv_fixed_cost = 0 
			END IF 

			LET fv_variable_price = fv_variable_cost * (1 + 
			(fr_workcentre.cost_markup_per / 100)) 
			LET fv_fixed_price = fv_fixed_cost * (1 + 
			(fr_workcentre.cost_markup_per / 100)) 

			CASE fr_workcentre.time_unit_ind 
				WHEN "D" 
					LET fv_time_unit = "day" 
				WHEN "H" 
					LET fv_time_unit = "hour" 
				WHEN "M" 
					LET fv_time_unit = "minute" 
			END CASE 

			IF fr_workcentre.processing_ind = "Q" THEN 
				LET fv_capacity_text = fr_workcentre.unit_uom_code clipped, 
				" per ", fv_time_unit 
			ELSE 
				LET fv_capacity_text = fv_time_unit clipped, "s per ", 
				fr_workcentre.unit_uom_code 
			END IF 

			DISPLAY BY NAME fr_workcentre.time_qty 
			DISPLAY fv_capacity_text TO capacity_text 

			DISPLAY fv_variable_cost, 
			fv_variable_price, 
			fv_fixed_cost, 
			fv_fixed_price 
			TO variable_cost, 
			variable_price, 
			fixed_cost, 
			fixed_price 

		AFTER FIELD desc_text 
			IF pr_bor.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M",9591,"") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD oper_factor_amt 
			IF pr_bor.oper_factor_amt IS NULL THEN 
				LET pr_bor.oper_factor_amt = 1 
				DISPLAY BY NAME pr_bor.oper_factor_amt 
			END IF 

		AFTER FIELD oper_factor_amt 
			IF pr_bor.oper_factor_amt IS NULL THEN 
				LET msgresp = kandoomsg("M",9594,"") 
				# ERROR "Operation factor must be entered"
				NEXT FIELD oper_factor_amt 
			END IF 

			IF pr_bor.oper_factor_amt <= 0 THEN 
				LET msgresp = kandoomsg("M",9595,"") 
				# ERROR "Operation factor must be greater than zero"
				NEXT FIELD oper_factor_amt 
			END IF 

		BEFORE FIELD overlap_per 
			IF pr_bor.overlap_per IS NULL THEN 
				LET pr_bor.overlap_per = 100 
				DISPLAY BY NAME pr_bor.overlap_per 
			END IF 

		AFTER FIELD overlap_per 
			IF pr_bor.overlap_per IS NULL THEN 
				LET msgresp = kandoomsg("M",9596,"") 
				# ERROR "Overlap percentage must be entered"
				NEXT FIELD overlap_per 
			END IF 

			IF pr_bor.overlap_per < 0 
			OR pr_bor.overlap_per > 100 THEN 
				LET msgresp = kandoomsg("M",9761,"") 
				# ERROR "Overlap percentage must be between 0 AND 100"
				NEXT FIELD overlap_per 
			END IF 

		AFTER FIELD end_date 
			IF pr_bor.start_date > pr_bor.end_date THEN 
				LET msgresp = kandoomsg("M",9588,"") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_bor.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
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
					AND ref_code = pr_bor.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
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
			IF pr_bor.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
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
					AND ref_code = pr_bor.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
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
			IF pr_bor.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
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
					AND ref_code = pr_bor.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_bor.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M",9591,"") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

			IF pr_bor.oper_factor_amt IS NULL THEN 
				LET msgresp = kandoomsg("M",9594,"") 
				# ERROR "Operation Factor must be entered"
				NEXT FIELD oper_factor_amt 
			END IF 

			IF pr_bor.overlap_per IS NULL THEN 
				LET msgresp = kandoomsg("M",9596,"") 
				# ERROR "Overlap Percentage must be entered"
				NEXT FIELD overlap_per 
			END IF 

			IF pr_bor.start_date > pr_bor.end_date THEN 
				LET msgresp = kandoomsg("M",9588,"") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

			IF pr_bor.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_bor.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				ERROR "User defined field must be entered" 
				NEXT FIELD user2_text 
			END IF 

			IF pr_bor.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				ERROR "User defined field must be entered" 
				NEXT FIELD user3_text 
			END IF 

	END INPUT 

	CLOSE WINDOW w1_m110 

END FUNCTION 
