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

	Source code beautified by beautify.pl on 2020-01-02 10:35:38	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


####################################################################
# FUNCTION disp_vm_hist(p_cmpy_code, p_vend_code, p_hist_year, p_period)
#
# FUNCTION disp_vm_hist displays vendor history details
####################################################################
FUNCTION disp_vm_hist(p_cmpy_code,p_vend_code,p_hist_year,p_period) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_vend_code LIKE vendor.vend_code
	DEFINE p_hist_year LIKE vendorhist.year_num
	DEFINE p_period LIKE vendorhist.period_num
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendorhist RECORD LIKE vendorhist.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_av_purchase_amt LIKE vendorhist.purchase_amt 
	DEFINE l_av_payment_amt LIKE vendorhist.purchase_amt 
	DEFINE l_av_debit_amt LIKE vendorhist.purchase_amt 
	DEFINE l_av_disc_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_purchase_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_payment_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_debit_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_disc_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_av_purchase_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_av_payment_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_av_debit_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_av_disc_amt LIKE vendorhist.purchase_amt 
	DEFINE l_yr_purchase_num INTEGER 
	DEFINE l_yr_payment_num INTEGER 
	DEFINE l_yr_debit_num INTEGER 

	SELECT vendor.* INTO l_rec_vendor.* FROM vendor 
	WHERE vendor.vend_code = p_vend_code 
	AND vendor.cmpy_code = p_cmpy_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor") 
		#7001 Logic Error: Vendor RECORD does NOT exist
		RETURN 
	END IF 
	SELECT currency.* INTO l_rec_currency.* FROM currency 
	WHERE currency.currency_code = l_rec_vendor.currency_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Currency") 
		#7001 Logic Error: Currency RECORD does NOT exist
		RETURN 
	END IF 

	LET l_yr_purchase_amt = 0 
	LET l_yr_payment_amt = 0 
	LET l_yr_debit_amt = 0 
	LET l_yr_disc_amt = 0 
	LET l_yr_purchase_num = 0 
	LET l_yr_payment_num = 0 
	LET l_yr_debit_num = 0 

	DECLARE hist_curs CURSOR FOR 
	SELECT vendorhist.* INTO l_rec_vendorhist.* FROM vendorhist 
	WHERE vendorhist.vend_code = p_vend_code 
	AND vendorhist.cmpy_code = p_cmpy_code 
	AND vendorhist.year_num = p_hist_year 

	FOREACH hist_curs 
		LET l_yr_purchase_amt = l_yr_purchase_amt + l_rec_vendorhist.purchase_amt 
		LET l_yr_payment_amt = l_yr_payment_amt + l_rec_vendorhist.payment_amt 
		LET l_yr_debit_amt = l_yr_debit_amt + l_rec_vendorhist.debit_amt 
		LET l_yr_disc_amt = l_yr_disc_amt + l_rec_vendorhist.disc_amt 
		LET l_yr_purchase_num = l_yr_purchase_num + l_rec_vendorhist.purchase_num 
		LET l_yr_payment_num = l_yr_payment_num + l_rec_vendorhist.payment_num 
		LET l_yr_debit_num = l_yr_debit_num + l_rec_vendorhist.debit_num 
	END FOREACH 

	IF l_yr_purchase_num = 0 THEN 
		LET l_yr_av_purchase_amt = 0 
	ELSE 
		LET l_yr_av_purchase_amt = l_yr_purchase_amt / l_yr_purchase_num 
	END IF 
	IF l_yr_payment_num = 0 THEN 
		LET l_yr_av_payment_amt = 0 
	ELSE 
		LET l_yr_av_payment_amt = l_yr_payment_amt / l_yr_payment_num 
	END IF 
	IF l_yr_debit_num = 0 THEN 
		LET l_yr_av_debit_amt = 0 
	ELSE 
		LET l_yr_av_debit_amt = l_yr_debit_amt / l_yr_debit_num 
	END IF 
	IF l_yr_purchase_num = 0 THEN 
		LET l_yr_av_disc_amt = 0 
	ELSE 
		LET l_yr_av_disc_amt = l_yr_disc_amt / l_yr_purchase_num 
	END IF 
	SELECT vendorhist.* INTO l_rec_vendorhist.* FROM vendorhist 
	WHERE vendorhist.vend_code = p_vend_code 
	AND vendorhist.cmpy_code = p_cmpy_code 
	AND vendorhist.year_num = p_hist_year 
	AND vendorhist.period_num = p_period 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor History") 
		#7001 Logic Error: Vendor History RECORD does NOT exist
		RETURN 
	END IF 
	IF l_rec_vendorhist.purchase_num = 0 THEN 
		LET l_av_purchase_amt = 0 
	ELSE 
		LET l_av_purchase_amt = l_rec_vendorhist.purchase_amt 
		/ l_rec_vendorhist.purchase_num 
	END IF 
	IF l_rec_vendorhist.payment_num = 0 THEN 
		LET l_av_payment_amt = 0 
	ELSE 
		LET l_av_payment_amt = l_rec_vendorhist.payment_amt / l_rec_vendorhist.payment_num 
	END IF 
	IF l_rec_vendorhist.debit_num = 0 THEN 
		LET l_av_debit_amt = 0 
	ELSE 
		LET l_av_debit_amt = l_rec_vendorhist.debit_amt / l_rec_vendorhist.debit_num 
	END IF 
	IF l_rec_vendorhist.purchase_num = 0 THEN 
		LET l_av_disc_amt = 0 
	ELSE 
		LET l_av_disc_amt = l_rec_vendorhist.disc_amt / l_rec_vendorhist.purchase_num 
	END IF 

	OPEN WINDOW p108 with FORM "P108" 
	CALL windecoration_p("P108") -- albo kd-752 

	DISPLAY l_rec_vendorhist.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_vendorhist.year_num, 
	l_rec_vendorhist.period_num, 
	l_rec_vendor.currency_code, 
	l_rec_currency.desc_text, 
	l_rec_vendorhist.purchase_num, 
	l_rec_vendorhist.purchase_amt, 
	l_rec_vendorhist.debit_num, 
	l_rec_vendorhist.debit_amt, 
	l_rec_vendorhist.payment_num, 
	l_rec_vendorhist.payment_amt, 
	l_rec_vendorhist.disc_amt, 
	l_av_purchase_amt, 
	l_av_payment_amt, 
	l_av_debit_amt, 
	l_av_disc_amt, 
	l_yr_purchase_amt, 
	l_yr_payment_amt, 
	l_yr_debit_amt, 
	l_yr_disc_amt, 
	l_yr_av_purchase_amt, 
	l_yr_av_payment_amt, 
	l_yr_av_debit_amt, 
	l_yr_av_disc_amt, 
	l_yr_purchase_num, 
	l_yr_payment_num, 
	l_yr_debit_num 
	TO 
	vend_code, 
	name_text, 
	year_num, 
	period_num, 
	currency_code, 
	desc_text, 
	purchase_num, 
	purchase_amt, 
	debit_num, 
	debit_amt, 
	payment_num, 
	payment_amt, 
	disc_amt, 
	av_purchase_amt, 
	av_payment_amt, 
	av_debit_amt, 
	av_disc_amt, 
	yr_purchase_amt, 
	yr_payment_amt, 
	yr_debit_amt, 
	yr_disc_amt, 
	yr_av_purchase_amt, 
	yr_av_payment_amt, 
	yr_av_debit_amt, 
	yr_av_disc_amt, 
	yr_purchase_num, 
	yr_payment_num, 
	yr_debit_num 
	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")
	#1 Press Any Key TO Continue

	CLOSE WINDOW p108 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 



