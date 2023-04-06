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
#  module vouchbox - routines FOR voucher transactions
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION adjust_po(p_rec_poaudit,p_rec_purchdetl)
#
#
###########################################################################
FUNCTION adjust_po(p_rec_poaudit,p_rec_purchdetl) 
 	# The code FROM here down IS an extraction FROM the wind FUNCTION pochg_line
	# with the transaction processing removed as it resides in the calling
	# FUNCTION.
	#
	########################################################################
	#
	#    pochng_line modifies the line that IS there
	#
	# two combinations can occur here.
	#
	#  4. Price only change AND vouchers present
	#       NOT allowed, edit voucher will take off voucher qty
	#       AND IF > 1 voucher THEN split line (because 2 prices)
	#       by change quantity CQ AND add new line AL
	#  5. Price only change AND receipts present
	#       - reverse out current with a CP
	#       - put new in with a CP
	#       - reverse out receipt qty with a GA with current price
	#                                    (Goods Receipt Adjustment)
	#       - put new price in with the GA
	#
	#  We should NOT get here under any other scenario
	DEFINE p_rec_poaudit RECORD LIKE poaudit.*
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.*
	DEFINE l_rec_poaudit RECORD LIKE poaudit.*
	DEFINE l_cmpy LIKE company.cmpy_code 
	DEFINE l_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_row_id INTEGER 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 

	LET l_cmpy = p_rec_poaudit.cmpy_code 
	LET l_kandoouser_sign_on_code = p_rec_poaudit.entry_code 

	SELECT purchhead.* INTO l_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_rec_purchdetl.cmpy_code 
	AND order_num = p_rec_purchdetl.order_num 

	### Obtain the current po_l_audit_it FOR reversing
	###   cu_ stands FOR current
	###   pr_ IS the UPDATE poaudit
	LET l_rec_poaudit.* = p_rec_poaudit.* 
	CALL po_line_info(
		l_cmpy, 
		p_rec_purchdetl.order_num, 
		p_rec_purchdetl.line_num) 
	RETURNING 
		l_rec_poaudit.order_qty, 
		l_rec_poaudit.received_qty, 
		l_rec_poaudit.voucher_qty, 
		l_rec_poaudit.unit_cost_amt, 
		l_rec_poaudit.ext_cost_amt, 
		l_rec_poaudit.unit_tax_amt, 
		l_rec_poaudit.ext_tax_amt, 
		l_rec_poaudit.line_total_amt 

	IF l_rec_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
	AND l_rec_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt THEN 

		RETURN p_rec_poaudit.seq_num ### no amt's changed 
	END IF 

	CASE 
	#  No voucher OR receipt AND both quantity AND price change
	#       disallow only price OR quantity seperately can be changed
	#  Both quantity AND price change AND receipts present
	#       disallow only price OR quantity seperately can be changed
	#  Both quantity AND price change AND vouchers present
	#       disallow only price OR quantity seperately can be changed
	#  Price only change AND vouchers present
	#       NOT allowed, edit voucher will take off voucher qty
	#       AND IF > 1 voucher THEN split line (because 2 prices)
	#       by change quantity CQ AND add new line AL
		WHEN (((l_rec_poaudit.unit_cost_amt != p_rec_poaudit.unit_cost_amt) OR 
			(l_rec_poaudit.unit_tax_amt != p_rec_poaudit.unit_tax_amt)) AND	(l_rec_poaudit.voucher_qty > 0)) 
			ERROR " Cannot change price with voucher logged, alter qty instead" 
			SLEEP 5 
			RETURN -1 
	END CASE 

	# ok now we need TO lock the purchdetl because we are going
	# TO change the seq_num as we add the poaudit transactions

	GOTO bypass 
	LABEL recovery: 

	LET l_err_continue = error_recover(l_err_message, status) 
	IF l_err_continue = "Y" THEN 
		RETURN -2 
	END IF 

	RETURN -1 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	DECLARE seq_curs CURSOR FOR 
	SELECT rowid, purchdetl.* 
	INTO l_row_id, p_rec_purchdetl.* 
	FROM purchdetl 
	WHERE cmpy_code = p_rec_purchdetl.cmpy_code 
	AND order_num = p_rec_purchdetl.order_num 
	AND line_num = p_rec_purchdetl.line_num 

	FOREACH seq_curs 
		EXIT FOREACH 
	END FOREACH 

	# now lets just have a look AND see which type described above
	# we have

	CASE 
	#  5. Price only change AND receipts present
	#       - reverse out current with a CP
	#       - put new in with a CP
	#       - reverse out receipt qty with a GA with current price
	#       - put new price in with the GA
		WHEN (( (l_rec_poaudit.unit_cost_amt != p_rec_poaudit.unit_cost_amt)	
			OR(l_rec_poaudit.unit_tax_amt != p_rec_poaudit.unit_tax_amt))	AND (l_rec_poaudit.received_qty > 0)) 
			
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			
			CALL l_audit_it(
				l_cmpy, 
				l_kandoouser_sign_on_code, 
				l_rec_purchhead.*, 
				p_rec_purchdetl.*, 
				l_rec_poaudit.*, "CP", "out") 
			RETURNING p_rec_purchdetl.seq_num 

			IF p_rec_purchdetl.seq_num < 0 THEN 
				RETURN p_rec_purchdetl.seq_num 
			END IF 

			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 

			CALL l_audit_it(
				l_cmpy, 
				l_kandoouser_sign_on_code, 
				l_rec_purchhead.*, 
				p_rec_purchdetl.*, 
				l_rec_poaudit.*, "GA", "out") 
			RETURNING p_rec_purchdetl.seq_num 

			IF p_rec_purchdetl.seq_num < 0 THEN 
				RETURN p_rec_purchdetl.seq_num 
			END IF 

			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			LET l_rec_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
			LET l_rec_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt 

			CALL l_audit_it(
				l_cmpy, 
				l_kandoouser_sign_on_code, 
				l_rec_purchhead.*, 
				p_rec_purchdetl.*, 
				l_rec_poaudit.*, "CP", TRAN_TYPE_INVOICE_IN) 
			RETURNING p_rec_purchdetl.seq_num 

			IF p_rec_purchdetl.seq_num < 0 THEN 
				RETURN p_rec_purchdetl.seq_num 
			END IF 

			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			LET l_rec_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
			LET l_rec_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt 

			CALL l_audit_it(
				l_cmpy, 
				l_kandoouser_sign_on_code, 
				l_rec_purchhead.*, 
				p_rec_purchdetl.*, 
				l_rec_poaudit.*, "GA", TRAN_TYPE_INVOICE_IN) 
			RETURNING p_rec_purchdetl.seq_num 

			IF p_rec_purchdetl.seq_num < 0 THEN 
				RETURN p_rec_purchdetl.seq_num 
			END IF 
		OTHERWISE 
			error" How did you get here, you have found a logic problem " 
			SLEEP 5 
			RETURN -1 
	END CASE 

	RETURN p_rec_purchdetl.seq_num 
END FUNCTION 
###########################################################################
# END FUNCTION adjust_po(p_rec_poaudit,p_rec_purchdetl)
###########################################################################



