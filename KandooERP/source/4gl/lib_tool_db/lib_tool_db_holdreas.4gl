
##############################################################################################
#TABLE holdreas
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_holdreas_get_count()
#
# Return total number of rows in holdreas FROM current company
############################################################
FUNCTION db_holdreas_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM holdreas 
		WHERE holdreas.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_holdreas_get_reason_text(p_ui_mode,p_hold_code)
# RETURN l_ret_reason_text 
#
# Get Hold Reason Text
############################################################
FUNCTION db_holdreas_get_reason_text(p_ui_mode,p_hold_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_hold_code LIKE holdreas.hold_code
	DEFINE l_ret_reason_text LIKE holdreas.reason_text
	DEFINE l_msg STRING
	
	IF p_hold_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN	
			ERROR "Sales Hold Reasons Code can NOT be empty"
		END IF
			RETURN NULL
	END IF

	
		SQL
			SELECT reason_text 
			INTO $l_ret_reason_text 
			FROM holdreas
			WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code				 
			AND holdreas.hold_code = $p_hold_code  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN
			LET l_msg = "Sales Hold Reasons Description with Code ",trim(p_hold_code),  " NOT found!" 		
			ERROR l_msg
		END IF			
		LET l_ret_reason_text = NULL
	ELSE
		#
	END IF	
	RETURN l_ret_reason_text
END FUNCTION