{
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

	Source code beautified by beautify.pl on 2020-01-02 17:06:15	Source code beautified by beautify.pl on 2020-01-02 17:03:24	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R21_GLOBALS.4gl" 

DEFINE 
pr_msg_flag SMALLINT 

FUNCTION select_mode() 
	DEFINE 
	pr_status_ind CHAR(1), 
	pr_mode_allowed CHAR(1) 

	LET pr_mode_allowed = get_kandoooption_feature_state("PU", "RM") 

	OPEN WINDOW r113 with FORM "R113" 
	CALL  windecoration_r("R113") 

	CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
	WHILE true 
		MENU " Receipt Mode" 

		#BEFORE MENU IS new section TO control goods receipt method allowed


			BEFORE MENU 
				CALL publish_toolbar("kandoo","R19","menu-receipt_mode-1") 

				HIDE option all 
				LET pr_prev_mode = 0 
				CASE (pr_mode_allowed) 
					WHEN "1" 
						SHOW option "Manual", "Exit" 
					WHEN "2" 
						SHOW option "Product", "Exit" 
					WHEN "3" 
						SHOW option "Line", "Exit" 
					WHEN "4" 
						SHOW option all 
					WHEN "5" 
						SHOW option "Manual", "Product", "Exit" 
					WHEN "6" 
						SHOW option "Manual", "Line", "Exit" 
					WHEN "7" 
						SHOW option "Product", "Line", "Exit" 
				END CASE 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 



			COMMAND "Product" " Enter product TO be received" 
				LET pr_mode = "1" 
				IF pr_prev_mode != "1" THEN 
					DELETE FROM t_purchdetl WHERE 1=1 
					DELETE FROM t_poaudit WHERE 1=1 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
				END IF 
				LET pr_prev_mode = pr_mode 
				CALL prod_lineitem(pr_mode) RETURNING pr_status_ind 
				EXIT MENU 
			COMMAND "Manual" " Default received quantity" 
				LET pr_mode = "2" 
				IF pr_prev_mode != "2" THEN 
					DELETE FROM t_purchdetl WHERE 1=1 
					DELETE FROM t_poaudit WHERE 1=1 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
				END IF 
				LET pr_prev_mode = pr_mode 
				CALL lineitem(pr_mode) RETURNING pr_status_ind 
				EXIT MENU 
			COMMAND "Line" " Set received quantity TO zero" 
				LET pr_mode = "3" 
				IF pr_prev_mode != "3" THEN 
					DELETE FROM t_purchdetl WHERE 1=1 
					DELETE FROM t_poaudit WHERE 1=1 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
				END IF 
				LET pr_prev_mode = pr_mode 
				CALL lineitem(pr_mode) RETURNING pr_status_ind 
				EXIT MENU 
			COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Header Details" 
				LET int_flag = false 
				LET quit_flag = false 
				LET pr_status_ind = "3" 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
		CASE pr_status_ind 
			WHEN "1" 
				CLOSE WINDOW r113 
				RETURN true 
			WHEN "3" 
				CLOSE WINDOW r113 
				RETURN false 
			OTHERWISE 
				CONTINUE WHILE 
		END CASE 
	END WHILE 
	CLOSE WINDOW r113 
END FUNCTION 


FUNCTION lineitem(pr_mode) 
	DEFINE 
	pr_mode CHAR(1), 
	pr_jmresource RECORD LIKE jmresource.*, 
	ps_poaudit RECORD LIKE poaudit.*, 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	pa_purchdetl ARRAY [2020] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE purchdetl.line_num, 
		type_ind LIKE purchdetl.type_ind, 
		ref_text LIKE purchdetl.ref_text, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		serial_flag LIKE product.serial_flag, 
		uom_code LIKE purchdetl.uom_code, 
		unit_cost_amt LIKE poaudit.unit_cost_amt 
	END RECORD, 
	scrn, id_flag,j,acount, ins_flag, del_flag SMALLINT, 
	pr_err_cnt,pr_warn_cnt SMALLINT, 
	pa_purchqty ARRAY [2020] OF RECORD 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty 
	END RECORD, 
	pa_shipflag ARRAY [2020] OF SMALLINT, 
	pr_shipment_total LIKE poaudit.line_total_amt, 
	pr_type_ind LIKE purchdetl.type_ind, 
	pr_res_code LIKE jmresource.res_code, 
	pr_received_qty LIKE poaudit.received_qty, 
	pr_new_received_qty LIKE poaudit.received_qty, 
	outstand_total, 
	vouch_amt,tax_amt,order_total,received_total LIKE poaudit.line_total_amt, 
	pr_available_amt, pr_check_amt, pr_ser_received_total LIKE poaudit.line_total_amt, 
	pr_status_ind CHAR(1), 
	pr_serial CHAR(1), 
	pr_serial_err CHAR(1), 
	pr_skip_input CHAR(1), 
	pr_ser_cnt SMALLINT, 
	pr_ser_cnt2 SMALLINT, 
	idx,i,arr_size SMALLINT, 
	pr_valid_tran CHAR(1) 

	INITIALIZE pr_purchdetl.* TO NULL 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f36 
	DECLARE c_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE order_num = pr_purchhead.order_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY line_num 
	LET msgresp=kandoomsg("U",1002,"") 
	#1002 Searching Database; Please wait
	DELETE FROM t_purchdetl WHERE 1=1 
	CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
	LET pr_ser_received_total = 0 
	LET pr_shipment_total = 0 
	LET idx = 0 
	FOREACH c_purchdetl INTO pr_purchdetl.* 
		LET idx = idx + 1 
		LET pa_purchdetl[idx].scroll_flag = NULL 
		LET pa_purchdetl[idx].line_num = pr_purchdetl.line_num 
		LET pa_purchdetl[idx].type_ind = pr_purchdetl.type_ind 
		LET pa_purchdetl[idx].ref_text = pr_purchdetl.ref_text 
		IF pr_purchdetl.type_ind = "J" THEN 
			LET pa_purchdetl[idx].ref_text = pr_purchdetl.res_code 
		END IF 
		LET pa_purchdetl[idx].uom_code = pr_purchdetl.uom_code 
		CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
		pr_purchdetl.order_num, 
		pr_purchdetl.line_num) 
		RETURNING pr_poaudit.order_qty, 
		pr_poaudit.received_qty, 
		pr_poaudit.voucher_qty, 
		pr_poaudit.unit_cost_amt, 
		pr_poaudit.ext_cost_amt, 
		pr_poaudit.unit_tax_amt, 
		pr_poaudit.ext_tax_amt, 
		pr_poaudit.line_total_amt 
		LET pa_purchdetl[idx].unit_cost_amt = pr_poaudit.unit_cost_amt 
		LET pa_purchdetl[idx].order_qty = pr_poaudit.order_qty 
		LET pa_purchdetl[idx].received_qty = pr_poaudit.order_qty 
		- pr_poaudit.received_qty 
		LET pa_purchqty[idx].order_qty = pr_poaudit.order_qty 
		LET pa_purchqty[idx].received_qty = pr_poaudit.received_qty 
		LET pa_purchqty[idx].voucher_qty = pr_poaudit.voucher_qty 
		LET pa_purchdetl[idx].serial_flag = "N" 
		IF pr_purchdetl.type_ind matches "[IC]" THEN 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_purchdetl.ref_text 
			AND serial_flag = 'Y' 
			IF status <> notfound THEN 
				LET pa_purchdetl[idx].serial_flag = "Y" 
				IF pr_mode = '2' THEN 
					LET pa_purchdetl[idx].received_qty = 0 
					LET pr_ser_received_total = pr_ser_received_total 
					+ (( pr_poaudit.order_qty - pr_poaudit.received_qty) 
					* ( pr_poaudit.unit_cost_amt 
					+ pr_poaudit.unit_tax_amt)) 
				END IF 
			END IF 
		END IF 
		IF pr_mode = "3" THEN 
			LET pa_purchdetl[idx].received_qty = 0 
		END IF 
		# Cannot receipt shipment lines
		SELECT unique 1 
		FROM shipdetl, shiphead 
		WHERE shipdetl.source_doc_num = pr_purchdetl.order_num 
		AND shipdetl.doc_line_num = pr_purchdetl.line_num 
		AND shipdetl.ship_inv_qty > 0 
		AND shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shipdetl.cmpy_code = shiphead.cmpy_code 
		AND shipdetl.ship_code = shiphead.ship_code 
		AND shiphead.finalised_flag <> "Y" 
		IF status = notfound THEN 
			LET pa_shipflag[idx] = false 
		ELSE 
			LET pa_shipflag[idx] = true 
			LET pa_purchdetl[idx].received_qty = 0 
			LET pa_purchqty[idx].received_qty = 0 
			LET pr_shipment_total = pr_shipment_total 
			+ (( pr_poaudit.order_qty - pr_poaudit.received_qty) 
			* ( pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt)) 
		END IF 
		INSERT INTO t_purchdetl VALUES (pr_purchdetl.*) 
		IF idx = 2000 THEN 
			LET msgresp=kandoomsg("R",9001,idx) 
			#9001 First 2000 rows selected.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL po_head_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
	RETURNING order_total, 
	received_total, 
	vouch_amt, 
	tax_amt 
	IF pr_mode = "2" THEN 
		LET received_total = order_total 
		- pr_ser_received_total 
		- pr_shipment_total 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("R",1023,"") 
	#1023 F5 Product Inquiry;  F7 Allocation;  F8 Bar Codes; ...
	LET pr_msg_flag = false 
	INPUT ARRAY pa_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R21b","inp-arr-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (F9) 
			CALL ord_window(glob_rec_kandoouser.cmpy_code,pa_purchdetl[idx].line_num, 
			pr_purchhead.order_num, 
			pa_purchdetl[idx].received_qty) 
			NEXT FIELD received_qty 
		ON KEY (F5) 
			SELECT type_ind INTO pr_type_ind FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			AND line_num = pa_purchdetl[idx].line_num 
			IF pr_type_ind != "I" 
			AND pr_type_ind != "C" THEN 
				LET msgresp = kandoomsg("R",9522,"") 
				#9522 This FUNCTION IS NOT applicable TO this line type.
			ELSE 
				IF pa_purchdetl[idx].ref_text IS NOT NULL THEN 
					CALL pinvwind(glob_rec_kandoouser.cmpy_code,pa_purchdetl[idx].ref_text) 
				END IF 
			END IF 
		ON KEY (F8) 
			CALL run_prog("I18","","","","") 
		ON KEY (F7) 
			SELECT type_ind, res_code INTO pr_type_ind, pr_res_code FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			AND line_num = pa_purchdetl[idx].line_num 
			IF pr_type_ind != "J" 
			AND pr_type_ind != "C" THEN 
				LET msgresp = kandoomsg("R",9522,"") 
				#9522 This FUNCTION IS NOT applicable TO this line type.
			ELSE 

				IF pr_res_code IS NOT NULL THEN 
					SELECT * INTO pr_jmresource.* FROM jmresource 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND res_code = pr_res_code 

					IF pa_jmresource[idx].allocation_ind IS NULL THEN 
						LET pa_jmresource[idx].allocation_ind 
						= pr_jmresource.allocation_ind 
					END IF 
					IF pr_jmresource.allocation_flag <> "1" OR 
					pr_jmresource.allocation_flag IS NULL THEN 
						LET msgresp = kandoomsg("J",9555,"") 
						#9555 Resource does NOT permit user TO overide the Alloc...
					ELSE 
						CALL adjust_allocflag(glob_rec_kandoouser.cmpy_code, 
						pr_jmresource.res_code, 
						pa_jmresource[idx].allocation_ind) 
						RETURNING pa_jmresource[idx].allocation_ind 
					END IF 
				END IF 
			END IF 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

			IF (fgl_lastkey() = fgl_keyval("prevpage") 
			OR fgl_lastkey() = fgl_keyval("up")) 
			AND pa_purchdetl[idx].scroll_flag = "*" THEN 
				LET msgresp = kandoomsg("R",9010,"") 
				#9010 Received qty > outstanding qty.
			END IF 
		BEFORE FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				IF pa_purchdetl[idx].scroll_flag = "*" THEN 
					LET msgresp = kandoomsg("R",9010,"") 
					#9010 Received qty > outstanding qty.
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
				END IF 
				NEXT FIELD received_qty 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_purchdetl[idx+1].line_num IS NULL 
				OR pa_purchdetl[idx+1].line_num = 0 THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD received_qty 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND (pa_purchdetl[idx+11].line_num IS NULL 
			OR pa_purchdetl[idx+11].line_num = 0) THEN 
				IF pa_purchdetl[idx].scroll_flag = "*" THEN 
					LET msgresp = kandoomsg("R",9010,"") 
					#9010 Received qty > outstanding qty.
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
				END IF 
				NEXT FIELD received_qty 
			END IF 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

			NEXT FIELD received_qty 

		BEFORE FIELD order_qty 
			NEXT FIELD received_qty 

		BEFORE FIELD received_qty 
			LET ps_poaudit.received_qty = pa_purchdetl[idx].received_qty 
			SELECT * INTO pr_purchdetl.* FROM t_purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			AND line_num = pa_purchdetl[idx].line_num 
			INITIALIZE pr_product.* TO NULL 
			IF pr_purchdetl.type_ind = "I" 
			OR pr_purchdetl.type_ind = "C" THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_purchdetl.ref_text 
			END IF 
			LET outstand_total = pa_purchqty[idx].order_qty - 
			(pa_purchqty[idx].received_qty + pa_purchdetl[idx].received_qty) 
			DISPLAY BY NAME pr_purchdetl.desc_text, 
			pr_product.oem_text, 
			pr_product.bar_code_text, 

			outstand_total, 
			order_total, 
			received_total 


			LET pr_received_qty = pa_purchdetl[idx].received_qty 


































































		AFTER FIELD received_qty 
			# Cannot receipt shipment lines
			IF pa_shipflag[idx] AND pa_purchdetl[idx].received_qty <> 0 THEN 
				LET msgresp = kandoomsg("R",9015,"") 
				#9015 Cannot enter shipment line receipt through Purchasing
				LET pa_purchdetl[idx].received_qty = 0 
				NEXT FIELD received_qty 
			END IF 

			## Calculate the new received quantity. Less than zero
			## OR less than the total vouchered TO date.
			LET pr_serial_err = 'N' 
			IF pr_product.serial_flag = 'Y' 
			AND pa_purchdetl[idx].received_qty <> pr_received_qty THEN 
				LET pr_serial_err = 'Y' 
				LET pa_purchdetl[idx].received_qty = pr_received_qty 
			END IF 
			IF pa_purchdetl[idx].received_qty IS NULL THEN 
				LET pa_purchdetl[idx].received_qty = 0 
			END IF 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchhead.order_num, 
			pa_purchdetl[idx].line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			LET pr_new_received_qty = pa_purchqty[idx].received_qty + 
			pa_purchdetl[idx].received_qty 
			IF pr_new_received_qty > pa_purchqty[idx].order_qty THEN 
				LET pr_check_amt = pr_new_received_qty * 
				(pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt) 
				CALL check_funds(glob_rec_kandoouser.cmpy_code, 
				pr_purchdetl.acct_code, 
				pr_check_amt, 
				pr_purchdetl.line_num, 
				pr_poaudit.year_num, 
				pr_poaudit.period_num, 
				"R", 
				pr_purchhead.order_num, 
				"N") 
				RETURNING pr_valid_tran, pr_available_amt 
				IF NOT pr_valid_tran THEN 
					LET msgresp = kandoomsg("U",9939,"") 
					#9939 Insufficient Approved Funds
					LET pa_purchdetl[idx].scroll_flag = NULL 
					NEXT FIELD received_qty 
				END IF 
				IF get_kandoooption_feature_state("PU","GR") = "Y" THEN 
					LET msgresp = kandoomsg("R",9010,"") 
					#9010 Received qty > outstanding qty.
					LET pa_purchdetl[idx].scroll_flag = "*" 
				ELSE 
					LET msgresp = kandoomsg("R",9515,"") 
					#9515 Received qty cannot be greater than ORDER qty.
					LET pa_purchdetl[idx].scroll_flag = NULL 
					NEXT FIELD received_qty 
				END IF 
			ELSE 
				LET pa_purchdetl[idx].scroll_flag = NULL 
			END IF 
			IF pr_received_qty != pa_purchdetl[idx].received_qty THEN 
				LET received_total = received_total 
				- (pr_received_qty 
				* (pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt)) 
				LET received_total = received_total 
				+ (pa_purchdetl[idx].received_qty 
				* (pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt)) 
			END IF 
			IF pr_new_received_qty < 0 THEN 
				LET msgresp = kandoomsg("R", 9512, "") 
				#9512 This entry will reduce total received TO less than zero
				NEXT FIELD received_qty 
			END IF 
			IF pr_new_received_qty < pa_purchqty[idx].voucher_qty THEN 
				LET msgresp = kandoomsg("R", 9513, "") 
				#9513 This entry will reduce total received TO less than invoiced
				NEXT FIELD received_qty 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") THEN 
				IF pa_purchdetl[idx+1].line_num IS NULL 
				OR pa_purchdetl[idx+1].line_num = 0 THEN 
					IF pa_purchdetl[idx].scroll_flag = "*" THEN 
						LET msgresp = kandoomsg("R",9010,"") 
						#9010 Received qty > outstanding qty.
					ELSE 
						IF pa_purchdetl[idx].serial_flag = "Y" THEN 
							NEXT FIELD serial_flag 
						ELSE 
							LET msgresp = kandoomsg("U",9001,"") 
							#9001 There no more rows...
						END IF 
					END IF 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF pr_serial_err = 'Y' THEN 
				LET msgresp = kandoomsg("I",9301,"") 
				#9301 Use Serial Code window TO alter Receipt Quantity.
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND (pa_purchdetl[idx+11].line_num IS NULL 
			OR pa_purchdetl[idx+11].line_num = 0) THEN 
				LET msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 


		BEFORE FIELD serial_flag 
			IF pa_purchdetl[idx].serial_flag = 'Y' THEN 
				# check that we dont have this product already
				LET pr_skip_input = 'N' 
				IF idx >= 1 THEN 
					FOR i = 1 TO arr_count() 
						IF i <> idx 
						AND pa_purchdetl[i].received_qty <> 0 THEN 
							SELECT unique 1 FROM t_purchdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pr_purchhead.order_num 
							AND line_num = pa_purchdetl[i].line_num 
							AND type_ind matches "[IC]" 
							AND ref_text = pr_purchdetl.ref_text 
							IF status <> notfound THEN 
								LET pa_purchdetl[idx].received_qty = 0 
								LET pr_skip_input = 'Y' 
							END IF 
						END IF 
					END FOR 
				END IF 
				IF pr_skip_input = 'N' THEN 
					LET pr_ser_cnt = serial_count(pr_product.part_code, 
					pr_purchhead.ware_code) 
					LET pr_ser_cnt2 = serial_input(pr_product.part_code, 
					pr_purchhead.ware_code, 
					pr_ser_cnt) 
					OPTIONS DELETE KEY f36, 
					INSERT KEY f36 
					IF pr_ser_cnt2 < 0 THEN 
						IF pr_ser_cnt2 = -1 THEN 


						ELSE 
							CALL errorlog("R21b - Fatal error in serial_input ") 
							EXIT program 
						END IF 
					ELSE 
						LET pa_purchdetl[idx].received_qty 
						= pa_purchdetl[idx].received_qty + pr_ser_cnt2 
						- pr_ser_cnt 
					END IF 
				END IF 
				IF pr_received_qty != pa_purchdetl[idx].received_qty THEN 
					CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
					pr_purchhead.order_num, 
					pa_purchdetl[idx].line_num) 
					RETURNING pr_poaudit.order_qty, 
					pr_poaudit.received_qty, 
					pr_poaudit.voucher_qty, 
					pr_poaudit.unit_cost_amt, 
					pr_poaudit.ext_cost_amt, 
					pr_poaudit.unit_tax_amt, 
					pr_poaudit.ext_tax_amt, 
					pr_poaudit.line_total_amt 
					LET received_total = received_total 
					+ ((pa_purchdetl[idx].received_qty - pr_received_qty) 
					* ( pr_poaudit.unit_cost_amt 
					+ pr_poaudit.unit_tax_amt)) 
					DISPLAY BY NAME received_total 

					LET pr_received_qty = pa_purchdetl[idx].received_qty 
				END IF 
				NEXT FIELD received_qty 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(received_qty)) THEN 
					LET pa_purchdetl[idx].received_qty = ps_poaudit.received_qty 
					LET int_flag = false 
					LET quit_flag = false 
					NEXT FIELD scroll_flag 
				ELSE 
					LET msgresp=kandoomsg("R",8008,"") 
					#8008 Changes made will be removed
					IF msgresp = "N" THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
					DELETE FROM t_purchdetl 
					WHERE 1=1 
					DELETE FROM t_poaudit 
					WHERE 1=1 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
					FOR idx = 1 TO arr_count() 
						LET pa_jmresource[idx].allocation_ind = NULL 
					END FOR 
				END IF 
			ELSE 
				LET arr_size = arr_count() 
				LET pr_warn_cnt = 0 
				DELETE FROM t_poaudit WHERE 1=1 
				FOR i = 1 TO arr_size 
					IF pa_purchdetl[i].line_num IS NOT NULL THEN 

						SELECT * INTO pr_purchdetl.* FROM purchdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND order_num = pr_purchhead.order_num 
						AND line_num = pa_purchdetl[i].line_num 

						LET pr_serial = 'N' 
						IF pr_purchdetl.type_ind = 'I' 
						OR pr_purchdetl.type_ind = "C" THEN 
							SELECT unique 1 FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_purchdetl.ref_text 
							AND serial_flag = 'Y' 
							IF status <> notfound THEN 
								LET pr_serial = 'Y' 
							END IF 
						END IF 
						IF pa_purchdetl[i].received_qty != 0 
						OR pr_serial = 'Y' THEN 

							SELECT * INTO pf_purchdetl.* FROM t_purchdetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND order_num = pr_purchhead.order_num 
							AND line_num = pa_purchdetl[i].line_num 
							CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
							pr_purchdetl.order_num, 
							pr_purchdetl.line_num) 
							RETURNING pr_poaudit.order_qty, 
							pr_poaudit.received_qty, 
							pr_poaudit.voucher_qty, 
							pr_poaudit.unit_cost_amt, 
							pr_poaudit.ext_cost_amt, 
							pr_poaudit.unit_tax_amt, 
							pr_poaudit.ext_tax_amt, 
							pr_poaudit.line_total_amt 
							IF pr_purchdetl.seq_num != pf_purchdetl.seq_num THEN 
								LET pr_warn_cnt = pr_warn_cnt + 1 
							END IF 
							LET pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET pr_poaudit.po_num = pr_purchdetl.order_num 
							LET pr_poaudit.line_num = pa_purchdetl[i].line_num 
							LET pr_poaudit.tran_date = save_date 
							LET pr_poaudit.received_qty = pa_purchdetl[i].received_qty 
							LET pr_poaudit.order_qty = pa_purchdetl[i].order_qty 
							LET pr_poaudit.desc_text = pf_purchdetl.desc_text 
							INSERT INTO t_poaudit VALUES (pr_poaudit.*) 
						ELSE 
							DELETE FROM t_purchdetl 
							WHERE line_num = pa_purchdetl[i].line_num 
							CALL serial_line_init(pa_purchdetl[i].ref_text, 
							pr_purchhead.ware_code) 
						END IF 
					ELSE 
						DELETE FROM t_purchdetl 
						WHERE line_num = pa_purchdetl[i].line_num 
						CALL serial_line_init(pa_purchdetl[i].ref_text, 
						pr_purchhead.ware_code) 
					END IF 
				END FOR 
				IF pr_warn_cnt > 0 THEN 
					LET msgresp=kandoomsg("R",9011,"") 
					#9011 Some lines may NOT be receipted
				END IF 
				IF received_total < order_total THEN 
					LET pr_msg_flag = true 
				END IF 
				CALL ring_menu(pr_jmresource.allocation_ind) 
				RETURNING pr_status_ind 
				CASE pr_status_ind 
					WHEN "2" 
						NEXT FIELD scroll_flag 
					OTHERWISE 
				END CASE 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET pr_status_ind = "4" 
	END IF 
	RETURN pr_status_ind 
