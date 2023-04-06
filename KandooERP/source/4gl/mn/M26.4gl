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


# Purpose - Indented BOR stock available inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 

GLOBALS 

	DEFINE 
	rpt_note CHAR(80), 
	formname CHAR(10), 
	fv_cost_type CHAR(1), 

	fv_indent SMALLINT, 
	fv_indent2 SMALLINT, 
	fv_cnt SMALLINT, 

	fv_makenow LIKE shopordhead.order_qty, 
	fv_makenow_part LIKE shopordhead.order_qty, 
	fv_makenowall LIKE shopordhead.order_qty, 
	fv_makenowall_part LIKE shopordhead.order_qty, 
	fv_short_tot LIKE prodstatus.onhand_qty, 
	fv_parent_part_code LIKE bor.parent_part_code, 
	fv_warehouse_code LIKE prodstatus.ware_code, 
	fv_quantity LIKE bor.required_qty, 
	fv_quantityb LIKE bor.required_qty, 
	fv_stock_qty LIKE prodstatus.onhand_qty, 

	fr_prodmfg RECORD LIKE prodmfg.*, 

	fa_bor_child array[2000] OF RECORD 
		indent_factor CHAR(2), 
		part_code CHAR(37), 
		uom_code CHAR(4), 
		required_qty LIKE bor.required_qty, 
		avail_qty LIKE prodstatus.onhand_qty, 
		onord_qty LIKE prodstatus.onhand_qty, 
		short_qty LIKE prodstatus.onhand_qty 
	END RECORD 

END GLOBALS 

