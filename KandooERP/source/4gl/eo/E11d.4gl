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
# \brief module E11d - Line Item Entry (Scan Array)
#
#    - Program Note1: the variable l_rec_orderdetl.cost_ind IS used within
#                     the program TO flag (Y/N) whether a line item
#                     permits backorders OR NOT.
#              Note2: the variable l_rec_orderdetl.job_code IS used within
#                     the program TO flag (TRUE/FALSE) whether a line has
#                     been used in a discount calculation OR NOT
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E11_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_orderdetl_curr_row RECORD LIKE orderdetl.*  #data from the currently selected row - orderdetl

###########################################################################
# FUNCTION db_t_orderdetl_get_datasource()
#
#
###########################################################################
FUNCTION db_t_orderdetl_get_datasource()
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.*
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD --array[500] OF RECORD 
--		scroll_flag char(1), 
		line_num LIKE orderdetl.line_num, 
		offer_code LIKE orderdetl.offer_code, 
		part_code LIKE orderdetl.part_code, 
		sold_qty LIKE orderdetl.sold_qty, 
		bonus_qty LIKE orderdetl.bonus_qty, 
		disc_per LIKE orderdetl.disc_per, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		line_tot_amt LIKE orderdetl.line_tot_amt, 
		autoinsert_flag LIKE orderdetl.autoinsert_flag 
	END RECORD 
	DEFINE l_idx SMALLINT
	
	DECLARE c1_orderdetl cursor FOR 
	SELECT * FROM t_orderdetl 
	ORDER BY line_num 

	LET l_idx = 0 


	FOREACH c1_orderdetl INTO l_rec_orderdetl.* 
		LET l_idx = l_idx + 1 
		IF l_rec_orderdetl.line_num != l_idx THEN 
			UPDATE t_orderdetl 
			SET line_num = l_idx 
			WHERE line_num = l_rec_orderdetl.line_num 
		END IF 
		LET l_arr_rec_orderdetl[l_idx].line_num = l_idx 
		LET l_arr_rec_orderdetl[l_idx].offer_code = l_rec_orderdetl.offer_code 
		LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl.part_code 
		LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl.sold_qty 
		LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl.bonus_qty 
		LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_orderdetl.disc_per 
		LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl.unit_price_amt 
		IF glob_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl.sold_qty	* (l_rec_orderdetl.unit_tax_amt+ l_rec_orderdetl.unit_price_amt) 
		ELSE 
			LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl.unit_price_amt 	* l_rec_orderdetl.sold_qty 
		END IF 
		IF l_rec_orderdetl.autoinsert_flag = "Y" THEN 
			LET l_arr_rec_orderdetl[l_idx].autoinsert_flag = "*" 
		ELSE 
			LET l_arr_rec_orderdetl[l_idx].autoinsert_flag = NULL 
		END IF 
		LET l_rec_orderdetl.line_num = l_idx 
	END FOREACH 
		
	RETURN l_arr_rec_orderdetl
END FUNCTION
###########################################################################
# END FUNCTION db_t_orderdetl_get_datasource()
###########################################################################


###########################################################################
# FUNCTION lineitem_scan()
#
#
###########################################################################
FUNCTION lineitem_scan() 
	DEFINE l_rec_orderdetl_curr_row RECORD LIKE orderdetl.* #current row full detail
	DEFINE l_rec_orderdetl_temp RECORD LIKE orderdetl.* #t_orderdetl
	DEFINE l_rec_s_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF RECORD --array[500] OF RECORD 
--		scroll_flag char(1), 
		line_num LIKE orderdetl.line_num, 
		offer_code LIKE orderdetl.offer_code, 
		part_code LIKE orderdetl.part_code, 
		sold_qty LIKE orderdetl.sold_qty, 
		bonus_qty LIKE orderdetl.bonus_qty, 
		disc_per LIKE orderdetl.disc_per, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		line_tot_amt LIKE orderdetl.line_tot_amt, 
		autoinsert_flag LIKE orderdetl.autoinsert_flag 
	END RECORD 
	DEFINE l_minmax_qty FLOAT 
	DEFINE l_horizontal_code char(15) 
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_matrix_prod SMALLINT 
	DEFINE l_reset_offer SMALLINT 
	DEFINE l_comp_prod SMALLINT 
	DEFINE l_upd_flag SMALLINT 
	DEFINE l_int_flag SMALLINT 
	DEFINE l_int_flag_check SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_valid_ind SMALLINT #return value of field validation function
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_errmsg char(60) 
	DEFINE l_lastkey INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE l_dummy LIKE product.part_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_detail_line_count SMALLINT 
	
	LET l_int_flag = FALSE 
	DISPLAY BY NAME glob_rec_orderhead.cust_code 
	DISPLAY BY NAME glob_rec_customer.name_text 

	DISPLAY BY NAME glob_rec_orderhead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

	WHILE TRUE
	
		CALL db_t_orderdetl_get_datasource() RETURNING l_arr_rec_orderdetl 
 		LET l_reset_offer = FALSE 
		LET l_comp_prod = FALSE 
		
		MESSAGE kandoomsg2 ("E",1169,"") 		#1169 F1 TO Add etc...   Ctrl+E Serial Codes
		INPUT ARRAY l_arr_rec_orderdetl WITHOUT DEFAULTS FROM sr_orderdetl.* ATTRIBUTE(UNBUFFERED, delete row = TRUE, insert row = FALSE, auto append = FALSE) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E11d","input-l_arr_rec_orderdetl-1") -- albo kd-502 
--				CALL comboList_prodstatus_productCode             ("part_code",		COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --warehouse existing products
				CALL combolist_prodstatus_productcode_in_warehouse("part_code",   glob_rec_orderhead.ware_code, COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --warehouse existing products
				#CALL glob_rec_orderhead.ware_code, combolist_prodstatus_productcode_in_warehouse
 				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_orderdetl.getSize())
#-------------------------------------------------------
			BEFORE ROW
				LET l_idx = arr_curr() --DISPLAY "BEFORE ROW l_idx=", l_idx
				IF l_idx = 0 THEN
				#DEBUG
					CALL fgl_winmessage("ERROR","BEFORE ROW - LET l_idx = arr_curr() = 0  !!!!","ERROR")
				END IF				
				
				LET l_lastkey = NULL
				IF l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN
					CALL dialog.setActionHidden("DELETE",TRUE)
					CALL dialog.setActionHidden("INSERT",TRUE)
					CALL dialog.setActionHidden("APPEND",TRUE)
				ELSE #WE WOULD NEED SOME VALID ROW FLAG
					IF ( 
						l_rec_orderdetl_curr_row.part_code IS NOT NULL AND
						modu_rec_orderdetl_curr_row.part_code IS NOT NULL AND 
						l_rec_orderdetl_curr_row.part_code  = modu_rec_orderdetl_curr_row.part_code 
					) THEN
						CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_orderdetl.getSize())				
						CALL dialog.setActionHidden("INSERT",NOT l_arr_rec_orderdetl.getSize())
						CALL dialog.setActionHidden("APPEND",NOT l_arr_rec_orderdetl.getSize())
					END IF										
				END IF 
--				LET l_idx = arr_curr()
--				DISPLAY "l_idx=", l_idx 
--				DISPLAY "l_arr_rec_orderdetl.getSize()=", l_arr_rec_orderdetl.getSize()  

#---------------------------------------------------------
{
				#Newly added row
				IF l_rec_orderdetl_curr_row.line_num IS NULL OR l_rec_orderdetl_curr_row.line_num = 0 THEN 
				
					CALL db_t_orderdetl_insert_line(l_idx) RETURNING l_rec_orderdetl_curr_row.*
					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num					 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* #update curr row rec
					INITIALIZE l_rec_s_orderdetl.* TO NULL 
					
					LET l_part_code = NULL 
--					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num 
					IF l_idx > 1 THEN #copy offer code from first line to all other lines
						LET l_arr_rec_orderdetl[l_idx].offer_code = l_arr_rec_orderdetl[l_idx-1].offer_code 
					END IF 
					
					#LET l_arr_rec_orderdetl[l_idx].ware_code = glob_rec_orderhead.ware_code  #we have lost the ware_code information.. needs to be part of each row for product validation prodstatus
					LET l_arr_rec_orderdetl[l_idx].sold_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].bonus_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].disc_per = 0 
					LET l_arr_rec_orderdetl[l_idx].unit_price_amt = 0 
					LET l_arr_rec_orderdetl[l_idx].line_tot_amt = 0
					
				#EXISTING ROW (Edit/View) 
				ELSE 
					LET l_rec_s_orderdetl.* = l_rec_orderdetl_curr_row.* 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* 
					LET l_part_code = l_rec_s_orderdetl.part_code 

					IF l_rec_orderdetl_curr_row.autoinsert_flag = "Y" THEN 
						IF NOT glob_rec_sales_order_parameter.pick_ind AND l_rec_orderdetl_curr_row.picked_qty > 0 THEN 
							IF NOT check_pick_edit() THEN 
								NEXT FIELD line_num --scroll_flag 
							END IF 
						END IF 
						
						IF lineitem_entry(l_rec_orderdetl_curr_row.*) THEN 
						END IF 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 

				CALL disp_total(l_rec_orderdetl_curr_row.*)
				#??? all strange to me 
				IF NOT get_is_screen_navigation_forward() THEN #nav backward
					--NEXT FIELD line_num --scroll_flag 
				ELSE 
					IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN 
						MESSAGE kandoomsg2("E",7090,"") #7090 warning about edit of invoiced lines
					END IF 
--					NEXT FIELD offer_code This breaks everything for the flow 
				END IF 
}
#---------------------------------------------------------

--				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_orderdetl.getSize())
								
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
 
					IF l_arr_rec_orderdetl[l_idx].part_code IS NULL AND l_idx != 1 THEN 
						IF compan_avail(l_arr_rec_orderdetl[l_idx-1].part_code) THEN #Are company products available
							LET l_comp_prod = TRUE 
							MESSAGE kandoomsg2("E",1182,"")	#1182 F1 TO Add; F2...F9 Companion etc..
						ELSE 
							IF l_comp_prod THEN 
								LET l_comp_prod = FALSE 
								MESSAGE kandoomsg2("E",1169,"") 		#1169 F1 TO Add etc...
							END IF 
						END IF 
					
					ELSE 
					
						IF l_comp_prod THEN 
							LET l_comp_prod = FALSE 
							MESSAGE kandoomsg2("E",1169,"") 		#1169 F1 TO Add etc...
						END IF 
					END IF 
					
					SELECT * 
					INTO l_rec_orderdetl_curr_row.* 
					FROM t_orderdetl 
					WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num
					 
					IF status = NOTFOUND THEN #NEW LINE INSERT 
						LET l_rec_orderdetl_curr_row.line_num = NULL
						
--						IF get_is_screen_navigation_forward() THEN 
--							NEXT FIELD line_num 
--						END IF
						 
					ELSE 
						CALL disp_total(l_rec_orderdetl_curr_row.*) 
--						NEXT FIELD line_num --scroll_flag 
					END IF 
			END IF

			AFTER ROW
DISPLAY "AFTER ROW"			
				LET l_idx = arr_curr() 
DISPLAY "AFTER ROW l_idx=", l_idx
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					LET l_int_flag_check = 0
					
					CASE
						#NULL/0 Row
						WHEN l_rec_orderdetl_curr_row.part_code IS NULL OR l_rec_orderdetl_curr_row.sold_qty = 0  
							IF get_is_screen_navigation_forward() THEN
								ERROR "PartCode/Quantity can not be empty"
								NEXT FIELD part_code
							ELSE								
								CALL db_t_orderdetl_delete_row(l_arr_rec_orderdetl[l_idx].line_num)
								CALL l_arr_rec_orderdetl.delete(l_idx)								 
							END IF

						WHEN l_arr_rec_orderdetl[l_idx].line_num != l_rec_orderdetl_curr_row.line_num   
							IF get_is_screen_navigation_forward() THEN
								CALL fgl_Winmessage("internal error","l_arr_rec_orderdetl[l_idx].line_num != l_rec_orderdetl_curr_row.line_num","ERROR")
								NEXT FIELD part_code
							ELSE
								CALL l_arr_rec_orderdetl.delete(l_idx)								 
							END IF
							
						OTHERWISE

					IF l_rec_orderdetl_curr_row.sold_qty = 0 #is this again some field validation ? overkill ?? required ???
					AND l_rec_orderdetl_curr_row.bonus_qty = 0 
					AND l_rec_orderdetl_curr_row.part_code IS NOT NULL THEN 
						IF int_flag OR quit_flag THEN 
							LET l_int_flag_check = 1 
						END IF 
						
						ERROR kandoomsg2("E",9242,l_arr_rec_orderdetl[l_idx].line_num) #9242 WARNING: Order Line ?? has Zero Quantities
						
						IF l_int_flag_check THEN 
							LET int_flag = 1 
						END IF 
					END IF 
					
					IF l_arr_rec_orderdetl[l_idx].sold_qty = 0 #is this again some field validation ? overkill ?? required ???
					AND l_arr_rec_orderdetl[l_idx].bonus_qty = 0 
					AND l_arr_rec_orderdetl[l_idx].part_code IS NOT NULL THEN 
						IF int_flag OR quit_flag THEN 
							LET l_int_flag_check = 1 
						END IF 
						ERROR kandoomsg2("E",9242,l_arr_rec_orderdetl[l_idx].line_num) #9242 WARNING: Order Line ?? has Zero Quantities
						IF l_int_flag_check THEN 
							LET int_flag = 1 
						END IF 
					END IF 
--					LET l_arr_rec_orderdetl[l_idx].scroll_flag = NULL 

					
				#------------------------
				#Validate current row before leaving - only leave if it's valid
				IF validate_row_generic(l_rec_orderdetl_curr_row.*) THEN #quick generic row validation from previous row
					CALL validate_field("ALL",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* #detailed row validation and completion
					IF NOT l_valid_ind THEN
						ERROR "Complete current row input prior to adding another row"
						NEXT FIELD part_code
					ELSE
						CALL db_t_orderdetl_update_line(l_rec_orderdetl_curr_row.*) 					
					END IF
				END IF
				#------------------------

					END CASE 

				END IF 

			#-----------------------------------------------------
			# FIELD line_num
			#-----------------------------------------------------
			# BEFORE FIELD -----------------
			BEFORE FIELD line_num 
				IF l_lastkey IS NULL THEN 
					LET l_lastkey = fgl_lastkey() 
				END IF 
{
				#Newly added row
				IF l_rec_orderdetl_curr_row.line_num IS NULL OR l_rec_orderdetl_curr_row.line_num = 0 THEN 
				
					CALL db_t_orderdetl_insert_line(l_idx) RETURNING l_rec_orderdetl_curr_row.*
					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num					 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* #update curr row rec
					INITIALIZE l_rec_s_orderdetl.* TO NULL 
					
					LET l_part_code = NULL 
--					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num 
					IF l_idx > 1 THEN #copy offer code from first line to all other lines
						LET l_arr_rec_orderdetl[l_idx].offer_code = l_arr_rec_orderdetl[l_idx-1].offer_code 
					END IF 
					
					#LET l_arr_rec_orderdetl[l_idx].ware_code = glob_rec_orderhead.ware_code  #we have lost the ware_code information.. needs to be part of each row for product validation prodstatus
					LET l_arr_rec_orderdetl[l_idx].sold_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].bonus_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].disc_per = 0 
					LET l_arr_rec_orderdetl[l_idx].unit_price_amt = 0 
					LET l_arr_rec_orderdetl[l_idx].line_tot_amt = 0
					
				#EXISTING ROW (Edit/View) 
				ELSE 
					LET l_rec_s_orderdetl.* = l_rec_orderdetl_curr_row.* 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* 
					LET l_part_code = l_rec_s_orderdetl.part_code 

					IF l_rec_orderdetl_curr_row.autoinsert_flag = "Y" THEN 
						IF NOT glob_rec_sales_order_parameter.pick_ind AND l_rec_orderdetl_curr_row.picked_qty > 0 THEN 
							IF NOT check_pick_edit() THEN 
