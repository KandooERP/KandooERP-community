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
# common/creddetl.4gl
###########################################################################

# \brief module A45.4gl - Credit Note Inquiry
#                     allows the user TO view Credit Information

#################################################################
# GLOBAL scope variables
#################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A45_GLOBALS.4gl"

#################################################################
# MAIN
#
#
#################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("A45") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A121 with FORM "A121" 
	CALL windecoration_a("A121") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	DISPLAY glob_rec_arparms.credit_ref1_text  TO credit_ref1_text
	
	CALL query()
	 
	CLOSE WINDOW A121 
	
END MAIN 
#################################################################
# END MAIN
#################################################################


#################################################################
# FUNCTION db_credithead_get_datasource()
#
#
#################################################################
FUNCTION db_credithead_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text CHAR(1000) 
	DEFINE l_query_text STRING
	DEFINE l_query_count_text STRING
	DEFINE l_query_segment STRING
	DEFINE l_ret_count_credit SMALLINT 
	MESSAGE kandoomsg2("A",1001,"") 

	#Make sure module scope cursor is not open from previous session
	WHENEVER ERROR CONTINUE 
		CLOSE c_count_credit 
		CLOSE c_credit 
	WHENEVER ERROR STOP
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	IF p_filter THEN

		CLEAR FORM 
		DISPLAY glob_rec_arparms.credit_ref1_text TO credit_ref1_text
	
		CONSTRUCT l_where_text ON 
			credithead.cust_code, 
			customer.name_text, 
			credithead.org_cust_code, 
			o_cust.name_text, 
			credithead.cred_num, 
			credithead.cred_date, 
			credithead.job_code, 
			credithead.cred_text, 
			customer.currency_code, 
			credithead.goods_amt, 
			credithead.hand_amt, 
			credithead.freight_amt, 
			credithead.tax_amt, 
			credithead.total_amt, 
			credithead.appl_amt, 
			credithead.disc_amt, 
			credithead.year_num, 
			credithead.period_num, 
			credithead.posted_flag, 
			credithead.on_state_flag, 
			credithead.cred_ind, 
			credithead.entry_code, 
			credithead.entry_date, 
			credithead.sale_code, 
			credithead.com1_text, 
			credithead.com2_text, 
			credithead.rev_date, 
			credithead.rev_num 
		FROM 
			credithead.cust_code, 
			customer.name_text, 
			credithead.org_cust_code, 
			formonly.org_name_text, 
			credithead.cred_num, 
			credithead.cred_date, 
			credithead.job_code, 
			credithead.cred_text, 
			customer.currency_code, 
			credithead.goods_amt, 
			credithead.hand_amt, 
			credithead.freight_amt, 
			credithead.tax_amt, 
			credithead.total_amt, 
			credithead.appl_amt, 
			credithead.disc_amt, 
			credithead.year_num, 
			credithead.period_num, 
			credithead.posted_flag, 
			credithead.on_state_flag, 
			credithead.cred_ind, 
			credithead.entry_code, 
			credithead.entry_date, 
			credithead.sale_code, 
			credithead.com1_text, 
			credithead.com2_text, 
			credithead.rev_date, 
			credithead.rev_num 
	
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A45","construct-credithead") 
	
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
	
	MESSAGE kandoomsg2("A",1002,"") #A1002 Searching database - please wait
	LET glob_y = length(l_where_text) 
	LET glob_word = "" 
	LET glob_use_outer = true 
	
	FOR glob_x = 1 TO glob_y 
		LET glob_letter = l_where_text[glob_x,(glob_x+1)] 
		IF glob_letter = " " OR 
			glob_letter = "=" OR 
			glob_letter = "(" OR 
			glob_letter = ")" OR 
			glob_letter = "[" OR 
			glob_letter = "]" OR 
			glob_letter = "." OR 
			glob_letter = "," THEN 
			LET glob_word = "" 
		END IF 

		LET glob_word = glob_word clipped,glob_letter 

		IF glob_word = "o_cust" THEN 
			LET glob_use_outer = false 
			EXIT FOR 
		END IF 
	END FOR 
	
	IF glob_use_outer THEN 
		#data query
		LET l_query_text = 
			"SELECT credithead.*,", 
			"customer.name_text, ", 
			"o_cust.name_text "
			#count query
		LET l_query_count_text = "SELECT count(*) "
		
		LET l_query_segment =
			"FROM credithead, ", 
			"customer, ", 
			"outer customer o_cust ", 
			"WHERE customer.cust_code = credithead.cust_code ", 
			"AND credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
			"AND customer.cmpy_code = credithead.cmpy_code ", 
			"AND o_cust.cust_code = credithead.org_cust_code ", 
			"AND o_cust.cmpy_code = credithead.cmpy_code ", 
			"AND ",l_where_text clipped
		
		LET l_query_text       = l_query_text CLIPPED,       " ", l_query_segment CLIPPED
		LET l_query_count_text = l_query_count_text CLIPPED, " ", l_query_segment CLIPPED
		 
		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = l_query_text clipped, " ORDER BY credithead.cust_code,", "credithead.cred_num "
		ELSE 
			LET l_query_text = l_query_text clipped, " ORDER BY customer.name_text,", "credithead.cred_num " 
		END IF 

	ELSE #------------------------  glob_use_outer = FALSE/0
	
		#data query
		LET l_query_text = 
			"SELECT credithead.*,", 
			"customer.name_text, ", 
			"o_cust.name_text "

		#count query
		LET l_query_count_text = "SELECT count(*) "

		LET l_query_segment =				 
			"FROM credithead,", 
			"customer, ", 
			"customer o_cust ", 
			"WHERE customer.cust_code = credithead.cust_code ", 
			"AND credithead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code CLIPPED,"\" ", 
			"AND customer.cmpy_code = credithead.cmpy_code ", 
			"AND o_cust.cust_code = credithead.org_cust_code ", 
			"AND o_cust.cmpy_code = credithead.cmpy_code ", 
			"AND ",l_where_text clipped 

		LET l_query_text       = l_query_text CLIPPED,       " ", l_query_segment CLIPPED
		LET l_query_count_text = l_query_count_text CLIPPED, " ", l_query_segment CLIPPED

		IF glob_rec_arparms.report_ord_flag = "C" THEN 
			LET l_query_text = l_query_text clipped," ORDER BY credithead.cust_code,", 
			"credithead.cred_num " 
		ELSE 
			LET l_query_text = l_query_text clipped," ORDER BY customer.name_text,", 
			"credithead.cred_num " 
		END IF 
	END IF 
	
	#COUNT
	PREPARE s_count_credit FROM l_query_count_text 
	DECLARE c_count_credit SCROLL CURSOR FOR s_count_credit 
	OPEN c_count_credit 
	FETCH c_count_credit INTO l_ret_count_credit 

	#DATA
	PREPARE s_credit FROM l_query_text 
	DECLARE c_credit SCROLL CURSOR FOR s_credit 
	OPEN c_credit 
	FETCH c_credit INTO glob_rec_credithead.*, glob_rec_customer.name_text, glob_org_name_text 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2 ("A",9508,"") 		# " No Credits Satisfied the Selection Criteria"
		LET l_ret_count_credit = 0 
	END IF
	
	RETURN l_ret_count_credit #return number/count of found rows 
