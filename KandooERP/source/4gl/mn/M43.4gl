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

	Source code beautified by beautify.pl on 2020-01-02 17:31:28	$Id: $
}


# Purpose - Shop Order Issue


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
	pv_first SMALLINT, 

	pr_menunames RECORD LIKE menunames.*, 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M43") -- albo 
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

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Any key TO continue"
		EXIT program 
	END IF 

	CALL input_issue() 

END MAIN 



FUNCTION input_issue() 

	DEFINE fv_part_code LIKE shopordhead.part_code, 
	fv_ware_code LIKE warehouse.ware_code, 
	fv_ware_desc LIKE warehouse.desc_text, 
	fv_wc_code LIKE workcentre.work_centre_code, 
	fv_wc_desc LIKE workcentre.desc_text, 
	fv_so_num LIKE shopordhead.shop_order_num, 
	fv_suffix_num LIKE shopordhead.suffix_num, 
	fv_status_ind LIKE shopordhead.status_ind, 
	fv_order_type_ind LIKE shopordhead.order_type_ind, 
	fv_old_part_code LIKE shoporddetl.part_code, 
	fv_old_ware_code LIKE prodstatus.ware_code, 
	fv_stk_qty LIKE prodledg.tran_qty, 
	fv_stk_cost_amt LIKE prodstatus.wgted_cost_amt, 
	fv_remaining_tot LIKE prodstatus.onhand_qty, 
	fv_remaining_qty LIKE prodstatus.onhand_qty, 
	fv_issued_qty LIKE prodstatus.onhand_qty, 
	fv_soissued_qty LIKE prodstatus.onhand_qty, 
	fv_cnt SMALLINT, 
	fv_failed SMALLINT, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodledg RECORD LIKE prodledg.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_shopordhead RECORD LIKE shopordhead.*, 
	fr_firstsodetl RECORD LIKE shoporddetl.*, 
	fr_lastsodetl RECORD LIKE shoporddetl.*, 

	fr_soissue RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE warehouse.ware_code, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		source_text LIKE prodledg.source_text, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		tran_desc LIKE prodledg.desc_text, 
		issued_qty LIKE shoporddetl.issued_qty 
	END RECORD 

	OPEN WINDOW w1_m161 with FORM "M161" 
	CALL  windecoration_m("M161") -- albo kd-762 

	WHILE true 

		LET msgresp = kandoomsg("M", 1505, "") 
		# MESSAGE "ESC TO Accept - DEL TO Exit"

		CLEAR FORM 
		INITIALIZE fr_soissue TO NULL 
		LET fr_soissue.source_text = "SO Issue" 
		LET fr_soissue.tran_date = today 

		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
		RETURNING fr_soissue.year_num, fr_soissue.period_num 

		INPUT BY NAME fr_soissue.part_code, 
		fr_soissue.ware_code, 
		fr_soissue.work_centre_code, 
		fr_soissue.shop_order_num, 
		fr_soissue.suffix_num, 
		fr_soissue.source_text, 
		fr_soissue.tran_date, 
		fr_soissue.year_num, 
		fr_soissue.period_num, 
		fr_soissue.tran_desc, 
		fr_soissue.issued_qty 
		WITHOUT DEFAULTS 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(part_code) 
						CALL show_mfgprods(glob_rec_kandoouser.cmpy_code, "MR") RETURNING fv_part_code 

						IF fv_part_code IS NOT NULL THEN 
							LET fr_soissue.part_code = fv_part_code 
							DISPLAY BY NAME fr_soissue.part_code 
						END IF 

					WHEN infield(ware_code) 
						CALL show_ware_part_code(glob_rec_kandoouser.cmpy_code, fr_soissue.part_code) 
						RETURNING fv_ware_code 

						IF fv_ware_code IS NOT NULL THEN 
							LET fr_soissue.ware_code = fv_ware_code 
							DISPLAY BY NAME fr_soissue.ware_code 
						END IF 

					WHEN infield(work_centre_code) 
						CALL show_centres(glob_rec_kandoouser.cmpy_code) RETURNING fv_wc_code 

						IF fv_wc_code IS NOT NULL THEN 
							LET fr_soissue.work_centre_code = fv_wc_code 
							DISPLAY BY NAME fr_soissue.work_centre_code 
						END IF 

					WHEN infield(shop_order_num) 
						CALL show_shopords(glob_rec_kandoouser.cmpy_code) 
						RETURNING fv_so_num, fv_suffix_num 

						IF fv_so_num IS NOT NULL THEN 
							LET fr_soissue.shop_order_num = fv_so_num 
							LET fr_soissue.suffix_num = fv_suffix_num 

							DISPLAY BY NAME fr_soissue.shop_order_num, 
							fr_soissue.suffix_num 
						END IF 

					WHEN infield(suffix_num) 
						CALL show_shopords(glob_rec_kandoouser.cmpy_code) 
						RETURNING fv_so_num, fv_suffix_num 

						IF fv_so_num IS NOT NULL THEN 
							LET fr_soissue.shop_order_num = fv_so_num 
							LET fr_soissue.suffix_num = fv_suffix_num 

							DISPLAY BY NAME fr_soissue.shop_order_num, 
							fr_soissue.suffix_num 
						END IF 
				END CASE 

			BEFORE FIELD part_code 
				LET fv_old_part_code = fr_soissue.part_code 

			AFTER FIELD part_code 
				IF fr_soissue.part_code IS NULL THEN 
					LET msgresp = kandoomsg("M", 9532, "") 
					# ERROR "Product code must be entered"
					NEXT FIELD part_code 
				END IF 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_soissue.part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9511, "") 
					#ERROR "This product does NOT exist in the database-Try win"
					NEXT FIELD part_code 
				END IF 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_soissue.part_code 

				IF status = notfound THEN 
					ERROR "This product IS NOT SET up as a manufacturing ", 
					"product - Try window" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD part_code 
				END IF 

				IF fr_prodmfg.part_type_ind matches "[GP]" THEN 
					ERROR "You cannot issue a generic OR phantom product TO a ", 
					"shop ORDER" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD part_code 
				END IF 

				IF fv_old_part_code != fr_soissue.part_code 
				OR fv_old_part_code IS NULL THEN 
					LET fr_soissue.ware_code = fr_prodmfg.def_ware_code 

					DISPLAY BY NAME fr_product.desc_text, 
					fr_soissue.ware_code 

					SELECT desc_text 
					INTO fv_ware_desc 
					FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = fr_soissue.ware_code 

					DISPLAY fv_ware_desc TO warehouse.desc_text 

					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_soissue.part_code 
					AND ware_code = fr_soissue.ware_code 

					IF status != notfound 
					AND fr_prodstatus.stocked_flag = "Y" 
					AND fr_prodstatus.status_ind = "1" THEN 
						CALL display_costs(fr_prodmfg.*, fr_product.*, 
						fr_prodstatus.*, 
						fr_soissue.issued_qty) 
						RETURNING fv_stk_qty, fv_stk_cost_amt 
					END IF 

					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						NEXT FIELD ware_code 
					END IF 
				END IF 

			BEFORE FIELD ware_code 
				LET fv_old_ware_code = fr_soissue.ware_code 

			AFTER FIELD ware_code 
				IF fr_soissue.ware_code IS NULL THEN 
					ERROR "Warehouse code must be entered" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD ware_code 
				END IF 

				SELECT desc_text 
				INTO fv_ware_desc 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = fr_soissue.ware_code 

				IF status = notfound THEN 
					ERROR "This warehouse does NOT exist - Try window" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD ware_code 
				END IF 

				DISPLAY fv_ware_desc TO warehouse.desc_text 

				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_soissue.part_code 
				AND ware_code = fr_soissue.ware_code 

				IF status = notfound THEN 
					ERROR "This warehouse IS NOT SET up FOR this product" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD ware_code 
				END IF 

				IF fr_prodstatus.stocked_flag = "N" THEN 
					ERROR "This product IS NOT stocked AT this warehouse" 
					--- modif ericv init # attributes (red, reverse)
					NEXT FIELD part_code 
				END IF 

				IF fr_prodstatus.status_ind != "1" THEN 
					ERROR "This product IS NOT available FOR issue FROM this ", 
					"warehouse" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD part_code 
				END IF 

				IF fv_old_ware_code != fr_soissue.ware_code 
				OR fv_old_ware_code IS NULL THEN 
					CALL display_costs(fr_prodmfg.*, fr_product.*, 
					fr_prodstatus.*, fr_soissue.issued_qty) 
					RETURNING fv_stk_qty, fv_stk_cost_amt 

					IF fgl_lastkey() = fgl_keyval("accept") THEN 
						NEXT FIELD issued_qty 
					END IF 
				END IF 

			AFTER FIELD work_centre_code 
				IF fr_soissue.work_centre_code IS NOT NULL THEN 
					SELECT desc_text 
					INTO fv_wc_desc 
					FROM workcentre 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND work_centre_code = fr_soissue.work_centre_code 

					DISPLAY fv_wc_desc TO workcentre.desc_text 
				ELSE 
					DISPLAY "" TO workcentre.desc_text 
				END IF 

			AFTER FIELD shop_order_num 
				IF fr_soissue.shop_order_num IS NULL THEN 
					ERROR "Shop ORDER number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

				SELECT unique shop_order_num 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 

				IF status = notfound THEN 
					ERROR "This shop ORDER does NOT exist - Try window" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

				IF fr_soissue.suffix_num IS NULL THEN 
					LET fr_soissue.suffix_num = 0 
					DISPLAY BY NAME fr_soissue.suffix_num 
				END IF 

			AFTER FIELD suffix_num 
				IF fr_soissue.suffix_num IS NULL THEN 
					ERROR "Shop ORDER suffix number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD suffix_num 
				END IF 

				SELECT status_ind, order_type_ind 
				INTO fv_status_ind, fv_order_type_ind 
				FROM shopordhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 
				AND suffix_num = fr_soissue.suffix_num 

				IF status = notfound THEN 
					ERROR "Incorrect suffix number FOR this shop ORDER - Try ", 
					"Window" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD suffix_num 
				END IF 

				IF fv_order_type_ind = "F" THEN 
					ERROR "This IS a forecast shop ORDER AND cannot be issued TO" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

				IF fv_status_ind = "C" THEN 
					ERROR "This shop ORDER IS closed" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

				SELECT unique part_code 
				FROM shoporddetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 
				AND suffix_num = fr_soissue.suffix_num 
				AND type_ind = "C" 
				AND part_code = fr_soissue.part_code 

				IF status = notfound THEN 
					ERROR "This shop ORDER does NOT contain this product" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

			AFTER FIELD source_text 
				IF fr_soissue.source_text IS NULL THEN 
					ERROR "Source ID must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD source_text 
				END IF 

			AFTER FIELD tran_date 
				IF fr_soissue.tran_date IS NULL THEN 
					ERROR "Transaction date must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD tran_date 
				END IF 

				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, fr_soissue.tran_date) 
				RETURNING fr_soissue.year_num, fr_soissue.period_num 

				DISPLAY BY NAME fr_soissue.year_num, 
				fr_soissue.period_num 

			AFTER FIELD year_num 
				IF fr_soissue.year_num IS NULL THEN 
					ERROR "Year number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD year_num 
				END IF 

			AFTER FIELD period_num 
				IF fr_soissue.period_num IS NULL THEN 
					ERROR "Period number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD period_num 
				END IF 

				CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_soissue.year_num, 
				fr_soissue.period_num, TRAN_TYPE_INVOICE_IN) 
				RETURNING fr_soissue.year_num, fr_soissue.period_num, 
				fv_failed 

				IF fv_failed THEN 
					NEXT FIELD year_num 
				END IF 

			AFTER FIELD issued_qty 
				IF fr_soissue.issued_qty IS NULL THEN 
					ERROR "Issue quantity must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD issued_qty 
				END IF 

				IF fr_soissue.issued_qty <= 0 THEN 
					ERROR "Issue quantity must be greater than 0" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD issued_qty 
				END IF 

				LET fv_stk_qty = fr_soissue.issued_qty * 
				fr_prodmfg.man_stk_con_qty 
				DISPLAY fv_stk_qty TO tran_qty 

				IF pr_mnparms.neg_issue_flag = "N" 
				AND fv_stk_qty > fr_prodstatus.onhand_qty THEN 
					ERROR "There IS NOT enough stock TO issue this quantity" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD issued_qty 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF fr_soissue.shop_order_num IS NULL THEN 
					ERROR "Shop ORDER number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD shop_order_num 
				END IF 

				IF fr_soissue.suffix_num IS NULL THEN 
					ERROR "Shop ORDER suffix number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD suffix_num 
				END IF 

				IF fr_soissue.year_num IS NULL THEN 
					ERROR "Year number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD year_num 
				END IF 

				IF fr_soissue.period_num IS NULL THEN 
					ERROR "Period number must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD period_num 
				END IF 

				CALL valid_period(glob_rec_kandoouser.cmpy_code, fr_soissue.year_num, 
				fr_soissue.period_num, TRAN_TYPE_INVOICE_IN) 
				RETURNING fr_soissue.year_num, fr_soissue.period_num, 
				fv_failed 

				IF fv_failed THEN 
					NEXT FIELD year_num 
				END IF 

				IF fr_soissue.issued_qty IS NULL THEN 
					ERROR "Issue quantity must be entered" 
					--- modif ericv init #  attributes (red, reverse)
					NEXT FIELD issued_qty 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET fr_soissue.tran_desc[21,25] = fr_soissue.suffix_num 

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
			### SELECT shopordhead record
			###

			LET err_message = "M43 - SELECT FROM shopordhead failed" 

			SELECT * 
			INTO fr_shopordhead.* 
			FROM shopordhead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = fr_soissue.shop_order_num 
			AND suffix_num = fr_soissue.suffix_num 

			###
			### Update shoporddetl table AND reverse out the reserved qty on prodstatus
			###

			LET fv_remaining_tot = fv_stk_qty 
			LET pv_first = false 
			LET fv_cnt = 0 
			LET err_message = "M43 - SELECT FROM shoporddetl failed" 

			IF fr_soissue.work_centre_code IS NOT NULL THEN 
				DECLARE c_wcsodetl CURSOR FOR 
				SELECT * 
				FROM shoporddetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 
				AND suffix_num = fr_soissue.suffix_num 
				AND type_ind = "C" 
				AND part_code = fr_soissue.part_code 
				AND work_centre_code = fr_soissue.work_centre_code 
				ORDER BY sequence_num 

				FOREACH c_wcsodetl INTO fr_shoporddetl.* 
					IF fr_shoporddetl.required_qty <= fr_shoporddetl.issued_qty THEN 
						IF NOT pv_first THEN 
							LET fr_firstsodetl.* = fr_shoporddetl.* 
							LET pv_first = true 
						END IF 

						CONTINUE FOREACH 
					END IF 

					CALL so_update(fr_product.*, fr_prodmfg.*, fr_soissue.*, 
					fr_prodstatus.*, fr_shoporddetl.*, 
					fr_shopordhead.*, fv_remaining_tot) 
					RETURNING fr_prodstatus.*, fr_shoporddetl.*, 
					fr_shopordhead.*, fv_remaining_tot 

					LET fv_cnt = fv_cnt + 1 
					LET fr_lastsodetl.* = fr_shoporddetl.* 

					IF fv_remaining_tot = 0 THEN 
						EXIT FOREACH 
					END IF 
				END FOREACH 
			END IF 

			IF fv_remaining_tot > 0 THEN 
				LET err_message = "M43 - SELECT FROM shoporddetl failed" 

				DECLARE c_shoporddetl CURSOR FOR 
				SELECT * 
				FROM shoporddetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 
				AND suffix_num = fr_soissue.suffix_num 
				AND type_ind = "C" 
				AND part_code = fr_soissue.part_code 
				ORDER BY sequence_num 

				FOREACH c_shoporddetl INTO fr_shoporddetl.* 
					IF fr_shoporddetl.required_qty <= fr_shoporddetl.issued_qty THEN 
						IF NOT pv_first THEN 
							LET fr_firstsodetl.* = fr_shoporddetl.* 
							LET pv_first = true 
						END IF 

						CONTINUE FOREACH 
					END IF 

					CALL so_update(fr_product.*, fr_prodmfg.*, fr_soissue.*, 
					fr_prodstatus.*, fr_shoporddetl.*, 
					fr_shopordhead.*, fv_remaining_tot) 
					RETURNING fr_prodstatus.*, fr_shoporddetl.*, 
					fr_shopordhead.*, fv_remaining_tot 

					LET fv_cnt = fv_cnt + 1 
					LET fr_lastsodetl.* = fr_shoporddetl.* 

					IF fv_remaining_tot = 0 THEN 
						EXIT FOREACH 
					END IF 
				END FOREACH 
			END IF 

			IF fv_cnt = 0 AND pv_first THEN 
				CALL so_update(fr_product.*, fr_prodmfg.*, fr_soissue.*, 
				fr_prodstatus.*, fr_firstsodetl.*, fr_shopordhead.*, 
				fv_remaining_tot) 
				RETURNING fr_prodstatus.*, fr_shoporddetl.*, fr_shopordhead.*, 
				fv_remaining_tot 
			END IF 

			IF fv_remaining_tot > 0 THEN 
				LET fr_shoporddetl.* = fr_lastsodetl.* 

				CASE 
					WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
						LET fv_remaining_tot = fv_remaining_tot / 
						fr_prodmfg.man_stk_con_qty 

					WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
						LET fv_remaining_tot = fv_remaining_tot * 
						fr_product.stk_sel_con_qty 

					WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
						LET fv_remaining_tot = fv_remaining_tot / 
						fr_product.pur_stk_con_qty 
				END CASE 

				LET err_message = "M43 - Update of shoporddetl failed" 

				UPDATE shoporddetl 
				SET issued_qty = issued_qty + fv_remaining_tot 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND shop_order_num = fr_soissue.shop_order_num 
				AND suffix_num = fr_soissue.suffix_num 
				AND part_code = fr_soissue.part_code 
				AND sequence_num = fr_shoporddetl.sequence_num 

				LET fr_shopordhead.act_est_cost_amt = 
				fr_shopordhead.act_est_cost_amt + 
				(fr_shoporddetl.act_est_cost_amt * fv_remaining_tot) 

				LET fr_shopordhead.act_wgted_cost_amt = 
				fr_shopordhead.act_wgted_cost_amt + 
				(fr_shoporddetl.act_wgted_cost_amt * fv_remaining_tot) 

				LET fr_shopordhead.act_act_cost_amt = 
				fr_shopordhead.act_act_cost_amt + 
				(fr_shoporddetl.act_act_cost_amt * fv_remaining_tot) 

				LET fr_shopordhead.act_price_amt = fr_shopordhead.act_price_amt + 
				(fr_shoporddetl.act_price_amt * fv_remaining_tot) 
			END IF 

			###
			### Update onhand qty on prodstatus
			###

			LET fr_prodstatus.onhand_qty = fr_prodstatus.onhand_qty - 
			fv_stk_qty 
			LET fr_prodstatus.seq_num = fr_prodstatus.seq_num + 1 
			LET fr_prodstatus.last_sale_date = fr_soissue.tran_date 
			LET err_message = "M43 - Update of prodstatus failed" 

			UPDATE prodstatus 
			SET * = fr_prodstatus.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_soissue.part_code 
			AND ware_code = fr_soissue.ware_code 

			###
			### Update shopordhead table
			###

			IF fr_shopordhead.release_date IS NULL THEN 
				LET fr_shopordhead.release_date = fr_soissue.tran_date 
			END IF 

			IF fr_shopordhead.actual_start_date IS NULL THEN 
				LET fr_shopordhead.actual_start_date = fr_soissue.tran_date 
			END IF 

			LET fr_shopordhead.status_ind = "R" 
			LET fr_shopordhead.last_change_date = today 
			LET fr_shopordhead.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_shopordhead.last_program_text = "M43" 
			LET err_message = "M43 - Update of shopordhead failed" 

			UPDATE shopordhead 
			SET * = fr_shopordhead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shop_order_num = fr_soissue.shop_order_num 
			AND suffix_num = fr_soissue.suffix_num 

			###
			### Insert row INTO prodledg table
			###

			LET fr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_prodledg.part_code = fr_soissue.part_code 
			LET fr_prodledg.ware_code = fr_soissue.ware_code 
			LET fr_prodledg.tran_date = fr_soissue.tran_date 
			LET fr_prodledg.seq_num = fr_prodstatus.seq_num 
			LET fr_prodledg.trantype_ind = "I" 
			LET fr_prodledg.year_num = fr_soissue.year_num 
			LET fr_prodledg.period_num = fr_soissue.period_num 
			LET fr_prodledg.source_text = fr_soissue.source_text 
			LET fr_prodledg.source_num = fr_soissue.shop_order_num 
			LET fr_prodledg.tran_qty = - fv_stk_qty 
			LET fr_prodledg.cost_amt = fv_stk_cost_amt 
			LET fr_prodledg.sales_amt = fr_prodstatus.list_amt 
			LET fr_prodledg.hist_flag = "N" 
			LET fr_prodledg.post_flag = "N" 
			LET fr_prodledg.jour_num = 0 
			LET fr_prodledg.desc_text = fr_soissue.tran_desc 
			LET fr_prodledg.acct_code = pr_mnparms.inv_exp_acct_code 
			LET fr_prodledg.bal_amt = fr_prodstatus.onhand_qty 
			LET fr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET fr_prodledg.entry_date = today 

			LET err_message = "M43 - Insert INTO prodledg failed" 

			INSERT INTO prodledg VALUES (fr_prodledg.*) 

			IF fr_product.serial_flag = "Y" THEN 
				LET fv_failed = ser_update(glob_rec_kandoouser.cmpy_code, fr_soissue.part_code, 
				fr_soissue.ware_code, fr_soissue.source_text, -1, 
				fr_soissue.tran_date, fv_stk_qty) 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 

		LET msgresp = kandoomsg("M", 7503, "") 
		# prompt "Product issued successfully - Press any key"

	END WHILE 

	CLOSE WINDOW w1_m161 

