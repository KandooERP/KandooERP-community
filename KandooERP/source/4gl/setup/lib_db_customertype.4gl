GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCustomertypeCount()
# FUNCTION customertypeLookupFilterDataSourceCursor(pRecCustomertypeFilter)
# FUNCTION customertypeLookupSearchDataSourceCursor(p_RecCustomertypeSearch)
# FUNCTION CustomertypeLookupFilterDataSource(pRecCustomertypeFilter)
# FUNCTION customertypeLookup_filter(pCustomertypeCode)
# FUNCTION import_customertype()
# FUNCTION exist_customertypeRec(p_cmpy_code, p_type_code)
# FUNCTION delete_customertype_all()
# FUNCTION customerTypeMenu()						-- Offer different OPTIONS of this library via a menu

# Customertype record types
	DEFINE t_recCustomertype
		TYPE AS RECORD
			type_code LIKE customertype.type_code,
			type_text LIKE customertype.type_text
		END RECORD 

	DEFINE t_recCustomertypeFilter  
		TYPE AS RECORD
			filter_type_code LIKE customertype.type_code,
			filter_type_text LIKE customertype.type_text
		END RECORD 

	DEFINE t_recCustomertypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCustomertype_noCmpyId 
		TYPE AS RECORD 
    type_code LIKE customertype.type_code,
    type_text LIKE customertype.type_text,
    ar_acct_code LIKE customertype.ar_acct_code,
    freight_acct_code LIKE customertype.freight_acct_code,
    tax_acct_code LIKE customertype.tax_acct_code,
    disc_acct_code LIKE customertype.disc_acct_code,
    exch_acct_code LIKE customertype.exch_acct_code,
    lab_acct_code LIKE customertype.lab_acct_code,
    acct_mask_code LIKE customertype.acct_mask_code
	END RECORD	

	
