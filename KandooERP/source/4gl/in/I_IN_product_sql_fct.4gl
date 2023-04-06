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

	Source code beautified by beautify.pl on 2020-01-03 09:12:19	$Id: $
}




# Purpose - Product Addition
#           This program allows the user TO enter new inventory products
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
-- No Globals GLOBALS "I11_GLOBALS.4gl" 

# DEFINE module variables
--DEFINE pr_product RECORD LIKE product.*
DEFINE yes_flag,no_flag CHAR(1)
--DEFINE glob_rec_company RECORD LIKE company.*
--DEFINE glob_rec_inparms RECORD LIKE inparms.*
DEFINE cb_maingrp_code ui.ComboBox
DEFINE cb_prodgrp_code ui.ComboBox
DEFINE cb_part_code ui.ComboBox

FUNCTION I_IN_product_sql_fct_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION


##########################################################################################
# FUNCTION image_product()
#
#
##########################################################################################
FUNCTION image_product(p_part_code) 
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE msgresp LIKE language.yes_flag 

	OPEN WINDOW i106 with FORM "I106" 
	#ATTRIBUTE(border)
	 CALL windecoration_i("I106") 

	LET l_rec_product.part_code = p_part_code 

	INPUT BY NAME l_rec_product.part_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11","input-part_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "REFRESH" 
			 CALL windecoration_i("I106") 


		ON KEY (control-b) 
			LET l_rec_product.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD part_code 

		AFTER FIELD part_code 
			IF l_rec_product.part_code IS NOT NULL THEN 
				SELECT * 
				INTO l_rec_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.part_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010" Product NOT found - Try Window"
					NEXT FIELD part_code 
				END IF 
			ELSE 
				LET quit_flag = true 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	---------------------------------

	CLOSE WINDOW i106 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE l_rec_product.* TO NULL
		RETURN false,l_rec_product.* 
	ELSE 
		LET l_rec_product.part_code = NULL 
		LET l_rec_product.setup_date = today 
		LET l_rec_product.last_calc_date = NULL 
		LET l_rec_product.stock_days_num = 0 
		LET l_rec_product.status_ind = "1" 
		LET l_rec_product.status_date = today 
		LET l_rec_product.bar_code_text = NULL 
		
		RETURN true ,l_rec_product.* 
	END IF 
END FUNCTION 	# image_product



##########################################################################################
# FUNCTION insert_product()
#
#
##########################################################################################
FUNCTION insert_product(p_rec_product) 
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE msgresp LIKE language.yes_flag 

	IF NOT check_prykey_exists_product(glob_rec_kandoouser.cmpy_code,p_rec_product.part_code) THEN
		LET p_rec_product.serial_flag = xlate_to(p_rec_product.serial_flag) 
		LET p_rec_product.total_tax_flag = xlate_to(p_rec_product.total_tax_flag) 
		LET p_rec_product.back_order_flag = xlate_to(p_rec_product.back_order_flag) 
		LET p_rec_product.disc_allow_flag = xlate_to(p_rec_product.disc_allow_flag) 
		LET p_rec_product.bonus_allow_flag = xlate_to(p_rec_product.bonus_allow_flag) 
		LET p_rec_product.trade_in_flag = xlate_to(p_rec_product.trade_in_flag) 
		LET p_rec_product.price_inv_flag = xlate_to(p_rec_product.price_inv_flag) 
		WHENEVER SQLERROR CONTINUE
		INSERT INTO product VALUES (p_rec_product.*) 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		IF sqlca.sqlcode < 0 THEN
			ERROR "INSERT product failed!"
			RETURN sqlca.sqlcode
		ELSE
			RETURN sqlca.sqlcode
		END IF
	ELSE
		LET msgresp=kandoomsg("I",9036,"") 
		#9036 "Product Code already exists, please re enter"
		RETURN -1 
	END IF 
END FUNCTION 	# insert_product

