GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCarrierCount()
# FUNCTION carrierLookupFilterDataSourceCursor(precCarrierFilter)
# FUNCTION carrierLookupSearchDataSourceCursor(p_recCarrierSearch)
# FUNCTION CarrierLookupFilterDataSource(precCarrierFilter)
# FUNCTION carrierLookup_filter(pCarrierCode)
# FUNCTION import_carrier()
# FUNCTION exist_carrierRec(p_cmpy_code, p_carrier_code)
# FUNCTION delete_carrier_all()
# FUNCTION carrierMenu()						-- Offer different OPTIONS of this library via a menu

# Carrier record types
	DEFINE t_recCarrier  
		TYPE AS RECORD
			carrier_code LIKE carrier.carrier_code,
			name_text LIKE carrier.name_text
		END RECORD 

	DEFINE t_recCarrierFilter  
		TYPE AS RECORD
			filter_carrier_code LIKE carrier.carrier_code,
			filter_name_text LIKE carrier.name_text
		END RECORD 

	DEFINE t_recCarrierSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCarrier_noCmpyId 
		TYPE AS RECORD 
    carrier_code LIKE carrier.carrier_code,
    name_text LIKE carrier.name_text,
    addr1_text LIKE carrier.addr1_text,
    addr2_text LIKE carrier.addr2_text,
    city_text LIKE carrier.city_text,
    state_code LIKE carrier.state_code,
    post_code LIKE carrier.post_code,
    country_code LIKE carrier.country_code,
    next_manifest LIKE carrier.next_manifest,
    next_consign LIKE carrier.next_consign,
    last_consign LIKE carrier.last_consign,
    charge_ind LIKE carrier.charge_ind,
    format_ind LIKE carrier.format_ind    
	END RECORD	


	
########################################################################################
# FUNCTION carrierMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION carrierMenu()
	MENU
		ON ACTION "Import"
			CALL import_carrier()
		ON ACTION "Export"
			CALL unload_carrier()
		#ON ACTION "Import"
		#	CALL import_carrier()
		ON ACTION "Delete All"
			CALL delete_carrier_all()
		ON ACTION "Count"
			CALL getCarrierCount() --Count all carrier rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCarrierCount()
#-------------------------------------------------------
# Returns the number of Carrier entries for the current company
########################################################################################
FUNCTION getCarrierCount()
	DEFINE ret_CarrierCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Carrier CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM carrier ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Carrier.DECLARE(sqlQuery) #CURSOR FOR getCarrier
	CALL c_Carrier.SetResults(ret_CarrierCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Carrier.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CarrierCount = -1
	ELSE
		CALL c_Carrier.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Carriers:", trim(ret_CarrierCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Carrier Count", tempMsg,"info") 	
	END IF

	RETURN ret_CarrierCount
END FUNCTION

########################################################################################
# FUNCTION carrierLookupFilterDataSourceCursor(precCarrierFilter)
#-------------------------------------------------------
# Returns the Carrier CURSOR for the lookup query
########################################################################################
FUNCTION carrierLookupFilterDataSourceCursor(precCarrierFilter)
	DEFINE precCarrierFilter OF t_recCarrierFilter
	DEFINE sqlQuery STRING
	DEFINE c_Carrier CURSOR
	
	LET sqlQuery =	"SELECT ",
									"carrier.carrier_code, ", 
									"carrier.name_text ",
									"FROM carrier ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precCarrierFilter.filter_carrier_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND carrier_code LIKE '", precCarrierFilter.filter_carrier_code CLIPPED, "%' "  
	END IF									

	IF precCarrierFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", precCarrierFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY carrier_code"

	CALL c_carrier.DECLARE(sqlQuery)
		
	RETURN c_carrier
END FUNCTION