--								NEXT FIELD line_num --scroll_flag 
							END IF 
						END IF 
						
						IF lineitem_entry(l_rec_orderdetl_curr_row.*) THEN 
						END IF 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 

				CALL disp_total(l_rec_orderdetl_curr_row.*)
				#??? all strange to me 
				IF NOT get_is_screen_navigation_forward() THEN #nav backward
					--NEXT FIELD line_num --scroll_flag 
				ELSE 
					IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN 
						MESSAGE kandoomsg2("E",7090,"") #7090 warning about edit of invoiced lines
					END IF 
					NEXT FIELD offer_code 
				END IF 
}

			# AFTER FIELD ------------------
			AFTER FIELD line_num 
				LET l_lastkey = fgl_lastkey()
 			
 			ON ACTION "REFRESH"
 				CALL l_arr_rec_orderdetl.clear()
 				CALL db_t_orderdetl_get_datasource() RETURNING l_arr_rec_orderdetl
 				 	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "DETAILS" --customer details / customer invoice submenu 
				CALL cinq_clnt(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) --customer details / customer invoice submenu 
			
			ON ACTION "LOOKUP" infield(offer_code)
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN		 
						LET glob_temp_text = 
						"exists(SELECT 1 FROM t_orderpart ", 
						"WHERE t_orderpart.offer_code=offersale.offer_code)" 

						LET glob_temp_text = show_offer(glob_rec_kandoouser.cmpy_code,glob_temp_text) 

						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 

						IF glob_temp_text IS NOT NULL THEN 
							LET l_arr_rec_orderdetl[l_idx].offer_code = glob_temp_text 
							NEXT FIELD offer_code 
						END IF 
				END IF
						
			ON ACTION "LOOKUP" infield(part_code)
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 		 
						LET glob_temp_text = 
							"status_ind!='3' AND part_code =", 
							"(SELECT part_code FROM prodstatus ", 
							"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
							"AND ware_code='",glob_rec_orderhead.ware_code,"' ",     -- "AND ware_code='",l_rec_orderdetl_curr_row.ware_code,"' ", 
							"AND part_code=product.part_code ", 
							"AND status_ind!='3')" 
						IF l_arr_rec_orderdetl[l_idx].offer_code IS NOT NULL THEN 
							LET glob_temp_text = 
								glob_temp_text clipped," AND exists ", 
								"(SELECT 1 FROM offerprod ", 
								"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
								"AND offer_code='",l_arr_rec_orderdetl[l_idx].offer_code,"' ", 
								"AND maingrp_code=product.maingrp_code ", 
								"AND (prodgrp_code =product.prodgrp_code ", 
								"OR prodgrp_code IS null)", 
								"AND (part_code =product.part_code ", 
								"OR part_code IS null))" 
						END IF 
						LET glob_temp_text = show_part(glob_rec_kandoouser.cmpy_code,glob_temp_text) 
						IF glob_temp_text IS NOT NULL THEN
						 
							LET l_arr_rec_orderdetl[l_idx].part_code = glob_temp_text 
							NEXT FIELD part_code 
						END IF 
 				END IF
 				
			ON ACTION "CUST PROD CODE LOOKUP"  infield(part_code) --ON KEY (f7) infield(part_code)
			  IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					LET glob_temp_text	= view_custpart_code(glob_rec_kandoouser.cmpy_code,glob_rec_orderhead.cust_code) 
					--OPTIONS INSERT KEY f1, 
					--DELETE KEY f36 
					IF glob_temp_text IS NOT NULL THEN 
						LET l_arr_rec_orderdetl[l_idx].part_code = glob_temp_text 
						--NEXT FIELD part_code 
					END IF 
				END IF
				
			ON ACTION "SPECIAL OFFERS" --ON KEY (f6) infield(scroll_flag)
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					IF l_arr_rec_orderdetl[l_idx].part_code IS NULL AND 
					l_arr_rec_orderdetl[l_idx].sold_qty = 0 AND 
					l_arr_rec_orderdetl[l_idx].bonus_qty = 0 AND 
					l_rec_orderdetl_curr_row.status_ind <> "3" THEN 
						DELETE FROM t_orderdetl   #delete row from temp table
						WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 
					END IF 
					--OPTIONS INSERT KEY f1, 
					--DELETE KEY f36 
					IF offer_entry() THEN 
						LET l_reset_offer = TRUE 
						EXIT INPUT 
					END IF 
 				END IF
 				
 			ON ACTION "AUTO DISC CALC" # Auto discount calc. FOR spec.offers OR conditions
			--ON KEY (f10) infield(scroll_flag) 
					SELECT unique 1 FROM t_orderpart 
					IF sqlca.sqlcode = 0 OR glob_rec_orderhead.cond_code IS NOT NULL THEN 
						## Auto discount calc. FOR spec.offers OR conditions
						EXIT INPUT 
					END IF 

			ON ACTION "F12 what does this do ?" --ON KEY (f12) --infield(scroll_flag) 
					SELECT unique 1 FROM t_orderdetl 
					WHERE part_code IS NOT NULL 
					IF status = 0 THEN 
						CALL display_parent_quantities() 
					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
--					NEXT FIELD scroll_flag 

			ON ACTION "F9InPartCode ? - what does this do ?" infield(part_code) --ON KEY (f9) infield(part_code)  
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 		
					IF l_comp_prod THEN 
						SELECT y.part_code 
						INTO l_arr_rec_orderdetl[l_idx].part_code 
						FROM product x, 
						product y, 
						prodstatus z 
						WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND z.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND x.part_code = l_arr_rec_orderdetl[l_idx-1].part_code 
						AND y.part_code = x.compn_part_code 
						AND y.part_code = z.part_code 
						AND z.ware_code = glob_rec_orderhead.ware_code 
						AND (z.onhand_qty - z.reserved_qty - z.back_qty) > 0 
						IF status = NOTFOUND THEN 
							LET l_arr_rec_orderdetl[l_idx].part_code = show_compan(l_arr_rec_orderdetl[l_idx-1].part_code) 
						END IF 
						NEXT FIELD part_code 
					END IF 
				END IF
				
			ON ACTION "SERIAL?" --ON KEY (control-e) --something to do with serial ?
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					SELECT unique 1 FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_arr_rec_orderdetl[l_idx].part_code 
					AND serial_flag = 'Y' 
					IF status <> NOTFOUND THEN 
						LET l_cnt = serial_count(l_arr_rec_orderdetl[l_idx].part_code, glob_rec_orderhead.ware_code) 
						LET l_cnt = serial_input(l_arr_rec_orderdetl[l_idx].part_code, glob_rec_orderhead.ware_code,l_cnt) 
	
						OPTIONS INSERT KEY f1, 
						DELETE KEY f36 
	
						IF l_cnt < 0 THEN 
							LET l_errmsg = 'unexpected ERROR in e11d. err=', l_cnt 
							CALL errorlog(l_errmsg)
							LET l_errmsg = trim(l_errmsg), "\nExit Program"
							CALL fgl_winmessage("ERROR",l_errmsg,"ERROR")  
							EXIT PROGRAM 
						ELSE 
							IF l_cnt > l_arr_rec_orderdetl[l_idx].sold_qty THEN 
								LET l_rec_orderdetl_curr_row.sold_qty = l_cnt 
								CALL validate_field("sold_qty",l_rec_orderdetl_curr_row.*) 
								RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
								CALL disp_total(l_rec_orderdetl_curr_row.*) 
								LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl_curr_row.sold_qty 
								LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl_curr_row.bonus_qty 
							END IF 
						END IF 
					END IF 
				END IF

			#-----------------------------------------------------
			# ON ACTION INSERT
			#-----------------------------------------------------
			# BEFORE INSERT -----------------
			BEFORE INSERT #we are in new row
				LET l_idx = arr_curr()
--				IF l_arr_rec_orderdetl.getSize() = 1 THEN #we do not need to validate on the first row
--							INITIALIZE l_rec_orderdetl_curr_row.* TO NULL  #not sure if we need this
--							LET l_rec_orderdetl_curr_row.ware_code = glob_rec_orderhead.ware_code #not sure if we need this
--							LET l_rec_orderdetl_curr_row.cust_code = glob_rec_orderhead.cust_code #not sure if we need this
--							LET l_rec_orderdetl_curr_row.order_num = glob_rec_orderhead.order_num #not sure if we need this

--							## default offer TO that of the current line
--							IF l_arr_rec_orderdetl.getSize() > 1 AND l_idx > 1 THEN #note: we work in append row mode (not insert mode)
--								LET l_arr_rec_orderdetl[l_idx].offer_code = l_arr_rec_orderdetl[l_idx-1].offer_code					 
--							END IF 
-------------------------------
				#Newly added row
				IF l_rec_orderdetl_curr_row.line_num IS NULL OR l_rec_orderdetl_curr_row.line_num = 0 THEN 
				
					CALL db_t_orderdetl_insert_line(l_idx) RETURNING l_rec_orderdetl_curr_row.*  #Create/Insert a new row with new line_number
	
					LET l_rec_orderdetl_curr_row.ware_code = glob_rec_orderhead.ware_code #not sure if we need this
					LET l_rec_orderdetl_curr_row.cust_code = glob_rec_orderhead.cust_code #not sure if we need this
					LET l_rec_orderdetl_curr_row.order_num = glob_rec_orderhead.order_num #not sure if we need this
	
					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num					 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* #update curr row rec
					INITIALIZE l_rec_s_orderdetl.* TO NULL 
					
					LET l_part_code = NULL 
--					LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num 
					IF l_idx > 1 THEN #copy offer code from first line to all other lines
						LET l_arr_rec_orderdetl[l_idx].offer_code = l_arr_rec_orderdetl[l_idx-1].offer_code 
					END IF 
	
					
					#LET l_arr_rec_orderdetl[l_idx].ware_code = glob_rec_orderhead.ware_code  #we have lost the ware_code information.. needs to be part of each row for product validation prodstatus
					LET l_arr_rec_orderdetl[l_idx].sold_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].bonus_qty = 0 
					LET l_arr_rec_orderdetl[l_idx].disc_per = 0 
					LET l_arr_rec_orderdetl[l_idx].unit_price_amt = 0 
					LET l_arr_rec_orderdetl[l_idx].line_tot_amt = 0
					
				#EXISTING ROW (Edit/View) 
				ELSE 
					LET l_rec_s_orderdetl.* = l_rec_orderdetl_curr_row.* 
					LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* 
					LET l_part_code = l_rec_s_orderdetl.part_code 

					#This needs checking.. some new row-record wizzard screen ?
					IF l_rec_orderdetl_curr_row.autoinsert_flag = "Y" THEN 
						IF NOT glob_rec_sales_order_parameter.pick_ind AND l_rec_orderdetl_curr_row.picked_qty > 0 THEN 
							IF NOT check_pick_edit() THEN 
--								NEXT FIELD line_num --scroll_flag 
							END IF 
						END IF 
						
						IF lineitem_entry(l_rec_orderdetl_curr_row.*) THEN 
						END IF 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 

				CALL disp_total(l_rec_orderdetl_curr_row.*)
--				
--				#??? all strange to me 
--				IF NOT get_is_screen_navigation_forward() THEN #nav backward
--					--NEXT FIELD line_num --scroll_flag 
--				ELSE 
--					IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN 
--						MESSAGE kandoomsg2("E",7090,"") #7090 warning about edit of invoiced lines
--					END IF 
--					NEXT FIELD offer_code 
--				END IF 

-------------------------------

				--ELSE				
