#This file IS used as GLOBALS file FROM P96b.4gl
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
############################################################
# GLOBAL SCOPE
############################################################
GLOBALS 
	DEFINE glob_rec_parameters RECORD 
		tax_vend_code LIKE vendortype.tax_vend_code, 
		name_text LIKE vendor.name_text, 
		rrn_num CHAR(20), 
		year_num LIKE cheque.year_num, 
		sign_on_code LIKE kandoouser.sign_on_code 
	END RECORD
	DEFINE glob_year_end_date DATE
	DEFINE glob_uline4 CHAR(4)
	DEFINE glob_uline14 CHAR(14)
	DEFINE glob_uline28 CHAR(28)
	DEFINE glob_uline74 CHAR(74)
	DEFINE glob_payee_total INTEGER
	DEFINE glob_payee_amt_total LIKE vendor.bal_amt
	DEFINE glob_payee_tax_total LIKE vendor.bal_amt
	DEFINE glob_signature_file LIKE kandoouser.signature_text 
END GLOBALS 