END FUNCTION 


FUNCTION prod_lineitem(pr_mode) 
	DEFINE 
	pr_mode CHAR(1), 
	pr_jmresource RECORD LIKE jmresource.*, 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	pf_poaudit RECORD LIKE poaudit.*, 
	ps_purchdetl RECORD LIKE purchdetl.*, 
	ps_poaudit RECORD LIKE poaudit.*, 
	pa_purchdetl ARRAY [2000] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE purchdetl.line_num, 
		type_ind LIKE purchdetl.type_ind, 
		ref_text LIKE purchdetl.ref_text, 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		serial_flag LIKE product.serial_flag, 
		uom_code LIKE purchdetl.uom_code, 
		unit_cost_amt LIKE poaudit.unit_cost_amt 
	END RECORD, 
	pr_set_zero, arr_size,scrn,i, j,idx,pr_curr,pr_cnt SMALLINT, 
	pa_purchqty ARRAY [2000] OF RECORD 
		order_qty LIKE poaudit.order_qty, 
		received_qty LIKE poaudit.received_qty, 
		voucher_qty LIKE poaudit.voucher_qty 
	END RECORD, 
	pr_ref_text LIKE purchdetl.ref_text, 
	pr_res_code LIKE jmresource.res_code, 
	pr_received_qty LIKE poaudit.received_qty, 
	pr_part_code LIKE product.part_code, 
	pr_rem_qty, pr_rec_qty, pr_new_received_qty LIKE poaudit.received_qty, 
	vouch_amt,tax_amt,order_total,received_total LIKE poaudit.line_total_amt, 
	pr_serial_flag LIKE product.serial_flag, 
	pr_found CHAR(1), 
	pr_serial_err CHAR(1), 
	pr_scroll_flag,pr_status_ind CHAR(1), 
	where_text CHAR(200), 
	winds_text CHAR(50), 
	pr_ser_cnt SMALLINT, 
	pr_ser_cnt2 SMALLINT, 
	pr_type_ind LIKE purchdetl.type_ind 

	INITIALIZE pr_purchdetl.* TO NULL 
	LET where_text = "part_code in (SELECT ref_text FROM purchdetl ", 
	" WHERE cmpy_code = ", "\"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND order_num = ",pr_purchhead.order_num," )" 
	DECLARE c2_purchdetl CURSOR FOR 
	SELECT * FROM t_purchdetl 
	WHERE order_num = pr_purchhead.order_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY line_num 
	LET idx = 0 
	FOREACH c2_purchdetl INTO pr_purchdetl.* 
		LET idx = idx + 1 
		SELECT * INTO pr_poaudit.* FROM t_poaudit 
		WHERE line_num = pr_purchdetl.line_num 
		LET pa_purchdetl[idx].scroll_flag = NULL 
		LET pa_purchdetl[idx].line_num = pr_purchdetl.line_num 
		LET pa_purchdetl[idx].type_ind = pr_purchdetl.type_ind 
		LET pa_purchdetl[idx].ref_text = pr_purchdetl.ref_text 
		IF pr_purchdetl.type_ind = "J" THEN 
			LET pa_purchdetl[idx].ref_text = pr_purchdetl.res_code 
		END IF 
		LET pa_purchdetl[idx].uom_code = pr_purchdetl.uom_code 
		LET pa_purchdetl[idx].unit_cost_amt = pr_poaudit.unit_cost_amt 
		LET pa_purchdetl[idx].order_qty = pr_poaudit.order_qty 
		LET pa_purchdetl[idx].received_qty = pr_poaudit.received_qty 
		LET pa_purchdetl[idx].serial_flag = "N" 
		IF pr_purchdetl.type_ind matches "IC" THEN 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_purchdetl.ref_text 
			AND serial_flag = "Y" 
			IF status != notfound THEN 
				LET pa_purchdetl[idx].serial_flag = "Y" 
			END IF 
		END IF 
		IF idx = 2000 THEN 
			LET msgresp=kandoomsg("R",9001,idx) 
			#R9001 " First idx rows selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL po_head_info(glob_rec_kandoouser.cmpy_code,pr_purchhead.order_num) 
	RETURNING order_total, 
	received_total, 
	vouch_amt, 
	tax_amt 
	DISPLAY BY NAME order_total, 
	received_total 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("R",1026,"") 
	#1026 F1 Add; F2 Delete; F5 Product Inq; F7 Allocation ...
	LET pr_msg_flag = false 
	OPTIONS DELETE KEY f36, 
	INSERT KEY f1 
	INPUT ARRAY pa_purchdetl WITHOUT DEFAULTS FROM sr_purchdetl.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","R21b","inp-arr-purchdetl-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (F1,F9) 
			--- modif ericv init # ON KEY(F9)
			IF infield(scroll_flag) 
			AND pf_purchdetl.line_num IS NOT NULL THEN 
				CALL ord_window(glob_rec_kandoouser.cmpy_code, pf_purchdetl.line_num, 
				pr_purchhead.order_num, 
				pa_purchdetl[idx].received_qty) 
				NEXT FIELD scroll_flag 
			END IF 
		ON KEY (control-b) 
			CASE 
				WHEN infield(ref_text) 
					IF pf_purchdetl.type_ind = "I" 
					OR pf_purchdetl.type_ind = "C" THEN 
						LET winds_text = show_part(glob_rec_kandoouser.cmpy_code,where_text) 
						IF winds_text IS NOT NULL THEN 
							LET pa_purchdetl[idx].ref_text = winds_text 
						END IF 
						OPTIONS DELETE KEY f36, 
						INSERT KEY f1 
						NEXT FIELD ref_text 
					END IF 
			END CASE 
		ON KEY (F5) 
			IF pf_purchdetl.type_ind != "I" 
			AND pf_purchdetl.type_ind != "C" THEN 

				LET msgresp = kandoomsg("R",9522,"") 
				#9522 This FUNCTION IS NOT applicable TO this line type.
			ELSE 
				IF pa_purchdetl[idx].ref_text IS NOT NULL THEN 
					CALL pinvwind(glob_rec_kandoouser.cmpy_code,pa_purchdetl[idx].ref_text) 
				END IF 
			END IF 
		ON KEY (F7) 
			IF pf_purchdetl.type_ind != "J" THEN 
				LET msgresp = kandoomsg("R",9522,"") 
				#9522 This FUNCTION IS NOT applicable TO this line type.
			ELSE 
				SELECT type_ind, res_code INTO pr_type_ind, pr_res_code 
				FROM purchdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_purchhead.order_num 
				AND line_num = pa_purchdetl[idx].line_num 
				IF pr_type_ind = "J" 
				AND pr_res_code IS NOT NULL THEN 

					SELECT * INTO pr_jmresource.* FROM jmresource 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND res_code = pr_res_code 

					IF pr_jmresource.allocation_flag <> "1" OR 
					pr_jmresource.allocation_flag IS NULL THEN 
						LET msgresp = kandoomsg("J",9555,"") 
						#9555 Resource does NOT permit user TO overide the Alloc...
					ELSE 
						CALL adjust_allocflag(glob_rec_kandoouser.cmpy_code, 
						pr_jmresource.res_code, 
						pr_jmresource.allocation_ind) 
						RETURNING pr_jmresource.allocation_ind 
						#DISPLAY pa_purchdetl[idx].allocation_ind TO
						#sr_purchdetl[scrn].allocation_ind
					END IF 
				END IF 
			END IF 
		ON KEY (F8) 
			CALL run_prog("I18","","","","") 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_ref_text = pa_purchdetl[idx].ref_text 
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF fgl_lastkey() = fgl_keyval("prevpage") 
			AND pa_purchdetl[idx].scroll_flag = "*" THEN 
				LET msgresp = kandoomsg("R",9010,"") 
				#9010 Received qty > outstanding qty.
			END IF 
			INITIALIZE pf_purchdetl.* TO NULL 
			LET pr_scroll_flag = pa_purchdetl[idx].scroll_flag 
			LET pr_ref_text = pa_purchdetl[idx].ref_text 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

			SELECT * INTO pf_purchdetl.* FROM purchdetl 
			WHERE line_num = pa_purchdetl[idx].line_num 
			AND order_num = pr_purchhead.order_num 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_purchdetl.* = pf_purchdetl.* 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			INITIALIZE pr_product.* TO NULL 
			IF pf_purchdetl.type_ind = "I" 
			OR pf_purchdetl.type_ind = "C" THEN 
				SELECT * INTO pr_product.* FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pf_purchdetl.ref_text 
			END IF 
			DISPLAY BY NAME pf_purchdetl.desc_text, 
			pr_product.oem_text, 
			pr_product.bar_code_text, 
			pf_purchdetl.type_ind, 
			received_total 

			IF ( (fgl_lastkey()=fgl_keyval("RETURN") 
			OR fgl_lastkey()=fgl_keyval("tab") 
			OR fgl_lastkey()=fgl_keyval("right") 
			OR fgl_lastkey()=fgl_keyval("down"))) 
			AND pr_ref_text IS NULL THEN 
				NEXT FIELD line_num 
			END IF 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND pa_purchdetl[idx+11].ref_text IS NULL THEN 
				IF pa_purchdetl[idx].scroll_flag = "*" THEN 
					LET msgresp = kandoomsg("R",9010,"") 
					#9010 Received qty > outstanding qty.
				ELSE 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
				END IF 
				NEXT FIELD scroll_flag 
			END IF 
			LET pa_purchdetl[idx].scroll_flag = pr_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_purchdetl[idx].ref_text IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		ON KEY (F2) 
			CALL serial_line_init(pa_purchdetl[idx].ref_text, 
			pr_purchhead.ware_code) 
			IF pa_purchdetl[idx].received_qty IS NULL THEN 
				LET pa_purchdetl[idx].received_qty = 0 
			END IF 
			LET received_total = received_total 
			- (pa_purchdetl[idx].received_qty 
			* (pr_poaudit.unit_cost_amt 
			+ pr_poaudit.unit_tax_amt)) 
			LET pr_curr = arr_curr() 
			LET pr_cnt = arr_count() 
			FOR i = pr_curr TO pr_cnt 
				LET pa_purchdetl[i].* = pa_purchdetl[i+1].* 
				IF scrn <= 11 THEN 
					IF pa_purchdetl[i].line_num IS NULL 
					OR pa_purchdetl[i].line_num = 0 THEN 
						LET pa_purchdetl[i].line_num = NULL 
						LET pa_purchdetl[i].ref_text = NULL 
						LET pa_purchdetl[i].uom_code = NULL 
						LET pa_purchdetl[i].order_qty = NULL 
						LET pa_purchdetl[i].received_qty = NULL 
						LET pa_purchdetl[i].unit_cost_amt = NULL 
					END IF 
					DISPLAY pa_purchdetl[i].* TO sr_purchdetl[scrn].* 

					LET scrn = scrn + 1 
				END IF 
			END FOR 
			INITIALIZE pa_purchdetl[i].* TO NULL 
			NEXT FIELD scroll_flag 
		BEFORE FIELD line_num 
			IF pf_purchdetl.line_num IS NULL THEN 
				INITIALIZE ps_purchdetl.* TO NULL 
				INITIALIZE ps_poaudit.* TO NULL 
			ELSE 
				LET ps_purchdetl.* = pf_purchdetl.* 
				LET ps_poaudit.received_qty = pa_purchdetl[idx].received_qty 
			END IF 
			NEXT FIELD ref_text 
		BEFORE FIELD ref_text 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

			IF pr_ref_text IS NOT NULL THEN 
				NEXT FIELD received_qty 
			END IF 
			LET pf_purchdetl.line_num = NULL 
			#The following DISPLAY IS intentianal so that before the user enters
			# the new part code they can see the previous details FOR confimation
			LET pf_purchdetl.desc_text = pr_product.desc_text 
			LET pf_purchdetl.type_ind = "I" 
			DISPLAY BY NAME pf_purchdetl.desc_text, 
			pr_product.oem_text, 
			pr_product.bar_code_text, 
			pf_purchdetl.type_ind, 
			received_total 

			INITIALIZE pr_product.* TO NULL 

		AFTER FIELD ref_text 
			IF pa_purchdetl[idx].ref_text IS NULL THEN 
				LET msgresp = kandoomsg("U", 9102, "") 
				#9102 Value must be entered
				NEXT FIELD ref_text 
			END IF 
			LET pr_part_code = get_product(pa_purchdetl[idx].ref_text) 
			IF pr_part_code IS NULL THEN 
				LET msgresp = kandoomsg("U",9910,"") 
				#9910 RECORD NOT found
				NEXT FIELD ref_text 
			END IF 
			DECLARE c3_purchdetl CURSOR FOR 
			SELECT * FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			AND ref_text = pr_part_code 
			ORDER BY line_num 
			OPEN c3_purchdetl 
			FETCH c3_purchdetl INTO pf_purchdetl.* 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("U",9910,"") 
				#9910 RECORD NOT found
				CLOSE c3_purchdetl 
				NEXT FIELD ref_text 
			ELSE 
				CLOSE c3_purchdetl 
				LET pr_rec_qty = 0 
				LET pr_rem_qty = 0 
				SELECT serial_flag INTO pr_serial_flag FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_purchdetl[idx].ref_text 
				LET pr_found = 'N' 
				FOR i = 1 TO arr_count() 
					IF pr_part_code = pa_purchdetl[i].ref_text 
					AND i != idx THEN 
						LET pr_rec_qty = pr_rec_qty + pa_purchdetl[i].received_qty 
						LET pr_found = 'Y' 
					END IF 
				END FOR 
				IF pr_serial_flag = 'Y' THEN 
					IF pr_found = 'Y' THEN 
						LET msgresp = kandoomsg("I",9292,"") 
						#9292 Serial Products can only occur once.
						NEXT FIELD ref_text 
					ELSE 
						LET pr_rec_qty = pa_purchdetl[idx].received_qty 
						IF pr_rec_qty IS NULL THEN 
							LET pr_rec_qty = 0 
						END IF 
					END IF 
				ELSE 
					FOREACH c3_purchdetl INTO pf_purchdetl.* 
						CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
						pf_purchdetl.order_num, 
						pf_purchdetl.line_num) 
						RETURNING pf_poaudit.order_qty, 
						pf_poaudit.received_qty, 
						pf_poaudit.voucher_qty, 
						pf_poaudit.unit_cost_amt, 
						pf_poaudit.ext_cost_amt, 
						pf_poaudit.unit_tax_amt, 
						pf_poaudit.ext_tax_amt, 
						pf_poaudit.line_total_amt 
						LET pr_rem_qty = pf_poaudit.order_qty 
						- pf_poaudit.received_qty 
						IF pr_rec_qty >= pr_rem_qty THEN 
							LET pr_rec_qty = pr_rec_qty - pr_rem_qty 
							LET pr_set_zero = true 
							CONTINUE FOREACH 
						ELSE 
							LET pr_rec_qty = pr_rem_qty - pr_rec_qty 
							LET pr_set_zero = false 
							EXIT FOREACH 
						END IF 
					END FOREACH 
					IF pr_set_zero = true THEN 
						IF get_kandoooption_feature_state("PU","GR") = "N" THEN 
							LET msgresp = kandoomsg("U",9104,"") 
							#9104 RECORD Already Exists
							NEXT FIELD ref_text 
						ELSE 
							LET pr_rec_qty = 0 
						END IF 
					END IF 
					IF pr_rec_qty IS NULL 
					OR pr_rec_qty < 0 THEN 
						LET pr_rec_qty = 0 
					END IF 
				END IF 
				# Cannot receipt shipment lines
				SELECT unique 1 
				FROM shipdetl, shiphead 
				WHERE shipdetl.source_doc_num = pf_purchdetl.order_num 
				AND shipdetl.doc_line_num = pf_purchdetl.line_num 
				AND shipdetl.ship_inv_qty > 0 
				AND shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shipdetl.cmpy_code = shiphead.cmpy_code 
				AND shipdetl.ship_code = shiphead.ship_code 
				AND shiphead.finalised_flag <> "Y" 
				IF status <> notfound THEN 
					LET msgresp = kandoomsg("R",9015,"") 
					#9015 Cannot enter shipment line receipt thorugh Purchasing
					NEXT FIELD ref_text 
				END IF 
				LET pa_purchdetl[idx].ref_text = pf_purchdetl.ref_text 
				LET pa_purchdetl[idx].line_num = pf_purchdetl.line_num 
				LET pa_purchdetl[idx].uom_code = pf_purchdetl.uom_code 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				pf_purchdetl.order_num, 
				pf_purchdetl.line_num) 
				RETURNING pf_poaudit.order_qty, 
				pf_poaudit.received_qty, 
				pf_poaudit.voucher_qty, 
				pf_poaudit.unit_cost_amt, 
				pf_poaudit.ext_cost_amt, 
				pf_poaudit.unit_tax_amt, 
				pf_poaudit.ext_tax_amt, 
				pf_poaudit.line_total_amt 
				LET pa_purchdetl[idx].unit_cost_amt = pf_poaudit.unit_cost_amt 
				LET pa_purchdetl[idx].order_qty = pf_poaudit.order_qty 
				LET pa_purchdetl[idx].received_qty = pr_rec_qty 
				LET pa_purchqty[idx].order_qty = pf_poaudit.order_qty 
				LET pa_purchqty[idx].received_qty = pr_rec_qty 
				LET pa_purchqty[idx].voucher_qty = pf_poaudit.voucher_qty 
				LET pf_poaudit.received_qty = pr_rec_qty 
				LET pr_purchdetl.* = pf_purchdetl.* 
				LET pr_poaudit.* = pf_poaudit.* 
				LET received_total = received_total 
				+ (pa_purchdetl[idx].received_qty 
				* (pf_poaudit.unit_cost_amt 
				+ pf_poaudit.unit_tax_amt)) 
				DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

				INITIALIZE pr_product.* TO NULL 
				IF pf_purchdetl.type_ind = "I" 
				OR pf_purchdetl.type_ind = "C" THEN 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pf_purchdetl.ref_text 
				END IF 
				DISPLAY BY NAME pf_purchdetl.desc_text, 
				pr_product.oem_text, 
				pr_product.bar_code_text, 
				pf_purchdetl.type_ind, 
				received_total 

				CASE 
					WHEN fgl_lastkey()=fgl_keyval("RETURN") 
						OR fgl_lastkey()=fgl_keyval("tab") 
						OR fgl_lastkey()=fgl_keyval("right") 
						OR fgl_lastkey()=fgl_keyval("accept") 
						OR fgl_lastkey()=fgl_keyval("down") 
						NEXT FIELD received_qty 
					WHEN fgl_lastkey()=fgl_keyval("left") 
						OR fgl_lastkey()=fgl_keyval("up") 
						NEXT FIELD ref_text 
					OTHERWISE 
						NEXT FIELD ref_text 
				END CASE 
			END IF 

		BEFORE FIELD order_qty 
			NEXT FIELD received_qty 

		BEFORE FIELD received_qty 
			LET pr_received_qty = pa_purchdetl[idx].received_qty 
			SELECT serial_flag INTO pr_serial_flag FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_purchdetl[idx].ref_text 
			IF pr_ref_text IS NULL 
			AND pr_serial_flag = 'N' THEN 
				NEXT FIELD NEXT 
			END IF 
			IF pr_serial_flag = 'Y' THEN 
				LET pr_ser_cnt = serial_count(pr_product.part_code, 
				pr_purchhead.ware_code) 
				LET pr_ser_cnt2 = serial_input(pr_product.part_code, 
				pr_purchhead.ware_code, 
				pr_ser_cnt) 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
				IF pr_ser_cnt2 < 0 THEN 
					IF pr_ser_cnt2 = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("R21b-2 Fatal error in serial_input ") 
						EXIT program 
					END IF 
				ELSE 
					LET pa_purchdetl[idx].received_qty 
					= pa_purchdetl[idx].received_qty + pr_ser_cnt2 
					- pr_ser_cnt 
				END IF 
				IF pr_received_qty != pa_purchdetl[idx].received_qty THEN 
					LET received_total = received_total 
					+ ((pa_purchdetl[idx].received_qty - pr_received_qty) 
					* (pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt)) 
					DISPLAY BY NAME received_total 

				END IF 
				LET pr_received_qty = pa_purchdetl[idx].received_qty 
			END IF 

		AFTER FIELD received_qty 

			## Received qty cannot be less than zero OR less
			## than the total vouchered TO date.
			LET pr_serial_err = 'N' 
			IF pr_serial_flag = 'Y' 
			AND pa_purchdetl[idx].received_qty <> pr_received_qty THEN 
				LET pr_serial_err = 'Y' 
				LET pa_purchdetl[idx].received_qty = pr_received_qty 
			END IF 
			IF pa_purchdetl[idx].received_qty IS NULL THEN 
				LET pa_purchdetl[idx].received_qty = 0 
			END IF 
			IF pa_purchdetl[idx].received_qty < 0 THEN 
				LET msgresp = kandoomsg("U",9907,"0") 
				#9907 Value must be greater than OR equal TO 0
				NEXT FIELD received_qty 
			END IF 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pr_purchdetl.order_num, 
			pr_purchdetl.line_num) 
			RETURNING pr_poaudit.order_qty, 
			pr_poaudit.received_qty, 
			pr_poaudit.voucher_qty, 
			pr_poaudit.unit_cost_amt, 
			pr_poaudit.ext_cost_amt, 
			pr_poaudit.unit_tax_amt, 
			pr_poaudit.ext_tax_amt, 
			pr_poaudit.line_total_amt 
			LET pr_rec_qty = 0 
			FOR i = 1 TO arr_count() 
				IF pa_purchdetl[idx].ref_text = pa_purchdetl[i].ref_text 
				AND pa_purchdetl[idx].line_num = pa_purchdetl[i].line_num 
				AND i != idx THEN 
					LET pr_rec_qty = pr_rec_qty + pa_purchdetl[i].received_qty 
				END IF 
			END FOR 
			LET pr_new_received_qty = pr_poaudit.received_qty 
			+ pa_purchdetl[idx].received_qty 
			+ pr_rec_qty 
			IF pr_new_received_qty > pa_purchdetl[idx].order_qty THEN 
				IF get_kandoooption_feature_state("PU","GR") = "Y" THEN 
					LET msgresp = kandoomsg("R",9010,"") 
					#9010 Received qty > outstanding qty.
					LET pa_purchdetl[idx].scroll_flag = "*" 
				ELSE 
					LET msgresp = kandoomsg("R",9515,"") 
					#9515 Received qty cannot be greater than ORDER qty.
					LET pa_purchdetl[idx].scroll_flag = NULL 
					NEXT FIELD received_qty 
				END IF 
			ELSE 
				LET pa_purchdetl[idx].scroll_flag = NULL 
			END IF 
			IF pr_new_received_qty < 0 THEN 
				LET msgresp = kandoomsg("R", 9512, "") 
				#9512 This entry will reduce total received TO less than zero
				NEXT FIELD received_qty 
			END IF 
			IF pr_new_received_qty < pr_poaudit.voucher_qty THEN 
				LET msgresp = kandoomsg("R", 9513, "") 
				#9513 This entry will reduce total received TO less than invoiced
				NEXT FIELD received_qty 
			END IF 
			IF pr_serial_err = 'Y' 
			AND pa_purchdetl[idx].scroll_flag <> "*" THEN 
				LET msgresp = kandoomsg("I",9301,"") 
				#9301 Use Serial Code window TO alter Receipt Quantity.
				NEXT FIELD scroll_flag 
			END IF 
			LET pr_poaudit.received_qty = pa_purchdetl[idx].received_qty 
			IF pr_received_qty != pa_purchdetl[idx].received_qty THEN 
				LET received_total = received_total 
				- (pr_received_qty 
				* (pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt)) 
				LET received_total = received_total 
				+ (pa_purchdetl[idx].received_qty 
				* (pr_poaudit.unit_cost_amt 
				+ pr_poaudit.unit_tax_amt)) 
			END IF 
			LET pf_purchdetl.* = pr_purchdetl.* 
			LET pf_poaudit.* = pr_poaudit.* 
			CASE 
				WHEN fgl_lastkey()=fgl_keyval("right") 
					OR fgl_lastkey()=fgl_keyval("down") 
					OR fgl_lastkey()=fgl_keyval("accept") 
					OR fgl_lastkey()=fgl_keyval("RETURN") 
					OR fgl_lastkey()=fgl_keyval("tab") 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey()=fgl_keyval("left") 
					OR fgl_lastkey()=fgl_keyval("up") 
					NEXT FIELD received_qty 
			END CASE 

		BEFORE INSERT 
			INITIALIZE pa_purchdetl[idx].* TO NULL 
			INITIALIZE pf_purchdetl.* TO NULL 
			INITIALIZE pf_poaudit.* TO NULL 
			INITIALIZE pr_ref_text TO NULL 
			### Informix bug - ON LAST ROW, IF del IS pressed, BEFORE INSERT
			### IS re-executed
			IF fgl_lastkey() = fgl_keyval("delete") 
			OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
				INITIALIZE pa_purchdetl[idx].* TO NULL 
				NEXT FIELD scroll_flag 
			ELSE 
				NEXT FIELD line_num 
			END IF 
		AFTER ROW 
			DISPLAY pa_purchdetl[idx].* TO sr_purchdetl[scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				IF (infield(scroll_flag)) THEN 
					IF pa_purchdetl[1].ref_text IS NOT NULL THEN 
						LET msgresp = kandoomsg("R",8008,"") 
						#8008 Changes made will be removed
						IF msgresp = "N" THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num) 
						END IF 
					END IF 
				ELSE 
					IF ps_purchdetl.line_num IS NULL THEN 
						LET j = scrn 
						FOR i = arr_curr() TO arr_count() 
							IF pa_purchdetl[i+1].line_num IS NOT NULL THEN 
								LET pa_purchdetl[i].* = pa_purchdetl[i+1].* 
							ELSE 
								INITIALIZE pa_purchdetl[i].* TO NULL 
							END IF 
							IF j <= 11 THEN 
								IF pa_purchdetl[i].line_num = 0 THEN 
									INITIALIZE pa_purchdetl[i].* TO NULL 
								END IF 
								DISPLAY pa_purchdetl[i].* TO sr_purchdetl[j].* 

								LET j = j + 1 
							END IF 
						END FOR 
					ELSE 
						LET pr_purchdetl.* = ps_purchdetl.* 
						LET pr_poaudit.* = ps_poaudit.* 
						LET pa_purchdetl[idx].line_num = ps_purchdetl.line_num 
						LET pa_purchdetl[idx].ref_text = ps_purchdetl.ref_text 
						LET pa_purchdetl[idx].uom_code = ps_purchdetl.uom_code 
						LET pa_purchdetl[idx].received_qty = ps_poaudit.received_qty 
					END IF 
					NEXT FIELD scroll_flag 
				END IF 
			ELSE 
				IF pa_purchdetl[1].ref_text IS NULL THEN 
					LET msgresp = kandoomsg("R", 9012, "") 
					#9012 One item must exist TO create a receipt
					NEXT FIELD scroll_flag 
				END IF 
				FOR i = 1 TO arr_count() 
					IF pa_purchdetl[i].line_num IS NULL THEN 
						CONTINUE FOR 
					END IF 
					SELECT * INTO pr_purchdetl.* FROM purchdetl 
					WHERE line_num = pa_purchdetl[i].line_num 
					AND order_num = pr_purchhead.order_num 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
					pr_purchdetl.order_num, 
					pr_purchdetl.line_num) 
					RETURNING pr_poaudit.order_qty, 
					pr_poaudit.received_qty, 
					pr_poaudit.voucher_qty, 
					pr_poaudit.unit_cost_amt, 
					pr_poaudit.ext_cost_amt, 
					pr_poaudit.unit_tax_amt, 
					pr_poaudit.ext_tax_amt, 
					pr_poaudit.line_total_amt 
					LET pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_poaudit.po_num = pr_purchdetl.order_num 
					LET pr_poaudit.line_num = pa_purchdetl[i].line_num 
					LET pr_poaudit.tran_date = save_date 
					LET pr_poaudit.received_qty = pa_purchdetl[i].received_qty 
					LET pr_poaudit.order_qty = pa_purchdetl[i].order_qty 
					LET pr_poaudit.desc_text = pr_purchdetl.desc_text 
					CALL t_purchdetl_update_line() 
				END FOR 
				IF received_total < order_total THEN 
					LET pr_msg_flag = true 
				END IF 
				CALL ring_menu(pr_jmresource.allocation_ind) 
				RETURNING pr_status_ind 
				CASE pr_status_ind 
					WHEN "2" 
						DELETE FROM t_purchdetl 
						WHERE 1=1 
						DELETE FROM t_poaudit 
						WHERE 1=1 
						#                  CALL serial_init(glob_rec_kandoouser.cmpy_code, 'P', '', pr_purchhead.order_num)
						NEXT FIELD scroll_flag 
				END CASE 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET pr_status_ind = "4" 
	END IF 
	RETURN pr_status_ind 
