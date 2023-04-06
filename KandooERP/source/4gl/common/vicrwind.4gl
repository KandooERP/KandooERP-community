
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

#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###################################################
# FUNCTION vinq_cred(p_cmpy_code,p_vend_code)
#
# \brief module - vicrwind.4gl Displays vendor credit STATUS details
###################################################
FUNCTION vinq_cred(p_cmpy_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_avail_cred_amt LIKE vendor.bal_amt 

	SELECT * INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 

	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014 Logic Error: Vendor NOT found
		RETURN 
	END IF 

	OPEN WINDOW wp103 with FORM "P103" 
	CALL windecoration_p("P103") 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	DISPLAY db_currency_get_desc_text(UI_OFF,l_rec_vendor.currency_code) TO currency.desc_text
	#ATTRIBUTE(green)
	DISPLAY l_rec_vendor.bal_amt, 
	l_rec_vendor.bal_amt 
	TO sr_vendor[1].bal_amt, 
	sr_vendor[2].bal_amt 

	LET l_avail_cred_amt = l_rec_vendor.limit_amt 
	- l_rec_vendor.onorder_amt 
	- l_rec_vendor.bal_amt 

	IF l_rec_vendor.hold_code IS NOT NULL THEN 
		SELECT * INTO l_rec_holdpay.* 
		FROM holdpay 
		WHERE cmpy_code = l_rec_vendor.cmpy_code 
		AND hold_code = l_rec_vendor.hold_code 
	END IF 

	IF l_rec_vendor.usual_acct_code IS NOT NULL THEN 
		SELECT * INTO l_rec_coa.* 
		FROM coa 
		WHERE cmpy_code = l_rec_vendor.cmpy_code 
		AND acct_code = l_rec_vendor.usual_acct_code 
	END IF 

	DISPLAY 
	l_rec_vendor.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_vendor.hold_code, 
	l_rec_holdpay.hold_text, 
	l_rec_vendor.def_exp_ind, 
	l_rec_vendor.usual_acct_code, 
	l_rec_coa.desc_text, 
	l_rec_vendor.curr_amt, 
	l_rec_vendor.over1_amt, 
	l_rec_vendor.over30_amt, 
	l_rec_vendor.over60_amt, 
	l_rec_vendor.over90_amt, 
	l_rec_vendor.bal_amt, 
	l_rec_vendor.limit_amt, 
	l_rec_vendor.onorder_amt, 
	l_avail_cred_amt, 
	l_rec_vendor.highest_bal_amt, 
	l_rec_vendor.ytd_amt, 
	l_rec_vendor.avg_day_paid_num, 
	l_rec_vendor.setup_date, 
	l_rec_vendor.last_payment_date, 
	l_rec_vendor.last_po_date, 
	l_rec_vendor.last_vouc_date, 
	l_rec_vendor.last_debit_date 
	TO 
	vend_code, 
	name_text, 
	hold_code, 
	hold_text, 
	def_exp_ind, 
	usual_acct_code, 
	desc_text, 
	curr_amt, 
	over1_amt, 
	over30_amt, 
	over60_amt, 
	over90_amt, 
	bal_amt, 
	limit_amt, 
	onorder_amt, 
	avail_cred_amt, 
	highest_bal_amt, 
	ytd_amt, 
	avg_day_paid_num, 
	setup_date, 
	last_payment_date, 
	last_po_date, 
	last_vouc_date, 
	last_debit_date 

	CALL donePrompt(NULL,NULL,"ACCEPT") 
	#LET l_msgresp=kandoomsg("U",1,"")
	#1 Any Key TO Continue

	CLOSE WINDOW wp103 

END FUNCTION 


