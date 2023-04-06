############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE glob_rec_customer RECORD LIKE customer.*
	DEFINE glob_rec_invoicehead RECORD LIKE invoicehead.*

	DEFINE A30_glob_dt_rec_invoicehead TYPE AS RECORD
--			scroll_flag CHAR(1), 
			inv_num LIKE invoicehead.inv_num, 
			purchase_code LIKE invoicehead.purchase_code, 
			inv_date LIKE invoicehead.inv_date, 
			total_amt LIKE invoicehead.total_amt, 
			paid_amt LIKE invoicehead.paid_amt 
	END RECORD 

	DEFINE A30_glob_dt_rec_invoicehead_discount TYPE AS RECORD
				due_date LIKE invoicehead.due_date, 
				disc_date LIKE invoicehead.disc_date, 
				disc_amt LIKE invoicehead.disc_amt, 
				disc_taken_amt LIKE invoicehead.disc_taken_amt, 
				cust_code LIKE invoicehead.cust_code 
	END RECORD 
		
	DEFINE A30_glob_dt_rec_receipt TYPE AS RECORD
		cash_num LIKE cashreceipt.cash_num, 
		com1_text LIKE cashreceipt.com1_text,
		cheque_text LIKE cashreceipt.cheque_text, 
		cash_date LIKE cashreceipt.cash_date, 
		year_num LIKE cashreceipt.year_num, 
		period_num LIKE cashreceipt.period_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt, 
		posted_flag LIKE cashreceipt.posted_flag 
	END RECORD 

	DEFINE A39_glob_dt_rec_receipt TYPE AS RECORD
		cash_num LIKE cashreceipt.cash_num, 
		com1_text LIKE cashreceipt.com1_text, 
		cust_code LIKE cashreceipt.cust_code ,
		cust_name_text LIKE customer.name_text,
		cash_date LIKE cashreceipt.cash_date, 
		year_num LIKE cashreceipt.year_num, 
		period_num LIKE cashreceipt.period_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt, 
		posted_flag LIKE cashreceipt.posted_flag 
	END RECORD 
		
END GLOBALS 
