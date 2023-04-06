#Import static 3 rows TO this table signcode

# Sign Code
# The default entered here will define the presentation of VALUES 
# FROM the accounts TO be used in lines AND columns.  
# This can be changed at the COLUMN AND line level if required.  
# The available OPTIONS are as follows:  
# Y = Reverse all database signs, AND the credits 
#     will PRINT as positive AND the debits as negative. 
# N = Leave database signs unchanged, AND the credits 
#     will PRINT as negative AND the debits as positive. 
# + = Reverse the sign of the entry if it IS different 
#     FROM the expected sign, where it IS different 
# FROM the expected PRINT it as a negative.  
# The user defines whether they expect the value of the line 
# TO be a debit (+) OR a credit (-).  
# If, when running the REPORT, the calculated value of 
# the line IS a credit, AND the expected value of the line 
# IS a credit, the value printed will appear as a positive value.  
# If the value was a debit, the value will be printed as a negative, 
# highlighting the amount TO the user.  
# In mathematical calculations within the REPORT, the debits 
# AND credits are treated correctly regardless of the sign code 
# used TO PRINT the REPORT.  
# These can be selected using the lookup CTRL+B search facility if required.


	
##########################################
--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
###############################################################
# Accessor Functions signcode records
###############################################################

FUNCTION get_sign_desc(p_sign_code)
	DEFINE p_sign_code LIKE signcode.sign_code

	DEFINE l_sign_desc LIKE signcode.sign_desc

	SELECT sign_desc INTO l_sign_desc
	FROM signcode
	WHERE sign_code = p_sign_code
	
	RETURN l_sign_desc

END FUNCTION

FUNCTION count_signcode(p_sign_code)
	DEFINE p_sign_code LIKE signcode.sign_code
	DEFINE recCount INT

	IF p_sign_code IS NULL THEN
		
		SELECT COUNT(*) INTO recCount FROM signcode 
     
	ELSE
	
		SELECT COUNT(*) INTO recCount FROM signcode 
     WHERE sign_code = p_sign_code
     
	END IF


	RETURN recCount

END FUNCTION

###############################################################
# Import records
###############################################################
FUNCTION import_signcode() 
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
	
	DEFINE rec_signcode RECORD 
		sign_code				CHAR(5),
		sign_desc			CHAR(35),
		sign_change				CHAR(1),
		sign_base					CHAR(1)
	END RECORD	
	
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_signcode
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_signcode(
			sign_code				CHAR(5),
			sign_desc			CHAR(35),
			sign_change				CHAR(1),
			sign_base					CHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_signcode	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	


	OPEN WINDOW wDataImport WITH FORM "per/setup/lib_db_data_import_01"
	DISPLAY "Import Sign Code / Table: signcode" TO header_text


	DISPLAY "N/A" TO cmpy_code

	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/signcode.unl" INSERT INTO temp_signcode
	#END IF



  DECLARE import_cur CURSOR FOR 
						SELECT *
						FROM temp_signcode

	WHENEVER ERROR CONTINUE		
					
  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH import_cur INTO rec_signcode
  	
				  	
		IF NOT count_signcode(rec_signcode.sign_code) THEN 

			LET importReport = importReport, "Code:", trim(rec_signcode.sign_code) , "     -     Desc:", trim(rec_signcode.sign_desc), "\n"

			INSERT INTO signcode VALUES(
	  	 	rec_signcode.sign_code,
	  	 	rec_signcode.sign_desc
	  	 
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
			LET importReport = importReport, "Code:", trim(rec_signcode.sign_code) , "     -     Desc:", trim(rec_signcode.sign_desc), "DUPLICATE = Ignored !\n"		
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

	DROP TABLE temp_signcode
	CLOSE WINDOW 	wDataImport
		
	RETURN count_rows_inserted
END FUNCTION


FUNCTION unload_signcode()
	UNLOAD TO "unl/signcode.unl" 
		SELECT * FROM signcode ORDER BY sign_code ASC
END FUNCTION		