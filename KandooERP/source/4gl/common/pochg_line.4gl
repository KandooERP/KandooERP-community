{
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

	Source code beautified by beautify.pl on 2020-01-02 10:35:26	$Id: $
}



#
#    pochng_line modifies the line that IS there
#
# A few combinations can occur here.
#
#  1. No voucher OR receipt AND price only change
#       - reverse out current with a CP
#       - put new in with a CP
#  2. No voucher OR receipt AND quantity only change
#       - reverse out current with a CQ
#       - put new in with a CQ
#  3. No voucher OR receipt AND both quantity AND price change
#       disallow only price OR quantity seperately can be changed
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
#  6. Quantity only change AND vouchers present
#       allow change down TO voucher qty only
#       - use CQ TO change quantity
#  7. Quantity only change AND receipts present
#       allow change down TO receipt qty only
#       - use CQ TO change quantity
#  8. Both quantity AND price change AND receipts present
#       disallow only price OR quantity seperately can be changed
#  9. Both quantity AND price change AND vouchers present
#       disallow only price OR quantity seperately can be changed
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION mod_po_line(p_cmpy_code, p_kandoouser_sign_on_code, p_rec_purchhead, p_rec_purchdetl, p_rec_poaudit)
#
#
############################################################
FUNCTION mod_po_line(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 

	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(70) 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
	#DEFINE l_rec_puparms RECORD LIKE puparms.* not used ?
	DEFINE l_err_stat INTEGER 
	DEFINE l_row_id INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	### Obtain the current po_audit FOR reversing
	###   cu_ stands FOR current
	###   pr_ IS the UPDATE poaudit
	LET l_rec_cu_poaudit.* = p_rec_poaudit.* 
	CALL po_line_info(p_cmpy_code, 
	p_rec_purchdetl.order_num, 
	p_rec_purchdetl.line_num) 
	RETURNING l_rec_cu_poaudit.order_qty, 
	l_rec_cu_poaudit.received_qty, 
	l_rec_cu_poaudit.voucher_qty, 
	l_rec_cu_poaudit.unit_cost_amt, 
	l_rec_cu_poaudit.ext_cost_amt, 
	l_rec_cu_poaudit.unit_tax_amt, 
	l_rec_cu_poaudit.ext_tax_amt, 
	l_rec_cu_poaudit.line_total_amt 
	IF l_rec_cu_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
	AND l_rec_cu_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt 
	AND l_rec_cu_poaudit.order_qty = p_rec_poaudit.order_qty THEN 
		RETURN true ### no qty's OR amt's changed 
	END IF 
	CASE 
	#  3. No voucher OR receipt AND both quantity AND price change
	#       disallow only price OR quantity seperately can be changed
	#  8. Both quantity AND price change AND receipts present
	#       disallow only price OR quantity seperately can be changed
	#  9. Both quantity AND price change AND vouchers present
	#       disallow only price OR quantity seperately can be changed
	#  4. Price only change AND vouchers present
	#       NOT allowed, edit voucher will take off voucher qty
	#       AND IF > 1 voucher THEN split line (because 2 prices)
	#       by change quantity CQ AND add new line AL
		WHEN (((l_rec_cu_poaudit.unit_cost_amt != p_rec_poaudit.unit_cost_amt) OR 
			(l_rec_cu_poaudit.unit_tax_amt != p_rec_poaudit.unit_tax_amt)) AND 
			(l_rec_cu_poaudit.voucher_qty > 0)) 
			LET l_msgresp = kandoomsg("P",9528,"") 
			#9528 Cannot change price with voucher logged, alter qty instead.
			RETURN true 
	END CASE 
	# ok now we need TO lock the purchdetl because we are going
	# TO change the seq_num as we add the poaudit transactions
	GOTO bypass 
	LABEL recovery: 
	LET l_err_stat = status 
	RETURN l_err_stat 
	# IF a lock was encountered pass lock TO po_mod() OR R14/R17/R21 etc
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	DECLARE seq_curs CURSOR FOR 
	SELECT rowid, purchdetl.* INTO l_row_id, p_rec_purchdetl.* FROM purchdetl 
	WHERE cmpy_code = p_rec_purchdetl.cmpy_code 
	AND order_num = p_rec_purchdetl.order_num 
	AND line_num = p_rec_purchdetl.line_num 
	FOR UPDATE 
	FOREACH seq_curs 
		EXIT FOREACH 
	END FOREACH 
	CASE 
	#  1. No voucher OR receipt AND price only change
	#       - reverse out current with a CP
	#       - put new in with a CP
		WHEN (l_rec_cu_poaudit.received_qty = 0 
			AND l_rec_cu_poaudit.voucher_qty = 0 
			AND (l_rec_cu_poaudit.order_qty = p_rec_poaudit.order_qty)) 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			l_rec_cu_poaudit.*, 
			"CP", 
			"out") 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			p_rec_poaudit.*, 
			"CP", 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			#  2. No voucher OR receipt AND quantity only change
			#       - reverse out current with a CQ
			#       - put new in with a CQ
		WHEN (l_rec_cu_poaudit.received_qty = 0 
			AND l_rec_cu_poaudit.voucher_qty = 0 
			AND (l_rec_cu_poaudit.order_qty != p_rec_poaudit.order_qty)) 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			l_rec_cu_poaudit.*, 
			"CQ", 
			"out") 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			# check IF zero dont put in, this FUNCTION does the delete too !!!
			IF p_rec_poaudit.order_qty > 0 THEN 
				CALL audit_it(p_cmpy_code, 
				p_kandoouser_sign_on_code, 
				p_rec_purchhead.*, 
				p_rec_purchdetl.*, 
				p_rec_poaudit.*, 
				"CQ", 
				TRAN_TYPE_INVOICE_IN) 
				RETURNING l_err_stat 
				IF l_err_stat < 0 THEN 
					RETURN l_err_stat 
				END IF 
			END IF 
			#  5. Price only change AND receipts present
			#       - reverse out current with a CP
			#       - put new in with a CP
			#       - reverse out receipt qty with a GA with current price
			#       - put new price in with the GA
		WHEN (( (l_rec_cu_poaudit.unit_cost_amt != p_rec_poaudit.unit_cost_amt) 
			OR(l_rec_cu_poaudit.unit_tax_amt != p_rec_poaudit.unit_tax_amt)) 
			AND (l_rec_cu_poaudit.received_qty > 0)) 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			l_rec_cu_poaudit.*, 
			"CP", 
			"out") 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			l_rec_cu_poaudit.*, 
			"GA", 
			"out") 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			p_rec_poaudit.*, 
			"CP", 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			p_rec_poaudit.*, 
			"GA", 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			#  6. Quantity only change AND vouchers present
			#       allow change down TO voucher qty only
			#       - use CQ TO change quantity
			#  7. Quantity only change AND receipts present
			#       allow change down TO receipt qty only
			#       - use CQ TO change quantity

		WHEN (l_rec_cu_poaudit.received_qty != 0 
			OR l_rec_cu_poaudit.voucher_qty > 0 
			AND (l_rec_cu_poaudit.order_qty != p_rec_poaudit.order_qty) 
			AND ((p_rec_poaudit.order_qty >= l_rec_cu_poaudit.voucher_qty) 
			AND (p_rec_poaudit.order_qty >= l_rec_cu_poaudit.received_qty))) 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			l_rec_cu_poaudit.*, 
			"CQ", 
			"out") 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
			LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
			CALL audit_it(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			p_rec_purchhead.*, 
			p_rec_purchdetl.*, 
			p_rec_poaudit.*, 
			"CQ", 
			TRAN_TYPE_INVOICE_IN) 
			RETURNING l_err_stat 
			IF l_err_stat < 0 THEN 
				RETURN l_err_stat 
			END IF 
		OTHERWISE 
			LET l_err_message = "A Logic Error has occurred with the modification of the qty fields" 
			CALL errorlog(l_err_message) 
			LET l_msgresp = kandoomsg("U",7004,"") 
			#7004 An error occured with the PO modification.
			ROLLBACK WORK 
			RETURN true 
	END CASE 

	UPDATE purchdetl 
	SET seq_num = p_rec_purchdetl.seq_num 
	WHERE rowid = l_row_id 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION audit_it(p_cmpy_code, p_kandoouser_sign_on_code, p_rec_purchhead, p_rec_purchdetl, p_rec_poaudit, p_tran_info, p_direct_ind)
