GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCustOfferCount()
# FUNCTION custofferLookupFilterDataSourceCursor(precCustOfferFilter)
# FUNCTION custofferLookupSearchDataSourceCursor(p_recCustOfferSearch)
# FUNCTION CustOfferLookupFilterDataSource(precCustOfferFilter)
# FUNCTION custofferLookup_filter(pCustOfferCode)
# FUNCTION import_custOffer()
# FUNCTION exist_custofferRec(p_cmpy_code, p_cust_code)
# FUNCTION delete_custoffer_all()
# FUNCTION custOfferMenu()						-- Offer different OPTIONS of this library via a menu

# CustOffer record types
	DEFINE t_recCustOffer
		TYPE AS RECORD
			cust_code LIKE custoffer.cust_code,
			offer_code LIKE custoffer.offer_code
		END RECORD 

	DEFINE t_recCustOfferFilter  
		TYPE AS RECORD
			filter_cust_code LIKE custoffer.cust_code,
			filter_offer_code LIKE custoffer.offer_code
		END RECORD 

	DEFINE t_recCustOfferSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCustOffer_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE custoffer.cust_code,
    offer_code LIKE custoffer.offer_code,
    offer_start_date LIKE custoffer.offer_start_date,
    effective_date LIKE custoffer.effective_date
	END RECORD	

	
########################################################################################
# FUNCTION custOfferMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION custOfferMenu()
	MENU
		ON ACTION "Import"
			CALL import_custOffer()
		ON ACTION "Export"
			CALL unload_custOffer()
		#ON ACTION "Import"
		#	CALL import_custOffer()
		ON ACTION "Delete All"
			CALL delete_custoffer_all()
		ON ACTION "Count"
			CALL getCustOfferCount() --Count all custoffer rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCustOfferCount()
