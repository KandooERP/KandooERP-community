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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

#################################################################
# MODULE scope variables
#################################################################

#################################################################
# FUNCTION A41_enter_credit_customer_detail(p_mode)
#
#
#################################################################
FUNCTION A41_enter_credit_customer_detail(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_corpcust RECORD LIKE customer.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE i SMALLINT 

	IF glob_rec_credithead.cust_code IS NOT NULL THEN
		CALL db_customer_get_rec(UI_OFF,glob_rec_credithead.cust_code) RETURNING glob_rec_customer.* 
--		SELECT * INTO glob_rec_customer.* 
--		FROM customer 
--		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--		AND cust_code = glob_rec_credithead.cust_code 

		IF glob_rec_customer.cust_code IS NULL THEN
			ERROR kandoomsg2("A",9009,"") 		#A9009 Customer NOT found"
			LET glob_rec_customer.name_text = "**********" 
		END IF 
		
		IF glob_rec_customer.delete_flag = "Y" THEN 
			ERROR kandoomsg2("A",7022,glob_rec_customer.name_text) 		#7022 Customer ???? has been marked FOR deletion
			LET glob_rec_customer.name_text = "**********" 
		END IF 

	END IF 

	INPUT BY NAME glob_rec_customer.cust_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			IF p_mode = MODE_CLASSIC_EDIT THEN 
				DISPLAY BY NAME glob_rec_credithead.cred_num 

				EXIT INPUT 
			ELSE 
				MESSAGE kandoomsg2("E",1063,"") 	#1063 Enter Customer TO be receice Credit Note - ESC TO Cont"
			END IF 

			CALL publish_toolbar("kandoo","A41a","inp-cust_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET glob_temp_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET glob_rec_customer.cust_code = glob_temp_text 
			END IF 
			NEXT FIELD cust_code 

		ON CHANGE cust_code
			
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_customer.cust_code) TO customer.name_text

			--DISPLAY db_customer_get_corp_cust_code(UI_OFF,glob_rec_customer.cust_code) TO customer.corp_cust_code
			--DISPLAY db_customer_get_name_text(UI_OFF,db_customer_get_corp_cust_code(UI_OFF,glob_rec_customer.cust_code)) TO cooperate_cust_name_text

			CALL db_country_localize(db_customer_get_country_code(UI_OFF,glob_rec_customer.cust_code)) #Localize
			DISPLAY db_customer_get_addr1_text(UI_OFF,glob_rec_customer.cust_code) TO customer.addr1_text
			DISPLAY db_customer_get_addr2_text(UI_OFF,glob_rec_customer.cust_code) TO customer.addr2_text
			DISPLAY db_customer_get_city_text(UI_OFF,glob_rec_customer.cust_code) TO customer.city_text
			DISPLAY db_customer_get_state_code(UI_OFF,glob_rec_customer.cust_code) TO customer.state_code
			DISPLAY db_customer_get_post_code(UI_OFF,glob_rec_customer.cust_code) TO customer.post_code
			DISPLAY glob_rec_customer.cust_code TO customer.country_code--@db-patch_2020_10_04--
			--DISPLAY db_customer_get_hold_code(UI_OFF,glob_rec_customer.cust_code) TO customer.hold_code
			DISPLAY db_customer_get_currency_code(UI_OFF,glob_rec_customer.cust_code) TO customer.currency_code
			--DISPLAY db_customer_get_curr_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.curr_amt
			--DISPLAY db_customer_get_over1_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.over1_amt
			--DISPLAY db_customer_over30_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.over30_amt
			--DISPLAY db_customer_over60_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.over60_amt
			--DISPLAY db_customer_over90_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.over90_amt
			--DISPLAY db_customer_bal_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.bal_amt
			--DISPLAY db_customer_cred_limit_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.cred_limit_amt
			--DISPLAY db_customer_balance_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.balance_amt
			--DISPLAY db_customer_onorder_amt(UI_OFF,glob_rec_customer.cust_code) TO customer.onorder_amt

--------------------------------------------		
		AFTER FIELD cust_code 
			CLEAR name_text 
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("A",9024,"") 			#9024" Cust. must be Entered"
				LET glob_rec_customer.cust_code = glob_rec_credithead.cust_code 
				NEXT FIELD cust_code 
			END IF 


			IF glob_rec_customer.cust_code IS NULL THEN
				SELECT * INTO glob_rec_customer.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				AND delete_flag = "N" 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9009,"") 			#9009" Cust NOT found - Try Window"
					NEXT FIELD cust_code 
				END IF 
			END IF
			
			IF glob_rec_customer.corp_cust_code IS NOT NULL AND	glob_rec_customer.corp_cust_ind = "1" THEN 
				SELECT * INTO l_rec_corpcust.* 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.corp_cust_code 
				AND delete_flag = "N" 
				IF sqlca.sqlcode = 0 THEN 
					ERROR kandoomsg2("E",7073,l_rec_corpcust.name_text) 				#7073" Must raise credit in name of corporate cust",
					LET glob_rec_credithead.org_cust_code = glob_rec_customer.cust_code 
					LET glob_rec_customer.* = l_rec_corpcust.* 
				END IF 
			END IF 

			IF glob_rec_customer.hold_code IS NOT NULL THEN 
				SELECT reason_text INTO glob_temp_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_customer.hold_code 
				ERROR kandoomsg2("E",7018,glob_temp_text) 		#7018" Warning : Nominated Customer 'On Hold'"
			END IF 
			
			IF glob_rec_credithead.cust_code IS NOT NULL	AND glob_rec_credithead.cust_code != glob_rec_customer.cust_code THEN 
				# DELETE FROM t_creditdetl ------------------
				DELETE FROM t_creditdetl 
			END IF 
			
			LET glob_rec_credithead.cust_code = glob_rec_customer.cust_code 
			LET glob_rec_credithead.currency_code = glob_rec_customer.currency_code 



	END INPUT 

	DISPLAY glob_rec_customer.name_text TO name_text  
	DISPLAY glob_rec_customer.addr1_text TO addr1_text 
	DISPLAY glob_rec_customer.addr2_text TO addr2_text 
	DISPLAY glob_rec_customer.city_text TO city_text  
	DISPLAY glob_rec_customer.state_code TO state_code 
	DISPLAY glob_rec_customer.post_code TO post_code 
	DISPLAY glob_rec_customer.country_code TO country_code --@db-patch_2020_10_04--

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE glob_rec_customer.* TO NULL
	END IF
	
	RETURN glob_rec_customer.* 
