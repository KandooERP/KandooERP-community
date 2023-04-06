GLOBALS "lib_db_globals.4gl"

###############################################################
# FUNCTION setupAR_Parameter()
###############################################################
FUNCTION setupAR_Parameter()

	OPEN WINDOW wAR_parameter WITH FORM "per/setup/setup_ar_parameter"
	CALL updateConsole()
	CALL read_arparms_from_tempTable()  # import data FROM tempTable
	CALL read_arparmext_from_tempTable()  # import data FROM tempTable

	LET gl_arparms.cmpy_code = gl_setupRec_default_company.cmpy_code
	LET gl_arparms.country_code = gl_setupRec_default_company.country_code
	LET gl_arparms.country_text = gl_setupRec_default_company.country_text
	LET gl_arparms.currency_code = gl_setupRec_default_company.curr_code

	CALL comboList_journalCode("sales_jour_code",0,0,0,3)	
	CALL comboList_journalCode("cash_jour_code",0,0,0,3)		
	CALL comboList_coa_account("ar_acct_code",0,0,0,3)  --, pVariable,pSort,pSingle,pHint) 
	CALL comboList_coa_account("cash_acct_code",0,0,0,3)
	CALL comboList_coa_account("freight_acct_code",0,0,0,3)
	CALL comboList_coa_account("lab_acct_code",0,0,0,3)

	CALL comboList_coa_account("int_acct_code",0,0,0,3)
	CALL comboList_coa_account("writeoff_acct_code",0,0,0,3)		

	CALL comboList_coa_account("tax_acct_code",0,0,0,3)
	CALL comboList_coa_account("disc_acct_code",0,0,0,3)
	CALL comboList_coa_account("exch_acct_code",0,0,0,3)

	CALL comboList_currency("currency_code",0,0,0,3)
	CALL comboList_creditReason("reason_code",0,0,0,3)
	CALL comboList_bankStatementType("stmnt_ind",0,0,0,3)			
	CALL comboList_CustomerReportOrder("report_ord_flag",0,1,0,2)			


	INPUT BY NAME
	
		gl_arparms.sales_jour_code,
		gl_arparms.cash_jour_code,
			
		gl_arparms.cash_acct_code,
		gl_arparms.ar_acct_code,
		gl_arparms.freight_acct_code,
		gl_arparms.tax_acct_code,
		gl_arparms.disc_acct_code,
		gl_arparms.exch_acct_code,
		gl_arparms.lab_acct_code,
				
		gl_arparmext.int_acct_code,  --different table
		gl_arparmext.writeoff_acct_code,  --different table		
		
		gl_arparms.cred_amt,
		gl_arparms.reason_code,
		gl_arparms.stmnt_ind,
		gl_arparms.next_bank_dep_num,
		gl_arparms.report_ord_flag,
		
		gl_arparms.consolidate_flag,	
		gl_arparms.corp_drs_flag,		
		gl_arparms.show_tax_flag,
		gl_arparms.show_seg_flag,
		gl_arparms.gl_flag,
		gl_arparms.detail_to_gl_flag
	
		WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		ON ACTION CANCEL
			CALL interrupt_installation()

		ON ACTION "Previous"
			LET mdNavigatePrevious = TRUE
			EXIT INPUT
			
		ON ACTION ACCEPT
			EXIT INPUT		

		END INPUT			


	IF int_flag = 1 THEN
		CALL interrupt_installation()
	ELSE
		IF mdNavigatePrevious THEN
			LET step_num = step_num - 1
			LET mdNavigatePrevious = FALSE
		ELSE
			LET step_num = step_num + 1
		END IF
	END IF

	CALL write_arparms_to_tempTable()	
	CALL write_arparmext_to_tempTable()	
				
	CLOSE WINDOW wAR_parameter				

END FUNCTION


