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

# \brief module A46 allows the user TO Scan Credit Memos

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A46_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_cnt SMALLINT
	DEFINE i SMALLINT
--	DEFINE l_cust_code LIKE customer.cust_code
	
	#Initial UI Init
	CALL setModuleId("A46") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	
	LET glob_ref_text = glob_temp_text #??? 
	
	INITIALIZE glob_rec_customer.* TO NULL 
	--INITIALIZE glob_org_customer.* TO NULL 

	IF l_cnt > 0 THEN 
		LET i = 1 
		FOR i = i TO l_cnt 
			INITIALIZE glob_arr_rec_nametext[i].* TO NULL 
		END FOR 
	END IF 

	IF (get_url_credit_number() IS NOT null) AND (get_url_company_code() IS NOT null) THEN 
		LET glob_v_corp_cust = false 
		CALL disp_credit(get_url_company_code(),get_url_credit_number()) #function disp_credit(p_cmpy_code,p_cred_num) 
	ELSE 
		OPEN WINDOW A122 with FORM "A122" 
		CALL windecoration_a("A122") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	--CALL select_cust() RETURNING l_cust_code
	CALL scan_credits(NULL)
--		WHILE select_cust() 
--			CALL scan_credits(NULL) 
--		END WHILE 
		CLOSE WINDOW A122 
	END IF 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION select_cust()
#
#
############################################################
FUNCTION select_cust() 

	CLEAR FORM 
	DISPLAY glob_rec_arparms.credit_ref2a_text TO credit_ref2a_text 
	DISPLAY glob_rec_arparms.credit_ref2b_text TO credit_ref2b_text
	MESSAGE kandoomsg2("A",1014,"") 	#1014 Enter Customer Code; OK TO Continue.

	OPTIONS INPUT NO WRAP
	INPUT glob_rec_t_credithead.cust_code FROM cust_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A46","inp-cust_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET glob_rec_t_credithead.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			DISPLAY glob_rec_t_credithead.cust_code TO cust_code

			NEXT FIELD cust_code
			 
		ON CHANGE cust_code
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_t_credithead.cust_code) TO customer.name_text
			DISPLAY db_customer_get_name_text(UI_OFF,glob_rec_t_credithead.org_cust_code) TO credithead.org_name_text
			DISPLAY db_customer_get_currency_code(UI_OFF,glob_rec_t_credithead.cust_code) TO customer.currency_code
			
		AFTER FIELD cust_code 
			IF glob_rec_t_credithead.cust_code IS NOT NULL THEN

			CALL db_customer_get_rec(UI_OFF,glob_rec_t_credithead.cust_code) RETURNING glob_rec_customer.* 
--				SELECT * INTO glob_rec_customer.* FROM customer 
--				WHERE cust_code = glob_rec_t_credithead.cust_code 
--				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF glob_rec_customer.cust_code IS NULL THEN
						ERROR kandoomsg2("U",9105,"")	#9105 RECORD NOT found; Try Window.
					NEXT FIELD cust_code 
				END IF 
			END IF 

			IF glob_rec_customer.corp_cust_code IS NOT NULL	AND glob_rec_customer.corp_cust_ind = "1" THEN 
				LET glob_v_corp_cust = true 
				SELECT * INTO glob_rec_corp_cust.* FROM customer 
				WHERE cust_code = glob_rec_customer.corp_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9121,"") 				#9121 "Originating customer code NOT found, setup using A15"
					NEXT FIELD cust_code 
				END IF 
			ELSE 
				LET glob_v_corp_cust = false 
			END IF 
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF glob_rec_t_credithead.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
				NEXT FIELD cust_code 
			END IF 

	END INPUT 
	OPTIONS INPUT WRAP
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE 
		RETURN glob_rec_t_credithead.cust_code 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION select_cust()
############################################################


