##############################################################################################
#TABLE proddept
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_proddept_get_count()
#
# Return total number of rows in proddept FROM current company
############################################################
FUNCTION db_proddept_get_count()
	DEFINE ret INT
	
		SELECT count(*) 
		INTO ret 
		FROM proddept 
		WHERE proddept.cmpy_code = glob_rec_kandoouser.cmpy_code		
	RETURN ret
END FUNCTION

# This function returns the proddept description
FUNCTION db_get_desc_proddept(p_cmpy_code,p_dept_code)
	DEFINE p_cmpy_code LIKE proddept.cmpy_code
	DEFINE p_dept_code LIKE proddept.dept_code
	DEFINE l_proddept_desc LIKE proddept.desc_text
	DEFINE p_set_isolation_mode PREPARED
	LET l_proddept_desc = NULL

	SET ISOLATION TO DIRTY READ
	SELECT desc_text INTO l_proddept_desc
	FROM proddept
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code



	IF sqlca.sqlcode = 0 THEN
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_proddept_desc,1
	ELSE
		CALL reset_isolation_mode()	#  reset to default isolation mode
		RETURN l_proddept_desc,0
	END IF
	
END FUNCTION # db_get_desc_proddept

FUNCTION check_prykey_exists_proddept(p_cmpy_code,p_dept_code)
	DEFINE p_cmpy_code LIKE proddept.cmpy_code
	DEFINE p_dept_code LIKE proddept.dept_code
	DEFINE prykey_exists BOOLEAN
	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET prykey_exists = FALSE
	SELECT TRUE
	INTO prykey_exists
	FROM proddept
	WHERE cmpy_code = p_cmpy_code
	AND dept_code = p_dept_code

	RETURN prykey_exists
END FUNCTION #check_prykey_exists_product()
