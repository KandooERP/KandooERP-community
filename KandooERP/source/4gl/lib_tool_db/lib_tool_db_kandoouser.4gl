##############################################################################################
# TABLE kandoouser
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_kandoouser_get_count()
#
# Return total number of rows in kandoouser 
############################################################
FUNCTION db_kandoouser_get_count()
	DEFINE l_ret_count INT

	WHENEVER SQLERROR CONTINUE 
		SQL
			SELECT count(*) 
			INTO $l_ret_count 
			FROM kandoouser 
		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			
	RETURN l_ret_count
END FUNCTION


############################################################
# FUNCTION db_kandoouser_pk_exists(p_ui,p_sign_on_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_kandoouser_pk_exists(p_ui,p_sign_on_code)
	DEFINE p_ui SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_exist BOOLEAN
	DEFINE l_rec_count INT
	DEFINE l_msg STRING

	IF p_sign_on_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "kandoouser Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQLERROR CONTINUE 
		SQL
			SELECT count(*) 
			INTO $l_rec_count 
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
	IF (l_rec_count <> 0) AND (sqlca.sqlcode != 0) THEN
		LET l_ret_exist = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "kandoouser Code exists! (", trim(p_sign_on_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "kandoouser Code already exists! (", trim(p_sign_on_code), ")"
		END IF
	ELSE
		LET l_ret_exist = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "kandoouser Code does not exists! (", trim(p_sign_on_code), ")"
		END IF
	END IF
	
	RETURN l_ret_exist
END FUNCTION

############################################################
# FUNCTION db_kandoouser_get_rec(p_sign_on_code)
#
#
############################################################
FUNCTION db_kandoouser_get_rec(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.*

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF
	
	WHENEVER SQLERROR CONTINUE
		SQL
	      SELECT *
	        INTO $l_rec_kandoouser.*
	        FROM kandoouser
	       WHERE sign_on_code = $p_sign_on_code
		END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN   	
		INITIALIZE l_rec_kandoouser.* TO NULL
	END IF
	
	RETURN l_rec_kandoouser.*
END FUNCTION	


############################################################
# FUNCTION db_kandoouser_get_rec_by_sign_on_code(p_sign_on_code)
#
#
############################################################
FUNCTION db_kandoouser_get_rec_by_sign_on_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.*

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF
	
	WHENEVER SQLERROR CONTINUE
		SQL
	      SELECT *
	        INTO $l_rec_kandoouser.*
	        FROM kandoouser
	       WHERE sign_on_code = $p_sign_on_code
		END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN   	
		INITIALIZE l_rec_kandoouser.* TO NULL
	END IF
	
	RETURN l_rec_kandoouser.*
END FUNCTION	


############################################################
# FUNCTION db_kandoouser_get_rec_by_email(p_email)
#
#
############################################################
FUNCTION db_kandoouser_get_rec_by_email(p_ui_mode,p_email)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_email LIKE kandoouser.email
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.*

	IF p_email IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF
	
	WHENEVER SQLERROR CONTINUE
		SQL
	      SELECT *
	        INTO $l_rec_kandoouser.*
	        FROM kandoouser
	       WHERE email = $p_email
		END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN   	
		INITIALIZE l_rec_kandoouser.* TO NULL
	END IF
	
	RETURN l_rec_kandoouser.*
END FUNCTION	



############################################################
# FUNCTION db_kandoouser_get_rec_by_login_name(p_login_name)
#
#
############################################################
FUNCTION db_kandoouser_get_rec_by_login_name(p_ui_mode,p_login_name)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_login_name LIKE kandoouser.login_name
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.*

	IF p_login_name IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF
	
	WHENEVER SQLERROR CONTINUE
		SQL
	      SELECT *
	        INTO $l_rec_kandoouser.*
	        FROM kandoouser
	       WHERE login_name = $p_login_name
		END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN   	
		INITIALIZE l_rec_kandoouser.* TO NULL
	END IF
	
	RETURN l_rec_kandoouser.*
END FUNCTION	

############################################################
# FUNCTION db_kandoouser_get_name_text(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_name_text(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_name_text LIKE kandoouser.name_text

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "kandoouser Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT name_text
			INTO $l_ret_name_text
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Description with Code ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_name_text = NULL
	END IF	

	RETURN l_ret_name_text
END FUNCTION



############################################################
# FUNCTION db_kandoouser_get_country_code(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_country_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_country_code LIKE kandoouser.country_code

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT country_code
			INTO $l_ret_country_code
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Country Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_country_code = NULL
	END IF	
	
	RETURN l_ret_country_code	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_kandoouser_get_language_code(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_language_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_language_code LIKE kandoouser.language_code

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT language_code
			INTO $l_ret_language_code
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Country Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_language_code = NULL
	END IF	
	
	RETURN l_ret_language_code	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_kandoouser_get_group_code(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_group_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_group_code LIKE kandoouser.group_code

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT group_code
			INTO $l_ret_group_code
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Country Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_group_code = NULL
	END IF	
	
	RETURN l_ret_group_code	                                                                                                
END FUNCTION



############################################################
# FUNCTION db_kandoouser_get_security_ind(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_security_ind(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_security_ind LIKE kandoouser.security_ind

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT security_ind
			INTO $l_ret_security_ind
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Country Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_security_ind = NULL
	END IF	
	
	RETURN l_ret_security_ind	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_kandoouser_get_access_ind(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_access_ind(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_access_ind LIKE kandoouser.access_ind

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT access_ind
			INTO $l_ret_access_ind
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Country Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_access_ind = NULL
	END IF	
	
	RETURN l_ret_access_ind	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_kandoouser_get_passwd_ind(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_passwd_ind(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_passwd_ind LIKE kandoouser.passwd_ind

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT passwd_ind
			INTO $l_ret_passwd_ind
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser currency Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_passwd_ind = NULL
	END IF	
	
	RETURN l_ret_passwd_ind	                                                                                                
END FUNCTION



############################################################
# FUNCTION db_kandoouser_get_memo_pri_ind(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_memo_pri_ind(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_memo_pri_ind LIKE kandoouser.memo_pri_ind

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT memo_pri_ind
			INTO $l_ret_memo_pri_ind
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser currency Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_memo_pri_ind = NULL
	END IF	
	
	RETURN l_ret_memo_pri_ind	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_kandoouser_get_user_role_code(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_user_role_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_user_role_code LIKE kandoouser.user_role_code

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT user_role_code
			INTO $l_ret_user_role_code
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser currency Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_user_role_code = NULL
	END IF	
	
	RETURN l_ret_user_role_code	                                                                                                
END FUNCTION



############################################################
# FUNCTION db_kandoouser_get_acct_mask_code(p_sign_on_code)
# RETURN l_ret_name_text
#
# Get kandoouser name of kandoouser record
############################################################
FUNCTION db_kandoouser_get_acct_mask_code(p_ui_mode,p_sign_on_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE l_ret_acct_mask_code LIKE kandoouser.acct_mask_code

	IF p_sign_on_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT acct_mask_code
			INTO $l_ret_acct_mask_code
			FROM kandoouser 
			WHERE kandoouser.sign_on_code = $p_sign_on_code  		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandoouser currency Code for kandoouserCode ",trim(p_sign_on_code),  "NOT found"
		END IF
		LET l_ret_acct_mask_code = NULL
	END IF	
	
	RETURN l_ret_acct_mask_code	                                                                                                
END FUNCTION



###########################################################
# FUNCTION get_kandoouser_info(p_sign_on_code)
# this function is used by most setup modules
# Gets common kandoouser information based on sign_on_code
###########################################################
FUNCTION get_kandoouser_info(p_sign_on_code)
	DEFINE p_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE p_name_text LIKE kandoouser.name_text
	DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_code LIKE kandoouser.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE recCount INT

	WHENEVER SQLERROR CONTINUE
	select kandoouser.name_text,
		kandoouser.country_code,
		country.country_text ,
		kandoouser.language_code,
		language.language_text
	INTO p_name_text,p_country_code,p_country_text,p_language_code,p_language_text 
	FROM kandoouser,
		country,
		language 
	WHERE kandoouser.sign_on_code = p_sign_on_code
		AND kandoouser.country_code = country.country_code
		AND kandoouser.language_code = language.language_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	 	
	CASE #HuHo WOW.. I have tears in my eyes 
		WHEN sqlca.sqlcode = 0 AND p_country_code IS NOT NULL 
			RETURN  p_name_text,p_country_code,p_country_text,p_language_code,p_language_text
		WHEN sqlca.sqlcode = 0 AND p_country_code IS NULL
			RETURN "NUL","NUL","NUL","NUL","NUL"
		WHEN sqlca.sqlcode = 100
			RETURN "0","0","0",0
		OTHERWISE
			RETURN sqlca.sqlcode,sqlca.sqlcode,sqlca.sqlcode,sqlca.sqlcode,sqlca.sqlcode
		END CASE
END FUNCTION


{

########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_kandoouser_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_kandoouser_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_kandoouser DYNAMIC ARRAY OF RECORD LIKE kandoouser.*		
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY kandoouser.sign_on_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 				
	END CASE

	WHENEVER SQLERROR CONTINUE
	PREPARE s_kandoouser FROM l_query_text
	DECLARE c_kandoouser CURSOR FOR s_kandoouser


	LET l_idx = 1
	FOREACH c_kandoouser INTO l_arr_rec_kandoouser[l_idx].*    -- albo KD-1223
      LET l_idx = l_idx + 1
#      LET l_arr_rec_kandoouser[l_idx].sign_on_code = l_rec_kandoouser.sign_on_code
#      LET l_arr_rec_kandoouser[l_idx].desc_text = l_rec_kandoouser.desc_text
#      LET l_arr_rec_kandoouser[l_idx].post_code = l_rec_kandoouser.post_code
#      LET l_arr_rec_kandoouser[l_idx].bank_ref = l_rec_kandoouser.bank_ref
	END FOREACH
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		LET l_arr_rec_kandoouser = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_kandoouser		                                                                                                
END FUNCTION


############################################################
# FUNCTION db_kandoouser_get_arr_rec_c_n_c_t(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_kandoouser_get_arr_rec_c_n_c_t(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_kandoouser DYNAMIC ARRAY OF t_rec_kandoouser_c_n_c_t	
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* #
	DEFINE l_idx SMALLINT
		
	IF p_query_or_where_text IS NULL THEN  #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY kandoouser.sign_on_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 				
	END CASE

	WHENEVER SQLERROR CONTINUE
	PREPARE s_kandoouser_short FROM l_query_text
	DECLARE c_kandoouser_short CURSOR FOR s_kandoouser_short

	LET l_idx = 0
	FOREACH c_kandoouser_short INTO l_rec_kandoouser.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_kandoouser[l_idx].sign_on_code = l_rec_kandoouser.sign_on_code
      LET l_arr_rec_kandoouser[l_idx].name_text = l_rec_kandoouser.name_text
      LET l_arr_rec_kandoouser[l_idx].city_text = l_rec_kandoouser.city_text
      LET l_arr_rec_kandoouser[l_idx].tele_text = l_rec_kandoouser.tele_text
	END FOREACH
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN   	
		LET l_arr_rec_kandoouser = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_kandoouser		                                                                                                
END FUNCTION


########################################################

############################################################
# FUNCTION db_kandoouser_get_arr_c_n_c_c_t_t_a_c_m(p_query_text)
#
#
############################################################
FUNCTION db_kandoouser_get_arr_c_n_c_c_t_t_a_c_m(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_kandoouser DYNAMIC ARRAY OF t_rec_kandoouser_c_n_c_c_t_t_a_c_m	
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* #
	DEFINE l_idx SMALLINT
	
	IF p_query_or_where_text IS NULL THEN  #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY kandoouser.sign_on_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM kandoouser ",
				"ORDER BY kandoouser.sign_on_code" 				
	END CASE

	WHENEVER SQLERROR CONTINUE
	PREPARE s2_kandoouser_short FROM l_query_text
	DECLARE c2_kandoouser_short CURSOR FOR s2_kandoouser_short

	LET l_idx = 0
	FOREACH c2_kandoouser_short INTO l_rec_kandoouser.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_kandoouser[l_idx].sign_on_code = l_rec_kandoouser.sign_on_code
      LET l_arr_rec_kandoouser[l_idx].name_text = l_rec_kandoouser.name_text
      LET l_arr_rec_kandoouser[l_idx].country_code = l_rec_kandoouser.country_code
      LET l_arr_rec_kandoouser[l_idx].city_text = l_rec_kandoouser.city_text
      LET l_arr_rec_kandoouser[l_idx].tele_text = l_rec_kandoouser.tele_text

      LET l_arr_rec_kandoouser[l_idx].tax_text = l_rec_kandoouser.tax_text
      LET l_arr_rec_kandoouser[l_idx].vat_code = l_rec_kandoouser.vat_code
      LET l_arr_rec_kandoouser[l_idx].curr_code = l_rec_kandoouser.curr_code
      LET l_arr_rec_kandoouser[l_idx].module_text = l_rec_kandoouser.module_text
      
	END FOREACH
	WHENEVER SQLERROR CONTINUE
	
	IF sqlca.sqlcode != 0 THEN   	
		LET l_arr_rec_kandoouser = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_kandoouser		                                                                                                
END FUNCTION

}