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
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

##- modular variable definition
	# Define array types that will be used in different functions (to pass array as arguments) 
	DEFINE t_arr_rec_prodstatus TYPE as RECORD
		scroll_flag CHAR(1), 
		part_code LIKE prodstatus.part_code, 
		desc_text LIKE product.desc_text,
		ware_code LIKE prodstatus.ware_code,
		warehouse_name LIKE warehouse.desc_text,
		onhand_qty LIKE prodstatus.onhand_qty, 
		reserved_qty LIKE prodstatus.reserved_qty, 
		avail LIKE prodstatus.onhand_qty, 
		status_date LIKE prodstatus.status_date, 
		status_ind LIKE prodstatus.status_ind
	END RECORD
	
	DEFINE t_arr_rec_prodstatus_aux TYPE AS RECORD	
		back_qty LIKE prodstatus.back_qty,	# stock back_qty out of the main array because needs intermediate calculations
		exists_in_warehouse SMALLINT			# 1 if product found in warehouse, 0 if not found ( because we do outer joins )
	END RECORD

	DEFINE t_rec_globalrec TYPE AS RECORD 
		parent_part_code LIKE product.part_code, 
		avail_qty LIKE prodstatus.onhand_qty, 
		favail_qty LIKE prodstatus.onhand_qty 
	END RECORD

	# DEFINE modu_arr_rec_prodstatus DYNAMIC ARRAY OF RECORD as the same TYPE 
	DEFINE modu_arr_rec_prodstatus DYNAMIC ARRAY OF t_arr_rec_prodstatus
	DEFINE modu_arr_rec_prodstatus_aux DYNAMIC ARRAY of t_arr_rec_prodstatus_aux
	

	DEFINE modu_rec_glparms RECORD LIKE glparms.*, 
	modu_rec_opparms RECORD LIKE opparms.*, 
	--modu_rec_product RECORD LIKE product.*, 
	--modu_rec_prodstatus RECORD LIKE prodstatus.*, 
	--modu_rec_backreas RECORD LIKE backreas.*, 
	--modu_rec_warehouse RECORD LIKE warehouse.*, 
	modu_temp_text CHAR(40) 

	# DEFINE CURSORS
	DEFINE crs_prodstatus_match_part_code CURSOR
	DEFINE crs_products_same_class CURSOR
	
	DEFINE cb_cat_code ui.ComboBox
	DEFINE cb_class_code ui.ComboBox
	DEFINE cb_dept_code ui.ComboBox
	DEFINE cb_maingrp_code ui.ComboBox
	DEFINE cb_prodgrp_code ui.ComboBox

####################################################################################
# MAIN
#
############################################################
# I16  Product Status Entry/Edit
# This program allows the user TO view product STATUS records
# AND change non crucial information
# Can pass part_code AND ware_code TO miss first SCREEN
#
####################################################################################
--MAIN 
FUNCTION I16_main()
	DEFINE l_which_products STRING
	DEFINE this_part_code LIKE product.part_code
	DEFINE l_edit_status INTEGER
	DEFINE l_sql_status INTEGER
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_backreas RECORD LIKE backreas.*
	DEFINE l_rec_globalrec t_rec_globalrec
	DEFINE query_text STRING
	SELECT unique 1 
	FROM inparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET msgresp = kandoomsg("I",5002,"") 
		#5002 Inventory Parameters are NOT SET up; Refer Menu IZP.
		EXIT program 
	END IF 

	SELECT * INTO modu_rec_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET msgresp = kandoomsg("U",5107,"") 
		#5107 General Ledger Parameters NOT SET up; Refer Menu GZP.
		EXIT program 
	END IF 

	SELECT cal_available_flag 
	INTO modu_rec_opparms.cal_available_flag 
	FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_rec_opparms.cal_available_flag = "N" 
	END IF 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		# prepare cursors and queries for product break
		LET query_text = "SELECT part_code,ware_code ",
		" FROM prodstatus WHERE cmpy_code = ? ",
		" AND part_code MATCHES ? ", 
		" AND ware_code = ? ",
		" AND part_code != ? "
		CALL crs_prodstatus_match_part_code.Declare(query_text)
	END IF
	
	LET query_text = "SELECT part_code ",
	" FROM product ",
	" WHERE part_code matches ? ",
	" AND cmpy_code = ?",
	" AND class_code = ? "
	CALL crs_products_same_class.Declare(query_text)	
	
	# Check if the program has been called by another program, passing the part_code as an argument
	LET this_part_code = get_url_product_part_code()
	CASE
		WHEN this_part_code IS NULL
		# The program has not been launched by another program
			OPEN WINDOW i613 with FORM "I613" 
			#   ATTRIBUTE(border)
			 CALL windecoration_i("I613") 
			WHILE TRUE
				DISPLAY "Please choose which products list you want to work on" TO lbinfo1
				MENU 
				COMMAND "List products assigned to a warehouse"
					LET l_which_products = "Assigned"
					EXIT MENU
				COMMAND "List products NOT assigned to a warehouse"
					LET l_which_products = "NotAssigned"
					EXIT MENU
				COMMAND "List ALL products"
					LET l_which_products = "AllProducts"
					EXIT MENU
				COMMAND "Exit"
					EXIT WHILE
				END MENU
				
				CALL construct_dataset_prodstatus(NULL,l_which_products) RETURNING modu_arr_rec_prodstatus,modu_arr_rec_prodstatus_aux
				CALL scan_dataset_pick_action_prodstatus(modu_arr_rec_prodstatus,modu_arr_rec_prodstatus_aux) 
			END WHILE 

			CLOSE WINDOW i613 
		
		WHEN this_part_code IS NOT NULL
			# The program HAS BEEN launched by another program
			OPEN WINDOW i614 with FORM "I614" 
			 CALL windecoration_i("I614") 

			CALL input_prodstatus("ADD",this_part_code,NULL) 
			RETURNING l_edit_status,l_rec_prodstatus.*,l_rec_product.*,	l_rec_backreas.*,l_rec_globalrec.*
			IF l_edit_status = 1 THEN
				CALL input_product_prices(l_rec_prodstatus.*,l_rec_product.*,l_rec_globalrec.*) 
				RETURNING l_edit_status,l_rec_prodstatus.*
				IF l_edit_status = 1 THEN
					CALL update_prodstatus("ADD",l_rec_prodstatus.*,l_rec_product.*,l_rec_backreas.*) RETURNING l_sql_status
					--EXIT WHILE 
				ELSE 
					--CALL preset_records_values("ADD",get_url_product_part_code(),"") 
					ERROR "INSERT Product Status FAILED!"
				END IF  
			END IF
			CLOSE WINDOW i614 
	END CASE
END FUNCTION  # I16_main       


####################################################################################
# FUNCTION construct_dataset_prodstatus(pr_part_code)
#
#
####################################################################################
FUNCTION construct_dataset_prodstatus(p_part_code,p_which_products) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_which_products STRING
	DEFINE l_which_products STRING
	DEFINE query_text,query_text_located,query_text_not_located STRING
	DEFINE where_text STRING 
	DEFINE idx smallint
	DEFINE l_arr_rec_prodstatus DYNAMIC ARRAY OF t_arr_rec_prodstatus
	DEFINE l_arr_rec_prodstatus_aux DYNAMIC ARRAY OF t_arr_rec_prodstatus_aux	
	DEFINE crs_construct_prodstatus CURSOR
	DEFINE l_qry_criteria_cat_code LIKE product.cat_code
	DEFINE l_qry_criteria_class_code LIKE product.class_code
	DEFINE l_qry_criteria_dept_code LIKE product.dept_code
	DEFINE l_qry_criteria_maingrp_code LIKE product.maingrp_code
	DEFINE l_qry_criteria_prodgrp_code LIKE product.prodgrp_code

	CALL l_arr_rec_prodstatus.Clear()
	CALL l_arr_rec_prodstatus_aux.Clear()
	CLEAR FORM
	IF p_part_code IS NULL THEN 
		# Running I16 from the kandoo menu
		LET msgresp=kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME where_text ON product.cat_code,
		product.class_code,
		product.dept_code,
		product.maingrp_code,
		product.prodgrp_code, 
		product.part_code, 
		product.desc_text,
		prodstatus.ware_code, 
		prodstatus.onhand_qty, 
		prodstatus.reserved_qty, 
		prodstatus.status_date, 
		prodstatus.status_ind 
		
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
	ELSE 
		# this function is called from another program, part_code has been passed as an URL argument
		LET where_text = "part_code = ", p_part_code 
	END IF 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	LET msgresp=kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.

	# pre-build both queries with a different query_text, so that they can be UNIONED in 3rd case
	# First, select products that are assigned to a warehouse
	LET query_text_located = "SELECT NULL::CHAR,",
	"product.part_code, ",
	"product.desc_text, ",
	"prodstatus.ware_code, ",
	"warehouse.desc_text, ",
	"prodstatus.onhand_qty,",
	"prodstatus.reserved_qty,",
	"NULL::INTEGER, ",
	"prodstatus.status_date,",
	"prodstatus.status_ind, ",
	"prodstatus.back_qty, ",
	"1::INTEGER ",
	" FROM prodstatus,product,warehouse ", 
	"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND prodstatus.cmpy_code = product.cmpy_code ",
	" AND prodstatus.part_code = product.part_code ",
	" AND prodstatus.cmpy_code = warehouse.cmpy_code ",
	" AND prodstatus.ware_code = warehouse.ware_code ",
	"AND ",where_text clipped

	# Second, select products that are NOT assigned to a warehouse
	LET query_text_not_located = "SELECT NULL::CHAR,",
	"product.part_code, ",
	"product.desc_text, ",
	"NULL::CHAR, ",
	"NULL::CHAR, ",
	"NULL::FLOAT, ",
	"NULL::FLOAT, ",
	"NULL::INTEGER, ",
	"NULL::DATE, ",
	"NULL::CHAR, ",
	"NULL::FLOAT, ",
	"0::INTEGER ",
	" FROM product ", 
	"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND product.part_code NOT IN (SELECT prodstatus.part_code FROM prodstatus WHERE cmpy_code = product.cmpy_code) ",
	"AND ",where_text clipped
	CASE 
		WHEN p_which_products = "Assigned"
			# Show only the product that are Assigned at least in one warehouse
			LET query_text = query_text_located,
			" ORDER BY product.part_code,prodstatus.ware_code" 
		WHEN p_which_products = "NotAssigned"
			# Show only the product that need to be Assigned in one warehouse ( they are not found in prodstatus)

			LET query_text = query_text_not_located,			
			" ORDER BY product.part_code" 
		
		WHEN p_which_products = "AllProducts"
			# Show products that are Assigned at least in one warehouse + products that need to be Assigned in one warehouse
			# USE SELECT UNION 
			LET query_text = query_text_located,
			" UNION ",
			query_text_not_located,
			" ORDER BY 2,4"
	 
		END CASE

	CALL crs_construct_prodstatus.Declare(query_text)
	
	CALL crs_construct_prodstatus.Open()
	LET idx = 1
	WHILE crs_construct_prodstatus.FetchNext(l_arr_rec_prodstatus[idx].*,l_arr_rec_prodstatus_aux[idx].*) = 0
		IF modu_rec_opparms.cal_available_flag = "N" THEN 
			LET l_arr_rec_prodstatus[idx].avail = l_arr_rec_prodstatus[idx].onhand_qty 
				- l_arr_rec_prodstatus[idx].reserved_qty 
				- l_arr_rec_prodstatus_aux[idx].back_qty 
		ELSE 
			LET l_arr_rec_prodstatus[idx].avail = l_arr_rec_prodstatus[idx].onhand_qty 
				- l_arr_rec_prodstatus[idx].reserved_qty 
		END IF
		LET idx = idx + 1
	END WHILE
	# Delete the last empty element of l_arr_rec_prodstatus
	CALL l_arr_rec_prodstatus.DeleteElement(idx)
	CALL l_arr_rec_prodstatus_aux.DeleteElement(idx)
	
	RETURN l_arr_rec_prodstatus,l_arr_rec_prodstatus_aux 
END FUNCTION 		# construct_dataset_prodstatus