#-------------------------------------------------------
# Returns the number of CustOffer entries for the current company
########################################################################################
FUNCTION getCustOfferCount()
	DEFINE ret_CustOfferCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_CustOffer CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM custoffer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_CustOffer.DECLARE(sqlQuery) #CURSOR FOR getCustOffer
	CALL c_CustOffer.SetResults(ret_CustOfferCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_CustOffer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CustOfferCount = -1
	ELSE
		CALL c_CustOffer.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Customer Types:", trim(ret_CustOfferCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_CustOfferCount
END FUNCTION

########################################################################################
# FUNCTION custofferLookupFilterDataSourceCursor(precCustOfferFilter)
#-------------------------------------------------------
# Returns the CustOffer CURSOR for the lookup query
########################################################################################
FUNCTION custofferLookupFilterDataSourceCursor(precCustOfferFilter)
	DEFINE precCustOfferFilter OF t_recCustOfferFilter
	DEFINE sqlQuery STRING
	DEFINE c_CustOffer CURSOR
	
	LET sqlQuery =	"SELECT ",
									"custoffer.cust_code, ", 
									"custoffer.offer_code ",
									"FROM custoffer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precCustOfferFilter.filter_cust_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cust_code LIKE '", precCustOfferFilter.filter_cust_code CLIPPED, "%' "  
	END IF									

	IF precCustOfferFilter.filter_offer_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND offer_code LIKE '", precCustOfferFilter.filter_offer_code CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cust_code"

	CALL c_custoffer.DECLARE(sqlQuery)
		
	RETURN c_custoffer
END FUNCTION



########################################################################################
# custofferLookupSearchDataSourceCursor(p_recCustOfferSearch)
#-------------------------------------------------------
# Returns the CustOffer CURSOR for the lookup query
########################################################################################
FUNCTION custofferLookupSearchDataSourceCursor(p_recCustOfferSearch)
	DEFINE p_recCustOfferSearch OF t_recCustOfferSearch  
	DEFINE sqlQuery STRING
	DEFINE c_CustOffer CURSOR
	
	LET sqlQuery =	"SELECT ",
									"custoffer.cust_code, ", 
									"custoffer.offer_code ",
 
									"FROM custoffer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recCustOfferSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cust_code LIKE '", p_recCustOfferSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR offer_code LIKE '",   p_recCustOfferSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recCustOfferSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cust_code"

	CALL c_custoffer.DECLARE(sqlQuery) #CURSOR FOR custoffer
	
	RETURN c_custoffer
END FUNCTION


########################################################################################
# FUNCTION CustOfferLookupFilterDataSource(precCustOfferFilter)
#-------------------------------------------------------
# CALLS CustOfferLookupFilterDataSourceCursor(precCustOfferFilter) with the CustOfferFilter data TO get a CURSOR
# Returns the CustOffer list array arrCustOfferList
########################################################################################
FUNCTION CustOfferLookupFilterDataSource(precCustOfferFilter)
	DEFINE precCustOfferFilter OF t_recCustOfferFilter
	DEFINE recCustOffer OF t_recCustOffer
	DEFINE arrCustOfferList DYNAMIC ARRAY OF t_recCustOffer 
	DEFINE c_CustOffer CURSOR
	DEFINE retError SMALLINT
		
	CALL CustOfferLookupFilterDataSourceCursor(precCustOfferFilter.*) RETURNING c_CustOffer
	
	CALL arrCustOfferList.CLEAR()

	CALL c_CustOffer.SetResults(recCustOffer.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CustOffer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CustOffer.FetchNext()=0)
		CALL arrCustOfferList.append([recCustOffer.cust_code, recCustOffer.offer_code])
	END WHILE	

	END IF
	
	IF arrCustOfferList.getSize() = 0 THEN
		ERROR "No custoffer's found with the specified filter criteria"
	END IF
	
	RETURN arrCustOfferList
END FUNCTION	

########################################################################################
# FUNCTION CustOfferLookupSearchDataSource(precCustOfferFilter)
#-------------------------------------------------------
# CALLS CustOfferLookupSearchDataSourceCursor(precCustOfferFilter) with the CustOfferFilter data TO get a CURSOR
# Returns the CustOffer list array arrCustOfferList
########################################################################################
FUNCTION CustOfferLookupSearchDataSource(p_recCustOfferSearch)
	DEFINE p_recCustOfferSearch OF t_recCustOfferSearch	
	DEFINE recCustOffer OF t_recCustOffer
	DEFINE arrCustOfferList DYNAMIC ARRAY OF t_recCustOffer 
	DEFINE c_CustOffer CURSOR
	DEFINE retError SMALLINT	
	CALL CustOfferLookupSearchDataSourceCursor(p_recCustOfferSearch) RETURNING c_CustOffer
	
	CALL arrCustOfferList.CLEAR()

	CALL c_CustOffer.SetResults(recCustOffer.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CustOffer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CustOffer.FetchNext()=0)
		CALL arrCustOfferList.append([recCustOffer.cust_code, recCustOffer.offer_code])
	END WHILE	

	END IF
	
	IF arrCustOfferList.getSize() = 0 THEN
		ERROR "No customer offers (custoffer) found with the specified filter criteria"
	END IF
	
	RETURN arrCustOfferList
END FUNCTION


########################################################################################
# FUNCTION custofferLookup_filter(pCustOfferCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustOffer code cust_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustOffer Code cust_code
#
# Example:
# 			LET pr_CustOffer.cust_code = CustOfferLookup(pr_CustOffer.cust_code)
########################################################################################
FUNCTION custofferLookup_filter(pCustOfferCode)
	DEFINE pCustOfferCode LIKE CustOffer.cust_code
	DEFINE arrCustOfferList DYNAMIC ARRAY OF t_recCustOffer
	DEFINE recCustOfferFilter OF t_recCustOfferFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustOfferLookup WITH FORM "CustOfferLookup_filter"


	CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustOfferFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustOfferList TO scCustOfferList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustOfferCode = arrCustOfferList[idx].cust_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustOfferFilter.filter_cust_code IS NOT NULL
			OR recCustOfferFilter.filter_offer_code IS NOT NULL

		THEN
			LET recCustOfferFilter.filter_cust_code = NULL
			LET recCustOfferFilter.filter_offer_code = NULL

			CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cust_code"
		IF recCustOfferFilter.filter_cust_code IS NOT NULL THEN
			LET recCustOfferFilter.filter_cust_code = NULL
			CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_offer_code"
		IF recCustOfferFilter.filter_offer_code IS NOT NULL THEN
			LET recCustOfferFilter.filter_offer_code = NULL
			CALL CustOfferLookupFilterDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustOfferLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustOfferCode	
END FUNCTION				
		

########################################################################################
# FUNCTION custofferLookup(pCustOfferCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CustOffer code cust_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustOfferLookupSearchDataSource(recCustOfferFilter.*) RETURNING arrCustOfferList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CustOffer Code cust_code
#
# Example:
# 			LET pr_CustOffer.cust_code = CustOfferLookup(pr_CustOffer.cust_code)
########################################################################################
FUNCTION custofferLookup(pCustOfferCode)
	DEFINE pCustOfferCode LIKE CustOffer.cust_code
	DEFINE arrCustOfferList DYNAMIC ARRAY OF t_recCustOffer
	DEFINE recCustOfferSearch OF t_recCustOfferSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustOfferLookup WITH FORM "custofferLookup"

	CALL CustOfferLookupSearchDataSource(recCustOfferSearch.*) RETURNING arrCustOfferList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustOfferSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CustOfferLookupSearchDataSource(recCustOfferSearch.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustOfferList TO scCustOfferList.* 
		BEFORE ROW
			IF arrCustOfferList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustOfferCode = arrCustOfferList[idx].cust_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustOfferSearch.filter_any_field IS NOT NULL

		THEN
			LET recCustOfferSearch.filter_any_field = NULL

			CALL CustOfferLookupSearchDataSource(recCustOfferSearch.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cust_code"
		IF recCustOfferSearch.filter_any_field IS NOT NULL THEN
			LET recCustOfferSearch.filter_any_field = NULL
			CALL CustOfferLookupSearchDataSource(recCustOfferSearch.*) RETURNING arrCustOfferList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustOfferLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustOfferCode	
END FUNCTION				

############################################
# FUNCTION import_custOffer()
############################################
FUNCTION import_custOffer()
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
	DEFINE p_offer_code LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_custOffer OF t_recCustOffer_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCustOfferImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Customer Offer List Data (table: custoffer)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_custoffer
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_custoffer(
	    cust_code CHAR(8),
	    offer_code CHAR(6),
	    offer_start_date DATE,
	    effective_date date	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_custoffer	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_offer_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wCustOfferImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_offer_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_offer_code,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wCustOfferImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/custoffer-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_custoffer
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_custoffer
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_custOffer
			LET importReport = importReport, "Code:", trim(rec_custOffer.cust_code) , "     -     Desc:", trim(rec_custOffer.offer_code), "\n"
					
			INSERT INTO custoffer VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_custOffer.*
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_custOffer.cust_code) , "     -     Desc:", trim(rec_custOffer.offer_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCustOfferImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_custofferRec(p_cmpy_code, p_cust_code)
########################################################
FUNCTION exist_custofferRec(p_cmpy_code, p_cust_code)
	DEFINE p_cmpy_code LIKE custoffer.cmpy_code
	DEFINE p_cust_code LIKE custoffer.cust_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM custoffer 
     WHERE cmpy_code = p_cmpy_code
     AND cust_code = p_cust_code

	DROP TABLE temp_custoffer
	CLOSE WINDOW wCustOfferImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_custOffer()
###############################################################
FUNCTION unload_custOffer(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/custoffer-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM custoffer ORDER BY cmpy_code, cust_code ASC
	
	LET tmpMsg = "All custoffer data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("custoffer Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_custoffer_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_custoffer_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE custoffer.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcustofferImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "custoffer Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing custoffer table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM custoffer
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table custoffer!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table custoffer where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCustOfferImport		
END FUNCTION	