GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getTermCount()
# FUNCTION termLookupFilterDataSourceCursor(pRecTermFilter)
# FUNCTION termLookupSearchDataSourceCursor(p_RecTermSearch)
# FUNCTION TermLookupFilterDataSource(pRecTermFilter)
# FUNCTION termLookup_filter(pTermCode)
# FUNCTION import_term()
# FUNCTION exist_termRec(p_cmpy_code, p_term_code)
# FUNCTION delete_term_all()
# FUNCTION termMenu()						-- Offer different OPTIONS of this library via a menu

# Term record types
	DEFINE t_recTerm  
		TYPE AS RECORD
			term_code LIKE term.term_code,
			desc_text LIKE term.desc_text
		END RECORD 

	DEFINE t_recTermFilter  
		TYPE AS RECORD
			filter_term_code LIKE term.term_code,
			filter_desc_text LIKE term.desc_text
		END RECORD 

	DEFINE t_recTermSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recTerm_noCmpyId 
		TYPE AS RECORD 
    term_code CHAR(3),
    desc_text CHAR(40),
    day_date_ind CHAR(1),
    due_day_num SMALLINT,
    disc_day_num SMALLINT,
    disc_per DECIMAL(6,3)
	END RECORD	

	
########################################################################################
# FUNCTION termMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION termMenu()
	MENU
		ON ACTION "Import"
			CALL import_term()
		ON ACTION "Export"
			CALL unload_term()
		#ON ACTION "Import"
		#	CALL import_term()
		ON ACTION "Delete All"
			CALL delete_term_all()
		ON ACTION "Count"
			CALL getTermCount() --Count all term rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getTermCount()
#-------------------------------------------------------
# Returns the number of Term entries for the current company
########################################################################################
FUNCTION getTermCount()
	DEFINE ret_TermCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Term CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Term ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Term.DECLARE(sqlQuery) #CURSOR FOR getTerm
	CALL c_Term.SetResults(ret_TermCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Term.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_TermCount = -1
	ELSE
		CALL c_Term.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Term(s):", trim(ret_TermCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Term Count", tempMsg,"info") 	
	END IF

	RETURN ret_TermCount
END FUNCTION

########################################################################################
# FUNCTION termLookupFilterDataSourceCursor(pRecTermFilter)
#-------------------------------------------------------
# Returns the Term CURSOR for the lookup query
########################################################################################
FUNCTION termLookupFilterDataSourceCursor(pRecTermFilter)
	DEFINE pRecTermFilter OF t_recTermFilter
	DEFINE sqlQuery STRING
	DEFINE c_Term CURSOR
	
	LET sqlQuery =	"SELECT ",
									"term.term_code, ", 
									"term.desc_text ",
									"FROM term ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecTermFilter.filter_term_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND term_code LIKE '", pRecTermFilter.filter_term_code CLIPPED, "%' "  
	END IF									

	IF pRecTermFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecTermFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY term_code"

	CALL c_term.DECLARE(sqlQuery)
		
	RETURN c_term
END FUNCTION



########################################################################################
# termLookupSearchDataSourceCursor(p_RecTermSearch)
#-------------------------------------------------------
# Returns the Term CURSOR for the lookup query
########################################################################################
FUNCTION termLookupSearchDataSourceCursor(p_RecTermSearch)
	DEFINE p_RecTermSearch OF t_recTermSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Term CURSOR
	
	LET sqlQuery =	"SELECT ",
									"term.term_code, ", 
									"term.desc_text ",
 
									"FROM term ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecTermSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((term_code LIKE '", p_RecTermSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecTermSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecTermSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY term_code"

	CALL c_term.DECLARE(sqlQuery) #CURSOR FOR term
	
	RETURN c_term
END FUNCTION


########################################################################################
# FUNCTION TermLookupFilterDataSource(pRecTermFilter)
#-------------------------------------------------------
# CALLS TermLookupFilterDataSourceCursor(pRecTermFilter) with the TermFilter data TO get a CURSOR
# Returns the Term list array arrTermList
########################################################################################
FUNCTION TermLookupFilterDataSource(pRecTermFilter)
	DEFINE pRecTermFilter OF t_recTermFilter
	DEFINE recTerm OF t_recTerm
	DEFINE arrTermList DYNAMIC ARRAY OF t_recTerm 
	DEFINE c_Term CURSOR
	DEFINE retError SMALLINT
		
	CALL TermLookupFilterDataSourceCursor(pRecTermFilter.*) RETURNING c_Term
	
	CALL arrTermList.CLEAR()

	CALL c_Term.SetResults(recTerm.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Term.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Term.FetchNext()=0)
		CALL arrTermList.append([recTerm.term_code, recTerm.desc_text])
	END WHILE	

	END IF
	
	IF arrTermList.getSize() = 0 THEN
		ERROR "No Term's found with the specified filter criteria"
	END IF
	
	RETURN arrTermList
END FUNCTION	

