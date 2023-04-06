GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getipparms_Count()
# FUNCTION ipparms_LookupFilterDataSourceCursor(pRecipparms_Filter)
# FUNCTION ipparms_LookupSearchDataSourceCursor(p_Recipparms_Search)
# FUNCTION ipparms_LookupFilterDataSource(pRecipparms_Filter)
# FUNCTION ipparms_Lookup_filter(p_key_num)
# FUNCTION import_ipparms()
# FUNCTION exist_ipparms_Rec(p_cmpy_code, p_key_num)
# FUNCTION delete_ipparms_all()
# FUNCTION ipparmsMenu()						-- Offer different OPTIONS of this library via a menu

# ipparms  record types
	DEFINE t_recipparms   
		TYPE AS RECORD
			key_num LIKE ipparms.key_num,
			ref1_text LIKE ipparms.ref1_text
		END RECORD 

	DEFINE t_recipparms_Filter  
		TYPE AS RECORD
			filter_key_num LIKE ipparms.key_num,
			filter_ref1_text LIKE ipparms.ref1_text
		END RECORD 

	DEFINE t_recipparms_Search  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recipparms_noCmpyId 
		TYPE AS RECORD 
    key_num LIKE ipparms.key_num,
    ref1_text  LIKE ipparms.ref1_text,
    ref1_shrt_text  LIKE ipparms.ref1_shrt_text,
    ref2_text  LIKE ipparms.ref2_text,
    ref2_shrt_text  LIKE ipparms.ref2_shrt_text,
    ref3_text  LIKE ipparms.ref3_text,
    ref3_shrt_text  LIKE ipparms.ref3_shrt_text,
    ref4_text  LIKE ipparms.ref4_text,
    ref4_shrt_text  LIKE ipparms.ref4_shrt_text,
    ref5_text  LIKE ipparms.ref5_text,
    ref5_shrt_text  LIKE ipparms.ref5_shrt_text,
    ref6_text  LIKE ipparms.ref6_text,
    ref6_shrt_text  LIKE ipparms.ref6_shrt_text,
    ref7_text  LIKE ipparms.ref7_text,
    ref7_shrt_text  LIKE ipparms.ref7_shrt_text,
    ref8_text  LIKE ipparms.ref8_text,
    ref8_shrt_text  LIKE ipparms.ref8_shrt_text,
    ref9_text  LIKE ipparms.ref9_text,
    ref9_shrt_text  LIKE ipparms.ref9_shrt_text,
    refa_text  LIKE ipparms.refa_text,
    refa_shrt_text  LIKE ipparms.refa_shrt_text
	END RECORD	

	
########################################################################################
# FUNCTION ipparmsMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION ipparmsMenu()
	MENU
		ON ACTION "Import"
			CALL import_ipparms()
		ON ACTION "Export"
			CALL unload_ipparms()
		#ON ACTION "Import"
		#	CALL import_ipparms()
		ON ACTION "Delete All"
			CALL delete_ipparms_all()
		ON ACTION "Count"
			CALL getipparms_Count() --Count all ipparms  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getipparms_Count()
