###########################################################################
# MODULE SCOPE VARIABLES 
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION is_erp_module_installed(p_erp_module_id)
#
# RETURN BOOLEAN TRUE=installed FALSE=NOT installed
###########################################################################
FUNCTION is_erp_module_installed(p_erp_module_id)
	DEFINE p_erp_module_id NCHAR
	DEFINE l_module_text STRING # LIKE company.module_text
	DEFINE i SMALLINT

	#ABCDEFGHIJKLMNOPQRSTUVWXYZ	
	#12345678901234567890123456 #char(26)	up to 26 characters
	
	LET l_module_text = glob_rec_company.module_text
	#DISPLAY trim(l_module_text.getLength())
		
	LET i = 1
	WHILE i <  l_module_text.getLength()
		IF l_module_text[i] = p_erp_module_id THEN
			#DISPLAY p_erp_module_id CLIPPED, "=INSTALLED"
			RETURN TRUE
		END IF
		LET i = i + 1
	END WHILE
	#DISPLAY p_erp_module_id CLIPPED, "= NOT INSTALLED"
	RETURN FALSE	
END FUNCTION
###########################################################################
# END FUNCTION is_erp_module_installed(p_erp_module_id)
###########################################################################