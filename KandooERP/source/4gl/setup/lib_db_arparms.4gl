GLOBALS "lib_db_globals.4gl"

# HUHO 08.05.2018 Created   (for setup)

	DEFINE t_recARParms_noCmpyId 
		TYPE AS RECORD 
	    #cmpy_code LIKE arparms.cmpy_code,
	    parm_code LIKE arparms.parm_code,
	    nextinv_num LIKE arparms.nextinv_num,
	    nextcash_num LIKE arparms.nextcash_num,
	    nextcredit_num LIKE arparms.nextcredit_num,
	    sales_jour_code LIKE arparms.sales_jour_code,
	    cash_jour_code LIKE arparms.cash_jour_code,
	    freight_tax_code LIKE arparms.freight_tax_code,
	    handling_tax_code LIKE arparms.handling_tax_code,
	    cash_acct_code LIKE arparms.cash_acct_code,
	    ar_acct_code LIKE arparms.ar_acct_code,
	    freight_acct_code LIKE arparms.freight_acct_code,
	    tax_acct_code LIKE arparms.tax_acct_code,
	    disc_acct_code LIKE arparms.disc_acct_code,
	    exch_acct_code LIKE arparms.exch_acct_code,
	    lab_acct_code LIKE arparms.lab_acct_code,
	    cust_age_date LIKE arparms.cust_age_date,
	    last_stmnt_date LIKE arparms.last_stmnt_date,
	    last_post_date LIKE arparms.last_post_date,
	    last_del_date LIKE arparms.last_del_date,
	    last_mail_date LIKE arparms.last_mail_date,
	    hist_flag LIKE arparms.hist_flag,
	    inven_tax_flag LIKE arparms.inven_tax_flag,
	    gl_detail_flag LIKE arparms.gl_detail_flag,
	    gl_flag LIKE arparms.gl_flag,
	    detail_to_gl_flag LIKE arparms.detail_to_gl_flag,
	    last_rec_date LIKE arparms.last_rec_date,
	    costings_ind LIKE arparms.costings_ind,
	    interest_per LIKE arparms.interest_per,
	    country_code LIKE arparms.country_code,
	    country_text LIKE arparms.country_text,
	    cred_amt LIKE arparms.cred_amt,
	    currency_code LIKE arparms.currency_code,
	    job_flag LIKE arparms.job_flag,
	    price_tax_flag LIKE arparms.price_tax_flag,
	    inv_ref1_text LIKE arparms.inv_ref1_text,
	    inv_ref2a_text LIKE arparms.inv_ref2a_text,
	    inv_ref2b_text LIKE arparms.inv_ref2b_text,
	    credit_ref1_text LIKE arparms.credit_ref1_text,
	    credit_ref2a_text LIKE arparms.credit_ref2a_text,
	    credit_ref2b_text LIKE arparms.credit_ref2b_text,
	    show_tax_flag LIKE arparms.show_tax_flag,
	    show_seg_flag LIKE arparms.show_seg_flag,
	    report_ord_flag LIKE arparms.report_ord_flag,
	    corp_drs_flag LIKE arparms.corp_drs_flag,
	    next_bank_dep_num LIKE arparms.next_bank_dep_num,
	    reason_code LIKE arparms.reason_code,
	    ref1_text LIKE arparms.ref1_text,
	    ref1_ind LIKE arparms.ref1_ind,
	    ref2_text LIKE arparms.ref2_text,
	    ref2_ind LIKE arparms.ref2_ind,
	    ref3_text LIKE arparms.ref3_text,
	    ref3_ind LIKE arparms.ref3_ind,
	    ref4_text LIKE arparms.ref4_text,
	    ref4_ind LIKE arparms.ref4_ind,
	    ref5_text LIKE arparms.ref5_text,
	    ref5_ind LIKE arparms.ref5_ind,
	    ref6_text LIKE arparms.ref6_text,
	    ref6_ind LIKE arparms.ref6_ind,
	    ref7_text LIKE arparms.ref7_text,
	    ref7_ind LIKE arparms.ref7_ind,
	    ref8_text LIKE arparms.ref8_text,
	    ref8_ind LIKE arparms.ref8_ind,
	    batch_cash_receipt LIKE arparms.batch_cash_receipt,
	    batch_no LIKE arparms.batch_no,
	    consolidate_flag LIKE arparms.consolidate_flag,
	    stmnt_ind LIKE arparms.stmnt_ind
	END RECORD	

	
