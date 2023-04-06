##############################################################################################
#TABLE printcodes
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_printcodes_get_count()
#
# Return total number of rows in vendorgrp FROM current company
############################################################
FUNCTION db_printcodes_get_count()
	DEFINE l_ret INT
	WHENEVER SQLERROR CONTINUE 	
	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM printcodes 
	END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN l_ret
END FUNCTION


               
############################################################
# FUNCTION db_printcodes_get_rec(p_print_code)
#
#
############################################################
FUNCTION db_printcodes_get_rec(p_ui_mode,p_print_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_print_code LIKE printcodes.print_code

	DEFINE l_rec_printcodes RECORD LIKE printcodes.*

	IF p_print_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty printcodes code"
		END IF	

		RETURN NULL
	END IF 

	WHENEVER SQLERROR CONTINUE
	SQL
      SELECT *
        INTO $l_rec_printcodes.*
        FROM printcodes
       WHERE print_code= $p_print_code
	END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN 
      ERROR "printcodes with print_code=", trim(p_print_code), " NOT found"
		RETURN NULL
   ELSE
		RETURN l_rec_printcodes.*		                                                                                                
	END IF	         
END FUNCTION	      

############################################################
# FUNCTION db_printcodes_get_device_ind(p_ui_mode,p_print_code)
# RETURN l_ret_device_ind 
#
# Get Sale GL-Account from printcodes 
############################################################
FUNCTION db_printcodes_get_device_ind(p_ui_mode,p_print_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_print_code LIKE printcodes.print_code
	DEFINE l_ret_device_ind LIKE printcodes.device_ind

	IF p_print_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Category Code (print_code) can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT device_ind 
			INTO $l_ret_device_ind
			FROM printcodes
			WHERE printcodes.print_code = $p_print_code  		
		END SQL
	WHENEVER SQLERROR CONTINUE
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Category Code/Reference ",trim(p_print_code),  "NOT found"
		END IF
		LET l_ret_device_ind = NULL
	END IF	

	RETURN l_ret_device_ind	                                                                                                
END FUNCTION


