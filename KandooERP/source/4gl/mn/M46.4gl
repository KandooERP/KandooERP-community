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


# Purpose - Work In Progress Receipt

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

	pr_mnparms RECORD LIKE mnparms.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M46") -- albo 
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

	CALL query_wip() 

END MAIN 



FUNCTION query_wip() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cc_ind LIKE workcentre.count_centre_ind, 

	fa_shoporddetl array[1000] OF RECORD 
		work_centre_code LIKE shoporddetl.part_code, 
		shop_order_num LIKE shopordhead.shop_order_num, 
		sequence_num LIKE shoporddetl.sequence_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		part_code LIKE shopordhead.part_code, 
		status_ind LIKE shopordhead.status_ind, 
		end_date LIKE shopordhead.end_date 
	END RECORD 

	OPEN WINDOW w1_m182 with FORM "M182" 
	CALL  windecoration_m("M182") -- albo kd-762 

	WHILE true 

		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text 
		ON work_centre_code, hd.shop_order_num, hd.suffix_num, hd.part_code, hd.status_ind, hd.end_date 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT work_centre_code, hd.shop_order_num, ", 
		"sequence_num, hd.suffix_num, hd.part_code,", 
		"hd.status_ind, hd.end_date ", 
		"FROM shopordhead hd, shoporddetl dt ", 
		"WHERE hd.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND hd.cmpy_code = dt.cmpy_code ", 
		"AND hd.shop_order_num = dt.shop_order_num ", 
		"AND hd.suffix_num = dt.suffix_num ", 
		"AND order_type_ind <> 'F' ", 
		"AND type_ind = 'W' ", 
		"AND status_ind != 'C' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY shop_order_num, suffix_num, ", 
		"sequence_num" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_shoporddetl CURSOR FOR sl_stmt1 

		LET fv_cnt = 1 

		FOREACH c_shoporddetl INTO fa_shoporddetl[fv_cnt].* 
			SELECT status_ind 
			FROM wipreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fa_shoporddetl[fv_cnt].work_centre_code 
			AND shop_order_num = fa_shoporddetl[fv_cnt].shop_order_num 
			AND suffix_num = fa_shoporddetl[fv_cnt].suffix_num 
			AND sequence_num = fa_shoporddetl[fv_cnt].sequence_num 
			AND part_code = fa_shoporddetl[fv_cnt].part_code 
			AND status_ind = "C" 

			IF status != notfound THEN 
				CONTINUE FOREACH 
			END IF 

			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 1000 THEN 
				ERROR "Only the first 1000 detail lines were selected" 

				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 1 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		MESSAGE " RETURN TO Receipt Work in Progress, F3 Fwd, F4 Bwd - DEL TO ", 
		"Exit" 
		attribute (yellow) 

		CALL set_count(fv_cnt - 1) 

		DISPLAY ARRAY fa_shoporddetl TO sr_shoporddetl.* 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M46","display-arr-shoporddetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 

				SELECT count_centre_ind 
				INTO fv_cc_ind 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = 
				fa_shoporddetl[fv_idx].work_centre_code 

				IF fv_cc_ind = "N" THEN 
					ERROR "You cannot receipt AT this work centre" 
					--- modif ericv init # attributes (red, reverse)
				ELSE 
					CALL wip_receipt(fa_shoporddetl[fv_idx].shop_order_num, 
					fa_shoporddetl[fv_idx].suffix_num, 
					fa_shoporddetl[fv_idx].sequence_num) 
				END IF 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m182 

END FUNCTION 