####################################################################################
# FUNCTION scan_dataset_pick_action_prodstatus()
#
#
####################################################################################
FUNCTION scan_dataset_pick_action_prodstatus(p_arr_rec_prodstatus,p_arr_rec_prodstatus_aux) 
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE p_arr_rec_prodstatus DYNAMIC ARRAY OF t_arr_rec_prodstatus 
	DEFINE p_arr_rec_prodstatus_aux DYNAMIC ARRAY OF t_arr_rec_prodstatus_aux
	DEFINE l_rec_s_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_backreas RECORD LIKE backreas.*
	DEFINE l_rec_globalrec t_rec_globalrec
	DEFINE l_part_code LIKE product.part_code
	DEFINE l_match_part_code LIKE product.part_code
	DEFINE l_rec_class_code LIKE class.class_code
	DEFINE idx,arrcurr ,scrline SMALLINT
	DEFINE l_parent, l_filler, l_flex_part_code LIKE product.part_code
	DEFINE l_flex_num INTEGER
	DEFINE l_counter, l_part_length SMALLINT
	DEFINE l_part_search,err_message CHAR(40) 
	DEFINE l_edit_status SMALLINT		# return status of a form input operation
	DEFINE l_sql_status SMALLINT		# return status of a sql insert/update/delete operation

	OPTIONS SQL interrupt ON 
	--CALL modu_arr_rec_prodstatus.Clear()
	LET idx = 0

	OPTIONS SQL interrupt off 

	LET msgresp=kandoomsg("U",9113,idx) 

	LET msgresp=kandoomsg("I",1015,"") 
	#1015 F1 TO Add;  F2 TO Delete;  F5 Stock In Transit; F6 TO Make Available;
	#     F7 TO Hold;  F8 TO Stop Reorder;  ENTER on line TO Edit.

	INPUT ARRAY p_arr_rec_prodstatus WITHOUT DEFAULTS FROM sr_prodstatus.* ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, DELETE ROW = FALSE) 
	#DISPLAY ARRAY p_arr_rec_prodstatus TO sr_prodstatus.* ATTRIBUTE(UNBUFFERED)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I16","inp-arr-prodstatus-1") 
			CALL dialog.setActionHidden("INSERT",TRUE)
			CALL dialog.setActionHidden("DELETE",TRUE)
			CALL dialog.setActionHidden("APPEND",TRUE)
			CALL dialog.setActionHidden("EDIT",NOT p_arr_rec_prodstatus.getSize())
			CALL dialog.setActionHidden("DOUBLECLICK",NOT p_arr_rec_prodstatus.getSize())
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			DISPLAY "Select a product, then an action in the TOOLBAR" TO lbinfo1

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
			
		BEFORE ROW	
			LET idx = arr_curr()
			LET arrcurr = arr_curr() 
			LET scrline = scr_line()
			IF p_arr_rec_prodstatus_aux[idx].exists_in_warehouse = 0 THEN
				# We hide actions that are not possible for product to be assigned to a warehouse
				CALL dialog.setActionHidden("EDIT",1)
				CALL dialog.setActionHidden("TRANSIT STATUS",1)
				CALL dialog.setActionHidden("SET AVAILABLE",1)
				CALL dialog.setActionHidden("SET ON HOLD",1)
				CALL dialog.setActionHidden("STOP RE-ORDER",1)
			ELSE
				CALL dialog.setActionHidden("EDIT",0)
				CALL dialog.setActionHidden("TRANSIT STATUS",0)
				CALL dialog.setActionHidden("SET AVAILABLE",0)
				CALL dialog.setActionHidden("SET ON HOLD",0)
				CALL dialog.setActionHidden("STOP RE-ORDER",0)
			END IF				

		ON ACTION ("EDIT","DOUBLECLICK")
		#BEFORE FIELD part_code 
			--IF p_arr_rec_prodstatus[idx].part_code IS NOT NULL THEN
			IF p_arr_rec_prodstatus_aux[idx].exists_in_warehouse = 1 THEN	# If this product exists in that warehouse, we can modify prodstatus 
				--CALL preset_records_values("EDIT",p_arr_rec_prodstatus[idx].part_code,p_arr_rec_prodstatus[idx].ware_code)  
				--RETURNING l_rec_product.*,l_rec_prodstatus.*,l_rec_backreas.*,l_rec_globalrec.*

				OPEN WINDOW i614 with FORM "I614" 
				 CALL windecoration_i("I614") 

				CALL input_prodstatus("EDIT",p_arr_rec_prodstatus[idx].part_code,p_arr_rec_prodstatus[idx].ware_code)
				RETURNING l_edit_status,l_rec_prodstatus.*,l_rec_product.*,l_rec_backreas.*,l_rec_globalrec.*
				
				IF l_edit_status = 1 THEN
					--CALL input_product_prices(l_rec_s_prodstatus.*) RETURNING l_edit_status
					CALL input_product_prices(l_rec_prodstatus.*,l_rec_product.*,l_rec_globalrec.*) 
					RETURNING l_edit_status,l_rec_prodstatus.*
					IF l_edit_status = 1 THEN
						CALL update_prodstatus("EDIT",l_rec_prodstatus.*,l_rec_product.*,l_rec_backreas.*) RETURNING l_edit_status
						IF l_edit_status = 1 THEN
							ERROR "Update Product Status ran successfully!"
						ELSE
							ERROR "Update Prodstatus FAILED!"
							# check if preset is really necessary
							--CALL preset_records_values("EDIT", p_arr_rec_prodstatus[idx].part_code, p_arr_rec_prodstatus[idx].ware_code) 
							--RETURNING l_rec_product.*,l_rec_prodstatus.*,l_rec_backreas.*,l_rec_globalrec.*
						END IF		
					END IF 
				END IF 
				CLOSE WINDOW i614 
				OPTIONS DELETE KEY f36, 
				INSERT KEY f1 
			ELSE
				ERROR "we can enter the product in a warehouse"
			END IF 
			--NEXT FIELD scroll_flag 

		ON ACTION "TRANSIT STATUS"
		--ON KEY (F5) --show stock transit status (only view) 
			CALL show_stock_transit(glob_rec_kandoouser.cmpy_code, p_arr_rec_prodstatus[idx].part_code, p_arr_rec_prodstatus[idx].ware_code) 
			NEXT FIELD scroll_flag 

		ON ACTION "SET AVAILABLE"
		--ON KEY (F6) --change product status to: available (1) 
			CALL change_status_prodstatus(p_arr_rec_prodstatus[idx].part_code,	p_arr_rec_prodstatus[idx].ware_code, "1", idx) 
			RETURNING l_sql_status
			--NEXT FIELD scroll_flag 

		ON ACTION "SET ON HOLD"
		--ON KEY (F7) --change product status to: ON HOLD (2) 
			CALL change_status_prodstatus(p_arr_rec_prodstatus[idx].part_code, p_arr_rec_prodstatus[idx].ware_code, "2", idx) 
			RETURNING l_sql_status
			--NEXT FIELD scroll_flag 

		ON ACTION "STOP RE-ORDER"
		--ON KEY (F8) --change product status to: stop re-order (4) 
			CALL change_status_prodstatus(p_arr_rec_prodstatus[idx].part_code, p_arr_rec_prodstatus[idx].ware_code, "4", idx) 
			RETURNING l_sql_status
			--NEXT FIELD scroll_flag 

			#DISPLAY p_arr_rec_prodstatus[arrcurr].* TO sr_prodstatus[scrline].*

			SELECT desc_text,desc2_text 
			INTO l_rec_product.desc2_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_arr_rec_prodstatus[arrcurr].part_code 
			DISPLAY BY NAME l_rec_product.desc_text,l_rec_product.desc2_text  

		--BEFORE INSERT
		ON ACTION ("ASSIGN TO WAREHOUSE") 
			# Can be done for a product that has no warehouse OR assign the product to ANOTHER warehouse, we assign it to a warehouse
			IF arr_curr() < arr_count() THEN 
				OPEN WINDOW i614 with FORM "I614" 
				 CALL windecoration_i("I614") 

				CALL input_prodstatus("ADD",p_arr_rec_prodstatus[idx].part_code,NULL)  
				RETURNING l_edit_status,l_rec_prodstatus.*,l_rec_product.*,	l_rec_backreas.*,l_rec_globalrec.*
				IF l_edit_status > 0 THEN
					CALL input_product_prices(l_rec_prodstatus.*,l_rec_product.*,l_rec_globalrec.*) 
					RETURNING l_edit_status,l_rec_prodstatus.*

					IF l_edit_status > 0 THEN
						CALL update_prodstatus("ADD",l_rec_prodstatus.*,l_rec_product.*,l_rec_backreas.*) RETURNING l_sql_status
						IF l_edit_status > 0 THEN
							## MESSAGE UPDATE worked
							LET p_arr_rec_prodstatus[arrcurr].part_code = l_rec_prodstatus.part_code 
							LET p_arr_rec_prodstatus[arrcurr].ware_code = l_rec_prodstatus.ware_code 
							LET p_arr_rec_prodstatus[arrcurr].onhand_qty = 0 
							LET p_arr_rec_prodstatus[arrcurr].reserved_qty = 0 
							LET p_arr_rec_prodstatus[arrcurr].avail = 0 
							LET p_arr_rec_prodstatus[arrcurr].status_date = today 
							LET p_arr_rec_prodstatus[arrcurr].status_ind = "1" 
							ERROR "Update Product Status ran successfully!"
						ELSE 
							ERROR "The INSERT operation FAILED!"
							--CALL preset_records_values("ADD",modu_rec_prodstatus.part_code,modu_rec_prodstatus.ware_code) 
							--RETURNING l_rec_product.*,l_rec_prodstatus.*,l_rec_backreas.*,l_rec_globalrec.*
						END IF 
					END IF 
				END IF

				CLOSE WINDOW i614 

				IF p_arr_rec_prodstatus[arrcurr].part_code IS NULL THEN 
					## INSERT failed
					FOR idx = arrcurr TO p_arr_rec_prodstatus.GetSize() 
						IF p_arr_rec_prodstatus[idx + 1].part_code IS NULL THEN 
							INITIALIZE p_arr_rec_prodstatus[idx + 1].* TO NULL 
						END IF 
						LET p_arr_rec_prodstatus[idx].* = p_arr_rec_prodstatus[idx+1].* 
					END FOR 
					INITIALIZE p_arr_rec_prodstatus[arrcurr].* TO NULL 
				END IF 
			ELSE 
				LET msgresp = kandoomsg("I",9001,"") 
				#9001 There are no more rows in the direction you are going "
			END IF 
			NEXT FIELD scroll_flag 

		ON ACTION "DELETE"  --KEY (F2) 
			CALL change_status_prodstatus(p_arr_rec_prodstatus[arrcurr].part_code, p_arr_rec_prodstatus[arrcurr].ware_code, "3", arrcurr) 
			RETURN l_sql_status
			--NEXT FIELD scroll_flag 


			#AFTER ROW
			#   DISPLAY p_arr_rec_prodstatus[arrcurr].* TO sr_prodstatus[scrline].*
	END INPUT 
	#   LET int_flag = FALSE
	#   LET quit_flag = FALSE
END FUNCTION 		# scan_dataset_pick_action_prodstatus


