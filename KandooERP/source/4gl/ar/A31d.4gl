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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A31_GLOBALS.4gl"

##########################################################################
# FUNCTION invoice_scan(p_cmpy_code, p_cash_date)
#
# p_cust_code added huho 28.11.19 to select only invoice belonging to this customer by default
#
# \brief module - A31d.4gl
#
# FUNCTION:    invoice_scan
# Description: Allows the user TO scan invoices FOR customers.
# Returns:     customer code
##########################################################################
FUNCTION invoice_scan(p_cmpy_code, p_cash_date, p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_cash_date LIKE cashreceipt.cash_date 
	DEFINE p_cust_code LIKE cashreceipt.cust_code #glob_rec_cashreceipt.cust_code 
	DEFINE l_inv_num LIKE invoicehead.inv_num 
	DEFINE l_exit_flag CHAR(1) 

	OPEN WINDOW A692 with FORM "A692" 
	CALL windecoration_a("A692") 

--	WHILE db_invoicehead_customer_get_datasource(p_cmpy_code,p_cust_code, false) 
--		CALL inv_scan(p_cmpy_code, p_cash_date) 
--		RETURNING l_exit_flag, l_inv_num 
--		
--		IF l_exit_flag = true THEN 
--			EXIT WHILE 
--		END IF 
--	END WHILE 


		CALL inv_scan(p_cmpy_code, p_cust_code,p_cash_date) RETURNING l_inv_num 

	CLOSE WINDOW A692 

	RETURN l_inv_num 
END FUNCTION 
##########################################################################
# END FUNCTION invoice_scan(p_cmpy_code, p_cash_date)
##########################################################################


##########################################################################
# FUNCTION db_invoicehead_customer_get_datasource(p_cmpy_code,p_cash_date,p_cust_code,p_filter)
#
#
##########################################################################
FUNCTION db_invoicehead_customer_get_datasource(p_cmpy_code,p_cash_date,p_cust_code,p_filter) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_cash_date LIKE cashreceipt.cash_date 
	DEFINE p_cust_code LIKE cashreceipt.cust_code #glob_rec_cashreceipt.cust_code 
	DEFINE p_filter boolean 

	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF A30_glob_dt_rec_invoicehead
	DEFINE l_arr_rec_invoicehead_discount DYNAMIC ARRAY OF A30_glob_dt_rec_invoicehead_discount 

	DEFINE l_where_text CHAR(1500) 
	DEFINE l_where2_text CHAR(1500) 
	DEFINE l_query_text CHAR(2000) 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_use_outer SMALLINT 
	DEFINE l_where2_length SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_letter CHAR(1) 
	DEFINE l_word CHAR(20) 
	DEFINE l_idx smallint

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1078,"") 		#1001 Enter Selection Criteria;  OK TO Continue;  F8 Extended Criteria.
		CONSTRUCT BY NAME l_where_text ON 
			invoicehead.inv_num, 
			invoicehead.purchase_code, 
			invoicehead.inv_date, 
			invoicehead.total_amt, 
			invoicehead.paid_amt, 
			invoicehead.cust_code, 
			invoicehead.due_date, 
			invoicehead.disc_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A31d","construct-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "INVOICE SCAN" 
				#ON KEY(F8)
				OPEN WINDOW A192 with FORM "A192" 
				CALL windecoration_a("A192") 

				MESSAGE kandoomsg2("U",1001,"") 				#1001 Enter Selection Criteria; OK TO Continue.
				SELECT inv_ref1_text INTO l_ref_text FROM arparms 
				WHERE cmpy_code = p_cmpy_code 
				AND parm_code = "1" 
				
				LET l_ref_text = l_ref_text clipped,"................" 
				DISPLAY l_ref_text TO arparms.inv_ref1_text 

				CONSTRUCT l_where2_text ON 
					invoicehead.cust_code, 
					customer.name_text, 
					invoicehead.org_cust_code, 
					o_cust.name_text, 
					invoicehead.inv_num, 
					invoicehead.inv_ind, 
					invoicehead.ord_num, 
					invoicehead.job_code, 
					customer.currency_code, 
					invoicehead.goods_amt, 
					invoicehead.tax_amt, 
					invoicehead.hand_amt, 
					invoicehead.freight_amt, 
					invoicehead.total_amt, 
					invoicehead.paid_amt, 
					invoicehead.inv_date, 
					invoicehead.due_date, 
					invoicehead.disc_date, 
					invoicehead.paid_date, 
					invoicehead.disc_amt, 
					invoicehead.disc_taken_amt, 
					invoicehead.year_num, 
					invoicehead.period_num, 
					invoicehead.posted_flag, 
					invoicehead.on_state_flag, 
					invoicehead.ref_num, 
					invoicehead.purchase_code, 
					invoicehead.sale_code, 
					invoicehead.entry_code, 
					invoicehead.entry_date, 
					invoicehead.rev_date, 
					invoicehead.rev_num, 
					invoicehead.com1_text, 
					invoicehead.com2_text 
				FROM 
					invoicehead.cust_code, 
					customer.name_text, 
					invoicehead.org_cust_code, 
					formonly.org_name_text, 
					invoicehead.inv_num, 
					invoicehead.inv_ind, 
					invoicehead.ord_num, 
					invoicehead.job_code, 
					customer.currency_code, 
					invoicehead.goods_amt, 
					invoicehead.tax_amt, 
					invoicehead.hand_amt, 
					invoicehead.freight_amt, 
					invoicehead.total_amt, 
					invoicehead.paid_amt, 
					invoicehead.inv_date, 
					invoicehead.due_date, 
					invoicehead.disc_date, 
					invoicehead.paid_date, 
					invoicehead.disc_amt, 
					invoicehead.disc_taken_amt, 
					invoicehead.year_num, 
					invoicehead.period_num, 
					invoicehead.posted_flag, 
					invoicehead.on_state_flag, 
					invoicehead.ref_num, 
					invoicehead.purchase_code, 
					invoicehead.sale_code, 
					invoicehead.entry_code, 
					invoicehead.entry_date, 
					invoicehead.rev_date, 
					invoicehead.rev_num, 
					invoicehead.com1_text, 
					invoicehead.com2_text 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 

				CLOSE WINDOW A192 
				EXIT CONSTRUCT 


		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where2_text = " 1=1 " 
			LET l_where_text = " 1=1 " 
			--RETURN FALSE
		END IF 

	ELSE 
		LET l_where2_text = " 1=1 " 
		LET l_where_text = " 1=1 " 

	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 Searching Database;  Please wait.
	IF l_ref_text IS NOT NULL THEN 
		LET l_use_outer = false 
		LET l_where2_length = length(l_where2_text) 
		LET l_word = "" 
		
		#---------------------------------
		FOR l_counter = 1 TO l_where2_length 
			LET l_letter = l_where2_text[l_counter,(l_counter+1)] 
		
			IF l_letter = " " OR 
			l_letter = "=" OR 
			l_letter = "(" OR 
			l_letter = ")" OR 
			l_letter = "[" OR 
			l_letter = "]" OR 
			l_letter = "." OR 
			l_letter = "," THEN 
				LET l_word = "" 
			END IF 
		
			LET l_word = l_word clipped,l_letter 
		
			IF l_word = "o_cust" THEN 
				LET l_use_outer = true 
				EXIT FOR 
			END IF 
		
		END FOR
		#---------------- 

		IF l_use_outer = true THEN 
			LET l_query_text = 
				"SELECT inv_num,purchase_code,inv_date, total_amt, ", 
				"paid_amt,due_date,disc_date,disc_amt, ", 
				"disc_taken_amt,invoicehead.cust_code, ", 
				"invoicehead.term_code ", 
				"FROM invoicehead, customer, customer o_cust ", 
				"WHERE invoicehead.cmpy_code = '",p_cmpy_code,"' ", 
				"AND customer.cust_code = invoicehead.cust_code ", 
				"AND customer.cmpy_code = invoicehead.cmpy_code ", 
				"AND o_cust.cust_code = invoicehead.org_cust_code ", 
				"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
				"AND total_amt != paid_amt ", 
				"AND ",l_where2_text clipped," " 

			IF p_cust_code IS NOT NULL THEN 
				LET l_query_text = trim(l_query_text), " AND cust_code = '" ,trim(p_cust_code), "' " 
			END IF 

			LET l_query_text = trim(l_query_text), " ORDER BY inv_num" 

		ELSE 
			LET l_query_text = 
				"SELECT inv_num,purchase_code,inv_date,total_amt, ", 
				"paid_amt,due_date,disc_date,disc_amt, ", 
				"disc_taken_amt,invoicehead.cust_code, ", 
				"invoicehead.term_code ", 
				"FROM invoicehead,customer ", 
				"WHERE invoicehead.cmpy_code = '",p_cmpy_code,"' ", 
				"AND customer.cust_code = invoicehead.cust_code ", 
				"AND customer.cmpy_code = invoicehead.cmpy_code ", 
				"AND total_amt != paid_amt ", 
				"AND ",l_where2_text clipped," " 

			IF p_cust_code IS NOT NULL THEN 
				LET l_query_text = trim(l_query_text), " AND cust_code = '" ,trim(p_cust_code), "' " 
			END IF 

		END IF 
	ELSE 
		LET l_query_text = 
			"SELECT inv_num,purchase_code,inv_date,total_amt, ", 
			"paid_amt,due_date,disc_date,disc_amt, ", 
			"disc_taken_amt,cust_code,invoicehead.term_code ", 
			"FROM invoicehead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND total_amt != paid_amt ", 
			"AND ", l_where_text clipped," " 

		IF p_cust_code IS NOT NULL THEN 
			LET l_query_text = trim(l_query_text), " AND cust_code = '" ,trim(p_cust_code), "' " 
		END IF 

		LET l_query_text = trim(l_query_text), " ORDER BY inv_num " 
	END IF 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 

