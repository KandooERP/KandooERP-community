GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getJmj_TrantypeCount()
# FUNCTION jmj_trantypeLookupFilterDataSourceCursor(pRecJmj_TrantypeFilter)
# FUNCTION jmj_trantypeLookupSearchDataSourceCursor(p_RecJmj_TrantypeSearch)
# FUNCTION Jmj_TrantypeLookupFilterDataSource(pRecJmj_TrantypeFilter)
# FUNCTION jmj_trantypeLookup_filter(pJmj_TrantypeCode)
# FUNCTION import_jmj_trantype()
# FUNCTION exist_jmj_trantypeRec(p_cmpy_code, p_trans_code)
# FUNCTION delete_jmj_trantype_all()
# FUNCTION jmj_TrantypeMenu()						-- Offer different OPTIONS of this library via a menu

# Jmj_Trantype record types
	DEFINE t_recJmj_Trantype  
		TYPE AS RECORD
			trans_code LIKE jmj_trantype.trans_code,
			desc_text LIKE jmj_trantype.desc_text
		END RECORD 

	DEFINE t_recJmj_TrantypeFilter  
		TYPE AS RECORD
			filter_trans_code LIKE jmj_trantype.trans_code,
			filter_desc_text LIKE jmj_trantype.desc_text
		END RECORD 

	DEFINE t_recJmj_TrantypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recJmj_Trantype_noCmpyId 
		TYPE AS RECORD 
    trans_code LIKE jmj_trantype.trans_code,
    record_ind LIKE jmj_trantype.record_ind,
    imprest_ind LIKE jmj_trantype.imprest_ind,
    desc_text  LIKE jmj_trantype.desc_text,
    cr_acct_code LIKE jmj_trantype.cr_acct_code,
    db_acct_code LIKE jmj_trantype.db_acct_code,
    debt_type_code LIKE jmj_trantype.debt_type_code
	END RECORD	

	
########################################################################################
# FUNCTION jmj_TrantypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION jmj_TrantypeMenu()
	MENU
		ON ACTION "Import"
			CALL import_jmj_trantype()
		ON ACTION "Export"
			CALL unload_jmj_trantype()
		#ON ACTION "Import"
		#	CALL import_jmj_trantype()
		ON ACTION "Delete All"
			CALL delete_jmj_trantype_all()
		ON ACTION "Count"
			CALL getJmj_TrantypeCount() --Count all jmj_trantype rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getJmj_TrantypeCount()
#-------------------------------------------------------
# Returns the number of Jmj_Trantype entries for the current company
########################################################################################
FUNCTION getJmj_TrantypeCount()
	DEFINE ret_Jmj_TrantypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Jmj_Trantype CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Jmj_Trantype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Jmj_Trantype.DECLARE(sqlQuery) #CURSOR FOR getJmj_Trantype
	CALL c_Jmj_Trantype.SetResults(ret_Jmj_TrantypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Trantype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_Jmj_TrantypeCount = -1
	ELSE
		CALL c_Jmj_Trantype.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Transaction Types (jmj_trantype):", trim(ret_Jmj_TrantypeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Transaction Type (jmj_trantype)Count", tempMsg,"info") 	
	END IF

	RETURN ret_Jmj_TrantypeCount
END FUNCTION

########################################################################################
# FUNCTION jmj_trantypeLookupFilterDataSourceCursor(pRecJmj_TrantypeFilter)
#-------------------------------------------------------
# Returns the Jmj_Trantype CURSOR for the lookup query
########################################################################################
FUNCTION jmj_trantypeLookupFilterDataSourceCursor(pRecJmj_TrantypeFilter)
	DEFINE pRecJmj_TrantypeFilter OF t_recJmj_TrantypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Jmj_Trantype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"jmj_trantype.trans_code, ", 
									"jmj_trantype.desc_text ",
									"FROM jmj_trantype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecJmj_TrantypeFilter.filter_trans_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND trans_code LIKE '", pRecJmj_TrantypeFilter.filter_trans_code CLIPPED, "%' "  
	END IF									

	IF pRecJmj_TrantypeFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecJmj_TrantypeFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY trans_code"

	CALL c_jmj_trantype.DECLARE(sqlQuery)
		
	RETURN c_jmj_trantype
END FUNCTION



########################################################################################
# jmj_trantypeLookupSearchDataSourceCursor(p_RecJmj_TrantypeSearch)
#-------------------------------------------------------
# Returns the Jmj_Trantype CURSOR for the lookup query
########################################################################################
FUNCTION jmj_trantypeLookupSearchDataSourceCursor(p_RecJmj_TrantypeSearch)
	DEFINE p_RecJmj_TrantypeSearch OF t_recJmj_TrantypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Jmj_Trantype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"jmj_trantype.trans_code, ", 
									"jmj_trantype.desc_text ",
 
									"FROM jmj_trantype ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecJmj_TrantypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((trans_code LIKE '", p_RecJmj_TrantypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecJmj_TrantypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecJmj_TrantypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY trans_code"

	CALL c_jmj_trantype.DECLARE(sqlQuery) #CURSOR FOR jmj_trantype
	
	RETURN c_jmj_trantype
