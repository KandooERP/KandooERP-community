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
# \brief module A31b allows the user TO apply Cash Receipts TO the invoices

#              The user can apply cash TO as many invoices as desired
#              AND IS NOT required TO completely pay any particular
#              invoice before applying cash TO another
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A31_GLOBALS.4gl"



############################################################
# FUNCTION app_cash(p_company_cmpy_code,p_cash_num,p_kandoouser_sign_on_code)
#
#
############################################################
FUNCTION app_cash(p_company_cmpy_code,p_cash_num,p_kandoouser_sign_on_code) 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cash_num LIKE cashreceipt.cash_num 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
--	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_arr_rec_cash DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 
	DEFINE l_msg STRING #for messages
	DEFINE l_idx INTEGER --, scrn 
	DEFINE l_save_disc_amt LIKE invoicehead.total_amt 
	DEFINE l_save_appl_amt LIKE invoicehead.total_amt 
	DEFINE l_err_message CHAR(60) 
	--	DEFINE l_base_inv_apply_amt LIKE invoicepay.pay_amt
	--	DEFINE l_base_cash_apply_amt LIKE invoicepay.pay_amt
	DEFINE l_where2_text CHAR(900) 
	DEFINE l_query_text CHAR(900) 

	DEFINE l_where_text CHAR(900) 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_override_ind SMALLINT 

	LET l_save_disc_amt = 0.00 #init
	LET l_save_appl_amt = 0.00 #init
	
	### Following kandoooption allows/disallows users
	### overkeying their own settlement discount
	IF get_kandoooption_feature_state("AR","01") = "Y" THEN 
		LET l_override_ind = true 
	ELSE 
		LET l_override_ind = false 
	END IF 

--	SELECT * INTO l_rec_arparms.* 
--	FROM arparms 
--	WHERE cmpy_code = p_company_cmpy_code 
--	AND parm_code = "1" 

	SELECT * INTO l_rec_cashreceipt.* 
	FROM cashreceipt 
	WHERE cmpy_code = p_company_cmpy_code 
	AND cash_num = p_cash_num 

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9137,"") 		#9137 " Logic error: Cashreceipt NOT found"
		RETURN 
	END IF 

	CALL db_customer_get_rec(UI_OFF,l_rec_cashreceipt.cust_code) RETURNING l_rec_customer.* #Note: original sql used p_company_cmpy_code
