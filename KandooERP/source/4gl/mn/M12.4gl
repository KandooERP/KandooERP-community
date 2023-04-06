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

	Source code beautified by beautify.pl on 2020-01-02 17:31:16	$Id: $
}


# Purpose - Manufacturing Product Inquiry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "M_MN_GLOBALS.4gl" 
GLOBALS "M12_GLOBALS.4gl" 

DEFINE 
gr_prodmfg RECORD LIKE prodmfg.*, 
gr_prodmfg_lookup RECORD 
	company_name CHAR(30), 
	part_description CHAR(30), 
	type_description CHAR(12), 
	cust_name CHAR(30), 
	warehouse_name CHAR(30) 
END RECORD 

MAIN 

	#Initial UI Init
	CALL setModuleId("M12") -- albo 
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
	fv_data_exists SMALLINT 

	OPEN WINDOW w0_prodmfg with FORM "M117" 
	CALL  windecoration_m("M117") -- albo kd-762 

	CALL kandoomenu("M", 101) # item master inquiry 
	RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text 
			LET fv_data_exists = query_prodmfg() 
			IF fv_data_exists THEN 
				CALL get_prodmfg("F") 
				CALL display_prodmfg() 
				NEXT option pr_menunames.cmd2_code # "Next" 
			ELSE 
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text 
			IF fv_data_exists THEN 
				CALL get_prodmfg("N") 
				CALL display_prodmfg() 
			ELSE 
				LET msgresp = kandoomsg("M",9554,"") 
				# ERROR "Must query first before viewing Products(manufacturing)
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text 
			IF fv_data_exists THEN 
				CALL get_prodmfg("P") 
				CALL display_prodmfg() 
			ELSE 
				LET msgresp = kandoomsg("M",9554,"") 
				# ERROR "Must query first before viewing Products(manufacturing)
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text 
			IF fv_data_exists THEN 
				CALL get_prodmfg("F") 
				CALL display_prodmfg() 
			ELSE 
				LET msgresp = kandoomsg("M",9554,"") 
				# ERROR "Must query first before viewing Products(manufacturing)
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text 
			IF fv_data_exists THEN 
				CALL get_prodmfg("L") 
				CALL display_prodmfg() 
			ELSE 
				LET msgresp = kandoomsg("M",9554,"") 
				# ERROR "Must query first before viewing Products(manufacturing)
				NEXT option pr_menunames.cmd1_code # "Query" 
			END IF 

		COMMAND pr_menunames.cmd6_code pr_menunames.cmd6_text 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW w0_prodmfg 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO perform a query by example on the item master SCREEN          #
#----------------------------------------------------------------------------#

FUNCTION query_prodmfg() 

	DEFINE 
	fv_where_part CHAR(400), 
	fv_query_text CHAR(500), 
	fv_query_ok SMALLINT, 
	fv_prodmfg RECORD LIKE prodmfg.* 

	LET fv_query_ok = true 
	CLEAR FORM 
	LET msgresp = kandoomsg("M",1505,"") 
	# MESSAGE "ESC TO accept, DEL TO Exit"

	CONSTRUCT fv_where_part 
	ON part_code, 
	part_type_ind, 
	def_ware_code, 
	man_uom_code, 
	man_stk_con_qty, 
	cust_code, 
	backflush_ind, 
	mps_ind, 
	config_ind, 
	demand_fence_num, 
	plan_fence_num, 
	yield_per, 
	scrap_per, 
	draw_revsn_text, 
	revsn_date 
	FROM part_code, 
	part_type_ind, 
	def_ware_code, 
	man_uom_code, 
	man_stk_con_qty, 
	cust_code, 
	backflush_ind, 
	mps_ind, 
	config_ind, 
	demand_fence_num, 
	plan_fence_num, 
	yield_per, 
	scrap_per, 
	draw_revsn_text, 
	revsn_date 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF (int_flag 
	OR quit_flag) THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET fv_query_ok = false 

		LET msgresp = kandoomsg("M",9556,"") 
		# ERROR "No detail satisfied the selection criteria"
	ELSE 
		LET fv_query_text = "SELECT prodmfg.* ", 
		"FROM prodmfg ", 
		"WHERE ",fv_where_part clipped," AND ", 
		"prodmfg.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"ORDER BY prodmfg.cmpy_code,prodmfg.part_code" 

		PREPARE statement1 FROM fv_query_text 
		DECLARE s_sprodmfg SCROLL CURSOR FOR statement1 

		OPEN s_sprodmfg 
		FETCH FIRST s_sprodmfg INTO fv_prodmfg.* 

		IF status = notfound THEN 
			LET msgresp = kandoomsg("M",9556,"") 
			LET fv_query_ok = false 
		END IF 
	END IF 

	RETURN fv_query_ok 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO get an item master RECORD FROM the database                   #
