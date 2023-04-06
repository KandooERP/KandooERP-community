GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCustomerPartCount()
# FUNCTION customerPartLookupFilterDataSourceCursor(precCustomerPartFilter)
# FUNCTION customerPartLookupSearchDataSourceCursor(p_recCustomerPartSearch)
# FUNCTION customerPartLookupFilterDataSource(precCustomerPartFilter)
# FUNCTION customerPartLookup_filter(pCustomerPartCode)
# FUNCTION import_customerPart()
# FUNCTION exist_customerPartRec(p_cmpy_code, p_part_code)
# FUNCTION delete_customerPart_all()
# FUNCTION customerPartMenu()						-- Offer different OPTIONS of this library via a menu

# CustomerPart record types
	DEFINE t_recCustomerPart  
		TYPE AS RECORD
			cust_code LIKE customerpart.cust_code,
			part_code LIKE customerpart.part_code,
			custpart_code LIKE customerpart.custpart_code
		END RECORD 

	DEFINE t_recCustomerPartFilter  
		TYPE AS RECORD
			filter_cust_code LIKE customerpart.cust_code,
			filter_part_code LIKE customerpart.part_code,
			filter_custpart_code LIKE customerpart.custpart_code
		END RECORD 

	DEFINE t_recCustomerPartSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCustomerPart_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE customerpart.cust_code,
    part_code LIKE customerpart.part_code,
    custpart_code LIKE customerpart.custpart_code    
    
    
	END RECORD	


	
########################################################################################
# FUNCTION customerPartMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION customerPartMenu()
	MENU
		ON ACTION "Import"
			CALL import_customerPart()
		ON ACTION "Export"
			CALL unload_customerPart()
		#ON ACTION "Import"
		#	CALL import_customerPart()
		ON ACTION "Delete All"
			CALL delete_customerPart_all()
		ON ACTION "Count"
			CALL getCustomerPartCount() --Count all customerPart rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCustomerPartCount()
#-------------------------------------------------------
# Returns the number of CustomerPart entries for the current company
########################################################################################
FUNCTION getCustomerPartCount()
	DEFINE ret_CustomerPartCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_CustomerPart CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM customerpart ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_CustomerPart.DECLARE(sqlQuery) #CURSOR FOR getCustomerPart
	CALL c_CustomerPart.SetResults(ret_CustomerPartCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_CustomerPart.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CustomerPartCount = -1
	ELSE
		CALL c_CustomerPart.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of customer parts:", trim(ret_CustomerPartCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Customer Part Count (table customerpart)", tempMsg,"info") 	
	END IF

	RETURN ret_CustomerPartCount
END FUNCTION

########################################################################################
# FUNCTION customerPartLookupFilterDataSourceCursor(precCustomerPartFilter)
#-------------------------------------------------------
# Returns the CustomerPart CURSOR for the lookup query
########################################################################################
FUNCTION customerPartLookupFilterDataSourceCursor(precCustomerPartFilter)
	DEFINE precCustomerPartFilter OF t_recCustomerPartFilter
	DEFINE sqlQuery STRING
	DEFINE c_CustomerPart CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customerpart.part_code, ", 
									"customerpart.custpart_code ",
									"FROM customerpart ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precCustomerPartFilter.filter_part_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND part_code LIKE '", precCustomerPartFilter.filter_part_code CLIPPED, "%' "  
	END IF									

	IF precCustomerPartFilter.filter_custpart_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND custpart_code LIKE '", precCustomerPartFilter.filter_custpart_code CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY part_code"

	CALL c_customerPart.DECLARE(sqlQuery)
		
	RETURN c_customerPart
END FUNCTION



########################################################################################
# customerPartLookupSearchDataSourceCursor(p_recCustomerPartSearch)
#-------------------------------------------------------
# Returns the CustomerPart CURSOR for the lookup query
########################################################################################
FUNCTION customerPartLookupSearchDataSourceCursor(p_recCustomerPartSearch)
	DEFINE p_recCustomerPartSearch OF t_recCustomerPartSearch  
	DEFINE sqlQuery STRING
	DEFINE c_CustomerPart CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customerpart.part_code, ", 
									"customerpart.custpart_code ",
 
									"FROM customerpart ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recCustomerPartSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((part_code LIKE '", p_recCustomerPartSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR custpart_code LIKE '",   p_recCustomerPartSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recCustomerPartSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY part_code"

	CALL c_customerPart.DECLARE(sqlQuery) #CURSOR FOR customerPart
	
	RETURN c_customerPart