###########################################################################
# FUNCTION l_audit_it(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_pr_purchdetl,p_rec_poaudit,p_tran_info,p_direct_ind)
#
#
###########################################################################
FUNCTION l_audit_it(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_pr_purchdetl,p_rec_poaudit,p_tran_info,p_direct_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchhead RECORD LIKE purchhead.*
	DEFINE p_rec_pr_purchdetl RECORD LIKE purchdetl.*
	DEFINE p_rec_poaudit RECORD LIKE poaudit.*
	DEFINE p_tran_info LIKE poaudit.tran_code
	DEFINE p_direct_ind CHAR(3) 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(50) 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 

	RETURN -1 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	###   Add the PO Audit row
	LET p_rec_poaudit.cmpy_code = p_rec_pr_purchdetl.cmpy_code 
	LET p_rec_poaudit.vend_code = p_rec_pr_purchdetl.vend_code 
	LET p_rec_poaudit.po_num = p_rec_pr_purchdetl.order_num 
	LET p_rec_poaudit.line_num = p_rec_pr_purchdetl.line_num 
	LET p_rec_poaudit.tran_code = p_tran_info 
	LET p_rec_poaudit.tran_num = 0 
	LET p_rec_poaudit.jour_num = 0 
	LET p_rec_poaudit.entry_date = today 
	LET p_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
	LET p_rec_poaudit.posted_flag = "N" 
	LET p_rec_poaudit.orig_auth_flag = "Y" 
	LET p_rec_poaudit.now_auth_flag = "Y" 
	LET p_rec_poaudit.seq_num = p_rec_pr_purchdetl.seq_num 
	LET p_rec_poaudit.desc_text = p_rec_pr_purchdetl.desc_text 


	###   Cover negatives by re multiplying out the extensions
	CASE 
		WHEN (p_direct_ind = "out" AND p_tran_info = "GA") 
			LET p_rec_poaudit.received_qty = - p_rec_poaudit.received_qty 
			LET p_rec_poaudit.order_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt	* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt * p_rec_poaudit.received_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt + p_rec_poaudit.ext_cost_amt 

		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "GA") 
			LET p_rec_poaudit.received_qty = p_rec_poaudit.received_qty 
			LET p_rec_poaudit.order_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt	* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt	* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt	+ p_rec_poaudit.ext_cost_amt 

		WHEN (p_direct_ind = "out" AND p_tran_info = "CP") 
			LET p_rec_poaudit.order_qty = - p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt	+ p_rec_poaudit.ext_cost_amt 

		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "CP") 
			LET p_rec_poaudit.order_qty = p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt + p_rec_poaudit.ext_cost_amt 

		WHEN (p_direct_ind = "out" AND p_tran_info = "CQ") 
			LET p_rec_poaudit.order_qty = - p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt	+ p_rec_poaudit.ext_cost_amt 
	
		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "CQ") 
			LET p_rec_poaudit.order_qty = p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt	* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt * p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt+ p_rec_poaudit.ext_cost_amt 

		OTHERWISE 
			error" Problem p_tran_info = ",p_tran_info,		" direct_info = ",p_direct_ind 
	END CASE 
	
	LET l_err_message = " Inserting row INTO poaudit " 
	
	# INSERT ------------------------------------
	INSERT INTO poaudit VALUES (p_rec_poaudit.*) 

	### Update Inventory WHERE required
	IF (p_rec_pr_purchdetl.type_ind = "I" OR p_rec_pr_purchdetl.type_ind = "C") 
	AND (p_tran_info = "GA" OR p_tran_info = "CQ") THEN 

		CALL l_po_adjustments(
			p_cmpy, p_kandoouser_sign_on_code, p_rec_purchhead.*, 
			p_rec_pr_purchdetl.*, 
			p_rec_poaudit.*, 
			p_tran_info) 
		RETURNING status 

		IF status < 0 THEN 
			LET l_err_message =" Error in UPDATE of product details " 
			GOTO recovery 
		END IF 
	END IF 
	### Reverse the jobledger transaction

	IF (p_rec_pr_purchdetl.type_ind = "J" OR p_rec_pr_purchdetl.type_ind = "C") 
	AND p_rec_poaudit.order_qty >= 0 
	AND p_tran_info = "GA" THEN 
		# INSERT a jobledger row FOR this transaction AND UPDATE
		# the activity with the cost of the purchase.
		DECLARE act_c CURSOR FOR 
		SELECT activity.* 
		FROM activity 
		WHERE cmpy_code = p_cmpy 
		AND job_code = p_rec_pr_purchdetl.job_code 
		AND var_code = p_rec_pr_purchdetl.var_num 
		AND activity_code = p_rec_pr_purchdetl.activity_code 
		FOR UPDATE 
		OPEN act_c		
		
		FETCH act_c INTO l_rec_activity.*
		 
		LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
		LET l_rec_jobledger.cmpy_code = p_cmpy 
		LET l_rec_jobledger.trans_date = p_rec_poaudit.tran_date 
		LET l_rec_jobledger.year_num = p_rec_poaudit.year_num 
		LET l_rec_jobledger.period_num = p_rec_poaudit.period_num 
		LET l_rec_jobledger.job_code = p_rec_pr_purchdetl.job_code 
		LET l_rec_jobledger.var_code = p_rec_pr_purchdetl.var_num 
		LET l_rec_jobledger.activity_code = p_rec_pr_purchdetl.activity_code 
		LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
		LET l_rec_jobledger.trans_type_ind = "PU" 
		LET l_rec_jobledger.trans_source_num = p_rec_poaudit.po_num 
		LET l_rec_jobledger.trans_source_text = p_rec_pr_purchdetl.ref_text 
		LET l_rec_jobledger.trans_amt = p_rec_poaudit.ext_cost_amt 
		LET l_rec_jobledger.trans_qty = p_rec_poaudit.received_qty 

		# charge RATE encoded INTO 9 TO 25
		LET l_rec_jobledger.charge_amt = p_rec_pr_purchdetl.charge_amt	* l_rec_jobledger.trans_qty 
		LET l_rec_jobledger.posted_flag = "N" 
		LET l_rec_jobledger.desc_text = p_rec_poaudit.desc_text 

		# INSERT INTO ------------------------
		INSERT INTO jobledger VALUES ( l_rec_jobledger.*) 
		UPDATE activity 
		SET 
			act_cost_amt = act_cost_amt + p_rec_poaudit.ext_cost_amt, 
			act_cost_qty = act_cost_qty + p_rec_poaudit.received_qty, 
			seq_num = l_rec_activity.seq_num 
		WHERE cmpy_code = p_cmpy 
		AND job_code = l_rec_jobledger.job_code 
		AND var_code = l_rec_jobledger.var_code 
		AND activity_code = l_rec_jobledger.activity_code 
	END IF 

	RETURN p_rec_poaudit.seq_num 
END FUNCTION 
###########################################################################
# END FUNCTION l_audit_it(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_pr_purchdetl,p_rec_poaudit,p_tran_info,p_direct_ind)
###########################################################################


