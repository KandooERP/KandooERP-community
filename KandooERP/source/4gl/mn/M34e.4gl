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

	Source code beautified by beautify.pl on 2020-01-02 17:31:27	$Id: $
}


# Purpose - Shop Order Maintenance - Set Up details entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M34.4gl" 


FUNCTION setup_input() 

	DEFINE fv_ref_code LIKE userref.ref_code, 
	dummy CHAR(1) 

	OPEN WINDOW w1_m143 with FORM "M143" 
	CALL  windecoration_m("M143") -- albo kd-762 

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

	INPUT BY NAME pr_shoporddetl.desc_text, 
	pr_shoporddetl.required_qty, 
	pr_shoporddetl.uom_code, 
	pr_shoporddetl.std_est_cost_amt, 
	pr_shoporddetl.std_price_amt, 
	pr_shoporddetl.cost_type_ind, 
	pr_shoporddetl.var_amt, 
	pr_shoporddetl.user1_text, 
	pr_shoporddetl.user2_text, 
	pr_shoporddetl.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

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

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.desc_text) 
				RETURNING pr_shoporddetl.desc_text 
				DISPLAY BY NAME pr_shoporddetl.desc_text 

		AFTER FIELD desc_text 
			IF pr_shoporddetl.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD required_qty 
			IF pr_shoporddetl.required_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9599, "") 
				# ERROR "Set up time must be entered"
				NEXT FIELD required_qty 
			END IF 

			IF pr_shoporddetl.required_qty <= 0 THEN 
				LET msgresp = kandoomsg("M", 9600, "") 
				# ERROR "Set up time must be greater than zero"
				NEXT FIELD required_qty 
			END IF 

		AFTER FIELD uom_code 
			IF pr_shoporddetl.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9601, "") 
				# ERROR "Unit of time must be entered"
				NEXT FIELD uom_code 
			END IF 

			IF pr_shoporddetl.uom_code NOT matches "[MHD]" THEN 
				LET msgresp = kandoomsg("M", 9602, "") 
				# ERROR "Invalid unit of time code"
				NEXT FIELD uom_code 
			END IF 

		AFTER FIELD std_est_cost_amt 
			IF pr_shoporddetl.std_est_cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9603, "") 
				# ERROR "Set up cost must be entered"
				NEXT FIELD std_est_cost_amt 
			END IF 

			IF pr_shoporddetl.std_est_cost_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9604, "") 
				# ERROR "Set up cost must be greater than zero"
				NEXT FIELD std_est_cost_amt 
			END IF 

		AFTER FIELD std_price_amt 
			IF pr_shoporddetl.std_price_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9605, "") 
				# ERROR "Set up price must be greater than zero"
				NEXT FIELD std_price_amt 
			END IF 

		AFTER FIELD cost_type_ind 
			IF pr_shoporddetl.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9606, "") 
				# ERROR "Set up type must be entered"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_shoporddetl.cost_type_ind NOT matches "[FMHDQ]" THEN 
				LET msgresp = kandoomsg("M", 9607, "") 
				# ERROR "Invalid SET up type"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_shoporddetl.cost_type_ind = "F" THEN 
				LET pr_shoporddetl.var_amt = NULL 
				DISPLAY BY NAME pr_shoporddetl.var_amt 
			END IF 

		BEFORE FIELD var_amt 
			IF pr_shoporddetl.cost_type_ind = "F" THEN 
				IF fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("right") THEN 
					NEXT FIELD user1_text 
				ELSE 
					NEXT FIELD cost_type_ind 
				END IF 
			END IF 

		AFTER FIELD var_amt 
			IF pr_shoporddetl.var_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9608, "") 
				# ERROR "Per quantity must be entered"
				NEXT FIELD var_amt 
			END IF 

			IF pr_shoporddetl.var_amt <= 0 THEN 
				LET msgresp = kandoomsg("M", 9609, "") 
				# ERROR "Per quantity must be greater than zero"
				NEXT FIELD var_amt 
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

			IF pr_shoporddetl.required_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9599, "") 
				# ERROR "Set up time must be entered"
				NEXT FIELD required_qty 
			END IF 

			IF pr_shoporddetl.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9601, "") 
				# ERROR "Unit of time must be entered"
				NEXT FIELD uom_code 
			END IF 

			IF pr_shoporddetl.std_est_cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9603, "") 
				# ERROR "Set up cost must be entered"
				NEXT FIELD std_est_cost_amt 
			END IF 

			IF pr_shoporddetl.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9606, "") 
				# ERROR "Set up type must be entered"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_shoporddetl.cost_type_ind != "F" 
			AND pr_shoporddetl.var_amt IS NULL THEN 
				LET msgresp = kandoomsg("M", 9608, "") 
				# ERROR "Per quantity must be entered"
				NEXT FIELD var_amt 
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

	CLOSE WINDOW w1_m143 

END FUNCTION 
