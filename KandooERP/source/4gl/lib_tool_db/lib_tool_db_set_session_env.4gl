--database kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 

--main
--call set_db_default_env_variables("informix","","","","")
--call set_db_default_context("informix","","","","")
--end main
# this function set the default values for the db_environment env variables
FUNCTION set_db_default_env_variables(l_db_vendor,l_module,l_domain,l_program,l_variable)
DEFINE l_db_vendor,l_module,l_domain,l_program STRING
DEFINE l_variable CHAR(32)
DEFINE l_default_value CHAR(32)
DEFINE set_statement STRING

LET l_variable = "OPTOFC"
LET l_default_value = "1"
LET set_statement = l_variable clipped,"=",l_default_value clipped
CALL fgl_putenv(set_statement)

LET l_variable = "FET_BUF_SIZE"
LET l_default_value = "65536"
LET set_statement = l_variable clipped,"=",l_default_value clipped
CALL fgl_putenv(set_statement)

END FUNCTION

# this function checks the db_environment table and set requested values as default values
FUNCTION set_db_default_context(l_db_vendor,l_module,l_domain,l_program,l_context)
DEFINE l_db_vendor,l_module,l_domain,l_program STRING
DEFINE l_context CHAR(32)
DEFINE l_default_value CHAR(32)
DEFINE set_statement STRING

LET l_context = "SET ISOLATION TO" 
LET l_default_value = "COMMITTED READ LAST COMMITTED"
LET set_statement = l_context clipped," ",l_default_value clipped
EXECUTE IMMEDIATE set_statement

LET l_context = "SET LOCK MODE TO " 
LET l_default_value = "WAIT 2"
LET set_statement = l_context clipped," ",l_default_value clipped
EXECUTE IMMEDIATE set_statement

if sqlca.sqlcode < 0 then
	error" BAddd"
END IF
END FUNCTION
