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

	Source code beautified by beautify.pl on 2020-01-02 17:31:19	$Id: $
}


# Purpose - BOR Maintenance - Component/By Product details entry SCREEN
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M16_GLOBALS.4gl" 



FUNCTION component_input(fv_parent_part_code) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	fv_cnt SMALLINT, 
	fv_part_code LIKE bor.part_code, 
	fv_old_part_code LIKE bor.part_code, 
	fv_uom_code LIKE bor.uom_code, 
	fv_wc_code LIKE bor.work_centre_code, 
	fv_wc_desc_text LIKE workcentre.desc_text, 
	fv_ref_code LIKE userref.ref_code, 
	fv_parent_part_code LIKE bor.parent_part_code, 
	dummy CHAR(1), 

	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_product RECORD LIKE product.* 


	IF pr_bor.type_ind = "C" THEN 
		OPEN WINDOW w1_m107 with FORM "M107" 
		CALL  windecoration_m("M107") -- albo kd-762 
	ELSE 
		OPEN WINDOW w1_m153 with FORM "M153" 
		CALL  windecoration_m("M153") -- albo kd-762 
	END IF 

	LET msgresp = kandoomsg("M",1505,"") # MESSAGE "ESC TO Accept - DEL TO Exit"

	DISPLAY BY NAME pr_bor.desc_text 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	INPUT BY NAME pr_bor.part_code, 
	pr_bor.required_qty, 
	pr_bor.uom_code, 
	pr_bor.work_centre_code, 
	pr_bor.start_date, 
	pr_bor.end_date, 
	pr_bor.user1_text, 
	pr_bor.user2_text, 
	pr_bor.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			IF pr_bor.part_code IS NOT NULL THEN 
				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_bor.part_code 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_bor.part_code 

				CALL display_costs(fr_product.*, fr_prodmfg.*) 
			END IF 

			IF pr_bor.work_centre_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO fv_wc_desc_text 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_bor.work_centre_code 

				DISPLAY fv_wc_desc_text TO wc_desc_text 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(part_code) 
					IF pr_bor.type_ind = "B" THEN 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "MR") RETURNING fv_part_code 

						IF fv_part_code IS NOT NULL THEN 
							LET pr_bor.part_code = fv_part_code 
							DISPLAY BY NAME pr_bor.part_code 
						END IF 
					ELSE 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING fv_part_code 

						IF fv_part_code IS NOT NULL THEN 
							LET pr_bor.part_code = fv_part_code 
							DISPLAY BY NAME pr_bor.part_code 
						END IF 
					END IF 

				WHEN infield(uom_code) 
					CALL lookup_uom(glob_rec_kandoouser.cmpy_code, pr_bor.part_code) 
					RETURNING fv_uom_code 

					IF fv_uom_code IS NOT NULL THEN 
						LET pr_bor.uom_code = fv_uom_code 
						NEXT FIELD uom_code 
					END IF 

				WHEN infield(work_centre_code) 
					CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

					IF fv_wc_code IS NOT NULL THEN 
						LET pr_bor.work_centre_code = fv_wc_code 
						NEXT FIELD work_centre_code 
					END IF 

				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_bor.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 
			END CASE 

		BEFORE FIELD part_code 
			LET fv_old_part_code = pr_bor.part_code 

		AFTER FIELD part_code 
			IF pr_bor.part_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9532,"") 
				# ERROR "Product code must be entered"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_bor.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9511,"") 
				# ERROR "This product does NOT exist in the database-Try Window"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_bor.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9569,"") 
				# ERROR "This product IS NOT SET up as a manufacturing product"
				NEXT FIELD part_code 
			END IF 

			IF pr_bor.type_ind = "B" 
			AND fr_prodmfg.part_type_ind NOT matches "[MR]" THEN 
				LET msgresp = kandoomsg("M",9583,"") 
				# ERROR "A by-product can only be a manufactured OR purchased.."
				NEXT FIELD part_code 
			END IF 

			IF pr_bor.part_code = fv_parent_part_code THEN 
				LET msgresp = kandoomsg("M",9584,"") 
				# ERROR "cannot enter the parent product as a child of itself"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO fr_prodstatus.* 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_bor.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			IF fr_prodstatus.stocked_flag = "N" THEN 
				IF pr_bor.type_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 7400, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This product IS NOT stocked AT it's
					#         default warehouse,<ware_code> Any key TO continue"
				ELSE 
					LET msgresp = kandoomsg("M", 7401, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This by-product IS NOT stocked AT it's
					#         default warehouse,<ware_code> Any key TO continue"
				END IF 
			END IF 

			IF fr_prodstatus.status_ind = "2" THEN 
				IF pr_bor.type_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 7402, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This product IS on hold AT it's
					#         default warehouse,<ware_code> Any key TO continue"
				ELSE 
					LET msgresp = kandoomsg("M", 7403, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This by-product IS on hold AT it's
					#         default warehouse,<ware_code> Any key TO continue"
				END IF 
			END IF 

			IF fr_prodstatus.status_ind = "3" THEN 
				IF pr_bor.type_ind = "C" THEN 
					LET msgresp = kandoomsg("M", 7404, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This product IS marked FOR deletion at
					# it's default warehouse, <ware_code> - Any key TO continue"
				ELSE 
					LET msgresp = kandoomsg("M", 7405, fr_prodmfg.def_ware_code) 
					# prompt "WARNING: This by-product IS marked FOR deletion at
					# it's default warehouse, <ware_code> - Any key TO continue"
				END IF 
			END IF 

			LET pr_bor.desc_text = fr_product.desc_text 
			DISPLAY BY NAME pr_bor.desc_text 

			IF pr_bor.part_code != fv_old_part_code 
			OR fv_old_part_code IS NULL THEN 

				IF fr_prodmfg.part_type_ind != "R" THEN 
					LET msgresp = kandoomsg("M", 1532, "") 
					# MESSAGE "Searching database - please wait"

					LET pv_bor_flag = false 
					CALL bor_check(fv_parent_part_code) 

					LET msgresp = kandoomsg("M", 1505, "") 
					# MESSAGE "ESC TO Accept - DEL TO Exit"

					IF pv_bor_flag THEN 
						LET msgresp = kandoomsg("M", 9585, "") 
						#error"This product IS used higher up in the BOR as a.."
						NEXT FIELD part_code 
					END IF 
				END IF 

				LET pr_bor.uom_code = fr_prodmfg.man_uom_code 
				DISPLAY BY NAME pr_bor.uom_code 

				IF pr_bor.required_qty IS NULL THEN 
					LET pr_bor.required_qty = 1 
					DISPLAY BY NAME pr_bor.required_qty 
				END IF 

				CALL display_costs(fr_product.*, fr_prodmfg.*) 

				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD uom_code 
				END IF 
			END IF 

		AFTER FIELD required_qty 
			IF pr_bor.required_qty IS NULL THEN 
				LET msgresp = kandoomsg("M",9586,"") 
				# ERROR "Quantity must be entered"
				NEXT FIELD required_qty 
			END IF 

			IF pr_bor.required_qty <= 0 THEN 
				LET msgresp = kandoomsg("M",9614,"") 
				# ERROR "Quantity must be greater than zero"
				NEXT FIELD required_qty 
			END IF 

			CALL display_costs(fr_product.*, fr_prodmfg.*) 

		AFTER FIELD uom_code 
			IF pr_bor.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9547,"") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD uom_code 
			END IF 

			SELECT uom_code 
			FROM uom 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND uom_code = pr_bor.uom_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M",9548,"") 
				# ERROR "Unit of measure code does NOT exist - Try Window"
				NEXT FIELD uom_code 
			END IF 

			IF pr_bor.uom_code != fr_prodmfg.man_uom_code 
			AND pr_bor.uom_code != fr_product.pur_uom_code 
			AND pr_bor.uom_code != fr_product.stock_uom_code 
			AND pr_bor.uom_code != fr_product.sell_uom_code THEN 
				LET msgresp = kandoomsg("M",9587,"") 
				#ERROR "Unit of measure code NOT valid FOR this product-Try Win"
				NEXT FIELD uom_code 
			END IF 

			CALL display_costs(fr_product.*, fr_prodmfg.*) 

		AFTER FIELD work_centre_code 
			IF pr_bor.work_centre_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO fv_wc_desc_text 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_bor.work_centre_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M",9527,"") 
					# ERROR "Work Centre does NOT exist in the database-Try Win"
					NEXT FIELD work_centre_code 
				END IF 

				DISPLAY fv_wc_desc_text TO wc_desc_text 
			ELSE 
				DISPLAY "" TO wc_desc_text 
			END IF 

		AFTER FIELD end_date 
			IF pr_bor.start_date > pr_bor.end_date THEN 
				LET msgresp = kandoomsg("M",9588,"") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_bor.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user1_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref1_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "1" 
					AND ref_code = pr_bor.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user1_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user2_text 
			IF pr_mnparms.ref2_ind NOT matches "[1234]" 
			OR pr_mnparms.ref2_ind IS NULL THEN 
				NEXT FIELD user3_text 
			END IF 

		AFTER FIELD user2_text 
			IF pr_bor.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user2_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref2_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "2" 
					AND ref_code = pr_bor.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user2_text 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD user3_text 
			IF pr_mnparms.ref3_ind NOT matches "[1234]" 
			OR pr_mnparms.ref3_ind IS NULL THEN 
				NEXT FIELD dummy 
			END IF 

		AFTER FIELD user3_text 
			IF pr_bor.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M",9589,"") 
					# ERROR "User defined field must be entered"
					NEXT FIELD user3_text 
				END IF 
			ELSE 
				IF pr_mnparms.ref3_ind matches "[34]" THEN 
					SELECT ref_code 
					FROM userref 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND source_ind = "M" 
					AND ref_ind = "3" 
					AND ref_code = pr_bor.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M",9590,"") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_bor.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M",9547,"") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD uom_code 
			END IF 

			IF pr_bor.start_date > pr_bor.end_date THEN 
				LET msgresp = kandoomsg("M",9588,"") 
				# ERROR "Start date cannot be later than END date"
				NEXT FIELD start_date 
			END IF 

			IF pr_bor.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_bor.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_bor.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M",9589,"") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 

	END INPUT 

	IF pr_bor.type_ind = "C" THEN 
		CLOSE WINDOW w1_m107 
	ELSE 
		CLOSE WINDOW w1_m153 
	END IF 

END FUNCTION 



FUNCTION display_costs(fr_product, fr_prodmfg) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fv_unit_cost_amt LIKE bor.cost_amt, 
	fv_unit_price_amt LIKE bor.price_amt, 
	fv_ext_cost_amt LIKE bor.cost_amt, 
	fv_ext_price_amt LIKE bor.price_amt 


	IF fr_prodmfg.part_type_ind = "R" THEN 
		SELECT * 
		INTO fr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_bor.part_code 
		AND ware_code = fr_prodmfg.def_ware_code 

		CASE 
			WHEN pr_inparms.cost_ind matches "[WF]" 
				LET fv_unit_cost_amt = fr_prodstatus.wgted_cost_amt * 
				fr_prodmfg.man_stk_con_qty 

			WHEN pr_inparms.cost_ind = "L" 
				LET fv_unit_cost_amt = fr_prodstatus.act_cost_amt * 
				fr_prodmfg.man_stk_con_qty 

			WHEN pr_inparms.cost_ind = "S" 
				LET fv_unit_cost_amt = fr_prodstatus.est_cost_amt * 
				fr_prodmfg.man_stk_con_qty 
		END CASE 

		LET fv_unit_price_amt = fr_prodstatus.list_amt * 
		fr_prodmfg.man_stk_con_qty 
	ELSE 
		CASE 
			WHEN pr_inparms.cost_ind matches "[WF]" 
				LET fv_unit_cost_amt = fr_prodmfg.wgted_cost_amt 

			WHEN pr_inparms.cost_ind = "L" 
				LET fv_unit_cost_amt = fr_prodmfg.act_cost_amt 

			WHEN pr_inparms.cost_ind = "S" 
				LET fv_unit_cost_amt = fr_prodmfg.est_cost_amt 
		END CASE 

		IF fv_unit_cost_amt IS NULL THEN 
			LET fv_unit_cost_amt = 0 
		END IF 

		IF fr_prodmfg.list_price_amt IS NULL THEN 
			LET fr_prodmfg.list_price_amt = 0 
		END IF 

		LET fv_unit_price_amt = fr_prodmfg.list_price_amt 
	END IF 

	IF pr_bor.type_ind = "B" THEN 
		LET fv_unit_cost_amt = 0 
		LET fv_unit_price_amt = 0 
	END IF 

	CASE 
		WHEN pr_bor.uom_code = fr_product.pur_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt / 
			(fr_prodmfg.man_stk_con_qty / 
			fr_product.pur_stk_con_qty) 
			LET fv_unit_price_amt = fv_unit_price_amt / 
			(fr_prodmfg.man_stk_con_qty / 
			fr_product.pur_stk_con_qty) 

		WHEN pr_bor.uom_code = fr_product.stock_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt / 
			fr_prodmfg.man_stk_con_qty 
			LET fv_unit_price_amt = fv_unit_price_amt / 
			fr_prodmfg.man_stk_con_qty 

		WHEN pr_bor.uom_code = fr_product.sell_uom_code 
			LET fv_unit_cost_amt = fv_unit_cost_amt / 
			(fr_prodmfg.man_stk_con_qty * 
			fr_product.stk_sel_con_qty) 
			LET fv_unit_price_amt = fv_unit_price_amt / 
			(fr_prodmfg.man_stk_con_qty * 
			fr_product.stk_sel_con_qty) 
	END CASE 

	LET fv_ext_cost_amt = fv_unit_cost_amt * pr_bor.required_qty 
	LET fv_ext_price_amt = fv_unit_price_amt * pr_bor.required_qty 

	DISPLAY fv_unit_cost_amt, 
	fv_unit_price_amt, 
	fv_ext_cost_amt, 
	fv_ext_price_amt 
	TO cost_amt, 
	price_amt, 
	ext_cost_amt, 
	ext_price_amt 

END FUNCTION 



FUNCTION bor_check(fv_part_code) 

	DEFINE 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_part_code LIKE bor.part_code, 
	fa_parent array[500] OF LIKE bor.parent_part_code, 
	fv_cnt SMALLINT, 
	fv_parent_cnt SMALLINT 


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

		IF pr_bor.part_code = fa_parent[fv_cnt] THEN 
			LET pv_bor_flag = true 
			EXIT WHILE 
		END IF 

		CALL bor_check(fa_parent[fv_cnt]) 

		IF pv_bor_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

END FUNCTION 
