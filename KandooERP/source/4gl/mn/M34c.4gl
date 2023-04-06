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

	Source code beautified by beautify.pl on 2020-01-02 17:31:26	$Id: $
}


# Purpose - Shop Order Maintenance - Component/By Product details entry
#           SCREEN & Instruction details entry SCREEN
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M34.4gl" 


FUNCTION component_input() 

	DEFINE fv_cnt SMALLINT, 
	fv_part_code LIKE shoporddetl.part_code, 
	fv_old_part_code LIKE shoporddetl.part_code, 
	fv_ware_code LIKE shoporddetl.issue_ware_code, 
	fv_ware_desc LIKE warehouse.desc_text, 
	fv_vend_name LIKE vendor.name_text, 
	fv_uom_code LIKE shoporddetl.uom_code, 
	fv_orig_uom LIKE shoporddetl.uom_code, 
	fv_wc_code LIKE shoporddetl.work_centre_code, 
	fv_wkcen_desc LIKE workcentre.desc_text, 
	fv_ref_code LIKE userref.ref_code, 
	fv_stocked LIKE prodstatus.stocked_flag, 
	fv_status LIKE prodstatus.status_ind, 
	dummy CHAR(1), 

	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_product RECORD LIKE product.* 


	IF pr_shoporddetl.type_ind = "C" THEN 
		OPEN WINDOW w1_m139 with FORM "M139" 
		CALL  windecoration_m("M139") -- albo kd-762 

		DISPLAY BY NAME pr_shoporddetl.issued_qty 
	ELSE 
		OPEN WINDOW w1_m154 with FORM "M154" 
		CALL  windecoration_m("M154") -- albo kd-762 

		DISPLAY BY NAME pr_shoporddetl.receipted_qty, 
		pr_shoporddetl.rejected_qty 
	END IF 

	LET msgresp = kandoomsg("M", 1505, "") 	# MESSAGE "ESC TO Accept - DEL TO Exit"

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	LET fv_orig_uom = pr_shoporddetl.uom_code 

	INPUT BY NAME pr_shoporddetl.part_code, 
	pr_shoporddetl.issue_ware_code, 
	pr_shoporddetl.required_qty, 
	pr_shoporddetl.uom_code, 
	pr_shoporddetl.work_centre_code, 
	pr_shoporddetl.user1_text, 
	pr_shoporddetl.user2_text, 
	pr_shoporddetl.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			IF pr_shoporddetl.part_code IS NOT NULL THEN 
				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shoporddetl.part_code 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_shoporddetl.part_code 

				SELECT name_text 
				INTO fv_vend_name 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = fr_product.vend_code 

				SELECT desc_text 
				INTO fv_ware_desc 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_shoporddetl.issue_ware_code 

				SELECT desc_text 
				INTO fv_wkcen_desc 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_shoporddetl.work_centre_code 

				DISPLAY BY NAME pr_shoporddetl.desc_text, 
				pr_shoporddetl.start_date, 
				pr_shoporddetl.actual_start_date, 
				fr_product.vend_code 

				DISPLAY fv_ware_desc, fv_vend_name, fv_wkcen_desc 
				TO warehouse.desc_text, name_text, workcentre.desc_text 

				CALL show_costs() 
			ELSE 
				IF pr_shoporddetl.type_ind = "B" THEN 
					LET pr_shoporddetl.std_est_cost_amt = 0 
					LET pr_shoporddetl.std_wgted_cost_amt = 0 
					LET pr_shoporddetl.std_act_cost_amt = 0 
					LET pr_shoporddetl.std_price_amt = 0 
					LET pr_shoporddetl.required_qty = 1 

					CALL show_costs() 
				END IF 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(part_code) 
					IF pr_shoporddetl.type_ind = "B" THEN 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "MR") RETURNING fv_part_code 

						IF fv_part_code IS NOT NULL THEN 
							LET pr_shoporddetl.part_code = fv_part_code 
							DISPLAY BY NAME pr_shoporddetl.part_code 
						END IF 
					ELSE 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "") RETURNING fv_part_code 

						IF fv_part_code IS NOT NULL THEN 
							LET pr_shoporddetl.part_code = fv_part_code 
							DISPLAY BY NAME pr_shoporddetl.part_code 
						END IF 
					END IF 

				WHEN infield(issue_ware_code) 
					CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.part_code) 
					RETURNING fv_ware_code 

					IF fv_ware_code IS NOT NULL THEN 
						LET pr_shoporddetl.issue_ware_code = fv_ware_code 
						DISPLAY BY NAME pr_shoporddetl.issue_ware_code 
					END IF 

				WHEN infield(uom_code) 
					CALL lookup_uom(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.part_code) 
					RETURNING fv_uom_code 

					IF fv_uom_code IS NOT NULL THEN 
						LET pr_shoporddetl.uom_code = fv_uom_code 
						NEXT FIELD uom_code 
					END IF 

				WHEN infield(work_centre_code) 
					CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

					IF fv_wc_code IS NOT NULL THEN 
						LET pr_shoporddetl.work_centre_code = fv_wc_code 
						NEXT FIELD work_centre_code 
					END IF 

				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 

			END CASE 

		BEFORE FIELD part_code 
			LET fv_old_part_code = pr_shoporddetl.part_code 

		AFTER FIELD part_code 
			IF pr_shoporddetl.part_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9532, "") 
				# ERROR "Product code must be entered"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO fr_product.* 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9511, "") 
				# ERROR "This product does NOT exist in the database - Try Wind"
				NEXT FIELD part_code 
			END IF 

			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9569, "") 
				# ERROR "This product IS NOT SET up as a manufacturing product"
				NEXT FIELD part_code 
			END IF 

			IF pr_shoporddetl.type_ind = "B" 
			AND fr_prodmfg.part_type_ind NOT matches "[MR]" THEN 
				LET msgresp = kandoomsg("M", 9583, "") 
				# ERROR "A by-product can only be a manufactured OR purchased.."
				NEXT FIELD part_code 
			END IF 

			IF pr_shoporddetl.part_code = pr_shopordhead.part_code THEN 
				LET msgresp = kandoomsg("M", 9584, "") 
				#error"You cannot enter the parent product as a child of itself"
				NEXT FIELD part_code 
			END IF 

			LET pr_shoporddetl.desc_text = fr_product.desc_text 
			DISPLAY BY NAME pr_shoporddetl.desc_text 

			IF pr_shoporddetl.part_code != fv_old_part_code 
			OR fv_old_part_code IS NULL THEN 
				SELECT name_text 
				INTO fv_vend_name 
				FROM vendor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = fr_product.vend_code 

				LET pr_shoporddetl.issue_ware_code = fr_prodmfg.def_ware_code 
				LET pr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 

				SELECT desc_text 
				INTO fv_ware_desc 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_shoporddetl.issue_ware_code 

				DISPLAY BY NAME pr_shoporddetl.issue_ware_code, 
				fr_product.vend_code, 
				pr_shoporddetl.uom_code 
				DISPLAY fv_ware_desc, fv_vend_name 
				TO warehouse.desc_text, name_text 

				IF pr_shoporddetl.type_ind = "C" THEN 
					CALL update_costs(pr_shoporddetl.*, fr_product.*, 
					fr_prodmfg.*) 
					RETURNING pr_shoporddetl.* 
					CALL show_costs() 
				END IF 
			END IF 

		AFTER FIELD issue_ware_code 
			IF pr_shoporddetl.issue_ware_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9762, "") 
				# ERROR "Warehouse code must be entered"
				NEXT FIELD issue_ware_code 
			END IF 

			SELECT desc_text 
			INTO fv_ware_desc 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_shoporddetl.issue_ware_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9534, "") 
				# ERROR "This warehouse does NOT exist in the database -Try win"
				NEXT FIELD issue_ware_code 
			END IF 

			SELECT stocked_flag, status_ind 
			INTO fv_stocked, fv_status 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 
			AND ware_code = pr_shoporddetl.issue_ware_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9535, "") 
				# ERROR "This warehouse IS NOT SET up FOR this product"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_stocked = "N" THEN 
				LET msgresp = kandoomsg("M", 9763, "") 
				# ERROR "This product IS NOT stocked AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_status = "2" THEN 
				LET msgresp = kandoomsg("M", 9764, "") 
				# ERROR "This product IS on hold AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_status = "3" THEN 
				LET msgresp = kandoomsg("M", 9765, "") 
				# ERROR "This product IS marked FOR deletion AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			DISPLAY fv_ware_desc TO warehouse.desc_text 

			IF pr_shoporddetl.type_ind = "C" THEN 
				CALL update_costs(pr_shoporddetl.*, fr_product.*, fr_prodmfg.*) 
				RETURNING pr_shoporddetl.* 
				CALL show_costs() 
			END IF 

		AFTER FIELD required_qty 
			IF pr_shoporddetl.required_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9586, "") 
				# ERROR "Quantity must be entered"
				NEXT FIELD required_qty 
			END IF 

			IF pr_shoporddetl.required_qty <= 0 THEN 
				LET msgresp = kandoomsg("M", 9614, "") 
				# ERROR "Quantity must be greater than zero"
				NEXT FIELD required_qty 
			END IF 

			CALL show_costs() 

		BEFORE FIELD uom_code 
			IF pr_shopordhead.status_ind = "R" 
			AND pr_shoporddetl.sequence_num IS NOT NULL 
			AND ((pr_shoporddetl.type_ind = "C" 
			AND pr_shoporddetl.issued_qty > 0) 
			OR (pr_shoporddetl.type_ind = "B" 
			AND (pr_shoporddetl.receipted_qty < 0 
			OR pr_shoporddetl.rejected_qty < 0))) THEN 

				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD required_qty 
				ELSE 
					NEXT FIELD work_centre_code 
				END IF 
			END IF 

		AFTER FIELD uom_code 
			IF pr_shoporddetl.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9547, "") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD uom_code 
			END IF 

			SELECT uom_code 
			FROM uom 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND uom_code = pr_shoporddetl.uom_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9548, "") 
				# ERROR "Unit of measure code NOT valid - Try Window"
				NEXT FIELD uom_code 
			END IF 

			IF pr_shoporddetl.uom_code != fr_prodmfg.man_uom_code 
			AND pr_shoporddetl.uom_code != fr_product.pur_uom_code 
			AND pr_shoporddetl.uom_code != fr_product.stock_uom_code 
			AND pr_shoporddetl.uom_code != fr_product.sell_uom_code THEN 
				LET msgresp = kandoomsg("M", 9587, "") 
				#ERROR "Unit of measure code NOT valid FOR this product-Try Win"
				NEXT FIELD uom_code 
			END IF 

			IF pr_shoporddetl.type_ind = "C" THEN 
				CALL update_costs(pr_shoporddetl.*, fr_product.*, fr_prodmfg.*) 
				RETURNING pr_shoporddetl.* 
				CALL show_costs() 
			END IF 

		AFTER FIELD work_centre_code 
			IF pr_shoporddetl.work_centre_code IS NOT NULL THEN 
				SELECT desc_text 
				INTO fv_wkcen_desc 
				FROM workcentre 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND work_centre_code = pr_shoporddetl.work_centre_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9527, "") 
					# ERROR "Work Centre does NOT exist in the database-Try Win"
					NEXT FIELD work_centre_code 
				END IF 

				DISPLAY fv_wkcen_desc TO workcentre.desc_text 
			ELSE 
				DISPLAY "" TO workcentre.desc_text 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_shoporddetl.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
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
			IF pr_shoporddetl.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
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
			IF pr_shoporddetl.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_shoporddetl.required_qty IS NULL THEN 
				LET msgresp = kandoomsg("M", 9586, "") 
				# ERROR "Quantity must be entered"
				NEXT FIELD required_qty 
			END IF 

			IF pr_shoporddetl.issue_ware_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9762, "") 
				# ERROR "Warehouse code must be entered"
				NEXT FIELD issue_ware_code 
			END IF 

			SELECT stocked_flag, status_ind 
			INTO fv_stocked, fv_status 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_shoporddetl.part_code 
			AND ware_code = pr_shoporddetl.issue_ware_code 

			IF status = notfound THEN 
				LET msgresp = kandoomsg("M", 9535, "") 
				# ERROR "This warehouse IS NOT SET up FOR this product"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_stocked = "N" THEN 
				LET msgresp = kandoomsg("M", 9763, "") 
				# ERROR "This product IS NOT stocked AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_status = "2" THEN 
				LET msgresp = kandoomsg("M", 9764, "") 
				# ERROR "This product IS on hold AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF fv_status = "3" THEN 
				LET msgresp = kandoomsg("M", 9765, "") 
				# ERROR "This product IS marked FOR deletion AT this warehouse"
				NEXT FIELD issue_ware_code 
			END IF 

			IF pr_shoporddetl.uom_code IS NULL THEN 
				LET msgresp = kandoomsg("M", 9547, "") 
				# ERROR "Unit of measure code must be entered"
				NEXT FIELD uom_code 
			END IF 

			IF pr_shoporddetl.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_shoporddetl.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_shoporddetl.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 

	END INPUT 

	IF pr_shoporddetl.type_ind = "C" THEN 
		CLOSE WINDOW w1_m139 
	ELSE 
		CLOSE WINDOW w1_m154 
	END IF 

	RETURN fr_prodmfg.part_type_ind 

