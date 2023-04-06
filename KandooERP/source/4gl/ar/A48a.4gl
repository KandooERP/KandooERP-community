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
#  A48a - FUNCTION cred_appl().
#                  Allows a user TO apply a credit TO invoices
#
#                - A48a_select_inv()
#                  Selects all invoices related TO creditor
#
#                - A48a_scan_inv()
#                  The FUNCTION allows the user TO apply Credit Memos
#                  TO the invoices The user can apply memos TO as many
#                  invoice as desired AND IS NOT required TO completely
#                  pay any particular invoice before applying memo TO another
#
#       - FUNCTION write_cred_appl().
#         Performs the necessary db UPDATE TO apply a known amount of a
#         credit note TO an invoice.  This FUNCTION may (AND IS) called
#         by other programs besides "cred_appl".  As long as the credit,
#         invoice AND amount IS known.
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"

GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A48_GLOBALS.4gl" 

#################################################################
# MODULE scope variables
#################################################################


######################################################################################
# FUNCTION cred_appl(p_crednum,p_kandoouser_sign_on_code)
#
# Allows a user TO apply a credit TO invoices
######################################################################################
FUNCTION cred_appl(p_crednum,p_kandoouser_sign_on_code) 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_crednum LIKE credithead.cred_num 

	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_query_text CHAR(1100) 
	DEFINE l_where_text CHAR(800) 
	DEFINE l_where2_text CHAR(800) 
	DEFINE l_override_ind SMALLINT 

	CALL arparms_init() # AR/Account Receivable Parameters (arparms)

	IF get_kandoooption_feature_state("AR","01") = "Y" THEN 
		LET l_override_ind = true 
	ELSE 
		LET l_override_ind = false 
	END IF 

	SELECT credithead.* INTO l_rec_credithead.* FROM credithead 
	WHERE cred_num = p_crednum 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",7076,p_crednum) 	#7076 "Credit Note NOT found - Try Again"
		RETURN 
	END IF 

	IF l_rec_credithead.appl_amt = l_rec_credithead.total_amt THEN 
		ERROR kandoomsg2("W",9315,"") 	#9315 "Credit Memo has been fully applied"
		RETURN 
	END IF 

	IF l_rec_credithead.appl_amt IS NULL THEN 
		LET l_rec_credithead.appl_amt = 0 
	END IF 

	CALL db_customer_get_rec(UI_OFF,l_rec_credithead.cust_code ) RETURNING glob_rec_customer.* 
--	SELECT * INTO glob_rec_customer.* FROM customer 
--	WHERE cust_code = l_rec_credithead.cust_code 
--	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF glob_rec_customer.cust_code IS NULL THEN
		ERROR kandoomsg2("A",9067,"")		#9067 Customer RECORD NOT found - Try again"
		RETURN 
	END IF 

	OPEN WINDOW A125 with FORM "A125" 
	CALL windecoration_a("A125") 

	DISPLAY BY NAME glob_rec_arparms.inv_ref2a_text, 	glob_rec_arparms.inv_ref2b_text 	
	DISPLAY BY NAME glob_rec_customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
	
	IF glob_rec_customer.corp_cust_code IS NOT NULL THEN 
		SELECT name_text INTO glob_rec_customer.name_text 
		FROM customer 
		WHERE cust_code = glob_rec_customer.corp_cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	DISPLAY l_rec_credithead.cust_code TO cust_code 
	DISPLAY glob_rec_customer.name_text TO name_text 
	DISPLAY l_rec_credithead.cred_num TO cred_num 
	DISPLAY l_rec_credithead.total_amt TO total_amt 
	DISPLAY l_rec_credithead.appl_amt TO appl_amt 

	CALL a48a_scan_inv(l_rec_credithead.*)

--	WHILE a48a_select_inv(l_rec_credithead.*,glob_rec_customer.*) 
--		IF a48a_scan_inv(l_rec_credithead.*) THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 

	CLOSE WINDOW A125 
END FUNCTION 
######################################################################################
# END FUNCTION cred_appl(p_crednum,p_kandoouser_sign_on_code)
######################################################################################


