GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCustomerCount()
# FUNCTION customerLookupFilterDataSourceCursor(pRecCustomerFilter)
# FUNCTION customerLookupSearchDataSourceCursor(p_RecCustomerSearch)
# FUNCTION CustomerLookupFilterDataSource(pRecCustomerFilter)
# FUNCTION customerLookup_filter(pCustomerCode)
# FUNCTION import_customer()
# FUNCTION exist_customerRec(p_cmpy_code, p_cust_code)
# FUNCTION delete_customer_all()
# FUNCTION customerMenu()						-- Offer different OPTIONS of this library via a menu

# Customer record types
	DEFINE t_recCustomer
		TYPE AS RECORD
			cust_code LIKE customer.cust_code,
			name_text LIKE customer.name_text
		END RECORD 

	DEFINE t_recCustomerFilter  
		TYPE AS RECORD
			filter_cust_code LIKE customer.cust_code,
			filter_name_text LIKE customer.name_text
		END RECORD 

	DEFINE t_recCustomerSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCustomer_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE customer.cust_code,
    corp_cust_code LIKE customer.corp_cust_code,
    name_text LIKE customer.name_text,
    addr1_text LIKE customer.addr1_text,
    addr2_text LIKE customer.addr2_text,
    city_text LIKE customer.city_text,
    state_code LIKE customer.state_code,
    post_code LIKE customer.post_code,
    country_text LIKE customer.country_text,
    country_code LIKE customer.country_code,
    language_code LIKE customer.language_code,
    type_code LIKE customer.type_code,
    sale_code LIKE customer.sale_code,
    term_code LIKE customer.term_code,
    tax_code LIKE customer.tax_code,
    inv_addr_flag LIKE customer.inv_addr_flag,
    sales_anly_flag LIKE customer.sales_anly_flag,
    credit_chk_flag LIKE customer.credit_chk_flag,
    setup_date LIKE customer.setup_date,
    last_mail_date LIKE customer.last_mail_date,
    tax_num_text LIKE customer.tax_num_text,
    contact_text LIKE customer.contact_text,
    tele_text LIKE customer.tele_text,
    cred_limit_amt LIKE customer.cred_limit_amt,
    cred_bal_amt LIKE customer.cred_bal_amt,
    bal_amt LIKE customer.bal_amt,
    highest_bal_amt LIKE customer.highest_bal_amt,
    curr_amt LIKE customer.curr_amt,
    over1_amt LIKE customer.over1_amt,
    over30_amt LIKE customer.over30_amt,
    over60_amt LIKE customer.over60_amt,
    over90_amt LIKE customer.over90_amt,
    onorder_amt LIKE customer.onorder_amt,
    inv_level_ind LIKE customer.inv_level_ind,
    dun_code LIKE customer.dun_code,
    bank_acct_code LIKE customer.bank_acct_code,
    delete_flag LIKE customer.delete_flag,
    delete_date LIKE customer.delete_date,
    show_disc_flag LIKE customer.show_disc_flag,
    consolidate_flag LIKE customer.consolidate_flag,
    cond_code LIKE customer.cond_code,
    pay_ind LIKE customer.pay_ind,
    hold_code LIKE customer.hold_code,
    share_flag LIKE customer.share_flag,
    scheme_amt LIKE customer.scheme_amt,    
    invoice_to_ind LIKE customer.invoice_to_ind,    
    ref1_code LIKE customer.ref1_code,
    ref2_code LIKE customer.ref2_code,
    ref3_code LIKE customer.ref3_code,
    ref4_code LIKE customer.ref4_code,
    ref5_code LIKE customer.ref5_code,
    ref6_code LIKE customer.ref6_code,
    ref7_code LIKE customer.ref7_code,
    ref8_code LIKE customer.ref8_code,    
    mobile_phone LIKE customer.mobile_phone,        
    ord_text_ind LIKE customer.ord_text_ind,
    corp_cust_ind LIKE customer.corp_cust_ind,
    registration_num LIKE customer.registration_num,
    cred_override_ind LIKE customer.cred_override_ind,
    comment_text LIKE customer.comment_text,
    inv_reqd_flag LIKE customer.inv_reqd_flag,    
    cred_reqd_flag LIKE customer.cred_reqd_flag,
    mail_reqd_flag LIKE customer.mail_reqd_flag,
    inv_format_ind LIKE customer.inv_format_ind,
    cred_format_ind LIKE customer.cred_format_ind,
    avg_cred_day_num LIKE customer.avg_cred_day_num,
    last_inv_date LIKE customer.last_inv_date,
    last_pay_date LIKE customer.last_pay_date,
    next_seq_num LIKE customer.next_seq_num,
    partial_ship_flag LIKE customer.partial_ship_flag,
    back_order_flag LIKE customer.back_order_flag,
    currency_code LIKE customer.currency_code,
    int_chge_flag LIKE customer.int_chge_flag,
    stmnt_ind LIKE customer.stmnt_ind,
    ytds_amt LIKE customer.ytds_amt,
    mtds_amt LIKE customer.mtds_amt,
    ytdp_amt LIKE customer.ytdp_amt,
    mtdp_amt LIKE customer.mtdp_amt,
    late_pay_num LIKE customer.late_pay_num,
    cred_given_num LIKE customer.cred_given_num,
    cred_taken_num LIKE customer.cred_taken_num,
    fax_text LIKE customer.fax_text,
    interest_per LIKE customer.interest_per,
    territory_code LIKE customer.territory_code,
    billing_ind LIKE customer.billing_ind,
    vat_code LIKE customer.vat_code
	END RECORD	

	