###############################################################
# FUNCTION read_arparms_from_tempTable()
# AR Accounts Receivable Parameters
# This function will be called prior TO INPUT
###############################################################
FUNCTION read_arparms_from_tempTable()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM temp_arparms 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  AND parm_code = "1"

			IF recCount = 1 THEN  --table data does exist in DB AND we will load it
				LET retState = 1

				SELECT * INTO gl_arparms.*  #global record 
				FROM temp_arparms
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  	AND parm_code = "1"

			ELSE	#Assign Default VALUES AND store in temp table
			
				LET gl_arparms.parm_code = "1"
			
				LET gl_arparms.nextinv_num = 1000
				LET gl_arparms.nextcash_num = 1000
				LET gl_arparms.nextcredit_num = 1000
				
				LET gl_arparms.sales_jour_code = "SJ"
				LET gl_arparms.cash_jour_code = "CB"
				
				
				LET gl_arparms.freight_tax_code = ""
				LET gl_arparms.handling_tax_code = ""
				LET gl_arparms.cash_acct_code = "1200"
				LET gl_arparms.ar_acct_code = "1100"
				LET gl_arparms.freight_acct_code = "4905"
				LET gl_arparms.tax_acct_code = "2200"
				LET gl_arparms.disc_acct_code = "4009"
				LET gl_arparms.exch_acct_code = "2200"
				LET gl_arparms.lab_acct_code = "4905"

				
				
				LET gl_arparms.cust_age_date = gl_setupRec.fiscal_startDate
				LET gl_arparms.last_stmnt_date = gl_setupRec.fiscal_startDate
				LET gl_arparms.last_post_date = gl_setupRec.fiscal_startDate
				LET gl_arparms.last_del_date = gl_setupRec.fiscal_startDate
				LET gl_arparms.last_mail_date = gl_setupRec.fiscal_startDate
				
				LET gl_arparms.hist_flag = ""
				LET gl_arparms.inven_tax_flag = ""
				LET gl_arparms.gl_detail_flag = ""
				LET gl_arparms.gl_flag = "Y"
				LET gl_arparms.detail_to_gl_flag = "Y"
				LET gl_arparms.last_rec_date = gl_setupRec.fiscal_startDate
				LET gl_arparms.costings_ind = ""
			
				LET gl_arparms.interest_per = ""
			
				LET gl_arparms.cred_amt = 10000.00
			
				LET gl_arparms.job_flag = ""
				LET gl_arparms.price_tax_flag = ""
				LET gl_arparms.inv_ref1_text = "Purchase Code"
				LET gl_arparms.inv_ref2a_text = "Purchase"
				LET gl_arparms.inv_ref2b_text = "  Code"
				LET gl_arparms.credit_ref1_text = "Authorise Code"
				LET gl_arparms.credit_ref2a_text = "  Auth."
				LET gl_arparms.credit_ref2b_text = "  Code"
				LET gl_arparms.show_tax_flag = "Y"
				LET gl_arparms.show_seg_flag = "Y"
				LET gl_arparms.report_ord_flag = "A"
				LET gl_arparms.corp_drs_flag = "Y"
				
				LET gl_arparms.next_bank_dep_num = 1
			
				LET gl_arparms.reason_code = "COR"
				LET gl_arparms.ref1_text = ""
				LET gl_arparms.ref1_ind = ""
				LET gl_arparms.ref2_text = ""
				LET gl_arparms.ref2_ind = ""
				LET gl_arparms.ref3_text = ""
				LET gl_arparms.ref3_ind = ""
				LET gl_arparms.ref4_text = ""
				LET gl_arparms.ref4_ind = ""
				LET gl_arparms.ref5_text = ""
				LET gl_arparms.ref5_ind = ""
				LET gl_arparms.ref6_text = ""
				LET gl_arparms.ref6_ind = ""
				LET gl_arparms.ref7_text = ""
				LET gl_arparms.ref7_ind = ""
				LET gl_arparms.ref8_text = ""
				LET gl_arparms.ref8_ind = ""
				LET gl_arparms.batch_cash_receipt = ""
				
				LET gl_arparms.batch_no = 0
				
				LET gl_arparms.consolidate_flag = "Y"
				LET gl_arparms.stmnt_ind = "O"
				
				CALL write_arparms_to_tempTable()  #write default data TO temp table

				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION


