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

	Source code beautified by beautify.pl on 2020-01-02 17:31:25	$Id: $
}


# Purpose - Shop Order Maintenance - INPUT of shop ORDER header
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M34.4gl" 


FUNCTION query_orders() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnt SMALLINT, 

	fa_shopordhead array[1000] OF RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		order_type_ind LIKE shopordhead.order_type_ind, 
		sales_order_num LIKE shopordhead.sales_order_num, 
		cust_code LIKE shopordhead.cust_code, 
		part_code LIKE shopordhead.part_code, 
		status_ind LIKE shopordhead.status_ind, 
		start_date LIKE shopordhead.start_date, 
		end_date LIKE shopordhead.end_date 
	END RECORD 

	OPEN WINDOW w1_m147 with FORM "M147" 
	CALL  windecoration_m("M147") -- albo kd-762 

	WHILE true 

		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON shop_order_num, suffix_num, order_type_ind, sales_order_num, 
		cust_code, part_code, status_ind, start_date, end_date 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT shop_order_num, suffix_num, order_type_ind", 
		", sales_order_num, cust_code, part_code, ", 
		"status_ind, start_date, end_date ", 
		"FROM shopordhead ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND order_type_ind != 'F' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY shop_order_num" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_shopordhead CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_shopordhead INTO fa_shopordhead[fv_cnt].* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 1000 THEN 
				LET msgresp = kandoomsg("M", 9506, "") 
				# ERROR "Only the first 1000 shop orders have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1511, "") 
		# MESSAGE "RETURN on line TO Edit, F3 Fwd, F4 Bwd - DEL TO Exit"

		CALL set_count(fv_cnt - 1) 

		DISPLAY ARRAY fa_shopordhead TO sr_shopordhead.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M34a","display-arr-shopordhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

				IF fa_shopordhead[fv_idx].status_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 9790, "") 
					# ERROR "Cannot maintain a closed shop ORDER"
				ELSE 
					IF input_shopordhead(fa_shopordhead[fv_idx].shop_order_num, 
					fa_shopordhead[fv_idx].suffix_num) 
					THEN 
						LET fa_shopordhead[fv_idx].start_date = 
						pr_shopordhead.start_date 
						LET fa_shopordhead[fv_idx].end_date = 
						pr_shopordhead.end_date 
						LET fa_shopordhead[fv_idx].order_type_ind = 
						pr_shopordhead.order_type_ind 
						LET fa_shopordhead[fv_idx].sales_order_num = 
						pr_shopordhead.sales_order_num 
						LET fa_shopordhead[fv_idx].cust_code = 
						pr_shopordhead.cust_code 

						DISPLAY fa_shopordhead[fv_idx].* 
						TO sr_shopordhead[fv_scrn].* 
					END IF 
				END IF 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m147 

END FUNCTION 



