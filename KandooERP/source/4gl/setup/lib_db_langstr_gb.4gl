GLOBALS "lib_db_globals.4gl"



	
########################################################################################
# FUNCTION langStrMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION langStrMenu()
	MENU
		ON ACTION "Import"
			CALL import_langstr_gb()
		ON ACTION "Export"
			CALL unload_langstr_gb()
		#ON ACTION "Import"
		#	CALL import_holdreas()
		ON ACTION "Delete All"
			CALL delete_langStr_GB()
		ON ACTION "Count"
			CALL getLangstrCount_gb() --Count all language string rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getlangstrCount_gb()
#-------------------------------------------------------
# Returns the number of Holdreas entries for the current company
########################################################################################
FUNCTION getLangstrCount_gb()
	DEFINE ret_LangstrCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Langstr CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	#note: this needs TO be extended for multiple language tables if we keep this..
# for now, only GB english default support
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM langstr_gb "
									#"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
						

	CALL c_langstr.DECLARE(sqlQuery) #CURSOR FOR getHoldreas
	CALL c_langstr.SetResults(ret_langstrCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_langstr.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_langstrCount = -1
	ELSE
		CALL c_langstr.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Hold Reasons:", trim(ret_langstrCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Hold Reasons Count", tempMsg,"info") 	
	END IF

	RETURN ret_langstrCount
END FUNCTION






###########################################################
# FUNCTION libPopulateStringGBCombo(widget_id)
# - widget_id - IS ID of combobox widget in the form
# Gets all currencies FROM DB AND put it in combobox widget
###########################################################
FUNCTION libPopulateStringGBCombo(widget_id)
	DEFINE widget_id STRING
	DEFINE id LIKE langStr_GB.id
	DEFINE langStr LIKE langStr_GB.langStr
	DEFINE combo_text CHAR(100)
	DEFINE cb ui.Combobox
		LET cb = ui.Combobox.Forname(widget_id)
		DECLARE curr CURSOR FOR SELECT id, langStr FROM langStr_GB ORDER BY langStr
		FOREACH curr INTO id,langStr
			LET combo_text = id CLIPPED, " -- ",langStr CLIPPED
			CALL cb.AddItem(id,combo_text)
		END FOREACH
		CLOSE curr
END FUNCTION
###########################################################
# FUNCTION libStringGBLoad()
# LOAD data FROM unl TO langStr_GB table
###########################################################
FUNCTION libStringGBLoad()
	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM langStr_GB)
	IF STATUS <> NOTFOUND THEN
		IF fgl_winquestion("Delete DB info", "StringGB catalog (langStr_GB table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF
	END IF
	
	DELETE FROM langStr_GB WHERE 1=1
	LOAD FROM "unl/langStr_GB.unl" INSERT INTO langstr_gb
END FUNCTION
#######################################################################
# FUNCTION import_langStr_GB(p_silentMode)
#######################################################################
FUNCTION import_langStr_GB()
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
	
	DEFINE rec_langStr_GB RECORD 
		id            VARCHAR(30),
		langStr            VARCHAR(100)
	END RECORD	
	
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_langstr_gb
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_langstr_gb(
			id            VARCHAR(30),
			langStr       VARCHAR(100)
	)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_langstr_gb	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	


	IF gl_setupRec.silentMode = FALSE THEN

		OPEN WINDOW wlangStr_GBImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "langStr_GB Type Import" TO header_text
	END IF


	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/langStr_GB.unl" INSERT INTO temp_langstr_gb
	#END IF



  DECLARE load_cur CURSOR FOR 
						SELECT *
						FROM temp_langstr_gb

	WHENEVER ERROR CONTINUE						

  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH load_cur INTO rec_langStr_GB
  	#DISPLAY rec_langStr_GB.*

		  	
		IF NOT exist_langStr_GBRec(rec_langStr_GB.id) THEN
			LET importReport = importReport, "Code:", trim(rec_langStr_GB.id) , "     -     Desc:", trim(rec_langStr_GB.langStr), "\n"
					
			INSERT INTO langStr_GB VALUES(
	  	 	rec_langStr_GB.id,
	  	 	rec_langStr_GB.langStr
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
			LET importReport = importReport, "Code:", trim(rec_langStr_GB.id) , "     -     Desc:", trim(rec_langStr_GB.langStr), " ->DUPLICATE = Ignored !\n"
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
		
	RETURN count_rows_inserted

END FUNCTION

#######################################################################
# FUNCTION exist_langStr_GBRec(p_id)
#######################################################################
FUNCTION exist_langStr_GBRec(p_id)
	DEFINE p_id LIKE langStr_GB.id
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM langStr_GB 
     WHERE id = p_id

	#DROP TABLE temp_langstr_gb
	#CLOSE WINDOW wlangStr_GBImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_langStr_GB()
###############################################################
FUNCTION unload_langStr_GB(p_fileExtension)
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/langStr_GB.", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM langStr_GB ORDER BY id ASC
	
	LET tmpMsg = "All langStr_GB data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("langStr_GB Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION		


###############################################################
# FUNCTION delete_langStr_GB()  NOTE: Delete ALL
###############################################################
FUNCTION delete_langStr_GB()

	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	
	IF gl_setupRec.silentMode = FALSE THEN -- ui
			OPEN WINDOW wlangStr_GBImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "langStr_GB Type Delete" TO header_text

		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)

	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM langStr_GB
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.silentMode = FALSE THEN -- ui
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table langStr_GB!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table langStr_GB where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	CLOSE WINDOW wlangStr_GBImport

	END IF

		
END FUNCTION	