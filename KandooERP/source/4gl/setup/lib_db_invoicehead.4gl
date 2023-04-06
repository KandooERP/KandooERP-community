GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getInvoiceHead_Count()
# FUNCTION invoicehead_LookupFilterDataSourceCursor(pRecInvoiceHead_Filter)
# FUNCTION invoicehead_LookupSearchDataSourceCursor(p_RecInvoiceHead_Search)
# FUNCTION InvoiceHead_LookupFilterDataSource(pRecInvoiceHead_Filter)
# FUNCTION invoicehead_Lookup_filter(p_inv_num)
# FUNCTION import_invoicehead()
# FUNCTION exist_invoicehead_Rec(p_cmpy_code, p_inv_num)
# FUNCTION delete_invoicehead_all()
# FUNCTION invoiceHeadMenu()						-- Offer different OPTIONS of this library via a menu

		

	DEFINE t_recInvoiceHead_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE invoicehead.cust_code,
    org_cust_code LIKE invoicehead.org_cust_code,
    inv_num LIKE invoicehead.inv_num,
    ord_num LIKE invoicehead.ord_num,
    purchase_code LIKE invoicehead.purchase_code,
    job_code LIKE invoicehead.job_code,
    inv_date LIKE invoicehead.inv_date,
    entry_code LIKE invoicehead.entry_code,
    entry_date LIKE invoicehead.entry_date,
    sale_code LIKE invoicehead.sale_code,
    term_code LIKE invoicehead.term_code,
    disc_per LIKE invoicehead.tax_code,
    tax_code LIKE invoicehead.tax_code,
    tax_per LIKE invoicehead.tax_per,
    goods_amt LIKE invoicehead.goods_amt,
    hand_amt LIKE invoicehead.hand_amt,
    hand_tax_code LIKE invoicehead.hand_tax_code,
    hand_tax_amt LIKE invoicehead.hand_tax_amt,
    freight_amt LIKE invoicehead.freight_amt,
    freight_tax_code LIKE invoicehead.freight_tax_code,
    freight_tax_amt LIKE invoicehead.freight_tax_amt,
    tax_amt LIKE invoicehead.tax_amt,
    disc_amt LIKE invoicehead.disc_amt,
    total_amt LIKE invoicehead.total_amt,
    cost_amt LIKE invoicehead.cost_amt,
    paid_amt LIKE invoicehead.paid_amt,
    paid_date LIKE invoicehead.paid_date,
    disc_taken_amt LIKE invoicehead.disc_taken_amt,
    due_date LIKE invoicehead.due_date,
    disc_date LIKE invoicehead.disc_date,
    expected_date LIKE invoicehead.expected_date,
    year_num LIKE invoicehead.year_num,
    period_num LIKE invoicehead.period_num,
    on_state_flag LIKE invoicehead.on_state_flag,
    posted_flag LIKE invoicehead.posted_flag,
    seq_num LIKE invoicehead.seq_num,
    line_num  LIKE invoicehead.line_num,
    printed_num  LIKE invoicehead.printed_num,
    story_flag  LIKE invoicehead.story_flag,
    rev_date  LIKE invoicehead.rev_date,
    rev_num  LIKE invoicehead.rev_num,
    ship_code  LIKE invoicehead.ship_code,
    name_text  LIKE invoicehead.name_text,
    addr1_text  LIKE invoicehead.addr1_text,
    addr2_text  LIKE invoicehead.addr2_text,
    city_text  LIKE invoicehead.city_text,
    state_code  LIKE invoicehead.state_code,
    post_code  LIKE invoicehead.post_code,
    country_text  LIKE invoicehead.country_text,
    ship1_text  LIKE invoicehead.ship1_text,
    ship2_text  LIKE invoicehead.ship2_text,
    ship_date  LIKE invoicehead.ship_date,
    fob_text  LIKE invoicehead.fob_text,
    prepaid_flag  LIKE invoicehead.prepaid_flag,
    com1_text  LIKE invoicehead.com1_text,
    com2_text  LIKE invoicehead.com2_text,
    cost_ind  LIKE invoicehead.cost_ind,
    currency_code  LIKE invoicehead.currency_code,
    conv_qty  LIKE invoicehead.conv_qty,
    inv_ind  LIKE invoicehead.inv_ind,
    prev_paid_amt  LIKE invoicehead.prev_paid_amt,
    acct_override_code  LIKE invoicehead.acct_override_code,
    price_tax_flag  LIKE invoicehead.price_tax_flag,
    contact_text  LIKE invoicehead.contact_text,
    tele_text  LIKE invoicehead.tele_text,
    invoice_to_ind  LIKE invoicehead.invoice_to_ind,
    territory_code  LIKE invoicehead.territory_code,
    mgr_code  LIKE invoicehead.mgr_code,
    area_code  LIKE invoicehead.area_code,
    cond_code  LIKE invoicehead.cond_code,
    scheme_amt  LIKE invoicehead.scheme_amt,
    jour_num  LIKE invoicehead.jour_num,
    post_date  LIKE invoicehead.post_date,
    carrier_code  LIKE invoicehead.carrier_code,
    manifest_num  LIKE invoicehead.manifest_num,
    bill_issue_ind  LIKE invoicehead.bill_issue_ind,
    contract_code  LIKE invoicehead.contract_code,
    stat_date  LIKE invoicehead.stat_date,
    country_code  LIKE invoicehead.country_code,
    tax_cert_text  LIKE invoicehead.tax_cert_text,
    ref_num  LIKE invoicehead.ref_num
	END RECORD	

	
