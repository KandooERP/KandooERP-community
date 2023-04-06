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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../mn/M_MN_GLOBALS.4gl" 
GLOBALS 
	DEFINE formname CHAR(10) 
	DEFINE fv_count SMALLINT 
	DEFINE pr_part_code LIKE prodmfg.part_code 
	DEFINE pr_menunames RECORD LIKE menunames.* 
END GLOBALS 
############################################################
# MODULE Scope Variables
############################################################
DEFINE gr_prodmfg RECORD LIKE prodmfg.*
DEFINE gr_prodmfg_lookup RECORD 
	company_name CHAR(30), 
	part_description CHAR(30), 
	type_description CHAR(12), 
	cust_name CHAR(30), 
	warehouse_name CHAR(30) 
END RECORD 
############################################################
# Manufacturing Product Add
############################################################
MAIN 
	
	CALL setModuleId("M11") #Initial UI Init
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL prodmfg_main() 
END MAIN 

############################################################
# FUNCTION prodmfg_main()
#
# OPEN up the window AND implement the menu    
############################################################
FUNCTION prodmfg_main() 

	DEFINE fv_data_exists SMALLINT 

	OPEN WINDOW w0_prodmfg with FORM "M117" 
	CALL  windecoration_m("M117") -- albo kd-762 

	INITIALIZE gr_prodmfg.* TO NULL 

	LET pr_part_code = arg_val(1) 

	WHILE true 
		CALL insert_prodmfg(pr_part_code) 

		INITIALIZE gr_prodmfg.* TO NULL 
		LET pr_part_code = NULL 

		IF promptyn("Exit","Do you wish to quit?","n") = "y" THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW w0_prodmfg 
END FUNCTION 

#------------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY a prodmfg RECORD on the SCREEN                          #
#------------------------------------------------------------------------------#

FUNCTION display_prodmfg() 

	DISPLAY gr_prodmfg.part_code, gr_prodmfg.part_type_ind , 
	gr_prodmfg.def_ware_code, gr_prodmfg.man_uom_code, 
	gr_prodmfg.man_stk_con_qty, gr_prodmfg.cust_code, 
	gr_prodmfg.backflush_ind, gr_prodmfg.mps_ind, 
	gr_prodmfg.config_ind, gr_prodmfg.demand_fence_num, 
	gr_prodmfg.plan_fence_num, gr_prodmfg.yield_per, 
	gr_prodmfg.scrap_per, gr_prodmfg_lookup.part_description, 
	gr_prodmfg_lookup.type_description, gr_prodmfg_lookup.cust_name, 
	gr_prodmfg.draw_revsn_text, gr_prodmfg.revsn_date 
	TO part_code, part_type_ind , 
	def_ware_code, man_uom_code, 
	man_stk_con_qty, cust_code, 
	backflush_ind, mps_ind, 
	config_ind, demand_fence_num, 
	plan_fence_num, yield_per, 
	scrap_per, part_description, 
	type_description, cust_name, 
	draw_revsn_text, revsn_date 

END FUNCTION 

#------------------------------------------------------------------------------#
#  FUNCTION TO INPUT data FROM the SCREEN AND  INSERT it INTO the database     #
#------------------------------------------------------------------------------#

