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
# \file
# \brief module : A27
# Purpose : allows the user TO edit  Accounts Receivable Invoices
#           updating inventory
#
#
#   Some invoices can be edited AND some cannot.
#
#   InvInd  Source Allowed  Notes
#   ---------------------------------------------------------------------
#   1       AR A21  Yes     Normal AR invoice
#   2       OE O54  No      No longer used.
#   3       JM J31  No      Use Job Mgt Module
#   4       AR A2A  Yes     Debtor Adjustment
#   5       EO E53  Yes     Not recommended but no real reason why NOT.
#   6       EO E53  Yes     Not recommended but no real reason why NOT.
#   7       SS K11  No      Use Subscriptions module
#   8       AR A2R  No      Debtors Refund. Invoice must match voucher.
#   9       AR A21  Yes     AR Sundry Charge/Interest Charge
#   P       AP P29  No      AP Charge Thru Expense. Inv must equal voucher
#   X       AR ASL  Yes     Depends on invoice source. Needed TO fix probs.
#   S       WO W91  No      Check Building Products Module
#   L       WO W91  No      Check Building Products Module
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A20_GLOBALS.4gl" 


############################################################
# FUNCTION select_customer()
#
#
############################################################
FUNCTION select_customer()
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_ret SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	
	
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_arparms.inv_ref2a_text, glob_rec_arparms.inv_ref2b_text 
		
		MESSAGE kandoomsg2("A",1068,"") #1068 "Enter Customer Code FOR beginning of scan"
		INPUT BY NAME glob_rec_invoicehead.cust_code,	glob_rec_invoicehead.org_cust_code ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A27","inp-invoicehead")
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "LOOKUP" infield(cust_code) 
					LET glob_rec_invoicehead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD cust_code 
	
			ON CHANGE cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_invoicehead.cust_code) TO customer.name_text
	
			ON CHANGE org_cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_invoicehead.org_cust_code) TO org_name_text
			
	
			AFTER FIELD cust_code 
				IF glob_rec_invoicehead.cust_code IS NULL THEN 
					ERROR kandoomsg2("A",9024,"") #9024" cust code must be entered"
					NEXT FIELD cust_code 
				ELSE 
					IF db_customer_pk_exists(UI_ON,MODE_SELECT,glob_rec_invoicehead.cust_code) THEN
						CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*
					ELSE
						ERROR kandoomsg2("A",9009,"") #9009 "Customer NOT found, try window"
						NEXT FIELD cust_code 
					END IF
--					CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code) RETURNING l_rec_customer.*
--					IF l_rec_customer.cust_code IS NULL THEN 
--						ERROR kandoomsg2("A",9009,"") #9009 "Customer NOT found, try window"
--						NEXT FIELD cust_code 
--					END IF 
	
					IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN
						CALL db_customer_get_rec(UI_OFF,l_rec_customer.corp_cust_code) RETURNING l_rec_customer.* 
	 					IF l_rec_customer.cust_code IS NULL THEN 
							ERROR kandoomsg2("A",9121,"") #9121 "Logic : Org Customer NOT found "
							NEXT FIELD cust_code 
						END IF 
					END IF 
				END IF 
	
		END INPUT 

END FUNCTION
############################################################
# END FUNCTION select_customer()
############################################################

