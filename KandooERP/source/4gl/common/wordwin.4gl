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
# common/inhdwind.4gl
###########################################################################


#      W15a - Order Inquiry
#                  allows the user TO view Order Information - Header
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE modu_rec_orderline RECORD LIKE orderline.* 
DEFINE modu_rec_ordlinerate RECORD LIKE ordlinerate.* 
DEFINE modu_rec_ordhead RECORD LIKE ordhead.* 
DEFINE modu_rec__prodstatus RECORD LIKE prodstatus.* 
DEFINE modu_rec_customer RECORD LIKE customer.* 
DEFINE modu_rec_mbparms RECORD LIKE mbparms.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_rec_conversion_qty LIKE uomconv.conversion_qty 

###########################################################################
# FUNCTION disp_ordhead(p_cmpy, pr_order_num) 
#
#
###########################################################################
FUNCTION disp_ordhead(p_cmpy, pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	pr_delivhead RECORD LIKE delivhead.*, 
	cust_hold_text,order_hold_text CHAR(40) 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 
	IF modu_rec_ordhead.hold_code IS NOT NULL THEN 
		LET order_hold_text = "*** ORDER ON HOLD ***" 
	ELSE 
		LET order_hold_text = NULL 
	END IF 
	IF modu_rec_customer.hold_code IS NOT NULL THEN 
		LET cust_hold_text = "** CUSTOMER ON HOLD **" 
	ELSE 
		LET cust_hold_text = NULL 
	END IF 
	SELECT * INTO pr_delivhead.* FROM delivhead 
	WHERE order_num = modu_rec_ordhead.order_num 
	AND cust_code = modu_rec_ordhead.cust_code 
	AND del_num = modu_rec_ordhead.last_del_num 
	AND cmpy_code = p_cmpy 
	DISPLAY " " at 4,62 attribute(yellow) 
	IF modu_rec_customer.pay_ind = "2" THEN 
		DISPLAY "*" at 4,62 attribute(yellow) 
	END IF 
	IF (modu_rec_customer.over30_amt + 
	modu_rec_customer.over60_amt + 
	modu_rec_customer.over90_amt) > 0 THEN 
		DISPLAY BY NAME modu_rec_ordhead.cust_code, 
		modu_rec_customer.name_text, 
		modu_rec_customer.term_code, 
		modu_rec_ordhead.order_num, 
		modu_rec_ordhead.ord_ind, 
		modu_rec_ordhead.order_date, 
		modu_rec_customer.type_code, 
		modu_rec_customer.tele_text, 
		modu_rec_ordhead.status_ind, 
		modu_rec_ordhead.hold_code, 
		modu_rec_ordhead.ship_addr1_text, 
		modu_rec_ordhead.ship_addr2_text, 
		modu_rec_ordhead.ship_city_text, 
		modu_rec_ordhead.ship_state_code, 
		modu_rec_ordhead.ship_post_code, 
		modu_rec_ordhead.map_reference, 
		modu_rec_ordhead.ord_text, 
		modu_rec_ordhead.ship_date, 
		modu_rec_ordhead.last_del_date, 
		modu_rec_ordhead.last_del_num, 
		pr_delivhead.pick_num, 
		modu_rec_ordhead.ware_code, 
		modu_rec_ordhead.cart_area_code, 
		modu_rec_ordhead.territory_code, 
		modu_rec_ordhead.sale_code, 
		modu_rec_ordhead.job_territory, 
		modu_rec_ordhead.quote_num, 
		modu_rec_ordhead.quote_date, 
		modu_rec_ordhead.quote_amt, 
		modu_rec_ordhead.net_area_qty, 
		modu_rec_ordhead.super_code, 
		modu_rec_ordhead.entry_code, 
		modu_rec_ordhead.entry_date, 
		modu_rec_ordhead.rev_date, 
		modu_rec_ordhead.rev_num, 
		cust_hold_text, 
		order_hold_text 
		attribute(red) 
	ELSE 
		IF (modu_rec_customer.over1_amt + modu_rec_customer.over30_amt 
		+ modu_rec_customer.over60_amt + modu_rec_customer.over90_amt) > 0 THEN 
			DISPLAY BY NAME modu_rec_ordhead.cust_code, 
			modu_rec_customer.name_text, 
			modu_rec_customer.term_code, 
			modu_rec_ordhead.order_num, 
			modu_rec_ordhead.ord_ind, 
			modu_rec_ordhead.order_date, 
			modu_rec_customer.type_code, 
			modu_rec_customer.tele_text, 
			modu_rec_ordhead.status_ind, 
			modu_rec_ordhead.hold_code, 
			modu_rec_ordhead.ship_addr1_text, 
			modu_rec_ordhead.ship_addr2_text, 
			modu_rec_ordhead.ship_city_text, 
			modu_rec_ordhead.ship_state_code, 
			modu_rec_ordhead.ship_post_code, 
			modu_rec_ordhead.map_reference, 
			modu_rec_ordhead.ord_text, 
			modu_rec_ordhead.ship_date, 
			modu_rec_ordhead.last_del_date, 
			modu_rec_ordhead.last_del_num, 
			pr_delivhead.pick_num, 
			modu_rec_ordhead.ware_code, 
			modu_rec_ordhead.cart_area_code, 
			modu_rec_ordhead.territory_code, 
			modu_rec_ordhead.sale_code, 
			modu_rec_ordhead.job_territory, 
			modu_rec_ordhead.quote_num, 
			modu_rec_ordhead.quote_date, 
			modu_rec_ordhead.quote_amt, 
			modu_rec_ordhead.net_area_qty, 
			modu_rec_ordhead.super_code, 
			modu_rec_ordhead.entry_code, 
			modu_rec_ordhead.entry_date, 
			modu_rec_ordhead.rev_date, 
			modu_rec_ordhead.rev_num, 
			cust_hold_text, 
			order_hold_text 
			attribute(yellow) 
		ELSE 
			DISPLAY BY NAME modu_rec_ordhead.cust_code, 
			modu_rec_customer.name_text, 
			modu_rec_customer.term_code, 
			modu_rec_ordhead.order_num, 
			modu_rec_ordhead.ord_ind, 
			modu_rec_ordhead.order_date, 
			modu_rec_customer.type_code, 
			modu_rec_customer.tele_text, 
			modu_rec_ordhead.status_ind, 
			modu_rec_ordhead.hold_code, 
			modu_rec_ordhead.ship_addr1_text, 
			modu_rec_ordhead.ship_addr2_text, 
			modu_rec_ordhead.ship_city_text, 
			modu_rec_ordhead.ship_state_code, 
			modu_rec_ordhead.ship_post_code, 
			modu_rec_ordhead.map_reference, 
			modu_rec_ordhead.ord_text, 
			modu_rec_ordhead.ship_date, 
			modu_rec_ordhead.last_del_date, 
			modu_rec_ordhead.last_del_num, 
			pr_delivhead.pick_num, 
			modu_rec_ordhead.ware_code, 
			modu_rec_ordhead.cart_area_code, 
			modu_rec_ordhead.territory_code, 
			modu_rec_ordhead.sale_code, 
			modu_rec_ordhead.job_territory, 
			modu_rec_ordhead.quote_num, 
			modu_rec_ordhead.quote_date, 
			modu_rec_ordhead.quote_amt, 
			modu_rec_ordhead.net_area_qty, 
			modu_rec_ordhead.super_code, 
			modu_rec_ordhead.entry_code, 
			modu_rec_ordhead.entry_date, 
			modu_rec_ordhead.rev_date, 
			modu_rec_ordhead.rev_num, 
			cust_hold_text, 
			order_hold_text 
			attribute(green) 
		END IF 
	END IF 
END FUNCTION 

########################################################################
#
#      W15b - Order Inquiry
#                  allows the user TO view Order Information - Job Address
#

FUNCTION disp_job_addr(p_cmpy, pr_order_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	msgresp LIKE language.yes_flag 

	OPEN WINDOW w178 with FORM "W178" 
	CALL windecoration_w("W178") -- albo kd-767 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	DISPLAY BY NAME modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference, 
	modu_rec_ordhead.contact_text, 
	modu_rec_ordhead.tele_text, 
	modu_rec_ordhead.mobile_phone, 
	modu_rec_ordhead.ord_text 

	CALL eventsuspend() # LET msgresp=kandoomsg("U",1,"") 
	CLOSE WINDOW w178 
END FUNCTION 
###########################################################################
# END FUNCTION disp_ordhead(p_cmpy, pr_order_num) 
#
#
###########################################################################

########################################################################
#      W15c - Order Inquiry
#                  allows the user TO view Order Information - Additional Info
###########################################################################

###########################################################################
# FUNCTION disp_add_info(p_cmpy, pr_order_num) 
#
#
###########################################################################
FUNCTION disp_add_info(p_cmpy, pr_order_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_territory RECORD LIKE territory.*, 
	pr_cartarea RECORD LIKE cartarea.*, 
	pr_salesperson RECORD LIKE salesperson.*, 
	pr_territory2 RECORD LIKE territory.*, 
	pr_location RECORD LIKE location.*, 
	pr_userlocn RECORD LIKE userlocn.*, 
	pi_customer RECORD LIKE customer.*, 
	pi_warehouse RECORD LIKE warehouse.*, 
	pr_suburb RECORD LIKE suburb.*, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	msgresp LIKE language.yes_flag 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO pr_location.* FROM location 
	WHERE cmpy_code = p_cmpy 
	AND locn_code = modu_rec_ordhead.locn_code 

	IF modu_rec_ordhead.internal_cust_code IS NOT NULL AND modu_rec_ordhead.internal_ware_code IS NOT NULL THEN 
		OPEN WINDOW w415 with FORM "W415" 
		CALL windecoration_w("W415") -- albo kd-767 
		INITIALIZE pi_customer.* TO NULL 
		INITIALIZE pi_warehouse.* TO NULL 
		SELECT * INTO pi_customer.* FROM customer 
		WHERE cust_code = modu_rec_ordhead.internal_cust_code 
		AND cmpy_code = p_cmpy 
		SELECT * INTO pi_warehouse.* FROM warehouse 
		WHERE ware_code = modu_rec_ordhead.internal_ware_code 
		AND cmpy_code = p_cmpy 
	ELSE 
		OPEN WINDOW w104 with FORM "W104" 
		CALL windecoration_w("W104") -- albo kd-767 
	END IF 
	
	INITIALIZE pr_suburb.* TO NULL 
	SELECT * INTO pr_suburb.* FROM suburb 
	WHERE cmpy_code = p_cmpy 
	AND suburb_text = modu_rec_ordhead.ship_city_text 
	AND state_code = modu_rec_ordhead.ship_state_code 
	AND post_code = modu_rec_ordhead.ship_post_code 

	INITIALIZE pr_territory.* TO NULL 
	SELECT * INTO pr_territory.* FROM territory 
	WHERE cmpy_code = p_cmpy 
	AND terr_code = modu_rec_ordhead.territory_code 

	INITIALIZE pr_cartarea.* TO NULL 
	SELECT * INTO pr_cartarea.* FROM cartarea 
	WHERE cmpy_code = p_cmpy 
	AND cart_area_code = modu_rec_ordhead.cart_area_code 

	INITIALIZE pr_salesperson.* TO NULL 
	SELECT * INTO pr_salesperson.* FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = modu_rec_ordhead.sale_code 

	SELECT * INTO pr_territory2.* FROM territory 
	WHERE terr_code = modu_rec_ordhead.job_territory 
	AND cmpy_code = p_cmpy 

	DISPLAY BY NAME 
		pr_location.locn_code, 
		modu_rec_ordhead.cart_area_code, 
		modu_rec_ordhead.job_territory, 
		modu_rec_ordhead.territory_code, 
		modu_rec_ordhead.sale_code, 
		modu_rec_ordhead.delivery_ind, 
		modu_rec_ordhead.initials_text, 
		modu_rec_ordhead.dwell_num 

	DISPLAY 
		pr_location.desc_text, 
		pr_cartarea.desc_text, 
		pr_territory2.desc_text, 
		pr_territory.desc_text, 
		pr_salesperson.name_text 
	TO 
		locn_desc, 
		cart_desc, 
		job_terr_desc, 
		terr_desc, 
		name_desc 

	IF modu_rec_ordhead.internal_cust_code IS NOT NULL AND modu_rec_ordhead.internal_ware_code IS NOT NULL THEN 
		DISPLAY BY NAME 
			modu_rec_ordhead.internal_cust_code, 
			modu_rec_ordhead.internal_ware_code 

		DISPLAY 
			pi_customer.name_text, 
			pi_warehouse.desc_text 
		TO 
			name_text, 
			ware_text 

	END IF 

	#LET msgresp = kandoomsg("U",1,"") CALL eventsuspend() 

	IF modu_rec_ordhead.internal_cust_code IS NOT NULL AND modu_rec_ordhead.internal_ware_code IS NOT NULL THEN 
		CLOSE WINDOW w415 
	ELSE 
		CLOSE WINDOW w104 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION disp_add_info(p_cmpy, pr_order_num) 
###########################################################################
 

########################################################################
#
#      W15d - Order Inquiry
#                  allows the user TO view Order Information - Line Items
#

###########################################################################
# FUNCTION disp_lines(pr_cmpy_code, pr_order_num)
#
# 
###########################################################################
FUNCTION disp_lines(pr_cmpy_code, pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_product RECORD LIKE product.*, 
	pa_orderline array[300] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE orderline.line_num, 
		part_code LIKE orderline.part_code, 
		ware_code LIKE orderline.ware_code, 
		order_qty LIKE orderline.order_qty, 
		uom_code LIKE orderline.uom_code, 
		disc_per LIKE orderline.disc_per, 
		unit_price_amt LIKE orderline.unit_price_amt, 
		price_uom_code LIKE orderline.price_uom_code, 
		line_tot_amt LIKE orderline.line_tot_amt 
	END RECORD, 
	pr_scroll_flag CHAR(1), 
	i, j, pr_curr, pr_cnt, idx, scrn SMALLINT 

	LET glob_rec_kandoouser.cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 

	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW w110 with FORM "W110" 
	CALL windecoration_w("W110") -- albo kd-767 

	SELECT * INTO pr_warehouse.* FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = modu_rec_ordhead.ware_code 

	DISPLAY BY NAME modu_rec_ordhead.ord_pallet_qty 

	LET idx = 0 
	DECLARE c_ordlines CURSOR FOR 
	SELECT * FROM orderline 
	WHERE order_num = pr_order_num 
	AND part_code IS NOT NULL 
	ORDER BY line_num 

	FOREACH c_ordlines INTO modu_rec_orderline.* 
		LET idx = idx + 1 
		LET pa_orderline[idx].line_num = modu_rec_orderline.line_num 
		LET pa_orderline[idx].part_code = modu_rec_orderline.part_code 
		LET pa_orderline[idx].ware_code = modu_rec_orderline.ware_code 
		LET pa_orderline[idx].order_qty = modu_rec_orderline.order_qty 
		LET pa_orderline[idx].uom_code = modu_rec_orderline.uom_code 
		LET pa_orderline[idx].disc_per = modu_rec_orderline.disc_per 
		LET modu_rec_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, modu_rec_orderline.part_code, 
		modu_rec_orderline.uom_code, 
		modu_rec_orderline.price_uom_code,1) 
		IF modu_rec_conversion_qty <= 0 THEN 
			LET pa_orderline[idx].unit_price_amt = NULL 
		ELSE 
			LET pa_orderline[idx].unit_price_amt = modu_rec_orderline.unit_price_amt 
			* modu_rec_conversion_qty 
		END IF 
		LET pa_orderline[idx].price_uom_code = modu_rec_orderline.price_uom_code 
		LET pa_orderline[idx].line_tot_amt = modu_rec_orderline.line_tot_amt 
		IF modu_rec_orderline.status_ind = "4" THEN 
			LET pa_orderline[idx].scroll_flag = "*" 
		END IF 

		IF idx = 300 THEN 
			LET msgresp = kandoomsg("W",9021,idx)		#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_orderline[1].* TO NULL 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(idx) 
	CALL disp_totals() 
	LET msgresp = kandoomsg("W",1095,"") #1095  RETURN on line TO view

	INPUT ARRAY pa_orderline WITHOUT DEFAULTS FROM sr_orderline.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-orderline-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F7) 
			CALL add_chargs(glob_rec_kandoouser.cmpy_code,pr_order_num) 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_orderline[idx].scroll_flag 
			DISPLAY pa_orderline[idx].* TO sr_orderline[scrn].* 

			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = pa_orderline[idx].part_code 
			AND cmpy_code = p_cmpy 
			LET modu_rec_orderline.desc_text = pr_product.desc_text 
			DISPLAY BY NAME modu_rec_orderline.desc_text, 
			pr_product.desc2_text 

		AFTER FIELD scroll_flag 
			--#IF fgl_lastkey() = fgl_keyval("accept")
			--#AND fgl_fglgui() THEN
			--#   NEXT FIELD line_num
			--#END IF
			LET pa_orderline[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_orderline[idx].scroll_flag TO 
			sr_orderline[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_orderline[idx+1].line_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD line_num 
			IF pa_orderline[idx].part_code IS NOT NULL THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET modu_rec_orderline.line_num = pa_orderline[idx].line_num 
				CALL orderlines() 
			END IF 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY pa_orderline[idx].* TO sr_orderline[scrn].* 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW w110 
END FUNCTION 
###########################################################################
# END FUNCTION disp_lines(pr_cmpy_code, pr_order_num)
###########################################################################


###########################################################################
# FUNCTION orderlines()
#
# 
###########################################################################
FUNCTION orderlines() 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_category RECORD LIKE category.*, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_supply RECORD LIKE supply.*, 
	pr_uom RECORD LIKE uom.*, 
	pr_cfwd_qty LIKE ordcallfwd.call_fwd_qty, 
	save_part LIKE orderline.part_code, 
	save_ware LIKE orderline.ware_code, 
	save_uom LIKE orderline.uom_code, 
	save_qty LIKE orderline.order_qty, 
	save_parent,pr_parent,pr_filler,pr_flex_part LIKE product.part_code, 
	pr_flex_num SMALLINT, 
	pr_unit_price_amt LIKE orderline.unit_price_amt, 
	pr_list_price_amt LIKE orderline.list_price_amt, 
	query_text CHAR(150), 
	line_ok CHAR(1), 
	pr_conv_rate, pr_save_freight FLOAT, 
	pr_uom_text CHAR(30) 

	OPEN WINDOW w187 with FORM "W187" 
	CALL windecoration_w("W187") -- albo kd-767 
	SELECT * INTO modu_rec_orderline.* FROM orderline 
	WHERE line_num = modu_rec_orderline.line_num 
	AND order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = p_cmpy 
	LET pr_save_freight = modu_rec_orderline.freight_amt 

	IF modu_rec_ordhead.cartage_ind = 1 OR modu_rec_ordhead.ord_ind = '9' THEN 
		SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
		WHERE line_num = modu_rec_orderline.line_num 
		AND order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 
		AND order_rate_type = "CRP" 
		LET modu_rec_orderline.freight_amt = modu_rec_ordlinerate.unit_price_amt 
	END IF 
	
	IF modu_rec_orderline.part_code IS NOT NULL THEN 
		SELECT * INTO pr_product.* FROM product 
		WHERE part_code = modu_rec_orderline.part_code 
		AND cmpy_code = p_cmpy 
		LET modu_rec_orderline.desc_text = pr_product.desc_text 
	END IF 
	
	LET pr_conv_rate = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, 
	modu_rec_orderline.part_code, 
	modu_rec_orderline.uom_code, 
	modu_rec_orderline.price_uom_code, 
	1) 
	LET modu_rec_orderline.freight_amt = modu_rec_orderline.freight_amt * pr_conv_rate 
	DISPLAY BY NAME modu_rec_orderline.part_code, 
	modu_rec_orderline.ware_code, 
	modu_rec_orderline.km_qty, 
	modu_rec_orderline.order_qty, 
	modu_rec_orderline.sched_qty, 
	modu_rec_orderline.inv_qty, 
	modu_rec_orderline.back_qty, 
	modu_rec_orderline.freight_amt, 
	modu_rec_orderline.uom_code, 
	modu_rec_orderline.price_uom_code, 
	modu_rec_orderline.desc_text, 
	pr_product.desc2_text, 
	modu_rec_orderline.offer_code, 
	modu_rec_orderline.return_qty, 
	modu_rec_orderline.auth_code 

	LET modu_rec_orderline.freight_amt = pr_save_freight 
	DISPLAY modu_rec_orderline.price_uom_code TO cartage_uom_code 

	SELECT desc_text INTO pr_uom_text FROM uom 
	WHERE uom_code = modu_rec_orderline.price_uom_code 
	AND cmpy_code = p_cmpy 
	DISPLAY BY NAME pr_uom_text 

	INITIALIZE pr_uom.* TO NULL 
	SELECT * INTO pr_uom.* FROM uom 
	WHERE cmpy_code = p_cmpy 
	AND uom_code = modu_rec_orderline.uom_code 
	DISPLAY pr_uom.desc_text TO uom_desc1 

	INITIALIZE pr_uom.* TO NULL 
	SELECT * INTO pr_uom.* FROM uom 
	WHERE cmpy_code = p_cmpy 
	AND uom_code = modu_rec_orderline.price_uom_code 
	DISPLAY pr_uom.desc_text TO uom_desc2 

	LET modu_rec_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, modu_rec_orderline.part_code, 
	modu_rec_orderline.uom_code, 
	modu_rec_orderline.price_uom_code,1) 
	
	IF modu_rec_conversion_qty <= 0 THEN 
		LET pr_unit_price_amt = NULL 
		LET pr_list_price_amt = NULL 
	ELSE 
		LET pr_unit_price_amt = modu_rec_orderline.unit_price_amt * modu_rec_conversion_qty 
		LET pr_list_price_amt = modu_rec_orderline.list_price_amt * modu_rec_conversion_qty 
	END IF 
	DISPLAY BY NAME modu_rec_orderline.level_ind, 
	modu_rec_orderline.line_tot_amt 

	DISPLAY pr_unit_price_amt, 
	pr_list_price_amt 
	TO unit_price_amt, 
	list_price_amt 

	DISPLAY BY NAME modu_rec_orderline.disc_per 

	MENU " Pricing Details" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","wordwin","menu-Pricing_Details-1") -- albo 
			NEXT option "Exit" 
		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Pricing" " Show Price Breakdown details " 
			CALL disp_pricebreak() 
			NEXT option "Exit" 
		COMMAND KEY (interrupt,"E") "Exit" " Exit FROM Order Line " 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW w187 
END FUNCTION 
###########################################################################
# END FUNCTION orderlines()
###########################################################################


###########################################################################
# FUNCTION disp_totals()
#
#
###########################################################################
FUNCTION disp_totals() 
	DEFINE 
	pallet_total LIKE orderline.line_tot_amt, 
	line_total LIKE orderline.line_tot_amt, 
	order_total LIKE orderline.line_tot_amt, 
	pr_labourline_cnt SMALLINT 

	###-this IS the same FUNCTION as W11c.4gl disp_totals -###
	###-this FUNCTION selects FROM the real tables NOT temp###

	SELECT sum(line_tot_amt) INTO line_total FROM orderline 
	WHERE order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = p_cmpy 
	AND status_ind != "4" 
	AND part_code IS NOT NULL 

	SELECT sum(line_tot_amt) INTO modu_rec_ordhead.add_amt FROM orderline 
	WHERE order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = p_cmpy 
	AND part_code IS NULL 

	IF modu_rec_ordhead.ord_ind != "8" THEN 
		LET pallet_total = modu_rec_ordhead.ord_pallet_qty * modu_rec_ordhead.pallet_price_amt 
	ELSE 
		LET pallet_total = NULL 
	END IF 

	IF line_total IS NULL THEN 
		LET line_total = 0 
	END IF 

	IF pallet_total IS NULL THEN 
		LET pallet_total = 0 
	END IF 

	IF modu_rec_ordhead.add_amt IS NULL THEN 
		LET modu_rec_ordhead.add_amt = 0 
	END IF 

	IF modu_rec_ordhead.freight_amt IS NULL THEN 
		LET modu_rec_ordhead.freight_amt = 0 
	END IF 

	IF modu_rec_ordhead.quote_amt IS NULL THEN 
		LET modu_rec_ordhead.quote_amt = 0 
	END IF 

	IF modu_rec_ordhead.nett_weight_amt IS NULL THEN 
		LET modu_rec_ordhead.nett_weight_amt = 0 
	END IF 

	LET order_total = line_total + 
	modu_rec_ordhead.add_amt + 
	pallet_total + 
	modu_rec_ordhead.freight_amt 

	IF order_total IS NULL THEN 
		LET order_total = 0 
	END IF 

	DISPLAY BY NAME modu_rec_ordhead.ord_pallet_qty, 
	modu_rec_ordhead.nett_weight_amt, 
	#line_total,
	modu_rec_ordhead.add_amt, 
	pallet_total, 
	modu_rec_ordhead.freight_amt, 
	modu_rec_ordhead.quote_amt, 
	order_total 
	attribute(magenta) 
END FUNCTION 
###########################################################################
# END FUNCTION disp_totals()
###########################################################################


###########################################################################
# FUNCTION disp_pricebreak()
#
#
###########################################################################
FUNCTION disp_pricebreak() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	ps_orderline RECORD LIKE orderline.*, 
	modu_rec_ordlinerate RECORD LIKE ordlinerate.*, 
	pr_uom RECORD LIKE uom.*, 
	pr_waregrp RECORD LIKE waregrp.*, 
	pr_waregrp_code LIKE warehouse.waregrp_code, 
	pa_ordlinerate array[10] OF RECORD 
		short_desc_text LIKE ordrates.short_desc_text, 
		unit_price_amt LIKE ordlinerate.unit_price_amt, 
		ext_price_amt LIKE orderline.ext_price_amt 
	END RECORD, 
	pa_type array[10] OF RECORD 
		rate_type LIKE ordlinerate.order_rate_type 
	END RECORD, 
	pr_conv_qty LIKE uomconv.conversion_qty, 
	pr_save_amt LIKE ordlinerate.unit_price_amt, 
	pr_save_ext LIKE ordlinerate.unit_price_amt, 
	pr_tot_unit_amt LIKE ordlinerate.unit_price_amt, 
	pr_tot_ext_amt LIKE orderline.ext_price_amt, 
	i, j, idx, uom_flag, rates_num, scrn SMALLINT, 
	sel_text CHAR(500) 

	IF modu_rec_orderline.line_num IS NULL THEN 
		SELECT count(*) INTO rates_num FROM ordlinerate 
		WHERE line_num IS NULL 
		AND order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 
	ELSE 
		SELECT count(*) INTO rates_num FROM ordlinerate 
		WHERE line_num = modu_rec_orderline.line_num 
		AND order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 
	END IF 
	IF rates_num > 5 THEN 
		OPEN WINDOW w181 with FORM "W181" # scrolling 6 LINES 
		CALL windecoration_w("W181") -- albo kd-767 
	END IF 
	IF rates_num = 5 THEN 
		OPEN WINDOW w181 with FORM "W181a" # 5 line ARRAY 
		CALL windecoration_w("W181a") -- albo kd-767 
	END IF 
	IF rates_num = 4 THEN 
		OPEN WINDOW w181 with FORM "W181b" # 4 line ARRAY 
		CALL windecoration_w("W181b") -- albo kd-767 
	END IF 

	IF rates_num = 3 THEN 
		OPEN WINDOW w181 with FORM "W181c" # 3 line ARRAY 
		CALL windecoration_w("W181c") -- albo kd-767 
	END IF 

	IF rates_num < 3 THEN 
		OPEN WINDOW w181 with FORM "W181d" # 2 line ARRAY 
		CALL windecoration_w("W181d") -- albo kd-767 
	END IF 

	LET ps_orderline.* = modu_rec_orderline.* 
	LET pr_conv_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, 
	ps_orderline.part_code, 
	ps_orderline.uom_code, 
	ps_orderline.price_uom_code,1) 

	IF pr_conv_qty < 0 THEN 
		LET pr_conv_qty = 0 
	END IF 
	LET pr_tot_unit_amt = 0 
	LET pr_tot_ext_amt = 0 
	DISPLAY BY NAME ps_orderline.price_uom_code 

	IF ps_orderline.line_num IS NULL THEN 
		SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
		WHERE line_num IS NULL 
		AND order_rate_type = "PRP" 
		AND order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 
	ELSE 
		SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
		WHERE line_num = ps_orderline.line_num 
		AND order_rate_type = "PRP" 
		AND order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 
	END IF 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9292,"") 
		#9292 " Logic error: Product Price Corruption"
		CLOSE WINDOW w181 
		RETURN 
	END IF 

	LET pa_type[1].rate_type = "PRP" 
	LET pa_ordlinerate[1].short_desc_text = "Product" 
	LET pa_ordlinerate[1].unit_price_amt = modu_rec_ordlinerate.unit_price_amt	* pr_conv_qty 
	LET pa_ordlinerate[1].ext_price_amt = (modu_rec_ordlinerate.unit_price_amt	* ps_orderline.order_qty) 
	LET pr_tot_unit_amt = pr_tot_unit_amt + pa_ordlinerate[1].unit_price_amt 
	LET pr_tot_ext_amt = pr_tot_ext_amt + pa_ordlinerate[1].ext_price_amt 
	LET pr_waregrp_code = get_waregrp(glob_rec_kandoouser.cmpy_code,modu_rec_ordhead.entry_code) 

	IF pr_waregrp_code IS NOT NULL THEN 
		SELECT * INTO pr_waregrp.* FROM waregrp 
		WHERE cmpy_code = p_cmpy 
		AND waregrp_code = pr_waregrp_code 

		IF modu_rec_ordhead.cartage_ind <> '1'	AND modu_rec_ordhead.ord_ind != '9' THEN 
			LET idx = 1 
		ELSE 
			IF ps_orderline.line_num IS NULL THEN 
				SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
				WHERE line_num IS NULL 
				AND order_rate_type = "CRP" 
				AND order_num = modu_rec_ordhead.order_num 
				AND cmpy_code = p_cmpy 
			ELSE 
				SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
				WHERE line_num = ps_orderline.line_num 
				AND order_rate_type = "CRP" 
				AND order_num = modu_rec_ordhead.order_num 
				AND cmpy_code = p_cmpy 
			END IF 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("W",9294,"")	#9294 " Logic error: Cartage Price Corruption"
				CLOSE WINDOW w181 
				RETURN 
			END IF 

			LET pa_type[2].rate_type = "CRP" 
			LET pa_ordlinerate[2].short_desc_text = "Cartage" 
			LET pa_ordlinerate[2].unit_price_amt = modu_rec_ordlinerate.unit_price_amt	* pr_conv_qty 
			LET pa_ordlinerate[2].ext_price_amt = (modu_rec_ordlinerate.unit_price_amt	* ps_orderline.order_qty) 
			LET pr_tot_unit_amt = pr_tot_unit_amt + pa_ordlinerate[2].unit_price_amt 
			LET pr_tot_ext_amt = pr_tot_ext_amt + pa_ordlinerate[2].ext_price_amt 
			LET idx = 2 
		END IF 
	END IF 

	IF modu_rec_ordhead.ord_ind = "9" THEN 
		IF ps_orderline.line_num IS NULL THEN 
			SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
			WHERE line_num IS NULL 
			AND order_rate_type = "LRP" 
			AND order_num = modu_rec_ordhead.order_num 
			AND cmpy_code = p_cmpy 
		ELSE 
			SELECT * INTO modu_rec_ordlinerate.* FROM ordlinerate 
			WHERE line_num = ps_orderline.line_num 
			AND order_rate_type = "LRP" 
			AND order_num = modu_rec_ordhead.order_num 
			AND cmpy_code = p_cmpy 
		END IF 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("W",9916,"")	#9916 " Logic error: Labour Price Corruption"
			CLOSE WINDOW w181 
			RETURN 
		END IF 

		LET pa_type[idx+1].rate_type = "LRP" 
		LET pa_ordlinerate[idx+1].short_desc_text = "Labour" 
		LET pa_ordlinerate[idx+1].unit_price_amt = modu_rec_ordlinerate.unit_price_amt	* pr_conv_qty 
		LET pa_ordlinerate[idx+1].ext_price_amt = (modu_rec_ordlinerate.unit_price_amt	* ps_orderline.order_qty) 
		LET pr_tot_unit_amt = pr_tot_unit_amt + pa_ordlinerate[idx+1].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt + pa_ordlinerate[idx+1].ext_price_amt 
		LET idx = idx+1 
	END IF 

	IF modu_rec_ordhead.ord_ind = "9" THEN 
		IF ps_orderline.line_num IS NULL THEN 
			LET sel_text = 
			"SELECT * FROM ordlinerate ", 
			"WHERE line_num IS NULL ", 
			" AND order_rate_type != \"PRP\" ", 
			" AND order_rate_type != \"CRP\" ", 
			" AND order_rate_type != \"LRP\" ", 
			" AND order_num = " ,modu_rec_ordhead.order_num , 
			" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
		ELSE 
			LET sel_text = 
			"SELECT * FROM ordlinerate ", 
			" WHERE line_num = ", ps_orderline.line_num, 
			" AND order_rate_type != \"PRP\" ", 
			" AND order_rate_type != \"CRP\" ", 
			" AND order_rate_type != \"LRP\" ", 
			" AND order_num = " ,modu_rec_ordhead.order_num , 
			" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
		END IF 
		PREPARE s1_ordlinerate FROM sel_text 
		DECLARE c1_ordlinerate CURSOR FOR s1_ordlinerate 

		FOREACH c1_ordlinerate INTO modu_rec_ordlinerate.* 
			LET idx = idx + 1 
			SELECT short_desc_text INTO pa_ordlinerate[idx].short_desc_text 
			FROM ordrates 
			WHERE cmpy_code = p_cmpy 
			AND rate_type_code = modu_rec_ordlinerate.order_rate_type 
			AND ord_ind = modu_rec_ordhead.ord_ind 
			IF status = notfound THEN 
				LET pa_ordlinerate[idx].short_desc_text = "***************" 
			END IF 
			LET pa_type[idx].rate_type = modu_rec_ordlinerate.order_rate_type 
			LET pa_ordlinerate[idx].unit_price_amt = modu_rec_ordlinerate.unit_price_amt * pr_conv_qty 
			LET pa_ordlinerate[idx].ext_price_amt = (modu_rec_ordlinerate.unit_price_amt * ps_orderline.order_qty) 
			LET pr_tot_unit_amt = pr_tot_unit_amt	+ pa_ordlinerate[idx].unit_price_amt 
			LET pr_tot_ext_amt = pr_tot_ext_amt + pa_ordlinerate[idx].ext_price_amt 
			IF idx = 10 THEN 
				LET msgresp = kandoomsg("W",9021,idx)	#9021 First idx entries Selected Only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
	ELSE
	 
		IF ps_orderline.line_num IS NULL THEN 
			LET sel_text = 
				"SELECT * FROM ordlinerate ", 
				"WHERE line_num IS NULL ", 
				" AND order_rate_type != \"PRP\" ", 
				" AND order_rate_type != \"CRP\" ", 
				" AND order_num = " ,modu_rec_ordhead.order_num , 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
		ELSE 
			LET sel_text = 
				"SELECT * FROM ordlinerate ", 
				" WHERE line_num = ", ps_orderline.line_num, 
				" AND order_rate_type != \"PRP\" ", 
				" AND order_rate_type != \"CRP\" ", 
				" AND order_num = " ,modu_rec_ordhead.order_num , 
				" AND cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
		END IF 

		PREPARE s2_ordlinerate FROM sel_text 
		DECLARE c2_ordlinerate CURSOR FOR s2_ordlinerate 
		FOREACH c2_ordlinerate INTO modu_rec_ordlinerate.* 
			LET idx = idx + 1 
			SELECT short_desc_text INTO pa_ordlinerate[idx].short_desc_text 
			FROM ordrates 
			WHERE cmpy_code = p_cmpy 
			AND rate_type_code = modu_rec_ordlinerate.order_rate_type 
			AND ord_ind = modu_rec_ordhead.ord_ind 
			IF status = notfound THEN 
				LET pa_ordlinerate[idx].short_desc_text = "***************" 
			END IF 
			LET pa_type[idx].rate_type = modu_rec_ordlinerate.order_rate_type 
			LET pa_ordlinerate[idx].unit_price_amt = modu_rec_ordlinerate.unit_price_amt * pr_conv_qty 
			LET pa_ordlinerate[idx].ext_price_amt = (modu_rec_ordlinerate.unit_price_amt * ps_orderline.order_qty) 
			LET pr_tot_unit_amt = pr_tot_unit_amt + pa_ordlinerate[idx].unit_price_amt 
			LET pr_tot_ext_amt = pr_tot_ext_amt + pa_ordlinerate[idx].ext_price_amt 
			
			IF idx = 10 THEN 
				LET msgresp = kandoomsg("W",9021,idx)	#9021 First idx entries Selected Only"
				EXIT FOREACH 
			END IF 
			
		END FOREACH 
	END IF 
	
	IF idx = 0 THEN 
		#Something went wrong
		CLOSE WINDOW w181 
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36, 
	NEXT KEY f36 
	CALL set_count(idx) 

	DISPLAY pr_tot_unit_amt, pr_tot_ext_amt 
	TO tot_unit_amt, tot_ext_amt 

	LET msgresp = kandoomsg("W",1008,"") 

	DISPLAY ARRAY pa_ordlinerate TO sr_ordlinerate.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-ordlinerate") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

	CLOSE WINDOW w181 

	OPTIONS NEXT KEY f3 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION disp_pricebreak()
