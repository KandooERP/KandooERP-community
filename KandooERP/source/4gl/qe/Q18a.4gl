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

	Source code beautified by beautify.pl on 2020-01-02 09:16:01	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "Q_QE_GLOBALS.4gl" 
GLOBALS "Q18_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module Q18a - Routine updates the orders tables with the VALUES FROM
#                the quotes tables FOR an accepted quote. It also reserves
#                any stock available, OR places it on back ORDER



FUNCTION write_order(pr_order_num) 
	DEFINE 
	pr_order_num LIKE quotehead.order_num, 
	pr_customer RECORD LIKE customer.*, 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_orderhead RECORD LIKE orderhead.*, 
	pr_orderdetl RECORD LIKE orderdetl.*, 
	pt_orderdetl RECORD LIKE orderdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_qpparms RECORD LIKE qpparms.*, 
	pr_back_qty, 
	pr_avail_qty, 
	pr_reserved_qty, 
	pr_outstanding_qty LIKE prodstatus.onhand_qty, 
	pr_err_message CHAR(60), 
	pr_back_flag SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(pr_err_message,status) != "Y" THEN 
		RETURN false, false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_back_flag = false 
		LET pr_err_message = "Q18 - Lock Quotation" 
		DECLARE c_quotehead CURSOR FOR 
		SELECT * FROM quotehead 
		WHERE order_num = pr_order_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_quotehead 
		FETCH c_quotehead INTO pr_quotehead.* 
		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO pr_customer.* 
		## setup ORDER header record
		LET pr_err_message = "Q18 - Prepare ORDER header RECORD " 
		INITIALIZE pr_orderhead.* TO NULL 
		LET pr_orderhead.cmpy_code = pr_quotehead.cmpy_code 
		LET pr_orderhead.cust_code = pr_quotehead.cust_code 
		LET pr_orderhead.order_num = pr_quotehead.order_num 
		LET pr_orderhead.last_inv_num = NULL 
		LET pr_orderhead.ord_text = pr_quotehead.ord_text 
		LET pr_orderhead.entry_code = pr_quotehead.entry_code 
		LET pr_orderhead.entry_date = today 
		LET pr_orderhead.order_date = today 
		LET pr_orderhead.sales_code = pr_quotehead.sales_code 
		LET pr_orderhead.term_code = pr_quotehead.term_code 
		LET pr_orderhead.tax_code = pr_quotehead.tax_code 
		LET pr_orderhead.goods_amt = pr_quotehead.goods_amt 
		LET pr_orderhead.hand_amt = pr_quotehead.hand_amt 
		LET pr_orderhead.hand_tax_code = pr_quotehead.hand_tax_code 
		LET pr_orderhead.hand_tax_amt = pr_quotehead.hand_tax_amt 
		LET pr_orderhead.freight_amt = pr_quotehead.freight_amt 
		LET pr_orderhead.freight_tax_code = pr_quotehead.freight_tax_code 
		LET pr_orderhead.freight_tax_amt = pr_quotehead.freight_tax_amt 
		LET pr_orderhead.tax_amt = pr_quotehead.tax_amt 
		LET pr_orderhead.disc_amt = pr_quotehead.disc_amt 
		LET pr_orderhead.total_amt = pr_quotehead.total_amt 
		LET pr_orderhead.cost_amt = pr_quotehead.cost_amt 
		LET pr_orderhead.status_ind = "U" 
		LET pr_orderhead.line_num = pr_quotehead.line_num 
		LET pr_orderhead.com1_text = pr_quotehead.com1_text 
		LET pr_orderhead.com2_text = pr_quotehead.com2_text 
		LET pr_orderhead.ship_code = pr_quotehead.ship_code 
		LET pr_orderhead.ship_name_text = pr_quotehead.ship_name_text 
		LET pr_orderhead.ship_addr1_text = pr_quotehead.ship_addr1_text 
		LET pr_orderhead.ship_addr2_text = pr_quotehead.ship_addr2_text 
		LET pr_orderhead.ship_city_text = pr_quotehead.ship_city_text 
		LET pr_orderhead.state_code = pr_quotehead.state_code 
		LET pr_orderhead.post_code = pr_quotehead.post_code 
		LET pr_orderhead.country_code = pr_quotehead.country_code --@db-patch_2020_10_04--
		LET pr_orderhead.ship1_text = pr_quotehead.ship1_text 
		LET pr_orderhead.ship2_text = pr_quotehead.ship2_text 
		LET pr_orderhead.ship_date = pr_quotehead.ship_date 
		LET pr_orderhead.fob_text = pr_quotehead.fob_text 
		LET pr_orderhead.prepaid_flag = pr_quotehead.prepaid_flag 
		LET pr_orderhead.cost_ind = pr_quotehead.cost_ind 
		LET pr_orderhead.hold_code = pr_quotehead.hold_code 
		LET pr_orderhead.currency_code = pr_quotehead.currency_code 
		LET pr_orderhead.conv_qty = pr_quotehead.conv_qty 
		LET pr_orderhead.acct_override_code=pr_quotehead.acct_override_code 
		LET pr_orderhead.price_tax_flag = pr_quotehead.price_tax_flag 
		LET pr_orderhead.contact_text = pr_quotehead.contact_text 
		LET pr_orderhead.tele_text = pr_quotehead.tele_text 
		LET pr_orderhead.mobile_phone = pr_quotehead.mobile_phone
		LET pr_orderhead.email = pr_quotehead.email
		LET pr_orderhead.ord_ind = pr_quotehead.quote_ind 
		LET pr_orderhead.first_inv_num = NULL 
		LET pr_orderhead.last_inv_date = NULL 
		LET pr_orderhead.invoice_to_ind = pr_quotehead.invoice_to_ind 
		LET pr_orderhead.territory_code = pr_quotehead.territory_code 
		LET pr_orderhead.mgr_code = pr_quotehead.mgr_code 
		LET pr_orderhead.area_code = pr_quotehead.area_code 
		LET pr_orderhead.cond_code = pr_quotehead.cond_code 
		LET pr_orderhead.carrier_code = pr_quotehead.carrier_code 
		LET pr_orderhead.freight_ind = pr_quotehead.freight_ind 
		LET pr_orderhead.delivery_ind = pr_quotehead.delivery_ind 
		LET pr_orderhead.ware_code = pr_quotehead.ware_code 
		LET pr_orderhead.freight_inv_amt = 0 
		LET pr_orderhead.hand_inv_amt = 0 
		LET pr_orderhead.rev_num = 0 
		LET pr_orderhead.rev_date = today 
		DECLARE c_quotedetl CURSOR FOR 
		SELECT * 
		FROM quotedetl 
		WHERE order_num = pr_quotehead.order_num 
		AND cmpy_code = pr_quotehead.cmpy_code 
		FOREACH c_quotedetl INTO pr_quotedetl.* 
			IF pr_quotedetl.maingrp_code IS NULL 
			OR pr_quotedetl.list_price_amt IS NULL 
			OR (pr_quotedetl.status_ind = 3 
			AND pr_quotedetl.part_code IS NOT null) 
			OR pr_quotedetl.unit_cost_amt IS NULL THEN 
				SELECT * INTO pr_qpparms.* 
				FROM qpparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_num = "1" 
				CALL update_line_details(glob_rec_kandoouser.cmpy_code,pr_quotedetl.*, 
				pr_quotehead.*, 
				pr_qpparms.*) 
				RETURNING pr_quotedetl.* 
			END IF 
			INITIALIZE pr_orderdetl.* TO NULL 
			LET pr_reserved_qty = 0 
			LET pr_back_qty = 0 
			IF pr_quotedetl.part_code IS NOT NULL THEN 
				LET pr_err_message = "Q18a - prodstatus UPDATE" 
				DECLARE c_prodstatus CURSOR FOR 
				SELECT * FROM prodstatus 
				WHERE part_code = pr_quotedetl.part_code 
				AND ware_code = pr_quotedetl.ware_code 
				AND cmpy_code = pr_quotedetl.cmpy_code 
				FOR UPDATE 
				OPEN c_prodstatus 
				FETCH c_prodstatus INTO pr_prodstatus.* 
				IF status = 0 THEN 
					SELECT unique 1 FROM product 
					WHERE part_code = pr_quotedetl.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND trade_in_flag = "Y" 
					IF status = notfound THEN 
						IF pr_prodstatus.stocked_flag = "Y" THEN 
							LET pr_avail_qty = pr_prodstatus.onhand_qty 
							- pr_prodstatus.reserved_qty 
							LET pr_outstanding_qty = pr_quotedetl.order_qty 
							- pr_quotedetl.reserved_qty 
							IF pr_avail_qty > 0 THEN 
								IF pr_avail_qty > pr_outstanding_qty THEN 
									LET pr_reserved_qty = pr_outstanding_qty 
									LET pr_back_qty = 0 
									LET pr_orderdetl.status_ind = pr_quotedetl.status_ind 
								ELSE 
									LET pr_reserved_qty = pr_avail_qty 
									LET pr_back_qty = pr_outstanding_qty - pr_avail_qty 
									LET pr_orderdetl.status_ind = "2" 
								END IF 
							ELSE 
								LET pr_reserved_qty = 0 
								LET pr_back_qty = pr_outstanding_qty 
								LET pr_orderdetl.status_ind = "2" 
							END IF 
							LET pr_err_message = "Q18a - Prodstatus Update" 
							UPDATE prodstatus 
							SET reserved_qty = reserved_qty + pr_reserved_qty, 
							back_qty = back_qty + pr_back_qty 
							WHERE part_code = pr_quotedetl.part_code 
							AND ware_code = pr_quotedetl.ware_code 
							AND cmpy_code = pr_quotedetl.cmpy_code 
						ELSE 
							#### Do NOT UPDATE non-stocked products
							LET pr_orderdetl.status_ind = "0" 
						END IF 
					ELSE 
						### Trade in lines
						LET pr_orderdetl.status_ind = "0" 
					END IF 
				END IF 
			ELSE 
				#### Null part code lines
				LET pr_orderdetl.status_ind = "3" 
			END IF 
			LET pr_err_message = "Q18 - Insert ORDER line" 
			LET pr_orderdetl.cmpy_code = pr_quotedetl.cmpy_code 
			LET pr_orderdetl.cust_code = pr_quotedetl.cust_code 
			LET pr_orderdetl.order_num = pr_quotedetl.order_num 
			LET pr_orderdetl.line_num = pr_quotedetl.line_num 
			LET pr_orderdetl.part_code = pr_quotedetl.part_code 
			LET pr_orderdetl.ware_code = pr_quotedetl.ware_code 
			LET pr_orderdetl.cat_code = pr_quotedetl.cat_code 
			LET pr_orderdetl.order_qty = pr_quotedetl.order_qty 
			LET pr_orderdetl.back_qty = pr_back_qty 
			IF pr_orderdetl.back_qty > 0 
			AND pr_customer.back_order_flag != "Y" THEN 
				LET pr_back_flag = true 
			END IF 
			LET pr_orderdetl.sched_qty = pr_quotedetl.order_qty 
			- pr_back_qty 
			LET pr_orderdetl.inv_qty = 0 
			LET pr_orderdetl.picked_qty = 0 
			LET pr_orderdetl.conf_qty = 0 
			LET pr_orderdetl.serial_flag = pr_quotedetl.serial_flag 
			LET pr_orderdetl.serial_qty = pr_quotedetl.serial_qty 
			LET pr_orderdetl.desc_text = pr_quotedetl.desc_text 
			LET pr_orderdetl.uom_code = pr_quotedetl.uom_code 
			LET pr_orderdetl.unit_price_amt = pr_quotedetl.unit_price_amt 
			LET pr_orderdetl.ext_price_amt = pr_quotedetl.ext_price_amt 
			LET pr_orderdetl.unit_tax_amt = pr_quotedetl.unit_tax_amt 
			LET pr_orderdetl.ext_tax_amt = pr_quotedetl.ext_tax_amt 
			LET pr_orderdetl.line_tot_amt = pr_quotedetl.line_tot_amt 
			LET pr_orderdetl.acct_code = pr_quotedetl.acct_code 
			LET pr_orderdetl.disc_per = pr_quotedetl.disc_per 
			LET pr_orderdetl.unit_cost_amt = pr_quotedetl.unit_cost_amt 
			LET pr_orderdetl.ext_cost_amt = pr_quotedetl.ext_cost_amt 
			LET pr_orderdetl.job_code = pr_quotedetl.job_code 
			LET pr_orderdetl.cost_ind = pr_quotedetl.cost_ind 
			LET pr_orderdetl.level_ind = pr_quotedetl.level_ind 
			LET pr_orderdetl.tax_code = pr_quotedetl.tax_code 
			LET pr_orderdetl.offer_code = pr_quotedetl.offer_code 
			LET pr_orderdetl.required_qty = pr_quotedetl.required_qty 
			LET pr_orderdetl.sold_qty = pr_quotedetl.sold_qty 
			LET pr_orderdetl.bonus_qty = pr_quotedetl.bonus_qty 
			LET pr_orderdetl.ext_bonus_amt = pr_quotedetl.ext_bonus_amt 
			LET pr_orderdetl.disc_amt = pr_quotedetl.disc_amt 
			LET pr_orderdetl.ext_stats_amt = pr_quotedetl.ext_stats_amt 
			LET pr_orderdetl.comm_amt = pr_quotedetl.comm_amt 
			LET pr_orderdetl.prodgrp_code = pr_quotedetl.prodgrp_code 
			LET pr_orderdetl.maingrp_code = pr_quotedetl.maingrp_code 
			LET pr_orderdetl.autoinsert_flag = pr_quotedetl.autoinsert_flag 
			LET pr_orderdetl.disc_allow_flag = pr_quotedetl.disc_allow_flag 
			LET pr_orderdetl.bonus_disc_amt = pr_quotedetl.bonus_disc_amt 
			LET pr_orderdetl.trade_in_flag = pr_quotedetl.trade_in_flag 
			LET pr_orderdetl.pick_flag = pr_quotedetl.pick_flag 
			LET pr_orderdetl.list_price_amt = pr_quotedetl.list_price_amt 
			LET pr_err_message = "Q18a - Orderdetl Insert" 
			INSERT INTO orderdetl VALUES (pr_orderdetl.*) 
			INITIALIZE pt_orderdetl.* TO NULL 
			IF NOT insert_line_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,pr_orderdetl.order_num, 
			pr_orderdetl.part_code, 
			pr_orderdetl.line_num, 
			pt_orderdetl.*, 
			pr_orderdetl.*) THEN 
				GOTO recovery 
			END IF 
		END FOREACH 
		LET pr_err_message = "Q18a - Orderhead Insert" 
		INSERT INTO orderhead VALUES (pr_orderhead.*) 
		LET pr_err_message = "Q18 - Order Log Insertion" 
		CALL insert_log(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,pr_orderhead.order_num,10,"","") 
		LET pr_err_message = "Q18 - Customer Update" 
		UPDATE customer 
		SET onorder_amt = onorder_amt + pr_orderhead.total_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN true, pr_back_flag 
END FUNCTION 
