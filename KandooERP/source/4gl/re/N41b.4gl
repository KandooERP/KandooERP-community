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
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N41_GLOBALS.4gl"  
# \brief module N41a (N41b !!!!) - Purchase Order Genaration


FUNCTION valid_vendor(pr_vend_code,pr_line_num,pr_replenish_ind,pr_deact_disp) 
	DEFINE 
	pr_vend_code LIKE vendor.vend_code, 
	pr_line_num LIKE reqdetl.line_num, 
	pr_replenish_ind LIKE reqdetl.replenish_ind, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_deact_disp CHAR(1) 

	LET err_message = NULL 
	IF pr_replenish_ind = 'P' THEN 
		IF pr_vend_code IS NULL THEN 
			LET err_message = 
			" Line Item ",pr_line_num USING "<<<"," Vendor does NOT Exist" 
		ELSE 
			SELECT hold_code INTO pr_vendor.hold_code FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_vend_code 
			IF status = notfound THEN 
				LET err_message = 
				" Line Item ",pr_line_num USING "<<<", 
				", Vendor ",pr_vend_code, 
				" IS Invalid " 
			ELSE 
				IF pr_vendor.hold_code = "ST" THEN 
					LET err_message = 
					" Line Item ",pr_line_num USING "<<", 
					" Vendor ",pr_vend_code clipped, 
					" on Hold - Release Before Proceeding" 
				END IF 
			END IF 
		END IF 
	ELSE 
		IF pr_vend_code IS NULL THEN 
			LET err_message = 
			" Line Item ",pr_line_num USING "<<<"," Warehouse does NOT Exist" 
		ELSE 
			SELECT * FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_vend_code 
			IF status = notfound THEN 
				LET err_message = 
				" Line Item ",pr_line_num USING "<<<", 
				", Warehouse ",pr_vend_code clipped, 
				" IS Invalid " 
			END IF 
		END IF 
	END IF 
	IF err_message IS NOT NULL 
	AND err_message != " " THEN 
		IF NOT pr_deact_disp THEN 
			LET msgresp=kandoomsg("N",7022,err_message) 
			#7022 err_message
		END IF 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION update_approve(pr_replenish_ind,pr_total_amt,l_mode) 
	DEFINE pr_replenish_ind LIKE reqdetl.replenish_ind 
	DEFINE pr_total_amt LIKE reqhead.total_sales_amt 
	DEFINE l_mode CHAR(2) 
	DEFINE pr_approve RECORD 
		replenish_ind CHAR(1), 
		total_amt DECIMAL(16,4) 
	END RECORD 

	SELECT * INTO pr_approve.* FROM t_approve 
	WHERE replenish_ind = pr_replenish_ind 
	IF status = notfound THEN 
		LET pr_approve.total_amt = pr_total_amt 
	ELSE 
		IF l_mode = TRAN_TYPE_INVOICE_IN THEN 
			LET pr_approve.total_amt = pr_approve.total_amt + pr_total_amt 
		ELSE 
			LET pr_approve.total_amt = pr_approve.total_amt - pr_total_amt 
		END IF 
	END IF 
	UPDATE t_approve 
	SET approve_amt = pr_approve.total_amt 
	WHERE replenish_ind = pr_replenish_ind 
	IF sqlca.sqlerrd[3] = 0 THEN 
		INSERT INTO t_approve VALUES (pr_replenish_ind, 
		pr_approve.total_amt) 
	END IF 
END FUNCTION 


