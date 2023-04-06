GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getHoldreasCount()
# FUNCTION holdreasLookupFilterDataSourceCursor(pRecHoldreasFilter)
# FUNCTION holdreasLookupSearchDataSourceCursor(p_RecHoldreasSearch)
# FUNCTION HoldreasLookupFilterDataSource(pRecHoldreasFilter)
# FUNCTION holdreasLookup_filter(pHoldreasCode)
# FUNCTION import_holdreas()
# FUNCTION exist_holdreasRec(p_cmpy_code, p_hold_code)
# FUNCTION delete_holdreas_all()
# FUNCTION holdReasMenu()						-- Offer different OPTIONS of this library via a menu

# Holdreas record types
	DEFINE t_recHoldreas  
		TYPE AS RECORD
			hold_code LIKE holdreas.hold_code,
			reason_text LIKE holdreas.reason_text
		END RECORD 

	DEFINE t_recHoldreasFilter  
		TYPE AS RECORD
			filter_hold_code LIKE holdreas.hold_code,
			filter_reason_text LIKE holdreas.reason_text
		END RECORD 

	DEFINE t_recHoldreasSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recHoldreas_noCmpyId 
		TYPE AS RECORD 
    hold_code LIKE holdreas.hold_code,
    reason_text LIKE holdreas.reason_text
	END RECORD	

	
########################################################################################
# FUNCTION holdReasMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION holdReasMenu()
	MENU
		ON ACTION "Import"
			CALL import_holdreas()
		ON ACTION "Export"
			CALL unload_holdreas(FALSE,"exp")

			
		#ON ACTION "Import"
		#	CALL import_holdreas()
		ON ACTION "Delete All"
			CALL delete_holdreas_all()
		ON ACTION "Count"
			CALL getHoldreasCount() --Count all holdreas rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getHoldreasCount()
#-------------------------------------------------------
# Returns the number of Holdreas entries for the current company
########################################################################################
FUNCTION getHoldreasCount()
	DEFINE ret_HoldreasCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Holdreas CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM holdreas ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Holdreas.DECLARE(sqlQuery) #CURSOR FOR getHoldreas
	CALL c_Holdreas.SetResults(ret_HoldreasCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Holdreas.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_HoldreasCount = -1
	ELSE
		CALL c_Holdreas.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Hold Reasons:", trim(ret_HoldreasCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Hold Reasons Count", tempMsg,"info") 	
	END IF

	RETURN ret_HoldreasCount
END FUNCTION

########################################################################################
# FUNCTION holdreasLookupFilterDataSourceCursor(pRecHoldreasFilter)
#-------------------------------------------------------
# Returns the Holdreas CURSOR for the lookup query
########################################################################################
FUNCTION holdreasLookupFilterDataSourceCursor(pRecHoldreasFilter)
	DEFINE pRecHoldreasFilter OF t_recHoldreasFilter
	DEFINE sqlQuery STRING
	DEFINE c_Holdreas CURSOR
	
	LET sqlQuery =	"SELECT ",
									"holdreas.hold_code, ", 
									"holdreas.reason_text ",
									"FROM holdreas ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecHoldreasFilter.filter_hold_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND hold_code LIKE '", pRecHoldreasFilter.filter_hold_code CLIPPED, "%' "  
	END IF									

	IF pRecHoldreasFilter.filter_reason_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND reason_text LIKE '", pRecHoldreasFilter.filter_reason_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY hold_code"

	CALL c_holdreas.DECLARE(sqlQuery)
		
	RETURN c_holdreas
END FUNCTION



########################################################################################
# holdreasLookupSearchDataSourceCursor(p_RecHoldreasSearch)
#-------------------------------------------------------
# Returns the Holdreas CURSOR for the lookup query
########################################################################################
FUNCTION holdreasLookupSearchDataSourceCursor(p_RecHoldreasSearch)
	DEFINE p_RecHoldreasSearch OF t_recHoldreasSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Holdreas CURSOR
	
	LET sqlQuery =	"SELECT ",
									"holdreas.hold_code, ", 
									"holdreas.reason_text ",
 
									"FROM holdreas ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecHoldreasSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((hold_code LIKE '", p_RecHoldreasSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR reason_text LIKE '",   p_RecHoldreasSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecHoldreasSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY hold_code"

	CALL c_holdreas.DECLARE(sqlQuery) #CURSOR FOR holdreas
	
	RETURN c_holdreas
