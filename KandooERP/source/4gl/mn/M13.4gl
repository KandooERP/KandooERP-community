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

	Source code beautified by beautify.pl on 2020-01-02 17:31:17	$Id: $
}


# Purpose - Manufacturing product maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M13_GLOBALS.4gl" 

DEFINE 
gr_prodmfg RECORD LIKE prodmfg.*, 

gr_prodmfg_lookup RECORD 
	company_name LIKE company.name_text, 
	part_description LIKE product.desc_text, 
	type_description CHAR(12), 
	cust_name LIKE customer.name_text, 
	warehouse_name LIKE warehouse.desc_text 
END RECORD 

MAIN 

	#Initial UI Init
	CALL setModuleId("M13") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL prodmfg_main() 

END MAIN 

#----------------------------------------------------------------------------#
#  FUNCTION TO OPEN up the window AND implement the menu                     #
#----------------------------------------------------------------------------#

FUNCTION prodmfg_main() 

	DEFINE 
	fv_data_exists SMALLINT, 
	fv_waste SMALLINT, 
	fv_description LIKE product.desc_text 

	INITIALIZE gr_prodmfg.* TO NULL 

	OPEN WINDOW w1_m126 with FORM "M126" 
	CALL  windecoration_m("M126") -- albo kd-762 

	WHILE true 
		CLEAR FORM 
		LET fv_reselect = true 

		LET msgresp = kandoomsg("M",1505,"") 
		# MESSAGE "ESC TO accept, DEL TO Exit"

		CONSTRUCT BY NAME fv_where_part 
		ON prodmfg.part_code, product.desc_text, prodmfg.part_type_ind 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 


		LET fv_cnt = 1 

		LET fv_type = NULL 
		LET fv_cnt = 1 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		CALL show_prodmfgs() RETURNING fv_part_code 

		IF fv_part_code IS NULL THEN 
			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			ELSE 
				CONTINUE WHILE 
			END IF 
		END IF 

		SELECT * 
		INTO gr_prodmfg.* 
		FROM prodmfg 
		WHERE prodmfg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND prodmfg.part_code = fv_part_code 


		OPEN WINDOW w0_prodmfg with FORM "M117" 
		CALL  windecoration_m("M117") 

		CALL display_prodmfg(gr_prodmfg.part_code) 

		DISPLAY 
		fv_part_code 
		TO part_code 

		CALL update_prodmfg(gr_prodmfg.part_code) RETURNING fv_waste 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 

		CALL display_prodmfg(gr_prodmfg.part_code) 

		CLOSE WINDOW w0_prodmfg 
	END WHILE 

	CLOSE WINDOW w1_m126 

END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY an item master RECORD on the SCREEN                   #
#----------------------------------------------------------------------------#

FUNCTION display_prodmfg(fv_part_code) 

	DEFINE 
	fv_part_code LIKE prodmfg.part_code 

	LET gr_prodmfg.part_code = fv_part_code 

	SELECT desc_text 
	INTO gr_prodmfg_lookup.part_description 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = gr_prodmfg.part_code 

	LET gr_prodmfg_lookup.type_description = 
	lookup_type_code(gr_prodmfg.part_type_ind ) 
	LET gr_prodmfg_lookup.warehouse_name = 
	lookup_warehouse( gr_prodmfg.def_ware_code) 
	LET gr_prodmfg_lookup.cust_name = lookup_customer( gr_prodmfg.cust_code) 

	DISPLAY 
	gr_prodmfg.part_code, gr_prodmfg.part_type_ind, 
	gr_prodmfg.def_ware_code, gr_prodmfg.man_uom_code, 
	gr_prodmfg.man_stk_con_qty, gr_prodmfg.cust_code, 
	gr_prodmfg.backflush_ind, gr_prodmfg.mps_ind, 
	gr_prodmfg.config_ind, gr_prodmfg.demand_fence_num, 
	gr_prodmfg.plan_fence_num, gr_prodmfg_lookup.part_description, 
	gr_prodmfg_lookup.type_description, gr_prodmfg_lookup.cust_name, 
	gr_prodmfg_lookup.warehouse_name, gr_prodmfg.yield_per, 
	gr_prodmfg.scrap_per, gr_prodmfg.draw_revsn_text, 
	gr_prodmfg.revsn_date 
	TO part_code, part_type_ind, 
	def_ware_code, man_uom_code, 
	man_stk_con_qty, cust_code, 
	backflush_ind, mps_ind, 
	config_ind, demand_fence_num, 
	plan_fence_num, part_description, 
	type_description, cust_name, 
	warehouse_name, yield_per, 
	scrap_per, draw_revsn_text, 
	revsn_date 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO INPUT data FROM the SCREEN AND  INSERT it INTO the database   #
