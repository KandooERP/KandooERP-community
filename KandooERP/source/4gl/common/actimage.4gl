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

GLOBALS 
	#DEFINE glob_rec_job RECORD LIKE job.*
	DEFINE glob_rec_activity RECORD LIKE activity.* 
	#DEFINE act_desc_cnt SMALLINT
	#DEFINE err_continue CHAR(1)
	#DEFINE ins_text CHAR(200)
	#DEFINE err_message CHAR(40)
	DEFINE glob_arr_act_desc DYNAMIC ARRAY OF LIKE act_desc.desc_text
	DEFINE glob_rec_act_desc record like act_desc.* 
END GLOBALS 

#######################################################################
# FUNCTION ac_detl_scan(p_cmpy, p_acct, p_acc_year, p_per, p_seq)
#
#
#######################################################################
FUNCTION image_activity(p_tgt_acct_code, p_tgt_wip_acct_code,p_tgt_cos_acct_code,p_source_job_code, p_source_title_text) 
	DEFINE p_tgt_acct_code LIKE job.wip_acct_code 
	DEFINE p_tgt_wip_acct_code LIKE job.wip_acct_code 
	DEFINE p_tgt_cos_acct_code LIKE job.wip_acct_code 
	DEFINE p_source_job_code LIKE job.job_code 
	DEFINE p_source_title_text LIKE job.title_text 
	DEFINE l_arr_pb_activity DYNAMIC ARRAY OF RECORD 
		image_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		title_text LIKE activity.title_text, 
		var_code LIKE activity.var_code 
	END RECORD 
	DEFINE l_arr_pa_activity DYNAMIC ARRAY OF RECORD LIKE activity.* 
	DEFINE l_rec_ps_activity RECORD LIKE activity.* 
	DEFINE l_source_locked_ind LIKE job.locked_ind 
	DEFINE l_image_desc CHAR(1) 
	DEFINE l_est_ind CHAR(1) 
	DEFINE l_bdgt_ind CHAR(1) 
	DEFINE l_est_per DECIMAL(5,2) 
	DEFINE l_bdgt_per DECIMAL(5,2) 
	DEFINE l_act_image_total SMALLINT 
	DEFINE l_act_image_cnt SMALLINT 
	DEFINE l_fv_resbdgt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_act_cnt SMALLINT 
	DEFINE l_return_status SMALLINT 
	DEFINE l_msg CHAR(50) 
	DEFINE l_act_desc_cnt SMALLINT 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF get_kandoooption_feature_state("JM","W1") matches "[y,Y]" THEN 
		LET l_fv_resbdgt = true 
		LET l_bdgt_ind = "Z" 
		LET l_est_ind = "Z" 
	ELSE 
		LET l_bdgt_ind = "B" 
		LET l_est_ind = "E" 
		LET l_fv_resbdgt = false 
	END IF 
	LET l_image_desc = "Y" 
	LET glob_rec_activity.job_code = l_rec_job.job_code 

	OPEN WINDOW J158 with FORM "J158" 
	CALL winDecoration_j("J158") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		IF l_fv_resbdgt THEN 
			ERROR kandoomsg2("J",1522," ") 
		END IF 

		DISPLAY p_source_job_code TO source_job_code
		DISPLAY p_source_title_text TO source_title_text 
		DISPLAY l_rec_job.job_code TO tgt_job_code
		DISPLAY l_rec_job.title_text TO tgt_title_text 

		INPUT 
			p_source_job_code, 
			l_bdgt_ind, 
			l_bdgt_per, 
			l_est_ind, 
			l_est_per, 
			l_image_desc WITHOUT DEFAULTS 
		FROM 
			p_source_job_code, 
			bdgt_ind, 
			bdgt_per, 
			est_ind, 
			est_per, 
			image_desc 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","actimage","input-job") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "LOOKUP" infield(p_source_job_code) 
				LET p_source_job_code = showujobs(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.acct_mask_code) 
				DISPLAY p_source_job_code TO p_source_job_code 


			AFTER FIELD p_source_job_code 
				IF p_source_job_code IS NULL THEN 
					ERROR kandoomsg2("J",9508,0) 				#ERROR " Job Code must be entered"
					NEXT FIELD p_source_job_code 
				ELSE 
					SELECT job.title_text, job.locked_ind 
					INTO p_source_title_text, l_source_locked_ind 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = p_source_job_code 
					AND (acct_code matches glob_rec_kandoouser.acct_mask_code  # user_scan_code 
					OR locked_ind <= "1") 
					IF status = notfound THEN 
						ERROR kandoomsg2("J",9558,0) 			#error" Job NOT found - Try Window"
						NEXT FIELD p_source_job_code 
					ELSE 
						DISPLAY p_source_title_text 
						TO p_source_title_text 

					END IF 
				END IF 
				
			BEFORE FIELD bdgt_ind 
				IF l_fv_resbdgt THEN 
					NEXT FIELD image_desc 
				END IF 
				
			BEFORE FIELD bdgt_per 
				IF l_bdgt_ind = "Z" THEN 
					NEXT FIELD est_ind 
				END IF 
				
			AFTER FIELD bdgt_per 
				IF l_bdgt_per IS NULL THEN 
					LET l_bdgt_per = 0 
					DISPLAY l_bdgt_per 
					TO bdgt_per 

				END IF 
			BEFORE FIELD est_ind 
				IF l_fv_resbdgt THEN 
					NEXT FIELD image_desc 
				END IF 

			BEFORE FIELD est_per 
				IF l_est_ind = "Z" THEN 
					NEXT FIELD image_desc 
				END IF 

			AFTER FIELD est_per 
				IF l_est_per IS NULL THEN 
					LET l_est_per = 0 
					DISPLAY l_est_per 
					TO est_per 

				END IF 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW J158 
			RETURN 
		END IF 

		DECLARE actcurs CURSOR FOR 
		SELECT * 
		INTO l_rec_ps_activity.* 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = p_source_job_code 
		LET l_idx = 0 
		FOREACH actcurs 
			LET l_idx = l_idx + 1 
			LET l_arr_pb_activity[l_idx].image_flag = "*" 
			LET l_arr_pb_activity[l_idx].activity_code = l_rec_ps_activity.activity_code 
			LET l_arr_pb_activity[l_idx].title_text = l_rec_ps_activity.title_text 
			LET l_arr_pb_activity[l_idx].var_code = l_rec_ps_activity.var_code 
			LET l_rec_ps_activity.job_code = glob_rec_activity.job_code 
			LET l_rec_ps_activity.var_code = glob_rec_activity.var_code 
			LET l_arr_pa_activity[l_idx].* = l_rec_ps_activity.* 
		END FOREACH 

		CALL set_count(l_idx) 
		IF l_idx = 0 THEN 
			ERROR kandoomsg2("J", 9572, p_source_job_code) 	#ERROR "Job ",p_source_job_code, "has no Activities"
			SLEEP 3 
			LET quit_flag = true 
		ELSE 
			WHENEVER ERROR CONTINUE 
			OPTIONS DELETE KEY f36, 
			INSERT KEY f36 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			ERROR kandoomsg2("J",1563,0) 	# MESSAGE" RETURN TO Toggle Image - DEL TO Re-SELECT Job"

			LET l_act_image_total = 0 
			LET l_act_image_cnt = 0 

			INPUT ARRAY l_arr_pb_activity WITHOUT DEFAULTS FROM sr_activity.* ATTRIBUTE(UNBUFFERED) 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","actimage","input-arr-activity") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF arr_curr() > arr_count() THEN 
						ERROR kandoomsg2("J",9001,0) 						#"There are NO rows in the direction you are going"
						NEXT FIELD image_flag 
					END IF 
				BEFORE FIELD activity_code 
					IF l_arr_pb_activity[l_idx].image_flag IS NULL THEN 
						LET l_arr_pb_activity[l_idx].image_flag = "*" 
						LET l_act_image_total = l_act_image_total + 1 
					ELSE 
						LET l_arr_pb_activity[l_idx].image_flag = NULL 
						LET l_act_image_total = l_act_image_total - 1 
					END IF 
					NEXT FIELD image_flag 



			END INPUT 

		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	FOR l_cnt = 1 TO arr_count() 
		WHILE l_arr_pb_activity[l_cnt].image_flag IS NOT NULL 
			LET l_act_image_cnt = l_act_image_cnt + 1 
			SELECT count(*) 
			INTO l_act_cnt 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = glob_rec_activity.job_code 
			AND var_code = glob_rec_activity.var_code 
			AND activity_code = l_arr_pa_activity[l_cnt].activity_code 
			IF l_act_cnt != 0 THEN 
				LET l_return_status = true 
				CALL validate_activity(l_arr_pa_activity[l_cnt].*) 
				RETURNING l_arr_pa_activity[l_cnt].*, l_return_status 
				IF NOT l_return_status THEN 
					LET l_act_image_total = l_act_image_total - 1 
					EXIT WHILE 
				END IF 
			END IF 
			LET l_msg = glob_rec_activity.activity_code clipped," Number ",l_act_image_cnt," of ",l_act_image_total 
			MESSAGE kandoomsg2("J",1023, l_msg) 	# MESSAGE" Imaging Activity:",glob_rec_activity.activity_code clipped,
			#" Number ",l_act_image_cnt," of ",l_act_image_total

			LET glob_rec_activity.* = l_arr_pa_activity[l_cnt].* 

			CASE (l_bdgt_ind) 
				WHEN "A" 
					LET glob_rec_activity.bdgt_cost_amt = 
					l_arr_pa_activity[l_cnt].act_cost_amt 
					* (l_bdgt_per/100 + 1) 
					LET glob_rec_activity.bdgt_cost_qty = 
					l_arr_pa_activity[l_cnt].act_cost_qty 
					* (l_bdgt_per/100 + 1) 
				WHEN "B" 
					LET glob_rec_activity.bdgt_cost_amt = 
					l_arr_pa_activity[l_cnt].bdgt_cost_amt 
					* (l_bdgt_per/100 + 1) 
					LET glob_rec_activity.bdgt_cost_qty = 
					l_arr_pa_activity[l_cnt].bdgt_cost_qty 
					* (l_bdgt_per/100 + 1) 
				WHEN "E" 
					LET glob_rec_activity.bdgt_cost_amt = 
					l_arr_pa_activity[l_cnt].est_cost_amt 
					* (l_bdgt_per/100 + 1) 
					LET glob_rec_activity.bdgt_cost_qty = 
					l_arr_pa_activity[l_cnt].est_cost_qty 
					* (l_bdgt_per/100 + 1) 
				WHEN "Z" 
					LET glob_rec_activity.bdgt_cost_amt = 0 
					LET glob_rec_activity.bdgt_cost_qty = 0 
					LET glob_rec_activity.bdgt_bill_amt = 0 
			END CASE 
			CASE (l_est_ind) 
				WHEN "A" 
					LET glob_rec_activity.est_cost_amt = 
					l_arr_pa_activity[l_cnt].act_cost_amt 
					* (l_est_per/100 + 1) 
					LET glob_rec_activity.est_cost_qty = 
					l_arr_pa_activity[l_cnt].act_cost_qty 
					* (l_est_per/100 + 1) 
				WHEN "B" 
					LET glob_rec_activity.est_cost_amt = 
					l_arr_pa_activity[l_cnt].bdgt_cost_amt 
					* (l_est_per/100 + 1) 
					LET glob_rec_activity.est_cost_qty = 
					l_arr_pa_activity[l_cnt].bdgt_cost_qty 
					* (l_est_per/100 + 1) 
				WHEN "E" 
					LET glob_rec_activity.est_cost_amt = 
					l_arr_pa_activity[l_cnt].est_cost_amt 
					* (l_est_per/100 + 1) 
					LET glob_rec_activity.est_cost_qty = 
					l_arr_pa_activity[l_cnt].est_cost_qty 
					* (l_est_per/100 + 1) 
				WHEN "Z" 
					LET glob_rec_activity.est_cost_amt = 0 
					LET glob_rec_activity.est_cost_qty = 0 
					LET glob_rec_activity.est_bill_amt = 0 
			END CASE 
			LET glob_rec_activity.est_start_date = l_rec_job.est_start_date 
			LET glob_rec_activity.est_end_date = l_rec_job.est_end_date 
			LET glob_rec_activity.act_start_date = NULL 
			LET glob_rec_activity.act_end_date = NULL 
			LET glob_rec_activity.next_bill_date = NULL 
			LET glob_rec_activity.act_cost_amt = 0 
			LET glob_rec_activity.act_cost_qty = 0 
			LET glob_rec_activity.est_comp_per = 0 
			LET glob_rec_activity.post_cost_amt = 0 
			LET glob_rec_activity.post_revenue_amt = 0 
			LET glob_rec_activity.act_bill_amt = 0 
			LET glob_rec_activity.act_bill_qty = 0 
			LET glob_rec_activity.est_wroff_qty = 0 
			LET glob_rec_activity.est_wroff_amt = 0 
			LET glob_rec_activity.bdgt_wroff_qty = 0 
			LET glob_rec_activity.bdgt_wroff_amt = 0 
			LET glob_rec_activity.act_wroff_qty = 0 
			LET glob_rec_activity.act_wroff_amt = 0 
			LET glob_rec_activity.seq_num = 0 
			IF l_rec_job.locked_ind = "0" THEN 
				LET glob_rec_activity.finish_flag = "Y" 
			ELSE 
				LET glob_rec_activity.finish_flag = "N" 
			END IF 
			IF glob_rec_activity.rev_image_flag = "N" THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				l_arr_pa_activity[l_cnt].acct_code, 
				p_tgt_acct_code) 
				RETURNING glob_rec_activity.acct_code 
			ELSE 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				p_tgt_acct_code, 
				l_arr_pa_activity[l_cnt].acct_code) 
				RETURNING glob_rec_activity.acct_code 
			END IF 
			IF glob_rec_activity.wip_image_flag = "N" THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				l_arr_pa_activity[l_cnt].wip_acct_code, 
				p_tgt_wip_acct_code) 
				RETURNING glob_rec_activity.wip_acct_code 
			ELSE 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				p_tgt_wip_acct_code, 
				l_arr_pa_activity[l_cnt].acct_code) 
				RETURNING glob_rec_activity.wip_acct_code 
			END IF 
			IF glob_rec_activity.cos_image_flag = "N" THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				l_arr_pa_activity[l_cnt].cos_acct_code, 
				p_tgt_cos_acct_code) 
				RETURNING glob_rec_activity.cos_acct_code 
			ELSE 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, 
				p_tgt_cos_acct_code, 
				l_arr_pa_activity[l_cnt].cos_acct_code) 
				RETURNING glob_rec_activity.cos_acct_code 
			END IF 
			IF l_image_desc = "Y" THEN 
				DECLARE c_desc CURSOR FOR 
				SELECT desc_text, 
				seq_num 
				FROM act_desc 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = p_source_job_code 
				AND var_code = l_arr_pb_activity[l_cnt].var_code 
				AND activity_code = l_arr_pb_activity[l_cnt].activity_code 
				ORDER BY seq_num 
				LET l_act_desc_cnt = 1 
				FOREACH c_desc INTO glob_arr_act_desc[l_act_desc_cnt], glob_rec_act_desc.seq_num 
					LET l_act_desc_cnt = l_act_desc_cnt + 1 
				END FOREACH 
			ELSE 
				SLEEP 1 
				LET l_act_desc_cnt = 0 
			END IF 
			IF NOT accounts_on_coa(l_rec_job.*) THEN 

				ERROR kandoomsg2("J",7200, glob_rec_activity.activity_code) 		#prompt " Warning: ", glob_rec_activity.activity_code clipped,			#" has Invalid Account - enter TO cont."

				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			
			CALL insert_image() 
			EXIT WHILE 
			
		END WHILE 
		
	END FOR 
	
	CLOSE WINDOW J158 
