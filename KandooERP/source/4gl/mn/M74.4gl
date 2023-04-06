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

	Source code beautified by beautify.pl on 2020-01-02 17:31:34	$Id: $
}


# Purpose - Shop Order Creation

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(15), 
	err_continue CHAR(1), 
	err_message CHAR(40), 
	pv_cnt SMALLINT, 
	pv_open SMALLINT, 
	pv_scost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_wcost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_lcost_tot LIKE shopordhead.std_est_cost_amt, 
	pv_price_tot LIKE shopordhead.std_price_amt, 

	pr_mnparms RECORD LIKE mnparms.*, 
	pr_shopordhead RECORD LIKE shopordhead.*, 

	pa_mps_orders array[1000] OF RECORD 
		toggle_text CHAR(1), 
		plan_code LIKE mpsdemand.plan_code, 
		part_code LIKE mpsdemand.part_code, 
		required_qty LIKE mpsdemand.required_qty, 
		start_date LIKE mpsdemand.start_date, 
		due_date LIKE mpsdemand.due_date 
	END RECORD, 

	pa_sales_orders array[1000] OF RECORD 
		toggle_text CHAR(1), 
		order_num LIKE recshordhead.order_num, 
		suffix_num LIKE recshordhead.suffix_num, 
		cust_code LIKE orderhead.cust_code, 
		order_date LIKE orderhead.order_date, 
		part_code LIKE recshordhead.part_code, 
		order_qty LIKE recshordhead.order_qty 
	END RECORD, 

	pa_config array[500] OF RECORD 
		part_code LIKE bor.part_code, 
		required_qty LIKE bor.required_qty 
	END RECORD, 

	pa_shoporddetl array[2000] OF RECORD LIKE shoporddetl.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M74") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	INTO pr_mnparms.* 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = 1 -- albo 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	OPTIONS 
	INSERT KEY f36 

	CREATE temp TABLE tempdelete 
	( 
	order_num INTEGER, 
	suffix_num SMALLINT, 
	plan_code CHAR(10), 
	part_code CHAR(15), 
	start_date DATE, 
	due_date DATE 
	) 
	with no LOG 

	CALL menu() 

END MAIN 



FUNCTION menu() 

	MENU "Shop Order Creation" 
		COMMAND "Sales Orders" "Recommended orders originate FROM sales orders" 
			DISPLAY "" at 1,1 
			DISPLAY "" at 2,1 
			CALL sales_orders() 

		COMMAND "MPS" "Recommended orders originate FROM MPS" 
			DISPLAY "" at 1,1 
			DISPLAY "" at 2,1 
			CALL mps_orders() 

		COMMAND "Exit" "Exit FROM this program" 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 
	END MENU 

END FUNCTION 



FUNCTION sales_orders() 

	DEFINE 
	fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_scrn SMALLINT 

	OPEN WINDOW wm192 with FORM "M192" 
	CALL  windecoration_m("M192") -- albo kd-762 

	WHILE true 
		INITIALIZE pa_sales_orders TO NULL 
		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON r.order_num, cust_code, order_date, part_code, order_qty 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT '', r.order_num, r.suffix_num, cust_code, ", 
		"order_date, r.part_code, r.order_qty ", 
		"FROM recshordhead r, orderhead o ", 
		"WHERE r.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND r.cmpy_code = o.cmpy_code ", 
		"AND r.order_num = o.order_num ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY r.order_num, r.part_code" 

		PREPARE sl_stmt FROM fv_query_text 
		DECLARE c_salesorders CURSOR FOR sl_stmt 

		LET fv_cnt = 1 

		FOREACH c_salesorders INTO pa_sales_orders[fv_cnt].* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 1000 THEN 
				#LET msgresp = kandoomsg("M", 9506, "")
				error"Only the first 1000 recommended orders have been selected" 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1540, "") 
		# MESSAGE "F2 Delete, F3 Fwd, F4 Bwd, F6 SELECT, F7 SELECT All - DEL TO

		LET fv_cnt = fv_cnt - 1 
		CALL set_count(fv_cnt) 

		INPUT ARRAY pa_sales_orders WITHOUT DEFAULTS FROM sr_salesorders.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

			AFTER FIELD order_qty 
				IF pa_sales_orders[fv_idx].order_qty IS NULL THEN 
					ERROR "Order quantity must be entered" 
					NEXT FIELD order_qty 
				END IF 

				IF pa_sales_orders[fv_idx].order_qty <= 0 THEN 
					ERROR "Order quantity must be greater than zero" 
					NEXT FIELD order_qty 
				END IF 

				IF pa_sales_orders[fv_idx + 1].part_code IS NULL 
				AND fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("left") 
				AND fgl_lastkey() != fgl_keyval("accept") THEN 
					LET msgresp = kandoomsg("M", 9530, "") 
					# ERROR "There are no more rows in the direction you are..."
					NEXT FIELD order_qty 
				END IF 

			BEFORE DELETE 
				LET fv_cnt = arr_count() 

				INSERT INTO tempdelete VALUES (pa_sales_orders[fv_idx].order_num, 
				pa_sales_orders[fv_idx].suffix_num, 
				"", "", "", "") 

			AFTER DELETE 
				INITIALIZE pa_sales_orders[fv_cnt].* TO NULL 

			ON KEY (f6) 
				IF pa_sales_orders[fv_idx].toggle_text = "*" THEN 
					LET pa_sales_orders[fv_idx].toggle_text = NULL 
				ELSE 
					SELECT unique suffix_num 
					FROM recshorddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_sales_orders[fv_idx].order_num 
					AND suffix_num = pa_sales_orders[fv_idx].suffix_num 

					IF status = notfound THEN 
						#                       ERROR "Cannot create shop ORDER - recommended ORDER ",
						#                             "has no detail lines"
						LET pa_sales_orders[fv_idx].toggle_text = "*" 
					ELSE 
						LET pa_sales_orders[fv_idx].toggle_text = "*" 
					END IF 
				END IF 

				DISPLAY pa_sales_orders[fv_idx].toggle_text 
				TO sr_salesorders[fv_scrn].toggle_text 
				DISPLAY pa_sales_orders[fv_idx].order_qty 
				TO sr_salesorders[fv_scrn].order_qty 

			ON KEY (f7) 
				FOR fv_cnt1 = 1 TO fv_cnt 
					SELECT unique suffix_num 
					FROM recshorddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = pa_sales_orders[fv_cnt1].order_num 
					AND suffix_num = pa_sales_orders[fv_cnt1].suffix_num 

					IF status != notfound THEN 
						LET pa_sales_orders[fv_cnt1].toggle_text = "*" 
					END IF 
				END FOR 

				FOR fv_cnt1 = 1 TO 14 
					DISPLAY pa_sales_orders[fv_idx-fv_scrn +fv_cnt1].toggle_text 
					TO sr_salesorders[fv_cnt1].toggle_text 
					DISPLAY pa_sales_orders[fv_idx - fv_scrn +fv_cnt1].order_qty 
					TO sr_salesorders[fv_cnt1].order_qty 
				END FOR 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			DELETE FROM tempdelete 
		ELSE 
			CALL salesord_shopord_create(fv_cnt) 
		END IF 
	END WHILE 

	CLOSE WINDOW wm192 

END FUNCTION 



FUNCTION mps_orders() 

	DEFINE 
	fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_scrn SMALLINT 


	OPEN WINDOW wm193 with FORM "M193" 
	CALL  windecoration_m("M193") -- albo kd-762 

	WHILE true 
		INITIALIZE pa_mps_orders TO NULL 
		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON plan_code, part_code, required_qty, start_date, due_date 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT '', plan_code, part_code, required_qty, ", 
		"start_date, due_date ", 
		"FROM mpsdemand ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND type_text = 'RO' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY plan_code, part_code" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_mps CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_mps INTO pa_mps_orders[fv_cnt].* 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 1000 THEN 
				#LET msgresp = kandoomsg("M", 9506, "")
				error"Only the first 1000 recommended orders have been selected" 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1540, "") 
		# MESSAGE "F2 Delete, F3 Fwd, F4 Bwd, F6 SELECT, F7 SELECT All - DEL TO

		LET fv_cnt = fv_cnt - 1 
		CALL set_count(fv_cnt) 

		INPUT ARRAY pa_mps_orders WITHOUT DEFAULTS FROM sr_mps.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

			AFTER FIELD required_qty 
				IF pa_mps_orders[fv_idx].required_qty IS NULL THEN 
					ERROR "Order quantity must be entered" 
					NEXT FIELD required_qty 
				END IF 

				IF pa_mps_orders[fv_idx].required_qty <= 0 THEN 
					ERROR "Order quantity must be greater than zero" 
					NEXT FIELD required_qty 
				END IF 

				IF pa_mps_orders[fv_idx + 1].part_code IS NULL 
				AND fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("left") 
				AND fgl_lastkey() != fgl_keyval("accept") THEN 
					LET msgresp = kandoomsg("M", 9530, "") 
					# ERROR "There are no more rows in the direction you are..."
					NEXT FIELD required_qty 
				END IF 

			BEFORE DELETE 
				LET fv_cnt = arr_count() 

				INSERT INTO tempdelete VALUES ("", "", 
				pa_mps_orders[fv_idx].plan_code, 
				pa_mps_orders[fv_idx].part_code, 
				pa_mps_orders[fv_idx].start_date, 
				pa_mps_orders[fv_idx].due_date) 

			AFTER DELETE 
				INITIALIZE pa_mps_orders[fv_cnt].* TO NULL 

			ON KEY (f6) 
				IF pa_mps_orders[fv_idx].toggle_text = "*" THEN 
					LET pa_mps_orders[fv_idx].toggle_text = NULL 
				ELSE 
					LET pa_mps_orders[fv_idx].toggle_text = "*" 
				END IF 

				DISPLAY pa_mps_orders[fv_idx].toggle_text 
				TO sr_mps[fv_scrn].toggle_text 
				DISPLAY pa_mps_orders[fv_idx].required_qty 
				TO sr_mps[fv_scrn].required_qty 

			ON KEY (f7) 
				FOR fv_cnt1 = 1 TO fv_cnt 
					LET pa_mps_orders[fv_cnt1].toggle_text = "*" 
				END FOR 

				FOR fv_cnt1 = 1 TO 14 
					DISPLAY pa_mps_orders[fv_idx - fv_scrn +fv_cnt1].toggle_text 
					TO sr_mps[fv_cnt1].toggle_text 
					DISPLAY pa_mps_orders[fv_idx -fv_scrn +fv_cnt1].required_qty 
					TO sr_mps[fv_idx].required_qty 
				END FOR 

			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF NOT mps_shopord_create(fv_cnt) THEN 
						LET msgresp = kandoomsg("M", 1540, "") 
						# MESSAGE "F2 Delete, F3 Fwd, F4 Bwd, F6 SELECT, F7 Sel
						NEXT FIELD required_qty 
					END IF 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			DELETE FROM tempdelete 
		END IF 
	END WHILE 

	CLOSE WINDOW wm193 