#----------------------------------------------------------------------------#

FUNCTION update_prodmfg(fv_part_code) 

	DEFINE 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fv_part_code LIKE prodmfg.part_code, 

	fr_prodmfg_lookup RECORD 
		company_name LIKE company.name_text, 
		part_description LIKE product.desc_text, 
		type_description CHAR(12), 
		cust_name LIKE customer.name_text, 
		warehouse_name LIKE warehouse.desc_text 
	END RECORD, 

	fv_update_ok SMALLINT, 
	fv_field SMALLINT, 
	fv_count SMALLINT 

	LET gr_prodmfg.part_code = fv_part_code 

	LET msgresp = kandoomsg("M",1510,"") 
	# MESSAGE "Amend details AND press ESC TO continue, F2 TO Delete"

	LET fr_prodmfg.* = gr_prodmfg.* 
	LET fr_prodmfg_lookup.* = gr_prodmfg_lookup.* 

	DISPLAY 
	fr_prodmfg.part_code, fr_prodmfg.part_type_ind, 
	fr_prodmfg.def_ware_code, fr_prodmfg.man_uom_code, 
	fr_prodmfg.man_stk_con_qty, fr_prodmfg.cust_code, 
	fr_prodmfg.backflush_ind, fr_prodmfg.mps_ind, 
	fr_prodmfg.config_ind, fr_prodmfg.demand_fence_num, 
	fr_prodmfg.plan_fence_num, fr_prodmfg_lookup.part_description, 
	fr_prodmfg_lookup.type_description, fr_prodmfg_lookup.cust_name, 
	fr_prodmfg_lookup.warehouse_name, fr_prodmfg.yield_per, 
	fr_prodmfg.scrap_per, fr_prodmfg.draw_revsn_text, 
	fr_prodmfg.revsn_date 
	TO part_code, part_type_ind, 
	def_ware_code, man_uom_code, 
	man_stk_con_qty, cust_code, 
	backflush_ind, mps_ind, 
	config_ind, demand_fence_num, 
	plan_fence_num, part_description, 
	type_description, cust_name, 
	warehouse_name, yield_per, 
	scrap_per, draw_revsn_text, 
	revsn_date 

	LET fv_update_ok = false 

	INPUT 
	fr_prodmfg.part_type_ind, fr_prodmfg.def_ware_code, 
	fr_prodmfg.man_uom_code, fr_prodmfg.man_stk_con_qty, 
	fr_prodmfg.cust_code, fr_prodmfg.backflush_ind, 
	fr_prodmfg.mps_ind, fr_prodmfg.config_ind, 
	fr_prodmfg.demand_fence_num, fr_prodmfg.plan_fence_num, 
	fr_prodmfg_lookup.part_description, fr_prodmfg_lookup.type_description, 
	fr_prodmfg_lookup.cust_name, fr_prodmfg.yield_per, 
	fr_prodmfg.scrap_per, fr_prodmfg.draw_revsn_text, 
	fr_prodmfg.revsn_date 
	WITHOUT DEFAULTS 
	FROM 
	part_type_ind, def_ware_code, 
	man_uom_code, man_stk_con_qty, 
	cust_code, backflush_ind, 
	mps_ind, config_ind, 
	demand_fence_num, plan_fence_num, 
	part_description, type_description, 
	cust_name, yield_per, 
	scrap_per, draw_revsn_text, 
	revsn_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD part_type_ind 
			LET fr_prodmfg_lookup.type_description = 
			lookup_type_code(fr_prodmfg.part_type_ind ) 

			IF fr_prodmfg_lookup.type_description = "err" THEN 
				LET fr_prodmfg.part_type_ind = NULL 
				LET fr_prodmfg_lookup.type_description = NULL 

				DISPLAY 
				fr_prodmfg.part_type_ind , 
				fr_prodmfg_lookup.type_description 
				TO part_type_ind, 
				type_description 

				NEXT FIELD part_type_ind 
			END IF 

			DISPLAY 
			fr_prodmfg.part_type_ind , 
			fr_prodmfg_lookup.type_description 
			TO part_type_ind, 
			type_description 

			CASE 
				WHEN fr_prodmfg.part_type_ind ="P" 
					INITIALIZE 
					fr_prodmfg.yield_per, 
					fr_prodmfg.scrap_per, 
					fr_prodmfg_lookup.warehouse_name, 
					fr_prodmfg.draw_revsn_text, 
					fr_prodmfg.revsn_date 
					TO NULL 

				WHEN fr_prodmfg.part_type_ind ="R" 
					SELECT unique count(*) 
					INTO fv_count 
					FROM bor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parent_part_code = gr_prodmfg.part_code 

					IF fv_count > 0 THEN 
						LET msgresp = kandoomsg("M",9518,"") 
						# ERROR "There are no BOR's with this parent component"
						NEXT FIELD part_type_ind 
					END IF 
			END CASE 

			DISPLAY 
			fr_prodmfg.part_code, fr_prodmfg.part_type_ind, 
			fr_prodmfg.def_ware_code, fr_prodmfg.man_uom_code, 
			fr_prodmfg.man_stk_con_qty, fr_prodmfg.cust_code, 
			fr_prodmfg.backflush_ind, fr_prodmfg.mps_ind, 
			fr_prodmfg.config_ind, fr_prodmfg.demand_fence_num, 
			fr_prodmfg.plan_fence_num, fr_prodmfg_lookup.part_description, 
			fr_prodmfg_lookup.type_description, fr_prodmfg_lookup.cust_name, 
			fr_prodmfg.yield_per, fr_prodmfg.scrap_per, 
			fr_prodmfg.draw_revsn_text, fr_prodmfg.revsn_date 
			TO part_code, part_type_ind, 
			def_ware_code, man_uom_code, 
			man_stk_con_qty, cust_code, 
			backflush_ind, mps_ind, 
			config_ind, demand_fence_num, 
			plan_fence_num, part_description, 
			type_description, cust_name, 
			yield_per, scrap_per, 
			draw_revsn_text, revsn_date 

			LET fr_prodmfg_lookup.part_description= 
			lookup_item_code( fr_prodmfg.part_code) 

			DISPLAY 
			fr_prodmfg.part_code, 
			fr_prodmfg_lookup.part_description 
			TO part_code, 
			part_description 


		AFTER FIELD def_ware_code 
			LET fr_prodmfg_lookup.warehouse_name = 
			lookup_warehouse( fr_prodmfg.def_ware_code) 

			IF fr_prodmfg_lookup.warehouse_name IS NULL THEN 
				LET msgresp = kandoomsg("M",9534,"") 
				# ERROR "This warehouse does NOT exist in the database"
				NEXT FIELD def_ware_code 
			END IF 

			SELECT unique count(*) 
			INTO fv_count 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_prodmfg.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			IF fv_count = 0 THEN 
				LET msgresp = kandoomsg("M",9557,"") 
				# ERROR "No prodstatus RECORD found FOR this warehouse"
				NEXT FIELD def_ware_code 
			END IF 

			DISPLAY 
			fr_prodmfg_lookup.warehouse_name 
			TO warehouse_name 

		AFTER FIELD man_uom_code 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD def_ware_code 
			END IF 

			IF NOT uom_exists(fr_prodmfg.man_uom_code) THEN 
				LET fr_prodmfg.man_uom_code = NULL 
				DISPLAY 
				fr_prodmfg.man_uom_code 
				TO man_uom_code 

				NEXT FIELD man_uom_code 
			ELSE 
				NEXT FIELD man_stk_con_qty 
			END IF 

		AFTER FIELD man_stk_con_qty 
			IF fr_prodmfg.man_stk_con_qty <= 0 THEN 
				LET msgresp = kandoomsg("M",9558,"") 
				# ERROR "Quantity conversion must be greater than zero"
				NEXT FIELD man_stk_con_qty 
			END IF 

		AFTER FIELD backflush_ind 
			IF fr_prodmfg.backflush_ind NOT matches "[YN]" THEN 
				LET msgresp = kandoomsg("M",9536,"") 
				# ERROR "Backflush Indicator must be either Y OR N"
				NEXT FIELD backflush_ind 
			END IF 

		BEFORE FIELD mps_ind 
			IF fr_prodmfg.part_type_ind matches "[PR]" THEN 
				LET fr_prodmfg.cust_code = NULL 
				LET fr_prodmfg.mps_ind = "N" 
				LET fr_prodmfg.config_ind = "N" 
				LET fr_prodmfg.demand_fence_num = 0 
				LET fr_prodmfg.plan_fence_num = 0 
				NEXT FIELD yield_per 
			END IF 

		AFTER FIELD mps_ind 
			IF fr_prodmfg.mps_ind matches "[Y]" THEN 
				IF fr_prodmfg.part_type_ind matches "[PR]" THEN 
					LET msgresp = kandoomsg("M",9537,"") 
					# ERROR "M.P.S cannot be SET up FOR a non manufactured item"
					NEXT FIELD mps_ind 
				END IF 
			ELSE 
				IF fr_prodmfg.mps_ind matches "[N]" THEN 
					SELECT unique count(*) 
					INTO fv_count 
					FROM shopordhead 
					WHERE shopordhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND shopordhead.part_code = fr_prodmfg.part_code 
					AND shopordhead.order_type_ind = "F" 

					IF fv_count > 0 THEN 
						LET msgresp = kandoomsg("M",9559,"") 
						# ERROR "M.P.S cannot be reset WHEN forecasts exist"
						NEXT FIELD mps_ind 
					END IF 
				ELSE 
					IF fr_prodmfg.mps_ind NOT matches "[YN]" THEN 
						LET msgresp = kandoomsg("M",9538,"") 
						# ERROR "M.P.S Indicator must be either Y OR N"
						NEXT FIELD mps_ind 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD config_ind 
			IF fr_prodmfg.part_type_ind matches "[M]" THEN 
				LET fr_prodmfg.config_ind = "N" 
				NEXT FIELD demand_fence_num 
			END IF 

		AFTER FIELD config_ind 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD mps_ind 
			END IF 

			IF fr_prodmfg.part_type_ind = "G" 
			AND fr_prodmfg.config_ind = "Y" THEN 
				SELECT unique count(*) 
				INTO fv_count 
				FROM bor 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND parent_part_code = gr_prodmfg.part_code 

				IF fv_count > 0 THEN 
					LET msgresp = kandoomsg("M",9560,"") 
					# ERROR "Cannot change TO configured, BOR exists"
					NEXT FIELD config_ind 
				END IF 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[M]" THEN 
				LET fr_prodmfg.config_ind = "N" 
				NEXT FIELD demand_fence_num 
			END IF 

			IF fr_prodmfg.config_ind matches "[YN]" THEN 
				NEXT FIELD demand_fence_num 
			ELSE 
				LET msgresp = kandoomsg("M",9540,"") 
				# ERROR "Config only must be either Y OR N"
				NEXT FIELD config_ind 
			END IF 

		AFTER FIELD demand_fence_num 
			IF fr_prodmfg.demand_fence_num < 0 THEN 
				LET msgresp = kandoomsg("M",9541,"") 
				# ERROR "Demand fence nust be greater than zero"
				NEXT FIELD demand_fence_num 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[M]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD mps_ind 
			END IF 

		AFTER FIELD plan_fence_num 
			IF fr_prodmfg.plan_fence_num < 0 THEN 
				LET msgresp = kandoomsg("M",9542,"") 
				# ERROR "Planning fence must be greater than zero"
				NEXT FIELD plan_fence_num 
			END IF 

			IF fr_prodmfg.plan_fence_num < fr_prodmfg.demand_fence_num THEN 
				LET msgresp = kandoomsg("M",9543,"") 
				#ERROR "Planning fence must NOT be less than demand"
				NEXT FIELD plan_fence_num 
			END IF 

		AFTER FIELD yield_per 
			IF fr_prodmfg.yield_per < 0 THEN 
				LET msgresp = kandoomsg("M",9544,"") 
				#ERROR "Yield percent must be greater than zero"
				NEXT FIELD yield_per 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[PR]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD backflush_ind 
			END IF 

		AFTER FIELD scrap_per 
			IF fr_prodmfg.scrap_per < 0 THEN 
				LET msgresp = kandoomsg("M",9545,"") 
				# ERROR "Scrap percent must be greater than zero"
				NEXT FIELD scrap_per 
			END IF 

		BEFORE FIELD cust_code 
			IF fr_prodmfg.part_type_ind matches "[R]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD man_stk_con_qty 
			END IF 

			IF fr_prodmfg.part_type_ind ="R" THEN 
				LET fr_prodmfg.cust_code = NULL 
				NEXT FIELD backflush_ind 
			END IF 

		AFTER FIELD cust_code 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD man_stk_con_qty 
			END IF 

			LET fr_prodmfg_lookup.cust_name = 
			lookup_customer( fr_prodmfg.cust_code) 

			IF fr_prodmfg_lookup.cust_name IS NULL THEN 
				LET fr_prodmfg.cust_code=null 
				DISPLAY 
				fr_prodmfg.cust_code, 
				fr_prodmfg_lookup.cust_name 
				TO cust_code, 
				cust_name 

				NEXT FIELD backflush_ind 
			END IF 

			DISPLAY 
			fr_prodmfg.cust_code, 
			fr_prodmfg_lookup.cust_name 
			TO cust_code, 
			cust_name 

		AFTER INPUT 
			IF (int_flag 
			OR quit_flag) THEN 
				EXIT INPUT 
			END IF 

			LET fr_prodmfg_lookup.warehouse_name = 
			lookup_warehouse(fr_prodmfg.def_ware_code) 

			IF fr_prodmfg_lookup.warehouse_name IS NULL THEN 
				LET msgresp = kandoomsg("M",9534,"") 
				# ERROR "This warehouse does NOT exist in the database"
				NEXT FIELD def_ware_code 
			END IF 

			IF fr_prodmfg.part_type_ind IS NULL THEN 
				LET msgresp = kandoomsg("M",9533,"") 
				# ERROR "Invalid part type entered"
				NEXT FIELD part_type_ind 
			ELSE 
				IF fr_prodmfg.part_type_ind NOT matches "[GPMR]" THEN 
					LET msgresp = kandoomsg("M",9533,"") 
					# ERROR "Invalid part type entered"
					NEXT FIELD part_type_ind 
				END IF 
			END IF 

			IF fr_prodmfg.part_type_ind NOT matches "[P]" THEN 
				IF fr_prodmfg.man_uom_code IS NULL THEN 
					LET msgresp = kandoomsg("M",9547,"") 
					# ERROR "Unit of measure must be entered"
					NEXT FIELD man_uom_code 
				ELSE 
					IF NOT uom_exists(fr_prodmfg.man_uom_code) THEN 
						LET msgresp = kandoomsg("M",9548,"") 
						# ERROR "This UOM does NOT exist in the database"
						NEXT FIELD man_uom_code 
					END IF 
				END IF 
			END IF 

			IF fr_prodmfg.cust_code IS NOT NULL THEN 
				LET fr_prodmfg_lookup.cust_name = 
				lookup_customer( fr_prodmfg.cust_code) 

				IF fr_prodmfg_lookup.cust_name IS NULL THEN 
					LET msgresp = kandoomsg("M",9561,"") 
					# ERROR "This customer does NOT exist in the database"
					NEXT FIELD cust_code 
				END IF 
			END IF 

		ON KEY (F2) 
			CALL delete_prodmfg(gr_prodmfg.part_code) RETURNING fv_update_ok 
			IF fv_update_ok = true THEN 
				CLEAR FORM 
			END IF 

		ON KEY (control-B) 
			CASE 
				WHEN infield(part_code) 
					LET fr_prodmfg.part_code = show_item(glob_rec_kandoouser.cmpy_code) 
					DISPLAY 
					fr_prodmfg.part_code 
					TO part_code 

				WHEN infield(man_uom_code) 
					LET fr_prodmfg.man_uom_code=show_uom(glob_rec_kandoouser.cmpy_code) 
					DISPLAY 
					fr_prodmfg.man_uom_code 
					TO man_uom_code 

				WHEN infield(cust_code) 
					LET fr_prodmfg.cust_code=show_cust(glob_rec_kandoouser.cmpy_code,"") 
					DISPLAY 
					fr_prodmfg.cust_code 
					TO cust_code 

				WHEN infield(def_ware_code) 
					LET fr_prodmfg.def_ware_code = 
					show_ware_part_code(glob_rec_kandoouser.cmpy_code,fr_prodmfg.part_code) 
					DISPLAY 
					fr_prodmfg.def_ware_code 
					TO def_ware_code 
			END CASE 

		ON KEY (interrupt) 
			LET fv_update_ok = false 
			EXIT INPUT 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_update_ok = false 
		LET msgresp = kandoomsg("M",9562,"") 
		# ERROR "Update Aborted"
	ELSE 
		BEGIN WORK 
			LET fr_prodmfg.last_change_date = today 
			LET fr_prodmfg.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_prodmfg.last_program_text = "M13" 

			UPDATE prodmfg 
			SET prodmfg.* = (fr_prodmfg.*) 
			WHERE prodmfg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodmfg.part_code = gr_prodmfg.part_code 

			IF status <> 0 THEN 
				LET msgresp = kandoomsg("M",9550,"") 
				# ERROR "Trouble saving data - Data NOT saved"
				ROLLBACK WORK 
			ELSE 
			COMMIT WORK 
			LET gr_prodmfg.* = fr_prodmfg.* 
			LET fv_update_ok = true 
		END IF 
	END IF 

	RETURN fv_update_ok 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO delete an item master extension FROM the database             #
