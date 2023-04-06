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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

##############################################################
# FUNCTION db_product_filter_datasource(p_filter)
#
#     partwind.4gl - show_part
#                    Window FUNCTION FOR finding product records
#                    FUNCTION will RETURN part_code TO calling program
#############################################################
FUNCTION db_product_filter_datasource(p_filter,p_query) 
	DEFINE p_filter BOOLEAN 
	DEFINE p_query STRING 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_gc_mc_nt_rs_with_scrollflag 
	DEFINE l_note_total SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_query IS NOT NULL THEN #if a query is passed, always ignore p_filter #I hate this approach.. passing complete queries
		LET p_query = "AND ", p_query CLIPPED
	END IF 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria;  OK TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			desc_text, 
			prodgrp_code, 
			maingrp_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","partwind","construct-product") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_product.part_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 
		
	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM product ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND status_ind <> '3' ", 
		"AND ",l_where_text clipped," ", 
		trim(p_query), " ",
		"ORDER BY part_code" 
	
	WHENEVER ERROR CONTINUE 
--	OPTIONS SQL interrupt ON 

	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	LET l_idx = 0 
	FOREACH c_product INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[l_idx].prodgrp_code = l_rec_product.prodgrp_code 
		LET l_arr_rec_product[l_idx].maingrp_code = l_rec_product.maingrp_code 

		SELECT count(*) INTO l_note_total FROM prodnote 
		WHERE cmpy_code = p_cmpy 
		AND part_code = l_rec_product.part_code 

		IF l_note_total > 0 THEN 
			LET l_arr_rec_product[l_idx].notes = "Y" 
		ELSE 
			LET l_arr_rec_product[l_idx].notes = "N" 
		END IF 
		IF l_rec_product.super_part_code IS NOT NULL OR l_rec_product.super_part_code != " " THEN 
			LET l_arr_rec_product[l_idx].relationship = "S" 
		ELSE 
			IF l_rec_product.alter_part_code IS NOT NULL OR l_rec_product.alter_part_code != " " THEN 
				LET l_arr_rec_product[l_idx].relationship = "A" 
			ELSE 
				IF l_rec_product.compn_part_code IS NOT NULL OR l_rec_product.compn_part_code != " " THEN 
					LET l_arr_rec_product[l_idx].relationship = "C" 
				ELSE 
					LET l_arr_rec_product[l_idx].relationship = " " 
				END IF 
			END IF 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH
	 
	MESSAGE kandoomsg2("U",9113,l_arr_rec_product.getLength()) #9113 "l_idx records selected"

	RETURN l_arr_rec_product 

END FUNCTION 
##############################################################
# END FUNCTION db_product_filter_datasource(p_filter)
#############################################################