########################################################################################
# FUNCTION customerMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION customerMenu()
	MENU
		ON ACTION "Import"
			CALL import_customer()
		ON ACTION "Export"
			CALL unload_customer(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_customer_all()
		ON ACTION "Count"
			CALL getCustomerCount() --Count all customer rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCustomerCount()
#-------------------------------------------------------
# Returns the number of Customer entries for the current company
########################################################################################
FUNCTION getCustomerCount()
	DEFINE ret_CustomerCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Customer CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM customer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Customer.DECLARE(sqlQuery) #CURSOR FOR getCustomer
	CALL c_Customer.SetResults(ret_CustomerCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Customer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CustomerCount = -1
	ELSE
		CALL c_Customer.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Customer Types:", trim(ret_CustomerCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Customer Count", tempMsg,"info") 	
	END IF

	RETURN ret_CustomerCount
END FUNCTION

########################################################################################
# FUNCTION customerLookupFilterDataSourceCursor(pRecCustomerFilter)
#-------------------------------------------------------
# Returns the Customer CURSOR for the lookup query
########################################################################################
FUNCTION customerLookupFilterDataSourceCursor(pRecCustomerFilter)
	DEFINE pRecCustomerFilter OF t_recCustomerFilter
	DEFINE sqlQuery STRING
	DEFINE c_Customer CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customer.cust_code, ", 
									"customer.name_text ",
									"FROM customer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCustomerFilter.filter_cust_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cust_code LIKE '", pRecCustomerFilter.filter_cust_code CLIPPED, "%' "  
	END IF									

	IF pRecCustomerFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecCustomerFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cust_code"

	CALL c_customer.DECLARE(sqlQuery)
		
	RETURN c_customer
END FUNCTION



########################################################################################
# customerLookupSearchDataSourceCursor(p_RecCustomerSearch)
#-------------------------------------------------------
# Returns the Customer CURSOR for the lookup query
########################################################################################
FUNCTION customerLookupSearchDataSourceCursor(p_RecCustomerSearch)
	DEFINE p_RecCustomerSearch OF t_recCustomerSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Customer CURSOR
	
	LET sqlQuery =	"SELECT ",
									"customer.cust_code, ", 
									"customer.name_text ",
 
									"FROM customer ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCustomerSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cust_code LIKE '", p_RecCustomerSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecCustomerSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecCustomerSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cust_code"

	CALL c_customer.DECLARE(sqlQuery) #CURSOR FOR customer
	
	RETURN c_customer
END FUNCTION


########################################################################################
# FUNCTION CustomerLookupFilterDataSource(pRecCustomerFilter)
#-------------------------------------------------------
# CALLS CustomerLookupFilterDataSourceCursor(pRecCustomerFilter) with the CustomerFilter data TO get a CURSOR
# Returns the Customer list array arrCustomerList
########################################################################################
FUNCTION CustomerLookupFilterDataSource(pRecCustomerFilter)
	DEFINE pRecCustomerFilter OF t_recCustomerFilter
	DEFINE recCustomer OF t_recCustomer
	DEFINE arrCustomerList DYNAMIC ARRAY OF t_recCustomer 
	DEFINE c_Customer CURSOR
	DEFINE retError SMALLINT
		
	CALL CustomerLookupFilterDataSourceCursor(pRecCustomerFilter.*) RETURNING c_Customer
	
	CALL arrCustomerList.CLEAR()

	CALL c_Customer.SetResults(recCustomer.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Customer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Customer.FetchNext()=0)
		CALL arrCustomerList.append([recCustomer.cust_code, recCustomer.name_text])
	END WHILE	

	END IF
	
	IF arrCustomerList.getSize() = 0 THEN
		ERROR "No customer's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerList
END FUNCTION	

########################################################################################
# FUNCTION CustomerLookupSearchDataSource(pRecCustomerFilter)
#-------------------------------------------------------
# CALLS CustomerLookupSearchDataSourceCursor(pRecCustomerFilter) with the CustomerFilter data TO get a CURSOR
# Returns the Customer list array arrCustomerList
########################################################################################
FUNCTION CustomerLookupSearchDataSource(p_recCustomerSearch)
	DEFINE p_recCustomerSearch OF t_recCustomerSearch	
	DEFINE recCustomer OF t_recCustomer
	DEFINE arrCustomerList DYNAMIC ARRAY OF t_recCustomer 
	DEFINE c_Customer CURSOR
	DEFINE retError SMALLINT	
	CALL CustomerLookupSearchDataSourceCursor(p_recCustomerSearch) RETURNING c_Customer
	
	CALL arrCustomerList.CLEAR()

	CALL c_Customer.SetResults(recCustomer.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Customer.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Customer.FetchNext()=0)
		CALL arrCustomerList.append([recCustomer.cust_code, recCustomer.name_text])
	END WHILE	

	END IF
	
	IF arrCustomerList.getSize() = 0 THEN
		ERROR "No customer's found with the specified filter criteria"
	END IF
	
	RETURN arrCustomerList
END FUNCTION


########################################################################################
# FUNCTION customerLookup_filter(pCustomerCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Customer code cust_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Customer Code cust_code
#
# Example:
# 			LET pr_Customer.cust_code = CustomerLookup(pr_Customer.cust_code)
########################################################################################
FUNCTION customerLookup_filter(pCustomerCode)
	DEFINE pCustomerCode LIKE Customer.cust_code
	DEFINE arrCustomerList DYNAMIC ARRAY OF t_recCustomer
	DEFINE recCustomerFilter OF t_recCustomerFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerLookup WITH FORM "CustomerLookup_filter"


	CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerList TO scCustomerList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerCode = arrCustomerList[idx].cust_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerFilter.filter_cust_code IS NOT NULL
			OR recCustomerFilter.filter_name_text IS NOT NULL

		THEN
			LET recCustomerFilter.filter_cust_code = NULL
			LET recCustomerFilter.filter_name_text = NULL

			CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cust_code"
		IF recCustomerFilter.filter_cust_code IS NOT NULL THEN
			LET recCustomerFilter.filter_cust_code = NULL
			CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recCustomerFilter.filter_name_text IS NOT NULL THEN
			LET recCustomerFilter.filter_name_text = NULL
			CALL CustomerLookupFilterDataSource(recCustomerFilter.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerCode	
END FUNCTION				
		

########################################################################################
# FUNCTION customerLookup(pCustomerCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Customer code cust_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CustomerLookupSearchDataSource(recCustomerFilter.*) RETURNING arrCustomerList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Customer Code cust_code
#
# Example:
# 			LET pr_Customer.cust_code = CustomerLookup(pr_Customer.cust_code)
########################################################################################
FUNCTION customerLookup(pCustomerCode)
	DEFINE pCustomerCode LIKE Customer.cust_code
	DEFINE arrCustomerList DYNAMIC ARRAY OF t_recCustomer
	DEFINE recCustomerSearch OF t_recCustomerSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCustomerLookup WITH FORM "customerLookup"

	CALL CustomerLookupSearchDataSource(recCustomerSearch.*) RETURNING arrCustomerList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCustomerSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CustomerLookupSearchDataSource(recCustomerSearch.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCustomerList TO scCustomerList.* 
		BEFORE ROW
			IF arrCustomerList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCustomerCode = arrCustomerList[idx].cust_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCustomerSearch.filter_any_field IS NOT NULL

		THEN
			LET recCustomerSearch.filter_any_field = NULL

			CALL CustomerLookupSearchDataSource(recCustomerSearch.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cust_code"
		IF recCustomerSearch.filter_any_field IS NOT NULL THEN
			LET recCustomerSearch.filter_any_field = NULL
			CALL CustomerLookupSearchDataSource(recCustomerSearch.*) RETURNING arrCustomerList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCustomerLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCustomerCode	
END FUNCTION				

############################################
# FUNCTION import_customer()
############################################
FUNCTION import_customer()
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
	
	DEFINE rec_customer OF t_recCustomer_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCustomerImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Customer List Data (table: customer)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_customer
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_customer(
    cust_code CHAR(8),
    corp_cust_code CHAR(8),
    name_text CHAR(30),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(20),
    state_code CHAR(6),
    post_code CHAR(10),
    country_text CHAR(40),
    country_code CHAR(3),
    language_code CHAR(3),
    type_code CHAR(3),
    sale_code CHAR(8),
    term_code CHAR(3),
    tax_code CHAR(3),
    inv_addr_flag CHAR(1),
    sales_anly_flag CHAR(1),
    credit_chk_flag CHAR(1),
    setup_date DATE,
    last_mail_date DATE,
    tax_num_text CHAR(15),
    contact_text CHAR(30),
    tele_text CHAR(20),
    cred_limit_amt DECIMAL(16,2),
    cred_bal_amt DECIMAL(16,2),
    bal_amt DECIMAL(16,2),
    highest_bal_amt DECIMAL(16,2),
    curr_amt DECIMAL(16,2),
    over1_amt DECIMAL(16,2),
    over30_amt DECIMAL(16,2),
    over60_amt DECIMAL(16,2),
    over90_amt DECIMAL(16,2),
    onorder_amt DECIMAL(16,2),
    inv_level_ind CHAR(1),
    dun_code CHAR(3),
    bank_acct_code CHAR(20),
    delete_flag CHAR(1),
    delete_date DATE,
    show_disc_flag CHAR(1),
    consolidate_flag CHAR(1),
    cond_code CHAR(3),
    pay_ind CHAR(1),
    hold_code CHAR(3),
    share_flag CHAR(1),
    scheme_amt DECIMAL(16,2),
    invoice_to_ind CHAR(1),
    ref1_code CHAR(10),
    ref2_code CHAR(10),
    ref3_code CHAR(10),
    ref4_code CHAR(10),
    ref5_code CHAR(10),
    ref6_code CHAR(10),
    ref7_code CHAR(10),
    ref8_code CHAR(10),
    mobile_phone CHAR(20),
    ord_text_ind CHAR(1),
    corp_cust_ind CHAR(1),
    registration_num CHAR(15),
    cred_override_ind CHAR(1),
    comment_text CHAR(60),
    inv_reqd_flag CHAR(1),
    cred_reqd_flag CHAR(1),
    mail_reqd_flag CHAR(1),
    inv_format_ind CHAR(1),
    cred_format_ind CHAR(1),
    avg_cred_day_num SMALLINT,
    last_inv_date DATE,
    last_pay_date DATE,
    next_seq_num INTEGER,
    partial_ship_flag CHAR(1),
    back_order_flag CHAR(1),
    currency_code CHAR(3),
    int_chge_flag CHAR(1),
    stmnt_ind CHAR(1),
    ytds_amt DECIMAL(16,2),
    mtds_amt DECIMAL(16,2),
    ytdp_amt DECIMAL(16,2),
    mtdp_amt DECIMAL(16,2),
    late_pay_num SMALLINT,
    cred_given_num DECIMAL(10),
    cred_taken_num DECIMAL(10),
    fax_text CHAR(20),
    interest_per DECIMAL(6,3),
    territory_code CHAR(5),
    billing_ind CHAR(1),
    vat_code CHAR(11)		
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_customer	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCustomerImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCustomerImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/customer-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_customer
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_customer
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_customer
			LET importReport = importReport, "Code:", trim(rec_customer.cust_code) , "     -     Desc:", trim(rec_customer.name_text), "\n"
					
			INSERT INTO customer VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_customer.cust_code,
				rec_customer.corp_cust_code,
				rec_customer.name_text,
				rec_customer.addr1_text,
				rec_customer.addr2_text,
				rec_customer.city_text,
				rec_customer.state_code,
				rec_customer.post_code,
				rec_customer.country_text,
				rec_customer.country_code,
				rec_customer.language_code,
				rec_customer.type_code,
				rec_customer.sale_code,
				rec_customer.term_code,
				rec_customer.tax_code,
				rec_customer.inv_addr_flag,
				rec_customer.sales_anly_flag,
				rec_customer.credit_chk_flag,
				rec_customer.setup_date,
				rec_customer.last_mail_date,
				rec_customer.tax_num_text,
				rec_customer.contact_text,
				rec_customer.tele_text,
				rec_customer.cred_limit_amt,
				rec_customer.cred_bal_amt,
				rec_customer.bal_amt,
				rec_customer.highest_bal_amt,
				rec_customer.curr_amt,
				rec_customer.over1_amt,
				rec_customer.over30_amt,
				rec_customer.over60_amt,
				rec_customer.over90_amt,
				rec_customer.onorder_amt,
				rec_customer.inv_level_ind,
				rec_customer.dun_code,
				rec_customer.bank_acct_code,
				rec_customer.delete_flag,
				rec_customer.delete_date,
				rec_customer.show_disc_flag,
				rec_customer.consolidate_flag,
				rec_customer.cond_code,
				rec_customer.pay_ind,
				rec_customer.hold_code,
				rec_customer.share_flag,
				rec_customer.scheme_amt,
				rec_customer.invoice_to_ind,
				rec_customer.ref1_code,
				rec_customer.ref2_code,
				rec_customer.ref3_code,
				rec_customer.ref4_code,
				rec_customer.ref5_code,
				rec_customer.ref6_code,
				rec_customer.ref7_code,
				rec_customer.ref8_code,
				rec_customer.mobile_phone,
				rec_customer.ord_text_ind,
				rec_customer.corp_cust_ind,
				rec_customer.registration_num,
				rec_customer.cred_override_ind,
				rec_customer.comment_text,
				rec_customer.inv_reqd_flag,
				rec_customer.cred_reqd_flag,
				rec_customer.mail_reqd_flag,
				rec_customer.inv_format_ind,
				rec_customer.cred_format_ind,
				rec_customer.avg_cred_day_num,
				rec_customer.last_inv_date,
				rec_customer.last_pay_date,
				rec_customer.next_seq_num,
				rec_customer.partial_ship_flag,
				rec_customer.back_order_flag,
				rec_customer.currency_code,
				rec_customer.int_chge_flag,
				rec_customer.stmnt_ind,
				rec_customer.ytds_amt,
				rec_customer.mtds_amt,
				rec_customer.ytdp_amt,
				rec_customer.mtdp_amt,
				rec_customer.late_pay_num,
				rec_customer.cred_given_num,
				rec_customer.cred_taken_num,
				rec_customer.fax_text,
				rec_customer.interest_per,
				rec_customer.territory_code,
				rec_customer.billing_ind,
				rec_customer.vat_code
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_customer.cust_code) , "     -     Desc:", trim(rec_customer.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCustomerImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_customerRec(p_cmpy_code, p_cust_code)
########################################################
FUNCTION exist_customerRec(p_cmpy_code, p_cust_code)
	DEFINE p_cmpy_code LIKE customer.cmpy_code
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM customer 
     WHERE cmpy_code = p_cmpy_code
     AND cust_code = p_cust_code

	DROP TABLE temp_customer
	CLOSE WINDOW wCustomerImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_customer()
###############################################################
FUNCTION unload_customer(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()
	LET unloadFile = "unl/customer-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
			cust_code,
			corp_cust_code,
			name_text,
			addr1_text,
			addr2_text,
			city_text,
			state_code,
			post_code,
			country_text,
			country_code,
			language_code,
			type_code,
			sale_code,
			term_code,
			tax_code,
			inv_addr_flag,
			sales_anly_flag,
			credit_chk_flag,
			setup_date,
			last_mail_date,
			tax_num_text,
			contact_text,
			tele_text,
			cred_limit_amt,
			cred_bal_amt,
			bal_amt,
			highest_bal_amt,
			curr_amt,
			over1_amt,
			over30_amt,
			over60_amt,
			over90_amt,
			onorder_amt,
			inv_level_ind,
			dun_code,
			bank_acct_code,
			delete_flag,
			delete_date,
			show_disc_flag,
			consolidate_flag,
			cond_code,
			pay_ind,
			hold_code,
			share_flag,
			scheme_amt,    
			invoice_to_ind,    
			ref1_code,
			ref2_code,
			ref3_code,
			ref4_code,
			ref5_code,
			ref6_code,
			ref7_code,
			ref8_code,    
			mobile_phone,        
			ord_text_ind,
			corp_cust_ind,
			registration_num,
			cred_override_ind,
			comment_text,
			inv_reqd_flag,    
			cred_reqd_flag,
			mail_reqd_flag,
			inv_format_ind,
			cred_format_ind,
			avg_cred_day_num,
			last_inv_date,
			last_pay_date,
			next_seq_num,
			partial_ship_flag,
			back_order_flag,
			currency_code,
			int_chge_flag,
			stmnt_ind,
			ytds_amt,
			mtds_amt,
			ytdp_amt,
			mtdp_amt,
			late_pay_num,
			cred_given_num,
			cred_taken_num,
			fax_text,
			interest_per,
			territory_code,
			billing_ind,
			vat_code
		FROM customer 
		WHERE cmpy_code = currentCompany
		ORDER BY country_code, cust_code ASC

	LET unloadFile2 = unloadFile CLIPPED, "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM customer 
		ORDER BY cmpy_code,country_code,cust_code ASC
	
	LET tmpMsg = "All customer data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("customer Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_customer_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_customer_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE customer.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcustomerImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "customer Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing customer table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM customer
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table customer!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table customer where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCustomerImport		
END FUNCTION	