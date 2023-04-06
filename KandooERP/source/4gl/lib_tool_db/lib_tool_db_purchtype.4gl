########################################################################################################################
# TABLE purchtype
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_purchtype_get_count()
#
# Return total number of rows in purchtype FROM current company
############################################################
FUNCTION db_purchtype_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM purchtype 
		WHERE purchtype.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_purchtype_pk_exists(p_purchtype_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_purchtype_pk_exists(p_purchtype_code)
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM purchtype 
		WHERE purchtype.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND purchtype.purchtype_code = $p_purchtype_code  		
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_purchtype_get_rec(p_purchtype_code)
#
#
############################################################
FUNCTION db_purchtype_get_rec(p_purchtype_code)
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code
	DEFINE l_rec_purchtype RECORD LIKE purchtype.*

	SQL
      SELECT *
        INTO $l_rec_purchtype.*
        FROM purchtype
       WHERE purchtype_code = $p_purchtype_code
         AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL         

	IF sqlca.sqlcode != 0 THEN   		                                                                                        
		RETURN -1	                                                                                              	
	ELSE		                                                                                                                    
		RETURN l_rec_purchtype.*		                                                                                                
	END IF	         
END FUNCTION	



########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_purchtype_update(p_rec_purchtype)
#
#
############################################################
FUNCTION db_purchtype_update(p_rec_purchtype)
	DEFINE p_rec_purchtype RECORD LIKE purchtype.*

	SQL
		UPDATE purchtype
		SET * = $p_rec_purchtype.*
		WHERE purchtype_code = $p_rec_purchtype.purchtype_code
		AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL

	RETURN sqlca.sqlcode
END FUNCTION        

   
############################################################
# FUNCTION db_purchtype_insert(p_rec_purchtype)
#
#
############################################################
FUNCTION db_purchtype_insert(p_rec_purchtype)
	DEFINE p_rec_purchtype RECORD LIKE purchtype.*

		INSERT INTO purchtype
    VALUES(p_rec_purchtype.*)

	RETURN sqlca.sqlcode
END FUNCTION


############################################################
# 
# FUNCTION db_purchtype_delete(p_purchtype_code)
#
#
############################################################

FUNCTION db_purchtype_delete(p_purchtype_code)
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_sql_stmt_status SMALLINT	

	SELECT unique(1) FROM purchhead
	 WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	   AND purchtype_code = p_purchtype_code
	IF sqlca.sqlcode = 0 THEN
	   LET l_msgresp = kandoomsg("P",9554,"")
	   #9553 Cannot delete P.O. type as its IS being used by ...
	END IF
	SELECT unique(1) FROM vendor
	 WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	   AND purchtype_code = p_purchtype_code
	IF sqlca.sqlcode = 0 THEN
	   LET l_msgresp = kandoomsg("P",9555,"")
	   #9553 Cannot delete P.O. type as its IS being used by Vendors.
	END IF
	
	SQL            
		DELETE FROM purchtype
		WHERE purchtype_code = $p_purchtype_code
		  AND cmpy_code = $glob_rec_kandoouser.cmpy_code     
	END SQL
	
	IF sqlca.sqlcode < 0 THEN   		                                                                                        
		LET l_sql_stmt_status = -1		                                                                                              	
	ELSE		                                                                                                                    
		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN l_sql_stmt_status	
		  
END FUNCTION	         

############################################################
# FUNCTION db_purchtype_validate_purchtype_code(p_purchtype_code,p_notNull)
#
#
############################################################
FUNCTION db_purchtype_validate_purchtype_code(p_purchtype_code,p_notNull,p_mode)
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append
	DEFINE ret BOOLEAN
	DEFINE l_msgresp LIKE language.yes_flag

	IF p_notNull THEN		
		IF p_purchtype_code IS NULL THEN
			LET l_msgresp = kandoomsg("R",9003,"")
			#9003 Purchase Order Type must be entered
			RETURN 1
		END IF
	END IF
	
	IF UPSHIFT(p_mode) <> "U" THEN 
		SELECT unique(1) FROM purchtype
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND purchtype_code = p_purchtype_code
		IF NOT(STATUS = NOTFOUND) THEN
			LET l_msgresp = kandoomsg("P",9553,"")
			#9553 Purchase Order Type already exists.
			RETURN 1
		END IF
	END IF	
	RETURN 0         
END FUNCTION         


############################################################
# FUNCTION db_purchtype_validate_desc_text(p_desc_text,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_purchtype_validate_desc_text(p_desc_text,p_notNull,p_mode)
	DEFINE p_desc_text LIKE purchtype.desc_text
	DEFINE p_notNull BOOLEAN	
	DEFINE p_mode CHAR  --U=Update A=Append	
	DEFINE l_msgresp LIKE language.yes_flag

	IF p_notNull THEN			
		IF p_desc_text IS NULL THEN
			LET l_msgresp = kandoomsg("R",9004,"")
			#9004  Description must be entered
			RETURN 1
		END IF
	END IF
	
	RETURN 0
END FUNCTION
