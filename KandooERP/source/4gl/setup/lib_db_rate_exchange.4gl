GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getRate_exchangeCount()
# FUNCTION rate_exchangeLookupFilterDataSourceCursor(pRecRate_exchangeFilter)
# FUNCTION rate_exchangeLookupSearchDataSourceCursor(p_RecRate_exchangeSearch)
# FUNCTION Rate_exchangeLookupFilterDataSource(pRecRate_exchangeFilter)
# FUNCTION rate_exchangeLookup_filter(pRate_exchangeCode)
# FUNCTION import_rate_exchange()
# FUNCTION exist_rate_exchangeRec(p_cmpy_code, p_currency_code)
# FUNCTION delete_rate_exchange_all()
# FUNCTION rate_exchangeMenu()						-- Offer different OPTIONS of this library via a menu

# Rate_exchange record types
	DEFINE t_recRate_exchange  
		TYPE AS RECORD
			currency_code LIKE rate_exchange.currency_code,
			start_date LIKE rate_exchange.start_date
		END RECORD 

	DEFINE t_recRate_exchangeFilter  
		TYPE AS RECORD
			filter_currency_code LIKE rate_exchange.currency_code,
			filter_start_date LIKE rate_exchange.start_date
		END RECORD 

	DEFINE t_recRate_exchangeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recRate_exchange_noCmpyId 
		TYPE AS RECORD 
    currency_code LIKE rate_exchange.currency_code,
    start_date LIKE rate_exchange.start_date,
    conv_buy_qty LIKE rate_exchange.conv_buy_qty,
    conv_sell_qty LIKE rate_exchange.conv_sell_qty,
    conv_budg_qty  LIKE rate_exchange.conv_budg_qty
	END RECORD	



########################################################################################
# FUNCTION setup_default_rate_exchange()
#-------------------------------------------------------
# Only used by the SETUP program
########################################################################################
FUNCTION setup_default_rate_exchange()
WHENEVER ERROR CONTINUE
INSERT INTO rate_exchange VALUES(
			gl_setupRec_default_company.cmpy_code, --"QU"
			gl_setupRec_default_company.curr_code,  --
			gl_setupRec.fiscal_startDate,
			1.0,
			1.0,
			1.0)
WHENEVER ERROR STOP						
			
END FUNCTION

########################################################################################
# FUNCTION rate_exchangeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION rate_exchangeMenu()
	MENU
		ON ACTION "Import"
			CALL import_rate_exchange()
		ON ACTION "Export"
			CALL unload_rate_exchange()
		#ON ACTION "Import"
		#	CALL import_rate_exchange()
		ON ACTION "Delete All"
			CALL delete_rate_exchange_all()
		ON ACTION "Count"
			CALL getRate_exchangeCount() --Count all rate_exchange rows FROM the current company
		ON ACTION "DefaultRate"
			CALL setup_default_rate_exchange()	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getRate_exchangeCount()
#-------------------------------------------------------
# Returns the number of Rate_exchange entries for the current company
########################################################################################
FUNCTION getRate_exchangeCount()
	DEFINE ret_Rate_exchangeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Rate_exchange CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Rate_exchange ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Rate_exchange.DECLARE(sqlQuery) #CURSOR FOR getRate_exchange
	CALL c_Rate_exchange.SetResults(ret_Rate_exchangeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Rate_exchange.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_Rate_exchangeCount = -1
	ELSE
		CALL c_Rate_exchange.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Exchange Rate Entries:", trim(ret_Rate_exchangeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Exchange Rate Count", tempMsg,"info") 	
	END IF

	RETURN ret_Rate_exchangeCount
END FUNCTION

########################################################################################
# FUNCTION rate_exchangeLookupFilterDataSourceCursor(pRecRate_exchangeFilter)
#-------------------------------------------------------
# Returns the Rate_exchange CURSOR for the lookup query
########################################################################################
FUNCTION rate_exchangeLookupFilterDataSourceCursor(pRecRate_exchangeFilter)
	DEFINE pRecRate_exchangeFilter OF t_recRate_exchangeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Rate_exchange CURSOR
	
	LET sqlQuery =	"SELECT ",
									"rate_exchange.currency_code, ", 
									"rate_exchange.start_date ",
									"FROM rate_exchange ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecRate_exchangeFilter.filter_currency_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND currency_code LIKE '", pRecRate_exchangeFilter.filter_currency_code CLIPPED, "%' "  
	END IF									

	IF pRecRate_exchangeFilter.filter_start_date IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND start_date LIKE '", pRecRate_exchangeFilter.filter_start_date CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY currency_code"

	CALL c_rate_exchange.DECLARE(sqlQuery)
		
	RETURN c_rate_exchange
END FUNCTION