########################################################################################
# FUNCTION aRParmsMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION aRParmsMenu()
	MENU
		ON ACTION "Import"
			CALL import_aRParms()
		ON ACTION "Export"
			CALL unload_aRParms(gl_setupRec.silentMode,gl_setupRec.unl_file_extension)
		ON ACTION "Delete All"
			CALL delete_aRParms_all()
		ON ACTION "Count"
			CALL getARParmsCount() --Count all aRParms rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getARParmsCount()
#-------------------------------------------------------
# Returns the number of ARParms entries for the current company
########################################################################################
FUNCTION getARParmsCount()
	DEFINE ret_ARParmsCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_ARParms CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM arparms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_ARParms.DECLARE(sqlQuery) #CURSOR FOR getARParms
	CALL c_ARParms.SetResults(ret_ARParmsCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_ARParms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ARParmsCount = -1
	ELSE
		CALL c_ARParms.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of ARParms Types:", trim(ret_ARParmsCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("ARParms Count", tempMsg,"info") 	
	END IF

	RETURN ret_ARParmsCount
END FUNCTION

############################################
# FUNCTION import_aRParms()
############################################
FUNCTION import_aRParms(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	
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
	
	DEFINE rec_aRParms OF t_recARParms_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wARParmsImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import ARParms List Data (table: arparms)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_arparms
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_arparms(
    #cmpy_code CHAR(2),
    parm_code CHAR(1),
    nextinv_num INTEGER,
    nextcash_num INTEGER,
    nextcredit_num INTEGER,
    sales_jour_code CHAR(10),
    cash_jour_code CHAR(10),
    freight_tax_code CHAR(3),
    handling_tax_code CHAR(3),
    cash_acct_code CHAR(18),
    ar_acct_code CHAR(18),
    freight_acct_code CHAR(18),
    tax_acct_code CHAR(18),
    disc_acct_code CHAR(18),
    exch_acct_code CHAR(18),
    lab_acct_code CHAR(18),
    cust_age_date DATE,
    last_stmnt_date DATE,
    last_post_date DATE,
    last_del_date DATE,
    last_mail_date DATE,
    hist_flag CHAR(1),
    inven_tax_flag CHAR(1),
    gl_detail_flag CHAR(1),
    gl_flag CHAR(1),
    detail_to_gl_flag CHAR(1),
    last_rec_date DATE,
    costings_ind CHAR(1),
    interest_per DECIMAL(5,2),
    country_code CHAR(3),
    country_text CHAR(40),
    cred_amt DECIMAL(10,2),
    currency_code CHAR(3),
    job_flag CHAR(1),
    price_tax_flag CHAR(1),
    inv_ref1_text CHAR(16),
    inv_ref2a_text CHAR(8),
    inv_ref2b_text CHAR(8),
    credit_ref1_text CHAR(16),
    credit_ref2a_text CHAR(8),
    credit_ref2b_text CHAR(8),
    show_tax_flag CHAR(1),
    show_seg_flag CHAR(1),
    report_ord_flag CHAR(1),
    corp_drs_flag CHAR(1),
    next_bank_dep_num INTEGER,
    reason_code CHAR(3),
    ref1_text CHAR(20),
    ref1_ind CHAR(1),
    ref2_text CHAR(20),
    ref2_ind CHAR(1),
    ref3_text CHAR(20),
    ref3_ind CHAR(1),
    ref4_text CHAR(20),
    ref4_ind CHAR(1),
    ref5_text CHAR(20),
    ref5_ind CHAR(1),
    ref6_text CHAR(20),
    ref6_ind CHAR(1),
    ref7_text CHAR(20),
    ref7_ind CHAR(1),
    ref8_text CHAR(20),
    ref8_ind CHAR(1),
    batch_cash_receipt CHAR(1),
    batch_no SMALLINT,
    consolidate_flag CHAR(1),
    stmnt_ind CHAR(1)


		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_arparms	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wARParmsImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wARParmsImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/arparms-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_arparms
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_arparms
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_aRParms
			LET importReport = importReport, "Code:", trim(rec_aRParms.parm_code) , "     -     Desc:", trim(rec_aRParms.parm_code), "\n"
					
			INSERT INTO arparms VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_aRParms.*
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_aRParms.parm_code) , "     -     Desc:", trim(rec_aRParms.parm_code), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wARParmsImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_aRParmsRec(p_cmpy_code, p_parm_code)
########################################################
FUNCTION exist_aRParmsRec(p_cmpy_code, p_parm_code)
	DEFINE p_cmpy_code LIKE arparms.cmpy_code
	DEFINE p_parm_code LIKE arparms.parm_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM arparms 
     WHERE cmpy_code = p_cmpy_code
     #AND parm_code = p_parm_code

	DROP TABLE temp_arparms
	CLOSE WINDOW wARParmsImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_aRParms()
###############################################################
FUNCTION unload_aRParms(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = trim(getCurrentUser_cmpy_code())
	LET unloadFile = "unl/arparms"	
	LET unloadFile1 = trim(unloadFile), "-" ,trim(gl_setupRec_default_company.country_code), "_", currentCompany, ".", p_fileExtension
	UNLOAD TO unloadFile1
		SELECT  
			#cmpy_code,
	    parm_code,
	    nextinv_num,
	    nextcash_num,
	    nextcredit_num,
	    sales_jour_code,
	    cash_jour_code,
	    freight_tax_code,
	    handling_tax_code,
	    cash_acct_code,
	    ar_acct_code,
	    freight_acct_code,
	    tax_acct_code,
	    disc_acct_code,
	    exch_acct_code,
	    lab_acct_code,
	    cust_age_date,
	    last_stmnt_date,
	    last_post_date,
	    last_del_date,
	    last_mail_date,
	    hist_flag,
	    inven_tax_flag,
	    gl_detail_flag,
	    gl_flag,
	    detail_to_gl_flag,
	    last_rec_date,
	    costings_ind,
	    interest_per,
	    country_code,
	    country_text,
	    cred_amt,
	    currency_code,
	    job_flag,
	    price_tax_flag,
	    inv_ref1_text,
	    inv_ref2a_text,
	    inv_ref2b_text,
	    credit_ref1_text,
	    credit_ref2a_text,
	    credit_ref2b_text,
	    show_tax_flag,
	    show_seg_flag,
	    report_ord_flag,
	    corp_drs_flag,
	    next_bank_dep_num,
	    reason_code,
	    ref1_text,
	    ref1_ind,
	    ref2_text,
	    ref2_ind,
	    ref3_text,
	    ref3_ind,
	    ref4_text,
	    ref4_ind,
	    ref5_text,
	    ref5_ind,
	    ref6_text,
	    ref6_ind,
	    ref7_text,
	    ref7_ind,
	    ref8_text,
	    ref8_ind,
	    batch_cash_receipt,
	    batch_no,
	    consolidate_flag,
	    stmnt_ind

		FROM arparms
		WHERE cmpy_code = currentCompany
		ORDER BY parm_code ASC
		
	LET unloadFile2 = 	unloadFile CLIPPED ,".", p_fileExtension
	UNLOAD TO unloadFile2 
	SELECT * FROM arparms ORDER BY cmpy_code,parm_code ASC	
		
	
	LET tmpMsg = "All aRParms (ORDER processing parameters) data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("arparms Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION


###############################################################
# FUNCTION delete_aRParms_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_aRParms_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE arparms.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW waRParmsImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "arparms (Order Processing Parameters) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing aRParms table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM arparms
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table aRParms!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table aRParms where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wARParmsImport		
END FUNCTION	