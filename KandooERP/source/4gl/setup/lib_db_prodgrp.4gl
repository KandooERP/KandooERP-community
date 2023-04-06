GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getProdGrpCount()
# FUNCTION prodgrpLookupFilterDataSourceCursor(pRecProdGrpFilter)
# FUNCTION prodgrpLookupSearchDataSourceCursor(p_RecProdGrpSearch)
# FUNCTION ProdGrpLookupFilterDataSource(pRecProdGrpFilter)
# FUNCTION prodgrpLookup_filter(pProdGrpCode)
# FUNCTION import_prodgrp()
# FUNCTION exist_prodgrpRec(p_cmpy_code, p_prodgrp_code)
# FUNCTION delete_prodgrp_all()
# FUNCTION prodgrpMenu()						-- Offer different OPTIONS of this library via a menu

# ProdGrp record types
	DEFINE t_recProdGrp  
		TYPE AS RECORD
			prodgrp_code LIKE prodgrp.prodgrp_code,
			desc_text LIKE prodgrp.desc_text
		END RECORD 

	DEFINE t_recProdGrpFilter  
		TYPE AS RECORD
			filter_prodgrp_code LIKE prodgrp.prodgrp_code,
			filter_desc_text LIKE prodgrp.desc_text
		END RECORD 

	DEFINE t_recProdGrpSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recProdGrp_noCmpyId 
		TYPE AS RECORD 
    prodgrp_code LIKE prodgrp.prodgrp_code,
    desc_text LIKE prodgrp.desc_text,
    maingrp_code LIKE prodgrp.maingrp_code,
    min_month_amt LIKE prodgrp.min_month_amt,
    min_quart_amt LIKE prodgrp.min_quart_amt,
    min_year_amt LIKE prodgrp.min_year_amt,
    subdept_code LIKE prodgrp.subdept_code
	END RECORD	

	
########################################################################################
# FUNCTION prodgrpMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION prodGrpMenu()
	MENU
		ON ACTION "Import"
			CALL import_prodgrp()
		ON ACTION "Export"
			CALL unload_prodgrp()
		#ON ACTION "Import"
		#	CALL import_prodgrp()
		ON ACTION "Delete All"
			CALL delete_prodgrp_all()
		ON ACTION "Count"
			CALL getProdGrpCount() --Count all prodgrp rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getProdGrpCount()
