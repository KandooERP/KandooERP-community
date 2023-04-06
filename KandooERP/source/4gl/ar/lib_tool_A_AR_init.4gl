############################################################
# Table arparms
############################################################


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 

############################################################
# FUNCTION init_a_ar()
#
# Initialise A/AR Module
############################################################
FUNCTION init_a_ar() 

	#--------------------------------------------------------
	# GL/General Ledger Parameters (glparms)
	CALL glparms_init()
	
	#--------------------------------------------------------
	# AR/Account Receivable Parameters (arparms)
	CALL arparms_init() #located in ar\lib_tool_a_ar_init_arparms.4gl

	#--------------------------------------------------------
	# AR/Account Receivable Parameters EXT (arparmext)
	CALL arparmext_init()

	
END FUNCTION
############################################################
# END FUNCTION init_a_ar()
############################################################

############################################################
# FUNCTION glparms_init()
#
# GL/General Ledger Parameters (glparms)
############################################################
FUNCTION glparms_init()

	SELECT * INTO glob_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	IF sqlca.sqlcode = NOTFOUND THEN 
		CALL fgl_winmessage("#A5001 GL Parameters",kandoomsg2("A",5001,""),"ERROR") 	#A5001 GL Parameters are NOT found"
		EXIT PROGRAM 
	END IF

END FUNCTION
############################################################
# END FUNCTION glparms_init()
############################################################

############################################################
# FUNCTION arparmext_init()
#
# AR/Account Receivable Parameters EXT (arparmext)
############################################################
FUNCTION arparmext_init()
	DEFINE l_moduleid STRING
	 
	LET l_moduleid = get_module_id()
 
	SELECT * INTO glob_rec_arparmext.* 
	FROM arparmext 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = 100 THEN
		IF 
			(l_moduleid[1,3] != "AZP") AND   
			(l_moduleid[1,3] != "AZ1") AND   
			(l_moduleid[1,3] != "PZ1")
		
		THEN 
		
			CALL fgl_winmessage("AR Parameters Not Set Up arparmext_init()","#7005 AR Parameters Not Set Up;\nTable arparmext is empty!\nRun Program AZP.","ERROR") #7005 AR Parameters Not Set Up;  Refer Menu AZP. #kandoomsg2("A",7005,"")
			EXIT PROGRAM
		ELSE
			MESSAGE "Creating new Accounts Receivable Parameters"
		END IF 
	END IF
END FUNCTION
############################################################
# END FUNCTION arparmext_init()
############################################################

############################################################
# FUNCTION check_prykey_exists_arparms(p_cmpy_code,p_parm_code)
#
#
############################################################
FUNCTION check_prykey_exists_arparms(p_cmpy_code,p_parm_code)
	DEFINE p_cmpy_code LIKE arparms.cmpy_code
	DEFINE p_parm_code LIKE arparms.parm_code
	DEFINE prykey_exists BOOLEAN

	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM arparms
	WHERE cmpy_code = p_cmpy_code
	AND parm_code = p_parm_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_arparms()
############################################################
# END FUNCTION check_prykey_exists_arparms(p_cmpy_code,p_parm_code)
############################################################


############################################################
# FUNCTION arparms_get_record(p_parm_code)
#
# new function arparms_get_record
############################################################
FUNCTION arparms_get_record(p_parm_code)
	DEFINE p_parm_code LIKE arparms.parm_code
	DEFINE l_rec_arparms RECORD LIKE arparms.*

	SELECT *
	INTO l_rec_arparms.*
	FROM arparms
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND parm_code= p_parm_code
	
	RETURN l_rec_arparms.*		                                                                                                
END FUNCTION # arparms_get_record	      
############################################################
# FUNCTION arparms_get_record(p_parm_code)
############################################################


