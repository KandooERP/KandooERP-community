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
# Requires
# common/note_disp.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_req(p_cmpy_code)
#
#
############################################################
FUNCTION show_req(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_arr_rec_reqhead DYNAMIC ARRAY OF #array[200] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			req_num LIKE reqhead.req_num, 
			person_code LIKE reqhead.person_code, 
			req_date LIKE reqhead.req_date, 
			stock_ind LIKE reqhead.stock_ind, 
			type_text CHAR(14), 
			status_ind LIKE reqhead.status_ind 
		END RECORD 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW n130 with FORM "N130" 
		CALL winDecoration_n("N130") 

		WHILE true 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue "

			CONSTRUCT BY NAME l_where_text ON req_num, 
			person_code, 
			req_date, 
			stock_ind, 
			status_ind 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","reqwind","construct-reqhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW n130 
				RETURN "" 
			END IF 
			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait "
			LET l_query_text = "SELECT * FROM reqhead ", 
			" WHERE cmpy_code = \"",p_cmpy_code,"\" ", 
			" AND ",l_where_text clipped," ", 
			" AND stock_ind != '0' ", 
			" AND status_ind != '9' ", 
			" AND status_ind != '0' ", 
			"ORDER BY req_num" 
			PREPARE s_reqhead FROM l_query_text 
			DECLARE c_reqhead CURSOR FOR s_reqhead 

			LET l_idx = 0 
			FOREACH c_reqhead INTO l_rec_reqhead.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_reqhead[l_idx].req_num = l_rec_reqhead.req_num 
				LET l_arr_rec_reqhead[l_idx].person_code = l_rec_reqhead.person_code 
				LET l_arr_rec_reqhead[l_idx].req_date = l_rec_reqhead.req_date 
				LET l_arr_rec_reqhead[l_idx].status_ind = l_rec_reqhead.status_ind 
				LET l_arr_rec_reqhead[l_idx].stock_ind = l_rec_reqhead.stock_ind 
				CASE l_rec_reqhead.stock_ind 
					WHEN "1" 
						LET l_arr_rec_reqhead[l_idx].type_text = kandooword("reqhead.stock_ind","1") 
					WHEN "2" 
						LET l_arr_rec_reqhead[l_idx].type_text = kandooword("reqhead.stock_ind","2") 
					OTHERWISE 
						LET l_arr_rec_reqhead[l_idx].type_text = NULL 
				END CASE 
				IF l_idx = 200 THEN 
					LET l_msgresp = kandoomsg("U",6100,l_idx) 
					#6100 First l_idx records selected
					EXIT FOREACH 
				END IF 
			END FOREACH 
			LET l_msgresp = kandoomsg("U",9113,l_idx) 
			#9113 l_idx records selected
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_reqhead[l_idx].* TO NULL 
			END IF 

			CALL set_count(l_idx) 
			LET l_msgresp = kandoomsg("U",1519,"") 
			#1519 "OK TO SELECT; ENTER TO View; F10 TO Add "
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

			INPUT ARRAY l_arr_rec_reqhead WITHOUT DEFAULTS FROM sr_reqhead.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","reqwind","input-arr-reqhead-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (F10) 
					CALL run_prog("N11","","","","") 
					NEXT FIELD scroll_flag 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					#            LET scrn = scr_line()
					NEXT FIELD scroll_flag 

					#		BEFORE FIELD scroll_flag
					#            DISPLAY l_arr_rec_reqhead[l_idx].* TO sr_reqhead[scrn].*

				AFTER FIELD scroll_flag 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 

					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF l_arr_rec_reqhead[l_idx+1].req_num IS NULL THEN 
							LET l_msgresp = kandoomsg("U",9001,"") 
							#9001 There no more rows...
							NEXT FIELD scroll_flag 
						END IF 
					END IF 

					IF fgl_lastkey() = fgl_keyval("nextpage") 
					AND l_arr_rec_reqhead[l_idx+8].person_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 No more rows in this direction
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD req_num 
					IF l_arr_rec_reqhead[l_idx].req_num IS NOT NULL THEN 

						MENU " Req. Details" 
							BEFORE MENU 
								CALL publish_toolbar("kandoo","reqwind","menu-Req_Details-1") 
							ON ACTION "WEB-HELP" -- albo kd-376 
								CALL onlinehelp(getmoduleid(),null) 

							COMMAND "Delivery" " Delivery Information" 
								CALL show_req_ship(p_cmpy_code,l_arr_rec_reqhead[l_idx].req_num) 

							COMMAND "Line Items" " Line Item Information" 
								CALL show_req_lines(p_cmpy_code,l_arr_rec_reqhead[l_idx].req_num) 

							COMMAND KEY(interrupt,"E")"Exit" " Exit TO Window" 
								LET int_flag = false 
								LET quit_flag = false 
								EXIT MENU 

						END MENU 

						LET l_msgresp = kandoomsg("U",1519,"") 
						#1519 "OK TO SELECT; ENTER TO View; F10 TO Add "
					END IF 
					NEXT FIELD scroll_flag 


					#		AFTER ROW
					#			DISPLAY l_arr_rec_reqhead[l_idx].* TO sr_reqhead[scrn].*


			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CONTINUE WHILE 
			END IF 
			EXIT WHILE 
		END WHILE 
		CLOSE WINDOW n130 
		OPTIONS INSERT KEY f1, 
		DELETE KEY f2 

		RETURN l_arr_rec_reqhead[l_idx].req_num 
END FUNCTION 


############################################################
# FUNCTION show_req_lines(p_cmpy_code,p_rec_req_num)
#
#
############################################################
FUNCTION show_req_lines(p_cmpy_code,p_rec_req_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_req_num LIKE reqhead.req_num 
	DEFINE l_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_arr_rec_reqdetl DYNAMIC ARRAY OF #array [2020] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE reqdetl.line_num, 
			part_code LIKE reqdetl.part_code, 
			req_qty LIKE reqdetl.req_qty, 
			uom_code LIKE reqdetl.uom_code, 
			warn_flag CHAR(1), 
			unit_sales_amt LIKE reqdetl.unit_sales_amt, 
			line_total_amt LIKE reqhead.total_sales_amt, 
			autoinsert_flag CHAR(1) 
		END RECORD 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

		OPEN WINDOW n107 with FORM "N107" 
		CALL winDecoration_n("N107") 

		LET l_msgresp = kandoomsg("U",1002,"") 
		SELECT * INTO l_rec_reqhead.* FROM reqhead 
		WHERE cmpy_code = p_cmpy_code 
		AND req_num = p_rec_req_num 
		DECLARE c_reqdetl CURSOR FOR 
		SELECT reqdetl.* FROM reqdetl 
		WHERE cmpy_code = p_cmpy_code 
		AND req_num = l_rec_reqhead.req_num 
		ORDER BY req_num, line_num 
		LET l_idx = 0 
		FOREACH c_reqdetl INTO l_rec_reqdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_reqdetl[l_idx].line_num = l_rec_reqdetl.line_num 
			LET l_arr_rec_reqdetl[l_idx].part_code = l_rec_reqdetl.part_code 
			LET l_arr_rec_reqdetl[l_idx].req_qty = l_rec_reqdetl.req_qty 
			LET l_arr_rec_reqdetl[l_idx].uom_code = l_rec_reqdetl.uom_code 
			LET l_arr_rec_reqdetl[l_idx].unit_sales_amt = l_rec_reqdetl.unit_sales_amt 
			LET l_arr_rec_reqdetl[l_idx].line_total_amt = l_rec_reqdetl.unit_sales_amt 
			* l_rec_reqdetl.req_qty 
			LET l_arr_rec_reqdetl[l_idx].autoinsert_flag = NULL 
			IF l_rec_reqdetl.req_num < 0 THEN 
				LET l_arr_rec_reqdetl[l_idx].warn_flag = "*" 
			ELSE 
				LET l_arr_rec_reqdetl[l_idx].warn_flag = check_quantity(p_cmpy_code,l_rec_reqdetl.*) 
			END IF 
			IF l_idx = 2000 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_reqdetl[l_idx].* TO NULL 
		END IF 
		LET l_msgresp = kandoomsg("R",1009,"") 
		#1009 F8 Line Detail;  F5 Product Inquiry;  CTRL+N View Notes.
		CALL set_count(l_idx) 
		SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
		WHERE cmpy_code = p_cmpy_code 
		AND ware_code = l_rec_reqhead.ware_code 
		DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 

		DISPLAY BY NAME l_rec_reqhead.total_sales_amt, 
		l_rec_reqhead.del_dept_text, 
		l_rec_reqhead.ware_code, 
		l_rec_reqhead.total_sales_amt 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		INPUT ARRAY l_arr_rec_reqdetl WITHOUT DEFAULTS FROM sr_reqdetl.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","reqwind","input-arr-reqdetl") 


			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (F8) 
				IF l_arr_rec_reqdetl[l_idx].part_code IS NOT NULL THEN 
					CALL display_line(p_cmpy_code,l_rec_reqdetl.*,1,l_rec_reqhead.ware_code) 
				END IF 
				NEXT FIELD scroll_flag 

			ON KEY (F5) 
				IF l_arr_rec_reqdetl[l_idx].part_code IS NOT NULL THEN 
					CALL pinvwind(p_cmpy_code,l_arr_rec_reqdetl[l_idx].part_code) 
					NEXT FIELD scroll_flag 
				END IF 

			ON ACTION "NOTES" --ON KEY (control-n) 
				IF l_rec_reqdetl.desc_text[1,3] = "###" 
				AND l_rec_reqdetl.desc_text[16,18] = "###" THEN 
					CALL note_disp(p_cmpy_code,l_rec_reqdetl.desc_text[4,15]) 
				ELSE 
					LET l_msgresp = kandoomsg("A",7027,"") 
					#7027 No Notes TO View
				END IF 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				NEXT FIELD scroll_flag 

			BEFORE FIELD scroll_flag 
				SELECT * INTO l_rec_reqdetl.* FROM reqdetl 
				WHERE cmpy_code = p_cmpy_code 
				AND req_num = l_rec_reqhead.req_num 
				AND line_num = l_arr_rec_reqdetl[l_idx].line_num 
				#         DISPLAY l_arr_rec_reqdetl[l_idx].* TO sr_reqdetl[scrn].*

				CALL display_stock(l_rec_reqdetl.*,2,l_rec_reqhead.ware_code) 
				DISPLAY l_rec_reqdetl.desc_text TO reqdetl.desc_text 

			AFTER FIELD scroll_flag 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_rec_reqdetl[l_idx+1].line_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
				IF fgl_lastkey() = fgl_keyval("nextpage") 
				AND l_arr_rec_reqdetl[l_idx+10].part_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD line_num 
				IF l_arr_rec_reqdetl[l_idx].part_code IS NOT NULL THEN 
					CALL show_line_status(p_cmpy_code,p_rec_req_num) 
				END IF 
				NEXT FIELD scroll_flag 

				#		AFTER ROW
				#         DISPLAY l_arr_rec_reqdetl[l_idx].* TO sr_reqdetl[scrn].*

				#			ON KEY (control-w)

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		CLOSE WINDOW n107 

END FUNCTION 


############################################################
# FUNCTION check_quantity(p_cmpy_code,p_rec_reqdetl)
#
#
############################################################
FUNCTION check_quantity(p_cmpy_code,p_rec_reqdetl) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 

	### Checking FOR outer_qty AND min_ord_qty differences ###
	SELECT * INTO l_rec_reqhead.* FROM reqhead 
	WHERE cmpy_code = p_cmpy_code 
	AND req_num = p_rec_reqdetl.req_num 
	SELECT product.min_ord_qty, 
	product.outer_qty, 
	prodstatus.replenish_ind 
	INTO l_rec_product.min_ord_qty, 
	l_rec_product.outer_qty, 
	l_rec_prodstatus.replenish_ind 
	FROM prodstatus, product 
	WHERE prodstatus.cmpy_code = p_cmpy_code 
	AND product.cmpy_code = p_cmpy_code 
	AND product.part_code = prodstatus.part_code 
	AND prodstatus.ware_code = l_rec_reqhead.ware_code 
	AND prodstatus.part_code = p_rec_reqdetl.part_code 
	IF status = 0 THEN 
		IF l_rec_prodstatus.replenish_ind = "P" 
		OR l_rec_prodstatus.replenish_ind IS NULL THEN 
			IF l_rec_product.min_ord_qty IS NOT NULL 
			AND l_rec_product.min_ord_qty != 0 THEN 
				IF p_rec_reqdetl.req_qty < l_rec_product.min_ord_qty THEN 
					RETURN "M" 
				END IF 
			END IF 
			IF l_rec_product.outer_qty IS NOT NULL 
			AND l_rec_product.outer_qty != 0 THEN 
				IF (p_rec_reqdetl.req_qty mod l_rec_product.outer_qty) > 0 THEN 
					RETURN "O" 
				END IF 
			END IF 
		END IF 
	END IF 
	RETURN "" 
END FUNCTION 


############################################################
# FUNCTION display_stock(p_rec_reqdetl,p_display_val,p_ware_code)
#
#
############################################################
FUNCTION display_stock(p_rec_reqdetl,p_display_val,p_ware_code) 
	DEFINE p_rec_reqdetl RECORD LIKE reqdetl.*
	DEFINE p_display_val SMALLINT
	DEFINE p_ware_code LIKE reqhead.ware_code
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_old_back LIKE reqdetl.back_qty 
	DEFINE l_old_reserve LIKE reqdetl.back_qty 
	DEFINE l_fut_avail LIKE prodstatus.onhand_qty
	DEFINE l_available LIKE prodstatus.onhand_qty	 

	LET l_cmpy_code = p_rec_reqdetl.cmpy_code 
	IF p_rec_reqdetl.part_code IS NOT NULL THEN 
		LET l_old_back = 0 
		LET l_old_reserve = 0 
		SELECT * INTO l_rec_product.* FROM product 
		WHERE part_code = p_rec_reqdetl.part_code 
		AND cmpy_code = l_cmpy_code 
		SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
		WHERE part_code = p_rec_reqdetl.part_code 
		AND ware_code = p_ware_code 
		AND cmpy_code = l_cmpy_code 
		IF l_rec_prodstatus.onhand_qty IS NULL THEN 
			LET l_rec_prodstatus.onhand_qty = 0 
		END IF 
		IF l_rec_prodstatus.onord_qty IS NULL THEN 
			LET l_rec_prodstatus.onord_qty = 0 
		END IF 
		IF l_rec_prodstatus.reserved_qty IS NULL THEN 
			LET l_rec_prodstatus.reserved_qty = 0 
		END IF 
		IF l_rec_prodstatus.back_qty IS NULL THEN 
			LET l_rec_prodstatus.back_qty = 0 
		END IF 
		LET l_rec_prodstatus.reserved_qty = l_rec_prodstatus.reserved_qty 
		- l_old_reserve 
		+ p_rec_reqdetl.reserved_qty 
		LET l_rec_prodstatus.back_qty = l_rec_prodstatus.back_qty 
		- l_old_back 
		+ p_rec_reqdetl.back_qty 
		LET l_available = l_rec_prodstatus.onhand_qty 
		- l_rec_prodstatus.reserved_qty 
		- l_rec_prodstatus.back_qty 
		LET l_fut_avail = l_available 
		+ l_rec_prodstatus.onord_qty 
	ELSE 
		INITIALIZE l_rec_prodstatus.* TO NULL 
		LET l_fut_avail = NULL 
		LET l_available = NULL 
	END IF 
	CASE p_display_val 
		WHEN 1 
			DISPLAY BY NAME l_rec_prodstatus.onhand_qty, 
			l_rec_prodstatus.onord_qty, 
			l_rec_prodstatus.reorder_point_qty, 
			l_rec_prodstatus.reorder_qty, 
			l_rec_prodstatus.max_qty, 
			l_rec_prodstatus.critical_qty, 
			l_rec_product.min_ord_qty, 
			l_rec_prodstatus.abc_ind 
			DISPLAY l_rec_prodstatus.back_qty,l_rec_prodstatus.reserved_qty,
			l_fut_avail,l_available 
			TO prodstatus.back_qty,prodstatus.reserved_qty,
			pr_fut_avail,pr_available 
		WHEN 2 
			DISPLAY l_rec_prodstatus.onhand_qty, 
			l_fut_avail,l_rec_prodstatus.max_qty,l_available
			TO l_rec_prodstatus.onhand_qty, 
			pr_fut_avail,l_rec_prodstatus.max_qty,pr_available
	END CASE 
END FUNCTION 


############################################################
# FUNCTION display_line(p_cmpy_code,p_rec_reqdetl,p_display_val,p_ware_code)
#
#
############################################################
FUNCTION display_line(p_cmpy_code,p_rec_reqdetl,p_display_val,p_ware_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE p_display_val SMALLINT 
	DEFINE p_ware_code LIKE reqhead.ware_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_prodquote RECORD LIKE prodquote.* 
	DEFINE l_rec_puparms RECORD LIKE puparms.* 
	DEFINE l_replenish_text CHAR(20) 
	DEFINE l_line_total LIKE reqhead.total_sales_amt 
	DEFINE l_conv_rate FLOAT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW n108 with FORM "N108" 
	CALL winDecoration_n("N108") 

	IF p_display_val THEN 
		IF p_rec_reqdetl.part_code IS NOT NULL THEN 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE part_code = p_rec_reqdetl.part_code 
			AND cmpy_code = p_cmpy_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9010,"") 
				#9010 Product Code does...
				CLOSE WINDOW n108 
				RETURN 
			END IF 
			IF p_rec_reqdetl.required_date IS NULL THEN 
				LET p_rec_reqdetl.required_date = today + l_rec_product.days_lead_num 
			END IF 
			SELECT category.* INTO l_rec_category.* FROM category 
			WHERE cmpy_code = p_cmpy_code 
			AND cat_code = l_rec_product.cat_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("N",9029,l_rec_product.part_code) 
				#9029 Product category...
				CLOSE WINDOW n108 
				RETURN 
			END IF 
			IF p_rec_reqdetl.acct_code IS NULL THEN 
				IF p_rec_reqdetl.desc_text IS NULL THEN 
					LET p_rec_reqdetl.desc_text = l_rec_product.desc_text 
				END IF 
				LET p_rec_reqdetl.acct_code = l_rec_category.sale_acct_code 
				LET p_rec_reqdetl.uom_code = l_rec_product.sell_uom_code 
				IF p_rec_reqdetl.replenish_ind IS NULL THEN 
					LET p_rec_reqdetl.replenish_ind = "P" 
				END IF 
				DECLARE c_prodquote SCROLL CURSOR FOR 
				SELECT cost_amt, curr_code 
				FROM prodquote 
				WHERE cmpy_code = p_cmpy_code 
				AND part_code = p_rec_reqdetl.part_code 
				AND vend_code = p_rec_reqdetl.vend_code 
				AND status_ind = 1 
				AND expiry_date >= today 
				ORDER BY cost_amt 
				OPEN c_prodquote 
				FETCH c_prodquote INTO l_rec_prodquote.cost_amt, 
				l_rec_prodquote.curr_code 
				IF status = notfound THEN 
					SELECT for_cost_amt 
					INTO p_rec_reqdetl.unit_sales_amt 
					FROM prodstatus 
					WHERE cmpy_code = p_cmpy_code 
					AND ware_code = p_ware_code 
					AND part_code = p_rec_reqdetl.part_code 
				ELSE 
					LET l_conv_rate = get_conv_rate(
						p_cmpy_code,
						l_rec_prodquote.curr_code,
						today,
						CASH_EXCHANGE_SELL) 
					
					LET p_rec_reqdetl.unit_sales_amt = l_rec_prodquote.cost_amt / l_conv_rate 
				END IF 
				CLOSE c_prodquote 
			END IF 
		END IF
		 
		IF p_rec_reqdetl.replenish_ind IS NOT NULL THEN 
			CASE p_rec_reqdetl.replenish_ind 
				WHEN "S" LET l_replenish_text = kandooword("prodstatus.replenish_ind", 
					p_rec_reqdetl.replenish_ind) 
					SELECT * INTO l_rec_puparms.* 
					FROM puparms 
					WHERE cmpy_code = p_cmpy_code 
					LET p_rec_reqdetl.vend_code = l_rec_puparms.usual_ware_code 
					SELECT desc_text INTO l_rec_vendor.name_text 
					FROM warehouse 
					WHERE cmpy_code = p_cmpy_code 
					AND ware_code = p_rec_reqdetl.vend_code 
				OTHERWISE LET p_rec_reqdetl.replenish_ind = "P" 
					LET l_replenish_text = kandooword("prodstatus.replenish_ind", 
					p_rec_reqdetl.replenish_ind) 
					SELECT * INTO l_rec_vendor.* FROM vendor 
					WHERE vend_code = p_rec_reqdetl.vend_code 
					AND cmpy_code = p_cmpy_code 
			END CASE 
		END IF 
		DISPLAY l_replenish_text TO replenish_text 

		DISPLAY BY NAME p_rec_reqdetl.part_code, 
		p_rec_reqdetl.desc_text, 
		p_rec_reqdetl.req_qty, 
		p_rec_reqdetl.reserved_qty, 
		p_rec_reqdetl.back_qty, 
		p_rec_reqdetl.picked_qty, 
		p_rec_reqdetl.confirmed_qty, 
		p_rec_reqdetl.replenish_ind, 
		p_rec_reqdetl.vend_code, 
		l_rec_vendor.name_text, 
		p_rec_reqdetl.required_date, 
		p_rec_reqdetl.unit_sales_amt, 
		p_rec_reqdetl.uom_code 

		DISPLAY p_ware_code 
		TO ware_code 

	END IF 
	IF p_rec_reqdetl.unit_sales_amt IS NULL THEN 
		LET p_rec_reqdetl.unit_sales_amt = 0 
	END IF 
	IF p_rec_reqdetl.req_qty IS NULL THEN 
		LET p_rec_reqdetl.req_qty = 0 
	END IF 
	LET l_line_total = p_rec_reqdetl.unit_sales_amt * p_rec_reqdetl.req_qty 
	DISPLAY l_line_total TO line_total 

	CALL display_stock(p_rec_reqdetl.*,1,p_ware_code) 
	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	#1 Any Key TO Continue
	CLOSE WINDOW n108 
END FUNCTION 



############################################################
# FUNCTION show_line_status(p_cmpy_code,p_req_num)
#
#
############################################################
FUNCTION show_line_status(p_cmpy_code,p_req_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_req_num LIKE reqhead.req_num 
	DEFINE l_arr_rec_reqstatus DYNAMIC ARRAY OF #array [2020] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			line_num LIKE reqdetl.line_num, 
			part_code LIKE reqdetl.part_code, 
			req_qty LIKE reqdetl.req_qty, 
			uom_code LIKE reqdetl.uom_code, 
			po_qty LIKE reqdetl.po_qty, 
			trf_qty LIKE reqdetl.po_qty 
		END RECORD 
	DEFINE l_arr_rec_transaction DYNAMIC ARRAY OF #array [2020] OF RECORD 
			RECORD 
				desc_text LIKE product.desc_text, 
				tran_num LIKE ibthead.trans_num, 
				tran_type CHAR(14), 
				tran_date DATE 
			END RECORD 
	DEFINE l_rec_reqdetl RECORD LIKE reqdetl.* 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_rec_ibthead RECORD LIKE ibthead.* 
	DEFINE l_rec_ibtdetl RECORD LIKE ibtdetl.* 
	DEFINE l_idx SMALLINT 
	DEFINE l_frm_label CHAR(7) 
	DEFINE l_waste FLOAT 
	DEFINE l_msgresp LIKE language.yes_flag 

			OPEN WINDOW n135 with FORM "N135" 
			CALL winDecoration_n("N135") 

			LET l_msgresp = kandoomsg("U",1002,"") 
			SELECT * INTO l_rec_reqhead.* FROM reqhead 
			WHERE req_num = p_req_num 
			AND cmpy_code = p_cmpy_code 
			DECLARE c2_reqdetl CURSOR FOR 
			SELECT * FROM reqdetl 
			WHERE req_num = l_rec_reqhead.req_num 
			AND cmpy_code = p_cmpy_code 
			ORDER BY req_num, line_num 
			LET l_idx = 0 
			FOREACH c2_reqdetl INTO l_rec_reqdetl.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_reqstatus[l_idx].line_num = l_rec_reqdetl.line_num 
				LET l_arr_rec_reqstatus[l_idx].part_code = l_rec_reqdetl.part_code 
				LET l_arr_rec_reqstatus[l_idx].req_qty = l_rec_reqdetl.req_qty 
				LET l_arr_rec_reqstatus[l_idx].uom_code = l_rec_reqdetl.uom_code 
				LET l_arr_rec_reqstatus[l_idx].po_qty = l_rec_reqdetl.po_qty 
				LET l_arr_rec_transaction[l_idx].tran_date = NULL 
				IF l_rec_reqdetl.replenish_ind = "S" THEN 
					SELECT trf_qty INTO l_arr_rec_reqstatus[l_idx].trf_qty FROM ibtdetl 
					WHERE trans_num = l_rec_reqdetl.trans_num 
					AND line_num = l_rec_reqdetl.trans_line_num 
					AND cmpy_code = p_cmpy_code 
					SELECT trans_date INTO l_arr_rec_transaction[l_idx].tran_date FROM ibthead 
					WHERE trans_num = l_rec_reqdetl.trans_num 
					AND cmpy_code = p_cmpy_code 
					LET l_arr_rec_transaction[l_idx].tran_type = 
					kandooword("prodstatus.replenish_ind","S") 
				ELSE 
					CALL po_line_info(p_cmpy_code, 
					l_rec_reqdetl.trans_num, 
					l_rec_reqdetl.trans_line_num) 
					RETURNING l_arr_rec_reqstatus[l_idx].trf_qty, 
					l_waste, 
					l_waste, 
					l_waste, 
					l_waste, 
					l_waste, 
					l_waste, 
					l_waste 
					SELECT order_date INTO l_arr_rec_transaction[l_idx].tran_date FROM purchhead 
					WHERE order_num = l_rec_reqdetl.trans_num 
					AND cmpy_code = p_cmpy_code 
					LET l_arr_rec_transaction[l_idx].tran_type = 
					kandooword("prodstatus.replenish_ind","P") 
				END IF 
				IF l_arr_rec_reqstatus[l_idx].trf_qty IS NULL THEN 
					LET l_arr_rec_reqstatus[l_idx].trf_qty = 0 
				END IF 
				LET l_arr_rec_transaction[l_idx].tran_num = l_rec_reqdetl.trans_num 
				SELECT desc_text INTO l_arr_rec_transaction[l_idx].desc_text FROM product 
				WHERE cmpy_code = p_cmpy_code 
				AND part_code = l_rec_reqdetl.part_code 
				IF l_idx = 2000 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			LET l_msgresp = kandoomsg("U",9113,l_idx) 
			#9113 l_idx records selected
			CALL set_count(l_idx) 
			DISPLAY BY NAME l_rec_reqhead.req_num, 
			l_rec_reqhead.req_date 

			LET l_msgresp = kandoomsg("R",1012,"") 
			#1012 ENTER TO View Purchase Order/Transfer Details;  OK TO Continue.
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

			INPUT ARRAY l_arr_rec_reqstatus WITHOUT DEFAULTS FROM sr_reqstatus.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","reqwind","input-arr-reqstatus") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				BEFORE ROW 
					LET l_idx = arr_curr() 
					#         LET scrn = scr_line()
					NEXT FIELD scroll_flag 

				BEFORE FIELD scroll_flag 
					#         DISPLAY l_arr_rec_reqstatus[l_idx].* TO sr_reqstatus[scrn].*

					SELECT * INTO l_rec_reqdetl.* FROM reqdetl 
					WHERE req_num = l_rec_reqhead.req_num 
					AND line_num = l_arr_rec_reqstatus[l_idx].line_num 
					AND cmpy_code = p_cmpy_code 
					DISPLAY BY NAME l_arr_rec_transaction[l_idx].desc_text, 
					l_arr_rec_transaction[l_idx].tran_num, 
					l_arr_rec_transaction[l_idx].tran_type, 
					l_arr_rec_transaction[l_idx].tran_date 

				AFTER FIELD scroll_flag 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD scroll_flag 
					END IF 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF l_arr_rec_reqstatus[l_idx+1].line_num IS NULL THEN 
							LET l_msgresp = kandoomsg("U",9001,"") 
							#9001 There no more rows...
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					IF fgl_lastkey() = fgl_keyval("nextpage") 
					AND l_arr_rec_reqstatus[l_idx+10].part_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						#9001 No more rows in this direction
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD line_num 
					IF l_arr_rec_transaction[l_idx].tran_type = 
					kandooword("prodstatus.replenish_ind","S") THEN 
						SELECT * INTO l_rec_ibthead.* FROM ibthead 
						WHERE trans_num = l_rec_reqdetl.trans_num 
						AND cmpy_code = p_cmpy_code 
						SELECT * INTO l_rec_ibtdetl.* FROM ibtdetl 
						WHERE trans_num = l_rec_reqdetl.trans_num 
						AND line_num = l_rec_reqdetl.trans_line_num 
						AND cmpy_code = p_cmpy_code 

						OPEN WINDOW i663 with FORM "I663" 
						CALL winDecoration_n("I663") 

						LET l_frm_label = "Inquiry" 
						DISPLAY l_frm_label TO frm_label 
						IF i55_disp_record(l_rec_ibthead.*,l_rec_ibtdetl.*) THEN 
							#LET l_msgresp = kandoomsg("U",1,"")
							CALL eventsuspend() 
							#1 Any Key TO Continue
						END IF 
						CLOSE WINDOW i663 
					ELSE 
						CALL podewind(p_cmpy_code,l_arr_rec_transaction[l_idx].tran_num) 
					END IF 
					NEXT FIELD scroll_flag 

					#      AFTER ROW
					#         DISPLAY l_arr_rec_reqstatus[l_idx].* TO sr_reqstatus[scrn].*


			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			CLOSE WINDOW n135 
END FUNCTION 



############################################################
# FUNCTION show_req_ship(p_cmpy_code,p_req_num)
#
#
############################################################
FUNCTION show_req_ship(p_cmpy_code,p_req_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_req_num LIKE reqhead.req_num 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_rec_reqhead RECORD LIKE reqhead.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Requistion") 
		#7001 Logic Error: Requisition RECORD Not Found
		RETURN 
	END IF 

	SELECT * INTO l_rec_reqhead.* FROM reqhead 
	WHERE req_num = p_req_num 
	AND cmpy_code = p_cmpy_code 

	SELECT * INTO l_rec_country.* FROM country 
	WHERE country_code = l_rec_reqhead.del_country_code 

	OPEN WINDOW n111 with FORM "N111" 
	CALL winDecoration_n("N111") 

	DISPLAY BY NAME 
		l_rec_reqhead.del_dept_text, 
		l_rec_reqhead.del_name_text, 
		l_rec_reqhead.del_addr1_text, 
		l_rec_reqhead.del_addr2_text, 
		l_rec_reqhead.del_addr3_text, 
		l_rec_reqhead.del_city_text, 
		l_rec_reqhead.del_state_code, 
		l_rec_reqhead.del_post_code, 
		l_rec_reqhead.del_country_code, 
--@db-patch_2020_10_04--		l_rec_country.country_text, 
		l_rec_reqhead.part_flag 

	#CALL eventSuspend()
	#LET l_msgresp = kandoomsg("U",1,"")

	CALL eventsuspend() 
	#1 Press Any Key TO Continue

	CLOSE WINDOW n111 
END FUNCTION 


