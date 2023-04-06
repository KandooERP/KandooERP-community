############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rows_output INTEGER 
	DEFINE glob_base_total_amt LIKE invoicehead.total_amt
	
	#Selector rmsreps
	DEFINE glob_period_sel CHAR(1) 
	DEFINE glob_year_num LIKE invoicehead.year_num 
	DEFINE glob_bper LIKE invoicehead.period_num
	DEFINE glob_eper LIKE invoicehead.period_num 

	DEFINE glob_date_sel CHAR(1)
	DEFINE glob_bdate DATE
	DEFINE glob_edate DATE 

	DEFINE glob_cust_sel CHAR(1)
	DEFINE glob_bcust LIKE customer.cust_code
	DEFINE glob_ecust LIKE customer.cust_code 
	
	DEFINE glob_tax_sel CHAR(1) 			
	DEFINE glob_btax LIKE tax.tax_code
	DEFINE glob_etax LIKE tax.tax_code 
	#End of rmsreps selector

END GLOBALS
