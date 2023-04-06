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

	Source code beautified by beautify.pl on 2020-01-02 19:48:28	$Id: $
}




# Purpose - This Program allows the user TO enter AND
#           maintain Job Types.
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_jobtype RECORD LIKE jobtype.*, 
	pa_jobtype array[120] OF RECORD 
		delete_flag CHAR(1), 
		type_code LIKE jobtype.type_code, 
		type_text LIKE jobtype.type_text 
	END RECORD, 
	user_mask_code LIKE coa.acct_code, 
	acct_desc_text LIKE coa.desc_text, 
	idx, i, scrn, cnt, del_no, delete_flag, insert_flag, entry_flag SMALLINT 
END GLOBALS 

MAIN 
	OPTIONS DELETE KEY f36 

	#Initial UI Init
	CALL setModuleId("JZ4") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT kandoouser.acct_mask_code 
	INTO user_mask_code 
	FROM kandoouser 
	WHERE kandoouser.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND kandoouser.sign_on_code = glob_rec_kandoouser.sign_on_code 
	IF status = notfound THEN 
		#5007 General Ledger Parameters NOT SET up - Refer GZP
		LET msgresp = kandoomsg("G", 5007, "") 
		SLEEP 3 
		EXIT program 
	END IF 
	OPEN WINDOW j167 with FORM "J167" -- alch kd-747 
	CALL winDecoration_j("J167") -- alch kd-747 
	IF user_mask_code IS NULL 
	OR user_mask_code = " " THEN 
		CALL build_mask(glob_rec_kandoouser.cmpy_code, 
		"??????????????????", 
		" ") 
		RETURNING user_mask_code 
	END IF 
	WHILE select_type() 
		CALL maintain_type() 
	END WHILE 
	CLOSE WINDOW j167 
END MAIN 



FUNCTION select_type() 
	DEFINE 
	query_text CHAR(400), 
	where_text CHAR(100) 
	CLEAR FORM 
	LET del_no = 0 
	#MESSAGE " Enter Selection Criteria - ESC TO Continue"
	LET msgresp = kandoomsg("U", 1001, "") 
	CONSTRUCT BY NAME where_text ON 
	type_code, 
	type_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","JZ4","const-type_code-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 
	LET query_text = 
	"SELECT jobtype.* ", 
	"FROM jobtype ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",where_text clipped, 
	" ORDER BY type_code" 
	PREPARE type_query FROM query_text 
	DECLARE c_type CURSOR FOR type_query 
	LET idx = 0 
	FOREACH c_type INTO pr_jobtype.* 
		LET idx = idx + 1 
		LET pa_jobtype[idx].delete_flag = NULL 
		LET pa_jobtype[idx].type_code = pr_jobtype.type_code 
		LET pa_jobtype[idx].type_text = pr_jobtype.type_text 
		IF idx = 120 THEN 
			#1519 Only First 120 Jobtypes Selected
			LET msgresp = kandoomsg("J", 1519, "") 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	RETURN true 
END FUNCTION 


