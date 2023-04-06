#Import static 3 rows TO this table rpttype

#Report Type
#At present, only one REPORT type IS available: 
# S = Standard.  
# The Standard REPORT defines the REPORT as being based solely on the Chart component of the General Ledger account number.  
# Other types that will be available are:  
#
# AD = Analysis Down, 
# where specific segments of the account numbers can be defined TO PRINT VALUES down the REPORT such as 
# Sales Division 1, Sales Division 2, etc., AND 
#
# AC = Analysis Across, 
# where specific segments of the account number can be defined TO PRINT VALUES across the REPORT, 
# by cost centre OR divisions etc.


	
##########################################
--DATABASE kandoodb
GLOBALS "../common/glob_DATABASE.4gl" 
#####################################################################################################
# Accessor Functions rpttype records
#####################################################################################################

###############################################################
# FUNCTION get_rpttype_desc(p_rpttype_id)
###############################################################
FUNCTION get_rpttype_desc(p_rpttype_id)
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id

	DEFINE l_rpttype_desc LIKE rpttype.rpttype_desc

	SELECT rpttype_desc INTO l_rpttype_desc
	FROM rpttype
	WHERE rpttype_id = p_rpttype_id
	
	RETURN l_rpttype_desc

END FUNCTION


###############################################################
# FUNCTION count_rpttype(p_rpttype_id)
###############################################################
FUNCTION count_rpttype(p_rpttype_id)
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id
	DEFINE recCount INT

	IF p_rpttype_id IS NULL THEN
		
		SELECT COUNT(*) INTO recCount FROM rpttype 
     
	ELSE
	
		SELECT COUNT(*) INTO recCount FROM rpttype 
     WHERE rpttype_id = p_rpttype_id
     
	END IF


	RETURN recCount

END FUNCTION


###############################################################
# Import records
###############################################################
FUNCTION import_rpttype() 
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
	
	DEFINE rec_rpttype RECORD 
		rpttype_id       CHAR(5),
		rpttype_desc     CHAR(35)
	END RECORD	
	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_rpttype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_rpttype(
			rpttype_id       CHAR(5),
			rpttype_desc     CHAR(35)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_rpttype	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	OPEN WINDOW wDataImport WITH FORM "per/setup/lib_db_data_import_01"
	DISPLAY "Import Report Type / Table: rpttype" TO header_text


	DISPLAY "N/A" TO cmpy_code

	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/rpttype.unl" INSERT INTO temp_rpttype
	#END IF



  DECLARE import_cur CURSOR FOR 
						SELECT *
						FROM temp_rpttype

	WHENEVER ERROR CONTINUE		
					
  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH import_cur INTO rec_rpttype
  	
				  	
		IF NOT count_rpttype(rec_rpttype.rpttype_id) THEN 

			LET importReport = importReport, "Code:", trim(rec_rpttype.rpttype_id) , "     -     Desc:", trim(rec_rpttype.rpttype_desc), "\n"

			INSERT INTO rpttype VALUES(
	  	 	rec_rpttype.rpttype_id,
	  	 	rec_rpttype.rpttype_desc
	  	 
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
			LET importReport = importReport, "Code:", trim(rec_rpttype.rpttype_id) , "     -     Desc:", trim(rec_rpttype.rpttype_desc), "DUPLICATE = Ignored !\n"		
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

	DROP TABLE temp_rpttype
	CLOSE WINDOW 	wDataImport
	
	RETURN count_rows_inserted
END FUNCTION

###############################################################
# FUNCTION unload_rpttype()
###############################################################
FUNCTION unload_rpttype()
	UNLOAD TO "unl/rpttype.unl" 
		SELECT * FROM rpttype ORDER BY rpttype_id ASC
END FUNCTION		

###############################################################
# FUNCTION delete_rpttype()  --NOTE DELETE ALL
###############################################################
FUNCTION delete_rpttype()
	DELETE FROM rpttype
END FUNCTION		