############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS "../re/../re/N_RE_GLOBALS.4gl" 

############################################################
# FUNCTION init_n_re()
#
# Initialise Internal Requisition  Module
############################################################
FUNCTION init_n_re() 

	SELECT * INTO glob_rec_reqparms.* FRoM reqparms
		WHERE cmpy_code = glob_rec_company.cmpy_code
		AND key_code = "1"
        
	IF status = NOTFOUND THEN
   	CALL fgl_winmessage("Configuration ERROR",kandoomsg2("N",5014,""),"ERROR") #5014 Reqparms not set up - use NZP
		EXIT PROGRAM
	END IF
   
END FUNCTION 