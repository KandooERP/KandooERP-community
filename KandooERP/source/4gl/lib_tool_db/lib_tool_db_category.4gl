##############################################################################################
#TABLE category
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_category_get_count()
#
# Return total number of rows in vendorgrp FROM current company
############################################################
FUNCTION db_category_get_count()
	DEFINE ret INT
	WHENEVER SQLERROR CONTINUE 	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM category 
		WHERE category.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN ret
END FUNCTION


               
############################################################
# FUNCTION db_category_get_rec(p_cat_code)
#
#
############################################################
FUNCTION db_category_get_rec(p_ui_mode,p_cat_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cat_code LIKE category.cat_code

	DEFINE l_rec_category RECORD LIKE category.*

	IF p_cat_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty category code"
		END IF	

		RETURN NULL
	END IF 

	WHENEVER SQLERROR CONTINUE
	SQL
      SELECT *
        INTO $l_rec_category.*
        FROM category
       WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
       	AND cat_code= $p_cat_code
	END SQL         
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF sqlca.sqlcode != 0 THEN 
      ERROR "category with cat_code=", trim(p_cat_code), " NOT found"
		RETURN NULL
   ELSE
		RETURN l_rec_category.*		                                                                                                
	END IF	         
END FUNCTION	      

############################################################
# FUNCTION db_category_get_sale_acct_code(p_ui_mode,p_cat_code)
# RETURN l_ret_sale_acct_code 
#
# Get Sale GL-Account from Product Category
############################################################
FUNCTION db_category_get_sale_acct_code(p_ui_mode,p_cat_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE l_ret_sale_acct_code LIKE category.sale_acct_code

	IF p_cat_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Category Code (cat_code) can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQLERROR CONTINUE
		SQL
			SELECT sale_acct_code 
			INTO $l_ret_sale_acct_code
			FROM category
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND category.cat_code = $p_cat_code  		
		END SQL
	WHENEVER SQLERROR CONTINUE
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Category Code/Reference ",trim(p_cat_code),  "NOT found"
		END IF
		LET l_ret_sale_acct_code = NULL
	END IF	

	RETURN l_ret_sale_acct_code	                                                                                                
END FUNCTION



############################################################
# FUNCTION db_category_get_first_sale_acct_code(p_ui_mode)
# RETURN l_ret_sale_acct_code 
#
# Get FIRST/LOWEST Sale GL-Account from ALL Categories
############################################################
FUNCTION db_category_get_first_sale_acct_code(p_ui_mode)
	DEFINE p_ui_mode SMALLINT
	DEFINE l_ret_sale_acct_code LIKE category.sale_acct_code
	DEFINE l_query_statement STRING
	DEFINE l_error_code SMALLINT
	DEFINE l_msg STRING
--	DEFINE curs_category_first_sale_acct_code CURSOR
	DEFINE prep_category_first_sale_acct_code PREPARED
	
	LET l_query_statement = 
	"SELECT FIRST 1 sale_acct_code FROM category ",
    "WHERE cmpy_code = ? ",
    "AND sale_acct_code IS NOT NULL  ",
    "ORDER BY sale_acct_code DESC "
    
	CALL prep_category_first_sale_acct_code.prepare(l_query_statement)  RETURNING l_error_code
--	IF l_error_code != 0 THEN
--		ERROR "Could not retrieve lowest/first GL sales account from category"
--	END IF
	CALL prep_category_first_sale_acct_code.setParameters(trim(glob_rec_kandoouser.cmpy_code))
	CALL prep_category_first_sale_acct_code.setResults(l_ret_sale_acct_code)
	CALL prep_category_first_sale_acct_code.execute()
	CALL prep_category_first_sale_acct_code.free()
--	CALL prep_category_first_sale_acct_code.execute() RETURNING l_error_code
		
--	CALL curs_category_first_sale_acct_code.declare(l_query_text)
--	CALL curs_category_first_sale_acct_code.setParameters(glob_rec_kandoouser.cmpy_code)	
--	CALL curs_category_first_sale_acct_code.setResults(l_ret_sale_acct_code)
	
--	CALL curs_category_first_sale_acct_code.Open() RETURNING l_error_code
--	IF l_error_code != 0 THEN
--		LET l_msg = "Could not retrieve lowest/first GL sales account from category\nError Code:", trim(l_error_code) 
--		ERROR l_msg
--	END IF
	
--	CALL curs_category_first_sale_acct_code.fetchFirst() RETURNING l_error_code
--	IF l_error_code != 0 THEN
--		ERROR "Could not retrieve lowest/first GL sales account from category"
--	END IF
	
--	CALL curs_category_first_sale_acct_code.close()
--	CALL curs_category_first_sale_acct_code.free()		
--	IF l_error_code != 0 THEN
--		LET l_msg = "Could not retrieve lowest/first GL sales account from category\nError Code:", trim(l_error_code) 
--		ERROR l_msg
--	END IF


	RETURN l_ret_sale_acct_code	                                                                                                
END FUNCTION # db_category_get_first_sale_acct_code
         
############################################################
# FUNCTION category_get_full_record(p_cat_code)
#
#
############################################################
FUNCTION category_get_full_record(p_cat_code)
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE l_rec_category RECORD LIKE category.*

	WHENEVER SQLERROR CONTINUE
      SELECT *
        INTO l_rec_category.*
        FROM category
       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       	AND cat_code= p_cat_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN sqlca.sqlcode,l_rec_category.*		                                                                                                
END FUNCTION # category_get_full_record	      

FUNCTION check_prykey_exists_category(p_cmpy_code,p_cat_code)
	DEFINE p_cmpy_code LIKE category.cmpy_code
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM category
	WHERE cmpy_code = p_cmpy_code
	AND cat_code = p_cat_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_category()

# This function returns the category description
FUNCTION db_get_desc_category(p_cmpy_code,p_cat_code)
	DEFINE p_cmpy_code LIKE category.cmpy_code
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE l_category_desc LIKE category.desc_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_category_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_category_desc
	FROM category
	WHERE cmpy_code = p_cmpy_code
	AND cat_code = p_cat_code

	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_category_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_category_desc,0
	END IF
	
END FUNCTION # db_get_desc_category