############################################################
# FUNCTION enter_invoice_edit_cust_code(p_filter) 
#
# get all invoices from the choosen customer
############################################################
FUNCTION enter_invoice_edit_cust_code(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_ret SMALLINT 	#Wizard Style Navigation NAV_BACKWARD=0 NAV_FORWARD SMALLINT=1 NAV_CANCEL SMALLINT=-1 NAV_DONE SMALLINT = 2	

--	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
--		inv_num LIKE invoicehead.inv_num, 
--		purchase_code LIKE invoicehead.purchase_code, 
--		inv_date LIKE invoicehead.inv_date, 
--		year_num LIKE invoicehead.year_num, 
--		period_num LIKE invoicehead.period_num, 
--		total_amt LIKE invoicehead.total_amt, 
--		paid_amt LIKE invoicehead.paid_amt, 
--		posted_flag LIKE invoicehead.posted_flag 
--	END RECORD 
--	DEFINE l_arr_rec_orgcust DYNAMIC ARRAY OF RECORD 
--		cust_code LIKE invoicehead.cust_code, 
--		name_text LIKE invoicehead.name_text 
--	END RECORD 
	DEFINE l_idx SMALLINT  
--	DEFINE l_rec_customer RECORD LIKE customer.*
		
	LET l_rec_customer .cust_code = glob_rec_invoicehead.cust_code
	LET l_rec_customer .corp_cust_code = glob_rec_invoicehead.org_cust_code

--	IF p_filter = TRUE OR glob_rec_invoicehead.cust_code IS NULL THEN
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_arparms.inv_ref2a_text, glob_rec_arparms.inv_ref2b_text 
		#ENTER CUSTOMER CODE
		MESSAGE kandoomsg2("A",1068,"") #1068 "Enter Customer Code FOR beginning of scan"
		INPUT 
			l_rec_customer.cust_code,	
			l_rec_customer.corp_cust_code WITHOUT DEFAULTS
		FROM 
			cust_code,
			org_cust_code ATTRIBUTE(UNBUFFERED)
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A27","inp-invoicehead")
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "LOOKUP" infield(cust_code) 
					LET l_rec_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD cust_code 
	
			ON CHANGE cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,l_rec_customer.cust_code) TO customer.name_text
				
				IF db_invoicehead_get_cust_code_count_not_posted(l_rec_customer.cust_code) = 0 THEN
					ERROR "Customer has got no none-posted invoices which can be modified"
					CONTINUE INPUT
				END IF

				IF db_invoicehead_get_cust_code_count_not_paid(l_rec_customer.cust_code) = 0 THEN
					ERROR "Customer has got no none-paid/partial paid invoices which can be modified"
					CONTINUE INPUT
				END IF
				
				LET l_ret = display_custromer_credit_status(l_rec_customer.cust_code,TRUE) 
				CASE l_ret
					WHEN NAV_BACKWARD
						#nothing - continue input
					WHEN NAV_FORWARD OR NAV_DONE
						IF l_rec_customer.cust_code IS NOT NULL THEN 
		
							IF db_invoicehead_get_cust_code_count_not_posted(l_rec_customer.cust_code) = 0 THEN
								ERROR "Customer has got no none-posted invoice which can be modified"
								NEXT FIELD cust_code
							END IF
		
							CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.*
							IF l_rec_customer.cust_code IS NULL THEN 
								ERROR kandoomsg2("A",9009,"") #9009 "Customer NOT found, try window"
								NEXT FIELD cust_code 
							END IF 
			
							IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN
								CALL db_customer_get_rec(UI_OFF,l_rec_customer.corp_cust_code) RETURNING l_rec_customer.* 
			 					IF l_rec_customer.cust_code IS NULL THEN 
									ERROR kandoomsg2("A",9121,"") #9121 "Logic : Org Customer NOT found "
									NEXT FIELD cust_code 
								END IF 
							END IF 
						END IF 
					
						ACCEPT INPUT
					WHEN NAV_CANCEL
						LET int_flag = TRUE
						EXIT INPUT
					OTHERWISE
						CALL fgl_winmessage("Internal 4gl error","Internal Error - contact support!\nError Code: #837821371","ERROR")							
				END CASE
			
	
			ON CHANGE org_cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,l_rec_customer.corp_cust_code) TO org_name_text
	
			AFTER FIELD cust_code 
				IF l_rec_customer.cust_code IS NOT NULL THEN 

					IF db_invoicehead_get_cust_code_count_not_posted(l_rec_customer.cust_code) = 0 THEN
						ERROR "Customer has got no none-posted invoice which can be modified"
						NEXT FIELD cust_code
					END IF

					CALL db_customer_get_rec(UI_OFF,l_rec_customer.cust_code) RETURNING l_rec_customer.*
					IF l_rec_customer.cust_code IS NULL THEN 
						ERROR kandoomsg2("A",9009,"") #9009 "Customer NOT found, try window"
						NEXT FIELD cust_code 
					END IF 
	
					IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN
						CALL db_customer_get_rec(UI_OFF,l_rec_customer.corp_cust_code) RETURNING l_rec_customer.* 
	 					IF l_rec_customer.cust_code IS NULL THEN 
							ERROR kandoomsg2("A",9121,"") #9121 "Logic : Org Customer NOT found "
							NEXT FIELD cust_code 
						END IF 
					END IF 
				END IF 

			AFTER FIELD org_cust_code
				IF l_rec_customer.cust_code IS NULL AND l_rec_customer.corp_cust_code IS NULL THEN
					ERROR "You need to specify the customer code or the cooperate code"
				END IF
			
			AFTER INPUT
				IF l_rec_customer.cust_code IS NULL AND l_rec_customer.corp_cust_code IS NULL THEN
					ERROR "You need to specify the customer code or the cooperate code"
					NEXT FIELD cust_code
				END IF


				#IF invoice_head count(*) choice = 0 stay in input or exit
				IF int_flag = FALSE THEN
					CASE
						WHEN l_rec_customer.cust_code IS NULL AND l_rec_customer.corp_cust_code IS NULL
							CALL fgl_winmessage("No Invoices found","Your search criteria did not match/find any invoices!","ERROR")
							CONTINUE INPUT
						
						WHEN l_rec_customer.cust_code IS NOT NULL AND l_rec_customer.corp_cust_code IS NOT NULL 					
							IF db_invoicehead_get_cust_org_cust_code_count(l_rec_customer.cust_code,l_rec_customer.corp_cust_code) = 0 THEN  
								CALL fgl_winmessage("No Invoices found","Your search criteria did not match/find any invoices!","ERROR")
								CONTINUE INPUT
							END IF
						
						WHEN l_rec_customer.cust_code IS NOT NULL
							IF db_invoicehead_get_cust_code_count_not_posted(l_rec_customer.cust_code) = 0 THEN
								CALL fgl_winmessage("No Invoices found","Your search criteria did not match/find any invoices!","ERROR")
								CONTINUE INPUT					
							END IF
	
						WHEN l_rec_customer.corp_cust_code IS NOT NULL
							IF db_invoicehead_get_org_cust_code_count(l_rec_customer.corp_cust_code) = 0 THEN
								CALL fgl_winmessage("No Invoices found","Your search criteria did not match/find any invoices!","ERROR")
								CONTINUE INPUT
							END IF
					END CASE							
				END IF
		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE
			INITIALIZE l_rec_customer.* TO NULL 
