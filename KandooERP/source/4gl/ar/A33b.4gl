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
GLOBALS "../ar/A31_GLOBALS.4gl" 
GLOBALS "../ar/A33_GLOBALS.4gl" 

############################################################
# FUNCTION dist_receipt()
#
#Program A33b.4gl - New Accounts Receivable Revenue Distribution
#                   FOR sundry receipts.
############################################################
FUNCTION dist_receipt() 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_rec_s_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_cashreceipt RECORD LIKE invoicedetl.* 
	DEFINE l_rec_s_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_arr_rec_invoicedetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE invoicedetl.line_num, 
		line_acct_code LIKE invoicedetl.line_acct_code, 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_repeat_ind SMALLINT 
	DEFINE l_temp_text CHAR(20) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_style STRING
	
	CALL db_bank_get_rec(UI_OFF,glob_rec_cashreceipt.bank_code) RETURNING l_rec_bank.* 
	 
	DISPLAY BY NAME 
		glob_rec_cashreceipt.bank_code, 
		glob_rec_cashreceipt.cash_amt, 
		glob_rec_cashreceipt.applied_amt
	 
	DISPLAY l_rec_bank.name_acct_text TO bank.name_acct_text 
	DISPLAY BY NAME glob_rec_cashreceipt.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it
	 
	MESSAGE kandoomsg2("A",1002,"") #A1002 Searching database - Please Wait

	DECLARE c_t_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl 
	ORDER BY line_num 

	WHILE true 
		LET l_idx = 0 
		LET l_repeat_ind = false 
		OPEN c_t_invoicedetl 

		FOREACH c_t_invoicedetl INTO l_rec_cashreceipt.* 
			LET l_idx = l_idx + 1 
			UPDATE t_invoicedetl 
			SET line_num = l_idx 
			WHERE line_num = l_rec_cashreceipt.line_num 
			
			LET l_arr_rec_invoicedetl[l_idx].line_num = l_idx 
			LET l_arr_rec_invoicedetl[l_idx].line_acct_code = l_rec_cashreceipt.line_acct_code 
			LET l_arr_rec_invoicedetl[l_idx].line_text = l_rec_cashreceipt.line_text 
			LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = l_rec_cashreceipt.unit_sale_amt 
		END FOREACH 


		# INPUT ARRAY ------------------------------------------------------------------------------------------
		MESSAGE kandoomsg2("A",1060,"") 	#A1060 F1 Add F2 Delete F10 Disburse
		INPUT ARRAY l_arr_rec_invoicedetl WITHOUT DEFAULTS FROM sr_invoicedetl.* ATTRIBUTE(UNBUFFERED, auto append = false, insert row = false) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A33b","inp-invoicedetl") 

			BEFORE ROW 
				LET l_idx = arr_curr() 

				SELECT * INTO l_rec_cashreceipt.* FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				IF status = NOTFOUND THEN 
					INITIALIZE l_rec_cashreceipt.* TO NULL 
				END IF 

				LET l_rec_s_invoicedetl.* = l_rec_cashreceipt.* 

				SELECT sum(unit_sale_amt) INTO glob_rec_cashreceipt.applied_amt 
				FROM t_invoicedetl 
				IF glob_rec_cashreceipt.applied_amt IS NULL THEN 
					LET glob_rec_cashreceipt.applied_amt = 0 
				END IF 
				
				DISPLAY BY NAME glob_rec_cashreceipt.applied_amt

			AFTER ROW 
				SELECT unique 1 FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				IF status = NOTFOUND THEN 
					INITIALIZE l_arr_rec_invoicedetl[l_idx].* TO NULL 
				END IF 
				#DISPLAY l_arr_rec_invoicedetl[l_idx].* TO sr_invoicedetl[scrn].*

			AFTER INPUT 
				#DEL & ESC go back TO scroll_flag IF CURSOR NOT on scroll_flag
				IF int_flag OR quit_flag THEN 
						
