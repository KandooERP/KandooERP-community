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
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

#  Setup initial VALUES in quotedetl

DEFINE modu_rec_prodstatus RECORD LIKE prodstatus.* 

###########################################################################
# FUNCTION update_line_details(p_cmpy_code, p_rec_quotedetl, p_rec_quotehead, p_rec_qpparms)
#
#
###########################################################################
FUNCTION update_line_details(p_cmpy_code, p_rec_quotedetl, p_rec_quotehead, p_rec_qpparms) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_quotedetl RECORD LIKE quotedetl.* 
	DEFINE p_rec_quotehead RECORD LIKE quotehead.* 
	DEFINE p_rec_qpparms RECORD LIKE qpparms.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_margin_percent FLOAT 
	DEFINE l_disc_per FLOAT	
	DEFINE l_taxable_amt LIKE quotehead.tax_amt 
	DEFINE l_round_err DECIMAL(16,2)
	DEFINE l_tax_amt DECIMAL(16,2)
	DEFINE l_tax_amt2 DECIMAL(16,2)	
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_tax2 RECORD LIKE tax.* 

	LET glob_rec_kandoouser.cmpy_code = p_cmpy_code 
	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cust_code = p_rec_quotehead.cust_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code
	 
	SELECT * FROM product 
	WHERE part_code = p_rec_quotedetl.part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = notfound THEN 
		LET p_rec_quotedetl.status_ind = "3" 
		LET p_rec_quotedetl.trade_in_flag = "N" 
		LET p_rec_quotedetl.disc_allow_flag = "" 
		LET p_rec_quotedetl.serial_flag = "N" 
		LET p_rec_quotedetl.pick_flag = "N" 
		LET p_rec_quotedetl.disc_per = 0 
		
		IF p_rec_quotedetl.unit_price_amt IS NULL THEN 
			LET p_rec_quotedetl.unit_price_amt = 0 
		END IF
		 
		LET p_rec_quotedetl.tax_code = p_rec_quotehead.tax_code 
		LET p_rec_quotedetl.list_price_amt = p_rec_quotedetl.unit_price_amt 
		LET p_rec_quotedetl.cost_ind = "N" # FIELD used as back_ord_flag(see notes) 
	ELSE 
		SELECT * INTO l_rec_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_rec_quotedetl.part_code 
		LET p_rec_quotedetl.cat_code = l_rec_product.cat_code 
		LET p_rec_quotedetl.uom_code = l_rec_product.sell_uom_code 
		LET p_rec_quotedetl.serial_flag = l_rec_product.serial_flag 
		LET p_rec_quotedetl.prodgrp_code = l_rec_product.prodgrp_code 
		LET p_rec_quotedetl.maingrp_code = l_rec_product.maingrp_code 
		LET p_rec_quotedetl.trade_in_flag = l_rec_product.trade_in_flag 

		IF p_rec_quotedetl.disc_allow_flag IS NULL THEN 
			LET p_rec_quotedetl.disc_allow_flag = l_rec_product.disc_allow_flag 
		END IF 

		IF p_rec_quotedetl.offer_code IS NOT NULL THEN 
			LET p_rec_quotedetl.serial_qty = true ## auto disc.calc reqd 
		END IF 

		IF p_rec_quotedetl.desc_text IS NULL THEN 
			LET p_rec_quotedetl.desc_text = l_rec_product.desc_text 
		END IF 

		SELECT sale_acct_code INTO p_rec_quotedetl.acct_code 
		FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cat_code = p_rec_quotedetl.cat_code 

		SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_quotedetl.ware_code 
		AND part_code = p_rec_quotedetl.part_code 
		IF status = notfound THEN 
			LET p_rec_quotedetl.status_ind = "3" 
			LET p_rec_quotedetl.disc_per = 0 
			IF p_rec_quotedetl.unit_price_amt IS NULL THEN 
				LET p_rec_quotedetl.unit_price_amt = 0 
			END IF 
			LET p_rec_quotedetl.tax_code = p_rec_quotehead.tax_code 
			LET p_rec_quotedetl.list_price_amt = p_rec_quotedetl.unit_price_amt 
			LET p_rec_quotedetl.cost_ind = "N" 
		ELSE 
			IF modu_rec_prodstatus.stocked_flag = "Y"	OR modu_rec_prodstatus.nonstk_pick_flag = "Y" THEN 
				LET p_rec_quotedetl.pick_flag = "Y" 
			ELSE 
				LET p_rec_quotedetl.pick_flag = "N" 
			END IF 

			LET p_rec_quotedetl.unit_cost_amt = modu_rec_prodstatus.wgted_cost_amt * p_rec_quotehead.conv_qty 
			LET p_rec_quotedetl.list_price_amt = modu_rec_prodstatus.list_amt 

			IF p_rec_quotedetl.list_price_amt = 0 THEN 
				IF p_rec_quotedetl.unit_price_amt IS NOT NULL THEN 
					LET p_rec_quotedetl.list_price_amt = p_rec_quotedetl.unit_price_amt 
					LET p_rec_quotedetl.disc_per = 0 
				END IF 
			END IF 

			IF p_rec_quotedetl.unit_price_amt IS NULL THEN 
				## calc price based on disc
				LET p_rec_quotedetl.unit_price_amt = p_rec_quotedetl.list_price_amt - (p_rec_quotedetl.list_price_amt * (p_rec_quotedetl.disc_per/100)) 
			END IF 

			## calc disc based on price
			IF p_rec_quotedetl.disc_per IS NULL THEN 
				IF p_rec_quotedetl.list_price_amt != 0 THEN 
					LET l_disc_per = 100 * (p_rec_quotedetl.list_price_amt - p_rec_quotedetl.unit_price_amt) / (p_rec_quotedetl.list_price_amt) 
					IF l_disc_per < 0 THEN 
						LET p_rec_quotedetl.disc_per = 0 
					ELSE 
						LET p_rec_quotedetl.disc_per = l_disc_per 
					END IF 
				ELSE 
					LET p_rec_quotedetl.disc_per = 0 
				END IF 
			END IF 

			LET p_rec_quotedetl.tax_code = modu_rec_prodstatus.sale_tax_code 
			LET p_rec_quotedetl.cost_ind = permit_backordering(
				p_rec_quotedetl.ware_code, 
				p_rec_quotedetl.part_code, 
				l_rec_customer.back_order_flag) 

			IF p_rec_quotedetl.serial_qty THEN ### auto discount calc reqd 
				LET p_rec_quotedetl.job_code = false ## jobcode IS discount_taken_ind 
			ELSE 
				LET p_rec_quotedetl.job_code = true ## jobcode IS discount_taken_ind 
			END IF 

			IF p_rec_quotedetl.autoinsert_flag = "Y" THEN 
				LET p_rec_quotedetl.job_code = true ## jobcode IS discount_taken_ind 
			END IF 

			IF p_rec_quotedetl.trade_in_flag = "Y" THEN 
				LET p_rec_quotedetl.disc_allow_flag = "N" 
				LET p_rec_quotedetl.pick_flag = "N" 
				LET p_rec_quotedetl.serial_qty = false 
				LET p_rec_quotedetl.serial_flag = "N" 
				LET p_rec_quotedetl.list_price_amt = p_rec_quotedetl.unit_price_amt 
				LET p_rec_quotedetl.job_code = true ## jobcode IS discount_taken_ind 
				LET p_rec_quotedetl.cost_ind = "N" ## cost_ind used as back_ord_flag 
			END IF 

			LET p_rec_quotedetl.required_qty = calc_avail(p_rec_quotedetl.*,false) 
		END IF 
	END IF 

	CALL calc_line_tax(
		glob_rec_kandoouser.cmpy_code,
		p_rec_quotehead.tax_code, 
		p_rec_quotedetl.tax_code, 
		modu_rec_prodstatus.sale_tax_amt, 
		p_rec_quotedetl.sold_qty, 
		p_rec_quotedetl.unit_cost_amt, 
		p_rec_quotedetl.unit_price_amt) 
	RETURNING 
		p_rec_quotedetl.unit_tax_amt, 
		p_rec_quotedetl.ext_tax_amt 

	LET p_rec_quotedetl.ext_price_amt = p_rec_quotedetl.unit_price_amt * p_rec_quotedetl.sold_qty 
	LET p_rec_quotedetl.ext_tax_amt = p_rec_quotedetl.unit_tax_amt * p_rec_quotedetl.sold_qty 
	LET l_round_err = 0 

	INITIALIZE l_rec_tax.* TO NULL 

	LET l_taxable_amt = 0 
	LET l_tax_amt = 0 
	LET l_tax_amt2 = 0 

	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = p_rec_quotehead.tax_code 
	
	IF l_rec_tax.calc_method_flag = "T" THEN 
		INITIALIZE l_rec_tax2.* TO NULL 
		SELECT * INTO l_rec_tax2.* FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_quotedetl.tax_code 

		IF l_rec_tax2.calc_method_flag != "X" THEN 
			SELECT sum(ext_price_amt) INTO l_taxable_amt 
			FROM t_quotedetl,tax 
			WHERE line_num != p_rec_quotedetl.line_num 
			AND t_quotedetl.tax_code = tax.tax_code 
			AND calc_method_flag != "X" 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_taxable_amt = l_taxable_amt + p_rec_quotedetl.ext_price_amt 
			
			CALL calc_total_tax(glob_rec_kandoouser.cmpy_code, "T", l_taxable_amt, l_rec_tax.tax_code) 
			RETURNING l_tax_amt 
			SELECT sum(ext_tax_amt) INTO l_tax_amt2 FROM t_quotedetl 
			WHERE line_num != p_rec_quotedetl.line_num 
			LET l_tax_amt2 = l_tax_amt2 + p_rec_quotedetl.ext_tax_amt
			 
			IF l_tax_amt != l_tax_amt2 THEN 
				LET l_round_err = l_tax_amt2 - l_tax_amt 
			END IF
			 
			IF l_round_err != 0 THEN 
				LET p_rec_quotedetl.ext_tax_amt = p_rec_quotedetl.ext_tax_amt - l_round_err 
			END IF 
		END IF 
	END IF 

	IF p_rec_quotedetl.ext_tax_amt IS NULL THEN 
		LET p_rec_quotedetl.ext_tax_amt = 0 
	END IF 

	IF p_rec_quotedetl.unit_cost_amt != 0 THEN 
		LET l_margin_percent = ((p_rec_quotedetl.unit_price_amt - p_rec_quotedetl.unit_cost_amt) / p_rec_quotedetl.unit_cost_amt) * 100 
	END IF 

	IF (l_margin_percent > p_rec_qpparms.max_margin_per 
	OR l_margin_percent < p_rec_qpparms.min_margin_per) 
	AND p_rec_quotedetl.trade_in_flag != "Y" 
	AND p_rec_quotedetl.offer_code IS NULL 
	AND p_rec_quotedetl.status_ind != "3" THEN 
		LET p_rec_quotedetl.margin_ind = "*" 
	ELSE 
		LET p_rec_quotedetl.margin_ind = "" 
	END IF 

	LET p_rec_quotedetl.ext_cost_amt = p_rec_quotedetl.unit_cost_amt * p_rec_quotedetl.order_qty 
	LET p_rec_quotedetl.ext_bonus_amt = p_rec_quotedetl.list_price_amt * p_rec_quotedetl.bonus_qty
	LET p_rec_quotedetl.ext_stats_amt = 0 
	LET p_rec_quotedetl.line_tot_amt = p_rec_quotedetl.sold_qty * (p_rec_quotedetl.unit_tax_amt + p_rec_quotedetl.unit_price_amt) 
	LET p_rec_quotedetl.disc_amt = p_rec_quotedetl.sold_qty * (p_rec_quotedetl.list_price_amt - p_rec_quotedetl.unit_price_amt) 
	RETURN p_rec_quotedetl.* 
