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

	Source code beautified by beautify.pl on 2020-01-03 14:28:28	Source code beautified by beautify.pl on 2019-11-01 09:53:16	$Id: $
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
# FUNCTION disp_base_curr_acct_sum(p_cmpy, p_acct, p_acc_year, p_curr_code)
#
#
############################################################
FUNCTION disp_base_curr_acct_sum(p_cmpy, p_acct, p_acc_year, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE account.acct_code 
	DEFINE p_acc_year LIKE account.year_num 
	DEFINE p_curr_code LIKE currency.currency_code #not used, but an FUNCTION argument 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_account RECORD LIKE account.* 
	DEFINE l_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_accountcur DYNAMIC ARRAY OF RECORD # array[250] OF RECORD 
		currency_code LIKE accountcur.currency_code, 
		base_debit_amt LIKE accountcur.base_debit_amt, 
		base_credit_amt LIKE accountcur.base_credit_amt, 
		base_bal_amt LIKE accountcur.base_bal_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_size SMALLINT 

	OPEN WINDOW wg203 with FORM "G203" 
	CALL windecoration_g("G203") 

	SELECT * 
	INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		CLOSE WINDOW wg203 
		RETURN " " 
	END IF 

	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE coa.acct_code = p_acct 
	AND coa.cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9210,"") 
		CLOSE WINDOW wg203 
		RETURN " " 
	END IF 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		CLOSE WINDOW wg203 
		RETURN " " 
	END IF 

	SELECT * INTO l_rec_account.* FROM account 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9031,"") 
		CLOSE WINDOW wg203 
		RETURN " " 
	END IF 

	DISPLAY p_cmpy, 
	l_rec_company.name_text, 
	p_acct, 
	l_rec_coa.desc_text, 
	p_acc_year, 
	l_rec_account.open_amt, 
	l_rec_account.bal_amt, 
	l_rec_account.debit_amt, 
	l_rec_account.credit_amt, 
	l_rec_glparms.base_currency_code 
	TO account.cmpy_code, 
	company.name_text, 
	account.acct_code, 
	coa.desc_text, 
	account.year_num, 
	account.open_amt, 
	account.bal_amt, 
	account.debit_amt, 
	account.credit_amt, 
	glparms.base_currency_code 


	DECLARE basecurracct CURSOR FOR 
	SELECT * 
	INTO l_rec_accountcur.* 
	FROM accountcur 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_acct 
	AND year_num = p_acc_year 

	LET l_idx = 0 
	FOREACH basecurracct 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_accountcur[l_idx].currency_code = 
		l_rec_accountcur.currency_code 
		LET l_arr_rec_accountcur[l_idx].base_debit_amt = 
		l_rec_accountcur.base_debit_amt 
		LET l_arr_rec_accountcur[l_idx].base_credit_amt = 
		l_rec_accountcur.base_credit_amt 
		LET l_arr_rec_accountcur[l_idx].base_bal_amt = 
		l_rec_accountcur.base_bal_amt 
		IF l_idx > 249 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_arr_size = l_idx 

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("U",9101,"") 
		CLOSE WINDOW wg203 
		RETURN " " 
	END IF 

	CALL set_count (l_idx) 

	LET l_msgresp = kandoomsg("G",1007,"") 
	INPUT ARRAY l_arr_rec_accountcur WITHOUT DEFAULTS FROM sr_accountcur.* attributes(unbuffered) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_accountcur.currency_code = 
			l_arr_rec_accountcur[l_idx].currency_code 
			IF l_idx > l_arr_size THEN 
				LET l_msgresp = kandoomsg("G",9001,"") 
			END IF 

		AFTER FIELD currency_code 
			LET l_arr_rec_accountcur[l_idx].currency_code = 
			l_rec_accountcur.currency_code 
			#DISPLAY l_arr_rec_accountcur[l_idx].* TO sr_accountcur[scrn].*


		BEFORE FIELD base_debit_amt 
			IF l_arr_rec_accountcur[l_idx].currency_code IS NULL THEN 
				LET l_msgresp = kandoomsg("R",9002,"") 
				NEXT FIELD currency_code 
			END IF 
			LET l_rec_accountcur.currency_code = 
			l_arr_rec_accountcur[l_idx].currency_code 
			EXIT INPUT 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = 0 
				LET quit_flag = 0 
				LET l_rec_accountcur.currency_code = NULL 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW wg203 
	RETURN l_rec_accountcur.currency_code 

END FUNCTION 


