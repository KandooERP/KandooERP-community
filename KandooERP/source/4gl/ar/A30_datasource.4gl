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
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl"

################################################################
# FUNCTION db_cashreceipt_get_datasource(p_rec_cashreceipt)
#
#
################################################################
FUNCTION db_cashreceipt_get_datasource(p_rec_cashreceipt)
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_s_cashreceipt OF A30_glob_dt_rec_receipt 
--	DEFINE p_rec_s_cashreceipt OF A30_glob_dt_rec_receipt --RECORD LIKE cashreceipt.*
--	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_cashreceipt DYNAMIC ARRAY OF A30_glob_dt_rec_receipt --RECORD --array[320] OF RECORD 
--		cash_num LIKE cashreceipt.cash_num, 
--		cheque_text LIKE cashreceipt.cheque_text, 
--		#com1_text LIKE cashreceipt.com1_text,
--		cash_date LIKE cashreceipt.cash_date, 
--		year_num LIKE cashreceipt.year_num, 
--		period_num LIKE cashreceipt.period_num, 
--		cash_amt LIKE cashreceipt.cash_amt, 
--		applied_amt LIKE cashreceipt.applied_amt, 
--		posted_flag LIKE cashreceipt.posted_flag 
--	END RECORD
	DEFINE l_idx SMALLINT --, scrn 
	DEFINE l_query STRING

	IF p_rec_cashreceipt.cust_code IS NULL AND (p_rec_cashreceipt.cash_num = 0 OR p_rec_cashreceipt.cash_num IS NULL) THEN
		
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1020,"Cash Receipt") #1020 Enter Cash Receipt Details; OK TO Continue
		INPUT p_rec_cashreceipt.cust_code, p_rec_cashreceipt.cash_num FROM cust_code, cash_num ATTRIBUTE(UNBUFFERED)
	
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A36","inp-cashreceipt") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			ON ACTION "LOOKUP" infield (cust_code) 
				LET p_rec_cashreceipt.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME p_rec_cashreceipt.cust_code 
				NEXT FIELD cust_code 
	
			ON CHANGE cust_code #cust_code is required !	
				CALL db_customer_get_rec(UI_OFF,p_rec_cashreceipt.cust_code) RETURNING p_rec_cashreceipt.*
				
				IF p_rec_cashreceipt.cust_code IS NULL THEN 
					ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
					NEXT FIELD cust_code
				ELSE
					DISPLAY db_customer_get_name_text(UI_OFF,p_rec_cashreceipt.cust_code) TO name_text
				END IF 
			
				DISPLAY db_customer_get_name_text(UI_OFF,p_rec_cashreceipt.cust_code) TO customer.name_text
				DISPLAY db_customer_get_currency_code(UI_OFF,p_rec_cashreceipt.cust_code) TO customer.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 
				DISPLAY db_currency_get_desc_text(UI_OFF,db_customer_get_currency_code(UI_OFF,p_rec_cashreceipt.cust_code)) TO currency.desc_text
	
			AFTER INPUT
				IF int_flag OR quit_flag THEN
					IF promptTF("Exit Program","Do you want to exit this program´?","Y") THEN  
						EXIT PROGRAM
					ELSE
						LET int_flag = FALSE 
						LET quit_flag = FALSE 
						CONTINUE INPUT
					END IF
				ELSE
					IF p_rec_cashreceipt.cust_code IS NULL THEN
						ERROR "Customer Code must be specified"
						NEXT FIELD cust_code
					END IF
				END IF
				
				
		END INPUT 
	

	END IF
	DISPLAY db_customer_get_name_text(UI_OFF,p_rec_cashreceipt.cust_code) TO name_text
	--DISPLAY BY NAME l_rec_customer.name_text 
	DISPLAY BY NAME p_rec_cashreceipt.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it 

	IF p_rec_cashreceipt.cash_num IS NULL THEN 
		LET p_rec_cashreceipt.cash_num = 0 
	END IF 
