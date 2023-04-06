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
# common/cioiwind.4gl
###########################################################################

#####################################################################
# FUNCTION cinq_clnt(p_cmpy,p_cust_code) -> Customer Details / Customer Invoice Submenu
# FUNCTION pallet_bal(p_cmpy, p_cust)
# FUNCTION pallet_dets(p_cmpy, p_cust_code)
# FUNCTION cinq_cred(p_rec_customer)
# FUNCTION customer_parameters(p_cmpy, p_cust_code)
# FUNCTION disp_cust_card(p_cmpy,p_cust_code)
# FUNCTION customer_Billing(p_cmpy,p_cust_code)
#####################################################################

###########################################################################
# \brief module - cinqwind.4gl
#
# Purpose - Displays CUSTOMER OPTIONS FOR user TO DISPLAY details WHEN doing a
#           customer inquiry.
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_msgresp LIKE language.yes_flag 

###########################################################################
# FUNCTION cinq_clnt(p_cmpy,p_cust_code)
# Customer Details / Customer Invoice Submenu
# Customer Invoice Submenu
###########################################################################
FUNCTION cinq_clnt(p_cmpy,p_cust_code) #p_cmpy will be ignored/removed -> globals
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_arr_custmenu ARRAY[20] OF RECORD 
		scroll_flag CHAR(1), 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_overdue LIKE customer.over1_amt 
	DEFINE l_baddue LIKE customer.over1_amt 
