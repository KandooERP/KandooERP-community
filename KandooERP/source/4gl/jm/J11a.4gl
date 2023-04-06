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

	Source code beautified by beautify.pl on 2020-01-02 19:48:01	$Id: $
}


#GLOBALS "../common/glob_GLOBALS.4gl"
#used as GLOBALS FROM J11.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J11_GLOBALS.4gl" 

#  J11a - Globals/Job addition

#  This Module contains 5 Functions
#    read_details       -   used by the INPUT job J11 AND UPDATE job J14
#    display_rep_codes  -   used by the inquiry job J12 AND UPDATE job J14
#    display_details    -   used by the UPDATE job J14
#    read_financials    -   used by the INPUT job J11 AND UPDATE job J14
#    display_financials -   used by the INPUT job J11 AND UPDATE job J14
#    read_description   -   used by the INPUT job J11 AND UPDATE job J14


FUNCTION read_details() 
	DEFINE 
	master_job SMALLINT 

	IF pr_job.locked_ind = "0" THEN 
		LET master_job = true 
	ELSE 
		LET master_job = false 
	END IF 
	INPUT BY NAME 
	pr_job.est_start_date, 
	pr_job.est_end_date, 
	pr_job.review_date, 
	pr_job.val_date, 
	pr_job.contract_text, 
	pr_job.contract_date, 
	pr_job.contract_amt, 
	pr_job.locked_ind, 
	pr_job.report_text, 
	pr_job.resp_code, 
	pr_job.internal_flag, 
	pr_job.report1_text, 
	pr_job.report2_text, 
	pr_job.report3_text, 
	pr_job.report4_text, 
	pr_job.report5_text, 
	pr_job.report6_text, 
	pr_job.report7_text, 
	pr_job.report8_text 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J11a","input-pr_job-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield (resp_code) THEN 
				LET pr_job.resp_code = show_resp(glob_rec_kandoouser.cmpy_code) 
				DISPLAY pr_job.resp_code 
				TO job.resp_code 

			END IF 
		AFTER FIELD resp_code 
			IF pr_job.resp_code IS NOT NULL THEN 
				SELECT responsible.* 
				FROM responsible 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND resp_code = pr_job.resp_code 
				IF status = notfound THEN 
					ERROR " Responsibility Code Does Not Exist - Try Window" 
					NEXT FIELD resp_code 
				END IF 
				SELECT name_text 
				INTO pr_responsible.name_text 
				FROM responsible 
				WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND responsible.resp_code = pr_job.resp_code 
				IF status != notfound THEN 
					DISPLAY pr_responsible.name_text 
					TO resp_name_text 

				END IF 
			END IF 
		AFTER FIELD locked_ind 
			IF (master_job AND pr_job.locked_ind != "0") OR 
			((NOT master_job) AND pr_job.locked_ind = "0") THEN 
				ERROR " Locked STATUS IS 0 only FOR master jobs" 
				NEXT FIELD locked_ind 
			END IF 
		BEFORE FIELD report1_text 
			IF pr_jobtype.prompt1_ind = 5 THEN 
				NEXT FIELD report2_text 
			END IF 
		AFTER FIELD report1_text 
			IF NOT master_job THEN 
				IF pr_jobtype.prompt1_ind = 2 AND 
				pr_job.report1_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report1_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt2_ind = 2 AND 
				pr_job.report2_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report2_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt3_ind = 2 AND 
				pr_job.report3_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report3_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt4_ind = 2 AND 
				pr_job.report4_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report4_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt5_ind = 2 AND 
				pr_job.report5_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report5_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt6_ind = 2 AND 
				pr_job.report6_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report6_text 
				END IF 
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
			IF NOT master_job THEN 
				IF pr_jobtype.prompt7_ind = 2 AND 
				pr_job.report7_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report7_text 
				END IF 
			END IF 

		BEFORE FIELD report8_text 
			IF pr_jobtype.prompt8_ind = 5 THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD report8_text 
			IF NOT master_job THEN 
				IF pr_jobtype.prompt8_ind = 2 AND 
				pr_job.report8_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report8_text 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF pr_job.est_start_date > pr_job.est_end_date THEN 
				ERROR "Job start date must preceed Job END date" 
				NEXT FIELD est_start_date 
			END IF 
			IF (master_job AND pr_job.locked_ind != "0") OR 
			((NOT master_job) AND pr_job.locked_ind = "0") THEN 
				ERROR " Locked STATUS IS 0 only FOR master jobs" 
				NEXT FIELD locked_ind 
			END IF 
			IF master_job AND pr_job.finish_flag != "Y" THEN 
				ERROR " Finished flag IS Y FOR master jobs" 
				NEXT FIELD locked_ind 
			END IF 


			IF pr_job.resp_code IS NOT NULL THEN 
				SELECT responsible.* 
				FROM responsible 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND resp_code = pr_job.resp_code 
				IF status = notfound THEN 
					ERROR " Responsibility Code Does Not Exist - Try Window" 
					NEXT FIELD resp_code 
				END IF 

				SELECT name_text 
				INTO pr_responsible.name_text 
				FROM responsible 
				WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND responsible.resp_code = pr_job.resp_code 
				IF status != notfound THEN 
					DISPLAY pr_responsible.name_text 
					TO resp_name_text 

				END IF 
			END IF 


			IF NOT master_job THEN 
				IF pr_jobtype.prompt1_ind = 2 AND 
				pr_job.report1_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report1_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt2_ind = 2 AND 
				pr_job.report2_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report2_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt3_ind = 2 AND 
				pr_job.report3_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report3_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt4_ind = 2 AND 
				pr_job.report4_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report4_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt5_ind = 2 AND 
				pr_job.report5_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report5_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt6_ind = 2 AND 
				pr_job.report6_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report6_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt7_ind = 2 AND 
				pr_job.report7_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report7_text 
				END IF 
			END IF 

			IF NOT master_job THEN 
				IF pr_jobtype.prompt8_ind = 2 AND 
				pr_job.report8_text IS NULL THEN 
					ERROR " Must enter User Prompt Text" 
					NEXT FIELD report8_text 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION display_rep_codes() 
	DISPLAY BY NAME 
	pr_jmparms.prompt1_text, 
	pr_jmparms.prompt2_text, 
	pr_jmparms.prompt3_text, 
	pr_jmparms.prompt4_text, 
	pr_jmparms.prompt5_text, 
	pr_jmparms.prompt6_text, 
	pr_jmparms.prompt7_text, 
	pr_jmparms.prompt8_text 
	attribute(white) 
