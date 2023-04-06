GLOBALS "lib_db_globals.4gl"

FUNCTION import_period()
	DEFINE recCount SMALLINT
	DEFINE importReport STRING

	DEFINE yearValue LIKE coa.start_year_num
	DEFINE periodValue LIKE coa.start_period_num
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
  
	DEFINE l_cmpy_code LIKE coa.cmpy_code
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num  LIKE coa.end_year_num 
	DEFINE l_end_period_num  LIKE coa.end_period_num 
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
 
	DEFINE rec_coa RECORD 
#cmpy_code            CHAR(2),
	acct_code            CHAR(18),
	desc_text            CHAR(40),
	type_ind             CHAR(1),
#start_year_num       SMALLINT,
#start_period_num     SMALLINT,
#end_year_num         SMALLINT,
#end_period_num       SMALLINT,
	group_code           CHAR(7),
	analy_req_flag       CHAR(1),
	analy_prompt_text    CHAR(20)--,
#qty_flag             CHAR(1),
#uom_code             CHAR(4),
#type_ind             CHAR(1),
#tax_code             CHAR(3)
	END RECORD	
	
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_coa
		IF STATUS = -206 THEN  --table does NOT exist
	CREATE TEMP TABLE temp_coa(
		#cmpy_code            CHAR(2),
		acct_code            CHAR(18),
		desc_text            CHAR(40),
		type_ind             CHAR(1),
		#start_year_num       SMALLINT,
		#start_period_num     SMALLINT,
		#end_year_num         SMALLINT,
		#end_period_num       SMALLINT,
		group_code           CHAR(7),
		analy_req_flag       CHAR(1),
		analy_prompt_text    CHAR(20)--,
		#qty_flag             CHAR(1),
		#uom_code             CHAR(4),
		#type_ind             CHAR(1),
		#tax_code             CHAR(3)
	)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_coa	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	OPEN WINDOW wDataImport WITH FORM "per/setup/db_coa_input"
	DISPLAY "Import Period / Table coa" TO header_text
		
	INPUT l_cmpy_code, l_start_year_num, l_start_period_num, l_end_year_num, l_end_period_num WITHOUT DEFAULTS FROM inputRec.*  
		ON ACTION "Hello"
			DISPLAY "Hello"
	END INPUT



	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/coa_template_v2.unl" INSERT INTO temp_coa
	#END IF



  DECLARE template_cur CURSOR FOR 
						SELECT *
						FROM temp_coa

	WHENEVER ERROR CONTINUE						
  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOR yearValue = l_start_year_num TO l_end_year_num
  	FOR periodValue = l_start_period_num TO l_end_period_num
			
			LET count_rows_processed= count_rows_processed + 1
			
			IF NOT exist_period(l_cmpy_code,yearValue,periodValue) THEN
				LET importReport = importReport, "Code:", trim(l_cmpy_code) , "     -     Year:", trim(yearValue), " Period:", trim(periodValue) ,"\n"
			
			
				LET count_rows_inserted = count_rows_inserted + 1
				
				INSERT INTO coa VALUES(
	  		 	l_cmpy_code,
	  		 	yearValue,
	  		 	periodValue  	 
	  		)
			END IF



			
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
			
  	
  	END FOR
  END FOR
  	
	WHENEVER ERROR STOP

	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	INPUT BY NAME importReport WITHOUT DEFAULTS
		ON ACTION "Done"
			EXIT INPUT
	END INPUT

	DROP TABLE temp_coa		
	CLOSE WINDOW 	wDataImport
	
	RETURN
END FUNCTION

FUNCTION exist_period(p_cmpy_code,p_yearValue,p_periodValue)
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE p_yearValue LIKE coa.start_year_num
	DEFINE p_periodValue LIKE coa.start_period_num
		
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM period 
     WHERE cmpy_code = p_cmpy_code
     AND year_num = p_yearValue
     AND period_num = p_periodValue

	RETURN recCount

END FUNCTION