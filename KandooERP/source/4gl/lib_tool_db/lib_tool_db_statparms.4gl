########################################################################################################################
# TABLE statparms
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
			
############################################################
# FUNCTION db_statparms_pk_exists(p_ui,p_parm_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_statparms_pk_exists(p_ui_mode,p_op_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Statistic Code can not be empty"			#LET msgresp = kandoomsg("G",9178,"")	#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF
	
	SELECT count(*) 
	INTO recCount 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND statparms.parm_code = p_parm_code  
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Statistics Code already exists! (", trim(p_parm_code), ")"
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
						ERROR "Statistic Code does not exist! (", trim(p_parm_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Statistic Code does not exist! (", trim(p_parm_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
					
		END CASE
	ELSE
		LET ret = FALSE	
		CASE p_op_mode		
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Statistic Code does not exist! (", trim(p_parm_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Statistic Code does not exist! (", trim(p_parm_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Statistic Code does not exist! (", trim(p_parm_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE
		END CASE	
	END IF
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_statparms_get_count()
#
# Return total number of rows in statparms 
############################################################
FUNCTION db_statparms_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
			
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_statparms_get_rec_exists(p_parm_code)
#
# Return BOOLEAN TRUE/FALSE if this record exists 
############################################################
FUNCTION db_statparms_get_rec_exists(p_parm_code)
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_count INT
	DEFINE ret_exists BOOLEAN
	
	SELECT count(*) 
	INTO l_count 
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND statparms.parm_code = p_parm_code
	
	LET ret_exists = l_count 
	RETURN ret_exists
END FUNCTION


############################################################
# FUNCTION db_statparms_get_rec(p_ui_mode,p_parm_code)
# RETURN l_rec_statparms.*
# Get statparms record
############################################################
FUNCTION db_statparms_get_rec(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_rec_statparms RECORD LIKE statparms.*

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Product Adjustment Types Code"
		END IF
		RETURN NULL
	END IF

	SELECT *
	INTO l_rec_statparms.*
	FROM statparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = p_parm_code
	
	IF sqlca.sqlcode != 0 THEN 
		INITIALIZE l_rec_statparms.* TO NULL 
	ELSE 
		# 
	END IF 

	RETURN l_rec_statparms.* 
END FUNCTION	


############################################################
# FUNCTION db_statparms_get_year_num(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get description text of Statistic Parameter record
############################################################
FUNCTION db_statparms_get_year_num(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_year_num LIKE statparms.year_num

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
			RETURN NULL
	END IF
	
	SELECT year_num 
	INTO l_ret_year_num 
	FROM statparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				 
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Description with Code ",trim(p_parm_code),  "NOT found"
		END IF			
		LET l_ret_year_num = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_year_num
END FUNCTION

############################################################
# FUNCTION db_statparms_get_qtr_num(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get the qtr_num
############################################################
FUNCTION db_statparms_get_qtr_num(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_qtr_num LIKE statparms.qtr_num

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT qtr_num 
	INTO l_ret_qtr_num
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Reference with Company Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_qtr_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_qtr_num	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_statparms_get_mth_num(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get the mth_num
############################################################
FUNCTION db_statparms_get_mth_num(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_mth_num LIKE statparms.mth_num

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT mth_num 
	INTO l_ret_mth_num
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Reference with Company Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_mth_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_mth_num	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_statparms_get_week_num(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get the week_num
############################################################
FUNCTION db_statparms_get_week_num(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_week_num LIKE statparms.week_num

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT week_num 
	INTO l_ret_week_num
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Reference with Company Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_week_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_week_num	                                                                                                
END FUNCTION

############################################################
# FUNCTION db_statparms_get_day_num(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get the day_num
############################################################
FUNCTION db_statparms_get_day_num(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_day_num LIKE statparms.day_num

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT day_num 
	INTO l_ret_day_num
	FROM statparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code				
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Reference with Company Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_day_num = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_day_num	                                                                                                
END FUNCTION


############################################################
# FUNCTION db_statparms_get_parm_code(p_ui_mode,p_parm_code)
# RETURN l_ret_year_num 
#
# Get description text of statparms record
############################################################
FUNCTION db_statparms_get_parm_code(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_ret_parm_code LIKE statparms.parm_code

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	SELECT parm_code 
	INTO l_ret_parm_code
	FROM statparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND statparms.parm_code = p_parm_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Statistic Parameter Code ",trim(p_parm_code),  "NOT found"
		END IF
		LET l_ret_parm_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_parm_code	                                                                                                
END FUNCTION


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_statparms_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_statparms_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_statparms DYNAMIC ARRAY OF RECORD LIKE statparms.*		
	DEFINE l_rec_statparms RECORD LIKE statparms.*
	DEFINE l_idx SMALLINT

	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
		
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT * FROM statparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY statparms.parm_code" 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT * FROM statparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY statparms.parm_code" 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT * FROM statparms ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY statparms.parm_code" 				
	END CASE

	PREPARE s_statparms FROM l_query_text
	DECLARE c_statparms CURSOR FOR s_statparms


	LET l_idx = 0
	FOREACH c_statparms INTO l_arr_rec_statparms[l_idx].*
      LET l_idx = l_idx + 1

	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_statparms = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_statparms		                                                                                                
END FUNCTION


########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_statparms_update(p_rec_statparms)
#
#
############################################################
FUNCTION db_statparms_update(p_ui_mode,p_pk_parm_code,p_rec_statparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_parm_code LIKE statparms.parm_code
	DEFINE p_rec_statparms RECORD LIKE statparms.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_parm_code IS NULL OR p_rec_statparms.parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Statistic Parameter code can not be empty ! (original statistic Code=",trim(p_pk_parm_code), " / new statistic Code=", trim(p_rec_statparms.parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_statparms_count(p_pk_parm_code) AND (p_pk_parm_code <> p_rec_statparms.parm_code) THEN #PK parm_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Statistic Parameter ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE statparms
				SET * = $p_rec_statparms.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND parm_code = $p_pk_parm_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Statistic Parameter record ! /nOriginal statistic", trim(p_pk_parm_code), "New statparms ", trim(p_rec_statparms.parm_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Statistic Parameter record",msgStr,"error")
		ELSE
			LET msgStr = "Statistic Parametert record ", trim(p_rec_statparms.parm_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_statparms_insert(p_rec_statparms)
#
#
############################################################
FUNCTION db_statparms_insert(p_ui_mode,p_rec_statparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_statparms RECORD LIKE statparms.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_statparms.parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Statistic Parameter code can not be empty ! (statistic=", trim(p_rec_statparms.parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_statparms.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_statparms_pk_exists(UI_PK,MODE_SELECT,p_rec_statparms.parm_code) THEN
		LET ret = -1
	ELSE
		
	INSERT INTO statparms
  VALUES(p_rec_statparms.*)
  LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Statistic Parameter record ", trim(p_rec_statparms.parm_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Statistic Parameter record",msgStr,"error")
		ELSE
			LET msgStr = "Statistic Parameter record ", trim(p_rec_statparms.parm_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_statparms_delete(p_parm_code)
#
#
############################################################
FUNCTION db_statparms_delete(p_ui_mode,p_confirm,p_parm_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_parm_code LIKE statparms.parm_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Statistic Parameter configuration ", trim(p_parm_code), " ?"
		IF NOT promptTF("Delete statistic",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Statistic Parameter code can not be empty ! (statistic=", trim(p_parm_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_statparms_count(p_parm_code) THEN #PK parm_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product ! ", trim(p_parm_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete statistic ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
	SQL
		DELETE FROM statparms
		WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
		AND parm_code = $p_parm_code
	END SQL
	LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Statistic Parameter record ", trim(p_parm_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Statistic Parameter record ", trim(p_parm_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_statparms_delete(p_parm_code)
#
#
#	CONSTANT MODE_INSERT = 1
#	CONSTANT MODE_UPDATE = 2
#	CONSTANT MODE_DELETE = 3
#
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
#	CONSTANT UI_DEL SMALLINT = 4	
############################################################
FUNCTION db_statparms_rec_validation(p_ui_mode,p_op_mode,p_rec_statparms)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_statparms RECORD LIKE statparms.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#parm_code
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_statparms_pk_exists(UI_PK,p_op_mode,p_rec_statparms.parm_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#year_num
			IF p_rec_statparms.year_num IS NULL THEN
				LET l_msgStr =  "Can not create statistic record with empty description text - parm_code: ", trim(p_rec_statparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#qtr_num
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_statparms.qtr_num) THEN
				LET l_msgStr =  "Can not create statistic record with invalid COA Code: ", trim(p_rec_statparms.qtr_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
				
		WHEN MODE_UPDATE
			#parm_code
			IF NOT db_statparms_pk_exists(UI_PK,p_op_mode,p_rec_statparms.parm_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#year_num
			IF p_rec_statparms.year_num IS NULL THEN
				LET l_msgStr =  "Can not update statistic record with empty description text - parm_code: ", trim(p_rec_statparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			#qtr_num
			IF NOT db_coa_pk_exists(UI_FK,p_op_mode,p_rec_statparms.qtr_num) THEN
				LET l_msgStr =  "Can not update statistic record with invalid GL-COA Code: ", trim(p_rec_statparms.qtr_num)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -3
			END IF
							
		WHEN MODE_DELETE
			#parm_code
			IF db_statparms_pk_exists(UI_PK,p_op_mode,p_rec_statparms.parm_code) THEN
				LET l_msgStr =  "Can not delete statistic record which does not exist - parm_code: ", trim(p_rec_statparms.parm_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