END FUNCTION 
#######################################################################
# END FUNCTION ac_detl_scan(p_cmpy, p_acct, p_acc_year, p_per, p_seq)
#######################################################################


#######################################################################
# FUNCTION validate_activity(p_img_activity)
#
#
#######################################################################
FUNCTION validate_activity(p_img_activity) 
	DEFINE p_img_activity RECORD LIKE activity.* 
	DEFINE l_title_text CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE ret_return_status SMALLINT 

	OPEN WINDOW J166 with FORM "J166" 
	CALL winDecoration_j("J166") -- albo kd-767 

	SELECT title_text 
	INTO l_title_text 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = p_img_activity.job_code 
	AND var_code = p_img_activity.var_code 
	AND activity_code = p_img_activity.activity_code 
	DISPLAY p_img_activity.activity_code, 
	l_title_text, 
	p_img_activity.activity_code, 
	p_img_activity.title_text 
	TO activity.activity_code, 
	activity.title_text, 
	img_act_code, 
	img_title_text 
	IF act_deletable(p_img_activity.job_code, 
	p_img_activity.var_code, 
	p_img_activity.activity_code) THEN 
		MENU "Activity Code" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","actimage","menu-Activity_Code-1") -- albo kd-512 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Rename" " Rename New Activity Code TO be Unique" 
				CALL rename_act_code(p_img_activity.*) 
				RETURNING p_img_activity.*, 
				ret_return_status 
				IF ret_return_status THEN 
					EXIT MENU 
				END IF 
			COMMAND "Keep" "Discard Imaged Activity Retaining Existing" 
				LET ret_return_status = false 
				EXIT MENU 
			COMMAND "Delete" " Replace Existing Activity with Imaged Activity" 
				ERROR kandoomsg2("J",8026, p_img_activity.activity_code) 		#prompt " Ok TO Delete Activity (y/n)?" FOR ans

				IF l_msgresp = "Y" THEN 
					CALL delete_activity(
						p_img_activity.job_code, 
						p_img_activity.var_code, 
						p_img_activity.activity_code) 
					LET ret_return_status = true 
					EXIT MENU 
				END IF 

		END MENU 
	ELSE 
		MENU "Activity Code" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","actimage","menu-Activity_Code-2") -- albo kd-512 
			
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			
			COMMAND "Rename" " Rename New Activity Code TO be Unique" 
				CALL rename_act_code(p_img_activity.*) 
				RETURNING p_img_activity.*, 
				ret_return_status 
				IF ret_return_status THEN 
					EXIT MENU 
				END IF 
			
			COMMAND "Keep" " Discard Imaged Activity Retaining Existing" 
				LET ret_return_status = false 
				EXIT MENU 

		END MENU 
	END IF 
	
	CLOSE WINDOW J166 
	LET int_flag = false 
	LET quit_flag = false 
	
	RETURN p_img_activity.*, ret_return_status 