FUNCTION maintain_type() 
	#MESSAGE " RETURN TO Edit - F1 TO Add - F2 TO Delete"
	LET msgresp = kandoomsg("U", 1003, "") 

	LET insert_flag = idx 
	CALL set_count(idx) 
	INPUT ARRAY pa_jobtype WITHOUT DEFAULTS FROM sr_jobtype.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ4","input_arr-pr_jobtype-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_jobtype.type_code = pa_jobtype[idx].type_code 
			LET pr_jobtype.type_text = pa_jobtype[idx].type_text 
			IF idx > arr_count() 
			AND arr_count() > 0 THEN 
				#9001 There are no more rows in the direction you are going
				LET msgresp = kandoomsg("U", 9001, "") 
			ELSE 
				DISPLAY pa_jobtype[idx].* 
				TO sr_jobtype[scrn].* 

			END IF 

		AFTER ROW 
			LET pa_jobtype[idx].type_code = pr_jobtype.type_code 
			LET pa_jobtype[idx].type_text = pr_jobtype.type_text 
			DISPLAY pa_jobtype[idx].* TO sr_jobtype[scrn].* 


		BEFORE FIELD type_code 
			IF pa_jobtype[idx].type_code IS NULL THEN 
				NEXT FIELD delete_flag 
			END IF 
			CALL change_jobtype() 
			LET pa_jobtype[idx].type_code = pr_jobtype.type_code 
			LET pa_jobtype[idx].type_text = pr_jobtype.type_text 
			DISPLAY pa_jobtype[idx].* 
			TO sr_jobtype[scrn].* 
			NEXT FIELD delete_flag 
		BEFORE FIELD type_text 
			NEXT FIELD type_code 
		ON KEY (F2) 
			IF pa_jobtype[idx].delete_flag IS NOT NULL THEN 
				LET pa_jobtype[idx].delete_flag = NULL 
				LET del_no = del_no - 1 
			ELSE 
				LET cnt = 0 
				SELECT count(*) 
				INTO cnt 
				FROM job 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = pr_jobtype.type_code 
				AND finish_flag <> "Y" 
				IF cnt <> 0 THEN 
					#9552 You may NOT delete this Job Type - Jobs are ...
					LET msgresp = kandoomsg("J", 9552, "") 
					DISPLAY pa_jobtype[idx].* TO sr_jobtype[scrn].* 
				ELSE 
					LET pa_jobtype[idx].delete_flag = "*" 
					LET del_no = del_no + 1 
				END IF 
			END IF 
			DISPLAY pa_jobtype[idx].delete_flag TO sr_jobtype[scrn].delete_flag 


		BEFORE INSERT 
			IF idx < arr_count() 
			OR ( NOT insert_flag ) 
			OR (idx = arr_count() 
			AND pr_jobtype.type_code IS NOT null) THEN 
				CALL add_jobtype() 
				LET pa_jobtype[idx].type_code = pr_jobtype.type_code 
				LET pa_jobtype[idx].type_text = pr_jobtype.type_text 
				DISPLAY pa_jobtype[idx].* TO sr_jobtype[scrn].* 
			END IF 
			LET insert_flag = true 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		# Confirm delete of selection records
	ELSE 
		IF del_no > 0 THEN 
			LET msgresp = kandoomsg("J", 8900, del_no) 
			#prompt "There are VALUE Job Types TO delete. Confirm...."
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_jobtype[idx].delete_flag IS NOT NULL THEN 
						DELETE FROM jobtype 
						WHERE jobtype.type_code = pa_jobtype[idx].type_code 
						AND jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 

	END IF 
END FUNCTION 


