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

# Purpose - Shop Order Inquiry

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

	DEFINE 
	formname CHAR(10), 
	pv_text CHAR(16), 
	pv_unit_cost_amt LIKE shopordhead.std_est_cost_amt, 
	pv_desc_text LIKE product.desc_text, 

	pr_mnparms RECORD LIKE mnparms.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_shopordhead RECORD LIKE shopordhead.*, 
	pr_menunames RECORD LIKE menunames.* 

END GLOBALS 


MAIN 

	#Initial UI Init
	CALL setModuleId("M32") -- albo 
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
		# prompt "Manufacturing parameters are NOT SET up - Press any key"
		EXIT program 
	END IF 

	SELECT * 
	INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = 1 

	IF status = notfound THEN 
		LET msgresp = kandoomsg("M", 7501, "") 
		# prompt "Inventory parameters are NOT SET up - Press any key"
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

	IF pr_mnparms.ref4_text IS NOT NULL THEN 
		LET pr_mnparms.ref4_text = pr_mnparms.ref4_text clipped, 
		"..................." 
	END IF 

	CALL inquiry_menu() 

END MAIN 



FUNCTION query_orders() 

	DEFINE fv_where_text CHAR(500), 
	fv_query_text CHAR(500) 


	CLEAR FORM 

	IF pr_mnparms.ref4_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref4_text 
	END IF 

	LET msgresp = kandoomsg("M", 1500, "") 
	# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

	IF pr_mnparms.ref4_ind matches "[1234]" THEN 
		CONSTRUCT BY NAME fv_where_text 
		ON shop_order_num, suffix_num, parent_part_code, order_type_ind, 
		sales_order_num, cust_code, part_code, status_ind, order_qty, 
		uom_code, receipted_qty, rejected_qty, start_date, release_date, 
		end_date, job_length_num, actual_start_date, actual_end_date, 
		user4_text 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
	ELSE 
		CONSTRUCT BY NAME fv_where_text 
		ON shop_order_num, suffix_num, parent_part_code, order_type_ind, 
		sales_order_num, cust_code, part_code, status_ind, order_qty, 
		uom_code, receipted_qty, rejected_qty, start_date, release_date, 
		end_date, job_length_num, actual_start_date, actual_end_date 

			ON ACTION "WEB-HELP" -- albo kd-376 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	LET msgresp = kandoomsg("M", 1532, "") 
	# MESSAGE "Searching database - please wait"

	LET fv_query_text = "SELECT * ", 
	"FROM shopordhead ", 
	"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	"AND order_type_ind != 'F' ", 
	"AND ", fv_where_text clipped, " ", 
	"ORDER BY shop_order_num, suffix_num" 

	PREPARE sl_stmt1 FROM fv_query_text 
	DECLARE s_shopordhead SCROLL CURSOR FOR sl_stmt1 
	OPEN s_shopordhead 

	FETCH s_shopordhead INTO pr_shopordhead.* 

	IF status = notfound THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 

END FUNCTION 



