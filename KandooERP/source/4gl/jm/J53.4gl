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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module J53, job management TO add activities TO a job
# Using "Imaging "


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
	CALL setModuleId("J53") -- albo 
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
		#ERROR " Must SET up JM Parameters first in JZP"
		LET msgresp = kandoomsg("J",1501," ") 
		SLEEP 5 
		EXIT program 
	END IF 
	OPEN WINDOW j157 with FORM "J157" -- alch kd-747 
	CALL winDecoration_j("J157") -- alch kd-747 
	WHILE image_act() 
	END WHILE 
	CLOSE WINDOW j157 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 

FUNCTION image_act() 
	DEFINE 
	pa_activity array[200] OF RECORD LIKE activity.*, 
	ps_activity RECORD LIKE activity.*, 
	source_job_code LIKE job.job_code, 
	source_var_code LIKE activity.var_code, 
	source_activity_code LIKE activity.activity_code, 
	tgt_job_code LIKE job.job_code, 
	tgt_acct_code LIKE job.acct_code, 
	rev_desc_text LIKE coa.desc_text, 
	tgt_wip_acct_code LIKE job.wip_acct_code, 
	wip_desc_text LIKE coa.desc_text, 
	tgt_cos_acct_code LIKE job.cos_acct_code, 
	cos_desc_text LIKE coa.desc_text, 
	est_ind, bdgt_ind, pr_image_desc CHAR(1), 
	est_per, bdgt_per DECIMAL(5,2), 
	fv_resbdgt SMALLINT, 
	idx, r, scrn, actcnt, cnt, pr_return_status, validation_type SMALLINT, 
	pr_msg CHAR(50) 

	# Resource budgets ?
	IF get_kandoooption_feature_state("JM", "W1") matches "[yY]" THEN 
		LET fv_resbdgt = true 
		LET bdgt_ind = "Z" 
		LET est_ind = "Z" 
	ELSE 
		LET fv_resbdgt = false 
		LET bdgt_ind = "B" 
		LET est_ind = "E" 
	END IF 

	LET pr_image_desc = "Y" 
	WHILE true 
		CLEAR FORM 
		# Check flag FOR resource budgets
		IF fv_resbdgt THEN 
			LET msgresp = kandoomsg("J",1522," ") 
		END IF 
		INPUT source_job_code, 
		source_var_code, 
		tgt_job_code, 
		tgt_acct_code, 
		tgt_wip_acct_code, 
		tgt_cos_acct_code, 
		bdgt_ind, 
		bdgt_per, 
		est_ind, 
		est_per, 
		pr_image_desc WITHOUT DEFAULTS 
		FROM source_job_code, 
		var_code, 
		tgt_job_code, 
		acct_code, 
		wip_acct_code, 
		cos_acct_code, 
		bdgt_ind, 
		bdgt_per, 
		est_ind, 
		est_per, 
		image_desc 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J53","input-source_job_code-1") -- alch kd-506 

			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(source_job_code) 
						LET source_job_code = 
						showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						DISPLAY source_job_code 
						TO source_job_code 

					WHEN infield(tgt_job_code) 
						LET tgt_job_code = 
						showujobs(glob_rec_kandoouser.cmpy_code, pr_user_scan_code) 
						DISPLAY tgt_job_code 
						TO tgt_job_code 

				END CASE 
			AFTER FIELD source_job_code 
				IF source_job_code IS NULL THEN 
					#ERROR " Source Job Code must be entered"
					LET msgresp = kandoomsg("J",9570," ") 
					NEXT FIELD source_job_code 
				ELSE 
					SELECT * 
					INTO pr_job.* 
					FROM job 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = source_job_code 
					AND (acct_code matches pr_user_scan_code 
					OR locked_ind <= "1") 
					IF status = notfound THEN 
						#error" Job NOT found - Try Window"
						LET msgresp = kandoomsg("J",9558," ") 
						NEXT FIELD source_job_code 
					ELSE 
						DISPLAY pr_job.title_text 
						TO source_title_text 

					END IF 
				END IF 
			AFTER FIELD var_code 
				IF source_var_code IS NULL 
				OR source_var_code = 0 THEN 
					LET source_var_code = 0 
					DISPLAY source_var_code 
					TO var_code 

				ELSE 
					SELECT title_text 
					INTO pr_jobvars.title_text 
					FROM jobvars 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND job_code = source_job_code 
					AND var_code = source_var_code 
					IF status = notfound THEN 
						#error"Source Job Variation NOT found - Try Window (W)"
						LET msgresp = kandoomsg("J",9510," ") 
						NEXT FIELD var_code 
					ELSE 
						DISPLAY BY NAME pr_jobvars.title_text 

					END IF 
				END IF 
			AFTER FIELD tgt_job_code 
				IF tgt_job_code IS NULL THEN 
					#ERROR " Target Job Code must be entered"
					LET msgresp = kandoomsg("J",9571," ") 
					NEXT FIELD tgt_job_code 
				END IF 
				IF tgt_job_code = source_job_code THEN 
					LET msgresp = kandoomsg("J",9645,0) 
					# source & target jobs must NOT be the same
					NEXT FIELD tgt_job_code 
				END IF 
				SELECT job.* 
				INTO pr_job.* 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = tgt_job_code 
				AND (acct_code matches pr_user_scan_code 
				OR locked_ind <= "1") 

				IF status = notfound THEN 
					#error" Target Job NOT found - Try Window"
					LET msgresp = kandoomsg("J",9558," ") 
					NEXT FIELD tgt_job_code 
				END IF 

				LET tgt_acct_code = pr_job.acct_code 
				LET tgt_wip_acct_code = pr_job.wip_acct_code 
				LET tgt_cos_acct_code = pr_job.cos_acct_code 

				CALL get_acct_masks(pr_job.type_code) 
				# Add revenue account
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
				IF pr_job.locked_ind = "0" THEN 
					LET validation_type = 2 
				ELSE 
					LET validation_type = 1 
				END IF 

				DISPLAY pr_job.title_text , 
				tgt_acct_code, 
				tgt_wip_acct_code, 
				tgt_cos_acct_code 
				TO tgt_title_text, 
				acct_code, 
				wip_acct_code, 
				cos_acct_code 


				NEXT FIELD acct_code 


				# Add revenue account
			BEFORE FIELD acct_code 





				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J53", 
				entry_mask, 
				tgt_acct_code, 
				validation_type, 
				"REV Account") 
				RETURNING tgt_acct_code, rev_desc_text, entry_flag 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					DISPLAY tgt_acct_code TO acct_code 
					DISPLAY rev_desc_text TO rev_desc_text 
					NEXT FIELD wip_acct_code 
				END IF 

			BEFORE FIELD wip_acct_code 





				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J53", 
				wip_entry_mask, 
				tgt_wip_acct_code, 
				validation_type, 
				"WIP Account") 
				RETURNING tgt_wip_acct_code, wip_desc_text, entry_flag 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					DISPLAY tgt_wip_acct_code TO wip_acct_code 
					DISPLAY wip_desc_text TO wip_desc_text 
					NEXT FIELD cos_acct_code 
				END IF 
			BEFORE FIELD cos_acct_code 





				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J53", 
				cos_entry_mask, 
				tgt_cos_acct_code, 
				validation_type, 
				"COS Account") 
				RETURNING tgt_cos_acct_code, cos_desc_text, entry_flag 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					DISPLAY tgt_cos_acct_code TO cos_acct_code 
					DISPLAY cos_desc_text TO cos_desc_text 
				END IF 
				#Skip fields IF resource budget flag
			BEFORE FIELD bdgt_ind 
				IF fv_resbdgt THEN 
					NEXT FIELD image_desc 
				END IF 
			BEFORE FIELD bdgt_per 
				IF bdgt_ind = "Z" THEN 
					NEXT FIELD est_ind 
				END IF 
			AFTER FIELD bdgt_per 
				IF bdgt_per IS NULL THEN 
					LET bdgt_per = 0 
					DISPLAY bdgt_per 
					TO bdgt_per 

				END IF 
				#Skip fields IF resource budget flag
			BEFORE FIELD est_ind 
				IF fv_resbdgt THEN 
					NEXT FIELD image_desc 
				END IF 
			BEFORE FIELD est_per 
				IF est_ind = "Z" THEN 
					NEXT FIELD image_desc 
				END IF 
			AFTER FIELD est_per 
				IF est_per IS NULL THEN 
					LET est_per = 0 
					DISPLAY est_per 
					TO est_per 

				END IF 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				IF source_job_code IS NULL THEN 
					#ERROR " Source Job Code must be entered"
					LET msgresp = kandoomsg("J",9570," ") 
					NEXT FIELD source_job_code 
				END IF 
				IF source_var_code IS NULL 
				OR source_var_code = 0 THEN 
					LET source_var_code = 0 
					DISPLAY source_var_code 
					TO var_code 

				END IF 
				IF tgt_job_code IS NULL THEN 
					#ERROR " Target Job Code must be entered"
					LET msgresp = kandoomsg("J",9571," ") 
					NEXT FIELD tgt_job_code 
				END IF 
				IF tgt_acct_code IS NULL THEN 
					CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J53", 
					entry_mask, 
					tgt_acct_code, 
					validation_type, 
					"REV Account") 
					RETURNING tgt_acct_code, rev_desc_text, entry_flag 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					ELSE 
						DISPLAY tgt_acct_code TO acct_code 
						DISPLAY rev_desc_text TO rev_desc_text 
					END IF 
				END IF 
				IF tgt_wip_acct_code IS NULL THEN 
					CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J53", 
					wip_entry_mask, 
					tgt_wip_acct_code, 
					validation_type, 
					"WIP Account") 
					RETURNING tgt_wip_acct_code, wip_desc_text, entry_flag 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					ELSE 
						DISPLAY tgt_wip_acct_code TO wip_acct_code 
						DISPLAY wip_desc_text TO wip_desc_text 
					END IF 
				END IF 
				IF tgt_cos_acct_code IS NULL THEN 
					CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J53", 
					cos_entry_mask, 
					tgt_cos_acct_code, 
					validation_type, 
					"COS Account") 
					RETURNING tgt_cos_acct_code, cos_desc_text, entry_flag 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					ELSE 
						DISPLAY tgt_cos_acct_code TO cos_acct_code 
						DISPLAY cos_desc_text TO cos_desc_text 
					END IF 
				END IF 
				# Add revenue account
				SELECT desc_text 
				INTO rev_desc_text 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = tgt_acct_code 
				IF status = notfound THEN 
					#ERROR " Revenue Account must be entered"
					LET msgresp = kandoomsg("J",9202," ") 
					NEXT FIELD acct_code 
				END IF 

				SELECT desc_text 
				INTO wip_desc_text 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = tgt_wip_acct_code 
				IF status = notfound THEN 
					#ERROR " WIP Account must be entered"
					LET msgresp = kandoomsg("J",9203," ") 
					NEXT FIELD wip_acct_code 
				END IF 
				SELECT desc_text 
				INTO cos_desc_text 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = tgt_cos_acct_code 
				IF status = notfound THEN 
					#ERROR " COS Account must be entered"
					LET msgresp = kandoomsg("J",9205," ") 
					NEXT FIELD cos_acct_code 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 


		IF int_flag OR quit_flag THEN 
			RETURN false 
		END IF 
		DECLARE actcurs CURSOR FOR 
		SELECT activity.* 
		INTO ps_activity.* 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = source_job_code 
		AND var_code = source_var_code 
		LET idx = 0 
		FOREACH actcurs 
			LET idx = idx + 1 
			LET ps_activity.job_code = pr_job.job_code 
			LET ps_activity.var_code = 0 

			# This IS FOR unresolved segments OTHERWISE use imaged activity wip AND cos accounts
			# Add revenue account
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			ps_activity.acct_code, 
			tgt_acct_code) 
			RETURNING ps_activity.acct_code 

			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			ps_activity.wip_acct_code, 
			tgt_wip_acct_code) 
			RETURNING ps_activity.wip_acct_code 

			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			ps_activity.cos_acct_code, 
			tgt_cos_acct_code) 
			RETURNING ps_activity.cos_acct_code 




			LET pa_activity[idx].* = ps_activity.* 
			IF idx = 200 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 0 THEN 
			#ERROR "Job ",source_job_code clipped, "has no Activities"
			LET msgresp = kandoomsg("J",9572,source_job_code) 
			SLEEP 3 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	FOR cnt = 1 TO idx 
		LET pr_return_status = true 
		SELECT count(*) 
		INTO actcnt 
		FROM activity 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_job.job_code 
		AND var_code = 0 
		AND activity_code = pa_activity[cnt].activity_code 
		LET pr_msg = pr_activity.activity_code clipped, 
		" Number ",cnt," of ",idx 
		LET msgresp = kandoomsg("J",1023, pr_msg) 
		LET source_activity_code = pa_activity[cnt].activity_code 
		# MESSAGE" Adding Activity :",pa_activity[cnt].activity_code clipped,
		#" - Number ",cnt," of ",idx
		IF actcnt != 0 THEN 
			CALL validate_activity(pa_activity[cnt].*) 
			RETURNING pa_activity[cnt].*, pr_return_status 
			IF NOT pr_return_status THEN 
				CONTINUE FOR 
			END IF 
		END IF 
		LET pr_activity.* = pa_activity[cnt].* 
		CASE (bdgt_ind) 
			WHEN "A" 
				LET pr_activity.bdgt_cost_amt = 
				pa_activity[cnt].act_cost_amt 
				* (bdgt_per/100 + 1) 
				LET pr_activity.bdgt_cost_qty = 
				pa_activity[cnt].act_cost_qty 
				* (bdgt_per/100 + 1) 
			WHEN "B" 
				LET pr_activity.bdgt_cost_amt = 
				pa_activity[cnt].bdgt_cost_amt 
				* (bdgt_per/100 + 1) 
				LET pr_activity.bdgt_cost_qty = 
				pa_activity[cnt].bdgt_cost_qty 
				* (bdgt_per/100 + 1) 
			WHEN "E" 
				LET pr_activity.bdgt_cost_amt = 
				pa_activity[cnt].est_cost_amt 
				* (bdgt_per/100 + 1) 
				LET pr_activity.bdgt_cost_qty = 
				pa_activity[cnt].est_cost_qty 
				* (bdgt_per/100 + 1) 
			WHEN "Z" 
				LET pr_activity.bdgt_cost_amt = 0 
				LET pr_activity.bdgt_cost_qty = 0 
		END CASE 
		CASE (est_ind) 
			WHEN "A" 
				LET pr_activity.est_cost_amt = 
				pa_activity[cnt].act_cost_amt 
				* (est_per/100 + 1) 
				LET pr_activity.est_cost_qty = 
				pa_activity[cnt].act_cost_qty 
				* (est_per/100 + 1) 
			WHEN "B" 
				LET pr_activity.est_cost_amt = 
				pa_activity[cnt].bdgt_cost_amt 
				* (est_per/100 + 1) 
				LET pr_activity.est_cost_qty = 
				pa_activity[cnt].bdgt_cost_qty 
				* (est_per/100 + 1) 
			WHEN "E" 
				LET pr_activity.est_cost_amt = 
				pa_activity[cnt].est_cost_amt 
				* (est_per/100 + 1) 
				LET pr_activity.est_cost_qty = 
				pa_activity[cnt].est_cost_qty 
				* (est_per/100 + 1) 
			WHEN "Z" 
				LET pr_activity.est_cost_amt = 0 
				LET pr_activity.est_cost_qty = 0 
		END CASE 
		LET pr_activity.est_start_date = pr_job.est_start_date 
		LET pr_activity.est_end_date = pr_job.est_end_date 
		LET pr_activity.act_start_date = NULL 
		LET pr_activity.act_end_date = NULL 
		LET pr_activity.next_bill_date = NULL 
		LET pr_activity.act_cost_amt = 0 
		LET pr_activity.act_cost_qty = 0 
		LET pr_activity.est_comp_per = 0 
		LET pr_activity.post_cost_amt = 0 
		LET pr_activity.post_revenue_amt = 0 
		LET pr_activity.act_bill_amt = 0 
		LET pr_activity.act_bill_qty = 0 
		LET pr_activity.seq_num = 0 
		LET pr_activity.finish_flag = "N" 

		LET r = 1 
		FOR r = r TO 100 
			INITIALIZE pa_act_desc[r] TO NULL 
		END FOR 

		IF pr_image_desc = "Y" THEN 
			DECLARE c_desc CURSOR FOR 
			SELECT desc_text, 
			seq_num 
			FROM act_desc 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = source_job_code 
			AND var_code = source_var_code 
			AND activity_code = source_activity_code 
			ORDER BY seq_num 
			LET act_desc_cnt = 1 
			FOREACH c_desc INTO pa_act_desc[act_desc_cnt], 
				pr_act_desc.seq_num 
				LET act_desc_cnt = act_desc_cnt + 1 
			END FOREACH 
		ELSE 
			SLEEP 2 
			LET act_desc_cnt = 0 
		END IF 
		CALL insert_image() 
	END FOR 
	MESSAGE "" 
	RETURN true 
END FUNCTION 