--					IF NOT infield(scroll_flag) THEN 

					IF l_idx > 0 THEN

						LET int_flag = false 
						LET quit_flag = false 
					
						DELETE FROM t_invoicedetl 
						WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
					
						IF l_rec_s_invoicedetl.line_acct_code IS NOT NULL THEN 
							LET l_arr_rec_invoicedetl[l_idx].line_num = l_rec_s_invoicedetl.line_num 
							LET l_arr_rec_invoicedetl[l_idx].line_acct_code =		l_rec_s_invoicedetl.line_acct_code 
							LET l_arr_rec_invoicedetl[l_idx].line_text = 	l_rec_s_invoicedetl.line_text 
							LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt =l_rec_s_invoicedetl.unit_sale_amt 
							#DISPLAY l_arr_rec_invoicedetl[l_idx].* TO sr_invoicedetl[scrn].*

							INSERT INTO t_invoicedetl VALUES (l_rec_s_invoicedetl.*) 

						ELSE 
							FOR i = arr_curr() TO arr_count() 
								IF l_arr_rec_invoicedetl[i+1].line_acct_code IS NOT NULL THEN 
									LET l_arr_rec_invoicedetl[i].* = l_arr_rec_invoicedetl[i+1].* 
								ELSE 
									INITIALIZE l_arr_rec_invoicedetl[i].* TO NULL 
								END IF 
								#IF scrn <= 7 THEN
								#   DISPLAY l_arr_rec_invoicedetl[i].* TO sr_invoicedetl[scrn].*
								#
								#   LET scrn = scrn + 1
								#END IF
							END FOR 
							#LET scrn = scr_line()
						END IF 
						--NEXT FIELD scroll_flag 

					END IF #l_idx > 0
					 
				ELSE #NOT int_flag OR quit_flag 

					CASE #Note: there is a mess in the original error messages...
						WHEN glob_rec_cashreceipt.applied_amt > glob_rec_cashreceipt.cash_amt 
							CALL fgl_winmessage("ERROR #A9216","#A9216 Receipt Distributions exceed receipt total","ERROR") 
							ERROR kandoomsg2("A",9216,"") 					#A9216" Receipt Distributions exceed receipt total
							CONTINUE INPUT

						WHEN glob_rec_cashreceipt.applied_amt != glob_rec_cashreceipt.cash_amt 
							CALL fgl_winmessage("ERROR #A9216",kandoomsg2("A",9216,""),"ERROR") 
							ERROR kandoomsg2("A",9216,"") 					#A9216" Receipt Distributions exceed receipt total
							CONTINUE INPUT
						
						OTHERWISE
							MESSAGE "Receipt Total matches the Applied Total"
							SLEEP 1
							  
					END CASE
					 
				END IF 

			#-------------------------------------------------------------------------------------------------------------------------
			# ACTIONS/KEY Events
			#------------------------------------------------------------------------------------------------------------------------- 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (line_acct_code) 
				LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
				IF l_temp_text IS NOT NULL THEN 
					LET l_arr_rec_invoicedetl[l_idx].line_acct_code = l_temp_text 
					NEXT FIELD line_acct_code 
				END IF 

			ON ACTION "NOTES" infield (line_text) ----ON KEY (control-n) infield (line_text) 
				LET l_arr_rec_invoicedetl[l_idx].line_text = sys_noter(glob_rec_kandoouser.cmpy_code,l_arr_rec_invoicedetl[l_idx].line_text) 
				NEXT FIELD line_text 

			ON ACTION "F10-Disburse Dist" 
				--         ON KEY(F10)
				IF disburse_dist() THEN 
					LET l_repeat_ind = true 
					EXIT INPUT 
				END IF 



			BEFORE INSERT 
				INITIALIZE l_rec_cashreceipt.* TO NULL 
				INITIALIZE l_rec_s_invoicedetl.* TO NULL 
				INITIALIZE l_arr_rec_invoicedetl[l_idx].* TO NULL 
				--## code b/t comments exists as w/around TO informix bug
				--IF fgl_lastkey() = fgl_keyval("delete") THEN 
				--	NEXT FIELD scroll_flag 
				--END IF 
				--## code b/t comments exists as w/around TO informix bug
				--NEXT FIELD line_acct_code 