FUNCTION update_product(p_part_code,p_rec_product)
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_match_part NCHAR(32)
	LET p_rec_product.serial_flag = xlate_to(p_rec_product.serial_flag) 
	LET p_rec_product.total_tax_flag = xlate_to(p_rec_product.total_tax_flag) 
	LET p_rec_product.back_order_flag = xlate_to(p_rec_product.back_order_flag) 
	LET p_rec_product.disc_allow_flag = xlate_to(p_rec_product.disc_allow_flag) 
	LET p_rec_product.bonus_allow_flag = xlate_to(p_rec_product.bonus_allow_flag) 
	LET p_rec_product.trade_in_flag = xlate_to(p_rec_product.trade_in_flag) 
	LET p_rec_product.price_inv_flag = xlate_to(p_rec_product.price_inv_flag) 
	
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	UPDATE product SET * = p_rec_product.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_product.part_code 

	IF sqlca.sqlcode < 0 THEN
		ERROR "Product update FAILED with errors"
		ROLLBACK WORK
		RETURN sqlca.sqlcode
	END IF
	
	--LET p_arr_rec_product[l_arr_curr].desc_text = p_rec_product.desc_text 
	--LET p_arr_rec_product[l_arr_curr].short_desc_text = p_rec_product.short_desc_text 
	--LET p_arr_rec_product[l_arr_curr].status_date = p_rec_product.status_date 
	--LET p_arr_rec_product[l_arr_curr].status_ind = p_rec_product.status_ind 
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		SELECT * INTO l_rec_class.* 
		FROM class 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = p_rec_product.class_code 
		IF l_rec_class.stock_level_ind IS NOT NULL AND  l_rec_class.stock_level_ind > l_rec_class.price_level_ind THEN 
			LET l_match_part = p_rec_product.part_code clipped,"*" 
			UPDATE product 
			SET prodgrp_code = p_rec_product.prodgrp_code, 
				maingrp_code = p_rec_product.maingrp_code, 
				dept_code = p_rec_product.dept_code, 
				status_date = p_rec_product.status_date, 
				cat_code = p_rec_product.cat_code, 
				pur_uom_code = p_rec_product.pur_uom_code, 
				stock_uom_code = p_rec_product.stock_uom_code, 
				sell_uom_code = p_rec_product.sell_uom_code, 
				price_uom_code = p_rec_product.price_uom_code, 
				pur_stk_con_qty = p_rec_product.pur_stk_con_qty, 
				stk_sel_con_qty = p_rec_product.stk_sel_con_qty, 
				weight_qty = p_rec_product.weight_qty, 
				cubic_qty = p_rec_product.cubic_qty, 
				area_qty = p_rec_product.area_qty, 
				length_qty = p_rec_product.length_qty, 
				pack_qty = p_rec_product.pack_qty, 
				target_turn_qty = p_rec_product.target_turn_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code matches l_match_part 
				AND class_code = l_rec_class.class_code 
			IF sqlca.sqlcode <  0 THEN
				ERROR "Flex Product update FAILED with errors"
				ROLLBACK WORK
				RETURN sqlca.sqlcode
			END IF
		END IF
	END IF 
	COMMIT WORK
	IF sqlca.sqlcode <  0 THEN
		ERROR "COMMIT FAILED!"
	END IF
	WHENEVER ERROR CALL kandoo_sql_errors_handler
	RETURN sqlca.sqlcode
END FUNCTION  #  update_product

{
FUNCTION initalize_rec_product(p_mode,p_rec_product)
	DEFINE p_mode CHAR(5)
	DEFINE p_rec_product RECORD LIKE product.*
	IF p_mode = "ADD" THEN 
		LET p_rec_product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET p_rec_product.weight_qty = 0 
		LET p_rec_product.cubic_qty = 0 
		LET p_rec_product.area_qty = 0 
		LET p_rec_product.length_qty = 0 
		LET p_rec_product.pack_qty = 0 
		LET p_rec_product.target_turn_qty = 0 
		LET p_rec_product.stock_turn_qty = 0 
		LET p_rec_product.stock_days_num = 0 
		LET p_rec_product.pur_stk_con_qty = 0 
		LET p_rec_product.dg_code = NULL 
		LET p_rec_product.stk_sel_con_qty = 0 
		LET p_rec_product.outer_qty = 1 
		LET p_rec_product.outer_sur_per = 0 
		LET p_rec_product.min_ord_qty = 0 
		LET p_rec_product.days_lead_num = 0 
		LET p_rec_product.days_warr_num = 0 
		LET p_rec_product.min_month_amt = 0 
		LET p_rec_product.min_quart_amt = 0 
		LET p_rec_product.min_year_amt = 0 
		LET p_rec_product.serial_flag = no_flag 
		LET p_rec_product.total_tax_flag = yes_flag 
		LET p_rec_product.back_order_flag = yes_flag 
		LET p_rec_product.disc_allow_flag = yes_flag 
		LET p_rec_product.bonus_allow_flag = yes_flag 
		LET p_rec_product.trade_in_flag = no_flag 
		LET p_rec_product.price_inv_flag = yes_flag 
		LET p_rec_product.status_ind = "1" 
		LET p_rec_product.status_date = today 
		LET p_rec_product.setup_date = today 
		LET p_rec_product.last_calc_date = today 
	ELSE
	END IF 
	RETURN p_rec_product.*
END FUNCTION	# initalize_rec_product
}
