{
###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_authenticate_dialog SMALLINT  --authenticate = 1 OR 0
DEFINE ml_authenticate_dialog_set BOOLEAN --TRUE = variable INITIALIZEd/SET FALSE=NOT INITIALIZEd


###########################################################################
# FUNCTION get_authenticate_dialog()
#
# Accessor Method for ml_authenticate
###########################################################################
FUNCTION get_authenticate_dialog()

	IF ml_authenticate_dialog_set = FALSE THEN
		IF fgl_getenv("AUTHENTICATE_DIALOG")	 IS NULL THEN
			CALL set_authenticate_dialog(0)
		ELSE
			CALL set_authenticate_dialog(fgl_getenv("AUTHENTICATE_DIALOG"))
		END IF
	END IF

	RETURN ml_authenticate_dialog
END FUNCTION


###########################################################################
# FUNCTION set_authenticate_dialog_set()
#
# Accessor Method for ml_authenticate_dialog_set  = STATUS, if authenticate was SET
###########################################################################
FUNCTION set_authenticate_dialog_set()
		RETURN ml_authenticate_dialog_set
END FUNCTION


###########################################################################
# FUNCTION set_authenticate_dialog(p_authenticate)
#
# Accessor Method for ml_authenticate
###########################################################################
FUNCTION set_authenticate_dialog(p_authenticate)
	DEFINE p_authenticate SMALLINT

	IF p_authenticate = 0 OR p_authenticate = 1 THEN
		LET ml_authenticate_dialog = p_authenticate
		CALL fgl_setenv("AUTHENTICATE_DIALOG",ml_authenticate_dialog)
		LET ml_authenticate_dialog_set = TRUE
	END IF
END FUNCTION
}