--			LET l_where_text = " 1=1 "			 
		ELSE 
			DISPLAY l_rec_customer.name_text TO name_text
			DISPLAY l_rec_customer.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
			
--			CALL db_invoicehead_get_datasource_invoices_of_customer(p_filter,l_rec_customer.cust_code,l_rec_customer.org_cust_code) RETURNING l_arr_rec_invoicehead 			 

		END IF
	LET glob_rec_invoicehead.cust_code = 	l_rec_customer.cust_code
	LET glob_rec_invoicehead.org_cust_code = 	l_rec_customer.corp_cust_code
	
	RETURN l_rec_customer.*
--	RETURN 	l_arr_rec_invoicehead
END FUNCTION
{		
			MESSAGE kandoomsg2("A",1001,"") #A1001 Enter selection criteria
	
			CONSTRUCT BY NAME l_where_text ON 
				invoicehead.inv_num, 
				invoicehead.purchase_code, 
				invoicehead.inv_date, 
				invoicehead.year_num, 
				invoicehead.period_num, 
				invoicehead.total_amt 
	
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","A27","construct-invoice") 
	
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 
	
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
	
			END CONSTRUCT 
	
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_where_text = " 1=1 "
			END IF
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF #if p_filter
		
	MESSAGE kandoomsg2("A",1002,"") #A1005 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		"AND cust_code = '",trim(glob_rec_invoicehead.cust_code),"' ", 
		"AND posted_flag = 'N' ", 
		"AND inv_ind in ('1','4','5','6','9','X') ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY cust_code,inv_num" 

	##
	## Check table above FOR invs WHERE edit allowed.
	##
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	

	LET l_idx = 0 
	FOREACH c_invoicehead INTO glob_rec_invoicehead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
		LET l_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
		LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_invoicehead[l_idx].posted_flag = glob_rec_invoicehead.posted_flag
		 
		IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
			LET l_arr_rec_orgcust[l_idx].cust_code = glob_rec_invoicehead.org_cust_code 
			SELECT name_text INTO l_arr_rec_orgcust[l_idx].name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_invoicehead.org_cust_code 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 

	IF l_arr_rec_invoicehead.getSize() = 0 THEN 
		MESSAGE kandoomsg2("A",9110,"") #A9110 " No invoices found FOR customer "
	ELSE 
		MESSAGE kandoomsg2("A",1013,"") #1013 " RETURN on line TO edit invoice"
	END IF
	
	RETURN 	l_arr_rec_invoicehead
END FUNCTION 
}
############################################################
# END FUNCTION select_invoices() 
############################################################

