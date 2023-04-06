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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E53_GLOBALS.4gl" 
###########################################################################
# GLOBAL Scope Variables
###########################################################################
--DEFINE modu_err_message char(60) 
###########################################################################
# FUNCTION load_tables(p_cmpy,p_kandoouser_sign_on_code,p_verbose_ind,p_order_text,p_pick_text)
#
#
#
#  This FUNCTION load up two temp tables
#             -  t_inv_head  -> proposed invoice header
#             -  t_inv_detl  -> proposed invoice details
#  on confirmation each entry in the above tables IS TO become
#  entries in the invoicehead AND invoicedetl respectively.
#
#  The "t_inv_head.invoice_ind" field indicates the invoice
#  type TO be created ie: 1 -> normal picked stock  (incl.non-invent)
#                         2 -> non-invent,non-stked (IF no type 1 exists)
#                         3 -> predelivered items only
#                         4 -> negative quantity lines (proposed credit)
#
#  The passed filters are used TO control the amount of data loaded
#  INTO the temp tables.  Table load takes a WHILE IF filters are
#  omitted OR user does NOT enter any selection criteria.
#
# N.B. Insert Cursor's have NOT been Closed since COMMIT WORK
#      will automatically close them. Although this IS NOT good
#      practice ( since they should be Close'd TO verify
#      successful execution ), the Insert's are only done on temp
#      tables.
#
# N.B. Begin & COMMIT WORK required FOR the Insert Cursors
#
# FUNCTION has a finite limit (100) invoices TO be inserted FOR
# performance reasons
###########################################################################
FUNCTION load_tables(p_cmpy,p_kandoouser_sign_on_code,p_verbose_ind,p_order_text,p_pick_text) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE p_verbose_ind SMALLINT
	DEFINE p_order_text char(200)
	DEFINE p_pick_text char(200)
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.*
	DEFINE l_rec_pickhead RECORD LIKE pickhead.*
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.*
--	DEFINE glob_rec_opparms RECORD LIKE opparms.*
	DEFINE l_rec_inv_head RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		invoice_ind SMALLINT, 
		cust_code char(8), 
		order_num INTEGER, 
		pick_date DATE, 
		hold_code char(3), 
		calc_freight_amt decimal(16,2), 
		freight_amt decimal(16,2), 
		calc_hand_amt decimal(16,2), 
		hand_amt decimal(16,2), 
		ship_date DATE, 
		inv_date DATE, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		com1_text char(30), 
		com2_text char(30), 
		batch_num INTEGER 
	END RECORD 
	DEFINE l_rec_inv_detl RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		order_num INTEGER, 
		order_line_num INTEGER, 
		order_rev_num INTEGER, 
		last_inv_num INTEGER, 
		order_date DATE, 
		part_code char(15), 
		picked_qty FLOAT, 
		sold_qty FLOAT, 
		offer_code char(3), 
		reduce_inv_flag char(1) 
	END RECORD 
	DEFINE l_query_text char(400) 
	DEFINE l_update_header char 
	DEFINE l_rowid INTEGER 
	DEFINE l_status INTEGER 
	DEFINE l_ord_num LIKE orderhead.order_num 
	DEFINE l_inv_cnt SMALLINT 

	### Declare dynamic cursors

	##1 SELECT pickdetl
	LET l_query_text = 
		"SELECT * FROM pickdetl ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ware_code = ? ", 
		"AND pick_num = ? " 
	PREPARE s_pickdetl FROM l_query_text 
	DECLARE c_pickdetl cursor FOR s_pickdetl 

	##2 SELECT orderhead
	LET l_query_text = 
		"SELECT * FROM orderhead ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND order_num = ? " 
	PREPARE s1_orderhead FROM l_query_text 
	DECLARE c1_orderhead cursor FOR s1_orderhead 

	##3 SELECT offer (offer only)
	LET l_query_text = 
		"SELECT offer_code FROM orderdetl ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND order_num = ? ", 
		"AND line_num = ? " 
	PREPARE s0_orderdetl FROM l_query_text 
	DECLARE c0_orderdetl cursor FOR s0_orderdetl 

	##4 Does ORDER already exist in prev invoice
	LET l_query_text = "SELECT 1 FROM t_inv_detl WHERE order_num = ?" 
	PREPARE s0_tinvdetl FROM l_query_text 
	DECLARE c0_tinvdetl cursor FOR s0_tinvdetl 

	##5 Update t_inv_head with freight & stuff
	LET l_query_text = 
		"UPDATE t_inv_head ", 
		"SET order_num=?,", 
		"hold_code=?,", 
		"com1_text=?,", 
		"com2_text=?,", 
		"calc_freight_amt=?,", 
		"freight_amt=?,", 
		"calc_hand_amt=?,", 
		"batch_num=?,", 
		"hand_amt=? ", 
		"WHERE rowid = ? " 
	PREPARE s_tinvhead FROM l_query_text 
	BEGIN WORK 

		DECLARE s1_t_invdetl cursor FOR 
		INSERT INTO t_inv_detl VALUES (l_rowid,l_rec_inv_detl.*) 
		OPEN s1_t_invdetl 
		##
		LET l_inv_cnt = 0 
		LET l_query_text = 
			"SELECT * FROM pickhead ", 
			"WHERE cmpy_code = '",p_cmpy,"' ", 
			"AND status_ind = '0' ", 
			"AND ",p_pick_text clipped," ", 
			"ORDER BY pick_date,", 
			"ware_code,", 
			"pick_num" 
		PREPARE s0_pickhead FROM l_query_text 
		DECLARE c0_pickhead cursor with hold FOR s0_pickhead
		 
		FOREACH c0_pickhead INTO l_rec_pickhead.* 
			LET l_rec_inv_head.ware_code = l_rec_pickhead.ware_code 
			LET l_rec_inv_head.pick_num = l_rec_pickhead.pick_num 
			LET l_rec_inv_head.batch_num = l_rec_pickhead.batch_num 
			LET l_rec_inv_head.invoice_ind = 1 
			LET l_rec_inv_head.cust_code = l_rec_pickhead.cust_code 
			LET l_rec_inv_head.order_num = NULL 
			LET l_rec_inv_head.pick_date = l_rec_pickhead.pick_date 
			LET l_rec_inv_head.hold_code = NULL 
			LET l_rec_inv_head.calc_freight_amt = 0 
			LET l_rec_inv_head.freight_amt = 0 
			LET l_rec_inv_head.calc_hand_amt = 0 
			LET l_rec_inv_head.hand_amt = 0 
			LET l_rec_inv_head.ship_date = today 
			IF l_rec_inv_head.pick_date > today THEN 
				LET l_rec_inv_head.inv_date = l_rec_inv_head.pick_date 
			ELSE 
				LET l_rec_inv_head.inv_date = today 
			END IF 

			INSERT INTO t_inv_head VALUES (l_rec_inv_head.*) 

			LET l_rowid = sqlca.sqlerrd[6] 
			LET l_inv_cnt = l_inv_cnt + 1 

			OPEN c_pickdetl USING 
				l_rec_pickhead.ware_code, 
				l_rec_pickhead.pick_num 
			LET l_ord_num = NULL 
			LET l_update_header = 'Y' 

			FOREACH c_pickdetl INTO l_rec_pickdetl.* 
				IF l_ord_num IS NULL OR l_ord_num != l_rec_pickdetl.order_num THEN 
					OPEN c1_orderhead USING l_rec_pickdetl.order_num 
					FETCH c1_orderhead INTO l_rec_orderhead.*
					 
					IF l_rec_orderhead.status_ind = "X" THEN 
						DELETE FROM t_inv_head WHERE rowid = l_rowid 
						DELETE FROM t_inv_detl WHERE inv_rowid = l_rowid 
						LET l_update_header = 'N' 
						EXIT FOREACH 
					END IF
					 
					LET l_ord_num = l_rec_pickdetl.order_num
					 
					IF l_rec_orderhead.rev_num != l_rec_pickdetl.order_rev_num THEN 
						# Not worried IF any DB I/O in FUNCTION reject_pickslip fails
						## Code should never get TO this point as ORDER edit should
						## reject any pickslips FOR the ORDER being editted
						#LET l_status = reject_pickslip(p_cmpy,p_kandoouser_sign_on_code,l_rec_pickhead.ware_code,
						#                                          l_rec_pickhead.pick_num)
						DELETE FROM t_inv_head WHERE rowid = l_rowid 
						DELETE FROM t_inv_detl WHERE inv_rowid = l_rowid 
						LET l_update_header = 'N' 
						EXIT FOREACH 
					END IF 
					IF l_rec_orderhead.hold_code IS NOT NULL THEN 
						LET l_rec_inv_head.hold_code = l_rec_orderhead.hold_code 
					END IF 
				END IF 

				LET l_rec_inv_detl.ware_code = l_rec_pickhead.ware_code 
				LET l_rec_inv_detl.pick_num = l_rec_pickhead.pick_num 
				LET l_rec_inv_detl.order_num = l_rec_pickdetl.order_num 
				LET l_rec_inv_detl.order_line_num = l_rec_pickdetl.order_line_num 
				LET l_rec_inv_detl.order_rev_num = l_rec_pickdetl.order_rev_num 
				LET l_rec_inv_detl.last_inv_num = l_rec_orderhead.last_inv_num 
				LET l_rec_inv_detl.order_date = l_rec_pickdetl.order_date 
				LET l_rec_inv_detl.part_code = l_rec_pickdetl.part_code 
				LET l_rec_inv_detl.picked_qty = l_rec_pickdetl.picked_qty 
				LET l_rec_inv_detl.sold_qty = l_rec_pickdetl.picked_qty 

				OPEN c0_orderdetl USING 
					l_rec_inv_detl.order_num, 
					l_rec_inv_detl.order_line_num 
				FETCH c0_orderdetl INTO l_rec_inv_detl.offer_code 

				OPEN c0_tinvdetl USING l_rec_pickdetl.order_num 
				FETCH c0_tinvdetl 
				LET l_status = status 

				INSERT INTO t_inv_detl VALUES (
					l_rowid,
					l_rec_inv_detl.*) 
				
				IF l_status = NOTFOUND THEN 
					LET l_query_text = 
					"SELECT * FROM orderdetl ", 
					"WHERE cmpy_code = '",p_cmpy,"' ", 
					"AND order_num = '",l_rec_pickdetl.order_num,"' ", 
					"AND status_ind in ('0','2','3')" 
					IF l_rec_orderhead.status_ind = "U" THEN 
						IF l_rec_inv_head.order_num IS NULL THEN 
							LET l_rec_inv_head.order_num = l_rec_orderhead.order_num 
							LET l_rec_inv_head.com1_text = l_rec_orderhead.com1_text 
							LET l_rec_inv_head.com2_text = l_rec_orderhead.com2_text 
							LET l_rec_inv_head.calc_freight_amt = l_rec_orderhead.freight_amt 
							LET l_rec_inv_head.calc_hand_amt = l_rec_orderhead.hand_amt 
						END IF 
						LET l_query_text = 
							l_query_text clipped," ", 
							"AND((pick_flag = 'N' AND sched_qty > 0) ", ## scheduled 
							"OR(part_code IS NULL AND order_qty=0) ", ## description 
							"OR(back_qty>0 AND back_qty=order_qty-inv_qty))"## backorders 
					ELSE 
						LET l_query_text = 
							l_query_text clipped," ", 
							"AND((pick_flag = 'N' AND sched_qty > 0) ", ## scheduled 
							"OR(back_qty>0 AND back_qty=order_qty-inv_qty))"## backorders 
					END IF 
					PREPARE s1_orderdetl FROM l_query_text 
					DECLARE c1_orderdetl cursor FOR s1_orderdetl 
					FOREACH c1_orderdetl INTO l_rec_orderdetl.* 
						LET l_rec_inv_detl.ware_code = l_rec_pickhead.ware_code 
						LET l_rec_inv_detl.pick_num = l_rec_pickhead.pick_num 
						LET l_rec_inv_detl.order_num = l_rec_orderdetl.order_num 
						LET l_rec_inv_detl.order_line_num = l_rec_orderdetl.line_num 
						LET l_rec_inv_detl.order_rev_num = l_rec_orderhead.rev_num 
						LET l_rec_inv_detl.last_inv_num = l_rec_orderhead.last_inv_num 
						LET l_rec_inv_detl.order_date = l_rec_orderhead.order_date 
						LET l_rec_inv_detl.part_code = l_rec_orderdetl.part_code 
						LET l_rec_inv_detl.picked_qty = l_rec_orderdetl.sched_qty 
						LET l_rec_inv_detl.sold_qty = l_rec_inv_detl.picked_qty 
						LET l_rec_inv_detl.offer_code = l_rec_orderdetl.offer_code 
						PUT s1_t_invdetl 
					END FOREACH 
				END IF 
			END FOREACH 

			IF l_rec_inv_head.order_num IS NULL THEN 
				#-------------------------------------------------
				# All orders are on second OR subsequent invoice
				LET l_rec_inv_head.order_num = l_rec_inv_detl.order_num 
				LET l_rec_inv_head.com1_text = l_rec_orderhead.com1_text 
				LET l_rec_inv_head.com2_text = l_rec_orderhead.com2_text 
				LET l_rec_inv_head.calc_freight_amt = 0 
				LET l_rec_inv_head.calc_hand_amt = 0 
			END IF 

			LET l_rec_inv_head.freight_amt = l_rec_inv_head.calc_freight_amt 
			LET l_rec_inv_head.hand_amt = l_rec_inv_head.calc_hand_amt 

			IF l_update_header = 'Y' THEN 
				EXECUTE s_tinvhead USING 
					l_rec_inv_head.order_num, 
					l_rec_inv_head.hold_code, 
					l_rec_inv_head.com1_text, 
					l_rec_inv_head.com2_text, 
					l_rec_inv_head.calc_freight_amt, 
					l_rec_inv_head.freight_amt, 
					l_rec_inv_head.calc_hand_amt, 
					l_rec_inv_head.batch_num, 
					l_rec_inv_head.hand_amt, 
					l_rowid 
			END IF 

			IF l_inv_cnt >= glob_rec_opparms.max_inv_cycle_num THEN 
				EXIT FOREACH 
			END IF 
			FLUSH s1_t_invdetl ## INSERT ROWS so reoccurrence OF ORDER no 
			## can be identified in next iteration
		END FOREACH 

		###
		### END of picked inventory lines calculation
		###
		IF l_inv_cnt < glob_rec_opparms.max_inv_cycle_num THEN 
			## Declare dynamic cursors TO be used inside iteration
			## #6 Trade-In lines
			LET l_query_text = 
				"SELECT * FROM orderdetl ", 
				"WHERE cmpy_code = '",p_cmpy, "' ", 
				"AND order_num = ? ", 
				"AND order_qty < 0 ", 
				"AND inv_qty != order_qty " 
			PREPARE s6_orderdetl FROM l_query_text 
			DECLARE c6_orderdetl cursor FOR s6_orderdetl 

			## #7 Pre-Delivered lines
			LET l_query_text = 
				"SELECT * FROM orderdetl ", 
				"WHERE cmpy_code = '",p_cmpy, "' ", 
				"AND order_num = ? ", 
				"AND conf_qty > 0 ", 
				"AND inv_qty < order_qty ", 
				"AND status_ind = '1' " 
			PREPARE s7_orderdetl FROM l_query_text 
			DECLARE c7_orderdetl cursor FOR s7_orderdetl 

			######### END of Dynamic Cursor Declaration
			###
			### Now retreive non-pick,  trade-in, AND pre-delivered invoices
			###
			LET l_query_text = 
				"SELECT * FROM orderhead ", 
				"WHERE cmpy_code = \"",p_cmpy,"\" ", 
				"AND status_ind in ('U','P') ", 
				"AND ord_ind = '2' ", 
				"AND hold_code IS NULL ", 
				"AND ship_date<=(\"",today+glob_rec_opparms.days_pick_num,"\") ", 
				"AND ",p_order_text clipped 
			PREPARE s_orderhead FROM l_query_text 
			DECLARE c_orderhead cursor FOR s_orderhead 

			FOREACH c_orderhead INTO l_rec_orderhead.* 
				###
				### Pick Up Stand Alone Non-Inventory Orders
				###
				### Only want orders such that invoice total > 0,
				### ie: dont create invoices with all backordered lines.
				### This IS done by ordering the orderdetl SELECT by sched_qty.  If
				### first line doesn't contain non-zero THEN no lines will.
				OPEN c0_tinvdetl USING l_rec_orderhead.order_num 
				FETCH c0_tinvdetl 
				IF sqlca.sqlcode = NOTFOUND THEN 
					##
					## Order IS NOT already in the invoice table
					##
					LET l_query_text = 
						"SELECT * FROM orderdetl ", 
						"WHERE cmpy_code='",p_cmpy,"' ", 
						"AND order_num='",l_rec_orderhead.order_num,"' ", 
						"AND status_ind in ('0','2','3')" 
					IF l_rec_orderhead.status_ind = "U" THEN 
						LET l_query_text = 
							l_query_text clipped," ", 
							"AND((pick_flag = 'N' AND sched_qty > 0) ", ## scheduled 
							"OR(part_code IS NULL AND order_qty=0) ", ## description 
							"OR(back_qty>0 AND back_qty=order_qty-inv_qty))"## backorders 
					ELSE 
						LET l_query_text = 
							l_query_text clipped," ", 
							"AND((pick_flag = 'N' AND sched_qty > 0) ", ## scheduled 
							"OR(back_qty>0 AND back_qty=order_qty-inv_qty))"## backorders 
					END IF 
					###
					### see note above as TO reason behind ORDER BY clause
					###
					LET l_query_text = l_query_text clipped," ORDER BY 3,sched_qty desc" 

					PREPARE s2_orderdetl FROM l_query_text 
					DECLARE c2_orderdetl cursor FOR s2_orderdetl 
					LET l_rec_inv_head.order_num = 0 

					FOREACH c2_orderdetl INTO l_rec_orderdetl.* 
						IF l_rec_inv_head.order_num = 0 THEN 
							IF l_rec_orderdetl.sched_qty = 0 THEN 
								###
								### Nothing TO invoice
								###
								EXIT FOREACH 
							END IF 
							
							LET l_rec_inv_head.order_num = l_rec_orderhead.order_num 
							LET l_rec_inv_head.ware_code = l_rec_orderhead.ware_code 
							LET l_rec_inv_head.pick_num = NULL 
							LET l_rec_inv_head.batch_num = NULL 
							LET l_rec_inv_head.invoice_ind = 2 
							LET l_rec_inv_head.cust_code = l_rec_orderhead.cust_code 
							LET l_rec_inv_head.order_num = l_rec_orderhead.order_num 
							LET l_rec_inv_head.pick_date = l_rec_orderhead.order_date 
							LET l_rec_inv_head.hold_code = NULL 

							IF l_rec_orderhead.ship_date > today THEN 
								LET l_rec_inv_head.inv_date = l_rec_orderhead.ship_date 
							ELSE 
								LET l_rec_inv_head.inv_date = today 
							END IF 

							LET l_rec_inv_head.ship_date = today 
							LET l_rec_inv_head.com1_text = l_rec_orderhead.com1_text 
							LET l_rec_inv_head.com2_text = l_rec_orderhead.com2_text 

							IF l_rec_orderhead.status_ind = "U" THEN 
								LET l_rec_inv_head.calc_freight_amt = 
								l_rec_orderhead.freight_amt 
								LET l_rec_inv_head.calc_hand_amt = l_rec_orderhead.hand_amt 
							ELSE 
								LET l_rec_inv_head.calc_freight_amt = 0 
								LET l_rec_inv_head.calc_hand_amt = 0 
							END IF 

							LET l_rec_inv_head.freight_amt = l_rec_inv_head.calc_freight_amt 
							LET l_rec_inv_head.hand_amt = l_rec_inv_head.calc_hand_amt 

							INSERT INTO t_inv_head VALUES (l_rec_inv_head.*) 

							LET l_rowid = sqlca.sqlerrd[6] 
							LET l_inv_cnt = l_inv_cnt + 1 
						END IF 

						LET l_rec_inv_detl.ware_code = l_rec_orderhead.ware_code 
						LET l_rec_inv_detl.pick_num = "" 
						LET l_rec_inv_detl.order_num = l_rec_orderdetl.order_num 
						LET l_rec_inv_detl.order_line_num = l_rec_orderdetl.line_num 
						LET l_rec_inv_detl.order_rev_num = l_rec_orderhead.rev_num 
						LET l_rec_inv_detl.last_inv_num = l_rec_orderhead.last_inv_num 
						LET l_rec_inv_detl.order_date = l_rec_orderhead.order_date 
						LET l_rec_inv_detl.part_code = l_rec_orderdetl.part_code 
						LET l_rec_inv_detl.picked_qty = l_rec_orderdetl.sched_qty 
						LET l_rec_inv_detl.sold_qty = l_rec_inv_detl.picked_qty 
						LET l_rec_inv_detl.offer_code = l_rec_orderdetl.offer_code 
						PUT s1_t_invdetl 
					END FOREACH 

					### Pick Up Pre-delivery Orders
					LET l_rec_inv_head.order_num = 0 
					OPEN c7_orderdetl USING l_rec_orderhead.order_num 

					FOREACH c7_orderdetl INTO l_rec_orderdetl.* 
						IF l_rec_inv_head.order_num = 0 THEN 
							LET l_rec_inv_head.order_num = l_rec_orderhead.order_num 
							LET l_rec_inv_head.ware_code = l_rec_orderhead.ware_code 
							LET l_rec_inv_head.pick_num = NULL 
							LET l_rec_inv_head.batch_num = NULL 
							LET l_rec_inv_head.invoice_ind = 3 
							LET l_rec_inv_head.cust_code = l_rec_orderhead.cust_code 
							LET l_rec_inv_head.pick_date = l_rec_orderhead.order_date 
							LET l_rec_inv_head.hold_code = NULL 

							IF l_rec_orderhead.order_date > today THEN 
								LET l_rec_inv_head.inv_date = l_rec_orderhead.order_date 
							ELSE 
								LET l_rec_inv_head.inv_date = today 
							END IF 

							LET l_rec_inv_head.ship_date = today 
							LET l_rec_inv_head.com1_text = l_rec_orderhead.com1_text 
							LET l_rec_inv_head.com2_text = l_rec_orderhead.com2_text 
							LET l_rec_inv_head.calc_freight_amt = 0 
							LET l_rec_inv_head.calc_hand_amt = 0 

							IF l_rec_orderhead.status_ind = "U" THEN 
								LET l_rec_inv_head.calc_freight_amt = l_rec_orderhead.freight_amt 
								LET l_rec_inv_head.calc_hand_amt = l_rec_orderhead.hand_amt 
							END IF 

							LET l_rec_inv_head.freight_amt = l_rec_inv_head.calc_freight_amt 
							LET l_rec_inv_head.hand_amt = l_rec_inv_head.calc_hand_amt 

							INSERT INTO t_inv_head VALUES (l_rec_inv_head.*) 

							LET l_rowid = sqlca.sqlerrd[6] 
							LET l_inv_cnt = l_inv_cnt + 1 
						END IF 

						LET l_rec_inv_detl.ware_code = l_rec_orderdetl.ware_code 
						LET l_rec_inv_detl.pick_num = "" 
						LET l_rec_inv_detl.order_num = l_rec_orderdetl.order_num 
						LET l_rec_inv_detl.order_line_num = l_rec_orderdetl.line_num 
						LET l_rec_inv_detl.order_rev_num = l_rec_orderhead.rev_num 
						LET l_rec_inv_detl.last_inv_num = l_rec_orderhead.last_inv_num 
						LET l_rec_inv_detl.order_date = l_rec_orderhead.order_date 
						LET l_rec_inv_detl.part_code = l_rec_orderdetl.part_code 
						LET l_rec_inv_detl.picked_qty = l_rec_orderdetl.conf_qty 
						LET l_rec_inv_detl.sold_qty = l_rec_orderdetl.conf_qty 
						LET l_rec_inv_detl.offer_code = l_rec_orderdetl.offer_code 

						PUT s1_t_invdetl 
					END FOREACH 

				END IF 

				#-------------------------------------------------------
				# Pickup Negative Quantity Lines FOR Proposed credit
				LET l_rec_inv_head.order_num = 0 
				OPEN c6_orderdetl USING l_rec_orderhead.order_num 

				FOREACH c6_orderdetl INTO l_rec_orderdetl.* 
					IF l_rec_inv_head.order_num = 0 THEN 
						LET l_rec_inv_head.order_num = l_rec_orderhead.order_num 
						LET l_rec_inv_head.ware_code = l_rec_orderhead.ware_code 
						LET l_rec_inv_head.pick_num = NULL 
						LET l_rec_inv_head.batch_num = NULL 
						LET l_rec_inv_head.invoice_ind = 4 
						LET l_rec_inv_head.cust_code = l_rec_orderhead.cust_code 
						LET l_rec_inv_head.pick_date = l_rec_orderhead.order_date 
						LET l_rec_inv_head.hold_code = NULL 
						
						IF l_rec_orderhead.order_date > today THEN 
							LET l_rec_inv_head.inv_date = l_rec_orderhead.order_date 
						ELSE 
							LET l_rec_inv_head.inv_date = today 
						END IF 
						
						LET l_rec_inv_head.ship_date = today 
						LET l_rec_inv_head.com1_text = l_rec_orderhead.com1_text 
						LET l_rec_inv_head.com2_text = l_rec_orderhead.com2_text 
						LET l_rec_inv_head.calc_freight_amt = 0 
						LET l_rec_inv_head.freight_amt = 0 
						LET l_rec_inv_head.calc_hand_amt = 0 
						LET l_rec_inv_head.hand_amt = 0 

						INSERT INTO t_inv_head VALUES (l_rec_inv_head.*) 

						LET l_rowid = sqlca.sqlerrd[6] 
						LET l_inv_cnt = l_inv_cnt + 1 
					END IF 
					
					LET l_rec_inv_detl.ware_code = l_rec_orderdetl.ware_code 
					LET l_rec_inv_detl.pick_num = "" 
					LET l_rec_inv_detl.order_num = l_rec_orderdetl.order_num 
					LET l_rec_inv_detl.order_line_num = l_rec_orderdetl.line_num 
					LET l_rec_inv_detl.order_rev_num = l_rec_orderhead.rev_num 
					LET l_rec_inv_detl.last_inv_num = l_rec_orderhead.last_inv_num 
					LET l_rec_inv_detl.order_date = l_rec_orderhead.order_date 
					LET l_rec_inv_detl.part_code = l_rec_orderdetl.part_code 
					LET l_rec_inv_detl.picked_qty = l_rec_orderdetl.order_qty	- l_rec_orderdetl.inv_qty 
					LET l_rec_inv_detl.sold_qty = l_rec_orderdetl.order_qty - l_rec_orderdetl.inv_qty 
					LET l_rec_inv_detl.offer_code = l_rec_orderdetl.offer_code 
					
					PUT s1_t_invdetl
					 
				END FOREACH 

				IF l_inv_cnt >= glob_rec_opparms.max_inv_cycle_num THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH
			 
		END IF 

		CLOSE s1_t_invdetl 

	COMMIT WORK 

