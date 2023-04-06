GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getDebitHeadCount()
# FUNCTION debitheadLookupFilterDataSourceCursor(pRecDebitHeadFilter)
# FUNCTION debitheadLookupSearchDataSourceCursor(p_RecDebitHeadSearch)
# FUNCTION DebitHeadLookupFilterDataSource(pRecDebitHeadFilter)
# FUNCTION debitheadLookup_filter(pDebitHeadCode)
# FUNCTION import_debithead()
# FUNCTION exist_debitheadRec(p_cmpy_code, p_debit_num)
# FUNCTION delete_debithead_all()
# FUNCTION debitHeadMenu()						-- Offer different OPTIONS of this library via a menu

# DebitHead record types
	DEFINE t_recDebitHead  
		TYPE AS RECORD
			debit_num LIKE debithead.debit_num,
			debit_text LIKE debithead.debit_text
		END RECORD 

	DEFINE t_recDebitHeadFilter  
		TYPE AS RECORD
			filter_debit_num LIKE debithead.debit_num,
			filter_debit_text LIKE debithead.debit_text
		END RECORD 

	DEFINE t_recDebitHeadSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recDebitHead_noCmpyId 
		TYPE AS RECORD 
    vend_code LIKE debithead.vend_code,
    debit_num LIKE debithead.debit_num,
    debit_text LIKE debithead.debit_text,
    rma_num LIKE debithead.rma_num,
    debit_date LIKE debithead.debit_date,
    entry_code LIKE debithead.entry_code,
    entry_date LIKE debithead.entry_date,
    contact_text LIKE debithead.contact_text,
    tax_code LIKE debithead.tax_code,
    goods_amt LIKE debithead.goods_amt,
    tax_amt LIKE debithead.tax_amt,
    total_amt LIKE debithead.total_amt,
    dist_qty LIKE debithead.dist_qty,
    dist_amt LIKE debithead.dist_amt,
    apply_amt LIKE debithead.apply_amt,
    disc_amt LIKE debithead.disc_amt,
    hist_flag LIKE debithead.hist_flag,
    jour_num LIKE debithead.jour_num,
    post_flag LIKE debithead.post_flag,
    year_num LIKE debithead.year_num,
    period_num LIKE debithead.period_num,
    appl_seq_num LIKE debithead.appl_seq_num,
    com1_text LIKE debithead.com1_text,
    com2_text LIKE debithead.com2_text,
    currency_code LIKE debithead.currency_code,
    conv_qty LIKE debithead.conv_qty,
    post_date LIKE debithead.post_date,
    batch_num LIKE debithead.batch_num
	END RECORD	

	
########################################################################################
# FUNCTION debitHeadMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION debitHeadMenu()
	MENU
		ON ACTION "Import"
			CALL import_debithead()
		ON ACTION "Export"
			CALL unload_debithead()
		#ON ACTION "Import"
		#	CALL import_debithead()
		ON ACTION "Delete All"
			CALL delete_debithead_all()
		ON ACTION "Count"
			CALL getDebitHeadCount() --Count all debithead rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getDebitHeadCount()
#-------------------------------------------------------
# Returns the number of DebitHead entries for the current company
########################################################################################
FUNCTION getDebitHeadCount()
	DEFINE ret_DebitHeadCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_DebitHead CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM DebitHead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_DebitHead.DECLARE(sqlQuery) #CURSOR FOR getDebitHead
	CALL c_DebitHead.SetResults(ret_DebitHeadCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_DebitHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_DebitHeadCount = -1
	ELSE
		CALL c_DebitHead.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Debits:", trim(ret_DebitHeadCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Debit Head Count", tempMsg,"info") 	
	END IF

	RETURN ret_DebitHeadCount
END FUNCTION

########################################################################################
# FUNCTION debitheadLookupFilterDataSourceCursor(pRecDebitHeadFilter)
#-------------------------------------------------------
# Returns the DebitHead CURSOR for the lookup query
########################################################################################
FUNCTION debitheadLookupFilterDataSourceCursor(pRecDebitHeadFilter)
	DEFINE pRecDebitHeadFilter OF t_recDebitHeadFilter
	DEFINE sqlQuery STRING
	DEFINE c_DebitHead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"debithead.debit_num, ", 
									"debithead.debit_text ",
									"FROM debithead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecDebitHeadFilter.filter_debit_num IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND debit_num LIKE '", pRecDebitHeadFilter.filter_debit_num CLIPPED, "%' "  
	END IF									

	IF pRecDebitHeadFilter.filter_debit_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND debit_text LIKE '", pRecDebitHeadFilter.filter_debit_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY debit_num"

	CALL c_debithead.DECLARE(sqlQuery)
		
	RETURN c_debithead
END FUNCTION



