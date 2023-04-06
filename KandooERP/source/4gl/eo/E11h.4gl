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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE err_message char(40) 

###########################################################################
# \brief module E11h - Updates Database with new OR Amended Sales Order
#
#                 - N.B. Insert CURSOR's have been used FOR efficiency
###########################################################################
###########################################################################
# FUNCTION insert_order() 
###########################################################################
FUNCTION insert_order() 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderlog RECORD LIKE orderlog.* 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN FALSE 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LET l_rec_orderhead.* = glob_rec_orderhead.* 
		SELECT area_code INTO l_rec_orderhead.area_code 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = glob_rec_orderhead.territory_code 
		LET l_rec_orderhead.ord_ind = "2" 
		LET l_rec_orderhead.goods_amt = 0 
		LET l_rec_orderhead.hand_amt = 0 
		LET l_rec_orderhead.hand_tax_amt = 0 
		LET l_rec_orderhead.freight_amt = 0 
		LET l_rec_orderhead.freight_tax_amt = 0 
		LET l_rec_orderhead.tax_amt = 0 
		LET l_rec_orderhead.disc_amt = 0 
		LET l_rec_orderhead.total_amt = 0 
		LET l_rec_orderhead.cost_amt = 0 
		LET l_rec_orderhead.line_num = 0 
		LET l_rec_orderhead.status_ind = "I" 
		LET err_message = "E11 - OE Params lock" 

		DECLARE c_opparms cursor FOR 
		SELECT next_ord_num FROM opparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
		FOR UPDATE 
		OPEN c_opparms 
		FETCH c_opparms INTO l_rec_orderhead.order_num 
		LET err_message = " E11 - Adding Order Header row" 

		INSERT INTO orderhead VALUES (l_rec_orderhead.*) 

		LET err_message = "E11 - Insert Order Log amendments" 
		CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,l_rec_orderhead.order_num,10,"","") 
		LET err_message = "E11 - Update Next Order number" 

		UPDATE opparms 
		SET next_ord_num = next_ord_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
		LET err_message = "E11 - Insert Hold Order Log amendments" 
		DECLARE c_orderlog cursor FOR 
		SELECT * FROM t_orderlog 

		FOREACH c_orderlog INTO l_rec_orderlog.* 
			CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, 
			l_rec_orderhead.order_num, 
			l_rec_orderlog.event_text, 
			l_rec_orderlog.curr_text, 
			l_rec_orderlog.prev_text) 
		END FOREACH 

		DELETE FROM t_orderlog 
		WHERE 1=1 

	COMMIT WORK 

	WHENEVER ERROR CONTINUE 
	LET glob_rec_orderhead.order_num = l_rec_orderhead.order_num 
	LET glob_rec_orderhead.ord_ind = l_rec_orderhead.ord_ind 
	LET glob_rec_orderhead.area_code = l_rec_orderhead.area_code 
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION insert_order()
###########################################################################


###########################################################################
# FUNCTION write_order(p_cancel)
#
#
#   The Update procedure IS as follows
#          begin transaction
#             lock the customer  (row level only)
#             lock the orderhead (row level only)
#             IF revision no. of ORDER IS NOT equal TO current THEN
#                back out (ie:another edit has been done )
#             END IF
#             IF last inv no. of ORDER IS NOT equal TO current THEN
#                back out (ie:invoice has been raised during edit )
#             END IF
#             UPDATE customer setting the onorder amt
#                = Sum of ORDER - old_order
#             back out any existing picking slips (IF permitted)
#             delete existing ORDER detail lines
#             add new ORDER detail lines
#                - (in rowid ORDER,as they appear in array)
#                - summing charges,costs,taxes
#             UPDATE orderheader row
#                setting correct VALUES FOR -revision no. & date
#                                           -status_ind (U,P,C)
#               (note a cancelled ORDER has no lines)
#             IF ORDER logging IS installed
#                log events AND amendments made TO relevant columns
#                FOR the numbers of each event refer TO E14a.4gl
#             END IF
#             IF sale commission share allowed
#                delete existing share lines
#                INSERT new share lines
#             END IF
#          commit transaction 
###########################################################################
FUNCTION write_order(p_cancel) 
	DEFINE p_cancel SMALLINT
	DEFINE l_rec_s_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_t_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_2_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_rec_saleshare RECORD LIKE saleshare.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_pick_num LIKE pickdetl.pick_num 
	DEFINE l_ware_code LIKE pickdetl.ware_code 
	DEFINE l_line_count SMALLINT 