--	RETURN true

			LET l_idx = 0 

			FOREACH c_invoicehead INTO 
				glob_rec_invoicehead.inv_num, 
				glob_rec_invoicehead.purchase_code, 
				glob_rec_invoicehead.inv_date, 
				glob_rec_invoicehead.total_amt, 
				glob_rec_invoicehead.paid_amt, 
				glob_rec_invoicehead.due_date, 
				glob_rec_invoicehead.disc_date, 
				glob_rec_invoicehead.disc_amt, 
				glob_rec_invoicehead.disc_taken_amt, 
				glob_rec_invoicehead.cust_code, 
				glob_rec_invoicehead.term_code 

				LET l_idx = l_idx + 1 
				LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
				LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
				LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
				LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
				LET l_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
				LET l_arr_rec_invoicehead_discount[l_idx].due_date = glob_rec_invoicehead.due_date 
				LET l_arr_rec_invoicehead_discount[l_idx].disc_date = glob_rec_invoicehead.disc_date 
				LET l_arr_rec_invoicehead_discount[l_idx].disc_amt = glob_rec_invoicehead.total_amt * 
					show_disc(
						p_cmpy_code, 
						glob_rec_invoicehead.term_code, 
						p_cash_date, 
						glob_rec_invoicehead.inv_date) 	/ 100 

				LET l_arr_rec_invoicehead_discount[l_idx].disc_taken_amt = glob_rec_invoicehead.disc_taken_amt 
				LET l_arr_rec_invoicehead_discount[l_idx].cust_code = glob_rec_invoicehead.cust_code 

				IF l_idx = glob_rec_settings.maxListArraySize THEN
					MESSAGE kandoomsg2("U",6100,l_idx)
					EXIT FOREACH
				END IF	
			END FOREACH 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

			IF l_idx = 0 THEN 
				ERROR kandoomsg2("U",9101,"") 			#9101 No rows satisfied selection criteria.
				RETURN false, "" 
			END IF 

			MESSAGE kandoomsg2("U",9113,l_idx) 		#9113 l_idx records selected.

	RETURN l_arr_rec_invoicehead,l_arr_rec_invoicehead_discount 
