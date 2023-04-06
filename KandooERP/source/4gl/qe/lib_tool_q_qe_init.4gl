############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"  
GLOBALS "../qe/Q_QE_GLOBALS.4gl" 

############################################################
# FUNCTION init_q_qe()
#
# Initialise Quotation Module
############################################################
FUNCTION init_q_qe() 
	DEFINE l_msg STRING
	
	SELECT * INTO glob_rec_qpparms.* 
	FROM qpparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		LET l_msg = kandoomsg2("Q",5002,""), "\nExit Application" #5002 " Quotation Parameters are NOT found"
		CALL fgl_winmessage("Quotation Settings", l_msg,"ERROR")
		EXIT program 
	END IF 


END FUNCTION 