END FUNCTION 
###########################################################################
# END FUNCTION update_line_details(p_cmpy_code, p_rec_quotedetl, p_rec_quotehead, p_rec_qpparms)
###########################################################################


###########################################################################
# FUNCTION calc_avail(p_rec_quotedetl,p_display_ind)
#
#
###########################################################################
FUNCTION calc_avail(p_rec_quotedetl,p_display_ind) 
	DEFINE p_rec_quotedetl RECORD LIKE quotedetl.*
	DEFINE p_display_ind SMALLINT	
	DEFINE l_rec_opparms RECORD LIKE opparms.* 
	DEFINE l_cur_avail_qty LIKE prodstatus.onhand_qty 
	DEFINE l_fut_avail_qty LIKE prodstatus.onhand_qty 

	CALL db_opparms_get_rec(UI_OFF,"1") RETURNING l_rec_opparms.*
	 
	SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_quotedetl.part_code 
	AND ware_code = p_rec_quotedetl.ware_code 
	IF status = notfound THEN 
		IF p_display_ind THEN 
			LET modu_rec_prodstatus.ware_code = p_rec_quotedetl.ware_code 
			LET modu_rec_prodstatus.onhand_qty = 0 
			LET modu_rec_prodstatus.reserved_qty = 0 
			LET modu_rec_prodstatus.back_qty = 0 
			LET l_cur_avail_qty = 0 
			LET modu_rec_prodstatus.onord_qty = 0 
			LET l_fut_avail_qty = 0 

			DISPLAY 
				modu_rec_prodstatus.ware_code, 
				modu_rec_prodstatus.onhand_qty, 
				modu_rec_prodstatus.reserved_qty, 
				modu_rec_prodstatus.back_qty, 
				l_cur_avail_qty, 
				modu_rec_prodstatus.onord_qty, 
				l_fut_avail_qty 
			TO 
				quotedetl.ware_code, 
				prodstatus.onhand_qty, 
				reserved_qty, 
				prodstatus.back_qty, 
				current_qty, 
				prodstatus.onord_qty, 
				future_qty attribute(yellow)			 
		END IF 
		
		RETURN NULL 
	END IF 
	
	IF modu_rec_prodstatus.stocked_flag = "Y" THEN 
		LET modu_rec_prodstatus.reserved_qty = modu_rec_prodstatus.reserved_qty + p_rec_quotedetl.reserved_qty 
		IF l_rec_opparms.cal_available_flag = "N" THEN 
			LET l_cur_avail_qty = modu_rec_prodstatus.onhand_qty - modu_rec_prodstatus.reserved_qty - modu_rec_prodstatus.back_qty 
		ELSE 
			LET l_cur_avail_qty = modu_rec_prodstatus.onhand_qty - modu_rec_prodstatus.reserved_qty 
			LET modu_rec_prodstatus.back_qty = "" 
		END IF 

		LET l_fut_avail_qty = l_cur_avail_qty + modu_rec_prodstatus.onord_qty 

		IF p_display_ind THEN 
			DISPLAY 
				modu_rec_prodstatus.ware_code, 
				modu_rec_prodstatus.onhand_qty, 
				modu_rec_prodstatus.reserved_qty, 
				modu_rec_prodstatus.back_qty, 
				l_cur_avail_qty, 
				modu_rec_prodstatus.onord_qty, 
				l_fut_avail_qty 
			TO 
				quotedetl.ware_code, 
				prodstatus.onhand_qty, 
				reserved_qty, 
				prodstatus.back_qty, 
				current_qty, 
				prodstatus.onord_qty, 
				future_qty	attribute(yellow)
		END IF 
		
		IF l_cur_avail_qty = 0 OR l_cur_avail_qty IS NULL THEN
			ERROR "Quantity is set to 0"
		END IF
		
		RETURN l_cur_avail_qty 
	ELSE 
		IF p_display_ind THEN 
			CALL fgl_winmessage("Stock Status","Item is not on Stock","INFO") --DISPLAY " NOT STOCKED " at 7,44
		END IF 
		RETURN NULL
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION calc_avail(p_rec_quotedetl,p_display_ind)
###########################################################################


