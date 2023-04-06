########################################################################################################################
# TABLE term
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_term_get_count()
#
# Return total number of rows in term FROM current company
############################################################
FUNCTION db_term_get_count()
	DEFINE l_ret_count INT

	SELECT count(*) 
	INTO l_ret_count 
	FROM term 
	WHERE term.cmpy_code = glob_rec_kandoouser.cmpy_code		
		
	RETURN l_ret_count
END FUNCTION
############################################################
# END FUNCTION db_term_get_count()
############################################################

				
############################################################
# FUNCTION db_term_pk_exists(p_term_code)
#
# Validate PK - Unique
############################################################
FUNCTION db_term_pk_exists(p_term_code)
	DEFINE p_term_code LIKE term.term_code
	DEFINE l_ret_exist INT

	SELECT count(*) 
	INTO l_ret_exist 
	FROM term 
	WHERE term.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term.term_code = p_term_code  		
	
	RETURN l_ret_exist
END FUNCTION
############################################################
# END FUNCTION db_term_pk_exists(p_term_code)
############################################################


############################################################
# FUNCTION db_term_get_rec(p_ui_mode,p_term_code)
#
# Return term record matching PK term_code
############################################################
FUNCTION db_term_get_rec(p_ui_mode,p_term_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_term_code LIKE term.term_code
	DEFINE l_ret_rec_term RECORD LIKE term.*
	DEFINE l_msg STRING
	
	IF p_term_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Term Code can NOT be empty"
			RETURN NULL
		END IF
	END IF

	SELECT * 
	INTO l_ret_rec_term 
	FROM term 
	WHERE term.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term.term_code = p_term_code  		
	
	IF sqlca.sqlcode != 0 THEN
		INITIALIZE l_ret_rec_term.* TO NULL 
		IF p_ui_mode != UI_OFF THEN 
			ERROR "Payment Term with Code ",trim(p_term_code),  "NOT found"
		END IF
	END IF

	RETURN l_ret_rec_term.* 
END FUNCTION 
############################################################
# END FUNCTION db_term_get_rec(p_ui_mode,p_term_code)
############################################################


########################################################################################################################
#
# ARRAY DATASOURCE
#
########################################################################################################################


############################################################
# FUNCTION db_term_get_arr_rec_short(p_where_text)
# RETURN l_arr_rec_term 
# Return term rec array
############################################################
FUNCTION db_term_get_arr_rec_short(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_query_text VARCHAR(500)
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_arr_rec_term DYNAMIC ARRAY OF
		RECORD
			term_code LIKE term.term_code,
			desc_text LIKE term.desc_text
		END RECORD
	DEFINE l_idx SMALLINT --loop control

	LET l_query_text = "SELECT * FROM term ",
                        "WHERE cmpy_code =\"",glob_rec_kandoouser.cmpy_code,"\" "

	IF p_where_text IS NOT NULL THEN 
		LET l_query_text =  l_query_text CLIPPED, " AND ", trim(p_where_text), " "
	END IF

	LET l_query_text =  l_query_text CLIPPED,
			"ORDER BY ",
				"cmpy_code,",
				"term_code"

	PREPARE s_term FROM l_query_text
	DECLARE c_term CURSOR FOR s_term


   LET l_idx = 0
   FOREACH c_term INTO l_rec_term.*
      LET l_idx = l_idx + 1
      LET l_arr_rec_term[l_idx].term_code = l_rec_term.term_code
      LET l_arr_rec_term[l_idx].desc_text = l_rec_term.desc_text
   END FOREACH

	RETURN l_arr_rec_term  
END FUNCTION	
############################################################
# END FUNCTION db_term_get_arr_rec_short(p_where_text)
############################################################


########################################################################################################################
#
# Field Accessor
#
########################################################################################################################

############################################################
# FUNCTION db_term_get_desc_text(p_ui_mode,p_term_code)
#
#
############################################################
FUNCTION db_term_get_desc_text(p_ui_mode,p_term_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_term_code LIKE term.term_code
	DEFINE l_ret_desc_text LIKE term.desc_text
	
	IF p_term_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Term Code can not be empty"
		END IF
		RETURN NULL
	END IF
	
	IF db_term_pk_exists(p_term_code) THEN
	
	SELECT desc_text INTO l_ret_desc_text 
	FROM term 
	WHERE term.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term.term_code = p_term_code  		
		
	ELSE
		IF p_ui_mode != UI_OFF THEN
			ERROR "Payment terms NOT found"
		END IF
		LET l_ret_desc_text = NULL
	END IF
		
	RETURN l_ret_desc_text
END FUNCTION	
############################################################
# END FUNCTION db_term_get_desc_text(p_ui_mode,p_term_code)
############################################################


########################################################################################################################
#
# Field Validation
#
########################################################################################################################


############################################################
# FUNCTION db_term_term_code_validate(p_term_code,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_term_term_code_validate(p_term_code,p_notNull,p_mode)
	DEFINE p_term_code LIKE term.term_code
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous

	IF p_notNull THEN		
		IF p_term_code IS NULL THEN
			ERROR kandoomsg2("A",9099,"")		# Payment term code must be entered.
			#ERROR "Payment term code value must be specified"
			RETURN -1
		END IF
	END IF

	CASE UPSHIFT(p_mode)
		WHEN "N"
			IF db_term_pk_exists(p_term_code) THEN
				#MESSAGE "Unique payment term with this Payment Term Code already exists"
				ERROR kandoomsg2("A",9098,"")			# Payment term code already exists
				RETURN -1
			END IF		  
		WHEN "E"
		WHEN "D"
		OTHERWISE --M
	END CASE

	RETURN 0         
END FUNCTION    
############################################################
# END FUNCTION db_term_term_code_validate(p_term_code,p_notNull,p_mode)
############################################################


############################################################
# FUNCTION db_term_desc_text_validate(p_desc_text,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_term_desc_text_validate(p_desc_text,p_notNull,p_mode)
	DEFINE p_desc_text LIKE term.desc_text
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous

	IF p_notNull THEN		
		IF p_desc_text IS NULL THEN
			ERROR kandoomsg2("A",9101,"")	# Must enter a description
			RETURN -1
		END IF
	END IF

	CASE UPSHIFT(p_mode)
		WHEN "N"
		WHEN "E"
		WHEN "D"
		OTHERWISE --M
	END CASE

	RETURN 0         
END FUNCTION    
############################################################
# END FUNCTION db_term_desc_text_validate(p_desc_text,p_notNull,p_mode)
############################################################


############################################################
# FUNCTION db_term_day_date_ind_validate(p_day_date_ind,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_term_day_date_ind_validate(p_day_date_ind,p_notNull,p_mode)
	DEFINE p_day_date_ind LIKE term.day_date_ind
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous

	IF p_notNull THEN		
		IF p_day_date_ind IS NULL THEN
			ERROR kandoomsg2("A",9102,"")	#9102 Must enter a value
			RETURN -1
		END IF
	END IF

	CASE UPSHIFT(p_mode)
		WHEN "N"
		WHEN "E"
		WHEN "D"
		OTHERWISE --M
	END CASE

	RETURN 0         
END FUNCTION    
############################################################
# END FUNCTION db_term_day_date_ind_validate(p_day_date_ind,p_notNull,p_mode)
############################################################


############################################################
# FUNCTION db_term_due_day_num_validate(p_due_day_num,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_term_due_day_num_validate(p_due_day_num,p_notNull,p_mode)
	DEFINE p_due_day_num LIKE term.due_day_num
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous

	IF p_notNull THEN		
		IF p_due_day_num IS NULL THEN
			ERROR kandoomsg2("A",9102,"")#9102 Must enter a value
			RETURN -1
		END IF
	END IF

	CASE UPSHIFT(p_mode)
		WHEN "N"
			IF p_due_day_num < 0 THEN
				ERROR kandoomsg2("A",9103,"")		# Number of days may NOT be negative
				RETURN -1
			END IF		
		WHEN "E"
		WHEN "D"
		OTHERWISE --M
	END CASE
	
{
				
			
            CASE
               WHEN l_rec_term.due_day_num IS NULL
                  LET l_rec_term.due_day_num = l_old_day_num
                  ERROR kandoomsg2("A",9102,"")              # Must enter a value
                  NEXT FIELD due_day_num
               WHEN l_rec_term.due_day_num < 0
                  ERROR kandoomsg2("A",9103,"")         # Number of days may NOT be negative
                  LET l_rec_term.due_day_num = l_old_day_num
                  DISPLAY l_rec_term.due_day_num TO due_day_num
                     
                  NEXT FIELD due_day_num
               WHEN l_rec_term.due_day_num = 0
                  IF l_rec_term.day_date_ind = "T"
                  OR l_rec_term.day_date_ind = "W" THEN
                     ERROR kandoomsg2("A",9104,"")            # Date must be between 1 AND 31
                     LET l_rec_term.due_day_num = 1
                     DISPLAY l_rec_term.due_day_num TO due_day_num
                        
                     NEXT FIELD due_day_num
                  END IF
               WHEN l_rec_term.due_day_num > 31
                  IF l_rec_term.day_date_ind = "C"
                  OR l_rec_term.day_date_ind = "T"
                  OR l_rec_term.day_date_ind = "W" THEN
                     ERROR kandoomsg2("A",9104,"")            # Date must be between 1 AND 31
                     LET l_rec_term.due_day_num = 31
                     DISPLAY l_rec_term.due_day_num TO due_day_num
                        
                     NEXT FIELD due_day_num
                  END IF
            END CASE

}

	RETURN 0         
END FUNCTION    
############################################################
# END FUNCTION db_term_due_day_num_validate(p_due_day_num,p_notNull,p_mode)
############################################################


############################################################
# FUNCTION db_term_due_day_num_validate(p_due_day_num,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_term_due_day_num_WITH_day_date_ind_validate(p_due_day_num,p_day_date_ind,p_notNull,p_mode)
	DEFINE p_due_day_num LIKE term.due_day_num
	DEFINE p_day_date_ind LIKE term.day_date_ind
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous

	IF p_notNull THEN		
		IF p_due_day_num IS NULL THEN
			ERROR kandoomsg2("A",9102,"")#9102 Must enter a value
			RETURN -1  
		END IF
	END IF

	CASE UPSHIFT(p_mode)
		WHEN "N"
			IF p_due_day_num < 0 THEN
				ERROR kandoomsg2("A",9103,"")	# Number of days may NOT be negative
				RETURN -1
			END IF
					
			IF p_due_day_num < 0 THEN 
				ERROR kandoomsg2("A",9103,"")		# Number of days may NOT be negative
				RETURN -1
      END IF
      IF p_due_day_num = 0 THEN 
				IF p_day_date_ind = "T"
				OR p_day_date_ind = "W" THEN
					ERROR kandoomsg2("A",9104,"")				# Date must be between 1 AND 31
					RETURN -2
				END IF
			END IF
			IF p_due_day_num > 31 THEN
				IF p_day_date_ind = "C"
				OR p_day_date_ind = "T"
				OR p_day_date_ind = "W" THEN
					ERROR kandoomsg2("A",9104,"")				# Date must be between 1 AND 31
					RETURN -3
				END IF
      END IF
		WHEN "E"
		WHEN "D"
		OTHERWISE --M
	END CASE
	
{
				
			
            CASE
               WHEN l_rec_term.due_day_num IS NULL
                  LET l_rec_term.due_day_num = l_old_day_num
                  ERROR kandoomsg2("A",9102,"")                 # Must enter a value
                  NEXT FIELD due_day_num
               WHEN l_rec_term.due_day_num < 0
                  ERROR kandoomsg2("A",9103,"")                 # Number of days may NOT be negative
                  LET l_rec_term.due_day_num = l_old_day_num
                  DISPLAY l_rec_term.due_day_num TO due_day_num
                     
                  NEXT FIELD due_day_num
               WHEN l_rec_term.due_day_num = 0
                  IF l_rec_term.day_date_ind = "T"
                  OR l_rec_term.day_date_ind = "W" THEN
                     ERROR kandoomsg2("A",9104,"")                    # Date must be between 1 AND 31
                     LET l_rec_term.due_day_num = 1
                     DISPLAY l_rec_term.due_day_num TO due_day_num
                        
                     NEXT FIELD due_day_num
                  END IF
               WHEN l_rec_term.due_day_num > 31
                  IF l_rec_term.day_date_ind = "C"
                  OR l_rec_term.day_date_ind = "T"
                  OR l_rec_term.day_date_ind = "W" THEN
                     ERROR kandoomsg2("A",9104,"")                   # Date must be between 1 AND 31
                     LET l_rec_term.due_day_num = 31
                     DISPLAY l_rec_term.due_day_num TO due_day_num
                        
                     NEXT FIELD due_day_num
                  END IF
            END CASE

}

	RETURN 0         
END FUNCTION    
############################################################
# END FUNCTION db_term_due_day_num_validate(p_due_day_num,p_notNull,p_mode)
############################################################


########################################################################################################################
#
# INSERT, UPDATE, DELETE
#
# DELETE IS missing AND needs adding
########################################################################################################################
   
############################################################
# FUNCTION db_term_insert(p_rec_term)
#
#
############################################################
FUNCTION db_term_insert(p_rec_term)
	DEFINE p_rec_term RECORD LIKE term.*

	#IF db_term_validate(p_rec_termdetl,"N") = 0 THEN

	IF NOT db_term_pk_exists(p_rec_term.term_code) THEN #check if record PK already exists
		INSERT INTO term
		VALUES(p_rec_term.*)

		IF sqlca.sqlerrd[2] <> 0 THEN
			CALL fgl_winmessage(sqlca.sqlerrd[6],"Could NOT INSERT new record","error")
		ELSE
			ERROR "New record created"
		END IF
	ELSE
		ERROR "Record already exists"
		RETURN -1	
	END IF
	 
	RETURN sqlca.sqlerrd[2]

END FUNCTION


############################################################
# FUNCTION db_term_update(p_rec_term)
#
#
############################################################
FUNCTION db_term_update(p_rec_term)
	DEFINE p_rec_term RECORD LIKE term.*

	IF NOT db_term_pk_exists(p_rec_term.term_code) THEN #check if record PK already exists
		ERROR "Payment Term ", trim(p_rec_term.term_code), " does NOT exist "
		RETURN -1
	ELSE 
	
		UPDATE term
		SET * = p_rec_term.*
		WHERE cmpy_code = p_rec_term.cmpy_code
		AND term_code = p_rec_term.term_code

	END IF	

	IF sqlca.sqlerrd[2] = 0 THEN
		MESSAGE "Payment Term UPDATE successful"
	ELSE
		ERROR "Payment term UPDATE failed! Error ", sqlca.sqlerrd[2] 
	END IF

	RETURN sqlca.sqlerrd[2]
				
END FUNCTION     
############################################################
# END FUNCTION db_term_insert(p_rec_term)
############################################################