############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	--DEFINE glob_rec_credithead RECORD LIKE credithead.* 
	--DEFINE glob_rec_t_credithead RECORD LIKE credithead.* 
--	DEFINE glob_arr_rec_credithead array[250] OF RECORD 
--		cred_num LIKE credithead.cred_num, 
--		cust_code LIKE credithead.cust_code , 
--		cred_date LIKE credithead.cred_date, 
--		year_num LIKE credithead.year_num, 
--		period_num LIKE credithead.period_num, 
--		total_amt LIKE credithead.total_amt, 
--		appl_amt LIKE credithead.appl_amt, 
--		posted_flag LIKE credithead.posted_flag 
--	END RECORD 
--	DEFINE idx SMALLINT
--	DEFINE cnt SMALLINT
--	DEFINE err_flag SMALLINT
	 
--	DEFINE sel_text CHAR(900)
--	DEFINE where_credit CHAR(900)
	 
--	DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
END GLOBALS 