####################################################################################
# FUNCTION preset_records_values(pr_mode,pr_part_code,pr_ware_code)
#
#
####################################################################################
FUNCTION preset_records_values(p_mode,p_part_code,p_ware_code) 
	DEFINE 	p_mode CHAR(4), 
	p_part_code LIKE prodstatus.part_code, 
	l_flex_part_code LIKE prodstatus.part_code, 
	p_ware_code LIKE prodstatus.ware_code
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_backreas RECORD LIKE backreas.*
	DEFINE l_rec_globalrec t_rec_globalrec
	DEFINE l_conv_factor FLOAT 
	##
	## Setup product RECORD - used FOR read only
	##
	IF p_part_code IS NOT NULL THEN 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET msgresp = kandoomsg("I",5010,"") 
			#5010 Logic error: Product code does NOT exist.
		END IF 
		SELECT 	desc_text, 
			sell_uom_code, 
			sell_uom_code, 
			sell_uom_code
		INTO l_rec_product.desc_text, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code
		FROM product
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND part_code = p_part_code
		
			IF sqlca.sqlcode = NOTFOUND THEN 
			LET msgresp = kandoomsg("I",5010,"") 
			#5010 Logic error: Product code does NOT exist.
		END IF 
		CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code,l_rec_product.class_code,1) 
		RETURNING l_rec_globalrec.parent_part_code, l_flex_part_code, modu_temp_text, modu_temp_text # VALUES returned 
	END IF 
	##
	## Setup prodstatus RECORD - used FOR INSERT OR UPDATE
	##
	INITIALIZE l_rec_prodstatus.* TO NULL 
	CASE 
		WHEN p_mode = "ADD"
			LET l_rec_prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_prodstatus.part_code = p_part_code 
			LET l_rec_prodstatus.ware_code = p_ware_code 
			LET l_rec_prodstatus.onhand_qty = 0 
			LET l_rec_prodstatus.back_qty = 0 
			LET l_rec_prodstatus.transit_qty = 0 
			LET l_rec_prodstatus.onord_qty = 0 
			LET l_rec_prodstatus.reserved_qty = 0 
			LET l_rec_prodstatus.forward_qty = 0 
			LET l_rec_prodstatus.reorder_point_qty = 0 
			LET l_rec_prodstatus.reorder_qty = 0 
			LET l_rec_prodstatus.critical_qty = 0 
			LET l_rec_prodstatus.max_qty = 0 
			LET l_rec_prodstatus.special_flag = "N" 
			LET l_rec_prodstatus.sale_tax_amt = 0 
			LET l_rec_prodstatus.purch_tax_amt = 0 
			LET l_rec_prodstatus.sale_tax_code = NULL 
			LET l_rec_prodstatus.purch_tax_code = NULL 
			LET l_rec_prodstatus.est_cost_amt = 0 
			LET l_rec_prodstatus.act_cost_amt = 0 
			LET l_rec_prodstatus.wgted_cost_amt = 0 
			LET l_rec_prodstatus.for_cost_amt = 0 
			LET l_rec_prodstatus.for_curr_code = modu_rec_glparms.base_currency_code 
			LET l_rec_prodstatus.stocked_flag = "Y" 
			LET l_rec_prodstatus.nonstk_pick_flag = "Y" 
			LET l_rec_prodstatus.status_ind = "1" 
			LET l_rec_prodstatus.status_date = today 
			LET l_rec_prodstatus.last_sale_date = today 
			LET l_rec_prodstatus.last_cost_date = today 
			LET l_rec_prodstatus.last_price_date = today 
			LET l_rec_prodstatus.last_list_date = today 
			LET l_rec_prodstatus.last_receipt_date = today 
			LET l_rec_prodstatus.last_stcktake_date = today 
			LET l_rec_prodstatus.seq_num = 0 
			LET l_rec_prodstatus.phys_count_qty = 0 
			LET l_rec_prodstatus.stcktake_days = 0 
			LET l_rec_prodstatus.min_ord_qty = 0 
			LET l_rec_prodstatus.replenish_ind = NULL 
			LET l_rec_prodstatus.abc_ind = "A" 
			LET l_rec_prodstatus.avg_qty = 0 
			LET l_rec_prodstatus.avg_cost_amt = 0 
			LET l_rec_prodstatus.stockturn_qty = 0 
			LET l_rec_prodstatus.list_amt = 0 
			LET l_rec_prodstatus.price1_amt = 0 
			LET l_rec_prodstatus.price2_amt = 0 
			LET l_rec_prodstatus.price3_amt = 0 
			LET l_rec_prodstatus.price4_amt = 0 
			LET l_rec_prodstatus.price5_amt = 0 
			LET l_rec_prodstatus.price6_amt = 0 
			LET l_rec_prodstatus.price7_amt = 0 
			LET l_rec_prodstatus.price8_amt = 0 
			LET l_rec_prodstatus.price9_amt = 0 
	WHEN p_mode = "EDIT" 
		## Setup warehouse RECORD - used FOR read only
		SET ISOLATION TO REPEATABLE READ
		SELECT part_code, 
			ware_code, 
			onhand_qty, 
			reserved_qty, 
			onord_qty, 
			back_qty, 
			forward_qty, 
			reorder_point_qty, 
			reorder_qty, 
			max_qty, 
			critical_qty, 
			bin1_text, 
			bin2_text, 
			bin3_text, 
			stocked_flag, 
			nonstk_pick_flag, 
			abc_ind, 
			replenish_ind, 
			last_sale_date, 
			last_receipt_date, 
			last_stcktake_date, 
			stockturn_qty, 
			avg_qty
		INTO l_rec_prodstatus.part_code, 
			l_rec_prodstatus.ware_code, 
			l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.reserved_qty, 
			l_rec_prodstatus.onord_qty, 
			l_rec_prodstatus.back_qty, 
			l_rec_prodstatus.forward_qty, 
			l_rec_prodstatus.reorder_point_qty, 
			l_rec_prodstatus.reorder_qty, 
			l_rec_prodstatus.max_qty, 
			l_rec_prodstatus.critical_qty, 
			l_rec_prodstatus.bin1_text, 
			l_rec_prodstatus.bin2_text, 
			l_rec_prodstatus.bin3_text, 
			l_rec_prodstatus.stocked_flag, 
			l_rec_prodstatus.nonstk_pick_flag, 
			l_rec_prodstatus.abc_ind, 
			l_rec_prodstatus.replenish_ind, 
			l_rec_prodstatus.last_sale_date, 
			l_rec_prodstatus.last_receipt_date, 
			l_rec_prodstatus.last_stcktake_date, 
			l_rec_prodstatus.stockturn_qty, 
			l_rec_prodstatus.avg_qty
		FROM prodstatus
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND part_code = p_part_code
			AND ware_code = p_ware_code
		IF sqlca.sqlcode = NOTFOUND THEN 
			error" Logic Error: Product STATUS RECORD NOT found" 
		END IF 

		# check to select those values
		-- 	l_rec_backreas.exp_date, 
		--	l_rec_backreas.reason_text, 
		##
		## Convert prices INTO Price UOM FOR ediiting
		##
		IF l_rec_product.sell_uom_code <> l_rec_product.price_uom_code THEN 
			LET l_conv_factor = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code,l_rec_product.sell_uom_code,l_rec_product.price_uom_code,1) 
			IF l_conv_factor > 0 THEN 
				LET l_rec_prodstatus.list_amt = l_rec_prodstatus.list_amt * l_conv_factor 
				LET l_rec_prodstatus.price1_amt = l_rec_prodstatus.price1_amt * l_conv_factor 
				LET l_rec_prodstatus.price2_amt = l_rec_prodstatus.price2_amt * l_conv_factor 
				LET l_rec_prodstatus.price3_amt = l_rec_prodstatus.price3_amt * l_conv_factor 
				LET l_rec_prodstatus.price4_amt = l_rec_prodstatus.price4_amt * l_conv_factor 
				LET l_rec_prodstatus.price5_amt = l_rec_prodstatus.price5_amt * l_conv_factor 
				LET l_rec_prodstatus.price6_amt = l_rec_prodstatus.price6_amt * l_conv_factor 
				LET l_rec_prodstatus.price7_amt = l_rec_prodstatus.price7_amt * l_conv_factor 
				LET l_rec_prodstatus.price8_amt = l_rec_prodstatus.price8_amt * l_conv_factor 
				LET l_rec_prodstatus.price9_amt = l_rec_prodstatus.price9_amt * l_conv_factor 
			END IF 
		END IF 

	END CASE
	##
	## Setup backread RECORD - used FOR INSERT OR UPDATE
	SELECT exp_date, 
		reason_text
	INTO l_rec_backreas.exp_date, 
		l_rec_backreas.reason_text
	FROM backreas
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
		AND part_code = p_part_code
		AND ware_code = p_ware_code
	
	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_rec_backreas.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_backreas.part_code = l_rec_prodstatus.part_code 
		LET l_rec_backreas.ware_code = l_rec_prodstatus.ware_code 
		LET l_rec_backreas.exp_date = NULL 
		LET l_rec_backreas.reason_text = NULL 
	END IF 
	IF modu_rec_opparms.cal_available_flag = "N" THEN 
		LET l_rec_globalrec.avail_qty = l_rec_prodstatus.onhand_qty 
		- l_rec_prodstatus.reserved_qty 
		- l_rec_prodstatus.back_qty 
	ELSE 
		LET l_rec_globalrec.avail_qty = l_rec_prodstatus.onhand_qty 
		- l_rec_prodstatus.reserved_qty 
	END IF 
	LET l_rec_globalrec.favail_qty = l_rec_globalrec.avail_qty 
	+ l_rec_prodstatus.onord_qty 
	- l_rec_prodstatus.forward_qty 
	RETURN l_rec_product.*,l_rec_prodstatus.*,l_rec_backreas.*,l_rec_globalrec.*
END FUNCTION 		# preset_records_values


