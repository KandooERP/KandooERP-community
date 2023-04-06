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

	Source code beautified by beautify.pl on 2020-01-02 10:35:28	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION prgdwind(p_cmpy,p_prod_part_code)
#
# prgdwind IS used TO DISPLAY general product details
############################################################
FUNCTION prgdwind(p_cmpy,p_prod_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_prod_part_code LIKE product.part_code 

	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_rec_t_product 
	RECORD 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text 
	END RECORD 
	DEFINE l_alter_text LIKE product.part_code 
	DEFINE l_super_text LIKE product.part_code 
	DEFINE l_compn_text LIKE product.part_code 
	DEFINE l_ans CHAR(1) 
	DEFINE l_anser CHAR(1) 
	DEFINE l_err_flag SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_chosen SMALLINT 
	DEFINE l_exist SMALLINT 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_prod_part_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Product") 
		#7001 Logic Error: Product RECORD NOT found.
		RETURN 
	END IF 
	SELECT category.desc_text INTO l_rec_category.desc_text FROM category 
	WHERE category.cat_code = l_rec_product.cat_code 
	AND category.cmpy_code = p_cmpy 
	IF (status = notfound) THEN 
		LET l_msgresp = kandoomsg("U",7001,"Product Category") 
		#7001 Logic Error: Product Category RECORD NOT found.
		RETURN 
	END IF 
	SELECT class.desc_text INTO l_rec_class.desc_text FROM class 
	WHERE class.class_code = l_rec_product.class_code 
	AND class.cmpy_code = p_cmpy 
	IF (status = notfound) THEN 
		LET l_msgresp = kandoomsg("U",7001,"Inventory Class") 
		#7001 Logic Error: Inventory Class RECORD NOT found.
		RETURN 
	END IF 

	OPEN WINDOW wi101 with FORM "I101" 
	CALL windecoration_i("I101") 

	LET l_alter_text = " " 
	SELECT desc_text INTO l_alter_text FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_product.alter_part_code 
	LET l_super_text = " " 
	SELECT desc_text INTO l_super_text FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_product.super_part_code 
	LET l_compn_text = " " 
	SELECT desc_text INTO l_compn_text FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_product.compn_part_code 
	DISPLAY l_rec_product.part_code, 
	l_rec_product.desc_text, 
	l_rec_product.desc2_text, 
	l_rec_product.cat_code, 
	l_rec_category.desc_text, 
	l_rec_product.class_code, 
	l_rec_class.desc_text, 
	l_rec_product.alter_part_code, 
	l_rec_product.super_part_code, 
	l_rec_product.compn_part_code, 
	l_rec_product.pur_uom_code, 
	l_rec_product.sell_uom_code, 
	l_rec_product.stock_uom_code, 
	l_rec_product.pur_stk_con_qty, 
	l_rec_product.stk_sel_con_qty, 
	l_rec_product.weight_qty, 
	l_rec_product.cubic_qty, 
	l_rec_product.area_qty, 
	l_rec_product.length_qty, 
	l_rec_product.pack_qty, 
	l_rec_product.target_turn_qty, 
	l_rec_product.stock_turn_qty, 
	l_rec_product.stock_days_num, 
	l_rec_product.last_calc_date, 
	l_rec_product.dg_code 
	TO 
	product.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.cat_code, 
	category.desc_text, 
	product.class_code, 
	class.desc_text, 
	product.alter_part_code, 
	product.super_part_code, 
	product.compn_part_code, 
	product.pur_uom_code, 
	product.sell_uom_code, 
	product.stock_uom_code, 
	product.pur_stk_con_qty, 
	product.stk_sel_con_qty, 
	product.weight_qty, 
	product.cubic_qty, 
	product.area_qty, 
	product.length_qty, 
	product.pack_qty, 
	product.target_turn_qty, 
	product.stock_turn_qty, 
	product.stock_days_num, 
	product.last_calc_date, 
	product.dg_code 

	DISPLAY l_alter_text TO alter_text 
	DISPLAY l_super_text TO super_text 
	DISPLAY l_compn_text TO compn_text 
	CALL ui.interface.refresh() 

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")
	#1 Press any key TO continue
	CLOSE WINDOW wi101 
END FUNCTION 

############################################################
# FUNCTION prgdwind(p_cmpy,p_prod_part_code)
#
# prgdwind IS used TO DISPLAY general product details
############################################################
FUNCTION purch_det(p_cmpy,p_prod_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_prod_part_code LIKE product.part_code 

	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_company RECORD LIKE company.* 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 
	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_prod_part_code 
	AND cmpy_code = p_cmpy 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Product") 
		#7001 Logic Error: Product RECORD NOT found.
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vend_code = l_rec_product.vend_code 
	AND cmpy_code = p_cmpy 
	INITIALIZE l_rec_warehouse.* TO NULL 
	IF l_rec_product.ware_code IS NOT NULL THEN 
		SELECT * INTO l_rec_warehouse.* FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = l_rec_product.ware_code 
	END IF 
	IF l_rec_company.module_text[5] = "E" THEN 

		OPEN WINDOW i105 with FORM "I105a" 
		CALL windecoration_i("I105a") 

	ELSE 
		OPEN WINDOW i105 with FORM "I105" 
		CALL windecoration_i("I105") 

		LET l_rec_product.price_inv_flag = NULL 
		LET l_rec_product.disc_allow_flag = NULL 
		LET l_rec_product.bonus_allow_flag = NULL 
		LET l_rec_product.back_order_flag = NULL 
		LET l_rec_product.trade_in_flag = NULL 
	END IF 
	DISPLAY BY NAME l_rec_product.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_product.oem_text, 
	l_rec_product.days_lead_num, 
	l_rec_product.tariff_code, 
	l_rec_product.min_ord_qty, 
	l_rec_product.pur_uom_code, 
	l_rec_product.outer_qty, 
	l_rec_product.outer_sur_per, 
	l_rec_product.bar_code_text, 
	l_rec_product.ware_code, 
	l_rec_product.days_warr_num, 
	l_rec_product.setup_date, 
	l_rec_product.serial_flag, 
	l_rec_product.total_tax_flag, 
	l_rec_product.price_inv_flag, 
	l_rec_product.disc_allow_flag, 
	l_rec_product.bonus_allow_flag, 
	l_rec_product.back_order_flag, 
	l_rec_product.trade_in_flag 
	DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")
	#1 Press any key TO continue
	CLOSE WINDOW i105 
END FUNCTION 