END FUNCTION 



FUNCTION display_costs(fr_prodmfg, fr_product, fr_prodstatus, fv_issue_qty) 

	DEFINE fv_avail_qty LIKE prodstatus.onhand_qty, 
	fv_availf_qty LIKE prodstatus.onhand_qty, 
	fv_issue_qty LIKE shoporddetl.issued_qty, 
	fv_man_cost_amt LIKE shoporddetl.act_wgted_cost_amt, 
	fv_stk_cost_amt LIKE prodstatus.wgted_cost_amt, 
	fv_stk_qty LIKE prodstatus.onhand_qty, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.* 


	LET fv_avail_qty = fr_prodstatus.onhand_qty - 
	fr_prodstatus.reserved_qty - 
	fr_prodstatus.back_qty 
	LET fv_availf_qty = fv_avail_qty + fr_prodstatus.onord_qty - 
	fr_prodstatus.forward_qty 

	CASE pr_inparms.cost_ind 
		WHEN "W" 
			LET fv_stk_cost_amt = fr_prodstatus.wgted_cost_amt 
		WHEN "F" 
			LET fv_stk_cost_amt = fr_prodstatus.wgted_cost_amt 
		WHEN "S" 
			LET fv_stk_cost_amt = fr_prodstatus.est_cost_amt 
		WHEN "L" 
			LET fv_stk_cost_amt = fr_prodstatus.act_cost_amt 
	END CASE 

	LET fv_man_cost_amt = fv_stk_cost_amt * fr_prodmfg.man_stk_con_qty 
	LET fv_stk_qty = fv_issue_qty * fr_prodmfg.man_stk_con_qty 

	DISPLAY BY NAME fr_prodstatus.onhand_qty, 
	fr_prodstatus.reserved_qty, 
	fr_prodstatus.back_qty, 
	fr_prodstatus.onord_qty, 
	fr_prodstatus.forward_qty, 
	fr_prodmfg.man_uom_code, 
	fr_product.stock_uom_code 

	DISPLAY fv_avail_qty, 
	fv_avail_qty, 
	fv_availf_qty, 
	fv_stk_qty, 
	fv_man_cost_amt, 
	fr_prodmfg.man_uom_code, 
	fv_stk_cost_amt, 
	fr_product.stock_uom_code 
	TO avail_qty, 
	avail1_qty, 
	availf_qty, 
	tran_qty, 
	man_cost_amt, 
	man_uom, 
	cost_amt, 
	stock_uom 

	RETURN fv_stk_qty, fv_stk_cost_amt 