--	SELECT * INTO l_rec_customer.* 
--	FROM customer 
--	WHERE customer.cmpy_code = p_company_cmpy_code 
--	AND customer.cust_code = l_rec_cashreceipt.cust_code 
	--IF l_rec_customer.cust_code IS NULL THEN
	IF l_rec_customer.cust_code IS NULL THEN
	--IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9138,"") 	#9138" Logic error: Customer RECORD NOT found"
		CALL fgl_winmessage("Error","Logic error: Customer RECORD NOT found","ERROR")
		RETURN 
	END IF 

	OPEN WINDOW A154 with FORM "A154" 
	CALL windecoration_a("A154") 

	DISPLAY glob_rec_arparms.inv_ref1_text TO inv_ref1_text 
	DISPLAY l_rec_customer.currency_code TO currency_code attribute(green) 
	DISPLAY l_rec_cashreceipt.cust_code TO cust_code 
	DISPLAY l_rec_customer.name_text TO name_text 
	DISPLAY l_rec_cashreceipt.cash_num TO cash_num 
	DISPLAY l_rec_cashreceipt.cash_date TO cash_date 
	DISPLAY l_rec_cashreceipt.cash_amt TO cash_amt 
	DISPLAY l_rec_cashreceipt.applied_amt TO applied_amt 



	 {
	   LET l_where2_text = NULL
	   MESSAGE kandoomsg2("A",1078,"")	#1001 " Enter selection criteria AND press ESC TO begin search"
	   CONSTRUCT BY NAME l_where_text on inv_num,
	                                   purchase_code,
	                                   disc_amt,
	                                   total_amt,
	                                   paid_amt,
	                                   due_date,
	                                   disc_date,
	                                   inv_date


			BEFORE CONSTRUCT
				CALL publish_toolbar("kandoo","A31b","construct-invoice")

			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)
				ON ACTION "actToolbarManager"
			 	CALL setupToolbar()

			ON ACTION "Invoice"
	--      ON KEY(F8)
	         LET l_where2_text = invext_select(p_company_cmpy_code)
	         IF l_where2_text IS NULL THEN
	            continue construct
	         ELSE
	            EXIT construct
	         END IF
	      AFTER construct
	         IF NOT(int_flag OR quit_flag) THEN
	            IF l_where2_text IS NULL THEN
	              LET l_where2_text = "1=1"
	            END IF
	         END IF

	   END construct
	   IF int_flag OR quit_flag THEN
	      LET int_flag = FALSE
	      LET quit_flag = FALSE
	   ELSE
	      ERROR kandoomsg2("A",1002,"")
	      LET l_query_text = "SELECT * FROM invoicehead ",
	                        "WHERE cmpy_code = '",p_company_cmpy_code,"' ",
	                          "AND cust_code = '",l_rec_cashreceipt.cust_code,"' ",
	                          "AND ",l_where_text clipped," ",
	                          "AND ",l_where2_text clipped
	      IF l_rec_cashreceipt.job_code IS NULL THEN
	         IF l_rec_cashreceipt.cash_amt < 0 THEN
	            LET l_query_text = l_query_text clipped,
	                             " AND paid_amt > 0 "
	         ELSE
	            LET l_query_text = l_query_text clipped,
	                             " AND total_amt != paid_amt "
	         END IF
	      END IF
	      LET l_query_text = l_query_text clipped, " ORDER BY cust_code,",
	                                                     "due_date,",
	                                                     "inv_date,",
	                                                     "inv_num"
	      PREPARE s_invoice FROM l_query_text

	      DECLARE c_invoice CURSOR FOR s_invoice
	      LET l_idx = 0
	      CASE get_kandoooption_feature_state("AR","PT")
	         WHEN '1'
	            LET l_recalc_ind = 'N'
	         WHEN '2'
	            LET l_recalc_ind = 'Y'
	         WHEN '3'
	            LET l_recalc_ind = kandoomsg("A",1051,"")
	#A1051 Override invoice discount settings (Y/N)
	         OTHERWISE
	            LET l_recalc_ind = 'N'
	      END CASE
	      FOREACH c_invoice INTO l_rec_invoicehead.*
	      		IF l_rec_invoicehead.disc_amt IS NULL THEN  #got NULL disc_amt (not 0.0)from invoice head.. this corrects it
	      			LET l_rec_invoicehead.disc_amt = 0
	      		END IF
	         LET l_idx = l_idx + 1
	         LET l_arr_rec_cash[l_idx].inv_num = l_rec_invoicehead.inv_num
	         LET l_arr_rec_cash[l_idx].purchase_code = l_rec_invoicehead.purchase_code
	         LET l_arr_rec_cash[l_idx].pay_amt = 0
	         LET l_arr_rec_cash[l_idx].disc_amt = 0

	         IF  l_rec_cashreceipt.cash_amt >= 0
	         AND l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N THEN
	## certain criteria apply before def.discount will show
	            IF l_recalc_ind = 'Y' THEN
	               LET l_arr_rec_cash[l_idx].disc_amt = l_rec_invoicehead.total_amt *
	                                         ( show_disc( p_company_cmpy_code,
	                                                      l_rec_invoicehead.term_code,
	                                                      l_rec_cashreceipt.cash_date,
	                                                      l_rec_invoicehead.inv_date )
	                                         / 100 )
	            ELSE
	               IF l_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN
	                  LET l_arr_rec_cash[l_idx].disc_amt = l_rec_invoicehead.disc_amt
	               END IF
	            END IF
	         END IF
	         LET l_arr_rec_cash[l_idx].total_amt = l_rec_invoicehead.total_amt
	         LET l_arr_rec_cash[l_idx].paid_amt = l_rec_invoicehead.paid_amt
	         IF l_idx = 400 THEN
	            EXIT FOREACH
	         END IF
	      END FOREACH
	      IF l_idx = 0 THEN
	         ERROR kandoomsg2("A",9110,"")
	      END IF
	}
	#----------------------------------------------------------------------

	CALL get_datasource_invoice_apply_cash(false,p_company_cmpy_code,l_rec_cashreceipt.*) RETURNING l_arr_rec_cash, l_rec_invoicehead.* 

	MESSAGE kandoomsg2("A",1029,"") #1029 " RETURN on line TO apply cash receipt, F9 Auto Apply
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	--     CALL set_count(l_idx)
	IF l_arr_rec_cash.getlength() > 0 THEN  --was 1 #if array is NOT EMPTY, INPUT Array.. otherwise, exit/return
		INPUT ARRAY l_arr_rec_cash WITHOUT DEFAULTS FROM sr_cash.* ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE, AUTO APPEND = FALSE, DELETE ROW = FALSE) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A31b","inp-arr-cash") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "REFRESH" 
				CALL l_arr_rec_cash.clear() 
				CALL get_datasource_invoice_apply_cash(false,p_company_cmpy_code,l_rec_cashreceipt.*) RETURNING l_arr_rec_cash, l_rec_invoicehead.* 

			ON ACTION "FILTER" 
				CALL l_arr_rec_cash.clear() 
				CALL get_datasource_invoice_apply_cash(true,p_company_cmpy_code,l_rec_cashreceipt.*) RETURNING l_arr_rec_cash, l_rec_invoicehead.* 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				###
				### code below displays VALUES in SCREEN box
				###
				IF l_arr_rec_cash[l_idx].inv_num IS NULL 
				OR l_arr_rec_cash[l_idx].inv_num = 0 THEN 
					LET l_rec_invoicehead.due_date = NULL 
					LET l_rec_invoicehead.disc_date = NULL 
					LET l_rec_invoicehead.disc_amt = NULL 
					LET l_rec_invoicehead.disc_taken_amt = NULL 
					LET l_rec_invoicehead.inv_date = NULL 
				ELSE 
					SELECT * INTO l_rec_invoicehead.* 
					FROM invoicehead 
					WHERE cmpy_code = p_company_cmpy_code 
					AND inv_num = l_arr_rec_cash[l_idx].inv_num 

					IF l_rec_invoicehead.due_date = "31/12/1899" THEN 
						LET l_rec_invoicehead.due_date = NULL 
					END IF 

					IF l_rec_invoicehead.disc_date = "31/12/1899" THEN 
						LET l_rec_invoicehead.disc_date = NULL 
					END IF 
				END IF 

				DISPLAY l_rec_invoicehead.due_date TO invoicehead.due_date 
				DISPLAY l_rec_invoicehead.disc_date TO invoicehead.disc_date 
				DISPLAY l_rec_invoicehead.disc_amt TO invoicehead.disc_amt 
				DISPLAY l_rec_invoicehead.disc_taken_amt TO invoicehead.disc_taken_amt 
				DISPLAY l_rec_invoicehead.inv_date TO invoicehead.inv_date 

				###
				### code above displays VALUES in SCREEN box
				###

			ON ACTION "APPLY_AMOUNT" 
				NEXT FIELD pay_amt 

			ON ACTION "CUSTOMER" --customer details 
				--         ON KEY(F5)  --Customer Details
				CALL cinq_clnt(p_company_cmpy_code,l_rec_customer.cust_code) --customer details 

			ON ACTION "Apply Receipt" 
				--         ON KEY(F9)
				IF l_rec_cashreceipt.cash_amt < 0 THEN 
					error" Cannot auto apply negative receipts" 
				ELSE 
					IF length(l_where_text) + length(l_where2_text) <= 500 THEN 
						ERROR kandoomsg2("A",1005,"") 
						LET l_where_text = l_where_text clipped," AND ",	l_where2_text clipped 
						CALL auto_cash_apply(p_company_cmpy_code,p_kandoouser_sign_on_code,p_cash_num,l_where_text) 
						EXIT INPUT 
					ELSE 
						error" Selection criteria exceeeds limit on auto application" 
					END IF 
				END IF 

			BEFORE FIELD inv_num 
				LET l_save_appl_amt = l_arr_rec_cash[l_idx].pay_amt 

			AFTER FIELD inv_num 
