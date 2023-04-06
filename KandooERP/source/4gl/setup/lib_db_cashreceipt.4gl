GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getcashreceipt_Count()
# FUNCTION cashreceipt_LookupFilterDataSourceCursor(pReccashreceipt_Filter)
# FUNCTION cashreceipt_LookupSearchDataSourceCursor(p_Reccashreceipt_Search)
# FUNCTION cashreceipt_LookupFilterDataSource(pReccashreceipt_Filter)
# FUNCTION cashreceipt_Lookup_filter(p_cash_num)
# FUNCTION import_cashreceipt()
# FUNCTION exist_cashreceipt_Rec(p_cmpy_code, p_cash_num)
# FUNCTION delete_cashreceipt_all()
# FUNCTION cashreceiptMenu()						-- Offer different OPTIONS of this library via a menu

# cashreceipt  record types
	#DEFINE t_reccashreceipt   
	#	TYPE AS RECORD
	#		cash_num LIKE cashreceipt.cash_num,
	#		ref1_text LIKE cashreceipt.ref1_text
	#	END RECORD 
#
#	DEFINE t_reccashreceipt_Filter  
#		TYPE AS RECORD
#			filter_cash_num LIKE cashreceipt.cash_num,
#			filter_ref1_text LIKE cashreceipt.ref1_text
#		END RECORD 
#
#	DEFINE t_reccashreceipt_Search  
#		TYPE AS RECORD
#			filter_any_field STRING
#		END RECORD 		

	DEFINE t_reccashreceipt_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE cashreceipt.cust_code,

    cash_num LIKE cashreceipt.cash_num,
    cheque_text LIKE cashreceipt.cheque_text,
    cash_acct_code LIKE cashreceipt.cash_acct_code,
    entry_code LIKE cashreceipt.entry_code,
    entry_date LIKE cashreceipt.entry_date,
    cash_date LIKE cashreceipt.cash_date,
    year_num LIKE cashreceipt.year_num,
    period_num LIKE cashreceipt.period_num,
    cash_amt LIKE cashreceipt.cash_amt,
    applied_amt LIKE cashreceipt.applied_amt,
    disc_amt LIKE cashreceipt.disc_amt,
    on_state_flag LIKE cashreceipt.on_state_flag,
    posted_flag LIKE cashreceipt.posted_flag,
    next_num LIKE cashreceipt.next_num,
    com1_text LIKE cashreceipt.com1_text,
    com2_text LIKE cashreceipt.com2_text,
    job_code LIKE cashreceipt.job_code,
    cash_type_ind LIKE cashreceipt.cash_type_ind,
    chq_date LIKE cashreceipt.chq_date,
    drawer_text LIKE cashreceipt.drawer_text,
    bank_text LIKE cashreceipt.bank_text,
    branch_text LIKE cashreceipt.branch_text,
    banked_flag LIKE cashreceipt.banked_flag,
    banked_date LIKE cashreceipt.banked_date,
    currency_code LIKE cashreceipt.currency_code,
    conv_qty LIKE cashreceipt.conv_qty,
    bank_code LIKE cashreceipt.bank_code,
    bank_currency_code LIKE cashreceipt.bank_currency_code,
    bank_dep_num LIKE cashreceipt.bank_dep_num,
    jour_num LIKE cashreceipt.jour_num,
    post_date LIKE cashreceipt.post_date,
    stat_date LIKE cashreceipt.stat_date,
    locn_code LIKE cashreceipt.locn_code,
    order_num LIKE cashreceipt.order_num,
    card_exp_date LIKE cashreceipt.card_exp_date,
    batch_no LIKE cashreceipt.batch_no
	END RECORD	

	
########################################################################################
# FUNCTION cashreceiptMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION cashreceiptMenu()
	MENU
		ON ACTION "Import"
			CALL import_cashreceipt()
		ON ACTION "Export"
			CALL unload_cashreceipt()
		#ON ACTION "Import"
		#	CALL import_cashreceipt()
		ON ACTION "Delete All"
			CALL delete_cashreceipt_all()
		ON ACTION "Count"
			CALL getcashreceipt_Count() --Count all cashreceipt  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getcashreceipt_Count()