END FUNCTION 


FUNCTION display_details() 

	SELECT name_text 
	INTO pr_responsible.name_text 
	FROM responsible 
	WHERE responsible.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND responsible.resp_code = pr_job.resp_code 
	IF status != notfound THEN 
		DISPLAY pr_responsible.name_text 
		TO resp_name_text 

	END IF 
	DISPLAY BY NAME 
	pr_job.job_code, 
	pr_job.title_text, 
	pr_job.type_code, 
	pr_jobtype.type_text, 
	pr_job.cust_code, 
	pr_customer.name_text, 
	pr_job.est_start_date, 
	pr_job.est_end_date, 
	pr_job.review_date, 
	pr_job.val_date, 
	pr_job.act_start_date, 
	pr_job.act_end_date, 
	pr_job.contract_text, 
	pr_job.contract_date, 
	pr_job.contract_amt, 
	pr_job.locked_ind, 
	pr_job.finish_flag, 

	pr_job.report_text, 

	pr_job.resp_code, 


	pr_job.internal_flag, 
	pr_job.report1_text, 
	pr_job.report2_text, 
	pr_job.report3_text, 
	pr_job.report4_text, 
	pr_job.report5_text, 
	pr_job.report6_text, 
	pr_job.report7_text, 
	pr_job.report8_text 


END FUNCTION 


