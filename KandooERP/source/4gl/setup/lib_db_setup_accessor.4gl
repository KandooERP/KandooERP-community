GLOBALS "lib_db_globals.4gl"
	DEFINE gl_setupRec_default_company_orig RECORD LIKE company.*

#	DEFINE gl_setupRec_admin_rec_kandoouser RECORD LIKE kandoouser.*
#	DEFINE glob_language RECORD LIKE language.*
#	DEFINE gl_setupRec_default_company RECORD LIKE company.*
#	DEFINE gl_setupRec_kandooprofile RECORD LIKE kandooprofile.*  
#	DEFINE gl_setupRec_bic RECORD LIKE bic.*

{
FUNCTION get_company_orig()
	RETURN gl_setupRec_default_company_orig.*
END FUNCTION

FUNCTION set_company_orig(pRecCompany)
	DEFINE pRecCompany RECORD LIKE company.*
	
	LET gl_setupRec_default_company_orig.* = pRecCompany.*
END FUNCTION
}
---------------
FUNCTION getCurrentUser_sign_on_code()
	RETURN gl_setupRec_admin_rec_kandoouser.sign_on_code
END FUNCTION

FUNCTION setCurrentUser_sign_on_code(p_sign_on_code)
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	LET gl_setupRec_admin_rec_kandoouser.sign_on_code = p_sign_on_code
END FUNCTION

-------------

FUNCTION getCurrentUser_name_text()
	RETURN gl_setupRec_admin_rec_kandoouser.name_text
END FUNCTION

FUNCTION setCurrentUser_name_text(p_name_text)
	DEFINE p_name_text LIKE kandoouser.name_text
	LET gl_setupRec_admin_rec_kandoouser.name_text = p_name_text
END FUNCTION

------------

FUNCTION getCurrentUser_security_ind()
	RETURN gl_setupRec_admin_rec_kandoouser.security_ind
END FUNCTION

FUNCTION setCurrentUser_security_ind(p_security_ind)
	DEFINE p_security_ind LIKE kandoouser.security_ind
	LET gl_setupRec_admin_rec_kandoouser.security_ind = p_security_ind
END FUNCTION

--------------

FUNCTION getCurrentUser_currency_code()
	RETURN gl_setupRec_default_company.curr_code
END FUNCTION

FUNCTION setCurrentUser_currency_code(p_curr_code)
	DEFINE p_curr_code LIKE company.curr_code
	LET gl_setupRec_default_company.curr_code = p_curr_code
END FUNCTION
--------------
FUNCTION getCurrentUser_country_code()
	RETURN gl_setupRec_default_company.country_code
END FUNCTION

FUNCTION setCurrentUser_country_code(p_country_code)
	DEFINE p_country_code LIKE company.country_code
	LET gl_setupRec_default_company.country_code = p_country_code 
END FUNCTION

--------------

FUNCTION getCurrentUser_language_code()
	RETURN gl_setupRec_default_company.language_code
END FUNCTION

FUNCTION setCurrentUser_language_code(p_language_code)
	DEFINE p_language_code LIKE company.language_code
	LET gl_setupRec_default_company.language_code = p_language_code 
	LET gl_setupRec_admin_rec_kandoouser.language_code = p_language_code	
END FUNCTION

---------------

FUNCTION getCurrentUser_cmpy_code()
	RETURN gl_setupRec_default_company.cmpy_code
END FUNCTION

FUNCTION setCurrentUser_cmpy_code(p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code
	LET gl_setupRec_default_company.cmpy_code = p_cmpy_code
END FUNCTION


#FUNCTION getCurrentUser_group_code()
#	RETURN glob_rec_kandoouser.group_code
#END FUNCTION