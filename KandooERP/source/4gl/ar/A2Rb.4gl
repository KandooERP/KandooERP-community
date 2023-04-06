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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2R_GLOBALS.4gl"
############################################################
# FUNCTION write_refund() 
#
#
############################################################
FUNCTION write_refund() 
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.*
	DEFINE l_rec_apparms RECORD LIKE apparms.*
	DEFINE l_rec_apaudit RECORD LIKE apaudit.*
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		##
		## Lock Debtors Record
		##
		LET l_err_message =" A2R - Customer Table Lock" 
		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 
		##
		## Lock Vendor Record
		##
		LET l_err_message =" A2R - Vendor Table Lock" 
		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_bank.bank_code 
		FOR UPDATE 
		OPEN c_vendor 
		FETCH c_vendor INTO l_rec_vendor.* 
		##
		## Obtain next invoice number
		##
		LET glob_rec_invoicehead.inv_num = 
		next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,"") 
		IF glob_rec_invoicehead.inv_num < 0 THEN 
			LET l_err_message = "A2R - Next invoice number UPDATE" 
			LET status = glob_rec_invoicehead.inv_num 
			GOTO recovery 
		END IF 
		LET glob_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_invoicedetl.cust_code = l_rec_customer.cust_code 
		LET glob_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
		LET glob_rec_invoicedetl.line_num = 1 
		LET glob_rec_invoicedetl.part_code = NULL 
		LET glob_rec_invoicedetl.ware_code = NULL 
		LET glob_rec_invoicedetl.cat_code = NULL 
		LET glob_rec_invoicedetl.ord_qty = 0 
		LET glob_rec_invoicedetl.ship_qty = 1 
		LET glob_rec_invoicedetl.prev_qty = 0 
		LET glob_rec_invoicedetl.back_qty = 0 
		LET glob_rec_invoicedetl.ser_flag = NULL 
		LET glob_rec_invoicedetl.ser_qty = 0 
		LET glob_rec_invoicedetl.uom_code = NULL 
		LET glob_rec_invoicedetl.unit_cost_amt = 0 
		LET glob_rec_invoicedetl.ext_cost_amt = 0 
		LET glob_rec_invoicedetl.disc_amt = 0 
		LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_invoicedetl.ext_sale_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_invoicedetl.unit_tax_amt = 0 
		LET glob_rec_invoicedetl.ext_tax_amt = 0 
		LET glob_rec_invoicedetl.line_total_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_invoicedetl.seq_num = 0 
		LET glob_rec_invoicedetl.line_acct_code = l_rec_vendor.usual_acct_code 
		LET glob_rec_invoicedetl.level_code = NULL 
		LET glob_rec_invoicedetl.comm_amt = 0 
		LET glob_rec_invoicedetl.comp_per = 0 
		LET glob_rec_invoicedetl.tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicedetl.order_line_num = 0 
		LET glob_rec_invoicedetl.order_num = NULL 
		LET glob_rec_invoicedetl.disc_per = 0 
		LET glob_rec_invoicedetl.offer_code = NULL 
		LET glob_rec_invoicedetl.sold_qty = 1 
		LET glob_rec_invoicedetl.bonus_qty = 0 
		LET glob_rec_invoicedetl.ext_bonus_amt = 0 
		LET glob_rec_invoicedetl.ext_stats_amt = 0 
		LET glob_rec_invoicedetl.prodgrp_code = NULL 
		LET glob_rec_invoicedetl.maingrp_code = NULL 
		LET glob_rec_invoicedetl.list_price_amt = 0 
		LET glob_rec_invoicedetl.price_uom_code = NULL 
		LET glob_rec_invoicedetl.return_qty = 0 
		LET glob_rec_invoicedetl.km_qty = 0 
		LET glob_rec_invoicedetl.proddept_code = NULL 

		#INSERT invoiceDetl Record
		IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicedetl.*) THEN
			INSERT INTO invoicedetl VALUES (glob_rec_invoicedetl.*)		
		ELSE
			DISPLAY glob_rec_invoicedetl.*
			CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
		END IF 
		
		#------------------------------------
		# Insert invoicehead / credithead
		
		LET l_err_message = "A2R - Customer Update Inv" 
		LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
		LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_invoicehead.entry_date = today 
		LET glob_rec_invoicehead.sale_code = l_rec_customer.sale_code 
		LET glob_rec_invoicehead.term_code = l_rec_customer.term_code 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.tax_code = l_rec_customer.tax_code 
		LET glob_rec_invoicehead.tax_per = 0 
		LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.paid_amt = 0 
		LET glob_rec_invoicehead.paid_date = NULL 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		LET glob_rec_invoicehead.disc_date = glob_rec_invoicehead.inv_date 
		LET glob_rec_invoicehead.expected_date = NULL 
		LET glob_rec_invoicehead.on_state_flag = "N" 
		LET glob_rec_invoicehead.posted_flag = "N" 
		LET glob_rec_invoicehead.seq_num = 0 
		LET glob_rec_invoicehead.line_num = 1 
		LET glob_rec_invoicehead.printed_num = 0 
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
		LET glob_rec_invoicehead.ship_date = today 
		LET glob_rec_invoicehead.currency_code = l_rec_customer.currency_code 
		LET glob_rec_invoicehead.inv_ind = "8" 
		LET glob_rec_invoicehead.prev_paid_amt = 0 
		LET glob_rec_invoicehead.invoice_to_ind = l_rec_customer.invoice_to_ind 
		LET glob_rec_invoicehead.territory_code = l_rec_customer.territory_code 
		LET glob_rec_invoicehead.jour_num = NULL 
		LET glob_rec_invoicehead.post_date = NULL 
		LET glob_rec_invoicehead.stat_date = NULL 
		
		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)
		ELSE
			DISPLAY glob_rec_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 
		
		#----------------------------------
		# Insert araudit record
		
		LET l_err_message = "A2R - AR Audit Row Insert" 
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Refund Invoice" 
		LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = l_rec_customer.sale_code 
		LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt + glob_rec_invoicehead.total_amt 
		LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
		##
		##  Update customer
		##
		LET l_err_message = "A2R - Update customer" 
		LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
		+ glob_rec_invoicehead.total_amt 
		LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
		+ glob_rec_invoicehead.total_amt 
		LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt 
		- l_rec_customer.bal_amt 
		LET l_rec_customer.last_inv_date = glob_rec_invoicehead.inv_date 
		UPDATE customer 
		SET next_seq_num = l_rec_customer.next_seq_num, 
		last_inv_date = l_rec_customer.last_inv_date, 
		bal_amt = l_rec_customer.bal_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		cred_bal_amt = l_rec_customer.cred_bal_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		##
		##   Lock apparms
		##
		LET l_err_message = "A2R - Lock apparms" 
		DECLARE c_apparms CURSOR FOR 
		SELECT * FROM apparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		FOR UPDATE 
		OPEN c_apparms 
		FETCH c_apparms INTO l_rec_apparms.* 
		##
		## Create Voucher
		##
		LET l_err_message = "A2R - Insert voucher" 
		INITIALIZE glob_rec_voucher.* TO NULL 
		LET glob_rec_voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_voucher.vend_code = glob_rec_bank.bank_code 
		LET glob_rec_voucher.vouch_code = l_rec_apparms.next_vouch_num 
		LET glob_rec_voucher.vouch_date = glob_rec_invoicehead.inv_date 
		LET glob_rec_voucher.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_voucher.entry_date = today 
		LET glob_rec_voucher.term_code = l_rec_vendor.term_code 
		LET glob_rec_voucher.tax_code = l_rec_vendor.tax_code 
		LET glob_rec_voucher.goods_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_voucher.tax_amt = 0 
		LET glob_rec_voucher.total_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_voucher.paid_amt = 0 
		LET glob_rec_voucher.dist_qty = 1 
		LET glob_rec_voucher.dist_amt = glob_rec_invoicehead.total_amt 
		LET glob_rec_voucher.poss_disc_amt = 0 
		LET glob_rec_voucher.taken_disc_amt = 0 
		LET glob_rec_voucher.paid_date = NULL 
		LET glob_rec_voucher.due_date = glob_rec_invoicehead.due_date 
		LET glob_rec_voucher.disc_date = glob_rec_voucher.vouch_date 
		LET glob_rec_voucher.post_flag = "N" 
		LET glob_rec_voucher.year_num = glob_rec_invoicehead.year_num 
		LET glob_rec_voucher.period_num = glob_rec_invoicehead.period_num 
		LET glob_rec_voucher.pay_seq_num = 0 
		LET glob_rec_voucher.line_num = 1 
		LET glob_rec_voucher.com1_text = glob_rec_invoicehead.com1_text 
		LET glob_rec_voucher.com2_text = glob_rec_invoicehead.com2_text 
		LET glob_rec_voucher.hold_code = l_rec_vendor.hold_code 
		LET glob_rec_voucher.currency_code = l_rec_customer.currency_code 
		LET glob_rec_voucher.conv_qty = glob_rec_invoicehead.conv_qty 
		LET glob_rec_voucher.source_ind = "8" 
		LET glob_rec_voucher.source_text = glob_rec_invoicehead.cust_code 
		LET glob_rec_voucher.withhold_tax_ind = "0" 
		IF l_rec_apparms.vouch_approve_flag = "Y" THEN 
			LET glob_rec_voucher.approved_code = "N" 
		ELSE 
			LET glob_rec_voucher.approved_code = "Y" 
		END IF 
		LET glob_rec_voucher.approved_date = NULL 
		LET glob_rec_voucher.approved_by_code = NULL 
		INSERT INTO voucher VALUES (glob_rec_voucher.*) 
		LET l_err_message = "A2R - Insert voucherdist" 
		INITIALIZE l_rec_voucherdist.* TO NULL 
		LET l_rec_voucherdist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_voucherdist.vend_code = glob_rec_bank.bank_code 
		LET l_rec_voucherdist.vouch_code = glob_rec_voucher.vouch_code 
		LET l_rec_voucherdist.line_num = glob_rec_voucher.line_num 
		LET l_rec_voucherdist.type_ind = "G" 
		LET l_rec_voucherdist.acct_code = l_rec_vendor.usual_acct_code 
		LET l_rec_voucherdist.desc_text = glob_rec_invoicedetl.line_text 
		LET l_rec_voucherdist.dist_qty = 1 
		LET l_rec_voucherdist.dist_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_voucherdist.trans_qty = 1 
		LET l_rec_voucherdist.cost_amt = 0 
		LET l_rec_voucherdist.charge_amt = glob_rec_invoicehead.total_amt 
		INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
		LET l_err_message = "A2R - Insert apaudit" 
		INITIALIZE l_rec_apaudit.* TO NULL 
		LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_apaudit.tran_date = glob_rec_invoicehead.inv_date 
		LET l_rec_apaudit.vend_code = glob_rec_bank.bank_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_apaudit.trantype_ind = "VO" 
		LET l_rec_apaudit.year_num = glob_rec_invoicehead.year_num 
		LET l_rec_apaudit.period_num = glob_rec_invoicehead.period_num 
		LET l_rec_apaudit.source_num = glob_rec_voucher.vouch_code 
		LET l_rec_apaudit.tran_text = "Refund Voucher" 
		LET l_rec_apaudit.tran_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_apaudit.for_tran_amt = 0 
		LET l_rec_apaudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt + glob_rec_invoicehead.total_amt 
		LET l_rec_apaudit.currency_code = l_rec_customer.currency_code 
		LET l_rec_apaudit.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		##
		## Update apparms
		##
		LET l_err_message = "A2R - Update apparms" 
		LET l_rec_apparms.next_vouch_num = l_rec_apparms.next_vouch_num + 1 
		UPDATE apparms 
		SET next_vouch_num = l_rec_apparms.next_vouch_num 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		##
		##  Update Vendor
		##
		LET l_err_message = "A2R - Update Vendor" 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + glob_rec_invoicehead.total_amt 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + glob_rec_invoicehead.total_amt 
		LET l_rec_vendor.last_vouc_date = glob_rec_invoicehead.inv_date 
		IF l_rec_vendor.ytd_amt IS NULL THEN 
			LET l_rec_vendor.ytd_amt = glob_rec_invoicehead.total_amt 
		ELSE 
			LET l_rec_vendor.ytd_amt = l_rec_vendor.ytd_amt + glob_rec_invoicehead.total_amt 
		END IF 
		UPDATE vendor 
		SET next_seq_num = l_rec_vendor.next_seq_num, 
		bal_amt = l_rec_vendor.bal_amt, 
		curr_amt = l_rec_vendor.curr_amt, 
		last_vouc_date = l_rec_vendor.last_vouc_date, 
		ytd_amt = l_rec_vendor.ytd_amt 
		WHERE vend_code = glob_rec_bank.bank_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN l_rec_araudit.source_num ## RETURN invoice number 
END FUNCTION 


