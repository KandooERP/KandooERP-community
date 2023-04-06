############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"

###########################################################################
# Module Scope Variables
###########################################################################
DEFINE modu_argstr1 STRING -- 1st program STRING argument 
DEFINE modu_argstr1_set boolean --true = variable initialized/set false=not initialized 
DEFINE modu_argstr2 STRING -- 2nd program STRING argument 
DEFINE modu_argstr2_set boolean --true = variable initialized/set false=not initialized 
DEFINE modu_argint1 int -- 1st program INTEGER argument #was VARCHAR(50) 
DEFINE modu_argint1_set boolean --true = variable initialized/set false=not initialized 
DEFINE modu_argint2 int -- 2nd program INTEGER argument #was VARCHAR(50) 
DEFINE modu_argint2_set boolean --true = variable initialized/set false=not initialized 

DEFINE modu_switch boolean --true = variable initialized/set false=not initialized
DEFINE modu_vendor_code LIKE vendor.vend_code 
DEFINE modu_cmpy_code LIKE company.cmpy_code  #company_code 
DEFINE modu_auto_company_code LIKE company.cmpy_code 
DEFINE modu_jmj_company_code LIKE company.cmpy_code
DEFINE modu_sale_code LIKE salesperson.sale_code
DEFINE modu_salesmgr_code LIKE salesperson.sale_code
DEFINE modu_customer_code LIKE customer.cust_code
DEFINE modu_area_code LIKE salearea.area_code
DEFINE modu_terr_code LIKE territory.terr_code
DEFINE modu_ship_code LIKE shiphead.ship_code 
DEFINE modu_warehouse_code LIKE warehouse.ware_code
DEFINE modu_invoice_number LIKE invoicehead.inv_num 
DEFINE modu_cashreceipt_number LIKE cashreceipt.cash_num 
DEFINE modu_credit_number LIKE credithead.cred_num 
DEFINE modu_bankdepartment_number LIKE tentbankhead.bank_dep_num 
DEFINE modu_batch_number LIKE cashrcphdr.batch_no 
DEFINE modu_last_batch_number LIKE cashrcphdr.batch_no 
DEFINE modu_sent_batch_number LIKE cashrcphdr.batch_no 
DEFINE modu_load_ind LIKE loadparms.load_ind 
DEFINE modu_fiscal_year_num LIKE period.year_num 
DEFINE modu_fiscal_period_num LIKE period.period_num 
DEFINE modu_fiscal_month_num SMALLINT 
DEFINE modu_fiscal_date DATE 

#Warehouse
DEFINE modu_part_code LIKE product.part_code
DEFINE modu_product_part_code LIKE product.part_code

DEFINE modu_tran_type_ind LIKE accountledger.tran_type_ind 
DEFINE modu_account_ledger CHAR(150) 
DEFINE modu_ref_text LIKE accountledger.ref_text 
DEFINE modu_ref_num LIKE accountledger.ref_num 
DEFINE modu_cycle_num LIKE tentpays.cycle_num 
DEFINE modu_invoice_text STRING #i believe this isused in queries - conditions 
DEFINE modu_credit_text STRING #i believe this isused in queries - conditions 

DEFINE modu_prog_child VARCHAR(5) #Program ID which called / which processed the CALL/RUN statement i.e. A11
DEFINE modu_module_child VARCHAR(5) #SubModule ID which called / which processed the CALL/RUN statement i.e. A11
DEFINE modu_prog_parent VARCHAR(5) #Program ID (note, there is a mess in Kandoo with char(3/4/5) program names) (was once only 3 characters !)
DEFINE modu_module_parent VARCHAR(5) #SubModule ID note, there is a mess in Kandoo with char(3/4/5) program names) (was once only 3 characters !)
DEFINE modu_child_run_once_only boolean #trun MAIN program loops ON / off 

# modu_prog Will be dropped # DON't use it anymore
DEFINE modu_prog VARCHAR(5) #Program which called / which processed the RUN statement i.e. A11

DEFINE modu_query_text STRING #used FOR complete OR partial queries 
DEFINE modu_query_where_text STRING #used FOR complete OR partial queries 
DEFINE modu_sel_text STRING #??? in reporting ??? may be also used for query  ??


DEFINE modu_autopost CHAR(1) #used s a boolean FOR automated posting flag 
DEFINE modu_order CHAR(1) #order OPTIONS FOR SQL 
DEFINE modu_char CHAR(1) --single CHAR argument WITHOUT any information in the code 
DEFINE modu_menu_char2 CHAR(2) --single CHAR argument WITHOUT any information in the code 

DEFINE modu_action STRING #usually used for batch/script integration
DEFINE modu_zero_suppress CHAR(1) 

DEFINE modu_verbose boolean #hide OR SHOW ui 
 
DEFINE modu_post_run_num SMALLINT #loop control FOR how many posts 
DEFINE modu_tempper SMALLINT #don't ask me... some names make me puuuke 

#Voucher
DEFINE modu_voucher_option CHAR(1)



#COA
DEFINE modu_group_code LIKE coa.group_code 
DEFINE modu_acct_code LIKE coa.acct_code 

#Toolbar Manager
DEFINE modu_tb_project_name STRING 
DEFINE modu_tb_module_name STRING 
DEFINE modu_tb_menu_name STRING 
DEFINE modu_tb_user_name STRING 
# up for drop ... or do it right
###########################################################################
# FUNCTION init_url_variables_null()
#
# Initialize numeric variables to NULL  
# INTEGER, BOOL etc 
###########################################################################
FUNCTION init_url_variables_null() 
	INITIALIZE modu_verbose TO NULL
END FUNCTION 