FUNCTION inquiry_menu() 

	DEFINE fv_exist SMALLINT 

	OPEN WINDOW w1_m128 with FORM "M128" 
	CALL  windecoration_m("M128") -- albo kd-762 

	IF pr_mnparms.ref4_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref4_text 
	END IF 

	LET fv_exist = false 

	CALL kandoomenu("M", 100) RETURNING pr_menunames.* 
	MENU pr_menunames.menu_text # shop ORDER inquiry 

		ON ACTION "WEB-HELP" -- albo kd-376 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE MENU 
			IF pr_mnparms.ref4_ind NOT matches "[1234]" THEN 
				HIDE option pr_menunames.cmd7_code # notes 
			END IF 

		COMMAND pr_menunames.cmd1_code pr_menunames.cmd1_text # query 
			LET fv_exist = query_orders() 

			IF fv_exist THEN 
				CALL show_header() 
			ELSE 
				LET msgresp = kandoomsg("M", 9620, "")		# ERROR "No shop orders satisfied the selection criteria"
			END IF 

		COMMAND pr_menunames.cmd2_code pr_menunames.cmd2_text # NEXT 
			IF fv_exist THEN 
				FETCH NEXT s_shopordhead INTO pr_shopordhead.* 

				IF status != notfound THEN 
					CALL show_header() 
				ELSE 
					LET msgresp = kandoomsg("M", 9618, "") 
					# ERROR "You have reached the END of the shop orders..."
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd3_code pr_menunames.cmd3_text # previous 
			IF fv_exist THEN 
				FETCH previous s_shopordhead INTO pr_shopordhead.* 

				IF status != notfound THEN 
					CALL show_header() 
				ELSE 
					LET msgresp = kandoomsg("M", 9619, "") 
					# ERROR "You have reached the start of the shop orders..."
				END IF 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd4_code pr_menunames.cmd4_text # FIRST 
			IF fv_exist THEN 
				FETCH FIRST s_shopordhead INTO pr_shopordhead.* 
				CALL show_header() 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd5_code pr_menunames.cmd5_text # LAST 
			IF fv_exist THEN 
				FETCH LAST s_shopordhead INTO pr_shopordhead.* 
				CALL show_header() 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd6_code pr_menunames.cmd6_text # details 
			IF fv_exist THEN 
				CALL view_details() 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd7_code pr_menunames.cmd7_text # notes 
			IF fv_exist THEN 
				IF pr_shopordhead.user4_text[1,3] = "###" THEN 
					CALL note_disp(glob_rec_kandoouser.cmpy_code, pr_shopordhead.user4_text[4,15]) 
				ELSE 
					ERROR "This shop ORDER header doesn't have any notes" 

				END IF 
			ELSE 
				LET msgresp = kandoomsg("M", 9617, "") 
				# ERROR "You have TO make a selection first"
			END IF 

		COMMAND pr_menunames.cmd8_code pr_menunames.cmd8_text # EXIT 
			EXIT MENU 

		COMMAND KEY (interrupt) 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW w1_m128 

END FUNCTION 



FUNCTION show_header() 

	DEFINE fv_unit_cost_amt LIKE shopordhead.std_est_cost_amt, 
	fv_unit_price_amt LIKE shopordhead.std_price_amt, 
	fv_act_unit_cost LIKE shopordhead.act_est_cost_amt, 
	fv_act_unit_price LIKE shopordhead.act_price_amt, 
	fv_parent_desc LIKE product.desc_text, 
	fv_name_text LIKE customer.name_text, 
	fv_desc_text LIKE product.desc_text 


	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.parent_part_code, 
	pr_shopordhead.order_type_ind, 
	pr_shopordhead.sales_order_num, 
	pr_shopordhead.cust_code, 
	pr_shopordhead.part_code, 
	pr_shopordhead.status_ind, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.uom_code, 
	pr_shopordhead.receipted_qty, 
	pr_shopordhead.rejected_qty, 
	pr_shopordhead.std_price_amt, 
	pr_shopordhead.act_price_amt, 
	pr_shopordhead.start_date, 
	pr_shopordhead.release_date, 
	pr_shopordhead.end_date, 
	pr_shopordhead.job_length_num, 
	pr_shopordhead.actual_start_date, 
	pr_shopordhead.actual_end_date 

	IF pr_mnparms.ref4_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_shopordhead.user4_text 
	END IF 

	IF pr_shopordhead.parent_part_code IS NOT NULL THEN 
		SELECT desc_text 
		INTO fv_parent_desc 
		FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_shopordhead.parent_part_code 

		DISPLAY fv_parent_desc TO parent_desc 
	ELSE 
		DISPLAY "" TO parent_desc 
	END IF 

	IF pr_shopordhead.cust_code IS NOT NULL THEN 
		SELECT name_text 
		INTO fv_name_text 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_shopordhead.cust_code 

		DISPLAY fv_name_text TO name_text 
	ELSE 
		DISPLAY "" TO name_text 
	END IF 

	SELECT desc_text 
	INTO pv_desc_text 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_shopordhead.part_code 

	DISPLAY pv_desc_text TO desc_text 

	CASE pr_shopordhead.status_ind 
		WHEN "H" 
			LET pv_text = kandooword("Held", "M07") 
			DISPLAY pv_text TO status_text 

		WHEN "R" 
			LET pv_text = kandooword("Released", "M08") 
			DISPLAY pv_text TO status_text 

		WHEN "C" 
			LET pv_text = kandooword("Closed", "M09") 
			DISPLAY pv_text TO status_text 
	END CASE 

	CASE 
		WHEN pr_inparms.cost_ind matches "[WF]" 
			IF pr_inparms.cost_ind = "W" THEN 
				LET pv_text = kandooword("Weighted", "M10") 
				DISPLAY pv_text TO cost_method_text 
			ELSE 
				LET pv_text = kandooword("FIFO", "M11") 
				DISPLAY pv_text TO cost_method_text 
			END IF 

			LET pv_unit_cost_amt = pr_shopordhead.std_wgted_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_wgted_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_wgted_cost_amt, 
			pr_shopordhead.act_wgted_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 

		WHEN pr_inparms.cost_ind = "S" 
			LET pv_text = kandooword("Standard", "M12") 
			DISPLAY pv_text TO cost_method_text 
			LET pv_unit_cost_amt = pr_shopordhead.std_est_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_est_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_est_cost_amt, 
			pr_shopordhead.act_est_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET pv_text = kandooword("Latest", "M13") 
			DISPLAY pv_text TO cost_method_text 
			LET pv_unit_cost_amt = pr_shopordhead.std_act_cost_amt / 
			pr_shopordhead.order_qty 

			IF pr_shopordhead.receipted_qty > 0 THEN 
				LET fv_act_unit_cost = pr_shopordhead.act_act_cost_amt / 
				pr_shopordhead.receipted_qty 
			ELSE 
				LET fv_act_unit_cost = 0 
			END IF 

			DISPLAY pr_shopordhead.std_act_cost_amt, 
			pr_shopordhead.act_act_cost_amt 
			TO ext_cost_amt, act_ext_cost_amt 
	END CASE 

	LET fv_unit_price_amt = pr_shopordhead.std_price_amt / 
	pr_shopordhead.order_qty 

	IF pr_shopordhead.receipted_qty > 0 THEN 
		LET fv_act_unit_price = pr_shopordhead.act_price_amt / 
		pr_shopordhead.receipted_qty 
	ELSE 
		LET fv_act_unit_price = 0 
	END IF 

	DISPLAY pv_unit_cost_amt, 
	fv_unit_price_amt, 
	fv_act_unit_cost, 
	fv_act_unit_price 
	TO unit_cost_amt, 
	unit_price_amt, 
	act_unit_cost_amt, 
	act_unit_price_amt 