--	DEFINE l_cnt SMALLINT 
	DEFINE l_upd_flag SMALLINT 
	DEFINE l_idx SMALLINT
	DEFINE l_reject_status SMALLINT 
	DEFINE l_errmsg STRING #error message string

	GOTO bypass 

	LABEL recovery: 
	LET glob_rec_orderhead.* = l_rec_s_orderhead.* 
	IF error_recover(err_message,status) != "Y" THEN 
		IF NOT p_cancel THEN 
			IF NOT back_out() THEN 
				RETURN -1 #back out failed do NOT EXIT MENU 
			END IF 
		END IF 
		RETURN FALSE 
	END IF 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_rec_s_orderhead.* = glob_rec_orderhead.* 
		IF p_cancel THEN 
			WHILE TRUE 
				CALL serial_init(glob_rec_kandoouser.cmpy_code, '1','1',glob_rec_orderhead.order_num) 
				LET l_upd_flag = 1 

				FOR l_idx = 1 TO glob_rec_orderhead.line_num 
					LET err_message = "E11 - SELECT ORDER detail FOR update" 
					SELECT * INTO l_rec_orderdetl.* FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = glob_rec_orderhead.order_num 
					AND line_num = l_idx 
					IF status = NOTFOUND THEN 
						GOTO recovery 
					END IF 

					CALL serial_delete(l_rec_orderdetl.part_code,l_rec_orderdetl.ware_code) 
					#IF l_rec_orderdetl.picked_qty > 0 THEN
					#   IF glob_rec_sales_order_parameter.pick_ind THEN #Reject pick slips
					#      LET l_rec_orderdetl.sched_qty = l_rec_orderdetl.sched_qty
					#                                 + l_rec_orderdetl.picked_qty
					#      LET l_rec_orderdetl.picked_qty = 0
					#   ELSE
					#      LET l_rec_orderdetl.sched_qty = l_rec_orderdetl.sched_qty
					#                                 - l_rec_orderdetl.picked_qty
					#   END IF
					#END IF
					INSERT INTO t_orderdetl VALUES (l_rec_orderdetl.*) 
					IF sqlca.sqlerrd[3] != 1 THEN 
						GOTO recovery 
					END IF 
					
					LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 
					
					IF l_upd_flag = -1 THEN 
						BEGIN WORK 
						CONTINUE WHILE 
					ELSE 
						IF l_upd_flag = 0 THEN 
							ERROR kandoomsg2("E",9264,"") 					#9264" Error occurred during cancellation"
							RETURN FALSE 
						END IF 
					END IF 

					DELETE FROM t_orderdetl WHERE line_num = l_rec_orderdetl.line_num 
					IF sqlca.sqlerrd[3] != 1 THEN 
						GOTO recovery 
					END IF 
				END FOR
					 
				EXIT WHILE 
				END WHILE
				 
			LET status = serial_return('','0') 
			LET glob_rec_orderhead.goods_amt = 0 
			LET glob_rec_orderhead.tax_amt = 0 
			LET glob_rec_orderhead.disc_amt = 0 
			LET glob_rec_orderhead.total_amt = 0 
			LET glob_rec_orderhead.freight_amt = 0 
			LET glob_rec_orderhead.freight_tax_amt = 0 
			LET glob_rec_orderhead.hand_amt = 0 
			LET glob_rec_orderhead.hand_tax_amt = 0 
			LET glob_rec_orderhead.hold_code = NULL 
		END IF 
			
			#----------------------------------------
			# IF an orderline with a pick slips has been modified than
			# remove all pick slips FOR the ORDER
			IF glob_rec_sales_order_parameter.pick_ind THEN 
				DECLARE c_pickhead cursor FOR 
				SELECT pick_num, ware_code 
				FROM pickhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND status_ind = "0" 
				AND pick_num in (select unique pick_num FROM pickdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = glob_rec_orderhead.order_num)
				 
				FOREACH c_pickhead INTO l_pick_num, l_ware_code 
					LET l_reject_status = reject_pickslip(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code, 
					l_ware_code, 
					l_pick_num) 
					IF l_reject_status < 0 THEN 
						IF l_reject_status = -1 THEN 
							LET err_message = "E11 - Consignment Note was created ", 
							"FOR picking slip" 
							GOTO recovery 
						ELSE 
							LET err_message = "E11 - Rejection of picking slip failed" 
							LET status = l_reject_status 
							GOTO recovery 
						END IF 
					END IF 
				END FOREACH 
			END IF 
			#----------------------------------------
			# Declare Insert Cursor's
			#----------------------------------------

			#----------------------------------------
			# Orderdetl
			DECLARE c_orderdetl cursor FOR 
			INSERT INTO orderdetl VALUES (l_rec_orderdetl.*) 
			OPEN c_orderdetl 
			
			#----------------------------------------
			# Saleshare
			DECLARE c_saleshare cursor FOR 
			INSERT INTO saleshare VALUES (l_rec_saleshare.*) 
			OPEN c_saleshare 
			
			#----------------------------------------
			# Orderoffer
			DECLARE c_orderoffer cursor FOR 
			INSERT INTO orderoffer VALUES (l_rec_orderoffer.*) 
			OPEN c_orderoffer 
			
			
			#----------------------------------------
			LET err_message = "E11 - Locking Customer record" 
			DECLARE c_customer cursor FOR 
			SELECT * FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_orderhead.cust_code 
			FOR UPDATE 
			OPEN c_customer 
			FETCH c_customer INTO l_rec_customer.*
			 
			IF l_rec_customer.onorder_amt IS NULL THEN 
				LET l_rec_customer.onorder_amt = 0 
			END IF 
			
			LET err_message = "E11 - Locking Order Header record" 
			DECLARE c_orderhead cursor FOR 
			SELECT * FROM orderhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = glob_rec_orderhead.order_num 
			FOR UPDATE 
			OPEN c_orderhead 
			FETCH c_orderhead INTO l_rec_t_orderhead.* 

			IF l_rec_t_orderhead.rev_num != glob_rec_orderhead.rev_num THEN 
				LET err_message = "E11 - Sales Order has changed during edit" 
			END IF 

			IF l_rec_t_orderhead.last_inv_num != glob_rec_orderhead.last_inv_num 
			OR (glob_rec_orderhead.last_inv_num IS NULL 
			AND l_rec_t_orderhead.last_inv_num IS NOT NULL ) THEN 
				LET err_message = "E11 - Sales Order has been invoiced during edit" 
				GOTO recovery 
			END IF 

			LET err_message = "E11 - Update Customer record" 

			UPDATE customer 
			SET onorder_amt = l_rec_customer.onorder_amt 
			+ (glob_rec_orderhead.total_amt 
			- glob_rec_orderhead.freight_tax_amt 
			- glob_rec_orderhead.hand_tax_amt) 
			- (l_rec_t_orderhead.total_amt 
			- l_rec_t_orderhead.freight_tax_amt 
			- l_rec_t_orderhead.hand_tax_amt) 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_orderhead.cust_code
			 
			#----------------------------------------
			# Is there a receipt
			#----------------------------------------

			LET l_rec_cashreceipt.cash_num = 0 
			SELECT * INTO l_rec_cashreceipt.* 
			FROM t_cashreceipt 
			WHERE cash_amt IS NOT NULL 
			IF status = 0 THEN 
				SELECT * INTO l_rec_customertype.* 
				FROM customertype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_customer.type_code 
				LET err_message = "E11 - Next Transaction Number generater" 
				LET l_rec_cashreceipt.cash_num = next_trans_num(
					glob_rec_kandoouser.cmpy_code,
					TRAN_TYPE_RECEIPT_CA,
					l_rec_customertype.acct_mask_code) 

				IF l_rec_cashreceipt.cash_num < 0 THEN 
					LET status = l_rec_cashreceipt.cash_num 
					GOTO recovery 
				END IF 

				LET err_message = "E11 - Cash Receipt insert" 
				LET l_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_cashreceipt.order_num = glob_rec_orderhead.order_num 
				LET l_rec_cashreceipt.applied_amt = 0 
				LET l_rec_cashreceipt.disc_amt = 0 
				LET l_rec_cashreceipt.on_state_flag = "N" 
				LET l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_NOT_POSTED_N 
				LET l_rec_cashreceipt.next_num = 0 
				LET l_rec_cashreceipt.banked_flag = "N" 

				SELECT unique 1 FROM cashreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cash_num = l_rec_cashreceipt.cash_num 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9114,"")			#9114 "transaction number exists - allocating new number
					LET l_rec_cashreceipt.cash_num = 
					next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,l_rec_customertype.acct_mask_code) 
					IF l_rec_cashreceipt.cash_num < 0 THEN 
						LET status = l_rec_cashreceipt.cash_num 
						GOTO recovery 
					END IF 
				END IF 

				INSERT INTO cashreceipt VALUES (l_rec_cashreceipt.*) 

				LET err_message =" E11 - Customer Table update" 
				DECLARE c1_customer cursor FOR 
				SELECT * FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_cashreceipt.cust_code 
				FOR UPDATE 

				OPEN c1_customer 
				FETCH c1_customer INTO l_rec_customer.* 
				LET l_rec_customer.bal_amt = l_rec_customer.bal_amt	- l_rec_cashreceipt.cash_amt 
				LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	- l_rec_cashreceipt.cash_amt 
				LET l_rec_customer.last_pay_date = l_rec_cashreceipt.cash_date 
				LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
				LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt	- l_rec_customer.bal_amt 
				LET l_rec_customer.ytdp_amt = l_rec_customer.ytdp_amt + l_rec_cashreceipt.cash_amt 
				LET l_rec_customer.mtdp_amt = l_rec_customer.mtdp_amt + l_rec_cashreceipt.cash_amt
				 
				UPDATE customer 
				SET 
					bal_amt = l_rec_customer.bal_amt, 
					last_pay_date = l_rec_customer.last_pay_date, 
					curr_amt = l_rec_customer.curr_amt, 
					next_seq_num = l_rec_customer.next_seq_num, 
					cred_bal_amt = l_rec_customer.cred_bal_amt, 
					ytdp_amt = l_rec_customer.ytdp_amt, 
					mtdp_amt = l_rec_customer.mtdp_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_cashreceipt.cust_code
				 
				LET err_message = "E11 - AR Audit Row insert" 
				LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_araudit.tran_date = l_rec_cashreceipt.cash_date 
				LET l_rec_araudit.cust_code = l_rec_cashreceipt.cust_code 
				LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
				LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
				LET l_rec_araudit.tran_text = "Cash receipt" 
				LET l_rec_araudit.tran_amt = 0 - l_rec_cashreceipt.cash_amt 
				LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
				LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
				LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
				LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
				LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
				LET l_rec_araudit.entry_date = today
				 
				INSERT INTO araudit VALUES (l_rec_araudit.*)
				 
			END IF 

			LET err_message = "E11 - Removing Existing Order Line items" 
			LET l_line_count = 0 

			DELETE FROM t3_orderdetl WHERE 1=1 

			DECLARE c1_orderdetl cursor FOR 
			SELECT * FROM orderdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_orderhead.cust_code 
			AND order_num = glob_rec_orderhead.order_num 
			FOR UPDATE 

			FOREACH c1_orderdetl INTO l_rec_orderdetl.* 
				#----------------------------------------
				# Line Audit Log - Determine IF line has been removed
				# Line will be in live table but NOT temporary table
				INITIALIZE l_rec_2_orderdetl.* TO NULL 
				SELECT * INTO l_rec_2_orderdetl.* FROM t_orderdetl 
				WHERE order_num = glob_rec_orderhead.order_num 
				AND line_num = l_rec_orderdetl.line_num 
				IF status = NOTFOUND THEN 
					IF NOT insert_line_log(
					glob_rec_kandoouser.cmpy_code,
					glob_rec_kandoouser.sign_on_code,
					l_rec_orderdetl.order_num, 
					l_rec_orderdetl.part_code, 
					l_rec_orderdetl.line_num, 
					l_rec_orderdetl.*,
					l_rec_2_orderdetl.*) THEN 
						LET err_message = "E11 - Line Log failed" 
						GOTO recovery 
					END IF 
				END IF 

				INSERT INTO t3_orderdetl VALUES (l_rec_orderdetl.*)
				 
				DELETE FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = glob_rec_orderhead.cust_code 
				AND order_num = glob_rec_orderhead.order_num 
				AND line_num = l_rec_orderdetl.line_num 
			END FOREACH 

			LET glob_rec_orderhead.line_num = 0 
			DECLARE c_t_orderdetl cursor FOR 
			SELECT * FROM t_orderdetl 
			ORDER BY line_num 

			FOREACH c_t_orderdetl INTO l_rec_orderdetl.* 
				LET l_line_count = l_line_count + 1 
				LET l_rec_orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_orderdetl.cust_code = glob_rec_orderhead.cust_code 
				LET l_rec_orderdetl.order_num = glob_rec_orderhead.order_num 

				IF l_rec_orderdetl.picked_qty > 0 THEN 
					IF glob_rec_sales_order_parameter.pick_ind THEN #reject pick slips 
						#LET l_rec_orderdetl.sched_qty = l_rec_orderdetl.sched_qty
						#                           + l_rec_orderdetl.picked_qty
						LET l_rec_orderdetl.picked_qty = 0 
					ELSE 
						LET l_rec_orderdetl.sched_qty = l_rec_orderdetl.sched_qty	- l_rec_orderdetl.picked_qty 
					END IF 
				END IF 

				IF l_rec_orderdetl.ext_tax_amt IS NULL THEN 
					LET l_rec_orderdetl.ext_tax_amt = 0 
				END IF 

				IF l_rec_orderdetl.ext_price_amt IS NULL THEN 
					LET l_rec_orderdetl.ext_price_amt = 0 
				END IF 

				IF l_rec_orderdetl.ext_cost_amt IS NULL THEN 
					LET l_rec_orderdetl.ext_cost_amt = 0 
				END IF 

				LET l_rec_orderdetl.job_code = NULL 
				LET l_rec_orderdetl.acct_code = build_mask(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.acct_override_code,	l_rec_orderdetl.acct_code ) 
				LET err_message = "E11 - Order Line Item insert" 

				INITIALIZE l_rec_2_orderdetl.* TO NULL 
				SELECT * INTO l_rec_2_orderdetl.* FROM t3_orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = glob_rec_orderhead.order_num 
				AND line_num = l_rec_orderdetl.line_num 

				IF status = NOTFOUND THEN 
					IF NOT insert_line_log(
						glob_rec_kandoouser.cmpy_code,
						glob_rec_kandoouser.sign_on_code,
						l_rec_orderdetl.order_num, 
						l_rec_orderdetl.part_code, 
						l_rec_orderdetl.line_num, 
						l_rec_orderdetl.*,l_rec_orderdetl.*) THEN 
						LET err_message = "E11 - Line Log failed" 
						GOTO recovery 
					END IF 
				ELSE 
					IF l_rec_2_orderdetl.order_qty != l_rec_orderdetl.order_qty 
					OR l_rec_2_orderdetl.unit_price_amt != l_rec_orderdetl.unit_price_amt 
					OR l_rec_2_orderdetl.unit_tax_amt != l_rec_orderdetl.unit_tax_amt THEN 

						IF NOT insert_line_log(
							glob_rec_kandoouser.cmpy_code,
							glob_rec_kandoouser.sign_on_code,
							l_rec_orderdetl.order_num, 
							l_rec_orderdetl.part_code, 
							l_rec_orderdetl.line_num, 
							l_rec_2_orderdetl.*,
							l_rec_orderdetl.*) THEN 
							LET err_message = "E11 - Line Log failded" 
							GOTO recovery 
						END IF 
					END IF 
				END IF 
	
				PUT c_orderdetl 

				SELECT unique 1 FROM product 
				WHERE part_code = l_rec_orderdetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND serial_flag = 'Y' 
				IF status <> NOTFOUND THEN 
					LET err_message = "E11h - serial_update " 
					LET l_rec_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_serialinfo.part_code = l_rec_orderdetl.part_code 
					LET l_rec_serialinfo.ware_code = glob_rec_orderhead.ware_code 
					LET l_rec_serialinfo.trans_num = l_rec_orderdetl.order_num 
					LET l_rec_serialinfo.ref_num = l_rec_orderdetl.order_num 
					LET l_rec_serialinfo.trantype_ind = "1" 
					LET status = serial_update(l_rec_serialinfo.*, 1, "") 
					IF status <> 0 THEN 
						GOTO recovery 
						LET l_errmsg = trim(l_errmsg), "Serial UPDATE Status: ", trim(status), "\nExit Program"
						CALL fgl_winmessage("ERROR",l_errmsg,"ERROR") 
						EXIT PROGRAM 
					END IF 
				END IF 

			END FOREACH 
			CLOSE c_orderdetl 
			
			LET err_message = "E11 - RETURN Serial codes" 
			LET status = serial_return("","0") 
			
			LET glob_rec_orderhead.rev_num = glob_rec_orderhead.rev_num + 1 
			LET glob_rec_orderhead.rev_date = today 
			LET glob_rec_orderhead.cost_ind = glob_rec_arparms.costings_ind 
			LET err_message = "E11 - Update Sales Order Header record" 
			LET glob_rec_orderhead.line_num = l_line_count 
	
			IF glob_rec_orderhead.line_num = 0 THEN 
				
				#----------------------------------------
				# No lines exist THEN ORDER IS cancelled
				LET glob_rec_orderhead.status_ind = "C" 
			ELSE 
				SELECT unique 1 FROM t_orderdetl 
				WHERE inv_qty != 0 
				IF sqlca.sqlcode = NOTFOUND THEN 
					
					#----------------------------------------
					# No lines shipped THEN ORDER IS unshipped
					LET glob_rec_orderhead.status_ind = "U" 
				ELSE 
					SELECT unique 1 FROM t_orderdetl 
					WHERE inv_qty != order_qty 
					IF sqlca.sqlcode = 0 THEN 
					
						#----------------------------------------
						# Incomplete lines exists so ORDER IS partial shipped
						LET glob_rec_orderhead.status_ind = "P" 
					ELSE 
						LET glob_rec_orderhead.status_ind = "C" 
					END IF 
				END IF 
			END IF 
	
			IF glob_rec_orderhead.sales_code IS NULL THEN 
				LET glob_rec_orderhead.sales_code = l_rec_customer.sale_code 
			END IF 
	
			IF glob_rec_orderhead.territory_code IS NULL THEN 
				LET glob_rec_orderhead.territory_code = l_rec_customer.territory_code 
			END IF 
	
			IF glob_rec_orderhead.delivery_ind IS NULL THEN 
				LET glob_rec_orderhead.delivery_ind = "1" 
			END IF 
	
			UPDATE orderhead SET * = glob_rec_orderhead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = glob_rec_orderhead.order_num 
			LET err_message = "E11 - Insert Order Log amendments" 
	
			IF l_rec_t_orderhead.status_ind = "I" THEN 
				LET l_rec_t_orderhead.cond_code = l_rec_customer.cond_code 
				LET l_rec_t_orderhead.sales_code = l_rec_customer.sale_code 
				LET l_rec_t_orderhead.territory_code = l_rec_customer.territory_code 
			ELSE 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,20,"","") 
			END IF 
	
			IF (glob_rec_orderhead.cond_code IS NULL AND l_rec_t_orderhead.cond_code IS NOT null) 
			OR (l_rec_t_orderhead.cond_code IS NULL AND glob_rec_orderhead.cond_code IS NOT null) 
			OR glob_rec_orderhead.cond_code != l_rec_t_orderhead.cond_code THEN 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,21, 
				glob_rec_orderhead.cond_code, 
				l_rec_t_orderhead.cond_code) 
			END IF 
	
			IF glob_rec_orderhead.sales_code != l_rec_t_orderhead.sales_code THEN 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,22, 
				glob_rec_orderhead.sales_code, 
				l_rec_t_orderhead.sales_code) 
			END IF 
	
			IF glob_rec_orderhead.territory_code != l_rec_t_orderhead.territory_code THEN 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,23, 
				glob_rec_orderhead.territory_code, 
				l_rec_t_orderhead.territory_code) 
			END IF 

			IF glob_rec_orderhead.freight_amt != l_rec_t_orderhead.freight_amt THEN 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,24, 
				glob_rec_orderhead.freight_amt, 
				l_rec_t_orderhead.freight_amt) 
			END IF 

			IF glob_rec_orderhead.hand_amt != l_rec_t_orderhead.hand_amt THEN 
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,25, 
				glob_rec_orderhead.hand_amt, 
				l_rec_t_orderhead.hand_amt) 
			END IF 

			CASE 
				WHEN glob_rec_orderhead.hold_code IS NULL AND 
					l_rec_t_orderhead.hold_code IS NOT NULL 
					CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,27, 
					glob_rec_orderhead.hold_code, 
					l_rec_t_orderhead.hold_code) 
				WHEN l_rec_t_orderhead.hold_code IS NULL AND 
					glob_rec_orderhead.hold_code IS NOT NULL 
					CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,28, 
					glob_rec_orderhead.hold_code, 
					l_rec_t_orderhead.hold_code) 
				WHEN glob_rec_orderhead.hold_code != l_rec_t_orderhead.hold_code 
					CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,26, 
					glob_rec_orderhead.hold_code, 
					l_rec_t_orderhead.hold_code) 
			END CASE
			 
			SELECT unique 1 FROM t_orderdetl 
			IF status = NOTFOUND THEN 
			
				#----------------------------------------
				# No lines exist so ORDER IS cancelled
				CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_orderhead.order_num,12,"","") 
			END IF 
			
			LET err_message = "E11 - Delete Sales Share rows" 
			
			DELETE FROM saleshare 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = glob_rec_orderhead.order_num 
			LET err_message = "E11 - Insert Sales Share rows" 
			SELECT unique 1 FROM t_saleshare 
			IF sqlca.sqlcode = 0 THEN 
				DECLARE c1_saleshare cursor FOR 
				SELECT * FROM t_saleshare 
				WHERE sale_code IS NOT NULL 
				FOREACH c1_saleshare INTO l_rec_saleshare.* 
					IF l_rec_saleshare.share_per != 100 
					OR l_rec_saleshare.sale_code != glob_rec_orderhead.sales_code THEN 
						LET l_rec_saleshare.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_saleshare.order_num = glob_rec_orderhead.order_num 
						IF l_rec_saleshare.share_per IS NULL THEN 
							LET l_rec_saleshare.share_per = 0 
						END IF 
						PUT c_saleshare 
					END IF 
				END FOREACH 
			END IF
			 
			CLOSE c_saleshare 
			LET err_message = "E11 - Delete Order Offer rows" 

			DELETE FROM orderoffer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = glob_rec_orderhead.order_num 

			LET err_message = "E11 - Insert Order Offer rows" 

			DECLARE c_orderpart cursor FOR 
			SELECT 
				"", 
				"", 
				offer_code, 
				disc_ind, 
				offer_qty, 
				disc_per, 
				bonus_amt 
			FROM t_orderpart 
			WHERE offer_qty > 0 AND offer_code != "###" 
			
			FOREACH c_orderpart INTO l_rec_orderoffer.* 
				LET l_rec_orderoffer.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_orderoffer.order_num = glob_rec_orderhead.order_num 

				IF l_rec_orderoffer.disc_per IS NULL THEN 
					LET l_rec_orderoffer.disc_per = 0 
				END IF 

				IF l_rec_orderoffer.bonus_amt IS NULL THEN 
					LET l_rec_orderoffer.bonus_amt = 0 
				END IF 

				SELECT sum(order_qty*list_price_amt), 
				sum(sold_qty* unit_price_amt) 
				INTO l_rec_orderoffer.gross_amt, 
				l_rec_orderoffer.net_amt 
				FROM t_orderdetl 
				WHERE offer_code = l_rec_orderoffer.offer_code 
				PUT c_orderoffer 
			END FOREACH
			 
			CLOSE c_orderoffer 
		
		COMMIT WORK 
		
		WHENEVER ERROR stop
		 
		RETURN glob_rec_orderhead.order_num 