END FUNCTION 
##########################################################################
# END FUNCTION db_invoicehead_customer_get_datasource(p_cmpy_code,p_cash_date,p_cust_code,p_filter)
##########################################################################


##########################################################################
# FUNCTION inv_scan(p_cmpy_code,p_cust_code,p_cash_date) 
#
# This function seems TO only show all invoices - select AND return invoice head
##########################################################################
FUNCTION inv_scan(p_cmpy_code,p_cust_code,p_cash_date) 
	DEFINE p_cmpy_code LIKE company.cmpy_code #huho may NOT used 
	DEFINE p_cust_code LIKE cashreceipt.cust_code #glob_rec_cashreceipt.cust_code 
	DEFINE p_cash_date LIKE cashreceipt.cash_date 

	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF A30_glob_dt_rec_invoicehead
--		RECORD 
--			scroll_flag CHAR(1), 
--			inv_num LIKE invoicehead.inv_num, 
--			purchase_code LIKE invoicehead.purchase_code, 
--			inv_date LIKE invoicehead.inv_date, 
--			total_amt LIKE invoicehead.total_amt, 
--			paid_amt LIKE invoicehead.paid_amt 
--		END RECORD 
		DEFINE l_arr_rec_invoicehead_discount DYNAMIC ARRAY OF A30_glob_dt_rec_invoicehead_discount 