END FUNCTION


########################################################################################
# FUNCTION Jmj_TrantypeLookupFilterDataSource(pRecJmj_TrantypeFilter)
#-------------------------------------------------------
# CALLS Jmj_TrantypeLookupFilterDataSourceCursor(pRecJmj_TrantypeFilter) with the Jmj_TrantypeFilter data TO get a CURSOR
# Returns the Jmj_Trantype list array arrJmj_TrantypeList
########################################################################################
FUNCTION Jmj_TrantypeLookupFilterDataSource(pRecJmj_TrantypeFilter)
	DEFINE pRecJmj_TrantypeFilter OF t_recJmj_TrantypeFilter
	DEFINE recJmj_Trantype OF t_recJmj_Trantype
	DEFINE arrJmj_TrantypeList DYNAMIC ARRAY OF t_recJmj_Trantype 
	DEFINE c_Jmj_Trantype CURSOR
	DEFINE retError SMALLINT
		
	CALL Jmj_TrantypeLookupFilterDataSourceCursor(pRecJmj_TrantypeFilter.*) RETURNING c_Jmj_Trantype
	
	CALL arrJmj_TrantypeList.CLEAR()

	CALL c_Jmj_Trantype.SetResults(recJmj_Trantype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Trantype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Jmj_Trantype.FetchNext()=0)
		CALL arrJmj_TrantypeList.append([recJmj_Trantype.trans_code, recJmj_Trantype.desc_text])
	END WHILE	

	END IF
	
	IF arrJmj_TrantypeList.getSize() = 0 THEN
		ERROR "No jmj_trantype's found with the specified filter criteria"
	END IF
	
	RETURN arrJmj_TrantypeList
END FUNCTION	

########################################################################################
# FUNCTION Jmj_TrantypeLookupSearchDataSource(pRecJmj_TrantypeFilter)
#-------------------------------------------------------
# CALLS Jmj_TrantypeLookupSearchDataSourceCursor(pRecJmj_TrantypeFilter) with the Jmj_TrantypeFilter data TO get a CURSOR
# Returns the Jmj_Trantype list array arrJmj_TrantypeList
########################################################################################
FUNCTION Jmj_TrantypeLookupSearchDataSource(p_recJmj_TrantypeSearch)
	DEFINE p_recJmj_TrantypeSearch OF t_recJmj_TrantypeSearch	
	DEFINE recJmj_Trantype OF t_recJmj_Trantype
	DEFINE arrJmj_TrantypeList DYNAMIC ARRAY OF t_recJmj_Trantype 
	DEFINE c_Jmj_Trantype CURSOR
	DEFINE retError SMALLINT	
	CALL Jmj_TrantypeLookupSearchDataSourceCursor(p_recJmj_TrantypeSearch) RETURNING c_Jmj_Trantype
	
	CALL arrJmj_TrantypeList.CLEAR()

	CALL c_Jmj_Trantype.SetResults(recJmj_Trantype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Jmj_Trantype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Jmj_Trantype.FetchNext()=0)
		CALL arrJmj_TrantypeList.append([recJmj_Trantype.trans_code, recJmj_Trantype.desc_text])
	END WHILE	

	END IF
	
	IF arrJmj_TrantypeList.getSize() = 0 THEN
		ERROR "No jmj_trantype's found with the specified filter criteria"
	END IF
	
	RETURN arrJmj_TrantypeList
END FUNCTION