FUNCTION add_jobtype() 
	OPEN WINDOW j168 with FORM "J168" -- alch kd-747 
	CALL winDecoration_j("J168") -- alch kd-747 
	LET msgresp = kandoomsg("J", 1639, "") 
	#J1639 Enter Job Type details; OK TO continue.
	LET pr_jobtype.cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET pr_jobtype.prompt1_ind = 5 
	LET pr_jobtype.prompt2_ind = 5 
	LET pr_jobtype.prompt3_ind = 5 
	LET pr_jobtype.prompt4_ind = 5 
	LET pr_jobtype.prompt5_ind = 5 
	LET pr_jobtype.prompt6_ind = 5 
	LET pr_jobtype.prompt7_ind = 5 
	LET pr_jobtype.prompt8_ind = 5 
	LET pr_jobtype.type_code = NULL 
	LET pr_jobtype.type_text = NULL 
	LET pr_jobtype.bill_way_ind = NULL 
	LET pr_jobtype.bill_issue_ind = NULL 
	LET pr_jobtype.bill_acct_code = NULL 
	LET pr_jobtype.wip_acct_code = NULL 
	LET pr_jobtype.cos_acct_code = NULL 
	LET pr_jobtype.prompt1_text = NULL 
	LET pr_jobtype.prompt2_text = NULL 
	LET pr_jobtype.prompt3_text = NULL 
	LET pr_jobtype.prompt4_text = NULL 
	LET pr_jobtype.prompt5_text = NULL 
	LET pr_jobtype.prompt6_text = NULL 
	LET pr_jobtype.prompt7_text = NULL 
	LET pr_jobtype.prompt8_text = NULL 


	INPUT BY NAME pr_jobtype.type_code, 
	pr_jobtype.type_text, 
	pr_jobtype.bill_way_ind, 
	pr_jobtype.bill_when_ind, 
	pr_jobtype.bill_issue_ind, 
	pr_jobtype.bill_acct_code, 
	pr_jobtype.wip_acct_code, 
	pr_jobtype.cos_acct_code, 
	pr_jobtype.prompt1_text, 
	pr_jobtype.prompt1_ind, 
	pr_jobtype.prompt2_text, 
	pr_jobtype.prompt2_ind, 
	pr_jobtype.prompt3_text, 
	pr_jobtype.prompt3_ind, 
	pr_jobtype.prompt4_text, 
	pr_jobtype.prompt4_ind, 
	pr_jobtype.prompt5_text, 
	pr_jobtype.prompt5_ind, 
	pr_jobtype.prompt6_text, 
	pr_jobtype.prompt6_ind, 
	pr_jobtype.prompt7_text, 
	pr_jobtype.prompt7_ind, 
	pr_jobtype.prompt8_text, 
	pr_jobtype.prompt8_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ4","input-pr_jobtype-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD type_code 
			IF pr_jobtype.type_code IS NULL THEN 
				#9546 You must enter a unique type code
				LET msgresp = kandoomsg("J", 9546, "") 
				NEXT FIELD type_code 
			END IF 
			SELECT count(*) 
			INTO cnt 
			FROM jobtype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_jobtype.type_code 
			IF cnt > 0 THEN 
				#9546 You must enter a unique type code
				LET msgresp = kandoomsg("J", 9546, "") 
				NEXT FIELD type_code 
			END IF 

		AFTER FIELD type_text 
			IF pr_jobtype.type_text IS NULL THEN 
				#9538 a Description must be entered
				LET msgresp = kandoomsg("J", 9538, "") 
				NEXT FIELD type_text 
			END IF 

		AFTER FIELD bill_way_ind 
			IF pr_jobtype.bill_way_ind IS NULL THEN 
				#9547 "Must enter a Method Indicator
				LET msgresp = kandoomsg("J", 9547, "") 
				NEXT FIELD bill_way_ind 
			END IF 

		AFTER FIELD bill_issue_ind 
			IF pr_jobtype.bill_issue_ind IS NULL THEN 
				#9548 "Must enter an Issues Indicator
				LET msgresp = kandoomsg("J", 9548, "") 
				NEXT FIELD bill_issue_ind 
			END IF 


		BEFORE FIELD bill_acct_code 





			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			user_mask_code, 
			2, 
			"Bill Account Mask") 
			RETURNING pr_jobtype.bill_acct_code, 
			acct_desc_text, 
			entry_flag 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			CALL display_desc(1) RETURNING cnt 
			NEXT FIELD wip_acct_code 
		BEFORE FIELD wip_acct_code 





			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			user_mask_code, 
			2, 
			"WIP Account Mask") 
			RETURNING pr_jobtype.wip_acct_code, 
			acct_desc_text, 
			entry_flag 
			CALL display_desc(2) RETURNING cnt 
			NEXT FIELD cos_acct_code 
		BEFORE FIELD cos_acct_code 





			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			user_mask_code, 
			2, 
			"COS Account Mask") 
			RETURNING pr_jobtype.cos_acct_code, 
			acct_desc_text, 
			entry_flag 
			IF NOT (int_flag OR quit_flag) THEN 
				CALL display_desc(3) RETURNING cnt 
				SLEEP 2 
			END IF 

			NEXT FIELD prompt1_text 


		AFTER FIELD prompt1_ind 
			IF pr_jobtype.prompt1_text IS NOT NULL AND 
			pr_jobtype.prompt1_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_text IS NULL AND 
			pr_jobtype.prompt1_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt1_ind 
			END IF 

		AFTER FIELD prompt2_ind 
			IF pr_jobtype.prompt2_text IS NOT NULL AND 
			pr_jobtype.prompt2_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_text IS NULL AND 
			pr_jobtype.prompt2_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt2_ind 
			END IF 

		AFTER FIELD prompt3_ind 
			IF pr_jobtype.prompt3_text IS NOT NULL AND 
			pr_jobtype.prompt3_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_text IS NULL AND 
			pr_jobtype.prompt3_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt3_ind 
			END IF 

		AFTER FIELD prompt4_ind 
			IF pr_jobtype.prompt4_text IS NOT NULL AND 
			pr_jobtype.prompt4_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_text IS NULL AND 
			pr_jobtype.prompt4_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt4_ind 
			END IF 

		AFTER FIELD prompt5_ind 
			IF pr_jobtype.prompt5_text IS NOT NULL AND 
			pr_jobtype.prompt5_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_text IS NULL AND 
			pr_jobtype.prompt5_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt5_ind 
			END IF 

		AFTER FIELD prompt6_ind 
			IF pr_jobtype.prompt6_text IS NOT NULL AND 
			pr_jobtype.prompt6_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_text IS NULL AND 
			pr_jobtype.prompt6_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt6_ind 
			END IF 

		AFTER FIELD prompt7_ind 
			IF pr_jobtype.prompt7_text IS NOT NULL AND 
			pr_jobtype.prompt7_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_text IS NULL AND 
			pr_jobtype.prompt7_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt7_ind 
			END IF 

		AFTER FIELD prompt8_ind 
			IF pr_jobtype.prompt8_text IS NOT NULL AND 
			pr_jobtype.prompt8_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_text IS NULL AND 
			pr_jobtype.prompt8_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			EXIT INPUT 
		AFTER INPUT 
			IF pr_jobtype.bill_acct_code IS NULL THEN 
				LET pr_jobtype.bill_acct_code = user_mask_code 
			END IF 
			IF pr_jobtype.wip_acct_code IS NULL THEN 
				LET pr_jobtype.wip_acct_code = user_mask_code 
			END IF 
			IF pr_jobtype.cos_acct_code IS NULL THEN 
				LET pr_jobtype.cos_acct_code = user_mask_code 
			END IF 


			IF pr_jobtype.prompt1_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_text IS NOT NULL AND 
			pr_jobtype.prompt1_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_text IS NULL AND 
			pr_jobtype.prompt1_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt2_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_text IS NOT NULL AND 
			pr_jobtype.prompt2_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_text IS NULL AND 
			pr_jobtype.prompt2_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt3_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_text IS NOT NULL AND 
			pr_jobtype.prompt3_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_text IS NULL AND 
			pr_jobtype.prompt3_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt4_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_text IS NOT NULL AND 
			pr_jobtype.prompt4_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_text IS NULL AND 
			pr_jobtype.prompt4_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt5_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_text IS NOT NULL AND 
			pr_jobtype.prompt5_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_text IS NULL AND 
			pr_jobtype.prompt5_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt6_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_text IS NOT NULL AND 
			pr_jobtype.prompt6_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_text IS NULL AND 
			pr_jobtype.prompt6_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt7_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_text IS NOT NULL AND 
			pr_jobtype.prompt7_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_text IS NULL AND 
			pr_jobtype.prompt7_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt8_text IS NOT NULL AND 
			pr_jobtype.prompt8_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_text IS NULL AND 
			pr_jobtype.prompt8_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_ind IS NULL THEN 
				#9551 Must enter Indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt8_ind 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j168 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		FOR i = idx TO arr_count() 
			IF i = arr_count() THEN 
				LET pa_jobtype[i].type_code = NULL 
				LET pa_jobtype[i].type_text = NULL 
			ELSE 
				LET pa_jobtype[i].type_code = pa_jobtype[i+1].type_code 
				LET pa_jobtype[i].type_text = pa_jobtype[i+1].type_text 
			END IF 
		END FOR 
		LET pr_jobtype.type_code = pa_jobtype[idx].type_code 
		LET pr_jobtype.type_text = pa_jobtype[idx].type_text 
		FOR i = 0 TO 10-scrn 
			DISPLAY pa_jobtype[idx+i].* TO sr_jobtype[scrn+i].* 
		END FOR 
	ELSE 
		INSERT INTO jobtype VALUES ( pr_jobtype.*) 
	END IF 
