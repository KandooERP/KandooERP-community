############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A27_GLOBALS.4gl" 

############################################################
# FUNCTION scan_invoices_by_customer() 
# RETURN 
#-------------------------------------
#1.customer selection
#2. customer invoice selection
#3. edit invoice....
#-------------------------------------
############################################################
FUNCTION scan_invoices_by_customer() 
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
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_idx SMALLINT  
	DEFINE l_rec_customer RECORD LIKE customer.*
	
	#-----------------------------------------------
	#Get customer record by cust_code
	CALL enter_invoice_edit_cust_code(FALSE) RETURNING l_rec_customer .*
	
	LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
	LET glob_rec_invoicehead.org_cust_code = l_rec_customer.corp_cust_code
	
	#-----------------------------------------------
	#Get list of ALL invoices of this customer (array of records)
	IF glob_rec_invoicehead.cust_code IS NOT NULL OR glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
		CALL db_invoicehead_get_datasource_invoices_of_customer(FALSE,glob_rec_invoicehead.cust_code,glob_rec_invoicehead.org_cust_code) RETURNING l_arr_rec_invoicehead
	ELSE #User pressed cancel in customer entry -> EXIT
		RETURN FALSE		
	END IF	
	
	--CALL db_invoicehead_get_datasource_invoices_of_customer(FALSE,glob_rec_invoicehead.cust_code,glob_rec_invoicehead.org_cust_code) RETURNING l_arr_rec_invoicehead
--	IF l_arr_rec_invoicehead.getSize() > 0 THEN

		#-----------------------------------------------
 		DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A27","inp-arr-invoicehead") 
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_invoicehead.getSize())
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar()


			ON ACTION "CUSTOMER"
				CALL enter_invoice_edit_cust_code(FALSE) RETURNING l_rec_customer .*
				
				LET glob_rec_invoicehead.cust_code = l_rec_customer.cust_code 
				LET glob_rec_invoicehead.org_cust_code = l_rec_customer.corp_cust_code
				
				IF glob_rec_invoicehead.cust_code IS NOT NULL OR glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
					CALL db_invoicehead_get_datasource_invoices_of_customer(FALSE,glob_rec_invoicehead.cust_code,glob_rec_invoicehead.org_cust_code) RETURNING l_arr_rec_invoicehead
				ELSE #User pressed cancel in customer entry -> EXIT
					RETURN FALSE		
				END IF	
			
				 
			ON ACTION "FILTER"
				CALL l_arr_rec_invoicehead.clear()
				--CALL enter_invoice_edit_cust_code(TRUE) RETURNING l_arr_rec_invoicehead
				CALL db_invoicehead_get_datasource_invoices_of_customer(TRUE,glob_rec_invoicehead.cust_code,glob_rec_invoicehead.org_cust_code) RETURNING l_arr_rec_invoicehead

--			ON ACTION "REFRESH"
--				CALL windecoration_a("A135")
--				CALL l_arr_rec_invoicehead.clear()
--				CALL db_invoicehead_get_datasource(FALSE) RETURNING l_arr_rec_invoicehead

							
			BEFORE ROW 
				LET l_idx = arr_curr() 
				IF l_idx > arr_count() THEN 
					MESSAGE kandoomsg2("A",9001,"") 
				END IF
				 
			ON ACTION ("EDIT","DOUBLECLICK")
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_invoicehead.getSize()) THEN
					CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.* 
					--SELECT * INTO glob_rec_invoicehead.* 
					--FROM invoicehead 
					--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
					--AND inv_num = l_arr_rec_invoicehead[l_idx].inv_num 
					IF glob_rec_invoicehead.inv_num IS NULL OR glob_rec_invoicehead.inv_num = 0 THEN #not found 
						NEXT FIELD inv_num 
					END IF
					 
					IF glob_rec_invoicehead.posted_flag = "Y" THEN 
						ERROR " Invoice IS posted TO General ledger - Edit NOT permitted" 
						NEXT FIELD inv_num 
					END IF
					 
					IF glob_rec_invoicehead.paid_amt != 0 THEN 
						ERROR " Invoice must be fully unpaid before editing IS permitted" 
						NEXT FIELD inv_num 
					END IF
					#--------------------------------------------------------
					#Edit the invoice with the choosen invoice number inv_num 
					CALL process_invoice(glob_rec_invoicehead.inv_num) 
					
					--NEXT FIELD inv_num 
					
					CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*					
					--SELECT * INTO glob_rec_invoicehead.* 
					--FROM invoicehead 
					--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					--AND inv_num = l_arr_rec_invoicehead[l_idx].inv_num 
	
					LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
					LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
					LET l_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
					LET l_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
					LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
					#DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*
					## redisplay new fields
					##
					#AFTER ROW
					#   DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*
				END IF
				
		END DISPLAY

--	END IF 
	
	IF int_flag THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF	
END FUNCTION 
############################################################
# END FUNCTION scan_invoices_by_customer() 
############################################################
