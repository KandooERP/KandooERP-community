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
# FUNCTION disp_ck_head(p_cmpy_code, p_vend_pass, p_cheq_num, p_pay_meth, p_bank_pass, p_chq_amt)
#
# FUNCTION disp_ck_head displays cheque details
############################################################
FUNCTION disp_ck_head(p_cmpy_code, p_vend_pass, p_cheq_num, p_pay_meth, p_bank_pass, p_chq_amt) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_pass LIKE cheque.vend_code 
	DEFINE p_cheq_num LIKE cheque.cheq_code 
	DEFINE p_pay_meth LIKE cheque.pay_meth_ind 
	DEFINE p_bank_pass LIKE cheque.bank_code 
	DEFINE p_chq_amt LIKE cheque.net_pay_amt 
	DEFINE l_rec_cancelcheq RECORD LIKE cancelcheq.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_meth_text CHAR(25) 
	DEFINE l_date_pres LIKE bankstatement.tran_date 
	DEFINE l_recon_ind LIKE bankstatement.recon_ind 
	DEFINE l_disp_mess CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_disp_mess = NULL 
	# There IS a fundamental database defficiency here.  The bank_code IS NOT
	# lodged against the apaudit.  This makes it difficult TO drill down. if
	# the bank_code IS NOT passed, THEN lets get the first entry AND NOT crash
	# the program.  This situation IS unlikey TO occur, but IF it does, users
	# can use P46, OR P4E OR P48 OR even P45...
	IF p_bank_pass IS NOT NULL THEN 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE cmpy_code = p_cmpy_code 
		AND cheq_code = p_cheq_num 
		AND vend_code = p_vend_pass 
		AND pay_meth_ind = p_pay_meth 
		AND bank_code = p_bank_pass 
	ELSE 
		DECLARE c_cheque CURSOR FOR 
		SELECT * INTO l_rec_cheque.* FROM cheque 
		WHERE cmpy_code = p_cmpy_code 
		AND cheq_code = p_cheq_num 
		AND vend_code = p_vend_pass 
		AND pay_meth_ind = p_pay_meth 
		AND net_pay_amt = p_chq_amt 
		OPEN c_cheque 
		FETCH c_cheque INTO l_rec_cheque.* 
	END IF 
	IF status = notfound THEN 
		IF p_bank_pass IS NOT NULL THEN 
			SELECT * INTO l_rec_cancelcheq.* FROM cancelcheq 
			WHERE cmpy_code = p_cmpy_code 
			AND cheq_code = p_cheq_num 
			AND vend_code = p_vend_pass 
			AND bank_code = p_bank_pass 
		ELSE 
			DECLARE c_canccheque CURSOR FOR 
			SELECT * INTO l_rec_cancelcheq.* FROM cancelcheq 
			WHERE cmpy_code = p_cmpy_code 
			AND cheq_code = p_cheq_num 
			AND vend_code = p_vend_pass 
			AND (net_pay_amt = (p_chq_amt * -1) OR 
			net_pay_amt = p_chq_amt ) 
			OPEN c_canccheque 
			FETCH c_canccheque INTO l_rec_cancelcheq.* 
		END IF 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("P", 9130, "") 
			#9130 "Cheque Not Found"
			RETURN 
		ELSE 
			### Lets align cancelcheq AND cheque records###
			INITIALIZE l_rec_cheque.* TO NULL 
			LET l_rec_cheque.cmpy_code = l_rec_cancelcheq.cmpy_code 
			LET l_rec_cheque.vend_code = l_rec_cancelcheq.vend_code 
			LET l_rec_cheque.cheq_code = l_rec_cancelcheq.cheq_code 
			LET l_rec_cheque.entry_code = l_rec_cancelcheq.entry_code 
			LET l_rec_cheque.entry_date = l_rec_cancelcheq.entry_date 
			LET l_rec_cheque.bank_acct_code = l_rec_cancelcheq.bank_acct_code 
			LET l_rec_cheque.bank_code = l_rec_cancelcheq.bank_code 
			LET l_rec_cheque.cheq_date = l_rec_cancelcheq.cheq_date 
			LET l_rec_cheque.pay_amt = l_rec_cancelcheq.pay_amt 
			LET l_rec_cheque.currency_code = l_rec_cancelcheq.orig_curr_code 
			LET l_rec_cheque.disc_amt = 0 
			LET l_rec_cheque.apply_amt = 0 
			LET l_rec_cheque.net_pay_amt = l_rec_cancelcheq.net_pay_amt 
			LET l_rec_cheque.tax_code = l_rec_cancelcheq.tax_code 
			LET l_rec_cheque.tax_per = l_rec_cancelcheq.tax_per 
			LET l_rec_cheque.conv_qty = l_rec_cancelcheq.orig_conv_qty 
			LET l_rec_cheque.year_num = l_rec_cancelcheq.orig_year_num 
			LET l_rec_cheque.period_num = l_rec_cancelcheq.orig_period_num 
			LET l_rec_cheque.post_flag = l_rec_cancelcheq.orig_posted_flag 
			LET l_rec_cheque.com1_text = l_rec_cancelcheq.com1_text 
			LET l_rec_cheque.com2_text = l_rec_cancelcheq.com2_text 
			LET l_rec_cheque.tax_amt = l_rec_cancelcheq.tax_amt 
			LET l_rec_cheque.contra_amt = l_rec_cancelcheq.contra_amt 
			LET l_disp_mess = " ****CANCELLED CHEQUE**** " 
		END IF 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vend_code = l_rec_cheque.vend_code 
	AND cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("P", 9501, "") 
		#9501 Vendor NOT Found
		RETURN 
	END IF 
	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE cmpy_code = p_cmpy_code 
	AND acct_code = l_rec_cheque.bank_acct_code 

	OPEN WINDOW wp132 with FORM "P132" 
	CALL windecoration_p("P132") 

	DISPLAY BY NAME l_rec_cheque.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_bank.bank_code, 
	l_rec_cheque.cheq_code, 
	l_rec_cheque.pay_meth_ind, 
	l_rec_cheque.entry_code, 
	l_rec_cheque.entry_date, 
	l_rec_cheque.bank_acct_code, 
	l_rec_cheque.com3_text, 
	l_rec_cheque.cheq_date, 
	l_rec_bank.name_acct_text, 
	l_rec_bank.iban, 
	l_rec_cheque.pay_amt, 
	l_rec_cheque.tax_amt, 
	l_rec_cheque.contra_amt, 
	l_rec_cheque.net_pay_amt, 
	l_rec_cheque.tax_code, 
	l_rec_cheque.tax_per, 
	l_rec_cheque.conv_qty, 
	l_rec_cheque.year_num, 
	l_rec_cheque.period_num, 
	l_rec_cheque.apply_amt, 
	l_rec_cheque.post_flag, 
	l_rec_cheque.disc_amt, 
	l_rec_cheque.rec_state_num, 
	l_rec_cheque.rec_line_num, 
	l_rec_cheque.com1_text, 
	l_rec_cheque.com2_text 

	LET l_meth_text = "" 
	IF l_rec_cheque.pay_meth_ind = "1" THEN 
		LET l_meth_text = "Auto/Manual Cheques" 
	ELSE 
		IF l_rec_cheque.pay_meth_ind = "3" THEN 
			LET l_meth_text = "EFT Payments " 
		ELSE 
			LET l_meth_text = "Direct Payment " 
		END IF 
	END IF 
	DISPLAY l_meth_text TO pay_meth_text 

	DISPLAY BY NAME l_rec_cheque.currency_code 
	attribute (green) 
	IF l_disp_mess IS NOT NULL THEN 
		MESSAGE l_disp_mess --DISPLAY l_disp_mess at 6,41 
		attribute(magenta) 
	END IF 

	IF l_rec_cheque.rec_state_num IS NOT NULL THEN 
		SELECT tran_date, recon_ind INTO l_date_pres, l_recon_ind 
		FROM bankstatement 
		WHERE bank_code = l_rec_cheque.bank_code 
		AND sheet_num = l_rec_cheque.rec_state_num 
		AND seq_num = l_rec_cheque.rec_line_num 
		AND cmpy_code = p_cmpy_code 
		IF NOT status THEN 
			DISPLAY l_date_pres TO date_presented 

			IF l_recon_ind <> "2" THEN 
				DISPLAY "*" TO close_flag 

			END IF 
		END IF 
	END IF 

	IF l_rec_cheque.apply_amt != 0 THEN 
		LET l_msgresp = kandoomsg("P",8003,"") 
		#8003 View cheque applications ? (Y/N)
		IF l_msgresp = "Y" THEN 
			CALL cheq_appl(p_cmpy_code, 
			l_rec_cheque.cheq_code, 
			l_rec_cheque.bank_acct_code, 
			l_rec_cheque.vend_code, 
			l_rec_cheque.pay_meth_ind) 
		END IF 
	ELSE 
		CALL eventsuspend() 
		#LET l_msgresp = kandoomsg("U",1,"")
		#2 Any Key TO Continue
	END IF 

	CLOSE WINDOW wp132 
	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 