###########################################################################


###########################################################################
# FUNCTION add_chargs(p_cmpy,pr_order)
#
#
###########################################################################
FUNCTION add_chargs(p_cmpy,pr_order) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	p_cmpy CHAR(2), 
	pr_order INTEGER, 
	pa_charges array[100] OF RECORD 
		scroll_flag CHAR(1), 
		desc_text LIKE orderline.desc_text, 
		unit_price_amt LIKE orderline.unit_price_amt, 
		order_qty LIKE orderline.order_qty, 
		inv_qty LIKE orderline.inv_qty, 
		line_tot_amt LIKE orderline.line_tot_amt, 
		ext_cost_amt LIKE orderline.ext_cost_amt 
	END RECORD, 
	pr_addcharge RECORD LIKE addcharge.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	winds_text CHAR(30), 
	idx,scrn,cnt SMALLINT 

	OPEN WINDOW w296a with FORM "W296a" 
	CALL windecoration_w("W296a") -- albo kd-767 

	DECLARE c2_orderline CURSOR FOR 
	SELECT * FROM orderline 
	WHERE part_code IS NULL 
	AND order_num = pr_order 
	AND cmpy_code = p_cmpy 
	LET idx = 0 
	FOREACH c2_orderline INTO modu_rec_orderline.* 
		LET idx = idx + 1 
		IF modu_rec_orderline.status_ind = "C" THEN 
			LET pa_charges[idx].scroll_flag = modu_rec_orderline.status_ind 
		END IF 
		SELECT unique 1 FROM addcharge 
		WHERE cmpy_code = p_cmpy 
		AND desc_code = modu_rec_orderline.desc_text 
		AND process_ind = "1" 
		IF status = 0 THEN 
			LET pa_charges[idx].order_qty = NULL 
			LET pa_charges[idx].inv_qty = NULL 
			LET pa_charges[idx].unit_price_amt = NULL 
			LET pa_charges[idx].ext_cost_amt = NULL 
		ELSE 
			LET pa_charges[idx].order_qty = modu_rec_orderline.order_qty 
			LET pa_charges[idx].inv_qty = modu_rec_orderline.inv_qty 
			LET pa_charges[idx].unit_price_amt = modu_rec_orderline.unit_price_amt 
			LET pa_charges[idx].ext_cost_amt = modu_rec_orderline.ext_cost_amt 
		END IF 
		LET pa_charges[idx].desc_text = modu_rec_orderline.desc_text 
		LET pa_charges[idx].line_tot_amt = modu_rec_orderline.line_tot_amt 

	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1008,"") 
	#1008 ESC TO Continue
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	DISPLAY ARRAY pa_charges TO sr_charges.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-charges") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

	CLOSE WINDOW w296a 
END FUNCTION 
###########################################################################
# END FUNCTION add_chargs(p_cmpy,pr_order)
###########################################################################



#                                                                      #
########################################################################
#
#      W15e - Order Inquiry
#                  allows the user TO view Order Information - Order Status
#