FUNCTION insert_prodmfg(fr_part_code) 

	DEFINE 
	fr_part_code LIKE product.part_code, 
	fr_prodmfg RECORD LIKE prodmfg.*, 
	fr_prodmfg_lookup RECORD 
		company_name LIKE company.name_text, 
		part_description LIKE product.desc_text, 
		type_description CHAR(12), 
		cust_name LIKE customer.name_text, 
		warehouse_name LIKE warehouse.desc_text 
	END RECORD, 

	fv_insert_ok SMALLINT, 
	fv_field SMALLINT 

	MESSAGE "Apply or Exit"

	INITIALIZE fr_prodmfg.*,fr_prodmfg_lookup TO NULL 

	SELECT * 
	INTO gr_prodmfg.* 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_part_code 

	IF status = 0 THEN 
		ERROR "product already exists"
	END IF 

	LET gr_prodmfg.part_code = fr_part_code 
	LET fr_prodmfg.part_code = fr_part_code 
	LET fr_prodmfg.man_stk_con_qty = 1 
	LET gr_prodmfg.man_stk_con_qty = 1 

	SELECT desc_text, 
	stock_uom_code 
	INTO gr_prodmfg_lookup.part_description, 
	gr_prodmfg.man_uom_code 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_part_code 

	DISPLAY BY NAME 
	gr_prodmfg.part_code, gr_prodmfg_lookup.part_description, 
	gr_prodmfg.man_uom_code, gr_prodmfg.man_stk_con_qty 

	CALL display_prodmfg() 
	LET fv_insert_ok = true 

	INPUT BY NAME 
	fr_prodmfg.part_code, fr_prodmfg.part_type_ind, 
	fr_prodmfg.def_ware_code, fr_prodmfg.man_uom_code, 
	fr_prodmfg.man_stk_con_qty, fr_prodmfg.cust_code, 
	fr_prodmfg.backflush_ind, fr_prodmfg.mps_ind, 
	fr_prodmfg.config_ind, fr_prodmfg.demand_fence_num, 
	fr_prodmfg.plan_fence_num, fr_prodmfg.yield_per, 
	fr_prodmfg.scrap_per, fr_prodmfg.draw_revsn_text, 
	fr_prodmfg.revsn_date 
	WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		ON CHANGE part_code
			IF fr_prodmfg.part_code IS NOT NULL THEN
				SELECT unique count(*) 
				INTO fv_count 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_prodmfg.part_code 

				IF fv_count = 0 THEN 
					ERROR "This product does NOT exist in Inventory"
					NEXT FIELD part_code 
				ELSE 
					IF exists_prodmfg(fr_prodmfg.part_code) THEN 
						ERROR "Product already exists"
						NEXT FIELD part_code 
					END IF 

					LET fr_prodmfg_lookup.part_description = lookup_item_code(fr_prodmfg.part_code) 
					DISPLAY fr_prodmfg_lookup.part_description TO part_description 
				END IF 
			END IF 			
			
		AFTER FIELD part_code 
			IF fr_prodmfg.part_code IS NULL THEN 
				MESSAGE "A part code must be entered"
				NEXT FIELD part_code 
			ELSE 
				SELECT unique count(*) 
				INTO fv_count 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_prodmfg.part_code 

				IF fv_count = 0 THEN 
					ERROR "This product does NOT exist in Inventory"
					NEXT FIELD part_code 
				ELSE 
					IF exists_prodmfg(fr_prodmfg.part_code) THEN 
						ERROR "Product already exists"
						NEXT FIELD part_code 
					END IF 
				END IF
				DISPLAY fr_prodmfg_lookup.part_description TO part_description 
			 
			END IF 

		BEFORE FIELD part_type_ind 
			IF (fr_prodmfg.part_code IS NOT null) THEN 
				LET fr_prodmfg_lookup.part_description = lookup_item_code(fr_prodmfg.part_code) 

				IF fr_prodmfg_lookup.part_description IS NULL THEN 
					LET fr_prodmfg.part_code = NULL 

					DISPLAY 
					fr_prodmfg.part_code, 
					fr_prodmfg_lookup.part_description 
					TO part_code, 
					part_description 

					NEXT FIELD part_code 
				END IF 

				DISPLAY fr_prodmfg.part_code TO part_code 
				DISPLAY fr_prodmfg_lookup.part_description TO part_description 
			END IF 

		ON CHANGE part_type_ind
			LET fr_prodmfg_lookup.type_description = lookup_type_code(fr_prodmfg.part_type_ind ) 

		AFTER FIELD part_type_ind 
			LET fr_prodmfg_lookup.type_description = lookup_type_code(fr_prodmfg.part_type_ind ) 
			IF fr_prodmfg_lookup.type_description = "err" THEN 
				LET fr_prodmfg.part_type_ind = NULL 
				LET fr_prodmfg_lookup.type_description = NULL 
				DISPLAY fr_prodmfg.part_type_ind TO part_type_ind 
				DISPLAY fr_prodmfg_lookup.type_description TO type_description
				NEXT FIELD part_type_ind 
			END IF 

			IF fr_prodmfg.part_type_ind IS NULL THEN 
				ERROR "Invalid Part type entered"
				NEXT FIELD part_type_ind 
			ELSE 
				DISPLAY 
				fr_prodmfg.part_type_ind, 
				fr_prodmfg_lookup.type_description 
				TO part_type_ind, 
				type_description 
			END IF 

			CASE 
				WHEN fr_prodmfg.part_type_ind ="P" 
					INITIALIZE 
					fr_prodmfg.yield_per, 
					fr_prodmfg.man_uom_code, 
					fr_prodmfg.man_stk_con_qty, 
					fr_prodmfg.cust_code, 
					fr_prodmfg.backflush_ind, 
					fr_prodmfg.mps_ind, 
					fr_prodmfg.config_ind, 
					fr_prodmfg.demand_fence_num, 
					fr_prodmfg.yield_per, 
					fr_prodmfg.scrap_per, 
					fr_prodmfg_lookup.warehouse_name, 
					fr_prodmfg_lookup.cust_name, 
					fr_prodmfg.draw_revsn_text, 
					fr_prodmfg.revsn_date 
					TO NULL 
			END CASE 

		ON CHANGE def_ware_code
			LET fr_prodmfg_lookup.warehouse_name = lookup_warehouse( fr_prodmfg.def_ware_code) 
			IF fr_prodmfg_lookup.warehouse_name IS NULL THEN 
				ERROR "This warehouse does NOT exist in the database"
				NEXT FIELD def_ware_code 
			END IF 

		AFTER FIELD def_ware_code 
			LET fr_prodmfg_lookup.warehouse_name = lookup_warehouse( fr_prodmfg.def_ware_code) 
			IF fr_prodmfg_lookup.warehouse_name IS NULL THEN 
				ERROR "This warehouse does NOT exist in the database"
				NEXT FIELD def_ware_code 
			END IF 

			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_prodmfg.part_code 
			AND ware_code = fr_prodmfg.def_ware_code 

			IF status <> 0 THEN 
				ERROR "Warehouse NOT SET up FOR this product"
				NEXT FIELD def_ware_code 
			END IF 

			DISPLAY 
			fr_prodmfg_lookup.warehouse_name 
			TO warehouse_name 

		AFTER FIELD backflush_ind 
			IF (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD cust_code 
			END IF 

			IF fr_prodmfg.backflush_ind matches "[YN]" THEN 
				NEXT FIELD mps_ind 
			ELSE 
				ERROR "Backflush indicator must be either Y OR N"
				NEXT FIELD backflush_ind 
			END IF 

		BEFORE FIELD backflush_ind 
			IF fr_prodmfg.part_type_ind matches "[P]" THEN 
				LET fr_prodmfg.backflush_ind = "N" 
				NEXT FIELD mps_ind 
			END IF 

		BEFORE FIELD mps_ind 
			IF fr_prodmfg.part_type_ind matches "[R]" THEN 
				LET fr_prodmfg.mps_ind = "N" 
				LET fr_prodmfg.config_ind = "N" 
				LET fr_prodmfg.demand_fence_num = 0 
				LET fr_prodmfg.plan_fence_num = 0 
				NEXT FIELD yield_per 
			END IF 

		AFTER FIELD mps_ind 
			IF fr_prodmfg.part_type_ind matches "[P]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD cust_code 
			END IF 

			IF fr_prodmfg.mps_ind matches "[Y]" THEN 
				IF fr_prodmfg.part_type_ind matches "[R]" THEN 
					ERROR "M.P.S cannot be SET FOR non manufactured Item"
					NEXT FIELD mps_ind 
				END IF 
			ELSE 
				IF fr_prodmfg.mps_ind NOT matches "[YN]" THEN 
					ERROR "M.P.S Indicator must be either Y OR N"
					NEXT FIELD mps_ind 
				END IF 
			END IF 

		BEFORE FIELD config_ind 
			IF fr_prodmfg.part_type_ind matches "[MP]" THEN 
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
					ERROR "Cannot change TO configured - BOR exists"
					NEXT FIELD config_ind 
				END IF 
			END IF 

			IF fr_prodmfg.config_ind matches "[YN]" THEN 
				NEXT FIELD demand_fence_num 
			ELSE 
				ERROR "Config only must be either Y OR N"
				NEXT FIELD config_ind 
			END IF 

		AFTER FIELD demand_fence_num 
			IF fr_prodmfg.demand_fence_num < 0 THEN 
				ERROR "Demand fence must be greater than zero"
				NEXT FIELD demand_fence_num 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[MP]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD mps_ind 
			END IF 

		AFTER FIELD plan_fence_num 
			IF fr_prodmfg.plan_fence_num < 0 THEN 
				ERROR "Planning fence must be greater than zero"
				NEXT FIELD plan_fence_num 
			END IF 

			IF fr_prodmfg.plan_fence_num < fr_prodmfg.demand_fence_num THEN 
				ERROR "Planning fence must NOT be less than demand"
				NEXT FIELD plan_fence_num 
			END IF 

		AFTER FIELD yield_per 
			IF fr_prodmfg.part_type_ind matches "[PR]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD backflush_ind 
			END IF 

			IF fr_prodmfg.yield_per < 0 THEN 
				ERROR "Yield percent must be greater than zero"
				NEXT FIELD yield_per 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[P]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD backflush_ind 
			END IF 

		AFTER FIELD scrap_per 
			IF fr_prodmfg.scrap_per < 0 THEN 
				ERROR "Scrap percent must be greater than zero"
				NEXT FIELD scrap_per 
			END IF 

		BEFORE FIELD man_stk_con_qty 
			LET fr_prodmfg.man_stk_con_qty = 1 
			DISPLAY fr_prodmfg.man_stk_con_qty TO man_stk_con_qty 

		AFTER FIELD man_stk_con_qty 
			IF (fr_prodmfg.man_stk_con_qty IS null) 
			OR (fr_prodmfg.man_stk_con_qty < 0) THEN 
				ERROR "A valid value must be enter in this field"
				NEXT FIELD man_stk_con_qty 
			END IF 

		BEFORE FIELD man_uom_code 
			SELECT stock_uom_code 
			INTO fr_prodmfg.man_uom_code 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = fr_prodmfg.part_code 

			DISPLAY fr_prodmfg.man_uom_code TO man_uom_code 


		AFTER FIELD man_uom_code 
			IF NOT uom_exists(fr_prodmfg.man_uom_code) THEN 
				LET fr_prodmfg.man_uom_code = NULL 
				DISPLAY 
				fr_prodmfg.man_uom_code 
				TO man_uom_code 

				NEXT FIELD man_uom_code 
			END IF 


		BEFORE FIELD cust_code 
			IF fr_prodmfg.part_type_ind matches "[R]" 
			AND (fgl_lastkey() = fgl_keyval("up") 
			OR fgl_lastkey() = fgl_keyval("left")) THEN 
				NEXT FIELD man_stk_con_qty 
			END IF 

			IF fr_prodmfg.part_type_ind matches "[R]" THEN 
				NEXT FIELD backflush_ind 
			END IF 

		ON CHANGE cust_code
			IF (fr_prodmfg.cust_code IS NOT null) THEN 
				LET fr_prodmfg_lookup.cust_name =	lookup_customer(fr_prodmfg.cust_code) 
				DISPLAY fr_prodmfg_lookup.cust_name TO cust_name 
			END IF

		AFTER FIELD cust_code 
			IF (fr_prodmfg.cust_code IS NOT null) THEN 
				IF fr_prodmfg.part_type_ind matches "[R]" THEN 
					LET fr_prodmfg.cust_code = NULL 
				ELSE 
					LET fr_prodmfg_lookup.cust_name =	lookup_customer(fr_prodmfg.cust_code) 
					IF fr_prodmfg_lookup.cust_name IS NULL THEN 
						LET fr_prodmfg.cust_code = NULL 
						DISPLAY fr_prodmfg.cust_code TO cust_code 
						DISPLAY fr_prodmfg_lookup.cust_name TO cust_name 
						NEXT FIELD cust_code 
					END IF 
				END IF 

				DISPLAY fr_prodmfg.cust_code TO cust_code 
				DISPLAY fr_prodmfg_lookup.cust_name TO cust_name 
			END IF 

		AFTER INPUT 

			IF int_flag OR quit_flag THEN 
				LET quit_flag = false 
				LET int_flag = false 
				EXIT INPUT 
			END IF 

			IF fr_prodmfg.part_code IS NULL THEN 
				ERROR "A part code must be entered"
				NEXT FIELD part_code 
			ELSE 
				IF exists_prodmfg(fr_prodmfg.part_code) THEN 
					ERROR "Product already exists"
					NEXT FIELD part_code 
				END IF 
			END IF 

			LET fr_prodmfg_lookup.warehouse_name= 
			lookup_warehouse( fr_prodmfg.def_ware_code) 
			IF fr_prodmfg_lookup.warehouse_name IS NULL THEN 
				ERROR "Warehouse does NOT exist in the database"
				NEXT FIELD def_ware_code 
			END IF 

			IF fr_prodmfg.part_type_ind IS NULL THEN 
				ERROR "Invalid part type entered"
				NEXT FIELD part_type_ind 
			ELSE 
				IF fr_prodmfg.part_type_ind NOT matches "[GPRM]" THEN 
					 ERROR "Invalid part type entered"

					NEXT FIELD part_type_ind 
				END IF 
			END IF 

			IF fr_prodmfg.part_type_ind NOT matches "[P]" THEN 
				IF fr_prodmfg.man_uom_code IS NULL THEN 
					ERROR "Unit of measure must be entered"
					NEXT FIELD man_uom_code 
				ELSE 
					IF NOT uom_exists(fr_prodmfg.man_uom_code) THEN 
						ERROR "This unit of measure IS NOT on the database"
						NEXT FIELD man_uom_code 
					END IF 
				END IF 
			END IF 

		ON KEY (control-B) infield(part_code) 
					LET fr_prodmfg.part_code=show_item(glob_rec_kandoouser.cmpy_code) 
					#DISPLAY fr_prodmfg.part_code TO part_code 
		ON KEY (control-B) infield(man_uom_code) 
					LET fr_prodmfg.man_uom_code=show_uom(glob_rec_kandoouser.cmpy_code) 
					#DISPLAY fr_prodmfg.man_uom_code TO man_uom_code 
		ON KEY (control-B) infield(cust_code) 
					LET fr_prodmfg.cust_code= show_cust(glob_rec_kandoouser.cmpy_code,fr_prodmfg.cust_code) 
					#DISPLAY fr_prodmfg.cust_code TO cust_code 
		ON KEY (control-B) infield(def_ware_code) 
					LET fr_prodmfg.def_ware_code=show_ware_part_code(glob_rec_kandoouser.cmpy_code,fr_prodmfg.part_code) 
					#DISPLAY fr_prodmfg.def_ware_code TO def_ware_code 
		ON KEY (interrupt) 
			LET fv_insert_ok = false 
			EXIT INPUT 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_insert_ok = false 
		ERROR "add aborted"
	ELSE 
		BEGIN WORK 
			LET fr_prodmfg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET fr_prodmfg.last_change_date = today 
			LET fr_prodmfg.last_user_text = glob_rec_kandoouser.sign_on_code 
			LET fr_prodmfg.last_program_text = "M11" 

			WHENEVER ERROR CONTINUE
				INSERT INTO prodmfg VALUES (fr_prodmfg.*) 
			WHENEVER ERROR STOP
			IF status <> 0 THEN 
				ERROR "Trouble saving data, data NOT saved"
				ROLLBACK WORK 
			ELSE 
				MESSAGE "Item added successfully" 
			COMMIT WORK 
			LET gr_prodmfg.* = fr_prodmfg.* 
			LET fv_insert_ok = true 
		END IF 
	END IF 

END FUNCTION 

#-----------------------------------------------------------------------------#
#  FUNCTION TO expand out the part type code given in the prodmfg RECORD      #
#-----------------------------------------------------------------------------#

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
			LET fv_description = "Raw Material (Purchased)" 
	END CASE 

	RETURN fv_description 
END FUNCTION 

#-----------------------------------------------------------------------------#
#  FUNCTION TO lookup the description FOR an item code                        #
#-----------------------------------------------------------------------------#

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

#-----------------------------------------------------------------------------#
#  FUNCTION TO lookup a customer AND RETURN thier name                        #
#-----------------------------------------------------------------------------#

FUNCTION lookup_customer(fp_customer) 

	DEFINE 
	fp_customer LIKE customer.cust_code, 
	fv_customer_name LIKE customer.name_text 


	SELECT customer.name_text 
	INTO fv_customer_name 
	FROM customer 
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = fp_customer 

	IF status <> 0 THEN 
		LET fv_customer_name = NULL 
	END IF 

	RETURN fv_customer_name 
END FUNCTION 

#-----------------------------------------------------------------------------#
#  FUNCTION TO lookup a warehouse AND RETURN its description                  #
#-----------------------------------------------------------------------------#

FUNCTION lookup_warehouse(fp_warehouse_code) 

	DEFINE 
	fp_warehouse_code LIKE warehouse.ware_code, 
	fv_warehouse_desc LIKE warehouse.desc_text 

	SELECT warehouse.desc_text 
	INTO fv_warehouse_desc 
	FROM warehouse 
	WHERE warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND warehouse.ware_code = fp_warehouse_code 

	IF status <> 0 THEN 
		LET fv_warehouse_desc = NULL 
	END IF 

	RETURN fv_warehouse_desc 
END FUNCTION 

#-----------------------------------------------------------------------------#
#  FUNCTION TO see IF the specified prodmfg already exists                    #
#-----------------------------------------------------------------------------#

FUNCTION exists_prodmfg(fp_part_code) 

	DEFINE 
	fp_part_code LIKE prodmfg.part_code 

	SELECT * 
	FROM prodmfg 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fp_part_code 

	RETURN (sqlca.sqlcode=0) 
END FUNCTION 

#-----------------------------------------------------------------------------#
#  FUNCTION TO check TO see IF the unit of meassure specifid actually exists  #
#-----------------------------------------------------------------------------#

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
		ERROR "Not allowed duplicate units of measure in the database"
		LET fv_uom_count = 0 
	ELSE 
		IF fv_uom_count = 0 THEN 
			ERROR "This unit of measure does NOT exist in the database"
		END IF 
	END IF 

	RETURN fv_uom_count 

END FUNCTION