END FUNCTION 
#################################################################
# END FUNCTION A41_enter_credit_customer_detail(p_mode)
#################################################################


#################################################################
# FUNCTION invoice_dataSource_query(p_filter) used to beFUNCTION select_invoice()
#
#
#################################################################
FUNCTION invoice_datasource_query(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_where_text STRING 
	DEFINE i SMALLINT 


	--   FOR i = 1 TO 4
	--      CLEAR sr_invoicehead[i].*
	--      CLEAR sr_invoicedetl[i].*
	--   END FOR



	IF p_filter THEN 
		INITIALIZE glob_rec_credheadaddr.* TO NULL 

		MESSAGE kandoomsg2("E",1001,"") 	#1001 Enter Selection Criteria - ESC TO Continue
		CONSTRUCT l_where_text ON 
			invoicehead.inv_num, 
			invoicehead.inv_date, 
			invoicehead.purchase_code, 
			invoicehead.total_amt, 
			invoicedetl.line_num, 
			invoicedetl.line_text, 
			invoicedetl.ship_qty, 
			invoicedetl.line_total_amt 
		FROM 
			invoicehead.inv_num, 
			invoicehead.inv_date, 
			invoicehead.purchase_code, 
			invoicehead.total_amt, 
			invoicedetl.line_num, 
			invoicedetl.line_text, 
			invoicedetl.ship_qty, 
			invoicedetl.line_total_amt 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A41a","construct-invoicehead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL 
	END IF 

	RETURN l_where_text 
END FUNCTION 
#################################################################
# END FUNCTION invoice_dataSource_query(p_filter) used to beFUNCTION select_invoice()
#################################################################


#################################################################
# FUNCTION invoice_datasource(l_where_text) 
#
#
#################################################################
FUNCTION invoice_datasource(l_where_text) 
	DEFINE l_where_text STRING 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF t_rec_invoicehead_in_id_pc_ia_ca_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 

	IF l_where_text IS NULL THEN 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("E",1002,"") #1002 Searching database so wait
	IF glob_rec_credithead.org_cust_code IS NOT NULL THEN 
		LET l_where_text = l_where_text clipped," ", "AND invoicehead.org_cust_code='",glob_rec_credithead.org_cust_code,"'" 
	END IF 
	
	LET l_query_text = 
		"SELECT unique invoicehead.cust_code,", 
		"invoicehead.inv_num ", 
		"FROM invoicehead,", 
		"invoicedetl ", 
		"WHERE invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicedetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND invoicehead.inv_num = invoicedetl.inv_num ", 
		"AND invoicehead.cust_code='",glob_rec_credithead.cust_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_invoicehead FROM l_query_text 
	DECLARE c_invoicehead CURSOR FOR s_invoicehead 
	LET l_idx = 0 

	FOREACH c_invoicehead INTO glob_rec_invoicehead.cust_code, glob_rec_invoicehead.inv_num 
		LET l_idx = l_idx + 1
		CALL db_invoicehead_get_rec(UI_OFF,glob_rec_invoicehead.inv_num) RETURNING glob_rec_invoicehead.*		 
		--SELECT * INTO glob_rec_invoicehead.* 
		--FROM invoicehead 
		--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		--AND inv_num = glob_rec_invoicehead.inv_num 

		LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].inv_amt = glob_rec_invoicehead.goods_amt	+ glob_rec_invoicehead.tax_amt 

		SELECT sum(line_total_amt) INTO l_arr_rec_invoicehead[l_idx].credit_amt 
		FROM t_creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND invoice_num = glob_rec_invoicehead.inv_num 

		IF l_arr_rec_invoicehead[l_idx].credit_amt IS NULL THEN 
			LET l_arr_rec_invoicehead[l_idx].credit_amt = 0 
			LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
		ELSE 
			LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
		END IF 
--		IF l_idx = 40 THEN 
--			ERROR kandoomsg2("E",9215,"40") 	#9215" Maximum 40 invoices selected "
--			EXIT FOREACH 
--		END IF 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 
CALL db_show_creditdetl_arr_rec() #huho-debug
	RETURN l_arr_rec_invoicehead 
