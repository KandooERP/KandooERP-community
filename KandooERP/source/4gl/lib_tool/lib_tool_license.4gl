GLOBALS "../common/glob_GLOBALS.4gl" 

#GLOBALS
#	DEFINE pr_company RECORD LIKE company.*
#END GLOBALS
######################################################################

# WE NEED a global record for the user company (the company using KandooERP ) OR access functions

######################################################################
# FUNCTION get_module_licenced(arg_module_Code)
#
# pr_company IS a default global record storing Kandoo User Organisation Details
# it also stores, what Kandoo program groups (modules) should be available
# in pr_company.module_text
#
# This function returns, if a module (identified by a single CHAR)
# IS available/licensed for this company
######################################################################
#FUNCTION get_module_licenced(arg_module_Code)
#	DEFINE arg_module_Code CHAR
#	DEFINE i INT
#	DISPLAY pr_company.module_text[66]
#	FOR i = 1 TO 26  --pr_company.module_text.get_length()
#		IF pr_company.module_text[i] = arg_module_Code THEN
#			RETURN TRUE
#		END IF
#	END FOR
#
#	RETURN FALSE
#
#END FUNCTION