#--------------------
	LET l_query = 
		"SELECT ",
		"cashreceipt.cash_num,",
		"cashreceipt.com1_text,",
		"cashreceipt.cheque_text,",
		"cashreceipt.cash_date,",
		"cashreceipt.year_num,",
		"cashreceipt.period_num,",
		"cashreceipt.cash_amt,",
		"cashreceipt.applied_amt,",
		"cashreceipt.posted_flag ",
		"FROM cashreceipt ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "' "

	IF  p_rec_cashreceipt.cust_code IS NOT NULL THEN	 
		LET l_query = l_query CLIPPED, " AND cust_code = '", p_rec_cashreceipt.cust_code CLIPPED, "'"
	END IF
	
	IF  p_rec_cashreceipt.cash_num != 0 THEN
		LET l_query = l_query CLIPPED, " AND cash_num >= ", p_rec_cashreceipt.cash_num CLIPPED
	END IF 
	
	LET l_query = l_query CLIPPED, " ORDER BY cash_num" 
	
	PREPARE s_cash FROM l_query
	DECLARE c_cash CURSOR FOR s_cash

	LET l_idx = 0 
	FOREACH c_cash INTO l_rec_s_cashreceipt.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cashreceipt[l_idx].cash_num = l_rec_s_cashreceipt.cash_num 
		LET l_arr_rec_cashreceipt[l_idx].com1_text = l_rec_s_cashreceipt.com1_text 
		LET l_arr_rec_cashreceipt[l_idx].cheque_text = l_rec_s_cashreceipt.cheque_text 
		LET l_arr_rec_cashreceipt[l_idx].cash_date = l_rec_s_cashreceipt.cash_date 
		LET l_arr_rec_cashreceipt[l_idx].year_num = l_rec_s_cashreceipt.year_num 
		LET l_arr_rec_cashreceipt[l_idx].period_num = l_rec_s_cashreceipt.period_num 
		LET l_arr_rec_cashreceipt[l_idx].cash_amt = l_rec_s_cashreceipt.cash_amt 
		LET l_arr_rec_cashreceipt[l_idx].applied_amt = l_rec_s_cashreceipt.applied_amt 
		LET l_arr_rec_cashreceipt[l_idx].posted_flag = l_rec_s_cashreceipt.posted_flag 
	END FOREACH 
	
	RETURN l_arr_rec_cashreceipt, p_rec_cashreceipt.*
END FUNCTION
################################################################
# FUNCTION db_cashreceipt_get_datasource(p_rec_cashreceipt)
################################################################

