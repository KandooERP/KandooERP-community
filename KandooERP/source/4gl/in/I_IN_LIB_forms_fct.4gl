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
FUNCTION input_product_main_details(p_mode,p_rec_product) 		# probability to use the same function for EDIT ...
	DEFINE p_mode CHAR(5)
	DEFINE p_rec_product RECORD LIKE product.*		# Main record for product INPUT
	DEFINE l_rec_category RECORD LIKE category.*
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_rec_proddept RECORD LIKE proddept.*
	DEFINE l_rec_maingrp RECORD LIKE maingrp.*
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.*

	DEFINE l_rec_product RECORD LIKE product.*		# Record for auxiliary product  INPUT
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

	CALL initalize_rec_product(p_mode,p_rec_product.*) RETURNING p_rec_product.*
	
	INPUT p_rec_product.cat_code,  
		p_rec_product.class_code,
		p_rec_product.dept_code, 
		p_rec_product.maingrp_code, 
		p_rec_product.prodgrp_code, 
		p_rec_product.part_code,  
		p_rec_product.desc_text, --this IS the one, which IS ignored... 
		p_rec_product.desc2_text,
		p_rec_product.short_desc_text, 
		p_rec_product.alter_part_code, 
		p_rec_product.super_part_code, 
		p_rec_product.compn_part_code, 
		p_rec_product.pur_uom_code, 
		p_rec_product.stock_uom_code, 
		p_rec_product.sell_uom_code, 
		p_rec_product.price_uom_code, 
		p_rec_product.pur_stk_con_qty, 
		p_rec_product.stk_sel_con_qty, 
		p_rec_product.dg_code, 
		p_rec_product.target_turn_qty, 
		p_rec_product.stock_turn_qty
	 
	WITHOUT DEFAULTS
	FROM product.*	# we use here a specific screen record that avoid listing all the fields in the from clause

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I11","input-p_rec_product") 
			CASE
				# When edit, we do not touch the primary key fields
				WHEN p_mode = "EDIT"
					CALL DIALOG.SetFieldActive("part_code", false)
				WHEN p_mode = "ADD"
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
					LET p_rec_product.prodgrp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
					NEXT FIELD prodgrp_code 
				WHEN infield(cat_code) 
					LET p_rec_product.cat_code = show_pcat(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD cat_code 
				WHEN infield(class_code) 
					LET p_rec_product.class_code = show_pcls(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD class_code 
				WHEN infield(alter_part_code) 
					LET p_rec_product.alter_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD alter_part_code 
				WHEN infield(super_part_code) 
					LET p_rec_product.super_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD super_part_code 
				WHEN infield(compn_part_code) 
					LET p_rec_product.compn_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD compn_part_code 
				WHEN infield(sell_uom_code) 
					LET p_rec_product.sell_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD sell_uom_code 
				WHEN infield(price_uom_code) 
					LET p_rec_product.price_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD price_uom_code 
				WHEN infield(pur_uom_code) 
					LET p_rec_product.pur_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD pur_uom_code 
				WHEN infield(stock_uom_code) 
					LET p_rec_product.stock_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
					NEXT FIELD stock_uom_code 
				WHEN infield(dg_code) 
					LET l_temp_text = show_proddanger(glob_rec_kandoouser.cmpy_code,"") 
					IF l_temp_text IS NOT NULL THEN 
						LET p_rec_product.dg_code = l_temp_text 
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
			IF p_rec_product.cat_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9038,"") 
				#9038 "product category Code must be entered"
				NEXT FIELD cat_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_category.desc_text 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_product.cat_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				ELSE 
					DISPLAY l_rec_category.desc_text TO category.desc_text 

				END IF 
			END IF 

		AFTER FIELD class_code 
			IF p_rec_product.class_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9040,"") 
				#9040 "Product Class code must be Entered"
				NEXT FIELD class_code 
			ELSE 
				SELECT desc_text INTO l_rec_class.desc_text 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = p_rec_product.class_code 
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
			IF p_rec_product.dept_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD dept_code 
			ELSE 
				SELECT desc_text, dept_code 
				INTO l_rec_proddept.desc_text, p_rec_product.dept_code 
				FROM proddept 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dept_code = p_rec_product.dept_code 
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
			CALL dyn_combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,p_rec_product.dept_code) 

			--IF l_opt_segment IS NOT NULL 
			--AND l_opt_segment != " " THEN 
				--IF l_direction_ind = "U" THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			--END IF 

		AFTER FIELD maingrp_code 
			IF p_rec_product.maingrp_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD maingrp_code 
			ELSE 
				SELECT desc_text, maingrp_code 
				INTO l_rec_maingrp.desc_text, p_rec_product.maingrp_code 
				FROM maingrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND maingrp_code = p_rec_product.maingrp_code 
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
			("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,p_rec_product.dept_code,p_rec_product.maingrp_code) 
			IF l_opt_segment IS NOT NULL 
			AND l_opt_segment != " " THEN 
				IF l_direction_ind = "U" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD prodgrp_code 
			IF p_rec_product.prodgrp_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD prodgrp_code 
			ELSE 
				SELECT desc_text, prodgrp_code 
				INTO l_rec_prodgrp.desc_text, p_rec_product.prodgrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_product.prodgrp_code 
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
			("part_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,p_rec_product.dept_code,p_rec_product.maingrp_code,p_rec_product.prodgrp_code) 
			
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" AND mult_segs(glob_rec_kandoouser.cmpy_code, p_rec_product.class_code) THEN 
				CALL segment_verify(p_rec_product.class_code, p_rec_product.part_code) 
				RETURNING p_rec_product.part_code, l_part_text, l_part2_text 
				IF p_rec_product.part_code IS NULL THEN 
					NEXT FIELD class_code 
				ELSE 
					LET l_temp_part_code = p_rec_product.part_code 
					LET p_rec_product.desc_text = NULL 
					LET p_rec_product.desc2_text = NULL 
					DISPLAY BY NAME p_rec_product.part_code 

					# TODO : see if we cannot make a lib function out of this section
					SELECT 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_product.part_code 

					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					ELSE 
						CALL break_prod(glob_rec_kandoouser.cmpy_code, p_rec_product.part_code,	p_rec_product.class_code,1) 
						RETURNING l_parent_part_code, l_filler, l_opt_segment, l_part_length 
						IF l_opt_segment IS NOT NULL AND l_opt_segment != " " THEN 
							SELECT * INTO l_rec_product.* 
							FROM product 
							WHERE part_code = l_parent_part_code 
								AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET p_rec_product.* = l_rec_product.* 
							LET p_rec_product.part_code = l_parent_part_code clipped,l_filler clipped, l_opt_segment clipped 
							LET p_rec_product.desc_text = l_part_text 
							LET p_rec_product.desc2_text = l_part2_text 
							LET p_rec_product.part_code = l_temp_part_code 
						END IF 

						IF p_rec_product.desc_text IS NULL AND p_rec_product.desc2_text IS NULL THEN 
							LET p_rec_product.desc_text = l_part_text 
							LET p_rec_product.desc2_text = l_part2_text 
							LET p_rec_product.short_desc_text = p_rec_product.part_code 
						END IF 

						#IF p_rec_product.short_desc_text IS NULL THEN
						#LET p_rec_product.short_desc_text = p_rec_product.part_code
						#END IF
						IF p_rec_product.oem_text IS NULL THEN 
							LET p_rec_product.oem_text = p_rec_product.part_code 
						END IF 

						DISPLAY BY NAME 
							p_rec_product.cat_code, 
							p_rec_product.class_code, 
							p_rec_product.dept_code,
							p_rec_product.maingrp_code,  
							p_rec_product.prodgrp_code,
							p_rec_product.short_desc_text, 
							p_rec_product.desc_text, 
							p_rec_product.desc2_text, 
							p_rec_product.alter_part_code, 
							p_rec_product.super_part_code, 
							p_rec_product.compn_part_code, 
							p_rec_product.pur_uom_code, 
							p_rec_product.stock_uom_code, 
							p_rec_product.sell_uom_code, 
							p_rec_product.price_uom_code, 
							p_rec_product.pur_stk_con_qty, 
							p_rec_product.stk_sel_con_qty, 
							p_rec_product.dg_code, 
							p_rec_product.stock_turn_qty, 
							p_rec_product.target_turn_qty 

						SELECT desc_text INTO l_rec_proddept.desc_text 
						FROM proddept 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND proddept_code = p_rec_product.proddept_code 
						DISPLAY l_rec_proddept.desc_text TO maingrp.desc_text 

						SELECT desc_text INTO l_rec_maingrp.desc_text 
						FROM maingrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND maingrp_code = p_rec_product.maingrp_code 
						DISPLAY l_rec_maingrp.desc_text TO maingrp.desc_text 

						SELECT desc_text INTO l_rec_prodgrp.desc_text 
						FROM prodgrp 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND prodgrp_code = p_rec_product.prodgrp_code 
						DISPLAY l_rec_prodgrp.desc_text TO prodgrp.desc_text 

						SELECT desc_text INTO l_rec_category.desc_text 
						FROM category 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND cat_code = p_rec_product.cat_code 
						DISPLAY l_rec_category.desc_text TO category.desc_text 

						SELECT * INTO l_rec_proddanger.* 
						FROM proddanger 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND dg_code = p_rec_product.dg_code 
						DISPLAY l_rec_proddanger.tech_text TO proddanger.tech_text 
					END IF 
					--NEXT FIELD short_desc_text 
				END IF 
			ELSE 
				#LET p_rec_product.desc_text = " "
				#LET p_rec_product.desc2_text = " "
				#LET p_rec_product.short_desc_text = " "
				DISPLAY BY NAME p_rec_product.desc_text,p_rec_product.short_desc_text 
			END IF 

		AFTER FIELD part_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				IF NOT mult_segs(glob_rec_kandoouser.cmpy_code, p_rec_product.class_code) THEN 
					SELECT sum(prodstructure.length) INTO l_rec_class_len 
					FROM prodstructure 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = p_rec_product.class_code 
					IF l_rec_class_len IS NULL THEN 
						LET l_rec_class_len = 15 
					END IF 
					LET l_char_string = p_rec_product.part_code 
					IF validate_string(l_char_string,1,l_rec_class_len,true) 
					THEN ELSE 
						NEXT FIELD part_code 
					END IF 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_rec_product.part_code 
					IF status = 0 THEN 
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					END IF 
					SELECT unique 1 FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = p_rec_product.part_code 
					IF status = 0 THEN 
						LET msgresp = kandoomsg("I",9552,"") 
						#9552 "Code already used by alternate/companion group.
						NEXT FIELD part_code 
					END IF 
				END IF 
			ELSE 
				LET l_char_string = p_rec_product.part_code 
				IF validate_string(l_char_string,1,15,true) 
				THEN ELSE 
					NEXT FIELD part_code 
				END IF 
				
				# Check duplicate primary key if ADD
				IF p_mode = "ADD" THEN
					IF check_prykey_exists_product(glob_rec_kandoouser.cmpy_code,p_rec_product.part_code) = true THEN
						LET msgresp=kandoomsg("I",9036,"") 
						#9036 "Product Code already exists, please re enter"
						NEXT FIELD part_code 
					END IF 
				END IF
			END IF 

		AFTER FIELD short_desc_text 
			IF p_rec_product.short_desc_text IS NULL THEN 
				LET msgresp=kandoomsg("I",9503,"") 
				#9503 " Product short description must be entered"
				NEXT FIELD short_desc_text 
			END IF 

		AFTER FIELD product.desc_text 
			IF p_rec_product.desc_text IS NULL THEN 
				LET msgresp=kandoomsg("I",9037,"") 
				#9037 " Product description must be entered"
				NEXT FIELD desc_text 
			END IF 

		--AFTER FIELD desc2_text 
			--LET l_direction_ind = "D" 

		--BEFORE FIELD alter_part_code 
			--LET l_direction_ind = "U" 

		AFTER FIELD alter_part_code 
			IF p_rec_product.alter_part_code IS NOT NULL THEN 
				IF p_rec_product.alter_part_code = p_rec_product.part_code THEN 
					LET msgresp=kandoomsg("I",9042,"") 
					#9042 "Product can NOT be an alternate TO itself"
					NEXT FIELD alter_part_code 
				END IF 
				SELECT desc_text 
				INTO l_alter_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.alter_part_code 
				IF sqlca.sqlcode = notfound THEN 
					SELECT desc_text 
					INTO l_alter_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = p_rec_product.alter_part_code 
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
			IF p_rec_product.super_part_code IS NOT NULL THEN 
				IF p_rec_product.part_code = p_rec_product.super_part_code THEN 
					LET msgresp=kandoomsg("I",9044,"") 
					#9044" Product cannot be superceded by itself "
					NEXT FIELD super_part_code 
				END IF 
				SELECT desc_text 
				INTO l_super_text 
				FROM product 
				WHERE part_code = p_rec_product.super_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010"Product Code NOT found - Try Window "
					NEXT FIELD super_part_code 
				END IF 
				DISPLAY BY NAME l_super_text 

			END IF 

		AFTER FIELD compn_part_code 
			CLEAR l_compn_text 
			IF p_rec_product.compn_part_code IS NOT NULL THEN 
				IF p_rec_product.part_code = p_rec_product.compn_part_code THEN 
					LET msgresp=kandoomsg("I",9047,"") 
					#9047 " Product cannot be a companion of itself "
					NEXT FIELD compn_part_code 
				END IF 
				SELECT desc_text 
				INTO l_compn_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.compn_part_code 
				IF sqlca.sqlcode = notfound THEN 
					SELECT desc_text 
					INTO l_compn_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = p_rec_product.compn_part_code 
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
			IF p_rec_product.pur_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9049,"") 
				#9049" Purchasing Unit Of Measure must be entered "
				NEXT FIELD pur_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.pur_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9050,"") 
					#9050" Purchasing Unit Of Measure NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				ELSE 
					IF p_rec_product.stock_uom_code IS NULL THEN 
						LET p_rec_product.stock_uom_code = p_rec_product.pur_uom_code 
					END IF 
				END IF 
			END IF 
			IF p_rec_product.pur_uom_code = p_rec_product.stock_uom_code THEN 
				LET p_rec_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME p_rec_product.pur_stk_con_qty 

			END IF 

		AFTER FIELD stock_uom_code 
			IF p_rec_product.stock_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9051,"") 
				#9051 "Stocking UOM must be entered"
				NEXT FIELD stock_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.stock_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				ELSE 
					IF p_rec_product.sell_uom_code IS NULL THEN 
						LET p_rec_product.sell_uom_code = p_rec_product.stock_uom_code 
					END IF 
				END IF 
			END IF 

			IF p_rec_product.pur_uom_code = p_rec_product.stock_uom_code THEN 
				LET p_rec_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME p_rec_product.pur_stk_con_qty 

			END IF 

			IF p_rec_product.stock_uom_code = p_rec_product.sell_uom_code THEN 
				LET p_rec_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME p_rec_product.stk_sel_con_qty 

			END IF 

		AFTER FIELD sell_uom_code 
			IF p_rec_product.sell_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9053,"") 
				#9053 "Selling Unit Of Measure must be entered"
				NEXT FIELD sell_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.sell_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				ELSE 
					IF p_rec_product.price_uom_code IS NULL THEN 
						LET p_rec_product.price_uom_code = p_rec_product.sell_uom_code 
					END IF 
				END IF 
			END IF 
			IF p_rec_product.stock_uom_code = p_rec_product.sell_uom_code THEN 
				LET p_rec_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME p_rec_product.stk_sel_con_qty 

			END IF 

		BEFORE FIELD price_uom_code 
			IF glob_rec_company.module_text[23] != "W" THEN 
				LET p_rec_product.price_uom_code = p_rec_product.sell_uom_code 
				DISPLAY BY NAME p_rec_product.price_uom_code 

				## Watch OUT!
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD price_uom_code 
			IF p_rec_product.price_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9215,"") 
				#9215 "Pricing Unit Of Measure must be entered"
				NEXT FIELD price_uom_code 
			ELSE 
				SELECT 1 
				FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.price_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9216,"") 
					#9216" UOM NOT found - Try Window"
					NEXT FIELD price_uom_code 
				END IF 
			END IF 

		BEFORE FIELD pur_stk_con_qty 
			IF p_rec_product.pur_uom_code = p_rec_product.stock_uom_code THEN 
				LET p_rec_product.pur_stk_con_qty = 1 
				## Watch OUT!
				--IF fgl_lastkey() = fgl_keyval("up") 
				--OR fgl_lastkey() = fgl_keyval("left") THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			END IF 

		AFTER FIELD pur_stk_con_qty 
			IF p_rec_product.pur_stk_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9055,"") 
				#9055 "Must enter Purchasing TO Stock Conversion Rate"
				NEXT FIELD pur_stk_con_qty 
			END IF 
			IF p_rec_product.pur_stk_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD pur_stk_con_qty 
			ELSE 
				IF p_rec_product.pur_stk_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7012,"") 
					#7012 "WARNING - the stocking unit IS larger than the buying .."
				END IF 
			END IF 

		BEFORE FIELD stk_sel_con_qty 
			IF p_rec_product.stock_uom_code = p_rec_product.sell_uom_code THEN 
				LET p_rec_product.stk_sel_con_qty = 1 
				## Watch OUT!
				--IF fgl_lastkey() = fgl_keyval("up") 
				--OR fgl_lastkey() = fgl_keyval("left") THEN 
					--NEXT FIELD previous 
				--ELSE 
					--NEXT FIELD NEXT 
				--END IF 
			END IF 

		AFTER FIELD stk_sel_con_qty 
			IF p_rec_product.stk_sel_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9056,"") 
				#9056" Must enter Stocking TO Sales Conversion rate "
				NEXT FIELD stk_sel_con_qty 
			END IF 
			IF p_rec_product.stk_sel_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD stk_sel_con_qty 
			ELSE 
				IF p_rec_product.stk_sel_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7013,"") 
					#7013 "WARNING - the stocking unit IS smaller than the selling.."
				END IF 
			END IF 

		AFTER FIELD dg_code 
			IF p_rec_product.dg_code IS NOT NULL THEN 
				SELECT * INTO l_rec_proddanger.* 
				FROM proddanger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dg_code = p_rec_product.dg_code 
				IF sqlca.sqlcode = notfound THEN 
					#9246 "Dangerous goods code does NOT EXIT - try window"
					LET msgresp=kandoomsg("I",9246,"") 
					NEXT FIELD dg_code 
				ELSE 
					DISPLAY l_rec_proddanger.tech_text 
					TO proddanger.tech_text 

				END IF 
			END IF 

		ON ACTION ("ImageProduct") infield (class_code)
			CALL image_product(p_rec_product.part_code) 
			RETURNING l_operation_status,p_rec_product.*
			IF l_operation_status THEN
				DISPLAY BY NAME p_rec_product.short_desc_text, 
				p_rec_product.desc_text, 
				p_rec_product.desc2_text, 
				p_rec_product.prodgrp_code, 
				p_rec_product.cat_code, 
				p_rec_product.class_code, 
				p_rec_product.alter_part_code, 
				p_rec_product.super_part_code, 
				p_rec_product.compn_part_code, 
				p_rec_product.pur_uom_code, 
				p_rec_product.stock_uom_code, 
				p_rec_product.sell_uom_code, 
				p_rec_product.price_uom_code, 
				p_rec_product.pur_stk_con_qty, 
				p_rec_product.stk_sel_con_qty, 
				p_rec_product.dg_code, 
				p_rec_product.stock_turn_qty, 
				p_rec_product.target_turn_qty 

				SELECT desc_text INTO l_rec_prodgrp.desc_text 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_product.prodgrp_code 
				
				SELECT desc_text INTO l_rec_category.desc_text 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_product.cat_code 
				
				SELECT desc_text INTO l_rec_class.desc_text 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = p_rec_product.class_code 
				
				SELECT desc_text INTO l_alter_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.alter_part_code 
				
				SELECT desc_text INTO l_compn_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.compn_part_code 
				
				SELECT desc_text INTO l_super_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.super_part_code 
				
				SELECT * INTO l_rec_proddanger.* 
				FROM proddanger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dg_code = p_rec_product.dg_code 
				
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
				IF p_rec_product.part_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9013,"") 
					#9013 Product Code must be Entered"
					NEXT FIELD part_code 
				END IF 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
					IF NOT mult_segs(glob_rec_kandoouser.cmpy_code, p_rec_product.class_code) THEN 
						SELECT sum(prodstructure.length) INTO l_rec_class_len 
						FROM prodstructure 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND class_code = p_rec_product.class_code 
						IF l_rec_class_len IS NULL THEN 
							LET l_rec_class_len = 15 
						END IF 
						LET l_char_string = p_rec_product.part_code 
						IF NOT validate_string(l_char_string,1,l_rec_class_len,true) 
						THEN 
							NEXT FIELD part_code 
						END IF 
					END IF 
				END IF 
				SELECT unique 1 FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_product.part_code 

				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9036,"") 
					#9036 "Product Code already exists, please re enter"
					NEXT FIELD part_code 
				END IF 

				IF p_rec_product.part_code = p_rec_product.alter_part_code THEN 
					LET msgresp=kandoomsg("I",9042,"") 
					#9042 Product cannot be an alternative of itself "
					CLEAR l_alter_text 
					NEXT FIELD alter_part_code 
				END IF 

				IF p_rec_product.part_code = p_rec_product.compn_part_code THEN 
					LET msgresp=kandoomsg("I",9047,"") 
					#9047" Product cannot be a companion of itself "
					NEXT FIELD compn_part_code 
				END IF 

				SELECT unique 1 FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_product.cat_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				END IF 
				SELECT maingrp_code 
				INTO p_rec_product.maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_product.prodgrp_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				END IF 
				SELECT unique 1 FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = p_rec_product.class_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				END IF 
				IF p_rec_product.short_desc_text IS NULL THEN 
					#9503 "Must enter description product description"
					LET msgresp=kandoomsg("I",9503,"") 
					NEXT FIELD short_desc_text 
				END IF 
				IF p_rec_product.desc_text IS NULL THEN 
					LET msgresp=kandoomsg("I",9037,"") 
					#9037 "Must enter description product description"
					NEXT FIELD desc_text 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.pur_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9050,"") 
					#9050 " Purchasing UOM NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.stock_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" Stocking UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_product.sell_uom_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" Selling UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				END IF 
				IF p_rec_product.price_uom_code IS NULL THEN 
					LET msgresp=kandoomsg("I",9215,"") 
					#9215 "Pricing Unit Of Measure must be entered"
					NEXT FIELD price_uom_code 
				ELSE 
					SELECT unique 1 FROM uom 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND uom_code = p_rec_product.price_uom_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp=kandoomsg("I",9216,"") 
						#9216" UOM NOT found - Try Window"
						NEXT FIELD price_uom_code 
					END IF 
				END IF 
				IF p_rec_product.pur_uom_code = p_rec_product.sell_uom_code 
				AND p_rec_product.pur_uom_code <> p_rec_product.stock_uom_code THEN 
					LET msgresp=kandoomsg("I",9298,"") 
					#9298 WHEN Purchase UOM = Sell UOM THEN Stock Uom needs t
					NEXT FIELD stock_uom_code 
				END IF 
				IF p_rec_product.serial_flag = 'Y' THEN 
					IF p_rec_product.pur_uom_code <> p_rec_product.stock_uom_code 
					OR p_rec_product.pur_uom_code <> p_rec_product.sell_uom_code THEN 
						LET msgresp=kandoomsg("I",9297,"") 
						#9297 All Units of Measure must be the same FOR serial
						NEXT FIELD pur_uom_code 
					END IF 
				END IF 
				IF p_rec_product.pur_stk_con_qty IS NULL THEN 
					LET msgresp=kandoomsg("I",9055,"") 
					#9055 "Must enter Purchasing TO Stock Conversion Rate"
					NEXT FIELD pur_stk_con_qty 
				END IF 
				IF p_rec_product.pur_stk_con_qty = 0 THEN 
					#9502 "Conversion rate cannot be zero"
					LET msgresp=kandoomsg("I",9502,"") 
					NEXT FIELD pur_stk_con_qty 
				ELSE 
					IF p_rec_product.pur_stk_con_qty < 1 THEN 
						LET msgresp=kandoomsg("I",7012,"") 
						#7012 "WARNING - the stocking unit IS larger than the buying"
					END IF 
				END IF 
				IF p_rec_product.stk_sel_con_qty IS NULL THEN 
					LET msgresp=kandoomsg("I",9056,"") 
					#9056" Must enter Stocking TO Sales Conversion rate "
					NEXT FIELD stk_sel_con_qty 
				END IF 
				IF p_rec_product.stk_sel_con_qty = 0 THEN 
					#9502 "Conversion rate cannot be zero"
					LET msgresp=kandoomsg("I",9502,"") 
					NEXT FIELD stk_sel_con_qty 
				ELSE 
					IF p_rec_product.stk_sel_con_qty < 1 THEN 
						LET msgresp=kandoomsg("I",7013,"") 
						#7013 "WARNING - the stocking unit IS smaller than the sell"
					END IF 
				END IF 
				IF p_rec_product.dg_code IS NOT NULL THEN 
					SELECT unique 1 FROM proddanger 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dg_code = p_rec_product.dg_code 
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
					IF NOT input_product_report_codes(p_rec_product.*) THEN 
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 
	-----------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false ,p_rec_product.*
	ELSE 
		RETURN true,p_rec_product.*
	END IF 
END FUNCTION 		# input_product_main_details

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