###########################################################################
# FUNCTION set_url_action(p_action)
#
# Accessor Method for URL modu_action
###########################################################################
FUNCTION set_url_action(p_action) 
	DEFINE p_action STRING 
	LET modu_action = p_action 
END FUNCTION 

###########################################################################
# FUNCTION get_url_action()
#
# Accessor Method for URL modu_action
###########################################################################
FUNCTION get_url_action() 
	RETURN modu_action 
END FUNCTION 


###########################################################################
# FUNCTION set_url_query_text(p_query_text)
#
# Accessor Method for URL modu_query_text
###########################################################################
FUNCTION set_url_query_text(p_query_text) 
	DEFINE p_query_text STRING 
	LET modu_query_text = p_query_text 
END FUNCTION 

###########################################################################
# FUNCTION get_url_query_text()
#
# Accessor Method for URL modu_query_text
###########################################################################
FUNCTION get_url_query_text() 
	RETURN modu_query_text 
END FUNCTION 

###########################################################################
# FUNCTION set_url_sel_text(p_sel_text)
#
# Accessor Method for URL modu_sel_text
###########################################################################
FUNCTION set_url_sel_text(p_sel_text) 
	DEFINE p_sel_text STRING 
	LET modu_sel_text = " ", trim(p_sel_text), " " 
END FUNCTION 

###########################################################################
# FUNCTION get_url_sel_text()
#
# Accessor Method for URL modu_sel_text
###########################################################################
FUNCTION get_url_sel_text() 
	RETURN modu_sel_text 
END FUNCTION 


###########################################################################
# FUNCTION set_url_query_where_text(p_query_where_text)
#
# Accessor Method for URL modu_query_where_text
###########################################################################
FUNCTION set_url_query_where_text(p_query_where_text) 
	DEFINE p_query_where_text STRING 
	LET modu_query_where_text = p_query_where_text 
END FUNCTION 

###########################################################################
# FUNCTION get_url_query_where_text()
#
# Accessor Method for URL modu_query_where_text
###########################################################################
FUNCTION get_url_query_where_text() 
	RETURN modu_query_where_text 
END FUNCTION 





###########################################################################
# FUNCTION set_url_load_ind(p_load_ind)
#
# Accessor Method for URL modu_load_ind
###########################################################################
FUNCTION set_url_load_ind(p_load_ind) 
	DEFINE p_load_ind LIKE loadparms.load_ind 
	LET modu_load_ind = p_load_ind 
END FUNCTION 

###########################################################################
# FUNCTION get_url_load_ind()
#
# Accessor Method for URL modu_load_ind
###########################################################################
FUNCTION get_url_load_ind() 
	RETURN modu_load_ind 
END FUNCTION 

					
###########################################################################
# PROG_PARENT
#
# WHEN "PROG_PARENT" #Progam ID which run another program char(5)
# 	CALL set_url_prog_parent(l_argval) 
###########################################################################
#--------------------------------------------------------------------------
# FUNCTION set_url_prog_parent(p_called_from)
#
# Accessor Method for URL modu_prog_parent
#--------------------------------------------------------------------------
FUNCTION set_url_prog_parent(p_called_from) 
	DEFINE p_called_from STRING 
	
	LET modu_prog_parent = p_called_from 
END FUNCTION 

#--------------------------------------------------------------------------
# FUNCTION get_url_prog_parent()
#
# Accessor Method for URL modu_prog_parent
#--------------------------------------------------------------------------
FUNCTION get_url_prog_parent() 
	RETURN modu_prog_parent 
END FUNCTION 
#--------------------------------------------------------------------------

###########################################################################
# PROG_CHILD
#
# WHEN "PROG_CHILD" #Progam ID which run another program char(5)
#		CALL set_url_prog_child(l_argval) 
###########################################################################
#--------------------------------------------------------------------------
# FUNCTION set_url_prog_child(p_prog_call)
#
# Accessor Method for URL modu_prog_child
#--------------------------------------------------------------------------
FUNCTION set_url_prog_child(p_prog_call) 
	DEFINE p_prog_call VARCHAR(5) 
	LET modu_prog_child = p_prog_call 
END FUNCTION 
#--------------------------------------------------------------------------
# FUNCTION get_url_prog_child()
#
# Accessor Method for URL modu_prog_child
#--------------------------------------------------------------------------
FUNCTION get_url_prog_child() 
	RETURN modu_prog_child 
END FUNCTION 
#--------------------------------------------------------------------------


###########################################################################
# MODULE_PARENT
#
#	WHEN "MODULE_PARENT" #ERP SUB MODULE ID which run another program char(5)
#		CALL set_url_module_parent(l_argval) 
###########################################################################

#--------------------------------------------------------------------------
# FUNCTION set_url_module_parent(p_called_from)
#
# Accessor Method for URL modu_module_parent
#--------------------------------------------------------------------------
FUNCTION set_url_module_parent(p_called_from) 
	DEFINE p_called_from STRING 
	LET modu_module_parent = p_called_from 
END FUNCTION 
#--------------------------------------------------------------------------
# FUNCTION get_url_module_parent()
#
# Accessor Method for URL modu_module_parent
#--------------------------------------------------------------------------
FUNCTION get_url_module_parent() 
	RETURN modu_module_parent 
END FUNCTION 
#--------------------------------------------------------------------------

###########################################################################
# MODULE_CHILD
#
#	WHEN "MODULE_CHILD" #ERP SUB MODULE ID which run another program char(5)
#		CALL set_url_module_child(l_argval) 
###########################################################################
#--------------------------------------------------------------------------
# FUNCTION set_url_module_child(p_module_call)
#
# Accessor Method for URL modu_module_child
#--------------------------------------------------------------------------
FUNCTION set_url_module_child(p_module_call) 
	DEFINE p_module_call VARCHAR(5) 
	LET modu_module_child = p_module_call 
