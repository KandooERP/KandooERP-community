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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A6_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A61_GLOBALS.4gl" 

############################################################################
# FUNCTION A61_main
#
# A61 - Bank Deposit Calculator
############################################################################
FUNCTION A61_main() 
	DEFINE l_run_arg STRING 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A61") 

	OPEN WINDOW A174 with FORM "A174" 
	CALL windecoration_a("A174") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Bank Deposit Calculator" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A61","menu-bank-deposit-calc") 
			CALL dialog.setActionHidden("REPORT",TRUE)

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "GENERATE"	#COMMAND "Generate" " Generate the tentative bank deposit"
			IF generate_tentative_deposit() THEN 
				DISPLAY glob_bank_dep_num TO bank_dep_num  
				CALL dialog.setActionHidden("REPORT",FALSE) 
			ELSE 
				LET glob_bank_dep_num = 0 
				CALL dialog.setActionHidden("REPORT",TRUE)
			END IF 

		ON ACTION "REPORT" 		#COMMAND "Report" " Generate REPORT on current bank deposit"
			LET l_run_arg = "BANKDEPARTMENT_NUMBER=", trim(glob_bank_dep_num) 
			CALL run_prog("A62",l_run_arg,"","","") #a62 - trial deposit PRINT 
			NEXT option "Exit" 

		ON ACTION "CANCEL" 		#command  key (interrupt,"E")"Exit" " Exit the Program"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A174 

END FUNCTION
############################################################################
# END FUNCTION A61_main
############################################################################


