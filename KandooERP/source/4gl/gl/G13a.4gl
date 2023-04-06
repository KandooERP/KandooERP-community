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

	Source code beautified by beautify.pl on 2020-01-03 14:28:27	Source code beautified by beautify.pl on 2019-11-01 09:53:15	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G13 provides Account/detail inquiry facilites FOR foreign
#             AND reporting currencies

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION select_currency(p_cmpy, p_last_currency)
#
#
############################################################
FUNCTION select_currency(p_cmpy, p_last_currency) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_last_currency LIKE currency.currency_code 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("G",3513,"") 
	#3513 Enter Currency Detail - OK TO Continue
	LET l_rec_currency.currency_code = p_last_currency 

	INPUT l_rec_currency.currency_code WITHOUT DEFAULTS FROM currency_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G13a","input-currency") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

					
		ON ACTION "LOOKUP"  infield(currency_code) 
			LET l_rec_currency.currency_code = show_curr(p_cmpy) 
			DISPLAY l_rec_currency.currency_code TO currency_code

			NEXT FIELD currency_code 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				LET l_rec_currency.currency_code = p_last_currency 
				EXIT INPUT 
			END IF 

			SELECT * INTO l_rec_currency.* FROM currency 
			WHERE currency_code = l_rec_currency.currency_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9505,"") 
				# 9505 Currency NOT found - Try Window
				NEXT FIELD currency_code 
			ELSE 
				DISPLAY l_rec_currency.desc_text TO currency.desc_text 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	RETURN l_rec_currency.currency_code 
END FUNCTION 


############################################################
# FUNCTION get_and_disp_acctcurr_rec(p_cmpy, p_acct, p_acc_year, p_curr_code)
#
#
############################################################
FUNCTION get_and_disp_acctcurr_rec(p_cmpy, p_acct, p_acc_year, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE account.acct_code 
	DEFINE p_acc_year LIKE account.year_num 
	DEFINE p_curr_code LIKE currency.currency_code 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		RETURN 
	END IF 

	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE coa.acct_code = p_acct 
	AND coa.cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9210,"") 
		#9210 COA NOT SET up
		RETURN 
	END IF 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		RETURN 
	END IF 

	SELECT * INTO l_rec_account.* FROM account 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9031,"") 
		# Account Code NOT found
		RETURN 
	END IF 

	SELECT * INTO l_rec_currency.* FROM currency 
	WHERE currency_code = p_curr_code 
	IF status = NOTFOUND THEN 
		LET l_rec_currency.desc_text = " " 
	END IF 

	SELECT accountcur.* INTO l_rec_accountcur.* FROM accountcur 
	WHERE accountcur.acct_code = p_acct 
	AND accountcur.cmpy_code = p_cmpy 
	AND accountcur.year_num = p_acc_year 
	AND accountcur.currency_code = p_curr_code 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9007,"") 
		RETURN 
	ELSE 
		CALL show_accountcur(l_rec_account.*, 
		l_rec_company.name_text, 
		l_rec_coa.desc_text, 
		l_rec_currency.currency_code, 
		l_rec_currency.desc_text, 
		l_rec_glparms.base_currency_code, 
		l_rec_accountcur.*) 
	END IF 
END FUNCTION 