END FUNCTION 



FUNCTION so_update(fr_product, fr_prodmfg, fr_soissue, fr_prodstatus, 
	fr_shoporddetl, fr_shopordhead, fv_remaining_tot) 

	DEFINE fv_remaining_tot LIKE prodstatus.onhand_qty, 
	fv_remaining_qty LIKE prodstatus.onhand_qty, 
	fv_issued_qty LIKE prodstatus.onhand_qty, 
	fv_soissued_qty LIKE prodstatus.onhand_qty, 

	fr_product RECORD LIKE product.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_shopordhead RECORD LIKE shopordhead.*, 

	fr_soissue RECORD 
		part_code LIKE product.part_code, 
		ware_code LIKE warehouse.ware_code, 
		work_centre_code LIKE shoporddetl.work_centre_code, 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		source_text LIKE prodledg.source_text, 
		tran_date LIKE prodledg.tran_date, 
		year_num LIKE prodledg.year_num, 
		period_num LIKE prodledg.period_num, 
		tran_desc LIKE prodledg.desc_text, 
		issued_qty LIKE shoporddetl.issued_qty 
	END RECORD 


	LET fv_remaining_qty = fr_shoporddetl.required_qty - 
	fr_shoporddetl.issued_qty 
	LET fv_soissued_qty = fv_remaining_qty 

	CASE 
		WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
			LET fv_remaining_qty = fv_remaining_qty * fr_prodmfg.man_stk_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
			LET fv_remaining_qty = fv_remaining_qty / fr_product.stk_sel_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
			LET fv_remaining_qty = fv_remaining_qty * fr_product.pur_stk_con_qty 
	END CASE 

	IF fv_remaining_qty <= fv_remaining_tot AND NOT pv_first THEN 
		LET fr_shoporddetl.issued_qty = fr_shoporddetl.required_qty 
		LET fv_issued_qty = fv_remaining_qty 
	ELSE 
		LET fv_issued_qty = fv_remaining_tot 
		LET fv_soissued_qty = fv_issued_qty 

		CASE 
			WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
				LET fv_soissued_qty = fv_soissued_qty / 
				fr_prodmfg.man_stk_con_qty 

			WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
				LET fv_soissued_qty = fv_soissued_qty * 
				fr_product.stk_sel_con_qty 

			WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
				LET fv_soissued_qty = fv_soissued_qty / 
				fr_product.pur_stk_con_qty 
		END CASE 

		LET fr_shoporddetl.issued_qty = fr_shoporddetl.issued_qty + 
		fv_soissued_qty 
	END IF 

	IF NOT pv_first THEN 
		LET fr_prodstatus.reserved_qty = fr_prodstatus.reserved_qty - 
		fv_issued_qty 
	END IF 

	LET fr_shoporddetl.act_est_cost_amt = fr_prodstatus.est_cost_amt 
	LET fr_shoporddetl.act_wgted_cost_amt = fr_prodstatus.wgted_cost_amt 
	LET fr_shoporddetl.act_act_cost_amt = fr_prodstatus.act_cost_amt 
	LET fr_shoporddetl.act_price_amt = fr_prodstatus.list_amt 

	CASE 
		WHEN fr_shoporddetl.uom_code = fr_prodmfg.man_uom_code 
			LET fr_shoporddetl.act_est_cost_amt = 
			fr_shoporddetl.act_est_cost_amt * fr_prodmfg.man_stk_con_qty 

			LET fr_shoporddetl.act_wgted_cost_amt = 
			fr_shoporddetl.act_wgted_cost_amt * fr_prodmfg.man_stk_con_qty 

			LET fr_shoporddetl.act_act_cost_amt = 
			fr_shoporddetl.act_act_cost_amt * fr_prodmfg.man_stk_con_qty 

			LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt * 
			fr_prodmfg.man_stk_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_product.sell_uom_code 
			LET fr_shoporddetl.act_est_cost_amt = 
			fr_shoporddetl.act_est_cost_amt / fr_product.stk_sel_con_qty 

			LET fr_shoporddetl.act_wgted_cost_amt = 
			fr_shoporddetl.act_wgted_cost_amt / fr_product.stk_sel_con_qty 

			LET fr_shoporddetl.act_act_cost_amt = 
			fr_shoporddetl.act_act_cost_amt / fr_product.stk_sel_con_qty 

			LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt / 
			fr_product.stk_sel_con_qty 

		WHEN fr_shoporddetl.uom_code = fr_product.pur_uom_code 
			LET fr_shoporddetl.act_est_cost_amt = 
			fr_shoporddetl.act_est_cost_amt * fr_product.pur_stk_con_qty 

			LET fr_shoporddetl.act_wgted_cost_amt = 
			fr_shoporddetl.act_wgted_cost_amt * fr_product.pur_stk_con_qty 

			LET fr_shoporddetl.act_act_cost_amt = 
			fr_shoporddetl.act_act_cost_amt * fr_product.pur_stk_con_qty 

			LET fr_shoporddetl.act_price_amt = fr_shoporddetl.act_price_amt * 
			fr_product.pur_stk_con_qty 
	END CASE 

	IF fr_shoporddetl.issued_qty >= fr_shoporddetl.required_qty THEN 
		LET fr_shoporddetl.issue_ware_code = fr_soissue.ware_code 
	END IF 

	IF fr_shoporddetl.actual_start_date IS NULL THEN 
		LET fr_shoporddetl.actual_start_date = fr_soissue.tran_date 
	END IF 

	LET fr_shoporddetl.last_change_date = today 
	LET fr_shoporddetl.last_user_text = glob_rec_kandoouser.sign_on_code 
	LET fr_shoporddetl.last_program_text = "M43" 
	LET fv_remaining_tot = fv_remaining_tot - fv_issued_qty 
	LET err_message = "M43 - Update of shoporddetl failed" 

	UPDATE shoporddetl 
	SET * = fr_shoporddetl.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = fr_soissue.shop_order_num 
	AND suffix_num = fr_soissue.suffix_num 
	AND part_code = fr_soissue.part_code 
	AND sequence_num = fr_shoporddetl.sequence_num 

	LET fr_shopordhead.act_est_cost_amt = fr_shopordhead.act_est_cost_amt + 
	(fr_shoporddetl.act_est_cost_amt * fv_soissued_qty) 

	LET fr_shopordhead.act_wgted_cost_amt = fr_shopordhead.act_wgted_cost_amt + 
	(fr_shoporddetl.act_wgted_cost_amt * fv_soissued_qty) 

	LET fr_shopordhead.act_act_cost_amt = fr_shopordhead.act_act_cost_amt + 
	(fr_shoporddetl.act_act_cost_amt * fv_soissued_qty) 

	LET fr_shopordhead.act_price_amt = fr_shopordhead.act_price_amt + 
	(fr_shoporddetl.act_price_amt * fv_soissued_qty) 

	RETURN fr_prodstatus.*, fr_shoporddetl.*, fr_shopordhead.*, fv_remaining_tot 

END FUNCTION 
