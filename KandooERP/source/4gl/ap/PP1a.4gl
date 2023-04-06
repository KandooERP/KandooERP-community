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

#
# FUNCTION - create_tax_voucher
# Purpose  - create_tax_voucher accepts a tax vendor AND tax amount AND
#            creates a voucher, distributed TO the nominated account.
#            The Tax vendor balance IS updated AND the appropriate
#            apaudit records created.
#            The voucher number IS returned TO the calling program.
#            IF there IS an error in either vendor OR apparms UPDATE,
#            the voucher number IS returned as a NULL TO signify that
#            no voucher was created.

#
# FUNCTION - create_tax_debit
# Purpose  - create_tax_debit accepts a tax vendor AND tax amount AND
#            creates a debit, distributed TO the nominated account.
#            The Tax vendor balance IS updated AND the appropriate
#            apaudit records created.
#            The debit number IS returned TO the calling program.
#            IF there IS an error in either vendor OR apparms UPDATE,
#            the debit number IS returned as a NULL TO signify that
#            no debit was created.
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 


############################################################
# FUNCTION create_tax_voucher(
#							p_cmpy,
#							p_kandoouser_sign_on_code,
#							p_tax_vendor,
#            p_tax_amount,
#            p_distribute_acct_code,
#            p_tax_year_num,
#            p_tax_period_num)
#
#
#
############################################################
FUNCTION create_tax_voucher( 
	p_cmpy, 
	p_kandoouser_sign_on_code, 
	p_tax_vendor, 
	p_tax_amount, 
	p_distribute_acct_code, 
	p_tax_year_num, 
	p_tax_period_num) 

	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_tax_vendor LIKE vendor.vend_code 
	DEFINE p_tax_amount LIKE cheque.net_pay_amt 
	DEFINE p_distribute_acct_code LIKE vendortype.pay_acct_code 
	DEFINE p_tax_year_num LIKE period.year_num 
	DEFINE p_tax_period_num LIKE period.period_num 
	#pr_apparms RECORD LIKE apparms.*,
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_update_error SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	INITIALIZE l_rec_apaudit.* TO NULL 
	INITIALIZE l_rec_voucher.* TO NULL 

	LET l_update_error = true 
	DECLARE c1_vendor CURSOR FOR 
	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE vendor.cmpy_code = p_cmpy 
	AND vendor.vend_code = p_tax_vendor 
	FOR UPDATE 
	FOREACH c1_vendor 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + p_tax_amount 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + p_tax_amount 
		IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
			LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
		END IF 
		IF l_rec_voucher.vouch_date > l_rec_vendor.last_vouc_date OR 
		l_rec_vendor.last_vouc_date IS NULL THEN 
			LET l_rec_vendor.last_vouc_date = today 
		END IF 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		UPDATE vendor 
		SET bal_amt = l_rec_vendor.bal_amt, 
		curr_amt = l_rec_vendor.curr_amt, 
		highest_bal_amt = l_rec_vendor.highest_bal_amt, 
		last_vouc_date = l_rec_vendor.last_vouc_date, 
		next_seq_num = l_rec_vendor.next_seq_num 
		WHERE CURRENT OF c1_vendor 
		LET l_update_error = false 
	END FOREACH 

	IF l_update_error THEN 
		RETURN ("") 
	END IF 

	LET l_update_error = true 
	DECLARE c1_apparms CURSOR FOR 
	SELECT * 
	INTO glob_rec_apparms.* 
	FROM apparms 
	WHERE apparms.parm_code = "1" 
	AND apparms.cmpy_code = p_cmpy 
	FOR UPDATE 
	FOREACH c1_apparms 
		IF glob_rec_apparms.next_vouch_num IS NULL THEN 
			LET glob_rec_apparms.next_vouch_num = 1 
		END IF 
		LET l_rec_voucher.vouch_code = glob_rec_apparms.next_vouch_num 
		LET glob_rec_apparms.next_vouch_num = glob_rec_apparms.next_vouch_num + 1 
		UPDATE apparms 
		SET next_vouch_num = glob_rec_apparms.next_vouch_num 
		WHERE apparms.cmpy_code = p_cmpy 
		AND apparms.parm_code = "1" 
		LET l_update_error = false 
	END FOREACH 

	IF l_update_error THEN 
		RETURN ("") 
	END IF 

	SELECT * 
	INTO l_rec_term.* 
	FROM term 
	WHERE term.term_code = l_rec_vendor.term_code 
	AND term.cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_rec_term.day_date_ind = "D" 
		LET l_rec_term.due_day_num = 0 
		LET l_rec_term.disc_day_num = 0 
		LET l_rec_term.disc_per = 0 
	END IF 
	CALL get_conv_rate(p_cmpy,l_rec_vendor.currency_code,today,	"B") 
	RETURNING l_rec_voucher.conv_qty 
	IF l_rec_voucher.conv_qty IS NULL OR l_rec_voucher.conv_qty = "" THEN 
		LET l_rec_voucher.conv_qty = 0 
	END IF 

	CALL get_due_and_discount_date(l_rec_term.*, today) 
	RETURNING l_rec_voucher.due_date, 
	l_rec_voucher.disc_date 
	IF l_rec_term.disc_day_num > 0 THEN 
		LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt * 
		l_rec_term.disc_per / 100 
	ELSE 
		LET l_rec_voucher.poss_disc_amt = 0 
		LET l_rec_voucher.disc_date = l_rec_voucher.due_date 
	END IF 

	LET l_rec_voucher.cmpy_code = p_cmpy 
	LET l_rec_voucher.vend_code = p_tax_vendor 
	LET l_rec_voucher.po_num = 0 
	LET l_rec_voucher.vouch_date = today 
	LET l_rec_voucher.entry_date = today 
	LET l_rec_voucher.entry_code = p_kandoouser_sign_on_code 
	LET l_rec_voucher.sales_text = l_rec_vendor.contact_text 
	LET l_rec_voucher.term_code = l_rec_vendor.term_code 
	LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
	LET l_rec_voucher.goods_amt = p_tax_amount 
	LET l_rec_voucher.total_amt = p_tax_amount 
	LET l_rec_voucher.dist_amt = p_tax_amount 
	LET l_rec_voucher.dist_qty = 0 
	LET l_rec_voucher.tax_amt = 0 
	LET l_rec_voucher.paid_amt = 0 
	LET l_rec_voucher.taken_disc_amt = 0 
	LET l_rec_voucher.paid_date = NULL 
	LET l_rec_voucher.jour_num = 0 
	LET l_rec_voucher.post_flag = "N" 
	LET l_rec_voucher.year_num = p_tax_year_num 
	LET l_rec_voucher.period_num = p_tax_period_num 
	IF glob_rec_apparms.vouch_approve_flag = "Y" THEN 
		LET l_rec_voucher.approved_code = 'N' 
	ELSE 
		LET l_rec_voucher.approved_code = 'Y' 
	END IF 
	LET l_rec_voucher.approved_date = NULL 
	LET l_rec_voucher.approved_by_code = NULL 
	LET l_rec_voucher.pay_seq_num = 0 
	LET l_rec_voucher.line_num = 0 
	LET l_rec_voucher.hold_code = l_rec_vendor.hold_code 
	LET l_rec_voucher.split_from_num = 0 
	LET l_rec_voucher.currency_code = l_rec_vendor.currency_code 
	IF l_rec_voucher.entry_code = 'AP' THEN 
		LET l_rec_voucher.com1_text = "AP Posting Run " 
		LET l_rec_voucher.com2_text = "On ", today 
	END IF 
	LET l_rec_voucher.source_ind = "4" 
	LET l_rec_voucher.withhold_tax_ind = "0" 
	INSERT INTO voucher VALUES (l_rec_voucher.*) 

	INITIALIZE l_rec_voucherdist.* TO NULL 
	LET l_rec_voucherdist.cmpy_code = p_cmpy 
	LET l_rec_voucherdist.vend_code = l_rec_voucher.vend_code 
	LET l_rec_voucherdist.vouch_code = l_rec_voucher.vouch_code 
	LET l_rec_voucherdist.line_num = 1 
	LET l_rec_voucherdist.type_ind = "G" 
	LET l_rec_voucherdist.acct_code = p_distribute_acct_code 
	LET l_rec_voucherdist.desc_text = "Automatic Tax Voucher Distribution" 
	LET l_rec_voucherdist.dist_amt = l_rec_voucher.total_amt 
	LET l_rec_voucherdist.dist_qty = 0 
	LET l_rec_voucherdist.var_code = 0 
	LET l_rec_voucherdist.po_num = 0 
	LET l_rec_voucherdist.po_line_num = 0 
	LET l_rec_voucherdist.trans_qty = 0 
	LET l_rec_voucherdist.cost_amt = 0 
	LET l_rec_voucherdist.charge_amt = 0 
	INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 

	LET l_rec_apaudit.cmpy_code = p_cmpy 
	LET l_rec_apaudit.tran_date = l_rec_voucher.vouch_date 
	LET l_rec_apaudit.vend_code = l_rec_voucher.vend_code 
	LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
	LET l_rec_apaudit.trantype_ind = "VO" 
	LET l_rec_apaudit.year_num = l_rec_voucher.year_num 
	LET l_rec_apaudit.period_num = l_rec_voucher.period_num 
	LET l_rec_apaudit.source_num = l_rec_voucher.vouch_code 
	LET l_rec_apaudit.tran_text = "Tax Voucher" 
	LET l_rec_apaudit.tran_amt = p_tax_amount 
	LET l_rec_apaudit.entry_code = l_rec_voucher.entry_code 
	LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
	LET l_rec_apaudit.currency_code = l_rec_voucher.currency_code 
	LET l_rec_apaudit.conv_qty = l_rec_voucher.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 

	RETURN l_rec_voucher.vouch_code 
