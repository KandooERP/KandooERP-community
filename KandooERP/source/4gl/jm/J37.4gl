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

	Source code beautified by beautify.pl on 2020-01-02 19:48:07	$Id: $
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
# \brief module J37 Scan resbill FOR sales AND cost of sales with job AND activity
#

GLOBALS 

	DEFINE 
	pa_resbill ARRAY [1000] OF RECORD #1644 
		seq_num LIKE resbill.seq_num, 
		tran_date LIKE resbill.tran_date, 
		tran_type CHAR(1), 
		inv_num LIKE resbill.inv_num, 
		desc_text LIKE resbill.desc_text, 
		apply_amt LIKE resbill.apply_amt 
	END RECORD, 
	p_apply_cos_amt LIKE resbill.apply_cos_amt, 
	p_year_num, 
	p_period_num INTEGER, 
	pr_customer RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text 
	END RECORD, 
	pr_resbill RECORD LIKE resbill.*, 
	pr_job RECORD LIKE job.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	another, 
	ans CHAR(1), 
	err_message CHAR(40), 
	where_text CHAR(500), 
	runner CHAR(200), 
	found_one, 
	idx, 
	scrn, 
	cnt SMALLINT 
END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("J37") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	CALL doit() 
	CLOSE WINDOW j159 
END MAIN 


FUNCTION doit() 
	OPEN WINDOW j159 with FORM "J159" -- alch kd-747 
	CALL winDecoration_j("J159") -- alch kd-747 
	CASE 
		WHEN num_args() > 2 
			LET pr_resbill.job_code = arg_val(1) 
			LET pr_resbill.activity_code = arg_val(2) 
			LET pr_resbill.var_code = arg_val(3) 
			LET where_text = "1=1" 
			CALL disp_ledg() 
		WHEN num_args() = 0 
			WHILE true 
				LET int_flag = false 
				LET quit_flag = false 
				IF NOT get_selection() THEN 
					EXIT WHILE 
				END IF 
				CALL disp_ledg() 
			END WHILE 
		OTHERWISE 
			ERROR " J37 called with incorrect no of args" 
			--         prompt " Note error AND proceed with any key"  -- albo
			--            FOR CHAR ans
			--DISPLAY "" at 4,4 
			CALL eventsuspend() --LET ans = AnyKey("Note error AND proceed with any key") -- albo 
			EXIT program 
	END CASE 
END FUNCTION 