####################################################################################
# FUNCTION update_prodstatus(pr_mode)
#
#
####################################################################################
FUNCTION update_prodstatus(p_mode,p_rec_prodstatus,p_rec_product,p_rec_backreas) 
	DEFINE p_mode CHAR(4) 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE p_rec_backreas RECORD LIKE backreas.*
	DEFINE l_rec_t_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_u_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_globalrec t_rec_globalrec
	DEFINE l_flex_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 

	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE err_message CHAR(40) 
	DEFINE l_conv_factor FLOAT 

	CALL break_prod(glob_rec_kandoouser.cmpy_code,p_rec_product.part_code,p_rec_product.class_code,1) 
	RETURNING l_rec_globalrec.parent_part_code, l_flex_part_code, modu_temp_text, modu_temp_text # VALUES returned 
	IF p_rec_product.sell_uom_code <> p_rec_product.price_uom_code THEN 
		## Convert prices back INTO sell UOM
		LET l_conv_factor = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,p_rec_prodstatus.part_code, 
		l_rec_product.price_uom_code, 
		l_rec_product.sell_uom_code,1) 
		IF l_conv_factor > 0 THEN 
			LET p_rec_prodstatus.list_amt = p_rec_prodstatus.list_amt * l_conv_factor 
			LET p_rec_prodstatus.price1_amt = p_rec_prodstatus.price1_amt * l_conv_factor 
			LET p_rec_prodstatus.price2_amt = p_rec_prodstatus.price2_amt * l_conv_factor 
			LET p_rec_prodstatus.price3_amt = p_rec_prodstatus.price3_amt * l_conv_factor 
			LET p_rec_prodstatus.price4_amt = p_rec_prodstatus.price4_amt * l_conv_factor 
			LET p_rec_prodstatus.price5_amt = p_rec_prodstatus.price5_amt * l_conv_factor 
			LET p_rec_prodstatus.price6_amt = p_rec_prodstatus.price6_amt * l_conv_factor 
			LET p_rec_prodstatus.price7_amt = p_rec_prodstatus.price7_amt * l_conv_factor 
			LET p_rec_prodstatus.price8_amt = p_rec_prodstatus.price8_amt * l_conv_factor 
			LET p_rec_prodstatus.price9_amt = p_rec_prodstatus.price9_amt * l_conv_factor 
		END IF 
	END IF 

	IF p_rec_prodstatus.list_amt IS NULL THEN 
		LET p_rec_prodstatus.list_amt = 0 
	END IF 
	IF p_rec_prodstatus.price1_amt IS NULL THEN 
		LET p_rec_prodstatus.price1_amt = 0 
	END IF 
	IF p_rec_prodstatus.price2_amt IS NULL THEN 
		LET p_rec_prodstatus.price2_amt = 0 
	END IF 
	IF p_rec_prodstatus.price3_amt IS NULL THEN 
		LET p_rec_prodstatus.price3_amt = 0 
	END IF 
	IF p_rec_prodstatus.price4_amt IS NULL THEN 
		LET p_rec_prodstatus.price4_amt = 0 
	END IF 
	IF p_rec_prodstatus.price5_amt IS NULL THEN 
		LET p_rec_prodstatus.price5_amt = 0 
	END IF 
	IF p_rec_prodstatus.price6_amt IS NULL THEN 
		LET p_rec_prodstatus.price6_amt = 0 
	END IF 
	IF p_rec_prodstatus.price7_amt IS NULL THEN 
		LET p_rec_prodstatus.price7_amt = 0 
	END IF 
	IF p_rec_prodstatus.price8_amt IS NULL THEN 
		LET p_rec_prodstatus.price8_amt = 0 
	END IF 
	IF p_rec_prodstatus.price9_amt IS NULL THEN 
		LET p_rec_prodstatus.price9_amt = 0 
	END IF 
	IF p_rec_prodstatus.est_cost_amt IS NULL THEN 
		LET p_rec_prodstatus.est_cost_amt = 0 
	END IF 
	IF p_rec_prodstatus.act_cost_amt IS NULL THEN 
		LET p_rec_prodstatus.act_cost_amt = 0 
	END IF 
	IF p_rec_prodstatus.wgted_cost_amt IS NULL THEN 
		LET p_rec_prodstatus.wgted_cost_amt = 0 
	END IF 
	IF p_rec_prodstatus.for_cost_amt IS NULL THEN 
		LET p_rec_prodstatus.for_cost_amt = 0 
	END IF 

	# Replace the check done by SQL with ON CHANGE of those fields in the INPUT prices sequence
	{
	SELECT list_amt,price1_amt,price2_amt,price3_amt,price4_amt,price5_amt,price6_amt,price7_amt,price8_amt,price9_amt,
		est_cost_amt,act_cost_amt,wgted_cost_amt,for_cost_amt
	INTO l_rec_u_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_rec_prodstatus.part_code 
		AND ware_code = p_rec_prodstatus.ware_code 
	IF p_rec_prodstatus.list_amt <> l_rec_u_prodstatus.list_amt 
	OR p_rec_prodstatus.price1_amt <> l_rec_u_prodstatus.price1_amt 
	OR p_rec_prodstatus.price2_amt <> l_rec_u_prodstatus.price2_amt 
	OR p_rec_prodstatus.price3_amt <> l_rec_u_prodstatus.price3_amt 
	OR p_rec_prodstatus.price4_amt <> l_rec_u_prodstatus.price4_amt 
	OR p_rec_prodstatus.price5_amt <> l_rec_u_prodstatus.price5_amt 
	OR p_rec_prodstatus.price6_amt <> l_rec_u_prodstatus.price6_amt 
	OR p_rec_prodstatus.price7_amt <> l_rec_u_prodstatus.price7_amt 
	OR p_rec_prodstatus.price8_amt <> l_rec_u_prodstatus.price8_amt 
	OR p_rec_prodstatus.price9_amt <> l_rec_u_prodstatus.price9_amt THEN 
		LET p_rec_prodstatus.last_price_date = today 
	END IF 
	IF p_rec_prodstatus.list_amt <> l_rec_u_prodstatus.list_amt THEN 
		LET p_rec_prodstatus.last_list_date = today 
	END IF 
	IF p_rec_prodstatus.est_cost_amt <> l_rec_u_prodstatus.est_cost_amt 
	OR p_rec_prodstatus.act_cost_amt <> l_rec_u_prodstatus.act_cost_amt 
	OR p_rec_prodstatus.wgted_cost_amt <> l_rec_u_prodstatus.wgted_cost_amt 
	OR p_rec_prodstatus.for_cost_amt <> l_rec_u_prodstatus.for_cost_amt THEN 
		LET p_rec_prodstatus.last_cost_date = today 
	END IF 
	}
	BEGIN WORK 
		WHENEVER SQLERRROR CONTINUE
		IF p_mode = "ADD" THEN
			INSERT INTO prodstatus VALUES (p_rec_prodstatus.*) 
			IF sqlca.sqlcode < 0 THEN
				ERROR "Insert has FAILED!"
				ROLLBACK WORK
				RETURN FALSE
			ELSE
				ERROR "Insert product status successful"
			END IF
		ELSE 
			UPDATE prodstatus 
			SET reorder_point_qty = p_rec_prodstatus.reorder_point_qty, 
				reorder_qty = p_rec_prodstatus.reorder_qty, 
				max_qty = p_rec_prodstatus.max_qty, 
				critical_qty = p_rec_prodstatus.critical_qty, 
				special_flag = p_rec_prodstatus.special_flag, 
				sale_tax_amt = p_rec_prodstatus.sale_tax_amt, 
				purch_tax_amt = p_rec_prodstatus.purch_tax_amt, 
				sale_tax_code = p_rec_prodstatus.sale_tax_code, 
				purch_tax_code = p_rec_prodstatus.purch_tax_code, 
				last_price_date = p_rec_prodstatus.last_price_date, 
				last_list_date = p_rec_prodstatus.last_list_date, 
				est_cost_amt = p_rec_prodstatus.est_cost_amt, 
				act_cost_amt = p_rec_prodstatus.act_cost_amt, 
				wgted_cost_amt = p_rec_prodstatus.wgted_cost_amt, 
				for_cost_amt = p_rec_prodstatus.for_cost_amt, 
				for_curr_code = p_rec_prodstatus.for_curr_code, 
				last_cost_date = p_rec_prodstatus.last_cost_date, 
				bin1_text = p_rec_prodstatus.bin1_text, 
				bin2_text = p_rec_prodstatus.bin2_text, 
				bin3_text = p_rec_prodstatus.bin3_text, 
				last_sale_date = p_rec_prodstatus.last_sale_date, 
				last_receipt_date = p_rec_prodstatus.last_receipt_date, 
				stocked_flag = p_rec_prodstatus.stocked_flag, 
				min_ord_qty = p_rec_prodstatus.min_ord_qty, 
				abc_ind = p_rec_prodstatus.abc_ind, 
				avg_qty = p_rec_prodstatus.avg_qty, 
				avg_cost_amt = p_rec_prodstatus.avg_cost_amt, 
				stockturn_qty = p_rec_prodstatus.stockturn_qty, 
				status_ind = p_rec_prodstatus.status_ind, 
				status_date = p_rec_prodstatus.status_date, 
				nonstk_pick_flag = p_rec_prodstatus.nonstk_pick_flag, 
				replenish_ind = p_rec_prodstatus.replenish_ind, 
				list_amt = p_rec_prodstatus.list_amt, 
				pricel_ind = p_rec_prodstatus.pricel_ind, 
				pricel_per = p_rec_prodstatus.pricel_per, 
				price1_amt = p_rec_prodstatus.price1_amt, 
				price1_ind = p_rec_prodstatus.price1_ind, 
				price1_per = p_rec_prodstatus.price1_per, 
				price2_amt = p_rec_prodstatus.price2_amt, 
				price2_ind = p_rec_prodstatus.price2_ind, 
				price2_per = p_rec_prodstatus.price2_per, 
				price3_amt = p_rec_prodstatus.price3_amt, 
				price3_ind = p_rec_prodstatus.price3_ind, 
				price3_per = p_rec_prodstatus.price3_per, 
				price4_amt = p_rec_prodstatus.price4_amt, 
				price4_ind = p_rec_prodstatus.price4_ind, 
				price4_per = p_rec_prodstatus.price4_per, 
				price5_amt = p_rec_prodstatus.price5_amt, 
				price5_ind = p_rec_prodstatus.price5_ind, 
				price5_per = p_rec_prodstatus.price5_per, 
				price6_amt = p_rec_prodstatus.price6_amt, 
				price6_ind = p_rec_prodstatus.price6_ind, 
				price6_per = p_rec_prodstatus.price6_per, 
				price7_amt = p_rec_prodstatus.price7_amt, 
				price7_ind = p_rec_prodstatus.price7_ind, 
				price7_per = p_rec_prodstatus.price7_per, 
				price8_amt = p_rec_prodstatus.price8_amt, 
				price8_ind = p_rec_prodstatus.price8_ind, 
				price8_per = p_rec_prodstatus.price8_per, 
				price9_amt = p_rec_prodstatus.price9_amt, 
				price9_ind = p_rec_prodstatus.price9_ind, 
				price9_per = p_rec_prodstatus.price9_per 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_rec_prodstatus.part_code 
				AND ware_code = p_rec_prodstatus.ware_code 
				
			IF sqlca.sqlcode < 0 THEN 
				LET err_message = "I16 - Status Update FAILED!" 
				ROLLBACK WORK
				RETURN FALSE 
			END IF
			IF sqlca.sqlerrd[3] != 1 THEN 
				LET err_message = "I16 - Status Update FAILED! (no row found)" 
				ROLLBACK WORK
				RETURN FALSE 
			END IF 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			##
			## IF this product IS a parent product THEN UPDATE all
			## children TO have the same prices.
			##
			INITIALIZE l_rec_class.* TO NULL 
			SELECT * INTO l_rec_class.* 
			FROM class 
			WHERE cmpy_code = p_rec_product.cmpy_code 
			AND class_code = p_rec_product.class_code 
			IF l_rec_class.ord_level_ind IS NULL THEN 
				LET l_rec_class.ord_level_ind = 1 
			END IF 
			IF l_rec_class.price_level_ind IS NULL THEN 
				LET l_rec_class.price_level_ind = 1 
			END IF 
			IF l_rec_class.stock_level_ind IS NULL THEN 
				LET l_rec_class.stock_level_ind = 1 
			END IF 
			
			# IF product = parent AND structure IS truely segmented (ie NOT
			# 1 1 1 OR 2 2 2 OR 3 3 3 etc) THEN dont UPDATE child prices.
			IF l_rec_globalrec.parent_part_code = p_rec_prodstatus.part_code AND l_rec_class.price_level_ind != l_rec_class.stock_level_ind THEN 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
					LET modu_temp_text = p_rec_prodstatus.part_code clipped,"*" 
					{
					DECLARE crs_prodstatus_match_part_code CURSOR FOR 
					SELECT * FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code matches modu_temp_text 
					AND ware_code = p_rec_prodstatus.ware_code 
					AND part_code != p_rec_prodstatus.part_code 
					FOR UPDATE 
					}
					CALL crs_prodstatus_match_part_code.Open(glob_rec_kandoouser.cmpy_code,modu_temp_text,p_rec_prodstatus.ware_code,p_rec_prodstatus.part_code)
					WHILE (crs_prodstatus_match_part_code.FetchNext(l_rec_t_prodstatus.part_code,l_rec_t_prodstatus.ware_code) = 0)
					--FOREACH crs_prodstatus_match_part_code INTO l_rec_t_prodstatus.* 
						
						SELECT sell_uom_code 
						INTO l_rec_product.sell_uom_code
						--INTO l_rec_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_t_prodstatus.part_code 
						
						IF l_rec_product.sell_uom_code <> l_rec_product.sell_uom_code THEN 
							## Convert product FROM parent sell uom code TO child
							## sell uom code ##
							LET l_conv_factor = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code, 
							l_rec_product.sell_uom_code, 
							l_rec_product.sell_uom_code,1) 
							IF l_conv_factor > 0 THEN 
								LET p_rec_prodstatus.list_amt = p_rec_prodstatus.list_amt * l_conv_factor 
								LET p_rec_prodstatus.price1_amt = p_rec_prodstatus.price1_amt * l_conv_factor 
								LET p_rec_prodstatus.price2_amt = p_rec_prodstatus.price2_amt * l_conv_factor 
								LET p_rec_prodstatus.price3_amt = p_rec_prodstatus.price3_amt * l_conv_factor 
								LET p_rec_prodstatus.price4_amt = p_rec_prodstatus.price4_amt * l_conv_factor 
								LET p_rec_prodstatus.price5_amt = p_rec_prodstatus.price5_amt * l_conv_factor 
								LET p_rec_prodstatus.price6_amt = p_rec_prodstatus.price6_amt * l_conv_factor 
								LET p_rec_prodstatus.price7_amt = p_rec_prodstatus.price7_amt * l_conv_factor 
								LET p_rec_prodstatus.price8_amt = p_rec_prodstatus.price8_amt * l_conv_factor 
								LET p_rec_prodstatus.price9_amt = p_rec_prodstatus.price9_amt * l_conv_factor 
							END IF 
						END IF 

						UPDATE prodstatus 
						SET list_amt = p_rec_prodstatus.list_amt, 
							pricel_ind = p_rec_prodstatus.pricel_ind, 
							pricel_per = p_rec_prodstatus.pricel_per, 
							price1_amt = p_rec_prodstatus.price1_amt, 
							price1_ind = p_rec_prodstatus.price1_ind, 
							price1_per = p_rec_prodstatus.price1_per, 
							price2_amt = p_rec_prodstatus.price2_amt, 
							price2_ind = p_rec_prodstatus.price2_ind, 
							price2_per = p_rec_prodstatus.price2_per, 
							price3_amt = p_rec_prodstatus.price3_amt, 
							price3_ind = p_rec_prodstatus.price3_ind, 
							price3_per = p_rec_prodstatus.price3_per, 
							price4_amt = p_rec_prodstatus.price4_amt, 
							price4_ind = p_rec_prodstatus.price4_ind, 
							price4_per = p_rec_prodstatus.price4_per, 
							price5_amt = p_rec_prodstatus.price5_amt, 
							price5_ind = p_rec_prodstatus.price5_ind, 
							price5_per = p_rec_prodstatus.price5_per, 
							price6_amt = p_rec_prodstatus.price6_amt, 
							price6_ind = p_rec_prodstatus.price6_ind, 
							price6_per = p_rec_prodstatus.price6_per, 
							price7_amt = p_rec_prodstatus.price7_amt, 
							price7_ind = p_rec_prodstatus.price7_ind, 
							price7_per = p_rec_prodstatus.price7_per, 
							price8_amt = p_rec_prodstatus.price8_amt, 
							price8_ind = p_rec_prodstatus.price8_ind, 
							price8_per = p_rec_prodstatus.price8_per, 
							price9_amt = p_rec_prodstatus.price9_amt, 
							price9_ind = p_rec_prodstatus.price9_ind, 
							price9_per = p_rec_prodstatus.price9_per, 
							est_cost_amt = p_rec_prodstatus.est_cost_amt, 
							act_cost_amt = p_rec_prodstatus.act_cost_amt, 
							for_curr_code = p_rec_prodstatus.for_curr_code, 
							for_cost_amt = p_rec_prodstatus.for_cost_amt, 
							sale_tax_code = p_rec_prodstatus.sale_tax_code, 
							purch_tax_code = p_rec_prodstatus.purch_tax_code, 
							sale_tax_amt = p_rec_prodstatus.sale_tax_amt, 
							purch_tax_amt = p_rec_prodstatus.purch_tax_amt, 
							last_cost_date = p_rec_prodstatus.last_cost_date, 
							last_price_date = p_rec_prodstatus.last_price_date, 
							last_list_date = p_rec_prodstatus.last_list_date 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = l_rec_t_prodstatus.part_code 
							AND ware_code = l_rec_t_prodstatus.ware_code 

						IF sqlca.sqlcode < 0 THEN 
							LET err_message = "I16 - Status Update FAILED!" 
							ROLLBACK WORK
							RETURN FALSE 
						END IF
						IF sqlca.sqlerrd[3] != 1 THEN 
							LET err_message = "I16 - Status Update FAILED! (no row found)" 
							ROLLBACK WORK
							RETURN FALSE 
						END IF
					END WHILE
					--END FOREACH 
				END IF 
			END IF 

			DELETE FROM backreas 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_prodstatus.part_code 
			AND ware_code = p_rec_prodstatus.ware_code
			IF sqlca.sqlcode < 0 THEN 
				LET err_message = "I16 - Delete backreas FAILED!" 
				ROLLBACK WORK
				RETURN FALSE 
			END IF
 
		END IF 
		IF p_rec_backreas.exp_date IS NOT NULL OR p_rec_backreas.reason_text IS NOT NULL THEN 
			INSERT INTO backreas VALUES (p_rec_backreas.*)
			IF sqlca.sqlcode < 0 THEN 
				LET err_message = "I16 - Insert into backreas FAILED!" 
				ROLLBACK WORK
				RETURN FALSE 
			END IF
		END IF 
		# maybe some SQL test here before committing ? ericv
	COMMIT WORK 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	ERROR "The product status has been successfully updated"
	RETURN true 
