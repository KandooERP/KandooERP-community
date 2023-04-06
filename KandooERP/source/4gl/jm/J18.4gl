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

	Source code beautified by beautify.pl on 2020-01-02 19:48:02	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J18 Scan Ledger with Job AND Activity

GLOBALS 
	DEFINE 
	pa_jobledger array[500] OF RECORD 
		trans_type_ind LIKE jobledger.trans_type_ind, 
		seq_num LIKE jobledger.seq_num, 
		trans_date LIKE jobledger.trans_date, 
		trans_source_num LIKE jobledger.trans_source_num, 
		trans_amt LIKE jobledger.trans_amt, 
		trans_qty LIKE jobledger.trans_qty, 
		charge_amt LIKE jobledger.charge_amt, 
		year_num LIKE jobledger.year_num, 
		period_num LIKE jobledger.period_num 
	END RECORD, 
	pr_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text 
	END RECORD, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	ans CHAR(1), 
	idx, scrn, cnt SMALLINT 
END GLOBALS 

MAIN 

	#Initial UI Init
	CALL setModuleId("J18") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	SELECT jmparms.* 
	INTO pr_jmparms.* 
	FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	jmparms.key_code = "1" 
	IF status = notfound THEN 
		ERROR " Must SET up JM Parameters first in JZP" 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j117 with FORM "J117" -- alch kd-747 
	CALL winDecoration_j("J117") -- alch kd-747 
	CASE 
		WHEN num_args() = 3 
			LET pr_jobledger.job_code = arg_val(1) 
			LET pr_jobledger.activity_code = arg_val(2) 
			LET pr_jobledger.var_code = arg_val(3) 
			CALL disp_ledg() 
		WHEN num_args() = 0 
			WHILE get_trans() 
				CALL disp_ledg() 
				LET int_flag = false 
				LET quit_flag = false 
			END WHILE 
		OTHERWISE 
			LET msgresp = kandoomsg("J",7007,"") 
			#7007 " J18 called with Incorrect no of args"
			EXIT program 
	END CASE 
	CLOSE WINDOW j117 
END MAIN 


