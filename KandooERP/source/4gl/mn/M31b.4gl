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

	Source code beautified by beautify.pl on 2020-01-02 17:31:23	$Id: $
}


# Purpose - Shop Order Add - Item type entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M31.4gl" 


FUNCTION input_shoporddetl(fv_desc_text) 

	DEFINE fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_scrn SMALLINT, 
	fv_seq_num SMALLINT, 
	fv_seq_cnt SMALLINT, 
	fv_insert SMALLINT, 
	fv_delete SMALLINT, 
	fv_image SMALLINT, 
	fv_image_part_code LIKE bor.parent_part_code, 
	fv_parent_code LIKE bor.parent_part_code, 
	fv_type_ind LIKE bor.type_ind, 
	fv_desc_text LIKE product.desc_text, 
	fv_unit_cost_amt LIKE shopordhead.std_est_cost_amt, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_def_ware_code LIKE prodmfg.def_ware_code, 
	fv_add_qty LIKE prodstatus.onord_qty, 
	fv_end_date LIKE shopordhead.end_date, 

	fr_bor RECORD LIKE bor.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.* 


	LET pv_config = false 
	LET pv_end = false 
	LET pv_ext_cost_amt = 0 
	LET pv_cnt = 0 
	INITIALIZE pa_shoporddetl, pa_scrn_sodetl TO NULL 

	LET fv_parent_code = pr_shopordhead.part_code 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = pr_shopordhead.part_code 
	ORDER BY sequence_num 

	FOREACH c_child INTO fr_bor.* 
		IF fr_bor.start_date > pr_shopordhead.end_date 
		OR fr_bor.end_date < pr_shopordhead.start_date THEN 
			CONTINUE FOREACH 
		END IF 

		IF fr_bor.type_ind matches "[CB]" THEN 
			SELECT part_type_ind, man_uom_code 
			INTO fv_part_type_ind, fv_man_uom_code 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			LET fr_bor.required_qty = fr_bor.required_qty * 
			pr_shopordhead.order_qty 

			IF fv_part_type_ind matches "[GP]" THEN 
				IF fv_part_type_ind = "P" THEN 
					CALL load_detl_array(fr_bor.*, "", fv_part_type_ind, 
					fv_man_uom_code) 
				END IF 

				CALL expand(fr_bor.part_code, fv_part_type_ind, 
				fr_bor.required_qty, fr_bor.parent_part_code) 

				IF int_flag OR quit_flag THEN 
					CLOSE WINDOW w3_m133 
					RETURN 
				END IF 

				IF pv_cnt = 2000 THEN 
					LET msgresp = kandoomsg("M", 9783, "") 
					# ERROR "Only the first 2000 items were selected"
					EXIT FOREACH 
				END IF 

				CONTINUE FOREACH 
			END IF 
		ELSE 
			LET fv_part_type_ind = NULL 
		END IF 

		CALL load_detl_array(fr_bor.*, "", fv_part_type_ind, fv_man_uom_code) 

		IF pv_cnt = 2000 THEN 
			LET msgresp = kandoomsg("M", 9783, "") 
			# ERROR "Only the first 2000 items were selected"
			EXIT FOREACH 
		END IF 

	END FOREACH 
	FREE c_child 

	LET pv_arr_size = pv_cnt 
	LET fv_unit_cost_amt = pv_ext_cost_amt / pr_shopordhead.order_qty 

	IF pv_config THEN 
		LET pv_config = false 
		CLOSE WINDOW w3_m133 
	END IF 

	OPEN WINDOW w4_m132 with FORM "M132" 
	CALL  windecoration_m("M132") -- albo kd-762 

	DISPLAY BY NAME pr_shopordhead.part_code, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.uom_code 

	DISPLAY fv_desc_text TO product.desc_text 

	WHILE true 
		LET msgresp = kandoomsg("M", 1533, "") 
		# MESSAGE "F1 Insert, F2 Delete, RETURN Add/Edit, F9 Image, ESC Accept"

		LET fv_delete = false 
		LET fv_image = false 
		CALL set_count(pv_arr_size) 

		DISPLAY fv_unit_cost_amt, pv_ext_cost_amt 
		TO unit_cost_amt, ext_cost_amt 

		INPUT ARRAY pa_scrn_sodetl WITHOUT DEFAULTS 
		FROM sr_shoporddetl.* 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET fv_idx = arr_curr() 
				LET fv_scrn = scr_line() 
				LET pv_arr_size = arr_count() 
				LET fv_insert = false 

			BEFORE INSERT 
				LET fv_insert = true 
				LET pv_arr_size = arr_count() 

			BEFORE DELETE 
				IF fv_idx = 1 AND NOT fv_insert AND 
				(pv_arr_size = 1 OR 
				(pv_arr_size = 2 AND pa_scrn_sodetl[2].sequence_num IS null)) 
				THEN 
					LET msgresp = kandoomsg("M", 9784, "") 
					# ERROR "There must be AT least one detail line on the so"
					LET fv_delete = true 
					LET pv_cnt = 1 
					EXIT INPUT 
				END IF 

				IF pa_scrn_sodetl[fv_idx].sequence_num IS NOT NULL THEN 
					LET fv_seq_num = pa_scrn_sodetl[fv_idx].sequence_num 

					IF pa_scrn_sodetl[fv_idx].component_type_ind = "P" 
					AND pa_shoporddetl[fv_seq_num].cost_type_ind IS NULL THEN 
						LET msgresp = kandoomsg("M", 4502, "") 
						# prompt "All children of this phantom will also be
						# deleted"
						# "Do you still wish TO proceed with the delete (Y/N)?"

						IF msgresp = "Y" THEN 
							CALL delete_phantom(fv_idx) 

							LET fv_unit_cost_amt = pv_ext_cost_amt / 
							pr_shopordhead.order_qty 
						END IF 

						LET fv_delete = true 
						EXIT INPUT 
					ELSE 
						CALL reduce_total(fv_seq_num) 

						LET fv_unit_cost_amt = pv_ext_cost_amt / 
						pr_shopordhead.order_qty 
						DISPLAY fv_unit_cost_amt, pv_ext_cost_amt 
						TO unit_cost_amt, ext_cost_amt 

						INITIALIZE pa_shoporddetl[fv_seq_num].* TO NULL 
					END IF 
				END IF 

			BEFORE FIELD type_ind 
				IF fv_idx > 1 AND pa_scrn_sodetl[fv_idx].type_ind IS NULL THEN 
					LET pa_scrn_sodetl[fv_idx].type_ind = 
					pa_scrn_sodetl[fv_idx - 1].type_ind 
					DISPLAY pa_scrn_sodetl[fv_idx].type_ind 
					TO sr_shoporddetl[fv_scrn].type_ind 
				END IF 

			AFTER FIELD type_ind 
				IF fgl_lastkey() != fgl_keyval("accept") THEN 
					IF pa_scrn_sodetl[fv_idx].type_ind IS NULL THEN 
						IF fgl_lastkey() != fgl_keyval("up") 
						OR fv_idx < pv_arr_size 
						OR (fv_idx = pv_arr_size 
						AND pa_scrn_sodetl[fv_idx].sequence_num IS NOT null) 
						THEN 
							LET msgresp = kandoomsg("M", 9573, "") 
							# ERROR "Item type must be entered"
							NEXT FIELD type_ind 
						END IF 
					ELSE 
						IF pa_scrn_sodetl[fv_idx].type_ind NOT matches 
						"[CISWUB]" THEN 
							LET msgresp = kandoomsg("M", 9574, "") 
							# ERROR "Invalid item type"
							NEXT FIELD type_ind 
						END IF 

						IF pa_scrn_sodetl[fv_idx].sequence_num IS NULL THEN 
							LET msgresp = kandoomsg("M", 9575, "") 
							# ERROR "Item details must be entered first"
							NEXT FIELD type_ind 
						END IF 
					END IF 
				END IF 

			ON KEY (RETURN) 
				LET fv_type_ind = get_fldbuf(sr_shoporddetl.type_ind) 

				IF fv_type_ind matches "[CISWUB]" THEN 
					INITIALIZE pr_shoporddetl TO NULL 

					IF pa_scrn_sodetl[fv_idx].sequence_num IS NOT NULL 
					AND pa_scrn_sodetl[fv_idx].sequence_num != 0 THEN 
						IF fv_type_ind != pa_scrn_sodetl[fv_idx].type_ind THEN 
							LET msgresp = kandoomsg("M", 9577, "") 
							# ERROR "Item type cannot be changed"
							NEXT FIELD type_ind 
						END IF 

						LET fv_seq_num = pa_scrn_sodetl[fv_idx].sequence_num 

						IF pa_scrn_sodetl[fv_idx].component_type_ind = "P" AND 
						pa_shoporddetl[fv_seq_num].cost_type_ind IS NULL THEN 
							LET msgresp = kandoomsg("M", 9785, "") 
							# ERROR "You cannot edit this phantom component -
							#        edit its children instead"
							NEXT FIELD type_ind 
						END IF 

						LET pr_shoporddetl.* = pa_shoporddetl[fv_seq_num].* 
					ELSE 
						LET pr_shoporddetl.type_ind = fv_type_ind 
						LET pa_shoporddetl[pv_cnt + 1].std_est_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt + 1].std_wgted_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt + 1].std_act_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt + 1].act_est_cost_amt = 0 
						LET pa_shoporddetl[pv_cnt + 1].required_qty = 0 
					END IF 

					CASE fv_type_ind 
						WHEN "C" 
							LET pr_shoporddetl.desc_text = 
							pa_scrn_sodetl[fv_idx].desc_text 
							CALL component_input() RETURNING fv_type_ind 
						WHEN "B" 
							LET pr_shoporddetl.desc_text = 
							pa_scrn_sodetl[fv_idx].desc_text 
							CALL component_input() RETURNING fv_type_ind 
						WHEN "I" 
							CALL instruct_input() 
						WHEN "S" 
							CALL cost_input() 
						WHEN "W" 
							CALL workcentre_input() 
						WHEN "U" 
							CALL setup_input() 
					END CASE 

					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						INITIALIZE pr_shoporddetl TO NULL 
					ELSE 
						LET pa_scrn_sodetl[fv_idx].desc_text = 
						pr_shoporddetl.desc_text 

						IF pr_shoporddetl.type_ind != "U" THEN 
							LET pa_scrn_sodetl[fv_idx].required_qty = 
							pr_shoporddetl.required_qty 
						END IF 

						IF pr_shoporddetl.type_ind matches "[CB]" THEN 
							LET pa_scrn_sodetl[fv_idx].component_type_ind = 
							fv_type_ind 

							IF fv_type_ind = "P" THEN 
								LET pr_shoporddetl.cost_type_ind = "U" 
							END IF 
							# This indicates that this phantom IS unexploded

							LET pr_shoporddetl.desc_text = NULL 
							LET pa_scrn_sodetl[fv_idx].part_code = 
							pr_shoporddetl.part_code 
						END IF 

						IF pa_scrn_sodetl[fv_idx].sequence_num IS NULL THEN 
							LET pv_cnt = pv_cnt + 1 
							LET pr_shoporddetl.sequence_num = pv_cnt 
							LET pr_shoporddetl.parent_part_code = 
							pr_shopordhead.part_code 
							LET pa_scrn_sodetl[fv_idx].type_ind = 
							pr_shoporddetl.type_ind 
							LET pa_scrn_sodetl[fv_idx].sequence_num = 
							pr_shoporddetl.sequence_num 
							LET fv_seq_num = pv_cnt 

							CASE pr_shoporddetl.type_ind 
								WHEN "I" 
									LET pa_scrn_sodetl[fv_idx].part_code = 
									kandooword("INSTRUCTION", "M14") 

								WHEN "S" 
									LET pa_scrn_sodetl[fv_idx].part_code = 
									kandooword("COST", "M15") 

								WHEN "W" 
									LET pa_scrn_sodetl[fv_idx].part_code = 
									pr_shoporddetl.work_centre_code 

								WHEN "U" 
									LET pa_scrn_sodetl[fv_idx].part_code = 
									kandooword("SET UP", "M17") 
							END CASE 
						END IF 

						IF pr_shoporddetl.type_ind != "I" THEN 
							CALL update_totals(fv_idx, fv_seq_num) 
						END IF 

						LET pa_shoporddetl[fv_seq_num].* = pr_shoporddetl.* 

						LET fv_unit_cost_amt = pv_ext_cost_amt / 
						pr_shopordhead.order_qty 
						DISPLAY fv_unit_cost_amt, pv_ext_cost_amt 
						TO unit_cost_amt, ext_cost_amt 

						DISPLAY pa_scrn_sodetl[fv_idx].* 
						TO sr_shoporddetl[fv_scrn].* 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("M", 9574, "") 
					# ERROR "Invalid item type"
				END IF 

			ON KEY (f9) 
				CALL bor_image(glob_rec_kandoouser.cmpy_code) RETURNING fv_image_part_code 

				IF fv_image_part_code IS NULL THEN 
					NEXT FIELD type_ind 
				END IF 

				LET fv_image = true 
				CLEAR sr_shoporddetl.* 
				INITIALIZE pa_scrn_sodetl, pa_shoporddetl TO NULL 
				LET pv_ext_cost_amt = 0 
				LET pv_cnt = 0 

				DECLARE c_image CURSOR FOR 
				SELECT * 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_image_part_code 
				ORDER BY sequence_num 

				FOREACH c_image INTO fr_bor.* 

					IF fr_bor.start_date > pr_shopordhead.end_date 
					OR fr_bor.end_date < pr_shopordhead.start_date THEN 
						CONTINUE FOREACH 
					END IF 

					IF fr_bor.type_ind matches "[CB]" THEN 
						IF fr_bor.part_code = pr_shopordhead.part_code THEN 
							CONTINUE FOREACH 
						END IF 

						LET fr_bor.required_qty = fr_bor.required_qty * 
						pr_shopordhead.order_qty 

						SELECT part_type_ind, man_uom_code 
						INTO fv_part_type_ind, fv_man_uom_code 
						FROM prodmfg 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fr_bor.part_code 

						IF fv_part_type_ind matches "[GP]" THEN 
							IF fv_part_type_ind = "P" THEN 
								CALL load_detl_array(fr_bor.*, "", 
								fv_part_type_ind, 
								fv_man_uom_code) 
							END IF 

							CALL expand(fr_bor.part_code, fv_part_type_ind, 
							fr_bor.required_qty, 
							fr_bor.parent_part_code) 

							IF int_flag OR quit_flag THEN 
								LET fv_image = false 
								EXIT FOREACH 
							END IF 

							IF pv_cnt = 2000 THEN 
								LET msgresp = kandoomsg("M", 9783, "") 
								#ERROR "Only the first 2000 items were selected"
								EXIT FOREACH 
							END IF 

							CONTINUE FOREACH 
						END IF 
					END IF 

					CALL load_detl_array(fr_bor.*, "", fv_part_type_ind, 
					fv_man_uom_code) 

					IF pv_cnt = 2000 THEN 
						LET msgresp = kandoomsg("M", 9783, "") 
						# ERROR "Only the first 2000 items were selected"
						EXIT FOREACH 
					END IF 

				END FOREACH 
				FREE c_image 

				IF pv_config THEN 
					LET pv_config = false 
					CLOSE WINDOW w3_m133 
				END IF 

				LET fv_unit_cost_amt = pv_ext_cost_amt / 
				pr_shopordhead.order_qty 
				LET pv_arr_size = pv_cnt 

				EXIT INPUT 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				INITIALIZE pa_sodetl_final TO NULL 

				LET pv_cnt1 = 0 
				LET pv_end = true 
				LET pv_phant_cnt = 0 
				LET pv_scost_tot = 0 
				LET pv_wcost_tot = 0 
				LET pv_lcost_tot = 0 
				LET pv_price_tot = 0 

				FOR fv_cnt = 1 TO pv_arr_size 
					IF pa_scrn_sodetl[fv_cnt].sequence_num IS NULL 
					OR pa_scrn_sodetl[fv_cnt].sequence_num = 0 THEN 
						CONTINUE FOR 
					END IF 

					IF pa_scrn_sodetl[fv_cnt].component_type_ind = "P" THEN 
						LET pv_phant_cnt = pv_phant_cnt + 1 
					END IF 

					LET fv_seq_num = pa_scrn_sodetl[fv_cnt].sequence_num 

					IF pa_scrn_sodetl[fv_cnt].component_type_ind = "G" 
					OR (pa_scrn_sodetl[fv_cnt].component_type_ind = "P" 
					AND pa_shoporddetl[fv_seq_num].cost_type_ind = "U") THEN 

						IF pa_scrn_sodetl[fv_cnt].component_type_ind = "P" THEN 
							LET pv_cnt1 = pv_cnt1 + 1 
							LET pa_sodetl_final[pv_cnt1].part_code = 
							pa_shoporddetl[fv_seq_num].part_code 
							LET pa_sodetl_final[pv_cnt1].parent_part_code = 
							pa_shoporddetl[fv_seq_num].parent_part_code 
							LET pa_sodetl_final[pv_cnt1].type_ind = 
							pa_shoporddetl[fv_seq_num].type_ind 
						END IF 

						CALL expand(pa_scrn_sodetl[fv_cnt].part_code, 
						pa_scrn_sodetl[fv_cnt].component_type_ind, 
						pa_scrn_sodetl[fv_cnt].required_qty, 
						pr_shopordhead.part_code) 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							LET fv_image = true 
							EXIT FOR 
						END IF 

						CONTINUE FOR 
					END IF 

					LET pv_cnt1 = pv_cnt1 + 1 
					LET pa_sodetl_final[pv_cnt1].* = 
					pa_shoporddetl[fv_seq_num].* 

					IF pa_sodetl_final[pv_cnt1].type_ind = "B" THEN 
						LET pa_sodetl_final[pv_cnt1].required_qty = 
						- pa_sodetl_final[pv_cnt1].required_qty 
					END IF 

					IF pa_scrn_sodetl[fv_cnt].type_ind != "C" 
					OR pa_scrn_sodetl[fv_cnt].component_type_ind != "P" THEN 
						CALL calc_cost_totals() 
					END IF 

					IF pv_cnt1 = 2000 THEN 
						EXIT FOR 
					END IF 
				END FOR 

				IF pv_config THEN 
					LET pv_config = false 
					CLOSE WINDOW w3_m133 
				END IF 

		END INPUT 

		IF NOT (fv_delete OR fv_image) THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w4_m132 

	IF int_flag OR quit_flag 
	OR pv_cnt1 = 0 OR pv_phant_cnt = pv_cnt1 THEN 
		RETURN 
	END IF 

	LET msgresp = kandoomsg("M", 1534, "") 
	# MESSAGE " Please wait WHILE creating shop ORDER..."

	IF pr_shopordhead.start_date IS NOT NULL THEN 
		LET pv_start = false 
		CALL calc_end_date() 
	ELSE 
		LET pv_start = true 
		LET pr_shopordhead.start_date = today 
		CALL calc_end_date() RETURNING fv_end_date 

		IF fv_end_date != pr_shopordhead.end_date THEN 
			CALL calc_start_date(fv_end_date) 
			LET pv_start = false 
			CALL calc_end_date() 
		END IF 
	END IF 

	LET pr_shopordhead.job_length_num = pr_shopordhead.end_date - 
	pr_shopordhead.start_date + 1 

	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		IF pv_header THEN 
			LET pv_suffix_num = pv_suffix_num + 1 
		END IF 

		IF (not pv_header) OR pv_suffix_num = 1 THEN 
			LET err_message = "M31b - SELECT FROM mnparms failed" 

			SELECT next_order_num 
			INTO pv_shoporder_num 
			FROM mnparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		END IF 

		###
		### Insert shopordhead RECORD & UPDATE on ORDER qty on prodstatus
		###

		LET err_message = "M31b - SELECT FROM prodmfg failed" 

		SELECT * 
		INTO fr_prodmfg.* 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 

		LET pr_shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_shopordhead.shop_order_num = pv_shoporder_num 
		LET pr_shopordhead.suffix_num = pv_suffix_num 
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
		LET pr_shopordhead.last_program_text = "M31" 

		LET err_message = "M31b - Insert INTO shopordhead failed" 

		INSERT INTO shopordhead VALUES (pr_shopordhead.*) 

		LET err_message = "M31b - SELECT FROM product failed" 

		SELECT * 
		INTO fr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 

		CALL uom_convert(pr_shopordhead.order_qty, pr_shopordhead.uom_code, 
		fr_prodmfg.*, fr_product.*) 
		RETURNING fv_add_qty 

		LET err_message = "M31b - Update of prodstatus failed" 

		UPDATE prodstatus 
		SET onord_qty = onord_qty + fv_add_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 
		AND ware_code = fr_prodmfg.def_ware_code 

		###
		### Insert detail lines INTO shoporddetl & UPDATE prodstatus
		###

		FOR fv_cnt = 1 TO pv_cnt1 
			LET pa_sodetl_final[fv_cnt].cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pa_sodetl_final[fv_cnt].shop_order_num = pv_shoporder_num 
			LET pa_sodetl_final[fv_cnt].suffix_num = pv_suffix_num 
			LET pa_sodetl_final[fv_cnt].sequence_num = fv_cnt 
			LET pa_sodetl_final[fv_cnt].last_change_date = today 
			LET pa_sodetl_final[fv_cnt].last_user_text = glob_rec_kandoouser.sign_on_code 
			LET pa_sodetl_final[fv_cnt].last_program_text = "M31" 

			IF pa_sodetl_final[fv_cnt].type_ind matches "[CB]" THEN 
				LET err_message = "M31b - SELECT FROM prodmfg failed" 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pa_sodetl_final[fv_cnt].part_code 

				IF fr_prodmfg.part_type_ind != "P" THEN 
					LET err_message = "M31b - SELECT FROM product failed" 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pa_sodetl_final[fv_cnt].part_code 

					CALL uom_convert(pa_sodetl_final[fv_cnt].required_qty, 
					pa_sodetl_final[fv_cnt].uom_code, 
					fr_prodmfg.*, 
					fr_product.*) 
					RETURNING fv_add_qty 

					LET err_message = "M31b - Update of prodstatus failed" 

					IF pa_sodetl_final[fv_cnt].type_ind = "C" THEN 
						LET pa_sodetl_final[fv_cnt].issued_qty = 0 

						UPDATE prodstatus 
						SET reserved_qty = reserved_qty + fv_add_qty 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_sodetl_final[fv_cnt].part_code 
						AND ware_code = pa_sodetl_final[fv_cnt].issue_ware_code 
					ELSE 
						LET pa_sodetl_final[fv_cnt].receipted_qty = 0 
						LET pa_sodetl_final[fv_cnt].rejected_qty = 0 

						UPDATE prodstatus 
						SET onord_qty = onord_qty - fv_add_qty 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pa_sodetl_final[fv_cnt].part_code 
						AND ware_code = pa_sodetl_final[fv_cnt].issue_ware_code 
					END IF 

					LET pa_sodetl_final[fv_cnt].act_est_cost_amt = 0 
					LET pa_sodetl_final[fv_cnt].act_wgted_cost_amt = 0 
					LET pa_sodetl_final[fv_cnt].act_act_cost_amt = 0 
					LET pa_sodetl_final[fv_cnt].act_price_amt = 0 
				END IF 
			END IF 

			LET err_message = "M31b - Insert INTO shoporddetl failed" 

			INSERT INTO shoporddetl VALUES (pa_sodetl_final[fv_cnt].*) 

		END FOR 

		IF (not pv_header) OR pv_suffix_num = 1 THEN 
			LET err_message = "M31b - Update of mnparms failed" 

			UPDATE mnparms 
			SET next_order_num = pv_shoporder_num + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		END IF 

	COMMIT WORK 
	WHENEVER ERROR stop 

