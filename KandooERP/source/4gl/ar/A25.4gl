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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A25_GLOBALS.4gl" 
############################################################
# FUNCTION A25_main()
#
# Invoice Inquiry allows the user TO view Invoice Information
############################################################
FUNCTION A25_main() 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A25") 

	SELECT inv_ref1_text INTO glob_ref_text FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET glob_temp_text = glob_ref_text clipped,"................" 
	LET glob_ref_text = glob_temp_text 
	LET glob_func_type = "View Invoice" 

	OPEN WINDOW A192 with FORM "A192" 

	CALL windecoration_a("A192") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	CALL A25_invoice_inquiry_menu() 

	CLOSE WINDOW A192 
	
END FUNCTION 
############################################################
# END FUNCTION A25_main()
############################################################


############################################################
# FUNCTION select_invoice() 
#
# 
###########################################################
FUNCTION select_invoice() 
	DEFINE l_query_select_text STRING
	DEFINE l_query_part_text STRING
	DEFINE l_where_part STRING	 
	DEFINE l_query_count_text STRING
	DEFINE l_count SMALLINT
	
	CLEAR FORM 

	DISPLAY glob_ref_text TO inv_ref1_text 

	MESSAGE kandoomsg2("A",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT l_where_part ON 
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
		invoicehead.hand_tax_amt, 
		invoicehead.freight_amt, 
		invoicehead.freight_tax_amt, 
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
		invoicehead.hand_tax_amt, 
		invoicehead.freight_amt, 
		invoicehead.freight_tax_amt, 
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

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A25","construct-invoice") 

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

	LET glob_y = length(l_where_part) 
	LET glob_word = "" 
	LET glob_use_outer = true 

	FOR glob_x = 1 TO glob_y 
		LET glob_letter = l_where_part[glob_x,(glob_x+1)] 
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

	LET l_query_part_text = ""
	LET l_query_count_text = "SELECT count(*) "  #only for counting
	 
	IF glob_use_outer THEN 
		LET l_query_select_text = "SELECT invoicehead.*, customer.name_text, o_cust.name_text " 
		
		LET l_query_part_text =	
			" FROM invoicehead , customer, outer customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",l_where_part clipped
		LET  l_query_count_text = trim(l_query_count_text), " ", trim(l_query_part_text)
		LET  l_query_part_text = trim(l_query_select_text), " ", trim(l_query_part_text)
		
	ELSE 
	
		LET l_query_part_text = "SELECT invoicehead.*,", "customer.name_text, o_cust.name_text "
		
		LET l_query_select_text =  
			"FROM invoicehead , customer, customer o_cust ", 
			"WHERE invoicehead.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND customer.cust_code = invoicehead.cust_code ", 
			"AND customer.cmpy_code = invoicehead.cmpy_code ", 
			"AND o_cust.cust_code = invoicehead.org_cust_code ", 
			"AND o_cust.cmpy_code = invoicehead.cmpy_code ", 
			"AND ",l_where_part clipped 

		LET l_query_part_text = trim(l_query_select_text), " ", trim(l_query_part_text)
		LET l_query_count_text = trim(l_query_count_text), " ", trim(l_query_part_text)		

	END IF
	 
	IF glob_rec_arparms.report_ord_flag = "C" THEN 
		LET l_query_part_text = l_query_part_text clipped, " ",	"ORDER BY invoicehead.cust_code, invoicehead.inv_num" 
	ELSE 
		LET l_query_part_text = l_query_part_text clipped, " ",	"ORDER BY customer.name_text, invoicehead.cust_code,",	"invoicehead.inv_num"
	END IF 

	MESSAGE kandoomsg2("A",1002,"")	#1002 Searching database - please wait

	WHENEVER ERROR CONTINUE

	CLOSE c_invoicehead_count
	CLOSE c_invoicehead
	 
	OPTIONS SQL interrupt ON 

	PREPARE s_invoicehead_count FROM l_query_count_text 
	DECLARE c_invoicehead_count SCROLL CURSOR FOR s_invoicehead_count 

	OPEN c_invoicehead_count 
	FETCH c_invoicehead_count INTO l_count

	
	PREPARE s_invoicehead FROM l_query_part_text 
	DECLARE c_invoicehead SCROLL CURSOR FOR s_invoicehead 
	OPEN c_invoicehead 
	FETCH c_invoicehead INTO 
		glob_rec_invoicehead.*, 
		glob_rec_customer.name_text, 
		glob_org_name_text
	 
	OPTIONS SQL interrupt off 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9110,"") 	#9110 "No Invoices Satisfied the Selection Criteria "
	ELSE 

	END IF
	
	RETURN l_count 
