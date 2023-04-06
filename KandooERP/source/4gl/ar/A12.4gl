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
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A12_GLOBALS.4gl" 

###########################################################################
# FUNCTION A12_main()
#
# Purpose  Allows the user TO view Customer Information including credit
#          information a single Customer AT a time
###########################################################################
FUNCTION A12_main() 

	CALL setModuleId("A12") 

	CALL A12_customer_menu() 
END FUNCTION 
###########################################################################
# END FUNCTION A12_main()
###########################################################################


#######################################################################
# FUNCTION A12_customer_datasource_cursor()
#
#
#######################################################################
FUNCTION A12_customer_datasource_cursor(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_cust_code LIKE customer.cust_code 
	DEFINE l_where_text STRING 
	DEFINE l_where2_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_query_count_text STRING	
	DEFINE l_fldbuf_country_code LIKE customer.country_code # 1. DEFINE variable FOR country code 
	DEFINE l_count SMALLINT 

	WHENEVER ERROR CONTINUE
		#Close any open cursor
		CLOSE c_count_customer
		CLOSE c_customer
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	IF p_filter THEN

		CLEAR FORM 
	
		LET l_where2_text = NULL 
		MESSAGE kandoomsg2("A",1078,"") 

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
				CALL publish_toolbar("kandoo","A12","construct-customer") 
				--CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_SPACE)
				CALL db_country_localize(glob_rec_customer.country_code) #Localize				 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "HIDE_DELETED"  #Feature Request Anna
				IF get_default_hideDeletedCustomers() = TRUE THEN 
					CALL set_default_hideDeletedCustomers(FALSE)
				ELSE
					CALL set_default_hideDeletedCustomers(TRUE)
				END IF
	
			ON KEY (F8) --extend criteria 
				IF get_kandoooption_feature_state("AR","CP") = 0 THEN 
					LET l_where2_text = "1=1" 
					ERROR kandoomsg2("A",9304,"") 	#9304 Customer Reporting Codes NOT available - Refer menu US1
				ELSE 
					LET l_where2_text = report_criteria(glob_rec_kandoouser.cmpy_code,"AR") 
					IF l_where2_text IS NULL THEN 
						CONTINUE CONSTRUCT 
					ELSE 
						EXIT CONSTRUCT 
					END IF 
				END IF 
	
			AFTER FIELD country_code #2. AFTER country_code field, read buffer AND populate corresponding state combo 
				LET l_fldbuf_country_code = get_fldbuf("country_code")
				CALL db_country_localize(l_fldbuf_country_code) #Localize	 
				--CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_fldbuf_country_code,COMBO_NULL_SPACE) 
	
				#Note: ON CHANGE is not supported in CONSTRUCT			... needs to be done using AFTER CONSTRUCT
				#ON CHANGE country_code
				#DISPLAY "hello"
				#		LET l_fldbuf_country_code = get_fldbuf("country_code")
				#		CALL comboList_state("state_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,l_fldbuf_country_code,COMBO_NULL_SPACE)
	
			AFTER CONSTRUCT 
				IF not(int_flag OR quit_flag) THEN 
					IF get_kandoooption_feature_state("AR","CP") = 2 AND l_where2_text IS NULL THEN 
						LET l_where2_text = report_criteria(glob_rec_kandoouser.cmpy_code,"AR") 
						IF l_where2_text IS NULL THEN 
							CONTINUE CONSTRUCT 
						END IF 
					END IF 
					IF l_where2_text IS NULL THEN 
						LET l_where2_text = " 1=1 " 
					END IF 
				END IF 
	
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where2_text = " 1=1 " 
		END IF 

	ELSE
		LET l_where2_text = " 1=1 " 
	END IF

	LET l_query_text = 
		"SELECT cust_code, name_text ", 
		"FROM customer ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
		--"AND ",l_where_text clipped," ", 
		--"AND ",l_where2_text clipped
	
	IF l_where_text IS NOT NULL THEN
		LET l_query_text = trim(l_query_text), " AND ",l_where_text clipped," "
	END IF

	IF l_where2_text IS NOT NULL THEN
		LET l_query_text = trim(l_query_text), " AND ",l_where2_text clipped," "
	END IF	 
	
	
	 
	#   Note the two selects below SELECT the name text FOR the purposes of the
	#   ORDER BY clause.  The data IS NOT returned TO a variable.

	#Hide deleted customers based on user settings
	IF get_default_hideDeletedCustomers() THEN #TRUE Hide deleted customers
		LET l_query_text = trim(l_query_text), " AND delete_flag != 'Y' "
	END IF

	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_text = l_query_text clipped," ORDER BY cust_code" 
	ELSE 
		LET l_query_text = l_query_text clipped," ORDER BY name_text,cust_code" 
	END IF 

	#result counter
	LET l_query_count_text = 
		"SELECT COUNT(*) ", 
		"FROM customer ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" "

	IF l_where_text IS NOT NULL THEN
		LET l_query_count_text = trim(l_query_count_text), " AND ",l_where_text clipped," "
	END IF

	IF l_where2_text IS NOT NULL THEN
		LET l_query_count_text = trim(l_query_count_text), " AND ",l_where2_text clipped," "
	END IF	 

	MESSAGE kandoomsg2("I",1002,"") 	#1002 " Searching database - please wait"

	#DISPLAY l_query_text clipped
	#sleep 20

	PREPARE s_count_customer FROM l_query_count_text 
	DECLARE c_count_customer SCROLL CURSOR FOR s_count_customer 
	OPEN c_count_customer #<<< <anton dickinson> ecpg -605 
	FETCH c_count_customer INTO l_count 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer SCROLL CURSOR FOR s_customer 
	OPEN c_customer #<<< <anton dickinson> ecpg -605 
	FETCH c_customer INTO l_cust_code 

	IF status = NOTFOUND THEN 
		RETURN 0 
	ELSE 
		CALL display_customer(l_cust_code) 
	END IF 
	
	RETURN l_count