END FUNCTION 



FUNCTION salesord_shopord_create(fv_arr_size) 

	DEFINE 
	fv_add_qty LIKE prodstatus.onord_qty, 
	fv_end_date LIKE shopordhead.end_date, 
	fv_wc_cost LIKE shoporddetl.std_est_cost_amt, 
	fv_ord_num LIKE recshordhead.order_num, 
	fv_sfx_num LIKE recshordhead.suffix_num, 
	fv_arr_size SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_open SMALLINT, 

	fr_recshorddetl RECORD LIKE recshorddetl.*, 
	fr_recshordhead RECORD LIKE recshordhead.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_workcentre RECORD LIKE workcentre.* 


	LET msgresp = kandoomsg("M", 1525, "") 
	# MESSAGE "Please wait....."

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 

	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		FOR fv_cnt = 1 TO fv_arr_size 
			IF pa_sales_orders[fv_cnt].toggle_text != "*" 
			OR pa_sales_orders[fv_cnt].toggle_text IS NULL THEN 
				CONTINUE FOR 
			END IF 

			IF NOT fv_open THEN 
				{
				            OPEN WINDOW w1_M74 AT 10,10 with 4 rows, 64 columns      -- albo  KD-762
				                attributes (border, white, MESSAGE line first)
				}
				LET fv_open = true 
			END IF 

			INITIALIZE pa_shoporddetl, pr_shopordhead TO NULL 

			LET err_message = "M74 - SELECT FROM mnparms failed" 

			SELECT next_order_num 
			INTO pr_shopordhead.shop_order_num 
			FROM mnparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 

			LET err_message = "M74 - Update of mnparms failed" 

			UPDATE mnparms 
			SET next_order_num = pr_shopordhead.shop_order_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 

			DISPLAY "" at 2,2 
			DISPLAY "Creating shop ORDER ", pr_shopordhead.shop_order_num, 
			"-0 FOR product ", pa_sales_orders[fv_cnt].part_code clipped 
			at 2,2 
			DISPLAY "FROM sales ORDER ", pa_sales_orders[fv_cnt].order_num at 3,18 

			###
			### Load shoporddetl ARRAY & UPDATE prodstatus
			###

			LET err_message = "M74 - SELECT FROM recshordhead failed" 

			SELECT * 
			INTO fr_recshordhead.* 
			FROM recshordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_sales_orders[fv_cnt].order_num 
			AND suffix_num = pa_sales_orders[fv_cnt].suffix_num 

			LET pv_cnt = 0 
			LET pv_scost_tot = 0 
			LET pv_wcost_tot = 0 
			LET pv_lcost_tot = 0 
			LET pv_price_tot = 0 

			CALL check_date(pa_sales_orders[fv_cnt].order_date, -1) 
			RETURNING pr_shopordhead.end_date 
			LET pr_shopordhead.order_qty = pa_sales_orders[fv_cnt].order_qty 

			DECLARE c_rodetl CURSOR FOR 
			SELECT * 
			FROM recshorddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_sales_orders[fv_cnt].order_num 
			AND suffix_num = pa_sales_orders[fv_cnt].suffix_num 
			ORDER BY sequence_num 

			FOREACH c_rodetl INTO fr_recshorddetl.* 
				IF fr_recshorddetl.start_date > pr_shopordhead.end_date THEN 
					CONTINUE FOREACH 
				END IF 

				LET pv_cnt = pv_cnt + 1 
				LET pa_shoporddetl[pv_cnt].cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pa_shoporddetl[pv_cnt].shop_order_num = 
				pr_shopordhead.shop_order_num 
				LET pa_shoporddetl[pv_cnt].suffix_num = 0 
				LET pa_shoporddetl[pv_cnt].parent_part_code = 
				fr_recshorddetl.parent_part_code 
				LET pa_shoporddetl[pv_cnt].sequence_num = pv_cnt 
				LET pa_shoporddetl[pv_cnt].part_code = fr_recshorddetl.part_code 
				LET pa_shoporddetl[pv_cnt].type_ind = fr_recshorddetl.type_ind 
				LET pa_shoporddetl[pv_cnt].last_change_date = today 
				LET pa_shoporddetl[pv_cnt].last_user_text = glob_rec_kandoouser.sign_on_code 
				LET pa_shoporddetl[pv_cnt].last_program_text = "M74" 

				IF fr_recshorddetl.type_ind matches "[CB]" THEN 
					LET err_message = "M74 - SELECT FROM prodmfg failed" 

					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_recshorddetl.part_code 

					IF fr_prodmfg.part_type_ind = "P" THEN 
						CONTINUE FOREACH 
					END IF 
				END IF 

				LET pa_shoporddetl[pv_cnt].required_qty = 
				fr_recshorddetl.required_qty 
				LET pa_shoporddetl[pv_cnt].uom_code = fr_recshorddetl.uom_code 
				LET pa_shoporddetl[pv_cnt].desc_text = fr_recshorddetl.desc_text 
				LET pa_shoporddetl[pv_cnt].std_est_cost_amt = 
				fr_recshorddetl.cost_amt 
				LET pa_shoporddetl[pv_cnt].std_price_amt = fr_recshorddetl.price_amt 
				LET pa_shoporddetl[pv_cnt].cost_type_ind = 
				fr_recshorddetl.cost_type_ind 
				LET pa_shoporddetl[pv_cnt].user1_text = fr_recshorddetl.user1_text 
				LET pa_shoporddetl[pv_cnt].user2_text = fr_recshorddetl.user2_text 
				LET pa_shoporddetl[pv_cnt].user3_text = fr_recshorddetl.user3_text 
				LET pa_shoporddetl[pv_cnt].work_centre_code = 
				fr_recshorddetl.work_centre_code 
				LET pa_shoporddetl[pv_cnt].overlap_per = fr_recshorddetl.overlap_per 
				LET pa_shoporddetl[pv_cnt].oper_factor_amt = 
				fr_recshorddetl.oper_factor_amt 
				LET pa_shoporddetl[pv_cnt].var_amt = fr_recshorddetl.var_amt 

				CASE 
					WHEN fr_recshorddetl.type_ind = "S" 
						IF fr_recshorddetl.cost_type_ind = "F" THEN 
							LET pv_scost_tot = pv_scost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_wcost_tot = pv_wcost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_lcost_tot = pv_lcost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_price_tot = pv_price_tot + 
							fr_recshorddetl.price_amt 
						ELSE 
							LET pv_scost_tot = pv_scost_tot + 
							(fr_recshorddetl.cost_amt * pr_shopordhead.order_qty) 
							LET pv_wcost_tot = pv_wcost_tot + 
							(fr_recshorddetl.cost_amt * pr_shopordhead.order_qty) 
							LET pv_lcost_tot = pv_lcost_tot + 
							(fr_recshorddetl.cost_amt * pr_shopordhead.order_qty) 
							LET pv_price_tot = pv_price_tot + 
							(fr_recshorddetl.price_amt *pr_shopordhead.order_qty) 
						END IF 

						LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_price_amt = 0 

					WHEN fr_recshorddetl.type_ind = "W" 
						LET err_message = "M74 - SELECT FROM workcentre failed" 

						SELECT * 
						INTO fr_workcentre.* 
						FROM workcentre 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_recshorddetl.work_centre_code 

						LET err_message = "M74 - SELECT FROM workctrrate failed" 

						SELECT sum(rate_amt) 
						INTO fr_recshorddetl.cost_amt 
						FROM workctrrate 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_recshorddetl.work_centre_code 
						AND rate_ind = "V" 

						IF fr_recshorddetl.cost_amt IS NULL THEN 
							LET fr_recshorddetl.cost_amt = 0 
						END IF 

						SELECT sum(rate_amt) 
						INTO fr_recshorddetl.price_amt 
						FROM workctrrate 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND work_centre_code = fr_recshorddetl.work_centre_code 
						AND rate_ind = "F" 

						IF fr_recshorddetl.price_amt IS NULL THEN 
							LET fr_recshorddetl.price_amt = 0 
						END IF 

						LET pa_shoporddetl[pv_cnt].required_qty = 
						pa_sales_orders[fv_cnt].order_qty 
						* fr_recshorddetl.oper_factor_amt 

						IF fr_workcentre.processing_ind = "Q" THEN 
							LET fv_wc_cost = ((fr_recshorddetl.cost_amt / 
							fr_workcentre.time_qty) * 
							pa_shoporddetl[pv_cnt].required_qty) 
							+ fr_recshorddetl.price_amt 
						ELSE 
							LET fv_wc_cost = (fr_recshorddetl.cost_amt * 
							pa_shoporddetl[pv_cnt].required_qty) + 
							fr_recshorddetl.price_amt 
						END IF 

						LET pa_shoporddetl[pv_cnt].std_act_cost_amt = fv_wc_cost 
						LET pa_shoporddetl[pv_cnt].std_price_amt = fv_wc_cost * 
						(1 + (fr_workcentre.cost_markup_per / 100)) 
						LET pa_shoporddetl[pv_cnt].receipted_qty = 0 
						LET pa_shoporddetl[pv_cnt].rejected_qty = 0 
						LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_price_amt = 0 
						LET pv_scost_tot = pv_scost_tot + fv_wc_cost 
						LET pv_wcost_tot = pv_wcost_tot + fv_wc_cost 
						LET pv_lcost_tot = pv_lcost_tot + fv_wc_cost 
						LET pv_price_tot = pv_price_tot + 
						pa_shoporddetl[pv_cnt].std_price_amt 

					WHEN fr_recshorddetl.type_ind = "U" 
						IF fr_recshorddetl.cost_type_ind = "Q" THEN 
							LET fv_setup_qty = pr_shopordhead.order_qty / 
							fr_recshorddetl.var_amt 

							IF (pr_shopordhead.order_qty / fr_recshorddetl.var_amt) 
							> fv_setup_qty THEN 
								LET fv_setup_qty = fv_setup_qty + 1 
							END IF 

							LET pv_scost_tot = pv_scost_tot + 
							(fr_recshorddetl.cost_amt * fv_setup_qty) 
							LET pv_wcost_tot = pv_wcost_tot + 
							(fr_recshorddetl.cost_amt * fv_setup_qty) 
							LET pv_lcost_tot = pv_lcost_tot + 
							(fr_recshorddetl.cost_amt * fv_setup_qty) 
							LET pv_price_tot = pv_price_tot + 
							(fr_recshorddetl.price_amt * fv_setup_qty) 
						ELSE 
							LET pv_scost_tot = pv_scost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_wcost_tot = pv_wcost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_lcost_tot = pv_lcost_tot + 
							fr_recshorddetl.cost_amt 
							LET pv_price_tot = pv_price_tot + 
							fr_recshorddetl.price_amt 
						END IF 

						LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_price_amt = 0 

					WHEN fr_recshorddetl.type_ind matches "[CB]" 
						LET err_message = "M74 - SELECT FROM product failed" 

						SELECT * 
						INTO fr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fr_recshorddetl.part_code 

						LET pa_shoporddetl[pv_cnt].issue_ware_code = 
						fr_prodmfg.def_ware_code 

						CALL to_stk_uom_conv(pa_shoporddetl[pv_cnt].required_qty, 
						pa_shoporddetl[pv_cnt].uom_code, 
						fr_prodmfg.*, 
						fr_product.*) 
						RETURNING fv_add_qty 

						LET err_message = "M74 - Update of prodstatus failed" 

						IF fr_recshorddetl.type_ind = "C" THEN 
							CALL get_costs(pa_shoporddetl[pv_cnt].*, 
							fr_product.*, 
							fr_prodmfg.*) 
							RETURNING pa_shoporddetl[pv_cnt].* 

							LET pv_scost_tot = pv_scost_tot + 
							(pa_shoporddetl[pv_cnt].std_est_cost_amt * 
							pa_shoporddetl[pv_cnt].required_qty) 
							LET pv_wcost_tot = pv_wcost_tot + 
							(pa_shoporddetl[pv_cnt].std_wgted_cost_amt * 
							pa_shoporddetl[pv_cnt].required_qty) 
							LET pv_lcost_tot = pv_lcost_tot + 
							(pa_shoporddetl[pv_cnt].std_act_cost_amt * 
							pa_shoporddetl[pv_cnt].required_qty) 
							LET pv_price_tot = pv_price_tot + 
							(pa_shoporddetl[pv_cnt].std_price_amt * 
							pa_shoporddetl[pv_cnt].required_qty) 
							LET pa_shoporddetl[pv_cnt].issued_qty = 0 

							UPDATE prodstatus 
							SET reserved_qty = reserved_qty + fv_add_qty 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pa_shoporddetl[pv_cnt].part_code 
							AND ware_code =pa_shoporddetl[pv_cnt].issue_ware_code 
						ELSE 
							LET pa_shoporddetl[pv_cnt].receipted_qty = 0 
							LET pa_shoporddetl[pv_cnt].rejected_qty = 0 
							LET pa_shoporddetl[pv_cnt].std_est_cost_amt = 0 
							LET pa_shoporddetl[pv_cnt].std_wgted_cost_amt = 0 
							LET pa_shoporddetl[pv_cnt].std_act_cost_amt = 0 
							LET pa_shoporddetl[pv_cnt].std_price_amt = 0 

							UPDATE prodstatus 
							SET onord_qty = onord_qty - fv_add_qty 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = pa_shoporddetl[pv_cnt].part_code 
							AND ware_code =pa_shoporddetl[pv_cnt].issue_ware_code 
						END IF 

						LET pa_shoporddetl[pv_cnt].act_est_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_wgted_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt].act_price_amt = 0 
				END CASE 
			END FOREACH 

			###
			### Insert shopordhead RECORD & UPDATE on ORDER qty on prodstatus
			###

			LET err_message = "M74 - SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_sales_orders[fv_cnt].part_code 

			LET pr_shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_shopordhead.suffix_num = 0 
			LET pr_shopordhead.order_type_ind = "S" 
			LET pr_shopordhead.status_ind = "H" 
			LET pr_shopordhead.probability_per = fr_recshordhead.probability_per 
			LET pr_shopordhead.sales_order_num = pa_sales_orders[fv_cnt].order_num 
			LET pr_shopordhead.cust_code = pa_sales_orders[fv_cnt].cust_code 
			LET pr_shopordhead.start_date = today 
			LET pr_shopordhead.part_code = pa_sales_orders[fv_cnt].part_code 
			LET pr_shopordhead.uom_code = fr_prodmfg.man_uom_code 
			LET pr_shopordhead.receipted_qty = 0 
			LET pr_shopordhead.rejected_qty = 0 
			LET pr_shopordhead.std_est_cost_amt = pv_scost_tot 
			LET pr_shopordhead.std_wgted_cost_amt = pv_wcost_tot 
			LET pr_shopordhead.std_act_cost_amt = pv_lcost_tot 
			LET pr_shopordhead.std_price_amt = pv_price_tot 
			LET pr_shopordhead.act_est_cost_amt = 0 
			LET pr_shopordhead.act_wgted_cost_amt = 0 
			LET pr_shopordhead.act_act_cost_amt = 0 
			LET pr_shopordhead.act_price_amt = 0 
			LET pr_shopordhead.receipt_ware_code = fr_prodmfg.def_ware_code 
			LET pr_shopordhead.last_change_date = today 
			LET pr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET pr_shopordhead.last_program_text = "M74" 

			CALL calc_end_date(true) RETURNING fv_end_date 

			IF fv_end_date != pr_shopordhead.end_date THEN 
				CALL calc_start_date(fv_end_date) 
				CALL calc_end_date(false) 
			END IF 

			LET pr_shopordhead.job_length_num = pr_shopordhead.end_date - 
			pr_shopordhead.start_date + 1 

			LET err_message = "M74 - Insert INTO shopordhead failed" 

			INSERT INTO shopordhead VALUES (pr_shopordhead.*) 

			LET err_message = "M74 - SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 

			CALL to_stk_uom_conv(pr_shopordhead.order_qty, pr_shopordhead.uom_code, 
			fr_prodmfg.*, fr_product.*) 
			RETURNING fv_add_qty 

			LET err_message = "M74 - Update of prodstatus failed" 

			UPDATE prodstatus 
			SET onord_qty = onord_qty + fv_add_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			###
			### Insert detail lines INTO shoporddetl table
			###

			LET err_message = "M74 - Insert INTO shoporddetl failed" 

			FOR fv_cnt1 = 1 TO pv_cnt 
				INSERT INTO shoporddetl VALUES (pa_shoporddetl[fv_cnt1].*) 
			END FOR 

			###
			### Delete recommended ORDER FROM recshordhead & recshorddetl
			###

			LET err_message = "M74 - DELETE FROM recshorddetl failed" 

			DELETE FROM recshorddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_sales_orders[fv_cnt].order_num 
			AND suffix_num = pa_sales_orders[fv_cnt].suffix_num 

			LET err_message = "M74 - DELETE FROM recshordhead failed" 

			DELETE FROM recshordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pa_sales_orders[fv_cnt].order_num 
			AND suffix_num = pa_sales_orders[fv_cnt].suffix_num 
		END FOR 

		###
		### Delete recommended orders that were deleted FROM the SCREEN array
		###

		DECLARE c_delete CURSOR FOR 
		SELECT order_num, suffix_num 
		FROM tempdelete 

		FOREACH c_delete INTO fv_ord_num, fv_sfx_num 
			LET err_message = "M74 - DELETE FROM recshorddetl failed" 

			DELETE FROM recshorddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = fv_ord_num 
			AND suffix_num = fv_sfx_num 

			LET err_message = "M74 - DELETE FROM recshordhead failed" 

			DELETE FROM recshordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = fv_ord_num 
			AND suffix_num = fv_sfx_num 
		END FOREACH 

		DELETE FROM tempdelete 

	COMMIT WORK 
	WHENEVER ERROR stop 

	IF fv_open THEN 
		--        CLOSE WINDOW w1_M74     -- albo  KD-762
	END IF 

