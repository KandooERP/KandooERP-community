GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getMainGrp_Count()
# FUNCTION maingrp_LookupFilterDataSourceCursor(pRecMainGrp_Filter)
# FUNCTION maingrp_LookupSearchDataSourceCursor(p_RecMainGrp_Search)
# FUNCTION MainGrp_LookupFilterDataSource(pRecMainGrp_Filter)
# FUNCTION maingrp_Lookup_filter(p_maingrp_code)
# FUNCTION import_maingrp()
# FUNCTION exist_maingrp_Rec(p_cmpy_code, p_maingrp_code)
# FUNCTION delete_maingrp_all()
# FUNCTION mainGrpMenu()						-- Offer different OPTIONS of this library via a menu

# MainGrp  record types
	DEFINE t_recMainGrp   
		TYPE AS RECORD
			maingrp_code LIKE maingrp.maingrp_code,
			desc_text LIKE maingrp.desc_text
		END RECORD 

	DEFINE t_recMainGrp_Filter  
		TYPE AS RECORD
			filter_maingrp_code LIKE maingrp.maingrp_code,
			filter_desc_text LIKE maingrp.desc_text
		END RECORD 

	DEFINE t_recMainGrp_Search  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recMainGrp_noCmpyId 
		TYPE AS RECORD 
    maingrp_code LIKE maingrp.maingrp_code,
    desc_text LIKE maingrp.desc_text,
    min_month_amt LIKE maingrp.min_month_amt,
    min_quart_amt LIKE maingrp.min_quart_amt,
    min_year_amt LIKE maingrp.min_year_amt,
    dept_code LIKE maingrp.dept_code    
	END RECORD	

	
########################################################################################
# FUNCTION mainGrpMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION mainGrpMenu()
	MENU
		ON ACTION "Import"
			CALL import_maingrp()
		ON ACTION "Export"
			CALL unload_maingrp()
		#ON ACTION "Import"
		#	CALL import_maingrp()
		ON ACTION "Delete All"
			CALL delete_maingrp_all()
		ON ACTION "Count"
			CALL getMainGrp_Count() --Count all maingrp  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getMainGrp_Count()