FUNCTION disp_ledg() 
	DEFINE 
	query_text CHAR(1500) 

	SELECT job.title_text, 
	activity.title_text, 
	customer.cust_code, 
	customer.name_text INTO pr_job.title_text, 
	pr_activity.title_text, 
	pr_customer.cust_code, 
	pr_customer.name_text 
	FROM job, 
	activity, 
	customer 
	WHERE job.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job.job_code = pr_resbill.job_code 
	AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = job.cust_code 
	AND activity.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND activity.job_code = pr_resbill.job_code 
	AND activity.activity_code = pr_resbill.activity_code 
	AND activity.var_code = pr_resbill.var_code 
	IF status = notfound THEN 
		#ERROR "No activities FOR that job, activity, client "
		#.prompt " Any key TO proceed " FOR CHAR ans
		#EXIT PROGRAM
		LET msgresp = kandoomsg("J", 9572, " ") 
		RETURN 
	END IF 
	DISPLAY pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_resbill.job_code, 
	pr_job.title_text, 
	pr_resbill.var_code, 
	pr_resbill.activity_code, 
	pr_activity.title_text 
	TO customer.cust_code, 
	customer.name_text, 
	resbill.job_code, 
	job.title_text, 
	resbill.var_code, 
	resbill.activity_code, 
	activity.title_text 

	IF num_args() = 0 THEN 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria; OK TO Continue
		CONSTRUCT BY NAME where_text ON 
		resbill.seq_num, 
		resbill.tran_date, 
		resbill.inv_num, 
		resbill.desc_text, 
		resbill.apply_amt 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","J37","const-seq_num-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
	END IF 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database; Please Wait
	LET query_text = "SELECT resbill.seq_num, invoicehead.inv_date, 'I', ", 
	" invoicehead.inv_num, resbill.desc_text, ", 
	" sum(resbill.apply_amt), sum(apply_cos_amt), ", 
	" invoicehead.year_num, invoicehead.period_num ", 
	" FROM resbill, invoicehead ", 
	" WHERE resbill.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND resbill.job_code = '",pr_resbill.job_code,"' ", 
	" AND resbill.activity_code = '", 
	pr_resbill.activity_code,"' ", 
	" AND resbill.var_code = ",pr_resbill.var_code," ", 
	" AND invoicehead.cmpy_code = resbill.cmpy_code ", 
	" AND invoicehead.inv_num = resbill.inv_num ", 
	" AND resbill.tran_type_ind in ('1','2') ", 
	" AND ",where_text clipped," ", 
	" group by resbill.seq_num, invoicehead.inv_date, ", 
	" invoicehead.inv_num, resbill.desc_text, ", 
	" invoicehead.year_num, invoicehead.period_num ", 
	" ORDER BY resbill.seq_num, invoicehead.inv_date, ", 
	" invoicehead.inv_num " 
	PREPARE s_invoice FROM query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	LET found_one = false 
	LET cnt = 1 
	FOREACH c_invoice INTO pa_resbill[cnt].seq_num, 
		pa_resbill[cnt].tran_date, 
		pa_resbill[cnt].tran_type, 
		pa_resbill[cnt].inv_num, 
		pa_resbill[cnt].desc_text, 
		pa_resbill[cnt].apply_amt, 
		p_apply_cos_amt, 
		p_year_num, 
		p_period_num 
		#1644 - Only increment count IF VALUES are NOT zero
		IF pa_resbill[cnt].apply_amt != 0 
		OR p_apply_cos_amt != 0 THEN 
			LET found_one = true 
			LET cnt = cnt + 1 
		ELSE 
			CONTINUE FOREACH 
		END IF 
		IF cnt > 1000 THEN 
			#ERROR "Only first 1000 selected"
			LET msgresp = kandoomsg("A", 9528, " ") 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	#Add credits
	LET query_text = " SELECT resbill.seq_num, credithead.cred_date, 'C', ", 
	" credithead.cred_num, resbill.desc_text, ", 
	" sum(resbill.apply_amt), sum(apply_cos_amt), ", 
	" credithead.year_num, credithead.period_num ", 
	" FROM resbill, credithead ", 
	" WHERE resbill.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND resbill.job_code = '",pr_resbill.job_code,"' ", 
	" AND resbill.activity_code = '", 
	pr_resbill.activity_code,"' ", 
	" AND resbill.var_code = '",pr_resbill.var_code,"' ", 
	" AND resbill.tran_type_ind = '3' ", 
	" AND credithead.cmpy_code = resbill.cmpy_code ", 
	" AND credithead.cred_num = resbill.inv_num ", 
	" AND ",where_text clipped," ", 
	" group by resbill.seq_num, credithead.cred_date, ", 
	" credithead.cred_num, resbill.desc_text, ", 
	" credithead.year_num, credithead.period_num ", 
	" ORDER BY resbill.seq_num, credithead.cred_date, ", 
	" credithead.cred_num " 
	PREPARE s_credit FROM query_text 
	DECLARE c_credit CURSOR FOR s_credit 
	FOREACH c_credit INTO pa_resbill[cnt].seq_num, 
		pa_resbill[cnt].tran_date, 
		pa_resbill[cnt].tran_type, 
		pa_resbill[cnt].inv_num, 
		pa_resbill[cnt].desc_text, 
		pa_resbill[cnt].apply_amt, 
		p_apply_cos_amt, 
		p_year_num, 
		p_period_num 
		IF pa_resbill[cnt].apply_amt != 0 
		OR p_apply_cos_amt != 0 THEN 
			LET found_one = true 
			LET cnt = cnt + 1 
		ELSE 
			CONTINUE FOREACH 
		END IF 
		IF cnt > 1000 THEN 
			#ERROR "Only first 1000 selected"
			LET msgresp = kandoomsg("A", 9528, " ") 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET cnt = cnt - 1 
	IF found_one = false THEN 
		#ERROR "No resource billing records found"
		LET msgresp = kandoomsg("J", 9593, " ") 
		SLEEP 3 
		RETURN 
	END IF 
	CALL set_count(cnt) 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	LET msgresp = kandoomsg("U",1008,"") 
	#F3/F4 TO Page Up/Down; OK TO Continue
	DISPLAY ARRAY pa_resbill TO sr_resbill.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J37","display-arr-resbill") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-w) 
			CALL kandoohelp("") 
	END DISPLAY 

	CLEAR FORM 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 


