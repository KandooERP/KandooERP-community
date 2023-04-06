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

	Source code beautified by beautify.pl on 2020-01-03 09:12:21	$Id: $
}



#         This program allows the user TO view product records
#              AND change non crucial information
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
--GLOBALS "I15_GLOBALS.4gl" 
DEFINE modu_rec_company RECORD LIKE company.*
DEFINE modu_rec_inparms RECORD LIKE inparms.*
DEFINE crs_product_from_class CURSOR
DEFINE crs_prodstatus_from_parent CURSOR
DEFINE t_rec_product_tree TYPE AS DYNAMIC ARRAY OF RECORD # t_rec_product_tree
	name NCHAR(80),
	id LIKE product.part_code,
	parentid LIKE product.part_code
END RECORD
DEFINE t_element_type TYPE AS DYNAMIC ARRAY OF CHAR(1) # type of array element (Dept,Main group, group, product) 


############################################################
# MODULE Scope Variables
############################################################
DEFINE t_arr_rec_product_scan TYPE AS RECORD
	cat_code LIKE product.cat_code,
	class_code LIKE product.class_code,
	dept_code LIKE product.dept_code,
	maingrp_code LIKE product.maingrp_code,
	prodgrp_code LIKE product.prodgrp_code,
	part_code LIKE product.part_code,
	desc_text LIKE product.desc_text,
	short_desc_text LIKE product.short_desc_text,
	status_date LIKE product.status_date,
	status_ind LIKE product.status_ind 
END RECORD

DEFINE t_rec_product_prykey TYPE AS RECORD
	cmpy_code LIKE product.cmpy_code,
	part_code LIKE product.part_code
END RECORD

DEFINE t_arr_action TYPE AS RECORD 
	action CHAR(3)
END RECORD

{
DEFINE modu_arr_rec_product DYNAMIC ARRAY OF RECORD 
	scroll_flag CHAR(1), 
	part_code LIKE product.part_code, 
	desc_text LIKE product.desc_text, 
	short_desc_text LIKE product.short_desc_text, 
	status_date LIKE product.status_date, 
	status_ind LIKE product.status_ind 
END RECORD 
}

############################################################
# MAIN
#
#
############################################################
FUNCTION I15_main()
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_arr_rec_product_scan
	DEFINE l_arr_rec_product_prykey DYNAMIC ARRAY OF t_rec_product_prykey
	DEFINE l_arr_rec_product_action DYNAMIC ARRAY OF t_arr_action
	DEFINE l_arr_rec_product_tree t_rec_product_tree
	DEFINE l_arr_rec_element_type t_element_type
	

{
	SELECT company.* 
	INTO modu_rec_company.* 
	FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET msgresp=kandoomsg("I",5003,"") 
	END IF 
}
	SELECT inparms.* 
	INTO modu_rec_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 

	IF sqlca.sqlcode = notfound THEN 
		--LET msgresp = kandoomsg("I",5002,"") 
		CALL fgl_winmessage("Inventory Parameters missing",kandoomsg2("I",5002,""),"ERROR") 
		#5002 In Parameters NOT SET up - Refer Menu IZP
		-- EXIT program   FIXME: this line must be enable after inparams are set 
	END IF 

	OPEN WINDOW i612 with FORM "I612" 
	 CALL windecoration_i("I612") 
	 CALL windecoration_i("I626") 	# populate combos ONCE
	MENU "products Management"
		COMMAND "Select Products"
			CALL construct_dataset_product_product() RETURNING l_arr_rec_product,l_arr_rec_product_prykey,l_arr_rec_product_action
			CALL scan_dataset_pick_action_product(l_arr_rec_product,l_arr_rec_product_prykey,l_arr_rec_product_action) 
		COMMAND "Select by Tree"
			CALL db_product_get_arr_tree () RETURNING l_arr_rec_product_tree,l_arr_rec_element_type
			CALL scan_tree_pick_action_product(l_arr_rec_product_tree,l_arr_rec_element_type)
		COMMAND "Exit"
			EXIT MENU
	END MENU
	--WHILE select_product() 
	--	CALL scan_product() 
	--END WHILE 

	CLOSE WINDOW i612 
END FUNCTION #  I15_main

