#GLOBALS "lib_db_globals.4gl"
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"
# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getVendorCount()
# FUNCTION vendorLookupFilterDataSourceCursor(pRecVendorFilter)
# FUNCTION vendorLookupSearchDataSourceCursor(p_RecVendorSearch)
# FUNCTION VendorLookupFilterDataSource(pRecVendorFilter)
# FUNCTION vendorLookup_filter(pVendorCode)
# FUNCTION import_vendor()
# FUNCTION exist_vendorRec(p_cmpy_code, p_vend_code)
# FUNCTION delete_vendor_all()
# FUNCTION VendorMenu()						-- Offer different OPTIONS of this library via a menu

# Vendor record types

	
########################################################################################
# FUNCTION VendorMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION VendorMenu()
	MENU
		ON ACTION "Import"
			CALL import_vendor()
		ON ACTION "Export"
			CALL unload_vendor()
		#ON ACTION "Import"
		#	CALL import_vendor()
		ON ACTION "Delete All"
			CALL delete_vendor_all()
		ON ACTION "Count"
			CALL getVendorCount() --Count all vendor rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getVendorCount()
#-------------------------------------------------------
# Returns the number of Vendor entries for the current company
########################################################################################
FUNCTION getVendorCount()
	DEFINE ret_VendorCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Vendor CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Vendor ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Vendor.DECLARE(sqlQuery) #CURSOR FOR getVendor
	CALL c_Vendor.SetResults(ret_VendorCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Vendor.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_VendorCount = -1
	ELSE
		CALL c_Vendor.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vendor Types:", trim(ret_VendorCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_VendorCount
END FUNCTION

############################################
# FUNCTION import_vendor()
############################################
FUNCTION import_vendor()
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
	
	DEFINE rec_vendor OF t_rec_vendor_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	
	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wVendorImport WITH FORM "per/setup/lib_db_data_import_01"
      CALL winDecoration("lib_db_data_import_01")  -- albo  KD-752
		DISPLAY "Import Vendor Type List Data (table: vendor)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_vendor
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_vendor(
    #cmpy_code CHAR(2),
    vend_code CHAR(8),
    name_text CHAR(30),
    addr1_text CHAR(40),
    addr2_text CHAR(40),
    addr3_text CHAR(40),
    city_text CHAR(40),
    state_code CHAR(6),
    post_code CHAR(10),
    country_text CHAR(40),
    country_code CHAR(3),
    language_code CHAR(3),
    type_code CHAR(3),
    term_code CHAR(3),
    tax_code CHAR(3),
    setup_date DATE,
    last_mail_date DATE,
    tax_text CHAR(10),
    our_acct_code CHAR(21),
    contact_text CHAR(20),
    tele_text CHAR(20),
    extension_text CHAR(7),
    acct_text CHAR(20),
    limit_amt DECIMAL(16,2),
    bal_amt DECIMAL(16,2),
    highest_bal_amt DECIMAL(16,2),
    curr_amt DECIMAL(16,2),
    over1_amt DECIMAL(16,2),
    over30_amt DECIMAL(16,2),
    over60_amt DECIMAL(16,2),
    over90_amt DECIMAL(16,2),
    onorder_amt DECIMAL(16,2),
    avg_day_paid_num SMALLINT,
    last_debit_date DATE,
    last_po_date DATE,
    last_vouc_date DATE,
    last_payment_date DATE,
    next_seq_num INTEGER,
    hold_code CHAR(2),
    usual_acct_code CHAR(18),
    ytd_amt DECIMAL(16,2),
    min_ord_amt DECIMAL(16,2),
    drop_flag CHAR(1),
    finance_per CHAR(1),
    fax_text CHAR(20),
    currency_code CHAR(3),
    bank_acct_code CHAR(20),
    bank_code CHAR(9),
    pay_meth_ind CHAR(1),
    bkdetls_mod_flag CHAR(1),
    purchtype_code CHAR(3),
    po_var_per float,
    po_var_amt DECIMAL(16,2),
    def_exp_ind CHAR(1),
    backorder_flag CHAR(1),
    contra_cust_code CHAR(8),
    contra_meth_ind CHAR(1),
    vat_code CHAR(11),
    tax_incl_flag CHAR(1)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_vendor	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wVendorImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wVendorImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/vendor-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_vendor
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_vendor
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_vendor
			LET importReport = importReport, "Code:", trim(rec_vendor.vend_code) , "     -     Desc:", trim(rec_vendor.name_text), "\n"
					
			INSERT INTO vendor VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_vendor.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_vendor.vend_code) , "     -     Desc:", trim(rec_vendor.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wVendorImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_vendorRec(p_cmpy_code, p_vend_code)
########################################################
FUNCTION exist_vendorRec(p_cmpy_code, p_vend_code)
	DEFINE p_cmpy_code LIKE vendor.cmpy_code
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM vendor 
     WHERE cmpy_code = p_cmpy_code
     AND vend_code = p_vend_code

	DROP TABLE temp_vendor
	CLOSE WINDOW wVendorImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_vendor()
###############################################################
FUNCTION unload_vendor(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/vendor-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM vendor ORDER BY cmpy_code, vend_code ASC
	
	LET tmpMsg = "All vendor data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("vendor Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_vendor_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_vendor_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE vendor.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wvendorImport WITH FORM "per/setup/lib_db_data_import_01"
      CALL winDecoration("lib_db_data_import_01")  -- albo  KD-752
		DISPLAY "vendor Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing vendor table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM vendor
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table vendor!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table vendor where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wVendorImport		
END FUNCTION	