GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getSalesPersonCount()
# FUNCTION salespersonLookupFilterDataSourceCursor(pRecSalesPersonFilter)
# FUNCTION salespersonLookupSearchDataSourceCursor(p_RecSalesPersonSearch)
# FUNCTION SalesPersonLookupFilterDataSource(pRecSalesPersonFilter)
# FUNCTION salespersonLookup_filter(pSalesPersonCode)
# FUNCTION import_salesPerson()
# FUNCTION exist_salespersonRec(p_cmpy_code, p_sale_code)
# FUNCTION delete_salesperson_all()
# FUNCTION salesPersonMenu()						-- Offer different OPTIONS of this library via a menu

# SalesPerson record types
	DEFINE t_recSalesPerson  
		TYPE AS RECORD
			sale_code LIKE salesperson.sale_code,
			name_text LIKE salesperson.name_text
		END RECORD 

	DEFINE t_recSalesPersonFilter  
		TYPE AS RECORD
			filter_sale_code LIKE salesperson.sale_code,
			filter_name_text LIKE salesperson.name_text
		END RECORD 

	DEFINE t_recSalesPersonSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recSalesPerson_noCmpyId 
		TYPE AS RECORD 
    sale_code LIKE salesperson.sale_code,
    name_text LIKE salesperson.name_text,
    comm_per LIKE salesperson.comm_per,
    terri_code LIKE salesperson.terri_code,
    ytds_amt LIKE salesperson.ytds_amt,
    mtds_amt LIKE salesperson.mtds_amt,
    mtdc_amt LIKE salesperson.mtdc_amt,
    ytdc_amt LIKE salesperson.ytdc_amt,
    comm_ind LIKE salesperson.comm_ind,
    sale_type_ind LIKE salesperson.sale_type_ind,
    addr1_text LIKE salesperson.addr1_text,
    addr2_text LIKE salesperson.addr2_text,
    city_text LIKE salesperson.city_text,
    state_code LIKE salesperson.state_code,
    post_code LIKE salesperson.post_code,
    country_code LIKE salesperson.country_code,
    language_code LIKE salesperson.language_code,
    fax_text LIKE salesperson.fax_text,
    tele_text LIKE salesperson.tele_text,
    alt_tele_text LIKE salesperson.alt_tele_text,
    com1_text LIKE salesperson.com1_text,
    com2_text LIKE salesperson.com2_text,
    ware_code LIKE salesperson.ware_code,
    share_per LIKE salesperson.share_per,
    mgr_code LIKE salesperson.mgr_code,
    acct_mask_code LIKE salesperson.acct_mask_code    
    
	END RECORD	

	
########################################################################################
# FUNCTION salesPersonMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION salesPersonMenu()
	MENU
		ON ACTION "Import"
			CALL import_salesPerson()
		ON ACTION "Export"
			CALL unload_salesPerson(1,"bak")
		#ON ACTION "Import"
		#	CALL import_salesPerson()
		ON ACTION "Delete All"
			CALL delete_salesperson_all()
		ON ACTION "Count"
			CALL getSalesPersonCount() --Count all salesperson rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getSalesPersonCount()
#-------------------------------------------------------
# Returns the number of SalesPerson entries for the current company
########################################################################################
FUNCTION getSalesPersonCount()
	DEFINE ret_SalesPersonCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_SalesPerson CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM SalesPerson ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_SalesPerson.DECLARE(sqlQuery) #CURSOR FOR getSalesPerson
	CALL c_SalesPerson.SetResults(ret_SalesPersonCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_SalesPerson.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_SalesPersonCount = -1
	ELSE
		CALL c_SalesPerson.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Sales Person:", trim(ret_SalesPersonCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Sales Manager Count", tempMsg,"info") 	
	END IF

	RETURN ret_SalesPersonCount
END FUNCTION

