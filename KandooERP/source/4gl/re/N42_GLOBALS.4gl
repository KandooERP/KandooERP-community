############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
--	DEFINE glob_rec_reqparms RECORD LIKE reqparms.* 
	DEFINE pr_puparms RECORD LIKE puparms.* 
	DEFINE pr_reqperson RECORD LIKE reqperson.* 
	DEFINE pa_pendhead array[200] OF RECORD 
		pend_num LIKE pendhead.pend_num, 
		vend_code LIKE pendhead.vend_code, 
		order_date LIKE pendhead.order_date, 
		entry_code LIKE pendhead.entry_code, 
		ware_code LIKE pendhead.ware_code, 
		auth_amt LIKE reqhead.total_sales_amt, 
		tot_po_amt LIKE reqhead.total_sales_amt 
	END RECORD 
	DEFINE pr_period RECORD LIKE period.* 
	DEFINE err_message CHAR(80) 
	DEFINE arr_size SMALLINT 
END GLOBALS 