END FUNCTION 



FUNCTION show_costs() 

	DEFINE fv_unit_cost_amt LIKE shoporddetl.std_est_cost_amt, 
	fv_ext_cost_amt LIKE shoporddetl.std_est_cost_amt, 
	fv_ext_price_amt LIKE shoporddetl.std_price_amt, 
	fv_act_unit_cost LIKE shoporddetl.act_est_cost_amt, 
	fv_act_ext_cost LIKE shoporddetl.act_est_cost_amt, 
	fv_act_ext_price LIKE shoporddetl.act_price_amt 


	CASE 
		WHEN pr_inparms.cost_ind = "S" 
			LET fv_unit_cost_amt = pr_shoporddetl.std_est_cost_amt 
			LET fv_act_unit_cost = pr_shoporddetl.act_est_cost_amt 

		WHEN pr_inparms.cost_ind matches "[WF]" 
			LET fv_unit_cost_amt = pr_shoporddetl.std_wgted_cost_amt 
			LET fv_act_unit_cost = pr_shoporddetl.act_wgted_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET fv_unit_cost_amt = pr_shoporddetl.std_act_cost_amt 
			LET fv_act_unit_cost = pr_shoporddetl.act_act_cost_amt 
	END CASE 

	LET fv_ext_cost_amt = fv_unit_cost_amt * pr_shoporddetl.required_qty 
	LET fv_ext_price_amt = pr_shoporddetl.std_price_amt * 
	pr_shoporddetl.required_qty 
	LET fv_act_ext_cost = fv_act_unit_cost * pr_shoporddetl.issued_qty 
	LET fv_act_ext_price = pr_shoporddetl.act_price_amt * 
	pr_shoporddetl.issued_qty 

	IF pr_shoporddetl.type_ind = "B" THEN 
		LET fv_act_ext_cost = fv_act_unit_cost * pr_shoporddetl.receipted_qty 
		LET fv_act_ext_price = pr_shoporddetl.act_price_amt * 
		pr_shoporddetl.receipted_qty 
	END IF 

	DISPLAY BY NAME pr_shoporddetl.std_price_amt, 
	pr_shoporddetl.act_price_amt 

	DISPLAY fv_unit_cost_amt, 
	fv_ext_cost_amt, 
	fv_ext_price_amt, 
	fv_act_unit_cost, 
	fv_act_ext_cost, 
	fv_act_ext_price 
	TO unit_cost_amt, 
	ext_cost_amt, 
	ext_price_amt, 
	act_unit_cost_amt, 
	act_ext_cost_amt, 
	act_ext_price_amt 

