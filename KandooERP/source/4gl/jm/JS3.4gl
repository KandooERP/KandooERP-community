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

	Source code beautified by beautify.pl on 2020-01-02 19:48:27	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module JS3 - Rate Maintenance Program
#           Purpose - Allow the user TO query,add AND UPDATE hourly rate

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_rate RECORD LIKE rate.*, 
	pr_person RECORD LIKE person.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_job RECORD LIKE job.*, 
	pv_rate_type LIKE rate.rate_type, 
	pv_insert_ok SMALLINT 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("JS3") -- albo 
	CALL ui_init(0) 
	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	OPEN WINDOW j212 with FORM "J212" -- alch kd-747 
	CALL winDecoration_j("J212") -- alch kd-747 
	CALL rate_menu() 
	CLOSE WINDOW j212 
END MAIN 

FUNCTION select_rate() 
	DEFINE 
	where_part CHAR(900), 
	query_text CHAR(990) 
	CLEAR FORM 
	INITIALIZE pr_rate.* TO NULL 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001" Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_part ON 
	rate.rate_type, 
	rate.hourly_rate, 
	rate.expiry_date, 
	rate.person_code, 
	rate.cust_code, 
	rate.job_code, 
	rate.var_code, 
	rate.activity_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JS3","const-rate_type-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD rate_type 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("down") 
			THEN 
				IF pr_rate.rate_type IS NOT NULL THEN 
					IF pr_rate.rate_type NOT matches "[CJVAN]" THEN 
						LET msgresp = kandoomsg("J",9848,"") 
						# "9848 " Rate type selection must be in C,J,V,A,N
						NEXT FIELD rate_type 
					END IF 
				END IF 
			END IF 
		ON KEY (control-b) 
			CASE 
				WHEN infield (person_code) 
					LET pr_rate.person_code = show_person(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_person.name_text 
					FROM person 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					person_code = pr_rate.person_code 
					DISPLAY BY NAME pr_rate.person_code, pr_person.name_text 
					NEXT FIELD cust_code 
				WHEN infield (cust_code) 
					LET pr_rate.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					cust_code = pr_rate.cust_code 
					DISPLAY BY NAME pr_rate.cust_code, pr_customer.name_text 
					NEXT FIELD job_code 
				WHEN infield (job_code) 
					LET pr_rate.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
					SELECT title_text 
					INTO pr_job.title_text 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					job_code = pr_rate.job_code 
					DISPLAY BY NAME pr_rate.job_code, pr_job.title_text 
					NEXT FIELD var_code 
				WHEN infield (var_code) 
					LET pr_rate.var_code = show_jobvars(glob_rec_kandoouser.cmpy_code, pr_rate.job_code) 
					DISPLAY BY NAME pr_rate.var_code 
					NEXT FIELD activity_code 
				WHEN infield (activity_code) 
					LET pr_rate.activity_code = show_activity(glob_rec_kandoouser.cmpy_code,pr_rate.job_code,pr_rate.var_code) 
					DISPLAY BY NAME pr_rate.activity_code 
			END CASE 
		ON KEY (control-w) 
			CALL kandoohelp("") 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN false 
			END IF 
	END CONSTRUCT 

	LET query_text = "SELECT rate.* ", 
	"FROM rate ", 
	"WHERE ", where_part clipped, 
	" AND rate.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" ORDER BY rate_type" 

	PREPARE s_rate FROM query_text 
	DECLARE c_rate SCROLL CURSOR FOR s_rate 
	OPEN c_rate 
	FETCH FIRST c_rate INTO pr_rate.* 
	IF status = notfound THEN 
		RETURN false 
	ELSE 
		CALL display_rate(pr_rate.*) 
		RETURN true 
	END IF 

END FUNCTION 

FUNCTION rate_menu() 
	MENU " Rate Maintenance" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			CALL publish_toolbar("kandoo","JS3","menu-rate_maintenance-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Query" " Enter Selection Criteria FOR Hourly rate " 
			IF select_rate() THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				NEXT option "Next" 
			ELSE 
				LET msgresp=kandoomsg("J",9865,"") 
				#9865 No Hourly rate satisfies selection criteria
				HIDE option "Next" 
				HIDE option "Previous" 
			END IF 

		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected hourly rate" 
			CLEAR FORM 
			FETCH NEXT c_rate INTO pr_rate.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9079,"") 
				#9079" "You have reached the END of the records selected"
			ELSE 
				CALL display_rate(pr_rate.*) 
			END IF 

		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected hourly rate" 
			CLEAR FORM 
			FETCH previous c_rate INTO pr_rate.* 
			IF status = notfound THEN 
				LET msgresp=kandoomsg("I",9080,"") 
				#9080 "You have reached the start of the rates selected"
			ELSE 
				CALL display_rate(pr_rate.*) 
			END IF 

		COMMAND "Add" "Add a new rate RECORD " 
			CLEAR FORM 
			IF get_rate_type() THEN 
				CALL add_rate() 
			ELSE 
				CONTINUE MENU 
			END IF 
		COMMAND "Update" "Update existing rate record" 
			CALL upd_rate() 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 

END FUNCTION 

FUNCTION get_rate_type() 

	DEFINE 
	rate CHAR(1), 
	get_rate_ok SMALLINT 

	CLEAR screen 
	{  -- albo
	OPEN WINDOW getrate AT 5,5
	with 3 rows, 70 columns
	   attribute (border, reverse, MESSAGE line last)
	}
	WHILE true 
		{  -- albo
		        MESSAGE "C - Customer, J - Job, V - Variation, A - Activity, N - Combination "
		        prompt " Enter hourly billing rate type "
		            FOR rate
		}
		LET rate = fgl_winbutton("Enter hourly billing rate type", "C - Customer, J - Job, V - Variation, A - Activity, N - Combination", "", "C|J|V|A|N", "info", 1) -- albo 
		LET rate = upshift(rate) 

		IF int_flag OR quit_flag THEN 
			LET get_rate_ok = false 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		CASE 
			WHEN rate IS NULL 
				LET msgresp = kandoomsg("J",9860,"") 
				# 9860 Rate type selection must be entered!
			WHEN rate NOT matches "[CJVAN]" 
				LET msgresp = kandoomsg("J", 9849, "") 
				# 9849 Invalid rate type, - try window
			OTHERWISE 
				LET get_rate_ok = true 
				LET pv_rate_type = rate 
				EXIT WHILE 
		END CASE 
	END WHILE 
	--    CLOSE WINDOW getrate  -- albo
	IF NOT get_rate_ok THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 

FUNCTION display_rate(pr_rate) 

	DEFINE 
	pr_rate RECORD LIKE rate.* 

	DISPLAY pr_rate.rate_type, 
	pr_rate.hourly_rate, 
	pr_rate.expiry_date, 
	pr_rate.person_code, 
	pr_rate.cust_code, 
	pr_rate.job_code, 
	pr_rate.var_code, 
	pr_rate.activity_code 

	TO 
	rate.rate_type, 
	rate.hourly_rate, 
	rate.expiry_date, 
	rate.person_code, 
	rate.cust_code, 
	rate.job_code, 
	rate.var_code, 
	rate.activity_code 


	IF pr_rate.person_code IS NOT NULL THEN 
		SELECT person.name_text INTO pr_person.name_text 
		FROM person 
		WHERE person.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND person.person_code = pr_rate.person_code 
		DISPLAY pr_person.name_text TO person.name_text 
	END IF 

	IF pr_rate.cust_code IS NOT NULL THEN 
		SELECT customer.name_text INTO pr_customer.name_text 
		FROM customer 
		WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customer.cust_code = pr_rate.cust_code 
		DISPLAY pr_customer.name_text TO customer.name_text 
	END IF 

	IF pr_rate.job_code IS NOT NULL THEN 
		SELECT job.title_text INTO pr_job.title_text 
		FROM job 
		WHERE job.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job.job_code = pr_rate.job_code 
		DISPLAY BY NAME pr_job.title_text 
	END IF 

END FUNCTION 


FUNCTION insert_rate(pr_rate_old, pv_mode) 
	DEFINE 
	pr_rate_old RECORD LIKE rate.*, 
	pv_mode CHAR(1), 
	pv_date_cnt SMALLINT 

	LET pv_insert_ok = true 
	LET int_flag = false 
	LET quit_flag = false 

	INPUT pr_rate.hourly_rate, 
	pr_rate.expiry_date, 
	pr_rate.person_code, 
	pr_rate.cust_code, 
	pr_rate.job_code, 
	pr_rate.var_code, 
	pr_rate.activity_code 
	WITHOUT DEFAULTS 
	FROM 
	rate.hourly_rate, 
	rate.expiry_date, 
	rate.person_code, 
	rate.cust_code, 
	rate.job_code, 
	rate.var_code, 
	rate.activity_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JS3","input-pr_rate-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

			### BEFORE FIELD SECTION
		BEFORE FIELD person_code 
			IF pr_rate.rate_type matches "[CJVA]" THEN 
				NEXT FIELD cust_code 
			END IF 
		BEFORE FIELD cust_code 
			IF pr_rate.rate_type matches "[JVA]" THEN 
				NEXT FIELD job_code 
			END IF 

		BEFORE FIELD var_code 
			IF pr_rate.job_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9861, "") 
				# 9861 Job code must be selected first
				NEXT FIELD job_code 
			END IF 

		BEFORE FIELD activity_code 
			IF pr_rate.job_code IS NULL THEN 
				LET msgresp = kandoomsg("J", 9861, "") 
				# 9861 Job code must be selected first
				NEXT FIELD job_code 
			END IF 

			IF pr_rate.var_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9862, "") 
				# 9862 Variation code must be selected first
				NEXT FIELD var_code 
			END IF 


			### AFTER FIELD SECTION
		AFTER FIELD hourly_rate 
			IF pr_rate.hourly_rate < 0 THEN 
				LET msgresp=kandoomsg("J",9850,"") 
				#9850 Hourly rate can NOT be less than than zero
				NEXT FIELD rate.hourly_rate 
			END IF 
		AFTER FIELD expiry_date 
			IF pr_rate.expiry_date IS NOT NULL THEN 
				IF pr_rate.expiry_date < today THEN 
					LET msgresp=kandoomsg("J",9851,today) 
					# 9851 Expiry date must be AFTER today!
					NEXT FIELD rate.expiry_date 
				END IF 
			END IF 

		AFTER FIELD person_code 
			IF pr_rate.person_code IS NOT NULL THEN 
				SELECT * FROM person 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND person_code = pr_rate.person_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found - Try Window"
					NEXT FIELD person_code 
				END IF 
			END IF 

		AFTER FIELD cust_code 
			IF pr_rate.cust_code IS NOT NULL THEN 
				SELECT * FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_rate.cust_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found - Try Window"
					NEXT FIELD cust_code 
				END IF 
			END IF 
			IF pr_rate.rate_type = "C" THEN 
				IF pr_rate.cust_code IS NULL THEN 
					LET msgresp=kandoomsg("J",9853,"") 
					# 9853 Customer selection must be entered!
					NEXT FIELD rate.cust_code 
				END IF 
				GOTO input_finished 
			END IF 

		AFTER FIELD job_code 
			IF pr_rate.job_code IS NOT NULL THEN 
				SELECT * FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_rate.job_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found - Try Window"
					NEXT FIELD job_code 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 
				IF pr_rate.rate_type matches "[JVA]" THEN 
					IF pr_rate.job_code IS NULL THEN 
						LET msgresp=kandoomsg("J",9854,"") 
						# 9854 Job code selection must be entered!
						NEXT FIELD rate.job_code 
					END IF 
				END IF 
				IF pr_rate.rate_type matches "[VA]" THEN 
					SELECT unique 1 FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_rate.job_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9863,"") 
						#9599 No variations exist FOR this job
						LET pr_rate.var_code = 0 
						DISPLAY BY NAME pr_rate.var_code 
						NEXT FIELD var_code 
					END IF 
				END IF 
				IF pr_rate.rate_type = "A" THEN 
					SELECT unique 1 FROM activity 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_rate.job_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9599,"") 
						#9599 No activities exist FOR this job
						NEXT FIELD job_code 
					END IF 
				END IF 
			END IF 
			IF pr_rate.rate_type = "J" THEN 
				GOTO input_finished 
			END IF 

		AFTER FIELD var_code 

			IF pr_rate.var_code != 0 THEN 
				SELECT * FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_rate.job_code 
				AND var_code = pr_rate.var_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 "Record Not Found; Try Window"
					LET pr_rate.var_code = NULL 
					NEXT FIELD var_code 
				END IF 
			END IF 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pr_rate.rate_type matches "[VA]" THEN 
						IF pr_rate.var_code IS NULL THEN 
							LET msgresp=kandoomsg("J",9855,"") 
							# 9855 Variation code selection must be entered!
							NEXT FIELD rate.var_code 
						END IF 
						IF pr_rate.rate_type = "A" THEN 
							SELECT unique 1 FROM activity 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pr_rate.job_code 
							AND var_code = pr_rate.var_code 
							IF status = notfound THEN 
								LET msgresp = kandoomsg("J",9599,"") 
								#9599 No activities exist FOR this job/variation.
								LET pr_rate.var_code = NULL 
								NEXT FIELD var_code 
							END IF 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
			END CASE 
			IF pr_rate.rate_type = "V" THEN 
				GOTO input_finished 
			END IF 

		AFTER FIELD activity_code 

			IF pr_rate.activity_code IS NOT NULL THEN 
				SELECT * FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_rate.job_code 
				AND var_code = pr_rate.var_code 
				AND activity_code = pr_rate.activity_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9512,"") 
					#9512 "This Activity NOT found FOR Job/Variation",
					LET pr_rate.activity_code = NULL 
					NEXT FIELD activity_code 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF pr_rate.rate_type = "A" THEN 
						IF pr_rate.activity_code IS NULL THEN 
							LET msgresp=kandoomsg("J",9856,"") 
							# 9856 Activity code selection must be entered!
							NEXT FIELD rate.activity_code 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
			END CASE 

		ON KEY (control-b) 
			CASE 
				WHEN int_flag OR quit_flag 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT CASE 

				WHEN infield (person_code) 
					LET pr_rate.person_code = show_person(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_person.name_text 
					FROM person 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					person_code = pr_rate.person_code 
					DISPLAY BY NAME pr_rate.person_code, pr_person.name_text 


				WHEN infield (cust_code) 
					LET pr_rate.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					SELECT name_text 
					INTO pr_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					cust_code = pr_rate.cust_code 
					DISPLAY BY NAME pr_rate.cust_code 
					DISPLAY pr_customer.name_text TO customer.name_text 

				WHEN infield (job_code) 
					LET pr_rate.job_code = 
					show_job(glob_rec_kandoouser.cmpy_code) 
					SELECT title_text 
					INTO pr_job.title_text 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					job_code = pr_rate.job_code 
					DISPLAY BY NAME pr_rate.job_code, pr_job.title_text 


				WHEN infield (var_code) 
					LET pr_rate.var_code = 
					show_jobvars(glob_rec_kandoouser.cmpy_code, pr_rate.job_code) 
					DISPLAY BY NAME pr_rate.var_code 

				WHEN infield (activity_code) 
					LET pr_rate.activity_code = show_activity(glob_rec_kandoouser.cmpy_code,pr_rate.job_code,pr_rate.var_code) 
					DISPLAY BY NAME pr_rate.activity_code 

			END CASE 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		AFTER INPUT 
			LABEL input_finished: 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET pv_insert_ok = false 
				EXIT INPUT 
			END IF 

			IF fgl_lastkey() = fgl_keyval("accept") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("down") THEN 

				WHENEVER ERROR CONTINUE 
				BEGIN WORK 
					IF pv_mode = "A" THEN 
						LET pr_rate.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pr_rate.rate_type = pr_rate_old.rate_type 
						## TO prevent INPUT more than one expiry_date FOR the same combination criteria
						SELECT count(expiry_date) 
						INTO pv_date_cnt 
						FROM rate 
						WHERE cmpy_code = pr_rate.cmpy_code 
						AND rate_type = pr_rate.rate_type 
						AND (person_code = pr_rate.person_code OR person_code IS null) 
						AND (cust_code = pr_rate.cust_code OR cust_code IS null) 
						AND (job_code = pr_rate.job_code OR job_code IS null) 
						AND (var_code = pr_rate.var_code OR var_code IS null) 
						AND (activity_code = pr_rate.activity_code OR activity_code IS null) 

						IF pv_date_cnt > 0 THEN 
							LET msgresp=kandoomsg("J",9866,"") 
							# 9866 A expiry date FOR the same combination already exists, please re enter
							EXIT INPUT 
						END IF 

						INSERT INTO rate VALUES (pr_rate.*) 
						IF status = 0 THEN 
							LET msgresp=kandoomsg("J",9858,"") 
							# 9858 Rate RECORD added succesfully
						ELSE 
							LET pv_insert_ok = false 
							LET msgresp=kandoomsg("J",9864,"") 
							#9864 A rate FOR this combination already exist, Please Re-enter
						END IF 
					END IF 

					IF pv_mode = "U" THEN 
						UPDATE rate SET 
						(hourly_rate,expiry_date,person_code,cust_code,job_code,var_code,activity_code) 
						= (pr_rate.hourly_rate,pr_rate.expiry_date,pr_rate.person_code,pr_rate.cust_code, 
						pr_rate.job_code, pr_rate.var_code, pr_rate.activity_code) 
						WHERE cmpy_code = pr_rate_old.cmpy_code 
						AND rate_type = pr_rate_old.rate_type 
						AND (expiry_date = pr_rate_old.expiry_date OR expiry_date IS null) 
						AND (person_code = pr_rate_old.person_code OR person_code IS null) 
						AND (cust_code = pr_rate_old.cust_code OR cust_code IS null) 
						AND (job_code = pr_rate_old.job_code OR job_code IS null) 
						AND (var_code = pr_rate_old.var_code OR var_code IS null) 
						AND (activity_code = pr_rate_old.activity_code OR activity_code IS null) 
						IF status = 0 THEN 
							LET msgresp=kandoomsg("J",9859,"") 
							# 9859 RECORD updated succesfully
						ELSE 
							LET pv_insert_ok = false 
							LET msgresp=kandoomsg("J",9864,"") 
							# 9864 A rate FOR this combination already exist, Please Re-enter
						END IF 
					END IF 
					WHENEVER ERROR stop 
				COMMIT WORK 
			END IF 
	END INPUT 
END FUNCTION 

FUNCTION add_rate() 
	DEFINE 
	pr_rate_old RECORD LIKE rate.* 

	CURRENT WINDOW IS j212 

	IF pr_rate.rate_type IS NOT NULL THEN 
		LET pr_rate_old.* = pr_rate.* 
	END IF 

	CLEAR FORM 
	INITIALIZE pr_rate.* TO NULL 

	LET pr_rate.rate_type = pv_rate_type 
	DISPLAY BY NAME pr_rate.rate_type 

	CALL insert_rate(pr_rate.*, "A") 

	IF NOT pv_insert_ok THEN 
		LET pr_rate.* = pr_rate_old.* 
		CALL display_rate(pr_rate.*) 
	END IF 

END FUNCTION 

FUNCTION upd_rate() 
	DEFINE 
	pr_rate_old RECORD LIKE rate.* 

	CURRENT WINDOW IS j212 
	IF pr_rate.rate_type IS NULL THEN 
		LET msgresp=kandoomsg("J",9857,"") 
		# 9857 No existing RECORD TO be updated, search RECORD first
		RETURN 
	ELSE 
		LET pr_rate_old.* = pr_rate.* 
	END IF 

	CALL insert_rate(pr_rate_old.*,"U") 

	IF NOT pv_insert_ok THEN 
		LET pr_rate.* = pr_rate_old.* 
		CALL display_rate(pr_rate.*) 
	END IF 
END FUNCTION 



