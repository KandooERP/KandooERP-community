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
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


#############################################################################
# FUNCTION coll_invo(p_cmpy,p_cust_code,p_overdue,p_baddue)
#
# Invoice
#############################################################################
FUNCTION coll_invo(p_cmpy,p_cust_code,p_overdue,p_baddue) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_overdue LIKE customer.over1_amt 
	DEFINE p_baddue LIKE customer.over1_amt 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD 
		inv_num LIKE invoicehead.inv_num, 
		expected_date LIKE invoicehead.expected_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		due_date LIKE invoicehead.due_date, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		note_num LIKE invstory.note_num 
	END RECORD 
	DEFINE l_arr_invoicehead DYNAMIC ARRAY OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		expected_date LIKE invoicehead.expected_date, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date,
		due_date LIKE invoicehead.due_date, 
		in_over DECIMAL(4,0), 
		paid_amt LIKE invoicehead.paid_amt, 
		in_out LIKE invoicehead.total_amt, 
		story_flag CHAR(1) 
	END RECORD 
	DEFINE l_save_date DATE 
	DEFINE l_cnt INTEGER 
	DEFINE l_out_total LIKE invoicehead.total_amt 
	DEFINE l_unapp_total LIKE invoicehead.total_amt
	DEFINE l_amount_due LIKE invoicehead.total_amt	 
--	DEFINE l_date_prompt CHAR(7) 
	DEFINE l_f_type CHAR(14) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_arparms RECORD LIKE arparms.* #Does also exist in globals AR / EO
	DEFINE l_run_arg STRING #for forming the RUN url argument 
	DEFINE l_query STRING
	DEFINE l_expected_date DATE #temp variable for due date edit-input via fgl_winprompt
	LET l_f_type = "View Invoice" 
	LET l_out_total = 0 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF STATUS = notfound THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) 	#9067 Logic Error: Customer XXXX NOT found
	END IF 

	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*

