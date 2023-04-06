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




# This module contains functions that are re used in several modules of the IN BM
# They are more specialized in forms handling and interaction
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

DEFINE cb_maingrp_code ui.ComboBox		# dynamic
DEFINE cb_prodgrp_code ui.ComboBox
DEFINE cb_part_code ui.ComboBox

##########################################################################################
# FUNCTION input_product_main_details()
#
#
##########################################################################################
FUNCTION input_product_main_details(p_mode,p_part_code) 		# probability to use the same function for EDIT ...
	DEFINE p_mode CHAR(5)
	DEFINE p_part_code LIKE product.part_code
	DEFINE l_rec_product RECORD LIKE product.*		# Main record for product INPUT
	DEFINE l_rec_category RECORD LIKE category.*
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_rec_proddept RECORD LIKE proddept.*
	DEFINE l_rec_maingrp RECORD LIKE maingrp.*
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.*

	DEFINE l_rec_product_aux RECORD LIKE product.*		# Record for auxiliary product  INPUT
	DEFINE l_rec_proddanger RECORD LIKE proddanger.*
	DEFINE l_temp_part_code LIKE product.part_code
	DEFINE l_alter_text,l_compn_text,l_super_text LIKE product.desc_text
	DEFINE l_part_text LIKE product.desc_text
	DEFINE l_part2_text LIKE product.desc2_text
	DEFINE msgresp LIKE language.yes_flag
	DEFINE l_parent_part_code, l_opt_segment, l_filler CHAR(1)
	DEFINE l_part_length SMALLINT
	DEFINE l_direction_ind CHAR(1)
	DEFINE l_temp_text CHAR(60)
	DEFINE l_char_string CHAR(30)
	DEFINE l_rec_class_len SMALLINT 
	DEFINE l_operation_status SMALLINT
	
	CASE
		WHEN p_mode = MODE_CLASSIC_EDIT OR p_mode = MODE_CLASSIC_REMOVE
			OPEN WINDOW i626 with FORM "I626"
			 CALL windecoration_i("I626")
			DISPLAY glob_rec_company.cmpy_code,glob_rec_company.name_text
			TO hdr_cmpy_code,hdr_cmpy_name
			
			SELECT *
			INTO l_rec_product.*
			FROM product
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND part_code = p_part_code
			IF sqlca.sqlcode = NOTFOUND THEN
				ERROR "This product does not exist"
			ELSE
				LET l_rec_product.serial_flag = xlate_from(l_rec_product.serial_flag) 
				LET l_rec_product.total_tax_flag = xlate_from(l_rec_product.total_tax_flag) 
				LET l_rec_product.back_order_flag = xlate_from(l_rec_product.back_order_flag) 
				LET l_rec_product.disc_allow_flag = xlate_from(l_rec_product.disc_allow_flag) 
				LET l_rec_product.bonus_allow_flag=xlate_from(l_rec_product.bonus_allow_flag) 
				LET l_rec_product.trade_in_flag = xlate_from(l_rec_product.trade_in_flag) 
				LET l_rec_product.price_inv_flag = xlate_from(l_rec_product.price_inv_flag) 

				CALL db_get_desc_class(l_rec_product.cmpy_code,l_rec_product.class_code)
				RETURNING l_rec_class.desc_text,l_operation_status

				CALL db_get_desc_category(l_rec_product.cmpy_code,l_rec_product.cat_code)
				RETURNING l_rec_category.desc_text,l_operation_status

				CALL db_get_desc_proddept(l_rec_product.cmpy_code,l_rec_product.dept_code)
				RETURNING l_rec_proddept.desc_text,l_operation_status

				CALL db_get_desc_maingrp(l_rec_product.cmpy_code,l_rec_product.dept_code,l_rec_product.maingrp_code)
				RETURNING l_rec_maingrp.desc_text,l_operation_status
				
				CALL db_get_desc_prodgrp(l_rec_product.cmpy_code,l_rec_product.dept_code,l_rec_product.maingrp_code,l_rec_product.prodgrp_code)
				RETURNING l_rec_prodgrp.desc_text,l_operation_status

				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.alter_part_code)
				RETURNING l_alter_text,l_operation_status

				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.super_part_code)
				RETURNING l_super_text,l_operation_status

				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.compn_part_code)
				RETURNING l_compn_text,l_operation_status


				DISPLAY BY NAME l_rec_product.cat_code,  
					l_rec_product.class_code,
					l_rec_product.dept_code, 
					l_rec_product.maingrp_code, 
					l_rec_product.prodgrp_code, 
					l_rec_product.part_code,  
					l_rec_product.desc_text,  
					l_rec_product.desc2_text,
					l_rec_product.short_desc_text, 
					l_rec_product.alter_part_code, 
					l_rec_product.super_part_code, 
					l_rec_product.compn_part_code, 
					l_rec_product.pur_uom_code, 
					l_rec_product.stock_uom_code, 
					l_rec_product.sell_uom_code, 
					l_rec_product.price_uom_code, 
					l_rec_product.pur_stk_con_qty, 
					l_rec_product.stk_sel_con_qty, 
					l_rec_product.dg_code, 
					l_rec_product.target_turn_qty, 
					l_rec_product.stock_turn_qty

				DISPLAY l_rec_category.desc_text TO category.desc_text
				DISPLAY l_rec_class.desc_text TO class.desc_text
				DISPLAY l_rec_proddept.desc_text TO proddept.desc_text
				DISPLAY l_rec_maingrp.desc_text TO maingrp.desc_text
				DISPLAY l_rec_prodgrp.desc_text TO prodgrp.desc_text
				DISPLAY l_alter_text TO alter_text
				DISPLAY l_super_text TO super_text
				DISPLAY l_compn_text TO compn_text
				
			END IF
		WHEN p_mode = MODE_CLASSIC_ADD	
			CALL initalize_rec_product(p_mode,l_rec_product.*) RETURNING l_rec_product.*
	END CASE
	
	INPUT l_rec_product.cat_code,  
		l_rec_product.class_code,
		l_rec_product.dept_code, 
		l_rec_product.maingrp_code, 
		l_rec_product.prodgrp_code, 
		l_rec_product.part_code,  
		l_rec_product.desc_text,  
		l_rec_product.desc2_text,
		l_rec_product.short_desc_text, 
		l_rec_product.alter_part_code, 
		l_rec_product.super_part_code, 
		l_rec_product.compn_part_code, 
		l_rec_product.pur_uom_code, 
		l_rec_product.stock_uom_code, 
		l_rec_product.sell_uom_code, 
		l_rec_product.price_uom_code, 
		l_rec_product.pur_stk_con_qty, 
		l_rec_product.stk_sel_con_qty, 
		l_rec_product.dg_code, 
		l_rec_product.target_turn_qty, 
		l_rec_product.stock_turn_qty
	 
	WITHOUT DEFAULTS
	FROM product.*	# we use here a specific screen record that avoid listing all the fields in the from clause

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11","input-l_rec_product") 
			CASE
				# When edit, we do not touch the primary key fields
				WHEN p_mode = MODE_CLASSIC_EDIT
					CALL DIALOG.SetFieldActive("part_code", false)
				WHEN p_mode = MODE_CLASSIC_ADD
					CALL DIALOG.SetFieldActive("part_code", true)
			END CASE
			

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		--ON KEY (control-b)
		ON ACTION ("LOOKUP","control-b") 
			CASE 
				WHEN infield(prodgrp_code) 
					LET l_rec_product.prodgrp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					NEXT FIELD prodgrp_code 
				WHEN infield(cat_code) 
					LET l_rec_product.cat_code = show_pcat(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD cat_code 
				WHEN infield(class_code) 
					LET l_rec_product.class_code = show_pcls(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD class_code 
				WHEN infield(alter_part_code) 
					LET l_rec_product.alter_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD alter_part_code 
				WHEN infield(super_part_code) 
					LET l_rec_product.super_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD super_part_code 
				WHEN infield(compn_part_code) 
					LET l_rec_product.compn_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD compn_part_code 
				WHEN infield(sell_uom_code) 
					LET l_rec_product.sell_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD sell_uom_code 
				WHEN infield(price_uom_code) 
					LET l_rec_product.price_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD price_uom_code 
				WHEN infield(pur_uom_code) 
					LET l_rec_product.pur_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD pur_uom_code 
				WHEN infield(stock_uom_code) 
					LET l_rec_product.stock_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD stock_uom_code 
				WHEN infield(dg_code) 
					LET l_temp_text = show_proddanger(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_text IS NOT NULL THEN 
						LET l_rec_product.dg_code = l_temp_text 
					END IF 
					NEXT FIELD dg_code 
			END CASE 

		--ON KEY (F9) infield (class_code) 

--		BEFORE FIELD class_code 
--			LET msgresp=kandoomsg("I",1011,"") 
--			#1011 " Enter product details - F9 TO Image Existing Product "
		#Not sure about what direction_ind = "U" means ....
		--BEFORE FIELD cat_code 
			--IF l_opt_segment IS NOT NULL AND l_opt_segment != " " THEN 
				--IF l_direction_ind = "U" THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			--END IF 

		AFTER FIELD cat_code 
			IF l_rec_product.cat_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9038,"") 
				#9038 "product category Code must be entered"
				NEXT FIELD cat_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_category.desc_text 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_rec_product.cat_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				ELSE 
					DISPLAY l_rec_category.desc_text TO category.desc_text 

				END IF 
			END IF 

		AFTER FIELD class_code 
			IF l_rec_product.class_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9040,"") 
				#9040 "Product Class code must be Entered"
				NEXT FIELD class_code 
			ELSE 
				SELECT desc_text INTO l_rec_class.desc_text 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_product.class_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				ELSE 
					DISPLAY l_rec_class.desc_text TO class.desc_text 

				END IF 
			END IF 
			LET msgresp=kandoomsg("I",1014,"") 
			#1014 " Enter product details

		AFTER FIELD dept_code 
			IF l_rec_product.dept_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD dept_code 
			ELSE 
				SELECT desc_text, dept_code 
				INTO l_rec_proddept.desc_text, l_rec_product.dept_code 
				FROM proddept 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = l_rec_product.dept_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD dept_code 
				ELSE 
					DISPLAY l_rec_proddept.desc_text TO proddept.desc_text 

				END IF 
			END IF 

		BEFORE FIELD maingrp_code 
			# because maingrp_code depends on dept_code, the combo is filled with a filter on dept_code 
			CALL dyn_combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_rec_product.dept_code) 

			--IF l_opt_segment IS NOT NULL 
			--AND l_opt_segment != " " THEN 
				--IF l_direction_ind = "U" THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			--END IF 

		AFTER FIELD maingrp_code 
			IF l_rec_product.maingrp_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT desc_text, maingrp_code 
				INTO l_rec_maingrp.desc_text, l_rec_product.maingrp_code 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = l_rec_product.maingrp_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD maingrp_code 
				ELSE 
					DISPLAY l_rec_maingrp.desc_text TO maingrp.desc_text 

				END IF 
			END IF 

		BEFORE FIELD prodgrp_code 
			# same principle as for maingrp_code
			CALL dyn_combolist_prodgrp 
			("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_rec_product.dept_code,l_rec_product.maingrp_code) 
			IF l_opt_segment IS NOT NULL 
			AND l_opt_segment != " " THEN 
				IF l_direction_ind = "U" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD prodgrp_code 
			IF l_rec_product.prodgrp_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD prodgrp_code 
			ELSE 
				SELECT desc_text, prodgrp_code 
				INTO l_rec_prodgrp.desc_text, l_rec_product.prodgrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_product.prodgrp_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				ELSE 
					DISPLAY l_rec_prodgrp.desc_text TO prodgrp.desc_text 

				END IF 
			END IF 

		BEFORE FIELD part_code 
			CALL dyn_combolist_product
			("part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_rec_product.dept_code,l_rec_product.maingrp_code,l_rec_product.prodgrp_code) 
			
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" AND mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_product.class_code) THEN 
				CALL segment_verify(l_rec_product.class_code, l_rec_product.part_code) 
				RETURNING l_rec_product.part_code, l_part_text, l_part2_text 
				IF l_rec_product.part_code IS NULL THEN 
					NEXT FIELD class_code 
				ELSE 
					LET l_temp_part_code = l_rec_product.part_code 
					LET l_rec_product.desc_text = NULL 
					LET l_rec_product.desc2_text = NULL 
					DISPLAY BY NAME l_rec_product.part_code 

					# TODO : see if we cannot make a lib function out of this section
					SELECT 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 

					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					ELSE 
						CALL break_prod(glob_rec_kandoouser.cmpy_code, l_rec_product.part_code,	l_rec_product.class_code,1) 
						RETURNING l_parent_part_code, l_filler, l_opt_segment, l_part_length 
						IF l_opt_segment IS NOT NULL AND l_opt_segment != " " THEN 
							SELECT * INTO l_rec_product_aux.* 
							FROM product 
							WHERE part_code = l_parent_part_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_product.* = l_rec_product_aux.* 
							LET l_rec_product.part_code = l_parent_part_code clipped,l_filler clipped, l_opt_segment clipped 
							LET l_rec_product.desc_text = l_part_text 
							LET l_rec_product.desc2_text = l_part2_text 
							LET l_rec_product.part_code = l_temp_part_code 
						END IF 

						IF l_rec_product.desc_text IS NULL AND l_rec_product.desc2_text IS NULL THEN 
							LET l_rec_product.desc_text = l_part_text 
							LET l_rec_product.desc2_text = l_part2_text 
							LET l_rec_product.short_desc_text = l_rec_product.part_code 
						END IF 

						#IF l_rec_product.short_desc_text IS NULL THEN
						#LET l_rec_product.short_desc_text = l_rec_product.part_code
						#END IF
						IF l_rec_product.oem_text IS NULL THEN 
							LET l_rec_product.oem_text = l_rec_product.part_code 
						END IF 

						DISPLAY BY NAME 
							l_rec_product.cat_code, 
							l_rec_product.class_code, 
							l_rec_product.dept_code,
							l_rec_product.maingrp_code,  
							l_rec_product.prodgrp_code,
							l_rec_product.short_desc_text, 
							l_rec_product.desc_text, 
							l_rec_product.desc2_text, 
							l_rec_product.alter_part_code, 
							l_rec_product.super_part_code, 
							l_rec_product.compn_part_code, 
							l_rec_product.pur_uom_code, 
							l_rec_product.stock_uom_code, 
							l_rec_product.sell_uom_code, 
							l_rec_product.price_uom_code, 
							l_rec_product.pur_stk_con_qty, 
							l_rec_product.stk_sel_con_qty, 
							l_rec_product.dg_code, 
							l_rec_product.stock_turn_qty, 
							l_rec_product.target_turn_qty 

						SELECT desc_text INTO l_rec_proddept.desc_text 
						FROM proddept 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND proddept_code = l_rec_product.proddept_code 
						DISPLAY l_rec_proddept.desc_text TO maingrp.desc_text 

						SELECT desc_text INTO l_rec_maingrp.desc_text 
						FROM maingrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND maingrp_code = l_rec_product.maingrp_code 
						DISPLAY l_rec_maingrp.desc_text TO maingrp.desc_text 

						SELECT desc_text INTO l_rec_prodgrp.desc_text 
						FROM prodgrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND prodgrp_code = l_rec_product.prodgrp_code 
						DISPLAY l_rec_prodgrp.desc_text TO prodgrp.desc_text 

						SELECT desc_text INTO l_rec_category.desc_text 
						FROM category 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cat_code = l_rec_product.cat_code 
						DISPLAY l_rec_category.desc_text TO category.desc_text 

						SELECT * INTO l_rec_proddanger.* 
						FROM proddanger 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND dg_code = l_rec_product.dg_code 
						DISPLAY l_rec_proddanger.tech_text TO proddanger.tech_text 
					END IF 
					--NEXT FIELD short_desc_text 
				END IF 
			ELSE 
				#LET l_rec_product.desc_text = " "
				#LET l_rec_product.desc2_text = " "
				#LET l_rec_product.short_desc_text = " "
				DISPLAY BY NAME l_rec_product.desc_text,l_rec_product.short_desc_text 
			END IF 

		AFTER FIELD part_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				IF NOT mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_product.class_code) THEN 
					SELECT sum(prodstructure.length) INTO l_rec_class_len 
					FROM prodstructure 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = l_rec_product.class_code 
					IF l_rec_class_len IS NULL THEN 
						LET l_rec_class_len = 15 
					END IF 
					LET l_char_string = l_rec_product.part_code 
					IF validate_string(l_char_string,1,l_rec_class_len,true) 
					THEN ELSE 
						NEXT FIELD part_code 
					END IF 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 
					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					END IF 
					SELECT unique 1 FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = l_rec_product.part_code 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("I",9552,"") 
						#9552 "Code already used by alternate/companion group.
						NEXT FIELD part_code 
					END IF 
				END IF 
			ELSE 
				LET l_char_string = l_rec_product.part_code 
				IF validate_string(l_char_string,1,15,true) 
				THEN ELSE 
					NEXT FIELD part_code 
				END IF 
				
				# Check duplicate primary key if ADD
				IF p_mode = MODE_CLASSIC_ADD THEN
					IF check_prykey_exists_product(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code) = true THEN
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					END IF 
				END IF
			END IF 

		AFTER FIELD short_desc_text 
			IF l_rec_product.short_desc_text IS NULL THEN 
				LET msgresp=kandoomsg("I",9503,"") 
				#9503 " Product short description must be entered"
				NEXT FIELD short_desc_text 
			END IF 

		AFTER FIELD product.desc_text 
			IF l_rec_product.desc_text IS NULL THEN 
				LET msgresp=kandoomsg("I",9037,"") 
				#9037 " Product description must be entered"
				NEXT FIELD desc_text 
			END IF 

		--AFTER FIELD desc2_text 
			--LET l_direction_ind = "D" 

		--BEFORE FIELD alter_part_code 
			--LET l_direction_ind = "U" 

		AFTER FIELD alter_part_code 
			IF l_rec_product.alter_part_code IS NOT NULL THEN 
				IF l_rec_product.alter_part_code = l_rec_product.part_code THEN 
					LET msgresp=kandoomsg("I",9042,"") 
					#9042 "Product can NOT be an alternate TO itself"
					NEXT FIELD alter_part_code 
				END IF 
				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.alter_part_code)
				RETURNING l_alter_text,l_operation_status

				IF l_operation_status = notfound THEN 
					SELECT desc_text 
					INTO l_alter_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = l_rec_product.alter_part_code 
					AND type_ind = "A" 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("I",9043,"") 
						#9043" Aletrnate Product OR Group NOT found - Try Window "
						NEXT FIELD alter_part_code 
					END IF 
				END IF 
				DISPLAY l_alter_text TO l_alter_text 
			END IF 

		AFTER FIELD super_part_code 
			CLEAR l_super_text 
			IF l_rec_product.super_part_code IS NOT NULL THEN 
				IF l_rec_product.part_code = l_rec_product.super_part_code THEN 
					LET msgresp=kandoomsg("I",9044,"") 
					#9044" Product cannot be superceded by itself "
					NEXT FIELD super_part_code 
				END IF 
				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.super_part_code)
				RETURNING l_super_text,l_operation_status

				IF l_operation_status = notfound THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010"Product Code NOT found - Try Window "
					NEXT FIELD super_part_code 
				END IF 
				DISPLAY BY NAME l_super_text 

			END IF 

		AFTER FIELD compn_part_code 
			CLEAR l_compn_text 
			IF l_rec_product.compn_part_code IS NOT NULL THEN 
				IF l_rec_product.part_code = l_rec_product.compn_part_code THEN 
					LET msgresp=kandoomsg("I",9047,"") 
					#9047 " Product cannot be a companion of itself "
					NEXT FIELD compn_part_code 
				END IF 
				CALL db_get_desc_product(l_rec_product.cmpy_code,l_rec_product.compn_part_code)
				RETURNING l_compn_text,l_operation_status

				IF l_operation_status = notfound THEN 
					SELECT desc_text 
					INTO l_compn_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = l_rec_product.compn_part_code 
					AND type_ind = "C" 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("I",9048,"") 
						#9048 " Companion Product OR Group NOT found - Try Window"
						NEXT FIELD compn_part_code 
					END IF 
				END IF 
				DISPLAY BY NAME l_compn_text 
			END IF 

		AFTER FIELD pur_uom_code 
			IF l_rec_product.pur_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9049,"") 
				#9049" Purchasing Unit Of Measure must be entered "
				NEXT FIELD pur_uom_code 
			ELSE 
				IF NOT check_prykey_exists_uom(l_rec_product.cmpy_code,l_rec_product.pur_uom_code) THEN
					LET msgresp=kandoomsg("I",9050,"") 
					#9050" Purchasing Unit Of Measure NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				ELSE			
					IF l_rec_product.stock_uom_code IS NULL THEN 
						LET l_rec_product.stock_uom_code = l_rec_product.pur_uom_code 
					END IF 
				END IF
			END IF 
			IF l_rec_product.pur_uom_code = l_rec_product.stock_uom_code THEN 
				LET l_rec_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME l_rec_product.pur_stk_con_qty 
			END IF 

		AFTER FIELD stock_uom_code 
			IF l_rec_product.stock_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9051,"") 
				#9051 "Stocking UOM must be entered"
				NEXT FIELD stock_uom_code 
			ELSE 
				IF NOT check_prykey_exists_uom(l_rec_product.cmpy_code,l_rec_product.stock_uom_code) THEN
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				ELSE 
					IF l_rec_product.sell_uom_code IS NULL THEN 
						LET l_rec_product.sell_uom_code = l_rec_product.stock_uom_code 
					END IF 
				END IF 
			END IF 

			IF l_rec_product.pur_uom_code = l_rec_product.stock_uom_code THEN 
				LET l_rec_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME l_rec_product.pur_stk_con_qty 
			END IF 

			IF l_rec_product.stock_uom_code = l_rec_product.sell_uom_code THEN 
				LET l_rec_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME l_rec_product.stk_sel_con_qty 
			END IF 

		AFTER FIELD sell_uom_code 
			IF l_rec_product.sell_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9053,"") 
				#9053 "Selling Unit Of Measure must be entered"
				NEXT FIELD sell_uom_code 
			ELSE 
				IF NOT check_prykey_exists_uom(l_rec_product.cmpy_code,l_rec_product.sell_uom_code) THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				ELSE 
					IF l_rec_product.price_uom_code IS NULL THEN 
						LET l_rec_product.price_uom_code = l_rec_product.sell_uom_code 
					END IF 
				END IF 
			END IF 
			IF l_rec_product.stock_uom_code = l_rec_product.sell_uom_code THEN 
				LET l_rec_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME l_rec_product.stk_sel_con_qty 
			END IF 

		BEFORE FIELD price_uom_code 
			IF glob_rec_company.module_text[23] != "W" THEN 
				LET l_rec_product.price_uom_code = l_rec_product.sell_uom_code 
				DISPLAY BY NAME l_rec_product.price_uom_code 

				
				## Watch OUT!
				{ IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
				}
			END IF 

		AFTER FIELD price_uom_code 
			IF l_rec_product.price_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9215,"") 
				#9215 "Pricing Unit Of Measure must be entered"
				NEXT FIELD price_uom_code 
			ELSE 
				IF NOT check_prykey_exists_uom(l_rec_product.cmpy_code,l_rec_product.price_uom_code) THEN 
					LET msgresp=kandoomsg("I",9216,"") 
					#9216" UOM NOT found - Try Window"
					NEXT FIELD price_uom_code 
				END IF 
			END IF 

		BEFORE FIELD pur_stk_con_qty 
			IF l_rec_product.pur_uom_code = l_rec_product.stock_uom_code THEN 
				LET l_rec_product.pur_stk_con_qty = 1 
				## Watch OUT!
				--IF fgl_lastkey() = fgl_keyval("up") 
				--OR fgl_lastkey() = fgl_keyval("left") THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			END IF 

		AFTER FIELD pur_stk_con_qty 
			IF l_rec_product.pur_stk_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9055,"") 
				#9055 "Must enter Purchasing TO Stock Conversion Rate"
				NEXT FIELD pur_stk_con_qty 
			END IF 
			IF l_rec_product.pur_stk_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD pur_stk_con_qty 
			ELSE 
				IF l_rec_product.pur_stk_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7012,"") 
					#7012 "WARNING - the stocking unit IS larger than the buying .."
				END IF 
			END IF 

		BEFORE FIELD stk_sel_con_qty 
			IF l_rec_product.stock_uom_code = l_rec_product.sell_uom_code THEN 
				LET l_rec_product.stk_sel_con_qty = 1 
				## Watch OUT!
				--IF fgl_lastkey() = fgl_keyval("up") 
				--OR fgl_lastkey() = fgl_keyval("left") THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			END IF 

		AFTER FIELD stk_sel_con_qty 
			IF l_rec_product.stk_sel_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9056,"") 
				#9056" Must enter Stocking TO Sales Conversion rate "
				NEXT FIELD stk_sel_con_qty 
			END IF 
			IF l_rec_product.stk_sel_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD stk_sel_con_qty 
			ELSE 
				IF l_rec_product.stk_sel_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7013,"") 
					#7013 "WARNING - the stocking unit IS smaller than the selling.."
				END IF 
			END IF 

		AFTER FIELD dg_code 
			IF l_rec_product.dg_code IS NOT NULL THEN 
				CALL db_get_desc_proddanger(glob_rec_kandoouser.cmpy_code,l_rec_product.dg_code)
				RETURNING l_rec_proddanger.tech_text ,l_operation_status
				IF l_operation_status = 0 THEN 
					#9246 "Dangerous goods code does NOT EXIT - try window"
					LET msgresp=kandoomsg("I",9246,"") 
					NEXT FIELD dg_code 
				ELSE 
					DISPLAY l_rec_proddanger.tech_text 
					TO proddanger.tech_text 
				END IF 
			END IF 

		ON ACTION ("ImageProduct") infield (class_code)
			CALL image_product(l_rec_product.part_code) 
			RETURNING l_operation_status,l_rec_product.*
			IF l_operation_status THEN
				DISPLAY BY NAME l_rec_product.short_desc_text, 
				l_rec_product.desc_text, 
				l_rec_product.desc2_text, 
				l_rec_product.prodgrp_code, 
				l_rec_product.cat_code, 
				l_rec_product.class_code, 
				l_rec_product.alter_part_code, 
				l_rec_product.super_part_code, 
				l_rec_product.compn_part_code, 
				l_rec_product.pur_uom_code, 
				l_rec_product.stock_uom_code, 
				l_rec_product.sell_uom_code, 
				l_rec_product.price_uom_code, 
				l_rec_product.pur_stk_con_qty, 
				l_rec_product.stk_sel_con_qty, 
				l_rec_product.dg_code, 
				l_rec_product.stock_turn_qty, 
				l_rec_product.target_turn_qty 

				SELECT desc_text INTO l_rec_prodgrp.desc_text 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_product.prodgrp_code 
				
				SELECT desc_text INTO l_rec_category.desc_text 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_rec_product.cat_code 
				
				SELECT desc_text INTO l_rec_class.desc_text 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_product.class_code 
				
				SELECT desc_text INTO l_alter_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.alter_part_code 
				
				SELECT desc_text INTO l_compn_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.compn_part_code 
				
				SELECT desc_text INTO l_super_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.super_part_code 
				
				SELECT * INTO l_rec_proddanger.* 
				FROM proddanger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dg_code = l_rec_product.dg_code 
				
				DISPLAY l_rec_prodgrp.desc_text, 
				l_rec_category.desc_text, 
				l_rec_class.desc_text, 
				l_alter_text, 
				l_compn_text, 
				l_super_text, 
				l_rec_proddanger.tech_text 
				TO prodgrp.desc_text, 
				category.desc_text, 
				class.desc_text, 
				alter_part_code, 
				compn_part_code, 
				super_part_code, 
				proddanger.tech_text 

				NEXT FIELD class_code 
			END IF 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET msgresp = kandoomsg("I",8010,"") 
				#8010 Do you wish TO Quit (Y/N)
				IF msgresp = "Y" THEN 
					LET quit_flag = true 
				ELSE 
					NEXT FIELD class_code 
				END IF 
			ELSE 
			{ 
				ericv: probably repeated tests from AFTER FIELD with no need to have at the end
				IF l_rec_product.part_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9013,"") 
					#9013 Product Code must be Entered"
					NEXT FIELD part_code 
				END IF 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
					IF NOT mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_product.class_code) THEN 
						SELECT sum(prodstructure.length) INTO l_rec_class_len 
						FROM prodstructure 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND class_code = l_rec_product.class_code 
						IF l_rec_class_len IS NULL THEN 
							LET l_rec_class_len = 15 
						END IF 
						LET l_char_string = l_rec_product.part_code 
						IF NOT validate_string(l_char_string,1,l_rec_class_len,true) 
						THEN 
							NEXT FIELD part_code 
						END IF 
					END IF 
				END IF 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_product.part_code 

				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9036,"") 
					#9036 "Product Code already exists, please re enter"
					NEXT FIELD part_code 
				END IF 

				IF l_rec_product.part_code = l_rec_product.alter_part_code THEN 
					LET msgresp=kandoomsg("I",9042,"") 
					#9042 Product cannot be an alternative of itself "
					CLEAR l_alter_text 
					NEXT FIELD alter_part_code 
				END IF 

				IF l_rec_product.part_code = l_rec_product.compn_part_code THEN 
					LET msgresp=kandoomsg("I",9047,"") 
					#9047" Product cannot be a companion of itself "
					NEXT FIELD compn_part_code 
				END IF 

				SELECT unique 1 FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_rec_product.cat_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				END IF 
				SELECT maingrp_code 
				INTO l_rec_product.maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = l_rec_product.prodgrp_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				END IF 
				SELECT unique 1 FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_rec_product.class_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				END IF 
				IF l_rec_product.short_desc_text IS NULL THEN 
					#9503 "Must enter description product description"
					LET msgresp=kandoomsg("I",9503,"") 
					NEXT FIELD short_desc_text 
				END IF 
				IF l_rec_product.desc_text IS NULL THEN 
					LET msgresp=kandoomsg("I",9037,"") 
					#9037 "Must enter description product description"
					NEXT FIELD desc_text 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = l_rec_product.pur_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9050,"") 
					#9050 " Purchasing UOM NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = l_rec_product.stock_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" Stocking UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = l_rec_product.sell_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" Selling UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				END IF 
				IF l_rec_product.price_uom_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9215,"") 
					#9215 "Pricing Unit Of Measure must be entered"
					NEXT FIELD price_uom_code 
				ELSE 
					SELECT unique 1 FROM uom 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND uom_code = l_rec_product.price_uom_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("I",9216,"") 
						#9216" UOM NOT found - Try Window"
						NEXT FIELD price_uom_code 
					END IF 
				END IF 
				IF l_rec_product.pur_uom_code = l_rec_product.sell_uom_code 
				AND l_rec_product.pur_uom_code <> l_rec_product.stock_uom_code THEN 
					LET msgresp=kandoomsg("I",9298,"") 
					#9298 WHEN Purchase UOM = Sell UOM THEN Stock Uom needs t
					NEXT FIELD stock_uom_code 
				END IF 
				IF l_rec_product.serial_flag = 'Y' THEN 
					IF l_rec_product.pur_uom_code <> l_rec_product.stock_uom_code 
					OR l_rec_product.pur_uom_code <> l_rec_product.sell_uom_code THEN 
						LET msgresp=kandoomsg("I",9297,"") 
						#9297 All Units of Measure must be the same FOR serial
						NEXT FIELD pur_uom_code 
					END IF 
				END IF 
				IF l_rec_product.pur_stk_con_qty IS NULL THEN 
					LET msgresp=kandoomsg("I",9055,"") 
					#9055 "Must enter Purchasing TO Stock Conversion Rate"
					NEXT FIELD pur_stk_con_qty 
				END IF 
				IF l_rec_product.pur_stk_con_qty = 0 THEN 
					#9502 "Conversion rate cannot be zero"
					LET msgresp=kandoomsg("I",9502,"") 
					NEXT FIELD pur_stk_con_qty 
				ELSE 
					IF l_rec_product.pur_stk_con_qty < 1 THEN 
						LET msgresp=kandoomsg("I",7012,"") 
						#7012 "WARNING - the stocking unit IS larger than the buying"
					END IF 
				END IF 
				IF l_rec_product.stk_sel_con_qty IS NULL THEN 
					LET msgresp=kandoomsg("I",9056,"") 
					#9056" Must enter Stocking TO Sales Conversion rate "
					NEXT FIELD stk_sel_con_qty 
				END IF 
				IF l_rec_product.stk_sel_con_qty = 0 THEN 
					#9502 "Conversion rate cannot be zero"
					LET msgresp=kandoomsg("I",9502,"") 
					NEXT FIELD stk_sel_con_qty 
				ELSE 
					IF l_rec_product.stk_sel_con_qty < 1 THEN 
						LET msgresp=kandoomsg("I",7013,"") 
						#7013 "WARNING - the stocking unit IS smaller than the sell"
					END IF 
				END IF 
				IF l_rec_product.dg_code IS NOT NULL THEN 
					SELECT unique 1 FROM proddanger 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dg_code = l_rec_product.dg_code 
					IF sqlca.sqlcode = notfound THEN 
						#9246 "Dangerous goods code does NOT EXIT - try window"
						LET msgresp=kandoomsg("I",9246,"") 
						NEXT FIELD dg_code 
					END IF 
				END IF 
				}
				IF glob_rec_inparms.ref1_ind = "2" OR glob_rec_inparms.ref1_ind = "4" 
				OR glob_rec_inparms.ref2_ind = "2" OR glob_rec_inparms.ref2_ind = "4" 
				OR glob_rec_inparms.ref3_ind = "2" OR glob_rec_inparms.ref3_ind = "4" 
				OR glob_rec_inparms.ref4_ind = "2" OR glob_rec_inparms.ref4_ind = "4" 
				OR glob_rec_inparms.ref5_ind = "2" OR glob_rec_inparms.ref5_ind = "4" 
				OR glob_rec_inparms.ref6_ind = "2" OR glob_rec_inparms.ref6_ind = "4" 
				OR glob_rec_inparms.ref7_ind = "2" OR glob_rec_inparms.ref7_ind = "4" 
				OR glob_rec_inparms.ref8_ind = "2" OR glob_rec_inparms.ref8_ind = "4" THEN 
					# FIXME: not sure what this means exactly
					--IF NOT input_product_report_codes(l_rec_product.*) THEN 
						--NEXT FIELD part_code 
					--END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	-----------------------------------------------------

	IF p_mode = MODE_CLASSIC_EDIT OR p_mode = MODE_CLASSIC_REMOVE THEN
		CLOSE WINDOW i626
	END IF

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN -1 ,l_rec_product.*
	ELSE 
		CASE 
			WHEN p_mode = MODE_CLASSIC_EDIT
				CALL update_product (p_part_code,l_rec_product.*) RETURNING l_operation_status
			WHEN p_mode = MODE_CLASSIC_ADD
				CALL insert_product(l_rec_product.*) RETURNING l_operation_status
			WHEN p_mode = MODE_CLASSIC_REMOVE
			
		END CASE
		RETURN l_operation_status,l_rec_product.*
	END IF 
