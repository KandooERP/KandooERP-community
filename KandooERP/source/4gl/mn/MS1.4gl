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

	Source code beautified by beautify.pl on 2020-01-02 17:31:36	$Id: $
}


# Purpose - Close Held Shop Orders

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	formname CHAR(10), 
	err_continue CHAR(1), 
	err_message CHAR(50), 

	pr_mnparms RECORD LIKE mnparms.*, 

	pa_shopordhead array[1000] OF RECORD 
		toggle_text CHAR(1), 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		order_type_ind LIKE shopordhead.order_type_ind, 
		sales_order_num LIKE shopordhead.sales_order_num, 
		cust_code LIKE shopordhead.cust_code, 
		part_code LIKE shopordhead.part_code, 
		start_date LIKE shopordhead.start_date, 
		end_date LIKE shopordhead.end_date 
	END RECORD 

END GLOBALS 


MAIN 

	CALL setModuleId("MS1") -- albo 
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

	CALL query_orders() 

END MAIN 



FUNCTION query_orders() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_scrn SMALLINT 

	OPEN WINDOW w1_m188 with FORM "M188" 
	CALL  windecoration_m("M188") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		INITIALIZE pa_shopordhead TO NULL 

		LET msgresp = kandoomsg("M", 1500, "") 	# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON shop_order_num, suffix_num, order_type_ind, sales_order_num, 
		cust_code, part_code, start_date, end_date 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") # MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT status_ind, shop_order_num, suffix_num, ", 
		"order_type_ind, sales_order_num, cust_code", 
		", part_code, start_date, end_date ", 
		"FROM shopordhead ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND status_ind = 'H' ", 
		"AND order_type_ind != 'F' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY shop_order_num, suffix_num" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_shopordhead CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_shopordhead INTO pa_shopordhead[fv_cnt].* 
			LET pa_shopordhead[fv_cnt].toggle_text = NULL 
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

		LET msgresp = kandoomsg("M", 1538, "") 
		# MESSAGE "F6 SELECT, F7 SELECT All, F3 Fwd, F4 Bwd, ESC TO Accept- DEL"

		LET fv_cnt = fv_cnt - 1 
		CALL set_count(fv_cnt) 

		DISPLAY ARRAY pa_shopordhead TO sr_shopordhead.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","MS1","display-arr-shopordhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 



			ON KEY (f6) 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

				IF pa_shopordhead[fv_idx].toggle_text IS NULL THEN 
					LET pa_shopordhead[fv_idx].toggle_text = "*" 
				ELSE 
					LET pa_shopordhead[fv_idx].toggle_text = NULL 
				END IF 

				DISPLAY pa_shopordhead[fv_idx].toggle_text 
				TO sr_shopordhead[fv_scrn].toggle_text 

			ON KEY (f7) 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 

				FOR fv_cnt1 = 1 TO fv_cnt 
					LET pa_shopordhead[fv_cnt1].toggle_text = "*" 
				END FOR 

				FOR fv_cnt1 = 1 TO 13 
					DISPLAY pa_shopordhead[fv_idx -fv_scrn +fv_cnt1].toggle_text 
					TO sr_shopordhead[fv_cnt1].toggle_text 
				END FOR 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			LET msgresp = kandoomsg("M", 1539, "") 
			# MESSAGE "Please wait WHILE closing shop ORDER(s)..."
			CALL close_orders(fv_cnt) 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m188 

END FUNCTION 



FUNCTION close_orders(fv_cnt) 

	DEFINE fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 

	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.* 


	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		FOR fv_cnt1 = 1 TO fv_cnt 
			IF pa_shopordhead[fv_cnt1].toggle_text IS NULL THEN 
				CONTINUE FOR 
			END IF 

			###
			### Reverse reserved/onorder qtys on prodstatus FOR all components/by-products
			###

			DECLARE c_reverse CURSOR FOR 
			SELECT * 
			FROM shoporddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pa_shopordhead[fv_cnt1].shop_order_num 
			AND suffix_num = pa_shopordhead[fv_cnt1].suffix_num 
			AND type_ind matches "[CB]" 
			ORDER BY sequence_num 

			FOREACH c_reverse INTO fr_shoporddetl.* 
				LET err_message = "MS1 - SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				LET err_message = "MS1 - SELECT FROM product failed" 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				CALL uom_convert(fr_shoporddetl.uom_code, 
				fr_shoporddetl.required_qty, fr_product.*, 
				fr_prodmfg.*) 
				RETURNING fr_shoporddetl.required_qty 

				LET err_message = "MS1 - Update of prodstatus failed" 

				IF fr_shoporddetl.type_ind = "C" THEN 
					UPDATE prodstatus 
					SET reserved_qty = reserved_qty - fr_shoporddetl.required_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 
					AND ware_code = fr_shoporddetl.issue_ware_code 
				ELSE 
					UPDATE prodstatus 
					SET onord_qty = onord_qty + fr_shoporddetl.required_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 
					AND ware_code = fr_shoporddetl.issue_ware_code 
				END IF 

			END FOREACH 

			###
			### Subtract shopordhead ORDER qty FROM prodstatus on ORDER qty
			###

			LET err_message = "MS1 - SELECT FROM shopordhead failed" 

			SELECT * 
			INTO fr_shopordhead.* 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pa_shopordhead[fv_cnt1].shop_order_num 
			AND suffix_num = pa_shopordhead[fv_cnt1].suffix_num 

			LET err_message = "MS1 - Second SELECT FROM prodmfg failed" 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shopordhead.part_code 

			LET err_message = "MS1 - Second SELECT FROM product failed" 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shopordhead.part_code 

			CALL uom_convert(fr_shopordhead.uom_code, fr_shopordhead.order_qty, 
			fr_product.*, fr_prodmfg.*) 
			RETURNING fr_shopordhead.order_qty 

			LET err_message = "MS1 - Second UPDATE of prodstatus failed" 

			UPDATE prodstatus 
			SET onord_qty = onord_qty - fr_shopordhead.order_qty 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_shopordhead.part_code 
			AND ware_code = fr_shopordhead.receipt_ware_code 

			###
			### Update shopordhead table
			###

			LET err_message = "MS1 - Update of shopordhead failed" 

			UPDATE shopordhead 
			SET status_ind = "C", 
			last_change_date = today, 
			last_user_text = glob_rec_kandoouser.sign_on_code, 
			last_program_text = "MS1" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = pa_shopordhead[fv_cnt1].shop_order_num 
			AND suffix_num = pa_shopordhead[fv_cnt1].suffix_num 
		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 



FUNCTION uom_convert(fv_uom_code, fv_qty, fr_product, fr_prodmfg) 

	DEFINE fv_uom_code LIKE shoporddetl.uom_code, 
	fv_qty LIKE shoporddetl.required_qty, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.* 


	CASE 
		WHEN fv_uom_code = fr_prodmfg.man_uom_code 
			LET fv_qty = fv_qty * fr_prodmfg.man_stk_con_qty 

		WHEN fv_uom_code = fr_product.sell_uom_code 
			LET fv_qty = fv_qty / fr_product.stk_sel_con_qty 

		WHEN fv_uom_code = fr_product.pur_uom_code 
			LET fv_qty = fv_qty * fr_product.pur_stk_con_qty 
	END CASE 

	RETURN fv_qty 

END FUNCTION 