END FUNCTION


########################################################################################
# FUNCTION HoldreasLookupFilterDataSource(pRecHoldreasFilter)
#-------------------------------------------------------
# CALLS HoldreasLookupFilterDataSourceCursor(pRecHoldreasFilter) with the HoldreasFilter data TO get a CURSOR
# Returns the Holdreas list array arrHoldreasList
########################################################################################
FUNCTION HoldreasLookupFilterDataSource(pRecHoldreasFilter)
	DEFINE pRecHoldreasFilter OF t_recHoldreasFilter
	DEFINE recHoldreas OF t_recHoldreas
	DEFINE arrHoldreasList DYNAMIC ARRAY OF t_recHoldreas 
	DEFINE c_Holdreas CURSOR
	DEFINE retError SMALLINT
		
	CALL HoldreasLookupFilterDataSourceCursor(pRecHoldreasFilter.*) RETURNING c_Holdreas
	
	CALL arrHoldreasList.CLEAR()

	CALL c_Holdreas.SetResults(recHoldreas.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Holdreas.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Holdreas.FetchNext()=0)
		CALL arrHoldreasList.append([recHoldreas.hold_code, recHoldreas.reason_text])
	END WHILE	

	END IF
	
	IF arrHoldreasList.getSize() = 0 THEN
		ERROR "No holdreas's found with the specified filter criteria"
	END IF
	
	RETURN arrHoldreasList
END FUNCTION	

########################################################################################
# FUNCTION HoldreasLookupSearchDataSource(pRecHoldreasFilter)
#-------------------------------------------------------
# CALLS HoldreasLookupSearchDataSourceCursor(pRecHoldreasFilter) with the HoldreasFilter data TO get a CURSOR
# Returns the Holdreas list array arrHoldreasList
########################################################################################
FUNCTION HoldreasLookupSearchDataSource(p_recHoldreasSearch)
	DEFINE p_recHoldreasSearch OF t_recHoldreasSearch	
	DEFINE recHoldreas OF t_recHoldreas
	DEFINE arrHoldreasList DYNAMIC ARRAY OF t_recHoldreas 
	DEFINE c_Holdreas CURSOR
	DEFINE retError SMALLINT	
	CALL HoldreasLookupSearchDataSourceCursor(p_recHoldreasSearch) RETURNING c_Holdreas
	
	CALL arrHoldreasList.CLEAR()

	CALL c_Holdreas.SetResults(recHoldreas.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Holdreas.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Holdreas.FetchNext()=0)
		CALL arrHoldreasList.append([recHoldreas.hold_code, recHoldreas.reason_text])
	END WHILE	

	END IF
	
	IF arrHoldreasList.getSize() = 0 THEN
		ERROR "No holdreas's found with the specified filter criteria"
	END IF
	
	RETURN arrHoldreasList
END FUNCTION


########################################################################################
# FUNCTION holdreasLookup_filter(pHoldreasCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Holdreas code hold_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Holdreas Code hold_code
#
# Example:
# 			LET pr_Holdreas.hold_code = HoldreasLookup(pr_Holdreas.hold_code)
########################################################################################
FUNCTION holdreasLookup_filter(pHoldreasCode)
	DEFINE pHoldreasCode LIKE Holdreas.hold_code
	DEFINE arrHoldreasList DYNAMIC ARRAY OF t_recHoldreas
	DEFINE recHoldreasFilter OF t_recHoldreasFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wHoldreasLookup WITH FORM "HoldreasLookup_filter"


	CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recHoldreasFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrHoldreasList TO scHoldreasList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pHoldreasCode = arrHoldreasList[idx].hold_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recHoldreasFilter.filter_hold_code IS NOT NULL
			OR recHoldreasFilter.filter_reason_text IS NOT NULL

		THEN
			LET recHoldreasFilter.filter_hold_code = NULL
			LET recHoldreasFilter.filter_reason_text = NULL

			CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_hold_code"
		IF recHoldreasFilter.filter_hold_code IS NOT NULL THEN
			LET recHoldreasFilter.filter_hold_code = NULL
			CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_reason_text"
		IF recHoldreasFilter.filter_reason_text IS NOT NULL THEN
			LET recHoldreasFilter.filter_reason_text = NULL
			CALL HoldreasLookupFilterDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wHoldreasLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pHoldreasCode	