#
#
############################################################
FUNCTION audit_it(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info,p_direct_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE p_tran_info LIKE poaudit.tran_code 
	DEFINE p_direct_ind CHAR(3) 

	#DEFINE l_err_continue CHAR(1) not used ?
	DEFINE l_err_message CHAR(50) 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_pf_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
	DEFINE l_alloc_ind LIKE jobledger.allocation_ind 
	#DEFINE l_temp_year_num   LIKE poaudit.year_num #not used ?
	#DEFINE l_temp_period_num LIKE poaudit.period_num #not used ?
	#DEFINE l_save_year_num   LIKE poaudit.year_num #not used ?
	#DEFINE l_save_period_num LIKE poaudit.period_num #not used ?
	DEFINE l_err_stat INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	LET l_err_stat = status 
	RETURN l_err_stat 
	#IF a locking error was encountered - pass back the lock error TO
	#the mod_po_line FUNCTION above
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET p_rec_poaudit.cmpy_code = p_rec_purchdetl.cmpy_code 
	LET p_rec_poaudit.vend_code = p_rec_purchdetl.vend_code 
	LET p_rec_poaudit.po_num = p_rec_purchdetl.order_num 
	LET p_rec_poaudit.line_num = p_rec_purchdetl.line_num 
	LET p_rec_poaudit.tran_code = p_tran_info 
	LET p_rec_poaudit.tran_num = 0 
	LET p_rec_poaudit.jour_num = 0 
	LET p_rec_poaudit.entry_date = today 
	LET p_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
	LET p_rec_poaudit.posted_flag = "N" 
	LET p_rec_poaudit.orig_auth_flag = "Y" 
	LET p_rec_poaudit.now_auth_flag = "Y" 
	LET p_rec_poaudit.seq_num = p_rec_purchdetl.seq_num 
	LET p_rec_poaudit.desc_text = p_rec_purchdetl.desc_text 
	CASE 
		WHEN (p_direct_ind = "out" AND p_tran_info = "GA") 
			LET p_rec_poaudit.received_qty = - p_rec_poaudit.received_qty 
			LET p_rec_poaudit.order_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "GA") 
			LET p_rec_poaudit.received_qty = p_rec_poaudit.received_qty 
			LET p_rec_poaudit.order_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.received_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		WHEN (p_direct_ind = "out" AND p_tran_info = "CP") 
			LET p_rec_poaudit.order_qty = - p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "CP") 
			LET p_rec_poaudit.order_qty = p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		WHEN (p_direct_ind = "out" AND p_tran_info = "CQ") 
			LET p_rec_poaudit.order_qty = - p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		WHEN (p_direct_ind = TRAN_TYPE_INVOICE_IN AND p_tran_info = "CQ") 
			LET p_rec_poaudit.order_qty = p_rec_poaudit.order_qty 
			LET p_rec_poaudit.received_qty = 0 
			LET p_rec_poaudit.voucher_qty = 0 
			LET p_rec_poaudit.ext_cost_amt = p_rec_poaudit.unit_cost_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.ext_tax_amt = p_rec_poaudit.unit_tax_amt 
			* p_rec_poaudit.order_qty 
			LET p_rec_poaudit.line_total_amt = p_rec_poaudit.ext_tax_amt 
			+ p_rec_poaudit.ext_cost_amt 
		OTHERWISE 
			LET l_err_message = " Problem p_tran_info = ",p_tran_info, 
			" direct_info = ",p_direct_ind 
			LET l_msgresp = kandoomsg("U",1,l_err_message) 
	END CASE 
	LET l_err_message = " Inserting row INTO poaudit " 
	INSERT INTO poaudit VALUES (p_rec_poaudit.*) 

	IF (p_rec_purchdetl.type_ind = "I" OR p_rec_purchdetl.type_ind = "C") 
	AND (p_tran_info = "GA" OR p_tran_info = "CQ") THEN 
		IF p_direct_ind = "out" THEN 
			SELECT * INTO l_rec_pf_purchdetl.* FROM purchdetl 
			WHERE cmpy_code = p_rec_purchhead.cmpy_code 
			AND order_num = p_rec_purchhead.order_num 
			AND line_num = p_rec_purchdetl.line_num 
			LET p_rec_purchdetl.ref_text = l_rec_pf_purchdetl.ref_text 
		ELSE 
			SELECT * INTO l_rec_pf_purchdetl.* FROM t_purchdetl 
			WHERE line_num = p_rec_purchdetl.line_num 
			LET p_rec_purchdetl.ref_text = l_rec_pf_purchdetl.ref_text 
		END IF 
		CALL po_adjustments(p_cmpy_code, 
		p_kandoouser_sign_on_code, 
		p_rec_purchhead.*, 
		p_rec_purchdetl.*, 
		p_rec_poaudit.*, 
		p_tran_info) 
		RETURNING l_err_stat 
		IF l_err_stat < 0 THEN 
			LET l_err_message =" Error in UPDATE of product details " 
			#IF a locking error was encountered - pass back the lock error TO
			#the caller of auditit FUNCTION above
			RETURN l_err_stat 
		END IF 
	END IF 
	### Reverse the jobledger transaction
	IF (p_rec_purchdetl.type_ind = "J" 
	OR p_rec_purchdetl.type_ind = "C") 
	AND p_rec_poaudit.order_qty >= 0 
	AND p_tran_info = "GA" THEN 
		# INSERT a jobledger row FOR this transaction AND UPDATE
		# the activity with the cost of the purchase.
		DECLARE act_c CURSOR FOR 
		SELECT activity.* FROM activity 
		WHERE cmpy_code = p_cmpy_code 
		AND job_code = p_rec_purchdetl.job_code 
		AND var_code = p_rec_purchdetl.var_num 
		AND activity_code = p_rec_purchdetl.activity_code 
		FOR UPDATE 
		OPEN act_c 
		FETCH act_c INTO l_rec_activity.* 

		SELECT allocation_ind INTO l_alloc_ind 
		FROM jmresource 
		WHERE cmpy_code = p_cmpy_code 
		AND res_code = p_rec_purchdetl.res_code 

		LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
		LET l_rec_jobledger.cmpy_code = p_cmpy_code 
		LET l_rec_jobledger.trans_date = p_rec_poaudit.tran_date 
		LET l_rec_jobledger.year_num = p_rec_poaudit.year_num 
		LET l_rec_jobledger.period_num = p_rec_poaudit.period_num 
		LET l_rec_jobledger.job_code = p_rec_purchdetl.job_code 
		LET l_rec_jobledger.var_code = p_rec_purchdetl.var_num 
		LET l_rec_jobledger.activity_code = p_rec_purchdetl.activity_code 
		LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
		LET l_rec_jobledger.trans_type_ind = "PU" 
		LET l_rec_jobledger.trans_source_num = p_rec_poaudit.po_num 
		LET l_rec_jobledger.trans_source_text = p_rec_purchdetl.ref_text 
		LET l_rec_jobledger.trans_amt = p_rec_poaudit.ext_cost_amt 
		LET l_rec_jobledger.trans_qty = p_rec_poaudit.received_qty 
		LET l_rec_jobledger.charge_amt = p_rec_purchdetl.charge_amt 
		* l_rec_jobledger.trans_qty 
		LET l_rec_jobledger.posted_flag = "N" 
		LET l_rec_jobledger.desc_text = p_rec_poaudit.desc_text 
		LET l_rec_jobledger.allocation_ind = l_alloc_ind 

		INSERT INTO jobledger VALUES ( l_rec_jobledger.*) 

		UPDATE activity 
		SET act_cost_amt = act_cost_amt + p_rec_poaudit.ext_cost_amt, 
		act_cost_qty = act_cost_qty + p_rec_poaudit.received_qty, 
		seq_num = l_rec_activity.seq_num 
		WHERE cmpy_code = p_cmpy_code 
		AND job_code = l_rec_jobledger.job_code 
		AND var_code = l_rec_jobledger.var_code 
		AND activity_code = l_rec_jobledger.activity_code 
	END IF 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION po_adjustments(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info)
