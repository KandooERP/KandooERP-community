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

	Source code beautified by beautify.pl on 2020-01-02 19:48:12	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J7_GLOBALS.4gl" 
GLOBALS "J77_GLOBALS.4gl" 
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J78 (J7X !!!!) , Budgets AT Resource level



DEFINE 
fv_num_args, 
mv_res_edit_flag SMALLINT, 
ma_res_code ARRAY [51] OF RECORD 
	delete_flag CHAR(1), 
	res_code LIKE resbdgt.res_code, 
	desc_text LIKE jmresource.desc_text 
END RECORD, 
mv_sys_resbdgt_flg char, 
fv_unit_code LIKE jmresource.unit_code 


MAIN 
	#Initial UI Init
	CALL setModuleId("J7X") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) RETURNING pv_cmpy_code, pv_username -- albo 

	CALL user_security(pv_cmpy_code, pv_username) 
	RETURNING glob_rec_kandoouser.acct_mask_code, 
	pv_user_scan_code 
	LET mv_sys_resbdgt_flg = get_kandoooption_feature_state("JM", "W1") 
	OPEN WINDOW j198w with FORM "J198" -- alch kd-747 
	CALL winDecoration_j("J198") -- alch kd-747 
	INITIALIZE pr_resbdgt TO NULL 
	LET fv_num_args = num_args() 
	IF fv_num_args > 1 
	OR fv_num_args = 0 THEN 
		#ERROR "Invalid program parmeters SET. Enquiry Only"
		LET msgresp = kandoomsg("J", 9582, " ") 
		LET mv_res_edit_flag = false 
	ELSE 
		IF arg_val(1) = '2' THEN 
			LET mv_res_edit_flag = true 
		ELSE 
			IF arg_val(1) = '4' THEN 
				LET mv_res_edit_flag = false 
			ELSE 
				#ERROR "Invalid program parmeters SET. Enquiry Only"
				LET msgresp = kandoomsg("J", 9582, " ") 
				LET mv_res_edit_flag = false 
			END IF 
		END IF 
	END IF 
	WHILE get_job_info() 
		WHILE select_res_code() 
			INITIALIZE ma_res_code TO NULL 
		END WHILE 
		INITIALIZE pr_resbdgt, 
		pr_activity, 
		ma_res_code TO NULL 
	END WHILE 
	CLOSE WINDOW j198w 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 


