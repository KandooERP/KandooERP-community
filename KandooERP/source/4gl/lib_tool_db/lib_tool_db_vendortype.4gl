##############################################################################################
#TABLE vendortype
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_vendortype_get_count()
#
# Return total number of rows in vendortype FROM current company
############################################################
FUNCTION db_vendortype_get_count()
	DEFINE ret INT
	SQL
		SELECT count(*) INTO $ret FROM vendortype WHERE vendortype.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendortype_pk_exists(p_type_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_vendortype_pk_exists(p_type_code)
	DEFINE p_type_code LIKE vendortype.type_code
	DEFINE ret INT
			
	SELECT COUNT(*) INTO ret FROM vendortype 
	WHERE vendortype.cmpy_code = glob_rec_kandoouser.cmpy_code AND
			vendortype.type_code = p_type_code		
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_vendortype_get_rec(p_type_code)
#
# Return vendortype record matching PK type_code
############################################################
FUNCTION db_vendortype_get_rec(p_type_code)
	DEFINE p_type_code LIKE vendortype.type_code
	DEFINE l_ret_rec_vendortype RECORD LIKE vendortype.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_type_code IS NULL THEN
		ERROR "Vendor Type Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT * 
		INTO $l_ret_rec_vendortype 
		FROM vendortype 
		WHERE vendortype.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendortype.type_code = $p_type_code  		
	END SQL

	IF sqlca.sqlcode != 0 THEN 
		ERROR "Vendor Type Record with Code ",trim(p_type_code),  "NOT found"
		ERROR kandoomsg2("P",9026,"")	#P9026 " Hold Code NOT found, try window"		
		INITIALIZE l_ret_rec_vendortype.* TO NULL	
		RETURN NULL
	ELSE
		RETURN l_ret_rec_vendortype.*		                                                                                                
	END IF			
END FUNCTION		

############################################################
# FUNCTION db_vendortype_get_withhold_tax_ind(p_type_code)
# RETURN ret_withhold_tax_ind
#
# Get withhold_tax_ind FROM vendortype
############################################################
FUNCTION db_vendortype_get_withhold_tax_ind(p_type_code)
	DEFINE p_type_code LIKE vendortype.type_code
	DEFINE ret_withhold_tax_ind LIKE vendortype.withhold_tax_ind

	IF p_type_code IS NULL THEN
		RETURN NULL
	END IF
	
	SQL
		SELECT withhold_tax_ind 
		INTO $ret_withhold_tax_ind 
		FROM vendortype 
		WHERE vendortype.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendortype.type_code = $p_type_code		
	END SQL

	IF sqlca.sqlcode != 0 THEN
		ERROR "Vendor Type Record with Code ",trim(p_type_code),  "NOT found"
		RETURN NULL
	ELSE
		RETURN ret_withhold_tax_ind	                                                                                                
	END IF			
END FUNCTION


############################################################
# FUNCTION db_withhold_tax_ind_get_desc_text(p_withhold_tax_ind)
# RETURN ret_withhold_tax_ind label text (ret)
#
# Get withhold_tax_ind text label (does not exist in DB)
############################################################
FUNCTION db_withhold_tax_ind_get_desc_text(p_withhold_tax_ind)
	DEFINE p_withhold_tax_ind SMALLINT
	DEFINE ret STRING
	
	CASE p_withhold_tax_ind
		WHEN 0 
			LET ret = "Tax is NOT applicable" 
		WHEN 1 
			LET ret = "Round to 2 decimals"
		WHEN 2 				
			LET ret = "Rounded down to whole number"
		WHEN 3 			 
			LET ret = "Rounded up (no decimals)" 			
	END CASE

	RETURN ret
END FUNCTION



#################################################################################
# FUNCTION db_vendortype_get_arr_rec(p_type_code)
#
# Get all detail rows for this term
#################################################################################
FUNCTION db_vendortype_get_arr_rec()
	#DEFINE p_type_code LIKE vendortype.type_code
	DEFINE idx SMALLINT
	DEFINE l_rec_vendortype RECORD LIKE vendortype.*
	DEFINE l_msg STRING

	DEFINE l_arr_rec_vendortype DYNAMIC ARRAY OF
		RECORD
         type_code LIKE vendortype.type_code,
         type_text LIKE vendortype.type_text
		END RECORD

	#IF p_type_code IS NULL THEN
	#	LET l_msg = "Invalid argument passed TO db_vendortype_get_arr_rec()!\np_type_code=", trim(p_type_code), "\nContact Maia Support support@kandooerp.org"
	#	CALL fgl_winmessage("Internal error in db_vendortype_get_arr_rec()", l_msg,"error")
	#END IF
					
   DECLARE c_vendortype CURSOR FOR
    SELECT * FROM vendortype
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
      # AND type_code = p_type_code
     ORDER BY type_code asc
   #LET l_old_day_num = l_rec_term.due_day_num

		LET idx = 0
		FOREACH c_vendortype INTO l_rec_vendortype.*
			LET idx = idx + 1
			#LET l_arr_rec_vendortype[idx].scroll_flag = NULL
			LET l_arr_rec_vendortype[idx].type_code = l_rec_vendortype.type_code
			LET l_arr_rec_vendortype[idx].type_text = l_rec_vendortype.type_text
		END FOREACH   

	RETURN l_arr_rec_vendortype    
END FUNCTION



############################################################
# FUNCTION db_vendortype_update(p_rec_vendortype)
#
#
############################################################
FUNCTION db_vendortype_update(p_rec_vendortype)
	DEFINE p_rec_vendortype RECORD LIKE vendortype.*

	IF NOT db_vendortype_pk_exists(p_rec_vendortype.type_code) THEN #check if record PK already exists
		ERROR "Vendor Type ", trim(p_rec_vendortype.type_code), " does NOT exist "
		RETURN -1
	ELSE 

	
	BEGIN WORK	
		SQL
			UPDATE vendortype
			SET * = $p_rec_vendortype.*
			WHERE cmpy_code = $p_rec_vendortype.cmpy_code
			AND type_code = $p_rec_vendortype.type_code
		END SQL

	COMMIT WORK
			
		
	END IF
	RETURN STATUS
END FUNCTION    


#      UPDATE vendortype SET type_text = l_rec_vendorType.type_text,
#                            withhold_tax_ind = l_rec_vendorType.withhold_tax_ind,
#                            tax_vend_code = l_rec_vendorType.tax_vend_code,
#                            pay_acct_code = l_rec_vendorType.pay_acct_code,
#                            freight_acct_code = l_rec_vendorType.freight_acct_code,
#                            salestax_acct_code = l_rec_vendorType.salestax_acct_code,
#                            disc_acct_code = l_rec_vendorType.disc_acct_code,
#                            exch_acct_code = l_rec_vendorType.exch_acct_code
#       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
#         AND type_code = l_rec_vendorType.type_code
#      COMMIT WORK
#      
#   END IF



############################################################
# FUNCTION db_vendortype_insert(p_rec_vendortype)
#
#
############################################################
FUNCTION db_vendortype_insert(p_rec_vendortype)
	DEFINE p_rec_vendortype RECORD LIKE vendortype.*

	IF db_vendortype_validate(p_rec_vendortype.*,NULL) <> 0 THEN
		ERROR "Vendor Type ", trim(p_rec_vendortype.type_code), " has conflicting data "
		RETURN -1
	END IF
	
	IF db_vendortype_pk_exists(p_rec_vendortype.type_code) THEN #check if record PK already exists
		ERROR "Vendor Type ", trim(p_rec_vendortype.type_code), " already exists "
		RETURN -1
	END IF

	
	BEGIN WORK	 

	INSERT INTO vendortype
	VALUES(p_rec_vendortype.*)

	COMMIT WORK
	
	
	IF sqlca.sqlcode != 0 THEN
		CALL fgl_winmessage(sqlca.sqlerrd[6],"Could NOT INSERT new record","error")
	END IF

	RETURN STATUS
END FUNCTION



############################################################
# 
# FUNCTION db_vendortype_delete(p_rec_vendortype)
#
#
############################################################
FUNCTION db_vendortype_delete(p_type_code)
	DEFINE p_type_code LIKE vendortype.type_code
	DEFINE l_msgresp LIKE language.yes_flag	
	
	SQL            
		DELETE FROM vendortype
		WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
		  AND type_code = $p_type_code
	END SQL
	
	IF sqlca.sqlcode != 0 THEN
		ERROR "Could NOT delete vendor type ",  p_type_code  		                                                                                        
	END IF		                                                                                                                    
	                                                                                                     
	RETURN STATUS	  
END FUNCTION	         



############################################################
# FUNCTION db_vendortype_validate(p_rec_vendortype,p_mode)
#
# Validates the record data 
############################################################
FUNCTION db_vendortype_validate(p_rec_vendortype,p_mode)
	DEFINE p_rec_vendortype RECORD LIKE vendortype.*
	DEFINE p_mode CHAR
	#.... for later
	RETURN 0 
END FUNCTION