########################################################################################
# FUNCTION salespersonLookupFilterDataSourceCursor(pRecSalesPersonFilter)
#-------------------------------------------------------
# Returns the SalesPerson CURSOR for the lookup query
########################################################################################
FUNCTION salespersonLookupFilterDataSourceCursor(pRecSalesPersonFilter)
	DEFINE pRecSalesPersonFilter OF t_recSalesPersonFilter
	DEFINE sqlQuery STRING
	DEFINE c_SalesPerson CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salesperson.sale_code, ", 
									"salesperson.name_text ",
									"FROM salesperson ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecSalesPersonFilter.filter_sale_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND sale_code LIKE '", pRecSalesPersonFilter.filter_sale_code CLIPPED, "%' "  
	END IF									

	IF pRecSalesPersonFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecSalesPersonFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY sale_code"

	CALL c_salesperson.DECLARE(sqlQuery)
		
	RETURN c_salesperson
END FUNCTION



########################################################################################
# salespersonLookupSearchDataSourceCursor(p_RecSalesPersonSearch)
#-------------------------------------------------------
# Returns the SalesPerson CURSOR for the lookup query
########################################################################################
FUNCTION salespersonLookupSearchDataSourceCursor(p_RecSalesPersonSearch)
	DEFINE p_RecSalesPersonSearch OF t_recSalesPersonSearch  
	DEFINE sqlQuery STRING
	DEFINE c_SalesPerson CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salesperson.sale_code, ", 
									"salesperson.name_text ",
 
									"FROM salesperson ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecSalesPersonSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((sale_code LIKE '", p_RecSalesPersonSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecSalesPersonSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecSalesPersonSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY sale_code"

	CALL c_salesperson.DECLARE(sqlQuery) #CURSOR FOR salesperson
	
	RETURN c_salesperson
END FUNCTION


########################################################################################
# FUNCTION SalesPersonLookupFilterDataSource(pRecSalesPersonFilter)
#-------------------------------------------------------
# CALLS SalesPersonLookupFilterDataSourceCursor(pRecSalesPersonFilter) with the SalesPersonFilter data TO get a CURSOR
# Returns the SalesPerson list array arrSalesPersonList
########################################################################################
FUNCTION SalesPersonLookupFilterDataSource(pRecSalesPersonFilter)
	DEFINE pRecSalesPersonFilter OF t_recSalesPersonFilter
	DEFINE recSalesPerson OF t_recSalesPerson
	DEFINE arrSalesPersonList DYNAMIC ARRAY OF t_recSalesPerson 
	DEFINE c_SalesPerson CURSOR
	DEFINE retError SMALLINT
		
	CALL SalesPersonLookupFilterDataSourceCursor(pRecSalesPersonFilter.*) RETURNING c_SalesPerson
	
	CALL arrSalesPersonList.CLEAR()

	CALL c_SalesPerson.SetResults(recSalesPerson.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_SalesPerson.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_SalesPerson.FetchNext()=0)
		CALL arrSalesPersonList.append([recSalesPerson.sale_code, recSalesPerson.name_text])
	END WHILE	

	END IF
	
	IF arrSalesPersonList.getSize() = 0 THEN
		ERROR "No salesperson's found with the specified filter criteria"
	END IF
	
	RETURN arrSalesPersonList
END FUNCTION	

########################################################################################
# FUNCTION SalesPersonLookupSearchDataSource(pRecSalesPersonFilter)
#-------------------------------------------------------
# CALLS SalesPersonLookupSearchDataSourceCursor(pRecSalesPersonFilter) with the SalesPersonFilter data TO get a CURSOR
# Returns the SalesPerson list array arrSalesPersonList
########################################################################################
FUNCTION SalesPersonLookupSearchDataSource(p_recSalesPersonSearch)
	DEFINE p_recSalesPersonSearch OF t_recSalesPersonSearch	
	DEFINE recSalesPerson OF t_recSalesPerson
	DEFINE arrSalesPersonList DYNAMIC ARRAY OF t_recSalesPerson 
	DEFINE c_SalesPerson CURSOR
	DEFINE retError SMALLINT	
	CALL SalesPersonLookupSearchDataSourceCursor(p_recSalesPersonSearch) RETURNING c_SalesPerson
	
	CALL arrSalesPersonList.CLEAR()

	CALL c_SalesPerson.SetResults(recSalesPerson.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_SalesPerson.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_SalesPerson.FetchNext()=0)
		CALL arrSalesPersonList.append([recSalesPerson.sale_code, recSalesPerson.name_text])
	END WHILE	

	END IF
	
	IF arrSalesPersonList.getSize() = 0 THEN
		ERROR "No salesperson's found with the specified filter criteria"
	END IF
	
	RETURN arrSalesPersonList
