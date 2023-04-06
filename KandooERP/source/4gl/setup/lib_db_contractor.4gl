GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getContractorCount()
# FUNCTION contractorLookupFilterDataSourceCursor(pRecContractorFilter)
# FUNCTION contractorLookupSearchDataSourceCursor(p_RecContractorSearch)
# FUNCTION ContractorLookupFilterDataSource(pRecContractorFilter)
# FUNCTION contractorLookup_filter(pContractorCode)
# FUNCTION import_contractor()
# FUNCTION exist_contractorRec(p_cmpy_code, p_vend_code)
# FUNCTION delete_contractor_all()
# FUNCTION contractorMenu()						-- Offer different OPTIONS of this library via a menu

# Contractor record types
	DEFINE t_recContractor  
		TYPE AS RECORD
			vend_code LIKE contractor.vend_code,
			home_phone_text LIKE contractor.home_phone_text
		END RECORD 

	DEFINE t_recContractorFilter  
		TYPE AS RECORD
			filter_vend_code LIKE contractor.vend_code,
			filter_home_phone_text LIKE contractor.home_phone_text
		END RECORD 

	DEFINE t_recContractorSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recContractor_noCmpyId 
		TYPE AS RECORD 
    vend_code LIKE contractor.vend_code,
    home_phone_text LIKE contractor.home_phone_text,
    pager_comp_text LIKE contractor.pager_comp_text,
    pager_num_text LIKE contractor.pager_num_text,
    start_date LIKE contractor.start_date,
    licence_text LIKE contractor.licence_text,
    expiry_date LIKE contractor.expiry_date,
    tax_no_text LIKE contractor.tax_no_text,
    regist_num_text LIKE contractor.regist_num_text,
    tax_rate_qty LIKE contractor.tax_rate_qty,
    variation_text LIKE contractor.variation_text,
    var_exp_date LIKE contractor.var_exp_date,
    account_num_text LIKE contractor.account_num_text,
    union_text LIKE contractor.union_text,
    union_num_text LIKE contractor.union_num_text,
    union_exp_date LIKE contractor.union_exp_date,
    comp_num_text LIKE contractor.comp_num_text,
    insurance_text LIKE contractor.insurance_text,
    ins_exp_date LIKE contractor.ins_exp_date,
    tax_code LIKE contractor.tax_code,
    var_start_date LIKE contractor.var_start_date
	END RECORD	

	
########################################################################################
# FUNCTION contractorMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION contractorMenu()
	MENU
		ON ACTION "Import"
			CALL import_contractor()
		ON ACTION "Export"
			CALL unload_contractor()
		#ON ACTION "Import"
		#	CALL import_contractor()
		ON ACTION "Delete All"
			CALL delete_contractor_all()
		ON ACTION "Count"
			CALL getContractorCount() --Count all contractor rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getContractorCount()
#-------------------------------------------------------
# Returns the number of Contractor entries for the current company
########################################################################################
FUNCTION getContractorCount()
	DEFINE ret_ContractorCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Contractor CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Contractor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Contractor.DECLARE(sqlQuery) #CURSOR FOR getContractor
	CALL c_Contractor.SetResults(ret_ContractorCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Contractor.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ContractorCount = -1
	ELSE
		CALL c_Contractor.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Contractors:", trim(ret_ContractorCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Contractor Count", tempMsg,"info") 	
	END IF

	RETURN ret_ContractorCount
END FUNCTION

########################################################################################
# FUNCTION contractorLookupFilterDataSourceCursor(pRecContractorFilter)
#-------------------------------------------------------
# Returns the Contractor CURSOR for the lookup query
########################################################################################
FUNCTION contractorLookupFilterDataSourceCursor(pRecContractorFilter)
	DEFINE pRecContractorFilter OF t_recContractorFilter
	DEFINE sqlQuery STRING
	DEFINE c_Contractor CURSOR
	
	LET sqlQuery =	"SELECT ",
									"contractor.vend_code, ", 
									"contractor.home_phone_text ",
									"FROM contractor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecContractorFilter.filter_vend_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND vend_code LIKE '", pRecContractorFilter.filter_vend_code CLIPPED, "%' "  
	END IF									

	IF pRecContractorFilter.filter_home_phone_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND home_phone_text LIKE '", pRecContractorFilter.filter_home_phone_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY vend_code"

	CALL c_contractor.DECLARE(sqlQuery)
		
	RETURN c_contractor
