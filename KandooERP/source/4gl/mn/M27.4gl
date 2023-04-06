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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../mn/M_MN_GLOBALS.4gl"
GLOBALS "../mn/M2_GROUP_GLOBALS.4gl" 
GLOBALS "../mn/M27_GLOBALS.4gl"

GLOBALS 

	DEFINE 
	rpt_note CHAR(80), 
	formname CHAR(15), 
	pr_output CHAR(60), 
	fv_query_text CHAR(1000), 
	fv_do_stuff CHAR(1), 
	rpt_pageno SMALLINT, 
	rpt_length SMALLINT, 
	fv_cnter SMALLINT, 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_cost_type LIKE bor.cost_type_ind, 
	fv_uom_code LIKE bor.uom_code, 
	fv_quantity LIKE bor.required_qty, 

	pr_lines RECORD 
		line1_text CHAR(132), 
		line2_text CHAR(132), 
		line3_text CHAR(132), 
		line4_text CHAR(132), 
		line5_text CHAR(132), 
		line6_text CHAR(132), 
		line7_text CHAR(132), 
		line8_text CHAR(132), 
		line9_text CHAR(132), 
		line10_text CHAR(132) 
	END RECORD, 

	fr_bor RECORD LIKE bor.*, 
	fr_workcentre RECORD LIKE workcentre.*, 
	fr_hld_bor RECORD LIKE bor.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 
###########################################################################
# MAIN
#
# BOR Listing
###########################################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("M27") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	LET fv_do_stuff = true 

	OPEN WINDOW wm168 with FORM "M168" 
	CALL  windecoration_m("M168") -- albo kd-762 

	CALL kandoomenu("M", 157) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # REPORT 
			CALL report_main() 
			RETURNING fv_do_stuff 

			IF fv_do_stuff = true THEN 
				NEXT option pr_menunames.cmd2_code #print 
			END IF 

		ON ACTION "Print Manager" 
			#  command pr_menunames.cmd2_code pr_menunames.cmd2_text
			CALL run_prog("URS", "", "", "", "") 
			NEXT option pr_menunames.cmd1_code #report 


		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text #exit 
			EXIT MENU 

		COMMAND KEY(interrupt) 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW wm168 

END MAIN 
###########################################################################
# END MAIN
###########################################################################


###########################################################################
# FUNCTION report_main()
#
# 
###########################################################################
FUNCTION report_main() 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE 
	fv_where_part CHAR (100), 
	fv_part_code LIKE bor.part_code, 
	fv_cnt SMALLINT, 
	fv_query_ok SMALLINT 


	LET fv_query_ok = true 
	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "ESC TO Accept - DEL TO Exit"

	CONSTRUCT fv_where_part 
	ON bor.parent_part_code 
	FROM parent_part_code 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			LET fv_part_code = show_parents(glob_rec_kandoouser.cmpy_code) 

			IF fv_part_code IS NULL THEN 
			ELSE 
				DISPLAY fv_part_code TO parent_part_code 
				LET fv_where_part = fv_part_code 
				EXIT CONSTRUCT 
			END IF 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_query_ok = false 
	ELSE 
		LET fv_query_text = "SELECT unique parent_part_code", 
		" FROM bor", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code clipped,"' ", 
		" AND ",fv_where_part clipped 

		PREPARE statement1 FROM fv_query_text 

		DECLARE bor_cur CURSOR with HOLD FOR statement1 
		LET fv_cnt = 0 

		FOREACH bor_cur INTO fr_hld_bor.parent_part_code 
			LET fv_cnt = fv_cnt + 1 

			IF fv_cnt = 1 THEN 
				SELECT man_uom_code 
				INTO fv_uom_code 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_hld_bor.parent_part_code 

				CALL report_sub() RETURNING fv_query_ok 

				IF fv_query_ok = true THEN 

					#------------------------------------------------------------
					LET l_rpt_idx = rpt_start(getmoduleid(),"M27_rpt_list_bor","N/A", RPT_SHOW_RMS_DIALOG)
					IF l_rpt_idx = 0 THEN #User pressed CANCEL
						RETURN FALSE
					END IF	
					START REPORT M27_rpt_list_bor TO rpt_get_report_file_with_path2(l_rpt_idx)
					WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
					TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
					BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
					LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
					RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
					#------------------------------------------------------------				
				
				ELSE 
					LET fv_cnt = 0 
					EXIT FOREACH 
				END IF 
			END IF 

			CALL build_report(l_rpt_idx, fr_hld_bor.parent_part_code) 
		END FOREACH 

		IF fv_cnt > 0 THEN 

			#------------------------------------------------------------
			FINISH REPORT M27_rpt_list_bor
			CALL rpt_finish("M27_rpt_list_bor")
			#------------------------------------------------------------

		END IF 
		DISPLAY "" TO parent_part_code 
		DISPLAY "" TO cost_type 
		DISPLAY "" TO quantity 
	END IF 

	RETURN fv_query_ok 