########################################################################################
# FUNCTION jmj_trantypeLookup_filter(pJmj_TrantypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Jmj_Trantype code trans_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Jmj_Trantype Code trans_code
#
# Example:
# 			LET pr_Jmj_Trantype.trans_code = Jmj_TrantypeLookup(pr_Jmj_Trantype.trans_code)
########################################################################################
FUNCTION jmj_trantypeLookup_filter(pJmj_TrantypeCode)
	DEFINE pJmj_TrantypeCode LIKE Jmj_Trantype.trans_code
	DEFINE arrJmj_TrantypeList DYNAMIC ARRAY OF t_recJmj_Trantype
	DEFINE recJmj_TrantypeFilter OF t_recJmj_TrantypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wJmj_TrantypeLookup WITH FORM "Jmj_TrantypeLookup_filter"


	CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recJmj_TrantypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrJmj_TrantypeList TO scJmj_TrantypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pJmj_TrantypeCode = arrJmj_TrantypeList[idx].trans_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recJmj_TrantypeFilter.filter_trans_code IS NOT NULL
			OR recJmj_TrantypeFilter.filter_desc_text IS NOT NULL

		THEN
			LET recJmj_TrantypeFilter.filter_trans_code = NULL
			LET recJmj_TrantypeFilter.filter_desc_text = NULL

			CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_trans_code"
		IF recJmj_TrantypeFilter.filter_trans_code IS NOT NULL THEN
			LET recJmj_TrantypeFilter.filter_trans_code = NULL
			CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recJmj_TrantypeFilter.filter_desc_text IS NOT NULL THEN
			LET recJmj_TrantypeFilter.filter_desc_text = NULL
			CALL Jmj_TrantypeLookupFilterDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wJmj_TrantypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pJmj_TrantypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION jmj_trantypeLookup(pJmj_TrantypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Jmj_Trantype code trans_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL Jmj_TrantypeLookupSearchDataSource(recJmj_TrantypeFilter.*) RETURNING arrJmj_TrantypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Jmj_Trantype Code trans_code
#
# Example:
# 			LET pr_Jmj_Trantype.trans_code = Jmj_TrantypeLookup(pr_Jmj_Trantype.trans_code)
########################################################################################
FUNCTION jmj_trantypeLookup(pJmj_TrantypeCode)
	DEFINE pJmj_TrantypeCode LIKE Jmj_Trantype.trans_code
	DEFINE arrJmj_TrantypeList DYNAMIC ARRAY OF t_recJmj_Trantype
	DEFINE recJmj_TrantypeSearch OF t_recJmj_TrantypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wJmj_TrantypeLookup WITH FORM "jmj_trantypeLookup"

	CALL Jmj_TrantypeLookupSearchDataSource(recJmj_TrantypeSearch.*) RETURNING arrJmj_TrantypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recJmj_TrantypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL Jmj_TrantypeLookupSearchDataSource(recJmj_TrantypeSearch.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrJmj_TrantypeList TO scJmj_TrantypeList.* 
		BEFORE ROW
			IF arrJmj_TrantypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pJmj_TrantypeCode = arrJmj_TrantypeList[idx].trans_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recJmj_TrantypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recJmj_TrantypeSearch.filter_any_field = NULL

			CALL Jmj_TrantypeLookupSearchDataSource(recJmj_TrantypeSearch.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_trans_code"
		IF recJmj_TrantypeSearch.filter_any_field IS NOT NULL THEN
			LET recJmj_TrantypeSearch.filter_any_field = NULL
			CALL Jmj_TrantypeLookupSearchDataSource(recJmj_TrantypeSearch.*) RETURNING arrJmj_TrantypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wJmj_TrantypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pJmj_TrantypeCode	
END FUNCTION				

############################################
# FUNCTION import_jmj_trantype()
############################################
FUNCTION import_jmj_trantype()
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
	
	DEFINE rec_jmj_trantype OF t_recJmj_Trantype_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wJmj_TrantypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Transaction Type List Data (table: jmj_trantype)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_jmj_trantype
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_jmj_trantype(
	    trans_code DECIMAL(2,0),
	    record_ind CHAR(1),
	    imprest_ind CHAR(1),
	    desc_text CHAR(30),
	    cr_acct_code CHAR(18),
	    db_acct_code CHAR(18),
	    debt_type_code CHAR(3)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_jmj_trantype	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wJmj_TrantypeImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wJmj_TrantypeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/jmj_trantype-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_jmj_trantype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_jmj_trantype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_jmj_trantype
			LET importReport = importReport, "Code:", trim(rec_jmj_trantype.trans_code) , "     -     Desc:", trim(rec_jmj_trantype.desc_text), "\n"
					
			INSERT INTO jmj_trantype VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_jmj_trantype.trans_code,
			rec_jmj_trantype.record_ind,
			rec_jmj_trantype.imprest_ind,
			rec_jmj_trantype.desc_text,
			rec_jmj_trantype.cr_acct_code,
			rec_jmj_trantype.db_acct_code,
			rec_jmj_trantype.debt_type_code			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_jmj_trantype.trans_code) , "     -     Desc:", trim(rec_jmj_trantype.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wJmj_TrantypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_jmj_trantypeRec(p_cmpy_code, p_trans_code)
########################################################
FUNCTION exist_jmj_trantypeRec(p_cmpy_code, p_trans_code)
	DEFINE p_cmpy_code LIKE jmj_trantype.cmpy_code
	DEFINE p_trans_code LIKE jmj_trantype.trans_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM jmj_trantype 
     WHERE cmpy_code = p_cmpy_code
     AND trans_code = p_trans_code

	DROP TABLE temp_jmj_trantype
	CLOSE WINDOW wJmj_TrantypeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_jmj_trantype()
###############################################################
FUNCTION unload_jmj_trantype(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/jmj_trantype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM jmj_trantype ORDER BY cmpy_code, trans_code ASC
	
	LET tmpMsg = "All jmj_trantype data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("jmj_trantype Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_jmj_trantype_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_jmj_trantype_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE jmj_trantype.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wjmj_trantypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "jmj_trantype Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing jmj_trantype table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM jmj_trantype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table jmj_trantype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table jmj_trantype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wJmj_TrantypeImport		
END FUNCTION	