######################################################################################
# FUNCTION db_invoicehead_get_datasource(p_filter,p_rec_credithead,p_rec_customer)
#
# RETURN l_arr_rec_cred,l_arr_rec_save_cred
######################################################################################
FUNCTION db_invoicehead_get_datasource(p_filter,p_rec_credithead,p_rec_customer)
	DEFINE p_filter BOOLEAN
	DEFINE p_rec_credithead RECORD LIKE credithead.* 
	DEFINE p_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_cred DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag CHAR(1), 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 	
	DEFINE l_arr_rec_save_cred DYNAMIC ARRAY OF RECORD --array[200] OF 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_where2_text STRING
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN

	MESSAGE kandoomsg2("A",1078,"") 	#1078 " Enter Selection Criteria - ESC TO Continue - F8 extended "
	CONSTRUCT l_where_text ON 
		invoicehead.inv_num, 
		invoicehead.purchase_code, 
		invoicehead.total_amt, 
		invoicehead.paid_amt, 
		invoicehead.due_date, 
		invoicehead.disc_date 
	FROM 
		invoicehead.inv_num, 
		invoicehead.purchase_code, 
		invoicehead.total_amt, 
		invoicehead.paid_amt, 
		invoicehead.due_date, 
		invoicehead.disc_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A48a","construct-invoicehead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F8) 
			LET l_where2_text = invext_select(glob_rec_kandoouser.cmpy_code) 

			IF l_where2_text IS NULL THEN 
				CONTINUE CONSTRUCT 
			ELSE 
				EXIT CONSTRUCT 
			END IF 
		AFTER CONSTRUCT
		 
			IF not(int_flag OR quit_flag) THEN 
				IF l_where2_text IS NULL THEN 
					LET l_where2_text = " 1=1 " 
				END IF 
			END IF 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = " 1=1 " 
	END IF

	ELSE
		LET l_where_text = " 1=1 " 
	END IF
		 
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code CLIPPED, "' ",    --"WHERE cmpy_code ='",p_rec_credithead.cmpy_code CLIPPED,"' ",
		"AND cust_code ='",p_rec_customer.cust_code CLIPPED,"' ", 
		"AND total_amt != paid_amt "
	
	IF l_where_text IS NOT NULL THEN
		LET l_query_text = l_query_text CLIPPED, " AND ",l_where_text clipped ," "
	END IF

	IF l_where2_text IS NOT NULL THEN
		LET l_query_text = l_query_text CLIPPED, " AND ",l_where2_text clipped ," "
	END IF

	
	IF p_rec_customer.corp_cust_code IS NOT NULL THEN 
		LET l_query_text = 
			l_query_text clipped," ", 
			"AND (org_cust_code='",p_rec_credithead.org_cust_code CLIPPED,"'", 
			" OR org_cust_code IS NULL) " 
	END IF 

	LET l_query_text = l_query_text clipped," ORDER BY cust_code,due_date,inv_date" 
	PREPARE s_invhead FROM l_query_text 

	
	LET l_idx = 0 
	DECLARE c_invhead CURSOR FOR s_invhead 
	
	FOREACH c_invhead INTO glob_rec_invoicehead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cred[l_idx].scroll_flag = NULL 
		LET l_arr_rec_cred[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_cred[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_cred[l_idx].pay_amt = 0 
		
		IF p_rec_credithead.posted_flag = "Y" THEN 
			LET l_arr_rec_cred[l_idx].disc_amt = 0 
		ELSE 
			## Dont default discount WHERE disc_date < cred_date
			## OR invoice IS NOT also paid by a cashreceipt.
			IF p_rec_credithead.cred_date > glob_rec_invoicehead.disc_date OR glob_rec_invoicehead.paid_amt = 0 THEN 
				LET l_arr_rec_cred[l_idx].disc_amt = 0 
			ELSE 
				LET l_arr_rec_cred[l_idx].disc_amt = glob_rec_invoicehead.disc_amt	- glob_rec_invoicehead.disc_taken_amt 

				IF l_arr_rec_cred[l_idx].disc_amt < 0 THEN 
					LET l_arr_rec_cred[l_idx].disc_amt = 0 
				END IF 

				IF l_arr_rec_cred[l_idx].disc_amt IS NULL THEN 
					LET l_arr_rec_cred[l_idx].disc_amt = 0 
				END IF 

			END IF 
		END IF 
		
		LET l_arr_rec_cred[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_cred[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_save_cred[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_save_cred[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_save_cred[l_idx].disc_amt = l_arr_rec_cred[l_idx].disc_amt 
		LET l_arr_rec_cred[l_idx].disc_amt = 0 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 
	
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("U",9506,"")		#9506 " No Records found Selection Criteria
	END IF 

	RETURN l_arr_rec_cred,l_arr_rec_save_cred
END FUNCTION
######################################################################################
# END FUNCTION db_invoicehead_get_datasource(p_filter,p_rec_credithead,p_rec_customer)
######################################################################################


######################################################################################
# FUNCTION A48a_select_inv(p_rec_credithead,p_rec_customer)
#
#
######################################################################################
FUNCTION a48a_select_inv(p_rec_credithead,p_rec_customer)
	DEFINE p_rec_credithead RECORD LIKE credithead.* 
	DEFINE p_rec_customer RECORD LIKE customer.* 

	DEFINE l_arr_rec_cred DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag CHAR(1), 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 	
	DEFINE l_arr_rec_save_cred DYNAMIC ARRAY OF RECORD --array[200] OF 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 

--	DEFINE l_query_text CHAR(800) 
--	DEFINE l_where_text CHAR(800) 
--	DEFINE l_where2_text CHAR(800) 
--	DEFINE l_rec_credithead RECORD LIKE credithead.* 

	CALL db_invoicehead_get_datasource(FALSE,p_rec_credithead.*,p_rec_customer.*) RETURNING l_arr_rec_cred,l_arr_rec_save_cred #RETURNING ??? shity globals approach - changing this now...
	 
END FUNCTION 
######################################################################################
# END FUNCTION A48a_select_inv(p_rec_credithead,p_rec_customer)
######################################################################################


######################################################################################
# FUNCTION A48a_scan_inv(p_rec_credithead)
#
#
######################################################################################
FUNCTION a48a_scan_inv(p_rec_credithead) 
	DEFINE p_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
--	DEFINE l_crednum LIKE credithead.cred_num 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_pre_amt LIKE invoicepay.pay_amt 
	DEFINE l_pre_dis LIKE invoicepay.disc_amt 
	DEFINE l_arr_rec_cred DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		scroll_flag CHAR(1), 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 

	DEFINE l_arr_rec_save_cred DYNAMIC ARRAY OF RECORD --array[200] OF RECORD 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 

	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	#DEFINE glob_rec_customer RECORD LIKE customer.*
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE idx SMALLINT 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_override_ind SMALLINT 
	DEFINE l_save_dis LIKE invoicepay.disc_amt 
	DEFINE l_save_amt LIKE invoicepay.pay_amt 
	DEFINE l_save_inv LIKE invoicehead.inv_num 

	CALL db_invoicehead_get_datasource(FALSE,p_rec_credithead.*,glob_rec_customer.*) RETURNING l_arr_rec_cred,l_arr_rec_save_cred

--		OPTIONS INSERT KEY f36, 
--		DELETE KEY f36 
 
		MESSAGE kandoomsg2("A",1092,"")		#1092 " RETURN on line TO apply credit, F5 Customer Inquiry
		INPUT ARRAY l_arr_rec_cred WITHOUT DEFAULTS FROM sr_cred.* ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE, DELETE ROW = FALSE, AUTO APPEND = FALSE) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A48a","inp-arr-cred") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "DETAILS" --ON KEY (F5) --customer details 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.cust_code) --customer details 

			BEFORE ROW 
				LET idx = arr_curr()
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_cred[idx].inv_num) RETURNING glob_rec_invoicehead.* 
				--SELECT * INTO glob_rec_invoicehead.* 
				--FROM invoicehead 
				--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				--AND inv_num = l_arr_rec_cred[idx].inv_num 
				
				DISPLAY glob_rec_invoicehead.due_date TO due_date 
				DISPLAY glob_rec_invoicehead.disc_date TO disc_date 
				DISPLAY glob_rec_invoicehead.disc_amt TO disc_amt
				DISPLAY glob_rec_invoicehead.disc_taken_amt TO disc_taken_amt 

				LET l_save_dis = l_arr_rec_cred[idx].disc_amt 
				LET l_save_amt = l_arr_rec_cred[idx].pay_amt 
				LET l_save_inv = l_arr_rec_cred[idx].inv_num 
				
			BEFORE FIELD scroll_flag 
				LET l_scroll_flag = l_arr_rec_cred[idx].scroll_flag 
				
			AFTER FIELD scroll_flag 
				LET l_arr_rec_cred[idx].scroll_flag = l_scroll_flag 

			BEFORE FIELD pay_amt 
				LET l_pre_amt = l_arr_rec_cred[idx].pay_amt 

				# LET amount TO apply = whats still available
				IF l_arr_rec_cred[idx].pay_amt = 0 THEN 
					LET l_arr_rec_cred[idx].pay_amt = p_rec_credithead.total_amt - p_rec_credithead.appl_amt 

					# IF too much too apply THEN adjust
					IF l_arr_rec_cred[idx].total_amt >= 0 THEN 
						IF l_arr_rec_cred[idx].pay_amt > (l_arr_rec_cred[idx].total_amt - l_arr_rec_cred[idx].paid_amt )- l_save_dis THEN 
							LET l_arr_rec_cred[idx].pay_amt = l_arr_rec_cred[idx].total_amt	- l_arr_rec_cred[idx].paid_amt - l_save_dis 
						END IF 
						IF l_arr_rec_cred[idx].pay_amt < 0 THEN 
							LET l_arr_rec_cred[idx].pay_amt = 0 
						END IF 
					END IF 

					IF l_arr_rec_cred[idx].total_amt < 0 THEN 
						IF l_arr_rec_cred[idx].pay_amt < l_arr_rec_cred[idx].total_amt + l_save_amt -	l_arr_rec_cred[idx].paid_amt - l_save_dis THEN 
							LET l_arr_rec_cred[idx].pay_amt = l_arr_rec_cred[idx].total_amt+l_save_amt- l_arr_rec_cred[idx].paid_amt - l_save_dis 
						END IF 
						IF l_arr_rec_cred[idx].pay_amt > 0 THEN 
							LET l_arr_rec_cred[idx].pay_amt = 0 
						END IF 
					END IF 

					# dont offer discount IF part paying
					IF l_arr_rec_cred[idx].pay_amt + l_arr_rec_cred[idx].disc_amt	< (l_arr_rec_cred[idx].total_amt - l_arr_rec_cred[idx].paid_amt) THEN 
						LET l_arr_rec_cred[idx].disc_amt = 0 
					END IF 
					
					LET l_save_amt = 0 
				END IF 
				#DISPLAY l_arr_rec_cred[idx].disc_amt,
				#          l_arr_rec_cred[idx].pay_amt,
				#          l_arr_rec_cred[idx].total_amt,
				#          l_arr_rec_cred[idx].paid_amt
				#       TO sr_cred[scrn].disc_amt,
				#          sr_cred[scrn].pay_amt,
				#          sr_cred[scrn].total_amt,
				#          sr_cred[scrn].paid_amt

			AFTER FIELD pay_amt 
				CASE 
					WHEN get_is_screen_navigation_forward()
						IF l_arr_rec_cred[idx].pay_amt IS NULL THEN 
							ERROR kandoomsg2("U",9102,"")							#9102 Value must be entered
							LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
							NEXT FIELD pay_amt 
						END IF 

						IF l_arr_rec_cred[idx].total_amt >= 0 THEN 
							IF l_arr_rec_cred[idx].pay_amt > 
							(l_arr_rec_cred[idx].total_amt-l_arr_rec_save_cred[idx].paid_amt) THEN 
								ERROR kandoomsg2("A",9519,"invoice")								#9519 "Amount will overapply the invoice"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								NEXT FIELD pay_amt 
							END IF 
						END IF 

						IF l_arr_rec_cred[idx].total_amt < 0 THEN 
							IF l_arr_rec_cred[idx].pay_amt < 
							(l_arr_rec_cred[idx].total_amt-l_arr_rec_save_cred[idx].paid_amt) THEN 
								ERROR kandoomsg2("A",9519,"invoice")								#9519 "Amount will overapply the invoice"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								NEXT FIELD pay_amt 
							END IF 
						END IF 
						NEXT FIELD disc_amt
						 
					WHEN NOT get_is_screen_navigation_forward()  
						LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
						NEXT FIELD scroll_flag 

					OTHERWISE 
						LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
						NEXT FIELD pay_amt 
				END CASE 
				
			BEFORE FIELD disc_amt 
				LET l_pre_dis = l_arr_rec_cred[idx].disc_amt 
				
			AFTER FIELD disc_amt 
				CASE 
					WHEN get_is_screen_navigation_forward() 
						IF l_arr_rec_cred[idx].disc_amt < 0 OR 
						l_arr_rec_cred[idx].disc_amt IS NULL THEN 
							LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
							ERROR kandoomsg2("A",9309,"")	#9309 Value must NOT be less than 0
							NEXT FIELD disc_amt 
						END IF
						 
						IF l_override_ind = false THEN 
							IF l_arr_rec_cred[idx].disc_amt > l_arr_rec_save_cred[idx].disc_amt THEN 
								ERROR kandoomsg2("A",9139,l_arr_rec_save_cred[idx].disc_amt)			#9139 Maximum discount available IS $$$$
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								NEXT FIELD pay_amt 
							END IF 
						END IF 
						
						IF p_rec_credithead.total_amt >= 0 THEN 
							IF p_rec_credithead.appl_amt + (l_arr_rec_cred[idx].pay_amt - l_pre_amt) 
							>	p_rec_credithead.total_amt THEN 

								ERROR kandoomsg2("A",9519,"memo")			#9519 "This entry will overapply the memo"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF 
						END IF
						 
						IF p_rec_credithead.total_amt < 0 THEN 
							IF p_rec_credithead.appl_amt + (l_arr_rec_cred[idx].pay_amt -	l_pre_amt) 
							<	p_rec_credithead.total_amt THEN 

								ERROR kandoomsg2("A",9519,"memo")		#9519 "This entry will overapply the memo"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF 
						END IF 
						
						IF l_arr_rec_cred[idx].total_amt >= 0 THEN 
							IF (l_arr_rec_cred[idx].pay_amt + l_arr_rec_cred[idx].disc_amt) 
							> (l_arr_rec_cred[idx].total_amt-l_arr_rec_save_cred[idx].paid_amt) THEN 

								ERROR kandoomsg2("A",9519,"invoice") 	#9519 "This entry will overapply the invoice"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF 
						END IF
						 
						IF l_arr_rec_cred[idx].total_amt < 0 THEN 
							IF (l_arr_rec_cred[idx].pay_amt + l_arr_rec_cred[idx].disc_amt ) 
							< (l_arr_rec_cred[idx].total_amt-l_arr_rec_save_cred[idx].paid_amt) THEN 

								ERROR kandoomsg2("A",9519,"invoice")				#9519 "This entry will overapply the invoice"
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF 
						END IF 
						
						IF l_arr_rec_cred[idx].disc_amt != 0 THEN 
							IF p_rec_credithead.posted_flag = "Y" THEN 

								ERROR kandoomsg2("A",9520,"") 						#9520 Credit Memo has been posted, no discounts allowed
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF
							 
							IF (l_arr_rec_cred[idx].pay_amt + l_arr_rec_cred[idx].disc_amt) 
							< (l_arr_rec_cred[idx].total_amt-l_arr_rec_save_cred[idx].paid_amt) THEN 
								ERROR kandoomsg2("A",9521,"")						#9521 "Must fully pay invoice TO get a discount"
								
								LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
								LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
								NEXT FIELD pay_amt 

							END IF 
						END IF 
						
						LET p_rec_credithead.appl_amt = p_rec_credithead.appl_amt + (l_arr_rec_cred[idx].pay_amt - l_pre_amt) 
						LET l_arr_rec_cred[idx].paid_amt = l_arr_rec_save_cred[idx].paid_amt + l_arr_rec_cred[idx].pay_amt + l_arr_rec_cred[idx].disc_amt 

						DISPLAY p_rec_credithead.appl_amt TO appl_amt attribute(magenta)
						 
						IF p_rec_credithead.appl_amt = p_rec_credithead.total_amt THEN 
							#MESSAGE "Credit Memo has been fully applied"
							ERROR kandoomsg2("A",7094,"")	#7094 "Credit Memo has been fully applied, ESC TO finish"
						END IF 
						
						LET l_save_amt = l_arr_rec_cred[idx].pay_amt 
						LET l_save_dis = l_arr_rec_cred[idx].disc_amt 
						--NEXT FIELD scroll_flag
						 
					WHEN NOT get_is_screen_navigation_forward() 
						LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
						LET l_arr_rec_cred[idx].pay_amt = l_pre_amt 
						NEXT FIELD pay_amt
						 
					OTHERWISE 
						LET l_arr_rec_cred[idx].disc_amt = l_pre_dis 
						NEXT FIELD disc_amt 
				END CASE 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
		ELSE 
			FOR idx = 1 TO l_arr_rec_cred.getSize() 

				IF l_arr_rec_cred[idx].pay_amt != 0 THEN 
					IF NOT write_cred_appl(
						glob_rec_kandoouser.cmpy_code,
						l_kandoouser_sign_on_code,
						p_rec_credithead.cred_num, 
						l_arr_rec_cred[idx].inv_num, 
						l_arr_rec_cred[idx].pay_amt, 
						l_arr_rec_cred[idx].disc_amt) THEN 
						
						LET l_err_cnt = l_err_cnt + 1 
						
					END IF 
				END IF 
			END FOR 
		END IF 

		LET int_flag = false 
		LET quit_flag = false 

		RETURN true 
END FUNCTION 
######################################################################################
# END FUNCTION A48a_scan_inv(p_rec_credithead)
######################################################################################


######################################################################################
# FUNCTION write_cred_appl(p_kandoouser_sign_on_code,p_cred_num,p_inv_num,p_pay_amt,p_disc_amt)
#
#
######################################################################################
FUNCTION write_cred_appl(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cred_num,p_inv_num, p_pay_amt,p_disc_amt) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code
	## Note this FUNCTION maybe (AND IS) called FROM external programs
	##
	# UPDATE procedure IS .
	#     1. lock credithead table
	#     2. re-check amounts
	#     3. FETCH invoicehead
	#     4. UPDATE invoicehead
	#     5. INSERT invoicepay
	#     6. INSERT exchange variance (IF any)
	#     7. IF any discount added THEN OUTPUT araudit
	#     8. IF any discount added THEN UPDATE customer
	#     9. UPDATE credithead
	##
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_pay_amt LIKE invoicehead.paid_amt 
	DEFINE p_disc_amt LIKE invoicehead.disc_amt 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	#DEFINE glob_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_kandoo_date LIKE invoicehead.paid_date 
	DEFINE l_base_inv_apply_amt LIKE invoicepay.pay_amt 
	DEFINE l_base_cred_apply_amt LIKE invoicepay.pay_amt 
	DEFINE l_credit_age SMALLINT 
	DEFINE l_invoice_age SMALLINT 

	IF p_company_cmpy_code IS NULL THEN
		LET p_company_cmpy_code = glob_rec_kandoouser.cmpy_code 
	ENd IF

--	SELECT * INTO l_rec_arparms.* 
--	FROM arparms 
--	WHERE cmpy_code = p_company_cmpy_code
--	AND parm_code = "1" 
	
	IF p_pay_amt IS NULL THEN 
		LET p_pay_amt = 0 
	END IF 
	
	IF p_disc_amt IS NULL THEN 
		LET p_disc_amt = 0 
	END IF 
	
	IF p_disc_amt = 0 AND p_pay_amt = 0 THEN 
		RETURN false 
	END IF 
	
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		RETURN false 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	
	BEGIN WORK 
		CALL set_aging(glob_rec_kandoouser.cmpy_code,glob_rec_arparms.cust_age_date) 
		LET l_err_message = "A48a - Credhead UPDATE"
		 
		DECLARE c_credithead CURSOR FOR 
		SELECT * FROM credithead 
		WHERE cred_num = p_cred_num 
		AND cmpy_code = p_company_cmpy_code
		AND appl_amt != total_amt 
		
		OPEN c_credithead 
		FETCH c_credithead INTO l_rec_credithead.* 
		LET l_credit_age = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
		IF sqlca.sqlcode != 0 THEN 
			IF status = 100 THEN 
				ERROR kandoomsg2("A",9303,"")	#9303 Credit has been applied by another user
				SLEEP 3 
				LET status = 0 
			END IF 
			GOTO recovery 
		END IF 

		IF l_rec_credithead.posted_flag = "Y" AND p_disc_amt != 0 THEN 
			ERROR kandoomsg2("A",9520,"") 	#9520 "Credit note IS posted - Discount IS NOT permiitted"
			SLEEP 3 
			GOTO recovery 
		END IF 
		IF l_rec_credithead.total_amt < (l_rec_credithead.appl_amt + p_pay_amt) THEN 
			ERROR kandoomsg2("A",9519,"credit")	#9519 Amount will overapply the credit
			SLEEP 3 
			GOTO recovery 
		END IF 
		LET l_err_message = "A48 - Invoice Lock & Update"
		 
		DECLARE c_invoicehead CURSOR FOR 
		SELECT * FROM invoicehead 
		WHERE inv_num = p_inv_num 
		AND cmpy_code = p_company_cmpy_code
		
		FOR UPDATE 
		OPEN c_invoicehead 
		FETCH c_invoicehead INTO glob_rec_invoicehead.* 
		IF sqlca.sqlcode != 0 THEN 
			ERROR kandoomsg2("U",7001,"Invoice Header")		#7001 Invoice Header RECORD does NOT exist in database
			GOTO recovery 
		END IF 

		LET l_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,glob_rec_invoicehead.due_date) 

		IF p_pay_amt IS NULL THEN 
			LET p_pay_amt = 0 
		END IF 

		IF p_disc_amt IS NULL THEN 
			LET p_disc_amt = 0 
		END IF 

		LET glob_rec_invoicehead.paid_amt = glob_rec_invoicehead.paid_amt + p_pay_amt + p_disc_amt 

		IF glob_rec_invoicehead.paid_amt > glob_rec_invoicehead.total_amt THEN 
			ERROR kandoomsg2("A",9519,"invoice")		#9519 "This entry will overapply the invoice"
			GOTO recovery 
		END IF 

		IF glob_rec_invoicehead.paid_amt != glob_rec_invoicehead.total_amt	AND p_disc_amt != 0 THEN 
			ERROR kandoomsg2("A",9140,"") 	#9140 Invoice must be fully paid TO obtain discount
			GOTO recovery 
		END IF 

		IF glob_rec_invoicehead.paid_amt = glob_rec_invoicehead.total_amt THEN
		 
			SELECT max(pay_date) INTO l_kandoo_date 
			FROM invoicepay 
			WHERE cmpy_code = p_company_cmpy_code
			AND cust_code = l_rec_credithead.cust_code 
			AND inv_num = p_inv_num
			 
			IF l_kandoo_date > l_rec_credithead.cred_date THEN 
				LET glob_rec_invoicehead.paid_date = l_kandoo_date 
			ELSE 
				LET glob_rec_invoicehead.paid_date = l_rec_credithead.cred_date 
			END IF 
		END IF 
		
		LET glob_rec_invoicehead.seq_num = glob_rec_invoicehead.seq_num + 1 
		LET glob_rec_invoicehead.disc_taken_amt = glob_rec_invoicehead.disc_taken_amt	+ p_disc_amt
		 
		UPDATE invoicehead 
		SET 
			paid_amt = glob_rec_invoicehead.paid_amt, 
			paid_date = glob_rec_invoicehead.paid_date, 
			seq_num = glob_rec_invoicehead.seq_num, 
			disc_taken_amt = glob_rec_invoicehead.disc_taken_amt 
		WHERE cmpy_code = p_company_cmpy_code
		AND inv_num = p_inv_num 
		
		LET l_rec_credithead.next_num = l_rec_credithead.next_num + 1 
		LET l_rec_invoicepay.cmpy_code = p_company_cmpy_code
		LET l_rec_invoicepay.cust_code = l_rec_credithead.cust_code 
		LET l_rec_invoicepay.inv_num = glob_rec_invoicehead.inv_num 
		LET l_rec_invoicepay.ref_num = l_rec_credithead.cred_num 
		LET l_rec_invoicepay.appl_num = 0 
		LET l_rec_invoicepay.pay_text = l_rec_credithead.cred_text 
		LET l_rec_invoicepay.apply_num = l_rec_credithead.next_num 
		LET l_rec_invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_invoicepay.pay_date = today 
		LET l_rec_invoicepay.pay_amt = p_pay_amt 
		LET l_rec_invoicepay.disc_amt = p_disc_amt 
		LET l_rec_invoicepay.rev_flag = NULL 
		LET l_rec_invoicepay.stat_date = NULL 
		LET l_rec_invoicepay.on_state_flag = "N" 
		LET l_err_message = "A48 - Invpay INSERT" 
		
		INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 

		IF l_rec_credithead.conv_qty IS NULL OR l_rec_credithead.conv_qty = 0 THEN 
			LET l_rec_credithead.conv_qty = 1 
		END IF 

		IF glob_rec_invoicehead.conv_qty IS NULL OR glob_rec_invoicehead.conv_qty = 0 THEN 
			LET glob_rec_invoicehead.conv_qty = 1 
		END IF 

		LET l_base_inv_apply_amt = l_rec_invoicepay.pay_amt/glob_rec_invoicehead.conv_qty 
		LET l_base_cred_apply_amt = l_rec_invoicepay.pay_amt/l_rec_credithead.conv_qty 

		IF l_base_inv_apply_amt != l_base_cred_apply_amt THEN 
			LET l_rec_exchangevar.cmpy_code = glob_rec_kandoouser.cmpy_code
			LET l_rec_exchangevar.year_num = l_rec_credithead.year_num 
			LET l_rec_exchangevar.period_num = l_rec_credithead.period_num 
			LET l_rec_exchangevar.source_ind = "A" 
			LET l_rec_exchangevar.tran_date = l_rec_credithead.cred_date 
			LET l_rec_exchangevar.ref_code = l_rec_credithead.cust_code 
			LET l_rec_exchangevar.tran_type1_ind = TRAN_TYPE_INVOICE_IN 
			LET l_rec_exchangevar.ref1_num = glob_rec_invoicehead.inv_num 
			LET l_rec_exchangevar.tran_type2_ind = TRAN_TYPE_CREDIT_CR 
			LET l_rec_exchangevar.ref2_num = l_rec_credithead.cred_num 
			LET l_rec_exchangevar.currency_code = glob_rec_invoicehead.currency_code 
			LET l_rec_exchangevar.exchangevar_amt =	l_base_inv_apply_amt - l_base_cred_apply_amt 
			LET l_rec_exchangevar.posted_flag = "N" 

			IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
				INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
			END IF 
		END IF 
		
		IF l_invoice_age <=0 AND l_credit_age <= 0 AND p_disc_amt = 0 THEN 
			#nothing
		ELSE 
			LET l_err_message = "A48 - Cust Main UPDATE"
			 
			DECLARE c_customer CURSOR FOR 
			SELECT * FROM customer 
			WHERE cust_code = l_rec_credithead.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code
			 
			FOR UPDATE 
			OPEN c_customer 
			FETCH c_customer INTO glob_rec_customer.*
			 
			CASE 
				WHEN l_credit_age <= 0 
					LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt + p_pay_amt 
				WHEN l_credit_age >=1 AND l_credit_age <=30 
					LET glob_rec_customer.over1_amt = glob_rec_customer.over1_amt + p_pay_amt 
				WHEN l_credit_age >=31 AND l_credit_age <=60 
					LET glob_rec_customer.over30_amt=glob_rec_customer.over30_amt + p_pay_amt 
				WHEN l_credit_age >=61 AND l_credit_age <=90 
					LET glob_rec_customer.over60_amt = glob_rec_customer.over60_amt+p_pay_amt 
				OTHERWISE 
					LET glob_rec_customer.over90_amt= glob_rec_customer.over90_amt + p_pay_amt 
			END CASE
			 
			CASE 
				WHEN l_invoice_age <=0 
					LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt - p_pay_amt 
				WHEN l_invoice_age >=1 AND l_invoice_age <=30 
					LET glob_rec_customer.over1_amt = glob_rec_customer.over1_amt - p_pay_amt 
				WHEN l_invoice_age >=31 AND l_invoice_age <=60 
					LET glob_rec_customer.over30_amt=glob_rec_customer.over30_amt - p_pay_amt 
				WHEN l_invoice_age >=61 AND l_invoice_age <=90 
					LET glob_rec_customer.over60_amt=glob_rec_customer.over60_amt - p_pay_amt 
				OTHERWISE 
					LET glob_rec_customer.over90_amt=glob_rec_customer.over90_amt - p_pay_amt 
			END CASE
			 
			IF p_disc_amt <> 0 THEN 
				LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt - p_disc_amt
				 
				CASE 
					WHEN l_invoice_age <=0 
						LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt	- p_disc_amt 
					WHEN l_invoice_age >=1 AND l_invoice_age <=30 
						LET glob_rec_customer.over1_amt = glob_rec_customer.over1_amt	- p_disc_amt 
					WHEN l_invoice_age >=31 AND l_invoice_age <=60 
						LET glob_rec_customer.over30_amt=glob_rec_customer.over30_amt - p_disc_amt 
					WHEN l_invoice_age >=61 AND l_invoice_age <=90 
						LET glob_rec_customer.over60_amt=glob_rec_customer.over60_amt - p_disc_amt 
					OTHERWISE 
						LET glob_rec_customer.over90_amt = glob_rec_customer.over90_amt - p_disc_amt 
				END CASE 
				
				LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
				LET l_err_message = "A87 - AR audit INSERT" 
				LET l_rec_araudit.cmpy_code = p_company_cmpy_code
				LET l_rec_araudit.tran_date = today 
				LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
				LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
				LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
				LET l_rec_araudit.tran_text = "Apply Discount" 
				LET l_rec_araudit.tran_amt = 0 - p_disc_amt 
				LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
				LET l_rec_araudit.year_num = l_rec_credithead.year_num 
				LET l_rec_araudit.period_num = l_rec_credithead.period_num 
				LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
				LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
				LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
				LET l_rec_araudit.entry_date = today
				 
				INSERT INTO araudit VALUES (l_rec_araudit.*)
				 
			END IF
			 
			UPDATE customer 
			SET 
				bal_amt = glob_rec_customer.bal_amt, 
				curr_amt = glob_rec_customer.curr_amt, 
				over1_amt = glob_rec_customer.over1_amt, 
				over30_amt = glob_rec_customer.over30_amt, 
				over60_amt = glob_rec_customer.over60_amt, 
				over90_amt = glob_rec_customer.over90_amt, 
				next_seq_num = glob_rec_customer.next_seq_num, 
				cred_bal_amt = cred_limit_amt - bal_amt 
			WHERE cust_code = l_rec_credithead.cust_code 
			AND cmpy_code = p_company_cmpy_code
		END IF
		 
		LET l_err_message = "A48 - Credhead UPDATE" 
		UPDATE credithead 
		SET 
			appl_amt = appl_amt + p_pay_amt, 
			disc_amt = disc_amt + p_disc_amt, 
			next_num = next_num + 1 
		WHERE cred_num = l_rec_credithead.cred_num 
		AND cmpy_code = p_company_cmpy_code

	COMMIT WORK 

	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN true 
END FUNCTION 
######################################################################################
# END FUNCTION write_cred_appl(p_kandoouser_sign_on_code,p_cred_num,p_inv_num,p_pay_amt,p_disc_amt)
######################################################################################


######################################################################################
# FUNCTION auto_credit_apply(p_kandoouser_sign_on_code,p_cred_num,p_where_text)
#
# CALLED LIKE THIS
# (glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_cred_num,"")then 
######################################################################################
FUNCTION auto_credit_apply(p_kandoouser_sign_on_code,p_cred_num,p_where_text) 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE p_where_text CHAR(500) 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_pay_amt DECIMAL(16,2) 
	DEFINE l_err_msg CHAR(30) 
	DEFINE l_err_cnt INTEGER 

	SELECT * INTO l_rec_credithead.* 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = p_cred_num 

	IF status = NOTFOUND THEN 
		LET l_err_msg = 'credit note ', p_cred_num USING '<<<<<<<<' 
		ERROR kandoomsg2("U",7001,"Credit Note") 
		RETURN false 
	END IF
	
	IF p_where_text IS NULL THEN 
		LET p_where_text = "1=1" 
	END IF
	 
	LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cust_code = '",l_rec_credithead.cust_code CLIPPED,"' ", 
		"AND total_amt > paid_amt ", 
		"AND ",p_where_text clipped," ", 
		"ORDER BY cust_code,due_date,inv_date" 

	PREPARE s1_invoicehead FROM l_query_text 
	DECLARE c1_invoicehead CURSOR with HOLD FOR s1_invoicehead 

	FOREACH c1_invoicehead INTO glob_rec_invoicehead.* 
		IF (l_rec_credithead.total_amt - l_rec_credithead.appl_amt) > (glob_rec_invoicehead.total_amt - glob_rec_invoicehead.paid_amt) THEN 
			LET l_pay_amt = glob_rec_invoicehead.total_amt - glob_rec_invoicehead.paid_amt 
		ELSE 
			LET l_pay_amt = l_rec_credithead.total_amt - l_rec_credithead.appl_amt 
		END IF 
		
		IF write_cred_appl(glob_rec_kandoouser.cmpy_code,p_kandoouser_sign_on_code,p_cred_num,	glob_rec_invoicehead.inv_num,	l_pay_amt,0) THEN 
			SELECT * INTO l_rec_credithead.* 
			FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cred_num = p_cred_num 
			IF l_rec_credithead.total_amt = l_rec_credithead.appl_amt THEN 
				EXIT FOREACH 
			END IF 
		ELSE 
			LET l_err_cnt = l_err_cnt + 1 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_err_cnt > 0 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION
######################################################################################
# END FUNCTION auto_credit_apply(p_kandoouser_sign_on_code,p_cred_num,p_where_text)
######################################################################################