#----------------------------------------------------------------------------#

FUNCTION delete_prodmfg(fv_part_code) 

	DEFINE 
	fv_delete_ok SMALLINT, 
	fv_answer CHAR(1), 
	fv_part_code LIKE prodmfg.part_code, 
	fv_count INTEGER 

	LET gr_prodmfg.part_code = fv_part_code 
	LET fv_count = 0 

	SELECT unique count(*) 
	INTO fv_count 
	FROM bor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parent_part_code = gr_prodmfg.part_code 

	IF fv_count = 0 THEN 
		SELECT unique count(*) 
		INTO fv_count 
		FROM bor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = gr_prodmfg.part_code 
	END IF 

	IF fv_count = 0 THEN 
		SELECT unique count(*) 
		INTO fv_count 
		FROM shoporddetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ( parent_part_code = gr_prodmfg.part_code 
		OR part_code = gr_prodmfg.part_code) 
	END IF 

	LET fv_delete_ok = true 
	IF fv_count = 0 THEN 
		IF delete_sure(gr_prodmfg.part_code) THEN 
			BEGIN WORK 

				DELETE 
				FROM prodmfg 
				WHERE prodmfg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodmfg.part_code = gr_prodmfg.part_code 

				IF status <> 0 THEN 
					LET msgresp = kandoomsg("M",9563,"") 
					# ERROR "Trouble deleting product, Data NOT deleted"
					LET fv_delete_ok = false 
					ROLLBACK WORK 
				ELSE 
				COMMIT WORK 
				CLEAR FORM 
			END IF 
		ELSE 
			LET fv_delete_ok = false 
		END IF 
	ELSE 
		LET msgresp = kandoomsg("M",9564,"") 
		# ERROR "This item still exists in a BOR, you cannot delete it"
		LET fv_delete_ok = false 
	END IF 

	RETURN fv_delete_ok 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO expand out the item type code given in the item master RECORD #