FUNCTION get_job_info() 
	DEFINE 
	fr_job RECORD LIKE job.*, 
	fr_customer RECORD LIKE customer.*, 
	fv_status SMALLINT, 
	fv_count INTEGER 
	CLEAR FORM 
	LET fv_status = true 
	# MESSAGE "Enter Criteria - ESC TO continue - DEL TO Exit"

	LET msgresp = kandoomsg("J", 1421, " ") 
	LET pr_resbdgt.var_code = 0 
	INPUT BY NAME pr_resbdgt.job_code, 
	pr_resbdgt.var_code, 
	pr_resbdgt.activity_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7X","input-pr_resbdgt-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(job_code) 
					LET pr_resbdgt.job_code = showujobs(pv_cmpy_code, 
					glob_rec_kandoouser.acct_mask_code ) 
					SELECT job.title_text, 
					customer.cust_code, 
					customer.name_text INTO fr_job.title_text, 
					fr_customer.cust_code, 
					fr_customer.name_text 
					FROM job, 
					customer 
					WHERE job.cmpy_code = pv_cmpy_code 
					AND job_code = pr_resbdgt.job_code 
					AND customer.cmpy_code = pv_cmpy_code 
					AND customer.cust_code = job.cust_code 
					AND (job.acct_code matches pv_user_scan_code 
					OR job.locked_ind <= "1") 
					IF status = notfound THEN 
						#ERROR "No such Job Code.   Try window. "
						LET msgresp = kandoomsg("J", 9509, " ") 
						NEXT FIELD job_code 
					END IF 
					DISPLAY BY NAME pr_resbdgt.job_code, 
					fr_job.title_text, 
					fr_customer.cust_code, 
					fr_customer.name_text 

				WHEN infield(var_code) 
					LET pr_resbdgt.var_code = show_jobvars(pv_cmpy_code, 
					pr_resbdgt.job_code ) 
					DISPLAY BY NAME pr_resbdgt.var_code 

				WHEN infield(activity_code) 
					LET pr_resbdgt.activity_code = show_activity(pv_cmpy_code, 
					pr_resbdgt.job_code , 
					pr_resbdgt.var_code ) 
					DISPLAY BY NAME pr_resbdgt.activity_code 

				OTHERWISE 
					#ERROR " No browse avaliable FOR this FUNCTION.  "
					LET msgresp = kandoomsg("U", 9901, " ") 
			END CASE 
		AFTER FIELD job_code 
			IF pr_resbdgt.job_code IS NULL THEN 
				#ERROR "A Job Code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9508, " ") 
				NEXT FIELD job_code 
			END IF 
			SELECT job.title_text, 
			customer.cust_code, 
			customer.name_text INTO fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 
			FROM job, 
			customer 
			WHERE job.cmpy_code = pv_cmpy_code 
			AND job.job_code = pr_resbdgt.job_code 
			AND customer.cmpy_code = pv_cmpy_code 
			AND customer.cust_code = job.cust_code 
			AND (job.acct_code matches pv_user_scan_code 
			OR job.locked_ind <= "1") 
			IF status = notfound THEN 
				#ERROR "No such Job Code.   Try window. "
				LET msgresp = kandoomsg("J", 9509, " ") 
				NEXT FIELD job_code 
			END IF 
			DISPLAY BY NAME pr_resbdgt.job_code, 
			fr_job.title_text, 
			fr_customer.cust_code, 
			fr_customer.name_text 

		AFTER FIELD var_code 
			IF pr_resbdgt.var_code IS NULL THEN 
				#ERROR "A variation code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9545, " ") 
				NEXT FIELD var_code 
			END IF 
			IF NOT pr_resbdgt.var_code = 0 THEN 
				SELECT count(*)INTO fv_count 
				FROM jobvars 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				IF status = notfound 
				OR fv_count = 0 THEN 
					#ERROR "No such variation FOR Job Code.  "
					LET msgresp = kandoomsg("J", 9510, " ") 
					NEXT FIELD var_code 
				END IF 
			END IF 
			DISPLAY BY NAME pr_resbdgt.var_code 

		AFTER FIELD activity_code 
			IF pr_resbdgt.activity_code IS NULL THEN 
				#ERROR "Activity code must be entered.  Try window."
				LET msgresp = kandoomsg("J", 9511, " ") 
				NEXT FIELD activity_code 
			END IF 
			SELECT * INTO pr_activity.* 
			FROM activity 
			WHERE cmpy_code = pv_cmpy_code 
			AND activity_code = pr_resbdgt.activity_code 
			AND job_code = pr_resbdgt.job_code 
			AND var_code = pr_resbdgt.var_code 
			IF status = notfound THEN 
				# ERROR "Activity code must exist FOR this job AND variation.  ",
				#       "Try window.  "
				LET msgresp = kandoomsg("J", 9512, " ") 
				NEXT FIELD job_code 
			END IF 
			DISPLAY pr_resbdgt.activity_code, 
			pr_activity.title_text TO activity_code, 
			activity_desc 

		AFTER INPUT 
			IF int_flag 
			OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_resbdgt.job_code IS NULL THEN 
				#ERROR " A job code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9508, " ") 
				NEXT FIELD job_code 
			END IF 
			IF pr_resbdgt.var_code IS NULL THEN 
				#ERROR " A variation code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9545, " ") 
				NEXT FIELD var_code 
			END IF 
			IF pr_resbdgt.activity_code IS NULL THEN 
				#ERROR " An activity code must be entered.  Try window.  "
				LET msgresp = kandoomsg("J", 9511, " ") 
				NEXT FIELD job_code 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_status = false 
	END IF 

	RETURN fv_status 
END FUNCTION 


