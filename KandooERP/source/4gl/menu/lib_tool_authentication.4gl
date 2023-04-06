##################################################################################
# GLOBAL Scope Variables
##################################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

##############################################################
# FUNCTION lib_tool_authentication_whenever_sqlerror ()
#
#
##############################################################
FUNCTION lib_tool_authentication_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
##############################################################
# END FUNCTION lib_tool_authentication_whenever_sqlerror ()
##############################################################


##############################################################
# FUNCTION main_authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password)
#
#
##############################################################
FUNCTION main_authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password) 
	DEFINE p_universal_login_name NVARCHAR(100) 
	DEFINE p_u_password LIKE kandoouser.password_text 
	DEFINE l_ret_authentication_status SMALLINT 
	DEFINE l_msg STRING 

	IF get_debug() = true THEN 
		DISPLAY "########### main_authenticated_kandoouser_and_set_globals() START ################" 
		DISPLAY "p_universal_login_name=", p_universal_login_name 
		DISPLAY "p_u_password=", p_u_password 
		DISPLAY "-----------------------------------------------------------" 
	END IF 

	#Function requires user name (sign_on_code, use_code OR email) otherwise, terminate
	IF (p_universal_login_name IS NULL) OR (p_u_password IS NULL ) THEN 
		CALL fgl_winmessage("Invalid Authentication","Authentication IS NOT possible without user name OR password") 
		RETURN -3 
	END IF 

	LET l_ret_authentication_status = authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password) 

	IF get_debug() = true THEN 
		DISPLAY "########### main_authenticated_kandoouser_and_set_globals() START ################" 
		DISPLAY "l_ret_authentication_status=", trim(l_ret_authentication_status) 
		DISPLAY "1 = Valid login via sign_on_code" 
		DISPLAY "2 = Valid login via user_code" 
		DISPLAY "3 = Valid login via email address" 
		DISPLAY "-1 = User IS Inactive" 
		DISPLAY "-2 = User does NOT belong TO any group"
		DISPLAY "-3 = User can not be authenticated (invalid authentication details)"  
		DISPLAY "-----------------------------------------------------------" 
	END IF 

	CASE l_ret_authentication_status 
		WHEN 1 
			#Valid login.. via sign_on_code
		WHEN 2 
			#Valid login..  via user_code
		WHEN 3 
			#Valid login..  via email address
		WHEN 99 
			#Valid login..  as special System Administrator
		WHEN -1 
			LET l_msg = "User ", trim(get_ku_sign_on_code()), " - ", trim(get_ku_name_text()), "\n", "User IS Inactive! ERROR -1001" 
			CALL fgl_winmessage("Login",l_msg,"info") 
		WHEN -2 
			LET l_msg = "User Account settings are incomplete\nUser does NOT belong TO any group\nUser ", trim(get_ku_sign_on_code()), " - ", trim(get_ku_name_text()), "\n", "User IS Inactive!(1)" 
			CALL fgl_winmessage("Login",l_msg,"info") 
		WHEN -3 
			LET l_msg = "The username or password is incorrect! \n", "No such user! ERROR -1003" 
			CALL fgl_winmessage("Login",l_msg,"info") 
		WHEN -4 
			LET l_msg = "The username is not allowed to work for that company \n", glob_rec_kandoouser.cmpy_code
			CALL fgl_winmessage("Login",l_msg,"info") 
		OTHERWISE 
			LET l_msg = "Invalid return FROM authenticated_kandoouser_and_set_globals)\nReturn Value =", trim(l_ret_authentication_status), "\nERROR -1002" 
			CALL fgl_winmessage("Invalid return",l_msg,"ERROR") 
			EXIT program #fix 4gl IF this happens 
	END CASE 

	IF l_ret_authentication_status > 0 THEN #positive = Valid login
		LET l_msg = "User ", trim(glob_rec_kandoouser.name_text), " Logged in to company ", trim(glob_rec_kandoouser.cmpy_code), " / " , db_company_get_name_text(UI_OFF,glob_rec_kandoouser.cmpy_code)
		MESSAGE l_msg
		--SLEEP 2 #would be nice to have some kind of timeout- for fgl_winmessage function (no user interaction.. just time)
	END IF

	IF get_debug() = true THEN 
		DISPLAY "########### main_authenticated_kandoouser_and_set_globals() END ################" 
		DISPLAY "p_universal_login_name=", p_universal_login_name 
		DISPLAY "p_u_password=", p_u_password 
		DISPLAY "get_ku_sign_on_code()=", get_ku_sign_on_code() 
		DISPLAY "get_ku_login_name()=", get_ku_login_name() 
		DISPLAY "get_ku_email()=", get_ku_email() 
		DISPLAY "get_ku_password_text()=", get_ku_password_text() 
		DISPLAY "get_ku_group_code()=", get_ku_group_code() 
		DISPLAY "get_ku_user_role_code()=", get_ku_user_role_code() 
		DISPLAY "get_ku_language_code()=", get_ku_language_code() 
		DISPLAY "l_ret_authentication_status=", l_ret_authentication_status 
		DISPLAY "-----------------------------------------------------------" 
	END IF 
	RETURN l_ret_authentication_status 

	# For now, we allow TO use user name, sign_in_name AND email address for the authentication process
	# for now = until we have decided how we manage authentication
