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
GLOBALS "../ar/A39_GLOBALS.4gl" 

################################################################
# FUNCTION A39_main()
#
# \brief module A39 - Cash Receipt Unapply
# \brief module provides a scan SCREEN of applied receipts
#                    allowing user TO SELECT a receipts FOR unapplying
################################################################
FUNCTION A39_main() 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A39") 

	OPEN WINDOW A150 with FORM "A150" 
	CALL windecoration_a("A150") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL receipt_browser() 

	CLOSE WINDOW A150
	 
END FUNCTION 
################################################################
# END FUNCTION A39_main()
################################################################



################################################################
# FUNCTION receipt_browser()
#
#
################################################################
FUNCTION receipt_browser() 
	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF A39_glob_dt_rec_receipt
	DEFINE l_rec_cashreceipt OF A39_glob_dt_rec_receipt
	DEFINE l_idx SMALLINT 

	CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt

	# DISPLAY ARRAY --------------------------------
	MESSAGE kandoomsg2("A",1027,"") #1027 RETURN on line TO unapply cash receipt"
	DISPLAY ARRAY l_arr_rec_s_cashreceipt TO sr_cashreceipt.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A39","inp-arr-cashreceipt-1")
			CALL dialog.setActionHidden("ACCEPT",TRUE) 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_s_cashreceipt.getSize())

		ON ACTION "FILTER"
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL A39_db_cashreceipt_get_datasource(TRUE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt		

		ON ACTION "REFRESH"
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt		

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("UNDO RECEIPT APPLY","DOUBLECLICK") 	#BEFORE FIELD cash_num
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_s_cashreceipt.getSize()) THEN
				IF l_arr_rec_s_cashreceipt[l_idx].applied_amt != 0 THEN 
					IF kandoomsg("A",8025,l_arr_rec_s_cashreceipt[l_idx].cash_num) = "Y" THEN #8020 Confirm TO unappply receipt ???					
						MESSAGE kandoomsg2("A",1002,"") 				#1002 Searching database please wait
						CALL unapp_cash(
							glob_rec_kandoouser.cmpy_code,
							l_arr_rec_s_cashreceipt[l_idx].cust_code,	
							l_arr_rec_s_cashreceipt[l_idx].cash_num,
							glob_rec_kandoouser.sign_on_code)
						 
						SELECT applied_amt INTO l_arr_rec_s_cashreceipt[l_idx].applied_amt 
						FROM cashreceipt 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cust_code = l_arr_rec_s_cashreceipt[l_idx].cust_code 
						AND cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num 
						MESSAGE kandoomsg2("A",1027,"") 				#1027 RETURN on line TO unapply cash receipt"
					END IF 
				END IF 

				CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt		

			END IF

	END DISPLAY 
	# END DISPLAY ---------------------------------------------
	
	LET int_flag = false 
	LET quit_flag = false 
	
END FUNCTION 
################################################################
# END FUNCTION receipt_browser()
################################################################