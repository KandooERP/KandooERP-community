GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getPurchTypeCount()
# FUNCTION purchtypeLookupFilterDataSourceCursor(pRecPurchTypeFilter)
# FUNCTION purchtypeLookupSearchDataSourceCursor(p_RecPurchTypeSearch)
# FUNCTION PurchTypeLookupFilterDataSource(pRecPurchTypeFilter)
# FUNCTION purchtypeLookup_filter(pPurchTypeCode)
# FUNCTION import_purchtype()
# FUNCTION exist_purchtypeRec(p_cmpy_code, p_purchtype_code)
# FUNCTION delete_purchtype_all()
# FUNCTION purchTypeMenu()						-- Offer different OPTIONS of this library via a menu

# PurchType record types
	DEFINE t_recPurchType  
		TYPE AS RECORD
			purchtype_code LIKE purchtype.purchtype_code,
			desc_text LIKE purchtype.desc_text
		END RECORD 

	DEFINE t_recPurchTypeFilter  
		TYPE AS RECORD
			filter_purchtype_code LIKE purchtype.purchtype_code,
			filter_desc_text LIKE purchtype.desc_text
		END RECORD 

	DEFINE t_recPurchTypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recPurchType_noCmpyId 
		TYPE AS RECORD 
    purchtype_code LIKE purchtype.purchtype_code,
    desc_text LIKE purchtype.desc_text,
    format_ind LIKE purchtype.format_ind,
    rms_flag LIKE purchtype.rms_flag,
    footer1_text LIKE purchtype.footer1_text,
    footer2_text LIKE purchtype.footer2_text,
    footer3_text LIKE purchtype.footer3_text
	END RECORD	

	
########################################################################################
# FUNCTION purchTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION purchTypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_purchtype()
		ON ACTION "Export"
			CALL unload_purchtype()
		#ON ACTION "Import"
		#	CALL import_purchtype()
		ON ACTION "Delete All"
			CALL delete_purchtype_all()
		ON ACTION "Count"
			CALL getPurchTypeCount() --Count all purchtype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getPurchTypeCount()
