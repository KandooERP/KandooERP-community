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

###########################################################################
# Requires
# common/invqwind.4gl
# common/cacdwind.4gl
###########################################################################


######################################################################################
# GLOBAL Scope Variables
######################################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_pr_wa148 SMALLINT 
END GLOBALS 
######################################################################################
# FUNCTION cash_disp(p_cmpy, p_cust, p_cashnum)
#
# Displays the cash receipts
######################################################################################
FUNCTION cash_disp(p_cmpy, p_cust, p_cashnum) 
	DEFINE p_cmpy    LIKE company.cmpy_code 
	DEFINE p_cust    LIKE customer.cust_code
	DEFINE p_cashnum LIKE cashreceipt.cash_num 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_reference_text  LIKE kandooword.reference_text 
	DEFINE l_arr_cashreceipt DYNAMIC ARRAY OF LIKE cashreceipt.cust_code

	SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_cmpy 
	AND cash_num = p_cashnum 

	IF status = notfound THEN 
		ERROR kandoomsg2("A",9137,"") 	#9137 Cash Receipt RECORD NOT found
		RETURN 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE customer.cust_code = p_cust 
	AND customer.cmpy_code = p_cmpy 

	IF (status = notfound) THEN 
		ERROR kandoomsg2("A",9067,p_cust)		#9067 Customer XXXX NOT found
		RETURN 
	END IF 

	SELECT * INTO l_rec_bank.* FROM bank
	WHERE cmpy_code = p_cmpy
	AND bank_code = l_rec_cashreceipt.bank_code

	IF glob_pr_wa148 < 1 THEN 
		LET glob_pr_wa148 = glob_pr_wa148 + 1 
		CALL open_window( 'A148', glob_pr_wa148 ) 
	ELSE 
		ERROR kandoomsg2("U",9917,"")	#9917 Window IS already opened
		RETURN 
	END IF 

	LET l_reference_text = kandooword("cashreceipt.cash_type_ind", l_rec_cashreceipt.cash_type_ind) 

	LET l_arr_cashreceipt[1] = l_rec_cashreceipt.cust_code
	DISPLAY ARRAY l_arr_cashreceipt TO cashreceipt.*
		BEFORE DISPLAY
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("FIND",TRUE)
			CALL fgl_dialog_setactionlabel("CASH APP","Cash Applications","{CONTEXT}/public/querix/icon/svg/24/ic_view_module_24px.svg",2,FALSE,"Cash Applications")
			DISPLAY l_rec_customer.name_text TO name_text
			DISPLAY l_rec_cashreceipt.cash_num TO cash_num
			DISPLAY l_rec_cashreceipt.order_num TO order_num
			DISPLAY l_rec_cashreceipt.cash_date TO cash_date
			DISPLAY l_rec_cashreceipt.cash_type_ind TO cash_type_ind
			DISPLAY l_reference_text TO cash_type_reference_text
			DISPLAY l_rec_customer.currency_code TO currency_code
			DISPLAY l_rec_cashreceipt.banked_flag TO banked_flag
			DISPLAY l_rec_cashreceipt.cash_amt TO cash_amt
			DISPLAY l_rec_cashreceipt.on_state_flag TO on_state_flag
			DISPLAY l_rec_cashreceipt.applied_amt TO applied_amt  
			DISPLAY l_rec_cashreceipt.locn_code TO locn_code
			DISPLAY l_rec_cashreceipt.disc_amt TO disc_amt
			DISPLAY l_rec_cashreceipt.year_num TO year_num
			DISPLAY l_rec_cashreceipt.bank_code TO bank_code
			DISPLAY l_rec_cashreceipt.period_num TO period_num
			DISPLAY l_rec_bank.iban TO iban
			DISPLAY l_rec_cashreceipt.posted_flag TO posted_flag
			DISPLAY l_rec_bank.bic_code TO bic_code
			DISPLAY l_rec_cashreceipt.cash_acct_code TO cash_acct_code
			DISPLAY l_rec_cashreceipt.bank_text TO bank_text
			DISPLAY l_rec_cashreceipt.cheque_text TO cheque_text
			DISPLAY l_rec_cashreceipt.chq_date TO chq_date
			DISPLAY l_rec_cashreceipt.bank_dep_num TO bank_dep_num
			DISPLAY l_rec_cashreceipt.banked_date TO banked_date
			DISPLAY l_rec_cashreceipt.drawer_text TO drawer_text
			DISPLAY l_rec_cashreceipt.branch_text TO branch_text
			DISPLAY l_rec_cashreceipt.com1_text TO com1_text
			DISPLAY l_rec_cashreceipt.com2_text TO com2_text
			DISPLAY l_rec_cashreceipt.entry_code TO entry_code
			DISPLAY l_rec_cashreceipt.entry_date TO entry_date

		ON ACTION "CASH APP"
			CALL disp_cash_app(p_cmpy,l_rec_cashreceipt.cust_code,l_rec_cashreceipt.cash_num) 

	END DISPLAY

	CALL close_win( 'A148', glob_pr_wa148 ) 

	LET glob_pr_wa148 = glob_pr_wa148 - 1 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	RETURN 

END FUNCTION 
######################################################################################
# END FUNCTION cash_disp(p_cmpy, p_cust, p_cashnum)
######################################################################################