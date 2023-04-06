########################################################################################################################
# TABLE batchhead
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_prodadjtype_get_count()
#
# Return total number of rows in prodadjtype 
############################################################
FUNCTION db_batchhead_get_count_post_flag_source_ind(p_post_flag,p_source_ind)
	DEFINE p_post_flag LIKE batchhead.post_flag
	DEFINE p_source_ind LIKE batchhead.source_ind
	DEFINE ret INT

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT count(*) 
	INTO ret 
	FROM batchhead
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND post_flag = p_post_flag
	AND source_ind = p_source_ind			
			
	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_prodadjtype_get_count()
############################################################