FUNCTION wip_receipt(fv_shop_order_num, fv_suffix_num, fv_sequence_num) 

	DEFINE fv_prod_desc LIKE product.desc_text, 
	fv_shop_order_num LIKE shoporddetl.shop_order_num, 
	fv_suffix_num LIKE shoporddetl.suffix_num, 
	fv_sequence_num LIKE shoporddetl.sequence_num, 
	fv_remain_qty LIKE shoporddetl.required_qty, 
	fv_variable_rate LIKE workctrrate.rate_amt, 
	fv_fixed_rate LIKE workctrrate.rate_amt, 
	fv_first SMALLINT, 

	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_wipreceipt RECORD LIKE wipreceipt.*, 

	fr_wiprecpt RECORD 
		type_ind LIKE wipreceipt.type_ind, 
		required_qty LIKE shoporddetl.required_qty, 
		receipted_qty LIKE shoporddetl.receipted_qty, 
		receipt_qty LIKE wipreceipt.receipt_qty, 
		uom_code LIKE wipreceipt.uom_code, 
		cost_amt LIKE wipreceipt.cost_amt, 
		price_amt LIKE wipreceipt.price_amt, 
		start_date LIKE wipreceipt.start_date, 
		start_time LIKE wipreceipt.start_time, 
		end_date LIKE wipreceipt.end_date, 
		end_time LIKE wipreceipt.end_time, 
		status_ind LIKE wipreceipt.status_ind, 
		desc_text LIKE wipreceipt.desc_text 
	END RECORD 


	SELECT * 
	INTO fr_shopordhead.* 
	FROM shopordhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fv_shop_order_num 
	AND suffix_num = fv_suffix_num 

	SELECT * 
	INTO fr_shoporddetl.* 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fv_shop_order_num 
	AND suffix_num = fv_suffix_num 
	AND sequence_num = fv_sequence_num 

	OPEN WINDOW w2_m183 with FORM "M183" 
	CALL  windecoration_m("M183") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1505, "") 	# MESSAGE "ESC TO Accept - DEL TO Exit"

	DISPLAY BY NAME fr_shoporddetl.work_centre_code, 
	fr_shoporddetl.shop_order_num, 
	fr_shoporddetl.suffix_num, 
	fr_shopordhead.part_code, 
	fr_shopordhead.order_qty 

	DISPLAY fr_shoporddetl.desc_text, fr_shopordhead.uom_code 
	TO wc_desc, uomcode 

	SELECT desc_text 
	INTO fv_prod_desc 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_shopordhead.part_code 

	DISPLAY fv_prod_desc TO prod_desc 

	SELECT * 
	INTO fr_workcentre.* 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 

	SELECT sum(rate_amt) 
	INTO fv_variable_rate 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 
	AND rate_ind = "V" 

	SELECT sum(rate_amt) 
	INTO fv_fixed_rate 
	FROM workctrrate 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 
	AND rate_ind = "F" 

	INITIALIZE fr_wiprecpt TO NULL 

	SELECT max(end_date) 
	INTO fr_wiprecpt.start_date 
	FROM wipreceipt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 
	AND shop_order_num = fr_shoporddetl.shop_order_num 
	AND suffix_num = fr_shoporddetl.suffix_num 
	AND sequence_num = fr_shoporddetl.sequence_num 
	AND part_code = fr_shopordhead.part_code 
	GROUP BY sequence_num 

	IF status = notfound THEN 
		LET fv_first = true 
		LET fr_wiprecpt.start_date = fr_shopordhead.actual_start_date 
		LET fr_wiprecpt.start_time = fr_shoporddetl.start_time 
	ELSE 
		SELECT max(end_time) 
		INTO fr_wiprecpt.start_time 
		FROM wipreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND work_centre_code = fr_shoporddetl.work_centre_code 
		AND shop_order_num = fr_shoporddetl.shop_order_num 
		AND suffix_num = fr_shoporddetl.suffix_num 
		AND sequence_num = fr_shoporddetl.sequence_num 
		AND part_code = fr_shopordhead.part_code 
		AND end_date = fr_wiprecpt.start_date 
	END IF 

	INPUT BY NAME fr_wiprecpt.type_ind, 
	fr_wiprecpt.receipt_qty, 
	fr_wiprecpt.cost_amt, 
	fr_wiprecpt.price_amt, 
	fr_wiprecpt.start_date, 
	fr_wiprecpt.start_time, 
	fr_wiprecpt.end_date, 
	fr_wiprecpt.end_time, 
	fr_wiprecpt.status_ind, 
	fr_wiprecpt.desc_text 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD type_ind 
			IF fr_wiprecpt.type_ind IS NULL THEN 
				ERROR "Receipt type must be entered" 

				NEXT FIELD type_ind 
			END IF 

			IF fr_wiprecpt.type_ind NOT matches "[TMC]" THEN 
				ERROR "Invalid receipt type" 

				NEXT FIELD type_ind 
			END IF 

			IF fr_workcentre.count_centre_ind = "P" 
			AND fr_wiprecpt.type_ind = "T" THEN 
				ERROR "Cannot receipt time - Work centre IS a count point FOR ", 
				"products" 

				NEXT FIELD type_ind 
			END IF 

			IF fr_workcentre.count_centre_ind = "T" 
			AND fr_wiprecpt.type_ind = "M" THEN 
				ERROR "Cannot receipt materials - Work centre IS a count point", 
				" FOR time" 

				NEXT FIELD type_ind 
			END IF 

			CASE fr_wiprecpt.type_ind 
				WHEN "T" 
					DISPLAY "Time" TO type_desc 

					IF fr_workcentre.processing_ind = "T" THEN 
						LET fr_wiprecpt.required_qty = fr_shopordhead.order_qty 
						* fr_shoporddetl.oper_factor_amt 
						* fr_workcentre.time_qty 
					ELSE 
						LET fr_wiprecpt.required_qty = (fr_shopordhead.order_qty 
						* fr_shoporddetl.oper_factor_amt) 
						/ fr_workcentre.time_qty 
					END IF 

					SELECT sum(receipt_qty) 
					INTO fr_wiprecpt.receipted_qty 
					FROM wipreceipt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_shoporddetl.work_centre_code 
					AND shop_order_num = fr_shoporddetl.shop_order_num 
					AND suffix_num = fr_shoporddetl.suffix_num 
					AND sequence_num = fr_shoporddetl.sequence_num 
					AND part_code = fr_shopordhead.part_code 
					AND type_ind = "T" 

					IF fr_wiprecpt.receipted_qty IS NULL THEN 
						LET fr_wiprecpt.receipted_qty = 0 
					END IF 

					LET fv_remain_qty = fr_wiprecpt.required_qty - 
					fr_wiprecpt.receipted_qty 
					LET fr_wiprecpt.uom_code = fr_workcentre.time_unit_ind 

					CASE fr_wiprecpt.uom_code 
						WHEN "D" 
							DISPLAY "Days" TO uom_desc 
						WHEN "H" 
							DISPLAY "Hours" TO uom_desc 
						WHEN "M" 
							DISPLAY "Minutes" TO uom_desc 
					END CASE 

				WHEN "M" 
					DISPLAY "Materials", "" TO type_desc, uom_desc 
					LET fr_wiprecpt.required_qty = fr_shoporddetl.required_qty 
					LET fr_wiprecpt.receipted_qty = fr_shoporddetl.receipted_qty 
					LET fr_wiprecpt.uom_code = fr_workcentre.unit_uom_code 
					LET fv_remain_qty = fr_wiprecpt.required_qty - 
					fr_wiprecpt.receipted_qty 

				WHEN "C" 
					DISPLAY "Costs", "" TO type_desc, uom_desc 
					LET fr_wiprecpt.required_qty = NULL 
					LET fr_wiprecpt.receipted_qty = NULL 
					LET fr_wiprecpt.receipt_qty = NULL 
					LET fr_wiprecpt.uom_code = NULL 
			END CASE 

			IF fr_wiprecpt.receipt_qty IS NULL THEN 
				IF fr_wiprecpt.receipted_qty < fr_wiprecpt.required_qty THEN 
					LET fr_wiprecpt.receipt_qty = fr_wiprecpt.required_qty - 
					fr_wiprecpt.receipted_qty 
				END IF 
			END IF 

			DISPLAY BY NAME fr_wiprecpt.required_qty, 
			fr_wiprecpt.receipted_qty, 
			fr_wiprecpt.receipt_qty, 
			fr_wiprecpt.uom_code 

			IF fr_wiprecpt.type_ind = "C" 
			AND fgl_lastkey() != fgl_keyval("up") 
			AND fgl_lastkey() != fgl_keyval("left") THEN 
				NEXT FIELD cost_amt 
			END IF 

		AFTER FIELD receipt_qty 
			IF fr_wiprecpt.receipt_qty IS NULL THEN 
				ERROR "Quantity TO receipt must be entered" 

				NEXT FIELD receipt_qty 
			END IF 

			IF fr_wiprecpt.receipt_qty <= 0 THEN 
				ERROR "Quantity TO receipt must be greater than 0" 

				NEXT FIELD receipt_qty 
			END IF 

		BEFORE FIELD cost_amt 
			IF fr_wiprecpt.cost_amt IS NULL THEN 
				CASE fr_wiprecpt.type_ind 
					WHEN "M" 
						IF fr_workcentre.processing_ind = "T" THEN 
							LET fr_wiprecpt.cost_amt = fv_variable_rate * 
							fr_wiprecpt.receipt_qty 
						ELSE 
							LET fr_wiprecpt.cost_amt = (fv_variable_rate / 
							fr_workcentre.time_qty) * 
							fr_wiprecpt.receipt_qty 
						END IF 

					WHEN "T" 
						IF fr_workcentre.processing_ind = "Q" THEN 
							LET fr_wiprecpt.cost_amt = fv_variable_rate * 
							fr_wiprecpt.receipt_qty 
						ELSE 
							LET fr_wiprecpt.cost_amt = (fv_variable_rate / 
							fr_workcentre.time_qty) *fr_wiprecpt.receipt_qty 
						END IF 

					WHEN "C" 
						LET fr_wiprecpt.cost_amt = fv_fixed_rate 
				END CASE 

				DISPLAY BY NAME fr_wiprecpt.cost_amt 
			END IF 

		AFTER FIELD cost_amt 
			IF fr_wiprecpt.cost_amt IS NULL THEN 
				ERROR "Cost amount must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD cost_amt 
			END IF 

			IF fr_wiprecpt.cost_amt < 0 THEN 
				ERROR "Cost amount cannot be less than 0" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD cost_amt 
			END IF 

			IF fr_wiprecpt.type_ind = "C" THEN 
				IF fr_wiprecpt.cost_amt = 0 THEN 
					ERROR "Cost amount must be greater than 0" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD cost_amt 
				END IF 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD type_ind 
				END IF 
			END IF 

		BEFORE FIELD price_amt 
			IF fr_wiprecpt.price_amt IS NULL THEN 
				LET fr_wiprecpt.price_amt = fr_wiprecpt.cost_amt * (1 + 
				(fr_workcentre.cost_markup_per / 100)) 
				DISPLAY BY NAME fr_wiprecpt.price_amt 
			END IF 

		AFTER FIELD price_amt 
			IF fr_wiprecpt.price_amt IS NULL THEN 
				ERROR "Price amount must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD price_amt 
			END IF 

			IF fr_wiprecpt.price_amt < 0 THEN 
				ERROR "Price amount cannot be less than 0" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD price_amt 
			END IF 

		AFTER FIELD start_date 
			IF fr_wiprecpt.start_date IS NULL THEN 
				ERROR "Receipt start date must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_date 
			END IF 

			IF fr_wiprecpt.start_date < fr_shopordhead.actual_start_date THEN 
				ERROR "Start date cannot be earlier than the shop ORDER start ", 
				"date" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD start_time 
			IF fr_wiprecpt.start_time IS NULL THEN 
				ERROR "Receipt start time must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_time 
			END IF 

			IF fr_wiprecpt.start_time < fr_workcentre.oper_start_time 
			OR fr_wiprecpt.start_time > fr_workcentre.oper_end_time THEN 
				ERROR "Start time IS outside the operation hours FOR this work", 
				" centre" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_time 
			END IF 

			IF NOT fv_first THEN 
				SELECT work_centre_code 
				FROM wipreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = fr_shoporddetl.work_centre_code 
				AND shop_order_num = fr_shoporddetl.shop_order_num 
				AND suffix_num = fr_shoporddetl.suffix_num 
				AND sequence_num = fr_shoporddetl.sequence_num 
				AND part_code = fr_shopordhead.part_code 
				AND start_date = fr_wiprecpt.start_date 
				AND start_time = fr_wiprecpt.start_time 

				IF status != notfound THEN 
					ERROR "Start date AND time already exist" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD start_date 
				END IF 
			END IF 

		BEFORE FIELD end_date 
			IF fr_wiprecpt.end_date IS NULL THEN 
				CASE fr_wiprecpt.type_ind 
					WHEN "T" 
						CALL calc_end_date(fr_workcentre.*, 
						fr_wiprecpt.receipt_qty, 
						fr_wiprecpt.start_date, 
						fr_wiprecpt.start_time) 
						RETURNING fr_wiprecpt.end_date, fr_wiprecpt.end_time 

					WHEN "M" 
						IF fr_workcentre.processing_ind = "T" THEN 
							CALL calc_end_date(fr_workcentre.*, 
							fr_wiprecpt.receipt_qty * 
							fr_workcentre.time_qty, 
							fr_wiprecpt.start_date, 
							fr_wiprecpt.start_time) 
							RETURNING fr_wiprecpt.end_date, 
							fr_wiprecpt.end_time 
						ELSE 
							CALL calc_end_date(fr_workcentre.*, 
							fr_wiprecpt.receipt_qty / 
							fr_workcentre.time_qty, 
							fr_wiprecpt.start_date, 
							fr_wiprecpt.start_time) 
							RETURNING fr_wiprecpt.end_date, 
							fr_wiprecpt.end_time 
						END IF 

					WHEN "C" 
						LET fr_wiprecpt.end_date = fr_wiprecpt.start_date 
						LET fr_wiprecpt.end_time = fr_wiprecpt.start_time 
				END CASE 

				DISPLAY BY NAME fr_wiprecpt.end_date, 
				fr_wiprecpt.end_time 
			END IF 

		AFTER FIELD end_date 
			IF fr_wiprecpt.end_date IS NULL THEN 
				ERROR "Receipt END date must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_date 
			END IF 

			IF fr_wiprecpt.end_date < fr_wiprecpt.start_date THEN 
				ERROR "Receipt END date cannot be earlier than the start date" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_date 
			END IF 

		AFTER FIELD end_time 
			IF fr_wiprecpt.end_time IS NULL THEN 
				ERROR "Receipt END time must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_time 
			END IF 

			IF fr_wiprecpt.end_time < fr_workcentre.oper_start_time 
			OR fr_wiprecpt.end_time > fr_workcentre.oper_end_time THEN 
				ERROR "END time IS outside the operation hours FOR this work", 
				" centre" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_time 
			END IF 

			IF fr_wiprecpt.start_date = fr_wiprecpt.end_date 
			AND fr_wiprecpt.end_time <= fr_wiprecpt.start_time THEN 
				ERROR "Receipt END time must be later than the start time" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_time 
			END IF 

		BEFORE FIELD status_ind 
			IF fr_wiprecpt.status_ind IS NULL THEN 
				IF fr_wiprecpt.type_ind != "C" 
				AND fr_wiprecpt.receipted_qty + fr_wiprecpt.receipt_qty >= 
				fr_wiprecpt.required_qty THEN 
					LET fr_wiprecpt.status_ind = "C" 
				ELSE 
					LET fr_wiprecpt.status_ind = "I" 
				END IF 

				DISPLAY BY NAME fr_wiprecpt.status_ind 
			END IF 

		AFTER FIELD status_ind 
			IF fr_wiprecpt.status_ind IS NULL THEN 
				ERROR "Work centre STATUS must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD status_ind 
			END IF 

			IF fr_wiprecpt.status_ind NOT matches "[IC]" THEN 
				ERROR "Invalid work centre STATUS" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD status_ind 
			END IF 

			IF fr_wiprecpt.status_ind = "I" THEN 
				DISPLAY "Incomplete" TO status_desc 
			ELSE 
				DISPLAY "Complete" TO status_desc 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT INPUT 
			END IF 

			IF fr_wiprecpt.receipt_qty IS NULL 
			AND fr_wiprecpt.type_ind != "C" THEN 
				ERROR "Quantity TO receipt must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fr_wiprecpt.cost_amt IS NULL THEN 
				ERROR "Cost amount must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD cost_amt 
			END IF 

			IF fr_wiprecpt.price_amt IS NULL THEN 
				ERROR "Price amount must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD price_amt 
			END IF 

			IF fr_wiprecpt.start_date IS NULL THEN 
				ERROR "Receipt start date must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_date 
			END IF 

			IF fr_wiprecpt.start_time IS NULL THEN 
				ERROR "Receipt start time must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD start_time 
			END IF 

			IF NOT fv_first THEN 
				SELECT work_centre_code 
				FROM wipreceipt 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = fr_shoporddetl.work_centre_code 
				AND shop_order_num = fr_shoporddetl.shop_order_num 
				AND suffix_num = fr_shoporddetl.suffix_num 
				AND sequence_num = fr_shoporddetl.sequence_num 
				AND part_code = fr_shopordhead.part_code 
				AND start_date = fr_wiprecpt.start_date 
				AND start_time = fr_wiprecpt.start_time 

				IF status != notfound THEN 
					ERROR "Start date AND time already exist" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD start_date 
				END IF 
			END IF 

			IF fr_wiprecpt.end_date IS NULL THEN 
				ERROR "Receipt END date must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_date 
			END IF 

			IF fr_wiprecpt.end_date < fr_wiprecpt.start_date THEN 
				ERROR "Receipt END date cannot be earlier than the start date" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_date 
			END IF 

			IF fr_wiprecpt.end_time IS NULL THEN 
				ERROR "Receipt END time must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_time 
			END IF 

			IF fr_wiprecpt.start_date = fr_wiprecpt.end_date 
			AND fr_wiprecpt.end_time <= fr_wiprecpt.start_time THEN 
				ERROR "Receipt END time must be later than the start time" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD end_time 
			END IF 

			IF fr_wiprecpt.status_ind IS NULL THEN 
				ERROR "Work centre STATUS must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD status_ind 
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
				### Update shoporddetl table
				###

				IF fr_wiprecpt.type_ind = "M" THEN 
					LET fr_shoporddetl.receipted_qty = fr_shoporddetl.receipted_qty 
					+ fr_wiprecpt.receipt_qty 
				END IF 

				IF fv_first THEN 
					LET fr_shoporddetl.actual_start_date = fr_wiprecpt.start_date 
					LET fr_shoporddetl.actual_start_time = fr_wiprecpt.start_time 
				END IF 

				LET fr_shoporddetl.act_act_cost_amt = 
				fr_shoporddetl.act_act_cost_amt + fr_wiprecpt.cost_amt 
				LET fr_shoporddetl.act_price_amt = 
				fr_shoporddetl.act_price_amt + fr_wiprecpt.price_amt 
				LET fr_shoporddetl.actual_end_date = fr_wiprecpt.end_date 
				LET fr_shoporddetl.actual_end_time = fr_wiprecpt.end_time 
				LET fr_shoporddetl.last_change_date = today 
				LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_shoporddetl.last_program_text = "M46" 
				LET err_message = "M46 - Update of shoporddetl failed" 

				UPDATE shoporddetl 
				SET * = fr_shoporddetl.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_shoporddetl.shop_order_num 
				AND suffix_num = fr_shoporddetl.suffix_num 
				AND sequence_num = fr_shoporddetl.sequence_num 

				###
				### Update shopordhead table
				###

				IF fr_wiprecpt.type_ind = "C" 
				OR fr_wiprecpt.cost_amt > 0 
				OR fr_wiprecpt.price_amt > 0 THEN 

					IF fr_shopordhead.status_ind = "H" THEN 
						LET fr_shopordhead.status_ind = "R" 
						LET fr_shopordhead.release_date = fr_wiprecpt.start_date 
						LET fr_shopordhead.actual_start_date =fr_wiprecpt.start_date 
					END IF 

					LET fr_shopordhead.act_est_cost_amt = fr_wiprecpt.cost_amt + 
					fr_shopordhead.act_est_cost_amt 
					LET fr_shopordhead.act_wgted_cost_amt = fr_wiprecpt.cost_amt + 
					fr_shopordhead.act_wgted_cost_amt 
					LET fr_shopordhead.act_act_cost_amt = fr_wiprecpt.cost_amt + 
					fr_shopordhead.act_act_cost_amt 
					LET fr_shopordhead.act_price_amt = fr_wiprecpt.price_amt + 
					fr_shopordhead.act_price_amt 
					LET fr_shopordhead.last_change_date = today 
					LET fr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
					LET fr_shopordhead.last_program_text = "M46" 
					LET err_message = "M46 - Update of shopordhead failed" 

					UPDATE shopordhead 
					SET * = fr_shopordhead.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = fr_shopordhead.shop_order_num 
					AND suffix_num = fr_shopordhead.suffix_num 
				END IF 

				###
				### Insert row INTO wipreceipt table
				###

				LET fr_wipreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET fr_wipreceipt.work_centre_code = fr_shoporddetl.work_centre_code 
				LET fr_wipreceipt.shop_order_num = fr_shoporddetl.shop_order_num 
				LET fr_wipreceipt.suffix_num = fr_shoporddetl.suffix_num 
				LET fr_wipreceipt.sequence_num = fr_shoporddetl.sequence_num 
				LET fr_wipreceipt.part_code = fr_shopordhead.part_code 
				LET fr_wipreceipt.start_date = fr_wiprecpt.start_date 
				LET fr_wipreceipt.start_time = fr_wiprecpt.start_time 
				LET fr_wipreceipt.end_date = fr_wiprecpt.end_date 
				LET fr_wipreceipt.end_time = fr_wiprecpt.end_time 
				LET fr_wipreceipt.type_ind = fr_wiprecpt.type_ind 
				LET fr_wipreceipt.receipt_qty = fr_wiprecpt.receipt_qty 
				LET fr_wipreceipt.uom_code = fr_wiprecpt.uom_code 
				LET fr_wipreceipt.cost_amt = fr_wiprecpt.cost_amt 
				LET fr_wipreceipt.price_amt = fr_wiprecpt.price_amt 
				LET fr_wipreceipt.status_ind = fr_wiprecpt.status_ind 
				LET fr_wipreceipt.desc_text = fr_wiprecpt.desc_text 
				LET fr_wipreceipt.last_change_date = today 
				LET fr_wipreceipt.last_user_text = glob_rec_kandoouser.sign_on_code 
				LET fr_wipreceipt.last_program_text = "M46" 
				LET err_message = "M46 - Insert INTO wipreceipt failed" 

				INSERT INTO wipreceipt VALUES (fr_wipreceipt.*) 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	CLOSE WINDOW w2_m183 

