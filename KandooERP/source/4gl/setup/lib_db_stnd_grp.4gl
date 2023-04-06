GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getStnd_GrpCount()
# FUNCTION stnd_grpLookupFilterDataSourceCursor(pRecStnd_GrpFilter)
# FUNCTION stnd_grpLookupSearchDataSourceCursor(p_RecStnd_GrpSearch)
# FUNCTION Stnd_GrpLookupFilterDataSource(pRecStnd_GrpFilter)
# FUNCTION stnd_grpLookup_filter(pStnd_GrpCode)
# FUNCTION import_stnd_grp()
# FUNCTION exist_stnd_grpRec(p_cmpy_code, p_group_code)
# FUNCTION delete_stnd_grp_all()
# FUNCTION stnd_grpMenu()						-- Offer different OPTIONS of this library via a menu

# Stnd_Grp record types
	DEFINE t_recStnd_Grp  
		TYPE AS RECORD
			group_code LIKE stnd_grp.group_code,
			desc_text LIKE stnd_grp.desc_text
		END RECORD 

	DEFINE t_recStnd_GrpFilter  
		TYPE AS RECORD
			filter_group_code LIKE stnd_grp.group_code,
			filter_desc_text LIKE stnd_grp.desc_text
		END RECORD 

	DEFINE t_recStnd_GrpSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recStnd_Grp_noCmpyId 
		TYPE AS RECORD 
    group_code CHAR(2),
    desc_text CHAR(40)
	END RECORD	

	
########################################################################################
# FUNCTION stnd_grpMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION stnd_grpMenu()
	MENU
		ON ACTION "Import"
			CALL import_stnd_grp()
		ON ACTION "Export"
			CALL unload_stnd_grp()
		#ON ACTION "Import"
		#	CALL import_stnd_grp()
		ON ACTION "Delete All"
			CALL delete_stnd_grp_all()
		ON ACTION "Count"
			CALL getStnd_GrpCount() --Count all stnd_grp rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getStnd_GrpCount()
#-------------------------------------------------------
# Returns the number of Stnd_Grp entries for the current company
########################################################################################
FUNCTION getStnd_GrpCount()
	DEFINE ret_Stnd_GrpCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Stnd_Grp CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Stnd_Grp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Stnd_Grp.DECLARE(sqlQuery) #CURSOR FOR getStnd_Grp
	CALL c_Stnd_Grp.SetResults(ret_Stnd_GrpCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Stnd_Grp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_Stnd_GrpCount = -1
	ELSE
		CALL c_Stnd_Grp.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Standard Groups:", trim(ret_Stnd_GrpCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Standard Groups (Stnd_Grp) Count", tempMsg,"info") 	
	END IF

	RETURN ret_Stnd_GrpCount
END FUNCTION

########################################################################################
# FUNCTION stnd_grpLookupFilterDataSourceCursor(pRecStnd_GrpFilter)
#-------------------------------------------------------
# Returns the Stnd_Grp CURSOR for the lookup query
########################################################################################
FUNCTION stnd_grpLookupFilterDataSourceCursor(pRecStnd_GrpFilter)
	DEFINE pRecStnd_GrpFilter OF t_recStnd_GrpFilter
	DEFINE sqlQuery STRING
	DEFINE c_Stnd_Grp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"stnd_grp.group_code, ", 
									"stnd_grp.desc_text ",
									"FROM stnd_grp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecStnd_GrpFilter.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", pRecStnd_GrpFilter.filter_group_code CLIPPED, "%' "  
	END IF									

	IF pRecStnd_GrpFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecStnd_GrpFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY group_code"

	CALL c_stnd_grp.DECLARE(sqlQuery)
		
	RETURN c_stnd_grp
END FUNCTION



########################################################################################
# stnd_grpLookupSearchDataSourceCursor(p_RecStnd_GrpSearch)
#-------------------------------------------------------
# Returns the Stnd_Grp CURSOR for the lookup query
########################################################################################
FUNCTION stnd_grpLookupSearchDataSourceCursor(p_RecStnd_GrpSearch)
	DEFINE p_RecStnd_GrpSearch OF t_recStnd_GrpSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Stnd_Grp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"stnd_grp.group_code, ", 
									"stnd_grp.desc_text ",
 
									"FROM stnd_grp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecStnd_GrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((group_code LIKE '", p_RecStnd_GrpSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecStnd_GrpSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecStnd_GrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY group_code"

	CALL c_stnd_grp.DECLARE(sqlQuery) #CURSOR FOR stnd_grp
	
	RETURN c_stnd_grp