########################################################################
# FUNCTION db_cashreceipt_get_datasource_2()
#
#
########################################################################
FUNCTION db_cashreceipt_get_datasource_2(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_order_text CHAR(50) 
	DEFINE l_cust SMALLINT 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_arr_rec_cashreceipt DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		cash_num LIKE cashreceipt.cash_num, 
		cust_code LIKE cashreceipt.cust_code , 
		cash_date LIKE cashreceipt.cash_date, 
		year_num LIKE cashreceipt.year_num, 
		period_num LIKE cashreceipt.period_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt, 
		posted_flag LIKE cashreceipt.posted_flag 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	LET l_cust = false 
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 Enter selection criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_text ON 
			cash_num, 
			cust_code, 
			cash_date, 
			year_num, 
			period_num, 
			cash_amt, 
			applied_amt, 
			posted_flag 
	
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A3A","construct-cash") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
			AFTER CONSTRUCT 
				IF field_touched(cust_code) THEN 
					LET l_cust = true 
				END IF 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	
	IF l_cust THEN 
		LET l_order_text = " cust_code,cash_num" 
	ELSE 
		LET l_order_text = " cash_num" 
	END IF 

	MESSAGE kandoomsg2("A",1002,"") 
	## SELECT unapplied receipts AND omit the neg've receipts
	## associated with a dishonoured cheque.

	
	LET l_query_text = 
		"SELECT * FROM cashreceipt ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
		"AND cash_amt != applied_amt ", 
		"AND ",l_where_text clipped," ", 
		"AND (cash_amt >= 0 OR job_code IS NULL) ", 
		"ORDER BY ",l_order_text clipped 
	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_cashreceipt CURSOR FOR s_cashreceipt 

	LET l_idx = 0 
	FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cashreceipt[l_idx].cash_num = l_rec_cashreceipt.cash_num 
		LET l_arr_rec_cashreceipt[l_idx].cust_code = l_rec_cashreceipt.cust_code 
		LET l_arr_rec_cashreceipt[l_idx].cash_date = l_rec_cashreceipt.cash_date 
		LET l_arr_rec_cashreceipt[l_idx].year_num = l_rec_cashreceipt.year_num 
		LET l_arr_rec_cashreceipt[l_idx].period_num = l_rec_cashreceipt.period_num 
		LET l_arr_rec_cashreceipt[l_idx].cash_amt = l_rec_cashreceipt.cash_amt 
		LET l_arr_rec_cashreceipt[l_idx].applied_amt = l_rec_cashreceipt.applied_amt 
		LET l_arr_rec_cashreceipt[l_idx].posted_flag = l_rec_cashreceipt.posted_flag 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("U",9101,"") #9101 No cashreceipts satisfied the selection criteria
	END IF

	RETURN l_arr_rec_cashreceipt 
END FUNCTION
########################################################################
# END FUNCTION db_cashreceipt_get_datasource_2()
########################################################################

###########################################################################
# FUNCTION get_datasource_invoice_apply_cash(p_filter,p_company_cmpy_code,p_rec_cashreceipt) 
#
# \brief module A31b allows the user TO apply Cash Receipts TO the invoices

#              The user can apply cash TO as many invoices as desired
#              AND IS NOT required TO completely pay any particular
#              invoice before applying cash TO another
###########################################################################
FUNCTION get_datasource_invoice_apply_cash(p_filter,p_company_cmpy_code,p_rec_cashreceipt) 
	DEFINE p_filter boolean 
	DEFINE p_company_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_arr_rec_cashreceipt DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt, 
		total_amt LIKE invoicehead.total_amt, 
		paid_amt LIKE invoicehead.paid_amt 
	END RECORD 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_query_text_data STRING #SQL for data array
	DEFINE l_query_text_count STRING  #SQL for count
	DEFINE l_where2_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_recalc_ind CHAR(1) 
	DEFINE l_count SMALLINT
	DEFINE l_msg STRING
	
	IF p_filter THEN 

		MESSAGE kandoomsg2("A",1078,"") 		#1001 " Enter selection criteria AND press ESC TO begin search"
		CONSTRUCT BY NAME l_where_text ON 
			inv_num, 
			purchase_code, 
			disc_amt, 
			total_amt, 
			paid_amt, 
			due_date, 
			disc_date, 
			inv_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A31b","construct-invoice") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Invoice" 	--      ON KEY(F8)
				LET l_where2_text = invext_select(p_company_cmpy_code) 
				IF l_where2_text IS NULL THEN 
					CONTINUE CONSTRUCT 
				ELSE 
					EXIT CONSTRUCT 
				END IF 

			AFTER CONSTRUCT 
				IF not(int_flag OR quit_flag) THEN 
					IF l_where2_text IS NULL THEN 
						LET l_where2_text = " 1=1 " 
					END IF 
				END IF 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
			LET l_where2_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
		LET l_where2_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("A",1002,"") 
	LET l_query_text_data = "SELECT * FROM invoicehead "
	LET l_query_text_count = "SELECT count(*) FROM invoicehead "

	LET l_query_text = 	 
		"WHERE cmpy_code = '",trim(p_company_cmpy_code),"' ", 
		"AND cust_code = '",trim(p_rec_cashreceipt.cust_code),"' ", 
		"AND ",l_where_text clipped," ", 
		"AND ",l_where2_text clipped 

	IF p_rec_cashreceipt.job_code IS NULL THEN 
		IF p_rec_cashreceipt.cash_amt < 0 THEN 
			LET l_query_text = l_query_text clipped,	" AND paid_amt > 0 " 
		ELSE 
			LET l_query_text = l_query_text clipped,	" AND total_amt != paid_amt " 
		END IF 
	END IF 
	
	#Count first
	LET l_query_text_count = l_query_text_count, " ", trim(l_query_text)
	
	LET l_query_text_data = 
		l_query_text_data CLIPPED, " ", l_query_text clipped, 
		" ORDER BY cust_code, due_date, inv_date, inv_num" 

	PREPARE s_invoice_count FROM l_query_text_count 
	DECLARE c_invoice_count CURSOR FOR s_invoice_count 

	FOREACH c_invoice_count INTO l_count	
		#??? huho: hmmm.. why was this done this way ?
	END FOREACH
	
	IF l_count = 0 THEN
		CALL fgl_winmessage("Nothing to apply","Can not apply the choosen invoices/receipts.\nNo open invoice exists for this customer","WARNING")
	ELSE
		LET l_msg = "Attempting to apply ", trim(l_count), " invoices/receipts"
		CALL fgl_winmessage("Apply",l_msg,"info")
	END IF
			
	PREPARE s_invoice FROM l_query_text_data 
	DECLARE c_invoice CURSOR FOR s_invoice 
	LET l_idx = 0 

	CASE get_kandoooption_feature_state("AR","PT") 
		WHEN '1' 
			LET l_recalc_ind = 'N' 
		WHEN '2' 
			LET l_recalc_ind = 'Y' 
		WHEN '3' 
			LET l_recalc_ind = kandoomsg("A",1051,"") 
			#A1051 Override invoice discount settings (Y/N)
		OTHERWISE 
			LET l_recalc_ind = 'N' 
	END CASE 

	LET l_idx = 0

	FOREACH c_invoice INTO l_rec_invoicehead.* 
		IF l_rec_invoicehead.disc_amt IS NULL THEN #got NULL disc_amt (not 0.0)from invoice head.. this corrects it 
			LET l_rec_invoicehead.disc_amt = 0 
		END IF 
		
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cashreceipt[l_idx].inv_num = l_rec_invoicehead.inv_num 
		LET l_arr_rec_cashreceipt[l_idx].purchase_code = l_rec_invoicehead.purchase_code 
		LET l_arr_rec_cashreceipt[l_idx].pay_amt = 0 
		LET l_arr_rec_cashreceipt[l_idx].disc_amt = 0 

		MESSAGE "Apply Invoice ", trim(l_arr_rec_cashreceipt[l_idx].inv_num), " for the total amount of ", trim(l_rec_invoicehead.total_amt)

		IF p_rec_cashreceipt.cash_amt >= 0	AND p_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N THEN 
			## certain criteria apply before def.discount will show
			IF l_recalc_ind = 'Y' THEN 
				LET l_arr_rec_cashreceipt[l_idx].disc_amt = l_rec_invoicehead.total_amt * 
				 
					show_disc( 
						p_company_cmpy_code, 
						l_rec_invoicehead.term_code, 
						p_rec_cashreceipt.cash_date, 
						l_rec_invoicehead.inv_date ) / 100 
				
				 
			ELSE 
				IF p_rec_cashreceipt.cash_date <= l_rec_invoicehead.disc_date THEN 
					LET l_arr_rec_cashreceipt[l_idx].disc_amt = l_rec_invoicehead.disc_amt 
				END IF 
			END IF 
		END IF
		 
		LET l_arr_rec_cashreceipt[l_idx].total_amt = l_rec_invoicehead.total_amt 
		LET l_arr_rec_cashreceipt[l_idx].paid_amt = l_rec_invoicehead.paid_amt 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 
	
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9110,"") 
	END IF 

	RETURN l_arr_rec_cashreceipt, l_rec_invoicehead.* 