#-------------------------------------------------------
# Returns the number of ProdGrp entries for the current company
########################################################################################
FUNCTION getProdGrpCount()
	DEFINE ret_ProdGrpCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ProdGrp CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM ProdGrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_ProdGrp.DECLARE(sqlQuery) #CURSOR FOR getProdGrp
	CALL c_ProdGrp.SetResults(ret_ProdGrpCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_ProdGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ProdGrpCount = -1
	ELSE
		CALL c_ProdGrp.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product Groups:", trim(ret_ProdGrpCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_ProdGrpCount
END FUNCTION

########################################################################################
# FUNCTION prodgrpLookupFilterDataSourceCursor(pRecProdGrpFilter)
#-------------------------------------------------------
# Returns the ProdGrp CURSOR for the lookup query
########################################################################################
FUNCTION prodgrpLookupFilterDataSourceCursor(pRecProdGrpFilter)
	DEFINE pRecProdGrpFilter OF t_recProdGrpFilter
	DEFINE sqlQuery STRING
	DEFINE c_ProdGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodgrp.prodgrp_code, ", 
									"prodgrp.desc_text ",
									"FROM prodgrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecProdGrpFilter.filter_prodgrp_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND prodgrp_code LIKE '", pRecProdGrpFilter.filter_prodgrp_code CLIPPED, "%' "  
	END IF									

	IF pRecProdGrpFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecProdGrpFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY prodgrp_code"

	CALL c_prodgrp.DECLARE(sqlQuery)
		
	RETURN c_prodgrp
END FUNCTION



########################################################################################
# prodgrpLookupSearchDataSourceCursor(p_RecProdGrpSearch)
#-------------------------------------------------------
# Returns the ProdGrp CURSOR for the lookup query
########################################################################################
FUNCTION prodgrpLookupSearchDataSourceCursor(p_RecProdGrpSearch)
	DEFINE p_RecProdGrpSearch OF t_recProdGrpSearch  
	DEFINE sqlQuery STRING
	DEFINE c_ProdGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodgrp.prodgrp_code, ", 
									"prodgrp.desc_text ",
 
									"FROM prodgrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecProdGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((prodgrp_code LIKE '", p_RecProdGrpSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecProdGrpSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecProdGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY prodgrp_code"

	CALL c_prodgrp.DECLARE(sqlQuery) #CURSOR FOR prodgrp
	
	RETURN c_prodgrp
END FUNCTION


########################################################################################
# FUNCTION ProdGrpLookupFilterDataSource(pRecProdGrpFilter)
#-------------------------------------------------------
# CALLS ProdGrpLookupFilterDataSourceCursor(pRecProdGrpFilter) with the ProdGrpFilter data TO get a CURSOR
# Returns the ProdGrp list array arrProdGrpList
########################################################################################
FUNCTION ProdGrpLookupFilterDataSource(pRecProdGrpFilter)
	DEFINE pRecProdGrpFilter OF t_recProdGrpFilter
	DEFINE recProdGrp OF t_recProdGrp
	DEFINE arrProdGrpList DYNAMIC ARRAY OF t_recProdGrp 
	DEFINE c_ProdGrp CURSOR
	DEFINE retError SMALLINT
		
	CALL ProdGrpLookupFilterDataSourceCursor(pRecProdGrpFilter.*) RETURNING c_ProdGrp
	
	CALL arrProdGrpList.CLEAR()

	CALL c_ProdGrp.SetResults(recProdGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdGrp.FetchNext()=0)
		CALL arrProdGrpList.append([recProdGrp.prodgrp_code, recProdGrp.desc_text])
	END WHILE	

	END IF
	
	IF arrProdGrpList.getSize() = 0 THEN
		ERROR "No prodgrp's found with the specified filter criteria"
	END IF
	
	RETURN arrProdGrpList
END FUNCTION	

########################################################################################
# FUNCTION ProdGrpLookupSearchDataSource(pRecProdGrpFilter)
#-------------------------------------------------------
# CALLS ProdGrpLookupSearchDataSourceCursor(pRecProdGrpFilter) with the ProdGrpFilter data TO get a CURSOR
# Returns the ProdGrp list array arrProdGrpList
########################################################################################
FUNCTION ProdGrpLookupSearchDataSource(p_recProdGrpSearch)
	DEFINE p_recProdGrpSearch OF t_recProdGrpSearch	
	DEFINE recProdGrp OF t_recProdGrp
	DEFINE arrProdGrpList DYNAMIC ARRAY OF t_recProdGrp 
	DEFINE c_ProdGrp CURSOR
	DEFINE retError SMALLINT	
	CALL ProdGrpLookupSearchDataSourceCursor(p_recProdGrpSearch) RETURNING c_ProdGrp
	
	CALL arrProdGrpList.CLEAR()

	CALL c_ProdGrp.SetResults(recProdGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdGrp.FetchNext()=0)
		CALL arrProdGrpList.append([recProdGrp.prodgrp_code, recProdGrp.desc_text])
	END WHILE	

	END IF
	
	IF arrProdGrpList.getSize() = 0 THEN
		ERROR "No prodgrp's found with the specified filter criteria"
	END IF
	
	RETURN arrProdGrpList
END FUNCTION


########################################################################################
# FUNCTION prodgrpLookup_filter(pProdGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdGrp code prodgrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdGrp Code prodgrp_code
#
# Example:
# 			LET pr_ProdGrp.prodgrp_code = ProdGrpLookup(pr_ProdGrp.prodgrp_code)
########################################################################################
FUNCTION prodgrpLookup_filter(pProdGrpCode)
	DEFINE pProdGrpCode LIKE ProdGrp.prodgrp_code
	DEFINE arrProdGrpList DYNAMIC ARRAY OF t_recProdGrp
	DEFINE recProdGrpFilter OF t_recProdGrpFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdGrpLookup WITH FORM "ProdGrpLookup_filter"


	CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdGrpFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdGrpList TO scProdGrpList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdGrpCode = arrProdGrpList[idx].prodgrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdGrpFilter.filter_prodgrp_code IS NOT NULL
			OR recProdGrpFilter.filter_desc_text IS NOT NULL

		THEN
			LET recProdGrpFilter.filter_prodgrp_code = NULL
			LET recProdGrpFilter.filter_desc_text = NULL

			CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_prodgrp_code"
		IF recProdGrpFilter.filter_prodgrp_code IS NOT NULL THEN
			LET recProdGrpFilter.filter_prodgrp_code = NULL
			CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recProdGrpFilter.filter_desc_text IS NOT NULL THEN
			LET recProdGrpFilter.filter_desc_text = NULL
			CALL ProdGrpLookupFilterDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdGrpCode	
END FUNCTION				
		

########################################################################################
# FUNCTION prodgrpLookup(pProdGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdGrp code prodgrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdGrpLookupSearchDataSource(recProdGrpFilter.*) RETURNING arrProdGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdGrp Code prodgrp_code
#
# Example:
# 			LET pr_ProdGrp.prodgrp_code = ProdGrpLookup(pr_ProdGrp.prodgrp_code)
########################################################################################
FUNCTION prodgrpLookup(pProdGrpCode)
	DEFINE pProdGrpCode LIKE ProdGrp.prodgrp_code
	DEFINE arrProdGrpList DYNAMIC ARRAY OF t_recProdGrp
	DEFINE recProdGrpSearch OF t_recProdGrpSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdGrpLookup WITH FORM "prodgrpLookup"

	CALL ProdGrpLookupSearchDataSource(recProdGrpSearch.*) RETURNING arrProdGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdGrpSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ProdGrpLookupSearchDataSource(recProdGrpSearch.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdGrpList TO scProdGrpList.* 
		BEFORE ROW
			IF arrProdGrpList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdGrpCode = arrProdGrpList[idx].prodgrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdGrpSearch.filter_any_field IS NOT NULL

		THEN
			LET recProdGrpSearch.filter_any_field = NULL

			CALL ProdGrpLookupSearchDataSource(recProdGrpSearch.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_prodgrp_code"
		IF recProdGrpSearch.filter_any_field IS NOT NULL THEN
			LET recProdGrpSearch.filter_any_field = NULL
			CALL ProdGrpLookupSearchDataSource(recProdGrpSearch.*) RETURNING arrProdGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdGrpCode	
END FUNCTION				

############################################
# FUNCTION import_prodgrp()
############################################
FUNCTION import_prodgrp()
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
	
	DEFINE rec_prodgrp OF t_recProdGrp_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wProdGrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Group List Data (table: prodgrp)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_prodgrp
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_prodgrp(
    prodgrp_code CHAR(3),
    desc_text CHAR(30),
    maingrp_code CHAR(3),
    min_month_amt DECIMAL(16,2),
    min_quart_amt DECIMAL(16,2),
    min_year_amt DECIMAL(16,2),
    subdept_code CHAR(3)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_prodgrp	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wProdGrpImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wProdGrpImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/prodgrp-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_prodgrp
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_prodgrp
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_prodgrp
			LET importReport = importReport, "Code:", trim(rec_prodgrp.prodgrp_code) , "     -     Desc:", trim(rec_prodgrp.desc_text), "\n"
					
			INSERT INTO prodgrp VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_prodgrp.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_prodgrp.prodgrp_code) , "     -     Desc:", trim(rec_prodgrp.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wProdGrpImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_prodgrpRec(p_cmpy_code, p_prodgrp_code)
########################################################
FUNCTION exist_prodgrpRec(p_cmpy_code, p_prodgrp_code)
	DEFINE p_cmpy_code LIKE prodgrp.cmpy_code
	DEFINE p_prodgrp_code LIKE prodgrp.prodgrp_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM prodgrp 
     WHERE cmpy_code = p_cmpy_code
     AND prodgrp_code = p_prodgrp_code

	DROP TABLE temp_prodgrp
	CLOSE WINDOW wProdGrpImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_prodgrp()
###############################################################
FUNCTION unload_prodgrp(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/prodgrp-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM prodgrp ORDER BY cmpy_code, prodgrp_code ASC
	
	LET tmpMsg = "All prodgrp data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("prodgrp Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_prodgrp_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_prodgrp_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE prodgrp.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wprodgrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Group (prodgrp) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing prodgrp table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM prodgrp
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table prodgrp!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table prodgrp where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wProdGrpImport		
END FUNCTION	