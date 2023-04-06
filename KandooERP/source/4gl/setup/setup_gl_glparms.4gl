GLOBALS "lib_db_globals.4gl"


########################################################
# FUNCTION glSetup()                           --Step 02
########################################################
FUNCTION glSetup(mdNewInst)
	DEFINE mdNewInst BOOLEAN
	
	DEFINE fiscalMonth, fiscalFactor SMALLINT
	
	OPEN WINDOW wGlSetup WITH FORM "per/setup/setup_gl_config"
	CALL updateConsole()


	IF mdNewInst THEN  --new installation / delete existing stuff
	
		#Default = single organisation without sub-organisations
		LET gl_setupRec_admin_rec_kandoouser.acct_mask_code = "????"  --otherwise "??.????"	
	
	ELSE  --UPDATE / read existing data

		#Default = single organisation without sub-organisations
		SELECT acct_mask_code INTO gl_setupRec_admin_rec_kandoouser.acct_mask_code FROM kandoouser
			WHERE sign_on_code = "Admin"
	
	END IF


	#OPEN WINDOW wGlSetup WITH FORM "per/setup/qxt_general_ledger"

	#DISPLAY "{CONTEXT}/public/querix/icon/svg/24/ic_done_24px.svg" TO lb_step01_done
	#CALL updateConsole()


	
	#Default industry type
	LET gl_setupRec.industry_type = "AF"
	#Fiscal Year init
	LET gl_setupRec.fiscal_startDate = TODAY
	LET gl_setupRec.start_year_num = year(TODAY)
	LET gl_setupRec.end_year_num = YEAR(TODAY) + 5 #Default - PREPARE fiscal periods for the next 5 years (can still be changed in the corresponding module) 
	#Fiscal Period Init
	LET gl_setupRec.fiscal_period_size = 4
	LET gl_setupRec.start_period_num = 1
	LET gl_setupRec.end_period_num = gl_setupRec.fiscal_period_size

	INPUT BY NAME gl_setupRec_admin_rec_kandoouser.acct_mask_code,gl_setupRec.industry_type, gl_setupRec.fiscal_period_size, gl_setupRec.fiscal_startDate  WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED) #gl_setupRec.fiscal_period_size,gl_setupRec.start_year_num, gl_setupRec.start_period_num,gl_setupRec.end_period_num
			ON ACTION "Previous"
				LET mdNavigatePrevious = TRUE
				EXIT INPUT
					
			AFTER FIELD fiscal_startDate
				LET gl_setupRec.start_year_num =  YEAR(gl_setupRec.fiscal_startDate)
				LET fiscalMonth = MONTH(gl_setupRec.fiscal_startDate)
				LET fiscalFactor = 12 / gl_setupRec.fiscal_period_size
				LET gl_setupRec.start_period_num = ((fiscalMonth-1) / fiscalFactor) +1
				LET gl_setupRec.end_year_num = YEAR(gl_setupRec.fiscal_startDate) + 5  --always create the records for the next 5 years
				
			#AFTER FIELD gl_setupRec.start_year_num
			#	LET gl_setupRec.end_year_num = gl_setupRec.start_year_num
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

	CLOSE WINDOW wGlSetup

END FUNCTION



###############################################################
# FUNCTION addGLParms()
# Just write default data with defined company code
# write local glparms record TO DB 
###############################################################
FUNCTION addGLParms()
	DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE recCount SMALLINT
	
	LET l_rec_glparms.cmpy_code = gl_setupRec_default_company.cmpy_code
	LET l_rec_glparms.key_code = "1"
	LET l_rec_glparms.next_jour_num = 0
	LET l_rec_glparms.next_seq_num = 0
	LET l_rec_glparms.next_post_num = 0
	LET l_rec_glparms.next_load_num = 0
	LET l_rec_glparms.next_consol_num = 0
	LET l_rec_glparms.gj_code = "GJ"
	#LET l_rec_glparms.last_depr_date = "NOT SET"
	LET l_rec_glparms.rj_code = "RJ"
	LET l_rec_glparms.cb_code = "CB"
	LET l_rec_glparms.last_post_date = TODAY
	LET l_rec_glparms.last_update_date = TODAY
	LET l_rec_glparms.last_close_date = TODAY
	LET l_rec_glparms.last_del_date = TODAY
	LET l_rec_glparms.cash_book_flag = "Y"
	LET l_rec_glparms.post_susp_flag = "Y
"	LET l_rec_glparms.susp_acct_code = "9998"
	LET l_rec_glparms.exch_acct_code = "7906"
	LET l_rec_glparms.unexch_acct_code = "7906"
	LET l_rec_glparms.clear_acct_code = "1260"
	LET l_rec_glparms.post_total_amt = 0
	LET l_rec_glparms.control_tot_flag = "N"
	LET l_rec_glparms.use_clear_flag = "N"
	LET l_rec_glparms.use_currency_flag = "N"
	LET l_rec_glparms.base_currency_code = gl_setupRec_default_company.curr_code
	#LET l_rec_glparms.budg1_text 
	LET l_rec_glparms.budg1_close_flag = "N"
	#LET l_rec_glparms.budg2_text
	LET l_rec_glparms.budg2_close_flag = "N"
	#LET l_rec_glparms.budg3_text
	LET l_rec_glparms.budg3_close_flag = "N"
	#LET l_rec_glparms.budg4_text
	LET l_rec_glparms.budg4_close_flag = "N"
	#LET l_rec_glparms.budg5_text
	LET l_rec_glparms.budg5_close_flag = "N"
	#LET l_rec_glparms.budg6_text
	LET l_rec_glparms.budg6_close_flag = "N"
	LET l_rec_glparms.style_ind = 2  --what IS this for ?
	#LET l_rec_glparms.site_code
	LET l_rec_glparms.acrl_code = "AJ"
	LET l_rec_glparms.rev_acrl_code = "ARJ"
	LET l_rec_glparms.last_acrl_yr_num = 0
	LET l_rec_glparms.last_acrl_per_num = 0

 SELECT COUNT(*) INTO recCount FROM glparms
 WHERE cmpy_code = l_rec_glparms.cmpy_code
 
 IF recCount = 0 THEN
 	INSERT INTO glparms VALUES(l_rec_glparms.*)
 END IF

END FUNCTION

