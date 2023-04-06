##############################################################################################
#TABLE vendornote
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
############################################################
# FUNCTION db_term_get_count()
#
# Return total number of rows in vendornote FROM current company
############################################################
FUNCTION db_vendornote_get_count(p_vend_code)
	DEFINE p_vend_code LIKE vendornote.vend_code
	DEFINE ret INT
	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM vendornote 
		WHERE vendornote.cmpy_code = $glob_rec_kandoouser.cmpy_code
		AND vend_code = $p_vend_code
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendornote_pk_exists(p_vend_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_vendornote_pk_exists(p_vend_code,p_note_date) #FUNCTION db_vendornote_pk_exists(p_vend_code,p_note_date,p_note_num)
	DEFINE p_vend_code LIKE vendornote.vend_code
	DEFINE p_note_date LIKE vendornote.note_date
#	DEFINE p_note_num LIKE vendornote.note_num removed by Eric 17.09.2019
	
	DEFINE ret INT

	IF (p_vend_code OR p_note_date) IS NULL THEN #	IF (p_vend_code OR p_note_date OR p_note_num) IS NULL THEN
	RETURN -1
	END IF
			
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM vendornote 
		WHERE vendornote.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendornote.vend_code = $p_vend_code		
		AND vendornote.note_date = $p_note_date	
		#AND vendornote.note_num = $p_note_num #removed		
		
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_vendornote_get_rec(p_vend_code)
#
#
############################################################
FUNCTION db_vendornote_get_rec(p_vend_code,p_note_date) #FUNCTION db_vendornote_get_rec(p_vend_code,p_note_date,p_note_num)
	DEFINE p_vend_code LIKE vendornote.vend_code
	DEFINE p_note_date LIKE vendornote.note_date
#	DEFINE p_note_num LIKE vendornote.note_num #removed by Erice 17.09.2019
	DEFINE l_rec_vendornote RECORD LIKE vendornote.*

	IF p_vend_code IS NULL THEN
		ERROR "vendornote Code can NOT be empty"
		RETURN NULL
	END IF
	
	SQL
      SELECT *
        INTO $l_rec_vendornote.*
        FROM vendornote
		WHERE vendornote.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND vendornote.vend_code = $p_vend_code		
		AND vendornote.note_date = $p_note_date	
		AND vendornote.note_num = $p_note_num		
	END SQL         

	IF sqlca.sqlcode != 0 THEN 
		ERROR "vendornote with vend_code ",trim(p_vend_code),  "NOT found"
		RETURN NULL
	ELSE
		RETURN l_rec_vendornote.*		                                                                                                
	END IF	         
END FUNCTION	



########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################


############################################################
# FUNCTION db_vendornote_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_vendornote 
# Return vendornote rec array
############################################################
FUNCTION db_vendornote_get_arr_rec_vc_nt_ct(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_vendornote OF t_rec_vendornote_nd_nt
	DEFINE l_arr_rec_vendornote DYNAMIC ARRAY OF t_rec_vendornote_nd_nt	
	#DEFINE l_arr_rec_vendornote DYNAMIC ARRAY OF
	#	RECORD
	#		vendor_code LIKE vendornote.vendor_code,
	#		desc_text LIKE vendornote.desc_text
	#	END RECORD
	DEFINE l_idx SMALLINT --loop control
	DEFINE l_msgresp LIKE language.yes_flag


  LET l_msgresp = kandoomsg("U",1002,"")
  #1002 " Searching database - please wait"

	LET l_query_text = "SELECT note_date, note_text FROM vendornote ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"note_date, note_num "
				
	PREPARE s_vendornote FROM l_query_text
	DECLARE c_vendornote CURSOR FOR s_vendornote


   LET l_idx = 0
   FOREACH c_vendornote INTO l_rec_vendornote.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_vendornote[l_idx].note_date = l_rec_vendornote.note_date
      LET l_arr_rec_vendornote[l_idx].note_text = l_rec_vendornote.note_text
   END FOREACH

	RETURN l_arr_rec_vendornote  
END FUNCTION	

