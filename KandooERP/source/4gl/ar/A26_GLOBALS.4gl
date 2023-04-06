############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

GLOBALS 
	DEFINE glob_cmpy_code LIKE company.cmpy_code 
	DEFINE glob_inv_num LIKE invoicehead.inv_num 
	DEFINE glob_cust_code LIKE customer.cust_code 
	DEFINE glob_name_text LIKE customer.name_text 
	DEFINE glob_t_name_text LIKE customer.name_text 
	--   	DEFINE glob_rec_customer RECORD LIKE customer.*,
	DEFINE glob_corp_cust SMALLINT 
	DEFINE glob_arr_rec_nametext array[320] OF RECORD 
		name_text LIKE customer.name_text, 
		cust_code LIKE customer.cust_code 
	END RECORD 
	-- 	DEFINE   glob_rec_invoicehead RECORD LIKE invoicehead.*,
	DEFINE glob_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 
	DEFINE glob_idx SMALLINT --scrn,
	DEFINE glob_i SMALLINT --scrn,
	DEFINE glob_cnt SMALLINT --scrn,
 
	DEFINE glob_ans CHAR(1) 
	DEFINE glob_func_type CHAR(14) 
	#glob_rec_arparms record  #huho 26.03.2019 experiment... sorry... cleaning up GLOBALS
	#   inv_ref1_text LIKE arparms.inv_ref1_text,
	#   inv_ref2a_text LIKE arparms.inv_ref2a_text,
	#   inv_ref2b_text LIKE arparms.inv_ref2b_text
	#END RECORD,
	DEFINE glob_ref_text LIKE arparms.inv_ref1_text 
END GLOBALS 