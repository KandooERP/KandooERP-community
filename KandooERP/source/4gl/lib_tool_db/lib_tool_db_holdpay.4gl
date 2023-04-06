########################################################################################################################
# TABLE holdpay
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_holdpay_get_count()
#
# Return total number of rows in holdpay FROM current company
############################################################
FUNCTION db_holdpay_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM holdpay 
		WHERE holdpay.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION

				
############################################################
# FUNCTION db_holdpay_pk_exists(p_hold_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_holdpay_pk_exists(p_hold_code)
	DEFINE p_hold_code LIKE holdpay.hold_code
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM holdpay 
		WHERE holdpay.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND holdpay.hold_code = $p_hold_code  		
	END SQL
	
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_holdpay_get_rec(p_hold_code)
#
# Return holdpay record matching PK hold_code
############################################################
FUNCTION db_holdpay_get_rec(p_hold_code)
	DEFINE p_hold_code LIKE holdpay.hold_code
	DEFINE l_ret_rec_holdpay RECORD LIKE holdpay.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_hold_code IS NULL THEN
		ERROR "Hold Payment Reason Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT * 
		INTO $l_ret_rec_holdpay 
		FROM holdpay 
		WHERE holdpay.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND holdpay.hold_code = $p_hold_code  		
	END SQL

	IF sqlca.sqlcode != 0 THEN 
		ERROR "Hold Payment Record with Code ",trim(p_hold_code),  "NOT found"
		ERROR kandoomsg2("P",9026,"")	#P9026 " Hold Code NOT found, try window"		
		INITIALIZE l_ret_rec_holdpay.* TO NULL	
		RETURN NULL
	ELSE
		RETURN l_ret_rec_holdpay.*		                                                                                                
	END IF	
END FUNCTION				

############################################################
# FUNCTION db_holdpay_get_hold_text(p_ui_mode,p_hold_code)
#
# Return holdpay hold_text
############################################################
FUNCTION db_holdpay_get_hold_text(p_ui_mode,p_hold_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_hold_code LIKE holdpay.hold_code
	DEFINE l_ret_hold_text LIKE holdpay.hold_text
	
	IF p_hold_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "holdpay Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
		SQL
			SELECT hold_text INTO $l_ret_hold_text 
			FROM holdpay 
			WHERE holdpay.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND holdpay.hold_code = $p_hold_code  		
		END SQL
		
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Payment holdpay NOT found"
		END IF
		LET l_ret_hold_text = NULL
	END IF
		
	RETURN l_ret_hold_text
END FUNCTION	