FUNCTION get_selection() 
	IF found_one = true THEN 
		LET pr_resbill.job_code = " " 
		LET pr_resbill.var_code = " " 
		LET pr_resbill.activity_code = " " 
	END IF 
	DISPLAY BY NAME pr_resbill.job_code, 
	pr_resbill.var_code, 
	pr_resbill.activity_code 

	LET msgresp = kandoomsg("U",1020,TRAN_TYPE_JOB_JOB) 
	#1001 "Enter selection criteria, DEL TO EXIT"
	INPUT BY NAME pr_resbill.job_code, 
	pr_resbill.var_code, 
	pr_resbill.activity_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J37","input-pr_resbill-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(job_code) 
					LET pr_resbill.job_code = show_job(glob_rec_kandoouser.cmpy_code) 
					DISPLAY pr_resbill.job_code TO job_code 

				WHEN infield(var_code) 
					LET pr_resbill.var_code = show_jobvars(glob_rec_kandoouser.cmpy_code, pr_resbill.job_code) 
					DISPLAY pr_resbill.var_code TO var_code 

				WHEN infield(activity_code) 
					LET pr_resbill.activity_code = show_activity(glob_rec_kandoouser.cmpy_code, 
					pr_resbill.job_code , 
					pr_resbill.var_code ) 
					DISPLAY pr_resbill.activity_code TO activity_code 

			END CASE 
		AFTER FIELD job_code 
			IF pr_resbill.job_code IS NULL THEN 
				#ERROR "Job Code must be entered"
				LET msgresp = kandoomsg("J", 9508, " ") 
				NEXT FIELD job_code 
			END IF 
			SELECT count(*)INTO cnt 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job.job_code = pr_resbill.job_code 
			IF cnt = 0 THEN 
				#ERROR " Job NOT found, use window FOR help"
				LET msgresp = kandoomsg("J", 9558, " ") 
				NEXT FIELD job_code 
			ELSE 
				NEXT FIELD var_code 
			END IF 
		AFTER FIELD var_code 
			IF pr_resbill.var_code IS NULL 
			OR pr_resbill.var_code = 0 THEN 
				LET pr_resbill.var_code = 0 
				DISPLAY pr_resbill.var_code TO var_code 

				NEXT FIELD activity_code 
			ELSE 
				SELECT count(*)INTO cnt 
				FROM jobvars 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_resbill.job_code 
				AND var_code = pr_resbill.var_code 
				IF cnt = 0 THEN 
					LET msgresp = kandoomsg("J",9510,0) 
					#ERROR " Variation NOT found, use window FOR help"
					NEXT FIELD var_code 
				ELSE 
					NEXT FIELD activity_code 
				END IF 
			END IF 
		AFTER FIELD activity_code 
			IF pr_resbill.activity_code IS NULL THEN 
				LET msgresp = kandoomsg("J",9647,0) 
				#ERROR " Activity Code must be entered"
				NEXT FIELD activity_code 
			END IF 
			SELECT count(*)INTO cnt 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_resbill.job_code 
			AND var_code = pr_resbill.var_code 
			AND activity_code = pr_resbill.activity_code 
			IF cnt = 0 THEN 
				LET msgresp = kandoomsg("J",9512,0) 
				#ERROR " Activity NOT found, use window FOR help"
				NEXT FIELD activity_code 
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
