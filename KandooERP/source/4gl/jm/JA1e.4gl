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

	Source code beautified by beautify.pl on 2020-01-02 19:48:16	$Id: $
}




# Purpose - Contract add
#           Edit/Add detail lines

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA1_GLOBALS.4gl" 


FUNCTION ent_job_dtls() 

	DEFINE 
	fv_x SMALLINT, 
	runner CHAR(100) 
	OPEN WINDOW wja03 with FORM "JA03" -- alch kd-747 
	CALL winDecoration_j("JA03") -- alch kd-747 
	LET msgresp = kandoomsg("A",1516,"") 
	# MESSAGE "ESC TO Accept, DEL TO Exit, F10 TO Add Job"

	DISPLAY "J" TO type_code 

	LET pr_contractdetl.* = pa_contractdetl[idx].* 

	LET pr_contractdetl.type_code = "J" 
	LET pr_contractdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_contractdetl.contract_code = pr_contracthead.contract_code 
	LET pr_contractdetl.cust_code = pr_contracthead.cust_code 

	IF pr_contractdetl.ship_code IS NOT NULL THEN 
		SELECT * 
		INTO pr_customership.* 
		FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_contractdetl.cust_code 
		AND ship_code = pr_contractdetl.ship_code 

		IF status != notfound THEN 
			DISPLAY BY NAME pr_customership.name_text, 
			pr_customership.addr_text, 
			pr_customership.addr2_text, 
			pr_customership.city_text, 
			pr_customership.state_code, 
			pr_customership.post_code 
		END IF 
	END IF 

	IF pr_contractdetl.job_code IS NOT NULL THEN 
		SELECT * 
		INTO pr_job.* 
		FROM job 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_contractdetl.cust_code 
		AND job_code = pr_contractdetl.job_code 

		IF status != notfound THEN 
			DISPLAY pr_job.title_text TO job_text 
		END IF 
	END IF 

	IF pr_contractdetl.var_code IS NOT NULL THEN 
		SELECT * 
		INTO pr_jobvars.* 
		FROM jobvars 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_contractdetl.job_code 
		AND var_code = pr_contractdetl.var_code 

		IF status != notfound THEN 
			DISPLAY pr_jobvars.title_text TO jobvars_text 
		END IF 
	END IF 

	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 

	# now lets get the gumpf

	INPUT BY NAME pr_contractdetl.ship_code, 
	pr_contractdetl.user1_text, 
	pr_contractdetl.user2_text, 
	pr_contractdetl.job_code, 
	pr_contractdetl.var_code, 
	pr_contractdetl.activity_code, 
	pr_contractdetl.desc_text 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA1e","input-pr_contractdetl-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "NOTES" infield (desc_text) --		ON KEY (control-n) 
			LET pr_contractdetl.desc_text = 
			sys_noter(glob_rec_kandoouser.cmpy_code, pr_contractdetl.desc_text) 
			DISPLAY BY NAME pr_contractdetl.desc_text 
			NEXT FIELD desc_text 


		ON KEY (control-b) 
			CASE 
				WHEN infield(ship_code) 
					LET pr_contractdetl.ship_code = 
					show_ship(glob_rec_kandoouser.cmpy_code,pr_contractdetl.cust_code) 
					DISPLAY BY NAME pr_contractdetl.ship_code 
					NEXT FIELD ship_code 

				WHEN infield(user1_text) 
					IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","B") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user1_text = pv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","C") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user2_text = pv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(job_code) 
					LET pr_contractdetl.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_contractdetl.job_code 
					NEXT FIELD job_code 

				WHEN infield(var_code) 
					LET pr_contractdetl.var_code = 
					show_jobvars(glob_rec_kandoouser.cmpy_code,pr_contractdetl.job_code) 
					DISPLAY BY NAME pr_contractdetl.var_code 
					NEXT FIELD var_code 

				WHEN infield(activity_code) 
					LET pr_contractdetl.activity_code = 
					show_activity(glob_rec_kandoouser.cmpy_code, pr_contractdetl.job_code, 
					pr_contractdetl.var_code) 
					DISPLAY BY NAME pr_contractdetl.activity_code 
					NEXT FIELD activity_code 
			END CASE 

		ON KEY (F10) 
			LET runner = " jobadd " 
			RUN runner 

		AFTER FIELD ship_code 
			IF pr_contractdetl.ship_code IS NOT NULL THEN 
				SELECT * 
				INTO pr_customership.* 
				FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_contractdetl.cust_code 
				AND ship_code = pr_contractdetl.ship_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# Invalid Location ID - try window"
					NEXT FIELD ship_code 
				ELSE 
					DISPLAY BY NAME pr_customership.name_text, 
					pr_customership.addr_text, 
					pr_customership.addr2_text, 
					pr_customership.city_text, 
					pr_customership.state_code, 
					pr_customership.post_code 
				END IF 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_contractdetl.ship_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Location ID Must Be Entered
				NEXT FIELD ship_code 
			END IF 

			IF pr_jmparms.cntrdt_prmpt1_ind = "5" THEN {skip this field} 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_contractdetl.user1_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "B" 
					AND ref_code = pr_contractdetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_jmparms.cntrdt_prmpt2_ind = "5" THEN {skip this field} 
				NEXT FIELD job_code 
			END IF 

		AFTER FIELD user2_text 
			IF pr_contractdetl.user2_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "C" 
					AND ref_code = pr_contractdetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9910,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		AFTER FIELD job_code 
			IF pr_contractdetl.job_code IS NOT NULL THEN 
				SELECT * 
				INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_contractdetl.job_code 
				AND cust_code = pr_contractdetl.cust_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# "Invalid Job Code - Try Window"
					NEXT FIELD job_code 
				END IF 

				LET pr_contractdetl.revenue_acct_code = pr_job.acct_code 

				# check that no other job code has been entered
				# FOR this contract











				DISPLAY pr_job.title_text TO job_text 

			END IF 

		BEFORE FIELD var_code 
			IF pr_contractdetl.job_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# "A Job code must be entered"
				NEXT FIELD job_code 
			END IF 
			IF pr_contractdetl.var_code IS NULL THEN 
				LET pr_contractdetl.var_code = 0 
			END IF 

		AFTER FIELD var_code 
			IF pr_contractdetl.var_code IS NOT NULL THEN 
				IF pr_contractdetl.var_code != 0 THEN 
					SELECT * 
					INTO pr_jobvars.* 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_contractdetl.job_code 
					AND var_code = pr_contractdetl.var_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# Invalid Variation Code - try window
						NEXT FIELD var_code 
					END IF 
				END IF 

				DISPLAY pr_jobvars.title_text TO jobvars_text 
			END IF 

		BEFORE FIELD activity_code 
			IF pr_contractdetl.var_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# "Variation code must be entered - try window"
				NEXT FIELD var_code 
			END IF 

		AFTER FIELD activity_code 
			IF pr_contractdetl.activity_code IS NOT NULL THEN 
				SELECT * 
				INTO pr_activity.* 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_contractdetl.job_code 
				AND var_code = pr_contractdetl.var_code 
				AND activity_code = pr_contractdetl.activity_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# This activity NOT found FOR job/variation - try window
					NEXT FIELD activity_code 
				END IF 

				# check that same combination of job_code, var_code &
				# activity_code has NOT already been entered FOR this contract.

				FOR fv_x = 1 TO arr_size 
					IF fv_x = idx THEN 
						CONTINUE FOR 
					END IF 
					IF pa_contractdetl[fv_x].type_code = "J" AND 
					pa_contractdetl[fv_x].job_code = 
					pr_contractdetl.job_code AND 
					pa_contractdetl[fv_x].var_code = 
					pr_contractdetl.var_code AND 
					pa_contractdetl[fv_x].activity_code = 
					pr_contractdetl.activity_code THEN 
						LET msgresp = kandoomsg("U",9104,"") 
						# Job/Variation/Activity already exists
						# FOR this contract
						NEXT FIELD var_code 
					END IF 
				END FOR 

				IF pr_contractdetl.desc_text IS NULL THEN 
					LET pr_contractdetl.desc_text = pr_activity.title_text 
				END IF 
				DISPLAY BY NAME pr_contractdetl.desc_text 
			END IF 

		BEFORE FIELD desc_text 
			IF pr_contractdetl.activity_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# Activity code must be entered
				NEXT FIELD activity_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_contractdetl.ship_code IS NULL OR 
			(pr_contractdetl.user1_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt1_ind = "4")) OR 
			(pr_contractdetl.user2_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt2_ind = "4")) OR 
			pr_contractdetl.job_code IS NULL OR 
			pr_contractdetl.var_code IS NULL OR 
			pr_contractdetl.activity_code IS NULL THEN 
				LET msgresp = kandoomsg("A",3536,"") 
				# All neccesary data must be entered before continuing
				NEXT FIELD ship_code 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wja03 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 



