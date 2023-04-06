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

	Source code beautified by beautify.pl on 2020-01-02 19:48:09	$Id: $
}



# Purpose - Activity Edit Program


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J5_GLOBALS.4gl" 

DEFINE 
pr_menunames RECORD LIKE menunames.* 

MAIN 
	#Initial UI Init
	CALL setModuleId("J54") -- albo 
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
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("J",1401,"") 
		# Must SET up JM Parameters first in JZP"
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j116 with FORM "J116" -- alch kd-747 
	CALL winDecoration_j("J116") -- alch kd-747 
	WHILE select_job() 
		CALL select_activity() 
		CLEAR FORM 
	END WHILE 
	CLOSE WINDOW j116 
END MAIN 


FUNCTION select_job() 
	LET msgresp = kandoomsg("J",1427,"") 
	#1427 Enter Job Details;  OK TO Continue.
	INPUT BY NAME pr_activity.job_code, 
	pr_activity.var_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J54","input-pr_activity-1") -- alch kd-506 
	
		ON KEY (control-b) 
			CASE 
				WHEN infield (job_code) 
					LET pr_activity.job_code = 
					showpjobs(glob_rec_kandoouser.cmpy_code,pr_user_scan_code) 
					SELECT title_text, 
					cust_code 
					INTO pr_job.title_text, 
					pr_job.cust_code 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_activity.job_code 
					DISPLAY pr_activity.job_code, 
					pr_job.title_text, 
					pr_job.cust_code 
					TO job_code, 
					job.title_text, 
					cust_code 

				WHEN infield (var_code) 
					LET pr_activity.var_code = 
					show_jobvars(glob_rec_kandoouser.cmpy_code, pr_activity.job_code) 
					DISPLAY pr_activity.var_code 
					TO activity.var_code 

			END CASE 
		BEFORE FIELD job_code 
			LET msgresp = kandoomsg("J",1427,"") 
			#J1427 Enter Job Details OK TO continue
		AFTER FIELD job_code 
			IF pr_activity.job_code IS NULL THEN 
				#ERROR " Job Code must be Entered"
				LET msgresp = kandoomsg("J",9508," ") 
				NEXT FIELD job_code 
			ELSE 
				SELECT job.* 
				INTO pr_job.* 
				FROM job 
				WHERE job_code = pr_activity.job_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ((acct_code matches pr_user_scan_code 
				AND locked_ind = "2") 
				OR locked_ind <= "1") 
				IF status = notfound THEN 
					#ERROR " Job Code Does Not Exist - Try Window"
					LET msgresp = kandoomsg("J",9558," ") 
					NEXT FIELD job_code 
				ELSE 
					#Check FOR master job
					IF pr_job.locked_ind = 0 THEN 
						#ERROR " Cannot Edit an Master Job - Try J55"
						LET msgresp = kandoomsg("J",9573," ") 
						NEXT FIELD job_code 
					END IF 
					SELECT name_text 
					INTO pr_customer.name_text 
					FROM customer 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cust_code = pr_job.cust_code 
					DISPLAY BY NAME pr_activity.job_code, 
					pr_job.title_text, 
					pr_job.cust_code, 
					pr_customer.name_text 

				END IF 
			END IF 
		AFTER FIELD var_code 
			CASE 
				WHEN pr_activity.var_code = 0 
					EXIT CASE 
				WHEN pr_activity.var_code IS NULL 
					LET pr_activity.var_code = 0 
					DISPLAY pr_activity.var_code TO var_code 

				OTHERWISE 
					SELECT jobvars.* 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = pr_activity.job_code 
					AND var_code = pr_activity.var_code 
					IF status = notfound THEN 
						#ERROR " Variation Does Not Exist - Try Window"
						LET msgresp = kandoomsg("J",9510," ") 
						LET pr_activity.var_code = 0 
						DISPLAY pr_activity.var_code TO var_code 

						NEXT FIELD var_code 
					END IF 
			END CASE 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				#Do nothing
			ELSE 
				IF pr_activity.var_code IS NULL THEN 
					#9545 "Variation code must be entered try window
					LET msgresp = kandoomsg("J", 9545, "") 
					NEXT FIELD var_code 
				END IF 
				CALL get_acct_masks(pr_job.type_code) 
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