END FUNCTION 



FUNCTION view_details() 

	DEFINE fv_idx SMALLINT, 
	fv_cnt SMALLINT, 
	fv_wc_tot LIKE shoporddetl.std_est_cost_amt, 

	fr_workcentre RECORD LIKE workcentre.*, 
	fr_shoporddetl RECORD LIKE shoporddetl.*, 

	fa_shoporddetl array[2000] OF RECORD LIKE shoporddetl.*, 
	fa_scrn_sodetl array[2000] OF RECORD 
		type_ind LIKE shoporddetl.type_ind, 
		component_type_ind CHAR(1), 
		part_code LIKE shoporddetl.part_code, 
		desc_text LIKE product.desc_text, 
		required_qty LIKE shoporddetl.required_qty, 
		unit_cost_amt LIKE shoporddetl.std_est_cost_amt, 
		sequence_num LIKE shoporddetl.sequence_num 
	END RECORD 


	DECLARE c_so_detl CURSOR FOR 
	SELECT * 
	FROM shoporddetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND shop_order_num = pr_shopordhead.shop_order_num 
	AND suffix_num = pr_shopordhead.suffix_num 
	ORDER BY sequence_num 

	LET fv_cnt = 0 

	FOREACH c_so_detl INTO fr_shoporddetl.* 
		LET fv_cnt = fv_cnt + 1 

		LET fa_scrn_sodetl[fv_cnt].type_ind = fr_shoporddetl.type_ind 
		LET fa_scrn_sodetl[fv_cnt].part_code = fr_shoporddetl.part_code 
		LET fa_scrn_sodetl[fv_cnt].required_qty = fr_shoporddetl.required_qty 
		LET fa_scrn_sodetl[fv_cnt].unit_cost_amt = 
		fr_shoporddetl.std_est_cost_amt 

		CASE fr_shoporddetl.type_ind 
			WHEN "I" 
				LET fa_scrn_sodetl[fv_cnt].part_code = 
				kandooword("INSTRUCTION", "M14") 

			WHEN "S" 
				LET fa_scrn_sodetl[fv_cnt].part_code = kandooword("COST", "M15") 

			WHEN "W" 
				LET fa_scrn_sodetl[fv_cnt].part_code = 
				fr_shoporddetl.work_centre_code 
				LET fa_scrn_sodetl[fv_cnt].unit_cost_amt = 
				fr_shoporddetl.std_act_cost_amt /fr_shoporddetl.required_qty 

			WHEN "U" 
				LET fa_scrn_sodetl[fv_cnt].part_code = kandooword("SET UP", "M17") 
				LET fa_scrn_sodetl[fv_cnt].required_qty = NULL 

			OTHERWISE 
				SELECT desc_text 
				INTO fr_shoporddetl.desc_text 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				SELECT part_type_ind 
				INTO fa_scrn_sodetl[fv_cnt].component_type_ind 
				FROM prodmfg 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = fr_shoporddetl.part_code 

				IF fr_shoporddetl.type_ind = "B" THEN 
					LET fr_shoporddetl.required_qty = 
					- fr_shoporddetl.required_qty 
					LET fr_shoporddetl.receipted_qty = 
					- fr_shoporddetl.receipted_qty 
					LET fr_shoporddetl.rejected_qty = 
					- fr_shoporddetl.rejected_qty 
					LET fa_scrn_sodetl[fv_cnt].required_qty = 
					- (fa_scrn_sodetl[fv_cnt].required_qty) 
				END IF 

				CASE 
					WHEN pr_inparms.cost_ind matches "[WF]" 
						LET fa_scrn_sodetl[fv_cnt].unit_cost_amt = 
						fr_shoporddetl.std_wgted_cost_amt 

					WHEN pr_inparms.cost_ind = "L" 
						LET fa_scrn_sodetl[fv_cnt].unit_cost_amt = 
						fr_shoporddetl.std_act_cost_amt 
				END CASE 
		END CASE 

		LET fa_shoporddetl[fv_cnt].* = fr_shoporddetl.* 
		LET fa_scrn_sodetl[fv_cnt].desc_text = fr_shoporddetl.desc_text 

		IF fv_cnt = 2000 THEN 
			LET msgresp = kandoomsg("M", 9760, "") 
			# ERROR "Only the first 2000 detail lines were selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	OPEN WINDOW w2_m151 with FORM "M151" 
	CALL  windecoration_m("M151") -- albo kd-762 

	LET msgresp = kandoomsg("M", 1528, "") # MESSAGE "RETURN TO View Item Details, F3 Fwd, F4 Bwd - DEL Exit"

	DISPLAY BY NAME pr_shopordhead.shop_order_num, 
	pr_shopordhead.suffix_num, 
	pr_shopordhead.order_qty, 
	pr_shopordhead.part_code 

	DISPLAY pv_desc_text, pv_unit_cost_amt TO product.desc_text, unit_cost_amt 

	CASE 
		WHEN pr_inparms.cost_ind matches "[WF]" 
			DISPLAY pr_shopordhead.std_wgted_cost_amt TO ext_cost_amt 

		WHEN pr_inparms.cost_ind = "S" 
			DISPLAY pr_shopordhead.std_est_cost_amt TO ext_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			DISPLAY pr_shopordhead.std_act_cost_amt TO ext_cost_amt 
	END CASE 

	CALL set_count(fv_cnt) 

	DISPLAY ARRAY fa_scrn_sodetl TO sr_shoporddetl.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","M32","display-arr-shoporddetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (RETURN) 
			LET fv_idx = arr_curr() 

			CASE fa_scrn_sodetl[fv_idx].type_ind 
				WHEN "I" 
					CALL display_instruc(fa_shoporddetl[fv_idx].*) 

				WHEN "S" 
					CALL display_cost(fa_shoporddetl[fv_idx].*) 

				WHEN "W" 
					CALL display_workcentre(fa_shoporddetl[fv_idx].*) 

				WHEN "U" 
					CALL display_setup(fa_shoporddetl[fv_idx].*) 

				OTHERWISE 
					IF fa_scrn_sodetl[fv_idx].component_type_ind = "P" THEN 
						LET msgresp = kandoomsg("M", 9759, "") 
						#error"There are no details TO view FOR phantom products"
					ELSE 
						CALL display_component(fa_shoporddetl[fv_idx].*) 
					END IF 
			END CASE 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW w2_m151 

