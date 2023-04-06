############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	pr_puparms RECORD LIKE puparms.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pa_reqhead array[200] OF RECORD 
		scroll_flag CHAR(1), 
		req_num LIKE reqhead.req_num, 
		person_code LIKE reqhead.person_code, 
		name_text LIKE reqperson.name_text, 
		stock_ind LIKE reqhead.stock_ind, 
		req_date LIKE reqhead.req_date, 
		ware_code LIKE reqhead.ware_code, 
		total_sales_amt LIKE reqhead.total_sales_amt, 
		status_ind LIKE reqhead.status_ind 
	END RECORD, 
	pr_period RECORD LIKE period.*, 
	err_message CHAR(80), 
	pr_po_cnt, pr_pnd_cnt SMALLINT, 
	pr_first_ponum LIKE puparms.next_po_num, 
	pr_last_ponum LIKE puparms.next_po_num, 
	pr_first_pnnum LIKE puparms.next_po_num, 
	pr_last_pnnum LIKE puparms.next_po_num, 
	pr_first_trfnum LIKE ibthead.trans_num, 
	pr_last_trfnum LIKE ibthead.trans_num, 
	arr_size SMALLINT, 
	# These global variables are the ones defined in I57 so I51a can be
	# called. ie I51_rpt_list
	pr_grandtot DECIMAL(16,2), 
	pr_inparms RECORD LIKE inparms.*, 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_mode CHAR(10), 
	query_text STRING 
END GLOBALS 
