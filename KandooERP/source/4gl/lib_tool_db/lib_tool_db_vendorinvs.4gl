########################################################################################################################
# TABLE vendorinvs
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

			
############################################################
# FUNCTION db_vendorinvs_pk_exists(p_ui_mode,p_op_mode,p_vouch_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_vendorinvs_pk_exists(p_ui_mode,p_op_mode,p_vouch_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT	
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE p_vouch_code LIKE vendorinvs.vouch_code

	DEFINE ret BOOLEAN
	DEFINE recCount INT
	DEFINE msgStr STRING

--	IF p_vend_code IS NULL THEN
--		IF p_ui_mode >= UI_ON THEN
--			ERROR "Vendor Invoice Code can not be empty"
--			#LET msgresp = kandoomsg("G",9178,"")
--			#9178 Bank/State/Branchs must NOT be NULL
--		END IF
--		RETURN FALSE
--	END IF

	IF p_vouch_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Vendor Voucher Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF


	
		SQL
			SELECT count(*) 
			INTO $recCount 
			FROM vendorinvs 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
--			AND vendorinvs.vend_code = $p_vend_code
			AND vendorinvs.vouch_code = $p_vouch_code    
		END SQL
	
		
	IF recCount > 0 THEN
		LET ret = TRUE	
		
		CASE p_op_mode
			WHEN MODE_INSERT
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Invoice (Voucher Code) already exists! (", trim(p_vend_code), ")"
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
						ERROR "Vendor Invoice (Voucher Code) does not exist! (", trim(p_vend_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE
			
			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						#No MESSAGE
					WHEN UI_FK
						ERROR "Vendor Invoice (Voucher Code) does not exist! (", trim(p_vend_code), ")"
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
						ERROR "Vendor Invoice (Voucher Code) does not exist! (", trim(p_vend_code), ")"
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_UPDATE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Invoice (Voucher Code) does not exist! (", trim(p_vend_code), ")"
					WHEN UI_FK
						#No MESSAGE
					OTHERWISE
						#No MESSAGE
				END CASE

			WHEN MODE_DELETE
				CASE p_ui_mode
					WHEN UI_PK
						ERROR "Vendor Invoice (Voucher Code) does not exist! (", trim(p_vend_code), ")"
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
# FUNCTION db_vendorinvs_get_count()
#
# Return total number of rows in vendorinvs 
############################################################
FUNCTION db_vendorinvs_get_inv_text_is_used(p_ui_mode,p_vend_code,p_vouch_code,p_inv_text)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE p_vouch_code LIKE vendorinvs.vouch_code
	DEFINE p_inv_text LIKE vendorinvs.inv_text
	DEFINE l_ret_count SMALLINT
		
	IF p_vend_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Vendor Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF
		
	IF p_vouch_code IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Vendor Voucher Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL
		END IF
		RETURN FALSE
	END IF

	IF p_inv_text IS NULL THEN
		IF p_ui_mode >= UI_ON THEN
			ERROR "Vendor Invoice Code can not be empty"
			#LET msgresp = kandoomsg("G",9178,"")
			#9178 Bank/State/Branchs must NOT be NULL	
		END IF
		RETURN FALSE
	END IF

	
	SELECT count(*) INTO l_ret_count 
	FROM vendorinvs
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND vend_code = p_vend_code
	--	AND vouch_code != l_rec_voucher.vouch_code
		AND inv_text = p_inv_text
	

	RETURN l_ret_count	
END FUNCTION	
############################################################
# FUNCTION db_vendorinvs_get_count()
#
# Return total number of rows in vendorinvs 
############################################################
FUNCTION db_vendorinvs_get_count()
	DEFINE ret INT

	
		SQL
			SELECT count(*) 
			INTO $ret 
			FROM vendorinvs 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
		
		END SQL
	
			
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_vendorinvs_get_vendor_invoice_count(p_vend_code)
#
# Return total number of rows in vendorinvs for a vendor
############################################################
FUNCTION db_vendorinvs_get_vendor_invoice_count(p_vend_code)
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_ret INT

	
		SQL
			SELECT count(*) 
			INTO $l_ret 
			FROM vendorinvs 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND vendorinvs.vend_code = $p_vend_code
		
		END SQL
	
			
	RETURN l_ret
END FUNCTION


############################################################
# FUNCTION db_vendorinvs_get_rec(p_ui_mode,p_vend_code)
# RETURN l_rec_vendorinvs.*
# Get vendorinvs/Part record
############################################################
FUNCTION db_vendorinvs_get_rec(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_rec_vendorinvs RECORD LIKE vendorinvs.*

	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Vendor Invoice Code"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT *
			INTO $l_rec_vendorinvs.*
			FROM vendorinvs
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code		        
			AND vend_code = $p_vend_code
		END SQL         
	
	
	IF sqlca.sqlcode != 0 THEN   		  
		INITIALIZE l_rec_vendorinvs.* TO NULL                                                                                      
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_rec_vendorinvs.*		                                                                                                
END FUNCTION	


############################################################
# FUNCTION db_vendorinvs_get_inv_text(p_ui_mode,p_vend_code)
# RETURN l_ret_desc_text 
#
# Get description text of Vendor Invoice record
############################################################
FUNCTION db_vendorinvs_get_inv_text(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_ret_inv_text LIKE vendorinvs.inv_text

	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Vendor Invoice Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT inv_text 
			INTO $l_ret_inv_text
			FROM vendorinvs
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND vendorinvs.vend_code = $p_vend_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Invoice Text with Code ",trim(p_vend_code),  "NOT found"
		END IF			
		LET l_ret_inv_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_inv_text
END FUNCTION

############################################################
# FUNCTION db_vendorinvs_get_vouch_code(p_ui_mode,p_vend_code)
# RETURN l_ret_desc_text 
#
# Get vouch_code of Product/Part record
############################################################
FUNCTION db_vendorinvs_get_vouch_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_ret_vouch_code LIKE vendorinvs.vouch_code

	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT vouch_code 
			INTO $l_ret_vouch_code
			FROM vendorinvs 
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
			AND vendorinvs.vend_code = $p_vend_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Invoice Reference with Vendor Invoice Code ",trim(p_vend_code),  "NOT found"
		END IF
		LET l_ret_vouch_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_vouch_code	                                                                                                
END FUNCTION



{
############################################################
# FUNCTION db_vendorinvs_get_cat_code(p_ui_mode,p_vend_code)
# RETURN l_ret_desc_text 
#
# Get description text of Product/Part record
############################################################
FUNCTION db_vendorinvs_get_cat_code(p_ui_mode,p_vend_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_ret_cat_code LIKE vendorinvs.cat_code

	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Invoice Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	
		SQL
			SELECT cat_code 
			INTO $l_ret_cat_code
			FROM vendorinvs
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND vendorinvs.vend_code = $p_vend_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Vendor Invoice Code ",trim(p_vend_code),  "NOT found"
		END IF
		LET l_ret_cat_code = NULL
	ELSE
		#	                                                                                                
	END IF	

	RETURN l_ret_cat_code	                                                                                                
END FUNCTION
}
########################################################################################################################
# 
# Get Array record data from DB
#
########################################################################################################################

############################################################
# FUNCTION db_vendorinvs_get_arr_rec(p_query_text)
#
#
############################################################
FUNCTION db_vendorinvs_get_arr_rec(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_vendorinvs DYNAMIC ARRAY OF t_rec_vendorinvs	
	DEFINE l_rec_vendorinvs t_rec_vendorinvs
	DEFINE l_idx SMALLINT
	
	IF p_query_type = FILTER_QUERY_WHERE AND p_query_or_where_text IS NULL THEN
		LET p_query_or_where_text = " 1=1 "
	END IF
	
	#p_query_text is optional
	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date ",
				"FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY vend_code, inv_text " 	

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date ",
				"FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY vend_code, inv_text " 	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date ",
				"FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY vend_code, inv_text " 				
	END CASE

	PREPARE s_vendorinvs FROM l_query_text
	DECLARE c_vendorinvs CURSOR FOR s_vendorinvs


	LET l_idx = 1
	FOREACH c_vendorinvs INTO l_arr_rec_vendorinvs[l_idx].*
	
#		DISPLAY l_arr_rec_vendorinvs[l_idx].*
#		DISPLAY "-----------------------"
#		DISPLAY "vend_code=", l_arr_rec_vendorinvs[l_idx].vend_code
#		DISPLAY "inv_text=", l_arr_rec_vendorinvs[l_idx].inv_text
#		DISPLAY "vouch_code=", l_arr_rec_vendorinvs[l_idx].vouch_code
#		DISPLAY "entry_date=", l_arr_rec_vendorinvs[l_idx].entry_date
	
      LET l_idx = l_idx + 1
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_vendorinvs = NULL	                                                                                        
	ELSE		                                                                                                                    
				                                                                                                
	END IF	         

#	FOR l_idx = 1 TO l_arr_rec_vendorinvs.getLength()
#		DISPLAY l_arr_rec_vendorinvs[l_idx].*
#	END FOR

	RETURN l_arr_rec_vendorinvs		                                                                                                
END FUNCTION


############################################################
# FUNCTION db_vendorinvs_get_arr_rec_no_cmpy(p_query_type,p_query_or_where_text)
#
#
############################################################
FUNCTION db_vendorinvs_get_arr_rec_no_cmpy(p_query_type,p_query_or_where_text)
	DEFINE p_query_type SMALLINT
	DEFINE p_query_or_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_arr_rec_vendorinvs DYNAMIC ARRAY OF t_rec_vendorinvs	
	DEFINE l_rec_vendorinvs t_rec_vendorinvs
	DEFINE l_idx SMALLINT
	
	#p_query_text is optional
	IF p_query_or_where_text IS NULL THEN
		LET p_query_type = FILTER_QUERY_OFF
	END IF
#			vend_code LIKE vendorinvs.vend_code,
#			inv_text LIKE vendorinvs.inv_text,
#			vouch_code LIKE vendorinvs.vouch_code,
#			entry_date LIKE vendorinvs.entry_date

	CASE p_query_type
		WHEN FILTER_QUERY_OFF
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY vendorinvs.vend_code" 	


#		WHEN FILTER_QUERY_ON
#			LET l_query_text = p_query_or_where_text

		WHEN FILTER_QUERY_WHERE
			LET l_where_text = p_query_or_where_text
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"AND ", l_where_text clipped," ",
				"ORDER BY vend_code, inv_text "	

		WHEN FILTER_QUERY_SELECT
			LET l_query_text = p_query_or_where_text		
		
		OTHERWISE
			LET l_query_text = 
				"SELECT vend_code,inv_text,vouch_code,entry_date FROM vendorinvs ",
				"WHERE cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ",					
				"ORDER BY vend_code, inv_text "				
	END CASE

	PREPARE s2_vendorinvs FROM l_query_text
	DECLARE c2_vendorinvs CURSOR FOR s2_vendorinvs


	LET l_idx = 0
	FOREACH c2_vendorinvs INTO l_rec_vendorinvs.*
		LET l_idx = l_idx + 1
		LET l_arr_rec_vendorinvs[l_idx].* = "",l_rec_vendorinvs.*
	END FOREACH

	IF sqlca.sqlcode < 0 THEN   	
		LET l_arr_rec_vendorinvs = NULL	                                                                                        
	ELSE		                                                                                                                    
		#		                                                                                                
	END IF	         

	RETURN l_arr_rec_vendorinvs		                                                                                                
END FUNCTION





########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_vendorinvs_update(p_rec_vendorinvs)
#
#
############################################################
FUNCTION db_vendorinvs_update(p_ui_mode,p_pk_vend_code,p_rec_vendorinvs)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_vend_code LIKE vendorinvs.vend_code
	DEFINE p_rec_vendorinvs RECORD LIKE vendorinvs.*
	DEFINE l_ui_mode SMALLINT
	DEFINE ret INT
	DEFINE msgStr STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_vend_code IS NULL OR p_rec_vendorinvs.vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Vendor Invoice code can not be empty ! (original Vendor Invoice Code=",trim(p_pk_vend_code), " / new Vendor Invoice Code=", trim(p_rec_vendorinvs.vend_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 	
#	IF db_XXXXXXXX_get_vendorinvs_count(p_pk_vend_code) AND (p_pk_vend_code <> p_rec_vendorinvs.vend_code) THEN #PK vend_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change Vendor Invoice ! It is already used in a configuration"
#		END IF
#		LET ret =  -1
#	ELSE
		
			SQL
				UPDATE vendorinvs
				SET * = $p_rec_vendorinvs.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code					
				AND vend_code = $p_pk_vend_code
			END SQL
			LET ret = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not modify Vendor Invoice record ! /nOriginal Vendor Invoice", trim(p_pk_vend_code), "New vendorinvs/Part ", trim(p_rec_vendorinvs.vend_code),  "\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to modify/update Vendor Invoice record",msgStr,"error")
		ELSE
			LET msgStr = "Vendor Invoicet record ", trim(p_rec_vendorinvs.vend_code), " updated successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF	
	
	RETURN ret
END FUNCTION        

   
############################################################
# FUNCTION db_vendorinvs_insert(p_rec_vendorinvs)
#
#
############################################################
FUNCTION db_vendorinvs_insert(p_ui_mode,p_rec_vendorinvs)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_vendorinvs RECORD LIKE vendorinvs.*
	DEFINE ret INT
	DEFINE l_ui_mode SMALLINT
	DEFINE msgStr STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_vendorinvs.vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Vendor Invoice code can not be empty ! (Vendor Invoice=", trim(p_rec_vendorinvs.vend_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF

	LET p_rec_vendorinvs.cmpy_code = glob_rec_kandoouser.cmpy_code
	
	IF db_vendorinvs_pk_exists(UI_PK,MODE_INSERT,p_rec_vendorinvs.vend_code) THEN
		LET ret = -1
	ELSE
		
			INSERT INTO vendorinvs
	    VALUES(p_rec_vendorinvs.*)
	    LET ret = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Coud not create Vendor Invoice record ", trim(p_rec_vendorinvs.vend_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to create/insert Vendor Invoice record",msgStr,"error")
		ELSE
			LET msgStr = "PVendor Invoice record ", trim(p_rec_vendorinvs.vend_code), " created successfully !"   
			MESSAGE msgStr
		END IF                                           	
	END IF
	
	RETURN ret
END FUNCTION


############################################################
# 
# FUNCTION db_vendorinvs_delete(p_vend_code)
#
#
############################################################
FUNCTION db_vendorinvs_delete(p_ui_mode,p_confirm,p_vend_code)
	DEFINE p_ui_mode SMALLINT #hide or show error/warning messages
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode	
	DEFINE p_vend_code LIKE vendorinvs.vend_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE ret SMALLINT	
	DEFINE msgStr STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET msgStr = "Delete Vendor Invoice configuration ", trim(p_vend_code), " ?"
		IF NOT promptTF("Delete Vendor Invoice",msgStr,TRUE) THEN
			RETURN -2
		END IF
	END IF
	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET msgStr = "Vendor Invoice code can not be empty ! (Vendor Invoice=", trim(p_vend_code), ")"  
			ERROR msgStr
		END IF
		RETURN -1
	END IF
# Needs doing !!!!!!!!!! 
#	IF db_XXXXX_get_vendorinvs_count(p_vend_code) THEN #PK vend_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET msgStr = "Can not delete Product/Part ! ", trim(p_vend_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete Vendor Invoice ! ",msgStr,"error")
#		END IF
#		LET ret =  -1
#	ELSE
		

	DELETE FROM vendorinvs
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code					
	AND vend_code = p_vend_code

	LET ret = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF ret < 0 THEN   		
			LET msgStr = "Could not delete Vendor Invoice record ", trim(p_vend_code), " !\nDatabase Error ", trim(ret)                                                                                        
			#ERROR msgStr 
			CALL fgl_winmessage("Error when trying to delete",msgStr,"error")
		ELSE
			LET msgStr = "Vendor Invoice record ", trim(p_vend_code), " deleted !"   
			MESSAGE msgStr
		END IF                                           	
	END IF		             

	RETURN ret	
		  
END FUNCTION
	

############################################################
# 
# FUNCTION db_vendorinvs_delete(p_vend_code)
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
FUNCTION db_vendorinvs_rec_validation(p_ui_mode,p_op_mode,p_rec_vendorinvs)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_op_mode SMALLINT
	DEFINE p_rec_vendorinvs RECORD LIKE vendorinvs.*
	DEFINE l_ret SMALLINT
	DEFINE l_msgStr STRING
	DISPLAY "p_ui_mode=", p_ui_mode
	DISPLAY "p_op_mode=", p_op_mode
	CASE p_op_mode
		WHEN MODE_INSERT
			#vend_code PK
			LET l_msgStr = "Can not create record. TAP Code already exists"  
			IF db_vendorinvs_pk_exists(UI_PK,p_op_mode,p_rec_vendorinvs.vend_code) THEN
				RETURN -1 #PK Already exists
			END IF		

			#inv_text NOT NULL
			IF p_rec_vendorinvs.inv_text IS NULL THEN
				LET l_msgStr =  "Can not create Vendor Invoice record with empty description text - vend_code: ", trim(p_rec_vendorinvs.vend_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			##vouch_code ??? not sure, if this is a required field / FK
			#IF NOT db_voucher_pk_exists(UI_FK,p_op_mode,p_rec_vendorinvs.vouch_code) THEN
			#	LET l_msgStr =  "Can not create Vendor Invoice record with invalid Voucher Code: ", trim(p_rec_vendorinvs.vouch_code)
			#	IF p_ui_mode > 0 THEN
			#		ERROR l_msgStr
			#	END IF
			#	RETURN -3
			#END IF
				
		WHEN MODE_UPDATE
			#vend_code PK
			IF NOT db_vendorinvs_pk_exists(UI_PK,p_op_mode,p_rec_vendorinvs.vend_code) THEN
				LET l_msgStr = "Can not update record. TAP Code does not exist!"  			
				RETURN -1 #PK NOT FOUND
			END IF			

			#inv_text NOT NULL
			IF p_rec_vendorinvs.inv_text IS NULL THEN
				LET l_msgStr =  "Can not update Vendor Invoice record with empty description text - vend_code: ", trim(p_rec_vendorinvs.vend_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF				
				RETURN -2
			END IF

			##vouch_code ??? not sure, if this is a required field / FK
			#IF NOT db_voucher_pk_exists(UI_FK,p_op_mode,p_rec_vendorinvs.vouch_code) THEN
			#	LET l_msgStr =  "Can not update Vendor Invoice record with invalid Voucher Code: ", trim(p_rec_vendorinvs.vouch_code)
			#	IF p_ui_mode > 0 THEN
			#		ERROR l_msgStr
			#	END IF
			#	RETURN -3
			#END IF
							
		WHEN MODE_DELETE
			#vend_code PK
			IF db_vendorinvs_pk_exists(UI_PK,p_op_mode,p_rec_vendorinvs.vend_code) THEN
				LET l_msgStr =  "Can not delete Vendor Invoice record which does not exist - vend_code: ", trim(p_rec_vendorinvs.vend_code)
				IF p_ui_mode > 0 THEN
					ERROR l_msgStr
				END IF
				RETURN -1 #PK NOT FOUND
			END IF			
	
	
	END CASE

	RETURN TRUE
	
	
END FUNCTION	
	
