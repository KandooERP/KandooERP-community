GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getProdDept_Count()
# FUNCTION proddept_LookupFilterDataSourceCursor(pRecProdDept_Filter)
# FUNCTION proddept_LookupSearchDataSourceCursor(p_RecProdDept_Search)
# FUNCTION ProdDept_LookupFilterDataSource(pRecProdDept_Filter)
# FUNCTION proddept_Lookup_filter(pProdDept_Code)
# FUNCTION import_proddept()
# FUNCTION exist_proddept_Rec(p_cmpy_code, p_dept_code)
# FUNCTION delete_proddept_all()
# FUNCTION prodDeptMenu()						-- Offer different OPTIONS of this library via a menu

# ProdDept  record types
	DEFINE t_recProdDept   
		TYPE AS RECORD
			dept_code LIKE proddept.dept_code,
			desc_text LIKE proddept.desc_text
		END RECORD 

	DEFINE t_recProdDept_Filter  
		TYPE AS RECORD
			filter_dept_code LIKE proddept.dept_code,
			filter_desc_text LIKE proddept.desc_text
		END RECORD 

	DEFINE t_recProdDept_Search  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recProdDept_noCmpyId 
		TYPE AS RECORD 
    dept_ind LIKE proddept.dept_ind,
    dept_code LIKE proddept.dept_code,
    desc_text LIKE proddept.desc_text
	END RECORD	

	
########################################################################################
# FUNCTION prodDeptMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION prodDeptMenu()
	MENU
		ON ACTION "Import"
			CALL import_proddept()
		ON ACTION "Export"
			CALL unload_proddept()
		#ON ACTION "Import"
		#	CALL import_proddept()
		ON ACTION "Delete All"
			CALL delete_proddept_all()
		ON ACTION "Count"
			CALL getProdDept_Count() --Count all proddept  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getProdDept_Count()