END FUNCTION 


############################################################
# FUNCTION create_tax_debit(p_cmpy,
#                    p_kandoouser_sign_on_code,
#                    p_tax_vendor,
#          p_tax_amount,
#          p_distribute_acct_code,
#          p_tax_year_num,
#          p_tax_period_num)
#
#
#
############################################################
FUNCTION create_tax_debit(p_cmpy, 
	p_kandoouser_sign_on_code, 
	p_tax_vendor, 
	p_tax_amount, 
	p_distribute_acct_code, 
	p_tax_year_num, 
	p_tax_period_num) 

	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_tax_vendor LIKE vendor.vend_code 
	DEFINE p_tax_amount LIKE cheque.net_pay_amt 
	DEFINE p_distribute_acct_code LIKE vendortype.pay_acct_code 
	DEFINE p_tax_year_num LIKE period.year_num 
	DEFINE p_tax_period_num LIKE period.period_num 
	#DEFINE l_debit_amt LIKE debithead.total_amt #not used
	#DEFINE #pr_apparms RECORD LIKE apparms.*
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_update_error SMALLINT 

	INITIALIZE l_rec_apaudit.* TO NULL 
	INITIALIZE l_rec_debithead.* TO NULL 

	LET l_update_error = true 
	DECLARE c2_vendor CURSOR FOR 
	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE vendor.cmpy_code = p_cmpy 
	AND vendor.vend_code = p_tax_vendor 
	FOR UPDATE 
	FOREACH c2_vendor 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + p_tax_amount 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt + p_tax_amount 
		IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
			LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
		END IF 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		UPDATE vendor 
		SET bal_amt = l_rec_vendor.bal_amt, 
		curr_amt = l_rec_vendor.curr_amt, 
		highest_bal_amt = l_rec_vendor.highest_bal_amt, 
		next_seq_num = l_rec_vendor.next_seq_num 
		WHERE CURRENT OF c2_vendor 
		LET l_update_error = false 
	END FOREACH 

	IF l_update_error THEN 
		RETURN ("") 
	END IF 

	LET l_update_error = true 
	DECLARE c2_apparms CURSOR FOR 
	SELECT * 
	INTO glob_rec_apparms.* 
	FROM apparms 
	WHERE apparms.parm_code = "1" 
	AND apparms.cmpy_code = p_cmpy 
	FOR UPDATE 
	FOREACH c2_apparms 
		IF glob_rec_apparms.next_deb_num IS NULL THEN 
			LET glob_rec_apparms.next_deb_num = 1 
		END IF 
		LET l_rec_debithead.debit_num = glob_rec_apparms.next_deb_num 
		LET glob_rec_apparms.next_deb_num = glob_rec_apparms.next_deb_num + 1 
		UPDATE apparms 
		SET next_deb_num = glob_rec_apparms.next_deb_num 
		WHERE apparms.cmpy_code = p_cmpy 
		AND apparms.parm_code = "1" 
		LET l_update_error = false 
	END FOREACH 

	IF l_update_error THEN 
		RETURN ("") 
	END IF 

	CALL get_conv_rate(p_cmpy, 
	l_rec_vendor.currency_code, 
	today, 
	"B") 
	RETURNING l_rec_debithead.conv_qty 
	IF l_rec_debithead.conv_qty IS NULL OR l_rec_debithead.conv_qty = "" THEN 
		LET l_rec_debithead.conv_qty = 0 
	END IF 

	LET l_rec_debithead.cmpy_code = p_cmpy 
	LET l_rec_debithead.vend_code = p_tax_vendor 
	LET l_rec_debithead.rma_num = 0 
	LET l_rec_debithead.debit_date = today 
	LET l_rec_debithead.entry_date = today 
	LET l_rec_debithead.entry_code = p_kandoouser_sign_on_code 
	LET l_rec_debithead.contact_text = l_rec_vendor.contact_text 
	LET l_rec_debithead.tax_code = l_rec_vendor.tax_code 
	LET l_rec_debithead.total_amt = 0 - p_tax_amount 
	LET l_rec_debithead.goods_amt = l_rec_debithead.total_amt 
	LET l_rec_debithead.dist_amt = l_rec_debithead.total_amt 
	LET l_rec_debithead.dist_qty = 0 
	LET l_rec_debithead.tax_amt = 0 
	LET l_rec_debithead.apply_amt = 0 
	LET l_rec_debithead.disc_amt = 0 
	LET l_rec_debithead.jour_num = 0 
	LET l_rec_debithead.post_flag = "N" 
	LET l_rec_debithead.year_num = p_tax_year_num 
	LET l_rec_debithead.period_num = p_tax_period_num 
	LET l_rec_debithead.appl_seq_num = 0 
	LET l_rec_debithead.currency_code = l_rec_vendor.currency_code 
	IF l_rec_debithead.entry_code = 'AP' THEN 
		LET l_rec_debithead.com1_text = "AP Posting Run " 
		LET l_rec_debithead.com2_text = "On ", today 
	END IF 
	INSERT INTO debithead VALUES (l_rec_debithead.*) 

	INITIALIZE l_rec_debitdist.* TO NULL 
	LET l_rec_debitdist.cmpy_code = p_cmpy 
	LET l_rec_debitdist.vend_code = l_rec_debithead.vend_code 
	LET l_rec_debitdist.debit_code = l_rec_debithead.debit_num 
	LET l_rec_debitdist.line_num = 1 
	LET l_rec_debitdist.acct_code = p_distribute_acct_code 
	LET l_rec_debitdist.desc_text = "Automatic Tax Debit Distribution" 
	LET l_rec_debitdist.dist_amt = l_rec_debithead.total_amt 
	LET l_rec_debitdist.dist_qty = 0 
	INSERT INTO debitdist VALUES (l_rec_debitdist.*) 

	LET l_rec_apaudit.cmpy_code = p_cmpy 
	LET l_rec_apaudit.tran_date = l_rec_debithead.debit_date 
	LET l_rec_apaudit.vend_code = l_rec_debithead.vend_code 
	LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
	LET l_rec_apaudit.trantype_ind = "DB" 
	LET l_rec_apaudit.year_num = l_rec_debithead.year_num 
	LET l_rec_apaudit.period_num = l_rec_debithead.period_num 
	LET l_rec_apaudit.source_num = l_rec_debithead.debit_num 
	LET l_rec_apaudit.tran_text = "Tax Debit" 
	LET l_rec_apaudit.tran_amt = p_tax_amount 
	LET l_rec_apaudit.entry_code = l_rec_debithead.entry_code 
	LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
	LET l_rec_apaudit.currency_code = l_rec_debithead.currency_code 
	LET l_rec_apaudit.conv_qty = l_rec_debithead.conv_qty 
	LET l_rec_apaudit.entry_date = today 
	INSERT INTO apaudit VALUES (l_rec_apaudit.*) 

	RETURN l_rec_debithead.debit_num 
END FUNCTION 