END FUNCTION 
############################################################
# END FUNCTION select_invoice() 
############################################################


############################################################
# FUNCTION A25_invoice_inquiry_menu() 
#
# 
############################################################
FUNCTION A25_invoice_inquiry_menu() 
	DEFINE l_count SMALLINT
	DEFINE l_exist SMALLINT 

	DISPLAY glob_ref_text TO inv_ref1_text 
	LET l_exist = false 

	MENU " Invoice" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A25","menu-invoice") 

			CALL select_invoice() RETURNING l_count
			DISPLAY l_count TO invoice_count

			IF l_count > 0 THEN 
				LET l_exist = true 
				#CALL dialog.setActionHidden("DETAIL",FALSE)
				CALL disp_invoice() 
			ELSE 
				LET l_exist = false
				#CALL dialog.setActionHidden("DETAIL",TRUE) 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			
		ON ACTION "Query" #" Search FOR invoices " #COMMAND "Query" " Search FOR invoices "

			CALL select_invoice() RETURNING l_count
			DISPLAY l_count TO invoice_count
			
			IF l_count > 0 THEN 
				LET l_exist = true 
				CALL dialog.setActionHidden("DETAIL",FALSE)
				CALL disp_invoice() 
			ELSE 
				LET l_exist = false
				CALL dialog.setActionHidden("DETAIL",TRUE) 
			END IF 
			
		ON ACTION ("Next") # " DISPLAY next selected invoice" #COMMAND KEY ("N",f21) "Next" " DISPLAY next selected invoice"

			IF l_exist THEN 
				FETCH NEXT c_invoicehead INTO 
					glob_rec_invoicehead.*, 
					glob_rec_customer.name_text, 
					glob_org_name_text 
				IF status <> NOTFOUND THEN 
					CALL disp_invoice() 
				ELSE 
					ERROR kandoomsg2("G",9157,"") 		#9157 "You have reached the END of the entries selected"
				END IF 
			ELSE 
				ERROR kandoomsg2("A",3515,"") 			#3515 "You have TO make a selection first"
				NEXT option "Query" 
			END IF 

			
		ON ACTION ("Previous") # " DISPLAY previous selected invoice" #COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected invoice"
			IF l_exist THEN 
				FETCH previous c_invoicehead INTO 
					glob_rec_invoicehead.*, 
					glob_rec_customer.name_text, 
					glob_org_name_text 
				IF status <> NOTFOUND THEN 
					CALL disp_invoice() 
				ELSE 
					ERROR kandoomsg2("G",9156,"") 			#9156 "You have reached the start of the entries selected"
				END IF 
			ELSE 
				ERROR kandoomsg2("A",3515,"") 			#3515 "You have TO make a selection first"
				NEXT option "Query" 
			END IF 

		ON ACTION ("Detail") # " View invoice details" --key ("D",f20) 
			IF l_exist THEN 
				CALL invqwind(glob_rec_kandoouser.cmpy_code,glob_rec_invoicehead.inv_num) 
			ELSE 
				ERROR kandoomsg2("A",3515,"") 			#3515 "You have TO make a selection first"
				NEXT option "Query" 
			END IF 
			
		ON ACTION ("First") # " DISPLAY first invoice in the selected list" #COMMAND KEY ("F",f18) "First" " DISPLAY first invoice in the selected list"
			IF l_exist THEN 
				FETCH FIRST c_invoicehead INTO 
					glob_rec_invoicehead.*, 
					glob_rec_customer.name_text, 
					glob_org_name_text 
				IF status <> NOTFOUND THEN 
					CALL disp_invoice() 
				ELSE 
					ERROR kandoomsg2("G",9156,"") 				#9156 "You have reached the start of the entries selected"
				END IF 
			ELSE 
				ERROR kandoomsg2("A",3515,"") 			#3515 "You have TO make a selection first"
				NEXT option "Query" 
			END IF 
			
		ON ACTION ("Last") # " DISPLAY last invoice in the selected list" #COMMAND KEY ("L",f22) "Last" " DISPLAY last invoice in the selected list"

			IF l_exist THEN 
				FETCH LAST c_invoicehead INTO 
					glob_rec_invoicehead.*, 
					glob_rec_customer.name_text, 
					glob_org_name_text 
				IF status <> NOTFOUND THEN 
					CALL disp_invoice() 
				ELSE 
					ERROR kandoomsg2("G",9157,"") 				#9157 "You have reached the END of the entries selected"
				END IF 
			ELSE 
				ERROR kandoomsg2("A",3515,"") 			#3515 "You have TO make a selection first"
				NEXT option "Query" 
			END IF 
			
		ON ACTION ("Exit") # " Exit FROM Invoice Inquiry" --key(interrupt,"E") #COMMAND "Exit" " Exit FROM Invoice Inquiry"  --KEY(interrupt,"E")
			EXIT MENU 

	END MENU 

