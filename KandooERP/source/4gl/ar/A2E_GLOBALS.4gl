############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_t_customer RECORD LIKE customer.* # new customer 
	DEFINE glob_rec_t_invoicehead RECORD LIKE invoicehead.* # new invoice 
	DEFINE glob_rec_customership RECORD LIKE customership.*
	DEFINE glob_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD
	DEFINE glob_sav_cust_code LIKE customer.cust_code
	DEFINE glob_rec_org_customer RECORD LIKE customer.*
	DEFINE glob_v_name_text LIKE customer.name_text
	DEFINE glob_t_name_text LIKE customer.name_text
	DEFINE glob_corp_cust RECORD LIKE customer.*
	DEFINE glob_v_corp_cust SMALLINT
	DEFINE where_text CHAR(500) #not used
END GLOBALS 