--	DEFINE glob_rec_company RECORD LIKE company.* 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	DEFINE l_part_code LIKE customerpart.part_code 
	DEFINE l_run_arg1 STRING #for forming the RUN url argument 
	DEFINE l_run_arg2 STRING #for forming the RUN url argument

	IF p_cust_code IS NULL THEN 
		CALL fgl_winmessage("Customer NOT specified","Please specify the customer prior","info") 
	END IF 

	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*
	
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF status = 0 THEN 
		LET l_overdue = l_rec_customer.over1_amt 
		+ l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt 
		LET l_baddue = l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt 

		FOR i = 1 TO 20 

			CASE i 

				WHEN "1" ## general details 
					LET l_idx = 1 
					LET l_arr_custmenu[l_idx].option_num = "1" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind",i) 

				WHEN "2" ## shipping address 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "2" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind",i) 

				WHEN "3" ## credit status 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "3" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind",i) 

				WHEN "4" ## outstanding invoices 
					IF l_rec_customer.next_seq_num > 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "4" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","4") 
					END IF 

				WHEN "5" ## CURRENT sales orders 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "5" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","5") 

				WHEN "6" ## notes 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "6" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","6") 

				WHEN "7" ## account ledger 
					IF l_rec_customer.next_seq_num > 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "7" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","7") 
					END IF 

				WHEN "8" ## customer parameters 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "8" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","8") 

				WHEN "9" ## reporting codes 
					IF l_rec_arparms.ref1_text IS NOT NULL 
					OR l_rec_arparms.ref2_text IS NOT NULL 
					OR l_rec_arparms.ref3_text IS NOT NULL 
					OR l_rec_arparms.ref4_text IS NOT NULL 
					OR l_rec_arparms.ref5_text IS NOT NULL 
					OR l_rec_arparms.ref6_text IS NOT NULL 
					OR l_rec_arparms.ref7_text IS NOT NULL 
					OR l_rec_arparms.ref8_text IS NOT NULL THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "9" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","9") 
					END IF 

				WHEN "10" ## STATISTICS 
					IF glob_rec_company.module_text[5] = "E" THEN 
						SELECT unique 1 FROM statparms 
						WHERE cmpy_code = p_cmpy 
						IF status = 0 THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_custmenu[l_idx].option_num = "A" 
							LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","A") 
						END IF 
					END IF 

				WHEN "11" ## pallet balances 
					IF glob_rec_company.module_text[23] = "W" THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "B" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","B") 
					END IF 

				WHEN "12" ## pallet details 
					IF glob_rec_company.module_text[23] = "W" THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "C" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","C") 
					END IF 

				WHEN "13" ## corporate accounts 
					IF l_rec_arparms.corp_drs_flag = "Y" THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "D" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","D") 
					END IF 

				WHEN "14" ## customer cards 
					SELECT unique 1 FROM custcard 
					WHERE cmpy_code = p_cmpy 
					AND cust_code = l_rec_customer.cust_code 
					IF status != notfound THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_custmenu[l_idx].option_num = "E" 
						LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","E") 
					END IF 

				WHEN "15" ## corporate transactions 
					IF l_rec_arparms.corp_drs_flag = "Y" THEN 
						SELECT unique 1 FROM customer 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_rec_customer.cust_code 
						AND corp_cust_code IS NOT NULL 
						IF status != notfound THEN 
							LET l_idx = l_idx + 1 
							LET l_arr_custmenu[l_idx].option_num = "F" 
							LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","F") 
						END IF 
					END IF 

				WHEN "16" ## billing 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "G" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","G") 

				WHEN "17" ## OPEN items 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "O" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","O") 

				WHEN "18" # customer part codes 
					LET l_idx = l_idx + 1 
					LET l_arr_custmenu[l_idx].option_num = "P" 
					LET l_arr_custmenu[l_idx].option_text = kandooword("cinqwind","P") 

			END CASE 

		END FOR 

		WHENEVER ERROR CONTINUE #huho ??? really ??? do we really NEED ON ERROR CONTINUE ???? 
		#window IS may be already OPEN.. there are better ways TO do handle this

		OPEN WINDOW A165 with FORM "A165" 
		IF status < 0 THEN 
			ERROR kandoomsg2("U",9917,"") 	#9917 Window IS already OPEN
			CURRENT WINDOW IS A165 #huho added 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		ELSE 
			CALL windecoration_a("A165") --newly opened WINDOW 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		DISPLAY l_rec_customer.cust_code TO cust_code 
		DISPLAY l_rec_customer.name_text TO name_text 

		CALL set_count(l_idx) 

		MESSAGE kandoomsg2("A",1030,"") 

		DISPLAY ARRAY l_arr_custmenu TO sr_custmenu.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","cinwind","input-arr-custmenu") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#DISPLAY l_arr_custmenu[l_idx].* TO sr_custmenu[scrn].*
				 {
				         AFTER FIELD scroll_flag
				            IF fgl_lastkey() = fgl_keyval("accept")
				            AND fgl_fglgui() THEN
				               NEXT FIELD option_num
				            END IF

				            IF l_arr_custmenu[l_idx].scroll_flag IS NULL THEN
				               IF fgl_lastkey() = fgl_keyval("down")
				               AND arr_curr() = arr_count() THEN
				                  LET modu_msgresp=kandoomsg("A",9001,"")
				                  NEXT FIELD scroll_flag
				               END IF
				            END IF
				  }
			ON ACTION "ACCEPT" 
				#NEXT FIELD option_num

				#         #BEFORE FIELD option_num
				#            IF l_arr_custmenu[l_idx].scroll_flag IS NULL THEN
				#               LET l_arr_custmenu[l_idx].scroll_flag = l_arr_custmenu[l_idx].option_num
				#            ELSE
				#               LET i = 1
				#
				#               WHILE (l_arr_custmenu[l_idx].scroll_flag IS NOT NULL)
				#                  IF l_arr_custmenu[i].option_num IS NULL THEN
				#                     LET l_arr_custmenu[l_idx].scroll_flag = NULL
				#                  ELSE
				#                     IF l_arr_custmenu[l_idx].scroll_flag=
				#                        l_arr_custmenu[i].option_num THEN
				#                        EXIT WHILE
				#                     END IF
				#                  END IF
				#                  LET i = i + 1
				#               END WHILE
				#
				#            END IF
				#Process actual Menu selection
				CASE l_arr_custmenu[l_idx].option_num #scroll_flag 
					WHEN "1" 
						CALL cinq_dets(p_cmpy,p_cust_code, l_overdue, l_baddue) 

					WHEN "2" 
						CALL cinq_ship(p_cmpy,p_cust_code) 

					WHEN "3" 
						CALL cinq_cred(l_rec_customer.*) 

					WHEN "4" --invoice 
						CALL coll_invo(p_cmpy,p_cust_code,l_overdue,l_baddue) 

					WHEN "5" 
						LET l_run_arg1 = "CUST_CODE=", trim(p_cust_code)
						IF glob_rec_company.module_text[23] = "W" THEN 
							#would this NOT be nicer ? -> IF get_module_licenced("W") THEN  #huho
							CALL run_prog("W12",l_run_arg1,"","","") 
							#W12 was missing in the sources
							CALL fgl_winmessage("w12 does NOT exist","Program w12 does NOT exist in the sources","info") 
						ELSE 
							CALL run_prog("E16",l_run_arg1,"","","") 
						END IF 

					WHEN "6" 
						LET l_run_arg1 = "CUSTOMER_CODE=", trim(p_cust_code) 
						CALL run_prog("A13",l_run_arg1,"","","") 

					WHEN "7" 
						LET l_run_arg1 = "ORDER=S" 
						LET l_run_arg2 = "CUSTOMER_CODE=",trim(p_cust_code)
						CALL run_prog("A1B",l_run_arg1,l_run_arg2,"","") 

					WHEN "8" 

						CALL customer_parameters(p_cmpy, p_cust_code) 

					WHEN "9" 
						CALL cinq_rep_code(p_cmpy,p_cust_code) 

					WHEN "A" 
						IF glob_rec_company.module_text[5] = "E" THEN 
							CALL cust_stats(p_cmpy,p_cust_code) 
						END IF 

					WHEN "B" 
						IF glob_rec_company.module_text[23] = "W" THEN 
							CALL pallet_bal(p_cmpy,p_cust_code) 
						END IF 

					WHEN "C" 
						IF glob_rec_company.module_text[23] = "W" THEN 
							CALL pallet_dets(p_cmpy,p_cust_code) 
						END IF 

					WHEN "D" 
						CALL disp_corp_acc(p_cmpy,p_cust_code) 

					WHEN "E" 
						CALL disp_cust_card(p_cmpy,p_cust_code) 

					WHEN "F" 
						CALL disp_corp_inv(p_cmpy,p_cust_code) 

					WHEN "G" 
						CALL customer_billing(p_cmpy,p_cust_code) 

					WHEN "O" 
						CALL cinq_openitems(p_cmpy,p_cust_code,l_overdue,l_baddue) 

					WHEN "P" 
						CALL view_custpart_code(p_cmpy,p_cust_code) 
						RETURNING l_part_code 
				END CASE 

				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 

				LET l_arr_custmenu[l_idx].scroll_flag = NULL 
				#NEXT FIELD scroll_flag

				#AFTER ROW
				#   DISPLAY l_arr_custmenu[l_idx].* TO sr_custmenu[scrn].*


		END DISPLAY 

		CLOSE WINDOW A165 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