############################################################
# FUNCTION db_invoicehead_get_datasource_invoices_of_customer(p_filter,p_cust_code,p_org_cust_code)
# RETURN 	l_arr_rec_invoicehead
#
# Returns ALL (p_filter=false) or a set via construct (true) invoices 
# for a given customer p_cust_code
############################################################
FUNCTION db_invoicehead_get_datasource_invoices_of_customer(p_filter,p_cust_code,p_org_cust_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cust_code LIKE invoicehead.cust_code 
	DEFINE p_org_cust_code LIKE invoicehead.org_cust_code
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 

	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD 
	DEFINE l_arr_rec_orgcust DYNAMIC ARRAY OF RECORD 
		cust_code LIKE invoicehead.cust_code, 
		name_text LIKE invoicehead.name_text 
	END RECORD 
	DEFINE l_idx SMALLINT  


	IF p_filter THEN
		MESSAGE kandoomsg2("A",1001,"") #A1001 Enter selection criteria

		CONSTRUCT BY NAME l_where_text ON 
			invoicehead.inv_num, 
			invoicehead.purchase_code, 
			invoicehead.inv_date, 
			invoicehead.year_num, 
			invoicehead.period_num, 
			invoicehead.total_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A27","construct-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF

	ELSE
		LET l_where_text = " 1=1 "
	END IF #if p_filter
		
	MESSAGE kandoomsg2("A",1002,"") #A1005 Searching database - please wait
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		"AND ",
			"(cust_code = '",trim(p_cust_code),"' ",
			"OR org_cust_code = '",  trim(p_org_cust_code),"' )",
		"AND posted_flag = 'N' ", 
		"AND inv_ind in ('1','4','5','6','9','X') ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY cust_code,inv_num" 

	##
	## Check table above FOR invs WHERE edit allowed.
	##
	PREPARE s_invoicehead2 FROM l_query_text 
	DECLARE c_invoicehead2 CURSOR FOR s_invoicehead2 
	

	LET l_idx = 0 
	FOREACH c_invoicehead2 INTO glob_rec_invoicehead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
		LET l_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
		LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_invoicehead[l_idx].posted_flag = glob_rec_invoicehead.posted_flag
		 
		IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
			LET l_arr_rec_orgcust[l_idx].cust_code = glob_rec_invoicehead.org_cust_code 
			SELECT name_text INTO l_arr_rec_orgcust[l_idx].name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_invoicehead.org_cust_code 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 

	IF l_arr_rec_invoicehead.getSize() = 0 THEN 
		ERROR kandoomsg2("A",9110,"") #A9110 " No invoices found FOR customer "
	ELSE 
		MESSAGE kandoomsg2("A",1013,"") #1013 " RETURN on line TO edit invoice"
	END IF
	
	RETURN 	l_arr_rec_invoicehead
END FUNCTION 
############################################################
# END FUNCTION db_invoicehead_get_datasource_invoices_of_customer(p_filter,p_cust_code,p_org_cust_code)
############################################################


########################################################################
# FUNCTION initialize_invoice(p_inv_num)
#
# called by edit_invoice
########################################################################
FUNCTION initialize_invoice(p_inv_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 

	DELETE FROM t_invoicedetl WHERE 1=1 #empty temp table t_invoicedetl
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_warehouse.* TO NULL 
	INITIALIZE glob_rec_invoicehead.* TO NULL 
	INITIALIZE glob_rec_customership.* TO NULL 

	IF p_inv_num IS NOT NULL THEN #EDIT or NEW Invoice
		CALL db_invoicehead_get_rec(UI_OFF,p_inv_num) RETURNING glob_rec_invoicehead.* 
		--SELECT * INTO glob_rec_invoicehead.* 
		--FROM invoicehead 
		--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND inv_num = p_inv_num 

		CALL db_customer_get_rec(UI_OFF,glob_rec_invoicehead.cust_code  ) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* 
--		FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = glob_rec_invoicehead.cust_code 

		INSERT INTO t_invoicedetl SELECT * FROM invoicedetl 
		WHERE inv_num = glob_rec_invoicehead.inv_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		#use warehouse code of first line as default - NOTE: what happens with the very first line insert ?
		SELECT ware_code INTO glob_rec_warehouse.ware_code 
		FROM t_invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		AND line_num = 1 

		CALL db_warehouse_get_rec(UI_OFF,glob_rec_warehouse.ware_code) RETURNING glob_rec_warehouse.* 


	ELSE #New Invoice 

		LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_invoicehead.inv_num = NULL 
		LET glob_rec_invoicehead.ord_num = NULL 
		LET glob_rec_invoicehead.job_code = NULL 
		LET glob_rec_invoicehead.inv_date = today 
		LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_invoicehead.entry_date = today 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.tax_per = 0 
		LET glob_rec_invoicehead.goods_amt = 0 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = 0 
		LET glob_rec_invoicehead.total_amt = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.paid_amt = 0 
		LET glob_rec_invoicehead.paid_date = NULL 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		LET glob_rec_invoicehead.due_date= NULL 
		LET glob_rec_invoicehead.disc_date = NULL 
		LET glob_rec_invoicehead.expected_date = NULL 
		LET glob_rec_invoicehead.year_num = NULL 
		LET glob_rec_invoicehead.period_num = NULL 
		LET glob_rec_invoicehead.on_state_flag = "N" 
		LET glob_rec_invoicehead.posted_flag = "N" 
		LET glob_rec_invoicehead.seq_num = 0 
		LET glob_rec_invoicehead.line_num = 0 
		LET glob_rec_invoicehead.printed_num = 0 
		LET glob_rec_invoicehead.story_flag = "N" 
		LET glob_rec_invoicehead.rev_date = today 
		LET glob_rec_invoicehead.rev_num = 0 
		LET glob_rec_invoicehead.prepaid_flag = "N" 
		LET glob_rec_invoicehead.inv_ind = "1" 
		LET glob_rec_invoicehead.prev_paid_amt = 0 
		LET glob_rec_invoicehead.jour_num = NULL 
		LET glob_rec_invoicehead.post_date = NULL 
		LET glob_rec_invoicehead.manifest_num = NULL 
		LET glob_rec_invoicehead.stat_date = NULL 
		LET glob_curr_inv_amt = 0 
	END IF 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, "S", "0", p_inv_num) 

END FUNCTION 
########################################################################
# END FUNCTION initialize_invoice(p_inv_num)
########################################################################