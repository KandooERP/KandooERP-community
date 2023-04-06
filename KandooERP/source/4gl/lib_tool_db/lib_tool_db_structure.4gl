##############################################################################################
#TABLE structure
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_structure_get_count()
#
# Return total number of rows in structure FROM current company
############################################################
FUNCTION db_structure_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM structure 
		WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL

	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_structure_get_type_count(p_type_ind)
#
# 
# Return total number of rows in structure FROM current company with particular type_ind
############################################################
FUNCTION db_structure_get_type_count(p_type_ind)
	DEFINE p_type_ind LIKE structure.type_ind
	DEFINE ret INT

	IF p_type_ind IS NULL THEN
		ERROR "TYPE_IND can not be NULL"
		RETURN -1
	END IF
	
	
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM structure 
		WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code
		AND structure.type_ind = $p_type_ind		
	END SQL
	
	
	RETURN ret
END FUNCTION

############################################################
# FUNCTION db_structure_pk_exists(p_start_num)
#
# Validate PK - Unique
############################################################
FUNCTION db_structure_pk_exists(p_start_num)
	DEFINE p_start_num LIKE structure.start_num
	DEFINE ret INT

	IF p_start_num IS NULL THEN
		RETURN -1
	END IF
			
	SQL
		SELECT count(*) 
		INTO $ret 
		FROM structure 
		WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND structure.start_num = $p_start_num
	END SQL
	
	RETURN ret
END FUNCTION


############################################################
# FUNCTION db_structure_get_rec(p_start_num)
#
# Return structure record matching PK start_num
############################################################
FUNCTION db_structure_get_rec(p_start_num)
	DEFINE p_start_num LIKE structure.start_num
	DEFINE l_ret_rec_structure RECORD LIKE structure.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_start_num IS NULL THEN
		ERROR "structure Code can NOT be empty"
		RETURN NULL
	END IF
		
		SQL
			SELECT * 
			INTO $l_ret_rec_structure 
			FROM structure 
			WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND structure.start_num = $p_start_num  		
		END SQL

	IF sqlca.sqlcode != 0 THEN 
		ERROR "structure Record with Code ",trim(p_start_num),  "NOT found"
		LET l_msgresp=kandoomsg("P",9106,"")
		#P9106 " structure Code NOT found, try window"		
		RETURN NULL
	ELSE
		RETURN l_ret_rec_structure.*		                                                                                                
	END IF	
END FUNCTION	

############################################################
# FUNCTION db_structure_get_rec_with_type(p_type_ind)
#
# Return structure record matching PK start_num
############################################################
FUNCTION db_structure_get_rec_with_type(p_type_ind)
	DEFINE p_type_ind LIKE structure.type_ind
	DEFINE l_ret_rec_structure RECORD LIKE structure.*
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_type_ind IS NULL THEN
		ERROR "Structure TYPE_IND Code can NOT be empty"
		RETURN NULL
	END IF
	
			
		SQL
			SELECT * 
			INTO $l_ret_rec_structure 
			FROM structure 
			WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code 
			AND structure.type_ind = $p_type_ind  		
		END SQL
	
	
	IF sqlca.sqlcode != 0 THEN 
		ERROR "structure Record with Type_IND Code ",trim(p_type_ind),  "NOT found"
		LET l_msgresp=kandoomsg("P",9106,"")
		#P9106 " structure Code NOT found, try window"		
		RETURN NULL
	ELSE
		RETURN l_ret_rec_structure.*		                                                                                                
	END IF	
END FUNCTION	

############################################################
# FUNCTION db_structure_get_desc_text(p_start_num)
# RETURN l_ret_desc_text
#
# Get desc_text FROM structure record
############################################################
FUNCTION db_structure_get_desc_text(p_start_num)
	DEFINE p_start_num LIKE structure.start_num
	DEFINE l_ret_desc_text LIKE structure.desc_text

	IF p_start_num IS NULL THEN
		ERROR "structure Code can NOT be empty"
		RETURN NULL
	END IF
		
	SQL
		SELECT desc_text 
		INTO $l_ret_desc_text 
		FROM structure 
		WHERE structure.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND structure.start_num = $p_start_num  		
	END SQL

	IF sqlca.sqlcode != 0 THEN
		ERROR "structure Description with Code ",trim(p_start_num),  "NOT found"
		RETURN NULL
	ELSE
		RETURN l_ret_desc_text	                                                                                                
	END IF	
END FUNCTION

				
########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################

############################################################
# FUNCTION db_structure_get_arr_rec(p_where_text)
# RETURN l_arr_rec_structure 
# Return structure rec array
############################################################
FUNCTION db_structure_get_arr_rec(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_arr_rec_structure DYNAMIC ARRAY OF RECORD LIKE structure.*
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM structure ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"start_num"
				
	PREPARE s_structure FROM l_query_text
	DECLARE c_structure CURSOR FOR s_structure


   LET l_idx = 0
   FOREACH c_structure INTO l_rec_structure.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_structure[l_idx].* = l_rec_structure.*
   END FOREACH

	FREE c_structure
	
	RETURN l_arr_rec_structure  
END FUNCTION	


############################################################
# FUNCTION db_structure_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_structure 
# Return structure rec array
############################################################
FUNCTION db_structure_get_arr_rec_short(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_arr_rec_structure DYNAMIC ARRAY OF
		RECORD
			start_num LIKE structure.start_num,
			desc_text LIKE structure.desc_text
		END RECORD
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM structure ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN                        
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF
			                      
	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"cmpy_code,",
				"start_num"
				
	PREPARE s_s_structure FROM l_query_text
	DECLARE c_s_structure CURSOR FOR s_s_structure


   LET l_idx = 0
   FOREACH c_structure INTO l_rec_structure.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num
      LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text
   END FOREACH

	FREE c_s_structure

	RETURN l_arr_rec_structure  
END FUNCTION	


	