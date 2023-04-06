
##############################################################################################
#TABLE carriercost
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
############################################################
# FUNCTION db_term_get_count()
#
# Return total number of rows in carriercostcost FROM current company
############################################################
FUNCTION db_carriercost_get_count()
	DEFINE l_ret INT
	
	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM carriercost 
		WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	
	RETURN l_ret
END FUNCTION

############################################################
# FUNCTION db_carriercost_get_count_by_carrier(p_carrier_code)
#
# Return total number of rows in carriercostcost FROM current company
############################################################
FUNCTION db_carriercost_get_count_by_carrier(p_carrier_code)
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE l_ret INT
	
	SQL
		SELECT count(*) 
		INTO $l_ret 
		FROM carriercost 
		WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code
		AND carrier_code = $p_carrier_code
	END SQL
	
	RETURN l_ret
END FUNCTION

############################################################
# FUNCTION db_carriercost_pk_exists(p_carriercost_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_carriercost_pk_exists(p_ui_mode,p_op_mode,p_carrier_code,p_country_code,p_state_code,p_freight_ind) #carrier_code + state_code + country_code + freight_ind + cmpy_code
-------------------------------------
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
#FUNCTION db_carriercost_pk_exists(p_ui_mode,p_op_mode,p_adj_type_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
#	DEFINE p_adj_type_code LIKE prodadjtype.adj_type_code

	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_state_code LIKE carriercost.state_code
	DEFINE p_freight_ind LIKE carriercost.freight_ind
				
	DEFINE l_ret SMALLINT


