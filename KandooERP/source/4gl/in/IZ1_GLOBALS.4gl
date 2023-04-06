############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_category RECORD LIKE category.* #pr_category 
	DEFINE glob_rec_sale_accounts  RECORD #pr_sale_accounts 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_cogs_accounts RECORD #pr_cogs_accounts  
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_int_rev_accts RECORD #pr_int_rev_accts 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_int_cogs_accts RECORD #pr_int_cogs_accts  
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_f_sale_accounts  RECORD  #pf_sale_accounts 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_f_cogs_accounts RECORD #pf_cogs_accounts  
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_f_int_rev_accts RECORD#pf_int_rev_accts 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
	DEFINE glob_rec_f_int_cogs_accts RECORD #pf_int_cogs_accts 
		def_acct_code LIKE coa.acct_code, 
		ord6_acct_code LIKE coa.acct_code, 
		ord7_acct_code LIKE coa.acct_code, 
		ord8_acct_code LIKE coa.acct_code, 
		ord9_acct_code LIKE coa.acct_code 
	END RECORD 
END GLOBALS 
