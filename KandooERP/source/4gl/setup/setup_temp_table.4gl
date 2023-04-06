GLOBALS "lib_db_globals.4gl"
GLOBALS "setup_globals.4gl"
#####################################################
# FUNCTION createTempTables()             --Utilities
#####################################################
FUNCTION createTempTables(pNewInst)
	DEFINE pNewInst BOOLEAN  --TRUE = UPDATE installation

		#Note: for now, we will create each temp table twice. For UPDATE installations, we will read the existing tables, populate the table/globalRecord pairs TO have the original data stored/available.	
		CREATE TEMP TABLE temp_company(
    cmpy_code CHAR(2) UNIQUE,
    name_text CHAR(30),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(30),
    state_code CHAR(6),
    post_code CHAR(10),
    country_text CHAR(20),
    country_code CHAR(3),
    language_code CHAR(3),
    fax_text CHAR(20),
    tax_text CHAR(30),
    telex_text CHAR(30),
    com1_text CHAR(50),
    com2_text CHAR(50),
    tele_text CHAR(20),
    curr_code CHAR(3),
    module_text CHAR(26),
    vat_code CHAR(11),
    vat_div_code CHAR(3)    
			)
		CREATE TEMP TABLE temp_company_orig(
    cmpy_code CHAR(2) UNIQUE,
    name_text CHAR(30),
    addr1_text CHAR(30),
    addr2_text CHAR(30),
    city_text CHAR(30),
    state_code CHAR(6),
    post_code CHAR(10),
    country_text CHAR(20),
    country_code CHAR(3),
    language_code CHAR(3),
    fax_text CHAR(20),
    tax_text CHAR(30),
    telex_text CHAR(30),
    com1_text CHAR(50),
    com2_text CHAR(50),
    tele_text CHAR(20),
    curr_code CHAR(3),
    module_text CHAR(26),
    vat_code CHAR(11),
    vat_div_code CHAR(3)    
			)

	INSERT INTO temp_company SELECT * FROM company
	INSERT INTO temp_company_orig SELECT * FROM company
	SELECT * INTO glRecCompany_orig FROM company

			
		CREATE TEMP TABLE temp_rec_kandoouser 
  (
    sign_on_code CHAR(8) UNIQUE,
    name_text CHAR(40),
    security_ind CHAR(1),
    password_text CHAR(8),
    language_code CHAR(3),
    cmpy_code CHAR(2),
    acct_mask_code CHAR(18),
    profile_code CHAR(3),
    access_ind CHAR(1),
    sign_on_date DATE,
    print_text CHAR(20),
    act_spawn_num SMALLINT,
    max_spawn_num SMALLINT,
    group_code CHAR(1),
    signature_text CHAR(20),
    passwd_ind CHAR(1),
    memo_pri_ind CHAR(1),
    email CHAR(60)
  )
		CREATE TEMP TABLE temp_kandoouser_orig 
  (
    sign_on_code CHAR(8) UNIQUE,
    name_text CHAR(40),
    security_ind CHAR(1),
    password_text CHAR(8),
    language_code CHAR(3),
    cmpy_code CHAR(2),
    acct_mask_code CHAR(18),
    profile_code CHAR(3),
    access_ind CHAR(1),
    sign_on_date DATE,
    print_text CHAR(20),
    act_spawn_num SMALLINT,
    max_spawn_num SMALLINT,
    group_code CHAR(1),
    signature_text CHAR(20),
    passwd_ind CHAR(1),
    memo_pri_ind CHAR(1),
    email CHAR(60)
  )


	INSERT INTO temp_rec_kandoouser SELECT * FROM kandoouser	
	INSERT INTO temp_kandoouser_orig SELECT * FROM kandoouser
	SELECT * INTO glRecKandoouser_orig FROM company
	
		CREATE TEMP TABLE temp_arparms 
  (
    cmpy_code CHAR(2),
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
		CREATE TEMP TABLE temp_arparms_orig 
  (
    cmpy_code CHAR(2),
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


	INSERT INTO temp_arparms SELECT * FROM arparms
	INSERT INTO temp_arparms_orig SELECT * FROM arparms
	SELECT * INTO glRecArparms_orig FROM arparms	
			
	CREATE TEMP TABLE temp_apparms 
  (
    cmpy_code CHAR(2),
    parm_code CHAR(1),
    next_vouch_num INTEGER,
    next_deb_num INTEGER,
    pur_jour_code CHAR(10),
    chq_jour_code CHAR(10),
    pay_acct_code CHAR(18),
    bank_acct_code CHAR(18),
    freight_acct_code CHAR(18),
    salestax_acct_code CHAR(18),
    disc_acct_code CHAR(18),
    exch_acct_code CHAR(18),
    last_chq_prnt_date DATE,
    last_post_date DATE,
    last_aging_date DATE,
    last_del_date DATE,
    last_mail_date DATE,
    gl_flag CHAR(1),
    hist_flag CHAR(1),
    gl_detl_flag CHAR(1),
    vouch_approve_flag CHAR(1),
    report_ord_flag CHAR(1),
    distrib_style CHAR(1)  
  )	
	CREATE TEMP TABLE temp_apparms_orig 
  (
    cmpy_code CHAR(2),
    parm_code CHAR(1),
    next_vouch_num INTEGER,
    next_deb_num INTEGER,
    pur_jour_code CHAR(10),
    chq_jour_code CHAR(10),
    pay_acct_code CHAR(18),
    bank_acct_code CHAR(18),
    freight_acct_code CHAR(18),
    salestax_acct_code CHAR(18),
    disc_acct_code CHAR(18),
    exch_acct_code CHAR(18),
    last_chq_prnt_date DATE,
    last_post_date DATE,
    last_aging_date DATE,
    last_del_date DATE,
    last_mail_date DATE,
    gl_flag CHAR(1),
    hist_flag CHAR(1),
    gl_detl_flag CHAR(1),
    vouch_approve_flag CHAR(1),
    report_ord_flag CHAR(1),
    distrib_style CHAR(1)  
  )	
	
	INSERT INTO temp_apparms SELECT * FROM apparms
	INSERT INTO temp_apparms_orig SELECT * FROM apparms
	SELECT * INTO glRecApparms_orig FROM apparms	
		
	CREATE TEMP TABLE temp_arparmext 
		(
    cmpy_code CHAR(2),
    last_int_date DATE,
    int_acct_code CHAR(18),
    writeoff_acct_code CHAR(18),
    last_writeoff_date date
    )
	CREATE TEMP TABLE temp_arparmext_orig 
		(
    cmpy_code CHAR(2),
    last_int_date DATE,
    int_acct_code CHAR(18),
    writeoff_acct_code CHAR(18),
    last_writeoff_date date
    )

   
 	INSERT INTO temp_arparmext SELECT * FROM arparmext   
 	INSERT INTO temp_arparmext_orig SELECT * FROM arparmext      
	SELECT * INTO glRecArparmext_orig FROM arparmext	
	    
END FUNCTION




 