# Not sure - we may need to fix this	
#	IF get_kandoooption_feature_state("AR","DT") = "N" THEN 
#		LET l_date_prompt = "Invoice" 
#	ELSE 
#		LET l_date_prompt = "Due" 
#	END IF 

	WHENEVER ERROR CONTINUE #huho got WINDOW already OPEN ERROR - temp solution 9.8.2018 
	OPEN WINDOW A158 with FORM "A158" 
	IF STATUS = 0 THEN
		CALL windecoration_a("A158") 
		--CALL combolist_inv_num_by_customer("inv_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_rec_customer.cust_code,COMBO_NULL_NOT) 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	ELSE	 
		ERROR kandoomsg2("U",9917,"") #9917 "Window IS already OPEN"
		CURRENT WINDOW IS A158 
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	DISPLAY l_rec_arparms.inv_ref2a_text TO inv_ref2a_text ATTRIBUTE(white) #Does also exist in globals AR / EO
	DISPLAY l_rec_arparms.inv_ref2b_text TO inv_ref2b_text ATTRIBUTE(white) #Does also exist in globals AR / EO
--	DISPLAY l_date_prompt TO date_prompt ATTRIBUTE(white)  #hmmm this is all strange to me
	DISPLAY l_rec_customer.currency_code TO currency_code	ATTRIBUTE(green) 
{
#call this once ... some kind of init
	LET l_query = 
	"SELECT i.inv_num, i.expected_date, i.purchase_code, ", 
	"i.inv_date, i.due_date, i.total_amt, ", 
	"i.paid_amt, min(s.note_num) ", 
	"FROM invoicehead i, OUTER invstory s ",
	"WHERE i.cust_code = '?' " , --  p_cust_code CLIPPED, "' ", 
	"AND i.cmpy_code = '?' ", -- p_cmpy CLIPPED, "' ", 
	"AND i.total_amt != i.paid_amt ", 
	"AND i.posted_flag != \"V\" ",
	"AND i.posted_flag != \"H\" ",
	"AND s.cmpy_code = i.cmpy_code ", 
	"AND s.inv_num = i.inv_num ",
	"AND s.cust_code = i.cust_code ",
	"GROUP BY i.inv_num, i.expected_date, i.purchase_code, ", 
	"i.inv_date, i.due_date, i.total_amt, i.paid_amt ", 
	"ORDER BY i.inv_num" 
}

	LET l_query = 
	"SELECT i.inv_num, i.expected_date, i.purchase_code, ", 
	"i.inv_date, i.due_date, i.total_amt, ", 
	"i.paid_amt, min(s.note_num) ", 
	"FROM invoicehead i, OUTER invstory s ",
	"WHERE i.cust_code = '" , p_cust_code CLIPPED, "' ", 
	"AND i.cmpy_code = '", p_cmpy CLIPPED, "' ", 
	"AND i.total_amt != i.paid_amt ", 
	"AND i.posted_flag != \"V\" ",
	"AND i.posted_flag != \"H\" ",
	"AND s.cmpy_code = i.cmpy_code ", 
	"AND s.inv_num = i.inv_num ",
	"AND s.cust_code = i.cust_code ",
	"GROUP BY i.inv_num, i.expected_date, i.purchase_code, ", 
	"i.inv_date, i.due_date, i.total_amt, i.paid_amt ", 
	"ORDER BY i.inv_num" 

	PREPARE s_query FROM l_query
	DECLARE curser_item CURSOR FOR s_query
#--------- end of init	
	
{	
	SELECT i.inv_num, i.expected_date, i.purchase_code, 
	i.inv_date, i.due_date, i.total_amt, 
	i.paid_amt, min(s.note_num) 
	INTO l_rec_invoicehead.* 
	FROM invoicehead i, invstory s 
	WHERE i.cust_code = p_cust_code 
	AND i.cmpy_code = p_cmpy 
	AND i.total_amt != i.paid_amt 
	AND i.posted_flag != "V" 
	AND i.posted_flag != "H" 
	AND s.cmpy_code = i.cmpy_code 
	AND s.inv_num = i.inv_num 
	AND s.cust_code = i.cust_code 
	GROUP BY i.inv_num, i.expected_date, i.purchase_code, 
	i.inv_date, i.due_date, i.total_amt, i.paid_amt 
	ORDER BY i.inv_num 
}

	LET l_idx = 0 
	OPEN curser_item #USING p_cust_code, p_cmpy
	FOREACH curser_item  INTO l_rec_invoicehead
		LET l_idx = l_idx + 1
		#inv_num 
		LET l_arr_invoicehead[l_idx].inv_num = l_rec_invoicehead.inv_num
		#expected_date
		LET l_arr_invoicehead[l_idx].expected_date = l_rec_invoicehead.expected_date
		#purchase_code
		LET l_arr_invoicehead[l_idx].purchase_code = l_rec_invoicehead.purchase_code
		--LET l_arr_invoicehead[l_idx].expected_date = l_rec_invoicehead.inv_date
 		#inv_date
		LET l_arr_invoicehead[l_idx].inv_date = l_rec_invoicehead.inv_date
		#due_date
		LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.due_date 
		#in_over
		IF today - l_rec_invoicehead.due_date > 9999 THEN #???? I'm loosing it.. Kandoo is loosing me.. I don't get it 
			LET l_arr_invoicehead[l_idx].in_over = 9999 
		ELSE 
			LET l_arr_invoicehead[l_idx].in_over = today - l_rec_invoicehead.due_date 
		END IF 
		#paid_amt
		LET l_arr_invoicehead[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
		#in_out
		LET l_arr_invoicehead[l_idx].in_out = l_rec_invoicehead.total_amt	- l_rec_invoicehead.paid_amt
		#story_flag
		IF l_rec_invoicehead.note_num IS NULL THEN
			LET l_arr_invoicehead[l_idx].story_flag = "N" 		 
		ELSE 
			LET l_arr_invoicehead[l_idx].story_flag = "Y" 
		END IF 

		
		#VALIDATION: expected_date
		IF l_arr_invoicehead[l_idx].expected_date IS NULL THEN
			LET l_arr_invoicehead[l_idx].expected_date = l_rec_invoicehead.inv_date
		END IF
		#VALIDATION: due_date		
		IF l_arr_invoicehead[l_idx].due_date IS NULL THEN 
			LET l_arr_invoicehead[l_idx].due_date = today #?????huho: I'M missing the logic here.. why do we ignore the invoice date if the due date is NULL ?
		END IF 
		
		#Misc. Calculation
		LET l_out_total = l_out_total + (l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt) 
		 
# Date
# Format 1:  The date that payment is due for this invoice based upon the payment terms assigned to it. This is the date from which the invoice is aged.  
# Format 2:  The date of the invoice.

--		IF l_date_prompt = "Invoice" THEN 
--			LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.inv_date 
--		ELSE 
--			IF l_rec_invoicehead.due_date IS NOT NULL THEN #HuHo, this is just my personal guess
--				LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.due_date 
--			ELSE
--				LET l_arr_invoicehead[l_idx].due_date = l_rec_invoicehead.inv_date
--			END IF
--		END IF 



		
		 
		



	END FOREACH 

	IF p_overdue > 0 THEN 
		IF p_baddue > 0 THEN 
			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text, 
				l_rec_customer.onorder_amt, 
				l_rec_customer.cred_limit_amt, 
				l_rec_customer.cred_bal_amt, 
				l_rec_customer.curr_amt, 
				l_rec_customer.over1_amt, 
				l_rec_customer.over30_amt, 
				l_rec_customer.over60_amt, 
				l_rec_customer.over90_amt, 
				l_rec_customer.bal_amt	ATTRIBUTE (red) 

			LET l_unapp_total = l_out_total - l_rec_customer.bal_amt 
			LET l_amount_due = ((l_rec_customer.over1_amt 
			+ l_rec_customer.over30_amt 
			+ l_rec_customer.over60_amt 
			+ l_rec_customer.over90_amt) 
			- l_unapp_total) 
			
			DISPLAY 
				l_out_total, 
				l_unapp_total, 
				l_amount_due 
			TO 
				tot_out, 
				tot_unapp, 
				due_amt	ATTRIBUTE(red) 

		ELSE 

			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text, 
				l_rec_customer.onorder_amt, 
				l_rec_customer.cred_limit_amt, 
				l_rec_customer.cred_bal_amt, 
				l_rec_customer.curr_amt, 
				l_rec_customer.over1_amt, 
				l_rec_customer.over30_amt, 
				l_rec_customer.over60_amt, 
				l_rec_customer.over90_amt, 
				l_rec_customer.bal_amt ATTRIBUTE (yellow) 

			LET l_unapp_total = l_out_total - l_rec_customer.bal_amt 
			LET l_amount_due = ((l_rec_customer.over1_amt 
			+ l_rec_customer.over30_amt 
			+ l_rec_customer.over60_amt 
			+ l_rec_customer.over90_amt) 
			- l_unapp_total) 

			DISPLAY l_out_total TO tot_out ATTRIBUTE(YELLOW)
			DISPLAY	l_unapp_total TO tot_unapp ATTRIBUTE(YELLOW)
			DISPLAY l_amount_due TO due_amt ATTRIBUTE(YELLOW)
		END IF 

	ELSE 

		DISPLAY BY NAME 
			l_rec_customer.cust_code, 
			l_rec_customer.name_text, 
			l_rec_customer.onorder_amt, 
			l_rec_customer.cred_limit_amt, 
			l_rec_customer.cred_bal_amt, 
			l_rec_customer.curr_amt, 
			l_rec_customer.over1_amt, 
			l_rec_customer.over30_amt, 
			l_rec_customer.over60_amt, 
			l_rec_customer.over90_amt, 
			l_rec_customer.bal_amt ATTRIBUTE (green) 

		LET l_unapp_total = l_out_total - l_rec_customer.bal_amt 
		LET l_amount_due = ((l_rec_customer.over1_amt 
		+ l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt) 
		- l_unapp_total) 

		DISPLAY 
			l_out_total, 
			l_unapp_total, 
			l_amount_due 
		TO
			tot_out, 
			tot_unapp, 
			due_amt	ATTRIBUTE(green) 

	END IF 
	#Only 1 fields due_date and inv
	#If we find a different solution for changing the expected date, we can convert the input array to a display array.
	MESSAGE kandoomsg2("A",1089,"") 	#1089"CTRL V View Invoice - CTRL C Customer Inquiry..."
	--INPUT ARRAY l_arr_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* ATTRIBUTE(UNBUFFERED, INSERT ROW=FALSE,DELETE ROW=FALSE, APPEND ROW = FALSE, AUTO APPEND = FALSE) 
	DISPLAY ARRAY l_arr_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","collwind","input-arr-invoicehead") 
 			CALL dialog.setActionHidden("ACCEPT",TRUE)
 			CALL dialog.setActionHidden("STORY",NOT l_arr_invoicehead.getSize())
 			CALL dialog.setActionHidden("INVOICE",NOT l_arr_invoicehead.getSize())
 			CALL dialog.setActionHidden("EDIT EXPECTED DATE",NOT l_arr_invoicehead.getSize())
 			
		BEFORE ROW 
			# SET up ARRAY variables
			LET l_idx = arr_curr()
			IF l_arr_invoicehead[l_idx].inv_num > 0 OR l_arr_invoicehead[l_idx].inv_num IS NOT NULL THEN 

				LET l_save_date = l_arr_invoicehead[l_idx].expected_date 
				IF l_arr_invoicehead[l_idx].inv_num = 0 OR l_arr_invoicehead[l_idx].inv_num IS NULL THEN
					CALL dialog.setActionHidden("STORY",TRUE)
				ELSE
					CALL dialog.setActionHidden("STORY",FALSE)
				END IF
			END IF
 			 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "CUSTOMER"	--ON KEY (control-c) --customer inquiry --collection calls ? LIKE a51 ?
 			IF l_rec_customer.cust_code IS NOT NULL THEN
				CALL cinq_clnt( p_cmpy, l_rec_customer.cust_code) 
--				NEXT FIELD inv_num
			END IF 

		ON ACTION "NOTES" #customer notes	--ON KEY (control-n) --customer notes
			IF l_rec_customer.cust_code IS NOT NULL THEN 
				LET l_run_arg = "CUSTOMER_CODE=", trim(l_rec_customer.cust_code) 
				CALL run_prog("A13",l_run_arg,"","","") #customer notes filter 
--			NEXT FIELD inv_num 
			END IF
			
		ON ACTION "STORY" #invoice stories--ON KEY (control-t) --invoice stories 
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicehead.getSize()) THEN
				IF l_arr_invoicehead[l_idx].inv_num > 0 OR l_arr_invoicehead[l_idx].inv_num IS NOT NULL THEN
				
					CALL inv_story(p_cmpy,l_rec_customer.cust_code,l_arr_invoicehead[l_idx].inv_num) 
					SELECT count(*) INTO l_cnt FROM invstory 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = p_cust_code 
					AND inv_num = l_arr_invoicehead[l_idx].inv_num 
					IF l_cnt = 0 THEN 
						LET l_arr_invoicehead[l_idx].story_flag = "N" 
					ELSE 
						LET l_arr_invoicehead[l_idx].story_flag = "Y" 
					END IF 
					#DISPLAY l_arr_invoicehead[l_idx].story_flag TO sr_invoicehead[scrn].story
--				NEXT FIELD inv_num 
				END IF
			END IF


		ON ACTION ("INVOICE","DOUBLECLICK") #view invoice--ON KEY (F5) --view invoice 
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicehead.getSize()) THEN 
				IF l_arr_invoicehead[l_idx].inv_num > 0 OR l_arr_invoicehead[l_idx].inv_num IS NOT NULL THEN
				
					CALL lineshow(p_cmpy, 
					l_rec_customer.cust_code, 
					l_arr_invoicehead[l_idx].inv_num, 
					l_f_type) 