--			RECORD 
--				due_date LIKE invoicehead.due_date, 
--				disc_date LIKE invoicehead.disc_date, 
--				disc_amt LIKE invoicehead.disc_amt, 
--				disc_taken_amt LIKE invoicehead.disc_taken_amt, 
--				cust_code LIKE invoicehead.cust_code 
--			END RECORD 

			DEFINE l_pay_text LIKE invoicepay.pay_text 
			--DEFINE l_scroll_flag CHAR(1) 
			DEFINE l_idx smallint#, 

			#DATSOURCE
			CALL db_invoicehead_customer_get_datasource(p_cmpy_code,p_cust_code, p_cash_date,false) 
			RETURNING 
				l_arr_rec_invoicehead,
				l_arr_rec_invoicehead_discount 

			#DISPLAY ARRAY ---------------------------------------------------------------------------
			MESSAGE kandoomsg2("U",1008,"") 		#1008 F3/F4 TO Page Fwd/Bwd;  OK TO Continue.
			DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","A31d","inp-arr-invoicehead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 

					#      BEFORE FIELD scroll_flag
					#         LET l_idx = arr_curr()
					#         #LET scrn = scr_line()
					#         LET l_scroll_flag = l_arr_rec_invoicehead[l_idx].scroll_flag
					#         #DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*
					#

         DISPLAY l_arr_rec_invoicehead_discount[l_idx].due_date TO invoicehead.due_date
         DISPLAY l_arr_rec_invoicehead_discount[l_idx].disc_date TO invoicehead.disc_date
         DISPLAY l_arr_rec_invoicehead_discount[l_idx].disc_amt TO invoicehead.disc_amt
         DISPLAY l_arr_rec_invoicehead_discount[l_idx].disc_taken_amt TO invoicehead.disc_taken_amt
         DISPLAY l_arr_rec_invoicehead_discount[l_idx].cust_code TO invoicehead.cust_code

					#ON ACTION "ACCEPT"
					#LET l_arr_rec_invoicehead[l_idx].scroll_flag = l_scroll_flag
					#IF fgl_lastkey() = fgl_keyval("down")
					#OR fgl_lastkey() = fgl_keyval("right")
					#OR fgl_lastkey() = fgl_keyval("tab")
					#OR fgl_lastkey() = fgl_keyval("RETURN") THEN
					#   IF l_idx >= arr_count() THEN
					#      ERROR kandoomsg2("W",9001,"")				#      #9001 There no more rows in the direction ...
					#      NEXT FIELD scroll_flag
					#   END IF
					#   IF l_arr_rec_invoicehead[l_idx+1].inv_num IS NULL
					#   OR arr_curr() >= arr_count() THEN
					#      ERROR kandoomsg2("W",9001,"")				#      #9001 There no more rows in the direction ...
					#      NEXT FIELD scroll_flag
					#   END IF
					#END IF

					#      AFTER FIELD scroll_flag
					#         LET l_arr_rec_invoicehead[l_idx].scroll_flag = l_scroll_flag
					#         IF fgl_lastkey() = fgl_keyval("down")
					#         OR fgl_lastkey() = fgl_keyval("right")
					#         OR fgl_	lastkey() = fgl_keyval("tab")
					#         OR fgl_lastkey() = fgl_keyval("RETURN") THEN
					#            IF l_idx >= arr_count() THEN
					#               ERROR kandoomsg2("W",9001,"")				#               #9001 There no more rows in the direction ...
					#               NEXT FIELD scroll_flag
					#            END IF
					#            IF l_arr_rec_invoicehead[l_idx+1].inv_num IS NULL
					#            OR arr_curr() >= arr_count() THEN
					#               ERROR kandoomsg2("W",9001,"")				#               #9001 There no more rows in the direction ...
					#               NEXT FIELD scroll_flag
					#            END IF
					#         END IF


					#AFTER ROW
					#   DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*


			END DISPLAY 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN NULL 
			END IF 

			RETURN l_arr_rec_invoicehead[l_idx].inv_num 