FUNCTION ent_inv_dtls() 

	DEFINE fv_x SMALLINT, 
	fv_rev_acct_code LIKE contractdetl.revenue_acct_code 
	OPEN WINDOW wja04 with FORM "JA04" -- alch kd-747 
	CALL winDecoration_j("JA04") -- alch kd-747 
	LET msgresp = kandoomsg("A",1511,"") 
	# MESSAGE "ESC TO Accept, DEL TO Exit"

	DISPLAY "I" TO type_code 

	LET pr_contractdetl.* = pa_contractdetl[idx].* 

	LET pr_contractdetl.type_code = "I" 
	LET pr_contractdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_contractdetl.contract_code = pr_contracthead.contract_code 
	LET pr_contractdetl.cust_code = pr_contracthead.cust_code 

	IF pr_contractdetl.ship_code IS NOT NULL THEN 
		SELECT * INTO pr_customership.* FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_contractdetl.cust_code 
		AND ship_code = pr_contractdetl.ship_code 

		IF status != notfound THEN 
			DISPLAY BY NAME pr_customership.name_text, 
			pr_customership.addr_text, 
			pr_customership.addr2_text, 
			pr_customership.city_text, 
			pr_customership.state_code, 
			pr_customership.post_code 
		END IF 
	END IF 

	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 

	INPUT BY NAME pr_contractdetl.ship_code, 
	pr_contractdetl.user1_text, 
	pr_contractdetl.user2_text, 
	pr_contractdetl.part_code, 
	pr_contractdetl.desc_text, 
	pr_contractdetl.bill_qty, 
	pr_contractdetl.bill_price 

	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA1e","input-pr_contractdetl-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
				LET pr_contractdetl.desc_text = 
				sys_noter(glob_rec_kandoouser.cmpy_code, pr_contractdetl.desc_text) 
				DISPLAY BY NAME pr_contractdetl.desc_text 
				NEXT FIELD desc_text 

		ON KEY (control-b) 
			CASE 
				WHEN infield(ship_code) 
					LET pr_contractdetl.ship_code = 
					show_ship(glob_rec_kandoouser.cmpy_code,pr_contractdetl.cust_code) 
					DISPLAY BY NAME pr_contractdetl.ship_code 
					NEXT FIELD ship_code 

				WHEN infield(user1_text) 
					IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","B") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user1_text = pv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","C") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user2_text = pv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(part_code) 
					LET pr_contractdetl.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_contractdetl.part_code 
					NEXT FIELD part_code 






			END CASE 

		AFTER FIELD ship_code 
			IF pr_contractdetl.ship_code IS NOT NULL THEN 
				SELECT * INTO pr_customership.* FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_contractdetl.cust_code 
				AND ship_code = pr_contractdetl.ship_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# Invalid Location ID - try window"
					NEXT FIELD ship_code 
				ELSE 
					DISPLAY BY NAME pr_customership.name_text, 
					pr_customership.addr_text, 
					pr_customership.addr2_text, 
					pr_customership.city_text, 
					pr_customership.state_code, 
					pr_customership.post_code 
				END IF 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_contractdetl.ship_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Location ID Must Be Entered
				NEXT FIELD ship_code 
			END IF 

			IF pr_jmparms.cntrdt_prmpt1_ind = "5" THEN {skip this field} 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_contractdetl.user1_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "B" 
					AND ref_code = pr_contractdetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9910,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_jmparms.cntrdt_prmpt2_ind = "5" THEN {skip this field} 
				NEXT FIELD part_code 
			END IF 

		AFTER FIELD user2_text 
			IF pr_contractdetl.user2_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "C" 
					AND ref_code = pr_contractdetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9910,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		AFTER FIELD part_code 
			IF pr_contractdetl.part_code IS NOT NULL THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_contractdetl.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# Product NOT found - try window
					NEXT FIELD part_code 
				END IF 

				# check that part has NOT already been entered FOR this contract

				FOR fv_x = 1 TO arr_size 
					IF pa_contractdetl[fv_x].type_code = "I" AND 
					fv_x != idx AND 
					pa_contractdetl[fv_x].part_code = 
					pr_contractdetl.part_code THEN 
						LET msgresp = kandoomsg("A",3541,"") 
						# This Part has already been entered FOR this contract
						NEXT FIELD part_code 
					END IF 
				END FOR 


				SELECT * 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_contractdetl.part_code 
				AND ware_code = pr_customership.ware_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("A",9550,"") 
					# "Product IS NOT SET up AT default shipping warehouse
					NEXT FIELD part_code 
				END IF 


				IF pr_contractdetl.desc_text IS NULL THEN 
					LET pr_contractdetl.desc_text = pr_product.desc_text 
					DISPLAY BY NAME pr_contractdetl.desc_text 
				END IF 
				CALL get_price(pr_contractdetl.part_code, 
				pr_customership.ware_code) 
				RETURNING pr_contractdetl.bill_price 
				DISPLAY BY NAME pr_contractdetl.bill_price 









			END IF 

		BEFORE FIELD desc_text 
			IF pr_contractdetl.part_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# Product Code must be entered
				NEXT FIELD part_code 
			END IF 

		BEFORE FIELD bill_price 
			IF pr_contractdetl.bill_qty IS NULL OR 
			pr_contractdetl.bill_qty = 0 THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Quantity must be entered
				NEXT FIELD bill_qty 
			END IF 

		AFTER FIELD bill_price 
			IF pr_contractdetl.bill_price IS NULL OR 
			pr_contractdetl.bill_price = 0 THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Price must be entered
				NEXT FIELD bill_price 
			END IF 















		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_contractdetl.ship_code IS NULL OR 
			(pr_contractdetl.user1_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt1_ind = "4")) OR 
			(pr_contractdetl.user2_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt2_ind = "4")) OR 
			pr_contractdetl.part_code IS NULL OR 
			pr_contractdetl.bill_qty IS NULL OR 
			pr_contractdetl.bill_price IS NULL OR 
			pr_contractdetl.bill_qty = 0 OR 
			pr_contractdetl.bill_price = 0 THEN 
				LET msgresp = kandoomsg("A",3536,"") 
				# All neccesary data must be entered before continuing
				NEXT FIELD ship_code 
			END IF 
			#Get Revenue account FOR this part
			SELECT * INTO pr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_contractdetl.part_code 

			SELECT sale_acct_code INTO fv_rev_acct_code 
			FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 

			LET pr_contractdetl.revenue_acct_code = fv_rev_acct_code 



			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_contractdetl.part_code 
			AND ware_code = pr_customership.ware_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9550,"") 
				# "Product IS NOT SET up AT default shipping warehouse"
				NEXT FIELD part_code 
			END IF 


		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wja04 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 