END FUNCTION 


FUNCTION t_purchdetl_update_line() 
	DEFINE 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	pf_poaudit RECORD LIKE poaudit.* 

	LET pf_purchdetl.* = pr_purchdetl.* 
	LET pf_poaudit.* = pr_poaudit.* 
	UPDATE t_purchdetl 
	SET vend_code = pf_purchdetl.vend_code, 
	seq_num = pf_purchdetl.seq_num, 
	type_ind = pf_purchdetl.type_ind, 
	ref_text = pf_purchdetl.ref_text, 
	oem_text = pf_purchdetl.oem_text, 
	res_code = pf_purchdetl.res_code, 
	job_code = pf_purchdetl.job_code, 
	var_num = pf_purchdetl.var_num, 
	activity_code = pf_purchdetl.activity_code, 
	desc_text = pf_purchdetl.desc_text, 
	uom_code = pf_purchdetl.uom_code, 
	acct_code = pf_purchdetl.acct_code, 
	req_num = pf_purchdetl.req_num, 
	req_line_num = pf_purchdetl.req_line_num 
	WHERE line_num = pf_purchdetl.line_num 
	IF sqlca.sqlerrd[3] = 0 THEN 
		INSERT INTO t_purchdetl VALUES (pf_purchdetl.*) 
	END IF 
	UPDATE t_poaudit 
	SET seq_num = pf_poaudit.seq_num, 
	vend_code = pf_poaudit.vend_code, 
	tran_code = pf_poaudit.tran_code, 
	tran_num = pf_poaudit.tran_num, 
	entry_date = pf_poaudit.entry_date, 
	entry_code = pf_poaudit.entry_code, 
	orig_auth_flag = pf_poaudit.orig_auth_flag, 
	now_auth_flag = pf_poaudit.now_auth_flag, 
	order_qty = pf_poaudit.order_qty, 
	received_qty = received_qty + pf_poaudit.received_qty, 
	voucher_qty = pf_poaudit.voucher_qty, 
	desc_text = pf_poaudit.desc_text, 
	unit_cost_amt = pf_poaudit.unit_cost_amt, 
	ext_cost_amt = pf_poaudit.ext_cost_amt, 
	unit_tax_amt = pf_poaudit.unit_tax_amt, 
	ext_tax_amt = pf_poaudit.ext_tax_amt, 
	line_total_amt = pf_poaudit.line_total_amt, 
	posted_flag = pf_poaudit.posted_flag, 
	jour_num = pf_poaudit.jour_num 
	WHERE line_num = pf_purchdetl.line_num 
	IF sqlca.sqlerrd[3] = 0 THEN 
		LET pf_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pf_poaudit.po_num = pr_purchhead.order_num 
		LET pf_poaudit.line_num = pf_purchdetl.line_num 
		LET pf_poaudit.tran_date = save_date 
		LET pf_poaudit.year_num = save_year 
		LET pf_poaudit.period_num = save_period 
		INSERT INTO t_poaudit VALUES (pf_poaudit.*) 
	END IF 
