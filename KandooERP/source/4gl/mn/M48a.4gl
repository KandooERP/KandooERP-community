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

	Source code beautified by beautify.pl on 2020-01-02 17:31:29	$Id: $
}


# Purpose - Shop Order Receipt - Query, menu, Ordinary receipt &
#                                configurable receipt functions
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M48.4gl" 


FUNCTION query_orders() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_scrn SMALLINT, 
	fv_part_type LIKE prodmfg.part_type_ind, 
	fv_config_ind LIKE prodmfg.config_ind, 

	fa_shopordhead array[1000] OF RECORD 
		part_code LIKE shopordhead.part_code, 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		end_date LIKE shopordhead.end_date, 
		order_qty LIKE shopordhead.order_qty, 
		receipted_qty LIKE shopordhead.receipted_qty 
	END RECORD 


	OPEN WINDOW w1_m173 with FORM "M173" 
	CALL  windecoration_m("M173") -- albo kd-762 

	WHILE true 

		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON part_code, shop_order_num, suffix_num, end_date, order_qty, receipted_qty 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT part_code, shop_order_num, suffix_num, ", 
		"end_date, order_qty, receipted_qty ", 
		"FROM shopordhead ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND status_ind = 'R' ", 
		"AND order_type_ind != 'F' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY shop_order_num, suffix_num" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_shopordhead CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_shopordhead INTO fa_shopordhead[fv_cnt].* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 1000 THEN 
				ERROR "Only the first 1000 shop orders were selected" 
				--- modif ericv  # attributes (red, reverse)
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			ERROR "The query returned no rows" 
			--- modif ericv init #attributes (red, reverse)
			CONTINUE WHILE 
		END IF 

		MESSAGE " RETURN TO Receipt Shop Order, F3 Fwd, F4 Bwd - DEL TO Exit" 
		attribute (yellow) 

		CALL set_count(fv_cnt - 1) 

		DISPLAY ARRAY fa_shopordhead TO sr_shopordhead.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M48a","display-arr-shopordhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

				SELECT * 
				INTO pr_shopordhead.* 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fa_shopordhead[fv_idx].shop_order_num 
				AND suffix_num = fa_shopordhead[fv_idx].suffix_num 

				CALL receipt_menu() 
				LET fa_shopordhead[fv_idx].receipted_qty = 
				pr_shopordhead.receipted_qty 
				DISPLAY fa_shopordhead[fv_idx].receipted_qty 
				TO sr_shopordhead[fv_scrn].receipted_qty 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m173 

END FUNCTION 



FUNCTION receipt_menu() 

	DEFINE fv_cnt SMALLINT, 
	fv_full_cnt SMALLINT, 
	fv_part_type LIKE prodmfg.part_type_ind 

	OPEN WINDOW w2_m174 with FORM "M174" 
	CALL  windecoration_m("M174") -- albo kd-762 

	SELECT desc_text 
	INTO pv_prod_desc 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_shopordhead.part_code 

	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.part_code, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.receipted_qty, 
	pr_shopordhead.rejected_qty, 
	pr_shopordhead.uom_code 

	DISPLAY pv_prod_desc TO product.desc_text 

	MENU "Shop Order Receipt" 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Receipt" "Receipt the shop ORDER product manufactured" 
			IF pr_shopordhead.status_ind = "C" THEN 
				LET msgresp = kandoomsg("M", 9807, "") 
				# ERROR "This shop ORDER IS closed"
				NEXT option "Exit" 
			ELSE 
				IF pr_shopordhead.order_qty = pr_shopordhead.receipted_qty + 
				pr_shopordhead.rejected_qty THEN 
					ERROR "This product has been fully receipted" 
					--- modif ericv init #attributes (red, reverse)
					NEXT option "Close" 
				ELSE 
					SELECT part_type_ind 
					INTO fv_part_type 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 

					IF fv_part_type = "G" THEN 
						SELECT unique generic_part_code 
						FROM configuration 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND generic_part_code = pr_shopordhead.part_code 

						IF status = notfound THEN 
							ERROR "This product must have configurations SET ", 
							"up before it can be receipted" 
							--- modif ericv init #attributes (red, reverse)
						ELSE 
							CALL receipt_configs() 

							DISPLAY BY NAME pr_shopordhead.receipted_qty, 
							pr_shopordhead.rejected_qty 
							NEXT option "Close" 
						END IF 
					ELSE 
						CALL receipt_order() 

						DISPLAY BY NAME pr_shopordhead.receipted_qty, 
						pr_shopordhead.rejected_qty 
						NEXT option "Close" 
					END IF 
				END IF 
			END IF 

		COMMAND "By-Product" "Receipt shop ORDER BY-products" 
			IF pr_shopordhead.status_ind = "C" THEN 
				ERROR "This shop ORDER IS closed" 
				--- modif ericv init #attributes (red, reverse)
				NEXT option "Exit" 
			ELSE 
				CALL receipt_byprods() RETURNING fv_cnt, fv_full_cnt 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					IF fv_cnt = 0 THEN 
						IF fv_full_cnt > 0 THEN 
							ERROR "The by-products on this shop ORDER have ", 
							"been fully receipted" 
							--- modif ericv init #attributes (red, reverse)
						ELSE 
							ERROR "This shop ORDER has no by-products" 
							--- modif ericv init #attributes (red, reverse)
						END IF 
					ELSE 
						NEXT option "Close" 
					END IF 
				END IF 
			END IF 

		COMMAND "Close" "Close the shop ORDER" 
			IF pr_shopordhead.status_ind = "C" THEN 
				ERROR "This shop ORDER IS already closed" 
				--- modif ericv init #attributes (red, reverse)
			ELSE 
				CALL close_order() 
			END IF 

			NEXT option "Exit" 

		COMMAND "Bill" "Generate a bill of resource FROM the shop ORDER" 
			CALL generate_bor() 
			NEXT option "Exit" 

		COMMAND "Exit" "Exit FROM this menu" 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW w2_m174 