############################################################
# FUNCTION db_credithead_get_datasource(p_filter,p_cust_code)
#
#
############################################################
FUNCTION db_credithead_get_datasource(p_filter,p_cust_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cust_code LIKE customer.cust_code

	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF RECORD --array[320] OF RECORD 
		cred_num LIKE credithead.cred_num, 
		cred_text LIKE credithead.cred_text, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 

	IF p_filter THEN #filter active
		CLEAR FORM 

		#------------------------- DISPLAY ? not sure if this should be here - moved it to  main customer manager		
		DISPLAY glob_rec_arparms.credit_ref2a_text TO credit_ref2a_text 
		DISPLAY glob_rec_arparms.credit_ref2b_text TO credit_ref2b_text
		# Swap the Customer codes around TO DISPLAY TO the SCREEN
		IF glob_v_corp_cust THEN 
			DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 

			DISPLAY glob_rec_t_credithead.cust_code TO credithead.org_cust_code 

			DISPLAY glob_rec_customer.corp_cust_code TO credithead.cust_code 

			DISPLAY glob_rec_corp_cust.name_text TO customer.name_text 

		ELSE 
			DISPLAY glob_rec_t_credithead.cust_code TO cust_code
			DISPLAY glob_rec_customer.name_text TO name_text

		END IF 
		IF glob_v_corp_cust THEN 
			DISPLAY glob_rec_customer.cust_code TO credithead.org_cust_code 
		END IF 
		DISPLAY glob_rec_customer.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
		#------------------------- DISPLAY ? not sure if this should be here - moved it to  main customer manager
 
		MESSAGE kandoomsg2("A",1001,"")	#1001 Enter Selection Criteria - ESC TO Continue
		IF glob_v_corp_cust THEN 
			LET glob_rec_t_credithead.cust_code = glob_rec_corp_cust.cust_code 
		END IF 

		CONSTRUCT BY NAME l_where_text ON 
			cred_num, 
			cred_text, 
			cred_date, 
			year_num, 
			period_num, 
			total_amt, 
			appl_amt, 
			posted_flag 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A46","construct-credithead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 
		
	MESSAGE kandoomsg2("A",1002,"") #1002 Searching database - please wait
	LET l_query_text = 
		"SELECT * ", 
		"FROM credithead ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
		"AND cust_code = \"", 
		glob_rec_t_credithead.cust_code CLIPPED,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"cred_num" 
	
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit CURSOR FOR s_credit 
	
	LET l_idx = 0 
	FOREACH c_credit INTO l_rec_credithead.* 
		IF glob_v_corp_cust THEN 
			IF l_rec_credithead.org_cust_code IS NULL OR l_rec_credithead.org_cust_code != glob_rec_customer.cust_code THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 

		LET l_idx = l_idx + 1 
		LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
		LET l_arr_rec_credithead[l_idx].cred_text = l_rec_credithead.cred_text 
		LET l_arr_rec_credithead[l_idx].cred_date = l_rec_credithead.cred_date 
		LET l_arr_rec_credithead[l_idx].year_num = l_rec_credithead.year_num 
		LET l_arr_rec_credithead[l_idx].period_num = l_rec_credithead.period_num 
		LET l_arr_rec_credithead[l_idx].total_amt = l_rec_credithead.total_amt 
		LET l_arr_rec_credithead[l_idx].appl_amt = l_rec_credithead.appl_amt 
		LET l_arr_rec_credithead[l_idx].posted_flag = l_rec_credithead.posted_flag

		 
--			IF l_idx = 300 THEN 
--				ERROR kandoomsg2("U",6100,l_idx) 
--				#6100 "First l_idx records selected "
--				EXIT FOREACH 
--			END IF 

		# DISPLAY originating customer code AND name TO SCREEN
		SELECT customer.name_text 
		INTO glob_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_credithead.org_cust_code 

		IF NOT status THEN 
			LET glob_arr_rec_nametext[l_idx].name_text = glob_name_text 
			LET glob_arr_rec_nametext[l_idx].cust_code = l_rec_credithead.org_cust_code 
		ELSE 
			LET glob_arr_rec_nametext[l_idx].name_text = NULL 
			LET glob_arr_rec_nametext[l_idx].cust_code = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH
	 
	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
	
	RETURN l_arr_rec_credithead
END FUNCTION
############################################################
# END FUNCTION db_credithead_get_datasource(p_filter,p_cust_code)
############################################################


############################################################
# FUNCTION scan_credits()
#
#
############################################################
FUNCTION scan_credits(p_cust_code)
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_arr_rec_credithead DYNAMIC ARRAY OF RECORD --array[320] OF RECORD 
		cred_num LIKE credithead.cred_num, 
		cred_text LIKE credithead.cred_text, 
		cred_date LIKE credithead.cred_date, 
		year_num LIKE credithead.year_num, 
		period_num LIKE credithead.period_num, 
		total_amt LIKE credithead.total_amt, 
		appl_amt LIKE credithead.appl_amt, 
		posted_flag LIKE credithead.posted_flag 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_where_text CHAR(200)
	DEFINE l_query_text CHAR(500) 

--	WHILE true
		IF p_cust_code IS NULL THEN	#choose customer cust_code
			CALL select_cust() RETURNING p_cust_code
		END IF	
		CALL db_credithead_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_credithead	--get ALL (true) data for this customer
	 
--		IF l_idx = 0 THEN 
--			CONTINUE WHILE 
--		END IF 
--
--		CALL set_count(l_idx) 

		MESSAGE kandoomsg2("I",1300,"") 	#1300 "ENTER on line TO View Details"
		#INPUT ARRAY l_arr_rec_credithead WITHOUT DEFAULTS FROM sr_credithead.* ATTRIBUTE(UNBUFFERED) 
		DISPLAY ARRAY l_arr_rec_credithead TO sr_credithead.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY
				CALL publish_toolbar("kandoo","A46","inp-arr-credithead") 

				#------------------------- DISPLAY ? moved it from data_source function to here		
				DISPLAY glob_rec_arparms.credit_ref2a_text TO credit_ref2a_text 
				DISPLAY glob_rec_arparms.credit_ref2b_text TO credit_ref2b_text
				# Swap the Customer codes around TO DISPLAY TO the SCREEN
				IF glob_v_corp_cust THEN 
					DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 
		
					DISPLAY glob_rec_t_credithead.cust_code TO credithead.org_cust_code 
		
					DISPLAY glob_rec_customer.corp_cust_code TO credithead.cust_code 
		
					DISPLAY glob_rec_corp_cust.name_text TO customer.name_text 
		
				ELSE 
					DISPLAY glob_rec_t_credithead.cust_code TO cust_code
					DISPLAY glob_rec_customer.name_text TO name_text
		
				END IF 
				IF glob_v_corp_cust THEN 
					DISPLAY glob_rec_customer.cust_code TO credithead.org_cust_code 
				END IF 
				DISPLAY glob_rec_customer.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
				
				
				
				#------------------------- DISPLAY ? moved it from data_source function to here
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "CUSTOMER"
				CALL select_cust() RETURNING p_cust_code
				CALL l_arr_rec_credithead.clear()
				CALL db_credithead_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_credithead	--get ALL (true) data for this customer

			ON ACTION "FILTER"
				CALL l_arr_rec_credithead.clear()
				CALL db_credithead_get_datasource(TRUE,p_cust_code) RETURNING l_arr_rec_credithead	--get ALL (true) data for this customer
				DISPLAY glob_rec_arparms.credit_ref2a_text TO credit_ref2a_text 
				DISPLAY glob_rec_arparms.credit_ref2b_text TO credit_ref2b_text

			ON ACTION "REFRESH"
				CALL windecoration_a("A122")
				CALL l_arr_rec_credithead.clear()
				CALL select_cust() RETURNING p_cust_code
				CALL db_credithead_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_credithead	--get ALL (true) data for this customer
			

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				LET l_rec_credithead.cred_num = l_arr_rec_credithead[l_idx].cred_num 
				DISPLAY glob_arr_rec_nametext[l_idx].name_text TO formonly.org_name_text 
				DISPLAY glob_arr_rec_nametext[l_idx].cust_code TO credithead.org_cust_code 


			ON ACTION ("DOUBLECLICK","ACCEPT")
				LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
				#DISPLAY l_arr_rec_credithead[l_idx].* TO sr_credithead[scrn].*

				IF l_rec_credithead.cred_num > 0 THEN 
					CALL disp_credit(glob_rec_kandoouser.cmpy_code,l_rec_credithead.cred_num) 
				END IF 
 




--			AFTER FIELD cred_num 
--				IF fgl_lastkey() = fgl_keyval("down") 
--				AND arr_curr() >= arr_count() THEN 
--					ERROR kandoomsg2("U",9001,"")  --					#9001 There no more rows...
--					NEXT FIELD cred_num 
--				END IF 
--				IF fgl_lastkey() = fgl_keyval("down") THEN 
--					IF l_arr_rec_credithead[l_idx+1].cred_num IS NULL THEN 
--						ERROR kandoomsg2("U",9001,"") --						#9001 There no more rows...
--						NEXT FIELD cred_num 
--					END IF 
--				END IF 
--				IF fgl_lastkey() = fgl_keyval("nextpage") 
--				AND (l_arr_rec_credithead[l_idx+10].cred_num IS NULL 
--				OR l_arr_rec_credithead[l_idx+10].cred_num = 0) THEN 
--					ERROR kandoomsg2("U",9001,"") --					#9001 No more rows in this direction
--					NEXT FIELD cred_num 
--				END IF 
--
--				LET l_arr_rec_credithead[l_idx].cred_num = l_rec_credithead.cred_num 
--				--DISPLAY l_arr_rec_credithead[l_idx].* TO sr_credithead[scrn].*

--			BEFORE FIELD cred_text 
--				IF l_rec_credithead.cred_num > 0 THEN 
--					CALL disp_credit(glob_rec_kandoouser.cmpy_code,l_rec_credithead.cred_num) 
--				END IF 
--				NEXT FIELD cred_num 

		END DISPLAY

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false
			RETURN FALSE 
		ELSE 
			RETURN TRUE
		END IF 

END FUNCTION 
############################################################
# END FUNCTION scan_credits()
############################################################


############################################################
# FUNCTION disp_credit(p_cmpy_code,p_cred_num)
#
#
############################################################
FUNCTION disp_credit(p_cmpy_code,p_cred_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_func_type CHAR(14) 

	OPEN WINDOW A121 with FORM "A121" 
	CALL windecoration_a("A121") 

	DISPLAY glob_ref_text TO credit_ref1_text
	 
	SELECT credithead.* INTO l_rec_credithead.* FROM credithead 
	WHERE cmpy_code = p_cmpy_code 
	AND cred_num = p_cred_num

	CALL db_salesperson_get_name_text(UI_OFF,l_rec_credithead.sale_code) RETURNING l_rec_salesperson.name_text
	
	DISPLAY l_rec_credithead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

	DISPLAY l_rec_credithead.cust_code TO cust_code
	DISPLAY l_rec_credithead.org_cust_code TO org_cust_code
	DISPLAY l_rec_credithead.cred_num TO cred_num
	DISPLAY l_rec_credithead.currency_code TO currency_code
	DISPLAY l_rec_credithead.goods_amt TO goods_amt
	DISPLAY l_rec_credithead.hand_amt TO hand_amt
	DISPLAY l_rec_credithead.freight_amt TO freight_amt
	DISPLAY l_rec_credithead.tax_amt TO tax_amt
	DISPLAY l_rec_credithead.total_amt TO total_amt
	DISPLAY l_rec_credithead.appl_amt TO appl_amt
	DISPLAY l_rec_credithead.disc_amt TO disc_amt
	DISPLAY l_rec_credithead.cred_text TO cred_text
	DISPLAY l_rec_credithead.cred_date TO cred_date
	DISPLAY l_rec_credithead.on_state_flag TO on_state_flag
	DISPLAY l_rec_credithead.cred_ind TO cred_ind
	DISPLAY l_rec_credithead.year_num TO year_num
	DISPLAY l_rec_credithead.period_num TO period_num
	DISPLAY l_rec_credithead.posted_flag TO posted_flag
	DISPLAY l_rec_credithead.entry_code TO entry_code
	DISPLAY l_rec_credithead.entry_date TO entry_date
	DISPLAY l_rec_credithead.sale_code TO sale_code
	DISPLAY l_rec_credithead.com1_text TO com1_text
	DISPLAY l_rec_credithead.com2_text TO com2_text
	DISPLAY l_rec_credithead.rev_date TO rev_date
	DISPLAY l_rec_credithead.rev_num TO rev_num

	DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

	IF glob_v_corp_cust THEN 
		DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 

		DISPLAY glob_rec_customer.corp_cust_code TO credithead.cust_code 

		DISPLAY glob_rec_corp_cust.name_text TO customer.name_text 

	ELSE 
		IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
			SELECT name_text INTO glob_v_name_text FROM customer 
			WHERE cmpy_code = p_cmpy_code 
			AND cust_code = l_rec_credithead.org_cust_code 
			DISPLAY glob_v_name_text TO formonly.org_name_text 
			DISPLAY glob_rec_customer.name_text  TO name_text

		END IF 
	END IF 
	LET l_func_type = "View Credit" 
	
	MENU " Credit Details" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A46","menu-credit-details") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Line Items" " View Credit line items " 
			CALL linecshow(p_cmpy_code,l_rec_credithead.cust_code, 
			l_rec_credithead.cred_num,l_func_type) 
			
		COMMAND "Entry Details" " View Credit entry details " 
			CALL show_cred_entry(p_cmpy_code, l_rec_credithead.cred_num)
			 
		COMMAND KEY(interrupt)"Exit" " RETURN TO Credit Scan" 
			EXIT MENU 

	END MENU
	 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW A121
	 
END FUNCTION
############################################################
# END FUNCTION disp_credit(p_cmpy_code,p_cred_num)
############################################################