###########################################################################
# FUNCTION disp_status(p_cmpy, pr_order_num)
#
#
###########################################################################
FUNCTION disp_status(p_cmpy, pr_order_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_customer RECORD LIKE customer.*, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_orderline RECORD LIKE orderline.*, 
	pr_product RECORD LIKE product.*, 
	pr_loadline RECORD LIKE loadline.*, 
	pa_orderline array[300] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE orderline.line_num, 
		part_code LIKE orderline.part_code, 
		ware_code LIKE orderline.ware_code, 
		order_qty LIKE orderline.order_qty, 
		back_qty LIKE orderline.back_qty, 
		sched_qty LIKE orderline.sched_qty, 
		hold_ind CHAR(1), 
		picked_qty LIKE orderline.picked_qty, 
		inv_qty LIKE orderline.inv_qty, 
		uom_code LIKE orderline.uom_code, 
		desc_text LIKE product.desc_text, 
		desc2_text LIKE product.desc2_text, 
		return_ind CHAR(1) 
	END RECORD, 
	msgresp LIKE language.yes_flag, 
	idx, scrn SMALLINT 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 

	OPEN WINDOW w179 with FORM "W179" 
	CALL windecoration_w("W179") -- albo kd-767 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_ordhead.order_num, 
	modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference, 
	modu_rec_ordhead.ord_text, 
	modu_rec_ordhead.order_date 

	DECLARE c1_orderline CURSOR FOR 
	SELECT * FROM orderline 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = modu_rec_ordhead.cust_code 
	AND order_num = modu_rec_ordhead.order_num 
	LET idx = 0 
	FOREACH c1_orderline INTO modu_rec_orderline.* 
		IF modu_rec_orderline.part_code IS NULL THEN 
			SELECT unique 1 FROM addcharge 
			WHERE cmpy_code = p_cmpy 
			AND desc_code = modu_rec_orderline.desc_text 
			AND process_ind = "1" 
			IF status = 0 THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LET idx = idx + 1 

		IF idx > 300 THEN 
			EXIT FOREACH 
		END IF 

		LET pa_orderline[idx].line_num = modu_rec_orderline.line_num 
		LET pa_orderline[idx].part_code = modu_rec_orderline.part_code 
		LET pa_orderline[idx].ware_code = modu_rec_orderline.ware_code 
		LET pa_orderline[idx].order_qty = modu_rec_orderline.order_qty 
		LET pa_orderline[idx].back_qty = modu_rec_orderline.back_qty 
		LET pa_orderline[idx].sched_qty = modu_rec_orderline.sched_qty 
		LET pa_orderline[idx].picked_qty = modu_rec_orderline.picked_qty +	modu_rec_orderline.conf_qty 
		LET pa_orderline[idx].inv_qty = modu_rec_orderline.inv_qty 
		LET pa_orderline[idx].uom_code = modu_rec_orderline.uom_code 

		IF modu_rec_orderline.part_code IS NULL THEN 
			LET pa_orderline[idx].desc_text = modu_rec_orderline.desc_text 
			LET pa_orderline[idx].desc2_text = NULL 
		ELSE 
			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = modu_rec_orderline.part_code 
			AND cmpy_code = p_cmpy 
			LET pa_orderline[idx].desc_text = pr_product.desc_text 
			LET pa_orderline[idx].desc2_text = pr_product.desc2_text 
		END IF 

		IF modu_rec_orderline.status_ind = "4" THEN 
			LET pa_orderline[idx].return_ind = "*" 
		ELSE 
			IF modu_rec_orderline.return_qty != 0 THEN 
				LET pa_orderline[idx].return_ind = "R" 
			END IF 
		END IF 

		DECLARE c_loadline CURSOR FOR 
		SELECT * FROM loadline 
		WHERE cmpy_code = p_cmpy 
		AND order_num = pr_order_num 
		AND order_line_num = modu_rec_orderline.line_num 
		FOREACH c_loadline INTO pr_loadline.* 
			IF pr_loadline.hold_code IS NOT NULL THEN 
				LET pa_orderline[idx].hold_ind = "*" 
			END IF 
		END FOREACH 
	END FOREACH 

	CALL set_count (idx) 
	LET msgresp = kandoomsg("W",1112,"") #1112 F3/F4 Page Down/Up - F8 TO view Planned Loads - ESC TO continue
	INPUT ARRAY pa_orderline WITHOUT DEFAULTS FROM sr_orderline.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-orderline-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F8) 
			CALL disp_load (p_cmpy,pr_order_num,pa_orderline[idx].line_num) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			DISPLAY pa_orderline[idx].* TO sr_orderline[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_orderline[idx].scroll_flag = NULL 
			DISPLAY pa_orderline[idx].scroll_flag 
			TO sr_orderline[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("RETURN") THEN 
				IF pa_orderline[idx+1].line_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD line_num 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY pa_orderline[idx].* TO sr_orderline[scrn].* 


	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w179 
END FUNCTION 
###########################################################################
# END FUNCTION disp_status(p_cmpy, pr_order_num)
###########################################################################

###########################################################################
# FUNCTION disp_load (p_cmpy,pr_order_num,pr_order_line_num)
#
#
###########################################################################
FUNCTION disp_load (p_cmpy,pr_order_num,pr_order_line_num) 
	DEFINE pr_order_num INTEGER, 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_line_num SMALLINT, 
	orig_part LIKE product.part_code, 
	dashes,flex_part LIKE product.part_code, 
	pr_class RECORD LIKE class.*, 
	pr_orderinst RECORD LIKE orderinst.*, 
	modu_rec_orderline RECORD LIKE orderline.*, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	pr_loadline RECORD LIKE loadline.*, 
	pr_loadhead RECORD LIKE loadhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	pr_product RECORD LIKE product.*, 
	pa_loaddet array[300] OF RECORD 
		scroll_flag CHAR(1), 
		load_num LIKE loadhead.load_num, 
		delivery_date LIKE loadhead.delivery_date, 
		ware_code LIKE loadhead.ware_code, 
		transp_type_code LIKE loadhead.transp_type_code, 
		veh_type_code LIKE loadhead.veh_type_code, 
		vehicle_code LIKE loadhead.vehicle_code, 
		driver_code LIKE loadhead.driver_code, 
		load_qty LIKE loadline.load_qty, 
		pallet_qty LIKE loadline.pallet_qty, 
		priority_flag LIKE loadline.priority_flag, 
		hold_code LIKE loadline.hold_code, 
		reason_text LIKE holdreas.reason_text 
	END RECORD, 
	pr_holdreas RECORD LIKE holdreas.*, 
	pr_userlocn RECORD LIKE userlocn.*, 
	pr_location RECORD LIKE location.*, 
	spec_text CHAR(240), 
	instr_cnt SMALLINT, 
	pa_detline array[300] OF RECORD 
		load_num LIKE loadline.load_num, 
		load_line_num LIKE loadline.load_line_num 
	END RECORD, 
	order_hold_text CHAR(30), 
	pr_flex,idx,scrn,i,j,h,x SMALLINT, 
	msgresp LIKE language.yes_flag 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO modu_rec_orderline.* FROM orderline 
	WHERE order_num = pr_order_num 
	AND line_num = pr_order_line_num 
	AND cmpy_code = p_cmpy 
	IF modu_rec_ordhead.hold_code IS NOT NULL THEN 
		LET order_hold_text = "**** ORDER ON HOLD ****" 
	ELSE 
		LET order_hold_text = NULL 
	END IF 
	IF modu_rec_ordhead.ord_pallet_qty IS NULL THEN 
		LET modu_rec_ordhead.ord_pallet_qty = 0 
	END IF 

	IF modu_rec_ordhead.ord_ind <> "8" AND modu_rec_ordhead.ord_pallet_qty > 0 THEN 
		OPEN WINDOW w314 with FORM "W314a" 
		CALL windecoration_w("W314a") -- albo kd-767 
		DISPLAY " Pallets" TO pallet_text 
	ELSE 
		OPEN WINDOW w314 with FORM "W314" 
		CALL windecoration_w("W314") -- albo kd-767 
	END IF 
	
	DECLARE c_orderinst CURSOR FOR 
	SELECT * FROM orderinst 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_order_num 

	LET instr_cnt = 0 
	FOREACH c_orderinst INTO pr_orderinst.* 
		LET instr_cnt = instr_cnt + 1 
		CASE 
			WHEN instr_cnt = 1 
				LET spec_text[1,60] = pr_orderinst.instr_text 
			WHEN instr_cnt = 2 
				LET spec_text[61,120] = pr_orderinst.instr_text 
			WHEN instr_cnt = 3 
				LET spec_text[121,180] = pr_orderinst.instr_text 
			WHEN instr_cnt = 4 
				LET spec_text[181,240] = pr_orderinst.instr_text 
				EXIT FOREACH 
		END CASE 
	END FOREACH 

	SELECT * INTO pr_product.* FROM product 
	WHERE part_code = modu_rec_orderline.part_code 
	AND cmpy_code = p_cmpy 

	SELECT * INTO pr_class.* FROM class 
	WHERE class_code = pr_product.class_code 
	AND cmpy_code = p_cmpy 

	CALL break_prod(p_cmpy,modu_rec_orderline.part_code,pr_product.class_code,1) 
	RETURNING orig_part,dashes,flex_part,pr_flex 

	DISPLAY BY NAME 
		orig_part,flex_part, 
		pr_product.desc_text, 
		pr_product.desc2_text, 
		spec_text, 
		order_hold_text 

	DECLARE c_loaddet CURSOR FOR 
	SELECT loadline.*,loadhead.* FROM loadline,loadhead 
	WHERE loadline.order_num = pr_order_num 
	AND loadline.order_line_num = pr_order_line_num 
	AND loadline.cmpy_code = p_cmpy 
	AND loadhead.cmpy_code = loadline.cmpy_code 
	AND loadhead.load_num = loadline.load_num 
	ORDER BY loadline.load_num,loadline.load_line_num 

	LET idx = 0 
	FOREACH c_loaddet INTO pr_loadline.*,pr_loadhead.* 
		LET idx = idx + 1 
		LET pa_loaddet[idx].load_num = pr_loadhead.load_num 
		LET pa_loaddet[idx].delivery_date = pr_loadhead.delivery_date 
		LET pa_loaddet[idx].ware_code = pr_loadhead.ware_code 
		LET pa_loaddet[idx].transp_type_code = pr_loadhead.transp_type_code 
		LET pa_loaddet[idx].veh_type_code = pr_loadhead.veh_type_code 
		LET pa_loaddet[idx].vehicle_code = pr_loadhead.vehicle_code 
		LET pa_loaddet[idx].driver_code = pr_loadhead.driver_code 
		LET pa_loaddet[idx].load_qty = pr_loadline.load_qty 
		LET pa_loaddet[idx].pallet_qty = pr_loadline.pallet_qty 
		IF modu_rec_ordhead.ord_ind = "8" THEN 
			LET pa_loaddet[idx].pallet_qty = NULL 
		END IF 
		LET pa_loaddet[idx].priority_flag = pr_loadline.priority_flag 
		IF pr_loadline.hold_code IS NOT NULL THEN 
			LET pa_loaddet[idx].hold_code = pr_loadline.hold_code 
			INITIALIZE pr_holdreas.* TO NULL 
			SELECT * INTO pr_holdreas.* FROM holdreas 
			WHERE hold_code = pr_loadline.hold_code 
			AND cmpy_code = p_cmpy 
			LET pa_loaddet[idx].reason_text = pr_holdreas.reason_text 
		END IF 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("W",9021,idx) 
			#9021 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1045,"")	#1045 ESC TO continue
	INPUT ARRAY pa_loaddet WITHOUT DEFAULTS FROM sr_load.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-loaddet") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag
			 
		BEFORE FIELD scroll_flag 
			DISPLAY pa_loaddet[idx].* TO sr_load[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_loaddet[idx].scroll_flag = NULL 
			DISPLAY pa_loaddet[idx].scroll_flag 
			TO sr_load[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("right") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("RETURN") THEN 
				IF pa_loaddet[idx+1].load_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("W",9001,"") 
					#9001 There are no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD load_num 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_loaddet[idx].* TO sr_load[scrn].* 


	END INPUT 
	CLOSE WINDOW w314 
END FUNCTION 
###########################################################################
# END FUNCTION disp_load (p_cmpy,pr_order_num,pr_order_line_num)
###########################################################################

#                                                                      #
########################################################################
#
#      W15f - Order Inquiry
#                  allows the user TO view Order Information - CALL Forwards
#

###########################################################################
# FUNCTION disp_load (p_cmpy,pr_order_num,pr_order_line_num)
#
#
###########################################################################
FUNCTION disp_callfwd(pr_cmpy_code, pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_cfwd_date LIKE ordcallfwd.call_fwd_date, 
	pr_reqd_date LIKE ordcallfwd.reqd_date, 
	pr_status_ind LIKE ordcallfwd.status_ind, 
	pr_instr_text LIKE ordcallfwd.instr_text, 
	pt_ordcallfwd RECORD LIKE ordcallfwd.*, 
	pa_cfwd array[300] OF RECORD 
		scroll_flag CHAR(1), 
		cfwd_date LIKE ordcallfwd.call_fwd_date, 
		reqd_date LIKE ordcallfwd.reqd_date, 
		instr_text LIKE ordcallfwd.instr_text 
	END RECORD, 
	pa_ord_text array[300] OF RECORD 
		ord_text LIKE ordcallfwd.ord_text 
	END RECORD, 
	pr_ord_text LIKE ordcallfwd.ord_text, 
	pr_receipt_num LIKE cashreceipt.cash_num, 
	sum_cfwd LIKE ordcallfwd.call_fwd_qty, 
	i, j, pr_curr, pr_cnt, idx, scrn, pr_counter SMALLINT, 
	pr_scroll_flag CHAR(1), 
	pr_ordcallfwd RECORD LIKE ordcallfwd.*, 
	pr_location RECORD LIKE location.*, 
	pa_cfwd2 array[300] OF RECORD 
		scroll_flag CHAR(1), 
		call_fwd_date LIKE ordcallfwd.call_fwd_date, 
		line_num LIKE ordcallfwd.line_num, 
		part_code LIKE orderline.part_code, 
		desc_text LIKE product.desc_text, 
		call_fwd_qty LIKE ordcallfwd.call_fwd_qty, 
		status_ind LIKE ordcallfwd.status_ind 
	END RECORD, 
	pa_ord_text2 array[300] OF RECORD 
		ord_text LIKE ordcallfwd.ord_text, 
		instr_text LIKE ordcallfwd.instr_text 
	END RECORD, 
	pr_job_address CHAR(60) 

	LET glob_rec_kandoouser.cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 

	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 

	SELECT * INTO pr_location.* FROM location 
	WHERE locn_code = modu_rec_ordhead.locn_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET pr_location.summ_cfwd_flag = "Y" 
	END IF 
	IF pr_location.summ_cfwd_flag = "Y" THEN 
		OPEN WINDOW w137 with FORM "W137" 
		CALL windecoration_w("W137") -- albo kd-767 
		DISPLAY BY NAME modu_rec_ordhead.cust_code, 
		modu_rec_customer.name_text, 
		modu_rec_ordhead.ship_addr1_text, 
		modu_rec_ordhead.ship_addr2_text, 
		modu_rec_ordhead.ship_city_text, 
		modu_rec_ordhead.ship_state_code, 
		modu_rec_ordhead.ship_post_code, 
		modu_rec_ordhead.map_reference 

		LET idx = 0 
		DECLARE c_callfwd CURSOR FOR 
		SELECT unique call_fwd_date, reqd_date, ord_text FROM ordcallfwd 
		WHERE order_num = modu_rec_ordhead.order_num 
		AND cmpy_code = p_cmpy 

		#####################################
		FOREACH c_callfwd INTO pr_cfwd_date, 
			pr_reqd_date, 
			pr_ord_text 
			#####################################
			DECLARE c_instruction CURSOR FOR 
			SELECT instr_text FROM ordcallfwd 
			WHERE order_num = modu_rec_ordhead.order_num 
			AND cmpy_code = p_cmpy 
			AND call_fwd_date = pr_cfwd_date 
			AND ord_text = pr_ord_text 
			OPEN c_instruction 
			FETCH c_instruction INTO pr_instr_text 
			CLOSE c_instruction 
			LET idx = idx + 1 
			LET pa_cfwd[idx].cfwd_date = pr_cfwd_date 
			LET pa_cfwd[idx].reqd_date = pr_reqd_date 
			LET pa_ord_text[idx].ord_text = pr_ord_text 
			LET pa_cfwd[idx].instr_text = pr_instr_text 
			IF idx = 300 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET msgresp = kandoomsg("U",9113,idx)		#U9133 idx records selected
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		CALL set_count(idx) 
		LET msgresp=kandoomsg("W",1007,"")		#1007 F3/F4 - Esc TO continue
		INPUT ARRAY pa_cfwd WITHOUT DEFAULTS FROM sr_cfwd.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","wordwin","input-arr-cfwd") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_scroll_flag = pa_cfwd[idx].scroll_flag 
				DISPLAY pa_cfwd[idx].* TO sr_cfwd[scrn].* 

				DISPLAY BY NAME pa_ord_text[idx].ord_text 

			AFTER FIELD scroll_flag 
				LET pa_cfwd[idx].scroll_flag = pr_scroll_flag 
				DISPLAY pa_cfwd[idx].scroll_flag TO sr_cfwd[scrn].scroll_flag 

				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF (pa_cfwd[idx+1].cfwd_date IS NULL OR 
					pa_cfwd[idx+1].cfwd_date = "31/12/1899") 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("G",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
					IF (pa_cfwd[idx+9].cfwd_date IS NULL OR 
					pa_cfwd[idx+9].cfwd_date = "31/12/1899") 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("G",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			BEFORE FIELD call_fwd_date 
				CALL disp_cfwd_entry(pa_cfwd[idx].cfwd_date, 
				pa_cfwd[idx].instr_text, 
				pa_ord_text[idx].ord_text) 
				NEXT FIELD scroll_flag 

			AFTER ROW 
				DISPLAY pa_cfwd[idx].* TO sr_cfwd[scrn].* 

		END INPUT 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w137 
	ELSE 
		OPEN WINDOW w430 with FORM "W430" 
		CALL windecoration_w("W430") -- albo kd-767 
		CLEAR FORM 
		LET pr_job_address = modu_rec_ordhead.ship_addr1_text clipped," ", 
		modu_rec_ordhead.ship_addr2_text clipped," ", 
		modu_rec_ordhead.ship_city_text clipped," ", 
		modu_rec_ordhead.ship_state_code clipped," ", 
		modu_rec_ordhead.ship_post_code," " 
		DISPLAY BY NAME pr_job_address 

		LET idx = 0 
		DECLARE c3_callfwd CURSOR FOR 
		SELECT * FROM ordcallfwd 
		WHERE cmpy_code = p_cmpy 
		AND order_num = modu_rec_ordhead.order_num 
		ORDER BY call_fwd_date, ord_text, line_num 

		FOREACH c3_callfwd INTO pr_ordcallfwd.* 
			LET idx = idx + 1 
			LET pa_cfwd2[idx].call_fwd_date = pr_ordcallfwd.call_fwd_date 
			LET pa_cfwd2[idx].line_num = pr_ordcallfwd.line_num 
			SELECT part_code INTO pa_cfwd2[idx].part_code FROM orderline 
			WHERE line_num = pr_ordcallfwd.line_num 
			AND order_num = pr_ordcallfwd.order_num 
			AND cmpy_code = p_cmpy 
			SELECT desc_text INTO pa_cfwd2[idx].desc_text FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = pa_cfwd2[idx].part_code 
			LET pa_cfwd2[idx].call_fwd_qty = pr_ordcallfwd.call_fwd_qty 
			LET pa_cfwd2[idx].status_ind = pr_ordcallfwd.status_ind 
			LET pa_ord_text2[idx].instr_text = pr_ordcallfwd.instr_text 
			LET pa_ord_text2[idx].ord_text = pr_ordcallfwd.ord_text 
			IF idx = 300 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF idx = 0 THEN 
			LET idx = 1 
			INITIALIZE pa_cfwd2[idx].* TO NULL 
			INITIALIZE pa_ord_text2[idx].* TO NULL 
		END IF 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		CALL set_count(idx) 
		LET msgresp=kandoomsg("W",1007,"")		#1007 F3/F4 - Esc TO continue
		INPUT ARRAY pa_cfwd2 WITHOUT DEFAULTS FROM sr_cfwd.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","wordwin","input-arr-cfwd2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE FIELD scroll_flag 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				LET pr_scroll_flag = pa_cfwd2[idx].scroll_flag 
				DISPLAY pa_cfwd2[idx].* TO sr_cfwd[scrn].* 

				DISPLAY BY NAME pa_ord_text2[idx].ord_text, 
				pa_ord_text2[idx].instr_text 

			AFTER FIELD scroll_flag 
				LET pa_cfwd2[idx].scroll_flag = pr_scroll_flag 
				DISPLAY pa_cfwd2[idx].scroll_flag TO sr_cfwd[scrn].scroll_flag 

				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF pa_cfwd2[idx+1].part_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("nextpage") 
				AND pa_cfwd2[idx+11].part_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD call_fwd_date 
				CALL disp_cfwd_entry(pa_cfwd2[idx].call_fwd_date, 
				pa_ord_text2[idx].instr_text, 
				pa_ord_text2[idx].ord_text) 
				NEXT FIELD scroll_flag 
			AFTER ROW 
				DISPLAY pa_cfwd2[idx].* TO sr_cfwd[scrn].* 


		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
		CLOSE WINDOW w430 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION disp_load (p_cmpy,pr_order_num,pr_order_line_num)
###########################################################################


###########################################################################
# FUNCTION disp_cfwd_entry(pr_cfwd_date,pr_instr_text,pr_ord_text)
#
#
###########################################################################
FUNCTION disp_cfwd_entry(pr_cfwd_date,pr_instr_text,pr_ord_text) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cfwd_date LIKE ordcallfwd.call_fwd_date, 
	pr_instr_text LIKE ordcallfwd.instr_text, 
	pr_ordcallfwd RECORD LIKE ordcallfwd.*, 
	pt_ordcallfwd RECORD LIKE ordcallfwd.*, 
	modu_rec_orderline RECORD LIKE orderline.*, 
	pr_product RECORD LIKE product.*, 
	pa_line array[300] OF RECORD 
		back_qty LIKE orderline.back_qty, 
		sched_qty LIKE orderline.sched_qty, 
		outer_qty LIKE orderline.order_qty, 
		call_fwd_code LIKE ordcallfwd.call_fwd_code 
	END RECORD, 
	pa_callfwd array[300] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE orderline.line_num, 
		part_code LIKE orderline.part_code, 
		unit_price_amt LIKE orderline.unit_price_amt, 
		char_sign CHAR(1), 
		price_uom_code LIKE orderline.price_uom_code, 
		uncalled_qty LIKE ordcallfwd.call_fwd_qty, 
		status_ind LIKE ordcallfwd.status_ind, 
		call_fwd_qty LIKE ordcallfwd.call_fwd_qty, 
		desc_text LIKE orderline.desc_text, 
		desc2_text LIKE product.desc2_text 
	END RECORD, 
	prev_date LIKE ordcallfwd.call_fwd_date, 
	pr_ord_text LIKE ordcallfwd.ord_text, 
	pr_outer_qty LIKE product.outer_qty, 
	pr_conv_qty LIKE uomconv.conversion_qty, 
	pr_outer_desc CHAR(10), 
	pr_sum_qty, prev_qty LIKE orderline.back_qty, 
	pr_amt_int INTEGER, 
	pr_amt_flt FLOAT, 
	pr_scroll_flag CHAR(1), 
	i,j,idx,scrn SMALLINT 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	INITIALIZE pr_ordcallfwd.* TO NULL 
	DECLARE c1_callfwd CURSOR FOR 
	SELECT unique(call_fwd_date), reqd_date, req_name_text, ord_text, 
	earliest_time, latest_time 
	FROM ordcallfwd 
	WHERE call_fwd_date = pr_cfwd_date 
	AND ord_text = pr_ord_text 
	AND order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = p_cmpy 
	OPEN c1_callfwd 
	FETCH c1_callfwd INTO pr_ordcallfwd.call_fwd_date, 
	pr_ordcallfwd.reqd_date, 
	pr_ordcallfwd.req_name_text, 
	pr_ordcallfwd.ord_text, 
	pr_ordcallfwd.earliest_time, 
	pr_ordcallfwd.latest_time 
	LET pr_ordcallfwd.instr_text = pr_instr_text 

	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
	DISPLAY "see common/wordwin.4gl" 
	EXIT program (1) 

	DECLARE c_lines CURSOR FOR 
	SELECT a.*, b.call_fwd_qty,b.status_ind,b.call_fwd_code 
	--DISABLED        FROM orderline a, outer ordcallfwd b
	FROM orderline a, ordcallfwd b 
	WHERE a.line_num = b.line_num 
	AND b.call_fwd_date = pr_cfwd_date 
	AND b.ord_text = pr_ord_text 
	AND a.order_num = modu_rec_ordhead.order_num 
	AND b.order_num = a.order_num 
	AND a.cmpy_code = p_cmpy 
	AND b.cmpy_code = a.cmpy_code 
	ORDER BY a.line_num 

	LET idx = 0 
	FOREACH c_lines INTO modu_rec_orderline.*, 
		pr_ordcallfwd.call_fwd_qty, 
		pr_ordcallfwd.status_ind, 
		pr_ordcallfwd.call_fwd_code 
		LET pr_conv_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, modu_rec_orderline.part_code, 
		modu_rec_orderline.uom_code, 
		modu_rec_orderline.price_uom_code,1) 
		IF pr_conv_qty < 0 THEN 
			LET pr_conv_qty = 0 
		END IF 
		LET modu_rec_orderline.unit_price_amt = modu_rec_orderline.unit_price_amt 
		* pr_conv_qty 
		LET idx = idx + 1 
		LET pa_callfwd[idx].char_sign = "/" 
		LET pa_callfwd[idx].line_num = modu_rec_orderline.line_num 
		LET pa_callfwd[idx].part_code = modu_rec_orderline.part_code 
		LET pa_callfwd[idx].unit_price_amt = modu_rec_orderline.unit_price_amt 
		LET pa_callfwd[idx].price_uom_code = modu_rec_orderline.price_uom_code 
		LET pa_callfwd[idx].desc_text = modu_rec_orderline.desc_text 
		LET pa_callfwd[idx].uncalled_qty = get_uncalled(modu_rec_orderline.line_num, 
		modu_rec_orderline.back_qty, 
		modu_rec_orderline.sched_qty) 
		LET pa_callfwd[idx].status_ind = pr_ordcallfwd.status_ind 
		IF pr_ordcallfwd.call_fwd_qty IS NULL THEN 
			LET pa_callfwd[idx].call_fwd_qty = 0 
		ELSE 
			LET pa_callfwd[idx].call_fwd_qty = pr_ordcallfwd.call_fwd_qty 
		END IF 
		IF pa_callfwd[idx].uncalled_qty = 0 
		AND pa_callfwd[idx].call_fwd_qty = 0 THEN 
			#Nothing outstanding AND nothing TO call... so dont DISPLAY it
			INITIALIZE pa_callfwd[idx].* TO NULL 
			LET idx = idx - 1 
			CONTINUE FOREACH 
		END IF 
		LET pa_line[idx].back_qty = modu_rec_orderline.back_qty 
		LET pa_line[idx].sched_qty = modu_rec_orderline.sched_qty 
		LET pa_line[idx].call_fwd_code = pr_ordcallfwd.call_fwd_code 
		SELECT outer_qty,desc2_text 
		INTO pr_outer_qty,pr_product.desc2_text 
		FROM product 
		WHERE cmpy_code = p_cmpy 
		AND part_code = modu_rec_orderline.part_code 
		LET pa_callfwd[idx].desc2_text = pr_product.desc2_text 
		IF pr_outer_qty IS NULL 
		OR pr_outer_qty = 0 
		OR pr_outer_qty = 1 THEN 
			LET pa_line[idx].outer_qty = NULL 
		ELSE 
			LET pa_line[idx].outer_qty = pr_outer_qty 
		END IF 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET msgresp = kandoomsg("U",9113,idx)	#U9113 idx records selected
	OPEN WINDOW w240 with FORM "W240" 
	CALL windecoration_w("W240") -- albo kd-767 
	FOR i = 1 TO idx 
		DISPLAY pa_callfwd[i].* TO sr_callfwd[i].* 

		IF i = 4 THEN 
			EXIT FOR 
		END IF 
	END FOR 

	LET msgresp = kandoomsg("W",1008,"")	#1008 F3/F4 - ESC TO continue
	IF pr_ordcallfwd.earliest_time = 0 THEN 
		LET pr_ordcallfwd.earliest_time = NULL 
	END IF 
	IF pr_ordcallfwd.latest_time = 0 THEN 
		LET pr_ordcallfwd.latest_time = NULL 
	END IF 
	DISPLAY BY NAME pr_ordcallfwd.call_fwd_date, 
	pr_ordcallfwd.reqd_date, 
	pr_ordcallfwd.req_name_text, 
	pr_ordcallfwd.ord_text, 
	pr_ordcallfwd.instr_text, 
	pr_ordcallfwd.earliest_time, 
	pr_ordcallfwd.latest_time 

	CALL set_count(idx) 
	INPUT ARRAY pa_callfwd WITHOUT DEFAULTS FROM sr_callfwd.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-callfwd") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET pr_scroll_flag = pa_callfwd[idx].scroll_flag 
			LET prev_qty = pa_callfwd[idx].call_fwd_qty 
			SELECT * INTO pr_ordcallfwd.* FROM ordcallfwd 
			WHERE cmpy_code = p_cmpy 
			AND call_fwd_code = pa_line[idx].call_fwd_code 
			DISPLAY BY NAME pr_ordcallfwd.entry_date, 
			pr_ordcallfwd.entry_code 

			DISPLAY pa_callfwd[idx].* TO sr_callfwd[scrn].* 

		BEFORE FIELD call_fwd_qty 
			NEXT FIELD scroll_flag 
		AFTER FIELD scroll_flag 
			LET pa_callfwd[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_callfwd[idx].scroll_flag TO sr_callfwd[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_callfwd[idx+1].part_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		AFTER ROW 
			DISPLAY pa_callfwd[idx].* TO sr_callfwd[scrn].* 


	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w240 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION disp_cfwd_entry(pr_cfwd_date,pr_instr_text,pr_ord_text)
###########################################################################


###########################################################################
# FUNCTION get_uncalled(pr_line_num, pr_back_qty, pr_sched_qty)
#
#
###########################################################################
FUNCTION get_uncalled(pr_line_num, pr_back_qty, pr_sched_qty) 
	DEFINE 
	pr_line_num LIKE orderline.line_num, 
	pr_sum_qty, uncalled_qty LIKE orderline.back_qty, 
	pr_back_qty, pr_sched_qty LIKE orderline.back_qty 

	SELECT sum(call_fwd_qty) INTO pr_sum_qty FROM ordcallfwd 
	WHERE line_num = pr_line_num 
	AND order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = p_cmpy 

	IF pr_sum_qty IS NULL THEN 
		LET pr_sum_qty = 0 
	END IF 

	LET uncalled_qty = (pr_back_qty + pr_sched_qty)	- pr_sum_qty 
	RETURN uncalled_qty 
END FUNCTION 
###########################################################################
# END FUNCTION get_uncalled(pr_line_num, pr_back_qty, pr_sched_qty)
###########################################################################


###########################################################################
# FUNCTION disp_deliv(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION disp_deliv(pr_cmpy_code, pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pa_delivhead array[200] OF RECORD 
		del_num LIKE delivhead.del_num, 
		pick_date LIKE delivhead.pick_date, 
		del_type CHAR(3), 
		transp_type_code LIKE delivhead.transp_type_code, 
		vehicle_code LIKE delivhead.vehicle_code, 
		load_num LIKE delivhead.load_num, 
		pick_num LIKE delivhead.pick_num, 
		inv_cr_num LIKE invoicehead.inv_num, 
		cancel_ind CHAR(1), 
		trip_num LIKE delivhead.trip_num, 
		trip_date LIKE delivhead.trip_date 
	END RECORD, 
	pr_count, 
	idx SMALLINT, 
	query_text, 
	where_text CHAR(1000) 

	LET glob_rec_kandoouser.cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = p_cmpy 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 

	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW w189 with FORM "W189" 
	CALL windecoration_w("W189") -- albo kd-767 

	DISPLAY BY NAME 
		modu_rec_ordhead.cust_code, 
		modu_rec_customer.name_text, 
		modu_rec_ordhead.order_num, 
		modu_rec_ordhead.ord_text 

	LET pr_count = 0 
	SELECT count(*) INTO pr_count FROM delivhead 
	WHERE order_num = modu_rec_ordhead.order_num 
	AND del_type_ind in ("1","2","4","5","6","9") 
	AND cmpy_code = p_cmpy 
	IF pr_count > 150 THEN 
		LET msgresp = kandoomsg("U",1001,"")	#1001 Enter selection criteria; OK TO continue.

		CONSTRUCT BY NAME where_text ON 
			delivhead.pick_date, 
			delivhead.transp_type_code, 
			delivhead.vehicle_code, 
			delivhead.load_num, 
			delivhead.pick_num, 
			delivhead.trip_num, 
			delivhead.trip_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wordwin","construct-delivhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 




		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW w189 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
	ELSE 
		LET where_text = " 1=1" 
	END IF 

	LET idx = 0 
	LET query_text = "SELECT * FROM delivhead ", 
	"WHERE order_num = '",modu_rec_ordhead.order_num,"' ", 
	"AND del_type_ind in ('1','2','4','5','6','9') ", 
	"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",where_text clipped," ", 
	"ORDER BY del_num" 

	PREPARE s_delivhead FROM query_text 
	DECLARE c_delivhead CURSOR FOR s_delivhead 
	FOREACH c_delivhead INTO pr_delivhead.* 
		LET idx = idx + 1 
		LET pa_delivhead[idx].del_num = pr_delivhead.del_num 
		LET pa_delivhead[idx].pick_date = pr_delivhead.pick_date 
		IF pr_delivhead.del_type_ind = "1" 
		OR pr_delivhead.del_type_ind = "4" 
		OR pr_delivhead.del_type_ind = "5" 
		OR pr_delivhead.del_type_ind = "6" 
		OR pr_delivhead.del_type_ind = "9" THEN 
			LET pa_delivhead[idx].del_type = "DEL" 
		ELSE 
			LET pa_delivhead[idx].del_type = "RET" 
		END IF 
		LET pa_delivhead[idx].transp_type_code = pr_delivhead.transp_type_code 
		LET pa_delivhead[idx].vehicle_code = pr_delivhead.vehicle_code 
		LET pa_delivhead[idx].load_num = pr_delivhead.load_num 
		LET pa_delivhead[idx].pick_num = pr_delivhead.pick_num 
		LET pa_delivhead[idx].inv_cr_num = NULL 
		LET pa_delivhead[idx].trip_num = pr_delivhead.trip_num 
		LET pa_delivhead[idx].trip_date = pr_delivhead.trip_date 
		IF pr_delivhead.del_type_ind = "1" 
		OR pr_delivhead.del_type_ind = "4" 
		OR pr_delivhead.del_type_ind = "6" 
		OR pr_delivhead.del_type_ind = "9" THEN 
			SELECT i.* INTO pr_invoicehead.* 
			FROM invoicehead i , invheadext e 
			WHERE i.ord_num = modu_rec_ordhead.order_num 
			AND i.manifest_num = pr_delivhead.pick_num 
			AND i.cmpy_code = p_cmpy 
			AND e.inv_num = i.inv_num 
			AND e.del_num = pr_delivhead.del_num 
			AND e.vehicle_code IS NOT NULL 
			AND e.cmpy_code = p_cmpy 
			IF status != notfound THEN 
				LET pa_delivhead[idx].inv_cr_num = pr_invoicehead.inv_num 
			END IF 
		ELSE 
			IF pr_delivhead.del_type_ind = "5" AND 
			pr_delivhead.status_ind = "1" THEN 
				LET pr_invoicehead.inv_num = NULL 
				SELECT inv_num INTO pr_invoicehead.inv_num 
				FROM exphead 
				WHERE cmpy_code = p_cmpy 
				AND pick_num = pr_delivhead.pick_num 
				LET pa_delivhead[idx].inv_cr_num = pr_invoicehead.inv_num 
			ELSE 
				LET pa_delivhead[idx].inv_cr_num = pr_delivhead.trans_num 
			END IF 
		END IF 
		IF pr_delivhead.status_ind = "9" THEN 
			LET pa_delivhead[idx].cancel_ind = "*" 
		END IF 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET msgresp = kandoomsg("U",9113,idx)#U9113 idx records selected
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 

	LET msgresp = kandoomsg("W",1007,"")	#1007  RETURN on line TO view
	DISPLAY ARRAY pa_delivhead TO sr_delivhead.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-delivhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 




		ON KEY (tab) 
			LET idx = arr_curr() 
			IF pa_delivhead[idx].inv_cr_num IS NULL THEN 
				CALL disp_unconf(pa_delivhead[idx].pick_num) 
			ELSE 
				CALL disp_delivdetl(pa_delivhead[idx].pick_num) 
			END IF 
		ON KEY (RETURN) 
			LET idx = arr_curr() 
			IF pa_delivhead[idx].inv_cr_num IS NULL THEN 
				CALL disp_unconf(pa_delivhead[idx].pick_num) 
			ELSE 
				CALL disp_delivdetl(pa_delivhead[idx].pick_num) 
			END IF 

	END DISPLAY 
	CLOSE WINDOW w189 
END FUNCTION 
###########################################################################
# END FUNCTION disp_deliv(pr_cmpy_code, pr_order_num)
###########################################################################

###########################################################################
# FUNCTION disp_delivdetl(pr_pick_num)
#
#
###########################################################################
FUNCTION disp_delivdetl(pr_pick_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_pick_num LIKE delivhead.pick_num, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_exphead RECORD LIKE exphead.*, 
	pr_expdetl RECORD LIKE expdetl.*, 
	pr_credithead RECORD LIKE credithead.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pr_product RECORD LIKE product.*, 
	pa_delivdetail array[200] OF RECORD 
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_text LIKE invoicedetl.line_text, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		desc2_text LIKE product.desc2_text 
	END RECORD, 
	modu_rec_conversion_qty FLOAT, 
	idx SMALLINT 

	SELECT * INTO pr_delivhead.* FROM delivhead 
	WHERE pick_num = pr_pick_num 
	AND cmpy_code = p_cmpy 
	IF pr_delivhead.del_type_ind = "1" 
	OR pr_delivhead.del_type_ind = "4" 
	OR pr_delivhead.del_type_ind = "6" 
	OR pr_delivhead.del_type_ind = "9" THEN 
		SELECT i.* INTO pr_invoicehead.* 
		FROM invoicehead i , invheadext e 
		WHERE i.ord_num = modu_rec_ordhead.order_num 
		AND i.manifest_num = pr_delivhead.pick_num 
		AND i.cmpy_code = p_cmpy 
		AND e.inv_num = i.inv_num 
		AND e.del_num = pr_delivhead.del_num 
		AND e.vehicle_code IS NOT NULL 
		AND e.cmpy_code = p_cmpy 
	ELSE 
		IF pr_delivhead.del_type_ind = "5" THEN 
			SELECT * INTO pr_exphead.* 
			FROM exphead 
			WHERE cmpy_code = p_cmpy 
			AND pick_num = pr_delivhead.pick_num 
			SELECT * INTO pr_invoicehead.* 
			FROM invoicehead 
			WHERE inv_num = pr_exphead.inv_num 
			AND cmpy_code = p_cmpy 
		ELSE 
			SELECT * INTO pr_credithead.* FROM credithead 
			WHERE cust_code = pr_delivhead.cust_code 
			AND cred_num = pr_delivhead.trans_num 
			AND cmpy_code = p_cmpy 
			LET pr_invoicehead.total_amt = pr_credithead.total_amt 
			LET pr_invoicehead.inv_date = pr_credithead.cred_date 
		END IF 
	END IF 
	OPEN WINDOW w190 with FORM "W190" 
	CALL windecoration_w("W190") -- albo kd-767 
	IF pr_delivhead.del_type_ind = "1" 
	OR pr_delivhead.del_type_ind = "4" 
	OR pr_delivhead.del_type_ind = "6" 
	OR pr_delivhead.del_type_ind = "9" THEN 
		DISPLAY "Delivery", 
		"Invoice....." 
		TO detail_type, 
		inv_cr_text 
		attribute(white) 
	ELSE 
		IF pr_delivhead.del_type_ind = "5" THEN 
			DISPLAY "Delivery", 
			"Invoice....." 
			TO detail_type, 
			inv_cr_text 
			attribute(white) 
		ELSE 
			DISPLAY "RETURN", 
			"Credit Note." 
			TO detail_type, 
			inv_cr_text 
			attribute(white) 
		END IF 
	END IF 
	IF pr_invoicehead.ref_num = pr_delivhead.pick_num THEN 
		LET pr_invoicehead.ref_num = NULL 
	END IF 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	pr_delivhead.order_num, 
	pr_invoicehead.total_amt, 
	pr_delivhead.pick_num, 
	pr_delivhead.del_num, 
	pr_delivhead.ord_text, 
	pr_invoicehead.inv_date, 
	pr_invoicehead.ref_num 

	DISPLAY BY NAME modu_rec_customer.currency_code 
	attribute(green) 
	IF pr_delivhead.del_type_ind = "1" 
	OR pr_delivhead.del_type_ind = "4" 
	OR pr_delivhead.del_type_ind = "6" 
	OR pr_delivhead.del_type_ind = "9" THEN 
		DISPLAY pr_invoicehead.inv_num, 
		pr_invoicehead.com1_text, 
		pr_invoicehead.com2_text 
		TO inv_num, 
		com1_text, 
		com2_text 

	ELSE 
		IF pr_delivhead.del_type_ind = "5" THEN 
			DISPLAY pr_exphead.inv_num, 
			pr_invoicehead.com1_text, 
			pr_invoicehead.com2_text 
			TO inv_num, 
			com1_text, 
			com2_text 

		ELSE 
			DISPLAY pr_credithead.cred_num, 
			pr_credithead.com1_text, 
			pr_credithead.com2_text 
			TO inv_num, 
			com1_text, 
			com2_text 

		END IF 
	END IF 
	IF pr_delivhead.pallet_qty != 0 AND 
	pr_delivhead.del_type_ind <> "5" THEN 
		DISPLAY "Pallets..........." 
		TO pallet_text 
		attribute(white) 
		DISPLAY BY NAME pr_delivhead.pallet_qty 

	END IF 
	IF pr_delivhead.del_type_ind = "1" 
	OR pr_delivhead.del_type_ind = "4" 
	OR pr_delivhead.del_type_ind = "6" 
	OR pr_delivhead.del_type_ind = "9" THEN 
		IF pr_invoicehead.freight_amt != 0 THEN 
			DISPLAY "Cartage....." 
			TO cartage_text 
			attribute(white) 
			DISPLAY BY NAME pr_invoicehead.freight_amt 

		END IF 
	ELSE 
		IF pr_delivhead.del_type_ind = "5" THEN 
			DISPLAY "Container........." 
			TO pallet_text 
			attribute(white) 
			DISPLAY pr_exphead.contain_text TO pallet_qty 

			DISPLAY "Seal........." 
			TO cartage_text 
			attribute(white) 
			DISPLAY pr_exphead.seal_text TO freight_amt 

		ELSE 
			IF pr_credithead.freight_amt != 0 THEN 
				DISPLAY "Cartage....." 
				TO cartage_text 
				attribute(white) 
				DISPLAY BY NAME pr_credithead.freight_amt 

			END IF 
		END IF 
	END IF 
	LET idx = 0 
	IF pr_delivhead.del_type_ind = "1" 
	OR pr_delivhead.del_type_ind = "4" 
	OR pr_delivhead.del_type_ind = "6" 
	OR pr_delivhead.del_type_ind = "9" THEN 
		DECLARE c_delivdetail CURSOR FOR 
		SELECT * FROM invoicedetl 
		WHERE inv_num = pr_invoicehead.inv_num 
		AND cmpy_code = p_cmpy 
		ORDER BY line_num 
		FOREACH c_delivdetail INTO pr_invoicedetl.* 
			LET idx = idx + 1 
			LET pa_delivdetail[idx].line_num = pr_invoicedetl.line_num 
			LET pa_delivdetail[idx].part_code = pr_invoicedetl.part_code 
			LET pa_delivdetail[idx].ship_qty = pr_invoicedetl.ship_qty 
			LET pa_delivdetail[idx].line_text = pr_invoicedetl.line_text 
			IF pr_invoicedetl.part_code IS NULL 
			OR pr_invoicedetl.uom_code IS NULL 
			OR pr_invoicedetl.price_uom_code IS NULL THEN 
				LET pa_delivdetail[idx].unit_sale_amt = pr_invoicedetl.unit_sale_amt 
			ELSE 
				LET modu_rec_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, pr_invoicedetl.part_code, 
				pr_invoicedetl.uom_code, 
				pr_invoicedetl.price_uom_code,1) 
				IF modu_rec_conversion_qty <= 0 THEN 
					LET pa_delivdetail[idx].unit_sale_amt = NULL 
				ELSE 
					LET pa_delivdetail[idx].unit_sale_amt 
					= pr_invoicedetl.unit_sale_amt * modu_rec_conversion_qty 
				END IF 
			END IF 
			IF pr_invoicedetl.part_code IS NOT NULL THEN 
				SELECT desc2_text INTO pr_product.desc2_text 
				FROM product 
				WHERE part_code = pr_invoicedetl.part_code 
				AND cmpy_code = p_cmpy 
				LET pa_delivdetail[idx].desc2_text = pr_product.desc2_text 
			END IF 
			LET pa_delivdetail[idx].line_total_amt = pr_invoicedetl.line_total_amt 
			IF idx = 200 THEN 
				LET msgresp = kandoomsg("U",6100,idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET msgresp = kandoomsg("U",9113,idx) 
		#U9113 idx records selected
	ELSE 
		IF pr_delivhead.del_type_ind = "5" THEN 
			DECLARE c3_delivdetail CURSOR FOR 
			SELECT * FROM expdetl 
			WHERE export_num = pr_exphead.export_num 
			AND cmpy_code = p_cmpy 
			ORDER BY line_num 
			FOREACH c3_delivdetail INTO pr_expdetl.* 
				LET idx = idx + 1 
				LET pa_delivdetail[idx].part_code = pr_expdetl.part_code 
				LET pa_delivdetail[idx].ship_qty = pr_expdetl.conf_qty 
				SELECT * INTO pr_invoicedetl.* 
				FROM invoicedetl 
				WHERE inv_num = pr_exphead.inv_num 
				AND cmpy_code = p_cmpy 
				AND part_code = pr_expdetl.part_code 
				AND ware_code = pr_expdetl.ware_code 
				LET pa_delivdetail[idx].line_num = pr_invoicedetl.line_num 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE part_code = pr_invoicedetl.part_code 
				AND cmpy_code = p_cmpy 
				IF pr_invoicedetl.part_code IS NULL 
				OR pr_invoicedetl.uom_code IS NULL 
				OR pr_invoicedetl.price_uom_code IS NULL THEN 
					LET pa_delivdetail[idx].unit_sale_amt = 
					pr_invoicedetl.unit_sale_amt 
				ELSE 
					LET modu_rec_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, pr_invoicedetl.part_code, 
					pr_invoicedetl.uom_code, 
					pr_invoicedetl.price_uom_code,1) 
					IF modu_rec_conversion_qty <= 0 THEN 
						LET pa_delivdetail[idx].unit_sale_amt = NULL 
					ELSE 
						LET pa_delivdetail[idx].unit_sale_amt 
						= pr_invoicedetl.unit_sale_amt * modu_rec_conversion_qty 
					END IF 
				END IF 
				LET pa_delivdetail[idx].line_total_amt = 
				pr_invoicedetl.unit_sale_amt * pr_expdetl.conf_qty 
				LET pa_delivdetail[idx].line_text = pr_product.desc_text 
				LET pa_delivdetail[idx].desc2_text = pr_product.desc2_text 
			END FOREACH 
		ELSE 
			DECLARE c2_delivdetail CURSOR FOR 
			SELECT * FROM creditdetl 
			WHERE cred_num = pr_delivhead.trans_num 
			AND cmpy_code = p_cmpy 
			ORDER BY line_num 
			FOREACH c2_delivdetail INTO pr_creditdetl.* 
				LET idx = idx + 1 
				LET pa_delivdetail[idx].line_num = pr_creditdetl.line_num 
				LET pa_delivdetail[idx].part_code = pr_creditdetl.part_code 
				LET pa_delivdetail[idx].ship_qty = pr_creditdetl.ship_qty 
				LET pa_delivdetail[idx].line_text = pr_creditdetl.line_text 
				IF pr_creditdetl.part_code IS NULL 
				OR pr_creditdetl.uom_code IS NULL 
				OR pr_creditdetl.price_uom_code IS NULL THEN 
					LET pa_delivdetail[idx].unit_sale_amt = NULL 
				ELSE 
					LET modu_rec_conversion_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, pr_creditdetl.part_code, 
					pr_creditdetl.uom_code, 
					pr_creditdetl.price_uom_code,1) 
					IF modu_rec_conversion_qty <= 0 THEN 
						LET pa_delivdetail[idx].unit_sale_amt = NULL 
					ELSE 
						LET pa_delivdetail[idx].unit_sale_amt 
						= pr_creditdetl.unit_sales_amt * modu_rec_conversion_qty 
					END IF 
				END IF 
				IF pr_creditdetl.part_code IS NOT NULL THEN 
					SELECT desc2_text INTO pr_product.desc2_text 
					FROM product 
					WHERE part_code = pr_creditdetl.part_code 
					AND cmpy_code = p_cmpy 
					LET pa_delivdetail[idx].desc2_text = pr_product.desc2_text 
				END IF 
				LET pa_delivdetail[idx].line_total_amt = pr_creditdetl.line_total_amt 
				IF idx = 200 THEN 
					LET msgresp = kandoomsg("U",6100,idx) 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			LET msgresp = kandoomsg("U",9113,idx) 
			#U9113 idx records selected
		END IF 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1061,"") 
	#1061  RETURN on line TO view
	DISPLAY ARRAY pa_delivdetail TO sr_delivdetail.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-delivdetail") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (RETURN) 
			LET idx = arr_curr() 
			IF pa_delivdetail[idx].part_code IS NOT NULL THEN 
				IF pr_delivhead.del_type_ind = "1" 
				OR pr_delivhead.del_type_ind = "4" 
				OR pr_delivhead.del_type_ind = "5" 
				OR pr_delivhead.del_type_ind = "6" 
				OR pr_delivhead.del_type_ind = "9" THEN 
					CALL disp_delivdetail(pr_delivhead.del_type_ind, 
					pr_invoicehead.inv_num, 
					pa_delivdetail[idx].line_num) 
				ELSE 
					CALL disp_delivdetail(pr_delivhead.del_type_ind, 
					pr_credithead.cred_num, 
					pa_delivdetail[idx].line_num) 
				END IF 
			END IF 
		ON KEY (F8) 
			LET idx = arr_curr() 
			CALL disp_delivinst(pr_delivhead.pick_num) 

	END DISPLAY 
	CLOSE WINDOW w190 
END FUNCTION 
###########################################################################
# END FUNCTION disp_delivdetl(pr_pick_num)
###########################################################################


###########################################################################
# FUNCTION disp_delivdetl(pr_pick_num)
#
#
###########################################################################
FUNCTION disp_delivdetail(pr_del_type_ind, pr_inv_num, pr_line_num) 
	DEFINE 
	pr_del_type_ind LIKE delivhead.del_type_ind, 
	pr_inv_num LIKE invoicehead.inv_num, 
	pr_line_num LIKE invoicedetl.line_num, 
	pr_invoicedetl RECORD 
		inv_num LIKE invoicedetl.inv_num, 
		line_num LIKE invoicedetl.line_num, 
		part_code LIKE invoicedetl.part_code, 
		ware_code LIKE invoicedetl.ware_code, 
		ship_qty LIKE invoicedetl.ship_qty, 
		line_text LIKE invoicedetl.line_text, 
		uom_code LIKE invoicedetl.uom_code, 
		unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
		line_total_amt LIKE invoicedetl.line_total_amt, 
		level_code LIKE invoicedetl.level_code, 
		price_uom_code LIKE invoicedetl.price_uom_code, 
		disc_per LIKE invoicedetl.disc_per, 
		list_price_amt LIKE invoicedetl.list_price_amt 
	END RECORD, 
	pr_uom RECORD LIKE uom.*, 
	pr_product RECORD LIKE product.*, 
	save_part LIKE orderline.part_code, 
	save_ware LIKE orderline.ware_code, 
	save_uom LIKE orderline.uom_code, 
	save_qty LIKE orderline.order_qty, 
	pr_unit_sale_amt LIKE invoicedetl.unit_sale_amt, 
	pr_list_price_amt LIKE invoicedetl.list_price_amt, 
	save_parent,pr_parent,pr_filler,pr_flex_part LIKE product.part_code, 
	pr_flex_num SMALLINT, 
	modu_rec_conversion_qty FLOAT, 
	query_text CHAR(150) 

	OPEN WINDOW w194 with FORM "W194" 
	CALL windecoration_w("W194") -- albo kd-767 
	IF pr_del_type_ind = "1" 
	OR pr_del_type_ind = "4" 
	OR pr_del_type_ind = "5" 
	OR pr_del_type_ind = "6" 
	OR pr_del_type_ind = "9" THEN 
		DISPLAY "Delivery" TO detail_type 
		attribute(white) 
	ELSE 
		DISPLAY "RETURN" TO detail_type 
		attribute(white) 
	END IF 

	IF pr_del_type_ind = "1" 
	OR pr_del_type_ind = "4" 
	OR pr_del_type_ind = "5" 
	OR pr_del_type_ind = "6" 
	OR pr_del_type_ind = "9" THEN 
		SELECT inv_num, line_num, part_code, ware_code, ship_qty, line_text, 
		uom_code, unit_sale_amt, line_total_amt, level_code, 
		price_uom_code, disc_per, list_price_amt 
		INTO pr_invoicedetl.* FROM invoicedetl 
		WHERE line_num = pr_line_num 
		AND inv_num = pr_inv_num 
		AND cmpy_code = p_cmpy 
	ELSE 
		SELECT cred_num, line_num, part_code, ware_code, ship_qty, line_text, 
		uom_code, unit_sales_amt, line_total_amt, level_code, 
		price_uom_code, 0, 0 
		INTO pr_invoicedetl.* FROM creditdetl 
		WHERE line_num = pr_line_num 
		AND cred_num = pr_inv_num 
		AND cmpy_code = p_cmpy 
		LET pr_invoicedetl.disc_per = NULL 
		LET pr_invoicedetl.list_price_amt = NULL 
	END IF 
	IF pr_invoicedetl.part_code IS NOT NULL THEN 
		SELECT desc2_text INTO pr_product.desc2_text 
		FROM product 
		WHERE part_code = pr_invoicedetl.part_code 
		AND cmpy_code = p_cmpy 
	END IF 
	DISPLAY BY NAME pr_invoicedetl.part_code, 
	pr_invoicedetl.ware_code, 
	pr_invoicedetl.ship_qty, 
	pr_invoicedetl.line_text, 
	pr_invoicedetl.uom_code, 
	pr_invoicedetl.line_total_amt, 
	pr_product.desc2_text, 
	pr_invoicedetl.level_code, 
	pr_invoicedetl.disc_per 

	INITIALIZE pr_uom.* TO NULL 
	SELECT * INTO pr_uom.* FROM uom 
	WHERE cmpy_code = p_cmpy 
	AND uom_code = pr_invoicedetl.uom_code 
	DISPLAY pr_uom.desc_text TO uom_desc1 

	INITIALIZE pr_uom.* TO NULL 
	SELECT * INTO pr_uom.* FROM uom 
	WHERE cmpy_code = p_cmpy 
	AND uom_code = pr_invoicedetl.price_uom_code 
	DISPLAY pr_uom.desc_text TO uom_desc2 

	IF pr_invoicedetl.part_code IS NULL 
	OR pr_invoicedetl.uom_code IS NULL 
	OR pr_invoicedetl.price_uom_code IS NULL THEN 
		LET pr_invoicedetl.unit_sale_amt = NULL 
		LET pr_invoicedetl.list_price_amt = NULL 
	ELSE 
		LET modu_rec_conversion_qty = get_uom_conversion_factor(
			glob_rec_kandoouser.cmpy_code, 
			pr_invoicedetl.part_code, 
			pr_invoicedetl.uom_code, 
			pr_invoicedetl.price_uom_code,1) 
		
		IF modu_rec_conversion_qty <= 0 THEN 
			LET pr_unit_sale_amt = NULL 
			LET pr_list_price_amt = NULL 
		ELSE 
			LET pr_unit_sale_amt = pr_invoicedetl.unit_sale_amt * modu_rec_conversion_qty 
			LET pr_list_price_amt = pr_invoicedetl.list_price_amt * modu_rec_conversion_qty 
		END IF 
	END IF 
	
	DISPLAY 
		pr_unit_sale_amt, 
		pr_list_price_amt 
	TO 
		unit_sale_amt, 
		list_price_amt 

	MENU " Pricing Details" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","wordwin","menu-Pricing_Details-2") -- albo 
			IF pr_invoicedetl.part_code = modu_rec_mbparms.pallet_part_code THEN 
				HIDE option "Pricing" 
			END IF 
			NEXT option "Exit" 

		ON ACTION "WEB-HELP" -- albo 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Pricing" " Show Price Breakdown details " 
			IF pr_del_type_ind = "1" 
			OR pr_del_type_ind = "4" 
			OR pr_del_type_ind = "5" 
			OR pr_del_type_ind = "6" 
			OR pr_del_type_ind = "9" THEN 
				CALL disp_del_pricebreak(pr_del_type_ind, 
				pr_inv_num, 
				pr_line_num) 
			ELSE 
				CALL disp_cred_pricebreak(pr_del_type_ind, 
				pr_inv_num, 
				pr_line_num) 
			END IF 
			NEXT option "Exit" 
		COMMAND KEY (interrupt,"E") "Exit" " Exit FROM Delivery Line " 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW w194 
END FUNCTION 
###########################################################################
# END FUNCTION disp_delivdetl(pr_pick_num)
###########################################################################


###########################################################################
# FUNCTION disp_del_pricebreak(pr_del_type_ind, pr_inv_num, pr_line_num)
#
#
###########################################################################
FUNCTION disp_del_pricebreak(pr_del_type_ind, pr_inv_num, pr_line_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_del_type_ind LIKE delivhead.del_type_ind, 
	pr_inv_num LIKE invoicehead.inv_num, 
	pr_line_num LIKE invoicedetl.line_num, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_invrates RECORD LIKE invrates.*, 
	pr_uom RECORD LIKE uom.*, 
	pa_invrates array[10] OF RECORD 
		short_desc_text LIKE ordrates.short_desc_text, 
		unit_price_amt LIKE invrates.unit_price_amt, 
		ext_price_amt LIKE orderline.ext_price_amt 
	END RECORD, 
	pa_type array[10] OF RECORD 
		rate_type LIKE invrates.rate_type 
	END RECORD, 
	pr_conv_qty LIKE uomconv.conversion_qty, 
	pr_save_amt LIKE invrates.unit_price_amt, 
	pr_save_ext LIKE invrates.unit_price_amt, 
	pr_tot_unit_amt LIKE invrates.unit_price_amt, 
	pr_tot_ext_amt LIKE orderline.ext_price_amt, 
	pr_waregrp_code LIKE waregrp.waregrp_code, 
	pr_cartage_ind LIKE waregrp.cartage_ind, 
	pr_entry_code LIKE invoicehead.entry_code, 
	i, j, idx, uom_flag, rates_num, scrn SMALLINT 

	SELECT entry_code INTO pr_entry_code FROM invoicehead 
	WHERE inv_num = pr_inv_num 
	AND cmpy_code = p_cmpy 

	SELECT * INTO pr_invoicedetl.* FROM invoicedetl 
	WHERE line_num = pr_line_num 
	AND inv_num = pr_inv_num 
	AND cmpy_code = p_cmpy 

	SELECT count(*) INTO rates_num FROM invrates 
	WHERE line_num = pr_invoicedetl.line_num 
	AND inv_num = pr_invoicedetl.inv_num 
	AND cmpy_code = p_cmpy 

	IF rates_num > 5 THEN 
		OPEN WINDOW w181 with FORM "W181" # scrolling 6 LINES 
		CALL windecoration_w("W181") -- albo kd-767 
	END IF 

	IF rates_num = 5 THEN 
		OPEN WINDOW w181 with FORM "W181a" # 5 line ARRAY 
		CALL windecoration_w("W181a") -- albo kd-767 
	END IF 
	IF rates_num = 4 THEN 
		OPEN WINDOW w181 with FORM "W181b" # 4 line ARRAY 
		CALL windecoration_w("W181b") -- albo kd-767 
	END IF 
	IF rates_num = 3 THEN 
		OPEN WINDOW w181 with FORM "W181c" # 3 line ARRAY 
		CALL windecoration_w("W181c") -- albo kd-767 
	END IF 
	IF rates_num < 3 THEN 
		OPEN WINDOW w181 with FORM "W181d" # 2 line ARRAY 
		CALL windecoration_w("W181d") -- albo kd-767 
	END IF 
	IF pr_invoicedetl.part_code IS NULL 
	OR pr_invoicedetl.uom_code IS NULL 
	OR pr_invoicedetl.price_uom_code IS NULL THEN 
		LET pr_conv_qty = 0 
	ELSE 
		LET pr_conv_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, 
		pr_invoicedetl.part_code, 
		pr_invoicedetl.uom_code, 
		pr_invoicedetl.price_uom_code,1) 
	END IF 
	IF pr_conv_qty < 0 THEN 
		LET pr_conv_qty = 0 
	END IF 
	LET pr_tot_unit_amt = 0 
	LET pr_tot_ext_amt = 0 
	DISPLAY BY NAME pr_invoicedetl.price_uom_code 

	SELECT * INTO pr_invrates.* FROM invrates 
	WHERE line_num = pr_invoicedetl.line_num 
	AND inv_num = pr_invoicedetl.inv_num 
	AND rate_type = "PRP" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9292,"") 
		#9292 " Logic error: Product Price Corruption"
		CLOSE WINDOW w181 
		RETURN 
	END IF 
	LET pa_type[1].rate_type = "PRP" 
	LET pa_invrates[1].short_desc_text = "Product" 
	LET pa_invrates[1].unit_price_amt = pr_invrates.unit_price_amt * pr_conv_qty 
	LET pa_invrates[1].ext_price_amt = (pr_invrates.unit_price_amt * pr_invoicedetl.ship_qty) 
	LET pr_tot_unit_amt = pr_tot_unit_amt + pa_invrates[1].unit_price_amt 
	LET pr_tot_ext_amt = pr_tot_ext_amt + pa_invrates[1].ext_price_amt 
	IF modu_rec_ordhead.cartage_ind <> '1' 
	AND modu_rec_ordhead.ord_ind <> '9' THEN 
		LET idx = 1 
	ELSE 
		SELECT * INTO pr_invrates.* FROM invrates 
		WHERE line_num = pr_invoicedetl.line_num 
		AND inv_num = pr_invoicedetl.inv_num 
		AND rate_type = "CRP" 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("W",9294,"") 
			#9294 " Logic error: Cartage Price Corruption"
			CLOSE WINDOW w181 
			RETURN 
		END IF 
		LET pa_type[2].rate_type = "CRP" 
		LET pa_invrates[2].short_desc_text = "Cartage" 
		LET pa_invrates[2].unit_price_amt = pr_invrates.unit_price_amt 
		* pr_conv_qty 
		LET pa_invrates[2].ext_price_amt = (pr_invrates.unit_price_amt 
		* pr_invoicedetl.ship_qty) 
		LET pr_tot_unit_amt = pr_tot_unit_amt + pa_invrates[2].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt + pa_invrates[2].ext_price_amt 
		LET idx = 2 
	END IF 
	
	IF modu_rec_ordhead.ord_ind = "9" THEN 
		SELECT * INTO pr_invrates.* FROM invrates 
		WHERE line_num = pr_invoicedetl.line_num 
		AND inv_num = pr_invoicedetl.inv_num 
		AND rate_type = "LRP" 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("W",9916,"") 
			#9916 Labour Price Corruption
			CLOSE WINDOW w181 
			RETURN 
		END IF 
		LET pa_type[idx+1].rate_type = "LRP" 
		LET pa_invrates[idx+1].short_desc_text = "Labour" 
		LET pa_invrates[idx+1].unit_price_amt = pr_invrates.unit_price_amt 
		* pr_conv_qty 
		LET pa_invrates[idx+1].ext_price_amt = (pr_invrates.unit_price_amt 
		* pr_invoicedetl.ship_qty) 
		LET pr_tot_unit_amt = pr_tot_unit_amt + pa_invrates[idx+1].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt + pa_invrates[idx+1].ext_price_amt 
		LET idx = idx+1 
	END IF 

	DECLARE c2_invrates CURSOR FOR 
	SELECT * FROM invrates 
	WHERE line_num = pr_invoicedetl.line_num 
	AND inv_num = pr_invoicedetl.inv_num 
	AND rate_type != "PRP" 
	AND rate_type != "CRP" 
	AND rate_type != "LRP" 
	AND cmpy_code = p_cmpy 

	FOREACH c2_invrates INTO pr_invrates.* 
		LET idx = idx + 1 
		SELECT short_desc_text INTO pa_invrates[idx].short_desc_text 
		FROM ordrates 
		WHERE cmpy_code = p_cmpy 
		AND rate_type_code = pr_invrates.rate_type 
		AND ord_ind = modu_rec_ordhead.ord_ind 
		IF status = notfound THEN 
			LET pa_invrates[idx].short_desc_text = "***************" 
		END IF 
		LET pa_type[idx].rate_type = pr_invrates.rate_type 
		LET pa_invrates[idx].unit_price_amt = pr_invrates.unit_price_amt * pr_conv_qty 
		LET pa_invrates[idx].ext_price_amt = (pr_invrates.unit_price_amt	* pr_invoicedetl.ship_qty) 
		LET pr_tot_unit_amt = pr_tot_unit_amt + pa_invrates[idx].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt	+ pa_invrates[idx].ext_price_amt 

		IF idx = 10 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) #U9113 idx records selected
	IF idx = 0 THEN 
		#Something went wrong
		CLOSE WINDOW w181 
		RETURN 
	END IF 
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36, 
	NEXT KEY f36 

	CALL set_count(idx) 

	DISPLAY 
		pr_tot_unit_amt, pr_tot_ext_amt 
	TO 
		tot_unit_amt, tot_ext_amt 

	LET msgresp = kandoomsg("W",1008,"") 

	DISPLAY ARRAY pa_invrates TO sr_ordlinerate.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-invrates") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 


	CLOSE WINDOW w181 
	OPTIONS NEXT KEY f3 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION disp_del_pricebreak(pr_del_type_ind, pr_inv_num, pr_line_num)
###########################################################################


###########################################################################
# FUNCTION disp_cred_pricebreak(pr_del_type_ind, pr_cred_num, pr_line_num)
#
#
###########################################################################
FUNCTION disp_cred_pricebreak(pr_del_type_ind, pr_cred_num, pr_line_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_del_type_ind LIKE delivhead.del_type_ind, 
	pr_cred_num LIKE credithead.cred_num, 
	pr_line_num LIKE creditdetl.line_num, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	pr_creditrates RECORD LIKE creditrates.*, 
	pr_uom RECORD LIKE uom.*, 
	pa_creditrates array[10] OF RECORD 
		short_desc_text LIKE ordrates.short_desc_text, 
		unit_price_amt LIKE creditrates.unit_price_amt, 
		ext_price_amt LIKE orderline.ext_price_amt 
	END RECORD, 
	pa_type array[10] OF RECORD 
		rate_type LIKE creditrates.rate_type 
	END RECORD, 
	pr_conv_qty LIKE uomconv.conversion_qty, 
	pr_save_amt LIKE creditrates.unit_price_amt, 
	pr_save_ext LIKE creditrates.unit_price_amt, 
	pr_tot_unit_amt LIKE creditrates.unit_price_amt, 
	pr_tot_ext_amt LIKE orderline.ext_price_amt, 
	pr_waregrp_code LIKE waregrp.waregrp_code, 
	pr_cartage_ind LIKE waregrp.cartage_ind, 
	pr_entry_code LIKE invoicehead.entry_code, 
	i, j, idx, uom_flag, rates_num, scrn SMALLINT 

	SELECT entry_code INTO pr_entry_code FROM credithead 
	WHERE cred_num = pr_cred_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO pr_creditdetl.* FROM creditdetl 
	WHERE line_num = pr_line_num 
	AND cred_num = pr_cred_num 
	AND cmpy_code = p_cmpy 
	SELECT count(*) INTO rates_num FROM creditrates 
	WHERE line_num = pr_creditdetl.line_num 
	AND cred_num = pr_creditdetl.cred_num 
	AND cmpy_code = p_cmpy 

	IF rates_num > 5 THEN 
		OPEN WINDOW w181 with FORM "W181" # scrolling 6 LINES 
		CALL windecoration_w("W181") -- albo kd-767 
	END IF 
	IF rates_num = 5 THEN 
		OPEN WINDOW w181 with FORM "W181a" # 5 line ARRAY 
		CALL windecoration_w("W181a") -- albo kd-767 
	END IF 
	IF rates_num = 4 THEN 
		OPEN WINDOW w181 with FORM "W181b" # 4 line ARRAY 
		CALL windecoration_w("W181b") -- albo kd-767 
	END IF 
	IF rates_num = 3 THEN 
		OPEN WINDOW w181 with FORM "W181c" # 3 line ARRAY 
		CALL windecoration_w("W181c") -- albo kd-767 
	END IF 
	IF rates_num < 3 THEN 
		OPEN WINDOW w181 with FORM "W181d" # 2 line ARRAY 
		CALL windecoration_w("W181d") -- albo kd-767 
	END IF 
	IF pr_creditdetl.part_code IS NULL 
	OR pr_creditdetl.uom_code IS NULL 
	OR pr_creditdetl.price_uom_code IS NULL THEN 
		LET pr_conv_qty = 0 
	ELSE 
		LET pr_conv_qty = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code, 
		pr_creditdetl.part_code, 
		pr_creditdetl.uom_code, 
		pr_creditdetl.price_uom_code,1) 
	END IF 
	IF pr_conv_qty < 0 THEN 
		LET pr_conv_qty = 0 
	END IF 
	LET pr_tot_unit_amt = 0 
	LET pr_tot_ext_amt = 0 
	DISPLAY BY NAME pr_creditdetl.price_uom_code 

	SELECT * INTO pr_creditrates.* FROM creditrates 
	WHERE line_num = pr_creditdetl.line_num 
	AND cred_num = pr_creditdetl.cred_num 
	AND rate_type = "PRP" 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9292,"") 
		#9292 " Logic error: Product Price Corruption"
		CLOSE WINDOW w181 
		RETURN 
	END IF 

	LET pa_type[1].rate_type = "PRP" 
	LET pa_creditrates[1].short_desc_text = "Product" 
	LET pa_creditrates[1].unit_price_amt = pr_creditrates.unit_price_amt	* pr_conv_qty 
	LET pa_creditrates[1].ext_price_amt = (pr_creditrates.unit_price_amt	* pr_creditdetl.ship_qty) 
	LET pr_tot_unit_amt = pr_tot_unit_amt + pa_creditrates[1].unit_price_amt 
	LET pr_tot_ext_amt = pr_tot_ext_amt + pa_creditrates[1].ext_price_amt 
	LET idx = 1 
	
	IF modu_rec_ordhead.cartage_ind <> '1' 
	AND modu_rec_ordhead.ord_ind <> '9' THEN 
		LET idx = 1 
	ELSE 
		SELECT * INTO pr_creditrates.* FROM creditrates 
		WHERE line_num = pr_creditdetl.line_num 
		AND cred_num = pr_creditdetl.cred_num 
		AND rate_type = "CRP" 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
		ELSE 
			LET pa_type[2].rate_type = "CRP" 
			LET pa_creditrates[2].short_desc_text = "Cartage" 
			LET pa_creditrates[2].unit_price_amt = pr_creditrates.unit_price_amt 
			* pr_conv_qty 
			LET pa_creditrates[2].ext_price_amt = (pr_creditrates.unit_price_amt 
			* pr_creditdetl.ship_qty) 
			LET pr_tot_unit_amt = pr_tot_unit_amt 
			+ pa_creditrates[2].unit_price_amt 
			LET pr_tot_ext_amt = pr_tot_ext_amt 
			+ pa_creditrates[2].ext_price_amt 
			LET idx = 2 
		END IF 
	END IF 
	IF modu_rec_ordhead.ord_ind = '9' THEN 
		SELECT * INTO pr_creditrates.* FROM creditrates 
		WHERE line_num = pr_creditdetl.line_num 
		AND cred_num = pr_creditdetl.cred_num 
		AND rate_type = "LRP" 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("W",9916,"") 
			#9294 " Logic error: Labour Price Corruption"
			CLOSE WINDOW w181 
			RETURN 
		END IF 
		LET pa_type[idx+1].rate_type = "LRP" 
		LET pa_creditrates[idx+1].short_desc_text = "Labour" 
		LET pa_creditrates[idx+1].unit_price_amt = pr_creditrates.unit_price_amt		* pr_conv_qty 
		LET pa_creditrates[idx+1].ext_price_amt = (pr_creditrates.unit_price_amt 	* pr_creditdetl.ship_qty) 
		LET pr_tot_unit_amt =pr_tot_unit_amt +pa_creditrates[idx+1].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt + pa_creditrates[idx+1].ext_price_amt 
		LET idx = idx+1 
	END IF 
	
	DECLARE c2_creditrates CURSOR FOR 
	SELECT * FROM creditrates 
	WHERE line_num = pr_creditdetl.line_num 
	AND cred_num = pr_creditdetl.cred_num 
	AND rate_type != "PRP" 
	AND rate_type != "CRP" 
	AND rate_type != "LRP" 
	AND cmpy_code = p_cmpy 
	FOREACH c2_creditrates INTO pr_creditrates.* 
		LET idx = idx + 1 
		SELECT short_desc_text INTO pa_creditrates[idx].short_desc_text 
		FROM ordrates 
		WHERE cmpy_code = p_cmpy 
		AND rate_type_code = pr_creditrates.rate_type 
		AND ord_ind = modu_rec_ordhead.ord_ind 
		IF status = notfound THEN 
			LET pa_creditrates[idx].short_desc_text = "***************" 
		END IF 
		LET pa_type[idx].rate_type = pr_creditrates.rate_type 
		LET pa_creditrates[idx].unit_price_amt = pr_creditrates.unit_price_amt 
		* pr_conv_qty 
		LET pa_creditrates[idx].ext_price_amt = (pr_creditrates.unit_price_amt 
		* pr_creditdetl.ship_qty) 
		LET pr_tot_unit_amt = pr_tot_unit_amt 
		+ pa_creditrates[idx].unit_price_amt 
		LET pr_tot_ext_amt = pr_tot_ext_amt 
		+ pa_creditrates[idx].ext_price_amt 
		IF idx = 10 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#U9113 idx records selected
	IF idx = 0 THEN 
		#Something went wrong
		CLOSE WINDOW w181 
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36, 
	NEXT KEY f36 
	CALL set_count(idx) 
	DISPLAY pr_tot_unit_amt, pr_tot_ext_amt 
	TO tot_unit_amt, tot_ext_amt 

	LET msgresp = kandoomsg("W",1008,"") 

	DISPLAY ARRAY pa_creditrates TO sr_ordlinerate.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-creditrates") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 


	CLOSE WINDOW w181 
	OPTIONS NEXT KEY f3 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION disp_cred_pricebreak(pr_del_type_ind, pr_cred_num, pr_line_num)
###########################################################################


###########################################################################
# FUNCTION disp_delivinst(pr_pick_num)
#
#
###########################################################################
FUNCTION disp_delivinst(pr_pick_num) 
	DEFINE 
	pr_pick_num LIKE delivhead.pick_num, 
	pr_delinst RECORD LIKE delinst.*, 
	instr_text CHAR(240), 
	blend_text CHAR(120), 
	spec_text CHAR(240), 
	query_text CHAR(150), 
	i,x,y,idx,scrn SMALLINT 

	OPEN WINDOW w167 with FORM "W167" 
	CALL windecoration_w("W167") -- albo kd-767 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference 

	LET query_text = "SELECT * FROM delinst ", 
	"WHERE instr_num between ? AND ? ", 
	" AND order_num = '", modu_rec_ordhead.order_num, "' ", 
	" AND pick_num = '", pr_pick_num, "' ", 
	"ORDER BY instr_num " 
	PREPARE s_delinst FROM query_text 
	DECLARE c_delinst CURSOR FOR s_delinst 
	#  Get first 4 lines - Delivery Instructions
	LET x = 1 
	LET y = 4 
	OPEN c_delinst USING x, y 
	LET x = 1 
	LET y = 60 
	FOREACH c_delinst INTO pr_delinst.* 
		LET instr_text[x,y] = pr_delinst.instr_text 
		LET x = x + 60 
		LET y = y + 60 
	END FOREACH 
	#  Get next 2 lines - Blend Instructions
	LET x = 5 
	LET y = 6 
	OPEN c_delinst USING x, y 
	LET x = 1 
	LET y = 60 
	FOREACH c_delinst INTO pr_delinst.* 
		LET blend_text[x,y] = pr_delinst.instr_text 
		LET x = x + 60 
		LET y = y + 60 
	END FOREACH 
	#  Get next 4 lines - Special Instructions
	LET x = 7 
	LET y = 10 
	OPEN c_delinst USING x, y 
	LET x = 1 
	LET y = 60 
	FOREACH c_delinst INTO pr_delinst.* 
		LET spec_text[x,y] = pr_delinst.instr_text 
		LET x = x + 60 
		LET y = y + 60 
	END FOREACH 
	DISPLAY BY NAME instr_text, 
	blend_text, 
	spec_text 

	#LET msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w167 
END FUNCTION 
###########################################################################
# END FUNCTION disp_delivinst(pr_pick_num)
###########################################################################


###########################################################################
# FUNCTION disp_unconf(pr_pick_num)
#
#
###########################################################################
FUNCTION disp_unconf(pr_pick_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_pick_num LIKE delivhead.pick_num, 
	pr_product RECORD LIKE product.*, 
	pr_delivdetl RECORD LIKE delivdetl.*, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pr_transptype RECORD LIKE transptype.*, 
	pa_delivdetl array[200] OF RECORD 
		pick_line_num LIKE delivdetl.pick_line_num, 
		part_code LIKE delivdetl.part_code, 
		desc_text LIKE product.desc_text, 
		picked_qty LIKE delivdetl.picked_qty, 
		desc2_text LIKE product.desc2_text 
	END RECORD, 
	idx SMALLINT 

	SELECT * INTO pr_delivhead.* FROM delivhead 
	WHERE pick_num = pr_pick_num 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW w227 with FORM "W227" 
	CALL windecoration_w("W227") -- albo kd-767 
	DISPLAY "Delivery" TO detail_type 
	attribute(white) 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	pr_delivhead.order_num, 
	pr_delivhead.pick_num, 
	pr_delivhead.del_num, 
	pr_delivhead.pick_date, 
	pr_delivhead.transp_type_code, 
	pr_delivhead.vehicle_code 

	SELECT * INTO pr_transptype.* FROM transptype 
	WHERE transp_type_code = pr_delivhead.transp_type_code 
	AND cmpy_code = p_cmpy 
	DISPLAY pr_transptype.desc_text TO transp_text 

	IF pr_delivhead.status_ind = "9" THEN 
		DISPLAY "CANCELLED" TO cancel_text 

	END IF 
	IF pr_delivhead.pallet_qty != 0 THEN 
		DISPLAY "Pallets..........." 
		TO pallet_text 
		attribute(white) 
		DISPLAY BY NAME pr_delivhead.pallet_qty 

	END IF 
	LET idx = 0 
	DECLARE c_delivdetl CURSOR FOR 
	SELECT * FROM delivdetl 
	WHERE pick_num = pr_delivhead.pick_num 
	AND cmpy_code = p_cmpy 
	ORDER BY pick_line_num 
	FOREACH c_delivdetl INTO pr_delivdetl.* 
		LET idx = idx + 1 
		LET pa_delivdetl[idx].pick_line_num = pr_delivdetl.pick_line_num 
		LET pa_delivdetl[idx].part_code = pr_delivdetl.part_code 
		LET pa_delivdetl[idx].picked_qty = pr_delivdetl.picked_qty 
		SELECT * INTO pr_product.* FROM product 
		WHERE part_code = pr_delivdetl.part_code 
		AND cmpy_code = p_cmpy 
		LET pa_delivdetl[idx].desc_text = pr_product.desc_text 
		LET pa_delivdetl[idx].desc2_text = pr_product.desc2_text 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#U9113 idx records selected
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1074,"") 

	#1074  F3/F4 ESC TO cont
	DISPLAY ARRAY pa_delivdetl TO sr_delivdetl.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-delivdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F8) 
			LET idx = arr_curr() 
			CALL disp_delivinst(pr_delivhead.pick_num) 

	END DISPLAY 
	CLOSE WINDOW w227 
END FUNCTION 
###########################################################################
# END FUNCTION disp_unconf(pr_pick_num)
###########################################################################


###########################################################################
# FUNCTION show_exp(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION show_exp(pr_cmpy_code, pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_exphead RECORD LIKE exphead.*, 
	pr_delivhead RECORD LIKE delivhead.*, 
	pr_expdetl RECORD LIKE expdetl.*, 
	pa_delivhead array[300] OF RECORD 
		del_num LIKE delivhead.del_num 
	END RECORD, 
	pa_exphead array[300] OF RECORD 
		pick_num LIKE delivhead.pick_num, 
		contain_text LIKE exphead.contain_text, 
		seal_text LIKE exphead.seal_text, 
		confirm_date LIKE exphead.confirm_date, 
		inv_num LIKE exphead.inv_num 
	END RECORD, 
	idx,scrn SMALLINT 

	LET glob_rec_kandoouser.cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",5006,"") 
		## 5006 Maxbrick parameters NOT SET up
		RETURN 
	END IF 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9302,"") 
		## 9302 Logic Error: Order NOT found
		RETURN 
	END IF 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("W",9303,"") 
		## 9303 Logic Error: Customer does NOT exist
		RETURN 
	END IF 
	OPEN WINDOW w306 with FORM "W306" 

	CALL windecoration_w("W306") -- albo kd-767 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.order_num, 
	modu_rec_ordhead.ord_text 


	DECLARE c_export CURSOR FOR 
	SELECT delivhead.*,exphead.* 
	FROM delivhead, exphead 
	WHERE delivhead.order_num = pr_order_num 
	AND delivhead.cmpy_code = p_cmpy 
	AND exphead.pick_num = delivhead.pick_num 
	AND exphead.cmpy_code = p_cmpy 

	LET idx = 0 
	FOREACH c_export INTO pr_delivhead.*,pr_exphead.* 
		LET idx = idx + 1 
		LET pa_delivhead[idx].del_num = pr_delivhead.del_num 
		LET pa_exphead[idx].pick_num = pr_delivhead.pick_num 
		LET pa_exphead[idx].contain_text = pr_exphead.contain_text 
		LET pa_exphead[idx].seal_text = pr_exphead.seal_text 
		LET pa_exphead[idx].confirm_date = pr_exphead.confirm_date 
		LET pa_exphead[idx].inv_num = pr_exphead.inv_num 
		IF idx > 299 THEN 
			LET msgresp = kandoomsg("U",6100,idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("U",9113,idx) 
	#U9113 idx records selected
	CALL set_count(idx) 
	IF idx = 0 THEN 
		SLEEP 2 
		CLOSE WINDOW w306 
		RETURN 
	END IF 
	LET msgresp = kandoomsg("W",1007,"") 
	#1007  RETURN on line TO view

	DISPLAY ARRAY pa_exphead TO sr_exphead.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-exphead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (RETURN) 
			LET idx = arr_curr() 
			CALL disp_delivdetl(pa_delivhead[idx].del_num) 

	END DISPLAY 
	CLOSE WINDOW w306 
END FUNCTION 
###########################################################################
# END FUNCTION show_exp(pr_cmpy_code, pr_order_num)
###########################################################################


#                                                                      #
########################################################################
#
#      W15h - Order Inquiry
#                  allows the user TO view Order Information - Reporting Codes
#

###########################################################################
# FUNCTION disp_report(pr_cmpy, pr_order_num)
#
#
###########################################################################
FUNCTION disp_report(pr_cmpy, pr_order_num) 
	DEFINE 
	pr_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	modu_rec_mbparms RECORD LIKE mbparms.*, 
	pr_userref RECORD LIKE userref.*, 
	pr_valid_flag, seq_num SMALLINT, 
	msgresp LIKE language.yes_flag 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = pr_cmpy 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = pr_cmpy 
	SELECT * INTO modu_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = pr_cmpy 
	OPEN WINDOW w105 with FORM "W105" 
	CALL windecoration_w("W105") -- albo kd-767 
	LET modu_rec_mbparms.ref1_text = make_rep_prompt(modu_rec_mbparms.ref1_text) 
	LET modu_rec_mbparms.ref2_text = make_rep_prompt(modu_rec_mbparms.ref2_text) 
	LET modu_rec_mbparms.ref3_text = make_rep_prompt(modu_rec_mbparms.ref3_text) 
	LET modu_rec_mbparms.ref4_text = make_rep_prompt(modu_rec_mbparms.ref4_text) 
	LET modu_rec_mbparms.ref5_text = make_rep_prompt(modu_rec_mbparms.ref5_text) 
	LET modu_rec_mbparms.ref6_text = make_rep_prompt(modu_rec_mbparms.ref6_text) 
	LET modu_rec_mbparms.ref7_text = make_rep_prompt(modu_rec_mbparms.ref7_text) 
	LET modu_rec_mbparms.ref8_text = make_rep_prompt(modu_rec_mbparms.ref8_text) 
	LET modu_rec_mbparms.flag1_text = make_rep_prompt(modu_rec_mbparms.flag1_text) 
	LET modu_rec_mbparms.flag2_text = make_rep_prompt(modu_rec_mbparms.flag2_text) 
	LET modu_rec_mbparms.flag3_text = make_rep_prompt(modu_rec_mbparms.flag3_text) 
	LET modu_rec_mbparms.flag4_text = make_rep_prompt(modu_rec_mbparms.flag4_text) 
	LET modu_rec_mbparms.flag5_text = make_rep_prompt(modu_rec_mbparms.flag5_text) 
	LET modu_rec_mbparms.flag6_text = make_rep_prompt(modu_rec_mbparms.flag6_text) 
	LET modu_rec_mbparms.flag7_text = make_rep_prompt(modu_rec_mbparms.flag7_text) 
	LET modu_rec_mbparms.flag8_text = make_rep_prompt(modu_rec_mbparms.flag8_text) 

	DISPLAY BY NAME modu_rec_mbparms.ref1_text, 
	modu_rec_mbparms.ref2_text, 
	modu_rec_mbparms.ref3_text, 
	modu_rec_mbparms.ref4_text, 
	modu_rec_mbparms.ref5_text, 
	modu_rec_mbparms.ref6_text, 
	modu_rec_mbparms.ref7_text, 
	modu_rec_mbparms.ref8_text, 
	modu_rec_mbparms.flag1_text, 
	modu_rec_mbparms.flag2_text, 
	modu_rec_mbparms.flag3_text, 
	modu_rec_mbparms.flag4_text, 
	modu_rec_mbparms.flag5_text, 
	modu_rec_mbparms.flag6_text, 
	modu_rec_mbparms.flag7_text, 
	modu_rec_mbparms.flag8_text 
	attribute(white) 

	DISPLAY BY NAME modu_rec_ordhead.ref1_code, 
	modu_rec_ordhead.ref2_code, 
	modu_rec_ordhead.ref3_code, 
	modu_rec_ordhead.ref4_code, 
	modu_rec_ordhead.ref5_code, 
	modu_rec_ordhead.ref6_code, 
	modu_rec_ordhead.ref7_code, 
	modu_rec_ordhead.ref8_code, 
	modu_rec_ordhead.flag1_ind, 
	modu_rec_ordhead.flag2_ind, 
	modu_rec_ordhead.flag3_ind, 
	modu_rec_ordhead.flag4_ind, 
	modu_rec_ordhead.flag5_ind, 
	modu_rec_ordhead.flag6_ind, 
	modu_rec_ordhead.flag7_ind, 
	modu_rec_ordhead.flag8_ind 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"1",modu_rec_ordhead.ref1_code) 
	DISPLAY pr_userref.ref_desc_text TO ref1_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"2",modu_rec_ordhead.ref2_code) 
	DISPLAY pr_userref.ref_desc_text TO ref2_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"3",modu_rec_ordhead.ref3_code) 
	DISPLAY pr_userref.ref_desc_text TO ref3_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"4",modu_rec_ordhead.ref4_code) 
	DISPLAY pr_userref.ref_desc_text TO ref4_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"5",modu_rec_ordhead.ref5_code) 
	DISPLAY pr_userref.ref_desc_text TO ref5_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"6",modu_rec_ordhead.ref6_code) 
	DISPLAY pr_userref.ref_desc_text TO ref6_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"7",modu_rec_ordhead.ref7_code) 
	DISPLAY pr_userref.ref_desc_text TO ref7_desc_text 

	LET pr_userref.ref_desc_text = user_ref(pr_cmpy,"8",modu_rec_ordhead.ref8_code) 
	DISPLAY pr_userref.ref_desc_text TO ref8_desc_text 

	#LET msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	CLOSE WINDOW w105 