END FUNCTION 
###########################################################################
# END FUNCTION load_tables(p_cmpy,p_kandoouser_sign_on_code,p_verbose_ind,p_order_text,p_pick_text)
###########################################################################


###########################################################################
# FUNCTION calc_chrgqty(p_cmpy,p_rowid) 
#
# This FUNCTION calculates the sold_qty value on the t_inv_detl.
# The invoice line amount will equal (sold_qty*(unit_price+unit_tax))
# Hence, sold_qty IS calculated as follows
###########################################################################
FUNCTION calc_chrgqty(p_cmpy,p_rowid) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_sold_qty LIKE orderdetl.sold_qty 
	DEFINE l_sold_inv_qty LIKE orderdetl.sold_qty 
	DEFINE l_line_qty LIKE orderdetl.sold_qty  
	DEFINE l_query_text char(400) 

	LET l_query_text = 
		"SELECT * FROM orderdetl ", 
		"WHERE cmpy_code = '",p_cmpy, "' ", 
		"AND order_num = ? ", 
		"AND line_num = ? ", 
		"AND bonus_qty > 0 " 
	PREPARE s3_orderdetl FROM l_query_text 
	DECLARE c3_orderdetl cursor FOR s3_orderdetl 
	
	LET l_query_text = 
		"UPDATE t_inv_detl SET sold_qty = ? ", 
		"WHERE inv_rowid=? ", 
		"AND order_num=? ", 
		"AND order_line_num = ? " 
	PREPARE s1_tinvdetl FROM l_query_text 
	DECLARE c_inv_detl cursor FOR
	 
	SELECT 
		order_num, 
		order_line_num, 
		picked_qty 
	FROM t_inv_detl 
	WHERE inv_rowid = p_rowid 
	ORDER BY order_line_num 
	
	FOREACH c_inv_detl INTO 
		l_rec_orderdetl.order_num, 
		l_rec_orderdetl.line_num, 
		l_line_qty 
		
		OPEN c3_orderdetl USING 
			l_rec_orderdetl.order_num, 
			l_rec_orderdetl.line_num 
		
		FETCH c3_orderdetl INTO l_rec_orderdetl.* 
		
		IF sqlca.sqlcode = 0 THEN 
			IF l_rec_orderdetl.inv_qty = 0 THEN 
				LET l_sold_inv_qty = 0 
			ELSE 
				SELECT sum(sold_qty) INTO l_sold_inv_qty 
				FROM invoicedetl 
				WHERE cmpy_code =p_cmpy 
				AND order_num =l_rec_orderdetl.order_num 
				AND order_line_num = l_rec_orderdetl.line_num 
				IF l_sold_inv_qty IS NULL THEN 
					LET l_sold_inv_qty = 0 
				END IF 
			END IF 
			#------------------------------------------------------
			# Warning: this code does NOT handle negative bonus_qty's
			IF l_sold_inv_qty < l_rec_orderdetl.sold_qty THEN 
				LET l_sold_qty = l_rec_orderdetl.sold_qty - l_sold_inv_qty 
				IF l_sold_qty > l_line_qty THEN 
					LET l_sold_qty = l_line_qty 
				END IF 
			ELSE 
				LET l_sold_qty = 0 
			END IF 
			
			EXECUTE s1_tinvdetl USING 
				l_sold_qty, 
				p_rowid, 
				l_rec_orderdetl.order_num, 
				l_rec_orderdetl.line_num 
		END IF 
	END FOREACH 
	
