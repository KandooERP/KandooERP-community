##############################################################################################
# TABLE: company
# NOTE: This Module is linked with lib_tool (not lib_tool_db) because it is required by ALL programs i.e. due to authentication
##############################################################################################

###########################################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

###########################################################################
# FUNCTION db_company_get_count()
#
# Return total number of rows in company 
###########################################################################
FUNCTION db_company_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM company 
			
	RETURN l_ret_count
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_count()
###########################################################################


###########################################################################
# FUNCTION db_company_pk_exists(p_ui,p_cmpy_code)
#
# Validate PK - Unique
###########################################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
###########################################################################
FUNCTION db_company_pk_exists(p_ui,p_cmpy_code)
	DEFINE p_ui SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_ret_exist BOOLEAN
	DEFINE l_rec_count INT
	DEFINE l_msg STRING

	IF p_cmpy_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "company Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	SELECT count(*) 
	INTO l_rec_count 
	FROM company 
	WHERE company.cmpy_code = p_cmpy_code  
		
	IF (l_rec_count <> 0) THEN --AND (sqlca.sqlcode != 0) THEN
		LET l_ret_exist = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "company Code exists! (", trim(p_cmpy_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "company Code already exists! (", trim(p_cmpy_code), ")"
		END IF
	ELSE
		LET l_ret_exist = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "company Code does not exists! (", trim(p_cmpy_code), ")"
		END IF
	END IF
	
	RETURN l_ret_exist
END FUNCTION
###########################################################################
# END FUNCTION db_company_pk_exists(p_ui,p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION db_company_get_rec(p_ui_mode,p_cmpy_code)
#
#
###########################################################################
FUNCTION db_company_get_rec(p_ui_mode,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_rec_company RECORD LIKE company.*

	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty BIC code"
		END IF
		RETURN NULL
	END IF
	
  SELECT *
    INTO l_rec_company.*
    FROM company
   WHERE cmpy_code = p_cmpy_code
	
	IF sqlca.sqlcode != 0 THEN   	
		INITIALIZE l_rec_company.* TO NULL
	END IF
	
	RETURN l_rec_company.*
END FUNCTION	
###########################################################################
# END FUNCTION db_company_get_rec(p_ui_mode,p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION db_company_get_name_text(p_ui_mode,p_cmpy_code)
# RETURN l_ret_name_text
#
# Get company name of company record
###########################################################################
FUNCTION db_company_get_name_text(p_ui_mode,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_ret_name_text LIKE company.name_text

	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Company Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT name_text
	INTO l_ret_name_text
	FROM company 
	WHERE company.cmpy_code = p_cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Company Description with Code ",trim(p_cmpy_code),  "NOT found"
		END IF
		LET l_ret_name_text = NULL
	END IF	

	RETURN l_ret_name_text
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_name_text(p_ui_mode,p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION db_company_get_country_code(p_ui_mode,p_cmpy_code)
# RETURN l_ret_name_text
#
# Get company name of company record
###########################################################################
FUNCTION db_company_get_country_code(p_ui_mode,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_ret_country_code LIKE company.country_code

	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Company Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT country_code
	INTO l_ret_country_code
	FROM company 
	WHERE company.cmpy_code = p_cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Company Country Code for companyCode ",trim(p_cmpy_code),  "NOT found"
		END IF
		LET l_ret_country_code = NULL
	END IF	
	
	RETURN l_ret_country_code	                                                                                                
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_country_code(p_ui_mode,p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION db_company_get_currency_code(p_ui_mode,p_cmpy_code)
# RETURN l_ret_name_text
#
# Get company name of company record
###########################################################################
FUNCTION db_company_get_currency_code(p_ui_mode,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_ret_currency_code LIKE company.curr_code

	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Company Code can NOT be empty"
		END IF
		RETURN NULL
	END IF
	
	SELECT curr_code
	INTO l_ret_currency_code
	FROM company 
	WHERE company.cmpy_code = p_cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Company currency Code for companyCode ",trim(p_cmpy_code),  "NOT found"
		END IF
		LET l_ret_currency_code = NULL
	END IF	
	
	RETURN l_ret_currency_code	                                                                                                
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_currency_code(p_ui_mode,p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION get_company_info(p_cmpy_code)
# this function is used by most setup modules
# Gets common company information based on cmpy_code
###########################################################################
FUNCTION get_company_info(p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE recCount INT

	WHENEVER SQLERROR CONTINUE
	select company.name_text,
		company.country_code,
		country.country_text ,
		company.language_code,
		language.language_text
	INTO p_name_text,p_country_code,p_country_text,p_language_code,p_language_text 
	FROM company,
		country,
		language 
	WHERE company.cmpy_code = p_cmpy_code
		AND company.country_code = country.country_code
		AND company.language_code = language.language_code
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
###########################################################################
# END FUNCTION get_company_info(p_cmpy_code)
###########################################################################


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

###########################################################################
# FUNCTION db_company_get_arr_rec(p_query_type,p_query_or_where_text)
#
#
###########################################################################
FUNCTION db_company_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_company DYNAMIC ARRAY OF RECORD LIKE company.*		
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 	

#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM company ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY company.cmpy_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 				
	END CASE

	WHENEVER SQLERROR CONTINUE
	PREPARE s_company FROM l_query_text
	DECLARE c_company CURSOR FOR s_company


	LET l_idx = 1
	FOREACH c_company INTO l_arr_rec_company[l_idx].*    -- albo KD-1223
      LET l_idx = l_idx + 1
#      LET l_arr_rec_company[l_idx].cmpy_code = l_rec_company.cmpy_code
#      LET l_arr_rec_company[l_idx].desc_text = l_rec_company.desc_text
#      LET l_arr_rec_company[l_idx].post_code = l_rec_company.post_code
#      LET l_arr_rec_company[l_idx].bank_ref = l_rec_company.bank_ref
	END FOREACH
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN
		LET l_arr_rec_company = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_company		                                                                                                
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_arr_rec(p_query_type,p_query_or_where_text)
###########################################################################


###########################################################################
# FUNCTION db_company_get_arr_rec_c_n_c_t(p_query_type,p_query_or_where_text)
#
#
###########################################################################
FUNCTION db_company_get_arr_rec_c_n_c_t(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_company DYNAMIC ARRAY OF t_rec_company_c_n_c_t	
	DEFINE l_rec_company RECORD LIKE company.* #
	DEFINE l_idx SMALLINT
		
	IF p_query_or_where_text IS NULL THEN  #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM company ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY company.cmpy_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 				
	END CASE

	PREPARE s_company_short FROM l_query_text
	DECLARE c_company_short CURSOR FOR s_company_short

	LET l_idx = 0
	FOREACH c_company_short INTO l_rec_company.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_company[l_idx].cmpy_code = l_rec_company.cmpy_code
      LET l_arr_rec_company[l_idx].name_text = l_rec_company.name_text
      LET l_arr_rec_company[l_idx].city_text = l_rec_company.city_text
      LET l_arr_rec_company[l_idx].tele_text = l_rec_company.tele_text
	END FOREACH
	
	IF sqlca.sqlcode != 0 THEN   	
		LET l_arr_rec_company = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_company		                                                                                                
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_arr_rec_c_n_c_t(p_query_type,p_query_or_where_text)
###########################################################################


###########################################################################
# FUNCTION db_company_get_arr_c_n_c_c_t_t_a_c_m(p_query_type,p_query_or_where_text)
#
#
###########################################################################
FUNCTION db_company_get_arr_c_n_c_c_t_t_a_c_m(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_company DYNAMIC ARRAY OF t_rec_company_c_n_c_c_t_t_a_c_m	
	DEFINE l_rec_company RECORD LIKE company.* #
	DEFINE l_idx SMALLINT
	
	IF p_query_or_where_text IS NULL THEN  #save guard
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM company ",
				"WHERE ", l_where_text clipped," ",
				"ORDER BY company.cmpy_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM company ",
				"ORDER BY company.cmpy_code" 				
	END CASE

	WHENEVER SQLERROR CONTINUE
	PREPARE s2_company_short FROM l_query_text
	DECLARE c2_company_short CURSOR FOR s2_company_short

	LET l_idx = 0
	FOREACH c2_company_short INTO l_rec_company.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_company[l_idx].cmpy_code = l_rec_company.cmpy_code
      LET l_arr_rec_company[l_idx].name_text = l_rec_company.name_text
      LET l_arr_rec_company[l_idx].country_code = l_rec_company.country_code
      LET l_arr_rec_company[l_idx].city_text = l_rec_company.city_text
      LET l_arr_rec_company[l_idx].tele_text = l_rec_company.tele_text

      LET l_arr_rec_company[l_idx].tax_text = l_rec_company.tax_text
      LET l_arr_rec_company[l_idx].vat_code = l_rec_company.vat_code
      LET l_arr_rec_company[l_idx].curr_code = l_rec_company.curr_code
      LET l_arr_rec_company[l_idx].module_text = l_rec_company.module_text
      
	END FOREACH
	WHENEVER SQLERROR CONTINUE
	
	IF sqlca.sqlcode != 0 THEN   	
		LET l_arr_rec_company = NULL	                                                                                        
	END IF	         

	RETURN l_arr_rec_company		                                                                                                
END FUNCTION
###########################################################################
# END FUNCTION db_company_get_arr_c_n_c_c_t_t_a_c_m(p_query_type,p_query_or_where_text)
###########################################################################