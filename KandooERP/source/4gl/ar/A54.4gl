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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A5_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A54_GLOBALS.4gl"
####################################################################
# MAIN
#
#  Allows the user TO SELECT customers that need TO be put on hold.
#  FOR each customer in the SET IS asked FOR which reason the
#  customer IS put on hold
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("A54") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL query() 

END MAIN 
####################################################################
# END MAIN
####################################################################


####################################################################
# FUNCTION db_customer_get_datasource_cursor()
#
#
####################################################################
FUNCTION db_customer_get_datasource_cursor() 
	DEFINE l_cust_code LIKE customer.cust_code
--	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_where_text CHAR(800)
	DEFINE l_query_text CHAR(900) 
	DEFINE l_query_count_text STRING
	DEFINE l_query_data_text STRING
	DEFINE l_count SMALLINT

--	#get Account Receivable Parameters Record
--	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.* 
		
	CLEAR FORM 

	MESSAGE kandoomsg2("A",1001,"")	# 1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON 
		cust_code, 
		name_text, 
		currency_code, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		country_code, 
		tele_text, 
		mobile_phone,
		email, 
		comment_text, 
		curr_amt, 
		over1_amt, 
		over30_amt, 
		over60_amt, 
		over90_amt, 
		bal_amt, 
		vat_code, 
		inv_level_ind, 
		cond_code, 
		avg_cred_day_num, 
		hold_code, 
		type_code, 
		sale_code, 
		territory_code, 
		cred_limit_amt, 
		onorder_amt, 
		last_inv_date, 
		last_pay_date, 
		setup_date, 
		delete_date 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A54","construct-customer") 

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
	IF glob_rec_arparms.report_ord_flag = "C" THEN
		LET l_query_text = 
			"FROM customer ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ",l_where_text clipped," ", 
			"AND delete_flag = 'N' " 

		
		LET l_query_data_text = "SELECT cust_code " , l_query_text CLIPPED,	" ORDER BY cust_code"
		LET l_query_count_text = "SELECT count(*) " , l_query_text CLIPPED
				 
	ELSE 
		LET l_query_text =  
			"FROM customer ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ",l_where_text clipped," ", 
			"AND delete_flag = 'N' " 
		 
		
		LET l_query_data_text = "SELECT cust_code,name_text " , l_query_text CLIPPED , " ORDER BY customer.name_text"
		LET l_query_count_text = "SELECT count(*) " , l_query_text CLIPPED
	END IF 

	#Count
	PREPARE s_count_customer FROM l_query_count_text 
	DECLARE c_count_customer SCROLL CURSOR with HOLD FOR s_count_customer 
	OPEN c_count_customer 
	FETCH c_count_customer INTO l_count 

	#Data
	PREPARE s_customer FROM l_query_data_text 
	DECLARE c_customer SCROLL CURSOR with HOLD FOR s_customer 
	OPEN c_customer 
	FETCH c_customer INTO l_cust_code 
	
	IF status = NOTFOUND THEN 
--		RETURN false 
	ELSE 
		CALL display_customer(l_cust_code) 
--		RETURN true 
	END IF 

	RETURN l_count	
END FUNCTION 
####################################################################
# END FUNCTION db_customer_get_datasource_cursor()
####################################################################


####################################################################
# FUNCTION show_navigation_options(p_count)
#
# Hide/Show navigation buttons depending on record count
####################################################################
FUNCTION show_navigation_options(p_count)
	DEFINE p_count SMALLINT

			CASE 
				WHEN p_count = 0
					HIDE option "First" 
					HIDE option "Previous" 
					HIDE option "Next" 
					HIDE option "Last" 

					HIDE option "Hold" 
					--NEXT option "Hold"

				ERROR kandoomsg2("A",9044,"") 				#9044 No Customer Satisfied Selection Criteria

				WHEN p_count = 1
					HIDE option "First" 
					HIDE option "Previous" 
					HIDE option "Next" 
					HIDE option "Last" 

					SHOW option "Hold" 
					NEXT option "Hold" 

				WHEN p_count = 2
					HIDE option "First" 
					SHOW option "Previous" 
					SHOW option "Next" 
					HIDE option "Last" 

					SHOW option "Hold" 
					NEXT option "Hold" 

				WHEN p_count >= 3
					SHOW option "First" 
					SHOW option "Previous" 
					SHOW option "Next" 
					SHOW option "Last" 

					SHOW option "Hold" 
					NEXT option "Hold" 

			END CASE				  


