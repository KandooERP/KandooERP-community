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
# common/crhdwind.4gl
# common/cashwind.4gl
# common/inhdwind.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A1B_GLOBALS.4gl" 

###########################################################################
# FUNCTION A1B_main()
#
# A1B - Customer Ledger Scan
#               Allows the user TO scan customer activity in either
#               transaction date OR entry sequence. Allows drill down
#               TO source transactions.
#
# Accepts (2) Arguments (both optional)
#
#    1.  ORDER BY Clause - (D) Date - (S) Entry Sequence(default)
#    2.  Customer Code
#
# This program called FROM main customer inquiry (A12) WHEN user SELECT
# ledger option FROM Detail window.
#
###########################################################################
FUNCTION A1B_main() 
	DEFINE l_cust_code LIKE customer.cust_code
	DEFINE p_arg_cust_code LIKE customer.cust_code
	DEFINE p_arg_order CHAR

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A1B") 

	OPEN WINDOW A113 with FORM "A113" 
	CALL windecoration_a("A113") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	LET p_arg_cust_code = get_url_cust_code()
	LET p_arg_order = get_url_order() 

	IF (p_arg_cust_code IS NOT null) AND (p_arg_order IS NOT null) THEN #order=s CUSTOMER_CODE=",trim(p_cust_code)
		CALL scan_araudit(p_arg_cust_code)
	ELSE 
	
		WHILE TRUE
			CALL select_cust() RETURNING l_cust_code 
			IF l_cust_code IS NULL THEN
				EXIT WHILE
			END IF
			CALL scan_araudit(l_cust_code) 
		END WHILE
		 
	END IF 
	
	CLOSE WINDOW A113
	 
END FUNCTION
###########################################################################
# END FUNCTION A1B_main()
###########################################################################


#################################################################
# FUNCTION select_cust()
#
#
#################################################################
FUNCTION select_cust() 
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_customer RECORD LIKE customer.*

	CLEAR FORM 

	IF get_url_cust_code() IS NOT NULL THEN 
		LET l_rec_araudit.cust_code = get_url_cust_code()
		CALL db_customer_get_rec(UI_OFF,l_rec_araudit.cust_code) RETURNING l_rec_customer.*  

		IF l_rec_customer.cust_code IS NULL THEN
			LET l_rec_araudit.cust_code = NULL 
		END IF 
	END IF 

	IF l_rec_araudit.cust_code IS NULL THEN 
		MESSAGE kandoomsg2("A",1068,"") 

		INPUT BY NAME l_rec_araudit.cust_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A1B","inp-araudit") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" #ON KEY (control-b) 
				LET l_rec_araudit.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
				NEXT FIELD cust_code 

			ON CHANGE cust_code
				DISPLAY db_customer_get_name_text(UI_OFF,l_rec_araudit.cust_code) TO customer.name_text		
				DISPLAY db_customer_get_currency_code(UI_OFF,l_rec_araudit.cust_code) TO customer.currency_code

			AFTER FIELD cust_code 
				CALL db_customer_get_rec(UI_OFF,l_rec_araudit.cust_code) RETURNING l_rec_customer.* 
--				SELECT * INTO l_rec_customer.* 
--				FROM customer 
--				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--				AND cust_code = l_rec_araudit.cust_code 
--				IF status = NOTFOUND THEN
				IF l_rec_customer.cust_code IS NULL THEN
					ERROR kandoomsg2("U",9105,"") 
					NEXT FIELD cust_code 
				END IF 

		END INPUT 

	END IF 

	DISPLAY BY NAME l_rec_customer.cust_code, l_rec_customer.name_text
	DISPLAY BY NAME l_rec_customer.currency_code 	#HuHo: attribute(GREEN) #why with color / green ? I'll remove it

	IF not(int_flag OR quit_flag) THEN 
		MESSAGE kandoomsg2("U",1001,"")
		RETURN l_rec_araudit.cust_code
	ELSE
		RETURN NULL
	END IF
	
END FUNCTION
#################################################################
# END FUNCTION select_cust()
#################################################################


#################################################################
# FUNCTION db_araudit_get_datasource(p_filter)
#
#
#################################################################
FUNCTION db_araudit_get_datasource(p_filter,p_cust_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_arr_rec_araudit DYNAMIC ARRAY OF RECORD 
		tran_date LIKE araudit.tran_date, 
		seq_num LIKE araudit.seq_num, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		tran_amt LIKE araudit.tran_amt, 
		bal_amt LIKE araudit.bal_amt 
	END RECORD
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN
			
		CONSTRUCT BY NAME l_where_text ON 
			tran_date, 
			seq_num, 
			tran_type_ind, 
			source_num, 
			tran_text, 
			tran_amt, 
			bal_amt 


			BEFORE CONSTRUCT 
				LET l_rec_araudit.tran_date = today - 120 
				LET l_query_text = ">=",l_rec_araudit.tran_date USING "ddmmyy" 
				DISPLAY l_query_text TO tran_date 

				CALL publish_toolbar("kandoo","A1B","construct-araudit") 

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
	
		MESSAGE kandoomsg2("U",1002,"") 
		LET l_query_text = 
			"SELECT * FROM araudit ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code CLIPPED,"' ", 
			"AND cust_code = '",p_cust_code CLIPPED,"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY cust_code" 

		IF get_url_order() = "D" THEN 
			LET l_query_text = l_query_text clipped,",tran_date,seq_num" 
		ELSE 
			LET l_query_text = l_query_text clipped,",seq_num" --can also be order="S" 
		END IF 

		PREPARE s_araudit FROM l_query_text 
		DECLARE c_araudit CURSOR FOR s_araudit 


	LET l_idx = 0 
	FOREACH c_araudit INTO l_rec_araudit.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_araudit[l_idx].tran_date = l_rec_araudit.tran_date 
		LET l_arr_rec_araudit[l_idx].seq_num = l_rec_araudit.seq_num 
		LET l_arr_rec_araudit[l_idx].tran_type_ind = l_rec_araudit.tran_type_ind 
		LET l_arr_rec_araudit[l_idx].source_num = l_rec_araudit.source_num 
		LET l_arr_rec_araudit[l_idx].tran_text = l_rec_araudit.tran_text 
		LET l_arr_rec_araudit[l_idx].tran_amt = l_rec_araudit.tran_amt 
		LET l_arr_rec_araudit[l_idx].bal_amt = l_rec_araudit.bal_amt

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx) 	#U9113 l_idx records selected

	RETURN l_arr_rec_araudit