END FUNCTION 
#################################################################
# END FUNCTION db_credithead_get_datasource()
#################################################################


#################################################################
# FUNCTION menu_options_handler(p_count)
#
# 
#################################################################
FUNCTION menu_options_handler(p_count)
	DEFINE p_count SMALLINT
	
	DISPLAY p_count TO data_source_count	
	CASE
		WHEN p_count = 0 
			HIDE option "Detail" 

			HIDE option "First" 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Last" 

		WHEN p_count = 1
			CALL disp_credit()  
			SHOW option "Detail" 

			HIDE option "First" 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "Last" 
		
		WHEN p_count = 2
			CALL disp_credit()  
			SHOW option "Detail" 

			HIDE option "First" 
			SHOW option "Next" 
			SHOW option "Previous" 
			HIDE option "Last" 

		WHEN p_count > 3
			CALL disp_credit()  
			SHOW option "Detail" 

			SHOW option "First"
			SHOW option "Next" 
			SHOW option "Previous" 
			SHOW option "Last" 
	END CASE			
	
END FUNCTION
#################################################################
# END FUNCTION menu_options_handler(p_count)
#################################################################


#################################################################
# FUNCTION query()
#
# 
#################################################################
FUNCTION query() 
	DEFINE l_credit_row_count SMALLINT 
	--DEFINE l_option CHAR(1) 
	--DEFINE l_exist SMALLINT 

	MENU " Credit" 
		BEFORE MENU
			CALL publish_toolbar("kandoo","A45","menu-credit-1") 

			LET l_credit_row_count = db_credithead_get_datasource(FALSE)
			CALL menu_options_handler(l_credit_row_count)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Query" " Search FOR credits" 
			LET l_credit_row_count = db_credithead_get_datasource(TRUE)
			CALL menu_options_handler(l_credit_row_count)
		
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected credit" 
			FETCH NEXT c_credit INTO glob_rec_credithead.*, glob_rec_customer.name_text, glob_org_name_text 
			IF status <> NOTFOUND THEN 
				CALL disp_credit() 
			ELSE 
				ERROR kandoomsg2("U","9001","") 
			END IF 
			
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected credit" 
			FETCH previous c_credit INTO glob_rec_credithead.*, glob_rec_customer.name_text, glob_org_name_text 
			IF status <> NOTFOUND THEN 
				CALL disp_credit() 
			ELSE 
				ERROR kandoomsg2("U","9001","") 
			END IF 
			
			
		COMMAND KEY ("D",f20) "Detail" " View credit details" 
			CALL credit_details(glob_rec_kandoouser.cmpy_code,glob_rec_credithead.cred_num) 
			
		COMMAND KEY ("F",f18) "First" " DISPLAY first credit in the selected list" 
			FETCH FIRST c_credit INTO glob_rec_credithead.*, glob_rec_customer.name_text, glob_org_name_text 
			CALL disp_credit() 
			
		COMMAND KEY ("L",f22) "Last" " DISPLAY last receipt in the selected list" 
			FETCH LAST c_credit INTO glob_rec_credithead.*, glob_rec_customer.name_text, glob_org_name_text 
			CALL disp_credit() 
			
		COMMAND KEY(interrupt,"E") "Exit" " Exit FROM Credit Inquiry" 
			EXIT MENU 


	END MENU 