END FUNCTION 
###########################################################################
# END FUNCTION calc_chrgqty(p_cmpy,p_rowid) 
###########################################################################


###########################################################################
# FUNCTION cr_inv_tables() 
#
# 
###########################################################################
FUNCTION cr_inv_tables()
 
	CREATE temp TABLE t_inv_head(
		ware_code char(3), 
		pick_num INTEGER, 
		invoice_ind SMALLINT, 
		cust_code char(8), 
		order_num INTEGER, 
		pick_date DATE, 
		hold_code char(3), 
		calc_freight_amt decimal(16,2), 
		freight_amt decimal(16,2), 
		calc_hand_amt decimal(16,2), 
		hand_amt decimal(16,2), 
		ship_date DATE, 
		inv_date DATE, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		com1_text char(30), 
		com2_text char(30), 
		batch_num integer) with no LOG 
		CREATE temp TABLE t_inv_detl(inv_rowid INTEGER, 
		ware_code char(3), 
		pick_num INTEGER, 
		order_num INTEGER, 
		order_line_num INTEGER, 
		order_rev_num INTEGER, 
		last_inv_num INTEGER, 
		order_date DATE, 
		part_code char(15), 
		picked_qty FLOAT, 
		sold_qty FLOAT, 
		offer_code char(3), 
		reduce_inv_flag char(1)) with no LOG 

	CREATE INDEX tdetl_key ON t_inv_detl(order_num,order_line_num) 

	CALL create_table("cashreceipt","t_cashreceipt","","N") 

