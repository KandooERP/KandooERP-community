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

	Source code beautified by beautify.pl on 2019-12-31 14:28:34	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module KZP Subscription Parameters
#             allows the user TO enter AND maintain SS Setup Parameters
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_ssparms RECORD LIKE ssparms.* 
	DEFINE glob_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 
	#Initial UI Init
	CALL setModuleId("KZP") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	OPEN WINDOW k126 WITH FORM "K126" 

	MENU " parameters" 
		BEFORE MENU 
			IF disp_parm() THEN 
				HIDE option "Add" 
			ELSE 
			HIDE option "Change" 
		END IF 

		COMMAND "Add " " Add parameters" 
			CALL add_parm() 
			IF disp_parm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 

		COMMAND "Change" " Change parameters" 
			CALL change_parm() 
			LET l_msgresp = disp_parm() 

		COMMAND KEY(interrupt,"E") "Exit" " Exit TO menus" 
			EXIT MENU 
			#      COMMAND KEY (control-w)
			#         CALL kandoohelp("")
	END MENU 

	CLOSE WINDOW k126 
END MAIN 



############################################################
# FUNCTION disp_parm()
#
#
############################################################
FUNCTION disp_parm() 

	CLEAR FORM 
	SELECT ssparms.* INTO glob_rec_ssparms.* 
	FROM ssparms 
	WHERE ssparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		RETURN false 
	END IF 
	SELECT reason_text INTO glob_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_ssparms.pp_hold_code 
	IF status != notfound THEN 
		DISPLAY glob_rec_holdreas.reason_text 
		TO hold_text 

	END IF 
	SELECT desc_text INTO glob_rec_coa.desc_text FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_ssparms.sub_acct_code 
	IF status != notfound THEN 
		DISPLAY glob_rec_coa.desc_text TO acct_text 

	END IF 
	DISPLAY BY NAME glob_rec_ssparms.sub_acct_code, 
	glob_rec_ssparms.pp_hold_code, 
	glob_rec_ssparms.format1_text, 
	glob_rec_ssparms.format2_text, 
	glob_rec_ssparms.format1_desc, 
	glob_rec_ssparms.f1_line1_text, 
	glob_rec_ssparms.f1_line2_text, 
	glob_rec_ssparms.format2_text, 
	glob_rec_ssparms.format2_desc, 
	glob_rec_ssparms.f2_line1_text, 
	glob_rec_ssparms.f2_line2_text, 
	glob_rec_ssparms.format3_text, 
	glob_rec_ssparms.format3_desc, 
	glob_rec_ssparms.f3_line1_text, 
	glob_rec_ssparms.f3_line2_text 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION add_parm()
