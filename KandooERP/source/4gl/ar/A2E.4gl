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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A2E_GLOBALS.4gl" 
############################################################
# FUNCTION A2E_main()
#
# Invoice Scan Screen & Transfer
# allows the user TO Scan Invoices FOR transfer
############################################################
FUNCTION A2E_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A2E") 
	CALL ui_init(0) 
	
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_org_customer.* TO NULL 
	LET glob_v_name_text = NULL 
	
	CREATE temp TABLE t_invoice (inv_num INTEGER, t_rowid integer) with no LOG 

	OPEN WINDOW A662 with FORM "A662" 
	
	CALL windecoration_a("A662") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Transfer Invoices" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A2E","menu-transfer-invoices-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "TRANSFER" #COMMAND "Transfer" " SELECT criteria AND PRINT REPORT" 
			WHILE get_customer() 
				IF A2E_scan_invoice() THEN 
					NEXT option "Print Manager" 
				END IF 
			END WHILE 
			LET quit_flag = false 
			LET int_flag = false 

		ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit"#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
			EXIT MENU 

	END MENU 
	CLOSE WINDOW A662 
	
END FUNCTION 
############################################################
# END FUNCTION A2E_main()
############################################################


############################################################
# FUNCTION get_customer()
#
# BLOODY MESS the transfer_to customer columns/fields are referenced as "_2" and/or "to_" in a sick mixed way
############################################################
FUNCTION get_customer() 
	DEFINE l_rec_t_corp_cust RECORD LIKE customer.*
	DEFINE l_rec_org_cust RECORD LIKE customer.*
	DEFINE l_rec_t_org_cust RECORD LIKE customer.*
	DEFINE l_to_cust_code LIKE customer.cust_code
	DEFINE l_name_text LIKE customer.name_text
	DEFINE l_addr1_text LIKE customer.addr1_text
	DEFINE l_addr2_text LIKE customer.addr1_text
	DEFINE l_city_text LIKE customer.city_text
--	DEFINE l_overdue_ind SMALLINT
	DEFINE l_temp_text CHAR(30) 

	CLEAR FORM 
	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text 
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text
	
	MESSAGE kandoomsg2("A",1083,"") #1083 Enter FROM AND Transfer Customers;  F8 Customer Detail.
	INPUT 
		glob_rec_t_invoicehead.cust_code, 
		l_to_cust_code 
	FROM 
		cust_code, 
		to_cust_code
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2E","inp-invoicehead-1") 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP"  infield (cust_code)  
				LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
				IF l_temp_text IS NOT NULL THEN 
					LET glob_rec_t_invoicehead.cust_code = l_temp_text 
				END IF 
				NEXT FIELD cust_code 

		ON ACTION "LOOKUP" infield (to_cust_code)  
				LET l_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
				IF l_temp_text IS NOT NULL THEN 
					LET l_to_cust_code = l_temp_text 
				END IF 
				NEXT FIELD to_cust_code 

		ON ACTION "CUSTOMER DETAILS" #ON KEY (F8)--Customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_customer.cust_code)--customer details 

		AFTER FIELD cust_code 
				CALL db_customer_get_rec(UI_OFF,glob_rec_t_invoicehead.cust_code) RETURNING glob_rec_customer.* 
--				SELECT * INTO glob_rec_customer.* FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = glob_rec_t_invoicehead.cust_code 
				IF glob_rec_customer.cust_code IS NULL THEN
				ERROR kandoomsg2("U",9105,"") 			#9105 "Record NOT found - Try window"
				NEXT FIELD cust_code 
			END IF 
			
			IF glob_rec_customer.corp_cust_code IS NOT NULL AND glob_rec_customer.corp_cust_ind = "1" THEN 
				LET glob_v_corp_cust = true 
				
				SELECT * INTO glob_corp_cust.* FROM customer 
				WHERE cust_code = glob_rec_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD cust_code 
				END IF 
			
			ELSE 
			
				LET glob_v_corp_cust = false 
			
			END IF
			 
			IF glob_v_corp_cust THEN 
				DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 

				DISPLAY glob_rec_t_invoicehead.cust_code TO invoicehead.org_cust_code 

				DISPLAY glob_rec_customer.corp_cust_code TO invoicehead.cust_code 

				DISPLAY glob_corp_cust.name_text TO customer.name_text 

				LET glob_rec_t_invoicehead.cust_code = glob_rec_customer.corp_cust_code 
				LET l_rec_org_cust.* = glob_corp_cust.* 
			
			ELSE 
			
				DISPLAY BY NAME 
					glob_rec_customer.name_text, 
					glob_rec_customer.addr1_text, 
					glob_rec_customer.addr2_text, 
					glob_rec_customer.city_text 

				LET l_rec_org_cust.* = glob_rec_customer.* 
			END IF
			 
			DISPLAY BY NAME 
				glob_rec_customer.addr1_text, 
				glob_rec_customer.addr2_text, 
				glob_rec_customer.city_text 

			NEXT FIELD to_cust_code 
			
		AFTER FIELD to_cust_code 
			SELECT * INTO glob_rec_t_customer.* FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_to_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found;  Try Window.
				NEXT FIELD to_cust_code 
			END IF 

			IF glob_rec_t_customer.corp_cust_code IS NOT NULL AND glob_rec_t_customer.corp_cust_ind = "1" THEN 
				SELECT * INTO l_rec_t_corp_cust.* FROM customer 
				WHERE cust_code = glob_rec_t_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD to_cust_code 
				END IF 

				DISPLAY glob_rec_t_customer.name_text TO formonly.org_name_text2 
				DISPLAY l_to_cust_code TO formonly.org_cust_code 
				DISPLAY l_rec_t_corp_cust.cust_code TO to_cust_code 
				DISPLAY l_rec_t_corp_cust.name_text TO name_text 

				LET l_to_cust_code = l_rec_t_corp_cust.cust_code 
				LET l_rec_t_org_cust.* = l_rec_t_corp_cust.* 

			ELSE 

				INITIALIZE l_rec_t_corp_cust.* TO NULL 

				LET l_name_text = glob_rec_t_customer.name_text 

				DISPLAY l_name_text TO name_text_2
				DISPLAY l_rec_t_corp_cust.name_text TO org_name_text2 
				DISPLAY l_rec_t_corp_cust.cust_code TO formonly.org_cust_code 

				LET l_rec_t_org_cust.* = glob_rec_t_customer.* 
			END IF 
			LET l_addr1_text = glob_rec_t_customer.addr1_text 
			LET l_addr2_text = glob_rec_t_customer.addr2_text 
			LET l_city_text = glob_rec_t_customer.city_text 
			
			DISPLAY l_addr1_text TO to_addr1_text
			DISPLAY l_addr2_text TO to_addr2_text
			DISPLAY l_city_text TO to_city_text
			
			IF glob_rec_t_customer.hold_code IS NOT NULL THEN 
				ERROR kandoomsg2("A",9143,"") 			#9143 Customer IS on hold;  Release before proceeding.
				NEXT FIELD to_cust_code 
			END IF 

			IF l_rec_t_org_cust.hold_code IS NOT NULL THEN 
				ERROR kandoomsg2("A",9143,"") 			#9143 Customer IS on hold;  Release before proceeding.
				NEXT FIELD to_cust_code 
			END IF 

			IF l_rec_t_org_cust.currency_code != l_rec_org_cust.currency_code THEN 
				ERROR kandoomsg2("A",9313,"") 			#9313 Must transfer TO customer with same currency.
				NEXT FIELD to_cust_code 
			END IF 

			IF l_rec_t_org_cust.cust_code = l_rec_org_cust.cust_code THEN 
				ERROR kandoomsg2("A",9314,"") 			#9314 Cannot transfer TO the same customer.
				NEXT FIELD to_cust_code 
			END IF 

			IF l_rec_t_org_cust.cred_override_ind = 0 THEN 
				IF l_rec_t_org_cust.bal_amt > l_rec_t_org_cust.cred_limit_amt THEN 
					ERROR kandoomsg2("A",7087,"") 				#7087 Customer has exceeded Credit Limit.
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		DISPLAY BY NAME l_rec_org_cust.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION get_customer()
############################################################