END FUNCTION



########################################################################################
# contractorLookupSearchDataSourceCursor(p_RecContractorSearch)
#-------------------------------------------------------
# Returns the Contractor CURSOR for the lookup query
########################################################################################
FUNCTION contractorLookupSearchDataSourceCursor(p_RecContractorSearch)
	DEFINE p_RecContractorSearch OF t_recContractorSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Contractor CURSOR
	
	LET sqlQuery =	"SELECT ",
									"contractor.vend_code, ", 
									"contractor.home_phone_text ",
 
									"FROM contractor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecContractorSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((vend_code LIKE '", p_RecContractorSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR home_phone_text LIKE '",   p_RecContractorSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecContractorSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY vend_code"

	CALL c_contractor.DECLARE(sqlQuery) #CURSOR FOR contractor
	
	RETURN c_contractor
END FUNCTION


########################################################################################
# FUNCTION ContractorLookupFilterDataSource(pRecContractorFilter)
#-------------------------------------------------------
# CALLS ContractorLookupFilterDataSourceCursor(pRecContractorFilter) with the ContractorFilter data TO get a CURSOR
# Returns the Contractor list array arrContractorList
########################################################################################
FUNCTION ContractorLookupFilterDataSource(pRecContractorFilter)
	DEFINE pRecContractorFilter OF t_recContractorFilter
	DEFINE recContractor OF t_recContractor
	DEFINE arrContractorList DYNAMIC ARRAY OF t_recContractor 
	DEFINE c_Contractor CURSOR
	DEFINE retError SMALLINT
		
	CALL ContractorLookupFilterDataSourceCursor(pRecContractorFilter.*) RETURNING c_Contractor
	
	CALL arrContractorList.CLEAR()

	CALL c_Contractor.SetResults(recContractor.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Contractor.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Contractor.FetchNext()=0)
		CALL arrContractorList.append([recContractor.vend_code, recContractor.home_phone_text])
	END WHILE	

	END IF
	
	IF arrContractorList.getSize() = 0 THEN
		ERROR "No contractor's found with the specified filter criteria"
	END IF
	
	RETURN arrContractorList
END FUNCTION	

########################################################################################
# FUNCTION ContractorLookupSearchDataSource(pRecContractorFilter)
#-------------------------------------------------------
# CALLS ContractorLookupSearchDataSourceCursor(pRecContractorFilter) with the ContractorFilter data TO get a CURSOR
# Returns the Contractor list array arrContractorList
########################################################################################
FUNCTION ContractorLookupSearchDataSource(p_recContractorSearch)
	DEFINE p_recContractorSearch OF t_recContractorSearch	
	DEFINE recContractor OF t_recContractor
	DEFINE arrContractorList DYNAMIC ARRAY OF t_recContractor 
	DEFINE c_Contractor CURSOR
	DEFINE retError SMALLINT	
	CALL ContractorLookupSearchDataSourceCursor(p_recContractorSearch) RETURNING c_Contractor
	
	CALL arrContractorList.CLEAR()

	CALL c_Contractor.SetResults(recContractor.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Contractor.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Contractor.FetchNext()=0)
		CALL arrContractorList.append([recContractor.vend_code, recContractor.home_phone_text])
	END WHILE	

	END IF
	
	IF arrContractorList.getSize() = 0 THEN
		ERROR "No contractor's found with the specified filter criteria"
	END IF
	
	RETURN arrContractorList
END FUNCTION


########################################################################################
# FUNCTION contractorLookup_filter(pContractorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Contractor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Contractor Code vend_code
#
# Example:
# 			LET pr_Contractor.vend_code = ContractorLookup(pr_Contractor.vend_code)
########################################################################################
FUNCTION contractorLookup_filter(pContractorCode)
	DEFINE pContractorCode LIKE Contractor.vend_code
	DEFINE arrContractorList DYNAMIC ARRAY OF t_recContractor
	DEFINE recContractorFilter OF t_recContractorFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wContractorLookup WITH FORM "ContractorLookup_filter"


	CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recContractorFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrContractorList TO scContractorList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pContractorCode = arrContractorList[idx].vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recContractorFilter.filter_vend_code IS NOT NULL
			OR recContractorFilter.filter_home_phone_text IS NOT NULL

		THEN
			LET recContractorFilter.filter_vend_code = NULL
			LET recContractorFilter.filter_home_phone_text = NULL

			CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_vend_code"
		IF recContractorFilter.filter_vend_code IS NOT NULL THEN
			LET recContractorFilter.filter_vend_code = NULL
			CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_home_phone_text"
		IF recContractorFilter.filter_home_phone_text IS NOT NULL THEN
			LET recContractorFilter.filter_home_phone_text = NULL
			CALL ContractorLookupFilterDataSource(recContractorFilter.*) RETURNING arrContractorList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wContractorLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pContractorCode	
