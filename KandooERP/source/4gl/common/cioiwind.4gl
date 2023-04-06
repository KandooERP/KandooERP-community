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
###########################################################################

###########################################################################
# Requires
# common/crhdwind.4gl
# common/cashwind.4gl
###########################################################################


##################################################################
# GLOBAL Scope Variables
##################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
##################################################################
# MODULE Scope Variables
##################################################################

##################################################################
# FUNCTION cinq_openitems(p_cmpy,p_cust_code,p_overdue_amt,p_baddue_amt)
#
#            Allows user TO scan through all outstanding
#                              FOR a particular customer.
##################################################################
FUNCTION cinq_openitems(p_cmpy,p_cust_code,p_overdue_amt,p_baddue_amt) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_overdue_amt LIKE customer.over1_amt 
	DEFINE p_baddue_amt LIKE customer.over1_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_current_amount LIKE invoicehead.total_amt
	DEFINE l_future_amount  LIKE invoicehead.total_amt
	DEFINE l_overdue2_bal   LIKE invoicehead.total_amt
	DEFINE l_overinv_amt    LIKE invoicehead.total_amt
	DEFINE l_unappcr_amt    LIKE invoicehead.total_amt
	DEFINE l_unappca_amt    LIKE invoicehead.total_amt
	DEFINE l_overbal_amt    LIKE invoicehead.total_amt 
	DEFINE l_rec_openitem RECORD 
		trans_num LIKE invoicehead.inv_num, 
		trans_type CHAR(2), 
		purchase_code LIKE invoicehead.purchase_code, 
		trans_date LIKE invoicehead.inv_date, 
		trans_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.total_amt, 
		due_date LIKE invoicehead.due_date, 
		trans_ind LIKE invoicehead.inv_ind, 
		job_code LIKE cashreceipt.job_code 
	END RECORD 
	DEFINE l_arr_openitem DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		trans_date LIKE invoicehead.inv_date, 
		trans_text CHAR(15), 
		trans_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		trans_amt LIKE invoicehead.total_amt, 
		days_over SMALLINT, 
		open_amt LIKE invoicehead.total_amt, 
		story_flag CHAR(1) 
	END RECORD 
	DEFINE l_arr_itemtype DYNAMIC ARRAY OF RECORD 
		trans_type CHAR(2) 
	END RECORD 
	DEFINE l_end_date DATE 
	DEFINE l_month SMALLINT
	DEFINE l_year SMALLINT
	DEFINE l_idx SMALLINT 
	DEFINE l_run_arg STRING 

	OPEN WINDOW A643 with FORM "A643" 
	CALL windecoration_a("A643") 

	MESSAGE kandoomsg2("A",1002,"") 	#A1002 Searching database - please wait
	LET l_overinv_amt = 0 
	LET l_unappcr_amt = 0 
	LET l_unappca_amt = 0 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF status = notfound THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) #9067 Logic Error: Customer XXXX does NOT exist
		CLOSE WINDOW A643 
		RETURN 
	END IF 

	DECLARE c_openitem CURSOR FOR 
	SELECT 
		inv_num,
		TRAN_TYPE_INVOICE_IN,
		purchase_code,
		inv_date, 
		total_amt,
		paid_amt,
		due_date,
		inv_ind, 
		0 
	FROM invoicehead 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	AND paid_amt < total_amt 
	union all 

	SELECT 
		cred_num,
		TRAN_TYPE_CREDIT_CR,
		cred_text,
		cred_date,
		0-total_amt,
		0-appl_amt,
		cred_date, 
		cred_ind, 0 
	FROM credithead 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	AND appl_amt < total_amt 
	union all 

	SELECT 
		cash_num,
		TRAN_TYPE_RECEIPT_CA,
		cheque_text,
		cash_date,
		0-cash_amt,
		0-applied_amt,
		cash_date,
		cash_type_ind, 
		job_code 
	FROM cashreceipt 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	AND ((applied_amt < cash_amt) 
	OR ((applied_amt > cash_amt) AND cash_amt < 0 )) # ret./rev. payments 
	ORDER BY 4, 1 

	LET l_idx = 0 


	FOREACH c_openitem INTO l_rec_openitem.* 
		LET l_idx = l_idx + 1 
		LET l_arr_openitem[l_idx].trans_date = l_rec_openitem.trans_date 
		LET l_arr_openitem[l_idx].purchase_code = l_rec_openitem.purchase_code 
		LET l_arr_openitem[l_idx].trans_num = l_rec_openitem.trans_num 
		LET l_arr_openitem[l_idx].trans_amt = l_rec_openitem.trans_amt 
		LET l_arr_openitem[l_idx].open_amt = l_rec_openitem.trans_amt - l_rec_openitem.paid_amt 
		LET l_arr_openitem[l_idx].days_over = NULL 
		LET l_arr_itemtype[l_idx].trans_type = l_rec_openitem.trans_type 

		CASE 
			WHEN l_rec_openitem.trans_type = TRAN_TYPE_INVOICE_IN 
				
				
				#--------------------------------
				# Invoices
				##
				LET l_arr_openitem[l_idx].trans_text = kandooword("invoicehead.inv_ind",l_rec_openitem.trans_ind)
				 
				IF l_arr_openitem[l_idx].trans_text IS NULL THEN 
					LET l_arr_openitem[l_idx].trans_text = "Invoice" 
				END IF 
				
				LET l_arr_openitem[l_idx].days_over = TODAY - l_rec_openitem.due_date 

				IF l_arr_openitem[l_idx].days_over > 0 THEN 
					LET l_overinv_amt =	l_overinv_amt 
						+ l_rec_openitem.trans_amt 
						- l_rec_openitem.paid_amt 
				END IF 

				#why are we not useing the story_flag in the table ?
				SELECT 1 FROM invstory 
				WHERE cmpy_code = p_cmpy 
				AND cust_code = l_rec_customer.cust_code 
				AND inv_num = l_rec_openitem.trans_num 
				AND note_num = 1 

				IF status = 0 THEN 
					LET l_arr_openitem[l_idx].story_flag = "Y"
				ELSE
					LET l_arr_openitem[l_idx].story_flag = "N"  
				END IF 


			WHEN l_rec_openitem.trans_type = TRAN_TYPE_CREDIT_CR 
				#--------------------------------
				# Credit Notes
				#--------------------------------
				LET l_arr_openitem[l_idx].trans_text = kandooword("credithead.cred_ind",l_rec_openitem.trans_ind) 
				IF l_arr_openitem[l_idx].trans_text IS NULL THEN 
					LET l_arr_openitem[l_idx].trans_text = "Credit Note" 
				END IF 
				
				LET l_arr_openitem[l_idx].days_over = NULL 
				LET l_unappcr_amt = l_unappcr_amt + 0 - (l_rec_openitem.trans_amt - l_rec_openitem.paid_amt) 
				##

			WHEN l_rec_openitem.trans_type = TRAN_TYPE_RECEIPT_CA 
				#--------------------------------
				# Cashreceipts
				#--------------------------------
				LET l_arr_openitem[l_idx].trans_text	= kandooword("cashreceipt.cash_type_ind",l_rec_openitem.trans_ind) 
				IF l_arr_openitem[l_idx].trans_text IS NULL THEN 
					LET l_arr_openitem[l_idx].trans_text = "Cashreceipt" 
				END IF 
				LET l_unappca_amt = l_unappca_amt + 0 - (l_rec_openitem.trans_amt - l_rec_openitem.paid_amt) 
		END CASE 


		IF l_idx = 500 THEN 
			ERROR kandoomsg2("A",9214,l_idx) 			#A9214 First 100 items selected only
			EXIT FOREACH 
		END IF 

	END FOREACH 

	LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt - l_rec_customer.onorder_amt 
	LET l_overbal_amt = l_overinv_amt - l_unappca_amt - l_unappcr_amt 
	LET l_month = MONTH(TODAY) 
	LET l_year = YEAR(TODAY) 

	IF l_month = 12 THEN 
		LET l_month = 1 
		LET l_year = l_year + 1 
	ELSE 
		LET l_month = l_month + 1 
	END IF 

	LET l_end_date = (mdy(l_month,1,l_year) - 1) 

	SELECT sum(total_amt - paid_amt) INTO l_current_amount FROM invoicehead 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	AND due_date >= TODAY 
	AND due_date <= l_end_date 

	IF l_current_amount IS NULL THEN 
		LET l_current_amount = 0 
	END IF 

	SELECT sum(total_amt - paid_amt) INTO l_future_amount FROM invoicehead 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	AND due_date > l_end_date 
	IF l_future_amount IS NULL THEN 
		LET l_future_amount = 0 
	END IF 

	LET l_overdue2_bal = l_overbal_amt 

	IF p_overdue_amt > 0 THEN 
		IF p_baddue_amt > 0 THEN 
			DISPLAY	l_rec_customer.cust_code TO	cust_code ATTRIBUTE(RED)
			DISPLAY	l_rec_customer.name_text TO name_text ATTRIBUTE(RED)
			DISPLAY	l_rec_customer.bal_amt TO bal_amt ATTRIBUTE(RED) 
			DISPLAY	l_rec_customer.cred_limit_amt TO cred_limit_amt ATTRIBUTE(RED)
			DISPLAY	l_current_amount TO current_amount ATTRIBUTE(RED)
			DISPLAY	l_future_amount TO future_amount ATTRIBUTE(RED) 
			DISPLAY	l_overdue2_bal TO overdue2_bal ATTRIBUTE(RED) 
			DISPLAY	l_rec_customer.onorder_amt TO onorder_amt ATTRIBUTE(RED)
			DISPLAY	l_rec_customer.cred_bal_amt TO cred_bal_amt ATTRIBUTE(RED)
			DISPLAY	l_overinv_amt TO overinv_amt ATTRIBUTE(RED)
			DISPLAY	l_unappca_amt TO unappca_amt ATTRIBUTE(RED)
			DISPLAY	l_unappcr_amt TO unappcr_amt ATTRIBUTE(RED)
			DISPLAY	l_overbal_amt TO overbal_amt ATTRIBUTE(RED)
		ELSE 
			DISPLAY	l_rec_customer.cust_code TO	cust_code ATTRIBUTE(MAGENTA)
			DISPLAY	l_rec_customer.name_text TO name_text ATTRIBUTE(MAGENTA)
			DISPLAY	l_rec_customer.bal_amt TO bal_amt ATTRIBUTE(MAGENTA) 
			DISPLAY	l_rec_customer.cred_limit_amt TO cred_limit_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_current_amount TO current_amount ATTRIBUTE(MAGENTA)
			DISPLAY	l_future_amount TO future_amount ATTRIBUTE(MAGENTA) 
			DISPLAY	l_overdue2_bal TO overdue2_bal ATTRIBUTE(MAGENTA) 
			DISPLAY	l_rec_customer.onorder_amt TO onorder_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_rec_customer.cred_bal_amt TO cred_bal_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_overinv_amt TO overinv_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_unappca_amt TO unappca_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_unappcr_amt TO unappcr_amt ATTRIBUTE(MAGENTA)
			DISPLAY	l_overbal_amt TO overbal_amt ATTRIBUTE(MAGENTA)
		END IF 
	ELSE 
		DISPLAY	l_rec_customer.cust_code TO	cust_code ATTRIBUTE(GREEN)
		DISPLAY	l_rec_customer.name_text TO name_text ATTRIBUTE(GREEN)
		DISPLAY	l_rec_customer.bal_amt TO bal_amt ATTRIBUTE(GREEN) 
		DISPLAY	l_rec_customer.cred_limit_amt TO cred_limit_amt ATTRIBUTE(GREEN)
		DISPLAY	l_current_amount TO current_amount ATTRIBUTE(GREEN)
		DISPLAY	l_future_amount TO future_amount ATTRIBUTE(GREEN) 
		DISPLAY	l_overdue2_bal TO overdue2_bal ATTRIBUTE(GREEN) 
		DISPLAY	l_rec_customer.onorder_amt TO onorder_amt ATTRIBUTE(GREEN)
		DISPLAY	l_rec_customer.cred_bal_amt TO cred_bal_amt ATTRIBUTE(GREEN)
		DISPLAY	l_overinv_amt TO overinv_amt ATTRIBUTE(GREEN)
		DISPLAY	l_unappca_amt TO unappca_amt ATTRIBUTE(GREEN)
		DISPLAY	l_unappcr_amt TO unappcr_amt ATTRIBUTE(GREEN)
		DISPLAY	l_overbal_amt TO overbal_amt ATTRIBUTE(GREEN)
	END IF 

	DISPLAY l_rec_customer.currency_code TO curr1_code ATTRIBUTE(GREEN) 
	DISPLAY l_rec_customer.currency_code TO curr3_code ATTRIBUTE(GREEN)
	DISPLAY l_rec_customer.currency_code TO curr4_code ATTRIBUTE(GREEN)
	 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("A",1069,"") 	#1069 "Enter TO view transaction, CTRL T = story, CTRL N = client notes"
	CALL set_count(l_idx) 

	#INPUT ARRAY l_arr_openitem WITHOUT DEFAULTS FROM sr_openitem.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_openitem TO sr_openitem.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cioiwind","input-arr-openitem") 
			CALL dialog.setActionHidden("STORY",NOT l_arr_openitem.getSize())
			CALL dialog.setActionHidden("NOTES",NOT l_arr_openitem.getSize())

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_arr_openitem[l_idx].scroll_flag = NULL

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Notes"
			#Customer Notes
		--ON KEY (control-n) 
			LET l_run_arg = "CUSTOMER_CODE=", trim(l_rec_customer.cust_code) 
			CALL run_prog("A13",l_run_arg,"","","") 
			NEXT FIELD scroll_flag 

			#Story Flag
		ON ACTION "STORY"	--ON KEY (control-t)
			IF (l_idx > 0) AND (l_idx <= l_arr_openitem.getSize()) THEN
				IF l_arr_itemtype[l_idx].trans_type = TRAN_TYPE_INVOICE_IN THEN 
					CALL inv_story(
						p_cmpy,
						l_rec_customer.cust_code,	
						l_arr_openitem[l_idx].trans_num)
					 
					SELECT 1 FROM invstory 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_customer.cust_code 
					AND inv_num = l_arr_openitem[l_idx].trans_num 
					AND note_num = 1 
					IF status = 0 THEN 
						LET l_arr_openitem[l_idx].story_flag = "Y" 
					ELSE 
						LET l_arr_openitem[l_idx].story_flag = "N" 
					END IF 
				END IF 
