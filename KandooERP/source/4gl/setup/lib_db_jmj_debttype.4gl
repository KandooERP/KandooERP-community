GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getJmj_DebttypeCount()
# FUNCTION jmj_debttypeLookupFilterDataSourceCursor(pRecJmj_DebttypeFilter)
# FUNCTION jmj_debttypeLookupSearchDataSourceCursor(p_RecJmj_DebttypeSearch)
# FUNCTION Jmj_DebttypeLookupFilterDataSource(pRecJmj_DebttypeFilter)
# FUNCTION jmj_debttypeLookup_filter(pJmj_DebttypeCode)
# FUNCTION import_jmj_debttype()
# FUNCTION exist_jmj_debttypeRec(p_cmpy_code, p_debt_type_code)
# FUNCTION delete_jmj_debttype_all()
# FUNCTION jmj_DebttypeMenu()						-- Offer different OPTIONS of this library via a menu

# Jmj_Debttype record types
	DEFINE t_recJmj_Debttype  
		TYPE AS RECORD
			debt_type_code LIKE jmj_debttype.debt_type_code,
			desc_text LIKE jmj_debttype.desc_text
		END RECORD 

	DEFINE t_recJmj_DebttypeFilter  
		TYPE AS RECORD
			filter_debt_type_code LIKE jmj_debttype.debt_type_code,
			filter_desc_text LIKE jmj_debttype.desc_text
		END RECORD 

	DEFINE t_recJmj_DebttypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recJmj_Debttype_noCmpyId 
		TYPE AS RECORD 
    debt_type_code CHAR(3),
    desc_text CHAR(30)
	END RECORD	

	