END FUNCTION


####################################################################
# FUNCTION query()
#
#
####################################################################
FUNCTION query() 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_count SMALLINT
	
	OPEN WINDOW A112 with FORM "A112" 
	CALL windecoration_a("A112") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET l_count = db_customer_get_datasource_cursor() #query and get the size

	MENU " Customer" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A54","menu-customer") 
			CALL show_navigation_options(l_count)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " Enter selection criteria FOR customers "
			LET l_count = db_customer_get_datasource_cursor()
			CALL show_navigation_options(l_count)
			FETCH FIRST c_customer INTO l_cust_code					

		ON ACTION "Next" 
			# COMMAND KEY ("N",f21) "Next" " DISPLAY next selected customer"
			FETCH NEXT c_customer INTO l_cust_code 
			IF status <> NOTFOUND THEN 
				CALL display_customer(l_cust_code) 
			ELSE 
				ERROR kandoomsg2("A",9071,"") 				#9071 You have reached the END of the customers selected"
			END IF 
			NEXT option "Hold" 

		ON ACTION "Previous" 
			# COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected customer"
			FETCH previous c_customer INTO l_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9070,"") 				#9070 You have reached the start of the customers selected"
			ELSE 
				CALL display_customer(l_cust_code) 
			END IF 

		ON ACTION "Hold" 
			#  COMMAND "Hold" " Put customer on hold"
			CALL hold_cust(l_cust_code) 
			NEXT option "Next" 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " DISPLAY first customer in the selected list"
			FETCH FIRST c_customer INTO l_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9070,"") 				#9070 You have reached the start of the customers selected"
			ELSE 
				CALL display_customer(l_cust_code) 
			END IF 

		ON ACTION "Last" 
			# COMMAND KEY ("L",f22) "Last" " DISPLAY last customer in the selected list"
			FETCH LAST c_customer INTO l_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9071,"") 				#9071 You have reached the END of the customers selected"
			ELSE 
				CALL display_customer(l_cust_code) 
			END IF 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu"
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A112 
	
END FUNCTION 



####################################################################
# FUNCTION display_customer(p_cust_code)
#
#
####################################################################
FUNCTION display_customer(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_inq_sale_text LIKE salesperson.name_text
	DEFINE l_inq_type_text LIKE customertype.type_text
	DEFINE l_inq_reason_text LIKE holdreas.reason_text
	DEFINE l_inq_terr_text LIKE territory.desc_text
	DEFINE l_cred_avail_amt LIKE customer.bal_amt
	DEFINE l_balance_amt LIKE customer.bal_amt
	DEFINE l_style STRING # i.e. ATTTRIBUTE_OK
	DEFINE l_1_overdue LIKE customer.over1_amt 
	DEFINE l_1_baddue LIKE customer.over1_amt 

	CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.*	
--	SELECT * INTO l_rec_customer.* FROM customer 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND cust_code = p_cust_code 

		IF l_rec_customer.cust_code IS NULL THEN			
--		IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust_code) 
	END IF 
	
	LET l_1_overdue = l_rec_customer.over1_amt 
		+ l_rec_customer.over30_amt 
		+ l_rec_customer.over60_amt 
		+ l_rec_customer.over90_amt 
	
	LET l_balance_amt = l_rec_customer.bal_amt 
	LET l_cred_avail_amt = l_rec_customer.cred_limit_amt 
		- l_rec_customer.bal_amt 
		- l_rec_customer.onorder_amt 

	SELECT type_text INTO l_inq_type_text FROM customertype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = l_rec_customer.type_code 
	
	SELECT name_text INTO l_inq_sale_text FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = l_rec_customer.sale_code 
	
	SELECT reason_text INTO l_inq_reason_text FROM holdreas 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = l_rec_customer.hold_code 
	
	SELECT desc_text INTO l_inq_terr_text FROM territory 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND terr_code = l_rec_customer.territory_code 
	
--	IF l_1_overdue > 0 THEN 
--		LET l_1_baddue = l_rec_customer.over30_amt 
--			+ l_rec_customer.over60_amt 
--			+ l_rec_customer.over90_amt 
--
		#--------------------------------
		#Color code depending on credit status
		IF l_1_overdue > 0 THEN --red 
			LET l_1_baddue = l_rec_customer.over30_amt 
				+ l_rec_customer.over60_amt 
				+ l_rec_customer.over90_amt 
	
			IF l_1_baddue > 0 THEN #error/red
				LET l_style = ATTRIBUTE_ERROR
			 
			ELSE #warning
				LET l_style = ATTRIBUTE_WARNING		
			END IF
		ELSE #OK / Green
			LET l_style = ATTRIBUTE_OK
		END IF
		#--------------------------------