END FUNCTION 	# update_prodstatus


####################################################################################
# FUNCTION input_prodstatus(pr_mode)
#
#
####################################################################################
FUNCTION input_prodstatus(p_mode,p_part_code,p_ware_code) 
	DEFINE p_mode CHAR(4)
	DEFINE p_part_code LIKE prodstatus.part_code
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.*
	DEFINE l_rec_backreas RECORD LIKE backreas.* 
	DEFINE l_rec_globalrec t_rec_globalrec
	DEFINE l_parent, l_filler, l_flex_part_code LIKE prodstatus.part_code 
	DEFINE l_flex_num INTEGER 

	CLEAR FORM
	INITIALIZE l_rec_prodstatus.* TO NULL 
	INITIALIZE l_rec_product.* TO NULL
	INITIALIZE l_rec_warehouse.* TO NULL
	-- IF p_part_code IS NOT NULL AND p_ware_code IS NOT NULL THEN
	IF p_part_code IS NOT NULL THEN
		SET ISOLATION TO REPEATABLE READ

		CALL preset_records_values(p_mode,p_part_code,p_ware_code)  
		RETURNING l_rec_product.*,l_rec_prodstatus.*,l_rec_backreas.*,l_rec_globalrec.*


		DISPLAY l_rec_product.desc_text, 
			l_rec_warehouse.desc_text, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code, 
			l_rec_product.sell_uom_code, 
		l_rec_globalrec.avail_qty, 
		l_rec_globalrec.avail_qty, 
		l_rec_globalrec.favail_qty 
		TO product.desc_text, 
		warehouse.desc_text, 
		sr_stock[1].stock_uom_code, 
		sr_stock[2].stock_uom_code, 
		sr_stock[3].stock_uom_code, 
		sr_avail[1].avail_qty, 
		sr_avail[2].avail_qty, 
		favail_qty 
	END IF

	IF l_rec_product.serial_flag = 'Y' THEN 
		LET msgresp=kandoomsg("I",1052,"") 
		#1052 Enter Warehouse Details; F9 FOR Serial Details; OK TO C
	ELSE 
		LET msgresp=kandoomsg("I",1016,"") 
		#1016 Enter product/warehouse details;  OK TO Continue.
	END IF 
	INPUT BY NAME l_rec_prodstatus.part_code, 
		l_rec_prodstatus.ware_code, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.onord_qty, 
		l_rec_prodstatus.back_qty, 
		l_rec_prodstatus.forward_qty, 
		l_rec_prodstatus.reorder_point_qty, 
		l_rec_prodstatus.reorder_qty, 
		l_rec_prodstatus.max_qty, 
		l_rec_prodstatus.critical_qty, 
		l_rec_prodstatus.bin1_text, 
		l_rec_prodstatus.bin2_text, 
		l_rec_prodstatus.bin3_text, 
		l_rec_prodstatus.stocked_flag, 
		l_rec_prodstatus.nonstk_pick_flag, 
		l_rec_prodstatus.abc_ind, 
		l_rec_prodstatus.replenish_ind, 
		l_rec_prodstatus.last_sale_date, 
		l_rec_prodstatus.last_receipt_date, 
		l_rec_prodstatus.last_stcktake_date, 
		l_rec_backreas.exp_date, 
		l_rec_backreas.reason_text, 
		l_rec_prodstatus.stockturn_qty, 
		l_rec_prodstatus.avg_qty 
		WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I16","inp-prodstatus-1")
			CALL DIALOG.SetFieldActive("part_code", false)      # part_code is never input 
			IF p_mode = "EDIT" THEN
				## replaces the next field next next field previous before field
				CALL DIALOG.SetFieldActive("ware_code", false)
			END IF
			DISPLAY "Please input data starting from Reorder:Point" TO lbinfo1		

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		--ON KEY (control-b) infield (part_code) 
		ON ACTION ("LOOKUP","control-b") infield (part_code)
			LET modu_temp_text = show_item(glob_rec_kandoouser.cmpy_code) 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_prodstatus.part_code = modu_temp_text 
			END IF 
			NEXT FIELD part_code 

		ON ACTION ("LOOKUP","control-b") infield (ware_code) 
			LET modu_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF modu_temp_text IS NOT NULL THEN 
				LET l_rec_prodstatus.ware_code = modu_temp_text 
			END IF 
			NEXT FIELD ware_code 

		--ON KEY (F9)
		ON ACTION ("SerialInquiry","F9") 
			IF l_rec_product.serial_flag = 'Y' THEN 
				CALL run_prog("I33",l_rec_product.part_code, 
				l_rec_prodstatus.ware_code,"","") 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

		AFTER FIELD part_code 
			IF l_rec_prodstatus.part_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9013,"") 
				#9013 Product must be entered
				NEXT FIELD part_code 
			ELSE 
				SELECT part_code, desc_text,class_code,
					status_ind,sell_uom_code,stock_uom_code
				INTO l_rec_product.part_code,l_rec_product.desc_text,l_rec_product.class_code,
					l_rec_product.status_ind,l_rec_product.sell_uom_code,l_rec_product.stock_uom_code
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_prodstatus.part_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9010,"") 
					#9010 " Product NOT found, try again"
					NEXT FIELD part_code 
				ELSE 
					IF l_rec_product.status_ind = "3" THEN 
						LET msgresp = kandoomsg("I",9511,"") 
						#9511 This product has been deleted
						NEXT FIELD part_code 
					END IF 
					CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code, 
					l_rec_product.class_code,1) 
					RETURNING l_rec_globalrec.parent_part_code, 
					modu_temp_text, # 
					modu_temp_text, # no NOT require other 
					modu_temp_text # VALUES returned 
					DISPLAY l_rec_product.desc_text, 
					l_rec_product.sell_uom_code, 
					l_rec_product.sell_uom_code, 
					l_rec_product.sell_uom_code 
					TO product.desc_text, 
					sr_stock[1].stock_uom_code, 
					sr_stock[2].stock_uom_code, 
					sr_stock[3].stock_uom_code 

				END IF 
			END IF 

		-- BEFORE FIELD ware_code # Replaced by setfieldActive -> false 

		AFTER FIELD ware_code 
			IF l_rec_prodstatus.ware_code IS NULL THEN 
				LET msgresp=kandoomsg("I",9029,"") 
				#9029 Warehouse must be entered
				NEXT FIELD ware_code 
			ELSE 
				SELECT desc_text INTO l_rec_warehouse.desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_prodstatus.ware_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9030,"") 
					#9030 "Warehouse NOT found, try again"
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 
				END IF 
			END IF 
			IF p_mode = "ADD" THEN 
				SELECT 1 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_prodstatus.part_code 
				AND ware_code = l_rec_prodstatus.ware_code 
				IF status = 0 THEN 
					LET msgresp=kandoomsg("I",9067,"") 
					#9067 "This STATUS already exists"
					NEXT FIELD ware_code 
				END IF 
			END IF 

			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
				CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code, 
				l_rec_product.class_code,1) 
				RETURNING l_parent, 
				l_filler, 
				l_flex_part_code, 
				l_flex_num 
				IF l_flex_part_code IS NOT NULL THEN 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE part_code = l_parent 
					AND ware_code = l_rec_prodstatus.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET msgresp = kandoomsg("I",9517,"") 
						#9100 Parent product STATUS does NOT exist AT this warehouse
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 

		AFTER FIELD stocked_flag 
			IF l_rec_prodstatus.stocked_flag = "N" THEN 
				IF l_rec_product.serial_flag = "Y" THEN 
					LET msgresp=kandoomsg("I",9068,"") 
					#9068 " Product cannot be non-stocked AND serial"
					LET l_rec_prodstatus.stocked_flag = "Y" 
					NEXT FIELD stocked_flag 
				END IF 
				LET msgresp=kandoomsg("I",7017,"") 
				#7017 " A long spiel on how non-stocked products work
			ELSE 
				LET l_rec_prodstatus.stocked_flag = "Y" 
			END IF 
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				LET l_rec_prodstatus.nonstk_pick_flag = "Y" 
				DISPLAY BY NAME l_rec_prodstatus.nonstk_pick_flag 

			END IF 

		AFTER INPUT 
			# are being reset in other functions
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			IF not(int_flag OR quit_flag) THEN 

			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false,l_rec_prodstatus.*,l_rec_product.*,l_rec_product.*,l_rec_backreas.*,l_rec_globalrec.*
	ELSE 
		RETURN true ,l_rec_prodstatus.*,l_rec_product.*,l_rec_backreas.*,l_rec_globalrec.*
	END IF 
END FUNCTION		# input_prodstatus


