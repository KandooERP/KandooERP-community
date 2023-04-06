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

	Source code beautified by beautify.pl on 2020-01-02 19:48:29	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../jm/J_JM_GLOBALS.4gl" 
GLOBALS 
	#DEFINE glob_rec_menunames   RECORD LIKE menunames.* #not used ?
	#DEFINE glob_rec_menunames1  RECORD LIKE menunames.* #not used ?
	#DEFINE glob_rec_menunames2  RECORD LIKE menunames.* #not used ?
	DEFINE glob_rec_s_jmparms RECORD LIKE jmparms.* 
	DEFINE glob_rec_jmparms RECORD LIKE jmparms.* 
	DEFINE glob_rec_journal RECORD LIKE journal.* 
	DEFINE glob_response_text LIKE kandooword.response_text 
END GLOBALS 


############################################################
# MAIN
#
# Purpose - Job Management parameters provides FOR the
#           Maintenance of JM Parmeters
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("JZP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	OPEN WINDOW j113 with FORM "J113" -- alch kd-747 
	CALL winDecoration_j("J113") -- alch kd-747 

	CALL get_kandoo_user() RETURNING glob_rec_kandoouser.* 

	MENU " Parameters" 
		BEFORE MENU 
			IF get_parm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "Change" 
			END IF 
			CALL publish_toolbar("kandoo","JZP","menu-parameters-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Display" " DISPLAY Parameters" 
			CALL display_menu() 

		COMMAND "Add" " Add Parameters" 
			IF add_parm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF get_parm() THEN 
			END IF 

		COMMAND "Change" " Change Parameters" 
			CALL change_menu() 

		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 

			#		COMMAND KEY (control-w)
			#			CALL kandoohelp("")
	END MENU 

	CLOSE WINDOW j113 
END MAIN 


############################################################
# FUNCTION display_menu()
#
#
############################################################
FUNCTION display_menu() 

	MENU " Display" 
		BEFORE MENU 
			IF glob_rec_jmparms.pa_post_flag = "N" THEN 
				HIDE option "Pay codes" 
			END IF 
			CALL publish_toolbar("kandoo","JZP","menu-display-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Contract prompts" " DISPLAY contract user defined prompts" 
			CALL disp_cntr_prmpts() 
		COMMAND "Pay codes" " DISPLAY pay codes" 
			CALL disp_paycodes(glob_rec_jmparms.env_code, 
			glob_rec_jmparms.pay_code, 
			glob_rec_jmparms.rate_code) 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO menus" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 



############################################################
# FUNCTION change_menu()
#
#
############################################################
FUNCTION change_menu() 

	MENU " Change" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","JZP","menu-change-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Parameters" " Change Parameters" 
			CALL input_jmparms("EDIT") 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL upd_parm() 
			END IF 
			CALL get_parm() 

		COMMAND "Contract prompts" " Change contract user defined prompts" 
			CALL input_cntr_prmpts("EDIT") 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				CALL upd_parm() 
			END IF 
			CALL get_parm() 

		COMMAND KEY (interrupt,"E") "Exit" " RETURN TO menus" 
			EXIT MENU 
			#		COMMAND KEY (control-w)
			#			CALL kandoohelp("")
	END MENU 
END FUNCTION 




############################################################
# FUNCTION disp_cntr_prmpts()
#
#
############################################################
FUNCTION disp_cntr_prmpts() 

	OPEN WINDOW j195 with FORM "J195" -- alch kd-747 
	CALL winDecoration_j("J195") -- alch kd-747 
	DISPLAY BY NAME glob_rec_jmparms.cntrhd_prmpt_text, 
	glob_rec_jmparms.cntrhd_prmpt_ind, 
	glob_rec_jmparms.cntrdt_prmpt1_text, 
	glob_rec_jmparms.cntrdt_prmpt1_ind, 
	glob_rec_jmparms.cntrdt_prmpt2_text, 
	glob_rec_jmparms.cntrdt_prmpt2_ind 
	LET msgresp = kandoomsg("J",7504,"") 

	CLOSE WINDOW j195 

END FUNCTION 


############################################################
# FUNCTION add_parm()
#
#
############################################################
FUNCTION add_parm() 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_cnt SMALLINT 

	INITIALIZE glob_rec_jmparms.* TO NULL 
	LET glob_rec_jmparms.nextjob_num = 0 
	LET glob_rec_jmparms.jm_flag = "N" 
	LET glob_rec_jmparms.pa_post_flag = "N" 
	LET glob_rec_jmparms.env_code = "" 
	LET glob_rec_jmparms.pay_code = "" 
	LET glob_rec_jmparms.rate_code = "" 
	LET glob_rec_jmparms.prompt1_text = "REPORT label 1" 
	LET glob_rec_jmparms.prompt2_text = "REPORT label 2" 
	LET glob_rec_jmparms.prompt3_text = "REPORT label 3" 
	LET glob_rec_jmparms.prompt4_text = "REPORT label 4" 
	LET glob_rec_jmparms.prompt5_text = "REPORT label 5" 
	LET glob_rec_jmparms.prompt6_text = "REPORT label 6" 
	LET glob_rec_jmparms.prompt7_text = "REPORT label 7" 
	LET glob_rec_jmparms.prompt8_text = "REPORT label 8" 
	LET glob_rec_jmparms.prompt1_ind = 1 
	LET glob_rec_jmparms.prompt2_ind = 1 
	LET glob_rec_jmparms.prompt3_ind = 1 
	LET glob_rec_jmparms.prompt4_ind = 1 
	LET glob_rec_jmparms.prompt5_ind = 1 
	LET glob_rec_jmparms.prompt6_ind = 1 
	LET glob_rec_jmparms.prompt7_ind = 1 
	LET glob_rec_jmparms.prompt8_ind = 1 

	CALL input_jmparms("ADD") 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET glob_rec_jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_jmparms.key_code = "1" 
	INSERT INTO jmparms VALUES (glob_rec_jmparms.*) 
	LET glob_rec_jmparms.cntrhd_prmpt_ind = "5" 
	LET glob_rec_jmparms.cntrdt_prmpt1_ind = "5" 
	LET glob_rec_jmparms.cntrdt_prmpt2_ind = "5" 

	CALL input_cntr_prmpts("ADD") 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET glob_rec_jmparms.cntrhd_prmpt_text = NULL 
		LET glob_rec_jmparms.cntrdt_prmpt1_text = NULL 
		LET glob_rec_jmparms.cntrdt_prmpt2_text = NULL 
		LET glob_rec_jmparms.cntrhd_prmpt_ind = "5" 
		LET glob_rec_jmparms.cntrdt_prmpt1_ind = "5" 
		LET glob_rec_jmparms.cntrdt_prmpt2_ind = "5" 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		#Need TO RETURN TRUE so that option "Change" IS displayed
		RETURN true 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "JZP - Update prompts" 
		UPDATE jmparms 
		SET cntrhd_prmpt_text = glob_rec_jmparms.cntrhd_prmpt_text, 
		cntrdt_prmpt1_text = glob_rec_jmparms.cntrdt_prmpt1_text, 
		cntrdt_prmpt2_text = glob_rec_jmparms.cntrdt_prmpt2_text, 
		cntrhd_prmpt_ind = glob_rec_jmparms.cntrhd_prmpt_ind, 
		cntrdt_prmpt1_ind = glob_rec_jmparms.cntrdt_prmpt1_ind, 
		cntrdt_prmpt2_ind = glob_rec_jmparms.cntrdt_prmpt2_ind 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION get_parm()
#
#
############################################################
FUNCTION get_parm() 

	CLEAR FORM 
	SELECT * INTO glob_rec_jmparms.* FROM jmparms 
	WHERE jmparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND jmparms.key_code = "1" 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	IF glob_rec_jmparms.prompt1_text IS NULL THEN 
		LET glob_rec_jmparms.prompt1_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt1_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt1_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt2_text IS NULL THEN 
		LET glob_rec_jmparms.prompt2_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt2_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt2_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt3_text IS NULL THEN 
		LET glob_rec_jmparms.prompt3_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt3_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt3_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt4_text IS NULL THEN 
		LET glob_rec_jmparms.prompt4_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt4_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt4_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt5_text IS NULL THEN 
		LET glob_rec_jmparms.prompt5_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt5_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt5_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt6_text IS NULL THEN 
		LET glob_rec_jmparms.prompt6_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt6_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt6_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt7_text IS NULL THEN 
		LET glob_rec_jmparms.prompt7_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt7_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt7_ind = 1 
		END IF 
	END IF 

	IF glob_rec_jmparms.prompt8_text IS NULL THEN 
		LET glob_rec_jmparms.prompt8_ind = 5 
	ELSE 
		IF glob_rec_jmparms.prompt8_ind IS NULL THEN 
			LET glob_rec_jmparms.prompt8_ind = 1 
		END IF 
	END IF 

	DISPLAY BY NAME glob_rec_jmparms.adj_num, 
	glob_rec_jmparms.ra_num, 
	glob_rec_jmparms.next_issue_num, 
	glob_rec_jmparms.jm_flag, 
	glob_rec_jmparms.last_post_date, 
	glob_rec_jmparms.jm_jour_code, 
	glob_rec_jmparms.cos_jour_code, 
	glob_rec_jmparms.adj_jour_code, 
	glob_rec_jmparms.acct_image_flag, 
	glob_rec_jmparms.cost_alloc_ind, 
	glob_rec_jmparms.pa_post_flag, 
	glob_rec_jmparms.prompt1_text, 
	glob_rec_jmparms.prompt2_text, 
	glob_rec_jmparms.prompt3_text, 
	glob_rec_jmparms.prompt4_text, 
	glob_rec_jmparms.prompt5_text, 
	glob_rec_jmparms.prompt6_text, 
	glob_rec_jmparms.prompt7_text, 
	glob_rec_jmparms.prompt8_text, 
	glob_rec_jmparms.prompt1_ind, 
	glob_rec_jmparms.prompt2_ind, 
	glob_rec_jmparms.prompt3_ind, 
	glob_rec_jmparms.prompt4_ind, 
	glob_rec_jmparms.prompt5_ind, 
	glob_rec_jmparms.prompt6_ind, 
	glob_rec_jmparms.prompt7_ind, 
	glob_rec_jmparms.prompt8_ind 

	SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
	WHERE journal.jour_code = glob_rec_jmparms.jm_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY glob_rec_journal.desc_text TO jm_desc_text 

	SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
	WHERE journal.jour_code = glob_rec_jmparms.cos_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY glob_rec_journal.desc_text TO cos_desc_text 

	SELECT desc_text INTO glob_rec_journal.desc_text FROM journal 
	WHERE journal.jour_code = glob_rec_jmparms.adj_jour_code 
	AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
	DISPLAY glob_rec_journal.desc_text TO adj_desc_text 

	IF glob_rec_jmparms.cost_alloc_ind IS NOT NULL THEN 
		SELECT response_text 
		INTO glob_response_text 
		FROM kandooword 
		WHERE language_code = glob_rec_kandoouser.language_code 
		AND reference_text = "jmparms.cost_alloc_ind" 
		AND reference_code = glob_rec_jmparms.cost_alloc_ind 
		IF status = notfound THEN 
			LET glob_response_text = NULL 
		END IF 
		DISPLAY glob_response_text 
		TO alloc_ind_text 

	END IF 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION upd_parm()
#
#
############################################################
FUNCTION upd_parm() 
	DEFINE l_rec_jmparms RECORD LIKE jmparms.* 
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "JZP - Locking Parameters Record" 
		DECLARE c_jmparms CURSOR FOR 
		SELECT * FROM jmparms 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_jmparms 
		FETCH c_jmparms INTO l_rec_jmparms.* 
		IF l_rec_jmparms.adj_num != glob_rec_s_jmparms.adj_num 
		OR l_rec_jmparms.ra_num != glob_rec_s_jmparms.ra_num 
		OR l_rec_jmparms.next_issue_num != glob_rec_s_jmparms.next_issue_num THEN 
			ROLLBACK WORK 
			LET msgresp = kandoomsg("U",7050,"") 
			#7050 Parameter VALUES have been updated since changes.
			RETURN 
		END IF 
		UPDATE jmparms 
		SET * = glob_rec_jmparms.* 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 



############################################################
# FUNCTION input_cntr_prmpts(l_mode)
#
#
############################################################
FUNCTION input_cntr_prmpts(l_mode) 
	DEFINE l_mode CHAR(4) 

	OPEN WINDOW j195 with FORM "J195" -- alch kd-747 
	CALL winDecoration_j("J195") -- alch kd-747 
	IF l_mode = "EDIT" THEN 
		SELECT * INTO glob_rec_jmparms.* FROM jmparms 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_s_jmparms.* = glob_rec_jmparms.* 
	END IF 
	DISPLAY BY NAME glob_rec_jmparms.cntrhd_prmpt_text, 
	glob_rec_jmparms.cntrhd_prmpt_ind, 
	glob_rec_jmparms.cntrdt_prmpt1_text, 
	glob_rec_jmparms.cntrdt_prmpt1_ind, 
	glob_rec_jmparms.cntrdt_prmpt2_text, 
	glob_rec_jmparms.cntrdt_prmpt2_ind 
	LET msgresp = kandoomsg ("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME glob_rec_jmparms.cntrhd_prmpt_text, 
	glob_rec_jmparms.cntrhd_prmpt_ind, 
	glob_rec_jmparms.cntrdt_prmpt1_text, 
	glob_rec_jmparms.cntrdt_prmpt1_ind, 
	glob_rec_jmparms.cntrdt_prmpt2_text, 
	glob_rec_jmparms.cntrdt_prmpt2_ind WITHOUT DEFAULTS 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZP","input-glob_rec_jmparms-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD cntrhd_prmpt_ind 
			IF glob_rec_jmparms.cntrhd_prmpt_text IS NOT NULL AND 
			glob_rec_jmparms.cntrhd_prmpt_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

			IF glob_rec_jmparms.cntrhd_prmpt_text IS NULL AND 
			glob_rec_jmparms.cntrhd_prmpt_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

			IF glob_rec_jmparms.cntrhd_prmpt_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

		AFTER FIELD cntrdt_prmpt1_ind 
			IF glob_rec_jmparms.cntrdt_prmpt1_text IS NOT NULL AND 
			glob_rec_jmparms.cntrdt_prmpt1_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt1_text IS NULL AND 
			glob_rec_jmparms.cntrdt_prmpt1_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt1_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

		AFTER FIELD cntrdt_prmpt2_ind 
			IF glob_rec_jmparms.cntrdt_prmpt2_text IS NOT NULL AND 
			glob_rec_jmparms.cntrdt_prmpt2_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt2_text IS NULL AND 
			glob_rec_jmparms.cntrdt_prmpt2_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt2_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

		AFTER INPUT 

			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF glob_rec_jmparms.cntrhd_prmpt_text IS NOT NULL AND 
			glob_rec_jmparms.cntrhd_prmpt_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

			IF glob_rec_jmparms.cntrhd_prmpt_text IS NULL AND 
			glob_rec_jmparms.cntrhd_prmpt_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

			IF glob_rec_jmparms.cntrhd_prmpt_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrhd_prmpt_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt1_text IS NOT NULL AND 
			glob_rec_jmparms.cntrdt_prmpt1_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt1_text IS NULL AND 
			glob_rec_jmparms.cntrdt_prmpt1_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt1_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrdt_prmpt1_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt2_text IS NOT NULL AND 
			glob_rec_jmparms.cntrdt_prmpt2_ind NOT matches "[1234]" THEN 
				LET msgresp = kandoomsg("J",9554,"") 
				# ERROR "Indicator must be 1-4"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt2_text IS NULL AND 
			glob_rec_jmparms.cntrdt_prmpt2_ind != "5" THEN 
				LET msgresp = kandoomsg("J",1411,"") 
				# ERROR "Indicator must be 5"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

			IF glob_rec_jmparms.cntrdt_prmpt2_ind IS NULL THEN 
				LET msgresp = kandoomsg("J",1412,"") 
				# ERROR "Must enter indicator"
				NEXT FIELD cntrdt_prmpt2_ind 
			END IF 

			#       ON KEY (control-w)
			#          CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW j195 

END FUNCTION 



############################################################
# FUNCTION input_jmparms(p_mode)
#
#
############################################################
FUNCTION input_jmparms(p_mode) 
	DEFINE p_mode CHAR(4) 

	DEFINE l_temp_text CHAR(30) 
	DEFINE l_temp_num INTEGER 

	IF p_mode = "EDIT" THEN 
		SELECT * INTO glob_rec_jmparms.* FROM jmparms 
		WHERE key_code = "1" 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_s_jmparms.* = glob_rec_jmparms.* 
	END IF 

	LET msgresp = kandoomsg ("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME glob_rec_jmparms.adj_num, 
	glob_rec_jmparms.ra_num, 
	glob_rec_jmparms.next_issue_num, 
	glob_rec_jmparms.jm_flag, 
	glob_rec_jmparms.last_post_date, 
	glob_rec_jmparms.jm_jour_code, 
	glob_rec_jmparms.cos_jour_code, 
	glob_rec_jmparms.adj_jour_code, 
	glob_rec_jmparms.acct_image_flag, 
	glob_rec_jmparms.cost_alloc_ind, 
	glob_rec_jmparms.pa_post_flag, 
	glob_rec_jmparms.prompt1_text, 
	glob_rec_jmparms.prompt1_ind, 
	glob_rec_jmparms.prompt2_text, 
	glob_rec_jmparms.prompt2_ind, 
	glob_rec_jmparms.prompt3_text, 
	glob_rec_jmparms.prompt3_ind, 
	glob_rec_jmparms.prompt4_text, 
	glob_rec_jmparms.prompt4_ind, 
	glob_rec_jmparms.prompt5_text, 
	glob_rec_jmparms.prompt5_ind, 
	glob_rec_jmparms.prompt6_text, 
	glob_rec_jmparms.prompt6_ind, 
	glob_rec_jmparms.prompt7_text, 
	glob_rec_jmparms.prompt7_ind, 
	glob_rec_jmparms.prompt8_text, 
	glob_rec_jmparms.prompt8_ind WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JZP","input-glob_rec_jmparms-2") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 


		ON KEY (control-b) infield (jm_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_jmparms.jm_jour_code = l_temp_text 
				DISPLAY BY NAME glob_rec_jmparms.jm_jour_code 

			END IF 
			NEXT FIELD jm_jour_code 

		ON KEY (control-b) infield (cos_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_jmparms.cos_jour_code = l_temp_text 
				DISPLAY BY NAME glob_rec_jmparms.cos_jour_code 

			END IF 
			NEXT FIELD cos_jour_code 

		ON KEY (control-b) infield (adj_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_jmparms.adj_jour_code = l_temp_text 
				DISPLAY BY NAME glob_rec_jmparms.adj_jour_code 

			END IF 
			NEXT FIELD adj_jour_code 

		ON KEY (control-b) infield(cost_alloc_ind) 
			LET l_temp_text = show_kandooword("jmparms.cost_alloc_ind") 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_jmparms.cost_alloc_ind = l_temp_text 
			END IF 
			DISPLAY glob_rec_jmparms.cost_alloc_ind 
			TO cost_alloc_ind 

			NEXT FIELD cost_alloc_ind 


		BEFORE FIELD adj_num 
			LET l_temp_num = glob_rec_jmparms.adj_num 

		AFTER FIELD adj_num 
			IF glob_rec_jmparms.adj_num < l_temp_num 
			OR glob_rec_jmparms.adj_num IS NULL THEN 
				#ERROR "New Adjustment Number must NOT be less than ",l_temp_num
				LET msgresp = kandoomsg("J",1404,l_temp_num) 
				LET glob_rec_jmparms.adj_num = l_temp_num 
				NEXT FIELD adj_num 
			END IF 

		BEFORE FIELD ra_num 
			LET l_temp_num = glob_rec_jmparms.ra_num 

		AFTER FIELD ra_num 
			IF glob_rec_jmparms.ra_num < l_temp_num 
			OR glob_rec_jmparms.ra_num IS NULL THEN 
				#ERROR "New Resource Allocation Number must NOT be less than ",
				LET msgresp = kandoomsg("J",1405,l_temp_num) 
				LET glob_rec_jmparms.ra_num = l_temp_num 
				NEXT FIELD ra_num 
			END IF 

		BEFORE FIELD next_issue_num 
			LET l_temp_num = glob_rec_jmparms.next_issue_num 

		AFTER FIELD next_issue_num 
			IF l_temp_num != glob_rec_jmparms.next_issue_num 
			OR glob_rec_jmparms.next_issue_num IS NULL THEN 
				SELECT max(source_num) 
				INTO l_temp_num 
				FROM prodledg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND trantype_ind = "J" 
				LET l_temp_num = l_temp_num + 1 
			END IF 
			IF glob_rec_jmparms.next_issue_num < l_temp_num 
			OR glob_rec_jmparms.next_issue_num IS NULL THEN 
				#ERROR "New Product Issue Number must NOT be less than ",l_temp_num
				LET msgresp = kandoomsg("J",1406,l_temp_num) 
				LET glob_rec_jmparms.next_issue_num = l_temp_num 
				NEXT FIELD next_issue_num 
			END IF 

		AFTER FIELD jm_flag 
			IF glob_rec_jmparms.jm_flag IS NULL 
			OR (glob_rec_jmparms.jm_flag != "Y" 
			AND glob_rec_jmparms.jm_flag != "N") THEN 
				LET msgresp = kandoomsg("U",1026,"") 
				#1026 Valid VALUES are (Y)es OR (N)o.
				NEXT FIELD jm_flag 
			END IF 

		AFTER FIELD jm_jour_code 
			SELECT journal.* INTO glob_rec_journal.* 
			FROM journal 
			WHERE journal.jour_code = glob_rec_jmparms.jm_jour_code 
			AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				#ERROR "Specified Journal NOT found, try again"
				LET msgresp = kandoomsg("J",1407,"") 
				NEXT FIELD jm_jour_code 
			END IF 
			DISPLAY glob_rec_journal.desc_text TO jm_desc_text 

		AFTER FIELD cos_jour_code 
			SELECT journal.* INTO glob_rec_journal.* 
			FROM journal 
			WHERE journal.jour_code = glob_rec_jmparms.cos_jour_code 
			AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				#ERROR "Specified Journal NOT found, try again"
				LET msgresp = kandoomsg("J",1407,"") 
				NEXT FIELD cos_jour_code 
			END IF 
			DISPLAY glob_rec_journal.desc_text TO cos_desc_text 

		AFTER FIELD adj_jour_code 
			SELECT journal.* INTO glob_rec_journal.* 
			FROM journal 
			WHERE journal.jour_code = glob_rec_jmparms.adj_jour_code 
			AND journal.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				#ERROR "Specified Journal NOT found - try again"
				LET msgresp = kandoomsg("J",1407,"") 
				NEXT FIELD adj_jour_code 
			END IF 
			DISPLAY glob_rec_journal.desc_text TO adj_desc_text 

		AFTER FIELD acct_image_flag 
			IF glob_rec_jmparms.acct_image_flag IS NULL 
			OR (glob_rec_jmparms.acct_image_flag != "Y" 
			AND glob_rec_jmparms.acct_image_flag != "N") THEN 
				#error" Override account flag must be 'Y' OR 'N'"
				LET msgresp = kandoomsg("J",1409,"") 
				NEXT FIELD acct_image_flag 
			END IF 

		AFTER FIELD pa_post_flag 
			IF glob_rec_jmparms.pa_post_flag IS NULL 
			OR (glob_rec_jmparms.pa_post_flag != "Y" 
			AND glob_rec_jmparms.pa_post_flag != "N") THEN 
				#error" Timesheet Payroll Posting Flag Invalid"
				LET msgresp = kandoomsg("J",1408,"") 
				NEXT FIELD pa_post_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("up") THEN 
				NEXT FIELD cost_alloc_ind 
			END IF 
			IF glob_rec_jmparms.pa_post_flag = "Y" THEN 
				CALL get_jmpaycodes(glob_rec_jmparms.env_code, 
				glob_rec_jmparms.pay_code, 
				glob_rec_jmparms.rate_code) 
				RETURNING glob_rec_jmparms.env_code, 
				glob_rec_jmparms.pay_code, 
				glob_rec_jmparms.rate_code 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD pa_post_flag 
				END IF 
			ELSE 
				INITIALIZE glob_rec_jmparms.env_code TO NULL 
				INITIALIZE glob_rec_jmparms.pay_code TO NULL 
				INITIALIZE glob_rec_jmparms.rate_code TO NULL 
			END IF 
			NEXT FIELD prompt1_text 


		AFTER FIELD cost_alloc_ind 
			IF glob_rec_jmparms.cost_alloc_ind IS NOT NULL THEN 
				SELECT response_text 
				INTO glob_response_text 
				FROM kandooword 
				WHERE language_code = glob_rec_kandoouser.language_code 
				AND reference_text = "jmparms.cost_alloc_ind" 
				AND reference_code = glob_rec_jmparms.cost_alloc_ind 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("J",9648,0) 
					NEXT FIELD cost_alloc_ind 
				ELSE 
					DISPLAY glob_response_text 
					TO alloc_ind_text 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("J",9461,0) 
				NEXT FIELD cost_alloc_ind 
			END IF 

		AFTER FIELD prompt1_ind 
			IF glob_rec_jmparms.prompt1_text IS NOT NULL AND 
			glob_rec_jmparms.prompt1_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF glob_rec_jmparms.prompt1_text IS NULL AND 
			glob_rec_jmparms.prompt1_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF glob_rec_jmparms.prompt1_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt1_ind 
			END IF 

		AFTER FIELD prompt2_ind 
			IF glob_rec_jmparms.prompt2_text IS NOT NULL AND 
			glob_rec_jmparms.prompt2_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF glob_rec_jmparms.prompt2_text IS NULL AND 
			glob_rec_jmparms.prompt2_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF glob_rec_jmparms.prompt2_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt2_ind 
			END IF 

		AFTER FIELD prompt3_ind 
			IF glob_rec_jmparms.prompt3_text IS NOT NULL AND 
			glob_rec_jmparms.prompt3_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF glob_rec_jmparms.prompt3_text IS NULL AND 
			glob_rec_jmparms.prompt3_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF glob_rec_jmparms.prompt3_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt3_ind 
			END IF 

		AFTER FIELD prompt4_ind 
			IF glob_rec_jmparms.prompt4_text IS NOT NULL AND 
			glob_rec_jmparms.prompt4_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF glob_rec_jmparms.prompt4_text IS NULL AND 
			glob_rec_jmparms.prompt4_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF glob_rec_jmparms.prompt4_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt4_ind 
			END IF 

		AFTER FIELD prompt5_ind 
			IF glob_rec_jmparms.prompt5_text IS NOT NULL AND 
			glob_rec_jmparms.prompt5_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF glob_rec_jmparms.prompt5_text IS NULL AND 
			glob_rec_jmparms.prompt5_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF glob_rec_jmparms.prompt5_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt5_ind 
			END IF 

		AFTER FIELD prompt6_ind 
			IF glob_rec_jmparms.prompt6_text IS NOT NULL AND 
			glob_rec_jmparms.prompt6_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF glob_rec_jmparms.prompt6_text IS NULL AND 
			glob_rec_jmparms.prompt6_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF glob_rec_jmparms.prompt6_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt6_ind 
			END IF 

		AFTER FIELD prompt7_ind 
			IF glob_rec_jmparms.prompt7_text IS NOT NULL AND 
			glob_rec_jmparms.prompt7_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF glob_rec_jmparms.prompt7_text IS NULL AND 
			glob_rec_jmparms.prompt7_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF glob_rec_jmparms.prompt7_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt7_ind 
			END IF 

		AFTER FIELD prompt8_ind 
			IF glob_rec_jmparms.prompt8_text IS NOT NULL AND 
			glob_rec_jmparms.prompt8_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF glob_rec_jmparms.prompt8_text IS NULL AND 
			glob_rec_jmparms.prompt8_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF glob_rec_jmparms.prompt8_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt8_ind 
			END IF 

		AFTER INPUT 
			IF glob_rec_jmparms.jm_flag IS NULL 
			OR (glob_rec_jmparms.jm_flag != "Y" 
			AND glob_rec_jmparms.jm_flag != "N") THEN 
				LET msgresp = kandoomsg("U",1026,"") 
				#1026 Valid VALUES are (Y)es OR (N)o.
				NEXT FIELD jm_flag 
			END IF 
			IF glob_rec_jmparms.prompt1_text IS NOT NULL AND 
			glob_rec_jmparms.prompt1_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF glob_rec_jmparms.prompt1_text IS NULL AND 
			glob_rec_jmparms.prompt1_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF glob_rec_jmparms.prompt1_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt1_ind 
			END IF 

			IF glob_rec_jmparms.prompt2_text IS NOT NULL AND 
			glob_rec_jmparms.prompt2_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF glob_rec_jmparms.prompt2_text IS NULL AND 
			glob_rec_jmparms.prompt2_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF glob_rec_jmparms.prompt2_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt2_ind 
			END IF 

			IF glob_rec_jmparms.prompt3_text IS NOT NULL AND 
			glob_rec_jmparms.prompt3_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF glob_rec_jmparms.prompt3_text IS NULL AND 
			glob_rec_jmparms.prompt3_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF glob_rec_jmparms.prompt3_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt3_ind 
			END IF 

			IF glob_rec_jmparms.prompt4_text IS NOT NULL AND 
			glob_rec_jmparms.prompt4_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF glob_rec_jmparms.prompt4_text IS NULL AND 
			glob_rec_jmparms.prompt4_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF glob_rec_jmparms.prompt4_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt4_ind 
			END IF 

			IF glob_rec_jmparms.prompt5_text IS NOT NULL AND 
			glob_rec_jmparms.prompt5_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF glob_rec_jmparms.prompt5_text IS NULL AND 
			glob_rec_jmparms.prompt5_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF glob_rec_jmparms.prompt5_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt5_ind 
			END IF 

			IF glob_rec_jmparms.prompt6_text IS NOT NULL AND 
			glob_rec_jmparms.prompt6_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF glob_rec_jmparms.prompt6_text IS NULL AND 
			glob_rec_jmparms.prompt6_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF glob_rec_jmparms.prompt6_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt6_ind 
			END IF 

			IF glob_rec_jmparms.prompt7_text IS NOT NULL AND 
			glob_rec_jmparms.prompt7_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF glob_rec_jmparms.prompt7_text IS NULL AND 
			glob_rec_jmparms.prompt7_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF glob_rec_jmparms.prompt7_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt7_ind 
			END IF 

			IF glob_rec_jmparms.prompt8_text IS NOT NULL AND 
			glob_rec_jmparms.prompt8_ind = 5 THEN 
				#ERROR "Indicator must be either 1 OR 2 "
				LET msgresp = kandoomsg("J",1410,"") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF glob_rec_jmparms.prompt8_text IS NULL AND 
			glob_rec_jmparms.prompt8_ind != 5 THEN 
				#ERROR "Indicator must be 5 "
				LET msgresp = kandoomsg("J",1411,"") 
				NEXT FIELD prompt8_ind 
			END IF 

			IF glob_rec_jmparms.prompt8_ind IS NULL THEN 
				#ERROR "Must enter indicator"
				LET msgresp = kandoomsg("J",1412,"") 
				NEXT FIELD prompt8_ind 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 
END FUNCTION 