END FUNCTION 



FUNCTION get_costs(fr_shoporddetl, fr_product, fr_prodmfg) 

	DEFINE 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.* 


	LET err_message = "M74 - SELECT FROM prodstatus failed" 

	SELECT est_cost_amt, wgted_cost_amt, act_cost_amt, list_amt 
	INTO fr_shoporddetl.std_est_cost_amt, 
	fr_shoporddetl.std_wgted_cost_amt, 
	fr_shoporddetl.std_act_cost_amt, 
	fr_shoporddetl.std_price_amt 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_shoporddetl.part_code 
	AND ware_code = fr_shoporddetl.issue_ware_code 

	CASE 
		WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
			LET fr_shoporddetl.std_est_cost_amt = fr_product.pur_stk_con_qty * 
			fr_shoporddetl.std_est_cost_amt 
			LET fr_shoporddetl.std_wgted_cost_amt = fr_product.pur_stk_con_qty * 
			fr_shoporddetl.std_wgted_cost_amt 
			LET fr_shoporddetl.std_act_cost_amt = fr_product.pur_stk_con_qty * 
			fr_shoporddetl.std_act_cost_amt 
			LET fr_shoporddetl.std_price_amt = fr_shoporddetl.std_price_amt * 
			fr_product.pur_stk_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
			LET fr_shoporddetl.std_est_cost_amt = 
			fr_shoporddetl.std_est_cost_amt / fr_product.stk_sel_con_qty 
			LET fr_shoporddetl.std_wgted_cost_amt = 
			fr_shoporddetl.std_wgted_cost_amt / fr_product.stk_sel_con_qty 
			LET fr_shoporddetl.std_act_cost_amt = 
			fr_shoporddetl.std_act_cost_amt / fr_product.stk_sel_con_qty 
			LET fr_shoporddetl.std_price_amt = fr_shoporddetl.std_price_amt / 
			fr_product.stk_sel_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
			LET fr_shoporddetl.std_est_cost_amt = fr_prodmfg.man_stk_con_qty * 
			fr_shoporddetl.std_est_cost_amt 
			LET fr_shoporddetl.std_wgted_cost_amt = fr_prodmfg.man_stk_con_qty * 
			fr_shoporddetl.std_wgted_cost_amt 
			LET fr_shoporddetl.std_act_cost_amt = fr_prodmfg.man_stk_con_qty * 
			fr_shoporddetl.std_act_cost_amt 
			LET fr_shoporddetl.std_price_amt = fr_shoporddetl.std_price_amt * 
			fr_prodmfg.man_stk_con_qty 
	END CASE 

	RETURN fr_shoporddetl.* 