END FUNCTION 
############################################################
# END FUNCTION A25_invoice_inquiry_menu() 
############################################################


############################################################
# FUNCTION disp_invoice()  
#
# 
###########################################################
FUNCTION disp_invoice() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_tot_sale_tax LIKE invoicehead.tax_amt 

	LET l_tot_sale_tax = glob_rec_invoicehead.tax_amt + glob_rec_invoicehead.hand_tax_amt	+ glob_rec_invoicehead.freight_tax_amt 
	DISPLAY l_tot_sale_tax TO total_tax_amt 

	IF glob_rec_invoicehead.paid_date != "31/12/1899" THEN 
		DISPLAY BY NAME glob_rec_invoicehead.paid_date 
	END IF 

	DISPLAY BY NAME glob_rec_invoicehead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
	DISPLAY BY NAME 
		glob_rec_invoicehead.cust_code, 
		glob_rec_invoicehead.org_cust_code, 
		glob_rec_invoicehead.inv_num, 
		glob_rec_invoicehead.ord_num, 
		glob_rec_invoicehead.job_code, 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.hand_amt, 
		glob_rec_invoicehead.hand_tax_amt, 
		glob_rec_invoicehead.freight_amt, 
		glob_rec_invoicehead.freight_tax_amt, 
		glob_rec_invoicehead.total_amt, 
		glob_rec_invoicehead.paid_amt, 
		glob_rec_invoicehead.inv_date, 
		glob_rec_invoicehead.due_date, 
		glob_rec_invoicehead.disc_date, 
		glob_rec_invoicehead.paid_date, 
		glob_rec_invoicehead.disc_amt, 
		glob_rec_invoicehead.disc_taken_amt, 
		glob_rec_invoicehead.year_num, 
		glob_rec_invoicehead.period_num, 
		glob_rec_invoicehead.posted_flag, 
		glob_rec_invoicehead.entry_code, 
		glob_rec_invoicehead.entry_date, 
		glob_rec_invoicehead.ref_num, 
		glob_rec_invoicehead.sale_code, 
		glob_rec_invoicehead.inv_ind, 
		glob_rec_invoicehead.purchase_code, 
		glob_rec_invoicehead.com1_text, 
		glob_rec_invoicehead.com2_text, 
		glob_rec_invoicehead.on_state_flag, 
		glob_rec_invoicehead.rev_date, 
		glob_rec_invoicehead.rev_num 
	
	DISPLAY glob_org_name_text TO name_text
	
	SELECT name_text 
	INTO l_rec_salesperson.name_text 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = glob_rec_invoicehead.sale_code 

	DISPLAY glob_rec_customer.name_text TO customer.name_text 
	DISPLAY l_rec_salesperson.name_text TO salesperson.name_text 

END FUNCTION 
############################################################
# END FUNCTION disp_invoice()  
###########################################################