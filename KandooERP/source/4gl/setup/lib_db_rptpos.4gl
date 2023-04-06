#Import static 3 rows TO this table rptpos

# Desc Position
# Three codes are available TO define where in the REPORT header the REPORT description IS TO PRINT.  These are:  
# C  = Centred, 
# L = Left Justified, 
# R = Right Justified.  
# These codes can be selected at runtime are used for validation


	
##########################################
--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
################################################################################################
# Accessor Functions rptpos records
################################################################################################


#############################################################
# FUNCTION get_rptpos_desc(p_rptpos_id)
#############################################################
FUNCTION get_rptpos_desc(p_rptpos_id)
	DEFINE p_rptpos_id LIKE rptpos.rptpos_id

	DEFINE l_rptpos_desc LIKE rptpos.rptpos_desc

	SELECT rptpos_desc INTO l_rptpos_desc
	FROM rptpos
	WHERE rptpos_id = p_rptpos_id
	
	RETURN l_rptpos_desc

END FUNCTION


#############################################################
# FUNCTION count_rptpos(p_rptpos_id)
#############################################################
FUNCTION count_rptpos(p_rptpos_id)
	DEFINE p_rptpos_id LIKE rptpos.rptpos_id
	DEFINE recCount INT

	IF p_rptpos_id IS NULL THEN
		
		SELECT COUNT(*) INTO recCount FROM rptpos 
     
	ELSE
	
		SELECT COUNT(*) INTO recCount FROM rptpos 
     WHERE rptpos_id = p_rptpos_id
     
	END IF


	RETURN recCount

END FUNCTION

###############################################################
# Import records
###############################################################
FUNCTION import_rptpos() 
	DEFINE recCount SMALLINT
	DEFINE msgString STRING
	DEFINE importReport STRING
	#DEFINE importReportLine VARCHAR(100)
			
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
  
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	
	DEFINE rec_rptpos RECORD 
		rptpos_id       CHAR(1),
		rptpos_desc     CHAR(35)
	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_rptpos
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_rptpos(
			rptpos_id       CHAR(1),
			rptpos_desc     CHAR(35)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_rptpos	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	
	
	OPEN WINDOW wDataImport WITH FORM "per/setup/lib_db_data_import_01"
	DISPLAY "Import Report Position / Table: rptpos" TO header_text
	
	DISPLAY "N/A" TO cmpy_code

	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/rptpos.unl" INSERT INTO temp_rptpos
	#END IF

  DECLARE import_cur CURSOR FOR 
						SELECT *
						FROM temp_rptpos

	WHENEVER ERROR CONTINUE		
					
  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH import_cur INTO rec_rptpos
				  	
		IF NOT count_rptpos(rec_rptpos.rptpos_id) THEN 

			LET importReport = importReport, "Code:", trim(rec_rptpos.rptpos_id) , "     -     Desc:", trim(rec_rptpos.rptpos_desc), "\n"

			INSERT INTO rptpos VALUES(
	  	 	rec_rptpos.rptpos_id,
	  	 	rec_rptpos.rptpos_desc
	  	 
	  	)
  	 
			IF STATUS <> 0 THEN --ERROR

				LET count_insert_errors = count_insert_errors +1
	
			  LET driver_error = fgl_driver_error()
			  LET native_error = fgl_native_error()
			  LET native_code = fgl_native_code()
	  
				LET importReport = importReport, "ERROR STATUS:\t", trim(STATUS), "\n"
				LET importReport = importReport, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
				LET importReport = importReport, "driver_error:\t", trim(driver_error), "\n"
				LET importReport = importReport, "native_error:\t", trim(native_error), "\n"
				LET importReport = importReport, "native_code:\t",  trim(native_code), "\n"						

			END IF
			
			LET count_rows_inserted = count_rows_inserted + 1
		ELSE
			LET importReport = importReport, "Code:", trim(rec_rptpos.rptpos_id) , "     -     Desc:", trim(rec_rptpos.rptpos_desc), "DUPLICATE = Ignored !\n"		
			LET count_already_exist = count_already_exist +1
		END IF
		
		LET count_rows_processed= count_rows_processed + 1
		DISPLAY BY NAME importReport

	END FOREACH

	WHENEVER ERROR STOP
		
	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	INPUT BY NAME importReport WITHOUT DEFAULTS
		ON ACTION "Done"
			EXIT INPUT
	END INPUT

	DROP TABLE temp_rptpos
	CLOSE WINDOW 	wDataImport
		
	RETURN count_rows_inserted
END FUNCTION

###############################################################
# FUNCTION unload_rptpos()
###############################################################
FUNCTION unload_rptpos()
	UNLOAD TO "unl/device_type.unl" 
		SELECT * FROM rptpos ORDER BY rptpos_id ASC
END FUNCTION		


###############################################################
# FUNCTION delete_rptpos()  NOTE: Delete ALL
###############################################################
FUNCTION delete_rptpos()
	DELETE FROM rptpos
END FUNCTION		