#-------------------------------------------------------
# Returns the number of ProdDept  entries for the current company
########################################################################################
FUNCTION getProdDept_Count()
	DEFINE ret_ProdDept_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ProdDept  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM ProdDept ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_proddept.DECLARE(sqlQuery) #CURSOR FOR getProdDept 
	CALL c_proddept.SetResults(ret_ProdDept_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_proddept.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ProdDept_Count = -1
	ELSE
		CALL c_proddept.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vendor Group:", trim(ret_ProdDept_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_ProdDept_Count
END FUNCTION

########################################################################################
# FUNCTION proddept_LookupFilterDataSourceCursor(pRecProdDept_Filter)
#-------------------------------------------------------
# Returns the ProdDept  CURSOR for the lookup query
########################################################################################
FUNCTION proddept_LookupFilterDataSourceCursor(pRecProdDept_Filter)
	DEFINE pRecProdDept_Filter OF t_recProdDept_Filter
	DEFINE sqlQuery STRING
	DEFINE c_ProdDept  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"proddept.dept_code, ", 
									"proddept.desc_text ",
									"FROM proddept  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecProdDept_Filter.filter_dept_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND dept_code LIKE '", pRecProdDept_Filter.filter_dept_code CLIPPED, "%' "  
	END IF									

	IF pRecProdDept_Filter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecProdDept_Filter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY dept_code"

	CALL c_proddept.DECLARE(sqlQuery)
		
	RETURN c_proddept 
END FUNCTION



########################################################################################
# proddept_LookupSearchDataSourceCursor(p_RecProdDept_Search)
#-------------------------------------------------------
# Returns the ProdDept  CURSOR for the lookup query
########################################################################################
FUNCTION proddept_LookupSearchDataSourceCursor(p_RecProdDept_Search)
	DEFINE p_RecProdDept_Search OF t_recProdDept_Search  
	DEFINE sqlQuery STRING
	DEFINE c_ProdDept  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"proddept.dept_code, ", 
									"proddept.desc_text ",
 
									"FROM proddept  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecProdDept_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((dept_code LIKE '", p_RecProdDept_Search.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecProdDept_Search.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecProdDept_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY dept_code"

	CALL c_proddept.DECLARE(sqlQuery) #CURSOR FOR proddept 
	
	RETURN c_proddept 
END FUNCTION


########################################################################################
# FUNCTION ProdDept_LookupFilterDataSource(pRecProdDept_Filter)
#-------------------------------------------------------
# CALLS ProdDept_LookupFilterDataSourceCursor(pRecProdDept_Filter) with the ProdDept_Filter data TO get a CURSOR
# Returns the ProdDept  list array arrProdDept_List
########################################################################################
FUNCTION ProdDept_LookupFilterDataSource(pRecProdDept_Filter)
	DEFINE pRecProdDept_Filter OF t_recProdDept_Filter
	DEFINE recProdDept  OF t_recProdDept 
	DEFINE arrProdDept_List DYNAMIC ARRAY OF t_recProdDept  
	DEFINE c_ProdDept  CURSOR
	DEFINE retError SMALLINT
		
	CALL ProdDept_LookupFilterDataSourceCursor(pRecProdDept_Filter.*) RETURNING c_ProdDept 
	
	CALL arrProdDept_List.CLEAR()

	CALL c_proddept.SetResults(recproddept.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_proddept.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_proddept.FetchNext()=0)
		CALL arrProdDept_List.append([recproddept.dept_code, recproddept.desc_text])
	END WHILE	

	END IF
	
	IF arrProdDept_List.getSize() = 0 THEN
		ERROR "No proddept 's found with the specified filter criteria"
	END IF
	
	RETURN arrProdDept_List
END FUNCTION	

########################################################################################
# FUNCTION ProdDept_LookupSearchDataSource(pRecProdDept_Filter)
#-------------------------------------------------------
# CALLS ProdDept_LookupSearchDataSourceCursor(pRecProdDept_Filter) with the ProdDept_Filter data TO get a CURSOR
# Returns the ProdDept  list array arrProdDept_List
########################################################################################
FUNCTION ProdDept_LookupSearchDataSource(p_recProdDept_Search)
	DEFINE p_recProdDept_Search OF t_recProdDept_Search	
	DEFINE recProdDept  OF t_recProdDept 
	DEFINE arrProdDept_List DYNAMIC ARRAY OF t_recProdDept  
	DEFINE c_ProdDept  CURSOR
	DEFINE retError SMALLINT	
	CALL ProdDept_LookupSearchDataSourceCursor(p_recProdDept_Search) RETURNING c_ProdDept 
	
	CALL arrProdDept_List.CLEAR()

	CALL c_proddept.SetResults(recproddept.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_proddept.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_proddept.FetchNext()=0)
		CALL arrProdDept_List.append([recproddept.dept_code, recproddept.desc_text])
	END WHILE	

	END IF
	
	IF arrProdDept_List.getSize() = 0 THEN
		ERROR "No proddept 's found with the specified filter criteria"
	END IF
	
	RETURN arrProdDept_List
END FUNCTION


########################################################################################
# FUNCTION proddept_Lookup_filter(pProdDept_Code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdDept  code dept_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdDept  Code dept_code
#
# Example:
# 			LET pr_proddept.dept_code = ProdDept_Lookup(pr_proddept.dept_code)
########################################################################################
FUNCTION proddept_Lookup_filter(pProdDept_Code)
	DEFINE pProdDept_Code LIKE proddept.dept_code
	DEFINE arrProdDept_List DYNAMIC ARRAY OF t_recProdDept 
	DEFINE recProdDept_Filter OF t_recProdDept_Filter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdDept_Lookup WITH FORM "ProdDept_Lookup_filter"


	CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdDept_Filter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdDept_List TO scProdDept_List.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdDept_Code = arrProdDept_List[idx].dept_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdDept_Filter.filter_dept_code IS NOT NULL
			OR recProdDept_Filter.filter_desc_text IS NOT NULL

		THEN
			LET recProdDept_Filter.filter_dept_code = NULL
			LET recProdDept_Filter.filter_desc_text = NULL

			CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_dept_code"
		IF recProdDept_Filter.filter_dept_code IS NOT NULL THEN
			LET recProdDept_Filter.filter_dept_code = NULL
			CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recProdDept_Filter.filter_desc_text IS NOT NULL THEN
			LET recProdDept_Filter.filter_desc_text = NULL
			CALL ProdDept_LookupFilterDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdDept_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdDept_Code	
END FUNCTION				
		

########################################################################################
# FUNCTION proddept_Lookup(pProdDept_Code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ProdDept  code dept_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ProdDept_LookupSearchDataSource(recProdDept_Filter.*) RETURNING arrProdDept_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ProdDept  Code dept_code
#
# Example:
# 			LET pr_proddept.dept_code = ProdDept_Lookup(pr_proddept.dept_code)
########################################################################################
FUNCTION proddept_Lookup(pProdDept_Code)
	DEFINE pProdDept_Code LIKE proddept.dept_code
	DEFINE arrProdDept_List DYNAMIC ARRAY OF t_recProdDept 
	DEFINE recProdDept_Search OF t_recProdDept_Search	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wProdDept_Lookup WITH FORM "proddept_Lookup"

	CALL ProdDept_LookupSearchDataSource(recProdDept_Search.*) RETURNING arrProdDept_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recProdDept_Search.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ProdDept_LookupSearchDataSource(recProdDept_Search.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrProdDept_List TO scProdDept_List.* 
		BEFORE ROW
			IF arrProdDept_List.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pProdDept_Code = arrProdDept_List[idx].dept_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recProdDept_Search.filter_any_field IS NOT NULL

		THEN
			LET recProdDept_Search.filter_any_field = NULL

			CALL ProdDept_LookupSearchDataSource(recProdDept_Search.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_dept_code"
		IF recProdDept_Search.filter_any_field IS NOT NULL THEN
			LET recProdDept_Search.filter_any_field = NULL
			CALL ProdDept_LookupSearchDataSource(recProdDept_Search.*) RETURNING arrProdDept_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wProdDept_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pProdDept_Code	
END FUNCTION				

############################################
# FUNCTION import_proddept()
############################################
FUNCTION import_proddept()
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
	
	DEFINE rec_proddept  OF t_recProdDept_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wProdDept_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Group List Data (table: proddept )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_proddept 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_proddept (
	    dept_ind CHAR(1),
	    dept_code CHAR(3),
	    desc_text CHAR(30)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_proddept 	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wProdDept_Import WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wProdDept_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/proddept-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_proddept 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_proddept 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_proddept 
			LET importReport = importReport, "Code:", trim(rec_proddept.dept_code) , "     -     Desc:", trim(rec_proddept.desc_text), "\n"
					
			INSERT INTO proddept  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_proddept.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_proddept.dept_code) , "     -     Desc:", trim(rec_proddept.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wProdDept_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_proddept_Rec(p_cmpy_code, p_dept_code)
########################################################
FUNCTION exist_proddept_Rec(p_cmpy_code, p_dept_code)
	DEFINE p_cmpy_code LIKE proddept.cmpy_code
	DEFINE p_dept_code LIKE proddept.dept_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM proddept  
     WHERE cmpy_code = p_cmpy_code
     AND dept_code = p_dept_code

	DROP TABLE temp_proddept 
	CLOSE WINDOW wProdDept_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_proddept()
###############################################################
FUNCTION unload_proddept (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/proddept-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM proddept ORDER BY cmpy_code, dept_code ASC
	
	LET tmpMsg = "All proddept data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("proddept Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_proddept_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_proddept_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE proddept.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wProdDept_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Vendor Group (proddept) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing proddept table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM proddept
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table proddept!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table proddept where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wProdDept_Import		
END FUNCTION	