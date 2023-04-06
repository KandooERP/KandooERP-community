GLOBALS "lib_db_globals.4gl"

###########################################################
# FUNCTION libPopulateCurrencyCombo(widget_id)
# - widget_id - IS ID of combobox widget in the form
# Gets all currencies FROM DB AND put it in combobox widget
###########################################################
FUNCTION libPopulateCurrencyCombo(widget_id)
	DEFINE widget_id STRING
	DEFINE curr_code LIKE currency.currency_code
	DEFINE curr_text LIKE currency.desc_text
	DEFINE combo_text CHAR(100)
	DEFINE cb ui.Combobox
		LET cb = ui.Combobox.Forname(widget_id)
		DECLARE curr CURSOR FOR SELECT currency_code, desc_text FROM currency ORDER BY desc_text
		FOREACH curr INTO curr_code,curr_text
			LET combo_text = curr_code CLIPPED, " -- ",curr_text CLIPPED
			CALL cb.AddItem(curr_code,combo_text)
		END FOREACH
		CLOSE curr
END FUNCTION
###########################################################
# FUNCTION libCurrencyLoad()
# LOAD data FROM unl TO currency table
###########################################################
FUNCTION libCurrencyLoad(pOverwrite)
	DEFINE pOverwrite BOOLEAN
	
	IF pOverwrite = TRUE THEN
			DELETE FROM currency WHERE 1=1
	END IF

	SELECT 1 FROM SYSTABLES WHERE tabid = 1 AND EXISTS (SELECT 1 FROM currency)
	IF STATUS <> NOTFOUND THEN
		IF fgl_winquestion("Delete DB info", "Currency catalog (currency table) IS NOT empty.\nAll existent data will be erased.\n\nClick 'No' TO skip.", "No", "Yes|No", "exclamation", 1) = "No" THEN
 			RETURN
 		END IF
	END IF
	
	DELETE FROM currency WHERE 1=1	--delete existing table data
	LOAD FROM "unl/currency.unl" INSERT INTO currency
END FUNCTION
#######################################################################
# FUNCTION import_currency(p_silentMode)
#######################################################################
FUNCTION import_currency()
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
	
	DEFINE rec_currency RECORD 
		currency_code            CHAR(3),
		desc_text            CHAR(30),
		symbol_text            CHAR(3)
	END RECORD	

----------------------------------------------		
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_currency
	IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_currency(
			currency_code            CHAR(3),
			desc_text            CHAR(30),
			symbol_text            CHAR(3)
		)
	END IF

	IF recCount <> 0 THEN  #table exists AND has got data
		DELETE FROM temp_currency	#we need TO INITIALIZE it, delete all rows
	END IF
		
	WHENEVER ERROR STOP	
----------------------------------------------	

	IF gl_setupRec.silentMode = FALSE THEN

		OPEN WINDOW wcurrencyImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "currency Type Import" TO header_text
	END IF


	#IF server_side_file_exists(file_name) THEN
	  LOAD FROM "unl/currency.unl" INSERT INTO temp_currency
	#END IF



  DECLARE load_cur CURSOR FOR 
						SELECT *
						FROM temp_currency

	WHENEVER ERROR CONTINUE						

  LET count_rows_processed = 0
  LET count_rows_inserted = 0
  LET count_insert_errors = 0
  LET count_already_exist = 0
  
  FOREACH load_cur INTO rec_currency
  	#DISPLAY rec_currency.*

		  	
		IF NOT exist_currencyRec(rec_currency.currency_code) THEN
			LET importReport = importReport, "Code:", trim(rec_currency.currency_code) , "     -     Desc:", trim(rec_currency.desc_text), "\n"
					
			INSERT INTO currency VALUES(
	  	 	rec_currency.currency_code,
	  	 	rec_currency.desc_text,
	  	 	rec_currency.symbol_text
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
			LET importReport = importReport, "Code:", trim(rec_currency.currency_code) , "     -     Desc:", trim(rec_currency.desc_text), " ->DUPLICATE = Ignored !\n"
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
# FUNCTION exist_currencyRec(p_currency_code)
#######################################################################
FUNCTION exist_currencyRec(p_currency_code)
	DEFINE p_currency_code LIKE currency.currency_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM currency 
     WHERE currency_code = p_currency_code

	#DROP TABLE temp_currency
	#CLOSE WINDOW wcurrencyImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_currency()
###############################################################
FUNCTION unload_currency(p_fileExtension)
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/currency.", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM currency ORDER BY currency_code ASC
	
	LET tmpMsg = "All currency data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("currency Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION		


###############################################################
# FUNCTION delete_currency()  NOTE: Delete ALL
###############################################################
FUNCTION delete_currency()

	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	
	IF gl_setupRec.silentMode = FALSE THEN -- ui
			OPEN WINDOW wcurrencyImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "currency Type Delete" TO header_text

		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)

	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM currency
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.silentMode = FALSE THEN -- ui
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table currency!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table currency where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	CLOSE WINDOW wcurrencyImport

	END IF

		
END FUNCTION	