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

	Source code beautified by beautify.pl on 2020-01-03 09:12:44	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IT3 : Updates the selected Stocktake Cycle + Warehouse
#
#FUNCTION select_cycle()
#         SELECT the Stock Take Cycle details TO DISPLAY cycles
#FUNCTION scan_cycle()
#         Scan the Stock Take cycle numbers TO SELECT a stock take TO
#         work with
#FUNCTION ringmenu_stocktake(lv_cycle_num,lv_ware_code)
#         Ring menu with stocktake OPTIONS
#FUNCTION INITIALIZE_stocktake()
#         INITIALIZE the global stocktake array
#FUNCTION select_stocktake(lv_cycle_num,lv_ware_code)
#         SELECT the stocktake details by entering criteria
#FUNCTION modify_stocktake(lv_update_flag, lv_idx)
#         Modify the selected stocktake details
#FUNCTION update_stocktake(lv_idx, lv_source)
#         Update the stocktake details
#FUNCTION insert_stocktake(lv_idx)
#         Functionality TO INSERT a new stocktake item
#FUNCTION delete_stocktake(lv_idx)
#         Functionality TO delete a stocktake item
#FUNCTION display_stocktake()
#         DISPLAY the stocktake item details on the SCREEN
#FUNCTION display_footer(lv_idx,lv_showstktake)
#         DISPLAY the stocktake item details on footer of SCREEN

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS 
	DEFINE 

	err_message CHAR(60), 
	where_text1 CHAR(100), 
	where_text2 CHAR(100), 
	where_text3 CHAR(400), 
	query_text CHAR(1000), 
	pr_wind_text CHAR(30), 
	gr_stktake RECORD LIKE stktake.*, 
	gr_ware_code LIKE stktakedetl.ware_code, 
	ga_stocktake array[5000] OF RECORD 
		bin_text LIKE stktakedetl.bin_text, 
		part_code LIKE stktakedetl.part_code, 
		maingrp_code LIKE stktakedetl.maingrp_code, 
		prodgrp_code LIKE stktakedetl.prodgrp_code, 
		count_qty LIKE stktakedetl.count_qty, 
		total_qty FLOAT, 
		sell_uom_code LIKE product.sell_uom_code, 
		onhand_qty LIKE stktakedetl.onhand_qty 
	END RECORD, 
	gv_array_size INTEGER 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE 
	pr_cycle_num LIKE stktake.cycle_num 
	#Initial UI Init
	CALL setModuleId("IT3") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW wi644 with FORM "I644" 
	 CALL windecoration_i("I644") -- albo kd-758 

	LET gv_array_size = 5000 
	SELECT unique 1 FROM stktake 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND status_ind = "1" 
	IF status = notfound THEN 
		LET msgresp=kandoomsg("I",7057,"") 
		#7057 No current Stock Take exist - Refer IT1
		EXIT program 
	END IF 
	WHILE select_cycle() 
		CALL scan_cycle() 
	END WHILE 
	CLOSE WINDOW wi644 
END MAIN 
#
# SELECT the Stocktake Cycle TO Modify
#
FUNCTION select_cycle() 

	CLEAR FORM 
	LET msgresp = kandoomsg("U",1001,"") 
	#1001 Enter selection criteria - OK TO Continue.
	CONSTRUCT BY NAME where_text1 ON cycle_num, 
	desc_text, 
	start_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT3","construct-cycle_num-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("U",1002,"") 
		#1002 Searching database;  Please wait.
		LET query_text = "SELECT * FROM stktake ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND status_ind = '1' ", 
		"AND ", where_text1 clipped," ", 
		"ORDER BY cycle_num,start_date" 
		PREPARE s_stktake FROM query_text 
		DECLARE c_stktake CURSOR FOR s_stktake 
		RETURN true 
	END IF 