#----------------------------------------------------------------------------#

FUNCTION lookup_type_code(fp_type) 

	DEFINE 
	fp_type LIKE prodmfg.part_type_ind, 
	fv_description CHAR(12) 

	CASE 
		WHEN fp_type IS NULL 
			LET fv_description = NULL 
		WHEN fp_type = "G" 
			LET fv_description = "Generic" 
		WHEN fp_type = "M" 
			LET fv_description = "Manufactured Product" 
		WHEN fp_type = "P" 
			LET fv_description = "Phantom" 
		WHEN fp_type = "R" 
			LET fv_description = "Raw Material" 
	END CASE 

	RETURN fv_description 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO lookup the description FOR an item code                       #
#----------------------------------------------------------------------------#

FUNCTION lookup_item_code(fp_item_code) 

	DEFINE 
	fp_item_code LIKE bor.parent_part_code, 
	fv_item_description LIKE product.desc_text 

	SELECT desc_text 
	INTO fv_item_description 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fp_item_code 

	IF status <> 0 THEN 
		LET fv_item_description = NULL 
	END IF 

	RETURN fv_item_description 

END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO lookup a customer AND RETURN thier name                       #
#----------------------------------------------------------------------------#

FUNCTION lookup_customer(fp_customer) 

	DEFINE 
	fp_customer LIKE customer.cust_code, 
	fv_customer_name LIKE customer.name_text 


	SELECT name_text 
	INTO fv_customer_name 
	FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = fp_customer 

	IF status <> 0 THEN 
		LET fv_customer_name = NULL 
	END IF 

	RETURN fv_customer_name 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO lookup a warehouse AND RETURN its description                 #
