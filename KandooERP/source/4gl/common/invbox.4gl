###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################


###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION Name:        invoice_INITIALIZE
# Description:          Used TO INITIALIZE the invoicehead RECORD with
#                       appropriate VALUES passed INTO this FUNCTION.
#                       Also provide the option TO CLEAR the invoicedetl
#                       temporary table.
# Passed: (Legend: M=Mandatory O=Optional)
# M p_cmpy_code   this IS the company code TO be stamped on the invoicehead
# M p_cust_code   this IS the customer code TO be stamped on the invoicehead
# O p_ord_num     this IS the ORDER number (IF exists) which the invoice
#                  will be produced FROM.
# O p_job_code    this IS the relative job code (IF exists)
# M p_whom        the sign on code of the person entering this invoice
# M pr_entry_date  the entry date of the invoice
# M p_proc_temp   TRUE OR FALSE; whether TO CLEAR the t_invoicedetl
#                  temp table records.
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   l_rec_ps_invoicehead IF above TRUE; INITIALIZEd invoicehead record.
#   l_pr_error_text  IS used TO show a brief description of the error found
#                  WHEN validating invoicehead details.

###########################################################################
# FUNCTION invoice_initialize(p_cmpy_code,p_cust_code,p_ord_num,p_job_code,p_whom,p_inv_date,p_proc_temp)
#
#
###########################################################################
FUNCTION invoice_initialize(p_cmpy_code,p_cust_code,p_ord_num,p_job_code,p_whom,p_inv_date,p_proc_temp) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE invoicehead.cust_code 
	DEFINE p_ord_num LIKE invoicehead.ord_num 
	DEFINE p_job_code LIKE invoicehead.job_code 
	DEFINE p_whom LIKE invoicehead.entry_code 
	DEFINE p_inv_date LIKE invoicehead.inv_date 
	DEFINE p_proc_temp SMALLINT
	DEFINE l_rec_ps_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_pr_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_pr_error_text CHAR(40) 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	### Has the calling FUNCTION selected TO CLEAR the temporary table FOR ###
	### invoice detail lines                                               ###
 
	IF p_proc_temp THEN 
		DELETE FROM t_invoicedetl WHERE 1=1; 
	END IF 

	### INITIALIZE invoicehead RECORD ###
	INITIALIZE l_rec_pr_invoicehead.* TO NULL 
	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy_code 
	IF status <> 0 THEN 
		LET l_pr_error_text = "Company Code NOT Valid - invbox" 
		RETURN FALSE, l_rec_pr_invoicehead.*, l_pr_error_text 
	END IF 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = l_rec_company.cmpy_code 
	IF status <> 0 THEN 
		LET l_pr_error_text = "Customer Code NOT Valid - invbox" 
		RETURN FALSE, l_rec_pr_invoicehead.*, l_pr_error_text 
	END IF 

	### INITIALIZE other RECORD variables ###
	LET l_rec_pr_invoicehead.cmpy_code = l_rec_company.cmpy_code 
	LET l_rec_pr_invoicehead.cust_code = l_rec_customer.cust_code 
	LET l_rec_pr_invoicehead.ord_num = p_ord_num 
	LET l_rec_pr_invoicehead.job_code = p_job_code 
	LET l_rec_pr_invoicehead.inv_date = p_inv_date 
	LET l_rec_pr_invoicehead.entry_code = p_whom 
	LET l_rec_pr_invoicehead.entry_date = today 
	LET l_rec_pr_invoicehead.sale_code = l_rec_customer.sale_code 
	LET l_rec_pr_invoicehead.term_code = l_rec_customer.term_code 
	LET l_rec_pr_invoicehead.disc_per = 0 
	LET l_rec_pr_invoicehead.tax_code = l_rec_customer.tax_code 
	LET l_rec_pr_invoicehead.goods_amt = 0 
	LET l_rec_pr_invoicehead.hand_amt = 0 
	LET l_rec_pr_invoicehead.hand_tax_code = l_rec_customer.tax_code 
	LET l_rec_pr_invoicehead.hand_tax_amt = 0 
	LET l_rec_pr_invoicehead.freight_amt = 0 
	LET l_rec_pr_invoicehead.freight_tax_code = l_rec_customer.tax_code 
	LET l_rec_pr_invoicehead.freight_tax_amt = 0 
	LET l_rec_pr_invoicehead.tax_amt = 0 
	LET l_rec_pr_invoicehead.disc_amt = 0 
	LET l_rec_pr_invoicehead.total_amt = 0 
	LET l_rec_pr_invoicehead.cost_amt = 0 
	LET l_rec_pr_invoicehead.paid_amt = 0 
	LET l_rec_pr_invoicehead.disc_taken_amt = 0 
	LET l_rec_pr_invoicehead.on_state_flag = 'N' 
	LET l_rec_pr_invoicehead.posted_flag = 'N' 
	LET l_rec_pr_invoicehead.seq_num = 0 
	LET l_rec_pr_invoicehead.line_num = 0 
	LET l_rec_pr_invoicehead.printed_num = 1 
	LET l_rec_pr_invoicehead.story_flag = 'N' 
	LET l_rec_pr_invoicehead.prepaid_flag = 'N' 
	LET l_rec_pr_invoicehead.rev_date = l_rec_pr_invoicehead.inv_date 
	LET l_rec_pr_invoicehead.rev_num = 0 
	LET l_rec_pr_invoicehead.cost_ind = 'L' 
	LET l_rec_pr_invoicehead.currency_code = l_rec_customer.currency_code 
	LET l_rec_pr_invoicehead.conv_qty = 1.0 

	IF l_rec_pr_invoicehead.currency_code != l_rec_company.curr_code THEN 
		CALL get_conv_rate(
			l_rec_pr_invoicehead.cmpy_code, 
			l_rec_pr_invoicehead.currency_code, 
			l_rec_pr_invoicehead.inv_date, 
			CASH_EXCHANGE_BUY) 
		RETURNING l_rec_pr_invoicehead.conv_qty 
	END IF 

	LET l_rec_pr_invoicehead.inv_ind = 1 
	LET l_rec_pr_invoicehead.prev_paid_amt = 0 
	LET l_rec_pr_invoicehead.price_tax_flag = '0' 
	LET l_rec_pr_invoicehead.invoice_to_ind = l_rec_customer.invoice_to_ind 
	LET l_rec_pr_invoicehead.territory_code = l_rec_customer.territory_code 
	LET l_rec_pr_invoicehead.country_code = l_rec_customer.country_code 
	LET l_rec_pr_invoicehead.cond_code = l_rec_customer.cond_code 
	LET l_rec_pr_invoicehead.scheme_amt = 0 

	SELECT mgr_code INTO l_rec_pr_invoicehead.mgr_code 
	FROM salesperson 
	WHERE cmpy_code = l_rec_pr_invoicehead.cmpy_code 
	AND sale_code = l_rec_customer.sale_code 

	SELECT area_code INTO l_rec_pr_invoicehead.area_code 
	FROM territory 
	WHERE cmpy_code = l_rec_pr_invoicehead.cmpy_code 
	AND terr_code = l_rec_customer.territory_code 

	CALL get_fiscal_year_period_for_date(l_rec_pr_invoicehead.cmpy_code,l_rec_pr_invoicehead.inv_date) 
	RETURNING 
		l_rec_pr_invoicehead.year_num, 
		l_rec_pr_invoicehead.period_num 
	
	IF (l_rec_pr_invoicehead.year_num IS NULL) OR	(l_rec_pr_invoicehead.period_num IS NULL)	THEN 
		LET l_pr_error_text = "Invalid Year/Period Found - invbox" 
		RETURN FALSE, l_rec_pr_invoicehead.*, l_pr_error_text 
	END IF 

	SELECT * INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = l_rec_pr_invoicehead.cmpy_code 
	AND term_code = l_rec_pr_invoicehead.term_code 
	IF status = 0 THEN 
		CALL get_due_and_discount_date(l_rec_term.*, l_rec_pr_invoicehead.inv_date) 
		RETURNING l_rec_pr_invoicehead.due_date, 
		l_rec_pr_invoicehead.disc_date 
	ELSE 
		### Use the default VALUES ###
		LET l_rec_pr_invoicehead.due_date = l_rec_pr_invoicehead.inv_date 
		LET l_rec_pr_invoicehead.disc_date = l_rec_pr_invoicehead.inv_date 
	END IF
	 
	SELECT tax_per INTO l_rec_pr_invoicehead.tax_per 
	FROM tax 
	WHERE cmpy_code = l_rec_pr_invoicehead.cmpy_code 
	AND tax_code = l_rec_pr_invoicehead.tax_code 
	IF status = notfound THEN 
		LET l_rec_pr_invoicehead.tax_per = 0 
	END IF
	 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	RETURN TRUE, l_rec_pr_invoicehead.*, l_pr_error_text 