####################################################################################
# FUNCTION input_product_prices()
#
#
####################################################################################
FUNCTION input_product_prices(p_rec_prodstatus,p_rec_product,p_rec_globalrec) 
	DEFINE 	l_rec_category RECORD LIKE category.*
	DEFINE pr_ware_desc_text LIKE warehouse.desc_text
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE p_rec_globalrec t_rec_globalrec
	DEFINE p_rec_product RECORD LIKE product.*
	DEFINE l_rec_prodstatus_parent RECORD LIKE prodstatus.*
	DEFINE l_rec_product_parent RECORD LIKE product.*

	DEFINE l_conv_factor FLOAT
	DEFINE l_sale_calc_flag LIKE tax.calc_method_flag
	DEFINE l_purch_calc_flag LIKE tax.calc_method_flag
	DEFINE l_sale_tax_per,l_purch_tax_per LIKE tax.tax_per 

	IF p_rec_globalrec.parent_part_code != p_rec_prodstatus.part_code THEN 
		##
		## IF this product IS price/cost dependant upon its parent
		## this this FUNCTION sets the prices & costs accordingly
		## AND returns without executing an INPUT statement.
		##
		SELECT * INTO l_rec_prodstatus_parent.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_rec_globalrec.parent_part_code 
		AND ware_code = p_rec_prodstatus.ware_code 

		SELECT * INTO l_rec_product_parent.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_prodstatus_parent.part_code 

		IF p_rec_product.sell_uom_code <> l_rec_product_parent.sell_uom_code THEN 
			## Convert product FROM parent sell uom code TO child
			## sell uom code ##
			LET l_conv_factor = 
			get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,p_rec_prodstatus.part_code,p_rec_product.sell_uom_code, 	p_rec_product.sell_uom_code,1) 
			IF l_conv_factor > 0 THEN 
				LET l_rec_prodstatus_parent.list_amt = l_rec_prodstatus_parent.list_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price1_amt = l_rec_prodstatus_parent.price1_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price2_amt = l_rec_prodstatus_parent.price2_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price3_amt = l_rec_prodstatus_parent.price3_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price4_amt = l_rec_prodstatus_parent.price4_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price5_amt = l_rec_prodstatus_parent.price5_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price6_amt = l_rec_prodstatus_parent.price6_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price7_amt = l_rec_prodstatus_parent.price7_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price8_amt = l_rec_prodstatus_parent.price8_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price9_amt = l_rec_prodstatus_parent.price9_amt * l_conv_factor 
			END IF 
		END IF 
		##
		## Convert prices INTO Price UOM FOR editing
		IF p_rec_product.sell_uom_code <> l_rec_product_parent.price_uom_code THEN 
			## Convert prices back INTO sell UOM
			LET l_conv_factor = 
			get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus_parent.part_code,	p_rec_product.sell_uom_code, p_rec_product.price_uom_code,1) 
			IF l_conv_factor > 0 THEN 
				LET l_rec_prodstatus_parent.list_amt = l_rec_prodstatus_parent.list_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price1_amt = l_rec_prodstatus_parent.price1_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price2_amt = l_rec_prodstatus_parent.price2_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price3_amt = l_rec_prodstatus_parent.price3_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price4_amt = l_rec_prodstatus_parent.price4_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price5_amt = l_rec_prodstatus_parent.price5_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price6_amt = l_rec_prodstatus_parent.price6_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price7_amt = l_rec_prodstatus_parent.price7_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price8_amt = l_rec_prodstatus_parent.price8_amt * l_conv_factor 
				LET l_rec_prodstatus_parent.price9_amt = p_rec_prodstatus.price9_amt * l_conv_factor 
			END IF 
		END IF 

		LET p_rec_prodstatus.list_amt = l_rec_prodstatus_parent.list_amt 
		LET p_rec_prodstatus.pricel_ind = l_rec_prodstatus_parent.pricel_ind 
		LET p_rec_prodstatus.pricel_per = l_rec_prodstatus_parent.pricel_per 
		LET p_rec_prodstatus.price1_amt = l_rec_prodstatus_parent.price1_amt 
		LET p_rec_prodstatus.price1_ind = l_rec_prodstatus_parent.price1_ind 
		LET p_rec_prodstatus.price1_per = l_rec_prodstatus_parent.price1_per 
		LET p_rec_prodstatus.price2_amt = l_rec_prodstatus_parent.price2_amt 
		LET p_rec_prodstatus.price2_ind = l_rec_prodstatus_parent.price2_ind 
		LET p_rec_prodstatus.price2_per = l_rec_prodstatus_parent.price2_per 
		LET p_rec_prodstatus.price3_amt = l_rec_prodstatus_parent.price3_amt 
		LET p_rec_prodstatus.price3_ind = l_rec_prodstatus_parent.price3_ind 
		LET p_rec_prodstatus.price3_per = l_rec_prodstatus_parent.price3_per 
		LET p_rec_prodstatus.price4_amt = l_rec_prodstatus_parent.price4_amt 
		LET p_rec_prodstatus.price4_ind = l_rec_prodstatus_parent.price4_ind 
		LET p_rec_prodstatus.price4_per = l_rec_prodstatus_parent.price4_per 
		LET p_rec_prodstatus.price5_amt = l_rec_prodstatus_parent.price5_amt 
		LET p_rec_prodstatus.price5_ind = l_rec_prodstatus_parent.price5_ind 
		LET p_rec_prodstatus.price5_per = l_rec_prodstatus_parent.price5_per 
		LET p_rec_prodstatus.price6_amt = l_rec_prodstatus_parent.price6_amt 
		LET p_rec_prodstatus.price6_ind = l_rec_prodstatus_parent.price6_ind 
		LET p_rec_prodstatus.price6_per = l_rec_prodstatus_parent.price6_per 
		LET p_rec_prodstatus.price7_amt = l_rec_prodstatus_parent.price7_amt 
		LET p_rec_prodstatus.price7_ind = l_rec_prodstatus_parent.price7_ind 
		LET p_rec_prodstatus.price7_per = l_rec_prodstatus_parent.price7_per 
		LET p_rec_prodstatus.price8_amt = l_rec_prodstatus_parent.price8_amt 
		LET p_rec_prodstatus.price8_ind = l_rec_prodstatus_parent.price8_ind 
		LET p_rec_prodstatus.price8_per = l_rec_prodstatus_parent.price8_per 
		LET p_rec_prodstatus.price9_amt = l_rec_prodstatus_parent.price9_amt 
		LET p_rec_prodstatus.price9_ind = l_rec_prodstatus_parent.price9_ind 
		LET p_rec_prodstatus.price9_per = l_rec_prodstatus_parent.price9_per 
		LET p_rec_prodstatus.wgted_cost_amt = l_rec_prodstatus_parent.wgted_cost_amt 
		LET p_rec_prodstatus.est_cost_amt = l_rec_prodstatus_parent.est_cost_amt 
		LET p_rec_prodstatus.act_cost_amt = l_rec_prodstatus_parent.act_cost_amt 
		LET p_rec_prodstatus.for_curr_code = l_rec_prodstatus_parent.for_curr_code 
		LET p_rec_prodstatus.for_cost_amt = l_rec_prodstatus_parent.for_cost_amt 
		LET p_rec_prodstatus.sale_tax_code = l_rec_prodstatus_parent.sale_tax_code 
		LET p_rec_prodstatus.purch_tax_code = l_rec_prodstatus_parent.purch_tax_code 
		LET p_rec_prodstatus.sale_tax_amt = l_rec_prodstatus_parent.sale_tax_amt 
		LET p_rec_prodstatus.purch_tax_amt = l_rec_prodstatus_parent.purch_tax_amt 
	ELSE 
		##this product IS NOT price/cost dependant upon its parent
		## we proceed to SELECT price-related data from prodstatus (that may go to another table in the future...)
		## Then We proceed to INPUT of new data
		SELECT  list_amt,pricel_ind,pricel_per,
			price1_ind, price1_per, price1_amt,
			price2_amt, price2_ind, price2_per, 
			price3_amt, price3_ind, price3_per,
			price4_amt, price4_ind, price4_per,
			price5_amt, price5_ind, price5_per,
			price6_amt, price6_ind, price6_per, 
			price7_amt, price7_ind, price7_per,
			price8_amt, price8_ind, price8_per, 
			price9_amt, price9_ind, price9_per,
			wgted_cost_amt,
			est_cost_amt,
			act_cost_amt,
			for_curr_code,
			for_cost_amt,
			sale_tax_code,
			purch_tax_code,
			sale_tax_amt,
			purch_tax_amt
		INTO p_rec_prodstatus.list_amt,p_rec_prodstatus.pricel_ind, p_rec_prodstatus.pricel_per,
			p_rec_prodstatus.price1_ind, p_rec_prodstatus.price1_per, p_rec_prodstatus.price1_amt,
			p_rec_prodstatus.price2_amt, p_rec_prodstatus.price2_ind, p_rec_prodstatus.price2_per, 
			p_rec_prodstatus.price3_amt, p_rec_prodstatus.price3_ind, p_rec_prodstatus.price3_per,
			p_rec_prodstatus.price4_amt, p_rec_prodstatus.price4_ind, p_rec_prodstatus.price4_per,
			p_rec_prodstatus.price5_amt, p_rec_prodstatus.price5_ind, p_rec_prodstatus.price5_per,
			p_rec_prodstatus.price6_amt, p_rec_prodstatus.price6_ind, p_rec_prodstatus.price6_per, 
			p_rec_prodstatus.price7_amt, p_rec_prodstatus.price7_ind, p_rec_prodstatus.price7_per,
			p_rec_prodstatus.price8_amt, p_rec_prodstatus.price8_ind, p_rec_prodstatus.price8_per, 
			p_rec_prodstatus.price9_amt, p_rec_prodstatus.price9_ind, p_rec_prodstatus.price9_per,
			p_rec_prodstatus.wgted_cost_amt,
			p_rec_prodstatus.est_cost_amt,
			p_rec_prodstatus.act_cost_amt,
			p_rec_prodstatus.for_curr_code,
			p_rec_prodstatus.for_cost_amt,
			p_rec_prodstatus.sale_tax_code,
			p_rec_prodstatus.purch_tax_code,
			p_rec_prodstatus.sale_tax_amt,
			p_rec_prodstatus.purch_tax_amt
		FROM prodstatus
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND part_code = p_rec_prodstatus.part_code
			AND ware_code = p_rec_prodstatus.ware_code
	
		SELECT * INTO l_rec_category.* 
		FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = p_rec_product.cat_code 
		
		SELECT tax_per, calc_method_flag 
		INTO l_sale_tax_per, l_sale_calc_flag 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = p_rec_prodstatus.sale_tax_code 

		IF l_sale_calc_flag = "I" THEN 
			LET p_rec_prodstatus.sale_tax_amt = (p_rec_prodstatus.for_cost_amt/(1+(l_sale_tax_per/100))) - p_rec_prodstatus.for_cost_amt 
		END IF 

		SELECT tax_per, calc_method_flag 
		INTO l_purch_tax_per, l_purch_calc_flag 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = p_rec_prodstatus.purch_tax_code 
		IF l_purch_calc_flag = "I" THEN 
			LET p_rec_prodstatus.purch_tax_amt = (p_rec_prodstatus.for_cost_amt/(1+(l_purch_tax_per/100))) - p_rec_prodstatus.for_cost_amt 
		END IF 

		SELECT desc_text INTO pr_ware_desc_text 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_prodstatus.ware_code 

		OPEN WINDOW i615 with FORM "I615" 
		 CALL windecoration_i("I615") 

		DISPLAY p_rec_product.part_code, 
			p_rec_product.desc_text, 
			p_rec_product.desc2_text, 
			pr_ware_desc_text, 
			p_rec_prodstatus.ware_code, 
			p_rec_prodstatus.sale_tax_amt, 
			l_sale_tax_per, 
			p_rec_prodstatus.purch_tax_amt, 
			l_purch_tax_per, 
			p_rec_product.sell_uom_code, 
			p_rec_product.price_uom_code 
		TO product.part_code, 
			part_desc_text, 
			part_desc2_text, 
			ware_desc_text, 
			warehouse.ware_code, 
			prodstatus.sale_tax_amt, 
			sale_tax_per, 
			prodstatus.purch_tax_amt, 
			purch_tax_per, 
			product.sell_uom_code, 
			product.price_uom_code 

		LET msgresp=kandoomsg("I",1017,"") 
		#1017 Enter Item Details - ESC TO Continue"
		INPUT BY NAME p_rec_prodstatus.list_amt, 
		p_rec_prodstatus.pricel_ind, 
		p_rec_prodstatus.pricel_per, 
		p_rec_prodstatus.price1_amt, 
		p_rec_prodstatus.price1_ind, 
		p_rec_prodstatus.price1_per, 
		p_rec_prodstatus.price2_amt, 
		p_rec_prodstatus.price2_ind, 
		p_rec_prodstatus.price2_per, 
		p_rec_prodstatus.price3_amt, 
		p_rec_prodstatus.price3_ind, 
		p_rec_prodstatus.price3_per, 
		p_rec_prodstatus.price4_amt, 
		p_rec_prodstatus.price4_ind, 
		p_rec_prodstatus.price4_per, 
		p_rec_prodstatus.price5_amt, 
		p_rec_prodstatus.price5_ind, 
		p_rec_prodstatus.price5_per, 
		p_rec_prodstatus.price6_amt, 
		p_rec_prodstatus.price6_ind, 
		p_rec_prodstatus.price6_per, 
		p_rec_prodstatus.price7_amt, 
		p_rec_prodstatus.price7_ind, 
		p_rec_prodstatus.price7_per, 
		p_rec_prodstatus.price8_amt, 
		p_rec_prodstatus.price8_ind, 
		p_rec_prodstatus.price8_per, 
		p_rec_prodstatus.price9_amt, 
		p_rec_prodstatus.price9_ind, 
		p_rec_prodstatus.price9_per, 
		p_rec_prodstatus.wgted_cost_amt, 
		p_rec_prodstatus.est_cost_amt, 
		p_rec_prodstatus.act_cost_amt, 
		p_rec_prodstatus.for_cost_amt, 
		p_rec_prodstatus.for_curr_code, 
		p_rec_prodstatus.sale_tax_code, 
		p_rec_prodstatus.sale_tax_amt, 
		p_rec_prodstatus.purch_tax_code, 
		p_rec_prodstatus.purch_tax_amt, 
		p_rec_prodstatus.last_price_date, 
		p_rec_prodstatus.last_list_date WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","I16","inp-prodstatus-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) 
				IF infield(wgted_cost_amt) 
				OR infield(est_cost_amt) 
				OR infield(act_cost_amt) 
				OR infield(for_cost_amt) 
				OR infield(tax_code) THEN 
					NEXT FIELD list_amt 
				ELSE 
					NEXT FIELD wgted_cost_amt 
				END IF 

			ON KEY (control-b) infield (for_curr_code) 
				LET modu_temp_text = show_curr(glob_rec_kandoouser.cmpy_code) 
				IF modu_temp_text IS NOT NULL THEN 
					LET p_rec_prodstatus.for_curr_code = modu_temp_text 
				END IF 
				NEXT FIELD for_curr_code 

			ON KEY (control-b) infield (sale_tax_code) 
				LET modu_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
				IF modu_temp_text IS NOT NULL THEN 
					LET p_rec_prodstatus.sale_tax_code = modu_temp_text 
				END IF 
				NEXT FIELD sale_tax_code 

			ON KEY (control-b) infield (purch_tax_code) 
				LET modu_temp_text = show_tax(glob_rec_kandoouser.cmpy_code) 
				IF modu_temp_text IS NOT NULL THEN 
					LET p_rec_prodstatus.purch_tax_code = modu_temp_text 
				END IF 
				NEXT FIELD purch_tax_code 

			ON KEY (F9) 
				CALL set_pricing_prodstatus( 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 'Y', 	p_rec_prodstatus.*, p_rec_product.* ) 
				RETURNING p_rec_prodstatus.* 
				DISPLAY BY NAME p_rec_prodstatus.list_amt, 
				p_rec_prodstatus.price1_amt, 
				p_rec_prodstatus.price2_amt, 
				p_rec_prodstatus.price3_amt, 
				p_rec_prodstatus.price4_amt, 
				p_rec_prodstatus.price5_amt, 
				p_rec_prodstatus.price6_amt, 
				p_rec_prodstatus.price7_amt, 
				p_rec_prodstatus.price8_amt, 
				p_rec_prodstatus.price9_amt 

				IF infield(list_amt) THEN 
					NEXT FIELD list_amt 
				END IF 

			-- AFTER FIELD list_amt 
			ON CHANGE list_amt 
				# Check on NULL values for all those columns will be done at update_prodstatus
				LET p_rec_prodstatus.last_list_date = today
				LET p_rec_prodstatus.last_price_date = today 

			--AFTER FIELD price1_amt 
			ON CHANGE price1_amt
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price2_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price3_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price4_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price5_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price6_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price7_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price8_amt 
				LET p_rec_prodstatus.last_price_date = today 

			ON CHANGE price9_amt 
				LET p_rec_prodstatus.last_price_date = today 

			AFTER FIELD pricel_ind 
				IF p_rec_prodstatus.pricel_ind = 'L' THEN 
					LET msgresp=kandoomsg("I",9202,"") 
					#9202 List price source indicator cannot be a FUNCTION of itself
					NEXT FIELD pricel_ind 
				END IF 

			AFTER FIELD wgted_cost_amt 
				LET p_rec_prodstatus.last_cost_date = today

			AFTER FIELD est_cost_amt 
				LET p_rec_prodstatus.last_cost_date = today			

			AFTER FIELD act_cost_amt 
				LET p_rec_prodstatus.last_cost_date = today

			AFTER FIELD for_curr_code 
				IF p_rec_prodstatus.for_curr_code IS NOT NULL THEN 
					SELECT unique 1 FROM currency 
					WHERE currency_code = p_rec_prodstatus.for_curr_code 
					IF sqlca.sqlcode = NOTFOUND THEN 
						LET msgresp=kandoomsg("I",9073,"") 
						#9073" Currency NOT found Try Window
						NEXT FIELD for_curr_code 
					END IF 
				END IF 
				

			BEFORE FIELD for_cost_amt 
				LET p_rec_prodstatus.last_cost_date = today

			AFTER FIELD for_cost_amt 
				IF p_rec_prodstatus.for_cost_amt IS NULL THEN 
					LET p_rec_prodstatus.for_cost_amt = p_rec_prodstatus.act_cost_amt 
					LET msgresp=kandoomsg("I",9074,"") 
					#9074" Unit Cost of last transaction NOT found
					NEXT FIELD for_cost_amt 
				ELSE 
					IF l_sale_calc_flag = "I" THEN 
						LET p_rec_prodstatus.sale_tax_amt = 
						(p_rec_prodstatus.for_cost_amt/(1+(l_sale_tax_per/100))) 
						-p_rec_prodstatus.for_cost_amt 
					END IF 
					IF l_purch_calc_flag = "I" THEN 
						LET p_rec_prodstatus.purch_tax_amt = 
						(p_rec_prodstatus.for_cost_amt/(1+(l_purch_tax_per/100))) 
						-p_rec_prodstatus.for_cost_amt 
					END IF 
					DISPLAY BY NAME p_rec_prodstatus.sale_tax_amt, 
					p_rec_prodstatus.purch_tax_amt 

				END IF 

			AFTER FIELD sale_tax_code 
				IF p_rec_prodstatus.sale_tax_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD sale_tax_code 
				END IF 
				SELECT tax_per, calc_method_flag 
				INTO l_sale_tax_per, l_sale_calc_flag 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = p_rec_prodstatus.sale_tax_code 
				
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9076,"") 
					#9076" Tax code NOT found - Try Window
					NEXT FIELD sale_tax_code 
				END IF 
				IF l_sale_calc_flag = "I" THEN 
					LET p_rec_prodstatus.sale_tax_amt = (p_rec_prodstatus.for_cost_amt/(1+(l_sale_tax_per/100))) - p_rec_prodstatus.for_cost_amt 
				END IF 
				DISPLAY p_rec_prodstatus.sale_tax_amt, 
				l_sale_tax_per 
				TO prodstatus.sale_tax_amt, 
				sale_tax_per 

			BEFORE FIELD sale_tax_amt 
				IF p_rec_prodstatus.sale_tax_code IS NOT NULL THEN 
					IF status <> notfound AND l_sale_calc_flag != 'D' THEN 
						IF fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") THEN 
							NEXT FIELD previous 
						ELSE 
							NEXT FIELD NEXT 
						END IF 
					END IF 
				END IF 

			AFTER FIELD sale_tax_amt 
				IF p_rec_prodstatus.sale_tax_amt IS NULL THEN 
					LET msgresp=kandoomsg("I",9064,"") 
					#9064" Tax amount must be entered
					LET p_rec_prodstatus.sale_tax_amt = 0 
					NEXT FIELD sale_tax_amt 
				END IF 
				
			AFTER FIELD purch_tax_code 
				IF p_rec_prodstatus.purch_tax_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD purch_tax_code 
				END IF 
				
				SELECT tax_per, calc_method_flag 
				INTO l_purch_tax_per, l_purch_calc_flag 
				FROM tax 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = p_rec_prodstatus.purch_tax_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET msgresp=kandoomsg("I",9076,"") 
					#9076" Tax code NOT found - Try Window
					NEXT FIELD purch_tax_code 
				END IF 
				IF l_purch_calc_flag = "I" THEN 
					LET p_rec_prodstatus.purch_tax_amt = (p_rec_prodstatus.for_cost_amt/(1+(l_purch_tax_per/100))) - p_rec_prodstatus.for_cost_amt 
				END IF 
				DISPLAY p_rec_prodstatus.purch_tax_amt, 
				l_purch_tax_per 
				TO prodstatus.purch_tax_amt, 
				purch_tax_per 

			BEFORE FIELD purch_tax_amt 
				IF p_rec_prodstatus.purch_tax_code IS NOT NULL THEN 
					IF l_purch_calc_flag != 'D' THEN 
						IF fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") THEN 
							NEXT FIELD previous 
						ELSE 
							NEXT FIELD NEXT 
						END IF 
					END IF 
				END IF 

			AFTER FIELD purch_tax_amt 
				IF p_rec_prodstatus.purch_tax_amt IS NULL THEN 
					LET msgresp=kandoomsg("I",9064,"") 
					#9064" Tax amount must be entered
					LET p_rec_prodstatus.purch_tax_amt = 0 
					NEXT FIELD purch_tax_amt 
				END IF 
			AFTER INPUT 
				IF not(int_flag OR quit_flag) THEN 
					IF p_rec_prodstatus.sale_tax_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD sale_tax_code 
					END IF 
					IF p_rec_prodstatus.purch_tax_code IS NULL THEN 
						LET msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD purch_tax_code 
					END IF 
					IF p_rec_prodstatus.act_cost_amt IS NULL THEN 
						LET p_rec_prodstatus.act_cost_amt = 0 
					END IF 
					IF p_rec_prodstatus.for_cost_amt IS NULL THEN 
						LET p_rec_prodstatus.for_cost_amt = 0 
					END IF 
					IF p_rec_prodstatus.est_cost_amt IS NULL THEN 
						LET p_rec_prodstatus.est_cost_amt = 0 
					END IF 
					IF p_rec_prodstatus.wgted_cost_amt IS NULL THEN 
						LET p_rec_prodstatus.wgted_cost_amt = 0 
					END IF 
					IF p_rec_prodstatus.est_cost_amt = 0 OR p_rec_prodstatus.for_cost_amt = 0 OR p_rec_prodstatus.act_cost_amt = 0 THEN 
						LET msgresp=kandoomsg("I",8019,"") 
						#8019 " Warning : Product Costs are Zero Re Enter (Y/N)"
						IF msgresp = "Y" THEN 
							NEXT FIELD est_cost_amt 
						END IF 
					END IF 
					IF p_rec_prodstatus.pricel_ind = 'L' THEN 
						LET msgresp=kandoomsg("I",9202,"") 
						#9202 List price source indicator cannot be a FUNCTION of itself
						NEXT FIELD pricel_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.pricel_per,p_rec_prodstatus.pricel_ind ) THEN 
						NEXT FIELD pricel_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price1_per,p_rec_prodstatus.price1_ind ) THEN 
						NEXT FIELD price1_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price2_per, p_rec_prodstatus.price2_ind ) THEN 
						NEXT FIELD price2_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price3_per, p_rec_prodstatus.price3_ind ) THEN 
						NEXT FIELD price3_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price4_per, p_rec_prodstatus.price4_ind ) THEN 
						NEXT FIELD price4_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price5_per, p_rec_prodstatus.price5_ind) THEN 
						NEXT FIELD price5_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price6_per, p_rec_prodstatus.price6_ind) THEN 
						NEXT FIELD price6_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price7_per, p_rec_prodstatus.price7_ind) THEN 
						NEXT FIELD price7_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price8_per, p_rec_prodstatus.price8_ind) THEN 
						NEXT FIELD price8_ind 
					END IF 
					IF NOT valid_level( p_rec_prodstatus.price9_per, p_rec_prodstatus.price9_ind) THEN 
						NEXT FIELD price9_ind 
					END IF 
				END IF 

			ON KEY (control-w) 
				CALL kandoohelp("") 

		END INPUT 

		CLOSE WINDOW i615 

	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false,p_rec_prodstatus.* 
	ELSE 
		RETURN true , p_rec_prodstatus.*
	END IF 