END FUNCTION 



FUNCTION uom_convert(fv_qty, fv_uom_code, fr_prodmfg, fr_product) 

	DEFINE fv_qty LIKE shopordhead.order_qty, 
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



FUNCTION update_totals(fv_idx, fv_seq_num) 

	DEFINE fv_seq_num SMALLINT, 
	fv_idx SMALLINT, 
	fv_setup_qty SMALLINT 


	CASE pr_shoporddetl.type_ind 
		WHEN "S" 
			LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
			pr_shoporddetl.std_est_cost_amt 

			IF pr_shoporddetl.cost_type_ind = "F" THEN 
				LET pr_shoporddetl.act_est_cost_amt = 
				pr_shoporddetl.std_est_cost_amt 
				LET pr_shoporddetl.act_wgted_cost_amt = 
				pr_shoporddetl.std_price_amt 
			ELSE 
				LET pr_shoporddetl.act_est_cost_amt = 
				pr_shoporddetl.std_est_cost_amt * pr_shopordhead.order_qty 
				LET pr_shoporddetl.act_wgted_cost_amt = 
				pr_shoporddetl.std_price_amt * pr_shopordhead.order_qty 
			END IF 

			LET pv_ext_cost_amt = pv_ext_cost_amt - 
			pa_shoporddetl[fv_seq_num].act_est_cost_amt + 
			pr_shoporddetl.act_est_cost_amt 

		WHEN "W" 
			LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
			pr_shoporddetl.std_act_cost_amt / pr_shoporddetl.required_qty 

			LET pv_ext_cost_amt = pv_ext_cost_amt - 
			pa_shoporddetl[fv_seq_num].std_act_cost_amt + 
			pr_shoporddetl.std_act_cost_amt 

		WHEN "U" 
			LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
			pr_shoporddetl.std_est_cost_amt 

			IF pr_shoporddetl.cost_type_ind = "Q" THEN 
				LET fv_setup_qty = pr_shopordhead.order_qty / 
				pr_shoporddetl.var_amt 

				IF (pr_shopordhead.order_qty / pr_shoporddetl.var_amt) > 
				fv_setup_qty THEN 
					LET fv_setup_qty = fv_setup_qty + 1 
				END IF 

				LET pr_shoporddetl.act_est_cost_amt = fv_setup_qty * 
				pr_shoporddetl.std_est_cost_amt 
				LET pr_shoporddetl.act_wgted_cost_amt = fv_setup_qty * 
				pr_shoporddetl.std_price_amt 
			ELSE 
				LET pr_shoporddetl.act_est_cost_amt = 
				pr_shoporddetl.std_est_cost_amt 
				LET pr_shoporddetl.act_wgted_cost_amt = 
				pr_shoporddetl.std_price_amt 
			END IF 

			LET pv_ext_cost_amt = pv_ext_cost_amt - 
			pa_shoporddetl[fv_seq_num].act_est_cost_amt 
			+ pr_shoporddetl.act_est_cost_amt 

		OTHERWISE 
			CASE 
				WHEN pr_inparms.cost_ind = "S" 
					LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
					pr_shoporddetl.std_est_cost_amt 

					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_est_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) + 
					(pr_shoporddetl.std_est_cost_amt * 
					pr_shoporddetl.required_qty) 

				WHEN pr_inparms.cost_ind matches "[WF]" 
					LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
					pr_shoporddetl.std_wgted_cost_amt 

					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_wgted_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) + 
					(pr_shoporddetl.std_wgted_cost_amt * 
					pr_shoporddetl.required_qty) 

				WHEN pr_inparms.cost_ind = "L" 
					LET pa_scrn_sodetl[fv_idx].unit_cost_amt = 
					pr_shoporddetl.std_act_cost_amt 

					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_act_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) + 
					(pr_shoporddetl.std_act_cost_amt * 
					pr_shoporddetl.required_qty) 
			END CASE 
	END CASE 

