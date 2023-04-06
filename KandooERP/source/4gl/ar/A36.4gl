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
# common/cashwind.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A36_GLOBALS.4gl" 
################################################################
# FUNCTION A36_main()
#
# A36 allows the user TO Scan Cash Receipts
################################################################
FUNCTION A36_main() 
	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A36") 
	
	OPEN WINDOW A149 with FORM "A149" 
	CALL windecoration_a("A149") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_cashreceipt() 

	CLOSE WINDOW A149 
END FUNCTION 
################################################################
# END FUNCTION A36_main()
################################################################



################################################################
# FUNCTION scan_cashreceipt()
#
#
################################################################
FUNCTION scan_cashreceipt() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_t_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF A30_glob_dt_rec_receipt		
--	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF RECORD --array[320] OF RECORD 
--		cash_num LIKE cashreceipt.cash_num, 
--		cheque_text LIKE cashreceipt.cheque_text, 
--		cash_date LIKE cashreceipt.cash_date, 
--		year_num LIKE cashreceipt.year_num, 
--		period_num LIKE cashreceipt.period_num, 
--		cash_amt LIKE cashreceipt.cash_amt, 
--		applied_amt LIKE cashreceipt.applied_amt, 
--		posted_flag LIKE cashreceipt.posted_flag 
--	END RECORD
	DEFINE l_idx SMALLINT --, scrn 
	DEFINE l_query STRING
	

