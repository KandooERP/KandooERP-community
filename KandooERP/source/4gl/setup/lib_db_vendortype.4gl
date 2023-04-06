GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getVendortypeCount()
# FUNCTION vendortypeLookupFilterDataSourceCursor(pRecVendortypeFilter)
# FUNCTION vendortypeLookupSearchDataSourceCursor(p_RecVendortypeSearch)
# FUNCTION VendortypeLookupFilterDataSource(pRecVendortypeFilter)
# FUNCTION vendortypeLookup_filter(pVendortypeCode)
# FUNCTION import_vendortype()
# FUNCTION exist_vendortypeRec(p_cmpy_code, p_type_code)
# FUNCTION delete_vendortype_all()
# FUNCTION vendorTypeMenu()						-- Offer different OPTIONS of this library via a menu

# Vendortype record types
	DEFINE t_recVendortype  
		TYPE AS RECORD
			type_code LIKE vendortype.type_code,
			type_text LIKE vendortype.type_text
		END RECORD 

	DEFINE t_recVendortypeFilter  
		TYPE AS RECORD
			filter_type_code LIKE vendortype.type_code,
			filter_type_text LIKE vendortype.type_text
		END RECORD 

	DEFINE t_recVendortypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recVendortype_noCmpyId 
		TYPE AS RECORD 
    type_code LIKE vendorType.type_code,
    type_text LIKE vendorType.type_text,
    pay_acct_code LIKE vendorType.pay_acct_code,
    freight_acct_code LIKE vendorType.freight_acct_code,
    salestax_acct_code LIKE vendorType.salestax_acct_code,
    disc_acct_code LIKE vendorType.disc_acct_code,
    exch_acct_code LIKE vendorType.exch_acct_code,
    withhold_tax_ind LIKE vendorType.withhold_tax_ind,
    tax_vend_code LIKE vendorType.tax_vend_code
	END RECORD	

	
########################################################################################
# FUNCTION vendorTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION vendorTypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_vendortype()
		ON ACTION "Export"
			CALL unload_vendortype()
		#ON ACTION "Import"
		#	CALL import_vendortype()
		ON ACTION "Delete All"
			CALL delete_vendortype_all()
		ON ACTION "Count"
			CALL getVendortypeCount() --Count all vendortype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getVendortypeCount()