END FUNCTION 



FUNCTION display_component(fr_shoporddetl) 

	DEFINE fv_wc_desc_text LIKE workcentre.desc_text, 
	fv_ware_desc LIKE warehouse.desc_text, 
	fv_vend_code LIKE product.vend_code, 
	fv_vend_name LIKE vendor.name_text, 
	fv_ext_cost_amt LIKE shoporddetl.std_est_cost_amt, 
	fv_ext_price_amt LIKE shoporddetl.std_price_amt, 
	fv_act_ext_cost LIKE shoporddetl.act_est_cost_amt, 
	fv_act_ext_price LIKE shoporddetl.act_price_amt, 

	fr_shoporddetl RECORD LIKE shoporddetl.* 


	IF fr_shoporddetl.type_ind = "C" THEN 
		OPEN WINDOW w3_m139 with FORM "M139" 
		CALL  windecoration_m("M139") -- albo kd-762 

		DISPLAY BY NAME fr_shoporddetl.issued_qty 
	ELSE 
		OPEN WINDOW w3_m154 with FORM "M154" 
		CALL  windecoration_m("M154") -- albo kd-762 

		DISPLAY BY NAME fr_shoporddetl.receipted_qty, 
		fr_shoporddetl.rejected_qty 
	END IF 

	DISPLAY BY NAME fr_shoporddetl.part_code, 
	fr_shoporddetl.desc_text, 
	fr_shoporddetl.issue_ware_code, 
	fr_shoporddetl.required_qty, 
	fr_shoporddetl.uom_code, 
	fr_shoporddetl.work_centre_code, 
	fr_shoporddetl.std_price_amt, 
	fr_shoporddetl.act_price_amt, 
	fr_shoporddetl.start_date, 
	fr_shoporddetl.actual_start_date 

	SELECT desc_text 
	INTO fv_ware_desc 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = fr_shoporddetl.issue_ware_code 

	SELECT desc_text 
	INTO fv_wc_desc_text 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 

	DISPLAY fv_ware_desc, fv_wc_desc_text 
	TO warehouse.desc_text, workcentre.desc_text 

	SELECT vend_code 
	INTO fv_vend_code 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = fr_shoporddetl.part_code 

	SELECT name_text 
	INTO fv_vend_name 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = fv_vend_code 

	DISPLAY fv_vend_code, fv_vend_name 
	TO vend_code, name_text 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_shoporddetl.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_shoporddetl.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_shoporddetl.user3_text 
	END IF 

	CASE 
		WHEN pr_inparms.cost_ind matches "[WF]" 
			LET fv_ext_cost_amt = fr_shoporddetl.std_wgted_cost_amt * 
			fr_shoporddetl.required_qty 
			LET fv_act_ext_cost = fr_shoporddetl.act_wgted_cost_amt * 
			fr_shoporddetl.issued_qty 

			DISPLAY fr_shoporddetl.std_wgted_cost_amt, 
			fr_shoporddetl.act_wgted_cost_amt 
			TO unit_cost_amt, act_unit_cost_amt 

		WHEN pr_inparms.cost_ind = "S" 
			LET fv_ext_cost_amt = fr_shoporddetl.std_est_cost_amt * 
			fr_shoporddetl.required_qty 
			LET fv_act_ext_cost = fr_shoporddetl.act_est_cost_amt * 
			fr_shoporddetl.issued_qty 

			DISPLAY fr_shoporddetl.std_est_cost_amt, 
			fr_shoporddetl.act_est_cost_amt 
			TO unit_cost_amt, act_unit_cost_amt 

		WHEN pr_inparms.cost_ind = "L" 
			LET fv_ext_cost_amt = fr_shoporddetl.std_act_cost_amt * 
			fr_shoporddetl.required_qty 
			LET fv_act_ext_cost = fr_shoporddetl.act_act_cost_amt * 
			fr_shoporddetl.issued_qty 

			DISPLAY fr_shoporddetl.std_act_cost_amt, 
			fr_shoporddetl.act_act_cost_amt 
			TO unit_cost_amt, act_unit_cost_amt 
	END CASE 

	LET fv_ext_price_amt = fr_shoporddetl.std_price_amt * 
	fr_shoporddetl.required_qty 
	LET fv_act_ext_price = fr_shoporddetl.act_price_amt * 
	fr_shoporddetl.issued_qty 

	IF fr_shoporddetl.type_ind = "B" THEN 
		LET fv_act_ext_cost = 0 
		LET fv_act_ext_price = 0 
	END IF 

	DISPLAY fv_ext_cost_amt, 
	fv_ext_price_amt, 
	fv_act_ext_cost, 
	fv_act_ext_price 
	TO ext_cost_amt, 
	ext_price_amt, 
	act_ext_cost_amt, 
	act_ext_price_amt 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	IF fr_shoporddetl.type_ind = "C" THEN 
		CLOSE WINDOW w3_m139 
	ELSE 
		CLOSE WINDOW w3_m154 
	END IF 