#	DEFINE l_ret BOOLEAN
	DEFINE l_recCount INT
	DEFINE msgStr STRING

	IF p_carrier_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Carrier Code Code can not be empty/NULL"
		END IF
		RETURN -11
	END IF

	IF p_country_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Country Code Code can not be empty/NULL"
		END IF
		RETURN -12
	END IF

	IF p_state_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "State Code Code can not be empty/NULL"
		END IF
		RETURN -13
	END IF

	IF p_freight_ind IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Freight Code Code can not be empty/NULL"
		END IF
		RETURN -13
	END IF


	

		SQL
			SELECT count(*) 
			INTO $l_recCount 
			FROM carriercost 
			WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND carriercost.carrier_code = $p_carrier_code		
			AND carriercost.country_code = $p_country_code		
			AND carriercost.state_code = $p_state_code		
			AND carriercost.freight_ind = $p_freight_ind
	
		END SQL	
	
		
	IF l_recCount > 0 THEN #PK exists
		LET l_ret = 1
		#Messages depend on UI_MODE on/off and the operation mode insert, update, delete	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Carriercost Code already exists! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE				

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "Carriercost Code does not exist! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "Carriercost Code does not exist! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					OTHERWISE
						#No MESSAGE
				END CASE
				
			OTHERWISE #i.e. NULL
				CASE p_ui_mode
					WHEN UI_PK
						#ERROR "Carriercost Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						ERROR "Carriercost Code already exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE		
									
		END CASE
		
	ELSE #PK does not exist
	
		LET l_ret = 0	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						#ERROR "Carriercost Code does not exist! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Carriercost Code does not exist! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Carriercost Code does not exist! (", trim(p_carrier_code), "/",trim(p_country_code), "/",trim(p_state_code), "/",trim(p_freight_ind), "/", ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			OTHERWISE #i.e. NULL
				CASE p_ui_mode
					WHEN UI_PK
						#ERROR "Carriercost Code already exists! (", trim(p_country_code), ")"
					WHEN UI_FK
						ERROR "Carriercost Code does not exists! (", trim(p_country_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE		
								
		END CASE	
	END IF
	
	RETURN l_ret
END FUNCTION
--------------------------------------
############################################################
# FUNCTION db_carriercost_pk_exists(p_carriercost_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_carriercost_pk_exists_old(p_carrier_code,p_country_code,p_state_code,p_freight_ind) #carrier_code + state_code + country_code + freight_ind + cmpy_code
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_state_code LIKE carriercost.state_code
	DEFINE p_freight_ind LIKE carriercost.freight_ind
				
	DEFINE l_ret INT

	#IF p_carrier_code IS NULL OR p_country_code IS NULL OR p_freight_ind IS NULL IS NULL THEN
	#RETURN -1
	#END IF

	IF p_state_code IS NULL THEN
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM carriercost 
			WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND carriercost.carrier_code = $p_carrier_code		
			AND carriercost.country_code = $p_country_code		
			AND carriercost.state_code IS NULL		
			AND carriercost.freight_ind = $p_freight_ind
	
		END SQL
	
	ELSE
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM carriercost 
			WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND carriercost.carrier_code = $p_carrier_code		
			AND carriercost.country_code = $p_country_code		
			AND carriercost.state_code = $p_state_code		
			AND carriercost.freight_ind = $p_freight_ind
	
		END SQL	

	END IF			


	
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_carriercost_get_rec(p_carriercost_code)
#
#
############################################################
FUNCTION db_carriercost_get_rec(p_carrier_code,p_country_code,p_state_code,p_freight_ind)
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_state_code LIKE carriercost.state_code
	DEFINE p_freight_ind LIKE carriercost.freight_ind	
	DEFINE l_rec_carriercost RECORD LIKE carriercost.*

	IF NOT db_carriercost_pk_exists(UI_ON,MODE_UPDATE,p_carrier_code,p_country_code,p_state_code,p_freight_ind) THEN
	#IF p_carrier_code IS NULL OR p_country_code IS NULL OR p_freight_ind IS NULL THEN
	#	ERROR "carriercost Code can NOT be empty"
		RETURN NULL
	END IF
	
	IF p_state_code IS NULL THEN
		SQL
      SELECT *
        INTO $l_rec_carriercost.*
        FROM carriercost
       WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
       AND carrier_code = $p_carrier_code
       AND country_code = $p_country_code
       AND state_code IS NULL
       AND freight_ind = $p_freight_ind     
		END SQL         
	ELSE
		SQL
      SELECT *
        INTO $l_rec_carriercost.*
        FROM carriercost
       WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
       AND carrier_code = $p_carrier_code
       AND country_code = $p_country_code
       AND state_code = $p_state_code  
       AND freight_ind = $p_freight_ind     
		END SQL 	
	END IF

	IF sqlca.sqlcode != 0 THEN  
		ERROR "carriercost with Code ",trim(p_carrier_code),  "NOT found"
		RETURN NULL
	ELSE
		RETURN l_rec_carriercost.*		                                                                                                
	END IF	         
END FUNCTION	



########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################

{
#################################################################################
# FUNCTION db_carriercost_get_arr_rec(p_type_code)
#
# Get all detail rows for this term
#################################################################################
FUNCTION db_carriercost_get_arr_rec(p_where_text)
	DEFINE p_where_text VARCHAR(500)
	#DEFINE p_type_code LIKE carriercost.type_code
	DEFINE idx SMALLINT
	DEFINE l_rec_carriercost RECORD LIKE carriercost.*
	DEFINE l_msg STRING

	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF RECORD LIKE carriercost.*

	#IF p_type_code IS NULL THEN
	#	LET l_msg = "Invalid argument passed TO db_carriercost_get_arr_rec()!\np_type_code=", trim(p_type_code), "\nContact Maia Support support@kandooerp.org"
	#	CALL fgl_winmessage("Internal error in db_carriercost_get_arr_rec()", l_msg,"error")
	#END IF
					
   DECLARE ca_carriercost CURSOR FOR
    SELECT * FROM carriercost
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
     ORDER BY carrier_code,country_code, state_code asc


		LET idx = 0
		FOREACH ca_carriercost INTO l_rec_carriercost.*
			LET idx = idx + 1
			LET l_arr_rec_carriercost[idx].* = l_rec_carriercost.*
		END FOREACH   

	RETURN l_arr_rec_carriercost    
END FUNCTION

}
############################################################
# FUNCTION db_carriercost_get_arr_rec_by_carrier(p_where_text)
# RETURN l_arr_rec_tax 
# Return tax rec array
############################################################
FUNCTION db_carriercost_get_arr_rec_by_carrier(p_carrier_code,p_where_text)
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(1000)
	DEFINE l_rec_carriercost RECORD LIKE carriercost.*
	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF RECORD LIKE carriercost.*
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM carriercost ",
                        "WHERE carriercost.cmpy_code =\"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ",
                        "AND carriercost.carrier_code =\"",p_carrier_code CLIPPED                       


	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"country_code, state_code"
				
	PREPARE s2_tax FROM l_query_text
	DECLARE c2_tax CURSOR FOR s2_tax


   LET l_idx = 0
   FOREACH c2_tax INTO l_rec_carriercost.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_carriercost[l_idx].* = l_rec_carriercost.*
   END FOREACH

	FREE c2_tax
	
	RETURN l_arr_rec_carriercost  
END FUNCTION	


############################################################
# FUNCTION db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,p_where_text)
# RETURN l_arr_rec_tax 
# Return tax rec array
############################################################
FUNCTION db_carriercost_get_arr_rec_by_carrier_short(p_carrier_code,p_where_text)
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(1000)
	DEFINE l_rec_carriercost RECORD LIKE carriercost.*
	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF t_rec_carriercost_co_st_fi_fa
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM carriercost ",
                        "WHERE carriercost.cmpy_code =\"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ",
                        "AND carriercost.carrier_code =\"",p_carrier_code CLIPPED ,"\" "                      


	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			" ORDER BY ",
				"country_code, state_code"
				
	PREPARE s3_tax FROM l_query_text
	DECLARE c3_tax CURSOR FOR s3_tax


   LET l_idx = 0
   FOREACH c3_tax INTO l_rec_carriercost.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_carriercost[l_idx].country_code = l_rec_carriercost.country_code
      LET l_arr_rec_carriercost[l_idx].state_code = l_rec_carriercost.state_code
      LET l_arr_rec_carriercost[l_idx].freight_ind = l_rec_carriercost.freight_ind
      LET l_arr_rec_carriercost[l_idx].freight_amt = l_rec_carriercost.freight_amt                  
			
   END FOREACH

	
	RETURN l_arr_rec_carriercost  
END FUNCTION	




{
############################################################
# FUNCTION db_carriercost_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_carriercost 
# Return carriercost rec array
############################################################
FUNCTION db_carriercost_get_arr_rec_vc_nt_ct(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_carriercost OF t_rec_carriercost_cd_na_cy
	DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF t_rec_carriercost_cd_na_cy	
	#DEFINE l_arr_rec_carriercost DYNAMIC ARRAY OF
	#	RECORD
	#		carriercost_code LIKE carriercost.carriercost_code,
	#		desc_text LIKE carriercost.desc_text
	#	END RECORD
	DEFINE l_idx SMALLINT --loop control
	DEFINE l_msgresp LIKE language.yes_flag


  LET l_msgresp = kandoomsg("U",1002,"")
  #1002 " Searching database - please wait"

	LET l_query_text = "SELECT carriercost_code, name_text, city_text FROM carriercost ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"cmpy_code, carriercost_code"  

	PREPARE s_carriercost FROM l_query_text
	DECLARE c_carriercost CURSOR FOR s_carriercost


   LET l_idx = 0
   FOREACH c_carriercost INTO l_rec_carriercost.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_carriercost[l_idx].carriercost_code = l_rec_carriercost.carriercost_code
      LET l_arr_rec_carriercost[l_idx].name_text = l_rec_carriercost.name_text
      LET l_arr_rec_carriercost[l_idx].name_text = l_rec_carriercost.name_text
      
   END FOREACH

	RETURN l_arr_rec_carriercost  
END FUNCTION	
}

########################################################################################################################
#
# Field Accessor
#
########################################################################################################################

############################################################
# FUNCTION db_carriercost_get_freight_amt(p_carrier_code,p_country_code,p_state_code)
#
# Return freight_amt 
############################################################
FUNCTION db_carriercost_get_freight_amt(p_carrier_code,p_country_code,p_state_code,p_freight_ind)
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_state_code LIKE carriercost.state_code	
	DEFINE p_freight_ind LIKE carriercost.freight_ind	
	DEFINE l_freight_amt LIKE carriercost.freight_amt
	
	IF p_state_code IS NULL THEN
		SQL
			SELECT freight_amt 
			INTO $l_freight_amt
			FROM carriercost
			WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code
			AND carriercost.carrier_code  = $p_carrier_code
			AND carriercost.country_code  = $p_country_code
			AND carriercost.state_code  IS NULL
			AND carriercost.freight_ind  = $p_freight_ind
			
		END SQL
	ELSE
		SQL
			SELECT freight_amt 
			INTO $l_freight_amt
			FROM carriercost
			WHERE carriercost.cmpy_code = $glob_rec_kandoouser.cmpy_code
			AND carriercost.carrier_code  = $p_carrier_code
			AND carriercost.country_code  = $p_country_code
			AND carriercost.state_code  = $p_state_code
			AND carriercost.freight_ind  = $p_freight_ind			
		END SQL	
	END IF
		
	RETURN l_freight_amt
END FUNCTION




############################################################
# FUNCTION db_vendorgrp_insert(p_rec_vendorgrp)
#
#
############################################################
FUNCTION db_carriercost_insert(p_rec_carriercost)
	DEFINE p_rec_carriercost RECORD LIKE carriercost.*

#	IF db_carriercost_validate_record(p_rec_carriercost,MODE_INSERT) =>

	IF db_carriercost_pk_exists(UI_ON,MODE_INSERT,p_rec_carriercost.carrier_code,p_rec_carriercost.country_code,p_rec_carriercost.state_code,p_rec_carriercost.freight_ind) THEN
		RETURN -1
	END IF

	
		INSERT INTO carriercost
    VALUES(p_rec_carriercost.*)
	

	RETURN sqlca.sqlerrd[6]
END FUNCTION



############################################################
# FUNCTION db_term_update(p_rec_carriercost)
#
#
############################################################
FUNCTION db_carriercost_update(p_rec_carriercost)
	DEFINE p_rec_carriercost RECORD LIKE carriercost.*
	DEFINE l_msg STRING
	IF db_carriercost_pk_exists(
		UI_ON,
		MODE_UPDATE,
		p_rec_carriercost.carrier_code,
		p_rec_carriercost.country_code,
		p_rec_carriercost.state_code,
		p_rec_carriercost.freight_ind) < 1 THEN
			LET l_msg = "Record carriercost ", trim(p_rec_carriercost.carrier_code), " does NOT exist "
			ERROR l_msg
		RETURN -1
	ELSE 
	
		IF p_rec_carriercost.state_code IS NULL THEN
			SQL
				UPDATE carriercost
				SET * = $p_rec_carriercost.*
				WHERE cmpy_code = $p_rec_carriercost.cmpy_code
				AND carrier_code = $p_rec_carriercost.carrier_code
				AND country_code = $p_rec_carriercost.country_code
				AND state_code IS NULL
				AND freight_ind = $p_rec_carriercost.freight_ind						
			END SQL
			ELSE
			SQL
				UPDATE carriercost
				SET * = $p_rec_carriercost.*
				WHERE cmpy_code = $p_rec_carriercost.cmpy_code
				AND carrier_code = $p_rec_carriercost.carrier_code
				AND country_code = $p_rec_carriercost.country_code
				AND state_code = $p_rec_carriercost.state_code
				AND freight_ind = $p_rec_carriercost.freight_ind						
			END SQL		
		END IF
	END IF
	
	IF sqlca.sqlcode != 0 THEN
		ERROR "Carrier cost could not be updated", sqlca.sqlerrd[2] 
	ELSE
		MESSAGE "Carrier cost updated"
	END IF

	RETURN sqlca.sqlcode				
END FUNCTION


############################################################
# FUNCTION db_term_update(p_rec_carriercost)
#
#
############################################################
FUNCTION db_carriercost_delete(p_carrier_code,p_country_code,p_state_code,p_freight_ind)
	DEFINE p_carrier_code LIKE carriercost.carrier_code
	DEFINE p_country_code LIKE carriercost.country_code
	DEFINE p_state_code LIKE carriercost.state_code	
	DEFINE p_freight_ind LIKE carriercost.freight_ind	

	IF p_state_code IS NULL THEN
		DELETE FROM carriercost
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND carrier_code = p_carrier_code
		AND country_code = p_country_code
		AND state_code IS NULL
		AND freight_ind = p_freight_ind
	ELSE
		DELETE FROM carriercost
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND carrier_code = p_carrier_code
		AND country_code = p_country_code
		AND state_code = p_state_code
		AND freight_ind = p_freight_ind
	END IF

	RETURN status
END FUNCTION
         
         
         
         
         