END FUNCTION
#################################################################
# END FUNCTION invoice_datasource(l_where_text) 
#################################################################


#################################################################
# FUNCTION A41_invoice_list_for_credit(l_where_text)
#
#
#################################################################
FUNCTION A41_invoice_list_for_credit(l_where_text) 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF t_rec_invoicehead_in_id_pc_ia_ca_with_scrollflag 
	#	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF #array[40] of record
	#		RECORD
	#         scroll_flag CHAR(1),
	#         inv_num LIKE invoicehead.inv_num,
	#         inv_date LIKE invoicehead.inv_date,
	#         purchase_code LIKE invoicehead.purchase_code,
	#         inv_amt LIKE invoicehead.total_amt,
	#         credit_amt LIKE invoicehead.total_amt
	#      END RECORD
	DEFINE l_part_code LIKE creditdetl.part_code 
	DEFINE l_ware_code LIKE creditdetl.ware_code 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_shipaddr_found SMALLINT 
	DEFINE l_idx SMALLINT 

	IF l_where_text IS NULL THEN 
		CALL invoice_datasource_query(false) RETURNING l_where_text 
		IF l_where_text IS NULL THEN 
			LET l_where_text = " 1=1 " 
		END IF 
	END IF 

	CALL l_arr_rec_invoicehead.clear() 
	CALL invoice_datasource(l_where_text) RETURNING l_arr_rec_invoicehead 
	{
	   MESSAGE kandoomsg2("E",1002,"")	#1002 Searching database so wait
	   IF glob_rec_credithead.org_cust_code IS NOT NULL THEN
	      LET l_where_text = l_where_text clipped," ",
	       "AND invoicehead.org_cust_code='",glob_rec_credithead.org_cust_code,"'"
	   END IF
	   LET l_query_text =
	      "SELECT unique invoicehead.cust_code,",
	                    "invoicehead.inv_num ",
	               "FROM invoicehead,",
	                    "invoicedetl ",
	              "WHERE invoicehead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
	                "AND invoicedetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ",
	                "AND invoicehead.inv_num = invoicedetl.inv_num ",
	                "AND invoicehead.cust_code='",glob_rec_credithead.cust_code,"' ",
	                "AND ",l_where_text clipped," ",
	              "ORDER BY 1,2"
	   PREPARE s_invoicehead FROM l_query_text
	   DECLARE c_invoicehead CURSOR FOR s_invoicehead
	   LET l_idx = 0

	   FOREACH c_invoicehead INTO glob_rec_invoicehead.cust_code,
	                              glob_rec_invoicehead.inv_num
	      LET l_idx = l_idx + 1
				CALL db_invoicehead_get_rec(UI_OFF,glob_rec_invoicehead.inv_num) RETURNING glob_rec_invoicehead.*
	      --SELECT * INTO glob_rec_invoicehead.*
	      --  FROM invoicehead
	      -- WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	      --   AND inv_num = glob_rec_invoicehead.inv_num
	      LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num
	      LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date
	      LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code
	      LET l_arr_rec_invoicehead[l_idx].inv_amt = glob_rec_invoicehead.goods_amt
	                                      + glob_rec_invoicehead.tax_amt
	      SELECT sum(line_total_amt) INTO l_arr_rec_invoicehead[l_idx].credit_amt
	        FROM t_creditdetl
	       WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	         AND invoice_num = glob_rec_invoicehead.inv_num
	      IF l_arr_rec_invoicehead[l_idx].credit_amt IS NULL THEN
	         LET l_arr_rec_invoicehead[l_idx].credit_amt = 0
	         LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL
	      ELSE
	         LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*"
	      END IF

	   END FOREACH

	}
	--   IF l_idx = 0 THEN
	--      LET l_idx = 1
	--   END IF

	#DISPLAY ARRAY ------------------------------------------------------------------------------
	MESSAGE kandoomsg2("A",1086,"") 	#1086- RETURN Line Items - F8 Cust.Info - F10 Toggle"
	DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A41a","inp-arr-invoicehead-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#BEFORE FIELD scroll_flag

			IF l_idx > 0 THEN 
		
				IF l_arr_rec_invoicehead[l_idx].inv_num > 0 THEN 
					CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,"DISP") 
					
					SELECT sum(line_total_amt) INTO l_arr_rec_invoicehead[l_idx].credit_amt 
					FROM t_creditdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
					IF l_arr_rec_invoicehead[l_idx].credit_amt IS NULL THEN 
						LET l_arr_rec_invoicehead[l_idx].credit_amt = 0 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
					ELSE 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
					END IF 
					#DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*
	
				ELSE 
					LET l_arr_rec_invoicehead[l_idx].inv_num = NULL 
					LET l_arr_rec_invoicehead[l_idx].inv_date = NULL 
					#CLEAR sr_invoicehead[scrn].*
				END IF 
	
				#ON ACTION "doubleClick"  --Invoice Submenu  #huho identical TO F8
				#   CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cust_code)--Customer Details
				#ON ACTION "DOUBLECLICK"

			END IF


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL invoice_datasource_query(true) RETURNING l_where_text 
			
			IF l_where_text IS NULL THEN 
				MESSAGE "Filter aborted" 
			ELSE 
				CALL l_arr_rec_invoicehead.clear() 
				CALL invoice_datasource(l_where_text) RETURNING l_arr_rec_invoicehead 
			END IF 


		ON ACTION "REFRESH" 
			CALL invoice_datasource_query(false) RETURNING l_where_text 
			
			IF l_where_text IS NULL THEN 
				MESSAGE "Filter aborted" 
			ELSE 
				CALL l_arr_rec_invoicehead.clear() 
				CALL invoice_datasource(l_where_text) RETURNING l_arr_rec_invoicehead 
			END IF 

			CALL windecoration_a("A666") 

			
		ON ACTION "SAVE"
			IF l_idx > 0 THEN 
	 		CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,MODE_CLASSIC_EDIT)
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.* 
			END IF
			
			EXIT DISPLAY
			
		ON ACTION ("ACCEPT")
			IF l_idx > 0 THEN 
				CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,MODE_CLASSIC_EDIT)
				MESSAGE kandoomsg2("E",1064,"")		#1064- F2 Delete - RETURN Line Items - F8 Cust.Info
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*
			 --EXIT DISPLAY
			
			#NEXT FIELD scroll_flag
			END IF
			
		ON ACTION "EDIT"		#BEFORE FIELD inv_num  --Update invoice line (display array) for the current invoice
			IF l_idx > 0 THEN
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*
				CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,MODE_CLASSIC_EDIT) 
				MESSAGE kandoomsg2("E",1064,"")		#1064- F2 Delete - RETURN Line Items - F8 Cust.Info
				#  NEXT FIELD scroll_flag
			END IF
			

		ON ACTION "NEW" 
			IF l_idx = 0 THEN #customer has no invoices yet 
				LET l_idx = 1 
			END IF 

			#BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			--            INITIALIZE l_arr_rec_invoicehead[l_idx].* TO NULL

			#            CALL fgl_winmessage("huho: needs investigating","LET l_arr_rec_invoicehead[l_idx].inv_num = enter_invoice(scrn)","info")
			LET l_arr_rec_invoicehead[l_idx].inv_num = enter_invoice(l_idx) --original: LET l_arr_rec_invoicehead[l_idx].inv_num = enter_invoice(scrn) 
			IF l_arr_rec_invoicehead[l_idx].inv_num IS NOT NULL THEN 
				SELECT 
					"",
					inv_num, 
					inv_date, 
					purchase_code, 
					(goods_amt+tax_amt),
					0 
				INTO l_arr_rec_invoicehead[l_idx].* 
				FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND inv_num = l_arr_rec_invoicehead[l_idx].inv_num 

				SELECT sum(line_total_amt) INTO l_arr_rec_invoicehead[l_idx].credit_amt 
				FROM t_creditdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 

				IF l_arr_rec_invoicehead[l_idx].credit_amt IS NULL THEN 
					LET l_arr_rec_invoicehead[l_idx].credit_amt = 0 
					LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
				ELSE 
					LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
				END IF 
			END IF 

			MESSAGE kandoomsg2("E",1064,"")		#1064- F2 Delete - RETURN Line Items - F8 Cust.Info
			#END IF
			#NEXT FIELD scroll_flag

		ON ACTION "DELETE"
			IF l_idx > 0 THEN 
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*		 
				
				# DELETE FROM t_creditdetl ------------------
				DELETE FROM t_creditdetl 
				WHERE invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
				
				CALL A41_credit_total_calculation_display() 
				#AFTER ROW
				#   DISPLAY l_arr_rec_invoicehead[l_idx].* TO sr_invoicehead[scrn].*

			END IF

		ON ACTION "DETAILS" #ON KEY (F8) Customer Details...
			IF l_idx > 0 THEN
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*
			END IF
			
			--ON KEY (F8) --invoice submenu --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cust_code)--customer details 

		ON ACTION "TOGGLE"  #Copy Paste Duplicate of F10
			IF l_idx > 0 THEN
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*			 

				IF l_arr_rec_invoicehead[l_idx].inv_num > 0 THEN 
					IF l_arr_rec_invoicehead[l_idx].scroll_flag = "*" THEN 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
	
						DECLARE c_t_creditdetl2 CURSOR FOR 
						SELECT part_code, ware_code FROM t_creditdetl 
						WHERE invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
	
						FOREACH c_t_creditdetl2 INTO l_part_code, l_ware_code 
							CALL serial_delete(l_part_code, l_ware_code) 
						END FOREACH 
	
						DELETE FROM t_creditdetl 
						WHERE invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
					ELSE 
						IF credit_insert_invoice_line(l_arr_rec_invoicehead[l_idx].inv_num,"") THEN 
							LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
						END IF 
					END IF 

