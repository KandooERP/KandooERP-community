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




# Purpose - Job Management Master Job Edit & Deletion

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J11_GLOBALS.4gl" 

MAIN 

	#Initial UI Init
	CALL setModuleId("J1A") -- albo 
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
		LET msgresp = kandoomsg("J",7002,"") 
		#7002 " Must SET up JM Parameters first in JZP"
		EXIT program 
	END IF 
	OPEN WINDOW j107 with FORM "J107" -- alch kd-747 
	CALL winDecoration_j("J107") -- alch kd-747 
	WHILE select_job() 
	END WHILE 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j107 
END MAIN 


FUNCTION select_job() 
	DEFINE 
	where_text CHAR(200), 
	query_text CHAR(1000), 
	idx, scrn, 
	job_array_size, 
	job_delete_cnt SMALLINT, 
	pa_job array[240] OF RECORD 
		delete_flag CHAR(1), 
		job_code LIKE job.job_code, 
		title_text LIKE job.title_text, 
		type_code LIKE job.type_code, 
		cust_code LIKE job.cust_code, 
		sale_code LIKE job.sale_code 
	END RECORD 

	CLEAR FORM 
	LET job_delete_cnt = 0 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON 
	job_code, 
	title_text, 
	type_code, 
	cust_code, 
	sale_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","J1A","const-job_code-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET query_text = "SELECT job.* ", 
	"FROM job ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND locked_ind = \"0\" ", 
	"AND ", where_text clipped," ", 
	"ORDER BY job_code " 
	PREPARE s_job FROM query_text 
	DECLARE c_job CURSOR FOR s_job 
	LET idx = 0 
	FOREACH c_job INTO pr_job.* 
		LET idx = idx + 1 
		LET pa_job[idx].delete_flag = NULL 
		LET pa_job[idx].job_code = pr_job.job_code 
		LET pa_job[idx].title_text = pr_job.title_text 
		LET pa_job[idx].type_code = pr_job.type_code 
		LET pa_job[idx].cust_code = pr_job.cust_code 
		LET pa_job[idx].sale_code = pr_job.sale_code 
		IF idx = 240 THEN 
			LET msgresp = kandoomsg("U",9100,idx) 
			#9100 " First 240 Jobs Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET job_array_size = idx 
	IF job_array_size = 0 THEN 
		LET msgresp = kandoomsg("U",9101,"") 
		#9101 " No Jobs Selected - Try Again"
		RETURN true 
	END IF 
	LET msgresp = kandoomsg("J",1014,"") 
	#1014 " RETURN TO Edit - F2 TO Toggle Delete - ESC Re-SELECT"
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	CALL set_count(job_array_size) 
	INPUT ARRAY pa_job WITHOUT DEFAULTS FROM sr_job.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J1A","input_arr-pa_job-1") -- alch kd-506 

		ON KEY (F2) 
			IF pa_job[idx].delete_flag IS NULL THEN 
				SELECT count(*) 
				INTO cnt 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_job.job_code 
				IF cnt > 0 THEN 
					LET msgresp = kandoomsg("J",9490,"") 
					#9490 " Job Code ",pr_job.job_code clipped ,
					##    " has ",cnt," Activities - Cannot be Deleted"
				ELSE 
					LET pa_job[idx].delete_flag = "*" 
					DISPLAY pa_job[idx].delete_flag 
					TO sr_job[scrn].delete_flag 
					attribute(red) 
					LET job_delete_cnt = job_delete_cnt + 1 
				END IF 
			ELSE 
				LET pa_job[idx].delete_flag = NULL 
				DISPLAY pa_job[idx].delete_flag 
				TO sr_job[scrn].delete_flag 
				LET job_delete_cnt = job_delete_cnt - 1 
			END IF 
		BEFORE FIELD delete_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_job[idx].* 
			TO sr_job[scrn].* 

		AFTER FIELD delete_flag 
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#NEXT FIELD job_code
			--#END IF
			DISPLAY pa_job[idx].* 
			TO sr_job[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() > arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001"There are no more rows in the direction you are going"
				NEXT FIELD delete_flag 
			END IF 
		BEFORE FIELD job_code 
			LET pr_job.job_code = pa_job[idx].job_code 
			LET pr_job.title_text = pa_job[idx].title_text 
			LET pr_job.type_code = pa_job[idx].type_code 
			LET pr_job.cust_code = pa_job[idx].cust_code 
			IF pa_job[idx].job_code IS NULL THEN 
				NEXT FIELD delete_flag 
			END IF 
			CALL edit_job_details() 
			SELECT title_text 
			INTO pr_job.title_text 
			FROM job 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pr_job.job_code = job.job_code 
			LET pa_job[idx].title_text = pr_job.title_text 
			DISPLAY pa_job[idx].title_text 
			TO sr_job[scrn].title_text 

			NEXT FIELD delete_flag 
		AFTER ROW 
			IF pa_job[idx].delete_flag != "*" THEN 
				LET pa_job[idx].delete_flag = NULL 
			END IF 
			DISPLAY pa_job[idx].* 
			TO sr_job[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = true 
		LET quit_flag = true 
	ELSE 
		IF job_delete_cnt > 0 THEN 
			LET msgresp = kandoomsg("U",8020,job_delete_cnt) 
			#8020 " About TO Delete ",job_delete_cnt," Job/s ?(y/n)"
			IF msgresp = "Y" THEN 
				GOTO bypass 
				LABEL recovery: 
				LET err_continue = error_recover(err_message, status) 
				IF err_continue != "Y" THEN 
					EXIT program 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					LET err_message = " J1A - Deleting Jobs" 
					FOR idx = 1 TO job_array_size 
						IF pa_job[idx].delete_flag IS NOT NULL THEN 
							DELETE FROM job 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pa_job[idx].job_code 
							DELETE FROM jobvars 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pa_job[idx].job_code 
							DELETE FROM job_desc 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pa_job[idx].job_code 
						END IF 
					END FOR 
					WHENEVER ERROR stop 
				COMMIT WORK 
			END IF 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION edit_job_details() 
	DEFINE 
	pr_rowid INTEGER, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	cust_chg_ok CHAR(1), 
	cnt SMALLINT 
	OPEN WINDOW j100 with FORM "J100" -- alch kd-747 
	CALL winDecoration_j("J100") -- alch kd-747 
	CLEAR FORM 
	# SELECT tailoring option TO determine whether customer
	#          can be
	LET cust_chg_ok = get_kandoooption_feature_state("JM","02") 
	SELECT jobtype.* 
	INTO pr_jobtype.* 
	FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pr_job.type_code 
	SELECT customer.* 
	INTO pr_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_job.cust_code 
	SELECT salesperson.* 
	INTO pr_salesperson.* 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = pr_job.sale_code 
	SELECT job.* , 
	rowid 
	INTO pr_job.*, 
	pr_rowid 
	FROM job 
	WHERE job.job_code = pr_job.job_code 
	AND job.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE curr_job_desc CURSOR FOR 
	SELECT job_desc.* 
	FROM job_desc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND job_code = pr_job.job_code 
	ORDER BY seq_num 
	FOREACH curr_job_desc INTO pr_job_desc.* 
		LET cnt = pr_job_desc.seq_num 
		LET pa_job_desc[cnt] = pr_job_desc.desc_text 
	END FOREACH 
	CALL disp_report_code() 
	CALL display_details() 

	MENU "Job Edit" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J1A","menu-job_edit-2") -- alch kd-506 
		COMMAND "Details" " Amend Job Details" 
			WHILE true 

				INPUT pr_job.title_text, 
				pr_job.cust_code, 
				pr_job.sale_code 
				WITHOUT DEFAULTS FROM 
				job.title_text, 
				job.cust_code, 
				job.sale_code 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","J1A","input-pr_job-1") -- alch kd-506 
					BEFORE FIELD title_text 
						LET msgresp=kandoomsg("J",1004,"") 
						# MESSAGE" F10 TO Enter Full-Page Description"
					AFTER FIELD title_text 
						IF cust_chg_ok = "1" THEN 
							DECLARE cust_chk_cur CURSOR FOR 
							SELECT * 
							INTO pr_invoicehead.* 
							FROM invoicehead 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pr_job.job_code 
							AND inv_ind = '3' 

							FOREACH cust_chk_cur 
								IF status = notfound THEN 
									LET cust_chg_ok = "2" 
									EXIT FOREACH 
								ELSE 
									LET cust_chg_ok = "0" 
									EXIT FOREACH 
								END IF 
							END FOREACH 
						END IF 

						IF cust_chg_ok = "0" THEN 
							EXIT INPUT 
						END IF 

					ON KEY (F10) 
						CALL read_description(cnt) 
						RETURNING cnt 
					AFTER FIELD cust_code 
						IF pr_job.cust_code IS NULL THEN 
							LET msgresp=kandoomsg("U",9102,"") 
							# ERROR " Client Code must be entered "
							NEXT FIELD job.cust_code 
						END IF 
						SELECT * 
						INTO pr_customer.* 
						FROM customer 
						WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND customer.cust_code = pr_job.cust_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("U",9105,"") 
							#ERROR " No such Client Code - try help window "
							NEXT FIELD job.cust_code 
						ELSE 





							DISPLAY pr_customer.name_text TO customer.name_text 

						END IF 

					AFTER FIELD sale_code 
						IF pr_job.sale_code IS NULL THEN 
							LET msgresp = kandoomsg("E",9272,"") 
							## " Sale Code must be entered "
							NEXT FIELD job.sale_code 
						END IF 
						SELECT * 
						INTO pr_salesperson.* 
						FROM salesperson 
						WHERE salesperson.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND salesperson.sale_code = pr_job.sale_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("E",9273,"") 
							#### " No such Sale Code - try help window "
							NEXT FIELD job.sale_code 
						END IF 

					ON KEY (control-w) 
						CALL kandoohelp("") 
				END INPUT 

				IF int_flag OR quit_flag THEN 
					EXIT WHILE 
				END IF 
				CALL read_details() 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					CALL update_job(pr_rowid) 
					EXIT WHILE 
				END IF 
			END WHILE 
		COMMAND "Financials" " Amend Financial Job Details" 
			OPEN WINDOW j103 with FORM "J103" -- alch kd-747 
			CALL winDecoration_j("J103") -- alch kd-747 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.bill_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING bill_entry_mask 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.wip_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING wip_entry_mask 
			CALL build_mask(glob_rec_kandoouser.cmpy_code, 
			pr_jobtype.cos_acct_code, 
			pr_rec_kandoouser.acct_mask_code) 
			RETURNING cos_entry_mask 
			CALL read_financials() 
			CLOSE WINDOW j103 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL update_job(pr_rowid) 
			END IF 
		COMMAND "Page Description" " Amend Full Page Description Of Job Notes" 
			CALL read_description(cnt) 
			RETURNING cnt 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL update_job(pr_rowid) 
			END IF 
		COMMAND KEY (interrupt,"E") "Exit" " RETURN TO Main Menu" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	CLOSE WINDOW j100 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION update_job(pr_rowid) 
	DEFINE 
	pr_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF upshift(err_continue) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	BEGIN WORK 
		LET err_message = " J1A - Updating Job" 
		WHENEVER ERROR GOTO recovery 
		UPDATE job SET * = pr_job.* 
		WHERE rowid = pr_rowid 
		LET err_message = " J1A - Inserting job description" 
		LET ins_text = " INSERT INTO job_desc VALUES (?,?,?,?)" 
		DELETE FROM job_desc 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_job.job_code 
		FOR cnt = 1 TO 100 
			IF pa_job_desc[cnt] IS NOT NULL THEN 
				INSERT INTO job_desc VALUES (glob_rec_kandoouser.cmpy_code, 
				pr_job.job_code, 
				cnt, 
				pa_job_desc[cnt]) 
			END IF 
		END FOR 

		WHENEVER ERROR stop 
	COMMIT WORK 
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


FUNCTION disp_report_code() 
	IF pr_jobtype.prompt1_text IS NULL THEN 
		LET pr_jobtype.prompt1_text = pr_jmparms.prompt1_text 
		LET pr_jobtype.prompt1_ind = pr_jmparms.prompt1_ind 
	END IF 
	IF pr_jobtype.prompt2_text IS NULL THEN 
		LET pr_jobtype.prompt2_text = pr_jmparms.prompt2_text 
		LET pr_jobtype.prompt2_ind = pr_jmparms.prompt2_ind 
	END IF 
	IF pr_jobtype.prompt3_text IS NULL THEN 
		LET pr_jobtype.prompt3_text = pr_jmparms.prompt3_text 
		LET pr_jobtype.prompt3_ind = pr_jmparms.prompt3_ind 
	END IF 
	IF pr_jobtype.prompt4_text IS NULL THEN 
		LET pr_jobtype.prompt4_text = pr_jmparms.prompt4_text 
		LET pr_jobtype.prompt4_ind = pr_jmparms.prompt4_ind 
	END IF 
	IF pr_jobtype.prompt5_text IS NULL THEN 
		LET pr_jobtype.prompt5_text = pr_jmparms.prompt5_text 
		LET pr_jobtype.prompt5_ind = pr_jmparms.prompt5_ind 
	END IF 
	IF pr_jobtype.prompt6_text IS NULL THEN 
		LET pr_jobtype.prompt6_text = pr_jmparms.prompt6_text 
		LET pr_jobtype.prompt6_ind = pr_jmparms.prompt6_ind 
	END IF 
	IF pr_jobtype.prompt7_text IS NULL THEN 
		LET pr_jobtype.prompt7_text = pr_jmparms.prompt7_text 
		LET pr_jobtype.prompt7_ind = pr_jmparms.prompt7_ind 
	END IF 
	IF pr_jobtype.prompt8_text IS NULL THEN 
		LET pr_jobtype.prompt8_text = pr_jmparms.prompt8_text 
		LET pr_jobtype.prompt8_ind = pr_jmparms.prompt8_ind 
	END IF 
	IF pr_jobtype.prompt1_ind != 5 OR 
	pr_jobtype.prompt2_ind != 5 OR 
	pr_jobtype.prompt3_ind != 5 OR 
	pr_jobtype.prompt4_ind != 5 OR 
	pr_jobtype.prompt5_ind != 5 OR 
	pr_jobtype.prompt6_ind != 5 OR 
	pr_jobtype.prompt7_ind != 5 OR 
	pr_jobtype.prompt8_ind != 5 THEN 


		DISPLAY BY NAME pr_jobtype.prompt1_text, 
		pr_jobtype.prompt2_text, 
		pr_jobtype.prompt3_text, 
		pr_jobtype.prompt4_text, 
		pr_jobtype.prompt5_text, 
		pr_jobtype.prompt6_text, 
		pr_jobtype.prompt7_text, 
		pr_jobtype.prompt8_text 


	END IF 

END FUNCTION 

FUNCTION report_code() 
	IF pr_jobtype.prompt1_text IS NULL THEN 
		LET pr_jobtype.prompt1_text = pr_jmparms.prompt1_text 
		LET pr_jobtype.prompt1_ind = pr_jmparms.prompt1_ind 
	END IF 
	IF pr_jobtype.prompt2_text IS NULL THEN 
		LET pr_jobtype.prompt2_text = pr_jmparms.prompt2_text 
		LET pr_jobtype.prompt2_ind = pr_jmparms.prompt2_ind 
	END IF 
	IF pr_jobtype.prompt3_text IS NULL THEN 
		LET pr_jobtype.prompt3_text = pr_jmparms.prompt3_text 
		LET pr_jobtype.prompt3_ind = pr_jmparms.prompt3_ind 
	END IF 
	IF pr_jobtype.prompt4_text IS NULL THEN 
		LET pr_jobtype.prompt4_text = pr_jmparms.prompt4_text 
		LET pr_jobtype.prompt4_ind = pr_jmparms.prompt4_ind 
	END IF 
	IF pr_jobtype.prompt5_text IS NULL THEN 
		LET pr_jobtype.prompt5_text = pr_jmparms.prompt5_text 
		LET pr_jobtype.prompt5_ind = pr_jmparms.prompt5_ind 
	END IF 
	IF pr_jobtype.prompt6_text IS NULL THEN 
		LET pr_jobtype.prompt6_text = pr_jmparms.prompt6_text 
		LET pr_jobtype.prompt6_ind = pr_jmparms.prompt6_ind 
	END IF 
	IF pr_jobtype.prompt7_text IS NULL THEN 
		LET pr_jobtype.prompt7_text = pr_jmparms.prompt7_text 
		LET pr_jobtype.prompt7_ind = pr_jmparms.prompt7_ind 
	END IF 
	IF pr_jobtype.prompt8_text IS NULL THEN 
		LET pr_jobtype.prompt8_text = pr_jmparms.prompt8_text 
		LET pr_jobtype.prompt8_ind = pr_jmparms.prompt8_ind 
	END IF 
	IF pr_jobtype.prompt1_ind != 5 OR 
	pr_jobtype.prompt2_ind != 5 OR 
	pr_jobtype.prompt3_ind != 5 OR 
	pr_jobtype.prompt4_ind != 5 OR 
	pr_jobtype.prompt5_ind != 5 OR 
	pr_jobtype.prompt6_ind != 5 OR 
	pr_jobtype.prompt7_ind != 5 OR 
	pr_jobtype.prompt8_ind != 5 THEN 
		OPEN WINDOW j184 with FORM "J184" -- alch kd-747 
		CALL winDecoration_j("J184") -- alch kd-747 
		DISPLAY BY NAME pr_jobtype.prompt1_text, 
		pr_jobtype.prompt2_text, 
		pr_jobtype.prompt3_text, 
		pr_jobtype.prompt4_text, 
		pr_jobtype.prompt5_text, 
		pr_jobtype.prompt6_text, 
		pr_jobtype.prompt7_text, 
		pr_jobtype.prompt8_text 

		INPUT BY NAME pr_job.report1_text, 
		pr_job.report2_text, 
		pr_job.report3_text, 
		pr_job.report4_text, 
		pr_job.report5_text, 
		pr_job.report6_text, 
		pr_job.report7_text, 
		pr_job.report8_text WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J1A","input-pr_job-2") -- alch kd-506 
			BEFORE FIELD report1_text 
				IF pr_jobtype.prompt1_ind = 5 THEN 
					NEXT FIELD report2_text 
				END IF 
			AFTER FIELD report1_text 
				IF pr_jobtype.prompt1_ind = 2 AND 
				pr_job.report1_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report1_text 
				END IF 
			BEFORE FIELD report2_text 
				IF pr_jobtype.prompt2_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report1_text 
					ELSE 
						NEXT FIELD report3_text 
					END IF 
				END IF 
			AFTER FIELD report2_text 
				IF pr_jobtype.prompt2_ind = 2 AND 
				pr_job.report2_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report2_text 
				END IF 
			BEFORE FIELD report3_text 
				IF pr_jobtype.prompt3_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report2_text 
					ELSE 
						NEXT FIELD report4_text 
					END IF 
				END IF 
			AFTER FIELD report3_text 
				IF pr_jobtype.prompt3_ind = 2 AND 
				pr_job.report3_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report3_text 
				END IF 
			BEFORE FIELD report4_text 
				IF pr_jobtype.prompt4_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report3_text 
					ELSE 
						NEXT FIELD report5_text 
					END IF 
				END IF 
			AFTER FIELD report4_text 
				IF pr_jobtype.prompt4_ind = 2 AND 
				pr_job.report4_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report4_text 
				END IF 
			BEFORE FIELD report5_text 
				IF pr_jobtype.prompt5_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report4_text 
					ELSE 
						NEXT FIELD report6_text 
					END IF 
				END IF 
			AFTER FIELD report5_text 
				IF pr_jobtype.prompt5_ind = 2 AND 
				pr_job.report5_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report5_text 
				END IF 
			BEFORE FIELD report6_text 
				IF pr_jobtype.prompt6_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report5_text 
					ELSE 
						NEXT FIELD report7_text 
					END IF 
				END IF 
			AFTER FIELD report6_text 
				IF pr_jobtype.prompt6_ind = 2 AND 
				pr_job.report6_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report6_text 
				END IF 
			BEFORE FIELD report7_text 
				IF pr_jobtype.prompt7_ind = 5 THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD report6_text 
					ELSE 
						NEXT FIELD report8_text 
					END IF 
				END IF 

			AFTER FIELD report7_text 
				IF pr_jobtype.prompt7_ind = 2 AND 
				pr_job.report7_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report7_text 
				END IF 

			BEFORE FIELD report8_text 
				IF pr_jobtype.prompt8_ind = 5 THEN 
					EXIT INPUT 
				END IF 

			AFTER FIELD report8_text 
				IF pr_jobtype.prompt8_ind = 2 AND 
				pr_job.report8_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report8_text 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 
				IF pr_jobtype.prompt1_ind = 2 AND 
				pr_job.report1_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report1_text 
				END IF 
				IF pr_jobtype.prompt2_ind = 2 AND 
				pr_job.report2_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report2_text 
				END IF 
				IF pr_jobtype.prompt3_ind = 2 AND 
				pr_job.report3_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report3_text 
				END IF 
				IF pr_jobtype.prompt4_ind = 2 AND 
				pr_job.report4_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report4_text 
				END IF 
				IF pr_jobtype.prompt5_ind = 2 AND 
				pr_job.report5_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report5_text 
				END IF 
				IF pr_jobtype.prompt6_ind = 2 AND 
				pr_job.report6_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report6_text 
				END IF 
				IF pr_jobtype.prompt7_ind = 2 AND 
				pr_job.report7_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report7_text 
				END IF 
				IF pr_jobtype.prompt8_ind = 2 AND 
				pr_job.report8_text IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 " Must enter User Prompt Text"
					NEXT FIELD report8_text 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW j184 
	END IF 
END FUNCTION 
