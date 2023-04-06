##############################################################################################
#TABLE vendorhist
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

FUNCTION db_vendorhist_get_count()
	DEFINE ret INT
	SQL
		SELECT count(*) INTO $ret FROM vendorhist WHERE vendorhist.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	RETURN ret
END FUNCTION

FUNCTION db_vendorhist_get_vendor_count(p_vend_code)
	DEFINE p_vend_code LIKE vendorhist.vend_code
	
	DEFINE ret INT
	SQL
		SELECT count(*) INTO $ret FROM vendorhist WHERE vendorhist.cmpy_code = $glob_rec_kandoouser.cmpy_code AND vendorhist.vend_code = $p_vend_code
	END SQL
	RETURN ret
END FUNCTION
