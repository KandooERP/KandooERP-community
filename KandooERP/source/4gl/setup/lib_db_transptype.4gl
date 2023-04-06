GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getTranspTypeCount()
# FUNCTION transptypeLookupFilterDataSourceCursor(pRecTranspTypeFilter)
# FUNCTION transptypeLookupSearchDataSourceCursor(p_RecTranspTypeSearch)
# FUNCTION TranspTypeLookupFilterDataSource(pRecTranspTypeFilter)
# FUNCTION transptypeLookup_filter(pTranspTypeCode)
# FUNCTION import_transptype()
# FUNCTION exist_transptypeRec(p_cmpy_code, p_transp_type_code)
# FUNCTION delete_transptype_all()
# FUNCTION transpTypeMenu()						-- Offer different OPTIONS of this library via a menu

# TranspType record types
	DEFINE t_recTranspType  
		TYPE AS RECORD
			transp_type_code LIKE transptype.transp_type_code,
			desc_text LIKE transptype.desc_text
		END RECORD 

	DEFINE t_recTranspTypeFilter  
		TYPE AS RECORD
			filter_transp_type_code LIKE transptype.transp_type_code,
			filter_desc_text LIKE transptype.desc_text
		END RECORD 

	DEFINE t_recTranspTypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recTranspType_noCmpyId 
		TYPE AS RECORD 
    transp_type_code LIKE transptype.transp_type_code,
    desc_text LIKE transptype.desc_text,
    add_drop_amt LIKE transptype.add_drop_amt
	END RECORD	

	
########################################################################################
# FUNCTION transpTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION transpTypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_transptype()
		ON ACTION "Export"
			CALL unload_transptype()
		#ON ACTION "Import"
		#	CALL import_transptype()
		ON ACTION "Delete All"
			CALL delete_transptype_all()
		ON ACTION "Count"
			CALL getTranspTypeCount() --Count all transptype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getTranspTypeCount()