--		IF l_1_baddue > 0 THEN 
--
--			LET l_style = ATTRIBUTE_ERROR

			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text, 
				l_rec_customer.currency_code, 
				l_rec_customer.addr1_text, 
				l_rec_customer.addr2_text, 
				l_rec_customer.city_text, 
				l_rec_customer.state_code, 
				l_rec_customer.post_code, 
				l_rec_customer.country_code, 
--@db-patch_2020_10_04--			l_rec_customer.country_text, 
				l_rec_customer.tele_text, 
				l_rec_customer.mobile_phone,
				l_rec_customer.email,						
				l_rec_customer.comment_text, 
				l_rec_customer.curr_amt, 
				l_rec_customer.over1_amt, 
				l_rec_customer.over30_amt, 
				l_rec_customer.over60_amt, 
				l_rec_customer.over90_amt, 
				l_rec_customer.bal_amt, 
				l_rec_customer.vat_code, 
				l_rec_customer.hold_code, 
				l_rec_customer.cond_code, 
				l_rec_customer.inv_level_ind, 
				l_rec_customer.avg_cred_day_num, 
				l_rec_customer.cred_limit_amt, 
				l_rec_customer.onorder_amt, 
				l_rec_customer.type_code, 
				l_rec_customer.sale_code, 
				l_rec_customer.territory_code, 
				l_rec_customer.last_inv_date, 
				l_rec_customer.last_pay_date, 
				l_rec_customer.setup_date, 
				l_rec_customer.delete_date, 
				l_rec_customer.mobile_phone 
				ATTRIBUTE(STYLE=l_style) 

			DISPLAY l_cred_avail_amt TO cred_avail_amt ATTRIBUTE(STYLE=l_style) 
			
			DISPLAY l_inq_reason_text TO holdreas.reason_text ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_inq_type_text TO customertype.type_text ATTRIBUTE(STYLE=l_style)  
			DISPLAY l_inq_sale_text TO salesperson.name_text ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_inq_terr_text TO territory.desc_text ATTRIBUTE(STYLE=l_style) 

{			
		ELSE 
			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text, 
				l_rec_customer.currency_code, 
				l_rec_customer.addr1_text, 
				l_rec_customer.addr2_text, 
				l_rec_customer.city_text, 
				l_rec_customer.state_code, 
				l_rec_customer.post_code, 
				l_rec_customer.country_code, 
--@db-patch_2020_10_04--			l_rec_customer.country_text, 
				l_rec_customer.tele_text, 
				l_rec_customer.mobile_phone,
				l_rec_customer.email,						
				l_rec_customer.comment_text, 
				l_rec_customer.curr_amt, 
				l_rec_customer.over1_amt, 
				l_rec_customer.over30_amt, 
				l_rec_customer.over60_amt, 
				l_rec_customer.over90_amt, 
				l_rec_customer.bal_amt, 
				l_rec_customer.vat_code, 
				l_rec_customer.hold_code, 
				l_rec_customer.cond_code, 
				l_rec_customer.inv_level_ind, 
				l_rec_customer.avg_cred_day_num, 
				l_rec_customer.cred_limit_amt, 
				l_rec_customer.onorder_amt, 
				l_rec_customer.type_code, 
				l_rec_customer.sale_code, 
				l_rec_customer.territory_code, 
				l_rec_customer.last_inv_date, 
				l_rec_customer.last_pay_date, 
				l_rec_customer.setup_date, 
				l_rec_customer.delete_date, 
				l_rec_customer.mobile_phone 
				attribute(yellow) 
			
			DISPLAY l_cred_avail_amt TO cred_avail_amt attribute(yellow)
			  
			DISPLAY l_inq_reason_text TO holdreas.reason_text attribute(yellow) 
			DISPLAY l_inq_type_text TO customertype.type_text attribute(yellow) 
			DISPLAY l_inq_sale_text TO salesperson.name_text attribute(yellow) 
			DISPLAY l_inq_terr_text TO territory.desc_text attribute(yellow) 
			
		END IF 
	ELSE 
		DISPLAY BY NAME l_rec_customer.cust_code, 
		l_rec_customer.name_text, 
		l_rec_customer.currency_code, 
		l_rec_customer.addr1_text, 
		l_rec_customer.addr2_text, 
		l_rec_customer.city_text, 
		l_rec_customer.state_code, 
		l_rec_customer.post_code, 
		l_rec_customer.country_code, 
--@db-patch_2020_10_04--		l_rec_customer.country_text, 
		l_rec_customer.tele_text, 
		l_rec_customer.mobile_phone,
		l_rec_customer.email,				
		l_rec_customer.comment_text, 
		l_rec_customer.curr_amt, 
		l_rec_customer.over1_amt, 
		l_rec_customer.over30_amt, 
		l_rec_customer.over60_amt, 
		l_rec_customer.over90_amt, 
		l_rec_customer.bal_amt, 
		l_rec_customer.vat_code, 
		l_rec_customer.hold_code, 
		l_rec_customer.cond_code, 
		l_rec_customer.inv_level_ind, 
		l_rec_customer.avg_cred_day_num, 
		l_rec_customer.cred_limit_amt, 
		l_rec_customer.onorder_amt, 
		l_rec_customer.type_code, 
		l_rec_customer.sale_code, 
		l_rec_customer.territory_code, 
		l_rec_customer.last_inv_date, 
		l_rec_customer.last_pay_date, 
		l_rec_customer.setup_date, 
		l_rec_customer.delete_date, 
		l_rec_customer.mobile_phone attribute(green) 
		DISPLAY l_cred_avail_amt TO cred_avail_amt attribute(green) 
		
		DISPLAY l_inq_reason_text TO holdreas.reason_text attribute(green)
		DISPLAY l_inq_type_text TO customertype.type_text attribute(green)
		DISPLAY l_inq_sale_text TO salesperson.name_text attribute(green)
		DISPLAY l_inq_terr_text TO territory.desc_text attribute(green)
	END IF
}
END FUNCTION 