###########################################################################
# FUNCTION permit_backordering(p_ware_code,p_part_code, p_back_order_flag)
#
#
###########################################################################
FUNCTION permit_backordering(p_ware_code,p_part_code, p_back_order_flag) 
	# FUNCTION returns "Y" OR "N" depending on whether the
	# cust, warehouse, product combo permits backordering
	DEFINE p_ware_code LIKE quotedetl.ware_code 
	DEFINE p_part_code LIKE quotedetl.part_code 
	DEFINE p_back_order_flag LIKE customer.back_order_flag 

	IF p_back_order_flag = "N"	AND NOT get_kandoooption_feature_state("EO","BA") THEN 
		RETURN "N" 
	END IF
	 
	IF p_ware_code IS NOT NULL THEN 
		SELECT unique 1 FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_ware_code 
		AND back_order_ind = "0" 
		IF sqlca.sqlcode = 0 THEN 
			RETURN "N" 
		END IF 
	END IF
	 
	IF p_part_code IS NOT NULL THEN 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code 
		AND back_order_flag = "N" 
		IF sqlca.sqlcode = 0 THEN 
			RETURN "N" 
		END IF 
	END IF 
	RETURN "Y" 
END FUNCTION 
###########################################################################
# END FUNCTION permit_backordering(p_ware_code,p_part_code, p_back_order_flag)
###########################################################################