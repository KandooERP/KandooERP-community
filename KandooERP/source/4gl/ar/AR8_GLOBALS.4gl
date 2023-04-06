############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
{
GLOBALS 
	DEFINE glob_year_num SMALLINT 
	DEFINE glob_period_num SMALLINT 
	DEFINE glob_output_flag CHAR(1) 
	DEFINE glob_l1_cust_bal_amt DECIMAL(10,2) 
	DEFINE glob_l2_cust_bal_amt DECIMAL(10,2) 
	DEFINE glob_l3_cust_bal_amt DECIMAL(10,2) 
	DEFINE glob_local_bal_amt DECIMAL(10,2) 
	DEFINE glob_tot_local_bal_amt DECIMAL(10,2) 
	DEFINE glob_first_ind SMALLINT 

	DEFINE glob_period RECORD LIKE period.* 
END GLOBALS 
}