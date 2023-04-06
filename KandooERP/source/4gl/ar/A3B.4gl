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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A3_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A3B_GLOBALS.4gl" 

###############################################################
# MAIN
#
# A3B scans the cash receipts FOR receipts NOT fully applied
###############################################################
MAIN 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A3B") 
	CALL ui_init(0) 	#Initial UI Init 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A183 with FORM "A183" 
	CALL windecoration_a("A183") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_receipt() 
		IF promptTF("Bulk apply",kandoomsg2("A",8028,""),1) THEN
			CALL process_bulk_apply() 
		END IF 
	END WHILE 

	CLOSE WINDOW A183 
END MAIN 
###############################################################
# END MAIN
###############################################################


###############################################################
# FUNCTION select_receipt()
#
#
###############################################################
FUNCTION select_receipt() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 

	CLEAR FORM 
	MESSAGE kandoomsg2("A",1001,"") 	#1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		cashreceipt.cust_code, 
		name_text, 
		addr1_text, 
		addr2_text, 
		city_text, 
		state_code, 
		post_code, 
		type_code, 
		term_code, 
		cred_limit_amt, 
		territory_code, 
		sale_code, 
		bank_code, 
		cash_num, 
		cash_date, 
		year_num, 
		period_num, 
		cash_type_ind, 
		cash_amt, 
		order_num, 
		locn_code, 
		com1_text, 
		com2_text, 
		entry_code, 
		entry_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A3B","construct-cashreceipt") 

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
		MESSAGE kandoomsg2("A",1002,"")	#1002 Seraching database - please wait
		## SELECT unapplied receipts AND omit the neg've receipts
		## associated with a dishonoured cheque.
		LET l_query_text = "SELECT cashreceipt.* FROM cashreceipt,customer ", 
		"WHERE cashreceipt.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cust_code = cashreceipt.cust_code ", 
		"AND cash_amt != applied_amt ", 
		"AND cash_amt > 0 ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cust_code,", ### TO avoid huge sort 
		"cash_date,", 
		"cash_num" 
		PREPARE s_cashreceipt FROM l_query_text 
		DECLARE c_cashreceipt CURSOR with HOLD FOR s_cashreceipt 
		RETURN true 
	END IF 
END FUNCTION 
###############################################################
# END FUNCTION select_receipt()
###############################################################


###############################################################
# FUNCTION process_bulk_apply()
#
#
###############################################################
FUNCTION process_bulk_apply() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_cash_cnt SMALLINT 

--	OPEN WINDOW w1 with FORM "U999" 
--	CALL windecoration_u("U999") 

	LET l_cash_cnt = 0 
--	DISPLAY " Customer:" at 1,1 
--	DISPLAY " Receipt:" at 2,1 

	CALL fgl_winmessage("progress ?","what about a simple \"in progress\" bar","info") 
	FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
		CALL auto_cash_apply(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rec_cashreceipt.cash_num,"1=1") 
		--DISPLAY l_rec_cashreceipt.cust_code at 1,13 
		--DISPLAY l_rec_cashreceipt.cash_num at 2,13 

		LET l_cash_cnt = l_cash_cnt + 1 
	END FOREACH 

--	CLOSE WINDOW w1 

	IF l_cash_cnt = 0 THEN 
		ERROR kandoomsg2("A",9135,"") 	#9135 No cashreceipts satisfied selection criteria
	ELSE 
		ERROR kandoomsg2("A",7080,"") 		#7080 " Bulk Receipt Application Completed "
	END IF
	 
END FUNCTION 
###############################################################
# END FUNCTION process_bulk_apply()
###############################################################