END FUNCTION 
###########################################################################
# END FUNCTION report_main()
###########################################################################


###########################################################################
# FUNCTION report_sub()
#
#
###########################################################################
FUNCTION report_sub() 
	DEFINE 
	fv_data_exists SMALLINT, 
	fv_item_code LIKE product.part_code, 
	fv_description LIKE product.desc_text, 
	fv_security_ind LIKE kandoouser.security_ind 


	LET fv_quantity = "" 
	LET fv_data_exists = true 
	LET fv_cost_type = "W" 

	DISPLAY fv_cost_type TO cost_type 
	DISPLAY fv_quantity TO quantity 

	INPUT fv_cost_type, fv_quantity WITHOUT DEFAULTS 
	FROM cost_type, quantity 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD cost_type 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

		AFTER FIELD quantity 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			IF fv_quantity IS NULL THEN 
				LET fv_quantity = 0 
			END IF 

		ON KEY (accept) 
			IF fv_quantity IS NULL THEN 
				LET fv_quantity = 0 
			END IF 

			EXIT INPUT 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET fv_data_exists = false 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	IF fv_cost_type = "C" THEN 
		SELECT cost_ind 
		INTO fv_cost_type 
		FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		IF fv_cost_type = "F" THEN 
			LET fv_cost_type = "W" 
		END IF 
	END IF 

	RETURN fv_data_exists 

END FUNCTION 
###########################################################################
# END FUNCTION report_sub()
###########################################################################


