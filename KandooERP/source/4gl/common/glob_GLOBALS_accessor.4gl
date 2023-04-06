############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION get_ku_rec()
#
#
############################################################
FUNCTION get_ku_rec() 
	RETURN glob_rec_kandoouser.* 
END FUNCTION 
############################################################
# END FUNCTION get_ku_rec()
############################################################


############################################################
# FUNCTION set_ku_rec(p_ku_rec)
#
#
############################################################
FUNCTION set_ku_rec(p_ku_rec) 
	DEFINE p_ku_rec RECORD LIKE kandoouser.* 
	LET glob_rec_kandoouser.* = p_ku_rec.* 
END FUNCTION 
############################################################
# END FUNCTION set_ku_rec(p_ku_rec)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_login_name()
#
#
############################################################
FUNCTION get_ku_login_name() 
	RETURN glob_rec_kandoouser.login_name 
END FUNCTION 
############################################################
# END FUNCTION get_ku_login_name()
############################################################

############################################################
# FUNCTION set_ku_login_name(p_login_name)
#
#
############################################################
FUNCTION set_ku_login_name(p_login_name) 
	DEFINE p_login_name LIKE kandoouser.login_name 

	IF p_login_name IS NOT NULL THEN 
		LET glob_rec_kandoouser.login_name = p_login_name 
		CALL fgl_setenv("KANDOO_LOGIN_NAME",glob_rec_kandoouser.login_name) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION set_ku_login_name(p_login_name)
############################################################


#temp fix until we fully sorted authentication
############################################################
# FUNCTION set_match_ku_user_sign_on_code_login_name()
#
#
############################################################
FUNCTION set_match_ku_user_sign_on_code_login_name() 
	LET glob_rec_kandoouser.login_name = glob_rec_kandoouser.sign_on_code 
END FUNCTION 
############################################################
# END FUNCTION set_match_ku_user_sign_on_code_login_name()
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_sign_on_code()
#
#
############################################################
FUNCTION get_ku_sign_on_code() 
	RETURN glob_rec_kandoouser.sign_on_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_sign_on_code()
############################################################

