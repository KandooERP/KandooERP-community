GLOBALS "../common/glob_GLOBALS.4gl" 

####################################################################
# FUNCTION readAuthenticationEnvVariables()
#
# User can specify the login details also via environment variables
# NOTE: launching programs via the menu will always use this approach for child applications
####################################################################
FUNCTION readauthenticationenvvariables() 
	CALL set_debug(fgl_getenv("KANDOO_DEBUG")) 
	CALL set_ku_sign_on_code(fgl_getenv("KANDOO_SIGN_ON_CODE")) 
	CALL set_ku_login_name(fgl_getenv("KANDOO_LOGIN_NAME")) 
	CALL set_ku_email(fgl_getenv("KANDOO_EMAIL")) 
	CALL set_ku_password_text(fgl_getenv("KANDOO_PASSWORD_TEXT")) 


	IF get_debug() = true THEN 
		DISPLAY "########### readAuthenticationEnvVariables() ################" 
		DISPLAY "glob_rec_kandoouser.sign_on_code =", glob_rec_kandoouser.sign_on_code 
		DISPLAY "glob_rec_kandoouser.password_text =", glob_rec_kandoouser.password_text 
		DISPLAY "glob_rec_kandoouser.login_name =", glob_rec_kandoouser.login_name 
		DISPLAY "glob_rec_kandoouser.email =", glob_rec_kandoouser.email 
		DISPLAY "--------------------------------------------------------------" 
	END IF 


END FUNCTION 