#----------------------------------------------------------------------------#

FUNCTION get_prodmfg(fp_option) 

	DEFINE 
	fp_option CHAR(1) 

	CASE 
		WHEN fp_option = "C" 
			FETCH CURRENT s_sprodmfg INTO gr_prodmfg.* 
		WHEN fp_option = "F" 
			FETCH FIRST s_sprodmfg INTO gr_prodmfg.* 
		WHEN fp_option = "L" 
			FETCH LAST s_sprodmfg INTO gr_prodmfg.* 
		WHEN fp_option = "N" 
			FETCH NEXT s_sprodmfg INTO gr_prodmfg.* 
		WHEN fp_option = "P" 
			FETCH previous s_sprodmfg INTO gr_prodmfg.* 
	END CASE 

	IF status <> 0 THEN 
		LET msgresp =kandoomsg("M",9530,"") 
	ELSE 
		LET gr_prodmfg_lookup.type_description = 
		lookup_type_code(gr_prodmfg.part_type_ind) 
		LET gr_prodmfg_lookup.warehouse_name = 
		lookup_warehouse(gr_prodmfg.def_ware_code) 
		LET gr_prodmfg_lookup.cust_name = 
		lookup_customer(gr_prodmfg.cust_code) 

		SELECT desc_text 
		INTO gr_prodmfg_lookup.part_description 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = gr_prodmfg.part_code 
	END IF 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO DISPLAY a prodmfg RECORD on the SCREEN                        #
#----------------------------------------------------------------------------#

FUNCTION display_prodmfg() 

	DISPLAY gr_prodmfg.part_code, gr_prodmfg.part_type_ind, 
	gr_prodmfg.def_ware_code, gr_prodmfg.man_uom_code, 
	gr_prodmfg.man_stk_con_qty, gr_prodmfg.cust_code, 
	gr_prodmfg.backflush_ind, gr_prodmfg.mps_ind, 
	gr_prodmfg.config_ind, gr_prodmfg.demand_fence_num, 
	gr_prodmfg.plan_fence_num, gr_prodmfg.yield_per, 
	gr_prodmfg.scrap_per, gr_prodmfg_lookup.part_description, 
	gr_prodmfg_lookup.type_description, gr_prodmfg_lookup.cust_name, 
	gr_prodmfg_lookup.warehouse_name, gr_prodmfg.draw_revsn_text, 
	gr_prodmfg.revsn_date 
	TO part_code, part_type_ind, 
	def_ware_code, man_uom_code, 
	man_stk_con_qty, cust_code, 
	backflush_ind, mps_ind, 
	config_ind, demand_fence_num, 
	plan_fence_num, yield_per, 
	scrap_per, part_description, 
	type_description, cust_name, 
	warehouse_name, draw_revsn_text, 
	revsn_date 

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
			LET fv_description = "Manufactured" 
		WHEN fp_type = "P" 
			LET fv_description = "Phantom" 
		WHEN fp_type = "R" 
			LET fv_description = "Raw Materials" 
	END CASE 

	RETURN fv_description 
END FUNCTION 

#----------------------------------------------------------------------------#
#  FUNCTION TO lookup a customer AND RETURN thier name                       #
#----------------------------------------------------------------------------#

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

#----------------------------------------------------------------------------#
#  FUNCTION TO lookup a warehouse AND RETURN its description                 #
#----------------------------------------------------------------------------#

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