END FUNCTION 



FUNCTION to_stk_uom_conv(fv_qty, fv_uom_code, fr_prodmfg, fr_product) 

	DEFINE 
	fv_qty LIKE shopordhead.order_qty, 
	fv_uom_code LIKE shopordhead.uom_code, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.* 


	CASE fv_uom_code 
		WHEN fr_prodmfg.man_uom_code 
			LET fv_qty = fv_qty * fr_prodmfg.man_stk_con_qty 

		WHEN fr_product.sell_uom_code 
			LET fv_qty = fv_qty / fr_product.stk_sel_con_qty 

		WHEN fr_product.pur_uom_code 
			LET fv_qty = fv_qty * fr_product.pur_stk_con_qty 
	END CASE 

	RETURN fv_qty 

END FUNCTION 



FUNCTION calc_end_date(fv_start) 

	DEFINE 
	fv_latest_date LIKE shoporddetl.start_date, 
	fv_latest_time LIKE shoporddetl.start_time, 
	fv_so_start_time LIKE shoporddetl.start_time, 
	fv_wc_date LIKE shopordhead.start_date, 
	fv_wc_time LIKE workcentre.oper_start_time, 
	fv_day_length INTERVAL hour TO second, 
	fv_wc_dy_lgth INTERVAL hour TO second, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_start SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_days_qty SMALLINT, 
	fv_days1_qty SMALLINT, 
	fv_dy_hrs SMALLINT, 
	fv_wc_dy_hrs SMALLINT, 
	fv_dy_mins SMALLINT, 
	fv_wc_dy_mins SMALLINT, 
	fv_hrs_length FLOAT, 
	fv_wc_hr_lgth FLOAT, 
	fv_mins_length SMALLINT, 
	fv_wc_min_lgth SMALLINT, 
	fv_length_char CHAR(9), 
	fv_wc_lgth_chr CHAR(9), 
	fv_time_left INTERVAL hour TO second, 
	fv_time1_left INTERVAL hour TO second, 
	fv_time_qty LIKE shoporddetl.required_qty, 
	fv_time1_qty LIKE shoporddetl.required_qty, 

	fr_workcentre RECORD LIKE workcentre.* 


	CALL check_date(pr_shopordhead.start_date, 1) RETURNING fv_latest_date 

	LET fv_day_length = pr_mnparms.oper_end_time - pr_mnparms.oper_start_time 
	LET fv_length_char = fv_day_length 
	LET fv_dy_hrs = fv_length_char[2,3] 
	LET fv_dy_mins = fv_length_char[5,6] 
	LET fv_hrs_length = fv_dy_hrs + (fv_dy_mins / 60) 
	LET fv_mins_length = (fv_dy_hrs * 60) + fv_dy_mins 

	FOR fv_cnt = 1 TO pv_cnt 
		CASE 
			WHEN pa_shoporddetl[fv_cnt].type_ind = "U" 
				LET fv_time_qty = pa_shoporddetl[fv_cnt].required_qty 

				IF pa_shoporddetl[fv_cnt].cost_type_ind = "Q" THEN 
					LET fv_setup_qty = pr_shopordhead.order_qty / 
					pa_shoporddetl[fv_cnt].var_amt 

					IF fv_setup_qty < (pr_shopordhead.order_qty / 
					pa_shoporddetl[fv_cnt].var_amt) THEN 
						LET fv_setup_qty = fv_setup_qty + 1 
					END IF 

					LET fv_time_qty = fv_time_qty * fv_setup_qty 
				END IF 

				IF fv_latest_time IS NULL 
				OR fv_latest_time < pr_mnparms.oper_start_time THEN 
					LET fv_latest_time = pr_mnparms.oper_start_time 
				END IF 

				IF fv_latest_time >= pr_mnparms.oper_end_time THEN 
					LET fv_latest_time = pr_mnparms.oper_start_time 
					LET fv_latest_date = fv_latest_date + 1 
					CALL check_date(fv_latest_date, 1) RETURNING fv_latest_date 
				END IF 

				LET pa_shoporddetl[fv_cnt].start_date = fv_latest_date 
				LET pa_shoporddetl[fv_cnt].start_time = fv_latest_time 

				IF fv_so_start_time IS NULL THEN 
					LET fv_so_start_time = fv_latest_time 
				END IF 

				CASE pa_shoporddetl[fv_cnt].uom_code 
					WHEN "D" 
						LET fv_days_qty = fv_time_qty 
						LET fv_time_left = fv_day_length * (fv_time_qty - 
						fv_days_qty) 

					WHEN "H" 
						LET fv_days_qty = fv_time_qty / fv_hrs_length 
						LET fv_time_left = fv_day_length * ((fv_time_qty - 
						(fv_hrs_length * fv_days_qty)) / fv_hrs_length) 

					WHEN "M" 
						LET fv_days_qty = fv_time_qty / fv_mins_length 
						LET fv_time_left = fv_day_length * ((fv_time_qty - 
						(fv_mins_length * fv_days_qty)) / fv_mins_length) 

				END CASE 

				IF fv_time_left = INTERVAL (0:00) hour TO minute 
				AND fv_latest_time = pr_mnparms.oper_start_time THEN 
					LET fv_latest_time = pr_mnparms.oper_end_time 
					LET fv_days_qty = fv_days_qty - 1 
				END IF 

				FOR fv_cnt1 = 1 TO fv_days_qty 
					LET fv_latest_date = fv_latest_date + 1 
					CALL check_date(fv_latest_date, 1) 
					RETURNING fv_latest_date 
				END FOR 

				IF (pr_mnparms.oper_end_time - fv_latest_time) >= 
				fv_time_left THEN 
					LET fv_latest_time = fv_latest_time + fv_time_left 
				ELSE 
					LET fv_latest_date = fv_latest_date + 1 
					CALL check_date(fv_latest_date, 1) 
					RETURNING fv_latest_date 
					LET fv_latest_time = pr_mnparms.oper_start_time + 
					fv_time_left - (pr_mnparms.oper_end_time - 
					fv_latest_time) 
				END IF 

				LET pa_shoporddetl[fv_cnt].end_date = fv_latest_date 
				LET pa_shoporddetl[fv_cnt].end_time = fv_latest_time 

			WHEN pa_shoporddetl[fv_cnt].type_ind = "W" 
				SELECT * 
				INTO fr_workcentre.* 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = 
				pa_shoporddetl[fv_cnt].work_centre_code 

				LET fv_wc_dy_lgth = fr_workcentre.oper_end_time - 
				fr_workcentre.oper_start_time 
				LET fv_wc_lgth_chr = fv_wc_dy_lgth 
				LET fv_wc_dy_hrs = fv_wc_lgth_chr[2,3] 
				LET fv_wc_dy_mins = fv_wc_lgth_chr[5,6] 
				LET fv_wc_hr_lgth = fv_wc_dy_hrs + (fv_wc_dy_mins / 60) 
				LET fv_wc_min_lgth = (fv_wc_dy_hrs * 60) + fv_wc_dy_mins 

				IF fr_workcentre.processing_ind = "Q" THEN 
					LET fv_time_qty = (pr_shopordhead.order_qty * 
					pa_shoporddetl[fv_cnt].oper_factor_amt) / 
					fr_workcentre.time_qty 
				ELSE 
					LET fv_time_qty = pr_shopordhead.order_qty * 
					fr_workcentre.time_qty * 
					pa_shoporddetl[fv_cnt].oper_factor_amt 
				END IF 

				IF fv_latest_time IS NULL THEN 
					LET pa_shoporddetl[fv_cnt].start_date = fv_latest_date 
					LET pa_shoporddetl[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
				ELSE 
					IF fv_wc_date IS NULL THEN 
						LET pa_shoporddetl[fv_cnt].start_date = fv_latest_date 
						LET pa_shoporddetl[fv_cnt].start_time = fv_latest_time 
					ELSE 
						LET pa_shoporddetl[fv_cnt].start_date = fv_wc_date 
						LET pa_shoporddetl[fv_cnt].start_time = fv_wc_time 
					END IF 
				END IF 

				IF pa_shoporddetl[fv_cnt].start_time < 
				fr_workcentre.oper_start_time THEN 
					LET pa_shoporddetl[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
				END IF 

				IF pa_shoporddetl[fv_cnt].start_time >= 
				fr_workcentre.oper_end_time THEN 
					LET pa_shoporddetl[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
					LET pa_shoporddetl[fv_cnt].start_date = 
					pa_shoporddetl[fv_cnt].start_date + 1 
					CALL check_date(pa_shoporddetl[fv_cnt].start_date, 1) 
					RETURNING pa_shoporddetl[fv_cnt].start_date 
				END IF 

				IF fv_so_start_time IS NULL THEN 
					LET fv_so_start_time = pa_shoporddetl[fv_cnt].start_time 
				END IF 

				LET pa_shoporddetl[fv_cnt].end_date = 
				pa_shoporddetl[fv_cnt].start_date 
				LET fv_wc_date = pa_shoporddetl[fv_cnt].start_date 
				LET pa_shoporddetl[fv_cnt].end_time = 
				pa_shoporddetl[fv_cnt].start_time 
				LET fv_wc_time = pa_shoporddetl[fv_cnt].start_time 

				CASE fr_workcentre.time_unit_ind 
					WHEN "D" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_shoporddetl[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty 
						LET fv_days1_qty = fv_time1_qty 
						LET fv_time_left = fv_wc_dy_lgth * (fv_time_qty - 
						fv_days_qty) 
						LET fv_time1_left = fv_wc_dy_lgth * (fv_time1_qty - 
						fv_days_qty) 

					WHEN "H" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_shoporddetl[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty / fv_wc_hr_lgth 
						LET fv_days1_qty = fv_time1_qty / fv_wc_hr_lgth 
						LET fv_time_left = fv_wc_dy_lgth * ((fv_time_qty - 
						(fv_wc_hr_lgth * fv_days_qty)) / fv_wc_hr_lgth) 
						LET fv_time1_left = fv_wc_dy_lgth * ((fv_time1_qty - 
						(fv_wc_hr_lgth * fv_days1_qty)) / fv_wc_hr_lgth) 

					WHEN "M" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_shoporddetl[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty / fv_wc_min_lgth 
						LET fv_days1_qty = fv_time1_qty / fv_wc_min_lgth 
						LET fv_time_left = fv_wc_dy_lgth * ((fv_time_qty - 
						(fv_wc_min_lgth * fv_days_qty)) / fv_wc_min_lgth) 
						LET fv_time1_left = fv_wc_dy_lgth * ((fv_time1_qty - 
						(fv_wc_min_lgth * fv_days1_qty)) / fv_wc_min_lgth) 

				END CASE 

				IF fv_time_left = INTERVAL (0:00) hour TO minute 
				AND pa_shoporddetl[fv_cnt].start_time = 
				fr_workcentre.oper_start_time THEN 
					LET pa_shoporddetl[fv_cnt].end_time = 
					fr_workcentre.oper_end_time 
					LET fv_days_qty = fv_days_qty - 1 
				END IF 

				IF fv_time1_left = INTERVAL (0:00) hour TO minute 
				AND fv_wc_time = fr_workcentre.oper_start_time THEN 
					LET fv_wc_time = fr_workcentre.oper_end_time 
					LET fv_days1_qty = fv_days1_qty - 1 
				END IF 

				FOR fv_cnt1 = 1 TO fv_days_qty 
					LET pa_shoporddetl[fv_cnt].end_date = 
					pa_shoporddetl[fv_cnt].end_date + 1 
					CALL check_date(pa_shoporddetl[fv_cnt].end_date, 1) 
					RETURNING pa_shoporddetl[fv_cnt].end_date 
				END FOR 

				FOR fv_cnt1 = 1 TO fv_days1_qty 
					LET fv_wc_date = fv_wc_date + 1 
					CALL check_date(fv_wc_date, 1) RETURNING fv_wc_date 
				END FOR 

				IF (fr_workcentre.oper_end_time - 
				pa_shoporddetl[fv_cnt].end_time) >= fv_time_left THEN 
					LET pa_shoporddetl[fv_cnt].end_time = 
					pa_shoporddetl[fv_cnt].end_time + fv_time_left 
				ELSE 
					LET pa_shoporddetl[fv_cnt].end_date = 
					pa_shoporddetl[fv_cnt].end_date + 1 
					CALL check_date(pa_shoporddetl[fv_cnt].end_date, 1) 
					RETURNING pa_shoporddetl[fv_cnt].end_date 
					LET pa_shoporddetl[fv_cnt].end_time = 
					fr_workcentre.oper_start_time + fv_time_left - 
					(fr_workcentre.oper_end_time - 
					pa_shoporddetl[fv_cnt].end_time) 
				END IF 

				IF (fr_workcentre.oper_end_time - fv_wc_time) >= 
				fv_time1_left THEN 
					LET fv_wc_time = fv_wc_time + fv_time1_left 
				ELSE 
					LET fv_wc_date = fv_wc_date + 1 
					CALL check_date(fv_wc_date, 1) RETURNING fv_wc_date 
					LET fv_wc_time = fr_workcentre.oper_start_time + 
					fv_time1_left - (fr_workcentre.oper_end_time - 
					fv_wc_time) 
				END IF 

				IF fv_latest_time IS NULL THEN 
					LET fv_latest_date = pa_shoporddetl[fv_cnt].end_date 
					LET fv_latest_time = pa_shoporddetl[fv_cnt].end_time 
				ELSE 
					CASE 
						WHEN pa_shoporddetl[fv_cnt].end_date > fv_latest_date 
							LET fv_latest_date = pa_shoporddetl[fv_cnt].end_date 
							LET fv_latest_time = pa_shoporddetl[fv_cnt].end_time 

						WHEN pa_shoporddetl[fv_cnt].end_date = fv_latest_date 
							IF pa_shoporddetl[fv_cnt].end_time > fv_latest_time 
							THEN 
								LET fv_latest_time = 
								pa_shoporddetl[fv_cnt].end_time 
							END IF 
					END CASE 
				END IF 

				IF pa_shoporddetl[fv_cnt].overlap_per = 100 THEN 
					LET fv_wc_date = NULL 
				END IF 

			WHEN pa_shoporddetl[fv_cnt].type_ind matches "[CB]" 
				IF pa_shoporddetl[fv_cnt].required_qty IS NOT NULL THEN 
					LET pa_shoporddetl[fv_cnt].start_date = 
					pr_shopordhead.start_date 

					IF fv_so_start_time IS NULL THEN 
						LET pa_shoporddetl[fv_cnt].start_time = 
						pr_mnparms.oper_start_time 
					ELSE 
						LET pa_shoporddetl[fv_cnt].start_time = fv_so_start_time 
					END IF 
				END IF 

		END CASE 
	END FOR 

	IF pr_shopordhead.end_date IS NULL THEN 
		LET pr_shopordhead.end_date = fv_latest_date 
	END IF 

	IF fv_start THEN 
		RETURN fv_latest_date 
	END IF 

END FUNCTION 



FUNCTION calc_start_date(fv_end_date) 

	DEFINE 
	fv_end_date LIKE shopordhead.end_date, 
	fv_step SMALLINT 


	IF fv_end_date < pr_shopordhead.end_date THEN 
		LET fv_step = 1 
	ELSE 
		LET fv_step = -1 
	END IF 

	WHILE fv_end_date != pr_shopordhead.end_date 
		LET fv_end_date = fv_end_date + fv_step 

		IF fv_end_date != pr_shopordhead.end_date THEN 
			CALL check_date(fv_end_date, fv_step) RETURNING fv_end_date 
		END IF 

		LET pr_shopordhead.start_date = pr_shopordhead.start_date + fv_step 
		CALL check_date(pr_shopordhead.start_date, fv_step) 
		RETURNING pr_shopordhead.start_date 
	END WHILE 

END FUNCTION 



FUNCTION check_date(fv_latest_date, fv_step) 

	DEFINE 
	fv_latest_date DATE, 
	fv_step SMALLINT, 
	#        fv_avail_ind   LIKE calendar.available_ind
	fv_avail_ind LIKE calendar.available_flag 


	WHILE true 
		SELECT available_ind 
		INTO fv_avail_ind 
		FROM calendar 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND calendar_date = fv_latest_date 

		IF status = notfound OR fv_avail_ind = "Y" THEN 
			RETURN fv_latest_date 
		END IF 

		LET fv_latest_date = fv_latest_date + fv_step 
	END WHILE 

END FUNCTION 



FUNCTION mps_shopord_create(fv_arr_size) 

	DEFINE 
	fv_add_qty LIKE prodstatus.onord_qty, 
	fv_plan_code LIKE mpsdemand.plan_code, 
	fv_part_code LIKE mpsdemand.part_code, 
	fv_start_date LIKE mpsdemand.start_date, 
	fv_due_date LIKE mpsdemand.due_date, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_open SMALLINT, 

	fr_bor RECORD LIKE bor.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.* 


	LET msgresp = kandoomsg("M", 1525, "") 
	# MESSAGE "Please wait....."

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 

	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		FOR fv_cnt = 1 TO fv_arr_size 
			IF pa_mps_orders[fv_cnt].toggle_text != "*" 
			OR pa_mps_orders[fv_cnt].toggle_text IS NULL THEN 
				CONTINUE FOR 
			END IF 

			IF NOT fv_open THEN 
				{
				            OPEN WINDOW w2_M74 AT 10,10 with 4 rows, 64 columns     -- albo  KD-762
				                attributes (border, white, MESSAGE line first)
				}
				LET fv_open = true 
			END IF 

			INITIALIZE pa_shoporddetl, pr_shopordhead TO NULL 

			LET err_message = "M74 - SELECT FROM mnparms failed" 

			SELECT next_order_num 
			INTO pr_shopordhead.shop_order_num 
			FROM mnparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 

			LET err_message = "M74 - Update of mnparms failed" 

			UPDATE mnparms 
			SET next_order_num = pr_shopordhead.shop_order_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 

			DISPLAY "" at 2,2 
			DISPLAY "Creating shop ORDER ", pr_shopordhead.shop_order_num, 
			"-0 FOR product ", pa_mps_orders[fv_cnt].part_code clipped 
			at 2,2 
			DISPLAY "FROM plan number ", pa_mps_orders[fv_cnt].plan_code at 3,18 

			###
			### Load shoporddetl ARRAY & UPDATE prodstatus
			###

			LET pv_cnt = 0 
			LET pv_scost_tot = 0 
			LET pv_wcost_tot = 0 
			LET pv_lcost_tot = 0 
			LET pv_price_tot = 0 
			LET pr_shopordhead.start_date = pa_mps_orders[fv_cnt].start_date 
			LET pr_shopordhead.end_date = pa_mps_orders[fv_cnt].due_date 
			LET pr_shopordhead.order_qty = pa_mps_orders[fv_cnt].required_qty 

			DECLARE c_bor CURSOR FOR 
			SELECT * 
			FROM bor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parent_part_code = pa_mps_orders[fv_cnt].part_code 

			FOREACH c_bor INTO fr_bor.* 
				IF fr_bor.start_date > pr_shopordhead.end_date 
				OR fr_bor.end_date < pr_shopordhead.start_date THEN 
					CONTINUE FOREACH 
				END IF 

				IF fr_bor.type_ind matches "[CB]" THEN 
					LET fr_bor.required_qty = fr_bor.required_qty * 
					pa_mps_orders[fv_cnt].required_qty 
				END IF 

				IF fr_bor.type_ind = "C" THEN 
					LET err_message = "M74 - SELECT FROM product failed" 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_bor.part_code 

					LET err_message = "M74 - SELECT FROM prodmfg failed" 

					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_bor.part_code 

					IF fr_prodmfg.part_type_ind matches "[GP]" THEN 
						IF fr_prodmfg.part_type_ind = "P" THEN 
							IF fr_bor.uom_code != fr_prodmfg.man_uom_code THEN 
								CALL to_mfg_uom_conv(fr_bor.required_qty, 
								fr_bor.uom_code, 
								fr_prodmfg.*, 
								fr_product.*) 
								RETURNING fr_bor.required_qty 
							END IF 

							CALL load_detl_array(fr_bor.*, fr_prodmfg.part_type_ind) 
						END IF 

						CALL expand(fr_bor.part_code, fr_prodmfg.part_type_ind, 
						fr_bor.required_qty, fr_bor.parent_part_code) 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							CLOSE WINDOW wm194 
							LET pv_open = false 
							--                        CLOSE WINDOW w2_M74    -- albo  KD-762
							ERROR "Shop ORDER create interrupted - Work rolled back" 
							ROLLBACK WORK 
							RETURN false 
						END IF 

						IF pv_cnt = 2000 THEN 
							EXIT FOREACH 
						END IF 

						CONTINUE FOREACH 
					END IF 
				ELSE 
					LET fr_prodmfg.part_type_ind = NULL 
				END IF 

				CALL load_detl_array(fr_bor.*, fr_prodmfg.part_type_ind) 

				IF pv_cnt = 2000 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			IF pv_open THEN 
				LET pv_open = false 
				CLOSE WINDOW wm194 
			END IF 

			IF pv_cnt = 0 THEN 
				ERROR "Product ", pa_mps_orders[fv_cnt].part_code clipped, 
				" has no BOR - Work rolled back" 
				CLOSE WINDOW w2_m74 
				ROLLBACK WORK 
				RETURN false 
			END IF 

			###
			### Insert shopordhead RECORD & UPDATE on ORDER qty on prodstatus
			###

			LET err_message = "M74 - SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_mps_orders[fv_cnt].part_code 

			LET pr_shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_shopordhead.suffix_num = 0 
			LET pr_shopordhead.order_type_ind = "O" 
			LET pr_shopordhead.status_ind = "H" 
			LET pr_shopordhead.part_code = pa_mps_orders[fv_cnt].part_code 
			LET pr_shopordhead.uom_code = fr_prodmfg.man_uom_code 
			LET pr_shopordhead.receipted_qty = 0 
			LET pr_shopordhead.rejected_qty = 0 
			LET pr_shopordhead.std_est_cost_amt = pv_scost_tot 
			LET pr_shopordhead.std_wgted_cost_amt = pv_wcost_tot 
			LET pr_shopordhead.std_act_cost_amt = pv_lcost_tot 
			LET pr_shopordhead.std_price_amt = pv_price_tot 
			LET pr_shopordhead.act_est_cost_amt = 0 
			LET pr_shopordhead.act_wgted_cost_amt = 0 
			LET pr_shopordhead.act_act_cost_amt = 0 
			LET pr_shopordhead.act_price_amt = 0 
			LET pr_shopordhead.receipt_ware_code = fr_prodmfg.def_ware_code 
			LET pr_shopordhead.last_change_date = today 
			LET pr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET pr_shopordhead.last_program_text = "M74" 

			CALL calc_end_date(false) 

			LET pr_shopordhead.job_length_num = pr_shopordhead.end_date - 
			pr_shopordhead.start_date + 1 

			LET err_message = "M74 - Insert INTO shopordhead failed" 

			INSERT INTO shopordhead VALUES (pr_shopordhead.*) 

			LET err_message = "M74 - SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 

			CALL to_stk_uom_conv(pr_shopordhead.order_qty, pr_shopordhead.uom_code, 
			fr_prodmfg.*, fr_product.*) 
			RETURNING fv_add_qty 

			LET err_message = "M74 - Update of prodstatus failed" 

			UPDATE prodstatus 
			SET onord_qty = onord_qty + fv_add_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shopordhead.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			###
			### Insert detail lines INTO shoporddetl table
			###

			LET err_message = "M74 - Insert INTO shoporddetl failed" 

			FOR fv_cnt1 = 1 TO pv_cnt 
				INSERT INTO shoporddetl VALUES (pa_shoporddetl[fv_cnt1].*) 
			END FOR 

			###
			### Delete recommended ORDER FROM mpsdemand
			###

			LET err_message = "M74 - DELETE FROM mpsdemand failed" 

			DELETE FROM mpsdemand 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = pa_mps_orders[fv_cnt].plan_code 
			AND part_code = pa_mps_orders[fv_cnt].part_code 
			AND start_date = pa_mps_orders[fv_cnt].start_date 
			AND due_date = pa_mps_orders[fv_cnt].due_date 
			AND type_text = "RO" 
		END FOR 

		###
		### Delete mpsdemand rows that were deleted FROM the SCREEN array
		###

		DECLARE c_delete1 CURSOR FOR 
		SELECT plan_code, part_code, start_date, due_date 
		FROM tempdelete 

		FOREACH c_delete1 INTO fv_plan_code, fv_part_code, fv_start_date,fv_due_date 
			LET err_message = "M74 - DELETE FROM mpsdemand failed" 

			DELETE FROM mpsdemand 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = fv_plan_code 
			AND part_code = fv_part_code 
			AND start_date = fv_start_date 
			AND due_date = fv_due_date 
			AND type_text = "RO" 
		END FOREACH 

		DELETE FROM tempdelete 

	COMMIT WORK 
	WHENEVER ERROR stop 

	IF fv_open THEN 
		CLOSE WINDOW w2_m74 
	END IF 

	RETURN true 

END FUNCTION 



FUNCTION load_detl_array(fr_bor, fv_part_type_ind) 

	DEFINE 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_wc_cost LIKE shoporddetl.std_est_cost_amt, 
	fv_add_qty LIKE prodstatus.onord_qty, 
	fv_setup_qty SMALLINT, 

	fr_bor RECORD LIKE bor.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_workcentre RECORD LIKE workcentre.* 


	LET pv_cnt = pv_cnt + 1 
	LET pa_shoporddetl[pv_cnt].cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pa_shoporddetl[pv_cnt].shop_order_num = pr_shopordhead.shop_order_num 
	LET pa_shoporddetl[pv_cnt].suffix_num = 0 
	LET pa_shoporddetl[pv_cnt].parent_part_code = fr_bor.parent_part_code 
	LET pa_shoporddetl[pv_cnt].sequence_num = pv_cnt 
	LET pa_shoporddetl[pv_cnt].part_code = fr_bor.part_code 
	LET pa_shoporddetl[pv_cnt].type_ind = fr_bor.type_ind 
	LET pa_shoporddetl[pv_cnt].last_change_date = today 
	LET pa_shoporddetl[pv_cnt].last_user_text = glob_rec_kandoouser.sign_on_code 
	LET pa_shoporddetl[pv_cnt].last_program_text = "M74" 

	IF fv_part_type_ind = "P" THEN 
		RETURN 
	END IF 

	LET pa_shoporddetl[pv_cnt].required_qty = fr_bor.required_qty 
	LET pa_shoporddetl[pv_cnt].uom_code = fr_bor.uom_code 
	LET pa_shoporddetl[pv_cnt].desc_text = fr_bor.desc_text 
	LET pa_shoporddetl[pv_cnt].std_est_cost_amt = fr_bor.cost_amt 
	LET pa_shoporddetl[pv_cnt].std_price_amt = fr_bor.price_amt 
	LET pa_shoporddetl[pv_cnt].cost_type_ind = fr_bor.cost_type_ind 
	LET pa_shoporddetl[pv_cnt].user1_text = fr_bor.user1_text 
	LET pa_shoporddetl[pv_cnt].user2_text = fr_bor.user2_text 
	LET pa_shoporddetl[pv_cnt].user3_text = fr_bor.user3_text 
	LET pa_shoporddetl[pv_cnt].work_centre_code = fr_bor.work_centre_code 
	LET pa_shoporddetl[pv_cnt].overlap_per = fr_bor.overlap_per 
	LET pa_shoporddetl[pv_cnt].oper_factor_amt = fr_bor.oper_factor_amt 
	LET pa_shoporddetl[pv_cnt].var_amt = fr_bor.var_amt 

	CASE 
		WHEN fr_bor.type_ind = "S" 
			IF fr_bor.cost_type_ind = "F" THEN 
				LET pv_scost_tot = pv_scost_tot + fr_bor.cost_amt 
				LET pv_wcost_tot = pv_wcost_tot + fr_bor.cost_amt 
				LET pv_lcost_tot = pv_lcost_tot + fr_bor.cost_amt 
				LET pv_price_tot = pv_price_tot + fr_bor.price_amt 
			ELSE 
				LET pv_scost_tot = pv_scost_tot + (fr_bor.cost_amt * 
				pr_shopordhead.order_qty) 
				LET pv_wcost_tot = pv_wcost_tot + (fr_bor.cost_amt * 
				pr_shopordhead.order_qty) 
				LET pv_lcost_tot = pv_lcost_tot + (fr_bor.cost_amt * 
				pr_shopordhead.order_qty) 
				LET pv_price_tot = pv_price_tot + (fr_bor.price_amt * 
				pr_shopordhead.order_qty) 
			END IF 

			LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_price_amt = 0 

		WHEN fr_bor.type_ind = "W" 
			LET err_message = "M74 - SELECT FROM workcentre failed" 

			SELECT * 
			INTO fr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 

			LET err_message = "M74 - SELECT FROM workctrrate failed" 

			SELECT sum(rate_amt) 
			INTO fr_bor.cost_amt 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 
			AND rate_ind = "V" 

			IF fr_bor.cost_amt IS NULL THEN 
				LET fr_bor.cost_amt = 0 
			END IF 

			SELECT sum(rate_amt) 
			INTO fr_bor.price_amt 
			FROM workctrrate 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 
			AND rate_ind = "F" 

			IF fr_bor.price_amt IS NULL THEN 
				LET fr_bor.price_amt = 0 
			END IF 

			LET pa_shoporddetl[pv_cnt].required_qty = pr_shopordhead.order_qty * 
			fr_bor.oper_factor_amt 

			IF fr_workcentre.processing_ind = "Q" THEN 
				LET fv_wc_cost = ((fr_bor.cost_amt / fr_workcentre.time_qty) * 
				pa_shoporddetl[pv_cnt].required_qty) + fr_bor.price_amt 
			ELSE 
				LET fv_wc_cost = (fr_bor.cost_amt * 
				pa_shoporddetl[pv_cnt].required_qty) + fr_bor.price_amt 
			END IF 

			LET pa_shoporddetl[pv_cnt].std_act_cost_amt = fv_wc_cost 
			LET pa_shoporddetl[pv_cnt].std_price_amt = fv_wc_cost * (1 + 
			(fr_workcentre.cost_markup_per / 100)) 
			LET pa_shoporddetl[pv_cnt].receipted_qty = 0 
			LET pa_shoporddetl[pv_cnt].rejected_qty = 0 
			LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_price_amt = 0 
			LET pv_scost_tot = pv_scost_tot + fv_wc_cost 
			LET pv_wcost_tot = pv_wcost_tot + fv_wc_cost 
			LET pv_lcost_tot = pv_lcost_tot + fv_wc_cost 
			LET pv_price_tot = pv_price_tot + 
			pa_shoporddetl[pv_cnt].std_price_amt 

		WHEN fr_bor.type_ind = "U" 
			IF fr_bor.cost_type_ind = "Q" THEN 
				LET fv_setup_qty = pr_shopordhead.order_qty / fr_bor.var_amt 

				IF (pr_shopordhead.order_qty / fr_bor.var_amt) > fv_setup_qty 
				THEN 
					LET fv_setup_qty = fv_setup_qty + 1 
				END IF 

				LET pv_scost_tot = pv_scost_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 
				LET pv_wcost_tot = pv_wcost_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 
				LET pv_lcost_tot = pv_lcost_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 
				LET pv_price_tot = pv_price_tot + (fr_bor.price_amt * 
				fv_setup_qty) 
			ELSE 
				LET pv_scost_tot = pv_scost_tot + fr_bor.cost_amt 
				LET pv_wcost_tot = pv_wcost_tot + fr_bor.cost_amt 
				LET pv_lcost_tot = pv_lcost_tot + fr_bor.cost_amt 
				LET pv_price_tot = pv_price_tot + fr_bor.price_amt 
			END IF 

			LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_price_amt = 0 

		WHEN fr_bor.type_ind matches "[CB]" 
			LET err_message = "M74 - SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			LET err_message = "M74 - SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			LET pa_shoporddetl[pv_cnt].issue_ware_code =fr_prodmfg.def_ware_code 

			CALL to_stk_uom_conv(pa_shoporddetl[pv_cnt].required_qty, 
			pa_shoporddetl[pv_cnt].uom_code, 
			fr_prodmfg.*, 
			fr_product.*) 
			RETURNING fv_add_qty 

			LET err_message = "M74 - Update of prodstatus failed" 

			IF fr_bor.type_ind = "C" THEN 
				CALL get_costs(pa_shoporddetl[pv_cnt].*, 
				fr_product.*, 
				fr_prodmfg.*) 
				RETURNING pa_shoporddetl[pv_cnt].* 

				LET pv_scost_tot = pv_scost_tot + 
				(pa_shoporddetl[pv_cnt].std_est_cost_amt * 
				pa_shoporddetl[pv_cnt].required_qty) 
				LET pv_wcost_tot = pv_wcost_tot + 
				(pa_shoporddetl[pv_cnt].std_wgted_cost_amt * 
				pa_shoporddetl[pv_cnt].required_qty) 
				LET pv_lcost_tot = pv_lcost_tot + 
				(pa_shoporddetl[pv_cnt].std_act_cost_amt * 
				pa_shoporddetl[pv_cnt].required_qty) 
				LET pv_price_tot = pv_price_tot + 
				(pa_shoporddetl[pv_cnt].std_price_amt * 
				pa_shoporddetl[pv_cnt].required_qty) 
				LET pa_shoporddetl[pv_cnt].issued_qty = 0 

				UPDATE prodstatus 
				SET reserved_qty = reserved_qty + fv_add_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_shoporddetl[pv_cnt].part_code 
				AND ware_code = pa_shoporddetl[pv_cnt].issue_ware_code 
			ELSE 
				LET pa_shoporddetl[pv_cnt].receipted_qty = 0 
				LET pa_shoporddetl[pv_cnt].rejected_qty = 0 
				LET pa_shoporddetl[pv_cnt].std_est_cost_amt = 0 
				LET pa_shoporddetl[pv_cnt].std_wgted_cost_amt = 0 
				LET pa_shoporddetl[pv_cnt].std_act_cost_amt = 0 
				LET pa_shoporddetl[pv_cnt].std_price_amt = 0 

				UPDATE prodstatus 
				SET onord_qty = onord_qty - fv_add_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_shoporddetl[pv_cnt].part_code 
				AND ware_code = pa_shoporddetl[pv_cnt].issue_ware_code 
			END IF 

			LET pa_shoporddetl[pv_cnt].act_est_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_wgted_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_act_cost_amt = 0 
			LET pa_shoporddetl[pv_cnt].act_price_amt = 0 
	END CASE 

END FUNCTION 



FUNCTION expand(fv_part_code, fv_type_ind, fv_req_qty, fv_parent_code) 

	DEFINE 
	fv_part_code LIKE shoporddetl.part_code, 
	fv_type_ind LIKE prodmfg.part_type_ind, 
	fv_req_qty LIKE shoporddetl.required_qty, 
	fv_parent_code LIKE shoporddetl.parent_part_code, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 

	fa_bor array[2000] OF RECORD LIKE bor.* 


	IF fv_type_ind = "P" THEN 
		DECLARE c_phantom CURSOR FOR 
		SELECT * 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fv_part_code 
		ORDER BY sequence_num 

		LET fv_arr_size = 1 

		FOREACH c_phantom INTO fa_bor[fv_arr_size].* 
			IF fa_bor[fv_arr_size].type_ind matches "[CB]" THEN 
				LET fa_bor[fv_arr_size].required_qty = fv_req_qty * 
				fa_bor[fv_arr_size].required_qty 
			END IF 

			LET fv_arr_size = fv_arr_size + 1 

			IF fv_arr_size > 2000 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET fv_arr_size = fv_arr_size - 1 

		IF fv_arr_size = 0 THEN 
			RETURN 
		END IF 
	ELSE 
		CALL input_child_configs(fv_part_code, fv_req_qty, fv_parent_code) 
		RETURNING fv_arr_size 

		IF fv_arr_size = 0 THEN 
			RETURN 
		END IF 

		FOR fv_cnt = 1 TO fv_arr_size 
			LET fa_bor[fv_cnt].parent_part_code = fv_parent_code 
			LET fa_bor[fv_cnt].part_code = pa_config[fv_cnt].part_code 
			LET fa_bor[fv_cnt].required_qty = pa_config[fv_cnt].required_qty 
			LET fa_bor[fv_cnt].type_ind = "C" 
			LET fa_bor[fv_cnt].start_date = NULL 
			LET fa_bor[fv_cnt].end_date = NULL 
		END FOR 
	END IF 

	LET fv_cnt = 0 

	WHILE fv_cnt < fv_arr_size 
		LET fv_cnt = fv_cnt + 1 
		LET fr_prodmfg.part_type_ind = NULL 

		IF fa_bor[fv_cnt].type_ind = "C" THEN 
			LET err_message = "M74 - SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_bor[fv_cnt].part_code 

			IF fa_bor[fv_cnt].uom_code IS NULL THEN 
				LET fa_bor[fv_cnt].uom_code = fr_prodmfg.man_uom_code 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[GP]" THEN 
				IF fr_prodmfg.part_type_ind = "P" THEN 
					IF fa_bor[fv_cnt].uom_code != fr_prodmfg.man_uom_code THEN 
						LET err_message = "M74 - SELECT FROM product failed" 

						SELECT * 
						INTO fr_product.* 
						FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fa_bor[fv_cnt].part_code 

						CALL to_mfg_uom_conv(fa_bor[fv_cnt].required_qty, 
						fa_bor[fv_cnt].uom_code, 
						fr_prodmfg.*, 
						fr_product.*) 
						RETURNING fa_bor[fv_cnt].required_qty 
					END IF 

					CALL load_detl_array(fa_bor[fv_cnt].*, 
					fr_prodmfg.part_type_ind) 
				END IF 

				CALL expand(fa_bor[fv_cnt].part_code, fr_prodmfg.part_type_ind, 
				fa_bor[fv_cnt].required_qty, 
				fa_bor[fv_cnt].parent_part_code) 

				IF int_flag OR quit_flag THEN 
					RETURN 
				END IF 

				IF pv_cnt = 2000 THEN 
					EXIT WHILE 
				END IF 

				CONTINUE WHILE 
			END IF 
		END IF 

		CALL load_detl_array(fa_bor[fv_cnt].*, fr_prodmfg.part_type_ind) 

		IF pv_cnt = 2000 THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

END FUNCTION 



FUNCTION input_child_configs(fv_part_code, fv_req_qty, fv_parent_code) 

	DEFINE 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_idx SMALLINT, 
	fv_total FLOAT, 
	fv_part_code LIKE configuration.generic_part_code, 
	fv_req_qty LIKE bor.required_qty, 
	fv_desc_text LIKE product.desc_text, 
	fv_option_num LIKE configuration.option_num, 
	fv_config_ind LIKE configuration.config_ind, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_parent_code LIKE bor.parent_part_code, 

	fa_config_specific array[500] OF RECORD 
		required_qty LIKE orderdetl.order_qty, 
		specific_part_code LIKE configuration.specific_part_code, 
		desc_text LIKE product.desc_text 
	END RECORD 


	LET err_message = "M74 - SELECT FROM product failed" 

	SELECT desc_text 
	INTO fv_desc_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_part_code 

	LET err_message = "M74 - SELECT FROM configuration, product" 

	DECLARE c_specific CURSOR FOR 
	SELECT specific_part_code, desc_text, config_ind, option_num 
	FROM configuration c, product p 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = p.cmpy_code 
	AND c.generic_part_code = fv_part_code 
	AND c.specific_part_code = p.part_code 

	LET fv_cnt = 1 

	FOREACH c_specific INTO fa_config_specific[fv_cnt].specific_part_code, 
		fa_config_specific[fv_cnt].desc_text, 
		fv_config_ind, 
		fv_option_num 

		IF fa_config_specific[fv_cnt].specific_part_code = fv_parent_code THEN 
			CONTINUE FOREACH 
		END IF 

		LET fv_cnt = fv_cnt + 1 

		IF fv_cnt > 500 THEN 
			LET msgresp = kandoomsg("M", 9567, "") 
			# ERROR "Only the first 500 products have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET fv_cnt = fv_cnt - 1 

	IF fv_cnt = 0 THEN 
		RETURN fv_cnt 
	END IF 

	IF NOT pv_open THEN 
		OPEN WINDOW wm194 with FORM "M194" 
		CALL  windecoration_m("M194") -- albo kd-762 

		LET pv_open = true 
	END IF 

	CLEAR FORM 

	LET msgresp = kandoomsg("M", 1523, "") 
	# MESSAGE "F3 Fwd, F4 Bwd, ESC TO Accept - DEL TO Exit"

	LET fv_req_qty = fv_req_qty * fv_option_num 

	DISPLAY fv_part_code, fv_desc_text, fv_option_num, fv_req_qty 
	TO generic_part_code, desc_text, option_num, req_qty 

	IF fv_config_ind = "F" THEN 
		DISPLAY "Feature" TO type_text 
	ELSE 
		DISPLAY "Option" TO type_text 
	END IF 

	OPTIONS 
	DELETE KEY f36 

	CALL set_count(fv_cnt) 

	INPUT ARRAY fa_config_specific WITHOUT DEFAULTS FROM sr_so_config.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 

		AFTER FIELD required_qty 
			IF fa_config_specific[fv_idx].required_qty < 0 THEN 
				LET msgresp = kandoomsg("M", 9816, "") 
				# ERROR "Quantity cannot be less than zero"
				NEXT FIELD required_qty 
			END IF 

			IF fa_config_specific[fv_idx].required_qty > fv_req_qty THEN 
				LET msgresp = kandoomsg("M", 9817, "") 
				# ERROR "Quantity cannot be greater than the required quantity"
				NEXT FIELD required_qty 
			END IF 

			IF fa_config_specific[fv_idx].required_qty > 0 THEN 
				LET err_message = "M74 - SELECT FROM prodmfg failed" 

				SELECT part_type_ind 
				INTO fv_part_type_ind 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_config_specific[fv_idx].specific_part_code 

				IF fv_part_type_ind = "G" THEN 
					LET err_message = "M74 - SELECT FROM configuration failed" 

					SELECT unique generic_part_code 
					FROM configuration 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND generic_part_code = 
					fa_config_specific[fv_idx].specific_part_code 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9775, "") 
						# error"This generic product must have configs SET up.."
						NEXT FIELD required_qty 
					END IF 
				END IF 
			END IF 

			IF (fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("right")) 
			AND fa_config_specific[fv_idx + 1].specific_part_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9530, "") 
				# ERROR "There are no more rows in the direction you are going"
				NEXT FIELD required_qty 
			END IF 

		AFTER INPUT 
			LET fv_cnt2 = 0 
			LET fv_total = 0 
			INITIALIZE pa_config TO NULL 

			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			FOR fv_cnt1 = 1 TO fv_cnt 
				IF fa_config_specific[fv_cnt1].required_qty IS NOT NULL 
				AND fa_config_specific[fv_cnt1].required_qty > 0 THEN 
					LET fv_total = fv_total + 
					fa_config_specific[fv_cnt1].required_qty 
					LET fv_cnt2 = fv_cnt2 + 1 
					LET pa_config[fv_cnt2].required_qty = 
					fa_config_specific[fv_cnt1].required_qty 
					LET pa_config[fv_cnt2].part_code = 
					fa_config_specific[fv_cnt1].specific_part_code 
				END IF 
			END FOR 

			IF fv_total > fv_req_qty THEN 
				LET msgresp = kandoomsg("M", 9786, "") 
				# error"The total of all products exceeds the required quantity"
				NEXT FIELD required_qty 
			END IF 

			IF fv_config_ind = "F" 
			AND fv_total < fv_req_qty THEN 
				LET msgresp = kandoomsg("M", 9787, "") 
				# ERROR "The total of all products must equal the required qty"
				NEXT FIELD required_qty 
			END IF 

	END INPUT 

	OPTIONS 
	DELETE KEY f2 

	RETURN fv_cnt2 

END FUNCTION 



FUNCTION to_mfg_uom_conv(fv_qty, fv_uom_code, fr_prodmfg, fr_product) 

	DEFINE 
	fv_qty LIKE bor.required_qty, 
	fv_uom_code LIKE bor.uom_code, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.* 


	CASE fv_uom_code 
		WHEN fr_product.stock_uom_code 
			LET fv_qty = fv_qty / fr_prodmfg.man_stk_con_qty 

		WHEN fr_product.sell_uom_code 
			LET fv_qty = (fv_qty / fr_product.stk_sel_con_qty) / 
			fr_prodmfg.man_stk_con_qty 

		WHEN fr_product.pur_uom_code 
			LET fv_qty = (fv_qty * fr_product.pur_stk_con_qty) / 
			fr_prodmfg.man_stk_con_qty 
	END CASE 

	RETURN fv_qty 

END FUNCTION 