--				NEXT FIELD inv_num 
				END IF
			END IF
			
			#ON KEY(control-v)  --huho 23.08.2018 commented / duplicate TO F5
			#   CALL lineshow(p_cmpy,
			#                 l_rec_customer.cust_code,
			#                 l_arr_invoicehead[l_idx].inv_num,
			#                 l_f_type)
			#   NEXT FIELD inv_num
		
		ON ACTION "EDIT EXPECTED DATE"				

		--ON ACTION "AFTER FIELD inv_num"
		--BEFORE FIELD expected_date
			LET l_idx = arr_curr()
			IF (l_idx > 0) AND (l_idx <= l_arr_invoicehead.getSize()) THEN
				IF l_arr_invoicehead[l_idx].inv_num > 0 OR l_arr_invoicehead[l_idx].inv_num IS NOT NULL THEN
					LET l_arr_invoicehead[l_idx].expected_date = db_invoicehead_get_due_date(UI_OFF,l_arr_invoicehead[l_idx].inv_num)
					LET l_arr_invoicehead[l_idx].purchase_code = db_invoicehead_get_purchase_code(UI_OFF,l_arr_invoicehead[l_idx].inv_num)
					LET l_arr_invoicehead[l_idx].paid_amt = db_invoicehead_get_total_amt(UI_OFF,l_arr_invoicehead[l_idx].inv_num)
					LET l_arr_invoicehead[l_idx].due_date = db_invoicehead_get_due_date(UI_OFF,l_arr_invoicehead[l_idx].inv_num)
					LET l_arr_invoicehead[l_idx].in_over = today - l_arr_invoicehead[l_idx].due_date 
					LET l_arr_invoicehead[l_idx].story_flag = db_invoicehead_get_story_flag(UI_OFF,l_arr_invoicehead[l_idx].inv_num)
		