END FUNCTION 
#--------------------------------------------------------------------------
# FUNCTION get_url_module_child()
#
# Accessor Method for URL modu_module_child
#--------------------------------------------------------------------------
FUNCTION get_url_module_child() 
	RETURN modu_module_child 
END FUNCTION 
#--------------------------------------------------------------------------

###########################################################################
# FUNCTION set_url_batch_number(p_batch_number)
#
# Accessor Method for URL modu_batch_number
###########################################################################
FUNCTION set_url_batch_number(p_batch_number) 
	DEFINE p_batch_number LIKE tentbankhead.bank_dep_num 
	LET modu_batch_number = p_batch_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_batch_number()
#
# Accessor Method for URL modu_batch_number
###########################################################################
FUNCTION get_url_batch_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_batch_number = 0 THEN 
		RETURN 0 
	ELSE 
		RETURN modu_batch_number 
	END IF 
END FUNCTION 



###########################################################################
# FUNCTION set_url_last_batch_number(p_last_batch_number)
#
# Accessor Method for URL modu_last_batch_number
###########################################################################
FUNCTION set_url_last_batch_number(p_last_batch_number) 
	DEFINE p_last_batch_number LIKE tentbankhead.bank_dep_num 
	LET modu_last_batch_number = p_last_batch_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_last_batch_number()
#
# Accessor Method for URL modu_last_batch_number
###########################################################################
FUNCTION get_url_last_batch_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_last_batch_number = 0 THEN 
		RETURN 0 
	ELSE 
		RETURN modu_last_batch_number 
	END IF 
END FUNCTION 



###########################################################################
# FUNCTION set_url_sent_batch_number(p_sent_batch_number)
#
# Accessor Method for URL modu_sent_batch_number
###########################################################################
FUNCTION set_url_sent_batch_number(p_sent_batch_number) 
	DEFINE p_sent_batch_number LIKE tentbankhead.bank_dep_num 
	LET modu_sent_batch_number = p_sent_batch_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_sent_batch_number()