###########################################################################
# FUNCTION build_report(fv_parent_part_code)
#
#
###########################################################################
FUNCTION build_report(p_rpt_idx,fv_parent_part_code)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE 
	fv_hld_type LIKE bor.type_ind, 
	fv_hld_part_code LIKE bor.part_code, 
	fv_hld_desc LIKE product.desc_text, 
	fv_hld_qty LIKE bor.required_qty, 
	fv_hld_uom LIKE bor.uom_code, 
	fv_hld_qtytim LIKE workcentre.processing_ind, 
	fv_hld_oper LIKE bor.oper_factor_amt, 
	fv_hld_rate LIKE bor.cost_amt, 
	fv_hld_unitcst LIKE bor.cost_amt, 
	fv_hld_unitprc LIKE bor.price_amt, 
	fv_parent_part_code LIKE bor.part_code, 
	fv_wc_tot LIKE bor.cost_amt, 
	fv_cost_tot LIKE bor.cost_amt, 
	fv_cost_amt LIKE bor.cost_amt, 
	fv_min_ord_qty LIKE product.min_ord_qty, 
	fv_pur_stk_con_qty LIKE product.pur_stk_con_qty, 
	fv_man_uom_code LIKE prodmfg.man_uom_code, 
	fv_man_stk_con_qty LIKE prodmfg.man_stk_con_qty, 
	fv_quantity_flg SMALLINT, 
	fv_setup_qty SMALLINT, 
	fv_hld_timunt CHAR(8), 
	fv_hld_capacity CHAR(12), 
	fv_output CHAR(80) 


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

	LET fv_quantity_flg = 0 
	LET fv_cost_tot = 0 

	IF fv_quantity = 0 THEN 
		LET fv_quantity = fv_min_ord_qty 
		LET fv_quantity_flg = 1 
	END IF 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	ORDER BY sequence_num 

	FOREACH c_child INTO fr_bor.* 
		DISPLAY fr_bor.part_code at 1,27 


		LET fv_hld_type = "" 
		LET fv_hld_part_code = "" 
		LET fv_hld_desc = "" 
		LET fv_hld_qty = NULL 
		LET fv_hld_capacity = "" 
		LET fv_hld_oper = NULL 
		LET fv_hld_rate = NULL 
		LET fv_hld_timunt = "" 
		LET fv_hld_unitcst = NULL 
		LET fv_hld_unitprc = NULL 

		CASE fr_bor.type_ind 
			WHEN "I" 
				LET fr_bor.part_code = "INSTRUCTION" 

			WHEN "S" 
				LET fr_bor.part_code = "COST" 

				IF fr_bor.required_qty IS NULL THEN 
					LET fr_bor.required_qty = 1 
				END IF 

				LET fv_hld_qty = fv_quantity / fr_bor.required_qty 

				IF fr_bor.cost_type_ind = "F" THEN 
					LET fv_cost_amt = fr_bor.cost_amt 
					LET fr_bor.price_amt = fr_bor.price_amt 
				ELSE 
					LET fv_cost_amt = fr_bor.cost_amt * fv_hld_qty 
					LET fr_bor.price_amt = fr_bor.price_amt * fv_hld_qty 
				END IF 

				IF fr_bor.price_amt > 0 THEN 
					LET fv_hld_unitprc = fr_bor.price_amt 
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

				IF fr_bor.desc_text IS NULL THEN 
					LET fr_bor.desc_text = fr_workcentre.desc_text 
				END IF 

				CASE fr_workcentre.time_unit_ind 
					WHEN "D" 
						LET fv_hld_timunt = "day" 
					WHEN "H" 
						LET fv_hld_timunt = "hr" 
					WHEN "M" 
						LET fv_hld_timunt = "min" 
				END CASE 

				IF fr_workcentre.processing_ind = "Q" THEN 
					LET fv_hld_capacity = 
					fr_workcentre.unit_uom_code clipped, " per ", 
					fv_hld_timunt 
				ELSE 
					LET fv_hld_capacity = 
					fv_hld_timunt clipped, "s per ", 
					fr_workcentre.unit_uom_code 
				END IF 

				LET fr_bor.required_qty = fr_workcentre.time_qty 
				#               LET fv_hld_uom     = fr_workcentre.unit_uom_code
				LET fv_hld_qty = fr_bor.required_qty 
				LET fv_hld_oper = fr_bor.oper_factor_amt 
				LET fv_hld_rate = fr_bor.cost_amt 

			WHEN "U" 
				LET fr_bor.part_code = "SET UP" 

				# IF fr_bor.cost_type_ind = "Q" THEN
				#     LET fv_setup_qty = fv_quantity / fr_bor.var_amt
				#     IF fv_setup_qty < 1 THEN
				#         LET fv_setup_qty = 1
				#     END IF

				#     LET fv_cost_amt = fr_bor.cost_amt * fv_setup_qty
				# ELSE
				#     LET fv_cost_amt = fr_bor.cost_amt
				# END IF

				# IF fr_bor.price_amt > 0 THEN
				#     LET fv_hld_unitprc = fr_bor.price_amt
				# END IF

				LET fv_cost_amt = fr_bor.cost_amt 
				LET fv_hld_qty = fr_bor.required_qty 
				LET fv_hld_unitprc = fr_bor.price_amt 

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

				LET fr_bor.desc_text = fr_product.desc_text 

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

				LET fv_hld_unitprc = fr_bor.price_amt 

				SELECT * 
				INTO fr_prodmfg.* 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				LET fv_hld_qty = fr_bor.required_qty * fv_quantity 
				LET fv_hld_capacity = fr_prodmfg.man_uom_code 
		END CASE 

		LET fv_hld_type = fr_bor.type_ind 
		LET fv_hld_part_code = fr_bor.part_code 
		LET fv_hld_desc = fr_bor.desc_text 

		IF fr_bor.type_ind = "W" THEN 
			LET fv_hld_unitcst = fv_wc_tot 
			LET fv_hld_unitprc = 
			fv_hld_unitcst * ((fr_workcentre.cost_markup_per / 100) + 1) 
		ELSE 
			IF fr_bor.type_ind matches "[US]" THEN 
				LET fv_hld_unitcst = fv_cost_amt 
				LET fv_hld_unitprc = fv_hld_unitprc 
			ELSE 
				LET fv_hld_unitcst = fv_cost_amt * fv_quantity 
				LET fv_hld_unitprc = fv_hld_unitprc * fv_quantity 
			END IF 
		END IF 

		IF fr_bor.type_ind matches "[BI]" THEN 
			LET fv_hld_unitcst = 0 
			LET fv_hld_unitprc = 0 
		ELSE 
			IF fv_hld_unitcst IS NULL THEN 
				LET fv_hld_unitcst = 0 
			END IF 

			IF fv_hld_unitprc IS NULL THEN 
				LET fv_hld_unitprc = 0 
			END IF 

			IF fr_bor.type_ind NOT matches "[USW]" THEN 
				LET fv_hld_unitcst = fv_hld_unitcst * fr_bor.required_qty 
				LET fv_hld_unitprc = fv_hld_unitprc * fr_bor.required_qty 
			END IF 
		END IF 

		#---------------------------------------------------------
		OUTPUT TO REPORT M27_rpt_list_bor(p_rpt_idx,
		fr_hld_bor.parent_part_code,fv_hld_type, 
		fv_hld_part_code, fv_hld_desc, fv_hld_qty, 
		fv_hld_capacity, fv_hld_rate, fv_hld_oper, 
		fv_hld_unitcst, fv_hld_unitprc) 
		#---------------------------------------------------------

	END FOREACH 

	IF fv_quantity_flg = 1 THEN 
		LET fv_quantity = 0 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION build_report(fv_parent_part_code)
