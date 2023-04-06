############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"


# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getHoldpayCount()
# FUNCTION HoldpayLookupFilterDataSourceCursor(pRecHoldpayFilter)
# FUNCTION HoldpayLookupSearchDataSourceCursor(p_RecHoldpaySearch)
# FUNCTION HoldpayLookupFilterDataSource(pRecHoldpayFilter)
# FUNCTION HoldpayLookup_filter(pHoldpayCode)
# FUNCTION import_Holdpay(NULL)
# FUNCTION exist_HoldpayRec(p_cmpy_code, p_hold_code)
# FUNCTION delete_Holdpay_all()
# FUNCTION HoldpayMenu()						-- Offer different OPTIONS of this library via a menu

# Holdpay record types
	DEFINE t_recHoldpay  
		TYPE AS RECORD
			hold_code LIKE Holdpay.hold_code,
			hold_text LIKE Holdpay.hold_text
		END RECORD 

	DEFINE t_recHoldpayFilter  
		TYPE AS RECORD
			filter_hold_code LIKE Holdpay.hold_code,
			filter_hold_text LIKE Holdpay.hold_text
		END RECORD 

	DEFINE t_recHoldpaySearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recHoldpay_noCmpyId 
		TYPE AS RECORD 
    hold_code CHAR(2),
    hold_text CHAR(40)
	END RECORD	

	
########################################################################################
# FUNCTION HoldpayMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION HoldpayMenu()
	MENU
		ON ACTION "Import"
			CALL import_Holdpay(NULL)
		ON ACTION "Export"
			CALL unload_Holdpay(UI_ON,NULL)
		#ON ACTION "Import"
		#	CALL import_Holdpay(NULL)
		ON ACTION "Delete All"
			CALL delete_Holdpay_all()
		ON ACTION "Count"
			CALL getHoldpayCount() --Count all Holdpay rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getHoldpayCount()