END FUNCTION 


FUNCTION change_jobtype() 
	OPEN WINDOW j168 with FORM "J168" -- alch kd-747 
	CALL winDecoration_j("J168") -- alch kd-747 
	LET msgresp = kandoomsg("J", 1639, "") 
	#J1639 Enter Job Type details; OK TO continue.
	SELECT * 
	INTO pr_jobtype.* 
	FROM jobtype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = pa_jobtype[idx].type_code 
	IF pr_jobtype.prompt1_text IS NULL THEN 
		LET pr_jobtype.prompt1_ind = 5 
	ELSE 
		IF pr_jobtype.prompt1_ind IS NULL THEN 
			LET pr_jobtype.prompt1_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt2_text IS NULL THEN 
		LET pr_jobtype.prompt2_ind = 5 
	ELSE 
		IF pr_jobtype.prompt2_ind IS NULL THEN 
			LET pr_jobtype.prompt2_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt3_text IS NULL THEN 
		LET pr_jobtype.prompt3_ind = 5 
	ELSE 
		IF pr_jobtype.prompt3_ind IS NULL THEN 
			LET pr_jobtype.prompt3_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt4_text IS NULL THEN 
		LET pr_jobtype.prompt4_ind = 5 
	ELSE 
		IF pr_jobtype.prompt4_ind IS NULL THEN 
			LET pr_jobtype.prompt4_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt5_text IS NULL THEN 
		LET pr_jobtype.prompt5_ind = 5 
	ELSE 
		IF pr_jobtype.prompt5_ind IS NULL THEN 
			LET pr_jobtype.prompt5_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt6_text IS NULL THEN 
		LET pr_jobtype.prompt6_ind = 5 
	ELSE 
		IF pr_jobtype.prompt6_ind IS NULL THEN 
			LET pr_jobtype.prompt6_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt7_text IS NULL THEN 
		LET pr_jobtype.prompt7_ind = 5 
	ELSE 
		IF pr_jobtype.prompt7_ind IS NULL THEN 
			LET pr_jobtype.prompt7_ind = 1 
		END IF 
	END IF 

	IF pr_jobtype.prompt8_text IS NULL THEN 
		LET pr_jobtype.prompt8_ind = 5 
	ELSE 
		IF pr_jobtype.prompt8_ind IS NULL THEN 
			LET pr_jobtype.prompt8_ind = 1 
		END IF 
	END IF 

	DISPLAY BY NAME pr_jobtype.type_code, 
	pr_jobtype.type_text, 
	pr_jobtype.bill_way_ind, 
	pr_jobtype.bill_when_ind, 
	pr_jobtype.bill_issue_ind, 
	pr_jobtype.prompt1_text, 
	pr_jobtype.prompt1_ind, 
	pr_jobtype.prompt2_text, 
	pr_jobtype.prompt2_ind, 
	pr_jobtype.prompt3_text, 
	pr_jobtype.prompt3_ind, 
	pr_jobtype.prompt4_text, 
	pr_jobtype.prompt4_ind, 
	pr_jobtype.prompt5_text, 
	pr_jobtype.prompt5_ind, 
	pr_jobtype.prompt6_text, 
	pr_jobtype.prompt6_ind, 
	pr_jobtype.prompt7_text, 
	pr_jobtype.prompt7_ind, 
	pr_jobtype.prompt8_text, 
	pr_jobtype.prompt8_ind 

	FOR i = 1 TO 3 
		CALL display_desc(i) RETURNING cnt 
	END FOR 
	INPUT BY NAME pr_jobtype.type_text, 
	pr_jobtype.bill_way_ind, 
	pr_jobtype.bill_when_ind, 
	pr_jobtype.bill_issue_ind, 
	pr_jobtype.bill_acct_code, 
	pr_jobtype.wip_acct_code, 
	pr_jobtype.cos_acct_code, 
	pr_jobtype.prompt1_text, 
	pr_jobtype.prompt1_ind, 
	pr_jobtype.prompt2_text, 
	pr_jobtype.prompt2_ind, 
	pr_jobtype.prompt3_text, 
	pr_jobtype.prompt3_ind, 
	pr_jobtype.prompt4_text, 
	pr_jobtype.prompt4_ind, 
	pr_jobtype.prompt5_text, 
	pr_jobtype.prompt5_ind, 
	pr_jobtype.prompt6_text, 
	pr_jobtype.prompt6_ind, 
	pr_jobtype.prompt7_text, 
	pr_jobtype.prompt7_ind, 
	pr_jobtype.prompt8_text, 
	pr_jobtype.prompt8_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZ4","input-pr_jobtype-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD type_text 
			IF pr_jobtype.type_text IS NULL THEN 
				#9538 a Description must be entered
				LET msgresp = kandoomsg("J", 9538, "") 
				NEXT FIELD type_text 
			END IF 

		AFTER FIELD bill_way_ind 
			IF pr_jobtype.bill_way_ind IS NULL THEN 
				#9547 Must enter a Method Indicator
				LET msgresp = kandoomsg("J", 9547, "") 
				NEXT FIELD bill_way_ind 
			END IF 

		AFTER FIELD bill_issue_ind 
			IF pr_jobtype.bill_issue_ind IS NULL THEN 
				#9548 Must enter an Issues Indicator
				LET msgresp = kandoomsg("J", 9548, "") 
				NEXT FIELD bill_issue_ind 
			END IF 

		BEFORE FIELD bill_acct_code 







			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			pr_jobtype.bill_acct_code, 
			2, 
			"Bill Account Mask") 
			RETURNING pr_jobtype.bill_acct_code, 
			acct_desc_text, 
			entry_flag 


			CALL display_desc(1) RETURNING cnt 
			NEXT FIELD wip_acct_code 

		BEFORE FIELD wip_acct_code 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 








			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			pr_jobtype.wip_acct_code, 
			2, 
			"WIP Account Mask") 
			RETURNING pr_jobtype.wip_acct_code, 
			acct_desc_text, 
			entry_flag 


			CALL display_desc(2) RETURNING cnt 
			NEXT FIELD cos_acct_code 


		BEFORE FIELD cos_acct_code 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 








			CALL acct_fill(glob_rec_kandoouser.cmpy_code, 
			glob_rec_kandoouser.sign_on_code, 
			"JZ4", 
			user_mask_code, 
			pr_jobtype.cos_acct_code, 
			2, 
			"COS Account Mask") 
			RETURNING pr_jobtype.cos_acct_code, 
			acct_desc_text, 
			entry_flag 


			IF NOT (int_flag OR quit_flag) THEN 
				CALL display_desc(3) RETURNING cnt 
				SLEEP 2 
			END IF 

			NEXT FIELD prompt1_text 

		BEFORE FIELD prompt1_text 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

		AFTER FIELD prompt1_ind 
			IF pr_jobtype.prompt1_text IS NOT NULL AND 
			pr_jobtype.prompt1_ind = 5 THEN 
				#9459  Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_text IS NULL AND 
			pr_jobtype.prompt1_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF pr_jobtype.prompt1_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt1_ind 
			END IF 

		AFTER FIELD prompt2_ind 
			IF pr_jobtype.prompt2_text IS NOT NULL AND 
			pr_jobtype.prompt2_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_text IS NULL AND 
			pr_jobtype.prompt2_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF pr_jobtype.prompt2_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt2_ind 
			END IF 

		AFTER FIELD prompt3_ind 
			IF pr_jobtype.prompt3_text IS NOT NULL AND 
			pr_jobtype.prompt3_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_text IS NULL AND 
			pr_jobtype.prompt3_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF pr_jobtype.prompt3_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt3_ind 
			END IF 

		AFTER FIELD prompt4_ind 
			IF pr_jobtype.prompt4_text IS NOT NULL AND 
			pr_jobtype.prompt4_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_text IS NULL AND 
			pr_jobtype.prompt4_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF pr_jobtype.prompt4_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt4_ind 
			END IF 

		AFTER FIELD prompt5_ind 
			IF pr_jobtype.prompt5_text IS NOT NULL AND 
			pr_jobtype.prompt5_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_text IS NULL AND 
			pr_jobtype.prompt5_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF pr_jobtype.prompt5_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt5_ind 
			END IF 

		AFTER FIELD prompt6_ind 
			IF pr_jobtype.prompt6_text IS NOT NULL AND 
			pr_jobtype.prompt6_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_text IS NULL AND 
			pr_jobtype.prompt6_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF pr_jobtype.prompt6_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt6_ind 
			END IF 

		AFTER FIELD prompt7_ind 
			IF pr_jobtype.prompt7_text IS NOT NULL AND 
			pr_jobtype.prompt7_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_text IS NULL AND 
			pr_jobtype.prompt7_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF pr_jobtype.prompt7_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt7_ind 
			END IF 

		AFTER FIELD prompt8_ind 
			IF pr_jobtype.prompt8_text IS NOT NULL AND 
			pr_jobtype.prompt8_ind = 5 THEN 
				#9549 Indicator must be either 1 OR 2
				LET msgresp = kandoomsg("J", 9549, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_text IS NULL AND 
			pr_jobtype.prompt8_ind != 5 THEN 
				#9550 Indicator must be 5
				LET msgresp = kandoomsg("J", 9550, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF pr_jobtype.prompt8_ind IS NULL THEN 
				#9551 Must enter indicator
				LET msgresp = kandoomsg("J", 9551, "") 
				NEXT FIELD prompt8_ind 
			END IF 

			EXIT INPUT 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		UPDATE jobtype SET * = pr_jobtype.* 
		WHERE cmpy_code = pr_jobtype.cmpy_code 
		AND type_code = pr_jobtype.type_code 
	END IF 

	CLOSE WINDOW j168 
END FUNCTION 


FUNCTION display_desc(i) 
	DEFINE 
	i SMALLINT, 
	account_code LIKE coa.acct_code, 
	acct_desc LIKE coa.desc_text 

	CASE i 
		WHEN 1 
			LET account_code = pr_jobtype.bill_acct_code 
			DISPLAY BY NAME pr_jobtype.bill_acct_code 
		WHEN 2 
			LET account_code = pr_jobtype.wip_acct_code 
			DISPLAY BY NAME pr_jobtype.wip_acct_code 
		WHEN 3 
			LET account_code = pr_jobtype.cos_acct_code 
			DISPLAY BY NAME pr_jobtype.cos_acct_code 
	END CASE 
	LET acct_desc = " " 
	IF account_code IS NOT NULL AND account_code != " " THEN 
		SELECT desc_text 
		INTO acct_desc 
		FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = account_code 
		IF status = notfound THEN 
			CASE i 
				WHEN 1 
					DISPLAY " " TO rev_desc_text 
				WHEN 2 
					DISPLAY " " TO wip_desc_text 
				WHEN 3 
					DISPLAY " " TO cos_desc_text 
			END CASE 
			RETURN(FALSE) 
		END IF 
	END IF 
	CASE i 
		WHEN 1 
			DISPLAY acct_desc TO rev_desc_text 
		WHEN 2 
			DISPLAY acct_desc TO wip_desc_text 
		WHEN 3 
			DISPLAY acct_desc TO cos_desc_text 
	END CASE 
	RETURN(TRUE) 
END FUNCTION 