########################################################################################
# debitheadLookupSearchDataSourceCursor(p_RecDebitHeadSearch)
#-------------------------------------------------------
# Returns the DebitHead CURSOR for the lookup query
########################################################################################
FUNCTION debitheadLookupSearchDataSourceCursor(p_RecDebitHeadSearch)
	DEFINE p_RecDebitHeadSearch OF t_recDebitHeadSearch  
	DEFINE sqlQuery STRING
	DEFINE c_DebitHead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"debithead.debit_num, ", 
									"debithead.debit_text ",
 
									"FROM debithead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecDebitHeadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((debit_num LIKE '", p_RecDebitHeadSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR debit_text LIKE '",   p_RecDebitHeadSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecDebitHeadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY debit_num"

	CALL c_debithead.DECLARE(sqlQuery) #CURSOR FOR debithead
	
	RETURN c_debithead
END FUNCTION


########################################################################################
# FUNCTION DebitHeadLookupFilterDataSource(pRecDebitHeadFilter)
#-------------------------------------------------------
# CALLS DebitHeadLookupFilterDataSourceCursor(pRecDebitHeadFilter) with the DebitHeadFilter data TO get a CURSOR
# Returns the DebitHead list array arrDebitHeadList
########################################################################################
FUNCTION DebitHeadLookupFilterDataSource(pRecDebitHeadFilter)
	DEFINE pRecDebitHeadFilter OF t_recDebitHeadFilter
	DEFINE recDebitHead OF t_recDebitHead
	DEFINE arrDebitHeadList DYNAMIC ARRAY OF t_recDebitHead 
	DEFINE c_DebitHead CURSOR
	DEFINE retError SMALLINT
		
	CALL DebitHeadLookupFilterDataSourceCursor(pRecDebitHeadFilter.*) RETURNING c_DebitHead
	
	CALL arrDebitHeadList.CLEAR()

	CALL c_DebitHead.SetResults(recDebitHead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_DebitHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_DebitHead.FetchNext()=0)
		CALL arrDebitHeadList.append([recDebitHead.debit_num, recDebitHead.debit_text])
	END WHILE	

	END IF
	
	IF arrDebitHeadList.getSize() = 0 THEN
		ERROR "No debithead's found with the specified filter criteria"
	END IF
	
	RETURN arrDebitHeadList
END FUNCTION	

########################################################################################
# FUNCTION DebitHeadLookupSearchDataSource(pRecDebitHeadFilter)
#-------------------------------------------------------
# CALLS DebitHeadLookupSearchDataSourceCursor(pRecDebitHeadFilter) with the DebitHeadFilter data TO get a CURSOR
# Returns the DebitHead list array arrDebitHeadList
########################################################################################
FUNCTION DebitHeadLookupSearchDataSource(p_recDebitHeadSearch)
	DEFINE p_recDebitHeadSearch OF t_recDebitHeadSearch	
	DEFINE recDebitHead OF t_recDebitHead
	DEFINE arrDebitHeadList DYNAMIC ARRAY OF t_recDebitHead 
	DEFINE c_DebitHead CURSOR
	DEFINE retError SMALLINT	
	CALL DebitHeadLookupSearchDataSourceCursor(p_recDebitHeadSearch) RETURNING c_DebitHead
	
	CALL arrDebitHeadList.CLEAR()

	CALL c_DebitHead.SetResults(recDebitHead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_DebitHead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_DebitHead.FetchNext()=0)
		CALL arrDebitHeadList.append([recDebitHead.debit_num, recDebitHead.debit_text])
	END WHILE	

	END IF
	
	IF arrDebitHeadList.getSize() = 0 THEN
		ERROR "No debithead's found with the specified filter criteria"
	END IF
	
	RETURN arrDebitHeadList
END FUNCTION


########################################################################################
# FUNCTION debitheadLookup_filter(pDebitHeadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required DebitHead code debit_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the DebitHead Code debit_num
#
# Example:
# 			LET pr_DebitHead.debit_num = DebitHeadLookup(pr_DebitHead.debit_num)
########################################################################################
FUNCTION debitheadLookup_filter(pDebitHeadCode)
	DEFINE pDebitHeadCode LIKE DebitHead.debit_num
	DEFINE arrDebitHeadList DYNAMIC ARRAY OF t_recDebitHead
	DEFINE recDebitHeadFilter OF t_recDebitHeadFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wDebitHeadLookup WITH FORM "DebitHeadLookup_filter"


	CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recDebitHeadFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrDebitHeadList TO scDebitHeadList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pDebitHeadCode = arrDebitHeadList[idx].debit_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recDebitHeadFilter.filter_debit_num IS NOT NULL
			OR recDebitHeadFilter.filter_debit_text IS NOT NULL

		THEN
			LET recDebitHeadFilter.filter_debit_num = NULL
			LET recDebitHeadFilter.filter_debit_text = NULL

			CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_debit_num"
		IF recDebitHeadFilter.filter_debit_num IS NOT NULL THEN
			LET recDebitHeadFilter.filter_debit_num = NULL
			CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_debit_text"
		IF recDebitHeadFilter.filter_debit_text IS NOT NULL THEN
			LET recDebitHeadFilter.filter_debit_text = NULL
			CALL DebitHeadLookupFilterDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wDebitHeadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pDebitHeadCode	
