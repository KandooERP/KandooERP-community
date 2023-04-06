GLOBALS "lib_db_globals.4gl"

##########################################################
# FUNCTION libPopulateLanguageCombo(widget_id)
# - widget_id - IS ID of combobox widget in the form
# Gets all languages FROM DB AND put it in combobox widget
##########################################################
FUNCTION libPopulateLanguageCombo(widget_id)
	DEFINE widget_id STRING
	DEFINE lang_code LIKE language.language_code
	DEFINE lang_text LIKE language.language_text
	DEFINE combo_text CHAR(100)
	DEFINE cb ui.Combobox
		LET cb = ui.Combobox.Forname(widget_id)
		DECLARE lang CURSOR FOR SELECT language_code, language_text FROM language ORDER BY language_text
		FOREACH lang INTO lang_code,lang_text
			LET combo_text = lang_code CLIPPED, " -- ",lang_text CLIPPED
			CALL cb.AddItem(lang_code,combo_text)
		END FOREACH
		CLOSE lang
END FUNCTION
#######################################################################
# FUNCTION libGetLangTextByCode(language_code) 
# LOAD language data FROM UNL
#######################################################################
FUNCTION libGetLangTextByCode(lang_code)
	DEFINE lang_code LIKE language.language_code
	DEFINE lang_text LIKE language.language_text
		SELECT language_text INTO lang_text FROM language WHERE language_code = lang_code
		RETURN lang_text
END FUNCTION


#######################################################################
# FUNCTION libLanguageLoad() 
# LOAD language datafrom UNL
#######################################################################
FUNCTION libLanguageLoad(pOverwrite)
	DEFINE col_num INTEGER
	DEFINE lang_rec RECORD LIKE language.*
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM language WHERE 1=1
	END IF
	
		SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM language)
		IF STATUS <> NOTFOUND THEN
			IF fgl_winquestion("Delete DB info", "Language table IS NOT empty.\nAll existent data will be erased.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 				RETURN
 			END IF
		END IF
	
		#check if language table IS modernized (has "national_text" field)
		SELECT ncols INTO col_num FROM SYSTABLES WHERE tabname = "language"
		IF col_num = 5 THEN 
			DELETE FROM language WHERE 1=1  --delete existing table data
			LOAD FROM "unl/language.unl" INSERT INTO language
		END IF
		IF col_num = 4 THEN
			CREATE TEMP TABLE temp_lang(
				language_code        CHAR(3),
				language_text        CHAR(20),
				yes_flag             CHAR(1),
				no_flag              CHAR(1),
				national_text        CHAR(20) 
			)
			LOAD FROM "unl/language.unl" INSERT INTO temp_lang
		
			DELETE FROM language WHERE 1=1
			DECLARE cur CURSOR FOR SELECT language_code,language_text,yes_flag,no_flag FROM temp_lang
			FOREACH cur INTO lang_rec.*
				INSERT INTO language VALUES (lang_rec.*)
			END FOREACH
		END IF
END FUNCTION

FUNCTION createTable_language()
	CREATE TABLE language(
language_code            CHAR(3),
language_text            CHAR(20),
yes_flag            CHAR(1),
no_flag            CHAR(1),
national_text CHAR(20)
)
END FUNCTION

FUNCTION dropTable_language()
	DROP TABLE language
END FUNCTION




#######################################################################
# FUNCTION import_language(p_silentMode)
#######################################################################
FUNCTION import_language()
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
	
	DEFINE rec_language RECORD 
		language_code            CHAR(3),
		language_text            CHAR(20),
		yes_flag            CHAR(1),
		no_flag            CHAR(1),
		national_text CHAR(20)
	END RECORD	
		
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_language
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_language(
			language_code            CHAR(3),
			language_text            CHAR(20),
			yes_flag            CHAR(1),
			no_flag            CHAR(1),
			national_text CHAR(20)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_language	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		


	IF gl_setupRec.silentMode = FALSE THEN

		OPEN WINDOW wlanguageImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "language Type Import" TO header_text
	END IF


	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/language.unl" INSERT INTO temp_language
	#END IF



  DECLARE load_cur CURSOR FOR 
						SELECT *
						FROM temp_language

	WHENEVER ERROR CONTINUE						

  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH load_cur INTO rec_language
  	#DISPLAY rec_language.*

		  	
		IF NOT exist_languageRec(rec_language.language_code) THEN
			LET importReport = importReport, "Code:", trim(rec_language.language_code) , "     -     Desc:", trim(rec_language.language_text), " - ", trim(rec_language.national_text),"\n"
					
			INSERT INTO language VALUES(
	  	 	rec_language.language_code,
	  	 	rec_language.language_text,
	  	 	rec_language.yes_flag,
	  	 	rec_language.no_flag,
    		rec_language.national_text 	 	

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
			LET importReport = importReport, "Code:", trim(rec_language.language_code) , "     -     Desc:", trim(rec_language.language_text), " ->DUPLICATE = Ignored !\n"
			LET count_already_exist = count_already_exist +1
		END IF
		
		LET count_rows_processed= count_rows_processed + 1
	
	END FOREACH

	WHENEVER ERROR STOP


		
	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	IF gl_setupRec.silentMode = FALSE THEN
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
	END IF

	#needs TO be dropped in case the function IS called again
	DROP TABLE temp_language
		
	RETURN count_rows_inserted

END FUNCTION



###############################################################
# FUNCTION unload_language()
###############################################################
FUNCTION unload_language(p_fileExtension)
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/language.", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM language ORDER BY language_code ASC
	
	LET tmpMsg = "All language data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("language Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION		


###############################################################
# FUNCTION delete_language()  NOTE: Delete ALL
###############################################################
FUNCTION delete_language()

	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	
	IF gl_setupRec.silentMode = FALSE THEN -- ui
			OPEN WINDOW wlanguageImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "language Type Delete" TO header_text

		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)

	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM language
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.silentMode = FALSE THEN -- ui
		
		IF sqlca.sqlcode <> 0 AND sqlca.sqlcode <> -206 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table language!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table language where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	CLOSE WINDOW wlanguageImport

	END IF

		
END FUNCTION	


#######################################################################
# FUNCTION exist_languageRec(p_language_code)
#######################################################################
FUNCTION exist_languageRec(p_language_code)
	DEFINE p_language_code LIKE language.language_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM language 
     WHERE language_code = p_language_code

	#DROP TABLE temp_language
	#CLOSE WINDOW wlanguageImport
	
	RETURN recCount

END FUNCTION