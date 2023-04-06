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

#######################################################################
# FUNCTION A63_main()
#
# Purpose - Deposit Edit
#######################################################################
FUNCTION A63_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A63") 

	OPEN WINDOW A687 with FORM "A687" 
	CALL windecoration_a("A687") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_deposit() 
	END WHILE 

	CLOSE WINDOW A687 

END FUNCTION 
#######################################################################
# END FUNCTION A63_main()
#######################################################################

#######################################################################
# FUNCTION select_deposit()
#
#
#######################################################################
FUNCTION select_deposit() 
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.* 
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD
	DEFINE l_err_message CHAR(60)
	DEFINE l_delete_tenthead SMALLINT
	DEFINE l_tent_left SMALLINT
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_status_ind CHAR(1)
	DEFINE l_idx SMALLINT

	MESSAGE kandoomsg2("U",1051,"Edit") 	#1051 "F3/F4 TO Page Up/Down;  ENTER on line TO Edit"

	CALL l_arr_rec_tentbankhead.CLEAR()
	CALL db_tentbankhead_get_datasource(FALSE) RETURNING l_arr_rec_tentbankhead

	DISPLAY ARRAY l_arr_rec_tentbankhead TO sr_tentbankhead.* ATTRIBUTE(UNBUFFERED)
 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A63","inp-arr-tentbankhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_tentbankhead.CLEAR()
			CALL db_tentbankhead_get_datasource(TRUE) RETURNING l_arr_rec_tentbankhead
			
		ON ACTION ("EDIT","DOUBLECLICK") #so, the user can also use the mouse
			LET l_idx = arr_curr()
--			IF l_arr_rec_tentbankhead[l_idx].scroll_flag = "*" THEN  #IS record/row marked for delete ? (albo) 
--				ERROR kandoomsg2("A",9524,"") 				#9524 This tentative deposit has been deleted
--				NEXT FIELD scroll_flag 
--			END IF
			 
			IF l_arr_rec_tentbankhead[l_idx].bank_dep_num IS NOT NULL 
			AND l_arr_rec_tentbankhead[l_idx].bank_dep_num != 0 THEN 
				SELECT tentbankhead.status_ind INTO l_status_ind FROM tentbankhead 
				WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
				AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code
				IF l_status_ind NOT MATCHES "[23]" THEN 
					BEGIN WORK 
						DECLARE c_tentbankhead3 CURSOR FOR 
						SELECT * FROM tentbankhead 
						WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code
						AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code 
						FOR UPDATE 
						OPEN c_tentbankhead3 
						FETCH c_tentbankhead3 INTO l_rec_tentbankhead.* 
						IF STATUS = 0 THEN 
							IF l_rec_tentbankhead.status_ind NOT MATCHES"[23]" THEN 
								LET l_err_message = "A63 - Update tentbankhead 1" 
								UPDATE tentbankhead 
								SET tentbankhead.status_ind = "2" 
								WHERE CURRENT OF c_tentbankhead3
							ELSE 
								ERROR kandoomsg2("A",9523,"") 								#9523 This tentative deposit IS currently being used.
								LET l_arr_rec_tentbankhead[l_idx].status_flag = "*" 
								ROLLBACK WORK 
								CONTINUE DISPLAY 
							END IF 
						ELSE 
							ERROR kandoomsg2("A",9527,"") 						#9527 This tentative bank deposit has been deleted OR banked.
							ROLLBACK WORK 
							CONTINUE DISPLAY
						END IF 

					COMMIT WORK 

					LET l_delete_tenthead = FALSE 
					CALL edit_deposit(l_arr_rec_tentbankhead[l_idx].bank_code,l_arr_rec_tentbankhead[l_idx].bank_dep_num) 

					SELECT COUNT(*) INTO l_tent_left FROM tentbankdetl 
					WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tentbankdetl.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
					IF l_tent_left = 0 THEN 
						LET l_delete_tenthead = TRUE 
					END IF 
					IF l_tent_left = 1 THEN 
						SELECT * INTO l_rec_tentbankdetl.* FROM tentbankdetl 
						WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tentbankdetl.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						IF l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_0 THEN 
							IF kandoomsg("A",8043,"") = "Y" THEN #8043 Confirm TO delete last POS cash tentbankdetl
								LET l_delete_tenthead = TRUE 
							END IF 
						END IF 
					END IF 

					BEGIN WORK 
						IF l_delete_tenthead THEN 
							LET l_err_message = "A63 - Deleting tentbankhead 1" 
							DELETE FROM tentbankhead 
							WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
							AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code
							LET l_err_message = "A63 - Update pospmnts 1" 
							UPDATE pospmnts 
							SET pospmnts.banked = "N", 
							pospmnts.date_banked = NULL, 
							pospmnts.bank_dep_num = NULL 
							WHERE pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND pospmnts.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
							LET l_arr_rec_tentbankhead[l_idx].deposit_amt = 0 
							LET l_arr_rec_tentbankhead[l_idx].scroll_flag = "*" 
							LET l_scroll_flag = "*" 
						ELSE 
							SELECT SUM(tentbankdetl.tran_amt) INTO l_arr_rec_tentbankhead[l_idx].deposit_amt 
							FROM tentbankdetl 
							WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tentbankdetl.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						END IF 
						LET l_err_message = "A63 - Update tentbankhead 2" 
						UPDATE tentbankhead 
						SET tentbankhead.status_ind = "1" 
						WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code

					COMMIT WORK 
					MESSAGE kandoomsg2("U",1051,"Edit") 					#1051 "F3/F4 TO Page Up/Down;  ENTER on line TO Edit"
				ELSE 
					ERROR kandoomsg2("A",9523,"") 					#9523 This tentative deposit IS currently being used.
					CONTINUE DISPLAY
				END IF 
			END IF 
			
			#Refresh from DB
			CALL l_arr_rec_tentbankhead.CLEAR()
			CALL db_tentbankhead_get_datasource(FALSE) RETURNING l_arr_rec_tentbankhead

	END DISPLAY

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
	
END FUNCTION 
#######################################################################
# END FUNCTION select_deposit()
#######################################################################