--				IF fgl_lastkey() = fgl_keyval("down") 
--				AND arr_curr() >= arr_count() THEN 
--					ERROR kandoomsg2("A",9001,"") 
	--				NEXT FIELD inv_num 
	--			END IF 
				LET l_arr_rec_cash[l_idx].inv_num = l_rec_invoicehead.inv_num 
				#DISPLAY l_arr_rec_cash[l_idx].*
				#     TO sr_cash[scrn].*

			BEFORE FIELD pay_amt 
				IF l_arr_rec_cash[l_idx].inv_num = 0 THEN 
					NEXT FIELD inv_num ## problem IF CURSOR past LAST line 
				END IF 

				IF l_arr_rec_cash[l_idx].pay_amt = 0 THEN 
					##
					## default how much TO pay FOR this line
					##
					LET l_arr_rec_cash[l_idx].pay_amt = l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt 
					IF l_rec_cashreceipt.cash_amt >= 0 THEN 
						#### Positive Receipt
						IF l_arr_rec_cash[l_idx].pay_amt >= (
							l_arr_rec_cash[l_idx].total_amt 
							- l_arr_rec_cash[l_idx].paid_amt 
							- l_arr_rec_cash[l_idx].disc_amt) THEN 
							LET l_arr_rec_cash[l_idx].pay_amt = 
								l_arr_rec_cash[l_idx].total_amt 
								- l_arr_rec_cash[l_idx].paid_amt 
								- l_arr_rec_cash[l_idx].disc_amt 
						ELSE 
							LET l_arr_rec_cash[l_idx].disc_amt = 0 
						END IF 
					ELSE 
						#### Negative Receipt
						IF l_arr_rec_cash[l_idx].pay_amt < (0-l_arr_rec_cash[l_idx].paid_amt) THEN 
							LET l_arr_rec_cash[l_idx].pay_amt = 0 - l_arr_rec_cash[l_idx].paid_amt 
						END IF 
					END IF 
				END IF 

			AFTER FIELD pay_amt 
				IF l_arr_rec_cash[l_idx].pay_amt IS NULL THEN 
					LET l_arr_rec_cash[l_idx].pay_amt = l_save_appl_amt 
					NEXT FIELD pay_amt 
				ELSE 
				
					IF l_rec_cashreceipt.cash_amt >= 0 THEN 
						IF l_arr_rec_cash[l_idx].disc_amt < 0 THEN 
							error" Amount must NOT be less than zero" 
							NEXT FIELD pay_amt 
						END IF 
					ELSE 
						IF l_arr_rec_cash[l_idx].pay_amt > 0 THEN 
							error" Amount must NOT be greater than zero" 
							NEXT FIELD pay_amt 
						END IF 
					END IF
					 
				END IF 
				IF l_rec_cashreceipt.job_code IS NOT NULL THEN 
					NEXT FIELD total_amt 
				ELSE 
					LET l_arr_rec_cash[l_idx].paid_amt = 
						l_rec_invoicehead.paid_amt 
						+ l_arr_rec_cash[l_idx].pay_amt 
						+ l_arr_rec_cash[l_idx].disc_amt 