END FUNCTION 		# input_product_main_details

FUNCTION input_product_purchase_detail(p_part_code,p_rec_product) 
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE p_part_code LIKE product.part_code
	DEFINE bkp_rec_product RECORD LIKE product.*		# backup of the inbound record, in case of int_flag
	DEFINE l_warehouse RECORD LIKE warehouse.*
	DEFINE l_vendor RECORD LIKE vendor.*
	DEFINE l_date DATE
	DEFINE l_sto_serial_flag LIKE product.serial_flag
	DEFINE l_ser_cnt INTEGER
	DEFINE winds_text CHAR(50) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE l_operation_status INTEGER

	IF glob_rec_company.module_text[5] = "E" THEN 
		OPEN WINDOW i105 with FORM "I105a" 
		 CALL windecoration_i("I105a") 
	ELSE 
		OPEN WINDOW i105 with FORM "I105" 
		 CALL windecoration_i("I105") 
		LET p_rec_product.price_inv_flag = NULL 
		LET p_rec_product.disc_allow_flag = NULL 
		LET p_rec_product.bonus_allow_flag = NULL 
		LET p_rec_product.back_order_flag = NULL 
		LET p_rec_product.trade_in_flag = NULL 
	END IF 
	INITIALIZE l_warehouse.* TO NULL 

	IF p_rec_product.part_code IS NULL THEN
		SELECT * INTO p_rec_product.*
		FROM product
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code
	END IF
	DISPLAY 
	p_rec_product.part_code,
	p_rec_product.desc_text TO 
	product.part_code,
	product.desc_text 

	IF p_rec_product.ware_code IS NOT NULL THEN 
		SELECT * INTO l_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_product.ware_code 
	END IF 
	DISPLAY 
	p_rec_product.pur_uom_code,
	p_rec_product.setup_date, 
	l_warehouse.desc_text TO
	product.pur_uom_code,
	product.setup_date, 
	warehouse.desc_text

	LET msgresp = kandoomsg("I",1021,"") 
	# 1021 Enter purchase AND stocking details - ESC TO Continue
	
	LET bkp_rec_product.* = p_rec_product.*			#backup of original record
	INPUT BY NAME p_rec_product.vend_code, 
		p_rec_product.oem_text, 
		p_rec_product.days_lead_num, 
		p_rec_product.tariff_code, 
		p_rec_product.min_ord_qty, 
		p_rec_product.outer_qty, 
		p_rec_product.outer_sur_per, 
		p_rec_product.bar_code_text, 
		p_rec_product.days_warr_num, 
		p_rec_product.ware_code, 
		p_rec_product.serial_flag, 
		p_rec_product.total_tax_flag, 
		p_rec_product.price_inv_flag, 
		p_rec_product.disc_allow_flag, 
		p_rec_product.bonus_allow_flag, 
		p_rec_product.back_order_flag, 
		p_rec_product.trade_in_flag 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11a","input-pr1_product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (vend_code) 
			LET p_rec_product.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,p_rec_product.vend_code) 
			NEXT FIELD vend_code 

		ON KEY (control-b) infield (ware_code) 
			LET winds_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET p_rec_product.ware_code = winds_text 
			END IF 
			NEXT FIELD ware_code 

		AFTER FIELD vend_code 
			CLEAR name_text 
			IF p_rec_product.vend_code IS NOT NULL THEN 
				SELECT name_text 
				INTO l_vendor.name_text 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = p_rec_product.vend_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("I",9057,"") 
					#9057 " Vendor NOT found - Try Window "
					NEXT FIELD vend_code 
				ELSE 
					DISPLAY BY NAME l_vendor.name_text 

				END IF 
			END IF 
		AFTER FIELD min_ord_qty 
			IF p_rec_product.min_ord_qty IS NULL THEN 
				LET p_rec_product.min_ord_qty = 0 
				NEXT FIELD min_ord_qty 
			END IF 
			IF p_rec_product.min_ord_qty < 0 THEN 
				LET msgresp=kandoomsg("I",9058,"") 
				#9058 "Minimum ORDER quantity must be positive"
				NEXT FIELD min_ord_qty 
			END IF 
		AFTER FIELD days_warr_num 
			IF p_rec_product.days_warr_num IS NULL THEN 
				LET p_rec_product.days_warr_num = 0 
				NEXT FIELD days_warr_num 
			END IF 
			IF p_rec_product.days_warr_num < 0 THEN 
				LET msgresp=kandoomsg("I",9059,"") 
				#9059" Warranty period must be positive"
				NEXT FIELD days_warr_num 
			END IF 
		AFTER FIELD bar_code_text 
			IF p_rec_product.bar_code_text IS NOT NULL THEN 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bar_code_text = p_rec_product.bar_code_text 
				AND part_code != p_rec_product.part_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9235,"") 
					#9235" Bar Code already exists"
					NEXT FIELD bar_code_text 
				END IF 
			END IF 
		AFTER FIELD ware_code 
			IF p_rec_product.ware_code IS NOT NULL THEN 
				SELECT * INTO l_warehouse.* FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = p_rec_product.ware_code 
				IF status = notfound THEN 
					LET msgresp=kandoomsg("U",9105,"") 
					#9105 "Record NOT found - Try Window"
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_warehouse.desc_text TO warehouse.desc_text 

				END IF 
			END IF 

		BEFORE FIELD serial_flag 
			LET l_sto_serial_flag = p_rec_product.serial_flag 

		AFTER FIELD serial_flag 
			IF l_sto_serial_flag <> p_rec_product.serial_flag THEN 
				SELECT count(*) INTO l_ser_cnt FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.part_code 
				AND onhand_qty <> 0 
				IF l_ser_cnt > 0 THEN 
					LET msgresp=kandoomsg("I",9122,"") 
					#9122  Cannot change serialization flag whilst Warehouses
					LET p_rec_product.serial_flag = l_sto_serial_flag 
					DISPLAY BY NAME p_rec_product.serial_flag 

				END IF 
				IF p_rec_product.serial_flag = 'Y' THEN 
					IF p_rec_product.pur_uom_code <> p_rec_product.stock_uom_code 
					OR p_rec_product.pur_uom_code <> p_rec_product.sell_uom_code THEN 
						LET msgresp=kandoomsg("I",9297,"") 
						#9297 All Units of Measure must be the same FOR serial
						LET p_rec_product.serial_flag = l_sto_serial_flag 
						DISPLAY BY NAME p_rec_product.serial_flag 

						NEXT FIELD serial_flag 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF p_rec_product.days_warr_num IS NULL THEN 
					LET p_rec_product.days_warr_num = 0 
				END IF 
				IF p_rec_product.min_ord_qty IS NULL THEN 
					LET p_rec_product.min_ord_qty = 0 
				END IF 
				IF p_rec_product.bar_code_text IS NOT NULL THEN 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bar_code_text = p_rec_product.bar_code_text 
					AND part_code != p_rec_product.part_code 
					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9235,"") 
						#9235" Bar Code already exists"
						NEXT FIELD bar_code_text 
					END IF 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i105 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		return -1,bkp_rec_product.*
	ELSE 
		CALL update_product (p_part_code,p_rec_product.*) RETURNING l_operation_status
		return l_operation_status,p_rec_product.*
	END IF 