END FUNCTION 


FUNCTION ring_menu(pr_allocation_ind) 
	DEFINE pr_status_ind CHAR(1)
	DEFINE l_kandoo_log_msg CHAR(200) 
	DEFINE pr_err_cnt SMALLINT 
	DEFINE pr_allocation_ind LIKE jmresource.allocation_ind 

	--   OPEN WINDOW word AT 13,13 with 4 rows, 53 columns  -- albo  KD-756
	--      ATTRIBUTE(border,white,menu line 3)

	LET msgresp = kandoomsg("R",1015,"") 
	#1015  Use the menu OPTIONS...

	MENU " Receipt Order" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","R19","menu-receipt_order-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "Save" " Save Receipt Details" 
			LET pr_status_ind = "1" 
			EXIT MENU 
		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Line Details" 
			LET int_flag = false 
			LET quit_flag = false 
			LET pr_status_ind = "2" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	IF pr_status_ind = "1" THEN 
		CALL write_receipt() 
		RETURNING pr_err_cnt 
		IF pr_err_cnt = 0 THEN 
			LET msgresp = kandoomsg("R",7015,pr_puparms.next_receipt_num) 
			#7015 Successful generation of receipt
		ELSE 
			LET l_kandoo_log_msg = pr_puparms.next_receipt_num USING "<<<<<<<<", 
			" ",pr_err_cnt USING "<<<<", 
			" errors encountered. Refer to ", trim(get_settings_logFile()) 
			LET msgresp = kandoomsg("R",7016,l_kandoo_log_msg) 
			#7015 Successful generation of receipt
		END IF 
		IF pr_vendor.backorder_flag = "N" 
		AND pr_msg_flag 
		AND pr_status_ind = "1" 
		AND pr_err_cnt = 0 THEN 
			LET msgresp = kandoomsg("R",8007,"") 
			#8007 Confirm TO close purchase ORDER
			IF msgresp = "Y" THEN 
				IF close_order() THEN 
				END IF 
			END IF 
			LET pr_status_ind = "1" 
		END IF 
	END IF 
	--   CLOSE WINDOW word  -- albo  KD-756
	RETURN pr_status_ind 