FUNCTION construct_dataset_product_product() 
	DEFINE query_text STRING
	DEFINE where_text STRING 
	DEFINE idx smallint
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_arr_rec_product_scan
	DEFINE l_arr_rec_product_prykey DYNAMIC ARRAY OF t_rec_product_prykey
	DEFINE l_arr_rec_product_action DYNAMIC ARRAY OF t_arr_action
	DEFINE crs_construct_product CURSOR
	DEFINE l_qry_criteria_cat_code LIKE product.cat_code
	DEFINE l_qry_criteria_class_code LIKE product.class_code
	DEFINE l_qry_criteria_dept_code LIKE product.dept_code
	DEFINE l_qry_criteria_maingrp_code LIKE product.maingrp_code
	DEFINE l_qry_criteria_prodgrp_code LIKE product.prodgrp_code
	DEFINE crs_construct_product_scan CURSOR
	CALL l_arr_rec_product.Clear()
	CLEAR FORM

		# Running I16 from the kandoo menu
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME where_text ON product.cat_code,
		product.class_code,
		product.dept_code,
		product.maingrp_code,
		product.prodgrp_code, 
		product.part_code, 
		product.desc_text
	
		ON CHANGE dept_code
			# save the value of dept_code for next combobox
			LET l_qry_criteria_dept_code = GET_FLDBUF(product.dept_code) clipped

		BEFORE FIELD maingrp_code
			# because maingrp_code depends on dept_code, the combo is filled with a filter on dept_code 
			CALL dyn_combolist_maingrp ("maingrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_qry_criteria_dept_code) 

		ON CHANGE maingrp_code
			# save the value of dept_code for next combobox
			LET l_qry_criteria_maingrp_code = GET_FLDBUF(maingrp_code) clipped

		BEFORE FIELD prodgrp_code
			# same principle as for maingrp_code
			CALL dyn_combolist_prodgrp 
			("prodgrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT,l_qry_criteria_dept_code,l_qry_criteria_maingrp_code) 

		ON CHANGE prodgrp_code
			LET l_qry_criteria_prodgrp_code = GET_FLDBUF(prodgrp_code) clipped
			
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I16","construct-prodstatus-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 
 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.

	# pre-build both queries with a different query_text, so that they can be UNIONED in 3rd case
	# First, select products that are assigned to a warehouse
	LET query_text = 
	"SELECT product.cat_code,",
	"product.class_code,", 
	" product.dept_code,",
	"product.maingrp_code, ",
	"product.prodgrp_code, ",
	"product.part_code, ",
	"product.desc_text, ",
	"product.short_desc_text,",
	"product.status_date, ",
	"product.status_ind, ",
	"product.cmpy_code,",
	"product.part_code,",
	"'='",
	" FROM product ", 
	"WHERE product.cmpy_code = ? ",
	"AND ",where_text clipped,
	" ORDER BY product.dept_code,product.maingrp_code,product.prodgrp_code,product.part_code"

	CALL crs_construct_product.Declare(query_text)
	CALL crs_construct_product.Open(glob_rec_kandoouser.cmpy_code)
	LET idx = 1
	WHILE crs_construct_product.FetchNext(l_arr_rec_product[idx].*,l_arr_rec_product_prykey[idx].*,l_arr_rec_product_action[idx].*) = 0
		LET idx = idx + 1
	END WHILE
	# Delete the last empty element of l_arr_rec_product
	CALL l_arr_rec_product.DeleteElement(idx)
	CALL l_arr_rec_product_prykey.DeleteElement(idx)
	CALL l_arr_rec_product_action.DeleteElement(idx)
	RETURN l_arr_rec_product,l_arr_rec_product_prykey,l_arr_rec_product_action
END FUNCTION 		# construct_dataset_product_product




############################################################
# FUNCTION scan_dataset_pick_action_product()
#
#
############################################################
FUNCTION scan_dataset_pick_action_product(p_arr_rec_product,p_arr_rec_product_prykey,p_arr_rec_product_action) 
	DEFINE p_arr_rec_product DYNAMIC ARRAY OF t_arr_rec_product_scan
	DEFINE p_arr_rec_product_prykey DYNAMIC ARRAY OF t_rec_product_prykey
	DEFINE p_arr_rec_product_action DYNAMIC ARRAY OF t_arr_action

	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_match_part LIKE product.part_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_back_msg SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_arr_curr SMALLINT
	DEFINE l_idx SMALLINT 
	DEFINE l_operation_status INTEGER
	DEFINE l_parent LIKE product.part_code 
	DEFINE l_filler LIKE product.part_code 
	DEFINE l_flex_part LIKE product.part_code 
	DEFINE l_flex_num INTEGER 
	DEFINE l_run_arg STRING
	DEFINE l_run_arg1 STRING
	DEFINE l_run_arg2 STRING
	
	LET msgresp=kandoomsg("U",9113,l_idx) 
	#9113 "l_idx records selected"
	LET msgresp=kandoomsg("I",1013,"") 
	#1013 " RETURN TO Edit - F6 TO Make Available - F7 TO Hold - F2 TO Delete"
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	#   CALL set_count(l_idx)
	--	INPUT ARRAY p_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTES(auto append = false, append row = false, delete row = false)
	DISPLAY ARRAY p_arr_rec_product TO sr_product.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I15","input-p_arr_rec_product-1") -- albo kd-505 
			IF l_idx = 0 THEN 
				LET p_arr_rec_product[1].status_date = NULL 
			END IF 
			CALL dialog.setActionHidden("EDIT",NOT p_arr_rec_product.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT p_arr_rec_product.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_arr_curr = arr_curr() 

		ON ACTION "MAKE AVAILABLE"
			CALL change_product_status("1",p_arr_rec_product_prykey[l_arr_curr].part_code,l_arr_curr) 

		ON ACTION "ON HOLD"
			CALL change_product_status("2",p_arr_rec_product_prykey[l_arr_curr].part_code,l_arr_curr) 

		ON ACTION "DELETE"
			CALL change_product_status("3",p_arr_rec_product_prykey[l_arr_curr].part_code,l_arr_curr) 

		ON ACTION "STOP TO REORDER"
			CALL change_product_status("4",p_arr_rec_product_prykey[l_arr_curr].part_code,l_arr_curr) 


		ON ACTION ("DOUBLECLICK","EDIT") # BEFORE FIELD part_code 
			CALL input_product_main_details(MODE_CLASSIC_EDIT,p_arr_rec_product_prykey[l_arr_curr].part_code) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0 
					ERROR "Product has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product updated has been cancelled by user"
				OTHERWISE
					ERROR "Product update has FAILED with errors!"
			END CASE
--			SHOW OPTION "Report Code","Turnover","Stock","Dimensions","Warehouse"

		ON ACTION ("Stock") 
			#       " Add purchasing AND stocking details"
			CALL input_product_purchase_detail(p_arr_rec_product_prykey[l_arr_curr].part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Purchase details have been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Purchase details modification has been cancelled by user"
				OTHERWISE
					ERROR "Purchase details modification has FAILED with errors!"
			END CASE

		ON ACTION ("Report Code")
			#        " Add reporting code VALUES TO the product"
			CALL input_product_report_codes(p_arr_rec_product_prykey[l_arr_curr].part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Report code has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Report code modification has been cancelled by user"
				OTHERWISE
					ERROR "Report code modification has FAILED with errors!"
			END CASE
		
		ON ACTION "Turnover" 
			#        " Add statistical VALUES TO the product"
			CALL input_product_statistic_amts(p_arr_rec_product_prykey[l_arr_curr].part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Turnover has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Turnover modification has been cancelled by user"
				OTHERWISE
					ERROR "Turnover modification has FAILED with errors!"
			END CASE

		ON ACTION "Dimensions" 
			#        " Add dimension quantities TO the product"
			CALL input_product_dimensions(p_arr_rec_product_prykey[l_arr_curr].part_code,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Product dimensions have been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product dimensions modification has been cancelled by user"
				OTHERWISE
					ERROR "Product dimensions modification has FAILED with errors!"
			END CASE

		ON ACTION "Information"
			CALL input_prodinfo(l_rec_product.part_code) RETURNING l_operation_status
			CASE
				WHEN l_operation_status = 0
					ERROR "Product information has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product information modification has been cancelled by user"
				OTHERWISE
					ERROR "Product information modification has FAILED with errors!"
			END CASE

		ON ACTION  "Warehouse"
			LET l_run_arg1 = "PRODUCT_PART_CODE=", trim(l_rec_product.part_code)
			LET l_run_arg2 = "MODE=", MODE_CLASSIC_EDIT
			CALL run_prog("I16",l_run_arg1,l_run_arg2,"","") 

{
					MENU " Inventory" 

						ON ACTION "WEB-HELP" -- albo kd-372 
							CALL onlinehelp(getmoduleid(),null) 

						BEFORE MENU 
							IF modu_rec_inparms.ref1_text IS NOT NULL 
							OR modu_rec_inparms.ref2_text IS NOT NULL 
							OR modu_rec_inparms.ref3_text IS NOT NULL 
							OR modu_rec_inparms.ref4_text IS NOT NULL 
							OR modu_rec_inparms.ref5_text IS NOT NULL 
							OR modu_rec_inparms.ref6_text IS NOT NULL 
							OR modu_rec_inparms.ref7_text IS NOT NULL 
							OR modu_rec_inparms.ref8_text IS NOT NULL THEN 
								SHOW option "Reporting" 
							ELSE 
								HIDE option "Reporting" 
							END IF 
							IF modu_rec_company.module_text[5] = "E" THEN 
								SHOW option "Turnover" 
							ELSE 
								HIDE option "Turnover" 
							END IF 
							CALL publish_toolbar("kandoo","I15","menu-Inventory-1") -- albo kd-505 

							LET p_arr_rec_product[l_arr_curr].desc_text = l_rec_product.desc_text 
							LET p_arr_rec_product[l_arr_curr].short_desc_text = l_rec_product.short_desc_text 
							LET p_arr_rec_product[l_arr_curr].status_date = l_rec_product.status_date 
							LET p_arr_rec_product[l_arr_curr].status_ind = l_rec_product.status_ind 
							IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
								SELECT * INTO l_rec_class.* 
								FROM class 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND class_code = l_rec_product.class_code 
								IF l_rec_class.stock_level_ind IS NOT NULL AND 
								l_rec_class.stock_level_ind > l_rec_class.price_level_ind THEN 
									LET l_match_part = p_arr_rec_product[l_arr_curr].part_code clipped,"*" 
									UPDATE product 
									SET prodgrp_code = l_rec_product.prodgrp_code, 
									maingrp_code = l_rec_product.maingrp_code, 
									status_date = l_rec_product.status_date, 
									cat_code = l_rec_product.cat_code, 
									pur_uom_code = l_rec_product.pur_uom_code, 
									stock_uom_code = l_rec_product.stock_uom_code, 
									sell_uom_code = l_rec_product.sell_uom_code, 
									price_uom_code = l_rec_product.price_uom_code, 
									pur_stk_con_qty = l_rec_product.pur_stk_con_qty, 
									stk_sel_con_qty = l_rec_product.stk_sel_con_qty, 
									weight_qty = l_rec_product.weight_qty, 
									cubic_qty = l_rec_product.cubic_qty, 
									area_qty = l_rec_product.area_qty, 
									length_qty = l_rec_product.length_qty, 
									pack_qty = l_rec_product.pack_qty, 
									target_turn_qty = l_rec_product.target_turn_qty 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code matches l_match_part 
									AND class_code = l_rec_class.class_code 
								END IF 
							END IF 
							EXIT MENU 

						X COMMAND "EDIT" "Edit details FOR this product" 
							CURRENT WINDOW IS i610 
							IF edit_product(l_rec_product.*) THEN 
							END IF 
							CURRENT WINDOW IS w1_i15 

						X COMMAND "STOCK" "Edit purchasing AND stocking details FOR this product" 
							CALL prod_detl(l_rec_product.*) 

						X COMMAND "DIMENSIONS" "Edit dimension details FOR this product" 
							IF dimension_amts(l_rec_product.*) THEN 
							END IF 

						X COMMAND "REPORT_CODE" "Edit reporting code VALUES FOR this product" 
							IF input_product_report_codes(l_rec_product.*) THEN 
							END IF 

						X COMMAND "TURNOVER" "Edit statistical VALUES TO the product" 
							IF statistic_amts(l_rec_product.*) THEN 
							END IF 

						X COMMAND "INFORMATION" "Edit product information" 
							CALL input_prodinfo(l_rec_product.part_code) 

						X COMMAND "WAREHOUSE" "Add product STATUS TO Warehouse"
							LET l_run_arg1 = "PRODUCT_PART_CODE=", trim(l_rec_product.part_code)
							LET l_run_arg2 = "MODE=", MODE_CLASSIC_EDIT
							CALL run_prog("I16",l_run_arg1,l_run_arg2,"","") 

						COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

					END MENU 
}
				--END IF 

 
				INITIALIZE l_rec_product.* TO NULL 
 
			#      AFTER ROW
			#         DISPLAY p_arr_rec_product[l_idx].*
			#              TO sr_product[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 	# scan_dataset_pick_action_product

####################################################################
# FUNCTION scan_tree_pick_action_product()
# This function displays the chart of account in tree form (product's hierarchy)
#
####################################################################
FUNCTION scan_tree_pick_action_product(l_arr_rec_product_tree,l_arr_rec_element_type) 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_select DYNAMIC ARRAY OF LIKE product.part_code 
	DEFINE l_arr_idx SMALLINT 
	DEFINE l_arr_curr SMALLINT
	DEFINE l_msgstr STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_del_count SMALLINT 
	DEFINE p_display_mode CHAR(4)
	DEFINE l_arr_rec_product_tree t_rec_product_tree
	DEFINE l_arr_rec_element_type t_element_type
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_operation_status INTEGER
	DEFINE l_run_arg1,l_run_arg2 STRING

	OPEN WINDOW I612_tree with FORM "I612_tree"
	 
	 CALL windecoration_i("I612") 

	# So the tree array contains Dept code, Main group codes, group codes or part codes
	DISPLAY ARRAY l_arr_rec_product_tree TO sr_product_tree.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I15","input-p_arr_rec_product-1") -- albo kd-505 
 
			CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_product_tree.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT l_arr_rec_product_tree.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_arr_curr = arr_curr() 
			CASE
				WHEN l_arr_rec_element_type[l_arr_curr] = "P"	# this is a product line
					CALL dialog.setActionHidden("EDIT",FALSE)
					CALL dialog.setActionHidden("MAKE AVAILABLE",FALSE)
					CALL dialog.setActionHidden("ON HOLD",FALSE)
					CALL dialog.setActionHidden("DELETE",FALSE)
					CALL dialog.setActionHidden("STOP TO REORDER",FALSE)
					CALL dialog.setActionHidden("STOCK",FALSE)
					CALL dialog.setActionHidden("REPORT CODE",FALSE)
					CALL dialog.setActionHidden("TURNOVER",FALSE)
					CALL dialog.setActionHidden("DIMENSIONS",FALSE)
					CALL dialog.setActionHidden("INFORMATION",FALSE)
					CALL dialog.setActionHidden("WAREHOUSE",FALSE)
				OTHERWISE
					CALL dialog.setActionHidden("EDIT",TRUE)
					CALL dialog.setActionHidden("MAKE AVAILABLE",TRUE)
					CALL dialog.setActionHidden("ON HOLD",TRUE)
					CALL dialog.setActionHidden("DELETE",TRUE)
					CALL dialog.setActionHidden("STOP TO REORDER",TRUE)
					CALL dialog.setActionHidden("STOCK",TRUE)
					CALL dialog.setActionHidden("REPORT CODE",TRUE)
					CALL dialog.setActionHidden("TURNOVER",TRUE)
					CALL dialog.setActionHidden("DIMENSIONS",TRUE)
					CALL dialog.setActionHidden("INFORMATION",TRUE)
					CALL dialog.setActionHidden("WAREHOUSE",TRUE)
			END CASE
		ON ACTION "MAKE AVAILABLE"
			CALL change_product_status("1",l_arr_rec_product_tree[l_arr_curr].id,l_arr_curr) 

		ON ACTION "ON HOLD"
			CALL change_product_status("2",l_arr_rec_product_tree[l_arr_curr].id,l_arr_curr) 

		ON ACTION "DELETE"
			CALL change_product_status("3",l_arr_rec_product_tree[l_arr_curr].id,l_arr_curr) 

		ON ACTION "STOP TO REORDER"
			CALL change_product_status("4",l_arr_rec_product_tree[l_arr_curr].id,l_arr_curr) 

		ON ACTION ("DOUBLECLICK","EDIT") # BEFORE FIELD part_code 
			CALL input_product_main_details(MODE_CLASSIC_EDIT,l_arr_rec_product_tree[l_arr_curr].id) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0 
					ERROR "Product has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product updated has been cancelled by user"
				OTHERWISE
					ERROR "Product update has FAILED with errors!"
			END CASE
--			SHOW OPTION "Report Code","Turnover","Stock","Dimensions","Warehouse"

		ON ACTION ("STOCK") 
			#       " Add purchasing AND stocking details"
			CALL input_product_purchase_detail(l_arr_rec_product_tree[l_arr_curr].id,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Purchase details have been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Purchase details modification has been cancelled by user"
				OTHERWISE
					ERROR "Purchase details modification has FAILED with errors!"
			END CASE

		ON ACTION ("REPORT CODE")
			#        " Add reporting code VALUES TO the product"
			CALL input_product_report_codes(l_arr_rec_product_tree[l_arr_curr].id,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Report code has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Report code modification has been cancelled by user"
				OTHERWISE
					ERROR "Report code modification has FAILED with errors!"
			END CASE
		
		ON ACTION "TURNOVER" 
			#        " Add statistical VALUES TO the product"
			CALL input_product_statistic_amts(l_arr_rec_product_tree[l_arr_curr].id,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Turnover has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Turnover modification has been cancelled by user"
				OTHERWISE
					ERROR "Turnover modification has FAILED with errors!"
			END CASE

		ON ACTION "DIMENSIONS" 
			#        " Add dimension quantities TO the product"
			CALL input_product_dimensions(l_arr_rec_product_tree[l_arr_curr].id,l_rec_product.*) RETURNING l_operation_status,l_rec_product.*
			CASE
				WHEN l_operation_status = 0
					ERROR "Product dimensions have been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product dimensions modification has been cancelled by user"
				OTHERWISE
					ERROR "Product dimensions modification has FAILED with errors!"
			END CASE

		ON ACTION "INFORMATION"
			CALL input_prodinfo(l_arr_rec_product_tree[l_arr_curr].id) RETURNING l_operation_status
			CASE
				WHEN l_operation_status = 0
					ERROR "Product information has been updated successfully"
				WHEN l_operation_status = -1 
					ERROR "Product information modification has been cancelled by user"
				OTHERWISE
					ERROR "Product information modification has FAILED with errors!"
			END CASE

		ON ACTION  "Warehouse"
			LET l_run_arg1 = "PRODUCT_PART_CODE=", trim(l_arr_rec_product_tree[l_arr_curr].id)
			LET l_run_arg2 = "MODE=", MODE_CLASSIC_EDIT
			CALL run_prog("I16",l_run_arg1,l_run_arg2,"","") 
	END DISPLAY


END FUNCTION  # scan_tree_pick_action_product() 

############################################################
# FUNCTION is_product_deletable(p_part_code)
#
#
############################################################
FUNCTION is_product_deletable(p_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_class RECORD LIKE class.* 

	{  This is granpa's way of doing, considering you have all the time to wait
	# Kandoo has referential integrity constraints, the real answer to is a product deletable
	# is if it has no children in other tables
	SELECT * INTO l_rec_product.* FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		SELECT * INTO l_rec_class.* FROM class 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = l_rec_product.class_code 
		IF l_rec_class.stock_level_ind IS NOT NULL AND l_rec_class.stock_level_ind > l_rec_class.price_level_ind THEN 
			LET p_part_code = p_part_code clipped,"*" 
			SELECT unique 1 FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code matches p_part_code 
			AND (onhand_qty != 0 OR onord_qty != 0 OR back_qty != 0) 
			IF status = 0 THEN 
				LET msgresp=kandoomsg("I",7014,l_rec_product.part_code) 
				#7014 "Stock exists on hand"
				RETURN false 
			ELSE 
				RETURN true 
			END IF 
		END IF 
	END IF 
	SELECT unique 1 FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_part_code 
	AND (onhand_qty != 0 OR onord_qty != 0 OR back_qty != 0) 
	}
	# Simulate a delete product and see what happens:
	# if errors: this product has children, else it can be deleted
	# in both cases we do not forget to rollback the delete :-)
	BEGIN WORK
	WHENEVER SQLERROR CONTINUE
	DELETE FROM product
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	AND part_code = p_part_code
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	IF sqlca.sqlcode < 0 THEN
		LET msgresp=kandoomsg("I",7014,p_part_code) 
		ROLLBACK WORK
		RETURN false 
	ELSE
		ROLLBACK WORK
		RETURN TRUE
	END IF
END FUNCTION 	# is_product_deletable



############################################################
# FUNCTION change_product_status(p_status_ind, p_part_code,p_idx)
# This function updates the product and prodstatus records status
#
############################################################
FUNCTION change_product_status(p_status_ind, p_part_code,p_idx) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_status_ind LIKE product.status_ind 
	DEFINE p_idx SMALLINT 
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_save_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_match_part_code LIKE product.part_code 
	DEFINE l_parent_part_code LIKE product.part_code 
	DEFINE l_filler_part_code LIKE product.part_code 
	DEFINE l_flex_part_code LIKE product.part_code 
	DEFINE l_rec_class_code LIKE class.class_code 
	DEFINE query_text STRING
	DEFINE l_counter SMALLINT 
	DEFINE l_counter2 SMALLINT 
	DEFINE l_counter3 SMALLINT 
	DEFINE l_not_flexible SMALLINT 
	DEFINE l_flex_num INTEGER 

	LET l_not_flexible = 1 
	IF p_part_code IS NULL THEN 
		RETURN 
	END IF 
	IF p_status_ind = "3" THEN 
		IF not(is_product_deletable(p_part_code)) THEN 
			RETURN 
		END IF 
	END IF 

	# Do we really need to read ALL the  product columns again just for status change?
	SELECT part_code,class_code 
	INTO l_rec_product.part_code,l_rec_product.class_code 
	FROM product 
	WHERE cmpy_code =glob_rec_kandoouser.cmpy_code 
	AND part_code = p_part_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN 
	END IF 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code,l_rec_product.class_code,1) 
		RETURNING l_parent_part_code, 
			l_filler_part_code, 
			l_flex_part_code, 
			l_flex_num 
		IF l_flex_part_code IS NOT NULL THEN 
			SELECT status_ind INTO l_rec_save_product.status_ind
			FROM product 
			WHERE part_code = l_parent_part_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF p_status_ind != "3" THEN 
				IF l_rec_save_product.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9512,"") 
					#9512 Parent product has been deleted
					RETURN 
				END IF 
				IF p_status_ind = "1" THEN 
					IF l_rec_save_product.status_ind = "2" THEN 
						LET msgresp = kandoomsg("I",9513,"") 
						#9512 Parent product has been put on hold
						RETURN 
					END IF 
					IF l_rec_save_product.status_ind = "4" THEN 
						LET msgresp = kandoomsg("I",9514,"") 
						#9514 Parent product has been stopped FROM reordering
						RETURN 
					END IF 
				END IF 
			END IF 
		END IF 

		SELECT * INTO l_rec_class.* 
		FROM class 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = l_rec_product.class_code 

		IF l_rec_class.stock_level_ind IS NOT NULL AND l_rec_class.stock_level_ind > l_rec_class.price_level_ind THEN 
			LET l_not_flexible = 0 
			LET l_match_part_code = p_part_code clipped,"*" 

			IF crs_product_from_class.GetName() IS NULL THEN
				LET query_text = "SELECT * ",
				" FROM product ",
				" WHERE part_code matches '?' ",
				" AND cmpy_code = ? ",
				" AND class_code = ?"
				CALL crs_product_from_class.Declare(query_text)
			END IF
			CALL crs_product_from_class.Open(l_match_part_code,glob_rec_kandoouser.cmpy_code,l_rec_class.class_code)

			WHILE crs_product_from_class.FetchNext(l_rec_product.*) = 0
				IF (p_status_ind = "2" OR p_status_ind = "4") AND p_part_code != l_rec_product.part_code THEN 
					UPDATE product 
					SET status_date = today, 
					status_ind = p_status_ind 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 
					AND status_ind != "3" 
				ELSE 
					UPDATE product 
					SET status_date = today, 
					status_ind = p_status_ind 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 
				END IF 

				IF l_flex_part_code IS NOT NULL THEN 
					IF crs_prodstatus_from_parent.GetName() IS NULL THEN
						LET query_text = "SELECT * FROM prodstatus ",
						" WHERE part_code = ? ",
						" AND cmpy_code =  ?"
						CALL crs_prodstatus_from_parent.Declare(query_text)
					END IF

					CALL crs_prodstatus_from_parent.Open(l_parent_part_code,glob_rec_kandoouser.cmpy_code)
					WHILE crs_prodstatus_from_parent.FetchNext(l_rec_prodstatus.*) = 0
						IF l_rec_prodstatus.status_ind != "3" THEN 
							IF p_status_ind = "1" THEN 
								IF l_rec_prodstatus.status_ind != "2" 
								AND l_rec_prodstatus.status_ind != "4" THEN 
									UPDATE prodstatus 
									SET status_date = today, 
									status_ind = p_status_ind 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code = l_rec_product.part_code 
									AND ware_code = l_rec_prodstatus.ware_code 
								END IF 
							ELSE 
								UPDATE prodstatus 
								SET status_date = today, 
									status_ind = p_status_ind 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = l_rec_product.part_code 
								AND ware_code = l_rec_prodstatus.ware_code 
								AND status_ind != "3" 
							END IF 
						END IF 
					END WHILE 
				ELSE 
					IF p_status_ind = "1" THEN 
						UPDATE prodstatus 
						SET status_date = today, 
							status_ind = p_status_ind 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_product.part_code 
					ELSE 
						UPDATE prodstatus 
						SET status_date = today, 
							status_ind = p_status_ind 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_product.part_code 
						AND status_ind != "3" 
					END IF 
				END IF 
			END WHILE 

			LET l_counter3 = 0 
			# FIXME: not sure what this is supposed to do...
			# Read the construct cursor again, fix empty status date
			# Anyway, display array to to form is not good, better return values
			# disabling the next block
			# This seems to be only cosmetics ... ericv 20201213
			{
			FOREACH c_product INTO l_rec_product.* 
				LET l_counter3 = l_counter3 + 1 
				LET modu_arr_rec_product[l_counter3].scroll_flag = NULL 
				LET modu_arr_rec_product[l_counter3].part_code = l_rec_product.part_code 
				LET modu_arr_rec_product[l_counter3].desc_text = l_rec_product.desc_text 
				LET modu_arr_rec_product[l_counter3].short_desc_text = 	l_rec_product.short_desc_text 
				IF l_rec_product.status_date IS NULL OR l_rec_product.status_date = "31/12/1899" THEN 
					LET modu_arr_rec_product[l_counter3].status_date = "" 
				ELSE 
					LET modu_arr_rec_product[l_counter3].status_date = 
					l_rec_product.status_date 
				END IF 
				LET modu_arr_rec_product[l_counter3].status_ind = l_rec_product.status_ind 
				#            IF l_counter3 = 250 THEN
				#               EXIT FOREACH
				#            END IF
			END FOREACH 

			IF l_counter3 > 14 THEN 
				LET l_counter2 = 14 
			ELSE 
				LET l_counter2 = l_counter3 
			END IF 
			FOR l_counter = 1 TO l_counter2 
				DISPLAY modu_arr_rec_product[l_counter].status_ind, 
				modu_arr_rec_product[l_counter].status_date 
				TO sr_product[l_counter].status_ind, 
				sr_product[l_counter].status_date 

			END FOR 
			}
		END IF 
	END IF 

	IF l_not_flexible THEN 
		UPDATE product 
		SET status_date = today, 
		status_ind = p_status_ind 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code 
		IF p_status_ind = "1" THEN 
			UPDATE prodstatus 
			SET status_date = today, 
			status_ind = p_status_ind 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_part_code 
		ELSE 
			UPDATE prodstatus 
			SET status_date = today, 
			status_ind = p_status_ind 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_part_code 
			AND status_ind != "3" 
		END IF 
		{
		LET modu_arr_rec_product[p_idx].status_ind = p_status_ind 
		LET modu_arr_rec_product[p_idx].status_date = today
		} 
	END IF 

	IF p_status_ind = "4" THEN 
		IF check_back(glob_rec_kandoouser.cmpy_code,p_part_code,l_rec_product.class_code) THEN 
			LET msgresp=kandoomsg("I",7061,"") 
			#7061 "This product...
		END IF 
	END IF 

END FUNCTION  # change_product_status_prodstatus


############################################################
# deprecated
# FUNCTION edit_product(p_rec_1_product)
# this function is replaced by input_product_main_details in I_IN_LIB_forms_fct.4gl
# duplicate code!
############################################################
{
--FUNCTION edit_product(p_rec_1_product) 
	DEFINE p_rec_1_product RECORD LIKE product.* 
	DEFINE l_rec_prodgrp RECORD LIKE prodgrp.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_direction_ind CHAR(1) 
	DEFINE l_alter_text LIKE product.desc_text 
	DEFINE l_compn_text LIKE product.desc_text 
	DEFINE l_super_text LIKE product.desc_text 
	DEFINE l_pr_parent_part_code LIKE product.part_code 
	DEFINE l_opt_segment LIKE product.part_code 
	DEFINE l_filler CHAR(1) 
	DEFINE l_part_length SMALLINT 

	LET msgresp=kandoomsg("I",1014,"") 
	#1014 " Enter product details - ESC TO Continue "
	CALL break_prod(glob_rec_kandoouser.cmpy_code, pr_product.part_code, 
	pr_product.class_code,1) 
	RETURNING l_pr_parent_part_code, l_filler, l_opt_segment, 
	l_part_length 

	SELECT desc_text 
	INTO l_rec_prodgrp.desc_text 
	FROM prodgrp 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodgrp_code = p_rec_1_product.prodgrp_code 
	SELECT desc_text 
	INTO l_rec_category.desc_text 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = p_rec_1_product.cat_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_category.desc_text = "**********" 
	END IF 

	SELECT desc_text 
	INTO l_rec_class.desc_text 
	FROM class 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND class_code = p_rec_1_product.class_code 
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_class.desc_text = "**********" 
	END IF 

	SELECT desc_text 
	INTO l_alter_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_1_product.alter_part_code 
	SELECT desc_text 
	INTO l_compn_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_1_product.compn_part_code 
	SELECT desc_text 
	INTO l_super_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_1_product.super_part_code 
	SELECT * INTO l_rec_proddanger.* 
	FROM proddanger 
	WHERE proddanger.dg_code = p_rec_1_product.dg_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	DISPLAY p_rec_1_product.part_code, 
	l_rec_prodgrp.desc_text, 
	l_rec_category.desc_text, 
	l_rec_class.desc_text, 
	l_alter_text, 
	l_compn_text, 
	l_super_text, 
	p_rec_1_product.stock_turn_qty, 
	p_rec_1_product.dg_code, 
	l_rec_proddanger.tech_text 
	TO product.part_code, 
	prodgrp.desc_text, 
	category.desc_text, 
	class.desc_text, 
	alter_text, 
	compn_text, 
	super_text, 
	stock_turn_qty, 
	dg_code, 
	proddanger.tech_text 

	INPUT BY NAME p_rec_1_product.short_desc_text, 
	p_rec_1_product.desc_text, 
	p_rec_1_product.desc2_text, 
	p_rec_1_product.prodgrp_code, 
	p_rec_1_product.cat_code, 
	p_rec_1_product.class_code, 
	p_rec_1_product.alter_part_code, 
	p_rec_1_product.super_part_code, 
	p_rec_1_product.compn_part_code, 
	p_rec_1_product.pur_uom_code, 
	p_rec_1_product.stock_uom_code, 
	p_rec_1_product.sell_uom_code, 
	p_rec_1_product.price_uom_code, 
	p_rec_1_product.pur_stk_con_qty, 
	p_rec_1_product.stk_sel_con_qty, 
	p_rec_1_product.dg_code, 
	p_rec_1_product.target_turn_qty WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I15","input-modu_arr_rec_product-2") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) infield (prodgrp_code) 
			LET p_rec_1_product.prodgrp_code = show_prodgrp(glob_rec_kandoouser.cmpy_code,"") 
			NEXT FIELD prodgrp_code 

		ON KEY (control-b) infield (cat_code) 
			LET p_rec_1_product.cat_code = show_pcat(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD cat_code 

		ON KEY (control-b) infield (alter_part_code) 
			LET p_rec_1_product.alter_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD alter_part_code 

		ON KEY (control-b) infield (super_part_code) 
			LET p_rec_1_product.super_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD super_part_code 

		ON KEY (control-b) infield (compn_part_code) 
			LET p_rec_1_product.compn_part_code = show_item(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD compn_part_code 

		ON KEY (control-b) infield (sell_uom_code) 
			LET p_rec_1_product.sell_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD sell_uom_code 

		ON KEY (control-b) infield (price_uom_code) 
			LET p_rec_1_product.price_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD price_uom_code 

		ON KEY (control-b) infield (pur_uom_code) 
			LET p_rec_1_product.pur_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD pur_uom_code 

		ON KEY (control-b) infield (stock_uom_code) 
			LET p_rec_1_product.stock_uom_code = show_uom(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD stock_uom_code 

		ON KEY (control-b) infield (class_code) 
			LET p_rec_1_product.class_code = show_pcls(glob_rec_kandoouser.cmpy_code) 
			NEXT FIELD class_code 

		ON KEY (control-b) infield (dg_code) 
			LET p_rec_1_product.dg_code = show_proddanger(glob_rec_kandoouser.cmpy_code, "") 
			NEXT FIELD dg_code 

		AFTER FIELD short_desc_text 
			IF p_rec_1_product.short_desc_text IS NULL THEN 
				LET msgresp=kandoomsg("I",9037,"") 
				#9037 " Product short description must be entered"
				LET p_rec_1_product.short_desc_text = p_rec_1_product.part_code 
				NEXT FIELD short_desc_text 
			END IF 

		AFTER FIELD desc2_text 
			LET l_direction_ind = "D" 

		BEFORE FIELD prodgrp_code 
			IF l_opt_segment IS NOT NULL 
			OR l_opt_segment != " " THEN 
				IF l_direction_ind = "U" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD prodgrp_code 
			CLEAR prodgrp.desc_text 
			IF p_rec_1_product.prodgrp_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9014,"") 
				#9014 "Product Group Code must be entered"
				NEXT FIELD prodgrp_code 
			ELSE 
				SELECT desc_text, 
				maingrp_code 
				INTO l_rec_prodgrp.desc_text, 
				p_rec_1_product.maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_1_product.prodgrp_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				ELSE 
					DISPLAY l_rec_prodgrp.desc_text TO prodgrp.desc_text 

				END IF 
			END IF 

		BEFORE FIELD cat_code 
			IF l_opt_segment IS NOT NULL 
			OR l_opt_segment != " " THEN 
				IF l_direction_ind = "U" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD cat_code 
			CLEAR category.desc_text 
			IF p_rec_1_product.cat_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9038,"") 
				#9038 "product category Code must be entered"
				NEXT FIELD cat_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_category.desc_text 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_1_product.cat_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				ELSE 
					DISPLAY l_rec_category.desc_text TO category.desc_text 

				END IF 
			END IF 

		BEFORE FIELD class_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD alter_part_code 
				END IF 
			END IF 

		AFTER FIELD class_code 
			CLEAR class.desc_text 
			IF p_rec_1_product.class_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9040,"") 
				#9040 "Product Class code must be Entered"
				NEXT FIELD class_code 
			ELSE 
				SELECT desc_text 
				INTO l_rec_class.desc_text 
				FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = p_rec_1_product.class_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				ELSE 
					DISPLAY l_rec_class.desc_text TO class.desc_text 

				END IF 
			END IF 

		BEFORE FIELD alter_part_code 
			LET l_direction_ind = "U" 

		AFTER FIELD alter_part_code 
			CLEAR l_alter_text 
			IF p_rec_1_product.alter_part_code IS NOT NULL THEN 
				IF p_rec_1_product.alter_part_code = p_rec_1_product.part_code THEN 
					LET msgresp=kandoomsg("I",9042,"") 
					#9042 "Product can NOT be an alternate TO itself"
					NEXT FIELD alter_part_code 
				END IF 
				SELECT desc_text 
				INTO l_alter_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_1_product.alter_part_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					SELECT desc_text 
					INTO l_alter_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = p_rec_1_product.alter_part_code 
					AND type_ind = "A" 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET msgresp=kandoomsg("I",9043,"") 
						#9043" Aletrnate Product OR Group NOT found - Try Window "
						NEXT FIELD alter_part_code 
					END IF 
				END IF 
				DISPLAY l_alter_text TO l_alter_text 

			END IF 

		AFTER FIELD super_part_code 
			CLEAR l_super_text 
			IF p_rec_1_product.super_part_code IS NOT NULL THEN 
				IF p_rec_1_product.part_code = p_rec_1_product.super_part_code THEN 
					LET msgresp=kandoomsg("I",9044,"") 
					#9044" Product cannot be superceded by itself "
					NEXT FIELD super_part_code 
				END IF 
				SELECT desc_text 
				INTO l_super_text 
				FROM product 
				WHERE part_code = p_rec_1_product.super_part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010"Product Code NOT found - Try Window "
					NEXT FIELD super_part_code 
				END IF 
				DISPLAY BY NAME l_super_text 

			END IF 

		AFTER FIELD compn_part_code 
			CLEAR l_compn_text 
			IF p_rec_1_product.compn_part_code IS NOT NULL THEN 
				IF p_rec_1_product.part_code = p_rec_1_product.compn_part_code THEN 
					LET msgresp=kandoomsg("I",9047,"") 
					#9047 " Product cannot be a companion of itself "
					NEXT FIELD compn_part_code 
				END IF 
				SELECT desc_text 
				INTO l_compn_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_1_product.compn_part_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					SELECT desc_text 
					INTO l_compn_text 
					FROM ingroup 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ingroup_code = p_rec_1_product.compn_part_code 
					AND type_ind = "C" 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET msgresp=kandoomsg("I",9048,"") 
						#9048 " Companion Product OR Group NOT found - Try Window"
						NEXT FIELD compn_part_code 
					END IF 
				END IF 
				DISPLAY BY NAME l_compn_text 

			END IF 

		AFTER FIELD pur_uom_code 
			IF p_rec_1_product.pur_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9049,"") 
				#9049" Purchasing Unit Of Measure must be entered "
				NEXT FIELD pur_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.pur_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9050,"") 
					#9050" Purchasing Unit Of Measure NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				ELSE 
					IF p_rec_1_product.stock_uom_code IS NULL THEN 
						LET p_rec_1_product.stock_uom_code = p_rec_1_product.pur_uom_code 
					END IF 
				END IF 
			END IF 
			IF p_rec_1_product.pur_uom_code = p_rec_1_product.stock_uom_code THEN 
				LET p_rec_1_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.pur_stk_con_qty 

			END IF 

		AFTER FIELD stock_uom_code 
			IF p_rec_1_product.stock_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9051,"") 
				#9051 "Stocking UOM must be entered"
				NEXT FIELD stock_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.stock_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				ELSE 
					IF p_rec_1_product.sell_uom_code IS NULL THEN 
						LET p_rec_1_product.sell_uom_code = p_rec_1_product.stock_uom_code 
					END IF 
				END IF 
			END IF 
			IF p_rec_1_product.pur_uom_code = p_rec_1_product.stock_uom_code THEN 
				LET p_rec_1_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.pur_stk_con_qty 

			END IF 
			IF p_rec_1_product.stock_uom_code = p_rec_1_product.sell_uom_code THEN 
				LET p_rec_1_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.stk_sel_con_qty 

			END IF 

		AFTER FIELD sell_uom_code 
			IF p_rec_1_product.sell_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9053,"") 
				#9053 "Selling Unit Of Measure must be entered"
				NEXT FIELD sell_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.sell_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				ELSE 
					IF p_rec_1_product.price_uom_code IS NULL THEN 
						LET p_rec_1_product.price_uom_code = p_rec_1_product.sell_uom_code 
					END IF 
				END IF 
			END IF 
			IF p_rec_1_product.stock_uom_code = p_rec_1_product.sell_uom_code THEN 
				LET p_rec_1_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.stk_sel_con_qty 

			END IF 

		BEFORE FIELD price_uom_code 
			IF modu_rec_company.module_text[23] != "W" THEN 
				LET p_rec_1_product.price_uom_code = p_rec_1_product.sell_uom_code 
				DISPLAY BY NAME p_rec_1_product.price_uom_code 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD price_uom_code 
			IF p_rec_1_product.price_uom_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9215,"") 
				#9215 "Pricing Unit Of Measure must be entered"
				NEXT FIELD price_uom_code 
			ELSE 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.price_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9216,"") 
					#9216" UOM NOT found - Try Window"
					NEXT FIELD price_uom_code 
				END IF 
			END IF 

		BEFORE FIELD pur_stk_con_qty 
			IF p_rec_1_product.pur_uom_code = p_rec_1_product.stock_uom_code THEN 
				LET p_rec_1_product.pur_stk_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.pur_stk_con_qty 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD pur_stk_con_qty 
			IF p_rec_1_product.pur_stk_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9055,"") 
				#9055 "Must enter Purchasing TO Stock Conversion Rate"
				NEXT FIELD pur_stk_con_qty 
			END IF 
			IF p_rec_1_product.pur_stk_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD pur_stk_con_qty 
			ELSE 
				IF p_rec_1_product.pur_stk_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7012,"") 
					#7012 "WARNING - the stocking unit IS larger than the buying ...
				END IF 
			END IF 

		BEFORE FIELD stk_sel_con_qty 
			IF p_rec_1_product.stock_uom_code = p_rec_1_product.sell_uom_code THEN 
				LET p_rec_1_product.stk_sel_con_qty = 1 
				DISPLAY BY NAME p_rec_1_product.stk_sel_con_qty 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD stk_sel_con_qty 
			IF p_rec_1_product.stk_sel_con_qty IS NULL THEN 
				LET msgresp=kandoomsg("I",9056,"") 
				#9056" Must enter Stocking TO Sales Conversion rate "
				NEXT FIELD stk_sel_con_qty 
			END IF 
			IF p_rec_1_product.stk_sel_con_qty = 0 THEN 
				#9502 "Conversion rate cannot be zero"
				LET msgresp=kandoomsg("I",9502,"") 
				NEXT FIELD stk_sel_con_qty 
			ELSE 
				IF p_rec_1_product.stk_sel_con_qty < 1 THEN 
					LET msgresp=kandoomsg("I",7013,"") 
					#7013 "WARNING - the stocking unit IS smaller than the ....
				END IF 
			END IF 

		AFTER FIELD dg_code 
			IF p_rec_1_product.dg_code IS NOT NULL THEN 
				SELECT * INTO l_rec_proddanger.* 
				FROM proddanger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND dg_code = p_rec_1_product.dg_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					#9246 "Dangerous goods code does NOT EXIT - try window"
					LET msgresp=kandoomsg("I",9246,"") 
					NEXT FIELD dg_code 
				ELSE 
					DISPLAY l_rec_proddanger.tech_text 
					TO proddanger.tech_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT maingrp_code 
				INTO p_rec_1_product.maingrp_code 
				FROM prodgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodgrp_code = p_rec_1_product.prodgrp_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9011,"") 
					#9011 "Product Group NOT found - Try Window"
					NEXT FIELD prodgrp_code 
				END IF 
				SELECT unique 1 FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = p_rec_1_product.cat_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9039,"") 
					#9039 "Product Category NOT found - Try Window"
					NEXT FIELD cat_code 
				END IF 
				SELECT unique 1 FROM class 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND class_code = p_rec_1_product.class_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				END IF 
				IF p_rec_1_product.short_desc_text IS NULL THEN 
					LET msgresp=kandoomsg("I",9037,"") 
					#9037 "Must enter description product description"
					NEXT FIELD short_desc_text 
				END IF 
				IF p_rec_1_product.desc_text IS NULL THEN 
					LET msgresp=kandoomsg("I",9037,"") 
					#9037 "Must enter description product description"
					NEXT FIELD desc_text 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.pur_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9050,"") 
					#9050 " Purchasing UOM NOT found - Try Window"
					NEXT FIELD pur_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.stock_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9052,"") 
					#9052" Stocking UOM NOT found - Try Window"
					NEXT FIELD stock_uom_code 
				END IF 
				SELECT unique 1 FROM uom 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND uom_code = p_rec_1_product.sell_uom_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9054,"") 
					#9054" Selling UOM NOT found - Try Window"
					NEXT FIELD sell_uom_code 
				END IF 
				IF p_rec_1_product.pur_uom_code = p_rec_1_product.sell_uom_code 
				AND p_rec_1_product.pur_uom_code <> p_rec_1_product.stock_uom_code THEN 
					LET msgresp=kandoomsg("I",9298,"") 
					#9298 WHEN Purchase UOM = Sell UOM THEN Stock Uom needs t
					NEXT FIELD stock_uom_code 
				END IF 
				IF p_rec_1_product.serial_flag = 'Y' THEN 
					IF p_rec_1_product.pur_uom_code <> p_rec_1_product.stock_uom_code 
					OR p_rec_1_product.pur_uom_code <> p_rec_1_product.sell_uom_code THEN 
						LET msgresp=kandoomsg("I",9297,"") 
						#9297 All Units of Measure must be the same FOR serial
						NEXT FIELD pur_uom_code 
					END IF 
				END IF 
				IF p_rec_1_product.dg_code IS NOT NULL THEN 
					SELECT unique 1 FROM proddanger 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND dg_code = p_rec_1_product.dg_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						#9246 "Dangerous goods code does NOT EXIT - try window"
						LET msgresp=kandoomsg("I",9246,"") 
						NEXT FIELD dg_code 
					END IF 
				END IF 
			END IF 

			#     ON KEY (control-w)
			#        CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET pr_product.* = p_rec_1_product.* 
		RETURN true 
	END IF 
