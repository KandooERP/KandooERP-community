##################################################################################
# GLOBAL Scope Variables
##################################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

##################################################################################
# FUNCTION get_kandoooption_feature_state(p_module_code,p_feature_code)
# U1T System Tailoring - Allows the Kandoo company to set system defaults (feature_ind Enabled = Y Disabled = N 
# @Eric - Please add this to your frequent Check & To Do List
##################################################################################
FUNCTION get_kandoooption_feature_state(p_module_code,p_feature_code) 
	DEFINE p_module_code LIKE kandoooption.module_code 
	DEFINE p_feature_code LIKE kandoooption.feature_code 
	DEFINE l_ret_feature_ind LIKE kandoooption.feature_ind 
	DEFINE l_msg STRING

	#CALL fgl_winmessage("table kandoooption","tabale kandoooption is for some reason always empty!\nNeeds investigating","info")

	SELECT feature_ind INTO l_ret_feature_ind FROM kandoooption 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = p_module_code 
	AND feature_code = p_feature_code
	
	IF STATUS = NOTFOUND THEN
		LET l_msg = "KandooOption Module=", trim(p_module_code), " Feature=", trim(p_feature_code), " not found in Table KandooOptions!\nContact Support" 
		CALL fgl_winmessage("Internal DB Data Error",l_msg,"Error")
		LET l_ret_feature_ind = 'N'
	END IF
	
	LET l_ret_feature_ind = UPSHIFT(l_ret_feature_ind)
	
	RETURN l_ret_feature_ind 
END FUNCTION 
##################################################################################
# END FUNCTION get_kandoooption_feature_state(p_module_code,p_feature_code)
##################################################################################

{
GL
get_kandoooption_feature_state('GL','MS') 
get_kandoooption_feature_state("GL","GL")
get_kandoooption_feature_state("AR","PT") 
get_kandoooption_feature_state("AR","01") 
get_kandoooption_feature_state("AR","CN")

AP
get_kandoooption_feature_state("AP","VA")
get_kandoooption_feature_state('AP','VI')
get_kandoooption_feature_state("AP", "DA")
get_kandoooption_feature_state("AP","DO")
get_kandoooption_feature_state('AP','MS')
get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"SC")
get_kandoooption_feature_state("AP","PT")
get_kandoooption_feature_state('AP','CH')
get_kandoooption_feature_state('AP','VY')
AR
get_kandoooption_feature_state("AR","GI")
get_kandoooption_feature_state("AR","CN")
get_kandoooption_feature_state("AR","CP")
get_kandoooption_feature_state("AR","IS")
get_kandoooption_feature_state("AR","PT") 
get_kandoooption_feature_state("AR","01")
get_kandoooption_feature_state("AR","AC")
get_kandoooption_feature_state("AR",TRAN_TYPE_RECEIPT_CA)
get_kandoooption_feature_state("AR", "RO")
get_kandoooption_feature_state("WO","TA")


ACCESSED IN COMMON
get_kandoooption_feature_state("JM","W1")
get_kandoooption_feature_state("AR","AG") 
get_kandoooption_feature_state("AR",TRAN_TYPE_RECEIPT_CA)
get_kandoooption_feature_state("AR","PT")
get_kandoooption_feature_state("AR","DT")
get_kandoooption_feature_state("AR","CP")
get_kandoooption_feature_state("WO","TA")
get_kandoooption_feature_state('GL','FA')
get_kandoooption_feature_state('PU','PD')
get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"SC")
get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS")

}

----------------------------------------------------------------------------------