####################################################################
# FUNCTION hold_cust(p_cust_code)
#
#
####################################################################
FUNCTION hold_cust(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_holdreas RECORD LIKE holdreas.*
	DEFINE l_prev_hold_code LIKE customer.hold_code
	DEFINE l_temp_text CHAR(10)
	DEFINE l_err_message CHAR(60) 

	CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.*	
--	SELECT * INTO l_rec_customer.* FROM customer 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND cust_code = p_cust_code 

		IF l_rec_customer.cust_code IS NULL THEN			
--		IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9109,"") 		#9109 Customer does NOT exist
		RETURN 
	END IF 

	OPEN WINDOW A217 with FORM "A217" 
	CALL windecoration_a("A217") 

	ERROR kandoomsg2("E",1013,"") 	#1013 Enter Hold Code; OK TO Continue.
	IF l_rec_customer.hold_code IS NOT NULL THEN 
		SELECT * INTO l_rec_holdreas.* FROM holdreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = l_rec_customer.hold_code 
		IF status = NOTFOUND THEN 
			SELECT * INTO l_rec_holdreas.* FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = glob_hold_code 
			IF status = NOTFOUND THEN 
				INITIALIZE l_rec_holdreas.* TO NULL 
			END IF 
		END IF 
	ELSE 
		SELECT * INTO l_rec_holdreas.* FROM holdreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = glob_hold_code 
		IF status = NOTFOUND THEN 
			INITIALIZE l_rec_holdreas.* TO NULL 
		END IF 
	END IF 
	LET l_prev_hold_code = l_rec_customer.hold_code 


	INPUT BY NAME l_rec_holdreas.hold_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A54","inp-holdreas") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_holdreas.hold_code = l_temp_text 
			END IF 
			NEXT FIELD hold_code 

		BEFORE FIELD hold_code 
			SELECT * INTO l_rec_holdreas.* FROM holdreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND hold_code = l_rec_holdreas.hold_code 
			DISPLAY BY NAME l_rec_holdreas.hold_code, 
			l_rec_holdreas.reason_text 

		AFTER FIELD hold_code 
			IF l_rec_holdreas.hold_code IS NOT NULL THEN 
				SELECT reason_text 
				INTO l_rec_holdreas.reason_text 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = l_rec_holdreas.hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9150,"") 					#9150 Hold code NOT found - Try window
					NEXT FIELD hold_code 
				END IF 
			ELSE 
				LET l_rec_holdreas.reason_text = NULL 
			END IF 
			DISPLAY l_rec_holdreas.reason_text  TO reason_text

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW A217 
		RETURN 
	END IF 

	LET glob_hold_code = l_rec_holdreas.hold_code 
	GOTO bypass 
	LABEL recovery: 

	IF error_recover(l_err_message,status) != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		UPDATE customer 
		SET hold_code = l_rec_holdreas.hold_code 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = p_cust_code 
	COMMIT WORK 
	WHENEVER ERROR stop
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CLOSE WINDOW A217 

	LET l_rec_customer.hold_code = l_rec_holdreas.hold_code 
	IF l_prev_hold_code IS NULL THEN 
		IF l_rec_customer.hold_code IS NOT NULL THEN 

			IF kandoomsg("A",8040,"") = "Y" THEN #8040 Confirm TO place all non-held orders on hold
				CALL hold_orders(l_prev_hold_code,l_rec_customer.cust_code) 
			END IF 
		END IF 
	ELSE 
		IF l_rec_customer.hold_code IS NULL THEN 
			IF kandoomsg("A",8041,"")  = "Y" THEN #8041 Confirm TO release all orders FROM hold
				CALL hold_orders(l_prev_hold_code,l_rec_customer.cust_code) 
			END IF 
		END IF 
	END IF 

	DISPLAY l_rec_customer.hold_code TO hold_code 
	DISPLAY l_rec_holdreas.reason_text TO reason_text 

