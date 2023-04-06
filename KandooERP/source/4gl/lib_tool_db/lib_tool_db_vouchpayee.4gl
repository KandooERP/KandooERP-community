##############################################################################################
#TABLE vouchpayee
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_vouchpayee_get_count()
#
#
############################################################
FUNCTION db_vouchpayee_get_count()
	DEFINE ret INT
	SQL
		SELECT count(*) INTO $ret FROM vouchpayee WHERE vouchpayee.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vouchpayee_pk_exists(p_vouch_code,p_vend_code)
#
#
############################################################
FUNCTION db_vouchpayee_pk_exists(p_vouch_code,p_vend_code)
	DEFINE p_vouch_code LIKE vouchpayee.vouch_code
	DEFINE p_vend_code LIKE vouchpayee.vend_code	
	DEFINE ret INT

	IF p_vouch_code IS NULL THEN
		RETURN -1
	END IF
			
	SQL
		SELECT count(*) INTO $ret FROM vouchpayee 
		WHERE vouchpayee.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vouchpayee.vouch_code = $p_vouch_code		
		AND vouchpayee.vend_code = $p_vend_code
	END SQL
	
	RETURN ret
END FUNCTION



############################################################
# FUNCTION db_vouchpayee_get_rec(p_vouch_code,p_vend_code)
#
#
############################################################
FUNCTION db_vouchpayee_get_rec(p_vouch_code,p_vend_code)
	DEFINE p_vouch_code LIKE vouchpayee.vouch_code
	DEFINE p_vend_code LIKE vouchpayee.vend_code
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.*

	IF p_vouch_code IS NULL THEN
		ERROR "Invalid voucher code ", trim(p_vouch_code), " in db_voucher_get_rec()"
		RETURN NULL
	END IF 
	IF p_vend_code IS NULL THEN
		ERROR "Invalid vendor code ", trim(p_vend_code), " in db_voucher_get_rec()"
		RETURN NULL
	END IF 

	SQL
      SELECT *
        INTO $l_rec_vouchpayee.*
        FROM vouchpayee
       WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code
       	AND vouchpayee.vouch_code= $p_vouch_code
        AND vouchpayee.vend_code = $p_vend_code
	END SQL         

	IF sqlca.sqlcode != 0 THEN 
      ERROR "Voucherpayee with vouch_code=", trim(p_vouch_code), " AND vend_code=", trim(p_vend_code), " NOT found"
		RETURN NULL
   ELSE
		RETURN l_rec_vouchpayee.*		                                                                                                
	END IF	         
END FUNCTION	