END FUNCTION 
#######################################################################
# END FUNCTION A12_customer_datasource_cursor()
#######################################################################


#######################################################################
# FUNCTION A12_customer_menu() - Starting point
#
#
#######################################################################
FUNCTION A12_customer_menu() 
	DEFINE l_rec_cust_code LIKE customer.cust_code 
	DEFINE l_count SMALLINT
	
	OPEN WINDOW A112 with FORM "A112" 
	CALL windecoration_a("A112") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 


	MENU " Customer" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A12","menu-customer") 
#			HIDE option "Next" 
#			HIDE option "Previous" 
#			HIDE option "First" 
#			HIDE option "Last" 
#			HIDE option "Detail" 
---------
			LET l_count = A12_customer_datasource_cursor(TRUE)
			CASE 
				WHEN l_count < 1
					MESSAGE kandoomsg2("A",9044,"") 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Last" 
					HIDE option "Detail" 
			
				
				WHEN l_count = 1
					FETCH FIRST c_customer INTO l_rec_cust_code
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Last" 
					HIDE option "Detail" 

					SHOW option "Detail" 
									
				WHEN l_count > 1
					FETCH FIRST c_customer INTO l_rec_cust_code
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "First" 
					SHOW option "Last" 
					SHOW option "Detail" 
				
			END CASE

--------
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Query" " Enter selection criteria FOR customers " 
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))
			LET l_count = A12_customer_datasource_cursor(TRUE)
			CASE 
				WHEN l_count < 1
					MESSAGE kandoomsg2("A",9044,"") 
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Last" 
					HIDE option "Detail" 
			
				
				WHEN l_count = 1
					FETCH FIRST c_customer INTO l_rec_cust_code
					HIDE option "Next" 
					HIDE option "Previous" 
					HIDE option "First" 
					HIDE option "Last" 
					HIDE option "Detail" 

					SHOW option "Detail" 
									
				WHEN l_count > 1
					FETCH FIRST c_customer INTO l_rec_cust_code
					SHOW option "Next" 
					SHOW option "Previous" 
					SHOW option "First" 
					SHOW option "Last" 
					SHOW option "Detail" 
				
			END CASE
			
	{		 
			IF A12_customer_datasource_cursor() THEN 
				FETCH FIRST c_customer INTO l_rec_cust_code
				I 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				MESSAGE kandoomsg2("A",9044,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
}
		ON ACTION "Detail" --customer details			#      COMMAND "Detail" " View customer details"
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))
			IF l_rec_cust_code IS NOT NULL THEN --if now RECORD IS filtered/displayed... no details can be shown/selected 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,l_rec_cust_code)--customer details 
			END IF 

		ON ACTION "First"			#      COMMAND KEY ("F") "First" " DISPLAY first customer in the selected list"  --,f18
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))

			FETCH FIRST c_customer INTO l_rec_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9070,"") 			#9070 You have reached the start of the customers selected"
			ELSE 
				CALL display_customer(l_rec_cust_code) 
			END IF 


		ON ACTION "Previous"		#      COMMAND KEY ("P") "Previous" " DISPLAY previous selected customer"  --,f19
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))

			FETCH previous c_customer INTO l_rec_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9070,"") 				#9070 You have reached the start of the customers selected"
			ELSE 
				CALL display_customer(l_rec_cust_code) 
			END IF 



		ON ACTION "Next" 		#COMMAND KEY ("N") "Next" " DISPLAY next selected customer"  --,f21
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))

			FETCH NEXT c_customer INTO l_rec_cust_code 
			IF status <> NOTFOUND THEN 
				CALL display_customer(l_rec_cust_code) 
			ELSE 
				ERROR kandoomsg2("A",9071,"") 		#9071 You have reached the END of the customers selected"
			END IF 


		ON ACTION "Last" 		#      COMMAND KEY ("L") "Last" " DISPLAY last customer in the selected list"  --,f22
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))

			FETCH LAST c_customer INTO l_rec_cust_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9071,"") 	#9071 You have reached the END of the customers selected"
			ELSE 
				CALL display_customer(l_rec_cust_code) 
			END IF 

		ON ACTION "Exit" 		#      COMMAND KEY(interrupt,"E") "Exit" " RETURN TO the Menu"
			#DISPLAY "LastKey=", trim(fgl_lastkey()), " name=", trim(fgl_keyname(fgl_lastkey()))

			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A112 