END FUNCTION 
#######################################################################
# END FUNCTION validate_activity(p_img_activity)
#######################################################################


#######################################################################
# FUNCTION insert_image()
#
#
#######################################################################
FUNCTION insert_image() 
	DEFINE l_cnt SMALLINT 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_ins_text CHAR(200) 
	DEFINE l_err_continue CHAR(1) 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "actimage - Inserting Imaged Activity" 
		
		INSERT INTO activity VALUES (glob_rec_activity.*) 
		
		LET l_err_message = "actimage - Inserting Imaged description" 
		LET l_ins_text = " INSERT INTO act_desc VALUES (?,?,?,?,?,?)" 
		PREPARE i_1 FROM l_ins_text 
		DECLARE ins_j_curs CURSOR FOR i_1 
		OPEN ins_j_curs 
		FOR l_cnt = 1 TO glob_arr_act_desc.getLength() 
			PUT ins_j_curs FROM glob_rec_kandoouser.cmpy_code, 
			glob_rec_activity.job_code, 
			glob_rec_activity.var_code, 
			glob_rec_activity.activity_code , 
			l_cnt, 
			glob_arr_act_desc[l_cnt] 
		END FOR 
		CLOSE ins_j_curs 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	COMMIT WORK 
END FUNCTION 
#######################################################################
# END FUNCTION insert_image()
#######################################################################


