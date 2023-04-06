############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE level CHAR(1) 
--	msg, prog CHAR(40), 
	DEFINE cmd CHAR(3) 
	DEFINE itis DATE 
--	query_text, where_part CHAR(1900), 
--	rpt_wid SMALLINT, 
--	rpt_date DATE, 
--	rpt_time CHAR(10), 
--	rpt_note CHAR(80), 

--	rpt_pageno LIKE rmsreps.page_num, 
--	rpt_length LIKE rmsreps.page_length_num, 
--	line1, line2 CHAR(80), 
--	offset1, offset2 SMALLINT, 
--	pr_company RECORD LIKE company.*, 
--	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
--	pr_output CHAR(60), 
--	prg_name CHAR(7), 
DEFINE poaudit_value LIKE poaudit.unit_cost_amt
DEFINE order_qty_tot LIKE poaudit.unit_cost_amt
DEFINE received_qty_tot LIKE poaudit.unit_cost_amt
DEFINE voucher_qty_tot LIKE poaudit.unit_cost_amt
DEFINE order_amt_tot LIKE poaudit.unit_cost_amt
DEFINE received_amt_tot LIKE poaudit.unit_cost_amt
DEFINE voucher_amt_tot LIKE poaudit.unit_cost_amt
DEFINE order_qty_gtot LIKE poaudit.unit_cost_amt
DEFINE received_qty_gtot LIKE poaudit.unit_cost_amt
DEFINE voucher_qty_gtot LIKE poaudit.unit_cost_amt
DEFINE order_amt_gtot LIKE poaudit.unit_cost_amt
DEFINE received_amt_gtot LIKE poaudit.unit_cost_amt
DEFINE voucher_amt_gtot LIKE poaudit.unit_cost_amt
DEFINE order_qty_ggtot LIKE poaudit.unit_cost_amt
DEFINE received_qty_ggtot LIKE poaudit.unit_cost_amt
DEFINE voucher_qty_ggtot LIKE poaudit.unit_cost_amt
DEFINE order_amt_ggtot LIKE poaudit.unit_cost_amt
DEFINE received_amt_ggtot LIKE poaudit.unit_cost_amt
DEFINE voucher_amt_ggtot LIKE poaudit.unit_cost_amt 
END GLOBALS 
