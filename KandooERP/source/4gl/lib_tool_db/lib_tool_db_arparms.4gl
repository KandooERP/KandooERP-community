##############################################################################################
# TABLE arparms #Account Receivable Parameters/Configfuration
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_arparms_parm_code_exist(p_parm_code)
############################################################
FUNCTION db_arparms_parm_code_exist(p_parm_code)
	DEFINE p_parm_code LIKE arparms.parm_code
	DEFINE l_count SMALLINT
	
	SELECT count(*) INTO l_count 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = p_parm_code 

	IF l_count > 0 THEN
		RETURN TRUE
	ELSE
		RETURN FALSE
	END IF 	
END FUNCTION
############################################################
# END FUNCTION db_arparms_parm_code_exist(p_parm_code)
############################################################

############################################################
# FUNCTION db_arparms_get_rec(p_ui_mode,p_parm_code)
#
# Arguments: 
#		p_ui_mode     UI errow/warning messages BOOLEAN
# 	p_parm_code		Usually 1 (so far always 1)
#
# RETURN l_rec_arparms.*	  
############################################################
FUNCTION db_arparms_get_rec(p_ui_mode,p_parm_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_parm_code LIKE arparms.parm_code
	DEFINE l_rec_arparms RECORD LIKE arparms.*

	IF p_parm_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty Parameter Code Number (parm_code)"
		END IF
		RETURN NULL
	END IF
	
  SELECT *
    INTO l_rec_arparms.*
    FROM arparms
   WHERE parm_code = p_parm_code
     AND cmpy_code = glob_rec_kandoouser.cmpy_code

	IF sqlca.sqlcode != 0 THEN 
	
		IF p_ui_mode != UI_OFF THEN
			ERROR "Could not retrieve the Account Receivable parameter Record (arparms)"
      ERROR kandoomsg2("P",5007,"")     #P5007 " Parameters Not Found, See Menu GZP"
		END IF                                                                                      
		INITIALIZE l_rec_arparms.* TO NULL
	ELSE
		# all fine					                                                                                                
	END IF

	RETURN l_rec_arparms.*
END FUNCTION	
############################################################
# END FUNCTION db_arparms_get_rec(p_ui_mode,p_parm_code)
############################################################