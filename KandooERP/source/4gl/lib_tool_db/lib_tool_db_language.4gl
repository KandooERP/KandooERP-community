##############################################################################################
# TABLE language
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_language_get_language_text(p_language_code)
#
#
############################################################
FUNCTION db_language_get_language_text(p_language_code)
	DEFINE p_language_code LIKE language.language_code
	DEFINE l_language_text LIKE language.yes_flag
	DEFINE l_msgresp LIKE language.yes_flag	

	SQL
		SELECT yes_flag
		INTO $l_language_text
		FROM language
		WHERE language_code = $p_language_code
	END SQL 

	IF SQLCA.SQLCODE != 0 THEN
		ERROR kandoomsg2("P",5007,"") #P5007 " Parameters Not Found, See Menu GZP"
--		sleep 2
 		ERROR kandoomsg2("U",5107,"") #5107 General Ledger Parameters NOT SET up; Refer Menu GZP. 

		RETURN NULL
	ELSE
		RETURN l_language_text 
	END IF 
END FUNCTION	


############################################################
# FUNCTION db_language_get_yes_flag(p_language_code)
#
#
############################################################
FUNCTION db_language_get_yes_flag(p_language_code)
	DEFINE p_language_code LIKE language.language_code
	DEFINE l_yes_flag LIKE language.yes_flag
	DEFINE l_msgresp LIKE language.yes_flag	

	SQL
		SELECT yes_flag
		INTO $l_yes_flag
		FROM language
		WHERE language_code = $p_language_code
	END SQL 

	IF SQLCA.SQLCODE != 0 THEN
		ERROR kandoomsg2("P",5007,"") #P5007 " Parameters Not Found, See Menu GZP"
--		sleep 2
 		ERROR kandoomsg2("U",5107,"") #5107 General Ledger Parameters NOT SET up; Refer Menu GZP.

		RETURN NULL
	ELSE
		RETURN l_yes_flag 
	END IF 
END FUNCTION 


############################################################
# FUNCTION db_language_get_no_flag(p_language_code)
#
#
############################################################
FUNCTION db_language_get_no_flag(p_language_code)
	DEFINE p_language_code LIKE language.language_code
	DEFINE l_no_flag LIKE language.no_flag
	DEFINE l_msgresp LIKE language.no_flag

	SQL
		SELECT no_flag
		INTO $l_no_flag
		FROM language
		WHERE language_code = $p_language_code
	END SQL

	IF sqlca.sqlcode != 0 THEN
		ERROR kandoomsg2("P",5007,"")
		#P5007 " Parameters Not Found, See Menu GZP"
--			sleep 2
 		ERROR kandoomsg2("U",5107,"")
		#5107 General Ledger Parameters NOT SET up; Refer Menu GZP. 
		RETURN NULL
	ELSE
		RETURN l_no_flag
	END IF 
END FUNCTION	



############################################################
# FUNCTION db_language_get_national_text(p_language_code)
#
#
############################################################
FUNCTION db_language_get_national_text(p_language_code)
	DEFINE p_language_code LIKE language.language_code
	DEFINE l_national_text LIKE language.national_text
	DEFINE l_msgresp LIKE language.national_text

	SQL
		SELECT national_text
		INTO $l_national_text
		FROM language
		WHERE language_code = $p_language_code
	END SQL 

	IF sqlca.sqlcode != 0 THEN
		ERROR kandoomsg2("P",5007,"")
		 #P5007 " Parameters Not Found, See Menu GZP"
		--	sleep 2
		ERROR kandoomsg2("U",5107,"")
		#5107 General Ledger Parameters NOT SET up; Refer Menu GZP. 
		RETURN NULL
	ELSE
		RETURN l_national_text
	END IF
END FUNCTION
