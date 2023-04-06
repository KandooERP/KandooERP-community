########################################################################################################################
# TABLE termdetl
#
#
########################################################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

FUNCTION db_termdetl_get_count()
	DEFINE ret INT

	SQL
		SELECT count(*) INTO $ret FROM termdetl WHERE termdetl.cmpy_code = $glob_rec_kandoouser.cmpy_code		
	END SQL
		
	RETURN ret
END FUNCTION




############################################################
# FUNCTION db_termdetl_pk_exists(p_term_code,p_days_num
#
# Validate PK - Unique
############################################################
FUNCTION db_termdetl_pk_exists(p_term_code,p_days_num)
	DEFINE p_term_code LIKE termdetl.term_code
	DEFINE p_days_num LIKE termdetl.days_num
	DEFINE ret INT

	SQL
		SELECT count(*) 
		INTO $ret 
		FROM termdetl 
		WHERE termdetl.cmpy_code = $glob_rec_kandoouser.cmpy_code 
		AND termdetl.term_code = $p_term_code 
		AND termdetl.days_num = $p_days_num 		
	END SQL
	
	RETURN ret
END FUNCTION



#################################################################################
# FUNCTION db_termdetl_get_arr_rec(p_term_code)
#
# Get all detail rows for this term
#################################################################################
FUNCTION db_termdetl_get_arr_rec(p_term_code)
	DEFINE p_term_code LIKE termdetl.term_code
	DEFINE idx SMALLINT
	DEFINE l_rec_termdetl RECORD LIKE termdetl.*
	DEFINE l_msg STRING

	DEFINE l_arr_rec_termdetl DYNAMIC ARRAY OF
		RECORD
         #scroll_flag CHAR(1),
         days_num LIKE termdetl.days_num,
         disc_per LIKE termdetl.disc_per
		END RECORD

	IF p_term_code IS NULL THEN
		LET l_msg = "Invalid argument passed TO db_termdetl_get_arr_rec()!\np_term_code=", trim(p_term_code), "\nContact Maia Support support@kandooerp.org"
		CALL fgl_winmessage("Internal error in db_termdetl_get_arr_rec()", l_msg,"error")
	END IF
					
   DECLARE c_termdetl CURSOR FOR
    SELECT * FROM termdetl
     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
       AND term_code = p_term_code
     ORDER BY days_num asc
   #LET l_old_day_num = l_rec_term.due_day_num

		LET idx = 0
		FOREACH c_termdetl INTO l_rec_termdetl.*
			LET idx = idx + 1
			#LET l_arr_rec_termdetl[idx].scroll_flag = NULL
			LET l_arr_rec_termdetl[idx].days_num = l_rec_termdetl.days_num
			LET l_arr_rec_termdetl[idx].disc_per = l_rec_termdetl.disc_per
		END FOREACH   

	RETURN l_arr_rec_termdetl    
END FUNCTION


############################################################
# 
# FUNCTION db_termdetl_delete(p_rec_termdetl)
#
#
############################################################
FUNCTION db_termdetl_delete(p_rec_termdetl)
	DEFINE p_rec_termdetl RECORD LIKE termdetl.*
	DEFINE l_msgresp LIKE language.yes_flag	
	DEFINE l_sql_stmt_status SMALLINT	
	
	SQL            
		DELETE FROM termdetl
		WHERE cmpy_code = $p_rec_termdetl.cmpy_code
		  AND term_code = $p_rec_termdetl.term_code
		  AND days_num = $p_rec_termdetl.days_num
	END SQL
	
	IF sqlca.sqlcode < 0 THEN   		                                                                                        
		LET l_sql_stmt_status = -1		                                                                                              	
	ELSE		                                                                                                                    
		LET l_sql_stmt_status=0		                                                                                                
	END IF		             
	                                                                                                     
	RETURN l_sql_stmt_status	
		  
END FUNCTION	         



############################################################
# FUNCTION db_termdetl_days_num_validate(p_rec_termdetl,p_Null,p_mode)
#
#
############################################################
FUNCTION db_termdetl_validate(p_rec_termdetl,p_mode)
	DEFINE p_rec_termdetl RECORD LIKE termdetl.*
	#DEFINE p_disc_per LIKE termdetl.disc_per
	DEFINE p_mode STRING  --U=Update A=Append M= Miscellaneous
	DEFINE ret BOOLEAN
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_msgStr STRING
	DEFINE i SMALLINT
	
	LET p_mode = p_mode.toUpperCase()

	#NULL check
	IF p_rec_termdetl.days_num IS NULL THEN
		ERROR "Days value must be specified"
		RETURN 1
	END IF

	#Negative check - can't be less than one day
	IF p_rec_termdetl.days_num < 1 THEN
		ERROR "Days value must be one ore more days"
		RETURN 1
	END IF


	IF p_rec_termdetl.disc_per IS NULL THEN
		ERROR "Discount value must be specified"
		RETURN 1
	END IF

	#General check - range
	IF (p_rec_termdetl.disc_per < 0) OR (p_rec_termdetl.disc_per > 100) THEN
		MESSAGE "Discount value must be in the range of 0 - 100"
		RETURN 1
	END IF


	#Special mode check
	FOR i = 1 TO p_mode.getLength()	
		CASE p_mode[i]
			WHEN "E"  
				IF NOT db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					ERROR "Record NOT found in Payment Term Detail (termdetl)"
				RETURN 1
				END IF
			WHEN "N"
				IF db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					LET l_msgStr =  "Payment Term Detail ", p_rec_termdetl.term_code CLIPPED, "with ", p_rec_termdetl.days_num CLIPPED , " days already exists!"
					ERROR l_msgStr
				RETURN 1
				END IF
			WHEN "D"
				IF db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					ERROR "Record NOT found in Payment Term Detail (termdetl)"
				RETURN 1
				END IF

			OTHERWISE
				#nothing
			
		END CASE
	END FOR

	RETURN 0 --all good         