END FUNCTION 



FUNCTION expand(fv_part_code, fv_type_ind, fv_req_qty, fv_parent_code) 

	DEFINE fv_part_code LIKE shoporddetl.part_code, 
	fv_type_ind LIKE prodmfg.part_type_ind, 
	fv_req_qty LIKE shoporddetl.required_qty, 
	fv_parent_code LIKE shoporddetl.parent_part_code, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_arr_size SMALLINT, 
	fv_cnt SMALLINT, 
	fa_bor array[250] OF RECORD LIKE bor.* 


	INITIALIZE fa_bor TO NULL 

	IF fv_type_ind = "P" THEN 
		DECLARE c_phantom CURSOR FOR 
		SELECT * 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fv_part_code 
		ORDER BY sequence_num 

		LET fv_cnt = 1 

		FOREACH c_phantom INTO fa_bor[fv_cnt].* 
			LET fa_bor[fv_cnt].required_qty = fa_bor[fv_cnt].required_qty * 
			fv_req_qty 

			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt > 250 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		FREE c_phantom 

		LET fv_cnt = fv_cnt - 1 
		LET fv_arr_size = fv_cnt 

		IF fv_arr_size = 0 THEN 
			RETURN 
		END IF 
	ELSE 
		CALL input_configs(fv_part_code, fv_req_qty, "N") RETURNING fv_arr_size 

		IF fv_arr_size > 0 THEN 
			FOR fv_cnt = 1 TO fv_arr_size 
				LET fa_bor[fv_cnt].parent_part_code = fv_parent_code 
				LET fa_bor[fv_cnt].part_code = pa_config[fv_cnt].part_code 
				LET fa_bor[fv_cnt].required_qty = pa_config[fv_cnt].required_qty 
				LET fa_bor[fv_cnt].type_ind = "C" 
			END FOR 
		ELSE 
			RETURN 
		END IF 
	END IF 

	LET fv_cnt = 0 

	WHILE fv_cnt < fv_arr_size 
		LET fv_cnt = fv_cnt + 1 
		LET fv_part_type_ind = NULL 

		IF fa_bor[fv_cnt].type_ind matches "[CB]" THEN 
			SELECT part_type_ind, man_uom_code 
			INTO fv_part_type_ind, fv_man_uom_code 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_bor[fv_cnt].part_code 

			IF fv_part_type_ind matches "[PG]" THEN 
				IF fv_part_type_ind = "P" THEN 
					IF pv_end THEN 
						LET pv_cnt1 = pv_cnt1 + 1 
						LET pv_phant_cnt = pv_phant_cnt + 1 

						CALL get_so_record(fa_bor[fv_cnt].*, fv_part_type_ind) 
						RETURNING pa_sodetl_final[pv_cnt1].* 
					ELSE 
						CALL load_detl_array(fa_bor[fv_cnt].*, "", 
						fv_part_type_ind, fv_man_uom_code) 
					END IF 
				END IF 

				CALL expand(fa_bor[fv_cnt].part_code, fv_part_type_ind, 
				fa_bor[fv_cnt].required_qty, 
				fa_bor[fv_cnt].parent_part_code) 

				IF int_flag OR quit_flag THEN 
					RETURN 
				END IF 

				IF pv_end THEN 
					IF pv_cnt1 = 2000 THEN 
						EXIT WHILE 
					END IF 
				ELSE 
					IF pv_cnt = 2000 THEN 
						EXIT WHILE 
					END IF 
				END IF 

				CONTINUE WHILE 
			END IF 
		END IF 

		IF pv_end THEN 
			LET pv_cnt1 = pv_cnt1 + 1 

			IF fv_type_ind = "G" THEN 
				LET fa_bor[fv_cnt].uom_code = fv_man_uom_code 
			END IF 

			CALL get_so_record(fa_bor[fv_cnt].*, fv_part_type_ind) 
			RETURNING pa_sodetl_final[pv_cnt1].* 

			IF fv_part_type_ind != "P" THEN 
				CALL calc_cost_totals() 
			END IF 

			IF pv_cnt1 = 2000 THEN 
				EXIT WHILE 
			END IF 
		ELSE 
			CALL load_detl_array(fa_bor[fv_cnt].*, fv_type_ind, 
			fv_part_type_ind, fv_man_uom_code) 

			IF pv_cnt = 2000 THEN 
				EXIT WHILE 
			END IF 
		END IF 

	END WHILE 

