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

	Source code beautified by beautify.pl on 2020-01-02 10:35:45	$Id: $
}



#
#  wtaxwind.4gl (dispwtax)
#                FUNCTION displays payee cheque information related TO a
#                Tax Vendor voucher OR debit on form P203
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 



####################################################################
# FUNCTION dispwtax(p_cmpy,
#             p_tax_vend_code,
#             p_doc_type,
#             p_doc_code)
#
# Purpose - wtaxcalc calculates net AND tax amounts FOR the given
#           gross amount AND tax percentage, according TO the
#           nominated tax indicator method
#           0 = tax NOT applicable
#           1 = rounded TO two DECIMAL places
#           2 = rounded down TO nearest whole number
#           3 = rounded up TO nearest whole number
####################################################################
FUNCTION dispwtax(p_cmpy,p_tax_vend_code,p_doc_type,p_doc_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_tax_vend_code LIKE vendor.vend_code 
	DEFINE p_doc_type CHAR(1) 
	DEFINE p_doc_code LIKE voucher.vouch_code 
	DEFINE l_total_amt LIKE voucher.total_amt 
	DEFINE l_paid_amt LIKE voucher.paid_amt 
	DEFINE l_dist_amt LIKE voucher.dist_amt 
	DEFINE l_doc_date LIKE voucher.vouch_date 
	DEFINE l_doc_text CHAR(11) 
	DEFINE l_doc_prompt CHAR(21) 
	DEFINE l_amt_prompt CHAR(14) 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_wholdtax RECORD LIKE wholdtax.* 
	DEFINE l_arr_rec_meth DYNAMIC ARRAY OF #array[500] OF 
	RECORD 
		pay_meth_ind LIKE wholdtax.pay_meth_ind, 
		bank_code LIKE cheque.bank_code 
	END RECORD 
	DEFINE l_arr_rec_wholdtax DYNAMIC ARRAY OF #array[500] OF 
	RECORD 
		scroll_flag CHAR(1), 
		payee_ref_num LIKE wholdtax.payee_ref_num, 
		payee_vend_code LIKE wholdtax.payee_vend_code, 
		pay_amt LIKE cheque.pay_amt, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		tax_amt LIKE cheque.tax_amt, 
		cancel_flag CHAR(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag #not used 

	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = p_tax_vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9501,"") 
		#9501 Vendor NOT found
		RETURN 
	END IF 

	CASE p_doc_type 
		WHEN ("1") 
			SELECT * 
			INTO l_rec_voucher.* 
			FROM voucher 
			WHERE cmpy_code = p_cmpy 
			AND vouch_code = p_doc_code 
			IF STATUS = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9122,"") 
				#9122 Voucher NOT found
				RETURN 
			END IF 
			LET l_doc_text = "Tax Voucher" 
			LET l_doc_prompt = "Voucher Number......." 
			LET p_doc_code = l_rec_voucher.vouch_code 
			LET l_total_amt = l_rec_voucher.total_amt 
			LET l_amt_prompt = "Paid Amount..." 
			LET l_paid_amt = l_rec_voucher.paid_amt 
			LET l_dist_amt = l_rec_voucher.dist_amt 
			LET l_doc_date = l_rec_voucher.vouch_date 
		WHEN ("2") 
			SELECT * 
			INTO l_rec_debithead.* 
			FROM debithead 
			WHERE cmpy_code = p_cmpy 
			AND debit_num = p_doc_code 
			IF STATUS = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9501,"") 
				#9501 Debit NOT found
				RETURN 
			END IF 
			LET l_doc_text = " Tax Debit" 
			LET l_doc_prompt = "Debit Number........." 
			LET p_doc_code = l_rec_debithead.debit_num 
			LET l_total_amt = l_rec_debithead.total_amt 
			LET l_amt_prompt = "Apply Amount.." 
			LET l_paid_amt = l_rec_debithead.apply_amt 
			LET l_dist_amt = l_rec_debithead.dist_amt 
			LET l_doc_date = l_rec_debithead.debit_date 
	END CASE 

	DECLARE c_wholdtax CURSOR FOR 
	SELECT * FROM wholdtax 
	WHERE cmpy_code = p_cmpy 
	AND tax_vend_code = p_tax_vend_code 
	AND tax_tran_type = p_doc_type 
	AND tax_ref_num = p_doc_code 
	ORDER BY cmpy_code, 
	payee_ref_num 
	LET l_idx = 0 
	FOREACH c_wholdtax INTO l_rec_wholdtax.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_meth[l_idx].pay_meth_ind = l_rec_wholdtax.pay_meth_ind 
		LET l_arr_rec_meth[l_idx].bank_code = l_rec_wholdtax.payee_bank_code 
		LET l_arr_rec_wholdtax[l_idx].payee_ref_num = l_rec_wholdtax.payee_ref_num 
		LET l_arr_rec_wholdtax[l_idx].payee_vend_code = l_rec_wholdtax.payee_vend_code 
		IF l_rec_wholdtax.payee_tran_type = "1" THEN 
			SELECT pay_amt, 
			net_pay_amt, 
			tax_amt 
			INTO l_arr_rec_wholdtax[l_idx].pay_amt, 
			l_arr_rec_wholdtax[l_idx].net_pay_amt, 
			l_arr_rec_wholdtax[l_idx].tax_amt 
			FROM cheque 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_wholdtax.payee_vend_code 
			AND cheq_code = l_rec_wholdtax.payee_ref_num 
			AND bank_code = l_rec_wholdtax.payee_bank_code 
			AND pay_meth_ind = l_rec_wholdtax.pay_meth_ind 
			IF STATUS = NOTFOUND THEN 
				LET l_arr_rec_wholdtax[l_idx].pay_amt = NULL 
				LET l_arr_rec_wholdtax[l_idx].net_pay_amt = NULL 
				LET l_arr_rec_wholdtax[l_idx].tax_amt = NULL 
			END IF 
			LET l_arr_rec_wholdtax[l_idx].cancel_flag = NULL 
		ELSE 
			LET l_arr_rec_wholdtax[l_idx].pay_amt = NULL 
			LET l_arr_rec_wholdtax[l_idx].net_pay_amt = NULL 
			LET l_arr_rec_wholdtax[l_idx].tax_amt = NULL 
			DECLARE c_cancelcheq CURSOR FOR 
			SELECT pay_amt, 
			net_pay_amt, 
			tax_amt 
			FROM cancelcheq 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = l_rec_wholdtax.payee_vend_code 
			AND cheq_code = l_rec_wholdtax.payee_ref_num 
			AND bank_code = l_rec_wholdtax.payee_bank_code 
			FOREACH c_cancelcheq INTO l_arr_rec_wholdtax[l_idx].pay_amt, 
				l_arr_rec_wholdtax[l_idx].net_pay_amt, 
				l_arr_rec_wholdtax[l_idx].tax_amt 
				EXIT FOREACH 
			END FOREACH 
			LET l_arr_rec_wholdtax[l_idx].cancel_flag = "Y" 
		END IF 
		IF l_idx = 500 THEN 
			LET l_msgresp = kandoomsg("P",9120,500) 
			#9120 First 500 tax transactions selected FOR this document
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("P",9121,"") 
		#9121 No tax transactions exist FOR this document
		#Informix bug workaround
		INITIALIZE l_arr_rec_wholdtax[1].* TO NULL 
		RETURN 
	END IF 
	CALL set_count(l_idx) 

	CALL fgl_winmessage("HuHo Debug - Missing Form P203","Form P203 needs TO be created/fixed\nDebug this place AND adjust the form accordingly","error") 
	OPEN WINDOW p203 with FORM "P203" 
	CALL windecoration_p("P203") 

	DISPLAY 
	l_doc_text, 
	l_doc_prompt, 
	l_amt_prompt 
	TO 
	doc_text, 
	doc_prompt, 
	amt_prompt 

	DISPLAY BY NAME l_rec_vendor.vend_code, 
	l_rec_vendor.name_text 
	DISPLAY 
	p_doc_code, 
	l_total_amt, 
	l_paid_amt, 
	l_dist_amt, 
	l_doc_date 
	TO
	doc_code, 
	total_amt, 
	paid_amt, 
	dist_amt, 
	doc_date 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute(green) 
	LET l_msgresp = kandoomsg("P",1007,"") 
	#1007 F3/F4 - RETURN TO View
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY l_arr_rec_wholdtax WITHOUT DEFAULTS FROM sr_wholdtax.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wtaxwind","input-arr-wholdtax") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			##DISPLAY l_arr_rec_wholdtax[l_idx].* TO sr_wholdtax[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_wholdtax[l_idx].scroll_flag = NULL 
			#DISPLAY l_arr_rec_wholdtax[l_idx].* TO sr_wholdtax[scrn].*

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET l_msgresp = kandoomsg("P",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD payee_ref_num 
			IF l_arr_rec_wholdtax[l_idx].cancel_flag = "Y" THEN 
				LET l_msgresp = kandoomsg("P",9123,"") 
				#9123 Inquiry NOT available FOR cancelled cheques
			ELSE 
				#Bank code IS always NULL because we dont have the info
				CALL disp_ck_head(p_cmpy, 
				l_arr_rec_wholdtax[l_idx].payee_vend_code, 
				l_arr_rec_wholdtax[l_idx].payee_ref_num, 
				l_arr_rec_meth[l_idx].pay_meth_ind, 
				l_arr_rec_meth[l_idx].bank_code, 
				0) 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_wholdtax[l_idx].*
			#        TO sr_wholdtax[scrn].*



	END INPUT 

	CLOSE WINDOW p203 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 


