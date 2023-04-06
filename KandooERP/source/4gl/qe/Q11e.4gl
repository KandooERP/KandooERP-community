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
# \brief module Q11e -  Line Item Detailed Entry

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

DEFINE 
pr_prodstatus RECORD LIKE prodstatus.*, 
pr_error_ind INTEGER 

FUNCTION lineitem_entry(pr_quotedetl) 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	ps_quotedetl RECORD LIKE quotedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_tmp_part_code LIKE quotedetl.part_code, 
	pr_tmp_sold_qty LIKE quotedetl.sold_qty, 
	pr_tmp_bonus_qty LIKE quotedetl.bonus_qty, 
	pr_temp_amt FLOAT, 
	pr_valid_ind SMALLINT, 
	i,j SMALLINT 

	LET ps_quotedetl.* = pr_quotedetl.* 
	## take copy of RECORD TO reinstate in CASE of back out
	OPEN WINDOW q215 with FORM "Q215" -- alch kd-747 
	CALL windecoration_q("Q215") -- alch kd-747 
	LET msgresp=kandoomsg("E",1026,"") 
	#1026 F5 Cust Inquiry - F8 Product Inquiry - ESC TO Continue
	CALL display_line(pr_quotedetl.*) 
	LET pr_quotedetl.required_qty = calc_avail(pr_quotedetl.*,true) 
	INPUT BY NAME pr_quotedetl.part_code, 
	pr_quotedetl.desc_text, 
	pr_quotedetl.sold_qty, 
	pr_quotedetl.bonus_qty, 
	pr_quotedetl.order_qty, 
	pr_quotedetl.reserved_qty, 
	pr_quotedetl.quote_lead_text, 
	pr_quotedetl.level_ind, 
	pr_quotedetl.disc_allow_flag, 
	pr_quotedetl.disc_per, 
	pr_quotedetl.unit_price_amt, 
	pr_quotedetl.unit_tax_amt WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11e","inp-part_code-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (control-b) 
			IF infield(part_code) THEN 
				LET pr_temp_text= "status_ind!='3' AND part_code =", 
				"(SELECT part_code FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND ware_code='",pr_quotedetl.ware_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND status_ind!='3')" 
				IF pr_quotedetl.offer_code IS NOT NULL THEN 
					LET pr_temp_text=pr_temp_text clipped," AND exists ", 
					"(SELECT 1 FROM offerprod ", 
					"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND offer_code='",pr_quotedetl.offer_code,"' ", 
					"AND maingrp_code=product.maingrp_code ", 
					"AND (prodgrp_code =product.prodgrp_code ", 
					"OR prodgrp_code IS NULL)", 
					"AND (part_code =product.part_code ", 
					"OR part_code IS NULL))" 
				END IF 
				LET pr_temp_text = show_part(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_quotedetl.part_code = pr_temp_text 
					NEXT FIELD part_code 
				END IF 
			END IF 
		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				OPTIONS DELETE KEY f2 
				LET pr_quotedetl.desc_text = 
				sys_noter(glob_rec_kandoouser.cmpy_code,pr_quotedetl.desc_text) 
				OPTIONS DELETE KEY f36 
				NEXT FIELD desc_text 

		ON KEY (control-p) 
			CALL dispgpfunc(pr_quotehead.currency_code, 
			pr_quotedetl.ext_cost_amt, 
			pr_quotedetl.ext_price_amt) 

		ON KEY (F5) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,pr_quotehead.cust_code) --customer details / customer invoice submenu 

		ON KEY (F8) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code) 

		BEFORE FIELD part_code 
			IF pr_quotedetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				NEXT FIELD NEXT 
			END IF 
			LET pr_tmp_part_code = pr_quotedetl.part_code 

		AFTER FIELD part_code 
			IF pr_quotedetl.part_code IS NULL THEN 
				IF ps_quotedetl.part_code IS NOT NULL THEN 
					LET pr_quotedetl.acct_code = NULL 
				END IF 
				LET pr_quotedetl.status_ind = "3" 
				LET pr_quotedetl.cost_ind = "N" 
				LET pr_quotedetl.offer_code = NULL 
				LET pr_quotedetl.trade_in_flag = "N" 
				LET pr_quotedetl.required_qty=calc_avail(pr_quotedetl.*,true) 
			ELSE 
				IF ps_quotedetl.part_code IS NULL THEN 
					LET pr_quotedetl.status_ind = "0" 
					DISPLAY BY NAME pr_quotedetl.status_ind 

				ELSE 
					## force change of lineinfo on change of partcode
					IF ps_quotedetl.part_code != pr_quotedetl.part_code THEN 
						LET pr_quotedetl.order_qty = 0 
						LET pr_quotedetl.sold_qty = 0 
						LET pr_quotedetl.bonus_qty = 0 
						LET pr_quotedetl.unit_price_amt = 0 
						LET pr_quotedetl.desc_text = NULL 
					END IF 
				END IF 
				CALL validate_field("part_code",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				IF NOT pr_valid_ind THEN 
					NEXT FIELD part_code 
				ELSE 
					LET pr_quotedetl.required_qty = calc_avail(pr_quotedetl.*,true) 
				END IF 
			END IF 
			IF pr_quotedetl.part_code IS NULL 
			OR pr_quotedetl.part_code != pr_tmp_part_code THEN 
				CALL get_lead(pr_quotedetl.*) 
				RETURNING pr_quotedetl.quote_lead_text, 
				pr_quotedetl.quote_lead_text2 
			END IF 
		BEFORE FIELD desc_text 
			IF pr_quotedetl.part_code IS NOT NULL 
			AND NOT (pr_quotedetl.desc_text[1,3] = "###" 
			AND pr_quotedetl.desc_text[16,18] = "###") THEN 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_quotedetl.part_code 
				IF status = 0 THEN 
					LET pr_quotedetl.desc_text = pr_product.desc_text 
				END IF 
			END IF 
			CALL display_line(pr_quotedetl.*) 
		BEFORE FIELD sold_qty 
			IF pr_quotedetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
			LET pr_tmp_sold_qty = pr_quotedetl.sold_qty 
		AFTER FIELD sold_qty 
			CALL validate_field("sold_qty",pr_quotedetl.*) 
			RETURNING pr_valid_ind,pr_quotedetl.* 
			IF NOT pr_valid_ind THEN 
				NEXT FIELD sold_qty 
			END IF 
			IF pr_quotedetl.sold_qty != pr_tmp_sold_qty THEN 
				CALL get_lead(pr_quotedetl.*) 
				RETURNING pr_quotedetl.quote_lead_text, 
				pr_quotedetl.quote_lead_text2 
			END IF 
			LET pr_quotedetl.required_qty=calc_avail(pr_quotedetl.*,true) 
			CALL display_line(pr_quotedetl.*) 
		BEFORE FIELD bonus_qty 
			IF pr_quotehead.cond_code IS NULL 
			AND pr_quotedetl.offer_code IS NULL THEN 
				LET pr_quotedetl.bonus_qty = 0 
				LET pr_product.bonus_allow_flag = "N" 
			END IF 
			IF pr_quotedetl.autoinsert_flag = "Y" THEN ## auto INSERT 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				IF pr_quotedetl.status_ind = "3" ## non-inventory 
				OR pr_quotedetl.trade_in_flag = "Y" ## trade-ins 
				OR pr_product.bonus_allow_flag = "N" THEN ## no bonus 
					LET pr_quotedetl.bonus_qty = 0 
					IF fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			END IF 
			LET pr_tmp_bonus_qty = pr_quotedetl.bonus_qty 
		AFTER FIELD bonus_qty 
			CALL validate_field("bonus_qty",pr_quotedetl.*) 
			RETURNING pr_valid_ind,pr_quotedetl.* 
			IF NOT pr_valid_ind THEN 
				NEXT FIELD bonus_qty 
			END IF 
			IF pr_quotedetl.bonus_qty != pr_tmp_bonus_qty THEN 
				CALL get_lead(pr_quotedetl.*) 
				RETURNING pr_quotedetl.quote_lead_text, 
				pr_quotedetl.quote_lead_text2 
			END IF 
			CALL display_line(pr_quotedetl.*) 
			LET pr_quotedetl.required_qty=calc_avail(pr_quotedetl.*,true) 
		BEFORE FIELD order_qty 
			IF pr_quotedetl.status_ind != "3" 
			AND pr_quotedetl.status_ind != "1" THEN 
				## Prompt TO sellup
				IF pr_product.stock_uom_code != pr_product.sell_uom_code 
				AND pr_product.stk_sel_con_qty > 1 THEN 
					LET i =(pr_quotedetl.order_qty/pr_product.stk_sel_con_qty)+0.5 
					LET j =(i * pr_product.stk_sel_con_qty) 
					IF pr_quotedetl.order_qty < j 
					AND pr_quotedetl.order_qty > (glob_rec_opparms.sellup_per/100)*j THEN 
						LET msgresp = kandoomsg("E",8014,j) 
						IF msgresp = "Y" THEN 
							LET pr_quotedetl.sold_qty = pr_quotedetl.sold_qty + j 
							- pr_quotedetl.order_qty 
							NEXT FIELD sold_qty 
						END IF 
					END IF 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left") THEN 
				NEXT FIELD previous 
			ELSE 
				NEXT FIELD NEXT 
			END IF 
		BEFORE FIELD reserved_qty 
			IF pr_quotedetl.status_ind = "3" ## non-inventory 
			OR pr_quotedetl.trade_in_flag = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD reserved_qty 
			CALL validate_field("reserved_qty",pr_quotedetl.*) 
			RETURNING pr_valid_ind,pr_quotedetl.* 
			IF pr_valid_ind THEN 
				CALL display_line(pr_quotedetl.*) 
			ELSE 
				CALL display_line(pr_quotedetl.*) 
				NEXT FIELD reserved_qty 
			END IF 
		BEFORE FIELD level_ind 
			LET pr_quotedetl.required_qty = calc_avail(pr_quotedetl.*,true) 
			IF pr_quotehead.cond_code IS NULL 
			AND pr_quotedetl.offer_code IS NULL 
			AND pr_quotedetl.trade_in_flag = "N" 
			AND pr_quotedetl.part_code IS NOT NULL THEN 
				LET pr_temp_text = pr_quotedetl.level_ind 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD level_ind 
			IF pr_quotedetl.level_ind IS NULL THEN 
				LET pr_quotedetl.level_ind = pr_customer.inv_level_ind 
				NEXT FIELD level_ind 
			END IF 
			IF pr_quotedetl.level_ind != pr_temp_text clipped THEN 
				LET pr_quotedetl.unit_price_amt = 
				unit_price(pr_quotedetl.ware_code, 
				pr_quotedetl.part_code, 
				pr_quotedetl.level_ind) 
				CALL validate_field("unit_price_amt",pr_quotedetl.*) 
				RETURNING pr_valid_ind,pr_quotedetl.* 
				IF pr_valid_ind THEN 
					CALL display_line(pr_quotedetl.*) 
				ELSE 
					NEXT FIELD unit_price_amt 
				END IF 
			END IF 
			CALL display_line(pr_quotedetl.*) 
		BEFORE FIELD disc_per 
			IF pr_quotedetl.offer_code IS NOT NULL 
			OR pr_quotedetl.disc_allow_flag = no_flag 
			OR pr_quotedetl.trade_in_flag = "Y" 
			OR pr_quotedetl.status_ind = "3" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD disc_per 
			CALL validate_field("disc_per",pr_quotedetl.*) 
			RETURNING pr_valid_ind,pr_quotedetl.* 
			IF pr_valid_ind THEN 
				CALL display_line(pr_quotedetl.*) 
			ELSE 
				NEXT FIELD disc_per 
			END IF 
		BEFORE FIELD unit_price_amt 
			IF pr_quotedetl.offer_code IS NOT NULL 
			OR pr_quotedetl.disc_allow_flag = no_flag THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
		AFTER FIELD unit_price_amt 
			CALL validate_field("unit_price_amt",pr_quotedetl.*) 
			RETURNING pr_valid_ind,pr_quotedetl.* 
			IF pr_valid_ind THEN 
				CALL display_line(pr_quotedetl.*) 
			ELSE 
				NEXT FIELD unit_price_amt 
			END IF 
		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF pr_quotedetl.status_ind = "3" 
				AND pr_quotedetl.line_tot_amt > 0 
				AND pr_quotedetl.part_code IS NULL THEN 
					LET pr_quotedetl.acct_code = enter_acct(pr_quotedetl.acct_code) 
					IF pr_quotedetl.acct_code IS NULL THEN 
						NEXT FIELD part_code 
					END IF 
				ELSE 
					CALL validate_field("sold_qty",pr_quotedetl.*) 
					RETURNING pr_valid_ind,pr_quotedetl.* 
					IF NOT pr_valid_ind THEN 
						NEXT FIELD sold_qty 
					END IF 
					IF fgl_lastkey() != fgl_keyval("accept") THEN 
						IF kandoomsg("E",8006,"") = "N" THEN 
							#8006 Line Entry Complete. (Y/N)?
							NEXT FIELD part_code 
						END IF 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW q215 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CALL update_line(ps_quotedetl.*) 
		RETURN false 
	ELSE 
		CALL update_line(pr_quotedetl.*) 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION display_line(pr_quotedetl) 
	DEFINE 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_disc_flag CHAR(1) ### auto-dosc calc true/false 

	DISPLAY BY NAME pr_quotehead.currency_code 
	attribute(green) 
	## mod of disc_per excludes line FROM autodisc calc
	IF pr_quotedetl.serial_qty THEN 
		LET pr_disc_flag = "*" 
	ELSE 
		LET pr_disc_flag = NULL 
	END IF 
	DISPLAY BY NAME pr_quotedetl.part_code, 
	pr_quotedetl.desc_text, 
	pr_quotedetl.status_ind, 
	pr_quotedetl.uom_code, 
	pr_quotedetl.sold_qty, 
	pr_quotedetl.bonus_qty, 
	pr_quotedetl.order_qty, 
	pr_quotedetl.reserved_qty, 
	pr_quotedetl.disc_allow_flag, 
	pr_disc_flag, 
	pr_quotedetl.level_ind, 
	pr_quotedetl.disc_per, 
	pr_quotedetl.list_price_amt, 
	pr_quotedetl.unit_price_amt, 
	pr_quotedetl.ext_price_amt, 
	pr_quotedetl.unit_tax_amt, 
	pr_quotedetl.ext_tax_amt, 
	pr_quotedetl.line_tot_amt, 
	pr_quotedetl.quote_lead_text, 
	pr_quotedetl.margin_ind 

END FUNCTION 


FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind) 
	DEFINE 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_part_code LIKE prodstatus.part_code, 
	pr_level_ind LIKE customer.inv_level_ind, 
	pr_price_amt LIKE quotedetl.unit_price_amt, 
	rate_per FLOAT 


	IF pr_quotehead.currency_code = pr_globals.base_curr_code THEN 
		LET rate_per = 1 
	ELSE 
		LET rate_per = get_conv_rate(
			glob_rec_kandoouser.cmpy_code,
			pr_quotehead.currency_code, 
			pr_quotehead.quote_date,
			CASH_EXCHANGE_SELL) 
	END IF 
	CALL prod_price(
		glob_rec_kandoouser.cmpy_code,
		pr_part_code,
		pr_customer.cust_code, 
		pr_ware_code,
		1,
		today) 
	RETURNING pr_price_amt,pr_error_ind 
	
	IF pr_price_amt = 0 THEN 
		CALL prod_price(glob_rec_kandoouser.cmpy_code,pr_part_code,pr_customer.cust_code, 
		pr_ware_code,2,today) 
		RETURNING pr_price_amt,pr_error_ind 
		IF pr_price_amt <> 0 THEN 
			RETURN (pr_price_amt * rate_per) 
		END IF 
	ELSE 
		RETURN (pr_price_amt * rate_per) 
	END IF 
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_ware_code 
	AND part_code = pr_part_code 
	IF sqlca.sqlcode = notfound THEN 
		RETURN 0 
	ELSE 
		CASE 
			WHEN pr_level_ind = "1" RETURN (pr_prodstatus.price1_amt*rate_per) 
			WHEN pr_level_ind = "2" RETURN (pr_prodstatus.price2_amt*rate_per) 
			WHEN pr_level_ind = "3" RETURN (pr_prodstatus.price3_amt*rate_per) 
			WHEN pr_level_ind = "4" RETURN (pr_prodstatus.price4_amt*rate_per) 
			WHEN pr_level_ind = "5" RETURN (pr_prodstatus.price5_amt*rate_per) 
			WHEN pr_level_ind = "6" RETURN (pr_prodstatus.price6_amt*rate_per) 
			WHEN pr_level_ind = "7" RETURN (pr_prodstatus.price7_amt*rate_per) 
			WHEN pr_level_ind = "8" RETURN (pr_prodstatus.price8_amt*rate_per) 
			WHEN pr_level_ind = "9" RETURN (pr_prodstatus.price9_amt*rate_per) 
			WHEN pr_level_ind = "L" RETURN (pr_prodstatus.list_amt*rate_per) 
			WHEN pr_level_ind = "C" RETURN (pr_prodstatus.wgted_cost_amt*rate_per) 
			OTHERWISE RETURN (pr_prodstatus.list_amt*rate_per) 
		END CASE 
	END IF 