{
			#Moved to BEFORE ROW
			BEFORE FIELD scroll_flag 
				SELECT * INTO l_rec_cashreceipt.* FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				IF status = NOTFOUND THEN 
					INITIALIZE l_rec_cashreceipt.* TO NULL 
				END IF 

				LET l_rec_s_invoicedetl.* = l_rec_cashreceipt.* 

				SELECT sum(unit_sale_amt) INTO glob_rec_cashreceipt.applied_amt 
				FROM t_invoicedetl 
				IF glob_rec_cashreceipt.applied_amt IS NULL THEN 
					LET glob_rec_cashreceipt.applied_amt = 0 
				END IF 
				
				DISPLAY BY NAME glob_rec_cashreceipt.applied_amt 
}

			#-------------------------------------------------------------------------------------------------------------------------
			# BEFORE/AFTER FIELD Events
			#------------------------------------------------------------------------------------------------------------------------- 

			BEFORE FIELD line_acct_code 
				INITIALIZE l_rec_coa.* TO NULL 

				IF l_arr_rec_invoicedetl[l_idx].line_num IS NULL OR l_arr_rec_invoicedetl[l_idx].line_num = 0 THEN 
					SELECT (max(line_num)+1) 
					INTO l_arr_rec_invoicedetl[l_idx].line_num 
					FROM t_invoicedetl 
					
					IF l_arr_rec_invoicedetl[l_idx].line_num IS NULL THEN 
						LET l_arr_rec_invoicedetl[l_idx].line_num = 1 
					END IF 
					
					LET l_arr_rec_invoicedetl[l_idx].line_text = "" 
					LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = 0 
					#DISPLAY l_arr_rec_invoicedetl[l_idx].* TO sr_invoicedetl[scrn].*

					LET l_rec_cashreceipt.line_num = l_arr_rec_invoicedetl[l_idx].line_num 
					INSERT INTO t_invoicedetl VALUES (l_rec_cashreceipt.*) 
				ELSE 
					SELECT * INTO l_rec_coa.* FROM coa 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND acct_code = l_arr_rec_invoicedetl[l_idx].line_acct_code 
				END IF 

			AFTER FIELD line_acct_code 
				IF l_arr_rec_invoicedetl[l_idx].line_acct_code IS NULL THEN 
					ERROR kandoomsg2("A",9127,"") 			#A9127" Account must be entered - Try Window"
					NEXT FIELD line_acct_code 
				END IF 

				CALL verify_acct_code(
					glob_rec_kandoouser.cmpy_code,
					l_arr_rec_invoicedetl[l_idx].line_acct_code, 
					glob_rec_cashreceipt.year_num, 
					glob_rec_cashreceipt.period_num) 
				RETURNING l_rec_coa.* 

				IF l_rec_coa.acct_code IS NULL THEN 
					NEXT FIELD line_acct_code 
				END IF 

				IF l_arr_rec_invoicedetl[l_idx].line_acct_code != l_rec_coa.acct_code THEN 
					LET l_arr_rec_invoicedetl[l_idx].line_acct_code = l_rec_coa.acct_code 
					LET l_arr_rec_invoicedetl[l_idx].line_text = NULL 
					NEXT FIELD line_acct_code 
				END IF 

				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD line_acct_code 
				END IF 

				UPDATE t_invoicedetl 
				SET line_acct_code = l_arr_rec_invoicedetl[l_idx].line_acct_code 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD scroll_flag 
					OTHERWISE 
						NEXT FIELD line_acct_code 
				END CASE 

			BEFORE FIELD line_text 
				IF l_arr_rec_invoicedetl[l_idx].line_text IS NULL THEN 
					LET l_arr_rec_invoicedetl[l_idx].line_text=l_rec_coa.desc_text 
				END IF 

			AFTER FIELD line_text 
				UPDATE t_invoicedetl 
				SET line_text = l_arr_rec_invoicedetl[l_idx].line_text 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 

--				CASE 
--					WHEN fgl_lastkey() = fgl_keyval("accept") 
--						NEXT FIELD scroll_flag 
--					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
--						OR fgl_lastkey() = fgl_keyval("right") 
--						OR fgl_lastkey() = fgl_keyval("tab") 
--						OR fgl_lastkey() = fgl_keyval("down") 
--						NEXT FIELD NEXT 
--					WHEN fgl_lastkey() = fgl_keyval("left") 
--						OR fgl_lastkey() = fgl_keyval("up") 
--						NEXT FIELD previous 
--					OTHERWISE 
--						NEXT FIELD line_text 
--				END CASE 

			BEFORE FIELD unit_sale_amt 
				IF l_arr_rec_invoicedetl[l_idx].unit_sale_amt = 0 THEN 
					LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = glob_rec_cashreceipt.cash_amt - glob_rec_cashreceipt.applied_amt 
				END IF 

			AFTER FIELD unit_sale_amt 
				IF l_arr_rec_invoicedetl[l_idx].unit_sale_amt IS NULL THEN 
					LET l_arr_rec_invoicedetl[l_idx].unit_sale_amt = 0 
				END IF 

				UPDATE t_invoicedetl 
				SET unit_sale_amt = l_arr_rec_invoicedetl[l_idx].unit_sale_amt 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 

				SELECT unique 1 FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				IF status = NOTFOUND THEN 
					INITIALIZE l_arr_rec_invoicedetl[l_idx].* TO NULL 
				END IF 

				SELECT * INTO l_rec_cashreceipt.* FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				IF status = NOTFOUND THEN 
					INITIALIZE l_rec_cashreceipt.* TO NULL 
				END IF 

				LET l_rec_s_invoicedetl.* = l_rec_cashreceipt.* 

				SELECT sum(unit_sale_amt) INTO glob_rec_cashreceipt.applied_amt 
				FROM t_invoicedetl 
				IF glob_rec_cashreceipt.applied_amt IS NULL THEN 
					LET glob_rec_cashreceipt.applied_amt = 0 
				END IF 
				
				CASE
					WHEN glob_rec_cashreceipt.cash_amt < glob_rec_cashreceipt.applied_amt 
						LET l_style = ATTRIBUTE_ERROR
					WHEN glob_rec_cashreceipt.cash_amt > glob_rec_cashreceipt.applied_amt
						LET l_style = ATTRIBUTE_WARNING 
					WHEN glob_rec_cashreceipt.cash_amt = glob_rec_cashreceipt.applied_amt
						LET l_style = ATTRIBUTE_OK 
				END CASE
	
				DISPLAY BY NAME glob_rec_cashreceipt.applied_amt ATTRIBUTE(STYLE=l_style)

	