END FUNCTION 
##############################################################
# END FUNCTION main_authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password)
##############################################################


#####################################################################
# FUNCTION authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password)
#
#
#####################################################################
FUNCTION authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password) 
	DEFINE p_u_password LIKE kandoouser.password_text 
	DEFINE p_universal_login_name NVARCHAR(100) 
	DEFINE l_ret SMALLINT 
	DEFINE l_msg STRING 
	DEFINE l_temp1char CHAR  

	IF get_debug() = true THEN 
		DISPLAY "########### authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password) START ################" 
		DISPLAY "p_universal_login_name=", p_universal_login_name 
		DISPLAY "p_u_password=", p_u_password 
		DISPLAY "-----------------------------------------------------------" 
	END IF 
	LET l_ret = NULL 

	# @eric - this is just a hack... we need your special "french-Eric" new Kandoo authentication lib/tools/db
	# New section 18.09.2019 Build in Admin Account
	# Needs some function and storage for special build in System Administrator
	CASE 
		WHEN p_universal_login_name = "admin" AND p_u_password = "admin"
			# Ok let's try go read admin's role in the	kandoouser table
			LET l_ret = 99 
			MESSAGE "Login as Kandoo System Administrator" 
			LET glob_rec_kandoouser.sign_on_code = p_universal_login_name 
			LET glob_rec_kandoouser.login_name = p_universal_login_name 
			LET glob_rec_kandoouser.password_text = p_u_password 
			LET glob_rec_company.language_code = "ENG" 
			LET glob_rec_kandoouser.name_text = "System Administrator" 
			LET glob_rec_kandoouser.security_ind = "Z" 
			LET glob_rec_kandoouser.language_code = "ENG" 
			LET glob_rec_kandoouser.cmpy_code = "99" 
			LET glob_rec_kandoouser.acct_mask_code = "??????????????????" 
			LET glob_rec_kandoouser.profile_code = "MAX" 
			LET glob_rec_kandoouser.access_ind = "1" 
			LET glob_rec_kandoouser.passwd_ind = "1" 
			LET glob_rec_kandoouser.memo_pri_ind = "1" 
			LET glob_rec_kandoouser.user_role_code = "A" 
			LET glob_rec_kandoouser.group_code = "1" 
			LET glob_rec_kandoouser.menu_group_code = "1" 
			LET glob_rec_kandoouser.pwchange = 0 
			LET glob_rec_company.cmpy_code = "99" 
			LET glob_rec_company.name_text = "Administrator doesn't belong to any company" 
			LET glob_rec_company.country_code = "UK" --@db-patch_2020_10_04-- 
			LET glob_rec_company.module_text = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" 
			CALL fgl_setenv("KANDOO_SIGN_ON_CODE",glob_rec_kandoouser.sign_on_code) 
			CALL fgl_setenv("KANDOO_LOGIN_NAME",glob_rec_kandoouser.login_name) 
			CALL fgl_setenv("KANDOO_PASSWORD_TEXT",glob_rec_kandoouser.password_text) 
			CALL fgl_setenv("KANDOO_LANGUAGE_CODE",glob_rec_kandoouser.language_code)
		#ELSE #normal user with kandoo company/user account 
		# We try login using sign_on_code,  user_code AND email
		# login with sign_in_code

		WHEN util.regex.match(p_universal_login_name,/\w+@\w+/)
			# if we have an email address
			SELECT * INTO glob_rec_kandoouser.* 
			FROM kandoouser 
			WHERE email = p_universal_login_name 
			AND password_text = p_u_password 
			IF sqlca.sqlcode = 0 THEN #100 
				LET l_ret = 3 
			END IF

		OTHERWISE
			SELECT * INTO glob_rec_kandoouser.* 
			FROM kandoouser 
			WHERE sign_on_code = p_universal_login_name
			AND password_text = p_u_password 
			IF sqlca.sqlcode = 0 THEN #100 
				LET l_ret = 1 
			ELSE 
				# if NOT found, try user_code
				SELECT * INTO glob_rec_kandoouser.* 
				FROM kandoouser 
				WHERE login_name = p_universal_login_name 
				AND password_text = p_u_password 
				IF sqlca.sqlcode = 0 THEN #100 
					LET l_ret = 2 
				ELSE
					LET l_ret = -3
					RETURN l_ret
				END IF
			END IF 

	END CASE 
		# changed TO kandoo user management
		# check if account IS enabled

	CALL set_authenticated_user_locale(glob_rec_kandoouser.language_code, glob_rec_kandoouser.country_code )

	SELECT 1 
	FROM kandoouser 
	WHERE access_ind > 0 
	AND sign_on_code = glob_rec_kandoouser.sign_on_code 
	IF status=notfound AND (glob_rec_kandoouser.cmpy_code != "99" OR glob_rec_kandoouser.cmpy_code IS NULL ) THEN 
		LET l_ret = -1 
		IF get_debug() = true THEN 
			DISPLAY "authenticated_kandoouser_and_set_globals() ################" 
			DISPLAY "User account is disabled (kandoouser.access_ind !=1)" 
		END IF
		RETURN l_ret 
	ELSE 
		IF get_debug() = true THEN 
			DISPLAY "authenticated_kandoouser_and_set_globals() ################" 
			DISPLAY "User account is enabled (kandoouser.access_ind = 1)" 
		END IF 
	END IF 

	# Check if this user is allowed to log into that company
	SELECT 't'
	FROM kandoousercmpy
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND sign_on_code = glob_rec_kandoouser.sign_on_code
	IF sqlca.sqlcode = NOTFOUND THEN
		LET l_ret = -4    # not allowed for this company
	END IF
	
	
	# check if user belongs TO a group (MUST be member of at least ONE group
	# this needs changing when we have decided on user roles & groups
	# Is labeled "Cheque Group Code"
	SELECT group_code INTO l_temp1char 
	FROM kandoouser 
	WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
		
	IF status=notfound AND (glob_rec_kandoouser.cmpy_code != "99" OR glob_rec_kandoouser.cmpy_code IS NULL ) THEN 
		LET l_ret = -2 
		IF get_debug() = true THEN 
			DISPLAY "authenticated_kandoouser_and_set_globals() ################" 
			DISPLAY "User does not belong to any group" 
			DISPLAY "User kandoouser.group_code=", trim(l_temp1char) 
		END IF 
	ELSE 
		IF get_debug() = true THEN 
			DISPLAY "authenticated_kandoouser_and_set_globals() ################" 
			DISPLAY "User does belong to a group" 
			DISPLAY "User kandoouser.group_code=", trim(l_temp1char) 
		END IF 
	END IF 
	IF l_ret > 0 THEN #update authentication log/success 
	END IF 
	RETURN l_ret #null = authentication faild, 1-3 authenticated via sign_on user_code OR email 