############################################################
# FUNCTION get_cmpy_and_parms_detl(p_cmpy)
#
#
############################################################
FUNCTION get_cmpy_and_parms_detl(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		INITIALIZE l_rec_company.* TO NULL 
		INITIALIZE l_rec_glparms.* TO NULL 
		RETURN l_rec_company.name_text, l_rec_glparms.base_currency_code 
	END IF 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		INITIALIZE l_rec_company.* TO NULL 
		INITIALIZE l_rec_glparms.* TO NULL 
		RETURN l_rec_company.name_text, l_rec_glparms.base_currency_code 
	END IF 
	RETURN l_rec_company.name_text, 
	l_rec_glparms.base_currency_code 
END FUNCTION 


############################################################
# FUNCTION show_account(p_rec_account,
#                      p_cmpy_name_text,
#                      p_coa_desc_text,
#                      p_base_curr_code)
#
#
############################################################
FUNCTION show_account(p_rec_account, 
	p_cmpy_name_text, 
	p_coa_desc_text, 
	p_base_curr_code) 

	DEFINE p_rec_account RECORD LIKE account.* 
	DEFINE p_cmpy_name_text LIKE company.name_text 
	DEFINE p_coa_desc_text LIKE coa.desc_text 
	DEFINE p_base_curr_code LIKE glparms.base_currency_code 

	DISPLAY p_rec_account.cmpy_code TO account.cmpy_code 
	DISPLAY p_cmpy_name_text TO company.name_text 
	DISPLAY p_rec_account.acct_code TO account.acct_code 
	DISPLAY p_coa_desc_text TO coa.desc_text 
	DISPLAY p_rec_account.year_num TO year_num 
	DISPLAY " " TO currency_code 
	DISPLAY " " TO currency.desc_text 
	DISPLAY p_base_curr_code TO base_currency_code 
	DISPLAY p_rec_account.open_amt TO base_open_amt 
	DISPLAY p_rec_account.bal_amt TO base_bal_amt 
	DISPLAY p_rec_account.debit_amt TO base_debit_amt 
	DISPLAY p_rec_account.credit_amt TO base_credit_amt 
	DISPLAY " " TO currency_code 
	DISPLAY " " TO open_amt 
	DISPLAY " " TO bal_amt 
	DISPLAY " " TO debit_amt 
	DISPLAY " " TO credit_amt 

END FUNCTION 


############################################################
# FUNCTION show_accountcur(p_rec_account,
#                          p_cmpy_name_text,
#                          p_coa_desc_text,
#                          p_curr_code,
#                          p_curr_desc_text,
#                          p_base_curr_code,
#                          p_rec_accountcur)
#
#
############################################################
FUNCTION show_accountcur(p_rec_account, 
	p_cmpy_name_text, 
	p_coa_desc_text, 
	p_curr_code, 
	p_curr_desc_text, 
	p_base_curr_code, 
	p_rec_accountcur) 

	DEFINE p_rec_account RECORD LIKE account.* 
	DEFINE p_cmpy_name_text LIKE company.name_text 
	DEFINE p_coa_desc_text LIKE coa.desc_text 
	DEFINE p_curr_code LIKE currency.currency_code 
	DEFINE p_curr_desc_text LIKE currency.desc_text 
	DEFINE p_base_curr_code LIKE glparms.base_currency_code 
	DEFINE p_rec_accountcur RECORD LIKE accountcur.* 

	DISPLAY p_rec_account.cmpy_code, 
	p_cmpy_name_text, 
	p_rec_account.acct_code, 
	p_coa_desc_text, 
	p_rec_account.year_num, 
	p_curr_code, 
	p_curr_desc_text, 
	p_base_curr_code, 
	p_rec_accountcur.base_open_amt, 
	p_rec_accountcur.base_bal_amt, 
	p_rec_accountcur.base_debit_amt, 
	p_rec_accountcur.base_credit_amt, 
	p_rec_accountcur.currency_code, 
	p_rec_accountcur.open_amt, 
	p_rec_accountcur.bal_amt, 
	p_rec_accountcur.debit_amt, 
	p_rec_accountcur.credit_amt 
	TO account.cmpy_code, 
	company.name_text, 
	account.acct_code, 
	coa.desc_text, 
	account.year_num, 
	formonly.currency_code, 
	currency.desc_text, 
	glparms.base_currency_code, 
	accountcur.base_open_amt, 
	accountcur.base_bal_amt, 
	accountcur.base_debit_amt, 
	accountcur.base_credit_amt, 
	accountcur.currency_code, 
	accountcur.open_amt, 
	accountcur.bal_amt, 
	accountcur.debit_amt, 
	accountcur.credit_amt 

END FUNCTION 


