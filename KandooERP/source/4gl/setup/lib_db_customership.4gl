GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCustomerShipCount()
# FUNCTION customerShipLookupFilterDataSourceCursor(precCustomerShipFilter)
# FUNCTION customerShipLookupSearchDataSourceCursor(p_recCustomerShipSearch)
# FUNCTION customerShipLookupFilterDataSource(precCustomerShipFilter)
# FUNCTION customerShipLookup_filter(pCustomerShipCode)
# FUNCTION import_customerShip()
# FUNCTION exist_customerShipRec(p_cmpy_code, p_ship_code)
# FUNCTION delete_customerShip_all()
# FUNCTION customerShipMenu()						-- Offer different OPTIONS of this library via a menu

# CustomerShip record types
	DEFINE t_recCustomerShip  
		TYPE AS RECORD
			cust_code LIKE customership.cust_code,
			ship_code LIKE customership.ship_code,
			name_text LIKE customership.name_text
		END RECORD 

	DEFINE t_recCustomerShipFilter  
		TYPE AS RECORD
			filter_cust_code LIKE customership.cust_code,
			filter_ship_code LIKE customership.ship_code,
			filter_name_text LIKE customership.name_text
		END RECORD 

	DEFINE t_recCustomerShipSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCustomerShip_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE customership.cust_code,
    ship_code LIKE customership.ship_code,
    name_text LIKE customership.name_text,    
    addr_text LIKE customership.addr_text,
    addr2_text LIKE customership.addr2_text,
    city_text LIKE customership.city_text,
    state_code LIKE customership.state_code,
    post_code LIKE customership.post_code,
    country_text LIKE customership.country_text,
    contact_text LIKE customership.contact_text,
    tele_text LIKE customership.tele_text,
    ware_code LIKE customership.ware_code,
    tax_code LIKE customership.tax_code,
    ship1_text LIKE customership.ship1_text,
    ship2_text LIKE customership.ship2_text,
    contract_text LIKE customership.contract_text,
    cat_code LIKE customership.cat_code,
    run_text LIKE customership.run_text,
    note_text LIKE customership.note_text,
    carrier_code LIKE customership.carrier_code,
    freight_ind LIKE customership.freight_ind,
    country_code LIKE customership.country_code  
    
	END RECORD	


	
########################################################################################
# FUNCTION customerShipMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION customerShipMenu()
	MENU
		ON ACTION "Import"
			CALL import_customerShip()
		ON ACTION "Export"
			CALL unload_customerShip()
		#ON ACTION "Import"
		#	CALL import_customerShip()
		ON ACTION "Delete All"
			CALL delete_customerShip_all()
		ON ACTION "Count"
			CALL getCustomerShipCount() --Count all customerShip rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCustomerShipCount()
#-------------------------------------------------------
# Returns the number of CustomerShip entries for the current company
########################################################################################
FUNCTION getCustomerShipCount()
	DEFINE ret_CustomerShipCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_CustomerShip CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM customership ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_customerShip.DECLARE(sqlQuery) #CURSOR FOR getCustomerShip
	CALL c_customerShip.SetResults(ret_CustomerShipCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_customerShip.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CustomerShipCount = -1
	ELSE
		CALL c_customerShip.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of customer parts:", trim(ret_CustomerShipCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Customer Part Count (table customership)", tempMsg,"info") 	
	END IF

	RETURN ret_CustomerShipCount
END FUNCTION

########################################################################################
# FUNCTION customerShipLookupFilterDataSourceCursor(precCustomerShipFilter)
#-------------------------------------------------------
# Returns the CustomerShip CURSOR for the lookup query
########################################################################################
FUNCTION customerShipLookupFilterDataSourceCursor(precCustomerShipFilter)
	DEFINE precCustomerShipFilter OF t_recCustomerShipFilter
	DEFINE sqlQuery STRING
	DEFINE c_CustomerShip CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customership.ship_code, ", 
									"customership.name_text ",
									"FROM customership ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precCustomerShipFilter.filter_ship_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ship_code LIKE '", precCustomerShipFilter.filter_ship_code CLIPPED, "%' "  
	END IF									

	IF precCustomerShipFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", precCustomerShipFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY ship_code"

	CALL c_customerShip.DECLARE(sqlQuery)
		
	RETURN c_customerShip
END FUNCTION