#-------------------------------------------------------
# Returns the number of Holdpay entries for the current company
########################################################################################
FUNCTION getHoldpayCount()
	DEFINE ret_HoldpayCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Holdpay CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Holdpay ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Holdpay.DECLARE(sqlQuery) #CURSOR FOR getHoldpay
	CALL c_Holdpay.SetResults(ret_HoldpayCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Holdpay.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_HoldpayCount = -1
	ELSE
		CALL c_Holdpay.FetchNext()
	END IF

	IF gl_setupRec.ui_mode = UI_ON THEN
		LET tempMsg = "Number of Holdpay(s):", trim(ret_HoldpayCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Holdpay Count", tempMsg,"info") 	
	END IF

	RETURN ret_HoldpayCount
END FUNCTION

########################################################################################
# FUNCTION HoldpayLookupFilterDataSourceCursor(pRecHoldpayFilter)
#-------------------------------------------------------
# Returns the Holdpay CURSOR for the lookup query
########################################################################################
FUNCTION HoldpayLookupFilterDataSourceCursor(pRecHoldpayFilter)
	DEFINE pRecHoldpayFilter OF t_recHoldpayFilter
	DEFINE sqlQuery STRING
	DEFINE c_Holdpay CURSOR
	
	LET sqlQuery =	"SELECT ",
									"Holdpay.hold_code, ", 
									"Holdpay.hold_text ",
									"FROM Holdpay ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecHoldpayFilter.filter_hold_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND hold_code LIKE '", pRecHoldpayFilter.filter_hold_code CLIPPED, "%' "  
	END IF									

	IF pRecHoldpayFilter.filter_hold_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND hold_text LIKE '", pRecHoldpayFilter.filter_hold_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY hold_code"

	CALL c_Holdpay.DECLARE(sqlQuery)
		
	RETURN c_Holdpay
END FUNCTION



########################################################################################
# HoldpayLookupSearchDataSourceCursor(p_RecHoldpaySearch)
#-------------------------------------------------------
# Returns the Holdpay CURSOR for the lookup query
########################################################################################
FUNCTION HoldpayLookupSearchDataSourceCursor(p_RecHoldpaySearch)
	DEFINE p_RecHoldpaySearch OF t_recHoldpaySearch  
	DEFINE sqlQuery STRING
	DEFINE c_Holdpay CURSOR
	
	LET sqlQuery =	"SELECT ",
									"Holdpay.hold_code, ", 
									"Holdpay.hold_text ",
 
									"FROM Holdpay ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecHoldpaySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((hold_code LIKE '", p_RecHoldpaySearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR hold_text LIKE '",   p_RecHoldpaySearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecHoldpaySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY hold_code"

	CALL c_Holdpay.DECLARE(sqlQuery) #CURSOR FOR Holdpay
	
	RETURN c_Holdpay
END FUNCTION


########################################################################################
# FUNCTION HoldpayLookupFilterDataSource(pRecHoldpayFilter)
#-------------------------------------------------------
# CALLS HoldpayLookupFilterDataSourceCursor(pRecHoldpayFilter) with the HoldpayFilter data TO get a CURSOR
# Returns the Holdpay list array arrHoldpayList
########################################################################################
FUNCTION HoldpayLookupFilterDataSource(pRecHoldpayFilter)
	DEFINE pRecHoldpayFilter OF t_recHoldpayFilter
	DEFINE recHoldpay OF t_recHoldpay
	DEFINE arrHoldpayList DYNAMIC ARRAY OF t_recHoldpay 
	DEFINE c_Holdpay CURSOR
	DEFINE retError SMALLINT
		
	CALL HoldpayLookupFilterDataSourceCursor(pRecHoldpayFilter.*) RETURNING c_Holdpay
	
	CALL arrHoldpayList.CLEAR()

	CALL c_Holdpay.SetResults(recHoldpay.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Holdpay.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Holdpay.FetchNext()=0)
		CALL arrHoldpayList.append([recHoldpay.hold_code, recHoldpay.hold_text])
	END WHILE	

	END IF
	
	IF arrHoldpayList.getSize() = 0 THEN
		ERROR "No Holdpay's found with the specified filter criteria"
	END IF
	
	RETURN arrHoldpayList
END FUNCTION	

########################################################################################
# FUNCTION HoldpayLookupSearchDataSource(pRecHoldpayFilter)
#-------------------------------------------------------
# CALLS HoldpayLookupSearchDataSourceCursor(pRecHoldpayFilter) with the HoldpayFilter data TO get a CURSOR
# Returns the Holdpay list array arrHoldpayList
########################################################################################
FUNCTION HoldpayLookupSearchDataSource(p_recHoldpaySearch)
	DEFINE p_recHoldpaySearch OF t_recHoldpaySearch	
	DEFINE recHoldpay OF t_recHoldpay
	DEFINE arrHoldpayList DYNAMIC ARRAY OF t_recHoldpay 
	DEFINE c_Holdpay CURSOR
	DEFINE retError SMALLINT	
	CALL HoldpayLookupSearchDataSourceCursor(p_recHoldpaySearch) RETURNING c_Holdpay
	
	CALL arrHoldpayList.CLEAR()

	CALL c_Holdpay.SetResults(recHoldpay.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Holdpay.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Holdpay.FetchNext()=0)
		CALL arrHoldpayList.append([recHoldpay.hold_code, recHoldpay.hold_text])
	END WHILE	

	END IF
	
	IF arrHoldpayList.getSize() = 0 THEN
		ERROR "No Holdpay's found with the specified filter criteria"
	END IF
	
	RETURN arrHoldpayList
END FUNCTION


########################################################################################
# FUNCTION HoldpayLookup_filter(pHoldpayCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Holdpay code hold_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Holdpay Code hold_code
#
# Example:
# 			LET pr_Holdpay.hold_code = HoldpayLookup(pr_Holdpay.hold_code)
########################################################################################
FUNCTION HoldpayLookup_filter(pHoldpayCode)
	DEFINE pHoldpayCode LIKE Holdpay.hold_code
	DEFINE arrHoldpayList DYNAMIC ARRAY OF t_recHoldpay
	DEFINE recHoldpayFilter OF t_recHoldpayFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wHoldpayLookup WITH FORM "HoldpayLookup_filter"


	CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recHoldpayFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrHoldpayList TO scHoldpayList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pHoldpayCode = arrHoldpayList[idx].hold_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recHoldpayFilter.filter_hold_code IS NOT NULL
			OR recHoldpayFilter.filter_hold_text IS NOT NULL

		THEN
			LET recHoldpayFilter.filter_hold_code = NULL
			LET recHoldpayFilter.filter_hold_text = NULL

			CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_hold_code"
		IF recHoldpayFilter.filter_hold_code IS NOT NULL THEN
			LET recHoldpayFilter.filter_hold_code = NULL
			CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_hold_text"
		IF recHoldpayFilter.filter_hold_text IS NOT NULL THEN
			LET recHoldpayFilter.filter_hold_text = NULL
			CALL HoldpayLookupFilterDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wHoldpayLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pHoldpayCode	
END FUNCTION				
		

########################################################################################
# FUNCTION HoldpayLookup(pHoldpayCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Holdpay code hold_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL HoldpayLookupSearchDataSource(recHoldpayFilter.*) RETURNING arrHoldpayList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Holdpay Code hold_code
#
# Example:
# 			LET pr_Holdpay.hold_code = HoldpayLookup(pr_Holdpay.hold_code)
########################################################################################
FUNCTION HoldpayLookup(pHoldpayCode)
	DEFINE pHoldpayCode LIKE Holdpay.hold_code
	DEFINE arrHoldpayList DYNAMIC ARRAY OF t_recHoldpay
	DEFINE recHoldpaySearch OF t_recHoldpaySearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wHoldpayLookup WITH FORM "HoldpayLookup"

	CALL HoldpayLookupSearchDataSource(recHoldpaySearch.*) RETURNING arrHoldpayList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recHoldpaySearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL HoldpayLookupSearchDataSource(recHoldpaySearch.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrHoldpayList TO scHoldpayList.* 
		BEFORE ROW
			IF arrHoldpayList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pHoldpayCode = arrHoldpayList[idx].hold_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recHoldpaySearch.filter_any_field IS NOT NULL

		THEN
			LET recHoldpaySearch.filter_any_field = NULL

			CALL HoldpayLookupSearchDataSource(recHoldpaySearch.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_hold_code"
		IF recHoldpaySearch.filter_any_field IS NOT NULL THEN
			LET recHoldpaySearch.filter_any_field = NULL
			CALL HoldpayLookupSearchDataSource(recHoldpaySearch.*) RETURNING arrHoldpayList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wHoldpayLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pHoldpayCode	
END FUNCTION				


############################################
# FUNCTION import_Holdpay(p_cmpy_code)
#
#
############################################
FUNCTION import_Holdpay(p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code
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
	DEFINE p_hold_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	DEFINE rec_Holdpay RECORD LIKE holdpay.* #OF t_recHoldpay_noCmpyId

	IF p_cmpy_code IS NULL THEN
		LET p_cmpy_code = glob_rec_setup_company.cmpy_code
	END IF

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.ui_mode = UI_ON THEN	
		OPEN WINDOW wHoldpayImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Holdpay List Data (table: Holdpay)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_holdpay
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_holdpay(
		cmpy_code NCHAR(2),
		hold_code NCHAR(2),
    hold_text NCHAR(40)
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_holdpay	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF p_cmpy_code IS NOT NULL THEN
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_hold_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text

		CASE 
			WHEN glob_rec_setup_company.country_code = "NUL"
				LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN		
			WHEN glob_rec_setup_company.country_code = "0"
				--company code comp_code does NOT exist
				LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN
			OTHERWISE
				LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.ui_mode = UI_ON THEN	
	#	OPEN WINDOW wHoldpayImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT p_cmpy_code, glob_rec_setup_company.country_code,glob_rec_setup_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (p_cmpy_code)
					RETURNING p_hold_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text

					CASE 
						WHEN glob_rec_setup_company.country_code = "NUL"
							LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN		
						WHEN glob_rec_setup_company.country_code = "0"
							--company code comp_code does NOT exist
							LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN
						OTHERWISE
							LET cmpy_code_provided = TRUE
							DISPLAY p_hold_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text 
							TO company.name_text,country_code,country_text,language_code,language_text
					END CASE 
			END INPUT

		ELSE
			IF gl_setupRec.ui_mode = UI_ON THEN	
				DISPLAY p_cmpy_code TO cmpy_code

				INPUT p_cmpy_code, glob_rec_setup_company.country_code,glob_rec_setup_company.language_code
					WITHOUT DEFAULTS 
					FROM inputRec3.*  
				END INPUT
				
				IF int_flag THEN
					LET int_flag = FALSE
					CLOSE WINDOW wHoldpayImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/holdpay-",glob_rec_setup_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",glob_rec_setup_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_holdpay
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_holdpay
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_Holdpay
			LET importReport = importReport, "Code:", trim(rec_Holdpay.hold_code) , "     -     Desc:", trim(rec_Holdpay.hold_text), "\n"
					
			INSERT INTO Holdpay VALUES(
			p_cmpy_code,
			rec_Holdpay.hold_code,
			rec_Holdpay.hold_text
  	
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_Holdpay.hold_code) , "     -     Desc:", trim(rec_Holdpay.hold_text), " ->DUPLICATE = Ignored !\n"
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

	IF gl_setupRec.ui_mode = UI_ON THEN
			
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wHoldpayImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_HoldpayRec(p_cmpy_code, p_hold_code)
########################################################
FUNCTION exist_HoldpayRec(p_cmpy_code, p_hold_code)
	DEFINE p_cmpy_code LIKE Holdpay.cmpy_code
	DEFINE p_hold_code LIKE Holdpay.hold_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM Holdpay 
     WHERE cmpy_code = p_cmpy_code
     AND hold_code = p_hold_code

	DROP TABLE temp_holdpay
	CLOSE WINDOW wHoldpayImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_Holdpay()
#
#
###############################################################
FUNCTION unload_Holdpay(p_ui_mode,p_fileExtension)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING

	IF p_fileExtension IS NULL THEN
		LET p_fileExtension = ".unl"
	END IF
	
	LET unloadFile = "unl/Holdpay-", trim(glob_rec_setup_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM Holdpay ORDER BY cmpy_code, hold_code ASC
	
	LET tmpMsg = "All Holdpay data were exported/written TO:\n", unloadFile
	IF p_ui_mode THEN
		CALL fgl_winmessage("Holdpay Table Data Unloaded",tmpMsg ,"info")
	ENd IF
		
END FUNCTION
###############################################################
# FUNCTION delete_Holdpay_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_Holdpay_all()
	DEFINE p_ui_mode SMALLINT
	#DEFINE p_cmpy_code LIKE Holdpay.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.ui_mode = UI_ON THEN
		OPEN WINDOW wHoldpayImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Holdpay Type Delete" TO header_text
	END IF

	
	IF glob_rec_setup_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,glob_rec_setup_company.cmpy_code) THEN	
		#IF NOT exist_company(glob_rec_setup_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT glob_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.ui_mode = UI_ON THEN 	
			DISPLAY glob_rec_setup_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.ui_mode = UI_ON THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM Holdpay
		WHENEVER ERROR STOP
	END IF	

		
	IF sqlca.sqlcode <> 0 THEN
		LET tmpMsg = "Error when trying TO delete all data in the table Holdpay!"
			CALL fgl_winmessage("Error",tmpMsg,"error")
	ELSE
		IF p_ui_mode = UI_ON THEN --no ui
			LET tmpMsg = "All data in the table Holdpay where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")
		END IF					
	END IF		


	CLOSE WINDOW wHoldpayImport		
END FUNCTION	