FUNCTION input_shopordhead(fv_shop_order_num, fv_suffix_num) 

	DEFINE fv_name_text LIKE customer.name_text, 
	fv_part_desc LIKE product.desc_text, 
	fv_shop_order_num LIKE shopordhead.shop_order_num, 
	fv_suffix_num LIKE shopordhead.suffix_num, 
	fv_unit_cost_amt LIKE shopordhead.std_est_cost_amt, 
	fv_unit_price_amt LIKE shopordhead.std_price_amt, 
	fv_act_unit_cost LIKE shopordhead.act_est_cost_amt, 
	fv_act_unit_price LIKE shopordhead.act_price_amt, 
	fv_old_qty LIKE shopordhead.order_qty, 
	#fv_avail_ind       LIKE calendar.available_ind,
	fv_avail_ind LIKE calendar.available_flag, 
	fv_sales_order_num LIKE shopordhead.sales_order_num, 
	fv_ref_code LIKE userref.ref_code, 
	fv_cnt1 SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_adjust CHAR(1), 
	dummy CHAR(1), 

	fr_product RECORD LIKE product.*, 
	fr_orderhead RECORD LIKE orderhead.* 


	SELECT * 
	INTO pr_shopordhead.* 
	FROM shopordhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fv_shop_order_num 
	AND suffix_num = fv_suffix_num 

	IF pr_shopordhead.order_qty = pr_shopordhead.receipted_qty + 
	pr_shopordhead.rejected_qty THEN 
		LET msgresp = kandoomsg("M", 9791, "") 
		# ERROR "This shop ORDER has been fully receipted"
		RETURN false 
	END IF 

	LET fv_old_qty = pr_shopordhead.order_qty 

	OPEN WINDOW w1_m128 with FORM "M128" 
	CALL  windecoration_m("M128") -- albo kd-762 

	IF pr_mnparms.ref4_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref4_text 
	END IF 

	LET msgresp = kandoomsg("M", 1505, "") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.parent_part_code, 
	pr_shopordhead.cust_code, 
	pr_shopordhead.part_code, 
	pr_shopordhead.status_ind, 
	pr_shopordhead.uom_code, 
	pr_shopordhead.receipted_qty, 
	pr_shopordhead.rejected_qty, 
	pr_shopordhead.std_price_amt, 
	pr_shopordhead.act_price_amt, 
	pr_shopordhead.job_length_num, 
	pr_shopordhead.actual_start_date, 
	pr_shopordhead.actual_end_date 

	IF pr_shopordhead.parent_part_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO fv_part_desc 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.parent_part_code 

		DISPLAY fv_part_desc TO parent_desc 
	END IF 

	IF pr_shopordhead.cust_code IS NOT NULL THEN 
		SELECT name_text 
		INTO fv_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_shopordhead.cust_code 

		DISPLAY fv_name_text TO name_text 
	END IF 

	SELECT * 
	INTO fr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_shopordhead.part_code 

	DISPLAY BY NAME fr_product.desc_text 

	CASE pr_shopordhead.status_ind 
		WHEN "H" 
			LET pv_text = kandooword("Held", "M07") 
		WHEN "R" 
			LET pv_text = kandooword("Released", "M08") 
	END CASE 

	DISPLAY pv_text TO status_text 

	CASE 
		WHEN pr_inparms.cost_ind matches "[WF]" 
			IF pr_inparms.cost_ind = "W" THEN 
				LET pv_text = kandooword("Weighted", "M10") 
			ELSE 
				LET pv_text = kandooword("FIFO", "M11") 
			END IF 

			LET fv_unit_cost_amt = pr_shopordhead.std_wgted_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_wgted_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_wgted_cost_amt, 
			pr_shopordhead.act_wgted_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 

		WHEN pr_inparms.cost_ind = "S" 
			LET pv_text = kandooword("Standard", "M12") 
			LET fv_unit_cost_amt = pr_shopordhead.std_est_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_est_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_est_cost_amt, 
			pr_shopordhead.act_est_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET pv_text = kandooword("Latest", "M13") 
			LET fv_unit_cost_amt = pr_shopordhead.std_act_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_act_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_act_cost_amt, 
			pr_shopordhead.act_act_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 
	END CASE 

	DISPLAY pv_text TO cost_method_text 
	LET fv_unit_price_amt = pr_shopordhead.std_price_amt / 
	pr_shopordhead.order_qty 

	IF pr_shopordhead.receipted_qty > 0 THEN 
		LET fv_act_unit_price = pr_shopordhead.act_price_amt / 
		pr_shopordhead.receipted_qty 
	ELSE 
		LET fv_act_unit_price = 0 
	END IF 

	DISPLAY fv_unit_cost_amt, 
	fv_unit_price_amt, 
	fv_act_unit_cost, 
	fv_act_unit_price 
	TO unit_cost_amt, 
	unit_price_amt, 
	act_unit_cost_amt, 
	act_unit_price_amt 

	INPUT BY NAME pr_shopordhead.order_type_ind, 
	pr_shopordhead.sales_order_num, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.start_date, 
	pr_shopordhead.end_date, 
	pr_shopordhead.user4_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(sales_order_num) 
					CALL show_orders(glob_rec_kandoouser.cmpy_code) RETURNING fv_sales_order_num 

					IF fv_sales_order_num IS NOT NULL THEN 
						LET pr_shopordhead.sales_order_num = fv_sales_order_num 
						NEXT FIELD sales_order_num 
					END IF 

				WHEN infield(user4_text) 
					IF pr_mnparms.ref4_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","4") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shopordhead.user4_text = fv_ref_code 
							NEXT FIELD user4_text 
						END IF 
					END IF 
			END CASE 

		ON ACTION "NOTES" infield (user4_text) --ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_shopordhead.user4_text) 
				RETURNING pr_shopordhead.user4_text 
				DISPLAY BY NAME pr_shopordhead.user4_text 

		AFTER FIELD order_type_ind 
			IF pr_shopordhead.order_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M", 9766, "") 
				# ERROR "Shop ORDER type must be entered"
				NEXT FIELD order_type_ind 
			END IF 

			IF pr_shopordhead.order_type_ind NOT matches "[OS]" THEN 
				LET msgresp = kandoomsg("M", 9767, "") 
				# ERROR "This shop ORDER type IS NOT valid"
				NEXT FIELD order_type_ind 
			END IF 

		AFTER FIELD sales_order_num 
			IF pr_shopordhead.order_type_ind = "S" THEN 
				IF pr_shopordhead.sales_order_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9768, "") 
					# ERROR "Sales ORDER number must be entered"
					NEXT FIELD order_type_ind 
				END IF 

				SELECT * 
				INTO fr_orderhead.* 
				FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_shopordhead.sales_order_num 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9769, "") 
					# ERROR "This sales ORDER doesn't exist in the database-Try"
					NEXT FIELD sales_order_num 
				END IF 

				IF fr_orderhead.status_ind != "U" THEN 
					LET msgresp = kandoomsg("M", 9770, "") 
					# ERROR "The STATUS of the sales ORDER must be 'Unshipped'"
					NEXT FIELD sales_order_num 
				END IF 

				SELECT unique part_code 
				FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_shopordhead.sales_order_num 
				AND part_code = pr_shopordhead.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9776, "") 
					# ERROR "This product IS NOT on the sales ORDER - Try Window"
					NEXT FIELD sales_order_num 
				END IF 

				# Get sales ORDER IF there
			ELSE 
				LET fr_orderhead.cust_code = NULL 
				LET fv_name_text = NULL 
				IF pr_shopordhead.sales_order_num IS NOT NULL THEN 
					SELECT * 
					INTO fr_orderhead.* 
					FROM orderhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pr_shopordhead.sales_order_num 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9769, "") 
						#  "This sales ORDER doesn't exist in the database-Try"
						NEXT FIELD sales_order_num 
					END IF 
				END IF 
			END IF 

			SELECT name_text 
			INTO fv_name_text 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = fr_orderhead.cust_code 

			LET pr_shopordhead.cust_code = fr_orderhead.cust_code 
			DISPLAY BY NAME pr_shopordhead.cust_code 
			DISPLAY fv_name_text TO customer.name_text 

		AFTER FIELD order_qty 
			IF pr_shopordhead.order_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9778, "") 
				# ERROR "Shop ORDER quantity must be entered"
				NEXT FIELD order_qty 
			END IF 

			IF pr_shopordhead.order_qty <= 0 THEN 
				LET msgresp = kandoomsg("M", 9779, "") 
				# ERROR "Shop ORDER quantity must be greater than zero"
				NEXT FIELD order_qty 
			END IF 

			IF pr_shopordhead.status_ind = "R" THEN 
				IF pr_shopordhead.order_qty < pr_shopordhead.receipted_qty + 
				pr_shopordhead.rejected_qty THEN 
					LET msgresp = kandoomsg("M", 9792, "") 
					#ERROR "Order qty cannot be less than receipt + reject qtys"
					NEXT FIELD order_qty 
				END IF 
			END IF 

			IF pr_shopordhead.order_type_ind = "S" THEN 
				SELECT sum(order_qty) 
				INTO fv_cnt1 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num != pr_shopordhead.shop_order_num 
				AND order_type_ind = "S" 
				AND sales_order_num = pr_shopordhead.sales_order_num 
				AND part_code = pr_shopordhead.part_code 

				IF fv_cnt1 IS NULL THEN 
					LET fv_cnt1 = 0 
				END IF 

				LET fv_cnt1 = fv_cnt1 + pr_shopordhead.order_qty 

				SELECT sum(order_qty) 
				INTO fv_cnt2 
				FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_shopordhead.sales_order_num 
				AND part_code = pr_shopordhead.part_code 

				IF fv_cnt2 IS NULL THEN 
					LET fv_cnt2 = 0 
				END IF 

				IF fv_cnt1 > fv_cnt2 THEN 
					LET msgresp = kandoomsg("M", 9777, "") 
					# ERROR "There IS already shop orders fulfilling total
					#        sales ORDER requirements"
					NEXT FIELD order_qty 
				END IF 
			END IF 


		BEFORE FIELD start_date 
			IF pr_shopordhead.status_ind = "R" THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD order_qty 
				ELSE 
					NEXT FIELD end_date 
				END IF 
			END IF 

		AFTER FIELD start_date 
			IF pr_shopordhead.start_date IS NOT NULL THEN 
				SELECT available_ind 
				INTO fv_avail_ind 
				FROM calendar 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND calendar_date = pr_shopordhead.start_date 

				IF status != notfound AND fv_avail_ind = "N" THEN 
					LET msgresp = kandoomsg("M", 9780, "") 
					# ERROR "This date IS NOT available"
					NEXT FIELD start_date 
				END IF 
			END IF 

			IF pr_shopordhead.start_date > pr_shopordhead.end_date THEN 
				LET msgresp = kandoomsg("M", 9588, "") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

			LET pr_shopordhead.job_length_num = pr_shopordhead.end_date - 
			pr_shopordhead.start_date + 1 
			DISPLAY BY NAME pr_shopordhead.job_length_num 

		AFTER FIELD end_date 
			IF pr_shopordhead.end_date IS NOT NULL THEN 
				SELECT available_ind 
				INTO fv_avail_ind 
				FROM calendar 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND calendar_date = pr_shopordhead.end_date 

				IF status != notfound AND fv_avail_ind = "N" THEN 
					LET msgresp = kandoomsg("M", 9780, "") 
					# ERROR "This date IS NOT available"
					NEXT FIELD end_date 
				END IF 
			END IF 

			IF pr_shopordhead.start_date > pr_shopordhead.end_date THEN 
				LET msgresp = kandoomsg("M", 9588, "") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD end_date 
			END IF 

			LET pr_shopordhead.job_length_num = pr_shopordhead.end_date - 
			pr_shopordhead.start_date + 1 
			DISPLAY BY NAME pr_shopordhead.job_length_num 

		BEFORE FIELD user4_text 
			IF pr_mnparms.ref4_ind NOT matches "[1234]" 
			OR pr_mnparms.ref4_ind IS NULL THEN 
				NEXT FIELD dummy 
			END IF 

		AFTER FIELD user4_text 
			IF pr_shopordhead.user4_text IS NULL THEN 
				IF pr_mnparms.ref4_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user4_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref4_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "4" 
					AND ref_code = pr_shopordhead.user4_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user4_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_shopordhead.order_type_ind = "S" THEN 
				IF pr_shopordhead.sales_order_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9768, "") 
					# ERROR "Sales ORDER number must be entered"
					NEXT FIELD sales_order_num 
				END IF 

				SELECT sum(order_qty) 
				INTO fv_cnt1 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num != pr_shopordhead.shop_order_num 
				AND order_type_ind = "S" 
				AND sales_order_num = pr_shopordhead.sales_order_num 
				AND part_code = pr_shopordhead.part_code 

				IF fv_cnt1 IS NULL THEN 
					LET fv_cnt1 = 0 
				END IF 

				LET fv_cnt1 = fv_cnt1 + pr_shopordhead.order_qty 

				SELECT sum(order_qty) 
				INTO fv_cnt2 
				FROM orderdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_shopordhead.sales_order_num 
				AND part_code = pr_shopordhead.part_code 

				IF fv_cnt2 IS NULL THEN 
					LET fv_cnt2 = 0 
				END IF 

				IF fv_cnt1 > fv_cnt2 THEN 
					LET msgresp = kandoomsg("M", 9777, "") 
					# ERROR "There IS already shop orders fulfilling total
					#        sales ORDER requirements"
					NEXT FIELD order_qty 
				END IF 
			END IF 

			IF pr_shopordhead.start_date IS NULL 
			AND pr_shopordhead.end_date IS NULL THEN 
				LET msgresp = kandoomsg("M", 9781, "") 
				# ERROR "A start OR END date must be entered"
				NEXT FIELD start_date 
			END IF 

			IF pr_shopordhead.start_date > pr_shopordhead.end_date THEN 
				LET msgresp = kandoomsg("M", 9588, "") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

			IF pr_shopordhead.user4_text IS NULL THEN 
				IF pr_mnparms.ref4_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user4_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref4_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "4" 
					AND ref_code = pr_shopordhead.user4_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user4_text 
					END IF 
				END IF 
			END IF 

			IF pr_shopordhead.order_qty != fv_old_qty THEN 
				LET fv_adjust = kandoomsg("M", 8502, "") 
				# prompt "The ORDER quantity has changed.  Do you want TO
				# adjust the quantities of all components AND by-products on
				# the shop ORDER (Y/N)?"
			END IF 

			CALL input_shoporddetl(fr_product.desc_text, fv_old_qty, fv_adjust) 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT FIELD order_qty 
			END IF 

			CALL redisplay_costs() 

	END INPUT 

	CLOSE WINDOW w1_m128 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