END FUNCTION 



FUNCTION input_configs(fv_part_code, fv_bor_req_qty, fv_parent) 

	DEFINE fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_cnt2 SMALLINT, 
	fv_idx SMALLINT, 
	fv_total FLOAT, 
	fv_parent CHAR(1), 
	fv_desc_text LIKE product.desc_text, 
	fv_option_num LIKE configuration.option_num, 
	fv_config_ind LIKE configuration.config_ind, 
	fv_required_qty LIKE bor.required_qty, 
	fv_bor_req_qty LIKE bor.required_qty, 
	fv_part_code LIKE bor.part_code, 

	fa_config_specific array[500] OF RECORD 
		required_qty LIKE bor.required_qty, 
		specific_part_code LIKE configuration.specific_part_code, 
		desc_text LIKE product.desc_text 
	END RECORD 

	SELECT unique config_ind, option_num 
	INTO fv_config_ind, fv_option_num 
	FROM configuration 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND generic_part_code = fv_part_code 

	IF status = notfound THEN 
		LET fv_cnt2 = 0 
		RETURN fv_cnt2 
	END IF 

	SELECT desc_text 
	INTO fv_desc_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_part_code 

	DECLARE c_specific CURSOR FOR 
	SELECT specific_part_code, desc_text 
	FROM configuration c, product p 
	WHERE c.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = p.cmpy_code 
	AND c.generic_part_code = fv_part_code 
	AND c.specific_part_code = p.part_code 

	LET fv_required_qty = fv_option_num * fv_bor_req_qty 
	LET fv_cnt = 1 

	FOREACH c_specific INTO fa_config_specific[fv_cnt].specific_part_code, 
		fa_config_specific[fv_cnt].desc_text 
		LET fv_cnt = fv_cnt + 1 

		IF fv_cnt > 500 THEN 
			LET msgresp = kandoomsg("M", 9567, "") 
			# ERROR "Only the first 500 products have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET fv_cnt = fv_cnt - 1 

	IF NOT pv_config THEN 
		OPEN WINDOW w3_m133 with FORM "M133" 
		CALL  windecoration_m("M133") -- albo kd-762 

		LET pv_config = true 
	END IF 

	CLEAR FORM 

	LET msgresp = kandoomsg("M", 1523, "") 	# MESSAGE " F3 Fwd, F4 Bwd, ESC TO Accept - DEL TO Exit"

	DISPLAY fv_part_code, fv_desc_text, fv_config_ind, fv_option_num, 
	fv_required_qty 
	TO part_code, formonly.desc_text, config_ind, option_num, 
	bor.required_qty 

	OPTIONS 
	INSERT KEY f36, 
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

			IF fa_config_specific[fv_idx].required_qty > fv_required_qty THEN 
				LET msgresp = kandoomsg("M", 9817, "") 
				# ERROR "Quantity cannot be greater than the required quantity"
				NEXT FIELD required_qty 
			END IF 

			IF fa_config_specific[fv_idx].required_qty > 0 
			AND fv_parent = "Y" THEN 
				SELECT part_code 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fa_config_specific[fv_idx].specific_part_code 
				AND part_type_ind = "P" 

				IF status != notfound THEN 
					LET msgresp = kandoomsg("M", 9818, "") 
					# error"This product IS a phantom-cannot create a so FOR it"
					NEXT FIELD required_qty 
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
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			LET fv_total = 0 
			LET fv_cnt2 = 0 
			INITIALIZE pa_config TO NULL 

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

			IF fv_total > fv_required_qty THEN 
				LET msgresp = kandoomsg("M", 9786, "") 
				# error"The total of all products exceeds the required quantity"
				NEXT FIELD required_qty 
			END IF 

			IF fv_config_ind = "F" 
			AND fv_total < fv_required_qty THEN 
				LET msgresp = kandoomsg("M", 9787, "") 
				# ERROR "The total of all products must equal the required qty"
				NEXT FIELD required_qty 
			END IF 

	END INPUT 

	OPTIONS 
	INSERT KEY f1, 
	DELETE KEY f2 

	RETURN fv_cnt2 