#
#
############################################################
FUNCTION add_parm() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_runner CHAR(100) 
	DEFINE l_retcode INTEGER 

	INITIALIZE glob_rec_ssparms.* TO NULL 
	LET glob_rec_ssparms.next_sub_num = 1 

	LET l_msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME glob_rec_ssparms.sub_acct_code, 
	glob_rec_ssparms.pp_hold_code, 
	glob_rec_ssparms.format1_desc, 
	glob_rec_ssparms.format1_text, 
	glob_rec_ssparms.f1_line1_text, 
	glob_rec_ssparms.f1_line2_text, 
	glob_rec_ssparms.format2_desc, 
	glob_rec_ssparms.format2_text, 
	glob_rec_ssparms.f2_line1_text, 
	glob_rec_ssparms.f2_line2_text, 
	glob_rec_ssparms.format3_desc, 
	glob_rec_ssparms.format3_text, 
	glob_rec_ssparms.f3_line1_text, 
	glob_rec_ssparms.f3_line2_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (sub_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_ssparms.sub_acct_code = glob_temp_text 
				NEXT FIELD sub_acct_code 
			END IF 

		ON KEY (control-b) infield (pp_hold_code) 
			LET glob_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_ssparms.pp_hold_code = glob_temp_text 
				NEXT FIELD pp_hold_code 
			END IF 

		AFTER FIELD sub_acct_code 
			IF glob_rec_ssparms.sub_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Account Code Must Be Entered
				NEXT FIELD sub_acct_code 
			ELSE 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_ssparms.sub_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD sub_acct_code 
			ELSE 
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_ssparms.sub_acct_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 Account Code NOT found - Try Window
				NEXT FIELD sub_acct_code 
			ELSE 
			DISPLAY glob_rec_coa.desc_text TO acct_text 

		END IF 
	END IF 
END IF 

		AFTER FIELD pp_hold_code 
			CLEAR hold_text 
			IF glob_rec_ssparms.pp_hold_code IS NOT NULL THEN 
				SELECT reason_text INTO glob_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_ssparms.pp_hold_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					# 9105 Hold code NOT found - Try Window
					NEXT FIELD pp_hold_code 
				ELSE 
				DISPLAY glob_rec_holdreas.reason_text 
				TO hold_text 

			END IF 
		ELSE 
		LET l_msgresp = kandoomsg("U",9102,"") 
		# 9102 Hold code NOT found
		NEXT FIELD pp_hold_code 
	END IF 

		AFTER FIELD format1_text 
			IF glob_rec_ssparms.format1_text IS NOT NULL THEN 
				LET l_runner = "[ -d ",glob_rec_ssparms.format1_text clipped," ]" 
				RUN l_runner RETURNING l_retcode 
				IF l_retcode THEN 
					LET l_msgresp = kandoomsg("U",9107,"") 
					#9107 Unix directory path does NOT exist
					NEXT FIELD format1_text 
				END IF 
			END IF 

		AFTER FIELD format2_text 
			IF glob_rec_ssparms.format2_text IS NOT NULL THEN 
				LET l_runner = "[ -d ",glob_rec_ssparms.format2_text clipped," ]" 
				RUN l_runner RETURNING l_retcode 
				IF l_retcode THEN 
					LET l_msgresp = kandoomsg("U",9107,"") 
					#9107 Unix directory path does NOT exist
					NEXT FIELD format2_text 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET quit_flag = false 
				LET int_flag = false 
			ELSE 
			IF glob_rec_ssparms.sub_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Account Code Must Be Entered
				NEXT FIELD sub_acct_code 
			END IF 
			SELECT * FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = glob_rec_ssparms.pp_hold_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				# 9102 Hold code must be entered
				NEXT FIELD pp_hold_code 
			END IF 
			LET glob_rec_ssparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			INSERT INTO ssparms VALUES (glob_rec_ssparms.*) 
		END IF 
		#      ON KEY (control-w)
		#         CALL kandoohelp("")
	END INPUT 
END FUNCTION 


############################################################
# FUNCTION change_parm()
#
#
############################################################
FUNCTION change_parm() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_runner CHAR(100) 
	DEFINE l_retcode INTEGER 

	SELECT reason_text INTO glob_rec_holdreas.reason_text 
	FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_ssparms.pp_hold_code 
	IF status != notfound THEN 
		DISPLAY glob_rec_holdreas.reason_text 
		TO hold_text 

	END IF 
	SELECT desc_text INTO glob_rec_coa.desc_text FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = glob_rec_ssparms.sub_acct_code 
	IF status != notfound THEN 
		DISPLAY glob_rec_coa.desc_text TO acct_text 

	END IF 
	LET l_msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INPUT BY NAME glob_rec_ssparms.sub_acct_code, 
	glob_rec_ssparms.pp_hold_code, 
	glob_rec_ssparms.format1_desc, 
	glob_rec_ssparms.format1_text, 
	glob_rec_ssparms.f1_line1_text, 
	glob_rec_ssparms.f1_line2_text, 
	glob_rec_ssparms.format2_desc, 
	glob_rec_ssparms.format2_text, 
	glob_rec_ssparms.f2_line1_text, 
	glob_rec_ssparms.f2_line2_text, 
	glob_rec_ssparms.format3_desc, 
	glob_rec_ssparms.format3_text, 
	glob_rec_ssparms.f3_line1_text, 
	glob_rec_ssparms.f3_line2_text WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (sub_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_ssparms.sub_acct_code = glob_temp_text 
				NEXT FIELD sub_acct_code 
			END IF 

		ON KEY (control-b) infield (pp_hold_code) 
			LET glob_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_ssparms.pp_hold_code = glob_temp_text 
				NEXT FIELD pp_hold_code 
			END IF 

		AFTER FIELD sub_acct_code 
			IF glob_rec_ssparms.sub_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Account Code Must Be Entered
				NEXT FIELD sub_acct_code 
			ELSE 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_ssparms.sub_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
				NEXT FIELD sub_acct_code 
			ELSE 
			SELECT * INTO glob_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = glob_rec_ssparms.sub_acct_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 Account Code NOT found - Try Window
				NEXT FIELD sub_acct_code 
			ELSE 
			DISPLAY glob_rec_coa.desc_text TO acct_text 

		END IF 
	END IF 
END IF 

		AFTER FIELD pp_hold_code 
			CLEAR hold_text 
			IF glob_rec_ssparms.pp_hold_code IS NOT NULL THEN 
				SELECT reason_text INTO glob_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_ssparms.pp_hold_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					# 9105 Hold code NOT found - Try Window
					NEXT FIELD pp_hold_code 
				ELSE 
				DISPLAY glob_rec_holdreas.reason_text 
				TO hold_text 

			END IF 
		ELSE 
		LET l_msgresp = kandoomsg("U",9102,"") 
		# 9102 Hold code NOT found
		NEXT FIELD pp_hold_code 
	END IF 


		AFTER FIELD format1_text 
			IF glob_rec_ssparms.format1_text IS NOT NULL THEN 
				LET l_runner = "[ -d ",glob_rec_ssparms.format1_text clipped," ]" 
				RUN l_runner RETURNING l_retcode 
				IF l_retcode THEN 
					LET l_msgresp = kandoomsg("U",9107,"") 
					#9107 Unix directory path does NOT exist
					NEXT FIELD format1_text 
				END IF 
			END IF 

		AFTER FIELD format2_text 
			IF glob_rec_ssparms.format2_text IS NOT NULL THEN 
				LET l_runner = "[ -d ",glob_rec_ssparms.format2_text clipped," ]" 
				RUN l_runner RETURNING l_retcode 
				IF l_retcode THEN 
					LET l_msgresp = kandoomsg("U",9107,"") 
					#9107 Unix directory path does NOT exist
					NEXT FIELD format2_text 
				END IF 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_ssparms.sub_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Account Code Must Be Entered
					NEXT FIELD sub_acct_code 
				END IF 
				SELECT * FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_ssparms.pp_hold_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					# 9102 Hold code must be entered
					NEXT FIELD pp_hold_code 
				END IF 
			END IF 
			#ON KEY (control-w)
			#   CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "KZP - Locking Parameters record" 
		DECLARE c_ssparms CURSOR FOR 
		SELECT * FROM ssparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_ssparms 
		FETCH c_ssparms 
		UPDATE ssparms 
		SET * = glob_rec_ssparms.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 

	WHENEVER ERROR stop 

END FUNCTION 
