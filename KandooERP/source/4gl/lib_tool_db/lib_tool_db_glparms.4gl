##############################################################################################
# TABLE glparms
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_glparms_get_count()
#
# Return total number of rows in glparms FROM current company
############################################################
FUNCTION db_glparms_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code		
		
	RETURN l_ret_count
END FUNCTION
############################################################
# FUNCTION db_glparms_get_count()
############################################################


############################################################
# FUNCTION db_glparms_key_code_get_count(p_key_code)
#
# Return total number of rows WITH choosen key_code in glparms FROM current company
############################################################
FUNCTION db_glparms_key_code_get_count(p_key_code)
	DEFINE p_key_code LIKE glparms.key_code
	DEFINE l_ret_count INT

	SELECT count(*) INTO l_ret_count 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND glparms.key_code = p_key_code	

	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_glparms_key_code_get_count(p_key_code)
############################################################


############################################################
# FUNCTION db_glparms_pk_exists(p_key_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_glparms_pk_exists(p_key_code)
	DEFINE p_key_code LIKE glparms.key_code
	DEFINE l_ret INT

	IF p_key_code IS NULL THEN
		RETURN -1
	END IF

	SELECT count(*) INTO l_ret FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = p_key_code 

	RETURN l_ret
END FUNCTION
############################################################
# FUNCTION db_glparms_pk_exists(p_key_code)
############################################################


############################################################
# FUNCTION db_glparms_get_rec(p_key_code)
#
#
############################################################
FUNCTION db_glparms_get_rec(p_key_code)
	DEFINE p_key_code LIKE glparms.key_code
	DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE l_msgresp LIKE language.yes_flag	

	SELECT *
	INTO l_rec_glparms.*
	FROM glparms
	WHERE key_code = p_key_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	IF sqlca.sqlcode != 0 THEN 
		ERROR kandoomsg2("P",5007,"")  #P5007 " Parameters Not Found, See Menu GZP"
--			sleep 2
 		ERROR kandoomsg2("U",5107,"")  #5107 General Ledger Parameters NOT SET up; Refer Menu GZP. 
		RETURN NULL
	ELSE
		RETURN l_rec_glparms.*
	END IF 
END FUNCTION	
############################################################
# END FUNCTION db_glparms_get_rec(p_key_code)
############################################################


############################################################
# FUNCTION db_glparms_get_rec(p_key_code)
#
#
############################################################
FUNCTION db_glparms_get_base_currency_code(p_key_code)
	DEFINE p_key_code LIKE glparms.key_code
	DEFINE l_base_currency_code LIKE glparms.base_currency_code
	DEFINE l_msgresp LIKE language.yes_flag

	SELECT base_currency_code
	INTO l_base_currency_code
	FROM glparms
	WHERE key_code = p_key_code
	AND cmpy_code = glob_rec_kandoouser.cmpy_code

	IF sqlca.sqlcode != 0 THEN
		ERROR kandoomsg2("P",5007,"") #P5007 " Parameters Not Found, See Menu GZP"
		--	sleep 2
 		ERROR kandoomsg2("U",5107,"") #5107 General Ledger Parameters NOT SET up; Refer Menu GZP. 
		RETURN NULL
	ELSE
		RETURN l_base_currency_code
	END IF 
END FUNCTION	
############################################################
# FUNCTION db_glparms_get_rec(p_key_code)
############################################################