END FUNCTION 
###########################################################################
# END FUNCTION disp_report(pr_cmpy, pr_order_num)
###########################################################################


###########################################################################
# FUNCTION user_ref(pr_cmpy,pr_ref_num,pr_ref_code)
#
#
###########################################################################
FUNCTION user_ref(pr_cmpy,pr_ref_num,pr_ref_code) 
	DEFINE 
	pr_cmpy LIKE company.cmpy_code, 
	pr_ref_num LIKE userref.ref_ind, 
	pr_ref_code LIKE customer.ref1_code, 
	pr_desc_text LIKE userref.ref_desc_text 

	SELECT ref_desc_text INTO pr_desc_text FROM userref 
	WHERE cmpy_code = pr_cmpy 
	AND source_ind = "W" 
	AND ref_ind = pr_ref_num 
	AND ref_code = pr_ref_code 
	RETURN pr_desc_text 
END FUNCTION 
###########################################################################
# END FUNCTION user_ref(pr_cmpy,pr_ref_num,pr_ref_code)
###########################################################################


###########################################################################
# FUNCTION make_rep_prompt(pr_ref_text)
#
#
###########################################################################
FUNCTION make_rep_prompt(pr_ref_text) 
	DEFINE 
	pr_temp_text CHAR(40), 
	pr_ref_text LIKE arparms.ref1_text 

	IF pr_ref_text IS NULL THEN 
		LET pr_temp_text = NULL 
	ELSE 
		LET pr_temp_text = pr_ref_text clipped, "...................." 
	END IF 
	RETURN pr_temp_text 
