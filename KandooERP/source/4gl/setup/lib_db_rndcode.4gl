#Import static 3 rows TO this table rndcode


# Rounding Code
# The level of rounding IS SET at the header level AND applies
# TO all columns across the REPORT.  
# The rounding available IS:  
# None = Full dollars AND cents, 
# Whole = Rounded TO the nearest dollar, 
# 100 = Rounded TO the nearest $100.00., 
# 1000 = Rounded TO the nearest $1,000.00., 
# 10000 = Rounded TO the nearest $10,000.00., 
# Hundt = Rounded TO the nearest $100,000.00.  
# These can be selected using the Lookup/CTRL+B search facility if required.


	
##########################################
GLOBALS "lib_db_globals.4gl"
#####################################################################################################
# Accessor Functions rndcode records
#####################################################################################################

###############################################################
# FUNCTION get_rnd_desc(p_rnd_code)
###############################################################
FUNCTION get_rnd_desc(p_rnd_code)
	DEFINE p_rnd_code LIKE rndcode.rnd_code

	DEFINE l_rnd_desc LIKE rndcode.rnd_desc

	SELECT rnd_desc INTO l_rnd_desc
	FROM rndcode
	WHERE rnd_code = p_rnd_code
	
	RETURN l_rnd_desc

END FUNCTION

###############################################################
# FUNCTION count_rndcode(p_rnd_code)
###############################################################
FUNCTION count_rndcode(p_rnd_code)
	DEFINE p_rnd_code LIKE rndcode.rnd_code
	DEFINE recCount INT

	IF p_rnd_code IS NULL THEN
		
		SELECT COUNT(*) INTO recCount FROM rndcode 
     
	ELSE
	
		SELECT COUNT(*) INTO recCount FROM rndcode 
     WHERE rnd_code = p_rnd_code
     
	END IF


	RETURN recCount

END FUNCTION

###############################################################
# Import records
###############################################################
FUNCTION import_rndcode() 
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
	
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	DEFINE cmpy_code_provided BOOLEAN	
	
	DEFINE rec_rndcode RECORD 
		rnd_code       CHAR(8),
		rnd_desc     CHAR(35),
		rnd_value INTEGER
	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_rndcode
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_rndcode(
			rnd_code       CHAR(8),
			rnd_desc     CHAR(35),
			rnd_value INTEGER
	)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_rndcode	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

		
	OPEN WINDOW wDataImport WITH FORM "per/setup/lib_db_data_import_01"
	DISPLAY "Round codes Import" TO header_text	
	let load_file = "unl/rndcode.unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_rndcode

	  DECLARE import_cur CURSOR FOR 
		SELECT *
		FROM temp_rndcode

		WHENEVER ERROR CONTINUE		
						
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0

  
		FOREACH import_cur INTO rec_rndcode
					
			INSERT INTO rndcode VALUES(
		 	rec_rndcode.rnd_code,
		 	rec_rndcode.rnd_desc,
		 	rec_rndcode.rnd_value	  	 	
			)

			CASE 
				WHEN STATUS = 0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					# duplicate primary key
					LET importReport = importReport, "Code:", trim(rec_rndcode.rnd_code) , "     -     Desc:", trim(rec_rndcode.rnd_desc), " ->DUPLICATE = Ignored !\n"
					LET count_already_exist = count_already_exist +1
				OTHERWISE	
					LET count_insert_errors = count_insert_errors +1
				  	LET driver_error = fgl_driver_error()
				  	LET native_error = fgl_native_error()
				  	LET native_code = fgl_native_code()
			  
					LET importReport = importReport, "ERROR STATUS:\t", trim(STATUS), "\n"
					LET importReport = importReport, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
					LET importReport = importReport, "driver_error:\t", trim(driver_error), "\n"
					LET importReport = importReport, "native_error:\t", trim(native_error), "\n"
					LET importReport = importReport, "native_code:\t",  trim(native_code), "\n"					
			END CASE
						
			LET count_rows_processed= count_rows_processed + 1
			DISPLAY BY NAME importReport
		
		END FOREACH

	END IF
	WHENEVER ERROR STOP
		
	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	INPUT BY NAME importReport WITHOUT DEFAULTS
		ON ACTION "Done"
			EXIT INPUT
	END INPUT

	DROP TABLE temp_rndcode
	CLOSE WINDOW wDataImport
	
	RETURN count_rows_inserted
END FUNCTION


###############################################################
# FUNCTION unload_rndcode()
###############################################################
FUNCTION unload_rndcode()
	UNLOAD TO "unl/rndcode.unl" 
		SELECT * FROM rndcode ORDER BY rnd_code ASC
END FUNCTION		


###############################################################
# FUNCTION delete_rndcode()
###############################################################
FUNCTION delete_rndcode()
	DELETE FROM rndcode
END FUNCTION		