########################################################################################
# customerShipLookupSearchDataSourceCursor(p_recCustomerShipSearch)
#-------------------------------------------------------
# Returns the CustomerShip CURSOR for the lookup query
########################################################################################
FUNCTION customerShipLookupSearchDataSourceCursor(p_recCustomerShipSearch)
	DEFINE p_recCustomerShipSearch OF t_recCustomerShipSearch  
	DEFINE sqlQuery STRING
	DEFINE c_CustomerShip CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customership.ship_code, ", 
									"customership.name_text ",
 
									"FROM customership ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recCustomerShipSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((ship_code LIKE '", p_recCustomerShipSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_recCustomerShipSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recCustomerShipSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY ship_code"

	CALL c_customerShip.DECLARE(sqlQuery) #CURSOR FOR customerShip
	
	RETURN c_customerShip
END FUNCTION


########################################################################################
# FUNCTION CustomerShipLookupFilterDataSource(precCustomerShipFilter)
#-------------------------------------------------------
# CALLS CustomerShipLookupFilterDataSourceCursor(precCustomerShipFilter) with the CustomerShipFilter data TO get a CURSOR
# Returns the CustomerShip list array arrCustomerShipList
########################################################################################
FUNCTION CustomerShipLookupFilterDataSource(precCustomerShipFilter)
	DEFINE precCustomerShipFilter OF t_recCustomerShipFilter
	DEFINE recCustomerShip OF t_recCustomerShip
	DEFINE arrCustomerShipList DYNAMIC ARRAY OF t_recCustomerShip 
	DEFINE c_CustomerShip CURSOR
	DEFINE retError SMALLINT
		
	CALL CustomerShipLookupFilterDataSourceCursor(precCustomerShipFilter.*) RETURNING c_CustomerShip
	
	CALL arrCustomerShipList.CLEAR()

	CALL c_customerShip.SetResults(recCustomerShip.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_customerShip.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_customerShip.FetchNext()=0)
		CALL arrCustomerShipList.append([recCustomerShip.ship_code, recCustomerShip.name_text])
	END WHILE	

	END IF
	
	IF arrCustomerShipList.getSize() = 0 THEN
		ERROR "No customer shipping addresses (customership) found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerShipList
END FUNCTION	

########################################################################################
# FUNCTION CustomerShipLookupSearchDataSource(precCustomerShipFilter)
#-------------------------------------------------------
# CALLS CustomerShipLookupSearchDataSourceCursor(precCustomerShipFilter) with the CustomerShipFilter data TO get a CURSOR
# Returns the CustomerShip list array arrCustomerShipList
########################################################################################
FUNCTION CustomerShipLookupSearchDataSource(p_recCustomerShipSearch)
	DEFINE p_recCustomerShipSearch OF t_recCustomerShipSearch	
	DEFINE recCustomerShip OF t_recCustomerShip
	DEFINE arrCustomerShipList DYNAMIC ARRAY OF t_recCustomerShip 
	DEFINE c_CustomerShip CURSOR
	DEFINE retError SMALLINT	
	CALL CustomerShipLookupSearchDataSourceCursor(p_recCustomerShipSearch) RETURNING c_CustomerShip
	
	CALL arrCustomerShipList.CLEAR()

	CALL c_customerShip.SetResults(recCustomerShip.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_customerShip.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_customerShip.FetchNext()=0)
		CALL arrCustomerShipList.append([recCustomerShip.ship_code, recCustomerShip.name_text])
	END WHILE	

	END IF
	
	IF arrCustomerShipList.getSize() = 0 THEN
		ERROR "No customer shipping addresses (customership) found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerShipList
END FUNCTION


########################################################################################
# FUNCTION customerShipLookup_filter(pCustomerShipCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustomerShip code ship_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustomerShip Code ship_code
#
# Example:
# 			LET pr_customerShip.ship_code = CustomerShipLookup(pr_customerShip.ship_code)
########################################################################################
FUNCTION customerShipLookup_filter(pCustomerShipCode)
	DEFINE pCustomerShipCode LIKE customership.ship_code
	DEFINE arrCustomerShipList DYNAMIC ARRAY OF t_recCustomerShip
	DEFINE recCustomerShipFilter OF t_recCustomerShipFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerShipLookup WITH FORM "CustomerShipLookup_filter"


	CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerShipFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerShipList TO scCustomerShipList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerShipCode = arrCustomerShipList[idx].ship_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerShipFilter.filter_ship_code IS NOT NULL
			OR recCustomerShipFilter.filter_name_text IS NOT NULL

		THEN
			LET recCustomerShipFilter.filter_ship_code = NULL
			LET recCustomerShipFilter.filter_name_text = NULL

			CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ship_code"
		IF recCustomerShipFilter.filter_ship_code IS NOT NULL THEN
			LET recCustomerShipFilter.filter_ship_code = NULL
			CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recCustomerShipFilter.filter_name_text IS NOT NULL THEN
			LET recCustomerShipFilter.filter_name_text = NULL
			CALL CustomerShipLookupFilterDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerShipLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerShipCode	