END FUNCTION 
###########################################################################
# END FUNCTION make_rep_prompt(pr_ref_text)
###########################################################################

#                                                                      #
########################################################################
#
#      W15i - Order Inquiry
#                  allows the user TO view Order Information - Notes
#

###########################################################################
# FUNCTION disp_notes(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION disp_notes(pr_cmpy_code, pr_order_num) 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	pr_ordernote RECORD LIKE ordernote.*, 
	pa_ordernote array[200] OF RECORD 
		scroll_flag CHAR(1), 
		note_date LIKE ordernote.note_date, 
		note_text LIKE ordernote.note_text 
	END RECORD, 
	msgresp LIKE language.yes_flag, 
	formheading CHAR(5), 
	idx,scrn SMALLINT 

	LET formheading = "Order" 
	OPEN WINDOW w188 with FORM "W188" 
	CALL windecoration_w("W188") -- albo kd-767 

	DISPLAY BY NAME formheading 
	attribute(white) 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cmpy_code = modu_rec_ordhead.cmpy_code 
	AND cust_code = modu_rec_ordhead.cust_code 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference 

	LET idx = 0 
	DECLARE c_ordernote CURSOR FOR 
	SELECT * FROM ordernote 
	WHERE order_num = pr_order_num 
	AND cmpy_code = pr_cmpy_code 
	ORDER BY note_date, note_num 
	FOREACH c_ordernote INTO pr_ordernote.* 
		LET idx = idx + 1 
		LET pa_ordernote[idx].note_date = pr_ordernote.note_date 
		LET pa_ordernote[idx].note_text = pr_ordernote.note_text 
		IF idx = 200 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
		LET pa_ordernote[1].note_date = NULL 
	END IF 
	CALL set_count(idx) 
	FOR idx = (idx+1) TO 200 
		INITIALIZE pa_ordernote[idx].* TO NULL 
	END FOR 

	LET msgresp = kandoomsg("W",1008,"") 
	#1008 F3/F4 Page Down/Up - ESC TO continue
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY pa_ordernote WITHOUT DEFAULTS FROM sr_ordernote.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-ordernote") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			DISPLAY pa_ordernote[idx].* TO sr_ordernote[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_ordernote[idx].scroll_flag = NULL 
			DISPLAY pa_ordernote[idx].scroll_flag 
			TO sr_ordernote[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("right") THEN 
				IF pa_ordernote[idx+1].note_date IS NULL 
				OR arr_curr() >= (arr_count() + 1) THEN 
					LET msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD note_date 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_ordernote[idx].* TO sr_ordernote[scrn].* 


	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w188 
END FUNCTION 
###########################################################################
# END FUNCTION disp_notes(pr_cmpy_code, pr_order_num)
###########################################################################


#                                                                      #
########################################################################
#
#      W15j - Order Inquiry
#                  allows the user TO view Order Information
#                                                       - Delivery Instructions
#

###########################################################################
# FUNCTION disp_del_inst(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION disp_del_inst(pr_cmpy_code, pr_order_num) 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	pr_orderinst RECORD LIKE orderinst.*, 
	msgresp LIKE language.yes_flag, 
	instr_text CHAR(240), 
	blend_text CHAR(120), 
	query_text CHAR(150), 
	i,x,y SMALLINT 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = pr_cmpy_code 
	OPEN WINDOW w108 with FORM "W108" 
	CALL windecoration_w("W108") -- albo kd-767 
	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference 

	LET query_text = "SELECT * FROM orderinst ", 
	"WHERE instr_num between ? AND ? ", 
	"AND order_num = '", modu_rec_ordhead.order_num, "' ", 
	"AND cmpy_code = '", pr_cmpy_code, "' ", 
	"ORDER BY instr_num " 
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE s_orderinst FROM query_text 
	DECLARE c2_orderinst CURSOR FOR s_orderinst 
	#  Get first 4 lines - Delivery Instructions
	LET x = 1 
	LET y = 4 
	OPEN c2_orderinst USING x, y 
	LET x = 1 
	LET y = 60 
	FOREACH c2_orderinst INTO pr_orderinst.* 
		LET instr_text[x,y] = pr_orderinst.instr_text 
		LET x = x + 60 
		LET y = y + 60 
	END FOREACH 
	#  Get next 2 lines - Blend Instructions
	LET x = 5 
	LET y = 6 
	OPEN c2_orderinst USING x, y 
	LET x = 1 
	LET y = 60 
	FOREACH c2_orderinst INTO pr_orderinst.* 
		LET blend_text[x,y] = pr_orderinst.instr_text 
		LET x = x + 60 
		LET y = y + 60 
	END FOREACH 
	OPTIONS SQL interrupt off 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	DISPLAY instr_text, 
	blend_text 
	TO instr_text, 
	blend_text 

	#LET msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w108 
END FUNCTION 
###########################################################################
# END FUNCTION disp_del_inst(pr_cmpy_code, pr_order_num)
###########################################################################


#                                                                      #
########################################################################
#
#      W15k - Order Inquiry
#                  allows the user TO view Order Information - Pallets
#


###########################################################################
# FUNCTION disp_pallet(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION disp_pallet(pr_cmpy_code, pr_order_num) 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	modu_rec_customer RECORD LIKE customer.*, 
	pr_pallet RECORD LIKE pallet.*, 
	pr_custpallet RECORD LIKE custpallet.*, 
	pa_pallet array[300] OF RECORD 
		scroll_flag CHAR(1), 
		tran_date LIKE pallet.tran_date, 
		tran_type CHAR(8), 
		trans_num LIKE pallet.trans_num, 
		unit_price_amt LIKE pallet.unit_price_amt, 
		trans_qty LIKE pallet.trans_qty 
	END RECORD, 
	pr_outstand_qty LIKE pallet.trans_qty, 
	pr_outstand_amt LIKE custpallet.bal_amt, 
	idx SMALLINT, 
	msgresp LIKE language.yes_flag 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = pr_cmpy_code 
	OPEN WINDOW w222 with FORM "W222" 
	CALL windecoration_w("W222") -- albo kd-767 
	DISPLAY BY NAME modu_rec_customer.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_ordhead.order_num 

	LET idx = 0 
	DECLARE c_pallet CURSOR FOR 
	SELECT * FROM pallet 
	WHERE order_num = modu_rec_ordhead.order_num 
	AND cmpy_code = pr_cmpy_code 
	ORDER BY tran_date,seq_num 
	LET pr_outstand_qty = 0 
	LET pr_outstand_amt = 0 
	FOREACH c_pallet INTO pr_pallet.* 
		LET idx = idx + 1 
		LET pa_pallet[idx].tran_date = pr_pallet.tran_date 
		CASE 
			WHEN pr_pallet.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				LET pa_pallet[idx].tran_type = "DELIVERY" 
			WHEN pr_pallet.tran_type_ind = "DE" 
				LET pa_pallet[idx].tran_type = "DEPOSIT" 
			WHEN pr_pallet.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				LET pa_pallet[idx].tran_type = "CREDIT" 
			WHEN pr_pallet.tran_type_ind = "RE" 
				LET pa_pallet[idx].tran_type = "REFUND" 
			WHEN pr_pallet.tran_type_ind = "WO" 
				LET pa_pallet[idx].tran_type = "WRITEOFF" 
			WHEN pr_pallet.tran_type_ind = "SC" 
				LET pa_pallet[idx].tran_type = "CLEARANCE" 
			WHEN pr_pallet.tran_type_ind = "SR" 
				LET pa_pallet[idx].tran_type = "SURPLUS" 
			WHEN pr_pallet.tran_type_ind = "TX" 
				LET pa_pallet[idx].tran_type = "TRANSFER" 
		END CASE 
		LET pa_pallet[idx].trans_num = pr_pallet.trans_num 
		LET pa_pallet[idx].unit_price_amt = pr_pallet.unit_price_amt 
		LET pa_pallet[idx].trans_qty = pr_pallet.trans_qty 
		IF idx = 300 THEN 
			LET msgresp = kandoomsg("W",9021,idx) 
			#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET pr_outstand_amt = modu_rec_ordhead.out_pallet_qty * modu_rec_ordhead.pallet_price_amt 

	DISPLAY modu_rec_ordhead.out_pallet_qty, 
	pr_outstand_amt 
	TO outstand_qty, 
	bal_amt 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1008,"") 

	DISPLAY ARRAY pa_pallet TO sr_pallet.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","display-arr-pallet") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 


	CLOSE WINDOW w222 
