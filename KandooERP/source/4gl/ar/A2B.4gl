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
# common/unapply_pay.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A2B_GLOBALS.4gl" 
############################################################
# FUNCTION A2B_main()
#
# allows the user TO view payments, scanning invoices
############################################################
FUNCTION A2B_main() 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A2B") --invoice payment scan 

	OPEN WINDOW A135 with FORM "A135" 
	CALL windecoration_a("A135") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_cust() 
		IF select_invoice() THEN 
			CALL A2B_scan_invoice() 
		END IF 
	END WHILE 

	CLOSE WINDOW A135 

END FUNCTION 
############################################################
# END FUNCTION A2B_main()
############################################################


############################################################
# FUNCTION select_cust() 
#
#
############################################################
FUNCTION select_cust() 

	CLEAR FORM
	 
	INITIALIZE glob_rec_customer.* TO NULL 
	INITIALIZE glob_rec_corpcust.* TO NULL
	 
	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text

	MESSAGE kandoomsg2("A",1011,"") #1011 " Enter Customer Code FOR beginning of scan" attribute (yellow)
	INPUT BY NAME glob_rec_customer.cust_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A2B","inp-cust_code") 
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" 
			LET glob_rec_customer.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD cust_code 

		AFTER FIELD cust_code 
			IF glob_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("A",9024,"") 			#A9024 "You must enter a customer code"
				NEXT FIELD cust_code 
			ELSE 
				CALL db_customer_get_rec(UI_OFF,glob_rec_customer.cust_code ) RETURNING glob_rec_customer.* 
--				SELECT * INTO glob_rec_customer.* 
--				FROM customer 
--				WHERE cust_code = glob_rec_customer.cust_code 
--				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF glob_rec_customer.cust_code IS NULL THEN
					ERROR kandoomsg2("A",9009,"") 				#A9009 " Customer NOT found, try window "
					NEXT FIELD cust_code 
				END IF 
				
				IF glob_rec_customer.corp_cust_code IS NOT NULL 
				AND glob_rec_customer.corp_cust_ind = "1" THEN 
					SELECT * INTO glob_rec_corpcust.* 
					FROM customer 
					WHERE cust_code = glob_rec_customer.corp_cust_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = NOTFOUND THEN 
						ERROR kandoomsg2("A",9009,"") 					#A9009 "customer code NOT found"
						NEXT FIELD cust_code 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF glob_rec_corpcust.cust_code IS NULL THEN 
			DISPLAY BY NAME glob_rec_customer.name_text 

		ELSE 
			DISPLAY glob_rec_corpcust.cust_code TO invoicehead.cust_code 
			DISPLAY glob_rec_corpcust.name_text TO customer.name_text 
			DISPLAY glob_rec_customer.cust_code TO invoicehead.org_cust_code 
			DISPLAY glob_rec_customer.name_text TO formonly.org_name_text 
		END IF 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_cust() 
############################################################


############################################################
# FUNCTION select_invoice()  
#
#
############################################################
FUNCTION select_invoice() 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 

	MESSAGE kandoomsg2("A",1001,"")	#A1001 Enter Selection Criteria
	CONSTRUCT BY NAME l_where_text ON 
		inv_num, 
		purchase_code, 
		inv_date, 
		year_num, 
		period_num, 
		total_amt, 
		paid_amt, 
		posted_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A2B","construct-invoice") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		ERROR kandoomsg2("A",1002,"") 
		IF glob_rec_corpcust.cust_code IS NULL THEN 
			LET l_where_text = l_where_text clipped, 
			" AND cust_code = '",glob_rec_customer.cust_code clipped,"'" ##huho added clipped 
		ELSE 
			LET l_where_text = l_where_text clipped, 
			" AND cust_code = '",glob_rec_corpcust.cust_code clipped,"'", # huohoclipped 
			" AND org_cust_code = '",glob_rec_customer.cust_code clipped,"'" 
		END IF 
		LET l_query_text = "SELECT * FROM invoicehead ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code clipped,"' ", 
		"AND paid_amt > 0 ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY inv_num" 
		PREPARE s_invoicehead FROM l_query_text 
		DECLARE c_invoicehead CURSOR FOR s_invoicehead 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION select_invoice()  
############################################################


############################################################
# FUNCTION A2B_scan_invoice() 
#
#
############################################################
FUNCTION A2B_scan_invoice() 
	DEFINE l_arr_rec_invoicehead DYNAMIC ARRAY OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt, 
		posted_flag LIKE invoicehead.posted_flag 
	END RECORD
	DEFINE l_arr_rec_origcust array[250] OF RECORD 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text 
	END RECORD
	DEFINE l_idx SMALLINT --, scrn 
	DEFINE l_name_text LIKE customer.name_text 

	LET l_idx = 0 
	FOREACH c_invoicehead INTO glob_rec_invoicehead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_invoicehead[l_idx].inv_num = glob_rec_invoicehead.inv_num 
		LET l_arr_rec_invoicehead[l_idx].purchase_code = glob_rec_invoicehead.purchase_code 
		LET l_arr_rec_invoicehead[l_idx].inv_date = glob_rec_invoicehead.inv_date 
		LET l_arr_rec_invoicehead[l_idx].year_num = glob_rec_invoicehead.year_num 
		LET l_arr_rec_invoicehead[l_idx].period_num = glob_rec_invoicehead.period_num 
		LET l_arr_rec_invoicehead[l_idx].total_amt = glob_rec_invoicehead.total_amt 
		LET l_arr_rec_invoicehead[l_idx].paid_amt = glob_rec_invoicehead.paid_amt 
		LET l_arr_rec_invoicehead[l_idx].posted_flag = glob_rec_invoicehead.posted_flag 
		IF glob_rec_invoicehead.org_cust_code IS NOT NULL THEN 
			LET l_arr_rec_origcust[l_idx].cust_code = glob_rec_invoicehead.org_cust_code 
			SELECT name_text INTO l_arr_rec_origcust[l_idx].name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_invoicehead.org_cust_code 
		ELSE 
			LET l_arr_rec_origcust[l_idx].cust_code = NULL 
			LET l_arr_rec_origcust[l_idx].name_text = NULL 
		END IF 

	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9110,"") 	#A9110" No invoices selected"
	ELSE 
		MESSAGE kandoomsg2("A",1007,"")		#1007 SELECT invoice AND press RETURN TO view applications"
		DISPLAY ARRAY l_arr_rec_invoicehead TO sr_invoicehead.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A2B","inp-arr-invoicehead")

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET glob_rec_invoicehead.inv_num = l_arr_rec_invoicehead[l_idx].inv_num 
				DISPLAY l_arr_rec_origcust[l_idx].cust_code TO org_cust_code 
				DISPLAY l_arr_rec_origcust[l_idx].name_text TO formonly.org_name_text 
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		
			ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD purchase_code 
				IF l_arr_rec_invoicehead[l_idx].inv_num IS NOT NULL THEN 
					LET l_arr_rec_invoicehead[l_idx].paid_amt = 
					unapply_pay(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.cust_code,	l_arr_rec_invoicehead[l_idx].inv_num) 
				END IF 

		END DISPLAY 
	END IF 
	
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
############################################################
# END FUNCTION A2B_scan_invoice() 
############################################################