--					NEXT FIELD disc_amt 
				END IF 

			BEFORE FIELD disc_amt 
				LET l_save_disc_amt = 0 
				IF l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
					LET l_arr_rec_cash[l_idx].disc_amt = 0 
				ELSE 
					IF l_recalc_ind = 'Y' THEN 
						LET l_save_disc_amt = l_rec_invoicehead.total_amt * 
							show_disc( 
								p_company_cmpy_code, 
								l_rec_invoicehead.term_code, 
								l_rec_cashreceipt.cash_date, 
								l_rec_invoicehead.inv_date ) / 100  
					ELSE 
						IF l_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN 
							LET l_save_disc_amt = l_rec_invoicehead.disc_amt 
						END IF 
					END IF 
				END IF 
				
				IF l_save_disc_amt = 0 AND NOT l_override_ind THEN 
				--	NEXT FIELD total_amt 
				END IF 

			AFTER FIELD disc_amt 
				IF l_arr_rec_cash[l_idx].disc_amt IS NULL THEN 
					LET l_arr_rec_cash[l_idx].disc_amt = l_save_disc_amt 
					NEXT FIELD disc_amt 
				END IF 

				IF l_rec_cashreceipt.cash_amt >= 0 THEN 
					IF l_arr_rec_cash[l_idx].disc_amt < 0 THEN 
						error" Amount must be greater than zero" 
						LET l_arr_rec_cash[l_idx].disc_amt = l_save_disc_amt 
						NEXT FIELD disc_amt 
					END IF 
				
					IF NOT l_override_ind THEN 
						IF l_arr_rec_cash[l_idx].disc_amt > l_save_disc_amt THEN 
							ERROR kandoomsg2("A",9139,l_save_disc_amt) 						#9139" Max. discount IS ",l_save_disc_amt
							LET l_arr_rec_cash[l_idx].disc_amt = l_save_disc_amt 
							NEXT FIELD disc_amt #### pay_amt -> disc_amt 
						END IF 
					END IF 
				ELSE 
					IF l_arr_rec_cash[l_idx].disc_amt > 0 THEN 
						error" Amount must be less than zero" 
						LET l_arr_rec_cash[l_idx].disc_amt = l_save_disc_amt 
						NEXT FIELD disc_amt 
					END IF 
				END IF 
				
				LET l_arr_rec_cash[l_idx].paid_amt = 
					l_rec_invoicehead.paid_amt 
					+ l_arr_rec_cash[l_idx].pay_amt 
					+ l_arr_rec_cash[l_idx].disc_amt 
				NEXT FIELD total_amt 

			BEFORE FIELD total_amt 
				#DISPLAY l_arr_rec_cash[l_idx].* TO sr_cash[scrn].*

				IF l_rec_cashreceipt.cash_amt >= 0 THEN 
					IF l_rec_cashreceipt.job_code IS NULL THEN 
						## dishon cheqs are allowed TO overpay invoices
						IF (l_arr_rec_cash[l_idx].pay_amt + l_arr_rec_cash[l_idx].disc_amt) > 
						(l_arr_rec_cash[l_idx].total_amt - l_rec_invoicehead.paid_amt) THEN 
							ERROR kandoomsg2("A",9136,"") 						#9136 "Amount will overapply the invoice"
							NEXT FIELD pay_amt 
						END IF 
					END IF 

					IF l_arr_rec_cash[l_idx].disc_amt > 0 THEN 
						IF l_arr_rec_cash[l_idx].total_amt != 
							(l_arr_rec_cash[l_idx].pay_amt 
							+ l_arr_rec_cash[l_idx].disc_amt 
							+ l_rec_invoicehead.paid_amt) THEN 
							
							ERROR kandoomsg2("A",9140,"") 						#9140 " Must fully pay invoice TO get a discount"
							
							LET l_arr_rec_cash[l_idx].disc_amt = 0 
							LET l_arr_rec_cash[l_idx].paid_amt = l_rec_invoicehead.paid_amt	+ l_arr_rec_cash[l_idx].pay_amt 
							#DISPLAY l_arr_rec_cash[l_idx].* TO sr_cash[scrn].*

						END IF 
					END IF 

					LET l_rec_cashreceipt.applied_amt = 
						l_rec_cashreceipt.applied_amt 
						+ l_arr_rec_cash[l_idx].pay_amt 
						- l_save_appl_amt 
					
					LET l_save_appl_amt = l_arr_rec_cash[l_idx].pay_amt 

					IF l_rec_cashreceipt.applied_amt > l_rec_cashreceipt.cash_amt	OR l_rec_cashreceipt.applied_amt < 0 THEN 
						ERROR kandoomsg2("A",9141,"") 					#9141 " This entry will overapply the receipt"
						NEXT FIELD pay_amt 
					END IF 
					
				ELSE
				 
					#
					# Code below handles negative receipts
					IF (l_arr_rec_cash[l_idx].pay_amt + l_arr_rec_cash[l_idx].disc_amt) 
					< (0-l_rec_invoicehead.paid_amt) THEN 
						ERROR kandoomsg2("A",9136,"") 					#9136 "Amount will overapply the invoice"
						NEXT FIELD pay_amt 
					END IF 
				
					LET l_rec_cashreceipt.applied_amt = 
						l_rec_cashreceipt.applied_amt 
						+ l_arr_rec_cash[l_idx].pay_amt 
						- l_save_appl_amt 
					
					LET l_save_appl_amt = l_arr_rec_cash[l_idx].pay_amt 

					IF l_rec_cashreceipt.applied_amt < l_rec_cashreceipt.cash_amt	OR l_rec_cashreceipt.applied_amt > 0 THEN 
						ERROR kandoomsg2("A",9141,"") 					#9141 " This entry will overapply the receipt"
						NEXT FIELD pay_amt 
					END IF 
					
					# Code above handles negative receipts
					#
				END IF 
				DISPLAY l_rec_cashreceipt.applied_amt TO applied_amt 

				IF l_rec_cashreceipt.applied_amt = l_rec_cashreceipt.cash_amt THEN 
					MESSAGE kandoomsg2("A",7033,"") 				#7033 " Receipt has been fully applied
					SLEEP 1
				END IF 
				NEXT FIELD inv_num 

			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF l_rec_cashreceipt.cash_amt >= 0 THEN 
						IF l_rec_cashreceipt.applied_amt > l_rec_cashreceipt.cash_amt	OR l_rec_cashreceipt.applied_amt < 0 THEN 
							ERROR kandoomsg2("A",9142,"") 						#9142 " Receipt has been over applied"
							NEXT FIELD inv_num 
						END IF 
					ELSE 
						IF l_rec_cashreceipt.applied_amt < l_rec_cashreceipt.cash_amt	OR l_rec_cashreceipt.applied_amt > 0 THEN 
							ERROR kandoomsg2("A",9142,"") 						#9142 " Negative Receipt has been over applied"
							NEXT FIELD inv_num 
						END IF 
					END IF 
					
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_cash[l_idx].pay_amt != 0 THEN 
							IF NOT receipt_apply(  #returns false on failure
								p_company_cmpy_code,
								p_kandoouser_sign_on_code, 
								l_rec_cashreceipt.cash_num, 
								l_arr_rec_cash[l_idx].inv_num, 
								l_arr_rec_cash[l_idx].pay_amt, 
								l_arr_rec_cash[l_idx].disc_amt) THEN
								#Feature request Anna: Show messages 
								LET l_msg = "Could not apply receipt ", trim(l_rec_cashreceipt.cash_num), " to invoice ", trim(l_arr_rec_cash[l_idx].inv_num),"!"
								CALL fgl_winmessage("Receipt NOT Applied",l_msg,"error") 
								NEXT FIELD inv_num 
							ELSE
								LET l_msg = trim(l_arr_rec_cash[l_idx].pay_amt), " from receipt ", trim(l_rec_cashreceipt.cash_num), " was applied to invoice ", trim(l_arr_rec_cash[l_idx].inv_num)
								CALL fgl_winmessage("Receipt Applied",l_msg,"info")
							END IF 
						END IF 
					END FOR 
				END IF 

		END INPUT 
	ELSE
		MESSAGE "No valid Receipts found which could habe been applied"
	END IF #end IF - condition is, IF the data ARRAY IS NOT empty 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW A154 

END FUNCTION 
############################################################
# FUNCTION app_cash(p_company_cmpy_code,p_cash_num,p_kandoouser_sign_on_code)
############################################################