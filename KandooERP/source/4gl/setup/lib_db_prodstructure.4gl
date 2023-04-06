GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getProdStructureCount()
# FUNCTION prodstructureLookupFilterDataSourceCursor(pRecProdStructureFilter)
# FUNCTION prodstructureLookupSearchDataSourceCursor(p_RecProdStructureSearch)
# FUNCTION ProdStructureLookupFilterDataSource(pRecProdStructureFilter)
# FUNCTION prodstructureLookup_filter(pProdStructureCode)
# FUNCTION import_prodstructure()
# FUNCTION exist_prodstructureRec(p_cmpy_code, p_class_code)
# FUNCTION delete_prodstructure_all()
# FUNCTION prodstructureMenu()						-- Offer different OPTIONS of this library via a menu

# ProdStructure record types
	DEFINE t_recProdStructure  
		TYPE AS RECORD
			class_code LIKE prodstructure.class_code,
			desc_text LIKE prodstructure.desc_text
		END RECORD 

	DEFINE t_recProdStructureFilter  
		TYPE AS RECORD
			filter_class_code LIKE prodstructure.class_code,
			filter_desc_text LIKE prodstructure.desc_text
		END RECORD 

	DEFINE t_recProdStructureSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recProdStructure_noCmpyId 
		TYPE AS RECORD 
    class_code LIKE prodstructure.class_code,
    seq_num LIKE prodstructure.seq_num,
    start_num LIKE prodstructure.start_num,
    length LIKE prodstructure.length,
    desc_text LIKE prodstructure.desc_text,
    type_ind LIKE prodstructure.type_ind,
    valid_flag LIKE prodstructure.valid_flag
	END RECORD	

	
########################################################################################
# FUNCTION prodstructureMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION prodStructureMenu()
	MENU
		ON ACTION "Import"
			CALL import_prodstructure()
		ON ACTION "Export"
			CALL unload_prodstructure()
		#ON ACTION "Import"
		#	CALL import_prodstructure()
		ON ACTION "Delete All"
			CALL delete_prodstructure_all()
		ON ACTION "Count"
			CALL getProdStructureCount() --Count all prodstructure rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getProdStructureCount()