############################################################
# FUNCTION set_ku_sign_on_code(p_sign_on_code)
#
#
############################################################
FUNCTION set_ku_sign_on_code(p_sign_on_code) 
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code 
	IF p_sign_on_code IS NOT NULL THEN 
		LET glob_rec_kandoouser.sign_on_code = p_sign_on_code 
		CALL fgl_setenv("KANDOO_SIGN_ON_CODE",glob_rec_kandoouser.sign_on_code) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION set_ku_sign_on_code(p_sign_on_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_password_text()
#
#
############################################################
FUNCTION get_ku_password_text() 
	RETURN glob_rec_kandoouser.password_text 
END FUNCTION 
############################################################
# END FUNCTION get_ku_password_text()
############################################################


############################################################
# FUNCTION set_ku_password_text(p_password_text)
############################################################
FUNCTION set_ku_password_text(p_password_text) 
	DEFINE p_password_text LIKE kandoouser.password_text 

	IF p_password_text IS NOT NULL THEN 
		LET glob_rec_kandoouser.password_text = p_password_text 
		CALL fgl_setenv("KANDOO_PASSWORD_TEXT",glob_rec_kandoouser.password_text) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION set_ku_password_text(p_password_text)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_name_text()
#
#
############################################################
FUNCTION get_ku_name_text() 
	RETURN glob_rec_kandoouser.name_text 
END FUNCTION 
############################################################
# END FUNCTION get_ku_name_text()
############################################################


############################################################
# FUNCTION set_ku_name_text(p_name_text)
#
#
############################################################
FUNCTION set_ku_name_text(p_name_text) 
	DEFINE p_name_text LIKE kandoouser.name_text 
	LET glob_rec_kandoouser.name_text = p_name_text 
END FUNCTION 
############################################################
# END FUNCTION set_ku_name_text(p_name_text)
############################################################

-------------------------------------

############################################################
# FUNCTION get_ku_cmpy_code()
#
#
############################################################
FUNCTION get_ku_cmpy_code() 
	RETURN glob_rec_kandoouser.cmpy_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_cmpy_code()
############################################################


############################################################
# FUNCTION set_ku_cmpy_code(p_cmpy_code)
#
#
############################################################
FUNCTION set_ku_cmpy_code(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE kandoouser.cmpy_code 
	LET glob_rec_kandoouser.cmpy_code  = p_cmpy_code 
END FUNCTION 
############################################################
# END FUNCTION set_ku_cmpy_code(p_cmpy_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_group_code()
#
#
############################################################
FUNCTION get_ku_group_code() 
	RETURN glob_rec_kandoouser.group_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_group_code()
############################################################


############################################################
# FUNCTION set_ku_group_code(p_group_code)
#
#
############################################################
FUNCTION set_ku_group_code(p_group_code) 
	DEFINE p_group_code LIKE kandoouser.group_code 
	LET glob_rec_kandoouser.group_code = p_group_code 
END FUNCTION 
############################################################
# END FUNCTION set_ku_group_code(p_group_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_user_role_code()
#
# user_role_code
############################################################
FUNCTION get_ku_user_role_code() 
	RETURN glob_rec_kandoouser.user_role_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_user_role_code()
############################################################

############################################################
# FUNCTION set_ku_user_role_code(p_user_role_code)
#
#
############################################################
FUNCTION set_ku_user_role_code(p_user_role_code) 
	DEFINE p_user_role_code LIKE kandoouser.user_role_code 
	LET glob_rec_kandoouser.user_role_code = p_user_role_code 
END FUNCTION 
############################################################
# END FUNCTION set_ku_user_role_code(p_user_role_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_country_code()
#
#
############################################################
FUNCTION get_ku_country_code() 
	RETURN glob_rec_kandoouser.country_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_country_code()
############################################################


############################################################
# FUNCTION set_ku_country_code(p_country_code)
#
#
############################################################
FUNCTION set_ku_country_code(p_country_code) 
	DEFINE p_country_code LIKE kandoouser.country_code 
	LET glob_rec_kandoouser.country_code = p_country_code 
	CALL fgl_setenv("KANDOO_country_CODE",glob_rec_kandoouser.country_code) 
END FUNCTION 
############################################################
# END FUNCTION set_ku_country_code(p_country_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_language_code()
#
#
############################################################
FUNCTION get_ku_language_code() 
	RETURN glob_rec_kandoouser.language_code 
END FUNCTION 
############################################################
# END FUNCTION get_ku_language_code()
############################################################

############################################################
# FUNCTION set_ku_language_code(p_language_code)
#
#
############################################################
FUNCTION set_ku_language_code(p_language_code) 
	DEFINE p_language_code LIKE kandoouser.language_code 
	LET glob_rec_kandoouser.language_code = p_language_code 
	CALL fgl_setenv("KANDOO_LANGUAGE_CODE",glob_rec_kandoouser.language_code) 
END FUNCTION 
############################################################
# END FUNCTION set_ku_language_code(p_language_code)
############################################################

-----------------------------------

############################################################
# FUNCTION get_ku_email()
#
#
############################################################
FUNCTION get_ku_email() 
	RETURN glob_rec_kandoouser.email 
END FUNCTION 
############################################################
# END FUNCTION get_ku_email()
############################################################


############################################################
# FUNCTION set_ku_email(p_email)
#
#
############################################################
FUNCTION set_ku_email(p_email) 
	DEFINE p_email LIKE kandoouser.email 

	IF p_email IS NOT NULL THEN 
		LET glob_rec_kandoouser.email = p_email 
		CALL fgl_setenv("KANDOO_EMAIL",glob_rec_kandoouser.email) 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION set_ku_email(p_email)
############################################################

----------------------------------

############################################################
# FUNCTION get_ku_database_name()
#
#
############################################################
FUNCTION get_ku_database_name()
	DEFINE l_db_name STRING
	
	LET l_db_name = fgl_getenv("KANDOODB")  
	RETURN l_db_name 
END FUNCTION
############################################################
# END FUNCTION get_ku_database_name()
############################################################