END FUNCTION


########################################################################################
# FUNCTION Stnd_GrpLookupFilterDataSource(pRecStnd_GrpFilter)
#-------------------------------------------------------
# CALLS Stnd_GrpLookupFilterDataSourceCursor(pRecStnd_GrpFilter) with the Stnd_GrpFilter data TO get a CURSOR
# Returns the Stnd_Grp list array arrStnd_GrpList
########################################################################################
FUNCTION Stnd_GrpLookupFilterDataSource(pRecStnd_GrpFilter)
	DEFINE pRecStnd_GrpFilter OF t_recStnd_GrpFilter
	DEFINE recStnd_Grp OF t_recStnd_Grp
	DEFINE arrStnd_GrpList DYNAMIC ARRAY OF t_recStnd_Grp 
	DEFINE c_Stnd_Grp CURSOR
	DEFINE retError SMALLINT
		
	CALL Stnd_GrpLookupFilterDataSourceCursor(pRecStnd_GrpFilter.*) RETURNING c_Stnd_Grp
	
	CALL arrStnd_GrpList.CLEAR()

	CALL c_Stnd_Grp.SetResults(recStnd_Grp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Stnd_Grp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Stnd_Grp.FetchNext()=0)
		CALL arrStnd_GrpList.append([recStnd_Grp.group_code, recStnd_Grp.desc_text])
	END WHILE	

	END IF
	
	IF arrStnd_GrpList.getSize() = 0 THEN
		ERROR "No stnd_grp's found with the specified filter criteria"
	END IF
	
	RETURN arrStnd_GrpList
END FUNCTION	

########################################################################################
# FUNCTION Stnd_GrpLookupSearchDataSource(pRecStnd_GrpFilter)
#-------------------------------------------------------
# CALLS Stnd_GrpLookupSearchDataSourceCursor(pRecStnd_GrpFilter) with the Stnd_GrpFilter data TO get a CURSOR
# Returns the Stnd_Grp list array arrStnd_GrpList
########################################################################################
FUNCTION Stnd_GrpLookupSearchDataSource(p_recStnd_GrpSearch)
	DEFINE p_recStnd_GrpSearch OF t_recStnd_GrpSearch	
	DEFINE recStnd_Grp OF t_recStnd_Grp
	DEFINE arrStnd_GrpList DYNAMIC ARRAY OF t_recStnd_Grp 
	DEFINE c_Stnd_Grp CURSOR
	DEFINE retError SMALLINT	
	CALL Stnd_GrpLookupSearchDataSourceCursor(p_recStnd_GrpSearch) RETURNING c_Stnd_Grp
	
	CALL arrStnd_GrpList.CLEAR()

	CALL c_Stnd_Grp.SetResults(recStnd_Grp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Stnd_Grp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Stnd_Grp.FetchNext()=0)
		CALL arrStnd_GrpList.append([recStnd_Grp.group_code, recStnd_Grp.desc_text])
	END WHILE	

	END IF
	
	IF arrStnd_GrpList.getSize() = 0 THEN
		ERROR "No stnd_grp's found with the specified filter criteria"
	END IF
	
	RETURN arrStnd_GrpList
END FUNCTION


########################################################################################
# FUNCTION stnd_grpLookup_filter(pStnd_GrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Stnd_Grp code group_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Stnd_Grp Code group_code
#
# Example:
# 			LET pr_Stnd_Grp.group_code = Stnd_GrpLookup(pr_Stnd_Grp.group_code)
########################################################################################
FUNCTION stnd_grpLookup_filter(pStnd_GrpCode)
	DEFINE pStnd_GrpCode LIKE Stnd_Grp.group_code
	DEFINE arrStnd_GrpList DYNAMIC ARRAY OF t_recStnd_Grp
	DEFINE recStnd_GrpFilter OF t_recStnd_GrpFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wStnd_GrpLookup WITH FORM "Stnd_GrpLookup_filter"


	CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recStnd_GrpFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrStnd_GrpList TO scStnd_GrpList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pStnd_GrpCode = arrStnd_GrpList[idx].group_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recStnd_GrpFilter.filter_group_code IS NOT NULL
			OR recStnd_GrpFilter.filter_desc_text IS NOT NULL

		THEN
			LET recStnd_GrpFilter.filter_group_code = NULL
			LET recStnd_GrpFilter.filter_desc_text = NULL

			CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_group_code"
		IF recStnd_GrpFilter.filter_group_code IS NOT NULL THEN
			LET recStnd_GrpFilter.filter_group_code = NULL
			CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recStnd_GrpFilter.filter_desc_text IS NOT NULL THEN
			LET recStnd_GrpFilter.filter_desc_text = NULL
			CALL Stnd_GrpLookupFilterDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wStnd_GrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pStnd_GrpCode	
