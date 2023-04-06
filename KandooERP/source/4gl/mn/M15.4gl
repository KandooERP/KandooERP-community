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


# Purpose - BOR Inquiry

###########################################################################
# Requires
# common/note_disp.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE formname CHAR(15), 
	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M15") -- albo 
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

	IF pr_mnparms.ref1_text IS NOT NULL THEN 
		LET pr_mnparms.ref1_text = pr_mnparms.ref1_text clipped, 
		"..................." 
	END IF 

	IF pr_mnparms.ref2_text IS NOT NULL THEN 
		LET pr_mnparms.ref2_text = pr_mnparms.ref2_text clipped, 
		"..................." 
	END IF 

	IF pr_mnparms.ref3_text IS NOT NULL THEN 
		LET pr_mnparms.ref3_text = pr_mnparms.ref3_text clipped, 
		"..................." 
	END IF 

	IF num_args() > 0 THEN 
		CALL view_kids(arg_val(1), arg_val(2)) 
	ELSE 
		CALL parent_query() 
	END IF 

END MAIN 



FUNCTION parent_query() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500), 
	fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_parent_code LIKE bor.parent_part_code, 

	fa_bor_parent array[2000] OF RECORD 
		parent_part_code LIKE bor.parent_part_code, 
		desc_text LIKE product.desc_text 
	END RECORD 

	OPEN WINDOW w1_m122 with FORM "M122" 
	CALL  windecoration_m("M122") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		LET msgresp = kandoomsg("M", 1500, "") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_text ON parent_part_code 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW w1_m122 
			RETURN 
		END IF 

		LET msgresp = kandoomsg("M", 1532, "") 
		# MESSAGE "Searching database - please wait"

		LET fv_query_text = "SELECT unique parent_part_code ", 
		"FROM bor ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", fv_where_text clipped, " ", 
		"ORDER BY parent_part_code" 

		PREPARE sl_stmt1 FROM fv_query_text 
		DECLARE c_bor CURSOR FOR sl_stmt1 

		LET fv_cnt = 0 

		FOREACH c_bor INTO fv_parent_code 
			LET fv_cnt = fv_cnt + 1 
			LET fa_bor_parent[fv_cnt].parent_part_code = fv_parent_code 

			SELECT desc_text 
			INTO fa_bor_parent[fv_cnt].desc_text 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fa_bor_parent[fv_cnt].parent_part_code 

			IF fv_cnt = 2000 THEN 
				LET msgresp = kandoomsg("M", 9502, "") 
				# ERROR "Only the first 2000 products have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF fv_cnt = 0 THEN 
			LET msgresp = kandoomsg("M", 9610, "") 
			# ERROR "The query returned no rows"
			CONTINUE WHILE 
		END IF 

		LET msgresp = kandoomsg("M", 1513, "") 
		# MESSAGE "RETURN on line TO view children,F3 Fwd, F4 Bwd - DEL TO Exit"

		CALL set_count(fv_cnt) 

		DISPLAY ARRAY fa_bor_parent TO sr_bor_parent.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","M15","display-arr-bor_parent") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (RETURN) 
				LET fv_idx = arr_curr() 

				CALL view_kids(fa_bor_parent[fv_idx].parent_part_code, 
				fa_bor_parent[fv_idx].desc_text) 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

	END WHILE 

END FUNCTION 



