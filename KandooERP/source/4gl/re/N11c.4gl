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

# Functions in this module are:
# * lineitem_entry - used TO enter a requisition line in detail mode.(F8)
# * display_stock  - DISPLAY stocking details of a requisitioned product
# * display_line   - DISPLAY the current requisition line details
# * validate_field - provides universal validation of all INPUT fields
# * quantity_check - verifies the quantities requested a requisition product
########################################################################
# \brief module N11c - Internal Requisition Single (Detail) Entry
DEFINE pr_available LIKE prodstatus.onhand_qty #necessary FOR validate_field# 

FUNCTION lineitem_entry(pr_reqdetl) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	ps_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_temp_amt FLOAT, 
	pr_valid_ind SMALLINT, 
	pr_temp_text CHAR(200), 
	i,j SMALLINT, 
	pr_status_ind INTEGER 

	## take copy of RECORD TO reinstate in CASE of back out
	LET ps_reqdetl.* = pr_reqdetl.* 
	OPEN WINDOW wn108 with FORM "N108" 
	CALL windecoration_n("N108") -- albo kd-763 
	LET msgresp = kandoomsg("N",1011,"") 
	#N1011 Enter Requisition Line Details; OK TO Continue. F5...
	CALL display_line(pr_reqdetl.*,1) 
	RETURNING pr_reqdetl.* 
	LET pr_available = display_stock(pr_reqdetl.*,1) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT BY NAME pr_reqdetl.part_code, 
	pr_reqdetl.desc_text, 
	pr_reqdetl.req_qty, 
	pr_reqdetl.reserved_qty, 
	pr_reqdetl.back_qty, 
	pr_reqdetl.replenish_ind, 
	pr_reqdetl.vend_code, 
	pr_reqdetl.unit_sales_amt, 
	pr_reqdetl.required_date WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-377 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (part_code) 
			LET pr_temp_text= "status_ind ='1' AND part_code in ", 
			"(SELECT part_code FROM prodstatus ", 
			"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND part_code=product.part_code ", 
			"AND status_ind = '1' ", 
			"AND ware_code='",pr_reqhead.ware_code,"')" 
			LET pr_temp_text = show_part(glob_rec_kandoouser.cmpy_code,pr_temp_text) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_reqdetl.part_code = pr_temp_text 
				NEXT FIELD part_code 
			END IF 

		ON KEY (control-b) infield (vend_code) 
			IF pr_reqdetl.replenish_ind = "S" THEN 
				LET pr_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_reqdetl.vend_code = pr_temp_text 
					NEXT FIELD vend_code 
				END IF 
			ELSE 
				LET pr_temp_text = show_vend(glob_rec_kandoouser.cmpy_code,pr_reqdetl.vend_code) 
				IF pr_temp_text IS NOT NULL THEN 
					LET pr_reqdetl.vend_code = pr_temp_text 
					NEXT FIELD vend_code 
				END IF 
			END IF 

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
			OPTIONS DELETE KEY f2 
			LET pr_reqdetl.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,pr_reqdetl.desc_text) 
			OPTIONS DELETE KEY f36 

		ON KEY (F5) 
			IF pr_reqdetl.part_code IS NOT NULL THEN 
				CALL pinvwind(glob_rec_kandoouser.cmpy_code,pr_reqdetl.part_code) 
			END IF 

		ON KEY (F7) 
			IF pr_reqdetl.replenish_ind = "P" THEN 
				IF pr_reqdetl.vend_code IS NOT NULL THEN 
					SELECT unique 1 FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_reqdetl.vend_code 
					IF status = 0 THEN 
						CALL vinq_vend(glob_rec_kandoouser.cmpy_code,pr_reqdetl.vend_code) 
					ELSE 
						LET msgresp = kandoomsg("P",9043,"") 
						#P9043 Vendor NOT found; Try Window
					END IF 
				END IF 
			END IF 

		AFTER FIELD part_code 
			CALL validate_field("part_code",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind,pr_reqdetl.* 
			IF NOT pr_valid_ind THEN 
				LET pr_reqdetl.part_code = ps_reqdetl.part_code 
				NEXT FIELD part_code 
			ELSE 
				LET pr_reqdetl.req_qty = pr_save.req_qty 
			END IF 
			CALL display_line(pr_reqdetl.*,1) 
			RETURNING pr_reqdetl.* 

		AFTER FIELD req_qty 
			CALL validate_field("req_qty",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF pr_valid_ind THEN 
				LET pr_save.reserved_qty = pr_reqdetl.reserved_qty 
				LET pr_save.back_qty = pr_reqdetl.back_qty 
				CALL display_line(pr_reqdetl.*,0) 
				RETURNING pr_reqdetl.* 
			ELSE 
				LET pr_reqdetl.req_qty = ps_reqdetl.req_qty 
				LET pr_save.reserved_qty = ps_reqdetl.reserved_qty 
				NEXT FIELD req_qty 
			END IF 
			DISPLAY BY NAME pr_reqdetl.reserved_qty, 
			pr_reqdetl.back_qty 

		BEFORE FIELD reserved_qty 
			IF pr_reqhead.stock_ind = 0 THEN 
				IF fgl_lastkey() = fgl_keyval("left") OR 
				fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD reserved_qty 
			CALL validate_field("reserved_qty", pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF pr_valid_ind THEN 
				DISPLAY BY NAME pr_reqdetl.req_qty, 
				pr_reqdetl.back_qty, 
				pr_reqdetl.reserved_qty 

			ELSE 
				LET pr_reqdetl.reserved_qty = pr_save.reserved_qty 
				NEXT FIELD reserved_qty 
			END IF 

		BEFORE FIELD back_qty 
			IF pr_reqhead.stock_ind = 0 THEN 
				IF fgl_lastkey() = fgl_keyval("left") OR 
				fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				LET pr_save.back_qty = pr_reqdetl.back_qty 
			END IF 

		AFTER FIELD back_qty 
			CALL validate_field("back_qty", pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF NOT pr_valid_ind THEN 
				LET pr_reqdetl.back_qty = pr_save.back_qty 
			END IF 

		BEFORE FIELD vend_code 
			LET pr_save.vend_code = pr_reqdetl.vend_code 

		AFTER FIELD vend_code 
			CALL validate_field("vend_code",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF pr_valid_ind THEN 
				CALL display_line(pr_reqdetl.*,1) 
				RETURNING pr_reqdetl.* 
				DISPLAY BY NAME pr_reqdetl.vend_code, 
				pr_reqdetl.unit_sales_amt 

			ELSE 
				NEXT FIELD vend_code 
			END IF 
		BEFORE FIELD replenish_ind 
			IF pr_reqdetl.replenish_ind IS NULL THEN 
				LET pr_reqdetl.replenish_ind = "P" 
				LET pr_temp_text = kandooword("prodstatus.replenish_ind", 
				pr_reqdetl.replenish_ind) 
				DISPLAY pr_temp_text TO replenish_text 

			END IF 
			LET pr_save.replenish_ind = pr_reqdetl.replenish_ind 

		AFTER FIELD replenish_ind 
			CALL validate_field("replenish_ind",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			CALL display_line(pr_reqdetl.*,1) 
			RETURNING pr_reqdetl.* 

		AFTER FIELD unit_sales_amt 
			CALL validate_field("unit_sales_amt",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind,pr_reqdetl.* 
			IF NOT pr_valid_ind THEN 
				NEXT FIELD unit_sales_amt 
			ELSE 
				CALL display_line(pr_reqdetl.*,0) 
				RETURNING pr_reqdetl.* 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			CALL validate_field("req_qty",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF NOT pr_valid_ind THEN 
				LET pr_reqdetl.req_qty = ps_reqdetl.req_qty 
				LET pr_save.reserved_qty = ps_reqdetl.reserved_qty 
				NEXT FIELD req_qty 
			END IF 
			LET pr_save.vend_code = pr_reqdetl.vend_code 
			CALL validate_field("vend_code",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind, pr_reqdetl.* 
			IF pr_valid_ind THEN 
				DISPLAY BY NAME pr_reqdetl.unit_sales_amt 

			ELSE 
				LET pr_reqdetl.vend_code = pr_save.vend_code 
				NEXT FIELD vend_code 
			END IF 
			CALL validate_field("unit_sales_amt",pr_reqdetl.*,1) 
			RETURNING pr_valid_ind,pr_reqdetl.* 
			IF NOT pr_valid_ind THEN 
				NEXT FIELD unit_sales_amt 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 


	END INPUT 
	#-----------------------------------------------------------------------------------------------------------------------

	CLOSE WINDOW wn108 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CALL update_line(ps_reqdetl.*) 
		CALL update_line(ps_reqdetl.*) 
		RETURN false 
	ELSE 
		LET pr_reqdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_reqdetl.level_ind = "C" 
		LET pr_reqdetl.uom_code = pr_product.sell_uom_code 
		IF pr_reqdetl.unit_cost_amt IS NULL THEN 
			LET pr_reqdetl.unit_cost_amt = 0 
		END IF 
		CALL update_line(pr_reqdetl.*) 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION display_stock(pr_reqdetl, pr_display_val) 
	DEFINE 
	pr_display_val SMALLINT, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_old_back LIKE reqdetl.back_qty, 
	pr_old_reserve LIKE reqdetl.back_qty, 
	pr_fut_avail, 
	pr_available LIKE prodstatus.onhand_qty 

	IF pr_reqdetl.part_code IS NOT NULL THEN 
		SELECT back_qty, reserved_qty INTO pr_old_back, pr_old_reserve 
		FROM t_reqdetl 
		WHERE line_num = pr_reqdetl.line_num 
		IF pr_old_back IS NULL THEN 
			LET pr_old_back = 0 
		END IF 
		IF pr_old_reserve IS NULL THEN 
			LET pr_old_reserve = 0 
		END IF 
		SELECT ps.*, p.* 
		INTO pr_prodstatus.*, 
		pr_product.* 
		FROM prodstatus ps, 
		product p 
		WHERE ps.part_code = pr_reqdetl.part_code 
		AND ps.ware_code = pr_reqhead.ware_code 
		AND ps.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND p.cmpy_code = ps.cmpy_code 
		AND p.part_code = ps.part_code 
		IF pr_prodstatus.onhand_qty IS NULL THEN 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 
		IF pr_prodstatus.onord_qty IS NULL THEN 
			LET pr_prodstatus.onord_qty = 0 
		END IF 
		IF pr_prodstatus.reserved_qty IS NULL THEN 
			LET pr_prodstatus.reserved_qty = 0 
		END IF 
		IF pr_prodstatus.back_qty IS NULL THEN 
			LET pr_prodstatus.back_qty = 0 
		END IF 
		LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty 
		- pr_old_reserve 
		+ pr_reqdetl.reserved_qty 
		LET pr_prodstatus.back_qty = pr_prodstatus.back_qty 
		- pr_old_back 
		+ pr_reqdetl.back_qty 
		LET pr_available = pr_prodstatus.onhand_qty 
		- pr_prodstatus.reserved_qty 
		- pr_prodstatus.back_qty 
		LET pr_fut_avail = pr_available 
		+ pr_prodstatus.onord_qty 
	ELSE 
		INITIALIZE pr_prodstatus.* TO NULL 
		LET pr_fut_avail = NULL 
		LET pr_available = NULL 
	END IF 
	CASE pr_display_val 
		WHEN 1 
			DISPLAY BY NAME pr_prodstatus.onhand_qty, 
			pr_prodstatus.onord_qty, 
			pr_prodstatus.reorder_point_qty, 
			pr_prodstatus.reorder_qty, 
			pr_prodstatus.max_qty, 
			pr_prodstatus.critical_qty, 
			pr_product.min_ord_qty, 
			pr_fut_avail, 
			pr_available, 
			pr_prodstatus.abc_ind 

			DISPLAY pr_prodstatus.back_qty, pr_prodstatus.reserved_qty 
			TO prodstatus.back_qty, prodstatus.reserved_qty 

		WHEN 2 
			DISPLAY BY NAME pr_prodstatus.onhand_qty, 
			pr_fut_avail, 
			pr_prodstatus.max_qty 

			DISPLAY pr_available TO prodstatus.onhand_qty 

	END CASE 
	IF pr_available < 0 THEN 
		LET pr_available = 0 
	END IF 
	RETURN pr_available 
END FUNCTION 


FUNCTION display_line(pr_reqdetl,pr_display_val) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_category RECORD LIKE category.*, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_new_line, 
	pr_display_val SMALLINT, 
	pr_replenish_text CHAR(20), 
	pr_line_total LIKE reqhead.total_sales_amt, 
	pr_conv_rate FLOAT 

	IF pr_display_val THEN 
		IF pr_reqdetl.part_code IS NOT NULL THEN 
			SELECT * INTO pr_product.* FROM product 
			WHERE part_code = pr_reqdetl.part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF pr_reqdetl.required_date IS NULL THEN 
				LET pr_reqdetl.required_date = today 
				+ pr_product.days_lead_num 
			END IF 
			SELECT category.* INTO pr_category.* FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
			LET pr_new_line = false 
			IF pr_reqdetl.acct_code IS NULL THEN ## entry-edit ?? 
				LET pr_new_line = true 
				IF pr_reqdetl.desc_text IS NULL THEN 
					LET pr_reqdetl.desc_text = pr_product.desc_text 
				END IF 
				LET pr_reqdetl.acct_code = pr_category.sale_acct_code 
				LET pr_reqdetl.uom_code = pr_product.sell_uom_code 
				IF pr_reqdetl.replenish_ind IS NULL THEN 
					LET pr_reqdetl.replenish_ind = "P" 
				END IF 
				IF pr_reqdetl.replenish_ind IS NULL THEN 
					DECLARE c_prodquote SCROLL CURSOR FOR 
					SELECT * FROM prodquote 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_reqdetl.part_code 
					AND status_ind = "1" 
					AND expiry_date >= today 
					ORDER BY cost_amt 
					OPEN c_prodquote 
					FETCH c_prodquote INTO pr_prodquote.* 
					IF status = notfound THEN 
						SELECT for_cost_amt INTO pr_reqdetl.unit_sales_amt 
						FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pr_reqhead.ware_code 
						AND part_code = pr_reqdetl.part_code 
					ELSE 
						LET pr_conv_rate = 
						get_conv_rate(
							glob_rec_kandoouser.cmpy_code,
							pr_prodquote.curr_code,
							today,
							CASH_EXCHANGE_SELL) 
						LET pr_reqdetl.unit_sales_amt = pr_prodquote.cost_amt / pr_conv_rate 
						LET pr_reqdetl.vend_code = pr_prodquote.vend_code 
						LET pr_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
					END IF 
					CLOSE c_prodquote 
				ELSE 
					SELECT * INTO pr_prodstatus.* FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_reqdetl.vend_code 
					AND part_code = pr_reqdetl.part_code 
					LET pr_reqdetl.unit_sales_amt = pr_prodstatus.wgted_cost_amt 
				END IF 
			END IF 
		END IF 
		IF NOT pr_new_line THEN 
			IF pr_reqdetl.replenish_ind IS NULL THEN 
				LET pr_reqdetl.replenish_ind = "P" 
			END IF 
			LET pr_replenish_text = kandooword("prodstatus.replenish_ind", 
			pr_reqdetl.replenish_ind) 
			IF pr_reqdetl.replenish_ind = "S" THEN 
				IF pr_reqdetl.req_qty = 0 
				AND pr_reqdetl.vend_code IS NULL THEN 
					SELECT * INTO pr_puparms.* FROM puparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_reqdetl.vend_code = pr_puparms.usual_ware_code 
					SELECT desc_text INTO pr_vendor.name_text FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_reqdetl.vend_code 
				ELSE 
					IF pr_reqdetl.vend_code IS NOT NULL THEN 
						SELECT desc_text INTO pr_vendor.name_text FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pr_reqdetl.vend_code 
					ELSE 
						LET pr_vendor.name_text = NULL 
					END IF 
				END IF 
			ELSE 
				IF pr_reqdetl.vend_code IS NOT NULL THEN 
					SELECT * INTO pr_vendor.* FROM vendor 
					WHERE vend_code = pr_reqdetl.vend_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				ELSE 
					LET pr_vendor.name_text = NULL 
				END IF 
			END IF 
		ELSE 
			CASE pr_reqdetl.replenish_ind 
				WHEN "S" LET pr_replenish_text = kandooword("prodstatus.replenish_ind", 
					pr_reqdetl.replenish_ind) 
					SELECT * INTO pr_puparms.* FROM puparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_reqdetl.vend_code = pr_puparms.usual_ware_code 
					SELECT desc_text INTO pr_vendor.name_text FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_reqdetl.vend_code 
				OTHERWISE LET pr_reqdetl.replenish_ind = "P" 
					LET pr_replenish_text =kandooword("prodstatus.replenish_ind", 
					pr_reqdetl.replenish_ind) 
					IF pr_reqdetl.vend_code IS NOT NULL THEN 
						SELECT * INTO pr_vendor.* FROM vendor 
						WHERE vend_code = pr_reqdetl.vend_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					ELSE 
						LET pr_vendor.name_text = NULL 
					END IF 
			END CASE 
		END IF 
		DISPLAY pr_replenish_text TO replenish_text 

		DISPLAY BY NAME pr_reqhead.ware_code, 
		pr_reqdetl.part_code, 
		pr_reqdetl.desc_text, 
		pr_reqdetl.req_qty, 
		pr_reqdetl.reserved_qty, 
		pr_reqdetl.back_qty, 
		pr_reqdetl.picked_qty, 
		pr_reqdetl.confirmed_qty, 
		pr_reqdetl.replenish_ind, 
		pr_reqdetl.vend_code, 
		pr_vendor.name_text, 
		pr_reqdetl.required_date, 
		pr_reqdetl.unit_sales_amt, 
		pr_reqdetl.uom_code 

	END IF 
	IF pr_reqdetl.unit_sales_amt IS NULL THEN 
		LET pr_reqdetl.unit_sales_amt = 0 
	END IF 
	IF pr_reqdetl.req_qty IS NULL THEN 
		LET pr_reqdetl.req_qty = 0 
	END IF 
	LET pr_line_total = pr_reqdetl.unit_sales_amt * pr_reqdetl.req_qty 
	DISPLAY pr_line_total TO line_total 

	RETURN pr_reqdetl.* 
END FUNCTION 


FUNCTION validate_field(pr_field_name,px_reqdetl,pr_display_val) 
	DEFINE 
	pr_field_name CHAR(15), 
	ps_reqdetl, 
	px_reqdetl RECORD LIKE reqdetl.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_puparms RECORD LIKE puparms.*, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_unit_sales_amt LIKE reqdetl.unit_sales_amt, 
	pr_part_code LIKE orderline.part_code, 
	pr_temp_text CHAR(20), 
	pr_temp_val, 
	pr_status INTEGER, 
	pr_conv_rate FLOAT, 
	pr_display_val, 
	i,idx SMALLINT 

	SELECT * INTO ps_reqdetl.* FROM t_reqdetl 
	WHERE line_num = px_reqdetl.line_num 
	CASE 
		WHEN pr_field_name = "part_code" 
			IF px_reqdetl.part_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9013,"") 
				#I9013 Product Code must be entered...
				RETURN false,px_reqdetl.* 
			END IF 
			LET pr_save.req_qty = px_reqdetl.req_qty 
			IF ps_reqdetl.part_code IS NULL 
			OR ps_reqdetl.part_code != px_reqdetl.part_code THEN 
				IF px_reqdetl.part_code IS NOT NULL THEN 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = px_reqdetl.part_code 
					IF pr_product.super_part_code IS NOT NULL THEN 
						LET idx = 0 
						WHILE pr_product.super_part_code IS NOT NULL 
							LET idx = idx + 1 
							IF NOT valid_part(glob_rec_kandoouser.cmpy_code,pr_product.super_part_code, 
							pr_reqhead.ware_code, 
							1,1,0,"","","") THEN 
								LET px_reqdetl.part_code = NULL 
								IF px_reqdetl.desc_text NOT matches "###*" THEN 
									LET px_reqdetl.desc_text = NULL 
								END IF 
								RETURN false,px_reqdetl.* 
							END IF 
							SELECT * INTO pr_product.* FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_product.super_part_code 
							IF idx > 20 THEN 
								LET msgresp = kandoomsg("E",9183,"") 
								#9183 Product code supercession limit exceeded
								LET px_reqdetl.part_code = NULL 
								IF px_reqdetl.desc_text NOT matches "###*" THEN 
									LET px_reqdetl.desc_text = NULL 
								END IF 
								RETURN false,px_reqdetl.* 
							END IF 
						END WHILE 
						LET msgresp = kandoomsg("E",7060,pr_product.part_code) 
						#7060 Product replaced by superceded product .....
						LET px_reqdetl.part_code = pr_product.part_code 
						IF px_reqdetl.desc_text NOT matches "###*" THEN 
							LET px_reqdetl.desc_text = pr_product.desc_text 
						END IF 
						RETURN false,px_reqdetl.* 
					ELSE 
						IF NOT valid_part(glob_rec_kandoouser.cmpy_code,px_reqdetl.part_code, 
						pr_reqhead.ware_code, 
						1,1,0,"","","") THEN 
							RETURN false,px_reqdetl.* 
						END IF 
						IF px_reqdetl.desc_text NOT matches "###*" THEN 
							LET px_reqdetl.desc_text = pr_product.desc_text 
						END IF 
					END IF 
					### Stock availability ###
					SELECT prodstatus.*, (onhand_qty - reserved_qty - back_qty) 
					INTO pr_prodstatus.*, 
					pr_available 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_reqhead.ware_code 
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
									LET px_reqdetl.part_code = pr_part_code 
								END IF 
							ELSE 
								IF pr_status = notfound THEN 
									LET px_reqdetl.part_code = ps_reqdetl.part_code 
									RETURN false, px_reqdetl.* 
								END IF 
							END IF 
						ELSE 
							IF pr_status = notfound THEN 
								LET msgresp=kandoomsg("I",9104,"") 
								#I9104 Product NOT Stocked AT this Warehouse
								LET px_reqdetl.part_code = ps_reqdetl.part_code 
								RETURN false, px_reqdetl.* 
							END IF 
						END IF 
					END IF 
					### Can we pre-allocate the reorder_qty here? ###
					IF pr_prodstatus.reorder_qty IS NOT NULL THEN 
						LET pr_save.req_qty = pr_prodstatus.reorder_qty 
					ELSE 
						LET pr_save.req_qty = 0 
					END IF 
					LET px_reqdetl.replenish_ind = pr_prodstatus.replenish_ind 
					IF px_reqdetl.replenish_ind IS NULL 
					OR px_reqdetl.replenish_ind = "P" THEN 
						LET px_reqdetl.replenish_ind = "P" 
						LET px_reqdetl.vend_code = pr_product.vend_code 
						SELECT * INTO pr_vendor.* FROM vendor 
						WHERE vend_code = px_reqdetl.vend_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					ELSE 
						IF px_reqdetl.vend_code IS NULL THEN 
							IF px_reqdetl.req_qty = 0 THEN 
								SELECT * INTO pr_puparms.* FROM puparms 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								LET px_reqdetl.vend_code = pr_puparms.usual_ware_code 
							END IF 
						END IF 
					END IF 
					LET pr_available = display_stock(px_reqdetl.*,pr_display_val) 
				END IF 
			END IF 
		WHEN pr_field_name = "req_qty" 
			IF px_reqdetl.req_qty IS NULL THEN 
				LET msgresp=kandoomsg("N",9030,"") 
				#N9030 Requested Quantity must be entered
				RETURN false, px_reqdetl.* 
			END IF 
			IF px_reqdetl.req_qty < 0 THEN 
				LET msgresp=kandoomsg("E",9180,"") 
				#E9180 Quantity may NOT be negative
				RETURN false, px_reqdetl.* 
			END IF 
			IF pr_reqhead.stock_ind != 0 THEN 
				IF px_reqdetl.req_qty < (px_reqdetl.picked_qty + 
				px_reqdetl.confirmed_qty) THEN 
					LET pr_temp_val = px_reqdetl.picked_qty 
					+ px_reqdetl.confirmed_qty 
					LET msgresp=kandoomsg("N",9031,pr_temp_val) 
					#N9031 Cannot Alter Requested Quantity TO less than VALUE .
					RETURN false, px_reqdetl.* 
				END IF 
			END IF 
			IF px_reqdetl.req_qty != ps_reqdetl.req_qty THEN 
				CASE pr_reqhead.stock_ind 
					WHEN 0 
						LET px_reqdetl.reserved_qty = 0 
						LET px_reqdetl.back_qty = 0 
					WHEN 1 
						IF (px_reqdetl.req_qty - px_reqdetl.picked_qty 
						- px_reqdetl.confirmed_qty) 
						> (pr_available - ps_reqdetl.req_qty 
						+ px_reqdetl.confirmed_qty) THEN 
							LET px_reqdetl.reserved_qty = pr_available 
							LET px_reqdetl.back_qty = px_reqdetl.req_qty 
							- pr_available 
							- px_reqdetl.picked_qty 
							- px_reqdetl.confirmed_qty 
						ELSE 
							LET px_reqdetl.reserved_qty = px_reqdetl.req_qty 
							- px_reqdetl.picked_qty 
							- px_reqdetl.confirmed_qty 
							LET px_reqdetl.back_qty = 0 
						END IF 
					WHEN 2 
						LET px_reqdetl.reserved_qty = 0 
						LET px_reqdetl.back_qty = px_reqdetl.req_qty 
						- px_reqdetl.picked_qty 
						- px_reqdetl.confirmed_qty 
				END CASE 
				IF pr_display_val = 2 THEN 
					LET pr_available = display_stock(px_reqdetl.*,pr_display_val) 
				END IF 
			END IF 
			CALL quantity_check(px_reqdetl.*,1) 
		WHEN pr_field_name = "reserved_qty" 
			CASE 
				WHEN px_reqdetl.reserved_qty IS NULL 
					LET msgresp=kandoomsg("N",9032,"") 
					#N9032 Reserved Quantity must be entered
					LET px_reqdetl.back_qty = pr_save.reserved_qty 
					RETURN false, px_reqdetl.* 
				WHEN px_reqdetl.reserved_qty < 0 
					LET msgresp=kandoomsg("N",9033,"") 
					#N9033 Reserved Quantity Cannot be less than Zero
					LET px_reqdetl.back_qty = pr_save.reserved_qty 
					RETURN false, px_reqdetl.* 
				WHEN px_reqdetl.reserved_qty > px_reqdetl.req_qty 
					LET msgresp=kandoomsg("N",9034,"") 
					#N9034 Reserved Quantity Exceeds Requisition Quantity
					LET px_reqdetl.reserved_qty = pr_save.reserved_qty 
					RETURN false, px_reqdetl.* 
				WHEN px_reqdetl.reserved_qty > pr_save.reserved_qty 
					AND px_reqdetl.reserved_qty > pr_available 
					LET msgresp=kandoomsg("N",9035,"") 
					#N9035 Reserved Quantity Exceeds Availability
					LET px_reqdetl.reserved_qty = pr_save.reserved_qty 
					RETURN false, px_reqdetl.* 
				OTHERWISE 
					LET px_reqdetl.back_qty = px_reqdetl.req_qty 
					- px_reqdetl.reserved_qty 
					- px_reqdetl.picked_qty 
					- px_reqdetl.confirmed_qty 
			END CASE 
		WHEN pr_field_name = "back_qty" 
			CASE 
				WHEN px_reqdetl.back_qty IS NULL 
					RETURN false, px_reqdetl.* 
				WHEN px_reqdetl.back_qty < 0 
					LET msgresp=kandoomsg("N",9036,"") 
					#N9036 Back Order Quantity cannot be less than Zero.
					RETURN false, px_reqdetl.* 
				WHEN px_reqdetl.back_qty > px_reqdetl.req_qty 
					LET msgresp=kandoomsg("N",9037,"") 
					#N9035 Back Order Quantity exceeds Requistion Quantity.
					RETURN false, px_reqdetl.* 
				OTHERWISE 
					IF px_reqdetl.back_qty > (px_reqdetl.req_qty 
					- px_reqdetl.picked_qty 
					- px_reqdetl.confirmed_qty 
					- px_reqdetl.reserved_qty) 
					THEN 
						LET msgresp=kandoomsg("N",7012,"") 
						#N7012 Warning: Back Order & Reserved Quantity
						#               Exceeds Requested Quantity
					END IF 
			END CASE 
		WHEN pr_field_name = "replenish_ind" 
			IF pr_save.replenish_ind = "P" 
			AND px_reqdetl.replenish_ind IS NULL THEN 
				#ie just spaced out the 'P' should have no effect
				LET px_reqdetl.replenish_ind = "P" 
			ELSE 
				IF px_reqdetl.replenish_ind != pr_save.replenish_ind 
				OR px_reqdetl.replenish_ind IS NULL THEN 
					CASE px_reqdetl.replenish_ind 
						WHEN "S" 
							LET px_reqdetl.acct_code = NULL 
							SELECT usual_ware_code INTO px_reqdetl.vend_code FROM puparms 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						OTHERWISE 
							LET px_reqdetl.replenish_ind = "P" 
							LET px_reqdetl.acct_code = NULL 
							SELECT * INTO pr_product.* FROM product 
							WHERE part_code = px_reqdetl.part_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET px_reqdetl.vend_code = pr_product.vend_code 
					END CASE 
				END IF 
			END IF 
			LET pr_temp_text = kandooword("prodstatus.replenish_ind", 
			px_reqdetl.replenish_ind) 

			IF px_reqdetl.replenish_ind = "P" THEN 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE vend_code = px_reqdetl.vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			ELSE 
				SELECT desc_text INTO pr_vendor.name_text FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = px_reqdetl.vend_code 
			END IF 
			DISPLAY BY NAME px_reqdetl.replenish_ind, 
			px_reqdetl.vend_code, 
			pr_vendor.name_text 

			DISPLAY pr_temp_text TO replenish_text 

		WHEN pr_field_name = "vend_code" 
			IF px_reqdetl.vend_code IS NOT NULL THEN 
				IF px_reqdetl.replenish_ind != "S" THEN 
					SELECT name_text INTO pr_vendor.name_text FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = px_reqdetl.vend_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("P",9043,"") 
						#P9043 Vendor NOT found; Try Window
						RETURN false, px_reqdetl.* 
					END IF 
				ELSE 
					SELECT desc_text INTO pr_vendor.name_text FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = px_reqdetl.vend_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("I",9030,"") 
						#I9030 Warehouse NOT found; Try Window
						RETURN false, px_reqdetl.* 
					END IF 
					IF px_reqdetl.vend_code = pr_reqhead.ware_code THEN 
						LET msgresp=kandoomsg("I",9111,"") 
						#I9111 Supply AND Destination warehouse cannot be the same
						RETURN false, px_reqdetl.* 
					END IF 
					SELECT unique 1 FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = px_reqdetl.part_code 
					AND ware_code = px_reqdetl.vend_code 
					IF status <> 0 THEN 
						LET msgresp=kandoomsg("I",9185,"") 
						#I9185 Must be stocked AT this warehouse...
						RETURN false, px_reqdetl.* 
					END IF 
				END IF 
			ELSE 
				LET pr_vendor.name_text = NULL 
			END IF 
			DISPLAY BY NAME pr_vendor.name_text 

			IF px_reqdetl.vend_code IS NULL 
			AND pr_save.vend_code IS NULL THEN 
			ELSE 
				IF px_reqdetl.vend_code != pr_save.vend_code 
				OR pr_save.vend_code IS NULL THEN 
					LET pr_save.vend_code = px_reqdetl.vend_code 
					IF px_reqdetl.replenish_ind = "S" THEN 
						SELECT wgted_cost_amt INTO px_reqdetl.unit_sales_amt 
						FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = px_reqdetl.part_code 
						AND ware_code = px_reqdetl.vend_code 
						LET px_reqdetl.required_date = today 
					ELSE 
						### ZZZZ ###
						DECLARE c_prodquote2 SCROLL CURSOR FOR 
						SELECT * INTO pr_prodquote.* FROM prodquote 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = px_reqdetl.part_code 
						AND status_ind = "1" 
						AND vend_code = px_reqdetl.vend_code 
						AND expiry_date >= today 
						ORDER BY cost_amt 
						OPEN c_prodquote2 
						FETCH c_prodquote2 INTO pr_prodquote.* 
						IF status = notfound THEN 
							SELECT for_cost_amt INTO px_reqdetl.unit_sales_amt 
							FROM prodstatus 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = pr_reqhead.ware_code 
							AND part_code = px_reqdetl.part_code 
							LET px_reqdetl.required_date = today 
						ELSE 
							LET pr_conv_rate = get_conv_rate(
								glob_rec_kandoouser.cmpy_code,
								pr_prodquote.curr_code,
								today,
								CASH_EXCHANGE_SELL) 
							
							LET px_reqdetl.unit_sales_amt = pr_prodquote.cost_amt	/ pr_conv_rate 
							LET px_reqdetl.required_date = today + pr_prodquote.lead_time_qty 
						END IF 
						
						CLOSE c_prodquote2 
					END IF 
				END IF 
			END IF 
		WHEN pr_field_name = "unit_sales_amt" 
			IF px_reqdetl.unit_sales_amt IS NULL THEN 
				LET msgresp=kandoomsg("N",9038,"")	#N9038 Unit Sales Amount must be entered
				RETURN false,px_reqdetl.* 
			ELSE 
				IF px_reqdetl.unit_sales_amt < 0 THEN 
					LET msgresp=kandoomsg("N",9039,"")		#N9039 Unit Price of Product must NOT be less than Zero
					RETURN false,px_reqdetl.* 
				END IF 
			END IF 
	END CASE 
	CALL update_line(px_reqdetl.*) 
	SELECT * INTO px_reqdetl.* FROM t_reqdetl 
	WHERE line_num = px_reqdetl.line_num 
	RETURN true, px_reqdetl.* 
END FUNCTION 


FUNCTION quantity_check(pr_reqdetl, pr_display_val) 
	DEFINE 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.*, 
	pr_display_val SMALLINT 

	### Checking FOR outer_qty AND min_ord_qty differences ###
	LET pr_save.warn_flag = NULL 
	SELECT p.min_ord_qty, 
	p.outer_qty, 
	ps.replenish_ind 
	INTO pr_product.min_ord_qty, 
	pr_product.outer_qty, 
	pr_prodstatus.replenish_ind 
	FROM prodstatus ps, 
	product p 
	WHERE ps.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND p.part_code = ps.part_code 
	AND ps.ware_code = pr_reqhead.ware_code 
	AND ps.part_code = pr_reqdetl.part_code 
	IF status = 0 THEN 
		IF (pr_prodstatus.replenish_ind != "S") OR 
		(pr_prodstatus.replenish_ind IS null) 
		THEN 
			IF pr_product.min_ord_qty IS NOT NULL AND 
			pr_product.min_ord_qty != 0 THEN 
				IF pr_reqdetl.req_qty < pr_product.min_ord_qty THEN 
					LET pr_save.warn_flag = "M" 
					IF pr_display_val THEN 
						LET msgresp=kandoomsg("N",7014,pr_product.min_ord_qty) 
						#N7014 Requested quantity IS less than...
					END IF 
					RETURN 
				END IF 
			END IF 
			IF pr_product.outer_qty IS NOT NULL AND 
			pr_product.outer_qty != 0 THEN 
				IF (pr_reqdetl.req_qty mod pr_product.outer_qty) > 0 THEN 
					LET pr_save.warn_flag = "O" 
					IF pr_display_val THEN 
						LET msgresp=kandoomsg("N",9061,pr_product.outer_qty) 
						#N7013  Requisition quantity IS NOT a multiple...
					END IF 
				END IF 
			END IF 
		END IF 
	END IF 
END FUNCTION 
