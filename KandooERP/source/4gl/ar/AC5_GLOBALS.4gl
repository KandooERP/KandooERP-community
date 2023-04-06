############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_total_disc_amt LIKE cashreceipt.disc_amt 
	DEFINE glob_total_pay_amt LIKE invoicepay.pay_amt 
	DEFINE glob_total_out_amt LIKE invoicehead.total_amt 
	DEFINE glob_disc_amt LIKE cashreceipt.disc_amt 
	DEFINE glob_pay_amt LIKE invoicepay.pay_amt 
	DEFINE glob_outstd_amt LIKE invoicehead.total_amt 
	DEFINE glob_out_amt LIKE invoicehead.total_amt 
END GLOBALS