END FUNCTION 



FUNCTION display_instruc(fr_shoporddetl) 

	DEFINE fr_shoporddetl RECORD LIKE shoporddetl.* 

	OPEN WINDOW w4_m140 with FORM "M140" 
	CALL  windecoration_m("M140") -- albo kd-762 

	DISPLAY BY NAME fr_shoporddetl.desc_text 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_shoporddetl.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_shoporddetl.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_shoporddetl.user3_text 
	END IF 

	IF fr_shoporddetl.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_shoporddetl.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w4_m140 

END FUNCTION 



FUNCTION display_cost(fr_shoporddetl) 

	DEFINE fr_shoporddetl RECORD LIKE shoporddetl.* 

	OPEN WINDOW w5_m141 with FORM "M141" 
	CALL  windecoration_m("M141") -- albo kd-762 

	DISPLAY BY NAME fr_shoporddetl.desc_text, 
	fr_shoporddetl.std_est_cost_amt, 
	fr_shoporddetl.act_act_cost_amt, 
	fr_shoporddetl.std_price_amt, 
	fr_shoporddetl.act_price_amt, 
	fr_shoporddetl.cost_type_ind 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_shoporddetl.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_shoporddetl.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_shoporddetl.user3_text 
	END IF 

	IF fr_shoporddetl.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_shoporddetl.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w5_m141 