END FUNCTION 


FUNCTION get_product(pr_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_product RECORD LIKE product.*, 
	pr_length SMALLINT 

	INITIALIZE pr_product.* TO NULL 
	IF pr_part_code[1,1] = "#" THEN 
		LET pr_length = length(pr_part_code) 
		LET pr_part_code = pr_part_code[2,pr_length] 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bar_code_text = pr_part_code 
		IF status = notfound THEN 
			LET pr_product.part_code = NULL 
		END IF 
	ELSE 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_part_code 
		IF status = notfound THEN 
			DECLARE c_oem CURSOR FOR 
			SELECT * INTO pr_product.* FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND oem_text = pr_part_code 
			OPEN c_oem 
			FETCH c_oem 
			IF status = notfound THEN 
				LET pr_product.part_code = NULL 
			END IF 
			CLOSE c_oem 
		END IF 
	END IF 
	RETURN pr_product.part_code 
END FUNCTION 


FUNCTION close_order() 
	DEFINE 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	cu_poaudit RECORD LIKE poaudit.*, 
	pr_old_onorder_amt LIKE vendor.onorder_amt, 
	pr_new_onorder_amt LIKE vendor.onorder_amt, 
	err_continue CHAR(1), 
	err_message CHAR(40), 
	pr_err_stat INTEGER 

	GOTO bypass1 
	LABEL recovery1: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 
	BEGIN WORK 
		LET msgresp = kandoomsg("U",1005,"") 
		#1005 Updating database...
		DECLARE c1_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_purchhead.vend_code 
		FOR UPDATE 
		DECLARE c6_purchdetl CURSOR FOR 
		SELECT * FROM purchdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_purchhead.order_num 
		ORDER BY line_num 
		OPEN c1_vendor 
		FETCH c1_vendor INTO pr_vendor.* 
		LET pr_new_onorder_amt = 0 
		LET pr_old_onorder_amt = 0 
		FOREACH c6_purchdetl INTO pf_purchdetl.* 
			LET err_message = "R21b - receipt line addition failed" 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pf_purchdetl.order_num, 
			pf_purchdetl.line_num) 
			RETURNING cu_poaudit.order_qty, 
			cu_poaudit.received_qty, 
			cu_poaudit.voucher_qty, 
			cu_poaudit.unit_cost_amt, 
			cu_poaudit.ext_cost_amt, 
			cu_poaudit.unit_tax_amt, 
			cu_poaudit.ext_tax_amt, 
			cu_poaudit.line_total_amt 
			LET pr_old_onorder_amt = pr_old_onorder_amt 
			+ ((cu_poaudit.order_qty - cu_poaudit.received_qty) 
			* (cu_poaudit.unit_cost_amt + cu_poaudit.unit_tax_amt)) 
			IF cu_poaudit.received_qty < cu_poaudit.order_qty THEN 
				LET cu_poaudit.tran_date = save_date 
				LET cu_poaudit.year_num = save_year 
				LET cu_poaudit.period_num = save_period 
				LET cu_poaudit.order_qty = cu_poaudit.received_qty 
				CALL mod_po_line(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, pr_purchhead.*, 
				pf_purchdetl.*, 
				cu_poaudit.*) 
				RETURNING pr_err_stat 
				IF pr_err_stat < 0 THEN 
					GO TO recovery1 
				END IF 
			END IF 
			CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
			pf_purchdetl.order_num, 
			pf_purchdetl.line_num) 
			RETURNING cu_poaudit.order_qty, 
			cu_poaudit.received_qty, 
			cu_poaudit.voucher_qty, 
			cu_poaudit.unit_cost_amt, 
			cu_poaudit.ext_cost_amt, 
			cu_poaudit.unit_tax_amt, 
			cu_poaudit.ext_tax_amt, 
			cu_poaudit.line_total_amt 
			LET pr_new_onorder_amt = pr_new_onorder_amt 
			+ ((cu_poaudit.order_qty - cu_poaudit.received_qty) 
			* (cu_poaudit.unit_cost_amt + cu_poaudit.unit_tax_amt)) 
		END FOREACH 
		LET pr_new_onorder_amt = pr_new_onorder_amt - pr_old_onorder_amt 
		UPDATE vendor 
		SET onorder_amt = onorder_amt + pr_new_onorder_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_purchhead.vend_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true 
END FUNCTION 