FUNCTION ent_gen_dtls() 

	DEFINE 
	fv_cb_flag LIKE glparms.cash_book_flag 
	OPEN WINDOW wja05 with FORM "JA05" -- alch kd-747 
	CALL winDecoration_j("JA05") -- alch kd-747 
	LET msgresp = kandoomsg("A",1511,"") 
	# MESSAGE "ESC TO Accept, DEL TO Exit"

	DISPLAY "G" TO type_code 

	LET pr_contractdetl.* = pa_contractdetl[idx].* 

	LET pr_contractdetl.type_code = "G" 
	LET pr_contractdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_contractdetl.contract_code = pr_contracthead.contract_code 
	LET pr_contractdetl.cust_code = pr_contracthead.cust_code 

	IF pr_contractdetl.ship_code IS NOT NULL THEN 
		SELECT * INTO pr_customership.* FROM customership 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_contractdetl.cust_code 
		AND ship_code = pr_contractdetl.ship_code 

		IF status != notfound THEN 
			DISPLAY BY NAME pr_customership.name_text, 
			pr_customership.addr_text, 
			pr_customership.addr2_text, 
			pr_customership.city_text, 
			pr_customership.state_code, 
			pr_customership.post_code 
		END IF 
	END IF 

	DISPLAY BY NAME pr_jmparms.cntrdt_prmpt1_text, 
	pr_jmparms.cntrdt_prmpt2_text 

	INPUT BY NAME pr_contractdetl.ship_code, 
	pr_contractdetl.user1_text, 
	pr_contractdetl.user2_text, 
	pr_contractdetl.desc_text, 
	pr_contractdetl.bill_qty, 
	pr_contractdetl.bill_price, 
	pr_contractdetl.revenue_acct_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JA1e","input-pr_contractdetl-3") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "NOTES" infield (desc_text) --	ON KEY (control-n) 
				LET pr_contractdetl.desc_text = 
				sys_noter(glob_rec_kandoouser.cmpy_code, pr_contractdetl.desc_text) 
				DISPLAY BY NAME pr_contractdetl.desc_text 
				NEXT FIELD desc_text 

		ON KEY (control-b) 
			CASE 
				WHEN infield(ship_code) 
					LET pr_contractdetl.ship_code = 
					show_ship(glob_rec_kandoouser.cmpy_code,pr_contractdetl.cust_code) 
					DISPLAY BY NAME pr_contractdetl.ship_code 
					NEXT FIELD ship_code 

				WHEN infield(user1_text) 
					IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","B") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user1_text = pv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
					pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"J","C") RETURNING pv_ref_code 
						IF pv_ref_code IS NOT NULL THEN 
							LET pr_contractdetl.user2_text = pv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(revenue_acct_code) 
					LET pr_contractdetl.revenue_acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_contractdetl.revenue_acct_code 
					NEXT FIELD revenue_acct_code 

			END CASE 

		AFTER FIELD ship_code 
			IF pr_contractdetl.ship_code IS NOT NULL THEN 
				SELECT * INTO pr_customership.* FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_contractdetl.cust_code 
				AND ship_code = pr_contractdetl.ship_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# Invalid Location ID - try window"
					NEXT FIELD ship_code 
				ELSE 
					DISPLAY BY NAME pr_customership.name_text, 
					pr_customership.addr_text, 
					pr_customership.addr2_text, 
					pr_customership.city_text, 
					pr_customership.state_code, 
					pr_customership.post_code 
				END IF 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_contractdetl.ship_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Location ID Must Be Entered
				NEXT FIELD ship_code 
			END IF 

			IF pr_jmparms.cntrdt_prmpt1_ind = "5" THEN {skip this field} 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_contractdetl.user1_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt1_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt1_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "B" 
					AND ref_code = pr_contractdetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_jmparms.cntrdt_prmpt2_ind = "5" THEN {skip this field} 
				NEXT FIELD bill_price 
			END IF 

		AFTER FIELD user2_text 
			IF pr_contractdetl.user2_text IS NULL THEN 
				IF pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					# "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_jmparms.cntrdt_prmpt2_ind = "3" OR 
				pr_jmparms.cntrdt_prmpt2_ind = "4" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "J" 
					AND ref_ind = "C" 
					AND ref_code = pr_contractdetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						# "User Defined INPUT NOT valid - Try window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD bill_price 
			IF pr_contractdetl.bill_qty IS NULL OR 
			pr_contractdetl.bill_qty = 0 THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Quantity must be entered
				NEXT FIELD bill_qty 
			END IF 

		BEFORE FIELD revenue_acct_code 
			IF pr_contractdetl.bill_price IS NULL OR 
			pr_contractdetl.bill_price = 0 THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# A Price must be entered
				NEXT FIELD bill_price 
			END IF 

		AFTER FIELD revenue_acct_code 
			IF pr_contractdetl.revenue_acct_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				# "Account code must be entered"
				NEXT FIELD revenue_acct_code 
			ELSE 
				SELECT * 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_contractdetl.revenue_acct_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					# Account number does NOT exist - Try window
					NEXT FIELD revenue_acct_code 
				END IF 


				SELECT cash_book_flag 
				INTO fv_cb_flag 
				FROM glparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_code = "1" 

				IF bk_ac_ck(glob_rec_kandoouser.cmpy_code, pr_contractdetl.revenue_acct_code, fv_cb_flag) 
				THEN 
					NEXT FIELD revenue_acct_code 
				END IF 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_contractdetl.ship_code IS NULL OR 
			(pr_contractdetl.user1_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt1_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt1_ind = "4")) OR 
			(pr_contractdetl.user2_text IS NULL AND 
			(pr_jmparms.cntrdt_prmpt2_ind = "2" OR 
			pr_jmparms.cntrdt_prmpt2_ind = "4")) OR 
			pr_contractdetl.bill_qty IS NULL OR 
			pr_contractdetl.bill_price IS NULL OR 
			pr_contractdetl.bill_qty = 0 OR 
			pr_contractdetl.bill_price = 0 THEN 
				LET msgresp = kandoomsg("A",3536,"") 
				# All neccesary data must be entered before continuing
				NEXT FIELD ship_code 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wja05 

	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 

