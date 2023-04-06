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
# \brief module J76 Inquire on resource allocation (based upon J75)
############################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS "../jm/J7_GROUP_GLOBALS.4gl" 
GLOBALS "../jm/J76_GLOBALS.4gl"


MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("J76") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_j_jm() #init a/ar module/program 
	--CALL J76_main()

	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("U",5110,"") 	#5110 Job Management Parameters Not Set Up;  Refer Menu RZP.
		EXIT program 
	END IF 
	
	SELECT glparms.* 
	INTO pr_glparms.* 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("G",5001,"") #5107 General Ledger Parameters Not Set Up;  Refer Menu GZP.
		EXIT program 
	END IF 
	OPEN WINDOW j122 with FORM "J122" -- alch kd-747 
	CALL winDecoration_j("J122") -- alch kd-747 
	LET pr_text = kandooword("Comments:", "052") 
	WHILE get_resource() 
		CALL disp_resource() 
	END WHILE 
	CLOSE WINDOW j122 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 


FUNCTION get_resource() 
	DEFINE 
	cnt SMALLINT, 
	str CHAR (3000) 

	WHILE true 
		CLEAR FORM 
		IF num_args() > 0 THEN 
			LET pr_jobledger.trans_source_num = arg_val(1) 
		ELSE 
			LET msgresp = kandoomsg("U",1058,"Resource Allocation Number") 
			#1058 Enter Resource Allocation Number;  OK TO Continue.
			INPUT BY NAME pr_jobledger.trans_source_num WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","J76","input-pr_jobledger-1") -- alch kd-506 

				AFTER FIELD trans_source_num 
					IF pr_jobledger.trans_source_num IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD trans_source_num 
					END IF 
				ON KEY (control-b) 
					CASE 
						WHEN infield(trans_source_num) 
							CALL scan_jobledge() 
							RETURNING pr_jobledger.trans_source_num 
							DISPLAY BY NAME pr_jobledger.trans_source_num 

					END CASE 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
		DECLARE a_curs CURSOR FOR 
		SELECT job_code, var_code, activity_code, trans_qty, 
		trans_amt, charge_amt, desc_text, trans_source_text, 
		trans_date, year_num, period_num, trans_source_num 
		FROM jobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_type_ind = "RE" 
		AND trans_source_num = pr_jobledger.trans_source_num 
		LET arr_size = 0 
		LET cnt = 1 
		FOREACH a_curs INTO pa_res_alloc[cnt].job_code, 
			pa_res_alloc[cnt].var_code, 
			pa_res_alloc[cnt].activity_code, 
			pa_res_alloc[cnt].trans_qty, 
			pa_res_alloc[cnt].trans_amt, 
			pa_res_alloc[cnt].charge_amt, 
			pa_desc[cnt].desc_text, 
			pr_jmresource.res_code, 
			pr_jobledger.trans_date, 
			pr_jobledger.year_num, 
			pr_jobledger.period_num, 
			pr_jobledger.trans_source_num 
			IF pa_desc[cnt].desc_text IS NOT NULL THEN 
				LET pa_desc[cnt].desc_prompt = pr_text 
			END IF 
			IF pa_res_alloc[cnt].trans_qty = 0 THEN 
				SELECT unit_cost_amt, 
				unit_bill_amt 
				INTO pa_res_alloc[cnt].unit_cost_amt, 
				pa_res_alloc[cnt].unit_bill_amt 
				FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jmresource.res_code 
			ELSE 
				LET pa_res_alloc[cnt].unit_cost_amt = 
				pa_res_alloc[cnt].trans_amt / 
				pa_res_alloc[cnt].trans_qty 
				LET pa_res_alloc[cnt].unit_bill_amt = 
				pa_res_alloc[cnt].charge_amt / 
				pa_res_alloc[cnt].trans_qty 
			END IF 
			LET arr_size = arr_size + 1 
			LET cnt = cnt + 1 
			IF cnt > 300 THEN 
				LET msgresp = kandoomsg("U",1505,arr_size) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF arr_size = 0 THEN 
			LET msgresp = kandoomsg("J",1521,"") 
			#1521 Allocation number does NOT exist.
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 


	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
	DISPLAY "see jm/J76.4gl" 
	EXIT program (1) 


	LET str = 
	" SELECT jmresource.*, coa.* ", 
	" INTO pr_jmresource.*, pr_coa.* ", 
	" FROM jmresource, outer coa ", 
	" WHERE jmresource.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
	" AND res_code = ", pr_jmresource.res_code, 
	" AND coa.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
	" AND coa.acct_code = jmresource.acct_code " 

	EXECUTE immediate str 

	SELECT actiunit.* INTO pr_actiunit.* 
	FROM actiunit 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND unit_code = pr_jmresource.unit_code 

	DISPLAY BY NAME 
	pr_jmresource.res_code, 
	pr_jmresource.unit_code, 
	pr_jmresource.cost_ind, 
	pr_jmresource.bill_ind, 
	pr_jobledger.trans_source_num, 
	pr_jobledger.trans_date, 
	pr_jobledger.year_num, 
	pr_jobledger.period_num 

	DISPLAY pr_jmresource.desc_text, 
	pr_actiunit.desc_text, 
	pr_jmresource.unit_cost_amt, 
	pr_jmresource.unit_bill_amt 
	TO res_desc_text, 
	unit_desc_text, 
	unit_cost_rate, 
	unit_bill_rate 

	RETURN true 
END FUNCTION 


