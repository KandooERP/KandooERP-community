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
# \brief module GCEd - Receipt Entry, Validation & Apply
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GCE_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION receipt_entry(p_rec_bankstatement,p_seq_num)
#
#
###########################################################################
FUNCTION receipt_entry(p_rec_bankstatement,p_seq_num) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE p_seq_num INTEGER 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_currency_ind char(1) ### (1)-> bank = base & cust = base 
	### (2)-> Bank = base & Cust = foreign
	### (3)-> Bank = foreign & Cust = foreign
	DEFINE l_save_remitted_amt LIKE bankstatement.tran_amt 
	DEFINE l_save_conv_qty LIKE bankstatement.conv_qty 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_ans char(1) 
	DEFINE l_last_field char(4) 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT customer.* INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = p_rec_bankstatement.ref_code 
	LET p_rec_bankstatement.ref_currency_code = l_rec_customer.currency_code 
	IF p_rec_bankstatement.bank_currency_code = glob_rec_glparms.base_currency_code THEN 
		IF p_rec_bankstatement.ref_currency_code = 
		p_rec_bankstatement.bank_currency_code THEN 
			LET l_currency_ind = "1" 
			LET p_rec_bankstatement.conv_qty = 1 
			LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
		ELSE 
			LET l_currency_ind = "2" 
			IF p_rec_bankstatement.conv_qty IS NULL 
			OR p_rec_bankstatement.conv_qty = 0 THEN 
				LET p_rec_bankstatement.conv_qty = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					p_rec_bankstatement.ref_currency_code, 
					p_rec_bankstatement.tran_date,
					CASH_EXCHANGE_SELL) 
			END IF 
			
			LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt * p_rec_bankstatement.conv_qty 
		END IF 
	ELSE 
	
		LET l_currency_ind = "3" 
		LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
		LET p_rec_bankstatement.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			p_rec_bankstatement.ref_currency_code, 
			p_rec_bankstatement.tran_date,
			CASH_EXCHANGE_SELL) 
	END IF
	 
	LET l_save_remitted_amt = p_rec_bankstatement.other_amt 
	LET l_save_conv_qty = p_rec_bankstatement.conv_qty 

	OPEN WINDOW G411 with FORM "G411" 
	CALL windecoration_g("G411") 

	DISPLAY BY NAME p_rec_bankstatement.ref_code, 
	l_rec_customer.name_text, 
	p_rec_bankstatement.tran_date, 
	p_rec_bankstatement.tran_amt, 
	p_rec_bankstatement.other_amt, 
	p_rec_bankstatement.conv_qty, 
	p_rec_bankstatement.year_num, 
	p_rec_bankstatement.period_num, 
	p_rec_bankstatement.acct_code, 
	p_rec_bankstatement.entry_code, 
	p_rec_bankstatement.entry_date 

	DISPLAY BY NAME p_rec_bankstatement.bank_currency_code, 
	p_rec_bankstatement.ref_currency_code 

	LET l_msgresp = kandoomsg("A",1093,"") 

	#1064" Enter Receipt Details - F8 FOR Account Status"
	INPUT BY NAME p_rec_bankstatement.ref_num, 
	p_rec_bankstatement.other_amt, 
	p_rec_bankstatement.conv_qty, 
	p_rec_bankstatement.year_num, 
	p_rec_bankstatement.period_num, 
	p_rec_bankstatement.com1_text, 
	p_rec_bankstatement.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEd","inp-bankstatement1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (f8) 

			OPEN WINDOW A204 with FORM "A204" 
			CALL windecoration_a("A204") 

			DISPLAY BY NAME l_rec_customer.curr_amt, 
			l_rec_customer.over1_amt, 
			l_rec_customer.over30_amt, 
			l_rec_customer.over60_amt, 
			l_rec_customer.over90_amt, 
			l_rec_customer.bal_amt, 
			l_rec_customer.onorder_amt, 
			l_rec_customer.cred_limit_amt, 
			l_rec_customer.last_pay_date 

			CALL eventsuspend() # LET l_ans = kandoomsg("U",1,"") 
			CLOSE WINDOW A204 

		AFTER FIELD ref_num 
			IF p_rec_bankstatement.ref_num = 0 THEN 
				LET p_rec_bankstatement.ref_num = NULL 
			END IF 
			LET l_last_field = "cheq" 

		BEFORE FIELD other_amt 
			IF l_currency_ind != "2" THEN 
				IF l_last_field = "cheq" THEN 
					NEXT FIELD conv_qty 
				ELSE 
					NEXT FIELD ref_num 
				END IF 
			END IF 

		AFTER FIELD other_amt 
			IF p_rec_bankstatement.other_amt IS NULL 
			OR p_rec_bankstatement.other_amt = 0 THEN 
				LET p_rec_bankstatement.other_amt = l_save_remitted_amt 
				DISPLAY BY NAME p_rec_bankstatement.other_amt 

				LET l_msgresp = kandoomsg("U",9102,"") 
				# Value must be entered
				NEXT FIELD other_amt 
			END IF 
			LET p_rec_bankstatement.conv_qty = p_rec_bankstatement.other_amt 
			/ p_rec_bankstatement.tran_amt 
			DISPLAY BY NAME p_rec_bankstatement.conv_qty 

			LET l_last_field = "rmit" 

		BEFORE FIELD conv_qty 
			IF l_currency_ind = "1" THEN 
				IF l_last_field = "year" THEN 
					NEXT FIELD other_amt 
				ELSE 
					NEXT FIELD year_num 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF p_rec_bankstatement.conv_qty IS NULL 
			OR p_rec_bankstatement.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				# Value must be entered
				LET p_rec_bankstatement.conv_qty = l_save_conv_qty 
				NEXT FIELD conv_qty 
			END IF 
			IF l_currency_ind = "2" THEN 
				LET p_rec_bankstatement.other_amt = p_rec_bankstatement.tran_amt 
				* p_rec_bankstatement.conv_qty 
				DISPLAY BY NAME p_rec_bankstatement.other_amt 

			END IF 
			LET l_last_field = "conv_qty" 

		AFTER FIELD year_num 
			LET l_last_field = "year_num" 

		AFTER FIELD period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,p_rec_bankstatement.year_num, 
			p_rec_bankstatement.period_num,"AR") 
			RETURNING p_rec_bankstatement.year_num, 
			p_rec_bankstatement.period_num, 
			l_invalid_period 
			IF l_invalid_period THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_rec_bankstatement.ref_num IS NOT NULL THEN 
					CALL banking(p_rec_bankstatement.*) 
					RETURNING p_rec_bankstatement.ref_text, 
					p_rec_bankstatement.desc_text 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code, p_rec_bankstatement.year_num, 
				p_rec_bankstatement.period_num,"AR") 
				RETURNING p_rec_bankstatement.year_num, 
				p_rec_bankstatement.period_num, 
				l_invalid_period 
				IF l_invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
				UPDATE t_bkstate 
				SET bank_currency_code = p_rec_bankstatement.bank_currency_code, 
				ref_currency_code = p_rec_bankstatement.ref_currency_code, 
				conv_qty = p_rec_bankstatement.conv_qty, 
				ref_num = p_rec_bankstatement.ref_num, 
				year_num = p_rec_bankstatement.year_num, 
				period_num = p_rec_bankstatement.period_num, 
				other_amt = p_rec_bankstatement.other_amt, 
				type_code = "C", 
				disc_amt = 0, 
				ref_text = p_rec_bankstatement.ref_text, 
				desc_text = p_rec_bankstatement.desc_text, 
				com1_text = p_rec_bankstatement.com1_text, 
				com2_text = p_rec_bankstatement.com2_text 
				WHERE seq_num = p_seq_num 

				MENU "Receipt entry" 
					BEFORE MENU 
						CALL publish_toolbar("kandoo","GCEd","menu-receipt-entry") 

						HIDE option "Apply receipt" 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					COMMAND "Apply receipt" 
						IF NOT apply_receipt(p_rec_bankstatement.*,p_seq_num) THEN 
							LET quit_flag = false 
						ELSE 
							LET quit_flag = true 
						END IF 
						EXIT MENU 

					COMMAND "Modify receipt" 
						LET quit_flag = false 
						EXIT MENU 

					COMMAND KEY(interrupt,"E")"Exit" 
						LET quit_flag = true 
						EXIT MENU 

						--               COMMAND KEY (control-w)
						--                  CALL kandoohelp("")
				END MENU 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					LET l_msgresp=kandoomsg("A",1093,"") 
					#1064" Enter Receipt Details - F8 FOR Account Status"
					NEXT FIELD ref_num 
				END IF 
			END IF 

			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	CLOSE WINDOW g411 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION apply_receipt(p_rec_bankstatement,p_seq_num)
