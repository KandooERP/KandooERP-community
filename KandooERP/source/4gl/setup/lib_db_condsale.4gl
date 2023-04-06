GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCondsaleCount()
# FUNCTION condsaleLookupFilterDataSourceCursor(pRecCondsaleFilter)
# FUNCTION condsaleLookupSearchDataSourceCursor(p_RecCondsaleSearch)
# FUNCTION CondsaleLookupFilterDataSource(pRecCondsaleFilter)
# FUNCTION condsaleLookup_filter(pCondsaleCode)
# FUNCTION import_condsale()
# FUNCTION exist_condsaleRec(p_cmpy_code, p_cond_code)
# FUNCTION delete_condsale_all()
# FUNCTION condsaleMenu()						-- Offer different OPTIONS of this library via a menu

# Condsale record types
	DEFINE t_recCondSale  
		TYPE AS RECORD
			cond_code LIKE condsale.cond_code,
			desc_text LIKE condsale.desc_text
		END RECORD 

	DEFINE t_recCondSaleFilter  
		TYPE AS RECORD
			filter_cond_code LIKE condsale.cond_code,
			filter_desc_text LIKE condsale.desc_text
		END RECORD 

	DEFINE t_recCondSaleSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCondSale_noCmpyId 
		TYPE AS RECORD 
    cond_code LIKE condsale.cond_code,
    desc_text LIKE condsale.desc_text,
		prodline_disc_flag LIKE condsale.prodline_disc_flag,
		scheme_amt LIKE condsale.scheme_amt,
		tier_disc_flag LIKE condsale.tier_disc_flag

	END RECORD	

	
########################################################################################
# FUNCTION condSaleMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION condSaleMenu()
	MENU
		ON ACTION "Import"
			CALL import_condsale()
		ON ACTION "Export"
			CALL unload_condsale()
		#ON ACTION "Import"
		#	CALL import_condsale()
		ON ACTION "Delete All"
			CALL delete_condsale_all()
		ON ACTION "Count"
			CALL getCondsaleCount() --Count all condsale rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCondsaleCount()