END FUNCTION 
###########################################################################
# END FUNCTION disp_pallet(pr_cmpy_code, pr_order_num)
###########################################################################


#                                                                      #
########################################################################
#
#      W15l - Order Inquiry
#                  allows the user TO view Order Information - Cash Receipts
#
###########################################################################
# FUNCTION disp_cashreceipt(pr_cmpy_code, pr_order_num)
#
#
###########################################################################
FUNCTION disp_cashreceipt(pr_cmpy_code, pr_order_num) 
	DEFINE 
	pr_cmpy_code LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pa_cashreceipt array[250] OF RECORD 
		scroll_flag CHAR(1), 
		cash_num LIKE cashreceipt.cash_num, 
		cheque_text LIKE cashreceipt.cheque_text, 
		cash_date LIKE cashreceipt.cash_date, 
		year_num LIKE cashreceipt.year_num, 
		period_num LIKE cashreceipt.period_num, 
		cash_amt LIKE cashreceipt.cash_amt, 
		applied_amt LIKE cashreceipt.applied_amt, 
		posted_flag LIKE cashreceipt.posted_flag 
	END RECORD, 
	idx, scrn SMALLINT, 
	msgresp LIKE language.yes_flag 

	LET glob_rec_kandoouser.cmpy_code = pr_cmpy_code 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	SELECT * INTO modu_rec_customer.* FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 
	OPEN WINDOW w223 with FORM "W223" 
	CALL windecoration_w("W223") -- albo kd-767 
	DISPLAY BY NAME modu_rec_customer.name_text, 
	modu_rec_customer.cust_code, 
	modu_rec_ordhead.order_num 

	DISPLAY BY NAME modu_rec_customer.currency_code 
	attribute(green) 
	DECLARE c_cashreceipt CURSOR FOR 
	SELECT * INTO modu_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = modu_rec_customer.cust_code 
	AND order_num = modu_rec_ordhead.order_num 
	ORDER BY cash_num 
	LET idx = 0 
	FOREACH c_cashreceipt 
		LET idx = idx + 1 
		LET pa_cashreceipt[idx].cash_num = modu_rec_cashreceipt.cash_num 
		LET pa_cashreceipt[idx].cheque_text = modu_rec_cashreceipt.cheque_text 
		LET pa_cashreceipt[idx].cash_date = modu_rec_cashreceipt.cash_date 
		LET pa_cashreceipt[idx].year_num = modu_rec_cashreceipt.year_num 
		LET pa_cashreceipt[idx].period_num = modu_rec_cashreceipt.period_num 
		LET pa_cashreceipt[idx].cash_amt = modu_rec_cashreceipt.cash_amt 
		LET pa_cashreceipt[idx].applied_amt = modu_rec_cashreceipt.applied_amt 
		LET pa_cashreceipt[idx].posted_flag = modu_rec_cashreceipt.posted_flag 
		IF idx = 250 THEN 
			LET msgresp = kandoomsg("W",9021,idx) 
			#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	LET msgresp=kandoomsg("W",1007,"") 
	#1007 F3/F4 RETURN
	INPUT ARRAY pa_cashreceipt WITHOUT DEFAULTS FROM sr_cashreceipt.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-cashreceipt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_cashreceipt[idx].* TO sr_cashreceipt[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_cashreceipt[idx].scroll_flag = NULL 
			DISPLAY pa_cashreceipt[idx].scroll_flag 
			TO sr_cashreceipt[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_cashreceipt[idx+1].cash_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_cashreceipt[idx+9].cash_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD cash_num 
			CALL disp_cash(pa_cashreceipt[idx].cash_num) 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_cashreceipt[idx].* TO sr_cashreceipt[scrn].* 


	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w223 
END FUNCTION 
###########################################################################
# END FUNCTION disp_cashreceipt(pr_cmpy_code, pr_order_num)
###########################################################################


###########################################################################
# FUNCTION disp_cash(pr_cashnum)
#
#
###########################################################################
FUNCTION disp_cash(pr_cashnum) 
	DEFINE 
	pr_cashnum LIKE cashreceipt.cash_num, 
	modu_rec_cashreceipt RECORD LIKE cashreceipt.*, 
	msgresp LIKE language.yes_flag, 
	pr_reference_text LIKE kandooword.reference_text 

	SELECT * INTO modu_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_cmpy 
	AND cash_num = pr_cashnum 
	OPEN WINDOW w224 with FORM "W224" 
	CALL windecoration_w("W224") -- albo kd-767 
	LET pr_reference_text = kandooword("cashreceipt.cash_type_ind", 
	modu_rec_cashreceipt.cash_type_ind) 
	DISPLAY BY NAME modu_rec_customer.currency_code, 
	modu_rec_cashreceipt.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_cashreceipt.cash_num, 
	modu_rec_cashreceipt.cash_date, 
	modu_rec_cashreceipt.cash_type_ind, 
	pr_reference_text, 
	modu_rec_cashreceipt.cash_amt, 
	modu_rec_cashreceipt.applied_amt, 
	modu_rec_cashreceipt.disc_amt, 
	modu_rec_cashreceipt.entry_code, 
	modu_rec_cashreceipt.entry_date, 
	modu_rec_cashreceipt.on_state_flag, 
	modu_rec_cashreceipt.year_num, 
	modu_rec_cashreceipt.period_num, 
	modu_rec_cashreceipt.cash_acct_code, 
	modu_rec_cashreceipt.posted_flag, 
	modu_rec_cashreceipt.cheque_text, 
	modu_rec_cashreceipt.bank_text, 
	modu_rec_cashreceipt.chq_date, 
	modu_rec_cashreceipt.drawer_text, 
	modu_rec_cashreceipt.branch_text, 
	modu_rec_cashreceipt.com1_text, 
	modu_rec_cashreceipt.com2_text 

	LET msgresp = kandoomsg("W",8040,"") 
	#8040 View Applications? (Y/N)
	IF msgresp = "Y" THEN 
		CALL disp_cash_applns(modu_rec_cashreceipt.cash_num) 
	END IF 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w224 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION disp_cash(pr_cashnum)
#
#
###########################################################################


###########################################################################
# FUNCTION disp_cash_applns(pr_recp_num)
#
#
###########################################################################
FUNCTION disp_cash_applns(pr_recp_num) 
	DEFINE 
	pr_recp_num LIKE cashreceipt.cash_num, 
	pr_invoicepay RECORD LIKE invoicepay.*, 
	pa_invoicepay array[200] OF RECORD 
		scroll_flag CHAR(1), 
		appl_num LIKE invoicepay.appl_num, 
		inv_num LIKE invoicepay.inv_num, 
		apply_num LIKE invoicepay.apply_num, 
		pay_date LIKE invoicepay.pay_date, 
		pay_amt LIKE invoicepay.pay_amt, 
		disc_amt LIKE invoicepay.disc_amt 
	END RECORD, 
	idx, scrn SMALLINT, 
	msgresp LIKE language.yes_flag 

	OPEN WINDOW w225 with FORM "W225" 
	CALL windecoration_w("W225") -- albo kd-767 
	SELECT * INTO modu_rec_cashreceipt.* FROM cashreceipt 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = modu_rec_ordhead.cust_code 
	AND cash_num = pr_recp_num 
	DISPLAY BY NAME modu_rec_customer.currency_code 

	LET pr_invoicepay.cust_code = modu_rec_cashreceipt.cust_code 
	LET pr_invoicepay.ref_num = modu_rec_cashreceipt.cash_num 
	DISPLAY BY NAME modu_rec_cashreceipt.cust_code, 
	modu_rec_customer.name_text, 
	modu_rec_cashreceipt.cash_num, 
	modu_rec_cashreceipt.cash_amt, 
	modu_rec_cashreceipt.applied_amt, 
	modu_rec_cashreceipt.cash_date 

	DECLARE c_invoicepay CURSOR FOR 
	SELECT * INTO pr_invoicepay.* FROM invoicepay 
	WHERE invoicepay.cmpy_code = p_cmpy 
	AND invoicepay.cust_code = modu_rec_cashreceipt.cust_code 
	AND invoicepay.ref_num = modu_rec_cashreceipt.cash_num 
	AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
	ORDER BY cust_code, ref_num, appl_num 
	LET idx = 0 
	FOREACH c_invoicepay 
		LET idx = idx + 1 
		LET pa_invoicepay[idx].appl_num = pr_invoicepay.appl_num 
		LET pa_invoicepay[idx].inv_num = pr_invoicepay.inv_num 
		LET pa_invoicepay[idx].apply_num = pr_invoicepay.apply_num 
		LET pa_invoicepay[idx].pay_date = pr_invoicepay.pay_date 
		LET pa_invoicepay[idx].pay_amt = pr_invoicepay.pay_amt 
		LET pa_invoicepay[idx].disc_amt = pr_invoicepay.disc_amt 
		IF idx = 200 THEN 
			LET msgresp = kandoomsg("W",9021,idx) 
			#9021 First idx entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(idx) 
	LET msgresp=kandoomsg("W",1007,"")	#1007 F3/F4 RETURN
	INPUT ARRAY pa_invoicepay WITHOUT DEFAULTS FROM sr_invoicepay.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-invoicepay") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_invoicepay[idx].* TO sr_invoicepay[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_invoicepay[idx].scroll_flag = NULL 
			DISPLAY pa_invoicepay[idx].scroll_flag 
			TO sr_invoicepay[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_invoicepay[idx+1].appl_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_invoicepay[idx+9].appl_num IS NULL		OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("G",9001,"")			#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			
		BEFORE FIELD appl_num 
			CALL disp_disc_per_head(pa_invoicepay[idx].inv_num) 
			NEXT FIELD scroll_flag 

		BEFORE FIELD inv_num 
			CALL disp_disc_per_head(pa_invoicepay[idx].inv_num) 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			DISPLAY pa_invoicepay[idx].* TO sr_invoicepay[scrn].* 


	END INPUT 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW w225 
END FUNCTION 
###########################################################################
# FUNCTION disp_cash_applns(pr_recp_num)
#
#
###########################################################################


###########################################################################
# FUNCTION disp_disc_per_head(pr_invnum)
#
#
###########################################################################
FUNCTION disp_disc_per_head(pr_invnum) 
	DEFINE 
	pr_invnum LIKE invoicehead.inv_num, 
	pv_name_text LIKE customer.name_text, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	ref_text CHAR(32), 
	pr_doc_ind_text CHAR(3), 
	pr_inv_ref1_text LIKE arparms.inv_ref1_text, 
	pr_name_text LIKE salesperson.name_text, 
	pr_desc_text LIKE territory.desc_text, 
	msgresp LIKE language.yes_flag 

	SELECT inv_ref1_text INTO pr_inv_ref1_text FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	LET ref_text = pr_inv_ref1_text clipped, "................" 
	SELECT * INTO pr_invoicehead.* FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = pr_invnum 
	AND cust_code = modu_rec_ordhead.cust_code 
	SELECT name_text INTO pr_name_text FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = pr_invoicehead.sale_code 
	IF sqlca.sqlcode = 0 THEN 
		LET pr_name_text = pr_name_text[1,25] 
	END IF 
	SELECT desc_text INTO pr_desc_text FROM territory 
	WHERE cmpy_code = p_cmpy 
	AND terr_code = pr_invoicehead.territory_code 
	IF sqlca.sqlcode = 0 THEN 
		LET pr_desc_text = pr_desc_text[1,25] 
	END IF 
	CASE pr_invoicehead.inv_ind 
		WHEN "1" 
			LET pr_doc_ind_text = "A-R" 
		WHEN "2" 
			LET pr_doc_ind_text = "NOR" 
		WHEN "3" 
			LET pr_doc_ind_text = TRAN_TYPE_JOB_JOB 
		WHEN "4" 
			LET pr_doc_ind_text = "ADJ" 
		WHEN "5" 
			LET pr_doc_ind_text = "PRE" 
		OTHERWISE 
			LET pr_doc_ind_text = "NOR" 
	END CASE 
	OPEN WINDOW w226 with FORM "W226" 
	CALL windecoration_w("W226") -- albo kd-767 
	DISPLAY ref_text TO formonly.inv_ref1_text 
	attribute(white) 
	IF pr_invoicehead.org_cust_code IS NOT NULL THEN 
		SELECT name_text INTO pv_name_text FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = pr_invoicehead.org_cust_code 
		DISPLAY pv_name_text TO formonly.org_name_text 

	END IF 
	IF pr_invoicehead.rev_date = '31/12/1899' THEN 
		LET pr_invoicehead.rev_date = NULL 
	END IF 
	IF pr_invoicehead.ship_date = '31/12/1899' THEN 
		LET pr_invoicehead.ship_date = NULL 
	END IF 
	IF pr_invoicehead.due_date = '31/12/1899' THEN 
		LET pr_invoicehead.due_date = NULL 
	END IF 
	IF pr_invoicehead.stat_date = '31/12/1899' THEN 
		LET pr_invoicehead.stat_date = NULL 
	END IF 
	IF pr_invoicehead.paid_date = '31/12/1899' THEN 
		LET pr_invoicehead.paid_date = NULL 
	END IF 
	IF pr_invoicehead.posted_flag = 'N' THEN 
		LET pr_invoicehead.post_date = NULL 
		LET pr_invoicehead.jour_num = NULL 
	END IF 
	DISPLAY modu_rec_customer.name_text, 
	modu_rec_customer.name_text, 
	modu_rec_customer.addr1_text, 
	modu_rec_customer.addr2_text, 
	modu_rec_customer.city_text, 
	modu_rec_customer.state_code, 
	modu_rec_customer.post_code, 
	pr_invoicehead.name_text, 
	pr_invoicehead.addr1_text, 
	pr_invoicehead.addr2_text, 
	pr_invoicehead.city_text, 
	pr_invoicehead.state_code, 
	pr_invoicehead.post_code, 
	pr_name_text, 
	pr_desc_text, 
	pr_doc_ind_text 
	TO customer.name_text, 
	formonly.name_text, 
	customer.addr1_text, 
	customer.addr2_text, 
	customer.city_text, 
	customer.state_code, 
	customer.post_code, 
	invoicehead.name_text, 
	invoicehead.addr1_text, 
	invoicehead.addr2_text, 
	invoicehead.city_text, 
	invoicehead.state_code, 
	invoicehead.post_code, 
	salesperson.name_text, 
	territory.desc_text, 
	formonly.doc_ind_text 

	DISPLAY BY NAME pr_invoicehead.cust_code, 
	pr_invoicehead.org_cust_code, 
	pr_invoicehead.ref_num, 
	pr_invoicehead.inv_num, 
	pr_invoicehead.inv_date, 
	pr_invoicehead.ord_num, 
	pr_invoicehead.sale_code, 
	pr_invoicehead.territory_code, 
	pr_invoicehead.com1_text, 
	pr_invoicehead.com2_text, 
	pr_invoicehead.goods_amt, 
	pr_invoicehead.freight_amt, 
	pr_invoicehead.hand_amt, 
	pr_invoicehead.tax_amt, 
	pr_invoicehead.total_amt, 
	pr_invoicehead.paid_amt, 
	pr_invoicehead.year_num, 
	pr_invoicehead.period_num, 
	pr_invoicehead.posted_flag, 
	pr_invoicehead.post_date, 
	pr_invoicehead.jour_num, 
	pr_invoicehead.entry_date, 
	pr_invoicehead.rev_date, 
	pr_invoicehead.ship_date, 
	pr_invoicehead.due_date, 
	pr_invoicehead.stat_date, 
	pr_invoicehead.paid_date 

	DISPLAY BY NAME modu_rec_customer.currency_code 

	#LET msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	CLOSE WINDOW w226 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION 
###########################################################################
# END FUNCTION disp_disc_per_head(pr_invnum)
###########################################################################


###########################################################################
# FUNCTION show_labouralloc(p_cmpy,pr_order_num)
#
#
###########################################################################
FUNCTION show_labouralloc(p_cmpy,pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	modu_rec_ordhead RECORD LIKE ordhead.*, 
	pr_labourer RECORD LIKE labourer.*, 
	pr_labourtrans RECORD LIKE labourtrans.*, 
	pa_labouralloc array[100] OF RECORD 
		scroll_flag CHAR(1), 
		labour_code LIKE labourer.labour_code, 
		name_text LIKE labourer.name_text, 
		lump_amt LIKE labouralloc.lump_amt, 
		alloc_per LIKE labouralloc.alloc_per, 
		pay_amt LIKE labouralloc.pay_amt 
	END RECORD, 
	pr_labouralloc RECORD LIKE labouralloc.*, 
	custname_desc LIKE customer.name_text, 
	area_to_cover LIKE ordhead.net_area_qty, 
	idx,scrn,cnt SMALLINT 

	OPEN WINDOW w343 with FORM "W343" 
	CALL windecoration_w("W343") -- albo kd-767 
	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	IF modu_rec_ordhead.comp_area_qty IS NULL THEN 
		LET modu_rec_ordhead.comp_area_qty = 0 
	END IF 
	IF modu_rec_ordhead.net_area_qty IS NULL THEN 
		LET modu_rec_ordhead.net_area_qty = 0 
	END IF 
	SELECT * INTO pr_labourtrans.* FROM labourtrans 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET pr_labourtrans.comp_to_per = 0 
		LET pr_labourtrans.pay_amt = 0 
		LET area_to_cover = 0 
	ELSE 
		LET area_to_cover =((pr_labourtrans.comp_to_per 
		* modu_rec_ordhead.net_area_qty) / 100) 
		- modu_rec_ordhead.comp_area_qty 
	END IF 
	SELECT name_text INTO custname_desc FROM customer 
	WHERE cust_code = modu_rec_ordhead.cust_code 
	AND cmpy_code = p_cmpy 

	DISPLAY BY NAME modu_rec_ordhead.cust_code, 
	custname_desc, 
	modu_rec_ordhead.ship_addr1_text, 
	modu_rec_ordhead.ship_addr2_text, 
	modu_rec_ordhead.ship_city_text, 
	modu_rec_ordhead.ship_state_code, 
	modu_rec_ordhead.ship_post_code, 
	modu_rec_ordhead.map_reference, 
	pr_labourtrans.comp_to_per, 
	area_to_cover, 
	pr_labourtrans.pay_amt, 
	modu_rec_ordhead.net_area_qty, 
	modu_rec_ordhead.comp_area_qty 

	DECLARE c_labouralloc CURSOR FOR 
	SELECT *,rowid FROM labouralloc 
	WHERE order_num = pr_order_num 
	LET idx = 0 
	FOREACH c_labouralloc INTO pr_labouralloc.* 
		LET idx = idx + 1 
		LET pa_labouralloc[idx].labour_code = pr_labouralloc.labour_code 
		SELECT * INTO pr_labourer.* FROM labourer 
		WHERE cmpy_code = p_cmpy 
		AND labour_code = pr_labouralloc.labour_code 
		LET pa_labouralloc[idx].name_text = pr_labourer.name_text 
		LET pa_labouralloc[idx].lump_amt = pr_labouralloc.lump_amt 
		LET pa_labouralloc[idx].alloc_per = pr_labouralloc.alloc_per 
		LET pa_labouralloc[idx].pay_amt = pr_labouralloc.pay_amt 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_labouralloc[idx].* TO NULL 
	END IF 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("W",1130,"") 
	#1130 F6 - View Labourer Allocations
	OPTIONS INSERT KEY f38, 
	DELETE KEY f36 
	INPUT ARRAY pa_labouralloc WITHOUT DEFAULTS FROM sr_labouralloc.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-labouralloc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (F6) 
			CALL show_labouritem(p_cmpy,modu_rec_ordhead.order_num) 
			OPTIONS INSERT KEY f38, 
			DELETE KEY f36 
		BEFORE FIELD scroll_flag 
			LET cnt = arr_count() 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF idx <= cnt THEN 
				DISPLAY pa_labouralloc[idx].* TO sr_labouralloc[scrn].* 

			END IF 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() 
				OR pa_labouralloc[idx+1].labour_code IS NULL THEN 
					LET msgresp = kandoomsg("W",9001,"") 
					#9001 No more Rows in direction
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			DISPLAY pa_labouralloc[idx].* TO sr_labouralloc[scrn].* 

		BEFORE FIELD labour_code 
			NEXT FIELD scroll_flag 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW w343 
END FUNCTION 
###########################################################################
# END FUNCTION show_labouralloc(p_cmpy,pr_order_num)
###########################################################################


###########################################################################
# FUNCTION show_labouritem(p_cmpy,pr_order_num)
#
#
###########################################################################
FUNCTION show_labouritem(p_cmpy,pr_order_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pr_order_num LIKE ordhead.order_num, 
	pr_labourtrans RECORD LIKE labourtrans.*, 
	pr_labourline RECORD LIKE labourline.*, 
	pa_labourline array[100] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE labourline.line_num, 
		part_code LIKE labourline.part_code, 
		ware_code LIKE labourline.ware_code, 
		order_qty LIKE labourline.order_qty, 
		uom_code LIKE labourline.uom_code, 
		pay_to_per LIKE labourline.pay_to_per, 
		comp_to_per LIKE labourline.comp_to_per 
	END RECORD, 
	area_to_cover LIKE ordhead.net_area_qty, 
	pr_comp_to_per LIKE labourtrans.comp_to_per, 
	idx,scrn,cnt SMALLINT 

	SELECT * INTO modu_rec_ordhead.* FROM ordhead 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	IF modu_rec_ordhead.comp_area_qty IS NULL THEN 
		LET modu_rec_ordhead.comp_area_qty = 0 
	END IF 
	IF modu_rec_ordhead.net_area_qty IS NULL THEN 
		LET modu_rec_ordhead.net_area_qty = 0 
	END IF 
	SELECT * INTO pr_labourtrans.* FROM labourtrans 
	WHERE order_num = pr_order_num 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET pr_comp_to_per = 0 
		LET pr_labourtrans.comp_to_per = 0 
		LET pr_labourtrans.pay_amt = 0 
		LET area_to_cover = 0 
	ELSE 
		LET pr_comp_to_per = pr_labourtrans.comp_to_per 
		LET area_to_cover =((pr_labourtrans.comp_to_per 
		* modu_rec_ordhead.net_area_qty) / 100) 
		- modu_rec_ordhead.comp_area_qty 
	END IF 
	OPEN WINDOW w341 with FORM "W341" 
	CALL windecoration_w("W341") -- albo kd-767 
	LET msgresp = kandoomsg("W",1008,"")	#1008 F3/F4 Page Fwd/Bwd - ESC TO continue
	DISPLAY BY NAME pr_comp_to_per, 
	area_to_cover, 
	modu_rec_ordhead.net_area_qty, 
	modu_rec_ordhead.comp_area_qty 

	DECLARE c1_labourline CURSOR FOR 
	SELECT *,rowid FROM labourline 
	WHERE order_num = pr_order_num 
	AND status_ind != "4" 
	AND cmpy_code = p_cmpy 
	LET idx = 0 
	FOREACH c1_labourline INTO pr_labourline.* 
		LET idx = idx + 1 
		LET pa_labourline[idx].line_num = pr_labourline.line_num 
		LET pa_labourline[idx].part_code = pr_labourline.part_code 
		LET pa_labourline[idx].ware_code = pr_labourline.ware_code 
		LET pa_labourline[idx].order_qty = pr_labourline.order_qty 
		LET pa_labourline[idx].uom_code = pr_labourline.uom_code 
		LET pa_labourline[idx].pay_to_per = pr_labourline.pay_to_per 
		LET pa_labourline[idx].comp_to_per = pr_labourline.comp_to_per 
	END FOREACH 

	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE pa_labourline[idx].* TO NULL 
	END IF 

	CALL set_count(idx) 
	OPTIONS INSERT KEY f38, 
	DELETE KEY f36 
	INPUT ARRAY pa_labourline WITHOUT DEFAULTS FROM sr_labourline.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","wordwin","input-arr-labourline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD scroll_flag 
			LET cnt = arr_count() 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF idx <= cnt THEN 
				DISPLAY pa_labourline[idx].* TO sr_labourline[scrn].* 

			END IF 
		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() 
				OR pa_labourline[idx+1].part_code IS NULL THEN 
					LET msgresp = kandoomsg("W",9001,"") 
					#9001 No more Rows in direction
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			DISPLAY pa_labourline[idx].* TO sr_labourline[scrn].* 

		BEFORE FIELD comp_to_per 
			NEXT FIELD scroll_flag 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	CLOSE WINDOW w341 
END FUNCTION 
###########################################################################
# END FUNCTION show_labouritem(p_cmpy,pr_order_num)
###########################################################################