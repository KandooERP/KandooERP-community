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


# Purpose - BOR Add - Cost details entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M14_GLOBALS.4gl" 


FUNCTION cost_input() 

	DEFINE 
	fv_ref_code LIKE userref.ref_code, 
	dummy CHAR(1) 


	OPEN WINDOW w1_m109 with FORM "M109" 
	CALL  windecoration_m("M109") -- albo kd-762 

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

	INPUT BY NAME pr_bor.desc_text, 
	pr_bor.cost_amt, 
	pr_bor.price_amt, 
	pr_bor.cost_type_ind, 
	pr_bor.start_date, 
	pr_bor.end_date, 
	pr_bor.user1_text, 
	pr_bor.user2_text, 
	pr_bor.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_bor.desc_text) 
				RETURNING pr_bor.desc_text 
				DISPLAY BY NAME pr_bor.desc_text 

		ON KEY (control-b) 
			CASE 
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

		AFTER FIELD desc_text 
			IF pr_bor.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M",9591,"") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD cost_amt 
			IF pr_bor.cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M",9581,"") 
				# ERROR "Cost amount must be entered"
				NEXT FIELD cost_amt 
			END IF 

			IF pr_bor.cost_amt <= 0 THEN 
				LET msgresp = kandoomsg("M",9582,"") 
				# ERROR "Cost amount must be greater than zero"
				NEXT FIELD cost_amt 
			END IF 

		AFTER FIELD price_amt 
			IF pr_bor.price_amt <= 0 THEN 
				LET msgresp = kandoomsg("M",9592,"") 
				# ERROR "Price amount must be greater than zero"
				NEXT FIELD price_amt 
			END IF 

		AFTER FIELD cost_type_ind 
			IF pr_bor.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9615,"") 
				# ERROR "Cost type must be entered"
				NEXT FIELD cost_type_ind 
			END IF 

			IF pr_bor.cost_type_ind NOT matches "[FV]" THEN 
				LET msgresp = kandoomsg("M",9616,"") 
				# ERROR "Invalid cost type"
				NEXT FIELD cost_type_ind 
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

			IF pr_bor.cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("M",9581,"") 
				# ERROR "Cost amount must be entered"
				NEXT FIELD cost_amt 
			END IF 

			IF pr_bor.cost_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9615,"") 
				# ERROR "Cost type must be entered"
				NEXT FIELD cost_type_ind 
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
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_bor.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 
	END INPUT 

	CLOSE WINDOW w1_m109 

END FUNCTION 
