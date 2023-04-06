############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"


# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getTaxCount()
# FUNCTION taxLookupFilterDataSourceCursor(pRecTaxFilter)
# FUNCTION taxLookupSearchDataSourceCursor(p_RecTaxSearch)
# FUNCTION TaxLookupFilterDataSource(pRecTaxFilter)
# FUNCTION taxLookup_filter(pTaxCode)
# FUNCTION import_tax(UI_OFF,NULL)
# FUNCTION exist_taxRec(p_cmpy_code, p_tax_code)
# FUNCTION delete_tax_all()
# FUNCTION vendorTypeMenu()						-- Offer different OPTIONS of this library via a menu

# Tax record types
	DEFINE t_recTax  
		TYPE AS RECORD
			tax_code LIKE tax.tax_code,
			desc_text LIKE tax.desc_text
		END RECORD 

	DEFINE t_recTaxFilter  
		TYPE AS RECORD
			filter_tax_code LIKE tax.tax_code,
			filter_desc_text LIKE tax.desc_text
		END RECORD 

	DEFINE t_recTaxSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recTax_noCmpyId 
		TYPE AS RECORD 
    tax_code LIKE tax.tax_code,
    desc_text LIKE tax.desc_text,
    tax_per LIKE tax.tax_per,
    start_date LIKE tax.start_date,
    buy_acct_code LIKE tax.buy_acct_code,
    sell_acct_code LIKE tax.sell_acct_code,
    calc_method_flag LIKE tax.calc_method_flag,
    freight_per LIKE tax.freight_per,
    hand_per LIKE tax.hand_per,
    uplift_per LIKE tax.uplift_per,
    buy_ctl_acct_code LIKE tax.buy_ctl_acct_code,
    buy_clr_acct_code LIKE tax.buy_clr_acct_code,
    buy_adj_acct_code LIKE tax.buy_adj_acct_code,
    sell_ctl_acct_code LIKE tax.sell_ctl_acct_code,
    sell_clr_acct_code LIKE tax.sell_clr_acct_code,
    sell_adj_acct_code LIKE tax.sell_adj_acct_code,
    badj_ctl_acct_code LIKE tax.badj_ctl_acct_code,
    sadj_ctl_acct_code LIKE tax.sadj_ctl_acct_code
	END RECORD	

	
########################################################################################
# FUNCTION taxMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION taxMenu()
	MENU
		ON ACTION "Import"
			CALL import_tax(UI_OFF,NULL)
		ON ACTION "Export"
			CALL unload_tax(UI_OFF,NULL)
		#ON ACTION "Import"
		#	CALL import_tax(UI_OFF,NULL)
		ON ACTION "Delete All"
			CALL delete_tax_all(UI_OFF)
		ON ACTION "Count"
			CALL getTaxCount() --Count all tax rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getTaxCount()