FUNCTION select_activity() 
	DEFINE 
	cnt, idx, scrn SMALLINT, 
	pa_activity array[300] OF RECORD 
		delete_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		title_text LIKE activity.title_text, 
		resp_code LIKE activity.resp_code, 
		sort_text LIKE activity.sort_text , 
		#est_end_date LIKE activity.est_end_date
		act_end_date LIKE activity.act_end_date 
	END RECORD, 
	where_act, 
	sel_text CHAR(1000), 
	activity_cnt, 
	act_delete_cnt SMALLINT 

	LET activity_cnt = 0 
	LET act_delete_cnt = 0 
	WHILE true 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT where_act ON 
		activity_code, 
		activity.title_text, 
		resp_code, 
		sort_text 
		FROM 
		activity_code, 
		activity.title_text, 
		resp_code, 
		sort_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","J54","const-activity_code-2") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
		LET sel_text = 
		" SELECT * ", 
		" FROM activity ", 
		" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
		" job_code = \"",pr_activity.job_code,"\" AND ", 
		" var_code = \"",pr_activity.var_code,"\" AND ", 
		where_act clipped, 
		" ORDER BY sort_text,activity_code " 
		PREPARE get_act FROM sel_text 
		DECLARE c_act CURSOR FOR get_act 
		OPEN c_act 
		LET idx = 0 
		FETCH c_act INTO pr_activity.* 
		WHILE status <> notfound 
			LET idx = idx + 1 
			LET pa_activity[idx].delete_flag = NULL 
			LET pa_activity[idx].activity_code = pr_activity.activity_code 
			LET pa_activity[idx].title_text = pr_activity.title_text 
			LET pa_activity[idx].resp_code = pr_activity.resp_code 
			LET pa_activity[idx].sort_text = pr_activity.sort_text 
			#LET pa_activity[idx].est_end_date = pr_activity.est_end_date
			LET pa_activity[idx].act_end_date = pr_activity.act_end_date 
			IF idx = 300 THEN 
				EXIT WHILE 
			END IF 
			FETCH c_act INTO pr_activity.* 
		END WHILE 
		LET activity_cnt = idx 
		IF idx > 0 THEN 
			#error" First idx Activities selected"
			LET msgresp = kandoomsg("J",1018,idx) 
			EXIT WHILE 
		ELSE 
			#ERROR " No Activities Exist"
			LET msgresp = kandoomsg("J",9572," ") 
		END IF 
	END WHILE 
	LET msgresp = kandoomsg("U",1518," ") 
	#1518 Enter on line TO Edit;  F2 TO Delete.
	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	WHENEVER ERROR stop 
	CALL set_count(activity_cnt) 
	INPUT ARRAY pa_activity WITHOUT DEFAULTS FROM sr_activity.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J54","input-pa_activity-1") -- alch kd-506 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 

		BEFORE FIELD delete_flag 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

		AFTER FIELD delete_flag 
			IF arr_curr() = arr_count() 
			AND fgl_lastkey() = fgl_keyval("down") THEN 
				LET msgresp = kandoomsg("U",3513," ") 
				#3513 There are no more rows in the direction you are going.
				NEXT FIELD delete_flag 
			END IF 
			LET pr_activity.activity_code = 
			pa_activity[idx].activity_code 
			LET pr_activity.title_text = pa_activity[idx].title_text 
			LET pr_activity.resp_code = pa_activity[idx].resp_code 
			LET pr_activity.sort_text = pa_activity[idx].sort_text 


			LET pr_activity.act_end_date = 
			pa_activity[idx].act_end_date 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

		AFTER ROW 
			DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

		BEFORE FIELD activity_code 
			IF pr_activity.activity_code IS NULL THEN 
				#ERROR "No activity selected"
				LET msgresp = kandoomsg("J",9574," ") 
			ELSE 
				OPTIONS DELETE KEY f2, 
				INSERT KEY f1 
				CALL edit_activity() 
				LET pa_activity[idx].activity_code = pr_activity.activity_code 
				LET pa_activity[idx].title_text = pr_activity.title_text 
				LET pa_activity[idx].resp_code = pr_activity.resp_code 
				LET pa_activity[idx].sort_text = pr_activity.sort_text 

				LET pa_activity[idx].act_end_date = pr_activity.act_end_date 

				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 


				OPTIONS DELETE KEY f36, 
				INSERT KEY f36 
			END IF 
			NEXT FIELD delete_flag 
		ON KEY (F2) 
			IF pa_activity[idx].delete_flag IS NULL THEN 
				IF act_deletable(pr_activity.job_code, 
				pr_activity.var_code, 
				pa_activity[idx].activity_code) THEN 
					LET pa_activity[idx].delete_flag = "*" 
					DISPLAY pa_activity[idx].delete_flag 
					TO sr_activity[scrn].delete_flag 
					attribute(red) 
					LET act_delete_cnt = act_delete_cnt + 1 
				ELSE 
					#error
					#"Activity has Ledger Transactions - Cannot Delete"
					LET msgresp = kandoomsg("J",9575,pa_activity[idx].activity_code) 
					NEXT FIELD delete_flag 
				END IF 
			ELSE 
				LET pa_activity[idx].delete_flag = NULL 
				DISPLAY pa_activity[idx].delete_flag 
				TO sr_activity[scrn].delete_flag 
				LET act_delete_cnt = act_delete_cnt - 1 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF NOT (int_flag OR quit_flag) 
	AND act_delete_cnt > 0 THEN 
		#prompt " About TO Delete ",act_delete_cnt," Activities? (y/n)"
		LET ans = kandoomsg("J",1413,act_delete_cnt) 
		IF upshift(ans) = "Y" THEN 
			FOR idx = 1 TO activity_cnt 
				IF pa_activity[idx].delete_flag IS NOT NULL THEN 
					CALL delete_activity(pr_activity.job_code, 
					pr_activity.var_code, 
					pa_activity[idx].activity_code) 
				END IF 
			END FOR 
		END IF 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION edit_activity() 
	DEFINE 
	cnt SMALLINT, 
	pr_rowid INTEGER 
	OPEN WINDOW j104 with FORM "J104" -- alch kd-747 
	CALL winDecoration_j("J104") -- alch kd-747 
	CALL read_data() RETURNING pr_rowid 
	CALL display_details() 
	MENU "Activity Edit" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J54","menu-act_edit-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND KEY ("D",f20) "Detail" "Edit non-financial activity details" 
			CALL read_details() 
			IF int_flag OR quit_flag THEN 
				CALL read_data() RETURNING pr_rowid 
				CALL display_details() 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL update_activity(pr_rowid) 
			END IF 
		COMMAND "Financials" "Edit activity financials" 
			OPEN WINDOW j105 with FORM "J105" -- alch kd-747 
			CALL winDecoration_j("J105") -- alch kd-747 
			CALL display_financials() 
			#Added TO allow edit of Revenue account field
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.bill_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING entry_mask 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.wip_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING wip_entry_mask 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.cos_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING cos_entry_mask 
			CALL read_financials() 
			CLOSE WINDOW j105 
			IF int_flag OR quit_flag THEN 
				CALL read_data() RETURNING pr_rowid 
				CALL display_details() 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL display_details() 
				CALL update_activity(pr_rowid) 
			END IF 
		COMMAND "Page" "Edit full page activity description" 
			CALL read_description() 
			IF int_flag OR quit_flag THEN 
				CALL read_data() RETURNING pr_rowid 
				CALL display_details() 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL update_activity(pr_rowid) 
			END IF 
		COMMAND KEY(interrupt,"E")"Exit" "RETURN TO activity scan" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j104 
