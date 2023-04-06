############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_yes_flag LIKE language.yes_flag 
	DEFINE glob_no_flag LIKE language.no_flag 
--	DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE glob_rec_opparms RECORD LIKE opparms.* 
--	DEFINE glob_rec_arparms RECORD LIKE arparms.* 
	DEFINE glob_rec_country RECORD LIKE country.* 
	DEFINE glob_rec_orderhead RECORD LIKE orderhead.* 
	--modu_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE glob_rec_customer RECORD LIKE customer.* 
	DEFINE glob_rec_sales_order_parameter RECORD 
		def_paydetl_flag char(1), ## session default. paydetail WINDOW 
		paydetl_flag char(1), ## indivdual order. paydetail WINDOW 
		def_suppl_flag char(1), ## session default. pre-delivered items 
		suppl_flag char(1), ## indivdual order. pre-delivered items 
		supp_ware_code LIKE warehouse.ware_code, 
		base_curr_code LIKE currency.currency_code, 
		order_date DATE, ## default ORDER DATE 
		ship_date DATE, ## default shipping DATE 
		complete_flag char(1), ## competed orders flag 
		owner_text char(8), ## ORDER owner flag 
		pick_ind SMALLINT ## are pick slips being rejected 
	END RECORD 
	DEFINE glob_status_ind char(1) 
	DEFINE glob_currord_amt decimal(16,2)## CURRENT ORDER total amount 
	DEFINE glob_temp_text VARCHAR(200) --STRING not possible -> SQL INTO ## temp scratch pad variable 
END GLOBALS  