END FUNCTION
###########################################################################
# END FUNCTION invoice_initialize(p_cmpy_code,p_cust_code,p_ord_num,p_job_code,p_whom,p_inv_date,p_proc_temp)
###########################################################################


 
##############################################################################
# FUNCTION Name:        invoicedetl_INITIALIZE
# Description:          Used TO INITIALIZE an invoicedetl RECORD TO pass back
#                       TO the calling FUNCTION
#                       IMPORTANT - temp table t_invoicedetl records
# Passed: (Legend: M=Mandatory O=Optional)
# M pr_cmpy        this will be the company code TO be stamped on the invoice
#                  detail line.
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   ps_invoicedetl IF above TRUE; validated invoicehead record.
#   l_error_text  IS used TO show a brief description of the error found
#                  WHEN validating invoicehead details.
##############################################################################
FUNCTION invoicedetl_initialize(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_error_text CHAR(40) 

	### The setup routine will INITIALIZE an invoicedetl RECORD THEN ###
	### pass back the INITIALIZEd RECORD TO the calling FUNCTION     ###
	INITIALIZE l_rec_invoicedetl.* TO NULL 
	LET l_error_text = NULL 
	LET l_rec_invoicedetl.cmpy_code = p_cmpy_code 
	LET l_rec_invoicedetl.ord_qty = 0 
	LET l_rec_invoicedetl.ship_qty = 0 
	LET l_rec_invoicedetl.prev_qty = 0 
	LET l_rec_invoicedetl.back_qty = 0 
	LET l_rec_invoicedetl.ser_flag = 'N' 
	LET l_rec_invoicedetl.ser_qty = 0 
	LET l_rec_invoicedetl.unit_cost_amt = 0 
	LET l_rec_invoicedetl.ext_cost_amt = 0 
	LET l_rec_invoicedetl.disc_amt = 0 
	LET l_rec_invoicedetl.disc_per = 0 
	LET l_rec_invoicedetl.unit_tax_amt = 0 
	LET l_rec_invoicedetl.ext_tax_amt = 0 
	LET l_rec_invoicedetl.level_code = 'L' 
	LET l_rec_invoicedetl.comm_amt = 0 
	LET l_rec_invoicedetl.sold_qty = 0 
	LET l_rec_invoicedetl.bonus_qty = 0 
	LET l_rec_invoicedetl.ext_bonus_amt = 0 
	LET l_rec_invoicedetl.ext_stats_amt = 0 
	LET l_rec_invoicedetl.list_price_amt = 0 

	RETURN TRUE, l_rec_invoicedetl.*, l_error_text 
END FUNCTION 
##############################################################################
# FUNCTION invoicedetl_initialize(p_cmpy_code) 
##############################################################################
 


#########################################################################
#FUNCTION invoice_verify(p_rec_invoicehead) 
#
# FUNCTION Name:        invoice_verify
# Description:          Used TO validate an invoice RECORD TO ensure all
#                       fields must exist TO create the RECORD are present
# Passed:
#   p_rec_invoicehead      the invoicehead RECORD prior TO all validation checks
#
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   l_rec_invoicehead      the complete/validated invoicehead record
#   l_pr_error_text       used TO indicate in brief the error that occurred
#                       IF the invoice_verify routine fails; NULL OTHERWISE
#########################################################################
FUNCTION invoice_verify(p_rec_invoicehead) 
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_pr_error_text CHAR(40) 

	### Setup all the fields in the invoicehead table based upon the passed
	### record.  THEN fill in the defaults AND blanks.

	###INITIALIZE the RECORD variables###
	INITIALIZE l_rec_invoicehead.* TO NULL 
	LET l_rec_invoicehead.* = p_rec_invoicehead.* 
	
	IF (l_rec_invoicehead.cmpy_code IS NULL) OR	(l_rec_invoicehead.cmpy_code = " ")	THEN 
		LET l_pr_error_text = "Company Code IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.cust_code IS NULL) OR (l_rec_invoicehead.cust_code = " ")	THEN 
		LET l_pr_error_text = "Customer IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.entry_code IS NULL) OR(l_rec_invoicehead.entry_code = " ")	THEN 
		LET l_pr_error_text = "User Login Code IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.entry_date IS NULL) OR	(l_rec_invoicehead.entry_date = " ")	THEN 
		LET l_pr_error_text = "User Login Date IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.inv_date IS NULL) OR	(l_rec_invoicehead.inv_date = " ")	THEN 
		LET l_pr_error_text = "Transaction Date IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.due_date IS NULL) OR	(l_rec_invoicehead.due_date = " ")	THEN 
		LET l_pr_error_text = "Transaction Due Date IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (p_rec_invoicehead.year_num IS NULL) OR	(p_rec_invoicehead.period_num IS NULL)	THEN 
		LET l_pr_error_text = "Fiscal Year/Period IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.currency_code IS NULL) OR	(l_rec_invoicehead.currency_code = " ")	THEN 
		LET l_pr_error_text = "Currency Code IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.conv_qty IS NULL) OR	(l_rec_invoicehead.conv_qty = 0)	THEN 
		LET l_pr_error_text = "Conversion Quantity IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	IF (l_rec_invoicehead.country_code IS NULL) OR	(l_rec_invoicehead.country_code = " ")	THEN 
		LET l_pr_error_text = "Country Code IS Blank - invbox" 
		RETURN FALSE, l_rec_invoicehead.*, l_pr_error_text 
	END IF 
	
	LET l_pr_error_text = NULL 
	RETURN TRUE, l_rec_invoicehead.*, l_pr_error_text 
END FUNCTION 
#########################################################################
# END FUNCTION invoice_verify(p_rec_invoicehead) 
#########################################################################


#########################################################################
# FUNCTION invoicedetail_verify(p_rec_invoicedetl) 
#
# FUNCTION Name:        invoicedetail_verify
# Description:          Used TO validate an invoice detail record
# Passed:
#   p_rec_invoicedetl      the invoicedetl RECORD prior TO all validation checks
#
# Returned:
#   TRUE/FALSE          FALSE-IF errors encountered;TRUE-no errors encountered
#   l_rec_invoicedetl      the complete/validated invoicehead record
#   l_error_text       used TO indicate in brief the error that occurred
#                       IF the invoicedetail_verify routine fails; NULL othwise
#########################################################################
FUNCTION invoicedetail_verify(p_rec_invoicedetl) 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_error_text CHAR(40) 

	### Setup all the fields in the invoicedetl table based upon the passed
	### record.  THEN fill in the defaults AND blanks.

	###INITIALIZE the RECORD variables###
	INITIALIZE l_rec_invoicedetl.* TO NULL 
	
	LET l_rec_invoicedetl.* = p_rec_invoicedetl.* 
	
	IF (l_rec_invoicedetl.cmpy_code IS NULL) OR (l_rec_invoicedetl.cmpy_code = " ")	THEN 
		LET l_error_text = "Company Code IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicedetl.*, l_error_text 
	END IF 
	
	IF (l_rec_invoicedetl.cust_code IS NULL) OR	(l_rec_invoicedetl.cust_code = " ")	THEN 
		LET l_error_text = "Customer IS Blank - invbox" 
		RETURN FALSE, p_rec_invoicedetl.*, l_error_text 
	END IF
	 
	LET l_error_text = NULL 
	RETURN TRUE, l_rec_invoicedetl.*, l_error_text 
END FUNCTION 
#########################################################################
# END FUNCTION invoicedetail_verify(p_rec_invoicedetl) 
#########################################################################
 

##############################################################################
# FUNCTION write_invoice(p_rec_invoicehead,p_mode)
#
# FUNCTION Name:        write_invoice
# Description:          Used TO UPDATE/INSERT invoice details TO the database
#                       IMPORTANT - temp table t_invoicedetl records
#                       represent invoicedetl RECORD details FOR the passed
#                       invoicehead
# Procedure:
#    Database UPDATE/INSERT works in the following manner
#       0.  Lock customer
#       1.  IF edit THEN
#       2.     - UPDATE prodstatus
#       3.     - INSERT neg prodledg
#       4.     - delete line items
#       5.     - UPDATE customer
#       6.     - INSERT audit
#       7.  END IF
#       8.  IF add THEN
#       9.     - get next invoice number
#       10. END IF
#       11. INSERT line items
#       12. UPDATE prodstatus
#       13. INSERT prodledg
#       14. IF add THEN
#       15.    - INSERT header
#       16. ELSE
#       17.    - UPDATE header
#       18. END IF
#       19. INSERT audit
#       20. UPDATE customer
# Passed:
#   p_rec_invoicehead this will be the cheque RECORD FROM the calling FUNCTION
#   p_mode        this value represents INSERT OR UPDATE mode; possible
#                  VALUES are "ADD" - INSERT mode; anything ELSE FOR UPDATE
# Returned:
#   TRUE/FALSE     FALSE - IF errors encountered; TRUE - no errors encountered
#   ps_inv_num     IF above TRUE; invoice number updated OR inserted
#   l_error_text  IF above FALSE; will represent the error that occured;
#                  OTHERWISE NULL
##############################################################################
FUNCTION write_invoice(p_rec_invoicehead,p_mode) 
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_mode CHAR(4) 
	DEFINE l_error_text CHAR(40) 
	DEFINE l_err_message CHAR(100) 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_temp_text CHAR(300) 
	DEFINE l_status INTEGER 
	DEFINE l_inv_num LIKE invoicehead.inv_num 

	##
	## Declare dynamic cursors
	##
	DECLARE c_t_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl ORDER BY line_num 
	LET l_temp_text = 
		"SELECT * FROM prodstatus ", 
		" WHERE cmpy_code ='",p_rec_invoicehead.cmpy_code,"' ", 
		" AND part_code = ? AND ware_code = ? " 
	
	PREPARE s_prodstatus FROM l_temp_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 
	
	GOTO bypass 
	LABEL founderror: 
	LET l_status = status 
	LET l_err_message = l_err_message clipped, "-", l_status 
	
	CALL errorlog(l_err_message) 
	RETURN FALSE, l_inv_num, l_error_text 
	LABEL bypass: 
	WHENEVER ERROR GOTO founderror
	
	#INSERT invoiceDetl Record 
	DECLARE c1_invoicedetl CURSOR FOR 
	INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)

	LET l_error_text = "InvoiceDetl Cursor Open Error - invbox" 

	OPEN c1_invoicedetl 
	DECLARE c_prodledg CURSOR FOR 
	INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

	LET l_error_text = "ProdLedg Cursor Open Error - invbox" 

	OPEN c_prodledg 
	DECLARE c_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
	AND cust_code = p_rec_invoicehead.cust_code 
	FOR UPDATE 

	LET l_error_text = "Customer Cursor Open Error - invbox" 

	OPEN c_customer 

	LET l_error_text = "Customer Fetch Error - invbox" 

	FETCH c_customer INTO l_rec_customer.* 

	IF p_mode = "ADD" THEN 
		LET l_error_text = "Next Invoice Number Failed - invbox" 
		LET p_rec_invoicehead.inv_num =	next_trans_num(
			p_rec_invoicehead.cmpy_code, 
			TRAN_TYPE_INVOICE_IN, 
			p_rec_invoicehead.acct_override_code) 
		
		IF p_rec_invoicehead.inv_num < 0 THEN 
			LET status = p_rec_invoicehead.inv_num 
			GOTO founderror 
		END IF 
	ELSE 
		## Obtain existing invoicehead TO ensure no second edit OR
		## posting has occurred.
		DECLARE c_invoicehead CURSOR FOR 
		SELECT * FROM invoicehead 
		WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
		AND inv_num = p_rec_invoicehead.inv_num 
		FOR UPDATE 
		
		OPEN c_invoicehead 
		
		FETCH c_invoicehead INTO l_rec_invoicehead.* 
		IF l_rec_invoicehead.rev_num != p_rec_invoicehead.rev_num THEN 
			LET l_error_text = "Invoice Being Edited - invbox" 
			GOTO founderror 
		END IF 
		
		IF l_rec_invoicehead.posted_flag = "Y" THEN 
			LET l_error_text = "Invoice Already Posted - invbox" 
			GOTO founderror 
		END IF 
		
		LET p_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt 
		LET p_rec_invoicehead.posted_flag = l_rec_invoicehead.posted_flag 
		LET p_rec_invoicehead.story_flag = l_rec_invoicehead.posted_flag 
		LET p_rec_invoicehead.rev_date = today 
		LET l_error_text = "Customer Backout Failed - invbox" 
		
		##
		## Undo stock STATUS UPDATE
		##
		DECLARE c_invoicedetl CURSOR FOR 
		SELECT * FROM invoicedetl 
		WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
		AND inv_num = p_rec_invoicehead.inv_num 
		AND part_code IS NOT NULL 
		AND ship_qty != 0 
		
		FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
			LET l_error_text = "Product Status Open Error 1 - invbox" 
			OPEN c_prodstatus USING 
				l_rec_invoicedetl.part_code, 
				l_rec_invoicedetl.ware_code 
			
			LET l_error_text = "Product Status Fetch Error - invbox" 
			FETCH c_prodstatus INTO l_rec_prodstatus.* 
			IF l_rec_prodstatus.onhand_qty IS NULL THEN 
				LET l_rec_prodstatus.onhand_qty = 0 
			END IF 
			
			LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
			
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty	+ l_rec_invoicedetl.ship_qty 
				LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty 

			END IF 

			LET l_error_text = "Product Ledger Insert Failed - invbox" 
			LET l_rec_prodledg.cmpy_code = p_rec_invoicehead.cmpy_code 
			LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
			LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
			LET l_rec_prodledg.tran_date = today 
			LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
			LET l_rec_prodledg.trantype_ind = "S" 
			LET l_rec_prodledg.year_num = p_rec_invoicehead.year_num 
			LET l_rec_prodledg.period_num = p_rec_invoicehead.period_num 
			LET l_rec_prodledg.source_text = l_rec_invoicedetl.cust_code 
			LET l_rec_prodledg.source_num = l_rec_invoicedetl.inv_num 
			LET l_rec_prodledg.tran_qty = l_rec_invoicedetl.ship_qty 
			LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
			LET l_rec_prodledg.hist_flag = "N" 
			LET l_rec_prodledg.post_flag = "N" 
			LET l_rec_prodledg.entry_code = p_rec_invoicehead.entry_code 
			LET l_rec_prodledg.entry_date = today 
			LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt / p_rec_invoicehead.conv_qty 
			LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt	/ p_rec_invoicehead.conv_qty 

			PUT c_prodledg 
			LET l_error_text = "Product Status Update Failed - invbox" 
			UPDATE prodstatus 

			SET onhand_qty = l_rec_prodstatus.onhand_qty, 
			reserved_qty = l_rec_prodstatus.reserved_qty, 
			seq_num = l_rec_prodstatus.seq_num 
			WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
			AND part_code = l_rec_prodstatus.part_code 
			AND ware_code = l_rec_prodstatus.ware_code 
		END FOREACH 

		##
		## Delete the invoice lines
		##
		LET l_error_text = "Invoice Line Delete Failed - invbox" 
		DELETE FROM invoicedetl 
		WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
		AND inv_num = p_rec_invoicehead.inv_num 
		
		LET l_rec_customer.bal_amt = l_rec_customer.bal_amt		- l_rec_invoicehead.total_amt 
		LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 

		INITIALIZE l_rec_araudit.* TO NULL 

		LET l_rec_araudit.cmpy_code = p_rec_invoicehead.cmpy_code 
		LET l_rec_araudit.tran_date = today 
		LET l_rec_araudit.cust_code = p_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Backout Invoice" 
		LET l_rec_araudit.tran_amt = (0 - l_rec_invoicehead.total_amt) 
		LET l_rec_araudit.entry_code = p_rec_invoicehead.entry_code 
		LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
		LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		LET l_error_text = "AR Audit Trail Insert Failed - invbox" 
		
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		
		LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	- l_rec_invoicehead.total_amt 
		LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt	- l_rec_customer.bal_amt 
		LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt - l_rec_invoicehead.total_amt 
		LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt - l_rec_invoicehead.total_amt 
	END IF 
	
	#---------------------------------------
	## INITIALIZE the sum-of-lines header fields
	##
	LET p_rec_invoicehead.cost_amt = 0 
	LET p_rec_invoicehead.tax_amt = 0 
	LET p_rec_invoicehead.goods_amt = 0 
	LET p_rec_invoicehead.line_num = 0 
	LET l_error_text = "Invoice Line Insert Failed - invbox"
	 
	OPEN c_t_invoicedetl 
	
	FOREACH c_t_invoicedetl INTO l_rec_invoicedetl.* 
		LET p_rec_invoicehead.line_num = p_rec_invoicehead.line_num + 1 
		LET l_rec_invoicedetl.cmpy_code = p_rec_invoicehead.cmpy_code 
		LET l_rec_invoicedetl.cust_code = p_rec_invoicehead.cust_code 
		LET l_rec_invoicedetl.inv_num = p_rec_invoicehead.inv_num 
		LET l_rec_invoicedetl.line_num = p_rec_invoicehead.line_num 
		IF l_rec_invoicedetl.ext_tax_amt IS NULL THEN 
			LET l_rec_invoicedetl.ext_tax_amt = 0 
		END IF 
		IF l_rec_invoicedetl.ext_sale_amt IS NULL THEN 
			LET l_rec_invoicedetl.ext_sale_amt = 0 
		END IF 

		IF l_rec_invoicedetl.line_total_amt IS NULL THEN 
			LET l_rec_invoicedetl.line_total_amt = 0 
		END IF 

		IF l_rec_invoicedetl.ext_cost_amt IS NULL THEN 
			LET l_rec_invoicedetl.ext_cost_amt = 0 
		END IF 

		IF l_rec_invoicedetl.part_code IS NOT NULL AND l_rec_invoicedetl.ship_qty != 0 THEN 
			LET l_error_text = "Product Status Open Error 2 - invbox" 

			OPEN c_prodstatus USING 
				l_rec_invoicedetl.part_code,
				l_rec_invoicedetl.ware_code 
			LET l_error_text = "Product Status Fetch Failed 2- invbox" 
			
			FETCH c_prodstatus INTO l_rec_prodstatus.* 
			
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
				LET l_rec_invoicedetl.seq_num = l_rec_prodstatus.seq_num 

				IF l_rec_prodstatus.onhand_qty IS NULL THEN 
					LET l_rec_prodstatus.onhand_qty = 0 
				END IF 

				LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty	- l_rec_invoicedetl.ship_qty 
				LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty 

				INITIALIZE l_rec_prodledg.* TO NULL 

				LET l_rec_prodledg.cmpy_code = l_rec_prodstatus.cmpy_code 
				LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
				LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
				LET l_rec_prodledg.tran_date = p_rec_invoicehead.inv_date 
				LET l_rec_prodledg.seq_num = l_rec_invoicedetl.seq_num 
				LET l_rec_prodledg.trantype_ind = "S" 
				LET l_rec_prodledg.year_num = p_rec_invoicehead.year_num 
				LET l_rec_prodledg.period_num = p_rec_invoicehead.period_num 
				LET l_rec_prodledg.source_text = l_rec_invoicedetl.cust_code 
				LET l_rec_prodledg.source_num = l_rec_invoicedetl.inv_num 
				LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty + 0 
				LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt			/ p_rec_invoicehead.conv_qty 
				LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt	/ p_rec_invoicehead.conv_qty 
				LET l_rec_prodledg.hist_flag = "N" 
				LET l_rec_prodledg.post_flag = "N" 
				LET l_rec_prodledg.entry_code = p_rec_invoicehead.entry_code 
				LET l_rec_prodledg.entry_date = today 
				LET l_error_text = "Product Ledger Insert Failed2- invbox" 
				PUT c_prodledg 
			END IF 
			
			LET l_error_text = "Product Status Update Failed2- invbox" 
			UPDATE prodstatus 
			SET 
				onhand_qty = l_rec_prodstatus.onhand_qty, 
				reserved_qty = l_rec_prodstatus.reserved_qty, 
				last_sale_date = p_rec_invoicehead.inv_date, 
				seq_num = l_rec_prodstatus.seq_num 
			WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
			AND part_code = l_rec_invoicedetl.part_code 
			AND ware_code = l_rec_invoicedetl.ware_code 
		END IF 

		LET l_rec_invoicedetl.line_acct_code =account_patch(
			p_rec_invoicehead.cmpy_code, 
			l_rec_invoicedetl.line_acct_code, 
			p_rec_invoicehead.acct_override_code) 
		
		LET l_error_text = "Invoice Detail Insert Failed2- invbox" 
		
		PUT c1_invoicedetl 
		LET p_rec_invoicehead.cost_amt = p_rec_invoicehead.cost_amt	+ l_rec_invoicedetl.ext_cost_amt 
		LET p_rec_invoicehead.tax_amt = p_rec_invoicehead.tax_amt + l_rec_invoicedetl.ext_tax_amt 
		LET p_rec_invoicehead.goods_amt = p_rec_invoicehead.goods_amt	+ l_rec_invoicedetl.ext_sale_amt 
	END FOREACH 
	
	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*
	
	LET p_rec_invoicehead.cost_ind = l_rec_arparms.costings_ind 
	LET p_rec_invoicehead.total_amt = p_rec_invoicehead.tax_amt 
	+ p_rec_invoicehead.goods_amt 
	+ p_rec_invoicehead.freight_amt 
	+ p_rec_invoicehead.freight_tax_amt 
	+ p_rec_invoicehead.hand_amt 
	+ p_rec_invoicehead.hand_tax_amt 

	IF p_mode = "EDIT" THEN 
		LET l_error_text = "Invoice Header Update Failed - invbox" 
		UPDATE invoicehead SET * = p_rec_invoicehead.* 
		WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
		AND inv_num = p_rec_invoicehead.inv_num 
	ELSE 
		LET l_error_text = "Invoice Header Insert Failed - invbox" 

		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
		ELSE
			DISPLAY l_rec_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 

		SELECT unique 1 FROM statparms 
		WHERE cmpy_code = p_rec_invoicehead.cmpy_code 
		IF status != notfound THEN 
			LET l_error_text = "Stats Trigger Insert Failed - invbox" 
			INSERT INTO stattrig VALUES (
				p_rec_invoicehead.cmpy_code, 
				TRAN_TYPE_INVOICE_IN, 
				p_rec_invoicehead.inv_num, 
				p_rec_invoicehead.inv_date) 
		END IF 
	END IF 

	#------------------------------
	# Now TO UPDATE customer
	#
	LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
	LET l_rec_customer.bal_amt = l_rec_customer.bal_amt	+ p_rec_invoicehead.total_amt 
	LET l_error_text = "AR Audit Trail Insert Failed2- invbox" 
	
	INITIALIZE l_rec_araudit.* TO NULL 
	
	LET l_rec_araudit.cmpy_code = p_rec_invoicehead.cmpy_code 
	LET l_rec_araudit.tran_date = p_rec_invoicehead.inv_date 
	LET l_rec_araudit.cust_code = p_rec_invoicehead.cust_code 
	LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
	LET l_rec_araudit.source_num = p_rec_invoicehead.inv_num 
	LET l_rec_araudit.tran_text = "Enter Invoice" 
	LET l_rec_araudit.tran_amt = p_rec_invoicehead.total_amt 
	LET l_rec_araudit.entry_code = p_rec_invoicehead.entry_code 
	LET l_rec_araudit.sales_code = p_rec_invoicehead.sale_code 
	LET l_rec_araudit.year_num = p_rec_invoicehead.year_num 
	LET l_rec_araudit.period_num = p_rec_invoicehead.period_num 
	LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
	LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
	LET l_rec_araudit.conv_qty = p_rec_invoicehead.conv_qty 
	LET l_rec_araudit.entry_date = today 

	INSERT INTO araudit VALUES (l_rec_araudit.*) 

	LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + p_rec_invoicehead.total_amt 
	IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
		LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
	END IF 
	
	LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
	- l_rec_customer.bal_amt 
	- l_rec_customer.onorder_amt 

	IF year(p_rec_invoicehead.inv_date) > year(l_rec_customer.last_inv_date) THEN 
		LET l_rec_customer.ytds_amt = 0 
		LET l_rec_customer.mtds_amt = 0 
	END IF 

	LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt	+ p_rec_invoicehead.total_amt 

	IF month(p_rec_invoicehead.inv_date)>month(l_rec_customer.last_inv_date) THEN 
		LET l_rec_customer.mtds_amt = 0 
	END IF 

	LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt+ p_rec_invoicehead.total_amt 
	LET l_rec_customer.last_inv_date = p_rec_invoicehead.inv_date 
	LET l_error_text = "Customer Update Failed 2 - invbox" 

	UPDATE customer 
	SET 
		next_seq_num = l_rec_customer.next_seq_num, 
		bal_amt = l_rec_customer.bal_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		highest_bal_amt = l_rec_customer.highest_bal_amt, 
		cred_bal_amt = l_rec_customer.cred_bal_amt, 
		last_inv_date = l_rec_customer.last_inv_date, 
		ytds_amt = l_rec_customer.ytds_amt, 
		mtds_amt = l_rec_customer.mtds_amt 
	WHERE cmpy_code = l_rec_customer.cmpy_code 
	AND cust_code = l_rec_customer.cust_code 
	LET l_error_text = NULL 

	RETURN TRUE, p_rec_invoicehead.inv_num, l_error_text 
END FUNCTION 
##############################################################################
# FUNCTION write_invoice(p_rec_invoicehead,p_mode)
##############################################################################