#-------------------------------------------------------
# Returns the number of MainGrp  entries for the current company
########################################################################################
FUNCTION getMainGrp_Count()
	DEFINE ret_MainGrp_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_MainGrp  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM MainGrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_maingrp.DECLARE(sqlQuery) #CURSOR FOR getMainGrp 
	CALL c_maingrp.SetResults(ret_MainGrp_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_maingrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_MainGrp_Count = -1
	ELSE
		CALL c_maingrp.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product Main Group:", trim(ret_MainGrp_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Main Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_MainGrp_Count
END FUNCTION

########################################################################################
# FUNCTION maingrp_LookupFilterDataSourceCursor(pRecMainGrp_Filter)
#-------------------------------------------------------
# Returns the MainGrp  CURSOR for the lookup query
########################################################################################
FUNCTION maingrp_LookupFilterDataSourceCursor(pRecMainGrp_Filter)
	DEFINE pRecMainGrp_Filter OF t_recMainGrp_Filter
	DEFINE sqlQuery STRING
	DEFINE c_MainGrp  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"maingrp.maingrp_code, ", 
									"maingrp.desc_text ",
									"FROM maingrp  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecMainGrp_Filter.filter_maingrp_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND maingrp_code LIKE '", pRecMainGrp_Filter.filter_maingrp_code CLIPPED, "%' "  
	END IF									

	IF pRecMainGrp_Filter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecMainGrp_Filter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY maingrp_code"

	CALL c_maingrp.DECLARE(sqlQuery)
		
	RETURN c_maingrp 
END FUNCTION



########################################################################################
# maingrp_LookupSearchDataSourceCursor(p_RecMainGrp_Search)
#-------------------------------------------------------
# Returns the MainGrp  CURSOR for the lookup query
########################################################################################
FUNCTION maingrp_LookupSearchDataSourceCursor(p_RecMainGrp_Search)
	DEFINE p_RecMainGrp_Search OF t_recMainGrp_Search  
	DEFINE sqlQuery STRING
	DEFINE c_MainGrp  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"maingrp.maingrp_code, ", 
									"maingrp.desc_text ",
 
									"FROM maingrp  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecMainGrp_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((maingrp_code LIKE '", p_RecMainGrp_Search.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecMainGrp_Search.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecMainGrp_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY maingrp_code"

	CALL c_maingrp.DECLARE(sqlQuery) #CURSOR FOR maingrp 
	
	RETURN c_maingrp 
END FUNCTION


########################################################################################
# FUNCTION MainGrp_LookupFilterDataSource(pRecMainGrp_Filter)
#-------------------------------------------------------
# CALLS MainGrp_LookupFilterDataSourceCursor(pRecMainGrp_Filter) with the MainGrp_Filter data TO get a CURSOR
# Returns the MainGrp  list array arrMainGrp_List
########################################################################################
FUNCTION MainGrp_LookupFilterDataSource(pRecMainGrp_Filter)
	DEFINE pRecMainGrp_Filter OF t_recMainGrp_Filter
	DEFINE recMainGrp  OF t_recMainGrp 
	DEFINE arrMainGrp_List DYNAMIC ARRAY OF t_recMainGrp  
	DEFINE c_MainGrp  CURSOR
	DEFINE retError SMALLINT
		
	CALL MainGrp_LookupFilterDataSourceCursor(pRecMainGrp_Filter.*) RETURNING c_MainGrp 
	
	CALL arrMainGrp_List.CLEAR()

	CALL c_maingrp.SetResults(recmaingrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_maingrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_maingrp.FetchNext()=0)
		CALL arrMainGrp_List.append([recmaingrp.maingrp_code, recmaingrp.desc_text])
	END WHILE	

	END IF
	
	IF arrMainGrp_List.getSize() = 0 THEN
		ERROR "No maingrp 's found with the specified filter criteria"
	END IF
	
	RETURN arrMainGrp_List
END FUNCTION	

########################################################################################
# FUNCTION MainGrp_LookupSearchDataSource(pRecMainGrp_Filter)
#-------------------------------------------------------
# CALLS MainGrp_LookupSearchDataSourceCursor(pRecMainGrp_Filter) with the MainGrp_Filter data TO get a CURSOR
# Returns the MainGrp  list array arrMainGrp_List
########################################################################################
FUNCTION MainGrp_LookupSearchDataSource(p_recMainGrp_Search)
	DEFINE p_recMainGrp_Search OF t_recMainGrp_Search	
	DEFINE recMainGrp  OF t_recMainGrp 
	DEFINE arrMainGrp_List DYNAMIC ARRAY OF t_recMainGrp  
	DEFINE c_MainGrp  CURSOR
	DEFINE retError SMALLINT	
	CALL MainGrp_LookupSearchDataSourceCursor(p_recMainGrp_Search) RETURNING c_MainGrp 
	
	CALL arrMainGrp_List.CLEAR()

	CALL c_maingrp.SetResults(recmaingrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_maingrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_maingrp.FetchNext()=0)
		CALL arrMainGrp_List.append([recmaingrp.maingrp_code, recmaingrp.desc_text])
	END WHILE	

	END IF
	
	IF arrMainGrp_List.getSize() = 0 THEN
		ERROR "No maingrp 's found with the specified filter criteria"
	END IF
	
	RETURN arrMainGrp_List
END FUNCTION


########################################################################################
# FUNCTION maingrp_Lookup_filter(p_maingrp_code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required MainGrp  code maingrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the MainGrp  Code maingrp_code
#
# Example:
# 			LET pr_maingrp.maingrp_code = MainGrp_Lookup(pr_maingrp.maingrp_code)
########################################################################################
FUNCTION maingrp_Lookup_filter(p_maingrp_code)
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE arrMainGrp_List DYNAMIC ARRAY OF t_recMainGrp 
	DEFINE recMainGrp_Filter OF t_recMainGrp_Filter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wMainGrp_Lookup WITH FORM "MainGrp_Lookup_filter"


	CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recMainGrp_Filter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrMainGrp_List TO scMainGrp_List.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_maingrp_code = arrMainGrp_List[idx].maingrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recMainGrp_Filter.filter_maingrp_code IS NOT NULL
			OR recMainGrp_Filter.filter_desc_text IS NOT NULL

		THEN
			LET recMainGrp_Filter.filter_maingrp_code = NULL
			LET recMainGrp_Filter.filter_desc_text = NULL

			CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_maingrp_code"
		IF recMainGrp_Filter.filter_maingrp_code IS NOT NULL THEN
			LET recMainGrp_Filter.filter_maingrp_code = NULL
			CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recMainGrp_Filter.filter_desc_text IS NOT NULL THEN
			LET recMainGrp_Filter.filter_desc_text = NULL
			CALL MainGrp_LookupFilterDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wMainGrp_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_maingrp_code	
END FUNCTION				
		

########################################################################################
# FUNCTION maingrp_Lookup(p_maingrp_code)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required MainGrp  code maingrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL MainGrp_LookupSearchDataSource(recMainGrp_Filter.*) RETURNING arrMainGrp_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the MainGrp  Code maingrp_code
#
# Example:
# 			LET pr_maingrp.maingrp_code = MainGrp_Lookup(pr_maingrp.maingrp_code)
########################################################################################
FUNCTION maingrp_Lookup(p_maingrp_code)
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE arrMainGrp_List DYNAMIC ARRAY OF t_recMainGrp 
	DEFINE recMainGrp_Search OF t_recMainGrp_Search	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wMainGrp_Lookup WITH FORM "maingrp_Lookup"

	CALL MainGrp_LookupSearchDataSource(recMainGrp_Search.*) RETURNING arrMainGrp_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recMainGrp_Search.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL MainGrp_LookupSearchDataSource(recMainGrp_Search.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrMainGrp_List TO scMainGrp_List.* 
		BEFORE ROW
			IF arrMainGrp_List.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_maingrp_code = arrMainGrp_List[idx].maingrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recMainGrp_Search.filter_any_field IS NOT NULL

		THEN
			LET recMainGrp_Search.filter_any_field = NULL

			CALL MainGrp_LookupSearchDataSource(recMainGrp_Search.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_maingrp_code"
		IF recMainGrp_Search.filter_any_field IS NOT NULL THEN
			LET recMainGrp_Search.filter_any_field = NULL
			CALL MainGrp_LookupSearchDataSource(recMainGrp_Search.*) RETURNING arrMainGrp_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wMainGrp_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_maingrp_code	
END FUNCTION				

############################################
# FUNCTION import_maingrp()
############################################
FUNCTION import_maingrp()
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
	
	DEFINE rec_maingrp  OF t_recMainGrp_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wMainGrp_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Main Group List Data (table: maingrp )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_maingrp 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_maingrp (
    maingrp_code CHAR(3),
    desc_text CHAR(30),
    min_month_amt DECIMAL(16,2),
    min_quart_amt DECIMAL(16,2),
    min_year_amt DECIMAL(16,2),
    dept_code CHAR(3)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_maingrp 	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wMainGrp_Import WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wMainGrp_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/maingrp-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("MainGroup Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_maingrp 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_maingrp 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_maingrp 
			LET importReport = importReport, "Code:", trim(rec_maingrp.maingrp_code) , "     -     Desc:", trim(rec_maingrp.desc_text), "\n"
					
			INSERT INTO maingrp  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_maingrp.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_maingrp.maingrp_code) , "     -     Desc:", trim(rec_maingrp.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wMainGrp_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_maingrp_Rec(p_cmpy_code, p_maingrp_code)
########################################################
FUNCTION exist_maingrp_Rec(p_cmpy_code, p_maingrp_code)
	DEFINE p_cmpy_code LIKE maingrp.cmpy_code
	DEFINE p_maingrp_code LIKE maingrp.maingrp_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM maingrp  
     WHERE cmpy_code = p_cmpy_code
     AND maingrp_code = p_maingrp_code

	DROP TABLE temp_maingrp 
	CLOSE WINDOW wMainGrp_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_maingrp()
###############################################################
FUNCTION unload_maingrp (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/maingrp-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM maingrp ORDER BY cmpy_code, maingrp_code ASC
	
	LET tmpMsg = "All maingrp data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("maingrp Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_maingrp_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_maingrp_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE maingrp.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wMainGrp_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Main Group (maingrp) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing maingrp table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM maingrp
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table maingrp!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table maingrp where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wMainGrp_Import		
END FUNCTION	