END FUNCTION 


FUNCTION enter_acct(pr_acct_code) 
	DEFINE 
	pr_acct_code LIKE quotedetl.acct_code, 
	pr_coa RECORD LIKE coa.* 

	LET pr_coa.acct_code = pr_acct_code 
	OPEN WINDOW A672 with FORM "A672" -- alch kd-747 
	CALL winDecoration_a("A672") -- alch kd-747 
	LET msgresp=kandoomsg("E",1025,"") 
	#1025 Enter G.L. Account - ESC TO Continue
	INPUT BY NAME pr_coa.acct_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","Q11e","inp-acct_code-1") -- alch kd-501 
		ON ACTION "WEB-HELP" -- albo kd-369 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (control-b) 
			LET pr_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL 
			AND pr_temp_text != " " THEN 
				LET pr_coa.acct_code = pr_temp_text 
			END IF 
			NEXT FIELD acct_code 
		AFTER FIELD acct_code 
			IF pr_coa.acct_code IS NULL THEN 
				LET msgresp = kandoomsg("E",9077,"") 
				#9077" Account Code IS required FOR Non-Inventory Lines"
				NEXT FIELD acct_code 
			ELSE 
				SELECT unique 1 FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = pr_coa.acct_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("E",9078,"") 
					#9078" Invoice Line Account code NOT found"
					NEXT FIELD acct_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW A672 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN pr_acct_code 
	ELSE 
		RETURN pr_coa.acct_code 
	END IF 