#######################################################################
# FUNCTION rename_act_code(p_ren_activity)
#
#
#######################################################################
FUNCTION rename_act_code(p_ren_activity) 
	DEFINE p_ren_activity RECORD LIKE activity.* 
	DEFINE l_img_act_code LIKE activity.activity_code 
	DEFINE l_img_title_text LIKE activity.title_text 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	INPUT 
		l_img_act_code, 
		l_img_title_text WITHOUT DEFAULTS 
	FROM 
		img_act_code, 
		img_title_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","actimage","input-act_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD img_act_code 
			IF l_img_act_code = p_ren_activity.activity_code THEN 
				ERROR kandoomsg2("J",9643,0)				#ERROR " Imaged Activity Code must be Unique"
				NEXT FIELD img_act_code 
			END IF 
			
			IF l_img_act_code IS NULL THEN 
				ERROR kandoomsg2("J",9644,0)				#ERROR " Imaged Activity Code must be Entered"
				NEXT FIELD img_act_code 
			ELSE 
				SELECT count(*) 
				INTO l_cnt 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = p_ren_activity.job_code 
				AND var_code = p_ren_activity.var_code 
				AND activity_code = l_img_act_code 
				IF l_cnt != 0 THEN 
					ERROR kandoomsg2("J",9643,0) 		#ERROR " Activity Exists - Imaged Activity must be Unique"
					NEXT FIELD img_act_code 
				END IF 
			END IF 
			
		ON ACTION "LOOKUP" --ON KEY (control-b) 
			IF infield (img_act_code) THEN 
				LET l_img_act_code = show_activity(
					glob_rec_kandoouser.cmpy_code, 
					glob_rec_activity.job_code, 
					glob_rec_activity.var_code ) 
				
				SELECT title_text 
				INTO l_img_title_text 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = p_ren_activity.job_code 
				AND var_code = p_ren_activity.var_code 
				AND activity_code = l_img_act_code 
				
				DISPLAY l_img_act_code TO img_act_code 
				DISPLAY l_img_title_text TO img_title_text 

			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		RETURN p_ren_activity.*, false 
	END IF 
	LET p_ren_activity.activity_code = l_img_act_code 
	LET p_ren_activity.title_text = l_img_title_text 

	RETURN p_ren_activity.*, true 