CALL db_show_creditdetl_arr_rec() #huho-debug
	
					CALL A41_credit_total_calculation_display() 
					IF l_idx > 0 THEN
						CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,"DISP")
					END IF 
					#     NEXT FIELD scroll_flag
				END IF 
			END IF

CALL db_show_creditdetl_arr_rec() #huho-debug
					
		ON KEY (F10) #Select
			IF l_idx > 0 THEN 
				CALL db_invoicehead_get_rec(UI_OFF,l_arr_rec_invoicehead[l_idx].inv_num) RETURNING glob_rec_invoicehead.*			 

				IF l_arr_rec_invoicehead[l_idx].inv_num > 0 THEN 
					IF l_arr_rec_invoicehead[l_idx].scroll_flag = "*" THEN 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
	
						DECLARE c2_t_creditdetl2 CURSOR FOR 
						SELECT part_code, ware_code FROM t_creditdetl 
						WHERE invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
	
						FOREACH c2_t_creditdetl2 INTO l_part_code, l_ware_code 
							CALL serial_delete(l_part_code, l_ware_code) 
						END FOREACH 

						# DELETE FROM t_creditdetl ------------------	
						DELETE FROM t_creditdetl 
						WHERE invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
					ELSE 
						IF credit_insert_invoice_line(l_arr_rec_invoicehead[l_idx].inv_num,"") THEN 
							LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*"
	