############################################################
# FUNCTION A2E_scan_invoice()
#
#
############################################################
FUNCTION A2E_scan_invoice() 
	DEFINE l_arr_rec_nametext DYNAMIC ARRAY OF RECORD 
		name_text LIKE customer.name_text, 
		cust_code LIKE customer.cust_code 
	END RECORD
	DEFINE l_arr_rec_row DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		row_id INTEGER 
	END RECORD
	DEFINE l_rowid INTEGER
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_query_text CHAR(400)
	DEFINE l_where_text CHAR(200)
	DEFINE l_idx SMALLINT 
	--DEFINE cnt SMALLINT
	DEFINE i SMALLINT 
	DEFINE l_success INTEGER
	DEFINE l_cnt SMALLINT 
	DEFINE h SMALLINT 
	DEFINE x SMALLINT 
	DEFINE j SMALLINT 
	DEFINE y SMALLINT 

	DELETE FROM t_invoice WHERE 1=1 
	LET glob_sav_cust_code = NULL 

	MESSAGE kandoomsg2("A",1001,"") 	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON 
		inv_num, 
		purchase_code, 
		inv_date, 
		year_num, 
		period_num, 
		total_amt, 
		paid_amt 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A2E","construct-invoice") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	IF glob_v_corp_cust OR glob_sav_cust_code IS NOT NULL THEN 
		LET glob_rec_t_invoicehead.cust_code = glob_corp_cust.cust_code 
	END IF 
	
	# Exclude paid invoices AND invoices FROM JM
	LET l_query_text = 
		"SELECT *,rowid ", 
		"FROM invoicehead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
		"AND cust_code = \"",glob_rec_t_invoicehead.cust_code CLIPPED,"\" ", 
		"AND ",l_where_text clipped," ", 
		"AND paid_amt = 0 ", 
		"ORDER BY inv_num" 
	PREPARE s_invoice FROM l_query_text 
	DECLARE c_invoice CURSOR FOR s_invoice 
	
	MESSAGE kandoomsg2("A",1002,"") #1002 " Searching database;  Please wait.
	LET l_idx = 0 
	FOREACH c_invoice INTO glob_rec_invoicehead.*,l_rowid 
		IF glob_v_corp_cust THEN 
			IF glob_rec_invoicehead.org_cust_code IS NULL OR glob_rec_invoicehead.org_cust_code != glob_rec_customer.cust_code THEN 
				CONTINUE FOREACH 
			END IF 
		END IF
		 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_row[l_idx].row_id = l_rowid 
		LET glob_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
		LET glob_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET glob_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET glob_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET glob_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
		LET glob_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
		LET glob_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET glob_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 

		# DISPLAY originating customer code AND name TO SCREEN
		SELECT customer.name_text INTO glob_t_name_text FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.org_cust_code 
		IF status = 0 THEN 
			LET l_arr_rec_nametext[l_idx].name_text = glob_t_name_text 
			LET l_arr_rec_nametext[l_idx].cust_code = glob_rec_invoicehead.org_cust_code 
		ELSE 
			LET l_arr_rec_nametext[l_idx].name_text = NULL 
			LET l_arr_rec_nametext[l_idx].cust_code = NULL 
		END IF 

	END FOREACH 
	ERROR kandoomsg2("U",9113,l_idx) #9113 l_idx records selected

	IF l_idx = 0 THEN 
		RETURN false 
	END IF 

	MESSAGE kandoomsg2("A",1084,"") #1084 F8 TO SELECT Invoice;  F10 SELECT All;  OK TO Continue.
	INPUT ARRAY glob_arr_rec_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* ATTRIBUTE(UNBUFFERED, insert row = false, delete row = false, append row=false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2E","inp-arr-invoicehead-1") 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_cnt = arr_count() 
			LET l_idx = arr_curr() 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = glob_arr_rec_invoicehead[l_idx].scroll_flag 
			LET glob_sav_cust_code = NULL 


			DISPLAY l_arr_rec_nametext[l_idx].name_text TO formonly.org_name_text 

			DISPLAY l_arr_rec_nametext[l_idx].cust_code TO invoicehead.org_cust_code 

			LET glob_sav_cust_code = l_arr_rec_nametext[l_idx].cust_code 

		AFTER FIELD scroll_flag 
			LET glob_arr_rec_invoicehead[l_idx].scroll_flag = l_scroll_flag 

		ON ACTION "SELECT ALL" #ON KEY (F10) 
			FOR i = 1 TO arr_count() 
				SELECT unique 1 FROM invoicedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = glob_arr_rec_invoicehead[i].inv_num 
				AND return_qty > 0 
				IF status = NOTFOUND THEN 
					IF glob_arr_rec_invoicehead[i].inv_num IS NOT NULL THEN 
						IF glob_arr_rec_invoicehead[i].scroll_flag IS NULL THEN 
							LET glob_arr_rec_invoicehead[i].scroll_flag = "*" 

							INSERT INTO t_invoice VALUES (
								glob_arr_rec_invoicehead[i].inv_num, 
								l_arr_rec_row[i].row_id) 
						ELSE 
							LET glob_arr_rec_invoicehead[i].scroll_flag = NULL 

							DELETE FROM t_invoice 
							WHERE t_rowid = l_arr_rec_row[i].row_id 

						END IF 
					END IF 
				END IF 
			END FOR 
			--LET h = arr_curr() 
			--LET x = scr_line() 
			--LET j = 7 - x 
			--LET y = (h - x) + 1 

			NEXT FIELD scroll_flag 

		ON ACTION "SELECT INVOICE" #ON KEY (F8) 
			SELECT unique 1 FROM invoicedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_arr_rec_invoicehead[l_idx].inv_num 
			AND return_qty > 0 
			IF status = NOTFOUND THEN 
				IF glob_arr_rec_invoicehead[l_idx].scroll_flag IS NULL THEN 
					INSERT INTO t_invoice VALUES (glob_arr_rec_invoicehead[l_idx].inv_num, 
					l_arr_rec_row[l_idx].row_id) 
					LET glob_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
				ELSE 
					LET glob_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
					DELETE FROM t_invoice 
					WHERE t_rowid = l_arr_rec_row[l_idx].row_id 
				END IF 
			ELSE 
				ERROR kandoomsg2("A",9320,"") 			#9320 "Invoice can NOT be transfered as returns have been
				NEXT FIELD scroll_flag 
			END IF 
			NEXT FIELD scroll_flag
			 
		BEFORE FIELD inv_num 
			NEXT FIELD scroll_flag 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT count(*) INTO l_cnt FROM t_invoice 
				IF l_cnt = 0 THEN 
					ERROR kandoomsg2("A",9312,"") 				#9312 No invoices have been selected FOR transfer.
					NEXT FIELD scroll_flag 
				ELSE 
					IF get_inv_details() THEN 
						EXIT INPUT 
					ELSE 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	
	RETURN true 
END FUNCTION 
############################################################
# END FUNCTION A2E_scan_invoice()
############################################################


############################################################
# FUNCTION get_inv_details()
#
#
############################################################
FUNCTION get_inv_details() 
	DEFINE l_rec_s_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_rec_salesperson RECORD LIKE salesperson.*
	DEFINE l_inv_num LIKE invoicehead.inv_num
	DEFINE i SMALLINT
	DEFINE l_invalid_period INTEGER
	DEFINE l_alter_flag,next_option INTEGER
	DEFINE l_term_text LIKE term.desc_text
	DEFINE l_tax_text LIKE tax.desc_text
	DEFINE l_sale_text LIKE salesperson.name_text
	DEFINE l_temp_text CHAR(30)
	DEFINE l_invalid_date CHAR(1)
	DEFINE l_inv_date LIKE invoicehead.inv_date
	DEFINE l_yp CHAR(100)
	DEFINE l_cred_reason LIKE credreas.reason_code
	DEFINE l_reason_text LIKE credreas.reason_text 

	LET l_invalid_date = "N" 

	OPEN WINDOW A207 with FORM "A207" 
	CALL windecoration_a("A207") 

	LET l_cred_reason = glob_rec_arparms.reason_code 
	IF l_cred_reason IS NOT NULL THEN 
		SELECT reason_text INTO l_reason_text FROM credreas 
		WHERE reason_code = l_cred_reason 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = NOTFOUND THEN 
			LET l_reason_text = "" 
		END IF 

		DISPLAY l_reason_text TO reason_text

	END IF 

	MESSAGE kandoomsg2("A",1085,"") #1085 Enter Invoice Details;  OK TO Continue.
	DECLARE c_invoice3 CURSOR FOR 
	SELECT inv_num FROM t_invoice 
	ORDER BY inv_num 
	OPEN c_invoice3 
	FETCH c_invoice3 INTO l_inv_num 
	CLOSE c_invoice3 

	CALL db_invoicehead_get_rec(UI_OFF,l_inv_num) RETURNING glob_rec_invoicehead.*
	--SELECT * INTO glob_rec_invoicehead.* FROM invoicehead 
	--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--AND inv_num = l_inv_num 

	LET l_rec_s_invoicehead.* = glob_rec_invoicehead.* 

	IF glob_rec_t_customer.corp_cust_code IS NOT NULL AND glob_rec_t_customer.corp_cust_ind = "1" THEN 
		LET l_rec_s_invoicehead.cust_code = glob_rec_t_customer.corp_cust_code 
		LET l_rec_s_invoicehead.org_cust_code = glob_rec_t_customer.cust_code 
	ELSE 
		LET l_rec_s_invoicehead.cust_code = glob_rec_t_customer.cust_code 
		LET l_rec_s_invoicehead.org_cust_code = NULL 
	END IF 

	LET l_rec_s_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_s_invoicehead.entry_date = today 
	LET l_rec_s_invoicehead.paid_date = NULL 
	LET l_rec_s_invoicehead.inv_date = NULL 
	LET l_rec_s_invoicehead.year_num = NULL 
	LET l_rec_s_invoicehead.period_num = NULL 
	LET l_rec_s_invoicehead.name_text = NULL 
	LET l_rec_s_invoicehead.addr1_text = NULL 
	LET l_rec_s_invoicehead.addr2_text = NULL 
	LET l_rec_s_invoicehead.city_text = NULL 
	LET l_rec_s_invoicehead.state_code = NULL 
	LET l_rec_s_invoicehead.post_code = NULL 
	LET l_rec_s_invoicehead.country_code = NULL --@db-patch_2020_10_04--
	LET l_rec_s_invoicehead.contact_text = NULL 
	LET l_rec_s_invoicehead.tele_text = NULL 
	LET l_rec_s_invoicehead.mobile_phone = NULL
	LET l_rec_s_invoicehead.email = NULL		
	LET glob_rec_customership.ship_code = glob_rec_t_customer.cust_code 

	#Sales Person
	CALL db_salesperson_get_rec(UI_OFF,glob_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.*

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE tax_code = glob_rec_invoicehead.tax_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	CALL db_term_get_rec(UI_OFF,glob_rec_invoicehead.term_code) RETURNING l_rec_term.*
--	SELECT * INTO l_rec_term.* FROM term 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND term_code = glob_rec_invoicehead.term_code 

	DECLARE c1_customership CURSOR FOR 
	SELECT * INTO glob_rec_customership.* FROM customership 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ship_code = glob_rec_customership.ship_code 

	OPEN c1_customership 
	FETCH c1_customership INTO glob_rec_customership.* 
	IF status = 0 THEN 
		LET l_rec_s_invoicehead.ship_code = glob_rec_customership.ship_code 
		LET l_rec_s_invoicehead.name_text = glob_rec_customership.name_text 
		LET l_rec_s_invoicehead.addr1_text = glob_rec_customership.addr_text 
		LET l_rec_s_invoicehead.addr2_text = glob_rec_customership.addr2_text 
		LET l_rec_s_invoicehead.city_text = glob_rec_customership.city_text 
		LET l_rec_s_invoicehead.state_code = glob_rec_customership.state_code 
		LET l_rec_s_invoicehead.post_code = glob_rec_customership.post_code 
		LET l_rec_s_invoicehead.country_code = glob_rec_customership.country_code --@db-patch_2020_10_04--
		LET l_rec_s_invoicehead.contact_text = glob_rec_customership.contact_text 
		LET l_rec_s_invoicehead.tele_text = glob_rec_customership.tele_text 
		LET l_rec_s_invoicehead.mobile_phone = glob_rec_customership.mobile_phone
		LET l_rec_s_invoicehead.email = glob_rec_customership.email				
	ELSE 
		LET l_rec_s_invoicehead.ship_code = NULL 
		LET glob_rec_customership.ship_code = NULL 
	END IF 

	LET l_term_text = l_rec_term.desc_text 
	LET l_tax_text = l_rec_tax.desc_text 
	LET l_sale_text = l_rec_salesperson.name_text 

	DISPLAY l_sale_text TO sale_text
	DISPLAY l_term_text TO term_text 
	DISPLAY l_tax_text TO tax_text

	INPUT 
		l_rec_s_invoicehead.inv_date, 
		l_rec_s_invoicehead.year_num, 
		l_rec_s_invoicehead.period_num, 
		glob_rec_customership.ship_code, 
		l_rec_s_invoicehead.name_text, 
		l_rec_s_invoicehead.addr1_text, 
		l_rec_s_invoicehead.addr2_text, 
		l_rec_s_invoicehead.city_text, 
		l_rec_s_invoicehead.sale_code, 
		l_rec_s_invoicehead.tax_code, 
		l_rec_s_invoicehead.term_code, 
		l_cred_reason WITHOUT DEFAULTS 
	FROM
		inv_date, 
		year_num, 
		period_num, 
		ship_code, 
		name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		sale_code, 
		tax_code, 
		term_code, 
		cred_reason 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2E","inp-invoicehead-2") 
			#populate ship_code combo (requires cust_code)
			CALL comboList_customership_DOUBLE("ship_code",l_rec_s_invoicehead.cust_code,COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(ship_code) 
			LET l_temp_text = show_ship(glob_rec_kandoouser.cmpy_code,l_rec_s_invoicehead.cust_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_customership.ship_code = l_temp_text 
			END IF 
			NEXT FIELD ship_code 
			
		ON ACTION "LOOKUP" infield (sale_code) 
			LET l_temp_text = show_sale(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_s_invoicehead.sale_code = l_temp_text 
			END IF 
			NEXT FIELD sale_code 
			
		ON ACTION "LOOKUP" infield (term_code) 
			LET l_temp_text = show_term(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_s_invoicehead.term_code = l_temp_text 
			END IF 
			NEXT FIELD term_code 
			
		ON ACTION "LOOKUP" infield (tax_code) 
			LET l_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_s_invoicehead.tax_code = l_temp_text 
			END IF 
			NEXT FIELD tax_code 
			
		ON ACTION "LOOKUP" infield(l_cred_reason) 
			#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
			LET l_temp_text = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,l_cred_reason) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_cred_reason = l_temp_text 
				NEXT FIELD cred_reason 
			END IF 

		BEFORE FIELD inv_date 
			LET l_inv_date = l_rec_s_invoicehead.inv_date 

		AFTER FIELD inv_date 
			IF l_rec_s_invoicehead.inv_date IS NOT NULL THEN 
				IF l_inv_date != l_rec_s_invoicehead.inv_date OR l_inv_date IS NULL THEN 
					CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, l_rec_s_invoicehead.inv_date) 
					RETURNING 
						l_rec_s_invoicehead.year_num, 
						l_rec_s_invoicehead.period_num 
					
					DISPLAY BY NAME 
						l_rec_s_invoicehead.year_num, 
						l_rec_s_invoicehead.period_num 

				END IF 
			
			ELSE 
			
				LET l_rec_s_invoicehead.year_num = NULL 
				LET l_rec_s_invoicehead.period_num = NULL 
				DISPLAY BY NAME 
					l_rec_s_invoicehead.year_num, 
					l_rec_s_invoicehead.period_num 

			END IF 

		AFTER FIELD year_num 
			IF l_rec_s_invoicehead.inv_date IS NULL AND l_rec_s_invoicehead.year_num IS NOT NULL THEN 
				INITIALIZE l_rec_s_invoicehead.year_num TO NULL 

				DISPLAY BY NAME l_rec_s_invoicehead.year_num 

				ERROR kandoomsg2("A",9510,"") 			#9510 Invoice Data must be entered before year/period can be ...
				NEXT FIELD inv_date 
			END IF 

		AFTER FIELD period_num 
			IF l_rec_s_invoicehead.inv_date IS NULL AND l_rec_s_invoicehead.period_num IS NOT NULL THEN 
				INITIALIZE l_rec_s_invoicehead.period_num TO NULL 
				
				DISPLAY BY NAME l_rec_s_invoicehead.period_num 

				ERROR kandoomsg2("A",9510,"") 			#9510 Invoice Data must be entered before year/period can be ...
				NEXT FIELD inv_date 
			END IF 

		AFTER FIELD sale_code 
			SELECT name_text INTO l_sale_text FROM salesperson 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND sale_code = l_rec_s_invoicehead.sale_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found;  Try Window.
				NEXT FIELD sale_code 
			ELSE 
				DISPLAY l_sale_text TO sale_text 
			END IF 

		AFTER FIELD term_code 
			CALL db_term_get_rec(UI_OFF,l_rec_s_invoicehead.term_code ) RETURNING l_rec_term.*
			IF sqlca.sqlcode = 0 THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found;  Try Window.
				NEXT FIELD term_code 
			ELSE 
				DISPLAY l_rec_term.desc_text TO term_text 

			END IF 

		AFTER FIELD tax_code 
			SELECT * INTO l_rec_tax.* FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = l_rec_s_invoicehead.tax_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD NOT found;  Try Window.
				NEXT FIELD tax_code 
			ELSE 
				DISPLAY l_rec_tax.desc_text TO tax_text 

			END IF 

		AFTER FIELD ship_code 
			IF glob_rec_customership.ship_code IS NULL THEN 
				INITIALIZE glob_rec_customership.* TO NULL 
				LET l_rec_s_invoicehead.ship_code = NULL 
				LET l_rec_s_invoicehead.state_code = NULL 
				LET l_rec_s_invoicehead.post_code = NULL 
				LET l_rec_s_invoicehead.country_code = NULL --@db-patch_2020_10_04--
				LET l_rec_s_invoicehead.contact_text = NULL 
				LET l_rec_s_invoicehead.tele_text = NULL 
				LET l_rec_s_invoicehead.mobile_phone = NULL
				LET l_rec_s_invoicehead.email = NULL								
			END IF 
			IF glob_rec_customership.ship_code IS NOT NULL THEN 
				DECLARE c2_customership CURSOR FOR 
				SELECT * FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ship_code = glob_rec_customership.ship_code 
				OPEN c2_customership 
				FETCH c2_customership INTO glob_rec_customership.* 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD ship_code 
				END IF 
				LET l_rec_s_invoicehead.ship_code = glob_rec_customership.ship_code 
				LET l_rec_s_invoicehead.name_text = glob_rec_customership.name_text 
				LET l_rec_s_invoicehead.addr1_text = glob_rec_customership.addr_text 
				LET l_rec_s_invoicehead.addr2_text = glob_rec_customership.addr2_text 
				LET l_rec_s_invoicehead.city_text = glob_rec_customership.city_text 
				LET l_rec_s_invoicehead.state_code = glob_rec_customership.state_code 
				LET l_rec_s_invoicehead.post_code = glob_rec_customership.post_code 
				LET l_rec_s_invoicehead.country_code = glob_rec_customership.country_code --@db-patch_2020_10_04--
				LET l_rec_s_invoicehead.contact_text = glob_rec_customership.contact_text 
				LET l_rec_s_invoicehead.tele_text = glob_rec_customership.tele_text 
				LET l_rec_s_invoicehead.mobile_phone = glob_rec_customership.mobile_phone
				LET l_rec_s_invoicehead.email = glob_rec_customership.email								
				
				DISPLAY BY NAME 
					l_rec_s_invoicehead.name_text, 
					l_rec_s_invoicehead.addr1_text, 
					l_rec_s_invoicehead.addr2_text, 
					l_rec_s_invoicehead.city_text 

			END IF 

		AFTER FIELD cred_reason 
			IF l_cred_reason IS NULL OR l_cred_reason = " " THEN 
				ERROR kandoomsg2("W",9277,"") 			#9277 Credit Reason must be entered.
				NEXT FIELD cred_reason 
			END IF 
			
			SELECT reason_text INTO l_reason_text FROM credreas 
			WHERE reason_code = l_cred_reason 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9058,"") 			#9058 Credit reason NOT found;  Try Window.
				NEXT FIELD cred_reason 
			END IF 
			
			DISPLAY l_reason_text TO reason_text 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF (l_rec_s_invoicehead.year_num IS NOT NULL 
				AND l_rec_s_invoicehead.period_num IS null) 
				OR (l_rec_s_invoicehead.period_num IS NOT NULL 
				AND l_rec_s_invoicehead.year_num IS null) THEN 
					ERROR kandoomsg2("A",9223,"") 				#9223 Invalid financial year & period.
					NEXT FIELD year_num 
				END IF 

				IF l_rec_s_invoicehead.inv_date IS NULL THEN 

					FOR i = 1 TO glob_arr_rec_invoicehead.getSize() 
						IF glob_arr_rec_invoicehead[i].inv_num IS NULL THEN 
							EXIT FOR 
						END IF 
						IF glob_arr_rec_invoicehead[i].scroll_flag = "*" THEN 
							CALL valid_period2(
								glob_rec_kandoouser.cmpy_code, 
								glob_arr_rec_invoicehead[i].year_num, 
								glob_arr_rec_invoicehead[i].period_num, 
								LEDGER_TYPE_AR) 
							RETURNING l_invalid_period 

							IF not(l_invalid_period) THEN 
								LET l_yp =
									"Transfer of invoice(s) unsuccessful - Year ", 
									glob_arr_rec_invoicehead[i].year_num USING "####","/", 
									glob_arr_rec_invoicehead[i].period_num USING "&#", 
									" closed" 

								ERROR kandoomsg2("A",7088,l_yp) 							#7088 <Displays the above MESSAGE - l_yp>
								LET l_invalid_date = "Y" 
								EXIT INPUT 
							END IF 
						END IF 

					END FOR 

				ELSE 

					CALL valid_period(
						glob_rec_kandoouser.cmpy_code, 
						l_rec_s_invoicehead.year_num, 
						l_rec_s_invoicehead.period_num, 
						LEDGER_TYPE_AR) 
					RETURNING 
						l_rec_s_invoicehead.year_num, 
						l_rec_s_invoicehead.period_num, 
						l_invalid_period 
					IF l_invalid_period THEN 
						NEXT FIELD year_num 
					END IF 
				END IF 
				
				IF glob_rec_customership.ship_code IS NOT NULL THEN 
					DECLARE c3_customership CURSOR FOR 
					SELECT * FROM customership 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ship_code = glob_rec_customership.ship_code 
					OPEN c3_customership 
					FETCH c3_customership INTO glob_rec_customership.* 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("U",9105,"") 					#9105 RECORD NOT found;  Try Window.
						NEXT FIELD ship_code 
					END IF 
				END IF 
				
				SELECT * FROM salesperson 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND sale_code = l_rec_s_invoicehead.sale_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD sale_code 
				END IF 
				
				CALL db_term_get_rec(UI_OFF,l_rec_s_invoicehead.term_code ) RETURNING l_rec_term.*
					IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD term_code 
				END IF 
				
				SELECT * INTO l_rec_tax.* FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_code = l_rec_s_invoicehead.tax_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 				#9105 RECORD NOT found;  Try Window.
					NEXT FIELD tax_code 
				END IF 
				
				IF l_cred_reason IS NULL OR l_cred_reason = " " THEN 
					ERROR kandoomsg2("W",9277,"") 				#9277 Credit Reason must be entered.
					NEXT FIELD cred_reason 
				END IF 
				
				LET l_alter_flag = ring_menu() 
				CASE l_alter_flag 
					WHEN 1 
						IF prepare_invoice(l_rec_s_invoicehead.*,l_cred_reason) THEN 
							EXIT INPUT 
						END IF 
					WHEN 2 
						NEXT FIELD inv_date 
					WHEN 3 
						EXIT INPUT 
				END CASE 
			END IF 


	END INPUT 

	IF l_invalid_date = "Y" THEN 
		CLOSE WINDOW A207 
		RETURN false 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A207 
		RETURN false 
	END IF 

	IF l_alter_flag = 1 THEN 
		CLOSE WINDOW A207 
		RETURN true 
	END IF 

	IF l_alter_flag = 3 THEN 
		CLOSE WINDOW A207 
		RETURN false 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION get_inv_details()
############################################################


############################################################
# FUNCTION ring_menu() 
#
#
############################################################
FUNCTION ring_menu() 
	DEFINE l_alter_flag INTEGER 

	LET l_alter_flag = false 
	MENU " Invoice Transfer" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A2E","menu-transfer-invoices-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Save" 		#COMMAND "Save" " Continue with transfer"
			LET l_alter_flag = 1 
			EXIT MENU 

		ON ACTION "EDIT" 		#COMMAND "Alter" " Modify Invoice Details"
			LET l_alter_flag = 2 
			EXIT MENU 

		ON ACTION "Exit" 		#COMMAND KEY (interrupt, E) "Exit" " Exit TO invoice scan"
			LET l_alter_flag = 3 
			EXIT MENU 

	END MENU 

--	IF l_alter_flag = 2 
--	OR l_alter_flag = 3 THEN 
--	END IF 
	RETURN l_alter_flag 
END FUNCTION 
############################################################
# END FUNCTION ring_menu() 
############################################################


############################################################
# FUNCTION prepare_invoice(p_rec_s_invoicehead, p_cred_reason) 
#
#
############################################################
FUNCTION prepare_invoice(p_rec_s_invoicehead, p_cred_reason) 
	DEFINE p_rec_s_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_cred_reason LIKE arparms.reason_code 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_t_invoicehead RECORD LIKE invoicehead.*
	DEFINE l_inv_num LIKE invoicehead.inv_num
	DEFINE l_new_inv LIKE invoicehead.inv_num
	DEFINE l_new_cred LIKE credithead.cred_num
	
	DECLARE c1_invoice CURSOR with HOLD FOR 
	SELECT inv_num FROM t_invoice 

	
	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"A2E_rpt_list_invoice","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT A2E_rpt_list_invoice TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	FOREACH c1_invoice INTO l_inv_num
		CALL db_invoicehead_get_rec(UI_OFF,l_inv_num) RETURNING glob_rec_invoicehead.* 
		--SELECT * INTO glob_rec_invoicehead.* FROM invoicehead 
		--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND inv_num = l_inv_num 

		LET l_rec_t_invoicehead.* = glob_rec_invoicehead.* 

		IF p_rec_s_invoicehead.inv_date IS NOT NULL THEN 
			LET l_rec_t_invoicehead.inv_date = p_rec_s_invoicehead.inv_date 
			LET l_rec_t_invoicehead.year_num = p_rec_s_invoicehead.year_num 
			LET l_rec_t_invoicehead.period_num = p_rec_s_invoicehead.period_num 
		END IF 

		LET l_rec_t_invoicehead.cust_code = p_rec_s_invoicehead.cust_code 
		LET l_rec_t_invoicehead.org_cust_code = p_rec_s_invoicehead.org_cust_code 
		LET l_rec_t_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_t_invoicehead.entry_date = today 
		IF p_rec_s_invoicehead.name_text IS NOT NULL 
		OR p_rec_s_invoicehead.ship_code IS NOT NULL 
		OR p_rec_s_invoicehead.addr1_text IS NOT NULL 
		OR p_rec_s_invoicehead.addr2_text IS NOT NULL 
		OR p_rec_s_invoicehead.city_text IS NOT NULL THEN 
			LET l_rec_t_invoicehead.name_text = p_rec_s_invoicehead.name_text 
			LET l_rec_t_invoicehead.ship_code = p_rec_s_invoicehead.ship_code 
			LET l_rec_t_invoicehead.addr1_text = p_rec_s_invoicehead.addr1_text 
			LET l_rec_t_invoicehead.addr2_text = p_rec_s_invoicehead.addr2_text 
			LET l_rec_t_invoicehead.city_text = p_rec_s_invoicehead.city_text 
			LET l_rec_t_invoicehead.state_code = p_rec_s_invoicehead.state_code 
			LET l_rec_t_invoicehead.post_code = p_rec_s_invoicehead.post_code 
			LET l_rec_t_invoicehead.country_code = p_rec_s_invoicehead.country_code --@db-patch_2020_10_04--
		END IF 

		LET l_rec_t_invoicehead.contact_text = p_rec_s_invoicehead.contact_text 
		LET l_rec_t_invoicehead.tele_text = p_rec_s_invoicehead.tele_text 
		LET l_rec_t_invoicehead.mobile_phone = p_rec_s_invoicehead.mobile_phone
		LET l_rec_t_invoicehead.email = p_rec_s_invoicehead.email				
		LET l_rec_t_invoicehead.sale_code = p_rec_s_invoicehead.sale_code 
		LET l_rec_t_invoicehead.tax_code = p_rec_s_invoicehead.tax_code 
		LET l_rec_t_invoicehead.term_code = p_rec_s_invoicehead.term_code 
		LET l_rec_t_invoicehead.on_state_flag = "N" 
		LET l_rec_t_invoicehead.posted_flag = "N" 
		LET l_rec_t_invoicehead.jour_num = NULL 
		LET l_rec_t_invoicehead.post_date = NULL 
		LET l_rec_t_invoicehead.stat_date = NULL 
		LET l_rec_t_invoicehead.manifest_num = NULL 
		LET l_rec_t_invoicehead.ord_num = NULL 
		LET l_rec_t_invoicehead.printed_num = 0 
		LET l_rec_t_invoicehead.com1_text = "Transfered FROM Inv: ",	l_inv_num USING "<<<<<<<<" 

		ERROR kandoomsg2("A",1094,l_inv_num) 	#1094 Transferring Invoice l_inv_num
		CALL transfer_invoice(l_rec_t_invoicehead.*,	p_cred_reason) 
		RETURNING l_new_inv, l_new_cred 
		
		#------------------------------------------------------------
		OUTPUT TO REPORT A2E_rpt_list_invoice(l_rpt_idx,glob_rec_invoicehead.inv_num, l_new_inv,l_new_cred)
		IF NOT rpt_int_flag_handler2("Invoice",l_inv_num, l_rec_t_invoicehead.cust_code,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
 
	END FOREACH 
	
--	FINISH REPORT a2e_invoice 
--	CALL upd_reports(glob_rec_rmsreps.file_text, glob_rec_rmsreps.page_num, glob_rec_rmsreps.report_width_num, glob_rec_rmsreps.page_length_num)

	#------------------------------------------------------------
	FINISH REPORT A2E_rpt_list_invoice
	DELETE FROM t_invoice WHERE 1=1
	RETURN rpt_finish("A2E_rpt_list_invoice")
	#------------------------------------------------------------

END FUNCTION 
############################################################
# END FUNCTION prepare_invoice(p_rec_s_invoicehead, p_cred_reason) 
############################################################


############################################################
# FUNCTION transfer_invoice(p_rec_t_invoicehead, p_cred_reason)   
#
#
############################################################
FUNCTION transfer_invoice(p_rec_t_invoicehead, p_cred_reason) 
	DEFINE p_rec_t_invoicehead RECORD LIKE invoicehead.*
	DEFINE p_cred_reason LIKE arparms.reason_code 
	
	DEFINE l_rec_inparms RECORD LIKE inparms.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_credheadaddr RECORD LIKE credheadaddr.*
	DEFINE l_rec_t_creditheadext RECORD LIKE creditheadext.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.*
	DEFINE l_rec_invheadext RECORD LIKE invheadext.*
	DEFINE l_rec_t_invheadext RECORD LIKE invheadext.*
	DEFINE l_rec_invrates RECORD LIKE invrates.*
	DEFINE l_rec_t_invrates RECORD LIKE invrates.*
	DEFINE l_rec_t_creditrates RECORD LIKE creditrates.*
	DEFINE l_rec_term RECORD LIKE term.*
	DEFINE l_rec_stattrig RECORD LIKE stattrig.*
	DEFINE l__seq_num LIKE prodstatus.seq_num
	DEFINE l_onhand_qty LIKE prodstatus.onhand_qty
	DEFINE l_prodrow INTEGER
	DEFINE l_temp_text CHAR(25)
	DEFINE l_err_message CHAR(80)
	DEFINE l_err_continue CHAR(1)
	DEFINE l_v_corp_cust_ind LIKE customer.corp_cust_ind
	DEFINE l_v_corp_cust_code LIKE customer.corp_cust_code 
	DEFINE l_invoice_age SMALLINT
	DEFINE l_t_invoice_age SMALLINT

	GOTO bypass 
	LABEL recovery: 
	LET l_err_continue = error_recover(l_err_message, status) 
	
	IF l_err_continue != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery
	 
	BEGIN WORK
	 
		INITIALIZE l_rec_credithead.* TO NULL 
		INITIALIZE l_rec_creditdetl.* TO NULL 
		INITIALIZE l_rec_araudit.* TO NULL 
		INITIALIZE l_rec_prodledg.* TO NULL 
		
		CALL set_aging(glob_rec_kandoouser.cmpy_code,glob_rec_arparms.cust_age_date) 
		LET l_err_message = "A2E - Arparms UPDATE" 
		LET l_rec_credithead.cred_num =	next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_CREDIT_CR, l_rec_credithead.acct_override_code) 

		IF not(l_rec_credithead.cred_num > 0) THEN 
			LET status = l_rec_credithead.cred_num 
			GOTO recovery 
		END IF 

		LET p_rec_t_invoicehead.inv_num =	next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_INVOICE_IN,p_rec_t_invoicehead.acct_override_code) 
		IF p_rec_t_invoicehead.inv_num < 0 THEN 
			LET l_err_message = "Updating Next Invoice Number" 
			LET status = p_rec_t_invoicehead.inv_num 
			GOTO recovery 
		END IF 
		
		# Credithead details are the same as the old invoice
		LET l_rec_credithead.cmpy_code = glob_rec_invoicehead.cmpy_code 
		LET l_rec_credithead.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_credithead.cred_text = glob_rec_invoicehead.inv_num 
		LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_credithead.entry_date = today 
		LET l_rec_credithead.cred_ind = "1" 
		LET l_rec_credithead.sale_code = glob_rec_invoicehead.sale_code 
		LET l_rec_credithead.tax_code = glob_rec_invoicehead.tax_code 
		LET l_rec_credithead.tax_per = glob_rec_invoicehead.tax_per 
		LET l_rec_credithead.goods_amt = glob_rec_invoicehead.goods_amt 
		LET l_rec_credithead.hand_amt = glob_rec_invoicehead.hand_amt 
		LET l_rec_credithead.hand_tax_code = glob_rec_invoicehead.hand_tax_code 
		LET l_rec_credithead.hand_tax_amt = glob_rec_invoicehead.hand_tax_amt 
		LET l_rec_credithead.freight_amt = glob_rec_invoicehead.freight_amt 
		LET l_rec_credithead.freight_tax_code = glob_rec_invoicehead.freight_tax_code 
		LET l_rec_credithead.freight_tax_amt = glob_rec_invoicehead.freight_tax_amt 
		LET l_rec_credithead.tax_amt = glob_rec_invoicehead.tax_amt 
		LET l_rec_credithead.total_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_credithead.cost_amt = glob_rec_invoicehead.cost_amt 
		LET l_rec_credithead.appl_amt = 0 
		LET l_rec_credithead.disc_amt = 0 
		# Posting year AND period AND credit date are that of new invoice
		LET l_rec_credithead.cred_date = p_rec_t_invoicehead.inv_date 
		LET l_rec_credithead.year_num = p_rec_t_invoicehead.year_num 
		LET l_rec_credithead.period_num = p_rec_t_invoicehead.period_num 
		LET l_rec_credithead.posted_flag = "N" 
		LET l_rec_credithead.on_state_flag = "N" 
		LET l_rec_credithead.printed_num = 0 
		LET l_rec_credithead.next_num = 1 
		LET l_rec_credithead.line_num = glob_rec_invoicehead.line_num 
		LET l_rec_credithead.com1_text = "Transfer of invoice ",	glob_rec_invoicehead.inv_num USING "<<<<<<<<" 
		LET l_rec_credithead.rev_date = today 
		LET l_rec_credithead.rev_num = 1 
		LET l_rec_credithead.cost_ind = glob_rec_arparms.costings_ind 
		LET l_rec_credithead.currency_code = glob_rec_invoicehead.currency_code 
		LET l_rec_credithead.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_credithead.acct_override_code = glob_rec_invoicehead.acct_override_code 
		LET l_rec_credithead.price_tax_flag = glob_rec_invoicehead.price_tax_flag 
		LET l_rec_credithead.appl_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_credithead.area_code = glob_rec_invoicehead.area_code 
		LET l_rec_credithead.territory_code = glob_rec_invoicehead.territory_code 
		LET l_rec_credithead.mgr_code = glob_rec_invoicehead.mgr_code 

		LET glob_rec_invoicehead.com1_text = "Transfered TO Inv: ", p_rec_t_invoicehead.inv_num USING "<<<<<<<<" 
		LET l_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,glob_rec_invoicehead.due_date) 
		
		UPDATE invoicehead 
		SET 
			paid_amt = glob_rec_invoicehead.total_amt, 
			paid_date = today, 
			com1_text = glob_rec_invoicehead.com1_text 
		WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 

		LET l_rec_invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_invoicepay.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_invoicepay.inv_num = glob_rec_invoicehead.inv_num 
		LET l_rec_invoicepay.appl_num = 0 
		LET l_rec_invoicepay.pay_date = today 
		LET l_rec_invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_invoicepay.ref_num = l_rec_credithead.cred_num 
		LET l_rec_invoicepay.apply_num = 1 
		LET l_rec_invoicepay.pay_text = "Invoice TX" 
		LET l_rec_invoicepay.pay_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_invoicepay.disc_amt = glob_rec_invoicehead.disc_amt 

		IF l_rec_invoicepay.disc_amt IS NULL THEN 
			LET l_rec_invoicepay.disc_amt = 0 
		END IF 

		LET l_err_message = "A2E - INSERT invoicepay" 

		INSERT INTO invoicepay VALUES (l_rec_invoicepay.*) 

		LET l_rec_credheadaddr.cred_num = l_rec_credithead.cred_num 
		LET l_rec_credheadaddr.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_credheadaddr.ship_text = glob_rec_invoicehead.name_text 
		LET l_rec_credheadaddr.addr1_text = glob_rec_invoicehead.addr1_text 
		LET l_rec_credheadaddr.addr2_text = glob_rec_invoicehead.addr2_text 
		LET l_rec_credheadaddr.city_text = glob_rec_invoicehead.city_text 
		LET l_rec_credheadaddr.state_code = glob_rec_invoicehead.state_code 
		LET l_rec_credheadaddr.post_code = glob_rec_invoicehead.post_code 
		LET l_err_message = "A2E - Credhead INSERT" 

		#
		# Check IF corporate debtor
		# AND change original customer code
		#
		LET l_rec_credithead.org_cust_code = glob_rec_invoicehead.org_cust_code 
		LET l_rec_credithead.reason_code = p_cred_reason 

		INSERT INTO credithead VALUES (l_rec_credithead.*) 

		#
		# Transfer invoice gets inserted INTO stattrig
		#
		LET l_rec_stattrig.cmpy_code = l_rec_credithead.cmpy_code 
		LET l_rec_stattrig.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_stattrig.trans_num = l_rec_credithead.cred_num 
		LET l_rec_stattrig.tran_date = l_rec_credithead.cred_date 

		INSERT INTO stattrig VALUES (l_rec_stattrig.*) 

		IF l_rec_credheadaddr.addr1_text IS NOT NULL 
		OR l_rec_credheadaddr.addr2_text IS NOT NULL 
		OR l_rec_credheadaddr.city_text IS NOT NULL 
		OR l_rec_credheadaddr.state_code IS NOT NULL 
		OR l_rec_credheadaddr.ship_text IS NOT NULL 
		OR l_rec_credheadaddr.post_code IS NOT NULL THEN 
			INSERT INTO credheadaddr VALUES (l_rec_credheadaddr.*) 
		END IF 

		# Update old customer balance AND o/p an araudit row
		LET l_err_message = "A2E - Customer UPDATE" 
		DECLARE c1_customer CURSOR FOR 
		SELECT * INTO glob_rec_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		FOR UPDATE 

		FOREACH c1_customer 
			LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
			LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt - l_rec_credithead.total_amt 
			CASE 
				WHEN l_invoice_age <=0 
					LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt - 
					l_rec_credithead.total_amt 
				WHEN l_invoice_age >=1 AND l_invoice_age <=30 
					LET glob_rec_customer.over1_amt = glob_rec_customer.over1_amt - 
					l_rec_credithead.total_amt 
				WHEN l_invoice_age >=31 AND l_invoice_age <=60 
					LET glob_rec_customer.over30_amt=glob_rec_customer.over30_amt - 
					l_rec_credithead.total_amt 
				WHEN l_invoice_age >=61 AND l_invoice_age <=90 
					LET glob_rec_customer.over60_amt=glob_rec_customer.over60_amt - 
					l_rec_credithead.total_amt 
				OTHERWISE 
					LET glob_rec_customer.over90_amt=glob_rec_customer.over90_amt - 
					l_rec_credithead.total_amt 
			END CASE 

			LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
			LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
			LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
			LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
			LET l_rec_araudit.tran_text = "Enter Credit" 
			LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
			LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_araudit.year_num = l_rec_credithead.year_num 
			LET l_rec_araudit.period_num = l_rec_credithead.period_num 
			LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
			LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_err_message = "A2E - Araudit INSERT" 

			INSERT INTO araudit VALUES (l_rec_araudit.*) 
			
			LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt -	(glob_rec_customer.bal_amt + glob_rec_customer.onorder_amt) 
			LET glob_rec_customer.ytds_amt = 	glob_rec_customer.ytds_amt - l_rec_credithead.total_amt 
			LET glob_rec_customer.mtds_amt = 	glob_rec_customer.mtds_amt - l_rec_credithead.total_amt 
			LET l_err_message = "A2E - Customer UPDATE" 

			UPDATE customer 
			SET 
				next_seq_num = glob_rec_customer.next_seq_num, 
				bal_amt = glob_rec_customer.bal_amt, 
				curr_amt = glob_rec_customer.curr_amt, 
				over1_amt = glob_rec_customer.over1_amt, 
				over30_amt = glob_rec_customer.over30_amt, 
				over60_amt = glob_rec_customer.over60_amt, 
				over90_amt = glob_rec_customer.over90_amt, 
				cred_bal_amt = glob_rec_customer.cred_bal_amt, 
				ytds_amt = glob_rec_customer.ytds_amt, 
				mtds_amt = glob_rec_customer.mtds_amt 
			WHERE 
				cust_code = glob_rec_customer.cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END FOREACH 
		# Insert new invoice header AND UPDATE new customer balances
		LET l_err_message = "A2E - Invoice INSERT " 
		#
		# Check FOR corporate debtor
		# AND change original customer code
		#
		IF p_rec_t_invoicehead.org_cust_code = glob_rec_org_customer.cust_code THEN 
			LET p_rec_t_invoicehead.org_cust_code = NULL 
		END IF 
		#
		# Make sure you get corporate debtor cust_code
		# WHEN transferring FROM one originating debtor
		# TO another originating debtor
		#
		SELECT corp_cust_code,corp_cust_ind 
		INTO l_v_corp_cust_code,l_v_corp_cust_ind 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_rec_t_invoicehead.cust_code 
		
		IF l_v_corp_cust_code IS NOT NULL AND	l_v_corp_cust_ind = "1" THEN 
			LET p_rec_t_invoicehead.org_cust_code = p_rec_t_invoicehead.cust_code 
			LET p_rec_t_invoicehead.cust_code = l_v_corp_cust_code 
		END IF 

		CALL db_term_get_rec(UI_OFF,glob_rec_t_customer.term_code ) RETURNING l_rec_term.*
					
		CALL get_due_and_discount_date(l_rec_term.*,p_rec_t_invoicehead.inv_date) 
		RETURNING 
			p_rec_t_invoicehead.due_date,	
			p_rec_t_invoicehead.disc_date 
		
		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,p_rec_t_invoicehead.*) THEN
			INSERT INTO invoicehead VALUES (p_rec_t_invoicehead.*)
		ELSE
			DISPLAY p_rec_t_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 
		 
		LET l_t_invoice_age = get_age_bucket(TRAN_TYPE_INVOICE_IN,p_rec_t_invoicehead.due_date)
		 
		#----------------------------------------------
		# Insertion INTO stattrig FOR invoices
		#
		
		LET l_rec_stattrig.cmpy_code = p_rec_t_invoicehead.cmpy_code 
		LET l_rec_stattrig.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_stattrig.trans_num = p_rec_t_invoicehead.inv_num 
		LET l_rec_stattrig.tran_date = p_rec_t_invoicehead.inv_date 
		
		INSERT INTO stattrig VALUES (l_rec_stattrig.*) 
		
		LET l_err_message = "A2E - Customer UPDATE " 
		
		DECLARE c2_customer CURSOR FOR 
		SELECT * INTO glob_rec_t_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_rec_t_invoicehead.cust_code 
		FOR UPDATE 
		
		FOREACH c2_customer 
			LET glob_rec_t_customer.next_seq_num = glob_rec_t_customer.next_seq_num + 1 
			LET glob_rec_t_customer.bal_amt =	glob_rec_t_customer.bal_amt + p_rec_t_invoicehead.total_amt 
			CASE 
				WHEN l_t_invoice_age <=0 
					LET glob_rec_t_customer.curr_amt = glob_rec_t_customer.curr_amt + 
					p_rec_t_invoicehead.total_amt 
				WHEN l_t_invoice_age >=1 AND l_t_invoice_age <=30 
					LET glob_rec_t_customer.over1_amt = glob_rec_t_customer.over1_amt + 
					p_rec_t_invoicehead.total_amt 
				WHEN l_t_invoice_age >=31 AND l_t_invoice_age <=60 
					LET glob_rec_t_customer.over30_amt=glob_rec_t_customer.over30_amt + 
					p_rec_t_invoicehead.total_amt 
				WHEN l_t_invoice_age >=61 AND l_t_invoice_age <=90 
					LET glob_rec_t_customer.over60_amt=glob_rec_t_customer.over60_amt + 
					p_rec_t_invoicehead.total_amt 
				OTHERWISE 
					LET glob_rec_t_customer.over90_amt=glob_rec_t_customer.over90_amt + 
					p_rec_t_invoicehead.total_amt 
			END CASE 
			LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_araudit.tran_date = p_rec_t_invoicehead.inv_date 
			LET l_rec_araudit.cust_code = p_rec_t_invoicehead.cust_code 
			LET l_rec_araudit.seq_num = glob_rec_t_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
			LET l_rec_araudit.source_num = p_rec_t_invoicehead.inv_num 
			LET l_rec_araudit.tran_text = "Enter Invoice" 
			LET l_rec_araudit.tran_amt = p_rec_t_invoicehead.total_amt 
			LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_araudit.sales_code = p_rec_t_invoicehead.sale_code 
			LET l_rec_araudit.year_num = p_rec_t_invoicehead.year_num 
			LET l_rec_araudit.period_num = p_rec_t_invoicehead.period_num 
			LET l_rec_araudit.bal_amt = glob_rec_t_customer.bal_amt 
			LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = p_rec_t_invoicehead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_err_message = "A2E - Unable TO add TO AR log table "
			 
			INSERT INTO araudit VALUES (l_rec_araudit.*) 
			
			IF (glob_rec_t_customer.bal_amt > glob_rec_t_customer.highest_bal_amt) THEN 
				LET glob_rec_t_customer.highest_bal_amt = glob_rec_t_customer.bal_amt 
			END IF 
			
			LET glob_rec_t_customer.cred_bal_amt = glob_rec_t_customer.cred_limit_amt - (glob_rec_t_customer.bal_amt + glob_rec_t_customer.onorder_amt) 
			IF year(p_rec_t_invoicehead.inv_date) > year(glob_rec_t_customer.last_inv_date) THEN 
				LET glob_rec_t_customer.ytds_amt = 0 
			END IF 
			
			LET glob_rec_t_customer.ytds_amt = glob_rec_t_customer.ytds_amt + p_rec_t_invoicehead.total_amt 
			
			IF (month(p_rec_t_invoicehead.inv_date) > month(glob_rec_t_customer.last_inv_date) 
			OR year(p_rec_t_invoicehead.inv_date) > year(glob_rec_t_customer.last_inv_date)) THEN 
				LET glob_rec_t_customer.mtds_amt = 0 
			END IF 
			
			LET glob_rec_t_customer.mtds_amt = glob_rec_t_customer.mtds_amt + p_rec_t_invoicehead.total_amt 
			LET glob_rec_t_customer.last_inv_date = p_rec_t_invoicehead.inv_date 
			LET l_err_message = "A2E - Customer actual UPDATE " 
			
			UPDATE customer 
			SET 
				next_seq_num = glob_rec_t_customer.next_seq_num, 
				bal_amt = glob_rec_t_customer.bal_amt, 
				curr_amt = glob_rec_t_customer.curr_amt, 
				over1_amt = glob_rec_t_customer.over1_amt, 
				over30_amt = glob_rec_t_customer.over30_amt, 
				over60_amt = glob_rec_t_customer.over60_amt, 
				over90_amt = glob_rec_t_customer.over90_amt, 
				highest_bal_amt = glob_rec_t_customer.highest_bal_amt, 
				cred_bal_amt = glob_rec_t_customer.cred_bal_amt, 
				last_inv_date = glob_rec_t_customer.last_inv_date, 
				ytds_amt = glob_rec_t_customer.ytds_amt, 
				mtds_amt = glob_rec_t_customer.mtds_amt 
			WHERE cust_code = glob_rec_t_customer.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END FOREACH 
		#
		# FOR each detail line on the original invoice,create a credit detail
		# line TO match AND a corresponding detail FOR the new invoice.
		# OUTPUT a prodledg row FOR inventory items TO reflect the credit AND
		# debit. Note that only the prodstatus sequence num IS updated as the
		# net effect on the stock IS nil
		# Note that the entries are marked as posted FOR the same reason
		# AND TO move the stock in AND out again distorts FIFO costing
		#
		DECLARE c_invoicedetl CURSOR FOR 
		SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
		WHERE cmpy_code = glob_rec_invoicehead.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		FOREACH c_invoicedetl 
			#
			# Retrieve prodstatus info FOR inventory items AND OUTPUT a credit
			# prodledg followed by a prodledg FOR the new invoice
			#
			LET l__seq_num = 0 
			IF l_rec_invoicedetl.part_code IS NOT NULL THEN 
				DECLARE c_prodstatus CURSOR FOR 
				SELECT rowid, seq_num, onhand_qty 
				FROM prodstatus 
				WHERE cmpy_code = l_rec_invoicedetl.cmpy_code 
				AND part_code = l_rec_invoicedetl.part_code 
				AND ware_code = l_rec_invoicedetl.ware_code 
				FOR UPDATE 

				OPEN c_prodstatus 
				FETCH c_prodstatus INTO l_prodrow, l__seq_num, l_onhand_qty 
				UPDATE prodstatus 
				SET seq_num = seq_num + 2 
				WHERE rowid = l_prodrow 

				LET l_rec_prodledg.cmpy_code = l_rec_invoicedetl.cmpy_code 
				LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
				LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
				LET l_rec_prodledg.tran_date = l_rec_credithead.cred_date 
				LET l_rec_prodledg.seq_num = l__seq_num + 1 
				LET l_rec_prodledg.trantype_ind = "C" 
				LET l_rec_prodledg.year_num = l_rec_credithead.year_num 
				LET l_rec_prodledg.period_num = l_rec_credithead.period_num 
				LET l_rec_prodledg.source_text = l_rec_invoicedetl.cust_code 
				LET l_rec_prodledg.source_num = l_rec_credithead.cred_num 
				LET l_rec_prodledg.tran_qty = l_rec_invoicedetl.ship_qty 
				LET l_rec_prodledg.bal_amt = l_onhand_qty + l_rec_invoicedetl.ship_qty 

				IF glob_rec_invoicehead.conv_qty IS NOT NULL THEN 
					IF glob_rec_invoicehead.conv_qty != 0 THEN 
						LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt / glob_rec_invoicehead.conv_qty 
						LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt / glob_rec_invoicehead.conv_qty 
					END IF 
				END IF

				CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.* 
				
				IF l_rec_inparms.hist_flag = "Y" THEN 
					LET l_rec_prodledg.hist_flag = "N" 
				ELSE 
					LET l_rec_prodledg.hist_flag = "Y" 
				END IF 

				LET l_rec_prodledg.post_flag = "Y" 
				LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_prodledg.entry_date = today 
				LET l_err_message = "A2E - Itemledg C INSERT" 

				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

				LET l_rec_prodledg.seq_num = l__seq_num + 2 
				LET l_rec_prodledg.trantype_ind = "S" 
				LET l_rec_prodledg.tran_date = p_rec_t_invoicehead.inv_date 
				LET l_rec_prodledg.year_num = p_rec_t_invoicehead.year_num 
				LET l_rec_prodledg.period_num = p_rec_t_invoicehead.period_num 
				LET l_rec_prodledg.source_text = p_rec_t_invoicehead.cust_code 
				LET l_rec_prodledg.source_num = p_rec_t_invoicehead.inv_num 
				LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty 
				LET l_rec_prodledg.post_flag = "Y" 
				LET l_rec_prodledg.bal_amt = l_onhand_qty 
				LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_prodledg.entry_date = today 
				LET l_err_message = "A2E - Itemledg S INSERT" 

				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

			END IF 

			LET l_rec_creditdetl.cmpy_code = l_rec_invoicedetl.cmpy_code 
			LET l_rec_creditdetl.cust_code = l_rec_invoicedetl.cust_code 
			LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
			LET l_rec_creditdetl.line_num = l_rec_invoicedetl.line_num 
			LET l_rec_creditdetl.part_code = l_rec_invoicedetl.part_code 
			LET l_rec_creditdetl.ware_code = l_rec_invoicedetl.ware_code 
			LET l_rec_creditdetl.cat_code = l_rec_invoicedetl.cat_code 
			LET l_rec_creditdetl.ship_qty = l_rec_invoicedetl.ship_qty 
			LET l_rec_creditdetl.ser_ind = l_rec_invoicedetl.ser_flag 
			LET l_rec_creditdetl.line_text = l_rec_invoicedetl.line_text 
			LET l_rec_creditdetl.uom_code = l_rec_invoicedetl.uom_code 
			LET l_rec_creditdetl.unit_cost_amt = l_rec_invoicedetl.unit_cost_amt 
			LET l_rec_creditdetl.ext_cost_amt = l_rec_invoicedetl.ext_cost_amt 
			LET l_rec_creditdetl.disc_amt = l_rec_invoicedetl.disc_amt 
			LET l_rec_creditdetl.unit_sales_amt = l_rec_invoicedetl.unit_sale_amt 
			LET l_rec_creditdetl.ext_sales_amt = l_rec_invoicedetl.ext_sale_amt 
			LET l_rec_creditdetl.unit_tax_amt = l_rec_invoicedetl.unit_tax_amt 
			LET l_rec_creditdetl.ext_tax_amt = l_rec_invoicedetl.ext_tax_amt 
			LET l_rec_creditdetl.line_total_amt = l_rec_invoicedetl.line_total_amt 
			LET l_rec_creditdetl.seq_num = l__seq_num + 1 
			LET l_rec_creditdetl.line_acct_code = l_rec_invoicedetl.line_acct_code 
			LET l_rec_creditdetl.job_code = NULL 
			LET l_rec_creditdetl.level_code = l_rec_invoicedetl.level_code 
			LET l_rec_creditdetl.comm_amt = l_rec_invoicedetl.comm_amt 
			LET l_rec_creditdetl.tax_code = l_rec_invoicedetl.tax_code 
			LET l_rec_creditdetl.reason_code = p_cred_reason 
			LET l_err_message = "A2E - Credline INSERT" 

			INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 

			LET l_rec_invoicedetl.cust_code = p_rec_t_invoicehead.cust_code 
			LET l_rec_invoicedetl.inv_num = p_rec_t_invoicehead.inv_num 
			LET l_rec_invoicedetl.seq_num = l__seq_num + 2 

			#----------------------------------------------------
			# Apply the new acct override code TO inventory items
			#
			IF l_rec_invoicedetl.part_code IS NOT NULL THEN 
				CALL account_patch(
					glob_rec_kandoouser.cmpy_code, 
					l_rec_invoicedetl.line_acct_code, 
					p_rec_t_invoicehead.acct_override_code) 
				RETURNING l_rec_invoicedetl.line_acct_code 
			END IF 

			#INSERT invoiceDetl Record
			IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
				INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
			ELSE
				DISPLAY l_rec_invoicedetl.*
				CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
			END IF 
			
			LET l_err_message = "A2E - Invline INSERT" 

			LET l_err_message = "A2E - old invoiceline UPDATE" 
			UPDATE invoicedetl SET return_qty = l_rec_invoicedetl.ship_qty 
			WHERE inv_num = glob_rec_invoicehead.inv_num 
			AND line_num = l_rec_invoicedetl.line_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		END FOREACH 

		DECLARE c_invheadext CURSOR FOR 
		SELECT * FROM invheadext 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		
		FOREACH c_invheadext INTO l_rec_invheadext.* 
			LET l_rec_t_invheadext.* = l_rec_invheadext.* 
			LET l_rec_t_invheadext.inv_num = p_rec_t_invoicehead.inv_num 
			LET l_rec_t_invheadext.cust_code = p_rec_t_invoicehead.cust_code 

			INSERT INTO invheadext VALUES (l_rec_t_invheadext.*) 

			LET l_rec_t_creditheadext.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_t_creditheadext.cust_code = l_rec_credithead.cust_code 
			LET l_rec_t_creditheadext.org_cust_code = l_rec_credithead.org_cust_code 
			LET l_rec_t_creditheadext.credit_num = l_rec_credithead.cred_num 
			LET l_rec_t_creditheadext.del_num = l_rec_invheadext.del_num 
			LET l_rec_t_creditheadext.map_gps_coordinates = l_rec_invheadext.map_gps_coordinates
			LET l_rec_t_creditheadext.ref1_code = l_rec_invheadext.ref1_code 
			LET l_rec_t_creditheadext.ref2_code = l_rec_invheadext.ref2_code 
			LET l_rec_t_creditheadext.ref3_code = l_rec_invheadext.ref3_code 
			LET l_rec_t_creditheadext.ref4_code = l_rec_invheadext.ref4_code 
			LET l_rec_t_creditheadext.ref5_code = l_rec_invheadext.ref5_code 
			LET l_rec_t_creditheadext.ref6_code = l_rec_invheadext.ref6_code 
			LET l_rec_t_creditheadext.ref7_code = l_rec_invheadext.ref7_code 
			LET l_rec_t_creditheadext.ref8_code = l_rec_invheadext.ref8_code 
			--LET l_rec_t_creditheadext.mobile_phone = l_rec_invheadext.mobile_phone 
			LET l_rec_t_creditheadext.km_qty = l_rec_invheadext.km_qty 
			LET l_rec_t_creditheadext.cart_area_code = l_rec_invheadext.cart_area_code 
			LET l_rec_t_creditheadext.transp_type_code = l_rec_invheadext.transp_type_code 
			LET l_rec_t_creditheadext.veh_type_code = l_rec_invheadext.veh_type_code 
			LET l_rec_t_creditheadext.vehicle_code = l_rec_invheadext.vehicle_code 
			LET l_rec_t_creditheadext.driver_code = l_rec_invheadext.driver_code 
			LET l_rec_t_creditheadext.initials_text = l_rec_invheadext.initials_text 
			LET l_rec_t_creditheadext.ord_ind = l_rec_invheadext.ord_ind 
			LET l_rec_t_creditheadext.job_territory = l_rec_invheadext.job_territory 
			LET l_rec_t_creditheadext.job_area = l_rec_invheadext.job_area 
			LET l_rec_t_creditheadext.locn_code = l_rec_invheadext.locn_code 

			INSERT INTO creditheadext VALUES (l_rec_t_creditheadext.*) 

		END FOREACH 
		
		DECLARE c_invrates CURSOR FOR 
		SELECT * FROM invrates 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = glob_rec_invoicehead.inv_num 
		
		FOREACH c_invrates INTO l_rec_invrates.* 
			LET l_rec_t_invrates.* = l_rec_invrates.* 
			LET l_rec_t_invrates.inv_num = p_rec_t_invoicehead.inv_num 

			INSERT INTO invrates VALUES (l_rec_t_invrates.*) 

			LET l_rec_t_creditrates.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_t_creditrates.cred_num = l_rec_credithead.cred_num 
			LET l_rec_t_creditrates.line_num = l_rec_invrates.line_num 
			LET l_rec_t_creditrates.rate_type = l_rec_invrates.rate_type 
			LET l_rec_t_creditrates.unit_price_amt = l_rec_invrates.unit_price_amt 
			LET l_rec_t_creditrates.unit_tax_amt = l_rec_invrates.unit_tax_amt 

			INSERT INTO creditrates VALUES (l_rec_t_creditrates.*) 

		END FOREACH 
		
	COMMIT WORK 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	LET l_temp_text = "inv_num = ",glob_rec_invoicehead.inv_num USING "<<<<<<<<" 
	
	RETURN p_rec_t_invoicehead.inv_num, l_rec_credithead.cred_num 