########################################################################################
# FUNCTION invoiceHeadMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION invoiceHeadMenu()
	MENU
		ON ACTION "Import"
			CALL import_invoicehead()
		ON ACTION "Export"
			CALL unload_invoicehead()
		#ON ACTION "Import"
		#	CALL import_invoicehead()
		ON ACTION "Delete All"
			CALL delete_invoicehead_all()
		ON ACTION "Count"
			CALL getInvoiceHead_Count() --Count all invoicehead  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getInvoiceHead_Count()
#-------------------------------------------------------
# Returns the number of InvoiceHead  entries for the current company
########################################################################################
FUNCTION getInvoiceHead_Count()
	DEFINE ret_invoicehead_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_invoicehead  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM InvoiceHead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_invoicehead.DECLARE(sqlQuery) #CURSOR FOR getInvoiceHead 
	CALL c_invoicehead.SetResults(ret_invoicehead_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_invoicehead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_invoicehead_Count = -1
	ELSE
		CALL c_invoicehead.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product IN Parameter Sets:", trim(ret_invoicehead_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("IN Parameter Set Count", tempMsg,"info") 	
	END IF

	RETURN ret_invoicehead_Count
END FUNCTION


############################################
# FUNCTION import_invoicehead()
############################################
FUNCTION import_invoicehead()
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
	
	DEFINE rec_invoicehead  OF t_recInvoiceHead_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wInvoiceHead_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import IN Parameter List Data (table: invoicehead )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_invoicehead 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_invoicehead (
    cust_code CHAR(8),
    org_cust_code CHAR(8),
    inv_num INTEGER,
    ord_num INTEGER,
    purchase_code CHAR(30),
    job_code CHAR(8),
    inv_date DATE,
    entry_code CHAR(8),
    entry_date DATE,
    sale_code CHAR(8),
    term_code CHAR(3),
    disc_per DECIMAL(6,3),
    tax_code CHAR(3),
    tax_per DECIMAL(6,3),
    goods_amt DECIMAL(16,2),
    hand_amt DECIMAL(16,2),
    hand_tax_code CHAR(3),
    hand_tax_amt DECIMAL(16,2),
    freight_amt DECIMAL(16,2),
    freight_tax_code CHAR(3),
    freight_tax_amt DECIMAL(16,2),
    tax_amt DECIMAL(16,2),
    disc_amt DECIMAL(16,2),
    total_amt DECIMAL(16,2),
    cost_amt DECIMAL(16,2),
    paid_amt DECIMAL(16,2),
    paid_date DATE,
    disc_taken_amt DECIMAL(16,2),
    due_date DATE,
    disc_date DATE,
    expected_date DATE,
    year_num SMALLINT,
    period_num SMALLINT,
    on_state_flag CHAR(1),
    posted_flag CHAR(1),
    seq_num SMALLINT,
    line_num SMALLINT,
    printed_num SMALLINT,
    story_flag CHAR(1),
    rev_date DATE,
    rev_num SMALLINT,
    ship_code CHAR(8),
    name_text CHAR(30),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(20),
    state_code CHAR(6),
    post_code CHAR(10),
    country_text CHAR(40),
    ship1_text CHAR(60),
    ship2_text CHAR(60),
    ship_date DATE,
    fob_text CHAR(20),
    prepaid_flag CHAR(1),
    com1_text CHAR(30),
    com2_text CHAR(30),
    cost_ind CHAR(1),
    currency_code CHAR(3),
    conv_qty float,
    inv_ind CHAR(1),
    prev_paid_amt DECIMAL(16,2),
    acct_override_code CHAR(18),
    price_tax_flag CHAR(1),
    contact_text CHAR(30),
    tele_text CHAR(20),
    invoice_to_ind CHAR(1),
    territory_code CHAR(5),
    mgr_code CHAR(8),
    area_code CHAR(5),
    cond_code CHAR(3),
    scheme_amt DECIMAL(16,2),
    jour_num INTEGER,
    post_date DATE,
    carrier_code CHAR(3),
    manifest_num INTEGER,
    bill_issue_ind CHAR(1),
    contract_code CHAR(10),
    stat_date DATE,
    country_code CHAR(3),
    tax_cert_text CHAR(15),
    ref_num INTEGER
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_invoicehead 	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wInvoiceHead_Import WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wInvoiceHead_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/invoicehead-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("InvoiceHead Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_invoicehead 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_invoicehead 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_invoicehead 
			LET importReport = importReport, "Code:", trim(rec_invoicehead.inv_num) , "     -     cust_code:", trim(rec_invoicehead.cust_code), "\n"
					
			INSERT INTO invoicehead  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_invoicehead.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_invoicehead.inv_num) , "     -     cust_code:", trim(rec_invoicehead.cust_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wInvoiceHead_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_invoicehead_Rec(p_cmpy_code, p_inv_num)
#
# (cust_code,inv_num,cmpy_code)
########################################################
FUNCTION exist_invoicehead_Rec(p_cmpy_code, p_inv_num)
	DEFINE p_cmpy_code LIKE invoicehead.cmpy_code
	DEFINE p_inv_num LIKE invoicehead.inv_num
	DEFINE p_cust_code LIKE invoicehead.cust_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM invoicehead  
     WHERE cmpy_code = p_cmpy_code
     AND inv_num = p_inv_num

	DROP TABLE temp_invoicehead 
	CLOSE WINDOW wInvoiceHead_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_invoicehead()
###############################################################
FUNCTION unload_invoicehead (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/invoicehead-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM invoicehead ORDER BY cmpy_code, inv_num ASC
	
	LET tmpMsg = "All invoicehead data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("invoicehead Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_invoicehead_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_invoicehead_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE invoicehead.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wInvoiceHead_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Main Group (invoicehead) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing invoicehead table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM invoicehead
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table invoicehead!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table invoicehead where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wInvoiceHead_Import		
END FUNCTION	