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
# Requires
# common/dispgpfunc.4gl
###########################################################################

###########################################################################
# \brief module Q11d - Line Item Entry (Scan Array)
#
#    Note: The variable pr_quotedetl.job_code IS used within
#          the program TO flag (TRUE/FALSE) whether a line has
#          been used in a discount calculation OR NOT
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

FUNCTION lineitem_scan() 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	ps_quotedetl RECORD LIKE quotedetl.*, 
	pa_quotedetl array[500] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE quotedetl.line_num, 
		offer_code LIKE quotedetl.offer_code, 
		part_code LIKE quotedetl.part_code, 
		sold_qty LIKE quotedetl.sold_qty, 
		bonus_qty LIKE quotedetl.bonus_qty, 
		disc_per LIKE quotedetl.disc_per, 
		unit_price_amt LIKE quotedetl.unit_price_amt, 
		line_tot_amt LIKE quotedetl.line_tot_amt, 
		autoinsert_flag LIKE quotedetl.autoinsert_flag 
	END RECORD, 
	pr_product RECORD LIKE product.*, 
	pr_tmp_sold_qty LIKE quotedetl.sold_qty, 
	pr_tmp_bonus_qty LIKE quotedetl.bonus_qty, 
	reset_offer SMALLINT, 
	pr_comp_prod, upd_flag SMALLINT, 
	pr_int_flag, int_flag_check,idx,scrn,pr_valid_ind,i,j SMALLINT, 
	pr_lastkey INTEGER, 
	pr_part_code LIKE product.part_code 

	LET pr_int_flag = false 
	DISPLAY BY NAME pr_customer.cred_bal_amt 

	DISPLAY BY NAME pr_quotehead.currency_code 
	attribute(green) 
	DECLARE c1_quotedetl CURSOR FOR 
	SELECT * FROM t_quotedetl 
	ORDER BY line_num 
	WHILE true 
		LET idx = 0 
		LET reset_offer = false 
		FOREACH c1_quotedetl INTO pr_quotedetl.* 
			LET idx = idx + 1 
			IF pr_quotedetl.line_num != idx THEN 
				UPDATE t_quotedetl 
				SET line_num = idx 
				WHERE line_num = pr_quotedetl.line_num 
			END IF 
			LET pa_quotedetl[idx].line_num = idx 
			LET pa_quotedetl[idx].offer_code = pr_quotedetl.offer_code 
			LET pa_quotedetl[idx].part_code = pr_quotedetl.part_code 
			LET pa_quotedetl[idx].sold_qty = pr_quotedetl.sold_qty 
			LET pa_quotedetl[idx].bonus_qty = pr_quotedetl.bonus_qty 
			LET pa_quotedetl[idx].disc_per = pr_quotedetl.disc_per 
			LET pa_quotedetl[idx].unit_price_amt = pr_quotedetl.unit_price_amt 
			IF pr_arparms.show_tax_flag = "Y" THEN 
				LET pa_quotedetl[idx].line_tot_amt = pr_quotedetl.sold_qty 
				* (pr_quotedetl.unit_tax_amt 
				+ pr_quotedetl.unit_price_amt) 
			ELSE 
				LET pa_quotedetl[idx].line_tot_amt = pr_quotedetl.unit_price_amt 
				* pr_quotedetl.sold_qty 
			END IF 
			IF pr_quotedetl.autoinsert_flag = "Y" THEN 
				LET pa_quotedetl[idx].autoinsert_flag = "*" 
			ELSE 
				LET pa_quotedetl[idx].autoinsert_flag = NULL 
			END IF 
			LET pr_quotedetl.line_num = idx 
		END FOREACH 
		CALL set_count(idx) 
		LET pr_comp_prod = false 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f36 
		LET msgresp=kandoomsg("E",1024,"") 
		#1024 F1 TO Add etc...
		INPUT ARRAY pa_quotedetl WITHOUT DEFAULTS FROM sr_quotedetl.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q11d","inp_arr-pa_quotedetl-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (F1,F5) --customer details / customer invoice submenu 
				--- modif ericv init # ON KEY(F5)
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) --customer details / customer invoice submenu 

			ON KEY (control-b) infield (offer_code) 
				LET pr_temp_text = 
				"exists(SELECT 1 FROM t_orderpart ", 
				"WHERE t_orderpart.offer_code=offersale.offer_code)" 
				LET pr_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF pr_temp_text IS NOT NULL THEN 
					LET pa_quotedetl[idx].offer_code = pr_temp_text 
					NEXT FIELD offer_code 
				END IF 

			ON KEY (control-b) infield (part_code) 
				LET pr_temp_text= "status_ind!='3' AND part_code =", 
				"(SELECT part_code FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND ware_code='",pr_quotedetl.ware_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND status_ind!='3')" 
				IF pa_quotedetl[idx].offer_code IS NOT NULL THEN 
					LET pr_temp_text=pr_temp_text clipped," AND exists ", 
					"(SELECT 1 FROM offerprod ", 
					"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND offer_code='",pa_quotedetl[idx].offer_code,"' ", 
					"AND maingrp_code=product.maingrp_code ", 
					"AND (prodgrp_code =product.prodgrp_code ", 
					"OR prodgrp_code IS NULL)", 
					"AND (part_code =product.part_code ", 
					"OR part_code IS NULL))" 
				END IF 
				LET pr_temp_text = show_part(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF pr_temp_text IS NOT NULL THEN 
					LET pa_quotedetl[idx].part_code = pr_temp_text 
					NEXT FIELD part_code 
				END IF 

			ON KEY (F7) 
				IF infield(part_code) THEN 
					LET pr_temp_text 
					= view_custpart_code(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					IF pr_temp_text IS NOT NULL THEN 
						LET pa_quotedetl[idx].part_code = pr_temp_text 
						NEXT FIELD part_code 
					END IF 
				END IF 
				
			ON ACTION "NOTES"  --ON KEY (control-n) 
				CALL dispgpfunc(
					pr_quotehead.currency_code, 
					pr_quotedetl.ext_cost_amt, 
					pr_quotedetl.ext_price_amt) 
			ON KEY (control-f) 
				IF infield(scroll_flag) THEN 
					IF image_quotelines() THEN 
						EXIT INPUT 
					END IF 
				END IF
				 
			ON KEY (F6) 
				IF pa_quotedetl[idx].part_code IS NULL AND 
				pa_quotedetl[idx].sold_qty = 0 AND 
				pa_quotedetl[idx].bonus_qty = 0 AND 
				pr_quotedetl.status_ind <> "3" THEN 
					DELETE FROM t_quotedetl 
					WHERE line_num = pa_quotedetl[idx].line_num 
				END IF 
				IF offer_entry() THEN 
					LET reset_offer = true 
					EXIT INPUT 
				END IF 
			ON KEY (F10) 
				SELECT unique 1 FROM t_orderpart 
				IF sqlca.sqlcode = 0 OR pr_quotehead.cond_code IS NOT NULL THEN 
					## Auto discount calc. FOR spec.offers OR conditions
					EXIT INPUT 
				END IF 
			ON KEY (F9) 
				IF infield(part_code) THEN 
					IF pr_comp_prod THEN 
						SELECT y.part_code 
						INTO pa_quotedetl[idx].part_code 
						FROM product x, 
						product y, 
						prodstatus z 
						WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND z.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND x.part_code = pa_quotedetl[idx-1].part_code 
						AND y.part_code = x.compn_part_code 
						AND y.part_code = z.part_code 
						AND z.ware_code = pr_quotehead.ware_code 
						AND (z.onhand_qty - z.reserved_qty - z.back_qty) > 0 
						IF status = notfound THEN 
							LET pa_quotedetl[idx].part_code = 
							show_compan(pa_quotedetl[idx-1].part_code) 
						END IF 
						NEXT FIELD part_code 
					END IF 
				END IF 
			BEFORE ROW 
				LET pr_lastkey = NULL 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_quotedetl[idx].part_code IS NULL AND idx != 1 THEN 
					IF compan_avail(pa_quotedetl[idx-1].part_code) THEN 
						LET pr_comp_prod = true 
						LET msgresp=kandoomsg("E",1182,"") 
						#1182 F1 TO Add; F2...F9 Companion etc..
					ELSE 
						IF pr_comp_prod THEN 
							LET pr_comp_prod = false 
							LET msgresp=kandoomsg("E",1024,"") 
							#1024 F1 TO Add etc...
						END IF 
					END IF 
				ELSE 
					IF pr_comp_prod THEN 
						LET pr_comp_prod = false 
						LET msgresp=kandoomsg("E",1024,"") 
						#1024 F1 TO Add etc...
					END IF 
				END IF 
				SELECT * INTO pr_quotedetl.* FROM t_quotedetl 
				WHERE line_num = pa_quotedetl[idx].line_num 
				IF status = notfound THEN 
					LET pr_quotedetl.line_num = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") THEN 
						NEXT FIELD line_num 
					END IF 
				ELSE 
					CALL disp_total(pr_quotedetl.*) 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD scroll_flag 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				DISPLAY pa_quotedetl[idx].* TO sr_quotedetl[scrn].* 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF pa_quotedetl[idx].line_num IS NULL THEN 
						NEXT FIELD line_num 
					END IF 
				END IF 
				LET pr_lastkey = fgl_lastkey() 
			BEFORE FIELD line_num 
				IF pr_lastkey IS NULL THEN 
					LET pr_lastkey = fgl_lastkey() 
				END IF 
				IF pr_quotedetl.line_num IS NULL THEN 
					CALL insert_line() RETURNING pr_quotedetl.* 
					LET pm_quotedetl.* = pr_quotedetl.* 
					INITIALIZE ps_quotedetl.* TO NULL 
					LET pr_part_code = NULL 
					LET pa_quotedetl[idx].line_num = pr_quotedetl.line_num 
					IF idx > 1 THEN 
						LET pa_quotedetl[idx].offer_code 
						= pa_quotedetl[idx-1].offer_code 
					END IF 
					LET pa_quotedetl[idx].sold_qty = 0 
					LET pa_quotedetl[idx].bonus_qty = 0 
					LET pa_quotedetl[idx].disc_per = 0 
					LET pa_quotedetl[idx].unit_price_amt = 0 
					LET pa_quotedetl[idx].line_tot_amt = 0 
				ELSE 
					LET ps_quotedetl.* = pr_quotedetl.* 
					LET pm_quotedetl.* = pr_quotedetl.* 
					LET pr_part_code = ps_quotedetl.part_code 
					IF pr_quotedetl.autoinsert_flag = "Y" THEN 
						IF lineitem_entry(pr_quotedetl.*) THEN 
						END IF 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 
				CALL disp_total(pr_quotedetl.*) 
				IF pr_lastkey = fgl_keyval("left") 
				OR pr_lastkey = fgl_keyval("up") THEN 
					NEXT FIELD scroll_flag 
				ELSE 
					NEXT FIELD offer_code 
				END IF 
			AFTER FIELD line_num 
				LET pr_lastkey = fgl_lastkey() 
			BEFORE FIELD offer_code 
				SELECT unique 1 FROM t_orderpart 
				WHERE offer_code != "###" 
				IF sqlca.sqlcode = notfound THEN 
					LET pa_quotedetl[idx].offer_code = NULL 
					## IF no offers nominated THEN noentry TO field
					IF pr_lastkey = fgl_keyval("left") 
					OR pr_lastkey = fgl_keyval("up") THEN 
						NEXT FIELD scroll_flag 
					ELSE 
						NEXT FIELD part_code 
					END IF 
				END IF 
			AFTER FIELD offer_code 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.offer_code = pa_quotedetl[idx].offer_code 
				CALL validate_field("offer_code",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].offer_code = pr_quotedetl.offer_code 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							NEXT FIELD NEXT 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD offer_code 
						OTHERWISE 
							NEXT FIELD offer_code 
					END CASE 
				ELSE 
					NEXT FIELD offer_code 
				END IF 
			AFTER FIELD part_code 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.part_code = pa_quotedetl[idx].part_code 
				IF (pr_part_code IS NULL AND pr_quotedetl.part_code IS NOT null) OR 
				pr_quotedetl.part_code != pr_part_code OR 
				(pr_quotedetl.part_code IS NULL AND pr_part_code IS NOT null) THEN 
					## force change of lineinfo on change of partcode
					LET pr_part_code = pr_quotedetl.part_code 
					LET pr_quotedetl.order_qty = 0 
					LET pr_quotedetl.sold_qty = 0 
					LET pr_quotedetl.bonus_qty = 0 
					LET pr_quotedetl.unit_price_amt = 0 
					LET pr_quotedetl.desc_text = NULL 
					CALL get_lead(pr_quotedetl.*) 
					RETURNING pr_quotedetl.quote_lead_text, 
					pr_quotedetl.quote_lead_text2 
				END IF 
				CALL validate_field("part_code",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].part_code = pr_quotedetl.part_code 
				LET pa_quotedetl[idx].sold_qty = pr_quotedetl.sold_qty 
				LET pa_quotedetl[idx].bonus_qty = pr_quotedetl.bonus_qty 
				LET pa_quotedetl[idx].disc_per = pr_quotedetl.disc_per 
				LET pa_quotedetl[idx].unit_price_amt = pr_quotedetl.unit_price_amt 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							IF pa_quotedetl[idx].part_code IS NULL THEN 
								LET msgresp = kandoomsg("U",9102,"") 
								#9102 Value must be entered
								NEXT FIELD part_code 
							ELSE 
								SELECT * INTO pr_product.* FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pa_quotedetl[idx].part_code 
								LET pr_quotedetl.status_ind = "0" 
								NEXT FIELD NEXT 
							END IF 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							IF pa_quotedetl[idx].part_code IS NULL THEN 
								LET msgresp = kandoomsg("U",9102,"") 
								#9102 Value must be entered
								NEXT FIELD part_code 
							ELSE 
								SELECT * INTO pr_product.* FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pa_quotedetl[idx].part_code 
								IF status = notfound THEN 
									LET pr_quotedetl.status_ind = "3" 
								ELSE 
									LET pr_quotedetl.status_ind = "0" 
								END IF 
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
			BEFORE FIELD sold_qty 
				LET pr_tmp_sold_qty = pa_quotedetl[idx].sold_qty 
			AFTER FIELD sold_qty 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.sold_qty = pa_quotedetl[idx].sold_qty 
				IF pr_tmp_sold_qty != pa_quotedetl[idx].sold_qty THEN 
					CALL get_lead(pr_quotedetl.*) 
					RETURNING pr_quotedetl.quote_lead_text, 
					pr_quotedetl.quote_lead_text2 
				END IF 
				CALL validate_field("sold_qty",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].sold_qty = pr_quotedetl.sold_qty 
				LET pa_quotedetl[idx].bonus_qty = pr_quotedetl.bonus_qty 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							NEXT FIELD NEXT 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD previous 
						OTHERWISE 
							NEXT FIELD sold_qty 
					END CASE 
				ELSE 
					NEXT FIELD sold_qty 
				END IF 
			BEFORE FIELD bonus_qty ## cannot enter bonus IF bonus_flag = n 
				IF pr_quotehead.cond_code IS NULL 
				AND pr_quotedetl.offer_code IS NULL THEN 
					LET pr_product.bonus_allow_flag = "N" 
				END IF 
				IF pr_product.bonus_allow_flag = "N" 
				OR pr_quotedetl.trade_in_flag = "Y" 
				OR pr_quotedetl.status_ind = "3" THEN 
					LET pa_quotedetl[idx].bonus_qty = 0 
					IF pr_lastkey=fgl_keyval("left") 
					OR pr_lastkey=fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
				LET pr_tmp_bonus_qty = pa_quotedetl[idx].bonus_qty 
			AFTER FIELD bonus_qty 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.bonus_qty = pa_quotedetl[idx].bonus_qty 
				IF pa_quotedetl[idx].bonus_qty != pr_tmp_bonus_qty THEN 
					CALL get_lead(pr_quotedetl.*) 
					RETURNING pr_quotedetl.quote_lead_text, 
					pr_quotedetl.quote_lead_text2 
				END IF 
				CALL validate_field("bonus_qty",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].bonus_qty = pr_quotedetl.bonus_qty 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							NEXT FIELD NEXT 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD previous 
						OTHERWISE 
							NEXT FIELD bonus_qty 
					END CASE 
				ELSE 
					NEXT FIELD sold_qty 
				END IF 
			BEFORE FIELD disc_per 
				LET pr_quotedetl.order_qty = pa_quotedetl[idx].bonus_qty 
				+ pa_quotedetl[idx].sold_qty 
				IF pr_quotedetl.status_ind = "0" THEN 
					##### PROMPT TO SELL UP WHOLE CARTON
					IF pr_product.stock_uom_code != pr_product.sell_uom_code 
					AND pr_product.stk_sel_con_qty > 1 THEN 
						LET i =(pr_quotedetl.order_qty/pr_product.stk_sel_con_qty)+0.5 
						LET j =(i * pr_product.stk_sel_con_qty) 
						IF pr_quotedetl.order_qty >= (glob_rec_opparms.sellup_per/100)*j 
						AND pr_quotedetl.order_qty < j THEN 
							IF kandoomsg("E",8014,j) = "Y" THEN 
								## Do you want TO change TO qty TO entire carton
								LET pa_quotedetl[idx].sold_qty = 
								pa_quotedetl[idx].sold_qty+j- pr_quotedetl.order_qty 
								NEXT FIELD sold_qty 
							END IF 
						END IF 
					END IF 
				END IF 
				IF pr_quotedetl.offer_code IS NOT NULL 
				OR pr_quotedetl.disc_allow_flag = "N" THEN 
					NEXT FIELD autoinsert_flag 
				END IF 
			AFTER FIELD disc_per 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.disc_per = pa_quotedetl[idx].disc_per 
				CALL validate_field("disc_per",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].disc_per = pr_quotedetl.disc_per 
				LET pa_quotedetl[idx].unit_price_amt = pr_quotedetl.unit_price_amt 
				IF pr_valid_ind THEN 
					CASE 
						WHEN pr_lastkey=fgl_keyval("accept") 
							NEXT FIELD autoinsert_flag ### line DISPLAY 
						WHEN pr_lastkey=fgl_keyval("RETURN") 
							OR pr_lastkey=fgl_keyval("right") 
							OR pr_lastkey=fgl_keyval("tab") 
							OR pr_lastkey=fgl_keyval("down") 
							NEXT FIELD NEXT 
						WHEN pr_lastkey=fgl_keyval("left") 
							OR pr_lastkey=fgl_keyval("up") 
							NEXT FIELD previous 
						OTHERWISE 
							NEXT FIELD disc_per 
					END CASE 
				ELSE 
					NEXT FIELD disc_per 
				END IF 
			BEFORE FIELD unit_price_amt 
				IF pr_quotedetl.offer_code IS NOT NULL 
				OR pr_quotedetl.disc_allow_flag = "N" THEN 
					NEXT FIELD autoinsert_flag 
				END IF 
			AFTER FIELD unit_price_amt 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_quotedetl.unit_price_amt = pa_quotedetl[idx].unit_price_amt 
				CALL validate_field("unit_price_amt",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				CALL disp_total(pr_quotedetl.*) 
				LET pa_quotedetl[idx].disc_per = pr_quotedetl.disc_per 
				LET pa_quotedetl[idx].unit_price_amt = pr_quotedetl.unit_price_amt 
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
							NEXT FIELD unit_price_amt 
					END CASE 
				ELSE 
					NEXT FIELD unit_price_amt 
				END IF 
			BEFORE FIELD autoinsert_flag 
				SELECT * INTO pr_quotedetl.* FROM t_quotedetl 
				WHERE line_num = pr_quotedetl.line_num 
				IF (pm_quotedetl.part_code IS NULL AND 
				pr_quotedetl.part_code IS NOT null) 
				OR pm_quotedetl.part_code != pr_quotedetl.part_code 
				OR pm_quotedetl.status_ind != pr_quotedetl.status_ind THEN 
					IF pr_quotedetl.acct_code IS NULL 
					AND pr_quotedetl.line_tot_amt > 0 THEN 
						IF pr_quotedetl.part_code IS NOT NULL THEN 
							SELECT unique 1 FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_quotedetl.part_code 
							IF status = 0 THEN 
								LET pr_quotedetl.acct_code = 
								enter_acct(pr_quotedetl.acct_code) 
								IF pr_quotedetl.acct_code IS NULL THEN 
									NEXT FIELD part_code 
								END IF 
							END IF 
						ELSE 
							LET pr_quotedetl.acct_code = 
							enter_acct(pr_quotedetl.acct_code) 
							IF pr_quotedetl.acct_code IS NULL THEN 
								NEXT FIELD part_code 
							END IF 
						END IF 
					END IF 
					CALL update_line(pr_quotedetl.*) 
				END IF 
				LET pa_quotedetl[idx].offer_code = pr_quotedetl.offer_code 
				LET pa_quotedetl[idx].part_code = pr_quotedetl.part_code 
				LET pa_quotedetl[idx].sold_qty = pr_quotedetl.sold_qty 
				LET pa_quotedetl[idx].bonus_qty = pr_quotedetl.bonus_qty 
				LET pa_quotedetl[idx].disc_per = pr_quotedetl.disc_per 
				LET pa_quotedetl[idx].unit_price_amt = pr_quotedetl.unit_price_amt 
				IF pr_arparms.show_tax_flag = "N" THEN 
					LET pa_quotedetl[idx].line_tot_amt = pr_quotedetl.ext_price_amt 
				ELSE 
					LET pa_quotedetl[idx].line_tot_amt = pr_quotedetl.line_tot_amt 
				END IF 
				CALL disp_total(pr_quotedetl.*) 
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
						INITIALIZE pm_quotedetl.* TO NULL 
						SELECT * INTO pm_quotedetl.* FROM t_quotedetl 
						WHERE line_num = pa_quotedetl[idx].line_num 
						IF pm_quotedetl.line_num IS NULL THEN 
							CALL insert_line() RETURNING pr_quotedetl.* 
							LET pm_quotedetl.* = pr_quotedetl.* 
							INITIALIZE ps_quotedetl.* TO NULL 
							LET pr_part_code = NULL 
							LET pa_quotedetl[idx].line_num = pr_quotedetl.line_num 
							IF idx > 1 THEN 
								LET pa_quotedetl[idx].offer_code 
								= pa_quotedetl[idx-1].offer_code 
							END IF 
							LET pa_quotedetl[idx].sold_qty = 0 
							LET pa_quotedetl[idx].bonus_qty = 0 
							LET pa_quotedetl[idx].disc_per = 0 
							LET pa_quotedetl[idx].unit_price_amt = 0 
							LET pa_quotedetl[idx].line_tot_amt = 0 
						END IF 
					WHEN infield(offer_code) 
						LET pr_temp_text = "offer_code" 
						LET pr_quotedetl.offer_code = get_fldbuf(offer_code) 
						IF length(pr_quotedetl.offer_code) = 0 THEN 
							## get_fldbuf returns spaces instead of nulls
							LET pr_quotedetl.offer_code = NULL 
						END IF 
					WHEN infield(part_code) 
						LET pr_temp_text = "part_code" 
						LET pr_quotedetl.part_code = get_fldbuf(part_code) 
						IF length(pr_quotedetl.part_code) = 0 THEN 
							## get_fldbuf returns spaces instead of nulls
							LET pr_quotedetl.part_code = NULL 
						END IF 
					WHEN infield(sold_qty) 
						LET pr_temp_text = "sold_qty" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET pr_quotedetl.sold_qty = get_fldbuf(sold_qty) 
						WHENEVER ERROR stop 
					WHEN infield(bonus_qty) 
						LET pr_temp_text = "bonus_qty" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET pr_quotedetl.bonus_qty = get_fldbuf(bonus_qty) 
						WHENEVER ERROR stop 
					WHEN infield(disc_per) 
						LET pr_temp_text = "disc_per" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET pr_quotedetl.disc_per = get_fldbuf(disc_per) 
						WHENEVER ERROR stop 
					WHEN infield(unit_price_amt) 
						LET pr_temp_text = "unit_price_amt" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET pr_quotedetl.unit_price_amt = get_fldbuf(unit_price_amt) 
						WHENEVER ERROR stop 
					OTHERWISE 
						LET pr_temp_text = "scroll_flag" 
						SELECT * INTO pr_quotedetl.* FROM t_quotedetl 
						WHERE line_num = pa_quotedetl[idx].line_num 
				END CASE 
				CALL validate_field(pr_temp_text,pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				IF pr_valid_ind THEN 
					IF lineitem_entry(pr_quotedetl.*) THEN 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 
			ON KEY (F2) 
				CASE 
					WHEN infield(scroll_flag) OR 
						pa_quotedetl[idx].part_code IS NULL 
						IF pa_quotedetl[idx].autoinsert_flag IS NOT NULL THEN 
							LET msgresp=kandoomsg("E",9075,"") 
							#9075" Cannot Delete Automatic Inserted Products"
							NEXT FIELD scroll_flag 
						END IF 
						DELETE FROM t_quotedetl 
						WHERE line_num = pa_quotedetl[idx].line_num 
						### shuffle array
						LET j = scrn 
						FOR i = idx TO arr_count() 
							IF i = 500 THEN 
								INITIALIZE pa_quotedetl[500].* TO NULL 
							ELSE 
								LET pa_quotedetl[i].* = pa_quotedetl[i+1].* 
							END IF 
							IF pa_quotedetl[i].line_num = 0 THEN 
								INITIALIZE pa_quotedetl[i].* TO NULL 
							END IF 
							IF j <= 8 THEN 
								DISPLAY pa_quotedetl[i].* TO sr_quotedetl[j].* 

								LET j = j + 1 
							END IF 
						END FOR 
						SELECT * INTO pr_quotedetl.* FROM t_quotedetl 
						WHERE line_num = pa_quotedetl[idx].line_num 
						IF sqlca.sqlcode = notfound THEN 
							INITIALIZE pr_quotedetl.* TO NULL 
						END IF 
						CALL disp_total(pr_quotedetl.*) 
						NEXT FIELD scroll_flag 
				END CASE 
			BEFORE INSERT 
				INITIALIZE pa_quotedetl[idx].* TO NULL 
				INITIALIZE pr_quotedetl.* TO NULL 
				## default offer TO that of the current line
				IF idx < 500 THEN 
					LET pa_quotedetl[idx].offer_code = pa_quotedetl[idx+1].offer_code 
				ELSE 
					LET pa_quotedetl[idx].offer_code = pa_quotedetl[idx-1].offer_code 
				END IF 
				NEXT FIELD line_num 
			AFTER ROW 
				LET int_flag_check = 0 
				IF pa_quotedetl[idx].sold_qty = 0 
				AND pa_quotedetl[idx].bonus_qty = 0 
				AND pa_quotedetl[idx].part_code IS NOT NULL THEN 
					IF int_flag OR quit_flag THEN 
						LET int_flag_check = 1 
					END IF 
					LET msgresp = kandoomsg("E",9242,pa_quotedetl[idx].line_num) 
					#9242 WARNING: Order Line ?? has Zero Quantities
					IF int_flag_check THEN 
						LET int_flag = 1 
					END IF 
				END IF 
				LET pa_quotedetl[idx].scroll_flag = NULL 
				DISPLAY pa_quotedetl[idx].* TO sr_quotedetl[scrn].* 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT infield(scroll_flag) THEN 
						LET int_flag = false 
						LET quit_flag = false 
						IF ps_quotedetl.line_num IS NULL THEN 
							DELETE FROM t_quotedetl 
							WHERE line_num = pa_quotedetl[idx].line_num 
							LET j = scrn 
							FOR i = arr_curr() TO arr_count() 
								IF pa_quotedetl[i+1].line_num IS NOT NULL THEN 
									LET pa_quotedetl[i].* = pa_quotedetl[i+1].* 
								ELSE 
									INITIALIZE pa_quotedetl[i].* TO NULL 
								END IF 
								IF j <= 8 THEN 
									IF pa_quotedetl[i].line_num = 0 THEN 
										LET pa_quotedetl[i].sold_qty = NULL 
									END IF 
									IF pa_quotedetl[i].line_num = 0 THEN 
										LET pa_quotedetl[i].bonus_qty = NULL 
									END IF 
									IF pa_quotedetl[i].line_num = 0 THEN 
										LET pa_quotedetl[i].line_num = NULL 
									END IF 
									DISPLAY pa_quotedetl[i].* TO sr_quotedetl[j].* 

									LET j = j + 1 
								END IF 
							END FOR 
							IF arr_curr() = arr_count() THEN 
								INITIALIZE pa_quotedetl[i].* TO NULL 
							END IF 
							NEXT FIELD scroll_flag 
						ELSE 
							CALL update_line(ps_quotedetl.*) 
							LET pa_quotedetl[idx].offer_code = ps_quotedetl.offer_code 
							LET pa_quotedetl[idx].part_code = ps_quotedetl.part_code 
							LET pa_quotedetl[idx].sold_qty = ps_quotedetl.sold_qty 
							LET pa_quotedetl[idx].bonus_qty = ps_quotedetl.bonus_qty 
							LET pa_quotedetl[idx].disc_per = ps_quotedetl.disc_per 
							LET pa_quotedetl[idx].unit_price_amt = 
							ps_quotedetl.unit_price_amt 
							LET pa_quotedetl[idx].line_tot_amt = 
							ps_quotedetl.line_tot_amt 
						END IF 
						CALL disp_total(ps_quotedetl.*) 
						NEXT FIELD autoinsert_flag 
					ELSE 
						LET msgresp = kandoomsg("E",8045,"") 
						#8045 Abort Order Line Changes
						IF msgresp = "Y" THEN 
							LET pr_int_flag = true 
						ELSE 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
				ELSE 
					IF pr_quotehead.cond_code IS NULL THEN 
						SELECT unique 1 FROM t_quotedetl 
						WHERE offer_code IS NULL 
						AND bonus_qty != 0 
						IF sqlca.sqlcode = 0 THEN 
							LET msgresp=kandoomsg("E",7030,"") 
							#7030 Items NOT part of an condition NOT have bonus
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					DELETE FROM t_quotedetl 
					WHERE part_code IS NULL 
					AND desc_text IS NULL 
					AND acct_code IS NULL 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF fgl_lastkey() = fgl_keyval("F10") THEN 
			IF check_offer() THEN 
			END IF 
		ELSE 
			IF NOT reset_offer THEN 
				EXIT WHILE 
			END IF 
		END IF 
	END WHILE 
	IF int_flag OR quit_flag OR pr_int_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET pr_quotehead.approved_by = NULL 
		LET pr_quotehead.approved_date = NULL 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION insert_line() 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.* 

	LET pr_quotedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_quotedetl.cust_code = pr_quotehead.cust_code 
	LET pr_quotedetl.order_num = pr_quotehead.order_num 
	SELECT max(line_num) INTO pr_quotehead.line_num 
	FROM t_quotedetl 
	IF pr_quotehead.line_num IS NULL THEN 
		LET pr_quotedetl.line_num = 1 
	ELSE 
		LET pr_quotedetl.line_num = pr_quotehead.line_num + 1 
	END IF 
	LET pr_quotedetl.tax_code = pr_quotehead.tax_code 
	IF pr_quotehead.cond_code IS NOT NULL THEN 
		LET pr_quotedetl.level_ind = "L" 
		LET pr_quotedetl.serial_qty = true ## SERIAL used as auto calc disc 
	ELSE 
		LET pr_quotedetl.level_ind = pr_customer.inv_level_ind 
		LET pr_quotedetl.serial_qty = false ## SERIAL used as auto calc disc 
	END IF 
	LET pr_quotedetl.status_ind = "0" 
	LET pr_quotedetl.ware_code = pr_quotehead.ware_code 
	LET pr_quotedetl.cost_ind = permit_backordering(pr_quotedetl.ware_code, 
	pr_quotedetl.part_code, 
	pr_customer.back_order_flag) 
	LET pr_quotedetl.job_code = false ## job code used as disc taken ind 
	LET pr_quotedetl.sold_qty = 0 
	LET pr_quotedetl.bonus_qty = 0 
	LET pr_quotedetl.required_qty = 0 
	LET pr_quotedetl.reserved_qty = 0 
	LET pr_quotedetl.order_qty = 0 
	LET pr_quotedetl.disc_per = 0 
	LET pr_quotedetl.disc_amt = 0 
	LET pr_quotedetl.bonus_disc_amt = 0 
	LET pr_quotedetl.unit_price_amt = 0 
	LET pr_quotedetl.ext_price_amt = 0 
	LET pr_quotedetl.unit_tax_amt = 0 
	LET pr_quotedetl.ext_tax_amt = 0 
	LET pr_quotedetl.unit_cost_amt = 0 
	LET pr_quotedetl.ext_cost_amt = 0 
	LET pr_quotedetl.line_tot_amt = 0 
	LET pr_quotedetl.serial_flag = "N" 
	LET pr_quotedetl.autoinsert_flag = "N" 
	LET pr_quotedetl.pick_flag = "Y" 
	LET pr_quotedetl.trade_in_flag = "N" 
	LET pr_quotedetl.disc_allow_flag = "" 
	LET pr_quotedetl.list_price_amt = 0 
	LET pr_quotedetl.quote_lead_text = glob_rec_qpparms.stockout_lead_text 
	INSERT INTO t_quotedetl VALUES (pr_quotedetl.*) 
	RETURN pr_quotedetl.* 
END FUNCTION 


FUNCTION update_line(pr_quotedetl) 
	## N.B. update_line() IS called with NULL unit_price_amt
	##      WHEN recalculation based on list price OR disc_per
	##      IS required
	## N.B. check FOR NULL prices FOR non-inventory lines, as comment-only lines
	##      can bypass all other price setting/checking code


	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.* 

	CALL update_line_details(
		glob_rec_kandoouser.cmpy_code,
		pr_quotedetl.*, 
		pr_quotehead.*, 
		glob_rec_qpparms.*) 
	RETURNING pr_quotedetl.* 

	UPDATE t_quotedetl 
	SET 
		line_num = pr_quotedetl.line_num, 
		offer_code = pr_quotedetl.offer_code, 
		part_code = pr_quotedetl.part_code, 
		ware_code = pr_quotedetl.ware_code, 
		cat_code = pr_quotedetl.cat_code, 
		order_qty = pr_quotedetl.sold_qty + pr_quotedetl.bonus_qty, 
		prodgrp_code = pr_quotedetl.prodgrp_code, 
		maingrp_code = pr_quotedetl.maingrp_code, 
		acct_code = pr_quotedetl.acct_code, 
		uom_code = pr_quotedetl.uom_code, 
		sold_qty = pr_quotedetl.sold_qty, 
		bonus_qty = pr_quotedetl.bonus_qty, 
		required_qty = pr_quotedetl.required_qty, 
		tax_code = pr_quotedetl.tax_code, 
		unit_tax_amt = pr_quotedetl.unit_tax_amt, 
		ext_tax_amt = pr_quotedetl.ext_tax_amt, 
		unit_price_amt = pr_quotedetl.unit_price_amt, 
		unit_cost_amt = pr_quotedetl.unit_cost_amt, 
		ext_cost_amt = pr_quotedetl.ext_cost_amt, 
		ext_price_amt = pr_quotedetl.ext_price_amt, 
		ext_bonus_amt = pr_quotedetl.ext_bonus_amt, 
		ext_stats_amt = pr_quotedetl.ext_stats_amt, 
		line_tot_amt = pr_quotedetl.line_tot_amt, 
		disc_per = pr_quotedetl.disc_per, 
		disc_amt = pr_quotedetl.disc_amt, 
		job_code = pr_quotedetl.job_code, 
		desc_text = pr_quotedetl.desc_text, 
		level_ind = pr_quotedetl.level_ind, 
		cost_ind = pr_quotedetl.cost_ind, 
		autoinsert_flag = pr_quotedetl.autoinsert_flag, 
		status_ind = pr_quotedetl.status_ind, 
		serial_flag = pr_quotedetl.serial_flag, 
		serial_qty = pr_quotedetl.serial_qty, 
		pick_flag = pr_quotedetl.pick_flag, 
		trade_in_flag = pr_quotedetl.trade_in_flag, 
		disc_allow_flag = pr_quotedetl.disc_allow_flag, 
		list_price_amt = pr_quotedetl.list_price_amt, 
		quote_lead_text = pr_quotedetl.quote_lead_text, 
		quote_lead_text2 = pr_quotedetl.quote_lead_text2, 
		reserved_qty = pr_quotedetl.reserved_qty, 
		margin_ind = pr_quotedetl.margin_ind 
	WHERE line_num = pr_quotedetl.line_num 
END FUNCTION 



FUNCTION disp_total(pr_quotedetl) 
	DEFINE 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	px_quotedetl RECORD LIKE quotedetl.*, 
	pr_desc_text CHAR(30), 
	scrn SMALLINT 

	### DISPLAY Current Line Info
	LET scrn = scr_line() 
	IF pr_arparms.show_tax_flag = "N" THEN 
		LET pr_quotedetl.line_tot_amt = pr_quotedetl.ext_price_amt 
	END IF 
	IF pr_quotedetl.autoinsert_flag = "Y" THEN 
		LET pr_quotedetl.autoinsert_flag = "*" 
	ELSE 
		LET pr_quotedetl.autoinsert_flag = "" 
	END IF 
	DISPLAY "",pr_quotedetl.line_num, 
	pr_quotedetl.offer_code, 
	pr_quotedetl.part_code, 
	pr_quotedetl.sold_qty, 
	pr_quotedetl.bonus_qty, 
	pr_quotedetl.disc_per, 
	pr_quotedetl.unit_price_amt, 
	pr_quotedetl.line_tot_amt, 
	pr_quotedetl.autoinsert_flag 
	TO sr_quotedetl[scrn].* 

	### DISPLAY Totals & Line Info
	SELECT sum(ext_price_amt), 
	sum(ext_tax_amt) 
	INTO pr_quotehead.goods_amt, 
	pr_quotehead.tax_amt 
	FROM t_quotedetl 
	LET pr_quotehead.total_amt = pr_quotehead.goods_amt 
	+ pr_quotehead.tax_amt 
	LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
	- pr_customer.bal_amt 
	- pr_customer.onorder_amt 
	- pr_quotehead.total_amt 
	+ pr_currord_amt 
	DISPLAY BY NAME pr_customer.cred_bal_amt, 
	pr_quotehead.goods_amt, 
	pr_quotehead.tax_amt, 
	pr_quotehead.total_amt 
	attribute(yellow) 
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_quotedetl.part_code 
	AND ware_code = pr_quotedetl.ware_code 
	IF status = notfound THEN 
		LET px_quotedetl.required_qty = 0 
	ELSE 
		IF pr_prodstatus.stocked_flag = "Y" THEN 
			IF glob_rec_opparms.cal_available_flag = "N" THEN 
				LET px_quotedetl.required_qty = pr_prodstatus.onhand_qty 
				- pr_prodstatus.reserved_qty 
				- pr_quotedetl.reserved_qty 
				- pr_prodstatus.back_qty 
			ELSE 
				LET px_quotedetl.required_qty = pr_prodstatus.onhand_qty 
				- pr_quotedetl.reserved_qty 
				- pr_prodstatus.reserved_qty 
			END IF 
		END IF 
	END IF 
	DISPLAY BY NAME px_quotedetl.required_qty 
	attribute(yellow) 
	DISPLAY BY NAME pr_quotedetl.desc_text, 
	pr_quotedetl.tax_code, 
	pr_quotedetl.ware_code, 
	pr_quotedetl.status_ind, 
	pr_quotedetl.disc_allow_flag, 
	pr_quotedetl.level_ind, 
	pr_quotedetl.quote_lead_text, 
	pr_quotedetl.quote_lead_text2, 
	pr_quotedetl.margin_ind 

	IF pr_quotedetl.offer_code IS NULL THEN 
		CLEAR offersale.desc_text 
	ELSE 
		SELECT desc_text INTO pr_desc_text FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = pr_quotedetl.offer_code 
		DISPLAY pr_desc_text TO offersale.desc_text 

	END IF 
	WHENEVER ERROR CONTINUE 
	IF pr_quotedetl.tax_code IS NULL THEN 
		CLEAR tax.desc_text 
	ELSE 
		SELECT desc_text INTO pr_desc_text FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = pr_quotedetl.tax_code 
		DISPLAY pr_desc_text TO tax.desc_text 

	END IF 
	WHENEVER ERROR stop 
END FUNCTION 


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
	AND y.ware_code = pr_quotehead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = notfound THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.alter_part_code = pr_alt_part_code 
		AND x.part_code <> pr_part_code 
		AND x.part_code = y.part_code 
		AND y.ware_code = pr_quotehead.ware_code 
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
	pr_available LIKE prodstatus.onhand_qty, 
	pa_product array[50] OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		available LIKE prodstatus.onhand_qty 
	END RECORD, 
	idx, scrn SMALLINT 

	SELECT x.* INTO pr_product.* 
	FROM product x, prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = pr_alt_part_code 
	AND x.part_code = y.part_code 
	AND x.part_code != pr_part_code 
	AND y.ware_code = pr_quotehead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = notfound THEN 
		OPEN WINDOW n131 with FORM "N131" -- alch kd-747 
		CALL winDecoration_n("N131") -- alch kd-747 
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
		AND y.ware_code = pr_quotehead.ware_code 
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
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET msgresp=kandoomsg("U",1019,"") 
		#U1019 Press OK TO...
		INPUT ARRAY pa_product WITHOUT DEFAULTS FROM sr_product.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","Q11c","inp_arr-pa_product-1") -- alch kd-501 
			ON ACTION "WEB-HELP" -- albo kd-369 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				DISPLAY pa_product[idx].* TO sr_product[scrn].* 

			AFTER ROW 
				DISPLAY pa_product[idx].* TO sr_product[scrn].* 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND pa_product[idx+1].part_code IS NULL THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#U9001 No more rows in the direction you are going"
					NEXT FIELD scroll_flag 
				END IF 
				LET pr_product.part_code = pa_product[idx].part_code 
			BEFORE FIELD part_code 
				NEXT FIELD scroll_flag 
			AFTER INPUT 
				LET idx = arr_curr() 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		CLOSE WINDOW n131 
	END IF 
	IF int_flag OR quit_flag THEN 
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
	AND ware_code = pr_quotehead.ware_code 
	AND (onhand_qty - reserved_qty - back_qty ) > 0 
	IF status = notfound THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.cmpy_code = y.cmpy_code 
		AND y.ware_code = pr_quotehead.ware_code 
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
	OPEN WINDOW n132 with FORM "N132" -- alch kd-747 
	CALL winDecoration_n("N132") -- alch kd-747 
	DECLARE c2_prodstatus CURSOR FOR 
	SELECT x.part_code, 
	x.desc_text, 
	(y.onhand_qty - y.reserved_qty - y.back_qty) 
	FROM product x, 
	prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.cmpy_code = y.cmpy_code 
	AND y.ware_code = pr_quotehead.ware_code 
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
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11c","inp_arr-pa_product-2") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
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


FUNCTION get_lead(pr_quotedetl) 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_total_available LIKE prodstatus.onhand_qty, 
	pr_available LIKE prodstatus.onhand_qty, 
	pr_lead1 LIKE quotedetl.quote_lead_text, 
	pr_lead2 LIKE quotedetl.quote_lead_text, 
	pr_desc_text LIKE warehouse.desc_text, 
	pr_quotelead RECORD LIKE quotelead.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.* 

	LET pr_quotedetl.order_qty = pr_quotedetl.sold_qty 
	+ pr_quotedetl.bonus_qty 
	LET pr_lead1 = glob_rec_qpparms.stockout_lead_text 
	LET pr_lead2 = NULL 
	IF pr_quotedetl.part_code IS NULL THEN 
		RETURN pr_lead1, pr_lead2 
	END IF 
	#Does it exist AT ANY warehouse?
	SELECT unique 1 FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_quotedetl.part_code 
	IF status = notfound THEN 
		RETURN pr_lead1, pr_lead2 
	END IF 
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_quotedetl.part_code 
	AND ware_code = pr_quotedetl.ware_code 
	IF status = notfound THEN 
		LET pr_total_available = calc_other_avail(pr_quotedetl.*) 
		IF pr_total_available > 0 THEN 
			IF pr_quotedetl.order_qty <= pr_total_available THEN 
				LET pr_lead1 = pr_quotedetl.order_qty USING "-<<<<&.&"," ", 
				glob_rec_qpparms.quote_lead_text 
			ELSE 
				LET pr_lead1 = pr_total_available USING "-<<<<&.&"," ", 
				glob_rec_qpparms.quote_lead_text 
				LET pr_lead2 = glob_rec_qpparms.quote_lead_text2," ", 
				glob_rec_qpparms.stockout_lead_text 
			END IF 
		END IF 
		RETURN pr_lead1, pr_lead2 
	END IF 
	# working with default warehouse now
	IF pr_prodstatus.stocked_flag = "N" THEN 
		RETURN pr_lead1, pr_lead2 
	END IF 
	LET pr_available = calc_avail(pr_quotedetl.*,false) 
	IF pr_available <= 0 THEN 
		LET pr_total_available = calc_other_avail(pr_quotedetl.*) 
		IF pr_total_available > 0 THEN 
			IF pr_quotedetl.order_qty <= pr_total_available THEN 
				LET pr_lead1 = pr_quotedetl.order_qty USING "-<<<<&.&"," ", 
				glob_rec_qpparms.quote_lead_text 
			ELSE 
				LET pr_lead1 = pr_total_available USING "-<<<<&.&"," ", 
				glob_rec_qpparms.quote_lead_text 
				LET pr_lead2 = glob_rec_qpparms.quote_lead_text2 clipped," ", 
				glob_rec_qpparms.stockout_lead_text 
			END IF 
		END IF 
		RETURN pr_lead1, pr_lead2 
	END IF 
	# working with default warehouse AND available > 0
	LET pr_desc_text = NULL 
	SELECT desc_text INTO pr_desc_text FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_quotedetl.ware_code 
	IF pr_quotedetl.order_qty <= pr_available THEN 
		LET pr_lead1 = pr_quotedetl.order_qty USING "-<<<<&.&"," ", 
		glob_rec_qpparms.quote_lead_text clipped," ", 
		pr_desc_text 
		RETURN pr_lead1, pr_lead2 
	END IF 
	# Ordered more than available
	LET pr_total_available = calc_other_avail(pr_quotedetl.*) 
	IF pr_total_available <= 0 THEN 
		LET pr_lead1 = pr_available USING "-<<<<&.&"," ", 
		glob_rec_qpparms.quote_lead_text clipped," ", 
		pr_desc_text 
		LET pr_lead2 = glob_rec_qpparms.quote_lead_text2," ", 
		glob_rec_qpparms.stockout_lead_text 
		RETURN pr_lead1, pr_lead2 
	ELSE 
		IF (pr_quotedetl.order_qty - pr_available) <= pr_total_available THEN 
			LET pr_lead1 = pr_available USING "-<<<<&.&"," ", 
			glob_rec_qpparms.quote_lead_text," ", 
			pr_desc_text 
			LET pr_lead2 = pr_quotedetl.order_qty - pr_available USING "-<<<<&.&", 
			" ",glob_rec_qpparms.quote_lead_text 
		ELSE 
			LET pr_lead1 = pr_available USING "-<<<<&.&"," ", 
			glob_rec_qpparms.quote_lead_text," ", 
			pr_desc_text 
			LET pr_lead2 = pr_total_available USING "-<<<<&.&"," ", 
			glob_rec_qpparms.quote_lead_text clipped," ", 
			glob_rec_qpparms.stockout_lead_text 
		END IF 
	END IF 
	RETURN pr_lead1, pr_lead2 
END FUNCTION 


FUNCTION image_quotelines() 
	DEFINE 
	pr_quote_text CHAR(8), 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pt_quotedetl RECORD LIKE quotedetl.*, 
	pn_quotehead RECORD LIKE quotehead.* 

	OPEN WINDOW q224 with FORM "Q224" -- alch kd-747 
	CALL windecoration_q("Q224") -- alch kd-747 
	INPUT BY NAME pn_quotehead.order_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11c","inp-order_num-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD order_num 
			IF pn_quotehead.order_num IS NULL THEN 
				LET msgresp = kandoomsg("Q",9095,"") 
				#9095 Quote must be entered
				NEXT FIELD order_num 
			ELSE 
				SELECT * FROM quotehead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pn_quotehead.order_num 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("Q",9094,"") 
					#9094 Quote does NOT exist. Cannot image
					NEXT FIELD order_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW q224 
		RETURN false 
	END IF 
	DECLARE c_quotedetl CURSOR FOR 
	SELECT * FROM quotedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = pn_quotehead.order_num 
	FOREACH c_quotedetl INTO pr_quotedetl.* 
		LET pr_quotedetl.offer_code = NULL 
		LET pr_quotedetl.autoinsert_flag = "N" 
		CALL insert_line() RETURNING pt_quotedetl.* 
		LET pr_quotedetl.line_num = pt_quotedetl.line_num 
		LET pr_quotedetl.unit_price_amt = NULL 
		CALL update_line(pr_quotedetl.*) 
	END FOREACH 
	CLOSE WINDOW q224 
	RETURN true 
END FUNCTION 


FUNCTION calc_other_avail(pr_quotedetl) 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_cur_avail_qty, 
	pr_back_qty, 
	pr_onhand_qty, 
	pr_reserved_qty LIKE prodstatus.reserved_qty 

	SELECT sum(back_qty), sum(onhand_qty), sum(reserved_qty) 
	INTO pr_back_qty, pr_onhand_qty, pr_reserved_qty 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_quotedetl.part_code 
	AND ware_code != pr_quotedetl.ware_code 
	IF pr_back_qty IS NULL THEN 
		LET pr_back_qty = 0 
	END IF 
	IF pr_onhand_qty IS NULL THEN 
		LET pr_onhand_qty = 0 
	END IF 
	IF pr_reserved_qty IS NULL THEN 
		LET pr_reserved_qty = 0 
	END IF 
	IF glob_rec_opparms.cal_available_flag = "N" THEN 
		LET pr_cur_avail_qty = pr_onhand_qty 
		- pr_reserved_qty 
		- pr_back_qty 
	ELSE 
		LET pr_cur_avail_qty = pr_onhand_qty 
		- pr_reserved_qty 
	END IF 
	RETURN pr_cur_avail_qty 
END FUNCTION 