##############################################################
# FUNCTION show_part(p_cmpy,p_filter_text) 
#
# RETURN l_ret_part_code
#############################################################
FUNCTION show_part(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_ret_part_code LIKE product.part_code
	
	LET l_ret_part_code = choose_part_from_list(p_cmpy,p_filter_text,NULL)
	RETURN l_ret_part_code
END FUNCTION
##############################################################
# END FUNCTION show_part(p_cmpy,p_filter_text) 
#############################################################


##############################################################
# FUNCTION choose_part_from_list(p_cmpy,p_arg_where_text,p_part_code_bak) 
#
# RETURN l_rec_product.part_code 
#############################################################
FUNCTION choose_part_from_list(p_cmpy,p_arg_where_text,p_part_code_bak) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_arg_where_text STRING
	DEFINE p_part_code_bak LIKE product.part_code
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF t_rec_product_pc_dt_gc_mc_nt_rs_with_scrollflag 
	#	DEFINE l_arr_rec_product array[100] of
	#		RECORD
	#         scroll_flag CHAR(1),
	#         part_code LIKE product.part_code,
	#         desc_text LIKE product.desc_text,
	#         prodgrp_code LIKE product.prodgrp_code,
	#         maingrp_code LIKE product.maingrp_code,
	#         notes CHAR(1),
	#         relationship CHAR(1)
	#      END RECORD
	DEFINE l_idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	#	DEFINE filter_text CHAR(400)

	OPEN WINDOW I600 with FORM "I600" --huho FORM was wrong - 2 missing COLUMNS notes AND relationship CHAR(1) formonly 
	CALL windecoration_i("I600") 

	-------------------------------

	CALL db_product_filter_datasource(FALSE,p_arg_where_text) RETURNING l_arr_rec_product

	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_product[1].* TO NULL
	#      END IF
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	MESSAGE kandoomsg2("U",1532,"")	#1532 Press OK on line TO SELECT;  F8 Detail;   F10 TO Add.
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","partwind","input-arr-product") 
--			IF p_arg_where_text IS NOT NULL THEN #hide filter event
--				CALL dialog.setActionHidden("FILTER", TRUE)
--			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_product_filter_datasource(TRUE,p_arg_where_text) RETURNING l_arr_rec_product 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "PRODUCT INFO"	--ON KEY (F8) 
			IF l_arr_rec_product[l_idx].part_code IS NOT NULL THEN 
				CALL pinqwind(p_cmpy,l_arr_rec_product[l_idx].part_code,0) 
				--CALL db_product_filter_datasource(FALSE,p_arg_where_text) RETURNING l_arr_rec_product 
			END IF 
			#            NEXT FIELD scroll_flag

		ON ACTION "PRODUCT ADD"  --ON KEY (F10) 
			CALL run_prog("I11","","","","") 
			CALL db_product_filter_datasource(FALSE,p_arg_where_text) RETURNING l_arr_rec_product 
			#         AFTER FIELD scroll_flag
			#            LET l_arr_rec_product[l_idx].scroll_flag = NULL
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("U",9001,"")
			#               NEXT FIELD scroll_flag
			#            END IF

			#         BEFORE FIELD part_code
			#            LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code
			#            EXIT INPUT
			#         AFTER ROW
			#            DISPLAY l_arr_rec_product[l_idx].* TO sr_product[scrn].*

		AFTER DISPLAY 
			IF l_idx > 0 THEN 
				LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code 
			END IF 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		LET l_rec_product.part_code = p_part_code_bak 
	END IF 

	CLOSE WINDOW I600 
	RETURN l_rec_product.part_code 
END FUNCTION 
##############################################################
# END FUNCTION choose_part_from_list(p_cmpy,p_arg_where_text,p_part_code_bak) 
#
# RETURN l_rec_product.part_code 
#############################################################


########################################################################
#    FUNCTION:   valid_part
#    Description:This FUNCTION IS designed TO validate the product (AND
#                warehouse IF passed).  The product AND warehouse are
#                checked TO see IF they exist.  Using the check_ind value
#                the rules regarding the product AND product/warehouse
#                AND the current STATUS indicator IS verified in three
#                possible scenarios:
#                 - a Purchasing  transaction  (check_ind = 1)
#                 - a Selling     transaction  (check_ind = 2)
#                 - a Stocktaking transaction  (check_ind = 3)
#                IF the verbose_ind value IS TRUE THEN any MESSAGEs are
#                displayed.
#                NOTE: IF the validation check IS successful ie:
#                the value of TRUE IS TO be returned THEN IF the verbose_ind
#                value IS TRUE this will automatically be SET TO FALSE
#
#     Parameters:p_cmpy           - company code value
#                p_part_code   - part code TO be validated
#                p_ware_code   - warehouse code TO be validated
#                p_verbose_ind - indicator (TRUE/FALSE) TO turn on/off
#                                 MESSAGEs
#                p_check_ind   - indicator TO determine the transaction type
#                                 which dictates different rules FOR validation
#                                 Possible VALUES are: 1-Purchasing
#                                                      2-Selling
#                                                      3-Stocktake
#                p_no_window   - indicator will stop
#                                 Product Does Not Exist - Try window
#                                 MESSAGE appearing, instead
#                                 Product Does Not Exist
#                                 MESSAGE will appear
#                p_temp1       - FOR future use
#                p_temp2       - FOR future use
#                p_temp3       - FOR future use
#
########################################################################
FUNCTION valid_part(p_cmpy,p_part_code,p_ware_code,p_verbose_ind,p_check_ind,p_no_window,p_temp1,p_temp2,p_temp3) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_ware_code LIKE prodstatus.ware_code
	DEFINE p_verbose_ind SMALLINT
	DEFINE p_check_ind SMALLINT
	DEFINE p_no_window SMALLINT	
	DEFINE p_temp1 CHAR(1) 
	DEFINE p_temp2 CHAR(1) 
	DEFINE p_temp3 CHAR(1) 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_return BOOLEAN 
	DEFINE l_message INTEGER 

	CALL db_product_get_rec(UI_OFF,p_part_code) RETURNING l_rec_product.*

	CASE 
		WHEN l_rec_product.part_code IS NULL #not found 
			IF p_no_window THEN 
				#### Product does NOT exist
				LET l_message = 9556 
			ELSE 
				#### Product NOT found - Try Window
				LET l_message = 9010 
			END IF 
			LET l_return = FALSE 

		WHEN l_rec_product.status_ind = "1" 
			#### Product IS currently available
			LET l_return = true 

		WHEN l_rec_product.status_ind = "2" 
			LET l_message = 7019 
			#### Product has been placed on hold
			CASE p_check_ind 
				WHEN 1 ### purchasing stock 
					LET l_return = FALSE 
				WHEN 2 ### selling stock 
					LET l_return = FALSE 
				WHEN 3 ### counting stock 
					LET l_return = true 
				OTHERWISE ### NOT a valid CHECK indicator 
					LET l_return = FALSE 
			END CASE 
			#RETURN 7019  #### Product has been placed on hold

		WHEN l_rec_product.status_ind = "3" 
			LET l_message = 7020 
			#### Product has been logically deleted
			CASE p_check_ind 
				WHEN 1 ### purchasing stock 
					LET l_return = FALSE 
				WHEN 2 ### selling stock 
					LET l_return = FALSE 
				WHEN 3 ### counting stock 
					LET l_return = FALSE 
				OTHERWISE ### NOT a valid CHECK indicator 
					LET l_return = FALSE 
			END CASE 

		WHEN l_rec_product.status_ind = "4" 
			LET l_message = 7062 
			#### Product has been tagged FOR no reorder
			CASE p_check_ind 
				WHEN 1 ### purchasing stock 
					LET l_return = FALSE 
				WHEN 2 ### selling stock 
					LET l_return = true 
				WHEN 3 ### counting stock 
					LET l_return = true 
				OTHERWISE ### NOT a valid CHECK indicator 
					LET l_return = true 
			END CASE 
	END CASE 
	
	IF l_return THEN 
		IF NOT db_warehouse_pk_exists(UI_OFF,p_ware_code) THEN
		--	SELECT unique 1 FROM warehouse 
		--	WHERE cmpy_code = p_cmpy 
		--	AND ware_code = p_ware_code 
		--	IF sqlca.sqlcode = notfound THEN 
				### Warehouse does NOT exist - Try Window
				LET l_message = 9506 
				LET l_return = FALSE 
		ELSE #found/exist 
			CALL db_prodstatus_get_rec(UI_ON,p_ware_code,p_part_code)	RETURNING l_rec_prodstatus.*
			
			CASE 
				WHEN l_rec_prodstatus.part_code IS NULL #sqlca.sqlcode = notfound 
					### Product NOT stocked AT this warehouse
					LET l_message = 9104 
					LET l_return = FALSE 
				
				WHEN l_rec_prodstatus.status_ind = "1" 
					#### Product/Warehouse IS currently available
					LET l_return = true 
				
				WHEN l_rec_prodstatus.status_ind = "2" 
					### Product/Warehouse has been placed on hold
					LET l_message = 7021 
					CASE p_check_ind 
						WHEN 1 ### purchasing stock 
							LET l_return = FALSE 
						WHEN 2 ### selling stock 
							LET l_return = FALSE 
						WHEN 3 ### counting stock 
							LET l_return = true 
						OTHERWISE ### NOT a valid CHECK indicator 
							LET l_return = FALSE 
					END CASE 
					
				WHEN l_rec_prodstatus.status_ind = "3" 
					### Product/Warehouse has been tagged FOR deletion
					LET l_message = 7022 
					CASE p_check_ind 
						WHEN 1 ### purchasing stock 
							LET l_return = FALSE 
						WHEN 2 ### selling stock 
							LET l_return = FALSE 
						WHEN 3 ### counting stock 
							LET l_return = FALSE 
						OTHERWISE ### NOT a valid CHECK indicator 
							LET l_return = FALSE 
					END CASE 

				WHEN l_rec_prodstatus.status_ind = "4" 
					### Product/Warehouse has been tagged FOR no reorder
					LET l_message = 7063 
					CASE p_check_ind 
						WHEN 1 ### purchasing stock 
							LET l_return = FALSE 
						WHEN 2 ### selling stock 
							LET l_return = true 
						WHEN 3 ### counting stock 
							LET l_return = true 
						OTHERWISE 
							LET l_return = FALSE 
					END CASE 
			END CASE 

		END IF 

	END IF 
	### DISPLAY MESSAGE IF verbose indicator SET AND RETURN value
	### BUT do NOT DISPLAY any MESSAGEs IF the RETURN value IS TRUE
	IF NOT l_return THEN 
		IF p_verbose_ind THEN 
			MESSAGE kandoomsg2("I",l_MESSAGE,"") 
		END IF 
	END IF 
	RETURN l_return 
END FUNCTION 
########################################################################
# END FUNCTION valid_part(p_cmpy,p_part_code,p_ware_code, 
#	p_verbose_ind,p_check_ind,p_no_window, 
#	p_temp1,p_temp2,p_temp3) 
########################################################################


##############################################################
# FUNCTION check_back(p_cmpy,p_part_code,p_class_code)
#
#
#############################################################
FUNCTION check_back(p_cmpy,p_part_code,p_class_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_back_count SMALLINT 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 

	LET l_query_text = "SELECT unique 1 ", 
	"FROM product ", 
	"WHERE cmpy_code = '", p_cmpy,"' " 
	IF p_class_code IS NOT NULL THEN 
		LET l_query_text = l_query_text clipped,	" AND class_code = '", p_class_code clipped, "'",	" AND part_code = '", p_part_code clipped,"'" 
	ELSE 
		LET l_query_text = l_query_text clipped,	" AND part_code = '", p_part_code clipped, "'" 
	END IF 
	LET l_query_text = l_query_text clipped, " AND back_order_flag = 'Y' " 
	
	PREPARE s_back_query FROM l_query_text 
	DECLARE c_back CURSOR FOR s_back_query 
	OPEN c_back 
	FETCH c_back INTO l_back_count 
	
	IF l_back_count > 0 THEN 
		RETURN true 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION 
##############################################################
# END FUNCTION check_back(p_cmpy,p_part_code,p_class_code)
#############################################################