--				CASE 
--					WHEN fgl_lastkey() = fgl_keyval("accept") 
--						NEXT FIELD scroll_flag 
--					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
--						OR fgl_lastkey() = fgl_keyval("right") 
--						OR fgl_lastkey() = fgl_keyval("tab") 
--						OR fgl_lastkey() = fgl_keyval("down") 
--						NEXT FIELD NEXT 
--					WHEN fgl_lastkey() = fgl_keyval("left") 
--						OR fgl_lastkey() = fgl_keyval("up") 
--						NEXT FIELD previous 
--					OTHERWISE 
--						NEXT FIELD unit_sale_amt 
--				END CASE 

			BEFORE DELETE 
				DELETE FROM t_invoicedetl 
				WHERE line_num = l_arr_rec_invoicedetl[l_idx].line_num 
				INITIALIZE l_arr_rec_invoicedetl[l_idx].* TO NULL 
				NEXT FIELD scroll_flag 


		END INPUT 

		#---------------------------
		DELETE FROM t_invoicedetl #Remove invalid lines
		WHERE line_acct_code IS NULL 
		OR unit_sale_amt IS NULL 

		IF NOT l_repeat_ind THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION dist_receipt()
############################################################


############################################################
# FUNCTION disburse_dist()
#
#
############################################################
FUNCTION disburse_dist() 
	DEFINE l_rec_disbdetl RECORD LIKE disbdetl.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_total_qty LIKE disbhead.total_qty 
	DEFINE l_temp_amt LIKE invoicedetl.unit_sale_amt 
	DEFINE l_line_num SMALLINT 

	LET l_temp_amt = glob_rec_cashreceipt.cash_amt - glob_rec_cashreceipt.applied_amt 
	CALL enter_disb(glob_rec_kandoouser.cmpy_code,"",l_temp_amt) RETURNING l_rec_disbdetl.disb_code,l_temp_amt
	 
	IF l_rec_disbdetl.disb_code IS NOT NULL AND l_temp_amt != 0 THEN 
		SELECT total_qty INTO l_total_qty 
		FROM disbhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 
		
		DECLARE c_disbdetl CURSOR FOR 
		SELECT * FROM disbdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND disb_code = l_rec_disbdetl.disb_code 
		SELECT max(line_num) INTO l_line_num 
		FROM t_invoicedetl 
		
		IF l_line_num IS NULL THEN 
			LET l_line_num = 0 
		END IF 
		
		FOREACH c_disbdetl INTO l_rec_disbdetl.* 
	
			INITIALIZE l_rec_invoicedetl.* TO NULL 
	
			LET l_line_num = l_line_num + 1 
			LET l_rec_invoicedetl.line_num = l_line_num 
			LET l_rec_invoicedetl.line_acct_code = l_rec_disbdetl.acct_code 
			LET l_rec_invoicedetl.line_text = l_rec_disbdetl.desc_text 
			LET l_rec_invoicedetl.unit_sale_amt = l_temp_amt * (l_rec_disbdetl.disb_qty/l_total_qty) 
			
			IF l_rec_invoicedetl.unit_sale_amt IS NULL THEN 
				LET l_rec_invoicedetl.unit_sale_amt = 0 
			END IF 
			
			#-----------------------------------------------------
			INSERT INTO t_invoicedetl VALUES (l_rec_invoicedetl.*) 
		END FOREACH 
		
		RETURN true 
	ELSE 
		RETURN false 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION disburse_dist()
############################################################