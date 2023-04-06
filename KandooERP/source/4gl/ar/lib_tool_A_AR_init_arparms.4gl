############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS
	DEFINE glob_rec_arparms RECORD LIKE arparms.*
END GLOBALS
	
############################################################
# FUNCTION arparms_init()
#
# AR/Account Receivable Parameters (arparms)
############################################################
FUNCTION arparms_init()
	DEFINE l_temp_text STRING
	DEFINE l_moduleid STRING
	 
	LET l_moduleid = get_module_id()
	
	SELECT * INTO glob_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = 100 THEN
		#Hardcoded list of programs which do not require AR setup validation / we need to come up with some better approach for this temp fix
		IF 
			(l_moduleid[1,3] != "AZP") AND   
			(l_moduleid[1,3] != "AZ1") AND   
			(l_moduleid[1,3] != "PZ1")
		
		THEN 
			CALL fgl_winmessage("AR Parameters Not Set Up -arparms_init()","#7005 AR Parameters Not Set Up;\nTable arparms is empty!\nRun Program AZP.","ERROR") #7005 AR Parameters Not Set Up;  Refer Menu AZP. #kandoomsg2("A",7005,"")
			EXIT PROGRAM
		ELSE
			MESSAGE "Creating new Accounts Receivable Parameters"
		END IF 
	ELSE 
		LET l_temp_text = glob_rec_arparms.inv_ref1_text clipped,"........." 
		LET glob_rec_arparms.inv_ref1_text = l_temp_text 
	END IF
	 
END FUNCTION
############################################################
# END FUNCTION arparms_init()
############################################################