END FUNCTION				
		

########################################################################################
# FUNCTION customerShipLookup(pCustomerShipCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustomerShip code ship_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerShipLookupSearchDataSource(recCustomerShipFilter.*) RETURNING arrCustomerShipList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustomerShip Code ship_code
#
# Example:
# 			LET pr_customerShip.ship_code = CustomerShipLookup(pr_customerShip.ship_code)
########################################################################################
FUNCTION customerShipLookup(pCustomerShipCode)
	DEFINE pCustomerShipCode LIKE customership.ship_code
	DEFINE arrCustomerShipList DYNAMIC ARRAY OF t_recCustomerShip
	DEFINE recCustomerShipSearch OF t_recCustomerShipSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerShipLookup WITH FORM "customerShipLookup"

	CALL CustomerShipLookupSearchDataSource(recCustomerShipSearch.*) RETURNING arrCustomerShipList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerShipSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CustomerShipLookupSearchDataSource(recCustomerShipSearch.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerShipList TO scCustomerShipList.* 
		BEFORE ROW
			IF arrCustomerShipList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerShipCode = arrCustomerShipList[idx].ship_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerShipSearch.filter_any_field IS NOT NULL

		THEN
			LET recCustomerShipSearch.filter_any_field = NULL

			CALL CustomerShipLookupSearchDataSource(recCustomerShipSearch.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ship_code"
		IF recCustomerShipSearch.filter_any_field IS NOT NULL THEN
			LET recCustomerShipSearch.filter_any_field = NULL
			CALL CustomerShipLookupSearchDataSource(recCustomerShipSearch.*) RETURNING arrCustomerShipList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerShipLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerShipCode	
END FUNCTION				

############################################
# FUNCTION import_customerShip()
############################################
FUNCTION import_customerShip()
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
	
	DEFINE rec_customerShip OF t_recCustomerShip_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCustomerShipImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Customer Shipping Addresses List Data (table: customership)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_customership
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_customership(	    
	    cust_code CHAR(8),
	    ship_code CHAR(8),
	    name_text CHAR(30),
	    addr_text CHAR(30),
	    addr2_text CHAR(30),
	    city_text CHAR(30),
	    state_code CHAR(6),
	    post_code CHAR(10),
	    country_text CHAR(40),
	    contact_text CHAR(30),
	    tele_text CHAR(20),
	    ware_code CHAR(3),
	    tax_code CHAR(3),
	    ship1_text CHAR(60),
	    ship2_text CHAR(60),
	    contract_text CHAR(10),
	    cat_code CHAR(3),
	    run_text CHAR(3),
	    note_text CHAR(40),
	    carrier_code CHAR(3),
	    freight_ind CHAR(1),
	    country_code CHAR(3)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_customership	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCustomerShipImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCustomerShipImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/customership-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_customership
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_customership
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_customership
			LET importReport = importReport, "Code:", trim(rec_customerShip.ship_code) , "     -     Desc:", trim(rec_customerShip.name_text), "\n"
					
			INSERT INTO customership VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_customerShip.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_customerShip.ship_code) , "     -     Desc:", trim(rec_customerShip.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCustomerShipImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_customerShipRec(p_cmpy_code, p_ship_code)
########################################################
FUNCTION exist_customerShipRec(p_cmpy_code, p_ship_code)
	DEFINE p_cmpy_code LIKE customership.cmpy_code
	DEFINE p_ship_code LIKE customership.ship_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM customership 
     WHERE cmpy_code = p_cmpy_code
     AND ship_code = p_ship_code

	DROP TABLE temp_customership
	CLOSE WINDOW wCustomerShipImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_customerShip()
###############################################################
FUNCTION unload_customerShip(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/customership-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile SELECT * FROM customership ORDER BY cmpy_code, ship_code ASC
	
	LET tmpMsg = "All customer shipping addresses (customership) data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("customership Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_customerShip_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_customerShip_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE customership.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcustomerShipImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Delete customer shipping addresses (table: customership)" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing customer shipping addresses (customership) table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM customership
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table customership!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table customership where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCustomerShipImport		
END FUNCTION	