END FUNCTION 
############################################################
# END FUNCTION get_datasource_invoice_apply_cash(p_filter,p_company_cmpy_code,p_rec_cashreceipt) 
############################################################



################################################################
# FUNCTION A39_db_cashreceipt_get_datasource(p_filter,p_query_module_id)
#
#
################################################################
FUNCTION A39_db_cashreceipt_get_datasource(p_filter,p_query_module_id)
	DEFINE p_filter BOOLEAN 
	DEFINE p_query_module_id VARCHAR(5) #LIKE program.module_id
	DEFINE l_module_where_text STRING
	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF A39_glob_dt_rec_receipt
	DEFINE l_rec_s_cashreceipt OF A39_glob_dt_rec_receipt
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_msg STRING
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 	#1001 Enter selection criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_text ON 
			cash_num, 
			cust_code, 
			cash_date, 
			year_num, 
			period_num, 
			cash_amt, 
			applied_amt, 
			posted_flag 
	
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A39","construct-cash") 
	
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
	 
	MESSAGE kandoomsg2("A",1002,"") #1002 Seraching db -pls wait

	CASE p_query_module_id
		WHEN "A39"
			LET l_module_where_text = 
			"AND applied_amt != 0 " 			
		WHEN "A3A"
			LET l_module_where_text = 
				"AND cash_amt != applied_amt "			
		OTHERWISE
			CALL fgl_winmessage("Internal 4GL Error","Invalid p_query_module_id","ERROR")
	END CASE


	LET l_query_text =
		"SELECT ", 
		"cashreceipt.cash_num,",
		"cashreceipt.com1_text,",
		"cashreceipt.cust_code,",
		"customer.name_text,",
		"cashreceipt.cash_date,",
		"cashreceipt.year_num,",
		"cashreceipt.period_num,",
		"cashreceipt.cash_amt,",
		"cashreceipt.applied_amt,",
		"cashreceipt.posted_flag",
		" FROM cashreceipt, outer customer ", 
		"WHERE cashreceipt.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ",
		"AND cashreceipt.cust_code = customer.cust_code ", 
		trim(l_module_where_text), " ",
		"AND ",l_where_text clipped," ", 
		"AND (cash_amt >= 0 OR job_code IS NULL) ", 
		"AND ( posted_flag = 'N' OR disc_amt = 0 ) ", 
		"ORDER BY cash_num " 

	PREPARE s_cashreceipt FROM l_query_text 
	DECLARE c_A39_cashreceipt CURSOR FOR s_cashreceipt 

	LET l_idx = 0 
	FOREACH c_A39_cashreceipt INTO l_rec_s_cashreceipt.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_s_cashreceipt[l_idx].cash_num = l_rec_s_cashreceipt.cash_num 
		LET l_arr_rec_s_cashreceipt[l_idx].cust_code = l_rec_s_cashreceipt.cust_code 
		LET l_arr_rec_s_cashreceipt[l_idx].cust_name_text = l_rec_s_cashreceipt.cust_name_text
		LET l_arr_rec_s_cashreceipt[l_idx].cash_date = l_rec_s_cashreceipt.cash_date 
		LET l_arr_rec_s_cashreceipt[l_idx].year_num = l_rec_s_cashreceipt.year_num 
		LET l_arr_rec_s_cashreceipt[l_idx].period_num = l_rec_s_cashreceipt.period_num 
		LET l_arr_rec_s_cashreceipt[l_idx].cash_amt = l_rec_s_cashreceipt.cash_amt 
		LET l_arr_rec_s_cashreceipt[l_idx].applied_amt = l_rec_s_cashreceipt.applied_amt 
		LET l_arr_rec_s_cashreceipt[l_idx].posted_flag = l_rec_s_cashreceipt.posted_flag 
	END FOREACH 
	
--	IF l_idx = 0 THEN 
--		ERROR kandoomsg2("A",9135,"") 	#9135 No cashreceipts satisfied the selection criteria
--		LET l_idx = 1 
--		LET l_arr_rec_s_cashreceipt[1].cash_num = "" 
--		LET l_arr_rec_s_cashreceipt[1].cash_date = "" 
--		LET l_arr_rec_s_cashreceipt[1].cash_amt = "" 
--		LET l_arr_rec_s_cashreceipt[1].applied_amt = "" 
--		LET l_arr_rec_s_cashreceipt[1].year_num = "" 
--		LET l_arr_rec_s_cashreceipt[1].period_num = "" 
--	END IF 
	LET l_msg = trim(l_arr_rec_s_cashreceipt.getSize()), " cashreceipts selected"
	MESSAGE l_msg
	RETURN l_arr_rec_s_cashreceipt 
 
END FUNCTION 
################################################################
# END FUNCTION A39_db_cashreceipt_get_datasource(p_filter,p_query_module_id)
################################################################
