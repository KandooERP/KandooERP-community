GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getPosStationCount()
# FUNCTION posstationLookupFilterDataSourceCursor(precPosStationFilter)
# FUNCTION posstationLookupSearchDataSourceCursor(p_recPosStationSearch)
# FUNCTION posstationLookupFilterDataSource(precPosStationFilter)
# FUNCTION posstationLookup_filter(pPosStationCode)
# FUNCTION import_posstation()
# FUNCTION exist_posstationRec(p_cmpy_code, p_station_code)
# FUNCTION delete_posstation_all()
# FUNCTION posstationMenu()						-- Offer different OPTIONS of this library via a menu

# PosStation record types
	DEFINE t_recPosStation  
		TYPE AS RECORD
			station_code LIKE posstation.station_code,
			station_desc LIKE posstation.station_desc
		END RECORD 

	DEFINE t_recPosStationFilter  
		TYPE AS RECORD
			filter_station_code LIKE posstation.station_code,
			filter_station_desc LIKE posstation.station_desc
		END RECORD 

	DEFINE t_recPosStationSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recPosStation_noCmpyId 
		TYPE AS RECORD 
    station_code LIKE posstation.station_code,
    station_desc LIKE posstation.station_desc,    
    locn_code LIKE posstation.locn_code,
    default_entry LIKE posstation.default_entry,
    learn_mode LIKE posstation.learn_mode,
    last_tran_detl LIKE posstation.last_tran_detl,
    item_quick_entry LIKE posstation.item_quick_entry,
    def_pmnt_type LIKE posstation.def_pmnt_type
    
    
    
	END RECORD	


	
########################################################################################
# FUNCTION posstationMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION posstationMenu()
	MENU
		ON ACTION "Import"
			CALL import_posstation()
		ON ACTION "Export"
			CALL unload_posstation()
		#ON ACTION "Import"
		#	CALL import_posstation()
		ON ACTION "Delete All"
			CALL delete_posstation_all()
		ON ACTION "Count"
			CALL getPosStationCount() --Count all posstation rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getPosStationCount()