END FUNCTION


########################################################################################
# FUNCTION CustomerPartLookupFilterDataSource(precCustomerPartFilter)
#-------------------------------------------------------
# CALLS CustomerPartLookupFilterDataSourceCursor(precCustomerPartFilter) with the CustomerPartFilter data TO get a CURSOR
# Returns the CustomerPart list array arrCustomerPartList
########################################################################################
FUNCTION CustomerPartLookupFilterDataSource(precCustomerPartFilter)
	DEFINE precCustomerPartFilter OF t_recCustomerPartFilter
	DEFINE recCustomerPart OF t_recCustomerPart
	DEFINE arrCustomerPartList DYNAMIC ARRAY OF t_recCustomerPart 
	DEFINE c_CustomerPart CURSOR
	DEFINE retError SMALLINT
		
	CALL CustomerPartLookupFilterDataSourceCursor(precCustomerPartFilter.*) RETURNING c_CustomerPart
	
	CALL arrCustomerPartList.CLEAR()

	CALL c_CustomerPart.SetResults(recCustomerPart.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CustomerPart.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CustomerPart.FetchNext()=0)
		CALL arrCustomerPartList.append([recCustomerPart.part_code, recCustomerPart.custpart_code])
	END WHILE	

	END IF
	
	IF arrCustomerPartList.getSize() = 0 THEN
		ERROR "No customerPart's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerPartList
END FUNCTION	

########################################################################################
# FUNCTION CustomerPartLookupSearchDataSource(precCustomerPartFilter)
#-------------------------------------------------------
# CALLS CustomerPartLookupSearchDataSourceCursor(precCustomerPartFilter) with the CustomerPartFilter data TO get a CURSOR
# Returns the CustomerPart list array arrCustomerPartList
########################################################################################
FUNCTION CustomerPartLookupSearchDataSource(p_recCustomerPartSearch)
	DEFINE p_recCustomerPartSearch OF t_recCustomerPartSearch	
	DEFINE recCustomerPart OF t_recCustomerPart
	DEFINE arrCustomerPartList DYNAMIC ARRAY OF t_recCustomerPart 
	DEFINE c_CustomerPart CURSOR
	DEFINE retError SMALLINT	
	CALL CustomerPartLookupSearchDataSourceCursor(p_recCustomerPartSearch) RETURNING c_CustomerPart
	
	CALL arrCustomerPartList.CLEAR()

	CALL c_CustomerPart.SetResults(recCustomerPart.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CustomerPart.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CustomerPart.FetchNext()=0)
		CALL arrCustomerPartList.append([recCustomerPart.part_code, recCustomerPart.custpart_code])
	END WHILE	

	END IF
	
	IF arrCustomerPartList.getSize() = 0 THEN
		ERROR "No customerPart's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerPartList
END FUNCTION


########################################################################################
# FUNCTION customerPartLookup_filter(pCustomerPartCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustomerPart code part_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustomerPart Code part_code
#
# Example:
# 			LET pr_CustomerPart.part_code = CustomerPartLookup(pr_CustomerPart.part_code)
########################################################################################
FUNCTION customerPartLookup_filter(pCustomerPartCode)
	DEFINE pCustomerPartCode LIKE customerpart.part_code
	DEFINE arrCustomerPartList DYNAMIC ARRAY OF t_recCustomerPart
	DEFINE recCustomerPartFilter OF t_recCustomerPartFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerPartLookup WITH FORM "CustomerPartLookup_filter"


	CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerPartFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerPartList TO scCustomerPartList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerPartCode = arrCustomerPartList[idx].part_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerPartFilter.filter_part_code IS NOT NULL
			OR recCustomerPartFilter.filter_custpart_code IS NOT NULL

		THEN
			LET recCustomerPartFilter.filter_part_code = NULL
			LET recCustomerPartFilter.filter_custpart_code = NULL

			CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_part_code"
		IF recCustomerPartFilter.filter_part_code IS NOT NULL THEN
			LET recCustomerPartFilter.filter_part_code = NULL
			CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_custpart_code"
		IF recCustomerPartFilter.filter_custpart_code IS NOT NULL THEN
			LET recCustomerPartFilter.filter_custpart_code = NULL
			CALL CustomerPartLookupFilterDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerPartLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerPartCode	