###########################################################################


###########################################################################
# REPORT M27_rpt_list_bor( rv_hld_parent, rv_hld_type, rv_hld_part_code, 
#	rv_hld_desc, rv_hld_qty, 
#	rv_hld_capacity, rv_hld_rate, rv_hld_oper, 
#	rv_hld_unitcst, rv_hld_unitprc)
#
#
###########################################################################
REPORT M27_rpt_list_bor(p_rpt_idx, rv_hld_parent, rv_hld_type, rv_hld_part_code, 
	rv_hld_desc, rv_hld_qty, 
	rv_hld_capacity, rv_hld_rate, rv_hld_oper, 
	rv_hld_unitcst, rv_hld_unitprc) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	rv_hld_parent LIKE bor.parent_part_code, 
	rv_hld_part_code LIKE bor.part_code, 
	rv_hld_desc LIKE product.desc_text, 
	rv_hld_qty LIKE bor.required_qty, 
	rv_hld_oper LIKE bor.oper_factor_amt, 
	rv_hld_rate LIKE bor.cost_amt, 
	rv_hld_unitcst LIKE bor.cost_amt, 
	rv_hld_unitprc LIKE bor.price_amt, 
	rv_total_cost LIKE bor.cost_amt, 
	rv_total_price LIKE bor.cost_amt, 
	fv_desc LIKE product.desc_text, 
	rv_cost_ind LIKE inparms.cost_ind, 
	rv_hld_type CHAR(1), 
	rv_hld_sub_type CHAR(1), 
	rv_hld_capacity CHAR(12), 
	fv_type CHAR(22), 
	rv_cmpy_name CHAR(30), 
	rv_title CHAR(70), 
	rv_position SMALLINT 

	OUTPUT 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
			
			SELECT cost_ind 
			INTO rv_cost_ind 
			FROM inparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

			CASE 
			#WHEN fv_cost_type = "F"
			#    IF rv_cost_ind = "F" THEN
			#        LET fv_type = "FIFO COGS"
			#    ELSE
			#        LET fv_type = "FIFO"
			#    END IF

				WHEN fv_cost_type = "W" 
					IF rv_cost_ind = "W" THEN 
						LET fv_type = "Weighted Average COGS" 
					ELSE 
						LET fv_type = "Weighted Average" 
					END IF 

				WHEN fv_cost_type = "S" 
					IF rv_cost_ind = "S" THEN 
						LET fv_type = "Standard COGS" 
					ELSE 
						LET fv_type = "Standard" 
					END IF 

				WHEN fv_cost_type = "L" 
					IF rv_cost_ind = "L" THEN 
						LET fv_type = "Latest COGS" 
					ELSE 
						LET fv_type = "Latest" 
					END IF 
			END CASE 

			SELECT desc_text 
			INTO fv_desc 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = rv_hld_parent 

			PRINT COLUMN 1, "Parent Product:", 
			COLUMN 17, rv_hld_parent, 
			COLUMN 43, "Cost Type:", 
			COLUMN 54, fv_type, 
			COLUMN 78, "Query Quantity:", 
			COLUMN 94, fv_quantity, 
			COLUMN 112, "UOM:", 
			COLUMN 117, fv_uom_code 

			PRINT COLUMN 17, fv_desc 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT 
			COLUMN 1, "Type", 
			COLUMN 6, "Product", 
			COLUMN 22, "Description", 
			COLUMN 58, "Quantity/Capacity", 
			COLUMN 82, "Rate/Op. Factor", 
			COLUMN 105, "Total Cost", 
			COLUMN 122, "Total Price" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

		BEFORE GROUP OF rv_hld_parent 
			SKIP TO top OF PAGE 

		ON EVERY ROW 
			IF rv_hld_type matches "[CB]" THEN 
				SELECT part_type_ind 
				INTO rv_hld_sub_type 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = rv_hld_part_code 
			ELSE 
				LET rv_hld_sub_type = "" 
			END IF 

			PRINT 
			COLUMN 1, rv_hld_type, 
			COLUMN 3, rv_hld_sub_type, 
			COLUMN 6, rv_hld_part_code, 
			COLUMN 22, rv_hld_desc clipped, 
			COLUMN 52, rv_hld_qty, 
			COLUMN 67, rv_hld_capacity, 
			COLUMN 79, rv_hld_rate USING "####.####", 
			COLUMN 88, rv_hld_oper USING "####.####", 
			COLUMN 97, rv_hld_unitcst, 
			COLUMN 115, rv_hld_unitprc 

			LET rv_total_cost = rv_total_cost + rv_hld_unitcst 
			LET rv_total_price = rv_total_price + rv_hld_unitprc 

		AFTER GROUP OF rv_hld_parent 
			PRINT 
			COLUMN 99, "----------------", 
			COLUMN 117, "----------------" 

			PRINT 
			COLUMN 90, "Totals", 
			COLUMN 97, rv_total_cost, 
			COLUMN 115, rv_total_price 
			PRINT 
			COLUMN 99, "----------------", 
			COLUMN 117, "----------------" 

			SKIP 1 line 

			PRINT 
			COLUMN 5, "Selection Criteria : ", 
			COLUMN 26, fv_query_text clipped 

			LET rv_total_cost = 0 
			LET rv_total_price = 0 

		ON LAST ROW 
			LET rv_title = "***** END OF REPORT M27 *****" 
			LET rv_position = (132-length(rv_title))/2 

			PRINT 
			PRINT COLUMN rv_position, rv_title 

			LET rpt_pageno = pageno 
			LET rpt_length = 66 

END REPORT 
###########################################################################
# END REPORT M27_rpt_list_bor(p_rpt_idx, rv_hld_parent, rv_hld_type, rv_hld_part_code, 
#	rv_hld_desc, rv_hld_qty, 
#	rv_hld_capacity, rv_hld_rate, rv_hld_oper, 
#	rv_hld_unitcst, rv_hld_unitprc)
###########################################################################