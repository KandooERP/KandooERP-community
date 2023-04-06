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
# common/cacdwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A35_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_dataexist boolean 

##############################################################
# FUNCTION A35_main()
#
# \brief module A35  -  Cash Receipt Inquiry Program
#                   Allows the user TO view Receipt Information
##############################################################
FUNCTION A35_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A35") 

	OPEN WINDOW A148 with FORM "A148" 
	CALL windecoration_a("A148") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL receipt_browser() 
	
	CLOSE WINDOW A148
	 
END FUNCTION 
##############################################################
# END FUNCTION A35_main()
##############################################################


##############################################################
# FUNCTION get_datasource_cashreceipt_customer()
#
#
##############################################################
FUNCTION get_datasource_cashreceipt_customer(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 

	CALL arparms_init() # AR/Account Receivable Parameters (arparms)
	
	IF p_filter THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 	#1001 " Enter criteria FOR selection - ESC TO begin search"
		CONSTRUCT BY NAME l_where_text ON 
			cashreceipt.cust_code, 
			customer.name_text, 
			cashreceipt.cash_num, 
			cashreceipt.cash_date, 
			cashreceipt.order_num, 
			cashreceipt.cash_type_ind, 
			customer.currency_code, 
			cashreceipt.cash_amt, 
			cashreceipt.applied_amt, 
			cashreceipt.disc_amt, 
			cashreceipt.banked_flag, 
			cashreceipt.locn_code, 
			cashreceipt.on_state_flag, 
			cashreceipt.year_num, 
			cashreceipt.period_num, 
			cashreceipt.posted_flag, 
			cashreceipt.bank_code, 
			cashreceipt.cash_acct_code, 
			cashreceipt.bank_text, 
			cashreceipt.cheque_text, 
			cashreceipt.chq_date, 
			cashreceipt.bank_dep_num, 
			cashreceipt.banked_date, 
			cashreceipt.drawer_text, 
			cashreceipt.branch_text, 
			cashreceipt.com1_text, 
			cashreceipt.com2_text, 
			cashreceipt.entry_code, 
			cashreceipt.entry_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A35","construct-cashreceipt") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("A",1002,"")	#1002 Searching database - please wait
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = 
			"SELECT cashreceipt.*, customer.* FROM cashreceipt, customer ", 
			" WHERE customer.cust_code = cashreceipt.cust_code ", 
			" AND cashreceipt.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
			" AND customer.cmpy_code = cashreceipt.cmpy_code ", 
			" AND ", l_where_text clipped," ", 
			"ORDER BY cashreceipt.cust_code, cashreceipt.cash_num " 
	ELSE 
		LET l_query_text = 
			"SELECT cashreceipt.*, customer.* FROM cashreceipt, customer ", 
			" WHERE customer.cust_code = cashreceipt.cust_code ", 
			" AND cashreceipt.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
			" AND customer.cmpy_code = cashreceipt.cmpy_code ", 
			" AND ", l_where_text clipped," ", 
			" ORDER BY customer.name_text, cashreceipt.cash_num " 
	END IF 

	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt SCROLL CURSOR FOR s_cashreceipt 
	OPEN c_cashreceipt 
	FETCH c_cashreceipt INTO glob_rec_cashreceipt.*,glob_rec_customer.* 
	IF status = NOTFOUND THEN 
		LET modu_dataexist = false 
		RETURN false 
	ELSE 
		CALL display_cashreceipt() 
		LET modu_dataexist = true 

		RETURN true 
	END IF 
END FUNCTION 
##############################################################
# END FUNCTION get_datasource_cashreceipt_customer()
##############################################################


##############################################################
# FUNCTION receipt_browser()
#
#
##############################################################
FUNCTION receipt_browser() 

	CALL get_datasource_cashreceipt_customer("FALSE") RETURNING modu_dataexist 

	MENU " Receipt" 
		BEFORE MENU 
			IF modu_dataexist THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "Detail" 
				SHOW option "First" 
				SHOW option "Last" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
			CALL publish_toolbar("kandoo","A35","menu-receipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		ON ACTION "Query" #COMMAND "Query" " Enter selection criteria FOR receipts "
			IF get_datasource_cashreceipt_customer(true) THEN 
				FETCH FIRST c_cashreceipt INTO glob_rec_cashreceipt.* ,glob_rec_customer.* 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "CASH" 
				SHOW option "First" 
				SHOW option "Last" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "CASH" 
			END IF 
			
		ON ACTION "Next" #COMMAND KEY ("N",f21) "Next" " DISPLAY next selected receipt"

			FETCH NEXT c_cashreceipt INTO glob_rec_cashreceipt.*,glob_rec_customer.* 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9157,"") 	#9157 "You have reached the END of the entries selected"
			ELSE 
				CALL display_cashreceipt() 
			END IF 
			
		ON ACTION "Previous" #COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected receipt"
			FETCH previous c_cashreceipt INTO glob_rec_cashreceipt.*,glob_rec_customer.* 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9156,"") #9157 "You have reached the start of the entries selected"
			ELSE 
				CALL display_cashreceipt() 
			END IF 
			
		ON ACTION "DETAIL" #COMMAND KEY ("D",f20) "Detail" " View receipt details"
			CALL disp_cash_app(
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_cashreceipt.cust_code, 
				glob_rec_cashreceipt.cash_num) 
			
		ON ACTION "First" #COMMAND KEY ("F",f18) "First" " DISPLAY first receipt in the selected list"
			FETCH FIRST c_cashreceipt INTO glob_rec_cashreceipt.*,glob_rec_customer.* 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9156,"") 	#9157 "You have reached the start of the entries selected"
			ELSE 
				CALL display_cashreceipt() 
			END IF 
			
		ON ACTION "Last" #COMMAND KEY ("L",f22) "Last" " DISPLAY last receipt in the selected list"
			FETCH LAST c_cashreceipt INTO glob_rec_cashreceipt.*,glob_rec_customer.* 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("G",9157,"") 			#9157 "You have reached the END of the entries selected"
			ELSE 
				CALL display_cashreceipt() 
			END IF 
			
		ON ACTION "Exit" #COMMAND KEY (interrupt,"E") "Exit" " Exit FROM Inquiry"
			EXIT MENU 

	END MENU 

