GLOBALS "lib_db_globals.4gl"

# FUNCTION getUomCount()
# FUNCTION uomLookupFilterDataSourceCursor(pRecUomFilter)
# FUNCTION uomLookupSearchDataSourceCursor(p_RecUomSearch)
# FUNCTION UomLookupFilterDataSource(pRecUomFilter)
# FUNCTION uomLookup_filter(pUomCode)
# FUNCTION import_uom()
# FUNCTION exist_uomRec(p_cmpy_code, p_uom_code)
# FUNCTION delete_uom_all()

# Uom record types
	DEFINE t_recUom  
		TYPE AS RECORD
			uom_code LIKE uom.uom_code,
			desc_text LIKE uom.desc_text
		END RECORD 

	DEFINE t_recUomFilter  
		TYPE AS RECORD
			filter_uom_code LIKE uom.uom_code,
			filter_desc_text LIKE uom.desc_text
		END RECORD 

	DEFINE t_recUomSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	
########################################################################################
# FUNCTION uomMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION uomMenu()
	MENU
		ON ACTION "Import"
			CALL import_uom()
		ON ACTION "Export"
			CALL unload_uom()
		#ON ACTION "Import"
		#	CALL import_term()
		ON ACTION "Delete All"
			CALL delete_uom_all()
		ON ACTION "Count"
			CALL getuomCount() --Count all term rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	

