GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getRecurHeadCount()
# FUNCTION recurheadLookupFilterDataSourceCursor(pRecRecurHeadFilter)
# FUNCTION recurheadLookupSearchDataSourceCursor(p_RecRecurHeadSearch)
# FUNCTION RecurHeadLookupFilterDataSource(pRecRecurHeadFilter)
# FUNCTION recurheadLookup_filter(pRecurHeadCode)
# FUNCTION import_recurhead()
# FUNCTION exist_recurheadRec(p_cmpy_code, p_recur_code)
# FUNCTION delete_recurhead_all()
# FUNCTION recurheadGroupMenu()						-- Offer different OPTIONS of this library via a menu

# RecurHead record types
	DEFINE t_recRecurHead  
		TYPE AS RECORD
			recur_code LIKE recurhead.recur_code,
			desc_text LIKE recurhead.desc_text
		END RECORD 

	DEFINE t_recRecurHeadFilter  
		TYPE AS RECORD
			filter_recur_code LIKE recurhead.recur_code,
			filter_desc_text LIKE recurhead.desc_text
		END RECORD 

	DEFINE t_recRecurHeadSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recRecurHead_noCmpyId 
		TYPE AS RECORD 
    recur_code LIKE recurhead.recur_code,
    desc_text LIKE recurhead.desc_text,
    vend_code LIKE recurhead.vend_code,
    inv_text LIKE recurhead.inv_text,
    term_code LIKE recurhead.term_code,
    tax_code LIKE recurhead.tax_code,
    start_date LIKE recurhead.start_date,
    end_date LIKE recurhead.end_date,
    int_ind LIKE recurhead.int_ind,
    int_num LIKE recurhead.int_num,
    hold_code LIKE recurhead.hold_code,
    group_text LIKE recurhead.group_text,
    goods_amt LIKE recurhead.goods_amt,
    tax_amt LIKE recurhead.tax_amt,
    total_amt LIKE recurhead.total_amt,
    dist_amt LIKE recurhead.dist_amt,
    dist_qty LIKE recurhead.dist_qty,
    curr_code LIKE recurhead.curr_code,
    conv_qty LIKE recurhead.conv_qty,
    run_date LIKE recurhead.run_date,
    run_code LIKE recurhead.run_code,
    run_num LIKE recurhead.run_num,
    max_run_num LIKE recurhead.max_run_num,
    last_vouch_code LIKE recurhead.last_vouch_code,
    last_vouch_date LIKE recurhead.last_vouch_date,
    last_year_num LIKE recurhead.last_year_num,
    last_period_num LIKE recurhead.last_period_num,
    next_vouch_date LIKE recurhead.next_vouch_date,
    next_due_date LIKE recurhead.next_due_date,
    rev_num LIKE recurhead.rev_num,
    rev_date LIKE recurhead.rev_date,
    rev_code LIKE recurhead.rev_code,
    line_num LIKE recurhead.line_num,
    com1_text LIKE recurhead.com1_text
	END RECORD	

	
########################################################################################
# FUNCTION recurheadMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION recurHeadMenu()
	MENU
		ON ACTION "Import"
			CALL import_recurhead()
		ON ACTION "Export"
			CALL unload_recurhead()
		#ON ACTION "Import"
		#	CALL import_recurhead()
		ON ACTION "Delete All"
			CALL delete_recurhead_all()
		ON ACTION "Count"
			CALL getRecurHeadCount() --Count all recurhead rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getRecurHeadCount()
