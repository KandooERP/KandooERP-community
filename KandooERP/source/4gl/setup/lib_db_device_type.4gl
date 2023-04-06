	
##########################################
--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
###############################################################
# Accessor Functions GroupInfo records
###############################################################

FUNCTION get_device_type_device_desc(p_device_type_id)
	DEFINE p_device_type_id LIKE device_type.device_type_id

	DEFINE l_device_desc LIKE device_type.device_desc

	SELECT desc_text INTO l_device_desc
	FROM device_type
	WHERE device_type_id = p_device_type_id
	
	RETURN l_device_desc

END FUNCTION

FUNCTION count_device_type(p_device_type_id)
	DEFINE p_device_type_id LIKE device_type.device_type_id
	DEFINE recCount INT

	IF p_device_type_id IS NULL THEN
		
		SELECT COUNT(*) INTO recCount FROM device_type 
     
	ELSE
	
		SELECT COUNT(*) INTO recCount FROM device_type 
     WHERE device_type_id = p_device_type_id
     
	END IF


	RETURN recCount

END FUNCTION



###############################################################
# Import records
###############################################################
FUNCTION import_device_type()
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
	
DEFINE rec_device_type RECORD 
	device_type_id       VARCHAR(20),
	device_desc          VARCHAR(30),
	slave_start_1        SMALLINT,
	slave_start_2        SMALLINT,
	slave_start_3        SMALLINT,
	slave_start_4        SMALLINT,
	slave_start_5        SMALLINT,
	slave_start_6        SMALLINT,
	slave_start_7       SMALLINT,
	slave_start_8       SMALLINT,
	slave_start_9       SMALLINT,
	slave_start_10      SMALLINT,
	slave_end_1         SMALLINT,
	slave_end_2         SMALLINT,
	slave_end_3         SMALLINT 
END RECORD	
	
----------------------------------------------		
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_device_type
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_device_type(
			device_type_id       VARCHAR(20),
			device_desc          VARCHAR(30),
			slave_start_1        SMALLINT,
			slave_start_2        SMALLINT,
			slave_start_3        SMALLINT,
			slave_start_4        SMALLINT,
			slave_start_5        SMALLINT,
			slave_start_6      SMALLINT,
			slave_start_7       SMALLINT,
			slave_start_8       SMALLINT,
			slave_start_9       SMALLINT,
			slave_start_10      SMALLINT,
			slave_end_1         SMALLINT,
			slave_end_2         SMALLINT,
			slave_end_3         SMALLINT 
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_device_type	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	OPEN WINDOW wDataImport WITH FORM "per/setup/lib_db_data_import_01"
	DISPLAY "Import Device Type / Table device_type" TO header_text

	DISPLAY "N/A" TO cmpy_code

	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/device_type.unl" INSERT INTO temp_device_type
	#END IF



  DECLARE import_cur CURSOR FOR 
						SELECT *
						FROM temp_device_type

	WHENEVER ERROR CONTINUE		
					
  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH import_cur INTO rec_device_type
  	
				  	
		IF NOT count_device_type(rec_device_type.device_type_id) THEN 

			LET importReport = importReport, "Code:", trim(rec_device_type.device_type_id) , "     -     Desc:", trim(rec_device_type.device_desc), "\n"

			INSERT INTO device_type VALUES(
	  	 	l_cmpy_code,
	  	 	rec_device_type.device_type_id,
	  	 	rec_device_type.device_desc
	  	 
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
			LET importReport = importReport, "Code:", trim(rec_device_type.device_type_id) , "     -     Desc:", trim(rec_device_type.device_desc), "DUPLICATE = Ignored !\n"		
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


	DROP TABLE temp_device_type	
	CLOSE WINDOW wDataImport

	RETURN count_rows_inserted
END FUNCTION


FUNCTION unload_device_type()
	UNLOAD TO "unl/device_type.unl" 
		SELECT * FROM device_type ORDER BY device_type_id ASC
END FUNCTION		