#-------------------------------------------------------
# Returns the number of cashreceipt  entries for the current company
########################################################################################
FUNCTION getcashreceipt_Count()
	DEFINE ret_cashreceipt_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_cashreceipt  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM cashreceipt ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_cashreceipt.DECLARE(sqlQuery) #CURSOR FOR getcashreceipt 
	CALL c_cashreceipt.SetResults(ret_cashreceipt_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_cashreceipt.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_cashreceipt_Count = -1
	ELSE
		CALL c_cashreceipt.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product IN Parameter Sets:", trim(ret_cashreceipt_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("IN Parameter Set Count", tempMsg,"info") 	
	END IF

	RETURN ret_cashreceipt_Count
END FUNCTION


############################################
# FUNCTION import_cashreceipt()
############################################
FUNCTION import_cashreceipt()
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
	
	DEFINE rec_cashreceipt  OF t_reccashreceipt_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wcashreceipt_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import IN Parameter List Data (table: cashreceipt )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_cashreceipt 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_cashreceipt (
    cust_code CHAR(8),
    cash_num INTEGER,
    cheque_text CHAR(10),
    cash_acct_code CHAR(18),
    entry_code CHAR(8),
    entry_date DATE,
    cash_date DATE,
    year_num SMALLINT,
    period_num SMALLINT,
    cash_amt DECIMAL(16,2),
    applied_amt DECIMAL(16,2),
    disc_amt DECIMAL(16,2),
    on_state_flag CHAR(1),
    posted_flag CHAR(1),
    next_num SMALLINT,
    com1_text CHAR(30),
    com2_text CHAR(30),
    job_code INTEGER,
    cash_type_ind CHAR(1),
    chq_date DATE,
    drawer_text CHAR(20),
    bank_text CHAR(15),
    branch_text CHAR(20),
    banked_flag CHAR(1),
    banked_date DATE,
    currency_code CHAR(3),
    conv_qty float,
    bank_code CHAR(9),
    bank_currency_code CHAR(3),
    bank_dep_num INTEGER,
    jour_num INTEGER,
    post_date DATE,
    stat_date DATE,
    locn_code CHAR(3),
    order_num INTEGER,
    card_exp_date CHAR(4),
    batch_no SMALLINT
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_cashreceipt 	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wcashreceipt_Import WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wcashreceipt_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/cashreceipt-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("cashreceipt Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_cashreceipt 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_cashreceipt 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_cashreceipt 
			LET importReport = importReport, "Code:", trim(rec_cashreceipt.cash_num) , "     -     cust_code:", trim(rec_cashreceipt.cust_code), "\n"
					
			INSERT INTO cashreceipt  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_cashreceipt.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_cashreceipt.cash_num) , "     -     cust_code:", trim(rec_cashreceipt.cust_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wcashreceipt_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_cashreceipt_Rec(p_cmpy_code, p_cash_num)
#
# (cust_code,cash_num,cmpy_code)
########################################################
FUNCTION exist_cashreceipt_Rec(p_cmpy_code, p_cash_num, p_cust_code)
	DEFINE p_cmpy_code LIKE cashreceipt.cmpy_code
	DEFINE p_cash_num LIKE cashreceipt.cash_num
	DEFINE p_cust_code LIKE cashreceipt.cust_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM cashreceipt  
     WHERE cmpy_code = p_cmpy_code
     AND cash_num = p_cash_num
     AND cust_code = p_cust_code

	DROP TABLE temp_cashreceipt 
	CLOSE WINDOW wcashreceipt_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_cashreceipt()
###############################################################
FUNCTION unload_cashreceipt (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/cashreceipt-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM cashreceipt ORDER BY cmpy_code, cash_num ASC
	
	LET tmpMsg = "All cashreceipt data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("cashreceipt Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_cashreceipt_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_cashreceipt_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE cashreceipt.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcashreceipt_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Main Group (cashreceipt) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing cashreceipt table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM cashreceipt
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table cashreceipt!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table cashreceipt where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wcashreceipt_Import		
END FUNCTION	