#-------------------------------------------------------
# Returns the number of Condsale entries for the current company
########################################################################################
FUNCTION getCondsaleCount()
	DEFINE ret_CondsaleCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Condsale CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM condsale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Condsale.DECLARE(sqlQuery) #CURSOR FOR getCondsale
	CALL c_Condsale.SetResults(ret_CondsaleCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Condsale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CondsaleCount = -1
	ELSE
		CALL c_Condsale.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of CondSales:", trim(ret_CondsaleCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("CondSale Count", tempMsg,"info") 	
	END IF

	RETURN ret_CondsaleCount
END FUNCTION

########################################################################################
# FUNCTION condsaleLookupFilterDataSourceCursor(pRecCondsaleFilter)
#-------------------------------------------------------
# Returns the Condsale CURSOR for the lookup query
########################################################################################
FUNCTION condsaleLookupFilterDataSourceCursor(pRecCondsaleFilter)
	DEFINE pRecCondsaleFilter OF t_recCondSaleFilter
	DEFINE sqlQuery STRING
	DEFINE c_Condsale CURSOR
	
	LET sqlQuery =	"SELECT ",
									"condsale.cond_code, ", 
									"condsale.desc_text ",
									"FROM condsale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCondsaleFilter.filter_cond_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cond_code LIKE '", pRecCondsaleFilter.filter_cond_code CLIPPED, "%' "  
	END IF									

	IF pRecCondsaleFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCondsaleFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cond_code"

	CALL c_condsale.DECLARE(sqlQuery)
		
	RETURN c_condsale
END FUNCTION



########################################################################################
# condsaleLookupSearchDataSourceCursor(p_RecCondsaleSearch)
#-------------------------------------------------------
# Returns the Condsale CURSOR for the lookup query
########################################################################################
FUNCTION condsaleLookupSearchDataSourceCursor(p_RecCondsaleSearch)
	DEFINE p_RecCondsaleSearch OF t_recCondSaleSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Condsale CURSOR
	
	LET sqlQuery =	"SELECT ",
									"condsale.cond_code, ", 
									"condsale.desc_text ",
 
									"FROM condsale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCondsaleSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cond_code LIKE '", p_RecCondsaleSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCondsaleSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecCondsaleSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cond_code"

	CALL c_condsale.DECLARE(sqlQuery) #CURSOR FOR condsale
	
	RETURN c_condsale
END FUNCTION


########################################################################################
# FUNCTION CondsaleLookupFilterDataSource(pRecCondsaleFilter)
#-------------------------------------------------------
# CALLS CondsaleLookupFilterDataSourceCursor(pRecCondsaleFilter) with the CondsaleFilter data TO get a CURSOR
# Returns the Condsale list array arrCondsaleList
########################################################################################
FUNCTION CondsaleLookupFilterDataSource(pRecCondsaleFilter)
	DEFINE pRecCondsaleFilter OF t_recCondSaleFilter
	DEFINE recCondSale OF t_recCondSale
	DEFINE arrCondsaleList DYNAMIC ARRAY OF t_recCondSale 
	DEFINE c_Condsale CURSOR
	DEFINE retError SMALLINT
		
	CALL CondsaleLookupFilterDataSourceCursor(pRecCondsaleFilter.*) RETURNING c_Condsale
	
	CALL arrCondsaleList.CLEAR()

	CALL c_Condsale.SetResults(recCondSale.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Condsale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Condsale.FetchNext()=0)
		CALL arrCondsaleList.append([recCondSale.cond_code, recCondSale.desc_text])
	END WHILE	

	END IF
	
	IF arrCondsaleList.getSize() = 0 THEN
		ERROR "No condsale's found with the specified filter criteria"
	END IF
	
	RETURN arrCondsaleList
END FUNCTION	

########################################################################################
# FUNCTION CondsaleLookupSearchDataSource(pRecCondsaleFilter)
#-------------------------------------------------------
# CALLS CondsaleLookupSearchDataSourceCursor(pRecCondsaleFilter) with the CondsaleFilter data TO get a CURSOR
# Returns the Condsale list array arrCondsaleList
########################################################################################
FUNCTION CondsaleLookupSearchDataSource(p_recCondSaleSearch)
	DEFINE p_recCondSaleSearch OF t_recCondSaleSearch	
	DEFINE recCondSale OF t_recCondSale
	DEFINE arrCondsaleList DYNAMIC ARRAY OF t_recCondSale 
	DEFINE c_Condsale CURSOR
	DEFINE retError SMALLINT	
	CALL CondsaleLookupSearchDataSourceCursor(p_recCondSaleSearch) RETURNING c_Condsale
	
	CALL arrCondsaleList.CLEAR()

	CALL c_Condsale.SetResults(recCondSale.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Condsale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Condsale.FetchNext()=0)
		CALL arrCondsaleList.append([recCondSale.cond_code, recCondSale.desc_text])
	END WHILE	

	END IF
	
	IF arrCondsaleList.getSize() = 0 THEN
		ERROR "No condsale's found with the specified filter criteria"
	END IF
	
	RETURN arrCondsaleList
END FUNCTION


########################################################################################
# FUNCTION condsaleLookup_filter(pCondsaleCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Condsale code cond_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Condsale Code cond_code
#
# Example:
# 			LET pr_Condsale.cond_code = CondsaleLookup(pr_Condsale.cond_code)
########################################################################################
FUNCTION condsaleLookup_filter(pCondsaleCode)
	DEFINE pCondsaleCode LIKE Condsale.cond_code
	DEFINE arrCondsaleList DYNAMIC ARRAY OF t_recCondSale
	DEFINE recCondSaleFilter OF t_recCondSaleFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCondsaleLookup WITH FORM "CondsaleLookup_filter"


	CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCondSaleFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCondsaleList TO scCondsaleList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCondsaleCode = arrCondsaleList[idx].cond_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCondSaleFilter.filter_cond_code IS NOT NULL
			OR recCondSaleFilter.filter_desc_text IS NOT NULL

		THEN
			LET recCondSaleFilter.filter_cond_code = NULL
			LET recCondSaleFilter.filter_desc_text = NULL

			CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cond_code"
		IF recCondSaleFilter.filter_cond_code IS NOT NULL THEN
			LET recCondSaleFilter.filter_cond_code = NULL
			CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCondSaleFilter.filter_desc_text IS NOT NULL THEN
			LET recCondSaleFilter.filter_desc_text = NULL
			CALL CondsaleLookupFilterDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCondsaleLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCondsaleCode	
END FUNCTION				
		

########################################################################################
# FUNCTION condsaleLookup(pCondsaleCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Condsale code cond_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CondsaleLookupSearchDataSource(recCondSaleFilter.*) RETURNING arrCondsaleList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Condsale Code cond_code
#
# Example:
# 			LET pr_Condsale.cond_code = CondsaleLookup(pr_Condsale.cond_code)
########################################################################################
FUNCTION condsaleLookup(pCondsaleCode)
	DEFINE pCondsaleCode LIKE Condsale.cond_code
	DEFINE arrCondsaleList DYNAMIC ARRAY OF t_recCondSale
	DEFINE recCondSaleSearch OF t_recCondSaleSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCondsaleLookup WITH FORM "condsaleLookup"

	CALL CondsaleLookupSearchDataSource(recCondSaleSearch.*) RETURNING arrCondsaleList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCondSaleSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CondsaleLookupSearchDataSource(recCondSaleSearch.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCondsaleList TO scCondsaleList.* 
		BEFORE ROW
			IF arrCondsaleList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCondsaleCode = arrCondsaleList[idx].cond_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCondSaleSearch.filter_any_field IS NOT NULL

		THEN
			LET recCondSaleSearch.filter_any_field = NULL

			CALL CondsaleLookupSearchDataSource(recCondSaleSearch.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cond_code"
		IF recCondSaleSearch.filter_any_field IS NOT NULL THEN
			LET recCondSaleSearch.filter_any_field = NULL
			CALL CondsaleLookupSearchDataSource(recCondSaleSearch.*) RETURNING arrCondsaleList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCondsaleLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCondsaleCode	
END FUNCTION				

############################################
# FUNCTION import_condsale()
############################################
FUNCTION import_condsale()
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
	
	DEFINE recCondSale OF t_recCondSale_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCondsaleImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Condsale List Data (table: condsale)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_condsale
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_condsale(
	    #cmpy_code CHAR(2),
	    cond_code CHAR(3),
	    desc_text CHAR(30),
	    prodline_disc_flag CHAR(1),
	    scheme_amt DECIMAL(16,2),
	    tier_disc_flag CHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_condsale	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCondsaleImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCondsaleImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/condsale-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_condsale
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_condsale
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO recCondSale
			LET importReport = importReport, "Code:", trim(recCondSale.cond_code) , "     -     Desc:", trim(recCondSale.desc_text), "\n"
					
			INSERT INTO condsale VALUES(
			gl_setupRec_default_company.cmpy_code,
			recCondSale.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(recCondSale.cond_code) , "     -     Desc:", trim(recCondSale.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCondsaleImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_condsaleRec(p_cmpy_code, p_cond_code)
########################################################
FUNCTION exist_condsaleRec(p_cmpy_code, p_cond_code)
	DEFINE p_cmpy_code LIKE condsale.cmpy_code
	DEFINE p_cond_code LIKE condsale.cond_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM condsale 
     WHERE cmpy_code = p_cmpy_code
     AND cond_code = p_cond_code

	DROP TABLE temp_condsale
	CLOSE WINDOW wCondsaleImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_condsale()
###############################################################
FUNCTION unload_condsale(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/condsale-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM condsale ORDER BY cmpy_code, cond_code ASC
	
	LET tmpMsg = "All condsale data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("condsale Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_condsale_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_condsale_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE condsale.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcondsaleImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Condsale List (condsale) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing condsale table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM condsale
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table condsale!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table condsale where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCondsaleImport		
END FUNCTION	