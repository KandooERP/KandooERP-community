###########################################################################
# Module Scope Variables
###########################################################################
DEFINE ml_kandoo_info boolean 

###########################################################################
# FUNCTION getKandooInfo()
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION getkandooinfo() 
	RETURN ml_kandoo_info 
END FUNCTION 




###########################################################################
# FUNCTION setKandooInfo(argValue)
#
# Accessor Method for ml_demo
###########################################################################
FUNCTION setkandooinfo(argvalue) 
	DEFINE argvalue VARCHAR(4) 
	LET ml_kandoo_info = argvalue 
END FUNCTION 

