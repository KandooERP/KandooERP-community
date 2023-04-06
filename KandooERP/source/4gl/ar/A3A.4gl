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
# \brief module A3A scans the cash receipts FOR receipts NOT fully applied
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A3A_GLOBALS.4gl" 

###########################################################################
# FUNCTION A3A_main()
#
#
###########################################################################
FUNCTION A3A_main()

	DEFER quit 
	DEFER interrupt 


	CALL setModuleId("A3A") 
	
	OPEN WINDOW A150 with FORM "A150" 
	CALL windecoration_a("A150") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL receipt_browser() 

	CLOSE WINDOW A150 
END FUNCTION
###########################################################################
# END FUNCTION A3A_main()
###########################################################################




########################################################################
# FUNCTION receipt_browser()
#
#
########################################################################
FUNCTION receipt_browser() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF A39_glob_dt_rec_receipt	 
--	DEFINE l_arr_rec_s_cashreceipt DYNAMIC ARRAY OF RECORD  
--		scroll_flag CHAR(1), 
--		cash_num LIKE cashreceipt.cash_num, 
--		cust_code LIKE cashreceipt.cust_code , 
--		cash_date LIKE cashreceipt.cash_date, 
--		year_num LIKE cashreceipt.year_num, 
--		period_num LIKE cashreceipt.period_num, 
--		cash_amt LIKE cashreceipt.cash_amt, 
--		applied_amt LIKE cashreceipt.applied_amt, 
--		posted_flag LIKE cashreceipt.posted_flag 
--	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_msg STRING
 
 	CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt
 

	MESSAGE kandoomsg2("A",1029,"") #1029 RETURN on line TO apply cash receipt"
	DISPLAY ARRAY l_arr_rec_s_cashreceipt TO sr_cashreceipt.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A3A","inp-arr-cashreceipt-1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

			IF (l_arr_rec_s_cashreceipt[l_idx].cash_amt > 0)
			AND (l_arr_rec_s_cashreceipt[l_idx].cash_amt != l_arr_rec_s_cashreceipt[l_idx].applied_amt) THEN
				CALL dialog.setActionHidden("AUTO APPLY",FALSE)
				CALL dialog.setActionHidden("MANUAL APPLY",FALSE)
			ELSE
				CALL dialog.setActionHidden("AUTO APPLY",TRUE)
				CALL dialog.setActionHidden("MANUAL APPLY",TRUE)
			END IF 
			
--			LET l_arr_rec_s_cashreceipt[l_idx].scroll_flag = "*" #Set Row Select Marker 			

		AFTER ROW
			#nothing
--			LET l_arr_rec_s_cashreceipt[l_idx].scroll_flag = NULL #Remove Row Select Marker 			

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar()
			 
		ON ACTION "FILTER"
			CALL windecoration_a("A150")
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL A39_db_cashreceipt_get_datasource(TRUE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt			

		ON ACTION "REFRESH"
			CALL l_arr_rec_s_cashreceipt.clear()
			CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt			

		ON ACTION "CUSTOMER" #customer apply invoice submenu --customer details
		--ON KEY (F5) --customer apply invoice submenu --customer details 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,l_arr_rec_s_cashreceipt[l_idx].cust_code)--customer details 

		ON ACTION "AUTO APPLY" #auto apply
		--ON KEY (F9) --auto apply 
			#step 1
			IF l_arr_rec_s_cashreceipt[l_idx].cash_amt < 0 THEN 
				CALL fgl_winmessage(""," Negative cash receipts must be manually applied","info") 
				#NEXT FIELD scroll_flag
			ELSE 
				
				#step 2: AUTO APPLY
				CALL auto_cash_apply(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_arr_rec_s_cashreceipt[l_idx].cash_num,"1=1") 
	
				SELECT applied_amt INTO l_arr_rec_s_cashreceipt[l_idx].applied_amt 
				FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num
				
				#Why is this condition not at the beginning ??? 
				IF l_arr_rec_s_cashreceipt[l_idx].cash_amt != l_arr_rec_s_cashreceipt[l_idx].applied_amt THEN 
					LET l_msg = "Receipt ", trim(l_arr_rec_s_cashreceipt[l_idx].cash_num), "\n", kandoomsg2("A",7041,l_arr_rec_s_cashreceipt[l_idx].cash_num) 
					--MESSAGE kandoomsg2("A",7041,l_arr_rec_s_cashreceipt[l_idx].cash_num) 				#7041 Partial application successful
					MESSAGE l_msg
				ELSE
					LET l_msg = "Receipt ", trim(l_arr_rec_s_cashreceipt[l_idx].cash_num), " for ", trim(l_arr_rec_s_cashreceipt[l_idx].cash_amt) , " applied succesfully !"
					CALL fgl_winmessage("Receipt Applied",l_msg, "INFO")
					--CALL fgl_winmessage("Already Applied","This receipt has already been applied or is not possible to apply","warning")
				END IF 
	
				CALL l_arr_rec_s_cashreceipt.clear()
				CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt	
			END IF
			
		ON ACTION ("ACCEPT","DOUBLECLICK","MANUAL APPLY") 
			#BEFORE FIELD cash_num
			#step 1
			IF l_arr_rec_s_cashreceipt[l_idx].applied_amt !=l_arr_rec_s_cashreceipt[l_idx].cash_amt THEN 
				SELECT * INTO l_rec_cashreceipt.* 
				FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num
				 
				IF l_rec_cashreceipt.job_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",7053,l_rec_cashreceipt.cash_num) 		#7053 cheques IS dishonoured - apply will NOT effect invoices
				END IF 
				
				#step 2: MANUAL APPLY
				CALL app_cash(glob_rec_kandoouser.cmpy_code,l_arr_rec_s_cashreceipt[l_idx].cash_num,glob_rec_kandoouser.sign_on_code)
				 
				SELECT applied_amt INTO l_arr_rec_s_cashreceipt[l_idx].applied_amt 
				FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_arr_rec_s_cashreceipt[l_idx].cust_code 
				AND cash_num = l_arr_rec_s_cashreceipt[l_idx].cash_num
			ELSE
				CALL fgl_winmessage("Already Applied","This receipt has already been applied or is not possible to apply","warning") 
			END IF 

			CALL l_arr_rec_s_cashreceipt.clear()
			CALL A39_db_cashreceipt_get_datasource(FALSE,get_module_id()) RETURNING l_arr_rec_s_cashreceipt	

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION
########################################################################
# END FUNCTION receipt_browser()
########################################################################