END FUNCTION         


############################################################
# FUNCTION db_termdetl_update(p_rec_termdetl)
#
#
############################################################
FUNCTION db_termdetl_update(p_rec_termdetl)
	DEFINE p_rec_termdetl RECORD LIKE termdetl.*

	IF NOT db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN #check if record PK already exists
		ERROR "Payment details for ", trim(p_rec_termdetl.days_num), " does NOT exist "
		RETURN -1
	ELSE 
	
		SQL
			UPDATE termdetl
			SET * = $p_rec_termdetl.*
			WHERE days_num = $p_rec_termdetl.days_num
			AND cmpy_code = $p_rec_termdetl.cmpy_code
			AND term_code = $p_rec_termdetl.term_code
		END SQL
	END IF
	RETURN STATUS
END FUNCTION        

   
############################################################
# FUNCTION db_termdetl_insert(p_rec_termdetl)
#
#
############################################################
FUNCTION db_termdetl_insert(p_rec_termdetl)
	DEFINE p_rec_termdetl RECORD LIKE termdetl.*

	IF db_termdetl_validate(p_rec_termdetl.*,NULL) = 0 THEN
	
	IF db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN #check if record PK already exists
		ERROR "Vendor Type ", trim(p_rec_termdetl.days_num), " already exists "
		RETURN -1
	END IF
	
	 
		INSERT INTO termdetl
    VALUES(p_rec_termdetl.*)

    IF sqlca.sqlerrd[2] <> 0 THEN
    	CALL fgl_winmessage(sqlca.sqlerrd[6],"Could NOT INSERT new record","error")
    END IF
	ELSE
		ERROR "Could NOT create new record"
	END IF

	 
	RETURN sqlca.sqlerrd[2]

END FUNCTION




############################################################
# FUNCTION db_termdetl_days_num_validate(p_rec_termdetl,p_Null,p_mode)
#
#
############################################################
FUNCTION db_termdetl_days_num_validate(p_rec_termdetl,p_Null,p_mode)
	DEFINE p_rec_termdetl RECORD LIKE termdetl.*
	#DEFINE p_disc_per LIKE termdetl.disc_per
	DEFINE p_null STRING
	DEFINE p_mode STRING  --U=Update A=Append M= Miscellaneous
	DEFINE ret BOOLEAN
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_msgStr STRING
	DEFINE i SMALLINT
	
	LET p_mode = p_mode.toUpperCase()
	LET p_null = p_null.toUpperCase()
	#NULL check
	IF p_Null <> "NULL" THEN		
		IF p_rec_termdetl.days_num IS NULL THEN
			ERROR "Days value must be specified" #yes, copy paste shit.. AND because I have data... it doesn'T trigger
			RETURN 1
		END IF
	END IF

	#General check - range
	IF p_rec_termdetl.days_num < 1 THEN
		MESSAGE "Minimum value IS 1 day !"
		RETURN 1
	END IF


	#Special mode check
	FOR i = 1 TO p_mode.getLength()	
		CASE p_mode[i]
			WHEN "E"  
				IF NOT db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					ERROR "Record NOT found in Payment Term Detail (termdetl)"
				END IF
			WHEN "N"
				IF db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					LET l_msgStr =  "Payment Term Detail ", p_rec_termdetl.term_code CLIPPED, "with ", p_rec_termdetl.days_num CLIPPED , " days already exists!"
					ERROR l_msgStr
				END IF
			WHEN "D"
				IF db_termdetl_pk_exists(p_rec_termdetl.term_code,p_rec_termdetl.days_num) THEN
					ERROR "Record NOT found in Payment Term Detail (termdetl)"
				END IF

			OTHERWISE
				#nothing
			
		END CASE
	END FOR

	RETURN 0         
END FUNCTION         


############################################################
# FUNCTION db_termdetl_disc_per_validate(p_disc_per,p_notNull,p_mode)
#
#
############################################################
FUNCTION db_termdetl_disc_per_validate(p_disc_per,p_notNull,p_mode)
	DEFINE p_disc_per LIKE termdetl.disc_per
	DEFINE p_notNull BOOLEAN
	DEFINE p_mode CHAR  --U=Update A=Append M= Miscellaneous
	DEFINE ret BOOLEAN
	DEFINE l_msgresp LIKE language.yes_flag

	IF p_notNull THEN		
		IF p_disc_per IS NULL THEN
			ERROR "Discount value must be specified"
			RETURN 1
		END IF
	END IF

	IF (p_disc_per < 0) OR (p_disc_per > 100) THEN
		MESSAGE "Discount value must be in the range of 0 - 100"
		RETURN 1
	END IF
	
	CASE UPSHIFT(p_mode)
		WHEN "U"  
		WHEN "A"
		WHEN "D"
		OTHERWISE
	END CASE

	RETURN 0         
END FUNCTION         