END FUNCTION				
		

########################################################################################
# FUNCTION customerPartLookup(pCustomerPartCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustomerPart code part_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerPartLookupSearchDataSource(recCustomerPartFilter.*) RETURNING arrCustomerPartList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustomerPart Code part_code
#
# Example:
# 			LET pr_CustomerPart.part_code = CustomerPartLookup(pr_CustomerPart.part_code)
########################################################################################
FUNCTION customerPartLookup(pCustomerPartCode)
	DEFINE pCustomerPartCode LIKE customerpart.part_code
	DEFINE arrCustomerPartList DYNAMIC ARRAY OF t_recCustomerPart
	DEFINE recCustomerPartSearch OF t_recCustomerPartSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerPartLookup WITH FORM "customerPartLookup"

	CALL CustomerPartLookupSearchDataSource(recCustomerPartSearch.*) RETURNING arrCustomerPartList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerPartSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CustomerPartLookupSearchDataSource(recCustomerPartSearch.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerPartList TO scCustomerPartList.* 
		BEFORE ROW
			IF arrCustomerPartList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerPartCode = arrCustomerPartList[idx].part_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerPartSearch.filter_any_field IS NOT NULL

		THEN
			LET recCustomerPartSearch.filter_any_field = NULL

			CALL CustomerPartLookupSearchDataSource(recCustomerPartSearch.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_part_code"
		IF recCustomerPartSearch.filter_any_field IS NOT NULL THEN
			LET recCustomerPartSearch.filter_any_field = NULL
			CALL CustomerPartLookupSearchDataSource(recCustomerPartSearch.*) RETURNING arrCustomerPartList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerPartLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerPartCode	
END FUNCTION				

############################################
# FUNCTION import_customerPart()
############################################
FUNCTION import_customerPart()
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
	DEFINE p_custpart_code LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_customerPart OF t_recCustomerPart_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCustomerPartImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Warehouse Group List Data (table: customerPart)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_customerpart
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_customerpart(	    
	    cust_code CHAR(8),
	    part_code CHAR(15),
	    custpart_code CHAR(20)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_customerPart	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_custpart_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wCustomerPartImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_custpart_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_custpart_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.custpart_code,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wCustomerPartImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/customerPart-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_customerpart
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_customerpart
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_customerPart
			LET importReport = importReport, "Code:", trim(rec_customerPart.part_code) , "     -     Desc:", trim(rec_customerPart.custpart_code), "\n"
					
			INSERT INTO customerPart VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_customerPart.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_customerPart.part_code) , "     -     Desc:", trim(rec_customerPart.custpart_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCustomerPartImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_customerPartRec(p_cmpy_code, p_part_code)
########################################################
FUNCTION exist_customerPartRec(p_cmpy_code, p_part_code)
	DEFINE p_cmpy_code LIKE customerpart.cmpy_code
	DEFINE p_part_code LIKE customerpart.part_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM customerpart 
     WHERE cmpy_code = p_cmpy_code
     AND part_code = p_part_code

	DROP TABLE temp_customerPart
	CLOSE WINDOW wCustomerPartImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_customerPart()
###############################################################
FUNCTION unload_customerPart(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/customerPart-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile SELECT * FROM customerpart ORDER BY cmpy_code, part_code ASC
	
	LET tmpMsg = "All customerPart data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("customerPart Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_customerPart_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_customerPart_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE customerpart.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcustomerPartImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "customerPart Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing customerPart table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM customerpart
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table customerPart!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table customerPart where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCustomerPartImport		
END FUNCTION	