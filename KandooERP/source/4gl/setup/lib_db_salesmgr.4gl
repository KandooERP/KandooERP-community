GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getSalesmgrCount()
# FUNCTION salesmgrLookupFilterDataSourceCursor(pRecSalesmgrFilter)
# FUNCTION salesmgrLookupSearchDataSourceCursor(p_RecSalesmgrSearch)
# FUNCTION SalesmgrLookupFilterDataSource(pRecSalesmgrFilter)
# FUNCTION salesmgrLookup_filter(pSalesmgrCode)
# FUNCTION import_salesmgr()
# FUNCTION exist_salesmgrRec(p_cmpy_code, p_mgr_code)
# FUNCTION delete_salesmgr_all()
# FUNCTION salesMgrMenu()						-- Offer different OPTIONS of this library via a menu

# Salesmgr record types
	DEFINE t_recSalesmgr  
		TYPE AS RECORD
			mgr_code LIKE salesmgr.mgr_code,
			name_text LIKE salesmgr.name_text
		END RECORD 

	DEFINE t_recSalesmgrFilter  
		TYPE AS RECORD
			filter_mgr_code LIKE salesmgr.mgr_code,
			filter_name_text LIKE salesmgr.name_text
		END RECORD 

	DEFINE t_recSalesmgrSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recSalesmgr_noCmpyId 
		TYPE AS RECORD 
    mgr_code LIKE salesmgr.mgr_code,
    name_text LIKE salesmgr.name_text
	END RECORD	

	