########################################################################################
# FUNCTION jmj_DebttypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION jmj_DebttypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_jmj_debttype()
		ON ACTION "Export"
			CALL unload_jmj_debttype(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_jmj_debttype()
		ON ACTION "Delete All"
			CALL delete_jmj_debttype_all()
		ON ACTION "Count"
			CALL getJmj_DebttypeCount() --Count all jmj_debttype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getJmj_DebttypeCount()
#-------------------------------------------------------
# Returns the number of Jmj_Debttype entries for the current company
########################################################################################
FUNCTION getJmj_DebttypeCount()
	DEFINE ret_Jmj_DebttypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Jmj_Debttype CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Jmj_Debttype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Jmj_Debttype.DECLARE(sqlQuery) #CURSOR FOR getJmj_Debttype
	CALL c_Jmj_Debttype.SetResults(ret_Jmj_DebttypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Debttype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_Jmj_DebttypeCount = -1
	ELSE
		CALL c_Jmj_Debttype.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Dept/Liability Types:", trim(ret_Jmj_DebttypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Dept/Liability  Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_Jmj_DebttypeCount
END FUNCTION

########################################################################################
# FUNCTION jmj_debttypeLookupFilterDataSourceCursor(pRecJmj_DebttypeFilter)
#-------------------------------------------------------
# Returns the Jmj_Debttype CURSOR for the lookup query
########################################################################################
FUNCTION jmj_debttypeLookupFilterDataSourceCursor(pRecJmj_DebttypeFilter)
	DEFINE pRecJmj_DebttypeFilter OF t_recJmj_DebttypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Jmj_Debttype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"jmj_debttype.debt_type_code, ", 
									"jmj_debttype.desc_text ",
									"FROM jmj_debttype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecJmj_DebttypeFilter.filter_debt_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND debt_type_code LIKE '", pRecJmj_DebttypeFilter.filter_debt_type_code CLIPPED, "%' "  
	END IF									

	IF pRecJmj_DebttypeFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecJmj_DebttypeFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY debt_type_code"

	CALL c_jmj_debttype.DECLARE(sqlQuery)
		
	RETURN c_jmj_debttype
END FUNCTION



########################################################################################
# jmj_debttypeLookupSearchDataSourceCursor(p_RecJmj_DebttypeSearch)
#-------------------------------------------------------
# Returns the Jmj_Debttype CURSOR for the lookup query
########################################################################################
FUNCTION jmj_debttypeLookupSearchDataSourceCursor(p_RecJmj_DebttypeSearch)
	DEFINE p_RecJmj_DebttypeSearch OF t_recJmj_DebttypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Jmj_Debttype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"jmj_debttype.debt_type_code, ", 
									"jmj_debttype.desc_text ",
 
									"FROM jmj_debttype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecJmj_DebttypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((debt_type_code LIKE '", p_RecJmj_DebttypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecJmj_DebttypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecJmj_DebttypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY debt_type_code"

	CALL c_jmj_debttype.DECLARE(sqlQuery) #CURSOR FOR jmj_debttype
	
	RETURN c_jmj_debttype
END FUNCTION


########################################################################################
# FUNCTION Jmj_DebttypeLookupFilterDataSource(pRecJmj_DebttypeFilter)
#-------------------------------------------------------
# CALLS Jmj_DebttypeLookupFilterDataSourceCursor(pRecJmj_DebttypeFilter) with the Jmj_DebttypeFilter data TO get a CURSOR
# Returns the Jmj_Debttype list array arrJmj_DebttypeList
########################################################################################
FUNCTION Jmj_DebttypeLookupFilterDataSource(pRecJmj_DebttypeFilter)
	DEFINE pRecJmj_DebttypeFilter OF t_recJmj_DebttypeFilter
	DEFINE recJmj_Debttype OF t_recJmj_Debttype
	DEFINE arrJmj_DebttypeList DYNAMIC ARRAY OF t_recJmj_Debttype 
	DEFINE c_Jmj_Debttype CURSOR
	DEFINE retError SMALLINT
		
	CALL Jmj_DebttypeLookupFilterDataSourceCursor(pRecJmj_DebttypeFilter.*) RETURNING c_Jmj_Debttype
	
	CALL arrJmj_DebttypeList.CLEAR()

	CALL c_Jmj_Debttype.SetResults(recJmj_Debttype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Debttype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Jmj_Debttype.FetchNext()=0)
		CALL arrJmj_DebttypeList.append([recJmj_Debttype.debt_type_code, recJmj_Debttype.desc_text])
	END WHILE	

	END IF
	
	IF arrJmj_DebttypeList.getSize() = 0 THEN
		ERROR "No jmj_debttype's found with the specified filter criteria"
	END IF
	
	RETURN arrJmj_DebttypeList
END FUNCTION	

########################################################################################
# FUNCTION Jmj_DebttypeLookupSearchDataSource(pRecJmj_DebttypeFilter)
#-------------------------------------------------------
# CALLS Jmj_DebttypeLookupSearchDataSourceCursor(pRecJmj_DebttypeFilter) with the Jmj_DebttypeFilter data TO get a CURSOR
# Returns the Jmj_Debttype list array arrJmj_DebttypeList
########################################################################################
FUNCTION Jmj_DebttypeLookupSearchDataSource(p_recJmj_DebttypeSearch)
	DEFINE p_recJmj_DebttypeSearch OF t_recJmj_DebttypeSearch	
	DEFINE recJmj_Debttype OF t_recJmj_Debttype
	DEFINE arrJmj_DebttypeList DYNAMIC ARRAY OF t_recJmj_Debttype 
	DEFINE c_Jmj_Debttype CURSOR
	DEFINE retError SMALLINT	
	CALL Jmj_DebttypeLookupSearchDataSourceCursor(p_recJmj_DebttypeSearch) RETURNING c_Jmj_Debttype
	
	CALL arrJmj_DebttypeList.CLEAR()

	CALL c_Jmj_Debttype.SetResults(recJmj_Debttype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Debttype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Jmj_Debttype.FetchNext()=0)
		CALL arrJmj_DebttypeList.append([recJmj_Debttype.debt_type_code, recJmj_Debttype.desc_text])
	END WHILE	

	END IF
	
	IF arrJmj_DebttypeList.getSize() = 0 THEN
		ERROR "No jmj_debttype's found with the specified filter criteria"
	END IF
	
	RETURN arrJmj_DebttypeList
END FUNCTION


########################################################################################
# FUNCTION jmj_debttypeLookup_filter(pJmj_DebttypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Jmj_Debttype code debt_type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Jmj_Debttype Code debt_type_code
#
# Example:
# 			LET pr_Jmj_Debttype.debt_type_code = Jmj_DebttypeLookup(pr_Jmj_Debttype.debt_type_code)
########################################################################################
FUNCTION jmj_debttypeLookup_filter(pJmj_DebttypeCode)
	DEFINE pJmj_DebttypeCode LIKE Jmj_Debttype.debt_type_code
	DEFINE arrJmj_DebttypeList DYNAMIC ARRAY OF t_recJmj_Debttype
	DEFINE recJmj_DebttypeFilter OF t_recJmj_DebttypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wJmj_DebttypeLookup WITH FORM "Jmj_DebttypeLookup_filter"


	CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recJmj_DebttypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrJmj_DebttypeList TO scJmj_DebttypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pJmj_DebttypeCode = arrJmj_DebttypeList[idx].debt_type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recJmj_DebttypeFilter.filter_debt_type_code IS NOT NULL
			OR recJmj_DebttypeFilter.filter_desc_text IS NOT NULL

		THEN
			LET recJmj_DebttypeFilter.filter_debt_type_code = NULL
			LET recJmj_DebttypeFilter.filter_desc_text = NULL

			CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_debt_type_code"
		IF recJmj_DebttypeFilter.filter_debt_type_code IS NOT NULL THEN
			LET recJmj_DebttypeFilter.filter_debt_type_code = NULL
			CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recJmj_DebttypeFilter.filter_desc_text IS NOT NULL THEN
			LET recJmj_DebttypeFilter.filter_desc_text = NULL
			CALL Jmj_DebttypeLookupFilterDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wJmj_DebttypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pJmj_DebttypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION jmj_debttypeLookup(pJmj_DebttypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Jmj_Debttype code debt_type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Jmj_DebttypeLookupSearchDataSource(recJmj_DebttypeFilter.*) RETURNING arrJmj_DebttypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Jmj_Debttype Code debt_type_code
#
# Example:
# 			LET pr_Jmj_Debttype.debt_type_code = Jmj_DebttypeLookup(pr_Jmj_Debttype.debt_type_code)
########################################################################################
FUNCTION jmj_debttypeLookup(pJmj_DebttypeCode)
	DEFINE pJmj_DebttypeCode LIKE Jmj_Debttype.debt_type_code
	DEFINE arrJmj_DebttypeList DYNAMIC ARRAY OF t_recJmj_Debttype
	DEFINE recJmj_DebttypeSearch OF t_recJmj_DebttypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wJmj_DebttypeLookup WITH FORM "jmj_debttypeLookup"

	CALL Jmj_DebttypeLookupSearchDataSource(recJmj_DebttypeSearch.*) RETURNING arrJmj_DebttypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recJmj_DebttypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL Jmj_DebttypeLookupSearchDataSource(recJmj_DebttypeSearch.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrJmj_DebttypeList TO scJmj_DebttypeList.* 
		BEFORE ROW
			IF arrJmj_DebttypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pJmj_DebttypeCode = arrJmj_DebttypeList[idx].debt_type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recJmj_DebttypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recJmj_DebttypeSearch.filter_any_field = NULL

			CALL Jmj_DebttypeLookupSearchDataSource(recJmj_DebttypeSearch.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_debt_type_code"
		IF recJmj_DebttypeSearch.filter_any_field IS NOT NULL THEN
			LET recJmj_DebttypeSearch.filter_any_field = NULL
			CALL Jmj_DebttypeLookupSearchDataSource(recJmj_DebttypeSearch.*) RETURNING arrJmj_DebttypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wJmj_DebttypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pJmj_DebttypeCode	
END FUNCTION				

############################################
# FUNCTION import_jmj_debttype()
############################################
FUNCTION import_jmj_debttype()
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
	
	DEFINE rec_jmj_debttype OF t_recJmj_Debttype_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wJmj_DebttypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Dept/Liability Type List Data (table: jmj_debttype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_jmj_debttype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_jmj_debttype(
	    debt_type_code CHAR(3),
	    desc_text CHAR(30)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_jmj_debttype	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wJmj_DebttypeImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wJmj_DebttypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/jmj_debttype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_jmj_debttype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_jmj_debttype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_jmj_debttype
			LET importReport = importReport, "Code:", trim(rec_jmj_debttype.debt_type_code) , "     -     Desc:", trim(rec_jmj_debttype.desc_text), "\n"
					
			INSERT INTO jmj_debttype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_jmj_debttype.debt_type_code,
			rec_jmj_debttype.desc_text
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_jmj_debttype.debt_type_code) , "     -     Desc:", trim(rec_jmj_debttype.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wJmj_DebttypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_jmj_debttypeRec(p_cmpy_code, p_debt_type_code)
########################################################
FUNCTION exist_jmj_debttypeRec(p_cmpy_code, p_debt_type_code)
	DEFINE p_cmpy_code LIKE jmj_debttype.cmpy_code
	DEFINE p_debt_type_code LIKE jmj_debttype.debt_type_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM jmj_debttype 
     WHERE cmpy_code = p_cmpy_code
     AND debt_type_code = p_debt_type_code

	DROP TABLE temp_jmj_debttype
	CLOSE WINDOW wJmj_DebttypeImport
	
	RETURN recCount

END FUNCTION



###############################################################
# FUNCTION unload_jmj_debttype()
###############################################################
FUNCTION unload_jmj_debttype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()
	
	LET unloadFile = "unl/jmj_debttype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension
	
	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1 
		SELECT 
	    #cmpy_code,
	    debt_type_code,
	    desc_text 
		FROM jmj_debttype
		WHERE cmpy_code = currentCompany 
		ORDER BY debt_type_code ASC

	LET unloadFile2 = unloadFile CLIPPED, "_all"
		
	UNLOAD TO unloadFile2 
		SELECT * 
		FROM jmj_debttype 
		ORDER BY cmpy_code, debt_type_code ASC
	
	
	LET tmpMsg = "All jmj_debttype data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("jmj_debttype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION


###############################################################
# FUNCTION delete_jmj_debttype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_jmj_debttype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE jmj_debttype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wjmj_debttypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "jmj_debttype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing jmj_debttype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM jmj_debttype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table jmj_debttype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table jmj_debttype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wJmj_DebttypeImport		
END FUNCTION	