#
#
############################################################
FUNCTION apply_receipt(p_rec_bankstatement,p_seq_num) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE p_seq_num INTEGER 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_arr_rec_invoice DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		ref_num LIKE bankdetails.ref_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		tran_amt LIKE bankdetails.tran_amt, 
		disc_amt LIKE bankdetails.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 
	DEFINE l_arr_inv_disc_taken DYNAMIC ARRAY OF money(12,2) 
	DEFINE l_arr_inv_disc_amt DYNAMIC ARRAY OF money(12,2) 
	DEFINE l_arr_orig_paid_amt DYNAMIC ARRAY OF money(12,2) 
	DEFINE l_max_app_amt LIKE cashreceipt.applied_amt 
	DEFINE l_applied_amt LIKE cashreceipt.applied_amt 
	DEFINE l_save_amt LIKE invoicehead.total_amt 
	DEFINE l_save_disc LIKE invoicehead.disc_amt 
	--DEFINE l_save_inv LIKE invoicehead.inv_num
	DEFINE l_arr_size INTEGER 
	DEFINE l_idx INTEGER 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_recalc_ind char(1) 
	--DEFINE l_disc_taken_ind CHAR(1)
	DEFINE l_query_text char(500) 
	DEFINE l_where_text char(200) 
	DEFINE l_override_ind SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT inv_ref1_text 
	INTO l_rec_arparms.inv_ref1_text 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	OPEN WINDOW g413 with FORM "G413" 
	CALL windecoration_g("G413") 

	WHILE true 
		CLEAR FORM 
		SELECT sum(tran_amt + disc_amt) 
		INTO l_applied_amt 
		FROM t_bkdetl 
		WHERE seq_num = p_seq_num 
		IF l_applied_amt IS NULL THEN 
			LET l_applied_amt = 0 
		ELSE 
			IF l_applied_amt > p_rec_bankstatement.other_amt THEN 
				DELETE FROM t_bkdetl 
				WHERE seq_num = p_seq_num 
				CONTINUE WHILE 
			END IF 
		END IF 
		DISPLAY BY NAME l_rec_arparms.inv_ref1_text 
		DISPLAY BY NAME p_rec_bankstatement.ref_currency_code 

		DISPLAY BY NAME p_rec_bankstatement.other_amt 
		DISPLAY l_applied_amt TO applied_amt

		IF p_rec_bankstatement.doc_num > 0 THEN 
			SELECT inv_num INTO l_rec_invoicehead.inv_num 
			FROM invoicehead 
			WHERE doc_num = p_rec_bankstatement.doc_num 
			AND (total_amt - paid_amt) = p_rec_bankstatement.other_amt 
			AND cust_code = p_rec_bankstatement.ref_code 
			IF status = NOTFOUND THEN 
				LET p_rec_bankstatement.doc_num = 0 
				CONTINUE WHILE 
			ELSE 
				LET l_where_text = " invoicehead.inv_num = ", 
				l_rec_invoicehead.inv_num," " 
			END IF 
		ELSE 
			LET l_msgresp=kandoomsg("G",1001,"") 
			#G1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT l_where_text ON inv_num FROM ref_num 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GCEd","construct-inv") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			ELSE 
				LET l_msgresp=kandoomsg("G",1002,"") 
				#G1002" Searching database - please wait"
			END IF 
		END IF 
		LET l_query_text = 
		"SELECT * FROM invoicehead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND cust_code = \"",p_rec_bankstatement.ref_code,"\" ", 
		"AND total_amt != paid_amt ", 
		"AND posted_flag NOT in (\"V\",\"H\") ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cust_code,", 
		"inv_num " 
		PREPARE s_invoice FROM l_query_text 
		DECLARE c_invoice CURSOR FOR s_invoice 
		LET l_idx = 0 
		LET l_recalc_ind = get_kandoooption_feature_state("AR","PT") 
		IF get_kandoooption_feature_state("AR","01") = "Y" THEN 
			LET l_override_ind = true 
		ELSE 
			LET l_override_ind = false 
		END IF 

		FOREACH c_invoice INTO l_rec_invoicehead.* 
			LET l_save_amt = sum_invoice_apps(l_rec_invoicehead.inv_num, 
			p_seq_num) 
			IF l_rec_invoicehead.total_amt = 
			(l_rec_invoicehead.paid_amt + l_save_amt) THEN 
				CONTINUE FOREACH 
			END IF 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_invoice[l_idx].ref_num = l_rec_invoicehead.inv_num 
			LET l_arr_rec_invoice[l_idx].purchase_code =l_rec_invoicehead.purchase_code 
			SELECT tran_amt, 
			disc_amt 
			INTO l_arr_rec_invoice[l_idx].tran_amt, 
			l_arr_rec_invoice[l_idx].disc_amt 
			FROM t_bkdetl 
			WHERE ref_num = l_rec_invoicehead.inv_num 
			AND seq_num = p_seq_num 
			IF status = NOTFOUND THEN 
				LET l_arr_rec_invoice[l_idx].tran_amt = 0 
			ELSE 
				LET l_arr_rec_invoice[l_idx].tran_amt = l_rec_invoicehead.total_amt 
				- l_rec_invoicehead.paid_amt 
			END IF 
			IF l_recalc_ind = 'Y' THEN 
				LET l_arr_rec_invoice[l_idx].disc_amt = l_rec_invoicehead.total_amt * 
				( show_disc( glob_rec_kandoouser.cmpy_code, 
				l_rec_invoicehead.term_code, 
				p_rec_bankstatement.tran_date, 
				l_rec_invoicehead.inv_date ) 
				/ 100 ) 
			ELSE 
				IF p_rec_bankstatement.tran_date <= l_rec_invoicehead.disc_date THEN 
					LET l_arr_rec_invoice[l_idx].disc_amt = l_rec_invoicehead.disc_amt 
				END IF 
			END IF 
			IF (l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt) 
			> (p_rec_bankstatement.tran_amt + l_arr_rec_invoice[l_idx].disc_amt) THEN 
				LET l_arr_rec_invoice[l_idx].disc_amt = 0 
			ELSE 
				LET l_arr_rec_invoice[l_idx].tran_amt = l_rec_invoicehead.total_amt 
				- l_rec_invoicehead.paid_amt 
				- l_arr_rec_invoice[l_idx].disc_amt 
			END IF 
			IF l_arr_rec_invoice[l_idx].disc_amt = 0 THEN 
				LET l_arr_inv_disc_taken[l_idx] = 0 
			ELSE 
				LET l_arr_inv_disc_taken[l_idx] = l_rec_invoicehead.disc_taken_amt 
			END IF 
			LET l_arr_inv_disc_amt[l_idx] = l_arr_rec_invoice[l_idx].disc_amt 
			LET l_arr_rec_invoice[l_idx].total_amt = l_rec_invoicehead.total_amt 
			LET l_arr_orig_paid_amt[l_idx] = l_rec_invoicehead.paid_amt + l_save_amt 
			LET l_arr_rec_invoice[l_idx].paid_amt = l_arr_orig_paid_amt[l_idx] 
			+ l_arr_rec_invoice[l_idx].tran_amt 
			+ l_arr_rec_invoice[l_idx].disc_amt 
			--         IF l_idx = 400 THEN
			--            #G9186 " Only first 400 invoices selected"
			--            LET l_msgresp=kandoomsg("G",9186,l_idx)
			--            EXIT FOREACH
			--         END IF
		END FOREACH 

		FREE s_invoice 
		LET l_arr_size = l_idx 
		CALL set_count(l_arr_size) 
		IF p_rec_bankstatement.doc_num > 0 THEN 
			IF l_save_amt > 0 THEN ### paid amt has changed 
				LET p_rec_bankstatement.doc_num = 0 
				CONTINUE WHILE 
			END IF 
			LET l_save_amt = l_arr_rec_invoice[1].tran_amt 
			DISPLAY l_arr_rec_invoice[1].* TO sr_invoice[1].* 

			SELECT due_date, 
			disc_date, 
			disc_taken_amt 
			INTO l_rec_invoicehead.due_date, 
			l_rec_invoicehead.disc_date, 
			l_rec_invoicehead.disc_taken_amt 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = l_arr_rec_invoice[l_idx].ref_num 
			LET l_rec_invoicehead.disc_amt = 0 
			DISPLAY l_rec_invoicehead.due_date, 
			l_rec_invoicehead.disc_date, 
			l_rec_invoicehead.disc_amt, 
			l_rec_invoicehead.disc_taken_amt 
			TO invoicehead.due_date, 
			invoicehead.disc_date, 
			invoicehead.disc_amt, 
			invoicehead.disc_taken_amt 


			MENU "Receipt application" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","GCEd","menu-receipt-application") 


				COMMAND "Apply" 
					" Apply this Receipt TO this invoice" 
					LET l_arr_rec_invoice[1].tran_amt = p_rec_bankstatement.other_amt 
					- l_arr_rec_invoice[1].disc_amt 
					LET l_arr_rec_invoice[1].paid_amt = l_arr_rec_invoice[1].paid_amt 
					+ l_arr_rec_invoice[1].tran_amt 
					+ l_arr_rec_invoice[1].disc_amt 
					- l_save_amt 
					DISPLAY l_arr_rec_invoice[1].* TO sr_invoice[1].* 

					LET l_applied_amt = l_arr_rec_invoice[1].tran_amt 
					+ l_arr_rec_invoice[1].disc_amt 
					DISPLAY l_applied_amt TO applied_amt  

					SLEEP 2 
					EXIT MENU 

				COMMAND "Re select" 
					" Re SELECT Invoices FOR Receipt application" 
					LET p_rec_bankstatement.doc_num = 0 
					EXIT MENU 

				COMMAND KEY(interrupt,"E")"Exit" 
					LET quit_flag = true 
					EXIT MENU 
					--            COMMAND KEY (control-w)
					--               CALL kandoohelp("")
			END MENU 

			DISPLAY "" at 1,1 
			DISPLAY "" at 2,1 
			IF p_rec_bankstatement.doc_num = 0 THEN 
				CONTINUE WHILE 
			END IF 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			LET l_msgresp = kandoomsg("A",1026,"") 
			#1026 Receipt Application; ENTER on line TO Apply
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			LET l_applied_amt = 0 
			LET l_arr_rec_invoice[1].tran_amt = 0 
			LET l_arr_rec_invoice[1].disc_amt = 0 
			LET l_arr_rec_invoice[1].paid_amt = 0 

			INPUT ARRAY l_arr_rec_invoice WITHOUT DEFAULTS FROM sr_invoice.* attributes(unbuffered) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","GCEd","inp-arr-invoice") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					#LET scrn = scr_line()
					SELECT * INTO l_rec_invoicehead.* 
					FROM invoicehead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND inv_num = l_arr_rec_invoice[l_idx].ref_num 
					DISPLAY l_rec_invoicehead.due_date, 
					l_rec_invoicehead.disc_date, 
					l_rec_invoicehead.disc_amt, 
					l_rec_invoicehead.disc_taken_amt 
					TO invoicehead.due_date, 
					invoicehead.disc_date, 
					invoicehead.disc_amt, 
					invoicehead.disc_taken_amt 

				BEFORE FIELD ref_num 
					LET l_save_amt = l_arr_rec_invoice[l_idx].tran_amt 
					LET l_rec_invoicehead.inv_num = l_arr_rec_invoice[l_idx].ref_num 

				AFTER FIELD ref_num 
					LET l_arr_rec_invoice[l_idx].ref_num = l_rec_invoicehead.inv_num 
					#DISPLAY l_arr_rec_invoice[l_idx].*
					#     TO sr_invoice[scrn].*

				BEFORE FIELD tran_amt 
					IF l_arr_rec_invoice[l_idx].ref_num = 0 THEN 
						NEXT FIELD inv_num 
					END IF 
					IF l_arr_rec_invoice[l_idx].tran_amt = 0 THEN 
						LET l_arr_rec_invoice[l_idx].tran_amt = p_rec_bankstatement.other_amt 
						- l_applied_amt 
						IF l_arr_rec_invoice[l_idx].total_amt >= 0 THEN 
							IF l_arr_rec_invoice[l_idx].tran_amt >= (l_arr_rec_invoice[l_idx].total_amt 
							- l_arr_rec_invoice[l_idx].paid_amt 
							- l_arr_rec_invoice[l_idx].disc_amt) THEN 
								LET l_arr_rec_invoice[l_idx].tran_amt = l_arr_rec_invoice[l_idx].total_amt 
								- l_arr_rec_invoice[l_idx].paid_amt 
								- l_arr_rec_invoice[l_idx].disc_amt 
							ELSE 
								LET l_arr_rec_invoice[l_idx].disc_amt = 0 
								IF ( 0 - ( p_rec_bankstatement.other_amt 
								- l_applied_amt ) ) 
								> ( l_arr_rec_invoice[l_idx].paid_amt 
								+ l_arr_rec_invoice[l_idx].disc_amt ) THEN 
									LET l_arr_rec_invoice[l_idx].tran_amt = 0 - l_arr_rec_invoice[l_idx].paid_amt 
								END IF 
							END IF 
						ELSE 
							IF l_arr_rec_invoice[l_idx].tran_amt <= (l_arr_rec_invoice[l_idx].total_amt 
							- l_arr_rec_invoice[l_idx].paid_amt) THEN 
								LET l_arr_rec_invoice[l_idx].tran_amt = l_arr_rec_invoice[l_idx].total_amt 
								- l_arr_rec_invoice[l_idx].paid_amt 
							END IF 
							IF l_arr_rec_invoice[l_idx].tran_amt > 0 THEN 
								LET l_arr_rec_invoice[l_idx].tran_amt = 0 
							END IF 
						END IF 
					END IF 
				AFTER FIELD tran_amt 
					IF l_arr_rec_invoice[l_idx].tran_amt IS NULL THEN 
						LET l_arr_rec_invoice[l_idx].tran_amt = l_save_amt 
						NEXT FIELD tran_amt 
					END IF 
					LET l_arr_rec_invoice[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
					+ l_arr_rec_invoice[l_idx].tran_amt 
					+ l_arr_rec_invoice[l_idx].disc_amt 
					NEXT FIELD disc_amt 

				BEFORE FIELD disc_amt 
					LET l_save_disc = 0 
					IF l_rec_invoicehead.posted_flag != "Y" THEN 
						IF l_recalc_ind = 'Y' THEN 
							LET l_save_disc = l_rec_invoicehead.total_amt * 
							( show_disc( glob_rec_kandoouser.cmpy_code, 
							l_rec_invoicehead.term_code, 
							p_rec_bankstatement.tran_date, 
							l_rec_invoicehead.inv_date ) 
							/ 100 ) 
						ELSE 
							IF p_rec_bankstatement.tran_date <= l_rec_invoicehead.disc_date THEN 
								LET l_save_disc = l_rec_invoicehead.disc_amt 
							END IF 
						END IF 
					END IF 
					IF l_save_disc = 0 THEN 
						NEXT FIELD total_amt 
					END IF 

				AFTER FIELD disc_amt 
					IF l_arr_rec_invoice[l_idx].disc_amt IS NULL 
					OR l_arr_rec_invoice[l_idx].disc_amt < 0 THEN 
						LET l_arr_rec_invoice[l_idx].disc_amt = l_save_disc 
						NEXT FIELD disc_amt 
					END IF 
					IF l_arr_rec_invoice[l_idx].disc_amt > 0 THEN 
						IF NOT l_override_ind THEN 
							IF l_arr_rec_invoice[l_idx].disc_amt > l_save_disc THEN 
								LET l_msgresp=kandoomsg("A",9139,l_save_disc) 
								#9139" Max. discount IS ",l_save_disc
								LET l_arr_rec_invoice[l_idx].disc_amt = l_save_disc 
								NEXT FIELD disc_amt #### tran_amt -> disc_amt 
							END IF 
						END IF 
					END IF 
					LET l_arr_rec_invoice[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
					+ l_arr_rec_invoice[l_idx].tran_amt 
					+ l_arr_rec_invoice[l_idx].disc_amt 
					NEXT FIELD total_amt 

				BEFORE FIELD total_amt 
					#DISPLAY l_arr_rec_invoice[l_idx].* TO sr_invoice[scrn].*

					IF l_arr_rec_invoice[l_idx].total_amt >= 0 THEN 
						IF (l_arr_rec_invoice[l_idx].tran_amt + l_arr_rec_invoice[l_idx].disc_amt) > 
						(l_arr_rec_invoice[l_idx].total_amt - l_rec_invoicehead.paid_amt) THEN 
							LET l_msgresp = kandoomsg("A",9136,"") 
							#9136 "Amount will overapply the invoice"
							NEXT FIELD tran_amt 
						END IF 
					ELSE 
						IF (l_arr_rec_invoice[l_idx].tran_amt + l_arr_rec_invoice[l_idx].disc_amt) < 
						(l_arr_rec_invoice[l_idx].total_amt - l_rec_invoicehead.paid_amt) THEN 
							LET l_msgresp = kandoomsg("A",9136,"") 
							#9136 "Amount will overapply the invoice"
							NEXT FIELD tran_amt 
						END IF 
					END IF 
					IF l_arr_rec_invoice[l_idx].disc_amt > 0 THEN 
						IF l_arr_rec_invoice[l_idx].total_amt != (l_arr_rec_invoice[l_idx].tran_amt 
						+ l_arr_rec_invoice[l_idx].disc_amt 
						+ l_rec_invoicehead.paid_amt) THEN 

							LET l_msgresp=kandoomsg("A",1510,"") 
							#A1510 Disc. amt. constrains full application of invoice
							LET l_msgresp=kandoomsg("A",9140,"") 
							#9140 " Must fully pay invoice TO get a discount"
							# BEFORE FIELD tran_amt sets the default IF tran_amt = 0
							LET l_arr_rec_invoice[l_idx].tran_amt = 0 

							LET l_arr_rec_invoice[l_idx].paid_amt = l_rec_invoicehead.paid_amt 
							+ l_arr_rec_invoice[l_idx].tran_amt 
							LET l_arr_rec_invoice[l_idx].disc_amt = 0 
							#DISPLAY l_arr_rec_invoice[l_idx].* TO sr_invoice[scrn].*


							NEXT FIELD tran_amt 
						END IF 
					END IF 
					LET l_applied_amt = l_applied_amt 
					+ l_arr_rec_invoice[l_idx].tran_amt 
					- l_save_amt 
					LET l_save_amt = l_arr_rec_invoice[l_idx].tran_amt 
					DISPLAY l_applied_amt TO applied_amt

					IF p_rec_bankstatement.other_amt >= 0 THEN 
						IF l_applied_amt > p_rec_bankstatement.other_amt 
						OR l_applied_amt < 0 THEN 
							LET l_msgresp=kandoomsg("A",9141,"") 
							#9141 " This entry will overapply the receipt"
							NEXT FIELD tran_amt 
						END IF 
					ELSE 
						IF l_applied_amt < p_rec_bankstatement.other_amt 
						OR l_applied_amt > 0 THEN 
							LET l_msgresp=kandoomsg("A",9141,"") 
							#9141 " This entry will overapply the receipt"
							NEXT FIELD tran_amt 
						END IF 
					END IF 
					IF l_applied_amt = p_rec_bankstatement.other_amt THEN 

						MENU " Receipt has been fully applied" 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","GCEd","menu-receipt-fully-applied") 

							ON ACTION "WEB-HELP" 
								CALL onlinehelp(getmoduleid(),null) 

							ON ACTION "actToolbarManager" 
								CALL setuptoolbar() 


							COMMAND "Continue" 
								EXIT MENU 

							COMMAND KEY(interrupt,"E")"Exit" 
								LET quit_flag = true 
								EXIT MENU 

								--                   COMMAND KEY (control-w)
								--                      CALL kandoohelp("")
						END MENU 

						IF int_flag OR quit_flag THEN 
							LET l_msgresp = kandoomsg("A",1026,"") 
							#1026 Receipt Application; ENTER on line TO Apply
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD inv_num 
						ELSE 
							EXIT INPUT 
						END IF 
					END IF 

				AFTER INPUT 
					IF not(int_flag OR quit_flag) THEN 
						IF p_rec_bankstatement.other_amt >= 0 THEN 
							IF l_applied_amt > p_rec_bankstatement.other_amt 
							OR l_applied_amt < 0 THEN 
								LET l_msgresp=kandoomsg("A",9142,"") 
								#9142 " Receipt has been over applied"
								NEXT FIELD inv_num 
							END IF 
						ELSE 
							IF l_applied_amt < p_rec_bankstatement.other_amt 
							OR l_applied_amt > 0 THEN 
								LET l_msgresp=kandoomsg("A",9142,"") 
								#9142 " Negative Receipt has been over applied"
								NEXT FIELD inv_num 
							END IF 
						END IF 
					END IF 
					--            ON KEY (control-w)
					--               CALL kandoohelp("")
			END INPUT 

		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g413 
	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	FOR l_idx = 1 TO l_arr_size 
		DELETE FROM t_bkdetl 
		WHERE seq_num = p_seq_num 
		AND ref_num = l_arr_rec_invoice[l_idx].ref_num 
		IF l_arr_rec_invoice[l_idx].tran_amt != 0 THEN 
			SELECT conv_qty 
			INTO l_rec_invoicehead.conv_qty 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = l_arr_rec_invoice[l_idx].ref_num 
			IF status = NOTFOUND THEN 
				CONTINUE FOR 
			END IF 

			INSERT INTO t_bkdetl VALUES (p_seq_num, 
			p_rec_bankstatement.ref_code, 
			l_arr_rec_invoice[l_idx].ref_num, 
			"", 
			l_arr_rec_invoice[l_idx].tran_amt, 
			l_arr_rec_invoice[l_idx].disc_amt, 
			"", 
			"", 
			l_rec_invoicehead.conv_qty) 
		END IF 
	END FOR 
	### Do NOT remove following code - <Suse> bug
	IF true THEN 
	END IF 

	UPDATE t_bkstate 
	SET doc_num = p_rec_bankstatement.doc_num 
	WHERE seq_num = p_seq_num 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION banking(p_rec_bankstatement)
#
#
############################################################
FUNCTION banking(p_rec_bankstatement) 
	DEFINE p_rec_bankstatement RECORD LIKE bankstatement.* 
	DEFINE l_branch_text char(10) 
	DEFINE l_drawer_text char(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g412 with FORM "G412" 
	CALL windecoration_g("G412") 

	IF p_rec_bankstatement.desc_text IS NULL THEN 
		SELECT name_text INTO l_drawer_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_rec_bankstatement.ref_code 
	ELSE 
		LET l_drawer_text = p_rec_bankstatement.desc_text[1,20] 
		LET l_branch_text = p_rec_bankstatement.desc_text[21,30] 
	END IF 
	DISPLAY BY NAME p_rec_bankstatement.ref_num, 
	p_rec_bankstatement.tran_date, 
	p_rec_bankstatement.ref_text
	DISPLAY l_branch_text TO branch_text 
	DISPLAY l_drawer_text TO drawer_text 


	INPUT 
		p_rec_bankstatement.ref_text, 
		l_branch_text, 
		l_drawer_text WITHOUT DEFAULTS 
	FROM
		ref_text, 
		branch_text, 
		drawer_text ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GCEd","inp-bankstatement2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	CLOSE WINDOW g412 
	LET p_rec_bankstatement.desc_text = l_drawer_text,l_branch_text 
	LET int_flag = false 
	LET quit_flag = false 

	RETURN p_rec_bankstatement.ref_text, 
	p_rec_bankstatement.desc_text 
END FUNCTION 


############################################################
# FUNCTION sum_invoice_apps(p_inv_num,p_seq_num)
#
#
# This FUNCTION sums all the unposted invoice applications
# made by other bank's statements OR other sheets FOR this bank.
#
############################################################
FUNCTION sum_invoice_apps(p_inv_num,p_seq_num) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_seq_num INTEGER 
	DEFINE l_sum_this_sheet LIKE bankdetails.tran_amt 
	DEFINE l_sum_this_bank LIKE bankdetails.tran_amt 
	DEFINE l_sum_other_banks LIKE bankdetails.tran_amt 
	DEFINE l_sum_total_app LIKE bankdetails.tran_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_this_sheet 
	FROM t_bkdetl 
	WHERE ref_num = p_inv_num 
	AND seq_num != p_seq_num 
	AND ((select entry_type_code 
	FROM t_bkstate 
	WHERE seq_num = t_bkdetl.seq_num) = "RE") 
	IF l_sum_this_sheet IS NULL THEN 
		LET l_sum_this_sheet = 0 
	END IF 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_this_bank 
	FROM bankdetails 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num != glob_rec_bank.sheet_num 
	AND ref_num = p_inv_num 
	AND sheet_num > (select sheet_num 
	FROM bank 
	WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank.bank_code = glob_rec_bank.bank_code) 
	AND (select entry_type_code 
	FROM bankstatement 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = glob_rec_bank.bank_code 
	AND sheet_num = bankdetails.sheet_num 
	AND seq_num = bankdetails.seq_num) = "RE" 
	IF l_sum_this_bank IS NULL THEN 
		LET l_sum_this_bank = 0 
	END IF 

	SELECT sum(tran_amt + disc_amt) 
	INTO l_sum_other_banks 
	FROM bankdetails 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code != glob_rec_bank.bank_code 
	AND ref_num = p_inv_num 
	AND (select entry_type_code 
	FROM bankstatement 
	WHERE cmpy_code = bankdetails.cmpy_code 
	AND bank_code = bankdetails.bank_code 
	AND sheet_num = bankdetails.sheet_num 
	AND seq_num = bankdetails.seq_num ) = "RE" 
	AND sheet_num > (select sheet_num 
	FROM bank 
	WHERE cmpy_code = bankdetails.cmpy_code 
	AND bank_code = bankdetails.bank_code) 
	IF l_sum_other_banks IS NULL THEN 
		LET l_sum_other_banks = 0 
	END IF 

	LET l_sum_total_app = l_sum_this_sheet 
	+ l_sum_this_bank 
	+ l_sum_other_banks 

	RETURN l_sum_total_app 
END FUNCTION 
