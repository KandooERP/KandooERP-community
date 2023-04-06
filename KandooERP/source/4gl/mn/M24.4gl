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

	Source code beautified by beautify.pl on 2020-01-02 17:31:21	$Id: $
}


# Purpose - Indented BOR inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	rpt_note CHAR(80), 
	formname CHAR(10), 
	fv_indent SMALLINT, 
	fv_indent2 SMALLINT, 
	fv_cnt SMALLINT, 
	fv_idx_now SMALLINT, 
	fv_total FLOAT, 
	fv_total2 FLOAT, 
	fr_prodmfg RECORD LIKE prodmfg.*, 

	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_cost_type LIKE bor.cost_type_ind, 
	fv_quantity LIKE bor.required_qty, 
	fv_time_unit CHAR(10), 

	fa_bor_child_extn array[2000] OF RECORD 
		desc_text LIKE bor.desc_text 
	END RECORD, 

	fa_bor_child array[2000] OF RECORD 
		type_ind LIKE bor.type_ind, 
		char_type CHAR(1), 
		dumb_char CHAR(1), 
		indent_factor CHAR(2), 
		part_code CHAR(32), 
		uom_code CHAR(4), 
		required_qty LIKE bor.required_qty, 
		cost_amt LIKE bor.cost_amt 
	END RECORD 
END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("M24") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL query_where() 
END MAIN 


FUNCTION query_where() 

	DEFINE 
	fv_cnter SMALLINT, 
	fv_idx SMALLINT, 
	fv_display_text CHAR(75), 
	fv_parent_part_code LIKE bor.parent_part_code 

	OPEN WINDOW w0_inquiry with FORM "M163" 
	CALL  windecoration_m("M163") -- albo kd-762 

	WHILE true 
		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "ESC TO Accept, DEL TO Exit"

		LET fv_parent_part_code = "" 
		LET fv_cost_type = "W" 
		LET fv_quantity = "" 
		LET fv_total = "" 
		LET fv_total2 = "" 

		DISPLAY fv_parent_part_code TO parent_part_code 
		DISPLAY fv_cost_type TO cost_type 
		DISPLAY fv_quantity TO quantity 
		DISPLAY fv_total TO totlcost 
		DISPLAY fv_total2 TO unitcost 
		DISPLAY "" TO noofcomp 
		DISPLAY "" TO uom 

		LET fv_total = 0 
		LET fv_total2 = 0 
		INPUT fv_parent_part_code, fv_cost_type, fv_quantity WITHOUT DEFAULTS 
		FROM parent_part_code, cost_type, quantity 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD parent_part_code 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				SELECT unique count(*) 
				INTO fv_cnter 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fv_parent_part_code 

				IF fv_cnter = 0 THEN 
					LET msgresp = kandoomsg("M",9518,"") 
					# ERROR "There are no BOR's with this parent component"
					NEXT FIELD parent_part_code 
				ELSE 
					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fv_parent_part_code 

					DISPLAY fr_prodmfg.man_uom_code TO uom 
				END IF 

			AFTER FIELD cost_type 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

			AFTER FIELD quantity 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				IF fv_quantity <= 0 THEN 
					LET msgresp = kandoomsg("M",9529,"") 
					# ERROR "Enter quantity greater than zero
					NEXT FIELD quantity 
				END IF 

			ON KEY (control-b) 
				CASE 
					WHEN infield(parent_part_code) 
						LET fv_parent_part_code = show_parents(glob_rec_kandoouser.cmpy_code) 

						SELECT unique count(*) 
						INTO fv_cnter 
						FROM bor 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND parent_part_code = fv_parent_part_code 

						IF fv_cnter = 0 THEN 
							LET msgresp = kandoomsg("M",9518,"") 
							# ERROR "No BOR's with this parent component"
							NEXT FIELD parent_part_code 
						ELSE 
							SELECT * 
							INTO fr_prodmfg.* 
							FROM prodmfg 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = fv_parent_part_code 

							DISPLAY fr_prodmfg.man_uom_code TO uom 
							DISPLAY fv_parent_part_code TO parent_part_code 
							NEXT FIELD cost_type 
						END IF 
				END CASE 
		END INPUT 

		IF (int_flag 
		OR quit_flag) THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLEAR FORM 
			EXIT WHILE 
		ELSE 
			IF fv_cost_type = "C" THEN 
				SELECT cost_ind 
				INTO fv_cost_type 
				FROM inparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF fv_cost_type = "F" THEN 
					LET fv_cost_type = "W" 
				END IF 
			END IF 

			LET fv_cnt = 0 
			LET fv_indent = -1 
			LET fv_indent2 = 0 
			{
			            OPEN WINDOW w1_IB1 AT 10,10      -- albo  KD-762
			                with 2 rows, 50 columns
			                ATTRIBUTE(border)
			}
			LET msgresp = kandoomsg("U",1506,"") 
			# MESSAGE "Searching database - Please stand by"
			LET msgresp = kandoomsg("I",1024,"") 
			# MESSAGE "Reporting on product"
			CALL view_kids(fv_parent_part_code) 
			LET msgresp = kandoomsg("U",1507,"") 
			# MESSAGE "database search IS complete"
			--            CLOSE WINDOW w1_IB1      -- albo  KD-762

			LET msgresp = kandoomsg("M",1509,"") 
			# MESSAGE "F3 Fwd, F4 Bwd, DEL TO Exit"

			LET fv_total2 = fv_total / fv_quantity 

			DISPLAY fv_total2 TO unitcost 
			DISPLAY fv_total TO totlcost 
			DISPLAY fv_cnt TO noofcomp 

			CALL set_count(fv_cnt) 
			INPUT ARRAY fa_bor_child WITHOUT DEFAULTS FROM sr_bor_child.* 
				ON ACTION "WEB-HELP" -- albo kd-376 
					CALL onlinehelp(getmoduleid(),null) 
				BEFORE ROW 
					LET fv_idx_now = arr_curr() 
					DISPLAY fa_bor_child_extn[fv_idx_now].* TO desc_text 
				AFTER FIELD dumb_char 
					IF fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("enter") 
					OR fgl_lastkey() = fgl_keyval("right") THEN 
						LET fv_idx_now = arr_curr() 
						IF fv_idx_now = fv_cnt THEN 
							LET msgresp = kandoomsg("M",9530,"") 
							# ERROR "No more rows in direction you are going"
							NEXT FIELD dumb_char 
						END IF 
					END IF 
			END INPUT 

			LET fa_bor_child_extn[1].desc_text = "" 
			DISPLAY fa_bor_child_extn[1].desc_text TO desc_text 

			LET fv_idx = 1 
			INITIALIZE fa_bor_child[fv_idx].* TO NULL 
			FOR fv_cnt = 1 TO 10 
				DISPLAY fa_bor_child[fv_idx].* TO sr_bor_child[fv_cnt].* 
			END FOR 

			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 