END FUNCTION 
#################################################################
# END FUNCTION db_araudit_get_datasource(p_filter)
#################################################################


#################################################################
# FUNCTION scan_araudit()
#
#
#################################################################
FUNCTION scan_araudit(p_cust_code)
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_arr_rec_araudit DYNAMIC ARRAY OF RECORD --array[500] OF RECORD 
		tran_date LIKE araudit.tran_date, 
		seq_num LIKE araudit.seq_num, 
		tran_type_ind LIKE araudit.tran_type_ind, 
		source_num LIKE araudit.source_num, 
		tran_text LIKE araudit.tran_text, 
		tran_amt LIKE araudit.tran_amt, 
		bal_amt LIKE araudit.bal_amt 
	END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_customer RECORD LIKE customer.*

	#Display a few customer details in the form
	CALL db_customer_get_rec(UI_ON,p_cust_code) RETURNING l_rec_customer.*  
	DISPLAY l_rec_customer.cust_code TO araudit.cust_code
	DISPLAY l_rec_customer.name_text TO customer.name_text
	DISPLAY l_rec_customer.currency_code TO customer.currency_code
	
	CALL db_araudit_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_araudit

	MESSAGE kandoomsg2("U",1007,"") 
	DISPLAY ARRAY l_arr_rec_araudit TO sr_araudit.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A1B","display-arr-araudit") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("View",NOT l_arr_rec_araudit.getSize())		

		BEFORE ROW
			LET l_idx = arr_curr() 		
			#in caes we need to do more, populate l_rec_araudit here based on the current row
					
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_araudit.clear()
			CALL db_araudit_get_datasource(TRUE,p_cust_code) RETURNING l_arr_rec_araudit
			CALL dialog.setActionHidden("View",NOT l_arr_rec_araudit.getSize())	
			
		ON ACTION "REFRESH"
			CALL windecoration_a("A113")
			CALL l_arr_rec_araudit.clear()
			CALL db_araudit_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_araudit
			CALL dialog.setActionHidden("View",NOT l_arr_rec_araudit.getSize())	

		ON ACTION ("View","ACCEPT","DOUBLECLICK") --duplicate OF ON KEY (tab) 
			LET l_idx = arr_curr() 

			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
				CALL disc_per_head(glob_rec_kandoouser.cmpy_code,p_cust_code,	l_arr_rec_araudit[l_idx].source_num) 
			END IF 

			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
				CALL cash_disp(glob_rec_kandoouser.cmpy_code,p_cust_code, l_arr_rec_araudit[l_idx].source_num) 
			END IF 

			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_CREDIT_CR THEN 
				CALL cr_disp_head(glob_rec_kandoouser.cmpy_code,p_cust_code, l_arr_rec_araudit[l_idx].source_num) 
			END IF 

			CALL l_arr_rec_araudit.clear()
			CALL db_araudit_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_araudit
{
		ON KEY (tab) 
			LET l_idx = arr_curr() 
			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_INVOICE_IN THEN 
				CALL disc_per_head(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code, 
				l_arr_rec_araudit[l_idx].source_num) 
			END IF 
			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
				CALL cash_disp(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code, 
				l_arr_rec_araudit[l_idx].source_num) 
			END IF 
			IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_CREDIT_CR THEN 
				CALL cr_disp_head(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code, 
				l_arr_rec_araudit[l_idx].source_num) 
			END IF 

			CALL l_arr_rec_araudit.clear()
			CALL db_araudit_get_datasource(FALSE,p_cust_code) RETURNING l_arr_rec_araudit
}
			{      ON KEY(RETURN)  --huho IS this really required.. let's comment it for now
			         LET l_idx = arr_curr()
			         IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_INVOICE_IN THEN
			            CALL disc_per_head(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code,
			                                    l_arr_rec_araudit[l_idx].source_num)
			         END IF
			         IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_RECEIPT_CA THEN
			            CALL cash_disp(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code,
			                                l_arr_rec_araudit[l_idx].source_num)
			         END IF
			         IF l_arr_rec_araudit[l_idx].tran_type_ind = TRAN_TYPE_CREDIT_CR THEN
			            CALL cr_disp_head(glob_rec_kandoouser.cmpy_code,l_rec_araudit.cust_code,
			                                   l_arr_rec_araudit[l_idx].source_num)
			         END IF
			}

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION
#################################################################
# END FUNCTION scan_araudit()
#################################################################