########################################################################################
# FUNCTION TermLookupSearchDataSource(pRecTermFilter)
#-------------------------------------------------------
# CALLS TermLookupSearchDataSourceCursor(pRecTermFilter) with the TermFilter data TO get a CURSOR
# Returns the Term list array arrTermList
########################################################################################
FUNCTION TermLookupSearchDataSource(p_recTermSearch)
	DEFINE p_recTermSearch OF t_recTermSearch	
	DEFINE recTerm OF t_recTerm
	DEFINE arrTermList DYNAMIC ARRAY OF t_recTerm 
	DEFINE c_Term CURSOR
	DEFINE retError SMALLINT	
	CALL TermLookupSearchDataSourceCursor(p_recTermSearch) RETURNING c_Term
	
	CALL arrTermList.CLEAR()

	CALL c_Term.SetResults(recTerm.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Term.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Term.FetchNext()=0)
		CALL arrTermList.append([recTerm.term_code, recTerm.desc_text])
	END WHILE	

	END IF
	
	IF arrTermList.getSize() = 0 THEN
		ERROR "No Term's found with the specified filter criteria"
	END IF
	
	RETURN arrTermList
END FUNCTION


########################################################################################
# FUNCTION termLookup_filter(pTermCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Term code term_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Term Code term_code
#
# Example:
# 			LET pr_Term.term_code = TermLookup(pr_Term.term_code)
########################################################################################
FUNCTION termLookup_filter(pTermCode)
	DEFINE pTermCode LIKE Term.term_code
	DEFINE arrTermList DYNAMIC ARRAY OF t_recTerm
	DEFINE recTermFilter OF t_recTermFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTermLookup WITH FORM "TermLookup_filter"


	CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTermFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTermList TO scTermList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTermCode = arrTermList[idx].term_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTermFilter.filter_term_code IS NOT NULL
			OR recTermFilter.filter_desc_text IS NOT NULL

		THEN
			LET recTermFilter.filter_term_code = NULL
			LET recTermFilter.filter_desc_text = NULL

			CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_term_code"
		IF recTermFilter.filter_term_code IS NOT NULL THEN
			LET recTermFilter.filter_term_code = NULL
			CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recTermFilter.filter_desc_text IS NOT NULL THEN
			LET recTermFilter.filter_desc_text = NULL
			CALL TermLookupFilterDataSource(recTermFilter.*) RETURNING arrTermList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTermLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTermCode	
END FUNCTION				
		

########################################################################################
# FUNCTION termLookup(pTermCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Term code term_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL TermLookupSearchDataSource(recTermFilter.*) RETURNING arrTermList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Term Code term_code
#
# Example:
# 			LET pr_Term.term_code = TermLookup(pr_Term.term_code)
########################################################################################
FUNCTION termLookup(pTermCode)
	DEFINE pTermCode LIKE Term.term_code
	DEFINE arrTermList DYNAMIC ARRAY OF t_recTerm
	DEFINE recTermSearch OF t_recTermSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wTermLookup WITH FORM "termLookup"

	CALL TermLookupSearchDataSource(recTermSearch.*) RETURNING arrTermList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recTermSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL TermLookupSearchDataSource(recTermSearch.*) RETURNING arrTermList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrTermList TO scTermList.* 
		BEFORE ROW
			IF arrTermList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pTermCode = arrTermList[idx].term_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recTermSearch.filter_any_field IS NOT NULL

		THEN
			LET recTermSearch.filter_any_field = NULL

			CALL TermLookupSearchDataSource(recTermSearch.*) RETURNING arrTermList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_term_code"
		IF recTermSearch.filter_any_field IS NOT NULL THEN
			LET recTermSearch.filter_any_field = NULL
			CALL TermLookupSearchDataSource(recTermSearch.*) RETURNING arrTermList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wTermLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pTermCode	
END FUNCTION				

############################################
# FUNCTION import_term()
############################################
FUNCTION import_term()
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
	
	DEFINE rec_term OF t_recTerm_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wTermImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Term List Data (table: term)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_term
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_term(
		term_code CHAR(3),
    desc_text CHAR(40),
    day_date_ind CHAR(1),
    due_day_num SMALLINT,
    disc_day_num SMALLINT,
    disc_per DECIMAL(6,3)
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_term	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wTermImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wTermImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/term-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_term
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_term
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_term
			LET importReport = importReport, "Code:", trim(rec_term.term_code) , "     -     Desc:", trim(rec_term.desc_text), "\n"
					
			INSERT INTO term VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_term.term_code,
			rec_term.desc_text,
			rec_term.day_date_ind,
			rec_term.due_day_num,
			rec_term.disc_day_num,
			rec_term.disc_per
  	
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_term.term_code) , "     -     Desc:", trim(rec_term.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wTermImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_termRec(p_cmpy_code, p_term_code)
########################################################
FUNCTION exist_termRec(p_cmpy_code, p_term_code)
	DEFINE p_cmpy_code LIKE term.cmpy_code
	DEFINE p_term_code LIKE term.term_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM term 
     WHERE cmpy_code = p_cmpy_code
     AND term_code = p_term_code

	DROP TABLE temp_term
	CLOSE WINDOW wTermImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_term()
###############################################################
FUNCTION unload_term(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/term-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM term ORDER BY cmpy_code, term_code ASC
	
	LET tmpMsg = "All term data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("term Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_term_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_term_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE term.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wtermImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "term Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM term
		WHENEVER ERROR STOP
	END IF	

		
	IF sqlca.sqlcode <> 0 THEN
		LET tmpMsg = "Error when trying TO delete all data in the table term!"
			CALL fgl_winmessage("Error",tmpMsg,"error")
	ELSE
		IF p_silentMode = 0 THEN --no ui
			LET tmpMsg = "All data in the table term where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")
		END IF					
	END IF		


	CLOSE WINDOW wtermImport		
END FUNCTION	