END FUNCTION 



FUNCTION receipt_order() 

	DEFINE fv_ware_code LIKE warehouse.ware_code, 
	fv_ware_desc LIKE warehouse.desc_text, 
	fv_remain_qty LIKE shopordhead.order_qty, 
	fv_new_list LIKE prodstatus.list_amt, 
	fv_onord_qty LIKE prodstatus.onord_qty, 
	fv_failed SMALLINT, 
	fv_cost SMALLINT, 
	fv_price SMALLINT, 
	fv_price1 SMALLINT, 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodledg RECORD LIKE prodledg.*, 

	fr_soreceipt RECORD 
		receipt_qty LIKE shopordhead.receipted_qty, 
		reject_qty LIKE shopordhead.rejected_qty, 
		receipt_ware_code LIKE shopordhead.receipt_ware_code, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num 
	END RECORD 


	LET fv_cost = false 
	LET fv_price = false 
	LET fv_price1 = false 

	DECLARE c_shopdetl CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 
	AND type_ind matches "[WSU]" 

	FOREACH c_shopdetl INTO fr_shoporddetl.* 
		IF fr_shoporddetl.type_ind = "W" THEN 
			IF fr_shoporddetl.act_act_cost_amt IS NULL 
			OR fr_shoporddetl.act_act_cost_amt = 0 THEN 
				LET fv_cost = true 
			END IF 

			IF fr_shoporddetl.act_price_amt IS NULL 
			OR fr_shoporddetl.act_price_amt = 0 THEN 
				LET fv_price = true 
			END IF 
		ELSE 
			IF fr_shoporddetl.act_price_amt = 0 
			AND fr_shoporddetl.std_price_amt IS NULL THEN 
				LET fv_price1 = true 
			END IF 
		END IF 
	END FOREACH 

	IF fv_cost THEN 
		IF fv_price THEN 
			LET msgresp = kandoomsg("M", 7511, "") 
			# prompt "WARNING: Some work centres have no cost OR no price
			#         allocated TO them - Any key TO continue"
		ELSE 
			LET msgresp = kandoomsg("M", 7509, "") 
			# prompt "WARNING: Some work centres have no cost allocated TO them
			#         Any key TO continue"
		END IF 
	ELSE 
		IF fv_price THEN 
			LET msgresp = kandoomsg("M", 7510, "") 
			# prompt "WARNING: Some work centres have no price allocated TO them
			#         Any key TO continue"
		END IF 
	END IF 

	IF fv_price1 THEN 
		LET msgresp = kandoomsg("M", 7512, "") 
		# prompt "WARNING: Some cost OR setup lines have no price allocated TO
		#         them - Any key TO continue"
	END IF 

	LET fv_remain_qty = pr_shopordhead.order_qty - pr_shopordhead.receipted_qty 
	- pr_shopordhead.rejected_qty 
	LET fr_soreceipt.receipt_qty = fv_remain_qty 
	LET fr_soreceipt.reject_qty = 0 
	LET fr_soreceipt.receipt_ware_code = pr_shopordhead.receipt_ware_code 
	LET fr_soreceipt.tran_date = today 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING fr_soreceipt.year_num, fr_soreceipt.period_num 

	INPUT BY NAME fr_soreceipt.receipt_qty, 
	fr_soreceipt.reject_qty, 
	fr_soreceipt.receipt_ware_code, 
	fr_soreceipt.tran_date, 
	fr_soreceipt.year_num, 
	fr_soreceipt.period_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			SELECT desc_text 
			INTO fv_ware_desc 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = fr_soreceipt.receipt_ware_code 
			DISPLAY fv_ware_desc TO warehouse.desc_text 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			IF infield(receipt_ware_code) THEN 
				CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, pr_shopordhead.part_code) 
				RETURNING fv_ware_code 

				IF fv_ware_code IS NOT NULL THEN 
					LET fr_soreceipt.receipt_ware_code = fv_ware_code 
					DISPLAY BY NAME fr_soreceipt.receipt_ware_code 
				END IF 
			END IF 

		AFTER FIELD receipt_qty 
			IF fr_soreceipt.receipt_qty IS NULL THEN 
				ERROR "Quantity TO receipt must be entered" 
				--- modif ericv init #attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fr_soreceipt.receipt_qty < 0 THEN 
				ERROR "Quantity TO receipt cannot be less than 0" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fr_soreceipt.receipt_qty > fv_remain_qty THEN 
				ERROR "Qty TO receipt cannot be greater than the remaining qty", 
				" TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fr_soreceipt.reject_qty + fr_soreceipt.receipt_qty > 
			fv_remain_qty THEN 
				ERROR "Receipt + reject qtys cannot be greater than remaining ", 
				"qty TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

		AFTER FIELD reject_qty 
			IF fr_soreceipt.reject_qty IS NULL THEN 
				ERROR "Quantity TO reject must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fr_soreceipt.reject_qty < 0 THEN 
				ERROR "Quantity TO reject cannot be less than 0" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fr_soreceipt.reject_qty > fv_remain_qty THEN 
				ERROR "Qty TO reject cannot be greater than the remaining qty", 
				" TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fr_soreceipt.reject_qty + fr_soreceipt.receipt_qty > 
			fv_remain_qty THEN 
				ERROR "Receipt + reject qtys cannot be greater than remaining ", 
				"qty TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

		AFTER FIELD receipt_ware_code 
			IF fr_soreceipt.receipt_ware_code IS NULL THEN 
				ERROR "Warehouse code must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

			SELECT desc_text 
			INTO fv_ware_desc 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = fr_soreceipt.receipt_ware_code 

			IF status = notfound THEN 
				ERROR "This warehouse does NOT exist - Try window" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

			DISPLAY fv_ware_desc TO warehouse.desc_text 

			SELECT * 
			INTO fr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 
			AND ware_code = fr_soreceipt.receipt_ware_code 

			IF status = notfound THEN 
				ERROR "This warehouse IS NOT SET up FOR this product" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

			IF fr_prodstatus.stocked_flag = "N" THEN 
				ERROR "This product IS NOT stocked AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

			IF fr_prodstatus.status_ind = "2" THEN 
				ERROR "This product IS on hold AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

			IF fr_prodstatus.status_ind = "3" THEN 
				ERROR "This product IS marked FOR deletion AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_ware_code 
			END IF 

		AFTER FIELD tran_date 
			IF fr_soreceipt.tran_date IS NULL THEN 
				ERROR "Shop ORDER receipt date must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD tran_date 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, fr_soreceipt.tran_date) 
			RETURNING fr_soreceipt.year_num, fr_soreceipt.period_num 

			DISPLAY BY NAME fr_soreceipt.year_num, 
			fr_soreceipt.period_num 

		AFTER FIELD year_num 
			IF fr_soreceipt.year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF fr_soreceipt.period_num IS NULL THEN 
				ERROR "Period number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD period_num 
			END IF 

			CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_soreceipt.year_num, 
			fr_soreceipt.period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING fr_soreceipt.year_num, fr_soreceipt.period_num, 
			fv_failed 

			IF fv_failed THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_soreceipt.year_num, 
			fr_soreceipt.period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING fr_soreceipt.year_num, fr_soreceipt.period_num, 
			fv_failed 

			IF fv_failed THEN 
				NEXT FIELD year_num 
			END IF 

			GOTO bypass 

			LABEL recovery: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 

			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 

			BEGIN WORK 

				###
				### Transfer costs FOR shoporddetl cost & setup lines TO actual COLUMN
				### & UPDATE shopordhead totals
				###

				LET pr_shopordhead.receipted_qty = pr_shopordhead.receipted_qty + 
				fr_soreceipt.receipt_qty 
				LET pr_shopordhead.rejected_qty = pr_shopordhead.rejected_qty + 
				fr_soreceipt.reject_qty 

				IF fr_soreceipt.receipt_qty + fr_soreceipt.reject_qty = 
				fv_remain_qty THEN 
					LET pr_shopordhead.receipt_ware_code = 
					fr_soreceipt.receipt_ware_code 
				END IF 

				CALL update_shop_order() 

				###
				### Subtract receipt & reject qtys FROM prodstatus on ORDER qty
				###

				LET err_message = "M48 - SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 

				LET err_message = "M48 - SELECT FROM product failed" 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 

				LET fv_onord_qty = fr_soreceipt.receipt_qty + 
				fr_soreceipt.reject_qty 

				CALL uom_convert(pr_shopordhead.uom_code, fv_onord_qty, 
				fr_product.*, fr_prodmfg.*) 
				RETURNING fv_onord_qty 

				LET err_message = "M48 - Update of prodstatus failed" 

				UPDATE prodstatus 
				SET onord_qty = onord_qty - fv_onord_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 
				AND ware_code = pr_shopordhead.receipt_ware_code 

				###
				### Add receipt qty TO prodstatus on ORDER qty & UPDATE costs
				###

				IF fr_soreceipt.receipt_qty > 0 THEN 
					LET err_message = "M48 - SELECT FROM prodstatus failed" 

					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 
					AND ware_code = fr_soreceipt.receipt_ware_code 

					LET fr_soreceipt.receipt_qty = fr_soreceipt.receipt_qty * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_prodstatus.act_cost_amt =(pr_shopordhead.std_act_cost_amt 
					/ pr_shopordhead.order_qty) * fr_prodmfg.man_stk_con_qty 
					LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 
					LET fr_prodstatus.last_receipt_date = fr_soreceipt.tran_date 
					LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty + 
					fr_soreceipt.receipt_qty 

					IF fr_prodstatus.onhand_qty <= 0 THEN 
						LET fr_prodstatus.wgted_cost_amt = 
						fr_prodstatus.act_cost_amt 
					ELSE 
						LET fr_prodstatus.wgted_cost_amt = 
						((fr_prodstatus.wgted_cost_amt * 
						(fr_prodstatus.onhand_qty - fr_soreceipt.receipt_qty)) + 
						(fr_soreceipt.receipt_qty * fr_prodstatus.act_cost_amt)) 
						/ fr_prodstatus.onhand_qty 

						IF fr_prodstatus.wgted_cost_amt < 0 THEN 
							LET fr_prodstatus.wgted_cost_amt = 
							fr_prodstatus.act_cost_amt 
						END IF 
					END IF 

					LET fv_new_list = (pr_shopordhead.std_price_amt / 
					pr_shopordhead.order_qty) * fr_prodmfg.man_stk_con_qty 

					IF pr_mnparms.upd_list_flag = "Y" 
					AND fr_prodstatus.list_amt != fv_new_list THEN 

						OPEN WINDOW w3_m177 with FORM "M177" 
						CALL  windecoration_m("M177") -- albo kd-762 

						DISPLAY BY NAME pr_shopordhead.part_code, 
						fr_prodstatus.list_amt, 
						fv_new_list 


						LET msgresp = kandoomsg("M", 4503, "") 				# prompt "Do you want TO UPDATE the list price (Y/N)?"

						IF msgresp = "Y" THEN 
							LET fr_prodstatus.list_amt = fv_new_list 
						END IF 

						CLOSE WINDOW w3_m177 
					END IF 

					LET err_message = "M48 - Second UPDATE of prodstatus failed" 

					UPDATE prodstatus 
					SET * = fr_prodstatus.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 
					AND ware_code = fr_soreceipt.receipt_ware_code 

					###
					### Insert row INTO prodledg table
					###

					LET fr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET fr_prodledg.part_code = pr_shopordhead.part_code 
					LET fr_prodledg.ware_code = fr_soreceipt.receipt_ware_code 
					LET fr_prodledg.tran_date = fr_soreceipt.tran_date 
					LET fr_prodledg.seq_num = fr_prodstatus.seq_num 
					LET fr_prodledg.trantype_ind = "R" 
					LET fr_prodledg.year_num = fr_soreceipt.year_num 
					LET fr_prodledg.period_num = fr_soreceipt.period_num 
					LET fr_prodledg.source_text = "SO Recpt" 
					LET fr_prodledg.source_num = pr_shopordhead.shop_order_num 
					LET fr_prodledg.tran_qty = fr_soreceipt.receipt_qty 
					LET fr_prodledg.sales_amt = fr_prodstatus.list_amt 
					LET fr_prodledg.hist_flag = "N" 
					LET fr_prodledg.post_flag = "N" 
					LET fr_prodledg.jour_num = 0 
					LET fr_prodledg.desc_text = pr_shopordhead.suffix_num 
					LET fr_prodledg.acct_code = pr_mnparms.wip_acct_code 
					LET fr_prodledg.bal_amt = fr_prodstatus.onhand_qty 
					LET fr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET fr_prodledg.entry_date = today 

					CASE pr_inparms.cost_ind 
						WHEN "W" 
							LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
						WHEN "F" 
							LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
						WHEN "S" 
							LET fr_prodledg.cost_amt = fr_prodstatus.est_cost_amt 
						WHEN "L" 
							LET fr_prodledg.cost_amt = fr_prodstatus.act_cost_amt 
					END CASE 

					LET err_message = "M48 - Insert INTO prodledg failed" 

					INSERT INTO prodledg VALUES (fr_prodledg.*) 

					IF fr_product.serial_flag = "Y" THEN 
						CALL serial_in(glob_rec_kandoouser.cmpy_code, fr_product.vend_code, 
						fr_soreceipt.receipt_qty, 
						pr_shopordhead.part_code, 
						fr_prodledg.cost_amt, 0, 
						fr_soreceipt.tran_date, 
						fr_prodledg.desc_text, 
						fr_soreceipt.receipt_ware_code) 
					END IF 
				END IF 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	CLEAR receipt_qty, reject_qty, receipt_ware_code, tran_date, year_num, 
	period_num 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 



