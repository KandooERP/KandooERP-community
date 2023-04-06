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

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION conv_currency(p_source_amt, p_cmpy_code, p_curr_code, p_to_from, p_tran_date,p_rate_type)
#
# \brief module - conv_curr
# Purpose - FUNCTION conv_currency converts amount
#           FROM currency TO currency
#           F- FROM foreign
#           T- TO foreign
############################################################
FUNCTION conv_currency(p_source_amt,p_cmpy_code, p_curr_code,p_to_from,p_tran_date,p_rate_type) 
	DEFINE p_source_amt DECIMAL(18,4) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_curr_code LIKE currency.currency_code 
	DEFINE p_to_from CHAR(1) 
	DEFINE p_tran_date DATE 
	DEFINE p_rate_type CHAR(1)
	DEFINE l_rec_rate_exchange RECORD LIKE rate_exchange.* 
	DEFINE l_conversion_qty LIKE rate_exchange.conv_buy_qty 
	DEFINE l_err_message STRING 
	DEFINE l_start_date DATE 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_conv_amt DECIMAL(18,4)
	DEFINE l_msg STRING

	DEFER QUIT 
	DEFER INTERRUPT 
	
	IF p_curr_code = glob_rec_glparms.base_currency_code THEN --glob_rec_company.curr_code THEN #HuHO: QA Anna feedback on exchange conversion problems in reports #KD-2576
		RETURN p_source_amt
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		
	SELECT max(start_date) INTO l_start_date FROM rate_exchange 
	WHERE cmpy_code = p_cmpy_code 
	AND currency_code = p_curr_code 
	AND start_date <= p_tran_date

	IF l_start_date IS NULL OR sqlca.sqlcode = NOTFOUND THEN 
		LET l_err_message = "Currency Exchange Rate NOT found:\nCurrency Code: ", p_curr_code, "\nExchange Rate Dated: ",	p_tran_date USING "dd/mm/yyyy", "\nCompany: ",trim(p_cmpy_code), "\nUse GZ8 TO add this missing Exchange Rate\nThis Program must be terminated" 
		ERROR l_err_message
		CALL fgl_winmessage("Exchange Rate Error (Missing)",l_err_message,"ERROR")
		EXIT program 1 
	END IF 
	
	SELECT * INTO l_rec_rate_exchange.* FROM rate_exchange 
	WHERE cmpy_code = p_cmpy_code 
	AND currency_code = p_curr_code 
	AND start_date = l_start_date
	 
	CASE p_rate_type 
		WHEN ("B") 
			LET l_conversion_qty = l_rec_rate_exchange.conv_buy_qty 
		WHEN ("S") 
			LET l_conversion_qty = l_rec_rate_exchange.conv_sell_qty 
		OTHERWISE 
			LET l_conversion_qty = l_rec_rate_exchange.conv_budg_qty 
	END CASE
	 
	IF p_to_from = "T" THEN 
		LET r_conv_amt = (p_source_amt * l_conversion_qty) 
	ELSE 
		LET r_conv_amt = (p_source_amt / l_conversion_qty) 
	END IF 

	RETURN r_conv_amt 
END FUNCTION 
############################################################
# END FUNCTION conv_currency(p_source_amt, p_cmpy_code, p_curr_code, p_to_from, p_tran_date,p_rate_type)
############################################################


############################################################
# FUNCTION conv_currency2(p_doc_type,p_doc_num, p_doc_cust, p_source_amt, p_cmpy_code, p_curr_code, p_to_from, p_tran_date)
#
#
############################################################
FUNCTION conv_currency2(p_doc_type,p_doc_num,p_doc_cust,p_source_amt,p_cmpy_code,p_curr_code,p_to_from,p_tran_date) 
	DEFINE p_doc_type CHAR(2)
	DEFINE p_doc_num LIKE invoicehead.inv_num
	DEFINE p_doc_cust LIKE invoicehead.cust_code
	DEFINE p_source_amt DECIMAL(18,4) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_curr_code LIKE currency.currency_code 
	DEFINE p_to_from CHAR(1) 
	DEFINE p_tran_date DATE 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_conversion_qty LIKE rate_exchange.conv_buy_qty 
	DEFINE l_err_message CHAR(70) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_conv_amt DECIMAL(18,4)

	IF p_doc_type = TRAN_TYPE_INVOICE_IN THEN 
		SELECT * INTO l_rec_invoicehead.* FROM invoicehead 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = p_doc_cust 
		AND inv_num = p_doc_num 
		AND inv_date = p_tran_date 
		LET l_conversion_qty = l_rec_invoicehead.conv_qty 

		IF p_to_from = "T" THEN 
			LET r_conv_amt = (p_source_amt * l_conversion_qty) 
		ELSE 
			LET r_conv_amt = (p_source_amt / l_conversion_qty) 
		END IF 

		RETURN r_conv_amt 
	END IF 

	IF p_doc_type = TRAN_TYPE_CREDIT_CR THEN 
		SELECT * INTO l_rec_credithead.* FROM credithead 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = p_doc_cust 
		AND cred_num = p_doc_num 
		AND cred_date = p_tran_date 
		LET l_conversion_qty = l_rec_credithead.conv_qty 

		IF p_to_from = "T" THEN 
			LET r_conv_amt = (p_source_amt * l_conversion_qty) 
		ELSE 
			LET r_conv_amt = (p_source_amt / l_conversion_qty) 
		END IF 

		RETURN r_conv_amt 
	END IF 

	IF p_doc_type = TRAN_TYPE_RECEIPT_CA THEN 
		SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = p_doc_cust 
		AND cash_num = p_doc_num 
		AND cash_date = p_tran_date 
		LET l_conversion_qty = l_rec_cashreceipt.conv_qty 

		IF p_to_from = "T" THEN 
			LET r_conv_amt = (p_source_amt * l_conversion_qty) 
		ELSE 
			LET r_conv_amt = (p_source_amt / l_conversion_qty) 
		END IF 

		RETURN r_conv_amt 
	END IF 

END FUNCTION
############################################################
# END FUNCTION conv_currency2(p_doc_type,p_doc_num, p_doc_cust, p_source_amt, p_cmpy_code, p_curr_code, p_to_from, p_tran_date)
############################################################