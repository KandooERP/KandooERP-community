##############################################################################################
# TABLE arparmext #Account Receivable Parameters/Configuration Part 2
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION arparmext_get_record()
#
# new function arparmext_get_record
############################################################
FUNCTION arparmext_get_record()
	DEFINE l_rec_arparmext RECORD LIKE arparmext.*

	SELECT *
	INTO l_rec_arparmext.*
	FROM arparmext
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	
	RETURN l_rec_arparmext.*		                                                                                                
END FUNCTION # arparmext_get_record	      
############################################################
# END FUNCTION arparmext_get_record() 
############################################################