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

###########################################################################
# FUNCTION prpdwind(p_cmpy, p_part_code)
#
# displays pricing details
###########################################################################
FUNCTION prpdwind(p_cmpy,p_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 

	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_error_msg CHAR(60) 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_uom_conv FLOAT 
	DEFINE l_security_ind LIKE kandoouser.security_ind 
	DEFINE l_feature_ind LIKE kandoooption.feature_ind 
	DEFINE l_sale_tax_per LIKE tax.tax_per 
	DEFINE l_purch_tax_per LIKE tax.tax_per 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL get_security_level() RETURNING l_security_ind 

	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = p_cmpy 

	OPEN WINDOW I615 with FORM "I615" 
	CALL windecoration_i("I615") 

	DISPLAY l_rec_product.part_code TO product.part_code 
	DISPLAY l_rec_product.desc_text TO part_desc_text 
	DISPLAY l_rec_product.desc2_text TO part_desc2_text 

	MESSAGE kandoomsg2("I",1030,"")#1030 Enter Warehouse Code;  OK TO Continue.
	INPUT BY NAME l_rec_warehouse.ware_code 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","prpdwind","input-warehouse") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" --ON KEY (control-b) 
			LET l_temp_text = show_ware(p_cmpy) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_warehouse.ware_code = l_temp_text 
				DISPLAY BY NAME l_rec_warehouse.ware_code 

			END IF 
			NEXT FIELD ware_code 

		AFTER FIELD ware_code 
			IF l_rec_warehouse.ware_code IS NULL OR l_rec_warehouse.ware_code = " " THEN 
				ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered.
				NEXT FIELD ware_code 
			END IF 

			SELECT * INTO l_rec_warehouse.* FROM warehouse 
			WHERE ware_code = l_rec_warehouse.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("I",9030,"") 				#9030 Warehouse does NOT exist;  Try Window.
				NEXT FIELD ware_code 
			END IF 

			SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
			WHERE part_code = l_rec_product.part_code 
			AND ware_code = l_rec_warehouse.ware_code 
			AND cmpy_code = p_cmpy 
			IF status = notfound THEN 
				ERROR kandoomsg2("A",9126,"") 				#9156 Product NOT stocked AT this location.
				NEXT FIELD ware_code 
			END IF 

			DISPLAY l_rec_warehouse.desc_text TO ware_desc_text 

	END INPUT #------------------ END INPUT
	

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

	ELSE 

		SELECT tax_per INTO l_sale_tax_per FROM tax 
		WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
		AND tax_code = l_rec_prodstatus.sale_tax_code 
		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"Tax") 			# 7001 Logic Error: Tax RECORD does NOT exist in database.
			CLOSE WINDOW i615 
			RETURN 
		END IF 

		SELECT tax_per INTO l_purch_tax_per FROM tax 
		WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
		AND tax_code = l_rec_prodstatus.purch_tax_code 
		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"Tax") 			# 7001 Logic Error: Tax RECORD does NOT exist in database.
		ELSE 
			IF l_rec_product.sell_uom_code <> l_rec_product.price_uom_code THEN 
				LET l_uom_conv = get_uom_conversion_factor(p_cmpy,l_rec_prodstatus.part_code, 
				l_rec_product.sell_uom_code, 
				l_rec_product.price_uom_code,1) 
				IF l_uom_conv > 0 THEN 
					LET l_rec_prodstatus.list_amt = l_rec_prodstatus.list_amt * l_uom_conv 
					LET l_rec_prodstatus.price1_amt = l_rec_prodstatus.price1_amt * l_uom_conv 
					LET l_rec_prodstatus.price2_amt = l_rec_prodstatus.price2_amt * l_uom_conv 
					LET l_rec_prodstatus.price3_amt = l_rec_prodstatus.price3_amt * l_uom_conv 
					LET l_rec_prodstatus.price4_amt = l_rec_prodstatus.price4_amt * l_uom_conv 
					LET l_rec_prodstatus.price5_amt = l_rec_prodstatus.price5_amt * l_uom_conv 
					LET l_rec_prodstatus.price6_amt = l_rec_prodstatus.price6_amt * l_uom_conv 
					LET l_rec_prodstatus.price7_amt = l_rec_prodstatus.price7_amt * l_uom_conv 
					LET l_rec_prodstatus.price8_amt = l_rec_prodstatus.price8_amt * l_uom_conv 
					LET l_rec_prodstatus.price9_amt = l_rec_prodstatus.price9_amt * l_uom_conv 
				END IF 
			END IF 

			SELECT feature_ind INTO l_feature_ind FROM kandoooption 
			WHERE cmpy_code = p_cmpy 
			AND module_code = TRAN_TYPE_INVOICE_IN 
			AND feature_code = "HC" 
			IF not(status = notfound) THEN 
				IF l_security_ind < l_feature_ind THEN 
					LET l_rec_prodstatus.wgted_cost_amt = NULL 
					LET l_rec_prodstatus.est_cost_amt = NULL 
					LET l_rec_prodstatus.act_cost_amt = NULL 
					LET l_rec_prodstatus.for_cost_amt = NULL 
					LET l_rec_prodstatus.for_curr_code = NULL 
				END IF 
			END IF 
			
			DISPLAY BY NAME 
				l_rec_product.price_uom_code, 
				l_rec_product.sell_uom_code, 
				l_rec_prodstatus.list_amt, 
				l_rec_prodstatus.pricel_ind, 
				l_rec_prodstatus.pricel_per, 
				l_rec_prodstatus.price1_amt, 
				l_rec_prodstatus.price1_ind, 
				l_rec_prodstatus.price1_per, 
				l_rec_prodstatus.price2_amt, 
				l_rec_prodstatus.price2_ind, 
				l_rec_prodstatus.price2_per, 
				l_rec_prodstatus.price3_amt, 
				l_rec_prodstatus.price3_ind, 
				l_rec_prodstatus.price3_per, 
				l_rec_prodstatus.price4_amt, 
				l_rec_prodstatus.price4_ind, 
				l_rec_prodstatus.price4_per, 
				l_rec_prodstatus.price5_amt, 
				l_rec_prodstatus.price5_ind, 
				l_rec_prodstatus.price5_per, 
				l_rec_prodstatus.price6_amt, 
				l_rec_prodstatus.price6_ind, 
				l_rec_prodstatus.price6_per, 
				l_rec_prodstatus.price7_amt, 
				l_rec_prodstatus.price7_ind, 
				l_rec_prodstatus.price7_per, 
				l_rec_prodstatus.price8_amt, 
				l_rec_prodstatus.price8_ind, 
				l_rec_prodstatus.price8_per, 
				l_rec_prodstatus.price9_amt, 
				l_rec_prodstatus.price9_ind, 
				l_rec_prodstatus.price9_per, 
				l_rec_prodstatus.wgted_cost_amt, 
				l_rec_prodstatus.est_cost_amt, 
				l_rec_prodstatus.act_cost_amt, 
				l_rec_prodstatus.for_cost_amt, 
				l_rec_prodstatus.sale_tax_code, 
				l_rec_prodstatus.purch_tax_code, 
				l_rec_prodstatus.sale_tax_amt, 
				l_rec_prodstatus.purch_tax_amt, 
				l_rec_prodstatus.last_price_date, 
				l_rec_prodstatus.last_list_date 

			DISPLAY BY NAME l_rec_prodstatus.for_curr_code attribute (green) 
			DISPLAY l_sale_tax_per	TO sale_tax_per 
			DISPLAY l_purch_tax_per	TO purch_tax_per

			CALL eventsuspend()
		END IF 
	END IF 

	CLOSE WINDOW I615 
END FUNCTION 

###########################################################################
# END FUNCTION prpdwind(p_cmpy, p_part_code)
###########################################################################