FUNCTION view_kids(fv_parent_part_code, fv_desc_text) 

	DEFINE fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnt SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_cost_ind CHAR(1), 
	fv_runner CHAR(105), 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_desc_text LIKE product.desc_text, 
	fv_cost1_tot LIKE bor.cost_amt, 
	fv_cost2_tot LIKE bor.cost_amt, 
	fv_cost3_tot LIKE bor.cost_amt, 
	fv_wc_tot LIKE bor.cost_amt, 
	fv_min_ord_qty LIKE product.min_ord_qty, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 

	fr_bor RECORD LIKE bor.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 

	fa_bor_child array[2000] OF RECORD 
		type_ind LIKE bor.type_ind, 
		part_code LIKE bor.part_code, 
		desc_text LIKE product.desc_text, 
		required_qty LIKE bor.required_qty, 
		cost_amt LIKE bor.cost_amt 
	END RECORD, 

	fa_bor array[2000] OF RECORD LIKE bor.*, 
	fa_cost1_amt array[2000] OF LIKE bor.cost_amt, 
	fa_cost2_amt array[2000] OF LIKE bor.cost_amt, 
	fa_cost3_amt array[2000] OF LIKE bor.cost_amt 


	SELECT min_ord_qty 
	INTO fv_min_ord_qty 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_parent_part_code 

	SELECT man_uom_code 
	INTO fv_man_uom_code 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fv_parent_part_code 

	IF fv_min_ord_qty IS NULL 
	OR fv_min_ord_qty = 0 THEN 
		LET fv_min_ord_qty = 1 
	END IF 

	LET fv_cost1_tot = 0 
	LET fv_cost2_tot = 0 
	LET fv_cost3_tot = 0 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	ORDER BY sequence_num 

	LET fv_cnt = 0 

	FOREACH c_child INTO fr_bor.* 
		IF fr_bor.start_date > today 
		OR fr_bor.end_date < today THEN 
			CONTINUE FOREACH 
		END IF 

		LET fv_cnt = fv_cnt + 1 

		CASE fr_bor.type_ind 
			WHEN "I" 
				LET fr_bor.part_code = kandooword("INSTRUCTION", "M14") 

			WHEN "S" 
				LET fr_bor.part_code = kandooword("COST", "M15") 

				IF fr_bor.cost_type_ind = "F" THEN 
					LET fv_cost1_tot = fv_cost1_tot + fr_bor.cost_amt 
					LET fv_cost2_tot = fv_cost2_tot + fr_bor.cost_amt 
					LET fv_cost3_tot = fv_cost3_tot + fr_bor.cost_amt 
				ELSE 
					LET fv_cost1_tot = fv_cost1_tot + (fr_bor.cost_amt * 
					fv_min_ord_qty) 
					LET fv_cost2_tot = fv_cost2_tot + (fr_bor.cost_amt * 
					fv_min_ord_qty) 
					LET fv_cost3_tot = fv_cost3_tot + (fr_bor.cost_amt * 
					fv_min_ord_qty) 
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
					LET fv_wc_tot = ((fr_bor.cost_amt / fr_workcentre.time_qty) 
					* fr_bor.oper_factor_amt * fv_min_ord_qty) + 
					fr_bor.price_amt 
				ELSE 
					LET fv_wc_tot = (fr_bor.cost_amt * fr_bor.oper_factor_amt * 
					fv_min_ord_qty) + fr_bor.price_amt 
				END IF 

				LET fv_cost1_tot = fv_cost1_tot + fv_wc_tot 
				LET fv_cost2_tot = fv_cost2_tot + fv_wc_tot 
				LET fv_cost3_tot = fv_cost3_tot + fv_wc_tot 

			WHEN "U" 
				LET fr_bor.part_code = kandooword("SET UP", "M17") 

				IF fr_bor.cost_type_ind = "Q" THEN 
					LET fv_setup_qty = fv_min_ord_qty / fr_bor.var_amt 

					IF fv_setup_qty < 1 THEN 
						LET fv_setup_qty = 1 
					END IF 
				ELSE 
					LET fv_setup_qty = 1 
				END IF 

				LET fv_cost1_tot = fv_cost1_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 
				LET fv_cost2_tot = fv_cost2_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 
				LET fv_cost3_tot = fv_cost3_tot + (fr_bor.cost_amt * 
				fv_setup_qty) 

			WHEN "B" 
				SELECT desc_text 
				INTO fr_bor.desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				LET fa_cost1_amt[fv_cnt] = 0 
				LET fa_cost2_amt[fv_cnt] = 0 
				LET fa_cost3_amt[fv_cnt] = 0 
				LET fr_bor.cost_amt = 0 
				LET fr_bor.price_amt = 0 
				LET fr_bor.required_qty = - (fr_bor.required_qty) 

			WHEN "C" 
				SELECT desc_text 
				INTO fr_bor.desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

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

				IF fr_prodmfg.part_type_ind = "R" THEN 
					SELECT * 
					INTO fr_prodstatus.* 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fr_bor.part_code 
					AND ware_code = fr_prodmfg.def_ware_code 

					LET fa_cost1_amt[fv_cnt] = fr_prodstatus.wgted_cost_amt * 
					fr_prodmfg.man_stk_con_qty 
					LET fa_cost2_amt[fv_cnt] = fr_prodstatus.est_cost_amt * 
					fr_prodmfg.man_stk_con_qty 
					LET fa_cost3_amt[fv_cnt] = fr_prodstatus.act_cost_amt * 
					fr_prodmfg.man_stk_con_qty 
					LET fr_bor.price_amt = fr_prodstatus.list_amt * 
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

					LET fa_cost1_amt[fv_cnt] = fr_prodmfg.wgted_cost_amt 
					LET fa_cost2_amt[fv_cnt] = fr_prodmfg.est_cost_amt 
					LET fa_cost3_amt[fv_cnt] = fr_prodmfg.act_cost_amt 
					LET fr_bor.price_amt = fr_prodmfg.list_price_amt 
				END IF 

				CASE 
					WHEN fr_bor.uom_code = fr_product.pur_uom_code 
						LET fa_cost1_amt[fv_cnt] = fa_cost1_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 
						LET fa_cost2_amt[fv_cnt] = fa_cost2_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 
						LET fa_cost3_amt[fv_cnt] = fa_cost3_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 
						LET fr_bor.price_amt = fr_bor.price_amt / 
						(fr_prodmfg.man_stk_con_qty / 
						fr_product.pur_stk_con_qty) 

					WHEN fr_bor.uom_code = fr_product.stock_uom_code 
						LET fa_cost1_amt[fv_cnt] = fa_cost1_amt[fv_cnt] / 
						fr_prodmfg.man_stk_con_qty 
						LET fa_cost2_amt[fv_cnt] = fa_cost2_amt[fv_cnt] / 
						fr_prodmfg.man_stk_con_qty 
						LET fa_cost3_amt[fv_cnt] = fa_cost3_amt[fv_cnt] / 
						fr_prodmfg.man_stk_con_qty 
						LET fr_bor.price_amt = fr_bor.price_amt / 
						fr_prodmfg.man_stk_con_qty 

					WHEN fr_bor.uom_code = fr_product.sell_uom_code 
						LET fa_cost1_amt[fv_cnt] = fa_cost1_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
						LET fa_cost2_amt[fv_cnt] = fa_cost2_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
						LET fa_cost3_amt[fv_cnt] = fa_cost3_amt[fv_cnt] / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
						LET fr_bor.price_amt = fr_bor.price_amt / 
						(fr_prodmfg.man_stk_con_qty * 
						fr_product.stk_sel_con_qty) 
				END CASE 

				CASE 
					WHEN pr_inparms.cost_ind matches "[WF]" 
						LET fr_bor.cost_amt = fa_cost1_amt[fv_cnt] 

					WHEN pr_inparms.cost_ind = "S" 
						LET fr_bor.cost_amt = fa_cost2_amt[fv_cnt] 

					WHEN pr_inparms.cost_ind = "L" 
						LET fr_bor.cost_amt = fa_cost3_amt[fv_cnt] 
				END CASE 

				LET fv_cost1_tot = fv_cost1_tot + (fa_cost1_amt[fv_cnt] * 
				fr_bor.required_qty * fv_min_ord_qty) 
				LET fv_cost2_tot = fv_cost2_tot + (fa_cost2_amt[fv_cnt] * 
				fr_bor.required_qty * fv_min_ord_qty) 
				LET fv_cost3_tot = fv_cost3_tot + (fa_cost3_amt[fv_cnt] * 
				fr_bor.required_qty * fv_min_ord_qty) 
		END CASE 

		LET fa_bor[fv_cnt].* = fr_bor.* 
		LET fa_bor_child[fv_cnt].type_ind = fr_bor.type_ind 
		LET fa_bor_child[fv_cnt].part_code = fr_bor.part_code 
		LET fa_bor_child[fv_cnt].desc_text = fr_bor.desc_text 
		LET fa_bor_child[fv_cnt].required_qty = fr_bor.required_qty 
		LET fa_bor_child[fv_cnt].cost_amt = fr_bor.cost_amt 

		IF fr_bor.type_ind = "W" THEN 
			LET fa_bor_child[fv_cnt].cost_amt = fv_wc_tot / fv_min_ord_qty 
		END IF 

		IF fa_bor_child[fv_cnt].type_ind = "U" THEN 
			LET fa_bor_child[fv_cnt].required_qty = NULL 
		END IF 

		IF fv_cnt = 2000 THEN 
			LET msgresp = kandoomsg("M", 9502, "") 
			# ERROR "Only the first 2000 products have been selected"
			EXIT FOREACH 
		END IF 

	END FOREACH 

	IF fv_cnt = 0 THEN 
		LET msgresp = kandoomsg("M", 9508, "") 
		# ERROR "This product has no children"
		RETURN 
	END IF 

	LET fv_cost1_tot = fv_cost1_tot / fv_min_ord_qty 
	LET fv_cost2_tot = fv_cost2_tot / fv_min_ord_qty 
	LET fv_cost3_tot = fv_cost3_tot / fv_min_ord_qty 

	OPEN WINDOW w2_m123 with FORM "M123" 
	CALL  windecoration_m("M123") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1514, "") 
	# MESSAGE"RETURN TO view line,F3 Fwd,F4 Bwd,F6 View BOR,F7 Change cost type"

	DISPLAY fv_parent_part_code, 
	fv_desc_text, 
	fv_min_ord_qty, 
	fv_man_uom_code 
	TO parent_part_code, 
	desc_text, 
	min_ord_qty, 
	man_uom_code 

	CASE pr_inparms.cost_ind 
		WHEN "W" 
			DISPLAY "Weighted Average", "COGS", fv_cost1_tot 
			TO cost_type, cogs_text, ext_cost_amt 
			LET fv_cost_ind = "W" 

		WHEN "F" 
			DISPLAY "FIFO", "COGS", fv_cost1_tot 
			TO cost_type, cogs_text, ext_cost_amt 
			LET fv_cost_ind = "F" 

		WHEN "S" 
			DISPLAY "Standard", "COGS", fv_cost2_tot 
			TO cost_type, cogs_text, ext_cost_amt 
			LET fv_cost_ind = "S" 

		WHEN "L" 
			DISPLAY "Latest", "COGS", fv_cost3_tot 
			TO cost_type, cogs_text, ext_cost_amt 
			LET fv_cost_ind = "L" 
	END CASE 

	CALL set_count(fv_cnt) 

	DISPLAY ARRAY fa_bor_child TO sr_bor_child.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M15","display-arr-bor_child") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (RETURN) 
			LET fv_idx = arr_curr() 

			CASE fa_bor_child[fv_idx].type_ind 
				WHEN "I" 
					CALL display_instruc(fa_bor[fv_idx].*) 

				WHEN "S" 
					CALL display_cost(fa_bor[fv_idx].*) 

				WHEN "W" 
					CALL display_workcentre(fa_bor[fv_idx].*) 

				WHEN "U" 
					CALL display_setup(fa_bor[fv_idx].*) 

				OTHERWISE 
					LET fa_bor[fv_idx].cost_amt = fa_bor_child[fv_idx].cost_amt 
					CALL display_component(fa_bor[fv_idx].*) 
			END CASE 

		ON KEY (f6) 
			LET fv_idx = arr_curr() 

			IF fa_bor_child[fv_idx].type_ind matches "[CB]" THEN 
				SELECT unique parent_part_code 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = fa_bor_child[fv_idx].part_code 

				IF status = notfound THEN 
					LET msgresp = kandoomsg("M", 9508, "") 
					# ERROR "This product has no children"
				ELSE 
					CALL run_prog("M15", fa_bor_child[fv_idx].part_code, 
					fa_bor_child[fv_idx].desc_text, "", "") 
				END IF 
			END IF 

		ON KEY (f7) 
			LET fv_idx = arr_curr() 
			LET fv_scrn = scr_line() 

			CASE fv_cost_ind 
				WHEN "W" 
					FOR fv_cnt1 = 1 TO fv_cnt 
						IF fa_bor_child[fv_cnt1].type_ind NOT matches "[CB]" 
						THEN 
							CONTINUE FOR 
						END IF 

						LET fa_bor_child[fv_cnt1].cost_amt = 
						fa_cost2_amt[fv_cnt1] 
						LET fa_bor[fv_cnt1].cost_amt = fa_cost2_amt[fv_cnt1] 
					END FOR 

					LET fv_cost_ind = "S" 

					DISPLAY "Standard", 
					"", 
					fv_cost2_tot 
					TO cost_type, 
					cogs_text, 
					ext_cost_amt 

				WHEN "S" 
					FOR fv_cnt1 = 1 TO fv_cnt 
						IF fa_bor_child[fv_cnt1].type_ind NOT matches "[CB]" 
						THEN 
							CONTINUE FOR 
						END IF 

						LET fa_bor_child[fv_cnt1].cost_amt = 
						fa_cost3_amt[fv_cnt1] 
						LET fa_bor[fv_cnt1].cost_amt = fa_cost3_amt[fv_cnt1] 
					END FOR 

					LET fv_cost_ind = "L" 

					DISPLAY "Latest", 
					"", 
					fv_cost3_tot 
					TO cost_type, 
					cogs_text, 
					ext_cost_amt 

				WHEN "L" 
					FOR fv_cnt1 = 1 TO fv_cnt 
						IF fa_bor_child[fv_cnt1].type_ind NOT matches "[CB]" 
						THEN 
							CONTINUE FOR 
						END IF 

						LET fa_bor_child[fv_cnt1].cost_amt = 
						fa_cost1_amt[fv_cnt1] 
						LET fa_bor[fv_cnt1].cost_amt = fa_cost1_amt[fv_cnt1] 
					END FOR 

					LET fv_cost_ind = "F" 

					DISPLAY "FIFO", "", fv_cost1_tot 
					TO cost_type, cogs_text, ext_cost_amt 

				WHEN "F" 
					LET fv_cost_ind = "W" 

					DISPLAY "Weighted Average", "" 
					TO cost_type, cogs_text 
			END CASE 

			IF fv_cost_ind = pr_inparms.cost_ind THEN 
				DISPLAY "COGS" TO cogs_text 
			END IF 

			FOR fv_cnt1 = 1 TO 11 
				DISPLAY 
				fa_bor_child[fv_idx - (fv_scrn - 1) - 1 + fv_cnt1].cost_amt 
				TO sr_bor_child[fv_cnt1].cost_amt 
			END FOR 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW w2_m123 