END FUNCTION 



####################################################################
# FUNCTION hold_orders(p_prev_hold_code,p_cust_code)
#
#
####################################################################
FUNCTION hold_orders(p_prev_hold_code,p_cust_code) 
	DEFINE p_prev_hold_code LIKE customer.hold_code
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_rec_orderhead2 RECORD LIKE orderhead.*
	DEFINE l_err_message CHAR(60) 

	MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please Wait..
	CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.*	
--	SELECT * INTO l_rec_customer.* FROM customer 
--	WHERE cust_code = p_cust_code 
--	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN 
	END IF 
	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 

	IF p_prev_hold_code IS NULL THEN 
		#Place Orders On Hold
		DECLARE c_holdorder CURSOR with HOLD FOR 
		SELECT * FROM orderhead 
		WHERE cust_code = l_rec_customer.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code IS NULL 
		AND status_ind in ("U","P","X") 

		FOREACH c_holdorder INTO l_rec_orderhead.* 

			BEGIN WORK 

				INITIALIZE l_rec_orderhead2.* TO NULL 
				LET l_err_message = "A11a - Getting Orderhead FOR Update" 
				DECLARE c2_holdorder CURSOR FOR 
				SELECT * FROM orderhead 
				WHERE order_num = l_rec_orderhead.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c2_holdorder 
				FETCH c2_holdorder INTO l_rec_orderhead2.* 
				IF l_rec_orderhead2.status_ind = "X" THEN 
					ERROR kandoomsg2("A",7095,"") 					#7095 Order being editted; No adjustment made.
					ROLLBACK WORK 
					CONTINUE FOREACH 
				END IF 

				LET l_err_message = "A11a - Updating Hold Code On Orders" 
				UPDATE orderhead 
				SET hold_code = l_rec_customer.hold_code 
				WHERE order_num = l_rec_orderhead2.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			COMMIT WORK 
		END FOREACH 

	ELSE 

		#Remove Customer Hold Code FROM Order
		DECLARE c3_holdorder CURSOR with HOLD FOR 
		SELECT * FROM orderhead 
		WHERE cust_code = l_rec_customer.cust_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = p_prev_hold_code 
		AND status_ind in ("U","P","X") 

		FOREACH c3_holdorder INTO l_rec_orderhead.* 
			BEGIN WORK 
				INITIALIZE l_rec_orderhead2.* TO NULL 
				LET l_err_message = "A11a - Getting Orderhead FOR Update2" 
				DECLARE c4_holdorder CURSOR FOR 
				SELECT * FROM orderhead 
				WHERE order_num = l_rec_orderhead.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c4_holdorder 
				FETCH c4_holdorder INTO l_rec_orderhead2.* 
				IF l_rec_orderhead2.status_ind = "X" THEN 
					ERROR kandoomsg2("A",7095,"") 				#7095 Order being editted; No adjustment made.

					ROLLBACK WORK 
					CONTINUE FOREACH 

				END IF 
				LET l_err_message = "A11a - Updating Hold Code On Orders2" 
				UPDATE orderhead 
				SET hold_code = NULL 
				WHERE order_num = l_rec_orderhead2.order_num 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			COMMIT WORK 

		END FOREACH 

	END IF 

END FUNCTION 