END FUNCTION				
		

########################################################################################
# FUNCTION holdreasLookup(pHoldreasCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Holdreas code hold_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL HoldreasLookupSearchDataSource(recHoldreasFilter.*) RETURNING arrHoldreasList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Holdreas Code hold_code
#
# Example:
# 			LET pr_Holdreas.hold_code = HoldreasLookup(pr_Holdreas.hold_code)
########################################################################################
FUNCTION holdreasLookup(pHoldreasCode)
	DEFINE pHoldreasCode LIKE Holdreas.hold_code
	DEFINE arrHoldreasList DYNAMIC ARRAY OF t_recHoldreas
	DEFINE recHoldreasSearch OF t_recHoldreasSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wHoldreasLookup WITH FORM "holdreasLookup"

	CALL HoldreasLookupSearchDataSource(recHoldreasSearch.*) RETURNING arrHoldreasList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recHoldreasSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL HoldreasLookupSearchDataSource(recHoldreasSearch.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrHoldreasList TO scHoldreasList.* 
		BEFORE ROW
			IF arrHoldreasList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pHoldreasCode = arrHoldreasList[idx].hold_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recHoldreasSearch.filter_any_field IS NOT NULL

		THEN
			LET recHoldreasSearch.filter_any_field = NULL

			CALL HoldreasLookupSearchDataSource(recHoldreasSearch.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_hold_code"
		IF recHoldreasSearch.filter_any_field IS NOT NULL THEN
			LET recHoldreasSearch.filter_any_field = NULL
			CALL HoldreasLookupSearchDataSource(recHoldreasSearch.*) RETURNING arrHoldreasList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wHoldreasLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pHoldreasCode	
END FUNCTION				

############################################
# FUNCTION import_holdreas()
############################################
FUNCTION import_holdreas()
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
	DEFINE p_reason_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_holdreas OF t_recHoldreas_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wHoldreasImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Hold Reason List Data (table: holdreas)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_holdreas
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_holdreas(
    hold_code CHAR(3),
    reason_text CHAR(30)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_holdreas	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_reason_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wHoldreasImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_reason_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_reason_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wHoldreasImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/holdreas-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_holdreas
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_holdreas
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_holdreas
			LET importReport = importReport, "Code:", trim(rec_holdreas.hold_code) , "     -     Desc:", trim(rec_holdreas.reason_text), "\n"
					
			INSERT INTO holdreas VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_holdreas.hold_code,
			rec_holdreas.reason_text			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_holdreas.hold_code) , "     -     Desc:", trim(rec_holdreas.reason_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wHoldreasImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_holdreasRec(p_cmpy_code, p_hold_code)
########################################################
FUNCTION exist_holdreasRec(p_cmpy_code, p_hold_code)
	DEFINE p_cmpy_code LIKE holdreas.cmpy_code
	DEFINE p_hold_code LIKE holdreas.hold_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM holdreas 
     WHERE cmpy_code = p_cmpy_code
     AND hold_code = p_hold_code

	DROP TABLE temp_holdreas
	CLOSE WINDOW wHoldreasImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_holdreas(p_silentMode,p_fileExtension)
###############################################################
FUNCTION unload_holdreas(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()			
	LET unloadFile = "unl/holdreas-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()	 
	UNLOAD TO unloadFile1 
		SELECT  
	    #cmpy_code CHAR(2),
	    hold_code, # CHAR(3),
	    reason_text # CHAR(30)
		FROM holdreas ORDER BY hold_code ASC

	LET unloadFile = unloadFile CLIPPED, "_all"

	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 	
		SELECT * 
		FROM holdreas ORDER BY cmpy_code, hold_code ASC
	

	
	LET tmpMsg = "All holdreas data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("holdreas Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_holdreas_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_holdreas_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE holdreas.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wholdreasImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "holdreas Type Delete" TO header_text
	END IF

	
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		#IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
		IF NOT db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing holdreas table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM holdreas
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table holdreas!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table holdreas where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wHoldreasImport		
END FUNCTION	