END FUNCTION 



FUNCTION load_detl_array(fr_bor, fv_type_ind, fv_part_type_ind, fv_man_uom_code) 

	DEFINE fv_type_ind LIKE bor.type_ind, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fr_bor RECORD LIKE bor.* 


	IF fv_type_ind = "G" THEN 
		LET fr_bor.uom_code = fv_man_uom_code 
	END IF 

	LET pv_cnt = pv_cnt + 1 
	CALL get_so_record(fr_bor.*, fv_part_type_ind) 
	RETURNING pa_shoporddetl[pv_cnt].* 

	LET pa_shoporddetl[pv_cnt].sequence_num = pv_cnt 

	IF fr_bor.type_ind = "B" THEN 
		LET pa_shoporddetl[pv_cnt].required_qty = 
		- pa_shoporddetl[pv_cnt].required_qty 
	END IF 

	LET pa_scrn_sodetl[pv_cnt].type_ind = fr_bor.type_ind 
	LET pa_scrn_sodetl[pv_cnt].sequence_num = pv_cnt 
	LET pa_scrn_sodetl[pv_cnt].desc_text = fr_bor.desc_text 

	IF fv_part_type_ind != "P" THEN 
		LET pa_scrn_sodetl[pv_cnt].required_qty = 
		pa_shoporddetl[pv_cnt].required_qty 
	END IF 

	CASE fr_bor.type_ind 
		WHEN "I" 
			LET pa_scrn_sodetl[pv_cnt].part_code = kandooword("INSTRUCTION", "M14") 

		WHEN "S" 
			LET pa_scrn_sodetl[pv_cnt].part_code = kandooword("COST", "M15") 
			LET pv_ext_cost_amt = pv_ext_cost_amt + 
			pa_shoporddetl[pv_cnt].act_est_cost_amt 

		WHEN "W" 
			LET pa_scrn_sodetl[pv_cnt].part_code = 
			pa_shoporddetl[pv_cnt].work_centre_code 
			LET pv_ext_cost_amt = pv_ext_cost_amt + 
			pa_shoporddetl[pv_cnt].std_act_cost_amt 
			LET fr_bor.cost_amt = pa_shoporddetl[pv_cnt].std_act_cost_amt / 
			pa_shoporddetl[pv_cnt].required_qty 

		WHEN "U" 
			LET pa_scrn_sodetl[pv_cnt].part_code = kandooword("SET UP", "M17") 
			LET pa_scrn_sodetl[pv_cnt].required_qty = NULL 
			LET pv_ext_cost_amt = pv_ext_cost_amt + 
			pa_shoporddetl[pv_cnt].act_est_cost_amt 

		OTHERWISE 
			LET pa_scrn_sodetl[pv_cnt].part_code = fr_bor.part_code 
			LET pa_scrn_sodetl[pv_cnt].component_type_ind = fv_part_type_ind 

			SELECT desc_text 
			INTO pa_scrn_sodetl[pv_cnt].desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			IF fv_part_type_ind = "P" THEN 
				RETURN 
			END IF 

			CASE 
				WHEN pr_inparms.cost_ind = "S" 
					LET pv_ext_cost_amt = pv_ext_cost_amt + (fr_bor.required_qty 
					* pa_shoporddetl[pv_cnt].std_est_cost_amt) 
					LET fr_bor.cost_amt = 
					pa_shoporddetl[pv_cnt].std_est_cost_amt 

				WHEN pr_inparms.cost_ind matches "[WF]" 
					LET pv_ext_cost_amt = pv_ext_cost_amt + (fr_bor.required_qty 
					* pa_shoporddetl[pv_cnt].std_wgted_cost_amt) 
					LET fr_bor.cost_amt = 
					pa_shoporddetl[pv_cnt].std_wgted_cost_amt 

				WHEN pr_inparms.cost_ind = "L" 
					LET pv_ext_cost_amt = pv_ext_cost_amt + (fr_bor.required_qty 
					* pa_shoporddetl[pv_cnt].std_act_cost_amt) 
					LET fr_bor.cost_amt = 
					pa_shoporddetl[pv_cnt].std_act_cost_amt 
			END CASE 
	END CASE 

	LET pa_scrn_sodetl[pv_cnt].unit_cost_amt = fr_bor.cost_amt 

