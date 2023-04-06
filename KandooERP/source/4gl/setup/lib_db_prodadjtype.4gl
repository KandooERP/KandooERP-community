GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getProdAdjTypeCount()
# FUNCTION prodadjtypeLookupFilterDataSourceCursor(pRecProdAdjTypeFilter)
# FUNCTION prodadjtypeLookupSearchDataSourceCursor(p_RecProdAdjTypeSearch)
# FUNCTION ProdAdjTypeLookupFilterDataSource(pRecProdAdjTypeFilter)
# FUNCTION prodadjtypeLookup_filter(pProdAdjTypeCode)
# FUNCTION import_prodadjtype()
# FUNCTION exist_prodadjtypeRec(p_cmpy_code, p_adj_type_code)
# FUNCTION delete_prodadjtype_all()
# FUNCTION prodAdjTypeMenu()						-- Offer different OPTIONS of this library via a menu

# ProdAdjType record types
	DEFINE t_recProdAdjType  
		TYPE AS RECORD
			source_code LIKE prodadjtype.adj_type_code,
			desc_text LIKE prodadjtype.desc_text
		END RECORD 

	DEFINE t_recProdAdjTypeFilter  
		TYPE AS RECORD
			filter_adj_type_code LIKE prodadjtype.adj_type_code,
			filter_desc_text LIKE prodadjtype.desc_text
		END RECORD 

	DEFINE t_recProdAdjTypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recProdAdjType_noCmpyId 
		TYPE AS RECORD 
    source_code LIKE prodadjtype.adj_type_code,
    desc_text LIKE prodadjtype.desc_text,
    adj_acct_code LIKE prodadjtype.adj_acct_code
	END RECORD	

	
########################################################################################
# FUNCTION prodAdjTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION prodAdjTypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_prodadjtype()
		ON ACTION "Export"
			CALL unload_prodadjtype()
		#ON ACTION "Import"
		#	CALL import_prodadjtype()
		ON ACTION "Delete All"
			CALL delete_prodadjtype_all()
		ON ACTION "Count"
			CALL getProdAdjTypeCount() --Count all prodadjtype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getProdAdjTypeCount()