END FUNCTION 
##########################################################################
# END FUNCTION inv_scan(p_cmpy_code,p_cust_code,p_cash_date) 
##########################################################################


##########################################################################
# FUNCTION calc_cash_amt(p_cmpy_code, p_cash_date, p_rec_invoicehead) 
#
#
##########################################################################
FUNCTION calc_cash_amt(p_cmpy_code, p_cash_date, p_rec_invoicehead) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cash_date LIKE cashreceipt.cash_date 
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.* 

	DEFINE l_cash_amt LIKE cashreceipt.cash_amt 
	DEFINE l_recalc_ind CHAR(1)
	DEFINE l_disc_amt LIKE cashreceipt.disc_amt 
	DEFINE l_disc_taken_ind CHAR(1) 
	 
	LET l_cash_amt = 0 
	LET l_recalc_ind = 0
	LET l_disc_amt = 0
	LET l_disc_taken_ind = NULL
	
	IF p_rec_invoicehead.total_amt IS NULL THEN
		LET p_rec_invoicehead.total_amt = 0
	ENd IF

	IF p_rec_invoicehead.disc_amt IS NULL THEN
		LET p_rec_invoicehead.disc_amt = 0
	END IF
		
	IF get_debug() THEN 
		DISPLAY "-----------------------------------------"
		DISPLAY "FUNCTION calc_cash_amt(p_cmpy_code, p_cash_date, p_rec_invoicehead)"
		DISPLAY "-----------------------------------------"
		DISPLAY "p_cmpy_code=", trim(p_cmpy_code)
		DISPLAY "p_p_cash_date_ind=", trim(p_cash_date)
		DISPLAY "p_rec_invoicehead=", p_rec_invoicehead.*
		DISPLAY "-----------------------------------------"
		
		DISPLAY "1 l_disc_amt=", l_disc_amt 
		DISPLAY "1 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
		DISPLAY "1 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
	
		DISPLAY "2 l_disc_amt=", l_disc_amt 
		DISPLAY "2 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
		DISPLAY "2 p_rec_invoicehead=", p_rec_invoicehead.disc_amt
		
		DISPLAY "get_kandoooption_feature_state(\"AR\",\"PT\") =", get_kandoooption_feature_state("AR","PT") 
	END IF
	
	LET l_recalc_ind = get_kandoooption_feature_state("AR","PT")
	IF l_recalc_ind IS NULL THEN
		LET l_recalc_ind = kandoomsg("A",1051,"") ##1051 Override invoice discount settings (Y/N)
	END IF
	 