FUNCTION select_res_code() 
	DEFINE 
	query_text CHAR(1000), 
	idx, 
	scrn, 
	res_array_size, 
	res_delete_cnt SMALLINT, 
	fv_res_desc_text LIKE jmresource.desc_text, 
	fv_status, 
	ans CHAR 
	# MESSAGE " Enter Selection Criteria - ESC TO Continue"

	LET msgresp = kandoomsg("U", 1001, " ") 
	FOR idx = 1 TO 10 
		DISPLAY ma_res_code[idx].res_code, 
		ma_res_code[idx].desc_text TO sa_res[idx].res_code, 
		sa_res[idx].desc_text 
	END FOR 
	CONSTRUCT pv_query_1 ON 
	resbdgt.res_code, 
	jmresource.desc_text 
	FROM 
	res_code, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J7X","const-resbdgt_res_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT resbdgt.res_code, ", 
	" jmresource.desc_text ", 
	"FROM jmresource, resbdgt ", 
	"WHERE jmresource.cmpy_code = '", pv_cmpy_code, "' ", 
	"AND jmresource.res_code = resbdgt.res_code ", 
	"AND resbdgt.cmpy_code = '", pv_cmpy_code, "' ", 
	"AND resbdgt.job_code = '", pr_resbdgt.job_code, "' ", 
	"AND resbdgt.var_code = '", pr_resbdgt.var_code, "' ", 
	"AND resbdgt.activity_code = '", pr_resbdgt.activity_code, "' ", 
	"AND ", pv_query_1 clipped 
	PREPARE s1 FROM query_text 
	DECLARE c_res CURSOR FOR s1 
	LET idx = 1 
	FOREACH c_res INTO ma_res_code[idx].res_code, 
		ma_res_code[idx].desc_text 
		LET idx = idx + 1 
		IF idx = 50 THEN 
			EXIT FOREACH 
			# MESSAGE "First 50 lines selected only."
			LET msgresp = kandoomsg("J", 1527, " ") 
		END IF 
		IF int_flag 
		OR quit_flag THEN 
			LET int_flag = false 
			LET int_flag = false 
			RETURN false 
		END IF 
	END FOREACH 
	LET res_array_size = idx -1 
	IF res_array_size = 0 THEN 
		#ERROR " No Resource Budgets Selected - Try Again"
		LET msgresp = kandoomsg("U", 9506, " ") 
		IF get_job_info() THEN 
			RETURN true 
		ELSE 
			RETURN false 
		END IF 
	END IF 
	IF mv_res_edit_flag THEN 
		LET msgresp = kandoomsg("J", 1553, " ") 
	ELSE 
		LET msgresp = kandoomsg("J", 1012, " ") 
	END IF 

	WHENEVER ERROR CONTINUE 
	OPTIONS 
	DELETE KEY f36, 
	INSERT KEY f36 

	WHENEVER ERROR stop 
	CALL set_count(res_array_size) 
	LET res_delete_cnt = 0 
	INPUT ARRAY ma_res_code WITHOUT DEFAULTS FROM sa_res.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7X","input-ma_res_code-1") -- alch kd-506 
		ON KEY (f2) 
			IF mv_res_edit_flag THEN 
				IF ma_res_code[idx].desc_text = "Deleted" THEN 
					#ERROR "Resource Budgets Already Deleted"
					LET msgresp = kandoomsg("J", 9583, " ") 
					NEXT FIELD delete_flag 
				END IF 
				IF delete_resbdgt(ma_res_code[idx].res_code) THEN 
					LET ma_res_code[idx].delete_flag = NULL 
					LET ma_res_code[idx].desc_text = "Deleted" 
					DISPLAY ma_res_code[idx].* TO sa_res[scrn].* 
					attribute (red) 
					NEXT FIELD delete_flag 
				END IF 
			ELSE 
				LET msgresp=kandoomsg("J",9653,0) 
				#9653 Inquiry Mode only; delete NOT allowed
				NEXT FIELD delete_flag 
			END IF 
		AFTER FIELD delete_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND ma_res_code[idx+1].res_code IS NULL THEN 
				LET msgresp=kandoomsg("J",9001,"") 
				#9001 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() > arr_count() THEN 
				#ERROR "There are no more rows in the direction you are going"
				LET msgresp = kandoomsg("U", 9001, " ") 
			ELSE 
				LET pr_resbdgt.res_code = ma_res_code[idx].res_code 
				LET fv_res_desc_text = ma_res_code[idx].desc_text 
				DISPLAY ma_res_code[idx].* TO sa_res[scrn].* 
			END IF 
		BEFORE FIELD res_code 
			IF ma_res_code[idx].res_code IS NULL THEN 
				NEXT FIELD delete_flag 
			END IF 
			IF ma_res_code[idx].desc_text = "Deleted" THEN 
				#ERROR "Resource Budgets Have Been Deleted"
				LET msgresp = kandoomsg("J", 1417, " ") 
				NEXT FIELD delete_flag 
			END IF 
			OPEN WINDOW j197w with FORM "J197" -- alch kd-747 
			CALL winDecoration_j("J197") -- alch kd-747 
			IF mv_res_edit_flag THEN 
				CALL edit_resbdgt() 
				RETURNING fv_status 
			ELSE 
				CALL view_resbdgt() 
			END IF 
			CLOSE WINDOW j197w 
			SELECT desc_text INTO fv_res_desc_text 
			FROM jmresource 
			WHERE cmpy_code = pv_cmpy_code 
			AND res_code = ma_res_code[idx].res_code 
			DISPLAY ma_res_code[idx].res_code, 
			ma_res_code[idx].desc_text TO sa_res[scrn].res_code, 
			sa_res[scrn].desc_text 
			NEXT FIELD delete_flag 
		AFTER ROW 
			IF mv_res_edit_flag THEN 
				LET msgresp = kandoomsg("J", 1553, " ") 
			ELSE 
				LET msgresp = kandoomsg("J", 1012, " ") 
			END IF 
			IF ma_res_code[idx].delete_flag != "*" THEN 
				LET ma_res_code[idx].delete_flag = NULL 
			END IF 
			DISPLAY ma_res_code[idx].* TO sa_res[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 


FUNCTION view_resbdgt() 
	DEFINE 
	fv_char CHAR 
	CALL display_resbdgt() 
	CALL eventsuspend() 
	#prompt "Press Any Key TO Continue" FOR CHAR fv_char
	#LET fv_char = kandoomsg("U", 0001, " ")
END FUNCTION 


FUNCTION display_resbdgt() 
	DEFINE 
	fr_job RECORD LIKE job.*, 
	fr_customer RECORD LIKE customer.*, 
	fv_desc_text LIKE jmresource.desc_text 
	SELECT * INTO pr_resbdgt.* 
	FROM resbdgt 
	WHERE cmpy_code = pv_cmpy_code 
	AND job_code = pr_resbdgt.job_code 
	AND var_code = pr_resbdgt.var_code 
	AND activity_code = pr_resbdgt.activity_code 
	AND res_code = pr_resbdgt.res_code 
	IF status THEN 
		#ERROR "Cannot SELECT Resource Budget",
		#      pr_resbdgt.res_code, "Status:",STATUS
		LET msgresp = kandoomsg("J", 1418, pr_resbdgt.res_code) 
	ELSE 
		SELECT job.title_text, 
		customer.cust_code, 
		customer.name_text INTO fr_job.title_text, 
		fr_customer.cust_code, 
		fr_customer.name_text 
		FROM job, 
		customer 
		WHERE job.cmpy_code = pv_cmpy_code 
		AND job_code = pr_resbdgt.job_code 
		AND customer.cmpy_code = pv_cmpy_code 
		AND customer.cust_code = job.cust_code 
		AND (job.acct_code matches pv_user_scan_code 
		OR job.locked_ind <= "1") 
		SELECT desc_text, unit_code INTO fv_desc_text, fv_unit_code 
		FROM jmresource 
		WHERE res_code = pr_resbdgt.res_code 
		AND cmpy_code = pv_cmpy_code 
		DISPLAY pr_resbdgt.job_code, 
		fr_job.title_text, 
		fr_customer.cust_code, 
		fr_customer.name_text, 
		pr_resbdgt.var_code, 
		pr_resbdgt.activity_code, 
		pr_activity.title_text, 
		pr_resbdgt.res_code, 
		fv_desc_text, 
		fv_unit_code, 
		pr_resbdgt.est_cost_amt, 
		pr_resbdgt.est_bill_amt, 
		pr_resbdgt.bdgt_cost_amt, 
		pr_resbdgt.bdgt_bill_amt , 
		pr_resbdgt.est_cost_qty, 
		pr_resbdgt.est_bill_qty, 
		pr_resbdgt.bdgt_cost_qty, 
		pr_resbdgt.bdgt_bill_qty 
		TO job_code, 
		title_text, 
		cust_code, 
		name_text, 
		var_code, 
		activity_code, 
		activity_desc, 
		res_code, 
		desc_text, 
		unit_code, 
		est_cost_amt, 
		est_bill_amt, 
		bdgt_cost_amt, 
		bdgt_bill_amt, 
		est_cost_qty, 
		est_bill_qty, 
		bdgt_cost_qty, 
		bdgt_bill_qty 

	END IF 
END FUNCTION 


FUNCTION edit_resbdgt() 
	DEFINE 
	fv_count INTEGER, 
	fr_customer RECORD LIKE customer.*, 
	fr_job RECORD LIKE job.*, 
	fv_status SMALLINT, 
	fv_desc_text LIKE jmresource.desc_text 
	CLEAR FORM 
	# MESSAGE "Enter Criteria - ESC TO continue - DEL TO Exit"
	#    attribute (yellow)
	LET msgresp = kandoomsg("J", 1420, " ") 
	SELECT * INTO pr_resbdgt.* 
	FROM resbdgt 
	WHERE cmpy_code = pv_cmpy_code 
	AND job_code = pr_resbdgt.job_code 
	AND var_code = pr_resbdgt.var_code 
	AND activity_code = pr_resbdgt.activity_code 
	AND res_code = pr_resbdgt.res_code 
	IF status THEN 
		#ERROR "Cannot SELECT Resource Budget", pr_resbdgt.res_code, "Status:",STATUS
		LET msgresp = kandoomsg("J", 1418, pr_resbdgt.res_code) 
		RETURN false 
	END IF 
	CALL display_resbdgt() 
	IF fv_unit_code != pr_activity.unit_code 
	OR (fv_unit_code IS NULL AND pr_activity.unit_code IS NOT null) 
	OR (fv_unit_code IS NOT NULL AND pr_activity.unit_code IS null) THEN 
		LET msgresp = kandoomsg("J",9652,0) 
		#J 9652 Quantity figures will NOT be updated on the Activity.
	END IF 
	LET fv_status = true 
	INPUT BY NAME pr_resbdgt.est_cost_amt, 
	pr_resbdgt.est_bill_amt, 
	pr_resbdgt.bdgt_cost_amt, 
	pr_resbdgt.bdgt_bill_amt, 
	pr_resbdgt.est_cost_qty, 
	pr_resbdgt.est_bill_qty, 
	pr_resbdgt.bdgt_cost_qty, 
	pr_resbdgt.bdgt_bill_qty WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J7X","input-pr_resbdgt-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD est_cost_amt 
			IF pr_resbdgt.est_cost_amt IS NULL THEN 
				LET pr_resbdgt.est_cost_amt = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.est_cost_amt, 
			pr_resbdgt.bdgt_cost_amt 

		AFTER FIELD est_bill_amt 
			IF pr_resbdgt.est_bill_amt IS NULL THEN 
				LET pr_resbdgt.est_bill_amt = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.est_bill_amt, 
			pr_resbdgt.bdgt_bill_amt 

		AFTER FIELD bdgt_cost_amt 
			IF pr_resbdgt.bdgt_cost_amt IS NULL THEN 
				LET pr_resbdgt.bdgt_cost_amt = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.bdgt_cost_amt 

		AFTER FIELD bdgt_bill_amt 
			IF pr_resbdgt.bdgt_bill_amt IS NULL THEN 
				LET pr_resbdgt.bdgt_bill_amt = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.bdgt_bill_amt 

		AFTER FIELD est_cost_qty 
			IF pr_resbdgt.est_cost_qty IS NULL THEN 
				LET pr_resbdgt.est_cost_qty = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.est_cost_qty, 
			pr_resbdgt.bdgt_cost_qty 

		AFTER FIELD est_bill_qty 
			IF pr_resbdgt.est_bill_qty IS NULL THEN 
				LET pr_resbdgt.est_bill_qty = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.est_bill_qty, 
			pr_resbdgt.bdgt_bill_qty 

		AFTER FIELD bdgt_cost_qty 
			IF pr_resbdgt.bdgt_cost_qty IS NULL THEN 
				LET pr_resbdgt.bdgt_cost_qty = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.bdgt_cost_qty 

		AFTER FIELD bdgt_bill_qty 
			IF pr_resbdgt.bdgt_bill_qty IS NULL THEN 
				LET pr_resbdgt.bdgt_bill_qty = 0.00 
			END IF 
			DISPLAY BY NAME pr_resbdgt.bdgt_bill_qty 

		AFTER INPUT 
			IF int_flag 
			OR quit_flag THEN 
				LET fv_status = false 
				EXIT INPUT 
			END IF 
			#Check FOR NULL inputs
			LET pr_resbdgt.cmpy_code = pv_cmpy_code 
			BEGIN WORK 
				UPDATE resbdgt 
				SET est_cost_amt = pr_resbdgt.est_cost_amt, 
				est_bill_amt = pr_resbdgt.est_bill_amt, 
				bdgt_cost_amt = pr_resbdgt.bdgt_cost_amt , 
				bdgt_bill_amt = pr_resbdgt.bdgt_bill_amt, 
				est_cost_qty = pr_resbdgt.est_cost_qty, 
				est_bill_qty = pr_resbdgt.est_bill_qty, 
				bdgt_cost_qty = pr_resbdgt.bdgt_cost_qty , 
				bdgt_bill_qty = pr_resbdgt.bdgt_bill_qty 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND var_code = pr_resbdgt.var_code 
				AND activity_code = pr_resbdgt.activity_code 
				AND res_code = pr_resbdgt.res_code 
				IF status THEN 
					#ERROR "Unsuccessful Update resbdget failed.  Stat:",STATUS
					LET msgresp = kandoomsg("J", 9584, status) 
					ROLLBACK WORK 
					LET fv_status = false 
					EXIT INPUT 
				ELSE 
					IF mv_sys_resbdgt_flg = "Y" THEN 
						SELECT sum(est_cost_amt), 
						sum(est_bill_amt), 
						sum(bdgt_cost_amt), 
						sum(bdgt_bill_amt) 
						INTO pr_activity.est_cost_amt, 
						pr_activity.est_bill_amt, 
						pr_activity.bdgt_cost_amt, 
						pr_activity.bdgt_bill_amt 
						FROM resbdgt 
						WHERE cmpy_code = pv_cmpy_code 
						AND job_code = pr_resbdgt.job_code 
						AND activity_code = pr_resbdgt.activity_code 
						AND var_code = pr_resbdgt.var_code 
						IF status THEN 
							#ERROR "Unsuccessful Update, sum of est_cost_amt failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9585, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						END IF 
						SELECT sum(resbdgt.est_cost_qty), 
						sum(resbdgt.est_bill_qty), 
						sum(resbdgt.bdgt_cost_qty), 
						sum(resbdgt.bdgt_bill_qty) 
						INTO pr_activity.est_cost_qty, 
						pr_activity.est_bill_qty, 
						pr_activity.bdgt_cost_qty, 
						pr_activity.bdgt_bill_qty 
						FROM resbdgt, jmresource, activity 
						WHERE resbdgt.cmpy_code = pv_cmpy_code 
						AND resbdgt.job_code = pr_resbdgt.job_code 
						AND resbdgt.activity_code = pr_resbdgt.activity_code 
						AND resbdgt.var_code = pr_resbdgt.var_code 
						AND resbdgt.cmpy_code = pv_cmpy_code 
						AND activity.job_code = pr_resbdgt.job_code 
						AND activity.activity_code = pr_resbdgt.activity_code 
						AND activity.var_code = pr_resbdgt.var_code 
						AND jmresource.cmpy_code = pv_cmpy_code 
						AND jmresource.res_code = resbdgt.res_code 
						AND (jmresource.unit_code = activity.unit_code 
						OR (jmresource.unit_code IS NULL 
						AND activity.unit_code IS null)) 
						IF status THEN 
							# ERROR "Unsuccessful Addition sum of est_cost_amt failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9578, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						END IF 
						IF pr_activity.est_cost_amt IS NULL THEN 
							LET pr_activity.est_cost_amt = 0 
						END IF 
						IF pr_activity.est_bill_amt IS NULL THEN 
							LET pr_activity.est_bill_amt = 0 
						END IF 
						IF pr_activity.bdgt_cost_amt IS NULL THEN 
							LET pr_activity.bdgt_cost_amt = 0 
						END IF 
						IF pr_activity.bdgt_bill_amt IS NULL THEN 
							LET pr_activity.bdgt_bill_amt = 0 
						END IF 
						IF pr_activity.est_cost_qty IS NULL THEN 
							LET pr_activity.est_cost_qty = 0 
						END IF 
						IF pr_activity.est_bill_qty IS NULL THEN 
							LET pr_activity.est_bill_qty = 0 
						END IF 
						IF pr_activity.bdgt_cost_qty IS NULL THEN 
							LET pr_activity.bdgt_cost_qty = 0 
						END IF 
						IF pr_activity.bdgt_bill_qty IS NULL THEN 
							LET pr_activity.bdgt_bill_qty = 0 
						END IF 
						UPDATE activity 
						SET est_cost_amt = pr_activity.est_cost_amt, 
						est_bill_amt = pr_activity.est_bill_amt, 
						bdgt_cost_amt = pr_activity.bdgt_cost_amt, 
						bdgt_bill_amt = pr_activity.bdgt_bill_amt, 
						est_cost_qty = pr_activity.est_cost_qty, 
						est_bill_qty = pr_activity.est_bill_qty, 
						bdgt_cost_qty = pr_activity.bdgt_cost_qty, 
						bdgt_bill_qty = pr_activity.bdgt_bill_qty 
						WHERE cmpy_code = pv_cmpy_code 
						AND activity_code = pr_activity.activity_code 
						AND job_code = pr_activity.job_code 
						AND var_code = pr_activity.var_code 
						IF status THEN 
							#ERROR "Unsuccessful Update, activity UPDATE failed.",
							#      "Stat:",STATUS
							LET msgresp = kandoomsg("J", 9586, status) 
							ROLLBACK WORK 
							LET fv_status = false 
							EXIT INPUT 
						ELSE 
						COMMIT WORK 
						# MESSAGE "Successful Update ..."
						LET msgresp = kandoomsg("J", 1536, " ") 
						LET fv_status = true 
						EXIT INPUT 
					END IF 
				ELSE 
				COMMIT WORK 
				# MESSAGE "Successful Update ..."
				LET msgresp = kandoomsg("J", 1536, " ") 
				LET fv_status = true 
				EXIT INPUT 
			END IF 
		END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN fv_status 
END FUNCTION #edit_resbdgt 


FUNCTION delete_resbdgt(fv_res_code) 
	DEFINE 
	fv_res_code LIKE resbdgt.res_code, 
	ans CHAR(1) 
	#prompt " About TO Delete Resource Budgets FOR Resource ",
	#        fv_res_code clipped,
	#     " (y/n) ?"
	#    FOR ans
	LET ans = kandoomsg("J", 1537, fv_res_code) 
	IF upshift(ans) = "Y" THEN 
		BEGIN WORK 
			DELETE 
			FROM resbdgt 
			WHERE cmpy_code = pv_cmpy_code 
			AND job_code = pr_resbdgt.job_code 
			AND activity_code = pr_resbdgt.activity_code 
			AND var_code = pr_resbdgt.var_code 
			AND res_code = fv_res_code 
			IF mv_sys_resbdgt_flg = "Y" THEN 
				SELECT sum(est_cost_amt), 
				sum(est_bill_amt), 
				sum(bdgt_cost_amt), 
				sum(bdgt_bill_amt) 
				INTO pr_activity.est_cost_amt, 
				pr_activity.est_bill_amt, 
				pr_activity.bdgt_cost_amt, 
				pr_activity.bdgt_bill_amt 
				FROM resbdgt 
				WHERE cmpy_code = pv_cmpy_code 
				AND job_code = pr_resbdgt.job_code 
				AND activity_code = pr_resbdgt.activity_code 
				AND var_code = pr_resbdgt.var_code 
				IF status THEN 
					#ERROR "Resource Budgets Not Found FOR Activity",
					#      " Stat:",STATUS
					LET msgresp = kandoomsg("J", 9587, " ") 
					ROLLBACK WORK 
					RETURN false 
				ELSE 
					SELECT sum(resbdgt.est_cost_qty), 
					sum(resbdgt.est_bill_qty), 
					sum(resbdgt.bdgt_cost_qty), 
					sum(resbdgt.bdgt_bill_qty) 
					INTO pr_activity.est_cost_qty, 
					pr_activity.est_bill_qty, 
					pr_activity.bdgt_cost_qty, 
					pr_activity.bdgt_bill_qty 
					FROM resbdgt, jmresource, activity 
					WHERE resbdgt.cmpy_code = pv_cmpy_code 
					AND resbdgt.job_code = pr_resbdgt.job_code 
					AND resbdgt.activity_code = pr_resbdgt.activity_code 
					AND resbdgt.var_code = pr_resbdgt.var_code 
					AND resbdgt.cmpy_code = pv_cmpy_code 
					AND activity.job_code = pr_resbdgt.job_code 
					AND activity.activity_code = pr_resbdgt.activity_code 
					AND activity.var_code = pr_resbdgt.var_code 
					AND jmresource.cmpy_code = pv_cmpy_code 
					AND jmresource.res_code = pr_resbdgt.res_code 
					AND (jmresource.unit_code = activity.unit_code 
					OR (jmresource.unit_code IS NULL 
					AND activity.unit_code IS null)) 
					IF status THEN 
						# ERROR "Unsuccessful Addition sum of est_cost_amt failed.",
						#      "Stat:",STATUS
						LET msgresp = kandoomsg("J", 9578, status) 
						ROLLBACK WORK 
						RETURN false 
					END IF 
					IF pr_activity.est_cost_amt IS NULL THEN 
						LET pr_activity.est_cost_amt = 0 
					END IF 
					IF pr_activity.est_bill_amt IS NULL THEN 
						LET pr_activity.est_bill_amt = 0 
					END IF 
					IF pr_activity.bdgt_cost_amt IS NULL THEN 
						LET pr_activity.bdgt_cost_amt = 0 
					END IF 
					IF pr_activity.bdgt_bill_amt IS NULL THEN 
						LET pr_activity.bdgt_bill_amt = 0 
					END IF 
					IF pr_activity.est_cost_qty IS NULL THEN 
						LET pr_activity.est_cost_qty = 0 
					END IF 
					IF pr_activity.est_bill_qty IS NULL THEN 
						LET pr_activity.est_bill_qty = 0 
					END IF 
					IF pr_activity.bdgt_cost_qty IS NULL THEN 
						LET pr_activity.bdgt_cost_qty = 0 
					END IF 
					IF pr_activity.bdgt_bill_qty IS NULL THEN 
						LET pr_activity.bdgt_bill_qty = 0 
					END IF 
					UPDATE activity 
					SET est_cost_amt = pr_activity.est_cost_amt, 
					est_bill_amt = pr_activity.est_bill_amt, 
					bdgt_cost_amt = pr_activity.bdgt_cost_amt, 
					bdgt_bill_amt = pr_activity.bdgt_bill_amt, 
					est_cost_qty = pr_activity.est_cost_qty, 
					est_bill_qty = pr_activity.est_bill_qty, 
					bdgt_cost_qty = pr_activity.bdgt_cost_qty, 
					bdgt_bill_qty = pr_activity.bdgt_bill_qty 
					WHERE cmpy_code = pv_cmpy_code 
					AND activity_code = pr_activity.activity_code 
					AND job_code = pr_activity.job_code 
					AND var_code = pr_activity.var_code 
					IF status THEN 
						#ERROR "Unsuccessful Update of Activity Budgets & Ests. ",
						#      "Stat:",STATUS
						LET msgresp = kandoomsg("J", 9586, " ") 
						ROLLBACK WORK 
						RETURN false 
					ELSE 
					COMMIT WORK 
					# MESSAGE "Budgets deleted FOR Resource " ,
					#          fv_res_code clipped,
					#   " AND Budgets Updated FOR Activity ",
					#             pr_activity.activity_code clipped
					#             attribute (yellow)
					LET msgresp = kandoomsg("J", 1414, pr_activity.activity_code) 
					LET msgresp = kandoomsg("J", 1419, fv_res_code) 
					RETURN true 
				END IF 
			END IF 
		ELSE 
			# MESSAGE "Resource Budgets Deleted (Activity Budgets NOT Updated)"
			#   attribute (yellow)
			LET msgresp = kandoomsg("J", 1416, pr_activity.activity_code) 
			LET msgresp = kandoomsg("J", 1419, fv_res_code) 
		COMMIT WORK 
	END IF 
ELSE 
	# MESSAGE "Delete aborted"
	#LET msgresp = kandoomsg("U", 9543, " ")
	RETURN false 
END IF 
END FUNCTION 