----------------- from before ROW
					CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,"DISP") 
					SELECT sum(line_total_amt) INTO l_arr_rec_invoicehead[l_idx].credit_amt 
					FROM t_creditdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND invoice_num = l_arr_rec_invoicehead[l_idx].inv_num 
	
					IF l_arr_rec_invoicehead[l_idx].credit_amt IS NULL THEN 
						LET l_arr_rec_invoicehead[l_idx].credit_amt = 0 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = NULL 
					ELSE 
						LET l_arr_rec_invoicehead[l_idx].scroll_flag = "*" 
					END IF 
--------------
	
							 
						END IF 
					END IF 
	
					CALL A41_credit_total_calculation_display() 
	
					IF l_idx > 0 THEN
						CALL inv_line(l_arr_rec_invoicehead[l_idx].inv_num,"DISP")
					END IF 
	
					#     NEXT FIELD scroll_flag
				END IF 
			
			END IF


	END DISPLAY #input 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_shipaddr_found = true 
		SELECT unique 1 FROM t_creditdetl 

		IF status = NOTFOUND THEN 
			INITIALIZE glob_rec_credheadaddr.* TO NULL 
			
			SELECT * INTO l_rec_customership.* FROM customership 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code 
			AND ship_code = glob_rec_customer.cust_code 

			IF status = NOTFOUND THEN 
				DECLARE c1_customership SCROLL CURSOR FOR 
				SELECT * FROM customership 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_customer.cust_code 
				OPEN c1_customership 
				FETCH FIRST c1_customership INTO l_rec_customership.* 

				IF status = NOTFOUND THEN 
					LET l_shipaddr_found = false 
					LET glob_rec_credheadaddr.cmpy_code = glob_rec_customer.cmpy_code 
					LET glob_rec_credheadaddr.addr1_text = glob_rec_customer.addr1_text 
					LET glob_rec_credheadaddr.addr2_text = glob_rec_customer.addr2_text 
					LET glob_rec_credheadaddr.city_text = glob_rec_customer.city_text 
					LET glob_rec_credheadaddr.state_code = glob_rec_customer.state_code 
					LET glob_rec_credheadaddr.post_code = glob_rec_customer.post_code 
					LET glob_rec_credheadaddr.country_code = glob_rec_customer.country_code 
				END IF 
			END IF 
			
			IF l_shipaddr_found THEN 
				LET glob_rec_credheadaddr.cmpy_code = l_rec_customership.cmpy_code 
				LET glob_rec_credheadaddr.addr1_text = l_rec_customership.addr_text 
				LET glob_rec_credheadaddr.addr2_text = l_rec_customership.addr2_text 
				LET glob_rec_credheadaddr.city_text = l_rec_customership.city_text 
				LET glob_rec_credheadaddr.state_code = l_rec_customership.state_code 
				LET glob_rec_credheadaddr.post_code = l_rec_customership.post_code 
				LET glob_rec_credheadaddr.country_code = l_rec_customership.country_code 
			END IF 
		END IF 
		RETURN true 
	END IF 
	CALL fgl_winmessage("RETURN Nothing","RETURN NOTHING from A41_invoice_list_for_credit()","info") 

END FUNCTION 
#################################################################
# END FUNCTION A41_invoice_list_for_credit(l_where_text)
#################################################################


#################################################################
# FUNCTION inv_line(p_inv_num,p_mode)
#
#
#################################################################
FUNCTION inv_line(p_inv_num,p_mode) 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF t_rec_invoicedetl_ln_lt_sq_lt_lc_with_lineflag 
	#	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF #array[250] of record
	#		RECORD
	#         line_flag CHAR(1),
	#         line_num LIKE invoicedetl.line_num,
	#         line_text LIKE invoicedetl.line_text,
	#         ship_qty LIKE invoicedetl.ship_qty,
	#         line_total_amt LIKE invoicedetl.line_total_amt,
	#         line_cred_amt LIKE invoicedetl.line_total_amt
	#		END RECORD
	DEFINE l_part_code LIKE creditdetl.part_code 
	DEFINE l_ware_code LIKE creditdetl.ware_code 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	DECLARE c_invoicedetl CURSOR FOR 
	SELECT * FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_credithead.cust_code 
	AND inv_num = p_inv_num 
	ORDER BY inv_num, line_num 
	LET l_idx = 0 

	FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicedetl[l_idx].line_num = l_rec_invoicedetl.line_num 
		LET l_arr_rec_invoicedetl[l_idx].line_text = l_rec_invoicedetl.line_text 
		LET l_arr_rec_invoicedetl[l_idx].ship_qty = l_rec_invoicedetl.ship_qty 
		LET l_arr_rec_invoicedetl[l_idx].line_total_amt = l_rec_invoicedetl.line_total_amt 
		
		SELECT line_total_amt INTO l_arr_rec_invoicedetl[l_idx].line_cred_amt 
		FROM t_creditdetl 
		WHERE invoice_num = l_rec_invoicedetl.inv_num 
		AND inv_line_num = l_rec_invoicedetl.line_num
		 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_invoicedetl[l_idx].line_flag = NULL 
			LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = 0 
		ELSE 
			LET l_arr_rec_invoicedetl[l_idx].line_flag = "*" 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET p_mode = "DISP" 
	END IF 

	IF p_mode = "DISP" THEN 
		DISPLAY ARRAY l_arr_rec_invoicedetl TO sr_invoicedetl.* WITHOUT SCROLL
