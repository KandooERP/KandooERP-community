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
############################################################
# A21 -  Allows the user TO enter Accounts Receivable Invoices
#        either updating inventory OR NOT depending on the parameters
#        file settings.
#
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A20_GLOBALS.4gl"

########################################################################
# FUNCTION display_custromer_credit_status(p_cust_code,p_win)
#
#
########################################################################
FUNCTION display_custromer_credit_status(p_cust_code,p_win)
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_win BOOLEAN 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_balance_amt LIKE customer.cred_bal_amt 
	DEFINE l_cred_avail_amt LIKE customer.cred_bal_amt
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_org_customer RECORD LIKE customer.* 
	DEFINE l_ret_nav SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2
	DEFINE l_style STRING #i.e. ATTRTIBUTE_OK

	IF p_cust_code IS NULL THEN
		LET l_rec_customer.* = glob_rec_customer.*
	ELSE
		CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.*
	END IF

	#If this summery info is used as an independent feature, we have to open the window-form and suspend, so the user can read the result
	IF p_win THEN #needs window/form to display data	
		OPEN WINDOW A137 with FORM "A137" #Invoice Header Window
		CALL windecoration_a("A137") 
	END IF
	
	IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		SELECT * INTO l_rec_org_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.org_cust_code 
		IF glob_rec_corpcust.inv_addr_flag != "C" THEN 
			## move orgs address TO cust addrs fields
		END IF 
	END IF 

	CALL db_term_get_rec(UI_OFF,l_rec_customer.term_code) RETURNING l_rec_term.*
	
	LET l_balance_amt = l_rec_customer.bal_amt 

	LET l_cred_avail_amt = 
		l_rec_customer.cred_limit_amt 
		- l_rec_customer.bal_amt #HuHo 17.3.21 changed back again... I'M confused... 15.3.2021 something strange.. balance_amt is already stored negative (-) - change minus to subtract/plus
		- l_rec_customer.onorder_amt  --have no exanmple data. don't know if it is negative or positive 

	IF l_rec_customer.bal_amt=l_rec_customer.curr_amt THEN #credit status OK
		MESSAGE "Credit status OK"
		LET l_style = ATTRIBUTE_OK
	ELSE 
		IF l_rec_customer.bal_amt=(l_rec_customer.curr_amt+l_rec_customer.over1_amt) THEN #Credit Amount reached
			ERROR "Credit Amount reached"
			LET l_style = ATTRIBUTE_WARNING 
		ELSE 
			ERROR "Customer has too much outstanding or overdue balance!"
			LET l_style = ATTRIBUTE_ERROR
		END IF
	END IF

	DISPLAY l_rec_customer.name_text TO name_text attribute(STYLE=l_style) 
	DISPLAY l_rec_customer.addr1_text TO addr1_text attribute(STYLE=l_style)
	DISPLAY l_rec_customer.addr2_text TO addr2_text attribute(STYLE=l_style)
	DISPLAY l_rec_customer.city_text TO city_text attribute(STYLE=l_style)
	DISPLAY l_rec_customer.state_code TO state_code attribute(STYLE=l_style)
	DISPLAY l_rec_customer.post_code TO post_code attribute(STYLE=l_style) 
	DISPLAY l_rec_customer.country_code TO country_code attribute(STYLE=l_style)--@db-patch_2020_10_04--
	DISPLAY l_rec_customer.curr_amt TO curr_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.over1_amt TO over1_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.over30_amt TO over30_amt attribute(STYLE=l_style) 
	DISPLAY l_rec_customer.over60_amt TO over60_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.over90_amt TO over90_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.bal_amt TO bal_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.cred_limit_amt TO cred_limit_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.currency_code TO currency_code attribute(STYLE=l_style)
	DISPLAY l_balance_amt TO balance_amt attribute(STYLE=l_style)
	DISPLAY l_rec_customer.onorder_amt TO onorder_amt attribute(STYLE=l_style)
	DISPLAY l_cred_avail_amt TO cred_avail_amt attribute(STYLE=l_style)
	DISPLAY l_rec_term.desc_text TO desc_text attribute(STYLE=l_style)


	IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		DISPLAY glob_rec_invoicehead.org_cust_code TO customer.cust_code attribute(STYLE=l_style) 
	ELSE 
		DISPLAY BY NAME l_rec_customer.cust_code attribute(STYLE=l_style) 
	END IF 

	#If this summery info is used as an independent feature, we have to open the window-form and suspend, so the user can read the result
	IF p_win THEN #needs window/form to display data	
		MENU 
			ON ACTION "NAV_BACKWARD"
				LET l_ret_nav = NAV_BACKWARD
				EXIT MENU
	
			ON ACTION ("NAV_FORWARD","ACCEPT")
				LET l_ret_nav = NAV_FORWARD
				EXIT MENU
	
			ON ACTION CANCEL
				LET l_ret_nav = NAV_CANCEL
				EXIT MENU
				
		END MENU
	ELSE
		LET l_ret_nav = NAV_FORWARD
	END IF
	
	IF int_flag THEN
		LET int_flag = FALSE
		LET l_ret_nav = NAV_CANCEL
	END IF
	
	IF p_win THEN #needs window/form to display data	
		CLOSE WINDOW A137
	END IF
	
	RETURN l_ret_nav
END FUNCTION 
########################################################################
# END FUNCTION display_custromer_credit_status(p_cust_code,p_win)
########################################################################
