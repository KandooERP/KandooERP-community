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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J7_GLOBALS.4gl" 

# Purpose - Allocate resource accruals TO activities

GLOBALS 
	DEFINE 
	pr_jmresource RECORD LIKE jmresource.*,
	pr_glparms RECORD LIKE glparms.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_actiunit RECORD LIKE actiunit.*,
	pa_res_alloc array[100] OF RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pa_comment array[100] OF RECORD 
		desc_text LIKE jobledger.desc_text 
	END RECORD, 
	pa_unit_code array[100] OF CHAR(3), 
	idx, scrn, return_status,pr_add_value SMALLINT, 
	pr_avg_rate_amt DECIMAL(12,4), 
	pr_tot_trans_qty DECIMAL(10,2), 
	pr_tot_cost_amt DECIMAL(17,2), 
	pr_tot_bill_amt DECIMAL(17,2) 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("J7B") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT jmparms.* INTO pr_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("N",5010,"") 
		#7002 Job Management Parameters Not Setup;  Refer Menu JZP.
		EXIT program 
	END IF 
	SELECT glparms.* INTO pr_glparms.* FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G",5007,"") 
		#5007 General Ledger Parameters Not Setup;  Refer Menu GZP.
		EXIT program 
	END IF 
	OPEN WINDOW j172 with FORM "J172" -- alch kd-747 
	CALL winDecoration_j("J172") -- alch kd-747 
	WHILE get_resource() 
		IF alloc_details() THEN 
			IF upd_jobledg() THEN 
			ELSE 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW j172 
END MAIN 