END FUNCTION 
#####################################################################
# END FUNCTION authenticated_kandoouser_and_set_globals(p_universal_login_name,p_u_password)
#####################################################################


#####################################################################
# FUNCTION init_kandoouser_environment()
#
#
#####################################################################
FUNCTION init_kandoouser_environment() 
	DEFINE l_msg STRING
	
	# "99" = Special build in none-existing System Administrator Company
	IF glob_rec_kandoouser.cmpy_code != "99" THEN 
		SELECT * 
		INTO glob_rec_kandoouser 
		FROM kandoouser 
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
		
		SELECT * 
		INTO glob_rec_company 
		FROM company 
		WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF sqlca.sqlcode = NOTFOUND THEN
			# added by ericv 2020-05-24: see how to manage this error in a more beautiful way
			#ERROR "The company of this user does not exist ",glob_rec_kandoouser.cmpy_code
			LET l_msg = "The company of this user does not exist ",glob_rec_kandoouser.cmpy_code
			CALL fgl_winmessage("ERROR", l_msg, "ERROR")
			--EXIT PROGRAM   
			RETURN FALSE
		END IF
		#LET cmpy = glob_rec_kandoouser.cmpy_code #at some stage, all modules should access cmpy_code directly FROM glob_rec_kandoouser
		#SELECT * INTO glob_language FROM language WHERE language_code = glob_rec_kandoouser.language_code
	END IF 
	
	# Set the local values for Yes flag and No flag (once forever for this user)
	CALL set_local_yes_no()
		
	#will be removed later
	CALL fgl_setenv("KANDOO_SIGN_ON_CODE",glob_rec_kandoouser.sign_on_code) 
	CALL fgl_setenv("KANDOO_LOGIN_NAME",glob_rec_kandoouser.login_name) 
	CALL fgl_setenv("KANDOO_PASSWORD_TEXT",glob_rec_kandoouser.password_text) 
	CALL fgl_setenv("KANDOO_LANGUAGE_CODE",glob_rec_kandoouser.language_code) 

	CALL registerlogindata() --write login TO LOG file/db 

	#INIT DEFAULT SETTINGS
	CALL init_general_company_settings()
	CALL init_general_division_settings()	#Division/Department
	CALL init_general_user_settings()
		
	RETURN TRUE
END FUNCTION 
#####################################################################
# END init_kandoouser_environment()
#####################################################################