END FUNCTION 		# input_product_prices


####################################################################################
# FUNCTION prod_deletable(pr_part_code,pr_ware_code)
#
#
####################################################################################
FUNCTION prod_deletable(pr_part_code,pr_ware_code) 
	DEFINE 
	pr_part_code LIKE prodstatus.part_code, 
	pr_ware_code LIKE prodstatus.ware_code, 
	ps_product RECORD LIKE product.*, 
	pr_class RECORD LIKE class.* 

	SELECT * INTO ps_product.* FROM product 
	WHERE part_code = pr_part_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		SELECT * INTO pr_class.* 
		FROM class 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND class_code = ps_product.class_code 
		IF pr_class.stock_level_ind IS NOT NULL 
		AND pr_class.stock_level_ind > pr_class.price_level_ind THEN 
			LET pr_part_code = pr_part_code clipped,"*" 
			SELECT unique 1 FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code matches pr_part_code 
			AND ware_code = pr_ware_code 
			AND (onhand_qty != 0 OR onord_qty != 0 OR back_qty != 0) 
			IF status = 0 THEN 
				LET msgresp=kandoomsg("I",7014,ps_product.part_code) 
				#7014 "Stock exists on hand"
				RETURN false 
			ELSE 
				RETURN true 
			END IF 
		END IF 
	END IF 

	SELECT unique 1 FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_part_code 
	AND ware_code = pr_ware_code 
	AND (onhand_qty != 0 OR onord_qty != 0 OR back_qty != 0) 
	IF status = 0 THEN 
		LET msgresp=kandoomsg("I",7014,pr_part_code) 
		#7014 "Stock exists on hand"
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 	# prod_deletable


