############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pr_count, 
	pr_total_count SMALLINT, 
	st_reqdetl array[2000] OF RECORD LIKE reqdetl.*, 
	pr_arr_size, 
	pr_reset_array SMALLINT, 
	trans_text CHAR(14), 
	pr_save RECORD 
		req_qty LIKE reqdetl.req_qty, 
		back_qty LIKE reqdetl.back_qty, 
		reserved_qty LIKE reqdetl.reserved_qty, 
		warn_flag CHAR(1), 
		unit_sales_amt LIKE reqdetl.unit_sales_amt, 
		replenish_ind LIKE reqdetl.replenish_ind, 
		vend_code LIKE vendor.vend_code 
	END RECORD, 
	pa_reqdetl array[2000] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE reqdetl.line_num, 
		part_code LIKE reqdetl.part_code, 
		req_qty LIKE reqdetl.req_qty, 
		uom_code LIKE reqdetl.uom_code, 
		warn_flag CHAR(1), 
		unit_sales_amt LIKE reqdetl.unit_sales_amt, 
		line_tot_amt LIKE reqhead.total_sales_amt, 
		autoinsert_flag CHAR(1) 
	END RECORD, 
	held_order SMALLINT 
END GLOBALS 
