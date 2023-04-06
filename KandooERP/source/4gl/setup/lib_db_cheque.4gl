GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getChequeCount()
# FUNCTION chequeLookupFilterDataSourceCursor(pRecChequeFilter)
# FUNCTION chequeLookupSearchDataSourceCursor(p_RecChequeSearch)
# FUNCTION ChequeLookupFilterDataSource(pRecChequeFilter)
# FUNCTION chequeLookup_filter(pChequeCode)
# FUNCTION import_cheque()
# FUNCTION exist_chequeRec(p_cmpy_code, p_cheq_code)
# FUNCTION delete_cheque_all()
# FUNCTION chequeMenu()						-- Offer different OPTIONS of this library via a menu

# Cheque record types
	DEFINE t_recCheque  
		TYPE AS RECORD
			cheq_code LIKE cheque.cheq_code,
			com3_text LIKE cheque.com3_text
		END RECORD 

	DEFINE t_recChequeFilter  
		TYPE AS RECORD
			filter_cheq_code LIKE cheque.cheq_code,
			filter_com3_text LIKE cheque.com3_text
		END RECORD 

	DEFINE t_recChequeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCheque_noCmpyId 
		TYPE AS RECORD 
    vend_code LIKE cheque.vend_code,
    cheq_code LIKE cheque.cheq_code,
    com3_text LIKE cheque.com3_text,
    bank_acct_code LIKE cheque.bank_acct_code,
    entry_code LIKE cheque.entry_code,
    entry_date LIKE cheque.entry_date,
    cheq_date LIKE cheque.cheq_date,
    year_num LIKE cheque.year_num,
    period_num LIKE cheque.period_num,
    pay_amt LIKE cheque.pay_amt,
    apply_amt LIKE cheque.apply_amt,
    disc_amt LIKE cheque.disc_amt,
    hist_flag LIKE cheque.hist_flag,
    jour_num LIKE cheque.jour_num,
    post_flag LIKE cheque.post_flag,
    recon_flag LIKE cheque.recon_flag,
    next_appl_num LIKE cheque.next_appl_num,
    com1_text LIKE cheque.com1_text,
    com2_text LIKE cheque.com2_text,
    rec_state_num LIKE cheque.rec_state_num,
    rec_line_num LIKE cheque.rec_line_num,
    part_recon_flag LIKE cheque.part_recon_flag,
    currency_code LIKE cheque.currency_code,
    conv_qty LIKE cheque.conv_qty,
    bank_code LIKE cheque.bank_code,
    bank_currency_code LIKE cheque.bank_currency_code,
    post_date LIKE cheque.post_date,
    net_pay_amt LIKE cheque.net_pay_amt,
    withhold_tax_ind LIKE cheque.withhold_tax_ind,
    tax_code LIKE cheque.tax_code,
    tax_per LIKE cheque.tax_per,
    pay_meth_ind LIKE cheque.pay_meth_ind,
    eft_run_num LIKE cheque.eft_run_num,
    doc_num LIKE cheque.doc_num,
    source_ind LIKE cheque.source_ind,
    source_text LIKE cheque.source_text,
    tax_amt LIKE cheque.tax_amt,
    contra_amt LIKE cheque.contra_amt,
    contra_trans_num LIKE cheque.contra_trans_num,
    whtax_rep_ind LIKE cheque.whtax_rep_ind
	END RECORD	


	
########################################################################################
# FUNCTION chequeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION chequeMenu()
	MENU
		ON ACTION "Import"
			CALL import_cheque()
		ON ACTION "Export"
			CALL unload_cheque()
		#ON ACTION "Import"
		#	CALL import_cheque()
		ON ACTION "Delete All"
			CALL delete_cheque_all()
		ON ACTION "Count"
			CALL getChequeCount() --Count all cheque rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getChequeCount()
#-------------------------------------------------------
# Returns the number of Cheque entries for the current company
########################################################################################
FUNCTION getChequeCount()
	DEFINE ret_ChequeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Cheque CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Cheque ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Cheque.DECLARE(sqlQuery) #CURSOR FOR getCheque
	CALL c_Cheque.SetResults(ret_ChequeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Cheque.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ChequeCount = -1
	ELSE
		CALL c_Cheque.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Cheques:", trim(ret_ChequeCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Cheque Count", tempMsg,"info") 	
	END IF

	RETURN ret_ChequeCount
END FUNCTION

########################################################################################
# FUNCTION chequeLookupFilterDataSourceCursor(pRecChequeFilter)
#-------------------------------------------------------
# Returns the Cheque CURSOR for the lookup query
########################################################################################
FUNCTION chequeLookupFilterDataSourceCursor(pRecChequeFilter)
	DEFINE pRecChequeFilter OF t_recChequeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Cheque CURSOR
	
	LET sqlQuery =	"SELECT ",
									"cheque.cheq_code, ", 
									"cheque.com3_text ",
									"FROM cheque ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecChequeFilter.filter_cheq_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cheq_code LIKE '", pRecChequeFilter.filter_cheq_code CLIPPED, "%' "  
	END IF									

	IF pRecChequeFilter.filter_com3_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND com3_text LIKE '", pRecChequeFilter.filter_com3_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cheq_code"

	CALL c_cheque.DECLARE(sqlQuery)
		
	RETURN c_cheque