#-------------------------------------------------------
# Returns the number of RecurHead entries for the current company
########################################################################################
FUNCTION getRecurHeadCount()
	DEFINE ret_RecurHeadCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_RecurHead CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM recurhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_RecurHead.DECLARE(sqlQuery) #CURSOR FOR getRecurHead
	CALL c_RecurHead.SetResults(ret_RecurHeadCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_RecurHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_RecurHeadCount = -1
	ELSE
		CALL c_RecurHead.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of recurhead:", trim(ret_RecurHeadCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("recurhead Count", tempMsg,"info") 	
	END IF

	RETURN ret_RecurHeadCount
END FUNCTION

########################################################################################
# FUNCTION recurheadLookupFilterDataSourceCursor(pRecRecurHeadFilter)
#-------------------------------------------------------
# Returns the RecurHead CURSOR for the lookup query
########################################################################################
FUNCTION recurheadLookupFilterDataSourceCursor(pRecRecurHeadFilter)
	DEFINE pRecRecurHeadFilter OF t_recRecurHeadFilter
	DEFINE sqlQuery STRING
	DEFINE c_RecurHead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"recurhead.recur_code, ", 
									"recurhead.desc_text ",
									"FROM recurhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecRecurHeadFilter.filter_recur_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND recur_code LIKE '", pRecRecurHeadFilter.filter_recur_code CLIPPED, "%' "  
	END IF									

	IF pRecRecurHeadFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecRecurHeadFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY recur_code"

	CALL c_recurhead.DECLARE(sqlQuery)
		
	RETURN c_recurhead
END FUNCTION



########################################################################################
# recurheadLookupSearchDataSourceCursor(p_RecRecurHeadSearch)
#-------------------------------------------------------
# Returns the RecurHead CURSOR for the lookup query
########################################################################################
FUNCTION recurheadLookupSearchDataSourceCursor(p_RecRecurHeadSearch)
	DEFINE p_RecRecurHeadSearch OF t_recRecurHeadSearch  
	DEFINE sqlQuery STRING
	DEFINE c_RecurHead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"recurhead.recur_code, ", 
									"recurhead.desc_text ",
 
									"FROM recurhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecRecurHeadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((recur_code LIKE '", p_RecRecurHeadSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecRecurHeadSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecRecurHeadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY recur_code"

	CALL c_recurhead.DECLARE(sqlQuery) #CURSOR FOR recurhead
	
	RETURN c_recurhead
END FUNCTION


########################################################################################
# FUNCTION RecurHeadLookupFilterDataSource(pRecRecurHeadFilter)
#-------------------------------------------------------
# CALLS RecurHeadLookupFilterDataSourceCursor(pRecRecurHeadFilter) with the RecurHeadFilter data TO get a CURSOR
# Returns the RecurHead list array arrRecurHeadList
########################################################################################
FUNCTION RecurHeadLookupFilterDataSource(pRecRecurHeadFilter)
	DEFINE pRecRecurHeadFilter OF t_recRecurHeadFilter
	DEFINE recRecurHead OF t_recRecurHead
	DEFINE arrRecurHeadList DYNAMIC ARRAY OF t_recRecurHead 
	DEFINE c_RecurHead CURSOR
	DEFINE retError SMALLINT
		
	CALL RecurHeadLookupFilterDataSourceCursor(pRecRecurHeadFilter.*) RETURNING c_RecurHead
	
	CALL arrRecurHeadList.CLEAR()

	CALL c_RecurHead.SetResults(recRecurHead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_RecurHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_RecurHead.FetchNext()=0)
		CALL arrRecurHeadList.append([recRecurHead.recur_code, recRecurHead.desc_text])
	END WHILE	

	END IF
	
	IF arrRecurHeadList.getSize() = 0 THEN
		ERROR "No recurhead's found with the specified filter criteria"
	END IF
	
	RETURN arrRecurHeadList
END FUNCTION	

########################################################################################
# FUNCTION RecurHeadLookupSearchDataSource(pRecRecurHeadFilter)
#-------------------------------------------------------
# CALLS RecurHeadLookupSearchDataSourceCursor(pRecRecurHeadFilter) with the RecurHeadFilter data TO get a CURSOR
# Returns the RecurHead list array arrRecurHeadList
########################################################################################
FUNCTION RecurHeadLookupSearchDataSource(p_recRecurHeadSearch)
	DEFINE p_recRecurHeadSearch OF t_recRecurHeadSearch	
	DEFINE recRecurHead OF t_recRecurHead
	DEFINE arrRecurHeadList DYNAMIC ARRAY OF t_recRecurHead 
	DEFINE c_RecurHead CURSOR
	DEFINE retError SMALLINT	
	CALL RecurHeadLookupSearchDataSourceCursor(p_recRecurHeadSearch) RETURNING c_RecurHead
	
	CALL arrRecurHeadList.CLEAR()

	CALL c_RecurHead.SetResults(recRecurHead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_RecurHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_RecurHead.FetchNext()=0)
		CALL arrRecurHeadList.append([recRecurHead.recur_code, recRecurHead.desc_text])
	END WHILE	

	END IF
	
	IF arrRecurHeadList.getSize() = 0 THEN
		ERROR "No recurhead's found with the specified filter criteria"
	END IF
	
	RETURN arrRecurHeadList
END FUNCTION


########################################################################################
# FUNCTION recurheadLookup_filter(pRecurHeadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required RecurHead code recur_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the RecurHead Code recur_code
#
# Example:
# 			LET pr_RecurHead.recur_code = RecurHeadLookup(pr_RecurHead.recur_code)
########################################################################################
FUNCTION recurheadLookup_filter(pRecurHeadCode)
	DEFINE pRecurHeadCode LIKE RecurHead.recur_code
	DEFINE arrRecurHeadList DYNAMIC ARRAY OF t_recRecurHead
	DEFINE recRecurHeadFilter OF t_recRecurHeadFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRecurHeadLookup WITH FORM "RecurHeadLookup_filter"


	CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRecurHeadFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRecurHeadList TO scRecurHeadList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRecurHeadCode = arrRecurHeadList[idx].recur_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRecurHeadFilter.filter_recur_code IS NOT NULL
			OR recRecurHeadFilter.filter_desc_text IS NOT NULL

		THEN
			LET recRecurHeadFilter.filter_recur_code = NULL
			LET recRecurHeadFilter.filter_desc_text = NULL

			CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_recur_code"
		IF recRecurHeadFilter.filter_recur_code IS NOT NULL THEN
			LET recRecurHeadFilter.filter_recur_code = NULL
			CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recRecurHeadFilter.filter_desc_text IS NOT NULL THEN
			LET recRecurHeadFilter.filter_desc_text = NULL
			CALL RecurHeadLookupFilterDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRecurHeadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRecurHeadCode	
END FUNCTION				
		

########################################################################################
# FUNCTION recurheadLookup(pRecurHeadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required RecurHead code recur_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL RecurHeadLookupSearchDataSource(recRecurHeadFilter.*) RETURNING arrRecurHeadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the RecurHead Code recur_code
#
# Example:
# 			LET pr_RecurHead.recur_code = RecurHeadLookup(pr_RecurHead.recur_code)
########################################################################################
FUNCTION recurheadLookup(pRecurHeadCode)
	DEFINE pRecurHeadCode LIKE RecurHead.recur_code
	DEFINE arrRecurHeadList DYNAMIC ARRAY OF t_recRecurHead
	DEFINE recRecurHeadSearch OF t_recRecurHeadSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRecurHeadLookup WITH FORM "recurheadLookup"

	CALL RecurHeadLookupSearchDataSource(recRecurHeadSearch.*) RETURNING arrRecurHeadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRecurHeadSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL RecurHeadLookupSearchDataSource(recRecurHeadSearch.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRecurHeadList TO scRecurHeadList.* 
		BEFORE ROW
			IF arrRecurHeadList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRecurHeadCode = arrRecurHeadList[idx].recur_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRecurHeadSearch.filter_any_field IS NOT NULL

		THEN
			LET recRecurHeadSearch.filter_any_field = NULL

			CALL RecurHeadLookupSearchDataSource(recRecurHeadSearch.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_recur_code"
		IF recRecurHeadSearch.filter_any_field IS NOT NULL THEN
			LET recRecurHeadSearch.filter_any_field = NULL
			CALL RecurHeadLookupSearchDataSource(recRecurHeadSearch.*) RETURNING arrRecurHeadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRecurHeadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRecurHeadCode	
END FUNCTION				

############################################
# FUNCTION import_recurhead()
############################################
FUNCTION import_recurhead()
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
	
	DEFINE rec_recurhead OF t_recRecurHead_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wRecurHeadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import recurhead List Data (table: recurhead)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_recurhead
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_recurhead(
	    recur_code CHAR(8),
	    desc_text CHAR(30),
	    vend_code CHAR(8),
	    inv_text CHAR(20),
	    term_code CHAR(3),
	    tax_code CHAR(3),
	    start_date DATE,
	    end_date DATE,
	    int_ind CHAR(1),
	    int_num SMALLINT,
	    hold_code CHAR(2),
	    group_text CHAR(8),
	    goods_amt DECIMAL(16,2),
	    tax_amt DECIMAL(16,2),
	    total_amt DECIMAL(16,2),
	    dist_amt DECIMAL(16,2),
	    dist_qty float,
	    curr_code CHAR(3),
	    conv_qty float,
	    run_date DATE,
	    run_code CHAR(8),
	    run_num SMALLINT,
	    max_run_num SMALLINT,
	    last_vouch_code INTEGER,
	    last_vouch_date DATE,
	    last_year_num SMALLINT,
	    last_period_num SMALLINT,
	    next_vouch_date DATE,
	    next_due_date DATE,
	    rev_num SMALLINT,
	    rev_date DATE,
	    rev_code CHAR(8),
	    line_num SMALLINT,
	    com1_text CHAR(60)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_recurhead	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wRecurHeadImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wRecurHeadImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/recurhead-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_recurhead
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_recurhead
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_recurhead
			LET importReport = importReport, "Code:", trim(rec_recurhead.recur_code) , "     -     Desc:", trim(rec_recurhead.desc_text), "\n"
					
			INSERT INTO recurhead VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_recurhead.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_recurhead.recur_code) , "     -     Desc:", trim(rec_recurhead.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wRecurHeadImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_recurheadRec(p_cmpy_code, p_recur_code)
########################################################
FUNCTION exist_recurheadRec(p_cmpy_code, p_recur_code)
	DEFINE p_cmpy_code LIKE recurhead.cmpy_code
	DEFINE p_recur_code LIKE recurhead.recur_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM recurhead 
     WHERE cmpy_code = p_cmpy_code
     AND recur_code = p_recur_code

	DROP TABLE temp_recurhead
	CLOSE WINDOW wRecurHeadImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_recurhead()
###############################################################
FUNCTION unload_recurhead(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/recurhead-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM recurhead ORDER BY cmpy_code, recur_code ASC
	
	LET tmpMsg = "All recurhead data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("recurhead Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_recurhead_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_recurhead_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE recurhead.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wrecurheadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Vendor recurhead Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing recurhead table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM recurhead
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table recurhead!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table recurhead where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wRecurHeadImport		
END FUNCTION	