END FUNCTION 
############################################################
# END FUNCTION transfer_invoice(p_rec_t_invoicehead, p_cred_reason)   
############################################################


############################################################
# REPORT A2E_rpt_list_invoice(p_rpt_idx,p_old_inv,p_new_inv,p_new_cred)
#
#
############################################################
REPORT A2E_rpt_list_invoice(p_rpt_idx,p_old_inv,p_new_inv,p_new_cred) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_old_inv LIKE invoicehead.inv_num
	DEFINE p_new_inv LIKE invoicehead.inv_num
	DEFINE p_new_cred LIKE credithead.cred_num

	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE l_line1 NCHAR(80)
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 
	DEFINE l_temp_string STRING
	OUTPUT 

	ORDER BY p_old_inv 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			 
			PRINT COLUMN 01, "Invoice Transferred", 
			COLUMN 22, "Credit Created", 
			COLUMN 39, "New Invoice"
			 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			
			PRINT COLUMN 01,"FROM:", 
			COLUMN 07, glob_rec_customer.cust_code, 
			COLUMN 38,"To:", 
			COLUMN 42, glob_rec_t_customer.cust_code
			 
			PRINT COLUMN 07, glob_rec_customer.name_text, 
			COLUMN 42, glob_rec_t_customer.name_text
			 
		ON EVERY ROW 
			PRINT COLUMN 12, p_old_inv USING "#######&", 
			COLUMN 28, p_new_cred USING "#######&", 
			COLUMN 42, p_new_inv USING "#######&"
			 
		ON LAST ROW 
			SKIP 3 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno
END REPORT 
############################################################
# END REPORT A2E_rpt_list_invoice(p_rpt_idx,p_old_inv,p_new_inv,p_new_cred)
############################################################
