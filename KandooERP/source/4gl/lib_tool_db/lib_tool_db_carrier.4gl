##############################################################################################
#TABLE carrier
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
# FUNCTION db_term_get_count()
#
# Return total number of rows in carrier FROM current company
############################################################
FUNCTION db_carrier_get_count()
	DEFINE ret INT
	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM carrier 
		WHERE carrier.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_carrier_pk_exists(p_carrier_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_carrier_pk_exists(p_carrier_code)
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE ret INT

	IF p_carrier_code IS NULL THEN
	RETURN -1
	END IF
			
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM carrier 
		WHERE carrier.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND carrier.carrier_code = $p_carrier_code		
	END SQL
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_carrier_is_used(p_carrier_code)
#
# Returns boolean if carrie (carrier_code) is used
############################################################
FUNCTION db_carrier_is_used(p_carrier_code)
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE ret BOOLEAN
	DEFINE msgresp LIKE language.yes_flag

		SELECT unique 1 FROM orderhead
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND carrier_code = p_carrier_code
		AND status_ind != "C"
		
		IF sqlca.sqlcode != 0 THEN
			LET msgresp = kandoomsg("E",7045,p_carrier_code)
			#7045 sales orders exits FOR this ORDER - deletion no
			LET ret = TRUE
		END IF

	RETURN ret
END FUNCTION
############################################################
# FUNCTION db_carrier_get_rec(p_carrier_code)
#
#
############################################################
FUNCTION db_carrier_get_rec(p_carrier_code)
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE l_rec_carrier RECORD LIKE carrier.*

	IF p_carrier_code IS NULL THEN
		ERROR "carrier Code can NOT be empty"
		RETURN NULL
	END IF
	
	SQL
      SELECT *
        INTO $l_rec_carrier.*
        FROM carrier
       WHERE carrier_code = $p_carrier_code
         AND cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL         

	IF sqlca.sqlcode != 0 THEN  
		ERROR "carrier with carrier Code ",trim(p_carrier_code),  "NOT found"
		RETURN NULL
	ELSE
		RETURN l_rec_carrier.*		                                                                                                
	END IF	         
END FUNCTION	



########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################


#################################################################################
# FUNCTION db_carrier_get_arr_rec(p_type_code)
#
# Get all detail rows for this term
#################################################################################
FUNCTION db_carrier_get_arr_rec()
	#DEFINE p_type_code LIKE carrier.type_code
	DEFINE idx SMALLINT
	DEFINE l_rec_carrier RECORD LIKE carrier.*
	DEFINE l_msg STRING

	DEFINE l_arr_rec_carrier DYNAMIC ARRAY OF RECORD LIKE carrier.*

	#IF p_type_code IS NULL THEN
	#	LET l_msg = "Invalid argument passed TO db_carrier_get_arr_rec()!\np_type_code=", trim(p_type_code), "\nContact Maia Support support@kandooerp.org"
	#	CALL fgl_winmessage("Internal error in db_carrier_get_arr_rec()", l_msg,"error")
	#END IF
					
   DECLARE ca_carrier CURSOR FOR
    SELECT * FROM carrier
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
     ORDER BY carrier_code asc


		LET idx = 0
		FOREACH ca_carrier INTO l_rec_carrier.*
			LET idx = idx + 1
			LET l_arr_rec_carrier[idx].* = l_rec_carrier.*
		END FOREACH   

	RETURN l_arr_rec_carrier    
END FUNCTION


############################################################
# FUNCTION db_carrier_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_carrier 
# Return carrier rec array
############################################################
FUNCTION db_carrier_get_arr_rec_vc_nt_ct(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_carrier OF t_rec_carrier_cd_na_cy
	DEFINE l_arr_rec_carrier DYNAMIC ARRAY OF t_rec_carrier_cd_na_cy	
	#DEFINE l_arr_rec_carrier DYNAMIC ARRAY OF
	#	RECORD
	#		carrier_code LIKE carrier.carrier_code,
	#		desc_text LIKE carrier.desc_text
	#	END RECORD
	DEFINE l_idx SMALLINT --loop control
	DEFINE l_msgresp LIKE language.yes_flag


  LET l_msgresp = kandoomsg("U",1002,"")
  #1002 " Searching database - please wait"

	LET l_query_text = "SELECT carrier_code, name_text, city_text FROM carrier ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			" ORDER BY ",
				"cmpy_code, carrier_code"  

	PREPARE s_carrier FROM l_query_text
	DECLARE c_carrier CURSOR FOR s_carrier


   LET l_idx = 0
   FOREACH c_carrier INTO l_rec_carrier.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_carrier[l_idx].carrier_code = l_rec_carrier.carrier_code
      LET l_arr_rec_carrier[l_idx].name_text = l_rec_carrier.name_text
      LET l_arr_rec_carrier[l_idx].city_text = l_rec_carrier.city_text
      
   END FOREACH

	RETURN l_arr_rec_carrier  
END FUNCTION	


########################################################################################################################
#
# Field Accessor
#
########################################################################################################################

############################################################
# FUNCTION getcarrierName(p_carrier_code)
#
# Return carrier name carrier.name_text
############################################################
FUNCTION getcarrierName(p_carrier_code)
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE l_vend_name LIKE carrier.name_text
	DEFINE l_cmpy_code LIKE company.cmpy_code
	
	LET l_cmpy_code = getCurrentUser_cmpy_code()

	IF p_carrier_code IS NOT NULL THEN
		SELECT name_text 
		INTO l_vend_name
		FROM carrier
		WHERE cmpy_code = l_cmpy_code
		AND carrier_code  = p_carrier_code
	END IF	
	
	RETURN l_vend_name
END FUNCTION


############################################################
# FUNCTION db_carrier_delete(p_carrier_code)
#
#
############################################################
FUNCTION db_carrier_delete(p_carrier_code)
	DEFINE p_carrier_code LIKE carriercost.carrier_code


	IF db_carrier_is_used(p_carrier_code) THEN
		ERROR "Can not delete carrier configuration as i is used"
		RETURN -1
	END IF

	DELETE FROM carriercost
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND carrier_code = p_carrier_code
	
	DELETE FROM carrier
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND carrier_code = p_carrier_code

	RETURN status
END FUNCTION


############################################################
# FUNCTION db_carrier_delete(p_carrier_code)
#
#
############################################################
FUNCTION db_carrier_insert(p_rec_carrier)
	DEFINE p_rec_carrier RECORD LIKE carrier.*
	DEFINE p_carrier_code LIKE carriercost.carrier_code


	IF db_carrier_pk_exists(p_rec_carrier.carrier_code) THEN
		ERROR "Carrier configuartion already exists!"
		RETURN -1
	ELSE
		INSERT INTO carrier VALUES(p_rec_carrier.*)
	END IF
	
	RETURN status
END FUNCTION