#
#
############################################################
FUNCTION po_adjustments(p_cmpy_code,p_kandoouser_sign_on_code,p_rec_purchhead,p_rec_purchdetl,p_rec_poaudit,p_tran_info) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
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
	DEFINE l_calc_method_flag LIKE tax.calc_method_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_error_msg CHAR(100) 
	DEFINE l_total_qty DECIMAL(12,4) 
	DEFINE l_wsale_tax DECIMAL(12,4) 
	DEFINE l_save_qty FLOAT 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_err_stat INTEGER 

	GOTO bypass 

	LABEL recovery: 
	LET l_err_stat = status 
	RETURN l_err_stat 
	#Returns a lock error back TO the auditit FUNCTION above OR FROM the
	#po_mod FUNCTION residing in po_mod.4gl

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	SELECT * INTO l_rec_inparms.* FROM inparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE cmpy_code = p_rec_purchhead.cmpy_code 
	AND part_code = p_rec_purchdetl.ref_text 
	IF status = notfound THEN 
		LET l_error_msg = "Product Details NOT found FOR ", 
		p_rec_purchdetl.ref_text 
		CALL errorlog(l_error_msg) 
		EXIT program 1 
	END IF 

	SELECT * INTO l_rec_vendor.* FROM vendor 
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

	DECLARE c_prodstatus CURSOR FOR 
	SELECT * FROM prodstatus 
	WHERE part_code = l_rec_prodledg.part_code 
	AND ware_code = l_rec_prodledg.ware_code 
	AND cmpy_code = p_rec_purchhead.cmpy_code 
	FOR UPDATE 
	OPEN c_prodstatus 
	FETCH c_prodstatus INTO l_rec_prodstatus.* 

	LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
	LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 

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
	LET l_rec_prodledg.cost_amt = conv_currency(l_rec_prodledg.cost_amt, 
	p_cmpy_code, 
	l_rec_vendor.currency_code, 
	"F", 
	p_rec_poaudit.tran_date, 
	"B") 
	IF p_tran_info = "GA" THEN 
		IF l_rec_prodledg.cost_amt IS NULL THEN 
			LET l_rec_prodledg.cost_amt = 0 
		END IF 
		LET l_rec_prodledg.cmpy_code = p_cmpy_code 
		LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
		LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
		LET l_rec_prodledg.trantype_ind = PAYMENT_TYPE_CC_P #? was "P" 
		LET l_rec_prodledg.sales_amt = 0 
		IF l_rec_inparms.hist_flag = "Y" THEN 
			LET l_rec_prodledg.hist_flag = "N" 
		ELSE 
			LET l_rec_prodledg.hist_flag = "Y" 
		END IF 
		LET l_rec_prodledg.post_flag = "N" 
		LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty + 
		p_rec_poaudit.received_qty 
		LET l_rec_prodledg.year_num = p_rec_poaudit.year_num 
		LET l_rec_prodledg.period_num = p_rec_poaudit.period_num 
		LET l_rec_prodledg.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_prodledg.entry_date = today 
		LET l_err_message = "pochg_line - Product Ledger INSERT" 

		INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

		LET l_rec_prodstatus.act_cost_amt = l_rec_prodledg.cost_amt 
		LET l_err_message = "pochg_line - prodstatus UPDATE" 
		LET l_total_qty = l_rec_prodstatus.onhand_qty + l_rec_prodledg.tran_qty 

		SELECT calc_method_flag INTO l_calc_method_flag FROM tax 
		WHERE cmpy_code = p_cmpy_code 
		AND tax_code = p_rec_purchhead.tax_code 

		SELECT * INTO l_rec_tax.* FROM tax 
		WHERE cmpy_code = p_cmpy_code 
		AND tax_code = l_rec_prodstatus.purch_tax_code 

		IF l_rec_tax.calc_method_flag = "W" 
		AND l_calc_method_flag = "W" THEN 
			IF l_rec_tax.uplift_per IS NULL THEN 
				LET l_rec_tax.uplift_per = 0 
			END IF 
			LET l_wsale_tax = 0 



		ELSE 
			LET l_wsale_tax = 0 
		END IF 

		IF l_total_qty <= 0 THEN 
			LET l_rec_prodstatus.wgted_cost_amt = l_rec_prodledg.cost_amt 
			LET l_rec_prodstatus.purch_tax_amt = 0 
		ELSE 
			LET l_save_qty = l_rec_prodstatus.onhand_qty 
			IF l_save_qty < 0 THEN 
				LET l_save_qty = 0 
			END IF 
			LET l_rec_prodstatus.wgted_cost_amt = 
			( (l_rec_prodstatus.wgted_cost_amt * l_save_qty) 
			+ (l_rec_prodledg.tran_qty * (l_rec_prodledg.cost_amt + l_wsale_tax))) 
			/ (l_rec_prodledg.tran_qty + l_save_qty ) 
			IF l_wsale_tax > 0 THEN 
				LET l_rec_prodstatus.purch_tax_amt = 
				( (l_rec_prodstatus.purch_tax_amt * l_save_qty) 
				+ (l_rec_prodledg.tran_qty * l_wsale_tax) ) 
				/ (l_rec_prodledg.tran_qty + l_save_qty) 
				IF l_rec_prodledg.tran_qty < 0 THEN 
					LET l_rec_prodledg.source_text = "PO C WS-TAX" 
				END IF 
				LET l_rec_prodledg.sales_amt = 0 
				LET l_rec_prodledg.hist_flag = "N" 
				LET l_rec_prodledg.post_flag = "N" 
				LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodledg.year_num = p_rec_poaudit.year_num 
				LET l_rec_prodledg.period_num = p_rec_poaudit.period_num 
				LET l_rec_prodledg.entry_code = p_kandoouser_sign_on_code 
				LET l_rec_prodledg.entry_date = today 
				LET l_rec_prodledg.part_code = l_rec_prodstatus.part_code 
				LET l_rec_prodledg.ware_code = l_rec_prodstatus.ware_code 
				LET l_rec_prodledg.tran_date = p_rec_poaudit.tran_date 
				LET l_rec_prodledg.trantype_ind = "W" 
				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
				LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
				LET l_rec_prodledg.cost_amt = l_wsale_tax 
				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
			END IF 
		END IF 
		LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty 
		+ l_rec_prodledg.tran_qty 
	END IF 

	IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
		LET l_rec_prodstatus.wgted_cost_amt = 0 
	END IF 
	IF l_rec_prodstatus.act_cost_amt IS NULL THEN 
		LET l_rec_prodstatus.act_cost_amt = 0 
	END IF 
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"SC") = "0" THEN 
		IF p_rec_purchhead.vend_code = l_rec_product.vend_code THEN 
			LET l_rec_prodstatus.for_cost_amt = 
			((p_rec_poaudit.unit_cost_amt 
			/ l_rec_product.pur_stk_con_qty) 
			/ l_rec_product.stk_sel_con_qty) 
		END IF 
		LET l_rec_prodstatus.for_curr_code = l_rec_vendor.currency_code 
	END IF 
	IF l_rec_prodstatus.stocked_flag = "Y" THEN 
		LET l_rec_prodstatus.onord_qty = l_rec_prodstatus.onord_qty 
		+ ((p_rec_poaudit.order_qty 
		* l_rec_product.pur_stk_con_qty) 
		* l_rec_product.stk_sel_con_qty) 
	END IF 

	IF l_rec_prodstatus.onord_qty IS NULL THEN 
		LET l_rec_prodstatus.onord_qty = 0 
	END IF 

	UPDATE prodstatus 
	SET seq_num = l_rec_prodstatus.seq_num, 
	onhand_qty = l_rec_prodstatus.onhand_qty, 
	onord_qty = l_rec_prodstatus.onord_qty, 
	wgted_cost_amt = l_rec_prodstatus.wgted_cost_amt, 
	purch_tax_amt = l_rec_prodstatus.purch_tax_amt, 
	act_cost_amt = l_rec_prodstatus.act_cost_amt, 
	for_cost_amt = l_rec_prodstatus.for_cost_amt, 
	for_curr_code = l_rec_prodstatus.for_curr_code 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = l_rec_prodstatus.part_code 
	AND ware_code = l_rec_prodstatus.ware_code 
	CLOSE c_prodstatus 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN true 
END FUNCTION 