END FUNCTION



########################################################################################
# chequeLookupSearchDataSourceCursor(p_RecChequeSearch)
#-------------------------------------------------------
# Returns the Cheque CURSOR for the lookup query
########################################################################################
FUNCTION chequeLookupSearchDataSourceCursor(p_RecChequeSearch)
	DEFINE p_RecChequeSearch OF t_recChequeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Cheque CURSOR
	
	LET sqlQuery =	"SELECT ",
									"cheque.cheq_code, ", 
									"cheque.com3_text ",
 
									"FROM cheque ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecChequeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cheq_code LIKE '", p_RecChequeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR com3_text LIKE '",   p_RecChequeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecChequeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cheq_code"

	CALL c_cheque.DECLARE(sqlQuery) #CURSOR FOR cheque
	
	RETURN c_cheque
END FUNCTION


########################################################################################
# FUNCTION ChequeLookupFilterDataSource(pRecChequeFilter)
#-------------------------------------------------------
# CALLS ChequeLookupFilterDataSourceCursor(pRecChequeFilter) with the ChequeFilter data TO get a CURSOR
# Returns the Cheque list array arrChequeList
########################################################################################
FUNCTION ChequeLookupFilterDataSource(pRecChequeFilter)
	DEFINE pRecChequeFilter OF t_recChequeFilter
	DEFINE recCheque OF t_recCheque
	DEFINE arrChequeList DYNAMIC ARRAY OF t_recCheque 
	DEFINE c_Cheque CURSOR
	DEFINE retError SMALLINT
		
	CALL ChequeLookupFilterDataSourceCursor(pRecChequeFilter.*) RETURNING c_Cheque
	
	CALL arrChequeList.CLEAR()

	CALL c_Cheque.SetResults(recCheque.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Cheque.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Cheque.FetchNext()=0)
		CALL arrChequeList.append([recCheque.cheq_code, recCheque.com3_text])
	END WHILE	

	END IF
	
	IF arrChequeList.getSize() = 0 THEN
		ERROR "No cheque's found with the specified filter criteria"
	END IF
	
	RETURN arrChequeList
END FUNCTION	

########################################################################################
# FUNCTION ChequeLookupSearchDataSource(pRecChequeFilter)
#-------------------------------------------------------
# CALLS ChequeLookupSearchDataSourceCursor(pRecChequeFilter) with the ChequeFilter data TO get a CURSOR
# Returns the Cheque list array arrChequeList
########################################################################################
FUNCTION ChequeLookupSearchDataSource(p_recChequeSearch)
	DEFINE p_recChequeSearch OF t_recChequeSearch	
	DEFINE recCheque OF t_recCheque
	DEFINE arrChequeList DYNAMIC ARRAY OF t_recCheque 
	DEFINE c_Cheque CURSOR
	DEFINE retError SMALLINT	
	CALL ChequeLookupSearchDataSourceCursor(p_recChequeSearch) RETURNING c_Cheque
	
	CALL arrChequeList.CLEAR()

	CALL c_Cheque.SetResults(recCheque.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Cheque.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Cheque.FetchNext()=0)
		CALL arrChequeList.append([recCheque.cheq_code, recCheque.com3_text])
	END WHILE	

	END IF
	
	IF arrChequeList.getSize() = 0 THEN
		ERROR "No cheque's found with the specified filter criteria"
	END IF
	
	RETURN arrChequeList
END FUNCTION


