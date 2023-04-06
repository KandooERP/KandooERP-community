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

	Source code beautified by beautify.pl on 2020-01-02 10:35:39	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


####################################################################
# FUNCTION display_voucher_header(p_cmpy_code, p_vouch_num)
#
# FUNCTION display_voucher_header displays the voucher header
####################################################################
FUNCTION display_voucher_header(p_cmpy_code,p_vouch_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vouch_num LIKE voucher.vouch_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_owing_amt LIKE voucher.total_amt 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_pptax_amt LIKE voucher.total_amt 
	DEFINE l_withhold_tax_ind LIKE cheque.withhold_tax_ind 
	DEFINE l_tax_code LIKE cheque.tax_code 
	DEFINE l_tax_per LIKE cheque.tax_per 
	DEFINE l_net_pay_amt LIKE voucher.total_amt 

	SELECT * INTO l_rec_voucher.* 
	FROM voucher 
	WHERE voucher.cmpy_code = p_cmpy_code 
	AND voucher.vouch_code = p_vouch_num 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9022,"") 
		#9022 Logic error: Voucher does NOT exist
		RETURN 
	END IF 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vend_code = l_rec_voucher.vend_code 
	AND cmpy_code = p_cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9022,"") 
		#9014 Logic error: Vendor does NOT exist
		RETURN 
	END IF 

	OPEN WINDOW p120 with FORM "P120" 
	CALL windecoration_p("P120") 

	SELECT desc_text 
	INTO l_rec_tax.desc_text 
	FROM tax 
	WHERE cmpy_code = p_cmpy_code 
	AND tax_code = l_rec_voucher.tax_code 

	SELECT desc_text 
	INTO l_rec_term.desc_text 
	FROM term 
	WHERE cmpy_code = p_cmpy_code 
	AND term_code = l_rec_voucher.term_code 

	SELECT hold_text 
	INTO l_rec_holdpay.hold_text 
	FROM holdpay 
	WHERE cmpy_code = p_cmpy_code 
	AND hold_code = l_rec_voucher.hold_code 

	LET l_owing_amt = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 

	IF l_rec_voucher.withhold_tax_ind != 0 THEN 
		IF l_owing_amt = 0 THEN 
			SELECT sum((apply_amt * tax_per) / 100) INTO l_rec_pptax_amt 
			FROM voucherpays 
			WHERE cmpy_code = p_cmpy_code 
			AND vend_code = l_rec_voucher.vend_code 
			AND vouch_code = l_rec_voucher.vouch_code 
		ELSE 
			CALL get_whold_tax(p_cmpy_code,l_rec_voucher.vend_code,l_rec_vendor.type_code) 
			RETURNING l_withhold_tax_ind, l_tax_code, l_tax_per 
			CALL wtaxcalc(l_owing_amt,l_tax_per,l_withhold_tax_ind, p_cmpy_code) 
			RETURNING l_net_pay_amt, l_rec_pptax_amt 
		END IF 

	ELSE 

		LET l_rec_pptax_amt = NULL 

	END IF 

	DISPLAY BY NAME l_rec_voucher.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_voucher.vouch_code, 
	l_rec_voucher.batch_num, 
	l_rec_vendor.currency_code, 
	l_rec_voucher.inv_text, 
	l_rec_voucher.vouch_date, 
	l_rec_voucher.due_date, 
	l_rec_voucher.term_code, 
	l_rec_voucher.tax_code, 
	l_rec_voucher.hold_code, 
	l_rec_holdpay.hold_text, 
	l_rec_voucher.total_amt, 
	l_rec_voucher.dist_amt, 
	l_rec_voucher.paid_amt, 
	l_rec_voucher.conv_qty, 
	l_rec_voucher.withhold_tax_ind, 
	l_rec_voucher.paid_date, 
	l_rec_voucher.disc_date, 
	l_rec_voucher.taken_disc_amt, 
	l_rec_voucher.poss_disc_amt, 
	l_rec_voucher.post_flag, 
	l_rec_voucher.year_num, 
	l_rec_voucher.period_num, 
	l_rec_voucher.entry_code, 
	l_rec_voucher.entry_date, 
	l_rec_voucher.com1_text, 
	l_rec_voucher.com2_text ,
	l_rec_vendor.currency_code
	
	DISPLAY l_owing_amt, 
		l_rec_pptax_amt, 
		l_rec_tax.desc_text, 
		l_rec_term.desc_text 
	TO owing_amt, 
		pptax_amt, 
		tax.desc_text, 
		term.desc_text 

	MENU " Voucher Information" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","vohdwind","menu-voucher-information") 

			IF l_rec_voucher.dist_amt = 0 THEN 
				HIDE option "Distributions" 
			END IF 

			IF l_rec_voucher.paid_amt = 0 THEN 
				HIDE option "Payments" 
			END IF 

			IF NOT (l_rec_voucher.split_from_num > 0) THEN 
				HIDE option "Transfers" 
			END IF 

			SELECT unique 1 
			FROM wholdtax 
			WHERE cmpy_code = p_cmpy_code 
			AND tax_vend_code = l_rec_voucher.vend_code 
			AND tax_tran_type = "1" 
			AND tax_ref_num = l_rec_voucher.vouch_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				HIDE option "Tax" 
			END IF 

			IF l_rec_voucher.source_ind = "S" THEN 
				SELECT * INTO l_rec_vouchpayee.* 
				FROM vouchpayee 
				WHERE vend_code = l_rec_voucher.vend_code 
				AND vouch_code = l_rec_voucher.vouch_code 
				AND cmpy_code = p_cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					HIDE option "Payee" 
				END IF 
			ELSE 
				HIDE option "Payee" 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Distributions" " View voucher distributions" 
			CALL disp_dist_amt(p_cmpy_code,l_rec_voucher.vouch_code) 

		COMMAND "Payments" " View voucher payment details" 
			CALL disp_vo_pay(p_cmpy_code,l_rec_voucher.vend_code,l_rec_voucher.vouch_code) 

		COMMAND "Transfers" " View voucher transfers" 
			CALL disp_splits(p_cmpy_code,l_rec_voucher.vend_code, l_rec_voucher.vouch_code) 

		COMMAND "Tax" " View tax transactions" 
			CALL dispwtax(p_cmpy_code,l_rec_voucher.vend_code,"1",l_rec_voucher.vouch_code) 

		COMMAND "Payee" " View voucher payee details" 
			CALL disp_payee_det(l_rec_vouchpayee.*) 

		COMMAND KEY(interrupt,"E")"Exit" " Exit FROM menu" 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END MENU 

	CLOSE WINDOW p120 