END FUNCTION				
		

########################################################################################
# FUNCTION stnd_grpLookup(pStnd_GrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Stnd_Grp code group_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Stnd_GrpLookupSearchDataSource(recStnd_GrpFilter.*) RETURNING arrStnd_GrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Stnd_Grp Code group_code
#
# Example:
# 			LET pr_Stnd_Grp.group_code = Stnd_GrpLookup(pr_Stnd_Grp.group_code)
########################################################################################
FUNCTION stnd_grpLookup(pStnd_GrpCode)
	DEFINE pStnd_GrpCode LIKE Stnd_Grp.group_code
	DEFINE arrStnd_GrpList DYNAMIC ARRAY OF t_recStnd_Grp
	DEFINE recStnd_GrpSearch OF t_recStnd_GrpSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wStnd_GrpLookup WITH FORM "stnd_grpLookup"

	CALL Stnd_GrpLookupSearchDataSource(recStnd_GrpSearch.*) RETURNING arrStnd_GrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recStnd_GrpSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL Stnd_GrpLookupSearchDataSource(recStnd_GrpSearch.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrStnd_GrpList TO scStnd_GrpList.* 
		BEFORE ROW
			IF arrStnd_GrpList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pStnd_GrpCode = arrStnd_GrpList[idx].group_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recStnd_GrpSearch.filter_any_field IS NOT NULL

		THEN
			LET recStnd_GrpSearch.filter_any_field = NULL

			CALL Stnd_GrpLookupSearchDataSource(recStnd_GrpSearch.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_group_code"
		IF recStnd_GrpSearch.filter_any_field IS NOT NULL THEN
			LET recStnd_GrpSearch.filter_any_field = NULL
			CALL Stnd_GrpLookupSearchDataSource(recStnd_GrpSearch.*) RETURNING arrStnd_GrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wStnd_GrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pStnd_GrpCode	
END FUNCTION				

############################################
# FUNCTION import_stnd_grp()
############################################
FUNCTION import_stnd_grp()
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
	
	DEFINE rec_stnd_grp OF t_recStnd_Grp_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wStnd_GrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Standard Group List Data (table: stnd_grp)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_stnd_grp
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_stnd_grp(
	    group_code CHAR(3),
	    desc_text CHAR(40)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_stnd_grp	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wStnd_GrpImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wStnd_GrpImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/stnd_grp-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_stnd_grp
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_stnd_grp
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_stnd_grp
			LET importReport = importReport, "Code:", trim(rec_stnd_grp.group_code) , "     -     Desc:", trim(rec_stnd_grp.desc_text), "\n"
					
			INSERT INTO stnd_grp VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_stnd_grp.group_code,
			rec_stnd_grp.desc_text
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_stnd_grp.group_code) , "     -     Desc:", trim(rec_stnd_grp.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wStnd_GrpImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_stnd_grpRec(p_cmpy_code, p_group_code)
########################################################
FUNCTION exist_stnd_grpRec(p_cmpy_code, p_group_code)
	DEFINE p_cmpy_code LIKE stnd_grp.cmpy_code
	DEFINE p_group_code LIKE stnd_grp.group_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM stnd_grp 
     WHERE cmpy_code = p_cmpy_code
     AND group_code = p_group_code

	DROP TABLE temp_stnd_grp
	CLOSE WINDOW wStnd_GrpImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_stnd_grp()
###############################################################
FUNCTION unload_stnd_grp(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/stnd_grp-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM stnd_grp ORDER BY cmpy_code, group_code ASC
	
	LET tmpMsg = "All stnd_grp data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("stnd_grp Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_stnd_grp_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_stnd_grp_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE stnd_grp.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wstnd_grpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "stnd_grp Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing stnd_grp table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM stnd_grp
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table stnd_grp!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table stnd_grp where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wStnd_GrpImport		
END FUNCTION	