########################################################################################
# FUNCTION customerTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION customerTypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_customertype()
		ON ACTION "Export"
			CALL unload_customertype(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_customertype()
		ON ACTION "Delete All"
			CALL delete_customertype_all()
		ON ACTION "Count"
			CALL getCustomertypeCount() --Count all customertype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCustomertypeCount()
#-------------------------------------------------------
# Returns the number of Customertype entries for the current company
########################################################################################
FUNCTION getCustomertypeCount()
	DEFINE ret_CustomertypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Customertype CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Customertype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Customertype.DECLARE(sqlQuery) #CURSOR FOR getCustomertype
	CALL c_Customertype.SetResults(ret_CustomertypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Customertype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CustomertypeCount = -1
	ELSE
		CALL c_Customertype.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Customer Types:", trim(ret_CustomertypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_CustomertypeCount
END FUNCTION

########################################################################################
# FUNCTION customertypeLookupFilterDataSourceCursor(pRecCustomertypeFilter)
#-------------------------------------------------------
# Returns the Customertype CURSOR for the lookup query
########################################################################################
FUNCTION customertypeLookupFilterDataSourceCursor(pRecCustomertypeFilter)
	DEFINE pRecCustomertypeFilter OF t_recCustomertypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Customertype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customertype.type_code, ", 
									"customertype.type_text ",
									"FROM customertype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCustomertypeFilter.filter_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_code LIKE '", pRecCustomertypeFilter.filter_type_code CLIPPED, "%' "  
	END IF									

	IF pRecCustomertypeFilter.filter_type_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_text LIKE '", pRecCustomertypeFilter.filter_type_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY type_code"

	CALL c_customertype.DECLARE(sqlQuery)
		
	RETURN c_customertype
END FUNCTION



########################################################################################
# customertypeLookupSearchDataSourceCursor(p_RecCustomertypeSearch)
#-------------------------------------------------------
# Returns the Customertype CURSOR for the lookup query
########################################################################################
FUNCTION customertypeLookupSearchDataSourceCursor(p_RecCustomertypeSearch)
	DEFINE p_RecCustomertypeSearch OF t_recCustomertypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Customertype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customertype.type_code, ", 
									"customertype.type_text ",
 
									"FROM customertype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCustomertypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((type_code LIKE '", p_RecCustomertypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR type_text LIKE '",   p_RecCustomertypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecCustomertypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY type_code"

	CALL c_customertype.DECLARE(sqlQuery) #CURSOR FOR customertype
	
	RETURN c_customertype
END FUNCTION


########################################################################################
# FUNCTION CustomertypeLookupFilterDataSource(pRecCustomertypeFilter)
#-------------------------------------------------------
# CALLS CustomertypeLookupFilterDataSourceCursor(pRecCustomertypeFilter) with the CustomertypeFilter data TO get a CURSOR
# Returns the Customertype list array arrCustomertypeList
########################################################################################
FUNCTION CustomertypeLookupFilterDataSource(pRecCustomertypeFilter)
	DEFINE pRecCustomertypeFilter OF t_recCustomertypeFilter
	DEFINE recCustomertype OF t_recCustomertype
	DEFINE arrCustomertypeList DYNAMIC ARRAY OF t_recCustomertype 
	DEFINE c_Customertype CURSOR
	DEFINE retError SMALLINT
		
	CALL CustomertypeLookupFilterDataSourceCursor(pRecCustomertypeFilter.*) RETURNING c_Customertype
	
	CALL arrCustomertypeList.CLEAR()

	CALL c_Customertype.SetResults(recCustomertype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Customertype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Customertype.FetchNext()=0)
		CALL arrCustomertypeList.append([recCustomertype.type_code, recCustomertype.type_text])
	END WHILE	

	END IF
	
	IF arrCustomertypeList.getSize() = 0 THEN
		ERROR "No customertype's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomertypeList
END FUNCTION	

########################################################################################
# FUNCTION CustomertypeLookupSearchDataSource(pRecCustomertypeFilter)
#-------------------------------------------------------
# CALLS CustomertypeLookupSearchDataSourceCursor(pRecCustomertypeFilter) with the CustomertypeFilter data TO get a CURSOR
# Returns the Customertype list array arrCustomertypeList
########################################################################################
FUNCTION CustomertypeLookupSearchDataSource(p_recCustomertypeSearch)
	DEFINE p_recCustomertypeSearch OF t_recCustomertypeSearch	
	DEFINE recCustomertype OF t_recCustomertype
	DEFINE arrCustomertypeList DYNAMIC ARRAY OF t_recCustomertype 
	DEFINE c_Customertype CURSOR
	DEFINE retError SMALLINT	
	CALL CustomertypeLookupSearchDataSourceCursor(p_recCustomertypeSearch) RETURNING c_Customertype
	
	CALL arrCustomertypeList.CLEAR()

	CALL c_Customertype.SetResults(recCustomertype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Customertype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Customertype.FetchNext()=0)
		CALL arrCustomertypeList.append([recCustomertype.type_code, recCustomertype.type_text])
	END WHILE	

	END IF
	
	IF arrCustomertypeList.getSize() = 0 THEN
		ERROR "No customertype's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomertypeList
END FUNCTION


########################################################################################
# FUNCTION customertypeLookup_filter(pCustomertypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Customertype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Customertype Code type_code
#
# Example:
# 			LET pr_Customertype.type_code = CustomertypeLookup(pr_Customertype.type_code)
########################################################################################
FUNCTION customertypeLookup_filter(pCustomertypeCode)
	DEFINE pCustomertypeCode LIKE Customertype.type_code
	DEFINE arrCustomertypeList DYNAMIC ARRAY OF t_recCustomertype
	DEFINE recCustomertypeFilter OF t_recCustomertypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomertypeLookup WITH FORM "CustomertypeLookup_filter"


	CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomertypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomertypeList TO scCustomertypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomertypeCode = arrCustomertypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomertypeFilter.filter_type_code IS NOT NULL
			OR recCustomertypeFilter.filter_type_text IS NOT NULL

		THEN
			LET recCustomertypeFilter.filter_type_code = NULL
			LET recCustomertypeFilter.filter_type_text = NULL

			CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recCustomertypeFilter.filter_type_code IS NOT NULL THEN
			LET recCustomertypeFilter.filter_type_code = NULL
			CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_type_text"
		IF recCustomertypeFilter.filter_type_text IS NOT NULL THEN
			LET recCustomertypeFilter.filter_type_text = NULL
			CALL CustomertypeLookupFilterDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomertypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomertypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION customertypeLookup(pCustomertypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Customertype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomertypeLookupSearchDataSource(recCustomertypeFilter.*) RETURNING arrCustomertypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Customertype Code type_code
#
# Example:
# 			LET pr_Customertype.type_code = CustomertypeLookup(pr_Customertype.type_code)
########################################################################################
FUNCTION customertypeLookup(pCustomertypeCode)
	DEFINE pCustomertypeCode LIKE Customertype.type_code
	DEFINE arrCustomertypeList DYNAMIC ARRAY OF t_recCustomertype
	DEFINE recCustomertypeSearch OF t_recCustomertypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomertypeLookup WITH FORM "customertypeLookup"

	CALL CustomertypeLookupSearchDataSource(recCustomertypeSearch.*) RETURNING arrCustomertypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomertypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CustomertypeLookupSearchDataSource(recCustomertypeSearch.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomertypeList TO scCustomertypeList.* 
		BEFORE ROW
			IF arrCustomertypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomertypeCode = arrCustomertypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomertypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recCustomertypeSearch.filter_any_field = NULL

			CALL CustomertypeLookupSearchDataSource(recCustomertypeSearch.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recCustomertypeSearch.filter_any_field IS NOT NULL THEN
			LET recCustomertypeSearch.filter_any_field = NULL
			CALL CustomertypeLookupSearchDataSource(recCustomertypeSearch.*) RETURNING arrCustomertypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomertypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomertypeCode	
END FUNCTION				

############################################
# FUNCTION import_customertype()
############################################
FUNCTION import_customertype()
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
	DEFINE p_type_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_customertype OF t_recCustomertype_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCustomertypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Type List Data (table: customertype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_customertype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_customertype(
	    type_code CHAR(3),
	    type_text CHAR(30),
	    ar_acct_code CHAR(18),
	    freight_acct_code CHAR(18),
	    tax_acct_code CHAR(18),
	    disc_acct_code CHAR(18),
	    exch_acct_code CHAR(18),
	    lab_acct_code CHAR(18),
	    acct_mask_code CHAR(18)		
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_customertype	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_type_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wCustomertypeImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_type_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_type_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wCustomertypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/customertype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_customertype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_customertype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_customertype
			LET importReport = importReport, "Code:", trim(rec_customertype.type_code) , "     -     Desc:", trim(rec_customertype.type_text), "\n"
					
			INSERT INTO customertype VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_customertype.type_code,
				rec_customertype.type_text,
				rec_customertype.ar_acct_code,
				rec_customertype.freight_acct_code,
				rec_customertype.tax_acct_code,
				rec_customertype.disc_acct_code,
				rec_customertype.exch_acct_code,
				rec_customertype.lab_acct_code,
				rec_customertype.acct_mask_code
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_customertype.type_code) , "     -     Desc:", trim(rec_customertype.type_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCustomertypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_customertypeRec(p_cmpy_code, p_type_code)
########################################################
FUNCTION exist_customertypeRec(p_cmpy_code, p_type_code)
	DEFINE p_cmpy_code LIKE customertype.cmpy_code
	DEFINE p_type_code LIKE customertype.type_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM customertype 
     WHERE cmpy_code = p_cmpy_code
     AND type_code = p_type_code

	DROP TABLE temp_customertype
	CLOSE WINDOW wCustomertypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_customertype()
###############################################################
FUNCTION unload_customertype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()	
	LET unloadFile = "unl/customertype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
	    #cmpy_code,
	    type_code,
	    type_text,
	    ar_acct_code,
	    freight_acct_code,
	    tax_acct_code,
	    disc_acct_code,
	    exch_acct_code,
	    lab_acct_code,
	    acct_mask_code		
		FROM customertype
		WHERE cmpy_code = currentCompany
		ORDER BY type_code ASC

	----	
	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM customertype ORDER BY cmpy_code, type_code ASC
	
	LET tmpMsg = "All customertype data were exported/written TO:\n", unloadFile1, "AND ", unloadFile2
	CALL fgl_winmessage("customertype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_customertype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_customertype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE customertype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcustomertypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "customertype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing customertype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM customertype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table customertype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table customertype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCustomertypeImport		
END FUNCTION	