END FUNCTION 		# input_product_purchase_detail



################
FUNCTION input_product_report_codes(p_part_code,p_rec_product) 
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE p_part_code LIKE product.part_code
	DEFINE bkp_rec_product RECORD LIKE product.* 		# backup record of inbound record
	DEFINE l_userref RECORD LIKE userref.*
	DEFINE l_valid_flag, seq_num SMALLINT 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE l_operation_status INTEGER
	OPEN WINDOW i611 with FORM "I611" 
	 CALL windecoration_i("I611") 
	LET msgresp = kandoomsg("I",1012,"") 

	IF p_rec_product.part_code IS NULL THEN
		SELECT * 
		INTO p_rec_product.*
		FROM product
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code
	END IF
	DISPLAY BY NAME p_rec_product.part_code,
		p_rec_product.desc_text

	#1012 Enter product reporting code details - ESC TO Continue"
	LET glob_rec_inparms.ref1_text = make_prompt(glob_rec_inparms.ref1_text) 
	LET glob_rec_inparms.ref2_text = make_prompt(glob_rec_inparms.ref2_text) 
	LET glob_rec_inparms.ref3_text = make_prompt(glob_rec_inparms.ref3_text) 
	LET glob_rec_inparms.ref4_text = make_prompt(glob_rec_inparms.ref4_text) 
	LET glob_rec_inparms.ref5_text = make_prompt(glob_rec_inparms.ref5_text) 
	LET glob_rec_inparms.ref6_text = make_prompt(glob_rec_inparms.ref6_text) 
	LET glob_rec_inparms.ref7_text = make_prompt(glob_rec_inparms.ref7_text) 
	LET glob_rec_inparms.ref8_text = make_prompt(glob_rec_inparms.ref8_text) 
	DISPLAY BY NAME glob_rec_inparms.ref1_text, 
		glob_rec_inparms.ref2_text, 
		glob_rec_inparms.ref3_text, 
		glob_rec_inparms.ref4_text, 
		glob_rec_inparms.ref5_text, 
		glob_rec_inparms.ref6_text, 
		glob_rec_inparms.ref7_text, 
		glob_rec_inparms.ref8_text 
	--attribute(white) 

	LET bkp_rec_product.* = p_rec_product.* 	# backup of original record in case on int_flag
	INPUT BY NAME p_rec_product.ref1_code, 
		p_rec_product.ref2_code, 
		p_rec_product.ref3_code, 
		p_rec_product.ref4_code, 
		p_rec_product.ref5_code, 
		p_rec_product.ref6_code, 
		p_rec_product.ref7_code, 
		p_rec_product.ref8_code 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11a","input-pr1_product-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 


		ON ACTION "REFERESH" 
			 CALL windecoration_i("I611") 

		ON KEY (control-b) infield (ref1_code) 
			LET p_rec_product.ref1_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","1") 
			NEXT FIELD ref1_code 
		ON KEY (control-b) infield (ref2_code) 
			LET p_rec_product.ref2_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","2") 
			NEXT FIELD ref2_code 
		ON KEY (control-b) infield (ref3_code) 
			LET p_rec_product.ref3_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","3") 
			NEXT FIELD ref3_code 
		ON KEY (control-b) infield (ref4_code) 
			LET p_rec_product.ref4_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","4") 
			NEXT FIELD ref4_code 
		ON KEY (control-b) infield (ref5_code) 
			LET p_rec_product.ref5_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","5") 
			NEXT FIELD ref5_code 
		ON KEY (control-b) infield (ref6_code) 
			LET p_rec_product.ref6_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","6") 
			NEXT FIELD ref6_code 
		ON KEY (control-b) infield (ref7_code) 
			LET p_rec_product.ref7_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","7") 
			NEXT FIELD ref7_code 
		ON KEY (control-b) infield (ref8_code) 
			LET p_rec_product.ref8_code = show_ref(glob_rec_kandoouser.cmpy_code,"I","8") 
			NEXT FIELD ref8_code 

		BEFORE FIELD ref1_code 
			IF glob_rec_inparms.ref1_text IS NULL THEN 
				LET seq_num = 1 
				NEXT FIELD ref2_code 
			END IF 
		
		AFTER FIELD ref1_code 
			LET seq_num = 1 
			CALL valid_ref("1",glob_rec_inparms.ref1_ind,p_rec_product.ref1_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref1_desc_text 

			ELSE 
				CLEAR ref1_desc_text 
				NEXT FIELD ref1_code 
			END IF 
		BEFORE FIELD ref2_code 
			IF glob_rec_inparms.ref2_text IS NULL THEN 
				IF seq_num > 2 THEN 
					LET seq_num = 2 
					NEXT FIELD ref1_code 
				ELSE 
					LET seq_num = 2 
					NEXT FIELD ref3_code 
				END IF 
			END IF 
		
		AFTER FIELD ref2_code 
			LET seq_num = 2 
			CALL valid_ref("2",glob_rec_inparms.ref2_ind,p_rec_product.ref2_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref2_desc_text 

			ELSE 
				CLEAR ref2_desc_text 
				NEXT FIELD ref2_code 
			END IF 
		
		BEFORE FIELD ref3_code 
			IF glob_rec_inparms.ref3_text IS NULL THEN 
				IF seq_num > 3 THEN 
					LET seq_num = 3 
					NEXT FIELD ref2_code 
				ELSE 
					LET seq_num = 3 
					NEXT FIELD ref4_code 
				END IF 
			END IF 
		
		AFTER FIELD ref3_code 
			LET seq_num = 3 
			CALL valid_ref("3",glob_rec_inparms.ref3_ind,p_rec_product.ref3_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref3_desc_text 

			ELSE 
				CLEAR ref3_desc_text 
				NEXT FIELD ref3_code 
			END IF 
		
		BEFORE FIELD ref4_code 
			IF glob_rec_inparms.ref4_text IS NULL THEN 
				IF seq_num > 4 THEN 
					LET seq_num = 4 
					NEXT FIELD ref3_code 
				ELSE 
					LET seq_num = 4 
					NEXT FIELD ref5_code 
				END IF 
			END IF 
		
		AFTER FIELD ref4_code 
			LET seq_num = 4 
			CALL valid_ref("4",glob_rec_inparms.ref4_ind,p_rec_product.ref4_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref4_desc_text 

			ELSE 
				CLEAR ref4_desc_text 
				NEXT FIELD ref4_code 
			END IF 
		
		BEFORE FIELD ref5_code 
			IF glob_rec_inparms.ref5_text IS NULL THEN 
				IF seq_num > 5 THEN 
					LET seq_num = 5 
					NEXT FIELD ref4_code 
				ELSE 
					LET seq_num = 5 
					NEXT FIELD ref6_code 
				END IF 
			END IF 
		
		AFTER FIELD ref5_code 
			LET seq_num = 5 
			CALL valid_ref("5",glob_rec_inparms.ref5_ind,p_rec_product.ref5_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref5_desc_text 

			ELSE 
				CLEAR ref5_desc_text 
				NEXT FIELD ref5_code 
			END IF 
		
		BEFORE FIELD ref6_code 
			IF glob_rec_inparms.ref6_text IS NULL THEN 
				IF seq_num > 6 THEN 
					LET seq_num = 6 
					NEXT FIELD ref5_code 
				ELSE 
					LET seq_num = 6 
					NEXT FIELD ref7_code 
				END IF 
			END IF 
		
		AFTER FIELD ref6_code 
			LET seq_num = 6 
			CALL valid_ref("6",glob_rec_inparms.ref6_ind,p_rec_product.ref6_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref6_desc_text 

			ELSE 
				CLEAR ref6_desc_text 
				NEXT FIELD ref6_code 
			END IF 
		
		BEFORE FIELD ref7_code 
			IF glob_rec_inparms.ref7_text IS NULL THEN 
				IF seq_num > 7 THEN 
					LET seq_num = 7 
					NEXT FIELD ref6_code 
				ELSE 
					LET seq_num = 7 
					NEXT FIELD ref8_code 
				END IF 
			END IF 
		
		AFTER FIELD ref7_code 
			LET seq_num = 7 
			CALL valid_ref("7",glob_rec_inparms.ref7_ind,p_rec_product.ref7_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref7_desc_text 

			ELSE 
				CLEAR ref7_desc_text 
				NEXT FIELD ref7_code 
			END IF 
		
		BEFORE FIELD ref8_code 
			IF glob_rec_inparms.ref8_text IS NULL THEN 
				LET seq_num = 8 
				EXIT INPUT 
			END IF 
		
		AFTER FIELD ref8_code 
			LET seq_num = 8 
			CALL valid_ref("8",glob_rec_inparms.ref8_ind,p_rec_product.ref8_code) 
			RETURNING l_valid_flag,l_userref.ref_desc_text 
			IF l_valid_flag THEN 
				DISPLAY l_userref.ref_desc_text 
				TO ref8_desc_text 
			ELSE 
				CLEAR ref8_desc_text 
				NEXT FIELD ref8_code 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
			{  All these checks have already been done AFTER FIELD
				CALL valid_ref("1",glob_rec_inparms.ref1_ind,p_rec_product.ref1_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref1_code 
				END IF 
				CALL valid_ref("2",glob_rec_inparms.ref2_ind,p_rec_product.ref2_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref2_code 
				END IF 
				CALL valid_ref("3",glob_rec_inparms.ref3_ind,p_rec_product.ref3_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref3_code 
				END IF 
				CALL valid_ref("4",glob_rec_inparms.ref4_ind,p_rec_product.ref4_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref4_code 
				END IF 
				CALL valid_ref("5",glob_rec_inparms.ref5_ind,p_rec_product.ref5_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref5_code 
				END IF 
				CALL valid_ref("6",glob_rec_inparms.ref6_ind,p_rec_product.ref6_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref6_code 
				END IF 
				CALL valid_ref("7",glob_rec_inparms.ref7_ind,p_rec_product.ref7_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref7_code 
				END IF 
				CALL valid_ref("8",glob_rec_inparms.ref8_ind,p_rec_product.ref8_code) 
				RETURNING l_valid_flag,l_userref.ref_desc_text 
				IF NOT l_valid_flag THEN 
					NEXT FIELD ref8_code 
				END IF
			} 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
		
	END INPUT 

	CLOSE WINDOW i611 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN -1,bkp_rec_product.*
	ELSE 
		CALL update_product (p_part_code,p_rec_product.*) RETURNING l_operation_status
		RETURN l_operation_status,p_rec_product.*
	END IF 
END FUNCTION 		# input_report_codes



FUNCTION input_product_statistic_amts(p_part_code,p_rec_product) 
	DEFINE p_part_code LIKE product.part_code 	
	DEFINE p_rec_product RECORD LIKE product.* 
	DEFINE bkp_rec_product RECORD LIKE product.*	# this record is the backup record in case of int_flag
	DEFINE l_operation_status INTEGER
	LET bkp_rec_product.* = p_rec_product.* 		# backup the original values
	OPEN WINDOW i174 with FORM "I174" 
	 CALL windecoration_i("I174") 
	LET msgresp = kandoomsg("I",1022,"") 

	IF p_rec_product.part_code IS NULL THEN
		SELECT * INTO p_rec_product.*
		FROM product
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code
	END IF

	DISPLAY BY NAME p_rec_product.part_code,
		p_rec_product.desc_text

	#1022 Enter statistical minimum turnover - ESC TO Continue"
	INPUT BY NAME p_rec_product.min_month_amt, 
		p_rec_product.min_quart_amt 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11a","input-p_rec_product-3") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD min_month_amt 
			IF p_rec_product.min_month_amt IS NULL THEN 
				LET msgresp = kandoomsg("I",9102,"") 
				#9102 Minimum amount must be entered
				NEXT FIELD min_month_amt 
			END IF 
			IF p_rec_product.min_month_amt < 0 THEN 
				LET msgresp = kandoomsg("I",9103,"") 
				#9103 Minimum amount may NOT be negative
				NEXT FIELD min_month_amt 
			END IF 

		AFTER FIELD min_quart_amt 
			IF p_rec_product.min_quart_amt IS NULL THEN 
				LET msgresp = kandoomsg("I",9102,"") 
				#9102 Minimum amount must be entered
				NEXT FIELD min_quart_amt 
			END IF 
			IF p_rec_product.min_quart_amt < 0 THEN 
				LET msgresp = kandoomsg("I",9103,"") 
				#9103 Minimum amount may NOT be negative
				NEXT FIELD min_quart_amt 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW i174 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN -1, bkp_rec_product.* 
	ELSE 
		CALL update_product (p_part_code,p_rec_product.*) RETURNING l_operation_status
		RETURN l_operation_status,p_rec_product.*  
	END IF 
END FUNCTION 


FUNCTION input_product_dimensions(p_part_code,p_rec_product) 
	DEFINE 	p_rec_product RECORD LIKE product.*
	DEFINE p_part_code LIKE product.part_code 
	DEFINE 	bkp_rec_product RECORD LIKE product.*		# backup record in case of int_flag	
	DEFINE l_operation_status INTEGER

	OPEN WINDOW i226 with FORM "I226" 
	 CALL windecoration_i("I226") 
	LET msgresp = kandoomsg("I",1121,"") 
	#1022 Enter dimension - ESC TO Continue"

	IF p_rec_product.part_code IS NULL THEN
		SELECT * INTO p_rec_product.*
		FROM product
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code
	END IF

	LET bkp_rec_product.* = p_rec_product.*		# backup the record before modifying values
	DISPLAY BY NAME p_rec_product.part_code,
		p_rec_product.desc_text

	INPUT BY NAME p_rec_product.weight_qty, 
		p_rec_product.cubic_qty, 
		p_rec_product.area_qty, 
		p_rec_product.length_qty, 
		p_rec_product.pack_qty 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11a","input-pr1_product-4") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD weight_qty 
			IF p_rec_product.weight_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9228,"") 
				#9228 Quantity must be entered
				NEXT FIELD weight_qty 
			END IF 
			IF p_rec_product.weight_qty < 0 THEN 
				LET msgresp = kandoomsg("I",9229,"") 
				#9229 Quantity may NOT be negative
				NEXT FIELD weight_qty 
			END IF 

		AFTER FIELD cubic_qty 
			IF p_rec_product.cubic_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9228,"") 
				#9228 Quantity must be entered
				NEXT FIELD cubic_qty 
			END IF 
			IF p_rec_product.cubic_qty < 0 THEN 
				LET msgresp = kandoomsg("I",9229,"") 
				#9229 Quantity may NOT be negative
				NEXT FIELD cubic_qty 
			END IF 

		AFTER FIELD area_qty 
			IF p_rec_product.area_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9228,"") 
				#9228 Quantity must be entered
				NEXT FIELD area_qty 
			END IF 
			IF p_rec_product.area_qty < 0 THEN 
				LET msgresp = kandoomsg("I",9229,"") 
				#9229 Quantity may NOT be negative
				NEXT FIELD area_qty 
			END IF 

		AFTER FIELD length_qty 
			IF p_rec_product.length_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9228,"") 
				#9228 Quantity must be entered
				NEXT FIELD length_qty 
			END IF 
			IF p_rec_product.length_qty < 0 THEN 
				LET msgresp = kandoomsg("I",9229,"") 
				#9229 Quantity may NOT be negative
				NEXT FIELD length_qty 
			END IF 

		AFTER FIELD pack_qty 
			IF p_rec_product.pack_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9228,"") 
				#9228 Quantity must be entered
				NEXT FIELD pack_qty 
			END IF 
			IF p_rec_product.pack_qty < 0 THEN 
				LET msgresp = kandoomsg("I",9229,"") 
				#9229 Quantity may NOT be negative
				NEXT FIELD pack_qty 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW i226 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN -1,bkp_rec_product.*     # -1 means cancelled
	ELSE 
		CALL update_product (p_part_code,p_rec_product.*) RETURNING l_operation_status
		RETURN l_operation_status, p_rec_product.* 
	END IF 
END FUNCTION 

FUNCTION initalize_rec_product(p_mode,p_rec_product)
	DEFINE p_mode CHAR(5)
	DEFINE p_rec_product RECORD LIKE product.*
	IF p_mode = MODE_CLASSIC_ADD THEN 
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
		LET p_rec_product.serial_flag = g_rec_no.english_val 
		LET p_rec_product.total_tax_flag = g_rec_yes.english_val 
		LET p_rec_product.back_order_flag = g_rec_yes.english_val 
		LET p_rec_product.disc_allow_flag = g_rec_yes.english_val 
		LET p_rec_product.bonus_allow_flag = g_rec_yes.english_val 
		LET p_rec_product.trade_in_flag = g_rec_no.english_val 
		LET p_rec_product.price_inv_flag = g_rec_yes.english_val 
		LET p_rec_product.status_ind = "1" 
		LET p_rec_product.status_date = today 
		LET p_rec_product.setup_date = today 
		LET p_rec_product.last_calc_date = today 
	ELSE
	END IF 
	RETURN p_rec_product.*
END FUNCTION	# initalize_rec_product

##########################################################################################
# FUNCTION segment_verify(pr_class_code, pr_part_code)
#
#
##########################################################################################
FUNCTION segment_verify(l_class_code, l_part_code) 
	DEFINE 
	l_rec_product RECORD LIKE product.*, 
	l_rec_class RECORD LIKE class.*, 
	l_class_code LIKE class.class_code, 
	l_desc_text LIKE class.desc_text, 
	l_part_code LIKE product.part_code, 
	l_part_desc LIKE product.desc_text, 
	l_part2_desc LIKE product.desc2_text, 
	l_arr_rec_prod array[2] OF RECORD 
		type CHAR(4), 
		START SMALLINT 
	END RECORD, 
	l_desc CHAR(30), 
	l_rec_prodstructure RECORD LIKE prodstructure.*, 
	l_rec_rec_prodflex RECORD LIKE prodflex.*, 
	l_arr_rec_segment array[99] OF RECORD 
		scroll_flag CHAR(1), 
		start_num LIKE prodstructure.start_num, 
		length LIKE prodstructure.length, 
		desc_text LIKE prodstructure.desc_text, 
		flex_code LIKE prodflex.flex_code 
	END RECORD, 
	l_arr_rec_rec_prodstructure array[99] OF RECORD 
		seq_num LIKE prodstructure.seq_num, 
		type_ind LIKE prodstructure.type_ind, 
		valid_flag LIKE prodstructure.valid_flag 
	END RECORD, 
	l_arr_rec_rec_prodflex array[99] OF RECORD 
		desc_text LIKE prodflex.desc_text 
	END RECORD, 
	l_part_length LIKE prodstructure.length, 
	l_start_num LIKE prodstructure.start_num, 
	l_kandoo_seq_num LIKE prodstructure.seq_num, 
	l_length LIKE prodstructure.length, 
	l_scroll_flag CHAR(1), 
	winds_text CHAR(40), 
	l_min_length, 
	l_first_desc_added, 
	l_second_desc_added, 
	l_counter SMALLINT, 
	l_parent_part_code LIKE product.part_code, 
	l_filler LIKE product.part_code, 
	l_opt_segments LIKE product.part_code, 
	l_char_string CHAR(30), 
	idx,scrn,x,len SMALLINT 

	OPEN WINDOW i625 with FORM "I625" 
	 CALL windecoration_i("I625") 

	LET msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	SELECT * INTO l_rec_class.* FROM class 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = l_class_code 
	DISPLAY BY NAME l_rec_class.class_code 

	DISPLAY l_rec_class.desc_text TO class_desc 

	DECLARE c_prodstructure CURSOR FOR 
	SELECT * FROM prodstructure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = l_class_code 
	ORDER BY seq_num 

	FOR idx = 1 TO 99 
		INITIALIZE l_arr_rec_segment[idx].* TO NULL 
	END FOR 

	LET idx = 0 
	FOREACH c_prodstructure INTO l_rec_prodstructure.* 
		IF l_rec_prodstructure.seq_num = l_rec_class.price_level_ind THEN 
			LET l_min_length = l_rec_prodstructure.start_num 
			+ l_rec_prodstructure.length - 1 
		END IF 
		IF l_rec_prodstructure.type_ind = "S" 
		OR l_rec_prodstructure.type_ind = "H" 
		OR l_rec_prodstructure.type_ind = "V" THEN 
			LET idx = idx + 1 
			LET l_arr_rec_segment[idx].start_num = l_rec_prodstructure.start_num 
			LET l_arr_rec_segment[idx].length = l_rec_prodstructure.length 
			LET l_arr_rec_segment[idx].desc_text = l_rec_prodstructure.desc_text 
			LET l_arr_rec_rec_prodstructure[idx].seq_num = l_rec_prodstructure.seq_num 
			LET l_arr_rec_rec_prodstructure[idx].type_ind = l_rec_prodstructure.type_ind 
			LET l_arr_rec_rec_prodstructure[idx].valid_flag = l_rec_prodstructure.valid_flag 
			IF l_part_code IS NOT NULL THEN 
				LET l_start_num = l_rec_prodstructure.start_num 
				LET l_length = l_rec_prodstructure.length 
				LET l_part_length = length(l_part_code) 
				IF (l_start_num + l_length) > l_part_length THEN 
					IF l_start_num <= l_part_length THEN 
						LET l_arr_rec_segment[idx].flex_code 
						= l_part_code[l_start_num, l_part_length] 
					END IF 
				ELSE 
					LET l_arr_rec_segment[idx].flex_code 
					= l_part_code[l_start_num, l_start_num + l_length - 1] 
				END IF 

				SELECT * INTO l_rec_rec_prodflex.* FROM prodflex 
				WHERE class_code = l_rec_prodstructure.class_code 
				AND start_num = l_rec_prodstructure.start_num 
				AND flex_code = l_arr_rec_segment[idx].flex_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF l_rec_prodstructure.seq_num <= l_rec_class.desc_level_ind THEN 
					LET l_arr_rec_rec_prodflex[idx].desc_text = l_rec_rec_prodflex.desc_text 
				ELSE 
					LET l_arr_rec_rec_prodflex[idx].desc_text = " " 
				END IF 

			ELSE 
				LET l_arr_rec_segment[idx].flex_code = NULL 
			END IF 
		END IF 

	END FOREACH 

	LET l_kandoo_seq_num = idx 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(idx) 
	LET msgresp = kandoomsg("I",1307,"") 

	#1307 Enter Product Flex Details
	INPUT ARRAY l_arr_rec_segment WITHOUT DEFAULTS FROM sr_segment.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11","input-segment") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield(flex_code) 
					LET winds_text = NULL 
					LET winds_text = show_flex_code(glob_rec_kandoouser.cmpy_code, l_rec_class.class_code, 
					l_arr_rec_segment[idx].start_num) 
					IF winds_text IS NOT NULL THEN 
						LET l_arr_rec_segment[idx].flex_code = winds_text 
						DISPLAY l_arr_rec_segment[idx].flex_code 
						TO sr_segment[scrn].flex_code 

					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD flex_code 
			END CASE 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			NEXT FIELD scroll_flag 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_segment[idx].scroll_flag 
			DISPLAY l_arr_rec_segment[idx].* TO sr_segment[scrn].* 

			NEXT FIELD flex_code 
		BEFORE FIELD flex_code 
			DISPLAY l_arr_rec_segment[idx].flex_code TO sr_segment[scrn].flex_code 

		AFTER FIELD flex_code 
			IF l_arr_rec_segment[idx].flex_code IS NOT NULL THEN 
				LET l_arr_rec_segment[idx].scroll_flag = NULL 
				DISPLAY l_arr_rec_segment[idx].scroll_flag 
				TO sr_segment[scrn].scroll_flag 


				LET l_char_string = l_arr_rec_segment[idx].flex_code 
				IF idx = l_kandoo_seq_num THEN # LAST segment can be 1 character 
					IF validate_string(l_char_string, 1, l_arr_rec_segment[idx].length, true) 
					THEN ELSE 
						NEXT FIELD flex_code 
					END IF 
				ELSE 
					IF validate_string(l_char_string, l_arr_rec_segment[idx].length, l_arr_rec_segment[idx].length, true) 
					THEN ELSE 
						NEXT FIELD flex_code 
					END IF 
				END IF 
				#IF length(l_arr_rec_segment[idx].flex_code) <> l_arr_rec_segment[idx].length                    THEN
				#LET msgresp = kandoomsg("I",9160,l_arr_rec_segment[idx].length)
				##9160 Product Flex Code must be ??? chars
				#NEXT FIELD flex_code
				#END IF
				#IF l_arr_rec_rec_prodstructure[idx].valid_flag = "Y" THEN
				SELECT * INTO l_rec_rec_prodflex.* FROM prodflex 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_class_code 
				AND start_num = l_arr_rec_segment[idx].start_num 
				AND flex_code = l_arr_rec_segment[idx].flex_code 
				IF sqlca.sqlcode = notfound THEN 
					IF l_arr_rec_rec_prodstructure[idx].valid_flag = "Y" THEN 
						LET msgresp = kandoomsg("I",9159,"") 
						#9159 Product Flex Code must a valid code
						NEXT FIELD flex_code 
					END IF 
					LET l_rec_rec_prodflex.desc_text = "" 
				END IF 

				IF idx <= l_rec_class.desc_level_ind THEN 
					# IF l_rec_prodstructure.seq_num <= l_rec_class.desc_level_ind THEN
					LET l_arr_rec_rec_prodflex[idx].desc_text = l_rec_rec_prodflex.desc_text 
				ELSE 
					LET l_arr_rec_rec_prodflex[idx].desc_text = " " 
				END IF 
				#END IF
			END IF 

			CASE 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_segment[idx+1].start_num IS NULL THEN 
						NEXT FIELD flex_code 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
			END CASE 

		AFTER ROW 
			DISPLAY l_arr_rec_segment[idx].* TO sr_segment[scrn].* 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_segment[idx].flex_code IS NULL THEN 
						IF l_rec_class.price_level_ind >= l_arr_rec_rec_prodstructure[idx].seq_num 
						THEN 
							LET msgresp = kandoomsg("I",9195,"") 
							#9195 Must enter upto the Order Segment
							NEXT FIELD flex_code 
							EXIT FOR 
						END IF 
					END IF 
				END FOR 

				LET l_part_code = NULL 
				DECLARE c_prodstructure2 CURSOR FOR 
				SELECT * FROM prodstructure 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = l_class_code 
				ORDER BY seq_num 
				OPEN c_prodstructure2 
				FETCH c_prodstructure2 INTO l_rec_prodstructure.* 
				IF status != notfound THEN 
					IF l_rec_prodstructure.type_ind = "F" THEN 
						LET l_length = l_rec_prodstructure.length 
						LET l_part_code = l_rec_prodstructure.desc_text[1] 
						LET l_part_length = l_length 
					ELSE 
						FOR idx = 1 TO 99 
							IF l_rec_prodstructure.seq_num = l_arr_rec_rec_prodstructure[idx].seq_num 
							THEN 
								LET l_part_code = l_arr_rec_segment[idx].flex_code 
								LET l_part_length = l_rec_prodstructure.length 
								EXIT FOR 
							END IF 
						END FOR 
					END IF 

					WHILE true 
						FETCH c_prodstructure2 INTO l_rec_prodstructure.* 
						IF status != notfound THEN 
							IF l_rec_prodstructure.type_ind = "F" THEN 
								LET l_length = l_rec_prodstructure.length 
								LET l_part_code = l_part_code[1,l_part_length], 
								l_rec_prodstructure.desc_text[1] 
								LET l_part_length = l_part_length + l_length 
							ELSE 
								FOR idx = 1 TO 99 
									IF l_rec_prodstructure.seq_num 
									= l_arr_rec_rec_prodstructure[idx].seq_num THEN 
										IF l_arr_rec_segment[idx].flex_code IS NOT NULL THEN 
											LET l_part_code = 
											l_part_code[1,l_part_length], 
											l_arr_rec_segment[idx].flex_code 
											LET l_part_length = l_part_length 
											+ l_arr_rec_segment[idx].length 
											EXIT FOR 
										ELSE 
											EXIT WHILE 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							EXIT WHILE 
						END IF 
					END WHILE 
				END IF 

				CALL break_prod(glob_rec_kandoouser.cmpy_code, l_part_code, l_class_code,1) 
				RETURNING l_parent_part_code, l_filler, l_opt_segments, 
				l_part_length 
				IF l_opt_segments IS NULL 
				OR l_opt_segments = " " THEN 
					LET l_part_code = l_parent_part_code 
				END IF 

				SELECT unique 1 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_part_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9036,"") 
					#9036 "Product Code already exists, please re enter"
					NEXT FIELD flex_code 
				END IF 

				IF l_opt_segments IS NOT NULL 
				AND l_opt_segments != " " THEN 
					SELECT * FROM product 
					WHERE part_code = l_parent_part_code 
					AND class_code = l_class_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp = kandoomsg("I",9196,"") 
						#9196 Parent Product does NOT exist
						NEXT FIELD flex_code 
					END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	--------------------------------------------------------

	LET l_part_desc = NULL 
	LET l_part2_desc = NULL 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_part_code = NULL 
	ELSE 
		LET l_first_desc_added = false 
		LET l_second_desc_added = false 
		FOR idx = 1 TO 99 
			IF l_arr_rec_rec_prodflex[idx].desc_text IS NOT NULL 
			AND l_arr_rec_segment[idx].flex_code IS NOT NULL THEN 
				IF NOT l_first_desc_added THEN 
					LET l_part_desc = l_arr_rec_rec_prodflex[idx].desc_text 
					LET l_first_desc_added = true 
					CONTINUE FOR 
				END IF 
				LET l_length = length(l_arr_rec_rec_prodflex[idx].desc_text) 
				+ length(l_part_desc) 
				# +1 FOR space added
				IF (l_length+1) < 31 THEN 
					LET l_part_desc = l_part_desc clipped, 
					" ", 
					l_arr_rec_rec_prodflex[idx].desc_text 
				ELSE 
					IF NOT l_second_desc_added THEN 
						LET l_part2_desc = l_arr_rec_rec_prodflex[idx].desc_text 
						LET l_second_desc_added = true 
						CONTINUE FOR 
					END IF 
					LET l_part2_desc = l_part2_desc clipped, 
					" ", 
					l_arr_rec_rec_prodflex[idx].desc_text 
				END IF 
			ELSE 
				EXIT FOR 
			END IF 
		END FOR 
	END IF 

	CLOSE WINDOW i625 

	IF l_part_desc IS NULL THEN 
		RETURN l_part_code, "", "" 
	ELSE 
		RETURN l_part_code, l_part_desc, l_part2_desc 
	END IF 

END FUNCTION 	# segment_verify