#-------------------------------------------------------
# Returns the number of Vendortype entries for the current company
########################################################################################
FUNCTION getVendortypeCount()
	DEFINE ret_VendortypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Vendortype CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Vendortype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Vendortype.DECLARE(sqlQuery) #CURSOR FOR getVendortype
	CALL c_Vendortype.SetResults(ret_VendortypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Vendortype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_VendortypeCount = -1
	ELSE
		CALL c_Vendortype.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vendor Types:", trim(ret_VendortypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_VendortypeCount
END FUNCTION

########################################################################################
# FUNCTION vendortypeLookupFilterDataSourceCursor(pRecVendortypeFilter)
#-------------------------------------------------------
# Returns the Vendortype CURSOR for the lookup query
########################################################################################
FUNCTION vendortypeLookupFilterDataSourceCursor(pRecVendortypeFilter)
	DEFINE pRecVendortypeFilter OF t_recVendortypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Vendortype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendortype.type_code, ", 
									"vendortype.type_text ",
									"FROM vendortype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecVendortypeFilter.filter_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_code LIKE '", pRecVendortypeFilter.filter_type_code CLIPPED, "%' "  
	END IF									

	IF pRecVendortypeFilter.filter_type_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_text LIKE '", pRecVendortypeFilter.filter_type_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY type_code"

	CALL c_vendortype.DECLARE(sqlQuery)
		
	RETURN c_vendortype
END FUNCTION



########################################################################################
# vendortypeLookupSearchDataSourceCursor(p_RecVendortypeSearch)
#-------------------------------------------------------
# Returns the Vendortype CURSOR for the lookup query
########################################################################################
FUNCTION vendortypeLookupSearchDataSourceCursor(p_RecVendortypeSearch)
	DEFINE p_RecVendortypeSearch OF t_recVendortypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Vendortype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendortype.type_code, ", 
									"vendortype.type_text ",
 
									"FROM vendortype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecVendortypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((type_code LIKE '", p_RecVendortypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR type_text LIKE '",   p_RecVendortypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecVendortypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY type_code"

	CALL c_vendortype.DECLARE(sqlQuery) #CURSOR FOR vendortype
	
	RETURN c_vendortype
END FUNCTION


########################################################################################
# FUNCTION VendortypeLookupFilterDataSource(pRecVendortypeFilter)
#-------------------------------------------------------
# CALLS VendortypeLookupFilterDataSourceCursor(pRecVendortypeFilter) with the VendortypeFilter data TO get a CURSOR
# Returns the Vendortype list array arrVendortypeList
########################################################################################
FUNCTION VendortypeLookupFilterDataSource(pRecVendortypeFilter)
	DEFINE pRecVendortypeFilter OF t_recVendortypeFilter
	DEFINE recVendortype OF t_recVendortype
	DEFINE arrVendortypeList DYNAMIC ARRAY OF t_recVendortype 
	DEFINE c_Vendortype CURSOR
	DEFINE retError SMALLINT
		
	CALL VendortypeLookupFilterDataSourceCursor(pRecVendortypeFilter.*) RETURNING c_Vendortype
	
	CALL arrVendortypeList.CLEAR()

	CALL c_Vendortype.SetResults(recVendortype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Vendortype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Vendortype.FetchNext()=0)
		CALL arrVendortypeList.append([recVendortype.type_code, recVendortype.type_text])
	END WHILE	

	END IF
	
	IF arrVendortypeList.getSize() = 0 THEN
		ERROR "No vendortype's found with the specified filter criteria"
	END IF
	
	RETURN arrVendortypeList
END FUNCTION	

########################################################################################
# FUNCTION VendortypeLookupSearchDataSource(pRecVendortypeFilter)
#-------------------------------------------------------
# CALLS VendortypeLookupSearchDataSourceCursor(pRecVendortypeFilter) with the VendortypeFilter data TO get a CURSOR
# Returns the Vendortype list array arrVendortypeList
########################################################################################
FUNCTION VendortypeLookupSearchDataSource(p_recVendortypeSearch)
	DEFINE p_recVendortypeSearch OF t_recVendortypeSearch	
	DEFINE recVendortype OF t_recVendortype
	DEFINE arrVendortypeList DYNAMIC ARRAY OF t_recVendortype 
	DEFINE c_Vendortype CURSOR
	DEFINE retError SMALLINT	
	CALL VendortypeLookupSearchDataSourceCursor(p_recVendortypeSearch) RETURNING c_Vendortype
	
	CALL arrVendortypeList.CLEAR()

	CALL c_Vendortype.SetResults(recVendortype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Vendortype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Vendortype.FetchNext()=0)
		CALL arrVendortypeList.append([recVendortype.type_code, recVendortype.type_text])
	END WHILE	

	END IF
	
	IF arrVendortypeList.getSize() = 0 THEN
		ERROR "No vendortype's found with the specified filter criteria"
	END IF
	
	RETURN arrVendortypeList
END FUNCTION


########################################################################################
# FUNCTION vendortypeLookup_filter(pVendortypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Vendortype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Vendortype Code type_code
#
# Example:
# 			LET pr_Vendortype.type_code = VendortypeLookup(pr_Vendortype.type_code)
########################################################################################
FUNCTION vendortypeLookup_filter(pVendortypeCode)
	DEFINE pVendortypeCode LIKE Vendortype.type_code
	DEFINE arrVendortypeList DYNAMIC ARRAY OF t_recVendortype
	DEFINE recVendortypeFilter OF t_recVendortypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendortypeLookup WITH FORM "VendortypeLookup_filter"


	CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendortypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendortypeList TO scVendortypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendortypeCode = arrVendortypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendortypeFilter.filter_type_code IS NOT NULL
			OR recVendortypeFilter.filter_type_text IS NOT NULL

		THEN
			LET recVendortypeFilter.filter_type_code = NULL
			LET recVendortypeFilter.filter_type_text = NULL

			CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recVendortypeFilter.filter_type_code IS NOT NULL THEN
			LET recVendortypeFilter.filter_type_code = NULL
			CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_type_text"
		IF recVendortypeFilter.filter_type_text IS NOT NULL THEN
			LET recVendortypeFilter.filter_type_text = NULL
			CALL VendortypeLookupFilterDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendortypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendortypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION vendortypeLookup(pVendortypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Vendortype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendortypeLookupSearchDataSource(recVendortypeFilter.*) RETURNING arrVendortypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Vendortype Code type_code
#
# Example:
# 			LET pr_Vendortype.type_code = VendortypeLookup(pr_Vendortype.type_code)
########################################################################################
FUNCTION vendortypeLookup(pVendortypeCode)
	DEFINE pVendortypeCode LIKE Vendortype.type_code
	DEFINE arrVendortypeList DYNAMIC ARRAY OF t_recVendortype
	DEFINE recVendortypeSearch OF t_recVendortypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendortypeLookup WITH FORM "vendortypeLookup"

	CALL VendortypeLookupSearchDataSource(recVendortypeSearch.*) RETURNING arrVendortypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendortypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL VendortypeLookupSearchDataSource(recVendortypeSearch.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendortypeList TO scVendortypeList.* 
		BEFORE ROW
			IF arrVendortypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendortypeCode = arrVendortypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendortypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recVendortypeSearch.filter_any_field = NULL

			CALL VendortypeLookupSearchDataSource(recVendortypeSearch.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recVendortypeSearch.filter_any_field IS NOT NULL THEN
			LET recVendortypeSearch.filter_any_field = NULL
			CALL VendortypeLookupSearchDataSource(recVendortypeSearch.*) RETURNING arrVendortypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendortypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendortypeCode	
END FUNCTION				

############################################
# FUNCTION import_vendortype()
############################################
FUNCTION import_vendortype()
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
	
	DEFINE rec_vendortype OF t_recVendortype_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wVendortypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Type List Data (table: vendortype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_vendortype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_vendortype(
	    type_code CHAR(3),
	    type_text CHAR(20),
	    pay_acct_code CHAR(18),
	    freight_acct_code CHAR(18),
	    salestax_acct_code CHAR(18),
	    disc_acct_code CHAR(18),
	    exch_acct_code CHAR(18),
	    withhold_tax_ind CHAR(1),
	    tax_vend_code CHAR(8)		
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_vendortype	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wVendortypeImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wVendortypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/vendortype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_vendortype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_vendortype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_vendortype
			LET importReport = importReport, "Code:", trim(rec_vendortype.type_code) , "     -     Desc:", trim(rec_vendortype.type_text), "\n"
					
			INSERT INTO vendortype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_vendortype.*
			{type_code,
			rec_vendortype.type_text,
			rec_vendortype.pay_acct_code,
			rec_vendortype.freight_acct_code,
			rec_vendortype.salestax_acct_code,
			rec_vendortype.disc_acct_code,
			rec_vendortype.exch_acct_code,
			rec_vendortype.withhold_tax_ind,
			rec_vendortype.tax_vend_code
			}
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_vendortype.type_code) , "     -     Desc:", trim(rec_vendortype.type_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wVendortypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_vendortypeRec(p_cmpy_code, p_type_code)
########################################################
FUNCTION exist_vendortypeRec(p_cmpy_code, p_type_code)
	DEFINE p_cmpy_code LIKE vendortype.cmpy_code
	DEFINE p_type_code LIKE vendortype.type_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM vendortype 
     WHERE cmpy_code = p_cmpy_code
     AND type_code = p_type_code

	DROP TABLE temp_vendortype
	CLOSE WINDOW wVendortypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_vendortype()
###############################################################
FUNCTION unload_vendortype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/vendortype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM vendortype ORDER BY cmpy_code, type_code ASC
	
	LET tmpMsg = "All vendortype data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("vendortype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_vendortype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_vendortype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE vendortype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wvendortypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "vendortype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing vendortype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM vendortype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table vendortype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table vendortype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wVendortypeImport		
END FUNCTION	