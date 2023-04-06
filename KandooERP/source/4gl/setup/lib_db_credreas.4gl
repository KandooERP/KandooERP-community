GLOBALS "lib_db_globals.4gl"

# FUNCTION import_credreas()
# FUNCTION exist_credreasRec(p_cmpy_code, p_reason_code) 
# FUNCTION unload_credreas(p_silentMode,p_fileExtension)
# FUNCTION delete_credreas(p_silentMode,p_cmpy_code)


########################################################################################
# FUNCTION credReasMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION credReasMenu()
	DEFINE tempMsg STRING
	MENU
		ON ACTION "Import"
			CALL import_credReas()
		ON ACTION "Export"
			CALL unload_credReas(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_credReas_all()
		ON ACTION "Count"
			IF gl_setupRec.silentMode = 0 THEN
				LET tempMsg = "Number of Credit Reasion Types:", trim(getcredReasCount()) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
				CALL fgl_winmessage("CreditReason Count", tempMsg,"info") 	
			END IF
			
			#CALL getcredReasCount() --Count all credReas rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION


########################################################################################
# FUNCTION getCredReasCount()
#-------------------------------------------------------
# Returns the number of CredReas entries for the current company
########################################################################################
FUNCTION getCredReasCount()
	DEFINE ret_CredReasCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_CredReas CURSOR
	DEFINE retError SMALLINT
	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM credreas "

	CALL c_CredReas.DECLARE(sqlQuery) #CURSOR FOR getCredReas
	CALL c_CredReas.SetResults(ret_CredReasCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_credreas.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_credreasCount = -1
	ELSE
		CALL c_credreas.FetchNext()
	END IF

	RETURN ret_credreasCount
END FUNCTION

#######################################################################
# FUNCTION import_credreas()
#######################################################################
FUNCTION import_credreas() 
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
		
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING

	DEFINE rec_credreas RECORD 
		#cmpy_code            CHAR(2),
		reason_code            CHAR(3),
		reason_text            CHAR(30),
		gl_flag             CHAR(1)
	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_credreas
	IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_credreas(
			#cmpy_code            CHAR(2),
			reason_code            CHAR(3),
			reason_text            CHAR(30),
			gl_flag             CHAR(1)
		)
	END IF

	IF recCount <> 0 THEN  #table exists AND has got data
		DELETE FROM temp_credreas	#we need TO INITIALIZE it, delete all rows
	END IF
		
	WHENEVER ERROR STOP	
----------------------------------------------	
	
	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text
		CASE 
		WHEN gl_setupRec_default_company.country_code = "NUL"
			IF gl_setupRec.silentMode = 0 THEN	
				LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			END IF
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN gl_setupRec_default_company.country_code = "0"
			--company code comp_code does NOT exist
			IF gl_setupRec.silentMode = 0 THEN	
				LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			END IF
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
			#DISPLAY p_name_text,md_country_code,p_country_text TO name_text,country_code,country_text
		END CASE				

		#OPEN WINDOW wtaxImport WITH FORM "per/setup/lib_db_data_import_01"
		#DISPLAY "tax Type Delete" TO header_text
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcredreasImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "credreas Type Import" TO header_text
		DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text TO name_text,country_code,country_text

	
	IF cmpy_code_provided = FALSE THEN
		INPUT gl_setupRec_default_company.cmpy_code,gl_setupRec_default_company.country_code WITHOUT DEFAULTS 
		FROM inputRec.* 
			AFTER FIELD cmpy_code
				CALL get_company_info (gl_setupRec_default_company.cmpy_code) RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text
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
					DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text TO name_text,country_code,country_text
				END CASE				
		END INPUT
	ELSE
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text
		IF gl_setupRec.silentMode = FALSE THEN
			DISPLAY gl_setupRec_default_company.cmpy_code,p_name_text,gl_setupRec_default_company.country_code,p_country_text
			TO cmpy_code,name_text,country_code,country_text
		END IF	
	END IF

	END IF
		

	
	LET load_file = "unl/credreas-", trim(gl_setupRec_default_company.country_code), ".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Group Info Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_credreas
	
		DECLARE load_cur CURSOR FOR 
		SELECT * FROM temp_credreas
	
		WHENEVER ERROR CONTINUE						
	
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
		  
		FOREACH load_cur INTO rec_credreas
	  	#DISPLAY rec_credreas.*
			LET importReport = importReport, "Code:", trim(rec_credreas.reason_code) , "     -     Desc:", trim(rec_credreas.reason_text), "\n"
			  	
				INSERT INTO credreas 
				VALUES (
		  	 	gl_setupRec_default_company.cmpy_code,
		  	 	rec_credreas.reason_code,
		  	 	rec_credreas.reason_text
		  	 	# rec_credreas.gl_flag
		  	)
			CASE 
				WHEN STATUS = 0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					# duplicate primary key OR unique key
					LET importReport = importReport, "Code:", trim(rec_credreas.reason_code) , "     -     Desc:", trim(rec_credreas.reason_text), " ->DUPLICATE = Ignored !\n"
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
		END FOREACH

	END IF
	WHENEVER ERROR STOP


	IF gl_setupRec.silentMode = 0 THEN
		
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
	
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
	END IF
		
	RETURN count_rows_inserted

END FUNCTION


#######################################################################
# FUNCTION exist_credreasRec(p_cmpy_code, p_reason_code)
#######################################################################
FUNCTION exist_credreasRec(p_cmpy_code, p_reason_code)
	DEFINE p_cmpy_code LIKE credreas.cmpy_code
	DEFINE p_reason_code LIKE credreas.reason_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM credreas 
     WHERE cmpy_code = p_cmpy_code
     AND reason_code = p_reason_code

	#DROP TABLE temp_credreas
	#CLOSE WINDOW wcredreasImport
	
	RETURN recCount

END FUNCTION


###############################################################
# FUNCTION unload_credreas()
###############################################################
FUNCTION unload_credreas(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()	
	
	LET unloadFile = "unl/credreas-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT 
	    #cmpy_code,
	    reason_code,
	    reason_text	 
		FROM credreas
		WHERE cmpy_code = currentCompany		 
		ORDER BY reason_code ASC
	
	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2
		SELECT * FROM credreas ORDER BY cmpy_code, reason_code ASC


	LET tmpMsg = "All credreas data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("credreas Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION		


###############################################################
# FUNCTION delete_credreas_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_credreas_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE credreas.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING


	IF gl_setupRec.silentMode = 0 THEN 
		OPEN WINDOW wcredreasImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "credreas Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM credreas
		WHENEVER ERROR STOP
	END IF	

		
	IF sqlca.sqlcode <> 0 THEN
		LET tmpMsg = "Error when trying TO delete all data in the table credreas!"
			CALL fgl_winmessage("Error",tmpMsg,"error")
	ELSE
		IF p_silentMode = 0 THEN --no ui
			LET tmpMsg = "All data in the table credreas where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")
		END IF					
	END IF		

	IF gl_setupRec.silentMode = 0 THEN 
		CLOSE WINDOW wcredreasImport	
	END IF	
	
END FUNCTION	