--			#1051 Override invoice discount settings (Y/N)
--	CASE get_kandoooption_feature_state("AR","PT") #I'm not too sure about this code... This will never return int - it will return CHAR(1)
--		WHEN '1' 
--			LET l_recalc_ind = 'N' 
--		WHEN '2' 
--			LET l_recalc_ind = 'Y' 
--		WHEN '3' 
--			LET l_recalc_ind = kandoomsg("A",1051,"") 
--			#1051 Override invoice discount settings (Y/N)
--	END CASE 

	IF get_debug() THEN 
		DISPLAY "3 l_disc_amt=", l_disc_amt 
		DISPLAY "3 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
		DISPLAY "3 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
	END IF

	# Cash_date = Inv_date
	IF l_recalc_ind = 'Y' THEN
		IF get_debug() THEN  
			DISPLAY "(show_disc(p_cmpy_code,p_rec_invoicehead.term_code, p_cash_date, p_rec_invoicehead.inv_date) / 100)"
			DISPLAY "=", show_disc(p_cmpy_code,p_rec_invoicehead.term_code, p_cash_date, p_rec_invoicehead.inv_date) / 100
		END IF 

		LET l_disc_amt = p_rec_invoicehead.total_amt * 0.01 * show_disc(
			p_cmpy_code,
			p_rec_invoicehead.term_code, 
			p_cash_date, 
			p_rec_invoicehead.inv_date)

		IF l_disc_amt != 0 THEN 
			IF l_disc_taken_ind IS NULL THEN 
				LET l_disc_taken_ind = kandoomsg("A",1050,"")		#A1050 Apply settlement discount ? (Y/N)
			END IF 
		END IF 
		IF l_disc_taken_ind = "N" THEN 
			LET l_disc_amt = 0 
		END IF 
	ELSE 

		IF get_debug() THEN 
			DISPLAY "4 l_disc_amt=", l_disc_amt 
			DISPLAY "4 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
			DISPLAY "4 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt   DISPLAY "p_cash_date=", p_cash_date DISPLAY "p_rec_invoicehead.disc_date=", p_rec_invoicehead.disc_date
		END IF

		IF p_cash_date <= p_rec_invoicehead.disc_date THEN
			IF get_debug() THEN  
				DISPLAY "5 l_disc_amt=", l_disc_amt 
				DISPLAY "5 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
				DISPLAY "5 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
			END IF
			
			LET l_disc_amt = p_rec_invoicehead.disc_amt
			
			IF get_debug() THEN  
				DISPLAY "6 l_disc_amt=", l_disc_amt 
				DISPLAY "6 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
				DISPLAY "6 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
			END IF

		ELSE 
			IF get_debug() THEN 
				DISPLAY "5 l_disc_amt=", l_disc_amt 
				DISPLAY "5 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
				DISPLAY "5 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt
				DISPLAY "l_cash_amt=", trim(l_cash_amt)
				DISPLAY "l_disc_amt=", trim(l_disc_amt)
				DISPLAY "l_recalc_ind=", trim(l_recalc_ind)
				DISPLAY "l_disc_taken_ind=", trim(l_disc_taken_ind)				 
			END IF
			
			LET l_disc_amt = 0 

			IF get_debug() THEN 
				DISPLAY "6 l_disc_amt=", l_disc_amt 
				DISPLAY "6 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
				DISPLAY "6 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
			END IF
			
		END IF 
	END IF 

	IF get_debug() THEN 
		DISPLAY "7 l_disc_amt=", l_disc_amt DISPLAY "l_cash_amt=", trim(l_cash_amt) 	DISPLAY "l_disc_amt=", trim(l_disc_amt) 		DISPLAY "l_recalc_ind=", trim(l_recalc_ind) 		DISPLAY "l_disc_taken_ind=", trim(l_disc_taken_ind)
		DISPLAY "7 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
		DISPLAY "7 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt 
	END IF
	
	LET l_cash_amt = p_rec_invoicehead.total_amt - p_rec_invoicehead.paid_amt	- l_disc_amt 


	IF get_debug() THEN 
		DISPLAY "8 l_disc_amt=", l_disc_amt 
		DISPLAY "8 p_rec_invoicehead.total_amt=", p_rec_invoicehead.total_amt 
		DISPLAY "8 p_rec_invoicehead.disc_amt=", p_rec_invoicehead.disc_amt
		DISPLAY "Arguments----------------------------------------------------------"
		DISPLAY "p_cmpy_code=", trim(p_cmpy_code)
		DISPLAY "p_p_cash_date_ind=", trim(p_cash_date)
		DISPLAY "p_rec_invoicehead=", p_rec_invoicehead.*
		DISPLAY "RETURN ----------------------------------------------------------"
		DISPLAY "l_cash_amt=", trim(l_cash_amt)
		DISPLAY "l_disc_amt=", trim(l_disc_amt)
		DISPLAY "l_recalc_ind=", trim(l_recalc_ind)
		DISPLAY "l_disc_taken_ind=", trim(l_disc_taken_ind)
		  
	END IF

	RETURN l_cash_amt, l_disc_amt, l_recalc_ind, l_disc_taken_ind 
END FUNCTION
##########################################################################
# END FUNCTION calc_cash_amt(p_cmpy_code, p_cash_date, p_rec_invoicehead) 
##########################################################################