END FUNCTION 


####################################################################
# FUNCTION disp_payee_det(p_rec_vouchpayee)
#
# FUNCTION: disp_payee_det
# Description: Displays the sundry voucher payee details.
# Note:        A copy of the same FUNCTION IS in "P25" & "P45"
#               - (TO save heaps of makefile changes)
####################################################################
FUNCTION disp_payee_det(p_rec_vouchpayee) 
	DEFINE p_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(13) 
	DEFINE l_method_text CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_bic_text = p_rec_vouchpayee.bank_acct_code[1,6] 
	LET l_acct_text = p_rec_vouchpayee.bank_acct_code[8,20] 
	LET l_method_text 
	= kandooword("vendor.pay_meth_ind",p_rec_vouchpayee.pay_meth_ind) 

	OPEN WINDOW p515 with FORM "P515" 
	CALL windecoration_p("P515") 

	DISPLAY BY NAME p_rec_vouchpayee.name_text, 
	p_rec_vouchpayee.addr1_text, 
	p_rec_vouchpayee.addr2_text, 
	p_rec_vouchpayee.addr3_text, 
	p_rec_vouchpayee.city_text, 
	p_rec_vouchpayee.state_code, 
	p_rec_vouchpayee.post_code, 
	p_rec_vouchpayee.country_code,--@db-patch_2020_10_04-- 
	p_rec_vouchpayee.pay_meth_ind 
   DISPLAY 
	l_method_text, 
	l_bic_text, 
	l_acct_text
	TO 
	method_text, 
	bic_text, 
	acct_text

	LET l_msgresp = kandoomsg("U",2,"") 
	# Any Key TO Continue
	CLOSE WINDOW p515 

END FUNCTION 