FUNCTION disp_ledg() 
	DEFINE where_text CHAR(500) 
	DEFINE query_text CHAR(1000) 
	DEFINE runner CHAR(200) 
	DEFINE l_arg1 STRING

	SELECT job.title_text, 
	activity.title_text, 
	customer.cust_code, 
	customer.name_text 
	INTO pr_job.title_text, 
	pr_activity.title_text, 
	pr_customer.cust_code, 
	pr_customer.name_text 
	FROM job, 
	activity, 
	customer 
	WHERE job.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND activity.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job.job_code = pr_jobledger.job_code 
	AND customer.cust_code = job.cust_code 
	AND activity.job_code = pr_jobledger.job_code 
	AND activity.activity_code = pr_jobledger.activity_code 
	AND activity.var_code = pr_jobledger.var_code 
	AND (job.locked_ind <= "1" 
	OR job.acct_code matches pr_user_scan_code) 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",7008,pr_jobledger.job_code ) 
		#7008 "  No Activities Exist FOR Job :",
		EXIT program 
	END IF 
	DISPLAY pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_jobledger.job_code, 
	pr_job.title_text, 
	pr_jobledger.var_code, 
	pr_jobledger.activity_code, 
	pr_activity.title_text 
	TO customer.cust_code, 
	customer.name_text, 
	job.job_code, 
	job.title_text, 
	activity.var_code, 
	activity.activity_code, 
	activity.title_text 

	LET msgresp = kandoomsg("U",1001,"") 
	##1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON 
	trans_type_ind, 
	trans_date, 
	period_num, 
	year_num, 
	trans_source_num, 
	trans_qty, 
	trans_amt, 
	charge_amt, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J18","const-trans_type_ind-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET query_text = 
	"SELECT trans_date,", 
	"trans_type_ind,", 
	"trans_source_num,", 
	"desc_text,", 
	"trans_amt,", 
	"trans_qty,", 
	"charge_amt,", 
	"year_num,", 
	"period_num,", 
	"seq_num ", 
	"FROM jobledger,", 
	"job ", 
	"WHERE jobledger.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND job.cmpy_code = jobledger.cmpy_code ", 
	"AND jobledger.job_code = \"",pr_jobledger.job_code,"\" ", 
	"AND job.job_code = \"",pr_jobledger.job_code,"\" ", 
	"AND var_code = \"",pr_jobledger.var_code,"\" ", 
	"AND activity_code = \"",pr_jobledger.activity_code,"\" ", 
	"AND ",where_text clipped," ", 
	"ORDER BY seq_num" 
	PREPARE q_jobledg FROM query_text 
	DECLARE c_jobledg CURSOR FOR q_jobledg 
	LET cnt = 0 
	OPEN c_jobledg 
	FETCH c_jobledg INTO 
	pr_jobledger.trans_date, 
	pr_jobledger.trans_type_ind, 
	pr_jobledger.trans_source_num, 
	pr_jobledger.desc_text, 
	pr_jobledger.trans_amt, 
	pr_jobledger.trans_qty, 
	pr_jobledger.charge_amt, 
	pr_jobledger.year_num, 
	pr_jobledger.period_num, 
	pr_jobledger.seq_num 
	WHILE status <> notfound 
		LET cnt = cnt + 1 
		IF cnt > 500 THEN 
			LET msgresp = kandoomsg("U",9100,cnt) 
			#9100 " Only first 500  Transactions Selected"
			LET cnt = 500 
			EXIT WHILE 
		END IF 
		LET pa_jobledger[cnt].trans_date = pr_jobledger.trans_date 
		LET pa_jobledger[cnt].seq_num = pr_jobledger.seq_num 
		LET pa_jobledger[cnt].trans_type_ind = 
		pr_jobledger.trans_type_ind 
		LET pa_jobledger[cnt].trans_source_num = 
		pr_jobledger.trans_source_num 
		LET pa_jobledger[cnt].trans_amt = pr_jobledger.trans_amt 
		LET pa_jobledger[cnt].trans_qty = pr_jobledger.trans_qty 
		LET pa_jobledger[cnt].charge_amt = pr_jobledger.charge_amt 
		LET pa_jobledger[cnt].year_num = pr_jobledger.year_num 
		LET pa_jobledger[cnt].period_num = pr_jobledger.period_num 
		FETCH c_jobledg INTO pr_jobledger.trans_date, 
		pr_jobledger.trans_type_ind, 
		pr_jobledger.trans_source_num, 
		pr_jobledger.desc_text, 
		pr_jobledger.trans_amt, 
		pr_jobledger.trans_qty, 
		pr_jobledger.charge_amt, 
		pr_jobledger.year_num, 
		pr_jobledger.period_num, 
		pr_jobledger.seq_num 
	END WHILE 
	IF cnt = 0 THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101 "No Transactions Satisfy this Selection Criteria" AT 1,1
		RETURN 
	END IF 
	CALL set_count(cnt) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET msgresp = kandoomsg("J",1013,"") 
	#1013 Tab TO view source document
	INPUT ARRAY pa_jobledger WITHOUT DEFAULTS FROM sr_jobledger.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J18","input_arr-pa_jobledger-1") -- alch kd-506 

		BEFORE ROW 
			#BEFORE FIELD trans_type_ind
			LET cnt = arr_curr() 
			IF pa_jobledger[cnt].trans_type_ind = "VO" OR 
			pa_jobledger[cnt].trans_type_ind = "DB" OR 
			pa_jobledger[cnt].trans_type_ind = "RE" OR 
			pa_jobledger[cnt].trans_type_ind = "TS" OR 
			pa_jobledger[cnt].trans_type_ind = "AD" OR 
			pa_jobledger[cnt].trans_type_ind = "PU" OR 
			pa_jobledger[cnt].trans_type_ind = "IS" THEN 
				SELECT desc_text INTO pr_jobledger.desc_text 
				FROM jobledger 
				WHERE trans_type_ind = pa_jobledger[cnt].trans_type_ind 
				AND seq_num = pa_jobledger[cnt].seq_num 
				AND job_code = pr_jobledger.job_code 
				AND var_code = pr_jobledger.var_code 
				AND activity_code = pr_jobledger.activity_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				DISPLAY BY NAME pr_jobledger.desc_text 
			ELSE 
			END IF 
			--- modif ericv init #AFTER FIELD trans_type_ind
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD trans_date
			--#END IF


		BEFORE FIELD trans_date 
			LET cnt = arr_curr() 
			CASE 
				WHEN pa_jobledger[cnt].trans_type_ind = "VO" 
					LET runner = " vouch_code = ",pa_jobledger[cnt].trans_source_num
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner) 
					CALL run_prog("P25",l_arg1,"","","") 
					
				WHEN pa_jobledger[cnt].trans_type_ind = "DB" 
					LET runner = " debit_num = ",pa_jobledger[cnt].trans_source_num
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner) 
					CALL run_prog("P65",l_arg1,"","","") 
					
				WHEN pa_jobledger[cnt].trans_type_ind = "RE" 
					CALL run_prog("J76",pa_jobledger[cnt].trans_source_num,"","","") 
					
				WHEN pa_jobledger[cnt].trans_type_ind = "AD" 
					CALL run_prog("J25",pa_jobledger[cnt].trans_source_num,"","","")
					 
				WHEN pa_jobledger[cnt].trans_type_ind = "TS" 
					CALL run_prog("J84",pa_jobledger[cnt].trans_source_num,"","","")
					 
				WHEN pa_jobledger[cnt].trans_type_ind = "PU" 
					CALL run_prog("R16",pa_jobledger[cnt].trans_source_num,"","","")
					 
				WHEN pa_jobledger[cnt].trans_type_ind = "IS" 
					LET runner = "jobledger.trans_source_num = ", pa_jobledger[cnt].trans_source_num
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner) 
					CALL run_prog("J92",l_arg1,"","","")
					 
			END CASE 
			
			NEXT FIELD trans_type_ind 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 


