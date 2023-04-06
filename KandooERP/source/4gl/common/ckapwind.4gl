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

	Source code beautified by beautify.pl on 2020-01-02 10:35:08	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION cheq_appl(p_cmpy_code, p_cheqnum, p_bankacct, p_vendor, p_pay_meth)
#
# cheq_appl shows WHERE the cheque IS applied (i.e. which vouchers)
############################################################
FUNCTION cheq_appl(p_cmpy_code, p_cheqnum, p_bankacct, p_vendor, p_pay_meth) 
	DEFINE p_cmpy_code LIKE cheque.cmpy_code 
	DEFINE p_cheqnum LIKE cheque.cheq_code 
	DEFINE p_bankacct LIKE cheque.bank_acct_code 
	DEFINE p_vendor LIKE cheque.vend_code 
	DEFINE p_pay_meth LIKE cheque.pay_meth_ind 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_arr_rec_cheq DYNAMIC ARRAY OF #array[400] OF 
	RECORD 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cmpy_code = p_cmpy_code 
	AND cheq_code = p_cheqnum 
	AND bank_acct_code = p_bankacct 
	AND vend_code = p_vendor 
	AND pay_meth_ind = p_pay_meth 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("P",9130,"") 
		#9130 Cheque NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_cheque.vend_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("P",9060,l_rec_cheque.vend_code) 
		#9060 "Vendor XXXX NOT found "
		RETURN 
	END IF 

	OPEN WINDOW wp138 with FORM "P138" 
	CALL windecoration_p("P138") 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute (green) 
	DISPLAY BY NAME l_rec_cheque.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_cheque.cheq_code, 
	l_rec_cheque.pay_amt, 
	l_rec_cheque.apply_amt, 
	l_rec_cheque.net_pay_amt, 
	l_rec_cheque.cheq_date 


	DECLARE vo_curs CURSOR FOR 
	SELECT * INTO l_rec_voucherpays.* FROM voucherpays 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = l_rec_cheque.vend_code 
	AND pay_num = l_rec_cheque.cheq_code 
	AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
	AND pay_type_code = "CH" 
	AND (bank_code = l_rec_cheque.bank_code OR bank_code IS null) 
	ORDER BY vouch_code,apply_num 

	LET l_idx = 0 
	FOREACH vo_curs INTO l_rec_voucherpays.* 
		SELECT * INTO l_rec_voucher.* FROM voucher 
		WHERE cmpy_code = p_cmpy_code AND 
		vouch_code = l_rec_voucherpays.vouch_code AND 
		vend_code = l_rec_voucherpays.vend_code 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cheq[l_idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_rec_cheq[l_idx].inv_text = l_rec_voucher.inv_text 
		LET l_arr_rec_cheq[l_idx].apply_amt = l_rec_voucherpays.apply_amt 
		LET l_arr_rec_cheq[l_idx].disc_amt = l_rec_voucherpays.disc_amt 
		LET l_arr_rec_cheq[l_idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_rec_cheq[l_idx].paid_amt = l_rec_voucher.paid_amt 
		IF l_idx = 300 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected only
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1008,"") 

	#1008  F3/F4 - ESC TO Continue
	DISPLAY ARRAY l_arr_rec_cheq TO sr_cheq.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cinwind","display-arr-cheq") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW wp138 

END FUNCTION 