FUNCTION read_financials() 

	DEFINE 
	validation_type SMALLINT, 
	pr_year_num, pr_period_num SMALLINT, 
	pr_bill_way_ind LIKE job.bill_way_ind, 
	pr_response_text LIKE kandooword.response_text, 
	pr_language_code LIKE language.language_code 

	CALL get_kandoo_user() RETURNING pr_rec_kandoouser.* 
	#Get tailoring option TO indicated whether TO validate accounts
	LET pr_validate_ind = get_kandoooption_feature_state("JM","03") 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING pr_year_num, pr_period_num 
	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_job.acct_code) 
	RETURNING bill_acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_job.acct_code 
	DISPLAY acct_desc_text 
	TO desc_text 

	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_job.wip_acct_code) 
	RETURNING wip_acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_job.wip_acct_code 
	DISPLAY acct_desc_text 
	TO wip_desc_text 

	CALL validate_acct(glob_rec_kandoouser.cmpy_code,pr_job.cos_acct_code) 
	RETURNING cos_acct_flag, 
	acct_desc_text 
	DISPLAY BY NAME pr_job.cos_acct_code 
	DISPLAY acct_desc_text 
	TO cos_desc_text 

	INPUT BY NAME 
	pr_job.bill_way_ind, 
	pr_job.markup_per, 
	pr_job.bill_when_ind, 
	pr_job.bill_issue_ind, 
	pr_job.acct_code, 
	pr_job.wip_acct_code, 
	pr_job.cos_acct_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J11a","input-pr_job-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(bill_way_ind) 
					LET pr_bill_way_ind = show_kandooword("job.bill_way_ind") 
					IF pr_bill_way_ind IS NOT NULL THEN 
						LET pr_job.bill_way_ind = pr_bill_way_ind 
					END IF 
					DISPLAY pr_job.bill_way_ind 
					TO bill_way_ind 

					NEXT FIELD bill_way_ind 
			END CASE 
		AFTER FIELD bill_way_ind 
			IF pr_job.bill_way_ind IS NOT NULL THEN 
				SELECT response_text 
				INTO pr_response_text 
				FROM kandooword 
				WHERE language_code = pr_rec_kandoouser.language_code 
				AND reference_text = "job.bill_way_ind" 
				AND reference_code = pr_job.bill_way_ind 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9648,0) 
					NEXT FIELD bill_way_ind 
				ELSE 
					DISPLAY pr_response_text 
					TO bill_way_text 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("J",9648,0) 
				NEXT FIELD bill_way_ind 
			END IF 

		AFTER FIELD markup_per 
			IF pr_job.markup_per IS NULL THEN 
				LET pr_job.markup_per = 0 
				DISPLAY BY NAME pr_job.markup_per 

			END IF 
		AFTER FIELD bill_when_ind 
			CASE (pr_job.bill_when_ind) 
				WHEN "1" 
					DISPLAY "Daily" 
					TO bill_when_text 

				OTHERWISE 
					CLEAR bill_when_text 
					ERROR "Invoice Interval must =(1) until", 
					" this facility IS fully implemented" 
					NEXT FIELD bill_when_ind 
			END CASE 
		AFTER FIELD bill_issue_ind 
			CASE (pr_job.bill_issue_ind) 
				WHEN "1" 
					DISPLAY "Summary " 
					TO bill_issue_text 

					NEXT FIELD acct_code 
				WHEN "2" 
					DISPLAY "Detailed " 
					TO bill_issue_text 

					NEXT FIELD acct_code 

				WHEN "3" 
					DISPLAY "Summary/Descrpt" 
					TO bill_issue_text 

					NEXT FIELD acct_code 
				WHEN "4" 
					DISPLAY "Detail/Descript" 
					TO bill_issue_text 

					NEXT FIELD acct_code 

				OTHERWISE 
					CLEAR bill_issue_text 
					ERROR " Invoice Issue must be (1), (2), (3) OR (4)" 
					NEXT FIELD bill_issue_ind 
			END CASE 
		BEFORE FIELD acct_code 
			IF bill_acct_flag != 1 
			OR bill_entry_mask != pr_job.acct_code THEN 
				IF pr_job.locked_ind = "0" THEN 
					LET validation_type = 2 
				ELSE 
					LET validation_type = 1 
				END IF 









				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				bill_entry_mask, 
				pr_job.acct_code, 
				validation_type, 
				"Revenue Account") 
				RETURNING pr_job.acct_code, 
				acct_desc_text, 
				entry_flag 

				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					DISPLAY BY NAME pr_job.acct_code 
					DISPLAY acct_desc_text TO desc_text 
				END IF 
			END IF 

		BEFORE FIELD wip_acct_code 
			IF wip_acct_flag != 1 
			OR wip_entry_mask != pr_job.wip_acct_code THEN 








				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				wip_entry_mask, 
				pr_job.wip_acct_code, 
				validation_type, 
				"WIP Account") 
				RETURNING pr_job.wip_acct_code, 
				acct_desc_text, 
				entry_flag 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				ELSE 
					DISPLAY BY NAME pr_job.wip_acct_code 
					DISPLAY acct_desc_text 
					TO wip_desc_text 

				END IF 
			END IF 

		BEFORE FIELD cos_acct_code 
			IF cos_acct_flag != 1 
			OR cos_entry_mask != pr_job.cos_acct_code THEN 








				CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				cos_entry_mask, 
				pr_job.cos_acct_code, 
				validation_type, 
				"COS Account") 
				RETURNING pr_job.cos_acct_code, 
				acct_desc_text, 
				entry_flag 
				DISPLAY BY NAME pr_job.cos_acct_code 
				DISPLAY acct_desc_text 
				TO cos_desc_text 

			END IF 
		AFTER FIELD acct_code 
			IF pr_validate_ind matches "[Y,y]" THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				pr_job.acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 



					NEXT FIELD acct_code 
				END IF 
				LET pr_job.acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_job.acct_code 
				DISPLAY pr_coa.desc_text TO desc_text 
			END IF 
			NEXT FIELD wip_acct_code 

		AFTER FIELD wip_acct_code 
			IF pr_validate_ind matches "[Y,y]" THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				pr_job.wip_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					# LET int_flag = TRUE
					# LET quit_flag = TRUE
					# EXIT INPUT
					NEXT FIELD wip_acct_code 
				END IF 
				LET pr_job.wip_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_job.wip_acct_code 
				DISPLAY pr_coa.desc_text TO wip_desc_text 
			END IF 
			NEXT FIELD cos_acct_code 

		AFTER FIELD cos_acct_code 
			IF pr_validate_ind matches "[Y,y]" THEN 
				CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
				glob_rec_kandoouser.sign_on_code, 
				"J11", 
				pr_job.cos_acct_code, 
				pr_year_num, pr_period_num) 
				RETURNING pr_coa.* 
				IF pr_coa.acct_code IS NULL THEN 
					# LET int_flag = TRUE
					# LET quit_flag = TRUE
					#EXIT INPUT
					NEXT FIELD cos_acct_code 
				END IF 
				LET pr_job.cos_acct_code = pr_coa.acct_code 
				DISPLAY BY NAME pr_job.cos_acct_code 
				DISPLAY pr_coa.desc_text TO cos_desc_text 
			END IF 
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 







			IF pr_job.locked_ind != "0" THEN 
				IF pr_validate_ind matches "[Y,y]" THEN 
					CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J11", 
					pr_job.acct_code, 
					pr_year_num, pr_period_num) 
					RETURNING pr_coa.* 
					IF pr_coa.acct_code IS NULL THEN 
						#LET int_flag = TRUE
						#LET quit_flag = TRUE
						#EXIT INPUT
						NEXT FIELD acct_code 
					END IF 
					LET pr_job.acct_code = pr_coa.acct_code 
					DISPLAY BY NAME pr_job.acct_code 
					DISPLAY pr_coa.desc_text TO desc_text 

					CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J11", 
					pr_job.wip_acct_code, 
					pr_year_num, pr_period_num) 
					RETURNING pr_coa.* 
					IF pr_coa.acct_code IS NULL THEN 
						# LET int_flag = TRUE
						# LET quit_flag = TRUE
						#EXIT INPUT
						NEXT FIELD wip_acct_code 
					END IF 
					LET pr_job.wip_acct_code = pr_coa.acct_code 
					DISPLAY BY NAME pr_job.wip_acct_code 
					DISPLAY pr_coa.desc_text TO wip_desc_text 

					CALL v_acct_code(glob_rec_kandoouser.cmpy_code, 
					glob_rec_kandoouser.sign_on_code, 
					"J11", 
					pr_job.cos_acct_code, 
					pr_year_num, pr_period_num) 
					RETURNING pr_coa.* 
					IF pr_coa.acct_code IS NULL THEN 
						#LET int_flag = TRUE
						#LET quit_flag = TRUE
						#EXIT INPUT
						NEXT FIELD cos_acct_code 
					END IF 
					LET pr_job.cos_acct_code = pr_coa.acct_code 
					DISPLAY BY NAME pr_job.cos_acct_code 
					DISPLAY pr_coa.desc_text TO cos_desc_text 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 