########################################################################################
# rate_exchangeLookupSearchDataSourceCursor(p_RecRate_exchangeSearch)
#-------------------------------------------------------
# Returns the Rate_exchange CURSOR for the lookup query
########################################################################################
FUNCTION rate_exchangeLookupSearchDataSourceCursor(p_RecRate_exchangeSearch)
	DEFINE p_RecRate_exchangeSearch OF t_recRate_exchangeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Rate_exchange CURSOR
	
	LET sqlQuery =	"SELECT ",
									"rate_exchange.currency_code, ", 
									"rate_exchange.start_date ",
 
									"FROM rate_exchange ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecRate_exchangeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((currency_code LIKE '", p_RecRate_exchangeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR start_date LIKE '",   p_RecRate_exchangeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecRate_exchangeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY currency_code"

	CALL c_rate_exchange.DECLARE(sqlQuery) #CURSOR FOR rate_exchange
	
	RETURN c_rate_exchange
END FUNCTION


########################################################################################
# FUNCTION Rate_exchangeLookupFilterDataSource(pRecRate_exchangeFilter)
#-------------------------------------------------------
# CALLS Rate_exchangeLookupFilterDataSourceCursor(pRecRate_exchangeFilter) with the Rate_exchangeFilter data TO get a CURSOR
# Returns the Rate_exchange list array arrRate_exchangeList
########################################################################################
FUNCTION Rate_exchangeLookupFilterDataSource(pRecRate_exchangeFilter)
	DEFINE pRecRate_exchangeFilter OF t_recRate_exchangeFilter
	DEFINE recRate_exchange OF t_recRate_exchange
	DEFINE arrRate_exchangeList DYNAMIC ARRAY OF t_recRate_exchange 
	DEFINE c_Rate_exchange CURSOR
	DEFINE retError SMALLINT
		
	CALL Rate_exchangeLookupFilterDataSourceCursor(pRecRate_exchangeFilter.*) RETURNING c_Rate_exchange
	
	CALL arrRate_exchangeList.CLEAR()

	CALL c_Rate_exchange.SetResults(recRate_exchange.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Rate_exchange.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Rate_exchange.FetchNext()=0)
		CALL arrRate_exchangeList.append([recRate_exchange.currency_code, recRate_exchange.start_date])
	END WHILE	

	END IF
	
	IF arrRate_exchangeList.getSize() = 0 THEN
		ERROR "No rate_exchange's found with the specified filter criteria"
	END IF
	
	RETURN arrRate_exchangeList
END FUNCTION	

########################################################################################
# FUNCTION Rate_exchangeLookupSearchDataSource(pRecRate_exchangeFilter)
#-------------------------------------------------------
# CALLS Rate_exchangeLookupSearchDataSourceCursor(pRecRate_exchangeFilter) with the Rate_exchangeFilter data TO get a CURSOR
# Returns the Rate_exchange list array arrRate_exchangeList
########################################################################################
FUNCTION Rate_exchangeLookupSearchDataSource(p_recRate_exchangeSearch)
	DEFINE p_recRate_exchangeSearch OF t_recRate_exchangeSearch	
	DEFINE recRate_exchange OF t_recRate_exchange
	DEFINE arrRate_exchangeList DYNAMIC ARRAY OF t_recRate_exchange 
	DEFINE c_Rate_exchange CURSOR
	DEFINE retError SMALLINT	
	CALL Rate_exchangeLookupSearchDataSourceCursor(p_recRate_exchangeSearch) RETURNING c_Rate_exchange
	
	CALL arrRate_exchangeList.CLEAR()

	CALL c_Rate_exchange.SetResults(recRate_exchange.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Rate_exchange.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Rate_exchange.FetchNext()=0)
		CALL arrRate_exchangeList.append([recRate_exchange.currency_code, recRate_exchange.start_date])
	END WHILE	

	END IF
	
	IF arrRate_exchangeList.getSize() = 0 THEN
		ERROR "No rate_exchange's found with the specified filter criteria"
	END IF
	
	RETURN arrRate_exchangeList
END FUNCTION


