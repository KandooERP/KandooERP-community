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

	Source code beautified by beautify.pl on 2020-01-02 17:31:30	$Id: $
}



# Purpose - Shop Order Receipt - By-product receipt & generate BOR
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M48.4gl" 


FUNCTION receipt_byprods() 

	DEFINE fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_full_cnt SMALLINT, 
	fv_idx SMALLINT, 
	fv_status LIKE prodstatus.status_ind, 
	fv_onord_qty LIKE prodstatus.onord_qty, 
	fv_stocked LIKE prodstatus.stocked_flag, 
	fv_ware_code LIKE shoporddetl.issue_ware_code, 
	fv_backflush LIKE prodmfg.backflush_ind, 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 

	fa_bpreceipt array[1000] OF RECORD 
		part_code LIKE shoporddetl.part_code, 
		required_qty LIKE shoporddetl.required_qty, 
		receipted_qty LIKE shoporddetl.receipted_qty, 
		rejected_qty LIKE shoporddetl.rejected_qty, 
		remain_qty LIKE shoporddetl.receipted_qty, 
		receipt_qty LIKE shoporddetl.receipted_qty, 
		reject_qty LIKE shoporddetl.rejected_qty, 
		issue_ware_code LIKE shoporddetl.issue_ware_code, 
		uom_code LIKE shoporddetl.uom_code, 
		sequence_num LIKE shoporddetl.sequence_num 
	END RECORD 


	DECLARE c_shoporddetl CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 
	AND type_ind = "B" 
	ORDER BY sequence_num 

	LET fv_cnt = 0 
	LET fv_full_cnt = 0 

	FOREACH c_shoporddetl INTO fr_shoporddetl.* 
		IF fr_shoporddetl.required_qty = fr_shoporddetl.receipted_qty + 
		fr_shoporddetl.rejected_qty THEN 
			LET fv_full_cnt = fv_full_cnt + 1 
			CONTINUE FOREACH 
		END IF 

		SELECT backflush_ind 
		INTO fv_backflush 
		FROM prodmfg 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = fr_shoporddetl.part_code 

		IF fv_backflush = "Y" THEN 
			LET fv_full_cnt = fv_full_cnt + 1 
			CONTINUE FOREACH 
		END IF 

		LET fv_cnt = fv_cnt + 1 

		LET fa_bpreceipt[fv_cnt].part_code = fr_shoporddetl.part_code 
		LET fa_bpreceipt[fv_cnt].required_qty = - fr_shoporddetl.required_qty 
		LET fa_bpreceipt[fv_cnt].receipted_qty = - fr_shoporddetl.receipted_qty 
		LET fa_bpreceipt[fv_cnt].rejected_qty = - fr_shoporddetl.rejected_qty 
		LET fa_bpreceipt[fv_cnt].remain_qty = - (fr_shoporddetl.required_qty 
		- fr_shoporddetl.receipted_qty - fr_shoporddetl.rejected_qty) 
		LET fa_bpreceipt[fv_cnt].receipt_qty = fa_bpreceipt[fv_cnt].remain_qty 
		LET fa_bpreceipt[fv_cnt].reject_qty = 0 
		LET fa_bpreceipt[fv_cnt].issue_ware_code =fr_shoporddetl.issue_ware_code 
		LET fa_bpreceipt[fv_cnt].uom_code = fr_shoporddetl.uom_code 
		LET fa_bpreceipt[fv_cnt].sequence_num = fr_shoporddetl.sequence_num 

		IF fv_cnt = 1000 THEN 
			ERROR "Only the first 1000 detail lines were selected" 
			--- modif ericv init # attributes (red, reverse)
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF fv_cnt = 0 THEN 
		RETURN fv_cnt, fv_full_cnt 
	END IF 

	OPEN WINDOW w5_m175 with FORM "M175" 
	CALL  windecoration_m("M175") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1523, "") 	# MESSAGE "F3 Fwd, F4 Bwd, ESC Accept - DEL Exit"

	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.part_code 
	DISPLAY pv_prod_desc TO desc_text 

	CALL set_count(fv_cnt) 

	OPTIONS 
	INSERT KEY f36, 
	DELETE KEY f36 

	INPUT ARRAY fa_bpreceipt WITHOUT DEFAULTS FROM sr_bpreceipt.* 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET fv_idx = arr_curr() 

		ON KEY (control-b) 
			IF infield(issue_ware_code) THEN 
				CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, fa_bpreceipt[fv_idx].part_code) 
				RETURNING fv_ware_code 

				IF fv_ware_code IS NOT NULL THEN 
					LET fa_bpreceipt[fv_idx].issue_ware_code = fv_ware_code 
					DISPLAY BY NAME fa_bpreceipt[fv_idx].issue_ware_code 
				END IF 
			END IF 

		AFTER FIELD receipt_qty 
			IF fa_bpreceipt[fv_idx].receipt_qty IS NULL THEN 
				ERROR "Quantity TO receipt must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].receipt_qty < 0 THEN 
				ERROR "Quantity TO receipt cannot be less than 0" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].receipt_qty > 
			fa_bpreceipt[fv_idx].remain_qty THEN 
				ERROR "Qty TO receipt cannot be greater than the remaining qty", 
				" TO be receipted" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].reject_qty + 
			fa_bpreceipt[fv_idx].receipt_qty > fa_bpreceipt[fv_idx].remain_qty 
			THEN 
				ERROR "Receipt + reject qtys cannot be greater than remaining ", 
				"qty TO be receipted" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND fv_idx = fv_cnt THEN 
				ERROR "There are no more rows in the direction you are going" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

		AFTER FIELD reject_qty 
			IF fa_bpreceipt[fv_idx].reject_qty IS NULL THEN 
				ERROR "Quantity TO reject must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].reject_qty < 0 THEN 
				ERROR "Quantity TO reject cannot be less than 0" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].reject_qty > 
			fa_bpreceipt[fv_idx].remain_qty THEN 
				ERROR "Qty TO reject cannot be greater than the remaining qty", 
				" TO be receipted" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].reject_qty + 
			fa_bpreceipt[fv_idx].receipt_qty > fa_bpreceipt[fv_idx].remain_qty 
			THEN 
				ERROR "Receipt + reject qtys cannot be greater than remaining ", 
				"qty TO be receipted" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND fv_idx = fv_cnt THEN 
				ERROR "There are no more rows in the direction you are going" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD reject_qty 
			END IF 

		AFTER FIELD issue_ware_code 
			IF fa_bpreceipt[fv_idx].issue_ware_code IS NULL THEN 
				ERROR "Warehouse code must be entered" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD issue_ware_code 
			END IF 

			SELECT status_ind, stocked_flag 
			INTO fv_status, fv_stocked 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_bpreceipt[fv_idx].part_code 
			AND ware_code = fa_bpreceipt[fv_idx].issue_ware_code 

			IF status = notfound THEN 
				ERROR "This warehouse IS NOT SET up FOR this product" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD issue_ware_code 
			END IF 

			IF fa_bpreceipt[fv_idx].receipt_qty > 0 
			AND fv_stocked = "N" THEN 
				ERROR "This product IS NOT stocked AT this warehouse" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].receipt_qty > 0 
			AND fv_status = "2" THEN 
				ERROR "This product IS on hold AT this warehouse" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF fa_bpreceipt[fv_idx].receipt_qty > 0 
			AND fv_status = "3" THEN 
				ERROR "This product IS marked FOR deletion AT this warehouse" 
				--- modif ericv init #  attributes (red, reverse)
				NEXT FIELD receipt_qty 
			END IF 

			IF (fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("RETURN") 
			OR fgl_lastkey() = fgl_keyval("right")) 
			AND fv_idx = fv_cnt THEN 
				LET msgresp = kandoomsg("M", 9530, "") 
				ERROR "There are no more rows in the direction you are going" 
				NEXT FIELD issue_ware_code 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			GOTO bypass2 

			LABEL recovery2: 
			LET err_continue = error_recover(err_message, status) 
			IF err_continue != "Y" THEN 
				EXIT program 
			END IF 

			LABEL bypass2: 
			WHENEVER ERROR GOTO recovery2 

			BEGIN WORK 

				FOR fv_cnt1 = 1 TO fv_cnt 
					IF fa_bpreceipt[fv_cnt1].receipt_qty = 0 
					AND fa_bpreceipt[fv_cnt1].reject_qty = 0 THEN 
						CONTINUE FOR 
					END IF 

					LET err_message = "M48 - SELECT FROM shoporddetl failed" 

					SELECT * 
					INTO fr_shoporddetl.* 
					FROM shoporddetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = pr_shopordhead.shop_order_num 
					AND suffix_num = pr_shopordhead.suffix_num 
					AND sequence_num = fa_bpreceipt[fv_cnt1].sequence_num 

					###
					### Subtract receipt & reject qtys FROM prodstatus on ORDER qty
					###

					LET err_message = "M48 - SELECT FROM prodmfg failed" 

					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_bpreceipt[fv_cnt1].part_code 

					LET err_message = "M48 - SELECT FROM product failed" 

					SELECT * 
					INTO fr_product.* 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_bpreceipt[fv_cnt1].part_code 

					LET fv_onord_qty = fa_bpreceipt[fv_cnt1].receipt_qty + 
					fa_bpreceipt[fv_cnt1].reject_qty 

					CALL uom_convert(fa_bpreceipt[fv_cnt1].uom_code, fv_onord_qty, 
					fr_product.*, fr_prodmfg.*) 
					RETURNING fv_onord_qty 

					LET err_message = "M48 - Update of prodstatus failed" 

					UPDATE prodstatus 
					SET onord_qty = onord_qty - fv_onord_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fa_bpreceipt[fv_cnt1].part_code 
					AND ware_code = fr_shoporddetl.issue_ware_code 

					###
					### Update shoporddetl table
					###

					LET fr_shoporddetl.receipted_qty = fr_shoporddetl.receipted_qty 
					- fa_bpreceipt[fv_cnt1].receipt_qty 
					LET fr_shoporddetl.rejected_qty = fr_shoporddetl.rejected_qty - 
					fa_bpreceipt[fv_cnt1].reject_qty 
					LET fr_shoporddetl.actual_start_date = today 
					LET fr_shoporddetl.last_change_date = today 
					LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
					LET fr_shoporddetl.last_program_text = "M48" 
					LET err_message = "M48 - Update of shoporddetl failed" 

					IF fa_bpreceipt[fv_cnt1].remain_qty = 
					(fa_bpreceipt[fv_cnt1].receipt_qty + 
					fa_bpreceipt[fv_cnt1].reject_qty) THEN 
						LET fr_shoporddetl.issue_ware_code = 
						fa_bpreceipt[fv_cnt1].issue_ware_code 
					END IF 

					UPDATE shoporddetl 
					SET * = fr_shoporddetl.* 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shop_order_num = pr_shopordhead.shop_order_num 
					AND suffix_num = pr_shopordhead.suffix_num 
					AND sequence_num = fa_bpreceipt[fv_cnt1].sequence_num 

					###
					### Add receipt qty TO prodstatus on ORDER qty
					###

					IF fa_bpreceipt[fv_cnt1].receipt_qty > 0 THEN 
						LET err_message = "M48 - SELECT FROM prodstatus failed" 

						SELECT * 
						INTO fr_prodstatus.* 
						FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fa_bpreceipt[fv_cnt1].part_code 
						AND ware_code = fa_bpreceipt[fv_cnt1].issue_ware_code 

						IF fr_prodstatus.status_ind matches "[23]" 
						OR fr_prodstatus.stocked_flag = "N" THEN 
							ROLLBACK WORK 
							LET msgresp = kandoomsg("M", 9203, 
							fa_bpreceipt[fv_cnt1].part_code) 
							# ERROR "Invalid warehouse FOR by-product "
							NEXT FIELD receipt_qty 
						END IF 

						CALL uom_convert(fa_bpreceipt[fv_cnt1].uom_code, 
						fa_bpreceipt[fv_cnt1].receipt_qty, 
						fr_product.*, fr_prodmfg.*) 
						RETURNING fa_bpreceipt[fv_cnt1].receipt_qty 

						LET fr_prodstatus.last_receipt_date = today 
						LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty + 
						fa_bpreceipt[fv_cnt1].receipt_qty 

						IF fr_prodstatus.onhand_qty <= 0 THEN 
							LET fr_prodstatus.wgted_cost_amt = 0 
						ELSE 
							LET fr_prodstatus.wgted_cost_amt = 
							(fr_prodstatus.wgted_cost_amt * 
							(fr_prodstatus.onhand_qty - 
							fa_bpreceipt[fv_cnt1].receipt_qty)) 
							/ fr_prodstatus.onhand_qty 

							IF fr_prodstatus.wgted_cost_amt < 0 THEN 
								LET fr_prodstatus.wgted_cost_amt = 0 
							END IF 
						END IF 

						LET err_message = "M48 - Second UPDATE of prodstatus failed" 

						UPDATE prodstatus 
						SET * = fr_prodstatus.* 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = fa_bpreceipt[fv_cnt1].part_code 
						AND ware_code = fa_bpreceipt[fv_cnt1].issue_ware_code 

						IF fr_product.serial_flag = "Y" THEN 
							CALL serial_in(glob_rec_kandoouser.cmpy_code, fr_product.vend_code, 
							fa_bpreceipt[fv_cnt1].receipt_qty, 
							pr_shopordhead.part_code, 0, 0, 
							today, pr_shopordhead.part_code, 
							fa_bpreceipt[fv_cnt1].issue_ware_code) 
						END IF 
					END IF 
				END FOR 

			COMMIT WORK 
			WHENEVER ERROR stop 

	END INPUT 

	CLOSE WINDOW w5_m175 
	RETURN 1,0 