FUNCTION get_trans() 
	CLEAR FORM 
	LET msgresp = kandoomsg("J",1421,"") 
	#1421 Enter Job/Activity details
	INPUT BY NAME pr_jobledger.job_code, 
	pr_jobledger.var_code, 
	pr_jobledger.activity_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J18","input-pr_jobledger-1") -- alch kd-506 
		
		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET pr_jobledger.job_code = 
					showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
					DISPLAY pr_jobledger.job_code 
					TO job_code 

				WHEN infield (var_code) 
					LET pr_jobledger.var_code = 
					show_jobvars(glob_rec_kandoouser.cmpy_code, pr_jobledger.job_code) 
					DISPLAY pr_jobledger.var_code 
					TO var_code 

				WHEN infield (activity_code) 
					LET pr_jobledger.activity_code = 
					show_activity(glob_rec_kandoouser.cmpy_code, pr_jobledger.job_code, 
					pr_jobledger.var_code) 
					DISPLAY pr_jobledger.activity_code 
					TO activity_code 

			END CASE 
		AFTER FIELD job_code 
			IF pr_jobledger.job_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9508,"") 
				#9508 "Job Code must be entered"
				NEXT FIELD job_code 
			END IF 
			SELECT count(*) 
			INTO cnt 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job.job_code = pr_jobledger.job_code 
			AND (job.locked_ind <= "1" 
			OR job.acct_code matches pr_user_scan_code) 
			IF cnt = 0 THEN 
				LET msgresp = kandoomsg("J",9508,"") 
				#9508 "Job Code must be entered"
				NEXT FIELD job_code 
			END IF 
		AFTER FIELD var_code 
			IF pr_jobledger.var_code IS NULL 
			OR pr_jobledger.var_code = 0 THEN 
				LET pr_jobledger.var_code = 0 
				DISPLAY BY NAME pr_jobledger.var_code 

				NEXT FIELD activity_code 
			ELSE 
				SELECT count(*) 
				INTO cnt 
				FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_jobledger.job_code 
				AND var_code = pr_jobledger.var_code 
				IF cnt = 0 THEN 
					LET msgresp = kandoomsg("J",9510,"") 
					#9510 "Var Code must be entered"
					ERROR " Variation NOT found, use window FOR help" 
					NEXT FIELD job_code 
				END IF 
			END IF 
		AFTER FIELD activity_code 
			IF pr_jobledger.activity_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9511,"") 
				#9511 "Var Code must be entered"
				NEXT FIELD job_code 
			END IF 
			SELECT count(*) 
			INTO cnt 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_jobledger.job_code 
			AND var_code = pr_jobledger.var_code 
			AND activity_code = pr_jobledger.activity_code 
			IF cnt = 0 THEN 
				LET msgresp = kandoomsg("J",9512,"") 
				#9512 "Var Code must be entered"
				NEXT FIELD job_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
