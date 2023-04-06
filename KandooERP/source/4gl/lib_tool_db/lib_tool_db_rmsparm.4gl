##############################################################################################
#TABLE rmsparm
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_rmsparm_get_count()
#
# Return total number of rows in rmsparm from currently registered user
############################################################
FUNCTION db_rmsparm_get_count()
	DEFINE l_ret_count INT

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT count(*) 
			INTO $l_ret_count 
			FROM rmsparm 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			
	RETURN l_ret_count
END FUNCTION


############################################################
# FUNCTION db_rmsparm_get_count_all()
#
# Return total number of ALL rows in rmsparm 
############################################################
FUNCTION db_rmsparm_get_count_all()
	DEFINE l_ret_count INT

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT count(*) 
			INTO $l_ret_count 
			FROM rmsparm 
			#WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			
	RETURN l_ret_count
END FUNCTION


############################################################
# FUNCTION db_rmsparm_get_count_cmpy(p_cmpy_code)
#
# Return total number of rows in rmsparm from a particular company 
############################################################
FUNCTION db_rmsparm_get_count_cmpy(p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_ret_count INT

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT count(*) 
			INTO $l_ret_count 
			FROM rmsparm 
			WHERE cmpy_code = $p_cmpy_code			
		
		END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			
	RETURN l_ret_count
END FUNCTION


				