END FUNCTION 
#
# Scan the Stocktake Table FOR details TO display
#
FUNCTION scan_cycle() 
	DEFINE 
	la_stktake array[400] OF RECORD 
		scroll_flag CHAR(1), 
		cycle_num LIKE stktake.cycle_num, 
		desc_text LIKE stktake.desc_text, 
		start_date LIKE stktake.start_date 
	END RECORD, 
	lr_stktake RECORD LIKE stktake.*, 
	lv_ware_code LIKE stktakedetl.ware_code, 
	lv_count_ware, 
	lv_scrn, lv_idx SMALLINT 

	FOR lv_idx = 1 TO gv_array_size 
		INITIALIZE ga_stocktake[lv_idx].* TO NULL 
	END FOR 
	LET lv_idx = 0 
	FOREACH c_stktake INTO lr_stktake.* 
		LET lv_idx = lv_idx + 1 
		LET la_stktake[lv_idx].cycle_num = lr_stktake.cycle_num 
		LET la_stktake[lv_idx].desc_text = lr_stktake.desc_text 
		LET la_stktake[lv_idx].start_date = lr_stktake.start_date 
		IF lv_idx = 100 THEN 
			LET msgresp = kandoomsg("U",6100,lv_idx) 
			# First 100 records selected only.  More may ...
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,lv_idx) 
	#9113 idx records selected
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count (lv_idx) 
	LET msgresp = kandoomsg("I",9504,"") 
	#9053 Press RETURN TO edit stock take cycle counts
	INPUT ARRAY la_stktake WITHOUT DEFAULTS FROM sr_stktake.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT3","input-arr-la_stktake-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE FIELD scroll_flag 
			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 
			DISPLAY la_stktake[lv_idx].* TO sr_stktake[lv_scrn].* 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF la_stktake[lv_idx+1].cycle_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD desc_text 
			IF la_stktake[lv_idx].cycle_num IS NOT NULL THEN 
				SELECT count (unique ware_code) 
				INTO lv_count_ware 
				FROM stktakedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cycle_num = la_stktake[lv_idx].cycle_num 
				CASE lv_count_ware 
					WHEN 0 
						LET lv_ware_code = " " 
					WHEN 1 
						SELECT unique(ware_code) 
						INTO lv_ware_code 
						FROM stktakedetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = la_stktake[lv_idx].cycle_num 
					OTHERWISE 
						LET lv_ware_code = "*" 
				END CASE 
				CALL ringmenu_stocktake(la_stktake[lv_idx].cycle_num, 
				lv_ware_code) 
				OPTIONS INSERT KEY f36, 
				DELETE KEY f36 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY la_stktake[lv_idx].* 
			TO sr_stktake[lv_scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
#
#  Ring Menu Stocktake - Ring menu that controls the stocktake procedures
#
FUNCTION ringmenu_stocktake(lv_cycle_num, lv_ware_code) 
	DEFINE 
	lv_cycle_num LIKE stktake.cycle_num, 
	lv_ware_code LIKE stktakedetl.ware_code, 
	lv_idx SMALLINT 

	OPEN WINDOW i657 with FORM "I657" 
	 CALL windecoration_i("I657") -- albo kd-758 
	###-Prepare SCREEN with appropriate VALUES-###
	CALL initialize_stocktake(0) 
	###-Fill a global variable-###
	SELECT * INTO gr_stktake.* FROM stktake 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = lv_cycle_num 
	IF select_stocktake(lv_ware_code) THEN 
		LET lv_idx = display_stocktake() 
		MENU " Stocktake" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","IT3","menu-Stocktake-1") -- albo kd-505 
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
			COMMAND "Count" " Enter stocktake count details " 
				CALL initialize_stocktake(1) 
				LET lv_idx = modify_stocktake(1, lv_idx) 
			COMMAND "Total" " Enter stocktake total details " 
				CALL initialize_stocktake(1) 
				LET lv_idx = modify_stocktake(0, lv_idx) 
			COMMAND "Report" " Report on the stock take details" 
				CALL run_prog("IT4","","","","") 
			COMMAND KEY(interrupt,E)"Exit" " RETURN TO scan stock take SCREEN" 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT MENU 
			COMMAND KEY (control-w) 
				CALL kandoohelp("") 
		END MENU 
	END IF 
	CLOSE WINDOW i657 
END FUNCTION 
#
# INITIALIZE Stocktake ARRAY - Clear all the ARRAY rows
#
FUNCTION initialize_stocktake(lv_count_only) 
	DEFINE 
	lv_count_only, 
	lv_counter SMALLINT 

	FOR lv_counter = 1 TO gv_array_size 
		IF ga_stocktake[lv_counter].part_code IS NOT NULL THEN 
			IF lv_count_only THEN 
				LET ga_stocktake[lv_counter].count_qty = 0 
			ELSE 
				INITIALIZE ga_stocktake[lv_counter].* TO NULL 
			END IF 
		ELSE 
			EXIT FOR 
		END IF 
	END FOR 
END FUNCTION 
#
# SELECT Stock - Enter selection criteria FOR the stocktake cycle
#
FUNCTION select_stocktake(lv_ware_code) 
	DEFINE 
	lv_ware_code, 
	lv_old_ware LIKE stktakedetl.ware_code, 
	lr_stktake RECORD LIKE stktake.*, 
	lr_stktakedetl RECORD LIKE stktakedetl.*, 
	lr_userlocn RECORD LIKE userlocn.*, 
	lr_location RECORD LIKE location.*, 
	lr_company RECORD LIKE company.*, 
	lr_warehouse RECORD LIKE warehouse.*, 
	order_text CHAR(100), 
	pr_wind_text CHAR(50) 

	CLEAR FORM 
	###-Collect the cycle description AND warehouse code-###
	DISPLAY gr_stktake.cycle_num, gr_stktake.desc_text 
	TO stktakedetl.cycle_num, stktake.desc_text 

	IF (lv_ware_code = " ") OR (lv_ware_code = "*") THEN 
		LET lv_old_ware = lv_ware_code 
		LET lv_ware_code = NULL 
		###-Need TO SELECT a stocktake warehouse TO work with-###
		LET msgresp=kandoomsg("U",1020,"Warehouse Code") 
		#1020 Enter Warehouse Code Details;  OK TO Continue.
		INPUT lv_ware_code WITHOUT DEFAULTS FROM stktakedetl.ware_code 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IT3","input-lv_ware_code-1") -- albo kd-505 
			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 
			ON KEY (control-b) 
				CASE 
					WHEN infield (ware_code) 
						LET pr_wind_text = show_ware(glob_rec_kandoouser.cmpy_code) 
						IF pr_wind_text IS NOT NULL THEN 
							LET lv_ware_code = pr_wind_text 
							DISPLAY lv_ware_code 
							TO ware_code 

						END IF 
						NEXT FIELD ware_code 
				END CASE 
			AFTER FIELD ware_code 
				IF lv_ware_code IS NOT NULL THEN 
					SELECT unique 1 FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = lv_ware_code 
					IF status = notfound THEN 
						LET msgresp=kandoomsg("I",9506,"") 
						#9505 Warehouse code does NOT exist
						NEXT FIELD NEXT 
					ELSE 
						SELECT unique 1 FROM stktakedetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cycle_num = gr_stktake.cycle_num 
						AND ware_code = lv_ware_code 
						IF status = notfound THEN 
							IF lv_old_ware != " " THEN 
								ERROR "This stock take cycle does NOT cover this warehouse" 
								NEXT FIELD NEXT 
							END IF 
						END IF 
					END IF 
				ELSE 
					LET msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD NEXT 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 
	END IF 
	SELECT * INTO lr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = lv_ware_code 
	DISPLAY lv_ware_code,lr_warehouse.desc_text 
	TO stktakedetl.ware_code,ware_text 

	LET gr_ware_code = lv_ware_code 
	LET msgresp=kandoomsg("U",1020,"Stocktake Bin/Product") 
	#1020 Enter Stocktake Bin/Product Details - Press ESC TO continue
	CONSTRUCT BY NAME where_text3 ON stktakedetl.bin_text, 
	stktakedetl.part_code, 
	stktakedetl.maingrp_code, 
	stktakedetl.prodgrp_code, 
	stktakedetl.count_qty 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IT3","construct-stktakedetl-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		SELECT * INTO lr_company.* FROM company 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT * INTO lr_userlocn.* FROM userlocn 
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		SELECT * INTO lr_location.* FROM location 
		WHERE locn_code = lr_userlocn.locn_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status = notfound 
		OR lr_location.stocktake_ind = "B" THEN 
			LET order_text = "stktakedetl.bin_text, stktakedetl.part_code" 
		ELSE 
			LET order_text = "stktakedetl.part_code, stktakedetl.bin_text" 
		END IF 
		LET query_text ="SELECT stktakedetl.rowid, stktakedetl.* ", 
		"FROM stktakedetl,stktake ", 
		"WHERE stktakedetl.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND stktake.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND stktake.cycle_num = stktakedetl.cycle_num ", 
		"AND stktake.status_ind = '1' ", ###-active stocktake 
		"AND stktake.cycle_num = '",gr_stktake.cycle_num, "'", 
		"AND stktakedetl.ware_code = '", gr_ware_code, "' ", 
		"AND ", where_text3 clipped," ", 
		"ORDER BY cycle_num,ware_code, ", order_text clipped 
		PREPARE s_stocktake FROM query_text 
		DECLARE c_stocktake CURSOR FOR s_stocktake 
		RETURN true 
	END IF 
END FUNCTION 
#
# Modify Stocktake - Modify the stocktake details either Count OR Total
#
FUNCTION modify_stocktake(lv_update_flag, lv_idx) 
	DEFINE 
	lv_update_flag, 
	lv_idx, lv_idx2 SMALLINT, 
	pr_stktakedetl RECORD LIKE stktakedetl.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	lr_product RECORD LIKE product.*, 
	lr_stocktake RECORD 
		bin_text LIKE stktakedetl.bin_text, 
		part_code LIKE stktakedetl.part_code, 
		maingrp_code LIKE stktakedetl.maingrp_code, 
		prodgrp_code LIKE stktakedetl.prodgrp_code, 
		count_qty LIKE stktakedetl.count_qty, 
		total_qty FLOAT, 
		sell_uom_code LIKE product.sell_uom_code, 
		onhand_qty LIKE stktakedetl.onhand_qty 
	END RECORD, 
	pr_bin_text LIKE stktakedetl.bin_text, 
	pr_part_code LIKE stktakedetl.part_code, 
	pr_onhand_qty LIKE stktakedetl.onhand_qty, 
	lv_mode CHAR(6), 
	lv_max, 
	pr_counter, 
	pr_invalid_entry, # SET TO true in CASE user presses CANCEL KEY 
	lv_scrn SMALLINT 

	LET lv_mode = "UPDATE" 
	CALL set_count(lv_idx) 
	LET msgresp = kandoomsg("U",1004,"") 
	#1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	###########################################################################
	# This INPUT ARRAY will DISPLAY the onhand quantity as a one character
	# field, this causes * TO be displayed. It will be hidden in the non-<Suse>
	# AND <Suse> character mode by displaying in color black, in gui the asterisk
	# will be displayed. This was implemented as a fix TO avoid the rewriting
	# of the ARRAY handling.
	###########################################################################

	INPUT ARRAY ga_stocktake WITHOUT DEFAULTS FROM sa_stocktake.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IT3","input-arr-ga_stocktake-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET lv_idx = arr_curr() 
			LET lv_scrn = scr_line() 
			INITIALIZE lr_stocktake.* TO NULL 
			LET lr_stocktake.* = ga_stocktake[lv_idx].* 
			DISPLAY ga_stocktake[lv_idx].* 
			TO sa_stocktake[lv_scrn].* 
			###-Also DISPLAY the SCREEN footer -###
			IF ga_stocktake[lv_idx].part_code IS NOT NULL THEN 
				CALL display_footer(lv_idx,1) 
				CASE lv_mode 
					WHEN "UPDATE" 
						IF lv_update_flag THEN 
							NEXT FIELD count_qty 
						ELSE 
							NEXT FIELD total_qty 
						END IF 
					WHEN "ADD" 
						IF arr_count() = 5000 THEN 
							IF lv_update_flag THEN 
								NEXT FIELD count_qty 
							ELSE 
								NEXT FIELD total_qty 
							END IF 
						END IF 
						NEXT FIELD bin_text 
				END CASE 
			END IF 
		BEFORE INSERT 
			LET pr_invalid_entry = false 
			LET ga_stocktake[lv_idx].count_qty = 0 
			LET ga_stocktake[lv_idx].total_qty = 0 
		AFTER INSERT 
			LET msgresp=kandoomsg("U",1020,"Stocktake Row") 
			#1020 Enter Stocktake Row Details;  OK TO Continue.
			INITIALIZE lr_stocktake.* TO NULL 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			CALL display_footer(0,0) 
		BEFORE FIELD bin_text 
			LET pr_invalid_entry = true 
		AFTER FIELD bin_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					NEXT FIELD part_code 
				OTHERWISE 
					NEXT FIELD bin_text 
			END CASE 
		AFTER FIELD part_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF ga_stocktake[lv_idx].part_code IS NULL THEN 
						LET msgresp=kandoomsg("I",9013,"") 
						#9013 Product Code must be Entered.
						LET pr_invalid_entry = true 
						NEXT FIELD part_code 
					ELSE 
						SELECT * INTO lr_product.* FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = ga_stocktake[lv_idx].part_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("I",9010,"") 
							#9010 This IS a non stocked product AT this warehouse
							LET pr_invalid_entry = true 
							NEXT FIELD part_code 
						END IF 
						###-verify the product STATUS-###
						SELECT * INTO lr_prodstatus.* 
						FROM prodstatus 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = gr_ware_code 
						AND part_code = ga_stocktake[lv_idx].part_code 
						AND status_ind != '3' 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("I",9222,"") 
							#9222 This IS a non stocked product AT this warehouse...
							LET pr_invalid_entry = true 
							NEXT FIELD part_code 
						END IF 
						IF lr_prodstatus.stocked_flag != "Y" THEN 
							LET msgresp=kandoomsg("I",9222,"") 
							#9222 This IS a non stocked product AT this warehouse
							LET pr_invalid_entry = true 
							NEXT FIELD part_code 
						END IF 
						### verify the product IS in the stock take cycle
						SELECT unique(1) INTO pr_stktakedetl.* 
						FROM stktakedetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = ga_stocktake[lv_idx].part_code 
						AND cycle_num = gr_stktake.cycle_num 
						IF status = notfound THEN 
							LET msgresp = kandoomsg("I",9544,"") 
							#9544 This product does NOT exist within the ...
							LET pr_invalid_entry = true 
							NEXT FIELD part_code 
						END IF 
						CALL display_footer(lv_idx,0) 
						LET ga_stocktake[lv_idx].maingrp_code = 
						lr_product.maingrp_code 
						LET ga_stocktake[lv_idx].prodgrp_code = 
						lr_product.prodgrp_code 
						LET ga_stocktake[lv_idx].sell_uom_code = 
						lr_product.sell_uom_code 
						DISPLAY ga_stocktake[lv_idx].* 
						TO sa_stocktake[lv_scrn].* 
						### verify the comb of part_code + bin_text
						### within database
						IF ga_stocktake[lv_idx].bin_text IS NULL THEN 
							SELECT unique(1) INTO pr_stktakedetl.* FROM stktakedetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = gr_ware_code 
							AND part_code = ga_stocktake[lv_idx].part_code 
							AND (bin_text IS NULL 
							OR bin_text = " ") 
							AND cycle_num = gr_stktake.cycle_num 
						ELSE 
							SELECT unique(1) INTO pr_stktakedetl.* FROM stktakedetl 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = gr_ware_code 
							AND part_code = ga_stocktake[lv_idx].part_code 
							AND bin_text = ga_stocktake[lv_idx].bin_text 
							AND cycle_num = gr_stktake.cycle_num 
						END IF 
						IF status <> notfound THEN 
							LET msgresp=kandoomsg("I",9224,"") 
							#9224 A count FOR this part/warehouse/location already
							DISPLAY ga_stocktake[lv_idx].* 
							TO sa_stocktake[lv_scrn].* 
							LET pr_invalid_entry = true 
							NEXT FIELD bin_text 
						END IF 
						LET pr_invalid_entry = false 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD part_code 
			END CASE 
		BEFORE FIELD count_qty 
			CASE lv_mode 
				WHEN "UPDATE" 
					LET lv_scrn = scr_line() 
					DISPLAY ga_stocktake[lv_idx].* 
					TO sa_stocktake[lv_scrn].* 
					IF NOT lv_update_flag THEN 
						NEXT FIELD total_qty 
					END IF 
					LET lr_stocktake.* = ga_stocktake[lv_idx].* 
				WHEN "ADD" 
					IF ga_stocktake[lv_idx].count_qty IS NULL THEN 
						LET ga_stocktake[lv_idx].count_qty = 0 
					END IF 
					IF ga_stocktake[lv_idx].total_qty IS NULL THEN 
						LET ga_stocktake[lv_idx].total_qty = 0 
					END IF 
			END CASE 
		AFTER FIELD count_qty 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF ga_stocktake[lv_idx].count_qty IS NULL THEN 
						LET ga_stocktake[lv_idx].count_qty = lr_stocktake.count_qty 
						NEXT FIELD count_qty 
					ELSE 
						CASE lv_mode 
							WHEN "UPDATE" 
								IF ga_stocktake[lv_idx].count_qty != 
								lr_stocktake.count_qty 
								THEN 
									IF (ga_stocktake[lv_idx].count_qty < 0) AND 
									((ga_stocktake[lv_idx].count_qty*-1)> 
									ga_stocktake[lv_idx].total_qty) 
									THEN 
										LET msgresp = kandoomsg("I",9546,"") 
										#9546 The adjustment value will cause the ...
										NEXT FIELD count_qty 
									END IF 
									LET ga_stocktake[lv_idx].total_qty = 
									update_stocktake(lv_idx, 
									"C", 
									lr_stocktake.count_qty) 
									DISPLAY ga_stocktake[lv_idx].* 
									TO sa_stocktake[lv_scrn].* 
									OPTIONS INSERT KEY f1, 
									DELETE KEY f36 
								END IF 
								IF (fgl_lastkey() = fgl_keyval("down") OR 
								fgl_lastkey() = fgl_keyval("right") OR 
								fgl_lastkey() = fgl_keyval("tab") OR 
								fgl_lastkey() = fgl_keyval("RETURN")) 
								THEN 
									IF lv_idx >= gv_array_size THEN 
										LET msgresp=kandoomsg("U",3513,"") 
										#3513 There no more rows...
										LET lr_stocktake.count_qty = 
										ga_stocktake[lv_idx].count_qty 
										CALL display_footer(lv_idx,1) 
										NEXT FIELD count_qty 
									END IF 
									IF ga_stocktake[lv_idx+1].part_code IS NULL 
									OR arr_curr() >= arr_count() THEN 
										LET msgresp=kandoomsg("U",3513,"") 
										#3513 There no more rows...
										LET lr_stocktake.count_qty = 
										ga_stocktake[lv_idx].count_qty 
										CALL display_footer(lv_idx,1) 
										NEXT FIELD count_qty 
									END IF 
								END IF 
							WHEN "ADD" 
								LET ga_stocktake[lv_idx].total_qty = 
								insert_stocktake(lv_idx) 
								DISPLAY ga_stocktake[lv_idx].* 
								TO sa_stocktake[lv_scrn].* 
								LET msgresp = kandoomsg("U",1004,"") 
								#1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"
								OPTIONS INSERT KEY f1, 
								DELETE KEY f36 
								LET lv_mode = "UPDATE" 
								IF lv_update_flag THEN 
									#NEXT FIELD sell_uom_code
								ELSE 
									NEXT FIELD total_qty 
								END IF 
						END CASE 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("nextpage") 
					IF ga_stocktake[lv_idx+10].part_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("U",3513,"") 
						#3513 There no more rows...
						NEXT FIELD count_qty 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("prevpage") 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("INSERT") 
					LET lv_mode = "ADD" 
				OTHERWISE 
					NEXT FIELD count_qty 
			END CASE 
		BEFORE FIELD total_qty 
			IF lv_update_flag THEN 
				NEXT FIELD sell_uom_code 
			END IF 
			LET lv_scrn = scr_line() 
			DISPLAY ga_stocktake[lv_idx].* 
			TO sa_stocktake[lv_scrn].* 
		AFTER FIELD total_qty 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("up") 
					IF ga_stocktake[lv_idx].total_qty IS NULL THEN 
						LET ga_stocktake[lv_idx].total_qty = lr_stocktake.total_qty 
						NEXT FIELD total_qty 
					ELSE 
						IF lr_stocktake.total_qty != ga_stocktake[lv_idx].total_qty 
						THEN 
							LET ga_stocktake[lv_idx].total_qty = 
							update_stocktake(lv_idx, "T",0) 
							LET lr_stocktake.* = ga_stocktake[lv_idx].* 
							DISPLAY ga_stocktake[lv_idx].* 
							TO sa_stocktake[lv_scrn].* 
							OPTIONS INSERT KEY f1, 
							DELETE KEY f36 
						END IF 
						IF (fgl_lastkey() = fgl_keyval("down") OR 
						fgl_lastkey() = fgl_keyval("right") OR 
						fgl_lastkey() = fgl_keyval("tab") OR 
						fgl_lastkey() = fgl_keyval("RETURN")) 
						THEN 
							IF ga_stocktake[lv_idx+1].part_code IS NULL 
							OR arr_curr() >= arr_count() THEN 
								LET msgresp=kandoomsg("U",3513,"") 
								#3513 There no more rows...
								CALL display_footer(lv_idx,1) 
								NEXT FIELD total_qty 
							END IF 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("nextpage") 
					IF ga_stocktake[lv_idx+10].part_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET msgresp=kandoomsg("U",3513,"") 
						#3513 There no more rows...
						NEXT FIELD total_qty 
					END IF 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("prevpage") 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("INSERT") 
					LET lv_mode = "ADD" 
				OTHERWISE 
					NEXT FIELD total_qty 
			END CASE 
		ON KEY (F2) 
			IF lv_mode = "UPDATE" THEN 
				IF ga_stocktake[lv_idx].part_code IS NOT NULL THEN 
					IF delete_stocktake(lv_idx) THEN 
						###-redisplay SCREEN-###
						LET pr_onhand_qty = ga_stocktake[lv_idx].onhand_qty 
						IF pr_onhand_qty IS NULL THEN 
							LET pr_onhand_qty = 0 
						END IF 
						LET pr_bin_text = ga_stocktake[lv_idx].bin_text 
						IF pr_bin_text IS NULL THEN 
							LET pr_bin_text = " " 
						END IF 
						LET pr_part_code = ga_stocktake[lv_idx].part_code 
						FOR lv_idx2 = arr_curr() TO arr_count() 
							LET ga_stocktake[lv_idx2].* = ga_stocktake[lv_idx2+1].* 
							IF arr_curr() = arr_count() THEN 
								INITIALIZE ga_stocktake[lv_idx2].* TO NULL 
								DISPLAY ga_stocktake[lv_idx2].* 
								TO sa_stocktake[lv_scrn].* 
								EXIT FOR 
							END IF 
							IF lv_scrn <= 10 THEN 
								DISPLAY ga_stocktake[lv_idx2].* 
								TO sa_stocktake[lv_scrn].* 
								LET lv_scrn = lv_scrn + 1 
							END IF 
						END FOR 
						# add onhand qty TO another bin that has same part code
						FOR pr_counter = 1 TO arr_count() 
							IF ga_stocktake[pr_counter].bin_text IS NULL THEN 
								LET ga_stocktake[pr_counter].bin_text = " " 
							END IF 
							IF ga_stocktake[pr_counter].part_code = pr_part_code 
							AND ga_stocktake[pr_counter].bin_text != pr_bin_text THEN 
								IF ga_stocktake[pr_counter].onhand_qty IS NULL THEN 
									LET ga_stocktake[pr_counter].onhand_qty = 0 
								END IF 
								IF pr_onhand_qty IS NULL THEN 
									LET pr_onhand_qty = 0 
								END IF 
								LET ga_stocktake[pr_counter].onhand_qty 
								= ga_stocktake[pr_counter].onhand_qty + pr_onhand_qty 
								IF ga_stocktake[pr_counter].bin_text = " " THEN 
									UPDATE stktakedetl 
									SET onhand_qty = ga_stocktake[pr_counter].onhand_qty 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code = ga_stocktake[pr_counter].part_code 
									AND cycle_num = gr_stktake.cycle_num 
									AND bin_text IS NULL 
								ELSE 
									UPDATE stktakedetl 
									SET onhand_qty = ga_stocktake[pr_counter].onhand_qty 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code = ga_stocktake[pr_counter].part_code 
									AND cycle_num = gr_stktake.cycle_num 
									AND bin_text = ga_stocktake[pr_counter].bin_text 
								END IF 
								EXIT FOR 
							END IF 
						END FOR 
					END IF 
					LET msgresp = kandoomsg("U",1004,"") 
					#1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
				END IF 
				IF lv_update_flag THEN 
					NEXT FIELD count_qty 
				ELSE 
					NEXT FIELD total_qty 
				END IF 
			END IF 
			LET pr_invalid_entry = false 
		ON KEY (control-b) 
			CASE 
				WHEN infield(part_code) 
					LET pr_wind_text = show_item(glob_rec_kandoouser.cmpy_code) 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					IF pr_wind_text IS NOT NULL THEN 
						LET ga_stocktake[lv_idx].part_code = pr_wind_text 
					END IF 
					NEXT FIELD part_code 
			END CASE 
		AFTER ROW 
			DISPLAY ga_stocktake[lv_idx].* 
			TO sa_stocktake[lv_scrn].* 
		AFTER INPUT 
			IF int_flag OR quit_flag OR pr_invalid_entry THEN 
				LET int_flag = false 
				LET quit_flag = false 
				###-IF previously in ADD mode THEN redisplay the SCREEN
				###-AND RETURN the array
				IF lv_mode = "ADD" THEN 
					LET msgresp = kandoomsg("U",1004,"") 
					#1004 " F1 TO Add - F2 TO Delete - ESC TO Continue"
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					FOR lv_idx2 = arr_curr() TO arr_count() 
						LET ga_stocktake[lv_idx2].* = ga_stocktake[lv_idx2+1].* 
						IF arr_curr() = arr_count() THEN 
							INITIALIZE ga_stocktake[lv_idx2].* TO NULL 
							DISPLAY ga_stocktake[lv_idx2].* 
							TO sa_stocktake[lv_scrn].* 
							LET lv_scrn = lv_scrn + 1 
							EXIT FOR 
						END IF 
						IF lv_scrn <= 10 THEN 
							DISPLAY ga_stocktake[lv_idx2].* 
							TO sa_stocktake[lv_scrn].* 
							LET lv_scrn = lv_scrn + 1 
						END IF 
					END FOR 
					LET lv_mode = "UPDATE" 
				END IF 
			END IF 
			LET lv_idx = arr_count() 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	RETURN lv_idx 
END FUNCTION 
#
# Update Stocktake Row - Intercatively UPDATE the new stocktake row
#
FUNCTION update_stocktake(lv_idx, lv_source,lv_old_count) 
	DEFINE 
	lv_idx SMALLINT, 
	lv_source CHAR(1), 
	lr_stktake RECORD LIKE stktake.*, 
	lr_stktakedetl RECORD LIKE stktakedetl.*, 
	lv_old_count,lv_return_qty FLOAT, 
	lv_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	IF ga_stocktake[lv_idx].bin_text IS NULL THEN 
		LET where_text1 = "bin_text IS NULL" 
	ELSE 
		LET where_text1 = "bin_text = '", 
		ga_stocktake[lv_idx].bin_text clipped, "'" 
	END IF 
	LET query_text = "SELECT rowid,* FROM stktakedetl ", 
	" WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND cycle_num = '", gr_stktake.cycle_num, "' ", 
	" AND ware_code = '", gr_ware_code, "' ", 
	" AND part_code = '", ga_stocktake[lv_idx].part_code, "' ", 
	" AND ", where_text1 clipped, " ", 
	" FOR UPDATE" 
	PREPARE s2_stocktake FROM query_text 
	DECLARE c2_stocktake CURSOR FOR s2_stocktake 
	BEGIN WORK 
		LET err_message = "Open CURSOR c2_stocktake error" 
		OPEN c2_stocktake 
		LET err_message = "Fetch CURSOR c2_stocktake error" 
		FETCH c2_stocktake INTO lv_rowid, lr_stktakedetl.* 
		CASE lv_source 
			WHEN "C" 
				LET lv_return_qty = lr_stktakedetl.count_qty + 
				(ga_stocktake[lv_idx].count_qty - lv_old_count) 
			WHEN "T" 
				LET lv_return_qty = ga_stocktake[lv_idx].total_qty 
		END CASE 
		LET err_message = "Updating stktakedetl FOR rowid = ", lv_rowid 
		UPDATE stktakedetl 
		SET count_qty = lv_return_qty, 
		entry_person = glob_rec_kandoouser.sign_on_code, 
		entered_date = today 
		WHERE rowid = lv_rowid 
		###-UPDATE the details of the stocktake-###
		DECLARE c2_stktake CURSOR FOR 
		SELECT rowid,* 
		FROM stktake 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = gr_stktake.cycle_num 
		FOR UPDATE 
		LET err_message = "Opening c2_stktake CURSOR" 
		OPEN c2_stktake 
		LET err_message = "Fetching c2_stktake CURSOR" 
		FETCH c2_stktake INTO lv_rowid, lr_stktake.* 
		LET lr_stktake.total_onhand_qty = 
		lr_stktake.total_onhand_qty + 
		(lv_return_qty - lr_stktakedetl.count_qty) 
		LET err_message = "Update - stktake total quantity " 
		UPDATE stktake 
		SET total_onhand_qty = lr_stktake.total_onhand_qty 
		WHERE rowid = lv_rowid 
	COMMIT WORK 
	WHENEVER ERROR CONTINUE 
	RETURN lv_return_qty 
END FUNCTION 
#
# Insert Stocktake Row - Interactively INSERT the new stocktake row
#
FUNCTION insert_stocktake(lv_idx) 
	DEFINE 
	lv_idx SMALLINT, 
	lr_stktakedetl RECORD LIKE stktakedetl.*, 
	lr_prodstatus RECORD LIKE prodstatus.*, 
	lv_rowid INTEGER 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		###-Collect the prodstatus details
		SELECT * INTO lr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = ga_stocktake[lv_idx].part_code 
		AND ware_code = gr_ware_code 
		###-Prepare the RECORD TO INSERT-###
		LET lr_stktakedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET lr_stktakedetl.part_code = ga_stocktake[lv_idx].part_code 
		LET lr_stktakedetl.ware_code = gr_ware_code 
		LET lr_stktakedetl.bin_text = ga_stocktake[lv_idx].bin_text 
		LET lr_stktakedetl.onhand_qty = 0 
		LET lr_stktakedetl.count_qty = ga_stocktake[lv_idx].count_qty 
		LET lr_stktakedetl.posted_flag = "N" 
		LET lr_stktakedetl.entry_person = glob_rec_kandoouser.sign_on_code 
		LET lr_stktakedetl.entered_date = today 
		LET lr_stktakedetl.posted_date = NULL 
		LET lr_stktakedetl.maingrp_code = ga_stocktake[lv_idx].maingrp_code 
		LET lr_stktakedetl.prodgrp_code = ga_stocktake[lv_idx].prodgrp_code 
		LET lr_stktakedetl.cycle_num = gr_stktake.cycle_num 
		###-Insert the stktakedetl row-###
		LET err_message = "Insert - stktakedetl row ", lv_idx 
		INSERT INTO stktakedetl VALUES (lr_stktakedetl.*) 
		###-Update the stktake table-###
		DECLARE c3_stktake CURSOR FOR 
		SELECT rowid 
		FROM stktake 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = gr_stktake.cycle_num 
		FOR UPDATE 
		LET err_message = "Opening c3_stktake CURSOR" 
		OPEN c3_stktake 
		LET err_message = "Fetching c3_stktake CURSOR" 
		FETCH c3_stktake INTO lv_rowid 
		LET err_message = "Update - stktake total onhand quantity " 
		UPDATE stktake 
		SET total_onhand_qty = total_onhand_qty + lr_stktakedetl.count_qty 
		WHERE rowid = lv_rowid 
	COMMIT WORK 
	WHENEVER ERROR CONTINUE 
	RETURN lr_stktakedetl.count_qty 
END FUNCTION 
#
# Delete Stocktake Row - Intercatively delete the stocktake row
#
FUNCTION delete_stocktake(lv_idx) 
	DEFINE 
	lv_idx SMALLINT, 
	lv_answer CHAR(1) 

	LET msgresp = kandoomsg("I","8036","") 
	#8036 Delete stock take count record? (Y/N)
	IF msgresp = "Y" THEN 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(err_message, status) = "N" THEN 
			EXIT program 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		#LET msgresp = kandoomsg("U",1005,"")
		#1005 Updating database....
		BEGIN WORK 
			LET err_message = "Delete - Stocktake detail ", lv_idx 
			IF ga_stocktake[lv_idx].bin_text IS NULL THEN 
				DELETE FROM stktakedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = gr_ware_code 
				AND part_code = ga_stocktake[lv_idx].part_code 
				AND bin_text IS NULL 
			ELSE 
				DELETE FROM stktakedetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = gr_ware_code 
				AND part_code = ga_stocktake[lv_idx].part_code 
				AND bin_text = ga_stocktake[lv_idx].bin_text 
			END IF 
		COMMIT WORK 
		WHENEVER ERROR CONTINUE 
		RETURN true 
	END IF 
	RETURN false 
END FUNCTION 
#
# DISPLAY Stocktake - Displays the rows on the stocktake SCREEN
#
FUNCTION display_stocktake() 
	DEFINE 
	lr_stktakedetl RECORD LIKE stktakedetl.*, 
	lr_product RECORD LIKE product.*, 
	lv_counter,lv_idx SMALLINT, 
	lv_rowid INTEGER 

	###-Prepare the ARRAY variables-###
	LET msgresp=kandoomsg("I",1002,"") 
	#1002 Searching database - please wait
	LET lv_idx = 1 
	FOREACH c_stocktake INTO lv_rowid, lr_stktakedetl.* 
		SELECT * INTO lr_product.* 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = lr_stktakedetl.part_code 
		LET ga_stocktake[lv_idx].onhand_qty = lr_stktakedetl.onhand_qty 
		LET ga_stocktake[lv_idx].bin_text = lr_stktakedetl.bin_text 
		LET ga_stocktake[lv_idx].part_code = lr_stktakedetl.part_code 
		LET ga_stocktake[lv_idx].maingrp_code = lr_stktakedetl.maingrp_code 
		LET ga_stocktake[lv_idx].prodgrp_code = lr_stktakedetl.prodgrp_code 
		LET ga_stocktake[lv_idx].count_qty = 0 
		LET ga_stocktake[lv_idx].total_qty = lr_stktakedetl.count_qty 
		LET ga_stocktake[lv_idx].sell_uom_code = lr_product.sell_uom_code 
		LET lv_idx = lv_idx + 1 
		IF lv_idx > gv_array_size THEN 
			LET msgresp=kandoomsg("U",6100,lv_idx-1) 
			#6100 "First x records selected only.  More may be available.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF lv_idx = 1 THEN 
		LET lv_idx = 0 
	ELSE 
		LET lv_idx = lv_idx - 1 
		FOR lv_counter = 1 TO lv_idx 
			IF lv_counter <= 10 THEN 
				DISPLAY ga_stocktake[lv_counter].* 
				TO sa_stocktake[lv_counter].* 
			ELSE 
				EXIT FOR 
			END IF 
		END FOR 
		CALL display_footer(1,1) 
	END IF 
	LET msgresp=kandoomsg("U",9113,lv_idx) 
	#9113 lv_idx records selected
	RETURN lv_idx 
END FUNCTION 
#
# DISPLAY Footer - displays the footer section of the SCREEN
#
FUNCTION display_footer(lv_idx,lv_showstktake) 
	DEFINE 
	lv_idx, lv_showstktake SMALLINT, 
	lr_product RECORD LIKE product.*, 
	lr_stktakedetl RECORD LIKE stktakedetl.* 

	########################################################
	###-IF showing stocktake detail information THEN
	###-   SELECT AND DISPLAY stocktake details AND
	###-   current product details AT bottom of SCREEN
	###-ELSE
	###-   do NOT DISPLAY stocktake row details but
	###-   DISPLAY ***'s in product descriptions
	###-   AND current date AND person AT bootom of SCREEN
	###-END IF
	########################################################
	IF lv_showstktake THEN 
		IF ga_stocktake[lv_idx].bin_text IS NULL THEN 
			SELECT * INTO lr_stktakedetl.* 
			FROM stktakedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = gr_ware_code 
			AND part_code = ga_stocktake[lv_idx].part_code 
			AND bin_text IS NULL 
		ELSE 
			SELECT * INTO lr_stktakedetl.* 
			FROM stktakedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = gr_ware_code 
			AND part_code = ga_stocktake[lv_idx].part_code 
			AND bin_text = ga_stocktake[lv_idx].bin_text 
		END IF 
	END IF 
	INITIALIZE lr_product.* TO NULL 
	IF lv_idx THEN 
		SELECT * INTO lr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = ga_stocktake[lv_idx].part_code 
		IF status <> notfound THEN 
			DISPLAY lr_product.desc_text TO product.desc_text 

			DISPLAY lr_product.desc2_text TO product.desc2_text 

		END IF 
	ELSE 
		DISPLAY lr_product.desc_text TO product.desc_text 

		DISPLAY lr_product.desc2_text TO product.desc2_text 

	END IF 
	IF NOT lv_showstktake THEN 
		LET lr_stktakedetl.entered_date = today 
		LET lr_stktakedetl.entry_person = glob_rec_kandoouser.sign_on_code 
	END IF 
	DISPLAY BY NAME lr_stktakedetl.entry_person 

	DISPLAY BY NAME lr_stktakedetl.entered_date 

END FUNCTION 