############################################################################
# FUNCTION generate_tentative_deposit()
#
#
############################################################################
FUNCTION generate_tentative_deposit() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_userlocn RECORD LIKE userlocn.*
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_continue SMALLINT
	DEFINE l_banking_required SMALLINT
	DEFINE l_desc_text STRING
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_msg STRING
	DEFINE l_idx SMALLINT
 
	MESSAGE kandoomsg2("U",1020,"Banking") #1020 Enter Banking Details; OK TO Continue
	CLEAR FORM
	INPUT l_rec_bank.bank_code,l_desc_text WITHOUT DEFAULTS  FROM bank_code,desc_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A61","inp-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING 
				l_rec_bank.bank_code, 
				l_rec_bank.acct_code 
			NEXT FIELD bank_code 

		AFTER FIELD bank_code 
			IF l_rec_bank.bank_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
				NEXT FIELD bank_code 
			END IF 

			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE bank.bank_code = l_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF STATUS = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 			#9105 RECORD Not Found; Try Window
				NEXT FIELD bank_code 
			END IF 
			DISPLAY BY NAME l_rec_bank.name_acct_text 

		AFTER FIELD desc_text 
			IF l_desc_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF int_flag = FALSE AND quit_flag = FALSE THEN 
				IF l_rec_bank.bank_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD bank_code 
				END IF 
				IF l_desc_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD desc_text 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	SELECT * INTO l_rec_userlocn.* FROM userlocn 
	WHERE userlocn.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND userlocn.sign_on_code = glob_rec_kandoouser.sign_on_code 

	MESSAGE kandoomsg2("U",1001,"")	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		entry_date, 
		cash_date, 
		cash_type_ind, 
		cheque_text, 
		drawer_text, 
		order_num, 
		locn_code, 
		entry_code 

		BEFORE CONSTRUCT 
			DISPLAY l_rec_userlocn.locn_code TO locn_code 
			CALL publish_toolbar("kandoo","A61","construct-bank") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 Searching Database; Please Wait

	BEGIN WORK
		LET glob_bank_dep_num = get_deposit_num() 
		IF glob_bank_dep_num = 0 THEN 
			ROLLBACK WORK
			CALL msgerror("","#7005 AR Parameters Not Set Up;\nTable arparms is empty!\nRun Program AZP.")
			RETURN FALSE 
		END IF 

		INITIALIZE l_rec_tentbankhead.* TO NULL 
		
		LET l_rec_tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_tentbankhead.bank_dep_num = glob_bank_dep_num 
		LET l_rec_tentbankhead.bank_code = l_rec_bank.bank_code 
		LET l_rec_tentbankhead.name_acct_text = l_rec_bank.name_acct_text 
		LET l_rec_tentbankhead.desc_text = l_desc_text 
		LET l_rec_tentbankhead.currency_code = l_rec_bank.currency_code 
		LET l_rec_tentbankhead.source_ind = "2" 
		LET l_rec_tentbankhead.tran_date = TODAY
		LET l_rec_tentbankhead.status_ind = "2" 
		LET l_rec_tentbankhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_tentbankhead.entry_date = TODAY 
		LET glob_err_message = "A61 - Insert INTO tentbankhead" 
		# INSERT -----------------------------------------------------
		INSERT INTO tentbankhead VALUES (l_rec_tentbankhead.*)
		 		 
		LET l_query_text = 
			"SELECT * FROM cashreceipt ", 
			"WHERE cashreceipt.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code),"' ", 
			"AND cashreceipt.cash_acct_code = '", trim(l_rec_bank.acct_code),"' ", 
			"AND (cashreceipt.banked_flag = 'N' OR cashreceipt.banked_flag IS NULL) ", 
			"AND (cashreceipt.chq_date <= '",TODAY,"' OR cashreceipt.chq_date IS NULL) ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY cashreceipt.cash_num, cashreceipt.cmpy_code"

		PREPARE s_cashreceipt FROM l_query_text 
		DECLARE c_cashreceipt CURSOR WITH HOLD FOR s_cashreceipt 
		
		LET l_idx = 0 
		LET l_continue = TRUE 
		LET l_banking_required = FALSE 

		FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
			LET l_idx = l_idx + 1 
			LET l_banking_required = TRUE 
			
			IF l_rec_cashreceipt.conv_qty IS NULL	OR l_rec_cashreceipt.conv_qty = 0 THEN 
				LET l_rec_cashreceipt.conv_qty = 1 
			END IF 
			
			IF l_rec_cashreceipt.cash_amt IS NULL THEN 
				LET l_rec_cashreceipt.cash_amt = 0 
			END IF 
			
			INITIALIZE l_rec_tentbankdetl.* TO NULL 
			
			LET l_rec_tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_tentbankdetl.bank_dep_num = glob_bank_dep_num 
			LET l_rec_tentbankdetl.seq_num = l_idx 
			LET l_rec_tentbankdetl.cust_code = l_rec_cashreceipt.cust_code 
			LET l_rec_tentbankdetl.cash_date = l_rec_cashreceipt.cash_date 
			LET l_rec_tentbankdetl.cash_num = l_rec_cashreceipt.cash_num 

			## IF the receipt currency code IS NOT the same as the bank currency
			## code, THEN the bank must be base currency AND the receipt must
			## be foreign.  We only allows receipts TO banks of like
			## currency OR TO a base currency bank
			IF l_rec_bank.currency_code != l_rec_cashreceipt.currency_code THEN 
				LET l_rec_tentbankdetl.tran_amt = l_rec_cashreceipt.cash_amt / 
				l_rec_cashreceipt.conv_qty 
			ELSE 
				LET l_rec_tentbankdetl.tran_amt = l_rec_cashreceipt.cash_amt 
			END IF 
			
			LET l_rec_tentbankdetl.currency_code = l_rec_cashreceipt.currency_code 
			LET l_rec_tentbankdetl.conv_qty = l_rec_cashreceipt.conv_qty 
			LET l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_2 
			LET l_rec_tentbankdetl.cash_type_ind = l_rec_cashreceipt.cash_type_ind 
			LET l_rec_tentbankdetl.drawer_text = l_rec_cashreceipt.drawer_text 
			LET l_rec_tentbankdetl.bank_text = l_rec_cashreceipt.bank_text 
			LET l_rec_tentbankdetl.branch_text = l_rec_cashreceipt.branch_text 
			LET l_rec_tentbankdetl.cheque_text = l_rec_cashreceipt.cheque_text 
			LET glob_err_message = "A61 - Insert INTO tentbankdetl" 
			# INSERT ---------------------------------------------------
			INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*)
			 
			LET glob_err_message = "A61 - Updating cashreceipt" 
			# UPDATE ---------------------------------------------------
			UPDATE cashreceipt SET 
				cashreceipt.banked_flag = "Y", 
				cashreceipt.banked_date = TODAY, 
				cashreceipt.bank_dep_num = glob_bank_dep_num 
			WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cashreceipt.cash_num = l_rec_cashreceipt.cash_num 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				IF promptTF("Bulk apply",kandoomsg2("A",8037,""),1) THEN
					LET l_continue = FALSE 
					EXIT FOREACH 
				END IF 
			END IF 

		END FOREACH 

		IF NOT l_banking_required THEN 
			ROLLBACK WORK
			CALL msgerror("",kandoomsg2("A",7501,""))
			RETURN FALSE 
		END IF 

		IF l_continue THEN 
			LET glob_err_message = "A61 - Updating tentbankhead" 
			# UPDATE ---------------------------------------
			UPDATE tentbankhead 
			SET tentbankhead.status_ind = "1" 
			WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tentbankhead.bank_dep_num = glob_bank_dep_num 
			COMMIT WORK 
			LET l_msg = "Added Deposit ",trim(l_rec_tentbankhead.bank_dep_num)," to Bank ",trim(l_rec_bank.bank_code )," - ",trim(l_rec_bank.name_acct_text)
			CALL msgcontinue("",l_msg)
			RETURN TRUE
		ELSE 
			ROLLBACK WORK
			RETURN FALSE 
		END IF 

END FUNCTION 
############################################################################
# END FUNCTION generate_tentative_deposit()
############################################################################