END FUNCTION 


FUNCTION update_activity(pr_rowid) 
	DEFINE 
	cnt SMALLINT, 
	pr_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF upshift(err_continue) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = " J54 - Updating Activity" 
		WHENEVER ERROR GOTO recovery 
		UPDATE activity 
		SET * = pr_activity.* 
		WHERE rowid = pr_rowid 
		LET err_message = " J54 - Deleting Activity Description" 
		DELETE FROM act_desc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_activity.job_code 
		AND var_code = pr_activity.var_code 
		AND activity_code = pr_activity.activity_code 
		DECLARE ins_j_curs CURSOR FOR 
		INSERT INTO act_desc VALUES (pr_act_desc.*) 
		OPEN ins_j_curs 
		LET err_message = " J54 - Inserting activity description" 
		FOR cnt = 1 TO act_desc_cnt 
			LET pr_act_desc.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_act_desc.job_code = pr_activity.job_code 
			LET pr_act_desc.var_code = pr_activity.var_code 
			LET pr_act_desc.activity_code = pr_activity.activity_code 
			LET pr_act_desc.seq_num = cnt 
			LET pr_act_desc.desc_text = pa_act_desc[cnt] 
			PUT ins_j_curs 
		END FOR 
		CLOSE ins_j_curs 
		LET err_message = " J54 - Updating Job" 
		WHENEVER ERROR GOTO recovery 
		UPDATE job SET ( est_start_date , est_end_date) = 
		( pr_job.est_start_date , pr_job.est_end_date) 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_job.job_code 
		AND cust_code = pr_job.cust_code 
		WHENEVER ERROR stop 
	COMMIT WORK 
END FUNCTION 


FUNCTION read_data() 
	DEFINE 
	cnt SMALLINT, 
	pr_rowid INTEGER 

	#Initialise ARRAY variables TO blank
	FOR cnt = 1 TO 100 
		LET pa_act_desc[cnt] = "" 
	END FOR 
	LET cnt = 0 

	SELECT activity.* , rowid 
	INTO pr_activity.*, pr_rowid 
	FROM activity 
	WHERE activity.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND activity.job_code = pr_activity.job_code 
	AND activity.var_code = pr_activity.var_code 
	AND activity.activity_code = pr_activity.activity_code 
	DECLARE c_act_desc CURSOR FOR 
	SELECT act_desc.* 
	FROM act_desc 
	WHERE act_desc.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND act_desc.job_code = pr_activity.job_code 
	AND act_desc.var_code = pr_activity.var_code 
	AND act_desc.activity_code = pr_activity.activity_code 
	ORDER BY seq_num 
	FOREACH c_act_desc INTO pr_act_desc.* 
		LET cnt = pr_act_desc.seq_num 
		IF cnt > 100 OR cnt < 1 THEN 
			LET err_message = "Program J54, act_desc count > 100 " 
			CALL errorlog(err_message) 
			LET msgresp = kandoomsg("J",7018,"") 
			# "Internal system error - see ", get_settings_logFile()
			EXIT program 
		END IF 
		LET pa_act_desc[cnt] = pr_act_desc.desc_text 
	END FOREACH 
	FREE c_act_desc 
	LET act_desc_cnt = cnt 
	RETURN pr_rowid 
END FUNCTION # read_data() 
