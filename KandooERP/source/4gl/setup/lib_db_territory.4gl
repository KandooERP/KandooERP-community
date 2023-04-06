GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getTerritoryCount()
# FUNCTION territoryLookupFilterDataSourceCursor(pRecTerritoryFilter)
# FUNCTION territoryLookupSearchDataSourceCursor(p_RecTerritorySearch)
# FUNCTION TerritoryLookupFilterDataSource(pRecTerritoryFilter)
# FUNCTION territoryLookup_filter(pTerritoryCode)
# FUNCTION import_territory()
# FUNCTION exist_territoryRec(p_cmpy_code, p_terr_code)
# FUNCTION delete_territory_all()
# FUNCTION territoryMenu()						-- Offer different OPTIONS of this library via a menu

# Territoryrecord types
	DEFINE t_recTerritory 
		TYPE AS RECORD
			terr_code LIKE territory.terr_code,
			desc_text LIKE territory.desc_text
		END RECORD 

	DEFINE t_recTerritoryFilter  
		TYPE AS RECORD
			filter_terr_code LIKE territory.terr_code,
			filter_desc_text LIKE territory.desc_text
		END RECORD 

	DEFINE t_recTerritorySearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recTerritory_noCmpyId 
		TYPE AS RECORD 
    terr_code LIKE territory.terr_code,
    desc_text LIKE territory.desc_text,
    terr_type_ind LIKE territory.terr_type_ind,
    area_code  LIKE territory.area_code,
    sale_code  LIKE territory.sale_code
            
	END RECORD	

	
