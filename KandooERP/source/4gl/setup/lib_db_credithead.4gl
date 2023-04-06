GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getcredithead_Count()
# FUNCTION credithead_LookupFilterDataSourceCursor(pReccredithead_Filter)
# FUNCTION credithead_LookupSearchDataSourceCursor(p_Reccredithead_Search)
# FUNCTION credithead_LookupFilterDataSource(pReccredithead_Filter)
# FUNCTION credithead_Lookup_filter(p_cred_num)
# FUNCTION import_credithead()
# FUNCTION exist_credithead_Rec(p_cmpy_code, p_cred_num)
# FUNCTION delete_credithead_all()
# FUNCTION creditheadMenu()						-- Offer different OPTIONS of this library via a menu

# credithead  record types
	#DEFINE t_reccredithead   
	#	TYPE AS RECORD
	#		cred_num LIKE credithead.cred_num,
	#		ref1_text LIKE credithead.ref1_text
	#	END RECORD 
#
#	DEFINE t_reccredithead_Filter  
#		TYPE AS RECORD
#			filter_cred_num LIKE credithead.cred_num,
#			filter_ref1_text LIKE credithead.ref1_text
#		END RECORD 
#
#	DEFINE t_reccredithead_Search  
#		TYPE AS RECORD
#			filter_any_field STRING
#		END RECORD 		

	DEFINE t_reccredithead_noCmpyId 
		TYPE AS RECORD 
    cust_code LIKE credithead.cust_code,
    org_cust_code LIKE credithead.org_cust_code,
    cred_num LIKE credithead.cred_num,
    rma_num LIKE credithead.rma_num,
    cred_text LIKE credithead.cred_text,
    job_code LIKE credithead.job_code,
    entry_code LIKE credithead.entry_code,
    entry_date LIKE credithead.entry_date,
    cred_date LIKE credithead.cred_date,
    sale_code LIKE credithead.sale_code,
    tax_code LIKE credithead.tax_code,
    tax_per LIKE credithead.tax_per,
    goods_amt LIKE credithead.goods_amt,
    hand_amt LIKE credithead.hand_amt,
    hand_tax_code LIKE credithead.hand_tax_code,
    hand_tax_amt LIKE credithead.hand_tax_amt,
    freight_amt LIKE credithead.freight_amt,
    freight_tax_code LIKE credithead.freight_tax_code,
    freight_tax_amt LIKE credithead.freight_tax_amt,
    tax_amt LIKE credithead.tax_amt,
    total_amt LIKE credithead.total_amt,
    cost_amt LIKE credithead.cost_amt,
    appl_amt LIKE credithead.appl_amt,
    disc_amt LIKE credithead.disc_amt,
    year_num LIKE credithead.year_num,
    period_num LIKE credithead.period_num,
    on_state_flag LIKE credithead.on_state_flag,
    posted_flag LIKE credithead.posted_flag,
    next_num LIKE credithead.next_num,
    line_num LIKE credithead.line_num,
    printed_num LIKE credithead.line_num,
    com1_text LIKE credithead.com1_text,
    com2_text LIKE credithead.com2_text,
    rev_date LIKE credithead.rev_date,
    rev_num LIKE credithead.rev_num,
    cost_ind LIKE credithead.cost_ind,
    currency_code LIKE credithead.currency_code,
    conv_qty LIKE credithead.conv_qty,
    cred_ind LIKE credithead.cred_ind,
    acct_override_code LIKE credithead.acct_override_code,
    price_tax_flag LIKE credithead.price_tax_flag,
    reason_code LIKE credithead.reason_code,
    jour_num LIKE credithead.jour_num,
    post_date LIKE credithead.post_date,
    bill_issue_ind LIKE credithead.bill_issue_ind,
    stat_date LIKE credithead.stat_date,
    address_to_ind LIKE credithead.address_to_ind,
    territory_code LIKE credithead.territory_code,
    mgr_code LIKE credithead.mgr_code,
    area_code LIKE credithead.area_code,
    cond_code LIKE credithead.cond_code,
    tax_cert_text LIKE credithead.tax_cert_text,
    ref_num LIKE credithead.ref_num

	END RECORD	

	