END FUNCTION 

FUNCTION view_kids(fv_parent_part_code) 

	DEFINE fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnter SMALLINT, 
	fv_cnterb SMALLINT, 
	fv_cntb SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_cost_ind CHAR(1), 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_cost_tot LIKE bor.cost_amt, 
	fv_wc_tot LIKE bor.cost_amt, 
	fv_min_ord_qty LIKE product.min_ord_qty, 
	fv_pur_stk_con_qty LIKE product.pur_stk_con_qty, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fv_man_stk_con_qty LIKE prodmfg.man_stk_con_qty, 
	fv_cost_amt LIKE bor.cost_amt, 

	fa_temp_part CHAR(40), 
	fa_hold array[81] OF RECORD LIKE bor.*, 

	fr_bor RECORD LIKE bor.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.* 

	IF fv_indent < 14 THEN 
		LET fv_indent = fv_indent + 1 
	END IF 
	LET fv_indent2 = fv_indent2 + 1 

	LET fa_temp_part = " " 

	SELECT min_ord_qty, pur_stk_con_qty 
	INTO fv_min_ord_qty, fv_pur_stk_con_qty 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_parent_part_code 

	SELECT man_stk_con_qty, man_uom_code 
	INTO fv_man_stk_con_qty, fv_man_uom_code 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_parent_part_code 

	IF fv_min_ord_qty IS NULL 
	OR fv_min_ord_qty = 0 THEN 
		LET fv_min_ord_qty = 1 
	ELSE 
		LET fv_min_ord_qty = fv_min_ord_qty / fv_pur_stk_con_qty * 
		fv_man_stk_con_qty 
	END IF 

	LET fv_cost_tot = 0 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	ORDER BY sequence_num 

	FOREACH c_child INTO fr_bor.* 
		LET fv_cnterb = fv_cnterb + 1 
		LET fa_hold[fv_cnterb].* = fr_bor.* 
	END FOREACH 

	LET fv_cntb = 0 
	WHILE fv_cntb < fv_cnterb 
		LET fv_cnt = fv_cnt + 1 
		LET fv_cntb = fv_cntb + 1 
		LET fr_bor.* = fa_hold[fv_cntb].* 
		LET fa_bor_child_extn[fv_cnt].desc_text = fr_bor.desc_text 

		DISPLAY fr_bor.part_code at 1,27 


		CASE fr_bor.type_ind 
			WHEN "I" 
				LET fr_bor.part_code = "INSTRUCTION" 
				LET fv_cost_amt = 0 

			WHEN "S" 
				LET fr_bor.part_code = "COST" 
				IF fr_bor.cost_type_ind = "F" THEN 
					LET fv_cost_amt = fr_bor.cost_amt 
				ELSE 
					LET fv_cost_amt = fr_bor.cost_amt * fv_quantity 
				END IF 

			WHEN "W" 
				LET fr_bor.part_code = fr_bor.work_centre_code 

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

				IF fr_workcentre.processing_ind = "Q" THEN 
					IF fv_min_ord_qty < fv_quantity THEN 
						LET fv_wc_tot = (((fr_bor.oper_factor_amt * fv_quantity) 
						/ fr_workcentre.time_qty) 
						* fr_bor.cost_amt) 
						+ fr_bor.price_amt 
					ELSE 
						LET fv_wc_tot = (((fr_bor.oper_factor_amt * fv_min_ord_qty) 
						/ fr_workcentre.time_qty) 
						* fr_bor.cost_amt) 
						+ fr_bor.price_amt 
					END IF 
					LET fv_cost_tot = fv_cost_tot + fv_wc_tot 
				ELSE 
					IF fv_min_ord_qty < fv_quantity THEN 
						LET fv_wc_tot = (((fr_bor.oper_factor_amt * fv_quantity) 
						* fr_workcentre.time_qty) 
						* fr_bor.cost_amt) 
						+ fr_bor.price_amt 
					ELSE 
						LET fv_wc_tot = (((fr_bor.oper_factor_amt * fv_min_ord_qty) 
						* fr_workcentre.time_qty) 
						* fr_bor.cost_amt) 
						+ fr_bor.price_amt 
					END IF 
					LET fv_cost_tot = fv_cost_tot + fv_wc_tot 
				END IF 

				CASE fr_workcentre.time_unit_ind 
					WHEN "D" 
						LET fv_time_unit = "day" 
					WHEN "H" 
						LET fv_time_unit = "hour" 
					WHEN "M" 
						LET fv_time_unit = "minute" 
				END CASE 

				IF fr_workcentre.processing_ind = "Q" THEN 
					LET fr_bor.desc_text = 
					fr_bor.work_centre_code clipped," ", 
					fr_workcentre.time_qty clipped," ", 
					fr_workcentre.unit_uom_code clipped, " per ", 
					fv_time_unit clipped," Op.Factor: ", 
					fr_bor.oper_factor_amt 
				ELSE 
					LET fr_bor.desc_text = 
					fr_bor.work_centre_code clipped," ", 
					fr_workcentre.time_qty clipped," ", 
					fv_time_unit clipped, "s per ", 
					fr_workcentre.unit_uom_code clipped, 
					" Op.Factor: ", 
					fr_bor.oper_factor_amt 
				END IF 

				IF fr_bor.desc_text IS NULL THEN 
					LET fr_bor.desc_text = fr_workcentre.desc_text 
				END IF 
				LET fa_bor_child_extn[fv_cnt].desc_text = fr_bor.desc_text 

			WHEN "U" 
				LET fr_bor.part_code = "SET UP" 

				#IF fr_bor.cost_type_ind = "Q" THEN
				#    LET fv_setup_qty = fv_quantity / fr_bor.var_amt
				#    IF fv_setup_qty < 1 THEN
				#        LET fv_setup_qty = 1
				#    END IF

				#    LET fv_cost_amt = fr_bor.cost_amt * fv_setup_qty
				#ELSE
				#    LET fv_cost_amt = fr_bor.cost_amt
				#END IF

				LET fv_cost_amt = fr_bor.cost_amt 

			OTHERWISE 
				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				SELECT * 
				INTO fr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				LET fa_bor_child_extn[fv_cnt].desc_text = fr_product.desc_text 

				IF fr_prodmfg.part_type_ind = "R" THEN 
					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_bor.part_code 
					AND ware_code = fr_prodmfg.def_ware_code 

					CASE 
						WHEN fv_cost_type = "W" 
							LET fv_cost_amt = fr_prodstatus.wgted_cost_amt * 
							fr_product.stk_sel_con_qty * 
							fr_prodmfg.man_stk_con_qty 
						WHEN fv_cost_type = "S" 
							LET fv_cost_amt = fr_prodstatus.est_cost_amt * 
							fr_product.stk_sel_con_qty * 
							fr_prodmfg.man_stk_con_qty 
						WHEN fv_cost_type = "L" 
							LET fv_cost_amt = fr_prodstatus.act_cost_amt * 
							fr_product.stk_sel_con_qty * 
							fr_prodmfg.man_stk_con_qty 
					END CASE 

					LET fr_bor.price_amt = fr_prodstatus.list_amt * 
					fr_product.stk_sel_con_qty * 
					fr_prodmfg.man_stk_con_qty 
				ELSE 
					IF fr_prodmfg.wgted_cost_amt IS NULL THEN 
						LET fr_prodmfg.wgted_cost_amt = 0 
					END IF 

					IF fr_prodmfg.est_cost_amt IS NULL THEN 
						LET fr_prodmfg.est_cost_amt = 0 
					END IF 

					IF fr_prodmfg.act_cost_amt IS NULL THEN 
						LET fr_prodmfg.act_cost_amt = 0 
					END IF 

					IF fr_prodmfg.list_price_amt IS NULL THEN 
						LET fr_prodmfg.list_price_amt = 0 
					END IF 

					CASE 
						WHEN fv_cost_type = "W" 
							LET fv_cost_amt = fr_prodmfg.wgted_cost_amt 
						WHEN fv_cost_type = "S" 
							LET fv_cost_amt = fr_prodmfg.est_cost_amt 
						WHEN fv_cost_type = "L" 
							LET fv_cost_amt = fr_prodmfg.act_cost_amt 
					END CASE 

					LET fr_bor.price_amt = fr_prodmfg.list_price_amt 
				END IF 

				CASE 
					WHEN fr_bor.uom_code = fr_product.pur_uom_code 
						LET fv_cost_amt = fv_cost_amt / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 

						LET fr_bor.price_amt = fr_bor.price_amt / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 

					WHEN fr_bor.uom_code = fr_product.stock_uom_code 
						LET fv_cost_amt = fv_cost_amt / 
						fr_prodmfg.man_stk_con_qty 
						LET fr_bor.price_amt = fr_bor.price_amt / 
						fr_prodmfg.man_stk_con_qty 

					WHEN fr_bor.uom_code = fr_product.sell_uom_code 
						LET fv_cost_amt = fv_cost_amt / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
						LET fr_bor.price_amt = fr_bor.price_amt / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
				END CASE 

				LET fr_bor.cost_amt = fv_cost_amt 

				LET fv_cost_tot = fv_cost_tot + (fv_cost_amt * 
				fr_bor.required_qty * fv_quantity) 

				IF fr_bor.type_ind = "B" THEN 
					LET fr_bor.required_qty = - (fr_bor.required_qty) 
				END IF 
		END CASE 

		LET fa_bor_child[fv_cnt].type_ind = fr_bor.type_ind 

		IF fv_indent > 0 THEN 
			LET fa_bor_child[fv_cnt].part_code = 
			fa_temp_part[1,fv_indent],fr_bor.part_code 
		ELSE 
			LET fa_bor_child[fv_cnt].part_code = fr_bor.part_code 
		END IF 

		IF fr_bor.type_ind matches "[CB]" THEN 
			SELECT * 
			INTO fr_prodmfg.* 
			FROM prodmfg 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_bor.part_code 

			LET fa_bor_child[fv_cnt].char_type = fr_prodmfg.part_type_ind 
			LET fa_bor_child[fv_cnt].uom_code = fr_prodmfg.man_uom_code 
		ELSE 
			LET fa_bor_child[fv_cnt].uom_code = "" 
			LET fa_bor_child[fv_cnt].char_type = "" 
		END IF 

		IF fv_indent2 = 1 THEN 
			LET fa_bor_child[fv_cnt].required_qty 
			= fr_bor.required_qty * fv_quantity 
			LET fa_bor_child[fv_cnt].cost_amt 
			= fv_cost_amt * fa_bor_child[fv_cnt].required_qty 
		ELSE 
			LET fa_bor_child[fv_cnt].required_qty 
			= fr_bor.required_qty 
			LET fa_bor_child[fv_cnt].cost_amt 
			= fv_cost_amt * fr_bor.required_qty 
		END IF 

		IF fr_bor.type_ind = "W" THEN 
			LET fa_bor_child[fv_cnt].cost_amt = fv_wc_tot 
		END IF 

		IF fa_bor_child[fv_cnt].type_ind matches "[US]" THEN 
			LET fa_bor_child[fv_cnt].cost_amt = fv_cost_amt 
		END IF 

		LET fa_bor_child[fv_cnt].indent_factor = fv_indent2 

		IF fa_bor_child[fv_cnt].type_ind matches "[BI]" THEN 
			LET fa_bor_child[fv_cnt].required_qty = NULL 
			LET fa_bor_child[fv_cnt].cost_amt = 0 
		END IF 

		IF fv_indent2 = 1 THEN 
			LET fv_total = fv_total + fa_bor_child[fv_cnt].cost_amt 
		END IF 

		IF fv_cnt = 2000 THEN 
			ERROR "Only the first 2000 children were selected" 
			--- modif ericv init # attributes (red, reverse)
			EXIT WHILE 
		END IF 

		SELECT unique count(*) 
		INTO fv_cnter 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fr_bor.part_code 

		IF fv_cnter > 0 THEN 
			CALL view_kids(fr_bor.part_code) 
		END IF 
	END WHILE 

	LET fv_indent = fv_indent - 1 
	LET fv_indent2 = fv_indent2 - 1 
END FUNCTION 