END FUNCTION				
		

########################################################################################
# FUNCTION debitheadLookup(pDebitHeadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required DebitHead code debit_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL DebitHeadLookupSearchDataSource(recDebitHeadFilter.*) RETURNING arrDebitHeadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the DebitHead Code debit_num
#
# Example:
# 			LET pr_DebitHead.debit_num = DebitHeadLookup(pr_DebitHead.debit_num)
########################################################################################
FUNCTION debitheadLookup(pDebitHeadCode)
	DEFINE pDebitHeadCode LIKE DebitHead.debit_num
	DEFINE arrDebitHeadList DYNAMIC ARRAY OF t_recDebitHead
	DEFINE recDebitHeadSearch OF t_recDebitHeadSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wDebitHeadLookup WITH FORM "debitheadLookup"

	CALL DebitHeadLookupSearchDataSource(recDebitHeadSearch.*) RETURNING arrDebitHeadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recDebitHeadSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL DebitHeadLookupSearchDataSource(recDebitHeadSearch.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrDebitHeadList TO scDebitHeadList.* 
		BEFORE ROW
			IF arrDebitHeadList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pDebitHeadCode = arrDebitHeadList[idx].debit_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recDebitHeadSearch.filter_any_field IS NOT NULL

		THEN
			LET recDebitHeadSearch.filter_any_field = NULL

			CALL DebitHeadLookupSearchDataSource(recDebitHeadSearch.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_debit_num"
		IF recDebitHeadSearch.filter_any_field IS NOT NULL THEN
			LET recDebitHeadSearch.filter_any_field = NULL
			CALL DebitHeadLookupSearchDataSource(recDebitHeadSearch.*) RETURNING arrDebitHeadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wDebitHeadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pDebitHeadCode	
END FUNCTION				

############################################
# FUNCTION import_debithead()
############################################
FUNCTION import_debithead()
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
	DEFINE p_debit_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_debithead OF t_recDebitHead_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wDebitHeadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Debit List Data (table: debithead)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_debithead
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_debithead(
    vend_code CHAR(8),
    debit_num INTEGER,
    debit_text CHAR(20),
    rma_num INTEGER,
    debit_date DATE,
    entry_code CHAR(8),
    entry_date DATE,
    contact_text CHAR(10),
    tax_code CHAR(3),
    goods_amt DECIMAL(16,2),
    tax_amt DECIMAL(16,2),
    total_amt DECIMAL(16,2),
    dist_qty float,
    dist_amt DECIMAL(16,2),
    apply_amt DECIMAL(16,2),
    disc_amt DECIMAL(16,2),
    hist_flag CHAR(1),
    jour_num INTEGER,
    post_flag CHAR(1),
    year_num SMALLINT,
    period_num SMALLINT,
    appl_seq_num SMALLINT,
    com1_text CHAR(30),
    com2_text CHAR(30),
    currency_code CHAR(3),
    conv_qty float,
    post_date DATE,
    batch_num INTEGER
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_debithead	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_debit_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wDebitHeadImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_debit_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_debit_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wDebitHeadImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/debithead-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_debithead
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_debithead
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_debithead
			LET importReport = importReport, "Code:", trim(rec_debithead.debit_num) , "     -     Desc:", trim(rec_debithead.debit_text), "\n"
					
			INSERT INTO debithead VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_debithead.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_debithead.debit_num) , "     -     Desc:", trim(rec_debithead.debit_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wDebitHeadImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_debitheadRec(p_cmpy_code, p_debit_num)
########################################################
FUNCTION exist_debitheadRec(p_cmpy_code, p_debit_num)
	DEFINE p_cmpy_code LIKE debithead.cmpy_code
	DEFINE p_debit_num LIKE debithead.debit_num
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM debithead 
     WHERE cmpy_code = p_cmpy_code
     AND debit_num = p_debit_num

	DROP TABLE temp_debithead
	CLOSE WINDOW wDebitHeadImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_debithead()
###############################################################
FUNCTION unload_debithead(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/debithead-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM debithead ORDER BY cmpy_code, debit_num ASC
	
	LET tmpMsg = "All debithead data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("debithead Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_debithead_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_debithead_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE debithead.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wdebitheadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "DebitHead List (debithead) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing debithead table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM debithead
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table debithead!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table debithead where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wDebitHeadImport		
END FUNCTION	