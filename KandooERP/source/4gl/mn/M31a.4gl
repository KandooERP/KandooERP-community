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

	Source code beautified by beautify.pl on 2020-01-02 17:31:22	$Id: $
}



# Purpose - Shop Order Add - INPUT of shop ORDER header
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M31.4gl" 


FUNCTION input_shopordhead() 

	DEFINE fv_cust_name LIKE customer.name_text, 
	fv_sales_order_num LIKE shopordhead.sales_order_num, 
	fv_part_code LIKE shopordhead.part_code, 
	fv_part_copy LIKE shopordhead.part_code, 
	fv_part_desc LIKE product.desc_text, 
	#fv_avail_ind          LIKE calendar.available_ind,
	fv_avail_ind LIKE calendar.available_flag, 
	fv_ref_code LIKE userref.ref_code, 
	dummy CHAR(1), 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_return SMALLINT, 

	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_orderhead RECORD LIKE orderhead.* 


	IF NOT pv_header THEN 
		# i.e. adding a shop ORDER (called FROM M31.4gl)
		OPEN WINDOW w1_m128 with FORM "M128" 
		CALL  windecoration_m("M128") -- albo kd-762 
	END IF 

	LET pv_shopord_cnt = 0 

	WHILE true 
		LET msgresp = kandoomsg("M", 1505, "") 	# MESSAGE "ESC TO Accept - DEL TO Exit"
		CLEAR FORM 

		IF pr_mnparms.ref4_ind matches "[1234]" THEN 
			DISPLAY BY NAME pr_mnparms.ref4_text 
		END IF 

		INITIALIZE pr_shopordhead.* TO NULL 
		LET pr_shopordhead.order_type_ind = "O" 
		LET pr_shopordhead.status_ind = "H" 
		LET pr_shopordhead.start_date = today 

		IF pv_args THEN 
			# pv_args probably FALSE WHEN creating a new ORDER
			LET pr_shopordhead.part_code = arg_val(1) 
			LET pr_shopordhead.order_qty = arg_val(2) 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 

			LET pr_shopordhead.uom_code = fr_prodmfg.man_uom_code 
		END IF 

		CASE pr_inparms.cost_ind 
			WHEN "W" 
				LET pv_text = kandooword("Weighted", "M10") 
			WHEN "F" 
				LET pv_text = kandooword("FIFO", "M11") 
			WHEN "S" 
				LET pv_text = kandooword("Standard", "M12") 
			WHEN "L" 
				LET pv_text = kandooword("Latest", "M13") 
		END CASE 

		DISPLAY pv_text TO cost_method_text 

		IF pv_header THEN 
			# i.e. NOT adding a new ORDER
			LET pr_shopordhead.part_code 
			= pa_parent[pv_shopord_cnt + 1].part_code 
			LET pr_shopordhead.order_qty 
			= pa_parent[pv_shopord_cnt + 1].required_qty 
			LET pr_shopordhead.parent_part_code = pr_sohead_master.part_code 
			LET pr_shopordhead.start_date = pr_sohead_master.start_date 
			LET pr_shopordhead.end_date = pr_sohead_master.end_date 

			SELECT man_uom_code 
			INTO pr_shopordhead.uom_code 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 

			SELECT desc_text 
			INTO fv_part_desc 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.parent_part_code 

			DISPLAY fv_part_desc TO parent_desc 
		END IF 

		IF fv_return THEN 
			LET pr_shopordhead.* = pr_sohead_master.* 
			LET fv_return = false 
		END IF 

		DISPLAY BY NAME pr_shopordhead.parent_part_code, 
		pr_shopordhead.status_ind, 
		pr_shopordhead.uom_code 
		LET pv_text = kandooword("Held", "M07") 
		DISPLAY pv_text TO status_text 

		INPUT BY NAME pr_shopordhead.order_type_ind, 
		pr_shopordhead.sales_order_num, 
		pr_shopordhead.part_code, 
		pr_shopordhead.order_qty, 
		pr_shopordhead.start_date, 
		pr_shopordhead.end_date, 
		pr_shopordhead.user4_text, 
		dummy 
		WITHOUT DEFAULTS 

			BEFORE INPUT 
				IF pv_args THEN 
					LET pv_args = false 
					DISPLAY BY NAME fr_product.desc_text 
					CALL display_costs(fr_product.*, fr_prodmfg.*) 
					NEXT FIELD part_code 
				END IF 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(part_code) 
						IF pr_shopordhead.order_type_ind = "O" THEN 
							CALL show_mfgprods(glob_rec_kandoouser.cmpy_code,"MG") RETURNING fv_part_code 

							IF fv_part_code IS NOT NULL THEN 
								LET pr_shopordhead.part_code = fv_part_code 
								DISPLAY BY NAME pr_shopordhead.part_code 
							END IF 
						ELSE 
							CALL lookup_products() RETURNING fv_part_code 

							IF fv_part_code IS NOT NULL THEN 
								LET pr_shopordhead.part_code = fv_part_code 
								DISPLAY BY NAME pr_shopordhead.part_code 
							END IF 
						END IF 

					WHEN infield(sales_order_num) 
						CALL show_orders(glob_rec_kandoouser.cmpy_code) RETURNING fv_sales_order_num 

						IF fv_sales_order_num IS NOT NULL THEN 
							LET pr_shopordhead.sales_order_num = 
							fv_sales_order_num 
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

			ON ACTION "NOTES" infield (user4_text) --	ON KEY (control-n) 
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

			BEFORE FIELD sales_order_num 
				IF pr_shopordhead.order_type_ind = "O" THEN 
					#3057                    IF fgl_lastkey() = fgl_keyval("RETURN")
					#3057                    OR fgl_lastkey() = fgl_keyval("tab")
					#3057                    OR fgl_lastkey() = fgl_keyval("down")
					#3057                    OR fgl_lastkey() = fgl_keyval("right") THEN
					#3057
					LET pr_shopordhead.sales_order_num = NULL 
					LET pr_shopordhead.cust_code = NULL 
					DISPLAY BY NAME pr_shopordhead.sales_order_num, 
					pr_shopordhead.cust_code 
					DISPLAY "" TO name_text 
					#3057                        NEXT FIELD part_code
					#3057                    ELSE
					#3057                        NEXT FIELD order_type_ind
					#3057                    END IF
				END IF 

			AFTER FIELD sales_order_num 
				IF pr_shopordhead.order_type_ind = "S" THEN #3057 
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

					SELECT count(*) 
					INTO fv_cnt 
					FROM orderdetl, prodmfg 
					WHERE orderdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND orderdetl.cmpy_code = prodmfg.cmpy_code 
					AND order_num = pr_shopordhead.sales_order_num 
					AND orderdetl.part_code = prodmfg.part_code 
					AND part_type_ind NOT matches "[RP]" 

					IF fv_cnt = 0 THEN 
						LET msgresp = kandoomsg("M", 9771, "") 
						# ERROR "This sales ORDER contains no generic OR
						#        manufactured products"
						NEXT FIELD sales_order_num 
					END IF 
					#3057 - Get sales ORDER IF there
				ELSE 
					LET fr_orderhead.cust_code = NULL 
					LET fv_cust_name = NULL 
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
				END IF #3057 
				#3057 - end

				SELECT name_text 
				INTO fv_cust_name 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = fr_orderhead.cust_code 

				LET pr_shopordhead.cust_code = fr_orderhead.cust_code 
				DISPLAY BY NAME pr_shopordhead.cust_code 
				DISPLAY fv_cust_name TO customer.name_text 

			BEFORE FIELD part_code 
				IF pv_header THEN 
					IF fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left") THEN 
						NEXT FIELD order_type_ind 
					ELSE 
						NEXT FIELD order_qty 
					END IF 
				END IF 

				LET fv_part_copy = pr_shopordhead.part_code 

			AFTER FIELD part_code 
				IF pr_shopordhead.part_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9532, "") 
					# ERROR "Product code must be entered"
					NEXT FIELD part_code 
				END IF 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9511, "") 
					#ERROR "This product does NOT exist in the database-Try win"
					NEXT FIELD part_code 
				END IF 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9569, "") 
					# ERROR "This product IS NOT SET up as a manufacturing prod"
					NEXT FIELD part_code 
				END IF 

				IF fr_prodmfg.part_type_ind matches "[RP]" THEN 
					LET msgresp = kandoomsg("M", 9773, "") 
					# ERROR "You cannot create a shop ORDER FOR a purchased OR
					#        phantom product"
					NEXT FIELD part_code 
				END IF 

				IF fr_prodmfg.part_type_ind = "G" THEN 
					IF pv_header 
					AND fr_prodmfg.config_ind = "Y" THEN 
						LET msgresp = kandoomsg("M", 9774, "") 
						# ERROR "Cannot have a configurable product on a
						#        configured shop ORDER"
						NEXT FIELD part_code 
					END IF 

					SELECT unique generic_part_code 
					FROM configuration 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND generic_part_code = pr_shopordhead.part_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9775, "") 
						# ERROR "This generic product must have configurations
						#        SET up first"
						NEXT FIELD part_code 
					END IF 
				END IF 

				IF pr_shopordhead.order_type_ind = "S" THEN 
					SELECT count(*) 
					INTO fv_cnt 
					FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pr_shopordhead.sales_order_num 
					AND part_code = pr_shopordhead.part_code 

					IF fv_cnt = 0 THEN 
						LET msgresp = kandoomsg("M", 9776, "") 
						# ERROR "This product IS NOT on the sales ORDER-Try Win"
						NEXT FIELD part_code 
					END IF 

					SELECT sum(order_qty) INTO fv_cnt1 
					FROM shopordhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND sales_order_num = pr_shopordhead.sales_order_num 
					AND part_code = pr_shopordhead.part_code 
					AND order_type_ind = "S" 

					SELECT sum(order_qty) 
					INTO fv_cnt2 
					FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pr_shopordhead.sales_order_num 
					AND part_code = pr_shopordhead.part_code 

					IF fv_cnt1 >= fv_cnt2 THEN 
						LET msgresp = kandoomsg("M", 9777, "") 
						#                      ERROR "There IS already shop orders fulfilling total
						#                             sales ORDER requirements"
						NEXT FIELD part_code 
					END IF 

					#SELECT shop_order_num
					#FROM   shopordhead
					#WHERE  cmpy_code       = glob_rec_kandoouser.cmpy_code
					#AND    sales_order_num = pr_shopordhead.sales_order_num
					#AND    part_code       = pr_shopordhead.part_code

					#IF STATUS != NOTFOUND THEN
					#LET msgresp = kandoomsg("M", 9777, "")
					# ERROR "There IS already a shop ORDER FOR this product
					#        AND sales ORDER"
					#NEXT FIELD part_code
					#END IF
				END IF 

				DISPLAY BY NAME fr_product.desc_text 

				IF pr_shopordhead.part_code != fv_part_copy 
				OR fv_part_copy IS NULL THEN 

					IF fr_product.min_ord_qty = 0 
					OR fr_product.min_ord_qty IS NULL THEN 
						LET pr_shopordhead.order_qty = 1 
					ELSE 
						LET pr_shopordhead.order_qty = fr_product.min_ord_qty * 
						fr_product.pur_stk_con_qty / 
						fr_prodmfg.man_stk_con_qty 
					END IF 

					LET pr_shopordhead.uom_code = fr_prodmfg.man_uom_code 
					DISPLAY BY NAME pr_shopordhead.uom_code, 
					pr_shopordhead.order_qty 

					CALL display_costs(fr_product.*, fr_prodmfg.*) 
				END IF 

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

				CALL display_costs(fr_product.*, fr_prodmfg.*) 

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
					# ERROR "Start date cannot be greater than END date"
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
					LET int_flag = false 
					LET quit_flag = false 
					LET pv_cont = true 
					RETURN 
				END IF 

				IF pr_shopordhead.order_type_ind = "S" 
				AND pr_shopordhead.sales_order_num IS NULL THEN 
					LET msgresp = kandoomsg("M", 9768, "") 
					# ERROR "Sales ORDER number must be entered"
					NEXT FIELD sales_order_num 
				END IF 

				IF pr_shopordhead.part_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9532, "") 
					# ERROR "Product code must be entered"
					NEXT FIELD part_code 
				END IF 

				IF pv_header THEN 
					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9511, "") 
						#error"This product does NOT exist in the dbase-Try win"
						NEXT FIELD order_type_ind 
					END IF 

					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9569, "") 
						# ERROR "This product IS NOT SET up as a mfg product"
						NEXT FIELD order_type_ind 
					END IF 

					IF fr_prodmfg.part_type_ind matches "[RP]" THEN 
						LET msgresp = kandoomsg("M", 9773, "") 
						# ERROR "You cannot create a shop ORDER FOR a purchased
						#        OR phantom product"
						NEXT FIELD order_type_ind 
					END IF 

					IF fr_prodmfg.part_type_ind = "G" THEN 
						IF fr_prodmfg.config_ind = "Y" THEN 
							LET msgresp = kandoomsg("M", 9774, "") 
							# ERROR "Cannot have a configurable product on a
							#        configured shop ORDER"
							NEXT FIELD order_type_ind 
						END IF 

						SELECT unique generic_part_code 
						FROM configuration 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND generic_part_code = pr_shopordhead.part_code 

						IF status = notfound THEN 
							LET msgresp = kandoomsg("M", 9775, "") 
							# ERROR "This generic product must have
							#        configurations SET up first"
							NEXT FIELD order_type_ind 
						END IF 
					END IF 

					IF pr_shopordhead.order_type_ind = "S" THEN 
						SELECT count(*) 
						INTO fv_cnt 
						FROM orderdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND order_num = pr_shopordhead.sales_order_num 
						AND part_code = pr_shopordhead.part_code 

						IF fv_cnt = 0 THEN 
							LET msgresp = kandoomsg("M", 9776, "") 
							#error"This prod IS NOT on the sales ORDER-Try Win"
							NEXT FIELD sales_order_num 
						END IF 

						#SELECT shop_order_num
						#FROM   shopordhead
						#WHERE  cmpy_code       = glob_rec_kandoouser.cmpy_code
						#AND    sales_order_num = pr_shopordhead.sales_order_num
						#AND    part_code       = pr_shopordhead.part_code

						#IF STATUS != NOTFOUND THEN
						#LET msgresp = kandoomsg("M", 9777, "")
						# ERROR "There IS already a shop ORDER FOR this
						#        product AND sales ORDER"
						#NEXT FIELD sales_order_num
						#END IF
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

				IF pr_shopordhead.user4_text IS NULL 
				AND pr_mnparms.ref4_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user4_text 
				END IF 

				IF fr_prodmfg.part_type_ind != "G" 
				OR fr_prodmfg.config_ind != "Y" THEN 
					CALL input_shoporddetl(fr_product.desc_text) 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD order_type_ind 
					END IF 
				ELSE 
					IF pv_header THEN 
						CALL input_shoporddetl(fr_product.desc_text) 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD order_type_ind 
						END IF 
					ELSE 
						CALL input_configs(pr_shopordhead.part_code, 
						pr_shopordhead.order_qty, "Y") 
						RETURNING pv_shopord_tot 

						CLOSE WINDOW w3_m133 
						LET pv_config = false 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD order_type_ind 
						END IF 

						IF pv_shopord_tot = 0 THEN 
							LET msgresp = kandoomsg("M", 9782, "") 
							# ERROR "No configurations were selected - Cannot
							#        create any shop orders"
							NEXT FIELD order_type_ind 
						END IF 

						INITIALIZE pa_parent TO NULL 

						FOR fv_cnt = 1 TO pv_shopord_tot 
							LET pa_parent[fv_cnt].* = pa_config[fv_cnt].* 
						END FOR 

						LET pr_sohead_master.* = pr_shopordhead.* 
						LET pv_header = true 

						CALL input_shopordhead() 

						IF pv_suffix_num > 0 THEN 
							EXIT program 
						END IF 

						IF pv_shopord_cnt != pv_shopord_tot THEN 
							LET fv_return = true 
						END IF 

						LET pv_header = false 
						EXIT INPUT 
					END IF 
				END IF 

				IF pv_cnt1 > 0 OR pv_phant_cnt != pv_cnt1 THEN 
					CALL redisplay_costs() 
				END IF 

				LET pv_cont = false 
				MESSAGE "" 
				{
				                OPEN WINDOW w5_cont AT 7,16 with 7 rows, 52 columns    -- albo  KD-762
				                    attributes (border, white)

				 }               IF pv_cnt1 = 0 OR pv_phant_cnt = pv_cnt1 THEN
				LET pv_text = kandooword("No so added", "M29") 
				DISPLAY " ", pv_text at 4,1 
			ELSE 
				LET pv_text = kandooword("so num", "M30") 
				LET pv_text1 = kandooword("Added Success", "M31") 

				DISPLAY " ", pv_text clipped, " ", 
				pr_shopordhead.shop_order_num, "-", 
				pr_shopordhead.suffix_num, " ", pv_text1 at 4,1 
			END IF 

			IF pv_header THEN 
				LET pv_shopord_cnt = pv_shopord_cnt + 1 
				LET fv_cnt = pv_shopord_tot - pv_shopord_cnt 
				LET pv_text1 = kandooword("more so", "M32") 
				LET pv_text = kandooword("configurable", "M33") 

				DISPLAY " ", fv_cnt, " ", pv_text1 clipped, " ", pv_text 
				at 5,1 

				LET pv_text = kandooword("product", "M34") 
				DISPLAY " ", pv_text, " ", pr_shopordhead.parent_part_code 
				at 6,1 
			END IF 

			CALL kandoomenu("M", 104) RETURNING pr_menunames.* 
			MENU pr_menunames.menu_text # add 

				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
					# Continue
					LET pv_cont = true 
					EXIT MENU 

				COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text # EXIT 
					EXIT MENU 

				COMMAND KEY (interrupt) 
					EXIT MENU 
			END MENU 

			--                CLOSE WINDOW w5_cont    -- albo  KD-762

		END INPUT 

		IF pv_header AND NOT pv_cont THEN 
			EXIT program 
		END IF 

		IF pv_header AND pv_cont AND pv_shopord_cnt = pv_shopord_tot THEN 
			LET pv_suffix_num = 0 
			RETURN 
		END IF 

		IF NOT pv_cont THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m128 

