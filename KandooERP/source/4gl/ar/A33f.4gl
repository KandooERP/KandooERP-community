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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A33_GLOBALS.4gl" 

###########################################################################
# FUNCTION write_receipt()
#
#
###########################################################################
FUNCTION write_receipt() 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_save_bal_amt LIKE customer.bal_amt 
	DEFINE l_round_amt DECIMAL(16,2) 
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	
	BEGIN WORK 
		EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
			
		#------------------------------
		## Lock Sundry Debtors Record
		##
		LET l_err_message =" A31 - Customer Table Lock" 

		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_cashreceipt.cust_code 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 

		LET l_save_bal_amt = l_rec_customer.bal_amt 

		CALL db_bank_get_rec(UI_OFF,glob_rec_cashreceipt.bank_code) RETURNING l_rec_bank.*
--		SELECT * INTO l_rec_bank.* 
--		FROM bank 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND bank_code = glob_rec_cashreceipt.bank_code 
		CALL db_term_get_rec(UI_OFF,l_rec_customer.term_code) RETURNING l_rec_term.* 
--		SELECT * INTO l_rec_term.* 
--		FROM term 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND term_code = l_rec_customer.term_code 
		CALL db_customertype_get_rec(UI_OFF,l_rec_customer.type_code) RETURNING l_rec_customertype.* 