{	
	CLEAR FORM 
	MESSAGE kandoomsg2("U",1020,"Cash Receipt") #1020 Enter Cash Receipt Details; OK TO Continue
	INPUT l_rec_t_cashreceipt.cust_code, l_rec_t_cashreceipt.cash_num FROM cust_code, cash_num ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A36","inp-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
			LET l_rec_t_cashreceipt.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME l_rec_t_cashreceipt.cust_code 
			NEXT FIELD cust_code 

		ON CHANGE cust_code #cust_code is required !	
			CALL db_customer_get_rec(UI_OFF,l_rec_t_cashreceipt.cust_code) RETURNING l_rec_customer.*
			IF l_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("U",9105,"") #9105 RECORD NOT found; Try window.
				--NEXT FIELD cust_code
			ELSE
				DISPLAY  l_rec_customer.name_text TO name_text
			END IF 
			DISPLAY db_customer_get_name_text(UI_OFF,l_rec_t_cashreceipt.cust_code) TO customer.name_text
			DISPLAY db_customer_get_currency_code(UI_OFF,l_rec_t_cashreceipt.cust_code) TO customer.currency_code DISPLAY BY NAME glob_rec_cashreceipt.applied_amt ATTRIBUTE(GREEN) 
			DISPLAY db_currency_get_desc_text(UI_OFF,db_customer_get_currency_code(UI_OFF,l_rec_t_cashreceipt.cust_code)) TO currency.desc_text

		AFTER INPUT
			IF NOT int_flag THEN
				IF l_rec_t_cashreceipt.cust_code IS NULL THEN
				ERROR "Customer Code must be specified"
				NEXT FIELD cust_code
			END IF
		END IF
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	DISPLAY BY NAME l_rec_customer.name_text 

	DISPLAY BY NAME l_rec_customer.currency_code DISPLAY BY NAME glob_rec_cashreceipt.applied_amt ATTRIBUTE(GREEN) 

	IF l_rec_t_cashreceipt.cash_num IS NULL THEN 
		LET l_rec_t_cashreceipt.cash_num = 0 
	END IF 
#--------------------
	LET l_query = 
	"SELECT * FROM cashreceipt ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "' "

	IF  l_rec_t_cashreceipt.cust_code IS NOT NULL THEN	 
		LET l_query = l_query CLIPPED, " AND cust_code = '", l_rec_t_cashreceipt.cust_code CLIPPED, "'"
	END IF
	
	IF  l_rec_t_cashreceipt.cash_num != 0 THEN
		LET l_query = l_query CLIPPED, " AND cash_num >= ", l_rec_t_cashreceipt.cash_num CLIPPED
	END IF 
	
	LET l_query = l_query CLIPPED, " ORDER BY cash_num" 
	
	PREPARE s_cash FROM l_query
	DECLARE c_cash CURSOR FOR s_cash

	LET l_idx = 0 
	FOREACH c_cash INTO l_rec_cashreceipt.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_s_cashreceipt[l_idx].cash_num = l_rec_cashreceipt.cash_num 
		LET l_arr_rec_s_cashreceipt[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
		LET l_arr_rec_s_cashreceipt[l_idx].cash_date = l_rec_cashreceipt.cash_date 
		LET l_arr_rec_s_cashreceipt[l_idx].year_num = l_rec_cashreceipt.year_num 
		LET l_arr_rec_s_cashreceipt[l_idx].period_num = l_rec_cashreceipt.period_num 
		LET l_arr_rec_s_cashreceipt[l_idx].cash_amt = l_rec_cashreceipt.cash_amt 
		LET l_arr_rec_s_cashreceipt[l_idx].applied_amt = l_rec_cashreceipt.applied_amt 
		LET l_arr_rec_s_cashreceipt[l_idx].posted_flag = l_rec_cashreceipt.posted_flag 
	END FOREACH 
}
--	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected


	CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*
	# DISPLAY ARRAY -----------------------------------------------------
	MESSAGE kandoomsg2("I",1300,"")	#1300 ENTER TO view details
	DISPLAY ARRAY l_arr_rec_s_cashreceipt TO sr_cashreceipt.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A36","inp-arr-cashreceipt") 
 			CALL dialog.setActionHidden("ACCEPT",TRUE)
 			CALL dialog.setActionHidden("VIEW",l_arr_rec_s_cashreceipt.getSize())
 			CALL dialog.setActionHidden("CASH DISP",l_arr_rec_s_cashreceipt.getSize())
 			 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_s_cashreceipt.clear()
			INITIALIZE l_rec_t_cashreceipt.* TO NULL
			CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*

		ON ACTION "REFRESH"
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_cashreceipt.cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num 
			LET l_rec_cashreceipt.com1_text = l_arr_rec_s_cashreceipt[l_idx].com1_text			
			LET l_rec_cashreceipt.cheque_text = l_arr_rec_s_cashreceipt[l_idx].cheque_text 
			LET l_rec_cashreceipt.cash_date = l_arr_rec_s_cashreceipt[l_idx].cash_date 
			LET l_rec_cashreceipt.year_num = l_arr_rec_s_cashreceipt[l_idx].year_num 
			LET l_rec_cashreceipt.period_num = l_arr_rec_s_cashreceipt[l_idx].period_num 
			LET l_rec_cashreceipt.cash_amt = l_arr_rec_s_cashreceipt[l_idx].cash_amt 
			LET l_rec_cashreceipt.applied_amt = l_arr_rec_s_cashreceipt[l_idx].applied_amt 
			LET l_rec_cashreceipt.posted_flag = l_arr_rec_s_cashreceipt[l_idx].posted_flag 

--		ON ACTION "CASH DISP"
--			IF l_idx > 0 THEN 
--				CALL cash_disp(
--					glob_rec_kandoouser.cmpy_code, 
--					l_rec_t_cashreceipt.cust_code, 
--					l_arr_rec_s_cashreceipt[l_idx].cash_num) 
--			END IF
--			CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*
						
		ON ACTION ("ACCEPT","VIEW","DOUBLECLICK")
			IF l_idx > 0 THEN
				CALL cash_disp(
					glob_rec_kandoouser.cmpy_code, 
					l_rec_t_cashreceipt.cust_code,			 
					l_arr_rec_s_cashreceipt[l_idx].cash_num) #NOTE: this value is taken from the INPUT (pseudo construct) 
				CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*
			END IF
	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 
	RETURN TRUE 

END FUNCTION 
################################################################
# END FUNCTION scan_cashreceipt()
################################################################