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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N1_GROUP_GLOBALS.4gl" 
GLOBALS "../re/N11_GLOBALS.4gl" 
########################################################################
# \file
# \brief module N11b - Internal Requisition Single Line Entry
########################################################################
# Functions in this module are:
# * lineitem_scan      - Single Line Item Entry
# * insert_line        - Insert New Default Requisition Line(t_reqdetl)
# * update_line        - Update Requisition Line (t_reqdetl)
# * disp_total         - DISPLAY the Line Item Totals
# * check_alternate    - Check IF Alternate Products exist
# * display_alternates - DISPLAY the Alternate Products
# * compan_avail       - Check TO see IF a Companion Product IS Available
# * show_compan        - Show the Companion Products
########################################################################


#
# Single Line Item Entry
#
FUNCTION lineitem_scan(pr_mode) 
	DEFINE 
	pm_reqdetl, 
	pr_reqdetl, 
	ps_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_mode CHAR(4), 
	pr_found_warn, 
	pr_exit_input, 
	upd_flag SMALLINT, 
	int_flag_check,idx,scrn,pr_valid_ind,i,j SMALLINT, 
	pr_lastkey INTEGER, 
	pr_part_code LIKE product.part_code, 
	pr_comp_prod SMALLINT, 
	pr_query_text CHAR(200), 
	pr_temp_text CHAR(50) 

	SELECT * INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_reqhead.ware_code 

	DISPLAY BY NAME pr_reqhead.del_dept_text, 
	pr_reqhead.ware_code 

	DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

	IF pr_mode != "ADD" THEN 
		INSERT INTO t_reqdetl 
		SELECT * FROM reqdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND req_num = pr_reqhead.req_num 
	END IF 
	LET pr_exit_input = false 
	WHILE true 
		LET msgresp=kandoomsg("U",1002,"") 
		LET idx = 0 
		DECLARE c_t_reqdetl CURSOR FOR 
		SELECT * FROM t_reqdetl 
		ORDER BY line_num 
		FOREACH c_t_reqdetl INTO pr_reqdetl.* 
			LET idx = idx + 1 
			IF pr_reqdetl.line_num != idx THEN 
				UPDATE t_reqdetl 
				SET line_num = idx, 
				req_num = pr_reqhead.req_num 
				WHERE line_num = pr_reqdetl.line_num 
			ELSE 
				UPDATE t_reqdetl 
				SET req_num = pr_reqhead.req_num 
				WHERE line_num = pr_reqdetl.line_num 
			END IF 
			LET pr_reqdetl.line_num = idx 
			LET pa_reqdetl[idx].line_num = idx 
			LET pa_reqdetl[idx].part_code = pr_reqdetl.part_code 
			LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
			LET pa_reqdetl[idx].uom_code = pr_reqdetl.uom_code 
			LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
			LET pa_reqdetl[idx].line_tot_amt = pr_reqdetl.unit_sales_amt 
			* pr_reqdetl.req_qty 
			### IF a recently file loaded requisition line     ###
			### has req_num < 0 THEN it IS a req line in error ###
			IF pr_reqdetl.req_num < 0 THEN 
				LET pa_reqdetl[idx].warn_flag = "*" 
			ELSE 
				CALL quantity_check(pr_reqdetl.*,0) 
				LET pa_reqdetl[idx].warn_flag = pr_save.warn_flag 
			END IF 
		END FOREACH 
		CLOSE c_t_reqdetl 
		LET pr_comp_prod = false 
		CALL set_count(idx) 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		LET msgresp=kandoomsg("N",1009,"") 
		#1009 F1 TO Add; F2...
		INPUT ARRAY pa_reqdetl WITHOUT DEFAULTS FROM sr_reqdetl.* 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "NOTES" --ON KEY (control-n) 
				IF pr_reqdetl.line_num IS NOT NULL THEN 
					OPTIONS DELETE KEY f2 
					LET pr_reqdetl.desc_text=sys_noter(glob_rec_kandoouser.cmpy_code,pr_reqdetl.desc_text) 
					OPTIONS DELETE KEY f36 
					CALL update_line(pr_reqdetl.*) 
					DISPLAY BY NAME pr_reqdetl.desc_text 

				END IF 
			ON KEY (control-b) 
				CASE 
					WHEN infield(part_code) 
						LET pr_query_text= "status_ind ='1' AND part_code in ", 
						"(SELECT part_code FROM prodstatus ", 
						"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND ware_code='",pr_reqhead.ware_code,"' ", 
						"AND part_code=product.part_code ", 
						"AND status_ind = '1' ) " 
						LET pr_temp_text = show_part(glob_rec_kandoouser.cmpy_code,pr_query_text) 
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
						IF pr_temp_text IS NOT NULL THEN 
							LET pa_reqdetl[idx].part_code = pr_temp_text 
							NEXT FIELD part_code 
						END IF 
				END CASE 
			ON KEY (F5) 
				IF pa_reqdetl[idx].part_code IS NOT NULL THEN 
					CALL pinvwind(glob_rec_kandoouser.cmpy_code,pa_reqdetl[idx].part_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
				END IF 
			ON KEY (F6) 
				IF infield(scroll_flag) THEN 
					IF pr_reqperson.loadfile_text IS NOT NULL THEN 
						IF load_req_file() THEN 
							EXIT INPUT 
						ELSE 
							OPTIONS INSERT KEY f1, 
							DELETE KEY f36 
							LET msgresp=kandoomsg("N",1009,"") 
							#N1009 F1 TO Add; F2...
							NEXT FIELD scroll_flag 
						END IF 
					ELSE 
						LET msgresp=kandoomsg("N",9044,pr_reqperson.person_code) 
						#N9044 There IS no load file specified...
					END IF 
				END IF 
			ON KEY (F10) 
				IF infield(part_code) THEN 
					IF pr_comp_prod THEN 
						SELECT y.part_code 
						INTO pa_reqdetl[idx].part_code 
						FROM product x, 
						product y, 
						prodstatus z 
						WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND x.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND x.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND x.part_code = pa_reqdetl[idx-1].part_code 
						AND y.part_code = x.compn_part_code 
						AND y.part_code = z.part_code 
						AND z.ware_code = pr_reqhead.ware_code 
						AND (z.onhand_qty - z.reserved_qty - z.back_qty) > 0 
						IF status = notfound THEN 
							LET pa_reqdetl[idx].part_code = 
							show_compan(pa_reqdetl[idx-1].part_code) 
						END IF 
						NEXT FIELD part_code 
					END IF 
				END IF 
			BEFORE ROW 
				LET pr_lastkey = NULL 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_reqdetl[idx].part_code IS NULL AND idx != 1 THEN 
					IF compan_avail(pa_reqdetl[idx-1].part_code) THEN 
						LET pr_comp_prod = true 
						LET msgresp=kandoomsg("N",1010,"") 
						#N1010 F1 TO Add; F2...
					ELSE 
						IF pr_comp_prod THEN 
							LET pr_comp_prod = false 
							LET msgresp=kandoomsg("N",1009,"") 
							#N1009 F1 TO Add; F2...
						END IF 
					END IF 
				ELSE 
					IF pr_comp_prod THEN 
						LET pr_comp_prod = false 
						LET msgresp=kandoomsg("N",1009,"") 
						#N1009 F1 TO Add; F2...
					END IF 
				END IF 
				SELECT * INTO pr_reqdetl.* FROM t_reqdetl 
				WHERE line_num = pa_reqdetl[idx].line_num 
				IF status = notfound THEN 
					LET pr_reqdetl.line_num = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") THEN 
						NEXT FIELD line_num 
					END IF 
				ELSE 
					LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
					LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
					LET pa_reqdetl[idx].line_tot_amt = pr_reqdetl.req_qty 
					* pr_reqdetl.unit_sales_amt 
					LET pr_save.warn_flag = pa_reqdetl[idx].warn_flag 
					CALL disp_total(pr_reqdetl.*) 
					IF display_stock(pr_reqdetl.*,2) THEN END IF 
						NEXT FIELD scroll_flag 
					END IF 
			BEFORE FIELD scroll_flag 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND pa_reqdetl[idx].line_num IS NULL THEN 
					NEXT FIELD line_num 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
			BEFORE FIELD line_num 
				IF pr_lastkey IS NULL THEN 
					LET pr_lastkey = fgl_lastkey() 
				END IF 
				IF pr_reqdetl.line_num IS NULL THEN 
					CALL insert_line() RETURNING pr_reqdetl.* 
					LET pm_reqdetl.* = pr_reqdetl.* 
					INITIALIZE ps_reqdetl.* TO NULL 
					LET pr_part_code = NULL 
					LET pa_reqdetl[idx].line_num = pr_reqdetl.line_num 
					LET pa_reqdetl[idx].req_qty = 0 
					LET pa_reqdetl[idx].unit_sales_amt = 0 
					LET pa_reqdetl[idx].line_tot_amt = 0 
					LET pa_reqdetl[idx].warn_flag = NULL 
					LET pa_reqdetl[idx].uom_code = NULL 
					LET pr_save.warn_flag = NULL 
				ELSE 
					LET ps_reqdetl.* = pr_reqdetl.* 
					LET pm_reqdetl.* = pr_reqdetl.* 
					LET pr_part_code = ps_reqdetl.part_code 
					LET pa_reqdetl[idx].line_tot_amt = pr_reqdetl.req_qty 
					* pr_reqdetl.unit_sales_amt 
				END IF 
				CALL disp_total(pr_reqdetl.*) 
				IF display_stock(pr_reqdetl.*,2) THEN END IF 
					IF pr_lastkey = fgl_keyval("left") 
					OR pr_lastkey = fgl_keyval("up") THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						IF pr_reqdetl.po_qty > 0 THEN 
							LET msgresp=kandoomsg("N",9063,"") 
							#N9063 Cannot Edit.  This requsition line has been approved.
							NEXT FIELD scroll_flag 
						ELSE 
							NEXT FIELD part_code 
						END IF 
					END IF 
			AFTER FIELD line_num 
				LET pr_lastkey = fgl_lastkey() 
			AFTER FIELD part_code 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_reqdetl.part_code = pa_reqdetl[idx].part_code 
				IF (pr_part_code IS NULL AND pr_reqdetl.part_code IS NOT null) OR 
				pr_reqdetl.part_code != pr_part_code OR 
				(pr_reqdetl.part_code IS NULL AND pr_part_code IS NOT null) 
				THEN 
					## force change of lineinfo on change of partcode
					LET pr_part_code = pr_reqdetl.part_code 
					LET pr_reqdetl.req_qty = 0 
					LET pr_reqdetl.acct_code = NULL 
				END IF 
				LET pr_save.req_qty = pr_reqdetl.req_qty 
				CALL validate_field("part_code",pr_reqdetl.*,2) 
				RETURNING pr_valid_ind,pr_reqdetl.* 
				CALL disp_total(pr_reqdetl.*) 
				LET pa_reqdetl[idx].part_code = pr_reqdetl.part_code 
				LET pa_reqdetl[idx].req_qty = pr_save.req_qty 
				LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
				IF pr_reqdetl.vend_code = pr_reqhead.ware_code THEN 
					LET msgresp=kandoomsg("I",9111,"") 
					#9111 Supply AND Destination warehouse cannot be the same
					LET pa_reqdetl[idx].warn_flag = "*" 
					DISPLAY pa_reqdetl[idx].warn_flag TO sr_reqdetl[scrn].warn_flag 

					LET pr_valid_ind = false 
				END IF 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							IF pa_reqdetl[idx].part_code IS NULL THEN 
								IF lineitem_entry(pr_reqdetl.*) THEN 
									OPTIONS INSERT KEY f1, 
									DELETE KEY f36 
									NEXT FIELD autoinsert_flag 
								ELSE 
									OPTIONS INSERT KEY f1, 
									DELETE KEY f36 
									NEXT FIELD part_code 
								END IF 
							ELSE 
								SELECT * INTO pr_product.* FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pa_reqdetl[idx].part_code 
								LET pa_reqdetl[idx].uom_code = pr_product.sell_uom_code 
								NEXT FIELD NEXT 
							END IF 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD part_code 
						OTHERWISE 
							NEXT FIELD part_code 
					END CASE 
				ELSE 
					NEXT FIELD part_code 
				END IF 
			AFTER FIELD req_qty 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_reqdetl.req_qty = pa_reqdetl[idx].req_qty 
				CALL validate_field("req_qty",pr_reqdetl.*,2) 
				RETURNING pr_valid_ind,pr_reqdetl.* 
				CALL disp_total(pr_reqdetl.*) 
				LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
				LET pa_reqdetl[idx].warn_flag = pr_save.warn_flag 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							NEXT FIELD autoinsert_flag 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD previous 
						OTHERWISE 
							NEXT FIELD req_qty 
					END CASE 
				ELSE 
					NEXT FIELD req_qty 
				END IF 
			BEFORE FIELD autoinsert_flag 
				SELECT * INTO pr_reqdetl.* FROM t_reqdetl 
				WHERE line_num = pr_reqdetl.line_num 
				IF (pm_reqdetl.part_code IS NULL AND 
				pr_reqdetl.part_code IS NOT null) 
				OR pm_reqdetl.part_code != pr_reqdetl.part_code 
				OR pm_reqdetl.req_qty != pr_reqdetl.req_qty THEN 
					LET trans_text = kandooword("reqhead.stock_ind",pr_reqhead.stock_ind) 
					IF pr_reqhead.stock_ind = 1 THEN 
						IF pr_reqperson.stock_limit_amt > 0 THEN 
							IF pr_reqhead.total_sales_amt > pr_reqperson.stock_limit_amt THEN 
								LET msgresp=kandoomsg("N",9509,trans_text) 
								#9509 limit exceeded
							END IF 
						END IF 
					ELSE 
						IF pr_reqperson.dr_limit_amt > 0 THEN 
							IF pr_reqhead.total_sales_amt > pr_reqperson.dr_limit_amt THEN 
								LET msgresp=kandoomsg("N",9509,trans_text) 
								#9509 limit exceeded
							END IF 
						END IF 
					END IF 
					WHILE true 
						LET upd_flag = 1 
						BEGIN WORK 
							CALL update_line(pm_reqdetl.*) 
							LET upd_flag = stock_line(pm_reqdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 
							IF upd_flag = -1 THEN 
								CONTINUE WHILE 
							ELSE 
								IF upd_flag = 0 THEN 
									CALL update_line(pm_reqdetl.*) 
									LET pr_reqdetl.* = pm_reqdetl.* 
									EXIT WHILE 
								END IF 
							END IF 
							CALL update_line(pr_reqdetl.*) 
							LET upd_flag = stock_line(pr_reqdetl.line_num,"OUT",1) 
							IF upd_flag = -1 THEN 
								CONTINUE WHILE 
							ELSE 
								IF upd_flag = 0 THEN 
									CALL update_line(pm_reqdetl.*) 
									LET pr_reqdetl.* = pm_reqdetl.* 
									EXIT WHILE 
								END IF 
							END IF 
						COMMIT WORK 
						EXIT WHILE 
					END WHILE 
				END IF 
				LET pa_reqdetl[idx].part_code = pr_reqdetl.part_code 
				LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
				LET pa_reqdetl[idx].uom_code = pr_reqdetl.uom_code 
				LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
				LET pa_reqdetl[idx].warn_flag = pr_save.warn_flag 
				CALL disp_total(pr_reqdetl.*) 
				IF pr_lastkey = fgl_keyval("interrupt") 
				OR pr_lastkey = fgl_keyval("accept") THEN 
					## IF line entry NOT complete THEN RETURN TO scroll flag
					NEXT FIELD scroll_flag 
				END IF 
			AFTER FIELD autoinsert_flag 
				LET pr_lastkey = fgl_lastkey() 
			ON KEY (F8) 
				CASE 
				## extract & validate current field
					WHEN infield(scroll_flag) 
						LET pr_temp_text = "scroll_flag" 
						INITIALIZE pm_reqdetl.* TO NULL 
						SELECT * INTO pm_reqdetl.* FROM t_reqdetl 
						WHERE line_num = pa_reqdetl[idx].line_num 
						IF pm_reqdetl.line_num IS NULL THEN 
							CALL insert_line() RETURNING pr_reqdetl.* 
							LET pm_reqdetl.* = pr_reqdetl.* 
							INITIALIZE ps_reqdetl.* TO NULL 
							LET pr_part_code = NULL 
							LET pa_reqdetl[idx].line_num = pr_reqdetl.line_num 
							LET pa_reqdetl[idx].unit_sales_amt = 0 
							LET pa_reqdetl[idx].line_tot_amt = 0 
						END IF 
					WHEN infield(part_code) 
						LET pr_temp_text = "part_code" 
						LET pr_reqdetl.part_code = get_fldbuf(part_code) 
						IF length(pr_reqdetl.part_code) = 0 THEN 
							## get_fldbuf returns spaces instead of nulls
							LET pr_reqdetl.part_code = NULL 
						END IF 
					WHEN infield(req_qty) 
						LET pr_temp_text = "req_qty" 
						WHENEVER ERROR CONTINUE 
						LET pr_reqdetl.req_qty = get_fldbuf(req_qty) 
						WHENEVER ERROR stop 
					WHEN infield(unit_sales_amt) 
						LET pr_temp_text = "unit_sales_amt" 
						WHENEVER ERROR CONTINUE 
						LET pr_reqdetl.unit_sales_amt = get_fldbuf(unit_sales_amt) 
						WHENEVER ERROR stop 
					OTHERWISE 
						LET pr_temp_text = "scroll_flag" 
						SELECT * INTO pr_reqdetl.* FROM t_reqdetl 
						WHERE line_num = pa_reqdetl[idx].line_num 
				END CASE 
				IF pr_temp_text != "part_code" THEN 
					CALL validate_field(pr_temp_text,pr_reqdetl.*,2) 
					RETURNING pr_valid_ind,pr_reqdetl.* 
				ELSE 
					LET pr_valid_ind = true 
				END IF 
				IF pr_valid_ind THEN 
					IF lineitem_entry(pr_reqdetl.*) THEN 
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
						NEXT FIELD autoinsert_flag 
					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
				END IF 
			ON KEY (F2) 
				CASE 
					WHEN infield(scroll_flag) OR 
						pa_reqdetl[idx].part_code IS NULL 
						IF pa_reqdetl[idx].part_code IS NOT NULL THEN 
							IF pr_reqdetl.picked_qty > 0 THEN 
								LET msgresp=kandoomsg("N",9028,"") 
								#N9027 Requsistion IS being Picked. Q...
								NEXT FIELD scroll_flag 
							END IF 
						END IF 
						IF pa_reqdetl[idx].line_tot_amt IS NOT NULL THEN 
							LET pr_reqhead.total_sales_amt = pr_reqhead.total_sales_amt 
							- pa_reqdetl[idx].line_tot_amt 
						END IF 
						DISPLAY BY NAME pr_reqhead.total_sales_amt 

						IF stock_line(pa_reqdetl[idx].line_num,TRAN_TYPE_INVOICE_IN,0) THEN 
							DELETE FROM t_reqdetl 
							WHERE line_num = pa_reqdetl[idx].line_num 
							### shuffle array
							LET j = scrn 
							FOR i = idx TO arr_count() 
								IF i = 2000 THEN 
									INITIALIZE pa_reqdetl[2000].* TO NULL 
								ELSE 
									LET pa_reqdetl[i].* = pa_reqdetl[i+1].* 
								END IF 
								IF pa_reqdetl[i].line_num = 0 THEN 
									INITIALIZE pa_reqdetl[i].* TO NULL 
								END IF 
								IF j <= 10 THEN 
									DISPLAY pa_reqdetl[i].* TO sr_reqdetl[j].* 

									LET j = j + 1 
								END IF 
							END FOR 
							SELECT * INTO pr_reqdetl.* FROM t_reqdetl 
							WHERE line_num = pa_reqdetl[idx].line_num 
							IF sqlca.sqlcode = notfound THEN 
								INITIALIZE pr_reqdetl.* TO NULL 
							END IF 
							CALL quantity_check(pr_reqdetl.*,0) 
							CALL disp_total(pr_reqdetl.*) 
							IF display_stock(pr_reqdetl.*,2) THEN END IF 
								NEXT FIELD scroll_flag 
							ELSE 
								NEXT FIELD scroll_flag 
							END IF 
				END CASE 
			BEFORE INSERT 
				INITIALIZE pa_reqdetl[idx].* TO NULL 
				INITIALIZE pr_reqdetl.* TO NULL 
				### Informix bug - ON LAST ROW, IF del IS pressed, BEFORE INSERT
				### IS re-executed
				IF fgl_lastkey() = fgl_keyval("delete") 
				OR fgl_lastkey() = fgl_keyval("interrupt") THEN 
					INITIALIZE pa_reqdetl[idx].* TO NULL 
					NEXT FIELD scroll_flag 
				ELSE 
					NEXT FIELD line_num 
				END IF 
			AFTER ROW 
				LET int_flag_check = 0 
				IF pa_reqdetl[idx].req_qty = 0 
				AND pa_reqdetl[idx].part_code IS NOT NULL THEN 
					IF int_flag OR quit_flag THEN 
						LET int_flag_check = 1 
					END IF 
					IF int_flag_check THEN 
						LET int_flag = 1 
					END IF 
				END IF 
				SELECT * INTO pr_reqdetl.* FROM t_reqdetl 
				WHERE line_num = pa_reqdetl[idx].line_num 
				IF status = 0 THEN 
					LET pa_reqdetl[idx].unit_sales_amt = pr_reqdetl.unit_sales_amt 
					LET pa_reqdetl[idx].req_qty = pr_reqdetl.req_qty 
				END IF 
				LET pa_reqdetl[idx].line_tot_amt = pa_reqdetl[idx].req_qty 
				* pa_reqdetl[idx].unit_sales_amt 
				LET pa_reqdetl[idx].scroll_flag = NULL 
				DISPLAY pa_reqdetl[idx].* TO sr_reqdetl[scrn].* 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT infield(scroll_flag) THEN 
						LET int_flag = false 
						LET quit_flag = false 
						IF ps_reqdetl.line_num IS NULL THEN 
							DELETE FROM t_reqdetl 
							WHERE line_num = pa_reqdetl[idx].line_num 
							LET j = scrn 
							FOR i = arr_curr() TO arr_count() 
								IF i != arr_count() THEN 
									LET pa_reqdetl[i].* = pa_reqdetl[i+1].* 
								ELSE 
									INITIALIZE pa_reqdetl[i].* TO NULL 
								END IF 
								IF j <= 10 THEN 
									IF pa_reqdetl[i].line_num = 0 THEN 
										LET pa_reqdetl[i].line_num = NULL 
									END IF 
									DISPLAY pa_reqdetl[i].* TO sr_reqdetl[j].* 

									LET j = j + 1 
								END IF 
							END FOR 
							IF arr_curr() = arr_count() THEN 
								INITIALIZE pa_reqdetl[i].* TO NULL 
							END IF 
							NEXT FIELD scroll_flag 
						ELSE 
							CALL update_line(ps_reqdetl.*) 
							LET pa_reqdetl[idx].part_code = ps_reqdetl.part_code 
							LET pa_reqdetl[idx].req_qty = ps_reqdetl.req_qty 
							LET pa_reqdetl[idx].uom_code = ps_reqdetl.uom_code 
							LET pa_reqdetl[idx].unit_sales_amt = 
							ps_reqdetl.unit_sales_amt 
						END IF 
						CALL disp_total(ps_reqdetl.*) 
						NEXT FIELD autoinsert_flag 
					ELSE 
						#N8021 Abort Requisition Line Changes?
						IF kandoomsg("N",8021,"") = "Y" THEN 
							LET int_flag = true 
							IF pr_reqhead.stock_ind != '0' THEN 
								WHILE true 
									LET upd_flag = 1 
									BEGIN WORK 
										FOR i = 1 TO arr_count() 
											LET upd_flag = 
											stock_line(pa_reqdetl[i].line_num,TRAN_TYPE_INVOICE_IN,1) 
											IF upd_flag = -1 THEN 
												CONTINUE WHILE 
											ELSE 
												IF upd_flag = 0 THEN 
													LET int_flag = false 
													LET quit_flag = false 
													NEXT FIELD scroll_flag 
												END IF 
											END IF 
										END FOR 
										LET upd_flag = stock_line(pr_reqhead.req_num,"REQ",1) 
										IF upd_flag = -1 THEN 
											CONTINUE WHILE 
										ELSE 
											IF upd_flag = 0 THEN 
												LET int_flag = false 
												LET quit_flag = false 
												NEXT FIELD scroll_flag 
											END IF 
										END IF 
									COMMIT WORK 
									EXIT WHILE 
								END WHILE 
							END IF 
							DELETE FROM t_reqdetl WHERE 1=1 
							IF pr_mode != "ADD" THEN 
								LET quit_flag = true 
							END IF 
							LET pr_exit_input = true 
							EXIT INPUT 
						ELSE 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				ELSE 
					DELETE FROM t_reqdetl 
					WHERE part_code IS NULL 
					AND acct_code IS NULL 
					### Check FOR warning flagged lines ###
					FOR i = 1 TO arr_count() 
						IF pa_reqdetl[i].part_code IS NOT NULL THEN 
							IF pa_reqdetl[i].warn_flag IS NOT NULL THEN 
								LET pr_found_warn = true 
								IF pa_reqdetl[i].warn_flag = "*" THEN 
									DELETE FROM t_reqdetl 
									WHERE line_num = pa_reqdetl[i].line_num 
								END IF 
							END IF 
						ELSE 
							EXIT FOR 
						END IF 
					END FOR 
					#8022 There are requisition lines with warnings...
					IF pr_found_warn THEN 
						IF kandoomsg("N",8022,"") != "Y" THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					IF (pr_reqhead.stock_ind = 1 
					AND pr_reqperson.stock_limit_amt > 0 
					AND pr_reqhead.total_sales_amt > pr_reqperson.stock_limit_amt) 
					OR ((pr_reqhead.stock_ind = 0 OR pr_reqhead.stock_ind = 2) 
					AND pr_reqperson.dr_limit_amt > 0 
					AND pr_reqhead.total_sales_amt > pr_reqperson.dr_limit_amt) THEN 
						{
						                  OPEN WINDOW w2_N11b AT 12,15 with 2 rows,50 columns      -- albo  KD-763
						                     ATTRIBUTE(border)
						}
						MENU " Person Limit Exceeded" 
							ON ACTION "WEB-HELP" -- albo kd-377 
								CALL onlinehelp(getmoduleid(),null) 
							COMMAND "Hold" " Continue Requisition with Hold Status" 
								LET held_order = true 
								LET pr_reqhead.status_ind = 0 
								EXIT MENU 
							COMMAND KEY(interrupt,"A")"Alter" 
								" Change Requisition Line Items" 
								LET pr_reqhead.status_ind = NULL 
								EXIT MENU 
							COMMAND "Exit" " Exit this Requisition Discarding Changes " 
								LET pr_reqhead.status_ind = 7 
								EXIT MENU 
							COMMAND KEY (control-w) 
								CALL kandoohelp("") 
						END MENU 
						LET int_flag = false 
						LET quit_flag = false 
						--                  CLOSE WINDOW w2_N11b        -- albo  KD-763
						IF pr_reqhead.status_ind IS NULL THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							IF pr_reqhead.status_ind = 7 THEN 
								LET quit_flag = true 
							END IF 
							LET pr_exit_input = true 
							EXIT INPUT 
						END IF 
					ELSE 
						{
						                  OPEN WINDOW w2_N11b AT 12,15 with 2 rows,50 columns
						                     ATTRIBUTE(border)
						}
						MENU " Requisition Entry" 
							BEFORE MENU 
								IF pr_mode != "ADD" THEN 
									HIDE option "Hold" 
								END IF 
							ON ACTION "WEB-HELP" -- albo kd-377 
								CALL onlinehelp(getmoduleid(),null) 
							COMMAND "Save" " Save Requisition Details" 
								LET pr_reqhead.status_ind = 1 
								EXIT MENU 
							COMMAND "Hold" " Continue Requisition with Hold Status" 
								LET held_order = true 
								LET pr_reqhead.status_ind = 0 
								EXIT MENU 
							COMMAND KEY(interrupt,"A")"Alter" 
								" Change Requisition Line Items" 
								LET pr_reqhead.status_ind = NULL 
								EXIT MENU 
							COMMAND "Exit" " Exit this Requisition Discarding Changes " 
								LET pr_reqhead.status_ind = 7 
								EXIT MENU 
							COMMAND KEY (control-w) 
								CALL kandoohelp("") 
						END MENU 
						--                  CLOSE WINDOW w2_N11b      -- albo  KD-763
						LET int_flag = false 
						LET quit_flag = false 
						IF pr_reqhead.status_ind IS NULL THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							IF pr_reqhead.status_ind != 7 THEN 
								LET pr_exit_input = true 
								EXIT INPUT 
							ELSE 
								WHILE true 
									LET upd_flag = 1 
									BEGIN WORK 
										FOR i = 1 TO arr_count() 
											LET upd_flag = 
											stock_line(pa_reqdetl[i].line_num,TRAN_TYPE_INVOICE_IN,1) 
											IF upd_flag = -1 THEN 
												CONTINUE WHILE 
											ELSE 
												IF upd_flag = 0 THEN 
													LET int_flag = false 
													LET quit_flag = false 
													NEXT FIELD scroll_flag 
												END IF 
											END IF 
										END FOR 
										LET upd_flag = stock_line(pr_reqhead.req_num,"REQ",1) 
										IF upd_flag = -1 THEN 
											CONTINUE WHILE 
										ELSE 
											IF upd_flag = 0 THEN 
												LET int_flag = false 
												LET quit_flag = false 
												NEXT FIELD scroll_flag 
											END IF 
										END IF 
									COMMIT WORK 
									EXIT WHILE 
								END WHILE 
								DELETE FROM t_reqdetl WHERE 1=1 
								LET quit_flag = true 
								LET pr_exit_input = true 
								EXIT INPUT 
							END IF 
						END IF 
					END IF 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF pr_exit_input THEN 
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
#
#
FUNCTION insert_line() 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.* 

	INITIALIZE pr_reqdetl.* TO NULL 
	LET pr_reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_reqdetl.req_num = pr_reqhead.req_num 
	SELECT max(line_num) 
	INTO pr_reqhead.line_num 
	FROM t_reqdetl 
	IF pr_reqhead.line_num IS NULL THEN 
		LET pr_reqdetl.line_num = 1 
	ELSE 
		LET pr_reqdetl.line_num = pr_reqhead.line_num + 1 
	END IF 
	LET pr_reqdetl.seq_num = 1 
	LET pr_reqdetl.req_qty = 0 
	LET pr_reqdetl.reserved_qty = 0 
	LET pr_reqdetl.picked_qty = 0 
	LET pr_reqdetl.confirmed_qty = 0 
	LET pr_reqdetl.back_qty = 0 
	LET pr_reqdetl.po_qty = 0 
	LET pr_reqdetl.po_rec_qty = 0 
	LET pr_reqdetl.unit_cost_amt = 0 
	LET pr_reqdetl.unit_tax_amt = 0 
	LET pr_reqdetl.unit_sales_amt = 0 
	LET pr_reqdetl.level_ind = "C" 
	INSERT INTO t_reqdetl VALUES (pr_reqdetl.*) 
	RETURN pr_reqdetl.* 
END FUNCTION 
#
#
FUNCTION update_line(pr_reqdetl) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	ps_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_conv_rate FLOAT 

	SELECT * INTO ps_reqdetl.* 
	FROM t_reqdetl 
	WHERE line_num = pr_reqdetl.line_num 
	IF status = notfound THEN 
		INITIALIZE ps_reqdetl.* TO NULL 
	END IF 
	IF pr_reqdetl.part_code IS NULL THEN 
		IF pr_reqdetl.unit_sales_amt IS NULL THEN 
			LET pr_reqdetl.unit_sales_amt = 0 
		END IF 
	ELSE 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_reqdetl.part_code 
		LET pr_reqdetl.uom_code = pr_product.sell_uom_code 
		IF pr_reqdetl.required_date IS NULL THEN 
			LET pr_reqdetl.required_date = today 
			+ pr_product.days_lead_num 
		END IF 
		IF pr_reqdetl.desc_text IS NULL THEN 
			LET pr_reqdetl.desc_text = pr_product.desc_text 
		END IF 
		IF pr_reqdetl.acct_code IS NULL THEN 
			SELECT sale_acct_code INTO pr_reqdetl.acct_code FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
		END IF 
		IF ps_reqdetl.replenish_ind IS NULL OR 
		pr_reqdetl.replenish_ind <> ps_reqdetl.replenish_ind THEN 
			IF pr_reqdetl.replenish_ind = "P" THEN 
				DECLARE c_prodquote CURSOR FOR 
				SELECT * FROM prodquote 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_reqdetl.part_code 
				AND status_ind = "1" 
				AND expiry_date >= today 
				ORDER BY cost_amt 
				OPEN c_prodquote 
				FETCH c_prodquote INTO pr_prodquote.* 
				IF status = notfound THEN 
					SELECT for_cost_amt INTO pr_reqdetl.unit_sales_amt FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_reqhead.ware_code 
					AND part_code = pr_reqdetl.part_code 
				ELSE 
					LET pr_conv_rate = get_conv_rate(
						glob_rec_kandoouser.cmpy_code,
						pr_prodquote.curr_code,
						today,
						CASH_EXCHANGE_SELL)
						 
					LET pr_reqdetl.vend_code = pr_prodquote.vend_code 
					LET pr_reqdetl.unit_sales_amt = pr_prodquote.cost_amt		/ pr_conv_rate 
					LET pr_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
				END IF 
			ELSE 
				SELECT * INTO pr_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_reqdetl.vend_code 
				AND part_code = pr_reqdetl.part_code 
				LET pr_reqdetl.unit_sales_amt = pr_prodstatus.wgted_cost_amt 
			END IF 
		END IF 
		
		UPDATE t_reqdetl SET 
			line_num = pr_reqdetl.line_num, 
			part_code = pr_reqdetl.part_code, 
			req_qty = pr_reqdetl.req_qty, 
			reserved_qty = pr_reqdetl.reserved_qty, 
			back_qty = pr_reqdetl.back_qty, 
			uom_code = pr_reqdetl.uom_code, 
			unit_cost_amt = pr_reqdetl.unit_cost_amt, 
			unit_sales_amt = pr_reqdetl.unit_sales_amt, 
			desc_text = pr_reqdetl.desc_text, 
			acct_code = pr_reqdetl.acct_code, 
			vend_code = pr_reqdetl.vend_code, 
			required_date = pr_reqdetl.required_date, 
			replenish_ind = pr_reqdetl.replenish_ind 
		WHERE line_num = pr_reqdetl.line_num 
	END IF 
END FUNCTION 
#
#
FUNCTION disp_total(pr_reqdetl) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_tot_line LIKE reqhead.total_sales_amt, 
	pr_desc_text LIKE reqdetl.desc_text, 
	pr_warn_message CHAR(18), 
	scrn SMALLINT 

	### DISPLAY Current Line Info ###
	LET pr_tot_line = pr_reqdetl.req_qty * pr_reqdetl.unit_sales_amt 
	IF pr_tot_line IS NULL THEN 
		LET pr_tot_line = 0 
	END IF 
	LET scrn = scr_line() 
	DISPLAY "",pr_reqdetl.line_num, 
	pr_reqdetl.part_code, 
	pr_reqdetl.req_qty, 
	pr_reqdetl.uom_code, 
	pr_save.warn_flag, 
	pr_reqdetl.unit_sales_amt, 
	pr_tot_line, 
	"" 
	TO sr_reqdetl[scrn].* 

	### DISPLAY Totals & Line Info ###
	SELECT sum(unit_sales_amt*req_qty) INTO pr_reqhead.total_sales_amt 
	FROM t_reqdetl 
	DISPLAY BY NAME pr_reqhead.total_sales_amt 

	SELECT desc_text INTO pr_desc_text FROM t_reqdetl 
	WHERE line_num = pr_reqdetl.line_num 
	DISPLAY pr_desc_text TO reqdetl.desc_text 

	CASE pr_save.warn_flag 
		WHEN "M" LET pr_warn_message = "**Below Min Ord**" 
		WHEN "O" LET pr_warn_message = "**Not Multiple**" 
		OTHERWISE LET pr_warn_message = NULL 
	END CASE 
	DISPLAY pr_warn_message TO warn_message 
	attribute(yellow) 
END FUNCTION 
#
#
FUNCTION check_alternate(pr_part_code,pr_alt_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_alt_part_code LIKE product.alter_part_code, 
	pr_product RECORD LIKE product.* 

	IF pr_alt_part_code IS NULL THEN 
		RETURN false 
	END IF 
	SELECT x.* INTO pr_product.* FROM product x, prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = pr_alt_part_code 
	AND x.part_code = y.part_code 
	AND x.part_code != pr_part_code 
	AND y.ware_code = pr_reqhead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = notfound THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.alter_part_code = pr_alt_part_code 
		AND x.part_code <> pr_part_code 
		AND x.part_code = y.part_code 
		AND y.ware_code = pr_reqhead.ware_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
		IF status = notfound THEN 
			RETURN false 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 
#
# DISPLAY Alternative Products
#
FUNCTION display_alternates(pr_part_code,pr_alt_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_alt_part_code LIKE product.alter_part_code, 
	pr_product RECORD LIKE product.*, 
	pa_product array[50] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		available LIKE prodstatus.onhand_qty 
	END RECORD, 
	pr_available LIKE prodstatus.onhand_qty, 
	idx, scrn SMALLINT 

	SELECT x.* INTO pr_product.* 
	FROM product x, prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = pr_alt_part_code 
	AND x.part_code = y.part_code 
	AND x.part_code != pr_part_code 
	AND y.ware_code = pr_reqhead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = notfound THEN 
		OPEN WINDOW n131 with FORM "N131" 
		CALL windecoration_n("N131") -- albo kd-763 
		DECLARE c_altprod CURSOR FOR 
		SELECT x.part_code, 
		x.desc_text, 
		(y.onhand_qty - y.reserved_qty - y.back_qty) 
		FROM product x, 
		prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.alter_part_code = pr_alt_part_code 
		AND x.part_code <> pr_part_code 
		AND x.part_code = y.part_code 
		AND y.ware_code = pr_reqhead.ware_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
		LET idx = 0 
		FOREACH c_altprod INTO pr_product.part_code, 
			pr_product.desc_text, 
			pr_available 
			LET idx = idx + 1 
			LET pa_product[idx].scroll_flag = NULL 
			LET pa_product[idx].part_code = pr_product.part_code 
			LET pa_product[idx].desc_text = pr_product.desc_text 
			LET pa_product[idx].available = pr_available 
			IF idx = 50 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				#6100 First XX records selected only.  More may be ...
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET msgresp = kandoomsg("U",9113,idx) 
		#9113 XX records selected.
		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE pa_product[idx].* TO NULL 
		END IF 
		CALL set_count(idx) 
		LET msgresp=kandoomsg("U",1019,"") 
		#U1019 Press OK TO...
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INPUT ARRAY pa_product WITHOUT DEFAULTS FROM sr_product.* 

			ON ACTION "WEB-HELP" -- albo kd-377 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				DISPLAY pa_product[idx].* TO sr_product[scrn].* 

			AFTER ROW 
				DISPLAY pa_product[idx].* TO sr_product[scrn].* 

			AFTER FIELD scroll_flag 
				LET pa_product[idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND pa_product[idx+1].part_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#U9001 No more rows in the direction you are going"
					NEXT FIELD scroll_flag 
				END IF 
				LET pr_product.part_code = pa_product[idx].part_code 
			BEFORE FIELD part_code 
				NEXT FIELD scroll_flag 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW n131 
	END IF 
	IF (int_flag OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	END IF 
	RETURN pr_product.part_code 
END FUNCTION 
#
# Determine IF Companion Products are available
#
FUNCTION compan_avail(pr_part_code) 
	DEFINE 
	pr_part_code LIKE prodstatus.part_code, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.* 

	SELECT compn_part_code INTO pr_product.compn_part_code FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	IF pr_product.compn_part_code IS NULL THEN 
		RETURN false 
	END IF 
	SELECT prodstatus.* INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.compn_part_code 
	AND ware_code = pr_reqhead.ware_code 
	AND (onhand_qty - reserved_qty - back_qty ) > 0 
	IF status = notfound THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.cmpy_code = y.cmpy_code 
		AND y.ware_code = pr_reqhead.ware_code 
		AND x.part_code = y.part_code 
		AND x.part_code != pr_part_code 
		AND x.compn_part_code = pr_product.compn_part_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty ) > 0 
		IF status = notfound THEN 
			RETURN false 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 
#
# Show Companion Products
#
FUNCTION show_compan(pr_part_code) 
	DEFINE 
	pr_part_code LIKE product.part_code, 
	pr_product RECORD LIKE product.*, 
	pa_product array[50] OF RECORD 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		available LIKE prodstatus.onhand_qty 
	END RECORD, 
	idx, scrn SMALLINT 

	SELECT compn_part_code INTO pr_product.compn_part_code FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	OPEN WINDOW n132 with FORM "N132" 
	CALL windecoration_n("N132") -- albo kd-763 
	DECLARE c2_prodstatus CURSOR FOR 
	SELECT x.part_code, 
	x.desc_text, 
	(y.onhand_qty - y.reserved_qty - y.back_qty) 
	FROM product x, 
	prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.cmpy_code = y.cmpy_code 
	AND y.ware_code = pr_reqhead.ware_code 
	AND x.part_code = y.part_code 
	AND x.part_code != pr_part_code 
	AND x.compn_part_code = pr_product.compn_part_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty ) > 0 
	LET idx = 1 
	FOREACH c2_prodstatus INTO pa_product[idx].* 
		LET idx = idx + 1 
		IF idx = 50 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET idx = idx -1 
	CALL set_count(idx) 
	LET msgresp=kandoomsg("U",1019,"") 
	#U1019 Press OK TO...
	INPUT ARRAY pa_product WITHOUT DEFAULTS FROM sr_product.* 
		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() > arr_count() THEN 
				LET msgresp=kandoomsg("U",9001,"") 
				#U9001 No more rows in the direction you are going"
			END IF 
		BEFORE FIELD part_code 
			LET pr_part_code = pa_product[idx].part_code 
		AFTER FIELD part_code 
			LET pa_product[idx].part_code = pr_part_code 
			DISPLAY pa_product[idx].* TO sr_product[scrn].* 

		BEFORE FIELD desc_text 
			EXIT INPUT 
		AFTER INPUT 
			LET idx = arr_curr() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW n132 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET pa_product[idx].part_code = " " 
	END IF 
	RETURN pa_product[idx].part_code 
END FUNCTION 


FUNCTION load_req_file() 
	DEFINE l_rpt_idx SMALLINT  
	DEFINE 
	pr_loadreq RECORD 
		bar_code_text LIKE product.bar_code_text, 
		req_qty LIKE reqdetl.req_qty 
	END RECORD, 
	pr2_reqdetl RECORD LIKE reqdetl.*, 
	pr_upd_flag, 
	pr_next_rec, 
	pr_status, 
	pr_idx, 
	pr_next_line_num, 
	pr_remain_num SMALLINT, 
	pr_err_message CHAR(100), 
	pr_runner CHAR(100), 
	pr_msg CHAR(50) 

	### Setup the load exception REPORT ###
	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"N11_rpt_list_exception","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT N11_rpt_list_exception TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num

	#------------------------------------------------------------

--	LET glob_rec_kandooreport.report_code = get_baseprogname() 
--	CALL kandooreport( glob_rec_kandoouser.cmpy_code, glob_rec_kandooreport.report_code ) 
--	RETURNING glob_rec_kandooreport.* 
--	IF glob_rec_kandooreport.header_text IS NULL THEN 
--		CALL set_defaults() 
--	END IF 
--
--	LET glob_rpt_note = "Requistion Load Exception Report" 
--	LET glob_rpt_output = init_report(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, glob_rpt_note) 
--	START REPORT exception_report TO glob_rpt_output 

	LET pr_err_message = "Commence Load FROM file ", pr_reqperson.loadfile_text clipped 
	
	#OUTPUT TO REPORT exception_report(pr_err_message) 
	#---------------------------------------------------------
	OUTPUT TO REPORT N11_rpt_list_exception(l_rpt_idx, pr_err_message)  
	#---------------------------------------------------------

	### Attempt TO Load the File Name ###
	LET pr_count = 0 ### successful RECORD inserts 
	LET pr_next_rec = 0 ### incremented each RECORD processed 
	LET pr_total_count = 0 ### count OF all records in the t_loadreq 
	LET pr_next_rec = 0 ### counts OF records read in FROM t_loadreq 

	WHENEVER ERROR CONTINUE 
	DELETE FROM t_loadreq WHERE 1=1 
	LOAD FROM pr_reqperson.loadfile_text delimiter "," INSERT INTO t_loadreq 
	WHENEVER ERROR stop 

	IF status <> 0 THEN 
		LET pr_err_message = "Failed attempt TO load FROM file ", 
		pr_reqperson.loadfile_text clipped
		#---------------------------------------------------------
		OUTPUT TO REPORT N11_rpt_list_exception(l_rpt_idx, pr_err_message)  
		#---------------------------------------------------------

		#------------------------------------------------------------
		FINISH REPORT N11_rpt_list_exception
		CALL rpt_finish("N11_rpt_list_exception")
		#------------------------------------------------------------
 
		ERROR kandoomsg2("N",7015,pr_reqperson.loadfile_text)	#N7015 Problems loading load file...
		RETURN false 
	ELSE 
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET pr_err_message = "There are records TO process in file ",	pr_reqperson.loadfile_text clipped 
			
			#---------------------------------------------------------
			OUTPUT TO REPORT N11_rpt_list_exception(l_rpt_idx, pr_err_message)  
			#---------------------------------------------------------
	
			#------------------------------------------------------------
			FINISH REPORT N11_rpt_list_exception
			CALL rpt_finish("N11_rpt_list_exception")
			#------------------------------------------------------------
			ERROR kandoomsg2("N",7016,pr_reqperson.loadfile_text)	#N7016 There are no records...There are NO records!...AAAhhhhhhhhhh!!!!
			RETURN false 
		ELSE 
			LET pr_total_count = sqlca.sqlerrd[3] 
		END IF 
	END IF 
	LET msgresp=kandoomsg("U",1028,"") 
	#U1028 Loading File...
	### Find the next ARRAY position AND line_num ###
	SELECT max(line_num+1) INTO pr_next_line_num FROM t_reqdetl 
	IF pr_next_line_num IS NULL THEN 
		LET pr_next_line_num = 1 
	END IF 
	FOR pr_idx = 1 TO pr_arr_size 
		IF pa_reqdetl[pr_idx].part_code IS NULL THEN 
			LET pr_remain_num = pr_idx 
			EXIT FOR 
		END IF 
	END FOR 
	### How many ARRAY rows are left TO fill? ###
	LET pr_remain_num = pr_arr_size - pr_remain_num #ensure does NOT exceed 2000# 
	IF pr_remain_num = 0 THEN 
		LET pr_err_message = "There are no requisition lines available TO load FROM ", 
		"file name ", pr_reqperson.loadfile_text clipped 

			#---------------------------------------------------------
			OUTPUT TO REPORT N11_rpt_list_exception(l_rpt_idx, pr_err_message)  
			#---------------------------------------------------------
	
			#------------------------------------------------------------
			FINISH REPORT N11_rpt_list_exception
			CALL rpt_finish("N11_rpt_list_exception")
			#------------------------------------------------------------

	 
		ERROR kandoomsg2("N",7017,"")	#N7017 There are no records...
		SLEEP 2
		RETURN false 
	END IF 
	### Validate AND Insert each loaded RECORD ###
	DECLARE c_t_loadreq CURSOR with HOLD FOR 
	SELECT * FROM t_loadreq 
	WHENEVER ERROR CONTINUE 
	FOREACH c_t_loadreq INTO pr_loadreq.* 
		LET pr_next_rec = pr_next_rec + 1 
		CALL create_load_record(pr_loadreq.*, pr_next_rec) 
		RETURNING pr_status, pr2_reqdetl.* 
		IF pr_status THEN 
			LET pr_remain_num = pr_remain_num - 1 
			IF pr_remain_num = 0 THEN 
				LET pr_err_message = "Record ARRAY IS full. ", 
				"There are ", pr_count USING "<<<<", 
				" records loaded out of a total of ", 
				pr_total_count USING "<<<<", 
				" records FROM file name ", 
				pr_reqperson.loadfile_text clipped 
				OUTPUT TO REPORT exception_report(pr_err_message) 
				LET msgresp=kandoomsg("N",7018,pr_count) 
				#N7018 The RECORD ARRAY IS full. Only VALUE records loaded.
				EXIT FOREACH 
			ELSE 
				LET pr2_reqdetl.line_num = pr_next_line_num 
				LET pr_next_line_num = pr_next_line_num + 1 
				INSERT INTO t_reqdetl VALUES (pr2_reqdetl.*) 
				IF status != 0 THEN 
					LET pr_err_message = "Failed TO load RECORD on line ", 
					pr_count USING "<<<<", 
					" in file name ", 
					pr_reqperson.loadfile_text clipped, 
					". See ", trim(get_settings_logFile()), " for error." 
					OUTPUT TO REPORT exception_report(pr_err_message) 
					LET pr_err_message = "Failed TO load RECORD on line ", 
					pr_count USING "<<<<", 
					" in file name ", 
					pr_reqperson.loadfile_text clipped 
					CALL errorlog(pr_err_message) 
					LET pr_next_line_num = pr_next_line_num - 1 
				ELSE 
					LET pr_upd_flag = 1 
					IF pr_reqhead.stock_ind != '0' THEN 
						WHILE true 
							LET pr_upd_flag = 1 
							BEGIN WORK 
								LET pr_upd_flag = stock_line(pr2_reqdetl.line_num,"OUT",1) 
								IF pr_upd_flag = -1 THEN 
									ROLLBACK WORK 
									CONTINUE WHILE 
								ELSE 
									IF pr_upd_flag = 0 THEN 
										EXIT WHILE 
									END IF 
								END IF 
							COMMIT WORK 
							EXIT WHILE 
						END WHILE 
					END IF 
					IF NOT pr_upd_flag THEN 
						LET pr_err_message = "Failed TO load RECORD on line ", 
						pr_count USING "<<<<", 
						" in file name ", 
						pr_reqperson.loadfile_text clipped, 
						". See ", trim(get_settings_logFile()), " for error." 
						OUTPUT TO REPORT exception_report(pr_err_message) 
						LET pr_err_message = "Failed TO load RECORD on line ", 
						pr_count USING "<<<<", 
						" in file name ", 
						pr_reqperson.loadfile_text clipped 
						CALL errorlog(pr_err_message) 
						DELETE FROM t_reqdetl WHERE line_num = pr2_reqdetl.line_num 
					ELSE 
						LET pr_count = pr_count + 1 
					END IF 
				END IF 
			END IF 
		END IF 
		LET pr_msg = "Loading Line ", pr_next_rec USING "###&", " of ", 
		pr_total_count USING "###&" 
		DISPLAY pr_msg at 1,2 attribute(yellow) 
	END FOREACH 
	
		#------------------------------------------------------------
		FINISH REPORT N11_rpt_list_exception
		CALL rpt_finish("N11_rpt_list_exception")
		#------------------------------------------------------------
	 
	IF pr_count = 0 THEN 
		LET msgresp=kandoomsg("N",7019,pr_reqperson.loadfile_text) 
		#N7019 Unsuccessful load of filename...
		RETURN false 
	ELSE 
		LET pr_runner = "mv -f ", pr_reqperson.loadfile_text clipped, 
		" ", pr_reqperson.loadfile_text clipped, ".tmp" 
		RUN pr_runner 
		IF pr_count != pr_total_count THEN 
			LET msgresp=kandoomsg("N",7020,"") 
			#N7020 Not all records have ...
		ELSE 
			LET msgresp=kandoomsg("N",7021,"") 
			#N7020 All requisition records have...
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


FUNCTION create_load_record(pr_loadreq, pr_cnt) 
	DEFINE 
	pr_loadreq RECORD 
		bar_code_text LIKE product.bar_code_text, 
		req_qty LIKE reqdetl.req_qty 
	END RECORD, 
	pr_available LIKE prodstatus.onhand_qty, 
	pr_conv_rate FLOAT, 
	pr_status, 
	pr_cnt SMALLINT, 
	pr_err_message CHAR(100), 
	pr3_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_category RECORD LIKE category.*, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_prodquote RECORD LIKE prodquote.* 

	### Designed TO create a valid reqdetl RECORD ###
	INITIALIZE pr3_reqdetl.* TO NULL 
	LET pr3_reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr3_reqdetl.req_num = 0 
	LET pr3_reqdetl.seq_num = 1 
	LET pr3_reqdetl.req_qty = 0 
	LET pr3_reqdetl.reserved_qty = 0 
	LET pr3_reqdetl.back_qty = 0 
	LET pr3_reqdetl.picked_qty = 0 
	LET pr3_reqdetl.confirmed_qty = 0 
	LET pr3_reqdetl.po_qty = 0 
	LET pr3_reqdetl.po_rec_qty = 0 
	LET pr3_reqdetl.unit_cost_amt = 0 
	LET pr3_reqdetl.unit_sales_amt= 0 
	LET pr3_reqdetl.unit_tax_amt = 0 
	LET pr3_reqdetl.level_ind = "C" 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bar_code_text = pr_loadreq.bar_code_text 
	IF status = notfound THEN 
		LET pr_err_message = "Cannot find Product FOR Bar Code: ", 
		pr_loadreq.bar_code_text clipped, " on Line ", 
		pr_cnt USING "<<<<<", " of file ", 
		pr_reqperson.loadfile_text clipped 
		OUTPUT TO REPORT exception_report(pr_err_message) 
		RETURN false, pr3_reqdetl.* 
	END IF 
	IF pr_product.super_part_code IS NOT NULL 
	AND pr_product.super_part_code != " " THEN 
		LET pr3_reqdetl.part_code = pr_product.super_part_code 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr3_reqdetl.part_code 
		IF status = notfound THEN 
			LET pr_err_message = "Cannot find Supersession Product ", 
			pr3_reqdetl.part_code clipped, " on Line ", 
			pr_cnt USING "<<<<<", " of file ", 
			pr_reqperson.loadfile_text clipped 
			OUTPUT TO REPORT exception_report(pr_err_message) 
			RETURN false, pr3_reqdetl.* 
		END IF 
	ELSE 
		LET pr3_reqdetl.part_code = pr_product.part_code 
	END IF 
	SELECT category.* INTO pr_category.* FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		LET pr_err_message = "Cannot find Product Category FOR Product ", 
		pr3_reqdetl.part_code clipped, " on Line ", 
		pr_cnt USING "<<<<<", " of file ", 
		pr_reqperson.loadfile_text clipped 
		OUTPUT TO REPORT exception_report(pr_err_message) 
		RETURN false, pr3_reqdetl.* 
	END IF 
	LET pr3_reqdetl.acct_code = pr_category.sale_acct_code 
	LET pr3_reqdetl.vend_code = pr_product.vend_code 
	LET pr3_reqdetl.uom_code = pr_product.sell_uom_code 
	LET pr3_reqdetl.desc_text = pr_product.desc_text 
	LET pr3_reqdetl.required_date = today + pr_product.days_lead_num 
	### Validate the product AND warehouse combination ###
	IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr3_reqdetl.part_code, 
	pr_reqhead.ware_code,0,1,0,"","","") 
	THEN 
		LET pr_err_message = "Product ", pr_product.part_code clipped, 
		" AND Warehouse ", pr_reqhead.ware_code clipped, 
		" IS NOT a valid combination. ", 
		"Check line ", pr_cnt USING "<<<<", " in file ", 
		pr_reqperson.loadfile_text clipped 
		OUTPUT TO REPORT exception_report(pr_err_message) 
		RETURN false, pr3_reqdetl.* 
	END IF 
	### Stock availability ###
	LET pr3_reqdetl.req_qty = pr_loadreq.req_qty 
	IF pr3_reqdetl.req_qty < 0 THEN 
		LET pr3_reqdetl.req_num = -1 
	END IF 
	SELECT prodstatus.*, (onhand_qty - reserved_qty - back_qty) 
	INTO pr_prodstatus.*, 
	pr_available 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_reqhead.ware_code 
	AND part_code = pr_product.part_code 
	IF status = notfound THEN 
		LET pr_err_message = "Product ", pr_product.part_code clipped, 
		" AND Warehouse ", pr_reqhead.ware_code clipped, 
		" could NOT be retrieved. ", 
		"Check line ", pr_cnt USING "<<<<", " in file ", 
		pr_reqperson.loadfile_text clipped 
		OUTPUT TO REPORT exception_report(pr_err_message) 
		RETURN false, pr3_reqdetl.* 
	END IF 
	IF pr_reqhead.stock_ind != "0" THEN 
		IF pr_available <= 0 THEN 
			LET pr3_reqdetl.back_qty = pr_loadreq.req_qty 
			LET pr3_reqdetl.reserved_qty = 0 
		ELSE 
			IF pr_loadreq.req_qty > pr_available THEN 
				LET pr3_reqdetl.reserved_qty = pr3_reqdetl.req_qty 
				- pr_available 
				LET pr3_reqdetl.back_qty = pr3_reqdetl.req_qty 
				- pr3_reqdetl.reserved_qty 
			ELSE 
				LET pr3_reqdetl.reserved_qty = pr3_reqdetl.req_qty 
				LET pr3_reqdetl.back_qty = 0 
			END IF 
		END IF 
	ELSE 
		LET pr3_reqdetl.reserved_qty = 0 
		LET pr3_reqdetl.back_qty = 0 
	END IF 
	### Check the quantity requested against outer/minimum VALUES ###
	### line_num = -1 IS ok record; line_num = -2 IS NOT ok record###
	### the line_num value IS used in the ARRAY processing section###
	### TO determine whether a "*" should be used OR NOT.         ###
	LET pr_save.warn_flag = NULL 
	CALL quantity_check(pr3_reqdetl.*,0) 
	### Replenishment Indicator AND Unit Cost/Sales Amt###
	IF pr_prodstatus.replenish_ind IS NULL THEN 
		LET pr3_reqdetl.replenish_ind = "P" 
	ELSE 
		LET pr3_reqdetl.replenish_ind = pr_prodstatus.replenish_ind 
	END IF 
	### Collect other vendor/warehouse default VALUES ###
	IF pr3_reqdetl.replenish_ind != "S" THEN 
		DECLARE c3_prodquote CURSOR FOR 
		SELECT * FROM prodquote 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr3_reqdetl.part_code 
		AND status_ind = "1" 
		AND expiry_date >= today 
		ORDER BY cost_amt 
		OPEN c3_prodquote 
		FETCH c3_prodquote INTO pr_prodquote.* 
		
		IF status = notfound THEN 
			SELECT for_cost_amt INTO pr3_reqdetl.unit_sales_amt FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_reqhead.ware_code 
			AND part_code = pr3_reqdetl.part_code 
		ELSE 
			LET pr_conv_rate = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				pr_prodquote.curr_code,
				today,
				CASH_EXCHANGE_SELL) 
			LET pr3_reqdetl.unit_sales_amt = pr_prodquote.cost_amt / pr_conv_rate 
			LET pr3_reqdetl.vend_code = pr_prodquote.vend_code 
			LET pr3_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
		END IF 
		CLOSE c3_prodquote 
	ELSE 
		SELECT * INTO pr_puparms.* FROM puparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT wgted_cost_amt INTO pr3_reqdetl.unit_sales_amt FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = pr_puparms.usual_ware_code 
		AND part_code = pr3_reqdetl.part_code 
		LET pr3_reqdetl.vend_code = pr_puparms.usual_ware_code 
	END IF 
	RETURN true, pr3_reqdetl.* 
END FUNCTION 
#
# Exception Report Listing
#
REPORT N11_rpt_list_exception(p_rpt_idx,pr_comments)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx] 
	DEFINE 
	pa_line array[4] OF CHAR(132), 
	pr_date_time DATETIME year TO second, 
	pr_comments CHAR(120) 

	OUTPUT 
	--left margin 0 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
		ON EVERY ROW 
			LET pr_date_time = CURRENT 
			PRINT COLUMN 001, pr_date_time, 
			COLUMN 022, pr_comments clipped 
		ON LAST ROW 
			NEED 20 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 10, "Total Requistion records TO be processed : ", 
			pr_total_count USING "####&" 
			SKIP 1 line 
			PRINT COLUMN 10, "Total records NOT processed : ", 
			(pr_total_count - pr_count) USING "####&" 
			PRINT COLUMN 10, "Total records successfully processed : ", 
			pr_count USING "####&" 
			PRINT COLUMN 54, "-------" 
			PRINT COLUMN 10, "Total records processed : ", 
			pr_total_count USING "####&" 
			PRINT COLUMN 54, "-------" 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
#
# Set Default parameters FOR Exception Report
#

