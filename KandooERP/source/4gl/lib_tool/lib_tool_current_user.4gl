GLOBALS "../common/glob_GLOBALS.4gl" 

################################################
#  FUNCTION getCurrentUser_sign_on_code()
################################################
FUNCTION getcurrentuser_sign_on_code() 
	RETURN glob_rec_kandoouser.sign_on_code 
END FUNCTION 

################################################
#  FUNCTION getCurrentUser_name_text()
################################################
FUNCTION getcurrentuser_name_text() 
	RETURN glob_rec_kandoouser.name_text 
END FUNCTION 

################################################
#  FUNCTION getCurrentUser_security_ind()
################################################
FUNCTION getcurrentuser_security_ind() 
	RETURN glob_rec_kandoouser.security_ind 
END FUNCTION 

################################################
#  FUNCTION getCurrentUser_language_code()
################################################
FUNCTION getcurrentuser_language_code() 
	RETURN glob_rec_kandoouser.language_code 
END FUNCTION 

################################################
#  FUNCTION getCurrentUser_cmpy_code()
################################################
FUNCTION getcurrentuser_cmpy_code() 
	RETURN glob_rec_kandoouser.cmpy_code 
END FUNCTION 

################################################
#  FUNCTION getCurrentUser_group_code()
################################################
FUNCTION getcurrentuser_group_code() 
	RETURN glob_rec_kandoouser.group_code 
END FUNCTION 