--			BEFORE DISPLAY
--				EXIT DISPLAY
--		END DISPLAY
		 
--		FOR l_idx = 1 TO 4 
--			IF l_arr_rec_invoicedetl[l_idx].line_num > 0 THEN 
--				DISPLAY l_arr_rec_invoicedetl[l_idx].* 
--				TO sr_invoicedetl[l_idx].* 
--
--			ELSE 
--				CLEAR sr_invoicedetl[l_idx].* 
--			END IF 
--		END FOR 
	ELSE  --EDIT MODE 
--		OPTIONS INSERT KEY f36, 
--		DELETE KEY f36 

		MESSAGE kandoomsg2("E",1065,"")		#1065 Invoice Line Items - F8 Invoice Info - F10 Toggle Line"
		DISPLAY ARRAY l_arr_rec_invoicedetl TO sr_invoicedetl.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A41a","disp-arr-invoicedetl-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 


				# huho added / F10
				###################
			ON KEY (F10)
				IF l_arr_rec_invoicedetl[l_idx].line_num > 0 THEN 
					IF l_arr_rec_invoicedetl[l_idx].line_flag IS NULL THEN 
						IF credit_insert_invoice_line(p_inv_num,l_arr_rec_invoicedetl[l_idx].line_num) THEN 
							LET l_arr_rec_invoicedetl[l_idx].line_flag = "*" 
							LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = l_arr_rec_invoicedetl[l_idx].line_total_amt 
						END IF 
					ELSE
					 
						SELECT part_code, ware_code 
						INTO l_part_code, l_ware_code FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num 
						
						CALL serial_delete(l_part_code, l_ware_code)
						
						# DELETE FROM t_creditdetl ------------------ 
						DELETE FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num 
						
						LET l_arr_rec_invoicedetl[l_idx].line_flag = NULL 
						LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = 0 
					END IF 
					CALL A41_credit_total_calculation_display() 
					#NEXT FIELD line_flag
				END IF 

				###################

				#LET scrn = scr_line()
				#BEFORE FIELD line_flag
				#   DISPLAY l_arr_rec_invoicedetl[l_idx].*
				#        TO sr_invoicedetl[scrn].*

				#   LET l_scroll_flag = l_arr_rec_invoicedetl[l_idx].line_flag

				#AFTER FIELD line_flag
				#   LET l_arr_rec_invoicedetl[l_idx].line_flag = l_scroll_flag
				#   IF fgl_lastkey() = fgl_keyval("down")
				#   AND arr_curr() = arr_count() THEN
				#      ERROR kandoomsg2("E",9001,"")
				#      NEXT FIELD line_flag
				#   END IF


				#BEFORE FIELD line_num
				#   NEXT FIELD line_flag

				#AFTER ROW
				#   DISPLAY l_arr_rec_invoicedetl[l_idx].*
				#        TO sr_invoicedetl[scrn].*
			ON ACTION "Line Details"
			--ON KEY (F8) #opens invoice line editor 
				CALL lineshow(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cust_code,p_inv_num,"") 
				#NEXT FIELD line_flag

			ON ACTION "Invoice Details"
			--ON KEY (F10) #invoice details ? #huho make this the default FOR BEFORE ROW 
				IF l_arr_rec_invoicedetl[l_idx].line_num > 0 THEN 
					IF l_arr_rec_invoicedetl[l_idx].line_flag IS NULL THEN 
						IF credit_insert_invoice_line(p_inv_num,l_arr_rec_invoicedetl[l_idx].line_num) THEN 
							LET l_arr_rec_invoicedetl[l_idx].line_flag = "*" 
							LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = l_arr_rec_invoicedetl[l_idx].line_total_amt 
						END IF 
					ELSE 
					
						SELECT part_code, ware_code 
						INTO l_part_code, l_ware_code FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num
						 
						CALL serial_delete(l_part_code, l_ware_code)

						# DELETE FROM t_creditdetl ------------------
						DELETE FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num
						 
						LET l_arr_rec_invoicedetl[l_idx].line_flag = NULL 
						LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = 0 
					END IF 
					CALL A41_credit_total_calculation_display() 
					#NEXT FIELD line_flag
				END IF 

