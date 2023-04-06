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
# FUNCTION ac_hist_scan(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code)
#
#
############################################################
FUNCTION ac_hist_scan(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 
	DEFINE p_curr_code LIKE currency.currency_code 
	--DEFINE l_rec_coa RECORD LIKE coa.* 
	--DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg197 with FORM "G197" 
	CALL windecoration_g("G197") 

	CALL get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
	MENU " Account ledger" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","G13b","menu-account-ledger") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Previous period" 
			#      COMMAND "Prior period" " SELECT details FOR the previous period"
			CALL change_period(p_cmpy, p_acc_year, p_per, -1) 
			RETURNING p_acc_year, p_per 
			CALL get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
			NEXT option "Previous period" 

		ON ACTION "Next period" 
			#COMMAND "Next period" " SELECT details FOR the next period"
			CALL change_period(p_cmpy, p_acc_year, p_per, 1) 
			RETURNING p_acc_year, p_per 
			CALL get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
			NEXT option "Next period" 

		ON ACTION "Detail" 
			#COMMAND KEY ("D",f20) "Detail" " View account details"
			CALL ledg_detl(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 

		ON ACTION "Summary" 
			#COMMAND "Summary" " DISPLAY history summary"
			CALL base_curr_ledg_sum(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
			RETURNING p_curr_code 
			IF p_curr_code IS NOT NULL 
			AND p_curr_code != " "then 
				CALL get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
			END IF 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E")"Exit" " Exit FROM this enquiry"
			EXIT MENU 

			--      COMMAND KEY (control-w)
			--         CALL kandoohelp("")
	END MENU 

	CLOSE WINDOW wg197 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 


############################################################
# FUNCTION get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code)
#
#
############################################################
FUNCTION get_and_disp_hist_rec(p_cmpy, p_acct, p_acc_year, p_per, p_curr_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_curr_code LIKE currency.currency_code 
	DEFINE p_acct LIKE accounthist.acct_code 
	DEFINE p_acc_year LIKE accounthist.year_num 
	DEFINE p_per LIKE accounthist.period_num 

	DEFINE l_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_t_accounthist RECORD LIKE accounthist.* 
	DEFINE l_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * 
	INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5000,"") 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_coa.* 
	FROM coa 
	WHERE coa.acct_code = p_acct 
	AND coa.cmpy_code = p_cmpy 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",9031,"") 
		RETURN 
	END IF 

	SELECT * INTO l_rec_glparms.* FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		RETURN 
	END IF 

	LET l_rec_t_accounthist.cmpy_code = p_cmpy 
	LET l_rec_t_accounthist.acct_code = p_acct 
	LET l_rec_t_accounthist.year_num = p_acc_year 
	LET l_rec_t_accounthist.period_num = p_per 

	IF p_curr_code IS NULL THEN 
		LET l_rec_currency.currency_code = l_rec_glparms.base_currency_code 
	ELSE 
		LET l_rec_currency.currency_code = p_curr_code 
	END IF 

	SELECT * INTO l_rec_currency.* FROM currency 
	WHERE currency_code = l_rec_currency.currency_code 
	IF status = NOTFOUND THEN 
		LET l_rec_currency.desc_text = " " 
	END IF 
	IF p_curr_code IS NULL THEN 
		SELECT * INTO l_rec_accounthist.* FROM accounthist 
		WHERE cmpy_code = p_cmpy 
		AND acct_code = p_acct 
		AND year_num = p_acc_year 
		AND period_num = p_per 

		IF status = NOTFOUND THEN 
			INITIALIZE l_rec_accounthist.* TO NULL 
		END IF 
	ELSE 
		SELECT * INTO l_rec_accounthistcur.* FROM accounthistcur 
		WHERE cmpy_code = p_cmpy 
		AND acct_code = p_acct 
		AND year_num = p_acc_year 
		AND period_num = p_per 
		AND currency_code = l_rec_currency.currency_code 

		IF status = NOTFOUND THEN 
			INITIALIZE l_rec_accounthistcur.* TO NULL 
		END IF 
	END IF 

	IF p_curr_code IS NULL THEN 
		LET l_rec_currency.currency_code = NULL 
		LET l_rec_currency.desc_text = NULL 
		CALL disp_accounthist(l_rec_accounthist.*, 
		l_rec_t_accounthist.*, 
		l_rec_company.*, 
		l_rec_coa.*, 
		l_rec_currency.*, 
		l_rec_glparms.*) 
	ELSE 
		CALL disp_accounthistcur(l_rec_accounthist.*, 
		l_rec_t_accounthist.*, 
		l_rec_company.*, 
		l_rec_coa.*, 
		l_rec_currency.*, 
		l_rec_glparms.*, 
		l_rec_accounthistcur.*) 
	END IF 
END FUNCTION 

############################################################
# FUNCTION disp_accounthist(p_rec_accounthist,
#                          p_rec_t_accounthist,
#                          p_rec_company,
#                          p_rec_coa,
#                          p_rec_currency,
#                          p_rec_glparms)
#
#
############################################################
FUNCTION disp_accounthist(p_rec_accounthist, 
	p_rec_t_accounthist, 
	p_rec_company, 
	p_rec_coa, 
	p_rec_currency, 
	p_rec_glparms) 

	DEFINE 
	p_rec_accounthist RECORD LIKE accounthist.*, 
	p_rec_t_accounthist RECORD LIKE accounthist.*, 
	p_rec_company RECORD LIKE company.*, 
	p_rec_coa RECORD LIKE coa.*, 
	p_rec_currency RECORD LIKE currency.*, 
	p_rec_glparms RECORD LIKE glparms.* 

	DISPLAY p_rec_t_accounthist.cmpy_code, 
	p_rec_company.name_text, 
	p_rec_t_accounthist.acct_code, 
	p_rec_coa.desc_text, 
	p_rec_t_accounthist.year_num, 
	p_rec_t_accounthist.period_num, 
	p_rec_currency.currency_code, 
	p_rec_currency.desc_text, 
	p_rec_glparms.base_currency_code, 
	p_rec_accounthist.open_amt, 
	p_rec_accounthist.close_amt, 
	p_rec_accounthist.debit_amt, 
	p_rec_accounthist.credit_amt, 
	" ", 
	" ", 
	" ", 
	" ", 
	" " 
	TO accounthist.cmpy_code, 
	company.name_text, 
	accounthist.acct_code, 
	coa.desc_text, 
	accounthist.year_num, 
	accounthist.period_num, 
	formonly.currency_code, 
	currency.desc_text, 
	glparms.base_currency_code, 
	accounthistcur.base_open_amt, 
	accounthistcur.base_close_amt, 
	accounthistcur.base_debit_amt, 
	accounthistcur.base_credit_amt, 
	accounthistcur.currency_code, 
	accounthistcur.open_amt, 
	accounthistcur.close_amt, 
	accounthistcur.debit_amt, 
	accounthistcur.credit_amt 

END FUNCTION 


############################################################
# FUNCTION disp_accounthist(p_rec_accounthist,
#                          p_rec_t_accounthist,
#                          p_rec_company,
#                          p_rec_coa,
#                          p_rec_currency,
#                          p_rec_glparms)
#
#
############################################################
FUNCTION disp_accounthistcur(p_rec_accounthist, 
	p_rec_t_accounthist, 
	p_rec_company, 
	p_rec_coa, 
	p_rec_currency, 
	p_rec_glparms, 
	p_rec_accounthistcur) 

	DEFINE 
	p_rec_accounthist RECORD LIKE accounthist.*, 
	p_rec_t_accounthist RECORD LIKE accounthist.*, 
	p_rec_company RECORD LIKE company.*, 
	p_rec_coa RECORD LIKE coa.*, 
	p_rec_currency RECORD LIKE currency.*, 
	p_rec_glparms RECORD LIKE glparms.*, 
	p_rec_accounthistcur RECORD LIKE accounthistcur.* 

	DISPLAY p_rec_t_accounthist.cmpy_code, 
	p_rec_company.name_text, 
	p_rec_t_accounthist.acct_code, 
	p_rec_coa.desc_text, 
	p_rec_t_accounthist.year_num, 
	p_rec_t_accounthist.period_num, 
	p_rec_currency.currency_code, 
	p_rec_currency.desc_text, 
	p_rec_glparms.base_currency_code, 
	p_rec_accounthistcur.base_open_amt, 
	p_rec_accounthistcur.base_close_amt, 
	p_rec_accounthistcur.base_debit_amt, 
	p_rec_accounthistcur.base_credit_amt, 
	p_rec_accounthistcur.currency_code, 
	p_rec_accounthistcur.open_amt, 
	p_rec_accounthistcur.close_amt, 
	p_rec_accounthistcur.debit_amt, 
	p_rec_accounthistcur.credit_amt 
	TO accounthist.cmpy_code, 
	company.name_text, 
	accounthist.acct_code, 
	coa.desc_text, 
	accounthist.year_num, 
	accounthist.period_num, 
	formonly.currency_code, 
	currency.desc_text, 
	glparms.base_currency_code, 
	accounthistcur.base_open_amt, 
	accounthistcur.base_close_amt, 
	accounthistcur.base_debit_amt, 
	accounthistcur.base_credit_amt, 
	accounthistcur.currency_code, 
	accounthistcur.open_amt, 
	accounthistcur.close_amt, 
	accounthistcur.debit_amt, 
	accounthistcur.credit_amt 

END FUNCTION 