#----------------------------------------------------------------------------#

FUNCTION lookup_warehouse(fp_warehouse_code) 

	DEFINE 
	fp_warehouse_code LIKE warehouse.ware_code, 
	fv_warehouse_desc LIKE warehouse.desc_text 

	SELECT desc_text 
	INTO fv_warehouse_desc 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = fp_warehouse_code 

	IF status <> 0 THEN 
		LET fv_warehouse_desc = NULL 
	END IF 

	RETURN fv_warehouse_desc 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO see IF the specified prodmfg already exists                   #
#----------------------------------------------------------------------------#

FUNCTION exists_prodmfg(fp_part_code) 

	DEFINE 
	fp_part_code LIKE prodmfg.part_code 

	SELECT * 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fp_part_code 

	RETURN (sqlca.sqlcode = 0) 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO check TO see IF the unit of meassure specifid actually exists #
#----------------------------------------------------------------------------#

FUNCTION uom_exists(fp_uom) 

	DEFINE 
	fp_uom LIKE uom.uom_code, 
	fv_uom_count INTEGER 

	LET fv_uom_count = 0 

	SELECT unique count(*) 
	INTO fv_uom_count 
	FROM uom 
	WHERE uom.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND uom.uom_code = fp_uom 

	IF fv_uom_count > 1 THEN 
		LET msgresp = kandoomsg("M",9565,"") 
		# ERROR "Not allowed duplicate UOM in the database"
		LET fv_uom_count = 0 
	ELSE 
		IF fv_uom_count = 0 THEN 
			LET msgresp = kandoomsg("M",9548,"") 
			# ERROR "This uint of measure does NOT exist in the database"
		END IF 
	END IF 

	RETURN fv_uom_count 