--			NEXT FIELD scroll_flag 
			END IF
--		BEFORE FIELD scroll_flag 
--			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_openitem[l_idx].* TO sr_openitem[scrn].*

--		AFTER FIELD scroll_flag 
--			--#IF fgl_lastkey() = fgl_keyval("accept")
--			--#AND fgl_fglgui() THEN
--			--# NEXT FIELD trans_date  #fixed 22.08.2018 NOTE there IS a pa.. AND l_rec_openitem record array
--			#--##   NEXT FIELD inv_date
--			--#END IF
--			LET l_arr_openitem[l_idx].scroll_flag = NULL 
--			IF fgl_lastkey() = fgl_keyval("down") THEN 
--				IF arr_curr() = arr_count() THEN 
--					ERROR kandoomsg2("A",9001,"") 
--					#9001 There no more rows...
--					NEXT FIELD scroll_flag 
--				END IF 
--			END IF 

		ON ACTION "Detail"		--BEFORE FIELD inv_date 
			IF (l_idx > 0) AND (l_idx <= l_arr_openitem.getSize()) THEN 

				IF l_arr_openitem[l_idx].trans_num IS NOT NULL THEN 
					CASE 
						WHEN l_arr_itemtype[l_idx].trans_type = TRAN_TYPE_INVOICE_IN 
							CALL lineshow(
								p_cmpy, 
								l_rec_customer.cust_code, 
								l_arr_openitem[l_idx].trans_num, 
								NULL) 
						WHEN l_arr_itemtype[l_idx].trans_type = TRAN_TYPE_CREDIT_CR 
							CALL cr_disp_head(
								p_cmpy, 
								l_rec_customer.cust_code, 
								l_arr_openitem[l_idx].trans_num) 
						WHEN l_arr_itemtype[l_idx].trans_type = TRAN_TYPE_RECEIPT_CA 
							CALL cash_disp(
								p_cmpy, 
								l_rec_customer.cust_code, 
								l_arr_openitem[l_idx].trans_num) 
					END CASE 
				END IF 

				NEXT FIELD scroll_flag 
			END IF

	END DISPLAY

	CLOSE WINDOW A643 
	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION
##################################################################
# FUNCTION cinq_openitems(p_cmpy,p_cust_code,p_overdue_amt,p_baddue_amt)
##################################################################