END FUNCTION 
}

{
# This function is deprecated
############################################################
# FUNCTION scan_product()
#
#
############################################################
--FUNCTION scan_product() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_match_part LIKE product.part_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_back_msg SMALLINT 
	DEFINE l_counter SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_runner CHAR(90) 
	DEFINE l_parent LIKE product.part_code 
	DEFINE l_filler LIKE product.part_code 
	DEFINE l_flex_part LIKE product.part_code 
	DEFINE l_flex_num INTEGER 
	DEFINE l_run_arg STRING
	DEFINE l_run_arg1 STRING
	DEFINE l_run_arg2 STRING
	
	LET l_idx = 0 
	FOREACH c_product INTO pr_product.* 
		LET l_idx = l_idx + 1 
		LET modu_arr_rec_product[l_idx].scroll_flag = NULL 
		LET modu_arr_rec_product[l_idx].part_code = pr_product.part_code 
		LET modu_arr_rec_product[l_idx].desc_text = pr_product.desc_text 
		LET modu_arr_rec_product[l_idx].short_desc_text = pr_product.short_desc_text 
		IF pr_product.status_date IS NULL 
		OR pr_product.status_date = "31/12/1899" THEN 
			LET modu_arr_rec_product[l_idx].status_date = "" 
		ELSE 
			LET modu_arr_rec_product[l_idx].status_date = pr_product.status_date 
		END IF 
		LET modu_arr_rec_product[l_idx].status_ind = pr_product.status_ind 
		#      IF l_idx = 250 THEN
		#         LET msgresp=kandoomsg("U",6100,l_idx)
		#         EXIT FOREACH
		#       END IF
	END FOREACH 

	LET msgresp=kandoomsg("U",9113,l_idx) 
	#9113 "l_idx records selected"
	LET msgresp=kandoomsg("I",1013,"") 
	#1013 " RETURN TO Edit - F6 TO Make Available - F7 TO Hold - F2 TO Delete"
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	#   CALL set_count(l_idx)
	--	INPUT ARRAY modu_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTES(auto append = false, append row = false, delete row = false)
	DISPLAY ARRAY modu_arr_rec_product TO sr_product.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","I15","input-modu_arr_rec_product-1") -- albo kd-505 
			IF l_idx = 0 THEN 
				LET modu_arr_rec_product[1].status_date = NULL 
			END IF 
			CALL dialog.setActionHidden("EDIT",NOT modu_arr_rec_product.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT modu_arr_rec_product.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 

			--		BEFORE FIELD scroll_flag
			--			LET l_idx = arr_curr()
			#         LET scrn = scr_line()
			#         DISPLAY modu_arr_rec_product[l_idx].*
			#              TO sr_product[scrn].*

			--		AFTER FIELD scroll_flag
			--			LET modu_arr_rec_product[l_idx].scroll_flag = NULL
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF arr_curr() = arr_count() THEN
			#               LET msgresp=kandoomsg("I",9001,"")
			#               #9001"There are no more rows in the direction you are going"
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		ON ACTION "MAKE AVAILABLE"
		--ON KEY (F6) 
			CALL change_status("1",modu_arr_rec_product[l_idx].part_code,l_idx) 
			--			NEXT FIELD scroll_flag

		ON ACTION "ON HOLD"
		--ON KEY (F7) 
			CALL change_status("2",modu_arr_rec_product[l_idx].part_code,l_idx) 
			--			NEXT FIELD scroll_flag
		ON ACTION "DELETE"
		--ON KEY (F2) 
			CALL change_status("3",modu_arr_rec_product[l_idx].part_code,l_idx) 
			--			NEXT FIELD scroll_flag

		ON ACTION "STOP TO REORDER"
		--ON KEY (F8) 
			CALL change_status("4",modu_arr_rec_product[l_idx].part_code,l_idx) 
			--			NEXT FIELD scroll_flag

		ON ACTION ("DOUBLECLICK","EDIT") # BEFORE FIELD part_code 
			LET l_idx = arr_curr() 
			IF l_idx = 0 THEN 
				ERROR "No record to edit" 
			ELSE 

				SELECT * 
				INTO pr_product.* 
				FROM product 
				WHERE cmpy_code =glob_rec_kandoouser.cmpy_code 
				AND part_code = modu_arr_rec_product[l_idx].part_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					NEXT FIELD scroll_flag 
				END IF 

				LET pr_product.serial_flag = xlate_from(pr_product.serial_flag) 
				LET pr_product.total_tax_flag = xlate_from(pr_product.total_tax_flag) 
				LET pr_product.back_order_flag = xlate_from(pr_product.back_order_flag) 
				LET pr_product.disc_allow_flag = xlate_from(pr_product.disc_allow_flag) 
				LET pr_product.bonus_allow_flag=xlate_from(pr_product.bonus_allow_flag) 
				LET pr_product.trade_in_flag = xlate_from(pr_product.trade_in_flag) 
				LET pr_product.price_inv_flag = xlate_from(pr_product.price_inv_flag) 

				OPEN WINDOW i610 with FORM "I610" 
				 CALL windecoration_i("I610") 

				IF edit_product(pr_product.*) THEN 
					#OPEN WINDOW w1_I15 AT 9,3 with 2 rows, 76 columns
					#   ATTRIBUTE(border,white)
					MENU " Inventory" 

						ON ACTION "WEB-HELP" -- albo kd-372 
							CALL onlinehelp(getmoduleid(),null) 

						BEFORE MENU 
							IF modu_rec_inparms.ref1_text IS NOT NULL 
							OR modu_rec_inparms.ref2_text IS NOT NULL 
							OR modu_rec_inparms.ref3_text IS NOT NULL 
							OR modu_rec_inparms.ref4_text IS NOT NULL 
							OR modu_rec_inparms.ref5_text IS NOT NULL 
							OR modu_rec_inparms.ref6_text IS NOT NULL 
							OR modu_rec_inparms.ref7_text IS NOT NULL 
							OR modu_rec_inparms.ref8_text IS NOT NULL THEN 
								SHOW option "Reporting" 
							ELSE 
								HIDE option "Reporting" 
							END IF 
							IF modu_rec_company.module_text[5] = "E" THEN 
								SHOW option "Turnover" 
							ELSE 
								HIDE option "Turnover" 
							END IF 
							CALL publish_toolbar("kandoo","I15","menu-Inventory-1") -- albo kd-505 

						COMMAND "Save" 
							" Save product details " 
							LET pr_product.serial_flag = xlate_to(pr_product.serial_flag) 
							LET pr_product.total_tax_flag = xlate_to(pr_product.total_tax_flag) 
							LET pr_product.back_order_flag = xlate_to(pr_product.back_order_flag) 
							LET pr_product.disc_allow_flag = xlate_to(pr_product.disc_allow_flag) 
							LET pr_product.bonus_allow_flag = xlate_to(pr_product.bonus_allow_flag) 
							LET pr_product.trade_in_flag = xlate_to(pr_product.trade_in_flag) 
							LET pr_product.price_inv_flag = xlate_to(pr_product.price_inv_flag) 
							
							UPDATE product SET * = pr_product.* 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pr_product.part_code 
							
							LET modu_arr_rec_product[l_idx].desc_text = pr_product.desc_text 
							LET modu_arr_rec_product[l_idx].short_desc_text = pr_product.short_desc_text 
							LET modu_arr_rec_product[l_idx].status_date = pr_product.status_date 
							LET modu_arr_rec_product[l_idx].status_ind = pr_product.status_ind 
							IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
								SELECT * INTO l_rec_class.* 
								FROM class 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND class_code = pr_product.class_code 
								IF l_rec_class.stock_level_ind IS NOT NULL AND 
								l_rec_class.stock_level_ind > l_rec_class.price_level_ind THEN 
									LET l_match_part = modu_arr_rec_product[l_idx].part_code clipped,"*" 
									UPDATE product 
									SET prodgrp_code = pr_product.prodgrp_code, 
									maingrp_code = pr_product.maingrp_code, 
									status_date = pr_product.status_date, 
									cat_code = pr_product.cat_code, 
									pur_uom_code = pr_product.pur_uom_code, 
									stock_uom_code = pr_product.stock_uom_code, 
									sell_uom_code = pr_product.sell_uom_code, 
									price_uom_code = pr_product.price_uom_code, 
									pur_stk_con_qty = pr_product.pur_stk_con_qty, 
									stk_sel_con_qty = pr_product.stk_sel_con_qty, 
									weight_qty = pr_product.weight_qty, 
									cubic_qty = pr_product.cubic_qty, 
									area_qty = pr_product.area_qty, 
									length_qty = pr_product.length_qty, 
									pack_qty = pr_product.pack_qty, 
									target_turn_qty = pr_product.target_turn_qty 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code matches l_match_part 
									AND class_code = l_rec_class.class_code 
								END IF 
							END IF 
							EXIT MENU 

						COMMAND "EDIT" "Edit details FOR this product" 
							CURRENT WINDOW IS i610 
							IF edit_product(pr_product.*) THEN 
							END IF 
							CURRENT WINDOW IS w1_i15 

						COMMAND "STOCK" "Edit purchasing AND stocking details FOR this product" 
							CALL prod_detl(pr_product.*) 

						COMMAND "DIMENSIONS" "Edit dimension details FOR this product" 
							IF dimension_amts(pr_product.*) THEN 
							END IF 

						COMMAND "REPORT_CODE" "Edit reporting code VALUES FOR this product" 
							IF input_product_report_codes(pr_product.*) THEN 
							END IF 

						COMMAND "TURNOVER" "Edit statistical VALUES TO the product" 
							IF statistic_amts(pr_product.*) THEN 
							END IF 

						COMMAND "INFORMATION" "Edit product information" 
							CALL input_prodinfo(pr_product.part_code) 

						COMMAND "WAREHOUSE" "Add product STATUS TO Warehouse"
							LET l_run_arg1 = "PRODUCT_PART_CODE=", trim(pr_product.part_code)
							LET l_run_arg2 = "MODE=", MODE_CLASSIC_EDIT
							CALL run_prog("I16",l_run_arg1,l_run_arg2,"","") 

						COMMAND KEY(interrupt,"E")"Exit" " Discard changes" 
							LET int_flag = false 
							LET quit_flag = false 
							EXIT MENU 

					END MENU 

				END IF 

				CLOSE WINDOW i610 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
				INITIALIZE pr_product.* TO NULL 
				--         NEXT FIELD scroll_flag

			END IF 
			#      AFTER ROW
			#         DISPLAY modu_arr_rec_product[l_idx].*
			#              TO sr_product[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 

############################################################
# FUNCTION select_product()
# This function is deprecated, replaced by construct_dataset_product
#############################################################
--FUNCTION select_product() 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text STRING 

	CLEAR FORM 
	LET msgresp=kandoomsg("U",1001,"") 
	#1001 Enter selection criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON part_code, 
	desc_text, 
	short_desc_text, 
	status_date, 
	status_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","I15","construct-part_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp=kandoomsg("U",1002,"") 
		LET l_query_text = "SELECT * ", 
		"FROM product ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"part_code" 
		PREPARE s_product FROM l_query_text 
		DECLARE c_product CURSOR FOR s_product 
		RETURN true 
	END IF 
END FUNCTION  # select_product
}