###########################################################################
# FUNCTION l_po_adjustments(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info)
#
#
###########################################################################
FUNCTION l_po_adjustments(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchhead RECORD LIKE purchhead.*
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.*
	DEFINE p_rec_poaudit RECORD LIKE poaudit.*
	DEFINE p_tran_info LIKE poaudit.tran_code 
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_error_msg CHAR(100) 
	DEFINE l_total_qty DECIMAL(12,4)
	DEFINE l_wsale_tax DECIMAL(12,4)
	DEFINE l_err_message CHAR(40) 

	GOTO bypass 
	LABEL recovery: 
	RETURN status 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.*
	
	SELECT * 
	INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_rec_purchhead.cmpy_code 
	AND part_code = p_rec_purchdetl.ref_text 
	IF status = notfound THEN 
		LET l_error_msg = "Product Details NOT found FOR ", 
		p_rec_purchdetl.ref_text 
		CALL errorlog(l_error_msg) 
		EXIT program 1 
	END IF 

	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_rec_purchhead.cmpy_code 
	AND vend_code = p_rec_purchhead.vend_code 
	IF status = notfound THEN 
		LET l_error_msg = "vendor details NOT found FOR ", 
		p_rec_purchhead.vend_code 
		CALL errorlog(l_error_msg) 
		EXIT program 1 
	END IF 

	LET l_rec_prodstatus.part_code = p_rec_purchdetl.ref_text 
	LET l_rec_prodstatus.ware_code = p_rec_purchhead.ware_code 
	LET l_rec_prodledg.part_code = p_rec_purchdetl.ref_text 
	LET l_rec_prodledg.ware_code = p_rec_purchhead.ware_code 
	LET l_rec_prodledg.tran_date = p_rec_poaudit.tran_date 
	LET l_rec_prodledg.source_text = "PO C Adj" 
	LET l_rec_prodledg.source_num = p_rec_poaudit.tran_num 

	# now do the producy quantity conversions IF required
	# TO the selling quantity
	CASE 
		WHEN (p_rec_purchdetl.uom_code = l_rec_product.pur_uom_code) 
			LET l_rec_prodledg.tran_qty = (p_rec_poaudit.received_qty 
			* l_rec_product.pur_stk_con_qty) 
			* l_rec_product.stk_sel_con_qty 
			LET l_rec_prodledg.cost_amt = (p_rec_poaudit.unit_cost_amt 
			+ p_rec_poaudit.unit_tax_amt) 
			/ l_rec_product.pur_stk_con_qty 
			/ l_rec_product.stk_sel_con_qty 
		WHEN (p_rec_purchdetl.uom_code = l_rec_product.stock_uom_code) 
			LET l_rec_prodledg.tran_qty = p_rec_poaudit.received_qty 
			* l_rec_product.stk_sel_con_qty 
			LET l_rec_prodledg.cost_amt = (p_rec_poaudit.unit_cost_amt 
			+ p_rec_poaudit.unit_tax_amt) 
			/ l_rec_product.stk_sel_con_qty 
		WHEN (p_rec_purchdetl.uom_code = l_rec_product.sell_uom_code) 
			LET l_rec_prodledg.tran_qty = p_rec_poaudit.received_qty 
			LET l_rec_prodledg.cost_amt = (p_rec_poaudit.unit_cost_amt 
			+ p_rec_poaudit.unit_tax_amt) 
	END CASE 

	LET l_rec_prodledg.cost_amt = conv_currency(
		l_rec_prodledg.cost_amt, 
		p_cmpy, 
		l_rec_vendor.currency_code, 
		"F", 
		p_rec_poaudit.tran_date, 
		"B") 

	LET l_err_message = "pochg_line - prodstatus UPDATE" 
	DECLARE c_prodstatus CURSOR FOR 
	SELECT prodstatus.* 
	FROM prodstatus 
	WHERE prodstatus.part_code = l_rec_prodledg.part_code 
	AND prodstatus.ware_code = l_rec_prodledg.ware_code 
	AND prodstatus.cmpy_code = p_rec_purchhead.cmpy_code 
	FOR UPDATE 

	OPEN c_prodstatus 
	FETCH c_prodstatus INTO l_rec_prodstatus.* 
	IF l_rec_prodstatus.onord_qty IS NULL THEN 
		LET l_rec_prodstatus.onord_qty = 0 
	END IF 

	LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
	LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
	IF l_rec_prodstatus.stocked_flag = "Y" THEN 
		LET l_rec_prodstatus.onord_qty = 
		l_rec_prodstatus.onord_qty + p_rec_poaudit.order_qty 
	END IF 

	IF p_tran_info = "GA" THEN 
		IF l_rec_prodledg.cost_amt IS NULL THEN 
			LET l_rec_prodledg.cost_amt = 0 
		END IF 
		IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
			LET l_rec_prodstatus.wgted_cost_amt = 0 
		END IF 
		IF l_rec_prodstatus.act_cost_amt IS NULL THEN 
			LET l_rec_prodstatus.act_cost_amt = 0 
		END IF 

		LET l_total_qty = l_rec_prodstatus.onhand_qty + p_rec_poaudit.received_qty 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE tax_code = l_rec_prodstatus.purch_tax_code 
		AND cmpy_code = l_rec_prodstatus.cmpy_code 
		IF l_rec_tax.uplift_per IS NULL THEN 
			LET l_rec_tax.uplift_per = 0 
		END IF 

		CASE 
			WHEN l_rec_prodstatus.onhand_qty <= 0 
				LET l_rec_prodstatus.wgted_cost_amt = l_rec_prodledg.cost_amt 
			WHEN l_total_qty = 0 AND l_rec_tax.calc_method_flag = "W" 
				LET l_rec_prodstatus.wgted_cost_amt = l_rec_prodledg.cost_amt 
				LET l_rec_prodstatus.purch_tax_amt = 0 
			OTHERWISE 
				IF l_rec_tax.calc_method_flag = "W" THEN 
					LET l_wsale_tax = 0 
					LET l_rec_prodstatus.wgted_cost_amt = 
						((l_rec_prodstatus.wgted_cost_amt * 
						l_rec_prodstatus.onhand_qty) 
						+ (p_rec_poaudit.received_qty * 
						(p_rec_poaudit.unit_cost_amt 
						+ p_rec_poaudit.unit_tax_amt 
						+ l_wsale_tax))) 
						/ l_total_qty 
					LET l_rec_prodstatus.purch_tax_amt = 
						((l_rec_prodstatus.purch_tax_amt 
						* l_rec_prodstatus.onhand_qty) + 
						+ (p_rec_poaudit.received_qty * (l_wsale_tax))) 
						/ l_total_qty 
				ELSE 
					LET l_rec_prodstatus.purch_tax_amt = 0 
					LET l_rec_prodstatus.wgted_cost_amt = 
						((l_rec_prodstatus.wgted_cost_amt 
						* l_rec_prodstatus.onhand_qty) 
						+ (l_rec_prodledg.tran_qty 
						* l_rec_prodledg.cost_amt)) 
						/ l_rec_prodstatus.onhand_qty 
				END IF 
		END CASE 
		# put actual TO latest cost amount
		LET l_rec_prodstatus.act_cost_amt = l_rec_prodledg.cost_amt 
		# save foreign cost as well IF required
		IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"SC") = "0" THEN 
			IF p_rec_purchhead.vend_code = l_rec_product.vend_code THEN 
				LET l_rec_prodstatus.for_cost_amt = 
				((p_rec_poaudit.unit_cost_amt / l_rec_product.pur_stk_con_qty)	/ l_rec_product.stk_sel_con_qty) 
			ELSE 
				LET l_rec_prodstatus.for_cost_amt = p_rec_poaudit.unit_cost_amt 
			END IF 
			LET l_rec_prodstatus.for_curr_code = l_rec_vendor.currency_code 
		END IF 
	END IF 

	IF p_tran_info = "GA" THEN 
		LET l_rec_prodledg.cmpy_code = p_cmpy 
		LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
		LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
		LET l_rec_prodledg.trantype_ind = "P" #?????
		LET l_rec_prodledg.sales_amt = 0 

		IF l_rec_inparms.hist_flag = "Y" THEN 
			LET l_rec_prodledg.hist_flag = "N" 
		ELSE 
			LET l_rec_prodledg.hist_flag = "Y" 
		END IF 

		LET l_rec_prodledg.post_flag = "N" 
		IF p_rec_poaudit.received_qty <= 0 THEN 
			LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty + 
			p_rec_poaudit.received_qty 
		ELSE 
			LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
		END IF 

		LET l_rec_prodledg.year_num = p_rec_poaudit.year_num 
		LET l_rec_prodledg.period_num = p_rec_poaudit.period_num 
		LET l_rec_prodledg.source_num = p_rec_purchdetl.order_num 
		LET l_rec_prodledg.desc_text = "PO Price Change" 
		LET l_rec_prodledg.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_prodledg.entry_date = today 
		LET l_err_message = "pochg_line - Product Ledger INSERT" 

		# -----------------------------------------------
		INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

		IF l_rec_tax.calc_method_flag = "W" AND l_wsale_tax > 0 THEN 
			IF l_rec_prodledg.tran_qty < 0 THEN 
				LET l_rec_prodledg.source_text = "PO C WS-TAX" 
			END IF 
			LET l_rec_prodledg.trantype_ind = "W" 
			LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
			LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
			LET l_rec_prodledg.cost_amt = l_wsale_tax 

			# INSERT INTO
			INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
		END IF 
	END IF 
	
	# UPDATE ------------------------------------
	UPDATE prodstatus 
	SET * = l_rec_prodstatus.* 
	WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
	AND part_code = l_rec_prodstatus.part_code 
	AND ware_code = l_rec_prodstatus.ware_code 
	CLOSE c_prodstatus 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true 
END FUNCTION 
###########################################################################
# END FUNCTION l_po_adjustments(p_cmpy,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info)
###########################################################################