FUNCTION receipt_configs() 

	DEFINE fv_remain_qty LIKE shopordhead.receipted_qty, 
	fv_tran_date LIKE prodledg.tran_date, 
	fv_year_num LIKE prodledg.year_num, 
	fv_period_num LIKE prodledg.period_num, 
	fv_part_code LIKE configuration.specific_part_code, 
	fv_reject_qty LIKE shopordhead.rejected_qty, 
	fv_receipt_qty LIKE shopordhead.receipted_qty, 
	fv_receipt_tot LIKE shopordhead.receipted_qty, 
	fv_ware_code LIKE prodstatus.ware_code, 
	fv_status LIKE prodstatus.status_ind, 
	fv_stocked LIKE prodstatus.stocked_flag, 
	fv_new_list LIKE prodstatus.list_amt, 
	fv_onord_qty LIKE prodstatus.onord_qty, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_idx SMALLINT, 
	fv_failed SMALLINT, 

	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodledg RECORD LIKE prodledg.*, 

	fa_config array[500] OF RECORD 
		part_code LIKE prodstatus.part_code, 
		desc_text LIKE product.desc_text, 
		receipt_qty LIKE shopordhead.receipted_qty, 
		ware_code LIKE prodstatus.ware_code 
	END RECORD 

	OPEN WINDOW w4_m176 with FORM "M176" 
	CALL  windecoration_m("M176") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1505, "") # MESSAGE "ESC TO Accept - DEL TO Exit"

	LET fv_remain_qty = pr_shopordhead.order_qty - pr_shopordhead.receipted_qty 
	- pr_shopordhead.rejected_qty 

	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.part_code, 
	pr_shopordhead.uom_code, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.receipted_qty, 
	pr_shopordhead.rejected_qty 

	DISPLAY pv_prod_desc TO formonly.desc_text 
	DISPLAY fv_remain_qty TO remain_qty 
	--- modif ericv init # attributes (cyan, bold)

	LET fv_reject_qty = 0 
	LET fv_tran_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) RETURNING fv_year_num, fv_period_num 

	INPUT fv_reject_qty, fv_tran_date, fv_year_num, fv_period_num 
	WITHOUT DEFAULTS FROM reject_qty, tran_date, year_num, period_num 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD reject_qty 
			IF fv_reject_qty IS NULL THEN 
				ERROR "Quantity TO reject must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fv_reject_qty < 0 THEN 
				ERROR "Quantity TO reject cannot be less than 0" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fv_reject_qty > fv_remain_qty THEN 
				ERROR "Qty TO reject cannot be greater than the remaining qty", 
				" TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

		AFTER FIELD tran_date 
			IF fv_tran_date IS NULL THEN 
				ERROR "Shop ORDER receipt date must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD tran_date 
			END IF 

			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, fv_tran_date) 
			RETURNING fv_year_num, fv_period_num 

			DISPLAY fv_year_num, fv_period_num TO year_num, period_num 

		AFTER FIELD year_num 
			IF fv_year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF fv_period_num IS NULL THEN 
				ERROR "Period number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD period_num 
			END IF 

			CALL valid_period(glob_rec_kandoouser.cmpy_code, fv_year_num, fv_period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING fv_year_num, fv_period_num, fv_failed 

			IF fv_failed THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF fv_year_num IS NULL THEN 
				ERROR "Year number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD year_num 
			END IF 

			IF fv_period_num IS NULL THEN 
				ERROR "Period number must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD period_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW w4_m176 
		RETURN 
	END IF 

	LET fv_remain_qty = fv_remain_qty - fv_reject_qty 
	DISPLAY fv_remain_qty TO remain_qty 
	attribute (cyan, bold) 

	DECLARE c_config CURSOR FOR 
	SELECT specific_part_code 
	FROM configuration 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND generic_part_code = pr_shopordhead.part_code 

	LET fv_cnt = 0 

	FOREACH c_config INTO fv_part_code 
		LET fv_cnt = fv_cnt + 1 
		LET fa_config[fv_cnt].part_code = fv_part_code 
		LET fa_config[fv_cnt].receipt_qty = 0 

		SELECT desc_text 
		INTO fa_config[fv_cnt].desc_text 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fa_config[fv_cnt].part_code 

		SELECT def_ware_code 
		INTO fa_config[fv_cnt].ware_code 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fa_config[fv_cnt].part_code 

		IF fv_cnt = 500 THEN 
			ERROR "Only the first 500 configurations were selected" 
			--- modif ericv init # attributes (red, reverse)
			EXIT FOREACH 
		END IF 
	END FOREACH 

	OPTIONS 
	INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(fv_cnt) 

	MESSAGE " F3 Fwd, F4 Bwd, ESC Accept - DEL Exit" 
	attribute (yellow) 

	INPUT ARRAY fa_config WITHOUT DEFAULTS FROM sr_config.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 

		ON KEY (control-b) 
			IF infield(ware_code) THEN 
				CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, fa_config[fv_idx].part_code) 
				RETURNING fv_ware_code 

				IF fv_ware_code IS NOT NULL THEN 
					LET fa_config[fv_idx].ware_code = fv_ware_code 
					DISPLAY BY NAME fa_config[fv_idx].ware_code 
				END IF 
			END IF 

		AFTER FIELD receipt_qty 
			IF fa_config[fv_idx].receipt_qty IS NULL THEN 
				ERROR "Quantity TO receipt must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_config[fv_idx].receipt_qty < 0 THEN 
				ERROR "Quantity TO receipt cannot be less than 0" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_config[fv_idx].receipt_qty > fv_remain_qty THEN 
				ERROR "Qty TO receipt cannot be greater than the remaining", 
				" qty TO be receipted" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_config[fv_idx].receipt_qty > 0 THEN 
				SELECT part_type_ind 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_config[fv_idx].part_code 
				AND part_type_ind = "P" 

				IF status != notfound THEN 
					ERROR "This IS a phantom product AND cannot be receipted" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD receipt_qty 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND fv_idx = fv_cnt THEN 
				LET msgresp = kandoomsg("M", 9509, "") 
				# ERROR "There are no more rows in the direction you are..."
				NEXT FIELD receipt_qty 
			END IF 

		AFTER FIELD ware_code 
			IF fa_config[fv_idx].ware_code IS NULL THEN 
				ERROR "Warehouse code must be entered" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD ware_code 
			END IF 

			SELECT status_ind, stocked_flag 
			INTO fv_status, fv_stocked 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_config[fv_idx].part_code 
			AND ware_code = fa_config[fv_idx].ware_code 

			IF status = notfound THEN 
				ERROR "This warehouse IS NOT SET up FOR this product" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD ware_code 
			END IF 

			IF fa_config[fv_idx].receipt_qty > 0 
			AND fv_stocked = "N" THEN 
				ERROR "This product IS NOT stocked AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_config[fv_idx].receipt_qty > 0 
			AND fv_status = "2" THEN 
				ERROR "This product IS on hold AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_config[fv_idx].receipt_qty > 0 
			AND fv_status = "3" THEN 
				ERROR "This product IS marked FOR deletion AT this warehouse" 
				--- modif ericv init # attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF (fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("right")) 
			AND fv_idx = fv_cnt THEN 
				LET msgresp = kandoomsg("M", 9509, "") 
				# ERROR "There are no more rows in the direction you are going"
				NEXT FIELD ware_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			GOTO bypass1 

			LABEL recovery1: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 

			LABEL bypass1: 
			WHENEVER ERROR GOTO recovery1 

			BEGIN WORK 

				LET err_message = "M48 - SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shopordhead.part_code 

				LET fv_receipt_tot = 0 

				FOR fv_cnt1 = 1 TO fv_cnt 
					IF fa_config[fv_cnt1].receipt_qty = 0 THEN 
						CONTINUE FOR 
					END IF 

					LET fv_receipt_tot = fv_receipt_tot + 
					fa_config[fv_cnt1].receipt_qty 

					IF fv_receipt_tot > fv_remain_qty THEN 
						ERROR "The total receipted qty exceeds the amount ", 
						"available TO be receipted" 
						--- modif ericv init # attributes (red, reverse)
						ROLLBACK WORK 
						NEXT FIELD receipt_qty 
					END IF 

					###
					### Add receipt qty TO prodstatus on hand qty & UPDATE costs
					###

					LET err_message = "M48 - SELECT FROM prodstatus failed" 

					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_config[fv_cnt1].part_code 
					AND ware_code = fa_config[fv_cnt1].ware_code 

					IF fr_prodstatus.status_ind matches "[23]" 
					OR fr_prodstatus.stocked_flag = "N" THEN 
						ROLLBACK WORK 
						LET msgresp = kandoomsg("M",9202, fa_config[fv_cnt1].part_code) 
						# ERROR "Invalid warehouse FOR product "
						NEXT FIELD receipt_qty 
					END IF 

					LET fv_receipt_qty = fa_config[fv_cnt1].receipt_qty * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_prodstatus.act_cost_amt = 
					(pr_shopordhead.std_act_cost_amt / pr_shopordhead.order_qty) 
					* fr_prodmfg.man_stk_con_qty 
					LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 
					LET fr_prodstatus.last_receipt_date = fv_tran_date 
					LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty + 
					fv_receipt_qty 

					IF fr_prodstatus.onhand_qty <= 0 THEN 
						LET fr_prodstatus.wgted_cost_amt = fr_prodstatus.act_cost_amt 
					ELSE 
						LET fr_prodstatus.wgted_cost_amt = 
						((fr_prodstatus.wgted_cost_amt * 
						(fr_prodstatus.onhand_qty - fv_receipt_qty)) + 
						(fv_receipt_qty * fr_prodstatus.act_cost_amt)) 
						/ fr_prodstatus.onhand_qty 

						IF fr_prodstatus.wgted_cost_amt < 0 THEN 
							LET fr_prodstatus.wgted_cost_amt = 
							fr_prodstatus.act_cost_amt 
						END IF 
					END IF 

					LET fv_new_list = (pr_shopordhead.std_price_amt / 
					pr_shopordhead.order_qty) * fr_prodmfg.man_stk_con_qty 

					IF pr_mnparms.upd_list_flag = "Y" 
					AND fr_prodstatus.list_amt != fv_new_list THEN 

						OPEN WINDOW w3_m177 with FORM "M177" 
						CALL  windecoration_m("M177") -- albo kd-762 

						DISPLAY BY NAME fa_config[fv_cnt1].part_code, 
						fr_prodstatus.list_amt, 
						fv_new_list 


						LET msgresp = kandoomsg("M", 4503, "") 
						# prompt "Do you want TO UPDATE the list price (Y/N)?"

						IF msgresp = "Y" THEN 
							LET fr_prodstatus.list_amt = fv_new_list 
						END IF 

						CLOSE WINDOW w3_m177 
					END IF 

					LET err_message = "M48 - Update of prodstatus failed" 

					UPDATE prodstatus 
					SET * = fr_prodstatus.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_config[fv_cnt1].part_code 
					AND ware_code = fa_config[fv_cnt1].ware_code 

					###
					### Insert row INTO prodledg table
					###

					LET fr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET fr_prodledg.part_code = fa_config[fv_cnt1].part_code 
					LET fr_prodledg.ware_code = fa_config[fv_cnt1].ware_code 
					LET fr_prodledg.tran_date = fv_tran_date 
					LET fr_prodledg.seq_num = fr_prodstatus.seq_num 
					LET fr_prodledg.trantype_ind = "R" 
					LET fr_prodledg.year_num = fv_year_num 
					LET fr_prodledg.period_num = fv_period_num 
					LET fr_prodledg.source_text = "SO Recpt" 
					LET fr_prodledg.source_num = pr_shopordhead.shop_order_num 
					LET fr_prodledg.tran_qty = fv_receipt_qty 
					LET fr_prodledg.sales_amt = fr_prodstatus.list_amt 
					LET fr_prodledg.hist_flag = "N" 
					LET fr_prodledg.post_flag = "N" 
					LET fr_prodledg.jour_num = 0 
					LET fr_prodledg.desc_text = pr_shopordhead.suffix_num 
					LET fr_prodledg.acct_code = pr_mnparms.wip_acct_code 
					LET fr_prodledg.bal_amt = fr_prodstatus.onhand_qty 
					LET fr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET fr_prodledg.entry_date = today 

					CASE pr_inparms.cost_ind 
						WHEN "W" 
							LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
						WHEN "F" 
							LET fr_prodledg.cost_amt = fr_prodstatus.wgted_cost_amt 
						WHEN "S" 
							LET fr_prodledg.cost_amt = fr_prodstatus.est_cost_amt 
						WHEN "L" 
							LET fr_prodledg.cost_amt = fr_prodstatus.act_cost_amt 
					END CASE 

					LET err_message = "M48 - Insert INTO prodledg failed" 

					INSERT INTO prodledg VALUES (fr_prodledg.*) 

					IF fr_product.serial_flag = "Y" THEN 
						LET err_message = "M48 - SELECT FROM product failed" 

						SELECT * 
						INTO fr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fa_config[fv_cnt1].part_code 

						CALL serial_in(glob_rec_kandoouser.cmpy_code, fr_product.vend_code, fv_receipt_qty, 
						pr_shopordhead.part_code, 
						fr_prodledg.cost_amt, 0, fv_tran_date, 
						fr_prodledg.desc_text, 
						fa_config[fv_cnt1].ware_code) 
					END IF 
				END FOR 

				IF fv_receipt_tot > 0 OR fv_reject_qty > 0 THEN 

					###
					### Transfer costs FOR shoporddetl cost & setup lines TO actual COLUMN &
					### UPDATE shopordhead totals
					###

					LET pr_shopordhead.receipted_qty = pr_shopordhead.receipted_qty 
					+ fv_receipt_tot 
					LET pr_shopordhead.rejected_qty = pr_shopordhead.rejected_qty 
					+ fv_reject_qty 
					CALL update_shop_order() 

					###
					### Subtract receipt & reject qtys FROM prodstatus on ORDER qty
					###

					LET err_message = "M48 - Second SELECT FROM product failed" 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 

					LET fv_onord_qty = fv_receipt_tot + fv_reject_qty 

					CALL uom_convert(pr_shopordhead.uom_code, fv_onord_qty, 
					fr_product.*, fr_prodmfg.*) 
					RETURNING fv_onord_qty 

					LET err_message = "M48 - Second UPDATE of prodstatus failed" 

					UPDATE prodstatus 
					SET onord_qty = onord_qty - fv_onord_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_shopordhead.part_code 
					AND ware_code = pr_shopordhead.receipt_ware_code 
				END IF 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW w4_m176 