END FUNCTION 
##############################################################
# END FUNCTION receipt_browser()
##############################################################


##############################################################
# FUNCTION display_cashreceipt()
#
#
##############################################################
FUNCTION display_cashreceipt() 
	DEFINE l_reference_text LIKE kandooword.reference_text 

	LET l_reference_text = kandooword("cashreceipt.cash_type_ind", glob_rec_cashreceipt.cash_type_ind) 
 
	DISPLAY	glob_rec_cashreceipt.cust_code TO cust_code  
	DISPLAY glob_rec_customer.name_text TO name_text 
	DISPLAY glob_rec_cashreceipt.cash_num TO cash_num
	DISPLAY glob_rec_cashreceipt.cash_date TO cash_date
	DISPLAY glob_rec_cashreceipt.order_num TO order_num 
	DISPLAY glob_rec_cashreceipt.cash_type_ind TO cash_type_ind 
	DISPLAY l_reference_text TO cash_type_reference_text
	DISPLAY glob_rec_customer.currency_code TO currency_code
	DISPLAY glob_rec_cashreceipt.cash_amt TO cash_amt
	DISPLAY glob_rec_cashreceipt.applied_amt TO applied_amt 
	DISPLAY glob_rec_cashreceipt.disc_amt TO disc_amt
	DISPLAY glob_rec_cashreceipt.banked_flag TO banked_flag 
	DISPLAY glob_rec_cashreceipt.locn_code TO locn_code 
	DISPLAY glob_rec_cashreceipt.on_state_flag TO on_state_flag 
	DISPLAY glob_rec_cashreceipt.year_num TO year_num
	DISPLAY glob_rec_cashreceipt.period_num TO period_num 
	DISPLAY glob_rec_cashreceipt.posted_flag TO posted_flag 
	DISPLAY glob_rec_cashreceipt.bank_code TO bank_code 
	DISPLAY glob_rec_cashreceipt.cash_acct_code TO cash_acct_code 
	DISPLAY glob_rec_cashreceipt.bank_text TO bank_text 
	DISPLAY glob_rec_cashreceipt.cheque_text TO cheque_text 
	DISPLAY glob_rec_cashreceipt.chq_date TO chq_date 
	DISPLAY glob_rec_cashreceipt.bank_dep_num TO bank_dep_num 
	DISPLAY glob_rec_cashreceipt.banked_date TO banked_date  
	DISPLAY glob_rec_cashreceipt.drawer_text TO drawer_text 
	DISPLAY glob_rec_cashreceipt.branch_text TO branch_text 
	DISPLAY glob_rec_cashreceipt.com1_text TO com1_text 
	DISPLAY glob_rec_cashreceipt.com2_text TO com2_text 
	DISPLAY glob_rec_cashreceipt.entry_code TO entry_code 
	DISPLAY glob_rec_cashreceipt.entry_date TO entry_date 

	DISPLAY db_bank_get_name_acct_text(UI_OFF,glob_rec_cashreceipt.bank_code) TO bank.name_acct_text
	DISPLAY db_bank_get_iban(UI_OFF,glob_rec_cashreceipt.bank_code) TO bank.iban
	DISPLAY db_bank_get_bic_code(UI_OFF,glob_rec_cashreceipt.bank_code) TO bank.bic_code
	DISPLAY db_coa_get_desc_text(UI_OFF,glob_rec_cashreceipt.cash_acct_code) TO coa.desc_text

END FUNCTION 
##############################################################
# ENMD FUNCTION display_cashreceipt()
##############################################################