###########################################################################
# FUNCTION update_database(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher)
#
#Accounts Payable Voucher Distribution Update
#
#     Updating IS governed by pr_update_ind
#                (1) = Insert voucher & distributions
#                (2) = Update voucher & distributions
#                (3) = Update distributions only
#removed dummy argument .. #p_rec_vouchpayee RECORD LIKE vouchpayee.*,  something really wrong witht his function
###########################################################################
FUNCTION update_database(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_update_ind CHAR(1) 
	DEFINE p_rec_voucher RECORD LIKE voucher.*
	DEFINE p_rec_vouchpayee RECORD LIKE vouchpayee.*
	DEFINE l_unit_cost_amt LIKE poaudit.unit_cost_amt 
 	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_apparms RECORD LIKE apparms.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_cust_code LIKE customer.corp_cust_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_pr_diff_qty DECIMAL(16,4) 
	DEFINE l_kandoooption LIKE kandoooption.feature_ind 

	LET l_msgresp=kandoomsg("P",1005,"") #1005 Updating database - please wait

	GOTO bypass 
	LABEL recovery: 
	RETURN false, l_err_message 
	LABEL bypass: 
	LET l_err_cnt = 0 

	WHENEVER ERROR GOTO recovery 

	LET l_err_message = "Locking Vendor FOR Update" 
	DECLARE c_vendor CURSOR FOR 
	SELECT * FROM vendor 
	WHERE cmpy_code = p_rec_voucher.cmpy_code 
	AND vend_code = p_rec_voucher.vend_code 
	FOR UPDATE 

	OPEN c_vendor 
	FETCH c_vendor INTO l_rec_vendor.* 
	DECLARE c_voucher CURSOR FOR 
	SELECT * FROM voucher 
	WHERE cmpy_code = p_rec_voucher.cmpy_code 
	AND vend_code = p_rec_voucher.vend_code 
	AND vouch_code = p_rec_voucher.vouch_code 
	FOR UPDATE 

	CASE p_update_ind 
		WHEN "1" #### new voucher 
			LET l_err_message = "Locking AP Parameters FOR Update" 

			DECLARE c_apparms CURSOR FOR 
			SELECT * FROM apparms 
			WHERE apparms.parm_code = "1" 
			AND apparms.cmpy_code = p_cmpy 
			FOR UPDATE 

			OPEN c_apparms 

			FETCH c_apparms INTO l_rec_apparms.* 

			LET p_rec_voucher.vouch_code = l_rec_apparms.next_vouch_num 
			LET l_err_message = "Updating AP Parameters FOR Update" 

			UPDATE apparms 
			SET next_vouch_num = l_rec_apparms.next_vouch_num + 1 
			WHERE cmpy_code = p_cmpy 
			AND parm_code = "1" 
			INITIALIZE l_rec_voucher.* TO NULL 
			LET l_rec_voucher.total_amt = 0 

		WHEN "2" #### UPDATE voucher 
			LET l_err_message = "Locking Voucher FOR Update" 
			OPEN c_voucher 
			FETCH c_voucher INTO l_rec_voucher.* 

		WHEN "3" #### UPDATE voucher distributions 
			LET l_err_message = "Locking Voucher FOR Update" 
			OPEN c_voucher 
			FETCH c_voucher INTO p_rec_voucher.* 
			LET l_rec_voucher.* = p_rec_voucher.* 
	END CASE 

	IF p_rec_voucher.dist_amt != 0 AND p_rec_voucher.post_flag = "N" THEN 
		# we have existing distributions so drop them
		DECLARE c_voucherdist CURSOR FOR 
		SELECT * FROM voucherdist 
		WHERE cmpy_code = p_rec_voucher.cmpy_code 
		AND vend_code = p_rec_voucher.vend_code 
		AND vouch_code = p_rec_voucher.vouch_code 

		FOREACH c_voucherdist INTO l_rec_voucherdist.* 

			CASE l_rec_voucherdist.type_ind 
				WHEN "P" 
					LET l_err_message = "Locking P.O. Line FOR Update" 
					DECLARE c_purchdetl CURSOR FOR 
					SELECT * FROM purchdetl 
					WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
					AND order_num = l_rec_voucherdist.po_num 
					AND line_num = l_rec_voucherdist.po_line_num 
					FOR UPDATE OF seq_num 

					OPEN c_purchdetl 
					FETCH c_purchdetl INTO l_rec_purchdetl.* 
					IF status = 0 THEN 
						LET l_err_message = "Insert P.O. Audit Line" 
						LET l_rec_purchdetl.seq_num = l_rec_purchdetl.seq_num + 1 
						CALL po_line_info(
							l_rec_voucherdist.cmpy_code, 
							l_rec_voucherdist.po_num, 
							l_rec_voucherdist.po_line_num) 
						RETURNING 
							l_rec_poaudit.order_qty, 
							l_rec_poaudit.received_qty, 
							l_rec_poaudit.voucher_qty, 
							l_rec_poaudit.unit_cost_amt, 
							l_rec_poaudit.ext_cost_amt, 
							l_rec_poaudit.unit_tax_amt, 
							l_rec_poaudit.ext_tax_amt, 
							l_rec_poaudit.line_total_amt 

						LET l_rec_poaudit.cmpy_code = l_rec_purchdetl.cmpy_code 
						LET l_rec_poaudit.po_num = l_rec_purchdetl.order_num 
						LET l_rec_poaudit.line_num = l_rec_purchdetl.line_num 
						LET l_rec_poaudit.seq_num = l_rec_purchdetl.seq_num 
						LET l_rec_poaudit.vend_code = p_rec_voucher.vend_code 
						LET l_rec_poaudit.tran_code = "VO" 
						LET l_rec_poaudit.tran_num = p_rec_voucher.vouch_code 
						LET l_rec_poaudit.tran_date = p_rec_voucher.vouch_date 
						LET l_rec_poaudit.entry_date = today 
						LET l_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_poaudit.orig_auth_flag = "N" 
						LET l_rec_poaudit.now_auth_flag = "N" 
						LET l_rec_poaudit.order_qty = 0 
						LET l_rec_poaudit.received_qty = 0 
						LET l_rec_poaudit.desc_text = l_rec_purchdetl.desc_text 
						LET l_rec_poaudit.posted_flag = "N" 
						LET l_rec_poaudit.jour_num = 0 
						LET l_rec_poaudit.year_num = p_rec_voucher.year_num 
						LET l_rec_poaudit.period_num = p_rec_voucher.period_num 
						LET l_rec_poaudit.voucher_qty = 0 - l_rec_voucherdist.trans_qty 
						LET l_rec_poaudit.line_total_amt = 0 - l_rec_voucherdist.dist_amt 

						#INSERT INTO ---------------------------------
						INSERT INTO poaudit VALUES (l_rec_poaudit.*) 
						LET l_err_message = "Update P.O. Line" 

						UPDATE purchdetl 
						SET seq_num = l_rec_purchdetl.seq_num 
						WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
						AND order_num = l_rec_voucherdist.po_num 
						AND line_num = l_rec_voucherdist.po_line_num 
						LET l_err_message = "Update P.O. Header" 

						UPDATE purchhead 
						SET status_ind = "P" 
						WHERE cmpy_code = p_cmpy 
						AND order_num = l_rec_poaudit.po_num 
						AND vend_code = l_rec_poaudit.vend_code 
					END IF 

				WHEN "J" 
					LET l_err_message = "Locking JM Activity FOR Update" 
					DECLARE c_activity CURSOR FOR 
					SELECT * FROM activity 
					WHERE cmpy_code = p_cmpy 
					AND job_code = l_rec_voucherdist.job_code 
					AND var_code = l_rec_voucherdist.var_code 
					AND activity_code = l_rec_voucherdist.act_code 
					AND finish_flag = "N" 
					FOR UPDATE 
					OPEN c_activity 
					FETCH c_activity INTO l_rec_activity.* 
					IF status = 0 THEN 
						LET l_err_message = "Insert JM Jobledger " 
						LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
						LET l_rec_jobledger.cmpy_code = p_cmpy 
						LET l_rec_jobledger.trans_date = p_rec_voucher.vouch_date 
						LET l_rec_jobledger.year_num = p_rec_voucher.year_num 
						LET l_rec_jobledger.period_num = p_rec_voucher.period_num 
						LET l_rec_jobledger.job_code = l_rec_voucherdist.job_code 
						LET l_rec_jobledger.var_code = l_rec_voucherdist.var_code 
						LET l_rec_jobledger.activity_code = l_rec_voucherdist.act_code 
						LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
						LET l_rec_jobledger.trans_type_ind = "VO" 
						LET l_rec_jobledger.trans_source_num = p_rec_voucher.vouch_code 
						LET l_rec_jobledger.trans_source_text=l_rec_voucherdist.res_code 
						LET l_rec_jobledger.trans_amt = 0 - l_rec_voucherdist.dist_amt 
						LET l_rec_jobledger.trans_qty = 0 - l_rec_voucherdist.trans_qty 
						LET l_rec_jobledger.charge_amt = 0 - l_rec_voucherdist.charge_amt 
						LET l_rec_jobledger.posted_flag = "N" 
						LET l_rec_jobledger.desc_text = "Voucher Reversal " 

						# INSERT INTO -------------------------------------------
						INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
						LET l_err_message = "Update JM Activity " 
						UPDATE activity 
						SET 
							seq_num =	l_rec_activity.seq_num, 
							act_cost_amt = act_cost_amt	- l_rec_voucherdist.dist_amt, 
							act_cost_qty = act_cost_qty	- l_rec_voucherdist.trans_qty, 
							post_revenue_amt = post_revenue_amt	- l_rec_voucherdist.charge_amt 
						WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
						AND job_code = l_rec_voucherdist.job_code 
						AND var_code = l_rec_voucherdist.var_code 
						AND activity_code = l_rec_voucherdist.act_code 
					ELSE 
						LET l_err_message="JM Activity IS closed - No Update Allowed" 
						GOTO recovery 
					END IF 

				WHEN "W" 
					LET l_err_message = "Locking Ordhead FOR UPDATE" 
					DECLARE c_ordhead CURSOR FOR 
					SELECT * FROM ordhead 
					WHERE cmpy_code = p_cmpy 
					AND order_num = l_rec_voucherdist.po_num 
					FOR UPDATE 
					OPEN c_ordhead 
					FETCH c_ordhead INTO l_rec_ordhead.* 
					UPDATE ordhead SET 
						export_cost_amt = export_cost_amt - 
						l_rec_voucherdist.dist_amt 
					WHERE cmpy_code = p_cmpy 
					AND order_num = l_rec_ordhead.order_num 
					CLOSE c_ordhead 
				
				WHEN "A" 
					# AR Updates
					DECLARE c1_customer CURSOR FOR 
					SELECT * FROM customer 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_voucherdist.res_code 
					FOR UPDATE 
					OPEN c1_customer 
					FETCH c1_customer INTO l_rec_customer.* 

					#get invoiceHead record
					IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,l_rec_voucherdist.po_num ) THEN
						CALL db_invoicehead_get_rec(UI_ON,l_rec_voucherdist.po_num ) RETURNING  l_rec_invoicehead.*
										
						INITIALIZE l_rec_araudit.* TO NULL 

						LET l_err_message = "Customer Update Inv" 
						LET l_rec_customer.next_seq_num =	l_rec_customer.next_seq_num + 1 
						LET l_rec_customer.bal_amt = l_rec_customer.bal_amt	- l_rec_invoicehead.total_amt 
						LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	- l_rec_invoicehead.total_amt 
						LET l_rec_araudit.cmpy_code = p_cmpy 
						LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
						LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
						LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
						LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
						LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
						LET l_rec_araudit.tran_text = "Adjustment" 
						LET l_rec_araudit.tran_amt = 0 - l_rec_invoicehead.total_amt 
						LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
						LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
						LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
						LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
						LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
						LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
						LET l_rec_araudit.entry_date = today 
						LET l_err_message = "Unable TO add TO AR log table " 
						
						INSERT INTO araudit VALUES (l_rec_araudit.*) 
						
						IF l_rec_customer.bal_amt> l_rec_customer.highest_bal_amt THEN 
							LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
						END IF 
						
						LET l_rec_customer.cred_bal_amt =	l_rec_customer.cred_limit_amt + l_rec_customer.bal_amt 
						
						IF year(l_rec_invoicehead.inv_date)	> year(l_rec_customer.last_inv_date) THEN 
							LET l_rec_customer.ytds_amt = 0 
						END IF 
						
						LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt- l_rec_invoicehead.total_amt 
						IF (month(l_rec_invoicehead.inv_date) 	> month(l_rec_customer.last_inv_date)		OR year(l_rec_invoicehead.inv_date)	> year(l_rec_customer.last_inv_date)) THEN 
							LET l_rec_customer.mtds_amt = 0 
						END IF 
						
						LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt	- l_rec_invoicehead.total_amt 
						LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
						LET l_err_message = "Custmain actual UPDATE " 
						
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
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_rec_voucherdist.res_code 
						CLOSE c1_customer 

						UPDATE invoicehead 
						SET 
							total_amt = 0, 
							goods_amt = 0, 
							paid_amt = 0, 
							hand_amt = 0, 
							hand_amt = 0, 
							tax_amt = 0 
						WHERE cmpy_code = p_cmpy 
						AND inv_num = l_rec_invoicehead.inv_num 
						UPDATE invoicedetl 
						SET 
							line_total_amt = 0, 
							ext_sale_amt = 0, 
							ext_tax_amt = 0, 
							unit_sale_amt = 0, 
							unit_tax_amt = 0 
						WHERE cmpy_code = p_cmpy 
						AND inv_num = l_rec_invoicehead.inv_num 
					END IF 
					# END AR Updates

			END CASE 
			LET l_err_message = "Deleting Existing Voucher Lines" 
			DELETE FROM voucherdist 
			WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
			AND vend_code = p_rec_voucher.vend_code 
			AND vouch_code = l_rec_voucherdist.vouch_code 
			AND line_num = l_rec_voucherdist.line_num 
		END FOREACH 
	END IF 

	####
	#### Insert/Update Voucher
	####
	IF p_update_ind != "3" THEN 
		CASE 
			WHEN (l_rec_voucher.inv_text IS NULL AND p_rec_voucher.inv_text IS null) 
			WHEN (l_rec_voucher.inv_text IS NULL AND p_rec_voucher.inv_text IS NOT null) 
				LET l_err_message = "Insert Vendor Invoice Entry" 
				LET l_kandoooption = get_kandoooption_feature_state('AP','VI') 

				IF l_kandoooption = 'N' THEN 
					INSERT INTO vendorinvs VALUES (
						p_cmpy,
						p_rec_voucher.vend_code, 
						p_rec_voucher.inv_text, 
						p_rec_voucher.vouch_code, 
						p_rec_voucher.entry_date) 
				ELSE 
					SELECT 1 FROM vendorinvs 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = p_rec_voucher.vend_code 
					AND inv_text = p_rec_voucher.inv_text 
					IF sqlca.sqlcode = notfound THEN 
						INSERT INTO vendorinvs VALUES (p_cmpy,p_rec_voucher.vend_code, 
						p_rec_voucher.inv_text, 
						p_rec_voucher.vouch_code, 
						p_rec_voucher.entry_date) 
					END IF 
				END IF 

			WHEN (l_rec_voucher.inv_text IS NOT NULL AND p_rec_voucher.inv_text IS null) 
				LET l_err_message = "Deleting Vendor Invoice Entry" 
				DELETE FROM vendorinvs 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = p_rec_voucher.vend_code 
				AND inv_text = l_rec_voucher.inv_text 

			WHEN (l_rec_voucher.inv_text != p_rec_voucher.inv_text) 
				LET l_err_message = "Updating Vendor Invoice Entry" 
				UPDATE vendorinvs 
				SET inv_text = p_rec_voucher.inv_text 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = p_rec_voucher.vend_code 
				AND inv_text = l_rec_voucher.inv_text 
		END CASE 

		IF p_rec_voucher.total_amt != l_rec_voucher.total_amt THEN 
			IF l_rec_voucher.total_amt != 0 THEN 
				LET l_err_message = "Insert AP Audit Line" 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_voucher.total_amt 
				LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt	- l_rec_voucher.total_amt 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_apaudit.cmpy_code = p_cmpy 
				LET l_rec_apaudit.tran_date = l_rec_voucher.vouch_date 
				LET l_rec_apaudit.vend_code = l_rec_voucher.vend_code 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				LET l_rec_apaudit.trantype_ind = "VO" 
				LET l_rec_apaudit.year_num = l_rec_voucher.year_num 
				LET l_rec_apaudit.period_num = l_rec_voucher.period_num 
				LET l_rec_apaudit.source_num = l_rec_voucher.vouch_code 
				LET l_rec_apaudit.tran_text = "Backout Voucher" 
				LET l_rec_apaudit.tran_amt = 0 - l_rec_voucher.total_amt 
				LET l_rec_apaudit.entry_code = l_rec_voucher.entry_code 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_rec_apaudit.currency_code = l_rec_voucher.currency_code 
				LET l_rec_apaudit.conv_qty = l_rec_voucher.conv_qty 
				LET l_rec_apaudit.entry_date = today 

				#INSERT INTO ---------------------------------------
				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 
			
			IF p_rec_voucher.total_amt != 0 THEN 
				LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + p_rec_voucher.total_amt 
				LET l_rec_vendor.curr_amt =l_rec_vendor.curr_amt + p_rec_voucher.total_amt 
				LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
				LET l_rec_apaudit.cmpy_code = p_cmpy 
				LET l_rec_apaudit.tran_date = p_rec_voucher.vouch_date 
				LET l_rec_apaudit.vend_code = p_rec_voucher.vend_code 
				LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
				LET l_rec_apaudit.trantype_ind = "VO" 
				LET l_rec_apaudit.year_num = p_rec_voucher.year_num 
				LET l_rec_apaudit.period_num = p_rec_voucher.period_num 
				LET l_rec_apaudit.source_num = p_rec_voucher.vouch_code 

				IF p_update_ind = "1" THEN 
					LET l_rec_apaudit.tran_text = "Voucher Entry" 
				ELSE 
					LET l_rec_apaudit.tran_text = "Voucher Edit" 
				END IF 
				LET l_rec_apaudit.tran_amt = p_rec_voucher.total_amt 
				LET l_rec_apaudit.entry_code = p_rec_voucher.entry_code 
				LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
				LET l_rec_apaudit.currency_code = p_rec_voucher.currency_code 
				LET l_rec_apaudit.conv_qty = p_rec_voucher.conv_qty 
				LET l_rec_apaudit.entry_date = today 

				INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
			END IF 

			IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
				LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
			END IF 
		END IF 

		IF l_rec_vendor.last_vouc_date IS NULL	OR p_rec_voucher.vouch_date > l_rec_vendor.last_vouc_date THEN 
			LET l_rec_vendor.last_vouc_date = p_rec_voucher.vouch_date 
		END IF 
		LET p_rec_voucher.goods_amt = p_rec_voucher.total_amt 
		
		IF p_rec_voucher.withhold_tax_ind IS NULL THEN 
			SELECT withhold_tax_ind INTO p_rec_voucher.withhold_tax_ind 
			FROM vendortype 
			WHERE cmpy_code = p_cmpy 
			AND type_code = l_rec_vendor.type_code 
			IF status = notfound THEN 
				LET p_rec_voucher.withhold_tax_ind = "0" 
			END IF 
		END IF 
		
		#Re-selected TO ensure latest value
		SELECT * INTO l_rec_apparms.* FROM apparms 
		WHERE cmpy_code = p_cmpy 
		IF l_rec_apparms.vouch_approve_flag = "Y" THEN 
			LET p_rec_voucher.approved_code = 'N' 
		ELSE 
			LET p_rec_voucher.approved_code = 'Y' 
		END IF
		 
		LET p_rec_voucher.approved_by_code = NULL 
		LET p_rec_voucher.approved_date = NULL 
		LET l_err_message = "Updating Voucher Header" 
		
		UPDATE voucher 
		SET * = p_rec_voucher.* 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = p_rec_voucher.vend_code 
		AND vouch_code = p_rec_voucher.vouch_code 
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET l_err_message = "Inserting Voucher Header" 
			INSERT INTO voucher VALUES (p_rec_voucher.*) 
		END IF 
		LET l_err_message = "Updating Vendor Header" 
		
		UPDATE vendor 
		SET 
			bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			highest_bal_amt = l_rec_vendor.highest_bal_amt, 
			last_vouc_date = l_rec_vendor.last_vouc_date, 
			next_seq_num = l_rec_vendor.next_seq_num 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = p_rec_voucher.vend_code 
	END IF 
	
	#-----------------------------------------
	#### Insert Distributions
	####
	IF p_rec_voucher.post_flag = "N" THEN 
		LET p_rec_voucher.dist_amt = 0 
		LET p_rec_voucher.dist_qty = 0 
		LET p_rec_voucher.line_num = 0 
		DECLARE c1_t_voucherdist CURSOR FOR 
		SELECT * FROM t_voucherdist 
		WHERE acct_code IS NOT NULL 
		ORDER BY line_num 
		
		FOREACH c1_t_voucherdist INTO l_rec_voucherdist.* 
			IF l_rec_voucherdist.dist_amt IS NULL THEN 
				LET l_rec_voucherdist.dist_amt = 0 
			END IF 

			IF l_rec_voucherdist.dist_qty IS NULL THEN 
				LET l_rec_voucherdist.dist_qty = 0 
			END IF 

			IF l_rec_voucherdist.dist_amt = 0	AND l_rec_voucherdist.dist_qty = 0 THEN 
				CONTINUE FOREACH 
			END IF 

			LET p_rec_voucher.line_num = p_rec_voucher.line_num + 1 
			LET l_rec_voucherdist.cmpy_code = p_rec_voucher.cmpy_code 
			LET l_rec_voucherdist.vend_code = p_rec_voucher.vend_code 
			LET l_rec_voucherdist.vouch_code = p_rec_voucher.vouch_code 
			LET l_rec_voucherdist.line_num = p_rec_voucher.line_num 
			LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt	+ l_rec_voucherdist.dist_amt 
			LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty	+ l_rec_voucherdist.dist_qty
			 
			IF p_rec_voucher.dist_amt <= p_rec_voucher.total_amt THEN 
				CASE l_rec_voucherdist.type_ind 
					WHEN "P" 
						LET l_err_message = "Locking P.O. Line FOR Update" 
						DECLARE c1_purchdetl CURSOR FOR 
						SELECT * FROM purchdetl 
						WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
						AND order_num = l_rec_voucherdist.po_num 
						AND line_num = l_rec_voucherdist.po_line_num 
						FOR UPDATE OF seq_num 
						OPEN c1_purchdetl 
						FETCH c1_purchdetl INTO l_rec_purchdetl.* 

						IF status = 0 THEN 
							LET l_err_message = "Inserting P.O. Audit Line" 

							CALL po_line_info(
								l_rec_voucherdist.cmpy_code, 
								l_rec_voucherdist.po_num, 
								l_rec_voucherdist.po_line_num) 
							RETURNING 
								l_rec_poaudit.order_qty, 
								l_rec_poaudit.received_qty, 
								l_rec_poaudit.voucher_qty, 
								l_rec_poaudit.unit_cost_amt, 
								l_rec_poaudit.ext_cost_amt, 
								l_rec_poaudit.unit_tax_amt, 
								l_rec_poaudit.ext_tax_amt, 
								l_rec_poaudit.line_total_amt 

							LET l_pr_diff_qty =	l_rec_voucherdist.trans_qty 
								- l_rec_poaudit.received_qty 
								- l_rec_poaudit.voucher_qty 

							IF l_pr_diff_qty <= 0 THEN 
								LET l_rec_poaudit.cmpy_code = l_rec_purchdetl.cmpy_code 
								LET l_rec_poaudit.po_num = l_rec_purchdetl.order_num 
								LET l_rec_poaudit.line_num = l_rec_purchdetl.line_num 
								LET l_rec_poaudit.seq_num = l_rec_purchdetl.seq_num 
								LET l_rec_poaudit.vend_code = p_rec_voucher.vend_code 
								LET l_rec_poaudit.tran_code = "VO" 
								LET l_rec_poaudit.tran_num = p_rec_voucher.vouch_code 
								LET l_rec_poaudit.tran_date = p_rec_voucher.vouch_date 
								LET l_rec_poaudit.entry_date = today 
								LET l_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
								LET l_rec_poaudit.orig_auth_flag = "N" 
								LET l_rec_poaudit.now_auth_flag = "N" 
								LET l_rec_poaudit.order_qty = 0 
								LET l_rec_poaudit.received_qty = 0 
								LET l_rec_poaudit.voucher_qty = l_rec_voucherdist.trans_qty 
								LET l_rec_poaudit.desc_text = l_rec_purchdetl.desc_text 
								LET l_rec_poaudit.posted_flag = "N" 
								LET l_rec_poaudit.jour_num = 0 
								LET l_rec_poaudit.year_num = p_rec_voucher.year_num 
								LET l_rec_poaudit.period_num = p_rec_voucher.period_num 
								LET l_rec_poaudit.line_total_amt=l_rec_voucherdist.dist_amt 
								LET l_unit_cost_amt = l_rec_voucherdist.dist_amt / 
								l_rec_voucherdist.trans_qty 

								LET l_rec_poaudit.ext_cost_amt = l_rec_poaudit.unit_cost_amt		* l_rec_voucherdist.trans_qty 
								#####  - The following test replaces the 'cross the board'
								#####         10 % variance AND uses the variance held in po_var_per
								#####         AND po_var_amt FOR each vendor
								###########
								IF l_rec_voucherdist.cost_amt != (l_rec_poaudit.unit_cost_amt + l_rec_poaudit.unit_tax_amt) 
								AND l_unit_cost_amt >= (l_rec_poaudit.unit_cost_amt	+ l_rec_poaudit.unit_tax_amt)	* (1 - (l_rec_vendor.po_var_per/100)) 
								AND l_unit_cost_amt <= (l_rec_poaudit.unit_cost_amt + l_rec_poaudit.unit_tax_amt)	* (1 + (l_rec_vendor.po_var_per/100)) 
								AND l_unit_cost_amt >= (l_rec_poaudit.unit_cost_amt + l_rec_poaudit.unit_tax_amt)-(l_rec_vendor.po_var_amt)
								AND l_unit_cost_amt <= (l_rec_poaudit.unit_cost_amt	+ l_rec_poaudit.unit_tax_amt)+(l_rec_vendor.po_var_amt) 
								THEN 
									LET l_rec_poaudit.unit_cost_amt = l_unit_cost_amt - l_rec_poaudit.unit_tax_amt 
									LET l_rec_poaudit.ext_cost_amt = l_rec_poaudit.unit_cost_amt * l_rec_voucherdist.trans_qty 
									CALL adjust_po(l_rec_poaudit.*,l_rec_purchdetl.*) 
									RETURNING l_rec_purchdetl.seq_num 
									
									IF l_rec_purchdetl.seq_num < 0 THEN 
										LET l_err_message = "Amendment of PO " 
										GOTO recovery 
									END IF 
								END IF 
								
								LET l_rec_purchdetl.seq_num = l_rec_purchdetl.seq_num + 1 
								LET l_rec_poaudit.seq_num = l_rec_purchdetl.seq_num 
								
								# INSERT --------------------------------------
								INSERT INTO poaudit VALUES (l_rec_poaudit.*) 
								LET l_err_message = "Updating P.O. Line" 
								
								UPDATE purchdetl 
								SET seq_num = l_rec_purchdetl.seq_num 
								WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
								AND order_num = l_rec_voucherdist.po_num 
								AND line_num = l_rec_voucherdist.po_line_num 
								LET l_err_message = "Updating P.O. Header" 
								
								UPDATE purchhead 
								SET status_ind = "P" 
								WHERE cmpy_code = p_cmpy 
								AND order_num = l_rec_poaudit.po_num 
								AND vend_code = l_rec_poaudit.vend_code 
								
								LET l_err_message = "Insert PO Voucher Dist Line" 
								
								INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
							ELSE 

								LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt	- l_rec_voucherdist.dist_amt 
								LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - l_rec_voucherdist.dist_qty 
								DELETE FROM t_voucherdist 
								WHERE line_num = l_rec_voucherdist.line_num 
								LET l_err_cnt = l_err_cnt + 1 
							END IF 
						ELSE 

							LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt	- l_rec_voucherdist.dist_amt 
							LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty	- l_rec_voucherdist.dist_qty 
							DELETE FROM t_voucherdist 
							WHERE line_num = l_rec_voucherdist.line_num 
							LET l_err_cnt = l_err_cnt + 1 
						END IF 
						
					WHEN "J" 
						LET l_err_message = "Locking JM Activity FOR Update" 
						DECLARE c1_activity CURSOR FOR 
						SELECT * FROM activity 
						WHERE cmpy_code = p_cmpy 
						AND job_code = l_rec_voucherdist.job_code 
						AND var_code = l_rec_voucherdist.var_code 
						AND activity_code = l_rec_voucherdist.act_code 
						AND finish_flag = "N" 
						FOR UPDATE 
						OPEN c1_activity 
						FETCH c1_activity INTO l_rec_activity.* 
						IF status = 0 THEN 
							LET l_err_message = "Insert JM Jobledger" 
							LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
							LET l_rec_jobledger.cmpy_code = p_cmpy 
							LET l_rec_jobledger.trans_date = p_rec_voucher.vouch_date 
							LET l_rec_jobledger.year_num = p_rec_voucher.year_num 
							LET l_rec_jobledger.period_num = p_rec_voucher.period_num 
							LET l_rec_jobledger.job_code = l_rec_voucherdist.job_code 
							LET l_rec_jobledger.var_code = l_rec_voucherdist.var_code 
							LET l_rec_jobledger.activity_code = l_rec_voucherdist.act_code 
							LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
							LET l_rec_jobledger.trans_type_ind = "VO" 
							LET l_rec_jobledger.trans_source_num=p_rec_voucher.vouch_code 
							LET l_rec_jobledger.trans_source_text= l_rec_voucherdist.res_code 
							LET l_rec_jobledger.trans_amt = l_rec_voucherdist.dist_amt 
							LET l_rec_jobledger.trans_qty = l_rec_voucherdist.trans_qty 
							LET l_rec_jobledger.charge_amt = l_rec_voucherdist.charge_amt 
							LET l_rec_jobledger.posted_flag = "N" 
							LET l_rec_jobledger.desc_text = "Voucher Edit " 
							
							INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
							LET l_err_message = "Update JM Activity" 
							
							UPDATE activity 
							SET seq_num = 
								l_rec_activity.seq_num,				
								act_cost_amt = act_cost_amt	- l_rec_voucherdist.dist_amt, 
								act_cost_qty = act_cost_qty	- l_rec_voucherdist.trans_qty, 
								post_revenue_amt = post_revenue_amt	- l_rec_voucherdist.charge_amt 
							WHERE cmpy_code = l_rec_voucherdist.cmpy_code 
							AND job_code = l_rec_voucherdist.job_code 
							AND var_code = l_rec_voucherdist.var_code 
							AND activity_code = l_rec_voucherdist.act_code 
							
							LET l_err_message = "Insert JM Voucher Dist.Lines" 
							
							INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
						ELSE 

							LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt	- l_rec_voucherdist.dist_amt 
							LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty	- l_rec_voucherdist.dist_qty 
							DELETE FROM t_voucherdist 
							WHERE line_num = l_rec_voucherdist.line_num 
							LET l_err_cnt = l_err_cnt + 1 
						END IF 
						
					WHEN "W" 
						LET l_err_message = "Locking Ordhead FOR UPDATE" 
						DECLARE c1_ordhead CURSOR FOR 
						SELECT * FROM ordhead 
						WHERE cmpy_code = p_cmpy 
						AND order_num = l_rec_voucherdist.po_num 
						FOR UPDATE 
						OPEN c1_ordhead 
						FETCH c1_ordhead INTO l_rec_ordhead.* 
						IF status = 0 THEN 
							UPDATE ordhead SET export_cost_amt = export_cost_amt +	l_rec_voucherdist.dist_amt 
							WHERE cmpy_code = p_cmpy 
							AND order_num = l_rec_ordhead.order_num 
							CLOSE c1_ordhead 
							LET l_err_message = "Insert OE Voucher Dist.Lines" 
							INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
						ELSE 
							#JP
							LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt	- l_rec_voucherdist.dist_amt 
							LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty	- l_rec_voucherdist.dist_qty 
							DELETE FROM t_voucherdist 
							WHERE line_num = l_rec_voucherdist.line_num 
							LET l_err_cnt = l_err_cnt + 1 
						END IF 
						
					WHEN "A" 
						# AR Updates

						SELECT * INTO l_rec_customer.* FROM customer 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_rec_voucherdist.res_code 
						LET l_rec_invoicehead.total_amt = l_rec_voucherdist.dist_amt +	l_rec_voucherdist.cost_amt +	l_rec_voucherdist.charge_amt 
						LET l_rec_invoicehead.inv_num = l_rec_voucherdist.po_num 
						LET l_rec_invoicehead.inv_date = l_rec_voucherdist.job_code 
						LET l_rec_invoicehead.cust_code = l_rec_voucherdist.res_code 
						LET l_rec_invoicehead.purchase_code = 
						l_rec_voucherdist.analysis_text 
						LET l_rec_invoicehead.year_num = p_rec_voucher.year_num 
						LET l_rec_invoicehead.period_num = p_rec_voucher.period_num 
						LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
						LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
						LET l_rec_invoicehead.com1_text = l_rec_voucherdist.desc_text 
						LET l_rec_invoicehead.goods_amt = l_rec_voucherdist.dist_amt 
						LET l_rec_invoicehead.hand_amt = l_rec_voucherdist.charge_amt 
						LET l_rec_invoicehead.tax_amt = l_rec_voucherdist.cost_amt 
						IF l_rec_customer.corp_cust_code IS NOT NULL AND 
						
						l_rec_customer.corp_cust_ind = "1" THEN 
							LET l_cust_code = l_rec_customer.corp_cust_code 
							LET l_rec_invoicehead.org_cust_code =	l_rec_invoicehead.cust_code 
						ELSE 
							LET l_cust_code = l_rec_customer.cust_code 
							LET l_rec_invoicehead.org_cust_code = NULL 
						END IF 

						SELECT * INTO l_rec_tax.* FROM tax 
						WHERE tax_code = l_rec_invoicehead.tax_code 
						AND cmpy_code = p_cmpy 
						DECLARE c2_customer CURSOR FOR 

						SELECT * FROM customer 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_cust_code 
						FOR UPDATE 
						OPEN c2_customer 
						FETCH c2_customer INTO l_rec_customer.* 

						SELECT * FROM invoicehead 
						WHERE cmpy_code = p_cmpy 
						AND inv_num = l_rec_voucherdist.po_num 
						IF status = 0 THEN 
							UPDATE invoicehead	SET 
								sale_code = l_rec_invoicehead.sale_code, 
								term_code = l_rec_invoicehead.term_code, 
								tax_code = l_rec_invoicehead.tax_code, 
								goods_amt = l_rec_invoicehead.goods_amt, 
								hand_amt = l_rec_invoicehead.hand_amt, 
								tax_amt = l_rec_invoicehead.tax_amt, 
								total_amt = l_rec_invoicehead.total_amt, 
								year_num = l_rec_invoicehead.year_num, 
								period_num = l_rec_invoicehead.period_num, 
								inv_date = l_rec_invoicehead.inv_date, 
								currency_code = l_rec_invoicehead.currency_code, 
								com1_text = l_rec_invoicehead.com1_text, 
								purchase_code = l_rec_invoicehead.purchase_code 
							WHERE cmpy_code = p_cmpy 
							AND inv_num = l_rec_voucherdist.po_num 
							AND cust_code = l_rec_voucherdist.res_code 
							UPDATE invoicedetl SET 
								invoicedetl.unit_sale_amt =	l_rec_invoicehead.goods_amt, 
								invoicedetl.unit_tax_amt = 	l_rec_invoicehead.tax_amt, 
								invoicedetl.line_total_amt =	l_rec_invoicehead.goods_amt	+ l_rec_invoicehead.tax_amt,
								invoicedetl.ext_sale_amt = 	l_rec_invoicehead.goods_amt, 
								invoicedetl.ext_tax_amt = l_rec_invoicehead.tax_amt, 
								invoicedetl.line_text = l_rec_invoicehead.com1_text 
							WHERE cmpy_code = p_cmpy 
							AND inv_num = l_rec_voucherdist.po_num 
							AND line_num = 1 
						ELSE 
							LET l_rec_invoicehead.cust_code = l_cust_code 
							LET l_rec_invoicehead.cmpy_code = p_cmpy 
							LET l_rec_invoicehead.ord_num = NULL 
							LET l_rec_invoicehead.job_code = NULL 
							LET l_rec_invoicehead.entry_code = p_kandoouser_sign_on_code 
							LET l_rec_invoicehead.entry_date = today 
							LET l_rec_invoicehead.sale_code = l_rec_customer.sale_code 
							LET l_rec_invoicehead.currency_code =	l_rec_customer.currency_code 
							LET l_rec_invoicehead.invoice_to_ind =	l_rec_customer.invoice_to_ind 
							LET l_rec_invoicehead.territory_code = l_rec_customer.territory_code 
							LET l_rec_invoicehead.scheme_amt = 0 
							LET l_rec_invoicehead.jour_num = NULL 
							LET l_rec_invoicehead.post_date = NULL 
							LET l_rec_invoicehead.manifest_num = NULL 
							LET l_rec_invoicehead.stat_date = NULL 
							LET l_rec_invoicehead.line_num = 1 
							LET l_rec_invoicehead.rev_date = l_rec_invoicehead.entry_date 
							LET l_rec_invoicehead.name_text = l_rec_customer.name_text 
							LET l_rec_invoicehead.ship_code = l_rec_customer.cust_code 
							LET l_rec_invoicehead.addr1_text = l_rec_customer.addr1_text 
							LET l_rec_invoicehead.addr2_text = l_rec_customer.addr2_text 
							LET l_rec_invoicehead.city_text = l_rec_customer.city_text 
							LET l_rec_invoicehead.state_code = l_rec_customer.state_code 
							LET l_rec_invoicehead.post_code = l_rec_customer.post_code 
							LET l_rec_invoicehead.country_code = l_rec_customer.country_code --@db-patch_2020_10_04-- 
							LET l_rec_invoicehead.contact_text = l_rec_customer.contact_text 
							LET l_rec_invoicehead.tele_text = l_rec_customer.tele_text 
							LET l_rec_invoicehead.hand_tax_amt = 0 
							LET l_rec_invoicehead.freight_amt = 0 
							LET l_rec_invoicehead.freight_tax_amt = 0 
							LET l_rec_invoicehead.tax_per = l_rec_tax.tax_per 
							LET l_rec_invoicehead.disc_amt = 0 
							LET l_rec_invoicehead.paid_amt = 0 
							LET l_rec_invoicehead.paid_date = NULL 
							LET l_rec_invoicehead.disc_taken_amt = 0 
							LET l_rec_invoicehead.disc_per = 0 
							LET l_rec_invoicehead.cost_amt = 0 
							LET l_rec_invoicehead.acct_override_code =	l_rec_voucherdist.acct_code 
							
							LET l_rec_invoicehead.conv_qty =	get_conv_rate(
								p_cmpy, 
								l_rec_invoicehead.currency_code, 
								l_rec_invoicehead.inv_date,
								CASH_EXCHANGE_SELL)
								 
							LET l_rec_invoicedetl.tax_code = l_rec_invoicehead.tax_code 
							
							IF l_rec_invoicehead.term_code IS NOT NULL THEN
							
								CALL db_term_get_rec(UI_OFF,l_rec_invoicehead.term_code) RETURNING l_rec_term.*  
								
								CALL get_due_and_discount_date(l_rec_term.*,l_rec_invoicehead.inv_date) 
								RETURNING l_rec_invoicehead.due_date,	l_rec_invoicehead.disc_date 
								
								LET l_rec_invoicehead.disc_per = l_rec_term.disc_per 
							END IF 
							
							LET l_rec_invoicehead.ship_date = l_rec_invoicehead.inv_date 
							LET l_rec_invoicehead.prepaid_flag = "P" 
							LET l_rec_invoicehead.seq_num = 0 
							LET l_rec_invoicehead.on_state_flag = "N" 
							LET l_rec_invoicehead.posted_flag = "N" 
							LET l_rec_invoicehead.inv_ind = "P" 
							LET l_rec_invoicehead.printed_num = 1 
							LET l_rec_invoicedetl.cmpy_code = p_cmpy 
							LET l_rec_invoicedetl.ship_qty = 1 
							LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ship_qty 
							LET l_rec_invoicedetl.line_num = 1 
							LET l_rec_invoicedetl.level_code = 1 
							LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicehead.goods_amt 
							LET l_rec_invoicedetl.unit_tax_amt = l_rec_invoicehead.tax_amt 
							LET l_rec_invoicedetl.ext_sale_amt = l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_sale_amt 
							LET l_rec_invoicedetl.ext_tax_amt = l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_tax_amt 
							LET l_rec_invoicedetl.line_total_amt = l_rec_invoicedetl.ext_sale_amt + l_rec_invoicedetl.ext_tax_amt 
							LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
							LET l_rec_invoicedetl.order_line_num = NULL 
							LET l_rec_invoicedetl.order_num = NULL 
							LET l_rec_invoicedetl.ord_qty = 1 
							LET l_rec_invoicedetl.back_qty = 0 
							LET l_rec_invoicedetl.prev_qty = 0 
							LET l_rec_invoicedetl.ser_flag = "N" 
							LET l_rec_invoicedetl.ser_qty = 0 
							LET l_rec_invoicedetl.unit_cost_amt = 0 
							LET l_rec_invoicedetl.ext_cost_amt = 0 
							LET l_rec_invoicedetl.disc_amt = 0 
							LET l_rec_invoicedetl.ext_bonus_amt = 0 
							LET l_rec_invoicedetl.ext_stats_amt = 0 
							LET l_rec_invoicedetl.disc_per = 0 
							LET l_rec_invoicedetl.line_text = l_rec_invoicehead.com1_text 
							LET l_rec_invoicedetl.line_acct_code = l_rec_voucherdist.acct_code 
							LET l_rec_invoicehead.inv_num = next_trans_num(
								p_cmpy,
								TRAN_TYPE_INVOICE_IN,
								l_rec_invoicehead.acct_override_code) 
							
							IF l_rec_invoicehead.inv_num < 0 THEN 
								LET l_err_message = "Next invoice number UPDATE" 
								LET status = l_rec_invoicehead.inv_num 
								GOTO recovery 
							END IF 
							
							LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
							LET l_err_message = "invoice line addition failed" 
							
							#INSERT invoiceDetl Record
							IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
								INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
							ELSE
								DISPLAY l_rec_invoicedetl.*
								CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
							END IF 
	
							LET l_err_message = "Unable TO add TO invoice header table" 

							#INSERT invoicehead Record
							IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
								INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
							ELSE
								DISPLAY l_rec_invoicehead.*
								CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
							END IF 

						END IF 
						
						LET l_err_message = "Customer Update Inv" 
						LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
						LET l_rec_customer.bal_amt = l_rec_customer.bal_amt + l_rec_invoicehead.total_amt 
						LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + l_rec_invoicehead.total_amt 
						
						INITIALIZE l_rec_araudit.* TO NULL 
						
						LET l_rec_araudit.cmpy_code = p_cmpy 
						LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
						LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
						LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
						LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
						LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
						LET l_rec_araudit.tran_text = "Adjustment" 
						LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
						LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
						LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
						LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
						LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
						LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
						LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
						LET l_rec_araudit.entry_date = today 
						LET l_err_message = "Unable TO add TO AR log table " 
						
						# INSERT INTO araudit ----------------------------------
						INSERT INTO araudit VALUES (l_rec_araudit.*) 
						
						IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
							LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
						END IF 
						
						LET l_rec_customer.cred_bal_amt =	l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
						
						IF year(l_rec_invoicehead.inv_date)	> year(l_rec_customer.last_inv_date) THEN 
							LET l_rec_customer.ytds_amt = 0 
						END IF 
						
						LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt	+ l_rec_invoicehead.total_amt 
						
						IF (month(l_rec_invoicehead.inv_date) > month(l_rec_customer.last_inv_date) 
						OR year(l_rec_invoicehead.inv_date)	> year(l_rec_customer.last_inv_date)) THEN 
							LET l_rec_customer.mtds_amt = 0 
						END IF 
						
						LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt	+ l_rec_invoicehead.total_amt 
						LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
						LET l_err_message = "Custmain actual UPDATE " 
						
						# UPDATE customer  --------------------------------------
						UPDATE customer SET 
							next_seq_num = l_rec_customer.next_seq_num, 
							bal_amt = l_rec_customer.bal_amt, 
							curr_amt = l_rec_customer.curr_amt, 
							highest_bal_amt = l_rec_customer.highest_bal_amt, 
							cred_bal_amt = l_rec_customer.cred_bal_amt, 
							last_inv_date = l_rec_customer.last_inv_date, 
							ytds_amt = l_rec_customer.ytds_amt, 
							mtds_amt = l_rec_customer.mtds_amt 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_rec_customer.cust_code 

						CLOSE c2_customer 

						LET l_rec_voucherdist.po_num = l_rec_invoicehead.inv_num 
						LET l_rec_voucherdist.po_line_num = 1 
						LET l_rec_voucherdist.trans_qty = 1 
						LET l_err_message = "Insert OE Voucher Dist.Lines" 

						# INSERT INTO voucherdist ------------------------------
						INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 

						# END AR Updates

					OTHERWISE 
						LET l_err_message = "Insert GL Voucher Dist.Lines"
						
						# INSERT INTO voucherdist ------------------------------ 
						INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
				END CASE 
			ELSE 

				LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt - l_rec_voucherdist.dist_amt 
				LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - l_rec_voucherdist.dist_qty 
				
				DELETE FROM t_voucherdist 
				WHERE line_num = l_rec_voucherdist.line_num 
				LET l_err_cnt = l_err_cnt + 1 
			END IF 
		END FOREACH 
		
		LET l_err_message = "Update Voucher Dist. Amounts" 
		
		# UPDATE voucher ----------------------------------
		UPDATE voucher SET 
			dist_amt = p_rec_voucher.dist_amt, 
			dist_qty = p_rec_voucher.dist_qty, 
			line_num = p_rec_voucher.line_num 
		WHERE cmpy_code = p_rec_voucher.cmpy_code 
		AND vouch_code = p_rec_voucher.vouch_code 
	
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	## Similar TO batch entry there are three possible states
	##  zero - No UPDATE
	##  pos vouch_num - Voucher/Vendor Update
	##  neg vouch_num - Voucher/Vendor Distributions
	IF l_err_cnt > 0 THEN 
		RETURN (0 - p_rec_voucher.vouch_code) 
	ELSE 
		RETURN p_rec_voucher.vouch_code 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION update_database(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher)
###########################################################################