########################################################################################
# FUNCTION chequeLookup_filter(pChequeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Cheque code cheq_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Cheque Code cheq_code
#
# Example:
# 			LET pr_Cheque.cheq_code = ChequeLookup(pr_Cheque.cheq_code)
########################################################################################
FUNCTION chequeLookup_filter(pChequeCode)
	DEFINE pChequeCode LIKE Cheque.cheq_code
	DEFINE arrChequeList DYNAMIC ARRAY OF t_recCheque
	DEFINE recChequeFilter OF t_recChequeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wChequeLookup WITH FORM "ChequeLookup_filter"


	CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recChequeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrChequeList TO scChequeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pChequeCode = arrChequeList[idx].cheq_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recChequeFilter.filter_cheq_code IS NOT NULL
			OR recChequeFilter.filter_com3_text IS NOT NULL

		THEN
			LET recChequeFilter.filter_cheq_code = NULL
			LET recChequeFilter.filter_com3_text = NULL

			CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cheq_code"
		IF recChequeFilter.filter_cheq_code IS NOT NULL THEN
			LET recChequeFilter.filter_cheq_code = NULL
			CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_com3_text"
		IF recChequeFilter.filter_com3_text IS NOT NULL THEN
			LET recChequeFilter.filter_com3_text = NULL
			CALL ChequeLookupFilterDataSource(recChequeFilter.*) RETURNING arrChequeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wChequeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pChequeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION chequeLookup(pChequeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Cheque code cheq_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ChequeLookupSearchDataSource(recChequeFilter.*) RETURNING arrChequeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Cheque Code cheq_code
#
# Example:
# 			LET pr_Cheque.cheq_code = ChequeLookup(pr_Cheque.cheq_code)
########################################################################################
FUNCTION chequeLookup(pChequeCode)
	DEFINE pChequeCode LIKE Cheque.cheq_code
	DEFINE arrChequeList DYNAMIC ARRAY OF t_recCheque
	DEFINE recChequeSearch OF t_recChequeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wChequeLookup WITH FORM "chequeLookup"

	CALL ChequeLookupSearchDataSource(recChequeSearch.*) RETURNING arrChequeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recChequeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ChequeLookupSearchDataSource(recChequeSearch.*) RETURNING arrChequeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrChequeList TO scChequeList.* 
		BEFORE ROW
			IF arrChequeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pChequeCode = arrChequeList[idx].cheq_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recChequeSearch.filter_any_field IS NOT NULL

		THEN
			LET recChequeSearch.filter_any_field = NULL

			CALL ChequeLookupSearchDataSource(recChequeSearch.*) RETURNING arrChequeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cheq_code"
		IF recChequeSearch.filter_any_field IS NOT NULL THEN
			LET recChequeSearch.filter_any_field = NULL
			CALL ChequeLookupSearchDataSource(recChequeSearch.*) RETURNING arrChequeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wChequeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pChequeCode	
END FUNCTION				

############################################
# FUNCTION import_cheque()
############################################
FUNCTION import_cheque()
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
	DEFINE p_com3_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_cheque OF t_recCheque_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wChequeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Cheque List Data (table: cheque)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_cheque
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_cheque(	    
    #cmpy_code CHAR(2),
    vend_code CHAR(8),
    cheq_code INTEGER,
    com3_text CHAR(20),
    bank_acct_code CHAR(18),
    entry_code CHAR(8),
    entry_date DATE,
    cheq_date DATE,
    year_num SMALLINT,
    period_num SMALLINT,
    pay_amt DECIMAL(16,2),
    apply_amt DECIMAL(16,2),
    disc_amt DECIMAL(16,2),
    hist_flag CHAR(1),
    jour_num INTEGER,
    post_flag CHAR(1),
    recon_flag CHAR(1),
    next_appl_num SMALLINT,
    com1_text CHAR(30),
    com2_text CHAR(30),
    rec_state_num SMALLINT,
    rec_line_num SMALLINT,
    part_recon_flag CHAR(1),
    currency_code CHAR(3),
    conv_qty float,
    bank_code CHAR(9),
    bank_currency_code CHAR(3),
    post_date DATE,
    net_pay_amt DECIMAL(16,2),
    withhold_tax_ind CHAR(1),
    tax_code CHAR(3),
    tax_per DECIMAL(6,3),
    pay_meth_ind CHAR(1),
    eft_run_num INTEGER,
    doc_num serial NOT NULL ,
    source_ind CHAR(1),
    source_text CHAR(8),
    tax_amt DECIMAL(16,2),
    contra_amt DECIMAL(16,2),
    contra_trans_num INTEGER,
    whtax_rep_ind CHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_cheque	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_com3_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wChequeImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_com3_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_com3_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.com3_text,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wChequeImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/cheque-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_cheque
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_cheque
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_cheque
			LET importReport = importReport, "Code:", trim(rec_cheque.cheq_code) , "     -     Desc:", trim(rec_cheque.com3_text), "\n"
					
			INSERT INTO cheque VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_cheque.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_cheque.cheq_code) , "     -     Desc:", trim(rec_cheque.com3_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wChequeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_chequeRec(p_cmpy_code, p_cheq_code)
########################################################
FUNCTION exist_chequeRec(p_cmpy_code, p_cheq_code)
	DEFINE p_cmpy_code LIKE cheque.cmpy_code
	DEFINE p_cheq_code LIKE cheque.cheq_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM cheque 
     WHERE cmpy_code = p_cmpy_code
     AND cheq_code = p_cheq_code

	DROP TABLE temp_cheque
	CLOSE WINDOW wChequeImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_cheque()
###############################################################
FUNCTION unload_cheque(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/cheque-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM cheque ORDER BY cmpy_code, cheq_code ASC
	
	LET tmpMsg = "All cheque data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("cheque Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_cheque_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_cheque_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE cheque.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wchequeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "cheque Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing cheque table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM cheque
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table cheque!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table cheque where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wChequeImport		
END FUNCTION	