MAIN 
	#Initial UI Init
	CALL setModuleId("M26") -- albo 
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
	fv_runner CHAR(100), 
	fv_answer CHAR(1), 

	fv_parent_part_code LIKE bor.parent_part_code 

	OPEN WINDOW w0_inquiry with FORM "M164" 
	CALL  windecoration_m("M164") -- albo kd-762 

	LET fv_cost_type = "S" 

	WHILE true 
		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "ESC TO accept DEL TO Exit"

		LET fv_parent_part_code = "" 
		LET fv_warehouse_code = "" 
		LET fv_quantity = "" 
		LET fv_makenow = 999999 
		LET fv_makenowall = 999999 

		DISPLAY fv_parent_part_code TO parent_part_code 
		DISPLAY fv_warehouse_code TO warehouse_code 
		DISPLAY fv_quantity TO quantity 
		DISPLAY "" TO noofcomp 
		DISPLAY "" TO makenow 
		DISPLAY "" TO makenowall 
		DISPLAY "" TO uom 

		INPUT fv_parent_part_code, fv_warehouse_code, fv_quantity 
		WITHOUT DEFAULTS 
		FROM parent_part_code, warehouse_code, quantity 

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
					LET msgresp = kandoomsg("M",9516,"") 
					# ERROR "there are no BOR's with this parent"
					NEXT FIELD parent_part_code 
				ELSE 
					SELECT * 
					INTO fr_prodmfg.* 
					FROM prodmfg 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fv_parent_part_code 

					DISPLAY fr_prodmfg.man_uom_code TO uom 
				END IF 

			AFTER FIELD warehouse_code 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				IF fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD parent_part_code 
				END IF 

				IF fv_warehouse_code IS NULL THEN 
					LET fv_warehouse_code = "*" 
				ELSE 
					SELECT unique count(*) 
					INTO fv_cnter 
					FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = fv_parent_part_code 
					AND ware_code = fv_warehouse_code 

					IF fv_cnter = 0 THEN 
						LET msgresp = kandoomsg("M",9517,"") 
						# ERROR "Invalid warehouse code entered"
						NEXT FIELD warehouse_code 
					END IF 
				END IF 

			AFTER FIELD quantity 
				IF (int_flag 
				OR quit_flag) THEN 
					EXIT INPUT 
				END IF 

				IF fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD parent_part_code 
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
							# ERROR "no BOR's with this parent component"
							NEXT FIELD parent_part_code 
						ELSE 
							SELECT * 
							INTO fr_prodmfg.* 
							FROM prodmfg 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code = fv_parent_part_code 

							DISPLAY fr_prodmfg.man_uom_code TO uom 
							DISPLAY fv_parent_part_code TO parent_part_code 
							NEXT FIELD warehouse_code 
						END IF 

					WHEN infield(warehouse_code) 
						LET fv_warehouse_code = 
						show_ware_part_code(glob_rec_kandoouser.cmpy_code, fv_parent_part_code) 

						IF fv_warehouse_code = "" 
						OR fv_warehouse_code IS NULL THEN 
							NEXT FIELD warehouse_code 
						ELSE 
							DISPLAY fv_warehouse_code TO warehouse_code 
							NEXT FIELD quantity 
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
			LET fv_cnt = 0 
			LET fv_indent = -1 
			LET fv_indent2 = 0 
			{
			            OPEN WINDOW w1_IB1 AT 10,10     -- albo  KD-762
			                with 2 rows, 50 columns
			                ATTRIBUTE(border)
			}
			LET msgresp = kandoomsg("U",1506,"") 
			# MESSAGE "searching database - please stand by"
			LET msgresp = kandoomsg("I",1024,"") 
			# MESSAGE "reporting on product"

			CALL view_kids(fv_parent_part_code) 

			LET msgresp = kandoomsg("U",1507,"") 
			# MESSAGE "f10 TO add shop ORDER, del TO EXIT"
			--            CLOSE WINDOW w1_IB1    -- albo  KD-762

			IF fv_cnt = 0 THEN 
				LET fv_cnt = 1 
				LET fa_bor_child[fv_cnt].part_code = 
				kandooword("ALL components AVAILABLE","501") 

				LET msgresp = kandoomsg("M",1507,"") 
				# MESSAGE "f10 TO add shop ORDER, del TO EXIT"


				LET fv_makenow = fv_quantity 
				LET fv_makenowall = fv_quantity 
			ELSE 
				LET msgresp = kandoomsg("M",1508,"") 
				# MESSAGE "f3 fwd f4 bwd f10 TO add shop ORDER del TO EXIT"
			END IF 

			CALL set_count(fv_cnt) 
			DISPLAY fv_cnt TO noofcomp 
			DISPLAY fv_makenow TO makenow 
			DISPLAY fv_makenowall TO makenowall 

			DISPLAY ARRAY fa_bor_child TO sr_bor_child.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","M26","display-arr-bor_child") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (f10) 
					LET fv_idx = arr_curr() 
					CALL run_prog("M31", fv_parent_part_code, fv_makenow, 
					"", "") 
					#                   LET fv_runner =
					#                       "fglgo M31 '", fv_parent_part_code,"' '", fv_makenow,
					#                       "'"#, fr_prodmfg.man_uom_code, "'"
					#                   run fv_runner
					EXIT DISPLAY 
			END DISPLAY 

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

	DEFINE 
	fv_idx SMALLINT, 
	fv_scrn SMALLINT, 
	fv_cnter SMALLINT, 
	fv_cnterb SMALLINT, 
	fv_cntb SMALLINT, 
	fv_cnt1 SMALLINT, 
	fv_avail_qty LIKE prodstatus.onhand_qty, 
	fv_onord_qty LIKE prodstatus.onhand_qty, 
	fv_short_qty LIKE prodstatus.onhand_qty, 
	fv_reser_qty LIKE prodstatus.onhand_qty, 
	fv_onhand_qty LIKE prodstatus.onhand_qty, 
	fv_parent_part_code LIKE bor.parent_part_code, 

	fa_temp_part CHAR(40), 
	fa_hold array[80] OF RECORD LIKE bor.*, 

	fr_bor RECORD LIKE bor.*, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_product RECORD LIKE product.*, 
	fr_prodstatus RECORD LIKE prodstatus.* 

	IF fv_indent < 10 THEN 
		LET fv_indent = fv_indent + 1 
	END IF 

	LET fv_indent2 = fv_indent2 + 1 

	DECLARE c_child CURSOR FOR 
	SELECT * 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = fv_parent_part_code 
	ORDER BY sequence_num 

	LET fv_cnterb = 0 
	FOREACH c_child INTO fr_bor.* 
		LET fv_cnterb = fv_cnterb + 1 
		LET fa_hold[fv_cnterb].* = fr_bor.* 
	END FOREACH 

	LET fv_cntb = 0 
	WHILE fv_cntb < fv_cnterb 
		LET fv_cnt = fv_cnt + 1 
		LET fv_cntb = fv_cntb + 1 
		LET fr_bor.* = fa_hold[fv_cntb].* 

		DISPLAY fr_bor.part_code at 1,27 

		IF fr_bor.type_ind = "C" THEN 
			LET fv_quantityb = fr_bor.required_qty * fv_quantity 

			IF fv_warehouse_code = "*" THEN 
				SELECT sum(onord_qty) 
				INTO fv_onord_qty 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				SELECT sum(onhand_qty) 
				INTO fv_onhand_qty 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 

				SELECT sum(reserved_qty) 
				INTO fv_reser_qty 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 
			ELSE 
				SELECT * 
				INTO fr_prodstatus.* 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_bor.part_code 
				AND ware_code = fv_warehouse_code 

				LET fv_onhand_qty = fr_prodstatus.onhand_qty 
				LET fv_onord_qty = fr_prodstatus.onord_qty 
				LET fv_reser_qty = fr_prodstatus.reserved_qty 
			END IF 

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

			LET fv_onhand_qty = (fv_onhand_qty / fr_product.stk_sel_con_qty) 
			/ fr_prodmfg.man_stk_con_qty 
			LET fv_onord_qty = (fv_onord_qty / fr_product.stk_sel_con_qty) 
			/ fr_prodmfg.man_stk_con_qty 
			LET fv_reser_qty = (fv_reser_qty / fr_product.stk_sel_con_qty) 
			/ fr_prodmfg.man_stk_con_qty 

			LET fv_avail_qty = fv_onhand_qty - fv_reser_qty 

			IF fv_avail_qty <= 0 THEN 
				LET fv_avail_qty = 0 
			END IF 

			IF fv_avail_qty < fv_quantityb THEN 
				IF fv_avail_qty <= 0 THEN 
					LET fv_short_qty = fv_quantityb 
					LET fv_makenow = 0 
				ELSE 
					LET fv_short_qty = fv_quantityb - fv_avail_qty 
					LET fv_makenow_part = fv_avail_qty / fr_bor.required_qty 
					IF fv_makenow_part < fv_makenow THEN 
						LET fv_makenow = fv_makenow_part 
					END IF 
				END IF 

				LET fv_stock_qty = fv_avail_qty + fv_reser_qty 
				IF fv_stock_qty <= 0 THEN 
					LET fv_makenowall = 0 
				ELSE 
					LET fv_makenowall_part = fv_stock_qty / fr_bor.required_qty 
					IF fv_makenowall_part < fv_makenowall THEN 
						LET fv_makenowall = fv_makenowall_part 
					END IF 
				END IF 
			ELSE 
				LET fv_short_qty = 0 
			END IF 

			IF fv_short_qty > 0 THEN 
				LET fv_short_tot = fv_short_tot + fv_short_qty 
				LET fa_bor_child[fv_cnt].indent_factor = fv_indent2 

				IF fv_indent > 0 THEN 
					LET fa_bor_child[fv_cnt].part_code = 
					fa_temp_part[1,fv_indent],fr_bor.part_code 
				ELSE 
					LET fa_bor_child[fv_cnt].part_code = fr_bor.part_code 
				END IF 

				LET fa_bor_child[fv_cnt].uom_code = fr_prodmfg.man_uom_code 
				LET fa_bor_child[fv_cnt].required_qty = 
				fr_bor.required_qty * fv_quantity 

				LET fa_bor_child[fv_cnt].avail_qty = fv_avail_qty 
				LET fa_bor_child[fv_cnt].onord_qty = fv_onord_qty 
				LET fa_bor_child[fv_cnt].short_qty = fv_short_qty 
			ELSE 
				LET fv_cnt = fv_cnt - 1 
			END IF 
		ELSE 
			LET fv_cnt = fv_cnt - 1 
		END IF 

		IF fv_cnt = 2000 THEN 
			LET msgresp = kandoomsg("M",9519,"") 
			# ERROR "only first 2000 children were selected"
			EXIT WHILE 
		END IF 

		SELECT unique count(*) 
		INTO fv_cnter 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parent_part_code = fr_bor.part_code 

		IF fv_cnter > 0 AND fv_short_qty > 0 THEN 
			CALL view_kids(fr_bor.part_code) 
		END IF 
	END WHILE 

	LET fv_indent = fv_indent - 1 
	LET fv_indent2 = fv_indent2 - 1 
END FUNCTION 