{			ON ACTION "ACCEPT" 
				IF l_arr_rec_invoicedetl[l_idx].line_num > 0 THEN 
					IF l_arr_rec_invoicedetl[l_idx].line_flag IS NULL THEN 
						IF credit_insert_invoice_line(p_inv_num,l_arr_rec_invoicedetl[l_idx].line_num) THEN 
							LET l_arr_rec_invoicedetl[l_idx].line_flag = "*" 
							LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = 
							l_arr_rec_invoicedetl[l_idx].line_total_amt 
						END IF 
					ELSE 
					
						SELECT part_code, ware_code 
						INTO l_part_code, l_ware_code FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num
						 
						CALL serial_delete(l_part_code, l_ware_code)

						# DELETE FROM t_creditdetl ------------------						 
						DELETE FROM t_creditdetl 
						WHERE invoice_num = p_inv_num 
						AND inv_line_num = l_arr_rec_invoicedetl[l_idx].line_num
						 
						LET l_arr_rec_invoicedetl[l_idx].line_flag = NULL 
						LET l_arr_rec_invoicedetl[l_idx].line_cred_amt = 0 
					END IF 
					CALL A41_credit_total_calculation_display() 
					#NEXT FIELD line_flag
				END IF 
}

		END DISPLAY 

		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 
	END IF 
END FUNCTION 
#################################################################
# END FUNCTION inv_line(p_inv_num,p_mode)
#################################################################


#################################################################
# FUNCTION enter_invoice(p_scrn)
#
#
#################################################################
FUNCTION enter_invoice(p_scrn) 
	DEFINE p_scrn SMALLINT --??? needs changing 
	DEFINE l_inv_num LIKE invoicehead.inv_num 

	MESSAGE kandoomsg2("E",1066,"") #1066" Enter Invoice"

	INPUT l_inv_num FROM sr_invoicehead[p_scrn].inv_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A41a","inp-inv_num") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD inv_num 
			IF l_inv_num IS NULL THEN 
				EXIT INPUT 
			ELSE 
				SELECT unique 1 FROM invoicehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_credithead.cust_code 
				AND inv_num = l_inv_num 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9216,"") 			#9216" Invoice doesn't exist FOR this customer"
					NEXT FIELD sr_invoicehead.inv_num 
				END IF 
			END IF 

			--      ON KEY(F2)
			--         LET l_inv_num = NULL
			--         EXIT INPUT



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_inv_num = NULL 
	END IF 

	RETURN l_inv_num 
END FUNCTION 
#################################################################
# END FUNCTION enter_invoice(p_scrn)
#################################################################