# Get correct price
FUNCTION get_price(fv_part_code, fv_ware_code) 
	DEFINE 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	fv_part_code LIKE product.part_code, 
	fv_ware_code LIKE prodstatus.ware_code, 
	fv_level_ind LIKE customer.inv_level_ind 

	IF fv_part_code IS NOT NULL THEN 
		SELECT * INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fv_part_code 
		AND ware_code = fv_ware_code 

		SELECT inv_level_ind INTO fv_level_ind 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_contractdetl.cust_code 

		CASE (fv_level_ind) 
			WHEN "1" LET pr_contractdetl.bill_price = pr_prodstatus.price1_amt 
			WHEN "2" LET pr_contractdetl.bill_price = pr_prodstatus.price2_amt 
			WHEN "3" LET pr_contractdetl.bill_price = pr_prodstatus.price3_amt 
			WHEN "4" LET pr_contractdetl.bill_price = pr_prodstatus.price4_amt 
			WHEN "5" LET pr_contractdetl.bill_price = pr_prodstatus.price5_amt 
			WHEN "6" LET pr_contractdetl.bill_price = pr_prodstatus.price6_amt 
			WHEN "7" LET pr_contractdetl.bill_price = pr_prodstatus.price7_amt 
			WHEN "8" LET pr_contractdetl.bill_price = pr_prodstatus.price8_amt 
			WHEN "9" LET pr_contractdetl.bill_price = pr_prodstatus.price9_amt 
			WHEN "L" LET pr_contractdetl.bill_price = pr_prodstatus.list_amt 
			WHEN "C" LET pr_contractdetl.bill_price = pr_prodstatus.wgted_cost_amt 
			OTHERWISE 
				LET pr_contractdetl.bill_price = pr_prodstatus.list_amt 
		END CASE 
	END IF 
	RETURN pr_contractdetl.bill_price 
END FUNCTION 