#-------------------------------------------------------
# Returns the number of Tax entries for the current company
########################################################################################
FUNCTION getTaxCount()
	DEFINE ret_TaxCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Tax CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM tax ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Tax.DECLARE(sqlQuery) #CURSOR FOR getTax
	CALL c_Tax.SetResults(ret_TaxCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Tax.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_TaxCount = -1
	ELSE
		CALL c_Tax.FetchNext()
	END IF

	IF gl_setupRec.ui_mode = UI_ON THEN
		LET tempMsg = "Number of Tax Types:", trim(ret_TaxCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Tax Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_TaxCount
END FUNCTION

########################################################################################
# FUNCTION taxLookupFilterDataSourceCursor(pRecTaxFilter)
#-------------------------------------------------------
# Returns the Tax CURSOR for the lookup query
########################################################################################
FUNCTION taxLookupFilterDataSourceCursor(pRecTaxFilter)
	DEFINE pRecTaxFilter OF t_recTaxFilter
	DEFINE sqlQuery STRING
	DEFINE c_Tax CURSOR
	
	LET sqlQuery =	"SELECT ",
									"tax.tax_code, ", 
									"tax.desc_text ",
									"FROM tax ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecTaxFilter.filter_tax_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND tax_code LIKE '", pRecTaxFilter.filter_tax_code CLIPPED, "%' "  
	END IF									

	IF pRecTaxFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecTaxFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY tax_code"

	CALL c_tax.DECLARE(sqlQuery)
		
	RETURN c_tax
END FUNCTION



########################################################################################
# taxLookupSearchDataSourceCursor(p_RecTaxSearch)
#-------------------------------------------------------
# Returns the Tax CURSOR for the lookup query
########################################################################################
FUNCTION taxLookupSearchDataSourceCursor(p_RecTaxSearch)
	DEFINE p_RecTaxSearch OF t_recTaxSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Tax CURSOR
	
	LET sqlQuery =	"SELECT ",
									"tax.tax_code, ", 
									"tax.desc_text ",
 
									"FROM tax ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecTaxSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((tax_code LIKE '", p_RecTaxSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecTaxSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecTaxSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY tax_code"

	CALL c_tax.DECLARE(sqlQuery) #CURSOR FOR tax
	
	RETURN c_tax
END FUNCTION


########################################################################################
# FUNCTION TaxLookupFilterDataSource(pRecTaxFilter)
#-------------------------------------------------------
# CALLS TaxLookupFilterDataSourceCursor(pRecTaxFilter) with the TaxFilter data TO get a CURSOR
# Returns the Tax list array arrTaxList
########################################################################################
FUNCTION TaxLookupFilterDataSource(pRecTaxFilter)
	DEFINE pRecTaxFilter OF t_recTaxFilter
	DEFINE recTax OF t_recTax
	DEFINE arrTaxList DYNAMIC ARRAY OF t_recTax 
	DEFINE c_Tax CURSOR
	DEFINE retError SMALLINT
		
	CALL TaxLookupFilterDataSourceCursor(pRecTaxFilter.*) RETURNING c_Tax
	
	CALL arrTaxList.CLEAR()

	CALL c_Tax.SetResults(recTax.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Tax.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Tax.FetchNext()=0)
		CALL arrTaxList.append([recTax.tax_code, recTax.desc_text])
	END WHILE	

	END IF
	
	IF arrTaxList.getSize() = 0 THEN
		ERROR "No tax's found with the specified filter criteria"
	END IF
	
	RETURN arrTaxList
END FUNCTION	

########################################################################################
# FUNCTION TaxLookupSearchDataSource(pRecTaxFilter)
#-------------------------------------------------------
# CALLS TaxLookupSearchDataSourceCursor(pRecTaxFilter) with the TaxFilter data TO get a CURSOR
# Returns the Tax list array arrTaxList
########################################################################################
FUNCTION TaxLookupSearchDataSource(p_recTaxSearch)
	DEFINE p_recTaxSearch OF t_recTaxSearch	
	DEFINE recTax OF t_recTax
	DEFINE arrTaxList DYNAMIC ARRAY OF t_recTax 
	DEFINE c_Tax CURSOR
	DEFINE retError SMALLINT	
	CALL TaxLookupSearchDataSourceCursor(p_recTaxSearch) RETURNING c_Tax
	
	CALL arrTaxList.CLEAR()

	CALL c_Tax.SetResults(recTax.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Tax.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Tax.FetchNext()=0)
		CALL arrTaxList.append([recTax.tax_code, recTax.desc_text])
	END WHILE	

	END IF
	
	IF arrTaxList.getSize() = 0 THEN
		ERROR "No tax's found with the specified filter criteria"
	END IF
	
	RETURN arrTaxList
END FUNCTION


########################################################################################
# FUNCTION taxLookup_filter(pTaxCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Tax code tax_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Tax Code tax_code
#
# Example:
# 			LET pr_Tax.tax_code = TaxLookup(pr_Tax.tax_code)
########################################################################################
FUNCTION taxLookup_filter(pTaxCode)
	DEFINE pTaxCode LIKE Tax.tax_code
	DEFINE arrTaxList DYNAMIC ARRAY OF t_recTax
	DEFINE recTaxFilter OF t_recTaxFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTaxLookup WITH FORM "TaxLookup_filter"


	CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTaxFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTaxList TO scTaxList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTaxCode = arrTaxList[idx].tax_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTaxFilter.filter_tax_code IS NOT NULL
			OR recTaxFilter.filter_desc_text IS NOT NULL

		THEN
			LET recTaxFilter.filter_tax_code = NULL
			LET recTaxFilter.filter_desc_text = NULL

			CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_tax_code"
		IF recTaxFilter.filter_tax_code IS NOT NULL THEN
			LET recTaxFilter.filter_tax_code = NULL
			CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recTaxFilter.filter_desc_text IS NOT NULL THEN
			LET recTaxFilter.filter_desc_text = NULL
			CALL TaxLookupFilterDataSource(recTaxFilter.*) RETURNING arrTaxList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTaxLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTaxCode	
END FUNCTION				
		

########################################################################################
# FUNCTION taxLookup(pTaxCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Tax code tax_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TaxLookupSearchDataSource(recTaxFilter.*) RETURNING arrTaxList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Tax Code tax_code
#
# Example:
# 			LET pr_Tax.tax_code = TaxLookup(pr_Tax.tax_code)
########################################################################################
FUNCTION taxLookup(pTaxCode)
	DEFINE pTaxCode LIKE Tax.tax_code
	DEFINE arrTaxList DYNAMIC ARRAY OF t_recTax
	DEFINE recTaxSearch OF t_recTaxSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTaxLookup WITH FORM "taxLookup"

	CALL TaxLookupSearchDataSource(recTaxSearch.*) RETURNING arrTaxList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTaxSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL TaxLookupSearchDataSource(recTaxSearch.*) RETURNING arrTaxList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTaxList TO scTaxList.* 
		BEFORE ROW
			IF arrTaxList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTaxCode = arrTaxList[idx].tax_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTaxSearch.filter_any_field IS NOT NULL

		THEN
			LET recTaxSearch.filter_any_field = NULL

			CALL TaxLookupSearchDataSource(recTaxSearch.*) RETURNING arrTaxList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_tax_code"
		IF recTaxSearch.filter_any_field IS NOT NULL THEN
			LET recTaxSearch.filter_any_field = NULL
			CALL TaxLookupSearchDataSource(recTaxSearch.*) RETURNING arrTaxList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTaxLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTaxCode	
END FUNCTION				

############################################
# FUNCTION import_tax(p_ui_mode,p_cmpy_code)
#
#
############################################
FUNCTION import_tax(p_ui_mode,p_cmpy_code)
	DEFINE p_ui_mode SMALLINT
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
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE l_rec_tax RECORD LIKE tax.* #OF tt_recTax_noCmpyId

	IF p_cmpy_code IS NULL then
		LET p_cmpy_code = glob_rec_setup_company.cmpy_code
	END IF

	IF p_ui_mode IS NULL THEN
		LET p_ui_mode = gl_setupRec.ui_mode
	END IF
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF p_ui_mode != UI_OFF THEN	
		OPEN WINDOW wTaxImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Tax Type List Data (table: tax)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_tax
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_tax(
		cmpy_code NCHAR(2),
    tax_code NCHAR(3),
    desc_text NCHAR(30),
    tax_per DECIMAL(6,3),
    start_date DATE,
    buy_acct_code NCHAR(18),
    sell_acct_code NCHAR(18),
    calc_method_flag NCHAR(1),
    freight_per DECIMAL(6,3),
    hand_per DECIMAL(6,3),
    uplift_per float,
    buy_ctl_acct_code NCHAR(18),
    buy_clr_acct_code NCHAR(18),
    buy_adj_acct_code NCHAR(18),
    sell_ctl_acct_code NCHAR(18),
    sell_clr_acct_code NCHAR(18),
    sell_adj_acct_code NCHAR(18),
    badj_ctl_acct_code NCHAR(18),
    sadj_ctl_acct_code NCHAR(18)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_tax	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF p_cmpy_code IS NOT NULL THEN
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_desc_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text

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
	
	IF p_ui_mode != UI_OFF THEN	
	#	OPEN WINDOW wTaxImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT p_cmpy_code, glob_rec_setup_company.country_code,glob_rec_setup_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (p_cmpy_code)
					RETURNING p_desc_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text

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
							DISPLAY p_desc_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text 
							TO company.name_text,country_code,country_text,language_code,language_text
					END CASE 
			END INPUT

		ELSE
			IF p_ui_mode != UI_OFF THEN	
				DISPLAY p_cmpy_code TO cmpy_code

				INPUT p_cmpy_code, glob_rec_setup_company.country_code,glob_rec_setup_company.language_code
					WITHOUT DEFAULTS 
					FROM inputRec3.*  
				END INPUT
				
				IF int_flag THEN
					LET int_flag = FALSE
					CLOSE WINDOW wTaxImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/tax-",glob_rec_setup_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",glob_rec_setup_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		#CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_tax
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_tax
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO l_rec_tax
			LET importReport = importReport, "Code:", trim(l_rec_tax.tax_code) , "     -     Desc:", trim(l_rec_tax.desc_text), "\n"
					
			INSERT INTO tax VALUES(
			p_cmpy_code,
			l_rec_tax.tax_code,
			l_rec_tax.desc_text,
			l_rec_tax.tax_per,
			l_rec_tax.start_date,
			l_rec_tax.buy_acct_code,
			l_rec_tax.sell_acct_code,
			l_rec_tax.calc_method_flag,
			l_rec_tax.freight_per,
			l_rec_tax.hand_per,
			l_rec_tax.uplift_per,
			l_rec_tax.buy_ctl_acct_code,
			l_rec_tax.buy_clr_acct_code,
			l_rec_tax.buy_adj_acct_code,
			l_rec_tax.sell_ctl_acct_code,
			l_rec_tax.sell_clr_acct_code,
			l_rec_tax.sell_adj_acct_code,
			l_rec_tax.badj_ctl_acct_code,
			l_rec_tax.sadj_ctl_acct_code
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(l_rec_tax.tax_code) , "     -     Desc:", trim(l_rec_tax.desc_text), " ->DUPLICATE = Ignored !\n"
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

	IF p_ui_mode != UI_OFF THEN
			
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wTaxImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_taxRec(p_cmpy_code, p_tax_code)
########################################################
FUNCTION exist_taxRec(p_cmpy_code, p_tax_code)
	DEFINE p_cmpy_code LIKE tax.cmpy_code
	DEFINE p_tax_code LIKE tax.tax_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM tax 
     WHERE cmpy_code = p_cmpy_code
     AND tax_code = p_tax_code

	DROP TABLE temp_tax
	CLOSE WINDOW wTaxImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_tax(p_ui_mode,p_fileExtension)
#
#
###############################################################
FUNCTION unload_tax(p_ui_mode,p_fileExtension)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	IF p_fileExtension IS NULL THEN
		LET p_fileExtension = "unl"
	END IF
	
	LET unloadFile = "unl/tax-", trim(glob_rec_setup_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM tax ORDER BY cmpy_code, tax_code ASC
	
	IF p_ui_mode THEN
		LET tmpMsg = "All tax data were exported/written TO:\n", unloadFile
		CALL fgl_winmessage("tax Table Data Unloaded",tmpMsg ,"info")
	END IF
		
END FUNCTION


###############################################################
# FUNCTION delete_tax_all()  NOTE: Delete ALL
#
#
###############################################################
FUNCTION delete_tax_all(p_ui_mode)
	DEFINE p_ui_mode SMALLINT
	#DEFINE p_cmpy_code LIKE tax.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.ui_mode = UI_ON THEN
		OPEN WINDOW wtaxImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "tax Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing tax table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM tax
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table tax!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_ui_mode = UI_ON THEN --no ui
				LET tmpMsg = "All data in the table tax where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF


	CLOSE WINDOW wtaxImport		
END FUNCTION	