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
GLOBALS "../ar/A6P_GLOBALS.4gl" 

############################################################################
# FUNCTION A6P_main
#
# A6P - POS Bank Deposit Calculator
############################################################################
FUNCTION A6P_main() 
	DEFINE l_run_arg STRING 

	DEFER interrupt 
	DEFER quit 

	#Initial UI Init
	CALL setModuleId("A6P") 

	OPEN WINDOW A689 with FORM "A689" 
	CALL windecoration_a("A689") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " POS Bank Deposit Calculator" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","A6P","menu-pos-bank-deposit") 
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

		ON ACTION "REPORT"		#COMMAND "Report" " Generate REPORT on current bank deposit"
			LET l_run_arg = "BANKDEPARTMENT_NUMBER=", trim(glob_bank_dep_num) 
			CALL run_prog("A62",l_run_arg,"","","") #a62 - trial deposit PRINT 
			NEXT option "Exit" 

		ON ACTION "CANCEL"		#command  key (interrupt,"E")"Exit" " Exit the Program"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A689 

END FUNCTION 
#######################################################################
# END FUNCTION A6P
#######################################################################


#######################################################################
# FUNCTION generate_tentative_deposit()
#
#
#######################################################################
FUNCTION generate_tentative_deposit() 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_rec_pospmnts RECORD LIKE pospmnts.*
	DEFINE l_rec_pospmnttype RECORD LIKE pospmnttype.*
	DEFINE l_rec_pospmntdet RECORD LIKE pospmntdet.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_userlocn RECORD LIKE userlocn.*
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_continue SMALLINT
	DEFINE l_banking_required SMALLINT
	DEFINE l_cash_amt LIKE tentbankdetl.tran_amt
	DEFINE l_cash_date LIKE pospmnts.tran_date
	DEFINE l_include_ar CHAR(1)
	DEFINE l_desc_text CHAR(30)
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_msg STRING
	DEFINE l_idx SMALLINT

	CLEAR FORM 
	ERROR kandoomsg2("U",1020,"Banking") 	#1020 Enter Banking Details; OK TO Continue
	LET l_rec_pospmnts.tran_date = TODAY 
	LET l_include_ar = "N" 
	
	INPUT 
		l_rec_pospmnts.tran_date, 
		l_rec_pospmnts.bank_code, 
		l_desc_text, 
		l_include_ar WITHOUT DEFAULTS 
	FROM
		tran_date, 
		bank_code, 
		desc_text, 
		include_ar	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A6P","inp-pospmnts") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING 
				l_rec_pospmnts.bank_code, 
				l_rec_bank.acct_code 
			NEXT FIELD bank_code 

		AFTER FIELD tran_date 
			IF l_rec_pospmnts.tran_date IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
				NEXT FIELD tran_date 
			END IF 

		AFTER FIELD bank_code 
			IF l_rec_pospmnts.bank_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
				NEXT FIELD bank_code 
			END IF 

			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE bank.bank_code = l_rec_pospmnts.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF STATUS = NOTFOUND THEN 
				ERROR kandoomsg2("U",9105,"") 				#9105 RECORD Not Found; Try Window
				NEXT FIELD bank_code 
			END IF 
			DISPLAY BY NAME l_rec_bank.name_acct_text 

		AFTER INPUT 
			IF int_flag = FALSE AND quit_flag = FALSE THEN 
				IF l_rec_pospmnts.bank_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
					NEXT FIELD bank_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	
	MESSAGE kandoomsg2("U",1001,"") 	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON 
		locn_code, 
		station_code, 
		entry_code, 
		pay_type 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","A6P","construct-tentbankhead") 

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
		LET l_rec_tentbankhead.source_ind = "1"		
		LET l_rec_tentbankhead.tran_date = l_rec_pospmnts.tran_date 
		LET l_rec_tentbankhead.status_ind = "2" 
		LET l_rec_tentbankhead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_tentbankhead.entry_date = TODAY 
		LET glob_err_message = "A6P - Insert INTO tentbankhead"
		# INSERT -------------------------------------------------------
		INSERT INTO tentbankhead VALUES (l_rec_tentbankhead.*)
		 
		LET l_query_text = 
			"SELECT * FROM pospmnts ", 
			"WHERE pospmnts.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
			"AND pospmnts.type_ind in ('C','A') ", 
			"AND pospmnts.bank_code = '",trim(l_rec_bank.bank_code),"' ", 
			"AND (pospmnts.banked = 'N' OR pospmnts.banked IS NULL) ", 
			"AND pospmnts.tran_date <= '",l_rec_pospmnts.tran_date,"' ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY pospmnts.doc_num" 

		PREPARE s_pospmnts FROM l_query_text 
		DECLARE c_pospmnts CURSOR with HOLD FOR s_pospmnts 

		LET l_idx = 0 
		LET l_continue = TRUE 
		LET l_banking_required = FALSE 
		LET l_cash_amt = 0 
		LET l_cash_date = l_rec_pospmnts.tran_date 

		FOREACH c_pospmnts INTO l_rec_pospmnts.* 
			LET l_banking_required = TRUE 

			INITIALIZE l_rec_tentbankdetl.* TO NULL 
			SELECT * INTO l_rec_pospmnttype.* FROM pospmnttype 
			WHERE pospmnttype.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pospmnttype.pmnt_type_code = l_rec_pospmnts.pay_type 

			IF l_rec_pospmnttype.pmnt_class = "C" THEN 
				LET l_cash_amt = l_cash_amt + l_rec_pospmnts.pay_amount 
			ELSE 
				LET l_idx = l_idx + 1 
				IF l_rec_pospmnts.cash_num IS NOT NULL THEN 
					INITIALIZE l_rec_cashreceipt.* TO NULL 
					SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
					WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code
					AND cashreceipt.cash_num = l_rec_pospmnts.cash_num 

					LET l_rec_tentbankdetl.currency_code = l_rec_cashreceipt.currency_code 
					LET l_rec_tentbankdetl.conv_qty = l_rec_cashreceipt.conv_qty 
					LET l_rec_tentbankdetl.bank_text = l_rec_cashreceipt.bank_text 
					LET l_rec_tentbankdetl.drawer_text = l_rec_cashreceipt.drawer_text 
					LET l_rec_tentbankdetl.branch_text = l_rec_cashreceipt.branch_text 
					LET l_rec_tentbankdetl.cheque_text = l_rec_cashreceipt.cheque_text 
				ELSE 
					INITIALIZE l_rec_pospmntdet.* TO NULL 
					SELECT * INTO l_rec_pospmntdet.* FROM pospmntdet 
					WHERE pospmntdet.sequence_num = l_rec_pospmnts.sequence_num 
					AND pospmntdet.cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET l_rec_tentbankdetl.currency_code = l_rec_bank.currency_code 
					LET l_rec_tentbankdetl.conv_qty = 1 

					CASE l_rec_pospmnttype.pmnt_class 
						WHEN PAYMENT_TYPE_CHEQUE_Q 
							LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
							LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.drawer 
							LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.branch 
							LET l_rec_tentbankdetl.cheque_text = l_rec_pospmntdet.cheque_no 
						
						WHEN PAYMENT_TYPE_CC_P 
							LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
							LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.card_holder 
							LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.ccard_no 
						
						OTHERWISE 
							LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
							LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.drawer 
							LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.branch 
							LET l_rec_tentbankdetl.cheque_text = l_rec_pospmntdet.cheque_no 
					END CASE 

				END IF 

				LET l_rec_tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentbankdetl.bank_dep_num = glob_bank_dep_num 
				LET l_rec_tentbankdetl.seq_num = l_idx 
				LET l_rec_tentbankdetl.cash_num = l_rec_pospmnts.cash_num 
				LET l_rec_tentbankdetl.pos_doc_num = l_rec_pospmnts.doc_num 
				LET l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_1 
				LET l_rec_tentbankdetl.tran_amt = l_rec_pospmnts.pay_amount 
				LET l_rec_tentbankdetl.cust_code = l_rec_pospmnts.cust_code 
				LET l_rec_tentbankdetl.cash_date = l_rec_pospmnts.tran_date 
				LET l_rec_tentbankdetl.cash_type_ind = l_rec_pospmnttype.pmnt_class 
				LET l_rec_tentbankdetl.station_code = l_rec_pospmnts.station_code 
				LET l_rec_tentbankdetl.locn_code = l_rec_pospmnts.locn_code 
				LET l_rec_tentbankdetl.pos_pay_type = l_rec_pospmnts.pay_type 
				LET glob_err_message = "A6P - Insert INTO tentbankdetl" 
				# INSERT -----------------------------------------------------------
				INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*) 
			END IF 

			LET glob_err_message = "A6P - Updating pospmnts" 
			# UPDATE ------------------------------------------------------------------
			UPDATE pospmnts 
			SET pospmnts.banked = "Y", 
			pospmnts.date_banked = TODAY, 
			pospmnts.bank_dep_num = glob_bank_dep_num 
			WHERE pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pospmnts.doc_num = l_rec_pospmnts.doc_num 
			
			IF l_rec_pospmnts.cash_num IS NOT NULL THEN 
				LET glob_err_message = "A6P - Updating cashreceipt" 
				UPDATE cashreceipt SET 
					cashreceipt.banked_flag = "Y", 
					cashreceipt.banked_date = TODAY, 
					cashreceipt.bank_dep_num = glob_bank_dep_num 
				WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cash_num = l_rec_pospmnts.cash_num 
			END IF 
			
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

		IF l_continue AND l_include_ar = "Y" THEN 
			LET l_query_text = 
				"SELECT * FROM cashreceipt ", 
				"WHERE cashreceipt.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
				"AND cashreceipt.cash_acct_code = '",trim(l_rec_bank.acct_code),"' ", 
				"AND (cashreceipt.banked_flag = 'N' OR cashreceipt.banked_flag IS NULL) ", 
				"AND (cashreceipt.chq_date <= '",TODAY,"' OR cashreceipt.chq_date IS NULL) ", 
				"ORDER BY cashreceipt.cash_num, cashreceipt.cmpy_code" 

			PREPARE s_cashreceipt FROM l_query_text 
			DECLARE c_cashreceipt CURSOR with HOLD FOR s_cashreceipt 

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
				## be foreign.  We only allow receipts TO banks of like
				## currency OR TO a base currency bank. POS receipts do NOT need
				## this conversion - POS requires the receipt bank always TO be
				## the same currency as the customer code AND hence the receipt
				## currency code will always match the bank.
				IF l_rec_bank.currency_code != l_rec_cashreceipt.currency_code THEN 
					LET l_rec_tentbankdetl.tran_amt = l_rec_cashreceipt.cash_amt / l_rec_cashreceipt.conv_qty 
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
				LET glob_err_message = "A6P - Insert INTO tentbankdetl" 
				# INSERT ---------------------------------------------------
				INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*) 

				LET glob_err_message = "A6P - Updating cashreceipt" 
				# UPDATE -----------------------------------------------------
				UPDATE cashreceipt SET 
					cashreceipt.banked_flag = "Y", 
					cashreceipt.banked_date = TODAY, 
					cashreceipt.bank_dep_num = glob_bank_dep_num 
				WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cash_num = l_rec_cashreceipt.cash_num 
				
				IF int_flag OR quit_flag THEN 
					LET int_flag = FALSE 
					LET quit_flag = FALSE 
					IF promptTF("",kandoomsg2("A",8037,""),1) THEN
						LET l_continue = FALSE 
						EXIT FOREACH 
					END IF 
				END IF 
			END FOREACH 

		END IF 

		IF l_continue THEN 
			IF l_cash_amt > 0 THEN 
				LET l_idx = l_idx + 1 
				
				INITIALIZE l_rec_tentbankdetl.* TO NULL 
				
				LET l_rec_tentbankdetl.currency_code = l_rec_bank.currency_code 
				LET l_rec_tentbankdetl.conv_qty = 1 
				LET l_rec_tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentbankdetl.bank_dep_num = glob_bank_dep_num 
				LET l_rec_tentbankdetl.seq_num = l_idx 
				LET l_rec_tentbankdetl.pos_doc_num = 0 
				LET l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_0 
				LET l_rec_tentbankdetl.tran_amt = l_cash_amt 
				LET l_rec_tentbankdetl.cash_type_ind = "C" 
				LET l_rec_tentbankdetl.cash_date = l_cash_date 
				LET glob_err_message = "A6P - Inserting tentbankdetl"
				# INSERT ------------------------------------------- 
				INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*) 
			END IF 

			LET glob_err_message = "A6P - Updating tentbankhead" 
			# UPDATE ---------------------------
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
#######################################################################
# END FUNCTION generate_tentative_deposit()
#######################################################################
