###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	DEFINE glob_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE glob_rec_orderdetl RECORD LIKE orderdetl.* 
--	DEFINE glob_rec_customer RECORD LIKE customer.* 
	DEFINE glob_sum_amt money(12,2)
	DEFINE glob_sum_cost money(12,2)
	DEFINE glob_sum_tax money(12,2)
	DEFINE glob_sum_paid money(12,2)
--	DEFINE glob_sum_dist money(12,2) 
--	DEFINE glob_sum_app money(12,2) 
--	DEFINE glob_sum_cash money(12,2) 
	DEFINE glob_sum_cred money(12,2) 	
	DEFINE glob_line_info char(132) 
	DEFINE glob_problem SMALLINT 
	DEFINE glob_ans char(1) 

END GLOBALS 