END FUNCTION 



FUNCTION display_workcentre(fr_shoporddetl) 

	DEFINE fv_time_unit CHAR(7), 
	fv_capacity_text CHAR(16), 

	fr_shoporddetl RECORD LIKE shoporddetl.*, 
	fr_workcentre RECORD LIKE workcentre.* 

	OPEN WINDOW w6_m142 with FORM "M142" 
	CALL  windecoration_m("M142") -- albo kd-762 

	SELECT * 
	INTO fr_workcentre.* 
	FROM workcentre 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND work_centre_code = fr_shoporddetl.work_centre_code 

	IF fr_shoporddetl.std_est_cost_amt IS NULL THEN 
		SELECT sum(rate_amt) 
		INTO fr_shoporddetl.std_est_cost_amt 
		FROM workctrrate 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND work_centre_code = fr_shoporddetl.work_centre_code 
		AND rate_ind = "V" 

		IF fr_shoporddetl.std_est_cost_amt IS NULL THEN 
			LET fr_shoporddetl.std_est_cost_amt = 0 
		END IF 

		SELECT sum(rate_amt) 
		INTO fr_shoporddetl.std_wgted_cost_amt 
		FROM workctrrate 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND work_centre_code = fr_shoporddetl.work_centre_code 
		AND rate_ind = "F" 

		IF fr_shoporddetl.std_wgted_cost_amt IS NULL THEN 
			LET fr_shoporddetl.std_wgted_cost_amt = 0 
		END IF 

		LET fr_shoporddetl.act_est_cost_amt = fr_shoporddetl.std_est_cost_amt * 
		(1 + (fr_workcentre.cost_markup_per / 100)) 

		LET fr_shoporddetl.act_wgted_cost_amt = 
		fr_shoporddetl.std_wgted_cost_amt * (1 + 
		(fr_workcentre.cost_markup_per / 100)) 
	END IF 

	DISPLAY BY NAME fr_shoporddetl.work_centre_code, 
	fr_shoporddetl.desc_text, 
	fr_shoporddetl.oper_factor_amt, 
	fr_shoporddetl.overlap_per, 
	fr_shoporddetl.act_act_cost_amt, 
	fr_shoporddetl.act_price_amt, 
	fr_shoporddetl.start_date, 
	fr_shoporddetl.start_time, 
	fr_shoporddetl.end_date, 
	fr_shoporddetl.end_time, 
	fr_shoporddetl.actual_start_date, 
	fr_shoporddetl.actual_start_time, 
	fr_shoporddetl.actual_end_date, 
	fr_shoporddetl.actual_end_time 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_shoporddetl.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_shoporddetl.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_shoporddetl.user3_text 
	END IF 

	LET pv_text = kandooword("per", "M18") 

	IF fr_workcentre.processing_ind = "Q" THEN 
		CASE fr_workcentre.time_unit_ind 
			WHEN "D" 
				LET fv_time_unit = kandooword("day", "M19") 
			WHEN "H" 
				LET fv_time_unit = kandooword("hour", "M20") 
			WHEN "M" 
				LET fv_time_unit = kandooword("minute", "M21") 
		END CASE 

		LET fv_capacity_text = fr_workcentre.unit_uom_code clipped, " ", 
		pv_text clipped, " ", fv_time_unit 
	ELSE 
		CASE fr_workcentre.time_unit_ind 
			WHEN "D" 
				LET fv_time_unit = kandooword("days", "M22") 
			WHEN "H" 
				LET fv_time_unit = kandooword("hours", "M23") 
			WHEN "M" 
				LET fv_time_unit = kandooword("minutes", "M24") 
		END CASE 

		LET fv_capacity_text = fv_time_unit clipped, " ", pv_text clipped, " ", 
		fr_workcentre.unit_uom_code 
	END IF 

	DISPLAY BY NAME fr_workcentre.time_qty 
	DISPLAY fv_capacity_text TO capacity_text 

	DISPLAY fr_shoporddetl.std_est_cost_amt, 
	fr_shoporddetl.std_wgted_cost_amt, 
	fr_shoporddetl.act_est_cost_amt, 
	fr_shoporddetl.act_wgted_cost_amt 
	TO variable_cost, 
	fixed_cost, 
	variable_price, 
	fixed_price 

	IF fr_shoporddetl.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_shoporddetl.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w6_m142 

