############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

############################################################
# FUNCTION init_p_ap()
#
# Initialise P/AP Module
############################################################
FUNCTION init_p_ap() 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_baseprogramid STRING 

	LET l_baseprogramid = getmoduleid() 

	IF l_baseprogramid != "PZP" THEN 
		LET l_cmpy_code = get_ku_cmpy_code() 

		SELECT * INTO glob_rec_apparms.* 
		FROM apparms 
		WHERE cmpy_code = l_cmpy_code 
		IF status = NOTFOUND THEN 
			#5116 Accounts Payable Parameters NOT SET up; Refer Menu PZP.
			#should it be error 5016 OR 5116 OR  #3510or #5002  ? I can see both in the code for the same check #3510 AP Parameters missing
			CALL fgl_winmessage("Accounts Payable Parameters",kandoomsg2("P",5016,""),"ERROR") 
			EXIT PROGRAM 
		END IF 

		SELECT * INTO glob_rec_glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 

		IF status = NOTFOUND THEN 
			CALL fgl_winmessage("GL-Parameters",kandoomsg2("U",5107,""),"ERROR") 
			#5107 General Ledger Parameters NOT SET up; Refer Menu GZP.
			EXIT PROGRAM 
		END IF 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION init_p_ap()
############################################################