END FUNCTION 



FUNCTION calc_cost_totals() 

	CASE 
		WHEN pa_sodetl_final[pv_cnt1].type_ind matches "[SU]" 
			LET pv_scost_tot = pv_scost_tot + 
			pa_sodetl_final[pv_cnt1].act_est_cost_amt 
			LET pv_wcost_tot = pv_wcost_tot + 
			pa_sodetl_final[pv_cnt1].act_est_cost_amt 
			LET pv_lcost_tot = pv_lcost_tot + 
			pa_sodetl_final[pv_cnt1].act_est_cost_amt 
			LET pa_sodetl_final[pv_cnt1].act_est_cost_amt = NULL 

			IF pa_sodetl_final[pv_cnt1].act_wgted_cost_amt IS NOT NULL THEN 
				LET pv_price_tot = pv_price_tot + 
				pa_sodetl_final[pv_cnt1].act_wgted_cost_amt 
				LET pa_sodetl_final[pv_cnt1].act_wgted_cost_amt = NULL 
			END IF 

		WHEN pa_sodetl_final[pv_cnt1].type_ind = "W" 
			LET pv_scost_tot = pv_scost_tot + 
			pa_sodetl_final[pv_cnt1].std_act_cost_amt 
			LET pv_wcost_tot = pv_wcost_tot + 
			pa_sodetl_final[pv_cnt1].std_act_cost_amt 
			LET pv_lcost_tot = pv_lcost_tot + 
			pa_sodetl_final[pv_cnt1].std_act_cost_amt 
			LET pv_price_tot = pv_price_tot + 
			pa_sodetl_final[pv_cnt1].std_price_amt 

		WHEN pa_sodetl_final[pv_cnt1].type_ind = "C" 

			LET pv_scost_tot = pv_scost_tot + 
			(pa_sodetl_final[pv_cnt1].std_est_cost_amt * 
			pa_sodetl_final[pv_cnt1].required_qty) 
			LET pv_wcost_tot = pv_wcost_tot + 
			(pa_sodetl_final[pv_cnt1].std_wgted_cost_amt * 
			pa_sodetl_final[pv_cnt1].required_qty) 
			LET pv_lcost_tot = pv_lcost_tot + 
			(pa_sodetl_final[pv_cnt1].std_act_cost_amt * 
			pa_sodetl_final[pv_cnt1].required_qty) 

			LET pv_price_tot = pv_price_tot + 
			(pa_sodetl_final[pv_cnt1].std_price_amt * 
			pa_sodetl_final[pv_cnt1].required_qty) 
	END CASE 

END FUNCTION 



FUNCTION get_so_record(fr_bor, fv_type_ind) 

	DEFINE fv_setup_qty SMALLINT, 
	fv_wc_cost LIKE shoporddetl.std_est_cost_amt, 
	fv_type_ind LIKE prodmfg.part_type_ind, 

	fr_bor RECORD LIKE bor.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_workcentre RECORD LIKE workcentre.* 


	INITIALIZE fr_shoporddetl TO NULL 

	LET fr_shoporddetl.parent_part_code = fr_bor.parent_part_code 
	LET fr_shoporddetl.part_code = fr_bor.part_code 
	LET fr_shoporddetl.type_ind = fr_bor.type_ind 

	IF fv_type_ind = "P" THEN 
		RETURN fr_shoporddetl.* 
	END IF 

	LET fr_shoporddetl.required_qty = fr_bor.required_qty 
	LET fr_shoporddetl.uom_code = fr_bor.uom_code 
	LET fr_shoporddetl.std_est_cost_amt = fr_bor.cost_amt 
	LET fr_shoporddetl.std_price_amt = fr_bor.price_amt 
	LET fr_shoporddetl.desc_text = fr_bor.desc_text 
	LET fr_shoporddetl.work_centre_code = fr_bor.work_centre_code 
	LET fr_shoporddetl.cost_type_ind = fr_bor.cost_type_ind 
	LET fr_shoporddetl.user1_text = fr_bor.user1_text 
	LET fr_shoporddetl.user2_text = fr_bor.user2_text 
	LET fr_shoporddetl.user3_text = fr_bor.user3_text 
	LET fr_shoporddetl.overlap_per = fr_bor.overlap_per 
	LET fr_shoporddetl.oper_factor_amt = fr_bor.oper_factor_amt 
	LET fr_shoporddetl.var_amt = fr_bor.var_amt 

	CASE 
		WHEN fr_bor.type_ind = "S" 
			IF fr_bor.cost_type_ind = "F" THEN 
				LET fr_shoporddetl.act_est_cost_amt = fr_bor.cost_amt 
				LET fr_shoporddetl.act_wgted_cost_amt = fr_bor.price_amt 
			ELSE 
				LET fr_shoporddetl.act_est_cost_amt = fr_bor.cost_amt * 
				pr_shopordhead.order_qty 
				LET fr_shoporddetl.act_wgted_cost_amt = fr_bor.price_amt * 
				pr_shopordhead.order_qty 
			END IF 

			LET fr_shoporddetl.act_act_cost_amt = 0 
			LET fr_shoporddetl.act_price_amt = 0 

		WHEN fr_bor.type_ind = "W" 
			SELECT * 
			INTO fr_workcentre.* 
			FROM workcentre 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND work_centre_code = fr_bor.work_centre_code 

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

			LET fr_shoporddetl.required_qty = pr_shopordhead.order_qty * 
			fr_bor.oper_factor_amt 

			IF fr_workcentre.processing_ind = "Q" THEN 
				LET fv_wc_cost = ((fr_bor.cost_amt / fr_workcentre.time_qty) * 
				fr_shoporddetl.required_qty) + fr_bor.price_amt 
			ELSE 
				LET fv_wc_cost = (fr_bor.cost_amt * fr_shoporddetl.required_qty) 
				+ fr_bor.price_amt 
			END IF 

			LET fr_shoporddetl.std_act_cost_amt = fv_wc_cost 
			LET fr_shoporddetl.std_price_amt = fv_wc_cost * (1 + 
			(fr_workcentre.cost_markup_per / 100)) 
			LET fr_shoporddetl.receipted_qty = 0 
			LET fr_shoporddetl.rejected_qty = 0 
			LET fr_shoporddetl.act_act_cost_amt = 0 
			LET fr_shoporddetl.act_price_amt = 0 

		WHEN fr_bor.type_ind = "U" 
			IF fr_bor.cost_type_ind = "Q" THEN 
				LET fv_setup_qty = pr_shopordhead.order_qty / fr_bor.var_amt 

				IF (pr_shopordhead.order_qty / fr_bor.var_amt) > fv_setup_qty 
				THEN 
					LET fv_setup_qty = fv_setup_qty + 1 
				END IF 

				LET fr_shoporddetl.act_est_cost_amt = fr_bor.cost_amt * 
				fv_setup_qty 
				LET fr_shoporddetl.act_wgted_cost_amt = fr_bor.price_amt * 
				fv_setup_qty 
			ELSE 
				LET fr_shoporddetl.act_est_cost_amt = fr_bor.cost_amt 
				LET fr_shoporddetl.act_wgted_cost_amt = fr_bor.price_amt 
			END IF 

			LET fr_shoporddetl.act_act_cost_amt = 0 
			LET fr_shoporddetl.act_price_amt = 0 

		WHEN fr_bor.type_ind matches "[CB]" 
			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			LET fr_shoporddetl.issue_ware_code = fr_prodmfg.def_ware_code 

			IF fr_bor.type_ind = "C" THEN 
				CALL update_costs(fr_shoporddetl.*, fr_product.*, fr_prodmfg.*) 
				RETURNING fr_shoporddetl.* 
			ELSE 
				LET fr_shoporddetl.std_est_cost_amt = 0 
				LET fr_shoporddetl.std_wgted_cost_amt = 0 
				LET fr_shoporddetl.std_act_cost_amt = 0 
				LET fr_shoporddetl.std_price_amt = 0 
			END IF 
	END CASE 

	RETURN fr_shoporddetl.* 