END FUNCTION 



FUNCTION update_shop_order() 

	DEFINE fv_finished_qty LIKE shopordhead.order_qty, 
	fv_cost_amt LIKE shoporddetl.act_act_cost_amt, 
	fv_price_amt LIKE shoporddetl.act_price_amt, 
	fv_setup_qty SMALLINT, 
	fr_shoporddetl RECORD LIKE shoporddetl.* 


	LET fv_finished_qty = pr_shopordhead.receipted_qty + 
	pr_shopordhead.rejected_qty 

	DECLARE c_shoporddetl1 CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 
	AND type_ind matches "[SU]" 

	FOREACH c_shoporddetl1 INTO fr_shoporddetl.* 
		CASE fr_shoporddetl.cost_type_ind 
			WHEN "V" 
				LET fv_cost_amt = fr_shoporddetl.std_est_cost_amt * 
				fv_finished_qty 

				IF fr_shoporddetl.std_price_amt IS NOT NULL THEN 
					LET fv_price_amt = fr_shoporddetl.std_price_amt * 
					fv_finished_qty 
				ELSE 
					LET fv_price_amt = 0 
				END IF 

			WHEN "Q" 
				LET fv_setup_qty = fv_finished_qty / fr_shoporddetl.var_amt 

				IF fv_finished_qty / fr_shoporddetl.var_amt > fv_setup_qty THEN 
					LET fv_setup_qty = fv_setup_qty + 1 
				END IF 

				LET fv_cost_amt = fr_shoporddetl.std_est_cost_amt * fv_setup_qty 

				IF fr_shoporddetl.std_price_amt IS NOT NULL THEN 
					LET fv_price_amt = fr_shoporddetl.std_price_amt *fv_setup_qty 
				ELSE 
					LET fv_price_amt = 0 
				END IF 

			OTHERWISE 
				LET fv_cost_amt = fr_shoporddetl.std_est_cost_amt 

				IF fr_shoporddetl.std_price_amt IS NOT NULL THEN 
					LET fv_price_amt = fr_shoporddetl.std_price_amt 
				ELSE 
					LET fv_price_amt = 0 
				END IF 
		END CASE 

		IF fv_cost_amt != fr_shoporddetl.act_act_cost_amt THEN 
			LET pr_shopordhead.act_est_cost_amt = 
			pr_shopordhead.act_est_cost_amt + (fv_cost_amt - 
			fr_shoporddetl.act_act_cost_amt) 
			LET pr_shopordhead.act_wgted_cost_amt = 
			pr_shopordhead.act_wgted_cost_amt + (fv_cost_amt - 
			fr_shoporddetl.act_act_cost_amt) 
			LET pr_shopordhead.act_act_cost_amt = 
			pr_shopordhead.act_act_cost_amt + (fv_cost_amt - 
			fr_shoporddetl.act_act_cost_amt) 
			LET fr_shoporddetl.act_act_cost_amt = fv_cost_amt 
		END IF 

		IF fv_price_amt != fr_shoporddetl.act_price_amt THEN 
			LET pr_shopordhead.act_price_amt = 
			pr_shopordhead.act_price_amt + (fv_price_amt - 
			fr_shoporddetl.act_price_amt) 
			LET fr_shoporddetl.act_price_amt = fv_price_amt 
		END IF 

		LET fr_shoporddetl.last_change_date = today 
		LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
		LET fr_shoporddetl.last_program_text = "M48" 
		LET err_message = "M48 - Update of shoporddetl failed" 

		UPDATE shoporddetl 
		SET * = fr_shoporddetl.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND shop_order_num = pr_shopordhead.shop_order_num 
		AND suffix_num = pr_shopordhead.suffix_num 
		AND sequence_num = fr_shoporddetl.sequence_num 
	END FOREACH 

	LET pr_shopordhead.last_change_date = today 
	LET pr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
	LET pr_shopordhead.last_program_text = "M48" 
	LET err_message = "M48 - Update of shopordhead failed" 

	UPDATE shopordhead 
	SET * = pr_shopordhead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 

END FUNCTION 