#-------------------------------------------------------
# Returns the number of PurchType entries for the current company
########################################################################################
FUNCTION getPurchTypeCount()
	DEFINE ret_PurchTypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_PurchType CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM PurchType ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_PurchType.DECLARE(sqlQuery) #CURSOR FOR getPurchType
	CALL c_PurchType.SetResults(ret_PurchTypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_PurchType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_PurchTypeCount = -1
	ELSE
		CALL c_PurchType.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Purchase Types:", trim(ret_PurchTypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Purchase Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_PurchTypeCount
END FUNCTION

########################################################################################
# FUNCTION purchtypeLookupFilterDataSourceCursor(pRecPurchTypeFilter)
#-------------------------------------------------------
# Returns the PurchType CURSOR for the lookup query
########################################################################################
FUNCTION purchtypeLookupFilterDataSourceCursor(pRecPurchTypeFilter)
	DEFINE pRecPurchTypeFilter OF t_recPurchTypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_PurchType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"purchtype.purchtype_code, ", 
									"purchtype.desc_text ",
									"FROM purchtype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecPurchTypeFilter.filter_purchtype_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND purchtype_code LIKE '", pRecPurchTypeFilter.filter_purchtype_code CLIPPED, "%' "  
	END IF									

	IF pRecPurchTypeFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecPurchTypeFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY purchtype_code"

	CALL c_purchtype.DECLARE(sqlQuery)
		
	RETURN c_purchtype
END FUNCTION



########################################################################################
# purchtypeLookupSearchDataSourceCursor(p_RecPurchTypeSearch)
#-------------------------------------------------------
# Returns the PurchType CURSOR for the lookup query
########################################################################################
FUNCTION purchtypeLookupSearchDataSourceCursor(p_RecPurchTypeSearch)
	DEFINE p_RecPurchTypeSearch OF t_recPurchTypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_PurchType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"purchtype.purchtype_code, ", 
									"purchtype.desc_text ",
 
									"FROM purchtype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecPurchTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((purchtype_code LIKE '", p_RecPurchTypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecPurchTypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecPurchTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY purchtype_code"

	CALL c_purchtype.DECLARE(sqlQuery) #CURSOR FOR purchtype
	
	RETURN c_purchtype
END FUNCTION


########################################################################################
# FUNCTION PurchTypeLookupFilterDataSource(pRecPurchTypeFilter)
#-------------------------------------------------------
# CALLS PurchTypeLookupFilterDataSourceCursor(pRecPurchTypeFilter) with the PurchTypeFilter data TO get a CURSOR
# Returns the PurchType list array arrPurchTypeList
########################################################################################
FUNCTION PurchTypeLookupFilterDataSource(pRecPurchTypeFilter)
	DEFINE pRecPurchTypeFilter OF t_recPurchTypeFilter
	DEFINE recPurchType OF t_recPurchType
	DEFINE arrPurchTypeList DYNAMIC ARRAY OF t_recPurchType 
	DEFINE c_PurchType CURSOR
	DEFINE retError SMALLINT
		
	CALL PurchTypeLookupFilterDataSourceCursor(pRecPurchTypeFilter.*) RETURNING c_PurchType
	
	CALL arrPurchTypeList.CLEAR()

	CALL c_PurchType.SetResults(recPurchType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PurchType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PurchType.FetchNext()=0)
		CALL arrPurchTypeList.append([recPurchType.purchtype_code, recPurchType.desc_text])
	END WHILE	

	END IF
	
	IF arrPurchTypeList.getSize() = 0 THEN
		ERROR "No purchtype's found with the specified filter criteria"
	END IF
	
	RETURN arrPurchTypeList
END FUNCTION	

########################################################################################
# FUNCTION PurchTypeLookupSearchDataSource(pRecPurchTypeFilter)
#-------------------------------------------------------
# CALLS PurchTypeLookupSearchDataSourceCursor(pRecPurchTypeFilter) with the PurchTypeFilter data TO get a CURSOR
# Returns the PurchType list array arrPurchTypeList
########################################################################################
FUNCTION PurchTypeLookupSearchDataSource(p_recPurchTypeSearch)
	DEFINE p_recPurchTypeSearch OF t_recPurchTypeSearch	
	DEFINE recPurchType OF t_recPurchType
	DEFINE arrPurchTypeList DYNAMIC ARRAY OF t_recPurchType 
	DEFINE c_PurchType CURSOR
	DEFINE retError SMALLINT	
	CALL PurchTypeLookupSearchDataSourceCursor(p_recPurchTypeSearch) RETURNING c_PurchType
	
	CALL arrPurchTypeList.CLEAR()

	CALL c_PurchType.SetResults(recPurchType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PurchType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PurchType.FetchNext()=0)
		CALL arrPurchTypeList.append([recPurchType.purchtype_code, recPurchType.desc_text])
	END WHILE	

	END IF
	
	IF arrPurchTypeList.getSize() = 0 THEN
		ERROR "No purchtype's found with the specified filter criteria"
	END IF
	
	RETURN arrPurchTypeList
END FUNCTION


########################################################################################
# FUNCTION purchtypeLookup_filter(pPurchTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PurchType code purchtype_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PurchType Code purchtype_code
#
# Example:
# 			LET pr_PurchType.purchtype_code = PurchTypeLookup(pr_PurchType.purchtype_code)
########################################################################################
FUNCTION purchtypeLookup_filter(pPurchTypeCode)
	DEFINE pPurchTypeCode LIKE PurchType.purchtype_code
	DEFINE arrPurchTypeList DYNAMIC ARRAY OF t_recPurchType
	DEFINE recPurchTypeFilter OF t_recPurchTypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPurchTypeLookup WITH FORM "PurchTypeLookup_filter"


	CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPurchTypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPurchTypeList TO scPurchTypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPurchTypeCode = arrPurchTypeList[idx].purchtype_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPurchTypeFilter.filter_purchtype_code IS NOT NULL
			OR recPurchTypeFilter.filter_desc_text IS NOT NULL

		THEN
			LET recPurchTypeFilter.filter_purchtype_code = NULL
			LET recPurchTypeFilter.filter_desc_text = NULL

			CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_purchtype_code"
		IF recPurchTypeFilter.filter_purchtype_code IS NOT NULL THEN
			LET recPurchTypeFilter.filter_purchtype_code = NULL
			CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recPurchTypeFilter.filter_desc_text IS NOT NULL THEN
			LET recPurchTypeFilter.filter_desc_text = NULL
			CALL PurchTypeLookupFilterDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPurchTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPurchTypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION purchtypeLookup(pPurchTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PurchType code purchtype_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PurchTypeLookupSearchDataSource(recPurchTypeFilter.*) RETURNING arrPurchTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PurchType Code purchtype_code
#
# Example:
# 			LET pr_PurchType.purchtype_code = PurchTypeLookup(pr_PurchType.purchtype_code)
########################################################################################
FUNCTION purchtypeLookup(pPurchTypeCode)
	DEFINE pPurchTypeCode LIKE PurchType.purchtype_code
	DEFINE arrPurchTypeList DYNAMIC ARRAY OF t_recPurchType
	DEFINE recPurchTypeSearch OF t_recPurchTypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPurchTypeLookup WITH FORM "purchtypeLookup"

	CALL PurchTypeLookupSearchDataSource(recPurchTypeSearch.*) RETURNING arrPurchTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPurchTypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL PurchTypeLookupSearchDataSource(recPurchTypeSearch.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPurchTypeList TO scPurchTypeList.* 
		BEFORE ROW
			IF arrPurchTypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPurchTypeCode = arrPurchTypeList[idx].purchtype_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPurchTypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recPurchTypeSearch.filter_any_field = NULL

			CALL PurchTypeLookupSearchDataSource(recPurchTypeSearch.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_purchtype_code"
		IF recPurchTypeSearch.filter_any_field IS NOT NULL THEN
			LET recPurchTypeSearch.filter_any_field = NULL
			CALL PurchTypeLookupSearchDataSource(recPurchTypeSearch.*) RETURNING arrPurchTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPurchTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPurchTypeCode	
END FUNCTION				

############################################
# FUNCTION import_purchtype()
############################################
FUNCTION import_purchtype()
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
	
	DEFINE rec_purchtype OF t_recPurchType_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wPurchTypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Purchase Type List Data (table: purchtype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_purchtype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_purchtype(
	    purchtype_code CHAR(3),
	    desc_text CHAR(30),
	    format_ind CHAR(2),
	    rms_flag CHAR(1),
	    footer1_text CHAR(60),
	    footer2_text CHAR(60),
	    footer3_text CHAR(60)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_purchtype	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wPurchTypeImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wPurchTypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/purchtype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_purchtype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_purchtype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_purchtype
			LET importReport = importReport, "Code:", trim(rec_purchtype.purchtype_code) , "     -     Desc:", trim(rec_purchtype.desc_text), "\n"
					
			INSERT INTO purchtype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_purchtype.*		
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_purchtype.purchtype_code) , "     -     Desc:", trim(rec_purchtype.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wPurchTypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_purchtypeRec(p_cmpy_code, p_purchtype_code)
########################################################
FUNCTION exist_purchtypeRec(p_cmpy_code, p_purchtype_code)
	DEFINE p_cmpy_code LIKE purchtype.cmpy_code
	DEFINE p_purchtype_code LIKE purchtype.purchtype_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM purchtype 
     WHERE cmpy_code = p_cmpy_code
     AND purchtype_code = p_purchtype_code

	DROP TABLE temp_purchtype
	CLOSE WINDOW wPurchTypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_purchtype()
###############################################################
FUNCTION unload_purchtype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/purchtype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM purchtype ORDER BY cmpy_code, purchtype_code ASC
	
	LET tmpMsg = "All purchtype data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("purchtype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_purchtype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_purchtype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE purchtype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wpurchtypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "purchtype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing purchtype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM purchtype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table purchtype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table purchtype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wPurchTypeImport		
END FUNCTION	