END FUNCTION 



FUNCTION lookup_products() 

	DEFINE fv_cnt SMALLINT, 
	fv_sales_order_num CHAR(10), 

	fa_prodmfg array[500] OF RECORD 
		part_code LIKE prodmfg.part_code, 
		desc_text LIKE product.desc_text, 
		part_type_ind LIKE prodmfg.part_type_ind, 
		part_type_text CHAR(12) 
	END RECORD 


	OPEN WINDOW w2_m130 with FORM "M130" 
	CALL  windecoration_m("M130") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1504, "") 	# MESSAGE "ESC TO SELECT - DEL TO Exit"

	LET fv_sales_order_num = pr_shopordhead.sales_order_num 
	DISPLAY fv_sales_order_num TO sales_order_num 

	DECLARE c_order CURSOR FOR 
	SELECT unique prodmfg.part_code, product.desc_text, part_type_ind 
	FROM product, prodmfg, orderdetl 
	WHERE prodmfg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND product.cmpy_code = prodmfg.cmpy_code 
	AND orderdetl.cmpy_code = prodmfg.cmpy_code 
	AND product.part_code = prodmfg.part_code 
	AND orderdetl.part_code = prodmfg.part_code 
	AND order_num = pr_shopordhead.sales_order_num 

	LET fv_cnt = 1 

	FOREACH c_order INTO fa_prodmfg[fv_cnt].* 

		CASE fa_prodmfg[fv_cnt].part_type_ind 
			WHEN "G" 
				LET pv_text = kandooword("Generic", "M25") 
			WHEN "M" 
				LET pv_text = kandooword("Manufactured", "M26") 
			WHEN "P" 
				LET pv_text = kandooword("Phantom", "M27") 
			WHEN "R" 
				LET pv_text = kandooword("Raw Material", "M28") 
		END CASE 

		LET fa_prodmfg[fv_cnt].part_type_text = pv_text 
		LET fv_cnt = fv_cnt + 1 

		IF fv_cnt > 500 THEN 
			LET msgresp = kandoomsg("M", 9567, "") 
			# ERROR "Only the first 500 products were selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(fv_cnt - 1) 

	DISPLAY ARRAY fa_prodmfg TO sr_prodmfg.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M31a","display-arr-prodmfg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 

	LET fv_cnt = arr_curr() 

	CLOSE WINDOW w2_m130 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	ELSE 
		RETURN fa_prodmfg[fv_cnt].part_code 
	END IF 