END FUNCTION 
###########################################################################
# END FUNCTION write_order(p_cancel)
###########################################################################


###########################################################################
# FUNCTION back_out()
#
# 
###########################################################################
FUNCTION back_out() 
	DEFINE l_line_num INTEGER 
	DEFINE l_upd_flag INTEGER
	
	GOTO bypass 
	LABEL recovery: 
	ROLLBACK WORK 
	RETURN FALSE 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	WHILE TRUE 
		DECLARE c_backout cursor with hold FOR 
		SELECT line_num FROM t_orderdetl 
		LET l_upd_flag = 1 

		BEGIN WORK 

			FOREACH c_backout INTO l_line_num 
				LET l_upd_flag = stock_line(l_line_num,TRAN_TYPE_INVOICE_IN,1) 
				IF l_upd_flag = -1 THEN 
					CONTINUE WHILE 
				ELSE 
					IF l_upd_flag = 0 THEN 
						RETURN FALSE 
					END IF 
				END IF 
			END FOREACH 

			LET l_upd_flag = stock_line(glob_rec_orderhead.order_num,TRAN_TYPE_ORDER_ORD,1) 
			IF l_upd_flag = -1 THEN 
				CONTINUE WHILE 
			ELSE 
				IF l_upd_flag = 0 THEN 
					RETURN FALSE 
				END IF 
			END IF 
			LET err_message = "E11 - Update Order head" 
			
			UPDATE orderhead 
			SET status_ind = glob_status_ind 
			WHERE order_num = glob_rec_orderhead.order_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		COMMIT WORK 

		WHENEVER ERROR stop 
		EXIT WHILE 
	END WHILE 
	
	RETURN TRUE 
END FUNCTION
###########################################################################
# END FUNCTION back_out()
###########################################################################