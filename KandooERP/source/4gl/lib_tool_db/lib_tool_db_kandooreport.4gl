##############################################################################################
#TABLE kandooreport
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# NOTE: Table is usd by ALL companies (no cmpy_code)
# PK = report_code	nchar	10 AND language_code	nchar	3
############################################################


############################################################
# FUNCTION db_kandooreport_get_count()
#
# Return total number of rows in kandooreport
############################################################
FUNCTION db_kandooreport_get_count()
	DEFINE ret INT
	WHENEVER SQLERROR CONTINUE 	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM kandooreport
	END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_kandooreport_get_count_language()
#
# Return total number of rows in kandooreport with language.. 
############################################################
FUNCTION db_kandooreport_get_count_language(p_language_code)
	DEFINE p_language_code LIKE kandooreport.language_code
	
	DEFINE ret INT
	WHENEVER SQLERROR CONTINUE 	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM kandooreport 
		WHERE kandooreport.language_code = $p_language_code	
	END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN ret
END FUNCTION

FUNCTION db_kandooreport_template_exists(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_country_code LIKE company.country_code
	DEFINE p_language_code LIKE kandooreport.language_code
	DEFINE p_module_id LIKE kandooreport.menupath_text
	DEFINE p_report_code_module_id LIKE kandooreport.report_code
	DEFINE l_ret_exists INT

	LET l_ret_exists = 0
	
	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_exists()","Can not retrieve report template with empty cmpy_code","ERROR")
		END IF	
		RETURN l_ret_exists
	END IF

	IF p_country_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_exists()","Can not retrieve report template with empty country_code","ERROR")
		END IF	
		RETURN l_ret_exists
	END IF

	IF p_language_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_exists()","Can not retrieve report template with empty language_code","ERROR")
		END IF	
		RETURN l_ret_exists
	END IF

	IF p_module_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_exists()","Can not retrieve report template with empty module_id","ERROR")
		END IF	
		RETURN l_ret_exists
	END IF

	IF p_report_code_module_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_exists()","Can not retrieve report template with empty p_report_code_module_id","ERROR")
		END IF	
		RETURN l_ret_exists
	END IF


	SELECT count(*) 
	INTO l_ret_exists 
	FROM kandooreport 
	WHERE kandooreport.cmpy_code = p_cmpy_code
	AND kandooreport.report_code = p_report_code_module_id
	AND kandooreport.language_code = p_language_code
	AND kandooreport.country_code = p_country_code	
	AND kandooreport.menupath_text = p_module_id 
{
	
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler	
	SQL
		SELECT count(*) 
		INTO $l_ret_exists 
		FROM kandooreport 
		WHERE kandooreport.language_code = $p_language_code	
		#AND kandooreport.cmpy_code = $p_cmpy_code
		#AND kandooreport.country_code = $p_country_code
		AND kandooreport.menupath_text = $p_module_id  #legazy
		AND kandooreport.report_code = $p_report_code_module_id #legazy
			
	END SQL
}	
	RETURN l_ret_exists

END FUNCTION

############################################################
# FUNCTION db_kandooreport_template_get_rec(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id)
#
# Retrieves a report template located in kandooreport
############################################################
FUNCTION db_kandooreport_template_get_rec(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_country_code LIKE company.country_code
	DEFINE p_language_code LIKE kandooreport.language_code
	DEFINE p_module_id LIKE kandooreport.menupath_text
	DEFINE p_report_code_module_id LIKE kandooreport.report_code
	DEFINE l_ret_exists INT
	DEFINE l_rec_kandooreport RECORD LIKE kandooreport.*
	DEFINE l_msg STRING
	
	INITIALIZE l_rec_kandooreport.* TO NULL
	
	IF p_cmpy_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_get_rec()","Can not retrieve report template with empty cmpy_code","ERROR")
		END IF	
		RETURN l_rec_kandooreport.*
	END IF

	IF p_country_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_get_rec()","Can not retrieve report template with empty country_code","ERROR")
		END IF	
		RETURN l_rec_kandooreport.*
	END IF

	IF p_language_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_get_rec()","Can not retrieve report template with empty language_code","ERROR")
		END IF	
		RETURN l_rec_kandooreport.*
	END IF

	IF p_module_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_get_rec()","Can not retrieve report template with empty module_id","ERROR")
		END IF	
		RETURN l_rec_kandooreport.*
	END IF

	IF p_report_code_module_id IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			CALL fgl_winmessage("4GL ERROR - db_kandooreport_template_get_rec()","Can not retrieve report template with empty p_report_code_module_id","ERROR")
		END IF	
		RETURN l_rec_kandooreport.*
	END IF


	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler	
	SQL
		SELECT * 
		INTO $l_rec_kandooreport 
		FROM kandooreport 
		WHERE kandooreport.language_code = $p_language_code	
		AND kandooreport.cmpy_code = $p_cmpy_code
		AND kandooreport.country_code = $p_country_code
		AND kandooreport.menupath_text = $p_module_id  #legazy
		AND kandooreport.report_code = $p_report_code_module_id #legazy
			
	END SQL

	IF sqlca.sqlcode != 0 THEN 
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "kandooreport with ",
			"cmpy_code=", trim(p_cmpy_code),
			"country_code=", trim(p_country_code),
			"language_code=", trim(p_language_code),
			"module_id=", trim(p_module_id),
			"p_report_code_module_id=", trim(p_report_code_module_id), #report_code
			" NOT found"
			ERROR l_msg
		END IF
		
		INITIALIZE l_rec_kandooreport.* TO NULL
	END IF

	RETURN l_rec_kandooreport.*

END FUNCTION 

############################################################
# FUNCTION db_kandooreport_get_rec(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id)
#
# JUST a wrapper for compatiblity reasons
############################################################
FUNCTION db_kandooreport_get_rec(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_country_code LIKE company.country_code
	DEFINE p_language_code LIKE kandooreport.language_code
	DEFINE p_module_id LIKE kandooreport.menupath_text
	DEFINE p_report_code_module_id LIKE kandooreport.report_code
	DEFINE l_ret_exists INT
	DEFINE l_rec_kandooreport RECORD LIKE kandooreport.*

	INITIALIZE l_rec_kandooreport.* TO NULL

	CALL db_kandooreport_template_get_rec(p_ui_mode,p_cmpy_code,p_country_code,p_language_code,p_module_id,p_report_code_module_id) RETURNING l_rec_kandooreport.*

	RETURN l_rec_kandooreport.*
END FUNCTION 

############################################################
# FUNCTION db_kandooreport_get_header_text(p_ui_mode,p_report_code)
# RETURN l_ret_header_text 
#
# Get Sale GL-Account from Product kandooreport
############################################################
FUNCTION db_kandooreport_get_header_text(p_ui_mode,p_report_code,p_language_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE kandooreport.report_code
	DEFINE p_language_code LIKE kandooreport.language_code
	DEFINE l_ret_header_text LIKE kandooreport.header_text

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandooreport Code (report_code) can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT header_text 
			INTO $l_ret_header_text
			FROM kandooreport
			WHERE kandooreport.report_code = $p_report_code				 
			AND kandooreport.language_code = $p_language_code  		
		END SQL
	WHENEVER SQLERROR CONTINUE
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandooreport Code/Reference ",trim(p_report_code),  "NOT found"
		END IF
		LET l_ret_header_text = NULL
	END IF	

	RETURN l_ret_header_text	                                                                                                
END FUNCTION



############################################################
# FUNCTION db_kandooreport_get_exec_ind(p_ui_mode,p_report_code)
# RETURN l_ret_exec_ind 
#
# Get Sale GL-Account from Product kandooreport
############################################################
FUNCTION db_kandooreport_get_exec_ind(p_ui_mode,p_report_code,p_language_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE kandooreport.report_code
	DEFINE p_language_code LIKE kandooreport.language_code
	DEFINE l_ret_exec_ind LIKE kandooreport.exec_ind

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandooreport Code (report_code) can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT kandooreport.exec_ind INTO l_ret_exec_ind
	FROM kandooreport
	WHERE kandooreport.report_code = p_report_code	AND 
			kandooreport.language_code = p_language_code AND 
			kandooreport.country_code = glob_rec_kandoouser.country_code AND
			kandooreport.cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "kandooreport Code/Reference ",trim(p_report_code),  "NOT found"
		END IF
		LET l_ret_exec_ind = NULL
	END IF	

	RETURN l_ret_exec_ind	                                                                                                
END FUNCTION