###############################################################
# FUNCTION read_arparmext_from_tempTable()
# AR Accounts Receivable Parameters EXTENSION  (needs 2 records...)
# This function will be called prior TO INPUT
###############################################################
FUNCTION read_arparmext_from_tempTable()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM temp_arparmext 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code


			IF recCount = 1 THEN  --table data does exist in DB AND we will load it
				LET retState = 1

				SELECT * INTO gl_arparmext.*  #global record 
				FROM temp_arparmext
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code


			ELSE	#Assign Default VALUES AND store in temp table

				LET gl_arparmext.last_int_date = gl_setupRec.fiscal_startDate
				LET gl_arparmext.int_acct_code = "4010"
				LET gl_arparmext.writeoff_acct_code ="8100"
				LET gl_arparmext.last_writeoff_date = gl_setupRec.fiscal_startDate
					
				CALL write_arparmext_to_tempTable()  #write default data TO temp table

				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION

###############################################################
# FUNCTION FUNCTION read_arparms_from_db()
# AR Accounts Receivable Parameters
# This function will only be called at installer startup/launch
###############################################################
FUNCTION read_arparms_from_db()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM arparms 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  AND parm_code = "1"

			IF recCount = 1 THEN  --table data does exist in DB AND we will load it
				LET retState = 1
				

				SELECT * INTO gl_arparms.*  #global record 
				FROM arparms
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  	AND parm_code = "1"

				INSERT INTO temp_arparms	#temp table 
		  	VALUES (gl_arparms.*)

			ELSE
				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION

###############################################################
# FUNCTION write_arparmext_to_db()
###############################################################
FUNCTION write_arparmext_to_db()
	DEFINE recCount SMALLINT

#@debug @huho
call fgl_winmessage("check this","table IS empty...AP.exe","info")
 
	SELECT COUNT(*) INTO recCount FROM arparmext
	WHERE cmpy_code = gl_arparmext.cmpy_code
 
	IF recCount = 0 THEN
		INSERT INTO arparmext VALUES(gl_arparmext.*)
	END IF
	
END FUNCTION

###############################################################
# FUNCTION write_arparms_to_db()
###############################################################
FUNCTION write_arparms_to_db()
	DEFINE recCount SMALLINT

	SELECT COUNT(*) INTO recCount FROM arparms
	WHERE cmpy_code = gl_arparms.cmpy_code
	AND parm_code = gl_arparms.parm_code
 
	IF recCount = 0 THEN
		INSERT INTO arparms VALUES(gl_arparms.*)
	END IF
	
END FUNCTION


###############################################################
# FUNCTION write_arparmext_to_tempTable()
# AR Accounts Receivable Parameters
# This function will only be called AFTER INPUT
###############################################################
FUNCTION write_arparmext_to_tempTable()
	DEFINE recCount, retState SMALLINT

  SELECT COUNT(*) INTO recCount 
  FROM temp_arparmext
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code

   
  IF recCount <> 0 THEN  #delete record FROM tempTable
  	DELETE FROM temp_arparmext
  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code

  END IF
  
  INSERT INTO temp_arparmext	#Insert record TO temp table 
	VALUES (gl_arparmext.*)

END FUNCTION

###############################################################
# FUNCTION write_arparms_to_tempTable()
# AR Accounts Receivable Parameters
# This function will only be called AFTER INPUT
###############################################################
FUNCTION write_arparms_to_tempTable()
	DEFINE recCount, retState SMALLINT

  SELECT COUNT(*) INTO recCount 
  FROM temp_arparms
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	AND parm_code = "1"
   
  IF recCount <> 0 THEN  #delete record FROM tempTable
  	DELETE FROM temp_arparms
  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		AND parm_code = "1"
  END IF
  
  INSERT INTO temp_arparms	#Insert record TO temp table 
	VALUES (gl_arparms.*)

END FUNCTION