--					IF validate_row_generic(l_rec_orderdetl_curr_row.*) THEN #quick generic row validation from previous row
--						CALL validate_field("ALL",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* #detailed row validation and completion
--						IF NOT l_valid_ind THEN
--							ERROR "Complete current row input prior to adding another row"
--							NEXT FIELD part_code
--						ELSE
--							INITIALIZE l_rec_orderdetl_curr_row.* TO NULL  #not sure if we need this
--							LET l_rec_orderdetl_curr_row.ware_code = glob_rec_orderhead.ware_code #not sure if we need this
--							LET l_rec_orderdetl_curr_row.cust_code = glob_rec_orderhead.cust_code #not sure if we need this
--							LET l_rec_orderdetl_curr_row.order_num = glob_rec_orderhead.order_num #not sure if we need this
			
							## default offer TO that of the current line
--							IF l_arr_rec_orderdetl.getSize() > 1 THEN #note: we work in append row mode (not insert mode)
--								LET l_arr_rec_orderdetl[l_idx].offer_code = l_arr_rec_orderdetl[l_idx-1].offer_code					 
--							END IF 
--							NEXT FIELD line_num 
												
--						END IF
--					ELSE
--						ERROR "Complete current row input prior to adding another row"				
--						NEXT FIELD part_code
--					END IF		
--				END IF 
--				IF l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN
--					NEXT FIELD part_code
--				ELSE
--					CALL validate_field("ALL",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.*
--					IF NOT l_valid_ind THEN
--						NEXT FIELD part_code						
--					END IF
--				END IF
					 
				--INITIALIZE l_arr_rec_orderdetl[l_idx].* TO NULL 
			# AFTER INSERT ------------------------
			AFTER INSERT
				DISPLAY "AFTER INSERT"			
				LET l_idx = arr_curr() DISPLAY "AFTER INSERT l_idx=", l_idx
				
--			BEFORE FIELD scroll_flag 
--				OPTIONS INSERT KEY f1, 
--				DELETE KEY f36 
--				LET l_idx = arr_curr() 
--				LET scrn = scr_line() 
--				DISPLAY l_arr_rec_orderdetl[l_idx].* TO sr_orderdetl[scrn].* 

--			AFTER FIELD scroll_flag 
--				LET l_idx = arr_curr()
--				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
--					IF fgl_lastkey() = fgl_keyval("down") AND l_arr_rec_orderdetl[l_idx].line_num IS NULL THEN 
--						NEXT FIELD line_num 
--					END IF
--				END IF
--				LET l_lastkey = fgl_lastkey()
				 

			#-----------------------------------------------------
			# FIELD offer_code
			#-----------------------------------------------------				 
			# BEFORE FIELD -----------------
			BEFORE FIELD offer_code 
				IF NOT glob_rec_sales_order_parameter.pick_ind AND l_rec_orderdetl_curr_row.picked_qty > 0 THEN 
					IF NOT check_pick_edit() THEN 
						--NEXT FIELD line_num --scroll_flag ????? 
					END IF 
				END IF 
				
				IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN
					IF NOT get_is_screen_navigation_forward() THEN #backward 
----						NEXT FIELD line_num --scroll_flag 
					ELSE 
						NEXT FIELD part_code 
					END IF 
				END IF 
				
				SELECT unique 1 FROM t_orderpart 
				WHERE offer_code != "###" 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_arr_rec_orderdetl[l_idx].offer_code = NULL 
					## IF no offers nominated THEN noentry TO field
					IF NOT get_is_screen_navigation_forward() THEN #backward 
					--IF l_lastkey = fgl_keyval("left")	OR l_lastkey = fgl_keyval("up") THEN 
--						NEXT FIELD line_num --scroll_flag 
					ELSE 
--						NEXT FIELD part_code 
					END IF 
				END IF
			
			# AFTER FIELD ------------------	 
			AFTER FIELD offer_code 
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_orderdetl_curr_row.offer_code = l_arr_rec_orderdetl[l_idx].offer_code
				 
				CALL validate_field("offer_code",l_rec_orderdetl_curr_row.*)RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				CALL disp_total(l_rec_orderdetl_curr_row.*) 
				
				LET l_arr_rec_orderdetl[l_idx].offer_code = l_rec_orderdetl_curr_row.offer_code 

				IF l_valid_ind THEN 
					CASE 
						#ACCEPT
						WHEN l_lastkey=fgl_keyval("ACCEPT") 
							NEXT FIELD autoinsert_flag ### line DISPLAY
--						#Forward 					
--						WHEN get_is_screen_navigation_forward()
--							NEXT FIELD NEXT
						#Backward 					
--						WHEN NOT get_is_screen_navigation_forward()
--							IF l_arr_rec_orderdetl[l_idx].offer_code IS NULL	AND l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN 
--								NEXT FIELD offer_code 
--							ELSE 
--								NEXT FIELD previous 
--							END IF 
--						OTHERWISE
--							CALL get_debug_information("#5342 Internal 4gl error\nE11d.4gl FUNCTION lineitem_scan() ")
--							NEXT FIELD offer_code 
					END CASE 
				ELSE 
					NEXT FIELD offer_code #wrong input, try again
				END IF 
								

			#-----------------------------------------------------
			# FIELD part_code 
			#-----------------------------------------------------				
			# BEFORE FIELD ----------------- 
			BEFORE FIELD part_code 
				LET glob_temp_text= 
					"status_ind!='3' AND part_code =", 
					"(SELECT part_code FROM prodstatus ", 
					"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
					"AND ware_code='",l_rec_orderdetl_curr_row.ware_code,"' ", 
					"AND part_code=product.part_code ", 
					"AND status_ind!='3')" 
				IF l_arr_rec_orderdetl[l_idx].offer_code IS NOT NULL THEN 
					LET glob_temp_text=
						glob_temp_text clipped," AND exists ", 
						"(SELECT 1 FROM offerprod ", 
						"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
						"AND offer_code='",l_arr_rec_orderdetl[l_idx].offer_code,"' ", 
						"AND maingrp_code=product.maingrp_code ", 
						"AND (prodgrp_code =product.prodgrp_code ", 
						"OR prodgrp_code IS null)", 
						"AND (part_code =product.part_code ", 
						"OR part_code IS null))" 
				END IF 
			--DISPLAY glob_temp_text

--			CALL combolist_productcode_where_text("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,glob_temp_text,COMBO_NULL_NOT)
			--CALL comboList_productCode("part_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

				IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_arr_rec_orderdetl[l_idx].part_code 
					## offer edit NOT allowed on invoiced lines
					IF NOT get_is_screen_navigation_forward() THEN #backward 
					--IF l_lastkey = fgl_keyval("left") OR l_lastkey = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 

			ON CHANGE part_code
				IF db_prodstatus_get_onhand_qty(modu_rec_orderdetl_curr_row.cmpy_code,modu_rec_orderdetl_curr_row.ware_code,l_arr_rec_orderdetl[l_idx].part_code) <= 0 THEN
					ERROR "This product is not available on stock! Loading Product Status Details..." SLEEP 2
					CALL db_prodstatus_show_availability(modu_rec_orderdetl_curr_row.cmpy_code,modu_rec_orderdetl_curr_row.ware_code,l_arr_rec_orderdetl[l_idx].part_code,"Availability")
				END IF
			
			# AFTER FIELD ------------------					
			AFTER FIELD part_code
				IF l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN
					IF get_is_screen_navigation_forward() THEN
						ERROR "Product Code can not be empty"
						SLEEP 1
						NEXT FIELD part_code
					ELSE
						#------------------------------------
						SELECT count(*)
						INTO l_detail_line_count 
						FROM t_orderdetl
						WHERE line_num = l_idx
						
						IF l_detail_line_count > 0 THEN #delete row from temp table
							DELETE FROM t_orderdetl   #delete row from temp table
							WHERE line_num = l_idx
						END IF 
						
						CALL l_arr_rec_orderdetl.delete(l_idx) #delete from array #We could also read the entire table in this case
						NEXT FIELD part_code
						#--------------------------------------
					END IF
				END IF 
				
				LET l_lastkey = fgl_lastkey() 
				
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = l_arr_rec_orderdetl[l_idx].part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL matrix_break_prod(glob_rec_kandoouser.cmpy_code, l_rec_product.part_code,	l_rec_product.class_code, 0) 
				RETURNING 
					l_dummy, 
					l_horizontal_code, 
					l_dummy, 
					l_dummy  #HuHo: ?????? what is this dummy dummy dummy ??? 

				IF l_rec_product.serial_flag = 'Y'	OR (l_horizontal_code IS NOT NULL	AND l_horizontal_code != " ") THEN 

					FOR i = 1 TO arr_count() 
						IF i <> l_idx AND l_arr_rec_orderdetl[l_idx].part_code	= l_arr_rec_orderdetl[i].part_code THEN 
							IF l_rec_product.serial_flag = 'Y' THEN 
								ERROR kandoomsg2("I",9292,"") #9292 Serial Products can only occur once.
							ELSE 
								ERROR kandoomsg2("E",9270,"") 	#9270 Matrix products can only be entered once.
							END IF 
							
							LET l_arr_rec_orderdetl[l_idx].part_code = NULL 
							NEXT FIELD part_code 
						END IF 
					END FOR 
				END IF
				 
				LET l_rec_orderdetl_curr_row.part_code = l_arr_rec_orderdetl[l_idx].part_code 

				IF (l_part_code IS NULL AND l_rec_orderdetl_curr_row.part_code IS NOT null) OR 
				l_rec_orderdetl_curr_row.part_code != l_part_code OR 
				(l_rec_orderdetl_curr_row.part_code IS NULL AND l_part_code IS NOT null) THEN 
					## force change of lineinfo on change of partcode
					LET l_part_code = l_rec_orderdetl_curr_row.part_code 
					LET l_rec_orderdetl_curr_row.order_qty = 0 
					LET l_rec_orderdetl_curr_row.sold_qty = 0 
					LET l_rec_orderdetl_curr_row.bonus_qty = 0 
					LET l_rec_orderdetl_curr_row.sched_qty = 0 
					LET l_rec_orderdetl_curr_row.back_qty = 0 
					LET l_rec_orderdetl_curr_row.unit_price_amt = NULL 
					LET l_rec_orderdetl_curr_row.desc_text = NULL 
				END IF
				 
				CALL validate_field("part_code",l_rec_orderdetl_curr_row.*) 
				RETURNING 
					l_valid_ind,
					l_rec_orderdetl_curr_row.*
				 
				CALL disp_total(l_rec_orderdetl_curr_row.*)
				
				CALL morph_orderdetl_rec_to_arr_row(l_rec_orderdetl_curr_row.*,l_arr_rec_orderdetl[l_idx].*) RETURNING l_arr_rec_orderdetl[l_idx].* 

--				LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl_curr_row.part_code 
--				LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl_curr_row.sold_qty 
--				LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl_curr_row.bonus_qty 
--				LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_orderdetl_curr_row.disc_per 
--				LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl_curr_row.unit_price_amt 
				
				IF l_valid_ind THEN 
					CASE 
						WHEN get_is_screen_navigation_forward() #forward
							IF l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN 
								ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
								NEXT FIELD part_code 
							ELSE 
								SELECT * INTO l_rec_product.* FROM product 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = l_arr_rec_orderdetl[l_idx].part_code
								
								IF l_arr_rec_orderdetl[l_idx].sold_qty = 0 THEN 
									ERROR "Order Quantitiy is required!"
									NEXT FIELD NEXT
								END IF 
								--NEXT FIELD NEXT 
							END IF 
							
						WHEN NOT get_is_screen_navigation_forward() #backward
							IF l_arr_rec_orderdetl.getLength() > 0 AND l_idx > 0 AND l_idx <= l_arr_rec_orderdetl.getLength() THEN


								#------------------------------------ --users wants to leave empty or invalid row - remove it
								SELECT count(*)
								INTO l_detail_line_count 
								FROM t_orderdetl
								WHERE line_num = l_idx
								
								IF l_detail_line_count > 0 THEN #delete row from temp table
									DELETE FROM t_orderdetl 
									WHERE line_num = l_idx
								END IF 
								
								CALL l_arr_rec_orderdetl.delete(l_idx) #delete from array #We could also read the entire table in this case
								#--------------------------------------


							END IF 
							--NEXT FIELD part_code 

						WHEN get_action_is_save()
							NEXT FIELD autoinsert_flag ### line DISPLAY

						WHEN l_lastkey=fgl_keyval("ACCEPT")
							NEXT FIELD autoinsert_flag ### line DISPLAY 

						OTHERWISE 
							NEXT FIELD part_code 
					END CASE 
				ELSE 
					NEXT FIELD part_code 
				END IF

			#-----------------------------------------------------
			# FIELD sold_qty 
			#-----------------------------------------------------
			# BEFORE FIELD -----------------						 
			BEFORE FIELD sold_qty
				LET l_matrix_prod = FALSE 
				IF initialize_matrix(l_rec_product.*,glob_rec_orderhead.ware_code, glob_rec_orderhead.cust_code,"O") THEN 
					LET l_matrix_prod = TRUE 
				END IF 
				
				IF l_matrix_prod THEN 
					DECLARE c9_orderdetl cursor FOR 
					SELECT * FROM t_orderdetl 
					WHERE part_code IS NOT NULL 
					ORDER BY part_code 
				
					FOREACH c9_orderdetl INTO l_rec_orderdetl_temp.* 
						IF l_rec_orderdetl_temp.inv_qty > 0 THEN 
							LET l_minmax_qty = l_rec_orderdetl_temp.inv_qty - l_rec_orderdetl_temp.bonus_qty 
						ELSE 
							LET l_minmax_qty = 0 
						END IF 
						CALL initialize_matrix_quantity(l_rec_orderdetl_temp.part_code, 
						l_rec_orderdetl_temp.sold_qty, 
						l_minmax_qty, 
						l_rec_orderdetl_temp.line_num) 
					END FOREACH 
				
					IF matrix_entry() THEN 
						CALL matrix_break_prod(
							glob_rec_kandoouser.cmpy_code, 
							l_arr_rec_orderdetl[l_idx].part_code, 
							l_rec_product.class_code,
							0) 
						RETURNING 
							l_dummy, 
							l_horizontal_code, 
							l_dummy, 
							l_dummy 
						IF l_horizontal_code IS NULL OR l_horizontal_code = " " THEN 
							DELETE FROM t_orderdetl #DELETE row from temp table
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 
						END IF 
						
						IF matrix_insert() THEN 
							LET l_reset_offer = TRUE 
							EXIT INPUT 
						END IF 
					END IF 
					
					NEXT FIELD line_num --scroll_flag 
				END IF 
			#ON CHANGE --------------------------
			ON CHANGE sold_qty
				LET l_rec_orderdetl_curr_row.sold_qty = l_arr_rec_orderdetl[l_idx].sold_qty 
			
				CALL validate_field("sold_qty",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl_curr_row.line_tot_amt
				CALL disp_total(l_rec_orderdetl_curr_row.*) 

			# AFTER FIELD ------------------			
			AFTER FIELD sold_qty 
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_orderdetl_curr_row.sold_qty = l_arr_rec_orderdetl[l_idx].sold_qty 
			
				CALL validate_field("sold_qty",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				
				CALL disp_total(l_rec_orderdetl_curr_row.*) 
				#Update validate return values to current row
				CALL morph_orderdetl_rec_to_arr_row(l_rec_orderdetl_curr_row.*,l_arr_rec_orderdetl[l_idx].*) RETURNING l_arr_rec_orderdetl[l_idx].* 
				
--				#Update validate return values to current row
--				LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl_curr_row.sold_qty 
--				LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl_curr_row.bonus_qty 

				IF l_valid_ind THEN 
					CASE 
						#ACCEPT
						WHEN l_lastkey=fgl_keyval("ACCEPT") 
							NEXT FIELD autoinsert_flag ### line DISPLAY
--						#Forward #natural navigation 					
--						WHEN get_is_screen_navigation_forward()
--							NEXT FIELD NEXT
--						#Backward #natural navigation 					
--						WHEN NOT get_is_screen_navigation_forward()
--							NEXT FIELD previous
--						OTHERWISE
--							CALL get_debug_information("#5342 Internal 4gl error\nE11d.4gl FUNCTION lineitem_scan() ")
--							NEXT FIELD sold_qty 
					END CASE 
				ELSE 
					NEXT FIELD sold_qty 
				END IF 

			#-----------------------------------------------------
			# FIELD bonus_qty 
			#-----------------------------------------------------	
			# BEFORE FIELD -----------------
			BEFORE FIELD bonus_qty ## cannot enter bonus Quantity if offer_code is empty -> IF bonus_flag = n
				DISPLAY "BEFORE FIELD bonus_qty" 
				IF glob_rec_orderhead.cond_code IS NULL AND l_rec_orderdetl_curr_row.offer_code IS NULL THEN 
					LET l_rec_product.bonus_allow_flag = "N" 
				END IF 
				
				IF l_rec_product.bonus_allow_flag = "N" 
				OR l_rec_product.serial_flag = 'Y' 
				OR l_rec_orderdetl_curr_row.trade_in_flag = "Y" 
				OR l_rec_orderdetl_curr_row.part_code IS NULL THEN 
					LET l_arr_rec_orderdetl[l_idx].bonus_qty = 0
					IF NOT get_is_screen_navigation_forward() THEN #backward  
						--IF l_lastkey=fgl_keyval("left") OR l_lastkey=fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			
			# AFTER FIELD ------------------
			AFTER FIELD bonus_qty 
			DISPLAY "AFTER FIELD bonus_qty"			
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_orderdetl_curr_row.bonus_qty = l_arr_rec_orderdetl[l_idx].bonus_qty
				 
				CALL validate_field("bonus_qty",l_rec_orderdetl_curr_row.*)		RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				CALL disp_total(l_rec_orderdetl_curr_row.*) 
				
				LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl_curr_row.bonus_qty
				 
				IF l_valid_ind THEN 
					CASE 
						#ACCEPT
						WHEN l_lastkey=fgl_keyval("ACCEPT") 
							NEXT FIELD autoinsert_flag ### line DISPLAY
						#Forward 					
						WHEN get_is_screen_navigation_forward()
							NEXT FIELD NEXT
						#Backward 					
						WHEN NOT get_is_screen_navigation_forward()
							NEXT FIELD previous
						OTHERWISE
							CALL get_debug_information("#5342 Internal 4gl error\nE11d.4gl FUNCTION lineitem_scan() ") 
							NEXT FIELD bonus_qty 
					END CASE 
				ELSE 
					NEXT FIELD sold_qty  #??? why not bonus_qty ??? 
				END IF 

			#-----------------------------------------------------
			# FIELD disc_per
			#-----------------------------------------------------
			# BEFORE FIELD -----------------
			BEFORE FIELD disc_per
				DISPLAY "BEFORE FIELD disc_per"			 
				LET l_rec_orderdetl_curr_row.order_qty = l_arr_rec_orderdetl[l_idx].bonus_qty	+ l_arr_rec_orderdetl[l_idx].sold_qty 
				IF l_rec_orderdetl_curr_row.inv_qty = 0 AND l_rec_orderdetl_curr_row.status_ind = "0" THEN 
					##### PROMPT TO SELL UP WHOLE CARTON
					IF l_rec_product.stock_uom_code != l_rec_product.sell_uom_code 
					AND l_rec_product.stk_sel_con_qty > 1 THEN 
						LET i =(l_rec_orderdetl_curr_row.order_qty/l_rec_product.stk_sel_con_qty)+0.5 
						LET j =(i * l_rec_product.stk_sel_con_qty) 
						IF l_rec_orderdetl_curr_row.order_qty >= (glob_rec_opparms.sellup_per/100)*j 
						AND l_rec_orderdetl_curr_row.order_qty < j THEN 
							IF kandoomsg("E",8014,j) = "Y" THEN 
								## Do you want TO change TO qty TO entire carton
								LET l_arr_rec_orderdetl[l_idx].sold_qty = 
								l_arr_rec_orderdetl[l_idx].sold_qty+j- l_rec_orderdetl_curr_row.order_qty 
								NEXT FIELD sold_qty 
							END IF 
						END IF 
					END IF 
				END IF 
				
				IF l_rec_orderdetl_curr_row.offer_code IS NOT NULL 
				OR l_rec_orderdetl_curr_row.inv_qty != 0 
				OR l_rec_orderdetl_curr_row.disc_allow_flag = "N" THEN 
					NEXT FIELD autoinsert_flag 
				END IF

			# AFTER FIELD ------------------
			AFTER FIELD disc_per 
				DISPLAY "AFTER FIELD disc_per"			
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_orderdetl_curr_row.disc_per = l_arr_rec_orderdetl[l_idx].disc_per 

				CALL validate_field("disc_per",l_rec_orderdetl_curr_row.*)	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				CALL disp_total(l_rec_orderdetl_curr_row.*) 

				#Update validate return values to current row
				CALL morph_orderdetl_rec_to_arr_row(l_rec_orderdetl_curr_row.*,l_arr_rec_orderdetl[l_idx].*) RETURNING l_arr_rec_orderdetl[l_idx].* 
--				LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_orderdetl_curr_row.disc_per 
--				LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl_curr_row.unit_price_amt 

				IF l_valid_ind THEN 
					CASE 
						#ACCEPT
						WHEN l_lastkey=fgl_keyval("ACCEPT") 
							NEXT FIELD autoinsert_flag ### line DISPLAY
						#Forward #use natural navigation 					
						#WHEN get_is_screen_navigation_forward()
						#	NEXT FIELD NEXT
						#Backward 					
						#WHEN NOT get_is_screen_navigation_forward()
						#	NEXT FIELD previous
					END CASE 
				ELSE 
					NEXT FIELD disc_per 
				END IF

			#-----------------------------------------------------
			# FIELD unit_price_amt /sell price
			#-----------------------------------------------------	
			# BEFORE FIELD -----------------			 
			BEFORE FIELD unit_price_amt
				DISPLAY "BEFORE FIELD unit_price_amt"			 
				IF l_rec_orderdetl_curr_row.offer_code IS NOT NULL OR l_rec_orderdetl_curr_row.disc_allow_flag = "N" THEN 
					NEXT FIELD autoinsert_flag 
				END IF
			
			# AFTER FIELD ------------------	 
			AFTER FIELD unit_price_amt 
				DISPLAY "AFTER FIELD unit_price_amt"			
				LET l_lastkey = fgl_lastkey() 
				LET l_rec_orderdetl_curr_row.unit_price_amt = l_arr_rec_orderdetl[l_idx].unit_price_amt 
				
				CALL validate_field("unit_price_amt",l_rec_orderdetl_curr_row.*) 	RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				CALL disp_total(l_rec_orderdetl_curr_row.*) 
				
				CALL morph_orderdetl_rec_to_arr_row(l_rec_orderdetl_curr_row.*,l_arr_rec_orderdetl[l_idx].*) RETURNING l_arr_rec_orderdetl[l_idx].* 
--				LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_orderdetl_curr_row.disc_per 
--				LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl_curr_row.unit_price_amt 


				IF l_valid_ind THEN 
					CASE 
						#ACCEPT
						WHEN l_lastkey=fgl_keyval("ACCEPT") 
							NEXT FIELD autoinsert_flag ### line DISPLAY
						#Forward 					
						WHEN get_is_screen_navigation_forward()
							NEXT FIELD autoinsert_flag --we are in the last active INPUT array field.. next field = save row
						#Backward 					
--						WHEN NOT get_is_screen_navigation_forward()
--							NEXT FIELD previous
--						OTHERWISE
--							CALL get_debug_information("#5342 Internal 4gl error\nE11d.4gl FUNCTION lineitem_scan() ") 
--							NEXT FIELD unit_price_amt 
					END CASE 
				ELSE 
					NEXT FIELD unit_price_amt 
				END IF


{
				IF l_valid_ind THEN 
					IF get_is_screen_navigation_forward() THEN
						NEXT FIELD autoinsert_flag
					ELSE
						NEXT FIELD previous
					END IF
					
					CALL validate_field("ALL",l_rec_orderdetl_curr_row.*) RETURNING l_valid_ind,l_rec_orderdetl_curr_row.*
				END IF
									
--					CASE 
--						WHEN get_is_screen_navigation_forward() 
--						WHEN l_lastkey=fgl_keyval("RETURN") 
--							OR l_lastkey=fgl_keyval("tab") 
--							OR l_lastkey=fgl_keyval("right") 
--							OR l_lastkey=fgl_keyval("down") 
--							NEXT FIELD autoinsert_flag 
--						WHEN l_lastkey=fgl_keyval("left") 
--							OR l_lastkey=fgl_keyval("up") 
--							NEXT FIELD previous 
--						WHEN l_lastkey=fgl_keyval("ACCEPT") 
--							NEXT FIELD autoinsert_flag ### line DISPLAY 
--						OTHERWISE  #joking ? 
--							NEXT FIELD unit_price_amt 
--					END CASE 
--				ELSE 
--					NEXT FIELD unit_price_amt 
--				END IF
}

			#-----------------------------------------------------
			# FIELD line_tot_amt
			#-----------------------------------------------------
			# BEFORE FIELD -----------------				 
			BEFORE FIELD line_tot_amt
				DISPLAY "BEFORE FIELD line_tot_amt"

			# AFTER FIELD ------------------
			AFTER FIELD line_tot_amt
				DISPLAY "AFTER FIELD line_tot_amt"
				--NEXT FIELD NEXT
 
			#-----------------------------------------------------
			# FIELD autoinsert_flag
			#-----------------------------------------------------		
			# BEFORE FIELD -----------------		 
			BEFORE FIELD autoinsert_flag
				LET l_idx = arr_curr()
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					#--------------------------------------
					#Final full row validation
					#--------------------------------------
					CALL validate_field("ALL",l_rec_orderdetl_curr_row.*) RETURNING l_valid_ind,l_rec_orderdetl_curr_row.*
					IF NOT l_valid_ind THEN
						NEXT FIELD part_code					
					END IF 
					#--------------------------------------

					SELECT * 
					INTO l_rec_orderdetl_curr_row.* 
					FROM t_orderdetl 
					WHERE line_num = l_rec_orderdetl_curr_row.line_num 

					IF (modu_rec_orderdetl_curr_row.part_code IS NULL AND l_rec_orderdetl_curr_row.part_code IS NOT null) 
					OR modu_rec_orderdetl_curr_row.part_code != l_rec_orderdetl_curr_row.part_code 
					OR modu_rec_orderdetl_curr_row.sched_qty != l_rec_orderdetl_curr_row.sched_qty 
					OR modu_rec_orderdetl_curr_row.conf_qty != l_rec_orderdetl_curr_row.conf_qty 
					OR modu_rec_orderdetl_curr_row.back_qty != l_rec_orderdetl_curr_row.back_qty 
					OR modu_rec_orderdetl_curr_row.status_ind != l_rec_orderdetl_curr_row.status_ind THEN
					 
						CALL db_t_orderdetl_update_line(modu_rec_orderdetl_curr_row.*) 

						LET l_rec_orderdetl_curr_row.sched_qty = modu_rec_orderdetl_curr_row.sched_qty 

						CALL allocate_stock(l_rec_orderdetl_curr_row.*,1) RETURNING l_rec_orderdetl_curr_row.* 
						CALL db_t_orderdetl_update_line(l_rec_orderdetl_curr_row.*) 

						WHILE TRUE #------------------------------------------------- 
							LET l_upd_flag = 1 
							
							BEGIN WORK 
								CALL db_t_orderdetl_update_line(modu_rec_orderdetl_curr_row.*) 
								LET l_upd_flag = stock_line(modu_rec_orderdetl_curr_row.line_num,TRAN_TYPE_INVOICE_IN,1) 
								
								IF l_upd_flag = -1 THEN 
									CONTINUE WHILE 
								ELSE 
									IF l_upd_flag = 0 THEN 
										CALL db_t_orderdetl_update_line(modu_rec_orderdetl_curr_row.*) 
										LET l_rec_orderdetl_curr_row.* = modu_rec_orderdetl_curr_row.* 
										EXIT WHILE 
									END IF 
								END IF 
	
								CALL db_t_orderdetl_update_line(l_rec_orderdetl_curr_row.*) 
	
								LET l_upd_flag = stock_line(l_rec_orderdetl_curr_row.line_num,"OUT",1) 
	
								IF l_upd_flag = -1 THEN 
									CONTINUE WHILE 
								ELSE 
									IF l_upd_flag = 0 THEN 
										CALL db_t_orderdetl_update_line(modu_rec_orderdetl_curr_row.*) 
										LET l_rec_orderdetl_curr_row.* = modu_rec_orderdetl_curr_row.* 
										EXIT WHILE 
									END IF 
								END IF 
	
							COMMIT WORK 
	
							EXIT WHILE 
						END WHILE 
					END IF 
	
					LET l_arr_rec_orderdetl[l_idx].offer_code = l_rec_orderdetl_curr_row.offer_code 
					LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl_curr_row.part_code 
					LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_orderdetl_curr_row.sold_qty 
					LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_orderdetl_curr_row.bonus_qty 
					LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_orderdetl_curr_row.disc_per 
					LET l_arr_rec_orderdetl[l_idx].unit_price_amt = l_rec_orderdetl_curr_row.unit_price_amt 
	
					IF glob_rec_arparms.show_tax_flag = "N" THEN 
						LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl_curr_row.ext_price_amt 
					ELSE 
						LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_orderdetl_curr_row.line_tot_amt 
					END IF 
	
					CALL disp_total(l_rec_orderdetl_curr_row.*) 
	
					#ACCEPT OR CANCEL
					IF l_lastkey = fgl_keyval("INTERRUPT") OR l_lastkey = fgl_keyval("ACCEPT") THEN 
						## IF line entry NOT complete THEN RETURN TO scroll flag
						NEXT FIELD line_num --scroll_flag
					ELSE		
						CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_orderdetl.getSize())				
						CALL dialog.setActionHidden("INSERT",NOT l_arr_rec_orderdetl.getSize())
						CALL dialog.setActionHidden("APPEND",NOT l_arr_rec_orderdetl.getSize())
 				END IF 
				END IF #check if l_idx > 0

			# AFTER FIELD ------------------
			AFTER FIELD autoinsert_flag 
				DISPLAY "AFTER FIELD autoinsert_flag"					
				LET l_lastkey = fgl_lastkey() 

			ON ACTION "VALIDATE" --ON KEY (f8) infield(scroll_flag) ## extract & validate current field
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					CASE
{			
						WHEN infield(scroll_flag)
						
							LET glob_temp_text = "scroll_flag" 
							INITIALIZE modu_rec_orderdetl_curr_row.* TO NULL 
							SELECT * INTO modu_rec_orderdetl_curr_row.* FROM t_orderdetl 
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 

							IF modu_rec_orderdetl_curr_row.line_num IS NULL THEN 
								CALL db_t_orderdetl_insert_line(l_idx) RETURNING l_rec_orderdetl_curr_row.*
								 
								LET modu_rec_orderdetl_curr_row.* = l_rec_orderdetl_curr_row.* 
								
								INITIALIZE l_rec_s_orderdetl.* TO NULL 
								
								LET l_part_code = NULL 
								LET l_arr_rec_orderdetl[l_idx].line_num = l_rec_orderdetl_curr_row.line_num 
								
								IF l_idx > 1 THEN 
									LET l_arr_rec_orderdetl[l_idx].offer_code	= l_arr_rec_orderdetl[l_idx-1].offer_code 
								END IF 
								
								LET l_arr_rec_orderdetl[l_idx].sold_qty = 0 
								LET l_arr_rec_orderdetl[l_idx].bonus_qty = 0 
								LET l_arr_rec_orderdetl[l_idx].disc_per = 0 
								LET l_arr_rec_orderdetl[l_idx].unit_price_amt = 0 
								LET l_arr_rec_orderdetl[l_idx].line_tot_amt = 0 
							ELSE 

								IF NOT glob_rec_sales_order_parameter.pick_ind AND modu_rec_orderdetl_curr_row.picked_qty > 0 THEN 
									IF NOT check_pick_edit() THEN 
										NEXT FIELD scroll_flag 
									END IF 
								END IF 
							END IF 
	}
						WHEN infield(offer_code)
							LET glob_temp_text = "offer_code"
							LET modu_rec_orderdetl_curr_row.offer_code = l_arr_rec_orderdetl[l_idx].offer_code
	
						WHEN infield(part_code)
							LET glob_temp_text = "part_code"
	
						WHEN infield(sold_qty)
							LET glob_temp_text = "sold_qty"												
	
						WHEN infield(bonus_qty)
							LET glob_temp_text = "bonus_qty"
	
						WHEN infield(disc_per)
							LET glob_temp_text = "disc_per"
	
						WHEN infield(unit_price_amt)
							LET glob_temp_text = "unit_price_amt"
																			  					
						OTHERWISE
							LET glob_temp_text = "scroll_flag"
							select * into modu_rec_orderdetl_curr_row.* 
							from t_orderdetl
	            where line_num = l_arr_rec_orderdetl[l_idx].line_num											  					
				END CASE
				
				LET modu_rec_orderdetl_curr_row.* = l_arr_rec_orderdetl[l_idx].*
					CALL validate_field(glob_temp_text,l_rec_orderdetl_curr_row.*)		RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
					IF l_valid_ind THEN 
						IF lineitem_entry(l_rec_orderdetl_curr_row.*) THEN 
							NEXT FIELD autoinsert_flag 
						END IF 
					END IF 
			END IF			
{
			ON KEY (f8) infield(offer_code) 
						LET glob_temp_text = "offer_code" 
						LET l_rec_orderdetl_curr_row.offer_code = get_fldbuf(offer_code) 
						IF length(l_rec_orderdetl_curr_row.offer_code) = 0 THEN 
							## get_fldbuf returns spaces instead of nulls
							LET l_rec_orderdetl_curr_row.offer_code = NULL 
						END IF
						 
			ON KEY (f8)  infield(part_code) 
						LET glob_temp_text = "part_code" 
						LET l_rec_orderdetl_curr_row.part_code = get_fldbuf(part_code) 
						IF length(l_rec_orderdetl_curr_row.part_code) = 0 THEN 
							## get_fldbuf returns spaces instead of nulls
							LET l_rec_orderdetl_curr_row.part_code = NULL 
						END IF 
						
			ON KEY (f8) infield(sold_qty) 
						LET glob_temp_text = "sold_qty" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET l_rec_orderdetl_curr_row.sold_qty = get_fldbuf(sold_qty) 
						WHENEVER ERROR stop 
						
			ON KEY (f8) infield(bonus_qty) 
						LET glob_temp_text = "bonus_qty" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET l_rec_orderdetl_curr_row.bonus_qty = get_fldbuf(bonus_qty) 
						WHENEVER ERROR stop 
						
			ON KEY (f8) infield(disc_per) 
						LET glob_temp_text = "disc_per" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET l_rec_orderdetl_curr_row.disc_per = get_fldbuf(disc_per) 
						WHENEVER ERROR stop 
						
			ON KEY (f8) IF infield(unit_price_amt) THEN 
						LET glob_temp_text = "unit_price_amt" 
						WHENEVER ERROR CONTINUE ## in CASE sold = "A" 
						LET l_rec_orderdetl_curr_row.unit_price_amt = get_fldbuf(unit_price_amt) 
						WHENEVER ERROR stop 
						
					ELSE
						IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
							LET glob_temp_text = "scroll_flag" 
							SELECT * INTO l_rec_orderdetl_curr_row.* FROM t_orderdetl 
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num
						END IF 
					END IF
					
				CALL validate_field(glob_temp_text,l_rec_orderdetl_curr_row.*) 
				RETURNING l_valid_ind,l_rec_orderdetl_curr_row.* 
				IF l_valid_ind THEN 
					IF lineitem_entry(l_rec_orderdetl_curr_row.*) THEN 
						NEXT FIELD autoinsert_flag 
					END IF 
				END IF 
}
			BEFORE DELETE
{			
FUNCTION db_t_orderdetl_line_num_exists(p_line_num)
	SELECT count(*) INTO l_ret_count
	FROM t_orderdetl 
	WHERE line_num = p_line_num
	
	RETURN l_ret_count
END FUNCTION

FUNCTION db_t_orderdetl_delete_row(p_line_num)
	DELETE FROM t_orderdetl 
	WHERE line_num = p_line_num
	
	RETURN status
END FUNCTION			
}			
				CASE
					#To delete, array must not be NULL/empty
					WHEN l_idx = 0 OR l_arr_rec_orderdetl.getSize() = 0
						NEXT FIELD line_num

					WHEN l_arr_rec_orderdetl[l_idx].part_code IS NULL #no product.. just delete it
						CALL db_t_orderdetl_delete_row(l_arr_rec_orderdetl[l_idx].line_num)
						
					WHEN l_arr_rec_orderdetl[l_idx].autoinsert_flag IS NOT NULL 
						ERROR kandoomsg2("E",9075,"") #9075 Cannot Delete Automatic Inserted Products"
						NEXT FIELD line_num

					WHEN l_rec_orderdetl_curr_row.inv_qty != 0 
							ERROR kandoomsg2("E",9076,"") #9076 Order lineitem has been delivered; Deletion IS NOT permitted.
							NEXT FIELD line_num 
						
					OTHERWISE 
						IF (NOT glob_rec_sales_order_parameter.pick_ind) AND (l_rec_orderdetl_curr_row.picked_qty > 0) THEN 
							IF NOT check_pick_edit() THEN 
								NEXT FIELD scroll_flag 
							END IF 
						END IF

						IF stock_line(l_arr_rec_orderdetl[l_idx].line_num,TRAN_TYPE_INVOICE_IN,0) THEN 
							CALL serial_delete(l_arr_rec_orderdetl[l_idx].part_code,	glob_rec_orderhead.ware_code) 
							DELETE FROM t_orderdetl #delete row from temp table
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num
							CALL l_arr_rec_orderdetl.delete(l_idx)
							 
							{ 
							### shuffle array
--							LET j = scrn 
							FOR i = l_idx TO arr_count() 
									LET l_arr_rec_orderdetl[i].* = l_arr_rec_orderdetl[i+1].* 
								IF l_arr_rec_orderdetl[i].line_num = 0 THEN 
									INITIALIZE l_arr_rec_orderdetl[i].* TO NULL 
								END IF 
								IF j <= 8 THEN 
									DISPLAY l_arr_rec_orderdetl[i].* TO sr_orderdetl[j].* 

									LET j = j + 1 
								END IF 
							END FOR 
							}
							SELECT * INTO l_rec_orderdetl_curr_row.* FROM t_orderdetl #strange approach
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 
							IF status = NOTFOUND THEN 
								INITIALIZE l_rec_orderdetl_curr_row.* TO NULL 
							END IF
							 
							CALL disp_total(l_rec_orderdetl_curr_row.*)
							 
							NEXT FIELD line_num --scroll_flag 
						ELSE 
							NEXT FIELD line_num --scroll_flag 
						END IF 
						 						 
														
				END CASE
			
			ON KEY (f2) --infield(scroll_flag) #Delete
				IF l_idx > 0 AND l_idx <= l_arr_rec_orderdetl.getSize() THEN 
					IF l_arr_rec_orderdetl[l_idx].part_code IS NULL THEN
						IF l_arr_rec_orderdetl[l_idx].autoinsert_flag IS NOT NULL THEN
 
							ERROR kandoomsg2("E",9075,"") #9075 Cannot Delete Automatic Inserted Products"
							NEXT FIELD scroll_flag 
						END IF 

						IF l_rec_orderdetl_curr_row.inv_qty != 0 THEN 
							ERROR kandoomsg2("E",9076,"") #9076 Order lineitem has been delivered; Deletion IS NOT permitted.
							NEXT FIELD scroll_flag 
						END IF 

						IF NOT glob_rec_sales_order_parameter.pick_ind AND l_rec_orderdetl_curr_row.picked_qty > 0 THEN 
							IF NOT check_pick_edit() THEN 
								NEXT FIELD scroll_flag 
							END IF 
						END IF 
						
						IF stock_line(l_arr_rec_orderdetl[l_idx].line_num,TRAN_TYPE_INVOICE_IN,0) THEN 
							CALL serial_delete(l_arr_rec_orderdetl[l_idx].part_code,	glob_rec_orderhead.ware_code) 
							DELETE FROM t_orderdetl #delete row from temp table
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num
							CALL l_arr_rec_orderdetl.delete(l_idx)
							 
							{ 
							### shuffle array
--							LET j = scrn 
							FOR i = l_idx TO arr_count() 
									LET l_arr_rec_orderdetl[i].* = l_arr_rec_orderdetl[i+1].* 
								IF l_arr_rec_orderdetl[i].line_num = 0 THEN 
									INITIALIZE l_arr_rec_orderdetl[i].* TO NULL 
								END IF 
								IF j <= 8 THEN 
									DISPLAY l_arr_rec_orderdetl[i].* TO sr_orderdetl[j].* 

									LET j = j + 1 
								END IF 
							END FOR 
							}
							SELECT * INTO l_rec_orderdetl_curr_row.* FROM t_orderdetl #strange approach
							WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 
							IF status = NOTFOUND THEN 
								INITIALIZE l_rec_orderdetl_curr_row.* TO NULL 
							END IF
							 
							CALL disp_total(l_rec_orderdetl_curr_row.*)
							 
							NEXT FIELD line_num --scroll_flag 
						ELSE 
							NEXT FIELD line_num --scroll_flag 
						END IF 
					END IF
				
					CALL l_arr_rec_orderdetl.clear()
 					CALL db_t_orderdetl_get_datasource() RETURNING l_arr_rec_orderdetl
				
				END IF
				
								
				

			AFTER INPUT 
				IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderdetl.getSize()) THEN 
					IF int_flag OR quit_flag THEN 
--						IF NOT infield(scroll_flag) THEN 
--							LET int_flag = FALSE 
--							LET quit_flag = FALSE 
							
							IF l_rec_s_orderdetl.line_num IS NULL THEN 
	
								DELETE FROM t_orderdetl #delete row from temp table
								WHERE line_num = l_arr_rec_orderdetl[l_idx].line_num 
								CALL l_arr_rec_orderdetl.delete(l_idx) #@huho added .. check it 
								--NEXT FIELD scroll_flag 
							ELSE 
								CALL db_t_orderdetl_update_line(l_rec_s_orderdetl.*) 
								LET l_arr_rec_orderdetl[l_idx].offer_code = l_rec_s_orderdetl.offer_code 
								LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_s_orderdetl.part_code 
								LET l_arr_rec_orderdetl[l_idx].sold_qty = l_rec_s_orderdetl.sold_qty 
								LET l_arr_rec_orderdetl[l_idx].bonus_qty = l_rec_s_orderdetl.bonus_qty 
								LET l_arr_rec_orderdetl[l_idx].disc_per = l_rec_s_orderdetl.disc_per 
								LET l_arr_rec_orderdetl[l_idx].unit_price_amt =	l_rec_s_orderdetl.unit_price_amt 
								LET l_arr_rec_orderdetl[l_idx].line_tot_amt = l_rec_s_orderdetl.line_tot_amt 
							END IF
							 
							CALL disp_total(l_rec_s_orderdetl.*) 
--							NEXT FIELD autoinsert_flag #@huho ??? haven't got this field in E114
--						ELSE 
							IF kandoomsg("E",8045,"") = "Y" THEN  #8045 Abort Order line changes?
								LET l_int_flag = TRUE 
	
								WHILE TRUE 
									LET l_upd_flag = 1
									 
									BEGIN WORK
									 
										FOR i = 1 TO l_arr_rec_orderdetl.getSize() #write/update each order line to DB
											#CALL stock_line() #? was commented 
											LET l_upd_flag = stock_line(l_arr_rec_orderdetl[i].line_num,TRAN_TYPE_INVOICE_IN,1) 
											
											IF l_upd_flag = -1 THEN 
												CONTINUE WHILE 
											ELSE 
												IF l_upd_flag = 0 THEN 
													LET int_flag = FALSE 
													LET quit_flag = FALSE 
													LET l_int_flag = FALSE 
													NEXT FIELD line_num --scroll_flag 
												END IF 
											END IF 
										END FOR
										#CALL stock_line() #? was commented
										LET l_upd_flag = stock_line(glob_rec_orderhead.order_num,TRAN_TYPE_ORDER_ORD,1) 
										
										IF l_upd_flag = -1 THEN 
											CONTINUE WHILE 
										ELSE 
											IF l_upd_flag = 0 THEN 
												LET int_flag = FALSE 
												LET quit_flag = FALSE 
												LET l_int_flag = FALSE 
												NEXT FIELD line_num --scroll_flag 
											END IF 
										END IF 
	
									COMMIT WORK 
	
									LET glob_rec_sales_order_parameter.pick_ind = FALSE 
									EXIT WHILE 
								END WHILE 
	
							ELSE 
								LET int_flag = FALSE 
								LET quit_flag = FALSE 
								NEXT FIELD line_num --scroll_flag 
							END IF 
						--END IF 
					ELSE 
	
						FOR i = 1 TO l_arr_rec_orderdetl.getSize() 
							SELECT unique 1 FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = l_arr_rec_orderdetl[i].part_code 
							AND serial_flag = 'Y' 
							
							IF status <> NOTFOUND THEN 
								LET l_cnt = serial_count(l_arr_rec_orderdetl[i].part_code, glob_rec_orderhead.ware_code) 
								IF l_cnt <> l_arr_rec_orderdetl[i].sold_qty THEN 
									SELECT unique 1 FROM t_orderdetl 
									WHERE line_num = l_arr_rec_orderdetl[i].line_num 
									AND status_ind <> 0 
									AND status_ind <> 2 
									IF status <> NOTFOUND THEN 
										ERROR kandoomsg2("I",9294,"") 		#9242 Number of Serial Codes entered needs TO
										NEXT FIELD line_num --scroll_flag 
									ELSE 
										IF l_cnt > l_arr_rec_orderdetl[i].sold_qty THEN 
											ERROR kandoomsg2("I",9295, l_arr_rec_orderdetl[i].part_code) #9295 Number of Serial Codes cannot be >
											NEXT FIELD line_num --scroll_flag 
										END IF 
									END IF 
								END IF 
							END IF 
						END FOR 
	
						IF glob_rec_orderhead.cond_code IS NULL THEN 
							SELECT unique 1 FROM t_orderdetl 
							WHERE offer_code IS NULL 
							AND bonus_qty != 0 
							IF sqlca.sqlcode = 0 THEN 
								ERROR kandoomsg2("E",7030,"") #7030 Items NOT part of an condition NOT have bonus
								NEXT FIELD line_num --scroll_flag 
							END IF 
						END IF 
						DELETE FROM t_orderdetl  #delete row from temp table
						WHERE part_code IS NULL 
						AND desc_text IS NULL 
						AND acct_code IS NULL 
					END IF 
				END IF #l_idx > 0 AND 

		END INPUT 
		#---------- END INPUT -------------------------------------------------------------------------------------------

--		DISPLAY fgl_lastaction()
		IF downshift(fgl_lastaction()) = downshift("AUTO DISC CALC") THEN #F10 = preview discount calculation `?
		--IF fgl_lastkey() = fgl_keyval("F10") THEN 
			IF check_offer() THEN 
			END IF 
		ELSE 
			IF NOT l_reset_offer THEN 
				EXIT WHILE 
			END IF 
		END IF 
		
	END WHILE	#--------- END WHILE ----------------------------------------------------------------------------------------
 
	IF int_flag OR quit_flag OR l_int_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION lineitem_scan()  
############################################################


###########################################################################
# FUNCTION db_t_orderdetl_line_num_exists(p_line_num)
#
# 
###########################################################################
FUNCTION db_t_orderdetl_line_num_exists(p_line_num)
	DEFINE p_line_num SMALLINT
	DEFINE l_ret_count SMALLINT
	
	SELECT count(*) INTO l_ret_count
	FROM t_orderdetl 
	WHERE line_num = p_line_num
	
	RETURN l_ret_count
END FUNCTION
###########################################################################
# END FUNCTION db_t_orderdetl_line_num_exists(p_line_num)
###########################################################################


###########################################################################
# FUNCTION db_t_orderdetl_delete_row(p_line_num)
#
# 
###########################################################################
FUNCTION db_t_orderdetl_delete_row(p_line_num)
	DEFINE p_line_num SMALLINT
	
	DELETE FROM t_orderdetl 
	WHERE line_num = p_line_num
	
	RETURN status
END FUNCTION
###########################################################################
# END FUNCTION db_t_orderdetl_delete_row(p_line_num)
###########################################################################


###########################################################################
# FUNCTION db_t_orderdetl_get_rec(p_line_num)
#
# 
###########################################################################
FUNCTION db_t_orderdetl_get_rec(p_line_num)
	DEFINE p_line_num SMALLINT
	DEFINE l_ret_rec_orderdetl RECORD LIKE orderdetl.*
	
	SELECT * INTO l_ret_rec_orderdetl.* 
	FROM t_orderdetl 
	WHERE line_num = p_line_num

	RETURN l_ret_rec_orderdetl.*
END FUNCTION
###########################################################################
# END FUNCTION db_t_orderdetl_get_rec(p_line_num)
###########################################################################


###########################################################################
# FUNCTION db_t_orderdetl_insert_line(p_idx)
#
#
###########################################################################
FUNCTION db_t_orderdetl_insert_line(p_idx)
	DEFINE p_idx SMALLINT 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 

	LET l_rec_orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_orderdetl.cust_code = glob_rec_orderhead.cust_code 
	LET l_rec_orderdetl.order_num = glob_rec_orderhead.order_num #when is this not null. when is it populated
	LET l_rec_orderdetl.ware_code = glob_rec_orderhead.ware_code
	 
	SELECT max(line_num) 
	INTO glob_rec_orderhead.line_num 
	FROM t_orderdetl
	 
	IF glob_rec_orderhead.line_num IS NULL OR glob_rec_orderhead.line_num = 0 THEN 
		LET l_rec_orderdetl.line_num = 1 #start with first line number 1
	ELSE
		IF p_idx IS NOT NULL AND p_idx != 0 THEN 
			IF glob_rec_orderhead.line_num < p_idx THEN
				LET l_rec_orderdetl.line_num = glob_rec_orderhead.line_num + 1  #increment line number
			ELSE
				LET l_rec_orderdetl.line_num = p_idx #this is all a bit dirty
			END IF
		END IF
	END IF 
	
	LET l_rec_orderdetl.tax_code = glob_rec_orderhead.tax_code 
	IF glob_rec_orderhead.cond_code IS NOT NULL THEN 
		LET l_rec_orderdetl.level_ind = "L" 
		LET l_rec_orderdetl.serial_qty = TRUE ## SERIAL used as auto calc disc 
	ELSE 
		LET l_rec_orderdetl.level_ind = glob_rec_customer.inv_level_ind 
		LET l_rec_orderdetl.serial_qty = FALSE ## SERIAL used as auto calc disc 
	END IF
	 
	IF glob_rec_sales_order_parameter.suppl_flag IS NULL OR glob_rec_sales_order_parameter.suppl_flag = "N" THEN 
		LET l_rec_orderdetl.status_ind = "0" 
		LET l_rec_orderdetl.ware_code = glob_rec_orderhead.ware_code 
		LET l_rec_orderdetl.cost_ind = permit_backordering(l_rec_orderdetl.ware_code, l_rec_orderdetl.part_code) 
		# cost_ind used as back_ord_flag (see notes)
	ELSE 
		LET l_rec_orderdetl.ware_code = glob_rec_sales_order_parameter.supp_ware_code 
		LET l_rec_orderdetl.status_ind = "1" 
		LET l_rec_orderdetl.cost_ind = "N" 
		# cost_ind used as back_ord_flag (see notes)
	END IF 
	
	LET l_rec_orderdetl.job_code = FALSE ## job code used as disc taken ind 
	LET l_rec_orderdetl.sold_qty = 0 
	LET l_rec_orderdetl.bonus_qty = 0 
	LET l_rec_orderdetl.required_qty = 0 
	LET l_rec_orderdetl.order_qty = 0 
	LET l_rec_orderdetl.sched_qty = 0 
	LET l_rec_orderdetl.inv_qty = 0 
	LET l_rec_orderdetl.back_qty = 0 
	LET l_rec_orderdetl.picked_qty = 0 
	LET l_rec_orderdetl.conf_qty = 0 
	LET l_rec_orderdetl.disc_per = 0 
	LET l_rec_orderdetl.disc_amt = 0 
	LET l_rec_orderdetl.bonus_disc_amt = 0 
	LET l_rec_orderdetl.unit_price_amt = 0 
	LET l_rec_orderdetl.ext_price_amt = 0 
	LET l_rec_orderdetl.unit_tax_amt = 0 
	LET l_rec_orderdetl.ext_tax_amt = 0 
	LET l_rec_orderdetl.unit_cost_amt = 0 
	LET l_rec_orderdetl.ext_cost_amt = 0 
	LET l_rec_orderdetl.line_tot_amt = 0 
	LET l_rec_orderdetl.serial_flag = "N" 
	LET l_rec_orderdetl.autoinsert_flag = "N" 
	LET l_rec_orderdetl.pick_flag = "Y" 
	LET l_rec_orderdetl.trade_in_flag = "N" 
	LET l_rec_orderdetl.disc_allow_flag = "" 
	LET l_rec_orderdetl.list_price_amt = 0 

	INSERT INTO t_orderdetl VALUES (l_rec_orderdetl.*) 
	RETURN l_rec_orderdetl.* 
END FUNCTION 
############################################################
# END FUNCTION db_t_orderdetl_insert_line(p_idx)
############################################################


###########################################################################
# FUNCTION db_t_orderdetl_update_line(p_rec_orderdetl)
#
# N.B. db_t_orderdetl_update_line() IS called with NULL unit_price_amt
#      WHEN recalculation based on list price OR disc_per
#      IS required
# N.B. check FOR NULL prices FOR non-inventory lines, as comment-only lines
#      can bypass all other price setting/checking code
###########################################################################
FUNCTION db_t_orderdetl_update_line(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_disc_per FLOAT 
	DEFINE l_taxable_amt LIKE orderhead.tax_amt 
	DEFINE l_round_err decimal(16,2)
	DEFINE l_tax_amt decimal(16,2)
	DEFINE l_tax_amt2 decimal(16,2)
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_tax2 RECORD LIKE tax.* 

	IF p_rec_orderdetl.part_code IS NULL THEN 
		LET p_rec_orderdetl.status_ind = "3" 
		LET p_rec_orderdetl.trade_in_flag = "N" 
		LET p_rec_orderdetl.disc_allow_flag = "" 
		LET p_rec_orderdetl.serial_flag = "N" 
		LET p_rec_orderdetl.pick_flag = "N" 
		LET p_rec_orderdetl.disc_per = 0 
		
		IF p_rec_orderdetl.unit_price_amt IS NULL THEN 
			LET p_rec_orderdetl.unit_price_amt = 0 
		END IF 
		
		LET p_rec_orderdetl.list_price_amt = p_rec_orderdetl.unit_price_amt 
		LET p_rec_orderdetl.cost_ind = "N" # FIELD used as back_ord_flag(see notes) 
	ELSE 
		
		SELECT * INTO l_rec_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = p_rec_orderdetl.part_code 
		
		LET p_rec_orderdetl.cat_code = l_rec_product.cat_code 
		LET p_rec_orderdetl.uom_code = l_rec_product.sell_uom_code 
		LET p_rec_orderdetl.serial_flag = l_rec_product.serial_flag 
		LET p_rec_orderdetl.prodgrp_code = l_rec_product.prodgrp_code 
		LET p_rec_orderdetl.maingrp_code = l_rec_product.maingrp_code 
		LET p_rec_orderdetl.trade_in_flag = l_rec_product.trade_in_flag 

		IF p_rec_orderdetl.disc_allow_flag IS NULL THEN 
			LET p_rec_orderdetl.disc_allow_flag = l_rec_product.disc_allow_flag 
		END IF
		 
		IF p_rec_orderdetl.offer_code IS NOT NULL THEN 
			LET p_rec_orderdetl.serial_qty = TRUE ## auto disc.calc reqd 
		END IF 
		
		IF p_rec_orderdetl.desc_text IS NULL THEN 
			LET p_rec_orderdetl.desc_text = l_rec_product.desc_text 
		END IF
		 
		SELECT sale_acct_code INTO p_rec_orderdetl.acct_code 
		FROM category 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cat_code = p_rec_orderdetl.cat_code 
		
		SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_orderdetl.ware_code 
		AND part_code = p_rec_orderdetl.part_code 
		
		IF l_rec_prodstatus.stocked_flag = "Y" OR l_rec_prodstatus.nonstk_pick_flag = "Y" THEN 
			LET p_rec_orderdetl.pick_flag = "Y" 
		ELSE 
			LET p_rec_orderdetl.pick_flag = "N" 
		END IF 
		
		LET p_rec_orderdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt * glob_rec_orderhead.conv_qty 
		
		IF p_rec_orderdetl.inv_qty = 0 THEN 
			LET p_rec_orderdetl.list_price_amt = l_rec_prodstatus.list_amt 
			IF p_rec_orderdetl.list_price_amt = 0 THEN 
				IF p_rec_orderdetl.unit_price_amt IS NOT NULL THEN 
					LET p_rec_orderdetl.list_price_amt = p_rec_orderdetl.unit_price_amt 
					LET p_rec_orderdetl.disc_per = 0 
				END IF 
			END IF 

			IF p_rec_orderdetl.unit_price_amt IS NULL THEN 
				## calc price based on disc
				LET p_rec_orderdetl.unit_price_amt = p_rec_orderdetl.list_price_amt	- (p_rec_orderdetl.list_price_amt * (p_rec_orderdetl.disc_per/100)) 
			END IF 

			IF p_rec_orderdetl.disc_per IS NULL THEN 
				## calc disc based on price
				LET l_disc_per = 100 * (p_rec_orderdetl.list_price_amt - p_rec_orderdetl.unit_price_amt) / (p_rec_orderdetl.list_price_amt) 
				IF l_disc_per < 0 THEN 
					LET p_rec_orderdetl.disc_per = 0 
				ELSE 
					LET p_rec_orderdetl.disc_per = l_disc_per 
				END IF 
			END IF 

			LET p_rec_orderdetl.tax_code = l_rec_prodstatus.sale_tax_code 

			IF p_rec_orderdetl.status_ind = "1" THEN 
				LET p_rec_orderdetl.cost_ind = "N" 
			ELSE 
				LET p_rec_orderdetl.cost_ind = permit_backordering(p_rec_orderdetl.ware_code,	p_rec_orderdetl.part_code) 
			END IF 

			IF p_rec_orderdetl.serial_qty THEN ### auto discount calc reqd 
				LET p_rec_orderdetl.job_code = FALSE ## jobcode IS discount_taken_ind 
			ELSE 
				LET p_rec_orderdetl.job_code = TRUE ## jobcode IS discount_taken_ind 
			END IF 

		ELSE 

			LET p_rec_orderdetl.job_code = TRUE 
			## jobcode IS discount_taken_ind. serialqty IS auto calc reqd
		END IF 

		IF p_rec_orderdetl.autoinsert_flag = "Y" THEN 
			LET p_rec_orderdetl.job_code = TRUE ## jobcode IS discount_taken_ind 
		END IF 

		IF p_rec_orderdetl.trade_in_flag = "Y" THEN 
			LET p_rec_orderdetl.disc_allow_flag = glob_no_flag 
			LET p_rec_orderdetl.pick_flag = "N" 
			LET p_rec_orderdetl.serial_qty = FALSE 
			LET p_rec_orderdetl.serial_flag = "N" 
			LET p_rec_orderdetl.list_price_amt = p_rec_orderdetl.unit_price_amt 
			LET p_rec_orderdetl.job_code = TRUE ## jobcode IS discount_taken_ind 
			LET p_rec_orderdetl.cost_ind = "N" ## cost_ind used as back_ord_flag 
		END IF 

		LET p_rec_orderdetl.required_qty = calc_avail(p_rec_orderdetl.*,FALSE) 
	END IF 
	
	CALL calc_line_tax(
		glob_rec_kandoouser.cmpy_code,
		glob_rec_orderhead.tax_code, 
		p_rec_orderdetl.tax_code, 
		l_rec_prodstatus.sale_tax_amt, 
		p_rec_orderdetl.sold_qty, 
		p_rec_orderdetl.unit_cost_amt, 
		p_rec_orderdetl.unit_price_amt) 
	RETURNING 
		p_rec_orderdetl.unit_tax_amt,	
		p_rec_orderdetl.ext_tax_amt 

	LET p_rec_orderdetl.ext_price_amt = p_rec_orderdetl.unit_price_amt * p_rec_orderdetl.sold_qty 
	LET p_rec_orderdetl.ext_tax_amt = p_rec_orderdetl.unit_tax_amt * p_rec_orderdetl.sold_qty 
	LET l_round_err = 0 
	
	INITIALIZE l_rec_tax.* TO NULL
	 
	LET l_taxable_amt = 0 
	LET l_tax_amt = 0 
	LET l_tax_amt2 = 0
	 
	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_orderhead.tax_code 

	IF l_rec_tax.calc_method_flag = "T" THEN 
		INITIALIZE l_rec_tax2.* TO NULL 
		SELECT * INTO l_rec_tax2.* FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_orderdetl.tax_code 

		IF l_rec_tax2.calc_method_flag != "X" THEN 
			SELECT sum(ext_price_amt) INTO l_taxable_amt 
			FROM t_orderdetl,tax 
			WHERE line_num != p_rec_orderdetl.line_num 
			AND t_orderdetl.tax_code = tax.tax_code 
			AND calc_method_flag != "X" 
			AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET l_taxable_amt = l_taxable_amt	+ p_rec_orderdetl.ext_price_amt 
			CALL calc_total_tax(glob_rec_kandoouser.cmpy_code, "T",	l_taxable_amt,l_rec_tax.tax_code)	RETURNING l_tax_amt 

			SELECT sum(ext_tax_amt) INTO l_tax_amt2 FROM t_orderdetl 
			WHERE line_num != p_rec_orderdetl.line_num 
			LET l_tax_amt2 = l_tax_amt2 + p_rec_orderdetl.ext_tax_amt 

			IF l_tax_amt != l_tax_amt2 THEN 
				LET l_round_err = l_tax_amt2 - l_tax_amt 
			END IF 

			IF l_round_err != 0 THEN 
				LET p_rec_orderdetl.ext_tax_amt = p_rec_orderdetl.ext_tax_amt 	- l_round_err 
			END IF 

		END IF 
	END IF 

	IF p_rec_orderdetl.ext_tax_amt IS NULL THEN 
		LET p_rec_orderdetl.ext_tax_amt = 0 
	END IF 

	UPDATE t_orderdetl SET 
		line_num = p_rec_orderdetl.line_num, 
		offer_code = p_rec_orderdetl.offer_code, 
		part_code = p_rec_orderdetl.part_code, 
		ware_code = p_rec_orderdetl.ware_code, 
		cat_code = p_rec_orderdetl.cat_code, 
		order_qty = p_rec_orderdetl.sold_qty + p_rec_orderdetl.bonus_qty, 
		prodgrp_code = p_rec_orderdetl.prodgrp_code, 
		maingrp_code = p_rec_orderdetl.maingrp_code, 
		acct_code = p_rec_orderdetl.acct_code, 
		uom_code = p_rec_orderdetl.uom_code, 
		sold_qty = p_rec_orderdetl.sold_qty, 
		bonus_qty = p_rec_orderdetl.bonus_qty, 
		required_qty = p_rec_orderdetl.required_qty, 
		sched_qty = p_rec_orderdetl.sched_qty, 
		back_qty = p_rec_orderdetl.back_qty, 
		picked_qty = p_rec_orderdetl.picked_qty, 
		conf_qty = p_rec_orderdetl.conf_qty, 
		tax_code = p_rec_orderdetl.tax_code, 
		unit_tax_amt = p_rec_orderdetl.unit_tax_amt, 
		ext_tax_amt = p_rec_orderdetl.ext_tax_amt, 
		unit_price_amt = p_rec_orderdetl.unit_price_amt, 
		unit_cost_amt = p_rec_orderdetl.unit_cost_amt, 
		ext_cost_amt = p_rec_orderdetl.unit_cost_amt * p_rec_orderdetl.order_qty, 
		ext_price_amt = p_rec_orderdetl.ext_price_amt, 
		ext_bonus_amt = p_rec_orderdetl.list_price_amt * p_rec_orderdetl.bonus_qty, 
		ext_stats_amt = 0, 
		line_tot_amt = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.unit_tax_amt	+ p_rec_orderdetl.unit_price_amt), 
		disc_per = p_rec_orderdetl.disc_per, 
		disc_amt = p_rec_orderdetl.sold_qty * (p_rec_orderdetl.list_price_amt - p_rec_orderdetl.unit_price_amt), 
		job_code = p_rec_orderdetl.job_code, 
		desc_text = p_rec_orderdetl.desc_text, 
		level_ind = p_rec_orderdetl.level_ind, 
		cost_ind = p_rec_orderdetl.cost_ind, 
		autoinsert_flag = p_rec_orderdetl.autoinsert_flag, 
		status_ind = p_rec_orderdetl.status_ind, 
		serial_flag = p_rec_orderdetl.serial_flag, 
		serial_qty = p_rec_orderdetl.serial_qty, 
		pick_flag = p_rec_orderdetl.pick_flag, 
		trade_in_flag = p_rec_orderdetl.trade_in_flag, 
		disc_allow_flag = p_rec_orderdetl.disc_allow_flag, 
		list_price_amt = p_rec_orderdetl.list_price_amt 
	WHERE 
		line_num = p_rec_orderdetl.line_num 

END FUNCTION 
############################################################
# END FUNCTION db_t_orderdetl_update_line(p_rec_orderdetl)  
############################################################
###########################################################################
# FUNCTION morph_orderdetl_arr_row_to_rec(p_rec_orderdetl_arr_row,p_rec_orderdetl) 
#
#
###########################################################################
FUNCTION morph_orderdetl_arr_row_to_rec(p_rec_orderdetl_arr_row,p_rec_orderdetl)
	DEFINE p_rec_orderdetl_arr_row RECORD
		line_num LIKE orderdetl.line_num, 
		offer_code LIKE orderdetl.offer_code, 
		part_code LIKE orderdetl.part_code, 
		sold_qty LIKE orderdetl.sold_qty, 
		bonus_qty LIKE orderdetl.bonus_qty, 
		disc_per LIKE orderdetl.disc_per, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		line_tot_amt LIKE orderdetl.line_tot_amt, 
		autoinsert_flag LIKE orderdetl.autoinsert_flag
	END RECORD
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.*
	
	LET p_rec_orderdetl.line_num = p_rec_orderdetl_arr_row.line_num
	LET p_rec_orderdetl.offer_code = p_rec_orderdetl_arr_row.offer_code
	LET p_rec_orderdetl.part_code = p_rec_orderdetl_arr_row.part_code
	LET p_rec_orderdetl.sold_qty = p_rec_orderdetl_arr_row.sold_qty
	LET p_rec_orderdetl.bonus_qty = p_rec_orderdetl_arr_row.bonus_qty
	LET p_rec_orderdetl.disc_per = p_rec_orderdetl_arr_row.disc_per
	LET p_rec_orderdetl.unit_price_amt = p_rec_orderdetl_arr_row.unit_price_amt
	LET p_rec_orderdetl.line_tot_amt = p_rec_orderdetl_arr_row.line_tot_amt
	LET p_rec_orderdetl.autoinsert_flag = p_rec_orderdetl_arr_row.autoinsert_flag
	
	RETURN p_rec_orderdetl.*	
END FUNCTION
###########################################################################
# END FUNCTION morph_orderdetl_arr_row_to_rec(p_rec_orderdetl_arr_row,p_rec_orderdetl) 
###########################################################################

###########################################################################
# FUNCTION morph_orderdetl_rec_to_arr_row(p_rec_orderdetl,p_rec_orderdetl_arr_row) 
#
#
###########################################################################
FUNCTION morph_orderdetl_rec_to_arr_row(p_rec_orderdetl,p_rec_orderdetl_arr_row)
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.*
	DEFINE p_rec_orderdetl_arr_row RECORD
		line_num LIKE orderdetl.line_num, 
		offer_code LIKE orderdetl.offer_code, 
		part_code LIKE orderdetl.part_code, 
		sold_qty LIKE orderdetl.sold_qty, 
		bonus_qty LIKE orderdetl.bonus_qty, 
		disc_per LIKE orderdetl.disc_per, 
		unit_price_amt LIKE orderdetl.unit_price_amt, 
		line_tot_amt LIKE orderdetl.line_tot_amt, 
		autoinsert_flag LIKE orderdetl.autoinsert_flag
	END RECORD

	
	LET p_rec_orderdetl_arr_row.line_num = p_rec_orderdetl.line_num
	LET p_rec_orderdetl_arr_row.offer_code = p_rec_orderdetl.offer_code
	LET p_rec_orderdetl_arr_row.part_code = p_rec_orderdetl.part_code
	LET p_rec_orderdetl_arr_row.sold_qty = p_rec_orderdetl.sold_qty
	LET p_rec_orderdetl_arr_row.bonus_qty = p_rec_orderdetl.bonus_qty
	LET p_rec_orderdetl_arr_row.disc_per = p_rec_orderdetl.disc_per
	LET p_rec_orderdetl_arr_row.unit_price_amt = p_rec_orderdetl.unit_price_amt
	LET p_rec_orderdetl_arr_row.line_tot_amt = p_rec_orderdetl.line_tot_amt
	LET p_rec_orderdetl_arr_row.autoinsert_flag = p_rec_orderdetl.autoinsert_flag
	
	RETURN p_rec_orderdetl_arr_row.*	
END FUNCTION
###########################################################################
# END FUNCTION morph_orderdetl_rec_to_arr_row(p_rec_orderdetl,p_rec_orderdetl_arr_row) 
###########################################################################


###########################################################################
# FUNCTION permit_backordering(l_ware_code,l_part_code)
#
# returns "Y" OR "N" depending on whether the cust, warehouse, product combo permits backordering
###########################################################################
FUNCTION permit_backordering(l_ware_code,l_part_code) 
	# FUNCTION returns "Y" OR "N" depending on whether the
	# cust, warehouse, product combo permits backordering
	DEFINE l_ware_code LIKE orderdetl.ware_code 
	DEFINE l_part_code LIKE orderdetl.part_code 

	IF glob_rec_customer.back_order_flag = "N" AND NOT get_kandoooption_feature_state("EO","BA") THEN 
		RETURN "N" 
	END IF 
	
	IF l_ware_code IS NOT NULL THEN 
		SELECT unique 1 FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_ware_code 
		AND back_order_ind = "0" 
		IF sqlca.sqlcode = 0 THEN 
			RETURN "N" 
		END IF 
	END IF
	 
	IF l_part_code IS NOT NULL THEN 
		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_part_code 
		AND back_order_flag = "N" 
		IF sqlca.sqlcode = 0 THEN 
			RETURN "N" 
		END IF 
	END IF
	 
	RETURN "Y" 
END FUNCTION 
############################################################
# FUNCTION permit_backordering(l_ware_code,l_part_code)  
############################################################


###########################################################################
# FUNCTION disp_total(p_rec_orderdetl) 
#
#
###########################################################################
FUNCTION disp_total(p_rec_orderdetl) 
	DEFINE p_rec_orderdetl RECORD LIKE orderdetl.*
 	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_desc_text char(30) 

	### DISPLAY Current Line Info
	IF glob_rec_arparms.show_tax_flag = "N" THEN 
		LET p_rec_orderdetl.line_tot_amt = p_rec_orderdetl.ext_price_amt 
	END IF 
	IF p_rec_orderdetl.autoinsert_flag = "Y" THEN 
		LET p_rec_orderdetl.autoinsert_flag = "*" 
	ELSE 
		LET p_rec_orderdetl.autoinsert_flag = "" 
	END IF 
{
	DISPLAY "",p_rec_orderdetl.line_num, 
	p_rec_orderdetl.offer_code, 
	p_rec_orderdetl.part_code, 
	p_rec_orderdetl.sold_qty, 
	p_rec_orderdetl.bonus_qty, 
	p_rec_orderdetl.disc_per, 
	p_rec_orderdetl.unit_price_amt, 
	p_rec_orderdetl.line_tot_amt, 
	p_rec_orderdetl.autoinsert_flag 
	TO sr_orderdetl[scrn].* 
}
	### DISPLAY Totals & Line Info
	SELECT sum(ext_price_amt), 
	sum(ext_tax_amt) 
	INTO glob_rec_orderhead.goods_amt, glob_rec_orderhead.tax_amt 
	FROM t_orderdetl 

	LET glob_rec_orderhead.total_amt = glob_rec_orderhead.goods_amt + glob_rec_orderhead.tax_amt 
	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt 
	- glob_rec_customer.bal_amt 
	- glob_rec_customer.onorder_amt 
	- glob_rec_orderhead.total_amt 
	+ glob_currord_amt 
	
	DISPLAY BY NAME 
		glob_rec_customer.cred_bal_amt, 
		glob_rec_orderhead.goods_amt, 
		glob_rec_orderhead.tax_amt, 
		glob_rec_orderhead.total_amt attribute(yellow) 
	
	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_rec_orderdetl.part_code 
	AND ware_code = p_rec_orderdetl.ware_code 
	IF status = NOTFOUND THEN 
		LET l_rec_orderdetl.required_qty = 0 
	ELSE 
		IF l_rec_prodstatus.stocked_flag = "Y" THEN 
			IF glob_rec_opparms.cal_available_flag = "N" THEN 
				LET l_rec_orderdetl.required_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.back_qty 
			ELSE 
				LET l_rec_orderdetl.required_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty 
			END IF 
		END IF 
	END IF 

	DISPLAY BY NAME l_rec_orderdetl.required_qty	attribute(yellow) 

	DISPLAY BY NAME 
		p_rec_orderdetl.desc_text, 
		p_rec_orderdetl.tax_code, 
		p_rec_orderdetl.ware_code, 
		p_rec_orderdetl.status_ind, 
		p_rec_orderdetl.disc_allow_flag, 
		p_rec_orderdetl.level_ind 

	IF p_rec_orderdetl.offer_code IS NULL THEN 
		CLEAR offersale.desc_text 
	ELSE 
		SELECT desc_text INTO l_desc_text FROM offersale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND offer_code = p_rec_orderdetl.offer_code 
		DISPLAY l_desc_text TO offersale.desc_text 

	END IF 

	WHENEVER ERROR CONTINUE 

	IF p_rec_orderdetl.tax_code IS NULL THEN 
		CLEAR tax.desc_text 
	ELSE 
		SELECT desc_text INTO l_desc_text FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = p_rec_orderdetl.tax_code 

		DISPLAY l_desc_text TO tax.desc_text 
	END IF 

	WHENEVER ERROR stop 

END FUNCTION 
############################################################
# END FUNCTION disp_total(p_rec_orderdetl)  
############################################################


###########################################################################
# FUNCTION check_alternate(p_part_code,p_alt_part_code) 
#
#
###########################################################################
FUNCTION check_alternate(p_part_code,p_alt_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_alt_part_code LIKE product.alter_part_code 
	DEFINE l_rec_product RECORD LIKE product.* 

	IF p_alt_part_code IS NULL THEN 
		RETURN FALSE 
	END IF 
	SELECT x.* INTO l_rec_product.* FROM product x, prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = p_alt_part_code 
	AND x.part_code = y.part_code 
	AND x.part_code != p_part_code 
	AND y.ware_code = glob_rec_orderhead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = NOTFOUND THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.alter_part_code = p_alt_part_code 
		AND x.part_code <> p_part_code 
		AND x.part_code = y.part_code 
		AND y.ware_code = glob_rec_orderhead.ware_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
		IF status = NOTFOUND THEN 
			RETURN FALSE 
		END IF 
	END IF 
	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION check_alternate(p_part_code,p_alt_part_code)  
############################################################


###########################################################################
# FUNCTION display_alternates(p_part_code,p_alt_part_code) 
#
# DISPLAY Alternative Products
###########################################################################
FUNCTION display_alternates(p_part_code,p_alt_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_alt_part_code LIKE product.alter_part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
--		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		available LIKE prodstatus.onhand_qty 
	END RECORD 
	DEFINE l_available LIKE prodstatus.onhand_qty 
	DEFINE l_idx SMALLINT 

	LET l_idx = 0 
	SELECT x.* INTO l_rec_product.* 
	FROM product x, prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.part_code = p_alt_part_code 
	AND x.part_code = y.part_code 
	AND x.part_code != p_part_code 
	AND y.ware_code = glob_rec_orderhead.ware_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 
	IF status = NOTFOUND THEN 
		OPEN WINDOW N131 with FORM "N131" 
		 CALL windecoration_n("N131") -- albo kd-755
 
		DECLARE c_altprod cursor FOR 
		SELECT x.part_code, 
		x.desc_text, 
		(y.onhand_qty - y.reserved_qty - y.back_qty) 
		FROM product x, 
		prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND y.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.alter_part_code = p_alt_part_code 
		AND x.part_code <> p_part_code 
		AND x.part_code = y.part_code 
		AND y.ware_code = glob_rec_orderhead.ware_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty) > 0 

		FOREACH c_altprod INTO l_rec_product.part_code, 
			l_rec_product.desc_text, 
			l_available 
			LET l_idx = l_idx + 1 
--			LET l_arr_rec_product[l_idx].scroll_flag = NULL 
			LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
			LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
			LET l_arr_rec_product[l_idx].available = l_available 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx) #9113 XX records selected
--		IF l_idx = 0 THEN 
--			LET l_idx = 1 
--			INITIALIZE l_arr_rec_product[l_idx].* TO NULL 
--		END IF 
--		CALL set_count(l_idx) 

		MESSAGE kandoomsg2("U",1019,"") 	#U1019 Press OK TO...
		--INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* ATTRIBUTE (UNBUFFERED,insert row=FALSE, delete row = FALSE)

		DISPLAY ARRAY l_arr_rec_product TO sr_product.*
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","E11d","input-l_arr_rec_product-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
DISPLAY "BEFORE ROW"			
				IF arr_curr() = 0 THEN
				#DEBUG
					CALL fgl_winmessage("ERROR","BEFORE ROW - LET l_idx = arr_curr() = 0  !!!!","ERROR")
				END IF		
				LET l_rec_product.part_code =  l_arr_rec_product[arr_curr()].part_code

		END DISPLAY 

		CLOSE WINDOW N131 
	END IF 

	IF (int_flag OR quit_flag) THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN NULL 
	ELSE
		RETURN l_rec_product.part_code
	END IF 
END FUNCTION 
############################################################
# END FUNCTION display_alternates(p_part_code,p_alt_part_code)  
############################################################

###########################################################################
# FUNCTION compan_avail(p_part_code)
#
# Determine IF Companion Products are available
###########################################################################
FUNCTION compan_avail(p_part_code) 
	DEFINE p_part_code LIKE prodstatus.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	SELECT compn_part_code INTO l_rec_product.compn_part_code FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_part_code 

	IF l_rec_product.compn_part_code IS NULL THEN 
		RETURN FALSE 
	END IF 

	SELECT prodstatus.* INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = l_rec_product.compn_part_code 
	AND ware_code = glob_rec_orderhead.ware_code 
	AND (onhand_qty - reserved_qty - back_qty ) > 0 
	IF status = NOTFOUND THEN 
		SELECT unique x.cmpy_code FROM product x, prodstatus y 
		WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND x.cmpy_code = y.cmpy_code 
		AND y.ware_code = glob_rec_orderhead.ware_code 
		AND x.part_code = y.part_code 
		AND x.part_code != p_part_code 
		AND x.compn_part_code = l_rec_product.compn_part_code 
		AND (y.onhand_qty - y.reserved_qty - y.back_qty ) > 0 
		IF status = NOTFOUND THEN 
			RETURN FALSE 
		END IF 
	END IF 

	RETURN TRUE 
END FUNCTION 
############################################################
# END FUNCTION compan_avail(p_part_code)  
############################################################


###########################################################################
# FUNCTION show_compan(p_part_code)
#
# Show Companion Products
###########################################################################
FUNCTION show_compan(p_part_code) 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		available LIKE prodstatus.onhand_qty 
	END RECORD 
	DEFINE l_idx SMALLINT

	SELECT compn_part_code INTO l_rec_product.compn_part_code FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = p_part_code 

	OPEN WINDOW N132 with FORM "N132" 
	 CALL windecoration_n("N132") -- albo kd-755
 
	DECLARE c2_prodstatus cursor FOR 
	SELECT 
		x.part_code, 
		x.desc_text, 
		(y.onhand_qty - y.reserved_qty - y.back_qty) 
	FROM 
		product x, 
		prodstatus y 
	WHERE x.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND x.cmpy_code = y.cmpy_code 
	AND y.ware_code = glob_rec_orderhead.ware_code 
	AND x.part_code = y.part_code 
	AND x.part_code != p_part_code 
	AND x.compn_part_code = l_rec_product.compn_part_code 
	AND (y.onhand_qty - y.reserved_qty - y.back_qty ) > 0 
	LET l_idx = 1
	 
	FOREACH c2_prodstatus INTO l_arr_rec_product[l_idx].* 
		LET l_idx = l_idx + 1 
	END FOREACH 

	LET l_idx = l_idx -1 
 
	MESSAGE kandoomsg2("U",1019,"") #U1019 Press OK TO...
	INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS FROM sr_product.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","E11d","input-l_arr_rec_product-2") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
DISPLAY "BEFORE ROW"		
				IF arr_curr() = 0 THEN
				#DEBUG
					CALL fgl_winmessage("ERROR","BEFORE ROW - LET l_idx = arr_curr() = 0  !!!!","ERROR")
				END IF			
			LET l_idx = arr_curr() 
			IF arr_curr() > arr_count() THEN 
				MESSAGE kandoomsg2("U",9001,"") #U9001 No more rows in the direction you are going"
			END IF 

		#-----------------------------------------------------
		# FIELD part_code
		#-----------------------------------------------------
		# BEFORE FIELD -----------------
		BEFORE FIELD part_code 
			LET p_part_code = l_arr_rec_product[l_idx].part_code 

		# AFTER FIELD ------------------
		AFTER FIELD part_code 
			LET l_arr_rec_product[l_idx].part_code = p_part_code 

		#-----------------------------------------------------
		# FIELD desc_text
		#-----------------------------------------------------
		# BEFORE FIELD -----------------
		BEFORE FIELD desc_text 
			EXIT INPUT 

	END INPUT 
	# END INPUT --------------------------------------------

	CLOSE WINDOW N132 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_arr_rec_product[l_idx].part_code = " " 
	END IF 

	RETURN l_arr_rec_product[l_idx].part_code 
END FUNCTION 
############################################################
# END FUNCTION show_compan(p_part_code)  
############################################################


###########################################################################
# FUNCTION matrix_insert()
#
# 
###########################################################################
FUNCTION matrix_insert() 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_matrix RECORD 
		part_code LIKE product.part_code, 
		order_qty LIKE orderdetl.sold_qty, 
		minmax_qty LIKE orderdetl.sold_qty, 
		line_num LIKE orderdetl.line_num 
	END RECORD 
	DEFINE l_upd_flag SMALLINT 
	DEFINE l_idx SMALLINT 

	LABEL tryagain: 

	BEGIN WORK 
		LET l_upd_flag = 1 
		DECLARE c_matrix cursor with hold FOR 
		SELECT * FROM t_matrix 
		ORDER BY part_code 

		FOREACH c_matrix INTO l_rec_matrix.* 
			IF (l_rec_matrix.line_num IS NULL	OR l_rec_matrix.line_num = 0)	AND l_rec_matrix.order_qty > 0 THEN 

				CALL db_t_orderdetl_insert_line(NULL) RETURNING l_rec_orderdetl.* 

				LET l_rec_orderdetl.part_code = l_rec_matrix.part_code 
				LET l_rec_orderdetl.sold_qty = l_rec_matrix.order_qty 
				LET l_rec_orderdetl.status_ind = "0" 
				LET l_rec_orderdetl.ware_code = glob_rec_orderhead.ware_code 
				IF valid_part(
					glob_rec_kandoouser.cmpy_code,
					l_rec_orderdetl.part_code, 
					l_rec_orderdetl.ware_code, 
					0,2,0,"","","") = FALSE THEN 
					ROLLBACK WORK 
					ERROR kandoomsg2("E",7003,l_rec_orderdetl.part_code) #7003 Matrix product IS NOT stocked OR available AT warehouse"

					RETURN FALSE 
				END IF 

				LET l_rec_orderdetl.autoinsert_flag = "N" 

				CALL allocate_stock(l_rec_orderdetl.*,1)	RETURNING l_rec_orderdetl.* 

				IF l_rec_orderdetl.status_ind = "4" THEN 
					ROLLBACK WORK 
					ERROR kandoomsg2("E",7004,l_rec_orderdetl.part_code) #7004 " Insufficent stock of matrix product AT warehouse"
					RETURN FALSE 
				ELSE 
					LET l_rec_orderdetl.unit_price_amt = NULL 

					CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 

					LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,"OUT",1) 

					IF l_upd_flag < 1 THEN 
						EXIT FOREACH 
					END IF 
				END IF 

				CONTINUE FOREACH 
			END IF 

			SELECT * INTO l_rec_orderdetl.* FROM t_orderdetl 
			WHERE line_num = l_rec_matrix.line_num 
			IF l_rec_matrix.line_num IS NOT NULL 
			AND l_rec_matrix.line_num != 0 
			AND l_rec_matrix.order_qty = 0 
			AND l_rec_matrix.minmax_qty = 0 
			AND l_rec_matrix.order_qty != l_rec_orderdetl.sold_qty 
			AND l_rec_orderdetl.bonus_qty = 0 THEN 
				LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 

				IF l_upd_flag < 1 THEN 
					EXIT FOREACH 
				END IF 

				DELETE FROM t_orderdetl  #delete row from temp table
				WHERE part_code = l_rec_matrix.part_code 
				CONTINUE FOREACH 
			END IF 

			IF l_rec_matrix.line_num != 0 
			AND l_rec_matrix.line_num IS NOT NULL 
			AND l_rec_matrix.order_qty != l_rec_orderdetl.sold_qty THEN 
				LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,TRAN_TYPE_INVOICE_IN,1) 

				IF l_upd_flag < 1 THEN 
					EXIT FOREACH 
				END IF 

				LET l_rec_orderdetl.sold_qty = l_rec_matrix.order_qty 

				CALL allocate_stock(l_rec_orderdetl.*,1)	RETURNING l_rec_orderdetl.* 
				CALL db_t_orderdetl_update_line(l_rec_orderdetl.*) 

				SELECT * INTO l_rec_orderdetl.* FROM t_orderdetl 
				WHERE line_num = l_rec_matrix.line_num 

				LET l_upd_flag = stock_line(l_rec_orderdetl.line_num,"OUT",1) 
				IF l_upd_flag < 1 THEN 
					EXIT FOREACH 
				END IF 

				CONTINUE FOREACH 
			END IF 
		END FOREACH 

		IF l_upd_flag = -1 THEN 
			GOTO tryagain 
		ELSE 
			IF l_upd_flag = 0 THEN 
				RETURN FALSE 
			END IF 
		END IF 

	COMMIT WORK 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION matrix_insert()
############################################################


###########################################################################
# FUNCTION display_parent_quantities()
#
# 
###########################################################################
FUNCTION display_parent_quantities() 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_parent DYNAMIC ARRAY OF RECORD 
--		scroll_flag char(1), 
		parent_code char(15), 
		desc_text char(30), 
		order_qty FLOAT 
	END RECORD 
	DEFINE l_dummy char(15)
	DEFINE l_prev_parent char(15)
	DEFINE l_parent_code char(15)
	DEFINE l_idx SMALLINT 

	OPEN WINDOW E460 with FORM "E460" 
	 CALL windecoration_e("E460") -- albo kd-755
 
	DECLARE c8_orderdetl cursor FOR 
	SELECT * FROM t_orderdetl 
	WHERE part_code IS NOT NULL 
	ORDER BY part_code 

	LET l_idx = 0 
	LET l_prev_parent = NULL 

	FOREACH c8_orderdetl INTO l_rec_orderdetl.* 
		SELECT * INTO l_rec_product.* FROM product 
		WHERE part_code = l_rec_orderdetl.part_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		CALL break_prod(glob_rec_kandoouser.cmpy_code, l_rec_orderdetl.part_code,l_rec_product.class_code,0) 
		RETURNING l_parent_code, l_dummy, l_dummy, l_dummy 

		IF l_parent_code = l_prev_parent THEN 
			LET l_arr_rec_parent[l_idx].order_qty = l_arr_rec_parent[l_idx].order_qty + l_rec_orderdetl.order_qty 
		ELSE 
			LET l_idx = l_idx + 1 
			LET l_prev_parent = l_parent_code 
--			LET l_arr_rec_parent[l_idx].scroll_flag = NULL 
			LET l_arr_rec_parent[l_idx].parent_code = l_parent_code 
			LET l_arr_rec_parent[l_idx].order_qty = l_rec_orderdetl.order_qty 

			SELECT desc_text INTO l_arr_rec_parent[l_idx].desc_text FROM product 
			WHERE part_code = l_parent_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
	END FOREACH 

--	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("E",1008,"") #1008 F3/F4 TO Page Fwd/Bwd; OK TO Continue

	DISPLAY ARRAY l_arr_rec_parent TO sr_parent.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E11d","display-arr-parent") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	CLOSE WINDOW E460 
END FUNCTION 
############################################################
# END FUNCTION display_parent_quantities()
############################################################


###########################################################################
# FUNCTION check_pick_edit()
#
# 
###########################################################################
FUNCTION check_pick_edit() 

	IF glob_rec_opparms.allow_edit_flag = "N" THEN 
		ERROR kandoomsg2("E",9269,"") #9269 Order cannot be altered as picking slip has NOT been confirmed.
		RETURN FALSE 
	END IF 
	SELECT unique 1 FROM pickdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pick_num in 
		(select pick_num FROM pickhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND con_status_ind = "1" 
		AND status_ind = "0") 
	AND order_num = glob_rec_orderhead.order_num 

	IF status = 0 THEN 
		ERROR kandoomsg2("E",9274,"") #9274 Consignment note created. Line cannot be edited.
		RETURN FALSE 
	END IF 

	IF kandoomsg("E",8047,"") = "N" THEN	#8047 Do you wish TO reject the picking slip?
		RETURN FALSE 
	ELSE 
		LET glob_rec_sales_order_parameter.pick_ind = TRUE 
		RETURN TRUE
	 END IF
END FUNCTION 
############################################################
# END FUNCTION check_pick_edit()
############################################################