END FUNCTION 



FUNCTION display_component(fr_bor) 

	DEFINE fr_bor RECORD LIKE bor.*, 
	fv_wc_desc_text LIKE workcentre.desc_text, 
	fv_ext_cost_amt LIKE bor.cost_amt, 
	fv_ext_price_amt LIKE bor.price_amt 


	IF fr_bor.type_ind = "C" THEN 
		OPEN WINDOW w3_m107 with FORM "M107" 
		CALL  windecoration_m("M107") -- albo kd-762 
	ELSE 
		OPEN WINDOW w3_m153 with FORM "M153" 
		CALL  windecoration_m("M153") -- albo kd-762 
	END IF 

	DISPLAY BY NAME fr_bor.part_code, 
	fr_bor.desc_text, 
	fr_bor.required_qty, 
	fr_bor.uom_code, 
	fr_bor.cost_amt, 
	fr_bor.price_amt, 
	fr_bor.work_centre_code, 
	fr_bor.start_date, 
	fr_bor.end_date 

	SELECT desc_text 
	INTO fv_wc_desc_text 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_bor.work_centre_code 

	DISPLAY fv_wc_desc_text TO wc_desc_text 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_bor.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_bor.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_bor.user3_text 
	END IF 

	LET fv_ext_cost_amt = fr_bor.cost_amt * fr_bor.required_qty 
	LET fv_ext_price_amt = fr_bor.price_amt * fr_bor.required_qty 

	DISPLAY fv_ext_cost_amt, 
	fv_ext_price_amt 
	TO ext_cost_amt, 
	ext_price_amt 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	IF fr_bor.type_ind = "C" THEN 
		CLOSE WINDOW w3_m107 
	ELSE 
		CLOSE WINDOW w3_m153 
	END IF 