#-------------------------------------------------------
# Returns the number of ipparms  entries for the current company
########################################################################################
FUNCTION getipparms_Count()
	DEFINE ret_ipparms_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ipparms  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM ipparms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_ipparms.DECLARE(sqlQuery) #CURSOR FOR getipparms 
	CALL c_ipparms.SetResults(ret_ipparms_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_ipparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ipparms_Count = -1
	ELSE
		CALL c_ipparms.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product IN Parameter Sets:", trim(ret_ipparms_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("IN Parameter Set Count", tempMsg,"info") 	
	END IF

	RETURN ret_ipparms_Count
END FUNCTION

########################################################################################
# FUNCTION ipparms_LookupFilterDataSourceCursor(pRecipparms_Filter)
#-------------------------------------------------------
# Returns the ipparms  CURSOR for the lookup query
########################################################################################
FUNCTION ipparms_LookupFilterDataSourceCursor(pRecipparms_Filter)
	DEFINE pRecipparms_Filter OF t_recipparms_Filter
	DEFINE sqlQuery STRING
	DEFINE c_ipparms  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"ipparms.key_num, ", 
									"ipparms.ref1_text ",
									"FROM ipparms  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecipparms_Filter.filter_key_num IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND key_num LIKE '", pRecipparms_Filter.filter_key_num CLIPPED, "%' "  
	END IF									

	IF pRecipparms_Filter.filter_ref1_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ref1_text LIKE '", pRecipparms_Filter.filter_ref1_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY key_num"

	CALL c_ipparms.DECLARE(sqlQuery)
		
	RETURN c_ipparms 
END FUNCTION



########################################################################################
# ipparms_LookupSearchDataSourceCursor(p_Recipparms_Search)
#-------------------------------------------------------
# Returns the ipparms  CURSOR for the lookup query
########################################################################################
FUNCTION ipparms_LookupSearchDataSourceCursor(p_Recipparms_Search)
	DEFINE p_Recipparms_Search OF t_recipparms_Search  
	DEFINE sqlQuery STRING
	DEFINE c_ipparms  CURSOR
	
	LET sqlQuery =	"SELECT ",
									"ipparms.key_num, ", 
									"ipparms.ref1_text ",
 
									"FROM ipparms  ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_Recipparms_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((key_num LIKE '", p_Recipparms_Search.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR ref1_text LIKE '",   p_Recipparms_Search.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_Recipparms_Search.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY key_num"

	CALL c_ipparms.DECLARE(sqlQuery) #CURSOR FOR ipparms 
	
	RETURN c_ipparms 
END FUNCTION


########################################################################################
# FUNCTION ipparms_LookupFilterDataSource(pRecipparms_Filter)
#-------------------------------------------------------
# CALLS ipparms_LookupFilterDataSourceCursor(pRecipparms_Filter) with the ipparms_Filter data TO get a CURSOR
# Returns the ipparms  list array arripparms_List
########################################################################################
FUNCTION ipparms_LookupFilterDataSource(pRecipparms_Filter)
	DEFINE pRecipparms_Filter OF t_recipparms_Filter
	DEFINE recipparms  OF t_recipparms 
	DEFINE arripparms_List DYNAMIC ARRAY OF t_recipparms  
	DEFINE c_ipparms  CURSOR
	DEFINE retError SMALLINT
		
	CALL ipparms_LookupFilterDataSourceCursor(pRecipparms_Filter.*) RETURNING c_ipparms 
	
	CALL arripparms_List.CLEAR()

	CALL c_ipparms.SetResults(recipparms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ipparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ipparms.FetchNext()=0)
		CALL arripparms_List.append([recipparms.key_num, recipparms.ref1_text])
	END WHILE	

	END IF
	
	IF arripparms_List.getSize() = 0 THEN
		ERROR "No ipparms 's found with the specified filter criteria"
	END IF
	
	RETURN arripparms_List
END FUNCTION	

########################################################################################
# FUNCTION ipparms_LookupSearchDataSource(pRecipparms_Filter)
#-------------------------------------------------------
# CALLS ipparms_LookupSearchDataSourceCursor(pRecipparms_Filter) with the ipparms_Filter data TO get a CURSOR
# Returns the ipparms  list array arripparms_List
########################################################################################
FUNCTION ipparms_LookupSearchDataSource(p_recipparms_Search)
	DEFINE p_recipparms_Search OF t_recipparms_Search	
	DEFINE recipparms  OF t_recipparms 
	DEFINE arripparms_List DYNAMIC ARRAY OF t_recipparms  
	DEFINE c_ipparms  CURSOR
	DEFINE retError SMALLINT	
	CALL ipparms_LookupSearchDataSourceCursor(p_recipparms_Search) RETURNING c_ipparms 
	
	CALL arripparms_List.CLEAR()

	CALL c_ipparms.SetResults(recipparms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_ipparms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_ipparms.FetchNext()=0)
		CALL arripparms_List.append([recipparms.key_num, recipparms.ref1_text])
	END WHILE	

	END IF
	
	IF arripparms_List.getSize() = 0 THEN
		ERROR "No ipparms 's found with the specified filter criteria"
	END IF
	
	RETURN arripparms_List
END FUNCTION


########################################################################################
# FUNCTION ipparms_Lookup_filter(p_key_num)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ipparms  code key_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ipparms  Code key_num
#
# Example:
# 			LET pr_ipparms.key_num = ipparms_Lookup(pr_ipparms.key_num)
########################################################################################
FUNCTION ipparms_Lookup_filter(p_key_num)
	DEFINE p_key_num LIKE ipparms.key_num
	DEFINE arripparms_List DYNAMIC ARRAY OF t_recipparms 
	DEFINE recipparms_Filter OF t_recipparms_Filter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wipparms_Lookup WITH FORM "ipparms_Lookup_filter"


	CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recipparms_Filter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arripparms_List TO scipparms_List.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_key_num = arripparms_List[idx].key_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recipparms_Filter.filter_key_num IS NOT NULL
			OR recipparms_Filter.filter_ref1_text IS NOT NULL

		THEN
			LET recipparms_Filter.filter_key_num = NULL
			LET recipparms_Filter.filter_ref1_text = NULL

			CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_key_num"
		IF recipparms_Filter.filter_key_num IS NOT NULL THEN
			LET recipparms_Filter.filter_key_num = NULL
			CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_ref1_text"
		IF recipparms_Filter.filter_ref1_text IS NOT NULL THEN
			LET recipparms_Filter.filter_ref1_text = NULL
			CALL ipparms_LookupFilterDataSource(recipparms_Filter.*) RETURNING arripparms_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wipparms_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_key_num	
END FUNCTION				
		

########################################################################################
# FUNCTION ipparms_Lookup(p_key_num)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required ipparms  code key_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL ipparms_LookupSearchDataSource(recipparms_Filter.*) RETURNING arripparms_List
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the ipparms  Code key_num
#
# Example:
# 			LET pr_ipparms.key_num = ipparms_Lookup(pr_ipparms.key_num)
########################################################################################
FUNCTION ipparms_Lookup(p_key_num)
	DEFINE p_key_num LIKE ipparms.key_num
	DEFINE arripparms_List DYNAMIC ARRAY OF t_recipparms 
	DEFINE recipparms_Search OF t_recipparms_Search	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wipparms_Lookup WITH FORM "ipparms_Lookup"

	CALL ipparms_LookupSearchDataSource(recipparms_Search.*) RETURNING arripparms_List

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recipparms_Search.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ipparms_LookupSearchDataSource(recipparms_Search.*) RETURNING arripparms_List
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arripparms_List TO scipparms_List.* 
		BEFORE ROW
			IF arripparms_List.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  p_key_num = arripparms_List[idx].key_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recipparms_Search.filter_any_field IS NOT NULL

		THEN
			LET recipparms_Search.filter_any_field = NULL

			CALL ipparms_LookupSearchDataSource(recipparms_Search.*) RETURNING arripparms_List
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_key_num"
		IF recipparms_Search.filter_any_field IS NOT NULL THEN
			LET recipparms_Search.filter_any_field = NULL
			CALL ipparms_LookupSearchDataSource(recipparms_Search.*) RETURNING arripparms_List
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wipparms_Lookup

	OPTIONS INPUT NO WRAP	
	
	RETURN p_key_num	
END FUNCTION				

############################################
# FUNCTION import_ipparms()
############################################
FUNCTION import_ipparms()
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
	DEFINE p_ref1_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_ipparms  OF t_recipparms_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wipparms_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Schedule Parameters List Data (table: ipparms )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_ipparms 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_ipparms (
    key_num SMALLINT,
    ref1_text CHAR(20),
    ref1_shrt_text CHAR(10),
    ref2_text CHAR(20),
    ref2_shrt_text CHAR(10),
    ref3_text CHAR(20),
    ref3_shrt_text CHAR(10),
    ref4_text CHAR(20),
    ref4_shrt_text CHAR(10),
    ref5_text CHAR(20),
    ref5_shrt_text CHAR(10),
    ref6_text CHAR(20),
    ref6_shrt_text CHAR(10),
    ref7_text CHAR(20),
    ref7_shrt_text CHAR(10),
    ref8_text CHAR(20),
    ref8_shrt_text CHAR(10),
    ref9_text CHAR(20),
    ref9_shrt_text CHAR(10),
    refa_text CHAR(20),
    refa_shrt_text CHAR(10)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_ipparms 	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wipparms_Import WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_ref1_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wipparms_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/ipparms-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("ipparms Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_ipparms 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_ipparms 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_ipparms 
			LET importReport = importReport, "Code:", trim(rec_ipparms.key_num) , "     -     Desc:", trim(rec_ipparms.ref1_text), "\n"
					
			INSERT INTO ipparms  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_ipparms.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_ipparms.key_num) , "     -     Desc:", trim(rec_ipparms.ref1_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wipparms_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_ipparms_Rec(p_cmpy_code, p_key_num)
########################################################
FUNCTION exist_ipparms_Rec(p_cmpy_code, p_key_num)
	DEFINE p_cmpy_code LIKE ipparms.cmpy_code
	DEFINE p_key_num LIKE ipparms.key_num
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM ipparms  
     WHERE cmpy_code = p_cmpy_code
     AND key_num = p_key_num

	DROP TABLE temp_ipparms 
	CLOSE WINDOW wipparms_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_ipparms()
###############################################################
FUNCTION unload_ipparms (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/ipparms-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM ipparms ORDER BY cmpy_code, key_num ASC
	
	LET tmpMsg = "All ipparms data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("ipparms Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_ipparms_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_ipparms_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE ipparms.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wipparms_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Schedule Parameters (ipparms) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing ipparms table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM ipparms
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table ipparms!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table ipparms where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wipparms_Import		
END FUNCTION	