########################################################################################
# carrierLookupSearchDataSourceCursor(p_recCarrierSearch)
#-------------------------------------------------------
# Returns the Carrier CURSOR for the lookup query
########################################################################################
FUNCTION carrierLookupSearchDataSourceCursor(p_recCarrierSearch)
	DEFINE p_recCarrierSearch OF t_recCarrierSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Carrier CURSOR
	
	LET sqlQuery =	"SELECT ",
									"carrier.carrier_code, ", 
									"carrier.name_text ",
 
									"FROM carrier ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recCarrierSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((carrier_code LIKE '", p_recCarrierSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_recCarrierSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recCarrierSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY carrier_code"

	CALL c_carrier.DECLARE(sqlQuery) #CURSOR FOR carrier
	
	RETURN c_carrier
END FUNCTION


########################################################################################
# FUNCTION CarrierLookupFilterDataSource(precCarrierFilter)
#-------------------------------------------------------
# CALLS CarrierLookupFilterDataSourceCursor(precCarrierFilter) with the CarrierFilter data TO get a CURSOR
# Returns the Carrier list array arrCarrierList
########################################################################################
FUNCTION CarrierLookupFilterDataSource(precCarrierFilter)
	DEFINE precCarrierFilter OF t_recCarrierFilter
	DEFINE recCarrier OF t_recCarrier
	DEFINE arrCarrierList DYNAMIC ARRAY OF t_recCarrier 
	DEFINE c_Carrier CURSOR
	DEFINE retError SMALLINT
		
	CALL CarrierLookupFilterDataSourceCursor(precCarrierFilter.*) RETURNING c_Carrier
	
	CALL arrCarrierList.CLEAR()

	CALL c_Carrier.SetResults(recCarrier.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Carrier.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Carrier.FetchNext()=0)
		CALL arrCarrierList.append([recCarrier.carrier_code, recCarrier.name_text])
	END WHILE	

	END IF
	
	IF arrCarrierList.getSize() = 0 THEN
		ERROR "No carrier's found with the specified filter criteria"
	END IF
	
	RETURN arrCarrierList
END FUNCTION	

########################################################################################
# FUNCTION CarrierLookupSearchDataSource(precCarrierFilter)
#-------------------------------------------------------
# CALLS CarrierLookupSearchDataSourceCursor(precCarrierFilter) with the CarrierFilter data TO get a CURSOR
# Returns the Carrier list array arrCarrierList
########################################################################################
FUNCTION CarrierLookupSearchDataSource(p_recCarrierSearch)
	DEFINE p_recCarrierSearch OF t_recCarrierSearch	
	DEFINE recCarrier OF t_recCarrier
	DEFINE arrCarrierList DYNAMIC ARRAY OF t_recCarrier 
	DEFINE c_Carrier CURSOR
	DEFINE retError SMALLINT	
	CALL CarrierLookupSearchDataSourceCursor(p_recCarrierSearch) RETURNING c_Carrier
	
	CALL arrCarrierList.CLEAR()

	CALL c_Carrier.SetResults(recCarrier.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Carrier.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Carrier.FetchNext()=0)
		CALL arrCarrierList.append([recCarrier.carrier_code, recCarrier.name_text])
	END WHILE	

	END IF
	
	IF arrCarrierList.getSize() = 0 THEN
		ERROR "No carrier's found with the specified filter criteria"
	END IF
	
	RETURN arrCarrierList
END FUNCTION


