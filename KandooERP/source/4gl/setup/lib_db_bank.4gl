GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getBankCount()
# FUNCTION bankLookupFilterDataSourceCursor(pRecBankFilter)
# FUNCTION bankLookupSearchDataSourceCursor(p_RecBankSearch)
# FUNCTION BankLookupFilterDataSource(pRecBankFilter)
# FUNCTION bankLookup_filter(pBankCode)
# FUNCTION import_bank()
# FUNCTION exist_bankRec(p_cmpy_code, p_bank_code)
# FUNCTION delete_bank_all()
# FUNCTION bankMenu()						-- Offer different OPTIONS of this library via a menu

# Bank record types
	DEFINE t_recBank
		TYPE AS RECORD
			bank_code LIKE bank.bank_code,
			name_text LIKE bank.name_text
		END RECORD 

	DEFINE t_recBankFilter  
		TYPE AS RECORD
			filter_bank_code LIKE bank.bank_code,
			filter_name_text LIKE bank.name_text
		END RECORD 

	DEFINE t_recBankSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recBank_noCmpyId 
		TYPE AS RECORD 
	    bank_code LIKE bank.bank_code,
	    #cmpy_code LIKE bank.cmpy_code,
	    acct_code LIKE bank.acct_code,
	    currency_code LIKE bank.currency_code,
	    name_acct_text LIKE bank.name_acct_text,
	    next_cheque_num LIKE bank.next_cheque_num,
	    iban LIKE bank.iban,
	    state_bal_amt LIKE bank.state_bal_amt,
	    sheet_num LIKE bank.sheet_num,
	    name_text LIKE bank.name_text,
	    branch_text LIKE bank.branch_text,
	    acct_name_text LIKE bank.acct_name_text,
	    state_base_bal_amt LIKE bank.state_base_bal_amt,
	    type_code LIKE bank.type_code,
	    next_eft_run_num LIKE bank.next_eft_run_num,
	    next_eft_ref_num LIKE bank.next_eft_ref_num,
	    remit_text LIKE bank.remit_text,
	    bic_code LIKE bank.bic_code,
	    user_text LIKE bank.user_text,
	    eft_rpt_ind LIKE bank.eft_rpt_ind,
	    next_cheq_run_num LIKE bank.next_cheq_run_num,
	    ext_file_ind LIKE bank.ext_file_ind,
	    ext_path_text LIKE bank.ext_path_text,
	    ext_file_text LIKE bank.ext_file_text
	END RECORD	

	