#
# Accessor Method for URL modu_sent_batch_number
###########################################################################
FUNCTION get_url_sent_batch_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_sent_batch_number = 0 THEN 
		RETURN 0 
	ELSE 
		RETURN modu_sent_batch_number 
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_part_code(p_part_code)
#
# Accessor Method for URL modu_part_code
###########################################################################
FUNCTION set_url_part_code(p_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	LET modu_part_code = p_part_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_part_code()
#
# Accessor Method for URL modu_part_code
###########################################################################
FUNCTION get_url_part_code() 
	#Note: int will be 0 NOT NULL by default
--	IF modu_part_code IS= 0 THEN 
--		RETURN NULL 
--	ELSE 
		RETURN modu_part_code 
--	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_product_part_code(p_product_part_code)
#
# Accessor Method for URL modu_product_part_code
###########################################################################
FUNCTION set_url_product_part_code(p_product_part_code) 
	DEFINE p_product_part_code LIKE product.part_code 
	LET modu_product_part_code = p_product_part_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_product_part_code()
#
# Accessor Method for URL modu_product_part_code
###########################################################################
FUNCTION get_url_product_part_code() 
	#Note: int will be 0 NOT NULL by default
--	IF modu_product_part_code IS= 0 THEN 
--		RETURN NULL 
--	ELSE 
		RETURN modu_product_part_code 
--	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_bankdepartment_number(p_bankdepartment_number)
#
# Accessor Method for URL modu_bankdepartment_number
###########################################################################
FUNCTION set_url_bankdepartment_number(p_bankdepartment_number) 
	DEFINE p_bankdepartment_number LIKE tentbankhead.bank_dep_num 
	LET modu_bankdepartment_number = p_bankdepartment_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_bankdepartment_number()
#
# Accessor Method for URL modu_bankdepartment_number
###########################################################################
FUNCTION get_url_bankdepartment_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_bankdepartment_number = 0 THEN 
		RETURN NULL 
	ELSE 
		RETURN modu_bankdepartment_number 
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_credit_number(p_credit_number)
#
# Accessor Method for URL modu_credit_number
###########################################################################
FUNCTION set_url_credit_number(p_credit_number) 
	DEFINE p_credit_number LIKE credithead.cred_num 
	LET modu_credit_number = p_credit_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_credit_number()
#
# Accessor Method for URL modu_credit_number
###########################################################################
FUNCTION get_url_credit_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_credit_number = 0 THEN 
		RETURN 0 
	ELSE 
		RETURN modu_credit_number 
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_cashreceipt_number(p_cashreceipt_number)
#
# Accessor Method for URL modu_cashreceipt_number
###########################################################################
FUNCTION set_url_cashreceipt_number(p_cashreceipt_number) 
	DEFINE p_cashreceipt_number LIKE cashreceipt.cash_num 
	LET modu_cashreceipt_number = p_cashreceipt_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_cashreceipt_number()
#
# Accessor Method for URL modu_cashreceipt_number
###########################################################################
FUNCTION get_url_cashreceipt_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_cashreceipt_number = 0 THEN 
		RETURN NULL 
	ELSE 
		RETURN modu_cashreceipt_number 
	END IF 
END FUNCTION 





###########################################################################
# FUNCTION set_url_invoice_number(p_invoice_number)
#
# Accessor Method for URL modu_invoice_number
###########################################################################
FUNCTION set_url_invoice_number(p_invoice_number) 
	DEFINE p_invoice_number LIKE invoicehead.inv_num 
	LET modu_invoice_number = p_invoice_number 
END FUNCTION 

###########################################################################
# FUNCTION get_url_invoice_number()
#
# Accessor Method for URL modu_invoice_number
###########################################################################
FUNCTION get_url_invoice_number() 
	#Note: int will be 0 NOT NULL by default
	IF modu_invoice_number = 0 THEN 
		RETURN 0 
	ELSE 
		RETURN modu_invoice_number 
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_warehouse_code(p_warehouse_code)
#
# Accessor Method for URL modu_warehouse_code
###########################################################################
FUNCTION set_url_warehouse_code(p_warehouse_code) 
	DEFINE p_warehouse_code LIKE warehouse.ware_code 
	LET modu_warehouse_code = p_warehouse_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_warehouse_code()
#
# Accessor Method for URL modu_warehouse_code
###########################################################################
FUNCTION get_url_warehouse_code() 
	IF modu_warehouse_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_warehouse_code
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_cust_code(p_customer_code)
#
# Accessor Method for URL modu_customer_code
###########################################################################
FUNCTION set_url_cust_code(p_customer_code) 
	DEFINE p_customer_code STRING 
	LET modu_customer_code = p_customer_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_cust_code()
#
# Accessor Method for URL modu_customer_code
###########################################################################
FUNCTION get_url_cust_code() 
	IF modu_customer_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_customer_code
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_sale_code(p_sale_code)
#
# Accessor Method for URL modu_sale_code
###########################################################################
FUNCTION set_url_sale_code(p_sale_code) 
	DEFINE p_sale_code STRING 
	LET modu_sale_code = p_sale_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_sale_code()
#
# Accessor Method for URL modu_sale_code
###########################################################################
FUNCTION get_url_sale_code() 
	IF modu_sale_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_sale_code
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION set_url_salesmgr_code(p_salesmgr_code)
#
# Accessor Method for URL modu_salesmgr_code
###########################################################################
FUNCTION set_url_salesmgr_code(p_salesmgr_code) 
	DEFINE p_salesmgr_code STRING 
	LET modu_salesmgr_code = p_salesmgr_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_salesmgr_code()
#
# Accessor Method for URL modu_salesmgr_code
###########################################################################
FUNCTION get_url_salesmgr_code() 
	IF modu_salesmgr_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_salesmgr_code
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_terr_code(p_terr_code)
#
# Accessor Method for URL modu_terr_code
###########################################################################
FUNCTION set_url_terr_code(p_terr_code) 
	DEFINE p_terr_code LIKE territory.terr_code  #terr_code nchar(5),
	LET modu_terr_code = p_terr_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_terr_code()
#
# Accessor Method for URL modu_terr_code
###########################################################################
FUNCTION get_url_terr_code() 
	IF modu_terr_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_terr_code
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_area_code(p_area_code)
#
# Accessor Method for URL modu_area_code
###########################################################################
FUNCTION set_url_area_code(p_area_code) 
	DEFINE p_area_code LIKE salearea.area_code  
	LET modu_area_code = p_area_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_area_code()
#
# Accessor Method for URL modu_area_code
###########################################################################
FUNCTION get_url_area_code() 
	IF modu_area_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_area_code
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION set_url_ship_code(p_ship_code)
#
# Accessor Method for URL modu_ship_code
###########################################################################
FUNCTION set_url_ship_code(p_ship_code) 
	DEFINE p_ship_code LIKE shiphead.ship_code  #ship_code nchar(8),
	LET modu_ship_code = p_ship_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_ship_code()
#
# Accessor Method for URL modu_ship_code
###########################################################################
FUNCTION get_url_ship_code() 
	IF modu_ship_code IS NULL THEN
		RETURN NULL
	ELSE
		RETURN modu_ship_code
	END IF 
END FUNCTION 




###########################################################################
# FUNCTION set_url_tran_type_ind(p_tran_type_ind)
#
# Accessor Method for URL modu_tran_type_ind
###########################################################################
FUNCTION set_url_tran_type_ind(p_tran_type_ind) 
	DEFINE p_tran_type_ind STRING 
	LET modu_tran_type_ind = p_tran_type_ind 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tran_type_ind()
#
# Accessor Method for URL modu_tran_type_ind
###########################################################################
FUNCTION get_url_tran_type_ind() 
	RETURN modu_tran_type_ind 
END FUNCTION 


###########################################################################
# FUNCTION set_url_cycle_num(p_cycle_num)
#
# Accessor Method for URL modu_cycle_num
###########################################################################
FUNCTION set_url_cycle_num(p_cycle_num) 
	DEFINE p_cycle_num STRING 
	LET modu_cycle_num = p_cycle_num 
END FUNCTION 

###########################################################################
# FUNCTION get_url_cycle_num()
#
# Accessor Method for URL modu_cycle_num
###########################################################################
FUNCTION get_url_cycle_num() 
	RETURN modu_cycle_num 
END FUNCTION 


###########################################################################
# FUNCTION set_url_ref_text(p_ref_text)
#
# Accessor Method for URL modu_ref_text
###########################################################################
FUNCTION set_url_ref_text(p_ref_text) 
	DEFINE p_ref_text LIKE accountledger.ref_text 
	LET modu_ref_text = p_ref_text 
END FUNCTION 

###########################################################################
# FUNCTION get_url_ref_text()
#
# Accessor Method for URL modu_ref_text
###########################################################################
FUNCTION get_url_ref_text() 
	RETURN modu_ref_text 
END FUNCTION 


###########################################################################
# FUNCTION set_url_ref_num(p_ref_num)
#
# Accessor Method for URL modu_ref_num
###########################################################################
FUNCTION set_url_ref_num(p_ref_num) 
	DEFINE p_ref_num LIKE accountledger.ref_num 
	LET modu_ref_num = p_ref_num 
END FUNCTION 

###########################################################################
# FUNCTION get_url_ref_num()
#
# Accessor Method for URL modu_ref_num
###########################################################################
FUNCTION get_url_ref_num() 
	RETURN modu_ref_num 
END FUNCTION 



###########################################################################
# FUNCTION set_url_account_ledger(p_account_ledger)
#
# Accessor Method for URL modu_account_ledger
###########################################################################
FUNCTION set_url_account_ledger(p_account_ledger) 
	DEFINE p_account_ledger CHAR(150) 
	LET modu_account_ledger = p_account_ledger 
END FUNCTION 

###########################################################################
# FUNCTION get_url_account_ledger()
#
# Accessor Method for URL modu_account_ledger
###########################################################################
FUNCTION get_url_account_ledger() 
	RETURN modu_account_ledger 
END FUNCTION 

------------------------------------------





###########################################################################
# FUNCTION set_url_acct_code(p_acct_code)
#
# Accessor Method for URL modu_acct_code
###########################################################################
FUNCTION set_url_acct_code(p_acct_code) 
	DEFINE p_acct_code LIKE coa.acct_code 
	LET modu_acct_code = p_acct_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_acct_code()
#
# Accessor Method for URL modu_acct_code
###########################################################################
FUNCTION get_url_acct_code() 
	RETURN modu_acct_code 
END FUNCTION 

###########################################################################
# FUNCTION set_url_group_code(p_group_code)
#
# Accessor Method for URL modu_group_code
###########################################################################
FUNCTION set_url_group_code(p_group_code) 
	DEFINE p_group_code LIKE coa.group_code 
	LET modu_group_code = p_group_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_group_code()
#
# Accessor Method for URL modu_group_code
###########################################################################
FUNCTION get_url_group_code() 
	RETURN modu_group_code 
END FUNCTION 


###########################################################################
# FUNCTION set_url_vendor_code(p_vendor_code)
#
# Accessor Method for URL modu_vendor_code
###########################################################################
FUNCTION set_url_vendor_code(p_vendor_code) 
	DEFINE p_vendor_code STRING 
	LET modu_vendor_code = p_vendor_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_vendor_code()
#
# Accessor Method for URL modu_vendor_code
###########################################################################
FUNCTION get_url_vendor_code() 
	RETURN modu_vendor_code 
END FUNCTION 

###########################################################################
# FUNCTION set_url_company_code(p_cmpy_code)
#
# Accessor Method for URL modu_company_code
###########################################################################
FUNCTION set_url_company_code(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	LET modu_cmpy_code = p_cmpy_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_company_code()
#
# Accessor Method for URL modu_company_code
###########################################################################
FUNCTION get_url_company_code() 
	RETURN modu_cmpy_code 
END FUNCTION 


###########################################################################
# FUNCTION set_url_cmpy_code(p_cmpy_code)
#
# Accessor Method for URL modu_cmpy_code
###########################################################################
FUNCTION set_url_cmpy_code(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	LET modu_cmpy_code = p_cmpy_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_cmpy_code()
#
# Accessor Method for URL modu_cmpy_code
###########################################################################
FUNCTION get_url_cmpy_code() 
	RETURN modu_cmpy_code 
END FUNCTION 

###########################################################################
# FUNCTION set_url_auto_company_code(p_auto_company_code)
#
# Accessor Method for URL modu_auto_company_code
###########################################################################
FUNCTION set_url_auto_company_code(p_auto_company_code) 
	DEFINE p_auto_company_code LIKE company.cmpy_code 
	LET modu_auto_company_code = p_auto_company_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_auto_company_code()
#
# Accessor Method for URL modu_auto_company_code
###########################################################################
FUNCTION get_url_auto_company_code() 
	RETURN modu_auto_company_code 
END FUNCTION 

###########################################################################
# FUNCTION set_url_jmj_company_code(p_jmj_company_code)
#
# Accessor Method for URL modu_jmj_company_code
###########################################################################
FUNCTION set_url_jmj_company_code(p_jmj_company_code) 
	DEFINE p_jmj_company_code LIKE company.cmpy_code 
	LET modu_jmj_company_code = p_jmj_company_code 
END FUNCTION 

###########################################################################
# FUNCTION get_url_jmj_company_code()
#
# Accessor Method for URL modu_jmj_company_code
###########################################################################
FUNCTION get_url_jmj_company_code() 
	RETURN modu_jmj_company_code 
END FUNCTION 


###########################################################################
# FUNCTION set_url_fiscal_year_num(p_fiscal_year_num)
#
# Accessor Method for URL modu_fiscal_year_num
###########################################################################
FUNCTION set_url_fiscal_year_num(p_fiscal_year_num) 
	DEFINE p_fiscal_year_num LIKE period.year_num 
	LET modu_fiscal_year_num = p_fiscal_year_num 
END FUNCTION 

###########################################################################
# FUNCTION get_url_fiscal_year_num()
#
# Accessor Method for URL modu_fiscal_year_num
###########################################################################
FUNCTION get_url_fiscal_year_num() 
	RETURN modu_fiscal_year_num 
END FUNCTION 

###########################################################################
# FUNCTION set_url_fiscal_period_num(p_fiscal_period_num)
#
# Accessor Method for URL modu_fiscal_period_num
###########################################################################
FUNCTION set_url_fiscal_period_num(p_fiscal_period_num) 
	DEFINE p_fiscal_period_num LIKE period.period_num 
	LET modu_fiscal_period_num = p_fiscal_period_num 
END FUNCTION 

###########################################################################
# FUNCTION get_url_fiscal_period_num()
#
# Accessor Method for URL modu_fiscal_period_num
###########################################################################
FUNCTION get_url_fiscal_period_num() 
	RETURN modu_fiscal_period_num 
END FUNCTION 

###########################################################################
# FUNCTION set_url_fiscal_month_num(p_fiscal_month_num)
#
# Accessor Method for URL modu_fiscal_month_num
###########################################################################
FUNCTION set_url_fiscal_month_num(p_fiscal_month_num) 
	DEFINE p_fiscal_month_num SMALLINT 
	LET modu_fiscal_month_num = p_fiscal_month_num 
END FUNCTION 

###########################################################################
# FUNCTION get_url_fiscal_month_num()
#
# Accessor Method for URL modu_fiscal_month_num
###########################################################################
FUNCTION get_url_fiscal_month_num() 
	RETURN modu_fiscal_month_num 
END FUNCTION 



###########################################################################
# FUNCTION set_url_fiscal_date(p_fiscal_date)
#
# Accessor Method for URL modu_fiscal_date
###########################################################################
FUNCTION set_url_fiscal_date(p_fiscal_date) 
	DEFINE p_fiscal_date DATE 
	LET modu_fiscal_date = p_fiscal_date 
END FUNCTION 

###########################################################################
# FUNCTION get_url_fiscal_date()
#
# Accessor Method for URL modu_fiscal_date
###########################################################################
FUNCTION get_url_fiscal_date() 
	RETURN modu_fiscal_date 
END FUNCTION 


###########################################################################
# FUNCTION set_url_int1(p_argInt1)
#
# Accessor Method for modu_argInt1
###########################################################################
FUNCTION set_url_int1(p_argint1) 
	DEFINE p_argint1 SMALLINT 

	IF modu_argint1_set = false OR modu_argint1_set IS NULL THEN 
		LET modu_argint1 = p_argint1 
		CALL fgl_setenv("ARGINT1",modu_argInt1) 
		LET modu_argint1_set = true 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION get_url_int1()
#
# Accessor Method for modu_argInt1
###########################################################################
FUNCTION get_url_int1() 

	IF modu_argint1_set = false OR modu_argint1_set IS NULL THEN 
		IF fgl_getenv("ARGINT1") IS NULL THEN 
			LET modu_argint1 = NULL 
			#CALL fgl_winmessage("argInt1 NOT specified","You need TO specify the value of argInt1\nIn the environment OR in the URL!","error")
		ELSE 
			CALL set_url_int1(fgl_getenv("ARGINT1")) 
		END IF 
	END IF 

	RETURN modu_argint1 
END FUNCTION 

###########################################################################
# FUNCTION get_argInt1_set()
#
# Accessor Method for modu_argInt1_set
###########################################################################
FUNCTION get_argint1_set() 
	RETURN modu_argint1_set 
END FUNCTION 



###########################################################################
# FUNCTION set_url_int2(p_argInt2)
#
# Accessor Method for modu_argInt2
###########################################################################
FUNCTION set_url_int2(p_argint2) 
	DEFINE p_argint2 SMALLINT 

	IF modu_argint2_set = false OR modu_argint2_set IS NULL THEN 
		LET modu_argint2 = p_argint2 
		CALL fgl_setenv("ARGINT2",modu_argInt2) 
		LET modu_argint2_set = true 
	END IF 
END FUNCTION 

###########################################################################
# FUNCTION get_url_int2()
#
# Accessor Method for modu_argInt2
###########################################################################
FUNCTION get_url_int2() 

	IF modu_argint2_set = false OR modu_argint2_set IS NULL THEN 
		IF fgl_getenv("ARGINT2") IS NULL THEN 
			#CALL fgl_winmessage("ARGINT2 NOT specified","You need TO specify the value of argInt2\nIn the environment OR in the URL!","error")
			LET modu_argint2 = NULL 
		ELSE 
			CALL set_url_int2(fgl_getenv("ARGINT2")) 
		END IF 
	END IF 

	RETURN modu_argint2 
END FUNCTION 

###########################################################################
# FUNCTION get_argInt2_set()
#
# Accessor Method for modu_argInt2_set
###########################################################################
FUNCTION get_argint2_set() 
	RETURN modu_argint2_set 
END FUNCTION 

###########################################################################
# FUNCTION set_url_str1(p_argStr1)
#
# Accessor Method for modu_argStr1
###########################################################################
FUNCTION set_url_str1(p_argstr1) 
	DEFINE p_argstr1 STRING 

	IF modu_argstr1_set = false OR modu_argstr1_set IS NULL THEN 
		LET modu_argstr1 = p_argstr1 
		CALL fgl_setenv("ARGSTR1",modu_argStr1) 
		LET modu_argstr1_set = true 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION get_url_str1()
#
# Accessor Method for modu_argStr1
###########################################################################
FUNCTION get_url_str1() 

	IF modu_argstr1_set = false OR modu_argstr1_set IS NULL THEN 
		IF fgl_getenv("ARGSTR1") IS NULL THEN 
			#CALL fgl_winmessage("argStr1 NOT specified","You need TO specify the value of argStr1\nIn the environment OR in the URL!","error")
			LET modu_argstr1 = NULL 
		ELSE 
			CALL set_url_str1(fgl_getenv("ARGSTR1")) 
		END IF 
	END IF 

	RETURN modu_argstr1 
END FUNCTION 

###########################################################################
# FUNCTION get_argStr1_set()
#
# Accessor Method for modu_argStr1_set
###########################################################################
FUNCTION get_argstr1_set() 
	RETURN modu_argstr1_set 
END FUNCTION 




###########################################################################
# FUNCTION set_url_str2(p_argStr2)
#
# Accessor Method for modu_argStr2
###########################################################################
FUNCTION set_url_str2(p_argstr2) 
	DEFINE p_argstr2 STRING 

	IF modu_argstr2_set = false OR modu_argstr2_set IS NULL THEN 
		LET modu_argstr2 = p_argstr2 
		CALL fgl_setenv("ARGSTR2",modu_argStr2) 
		LET modu_argstr2_set = true 
	END IF 
END FUNCTION 


###########################################################################
# FUNCTION get_url_str2()
#
# Accessor Method for modu_argStr2
###########################################################################
FUNCTION get_url_str2() 

	IF modu_argstr2_set = false OR modu_argstr2_set IS NULL THEN 
		IF fgl_getenv("ARGSTR2") IS NULL THEN 
			#CALL fgl_winmessage("argStr2 NOT specified","You need TO specify the value of argStr2\nIn the environment OR in the URL!","error")
			LET modu_argstr2 = NULL 
		ELSE 
			CALL set_url_str2(fgl_getenv("ARGSTR2")) 
		END IF 
	END IF 

	RETURN modu_argstr2 
END FUNCTION 

###########################################################################
# FUNCTION get_argStr2_set()
#
# Accessor Method for modu_argStr2_set
###########################################################################
FUNCTION get_argstr2_set() 
	RETURN modu_argstr2_set 
END FUNCTION 



###########################################################################
# FUNCTION set_url_order(p_order)
#
# Accessor Method for URL modu_order
###########################################################################
FUNCTION set_url_order(p_order) 
	DEFINE p_order STRING 
	#we need to add validations after we know, what order symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_order = p_order.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_order()
#
# Accessor Method for URL modu_order
###########################################################################
FUNCTION get_url_order() 
	RETURN modu_order 
END FUNCTION 



###########################################################################
# FUNCTION set_url_char(p_char)
#
# Accessor Method for URL modu_char
###########################################################################
FUNCTION set_url_char(p_char) 
	DEFINE p_char STRING 
	#we need to add validations after we know, what char symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_char = p_char.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_char()
#
# Accessor Method for URL modu_char
###########################################################################
FUNCTION get_url_char() 
	RETURN modu_char 
END FUNCTION 

###########################################################################
# FUNCTION set_url_menu_char2(p_menu_char2)
#
# Accessor Method for URL modu_menu_char2
###########################################################################
FUNCTION set_url_menu_char2(p_menu_char2) 
	DEFINE p_menu_char2 STRING 
	#we need to add validations after we know, what menu_char2 symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_menu_char2 = p_menu_char2.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_menu_char2()
#
# Accessor Method for URL modu_menu_char2
###########################################################################
FUNCTION get_url_menu_char2() 
	RETURN modu_menu_char2 
END FUNCTION 


###########################################################################
# FUNCTION set_url_zero_suppress(p_zero_suppress)
#
# Accessor Method for URL modu_zero_suppress
###########################################################################
FUNCTION set_url_zero_suppress(p_zero_suppress) 
	DEFINE p_zero_suppress STRING 
	#we need to add validations after we know, what zero_suppress symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_zero_suppress = p_zero_suppress.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_zero_suppress()
#
# Accessor Method for URL modu_zero_suppress
###########################################################################
FUNCTION get_url_zero_suppress() 
	RETURN modu_zero_suppress 
END FUNCTION 



###########################################################################
# FUNCTION set_url_voucher_option(p_voucher_option)
#
# Accessor Method for URL modu_voucher_option
###########################################################################
FUNCTION set_url_voucher_option(p_voucher_option) 
	DEFINE p_voucher_option STRING 
	#we need to add validations after we know, what voucher_option symbols are used/required
	
	LET p_voucher_option = p_voucher_option.touppercase()
	LET modu_voucher_option = p_voucher_option[1] 
END FUNCTION 

###########################################################################
# FUNCTION get_url_voucher_option()
#
# Accessor Method for URL modu_voucher_option
###########################################################################
FUNCTION get_url_voucher_option() 
	RETURN modu_voucher_option 
END FUNCTION 


###########################################################################
# FUNCTION set_url_invoice_text(p_invoice_text)
#
# Accessor Method for URL modu_invoice_text
###########################################################################
FUNCTION set_url_invoice_text(p_invoice_text) 
	DEFINE p_invoice_text STRING 
	#we need to add validations after we know, what invoice_text symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_invoice_text = p_invoice_text.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_invoice_text()
#
# Accessor Method for URL modu_invoice_text
###########################################################################
FUNCTION get_url_invoice_text() 
	RETURN modu_invoice_text 
END FUNCTION 

###########################################################################
# FUNCTION set_url_credit_text(p_credit_text)
#
# Accessor Method for URL modu_credit_text
###########################################################################
FUNCTION set_url_credit_text(p_credit_text) 
	DEFINE p_credit_text STRING 
	#we need to add validations after we know, what credit_text symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_credit_text = p_credit_text.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_credit_text()
#
# Accessor Method for URL modu_credit_text
###########################################################################
FUNCTION get_url_credit_text() 
	RETURN modu_credit_text 
END FUNCTION 

-------------------------------------------

###########################################################################
# FUNCTION set_url_child_run_once_only(p_modu_child_run_once_only)
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION set_url_child_run_once_only(p_modu_child_run_once_only) 
	DEFINE p_modu_child_run_once_only boolean 
	#we need to add validations after we know, what file_name symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_child_run_once_only = p_modu_child_run_once_only 
END FUNCTION 

###########################################################################
# FUNCTION get_url_child_run_once_only()
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION get_url_child_run_once_only() 
	RETURN modu_child_run_once_only 
END FUNCTION 


###########################################################################
# FUNCTION set_url_verbose(p_modu_verbose)
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION set_url_verbose(p_modu_verbose) 
	DEFINE p_modu_verbose boolean 
	#we need to add validations after we know, what file_name symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_verbose = p_modu_verbose 
END FUNCTION 

###########################################################################
# FUNCTION get_url_verbose()
#
# Accessor Method for URL modu_file_name
###########################################################################
FUNCTION get_url_verbose() 
	RETURN modu_verbose 
END FUNCTION 


-------------------------------------------------


###########################################################################
# FUNCTION set_url_post_run_num(p_post_run_num)
#
# Accessor Method for URL modu_post_run_num
###########################################################################
FUNCTION set_url_post_run_num(p_post_run_num) 
	DEFINE p_post_run_num STRING 
	#we need to add validations after we know, what post_run_num symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_post_run_num = p_post_run_num.touppercase() 
END FUNCTION 

###########################################################################
# FUNCTION get_url_post_run_num()
#
# Accessor Method for URL modu_post_run_num
###########################################################################
FUNCTION get_url_post_run_num() 
	RETURN modu_post_run_num 
END FUNCTION 

---------------------------------------------------------------------

###########################################################################
# FUNCTION set_url_autopost(p_autopost)
#
# Accessor Method for URL modu_autopost
###########################################################################
FUNCTION set_url_autopost(p_autopost) 
	DEFINE p_autopost CHAR(1) 
	#we need to add validations after we know, what autopost symbols are used/required
	#so far, I have seen "D" and "S"
	LET modu_autopost = p_autopost 
END FUNCTION 

###########################################################################
# FUNCTION get_url_autopost()
#
# Accessor Method for URL modu_autopost
###########################################################################
FUNCTION get_url_autopost() 
	RETURN modu_autopost 
END FUNCTION 


###########################################################################
# FUNCTION set_url_switch(p_switch)
#
# Accessor Method for URL modu_switch
###########################################################################
FUNCTION set_url_switch(p_switch) 
	DEFINE p_switch STRING 
	
	IF ((p_switch IS NOT NULL) AND (p_switch != FALSE) AND (p_switch != 'OFF') AND (p_switch != 'No') AND (p_switch != 'N')) THEN
		LET modu_switch = TRUE
	ELSE
		LET modu_switch = FALSE
	END IF		
	#we need to add validations after we know, what switch symbols are used/required
	#so far, I have seen "Y" and "N"
	#LET modu_switch = p_switch 
END FUNCTION 

###########################################################################
# FUNCTION get_url_switch()
#
# Accessor Method for URL modu_switch
###########################################################################
FUNCTION get_url_switch()
	IF modu_switch IS NULL THEN
		LET modu_switch = FALSE
	END IF 
	RETURN modu_switch 
END FUNCTION 


###########################################################################
# FUNCTION set_url_tempper(p_tempper)
#
# Accessor Method for URL modu_tempper
###########################################################################
FUNCTION set_url_tempper(p_tempper) 
	DEFINE p_tempper SMALLINT 
	LET modu_tempper = p_tempper 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tempper()
#
# Accessor Method for URL modu_tempper
###########################################################################
FUNCTION get_url_tempper() 
	RETURN modu_tempper 
END FUNCTION 


########################################
# For toolbar manager
########################################

###########################################################################
# FUNCTION set_url_tb_project_name(p_tb_project_name)
#
# Accessor Method for URL modu_tb_project_name
###########################################################################
FUNCTION set_url_tb_project_name(p_tb_project_name) 
	DEFINE p_tb_project_name STRING 

	LET modu_tb_project_name = p_tb_project_name 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tb_project_name()
#
# Accessor Method for URL modu_tb_project_name
###########################################################################
FUNCTION get_url_tb_project_name() 
	RETURN modu_tb_project_name 
END FUNCTION 


###########################################################################
# FUNCTION set_url_tb_module_name(p_tb_module_name)
#
# Accessor Method for URL modu_tb_module_name
###########################################################################
FUNCTION set_url_tb_module_name(p_tb_module_name) 
	DEFINE p_tb_module_name STRING 

	LET modu_tb_module_name = p_tb_module_name 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tb_module_name()
#
# Accessor Method for URL modu_tb_module_name
###########################################################################
FUNCTION get_url_tb_module_name() 
	RETURN modu_tb_module_name 
END FUNCTION 


###########################################################################
# FUNCTION set_url_tb_menu_name(p_tb_menu_name)
#
# Accessor Method for URL modu_tb_menu_name
###########################################################################
FUNCTION set_url_tb_menu_name(p_tb_menu_name) 
	DEFINE p_tb_menu_name STRING 

	LET modu_tb_menu_name = p_tb_menu_name 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tb_menu_name()
#
# Accessor Method for URL modu_tb_menu_name
###########################################################################
FUNCTION get_url_tb_menu_name() 
	RETURN modu_tb_menu_name 
END FUNCTION 


###########################################################################
# FUNCTION set_url_tb_user_name(p_tb_user_name)
#
# Accessor Method for URL modu_tb_user_name
###########################################################################
FUNCTION set_url_tb_user_name(p_tb_user_name) 
	DEFINE p_tb_user_name STRING 

	LET modu_tb_user_name = p_tb_user_name 
END FUNCTION 

###########################################################################
# FUNCTION get_url_tb_user_name()
#
# Accessor Method for URL modu_tb_user_name
###########################################################################
FUNCTION get_url_tb_user_name() 
	RETURN modu_tb_user_name 
END FUNCTION 