########################################################################################
# FUNCTION rate_exchangeLookup_filter(pRate_exchangeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Rate_exchange code currency_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Rate_exchange Code currency_code
#
# Example:
# 			LET pr_Rate_exchange.currency_code = Rate_exchangeLookup(pr_Rate_exchange.currency_code)
########################################################################################
FUNCTION rate_exchangeLookup_filter(pRate_exchangeCode)
	DEFINE pRate_exchangeCode LIKE Rate_exchange.currency_code
	DEFINE arrRate_exchangeList DYNAMIC ARRAY OF t_recRate_exchange
	DEFINE recRate_exchangeFilter OF t_recRate_exchangeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRate_exchangeLookup WITH FORM "Rate_exchangeLookup_filter"


	CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRate_exchangeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRate_exchangeList TO scRate_exchangeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRate_exchangeCode = arrRate_exchangeList[idx].currency_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRate_exchangeFilter.filter_currency_code IS NOT NULL
			OR recRate_exchangeFilter.filter_start_date IS NOT NULL

		THEN
			LET recRate_exchangeFilter.filter_currency_code = NULL
			LET recRate_exchangeFilter.filter_start_date = NULL

			CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_currency_code"
		IF recRate_exchangeFilter.filter_currency_code IS NOT NULL THEN
			LET recRate_exchangeFilter.filter_currency_code = NULL
			CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_start_date"
		IF recRate_exchangeFilter.filter_start_date IS NOT NULL THEN
			LET recRate_exchangeFilter.filter_start_date = NULL
			CALL Rate_exchangeLookupFilterDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRate_exchangeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRate_exchangeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION rate_exchangeLookup(pRate_exchangeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Rate_exchange code currency_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Rate_exchangeLookupSearchDataSource(recRate_exchangeFilter.*) RETURNING arrRate_exchangeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Rate_exchange Code currency_code
#
# Example:
# 			LET pr_Rate_exchange.currency_code = Rate_exchangeLookup(pr_Rate_exchange.currency_code)
########################################################################################
FUNCTION rate_exchangeLookup(pRate_exchangeCode)
	DEFINE pRate_exchangeCode LIKE Rate_exchange.currency_code
	DEFINE arrRate_exchangeList DYNAMIC ARRAY OF t_recRate_exchange
	DEFINE recRate_exchangeSearch OF t_recRate_exchangeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRate_exchangeLookup WITH FORM "rate_exchangeLookup"

	CALL Rate_exchangeLookupSearchDataSource(recRate_exchangeSearch.*) RETURNING arrRate_exchangeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRate_exchangeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL Rate_exchangeLookupSearchDataSource(recRate_exchangeSearch.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRate_exchangeList TO scRate_exchangeList.* 
		BEFORE ROW
			IF arrRate_exchangeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRate_exchangeCode = arrRate_exchangeList[idx].currency_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRate_exchangeSearch.filter_any_field IS NOT NULL

		THEN
			LET recRate_exchangeSearch.filter_any_field = NULL

			CALL Rate_exchangeLookupSearchDataSource(recRate_exchangeSearch.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_currency_code"
		IF recRate_exchangeSearch.filter_any_field IS NOT NULL THEN
			LET recRate_exchangeSearch.filter_any_field = NULL
			CALL Rate_exchangeLookupSearchDataSource(recRate_exchangeSearch.*) RETURNING arrRate_exchangeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRate_exchangeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRate_exchangeCode	
END FUNCTION				

############################################
# FUNCTION import_rate_exchange()
############################################
FUNCTION import_rate_exchange()
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
	DEFINE p_start_date LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_rate_exchange OF t_recRate_exchange_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wRate_exchangeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Exchange Rate List Data (table: rate_exchange)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_rate_exchange
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_rate_exchange(
	    currency_code CHAR(3),
	    start_date DATE,
	    conv_buy_qty float,
	    conv_sell_qty float,
	    conv_budg_qty float
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_rate_exchange	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_start_date,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wRate_exchangeImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_start_date,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_start_date,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wRate_exchangeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/rate_exchange-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		LOAD FROM load_file INSERT INTO temp_rate_exchange
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_rate_exchange
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_rate_exchange
			LET importReport = importReport, "Code:", trim(rec_rate_exchange.currency_code) , "     -     Desc:", trim(rec_rate_exchange.start_date), "\n"
					
			INSERT INTO rate_exchange VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_rate_exchange.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_rate_exchange.currency_code) , "     -     Desc:", trim(rec_rate_exchange.start_date), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wRate_exchangeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_rate_exchangeRec(p_cmpy_code, p_currency_code)
########################################################
FUNCTION exist_rate_exchangeRec(p_cmpy_code, p_currency_code)
	DEFINE p_cmpy_code LIKE rate_exchange.cmpy_code
	DEFINE p_currency_code LIKE rate_exchange.currency_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM rate_exchange 
     WHERE cmpy_code = p_cmpy_code
     AND currency_code = p_currency_code

	DROP TABLE temp_rate_exchange
	CLOSE WINDOW wRate_exchangeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_rate_exchange()
###############################################################
FUNCTION unload_rate_exchange(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/rate_exchange-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM rate_exchange ORDER BY cmpy_code, currency_code ASC
	
	LET tmpMsg = "All rate_exchange data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("rate_exchange Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_rate_exchange_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_rate_exchange_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE rate_exchange.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wrate_exchangeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "rate_exchange Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing rate_exchange table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM rate_exchange
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table rate_exchange!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table rate_exchange where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wRate_exchangeImport		
END FUNCTION	