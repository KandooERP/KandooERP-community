GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getPrintCodesCount()
# FUNCTION printcodesLookupFilterDataSourceCursor(pRecPrintCodesFilter)
# FUNCTION printcodesLookupSearchDataSourceCursor(p_RecPrintCodesSearch)
# FUNCTION PrintCodesLookupFilterDataSource(pRecPrintCodesFilter)
# FUNCTION printcodesLookup_filter(pPrintCodesCode)
# FUNCTION import_printcodes()
# FUNCTION exist_printcodesRec(p_print_code)
# FUNCTION delete_printcodes_all()
# FUNCTION printCodesMenu()						-- Offer different OPTIONS of this library via a menu

# PrintCodes record types
	DEFINE t_recPrintCodes  
		TYPE AS RECORD
			print_code LIKE printcodes.print_code,
			desc_text LIKE printcodes.desc_text
		END RECORD 

	DEFINE t_recPrintCodesFilter  
		TYPE AS RECORD
			filter_print_code LIKE printcodes.print_code,
			filter_desc_text LIKE printcodes.desc_text
		END RECORD 

	DEFINE t_recPrintCodesSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recPrintCodes_noCmpyId 
		TYPE AS RECORD 
    print_code LIKE printcodes.print_code,
    device_ind LIKE printcodes.device_ind,
    width_num LIKE printcodes.width_num,
    length_num LIKE printcodes.length_num,
    compress_1 LIKE printcodes.compress_1,
    compress_2 LIKE printcodes.compress_2,
    compress_3  LIKE printcodes.compress_3,
    compress_4  LIKE printcodes.compress_4,
    compress_5  LIKE printcodes.compress_5,
    compress_6  LIKE printcodes.compress_6,
    compress_7  LIKE printcodes.compress_7,
    compress_8  LIKE printcodes.compress_8,
    compress_9  LIKE printcodes.compress_9,
    compress_10  LIKE printcodes.compress_10,
    normal_1  LIKE printcodes.normal_1,
    normal_2  LIKE printcodes.normal_2,
    normal_3  LIKE printcodes.normal_3,
    normal_4  LIKE printcodes.normal_4,
    normal_5  LIKE printcodes.normal_5,
    normal_6  LIKE printcodes.normal_6,
    normal_7  LIKE printcodes.normal_7,
    normal_8  LIKE printcodes.normal_8,
    normal_9  LIKE printcodes.normal_9,
    normal_10  LIKE printcodes.normal_10,
    compress_11  LIKE printcodes.compress_11,
    compress_12  LIKE printcodes.compress_12,
    compress_13  LIKE printcodes.compress_13,
    compress_14  LIKE printcodes.compress_14,
    compress_15  LIKE printcodes.compress_15,
    compress_16  LIKE printcodes.compress_16,
    compress_17  LIKE printcodes.compress_17,
    compress_18  LIKE printcodes.compress_18,
    compress_19  LIKE printcodes.compress_19,
    compress_20  LIKE printcodes.compress_20,
    print_text  LIKE printcodes.print_text,
    desc_text  LIKE printcodes.desc_text
	END RECORD	

	
########################################################################################
# FUNCTION printCodesMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION printCodesMenu()
	MENU
		ON ACTION "Import"
			CALL import_printcodes()
		ON ACTION "Export"
			CALL unload_printcodes()
		#ON ACTION "Import"
		#	CALL import_printcodes()
		ON ACTION "Delete All"
			CALL delete_printcodes_all()
		ON ACTION "Count"
			CALL getPrintCodesCount() --Count all printcodes rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getPrintCodesCount()