########################################################################################
# FUNCTION creditheadMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION creditheadMenu()
	MENU
		ON ACTION "Import"
			CALL import_credithead()
		ON ACTION "Export"
			CALL unload_credithead(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_credithead_all()
		ON ACTION "Count"
			CALL getcredithead_Count() --Count all credithead  rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getcredithead_Count()
#-------------------------------------------------------
# Returns the number of credithead  entries for the current company
########################################################################################
FUNCTION getcredithead_Count()
	DEFINE ret_credithead_Count SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_credithead  CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM credithead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_credithead.DECLARE(sqlQuery) #CURSOR FOR getcredithead 
	CALL c_credithead.SetResults(ret_credithead_Count)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_credithead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_credithead_Count = -1
	ELSE
		CALL c_credithead.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product IN Parameter Sets:", trim(ret_credithead_Count) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("IN Parameter Set Count", tempMsg,"info") 	
	END IF

	RETURN ret_credithead_Count
END FUNCTION


############################################
# FUNCTION import_credithead()
############################################
FUNCTION import_credithead()
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
	
	DEFINE rec_credithead  OF t_reccredithead_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wcredithead_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import IN Parameter List Data (table: credithead )" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_credithead 
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_credithead (
    #cmpy_code CHAR(2),
    cust_code CHAR(8),
    org_cust_code CHAR(8),
    cred_num INTEGER,
    rma_num INTEGER,
    cred_text CHAR(10),
    job_code CHAR(8),
    entry_code CHAR(8),
    entry_date DATE,
    cred_date DATE,
    sale_code CHAR(8),
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
    total_amt DECIMAL(16,2),
    cost_amt DECIMAL(16,2),
    appl_amt DECIMAL(16,2),
    disc_amt DECIMAL(16,2),
    year_num SMALLINT,
    period_num SMALLINT,
    on_state_flag CHAR(1),
    posted_flag CHAR(1),
    next_num SMALLINT,
    line_num SMALLINT,
    printed_num SMALLINT,
    com1_text CHAR(30),
    com2_text CHAR(30),
    rev_date DATE,
    rev_num SMALLINT,
    cost_ind CHAR(1),
    currency_code CHAR(3),
    conv_qty float,
    cred_ind CHAR(1),
    acct_override_code CHAR(18),
    price_tax_flag CHAR(1),
    reason_code CHAR(3),
    jour_num INTEGER,
    post_date DATE,
    bill_issue_ind CHAR(1),
    stat_date DATE,
    address_to_ind CHAR(1),
    territory_code CHAR(5),
    mgr_code CHAR(8),
    area_code CHAR(5),
    cond_code CHAR(3),
    tax_cert_text CHAR(15),
    ref_num INTEGER
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_credithead 	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wcredithead_Import WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wcredithead_Import
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/credithead-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("credithead Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_credithead 
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_credithead 
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_credithead 
			LET importReport = importReport, "Code:", trim(rec_credithead.cred_num) , "     -     cust_code:", trim(rec_credithead.cust_code), "\n"
					
			INSERT INTO credithead  VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_credithead.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_credithead.cred_num) , "     -     cust_code:", trim(rec_credithead.cust_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wcredithead_Import
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_credithead_Rec(p_cmpy_code, p_cred_num)
#
# (cust_code,cred_num,cmpy_code)
########################################################
FUNCTION exist_credithead_Rec(p_cmpy_code, p_cred_num)
	DEFINE p_cmpy_code LIKE credithead.cmpy_code
	DEFINE p_cred_num LIKE credithead.cred_num
	DEFINE p_cust_code LIKE credithead.cust_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM credithead  
     WHERE cmpy_code = p_cmpy_code
     AND cred_num = p_cred_num

	DROP TABLE temp_credithead 
	CLOSE WINDOW wcredithead_Import
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_credithead()
###############################################################
FUNCTION unload_credithead (p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()	
	LET unloadFile = "unl/credithead-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()	
	UNLOAD TO unloadFile1 
		SELECT 
    #cust_code,
    org_cust_code,
    cred_num,
    rma_num,
    cred_text,
    job_code,
    entry_code,
    entry_date,
    cred_date,
    sale_code,
    tax_code,
    tax_per,
    goods_amt,
    hand_amt,
    hand_tax_code,
    hand_tax_amt,
    freight_amt,
    freight_tax_code,
    freight_tax_amt,
    tax_amt,
    total_amt,
    cost_amt,
    appl_amt,
    disc_amt,
    year_num,
    period_num,
    on_state_flag,
    posted_flag,
    next_num,
    line_num,
    printed_num,
    com1_text,
    com2_text,
    rev_date,
    rev_num,
    cost_ind,
    currency_code,
    conv_qty,
    cred_ind,
    acct_override_code,
    price_tax_flag,
    reason_code,
    jour_num,
    post_date,
    bill_issue_ind,
    stat_date,
    address_to_ind,
    territory_code,
    mgr_code,
    area_code,
    cond_code,
    tax_cert_text,
    ref_num
		
		FROM credithead ORDER BY cred_num, org_cust_code ASC

	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
		SELECT * FROM credithead ORDER BY cmpy_code, cred_num, org_cust_code ASC
	
	LET tmpMsg = "All credithead data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("credithead Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_credithead_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_credithead_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE credithead.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcredithead_Import WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Product Main Group (credithead) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing credithead table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM credithead
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table credithead!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table credithead where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wcredithead_Import		
END FUNCTION	