END FUNCTION				
		

########################################################################################
# FUNCTION contractorLookup(pContractorCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Contractor code vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ContractorLookupSearchDataSource(recContractorFilter.*) RETURNING arrContractorList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Contractor Code vend_code
#
# Example:
# 			LET pr_Contractor.vend_code = ContractorLookup(pr_Contractor.vend_code)
########################################################################################
FUNCTION contractorLookup(pContractorCode)
	DEFINE pContractorCode LIKE Contractor.vend_code
	DEFINE arrContractorList DYNAMIC ARRAY OF t_recContractor
	DEFINE recContractorSearch OF t_recContractorSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wContractorLookup WITH FORM "contractorLookup"

	CALL ContractorLookupSearchDataSource(recContractorSearch.*) RETURNING arrContractorList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recContractorSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ContractorLookupSearchDataSource(recContractorSearch.*) RETURNING arrContractorList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrContractorList TO scContractorList.* 
		BEFORE ROW
			IF arrContractorList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pContractorCode = arrContractorList[idx].vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recContractorSearch.filter_any_field IS NOT NULL

		THEN
			LET recContractorSearch.filter_any_field = NULL

			CALL ContractorLookupSearchDataSource(recContractorSearch.*) RETURNING arrContractorList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_vend_code"
		IF recContractorSearch.filter_any_field IS NOT NULL THEN
			LET recContractorSearch.filter_any_field = NULL
			CALL ContractorLookupSearchDataSource(recContractorSearch.*) RETURNING arrContractorList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wContractorLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pContractorCode	
END FUNCTION				

############################################
# FUNCTION import_contractor()
############################################
FUNCTION import_contractor()
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
	DEFINE p_home_phone_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_contractor OF t_recContractor_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wContractorImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Contractor List Data (table: contractor)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_contractor
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_contractor(
	    vend_code CHAR(8),
	    home_phone_text CHAR(20),
	    pager_comp_text CHAR(15),
	    pager_num_text CHAR(10),
	    start_date DATE,
	    licence_text CHAR(12),
	    expiry_date DATE,
	    tax_no_text CHAR(10),
	    regist_num_text CHAR(10),
	    tax_rate_qty DECIMAL(4,2),
	    variation_text CHAR(10),
	    var_exp_date DATE,
	    account_num_text CHAR(10),
	    union_text CHAR(20),
	    union_num_text CHAR(10),
	    union_exp_date DATE,
	    comp_num_text CHAR(10),
	    insurance_text CHAR(20),
	    ins_exp_date DATE,
	    tax_code CHAR(3),
	    var_start_date date
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_contractor	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_home_phone_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wContractorImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_home_phone_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_home_phone_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wContractorImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/contractor-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_contractor
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_contractor
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_contractor
			LET importReport = importReport, "Code:", trim(rec_contractor.vend_code) , "     -     Desc:", trim(rec_contractor.home_phone_text), "\n"
					
			INSERT INTO contractor VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_contractor.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_contractor.vend_code) , "     -     Desc:", trim(rec_contractor.home_phone_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wContractorImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_contractorRec(p_cmpy_code, p_vend_code)
########################################################
FUNCTION exist_contractorRec(p_cmpy_code, p_vend_code)
	DEFINE p_cmpy_code LIKE contractor.cmpy_code
	DEFINE p_vend_code LIKE contractor.vend_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM contractor 
     WHERE cmpy_code = p_cmpy_code
     AND vend_code = p_vend_code

	DROP TABLE temp_contractor
	CLOSE WINDOW wContractorImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_contractor()
###############################################################
FUNCTION unload_contractor(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/contractor-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM contractor ORDER BY cmpy_code, vend_code ASC
	
	LET tmpMsg = "All contractor data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("contractor Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_contractor_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_contractor_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE contractor.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcontractorImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Contractor List (contractor) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing contractor table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM contractor
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table contractor!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table contractor where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wContractorImport		
END FUNCTION	