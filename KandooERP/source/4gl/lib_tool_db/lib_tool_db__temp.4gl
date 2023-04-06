GLOBALS "../common/glob_GLOBALS.4gl"
########################################################################################################################
# 
# UPDATE INSERT DELETE row from DB
#
########################################################################################################################


############################################################
# FUNCTION db_voucher_update(p_rec_voucher)
#
#
############################################################
{
FUNCTION db_voucher_update(p_ui_mode,p_pk_vend_code,p_pk_vouch_code,p_rec_voucher)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_pk_vend_code LIKE voucher.vend_code
	DEFINE p_pk_vouch_code LIKE voucher.vouch_code
	DEFINE p_rec_voucher RECORD LIKE voucher.*
	DEFINE l_ui_mode SMALLINT
	DEFINE l_ret_status INT
	DEFINE l_msg_str STRING
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_pk_vend_code IS NULL OR p_rec_voucher.vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher vend_code code can not be empty ! (original vend_code=",trim(p_pk_vend_code), " / new vend_code=", trim(p_rec_voucher.vend_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -1
	END IF

	IF p_pk_vouch_code IS NULL OR p_rec_voucher.vouch_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher code can not be empty ! (original voucher=",trim(p_pk_vouch_code), " / new voucher=", trim(p_rec_voucher.vouch_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -2
	END IF
	
#	IF db_product_get_class_count(p_pk_vouch_code) AND (p_pk_vouch_code <> p_rec_voucher.vouch_code) THEN #PK vouch_code can only be changed if it's not used already
#		IF p_ui_mode > 0 THEN
#			ERROR "Can not change voucher ! It is already used in a bank configuration"
#		END IF
#		LET l_ret_status =  -1
#	ELSE
		
			SQL
				UPDATE voucher
				SET * = $p_rec_voucher.*
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				
				AND vend_code = $p_pk_vend_code
				AND vouch_code = $p_pk_vouch_code
			END SQL
			LET l_ret_status = status
		
#	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msg_str = "Coud not modify voucher record ! /nOriginal vend_code/vouch_code", trim(p_pk_vend_code), "/", trim(p_pk_vouch_code), "New vend_code/vouch_code ", trim(p_rec_voucher.vend_code), "/" , trim(p_rec_voucher.vouch_code),  "\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msg_str 
			CALL fgl_winmessage("Error when trying to modify/update voucher record",l_msg_str,"error")
		ELSE
			LET l_msg_str = "voucher record ", trim(p_rec_voucher.vouch_code), "/", trim(p_rec_voucher.vend_code),  " updated successfully !"   
			MESSAGE l_msg_str
		END IF                                           	
	END IF	
	
	RETURN l_ret_status
END FUNCTION        

   
############################################################
# FUNCTION db_voucher_insert(p_rec_voucher)
#
#
############################################################
FUNCTION db_voucher_insert(p_ui_mode,p_rec_voucher)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_rec_voucher RECORD LIKE voucher.*
	DEFINE l_ret_status INT
	DEFINE l_ui_mode SMALLINT
	DEFINE l_msg_str STRING	
	
	IF p_ui_mode = UI_ON THEN
		LET l_ui_mode = UI_PK
	END IF

	IF p_rec_voucher.vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher vend_code can not be empty ! (voucher vend_code=", trim(p_rec_voucher.vend_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -1
	END IF
	
	IF p_rec_voucher.vouch_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher code can not be empty ! (voucher=", trim(p_rec_voucher.vouch_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -2
	END IF
	
	IF db_voucher_pk_exists(UI_PK,p_rec_voucher.vend_code,p_rec_voucher.vouch_code) THEN
		LET l_ret_status = -1
	ELSE
		
			INSERT INTO voucher
	    VALUES(p_rec_voucher.*)
	    
	    LET l_ret_status = status
		
	END IF

	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msg_str = "Coud not create voucher record ", trim(p_rec_voucher.vouch_code),"/", trim(p_rec_voucher.vend_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msg_str 
			CALL fgl_winmessage("Error when trying to create/insert voucher record",l_msg_str,"error")
		ELSE
			LET l_msg_str = "voucher record ", trim(p_rec_voucher.vouch_code),"/", trim(p_rec_voucher.vend_code), " created successfully !"   
			MESSAGE l_msg_str
		END IF                                           	
	END IF
	
	RETURN l_ret_status
END FUNCTION


############################################################
# FUNCTION db_voucher_delete(p_ui_mode,p_confirm,p_vend_code,p_vouch_code)
#
#
############################################################
FUNCTION db_voucher_delete(p_ui_mode,p_confirm,p_vend_code,p_vouch_code)
	DEFINE p_ui_mode SMALLINT #with UI messages or silent
	DEFINE p_confirm BOOLEAN #is operator requested to confirm this operation / independent of ui mode
	DEFINE p_vend_code LIKE voucher.vend_code
	DEFINE p_vouch_code LIKE voucher.vouch_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_ret_status SMALLINT	
	DEFINE l_msg_str STRING

	IF p_confirm = UI_CONFIRM_ON THEN
		LET l_msg_str = "Delete voucher configuration ", trim(p_vend_code), "/", trim(p_vouch_code), " ?"
		IF NOT promptTF("Delete voucher",l_msg_str,TRUE) THEN
			RETURN -10
		END IF
	END IF

	
	IF p_vend_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher vend_code code can not be empty ! (vend_code/vouch_code=", trim(p_vend_code), "/", trim(p_vouch_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -1
	END IF

	
	IF p_vouch_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg_str = "voucher code can not be empty ! (voucher=", trim(p_vouch_code), ")"  
			ERROR l_msg_str
		END IF
		RETURN -2
	END IF

#	IF db_bank_get_class_count(p_vouch_code) THEN #PK vouch_code can only be deleted if it's not used already
#		IF p_ui_mode != UI_OFF THEN
#			LET l_msg_str = "Can not delete voucher ! ", trim(p_vouch_code), " It is already used in a bank configuration"
#			CALL fgl_winmessage("Can not delete voucher ! ",l_msg_str,"error")
#		END IF
#		LET l_ret_status =  -1
#	ELSE
		
			SQL
				DELETE FROM voucher
				WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
				AND vend_code = $p_vend_code
				AND vouch_code = $p_vouch_code
			END SQL
			LET l_ret_status = status
		
			
#	END IF
	
	IF p_ui_mode != UI_OFF THEN #display MESSAGE if ui is enabled
		IF l_ret_status < 0 THEN   		
			LET l_msg_str = "Coud not delete vend_code/vouch_code=", trim(p_vend_code), "/", trim(p_vouch_code), " !\nDatabase Error ", trim(l_ret_status)                                                                                        
			#ERROR l_msg_str 
			CALL fgl_winmessage("Error when trying to delete",l_msg_str,"error")
		ELSE
			LET l_msg_str = "voucher record ", trim(p_vend_code), "/", trim(p_vouch_code), " deleted !"   
			MESSAGE l_msg_str
		END IF                                           	
	END IF		             

	RETURN l_ret_status	
		  
END FUNCTION
	
}