END FUNCTION 
#######################################################################
# END FUNCTION rename_act_code(p_ren_activity)
#######################################################################


#######################################################################
# FUNCTION delete_activity(p_delact_job_code,p_delact_var_code,p_delact_act_code)
#
#
#######################################################################
FUNCTION delete_activity(p_delact_job_code,p_delact_var_code,p_delact_act_code) 
	DEFINE p_delact_job_code LIKE activity.job_code 
	DEFINE p_delact_var_code LIKE activity.var_code 
	DEFINE p_delact_act_code LIKE activity.activity_code 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(40) 

	IF NOT act_deletable(
		p_delact_job_code, 
		p_delact_var_code, 
		p_delact_act_code) THEN 
		RETURN 
	END IF 
	
	GOTO bypass 
	LABEL recovery: 
	
	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue != "Y" THEN 
		EXIT program 
	END IF 
	
	LABEL bypass: 
	
	WHENEVER ERROR GOTO recovery
	 
	BEGIN WORK 
		LET l_err_message = " actimage - Deleting Activity " 
		
		DELETE FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = p_delact_job_code 
		AND var_code = p_delact_var_code 
		AND activity_code = p_delact_act_code 
		
		DELETE FROM act_desc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = p_delact_job_code 
		AND var_code = p_delact_var_code 
		AND activity_code = p_delact_act_code 
	COMMIT WORK
	 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
