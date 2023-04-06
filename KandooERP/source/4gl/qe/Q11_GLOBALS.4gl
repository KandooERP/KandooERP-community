############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	yes_flag LIKE language.yes_flag, 
	no_flag LIKE language.no_flag, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	glob_rec_opparms RECORD LIKE opparms.*, 
	#pr_qpparms RECORD LIKE qpparms.*,
	pr_country RECORD LIKE country.*, 
	pr_quotehead RECORD LIKE quotehead.*, 
	pm_quotedetl RECORD LIKE quotedetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_globals RECORD 
		def_paydetl_flag CHAR(1), ## session default. paydetail WINDOW 
		paydetl_flag CHAR(1), ## indivdual order. paydetail WINDOW 
		supp_ware_code LIKE warehouse.ware_code, 
		base_curr_code LIKE currency.currency_code, 
		quote_date DATE, ## default ORDER DATE 
		ship_date DATE, ## default shipping DATE 
		owner_text CHAR(8) ## ORDER owner flag 
	END RECORD, 
	pr_currord_amt DECIMAL(16,2),## CURRENT ORDER total amount 
	pr_temp_text CHAR(500) ## temp scratch pad variable 
END GLOBALS 