END FUNCTION


########################################################################################
# FUNCTION salespersonLookup_filter(pSalesPersonCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required SalesPerson code sale_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the SalesPerson Code sale_code
#
# Example:
# 			LET pr_SalesPerson.sale_code = SalesPersonLookup(pr_SalesPerson.sale_code)
########################################################################################
FUNCTION salespersonLookup_filter(pSalesPersonCode)
	DEFINE pSalesPersonCode LIKE SalesPerson.sale_code
	DEFINE arrSalesPersonList DYNAMIC ARRAY OF t_recSalesPerson
	DEFINE recSalesPersonFilter OF t_recSalesPersonFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSalesPersonLookup WITH FORM "SalesPersonLookup_filter"


	CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSalesPersonFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSalesPersonList TO scSalesPersonList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSalesPersonCode = arrSalesPersonList[idx].sale_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSalesPersonFilter.filter_sale_code IS NOT NULL
			OR recSalesPersonFilter.filter_name_text IS NOT NULL

		THEN
			LET recSalesPersonFilter.filter_sale_code = NULL
			LET recSalesPersonFilter.filter_name_text = NULL

			CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_sale_code"
		IF recSalesPersonFilter.filter_sale_code IS NOT NULL THEN
			LET recSalesPersonFilter.filter_sale_code = NULL
			CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recSalesPersonFilter.filter_name_text IS NOT NULL THEN
			LET recSalesPersonFilter.filter_name_text = NULL
			CALL SalesPersonLookupFilterDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSalesPersonLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSalesPersonCode	
END FUNCTION				
		