END FUNCTION 
#################################################################
# END FUNCTION query()
#################################################################


#################################################################
# FUNCTION disp_credit()
#
# 
#################################################################
FUNCTION disp_credit() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 

	SELECT name_text 
	INTO l_rec_salesperson.name_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = glob_rec_credithead.sale_code 
	
	DISPLAY glob_rec_credithead.currency_code TO currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
	
	DISPLAY glob_rec_credithead.cust_code TO cust_code
	DISPLAY glob_rec_credithead.org_cust_code TO org_cust_code
	DISPLAY glob_org_name_text TO org_name_text
	DISPLAY glob_rec_credithead.cred_num TO  cred_num
	DISPLAY glob_rec_credithead.goods_amt TO goods_amt
	DISPLAY glob_rec_credithead.hand_amt TO hand_amt
	DISPLAY glob_rec_credithead.freight_amt TO freight_amt
	DISPLAY glob_rec_credithead.tax_amt TO tax_amt
	DISPLAY glob_rec_credithead.total_amt TO total_amt
	DISPLAY glob_rec_credithead.disc_amt TO disc_amt
	DISPLAY glob_rec_credithead.appl_amt TO appl_amt
	DISPLAY glob_rec_credithead.entry_code TO entry_code
	DISPLAY glob_rec_credithead.entry_date TO entry_date
	DISPLAY glob_rec_credithead.sale_code TO sale_code
	DISPLAY glob_rec_credithead.cred_text TO cred_text
	DISPLAY glob_rec_credithead.job_code TO job_code
	DISPLAY glob_rec_credithead.cred_date TO cred_date
	DISPLAY glob_rec_credithead.year_num TO year_num
	DISPLAY glob_rec_credithead.period_num TO period_num
	DISPLAY glob_rec_credithead.posted_flag TO posted_flag
	DISPLAY glob_rec_credithead.on_state_flag TO on_state_flag
	DISPLAY glob_rec_credithead.cred_ind TO cred_ind
	DISPLAY glob_rec_credithead.com1_text TO com1_text
	DISPLAY glob_rec_credithead.rev_date TO rev_date
	DISPLAY glob_rec_credithead.com2_text TO com2_text
	DISPLAY glob_rec_credithead.rev_num TO rev_num
	
	DISPLAY glob_rec_customer.name_text TO customer.name_text
	DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

END FUNCTION
#################################################################
# END FUNCTION disp_credit()
#################################################################