--				IF l_arr_invoicehead[l_idx].inv_num = 0 OR l_arr_invoicehead[l_idx].inv_num IS NULL THEN
--					CALL dialog.setActionHidden("STORY",TRUE)
--				ELSE
--					CALL dialog.setActionHidden("STORY",FALSE)
--				END IF
--			END IF
				
			--ON CHANGE expected_date --AFTER FIELD expected_date
--			IF l_arr_invoicehead[l_idx].inv_num > 0 OR l_arr_invoicehead[l_idx].inv_num IS NOT NULL THEN
					LET l_expected_date = l_arr_invoicehead[l_idx].expected_date
					LET l_expected_date = fgl_winprompt(1,1,"Enter the new \'Expected\' Date", l_expected_date, 10,7) #7=date dataType 
					IF (
					l_expected_date != l_save_date
					OR (l_save_date IS NULL	AND l_expected_date IS NOT null)
--				l_arr_invoicehead[l_idx].expected_date != l_save_date 
--				OR (l_save_date IS NULL	AND l_arr_invoicehead[l_idx].expected_date IS NOT null)
					) THEN
						#assign ret value to array row element
						LET l_arr_invoicehead[l_idx].expected_date = l_expected_date
						#update DB
						UPDATE invoicehead 
						SET expected_date = l_arr_invoicehead[l_idx].expected_date 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = p_cust_code 
						AND inv_num = l_arr_invoicehead[l_idx].inv_num 
					END IF 
				END IF
			END IF
	END DISPLAY 

	CLOSE WINDOW A158 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN 

END FUNCTION 
#############################################################################
# FUNCTION coll_invo(p_cmpy,p_cust_code,p_overdue,p_baddue)
#############################################################################