FUNCTION redisplay_costs() 

	DEFINE fv_unit_cost_amt LIKE shopordhead.std_est_cost_amt, 
	fv_unit_price_amt LIKE shopordhead.std_price_amt, 
	fv_ext_cost_amt LIKE shopordhead.std_est_cost_amt 


	CASE 
		WHEN pr_inparms.cost_ind = "S" 
			LET fv_unit_cost_amt = pr_shopordhead.std_est_cost_amt / 
			pr_shopordhead.order_qty 
			LET fv_ext_cost_amt = pr_shopordhead.std_est_cost_amt 

		WHEN pr_inparms.cost_ind matches "[WF]" 
			LET fv_unit_cost_amt = pr_shopordhead.std_wgted_cost_amt / 
			pr_shopordhead.order_qty 
			LET fv_ext_cost_amt = pr_shopordhead.std_wgted_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET fv_unit_cost_amt = pr_shopordhead.std_act_cost_amt / 
			pr_shopordhead.order_qty 
			LET fv_ext_cost_amt = pr_shopordhead.std_act_cost_amt 
	END CASE 

	LET fv_unit_price_amt = pr_shopordhead.std_price_amt / 
	pr_shopordhead.order_qty 

	DISPLAY fv_unit_cost_amt, 
	fv_unit_price_amt, 
	fv_ext_cost_amt, 
	pr_shopordhead.act_price_amt, 
	pr_shopordhead.act_price_amt, 
	pr_shopordhead.act_price_amt 
	TO unit_cost_amt, 
	unit_price_amt, 
	ext_cost_amt, 
	act_unit_cost_amt, 
	act_unit_price_amt, 
	act_ext_cost_amt 

	DISPLAY BY NAME pr_shopordhead.std_price_amt, 
	pr_shopordhead.act_price_amt, 
	pr_shopordhead.start_date, 
	pr_shopordhead.end_date, 
	pr_shopordhead.job_length_num 

END FUNCTION 