FUNCTION create_po(pr_req_num) 
	DEFINE 
	pr_scroll_flag CHAR(1), 
	pr_req_num LIKE reqhead.req_num, 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	ps_reqdetl RECORD LIKE reqdetl.*, 
	pr_reqperson RECORD LIKE reqperson.*, 
	pr_reqperson2 RECORD LIKE reqperson.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pa_reqdetl ARRAY [2000] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE reqdetl.line_num, 
		part_code LIKE reqdetl.part_code, 
		req_qty LIKE reqdetl.req_qty, 
		uom_code LIKE reqdetl.uom_code, 
		outer_flag CHAR(1), 
		unit_sales_amt LIKE reqdetl.unit_sales_amt, 
		line_total LIKE reqhead.total_sales_amt, 
		replenish_ind LIKE reqdetl.replenish_ind, 
		vend_code LIKE reqdetl.vend_code 
	END RECORD, 
	pr_reqdetl2 RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE reqdetl.line_num, 
		part_code LIKE reqdetl.part_code, 
		req_qty LIKE reqdetl.req_qty, 
		uom_code LIKE reqdetl.uom_code, 
		outer_flag CHAR(1), 
		unit_sales_amt LIKE reqdetl.unit_sales_amt, 
		line_total LIKE reqhead.total_sales_amt, 
		replenish_ind LIKE reqdetl.replenish_ind, 
		vend_code LIKE reqdetl.vend_code, 
		desc_text LIKE product.desc_text 
	END RECORD, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_save_unit_cost_amt LIKE reqdetl.unit_cost_amt, 
	pr_save_qty,pr_approve_qty LIKE reqdetl.po_qty, 
	pr_replenish_ind LIKE reqdetl.replenish_ind, 
	pr_line_total LIKE reqhead.total_sales_amt, 
	ps_outer_flag CHAR(1), 
	ps_line_total LIKE reqhead.total_sales_amt, 
	pr_conv_rate LIKE rate_exchange.conv_buy_qty, 
	pr_total_sales_amt LIKE reqhead.total_sales_amt, 
	err_continue, pr_sort_flag CHAR(1), 
	pr_temp_text CHAR(40), 
	pr_toggle, pr_scrn, pr_counter SMALLINT, 
	idx, scrn, cnt, pr_error_count SMALLINT, 
	pr_po_qty LIKE poaudit.order_qty, 
	pr_limit_amt,pr_initial_amt,pr_amt_int INTEGER, 
	pr_low_amt,pr_high_amt CHAR(17), 
	pr_message_text CHAR(40), 
	pr_warn_message CHAR(30), 
	tot_stk_appr,tot_po_appr LIKE prodstatus.list_amt, 
	pr_save_replenish_ind LIKE reqdetl.replenish_ind, 
	pr_total_amount, pr_amt_flt FLOAT, 
	pr_temp_line_total LIKE reqhead.total_sales_amt 

	SELECT reqhead.*, reqperson.* INTO pr_reqhead.*, pr_reqperson.* 
	FROM reqhead, reqperson 
	WHERE reqhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND reqhead.cmpy_code = reqperson.cmpy_code 
	AND reqhead.person_code = reqperson.person_code 
	AND reqhead.req_num = pr_req_num 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("N",9512,"") 
		#9512 Requisition number does NOT exist.
		RETURN 
	END IF 
	SELECT * INTO pr_reqperson2.* FROM reqperson 
	WHERE person_code = glob_rec_kandoouser.sign_on_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_sort_flag = false 
	WHILE true 
		LET idx = 0 
		IF pr_sort_flag THEN 
			DECLARE c2_reqdetl CURSOR FOR 
			SELECT * FROM t_reqdetl2 
			WHERE 1 = 1 
			ORDER BY vend_code, desc_text 
			FOREACH c2_reqdetl INTO pr_reqdetl2.* 
				LET idx = idx + 1 
				LET pa_reqdetl[idx].scroll_flag = pr_reqdetl2.scroll_flag 
				LET pa_reqdetl[idx].line_num = pr_reqdetl2.line_num 
				LET pa_reqdetl[idx].part_code = pr_reqdetl2.part_code 
				LET pa_reqdetl[idx].req_qty = pr_reqdetl2.req_qty 
				LET pa_reqdetl[idx].uom_code = pr_reqdetl2.uom_code 
				LET pa_reqdetl[idx].outer_flag = pr_reqdetl2.outer_flag 
				LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl2.unit_sales_amt 
				LET pa_reqdetl[idx].line_total = pr_reqdetl2.line_total 
				LET pa_reqdetl[idx].replenish_ind = pr_reqdetl2.replenish_ind 
				LET pa_reqdetl[idx].vend_code = pr_reqdetl2.vend_code 
			END FOREACH 
		ELSE 
			DECLARE c1_reqdetl CURSOR FOR 
			SELECT * FROM reqdetl 
			WHERE reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND reqdetl.req_num = pr_req_num 
			AND ( reqdetl.req_qty > reqdetl.po_qty 
			OR ( reqdetl.back_qty > 0 
			AND reqdetl.back_qty > reqdetl.po_qty) ) 
			AND reqdetl.po_qty = 0 
			ORDER BY line_num 
			LET tot_stk_appr = 0 
			LET tot_po_appr = 0 
			FOREACH c1_reqdetl INTO pr_reqdetl.* 
				### Above CURSOR selects reqs other than type '0' WHERE back qty = 0
				### Test IS required TO filter these req lines out of the array
				IF pr_reqhead.stock_ind != '0' THEN 
					IF pr_reqdetl.back_qty = 0 
					OR pr_reqdetl.po_qty > 0 THEN 
						CONTINUE FOREACH 
					END IF 
				END IF 
				LET idx = idx + 1 
				LET pa_reqdetl[idx].scroll_flag = NULL 
				LET pa_reqdetl[idx].line_num = pr_reqdetl.line_num 
				LET pa_reqdetl[idx].part_code = pr_reqdetl.part_code 
				SELECT approve_qty INTO pr_approve_qty FROM t_reqdetl 
				WHERE req_num = pr_reqhead.req_num 
				AND line_num = pr_reqdetl.line_num 
				IF status = notfound THEN 
					IF pr_reqhead.stock_ind = '0' THEN 
						LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
						- pr_reqdetl.po_qty 
					ELSE 
						LET pa_reqdetl[idx].req_qty = pr_reqdetl.back_qty 
						- pr_reqdetl.po_qty 
					END IF 
				ELSE 
					LET pa_reqdetl[idx].req_qty = pr_approve_qty 
				END IF 
				LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
				LET pa_reqdetl[idx].uom_code = pr_reqdetl.uom_code 
				LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty 
				* pa_reqdetl[idx].unit_sales_amt 
				LET pa_reqdetl[idx].replenish_ind = pr_reqdetl.replenish_ind 
				LET pa_reqdetl[idx].vend_code = pr_reqdetl.vend_code 
				### Determine IF requisition currently selected
				SELECT * FROM reqpurch 
				WHERE req_num = pr_reqdetl.req_num 
				AND line_num = pr_reqdetl.line_num 
				IF status = notfound THEN 
					LET pa_reqdetl[idx].scroll_flag = NULL 
				ELSE 
					LET pa_reqdetl[idx].scroll_flag = "*" 
				END IF 
				LET pa_reqdetl[idx].outer_flag = NULL 
				### Outer quantity test
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_reqdetl.part_code 
				IF pr_product.min_ord_qty IS NOT NULL 
				AND pr_product.min_ord_qty != 0 THEN 
					IF pr_reqdetl.req_qty < pr_product.min_ord_qty THEN 
						LET pa_reqdetl[idx].outer_flag = "M" 
					END IF 
				END IF 
				IF pa_reqdetl[idx].outer_flag IS NULL THEN 
					IF pr_reqdetl.req_qty != 0 
					AND (pr_product.outer_qty != 0 
					AND pr_product.outer_qty IS NOT null) THEN 
						LET pr_amt_int = pr_reqdetl.req_qty / pr_product.outer_qty 
						LET pr_amt_flt = pr_reqdetl.req_qty / pr_product.outer_qty 
						IF (pr_amt_flt - pr_amt_int) > 0 
						AND (pr_reqdetl.req_qty < pr_product.outer_qty) THEN 
							LET pa_reqdetl[idx].outer_flag = "O" 
						END IF 
					END IF 
					IF (pr_amt_flt - pr_amt_int) > 0 
					AND (pr_reqdetl.req_qty > pr_product.outer_qty) THEN 
						LET pa_reqdetl[idx].outer_flag = "O" 
					END IF 
				END IF 
				IF idx = 2000 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 
		END IF 
		IF NOT pr_sort_flag THEN 
			OPEN WINDOW n116 with FORM "N116" 
			CALL windecoration_n("N116") -- albo kd-763 
		END IF 
		DISPLAY BY NAME pr_reqhead.req_num, 
		pr_reqhead.person_code, 
		pr_reqperson.name_text, 
		pr_reqhead.del_dept_text, 
		tot_po_appr,tot_stk_appr 

		LET msgresp = kandoomsg("N",1046,"") 
		#1046 Enter on line TO Edit;  F5 Product Inquiry;  F6 Item Inquiry;
		#     F7 Toggle Line;  F8 Toggle All;  F10 Toggle Supply;  OK TO Continue.
		CALL set_count(idx) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET pr_total_amount = 0 
		INPUT ARRAY pa_reqdetl WITHOUT DEFAULTS FROM sr_reqdetl.* 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_scroll_flag = pa_reqdetl[idx].scroll_flag 
				SELECT * INTO pr_reqdetl.* FROM reqdetl 
				WHERE req_num = pr_reqhead.req_num 
				AND line_num = pa_reqdetl[idx].line_num 
				AND cmpy_code = pr_reqhead.cmpy_code 
				LET ps_reqdetl.req_qty = pa_reqdetl[idx].req_qty 
				LET ps_outer_flag = pa_reqdetl[idx].outer_flag 
				LET ps_line_total = pa_reqdetl[idx].line_total 
				LET ps_reqdetl.unit_sales_amt = pa_reqdetl[idx].unit_sales_amt 
				LET ps_reqdetl.replenish_ind = pa_reqdetl[idx].replenish_ind 
				LET ps_reqdetl.vend_code = pa_reqdetl[idx].vend_code 
				SELECT approve_amt INTO tot_po_appr FROM t_approve 
				WHERE replenish_ind = 'P' 
				SELECT approve_amt INTO tot_stk_appr FROM t_approve 
				WHERE replenish_ind = 'S' 
				CASE pa_reqdetl[idx].outer_flag 
					WHEN "M" LET pr_warn_message = "**Below Min Ord**" 
					WHEN "O" LET pr_warn_message = "**Not Multiple**" 
					OTHERWISE LET pr_warn_message = NULL 
				END CASE 
				DISPLAY pr_warn_message TO warn_message 
				attribute(yellow) 
				DISPLAY BY NAME pr_reqdetl.desc_text, 
				tot_po_appr, 
				tot_stk_appr 

				DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

			AFTER FIELD scroll_flag 
				LET pa_reqdetl[idx].scroll_flag = pr_scroll_flag 
				IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
					IF pa_reqdetl[idx+9].part_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9001,"") 
						#9001 No more rows in this direction
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() = arr_count() THEN 
					LET msgresp = kandoomsg("W",9001,"") 
					#9001 No more Rows in direction
					NEXT FIELD scroll_flag 
				END IF 
				DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

			ON KEY (control-b) 
				CASE WHEN infield(vend_code) 
				IF pa_reqdetl[idx].replenish_ind = 'P' THEN 
					LET pr_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,pa_reqdetl[idx].vend_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pa_reqdetl[idx].vend_code = pr_temp_text 
					END IF 
				ELSE 
					LET pr_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF pr_temp_text IS NOT NULL THEN 
						LET pa_reqdetl[idx].vend_code = pr_temp_text 
					END IF 
				END IF 
				NEXT FIELD vend_code 
				END CASE 
			ON KEY (F5) 
				IF pa_reqdetl[idx].part_code IS NOT NULL THEN 
					CALL pinvwind(glob_rec_kandoouser.cmpy_code,pa_reqdetl[idx].part_code) 
				END IF 
			ON KEY (F6) 
				IF pa_reqdetl[idx].part_code IS NOT NULL THEN 
					CALL display_line(pr_reqhead.cmpy_code,pr_reqdetl.*,1, 
					pr_reqhead.ware_code) 
				END IF 
			ON KEY (F7) 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_reqdetl[idx].scroll_flag IS NULL THEN 
					IF pa_reqdetl[idx].vend_code IS NULL THEN 
						LET msgresp = kandoomsg("N",9045,"") 
						#9045 Supply source must bve entered
						NEXT FIELD scroll_flag 
					ELSE 
						SELECT sum(approve_amt) INTO pr_total_amount FROM t_approve 
						IF pr_total_amount IS NULL THEN 
							LET pr_total_amount = 0 
						END IF 
						LET pr_total_amount = pr_total_amount 
						+ pa_reqdetl[idx].line_total 
						IF pr_reqperson2.po_up_limit_amt < pr_total_amount 
						AND glob_rec_reqparms.pend_purch_flag = "N" 
						AND pr_reqperson2.po_up_limit_amt != 0 THEN 
							LET msgresp = kandoomsg("N",9509,"Upper Approval") 						#9509 Upper Approval Limit Exceeded
						ELSE 
							LET pa_reqdetl[idx].scroll_flag = "*" 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
						END IF 
					END IF 
				ELSE 
					LET pa_reqdetl[idx].scroll_flag = NULL 
					CALL update_approve(pa_reqdetl[idx].replenish_ind, 
					pa_reqdetl[idx].line_total,"OUT") 
				END IF 
				DISPLAY pa_reqdetl[idx].scroll_flag TO sr_reqdetl[scrn].scroll_flag 

				NEXT FIELD scroll_flag 
			ON KEY (F8) 
				LET msgresp = kandoomsg("U",1002,"") 
				#1002 Searching Database; Please Wait.
				LET pr_counter = 0 
				FOR idx = 1 TO arr_count() 
					# Check that all requisitions have been approved.
					# IF so, we want TO reset them all back TO being unapproved.
					IF pa_reqdetl[idx].scroll_flag IS NOT NULL THEN 
						LET pr_counter = pr_counter + 1 
					END IF 
				END FOR 
				IF pr_toggle 
				OR pr_counter = arr_count() THEN 
					FOR idx = 1 TO arr_count() 
						IF pa_reqdetl[idx].scroll_flag IS NOT NULL THEN 
							LET pa_reqdetl[idx].scroll_flag = NULL 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,"OUT") 
						END IF 
					END FOR 
					LET pr_toggle = false 
				ELSE 
					LET pr_error_count = 0 
					FOR idx = 1 TO arr_count() 
						IF pa_reqdetl[idx].scroll_flag IS NULL THEN 
							IF valid_vendor(pa_reqdetl[idx].vend_code, 
							pa_reqdetl[idx].line_num, 
							pa_reqdetl[idx].replenish_ind, 
							true) THEN 
								SELECT sum(approve_amt) INTO pr_total_amount FROM t_approve 
								IF pr_total_amount IS NULL THEN 
									LET pr_total_amount = 0 
								END IF 
								LET pr_total_amount = pr_total_amount 
								+ pa_reqdetl[idx].line_total 
								IF pr_reqperson2.po_up_limit_amt < pr_total_amount 
								AND glob_rec_reqparms.pend_purch_flag = "N" 
								AND pr_reqperson2.po_up_limit_amt != 0 THEN 
									LET msgresp = kandoomsg("N",9509,"Upper Approval") 									#9509 Upper Approval Limit Exceeded
									EXIT FOR 
								END IF 
								LET pa_reqdetl[idx].scroll_flag = "*" 
								CALL update_approve(pa_reqdetl[idx].replenish_ind, 
								pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
							ELSE 
								LET pr_error_count = pr_error_count + 1 
							END IF 
						END IF 
					END FOR 
					IF pr_error_count > 0 THEN 
						LET msgresp = kandoomsg("N",9513,pr_error_count) 
						#9513 There are pr_error_count line items that will require..
						LET pr_toggle = false 
					ELSE 
						LET pr_toggle = true 
					END IF 
				END IF 
				FOR scrn = 1 TO 9 
					LET idx = arr_curr() - scr_line() + scrn 
					IF idx <= arr_count() THEN 
						DISPLAY pa_reqdetl[idx].scroll_flag 
						TO sr_reqdetl[scrn].scroll_flag 

					ELSE 
						EXIT FOR 
					END IF 
				END FOR 
				LET msgresp = kandoomsg("N",1046,"") 
				#1046 Enter on line TO Edit;  F5 Product Inquiry;  F6 Item Inquiry;
				#     F7 Toggle Line;  F8 Toggle All;  F10 Toggle Status;  OK TO ...
				NEXT FIELD scroll_flag 
			ON KEY (F9) 
				LET msgresp = kandoomsg("U",1002,"") 
				#1002 Searching Database; Please Wait.
				LET pr_sort_flag = true 
				DELETE FROM t_reqdetl2 WHERE 1=1 
				FOR idx = 1 TO arr_count() 
					LET pr_reqdetl2.scroll_flag = pa_reqdetl[idx].scroll_flag 
					LET pr_reqdetl2.line_num = pa_reqdetl[idx].line_num 
					LET pr_reqdetl2.part_code = pa_reqdetl[idx].part_code 
					LET pr_reqdetl2.req_qty = pa_reqdetl[idx].req_qty 
					LET pr_reqdetl2.uom_code = pa_reqdetl[idx].uom_code 
					LET pr_reqdetl2.outer_flag = pa_reqdetl[idx].outer_flag 
					LET pr_reqdetl2.unit_sales_amt = pa_reqdetl[idx].unit_sales_amt 
					LET pr_reqdetl2.line_total = pa_reqdetl[idx].line_total 
					LET pr_reqdetl2.replenish_ind = pa_reqdetl[idx].replenish_ind 
					LET pr_reqdetl2.vend_code = pa_reqdetl[idx].vend_code 
					SELECT desc_text INTO pr_reqdetl2.desc_text FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pa_reqdetl[idx].part_code 
					IF status = notfound THEN 
						LET pr_reqdetl2.desc_text = " " 
					END IF 
					INSERT INTO t_reqdetl2 VALUES (pr_reqdetl2.*) 
				END FOR 
				EXIT INPUT 
			ON KEY (F10) 
				LET msgresp = kandoomsg("U",1002,"") 
				#1002 searching database;  Please wait.
				LET pr_error_count = 0 
				FOR idx = 1 TO arr_count() 
					IF pa_reqdetl[idx].scroll_flag = '*' THEN 
						CONTINUE FOR 
					END IF 
					IF pa_reqdetl[idx].replenish_ind = "P" THEN 
						LET pa_reqdetl[idx].replenish_ind = "S" 
						SELECT usual_ware_code INTO pa_reqdetl[idx].vend_code 
						FROM puparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						SELECT wgted_cost_amt, status_ind 
						INTO pr_prodstatus.wgted_cost_amt, pr_prodstatus.status_ind 
						FROM prodstatus 
						WHERE part_code = pa_reqdetl[idx].part_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						AND cmpy_code = pr_reqhead.cmpy_code 
						IF status = notfound 
						OR pr_prodstatus.status_ind = "3" 
						OR pa_reqdetl[idx].vend_code IS NULL THEN 
							LET pr_error_count = pr_error_count + 1 
							LET pa_reqdetl[idx].vend_code = "" 
						ELSE 
							LET pa_reqdetl[idx].unit_sales_amt 
							= pr_prodstatus.wgted_cost_amt 
							SELECT * FROM warehouse 
							WHERE cmpy_code = pr_reqhead.cmpy_code 
							AND ware_code = pa_reqdetl[idx].vend_code 
							IF status = notfound 
							OR pa_reqdetl[idx].vend_code = pr_reqhead.ware_code THEN 
								LET pr_error_count = pr_error_count + 1 
								LET pa_reqdetl[idx].vend_code = "" 
							END IF 
						END IF 
					ELSE 
						LET pa_reqdetl[idx].vend_code = "" 
						LET pa_reqdetl[idx].replenish_ind = "P" 
						SELECT * INTO pr_product.* FROM product 
						WHERE part_code = pa_reqdetl[idx].part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pa_reqdetl[idx].vend_code = pr_product.vend_code 
						DECLARE c_prodquote CURSOR FOR 
						SELECT * FROM prodquote 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_reqdetl[idx].part_code 
						AND status_ind = "1" 
						AND expiry_date >= today 
						ORDER BY cost_amt 
						OPEN c_prodquote 
						FETCH c_prodquote INTO pr_prodquote.* 
						IF status = notfound THEN 
							SELECT for_cost_amt INTO pa_reqdetl[idx].unit_sales_amt 
							FROM prodstatus 
							WHERE cmpy_code = pr_reqhead.cmpy_code 
							AND ware_code = pr_reqhead.ware_code 
							AND part_code = pa_reqdetl[idx].part_code 
						ELSE 
							LET pr_conv_rate = 
							get_conv_rate(
								glob_rec_kandoouser.cmpy_code,
								pr_prodquote.curr_code,
								today,
								CASH_EXCHANGE_SELL) 
							LET pa_reqdetl[idx].vend_code = pr_prodquote.vend_code 
							LET pa_reqdetl[idx].unit_sales_amt = pr_prodquote.cost_amt / pr_conv_rate 
							LET pr_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
						END IF 
						CLOSE c_prodquote 
						
						IF pa_reqdetl[idx].vend_code IS NOT NULL THEN 
							SELECT hold_code INTO pr_vendor.hold_code FROM vendor 
							WHERE cmpy_code = pr_reqhead.cmpy_code 
							AND vend_code = pa_reqdetl[idx].vend_code 
							IF status = notfound 
							OR pr_vendor.hold_code = "ST" THEN 
								LET pa_reqdetl[idx].vend_code = "" 
								LET pr_error_count = pr_error_count + 1 
							END IF 
						ELSE 
							LET pr_error_count = pr_error_count + 1 
						END IF 
					END IF 
					LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty 
					* pa_reqdetl[idx].unit_sales_amt 
				END FOR 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_scrn = scr_line() - 1 
				IF pr_scrn = 0 THEN 
					LET pr_scrn = 1 
				ELSE 
					LET pr_scrn = pr_scrn + 1 
				END IF 
				FOR pr_counter = 1 TO 9 
					IF pa_reqdetl[pr_counter].part_code IS NULL 
					OR pa_reqdetl[pr_counter].part_code = " " THEN 
						EXIT FOR 
					END IF 
					DISPLAY pa_reqdetl[idx + pr_counter - pr_scrn].* 
					TO sr_reqdetl[pr_counter].* 

				END FOR 
				IF pr_error_count > 0 THEN 
					LET msgresp = kandoomsg("N",9513,pr_error_count) 
					#9513 There are pr_error_count line items that will require ...
				END IF 
				IF infield(scroll_flag) THEN 
					DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

				END IF 
				LET msgresp = kandoomsg("N",1046,"") 
				#1046 Enter on line TO Edit;  F5 Product Inquiry;  F6 Item Inquiry;
				#     F7 Toggle Line;  F8 Toggle All;  F10 Toggle Supply;  OK ...
			BEFORE FIELD req_qty 
				LET pr_save_qty = pa_reqdetl[idx].req_qty 
				IF pr_reqhead.stock_ind != "0" THEN 
					NEXT FIELD unit_sales_amt 
				END IF 
			AFTER FIELD req_qty 
				IF pa_reqdetl[idx].req_qty IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD req_qty 
				END IF 
				IF pa_reqdetl[idx].req_qty < 0 THEN 
					LET msgresp = kandoomsg("U",9907,"0") 
					#9907 Value must be greater than OR equal TO 0.
					NEXT FIELD req_qty 
				ELSE 
					IF pa_reqdetl[idx].req_qty < pr_reqdetl.po_qty THEN 
						LET msgresp = kandoomsg("U",9907,pr_reqdetl.po_qty) 
						#9907 Value must be greater than VALUE
						LET pa_reqdetl[idx].req_qty = pr_save_qty 
						NEXT FIELD scroll_flag 
					END IF 
					### Outer quantity test
					LET pa_reqdetl[idx].outer_flag = NULL 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_reqdetl.part_code 
					IF pr_product.min_ord_qty IS NOT NULL 
					AND pr_product.min_ord_qty != 0 THEN 
						IF pa_reqdetl[idx].req_qty < pr_product.min_ord_qty THEN 
							LET pa_reqdetl[idx].outer_flag = "M" 
							LET msgresp=kandoomsg("N",7014,pr_product.min_ord_qty) 
							#N7014 Requested quantity IS less than...
						END IF 
					END IF 
					IF pa_reqdetl[idx].outer_flag IS NULL THEN 
						IF pa_reqdetl[idx].req_qty != 0 
						AND (pr_product.outer_qty != 0 
						AND pr_product.outer_qty IS NOT null) THEN 
							LET pr_amt_int = pa_reqdetl[idx].req_qty 
							/ pr_product.outer_qty 
							LET pr_amt_flt = pa_reqdetl[idx].req_qty 
							/ pr_product.outer_qty 
							IF (pr_amt_flt - pr_amt_int) > 0 
							AND (pa_reqdetl[idx].req_qty < pr_product.outer_qty) THEN 
								LET msgresp = kandoomsg("N",9061,pr_product.outer_qty) 
								#9061 Quantity IS NOT a multiple of the pack size.
								LET pa_reqdetl[idx].outer_flag = "O" 
							END IF 
							IF (pr_amt_flt - pr_amt_int) > 0 
							AND (pa_reqdetl[idx].req_qty > pr_product.outer_qty) THEN 
								LET pr_limit_amt = pr_product.outer_qty * pr_amt_int 
								LET pr_low_amt = pr_limit_amt USING "<<<<<<<<&" 
								LET pr_initial_amt = pr_limit_amt + pr_product.outer_qty 
								LET pr_high_amt = pr_initial_amt USING "<<<<<<<<&" 
								LET pr_message_text = pr_low_amt clipped," OR ", 
								pr_high_amt clipped 
								LET pa_reqdetl[idx].outer_flag = "O" 
								LET msgresp = kandoomsg("N",9061,pr_MESSAGE_text) 
								#9061 Quantity IS NOT a multiple of the pack size
							END IF 
						END IF 
					END IF 
					IF pa_reqdetl[idx].scroll_flag = '*' THEN 
						CALL update_approve(pa_reqdetl[idx].replenish_ind, 
						pa_reqdetl[idx].line_total,"OUT") 
					END IF 
					LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty 
					* pa_reqdetl[idx].unit_sales_amt 
					IF pa_reqdetl[idx].scroll_flag = '*' THEN 
						CALL update_approve(pa_reqdetl[idx].replenish_ind, 
						pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
					END IF 
					DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						NEXT FIELD scroll_flag 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD unit_sales_amt 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD scroll_flag 
					OTHERWISE 
						NEXT FIELD req_qty 
				END CASE 
			AFTER FIELD unit_sales_amt 
				IF pa_reqdetl[idx].unit_sales_amt < 0 
				OR pa_reqdetl[idx].unit_sales_amt IS NULL THEN 
					LET msgresp = kandoomsg("U",9927,"0") 
					#9927 Value must be greater than 0
					NEXT FIELD unit_sales_amt 
				ELSE 
					IF pa_reqdetl[idx].scroll_flag = '*' THEN 
						CALL update_approve(pa_reqdetl[idx].replenish_ind, 
						pa_reqdetl[idx].line_total,"OUT") 
					END IF 
					LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty 
					* pa_reqdetl[idx].unit_sales_amt 
					IF pa_reqdetl[idx].scroll_flag = '*' THEN 
						CALL update_approve(pa_reqdetl[idx].replenish_ind, 
						pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
					END IF 
				END IF 
				DISPLAY pa_reqdetl[idx].line_total TO sr_reqdetl[scrn].line_total 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						NEXT FIELD scroll_flag 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD replenish_ind 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD req_qty 
					OTHERWISE 
						NEXT FIELD unit_sales_amt 
				END CASE 
			BEFORE FIELD replenish_ind 
				LET pr_save_replenish_ind = pa_reqdetl[idx].replenish_ind 
				LET pr_temp_line_total = pa_reqdetl[idx].line_total 
			AFTER FIELD replenish_ind 
				IF pa_reqdetl[idx].replenish_ind != pr_save_replenish_ind 
				OR pa_reqdetl[idx].replenish_ind IS NULL THEN 
					CASE pa_reqdetl[idx].replenish_ind 
						WHEN "S" 
							SELECT usual_ware_code INTO pa_reqdetl[idx].vend_code 
							FROM puparms 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						OTHERWISE 
							LET pa_reqdetl[idx].replenish_ind = "P" 
							SELECT * INTO pr_product.* FROM product 
							WHERE part_code = pa_reqdetl[idx].part_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET pa_reqdetl[idx].vend_code = pr_product.vend_code 
					END CASE 
					IF pa_reqdetl[idx].replenish_ind = "P" THEN 
						DECLARE c_prodquote2 CURSOR FOR 
						SELECT * FROM prodquote 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_reqdetl[idx].part_code 
						AND status_ind = "1" 
						AND expiry_date >= today 
						ORDER BY cost_amt 
						OPEN c_prodquote2 
						FETCH c_prodquote2 INTO pr_prodquote.* 
						IF status = notfound THEN 
							SELECT for_cost_amt INTO pa_reqdetl[idx].unit_sales_amt FROM prodstatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = pr_reqhead.ware_code 
							AND part_code = pa_reqdetl[idx].part_code 
						ELSE 
							LET pr_conv_rate = get_conv_rate(
								glob_rec_kandoouser.cmpy_code,
								pr_prodquote.curr_code,
								today,
								CASH_EXCHANGE_SELL) 
							LET pa_reqdetl[idx].vend_code = pr_prodquote.vend_code 
							LET pa_reqdetl[idx].unit_sales_amt = pr_prodquote.cost_amt / pr_conv_rate 
							LET pr_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
						END IF 
					ELSE 
						SELECT * INTO pr_prodstatus.* FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						AND part_code = pa_reqdetl[idx].part_code 
						LET pa_reqdetl[idx].unit_sales_amt = pr_prodstatus.wgted_cost_amt 
					END IF 
					
					LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty * pa_reqdetl[idx].unit_sales_amt 
					
					DISPLAY pa_reqdetl[idx].replenish_ind, 
					pa_reqdetl[idx].vend_code, 
					pa_reqdetl[idx].line_total, 
					pa_reqdetl[idx].unit_sales_amt 
					TO sr_reqdetl[scrn].replenish_ind, 
					sr_reqdetl[scrn].vend_code, 
					sr_reqdetl[scrn].line_total, 
					sr_reqdetl[scrn].unit_sales_amt 

				END IF 
				IF pa_reqdetl[idx].replenish_ind = 'P' THEN 
					IF pa_reqdetl[idx].vend_code IS NOT NULL THEN 
						SELECT * INTO pr_vendor.* FROM vendor 
						WHERE cmpy_code = pr_reqhead.cmpy_code 
						AND vend_code = pa_reqdetl[idx].vend_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("U",9105,"") 
							#9105 RECORD NOT found
							NEXT FIELD vend_code 
						ELSE 
							IF pr_vendor.hold_code = "ST" THEN 
								LET msgresp=kandoomsg("N",9046,"") 
								#9046 Vendor IS on hold
								NEXT FIELD vend_code 
							END IF 
						END IF 
					END IF 
				ELSE 
					IF pa_reqdetl[idx].vend_code IS NOT NULL THEN 
						SELECT * FROM warehouse 
						WHERE cmpy_code = pr_reqhead.cmpy_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("U",9105,"") 
							#9105 RECORD NOT found
							NEXT FIELD vend_code 
						END IF 
						IF pa_reqdetl[idx].vend_code = pr_reqhead.ware_code THEN 
							LET msgresp = kandoomsg("I",9111,"") 
							#9111 source & dest warehouse cannot be the same.
							NEXT FIELD vend_code 
						END IF 
						SELECT * INTO pr_prodstatus.* FROM prodstatus 
						WHERE part_code = pa_reqdetl[idx].part_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						AND cmpy_code = pr_reqhead.cmpy_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("I",7035,"") 
							# I7035 Product STATUS FOR warehouse NOT found,try again
							NEXT FIELD vend_code 
						END IF 
						IF pr_prodstatus.status_ind = "3" THEN 
							LET msgresp = kandoomsg("U",9915,pa_reqdetl[idx].vend_code) 
							#9915 Product has been deleted AT the MEL warehouse
							NEXT FIELD vend_code 
						END IF 
					END IF 
				END IF 
				IF pa_reqdetl[idx].scroll_flag = '*' THEN 
					CALL update_approve(ps_reqdetl.replenish_ind, 
					pr_temp_line_total,"OUT") 
					LET pa_reqdetl[idx].line_total = pa_reqdetl[idx].req_qty 
					* pa_reqdetl[idx].unit_sales_amt 
					CALL update_approve(pa_reqdetl[idx].replenish_ind, 
					pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						NEXT FIELD scroll_flag 
					WHEN fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD vend_code 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD unit_sales_amt 
					OTHERWISE 
						NEXT FIELD replenish_ind 
				END CASE 
			AFTER FIELD vend_code 
				IF pa_reqdetl[idx].replenish_ind = 'P' THEN 
					IF pa_reqdetl[idx].vend_code IS NOT NULL THEN 
						SELECT * INTO pr_vendor.* FROM vendor 
						WHERE cmpy_code = pr_reqhead.cmpy_code 
						AND vend_code = pa_reqdetl[idx].vend_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("U",9105,"") 
							#9105 RECORD NOT found
							NEXT FIELD vend_code 
						ELSE 
							IF pr_vendor.hold_code = "ST" THEN 
								LET msgresp=kandoomsg("N",9046,"") 
								#9046 Vendor IS on hold
								NEXT FIELD vend_code 
							END IF 
						END IF 
					ELSE 
						IF pa_reqdetl[idx].scroll_flag = "*" THEN 
							LET pa_reqdetl[idx].scroll_flag = "" 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,"OUT") 
						END IF 
					END IF 
				ELSE 
					IF pa_reqdetl[idx].vend_code IS NOT NULL THEN 
						SELECT * FROM warehouse 
						WHERE cmpy_code = pr_reqhead.cmpy_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("U",9105,"") 
							#9105 RECORD NOT found
							NEXT FIELD vend_code 
						END IF 
						IF pa_reqdetl[idx].vend_code = pr_reqhead.ware_code THEN 
							LET msgresp = kandoomsg("I",9111,"") 
							#9111 source & dest warehouse cannot be the same
							NEXT FIELD vend_code 
						END IF 
						SELECT * INTO pr_prodstatus.* FROM prodstatus 
						WHERE part_code = pa_reqdetl[idx].part_code 
						AND ware_code = pa_reqdetl[idx].vend_code 
						AND cmpy_code = pr_reqhead.cmpy_code 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("I",7035,"") 
							#7035 Product STATUS FOR warehouse NOT found,try again
							NEXT FIELD vend_code 
						END IF 
						IF pr_prodstatus.status_ind = "3" THEN 
							LET msgresp = kandoomsg("U",9915,pa_reqdetl[idx].vend_code) 
							#9915 Product has been deleted AT the MEL warehouse
							NEXT FIELD vend_code 
						END IF 
					ELSE 
						IF pa_reqdetl[idx].scroll_flag = "*" THEN 
							LET pa_reqdetl[idx].scroll_flag = "" 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,"OUT") 
						END IF 
					END IF 
				END IF 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("down") 
						NEXT FIELD scroll_flag 
					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD replenish_ind 
					OTHERWISE 
						NEXT FIELD vend_code 
				END CASE 
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT (infield(scroll_flag)) THEN 
						IF pa_reqdetl[idx].scroll_flag = '*' THEN 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,"OUT") 
						END IF 
						LET pa_reqdetl[idx].req_qty = ps_reqdetl.req_qty 
						LET pa_reqdetl[idx].outer_flag = ps_outer_flag 
						LET pa_reqdetl[idx].unit_sales_amt = ps_reqdetl.unit_sales_amt 
						LET pa_reqdetl[idx].line_total = ps_line_total 
						LET pa_reqdetl[idx].replenish_ind = ps_reqdetl.replenish_ind 
						LET pa_reqdetl[idx].vend_code = ps_reqdetl.vend_code 
						IF pa_reqdetl[idx].scroll_flag = '*' THEN 
							CALL update_approve(pa_reqdetl[idx].replenish_ind, 
							pa_reqdetl[idx].line_total,TRAN_TYPE_INVOICE_IN) 
						END IF 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				LET pr_sort_flag = false 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF NOT pr_sort_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		### Restore approved amount TO original STATUS
		FOR idx = 1 TO arr_count() 
			IF pa_reqdetl[idx].scroll_flag = '*' THEN 
				CALL update_approve(pa_reqdetl[idx].replenish_ind, 
				pa_reqdetl[idx].line_total,"OUT") 
			END IF 
			SELECT replenish_ind,(po_qty * unit_sales_amt) 
			INTO pr_replenish_ind,pr_line_total 
			FROM reqpurch 
			WHERE req_num = pr_reqhead.req_num 
			AND line_num = pa_reqdetl[idx].line_num 
			IF status = 0 THEN 
				CALL update_approve(pr_replenish_ind, 
				pr_line_total,TRAN_TYPE_INVOICE_IN) 
			END IF 
		END FOR 
	ELSE 
		LET msgresp=kandoomsg("U",1005,"") 
		#1005 Updating Database;  Please Wait.
		GOTO bypass 
		LABEL recovery: 
		LET err_continue = error_recover(err_message,status) 
		IF err_continue != "Y" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			FOR idx = 1 TO arr_count() 
				LET err_message = "N41 - RE Requisition Detail Update " 
				DECLARE c3_reqdetl CURSOR FOR 
				SELECT * FROM reqdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqhead.req_num 
				AND line_num = pa_reqdetl[idx].line_num 
				FOR UPDATE 
				OPEN c3_reqdetl 
				FETCH c3_reqdetl INTO pr_reqdetl.* 
				DELETE FROM reqpurch 
				WHERE req_num = pr_reqhead.req_num 
				AND line_num = pa_reqdetl[idx].line_num 
				IF pa_reqdetl[idx].scroll_flag IS NOT NULL 
				AND pa_reqdetl[idx].scroll_flag = '*' THEN 
					LET pr_po_qty = pa_reqdetl[idx].req_qty 
					UPDATE reqpurch 
					SET replenish_ind = pa_reqdetl[idx].replenish_ind, 
					unit_sales_amt = pa_reqdetl[idx].unit_sales_amt, 
					vend_code = pa_reqdetl[idx].vend_code, 
					po_qty = pr_po_qty 
					WHERE req_num = pr_reqhead.req_num 
					AND line_num = pa_reqdetl[idx].line_num 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO reqpurch VALUES (pa_reqdetl[idx].vend_code, 
						pr_reqhead.ware_code, 
						pa_reqdetl[idx].part_code, 
						pr_reqhead.req_num, 
						pa_reqdetl[idx].line_num, 
						pa_reqdetl[idx].replenish_ind, 
						pa_reqdetl[idx].unit_sales_amt, 
						pr_po_qty, 
						pr_reqdetl.desc_text ) 
					END IF 
				END IF 
				UPDATE t_reqdetl 
				SET approve_qty = pa_reqdetl[idx].req_qty 
				WHERE req_num = pr_reqhead.req_num 
				AND line_num = pa_reqdetl[idx].line_num 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO t_reqdetl VALUES ( pr_reqhead.req_num, 
					pa_reqdetl[idx].line_num, 
					pa_reqdetl[idx].req_qty ) 
				END IF 
				LET pr_reqdetl.seq_num = pr_reqdetl.seq_num + 1 
				UPDATE reqdetl 
				SET seq_num = pr_reqdetl.seq_num, 
				vend_code = pa_reqdetl[idx].vend_code, 
				replenish_ind = pa_reqdetl[idx].replenish_ind, 
				req_qty = pa_reqdetl[idx].req_qty, 
				unit_sales_amt = pa_reqdetl[idx].unit_sales_amt, 
				unit_cost_amt = pa_reqdetl[idx].unit_sales_amt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqhead.req_num 
				AND line_num = pa_reqdetl[idx].line_num 
			END FOR 
			LET err_message = "N14 - Requisition Header Update" 
			SELECT sum(unit_sales_amt * req_qty) INTO pr_total_sales_amt 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqhead.req_num 
			AND req_qty IS NOT NULL 
			AND unit_sales_amt IS NOT NULL 
			IF pr_total_sales_amt IS NULL THEN 
				LET pr_total_sales_amt = 0 
			END IF 
			UPDATE reqhead 
			SET total_sales_amt = pr_total_sales_amt, 
			total_cost_amt = pr_total_sales_amt, 
			last_mod_code = glob_rec_kandoouser.sign_on_code, 
			last_mod_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqhead.req_num 
		COMMIT WORK 
	END IF 
	CLOSE WINDOW n116 
END FUNCTION 