END FUNCTION 


FUNCTION validate_field(pr_field_name,pr_quotedetl) 
	##
	## Common validation routines are NOT usual in max but has
	## been included here TO avoid gross duplication of code
	## This FUNCTION now uses validation based on whether the line
	## IS being added OR editted.
	##
	DEFINE 
	pr_field_name CHAR(15), 
	ps_quotedetl, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pt_quotedetl RECORD LIKE quotedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_disc_per LIKE quotedetl.disc_per, 
	pr_unit_price_amt LIKE quotedetl.unit_price_amt, 
	pr_status INTEGER, 
	pr_future_available, 
	pr_available LIKE prodstatus.onhand_qty, 
	pr_part_code LIKE orderline.part_code, 
	pr_msg CHAR(60), 
	pr_super_ind, 
	pr_valid_ind, 
	i, idx SMALLINT 

	SELECT * INTO ps_quotedetl.* 
	FROM t_quotedetl 
	WHERE line_num = pr_quotedetl.line_num 
	CASE 
		WHEN pr_field_name = "offer_code" 
			IF pr_quotedetl.offer_code IS NOT NULL THEN 
				SELECT unique 1 FROM offersale 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND offer_code = pr_quotedetl.offer_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9070,"") 
					#9070 Special Offer code does NOT exist - Try Window"
					RETURN false, pr_quotedetl.* 
				END IF 
				SELECT unique 1 FROM t_orderpart 
				WHERE offer_code = pr_quotedetl.offer_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("E",9072,"") 
					#9072 offer code NOT nominated FOR this sales ORDER"
					RETURN false, pr_quotedetl.* 
				END IF 
				IF pr_quotedetl.part_code IS NOT NULL THEN 
					CALL validate_field("part_code",pr_quotedetl.*) 
					RETURNING idx,pr_quotedetl.* 
					IF idx = 0 THEN 
						RETURN false,pr_quotedetl.* 
					END IF 
				END IF 
				LET pr_quotedetl.level_ind = "L" 
			END IF 
		WHEN pr_field_name = "part_code" 
			IF ps_quotedetl.part_code IS NULL 
			OR ps_quotedetl.part_code != pr_quotedetl.part_code THEN 
				SELECT unique 1 FROM product 
				WHERE part_code = pr_quotedetl.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					IF pr_quotedetl.part_code IS NOT NULL THEN 
						LET msgresp = kandoomsg("Q",8015,"") 
						IF msgresp = "N" THEN 
							RETURN false,pr_quotedetl.* 
						END IF 
					END IF 
					EXIT CASE 
				END IF 
				SELECT unique 1 FROM prodstatus 
				WHERE part_code = pr_quotedetl.part_code 
				AND ware_code = pr_quotehead.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					EXIT CASE 
				END IF 
				#### Check FOR exclusions
				IF pr_quotedetl.part_code IS NOT NULL THEN 
					IF prod_exclude(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
					pr_customer.cust_code, 
					pr_quotedetl.ware_code, 
					5, 
					today) THEN 
						LET msgresp=kandoomsg("E",9261,"") 
						#9261" product can NOT be sold
						RETURN false,pr_quotedetl.* 
					END IF 
					IF prod_exclude(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
					pr_customer.cust_code, 
					pr_quotedetl.ware_code, 
					6, 
					today) THEN 
						LET msgresp=kandoomsg("E",9261,"") 
						#9261" product can NOT be sold
						RETURN false,pr_quotedetl.* 
					END IF 
				END IF 
				IF pr_quotedetl.part_code IS NOT NULL THEN 
					LET pr_super_ind = false 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_quotedetl.part_code 
					IF pr_product.super_part_code IS NOT NULL THEN 
						LET idx = 0 
						WHILE pr_product.super_part_code IS NOT NULL 
							LET idx = idx + 1 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_product.super_part_code, 
							pr_quotedetl.ware_code, 
							0,2,0,"","","") THEN 
								LET msgresp = kandoomsg("E",9263,"") 
								#9263 Product has been superseded with an invalid part
								LET pr_quotedetl.part_code = NULL 
								LET pr_quotedetl.desc_text = NULL 
								RETURN false,pr_quotedetl.* 
							END IF 
							IF get_kandoooption_feature_state("EO","SP") THEN 
								LET pr_future_available = 0 
								SELECT onhand_qty - reserved_qty - back_qty + onord_qty 
								INTO pr_future_available FROM prodstatus 
								WHERE part_code = pr_product.part_code 
								AND ware_code = pr_quotehead.ware_code 
								IF pr_future_available > 0 THEN 
									LET pr_msg = "Product ",pr_product.part_code clipped, 
									" has been superseded by ", 
									pr_product.super_part_code clipped,"." 
									IF kandoomsg("E",8036,pr_msg) = "N" THEN 
										#8036 Product ? been superseded by ?.
										#8036 Change product selection (Y/N).
										LET pr_super_ind = true 
										EXIT WHILE 
									END IF 
								END IF 
							END IF 
							SELECT * INTO pr_product.* FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_product.super_part_code 
							IF idx > 20 THEN 
								LET msgresp = kandoomsg("E",9183,"") 
								#9183 Product code supercession limit exceeded
								LET pr_quotedetl.part_code = NULL 
								LET pr_quotedetl.desc_text = NULL 
								RETURN false,pr_quotedetl.* 
							END IF 
						END WHILE 
						LET pr_quotedetl.part_code = pr_product.part_code 
						LET pr_quotedetl.desc_text = pr_product.desc_text 
						IF NOT pr_super_ind THEN 
							LET msgresp = kandoomsg("E",7060,pr_product.part_code) 
							#7060 Product replaced by superceded product .....
						ELSE 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
							pr_quotedetl.ware_code, 
							0,2,0,"","","") THEN 
								LET msgresp = kandoomsg("E",9263,"") 
								#9263 Product has been superseded with invalid part
								LET pr_quotedetl.part_code = NULL 
								LET pr_quotedetl.desc_text = NULL 
								RETURN false,pr_quotedetl.* 
							END IF 
							IF pr_quotedetl.part_code IS NOT NULL THEN 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
								pr_customer.cust_code, 
								pr_quotedetl.ware_code, 
								5, 
								today) THEN 
									LET msgresp = kandoomsg("E",9263,"") 
									#9263 Product has been superseded with invalid part
									LET pr_quotedetl.part_code = NULL 
									LET pr_quotedetl.desc_text = NULL 
									RETURN false,pr_quotedetl.* 
								END IF 
								IF prod_exclude(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
								pr_customer.cust_code, 
								pr_quotedetl.ware_code, 
								6, 
								today) THEN 
									LET msgresp = kandoomsg("E",9263,"") 
									#9263 Product has been superseded with invalid part
									LET pr_quotedetl.part_code = NULL 
									LET pr_quotedetl.desc_text = NULL 
									RETURN false,pr_quotedetl.* 
								END IF 
							END IF 
						END IF 
					ELSE 
						IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_quotedetl.part_code, 
						pr_quotedetl.ware_code,1,2,0,"","","") 
						THEN 
							RETURN false,pr_quotedetl.* 
						END IF 
						LET pr_quotedetl.desc_text = pr_product.desc_text 
						LET pr_quotedetl.trade_in_flag = pr_product.trade_in_flag 
						LET pr_quotedetl.disc_allow_flag = pr_product.disc_allow_flag 
					END IF 
					### Stock availability ###
					SELECT prodstatus.*, (onhand_qty - reserved_qty - back_qty) 
					INTO pr_prodstatus.*, 
					pr_available 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_quotedetl.ware_code 
					AND part_code = pr_product.part_code 
					LET pr_status = status 
					IF pr_status = notfound OR pr_available <= 0 THEN 
						IF check_alternate(pr_product.part_code, 
						pr_product.alter_part_code) THEN 
							#N8020 Product NOT currently stocked.Choose Alternate?
							IF kandoomsg("N",8020,"") = "Y" THEN 
								LET pr_part_code 
								= display_alternates(pr_product.part_code, 
								pr_product.alter_part_code) 
								IF pr_part_code IS NOT NULL THEN 
									LET pr_quotedetl.part_code = pr_part_code 
									SELECT * INTO pr_product.* FROM product 
									WHERE part_code = pr_quotedetl.part_code 
									AND cmpy_code = glob_rec_kandoouser.cmpy_code 
									LET pr_quotedetl.desc_text = pr_product.desc_text 
									CALL validate_field("part_code",pr_quotedetl.*) 
									RETURNING pr_valid_ind,pr_quotedetl.* 
									IF NOT pr_valid_ind THEN 
										RETURN false, pr_quotedetl.* 
									END IF 
								END IF 
							ELSE 
								IF pr_status = notfound THEN 
									LET pr_quotedetl.part_code = ps_quotedetl.part_code 
									RETURN false, pr_quotedetl.* 
								END IF 
							END IF 
						ELSE 
							IF pr_status = notfound THEN 
								LET msgresp = kandoomsg("I",9104,"") 
								#I9104 Product NOT Stocked AT this Warehouse
								LET pr_quotedetl.part_code = ps_quotedetl.part_code 
								RETURN false, pr_quotedetl.* 
							END IF 
						END IF 
					END IF 
					IF pr_quotedetl.offer_code IS NOT NULL THEN 
						SELECT unique 1 FROM offerprod 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND offer_code= pr_quotedetl.offer_code 
						AND maingrp_code = pr_product.maingrp_code 
						AND (prodgrp_code = pr_product.prodgrp_code 
						OR prodgrp_code IS null) 
						AND (part_code=pr_product.part_code OR part_code IS null) 
						IF sqlca.sqlcode = notfound THEN 
							LET msgresp=kandoomsg("E",9073,pr_product.part_code) 
							#9073" product IS NOT available as part of offer
							RETURN false,pr_quotedetl.* 
						END IF 
					END IF 
					## Unit Price always calc. b/c in Add Mode
					LET pr_quotedetl.unit_price_amt = 
					unit_price(pr_quotedetl.ware_code, 
					pr_quotedetl.part_code, 
					pr_quotedetl.level_ind) 
					## Calc. disc always b/c in Add Mode
					LET pr_quotedetl.disc_per = NULL 
				END IF 
			END IF 
		WHEN pr_field_name = "sold_qty" 
			CASE 
				WHEN pr_quotedetl.sold_qty IS NULL 
					LET pr_quotedetl.sold_qty = 0 
					RETURN false,pr_quotedetl.* 
				WHEN pr_quotedetl.trade_in_flag = "Y" 
					IF pr_quotedetl.sold_qty > 0 THEN 
						LET msgresp = kandoomsg("E",9181,"") 
						#9181 Trade-in products can be entered negative only
						LET pr_quotedetl.sold_qty = 0 - pr_quotedetl.sold_qty 
						RETURN false, pr_quotedetl.* 
					END IF 
				OTHERWISE 
					IF pr_quotedetl.sold_qty < 0 THEN 
						LET msgresp = kandoomsg("E",9180,"") 
						#9180 Quantity may NOT be negative
						LET pr_quotedetl.sold_qty = 0 - pr_quotedetl.sold_qty 
						RETURN false,pr_quotedetl.* 
					END IF 
			END CASE 
			IF ((pr_quotedetl.sold_qty + pr_quotedetl.bonus_qty) 
			< pr_quotedetl.reserved_qty) 
			AND pr_quotedetl.reserved_qty != 0 THEN 
				LET pr_quotedetl.reserved_qty = 0 
				LET msgresp = kandoomsg("Q",9241,"") 
				#9241 Reserved qty > ordered qty. Reserved qty has been SET TO 0.
			END IF 
		WHEN pr_field_name = "bonus_qty" 
			CASE 
				WHEN pr_quotedetl.bonus_qty IS NULL 
					LET pr_quotedetl.bonus_qty = 0 
					RETURN false,pr_quotedetl.* 
				WHEN pr_quotedetl.sold_qty < 0 
					LET msgresp = kandoomsg("E",9180,"") 
					#9180 Quantity may NOT be negative
					LET pr_quotedetl.bonus_qty = 0 - pr_quotedetl.bonus_qty 
					RETURN false,pr_quotedetl.* 
			END CASE 
			IF ((pr_quotedetl.sold_qty + pr_quotedetl.bonus_qty) 
			< pr_quotedetl.reserved_qty) 
			AND pr_quotedetl.reserved_qty != 0 THEN 
				LET pr_quotedetl.reserved_qty = 0 
				LET msgresp = kandoomsg("Q",9241,"") 
				#9241 Reserved qty > ordered qty. Reserved qty has been SET TO 0.
			END IF 
			IF (pr_quotehead.cond_code IS NULL AND pr_quotedetl.offer_code IS null) 
			OR pr_quotedetl.status_ind = "3" ## non-inventory 
			OR pr_quotedetl.trade_in_flag = "Y" THEN ## trade-ins 
				LET pr_quotedetl.bonus_qty = 0 
				RETURN false, pr_quotedetl.* 
			END IF 
		WHEN pr_field_name = "reserved_qty" 
			CASE 
				WHEN pr_quotedetl.reserved_qty IS NULL 
					LET pr_quotedetl.reserved_qty = 0 
					RETURN false, pr_quotedetl.* 
				WHEN pr_quotedetl.reserved_qty < 0 
					LET msgresp = kandoomsg("Q",9081,"") 
					#9081" Reserved Quantity Must Not be Negative"
					RETURN false, pr_quotedetl.* 
				WHEN pr_quotedetl.reserved_qty > pr_quotedetl.order_qty 
					LET msgresp = kandoomsg("Q",9082,"") 
					#9082" Reserved Quantity Exceeds Required Qty"
					RETURN false, pr_quotedetl.* 
			END CASE 
			LET pr_quotedetl.required_qty = calc_avail(pr_quotedetl.*,true) 
			#IF pr_quotedetl.reserved_qty > pr_quotedetl.required_qty
			#AND pr_quotedetl.reserved_qty != 0 THEN
			IF (pr_quotedetl.required_qty < 0 
			OR pr_quotedetl.required_qty IS NULL ) 
			AND pr_quotedetl.reserved_qty != 0 THEN 
				LET msgresp = kandoomsg("Q",9242,"") 
				#9242 Reserved IS greater than available quantity
				RETURN false, pr_quotedetl.* 
			END IF 
		WHEN pr_field_name = "disc_per" 
			IF pr_quotedetl.disc_per IS NULL THEN 
				LET pr_quotedetl.disc_per = 0 
				RETURN false,pr_quotedetl.* 
			ELSE 
				IF pr_quotedetl.list_price_amt > 0 THEN 
					IF ps_quotedetl.disc_per IS NOT NULL 
					AND ( ps_quotedetl.disc_per < (pr_quotedetl.disc_per-0.1) 
					OR ps_quotedetl.disc_per > (pr_quotedetl.disc_per+0.1) ) THEN 
						##### 0.1 TO avoid rounding error
						## IF disc changed THEN recalc price
						LET pr_quotedetl.unit_price_amt = NULL 
						LET pr_quotedetl.serial_qty = false 
						## IF discount changed THEN auto_disc = FALSE
					END IF 
				END IF 
			END IF 
		WHEN pr_field_name = "unit_price_amt" 
			IF pr_quotedetl.unit_price_amt IS NULL THEN 
				LET pr_quotedetl.unit_price_amt = 
				unit_price(pr_quotedetl.ware_code, 
				pr_quotedetl.part_code, 
				pr_quotedetl.level_ind) 
				RETURN false,pr_quotedetl.* 
			ELSE 
				IF pr_quotedetl.unit_price_amt < 0 THEN 
					LET msgresp=kandoomsg("E",9239,"") 
					#9239 Selling price cannot be negative
					RETURN false,pr_quotedetl.* 
				ELSE 
					IF pr_quotedetl.list_price_amt = 0 THEN 
						LET pr_quotedetl.list_price_amt = pr_quotedetl.unit_price_amt 
						LET pr_quotedetl.disc_per = 0 
					ELSE 
						IF ps_quotedetl.unit_price_amt IS NOT NULL 
						AND ( ps_quotedetl.unit_price_amt < 
						(pr_quotedetl.unit_price_amt-0.1) 
						OR ps_quotedetl.unit_price_amt > 
						(pr_quotedetl.unit_price_amt+0.1) ) THEN 
							##### +/-0.1 TO avoid rounding error
							## IF price changed THEN recalc disc
							LET pr_quotedetl.disc_per = NULL 
							LET pr_quotedetl.serial_qty = false 
							## IF price changed THEN auto_disc = FALSE
						END IF 
					END IF 
				END IF 
			END IF 
	END CASE 
	CALL update_line(pr_quotedetl.*) 
	SELECT * INTO pr_quotedetl.* 
	FROM t_quotedetl 
	WHERE line_num = pr_quotedetl.line_num 
	RETURN true, 
	pr_quotedetl.* 
END FUNCTION 