#-------------------------------------------------------
# Returns the number of TranspType entries for the current company
########################################################################################
FUNCTION getTranspTypeCount()
	DEFINE ret_TranspTypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_TranspType CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM TranspType ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_TranspType.DECLARE(sqlQuery) #CURSOR FOR getTranspType
	CALL c_TranspType.SetResults(ret_TranspTypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_TranspType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_TranspTypeCount = -1
	ELSE
		CALL c_TranspType.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Transp Types (transptype):", trim(ret_TranspTypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Transp Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_TranspTypeCount
END FUNCTION

########################################################################################
# FUNCTION transptypeLookupFilterDataSourceCursor(pRecTranspTypeFilter)
#-------------------------------------------------------
# Returns the TranspType CURSOR for the lookup query
########################################################################################
FUNCTION transptypeLookupFilterDataSourceCursor(pRecTranspTypeFilter)
	DEFINE pRecTranspTypeFilter OF t_recTranspTypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_TranspType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"transptype.transp_type_code, ", 
									"transptype.desc_text ",
									"FROM transptype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecTranspTypeFilter.filter_transp_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND transp_type_code LIKE '", pRecTranspTypeFilter.filter_transp_type_code CLIPPED, "%' "  
	END IF									

	IF pRecTranspTypeFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecTranspTypeFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY transp_type_code"

	CALL c_transptype.DECLARE(sqlQuery)
		
	RETURN c_transptype
END FUNCTION



########################################################################################
# transptypeLookupSearchDataSourceCursor(p_RecTranspTypeSearch)
#-------------------------------------------------------
# Returns the TranspType CURSOR for the lookup query
########################################################################################
FUNCTION transptypeLookupSearchDataSourceCursor(p_RecTranspTypeSearch)
	DEFINE p_RecTranspTypeSearch OF t_recTranspTypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_TranspType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"transptype.transp_type_code, ", 
									"transptype.desc_text ",
 
									"FROM transptype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecTranspTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((transp_type_code LIKE '", p_RecTranspTypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecTranspTypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecTranspTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY transp_type_code"

	CALL c_transptype.DECLARE(sqlQuery) #CURSOR FOR transptype
	
	RETURN c_transptype
END FUNCTION


########################################################################################
# FUNCTION TranspTypeLookupFilterDataSource(pRecTranspTypeFilter)
#-------------------------------------------------------
# CALLS TranspTypeLookupFilterDataSourceCursor(pRecTranspTypeFilter) with the TranspTypeFilter data TO get a CURSOR
# Returns the TranspType list array arrTranspTypeList
########################################################################################
FUNCTION TranspTypeLookupFilterDataSource(pRecTranspTypeFilter)
	DEFINE pRecTranspTypeFilter OF t_recTranspTypeFilter
	DEFINE recTranspType OF t_recTranspType
	DEFINE arrTranspTypeList DYNAMIC ARRAY OF t_recTranspType 
	DEFINE c_TranspType CURSOR
	DEFINE retError SMALLINT
		
	CALL TranspTypeLookupFilterDataSourceCursor(pRecTranspTypeFilter.*) RETURNING c_TranspType
	
	CALL arrTranspTypeList.CLEAR()

	CALL c_TranspType.SetResults(recTranspType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_TranspType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_TranspType.FetchNext()=0)
		CALL arrTranspTypeList.append([recTranspType.transp_type_code, recTranspType.desc_text])
	END WHILE	

	END IF
	
	IF arrTranspTypeList.getSize() = 0 THEN
		ERROR "No transptype's found with the specified filter criteria"
	END IF
	
	RETURN arrTranspTypeList
END FUNCTION	

########################################################################################
# FUNCTION TranspTypeLookupSearchDataSource(pRecTranspTypeFilter)
#-------------------------------------------------------
# CALLS TranspTypeLookupSearchDataSourceCursor(pRecTranspTypeFilter) with the TranspTypeFilter data TO get a CURSOR
# Returns the TranspType list array arrTranspTypeList
########################################################################################
FUNCTION TranspTypeLookupSearchDataSource(p_recTranspTypeSearch)
	DEFINE p_recTranspTypeSearch OF t_recTranspTypeSearch	
	DEFINE recTranspType OF t_recTranspType
	DEFINE arrTranspTypeList DYNAMIC ARRAY OF t_recTranspType 
	DEFINE c_TranspType CURSOR
	DEFINE retError SMALLINT	
	CALL TranspTypeLookupSearchDataSourceCursor(p_recTranspTypeSearch) RETURNING c_TranspType
	
	CALL arrTranspTypeList.CLEAR()

	CALL c_TranspType.SetResults(recTranspType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_TranspType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_TranspType.FetchNext()=0)
		CALL arrTranspTypeList.append([recTranspType.transp_type_code, recTranspType.desc_text])
	END WHILE	

	END IF
	
	IF arrTranspTypeList.getSize() = 0 THEN
		ERROR "No transptype's found with the specified filter criteria"
	END IF
	
	RETURN arrTranspTypeList
END FUNCTION


########################################################################################
# FUNCTION transptypeLookup_filter(pTranspTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required TranspType code transp_type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the TranspType Code transp_type_code
#
# Example:
# 			LET pr_TranspType.transp_type_code = TranspTypeLookup(pr_TranspType.transp_type_code)
########################################################################################
FUNCTION transptypeLookup_filter(pTranspTypeCode)
	DEFINE pTranspTypeCode LIKE TranspType.transp_type_code
	DEFINE arrTranspTypeList DYNAMIC ARRAY OF t_recTranspType
	DEFINE recTranspTypeFilter OF t_recTranspTypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTranspTypeLookup WITH FORM "TranspTypeLookup_filter"


	CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTranspTypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTranspTypeList TO scTranspTypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTranspTypeCode = arrTranspTypeList[idx].transp_type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTranspTypeFilter.filter_transp_type_code IS NOT NULL
			OR recTranspTypeFilter.filter_desc_text IS NOT NULL

		THEN
			LET recTranspTypeFilter.filter_transp_type_code = NULL
			LET recTranspTypeFilter.filter_desc_text = NULL

			CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_transp_type_code"
		IF recTranspTypeFilter.filter_transp_type_code IS NOT NULL THEN
			LET recTranspTypeFilter.filter_transp_type_code = NULL
			CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recTranspTypeFilter.filter_desc_text IS NOT NULL THEN
			LET recTranspTypeFilter.filter_desc_text = NULL
			CALL TranspTypeLookupFilterDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTranspTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTranspTypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION transptypeLookup(pTranspTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required TranspType code transp_type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TranspTypeLookupSearchDataSource(recTranspTypeFilter.*) RETURNING arrTranspTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the TranspType Code transp_type_code
#
# Example:
# 			LET pr_TranspType.transp_type_code = TranspTypeLookup(pr_TranspType.transp_type_code)
########################################################################################
FUNCTION transptypeLookup(pTranspTypeCode)
	DEFINE pTranspTypeCode LIKE TranspType.transp_type_code
	DEFINE arrTranspTypeList DYNAMIC ARRAY OF t_recTranspType
	DEFINE recTranspTypeSearch OF t_recTranspTypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTranspTypeLookup WITH FORM "transptypeLookup"

	CALL TranspTypeLookupSearchDataSource(recTranspTypeSearch.*) RETURNING arrTranspTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTranspTypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL TranspTypeLookupSearchDataSource(recTranspTypeSearch.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTranspTypeList TO scTranspTypeList.* 
		BEFORE ROW
			IF arrTranspTypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTranspTypeCode = arrTranspTypeList[idx].transp_type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTranspTypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recTranspTypeSearch.filter_any_field = NULL

			CALL TranspTypeLookupSearchDataSource(recTranspTypeSearch.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_transp_type_code"
		IF recTranspTypeSearch.filter_any_field IS NOT NULL THEN
			LET recTranspTypeSearch.filter_any_field = NULL
			CALL TranspTypeLookupSearchDataSource(recTranspTypeSearch.*) RETURNING arrTranspTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTranspTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTranspTypeCode	
END FUNCTION				

############################################
# FUNCTION import_transptype()
############################################
FUNCTION import_transptype()
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
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_transptype OF t_recTranspType_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wTranspTypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Transp Type List Data (table: transptype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_transptype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_transptype(
	    #cmpy_code CHAR(2),
	    transp_type_code CHAR(3),
	    desc_text CHAR(40),
	    add_drop_amt DECIMAL(16,4)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_transptype	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wTranspTypeImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wTranspTypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/transptype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_transptype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_transptype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_transptype
			LET importReport = importReport, "Code:", trim(rec_transptype.transp_type_code) , "     -     Desc:", trim(rec_transptype.desc_text), "\n"
					
			INSERT INTO transptype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_transptype.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_transptype.transp_type_code) , "     -     Desc:", trim(rec_transptype.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wTranspTypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_transptypeRec(p_cmpy_code, p_transp_type_code)
########################################################
FUNCTION exist_transptypeRec(p_cmpy_code, p_transp_type_code)
	DEFINE p_cmpy_code LIKE transptype.cmpy_code
	DEFINE p_transp_type_code LIKE transptype.transp_type_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM transptype 
     WHERE cmpy_code = p_cmpy_code
     AND transp_type_code = p_transp_type_code

	DROP TABLE temp_transptype
	CLOSE WINDOW wTranspTypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_transptype()
###############################################################
FUNCTION unload_transptype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/transptype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM transptype ORDER BY cmpy_code, transp_type_code ASC
	
	LET tmpMsg = "All transptype data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("transptype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_transptype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_transptype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE transptype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wtransptypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Transp Type (transptype) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing transptype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM transptype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table transptype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table transptype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wTranspTypeImport		
END FUNCTION	