END FUNCTION 



FUNCTION update_costs(fr_shoporddetl, fr_product, fr_prodmfg) 

	DEFINE fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.* 


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



FUNCTION delete_phantom(fv_idx) 

	DEFINE fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_seq_num LIKE shoporddetl.sequence_num, 

	fa_scrn_sodetl array[2000] OF RECORD 
		type_ind LIKE shoporddetl.type_ind, 
		component_type_ind CHAR(1), 
		part_code LIKE shoporddetl.part_code, 
		desc_text LIKE product.desc_text, 
		required_qty LIKE shoporddetl.required_qty, 
		unit_cost_amt LIKE shoporddetl.std_est_cost_amt, 
		sequence_num LIKE shoporddetl.sequence_num 
	END RECORD 


	LET fv_seq_num = pa_scrn_sodetl[fv_idx].sequence_num 

	CALL delete_kids(fv_idx) 
	INITIALIZE pa_scrn_sodetl[fv_idx].*, pa_shoporddetl[fv_seq_num].* TO NULL 
	LET fv_cnt1 = 0 

	FOR fv_cnt = 1 TO pv_arr_size 
		IF pa_scrn_sodetl[fv_cnt].sequence_num IS NULL 
		OR pa_scrn_sodetl[fv_cnt].sequence_num = 0 THEN 
			CONTINUE FOR 
		END IF 

		LET fv_cnt1 = fv_cnt1 + 1 
		LET fa_scrn_sodetl[fv_cnt1].* = pa_scrn_sodetl[fv_cnt].* 
	END FOR 

	INITIALIZE pa_scrn_sodetl TO NULL 

	FOR fv_cnt = 1 TO fv_cnt1 
		LET pa_scrn_sodetl[fv_cnt].* = fa_scrn_sodetl[fv_cnt].* 
	END FOR 

	LET pv_arr_size = fv_cnt1 

END FUNCTION 



FUNCTION delete_kids(fv_idx) 

	DEFINE fv_cnt SMALLINT, 
	fv_idx SMALLINT, 
	fv_seq_num LIKE shoporddetl.sequence_num 


	FOR fv_cnt = fv_idx + 1 TO pv_arr_size 
		IF pa_scrn_sodetl[fv_cnt].sequence_num IS NULL 
		OR pa_scrn_sodetl[fv_cnt].sequence_num = 0 THEN 
			CONTINUE FOR 
		END IF 

		LET fv_seq_num = pa_scrn_sodetl[fv_cnt].sequence_num 

		IF pa_shoporddetl[fv_seq_num].parent_part_code = 
		pa_scrn_sodetl[fv_idx].part_code THEN 

			IF pa_scrn_sodetl[fv_cnt].component_type_ind = "P" THEN 
				CALL delete_kids(fv_cnt) 
			ELSE 
				CALL reduce_total(fv_seq_num) 
			END IF 

			INITIALIZE pa_scrn_sodetl[fv_cnt].*, pa_shoporddetl[fv_seq_num].* 
			TO NULL 
		END IF 
	END FOR 

END FUNCTION 



FUNCTION reduce_total(fv_seq_num) 

	DEFINE fv_seq_num SMALLINT 


	CASE 
		WHEN pa_shoporddetl[fv_seq_num].type_ind matches "[SU]" 
			LET pv_ext_cost_amt = pv_ext_cost_amt - 
			pa_shoporddetl[fv_seq_num].act_est_cost_amt 

		WHEN pa_shoporddetl[fv_seq_num].type_ind = "W" 
			LET pv_ext_cost_amt = pv_ext_cost_amt - 
			pa_shoporddetl[fv_seq_num].std_act_cost_amt 

		WHEN pa_shoporddetl[fv_seq_num].type_ind = "C" 
			CASE 
				WHEN pr_inparms.cost_ind = "S" 
					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_est_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) 

				WHEN pr_inparms.cost_ind matches "[WF]" 
					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_wgted_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) 

				WHEN pr_inparms.cost_ind = "L" 
					LET pv_ext_cost_amt = pv_ext_cost_amt - 
					(pa_shoporddetl[fv_seq_num].std_act_cost_amt * 
					pa_shoporddetl[fv_seq_num].required_qty) 
			END CASE 
	END CASE 

END FUNCTION 



