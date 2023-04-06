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


# Purpose - Purchase Order Creation

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

	pa_mps_orders array[1000] OF RECORD 
		toggle_text CHAR(1), 
		vend_code LIKE product.vend_code, 
		plan_code LIKE mpsdemand.plan_code, 
		part_code LIKE mpsdemand.part_code, 
		required_qty LIKE mpsdemand.required_qty, 
		due_date LIKE mpsdemand.due_date 
	END RECORD 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M73") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 


	SELECT * 
	FROM mnparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--    AND    parm_code = 1  -- albo
	AND param_code = "1" -- albo 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7500, "") 
		# prompt "Manufacturing parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	SELECT * 
	FROM puparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = notfound THEN 
		ERROR " Purchasing Parameters Not Set Up - Refer Menu RZP" 
		SLEEP 4 
		EXIT program 
	END IF 

	CREATE temp TABLE temporders 
	( 
	vend_code CHAR(8), 
	due_date DATE, 
	ware_code CHAR(3), 
	seq_num SMALLINT, 
	plan_code CHAR(10), 
	part_code CHAR(15) 
	) 
	with no LOG 

	OPTIONS 
	INSERT KEY f36 

	CALL select_orders() 

END MAIN 



FUNCTION select_orders() 

	DEFINE 
	fv_vend_code LIKE vendor.vend_code, 
	fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_scrn SMALLINT, 
	fv_order CHAR(1), #3504 
	fr_vendor RECORD LIKE vendor.* 

	OPEN WINDOW wm195 with FORM "M195" 
	CALL  windecoration_m("M195") -- albo kd-762 

	WHILE true 
		INITIALIZE pa_mps_orders TO NULL 
		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 	# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON plan_code, mpsdemand.part_code, required_qty, due_date 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 
		
		LET msgresp = kandoomsg("M", 8503, "") #3504 - SELECT ORDER FOR query
		LET fv_order = upshift(msgresp) 
		#3504 - end

		LET msgresp = kandoomsg("M", 1532, "") 	# MESSAGE "Searching database - please wait"

		#3504 - do different queries depending on selected ORDER
		IF fv_order = "N" THEN 
			LET fv_query_text = "SELECT '', vend_code, plan_code, ", 
			"mpsdemand.part_code, required_qty, ", 
			"due_date ", 
			"FROM mpsdemand, product ", 
			"WHERE product.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			"AND product.cmpy_code = mpsdemand.cmpy_code ", 
			"AND product.part_code = mpsdemand.part_code ", 
			"AND type_text = 'RP' ", 
			"AND ", fv_where_text clipped, " ", 
			"ORDER BY plan_code, mpsdemand.part_code" 
		ELSE 
			LET fv_query_text = "SELECT '', vend_code, plan_code, ", 
			"mpsdemand.part_code, required_qty, ", 
			"due_date ", 
			"FROM mpsdemand, product ", 
			"WHERE product.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
			"AND product.cmpy_code = mpsdemand.cmpy_code ", 
			"AND product.part_code = mpsdemand.part_code ", 
			"AND type_text = 'RP' ", 
			"AND ", fv_where_text clipped, " ", 
			"ORDER BY vend_code, plan_code, mpsdemand.part_code" 
		END IF 
		#3054 - end

		PREPARE sl_stmt FROM fv_query_text 
		DECLARE c_mps CURSOR FOR sl_stmt 

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

			AFTER FIELD vend_code 
				IF pa_mps_orders[fv_idx].vend_code IS NOT NULL THEN 
					SELECT * 
					INTO fr_vendor.* 
					FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pa_mps_orders[fv_idx].vend_code 

					IF status = notfound THEN 
						ERROR "Vendor code does NOT exist in the database - ", 
						"Try Window" 
						NEXT FIELD vend_code 
					END IF 

					IF fr_vendor.hold_code = "ST" THEN 
						ERROR "Vendor IS on hold" 
						NEXT FIELD vend_code 
					END IF 

					IF fr_vendor.bal_amt > fr_vendor.limit_amt THEN 
						ERROR "Vendor's credit limit has been exceeded" 
						NEXT FIELD vend_code 
					END IF 

					IF fr_vendor.currency_code IS NULL THEN 
						ERROR "Vendor has no currency SET up" 
						NEXT FIELD vend_code 
					END IF 
				ELSE 
					IF pa_mps_orders[fv_idx].toggle_text = "*" THEN 
						ERROR "Vendor code must be entered" 
						NEXT FIELD vend_code 
					END IF 
				END IF 

				IF fgl_lastkey() = fgl_keyval("down") 
				AND pa_mps_orders[fv_idx + 1].plan_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9530, "") 
					# ERROR "There are no more rows in the direction you are..."
					NEXT FIELD vend_code 
				END IF 

			AFTER FIELD required_qty 
				IF pa_mps_orders[fv_idx].required_qty IS NULL THEN 
					ERROR "Required quantity must be entered" 
					NEXT FIELD required_qty 
				END IF 

				IF pa_mps_orders[fv_idx].required_qty <= 0 THEN 
					ERROR "Required quantity must be greater than zero" 
					NEXT FIELD required_qty 
				END IF 

				IF fgl_lastkey() != fgl_keyval("up") 
				AND fgl_lastkey() != fgl_keyval("left") 
				AND fgl_lastkey() != fgl_keyval("accept") 
				AND pa_mps_orders[fv_idx + 1].plan_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9530, "") 
					# ERROR "There are no more rows in the direction you are..."
					NEXT FIELD required_qty 
				END IF 

			BEFORE DELETE 
				LET fv_cnt = arr_count() 

				INSERT INTO temporders VALUES ("", 
				pa_mps_orders[fv_idx].due_date, 
				"", 
				9999, 
				pa_mps_orders[fv_idx].plan_code, 
				pa_mps_orders[fv_idx].part_code) 

			AFTER DELETE 
				INITIALIZE pa_mps_orders[fv_cnt].* TO NULL 

			ON KEY (f6) 
				IF pa_mps_orders[fv_idx].toggle_text = "*" THEN 
					LET pa_mps_orders[fv_idx].toggle_text = "" 
				ELSE 
					IF pa_mps_orders[fv_idx].vend_code IS NOT NULL THEN 
						SELECT * 
						INTO fr_vendor.* 
						FROM vendor 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = pa_mps_orders[fv_idx].vend_code 

						IF status = notfound THEN 
							ERROR "Vendor code does NOT exist in the database", 
							" - Try Window" 
							NEXT FIELD vend_code 
						END IF 

						IF fr_vendor.hold_code = "ST" THEN 
							ERROR "Vendor IS on hold" 
							NEXT FIELD vend_code 
						END IF 

						IF fr_vendor.bal_amt > fr_vendor.limit_amt THEN 
							ERROR "Vendor's credit limit has been exceeded" 
							NEXT FIELD vend_code 
						END IF 

						IF fr_vendor.currency_code IS NULL THEN 
							ERROR "Vendor has no currency SET up" 
							NEXT FIELD vend_code 
						END IF 

						LET pa_mps_orders[fv_idx].toggle_text = "*" 
					ELSE 
						ERROR "Vendor code must be entered" 
						NEXT FIELD vend_code 
					END IF 
				END IF 

				DISPLAY pa_mps_orders[fv_idx].toggle_text 
				TO sr_mps[fv_scrn].toggle_text 
				DISPLAY pa_mps_orders[fv_idx].required_qty 
				TO sr_mps[fv_scrn].required_qty 

			ON KEY (f7) 
				FOR fv_cnt1 = 1 TO fv_cnt 
					IF pa_mps_orders[fv_cnt1].vend_code IS NOT NULL THEN 
						LET pa_mps_orders[fv_cnt1].toggle_text = "*" 
					END IF 
				END FOR 

				FOR fv_cnt1 = 1 TO 14 
					DISPLAY pa_mps_orders[fv_idx - fv_scrn +fv_cnt1].toggle_text 
					TO sr_mps[fv_cnt1].toggle_text 
					DISPLAY pa_mps_orders[fv_idx -fv_scrn +fv_cnt1].required_qty 
					TO sr_mps[fv_cnt1].required_qty 
				END FOR 

			ON KEY (control-b) 
				CALL show_vend(glob_rec_kandoouser.cmpy_code,pa_mps_orders[fv_idx].vend_code) RETURNING fv_vend_code 

				IF fv_vend_code IS NOT NULL THEN 
					LET pa_mps_orders[fv_idx].vend_code = fv_vend_code 
					DISPLAY pa_mps_orders[fv_idx].vend_code 
					TO sr_mps[fv_scrn].vend_code 
				END IF 

			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF NOT create_purchord(fv_cnt) THEN 
						NEXT FIELD vend_code 
					END IF 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			DELETE FROM temporders 
		END IF 
	END WHILE 

	CLOSE WINDOW wm195 