####################################################################################
# FUNCTION set_pricing_prodstatus()
#
#
####################################################################################
FUNCTION set_pricing_prodstatus( l_upd_list_flag, l_upd_price1_flag, l_upd_price2_flag, 
	l_upd_price3_flag, l_upd_price4_flag, l_upd_price5_flag, 
	l_upd_price6_flag, l_upd_price7_flag, l_upd_price8_flag, 
	l_upd_price9_flag, l_rec_prodstatus, l_rec_product ) 
	DEFINE 
	l_upd_list_flag, 
	l_upd_price1_flag, 
	l_upd_price2_flag, 
	l_upd_price3_flag, 
	l_upd_price4_flag, 
	l_upd_price5_flag, 
	l_upd_price6_flag, 
	l_upd_price7_flag, 
	l_upd_price8_flag, 
	l_upd_price9_flag CHAR(1), 
	l_rec_prodstatus RECORD LIKE prodstatus.*, 
	l_rec_product RECORD LIKE product.*, 
	l_rec_category RECORD LIKE category.*, 
	x FLOAT 


	# convert TO stock uom's as data previously altered FOR DISPLAY TO price uoms
	IF l_rec_product.sell_uom_code <> l_rec_product.price_uom_code THEN 
		LET x = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code, 
		l_rec_product.sell_uom_code, 
		l_rec_product.price_uom_code,1) 
		IF x > 0 THEN 
			LET l_rec_prodstatus.list_amt = l_rec_prodstatus.list_amt / x 
			LET l_rec_prodstatus.price1_amt = l_rec_prodstatus.price1_amt / x 
			LET l_rec_prodstatus.price2_amt = l_rec_prodstatus.price2_amt / x 
			LET l_rec_prodstatus.price3_amt = l_rec_prodstatus.price3_amt / x 
			LET l_rec_prodstatus.price4_amt = l_rec_prodstatus.price4_amt / x 
			LET l_rec_prodstatus.price5_amt = l_rec_prodstatus.price5_amt / x 
			LET l_rec_prodstatus.price6_amt = l_rec_prodstatus.price6_amt / x 
			LET l_rec_prodstatus.price7_amt = l_rec_prodstatus.price7_amt / x 
			LET l_rec_prodstatus.price8_amt = l_rec_prodstatus.price8_amt / x 
			LET l_rec_prodstatus.price9_amt = l_rec_prodstatus.price9_amt / x 
		END IF 
	END IF 

	SELECT * INTO l_rec_category.* 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = l_rec_product.cat_code 
	IF l_upd_list_flag = 'Y' THEN 
		LET l_rec_prodstatus.list_amt = calculate_price('L', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price1_flag = 'Y' THEN 
		LET l_rec_prodstatus.price1_amt = calculate_price('1', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price2_flag = 'Y' THEN 
		LET l_rec_prodstatus.price2_amt = calculate_price('2', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price3_flag = 'Y' THEN 
		LET l_rec_prodstatus.price3_amt = calculate_price('3', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price4_flag = 'Y' THEN 
		LET l_rec_prodstatus.price4_amt = calculate_price('4', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price5_flag = 'Y' THEN 
		LET l_rec_prodstatus.price5_amt = calculate_price('5', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price6_flag = 'Y' THEN 
		LET l_rec_prodstatus.price6_amt = calculate_price('6', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price7_flag = 'Y' THEN 
		LET l_rec_prodstatus.price7_amt = calculate_price('7', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price8_flag = 'Y' THEN 
		LET l_rec_prodstatus.price8_amt = calculate_price('8', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	IF l_upd_price9_flag = 'Y' THEN 
		LET l_rec_prodstatus.price9_amt = calculate_price('9', l_rec_prodstatus.*, 
		l_rec_category.cat_code, 
		l_rec_product.tariff_code, 
		"", today) 
	END IF 
	# convert back TO price uom's as data previously altered FOR calculations  TO stock uoms
	IF l_rec_product.sell_uom_code <> l_rec_product.price_uom_code THEN 
		LET x = get_uom_conversion_factor(glob_rec_kandoouser.cmpy_code,l_rec_prodstatus.part_code, 
		l_rec_product.sell_uom_code, 
		l_rec_product.price_uom_code,1) 
		IF x > 0 THEN 
			LET l_rec_prodstatus.list_amt = l_rec_prodstatus.list_amt * x 
			LET l_rec_prodstatus.price1_amt = l_rec_prodstatus.price1_amt * x 
			LET l_rec_prodstatus.price2_amt = l_rec_prodstatus.price2_amt * x 
			LET l_rec_prodstatus.price3_amt = l_rec_prodstatus.price3_amt * x 
			LET l_rec_prodstatus.price4_amt = l_rec_prodstatus.price4_amt * x 
			LET l_rec_prodstatus.price5_amt = l_rec_prodstatus.price5_amt * x 
			LET l_rec_prodstatus.price6_amt = l_rec_prodstatus.price6_amt * x 
			LET l_rec_prodstatus.price7_amt = l_rec_prodstatus.price7_amt * x 
			LET l_rec_prodstatus.price8_amt = l_rec_prodstatus.price8_amt * x 
			LET l_rec_prodstatus.price9_amt = l_rec_prodstatus.price9_amt * x 
		END IF 
	END IF 

	RETURN l_rec_prodstatus.* 
END FUNCTION 			# set_pricing_prodstatus


####################################################################################
# FUNCTION valid_level( l_upd_list_flag, pr_price_ind )
#
#
####################################################################################
FUNCTION valid_level( l_upd_list_flag, pr_price_ind ) 
	#
	# valid_level() ensures that either  - both type & markup are NOT entered
	#                                OR  - both type & markup are entered
	#
	#
	DEFINE 
	l_upd_list_flag LIKE prodstatus.pricel_per, 
	pr_price_ind LIKE category.price1_ind 

	IF ( l_upd_list_flag IS NULL 
	AND pr_price_ind IS NOT NULL ) 
	OR ( pr_price_ind IS NULL 
	AND l_upd_list_flag IS NOT NULL ) THEN 
		LET msgresp=kandoomsg("I",9207,"") 
		#9207 Source indicator AND markup must both be entered
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 	# valid_level


####################################################################################
# FUNCTION change_status_prodstatus(l_part_code, l_ware_code, l_status_ind, p_idx)
#
#
####################################################################################
FUNCTION change_status_prodstatus(p_part_code, p_ware_code, l_status_ind, p_idx) 
	DEFINE 	p_part_code LIKE prodstatus.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE l_status_ind LIKE prodstatus.status_ind 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_match_part_code LIKE product.part_code 
	DEFINE l_parent_part_code, l_filler, l_flex_part_code LIKE product.part_code 
	DEFINE p_idx,l_counter,l_counter2, l_counter3, l_not_flexible SMALLINT 
	DEFINE l_flex_num INTEGER 

	LET l_not_flexible = 1 
	IF p_part_code IS NULL THEN 
		RETURN 
	END IF 

	IF l_status_ind = "3" THEN --3=product deleted 
		IF not(prod_deletable(p_part_code, p_ware_code)) THEN 
			RETURN 0
		END IF 
	END IF 
	
	SELECT status_ind INTO l_rec_product.status_ind 
	FROM product 
	WHERE cmpy_code =glob_rec_kandoouser.cmpy_code
	AND part_code = p_part_code  
	--AND part_code = modu_arr_rec_prodstatus[p_idx].part_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN  0
	END IF 

	IF l_rec_product.status_ind = "3" AND l_status_ind != "3" THEN 
		LET msgresp = kandoomsg("I",9511,"") 
		#9511 Product has been deleted
		RETURN 0
	END IF 

	IF l_status_ind = "1" THEN 
		IF l_rec_product.status_ind = "2" THEN 
			LET msgresp = kandoomsg("I",9515,"") 
			#9515 Product has been put on hold
			RETURN 0
		END IF 
		IF l_rec_product.status_ind = "4" THEN 
			LET msgresp = kandoomsg("I",9516,"") 
			#9516 Product has been stopped FROM reordering
			RETURN 0
		END IF 
	END IF 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" THEN 
		CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product.part_code, l_rec_product.class_code,1) 
		RETURNING l_parent_part_code, l_filler, l_flex_part_code, l_flex_num 
		
		IF l_flex_part_code IS NOT NULL THEN 
			SELECT status_ind INTO l_rec_prodstatus.status_ind
			FROM prodstatus 
			WHERE part_code = l_parent_part_code 
			AND ware_code = p_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_status_ind != "3" THEN 
				IF l_rec_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9512,"") 
					#9512 Parent product has been deleted
					RETURN 0	# done nothing
				END IF 
				IF l_status_ind = "1" THEN 
					IF l_rec_prodstatus.status_ind = "2" THEN 
						LET msgresp = kandoomsg("I",9513,"") 
						#9513 Parent product has been put on hold
						RETURN 0 # done nothing
					END IF 
					IF l_rec_prodstatus.status_ind = "4" THEN 
						LET msgresp = kandoomsg("I",9514,"") 
						#9514 Parent Product has been stopped FROM reordering
						RETURN # done nothing
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
			# Scan products from same class having matching part_code*
			LET l_match_part_code = l_rec_product.part_code clipped,"*" 
			# Look at products of same class matching "part_code*
			CALL crs_products_same_class.Open(l_match_part_code,glob_rec_kandoouser.cmpy_code,l_rec_class.class_code)
			--FOREACH crs_products_same_class INTO l_rec_product.* 
			WHILE (crs_products_same_class.FetchNext(l_rec_product.part_code) = 0 )
				IF (l_status_ind = "4" OR l_status_ind = "2") AND p_part_code != l_rec_product.part_code THEN 
					WHENEVER SQLERROR CONTINUE
					UPDATE prodstatus 
					SET status_date = today, 
					status_ind = l_status_ind 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_product.part_code 
					AND ware_code = p_ware_code 
					AND status_ind != "3" 
					WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
					IF sqlca.sqlcode < 0 THEN
						ERROR "Status change of related product FAILED!"
						RETURN -1
					END IF
				ELSE 
					IF NOT (l_status_ind = "1" AND (l_rec_product.status_ind = "3" OR l_rec_product.status_ind = "2" OR l_rec_product.status_ind = "4")) THEN 
						WHENEVER SQLERROR CONTINUE
						UPDATE prodstatus 
						SET status_date = today, 
						status_ind = l_status_ind 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = l_rec_product.part_code 
						AND ware_code = p_ware_code 
						WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
						IF sqlca.sqlcode < 0 THEN
							ERROR "Status change of related product FAILED!"
							RETURN -1
						END IF
					END IF 
				END IF 
			END WHILE
			--END FOREACH 

			LET l_counter3 = 0 

{
			# ericv 2020-11-20: OK, we have done sooo many things that we don't remember exactly what has been done
			# So, just in case, we run the main cursor again and display current values after changes
			FOREACH crs_construct_prodstatus INTO modu_rec_prodstatus.* 
				LET l_counter3 = l_counter3 + 1 
				LET modu_arr_rec_prodstatus[l_counter3].part_code = 
				modu_rec_prodstatus.part_code 
				LET modu_arr_rec_prodstatus[l_counter3].ware_code = 
				modu_rec_prodstatus.ware_code 
				LET modu_arr_rec_prodstatus[l_counter3].onhand_qty = 
				modu_rec_prodstatus.onhand_qty 
				LET modu_arr_rec_prodstatus[l_counter3].reserved_qty = 
				modu_rec_prodstatus.reserved_qty 
				IF modu_rec_opparms.cal_available_flag = "N" THEN 
					LET modu_arr_rec_prodstatus[l_counter3].avail = 
					modu_rec_prodstatus.onhand_qty - 
					modu_rec_prodstatus.reserved_qty - 
					modu_rec_prodstatus.back_qty 
				ELSE 
					LET modu_arr_rec_prodstatus[l_counter3].avail = 
					modu_rec_prodstatus.onhand_qty - 
					modu_rec_prodstatus.reserved_qty 
				END IF 
				LET modu_arr_rec_prodstatus[l_counter3].status_date = 
				modu_rec_prodstatus.status_date 
				LET modu_arr_rec_prodstatus[l_counter3].status_ind = 
				modu_rec_prodstatus.status_ind 
				IF l_counter3 = 500 THEN 
					EXIT FOREACH 
				END IF 

			END FOREACH 
}
			IF l_counter3 > 13 THEN 
				LET l_counter2 = 13 
			ELSE 
				LET l_counter2 = l_counter3 
			END IF 

			# Is this an array refresh ?
			# TODO: find a way to refresh the array modu_arr_rec_prodstatus in a regular way
			FOR l_counter = 1 TO l_counter2 
				DISPLAY modu_arr_rec_prodstatus[l_counter].* 
				TO sr_prodstatus[l_counter].* 

			END FOR 

		END IF 
	END IF 

	IF l_not_flexible THEN 
		WHENEVER SQLERROR CONTINUE
		UPDATE prodstatus 
		SET status_date = today, 
		status_ind = l_status_ind 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_part_code 
		AND ware_code = p_ware_code 
		IF sqlca.sqlcode < 0 THEN
			ERROR "Status change for this product FAILED!"
			RETURN -1
		END IF
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		LET modu_arr_rec_prodstatus[p_idx].status_ind = l_status_ind 
		LET modu_arr_rec_prodstatus[p_idx].status_date = today 
	END IF 

	IF l_status_ind = "4" THEN 
		IF check_back(glob_rec_kandoouser.cmpy_code,p_part_code,l_rec_product.class_code) THEN 
			LET msgresp=kandoomsg("I",7061,"") 
			#7061 Warning - This product currently allows back ordering
		END IF 
	END IF 
	RETURN 1	# well done!
END FUNCTION   # change_status_prodstatus
