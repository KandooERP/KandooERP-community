GLOBALS "lib_db_globals.4gl"


###############################################################
# FUNCTION setupAP_Parameter()
###############################################################
FUNCTION setupAP_Parameter()

	OPEN WINDOW wAP_parameter WITH FORM "per/setup/setup_ap_parameter"
	CALL updateConsole()	
	CALL read_apparms_from_tempTable() #Read data FROM temp table

	CALL comboList_journalCode("pur_jour_code",0,0,0,3)	
	CALL comboList_journalCode("chq_jour_code",0,0,0,3)

	CALL comboList_coa_account("pay_acct_code",0,0,0,3)  --COA
	CALL comboList_coa_account("bank_acct_code",0,0,0,3)  --COA
	CALL comboList_coa_account("freight_acct_code",0,0,0,3)  --COA
	CALL comboList_coa_account("salestax_acct_code",0,0,0,3)  --COA
	CALL comboList_coa_account("disc_acct_code",0,0,0,3)  --COA
	CALL comboList_coa_account("exch_acct_code",0,0,0,3)  --COA
	

	


	
	#CALL comboList_banktype("type_code",0,1,0,2)  --Bank Type
	#CALL comboList_currency("currency_code",0,0,0,3)
#
	#CALL comboList_coa_account("acct_code",0,0,0,3)  --COA

	INPUT BY NAME
			gl_apparms.next_vouch_num,
			gl_apparms.next_deb_num,
			gl_apparms.pur_jour_code,
			gl_apparms.chq_jour_code,
			gl_apparms.pay_acct_code,
			gl_apparms.bank_acct_code,
			gl_apparms.freight_acct_code,
			gl_apparms.salestax_acct_code,
			gl_apparms.disc_acct_code,
			gl_apparms.exch_acct_code,
			
			gl_apparms.gl_flag,
			gl_apparms.hist_flag,
			gl_apparms.vouch_approve_flag,
			gl_apparms.report_ord_flag
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

	CALL write_apparms_to_tempTable()
				
	CLOSE WINDOW wAP_parameter				

END FUNCTION

#################################################################



###############################################################
# FUNCTION FUNCTION read_apparms_from_db()
# AR Accounts Payable Parameters
# This function will only be called at installer startup/launch
###############################################################
FUNCTION read_apparms_from_db()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM apparms 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  AND parm_code = "1"

			IF recCount = 1 THEN  --table data does exist in DB AND we will load it
				LET retState = 1
				

				SELECT * INTO gl_apparms.*  #global record 
				FROM apparms
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  	AND parm_code = "1"

				INSERT INTO temp_apparms	#temp table 
		  	VALUES (gl_apparms.*)

			ELSE
				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION

###############################################################
# FUNCTION write_apparms_to_db()
###############################################################
FUNCTION write_apparms_to_db()
	DEFINE recCount SMALLINT

	SELECT COUNT(*) INTO recCount FROM apparms
	WHERE cmpy_code = gl_apparms.cmpy_code
	AND parm_code = gl_apparms.parm_code
 
	IF recCount = 0 THEN
		INSERT INTO apparms VALUES(gl_apparms.*)
	END IF
	
END FUNCTION

###############################################################
# FUNCTION read_apparms_from_tempTable()
# AR Accounts Payable Parameters
# This function will be called prior TO INPUT
###############################################################
FUNCTION read_apparms_from_tempTable()
	DEFINE recCount, retState SMALLINT

			# 01 - Check if table data exist in the Database
		  SELECT COUNT(*) INTO recCount FROM temp_apparms 
		  WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  AND parm_code = "1"

			IF recCount = 1 THEN  --table data does exist in tempTable/DB AND we will load it
				LET retState = 1				

				SELECT * INTO gl_apparms.*  #global record 
				FROM temp_apparms
		  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		  	AND parm_code = "1"

			ELSE
				LET gl_apparms.cmpy_code = gl_setupRec_default_company.cmpy_code
				LET gl_apparms.parm_code = "1"
			
				LET gl_apparms.next_vouch_num = 1000
				LET gl_apparms.next_deb_num = 1000
				LET gl_apparms.pur_jour_code = "PJ"
				LET gl_apparms.chq_jour_code = "CP"
			
				LET gl_apparms.pay_acct_code = "2100"
				LET gl_apparms.bank_acct_code= "1200"
				LET gl_apparms.freight_acct_code = "5100"
				LET gl_apparms.salestax_acct_code = "2201"
				LET gl_apparms.disc_acct_code = "5009"
				LET gl_apparms.exch_acct_code = "7906"
			
				LET gl_apparms.last_chq_prnt_date = gl_setupRec.fiscal_startDate
				LET gl_apparms.last_post_date = gl_setupRec.fiscal_startDate
				LET gl_apparms.last_aging_date = gl_setupRec.fiscal_startDate
				LET gl_apparms.last_del_date = gl_setupRec.fiscal_startDate
				LET gl_apparms.last_mail_date = gl_setupRec.fiscal_startDate
			
				LET gl_apparms.gl_flag = "Y"
				LET gl_apparms.hist_flag = "Y"
				LET gl_apparms.vouch_approve_flag = "N"
				LET gl_apparms.report_ord_flag = "C"
			
				LET gl_apparms.gl_detl_flag = "N"
				LET gl_apparms.distrib_style = ""
			
				#Write default data TO temp table / will only happen max 1 times
				CALL write_apparms_to_tempTable()
				
				LET retState = 0
			END IF		  

	RETURN retState
END FUNCTION

###############################################################
# FUNCTION write_apparms_to_tempTable()
# AR Accounts Payable Parameters
# This function will only be called AFTER INPUT
###############################################################
FUNCTION write_apparms_to_tempTable()
	DEFINE recCount, retState SMALLINT

  SELECT COUNT(*) INTO recCount 
  FROM temp_apparms
	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
	AND parm_code = "1"
   
  IF recCount <> 0 THEN  #delete record FROM tempTable
  	DELETE FROM temp_apparms
  	WHERE cmpy_code = gl_setupRec_default_company.cmpy_code
		AND parm_code = "1"
  END IF
  
  INSERT INTO temp_apparms	#Insert record TO temp table 
	VALUES (gl_apparms.*)

END FUNCTION
