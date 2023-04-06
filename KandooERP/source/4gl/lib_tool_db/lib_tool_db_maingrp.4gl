##############################################################################################
#TABLE maingrp
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_maingrp_get_count()
#
# Return total number of rows in maingrp FROM current company
############################################################
FUNCTION db_maingrp_get_count()
	DEFINE ret INT
	
		SELECT count(*) 
		INTO ret 
		FROM maingrp 
		WHERE maingrp.cmpy_code = glob_rec_kandoouser.cmpy_code		
	RETURN ret
END FUNCTION

# This function returns the maingrp description
FUNCTION db_get_desc_maingrp(p_cmpy_code,p_dept_code,p_maingrp_code)
	DEFINE p_cmpy_code LIKE maingrp.cmpy_code
	DEFINE p_dept_code LIKE maingrp.dept_code
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE l_maingrp_desc LIKE maingrp.desc_text
	LET l_maingrp_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_maingrp_desc
	FROM maingrp
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code
	AND maingrp_code = p_maingrp_code 

    
	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_maingrp_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_maingrp_desc,0
	END IF
	
END FUNCTION # db_get_desc_maingrp




#########################################################################
# FUNCTION db_get_desc_maingrp(p_cmpy_code,p_dept_code,p_maingrp_code)
#
# This function returns the maingrp description
#########################################################################
FUNCTION db_maingrp_get_dept_code(p_maingrp_code)
	DEFINE p_cmpy_code LIKE maingrp.cmpy_code
	DEFINE p_dept_code LIKE maingrp.dept_code
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE l_dept_code LIKE maingrp.desc_text

#     Original examle
#			SELECT dept_code INTO p_rec_creditdetl.proddept_code 
#			FROM maingrp 
#			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
#			AND maingrp_code = p_rec_creditdetl.maingrp_code 

	LET l_dept_code = NULL

	SET ISOLATION TO DIRTY READ
	SELECT dept_code INTO l_dept_code
	FROM maingrp
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND maingrp_code = p_maingrp_code 
    
	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_dept_code,TRUE
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_dept_code,FALSE
	END IF
	
END FUNCTION # db_get_desc_maingrp
#########################################################################
# END FUNCTION db_get_desc_maingrp(p_cmpy_code,p_dept_code,p_maingrp_code)
#########################################################################



FUNCTION check_prykey_exists_maingrp(p_cmpy_code,p_dept_code,p_maingrp_code)
	DEFINE p_cmpy_code LIKE maingrp.cmpy_code
	DEFINE p_dept_code LIKE maingrp.dept_code
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM maingrp
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code
	AND maingrp_code = p_maingrp_code 

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_maingrp()