########################################################################################
# FUNCTION territoryMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION territoryMenu()
	MENU
		ON ACTION "Import"
			CALL import_territory()
		ON ACTION "Export"
			CALL unload_territory(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_territory()
		ON ACTION "Delete All"
			CALL delete_territory_all()
		ON ACTION "Count"
			CALL getTerritoryCount() --Count all territoryrows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getTerritoryCount()
#-------------------------------------------------------
# Returns the number of Territoryentries for the current company
########################################################################################
FUNCTION getTerritoryCount()
	DEFINE ret_TerritoryCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Territory CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM territory ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Territory.DECLARE(sqlQuery) #CURSOR FOR getTerritory
	CALL c_Territory.SetResults(ret_TerritoryCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Territory.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_TerritoryCount = -1
	ELSE
		CALL c_Territory.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Territories (territory):", trim(ret_TerritoryCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Territories (territory) Count", tempMsg,"info") 	
	END IF

	RETURN ret_TerritoryCount
END FUNCTION

########################################################################################
# FUNCTION territoryLookupFilterDataSourceCursor(pRecTerritoryFilter)
#-------------------------------------------------------
# Returns the Territorycursor for the lookup query
########################################################################################
FUNCTION territoryLookupFilterDataSourceCursor(pRecTerritoryFilter)
	DEFINE pRecTerritoryFilter OF t_recTerritoryFilter
	DEFINE sqlQuery STRING
	DEFINE c_Territory CURSOR
	
	LET sqlQuery =	"SELECT ",
									"territory.terr_code, ", 
									"territory.desc_text ",
									"FROM territory ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecTerritoryFilter.filter_terr_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND terr_code LIKE '", pRecTerritoryFilter.filter_terr_code CLIPPED, "%' "  
	END IF									

	IF pRecTerritoryFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecTerritoryFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY terr_code"

	CALL c_territory.DECLARE(sqlQuery)
		
	RETURN c_territory
END FUNCTION



########################################################################################
# territoryLookupSearchDataSourceCursor(p_RecTerritorySearch)
#-------------------------------------------------------
# Returns the Territorycursor for the lookup query
########################################################################################
FUNCTION territoryLookupSearchDataSourceCursor(p_RecTerritorySearch)
	DEFINE p_RecTerritorySearch OF t_recTerritorySearch  
	DEFINE sqlQuery STRING
	DEFINE c_Territory CURSOR
	
	LET sqlQuery =	"SELECT ",
									"territory.terr_code, ", 
									"territory.desc_text ",
 
									"FROM territory ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecTerritorySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((terr_code LIKE '", p_RecTerritorySearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecTerritorySearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecTerritorySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, " ORDER BY terr_code "

	CALL c_territory.DECLARE(sqlQuery) #CURSOR FOR territory
	
	RETURN c_territory
END FUNCTION


########################################################################################
# FUNCTION TerritoryLookupFilterDataSource(pRecTerritoryFilter)
#-------------------------------------------------------
# CALLS TerritoryLookupFilterDataSourceCursor(pRecTerritoryFilter) with the TerritoryFilter data TO get a CURSOR
# Returns the Territorylist array arrTerritoryList
########################################################################################
FUNCTION TerritoryLookupFilterDataSource(pRecTerritoryFilter)
	DEFINE pRecTerritoryFilter OF t_recTerritoryFilter
	DEFINE recTerritory OF t_recTerritory
	DEFINE arrTerritoryList DYNAMIC ARRAY OF t_recTerritory
	DEFINE c_Territory CURSOR
	DEFINE retError SMALLINT
		
	CALL TerritoryLookupFilterDataSourceCursor(pRecTerritoryFilter.*) RETURNING c_Territory
	
	CALL arrTerritoryList.CLEAR()

	CALL c_Territory.SetResults(recTerritory.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Territory.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Territory.FetchNext()=0)
		CALL arrTerritoryList.append([recTerritory.terr_code, recTerritory.desc_text])
	END WHILE	

	END IF
	
	IF arrTerritoryList.getSize() = 0 THEN
		ERROR "No territory's found with the specified filter criteria"
	END IF
	
	RETURN arrTerritoryList
END FUNCTION	

########################################################################################
# FUNCTION TerritoryLookupSearchDataSource(pRecTerritoryFilter)
#-------------------------------------------------------
# CALLS TerritoryLookupSearchDataSourceCursor(pRecTerritoryFilter) with the TerritoryFilter data TO get a CURSOR
# Returns the Territorylist array arrTerritoryList
########################################################################################
FUNCTION TerritoryLookupSearchDataSource(p_recTerritorySearch)
	DEFINE p_recTerritorySearch OF t_recTerritorySearch	
	DEFINE recTerritory OF t_recTerritory
	DEFINE arrTerritoryList DYNAMIC ARRAY OF t_recTerritory
	DEFINE c_Territory CURSOR
	DEFINE retError SMALLINT	
	CALL TerritoryLookupSearchDataSourceCursor(p_recTerritorySearch) RETURNING c_Territory
	
	CALL arrTerritoryList.CLEAR()

	CALL c_Territory.SetResults(recTerritory.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Territory.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Territory.FetchNext()=0)
		CALL arrTerritoryList.append([recTerritory.terr_code, recTerritory.desc_text])
	END WHILE	

	END IF
	
	IF arrTerritoryList.getSize() = 0 THEN
		ERROR "No territory's found with the specified filter criteria"
	END IF
	
	RETURN arrTerritoryList
END FUNCTION


########################################################################################
# FUNCTION territoryLookup_filter(pTerritoryCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Territorycode terr_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the TerritoryCode terr_code
#
# Example:
# 			LET pr_Territory.terr_code = TerritoryLookup(pr_Territory.terr_code)
########################################################################################
FUNCTION territoryLookup_filter(pTerritoryCode)
	DEFINE pTerritoryCode LIKE Territory.terr_code
	DEFINE arrTerritoryList DYNAMIC ARRAY OF t_recTerritory
	DEFINE recTerritoryFilter OF t_recTerritoryFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTerritoryLookup WITH FORM "TerritoryLookup_filter"


	CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTerritoryFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTerritoryList TO scTerritoryList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTerritoryCode = arrTerritoryList[idx].terr_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTerritoryFilter.filter_terr_code IS NOT NULL
			OR recTerritoryFilter.filter_desc_text IS NOT NULL

		THEN
			LET recTerritoryFilter.filter_terr_code = NULL
			LET recTerritoryFilter.filter_desc_text = NULL

			CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_terr_code"
		IF recTerritoryFilter.filter_terr_code IS NOT NULL THEN
			LET recTerritoryFilter.filter_terr_code = NULL
			CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recTerritoryFilter.filter_desc_text IS NOT NULL THEN
			LET recTerritoryFilter.filter_desc_text = NULL
			CALL TerritoryLookupFilterDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTerritoryLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTerritoryCode	
END FUNCTION				
		

########################################################################################
# FUNCTION territoryLookup(pTerritoryCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Territorycode terr_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TerritoryLookupSearchDataSource(recTerritoryFilter.*) RETURNING arrTerritoryList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the TerritoryCode terr_code
#
# Example:
# 			LET pr_Territory.terr_code = TerritoryLookup(pr_Territory.terr_code)
########################################################################################
FUNCTION territoryLookup(pTerritoryCode)
	DEFINE pTerritoryCode LIKE Territory.terr_code
	DEFINE arrTerritoryList DYNAMIC ARRAY OF t_recTerritory
	DEFINE recTerritorySearch OF t_recTerritorySearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTerritoryLookup WITH FORM "territoryLookup"

	CALL TerritoryLookupSearchDataSource(recTerritorySearch.*) RETURNING arrTerritoryList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTerritorySearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL TerritoryLookupSearchDataSource(recTerritorySearch.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTerritoryList TO scTerritoryList.* 
		BEFORE ROW
			IF arrTerritoryList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTerritoryCode = arrTerritoryList[idx].terr_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTerritorySearch.filter_any_field IS NOT NULL

		THEN
			LET recTerritorySearch.filter_any_field = NULL

			CALL TerritoryLookupSearchDataSource(recTerritorySearch.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_terr_code"
		IF recTerritorySearch.filter_any_field IS NOT NULL THEN
			LET recTerritorySearch.filter_any_field = NULL
			CALL TerritoryLookupSearchDataSource(recTerritorySearch.*) RETURNING arrTerritoryList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTerritoryLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTerritoryCode	
END FUNCTION				

############################################
# FUNCTION import_territory()
############################################
FUNCTION import_territory()
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
	
	DEFINE rec_territory OF t_recTerritory_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wTerritoryImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Territories List Data (table: territory)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_territory
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_territory(
		
    terr_code CHAR(5),
    desc_text CHAR(30),
    terr_type_ind CHAR(1),
    area_code CHAR(5),
    sale_code CHAR(8)
    
    
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_territory	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wTerritoryImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wTerritoryImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/territory-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_territory
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_territory
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_territory
			LET importReport = importReport, "Code:", trim(rec_territory.terr_code) , "     -     Desc:", trim(rec_territory.desc_text), "\n"
					
			INSERT INTO territory VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_territory.terr_code,
			rec_territory.desc_text,
			rec_territory.terr_type_ind,
			rec_territory.area_code,
			rec_territory.sale_code
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_territory.terr_code) , "     -     Desc:", trim(rec_territory.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wTerritoryImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_territoryRec(p_cmpy_code, p_terr_code)
########################################################
FUNCTION exist_territoryRec(p_cmpy_code, p_terr_code)
	DEFINE p_cmpy_code LIKE territory.cmpy_code
	DEFINE p_terr_code LIKE territory.terr_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM territory
     WHERE cmpy_code = p_cmpy_code
     AND terr_code = p_terr_code

	DROP TABLE temp_territory
	CLOSE WINDOW wTerritoryImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_territory()
###############################################################
FUNCTION unload_territory(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()	
	
	LET unloadFile = "unl/territory-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
	    #cmpy_code,
	    terr_code,
	    desc_text,
	    terr_type_ind,
	    area_code,
	    sale_code		
		FROM territory 
		WHERE cmpy_code = currentCompany	
		ORDER BY cmpy_code, terr_code ASC
	

	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM territory ORDER BY cmpy_code, terr_code ASC


	LET tmpMsg = "All territorydata were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("territory Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_territory_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_territory_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE territory.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wterritoryImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "territory Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing territory table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM territory
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table territory!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table territorywhere deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wTerritoryImport		
END FUNCTION	