END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO RETURN the decision of the user as TO deletion of a RECORD    #
#----------------------------------------------------------------------------#

FUNCTION delete_sure(fp_thing) 

	DEFINE 
	fp_thing CHAR(34), 
	fv_length SMALLINT, 
	fv_left SMALLINT, 
	fv_answer CHAR(1), 
	fv_string CHAR(75) 

	LET fv_string = "Are you sure you want TO delete ", 
	fp_thing clipped," (Y/N)?" 
	LET fv_length = length(fv_string)+2 
	LET fv_left = (75-fv_length)/2 
	{   -- albo
	    OPEN WINDOW w0_sure AT 23,fv_left with 1 rows,fv_length columns
	        ATTRIBUTE(white,border,prompt line first)

	    LET fv_answer = "A"

	    WHILE fv_answer NOT matches "[NY]"
	        prompt fv_string FOR CHAR fv_answer
	        IF (int_flag
	        OR quit_flag) THEN
	            LET int_flag  = FALSE
	            LET quit_flag = FALSE
	            LET fv_answer = "N"
	        ELSE
	            LET fv_answer = upshift(fv_answer)
	        END IF
	    END WHILE

	    CLOSE WINDOW w0_sure
	}
	-- albo --
	LET fv_answer = promptYN("",fv_string,"Y") 
	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_answer = "N" 
	ELSE 
		LET fv_answer = upshift(fv_answer) 
	END IF 
	----------
	RETURN (fv_answer = "Y") 