END FUNCTION 



FUNCTION calc_end_date(fr_workcentre, fv_time_qty, fv_end_date, fv_end_time) 

	DEFINE fv_day_length INTERVAL hour TO second, 
	fv_cnt SMALLINT, 
	fv_days_qty SMALLINT, 
	fv_dy_hrs SMALLINT, 
	fv_dy_mins SMALLINT, 
	fv_hrs_length FLOAT, 
	fv_mins_length SMALLINT, 
	fv_length_char CHAR(9), 
	fv_time_left INTERVAL hour TO second, 
	fv_time_qty LIKE wipreceipt.receipt_qty, 
	fv_end_date LIKE wipreceipt.end_date, 
	fv_end_time LIKE wipreceipt.end_time, 
	fr_workcentre RECORD LIKE workcentre.* 


	LET fv_day_length = fr_workcentre.oper_end_time - 
	fr_workcentre.oper_start_time 
	LET fv_length_char = fv_day_length 
	LET fv_dy_hrs = fv_length_char[2,3] 
	LET fv_dy_mins = fv_length_char[5,6] 
	LET fv_hrs_length = fv_dy_hrs + (fv_dy_mins / 60) 
	LET fv_mins_length = (fv_dy_hrs * 60) + fv_dy_mins 

	CASE fr_workcentre.time_unit_ind 
		WHEN "D" 
			LET fv_days_qty = fv_time_qty 
			LET fv_time_left = fv_day_length * (fv_time_qty - fv_days_qty) 

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
	AND fv_end_time = fr_workcentre.oper_start_time THEN 
		LET fv_end_time = fr_workcentre.oper_end_time 
		LET fv_days_qty = fv_days_qty - 1 
	END IF 

	FOR fv_cnt = 1 TO fv_days_qty 
		LET fv_end_date = fv_end_date + 1 
		CALL check_date(fv_end_date) 
		RETURNING fv_end_date 
	END FOR 

	IF (fr_workcentre.oper_end_time - fv_end_time) >= fv_time_left THEN 
		LET fv_end_time = fv_end_time + fv_time_left 
	ELSE 
		LET fv_end_date = fv_end_date + 1 
		CALL check_date(fv_end_date) 
		RETURNING fv_end_date 
		LET fv_end_time = fr_workcentre.oper_start_time + fv_time_left - 
		(fr_workcentre.oper_end_time - fv_end_time) 
	END IF 

	RETURN fv_end_date, fv_end_time 

END FUNCTION 



FUNCTION check_date(fv_latest_date) 

	DEFINE fv_latest_date DATE, 
	#fv_avail_ind   LIKE calendar.available_ind
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

		LET fv_latest_date = fv_latest_date + 1 

	END WHILE 

END FUNCTION 
