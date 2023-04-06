############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

###################################################################
# FUNCTION check_auth_with_idx_or_code(p_idx,p_action)
#
# Used by report manager i.e. URS and direct_print()
# Validate, if authenticated user is allowed to view this report
###################################################################
FUNCTION check_auth_with_idx_or_code(p_idx,p_report_code,p_action) 
	DEFINE p_idx SMALLINT 
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE p_action CHAR(1) 
	DEFINE l_name_text CHAR(30) 
	#DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.*
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.* 
	DEFINE l_temp_password LIKE kandoouser.password_text 
	DEFINE l_temp_sec_ind LIKE kandoouser.security_ind 
	DEFINE l_return SMALLINT 
	DEFINE l_cnt SMALLINT 

	DEFINE l_char CHAR(1) 
	DEFINE l_loop INTEGER 
	DEFINE l_message CHAR(32) 
	DEFINE l_entered CHAR(20) 
	DEFINE l_ret_value INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_report_code IS NOT NULL THEN

		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = p_report_code
		
		IF status = NOTFOUND THEN
			RETURN FALSE
		END IF 
{
	###################################
	# HuHo: I DO NOT LIKE THIS
	###################################	
	ELSE

		SELECT * INTO l_rec_rmsreps.* FROM rmsreps 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND report_code = glob_arr_rec_rms_code[p_idx].report_code 
}	
	END IF

	IF l_rec_rmsreps.entry_code = glob_rec_kandoouser.sign_on_code THEN 
		RETURN true 
	END IF 
	
	SELECT security_ind INTO l_temp_sec_ind FROM kandoouser 

	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	SELECT * INTO glob_rec_kandoouser.* FROM kandoouser 
	WHERE sign_on_code = l_rec_rmsreps.entry_code 

	IF status = notfound THEN 
		RETURN true 
	END IF 

	#LET glob_rec_kandoouser.password_text = glob_rec_kandoouser.password_text clipped #??????

	IF l_temp_sec_ind < glob_rec_kandoouser.security_ind 
	OR l_temp_sec_ind < l_rec_rmsreps.security_ind THEN 
		IF glob_rec_kandoouser.password_text IS NULL 
		OR glob_rec_kandoouser.password_text = " " THEN 
			RETURN false 
		END IF 

	ELSE 

		IF glob_rec_kandoouser.password_text IS NULL 
		OR glob_rec_kandoouser.password_text = " " THEN 
			RETURN true 
		END IF 

	END IF 

	CASE p_action 
		WHEN "D" 
			LET l_name_text = "Deleting Report File" 
		WHEN "V" 
			LET l_name_text = "Viewing Report File " 
		WHEN "P" 
			LET l_name_text = "Printing Report File" 
		WHEN "F" 
			LET l_name_text = "Coping Report File" 
	END CASE 

	OPEN WINDOW u129 with FORM "U129" 
	CALL windecoration_u("U129") 
	-- albo --
	INPUT l_entered FROM password_text 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","URS","input-l_entered-1") -- albo kd-511 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_ret_value = false 
				EXIT INPUT 
			END IF 
			IF l_entered = glob_rec_kandoouser.password_text THEN 
				LET l_ret_value = true 
				EXIT INPUT 
			ELSE 
				LET l_msgresp = kandoomsg("U",9002,"") 
				CONTINUE INPUT 
			END IF 
	END INPUT 
	----------
	{   -- albo
		CALL fgl_winmessage("this needs fixing URS.4gl","this needs fixing URS.4gl","info")

	   DISPLAY BY NAME l_name_text
	--huho OPTIONS INPUT ATTRIBUTE(invisible)

	   OPTIONS prompt line 7

	   FOR l_cnt = 1 TO 3
	      LET l_MESSAGE = "      Enter password......" clipped
	      LET l_entered = ""
	      FOR l_loop = 1 TO 8
	         IF l_loop > 20 THEN
	             EXIT FOR
	         END IF
	         prompt l_MESSAGE clipped FOR CHAR l_char  -- no need TO replace yet -- albo
	         IF l_char IS NULL THEN
	             EXIT FOR
	         END IF
	         LET l_entered[l_loop] = l_char
	         LET l_MESSAGE = l_MESSAGE clipped, "x"
	      END FOR

	      IF int_flag OR quit_flag THEN
	         LET int_flag = FALSE
	         LET quit_flag = FALSE
	         EXIT FOR
	      END IF

	      IF l_entered = glob_rec_kandoouser.password_text THEN
	         CLOSE WINDOW U129

	         RETURN TRUE
	      ELSE
	         LET l_msgresp = kandoomsg("U",9002,"")
	      END IF

	   END FOR
	}

	CLOSE WINDOW u129 

	RETURN l_ret_value 

END FUNCTION 