#-------------------------------------------------------
# Returns the number of ProdAdjType entries for the current company
########################################################################################
FUNCTION getProdAdjTypeCount()
	DEFINE ret_ProdAdjTypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ProdAdjType CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM ProdAdjType ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_ProdAdjType.DECLARE(sqlQuery) #CURSOR FOR getProdAdjType
	CALL c_ProdAdjType.SetResults(ret_ProdAdjTypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_ProdAdjType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ProdAdjTypeCount = -1
	ELSE
		CALL c_ProdAdjType.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product Adjustment Types:", trim(ret_ProdAdjTypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Adjustment Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_ProdAdjTypeCount
END FUNCTION

########################################################################################
# FUNCTION prodadjtypeLookupFilterDataSourceCursor(pRecProdAdjTypeFilter)
#-------------------------------------------------------
# Returns the ProdAdjType CURSOR for the lookup query
########################################################################################
FUNCTION prodadjtypeLookupFilterDataSourceCursor(pRecProdAdjTypeFilter)
	DEFINE pRecProdAdjTypeFilter OF t_recProdAdjTypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_ProdAdjType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodadjtype.adj_type_code, ", 
									"prodadjtype.desc_text ",
									"FROM prodadjtype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecProdAdjTypeFilter.filter_adj_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND source_code LIKE '", pRecProdAdjTypeFilter.filter_adj_type_code CLIPPED, "%' "  
	END IF									

	IF pRecProdAdjTypeFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecProdAdjTypeFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY source_code"

	CALL c_prodadjtype.DECLARE(sqlQuery)
		
	RETURN c_prodadjtype
END FUNCTION



########################################################################################
# prodadjtypeLookupSearchDataSourceCursor(p_RecProdAdjTypeSearch)
#-------------------------------------------------------
# Returns the ProdAdjType CURSOR for the lookup query
########################################################################################
FUNCTION prodadjtypeLookupSearchDataSourceCursor(p_RecProdAdjTypeSearch)
	DEFINE p_RecProdAdjTypeSearch OF t_recProdAdjTypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_ProdAdjType CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodadjtype.adj_type_code, ", 
									"prodadjtype.desc_text ",
 
									"FROM prodadjtype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecProdAdjTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((source_code LIKE '", p_RecProdAdjTypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecProdAdjTypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecProdAdjTypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY source_code"

	CALL c_prodadjtype.DECLARE(sqlQuery) #CURSOR FOR prodadjtype
	
	RETURN c_prodadjtype
END FUNCTION


########################################################################################
# FUNCTION ProdAdjTypeLookupFilterDataSource(pRecProdAdjTypeFilter)
#-------------------------------------------------------
# CALLS ProdAdjTypeLookupFilterDataSourceCursor(pRecProdAdjTypeFilter) with the ProdAdjTypeFilter data TO get a CURSOR
# Returns the ProdAdjType list array arrProdAdjTypeList
########################################################################################
FUNCTION ProdAdjTypeLookupFilterDataSource(pRecProdAdjTypeFilter)
	DEFINE pRecProdAdjTypeFilter OF t_recProdAdjTypeFilter
	DEFINE recProdAdjType OF t_recProdAdjType
	DEFINE arrProdAdjTypeList DYNAMIC ARRAY OF t_recProdAdjType 
	DEFINE c_ProdAdjType CURSOR
	DEFINE retError SMALLINT
		
	CALL ProdAdjTypeLookupFilterDataSourceCursor(pRecProdAdjTypeFilter.*) RETURNING c_ProdAdjType
	
	CALL arrProdAdjTypeList.CLEAR()

	CALL c_ProdAdjType.SetResults(recProdAdjType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdAdjType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdAdjType.FetchNext()=0)
		CALL arrProdAdjTypeList.append([recprodadjtype.adj_type_code, recProdAdjType.desc_text])
	END WHILE	

	END IF
	
	IF arrProdAdjTypeList.getSize() = 0 THEN
		ERROR "No prodadjtype's found with the specified filter criteria"
	END IF
	
	RETURN arrProdAdjTypeList
END FUNCTION	

########################################################################################
# FUNCTION ProdAdjTypeLookupSearchDataSource(pRecProdAdjTypeFilter)
#-------------------------------------------------------
# CALLS ProdAdjTypeLookupSearchDataSourceCursor(pRecProdAdjTypeFilter) with the ProdAdjTypeFilter data TO get a CURSOR
# Returns the ProdAdjType list array arrProdAdjTypeList
########################################################################################
FUNCTION ProdAdjTypeLookupSearchDataSource(p_recProdAdjTypeSearch)
	DEFINE p_recProdAdjTypeSearch OF t_recProdAdjTypeSearch	
	DEFINE recProdAdjType OF t_recProdAdjType
	DEFINE arrProdAdjTypeList DYNAMIC ARRAY OF t_recProdAdjType 
	DEFINE c_ProdAdjType CURSOR
	DEFINE retError SMALLINT	
	CALL ProdAdjTypeLookupSearchDataSourceCursor(p_recProdAdjTypeSearch) RETURNING c_ProdAdjType
	
	CALL arrProdAdjTypeList.CLEAR()

	CALL c_ProdAdjType.SetResults(recProdAdjType.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdAdjType.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdAdjType.FetchNext()=0)
		CALL arrProdAdjTypeList.append([recprodadjtype.adj_type_code, recProdAdjType.desc_text])
	END WHILE	

	END IF
	
	IF arrProdAdjTypeList.getSize() = 0 THEN
		ERROR "No prodadjtype's found with the specified filter criteria"
	END IF
	
	RETURN arrProdAdjTypeList
END FUNCTION


########################################################################################
# FUNCTION prodadjtypeLookup_filter(pProdAdjTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdAdjType code source_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdAdjType Code source_code
#
# Example:
# 			LET pr_prodadjtype.adj_type_code = ProdAdjTypeLookup(pr_prodadjtype.adj_type_code)
########################################################################################
FUNCTION prodadjtypeLookup_filter(pProdAdjTypeCode)
	DEFINE pProdAdjTypeCode LIKE prodadjtype.adj_type_code
	DEFINE arrProdAdjTypeList DYNAMIC ARRAY OF t_recProdAdjType
	DEFINE recProdAdjTypeFilter OF t_recProdAdjTypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdAdjTypeLookup WITH FORM "ProdAdjTypeLookup_filter"


	CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdAdjTypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdAdjTypeList TO scProdAdjTypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdAdjTypeCode = arrProdAdjTypeList[idx].source_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdAdjTypeFilter.filter_adj_type_code IS NOT NULL
			OR recProdAdjTypeFilter.filter_desc_text IS NOT NULL

		THEN
			LET recProdAdjTypeFilter.filter_adj_type_code = NULL
			LET recProdAdjTypeFilter.filter_desc_text = NULL

			CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_adj_type_code"
		IF recProdAdjTypeFilter.filter_adj_type_code IS NOT NULL THEN
			LET recProdAdjTypeFilter.filter_adj_type_code = NULL
			CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recProdAdjTypeFilter.filter_desc_text IS NOT NULL THEN
			LET recProdAdjTypeFilter.filter_desc_text = NULL
			CALL ProdAdjTypeLookupFilterDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdAdjTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdAdjTypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION prodadjtypeLookup(pProdAdjTypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdAdjType code source_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdAdjTypeLookupSearchDataSource(recProdAdjTypeFilter.*) RETURNING arrProdAdjTypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdAdjType Code source_code
#
# Example:
# 			LET pr_prodadjtype.adj_type_code = ProdAdjTypeLookup(pr_prodadjtype.adj_type_code)
########################################################################################
FUNCTION prodadjtypeLookup(pProdAdjTypeCode)
	DEFINE pProdAdjTypeCode LIKE prodadjtype.adj_type_code
	DEFINE arrProdAdjTypeList DYNAMIC ARRAY OF t_recProdAdjType
	DEFINE recProdAdjTypeSearch OF t_recProdAdjTypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdAdjTypeLookup WITH FORM "prodadjtypeLookup"

	CALL ProdAdjTypeLookupSearchDataSource(recProdAdjTypeSearch.*) RETURNING arrProdAdjTypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdAdjTypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ProdAdjTypeLookupSearchDataSource(recProdAdjTypeSearch.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdAdjTypeList TO scProdAdjTypeList.* 
		BEFORE ROW
			IF arrProdAdjTypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdAdjTypeCode = arrProdAdjTypeList[idx].source_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdAdjTypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recProdAdjTypeSearch.filter_any_field = NULL

			CALL ProdAdjTypeLookupSearchDataSource(recProdAdjTypeSearch.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_adj_type_code"
		IF recProdAdjTypeSearch.filter_any_field IS NOT NULL THEN
			LET recProdAdjTypeSearch.filter_any_field = NULL
			CALL ProdAdjTypeLookupSearchDataSource(recProdAdjTypeSearch.*) RETURNING arrProdAdjTypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdAdjTypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdAdjTypeCode	
END FUNCTION				

############################################
# FUNCTION import_prodadjtype()
############################################
FUNCTION import_prodadjtype()
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
	
	DEFINE rec_prodadjtype OF t_recProdAdjType_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wProdAdjTypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Adjustment Type List Data (table: prodadjtype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_prodadjtype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_prodadjtype(
	    source_code CHAR(8),
	    desc_text CHAR(40),
	    adj_acct_code CHAR(18)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_prodadjtype	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wProdAdjTypeImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wProdAdjTypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/prodadjtype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_prodadjtype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_prodadjtype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_prodadjtype
			LET importReport = importReport, "Code:", trim(rec_prodadjtype.adj_type_code) , "     -     Desc:", trim(rec_prodadjtype.desc_text), "\n"
					
			INSERT INTO prodadjtype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_prodadjtype.*
			{source_code,
			rec_prodadjtype.desc_text,
			rec_prodadjtype.pay_acct_code,
			rec_prodadjtype.freight_acct_code,
			rec_prodadjtype.salestax_acct_code,
			rec_prodadjtype.disc_acct_code,
			rec_prodadjtype.exch_acct_code,
			rec_prodadjtype.withhold_tax_ind,
			rec_prodadjtype.tax_vend_code
			}
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_prodadjtype.adj_type_code) , "     -     Desc:", trim(rec_prodadjtype.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wProdAdjTypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_prodadjtypeRec(p_cmpy_code, p_adj_type_code)
########################################################
FUNCTION exist_prodadjtypeRec(p_cmpy_code, p_adj_type_code)
	DEFINE p_cmpy_code LIKE prodadjtype.cmpy_code
	DEFINE p_adj_type_code LIKE prodadjtype.adj_type_code
	DEFINE recCount INT

	SELECT COUNT(*) INTO recCount 
	FROM prodadjtype 
    WHERE cmpy_code = p_cmpy_code
    AND adj_type_code = p_adj_type_code

	DROP TABLE temp_prodadjtype
	CLOSE WINDOW wProdAdjTypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_prodadjtype()
###############################################################
FUNCTION unload_prodadjtype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/prodadjtype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM prodadjtype ORDER BY cmpy_code, source_code ASC
	
	LET tmpMsg = "All prodadjtype data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("prodadjtype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_prodadjtype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_prodadjtype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE prodadjtype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wprodadjtypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "prodadjtype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing prodadjtype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM prodadjtype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table prodadjtype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table prodadjtype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wProdAdjTypeImport		
END FUNCTION	