END FUNCTION 



FUNCTION create_purchord(fv_arr_size) 
	DEFINE 
	fv_year_num LIKE period.year_num, 
	fv_period_num LIKE period.period_num, 
	fv_base_curr_code LIKE arparms.currency_code, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_seq_num SMALLINT, 
	fv_open SMALLINT, 

	fr_purchhead RECORD LIKE purchhead.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_vendor RECORD LIKE vendor.*, 
	fr_warehouse RECORD LIKE warehouse.*, 
	fr_puparms RECORD LIKE puparms.*, 
	fr_purchdetl RECORD LIKE purchdetl.*, 
	fr_poaudit RECORD LIKE poaudit.*, 
	fr_coa RECORD LIKE coa.*, 

	fr_temporders RECORD 
		vend_code CHAR(8), 
		due_date DATE, 
		ware_code CHAR(3) 
	END RECORD, 

	fr_delete RECORD 
		plan_code CHAR(10), 
		part_code CHAR(10), 
		due_date DATE 
	END RECORD 


	LET msgresp = kandoomsg("M", 1525, "") 
	# MESSAGE "Please wait....."

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING fv_year_num, fv_period_num 

	SELECT * 
	FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = fv_year_num 
	AND period_num = fv_period_num 
	AND pu_flag = "Y" 

	IF status = notfound THEN 
		ERROR "Accounting period IS closed OR NOT SET up" 
		RETURN false 
	END IF 

	FOR fv_cnt = 1 TO fv_arr_size 
		IF pa_mps_orders[fv_cnt].toggle_text = "*" THEN 
			SELECT * 
			INTO fr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pa_mps_orders[fv_cnt].vend_code 

			IF status = notfound THEN 
				ERROR "Vendor ", pa_mps_orders[fv_cnt].vend_code clipped, 
				" does NOT exist in the database" 
				RETURN false 
			END IF 

			IF fr_vendor.hold_code = "ST" THEN 
				ERROR "Vendor ", pa_mps_orders[fv_cnt].vend_code clipped, 
				" IS on hold" 
				RETURN false 
			END IF 

			IF fr_vendor.bal_amt > fr_vendor.limit_amt THEN 
				ERROR "Credit limit FOR vendor ", 
				pa_mps_orders[fv_cnt].vend_code clipped, 
				" has been exceeded" 
				RETURN false 
			END IF 

			IF fr_vendor.currency_code IS NULL THEN 
				ERROR "Vendor ", pa_mps_orders[fv_cnt].vend_code clipped, 
				" has no currency SET up" 
				RETURN false 
			END IF 

			SELECT currency_code 
			FROM currency 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND currency_code = fr_vendor.currency_code 

			IF status = notfound THEN 
				ERROR "Currency FOR vendor ", pa_mps_orders[fv_cnt].vend_code 
				clipped, " does NOT exist" 
				RETURN false 
			END IF 

			SELECT * 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_mps_orders[fv_cnt].part_code 

			IF status = notfound THEN 
				ERROR "Product ", pa_mps_orders[fv_cnt].part_code clipped, 
				" does NOT exist in the database" 
				RETURN false 
			END IF 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_mps_orders[fv_cnt].part_code 

			IF status = notfound THEN 
				ERROR "Manufacturing details FOR product ", 
				pa_mps_orders[fv_cnt].part_code clipped, " are NOT SET up" 
				RETURN false 
			END IF 

			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pa_mps_orders[fv_cnt].part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			IF status = notfound THEN 
				ERROR "Default warehouse details FOR product ", 
				pa_mps_orders[fv_cnt].part_code clipped, " are NOT SET up" 
				RETURN false 
			END IF 

			INSERT INTO temporders VALUES (pa_mps_orders[fv_cnt].vend_code, 
			pa_mps_orders[fv_cnt].due_date, 
			fr_prodmfg.def_ware_code, 
			fv_cnt, 
			"", 
			"") 
		END IF 
	END FOR 

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
		### Load the purchhead RECORD & INSERT INTO the table
		###

		DECLARE c_orderhead CURSOR FOR 
		SELECT vend_code, due_date, ware_code 
		FROM temporders 
		WHERE seq_num != 9999 
		GROUP BY vend_code, due_date, ware_code 

		FOREACH c_orderhead INTO fr_temporders.* 
			IF NOT fv_open THEN 
				{
				            OPEN WINDOW w1_M73 AT 10,20 with 8 rows, 42 columns     -- albo  KD-762
				                attributes (border, white, MESSAGE line first)
				}
				LET fv_open = true 
			END IF 

			LET err_message = "M73 - SELECT FROM puparms failed" 

			SELECT * 
			INTO fr_puparms.* 
			FROM puparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 

			INITIALIZE fr_purchhead, fr_vendor, fr_warehouse TO NULL 

			#       LET err_message = "M73 - Update of puparms failed"


			LET fr_purchhead.order_num = next_trans_num(glob_rec_kandoouser.cmpy_code,"PU","") 

			DISPLAY "" at 2,2 

			DISPLAY "Creating purchase ORDER ", fr_purchhead.order_num at 2,2 
			DISPLAY "Vendor : ", fr_temporders.vend_code at 3,2 
			DISPLAY "Due Date : ", fr_temporders.due_date at 4,2 
			DISPLAY "Warehouse : ", fr_temporders.ware_code at 5,2 
			DISPLAY "Product :" at 7,2 
			SLEEP 1 

			LET err_message = "M73 - SELECT FROM vendor failed" 

			SELECT * 
			INTO fr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = fr_temporders.vend_code 

			LET err_message = "M73 - SELECT FROM warehouse failed" 

			SELECT * 
			INTO fr_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = fr_temporders.ware_code 

			LET fr_purchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_purchhead.vend_code = fr_temporders.vend_code 

			LET fr_purchhead.year_num = fv_year_num 
			LET fr_purchhead.period_num = fv_period_num 
			LET fr_purchhead.enter_code = glob_rec_kandoouser.sign_on_code 
			LET fr_purchhead.entry_date = today 
			LET fr_purchhead.order_date = today 
			LET fr_purchhead.salesperson_text = fr_vendor.contact_text 
			LET fr_purchhead.term_code = fr_vendor.term_code 
			LET fr_purchhead.tax_code = fr_vendor.tax_code 
			LET fr_purchhead.ware_code = fr_temporders.ware_code 
			LET fr_purchhead.curr_code = fr_vendor.currency_code 

			LET err_message = "M73 - SELECT FROM rate_exchange failed" 

			SELECT conv_buy_qty 
			INTO fr_purchhead.conv_qty 
			FROM rate_exchange 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND currency_code = fr_purchhead.curr_code 
			AND start_date = (SELECT max(start_date) 
			FROM rate_exchange 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND currency_code = fr_purchhead.curr_code 
			AND start_date <= fr_purchhead.order_date) 

			LET fr_purchhead.due_date = fr_temporders.due_date 
			LET fr_purchhead.status_ind = "O" 
			LET fr_purchhead.printed_flag = "N" 
			LET fr_purchhead.del_name_text = fr_warehouse.desc_text 
			LET fr_purchhead.del_addr1_text = fr_warehouse.addr1_text 
			LET fr_purchhead.del_addr2_text = fr_warehouse.addr2_text 
			LET fr_purchhead.del_addr3_text = fr_warehouse.city_text 
			LET fr_purchhead.del_addr4_text = fr_warehouse.state_code, ", ", 	fr_warehouse.post_code 
			LET fr_purchhead.del_country_code = fr_warehouse.country_code --@db-patch_2020_10_04--
			LET fr_purchhead.type_ind = fr_puparms.post_method_ind 
			LET fr_purchhead.confirm_ind = fr_puparms.usual_conf_flag 

			LET err_message = "M73 - Insert INTO purchhead failed" 

			INSERT INTO purchhead VALUES (fr_purchhead.*) 

			###
			### Load the purchdetl RECORD & INSERT INTO the table
			###

			DECLARE c_orderdetl CURSOR FOR 
			SELECT seq_num 
			FROM temporders 
			WHERE vend_code = fr_temporders.vend_code 
			AND due_date = fr_temporders.due_date 
			AND ware_code = fr_temporders.ware_code 

			LET fv_cnt1 = 0 

			FOREACH c_orderdetl INTO fv_seq_num 
				DISPLAY pa_mps_orders[fv_seq_num].part_code at 7,14 

				INITIALIZE fr_purchdetl, fr_poaudit TO NULL 

				LET err_message = "M73 - SELECT FROM product failed" 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_mps_orders[fv_seq_num].part_code 

				LET err_message = "M73 - SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_mps_orders[fv_seq_num].part_code 

				LET err_message = "M73 - SELECT FROM prodstatus failed" 

				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_mps_orders[fv_seq_num].part_code 
				AND ware_code = fr_purchhead.ware_code 

				LET fv_cnt1 = fv_cnt1 + 1 
				LET fr_purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET fr_purchdetl.vend_code = fr_purchhead.vend_code 
				LET fr_purchdetl.order_num = fr_purchhead.order_num 
				LET fr_purchdetl.line_num = fv_cnt1 
				LET fr_purchdetl.seq_num = 1 
				LET fr_purchdetl.type_ind = "I" 
				LET fr_purchdetl.ref_text = pa_mps_orders[fv_seq_num].part_code 
				LET fr_purchdetl.oem_text = fr_product.oem_text 
				LET fr_purchdetl.desc_text = fr_product.desc_text 

				LET err_message = "M73 - SELECT FROM category failed" 

				SELECT stock_acct_code 
				INTO fr_purchdetl.acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = fr_product.cat_code 

				CALL verify_acct_code(glob_rec_kandoouser.cmpy_code, 
				fr_purchdetl.acct_code, 
				fv_year_num, 
				fv_period_num) 
				RETURNING fr_coa.* 

				LET fr_purchdetl.acct_code = fr_coa.acct_code 

				IF fr_purchdetl.acct_code IS NULL THEN 
					ERROR "Account code FOR product ",fr_purchdetl.ref_text clipped, 
					" IS NOT valid" 
					ROLLBACK WORK 

					IF fv_open THEN 
						--                    CLOSE WINDOW w1_M73     -- albo  KD-762
					END IF 

					RETURN false 
				END IF 

				IF fr_purchhead.vend_code = fr_product.vend_code THEN 
					LET fr_purchdetl.uom_code = fr_product.pur_uom_code 
					LET fr_poaudit.unit_cost_amt = fr_prodstatus.for_cost_amt * 
					fr_product.pur_stk_con_qty * fr_product.stk_sel_con_qty 
					LET fr_poaudit.order_qty = 
					(pa_mps_orders[fv_seq_num].required_qty 
					* fr_prodmfg.man_stk_con_qty) / fr_product.pur_stk_con_qty 
				ELSE 
					LET fr_purchdetl.uom_code = fr_product.sell_uom_code 
					LET fr_poaudit.unit_cost_amt = fr_prodstatus.for_cost_amt 
					LET fr_poaudit.order_qty = 
					pa_mps_orders[fv_seq_num].required_qty * 
					fr_prodmfg.man_stk_con_qty * fr_product.stk_sel_con_qty 
				END IF 

				LET err_message = "M73 - Insert INTO purchdetl failed" 

				INSERT INTO purchdetl VALUES (fr_purchdetl.*) 

				###
				### Load the poaudit RECORD & INSERT INTO the table
				###

				LET fr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET fr_poaudit.po_num = fr_purchhead.order_num 
				LET fr_poaudit.line_num = fv_cnt1 
				LET fr_poaudit.seq_num = 1 
				LET fr_poaudit.vend_code = fr_purchhead.vend_code 
				LET fr_poaudit.tran_code = "AA" 
				LET fr_poaudit.tran_num = 0 
				LET fr_poaudit.tran_date = fr_purchhead.order_date 
				LET fr_poaudit.entry_date = today 
				LET fr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET fr_poaudit.orig_auth_flag = "N" 
				LET fr_poaudit.now_auth_flag = "N" 
				LET fr_poaudit.received_qty = 0 
				LET fr_poaudit.voucher_qty = 0 
				LET fr_poaudit.desc_text = fr_purchdetl.desc_text 

				IF fr_prodstatus.for_curr_code != fr_vendor.currency_code THEN 
					LET err_message = "M73 - SELECT FROM arparms failed" 

					SELECT currency_code 
					INTO fv_base_curr_code 
					FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 

					IF status = notfound THEN 
						ERROR "Base currency NOT found in arparms" 
						ROLLBACK WORK 

						IF fv_open THEN 
							--                        CLOSE WINDOW w1_M73     -- albo  KD-762
						END IF 

						RETURN false 
					END IF 

					IF fr_vendor.currency_code = fv_base_curr_code THEN 
						LET fr_poaudit.unit_cost_amt = 
						conv_currency(fr_poaudit.unit_cost_amt, 
						glob_rec_kandoouser.cmpy_code, 
						fr_prodstatus.for_curr_code, 
						"F", 
						fr_purchhead.order_date, 
						"B") 
					ELSE 
						IF fr_prodstatus.for_curr_code = fv_base_curr_code THEN 
							LET fr_poaudit.unit_cost_amt = 
							conv_currency(fr_poaudit.unit_cost_amt, 
							glob_rec_kandoouser.cmpy_code, 
							fr_vendor.currency_code, 
							"T", 
							fr_purchhead.order_date, 
							"B") 
						ELSE 
							LET fr_poaudit.unit_cost_amt = 
							conv_currency(fr_poaudit.unit_cost_amt, 
							glob_rec_kandoouser.cmpy_code, 
							fr_prodstatus.for_curr_code, 
							"F", 
							fr_purchhead.order_date, 
							"B") 

							LET fr_poaudit.unit_cost_amt = 
							conv_currency(fr_poaudit.unit_cost_amt, 
							glob_rec_kandoouser.cmpy_code, 
							fr_vendor.currency_code, 
							"T", 
							fr_purchhead.order_date, 
							"B") 
						END IF 
					END IF 
				END IF 

				LET fr_poaudit.ext_cost_amt = fr_poaudit.unit_cost_amt * 
				fr_poaudit.order_qty 
				LET fr_poaudit.unit_tax_amt = 0 
				LET fr_poaudit.ext_tax_amt = 0 
				LET fr_poaudit.line_total_amt = fr_poaudit.ext_cost_amt 
				LET fr_poaudit.posted_flag = "N" 
				LET fr_poaudit.jour_num = 0 
				LET fr_poaudit.year_num = fv_year_num 
				LET fr_poaudit.period_num = fv_period_num 

				LET err_message = "M73 - Insert INTO poaudit failed" 

				INSERT INTO poaudit VALUES (fr_poaudit.*) 

				###
				### Update onord_qty & seq_num on prodstatus
				###

				LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 

				IF fr_prodstatus.onord_qty IS NULL THEN 
					LET fr_prodstatus.onord_qty = 0 
				END IF 

				IF fr_prodstatus.stocked_flag = "Y" THEN 
					IF fr_purchdetl.uom_code = fr_product.pur_uom_code THEN 
						LET fr_poaudit.order_qty = fr_poaudit.order_qty * 
						fr_product.pur_stk_con_qty * fr_product.stk_sel_con_qty 
					END IF 

					LET fr_prodstatus.onord_qty = fr_prodstatus.onord_qty + 
					fr_poaudit.order_qty 
				END IF 

				LET err_message = "M73 - Update of prodstatus failed" 

				UPDATE prodstatus 
				SET onord_qty = fr_prodstatus.onord_qty, 
				seq_num = fr_prodstatus.seq_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_purchdetl.ref_text 
				AND ware_code = fr_purchhead.ware_code 

				###
				### Delete recommended purchase ORDER FROM mpsdemand & temporders
				###

				LET err_message = "M73 - DELETE FROM mpsdemand failed" 

				DELETE FROM mpsdemand 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND plan_code = pa_mps_orders[fv_seq_num].plan_code 
				AND part_code = pa_mps_orders[fv_seq_num].part_code 
				AND due_date = pa_mps_orders[fv_seq_num].due_date 
				AND type_text = "RP" 

				DELETE FROM temporders 
				WHERE seq_num = fv_seq_num 
			END FOREACH 

			###
			### Update last_po_date on vendor table
			###

			IF fr_purchhead.order_date > fr_vendor.last_po_date 
			OR fr_vendor.last_po_date IS NULL THEN 
				LET err_message = "M73 - Update of vendor failed" 

				UPDATE vendor 
				SET last_po_date = fr_purchhead.order_date 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = fr_purchhead.vend_code 
			END IF 
		END FOREACH 

		###
		### Delete mpsdemand rows that were deleted FROM the SCREEN array
		###

		DECLARE c_delete CURSOR FOR 
		SELECT plan_code, part_code, due_date 
		FROM temporders 
		WHERE seq_num = 9999 

		LET err_message = "M73 - DELETE FROM mpsdemand failed" 

		FOREACH c_delete INTO fr_delete.* 
			DELETE FROM mpsdemand 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND plan_code = fr_delete.plan_code 
			AND part_code = fr_delete.part_code 
			AND due_date = fr_delete.due_date 
			AND type_text = "RP" 
		END FOREACH 

		DELETE FROM temporders 
		WHERE seq_num = 9999 

	COMMIT WORK 
	WHENEVER ERROR stop 

	IF fv_open THEN 
		--        CLOSE WINDOW w1_M73     -- albo  KD-762
	END IF 

	RETURN true 

END FUNCTION 