FUNCTION display_financials() 
	OPEN WINDOW j103 with FORM "J103" -- alch kd-747 
	CALL winDecoration_j("J103") -- alch kd-747 
	DISPLAY BY NAME 
	pr_job.bill_way_ind, 
	pr_job.bill_when_ind, 
	pr_job.bill_issue_ind 

	CASE (pr_job.bill_way_ind) 
		WHEN "C" 
			DISPLAY "Cost Plus", 
			pr_job.markup_per 
			TO bill_way_text, 
			markup_per 

		WHEN "F" 
			DISPLAY "Fixed Cost " 
			TO bill_way_text 

		WHEN "T" 
			DISPLAY "Time & Materials" 
			TO bill_way_text 

		WHEN "R" 
			DISPLAY "Recurring" 
			TO bill_way_text 

	END CASE 
	CASE (pr_job.bill_when_ind) 
		WHEN "1" 
			DISPLAY "Daily" 
			TO bill_when_text 

	END CASE 
	CASE (pr_job.bill_issue_ind) 
		WHEN "1" 
			DISPLAY "Summary " 
			TO bill_issue_text 

		WHEN "2" 
			DISPLAY "Detailed " 
			TO bill_issue_text 


		WHEN "3" 
			DISPLAY "Summary/Descrpt" 
			TO bill_issue_text 

		WHEN "4" 
			DISPLAY "Detail/Descript" 
			TO bill_issue_text 


	END CASE 
	DISPLAY BY NAME 
	pr_job.acct_code, 
	pr_job.wip_acct_code, 
	pr_job.cos_acct_code 

	SELECT coa.* 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_job.acct_code 
	IF status != notfound THEN 
		DISPLAY pr_coa.desc_text TO coa.desc_text 

	END IF 
	SELECT coa.* 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_job.wip_acct_code 
	IF status != notfound THEN 
		DISPLAY pr_coa.desc_text TO wip_desc_text 

	END IF 
	SELECT coa.* 
	INTO pr_coa.* 
	FROM coa 
	WHERE coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND coa.acct_code = pr_job.cos_acct_code 
	IF status != notfound THEN 
		DISPLAY pr_coa.desc_text TO cos_desc_text 

	END IF 
	LET msgresp = kandoomsg("U",2,"") 
	CLOSE WINDOW w1 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j103 
END FUNCTION 


FUNCTION read_description(desc_lines) 
	DEFINE 
	i, 
	desc_lines SMALLINT 

	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	WHENEVER ERROR stop 
	IF desc_lines IS NULL THEN 
		LET desc_lines = 0 
	END IF 

	FOR i = desc_lines+1 TO 100 
		LET pa_job_desc[i]=null 
	END FOR 
	OPEN WINDOW j174 with FORM "J174" -- alch kd-747 
	CALL winDecoration_j("J174") -- alch kd-747 
	MESSAGE " Enter up TO 100 lines of Job Description - ESC TO Continue" 
	attribute(yellow) 
	CALL set_count(desc_lines) 
	INPUT ARRAY pa_job_desc WITHOUT DEFAULTS FROM sr_job_desc.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J11a","input_arr-pr_job_desc-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	LET desc_lines = arr_count() 
	FOR i = desc_lines+1 TO 100 
		LET pa_job_desc[i]=null 
	END FOR 

	CLOSE WINDOW j174 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	RETURN arr_count() 
END FUNCTION 
