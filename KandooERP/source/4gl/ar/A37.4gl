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
GLOBALS "../ar/A37_GLOBALS.4gl" 

###################################################################
# FUNCTION A37_main()
#
# A37 allows the user TO Scan Cash Receipts THEN edit as required
###################################################################
FUNCTION A37_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A37") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	IF get_url_cashreceipt_number() IS NOT NULL THEN 
		CALL cashreceipt_edit(glob_rec_kandoouser.cmpy_code, get_url_cashreceipt_number(), glob_rec_kandoouser.sign_on_code) 
	ELSE 

		OPEN WINDOW A149 with FORM "A149" 
		CALL windecoration_a("A149") 
		CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

		CALL A37_enter_receipt() 
 
		CLOSE WINDOW A149 
	END IF 
END FUNCTION
###################################################################
# END FUNCTION A37_main()
#
# A37 allows the user TO Scan Cash Receipts THEN edit as required
###################################################################


###################################################################
# FUNCTION A37_enter_receipt()
#
#
###################################################################
FUNCTION A37_enter_receipt() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_t_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF A30_glob_dt_rec_receipt	
--	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF RECORD 
--		cash_num LIKE cashreceipt.cash_num, 
--		cheque_text LIKE cashreceipt.cheque_text, 
--		cash_date LIKE cashreceipt.cash_date, 
--		year_num LIKE cashreceipt.year_num, 
--		period_num LIKE cashreceipt.period_num, 
--		cash_amt LIKE cashreceipt.cash_amt, 
--		applied_amt LIKE cashreceipt.applied_amt, 
--		posted_flag LIKE cashreceipt.posted_flag 
--	END RECORD
	DEFINE l_idx SMALLINT 
{
	CLEAR FORM 
	# INPUT -------------------------------------------------------------
	ERROR kandoomsg2("U",1020,"Cash Receipt") #1056 Enter Receipt details
	INPUT BY NAME l_rec_t_cashreceipt.cust_code, l_rec_t_cashreceipt.cash_num ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A37","inp-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (cust_code) 
			LET l_rec_t_cashreceipt.cust_code = show_clnt(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME l_rec_t_cashreceipt.cust_code 
			NEXT FIELD cust_code 

		ON CHANGE cust_code
			CALL db_customer_get_rec(UI_OFF,l_rec_t_cashreceipt.cust_code) RETURNING l_rec_customer.*

			IF l_rec_customer.cust_code IS NULL THEN 
				ERROR kandoomsg2("A",9009,"") #9009 Customer code NOT found, try window"
				NEXT FIELD cust_code 
			END IF 

			DISPLAY db_customer_get_name_text(UI_OFF,l_rec_t_cashreceipt.cust_code) TO customer.name_text
			DISPLAY db_customer_get_currency_code(UI_OFF,l_rec_t_cashreceipt.cust_code) TO customer.currency_code DISPLAY BY NAME glob_rec_cashreceipt.applied_amt ATTRIBUTE(GREEN) 
			DISPLAY db_currency_get_desc_text(UI_OFF,db_customer_get_currency_code(UI_OFF,l_rec_t_cashreceipt.cust_code)) TO currency.desc_text

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF l_rec_t_cashreceipt.cash_num IS NULL THEN 
		LET l_rec_t_cashreceipt.cash_num = 0 
	END IF 

	DECLARE c_cash CURSOR FOR 
	SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = l_rec_t_cashreceipt.cust_code 
	AND cash_num >= l_rec_t_cashreceipt.cash_num 
	ORDER BY cash_num 

	LET l_idx = 0 
	FOREACH c_cash 
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

	MESSAGE kandoomsg2("U",9113,l_idx) #9113 l_idx records selected
}


	CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*
	
	MESSAGE kandoomsg2("A",1013,"") 	#1013  F3/F4 - RETURN on line TO Edit"
	DISPLAY ARRAY l_arr_rec_s_cashreceipt TO sr_cashreceipt.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A37","inp-arr-cashreceipt") 
 			CALL dialog.setActionHidden("ACCEPT",TRUE)
 			CALL dialog.setActionHidden("VIEW",l_arr_rec_s_cashreceipt.getSize())
 			CALL dialog.setActionHidden("CASH DISP",l_arr_rec_s_cashreceipt.getSize())
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_s_cashreceipt.getSize())
  		CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_s_cashreceipt.getSize())
		BEFORE ROW 
			LET l_idx = arr_curr() 

 			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_s_cashreceipt.clear()
			INITIALIZE l_rec_t_cashreceipt.* TO NULL
			CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*

		ON ACTION "REFRESH"
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*


