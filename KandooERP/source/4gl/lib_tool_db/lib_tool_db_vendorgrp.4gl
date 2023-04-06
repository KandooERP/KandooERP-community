##############################################################################################
#TABLE vendorgrp
#
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_vendorgrp_get_count()
#
# Return total number of rows in vendorgrp FROM current company
############################################################
FUNCTION db_vendorgrp_get_count()
	DEFINE ret INT
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM vendorgrp 
		WHERE vendorgrp.cmpy_code = $glob_rec_kandoouser.cmpy_code
	END SQL
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendorgrp_pk_exists(p_mast_vend_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_vendorgrp_pk_exists(p_mast_vend_code)
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code
	DEFINE ret INT
		
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM vendorgrp 
		WHERE vendorgrp.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendorgrp.mast_vend_code = $p_mast_vend_code		
	END SQL
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendorgrp_update_description(p_mast_vend_code,p_master_vendor_description)
#
# Update description
############################################################
FUNCTION db_vendorgrp_update_description(p_mast_vend_code,p_master_vendor_description)
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code
	DEFINE p_master_vendor_description LIKE vendorgrp.desc_text
	DEFINE ret INT
		
	SQL
		UPDATE vendorgrp SET desc_text = $p_master_vendor_description WHERE vendorgrp.cmpy_code = $glob_rec_kandoouser.cmpy_code AND vendorgrp.mast_vend_code = $p_mast_vend_code
	END SQL
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_vendorgrp_vendor_already_member(p_vend_code)
#
# Check, if this company is already a member of this vendor group
############################################################
FUNCTION db_vendorgrp_vendor_already_member(p_vend_code)
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE ret INT

	SQL
		SELECT count(*) INTO $ret FROM vendorgrp WHERE vendorgrp.cmpy_code = $glob_rec_kandoouser.cmpy_code AND vendorgrp.vend_code = $p_vend_code		
	END SQL
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_vendorgrp_get_cursorDistinctMasterVendorCode(p_where_text)
#
# RETURN CURSOR
############################################################
FUNCTION db_vendorgrp_get_cursorDistinctMasterVendorCode(p_where_text)
	DEFINE p_where_text VARCHAR(500)
	DEFINE l_query_text VARCHAR(1000)
	DEFINE l_pre_mast_vend_code PREPARED
	DEFINE l_cur_mast_vend_code CURSOR
	DEFINE retErr SMALLINT
	LET l_query_text =
		"SELECT distinct mast_vend_code FROM vendorgrp ",
		"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"' ",
		"AND ", p_where_text clipped," ",
		"ORDER BY mast_vend_code"

	CALL l_pre_mast_vend_code.PREPARE(l_query_text) RETURNING retErr
	DISPLAY retErr
	CALL l_cur_mast_vend_code.DECLARE(l_pre_mast_vend_code,0,1) RETURNING retErr
	DISPLAY retErr

	RETURN l_cur_mast_vend_code                  
	#PREPARE s_vendorgrp FROM l_query_text
	#DECLARE c_vendorgrp CURSOR FOR s_vendorgrp
END FUNCTION

##################################################################################################################################################################################################



############################################################
# FUNCTION db_vendorgrp_insert(p_rec_vendorgrp)
#
#
############################################################
FUNCTION db_vendorgrp_insert(p_rec_vendorgrp)
	DEFINE p_rec_vendorgrp RECORD LIKE vendorgrp.*
	
	
	
	
		INSERT INTO vendorgrp
    VALUES(p_rec_vendorgrp.*)
	
	RETURN sqlca.sqlerrd[6]
END FUNCTION
         
############################################################
# 
# FUNCTION db_vendorgrp_delete(p_mast_vend_code, p_vend_code)
#
#
############################################################
FUNCTION db_vendorgrp_delete(p_mast_vend_code, p_vend_code)
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code
	DEFINE p_vend_code LIKE vendorgrp.vend_code
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_sql_stmt_status SMALLINT	
	
	SQL            
		DELETE FROM vendorgrp 
		WHERE cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND mast_vend_code = $p_mast_vend_code
		AND vend_code = $p_vend_code
	END SQL
	
	IF sqlca.sqlcode < 0 THEN   		                                                                                        
		LET l_sql_stmt_status = -1		                                                                                              	
	ELSE		                                                                                                                    
		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN l_sql_stmt_status	
		  
END FUNCTION	         


# END TABLE vendorgrp #################################################################################################################################################################################################