#######################################################################
# FUNCTION edit_deposit(p_bank_code,p_bank_dep_num)
#
#
#######################################################################
FUNCTION edit_deposit(p_bank_code,p_bank_dep_num) 
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_bank_dep_num LIKE tentbankhead.bank_dep_num 
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_rec_pospmnts RECORD LIKE pospmnts.*
	DEFINE l_rec_pospmnttype RECORD LIKE pospmnttype.*
	DEFINE l_rec_pospmntdet RECORD LIKE pospmntdet.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_arr_rec_tentbankdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cash_num LIKE tentbankdetl.cash_num, 
		cust_code LIKE tentbankdetl.cust_code, 
		cash_date LIKE tentbankdetl.cash_date, 
		tran_amt LIKE tentbankdetl.tran_amt, 
		cheque_text CHAR(10), 
		bank_text CHAR(15), 
		cash_type_ind CHAR(1) 
	END RECORD
	DEFINE l_arr_rec_pospmnts DYNAMIC ARRAY OF RECORD 
		doc_num INTEGER 
	END RECORD
	DEFINE l_deposit_amt LIKE cashreceipt.cash_amt
	DEFINE l_cash_amt LIKE cashreceipt.cash_amt
	DEFINE l_pos_amt LIKE cashreceipt.cash_amt
	DEFINE l_other_amt LIKE cashreceipt.cash_amt
	DEFINE l_insert_flag SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_err_message CHAR(60)
	DEFINE l_scroll_flag CHAR(1)
	DEFINE l_run_arg STRING 
	DEFINE l_i SMALLINT
	DEFINE l_h SMALLINT
	DEFINE l_j SMALLINT
	DEFINE l_x SMALLINT
	DEFINE l_y SMALLINT
	DEFINE l_idx SMALLINT

	SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
	WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankhead.bank_dep_num = p_bank_dep_num 
	AND tentbankhead.bank_code = p_bank_code

	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank.bank_code = l_rec_tentbankhead.bank_code 

	SELECT SUM(tentbankdetl.tran_amt) INTO l_deposit_amt FROM tentbankdetl 
	WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankdetl.bank_dep_num = p_bank_dep_num 

	SELECT SUM(tentbankdetl.tran_amt) INTO l_cash_amt FROM tentbankdetl 
	WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankdetl.bank_dep_num = p_bank_dep_num 
	AND tentbankdetl.cash_type_ind = "C" 
	AND tentbankdetl.cash_num IS NOT NULL 

	SELECT SUM(tentbankdetl.tran_amt) INTO l_other_amt FROM tentbankdetl 
	WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankdetl.bank_dep_num = p_bank_dep_num 
	AND tentbankdetl.cash_type_ind != "C" 

	SELECT SUM(tentbankdetl.tran_amt) INTO l_pos_amt FROM tentbankdetl 
	WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankdetl.bank_dep_num = p_bank_dep_num 
	AND tentbankdetl.cash_type_ind = "C" 
	AND tentbankdetl.cash_num IS NULL 

	IF l_deposit_amt IS NULL THEN 
		LET l_deposit_amt = 0 
	END IF 
	IF l_cash_amt IS NULL THEN 
		LET l_cash_amt = 0 
	END IF 
	IF l_pos_amt IS NULL THEN 
		LET l_pos_amt = 0 
	END IF 
	IF l_other_amt IS NULL THEN 
		LET l_other_amt = 0 
	END IF 

	OPEN WINDOW A688 with FORM "A688" 
	CALL windecoration_a("A688") 

	DISPLAY l_rec_tentbankhead.bank_code TO bank_code
	DISPLAY l_rec_tentbankhead.bank_dep_num TO bank_dep_num
	DISPLAY l_rec_tentbankhead.desc_text TO desc_text
	DISPLAY l_deposit_amt TO deposit_amt
	DISPLAY l_pos_amt TO pos_amt
	DISPLAY l_cash_amt TO cash_amt 
	DISPLAY l_other_amt TO other_amt
	DISPLAY l_rec_tentbankhead.currency_code TO currency_code

	CALL l_arr_rec_tentbankdetl.CLEAR()
	CALL l_arr_rec_pospmnts.CLEAR() 
	CALL db_tentbankdetl_get_datsource_edit_row_rec(FALSE,p_bank_dep_num) RETURNING l_arr_rec_tentbankdetl, l_arr_rec_pospmnts

	MESSAGE kandoomsg2("A",1044,"") #1044 "F1 TO Add;  F2 TO Delete; F10 TO Delete All;  OK TO Continue"

	LET l_del_cnt = 0 
	LET l_insert_flag = FALSE 

	INPUT ARRAY l_arr_rec_tentbankdetl WITHOUT DEFAULTS FROM sr_tentbankdetl.* ATTRIBUTE(UNBUFFERED, DELETE ROW = FALSE, INSERT ROW = FALSE, AUTO APPEND = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A63","inp-arr-tentbankdetl") 
			CALL fgl_dialog_setactionlabel("DELETE ALL","Delete All","{CONTEXT}/public/querix/icon/svg/24/ic_delete_24px.svg",12,FALSE,"Delete all records")
			IF l_insert_flag = TRUE THEN
				CALL DIALOG.SetFieldActive("cash_num",TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("cash_num",FALSE)
			END IF

		BEFORE INSERT 
			LET l_insert_flag = TRUE
			NEXT FIELD cash_num

		BEFORE FIELD cash_num
			IF l_insert_flag = TRUE THEN
				CALL DIALOG.SetFieldActive("cash_num",TRUE)
			ELSE
				CALL DIALOG.SetFieldActive("cash_num",FALSE)
			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_tentbankdetl.CLEAR()
			CALL l_arr_rec_pospmnts.CLEAR() 
			CALL db_tentbankdetl_get_datsource_edit_row_rec(TRUE,p_bank_dep_num) RETURNING l_arr_rec_tentbankdetl, l_arr_rec_pospmnts

{ !!! For the A35 program you need implement the ability to use external arguments CALL run_prog("A35",l_run_arg,"","","") !!! (albo) 
		ON KEY (F5) infield(scroll_flag) 
			CALL run_prog("A35","","","","") 
}
		ON ACTION "EDIT"
			LET l_idx = arr_curr()
			LET l_run_arg = "CASHRECEIPT_NUMBER=", trim(l_arr_rec_tentbankdetl[l_idx].cash_num) 
			IF l_arr_rec_tentbankdetl[l_idx].cash_num != 0 
			AND l_arr_rec_tentbankdetl[l_idx].cash_num IS NOT NULL THEN 
				IF l_arr_rec_pospmnts[l_idx].doc_num IS NULL THEN 
					CALL run_prog("A37",l_run_arg,"","","") 
				ELSE 
					CALL run_prog("sucash",l_run_arg,"","","") 
					CONTINUE INPUT -- The program "sucash" does NOT exist in Kandoo project. We may need to develop this program. (albo)
				END IF 
				
				SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
				WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cash_num = l_arr_rec_tentbankdetl[l_idx].cash_num
				 
				LET l_arr_rec_tentbankdetl[l_idx].cash_date = l_rec_cashreceipt.cash_date 
				LET l_arr_rec_tentbankdetl[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
				LET l_arr_rec_tentbankdetl[l_idx].bank_text = l_rec_cashreceipt.bank_text 
				LET l_arr_rec_tentbankdetl[l_idx].cash_type_ind = 
				l_rec_cashreceipt.cash_type_ind 
				IF l_rec_bank.currency_code != l_rec_cashreceipt.currency_code THEN 
					LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_cashreceipt.cash_amt	/ l_rec_cashreceipt.conv_qty 
				ELSE 
					LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_cashreceipt.cash_amt 
				END IF 

				LET l_err_message = "A63 - Updating Tentbankdetl 1" 
				UPDATE tentbankdetl 
				SET 
				tentbankdetl.cash_type_ind = l_rec_cashreceipt.cash_type_ind, 
				tentbankdetl.drawer_text = l_rec_cashreceipt.drawer_text, 
				tentbankdetl.bank_text = l_rec_cashreceipt.bank_text, 
				tentbankdetl.branch_text = l_rec_cashreceipt.branch_text, 
				tentbankdetl.cheque_text = l_rec_cashreceipt.cheque_text, 
				tentbankdetl.tran_amt = l_arr_rec_tentbankdetl[l_idx].tran_amt, 
				tentbankdetl.cash_date = l_rec_cashreceipt.cash_date 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.cash_num = l_rec_cashreceipt.cash_num 

				SELECT SUM(tentbankdetl.tran_amt) INTO l_deposit_amt FROM tentbankdetl 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.bank_dep_num = p_bank_dep_num
				 
				SELECT SUM(tentbankdetl.tran_amt) INTO l_cash_amt FROM tentbankdetl 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.bank_dep_num = p_bank_dep_num 
				AND tentbankdetl.cash_type_ind = "C" 
				AND tentbankdetl.cash_num IS NOT NULL
				 
				SELECT SUM(tentbankdetl.tran_amt) INTO l_other_amt FROM tentbankdetl 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.bank_dep_num = p_bank_dep_num 
				AND tentbankdetl.cash_type_ind != "C"
				 
				IF l_deposit_amt IS NULL THEN 
					LET l_deposit_amt = 0 
				END IF 
				IF l_cash_amt IS NULL THEN 
					LET l_cash_amt = 0 
				END IF 
				IF l_other_amt IS NULL THEN 
					LET l_other_amt = 0 
				END IF 
				
				DISPLAY l_cash_amt TO cash_amt
				DISPLAY l_other_amt TO other_amt
				DISPLAY l_deposit_amt TO deposit_amt
			ELSE 
				ERROR kandoomsg2("A",9556,"")		#9556 No Cashreceipt exists FOR this entry; Cannot Edit.
			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "LOOKUP" infield(cash_num) 
			LET l_idx = arr_curr()
			IF l_rec_tentbankhead.source_ind = "1" THEN 
				LET l_arr_rec_pospmnts[l_idx].doc_num = show_pospmnt(glob_rec_kandoouser.cmpy_code,	l_rec_tentbankhead.bank_code) 
				IF l_arr_rec_pospmnts[l_idx].doc_num IS NOT NULL 
				AND l_arr_rec_pospmnts[l_idx].doc_num > 0 THEN 
					SELECT * INTO l_rec_pospmnts.* FROM pospmnts 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_arr_rec_pospmnts[l_idx].doc_num 

					IF STATUS = 0 THEN 
						SELECT * INTO l_rec_pospmnttype.* FROM pospmnttype 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND pmnt_type_code = l_rec_pospmnts.pay_type 
						SELECT * INTO l_rec_pospmntdet.* FROM pospmntdet 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND sequence_num = l_rec_pospmnts.sequence_num 

						FOR l_j = 1 TO arr_count() 
							IF l_arr_rec_pospmnts[l_j].doc_num = l_arr_rec_pospmnts[l_idx].doc_num 
							AND l_j != l_idx THEN 
								ERROR kandoomsg2("U",9529,"")		#9529 This row entry already exists
								NEXT FIELD cash_num 
							END IF 
						END FOR 

						IF NOT insert_tentbankdetl(p_bank_code,0,l_arr_rec_pospmnts[l_idx].doc_num,p_bank_dep_num) THEN 
							MESSAGE kandoomsg2("A",1044,"")	#1044 "F1 TO Add;  F2 TO Delete; F10 TO Delete All.
							LET l_arr_rec_pospmnts[l_idx].doc_num = NULL 
							NEXT FIELD cash_num 
						END IF 

						MESSAGE kandoomsg2("A",1044,"") 	#1044 "F1 TO Add;  F2 TO Delete; F10 TO Delete All.
						INITIALIZE l_arr_rec_tentbankdetl[l_idx].* TO NULL 

						CASE l_rec_pospmnttype.pmnt_class 
							WHEN PAYMENT_TYPE_CHEQUE_Q 
								LET l_arr_rec_tentbankdetl[l_idx].bank_text = 
								l_rec_pospmntdet.bank_name 
								LET l_arr_rec_tentbankdetl[l_idx].cheque_text = 
								l_rec_pospmntdet.cheque_no 
							WHEN "P" 
								LET l_arr_rec_tentbankdetl[l_idx].bank_text = 
								l_rec_pospmntdet.bank_name 
							OTHERWISE 
								LET l_arr_rec_tentbankdetl[l_idx].bank_text = 
								l_rec_pospmntdet.bank_name 
								LET l_arr_rec_tentbankdetl[l_idx].cheque_text = 
								l_rec_pospmntdet.cheque_no 
						END CASE 

						LET l_arr_rec_tentbankdetl[l_idx].cust_code = l_rec_pospmnts.cust_code 
						LET l_arr_rec_tentbankdetl[l_idx].cash_num = l_rec_pospmnts.cash_num 
						LET l_arr_rec_tentbankdetl[l_idx].cash_date = l_rec_pospmnts.tran_date 
						LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_pospmnts.pay_amount 
						LET l_arr_rec_tentbankdetl[l_idx].cash_type_ind = l_rec_pospmnttype.pmnt_class 
						LET l_deposit_amt = l_deposit_amt + l_rec_pospmnts.pay_amount 
						LET l_other_amt = l_other_amt + l_rec_pospmnts.pay_amount 

						DISPLAY l_deposit_amt TO deposit_amt 
						DISPLAY l_other_amt TO other_amt

						LET l_insert_flag = FALSE 
					ELSE 
						ERROR kandoomsg2("U",9910,"") #9910 RECORD Not Found.
						NEXT FIELD cash_num 
					END IF 
				ELSE 
					NEXT FIELD cash_num 
				END IF 
				NEXT FIELD cash_num 
			END IF 
 
		ON ACTION ("VIEW","DOUBLECLICK") #so, the user can also use the mouse
			LET l_idx = arr_curr()
			IF l_arr_rec_tentbankdetl[l_idx].cash_num IS NOT NULL THEN 
				CALL cash_disp(
					glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_tentbankdetl[l_idx].cust_code, 
					l_arr_rec_tentbankdetl[l_idx].cash_num) 
			END IF 

		ON CHANGE scroll_flag
			LET l_idx = arr_curr()
			IF l_arr_rec_tentbankdetl[l_idx].scroll_flag IS NOT NULL THEN 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_del_cnt = l_del_cnt - 1 
			END IF		

		ON ACTION "DELETE"
			LET l_idx = arr_curr()
			IF l_arr_rec_tentbankdetl[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_tentbankdetl[l_idx].scroll_flag = "*" 
				LET l_scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_tentbankdetl[l_idx].scroll_flag = NULL 
				LET l_scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 

		ON ACTION "DELETE ALL"
			FOR l_i = 1 TO arr_count() 
				IF (l_arr_rec_tentbankdetl[l_i].scroll_flag IS NULL 
				OR l_arr_rec_tentbankdetl[l_i].scroll_flag != "*") 
				AND l_arr_rec_tentbankdetl[l_i].cust_code IS NOT NULL THEN 
					LET l_arr_rec_tentbankdetl[l_i].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_tentbankdetl[l_i].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END FOR 
			LET l_h = arr_curr() 
			LET l_x = scr_line() 
			LET l_j = 10 - l_x 
			LET l_y = (l_h - l_x) + 1 

		AFTER FIELD cash_num 
			LET l_idx = arr_curr()
			IF l_insert_flag = TRUE THEN 			
				IF l_arr_rec_tentbankdetl[l_idx].cash_num IS NOT NULL THEN
					SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
					WHERE cashreceipt.cash_num = l_arr_rec_tentbankdetl[l_idx].cash_num 
					AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF STATUS = 0 THEN 
						FOR l_i = 1 TO arr_count() 
							IF l_arr_rec_tentbankdetl[l_i].cash_num = l_arr_rec_tentbankdetl[l_idx].cash_num 
							AND l_i != l_idx THEN 
								ERROR kandoomsg2("U",9529,"")				#9529 This row entry already exists
								NEXT FIELD cash_num
							END IF 
						END FOR 
						IF NOT insert_tentbankdetl(p_bank_code,1,l_arr_rec_tentbankdetl[l_idx].cash_num,p_bank_dep_num) THEN 
							NEXT FIELD cash_num
						END IF 
						LET l_arr_rec_tentbankdetl[l_idx].cust_code = l_rec_cashreceipt.cust_code 
						LET l_arr_rec_tentbankdetl[l_idx].cash_num = l_rec_cashreceipt.cash_num 
						LET l_arr_rec_tentbankdetl[l_idx].cash_date = l_rec_cashreceipt.cash_date 
						IF l_rec_cashreceipt.currency_code != l_rec_bank.currency_code THEN 
							LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_cashreceipt.cash_amt/l_rec_cashreceipt.conv_qty 
						ELSE 
							LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_cashreceipt.cash_amt 
						END IF 
						LET l_arr_rec_tentbankdetl[l_idx].cheque_text = l_rec_cashreceipt.cheque_text 
						LET l_arr_rec_tentbankdetl[l_idx].bank_text = l_rec_cashreceipt.bank_text 
						LET l_arr_rec_tentbankdetl[l_idx].cash_type_ind = l_rec_cashreceipt.cash_type_ind 
						IF l_rec_cashreceipt.cash_type_ind = "C" THEN 
							IF l_rec_cashreceipt.currency_code != l_rec_bank.currency_code THEN 
								LET l_cash_amt = l_cash_amt + l_rec_cashreceipt.cash_amt/l_rec_cashreceipt.conv_qty 
							ELSE 
								LET l_cash_amt = l_cash_amt + l_rec_cashreceipt.cash_amt 
							END IF 
							DISPLAY l_cash_amt TO cash_amt  
						ELSE 
							IF l_rec_cashreceipt.currency_code != l_rec_bank.currency_code THEN 
								LET l_other_amt = l_other_amt + l_rec_cashreceipt.cash_amt/l_rec_cashreceipt.conv_qty 
							ELSE 
								LET l_other_amt = l_other_amt + l_rec_cashreceipt.cash_amt 
							END IF 
							DISPLAY l_other_amt TO other_amt 
						END IF 
						LET l_deposit_amt = l_deposit_amt + l_rec_cashreceipt.cash_amt 
						DISPLAY l_deposit_amt TO deposit_amt 
					ELSE 
						ERROR kandoomsg2("U",9910,"")		#9910 RECORD Not Found.
						IF l_arr_rec_tentbankdetl[l_idx].scroll_flag IS NULL THEN
						 	NEXT FIELD cash_num
						END IF  
					END IF 
				ELSE
					IF (l_arr_rec_tentbankdetl[l_idx].cash_num IS NULL 
					 OR l_arr_rec_tentbankdetl[l_idx].cash_num = 0) 
					AND (l_arr_rec_pospmnts[l_idx].doc_num IS NULL 
					 OR  l_arr_rec_pospmnts[l_idx].doc_num = 0) THEN 
						ERROR kandoomsg2("U",9102,"")		#9102 Value must be entered
						NEXT FIELD cash_num 
					END IF 
				END IF 
			END IF
			LET l_insert_flag = FALSE

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		CLOSE WINDOW A688 
		RETURN 
	END IF 
	
	IF l_del_cnt > 0 THEN 
		IF kandoomsg("U",8000,l_del_cnt) = "Y" THEN 
			#8000 Confirmation TO delete ??? rows.
			MESSAGE kandoomsg2("U",1005,"") 			#1005 Updating Database, Please Wait;
			BEGIN WORK		
			FOR l_i = 1 TO arr_count() 
				IF l_arr_rec_tentbankdetl[l_i].scroll_flag = "*" THEN 
					IF l_arr_rec_pospmnts[l_i].doc_num IS NULL 
					OR l_arr_rec_pospmnts[l_i].doc_num = 0 
					THEN 
						INITIALIZE l_rec_tentbankdetl.* TO NULL 
						SELECT * INTO l_rec_tentbankdetl.* FROM tentbankdetl 
						WHERE tentbankdetl.cash_num = l_arr_rec_tentbankdetl[l_i].cash_num 
						AND tentbankdetl.bank_dep_num = p_bank_dep_num 
						AND tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_err_message = "A63 - Deleting tentbankdetl 1" 
						DELETE FROM tentbankdetl 
						WHERE tentbankdetl.cash_num = l_arr_rec_tentbankdetl[l_i].cash_num 
						AND tentbankdetl.bank_dep_num = p_bank_dep_num 
						AND tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					ELSE 
						INITIALIZE l_rec_tentbankdetl.* TO NULL 
						SELECT * INTO l_rec_tentbankdetl.* FROM tentbankdetl 
						WHERE tentbankdetl.pos_doc_num = l_arr_rec_pospmnts[l_i].doc_num 
						AND tentbankdetl.bank_dep_num = p_bank_dep_num 
						AND tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_err_message = "A63 - Deleting tentbankdetl 2" 
						DELETE FROM tentbankdetl 
						WHERE tentbankdetl.pos_doc_num = l_arr_rec_pospmnts[l_i].doc_num 
						AND tentbankdetl.bank_dep_num = p_bank_dep_num 
						AND tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
					IF l_rec_tentbankdetl.pos_doc_num IS NOT NULL THEN 
						LET l_err_message = "A63 - Updating pospmnts 2" 
						UPDATE pospmnts 
						SET pospmnts.banked = "N", 
						pospmnts.date_banked = NULL, 
						pospmnts.bank_dep_num = NULL 
						WHERE pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND pospmnts.doc_num = l_rec_tentbankdetl.pos_doc_num 
					END IF 
					IF l_rec_tentbankdetl.cash_num IS NOT NULL 
					AND l_rec_tentbankdetl.pos_doc_num IS NULL THEN 
						LET l_err_message = "A63 - Updating cashreceipt 1" 
						UPDATE cashreceipt 
						SET cashreceipt.banked_flag = "N", 
						cashreceipt.banked_date = NULL, 
						cashreceipt.bank_dep_num = NULL 
						WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cashreceipt.cash_num = l_rec_tentbankdetl.cash_num 
					END IF 
					LET l_arr_rec_tentbankdetl[l_i].scroll_flag = NULL 
				END IF 
			END FOR 
			COMMIT WORK
		END IF 
	END IF 

	CLOSE WINDOW A688 

END FUNCTION 
#######################################################################
# END FUNCTION edit_deposit(p_bank_code,p_bank_dep_num)
#######################################################################


#######################################################################
# FUNCTION show_pospmnt(p_cmpy_code,p_bank_code)
#
#
#######################################################################
FUNCTION show_pospmnt(p_cmpy_code,p_bank_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_bank_code LIKE pospmnts.bank_code
	DEFINE l_rec_pospmnts RECORD LIKE pospmnts.*
	DEFINE l_rec_pospmntdet RECORD LIKE pospmntdet.*
	DEFINE l_rec_pospmnttype RECORD LIKE pospmnttype.*
	DEFINE l_doc_num LIKE pospmnts.doc_num
	DEFINE l_arr_rec_pospmnt2 DYNAMIC ARRAY OF RECORD 
		cheque_no CHAR(10), 
		drawer CHAR(20), 
		bank_name CHAR(15), 
		ccard_no CHAR(20), 
		card_holder CHAR(20), 
		doc_num INTEGER 
	END RECORD
	DEFINE l_arr_rec_pospmnts DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		tran_date DATE, 
		pay_amount DECIMAL(16,2), 
		locn_code CHAR(8), 
		station_code CHAR(8), 
		pay_type CHAR(2), 
		bank_code CHAR(9) 
	END RECORD
	DEFINE l_idx SMALLINT
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 

	OPEN WINDOW A695 with FORM "A695" 
	CALL windecoration_a("A695") 

	WHILE TRUE 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			tran_date, 
			pay_amount, 
			locn_code, 
			station_code, 
			pay_type, 
			bank_code, 
			cheque_no, 
			drawer, 
			bank_name, 
			ccard_no, 
			card_holder 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A63","construct-pospmnts") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			INITIALIZE l_rec_pospmnts.doc_num TO NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"

		LET l_query_text = 
			"SELECT pospmnts.* FROM pospmnts, outer pospmntdet ", 
			" WHERE pospmnts.cmpy_code = '",trim(p_cmpy_code),"' ", 
			" AND pospmnts.sequence_num = pospmntdet.sequence_num ", 
			" AND pospmnts.cmpy_code = pospmntdet.cmpy_code ", 
			" AND pospmnts.bank_code = '",trim(p_bank_code),"' ", 
			" AND (pospmnts.banked = 'N' OR pospmnts.banked IS NULL) ", 
			" AND pospmnts.cash_num IS NULL ", 
			" AND ",l_where_text CLIPPED," ", 
			"ORDER BY pospmnts.tran_date" 

		PREPARE s_pospmnts FROM l_query_text 
		DECLARE c_pospmnts CURSOR FOR s_pospmnts 

		LET l_idx = 0 
		FOREACH c_pospmnts INTO l_rec_pospmnts.* 
			LET l_idx = l_idx + 1 

			SELECT * INTO l_rec_pospmntdet.* FROM pospmntdet 
			WHERE pospmntdet.sequence_num = l_rec_pospmnts.sequence_num 
			AND pospmntdet.cmpy_code = p_cmpy_code 

			SELECT * INTO l_rec_pospmnttype.* FROM pospmnttype 
			WHERE pospmnttype.cmpy_code = p_cmpy_code 
			AND pospmnttype.pmnt_type_code = l_rec_pospmnts.pay_type 

			IF l_rec_pospmnttype.pmnt_class = "C" THEN 
				CONTINUE FOREACH 
			END IF 

			INITIALIZE l_arr_rec_pospmnt2[l_idx].* TO NULL 

			CASE l_rec_pospmnttype.pmnt_class 
				WHEN PAYMENT_TYPE_CHEQUE_Q 
					LET l_arr_rec_pospmnt2[l_idx].bank_name = l_rec_pospmntdet.bank_name 
					LET l_arr_rec_pospmnt2[l_idx].drawer = l_rec_pospmntdet.drawer 
					LET l_arr_rec_pospmnt2[l_idx].cheque_no = l_rec_pospmntdet.cheque_no 
				WHEN "P" 
					LET l_arr_rec_pospmnt2[l_idx].bank_name = l_rec_pospmntdet.bank_name 
					LET l_arr_rec_pospmnt2[l_idx].drawer = l_rec_pospmntdet.card_holder 
					LET l_arr_rec_pospmnt2[l_idx].ccard_no = l_rec_pospmntdet.ccard_no 
				OTHERWISE 
					LET l_arr_rec_pospmnt2[l_idx].bank_name = l_rec_pospmntdet.bank_name 
					LET l_arr_rec_pospmnt2[l_idx].drawer = l_rec_pospmntdet.drawer 
					LET l_arr_rec_pospmnt2[l_idx].cheque_no = l_rec_pospmntdet.cheque_no 
			END CASE 

			LET l_arr_rec_pospmnt2[l_idx].doc_num = l_rec_pospmnts.doc_num 
			LET l_arr_rec_pospmnts[l_idx].tran_date = l_rec_pospmnts.tran_date 
			LET l_arr_rec_pospmnts[l_idx].pay_amount = l_rec_pospmnts.pay_amount 
			LET l_arr_rec_pospmnts[l_idx].locn_code = l_rec_pospmnts.locn_code 
			LET l_arr_rec_pospmnts[l_idx].station_code = l_rec_pospmnts.station_code 
			LET l_arr_rec_pospmnts[l_idx].pay_type = l_rec_pospmnts.pay_type 
			LET l_arr_rec_pospmnts[l_idx].bank_code = l_rec_pospmnts.bank_code 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF	

		END FOREACH 

		DISPLAY ARRAY l_arr_rec_pospmnts TO sr_pospmnts.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","A63","inp-arr-pospmnts") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD tran_date
				LET l_idx = arr_curr()
				IF l_idx > 0 THEN 
					LET l_rec_pospmnts.doc_num = l_arr_rec_pospmnt2[l_idx].doc_num
				END IF 
				EXIT DISPLAY 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW A695 

	RETURN l_rec_pospmnts.doc_num 
END FUNCTION 
#######################################################################
# END FUNCTION show_pospmnt(p_cmpy_code,p_bank_code)
#######################################################################


#######################################################################
# FUNCTION db_tentbankhead_get_datasource(p_filter)
#
#
#######################################################################
FUNCTION db_tentbankhead_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
		tentbankhead.bank_code, 
		tentbankhead.bank_dep_num, 
		tentbankhead.desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A64","construct-tentbankhead") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM tentbankhead ", 
		"WHERE tentbankhead.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY tentbankhead.bank_code, tentbankhead.bank_dep_num" 

	PREPARE s_tentbankhead FROM l_query_text 
	DECLARE c_tentbankhead CURSOR FOR s_tentbankhead 

	LET l_idx = 0 
	CALL l_arr_rec_tentbankhead.CLEAR()
	FOREACH c_tentbankhead INTO l_rec_tentbankhead.* 
		LET l_idx = l_idx + 1 
		INITIALIZE l_arr_rec_tentbankhead[l_idx].* TO NULL 
		LET l_arr_rec_tentbankhead[l_idx].bank_code = l_rec_tentbankhead.bank_code 
		LET l_arr_rec_tentbankhead[l_idx].bank_dep_num = l_rec_tentbankhead.bank_dep_num 
		LET l_arr_rec_tentbankhead[l_idx].desc_text = l_rec_tentbankhead.desc_text 
		IF l_rec_tentbankhead.status_ind MATCHES "[23]" THEN 
			LET l_arr_rec_tentbankhead[l_idx].status_flag = "*" 
		END IF 
		SELECT SUM(tentbankdetl.tran_amt) INTO l_arr_rec_tentbankhead[l_idx].deposit_amt 
		FROM tentbankdetl 
		WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tentbankdetl.bank_dep_num = l_rec_tentbankhead.bank_dep_num
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)#U9113 l_idx records selected

	RETURN l_arr_rec_tentbankhead

END FUNCTION
#######################################################################
# END FUNCTION db_tentbankhead_get_datasource(p_filter)
#######################################################################


#######################################################################
# FUNCTION db_tentbankdetl_get_datsource_edit_row_rec(p_filter,p_bank_dep_num)
#
#
#######################################################################
FUNCTION db_tentbankdetl_get_datsource_edit_row_rec(p_filter,p_bank_dep_num)
	DEFINE p_filter BOOLEAN
	DEFINE p_bank_dep_num LIKE tentbankhead.bank_dep_num 
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_arr_rec_tentbankdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cash_num LIKE tentbankdetl.cash_num, 
		cust_code LIKE tentbankdetl.cust_code, 
		cash_date LIKE tentbankdetl.cash_date, 
		tran_amt LIKE tentbankdetl.tran_amt, 
		cheque_text CHAR(10), 
		bank_text CHAR(15), 
		cash_type_ind CHAR(1) 
	END RECORD
	DEFINE l_arr_rec_pospmnts DYNAMIC ARRAY OF RECORD 
		doc_num INTEGER 
	END RECORD
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT	

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
		cash_num, 
		cust_code, 
		cash_date, 
		tran_amt, 
		cheque_text, 
		bank_text, 
		cash_type_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A63","construct-tentbankdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF
		
	ELSE
		LET l_where_text = " 1=1 "
	END IF
		 
	LET l_query_text = 
	"SELECT * FROM tentbankdetl ", 
	" WHERE tentbankdetl.cmpy_code = '",trim(glob_rec_kandoouser.cmpy_code),"' ", 
	" AND tentbankdetl.bank_dep_num = ",trim(p_bank_dep_num)," ", 
	" AND tentbankdetl.tran_type_ind != '0' ", 
	" AND ",l_where_text CLIPPED," ", 
	" ORDER BY tentbankdetl.cash_num,tentbankdetl.cust_code " 
 
	MESSAGE kandoomsg2("U",1002,"")#1002 " Searching database - please wait"

	PREPARE s_tentbankdetl FROM l_query_text 
	DECLARE c_tentbankdetl CURSOR FOR s_tentbankdetl 

	LET l_idx = 0 
	CALL l_arr_rec_tentbankdetl.CLEAR()
	CALL l_arr_rec_pospmnts.CLEAR()
	FOREACH c_tentbankdetl INTO l_rec_tentbankdetl.* 
		LET l_idx = l_idx + 1 
		INITIALIZE l_arr_rec_tentbankdetl[l_idx].* TO NULL 
		INITIALIZE l_arr_rec_pospmnts[l_idx].* TO NULL
		LET l_arr_rec_tentbankdetl[l_idx].cust_code = l_rec_tentbankdetl.cust_code 
		LET l_arr_rec_tentbankdetl[l_idx].cash_num = l_rec_tentbankdetl.cash_num 
		LET l_arr_rec_tentbankdetl[l_idx].cash_date = l_rec_tentbankdetl.cash_date 
		LET l_arr_rec_tentbankdetl[l_idx].tran_amt = l_rec_tentbankdetl.tran_amt 
		LET l_arr_rec_tentbankdetl[l_idx].cheque_text = l_rec_tentbankdetl.cheque_text 
		LET l_arr_rec_tentbankdetl[l_idx].bank_text = l_rec_tentbankdetl.bank_text 
		LET l_arr_rec_tentbankdetl[l_idx].cash_type_ind = l_rec_tentbankdetl.cash_type_ind 
		LET l_arr_rec_pospmnts[l_idx].doc_num = l_rec_tentbankdetl.pos_doc_num 
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected
	
	RETURN l_arr_rec_tentbankdetl, l_arr_rec_pospmnts	

END FUNCTION
#######################################################################
# END FUNCTION db_tentbankdetl_get_datsource_edit_row_rec(p_filter,p_bank_dep_num)
#######################################################################


#######################################################################
# FUNCTION insert_tentbankdetl(p_bank_code,p_type_ind,p_tran_num,p_bank_dep_num) 
#
#
#######################################################################
FUNCTION insert_tentbankdetl(p_bank_code,p_type_ind,p_tran_num,p_bank_dep_num) 
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_type_ind SMALLINT 
	DEFINE p_tran_num INTEGER 
	DEFINE p_bank_dep_num LIKE tentbankhead.bank_dep_num
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_rec_pospmnts RECORD LIKE pospmnts.*
	DEFINE l_rec_pospmnttype RECORD LIKE pospmnttype.*
	DEFINE l_rec_pospmntdet RECORD LIKE pospmntdet.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.*
	DEFINE l_err_message CHAR(60)
	DEFINE l_seq_num INTEGER
	
	SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
	WHERE tentbankhead.bank_dep_num = p_bank_dep_num 
	AND tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankhead.bank_code = p_bank_code

	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank.bank_code = l_rec_tentbankhead.bank_code 

	BEGIN WORK 

		MESSAGE kandoomsg2("U",1005,"") #1005 Updating Database; Please Wait;
		IF p_type_ind = "1" THEN 
			DECLARE c_cashreceipt CURSOR FOR 
			SELECT * FROM cashreceipt 
			WHERE cashreceipt.cash_num = p_tran_num 
			AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			OPEN c_cashreceipt 
			FETCH c_cashreceipt INTO l_rec_cashreceipt.* 
			IF STATUS = 0 THEN 
				INITIALIZE l_rec_tentbankdetl.* TO NULL 
				LET l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_2 
				DECLARE c3_pospmnts CURSOR FOR 
				SELECT * FROM pospmnts 
				WHERE pospmnts.cash_num = l_rec_cashreceipt.cash_num 
				AND pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c3_pospmnts 
				FETCH c3_pospmnts INTO l_rec_pospmnts.* 
				IF STATUS = 0 THEN 
					IF l_rec_pospmnts.bank_code != l_rec_tentbankhead.bank_code THEN 
						ERROR kandoomsg2("A",9529,"")				#9529 POS Payment does NOT belong TO this bank
						ROLLBACK WORK 
						RETURN FALSE 
					END IF 
					IF l_rec_pospmnts.banked = "Y" THEN 
						ERROR kandoomsg2("A",9007,"") 	#9007 Receipt IS banked
						ROLLBACK WORK 
						RETURN FALSE 
					END IF 
					LET l_err_message = "A63 - Updating pospmnts 3" 
					UPDATE pospmnts 
					SET pospmnts.banked = "Y", 
					pospmnts.date_banked = TODAY, 
					pospmnts.bank_dep_num = p_bank_dep_num 
					WHERE pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND pospmnts.cash_num = l_rec_cashreceipt.cash_num 

					LET l_rec_tentbankdetl.tran_type_ind = DEPOSIT_TENTBANK_TRAN_TYPE_1 
					LET l_rec_tentbankdetl.pos_doc_num = l_rec_pospmnts.doc_num 
					LET l_rec_tentbankdetl.station_code = l_rec_pospmnts.station_code 
					LET l_rec_tentbankdetl.locn_code = l_rec_pospmnts.locn_code 
					LET l_rec_tentbankdetl.pos_pay_type = l_rec_pospmnts.pay_type 
				ELSE 
					IF l_rec_cashreceipt.chq_date > TODAY THEN 
						ERROR kandoomsg2("P",9190,"")	#9190 Cheque Date IS invalid
						ROLLBACK WORK 
						RETURN FALSE 
					END IF 
					IF l_rec_cashreceipt.banked_flag = "Y" THEN 
						ERROR kandoomsg2("A",9007,"")		#9007 Receipt IS banked
						ROLLBACK WORK 
						RETURN FALSE 
					END IF 
				END IF 

				IF l_rec_cashreceipt.bank_code != l_rec_tentbankhead.bank_code THEN 
					ERROR kandoomsg2("A",9526,"") #9526 Cashreceipt does NOT belong TO this bank
					ROLLBACK WORK 
					RETURN FALSE 
				END IF 
				IF l_rec_cashreceipt.conv_qty IS NULL 
				OR l_rec_cashreceipt.conv_qty = 0 THEN 
					LET l_rec_cashreceipt.conv_qty = 1 
				END IF 
				IF l_rec_cashreceipt.cash_amt IS NULL THEN 
					LET l_rec_cashreceipt.cash_amt = 0 
				END IF 
				SELECT MAX(tentbankdetl.seq_num) INTO l_seq_num FROM tentbankdetl 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.bank_dep_num = p_bank_dep_num 
				IF l_seq_num IS NULL THEN 
					LET l_seq_num = 0 
				END IF
				 
				LET l_rec_tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentbankdetl.bank_dep_num = p_bank_dep_num 
				LET l_rec_tentbankdetl.seq_num = l_seq_num + 1 
				LET l_rec_tentbankdetl.cust_code = l_rec_cashreceipt.cust_code 
				LET l_rec_tentbankdetl.cash_num = l_rec_cashreceipt.cash_num 
				LET l_rec_tentbankdetl.cash_date = l_rec_cashreceipt.cash_date 

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
				LET l_rec_tentbankdetl.cash_type_ind = l_rec_cashreceipt.cash_type_ind 
				LET l_rec_tentbankdetl.drawer_text = l_rec_cashreceipt.drawer_text 
				LET l_rec_tentbankdetl.bank_text = l_rec_cashreceipt.bank_text 
				LET l_rec_tentbankdetl.branch_text = l_rec_cashreceipt.branch_text 
				LET l_rec_tentbankdetl.cheque_text = l_rec_cashreceipt.cheque_text 
				LET l_err_message = "A63 - Insert INTO tentbankdetl 1" 

				INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*) 
				LET l_err_message = "A63 - Updating cashreceipt 2" 
				UPDATE cashreceipt 
				SET cashreceipt.banked_flag = "Y", 
				cashreceipt.banked_date = TODAY, 
				cashreceipt.bank_dep_num = p_bank_dep_num 
				WHERE CURRENT OF c_cashreceipt
			END IF 
		ELSE 
			INITIALIZE l_rec_pospmnts.* TO NULL 
			DECLARE c4_pospmnts CURSOR FOR 
			SELECT * FROM pospmnts 
			WHERE pospmnts.doc_num = p_tran_num 
			AND pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			OPEN c4_pospmnts 
			FETCH c4_pospmnts INTO l_rec_pospmnts.* 
			IF STATUS = 0 THEN 
				IF l_rec_pospmnts.bank_code != l_rec_tentbankhead.bank_code THEN 
					ERROR kandoomsg2("A",9529,"")				#9529 POS Payment does NOT belong TO this bank
					ROLLBACK WORK 
					RETURN FALSE 
				END IF 
				IF l_rec_pospmnts.banked = "Y" THEN 
					ERROR kandoomsg2("A",9007,"")		#9007 Receipt IS banked
					ROLLBACK WORK 
					RETURN FALSE 
				END IF 
				SELECT * INTO l_rec_bank.* FROM bank 
				WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank.bank_code = l_rec_pospmnts.bank_code 
				INITIALIZE l_rec_pospmntdet.* TO NULL 
				SELECT * INTO l_rec_pospmntdet.* FROM pospmntdet 
				WHERE pospmntdet.sequence_num = l_rec_pospmnts.sequence_num 
				AND pospmntdet.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_pospmntdet.cheque_date > TODAY THEN 
					ERROR kandoomsg2("P",9190,"")		#9190 Cheque Date IS invalid
					ROLLBACK WORK 
					RETURN FALSE 
				END IF 
				SELECT * INTO l_rec_pospmnttype.* FROM pospmnttype 
				WHERE pospmnttype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND pospmnttype.pmnt_type_code = l_rec_pospmnts.pay_type 

				SELECT MAX(tentbankdetl.seq_num) INTO l_seq_num FROM tentbankdetl 
				WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankdetl.bank_dep_num = p_bank_dep_num 
				IF l_seq_num IS NULL THEN 
					LET l_seq_num = 0 
				END IF 

				## Retrieve the cash receipt RECORD FOR currency AND conversion rate
				## details.  Note that the transaction amount does NOT require
				## conversion because POS only allows receipts TO banks with the
				## same currency as the customer AND associated receipt.
				SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
				WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cashreceipt.cash_num = l_rec_pospmnts.cash_num 

				LET l_rec_tentbankdetl.currency_code = l_rec_cashreceipt.currency_code 
				LET l_rec_tentbankdetl.conv_qty = l_rec_cashreceipt.conv_qty 

				CASE l_rec_pospmnttype.pmnt_class 
					WHEN PAYMENT_TYPE_CHEQUE_Q 
						LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
						LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.drawer 
						LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.branch 
						LET l_rec_tentbankdetl.cheque_text = l_rec_pospmntdet.cheque_no 
					WHEN "P" 
						LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
						LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.card_holder 
						LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.ccard_no 
					OTHERWISE 
						LET l_rec_tentbankdetl.bank_text = l_rec_pospmntdet.bank_name 
						LET l_rec_tentbankdetl.drawer_text = l_rec_pospmntdet.drawer 
						LET l_rec_tentbankdetl.branch_text = l_rec_pospmntdet.branch 
						LET l_rec_tentbankdetl.cheque_text = l_rec_pospmntdet.cheque_no 
				END CASE 

				LET l_rec_tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_tentbankdetl.bank_dep_num = p_bank_dep_num 
				LET l_rec_tentbankdetl.seq_num = l_seq_num + 1 
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
				LET l_err_message = "A63 - Insert INTO tentbankdetl 2" 

				INSERT INTO tentbankdetl VALUES (l_rec_tentbankdetl.*) 

				LET l_err_message = "A63 - Updating pospmnts 4" 
				UPDATE pospmnts 
				SET pospmnts.banked = "Y", 
				pospmnts.date_banked = TODAY, 
				pospmnts.bank_dep_num = p_bank_dep_num 
				WHERE pospmnts.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND pospmnts.doc_num = l_rec_pospmnts.doc_num 
			END IF 
		END IF 
		
	COMMIT WORK 
	
	RETURN TRUE 

END FUNCTION 
#######################################################################
# END FUNCTION insert_tentbankdetl()
#######################################################################