#################################################################
# FUNCTION credit_insert_invoice_line(p_inv_num,p_line_num)
#
# checks invoice TO ensure same warehouse, salesperson & tax rate
# as other creditlines.  IF NOT THEN user IS warned AND prompted TO
# continue.  Each invoice IS only checked once.
#################################################################
FUNCTION credit_insert_invoice_line(p_inv_num,p_line_num) 
	DEFINE p_inv_num LIKE invoicedetl.inv_num 
	DEFINE p_line_num LIKE invoicedetl.line_num 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rowid INTEGER 
	DEFINE l_query_text STRING 

	SELECT unique 1 FROM t_creditdetl 
	WHERE invoice_num = p_inv_num 

	IF status = NOTFOUND THEN 
	
		### Only check invoice first time selected
		#IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,p_inv_num) THEN
		CALL db_invoicehead_get_rec(UI_ON,p_inv_num) RETURNING  l_rec_invoicehead.*
		 
		DECLARE c_warehouse CURSOR FOR 
		SELECT * INTO l_rec_invoicedetl.* FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = p_inv_num 
		AND cust_code = glob_rec_credithead.cust_code 
		AND ware_code IS NOT NULL 
		ORDER BY inv_num,line_num 

		OPEN c_warehouse 
		FETCH c_warehouse 

		CLOSE c_warehouse 

		SELECT unique 1 FROM t_creditdetl 

		LET glob_rec_credheadaddr.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_credheadaddr.ship_text = l_rec_invoicehead.name_text 
		LET glob_rec_credheadaddr.addr1_text = l_rec_invoicehead.addr1_text 
		LET glob_rec_credheadaddr.addr2_text = l_rec_invoicehead.addr2_text 
		LET glob_rec_credheadaddr.city_text = l_rec_invoicehead.city_text 
		LET glob_rec_credheadaddr.state_code = l_rec_invoicehead.state_code 
		LET glob_rec_credheadaddr.post_code = l_rec_invoicehead.post_code 

		IF status = NOTFOUND THEN 
			### IF no lines exist THEN SET VALUES TO what we want
			LET glob_rec_warehouse.ware_code = l_rec_invoicedetl.ware_code 
			LET glob_rec_credithead.sale_code = l_rec_invoicehead.sale_code 
			LET glob_rec_credithead.tax_code = l_rec_invoicehead.tax_code 
			LET glob_rec_credithead.conv_qty = l_rec_invoicehead.conv_qty 
			LET glob_rec_credithead.acct_override_code=l_rec_invoicehead.acct_override_code 

		ELSE 

			IF glob_rec_warehouse.ware_code IS NULL THEN 
				LET glob_rec_warehouse.ware_code = l_rec_invoicedetl.ware_code 
			ELSE 
				IF glob_rec_warehouse.ware_code != l_rec_invoicedetl.ware_code THEN 
					ERROR kandoomsg2("E",7074,"") 				#7074 Warning: Selected invoice has diff warehouse FROM credit"
				END IF 
			END IF 

			IF glob_rec_credithead.sale_code IS NULL THEN 
				LET glob_rec_credithead.sale_code = l_rec_invoicehead.sale_code 
			ELSE 
				IF glob_rec_credithead.sale_code != l_rec_invoicehead.sale_code THEN 
					ERROR kandoomsg2("E",7075,"") 				#7075 Warning: Selected invoice has diff salespers FROM credit"
				END IF 
			END IF 

			IF glob_rec_credithead.tax_code IS NULL THEN 
				LET glob_rec_credithead.tax_code = l_rec_invoicehead.tax_code 
			ELSE 
				IF glob_rec_credithead.tax_code != l_rec_invoicehead.tax_code THEN 
					ERROR kandoomsg2("E",7076,"") 				#7076 Warning: Selected invoice has diff tax code FROM credit"
				END IF 
			END IF 

			IF glob_rec_credithead.conv_qty = 0 THEN 
				LET glob_rec_credithead.conv_qty = l_rec_invoicehead.conv_qty 
			ELSE 
				IF glob_rec_credithead.conv_qty != l_rec_invoicehead.conv_qty THEN 
					ERROR kandoomsg2("E",7077,"") 				#7077 Warning: Selected invoice has conv qty FROM credit"
				END IF 
			END IF 

		END IF 
	END IF 
	# Get invoice details / invoice lines
	LET l_query_text = 
		"SELECT * FROM invoicedetl ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND inv_num = ",trim(p_inv_num)," ", 
		"AND cust_code = '",trim(glob_rec_credithead.cust_code),"' " 

	IF p_line_num IS NOT NULL THEN 
		LET l_query_text = l_query_text clipped," ", "AND line_num = ",trim(p_line_num)," " 
	END IF 

	PREPARE s1_invoicedetl FROM l_query_text 
	DECLARE c1_invoicedetl CURSOR FOR s1_invoicedetl 

	FOREACH c1_invoicedetl INTO l_rec_invoicedetl.* 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_invoicedetl.part_code 
		AND serial_flag = 'Y' 
		IF status = 0 THEN 
			SELECT unique 1 FROM t_creditdetl 
			WHERE part_code = l_rec_invoicedetl.part_code 
			IF status = 0 THEN 
				ERROR kandoomsg2("I",9555,"") 			#9555 Could NOT add Invoice Details as it would add serial
				RETURN false 
			END IF 
		END IF 
	END FOREACH 

	FOREACH c1_invoicedetl INTO l_rec_invoicedetl.*
		CALL creditdetl_insert_row() RETURNING l_rec_creditdetl.* 
		LET l_rowid = l_rec_creditdetl.line_num
		
		#not sure why we do this... we could simple use the returned record 
		SELECT * INTO l_rec_creditdetl.* #get credit note row-data 
		FROM t_creditdetl 
		WHERE rowid = l_rowid 
		
		IF sqlca.sqlcode < 0 THEN
			CALL fgl_winmessage("Internal 4GL Error","Could not retrieve credit line row data! #9347839", "ERROR")
		END IF

		LET l_rec_creditdetl.part_code = l_rec_invoicedetl.part_code 
		LET l_rec_creditdetl.ship_qty = l_rec_invoicedetl.ship_qty 
		LET l_rec_creditdetl.line_text = l_rec_invoicedetl.line_text 

		IF l_rec_invoicedetl.bonus_qty > 0 THEN 
			#---------------------------------------------
			# WHEN crediting bonus qty's average out price
			LET l_rec_creditdetl.unit_sales_amt = l_rec_invoicedetl.ext_sale_amt / ( l_rec_invoicedetl.sold_qty+ l_rec_invoicedetl.bonus_qty) 

			LET l_rec_creditdetl.unit_tax_amt = l_rec_invoicedetl.ext_tax_amt	/ ( l_rec_invoicedetl.sold_qty	+ l_rec_invoicedetl.bonus_qty) 
		ELSE 
			LET l_rec_creditdetl.unit_sales_amt = l_rec_invoicedetl.unit_sale_amt 
			LET l_rec_creditdetl.unit_tax_amt = l_rec_invoicedetl.unit_tax_amt 
			LET l_rec_creditdetl.unit_cost_amt = l_rec_invoicedetl.unit_cost_amt 
		END IF 

		LET l_rec_creditdetl.line_acct_code = l_rec_invoicedetl.line_acct_code 
		LET l_rec_creditdetl.tax_code = l_rec_invoicedetl.tax_code 
		LET l_rec_creditdetl.level_code = l_rec_invoicedetl.level_code 
		LET l_rec_creditdetl.received_qty = l_rec_invoicedetl.ship_qty 
		LET l_rec_creditdetl.comm_amt = l_rec_invoicedetl.comm_amt 
		LET l_rec_creditdetl.list_amt = l_rec_invoicedetl.list_price_amt 
		LET l_rec_creditdetl.invoice_num = l_rec_invoicedetl.inv_num 
		LET l_rec_creditdetl.inv_line_num = l_rec_invoicedetl.line_num 
		
		CALL A41_creditdetl_update_line(l_rowid,l_rec_creditdetl.*) RETURNING l_rec_creditdetl.* 
	END FOREACH 

	CALL db_show_creditdetl_arr_rec() #huho-debug

	RETURN true 
END FUNCTION 
#################################################################
# END FUNCTION credit_insert_invoice_line(p_inv_num,p_line_num)
#################################################################