########################################################################################
# FUNCTION salespersonLookup(pSalesPersonCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required SalesPerson code sale_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SalesPersonLookupSearchDataSource(recSalesPersonFilter.*) RETURNING arrSalesPersonList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the SalesPerson Code sale_code
#
# Example:
# 			LET pr_SalesPerson.sale_code = SalesPersonLookup(pr_SalesPerson.sale_code)
########################################################################################
FUNCTION salespersonLookup(pSalesPersonCode)
	DEFINE pSalesPersonCode LIKE SalesPerson.sale_code
	DEFINE arrSalesPersonList DYNAMIC ARRAY OF t_recSalesPerson
	DEFINE recSalesPersonSearch OF t_recSalesPersonSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSalesPersonLookup WITH FORM "salespersonLookup"

	CALL SalesPersonLookupSearchDataSource(recSalesPersonSearch.*) RETURNING arrSalesPersonList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSalesPersonSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL SalesPersonLookupSearchDataSource(recSalesPersonSearch.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSalesPersonList TO scSalesPersonList.* 
		BEFORE ROW
			IF arrSalesPersonList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSalesPersonCode = arrSalesPersonList[idx].sale_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSalesPersonSearch.filter_any_field IS NOT NULL

		THEN
			LET recSalesPersonSearch.filter_any_field = NULL

			CALL SalesPersonLookupSearchDataSource(recSalesPersonSearch.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_sale_code"
		IF recSalesPersonSearch.filter_any_field IS NOT NULL THEN
			LET recSalesPersonSearch.filter_any_field = NULL
			CALL SalesPersonLookupSearchDataSource(recSalesPersonSearch.*) RETURNING arrSalesPersonList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSalesPersonLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSalesPersonCode	
END FUNCTION				

############################################
# FUNCTION import_salesPerson()
############################################
FUNCTION import_salesPerson()
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
	
	DEFINE rec_salesperson OF t_recSalesPerson_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wSalesPersonImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Sales Manager List Data (table: salesperson)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_salesperson
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_salesPerson(

    #cmpy_code CHAR(2),
    sale_code CHAR(8),
    name_text CHAR(30),
    comm_per DECIMAL(6,3),
    terri_code CHAR(5),
    ytds_amt DECIMAL(16,2),
    mtds_amt DECIMAL(16,2),
    mtdc_amt DECIMAL(16,2),
    ytdc_amt DECIMAL(16,2),
    comm_ind CHAR(1),
    sale_type_ind CHAR(1),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(20),
    state_code CHAR(6),
    post_code CHAR(10),
    country_code CHAR(3),
    language_code CHAR(3),
    fax_text CHAR(20),
    tele_text CHAR(20),
    alt_tele_text CHAR(20),
    com1_text CHAR(30),
    com2_text CHAR(30),
    ware_code CHAR(3),
    share_per DECIMAL(2,0),
    mgr_code CHAR(8),
    acct_mask_code CHAR(18)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_salesperson	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

		CASE 
			WHEN gl_setupRec_default_company.country_code = "NUL"
				LET msgString = "Sales-Person country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Sales-Person country code does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN		
			WHEN gl_setupRec_default_company.country_code = "0"
				--company code comp_code does NOT exist
				LET msgString = "Sales-Person code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Sales-Person does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN
			OTHERWISE
				LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wSalesPersonImport WITH FORM "per/setup/lib_db_data_import_01"
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
							CALL fgl_winmessage("Sales-Person country code does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN		
						WHEN gl_setupRec_default_company.country_code = "0"
							--company code comp_code does NOT exist
							LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Sales-Person does NOT exist",msgString,"error")
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
					CLOSE WINDOW wSalesPersonImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/salesperson-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Sales-Person Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_salesperson

		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_salesperson
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_salesperson
			LET importReport = importReport, "Code:", trim(rec_salesperson.sale_code) , "     -     Desc:", trim(rec_salesperson.name_text), "\n"
					
			INSERT INTO salesperson VALUES(
			gl_setupRec_default_company.cmpy_code,
	
	    rec_salesperson.sale_code,
	    rec_salesperson.name_text,
	    rec_salesperson.comm_per,
	    rec_salesperson.terri_code,
	    rec_salesperson.ytds_amt,
	    rec_salesperson.mtds_amt,
	    rec_salesperson.mtdc_amt,
	    rec_salesperson.ytdc_amt,
	    rec_salesperson.comm_ind,
	    rec_salesperson.sale_type_ind,
	    rec_salesperson.addr1_text,
	    rec_salesperson.addr2_text,
	    rec_salesperson.city_text,
	    rec_salesperson.state_code,
	    rec_salesperson.post_code,
	    rec_salesperson.country_code,
	    rec_salesperson.language_code,
	    rec_salesperson.fax_text,
	    rec_salesperson.tele_text,
	    rec_salesperson.alt_tele_text,
	    rec_salesperson.com1_text,
	    rec_salesperson.com2_text,
	    rec_salesperson.ware_code,
	    rec_salesperson.share_per,
	    rec_salesperson.mgr_code,
	    rec_salesperson.acct_mask_code		

			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_salesperson.sale_code) , "     -     Desc:", trim(rec_salesperson.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wSalesPersonImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_salespersonRec(p_cmpy_code, p_sale_code)
########################################################
FUNCTION exist_salespersonRec(p_cmpy_code, p_sale_code)
	DEFINE p_cmpy_code LIKE salesperson.cmpy_code
	DEFINE p_sale_code LIKE salesperson.sale_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM salesperson 
     WHERE cmpy_code = p_cmpy_code
     AND sale_code = p_sale_code

	DROP TABLE temp_salesperson
	CLOSE WINDOW wSalesPersonImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_salesPerson(p_silentMode,p_fileExtension)
###############################################################
FUNCTION unload_salesPerson(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/salesperson-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM salesperson ORDER BY cmpy_code, sale_code ASC
	
	LET tmpMsg = "All salesperson data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("salesperson Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_salesperson_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_salesperson_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE salesperson.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wsalespersonImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "salesperson Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing salesperson table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM salesperson
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table salesperson!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table salesperson where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wSalesPersonImport		
END FUNCTION	