########################################################################################
# FUNCTION getUomCount()
#-------------------------------------------------------
# Returns the number of Uom entries for the current company
########################################################################################
FUNCTION getUomCount()
	DEFINE ret_UomCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Uom CURSOR
	DEFINE retError SMALLINT
	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Uom ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Uom.DECLARE(sqlQuery) #CURSOR FOR getUom
	CALL c_Uom.SetResults(ret_UomCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Uom.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_UomCount = -1
	ELSE
		CALL c_Uom.FetchNext()
	END IF

	RETURN ret_UomCount
END FUNCTION

########################################################################################
# FUNCTION uomLookupFilterDataSourceCursor(pRecUomFilter)
#-------------------------------------------------------
# Returns the Uom CURSOR for the lookup query
########################################################################################
FUNCTION uomLookupFilterDataSourceCursor(pRecUomFilter)
	DEFINE pRecUomFilter OF t_recUomFilter
	DEFINE sqlQuery STRING
	DEFINE c_Uom CURSOR
	
	LET sqlQuery =	"SELECT ",
									"uom.uom_code, ", 
									"uom.desc_text ",
									"FROM uom ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecUomFilter.filter_uom_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND uom_code LIKE '", pRecUomFilter.filter_uom_code CLIPPED, "%' "  
	END IF									

	IF pRecUomFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecUomFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY uom_code"

	CALL c_uom.DECLARE(sqlQuery)
		
	RETURN c_uom
END FUNCTION



########################################################################################
# uomLookupSearchDataSourceCursor(p_RecUomSearch)
#-------------------------------------------------------
# Returns the Uom CURSOR for the lookup query
########################################################################################
FUNCTION uomLookupSearchDataSourceCursor(p_RecUomSearch)
	DEFINE p_RecUomSearch OF t_recUomSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Uom CURSOR
	
	LET sqlQuery =	"SELECT ",
									"uom.uom_code, ", 
									"uom.desc_text ",
 
									"FROM uom ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecUomSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((uom_code LIKE '", p_RecUomSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecUomSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecUomSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY uom_code"

	CALL c_uom.DECLARE(sqlQuery) #CURSOR FOR COA
	
	RETURN c_uom
END FUNCTION


########################################################################################
# FUNCTION UomLookupFilterDataSource(pRecUomFilter)
#-------------------------------------------------------
# CALLS UomLookupFilterDataSourceCursor(pRecUomFilter) with the UomFilter data TO get a CURSOR
# Returns the Uom list array arrUomList
########################################################################################
FUNCTION UomLookupFilterDataSource(pRecUomFilter)
	DEFINE pRecUomFilter OF t_recUomFilter
	DEFINE recUom OF t_recUom
	DEFINE arrUomList DYNAMIC ARRAY OF t_recUom 
	DEFINE c_Uom CURSOR
	DEFINE retError SMALLINT
		
	CALL UomLookupFilterDataSourceCursor(pRecUomFilter.*) RETURNING c_Uom
	
	CALL arrUomList.CLEAR()

	CALL c_Uom.SetResults(recUom.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Uom.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Uom.FetchNext()=0)
		CALL arrUomList.append([recUom.uom_code, recUom.desc_text])
	END WHILE	

	END IF
	
	IF arrUomList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrUomList
END FUNCTION	

########################################################################################
# FUNCTION UomLookupSearchDataSource(pRecUomFilter)
#-------------------------------------------------------
# CALLS UomLookupSearchDataSourceCursor(pRecUomFilter) with the UomFilter data TO get a CURSOR
# Returns the Uom list array arrUomList
########################################################################################
FUNCTION UomLookupSearchDataSource(p_recUomSearch)
	DEFINE p_recUomSearch OF t_recUomSearch	
	DEFINE recUom OF t_recUom
	DEFINE arrUomList DYNAMIC ARRAY OF t_recUom 
	DEFINE c_Uom CURSOR
	DEFINE retError SMALLINT	
	CALL UomLookupSearchDataSourceCursor(p_recUomSearch) RETURNING c_Uom
	
	CALL arrUomList.CLEAR()

	CALL c_Uom.SetResults(recUom.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Uom.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Uom.FetchNext()=0)
		CALL arrUomList.append([recUom.uom_code, recUom.desc_text])
	END WHILE	

	END IF
	
	IF arrUomList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrUomList
END FUNCTION


########################################################################################
# FUNCTION uomLookup_filter(pUomCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Uom code uom_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Uom Code uom_code
#
# Example:
# 			LET pr_Uom.uom_code = UomLookup(pr_Uom.uom_code)
########################################################################################
FUNCTION uomLookup_filter(pUomCode)
	DEFINE pUomCode LIKE Uom.uom_code
	DEFINE arrUomList DYNAMIC ARRAY OF t_recUom
	DEFINE recUomFilter OF t_recUomFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wUomLookup WITH FORM "UomLookup_filter"


	CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recUomFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrUomList TO scUomList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pUomCode = arrUomList[idx].uom_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recUomFilter.filter_uom_code IS NOT NULL
			OR recUomFilter.filter_desc_text IS NOT NULL

		THEN
			LET recUomFilter.filter_uom_code = NULL
			LET recUomFilter.filter_desc_text = NULL

			CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_uom_code"
		IF recUomFilter.filter_uom_code IS NOT NULL THEN
			LET recUomFilter.filter_uom_code = NULL
			CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recUomFilter.filter_desc_text IS NOT NULL THEN
			LET recUomFilter.filter_desc_text = NULL
			CALL UomLookupFilterDataSource(recUomFilter.*) RETURNING arrUomList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wUomLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pUomCode	
END FUNCTION				
		

########################################################################################
# FUNCTION uomLookup(pUomCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Uom code uom_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL UomLookupSearchDataSource(recUomFilter.*) RETURNING arrUomList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Uom Code uom_code
#
# Example:
# 			LET pr_Uom.uom_code = UomLookup(pr_Uom.uom_code)
########################################################################################
FUNCTION uomLookup(pUomCode)
	DEFINE pUomCode LIKE Uom.uom_code
	DEFINE arrUomList DYNAMIC ARRAY OF t_recUom
	DEFINE recUomSearch OF t_recUomSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wUomLookup WITH FORM "uomLookup"

	CALL UomLookupSearchDataSource(recUomSearch.*) RETURNING arrUomList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recUomSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL UomLookupSearchDataSource(recUomSearch.*) RETURNING arrUomList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrUomList TO scUomList.* 
		BEFORE ROW
			IF arrUomList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pUomCode = arrUomList[idx].uom_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recUomSearch.filter_any_field IS NOT NULL

		THEN
			LET recUomSearch.filter_any_field = NULL

			CALL UomLookupSearchDataSource(recUomSearch.*) RETURNING arrUomList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_uom_code"
		IF recUomSearch.filter_any_field IS NOT NULL THEN
			LET recUomSearch.filter_any_field = NULL
			CALL UomLookupSearchDataSource(recUomSearch.*) RETURNING arrUomList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wUomLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pUomCode	
END FUNCTION				

############################################
# FUNCTION import_uom()
############################################
FUNCTION import_uom()
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
	
	DEFINE rec_uom RECORD 
		uom_code            CHAR(18),
		desc_text            CHAR(40)
	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_uom
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_uom(
			uom_code            CHAR(18),
			desc_text            CHAR(40)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_uom	#we need TO INITIALIZE it, delete all rows
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
		OPEN WINDOW wUomImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Chart of Accounts Import" TO header_text
	END IF
	
	IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec.*
			
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

		END IF

	
	END IF

	let load_file = "unl/uom-",gl_setupRec_default_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("UOM Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_uom
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_uom
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_uom
			LET importReport = importReport, "Code:", trim(rec_uom.uom_code) , "     -     Desc:", trim(rec_uom.desc_text), "\n"
					
			INSERT INTO uom VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_uom.uom_code,
			rec_uom.desc_text
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_uom.uom_code) , "     -     Desc:", trim(rec_uom.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wUomImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_uomRec(p_cmpy_code, p_uom_code)
########################################################
FUNCTION exist_uomRec(p_cmpy_code, p_uom_code)
	DEFINE p_cmpy_code LIKE uom.cmpy_code
	DEFINE p_uom_code LIKE uom.uom_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM uom 
     WHERE cmpy_code = p_cmpy_code
     AND uom_code = p_uom_code

	DROP TABLE temp_uom
	CLOSE WINDOW wUomImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_uom()
###############################################################
FUNCTION unload_uom(p_fileExtension)
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/uom-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM uom ORDER BY cmpy_code, uom_code ASC
	
	LET tmpMsg = "All UOM data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("UOM Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION

###############################################################
# FUNCTION delete_uom_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_uom_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE uom.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING
	
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

		OPEN WINDOW wuomImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "uom Type Delete" TO header_text
		
				
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
			DELETE FROM uom
		WHENEVER ERROR STOP
	END IF	

		
	IF sqlca.sqlcode <> 0 THEN
		LET tmpMsg = "Error when trying TO delete all data in the table uom!"
			CALL fgl_winmessage("Error",tmpMsg,"error")
	ELSE
		IF p_silentMode = 0 THEN --no ui
			LET tmpMsg = "All data in the table uom where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")
		END IF					
	END IF		


	CLOSE WINDOW wuomImport		
END FUNCTION	