#-------------------------------------------------------
# Returns the number of PosStation entries for the current company
########################################################################################
FUNCTION getPosStationCount()
	DEFINE ret_PosStationCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_PosStation CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM posstation ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_PosStation.DECLARE(sqlQuery) #CURSOR FOR getPosStation
	CALL c_PosStation.SetResults(ret_PosStationCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_PosStation.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_PosStationCount = -1
	ELSE
		CALL c_PosStation.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Warehouse Groups:", trim(ret_PosStationCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Warehouse Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_PosStationCount
END FUNCTION

########################################################################################
# FUNCTION posstationLookupFilterDataSourceCursor(precPosStationFilter)
#-------------------------------------------------------
# Returns the PosStation CURSOR for the lookup query
########################################################################################
FUNCTION posstationLookupFilterDataSourceCursor(precPosStationFilter)
	DEFINE precPosStationFilter OF t_recPosStationFilter
	DEFINE sqlQuery STRING
	DEFINE c_PosStation CURSOR
	
	LET sqlQuery =	"SELECT ",
									"posstation.station_code, ", 
									"posstation.station_desc ",
									"FROM posstation ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precPosStationFilter.filter_station_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND station_code LIKE '", precPosStationFilter.filter_station_code CLIPPED, "%' "  
	END IF									

	IF precPosStationFilter.filter_station_desc IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND station_desc LIKE '", precPosStationFilter.filter_station_desc CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY station_code"

	CALL c_posstation.DECLARE(sqlQuery)
		
	RETURN c_posstation
END FUNCTION



########################################################################################
# posstationLookupSearchDataSourceCursor(p_recPosStationSearch)
#-------------------------------------------------------
# Returns the PosStation CURSOR for the lookup query
########################################################################################
FUNCTION posstationLookupSearchDataSourceCursor(p_recPosStationSearch)
	DEFINE p_recPosStationSearch OF t_recPosStationSearch  
	DEFINE sqlQuery STRING
	DEFINE c_PosStation CURSOR
	
	LET sqlQuery =	"SELECT ",
									"posstation.station_code, ", 
									"posstation.station_desc ",
 
									"FROM posstation ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recPosStationSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((station_code LIKE '", p_recPosStationSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR station_desc LIKE '",   p_recPosStationSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recPosStationSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY station_code"

	CALL c_posstation.DECLARE(sqlQuery) #CURSOR FOR posstation
	
	RETURN c_posstation
END FUNCTION


########################################################################################
# FUNCTION PosStationLookupFilterDataSource(precPosStationFilter)
#-------------------------------------------------------
# CALLS PosStationLookupFilterDataSourceCursor(precPosStationFilter) with the PosStationFilter data TO get a CURSOR
# Returns the PosStation list array arrPosStationList
########################################################################################
FUNCTION PosStationLookupFilterDataSource(precPosStationFilter)
	DEFINE precPosStationFilter OF t_recPosStationFilter
	DEFINE recPosStation OF t_recPosStation
	DEFINE arrPosStationList DYNAMIC ARRAY OF t_recPosStation 
	DEFINE c_PosStation CURSOR
	DEFINE retError SMALLINT
		
	CALL PosStationLookupFilterDataSourceCursor(precPosStationFilter.*) RETURNING c_PosStation
	
	CALL arrPosStationList.CLEAR()

	CALL c_PosStation.SetResults(recPosStation.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PosStation.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PosStation.FetchNext()=0)
		CALL arrPosStationList.append([recPosStation.station_code, recPosStation.station_desc])
	END WHILE	

	END IF
	
	IF arrPosStationList.getSize() = 0 THEN
		ERROR "No posstation's found with the specified filter criteria"
	END IF
	
	RETURN arrPosStationList
END FUNCTION	

########################################################################################
# FUNCTION PosStationLookupSearchDataSource(precPosStationFilter)
#-------------------------------------------------------
# CALLS PosStationLookupSearchDataSourceCursor(precPosStationFilter) with the PosStationFilter data TO get a CURSOR
# Returns the PosStation list array arrPosStationList
########################################################################################
FUNCTION PosStationLookupSearchDataSource(p_recPosStationSearch)
	DEFINE p_recPosStationSearch OF t_recPosStationSearch	
	DEFINE recPosStation OF t_recPosStation
	DEFINE arrPosStationList DYNAMIC ARRAY OF t_recPosStation 
	DEFINE c_PosStation CURSOR
	DEFINE retError SMALLINT	
	CALL PosStationLookupSearchDataSourceCursor(p_recPosStationSearch) RETURNING c_PosStation
	
	CALL arrPosStationList.CLEAR()

	CALL c_PosStation.SetResults(recPosStation.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_PosStation.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_PosStation.FetchNext()=0)
		CALL arrPosStationList.append([recPosStation.station_code, recPosStation.station_desc])
	END WHILE	

	END IF
	
	IF arrPosStationList.getSize() = 0 THEN
		ERROR "No posstation's found with the specified filter criteria"
	END IF
	
	RETURN arrPosStationList
END FUNCTION


########################################################################################
# FUNCTION posstationLookup_filter(pPosStationCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PosStation code station_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PosStation Code station_code
#
# Example:
# 			LET pr_PosStation.station_code = PosStationLookup(pr_PosStation.station_code)
########################################################################################
FUNCTION posstationLookup_filter(pPosStationCode)
	DEFINE pPosStationCode LIKE PosStation.station_code
	DEFINE arrPosStationList DYNAMIC ARRAY OF t_recPosStation
	DEFINE recPosStationFilter OF t_recPosStationFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPosStationLookup WITH FORM "PosStationLookup_filter"


	CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPosStationFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPosStationList TO scPosStationList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPosStationCode = arrPosStationList[idx].station_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPosStationFilter.filter_station_code IS NOT NULL
			OR recPosStationFilter.filter_station_desc IS NOT NULL

		THEN
			LET recPosStationFilter.filter_station_code = NULL
			LET recPosStationFilter.filter_station_desc = NULL

			CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_station_code"
		IF recPosStationFilter.filter_station_code IS NOT NULL THEN
			LET recPosStationFilter.filter_station_code = NULL
			CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_station_desc"
		IF recPosStationFilter.filter_station_desc IS NOT NULL THEN
			LET recPosStationFilter.filter_station_desc = NULL
			CALL PosStationLookupFilterDataSource(recPosStationFilter.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPosStationLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPosStationCode	
END FUNCTION				
		

########################################################################################
# FUNCTION posstationLookup(pPosStationCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required PosStation code station_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PosStationLookupSearchDataSource(recPosStationFilter.*) RETURNING arrPosStationList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the PosStation Code station_code
#
# Example:
# 			LET pr_PosStation.station_code = PosStationLookup(pr_PosStation.station_code)
########################################################################################
FUNCTION posstationLookup(pPosStationCode)
	DEFINE pPosStationCode LIKE PosStation.station_code
	DEFINE arrPosStationList DYNAMIC ARRAY OF t_recPosStation
	DEFINE recPosStationSearch OF t_recPosStationSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPosStationLookup WITH FORM "posstationLookup"

	CALL PosStationLookupSearchDataSource(recPosStationSearch.*) RETURNING arrPosStationList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPosStationSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL PosStationLookupSearchDataSource(recPosStationSearch.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPosStationList TO scPosStationList.* 
		BEFORE ROW
			IF arrPosStationList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPosStationCode = arrPosStationList[idx].station_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPosStationSearch.filter_any_field IS NOT NULL

		THEN
			LET recPosStationSearch.filter_any_field = NULL

			CALL PosStationLookupSearchDataSource(recPosStationSearch.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_station_code"
		IF recPosStationSearch.filter_any_field IS NOT NULL THEN
			LET recPosStationSearch.filter_any_field = NULL
			CALL PosStationLookupSearchDataSource(recPosStationSearch.*) RETURNING arrPosStationList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPosStationLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPosStationCode	
END FUNCTION				

############################################
# FUNCTION import_posstation()
############################################
FUNCTION import_posstation()
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
	DEFINE p_station_desc LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_posstation OF t_recPosStation_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wPosStationImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Warehouse Group List Data (table: posstation)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_posstation
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_posstation(	    
    station_code CHAR(8),
    station_desc CHAR(30),
    locn_code CHAR(8),
    default_entry CHAR(1),
    learn_mode CHAR(1),
    last_tran_detl CHAR(35),
    item_quick_entry CHAR(1),
    def_pmnt_type CHAR(2)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_posstation	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_station_desc,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wPosStationImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_station_desc,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_station_desc,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.station_desc,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wPosStationImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/posstation-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_posstation
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_posstation
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_posstation
			LET importReport = importReport, "Code:", trim(rec_posstation.station_code) , "     -     Desc:", trim(rec_posstation.station_desc), "\n"
					
			INSERT INTO posstation VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_posstation.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_posstation.station_code) , "     -     Desc:", trim(rec_posstation.station_desc), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wPosStationImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_posstationRec(p_cmpy_code, p_station_code)
########################################################
FUNCTION exist_posstationRec(p_cmpy_code, p_station_code)
	DEFINE p_cmpy_code LIKE posstation.cmpy_code
	DEFINE p_station_code LIKE posstation.station_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM posstation 
     WHERE cmpy_code = p_cmpy_code
     AND station_code = p_station_code

	DROP TABLE temp_posstation
	CLOSE WINDOW wPosStationImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_posstation()
###############################################################
FUNCTION unload_posstation(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/posstation-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM posstation ORDER BY cmpy_code, station_code ASC
	
	LET tmpMsg = "All posstation data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("posstation Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_posstation_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_posstation_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE posstation.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wposstationImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "posstation Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing posstation table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM posstation
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table posstation!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table posstation where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wPosStationImport		
END FUNCTION	