--		BEFORE ROW 
--			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			#DISPLAY l_arr_rec_s_cashreceipt[l_idx].* TO sr_cashreceipt[scrn].*

			#      AFTER FIELD cash_num
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#             ERROR kandoomsg2("U",9001,"")			#             #9001 There no more rows...
			#             NEXT FIELD cash_num
			#         END IF
			#
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_s_cashreceipt[l_idx+1].cash_num IS NULL THEN
			#              ERROR kandoomsg2("U",9001,"")		#              #9001 There no more rows...
			#              NEXT FIELD cash_num
			#            END IF
			#         END IF
			#
			#         IF fgl_lastkey() = fgl_keyval("nextpage")
			#         AND (l_arr_rec_s_cashreceipt[l_idx+12].cash_num IS NULL
			#          OR l_arr_rec_s_cashreceipt[l_idx+12].cash_num = 0) THEN
			#            ERROR kandoomsg2("U",9001,"")            #9001 No more rows in this direction
			#            NEXT FIELD cash_num
			#         END IF

		ON ACTION ("ACCEPT","DOUBLECLICK","EDIT") 
			IF l_idx > 0 THEN #not on empty arrays

				#BEFORE FIELD cheque_text
				IF l_arr_rec_s_cashreceipt[l_idx].cash_num IS NOT NULL AND l_arr_rec_s_cashreceipt[l_idx].cash_num > 0 THEN 
					CALL cashreceipt_edit(glob_rec_kandoouser.cmpy_code, l_arr_rec_s_cashreceipt[l_idx].cash_num, glob_rec_kandoouser.sign_on_code) 
					
					SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num 

					LET l_arr_rec_s_cashreceipt[l_idx].cash_num = l_rec_cashreceipt.cash_num					
					LET l_arr_rec_s_cashreceipt[l_idx].com1_text = l_rec_cashreceipt.com1_text					
					LET l_arr_rec_s_cashreceipt[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
					LET l_arr_rec_s_cashreceipt[l_idx].cash_date = l_rec_cashreceipt.cash_date 
					LET l_arr_rec_s_cashreceipt[l_idx].year_num = l_rec_cashreceipt.year_num 
					LET l_arr_rec_s_cashreceipt[l_idx].period_num = l_rec_cashreceipt.period_num 
					LET l_arr_rec_s_cashreceipt[l_idx].cash_amt = l_rec_cashreceipt.cash_amt 
					LET l_arr_rec_s_cashreceipt[l_idx].applied_amt = l_rec_cashreceipt.applied_amt 
					LET l_arr_rec_s_cashreceipt[l_idx].posted_flag = l_rec_cashreceipt.posted_flag
					#DISPLAY l_arr_rec_s_cashreceipt[l_idx].* TO sr_cashreceipt[scrn].*
					
					CALL l_arr_rec_s_cashreceipt.clear()
					CALL db_cashreceipt_get_datasource(l_rec_t_cashreceipt.*) RETURNING l_arr_rec_s_cashreceipt, l_rec_t_cashreceipt.*
				END IF 
				#NEXT FIELD cash_num
			END IF
			
	END DISPLAY
	# END DISPLAY --------------------------------------------------------------- 

	LET int_flag = false 
	LET quit_flag = false 

	RETURN true 
END FUNCTION 
###################################################################
# END FUNCTION A37_enter_receipt()
###################################################################