############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"




########################################################################################
# FUNCTION journalMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION journalMenu()
	MENU
		ON ACTION "Import"
			CALL import_journal(TRUE,glob_rec_setup_company.cmpy_code)
			
		ON ACTION "Export"
			CALL unload_journal(FALSE,"exp")
			
		ON ACTION "Delete All"
			CALL delete_journal_all()
			
		ON ACTION "Count"
			CALL getJournalCount() --Count all printcodes rows FROM the current company
	
		ON ACTION "Exit"
			EXIT MENU
			
	END MENU
			
END FUNCTION

########################################################################################
# FUNCTION getJournalCount()
#-------------------------------------------------------
# Returns the number of Journal entries for the current company
########################################################################################
FUNCTION getJournalCount()
	DEFINE ret_journalCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_journal CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM journal ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_journal.DECLARE(sqlQuery) #CURSOR FOR getjournal
	CALL c_journal.SetResults(ret_journalCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_journal.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_journalCount = -1
	ELSE
		CALL c_journal.FetchNext()
	END IF

	IF gl_setupRec.ui_mode = UI_ON THEN
		LET tempMsg = "Number of journal:", trim(ret_journalCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("journal Count", tempMsg,"info") 	
	END IF

	RETURN ret_journalCount
END FUNCTION


#######################################################################
# FUNCTION import_journal(p_cmpy_code, p_verbose)
#
#
#######################################################################
FUNCTION import_journal(p_verbose,p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_verbose BOOLEAN
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
	DEFINE p_language_text LIKE language.language_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_journal RECORD 
		jour_code            NCHAR(3),
		desc_text            NCHAR(40),
		gl_flag             NCHAR(1)
	END RECORD	


	IF p_cmpy_code IS NULL THEN
		LET p_cmpy_code = glob_rec_setup_company.cmpy_code
	END IF

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_journal
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_journal(
			cmpy_code            NCHAR(2),
			jour_code            NCHAR(3),
			desc_text            NCHAR(40),
			gl_flag             NCHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_journal	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	
# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF p_cmpy_code IS NOT NULL THEN
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
		CASE 
		WHEN glob_rec_setup_company.country_code = "NUL"
			LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN glob_rec_setup_company.country_code = "0"
			--company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
			#DISPLAY p_name_text,p_country_code,p_country_text TO name_text,country_code,country_text
		END CASE				

		#OPEN WINDOW wtaxImport WITH FORM "per/setup/lib_db_data_import_01"
		#DISPLAY "tax Type Delete" TO header_text
	END IF
--------------------------------------------------------------------------------------------------------------------------------------------------

	IF gl_setupRec.ui_mode = UI_ON THEN
		OPEN WINDOW wjournalImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Journal Type Import" TO header_text
		DISPLAY p_name_text,glob_rec_setup_company.country_code,p_country_text TO name_text,country_code,country_text
	END IF
--------------------------------------------------------------------------------------------------------------------------------------------------
IF cmpy_code_provided = FALSE THEN
		INPUT p_cmpy_code,glob_rec_setup_company.country_code WITHOUT DEFAULTS 
		FROM cmpy_code,country_code 
			AFTER FIELD cmpy_code
				CALL get_company_info (p_cmpy_code) 
				RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
				CASE 
				WHEN glob_rec_setup_company.country_code = "NUL"
					LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN		
				WHEN glob_rec_setup_company.country_code = "0"
					--company code comp_code does NOT exist
					LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN
				OTHERWISE
					LET cmpy_code_provided = TRUE
					DISPLAY p_cmpy_code,p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
					TO cmpy_code,name_text,country_code,country_text,language_code,language_text
				END CASE				
		END INPUT
	ELSE
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
		IF gl_setupRec.ui_mode = UI_ON THEN
			DISPLAY p_cmpy_code,p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
			TO cmpy_code,name_text,country_code,country_text,language_code,language_text
		END IF	
	END IF

	let load_file = "unl/journal-",glob_rec_setup_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",glob_rec_setup_company.country_code
		CALL fgl_winmessage("Journal Table Data load",tmpMsg ,"error")
	ELSE
		#CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_journal
	END IF

	DECLARE load_cur CURSOR FOR SELECT * FROM temp_journal
	LET count_rows_processed = 0
	LET count_rows_inserted = 0
	LET count_insert_errors = 0
	LET count_already_exist = 0
	WHENEVER ERROR CONTINUE  
	FOREACH load_cur INTO rec_journal
  	#DISPLAY rec_journal.*
		LET importReport = importReport, "Code:", trim(rec_journal.jour_code) , "     -     Desc:", trim(rec_journal.desc_text), "\n"
		INSERT INTO journal VALUES(
	  	 	p_cmpy_code,
  		 	rec_journal.jour_code,
  	 		rec_journal.desc_text,
  	 		rec_journal.gl_flag
	  	)
 
		CASE 
 		WHEN STATUS = 0
 			LET count_rows_inserted = count_rows_inserted + 1
 		WHEN STATUS = -268 OR STATUS = -239
 			# duplicate primary key
 			LET importReport = importReport, "Code:", trim(rec_journal.jour_code) , "     -     Desc:", trim(rec_journal.desc_text), " ->DUPLICATE = Ignored !\n"
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
	WHENEVER ERROR STOP

	IF gl_setupRec.ui_mode = UI_ON THEN
	
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
	END IF
	
	
	IF gl_setupRec.ui_mode = UI_ON THEN
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
	END IF
		
	RETURN count_rows_inserted

END FUNCTION

#######################################################################
# FUNCTION exist_journalRec(p_cmpy_code, p_jour_code)
#######################################################################
FUNCTION exist_journalRec(p_cmpy_code, p_jour_code)
	DEFINE p_cmpy_code LIKE journal.cmpy_code
	DEFINE p_jour_code LIKE journal.jour_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM journal 
     WHERE cmpy_code = p_cmpy_code
     AND jour_code = p_jour_code

	#DROP TABLE temp_journal
	#CLOSE WINDOW wjournalImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_journal()
###############################################################
FUNCTION unload_journal(p_ui_mode,p_fileExtension)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()
	LET unloadFile = "unl/journal-", trim(glob_rec_setup_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT 
	    #cmpy_code,
	    jour_code,
	    desc_text,
	    gl_flag
    		 
		FROM journal
		WHERE cmpy_code = currentCompany		 
		ORDER BY cmpy_code, jour_code ASC


	LET unloadFile2 = unloadFile CLIPPED, "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM journal ORDER BY cmpy_code, jour_code ASC
			
	LET tmpMsg = "All Journal data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("Journal Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION		


###############################################################
# FUNCTION delete_journal_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_journal_all()

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING
	
	IF glob_rec_setup_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,glob_rec_setup_company.cmpy_code) THEN	
		#IF NOT exist_company(glob_rec_setup_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
			
			IF gl_setupRec.ui_mode = UI_ON THEN
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			END IF
			
			RETURN
		END IF
		
		LET cmpy_code_provided = TRUE
	ELSE
		LET cmpy_code_provided = FALSE				

		IF gl_setupRec.ui_mode <> UI_ON AND cmpy_code_provided = FALSE THEN
			CALL fgl_winmessage("No valid cmpy_code argument","Function delete_journalAll() was called\nin silent mode without a cmpy_code argument","error")
			RETURN
		END IF

		IF gl_setupRec.ui_mode = UI_ON THEN
		
			OPEN WINDOW wjournalImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "Journal Type Delete" TO header_text
		END IF		
				
	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT glob_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.ui_mode = UI_ON THEN	
			DISPLAY glob_rec_setup_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.ui_mode = UI_ON THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM journal
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.ui_mode = UI_ON THEN --no ui
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table journal!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table journal where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	END IF

	IF gl_setupRec.ui_mode = UI_ON THEN
		CLOSE WINDOW wjournalImport
	END IF
			
END FUNCTION	
