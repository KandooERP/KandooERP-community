##############################################################################################
#TABLE journal
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"


############################################################
# FUNCTION db_journal_get_count()
#
# Return total number of rows in journal FROM current company
############################################################
FUNCTION db_journal_get_count()
	DEFINE ret INT

	SELECT count(*) 
	INTO ret 
	FROM journal 
	WHERE journal.cmpy_code = glob_rec_kandoouser.cmpy_code		

	RETURN ret
END FUNCTION
############################################################
# END FUNCTION db_journal_get_count()
############################################################


############################################################
# FUNCTION journal_get_full_record(p_jour_code)
#
# get full record, no GUI involved
############################################################
FUNCTION journal_get_full_record(p_jour_code)
	DEFINE p_jour_code LIKE journal.jour_code
	DEFINE l_rec_journal RECORD LIKE journal.*

	SELECT *
	INTO l_rec_journal.*
	FROM journal
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND jour_code= p_jour_code

	RETURN sqlca.sqlcode,l_rec_journal.*	
END FUNCTION # category_get_full_record
############################################################
# FUNCTION journal_get_full_record(p_jour_code)
############################################################


############################################################
# FUNCTION db_get_desc_journal(p_jour_code)
#
#
############################################################
FUNCTION db_get_desc_journal(p_jour_code)
	DEFINE p_jour_code LIKE journal.jour_code
	DEFINE l_desc_text LIKE journal.desc_text

	SELECT desc_text
	INTO l_desc_text
	FROM journal
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND jour_code= p_jour_code
	
	RETURN sqlca.sqlcode,l_desc_text	
END FUNCTION # category_get_full_record
############################################################
# END FUNCTION db_get_desc_journal(p_jour_code)
############################################################



############################################################
# FUNCTION db_journal_pk_exists(p_cmpy_code,p_jour_code)
#
#
############################################################
FUNCTION db_journal_pk_exists(p_cmpy_code,p_jour_code)
	DEFINE p_cmpy_code LIKE journal.cmpy_code
	DEFINE p_jour_code LIKE journal.jour_code
	DEFINE l_ret_prykey_exists BOOLEAN

	# initialize prykey_exists to false. If key is found, it is set to 'true'
	LET l_ret_prykey_exists = FALSE
	
	SELECT TRUE
	INTO l_ret_prykey_exists
	FROM journal
	WHERE cmpy_code = p_cmpy_code
	AND jour_code = p_jour_code 

	RETURN l_ret_prykey_exists
END FUNCTION #db_journal_pk_exists()
############################################################
# END FUNCTION db_journal_pk_exists(p_cmpy_code,p_jour_code)
############################################################