#-------------------------------------------------------
# Returns the number of PrintCodes entries for the current company
########################################################################################
FUNCTION getPrintCodesCount()
	DEFINE ret_PrintCodesCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_PrintCodes CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM PrintCodes "

	CALL c_PrintCodes.DECLARE(sqlQuery) #CURSOR FOR getPrintCodes
	CALL c_PrintCodes.SetResults(ret_PrintCodesCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_PrintCodes.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_PrintCodesCount = -1
	ELSE
		CALL c_PrintCodes.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Print Codes:", trim(ret_PrintCodesCount)  
		CALL fgl_winmessage("Print Codes Count", tempMsg,"info") 	
	END IF

	RETURN ret_PrintCodesCount
END FUNCTION

########################################################################################
# FUNCTION printcodesLookupFilterDataSourceCursor(pRecPrintCodesFilter)
#-------------------------------------------------------
# Returns the PrintCodes CURSOR for the lookup query
########################################################################################
FUNCTION printcodesLookupFilterDataSourceCursor(pRecPrintCodesFilter)
	DEFINE pRecPrintCodesFilter OF t_recPrintCodesFilter
	DEFINE sqlQuery STRING
	DEFINE c_PrintCodes CURSOR
	
	LET sqlQuery =	"SELECT ",
									"printcodes.print_code, ", 
									"printcodes.desc_text ",
									"FROM printcodes "
									
	IF pRecPrintCodesFilter.filter_print_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND print_code LIKE '", pRecPrintCodesFilter.filter_print_code CLIPPED, "%' "  
	END IF									

	IF pRecPrintCodesFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecPrintCodesFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY print_code"

	CALL c_printcodes.DECLARE(sqlQuery)
		
	RETURN c_printcodes
END FUNCTION



########################################################################################
# printcodesLookupSearchDataSourceCursor(p_RecPrintCodesSearch)
#-------------------------------------------------------
# Returns the PrintCodes CURSOR for the lookup query
########################################################################################
FUNCTION printcodesLookupSearchDataSourceCursor(p_RecPrintCodesSearch)
	DEFINE p_RecPrintCodesSearch OF t_recPrintCodesSearch  
	DEFINE sqlQuery STRING
	DEFINE c_PrintCodes CURSOR
	
	LET sqlQuery =	"SELECT ",
									"printcodes.print_code, ", 
									"printcodes.desc_text ",
 
									"FROM printcodes "
	
	IF p_RecPrintCodesSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((print_code LIKE '", p_RecPrintCodesSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecPrintCodesSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecPrintCodesSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY print_code"

	CALL c_printcodes.DECLARE(sqlQuery) #CURSOR FOR printcodes
	
	RETURN c_printcodes
END FUNCTION


########################################################################################
# FUNCTION PrintCodesLookupFilterDataSource(pRecPrintCodesFilter)
#-------------------------------------------------------
# CALLS PrintCodesLookupFilterDataSourceCursor(pRecPrintCodesFilter) with the PrintCodesFilter data TO get a CURSOR
# Returns the PrintCodes list array arrPrintCodesList
########################################################################################
FUNCTION PrintCodesLookupFilterDataSource(pRecPrintCodesFilter)
	DEFINE pRecPrintCodesFilter OF t_recPrintCodesFilter
	DEFINE recPrintCodes OF t_recPrintCodes
	DEFINE arrPrintCodesList DYNAMIC ARRAY OF t_recPrintCodes 
	DEFINE c_PrintCodes CURSOR
	DEFINE retError SMALLINT
		
	CALL PrintCodesLookupFilterDataSourceCursor(pRecPrintCodesFilter.*) RETURNING c_PrintCodes
	
	CALL arrPrintCodesList.CLEAR()

	CALL c_PrintCodes.SetResults(recPrintCodes.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PrintCodes.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PrintCodes.FetchNext()=0)
		CALL arrPrintCodesList.append([recPrintCodes.print_code, recPrintCodes.desc_text])
	END WHILE	

	END IF
	
	IF arrPrintCodesList.getSize() = 0 THEN
		ERROR "No printcodes's found with the specified filter criteria"
	END IF
	
	RETURN arrPrintCodesList
END FUNCTION	

########################################################################################
# FUNCTION PrintCodesLookupSearchDataSource(pRecPrintCodesFilter)
#-------------------------------------------------------
# CALLS PrintCodesLookupSearchDataSourceCursor(pRecPrintCodesFilter) with the PrintCodesFilter data TO get a CURSOR
# Returns the PrintCodes list array arrPrintCodesList
########################################################################################
FUNCTION PrintCodesLookupSearchDataSource(p_recPrintCodesSearch)
	DEFINE p_recPrintCodesSearch OF t_recPrintCodesSearch	
	DEFINE recPrintCodes OF t_recPrintCodes
	DEFINE arrPrintCodesList DYNAMIC ARRAY OF t_recPrintCodes 
	DEFINE c_PrintCodes CURSOR
	DEFINE retError SMALLINT	
	CALL PrintCodesLookupSearchDataSourceCursor(p_recPrintCodesSearch) RETURNING c_PrintCodes
	
	CALL arrPrintCodesList.CLEAR()

	CALL c_PrintCodes.SetResults(recPrintCodes.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PrintCodes.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PrintCodes.FetchNext()=0)
		CALL arrPrintCodesList.append([recPrintCodes.print_code, recPrintCodes.desc_text])
	END WHILE	

	END IF
	
	IF arrPrintCodesList.getSize() = 0 THEN
		ERROR "No printcodes's found with the specified filter criteria"
	END IF
	
	RETURN arrPrintCodesList
END FUNCTION


########################################################################################
# FUNCTION printcodesLookup_filter(pPrintCodesCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PrintCodes code print_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PrintCodes Code print_code
#
# Example:
# 			LET pr_PrintCodes.print_code = PrintCodesLookup(pr_PrintCodes.print_code)
########################################################################################
FUNCTION printcodesLookup_filter(pPrintCodesCode)
	DEFINE pPrintCodesCode LIKE PrintCodes.print_code
	DEFINE arrPrintCodesList DYNAMIC ARRAY OF t_recPrintCodes
	DEFINE recPrintCodesFilter OF t_recPrintCodesFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPrintCodesLookup WITH FORM "PrintCodesLookup_filter"


	CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPrintCodesFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPrintCodesList TO scPrintCodesList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPrintCodesCode = arrPrintCodesList[idx].print_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPrintCodesFilter.filter_print_code IS NOT NULL
			OR recPrintCodesFilter.filter_desc_text IS NOT NULL

		THEN
			LET recPrintCodesFilter.filter_print_code = NULL
			LET recPrintCodesFilter.filter_desc_text = NULL

			CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_print_code"
		IF recPrintCodesFilter.filter_print_code IS NOT NULL THEN
			LET recPrintCodesFilter.filter_print_code = NULL
			CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recPrintCodesFilter.filter_desc_text IS NOT NULL THEN
			LET recPrintCodesFilter.filter_desc_text = NULL
			CALL PrintCodesLookupFilterDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPrintCodesLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPrintCodesCode	
END FUNCTION				
		

########################################################################################
# FUNCTION printcodesLookup(pPrintCodesCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PrintCodes code print_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PrintCodesLookupSearchDataSource(recPrintCodesFilter.*) RETURNING arrPrintCodesList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PrintCodes Code print_code
#
# Example:
# 			LET pr_PrintCodes.print_code = PrintCodesLookup(pr_PrintCodes.print_code)
########################################################################################
FUNCTION printcodesLookup(pPrintCodesCode)
	DEFINE pPrintCodesCode LIKE PrintCodes.print_code
	DEFINE arrPrintCodesList DYNAMIC ARRAY OF t_recPrintCodes
	DEFINE recPrintCodesSearch OF t_recPrintCodesSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPrintCodesLookup WITH FORM "printcodesLookup"

	CALL PrintCodesLookupSearchDataSource(recPrintCodesSearch.*) RETURNING arrPrintCodesList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPrintCodesSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL PrintCodesLookupSearchDataSource(recPrintCodesSearch.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPrintCodesList TO scPrintCodesList.* 
		BEFORE ROW
			IF arrPrintCodesList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPrintCodesCode = arrPrintCodesList[idx].print_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPrintCodesSearch.filter_any_field IS NOT NULL

		THEN
			LET recPrintCodesSearch.filter_any_field = NULL

			CALL PrintCodesLookupSearchDataSource(recPrintCodesSearch.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_print_code"
		IF recPrintCodesSearch.filter_any_field IS NOT NULL THEN
			LET recPrintCodesSearch.filter_any_field = NULL
			CALL PrintCodesLookupSearchDataSource(recPrintCodesSearch.*) RETURNING arrPrintCodesList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPrintCodesLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPrintCodesCode	
END FUNCTION				

############################################
# FUNCTION import_printcodes()
############################################
FUNCTION import_printcodes()
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
	 
	DEFINE cmpy_code_provided BOOLEAN	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_printcodes OF t_recPrintCodes_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wPrintCodesImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Print Codes List Data (table: printcodes)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_printcodes
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_printcodes(
    print_code CHAR(20),
    device_ind CHAR(1),
    width_num SMALLINT,
    length_num SMALLINT,
    compress_1 SMALLINT,
    compress_2 SMALLINT,
    compress_3 SMALLINT,
    compress_4 SMALLINT,
    compress_5 SMALLINT,
    compress_6 SMALLINT,
    compress_7 SMALLINT,
    compress_8 SMALLINT,
    compress_9 SMALLINT,
    compress_10 SMALLINT,
    normal_1 SMALLINT,
    normal_2 SMALLINT,
    normal_3 SMALLINT,
    normal_4 SMALLINT,
    normal_5 SMALLINT,
    normal_6 SMALLINT,
    normal_7 SMALLINT,
    normal_8 SMALLINT,
    normal_9 SMALLINT,
    normal_10 SMALLINT,
    compress_11 SMALLINT,
    compress_12 SMALLINT,
    compress_13 SMALLINT,
    compress_14 SMALLINT,
    compress_15 SMALLINT,
    compress_16 SMALLINT,
    compress_17 SMALLINT,
    compress_18 SMALLINT,
    compress_19 SMALLINT,
    compress_20 SMALLINT,
    print_text CHAR(60),
    desc_text CHAR(30)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_printcodes	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wPrintCodesImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wPrintCodesImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/printcodes-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_printcodes
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_printcodes
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_printcodes
			LET importReport = importReport, "Code:", trim(rec_printcodes.print_code) , "     -     Desc:", trim(rec_printcodes.desc_text), "\n"
					
			INSERT INTO printcodes VALUES(
			rec_printcodes.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_printcodes.print_code) , "     -     Desc:", trim(rec_printcodes.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wPrintCodesImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_printcodesRec(p_cmpy_code, p_print_code)
########################################################
FUNCTION exist_printcodesRec(p_print_code)
	DEFINE p_print_code LIKE printcodes.print_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM printcodes 
     WHERE print_code = p_print_code

	DROP TABLE temp_printcodes
	CLOSE WINDOW wPrintCodesImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_printcodes()
###############################################################
FUNCTION unload_printcodes(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/printcodes-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM printcodes ORDER BY print_code ASC
	
	LET tmpMsg = "All printcodes data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("printcodes Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_printcodes_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_printcodes_all()
	DEFINE p_silentMode BOOLEAN


	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wprintcodesImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Print Codes (printcodes) Delete" TO header_text
	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing printcodes table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM printcodes
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table printcodes!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table printcodes where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wPrintCodesImport		
END FUNCTION	