########################################################################################
# FUNCTION salesMgrMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION salesMgrMenu()
	MENU
		ON ACTION "Import"
			CALL import_salesmgr()
		ON ACTION "Export"
			CALL unload_salesmgr(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_salesmgr()
		ON ACTION "Delete All"
			CALL delete_salesmgr_all()
		ON ACTION "Count"
			CALL getSalesmgrCount() --Count all salesmgr rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getSalesmgrCount()
#-------------------------------------------------------
# Returns the number of Salesmgr entries for the current company
########################################################################################
FUNCTION getSalesmgrCount()
	DEFINE ret_SalesmgrCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Salesmgr CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Salesmgr ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Salesmgr.DECLARE(sqlQuery) #CURSOR FOR getSalesmgr
	CALL c_Salesmgr.SetResults(ret_SalesmgrCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Salesmgr.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_SalesmgrCount = -1
	ELSE
		CALL c_Salesmgr.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Sales Managers:", trim(ret_SalesmgrCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Sales Manager Count", tempMsg,"info") 	
	END IF

	RETURN ret_SalesmgrCount
END FUNCTION

########################################################################################
# FUNCTION salesmgrLookupFilterDataSourceCursor(pRecSalesmgrFilter)
#-------------------------------------------------------
# Returns the Salesmgr CURSOR for the lookup query
########################################################################################
FUNCTION salesmgrLookupFilterDataSourceCursor(pRecSalesmgrFilter)
	DEFINE pRecSalesmgrFilter OF t_recSalesmgrFilter
	DEFINE sqlQuery STRING
	DEFINE c_Salesmgr CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salesmgr.mgr_code, ", 
									"salesmgr.name_text ",
									"FROM salesmgr ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecSalesmgrFilter.filter_mgr_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND mgr_code LIKE '", pRecSalesmgrFilter.filter_mgr_code CLIPPED, "%' "  
	END IF									

	IF pRecSalesmgrFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecSalesmgrFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY mgr_code"

	CALL c_salesmgr.DECLARE(sqlQuery)
		
	RETURN c_salesmgr
END FUNCTION



########################################################################################
# salesmgrLookupSearchDataSourceCursor(p_RecSalesmgrSearch)
#-------------------------------------------------------
# Returns the Salesmgr CURSOR for the lookup query
########################################################################################
FUNCTION salesmgrLookupSearchDataSourceCursor(p_RecSalesmgrSearch)
	DEFINE p_RecSalesmgrSearch OF t_recSalesmgrSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Salesmgr CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salesmgr.mgr_code, ", 
									"salesmgr.name_text ",
 
									"FROM salesmgr ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecSalesmgrSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((mgr_code LIKE '", p_RecSalesmgrSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecSalesmgrSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecSalesmgrSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY mgr_code"

	CALL c_salesmgr.DECLARE(sqlQuery) #CURSOR FOR salesmgr
	
	RETURN c_salesmgr
END FUNCTION


########################################################################################
# FUNCTION SalesmgrLookupFilterDataSource(pRecSalesmgrFilter)
#-------------------------------------------------------
# CALLS SalesmgrLookupFilterDataSourceCursor(pRecSalesmgrFilter) with the SalesmgrFilter data TO get a CURSOR
# Returns the Salesmgr list array arrSalesmgrList
########################################################################################
FUNCTION SalesmgrLookupFilterDataSource(pRecSalesmgrFilter)
	DEFINE pRecSalesmgrFilter OF t_recSalesmgrFilter
	DEFINE recSalesmgr OF t_recSalesmgr
	DEFINE arrSalesmgrList DYNAMIC ARRAY OF t_recSalesmgr 
	DEFINE c_Salesmgr CURSOR
	DEFINE retError SMALLINT
		
	CALL SalesmgrLookupFilterDataSourceCursor(pRecSalesmgrFilter.*) RETURNING c_Salesmgr
	
	CALL arrSalesmgrList.CLEAR()

	CALL c_Salesmgr.SetResults(recSalesmgr.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Salesmgr.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Salesmgr.FetchNext()=0)
		CALL arrSalesmgrList.append([recSalesmgr.mgr_code, recSalesmgr.name_text])
	END WHILE	

	END IF
	
	IF arrSalesmgrList.getSize() = 0 THEN
		ERROR "No salesmgr's found with the specified filter criteria"
	END IF
	
	RETURN arrSalesmgrList
END FUNCTION	

########################################################################################
# FUNCTION SalesmgrLookupSearchDataSource(pRecSalesmgrFilter)
#-------------------------------------------------------
# CALLS SalesmgrLookupSearchDataSourceCursor(pRecSalesmgrFilter) with the SalesmgrFilter data TO get a CURSOR
# Returns the Salesmgr list array arrSalesmgrList
########################################################################################
FUNCTION SalesmgrLookupSearchDataSource(p_recSalesmgrSearch)
	DEFINE p_recSalesmgrSearch OF t_recSalesmgrSearch	
	DEFINE recSalesmgr OF t_recSalesmgr
	DEFINE arrSalesmgrList DYNAMIC ARRAY OF t_recSalesmgr 
	DEFINE c_Salesmgr CURSOR
	DEFINE retError SMALLINT	
	CALL SalesmgrLookupSearchDataSourceCursor(p_recSalesmgrSearch) RETURNING c_Salesmgr
	
	CALL arrSalesmgrList.CLEAR()

	CALL c_Salesmgr.SetResults(recSalesmgr.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Salesmgr.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Salesmgr.FetchNext()=0)
		CALL arrSalesmgrList.append([recSalesmgr.mgr_code, recSalesmgr.name_text])
	END WHILE	

	END IF
	
	IF arrSalesmgrList.getSize() = 0 THEN
		ERROR "No salesmgr's found with the specified filter criteria"
	END IF
	
	RETURN arrSalesmgrList
END FUNCTION


########################################################################################
# FUNCTION salesmgrLookup_filter(pSalesmgrCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Salesmgr code mgr_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Salesmgr Code mgr_code
#
# Example:
# 			LET pr_Salesmgr.mgr_code = SalesmgrLookup(pr_Salesmgr.mgr_code)
########################################################################################
FUNCTION salesmgrLookup_filter(pSalesmgrCode)
	DEFINE pSalesmgrCode LIKE Salesmgr.mgr_code
	DEFINE arrSalesmgrList DYNAMIC ARRAY OF t_recSalesmgr
	DEFINE recSalesmgrFilter OF t_recSalesmgrFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSalesmgrLookup WITH FORM "SalesmgrLookup_filter"


	CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSalesmgrFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSalesmgrList TO scSalesmgrList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSalesmgrCode = arrSalesmgrList[idx].mgr_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSalesmgrFilter.filter_mgr_code IS NOT NULL
			OR recSalesmgrFilter.filter_name_text IS NOT NULL

		THEN
			LET recSalesmgrFilter.filter_mgr_code = NULL
			LET recSalesmgrFilter.filter_name_text = NULL

			CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_mgr_code"
		IF recSalesmgrFilter.filter_mgr_code IS NOT NULL THEN
			LET recSalesmgrFilter.filter_mgr_code = NULL
			CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recSalesmgrFilter.filter_name_text IS NOT NULL THEN
			LET recSalesmgrFilter.filter_name_text = NULL
			CALL SalesmgrLookupFilterDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSalesmgrLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSalesmgrCode	
END FUNCTION				
		

########################################################################################
# FUNCTION salesmgrLookup(pSalesmgrCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Salesmgr code mgr_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SalesmgrLookupSearchDataSource(recSalesmgrFilter.*) RETURNING arrSalesmgrList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Salesmgr Code mgr_code
#
# Example:
# 			LET pr_Salesmgr.mgr_code = SalesmgrLookup(pr_Salesmgr.mgr_code)
########################################################################################
FUNCTION salesmgrLookup(pSalesmgrCode)
	DEFINE pSalesmgrCode LIKE Salesmgr.mgr_code
	DEFINE arrSalesmgrList DYNAMIC ARRAY OF t_recSalesmgr
	DEFINE recSalesmgrSearch OF t_recSalesmgrSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSalesmgrLookup WITH FORM "salesmgrLookup"

	CALL SalesmgrLookupSearchDataSource(recSalesmgrSearch.*) RETURNING arrSalesmgrList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSalesmgrSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL SalesmgrLookupSearchDataSource(recSalesmgrSearch.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSalesmgrList TO scSalesmgrList.* 
		BEFORE ROW
			IF arrSalesmgrList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSalesmgrCode = arrSalesmgrList[idx].mgr_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSalesmgrSearch.filter_any_field IS NOT NULL

		THEN
			LET recSalesmgrSearch.filter_any_field = NULL

			CALL SalesmgrLookupSearchDataSource(recSalesmgrSearch.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_mgr_code"
		IF recSalesmgrSearch.filter_any_field IS NOT NULL THEN
			LET recSalesmgrSearch.filter_any_field = NULL
			CALL SalesmgrLookupSearchDataSource(recSalesmgrSearch.*) RETURNING arrSalesmgrList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSalesmgrLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSalesmgrCode	
END FUNCTION				

############################################
# FUNCTION import_salesmgr()
############################################
FUNCTION import_salesmgr()
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
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_salesmgr OF t_recSalesmgr_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wSalesmgrImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Sales Manager List Data (table: salesmgr)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_salesmgr
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_salesmgr(
	    mgr_code CHAR(8),
	    name_text CHAR(30)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_salesmgr	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wSalesmgrImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wSalesmgrImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/salesmgr-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_salesmgr
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_salesmgr
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_salesmgr
			LET importReport = importReport, "Code:", trim(rec_salesmgr.mgr_code) , "     -     Desc:", trim(rec_salesmgr.name_text), "\n"
					
			INSERT INTO salesmgr VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_salesmgr.mgr_code,
			rec_salesmgr.name_text

			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_salesmgr.mgr_code) , "     -     Desc:", trim(rec_salesmgr.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wSalesmgrImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_salesmgrRec(p_cmpy_code, p_mgr_code)
########################################################
FUNCTION exist_salesmgrRec(p_cmpy_code, p_mgr_code)
	DEFINE p_cmpy_code LIKE salesmgr.cmpy_code
	DEFINE p_mgr_code LIKE salesmgr.mgr_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM salesmgr 
     WHERE cmpy_code = p_cmpy_code
     AND mgr_code = p_mgr_code

	DROP TABLE temp_salesmgr
	CLOSE WINDOW wSalesmgrImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_salesmgr()
###############################################################
FUNCTION unload_salesmgr(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()	
	
	LET unloadFile = "unl/salesmgr-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1  
		SELECT 
	    #cmpy_code,
	    mgr_code,
	    name_text		 
		FROM salesmgr 
		WHERE cmpy_code = currentCompany			
		ORDER BY mgr_code ASC



	----	
	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT * 
		FROM salesmgr 
		ORDER BY cmpy_code, mgr_code ASC


	
	LET tmpMsg = "All salesmgr data were exported/written TO:\n", unloadFile1, "AND ", unloadFile2
	CALL fgl_winmessage("salesmgr Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_salesmgr_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_salesmgr_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE salesmgr.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wsalesmgrImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "salesmgr Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing salesmgr table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM salesmgr
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table salesmgr!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table salesmgr where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wSalesmgrImport		
END FUNCTION	