########################################################################################
# FUNCTION carrierLookup_filter(pCarrierCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Carrier code carrier_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Carrier Code carrier_code
#
# Example:
# 			LET pr_Carrier.carrier_code = CarrierLookup(pr_Carrier.carrier_code)
########################################################################################
FUNCTION carrierLookup_filter(pCarrierCode)
	DEFINE pCarrierCode LIKE Carrier.carrier_code
	DEFINE arrCarrierList DYNAMIC ARRAY OF t_recCarrier
	DEFINE recCarrierFilter OF t_recCarrierFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCarrierLookup WITH FORM "CarrierLookup_filter"


	CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCarrierFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCarrierList TO scCarrierList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCarrierCode = arrCarrierList[idx].carrier_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCarrierFilter.filter_carrier_code IS NOT NULL
			OR recCarrierFilter.filter_name_text IS NOT NULL

		THEN
			LET recCarrierFilter.filter_carrier_code = NULL
			LET recCarrierFilter.filter_name_text = NULL

			CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_carrier_code"
		IF recCarrierFilter.filter_carrier_code IS NOT NULL THEN
			LET recCarrierFilter.filter_carrier_code = NULL
			CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recCarrierFilter.filter_name_text IS NOT NULL THEN
			LET recCarrierFilter.filter_name_text = NULL
			CALL CarrierLookupFilterDataSource(recCarrierFilter.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCarrierLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCarrierCode	
END FUNCTION				
		

########################################################################################
# FUNCTION carrierLookup(pCarrierCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Carrier code carrier_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CarrierLookupSearchDataSource(recCarrierFilter.*) RETURNING arrCarrierList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Carrier Code carrier_code
#
# Example:
# 			LET pr_Carrier.carrier_code = CarrierLookup(pr_Carrier.carrier_code)
########################################################################################
FUNCTION carrierLookup(pCarrierCode)
	DEFINE pCarrierCode LIKE Carrier.carrier_code
	DEFINE arrCarrierList DYNAMIC ARRAY OF t_recCarrier
	DEFINE recCarrierSearch OF t_recCarrierSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCarrierLookup WITH FORM "carrierLookup"

	CALL CarrierLookupSearchDataSource(recCarrierSearch.*) RETURNING arrCarrierList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCarrierSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CarrierLookupSearchDataSource(recCarrierSearch.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCarrierList TO scCarrierList.* 
		BEFORE ROW
			IF arrCarrierList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCarrierCode = arrCarrierList[idx].carrier_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCarrierSearch.filter_any_field IS NOT NULL

		THEN
			LET recCarrierSearch.filter_any_field = NULL

			CALL CarrierLookupSearchDataSource(recCarrierSearch.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_carrier_code"
		IF recCarrierSearch.filter_any_field IS NOT NULL THEN
			LET recCarrierSearch.filter_any_field = NULL
			CALL CarrierLookupSearchDataSource(recCarrierSearch.*) RETURNING arrCarrierList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCarrierLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCarrierCode	
END FUNCTION				

############################################
# FUNCTION import_carrier()
############################################
FUNCTION import_carrier()
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
	
	DEFINE rec_carrier OF t_recCarrier_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCarrierImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Carrier List Data (table: carrier)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_carrier
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_carrier(	    
    carrier_code CHAR(3),
    name_text CHAR(30),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(20),
    state_code CHAR(6),
    post_code CHAR(10),
    country_code CHAR(3),
    next_manifest INTEGER,
    next_consign CHAR(15),
    last_consign CHAR(15),
    charge_ind CHAR(1),
    format_ind DECIMAL(2,0)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_carrier	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCarrierImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCarrierImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/carrier-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_carrier
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_carrier
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_carrier
			LET importReport = importReport, "Code:", trim(rec_carrier.carrier_code) , "     -     Desc:", trim(rec_carrier.name_text), "\n"
					
			INSERT INTO carrier VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_carrier.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_carrier.carrier_code) , "     -     Desc:", trim(rec_carrier.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCarrierImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_carrierRec(p_cmpy_code, p_carrier_code)
########################################################
FUNCTION exist_carrierRec(p_cmpy_code, p_carrier_code)
	DEFINE p_cmpy_code LIKE carrier.cmpy_code
	DEFINE p_carrier_code LIKE carrier.carrier_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM carrier 
     WHERE cmpy_code = p_cmpy_code
     AND carrier_code = p_carrier_code

	DROP TABLE temp_carrier
	CLOSE WINDOW wCarrierImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_carrier()
###############################################################
FUNCTION unload_carrier(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/carrier-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM carrier ORDER BY cmpy_code, carrier_code ASC
	
	LET tmpMsg = "All carrier data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("carrier Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_carrier_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_carrier_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE carrier.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcarrierImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "carrier Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing carrier table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM carrier
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table carrier!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table carrier where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCarrierImport		
END FUNCTION	