END FUNCTION 
#######################################################################
# END FUNCTION delete_activity(p_delact_job_code,p_delact_var_code,p_delact_act_code)
#######################################################################

#######################################################################
# FUNCTION act_deletable(p_delact_job_code, p_delact_var_code, p_delact_act_code)
#
#
#######################################################################
FUNCTION act_deletable(p_delact_job_code, p_delact_var_code, p_delact_act_code) 
	DEFINE 
	p_delact_job_code LIKE activity.job_code, 
	p_delact_var_code LIKE activity.var_code, 
	p_delact_act_code LIKE activity.activity_code, 
	l_post_revenue_amt LIKE activity.post_revenue_amt, 
	l_act_cost_amt LIKE activity.act_cost_amt, 
	l_act_cost_qty LIKE activity.act_cost_qty, 
	l_act_bill_amt LIKE activity.act_bill_amt, 
	l_post_cost_amt LIKE activity.post_cost_amt, 
	l_act_bill_qty LIKE activity.act_bill_qty, 
	l_cnt SMALLINT 

	SELECT count(*) 
	INTO l_cnt 
	FROM jobledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = p_delact_job_code 
	AND var_code = p_delact_var_code 
	AND activity_code = p_delact_act_code 
	IF l_cnt != 0 THEN 
		RETURN false 
	END IF 

	SELECT post_revenue_amt, 
	act_cost_amt, 
	act_cost_qty, 
	act_bill_amt, 
	post_cost_amt, 
	act_bill_qty 
	INTO l_post_revenue_amt, 
	l_act_cost_amt, 
	l_act_cost_qty, 
	l_act_bill_amt, 
	l_post_cost_amt, 
	l_act_bill_qty 
	FROM activity 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = p_delact_job_code 
	AND var_code = p_delact_var_code 
	AND activity_code = p_delact_act_code 
	IF l_post_revenue_amt != 0 
	OR l_act_cost_amt != 0 
	OR l_act_cost_qty != 0 
	OR l_act_bill_amt != 0 
	OR l_post_cost_amt != 0 
	OR l_act_bill_qty != 0 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#######################################################################
# END FUNCTION act_deletable(p_delact_job_code, p_delact_var_code, p_delact_act_code)
#######################################################################


#######################################################################
# FUNCTION accounts_on_coa(p_rec_job) 
#
#
#######################################################################
FUNCTION accounts_on_coa(p_rec_job) 
	DEFINE p_rec_job RECORD LIKE job.* 
	DEFINE l_acct_code LIKE coa.acct_code 
	
	# Note: Master Jobs (locked_ind = "0") do NOT require valid accts
	IF p_rec_job.locked_ind = "0" THEN 
		RETURN true 
	END IF
	 
	SELECT acct_code 
	INTO l_acct_code 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_activity.acct_code 
	IF status = notfound THEN 
		RETURN false 
	END IF
	 
	SELECT acct_code 
	INTO l_acct_code 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_activity.wip_acct_code 
	IF status = notfound THEN 
		RETURN false 
	END IF
	 
	SELECT acct_code 
	FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_activity.cos_acct_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 
#######################################################################
# END FUNCTION accounts_on_coa(p_rec_job) 
#######################################################################