########################################################################################
# FUNCTION bankMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION bankMenu()
	MENU
		ON ACTION "Import"
			CALL import_bank()
		ON ACTION "Export"
			CALL unload_bank(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_bank_all()
		ON ACTION "Count"
			CALL getBankCount() --Count all bank rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getBankCount()
#-------------------------------------------------------
# Returns the number of Bank entries for the current company
########################################################################################
FUNCTION getBankCount()
	DEFINE ret_BankCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Bank CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM bank ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Bank.DECLARE(sqlQuery) #CURSOR FOR getBank
	CALL c_Bank.SetResults(ret_BankCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Bank.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_BankCount = -1
	ELSE
		CALL c_Bank.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Banks:", trim(ret_BankCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Bank Count", tempMsg,"info") 	
	END IF

	RETURN ret_BankCount
END FUNCTION

########################################################################################
# FUNCTION bankLookupFilterDataSourceCursor(pRecBankFilter)
#-------------------------------------------------------
# Returns the Bank CURSOR for the lookup query
########################################################################################
FUNCTION bankLookupFilterDataSourceCursor(pRecBankFilter)
	DEFINE pRecBankFilter OF t_recBankFilter
	DEFINE sqlQuery STRING
	DEFINE c_Bank CURSOR
	
	LET sqlQuery =	"SELECT ",
									"bank.bank_code, ", 
									"bank.name_text ",
									"FROM bank ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecBankFilter.filter_bank_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND bank_code LIKE '", pRecBankFilter.filter_bank_code CLIPPED, "%' "  
	END IF									

	IF pRecBankFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecBankFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY bank_code"

	CALL c_bank.DECLARE(sqlQuery)
		
	RETURN c_bank
END FUNCTION



########################################################################################
# bankLookupSearchDataSourceCursor(p_RecBankSearch)
#-------------------------------------------------------
# Returns the Bank CURSOR for the lookup query
########################################################################################
FUNCTION bankLookupSearchDataSourceCursor(p_RecBankSearch)
	DEFINE p_RecBankSearch OF t_recBankSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Bank CURSOR
	
	LET sqlQuery =	"SELECT ",
									"bank.bank_code, ", 
									"bank.name_text ",
 
									"FROM bank ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecBankSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((bank_code LIKE '", p_RecBankSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecBankSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecBankSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY bank_code"

	CALL c_bank.DECLARE(sqlQuery) #CURSOR FOR bank
	
	RETURN c_bank
END FUNCTION


########################################################################################
# FUNCTION BankLookupFilterDataSource(pRecBankFilter)
#-------------------------------------------------------
# CALLS BankLookupFilterDataSourceCursor(pRecBankFilter) with the BankFilter data TO get a CURSOR
# Returns the Bank list array arrBankList
########################################################################################
FUNCTION BankLookupFilterDataSource(pRecBankFilter)
	DEFINE pRecBankFilter OF t_recBankFilter
	DEFINE recBank OF t_recBank
	DEFINE arrBankList DYNAMIC ARRAY OF t_recBank 
	DEFINE c_Bank CURSOR
	DEFINE retError SMALLINT
		
	CALL BankLookupFilterDataSourceCursor(pRecBankFilter.*) RETURNING c_Bank
	
	CALL arrBankList.CLEAR()

	CALL c_Bank.SetResults(recBank.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Bank.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Bank.FetchNext()=0)
		CALL arrBankList.append([recBank.bank_code, recBank.name_text])
	END WHILE	

	END IF
	
	IF arrBankList.getSize() = 0 THEN
		ERROR "No bank's found with the specified filter criteria"
	END IF
	
	RETURN arrBankList
END FUNCTION	

########################################################################################
# FUNCTION BankLookupSearchDataSource(pRecBankFilter)
#-------------------------------------------------------
# CALLS BankLookupSearchDataSourceCursor(pRecBankFilter) with the BankFilter data TO get a CURSOR
# Returns the Bank list array arrBankList
########################################################################################
FUNCTION BankLookupSearchDataSource(p_recBankSearch)
	DEFINE p_recBankSearch OF t_recBankSearch	
	DEFINE recBank OF t_recBank
	DEFINE arrBankList DYNAMIC ARRAY OF t_recBank 
	DEFINE c_Bank CURSOR
	DEFINE retError SMALLINT	
	CALL BankLookupSearchDataSourceCursor(p_recBankSearch) RETURNING c_Bank
	
	CALL arrBankList.CLEAR()

	CALL c_Bank.SetResults(recBank.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Bank.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Bank.FetchNext()=0)
		CALL arrBankList.append([recBank.bank_code, recBank.name_text])
	END WHILE	

	END IF
	
	IF arrBankList.getSize() = 0 THEN
		ERROR "No bank's found with the specified filter criteria"
	END IF
	
	RETURN arrBankList
END FUNCTION


########################################################################################
# FUNCTION bankLookup_filter(pBankCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Bank code bank_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Bank Code bank_code
#
# Example:
# 			LET pr_Bank.bank_code = BankLookup(pr_Bank.bank_code)
########################################################################################
FUNCTION bankLookup_filter(pBankCode)
	DEFINE pBankCode LIKE Bank.bank_code
	DEFINE arrBankList DYNAMIC ARRAY OF t_recBank
	DEFINE recBankFilter OF t_recBankFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wBankLookup WITH FORM "BankLookup_filter"


	CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recBankFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrBankList TO scBankList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pBankCode = arrBankList[idx].bank_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recBankFilter.filter_bank_code IS NOT NULL
			OR recBankFilter.filter_name_text IS NOT NULL

		THEN
			LET recBankFilter.filter_bank_code = NULL
			LET recBankFilter.filter_name_text = NULL

			CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_bank_code"
		IF recBankFilter.filter_bank_code IS NOT NULL THEN
			LET recBankFilter.filter_bank_code = NULL
			CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recBankFilter.filter_name_text IS NOT NULL THEN
			LET recBankFilter.filter_name_text = NULL
			CALL BankLookupFilterDataSource(recBankFilter.*) RETURNING arrBankList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wBankLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pBankCode	
END FUNCTION				
		

########################################################################################
# FUNCTION bankLookup(pBankCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Bank code bank_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL BankLookupSearchDataSource(recBankFilter.*) RETURNING arrBankList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Bank Code bank_code
#
# Example:
# 			LET pr_Bank.bank_code = BankLookup(pr_Bank.bank_code)
########################################################################################
FUNCTION bankLookup(pBankCode)
	DEFINE pBankCode LIKE Bank.bank_code
	DEFINE arrBankList DYNAMIC ARRAY OF t_recBank
	DEFINE recBankSearch OF t_recBankSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wBankLookup WITH FORM "bankLookup"

	CALL BankLookupSearchDataSource(recBankSearch.*) RETURNING arrBankList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recBankSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL BankLookupSearchDataSource(recBankSearch.*) RETURNING arrBankList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrBankList TO scBankList.* 
		BEFORE ROW
			IF arrBankList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pBankCode = arrBankList[idx].bank_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recBankSearch.filter_any_field IS NOT NULL

		THEN
			LET recBankSearch.filter_any_field = NULL

			CALL BankLookupSearchDataSource(recBankSearch.*) RETURNING arrBankList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_bank_code"
		IF recBankSearch.filter_any_field IS NOT NULL THEN
			LET recBankSearch.filter_any_field = NULL
			CALL BankLookupSearchDataSource(recBankSearch.*) RETURNING arrBankList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wBankLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pBankCode	
END FUNCTION				

############################################
# FUNCTION import_bank()
############################################
FUNCTION import_bank()
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
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_bank OF t_recBank_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wBankImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Bank List Data (table: bank)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_bank
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_bank(
	    bank_code CHAR(9),
	    #cmpy_code CHAR(2),
	    acct_code CHAR(18),
	    currency_code CHAR(3),
	    name_acct_text CHAR(40),
	    next_cheque_num INTEGER,
	    iban CHAR(40),
	    state_bal_amt DECIMAL(16,2),
	    sheet_num SMALLINT,
	    name_text CHAR(40),
	    branch_text CHAR(40),
	    acct_name_text CHAR(40),
	    state_base_bal_amt DECIMAL(16,4),
	    type_code CHAR(8),
	    next_eft_run_num INTEGER,
	    next_eft_ref_num INTEGER,
	    remit_text CHAR(20),
	    bic_code CHAR(11),
	    user_text CHAR(6),
	    eft_rpt_ind SMALLINT,
	    next_cheq_run_num INTEGER,
	    ext_file_ind CHAR(1),
	    ext_path_text CHAR(40),
	    ext_file_text CHAR(20)


		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_bank	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wBankImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wBankImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/bank-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_bank
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_bank
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_bank
			LET importReport = importReport, "Code:", trim(rec_bank.bank_code) , "     -     Desc:", trim(rec_bank.name_text), "\n"
					
			INSERT INTO bank VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_bank.bank_code,
				rec_bank.corp_bank_code,
				rec_bank.name_text,
				rec_bank.addr1_text,
				rec_bank.addr2_text,
				rec_bank.city_text,
				rec_bank.state_code,
				rec_bank.post_code,
				rec_bank.country_text,
				rec_bank.country_code,
				rec_bank.language_code,
				rec_bank.type_code,
				rec_bank.sale_code,
				rec_bank.term_code,
				rec_bank.tax_code,
				rec_bank.inv_addr_flag,
				rec_bank.sales_anly_flag,
				rec_bank.credit_chk_flag,
				rec_bank.setup_date,
				rec_bank.last_mail_date,
				rec_bank.tax_num_text,
				rec_bank.contact_text,
				rec_bank.tele_text,
				rec_bank.cred_limit_amt,
				rec_bank.cred_bal_amt,
				rec_bank.bal_amt,
				rec_bank.highest_bal_amt,
				rec_bank.curr_amt,
				rec_bank.over1_amt,
				rec_bank.over30_amt,
				rec_bank.over60_amt,
				rec_bank.over90_amt,
				rec_bank.onorder_amt,
				rec_bank.inv_level_ind,
				rec_bank.dun_code,
				rec_bank.bank_acct_code,
				rec_bank.delete_flag,
				rec_bank.delete_date,
				rec_bank.show_disc_flag,
				rec_bank.consolidate_flag,
				rec_bank.cond_code,
				rec_bank.pay_ind,
				rec_bank.hold_code,
				rec_bank.share_flag,
				rec_bank.scheme_amt,
				rec_bank.invoice_to_ind,
				rec_bank.ref1_code,
				rec_bank.ref2_code,
				rec_bank.ref3_code,
				rec_bank.ref4_code,
				rec_bank.ref5_code,
				rec_bank.ref6_code,
				rec_bank.ref7_code,
				rec_bank.ref8_code,
				rec_bank.mobile_phone,
				rec_bank.ord_text_ind,
				rec_bank.corp_cust_ind,
				rec_bank.registration_num,
				rec_bank.cred_override_ind,
				rec_bank.comment_text,
				rec_bank.inv_reqd_flag,
				rec_bank.cred_reqd_flag,
				rec_bank.mail_reqd_flag,
				rec_bank.inv_format_ind,
				rec_bank.cred_format_ind,
				rec_bank.avg_cred_day_num,
				rec_bank.last_inv_date,
				rec_bank.last_pay_date,
				rec_bank.next_seq_num,
				rec_bank.partial_ship_flag,
				rec_bank.back_order_flag,
				rec_bank.currency_code,
				rec_bank.int_chge_flag,
				rec_bank.stmnt_ind,
				rec_bank.ytds_amt,
				rec_bank.mtds_amt,
				rec_bank.ytdp_amt,
				rec_bank.mtdp_amt,
				rec_bank.late_pay_num,
				rec_bank.cred_given_num,
				rec_bank.cred_taken_num,
				rec_bank.fax_text,
				rec_bank.interest_per,
				rec_bank.territory_code,
				rec_bank.billing_ind,
				rec_bank.vat_code
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_bank.bank_code) , "     -     Desc:", trim(rec_bank.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wBankImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_bankRec(p_cmpy_code, p_bank_code)
########################################################
FUNCTION exist_bankRec(p_cmpy_code, p_bank_code)
	DEFINE p_cmpy_code LIKE bank.cmpy_code
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM bank 
     WHERE cmpy_code = p_cmpy_code
     AND bank_code = p_bank_code

	DROP TABLE temp_bank
	CLOSE WINDOW wBankImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_bank()
###############################################################
FUNCTION unload_bank(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()
	LET unloadFile = "unl/bank-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
    bank_code,
    #cmpy_code,
    acct_code,
    currency_code,
    name_acct_text,
    next_cheque_num,
    iban,
    state_bal_amt,
    sheet_num,
    name_text,
    branch_text,
    acct_name_text,
    state_base_bal_amt,
    type_code,
    next_eft_run_num,
    next_eft_ref_num,
    remit_text,
    bic_code,
    user_text,
    eft_rpt_ind,
    next_cheq_run_num,
    ext_file_ind,
    ext_path_text,
    ext_file_text


		FROM bank 
		WHERE cmpy_code = currentCompany
		ORDER BY bank_code ASC

	LET unloadFile2 = unloadFile CLIPPED, "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM bank 
		ORDER BY cmpy_code,bank_code ASC
	
	LET tmpMsg = "All bank data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("bank Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_bank_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_bank_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE bank.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wbankImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "bank Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing bank table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM bank
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table bank!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table bank where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wBankImport		
END FUNCTION	