END FUNCTION 



FUNCTION display_setup(fr_shoporddetl) 

	DEFINE fr_shoporddetl RECORD LIKE shoporddetl.* 

	OPEN WINDOW w7_m143 with FORM "M143" 
	CALL  windecoration_m("M143") -- albo kd-762 

	DISPLAY BY NAME fr_shoporddetl.desc_text, 
	fr_shoporddetl.required_qty, 
	fr_shoporddetl.uom_code, 
	fr_shoporddetl.std_est_cost_amt, 
	fr_shoporddetl.act_act_cost_amt, 
	fr_shoporddetl.std_price_amt, 
	fr_shoporddetl.act_price_amt, 
	fr_shoporddetl.cost_type_ind, 
	fr_shoporddetl.start_date, 
	fr_shoporddetl.start_time, 
	fr_shoporddetl.end_date, 
	fr_shoporddetl.end_time, 
	fr_shoporddetl.actual_start_date, 
	fr_shoporddetl.actual_start_time, 
	fr_shoporddetl.actual_end_date, 
	fr_shoporddetl.actual_end_time 

	IF pr_mnparms.ref1_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref1_text, 
		fr_shoporddetl.user1_text 
	END IF 

	IF pr_mnparms.ref2_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref2_text, 
		fr_shoporddetl.user2_text 
	END IF 

	IF pr_mnparms.ref3_ind matches "[1234]" THEN 
		DISPLAY BY NAME pr_mnparms.ref3_text, 
		fr_shoporddetl.user3_text 
	END IF 

	IF fr_shoporddetl.cost_type_ind != "F" THEN 
		DISPLAY BY NAME fr_shoporddetl.var_amt 
	END IF 

	IF fr_shoporddetl.desc_text[1,3] = "###" THEN 
		CALL note_disp(glob_rec_kandoouser.cmpy_code, fr_shoporddetl.desc_text[4,15]) 
	END IF 

	LET msgresp = kandoomsg("M", 7502, "") 
	# prompt "Any key TO continue"

	CLOSE WINDOW w7_m143 

END FUNCTION 