END FUNCTION 



FUNCTION display_instruc(fr_bor) 

	DEFINE fr_bor RECORD LIKE bor.* 


	OPEN WINDOW w3_m108 with FORM "M108" 
	CALL  windecoration_m("M108") -- albo kd-762 

	DISPLAY BY NAME fr_bor.desc_text, 
	fr_bor.start_date, 
	fr_bor.end_date 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_bor.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_bor.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_bor.user3_text 
	END IF 

	IF fr_bor.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_bor.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w3_m108 

END FUNCTION 



FUNCTION display_cost(fr_bor) 

	DEFINE fr_bor RECORD LIKE bor.* 

	OPEN WINDOW w3_m109 with FORM "M109" 
	CALL  windecoration_m("M109") -- albo kd-762 

	DISPLAY BY NAME fr_bor.desc_text, 
	fr_bor.cost_amt, 
	fr_bor.price_amt, 
	fr_bor.cost_type_ind, 
	fr_bor.start_date, 
	fr_bor.end_date 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_bor.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_bor.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_bor.user3_text 
	END IF 

	IF fr_bor.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_bor.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w3_m109 

END FUNCTION 



FUNCTION display_workcentre(fr_bor) 

	DEFINE fr_bor RECORD LIKE bor.*, 
	fv_variable_price LIKE bor.price_amt, 
	fv_fixed_price LIKE bor.price_amt, 
	fv_time_unit CHAR(7), 
	fv_capacity_text CHAR(16), 
	fr_workcentre RECORD LIKE workcentre.* 

	OPEN WINDOW w3_m110 with FORM "M110" 
	CALL  windecoration_m("M110") -- albo kd-762 

	DISPLAY BY NAME fr_bor.work_centre_code, 
	fr_bor.desc_text, 
	fr_bor.oper_factor_amt, 
	fr_bor.overlap_per, 
	fr_bor.start_date, 
	fr_bor.end_date 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_bor.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_bor.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_bor.user3_text 
	END IF 

	SELECT * 
	INTO fr_workcentre.* 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_bor.work_centre_code 

	LET fv_variable_price = fr_bor.cost_amt * (1 + 
	(fr_workcentre.cost_markup_per / 100)) 
	LET fv_fixed_price = fr_bor.price_amt * (1 + 
	(fr_workcentre.cost_markup_per / 100)) 

	CASE fr_workcentre.time_unit_ind 
		WHEN "D" 
			LET fv_time_unit = "day" 
		WHEN "H" 
			LET fv_time_unit = "hour" 
		WHEN "M" 
			LET fv_time_unit = "minute" 
	END CASE 

	IF fr_workcentre.processing_ind = "Q" THEN 
		LET fv_capacity_text = fr_workcentre.unit_uom_code clipped, " per ", 
		fv_time_unit 
	ELSE 
		LET fv_capacity_text = fv_time_unit clipped, "s per ", 
		fr_workcentre.unit_uom_code 
	END IF 

	DISPLAY BY NAME fr_workcentre.time_qty 
	DISPLAY fv_capacity_text, 
	fr_bor.cost_amt, 
	fv_variable_price, 
	fr_bor.price_amt, 
	fv_fixed_price 
	TO capacity_text, 
	variable_cost, 
	variable_price, 
	fixed_cost, 
	fixed_price 

	IF fr_bor.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_bor.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w3_m110 

END FUNCTION 



FUNCTION display_setup(fr_bor) 

	DEFINE fr_bor RECORD LIKE bor.* 

	OPEN WINDOW w3_m111 with FORM "M111" 
	CALL  windecoration_m("M111") -- albo kd-762 

	DISPLAY BY NAME fr_bor.desc_text, 
	fr_bor.required_qty, 
	fr_bor.uom_code, 
	fr_bor.cost_amt, 
	fr_bor.price_amt, 
	fr_bor.cost_type_ind, 
	fr_bor.start_date, 
	fr_bor.end_date 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_bor.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_bor.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_bor.user3_text 
	END IF 

	IF fr_bor.cost_type_ind != "F" THEN 
		DISPLAY BY NAME fr_bor.var_amt 
	END IF 

	IF fr_bor.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_bor.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w3_m111 

END FUNCTION 
