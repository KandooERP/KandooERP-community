##############################################################################################
#TABLE prodgrp
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_prodgrp_get_count()
#
# Return total number of rows in prodgrp FROM current company
############################################################
FUNCTION db_prodgrp_get_count()
	DEFINE ret INT
	
		SELECT count(*) 
		INTO ret 
		FROM prodgrp 
		WHERE prodgrp.cmpy_code = glob_rec_kandoouser.cmpy_code		
	RETURN ret
END FUNCTION

# This function returns the prodgrp description
FUNCTION db_get_desc_prodgrp(p_cmpy_code,p_dept_code,p_maingrp_code,p_prodgrp_code)
	DEFINE p_cmpy_code LIKE prodgrp.cmpy_code
	DEFINE p_dept_code LIKE prodgrp.dept_code
    DEFINE p_maingrp_code LIKE prodgrp.maingrp_code
    DEFINE p_prodgrp_code LIKE prodgrp.prodgrp_code
	DEFINE l_prodgrp_desc LIKE prodgrp.desc_text
	DEFINE l_set_isolation_mode PREPARED
	LET l_prodgrp_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_prodgrp_desc
	FROM prodgrp
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code
    AND maingrp_code = p_maingrp_code
    AND prodgrp_code = p_prodgrp_code

	IF sqlca.sqlcode = 0 THEN
        CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_prodgrp_desc,1
	ELSE
        CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_prodgrp_desc,0
	END IF
	
END FUNCTION # db_get_desc_prodgrp

FUNCTION check_prykey_exists_prodgrp(p_cmpy_code,p_dept_code,p_maingrp_code,p_prodgrp_code)
	DEFINE p_cmpy_code LIKE prodgrp.cmpy_code
	DEFINE p_dept_code LIKE prodgrp.dept_code
    DEFINE p_maingrp_code LIKE prodgrp.maingrp_code
    DEFINE p_prodgrp_code LIKE prodgrp.prodgrp_code

	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM prodgrp
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code
    AND maingrp_code = p_maingrp_code
    AND prodgrp_code = p_prodgrp_code

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_prodgrp()