END FUNCTION 



FUNCTION display_costs(fr_product, fr_prodmfg) 

	DEFINE fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fv_unit_cost_amt LIKE bor.cost_amt, 
	fv_ext_cost_amt LIKE bor.cost_amt, 
	fv_ext_price_amt LIKE bor.price_amt, 
	fr_prodstatus RECORD LIKE prodstatus.* 


	SELECT * 
	INTO fr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_shopordhead.part_code 
	AND ware_code = fr_prodmfg.def_ware_code 

	CASE 
		WHEN pr_inparms.cost_ind matches "[WF]" 
			LET fv_unit_cost_amt = fr_prodstatus.wgted_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET fv_unit_cost_amt = fr_prodstatus.act_cost_amt 

		WHEN pr_inparms.cost_ind = "S" 
			LET fv_unit_cost_amt = fr_prodstatus.est_cost_amt 
	END CASE 

	LET pr_shopordhead.std_price_amt = fr_prodstatus.list_amt 

	CASE 
		WHEN pr_shopordhead.uom_code = fr_product.pur_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt * fr_product.pur_stk_con_qty 
			LET pr_shopordhead.std_price_amt = pr_shopordhead.std_price_amt * 
			fr_product.pur_stk_con_qty 

		WHEN pr_shopordhead.uom_code = fr_product.sell_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt / fr_product.stk_sel_con_qty 
			LET pr_shopordhead.std_price_amt = pr_shopordhead.std_price_amt / 
			fr_product.stk_sel_con_qty 

		WHEN pr_shopordhead.uom_code = fr_prodmfg.man_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt * fr_prodmfg.man_stk_con_qty 
			LET pr_shopordhead.std_price_amt = pr_shopordhead.std_price_amt * 
			fr_prodmfg.man_stk_con_qty 
	END CASE 

	LET fv_ext_cost_amt = fv_unit_cost_amt * pr_shopordhead.order_qty 
	LET fv_ext_price_amt = pr_shopordhead.std_price_amt * 
	pr_shopordhead.order_qty 

	DISPLAY fv_unit_cost_amt, 
	pr_shopordhead.std_price_amt, 
	fv_ext_cost_amt, 
	fv_ext_price_amt 
	TO unit_cost_amt, 
	unit_price_amt, 
	ext_cost_amt, 
	std_price_amt 

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