###########################################################################
# END FUNCTION cinq_clnt(p_cmpy,p_cust_code)
###########################################################################


#####################################################################
# FUNCTION pallet_bal(p_cmpy, p_cust)
#
#
#####################################################################
FUNCTION pallet_bal(p_cmpy, p_cust) 
	DEFINE p_cmpy LIKE customer.cmpy_code
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_custpallet RECORD LIKE custpallet.* 
	DEFINE l_cred_avail_amt LIKE customer.bal_amt 
	DEFINE l_balance_amt LIKE customer.bal_amt
	DEFINE l_rec_trade RECORD LIKE custpallet.* 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	SELECT * INTO l_rec_custpallet.* FROM custpallet 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	LET l_balance_amt = l_rec_customer.bal_amt 
	LET l_cred_avail_amt = l_rec_customer.cred_limit_amt 
	- l_rec_customer.bal_amt 
	- l_rec_customer.onorder_amt 
	LET l_rec_trade.curr_amt = (l_rec_customer.curr_amt - l_rec_custpallet.curr_amt) 
	LET l_rec_trade.over1_amt = (l_rec_customer.over1_amt - l_rec_custpallet.over1_amt) 
	LET l_rec_trade.over30_amt = (l_rec_customer.over30_amt - l_rec_custpallet.over30_amt) 
	LET l_rec_trade.over60_amt = (l_rec_customer.over60_amt - l_rec_custpallet.over60_amt) 
	LET l_rec_trade.over90_amt = (l_rec_customer.over90_amt - l_rec_custpallet.over90_amt) 
	LET l_rec_trade.bal_amt = (l_rec_customer.bal_amt - l_rec_custpallet.bal_amt) 
	LET l_rec_trade.onorder_amt = (l_rec_customer.onorder_amt - l_rec_custpallet.onorder_amt) 

	OPEN WINDOW w229 with FORM "W229" 
	CALL windecoration_w("W229") 

	DISPLAY l_rec_customer.cust_code TO cust_code 
	DISPLAY l_rec_customer.name_text TO name_text
	DISPLAY l_rec_customer.currency_code TO currency_code
	DISPLAY l_rec_customer.curr_amt TO curr_amt
	DISPLAY l_rec_customer.over1_amt TO over1_amt
	DISPLAY l_rec_customer.over30_amt TO over30_amt 
	DISPLAY l_rec_customer.over60_amt TO over60_amt
	DISPLAY l_rec_customer.over90_amt TO over90_amt
	DISPLAY l_rec_customer.bal_amt TO bal_amt
	DISPLAY l_rec_customer.cred_limit_amt TO cred_limit_amt
	DISPLAY l_balance_amt TO balance_amt 
	DISPLAY l_rec_customer.onorder_amt TO onorder_amt
	DISPLAY l_rec_customer.onorder_amt TO onorder2_amt
	DISPLAY l_cred_avail_amt TO cred_avail_amt
	DISPLAY l_rec_custpallet.curr_amt TO pallet_curr_amt
	DISPLAY l_rec_custpallet.over1_amt TO pallet_over1_amt
	DISPLAY l_rec_custpallet.over30_amt TO pallet_over30_amt
	DISPLAY l_rec_custpallet.over60_amt TO pallet_over60_amt
	DISPLAY l_rec_custpallet.over90_amt TO pallet_over90_amt
	DISPLAY l_rec_custpallet.bal_amt TO pallet_bal_amt
	DISPLAY l_rec_custpallet.onorder_amt TO pallet_onorder_amt
	DISPLAY l_rec_trade.curr_amt TO trade_curr_amt
	DISPLAY l_rec_trade.over1_amt TO trade_over1_amt 
	DISPLAY l_rec_trade.over30_amt TO trade_over30_amt 
	DISPLAY l_rec_trade.over60_amt TO trade_over60_amt
	DISPLAY l_rec_trade.over90_amt TO trade_over90_amt
	DISPLAY l_rec_trade.bal_amt TO trade_bal_amt
	DISPLAY l_rec_trade.onorder_amt TO trade_onorder_amt

	CALL eventsuspend() 
	#LET modu_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW w229 