FUNCTION disp_resource() 
	DEFINE 
	pr_job_code LIKE jobledger.job_code, 
	pr_tot_trans_qty DECIMAL(10,2), 
	pr_avg_rate_amt DECIMAL(12,4), 
	pr_tot_cost_amt DECIMAL(16,2), 
	pr_tot_charge_amt DECIMAL(16,2), 
	scrn, cnt SMALLINT 

	LET pr_tot_trans_qty = 0 
	LET pr_avg_rate_amt = 0 
	LET pr_tot_cost_amt = 0 
	LET pr_tot_charge_amt = 0 
	FOR cnt = 1 TO arr_size 
		LET pr_tot_trans_qty = pr_tot_trans_qty + 
		pa_res_alloc[cnt].trans_qty 
		LET pr_tot_cost_amt = pr_tot_cost_amt + 
		pa_res_alloc[cnt].trans_amt 
		LET pr_tot_charge_amt = pr_tot_charge_amt + 
		pa_res_alloc[cnt].charge_amt 
	END FOR 
	IF pr_tot_trans_qty = 0 THEN 
		LET pr_tot_trans_qty = 1 
	END IF 
	LET pr_avg_rate_amt = pr_tot_cost_amt / pr_tot_trans_qty 
	DISPLAY pr_tot_trans_qty, 
	pr_avg_rate_amt, 
	pr_tot_cost_amt, 
	pr_tot_charge_amt 
	TO tot_trans_qty, 
	avg_rate_amt, 
	tot_cost_amt, 
	tot_charge_amt 

	LET msgresp = kandoomsg("J",1507,"") 
	#1507 F3/F4 Page Fwd/Bwd;  OK TO Continue.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(arr_size) 
	INPUT ARRAY pa_res_alloc WITHOUT DEFAULTS FROM sr_res_alloc.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J76","input_arr-pa_res_alloc-1") -- alch kd-506 

		BEFORE ROW 
			LET cnt = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_desc[cnt].desc_prompt TO desc_prompt 
			attribute(white) 
			DISPLAY pa_desc[cnt].desc_text TO desc_text 

			DISPLAY pa_res_alloc[cnt].* TO sr_res_alloc[scrn].* 

		BEFORE FIELD job_code 
			LET pr_job_code = pa_res_alloc[cnt].job_code 
		AFTER FIELD job_code 
			LET pa_res_alloc[cnt].job_code = pr_job_code 
			IF (fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down")) 
			AND arr_curr() = arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD job_code 
			END IF 
		BEFORE FIELD var_code 
			NEXT FIELD job_code 
		AFTER ROW 
			DISPLAY pa_res_alloc[cnt].* TO sr_res_alloc[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF num_args() = 0 
	AND int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 

#FUNCTION scan_joblede (Based on J15)
FUNCTION scan_jobledge() 
	DEFINE 
	where_part, query_text CHAR(500) 

--	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 
--	RETURNING pr_rec_kandoouser.acct_mask_code, 
--	pr_user_scan_code 

	OPEN WINDOW J133 with FORM "J133" -- alch kd-747 
	CALL winDecoration_j("J133") -- alch kd-747 
	CLEAR FORM 
	
	LET msgresp = kandoomsg("U",1001,"")	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME where_part ON 
	jobledger.job_code, 
	jobledger.var_code, 
	jobledger.activity_code, 
	jobledger.trans_type_ind, 
	jobledger.trans_date, 
	jobledger.trans_source_num, 
	jobledger.trans_source_text, 
	jobledger.trans_amt, 
	jobledger.year_num, 
	jobledger.period_num, 
	jobledger.posted_flag 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J76","const-jobledger_job_code-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW j133 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.
	LET query_text = 
	"SELECT jobledger.* ", 
	"FROM jobledger,", 
	"job ", 
	"WHERE job.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND jobledger.cmpy_code = job.cmpy_code ", 
	"AND jobledger.trans_type_ind = 'RE' ", 
	"AND job.job_code = jobledger.job_code ", 
	"AND (job.locked_ind <= '1' ", 
	"OR job.acct_code matches '",glob_rec_kandoouser.acct_mask_code ,"') AND ",   # was pr_user_scan_code
	where_part clipped," ", 
	"ORDER BY job_code, var_code, activity_code, ", 
	"trans_type_ind, trans_source_num " 

	PREPARE s_jobledg FROM query_text 
	DECLARE c_jobledg CURSOR FOR s_jobledg 
	LET idx = 0 
	FOREACH c_jobledg INTO pr_jobledger.* 
		LET idx = idx + 1 
		LET pa_jobledger[idx].job_code = pr_jobledger.job_code 
		LET pa_jobledger[idx].var_code = pr_jobledger.var_code 
		LET pa_jobledger[idx].activity_code = 
		pr_jobledger.activity_code 
		LET pa_jobledger[idx].trans_type_ind = 
		pr_jobledger.trans_type_ind 
		LET pa_jobledger[idx].trans_date = pr_jobledger.trans_date 
		LET pa_jobledger[idx].trans_source_num = 
		pr_jobledger.trans_source_num 
		LET pa_jobledger[idx].trans_source_text = 
		pr_jobledger.trans_source_text 
		LET pa_jobledger[idx].trans_amt = pr_jobledger.trans_amt 
		LET pa_jobledger[idx].year_num = pr_jobledger.year_num 
		LET pa_jobledger[idx].period_num = pr_jobledger.period_num 
		LET pa_jobledger[idx].posted_flag = pr_jobledger.posted_flag 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			#6100 First 300 records selected only.  More may be available.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("A",1511,"") 
	#1511 OK TO Continue.
	CALL set_count(idx) 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("U",9506,"") 
		#9506 No Rows found FOR this Selection Criteria.
	END IF 
	DISPLAY ARRAY pa_jobledger TO sr_jobledger.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J76","display-arr-jobledger") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	LET idx = arr_curr() 
	CLOSE WINDOW j133 
	RETURN pa_jobledger[idx].trans_source_num 
END FUNCTION 