END FUNCTION 
#######################################################################
# END FUNCTION A12_customer_menu() - Starting point
#######################################################################


#######################################################################
# FUNCTION display_customer(p_cust_code)
#
#
#######################################################################
FUNCTION display_customer(p_cust_code) 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_inq_sale_text LIKE salesperson.name_text
	DEFINE l_inq_type_text LIKE customertype.type_text
	DEFINE l_inq_reason_text LIKE holdreas.reason_text
	DEFINE l_inq_terr_text LIKE territory.desc_text
	DEFINE l_cred_avail_amt, l_balance_amt LIKE customer.bal_amt
	DEFINE l_p1_overdue,l_p1_baddue LIKE customer.over1_amt
	DEFINE l_style STRING #	like ATTRIBUTE_OK, ATTRIBUTE_WARNING, ATTRIBUTE_ERROR, ATTRIBUTE_GREEN, ATTRIBUTE_YELLOW, ATTRIBUTE_RED
 
	CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.* 
--	SELECT * INTO l_rec_customer.* FROM customer 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND cust_code = p_cust_code 
--	IF status = NOTFOUND THEN 
	IF l_rec_customer.cust_code IS NULL THEN
		ERROR kandoomsg2("A",9067,p_cust_code) 
	END IF 

	LET l_p1_overdue = l_rec_customer.over1_amt 
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
	
	CALL db_country_localize(l_rec_customer.country_code) #Localize	 

	IF l_p1_overdue > 0 THEN 
		LET l_p1_baddue = l_rec_customer.over30_amt 
			+ l_rec_customer.over60_amt 
			+ l_rec_customer.over90_amt 

		IF l_p1_baddue > 0 THEN 
			LET l_style = ATTRIBUTE_OK
		ELSE 
			LET l_style = ATTRIBUTE_WARNING
		END IF

	ELSE
		LET l_style = ATTRIBUTE_ERROR
	END IF
	
			DISPLAY l_rec_customer.cust_code TO cust_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.name_text TO name_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.currency_code TO currency_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.addr1_text TO addr1_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.addr2_text TO addr2_text ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_rec_customer.city_text TO city_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.state_code TO state_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.post_code TO post_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.country_code TO country_code  ATTRIBUTE(STYLE=l_style)
			--DISPLAY l_rec_customer.country_text TO country_text ATTRIBUTE(STYLE=l_style)--@db-patch_2020_10_04--
			DISPLAY l_rec_customer.tele_text TO tele_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.mobile_phone TO mobile_phone ATTRIBUTE(STYLE=l_style)			
			DISPLAY l_rec_customer.email TO email ATTRIBUTE(STYLE=l_style)			
			DISPLAY l_rec_customer.comment_text TO comment_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.curr_amt TO curr_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.over1_amt TO over1_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.over30_amt TO over30_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.over60_amt TO over60_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.over90_amt TO over90_amt ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_rec_customer.bal_amt TO bal_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.vat_code TO vat_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.cond_code TO cond_code ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_rec_customer.hold_code TO hold_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.inv_level_ind TO inv_level_ind ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.avg_cred_day_num TO avg_cred_day_num ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.cred_limit_amt TO cred_limit_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.onorder_amt TO onorder_amt ATTRIBUTE(STYLE=l_style)
			DISPLAY l_cred_avail_amt TO cred_avail_amt ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_rec_customer.type_code TO type_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.sale_code TO sale_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.territory_code TO territory_code ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.setup_date TO setup_date ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.last_inv_date TO last_inv_date ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.last_pay_date TO last_pay_date ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.delete_date TO delete_date ATTRIBUTE(STYLE=l_style)
			DISPLAY l_rec_customer.mobile_phone TO mobile_phone ATTRIBUTE(STYLE=l_style)

			DISPLAY l_inq_reason_text TO holdreas.reason_text ATTRIBUTE(STYLE=l_style) 
			DISPLAY l_inq_type_text TO customertype.type_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_inq_sale_text TO salesperson.name_text ATTRIBUTE(STYLE=l_style)
			DISPLAY l_inq_terr_text TO territory.desc_text ATTRIBUTE(STYLE=l_style)		

END FUNCTION 
#######################################################################
# END FUNCTION display_customer(p_cust_code)
#######################################################################