END FUNCTION 

#----------------------------------------------------------------------------#

#----------------------------------------------------------------------------#

FUNCTION show_prodmfgs() 

	LET fv_query_text = "SELECT prodmfg.part_code, desc_text, ", 
	"part_type_ind ", 
	"FROM prodmfg, product ", 
	"WHERE prodmfg.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND prodmfg.cmpy_code = product.cmpy_code ", 
	"AND prodmfg.part_code = product.part_code ", 
	"AND ", fv_where_part clipped, " ", 
	"ORDER BY prodmfg.part_code" 

	PREPARE sl_stmt1 FROM fv_query_text 
	DECLARE c_prodmfg CURSOR FOR sl_stmt1 

	LET fv_cnt = 1 
	FOREACH c_prodmfg INTO fa_prodmfg[fv_cnt].* 

		CASE fa_prodmfg[fv_cnt].part_type_ind 
			WHEN "G" 
				LET fa_prodmfg[fv_cnt].part_type_text = "Generic" 
			WHEN "M" 
				LET fa_prodmfg[fv_cnt].part_type_text = "Manufactured" 
			WHEN "P" 
				LET fa_prodmfg[fv_cnt].part_type_text = "Phantom" 
			WHEN "R" 
				LET fa_prodmfg[fv_cnt].part_type_text = "Raw Material" 
		END CASE 

		LET fv_cnt = fv_cnt + 1 

		IF fv_cnt > 499 THEN 
			LET msgresp = kandoomsg("M",9567,"") 
			# ERROR "Only first 500 products have been selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp = kandoomsg("M",1511,"") 
	# ERROR "RETURN on line TO Edit, F3 Fwd, F4 Bwd - DEL Exit"

	LET fv_reselect = false 
	CALL set_count(fv_cnt - 1) 

	DISPLAY ARRAY fa_prodmfg TO sr_prodmfg.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M13","display-arr-prodmfg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
		ON KEY (f9) 
			LET fv_reselect = true 
			LET fv_cnt = arr_curr() 
			LET fa_prodmfg[fv_cnt].part_code = NULL 
			EXIT DISPLAY 

		ON KEY (f10) 
			CALL run_prog("I11", "", "", "", "") 

		ON KEY (RETURN) 
			LET fv_cnt = arr_curr() 
			EXIT DISPLAY 

	END DISPLAY 


	IF int_flag OR quit_flag THEN 
		LET fa_prodmfg[fv_cnt].part_code = NULL 
	END IF 

	LET fv_part_code = fa_prodmfg[fv_cnt].part_code 
	RETURN fv_part_code 
END FUNCTION 