END FUNCTION 
#####################################################################
# END FUNCTION pallet_bal(p_cmpy, p_cust)
#####################################################################


#####################################################################
# FUNCTION pallet_dets(p_cmpy, p_cust_code)
#
#
#####################################################################
FUNCTION pallet_dets(p_cmpy, p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE ordhead.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_pallet RECORD 
		tran_date LIKE pallet.tran_date, 
		seq_num LIKE pallet.seq_num, 
		order_num LIKE pallet.order_num, 
		tran_type_ind LIKE pallet.tran_type_ind, 
		trans_num LIKE pallet.trans_num, 
		unit_price_amt LIKE pallet.unit_price_amt, 
		trans_qty LIKE pallet.trans_qty 
	END RECORD 
	DEFINE l_arr_pallet DYNAMIC ARRAY OF RECORD --ARRAY[300] OF RECORD 
		scroll_flag CHAR(1), 
		tran_date LIKE pallet.tran_date, 
		order_num LIKE pallet.order_num, 
		tran_type CHAR(9), 
		trans_num LIKE pallet.trans_num, 
		unit_price_amt LIKE pallet.unit_price_amt, 
		trans_qty LIKE pallet.trans_qty 
	END RECORD 
	DEFINE l_rec_custpallet RECORD LIKE custpallet.* 
	DEFINE l_outstand_qty LIKE pallet.trans_qty 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = p_cmpy 

	SELECT * INTO l_rec_custpallet.* FROM custpallet 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_customer.cust_code 

	OPEN WINDOW W232 with FORM "W232" 
	CALL windecoration_w("W232") 

	DISPLAY l_rec_customer.cust_code TO cust_code 
	DISPLAY l_rec_customer.name_text TO name_text 
	DISPLAY l_rec_custpallet.bal_amt TO bal_amt 

	LET l_idx = 0 

	DECLARE c_pallet CURSOR FOR 
	SELECT 
		tran_date, 
		seq_num, 
		order_num, 
		tran_type_ind, 
		trans_num, 
		unit_price_amt, 
	sum(trans_qty) 
	FROM pallet 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	GROUP BY tran_date, seq_num, order_num, tran_type_ind, trans_num, unit_price_amt 
	ORDER BY tran_date, seq_num, order_num, tran_type_ind, trans_num, unit_price_amt 

	LET l_outstand_qty = 0 

	FOREACH c_pallet INTO l_rec_pallet.* 
		LET l_idx = l_idx + 1 
		LET l_arr_pallet[l_idx].tran_date = l_rec_pallet.tran_date 
		LET l_arr_pallet[l_idx].order_num = l_rec_pallet.order_num 

		CASE 
			WHEN l_rec_pallet.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				LET l_arr_pallet[l_idx].tran_type = "DELIVERY" 
			WHEN l_rec_pallet.tran_type_ind = "DE" 
				LET l_arr_pallet[l_idx].tran_type = "DEPOSIT" 
			WHEN l_rec_pallet.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				LET l_arr_pallet[l_idx].tran_type = "RETURN" 
			WHEN l_rec_pallet.tran_type_ind = "RE" 
				LET l_arr_pallet[l_idx].tran_type = "REFUND" 
			WHEN l_rec_pallet.tran_type_ind = "WO" 
				LET l_arr_pallet[l_idx].tran_type = "WRITE OFF" 
			WHEN l_rec_pallet.tran_type_ind = "SC" 
				LET l_arr_pallet[l_idx].tran_type = "SITE CLEAR" 
			WHEN l_rec_pallet.tran_type_ind = "SR" 
				LET l_arr_pallet[l_idx].tran_type = "SURPLUS RETURN" 
			WHEN l_rec_pallet.tran_type_ind = "TX" 
				LET l_arr_pallet[l_idx].tran_type = "TRANSFER SURPLUS" 
		END CASE 

		LET l_arr_pallet[l_idx].trans_num = l_rec_pallet.trans_num 
		LET l_arr_pallet[l_idx].unit_price_amt = l_rec_pallet.unit_price_amt 
		LET l_arr_pallet[l_idx].trans_qty = l_rec_pallet.trans_qty 

		IF l_rec_pallet.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		OR l_rec_pallet.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		OR l_rec_pallet.tran_type_ind = "SR" 
		OR l_rec_pallet.tran_type_ind = "TX" 
		OR l_rec_pallet.tran_type_ind = "SC" 
		OR l_rec_pallet.tran_type_ind = "WO" 
		OR l_rec_pallet.tran_type_ind = "DE" 
		OR l_rec_pallet.tran_type_ind = "RE" THEN 
			LET l_outstand_qty = l_outstand_qty + l_rec_pallet.trans_qty 
		END IF 

--		IF l_idx = 300 THEN 
--			ERROR kandoomsg2("W",9021,l_idx) 		#9021 First l_idx entries Selected Only"
--			EXIT FOREACH 
--		END IF 

	END FOREACH 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	DISPLAY l_outstand_qty TO outstand_qty 

--	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("W",1008,"") 

	DISPLAY ARRAY l_arr_pallet TO sr_pallet.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cinwind","display-arr-pallet") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW W232 
	RETURN 
END FUNCTION 
#####################################################################
# END FUNCTION pallet_dets(p_cmpy, p_cust_code)
#####################################################################


#####################################################################
# FUNCTION cinq_cred(p_rec_customer)
#
#
#####################################################################
FUNCTION cinq_cred(p_rec_customer) 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_rec_custstmnt RECORD LIKE custstmnt.* 
	DEFINE l_balance_amt LIKE customer.bal_amt 

	IF p_rec_customer.hold_code IS NOT NULL THEN 
		SELECT reason_text INTO l_rec_holdreas.reason_text 
		FROM holdreas 
		WHERE cmpy_code = p_rec_customer.cmpy_code 
		AND hold_code = p_rec_customer.hold_code 
		IF status = notfound THEN 
			LET l_rec_holdreas.reason_text = "**********" 
		END IF 
	END IF 

	IF p_rec_customer.next_seq_num > 0 THEN 
		SELECT max(stat_date) INTO l_rec_custstmnt.stat_date 
		FROM custstmnt 
		WHERE cmpy_code = p_rec_customer.cmpy_code 
		AND cust_code = p_rec_customer.cust_code 
	END IF 

	IF p_rec_customer.last_pay_date = "31/12/1899" THEN 
		LET p_rec_customer.last_pay_date = NULL 
	END IF 

	IF p_rec_customer.setup_date = "31/12/1899" THEN 
		LET p_rec_customer.setup_date = NULL 
	END IF 

	IF p_rec_customer.last_inv_date = "31/12/1899" THEN 
		LET p_rec_customer.last_inv_date = NULL 
	END IF 

	IF l_rec_custstmnt.stat_date = "31/12/1899" THEN 
		LET l_rec_custstmnt.stat_date = NULL 
	END IF 

	LET l_balance_amt = p_rec_customer.bal_amt 
	LET p_rec_customer.cred_bal_amt = p_rec_customer.cred_limit_amt	- p_rec_customer.bal_amt - p_rec_customer.onorder_amt 

	OPEN WINDOW A108 with FORM "A108" 
	CALL windecoration_a("A108") 


	DISPLAY p_rec_customer.cust_code TO cust_code  
	DISPLAY p_rec_customer.name_text TO name_text
	DISPLAY p_rec_customer.int_chge_flag TO int_chge_flag
	DISPLAY p_rec_customer.hold_code TO hold_code
	DISPLAY l_rec_holdreas.reason_text TO reason_text 
	DISPLAY p_rec_customer.cred_override_ind TO cred_override_ind  
	DISPLAY p_rec_customer.curr_amt TO curr_amt 
	DISPLAY p_rec_customer.over1_amt TO over1_amt  
	DISPLAY p_rec_customer.over30_amt TO over30_amt 
	DISPLAY p_rec_customer.over60_amt TO over60_amt 
	DISPLAY p_rec_customer.over90_amt TO over90_amt  
	DISPLAY p_rec_customer.bal_amt TO bal_amt 
	DISPLAY p_rec_customer.cred_limit_amt TO cred_limit_amt 
	DISPLAY p_rec_customer.onorder_amt TO onorder_amt 
	DISPLAY p_rec_customer.cred_bal_amt TO cred_bal_amt 
	DISPLAY l_balance_amt TO balance_amt 
	DISPLAY p_rec_customer.avg_cred_day_num TO avg_cred_day_num 
	DISPLAY p_rec_customer.highest_bal_amt TO highest_bal_amt 
	DISPLAY p_rec_customer.ytds_amt TO ytds_amt 
	DISPLAY p_rec_customer.ytdp_amt TO ytdp_amt 
	DISPLAY p_rec_customer.late_pay_num TO late_pay_num  
	DISPLAY p_rec_customer.last_pay_date TO last_pay_date
	DISPLAY p_rec_customer.setup_date TO setup_date 
	DISPLAY p_rec_customer.last_inv_date TO last_inv_date 
	DISPLAY l_rec_custstmnt.stat_date TO stat_date 

	DISPLAY p_rec_customer.currency_code TO currency_code attribute(green) 
	CALL eventsuspend() 
	#LET modu_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW A108 
END FUNCTION 
#####################################################################
# END FUNCTION cinq_cred(p_rec_customer)
#####################################################################


#####################################################################
# FUNCTION customer_parameters(p_cmpy, p_cust_code)
#
#
#####################################################################
FUNCTION customer_parameters(p_cmpy, p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	OPEN WINDOW A607 with FORM "A607" 
	CALL windecoration_a("A607") 

	IF l_rec_customer.cond_code IS NOT NULL THEN 
		SELECT * INTO l_rec_condsale.* 
		FROM condsale 
		WHERE cond_code = l_rec_customer.cond_code 
		AND cmpy_code = p_cmpy 

		IF status = notfound THEN 
			LET l_rec_condsale.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_condsale.desc_text TO condsale.desc_text 

	END IF 

	IF l_rec_customer.tax_code IS NOT NULL THEN 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE tax_code = l_rec_customer.tax_code 
		AND cmpy_code = p_cmpy 

		IF status = notfound THEN 
			LET l_rec_tax.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_tax.desc_text TO tax.desc_text 

	END IF 

	IF l_rec_customer.term_code IS NOT NULL THEN 
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE term_code = l_rec_customer.term_code 
		AND cmpy_code = p_cmpy 

		IF status = notfound THEN 
			LET l_rec_term.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_term.desc_text TO term.desc_text 

	END IF 

	DISPLAY l_rec_customer.inv_level_ind TO inv_level_ind 
	DISPLAY l_rec_customer.cond_code TO cond_code 
	DISPLAY l_rec_customer.tax_code TO  tax_code
	DISPLAY l_rec_customer.tax_num_text TO tax_num_text 
	DISPLAY l_rec_customer.last_mail_date TO last_mail_date 
	DISPLAY l_rec_customer.pay_ind TO pay_ind 
	DISPLAY l_rec_customer.term_code TO term_code 
	DISPLAY l_rec_customer.bank_acct_code TO bank_acct_code 
	DISPLAY l_rec_customer.invoice_to_ind TO invoice_to_ind 
	DISPLAY l_rec_customer.ord_text_ind TO ord_text_ind 
	DISPLAY l_rec_customer.consolidate_flag TO consolidate_flag 
	DISPLAY l_rec_customer.back_order_flag TO back_order_flag
	DISPLAY l_rec_customer.partial_ship_flag TO partial_ship_flag 
	DISPLAY l_rec_customer.share_flag TO share_flag 

	CALL eventsuspend() 
	#LET modu_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW A607 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 

#####################################################################
# END FUNCTION customer_parameters(p_cmpy, p_cust_code)
#####################################################################


#####################################################################
# FUNCTION disp_cust_card(p_cmpy,p_cust_code)
#
#
#####################################################################
FUNCTION disp_cust_card(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE ordhead.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_custcard RECORD LIKE custcard.* 
	DEFINE l_arr_custcard DYNAMIC ARRAY OF RECORD 
		card_code LIKE custcard.card_code, 
		card_text LIKE custcard.card_text, 
		issue_date LIKE custcard.issue_date, 
		expiry_date LIKE custcard.expiry_date, 
		hold_code LIKE custcard.hold_code 
	END RECORD 
	DEFINE l_idx SMALLINT
   DEFINE i     SMALLINT 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = p_cust_code 
	AND cmpy_code = p_cmpy 

	OPEN WINDOW A678 with FORM "A678" 
	CALL windecoration_a("A678") 


	DISPLAY l_rec_customer.cust_code TO cust_code 
	DISPLAY l_rec_customer.name_text TO name_text

	LET l_idx = 0 

	DECLARE c_custcard CURSOR FOR 
	SELECT * FROM custcard 
	WHERE cust_code = l_rec_customer.cust_code 
	AND cmpy_code = p_cmpy 
	ORDER BY card_code 

	FOREACH c_custcard INTO l_rec_custcard.* 
		LET l_idx = l_idx + 1 
		LET l_arr_custcard[l_idx].card_code = l_rec_custcard.card_code 
		LET l_arr_custcard[l_idx].card_text = l_rec_custcard.card_text 
		LET l_arr_custcard[l_idx].issue_date = l_rec_custcard.issue_date 
		LET l_arr_custcard[l_idx].expiry_date = l_rec_custcard.expiry_date 
		LET l_arr_custcard[l_idx].hold_code = l_rec_custcard.hold_code 
	END FOREACH 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("U",1008,"") 

	DISPLAY ARRAY l_arr_custcard TO sr_custcard.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","cinwind","display-arr-custard") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW A678 

	RETURN 
END FUNCTION 
#####################################################################
# END FUNCTION disp_cust_card(p_cmpy,p_cust_code)
#####################################################################



#####################################################################
# FUNCTION customer_Billing(p_cmpy,p_cust_code)
#
#
#####################################################################
FUNCTION customer_billing(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_custstmnt RECORD LIKE custstmnt.* 
	DEFINE l_rec_stateinfo RECORD LIKE stateinfo.* 
	DEFINE l_stmnt_text CHAR(40) 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF l_rec_customer.next_seq_num = 0 THEN 
		LET l_rec_custstmnt.stat_date = "" 
		LET l_rec_custstmnt.bal_amt = "" 
	ELSE 
		DECLARE c_custstmnt CURSOR FOR 
		SELECT * FROM custstmnt 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = p_cust_code 
		ORDER BY cust_code,	stat_date desc
		 
		OPEN c_custstmnt 
		FETCH c_custstmnt INTO l_rec_custstmnt.* 
		IF status = notfound THEN 
			LET l_rec_custstmnt.stat_date = "" 
			LET l_rec_custstmnt.bal_amt = "" 
		END IF 
	END IF 

	SELECT * INTO l_rec_stateinfo.* FROM stateinfo 
	WHERE cmpy_code = p_cmpy 
	AND dun_code = l_rec_customer.dun_code 

	IF status = notfound THEN 
		LET l_rec_stateinfo.all1_text = "" 
	END IF 

	OPEN WINDOW A234 with FORM "A234" 
	CALL windecoration_a("A234") 

	DISPLAY l_rec_customer.stmnt_ind TO stmnt_ind 
	DISPLAY l_rec_custstmnt.stat_date TO  stat_date
	DISPLAY l_rec_custstmnt.bal_amt TO bal_amt 
	DISPLAY l_rec_customer.dun_code TO dun_code 
	DISPLAY l_rec_stateinfo.all1_text TO all1_text  
	DISPLAY l_rec_customer.inv_reqd_flag TO  inv_reqd_flag
	DISPLAY l_rec_customer.inv_format_ind TO inv_format_ind 
	DISPLAY l_rec_customer.cred_reqd_flag TO cred_reqd_flag  
	DISPLAY l_rec_customer.cred_format_ind TO cred_format_ind 
	DISPLAY l_rec_customer.mail_reqd_flag TO mail_reqd_flag 

	CASE l_rec_customer.stmnt_ind 
		WHEN "O" 
			LET l_stmnt_text = "Open Item" 
		WHEN "B" 
			LET l_stmnt_text = "Balance Forward" 
		WHEN "N" 
			LET l_stmnt_text = "No Statement" 
		WHEN "W" 
			LET l_stmnt_text = "Weekly" 
		OTHERWISE 
			LET l_stmnt_text = " " 
	END CASE 

	DISPLAY l_stmnt_text TO stmnt_text 

	CALL eventsuspend() 
	#LET modu_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW A234 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 
#####################################################################
# END FUNCTION customer_Billing(p_cmpy,p_cust_code)
#####################################################################