FUNCTION calc_end_date() 

	DEFINE fv_latest_date LIKE shoporddetl.start_date, 
	fv_latest_time LIKE shoporddetl.start_time, 
	fv_so_start_time LIKE shoporddetl.start_time, 
	fv_wc_date LIKE shopordhead.start_date, 
	fv_wc_time LIKE workcentre.oper_start_time, 
	fv_day_length INTERVAL hour TO second, 
	fv_wc_dy_lgth INTERVAL hour TO second, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
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
	fv_wcount SMALLINT, 
	fv_lead_time LIKE product.days_lead_num, 
	fr_workcentre RECORD LIKE workcentre.* 


	CALL check_date(pr_shopordhead.start_date, 1) RETURNING fv_latest_date 

	LET fv_day_length = pr_mnparms.oper_end_time - pr_mnparms.oper_start_time 
	LET fv_length_char = fv_day_length 
	LET fv_dy_hrs = fv_length_char[2,3] 
	LET fv_dy_mins = fv_length_char[5,6] 
	LET fv_hrs_length = fv_dy_hrs + (fv_dy_mins / 60) 
	LET fv_mins_length = (fv_dy_hrs * 60) + fv_dy_mins 

	FOR fv_cnt = 1 TO pv_cnt1 
		CASE 
			WHEN pa_sodetl_final[fv_cnt].type_ind = "U" 
				LET fv_time_qty = pa_sodetl_final[fv_cnt].required_qty 

				IF pa_sodetl_final[fv_cnt].cost_type_ind = "Q" THEN 
					LET fv_setup_qty = pr_shopordhead.order_qty / 
					pa_sodetl_final[fv_cnt].var_amt 

					IF fv_setup_qty < (pr_shopordhead.order_qty / 
					pa_sodetl_final[fv_cnt].var_amt) THEN 
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

				LET pa_sodetl_final[fv_cnt].start_date = fv_latest_date 
				LET pa_sodetl_final[fv_cnt].start_time = fv_latest_time 

				IF fv_so_start_time IS NULL THEN 
					LET fv_so_start_time = fv_latest_time 
				END IF 

				CASE pa_sodetl_final[fv_cnt].uom_code 
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

				LET pa_sodetl_final[fv_cnt].end_date = fv_latest_date 
				LET pa_sodetl_final[fv_cnt].end_time = fv_latest_time 

			WHEN pa_sodetl_final[fv_cnt].type_ind = "W" 

				SELECT * 
				INTO fr_workcentre.* 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = 
				pa_sodetl_final[fv_cnt].work_centre_code 

				# IF a workcentre IS present SET the flag FOR date calculation
				LET fv_wcount = fv_wcount + 1 

				LET fv_wc_dy_lgth = fr_workcentre.oper_end_time - 
				fr_workcentre.oper_start_time 
				LET fv_wc_lgth_chr = fv_wc_dy_lgth 
				LET fv_wc_dy_hrs = fv_wc_lgth_chr[2,3] 
				LET fv_wc_dy_mins = fv_wc_lgth_chr[5,6] 
				LET fv_wc_hr_lgth = fv_wc_dy_hrs + (fv_wc_dy_mins / 60) 
				LET fv_wc_min_lgth = (fv_wc_dy_hrs * 60) + fv_wc_dy_mins 

				IF fr_workcentre.processing_ind = "Q" THEN 
					LET fv_time_qty = (pr_shopordhead.order_qty * 
					pa_sodetl_final[fv_cnt].oper_factor_amt) / 
					fr_workcentre.time_qty 
				ELSE 
					LET fv_time_qty = pr_shopordhead.order_qty * 
					fr_workcentre.time_qty * 
					pa_sodetl_final[fv_cnt].oper_factor_amt 
				END IF 

				IF fv_latest_time IS NULL THEN 
					LET pa_sodetl_final[fv_cnt].start_date = fv_latest_date 
					LET pa_sodetl_final[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
				ELSE 
					IF fv_wc_date IS NULL THEN 
						LET pa_sodetl_final[fv_cnt].start_date = fv_latest_date 
						LET pa_sodetl_final[fv_cnt].start_time = fv_latest_time 
					ELSE 
						LET pa_sodetl_final[fv_cnt].start_date = fv_wc_date 
						LET pa_sodetl_final[fv_cnt].start_time = fv_wc_time 
					END IF 
				END IF 

				IF pa_sodetl_final[fv_cnt].start_time < 
				fr_workcentre.oper_start_time THEN 
					LET pa_sodetl_final[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
				END IF 

				IF pa_sodetl_final[fv_cnt].start_time >= 
				fr_workcentre.oper_end_time THEN 
					LET pa_sodetl_final[fv_cnt].start_time = 
					fr_workcentre.oper_start_time 
					LET pa_sodetl_final[fv_cnt].start_date = 
					pa_sodetl_final[fv_cnt].start_date + 1 
					CALL check_date(pa_sodetl_final[fv_cnt].start_date, 1) 
					RETURNING pa_sodetl_final[fv_cnt].start_date 
				END IF 

				IF fv_so_start_time IS NULL THEN 
					LET fv_so_start_time = pa_sodetl_final[fv_cnt].start_time 
				END IF 

				LET pa_sodetl_final[fv_cnt].end_date = 
				pa_sodetl_final[fv_cnt].start_date 
				LET fv_wc_date = pa_sodetl_final[fv_cnt].start_date 
				LET pa_sodetl_final[fv_cnt].end_time = 
				pa_sodetl_final[fv_cnt].start_time 
				LET fv_wc_time = pa_sodetl_final[fv_cnt].start_time 

				CASE fr_workcentre.time_unit_ind 
					WHEN "D" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_sodetl_final[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty 
						LET fv_days1_qty = fv_time1_qty 
						LET fv_time_left = fv_wc_dy_lgth * (fv_time_qty - 
						fv_days_qty) 
						LET fv_time1_left = fv_wc_dy_lgth * (fv_time1_qty - 
						fv_days_qty) 

					WHEN "H" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_sodetl_final[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty / fv_wc_hr_lgth 
						LET fv_days1_qty = fv_time1_qty / fv_wc_hr_lgth 
						LET fv_time_left = fv_wc_dy_lgth * ((fv_time_qty - 
						(fv_wc_hr_lgth * fv_days_qty)) / fv_wc_hr_lgth) 
						LET fv_time1_left = fv_wc_dy_lgth * ((fv_time1_qty - 
						(fv_wc_hr_lgth * fv_days1_qty)) / fv_wc_hr_lgth) 

					WHEN "M" 
						LET fv_time1_qty = fv_time_qty * 
						(pa_sodetl_final[fv_cnt].overlap_per / 100) 
						LET fv_days_qty = fv_time_qty / fv_wc_min_lgth 
						LET fv_days1_qty = fv_time1_qty / fv_wc_min_lgth 
						LET fv_time_left = fv_wc_dy_lgth * ((fv_time_qty - 
						(fv_wc_min_lgth * fv_days_qty)) / fv_wc_min_lgth) 
						LET fv_time1_left = fv_wc_dy_lgth * ((fv_time1_qty - 
						(fv_wc_min_lgth * fv_days1_qty)) / fv_wc_min_lgth) 

				END CASE 

				IF fv_time_left = INTERVAL (0:00) hour TO minute 
				AND pa_sodetl_final[fv_cnt].start_time = 
				fr_workcentre.oper_start_time THEN 
					LET pa_sodetl_final[fv_cnt].end_time = 
					fr_workcentre.oper_end_time 
					LET fv_days_qty = fv_days_qty - 1 
				END IF 

				IF fv_time1_left = INTERVAL (0:00) hour TO minute 
				AND fv_wc_time = fr_workcentre.oper_start_time THEN 
					LET fv_wc_time = fr_workcentre.oper_end_time 
					LET fv_days1_qty = fv_days1_qty - 1 
				END IF 

				FOR fv_cnt1 = 1 TO fv_days_qty 
					LET pa_sodetl_final[fv_cnt].end_date = 
					pa_sodetl_final[fv_cnt].end_date + 1 
					CALL check_date(pa_sodetl_final[fv_cnt].end_date, 1) 
					RETURNING pa_sodetl_final[fv_cnt].end_date 
				END FOR 

				FOR fv_cnt1 = 1 TO fv_days1_qty 
					LET fv_wc_date = fv_wc_date + 1 
					CALL check_date(fv_wc_date, 1) RETURNING fv_wc_date 
				END FOR 

				IF (fr_workcentre.oper_end_time - 
				pa_sodetl_final[fv_cnt].end_time) >= fv_time_left THEN 
					LET pa_sodetl_final[fv_cnt].end_time = 
					pa_sodetl_final[fv_cnt].end_time + fv_time_left 
				ELSE 
					LET pa_sodetl_final[fv_cnt].end_date = 
					pa_sodetl_final[fv_cnt].end_date + 1 
					CALL check_date(pa_sodetl_final[fv_cnt].end_date, 1) 
					RETURNING pa_sodetl_final[fv_cnt].end_date 
					LET pa_sodetl_final[fv_cnt].end_time = 
					fr_workcentre.oper_start_time + fv_time_left - 
					(fr_workcentre.oper_end_time - 
					pa_sodetl_final[fv_cnt].end_time) 
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
					LET fv_latest_date = pa_sodetl_final[fv_cnt].end_date 
					LET fv_latest_time = pa_sodetl_final[fv_cnt].end_time 
				ELSE 
					CASE 
						WHEN pa_sodetl_final[fv_cnt].end_date > fv_latest_date 
							LET fv_latest_date = pa_sodetl_final[fv_cnt].end_date 
							LET fv_latest_time = pa_sodetl_final[fv_cnt].end_time 

						WHEN pa_sodetl_final[fv_cnt].end_date = fv_latest_date 
							IF pa_sodetl_final[fv_cnt].end_time > fv_latest_time 
							THEN 
								LET fv_latest_time = 
								pa_sodetl_final[fv_cnt].end_time 
							END IF 
					END CASE 
				END IF 

				IF pa_sodetl_final[fv_cnt].overlap_per = 100 THEN 
					LET fv_wc_date = NULL 
				END IF 

			WHEN pa_sodetl_final[fv_cnt].type_ind matches "[CB]" 
				IF pa_sodetl_final[fv_cnt].required_qty IS NOT NULL THEN 
					LET pa_sodetl_final[fv_cnt].start_date = 
					pr_shopordhead.start_date 

					IF fv_so_start_time IS NULL THEN 
						LET pa_sodetl_final[fv_cnt].start_time = 
						pr_mnparms.oper_start_time 
					ELSE 
						LET pa_sodetl_final[fv_cnt].start_time = fv_so_start_time 
					END IF 
				END IF 

		END CASE 
	END FOR 

	IF pr_shopordhead.end_date IS NULL THEN 
		LET pr_shopordhead.end_date = fv_latest_date 
	END IF 

	# IF the start date IS the same as the END date AND there have been no
	# workcentres processed THEN use the  inventory lead time.
	IF fv_wcount > 0 THEN 
	ELSE 
		SELECT days_lead_num INTO fv_lead_time 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.part_code 
		IF pv_start THEN 
			LET pr_shopordhead.end_date = pr_shopordhead.end_date 
			- fv_lead_time 
		ELSE 
			IF pr_shopordhead.start_date = pr_shopordhead.end_date THEN 
				LET pr_shopordhead.end_date = pr_shopordhead.end_date 
				+ fv_lead_time 
			END IF 
		END IF 
	END IF 
	LET fv_wcount = 0 

	IF pv_start THEN 
		RETURN fv_latest_date 
	END IF 

END FUNCTION 



FUNCTION calc_start_date(fv_end_date) 

	DEFINE fv_end_date LIKE shopordhead.end_date, 
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

	DEFINE fv_latest_date DATE, 
	fv_step SMALLINT, 
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

		LET fv_latest_date = fv_latest_date + fv_step 

	END WHILE 

END FUNCTION 