END FUNCTION 



FUNCTION generate_bor() 

	DEFINE fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.parent_part_code, 
	fv_part_type_ind LIKE prodmfg.part_type_ind, 
	fv_config_ind LIKE prodmfg.config_ind, 
	fv_cnt SMALLINT, 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_bor RECORD LIKE bor.* 


	SELECT unique parent_part_code 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = pr_shopordhead.part_code 

	IF status != notfound THEN 
		OPEN WINDOW w6_m180 with FORM "M180" 
		CALL  windecoration_m("M180") -- albo kd-762 

		LET msgresp = kandoomsg("M", 1505, "") 
		# MESSAGE "ESC TO Accept - DEL TO Exit"

		INPUT fv_parent_part_code FROM parent_part_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "MGP") RETURNING fv_part_code 

				IF fv_part_code IS NOT NULL THEN 
					LET fv_parent_part_code = fv_part_code 
					DISPLAY fv_parent_part_code TO parent_part_code 

				END IF 

			AFTER FIELD parent_part_code 
				IF fv_parent_part_code IS NULL THEN 
					ERROR "Parent product must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

				SELECT part_code 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fv_parent_part_code 

				IF status = notfound THEN 
					ERROR "This product does NOT exist" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

				SELECT part_type_ind, config_ind 
				INTO fv_part_type_ind, fv_config_ind 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fv_parent_part_code 

				IF status = notfound THEN 
					ERROR "This product IS NOT SET up as a manufacturing ", 
					"product" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

				IF fv_part_type_ind = "R" THEN 
					ERROR "This IS a purchased product AND cannot be a parent" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

				IF fv_part_type_ind = "G" 
				AND fv_config_ind = "Y" THEN 
					ERROR "This IS a configurable product AND cannot be a ", 
					"parent" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

				SELECT unique parent_part_code 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_parent_part_code 

				IF status != notfound THEN 
					ERROR "This product already has a bill of resource" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD parent_part_code 
				END IF 

		END INPUT 

		CLOSE WINDOW w6_m180 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN 
		END IF 
	ELSE 
		LET fv_parent_part_code = pr_shopordhead.part_code 
	END IF 
	{
	    OPEN WINDOW w7_M48 AT 9,7 with 4 rows, 67 columns     -- albo  KD-762
	        attributes (border, white)
	}
	DISPLAY "Generating bill of resource FOR product ", fv_parent_part_code 
	at 1,2 

	DISPLAY "Item: " at 3,2 

	SLEEP 1 

	DECLARE c_shopord CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 
	ORDER BY sequence_num 

	GOTO bypass3 

	LABEL recovery3: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass3: 
	WHENEVER ERROR GOTO recovery3 

	BEGIN WORK 

		LET fv_cnt = 0 

		FOREACH c_shopord INTO fr_shoporddetl.* 
			INITIALIZE fr_bor TO NULL 

			CASE fr_shoporddetl.type_ind 
				WHEN "I" 
					DISPLAY "INSTRUCTION" at 3,8 


				WHEN "S" 
					DISPLAY "COST" at 3,8 

					LET fr_bor.cost_amt = fr_shoporddetl.std_est_cost_amt 
					LET fr_bor.price_amt = fr_shoporddetl.std_price_amt 

				WHEN "U" 
					DISPLAY "SETUP" at 3,8 

					LET fr_bor.cost_amt = fr_shoporddetl.std_est_cost_amt 
					LET fr_bor.price_amt = fr_shoporddetl.std_price_amt 

				WHEN "W" 
					LET err_message = "M48 - SELECT FROM workcentre failed" 

					SELECT work_centre_code 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_shoporddetl.work_centre_code 

					IF status = notfound THEN 
						CONTINUE FOREACH 
					END IF 

					DISPLAY "WORKCENTRE" at 3,8 


				OTHERWISE 
					IF fr_shoporddetl.part_code = fv_parent_part_code THEN 
						CONTINUE FOREACH 
					END IF 

					LET err_message = "M48 - SELECT FROM product failed" 

					SELECT part_code 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 

					IF status = notfound THEN 
						CONTINUE FOREACH 
					END IF 

					LET err_message = "M48 - SELECT FROM prodmfg failed" 

					SELECT part_type_ind 
					INTO fv_part_type_ind 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_shoporddetl.part_code 

					IF status = notfound OR fv_part_type_ind = "P" THEN 
						CONTINUE FOREACH 
					END IF 

					LET pv_bor_flag = false 
					LET pv_part_code = fr_shoporddetl.part_code 
					CALL bor_check(fv_parent_part_code) 

					IF pv_bor_flag THEN 
						CONTINUE FOREACH 
					END IF 

					DISPLAY fr_shoporddetl.part_code at 3,8 

			END CASE 


			LET fv_cnt = fv_cnt + 1 
			LET fr_bor.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_bor.parent_part_code = fv_parent_part_code 
			LET fr_bor.sequence_num = fv_cnt 
			LET fr_bor.type_ind = fr_shoporddetl.type_ind 
			LET fr_bor.part_code = fr_shoporddetl.part_code 
			LET fr_bor.required_qty = fr_shoporddetl.required_qty / 
			pr_shopordhead.order_qty 
			LET fr_bor.uom_code = fr_shoporddetl.uom_code 
			LET fr_bor.desc_text = fr_shoporddetl.desc_text 
			LET fr_bor.cost_type_ind = fr_shoporddetl.user1_text 
			LET fr_bor.user1_text = fr_shoporddetl.user1_text 
			LET fr_bor.user2_text = fr_shoporddetl.user2_text 
			LET fr_bor.user3_text = fr_shoporddetl.user3_text 
			LET fr_bor.work_centre_code = fr_shoporddetl.work_centre_code 
			LET fr_bor.overlap_per = fr_shoporddetl.overlap_per 
			LET fr_bor.oper_factor_amt = fr_shoporddetl.oper_factor_amt 
			LET fr_bor.var_amt = fr_shoporddetl.var_amt 
			LET fr_bor.last_change_date = today 
			LET fr_bor.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_bor.last_program_text = "M48" 
			LET err_message = "M48 - Insert INTO bor failed" 

			INSERT INTO bor VALUES (fr_bor.*) 

		END FOREACH 

		--    CLEAR window w7_M48      -- albo  KD-762

		IF fv_cnt > 0 THEN 
			DISPLAY "Bill of resource created successfully FOR product ", 
			fv_parent_part_code 
			at 2,2 
		ELSE 
			DISPLAY "No bill of resource was created" at 2,2 

		END IF 

		SLEEP 2 

	COMMIT WORK 
	WHENEVER ERROR stop 

	--    CLOSE WINDOW w7_M48      -- albo  KD-762

END FUNCTION 



FUNCTION bor_check(fv_part_code) 

	DEFINE fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.part_code, 
	fv_cnt SMALLINT, 
	fv_parent_cnt SMALLINT, 

	fa_parent array[2000] OF LIKE bor.parent_part_code 


	DECLARE c_bor CURSOR FOR 
	SELECT unique parent_part_code 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_part_code 

	LET fv_parent_cnt = 0 

	FOREACH c_bor INTO fv_parent_part_code 
		LET fv_parent_cnt = fv_parent_cnt + 1 
		LET fa_parent[fv_parent_cnt] = fv_parent_part_code 
	END FOREACH 

	LET fv_cnt = 0 

	WHILE fv_cnt < fv_parent_cnt 
		LET fv_cnt = fv_cnt + 1 

		IF pv_part_code = fa_parent[fv_cnt] THEN 
			LET pv_bor_flag = true 
			EXIT WHILE 
		END IF 

		CALL bor_check(fa_parent[fv_cnt]) 

		IF pv_bor_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

END FUNCTION 
