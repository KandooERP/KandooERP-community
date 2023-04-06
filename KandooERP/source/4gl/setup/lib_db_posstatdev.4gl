  GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getposstatdev_Count()
# FUNCTION posstatdev_LookupFilterDataSourceCursor(pRecposstatdev_Filter)
# FUNCTION posstatdev_LookupSearchDataSourceCursor(p_Recposstatdev_Search)
# FUNCTION posstatdev_LookupFilterDataSource(pRecposstatdev_Filter)
# FUNCTION posstatdev_Lookup_filter(p_station_code)
# FUNCTION import_posstatdev()
# FUNCTION exist_posstatdev_Rec(p_cmpy_code, p_station_code)
# FUNCTION delete_posstatdev_all()
# FUNCTION posstatdevMenu()						-- Offer different OPTIONS of this library via a menu


	DEFINE t_recposstatdev_noCmpyId 
		TYPE AS RECORD 
	    station_code LIKE posstatdev.station_code,
	    device_code LIKE posstatdev.device_code,
	    dev_conn_to LIKE posstatdev.dev_conn_to,
	    dev_conn_port LIKE posstatdev.dev_conn_port,
	    access_cmd LIKE posstatdev.access_cmd,
	    device_type LIKE posstatdev.device_type
	END RECORD	

	
########################################################################################
# FUNCTION posstatdevMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION posstatdevMenu()
	MENU
		ON ACTION "Import"
			CALL import_posstatdev()
		ON ACTION "Export"
			CALL unload_posstatdev()
		#ON ACTION "Import"
		#	CALL import_posstatdev()
		ON ACTION "Delete All"
			CALL delete_posstatdev_all()
		ON ACTION "Count"
			CALL getposstatdev_Count() --Count all posstatdev  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getposstatdev_Count()
#-------------------------------------------------------
# Returns the number of posstatdev  entries for the current company
########################################################################################
FUNCTION getposstatdev_Count()
	DEFINE ret_posstatdev_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_posstatdev  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM posstatdev ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_posstatdev.DECLARE(sqlQuery) #CURSOR FOR getposstatdev 
	CALL c_posstatdev.SetResults(ret_posstatdev_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_posstatdev.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_posstatdev_Count = -1
	ELSE
		CALL c_posstatdev.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Post Station Devices:", trim(ret_posstatdev_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("posstatdev Count", tempMsg,"info") 	
	END IF

	RETURN ret_posstatdev_Count
END FUNCTION


############################################
# FUNCTION import_posstatdev()
############################################
FUNCTION import_posstatdev()
	DEFINE recCount SMALLINT
	
	DEFINE msgString STRING
	DEFINE importReport STRING
		
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	 
	DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_ref1_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_posstatdev  OF t_recposstatdev_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wposstatdev_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import IN Parameter List Data (table: posstatdev )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_posstatdev 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_posstatdev (
    #cmpy_code CHAR(2),
    cmpy_code CHAR(2),
    station_code CHAR(8),
    device_code CHAR(10),
    dev_conn_to CHAR(10),
    dev_conn_port CHAR(10),
    access_cmd CHAR(30),
    device_type CHAR(3)

		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_posstatdev 	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

		CASE 
			WHEN gl_setupRec_default_company.country_code = "NUL"
				LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN		
			WHEN gl_setupRec_default_company.country_code = "0"
				--company code comp_code does NOT exist
				LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN
			OTHERWISE
				LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wposstatdev_Import WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

					CASE 
						WHEN gl_setupRec_default_company.country_code = "NUL"
							LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN		
						WHEN gl_setupRec_default_company.country_code = "0"
							--company code comp_code does NOT exist
							LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN
						OTHERWISE
							LET cmpy_code_provided = TRUE
							DISPLAY p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.name_text,country_code,country_text,language_code,language_text
					END CASE 
			END INPUT

		ELSE
			IF gl_setupRec.silentMode = FALSE THEN	
				DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code

				INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code
					WITHOUT DEFAULTS 
					FROM inputRec3.*  
				END INPUT
				
				IF int_flag THEN
					LET int_flag = FALSE
					CLOSE WINDOW wposstatdev_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/posstatdev-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("posstatdev Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_posstatdev 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_posstatdev 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_posstatdev 
			LET importReport = importReport, "Code:", trim(rec_posstatdev.station_code) , "     -     device_code:", trim(rec_posstatdev.device_code), "\n"
					
			INSERT INTO posstatdev  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_posstatdev.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_posstatdev.station_code) , "     -     device_code:", trim(rec_posstatdev.device_code), " ->DUPLICATE = Ignored !\n"
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
		
		END FOREACH

	END IF

	WHENEVER ERROR STOP

	IF gl_setupRec.silentMode = FALSE THEN
			
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wposstatdev_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_posstatdev_Rec(p_cmpy_code, p_station_code)
#
# (device_code,station_code,cmpy_code)
########################################################
FUNCTION exist_posstatdev_Rec(p_cmpy_code, p_station_code)
	DEFINE p_cmpy_code LIKE posstatdev.cmpy_code
	DEFINE p_station_code LIKE posstatdev.station_code
	DEFINE p_device_code LIKE posstatdev.device_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM posstatdev  
     WHERE cmpy_code = p_cmpy_code
     AND station_code = p_station_code

	DROP TABLE temp_posstatdev 
	CLOSE WINDOW wposstatdev_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_posstatdev()
###############################################################
FUNCTION unload_posstatdev (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/posstatdev-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM posstatdev ORDER BY cmpy_code, station_code ASC
	
	LET tmpMsg = "All posstatdev data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("posstatdev Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_posstatdev_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_posstatdev_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE posstatdev.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wposstatdev_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Post Station Devices (posstatdev) Delete" TO header_text
	END IF

	
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN
		#IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT gl_setupRec_default_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.silentMode = 0 THEN 	
			DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing posstatdev table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM posstatdev
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table posstatdev!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table posstatdev where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wposstatdev_Import		
END FUNCTION	