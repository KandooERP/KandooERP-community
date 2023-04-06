############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	pr_menunames RECORD LIKE menunames.*, 
	pr_invoicehead RECORD 
		cust_code LIKE invoicehead.cust_code, 
		org_cust_code LIKE invoicehead.org_cust_code, 
		name_text LIKE customer.name_text, 
		org_name_text LIKE customer.name_text, 
		currency_code LIKE customer.currency_code, 
		inv_num LIKE invoicehead.inv_num, 
		paid_date LIKE invoicehead.paid_date, 
		due_date LIKE invoicehead.due_date, 
		disc_date LIKE invoicehead.disc_date, 
		goods_amt LIKE invoicehead.goods_amt, 
		hand_amt LIKE invoicehead.hand_amt, 
		freight_amt LIKE invoicehead.freight_amt, 
		tax_amt LIKE invoicehead.tax_amt, 
		total_amt LIKE invoicehead.total_amt, 
		disc_amt LIKE invoicehead.disc_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		disc_taken_amt LIKE invoicehead.disc_taken_amt, 
		entry_code LIKE invoicehead.entry_code, 
		entry_date LIKE invoicehead.entry_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		job_code LIKE invoicehead.job_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		posted_flag LIKE invoicehead.posted_flag, 
		ord_num LIKE invoicehead.ord_num, 
		on_state_flag LIKE invoicehead.on_state_flag, 
		com1_text LIKE invoicehead.com1_text, 
		rev_date LIKE invoicehead.rev_date, 
		com2_text LIKE invoicehead.com2_text, 
		rev_num LIKE invoicehead.rev_num 
	END RECORD, 
	where_part CHAR(1500), 
	query_text CHAR(2000), 
	answer, 
	ans CHAR(1), 
	func_type CHAR(14), 
	mrow, 
	chosen, 
	exist SMALLINT, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	temp_text CHAR(32), 
	ref_text LIKE arparms.inv_ref1_text, 
	use_outer, 
	x, 
	y SMALLINT, 
	word CHAR(20), 
	letter CHAR(1) 
END GLOBALS 
