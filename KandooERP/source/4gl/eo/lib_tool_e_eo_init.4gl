############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl" 
GLOBALS "../eo/EZP_GLOBALS.4gl"

############################################################
# FUNCTION init_e_eo()
#
# Initialise Sales Order Processing Module
############################################################
FUNCTION init_e_eo() 
	DEFINE l_moduleid STRING
	 
	LET l_moduleid = getmoduleid()

	SELECT * INTO glob_rec_opparms.* 
	FROM opparms 
	WHERE opparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND opparms.key_num = "1" 

	IF SQLCA.SQLCODE = NOTFOUND THEN 
		IF l_moduleid != "EZP" THEN
			CALL fgl_winmessage("Configuration Error Accounts Receivable (#arparms)",kandoomsg2("U",5105,""),"ERROR") #5105 Order Entry Parameters NOT SET up; Refer Menu EZP.
			EXIT PROGRAM 
		END IF
	END IF

	#Statistic Parameter record
	CALL db_statparms_get_rec(UI_ON,"1") RETURNING glob_rec_statparms.*
	IF l_moduleid[1,2] != "EZ" THEN 
		IF NOT db_statparms_get_rec_exists("1") THEN
			CALL fgl_winmessage("ERROR",kandoomsg2("E",5004,""),"ERROR") #Missing record/configuration exits program except for configuration programs 
			EXIT PROGRAM 
		END IF 
	END IF

--	SELECT inv_ref1_text 
--	INTO glob_inv_ref1_text 
--	FROM arparms 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND parm_code = "1" 
	
END FUNCTION 
############################################################
# END FUNCTION init_e_eo()
############################################################