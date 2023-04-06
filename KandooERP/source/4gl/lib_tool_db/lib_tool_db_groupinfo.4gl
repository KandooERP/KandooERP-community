########################################################################################################################
# TABLE groupinfo
#
# 3 Column PK cmpy, group_code
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


############################################################
# FUNCTION db_groupinfo_get_count()
#
# Return total number of rows in groupinfo 
############################################################
FUNCTION db_groupinfo_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM groupinfo 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		
		
		END SQL
	
			
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_groupinfo_pk_exists(p_ui,p_group_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_groupinfo_pk_exists(p_ui,p_group_code)
	DEFINE p_ui SMALLINT
	DEFINE p_group_code LIKE groupinfo.group_code
	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

	IF p_group_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "groupinfo Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM groupinfo
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
			AND groupinfo.group_code = $p_group_code
		END SQL
	
		
	IF recCount <> 0 THEN
		LET ret = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "groupinfo Code exists! (", trim(p_group_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "groupinfo Code already exists! (", trim(p_group_code), ")"
		END IF
	ELSE
		LET ret = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "groupinfo Code does not exists! (", trim(p_group_code), ")"
		END IF
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_groupinfo_get_rec(p_ui_mode,p_group_code)
# RETURN l_rec_groupinfo.*	
# Get groupinfo record
############################################################
FUNCTION db_groupinfo_get_rec(p_ui_mode,p_group_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_group_code LIKE groupinfo.group_code
	DEFINE l_rec_groupinfo RECORD LIKE groupinfo.*


	IF p_group_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty groupinfo code"
		END IF
		RETURN NULL
	END IF


	
		SQL
	      SELECT *
	        INTO $l_rec_groupinfo.*
	        FROM groupinfo
					WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code			
	       AND group_code = $p_group_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   
		INITIALIZE l_rec_groupinfo.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_groupinfo.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_groupinfo_get_desc_text(p_ui_mode,p_group_code)
# RETURN l_ret_desc_text 
#
# Get description text of groupinfo record
############################################################
FUNCTION db_groupinfo_get_desc_text(p_ui_mode,p_group_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_group_code LIKE groupinfo.group_code
	DEFINE l_ret_desc_text LIKE groupinfo.desc_text


	IF p_group_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "groupinfo Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT desc_text 
			INTO $l_ret_desc_text 
			FROM groupinfo 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND groupinfo.group_code = $p_group_code
						  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "groupinfo Description with Code ",trim(p_group_code),  " NOT found"
		END IF			
		LET l_ret_desc_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_desc_text
END FUNCTION


########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_groupinfo_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_groupinfo_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_where_text VARCHAR(500)
	DEFINE l_arr_rec_groupinfo DYNAMIC ARRAY OF t_rec_groupinfo_no_cmpy_code	
#	DEFINE l_rec_groupinfo t_rec_groupinfo_i_d_t
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT group_code,desc_text FROM groupinfo ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY groupinfo.group_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT group_code,desc_text FROM groupinfo ",
				"WHERE ", l_where_text clipped," ",
				"AND cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 				
				"ORDER BY groupinfo.group_code" 	


		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT group_code,desc_text FROM groupinfo ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
				"ORDER BY groupinfo.group_code" 
				 				
	END CASE

	PREPARE s_groupinfo FROM l_query_text
	DECLARE c_groupinfo CURSOR FOR s_groupinfo


	LET l_idx = 1
	FOREACH c_groupinfo INTO l_arr_rec_groupinfo[l_idx].*
		LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_groupinfo = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_groupinfo		                                                                                                
END FUNCTION




########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_groupinfo_update(p_ui_mode,p_pk_group_code,p_rec_groupinfo)
#
#
############################################################
FUNCTION db_groupinfo_update(p_ui_mode,p_pk_group_code,p_rec_groupinfo)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_group_code LIKE groupinfo.group_code
	DEFINE p_rec_groupinfo RECORD LIKE groupinfo.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF


	IF p_pk_group_code IS NULL OR p_rec_groupinfo.group_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "groupinfo code can not be empty ! (original groupinfo=",trim(p_pk_group_code), " / new groupinfo=", trim(p_rec_groupinfo.group_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	IF p_rec_groupinfo.desc_text IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "groupinfo Description text code can not be empty ! "   
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_group_code) AND (p_pk_group_code <> p_rec_groupinfo.group_code) THEN #PK group_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change groupinfo ! It is already used in a bank configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE groupinfo
				SET * = $p_rec_groupinfo.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
				AND group_code = $p_pk_group_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify groupinfo record ! /nOriginal groupinfo", trim(p_pk_group_code), "New groupinfo ", trim(p_rec_groupinfo.group_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update groupinfo record",msgStr,"error")
		ELSE
			LET msgStr = "groupinfo record ", trim(p_rec_groupinfo.group_code),  " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_groupinfo_insert(p_rec_groupinfo)
#
#
############################################################
FUNCTION db_groupinfo_insert(p_ui_mode,p_rec_groupinfo)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_groupinfo RECORD LIKE groupinfo.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF


	IF p_rec_groupinfo.group_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "groupinfo code can not be empty ! (groupinfo=", trim(p_rec_groupinfo.group_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF


	IF p_rec_groupinfo.desc_text IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "groupinfo desc_text can not be empty ! (groupinfo desc_text=", trim(p_rec_groupinfo.desc_text), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF
	
	IF db_groupinfo_pk_exists(UI_PK,p_rec_groupinfo.group_code) THEN
		LET ret = -10
	ELSE
		
			INSERT INTO groupinfo
	    VALUES(p_rec_groupinfo.*)
	    
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create groupinfo record ", trim(p_rec_groupinfo.group_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert groupinfo record",msgStr,"error")
		ELSE
			LET msgStr = "groupinfo record ", trim(p_rec_groupinfo.group_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_groupinfo_delete(p_group_code)
#
#
############################################################
FUNCTION db_groupinfo_delete(p_ui_mode,p_group_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_group_code LIKE groupinfo.group_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete groupinfo configuration ", trim(p_group_code), " ?"
		IF NOT promptTF("Delete groupinfo",msgStr,TRUE) THEN
			RETURN -10
		END IF
	END IF
	
	IF p_group_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "groupinfo code can not be empty ! (groupinfo=", trim(p_group_code), ")"  
			ERROR msgStr
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_group_code) THEN #PK group_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete groupinfo ! ", trim(p_group_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete groupinfo ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				DELETE FROM groupinfo
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
				AND group_code = $p_group_code
			END SQL
			LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not delete groupinfo=", trim(p_group_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "groupinfo record ", trim(p_group_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	