#-------------------------------------------------------
# Returns the number of ProdStructure entries for the current company
########################################################################################
FUNCTION getProdStructureCount()
	DEFINE ret_ProdStructureCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ProdStructure CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM ProdStructure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_ProdStructure.DECLARE(sqlQuery) #CURSOR FOR getProdStructure
	CALL c_ProdStructure.SetResults(ret_ProdStructureCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_ProdStructure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ProdStructureCount = -1
	ELSE
		CALL c_ProdStructure.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product Groups:", trim(ret_ProdStructureCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_ProdStructureCount
END FUNCTION

########################################################################################
# FUNCTION prodstructureLookupFilterDataSourceCursor(pRecProdStructureFilter)
#-------------------------------------------------------
# Returns the ProdStructure CURSOR for the lookup query
########################################################################################
FUNCTION prodstructureLookupFilterDataSourceCursor(pRecProdStructureFilter)
	DEFINE pRecProdStructureFilter OF t_recProdStructureFilter
	DEFINE sqlQuery STRING
	DEFINE c_ProdStructure CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodstructure.class_code, ", 
									"prodstructure.desc_text ",
									"FROM prodstructure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecProdStructureFilter.filter_class_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND class_code LIKE '", pRecProdStructureFilter.filter_class_code CLIPPED, "%' "  
	END IF									

	IF pRecProdStructureFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecProdStructureFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY class_code"

	CALL c_prodstructure.DECLARE(sqlQuery)
		
	RETURN c_prodstructure
END FUNCTION



########################################################################################
# prodstructureLookupSearchDataSourceCursor(p_RecProdStructureSearch)
#-------------------------------------------------------
# Returns the ProdStructure CURSOR for the lookup query
########################################################################################
FUNCTION prodstructureLookupSearchDataSourceCursor(p_RecProdStructureSearch)
	DEFINE p_RecProdStructureSearch OF t_recProdStructureSearch  
	DEFINE sqlQuery STRING
	DEFINE c_ProdStructure CURSOR
	
	LET sqlQuery =	"SELECT ",
									"prodstructure.class_code, ", 
									"prodstructure.desc_text ",
 
									"FROM prodstructure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecProdStructureSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((class_code LIKE '", p_RecProdStructureSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecProdStructureSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecProdStructureSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY class_code"

	CALL c_prodstructure.DECLARE(sqlQuery) #CURSOR FOR prodstructure
	
	RETURN c_prodstructure
END FUNCTION


########################################################################################
# FUNCTION ProdStructureLookupFilterDataSource(pRecProdStructureFilter)
#-------------------------------------------------------
# CALLS ProdStructureLookupFilterDataSourceCursor(pRecProdStructureFilter) with the ProdStructureFilter data TO get a CURSOR
# Returns the ProdStructure list array arrProdStructureList
########################################################################################
FUNCTION ProdStructureLookupFilterDataSource(pRecProdStructureFilter)
	DEFINE pRecProdStructureFilter OF t_recProdStructureFilter
	DEFINE recProdStructure OF t_recProdStructure
	DEFINE arrProdStructureList DYNAMIC ARRAY OF t_recProdStructure 
	DEFINE c_ProdStructure CURSOR
	DEFINE retError SMALLINT
		
	CALL ProdStructureLookupFilterDataSourceCursor(pRecProdStructureFilter.*) RETURNING c_ProdStructure
	
	CALL arrProdStructureList.CLEAR()

	CALL c_ProdStructure.SetResults(recProdStructure.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdStructure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdStructure.FetchNext()=0)
		CALL arrProdStructureList.append([recProdStructure.class_code, recProdStructure.desc_text])
	END WHILE	

	END IF
	
	IF arrProdStructureList.getSize() = 0 THEN
		ERROR "No prodstructure's found with the specified filter criteria"
	END IF
	
	RETURN arrProdStructureList
END FUNCTION	

########################################################################################
# FUNCTION ProdStructureLookupSearchDataSource(pRecProdStructureFilter)
#-------------------------------------------------------
# CALLS ProdStructureLookupSearchDataSourceCursor(pRecProdStructureFilter) with the ProdStructureFilter data TO get a CURSOR
# Returns the ProdStructure list array arrProdStructureList
########################################################################################
FUNCTION ProdStructureLookupSearchDataSource(p_recProdStructureSearch)
	DEFINE p_recProdStructureSearch OF t_recProdStructureSearch	
	DEFINE recProdStructure OF t_recProdStructure
	DEFINE arrProdStructureList DYNAMIC ARRAY OF t_recProdStructure 
	DEFINE c_ProdStructure CURSOR
	DEFINE retError SMALLINT	
	CALL ProdStructureLookupSearchDataSourceCursor(p_recProdStructureSearch) RETURNING c_ProdStructure
	
	CALL arrProdStructureList.CLEAR()

	CALL c_ProdStructure.SetResults(recProdStructure.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ProdStructure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ProdStructure.FetchNext()=0)
		CALL arrProdStructureList.append([recProdStructure.class_code, recProdStructure.desc_text])
	END WHILE	

	END IF
	
	IF arrProdStructureList.getSize() = 0 THEN
		ERROR "No prodstructure's found with the specified filter criteria"
	END IF
	
	RETURN arrProdStructureList
END FUNCTION


########################################################################################
# FUNCTION prodstructureLookup_filter(pProdStructureCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdStructure code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdStructure Code class_code
#
# Example:
# 			LET pr_ProdStructure.class_code = ProdStructureLookup(pr_ProdStructure.class_code)
########################################################################################
FUNCTION prodstructureLookup_filter(pProdStructureCode)
	DEFINE pProdStructureCode LIKE ProdStructure.class_code
	DEFINE arrProdStructureList DYNAMIC ARRAY OF t_recProdStructure
	DEFINE recProdStructureFilter OF t_recProdStructureFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdStructureLookup WITH FORM "ProdStructureLookup_filter"


	CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdStructureFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdStructureList TO scProdStructureList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdStructureCode = arrProdStructureList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdStructureFilter.filter_class_code IS NOT NULL
			OR recProdStructureFilter.filter_desc_text IS NOT NULL

		THEN
			LET recProdStructureFilter.filter_class_code = NULL
			LET recProdStructureFilter.filter_desc_text = NULL

			CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recProdStructureFilter.filter_class_code IS NOT NULL THEN
			LET recProdStructureFilter.filter_class_code = NULL
			CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recProdStructureFilter.filter_desc_text IS NOT NULL THEN
			LET recProdStructureFilter.filter_desc_text = NULL
			CALL ProdStructureLookupFilterDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdStructureLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdStructureCode	
END FUNCTION				
		

########################################################################################
# FUNCTION prodstructureLookup(pProdStructureCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdStructure code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdStructureLookupSearchDataSource(recProdStructureFilter.*) RETURNING arrProdStructureList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdStructure Code class_code
#
# Example:
# 			LET pr_ProdStructure.class_code = ProdStructureLookup(pr_ProdStructure.class_code)
########################################################################################
FUNCTION prodstructureLookup(pProdStructureCode)
	DEFINE pProdStructureCode LIKE ProdStructure.class_code
	DEFINE arrProdStructureList DYNAMIC ARRAY OF t_recProdStructure
	DEFINE recProdStructureSearch OF t_recProdStructureSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdStructureLookup WITH FORM "prodstructureLookup"

	CALL ProdStructureLookupSearchDataSource(recProdStructureSearch.*) RETURNING arrProdStructureList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdStructureSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ProdStructureLookupSearchDataSource(recProdStructureSearch.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdStructureList TO scProdStructureList.* 
		BEFORE ROW
			IF arrProdStructureList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdStructureCode = arrProdStructureList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdStructureSearch.filter_any_field IS NOT NULL

		THEN
			LET recProdStructureSearch.filter_any_field = NULL

			CALL ProdStructureLookupSearchDataSource(recProdStructureSearch.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recProdStructureSearch.filter_any_field IS NOT NULL THEN
			LET recProdStructureSearch.filter_any_field = NULL
			CALL ProdStructureLookupSearchDataSource(recProdStructureSearch.*) RETURNING arrProdStructureList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdStructureLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdStructureCode	
END FUNCTION				

############################################
# FUNCTION import_prodstructure()
############################################
FUNCTION import_prodstructure()
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
	
	DEFINE rec_prodstructure OF t_recProdStructure_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wProdStructureImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Group List Data (table: prodstructure)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_prodstructure
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_prodstructure(
    class_code CHAR(8),
    seq_num SMALLINT,
    start_num SMALLINT,
    length SMALLINT,
    desc_text CHAR(30),
    type_ind CHAR(1),
    valid_flag CHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_prodstructure	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wProdStructureImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wProdStructureImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/prodstructure-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_prodstructure
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_prodstructure
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_prodstructure
			LET importReport = importReport, "Code:", trim(rec_prodstructure.class_code) , "     -     Desc:", trim(rec_prodstructure.desc_text), "\n"
					
			INSERT INTO prodstructure VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_prodstructure.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_prodstructure.class_code) , "     -     Desc:", trim(rec_prodstructure.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wProdStructureImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_prodstructureRec(p_cmpy_code, p_class_code)
########################################################
FUNCTION exist_prodstructureRec(p_cmpy_code, p_class_code)
	DEFINE p_cmpy_code LIKE prodstructure.cmpy_code
	DEFINE p_class_code LIKE prodstructure.class_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM prodstructure 
     WHERE cmpy_code = p_cmpy_code
     AND class_code = p_class_code

	DROP TABLE temp_prodstructure
	CLOSE WINDOW wProdStructureImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_prodstructure()
###############################################################
FUNCTION unload_prodstructure(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/prodstructure-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM prodstructure ORDER BY cmpy_code, class_code ASC
	
	LET tmpMsg = "All prodstructure data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("prodstructure Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_prodstructure_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_prodstructure_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE prodstructure.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wprodstructureImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Group (prodstructure) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing prodstructure table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM prodstructure
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table prodstructure!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table prodstructure where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wProdStructureImport		
END FUNCTION	