END FUNCTION 



FUNCTION instruct_input() 

	DEFINE fv_ref_code LIKE userref.ref_code, 
	dummy CHAR(1) 

	OPEN WINDOW w1_m140 with FORM "M140" 
	CALL  windecoration_m("M140") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1505, "") 	# MESSAGE "ESC TO Accept - DEL TO Exit"

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text 
	END IF 

	INPUT BY NAME pr_shoporddetl.desc_text, 
	pr_shoporddetl.user1_text, 
	pr_shoporddetl.user2_text, 
	pr_shoporddetl.user3_text, 
	dummy 
	WITHOUT DEFAULTS 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(user1_text) 
					IF pr_mnparms.ref1_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","1") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user1_text = fv_ref_code 
							NEXT FIELD user1_text 
						END IF 
					END IF 

				WHEN infield(user2_text) 
					IF pr_mnparms.ref2_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","2") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user2_text = fv_ref_code 
							NEXT FIELD user2_text 
						END IF 
					END IF 

				WHEN infield(user3_text) 
					IF pr_mnparms.ref3_ind matches "[34]" THEN 
						CALL show_ref(glob_rec_kandoouser.cmpy_code,"M","3") RETURNING fv_ref_code 

						IF fv_ref_code IS NOT NULL THEN 
							LET pr_shoporddetl.user3_text = fv_ref_code 
							NEXT FIELD user3_text 
						END IF 
					END IF 

			END CASE 

		ON ACTION "NOTES" infield (desc_text) --ON KEY (control-n) 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pr_shoporddetl.desc_text) 
				RETURNING pr_shoporddetl.desc_text 
				DISPLAY BY NAME pr_shoporddetl.desc_text 


		AFTER FIELD desc_text 
			IF pr_shoporddetl.desc_text IS NULL THEN 
				LET msgresp = kandoomsg("M", 9591, "") 
				# ERROR "Description must be entered"
				NEXT FIELD desc_text 
			END IF 

		BEFORE FIELD user1_text 
			IF pr_mnparms.ref1_ind NOT matches "[1234]" 
			OR pr_mnparms.ref1_ind IS NULL THEN 
				NEXT FIELD user2_text 
			END IF 

		AFTER FIELD user1_text 
			IF pr_shoporddetl.user1_text IS NULL THEN 
				IF pr_mnparms.ref1_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user1_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
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
			IF pr_shoporddetl.user2_text IS NULL THEN 
				IF pr_mnparms.ref2_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user2_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
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
			IF pr_shoporddetl.user3_text IS NULL THEN 
				IF pr_mnparms.ref3_ind matches "[24]" THEN 
					LET msgresp = kandoomsg("M", 9589, "") 
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
					AND ref_code = pr_shoporddetl.user3_text 

					IF status = notfound THEN 
						LET msgresp = kandoomsg("M", 9590, "") 
						# ERROR "User defined INPUT NOT valid - Try Window"
						NEXT FIELD user3_text 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF pr_shoporddetl.user1_text IS NULL 
			AND pr_mnparms.ref1_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user1_text 
			END IF 

			IF pr_shoporddetl.user2_text IS NULL 
			AND pr_mnparms.ref2_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user2_text 
			END IF 

			IF pr_shoporddetl.user3_text IS NULL 
			AND pr_mnparms.ref3_ind matches "[24]" THEN 
				LET msgresp = kandoomsg("M", 9589, "") 
				# ERROR "User defined field must be entered"
				NEXT FIELD user3_text 
			END IF 

	END INPUT 

	CLOSE WINDOW w1_m140 

END FUNCTION 