FUNCTION get_resource() 
	DEFINE str CHAR (3000) 
	CLEAR FORM 
	INITIALIZE pr_jobledger.* TO NULL 
	LET pr_jobledger.trans_date = today 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_jobledger.year_num, 
	pr_jobledger.period_num 

	INPUT pr_jmresource.res_code, 
	pr_jobledger.trans_date, 
	pr_jobledger.year_num, 
	pr_jobledger.period_num WITHOUT DEFAULTS 
	FROM res_code, 
	trans_date, 
	year_num, 
	period_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7B","input-pr_jmresource-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (interrupt) 
			EXIT INPUT 

		ON KEY (control-b) 
			IF infield (res_code) THEN 
				LET pr_jmresource.res_code = show_res(glob_rec_kandoouser.cmpy_code) 
				SELECT desc_text INTO pr_jmresource.desc_text FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jmresource.res_code 
				DISPLAY pr_jmresource.res_code, 
				pr_jmresource.desc_text 
				TO jmresource.res_code, 
				res_desc_text 

			END IF 
		AFTER FIELD res_code 
			IF pr_jmresource.res_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9514," ") 
				#9514 Resource Code must be entered.
				NEXT FIELD res_code 
			END IF 


			DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
			DISPLAY "see jm/J76.4gl" 
			EXIT program (1) 

			LET str = 
			" SELECT jmresource.*, actiunit.* ", 
			" INTO pr_jmresource.*, pr_actiunit.* ", 
			" FROM jmresource, outer actiunit ", 
			" WHERE jmresource.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
			" AND res_code = ", pr_jmresource.res_code, 
			" AND actiunit.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
			" AND actiunit.unit_code = jmresource.unit_code " 

			EXECUTE immediate str 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("J",9515," ") 
				#9515 No such Resource Code;  Try Window.
				NEXT FIELD res_code 
			END IF 
			IF pr_jmresource.allocation_ind IS NULL THEN 
				LET pr_jmresource.allocation_ind = "A" 
			END IF 
			DISPLAY pr_jmresource.desc_text, 
			pr_jmresource.unit_code, 
			pr_jmresource.unit_cost_amt, 
			pr_jmresource.cost_ind, 
			pr_jmresource.unit_bill_amt, 
			pr_jmresource.bill_ind, 
			pr_actiunit.desc_text 
			TO res_desc_text, 
			jmresource.unit_code, 
			unit_cost_rate, 
			jmresource.cost_ind, 
			unit_bill_rate, 
			jmresource.bill_ind, 
			unit_desc_text 


		AFTER FIELD trans_date 
			IF pr_jobledger.trans_date IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET pr_jobledger.trans_date = today 
				NEXT FIELD trans_date 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.trans_date) 
			RETURNING pr_jobledger.year_num, 
			pr_jobledger.period_num 
			DISPLAY BY NAME pr_jobledger.year_num, 
			pr_jobledger.period_num 


		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_jobledger.year_num, 
				pr_jobledger.period_num, "JM") 
				RETURNING pr_jobledger.year_num, 
				pr_jobledger.period_num, 
				return_status 
				IF return_status THEN 
					NEXT FIELD trans_date 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION alloc_details() 
	DEFINE 
	pf_res_alloc RECORD 
		scroll_flag CHAR(1), 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		trans_qty LIKE jobledger.trans_qty, 
		unit_cost_amt LIKE jmresource.unit_cost_amt, 
		unit_bill_amt LIKE jmresource.unit_bill_amt, 
		trans_amt LIKE jobledger.trans_amt, 
		charge_amt LIKE jobledger.charge_amt, 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_cnt1, pr_cnt2, 
	pr_counter SMALLINT, 
	pr_first_time, 
	pr_scroll_flag CHAR(1), 
	pr_job_code LIKE jobledger.job_code, 
	pr_activity_code LIKE jobledger.activity_code 

	LET msgresp = kandoomsg("J",1549,"") 
	#1549 F8 Allocation Mode;  OK TO Continue.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f2 
	LET pr_first_time = true 
	FOR pr_counter = 1 TO 100 
		INITIALIZE pa_res_alloc[pr_counter].* TO NULL 
		INITIALIZE pa_comment[pr_counter].* TO NULL 
	END FOR 
	CALL set_count(1) 
	INPUT ARRAY pa_res_alloc WITHOUT DEFAULTS FROM sr_res_alloc.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7B","input-pa_res_alloc-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE INSERT 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pa_unit_code[idx] = pr_jmresource.unit_code 
			LET pa_res_alloc[idx].allocation_ind = 
			pr_jmresource.allocation_ind 
			DISPLAY pa_res_alloc[idx].unit_cost_amt, 
			pa_res_alloc[idx].unit_bill_amt 
			TO sr_res_alloc[scrn].unit_cost_amt, 
			sr_res_alloc[scrn].unit_bill_amt 

		AFTER DELETE 
			IF infield(scroll_flag) THEN 
				LET pr_first_time = false 
				FOR pr_counter = arr_curr() TO (arr_count() + 1) 
					LET pa_comment[pr_counter].* = pa_comment[pr_counter+1].* 
				END FOR 
				LET pr_tot_trans_qty = 0 
				LET pr_tot_cost_amt = 0 
				LET pr_tot_bill_amt = 0 
				LET pr_avg_rate_amt= 0 
				FOR pr_counter = 1 TO arr_count() 
					IF pa_res_alloc[pr_counter].job_code IS NULL THEN 
						CONTINUE FOR 
					END IF 
					LET pr_tot_trans_qty = pr_tot_trans_qty + 
					pa_res_alloc[pr_counter].trans_qty 
					LET pr_tot_cost_amt = pr_tot_cost_amt + 
					pa_res_alloc[pr_counter].trans_amt 
					LET pr_tot_bill_amt = pr_tot_bill_amt + 
					pa_res_alloc[pr_counter].charge_amt 
				END FOR 
				IF pr_tot_trans_qty = 0 THEN 
					LET pr_avg_rate_amt = 0 
				ELSE 
					LET pr_avg_rate_amt = pr_tot_cost_amt / pr_tot_trans_qty 
				END IF 
				DISPLAY pr_tot_trans_qty, 
				pr_tot_cost_amt, 
				pr_tot_bill_amt, 
				pr_avg_rate_amt 
				TO tot_trans_qty, 
				tot_cost_amt, 
				tot_charge_amt, 
				avg_rate_amt 

			END IF 
		ON KEY (F8) 
			IF pr_jmresource.allocation_flag <> "1" THEN 
				LET msgresp = kandoomsg("J",9555,"") 
				#9555 Resource does NOT permit user TO override the Allocation ...
			ELSE 
				IF pa_res_alloc[idx].job_code IS NOT NULL THEN 
					CALL adjust_allocflag(glob_rec_kandoouser.cmpy_code, pr_jmresource.res_code, 
					pa_res_alloc[idx].allocation_ind) 
					RETURNING pa_res_alloc[idx].allocation_ind 
					DISPLAY BY NAME pa_res_alloc[idx].allocation_ind 

				END IF 
			END IF 
		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET pa_res_alloc[idx].job_code = show_job(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pa_res_alloc[idx].job_code 
					TO sr_res_alloc[scrn].job_code 

				WHEN infield (var_code) 
					LET pa_res_alloc[idx].var_code = 
					show_jobvars(glob_rec_kandoouser.cmpy_code, pa_res_alloc[idx].job_code) 
					DISPLAY pa_res_alloc[idx].var_code 
					TO sr_res_alloc[scrn].var_code 

				WHEN infield (activity_code) 
					LET pa_res_alloc[idx].activity_code = 
					show_activity(glob_rec_kandoouser.cmpy_code, pa_res_alloc[idx].job_code, 
					pa_res_alloc[idx].var_code) 
					DISPLAY pa_res_alloc[idx].activity_code 
					TO sr_res_alloc[scrn].activity_code 

			END CASE 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_res_alloc[idx].scroll_flag 
			LET pf_res_alloc.* = pa_res_alloc[idx].* 
			IF pf_res_alloc.job_code IS NULL THEN 
				# Used FOR WHEN the user presses CANCEL AFTER inserting a line
				LET pf_res_alloc.allocation_ind = NULL 
			END IF 
			IF pr_first_time THEN 
				NEXT FIELD job_code 
			END IF 
			DISPLAY pf_res_alloc.* 
			TO sr_res_alloc[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_res_alloc[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_res_alloc[idx].* 
			TO sr_res_alloc[scrn].* 

			IF pa_res_alloc[idx].job_code IS NULL 
			AND pa_res_alloc[idx].var_code IS NULL 
			AND pa_res_alloc[idx].activity_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() + 1 > arr_count() THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("left") THEN 
					LET pr_first_time = true 
				END IF 
			END IF 
		BEFORE FIELD job_code 
			# Don't want user TO use DELETE key in ARRAY entry.
			OPTIONS DELETE KEY f36 
			LET pr_job_code = pa_res_alloc[idx].job_code 
		AFTER FIELD job_code 
			IF pa_res_alloc[idx].job_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET pa_res_alloc[idx].job_code = pr_job_code 
				NEXT FIELD job_code 
			END IF 
			SELECT unique(1) FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job.job_code = pa_res_alloc[idx].job_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("J",9558," ") 
				#9558 Job Code NOT found - Try Window.
				LET pa_res_alloc[idx].job_code = pr_job_code 
				NEXT FIELD job_code 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				NEXT FIELD NEXT 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				IF pa_res_alloc[idx].job_code IS NULL 
				AND pa_res_alloc[idx].var_code IS NOT NULL 
				AND pa_res_alloc[idx].activity_code IS NOT NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					LET pa_res_alloc[idx].job_code = pr_job_code 
					#9102 Value must be entered.
					NEXT FIELD job_code 
				END IF 
				IF pa_res_alloc[idx].var_code IS NULL THEN 
					LET msgresp = kandoomsg("J",9511," ") 
					#9511 Activity Code must be entered.
					NEXT FIELD var_code 
				END IF 
				IF pa_res_alloc[idx].activity_code IS NULL THEN 
					LET msgresp = kandoomsg("J",9511," ") 
					#9511 Activity Code must be entered.
					NEXT FIELD activity_code 
				END IF 
			END IF 
			CALL default_values() 
		BEFORE FIELD var_code 
			CALL default_values() 
		AFTER FIELD var_code 
			IF pa_res_alloc[idx].var_code IS NULL 
			OR pa_res_alloc[idx].var_code = 0 THEN 
				LET pa_res_alloc[idx].var_code = 0 
				DISPLAY pa_res_alloc[idx].var_code 
				TO sr_res_alloc[scrn].var_code 

				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					IF fgl_lastkey() != fgl_keyval("accept") THEN 
						NEXT FIELD activity_code 
					END IF 
				END IF 
			ELSE 
				SELECT unique(1) FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_res_alloc[idx].job_code 
				AND var_code = pa_res_alloc[idx].var_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9510,"") 
					#9510 Variation NOT found;  Try Window.
					NEXT FIELD var_code 
				END IF 
				IF fgl_lastkey() = fgl_keyval("left") 
				OR fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					IF fgl_lastkey() != fgl_keyval("accept") THEN 
						NEXT FIELD activity_code 
					END IF 
				END IF 
			END IF 
		BEFORE FIELD activity_code 
			CALL default_values() 
		AFTER FIELD activity_code 
			IF pa_res_alloc[idx].activity_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9511," ") 
				#9511 Activity Code must be entered.
				LET pa_res_alloc[idx].activity_code = pf_res_alloc.activity_code 
				NEXT FIELD activity_code 
			END IF 
			SELECT finish_flag, 
			wip_acct_code 
			INTO pr_activity.finish_flag, 
			pr_activity.wip_acct_code 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pa_res_alloc[idx].job_code 
			AND var_code = pa_res_alloc[idx].var_code 
			AND activity_code = pa_res_alloc[idx].activity_code 
			CASE 
				WHEN status = notfound 
					LET msgresp = kandoomsg("J",9512," ") 
					#9512 This activity NOT found FOR this job/variation.
					LET pa_res_alloc[idx].activity_code = pf_res_alloc.activity_code 
					DISPLAY pa_res_alloc[idx].activity_code 
					TO sr_res_alloc[scrn].activity_code 

					NEXT FIELD job_code 
				WHEN pr_activity.finish_flag = "Y" 
					LET msgresp = kandoomsg("J",9513," ") 
					#9513 This Activity IS Finished;  No costs may be allocated.
					LET pa_res_alloc[idx].activity_code = pf_res_alloc.activity_code 
					DISPLAY BY NAME pa_res_alloc[idx].activity_code 

					NEXT FIELD job_code 
				OTHERWISE 
					IF fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						IF fgl_lastkey() != fgl_keyval("accept") THEN 
							NEXT FIELD trans_qty 
						END IF 
					END IF 
			END CASE 
		AFTER FIELD trans_qty 
			IF pa_res_alloc[idx].trans_qty IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				LET pa_res_alloc[idx].trans_qty = 0 
				#9102 value must be entered.
				NEXT FIELD trans_qty 
			END IF 
			LET pa_res_alloc[idx].trans_amt = 
			pa_res_alloc[idx].unit_cost_amt * 
			pa_res_alloc[idx].trans_qty 
			LET pa_res_alloc[idx].charge_amt = 
			pa_res_alloc[idx].unit_bill_amt * 
			pa_res_alloc[idx].trans_qty 
			DISPLAY pa_res_alloc[idx].trans_amt, 
			pa_res_alloc[idx].charge_amt 
			TO sr_res_alloc[scrn].trans_amt, 
			sr_res_alloc[scrn].charge_amt 

			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			END IF 
			IF pr_jmresource.cost_ind = "2" THEN 
				LET pa_comment[idx].desc_text = get_comment(pa_comment[idx].*) 
				NEXT FIELD charge_amt 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				NEXT FIELD NEXT 
			END IF 
		AFTER FIELD unit_cost_amt 
			IF pa_res_alloc[idx].unit_cost_amt IS NULL THEN 
				LET pa_res_alloc[idx].unit_cost_amt = 
				pr_jmresource.unit_cost_amt 
				DISPLAY pa_res_alloc[idx].unit_cost_amt 
				TO sr_res_alloc[scrn].unit_cost_amt 

			ELSE 
				LET pa_res_alloc[idx].trans_amt = 
				pa_res_alloc[idx].unit_cost_amt * 
				pa_res_alloc[idx].trans_qty 
				DISPLAY pa_res_alloc[idx].trans_amt 
				TO sr_res_alloc[scrn].trans_amt 

			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				NEXT FIELD NEXT 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD previous 
			END IF 
		AFTER FIELD unit_bill_amt 
			IF pa_res_alloc[idx].unit_bill_amt IS NULL THEN 
				LET pa_res_alloc[idx].unit_bill_amt = 
				pr_jmresource.unit_bill_amt 
				DISPLAY pa_res_alloc[idx].unit_bill_amt 
				TO sr_res_alloc[scrn].unit_bill_amt 

			ELSE 
				LET pa_res_alloc[idx].charge_amt = 
				pa_res_alloc[idx].unit_bill_amt * 
				pa_res_alloc[idx].trans_qty 
				DISPLAY pa_res_alloc[idx].charge_amt 
				TO sr_res_alloc[scrn].charge_amt 

			END IF 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD previous 
			ELSE 
				LET pa_comment[idx].desc_text = get_comment(pa_comment[idx].*) 
				NEXT FIELD trans_amt 
			END IF 
		AFTER ROW 
			IF not(int_flag OR quit_flag) THEN 
				INITIALIZE pf_res_alloc.* TO NULL 
				LET pr_tot_trans_qty = 0 
				LET pr_tot_cost_amt = 0 
				LET pr_tot_bill_amt = 0 
				LET pr_avg_rate_amt= 0 
				FOR pr_counter = 1 TO arr_count() 
					IF pa_res_alloc[pr_counter].job_code IS NULL THEN 
						CONTINUE FOR 
					END IF 
					LET pr_tot_trans_qty = pr_tot_trans_qty + 
					pa_res_alloc[pr_counter].trans_qty 
					LET pr_tot_cost_amt = pr_tot_cost_amt + 
					pa_res_alloc[pr_counter].trans_amt 
					LET pr_tot_bill_amt = pr_tot_bill_amt + 
					pa_res_alloc[pr_counter].charge_amt 
				END FOR 
				IF pr_tot_trans_qty = 0 THEN 
					LET pr_avg_rate_amt = 0 
				ELSE 
					LET pr_avg_rate_amt = pr_tot_cost_amt / pr_tot_trans_qty 
				END IF 
				DISPLAY pr_tot_trans_qty, 
				pr_tot_cost_amt, 
				pr_tot_bill_amt, 
				pr_avg_rate_amt 
				TO tot_trans_qty, 
				tot_cost_amt, 
				tot_charge_amt, 
				avg_rate_amt 

			END IF 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f2 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF fgl_lastkey() = fgl_keyval("accept") 
				AND NOT infield(scroll_flag) THEN 
					IF pa_res_alloc[idx].var_code IS NULL THEN 
						LET pa_res_alloc[idx].var_code = 0 
						DISPLAY BY NAME pa_res_alloc[idx].var_code 

					END IF 
					IF pa_res_alloc[idx].activity_code IS NULL THEN 
						LET msgresp = kandoomsg("J",9511," ") 
						#9511 Activity Code must be entered.
						NEXT FIELD activity_code 
					END IF 
					SELECT unique(1) FROM activity 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pa_res_alloc[idx].job_code 
					AND var_code = pa_res_alloc[idx].var_code 
					AND activity_code = pa_res_alloc[idx].activity_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("J",9512," ") 
						#9512 This activity NOT found FOR this job/variation.
						NEXT FIELD job_code 
					END IF 
					IF pa_res_alloc[idx].trans_qty IS NULL THEN 
						LET msgresp = kandoomsg("J",9102," ") 
						#9102 Value must be entered.
						NEXT FIELD trans_qty 
					END IF 
					NEXT FIELD allocation_ind 
				ELSE 
					IF pa_res_alloc[1].job_code IS NOT NULL THEN 
						LET msgresp = kandoomsg("J",8027,"") 
						#8023 Do you wish TO save Resource accrual details? (Y/N)
						IF msgresp = "N" THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				END IF 
			ELSE 
				LET pr_first_time = false 
				IF infield(scroll_flag) THEN 
					LET msgresp = kandoomsg("J",8028,"") 
					#8024 Do you wish TO abandon resources accrual? (Y/N)
					IF msgresp = "N" THEN 
						LET int_flag = false 
						LET quit_flag = false 
						INITIALIZE pf_res_alloc.* TO NULL 
						NEXT FIELD scroll_flag 
					END IF 
					LET int_flag = true 
				ELSE 
					LET pa_res_alloc[idx].* = pf_res_alloc.* 
					INITIALIZE pf_res_alloc.* TO NULL 
					DISPLAY pa_res_alloc[idx].* 
					TO sr_res_alloc[scrn].* 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag 
	OR pa_res_alloc[1].job_code IS NULL THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION get_comment(pr_comment) 
	DEFINE 
	pr_comment LIKE jobledger.desc_text, 
	pr_jobledger RECORD LIKE jobledger.* 
	OPEN WINDOW j310 with FORM "J310" -- alch kd-747 
	CALL winDecoration_j("J310") -- alch kd-747 
	LET msgresp = kandoomsg("U",1020,"Comment") 
	#1020 Enter Comment Details.
	LET pr_jobledger.desc_text = pr_comment 
	INPUT BY NAME pr_jobledger.desc_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7B","input-pr_jobledger-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j310 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN pr_jobledger.desc_text 
END FUNCTION 


FUNCTION upd_jobledg() 
	DEFINE 
	err_message CHAR(40), 
	err_continue CHAR(1), 
	pr_counter SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "Updating jmparms" 
		DECLARE jm_upd CURSOR FOR 
		SELECT jmparms.* 
		INTO pr_jmparms.* 
		FROM jmparms 
		WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jmparms.key_code = "1" 
		FOR UPDATE 
		OPEN jm_upd 
		FETCH jm_upd 
		LET pr_jmparms.ra_num = pr_jmparms.ra_num + 1 
		UPDATE jmparms 
		SET ra_num = pr_jmparms.ra_num 
		WHERE CURRENT OF jm_upd 
		FOR idx = 1 TO arr_count() 
			IF pa_res_alloc[idx].trans_amt IS NOT NULL THEN 
				LET err_message = "J7B SELECT FROM activity" 
				DECLARE act_upd CURSOR FOR 
				SELECT * 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pa_res_alloc[idx].job_code 
				AND var_code = pa_res_alloc[idx].var_code 
				AND activity_code = pa_res_alloc[idx].activity_code 
				FOR UPDATE 
				OPEN act_upd 
				FETCH act_upd INTO pr_activity.* 
				IF status = notfound THEN 
					GOTO recovery 
				END IF 
				LET pr_activity.seq_num = pr_activity.seq_num + 1 
				LET err_message = "Inserting jobledger" 
				LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_jobledger.trans_date = pr_jobledger.trans_date 
				LET pr_jobledger.year_num = pr_jobledger.year_num 
				LET pr_jobledger.period_num = pr_jobledger.period_num 
				LET pr_jobledger.job_code = pa_res_alloc[idx].job_code 
				LET pr_jobledger.var_code = pa_res_alloc[idx].var_code 
				LET pr_jobledger.activity_code = 
				pa_res_alloc[idx].activity_code 
				LET pr_jobledger.seq_num = pr_activity.seq_num 
				LET pr_jobledger.trans_type_ind = "RE" 
				LET pr_jobledger.trans_source_num = pr_jmparms.ra_num 
				LET pr_jobledger.trans_source_text = pr_jmresource.res_code 
				LET pr_jobledger.trans_amt = pa_res_alloc[idx].trans_amt 
				LET pr_jobledger.trans_qty = pa_res_alloc[idx].trans_qty 
				LET pr_jobledger.charge_amt = pa_res_alloc[idx].charge_amt 
				LET pr_jobledger.posted_flag = "N" 
				LET pr_jobledger.desc_text = pa_comment[idx].desc_text 
				IF pr_jobledger.desc_text IS NULL THEN 
					LET pr_jobledger.desc_text = pr_jmresource.desc_text 
				END IF 
				LET pr_jobledger.allocation_ind = pa_res_alloc[idx].allocation_ind 
				LET pr_jobledger.accrual_ind = "1" 
				LET pr_jobledger.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_jobledger.entry_date = today 
				INSERT INTO jobledger VALUES (pr_jobledger.*) 
				LET pr_activity.act_cost_amt = pr_activity.act_cost_amt + 
				pa_res_alloc[idx].trans_amt 
				LET pr_activity.post_revenue_amt = 
				pr_activity.post_revenue_amt + 
				pa_res_alloc[idx].charge_amt 
				IF (pr_activity.unit_code IS NULL AND pa_unit_code[idx] IS null) 
				OR pr_activity.unit_code = pa_unit_code[idx] THEN 
					LET pr_activity.act_cost_qty = 
					pr_activity.act_cost_qty + 
					pa_res_alloc[idx].trans_qty 
				END IF 
				LET err_message = "J7B Updating Activity" 
				CALL set_start(pr_jobledger.job_code, pr_jobledger.trans_date) 
				IF pr_activity.act_start_date IS NULL OR 
				pr_activity.act_start_date > pr_jobledger.trans_date THEN 
					UPDATE activity 
					SET act_start_date = pr_jobledger.trans_date, 
					act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE CURRENT OF act_upd 
				ELSE 
					UPDATE activity 
					SET act_cost_amt = pr_activity.act_cost_amt, 
					act_cost_qty = pr_activity.act_cost_qty, 
					post_revenue_amt = pr_activity.post_revenue_amt, 
					seq_num = pr_activity.seq_num 
					WHERE CURRENT OF act_upd 
				END IF 
			END IF 

		END FOR 
	COMMIT WORK 
	WHENEVER ERROR stop 
	FOR pr_counter = 1 TO arr_count() 
		INITIALIZE pa_comment[pr_counter].* TO NULL 
	END FOR 
	LET msgresp = kandoomsg("J",1556,pr_jmparms.ra_num) 
	#1554 Successful Addition. Enter another Resource Accrual?
	IF msgresp = "N" THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION default_values() 
	IF pa_res_alloc[idx].trans_qty IS NULL THEN 
		# There has been an INSERT
		IF pa_res_alloc[idx].var_code IS NULL THEN 
			LET pa_res_alloc[idx].var_code = 0 
		END IF 
		LET pa_unit_code[idx] = pr_jmresource.unit_code 
		LET pa_res_alloc[idx].trans_qty = 0 
		LET pa_res_alloc[idx].unit_cost_amt = pr_jmresource.unit_cost_amt 
		LET pa_res_alloc[idx].unit_bill_amt = pr_jmresource.unit_bill_amt 
		LET pa_res_alloc[idx].trans_amt = 0 
		LET pa_res_alloc[idx].charge_amt = 0 
		LET pa_res_alloc[idx].allocation_ind = pr_jmresource.allocation_ind 
		DISPLAY pa_res_alloc[idx].var_code, 
		pa_res_alloc[idx].trans_qty, 
		pa_res_alloc[idx].unit_cost_amt, 
		pa_res_alloc[idx].unit_bill_amt, 
		pa_res_alloc[idx].trans_amt, 
		pa_res_alloc[idx].charge_amt, 
		pa_res_alloc[idx].allocation_ind 
		TO activity[scrn].var_code, 
		jobledger[scrn].trans_qty, 
		jmresource[scrn].unit_cost_amt, 
		jmresource[scrn].unit_bill_amt, 
		jobledger[scrn].trans_amt, 
		jobledger[scrn].charge_amt, 
		jmresource[scrn].allocation_ind 

	END IF 
END FUNCTION 