END FUNCTION 
###########################################################################
# END FUNCTION cr_inv_tables() 
###########################################################################


###########################################################################
# FUNCTION calc_comm(p_cmpy,
# p_sale_code, 
#	p_comm_per, 
#	p_comm_ind, 
#	p_cond_code, 
#	p_rec_invoicedetl) 
#
# dollar amount based commission rates are calculated
# AT ORDER entry time so the count of offers, conditions ...etc
# IS known.  percent based commission rates are calculated at
# invoice generation time so the commission base amounts are known
###########################################################################
FUNCTION calc_comm(p_cmpy,
	p_sale_code, 
	p_comm_per, 
	p_comm_ind, 
	p_cond_code, 
	p_rec_invoicedetl) 

	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_comm_per LIKE salestrct.comm_per 
	DEFINE p_comm_ind LIKE salesperson.comm_ind 
	DEFINE p_cond_code LIKE invoicehead.cond_code 
	DEFINE p_rec_invoicedetl RECORD LIKE invoicedetl.* 

	DEFINE l_comm_amt LIKE salestrct.comm_amt 
	DEFINE l_comm_base_amt decimal(16,2) 
	DEFINE l_query_text char(300) 
	DEFINE i SMALLINT 

	LET l_query_text = 
		"SELECT comm_amt,comm_per FROM salestrct ", 
		"WHERE cmpy_code ='",p_cmpy,"' ", 
		"AND sale_code ='",p_sale_code,"' ", 
		"AND type_ind = ? ", 
		"AND type_code = ?" 
	PREPARE s_salestrct FROM l_query_text 
	DECLARE c_salestrct cursor FOR s_salestrct
	 
	FOR i = 1 TO 6 
		CASE i 
			WHEN 1 
				IF p_rec_invoicedetl.offer_code IS NULL THEN 
					CONTINUE FOR 
				END IF 
				OPEN c_salestrct USING i, p_rec_invoicedetl.offer_code 
			WHEN 2 
				IF p_cond_code IS NULL THEN 
					CONTINUE FOR 
				END IF 
				OPEN c_salestrct USING i, p_cond_code 
			WHEN 3 
				IF p_rec_invoicedetl.part_code IS NULL THEN 
					CONTINUE FOR 
				END IF 
				OPEN c_salestrct USING i, p_rec_invoicedetl.part_code 
			WHEN 4 
				IF p_rec_invoicedetl.prodgrp_code IS NULL THEN 
					CONTINUE FOR 
				END IF 
				OPEN c_salestrct USING i, p_rec_invoicedetl.prodgrp_code 
			WHEN 5 
				IF p_rec_invoicedetl.maingrp_code IS NULL THEN 
					CONTINUE FOR 
				END IF 
				OPEN c_salestrct USING i, p_rec_invoicedetl.maingrp_code 
			WHEN 6 
				LET l_comm_amt = 0 
		END CASE
		 
		IF i = 6 THEN 
			LET sqlca.sqlcode = 0 
		ELSE 
			FETCH c_salestrct INTO l_comm_amt, p_comm_per 
		END IF 
		
		IF sqlca.sqlcode = 0 THEN 
			IF p_comm_per IS NOT NULL THEN 
				##
				### commisssion IS percentage based
				IF p_comm_ind = "1" THEN 
					## nett
					LET l_comm_amt = (p_comm_per/100)* p_rec_invoicedetl.ext_stats_amt 
				ELSE 
					## gross
					LET l_comm_amt = (p_comm_per/100)* 
					(p_rec_invoicedetl.list_price_amt * p_rec_invoicedetl.ship_qty) 
				END IF 
			ELSE 
				##
				### commisssion IS amount based
				CASE i 
					WHEN 1 ## special offer 
						IF p_comm_ind = "1" THEN 
							## nett
							##                 SELECT sum(ext_stats_amt) INTO l_comm_base_amt
							##                   FROM invoicedetl
							##                  WHERE cmpy_code = p_cmpy
							##                    AND order_num = p_rec_invoicedetl.order_num
							##                    AND offer_code = p_rec_invoicedetl.offer_code
							SELECT net_amt INTO l_comm_base_amt 
							FROM orderoffer 
							WHERE cmpy_code = p_cmpy 
							AND order_num = p_rec_invoicedetl.order_num 
							AND offer_code = p_rec_invoicedetl.offer_code 
							IF l_comm_base_amt != 0 THEN 
								LET l_comm_amt = l_comm_amt * (p_rec_invoicedetl.ext_stats_amt/l_comm_base_amt) 
							END IF 
						ELSE 
							## gross
							##                 SELECT sum(list_price_amt*ship_qty) INTO l_comm_base_amt
							##                   FROM orderdetl
							##                  WHERE cmpy_code = p_cmpy
							##                    AND order_num = p_rec_invoicedetl.order_num
							##                    AND offer_code = p_rec_invoicedetl.offer_code
							SELECT gross_amt INTO l_comm_base_amt 
							FROM orderoffer 
							WHERE cmpy_code = p_cmpy 
							AND order_num = p_rec_invoicedetl.order_num 
							AND offer_code = p_rec_invoicedetl.offer_code 
							IF l_comm_base_amt != 0 THEN 
								LET l_comm_amt = l_comm_amt * 
								((p_rec_invoicedetl.list_price_amt*p_rec_invoicedetl.ship_qty) / l_comm_base_amt) 
							END IF 
						END IF 
						
					WHEN 2 
						IF p_comm_ind = "1" THEN 
							#----------------------------
							# nett
							SELECT sum(ext_stats_amt) INTO l_comm_base_amt 
							FROM orderdetl 
							WHERE cmpy_code = p_cmpy 
							AND order_num = p_rec_invoicedetl.order_num 
							AND part_code IS NOT NULL 
							AND (offer_code = "###" OR offer_code IS null) 
							IF l_comm_base_amt != 0 THEN 
								LET l_comm_amt = l_comm_amt * (p_rec_invoicedetl.ext_sale_amt/l_comm_base_amt) 
							END IF 
						ELSE 
							## gross
							SELECT sum(list_price_amt*ship_qty) INTO l_comm_base_amt 
							FROM orderdetl 
							WHERE cmpy_code = p_cmpy 
							AND order_num = p_rec_invoicedetl.order_num 
							AND part_code IS NOT NULL 
							AND (offer_code = "###" OR offer_code IS null) 
							IF l_comm_base_amt != 0 THEN 
								LET l_comm_amt = l_comm_amt * ((p_rec_invoicedetl.list_price_amt*p_rec_invoicedetl.ship_qty) / l_comm_base_amt) 
							END IF 
						END IF 
					OTHERWISE 
						IF p_comm_ind = "1" THEN 
							## nett
							LET l_comm_amt = l_comm_amt * p_rec_invoicedetl.ship_qty 
						ELSE 
							## gross
						END IF 
				END CASE 
				
			END IF
			 
			IF l_comm_amt IS NULL THEN 
				LET l_comm_amt = 0 
			END IF 
			EXIT FOR
			 
		END IF
		 
	END FOR
	 
	FREE s_salestrct 
	
	RETURN l_comm_amt 
END FUNCTION
###########################################################################
# END FUNCTION calc_comm(p_cmpy,
###########################################################################