--		SELECT * INTO l_rec_customertype.* 
--		FROM customertype 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND type_code = l_rec_customer.type_code 
		
		#----------------------------------------------
		## Obtain next cashreceipt number
		##
		LET l_err_message = "A33 - Next Transaction Number Generater" 
		LET glob_rec_cashreceipt.cash_num = next_trans_num(
			glob_rec_kandoouser.cmpy_code,
			TRAN_TYPE_RECEIPT_CA,
			l_rec_customertype.acct_mask_code) 
		
		IF glob_rec_cashreceipt.cash_num < 0 THEN 
			LET status = glob_rec_cashreceipt.cash_num 
			GOTO recovery 
		END IF 
		
		#---------------------------------------------
		## Insert cashreceipt record
		##
		LET l_err_message = "A31a - Cash Receipt Insert" 
		LET glob_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_cashreceipt.cust_code = glob_rec_cashreceipt.bank_code 
		LET glob_rec_cashreceipt.cash_acct_code = l_rec_bank.acct_code 
		LET glob_rec_cashreceipt.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_cashreceipt.entry_date = today 
		LET glob_rec_cashreceipt.applied_amt = 0 
		LET glob_rec_cashreceipt.disc_amt = 0 
		LET glob_rec_cashreceipt.on_state_flag = "N" 
		LET glob_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
		LET glob_rec_cashreceipt.next_num = 0 
		LET glob_rec_cashreceipt.job_code = NULL 
		LET glob_rec_cashreceipt.banked_date = NULL 
		LET glob_rec_cashreceipt.banked_flag = "N" 
		LET glob_rec_cashreceipt.bank_currency_code = l_rec_bank.currency_code 
		LET glob_rec_cashreceipt.bank_dep_num = NULL 
		LET glob_rec_cashreceipt.jour_num = NULL 
		LET glob_rec_cashreceipt.post_date = NULL 
		LET glob_rec_cashreceipt.stat_date = NULL 
		
		SELECT locn_code INTO glob_rec_cashreceipt.locn_code 
		FROM userlocn 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sign_on_code = glob_rec_kandoouser.sign_on_code 
		
		#----------------------------------------------------------
		INSERT INTO cashreceipt VALUES (glob_rec_cashreceipt.*) 
		
		LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - glob_rec_cashreceipt.cash_amt 
		LET l_rec_customer.last_pay_date = glob_rec_cashreceipt.cash_date 
		LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt	+ glob_rec_cashreceipt.cash_amt 
		LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt	+ glob_rec_cashreceipt.cash_amt 
		
		#-------------------------------------------
		## Insert araudit record
		##
		LET l_err_message = "A32 - AR Audit Row Insert" 
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_cashreceipt.cash_date 
		LET l_rec_araudit.cust_code = glob_rec_cashreceipt.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
		LET l_rec_araudit.source_num = glob_rec_cashreceipt.cash_num 
		LET l_rec_araudit.tran_text = "Sundry Receipt" 
		LET l_rec_araudit.tran_amt = 0 - glob_rec_cashreceipt.cash_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.year_num = glob_rec_cashreceipt.year_num 
		LET l_rec_araudit.period_num = glob_rec_cashreceipt.period_num 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_cashreceipt.conv_qty 
		LET l_rec_araudit.entry_date = today 
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		
		#-----------------------------------
		## Insert invoicehead / credithead
		##
		IF glob_rec_cashreceipt.cash_amt >= 0 THEN 
			##
			## Obtain next invoice number
			##
			LET glob_rec_invoicehead.inv_num = next_trans_num(
				glob_rec_kandoouser.cmpy_code,
				TRAN_TYPE_INVOICE_IN,
				glob_rec_invoicehead.acct_override_code) 
			
			IF glob_rec_invoicehead.inv_num < 0 THEN 
				LET l_err_message = "A2A - Next invoice number UPDATE" 
				LET status = glob_rec_invoicehead.inv_num 
				GOTO recovery 
			END IF 
			
			LET l_err_message = "A21 - Customer Update Inv" 
			LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
			LET glob_rec_invoicehead.inv_date = glob_rec_cashreceipt.cash_date 
			LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET glob_rec_invoicehead.entry_date = today 
			LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
			LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
			LET glob_rec_invoicehead.disc_per = 0 
			LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
			LET glob_rec_invoicehead.tax_per = 0 
			LET glob_rec_invoicehead.goods_amt = 0 
			LET glob_rec_invoicehead.hand_amt = 0 
			LET glob_rec_invoicehead.hand_tax_amt = 0 
			LET glob_rec_invoicehead.freight_amt = 0 
			LET glob_rec_invoicehead.freight_tax_amt = 0 
			LET glob_rec_invoicehead.tax_amt = 0 
			LET glob_rec_invoicehead.disc_amt = 0 
			LET glob_rec_invoicehead.total_amt = 0 
			LET glob_rec_invoicehead.cost_amt = 0 
			LET glob_rec_invoicehead.paid_amt = 0 
			LET glob_rec_invoicehead.paid_date = NULL 
			LET glob_rec_invoicehead.disc_taken_amt = 0 
			
			CALL get_due_and_discount_date(l_rec_term.*,glob_rec_invoicehead.inv_date) 
			RETURNING 
				glob_rec_invoicehead.due_date, 
				glob_rec_invoicehead.disc_date 
			
			LET glob_rec_invoicehead.expected_date = glob_rec_cashreceipt.cash_date 
			LET glob_rec_invoicehead.year_num = glob_rec_cashreceipt.year_num 
			LET glob_rec_invoicehead.period_num = glob_rec_cashreceipt.period_num 
			LET glob_rec_invoicehead.on_state_flag = "N" 
			LET glob_rec_invoicehead.posted_flag = "N" 
			LET glob_rec_invoicehead.seq_num = 0 
			LET glob_rec_invoicehead.line_num = 0 
			LET glob_rec_invoicehead.printed_num = 1 
			LET glob_rec_invoicehead.rev_num = 0 
			LET glob_rec_invoicehead.rev_date = today 
			LET glob_rec_invoicehead.ship_code = l_rec_customer.cust_code 
			LET glob_rec_invoicehead.name_text = l_rec_customer.name_text 
			LET glob_rec_invoicehead.addr1_text = l_rec_customer.addr1_text 
			LET glob_rec_invoicehead.addr2_text = l_rec_customer.addr2_text 
			LET glob_rec_invoicehead.city_text = l_rec_customer.city_text 
			LET glob_rec_invoicehead.state_code = l_rec_customer.state_code 
			LET glob_rec_invoicehead.post_code = l_rec_customer.post_code 
			LET glob_rec_invoicehead.country_code = l_rec_customer.country_code --@db-patch_2020_10_04--
			LET glob_rec_invoicehead.ship_date = glob_rec_invoicehead.inv_date 
			LET glob_rec_invoicehead.currency_code = l_rec_customer.currency_code 
			LET glob_rec_invoicehead.conv_qty = glob_rec_cashreceipt.conv_qty 
			LET glob_rec_invoicehead.inv_ind = "A" 
			LET glob_rec_invoicehead.prev_paid_amt = 0 
			LET glob_rec_invoicehead.contact_text = l_rec_customer.contact_text 
			LET glob_rec_invoicehead.tele_text = l_rec_customer.tele_text 
			LET glob_rec_invoicehead.mobile_phone = l_rec_customer.mobile_phone
			LET glob_rec_invoicehead.email = l_rec_customer.email						
			LET glob_rec_invoicehead.invoice_to_ind = l_rec_customer.invoice_to_ind 
			LET glob_rec_invoicehead.territory_code = l_rec_customer.territory_code 
			LET glob_rec_invoicehead.jour_num = NULL 
			LET glob_rec_invoicehead.post_date = NULL 
			LET glob_rec_invoicehead.stat_date = NULL 
			##
			## Loop thru invoicedetl setting up lines
			##
			DECLARE c_t_invoicedetl CURSOR FOR 
			SELECT * FROM t_invoicedetl 
			ORDER BY line_num 
			FOREACH c_t_invoicedetl INTO l_rec_invoicedetl.* 
				LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
				LET l_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
				LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
				LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
				LET l_rec_invoicedetl.ord_qty = 0 
				LET l_rec_invoicedetl.ship_qty = 1 
				LET l_rec_invoicedetl.prev_qty = 0 
				LET l_rec_invoicedetl.back_qty = 0 
				LET l_rec_invoicedetl.level_code = 1 
				LET l_rec_invoicedetl.unit_cost_amt = 0 
				LET l_rec_invoicedetl.ext_cost_amt = 0 
				LET l_rec_invoicedetl.disc_amt = 0 
				LET l_rec_invoicedetl.ext_sale_amt = l_rec_invoicedetl.unit_sale_amt 
				LET l_rec_invoicedetl.unit_tax_amt = 0 
				LET l_rec_invoicedetl.ext_tax_amt = 0 
				LET l_rec_invoicedetl.line_total_amt = l_rec_invoicedetl.unit_tax_amt + l_rec_invoicedetl.unit_sale_amt 
				LET l_rec_invoicedetl.seq_num = 0 
				LET l_rec_invoicedetl.comm_amt = 0 
				LET l_rec_invoicedetl.comp_per = 0 
				LET l_rec_invoicedetl.tax_code = glob_rec_invoicehead.tax_code 
				LET l_rec_invoicedetl.disc_per = 0 
				LET l_rec_invoicedetl.sold_qty = 1 
				LET l_rec_invoicedetl.bonus_qty = 0 
				LET l_rec_invoicedetl.ext_bonus_amt = 0 
				LET l_rec_invoicedetl.ext_stats_amt = 0 

				#INSERT invoiceDetl Record
				IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
					INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
				ELSE
					DISPLAY l_rec_invoicedetl.*
					CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
				END IF 

				
				LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt	+ l_rec_invoicedetl.ext_sale_amt 
			END FOREACH 

			#------------------------------------------------------------------
			# Check FOR Rounding Errors - (very important IF auto-disb)
			#
			# A diff b/t 0 AND 0.5 IS considered rounding.  Rounding IS
			# adjusted FROM last line.  amount IS usually .-03 TO 0.02
			LET l_round_amt=glob_rec_invoicehead.goods_amt-glob_rec_cashreceipt.cash_amt 
			
			IF (l_round_amt > 0 AND l_round_amt < 0.5) 
			OR (l_round_amt < 0 AND l_round_amt > -0.5) THEN 
				UPDATE invoicedetl SET 
					unit_sale_amt = unit_sale_amt-l_round_amt, 
					ext_sale_amt = unit_sale_amt-l_round_amt, 
					line_total_amt = unit_sale_amt-l_round_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_rec_invoicedetl.inv_num 
				AND line_num = l_rec_invoicedetl.line_num 
				LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt	- l_round_amt 
			END IF 

			##
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt
	
			#INSERT invoicehead Record
			IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
				INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
			ELSE
				DISPLAY glob_rec_invoicehead.*
				CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
			END IF 
			
			
			LET l_rec_customer.bal_amt = l_rec_customer.bal_amt		+ glob_rec_invoicehead.total_amt 
			LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
			
			#--------------------------------------------
			# SET up araudit field sspecific TO invoice
			
			LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
			LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
			LET l_rec_araudit.tran_text = "Sundry Invoice" 
		ELSE 
			## Create Sundry Credit Note IF cashreceipt < 0
			##
			## Obtain next credit number
			##
			LET l_rec_credithead.cred_num = next_trans_num(
				glob_rec_kandoouser.cmpy_code,
				TRAN_TYPE_CREDIT_CR,
				l_rec_credithead.acct_override_code) 
			
			IF l_rec_credithead.cred_num < 0 THEN 
				LET l_err_message = "A2A - Next credit number UPDATE" 
				LET status = l_rec_credithead.cred_num 
				GOTO recovery 
			END IF 
			
			LET l_err_message = "A21 - Customer Update Credit" 
			LET l_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_credithead.cust_code = l_rec_customer.cust_code 
			LET l_rec_credithead.cred_date = glob_rec_cashreceipt.cash_date 
			LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_credithead.entry_date = today 
			LET l_rec_credithead.sale_code = l_rec_customer.sale_code 
			LET l_rec_credithead.tax_code = l_rec_customer.tax_code 
			LET l_rec_credithead.tax_per = 0 
			LET l_rec_credithead.goods_amt = 0 
			LET l_rec_credithead.hand_amt = 0 
			LET l_rec_credithead.hand_tax_amt = 0 
			LET l_rec_credithead.freight_amt = 0 
			LET l_rec_credithead.freight_tax_amt = 0 
			LET l_rec_credithead.tax_amt = 0 
			LET l_rec_credithead.disc_amt = 0 
			LET l_rec_credithead.total_amt = 0 
			LET l_rec_credithead.cost_amt = 0 
			LET l_rec_credithead.appl_amt = 0 
			LET l_rec_credithead.year_num = glob_rec_cashreceipt.year_num 
			LET l_rec_credithead.period_num = glob_rec_cashreceipt.period_num 
			LET l_rec_credithead.on_state_flag = "N" 
			LET l_rec_credithead.posted_flag = "N" 
			LET l_rec_credithead.line_num = 0 
			LET l_rec_credithead.printed_num = 1 
			LET l_rec_credithead.rev_num = 0 
			LET l_rec_credithead.rev_date = today 
			LET l_rec_credithead.currency_code = l_rec_customer.currency_code 
			LET l_rec_credithead.conv_qty = glob_rec_cashreceipt.conv_qty 
			LET l_rec_credithead.cred_ind = "1" 
			LET l_rec_credithead.cred_ind = "1" 
			LET l_rec_credithead.territory_code = l_rec_customer.territory_code 
			LET l_rec_credithead.jour_num = NULL 
			LET l_rec_credithead.post_date = NULL 
			LET l_rec_credithead.stat_date = NULL 
			##
			## Loop thru temp table setting up lines
			##
			DECLARE c_t_creditdetl CURSOR FOR 
			SELECT * FROM t_invoicedetl 
			ORDER BY line_num 
			FOREACH c_t_creditdetl INTO l_rec_invoicedetl.* 
				LET l_rec_credithead.line_num = l_rec_credithead.line_num + 1 
				LET l_rec_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
				LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
				LET l_rec_creditdetl.line_num = l_rec_credithead.line_num 
				LET l_rec_creditdetl.ship_qty = 1 
				LET l_rec_creditdetl.unit_cost_amt = 0 
				LET l_rec_creditdetl.ext_cost_amt = 0 
				LET l_rec_creditdetl.disc_amt = 0 
				LET l_rec_creditdetl.line_text = l_rec_invoicedetl.line_text 
				LET l_rec_creditdetl.line_acct_code = l_rec_invoicedetl.line_acct_code 
				LET l_rec_creditdetl.unit_sales_amt = 0 - l_rec_invoicedetl.unit_sale_amt 
				LET l_rec_creditdetl.ext_sales_amt = l_rec_creditdetl.unit_sales_amt 
				LET l_rec_creditdetl.unit_tax_amt = 0 
				LET l_rec_creditdetl.ext_tax_amt = 0 
				LET l_rec_creditdetl.line_total_amt = l_rec_creditdetl.unit_tax_amt + l_rec_creditdetl.unit_sales_amt 
				LET l_rec_creditdetl.seq_num = 0 
				LET l_rec_creditdetl.comm_amt = 0 
				LET l_rec_creditdetl.tax_code = l_rec_credithead.tax_code 
				INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
				LET l_rec_credithead.goods_amt = l_rec_credithead.goods_amt 
				+ l_rec_creditdetl.ext_sales_amt 
			END FOREACH 
			##
			## Check FOR Rounding Errors - (very important IF auto-disb)
			##
			## A diff b/t 0 AND 0.5 IS considered rounding
			##
			LET l_round_amt=l_rec_credithead.goods_amt+glob_rec_cashreceipt.cash_amt 
			IF (l_round_amt > 0 AND l_round_amt < 0.5) 
			OR (l_round_amt < 0 AND l_round_amt > -0.5) THEN 
				UPDATE creditdetl SET 
					unit_sales_amt = unit_sales_amt-l_round_amt, 
					ext_sales_amt = ext_sales_amt-l_round_amt, 
					line_total_amt = line_total_amt-l_round_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cred_num = l_rec_creditdetl.cred_num 
				AND line_num = l_rec_creditdetl.line_num 
				
				LET l_rec_credithead.goods_amt = l_rec_credithead.goods_amt	- l_round_amt 
			END IF 
			
			LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
			
			----------------------
			INSERT INTO credithead VALUES (l_rec_credithead.*) 
			LET l_rec_customer.bal_amt = l_rec_customer.bal_amt	- l_rec_credithead.total_amt 
			LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
			##
			## SET up araudit field sspecific TO credit
			##
			LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
			LET l_rec_araudit.tran_text = "Sundry Credit" 
		END IF 
		##
		## Insert AR audit entry
		##
		LET l_err_message = "A33 - Creating Sundry Invoice" 
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.cust_code = glob_rec_cashreceipt.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_amt = glob_rec_cashreceipt.cash_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = l_rec_customer.sale_code 
		LET l_rec_araudit.year_num = glob_rec_cashreceipt.year_num 
		LET l_rec_araudit.period_num = glob_rec_cashreceipt.period_num 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_cashreceipt.conv_qty 
		LET l_rec_araudit.entry_date = today 

		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		##
		## Update customer.  **** The balance must NOT have changed ****
		##
		LET l_err_message = "A2A - Custmain actual UPDATE " 
		IF year(l_rec_araudit.tran_date) > year(l_rec_customer.last_inv_date) THEN 
			LET l_rec_customer.mtds_amt = 0 
			LET l_rec_customer.ytds_amt = 0 
		END IF 

		IF (month(l_rec_araudit.tran_date) > month(l_rec_customer.last_inv_date)) THEN 
			LET l_rec_customer.mtds_amt = 0 
		END IF 

		LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt + l_rec_araudit.tran_amt 
		LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt + l_rec_araudit.tran_amt 
		LET l_rec_customer.last_inv_date = l_rec_araudit.tran_date 

		IF l_rec_customer.bal_amt != l_save_bal_amt 
		OR l_rec_customer.bal_amt IS NULL THEN 
			LET l_err_message = "A33 - Internal Audit Error has occurred" 
			GOTO recovery 
		END IF 

		UPDATE customer SET 
			next_seq_num = l_rec_customer.next_seq_num, 
			last_inv_date = l_rec_customer.last_inv_date, 
			last_pay_date = l_rec_customer.last_pay_date, 
			ytds_amt = l_rec_customer.ytds_amt, 
			mtds_amt = l_rec_customer.mtds_amt, 
			ytdp_amt = l_rec_customer.ytdp_amt, 
			mtdp_amt = l_rec_customer.mtdp_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_cashreceipt.cust_code 

	COMMIT WORK 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN l_rec_araudit.source_num ## RETURN invoice/credit no. 
END FUNCTION 
###########################################################################
# END FUNCTION write_receipt()
###########################################################################