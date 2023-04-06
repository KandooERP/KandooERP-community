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

	Source code beautified by beautify.pl on 2020-01-03 09:12:39	$Id: $
}

##- IS2 - Image Pricing and Costing
##- This menu path is used to maintain consistent pricing over an entire organisation.  
##- This facility is provided by nominating a master warehouse whose price and cost attributes can be used to update a series 
##- of selected warehouses.

# TODO: Code clean priority 1 
# TODO: Code clean priority 2
# TODO: Code clean priority 3

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "I_IN_GLOBALS.4gl" 

# Module scope variable
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_mast_code LIKE inparms.mast_ware_code, 
	where1_text char(500), ## global b/c reqd. FOR REPORT 
	pr_temp_text CHAR(500), 
	upd_list_flag, 
	upd_price1_flag, 
	upd_price2_flag, 
	upd_price3_flag, 
	upd_price4_flag, 
	upd_price5_flag, 
	upd_price6_flag, 
	upd_price7_flag, 
	upd_price8_flag, 
	upd_price9_flag, 
	upd_est_flag, 
	upd_act_flag, 
	upd_for_flag, 
	upd_tax_code, 
	upd_tax_amt CHAR(1) 



####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE err_cnt INTEGER 
	#Initial UI Init
	CALL setModuleId("IS2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL IS2_main()

END MAIN

FUNCTION IS2_main ()
	DEFINE err_cnt SMALLINT
	SELECT * INTO pr_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",9002,"") 
		##9002 Inventory parameters NOT SET up - Refer IZP
		EXIT program 
	END IF 
	LET pr_mast_code = pr_inparms.mast_ware_code 
	OPEN WINDOW i138 with FORM "I138" 
	 CALL windecoration_i("I138") -- albo kd-758 
	WHILE input_mast() 
		## Need TO initialise VALUES b/c defined as GLOBALS
		LET upd_list_flag = NULL 
		LET upd_price1_flag = NULL 
		LET upd_price2_flag = NULL 
		LET upd_price3_flag = NULL 
		LET upd_price4_flag = NULL 
		LET upd_price5_flag = NULL 
		LET upd_price6_flag = NULL 
		LET upd_price7_flag = NULL 
		LET upd_price8_flag = NULL 
		LET upd_price9_flag = NULL 
		LET upd_est_flag = NULL 
		LET upd_act_flag = NULL 
		LET upd_for_flag = NULL 
		LET upd_tax_code = NULL 
		LET upd_tax_amt = NULL 
		LET pr_temp_text = select_ware() 
		IF pr_temp_text IS NOT NULL THEN 
			OPEN WINDOW i179 with FORM "I179" 
			 CALL windecoration_i("I179") -- albo kd-758 
			WHILE NOT ( int_flag OR quit_flag ) 
				IF select_attr() THEN 
					IF scan_info() THEN 
						IF kandoomsg("I",8030,"") = 'Y' THEN 
							LET err_cnt = update_price(pr_temp_text) 
							IF err_cnt THEN 
								LET msgresp = kandoomsg("I",7042,err_cnt) 
								#7042 Process completed with errors - Refer get_settings_logFile()
							ELSE 
								LET msgresp = kandoomsg("I",7043,"") 
								#7043 Process Completed Successfully
							END IF 
							RUN "fglgo URS.4gi" 
							LET quit_flag = true 
						END IF 
					END IF 
				END IF 
			END WHILE 
			CLOSE WINDOW i179 
			LET int_flag = false 
			LET quit_flag = false 
		END IF 
	END WHILE 
	CLOSE WINDOW i138 
END FUNCTION   # IS2_main () 


FUNCTION select_ware() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pa_warehouse DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE warehouse.desc_text, 
		contact_text LIKE warehouse.contact_text, 
		tele_text LIKE warehouse.tele_text, 
		mobile_phone LIKE warehouse.mobile_phone,
		email LIKE warehouse.email,
		upd_flag CHAR(1) 
	END RECORD, 
	query_text CHAR(300), 
	where_text CHAR(500), 
	pr_scroll_flag CHAR(1), 
	upd_cnt, 
	pr_toggle_ind, 
	a,b,c,i, j, idx, scrn SMALLINT 


	CALL pa_warehouse.Clear()
	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter selection criteria - ESC TO continue
	CONSTRUCT BY NAME where_text ON ware_code, 
	desc_text, 
	contact_text, 
	tele_text,
	mobile_phone,
	email 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IS2","construct-ware_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN '' 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 Searching database - please wait
		LET query_text = "SELECT * FROM warehouse ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ware_code != '",pr_mast_code,"' ", 
		"AND ",where_text clipped," ", 
		"ORDER BY ware_code" 
		PREPARE s_warehouse FROM query_text 
		DECLARE c_warehouse CURSOR FOR s_warehouse 
		LET idx = 0 
		LET pr_toggle_ind = true 
		FOREACH c_warehouse INTO pr_warehouse.* 
			LET idx = idx + 1 
			LET pa_warehouse[idx].scroll_flag = NULL 
			LET pa_warehouse[idx].ware_code = pr_warehouse.ware_code 
			LET pa_warehouse[idx].desc_text = pr_warehouse.desc_text 
			LET pa_warehouse[idx].contact_text = pr_warehouse.contact_text 
			LET pa_warehouse[idx].tele_text = pr_warehouse.tele_text 
			LET pa_warehouse[idx].mobile_phone = pr_warehouse.mobile_phone 
			LET pa_warehouse[idx].email = pr_warehouse.email 
			LET pa_warehouse[idx].upd_flag = NULL 
			IF idx = 100 THEN 
				LET msgresp = kandoomsg("I",9161,100) 
				#9161 First 100 warehouses selected only
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 0 THEN 
			LET msgresp=kandoomsg("I",9087,"") 
			#9087 " No warehouses satisfied the selection criteria"
			LET idx = 1 
			INITIALIZE pa_warehouse[idx].* TO NULL 
		END IF 
		LET msgresp = kandoomsg("I",1035,"") 
		#1035 RETURN on line - Toggle line FOR UPDATE  F8 - Toggle all FOR UPDATE
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		CALL set_count(idx) 

		DISPLAY ARRAY pa_warehouse TO sr_warehouse.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","IS2","display-arr-warehouse") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F8) 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_warehouse[idx].ware_code IS NOT NULL THEN ## IF LINES exist 
					FOR i = 1 TO arr_count() 
						IF pa_warehouse[i].ware_code IS NOT NULL THEN 
							IF pr_toggle_ind THEN 
								LET pa_warehouse[i].upd_flag = "*" 
								LET upd_cnt = upd_cnt + 1 
							ELSE 
								LET pa_warehouse[i].upd_flag = NULL 
								LET upd_cnt = upd_cnt - 1 
							END IF 
						END IF 
					END FOR 
					IF pr_toggle_ind THEN 
						LET pr_toggle_ind = false 
					ELSE 
						LET pr_toggle_ind = true 
					END IF 
					LET j = 1 
					FOR i = ( idx - scrn + 1 ) TO ( ( idx - scrn + 1 ) + 12 - 1 ) 
						DISPLAY pa_warehouse[i].* TO sr_warehouse[j].* 

						LET j = j + 1 
					END FOR 
				END IF 
			ON KEY (tab) 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_warehouse[idx].ware_code IS NOT NULL THEN 
					IF pa_warehouse[idx].upd_flag IS NULL THEN 
						LET pa_warehouse[idx].upd_flag = "*" 
						LET upd_cnt = upd_cnt + 1 
					ELSE 
						LET pa_warehouse[idx].upd_flag = NULL 
						LET upd_cnt = upd_cnt - 1 
					END IF 
				END IF 
				DISPLAY pa_warehouse[idx].* TO sr_warehouse[scrn].* 

			ON KEY (RETURN) 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_warehouse[idx].ware_code IS NOT NULL THEN 
					IF pa_warehouse[idx].upd_flag IS NULL THEN 
						LET pa_warehouse[idx].upd_flag = "*" 
						LET upd_cnt = upd_cnt + 1 
					ELSE 
						LET pa_warehouse[idx].upd_flag = NULL 
						LET upd_cnt = upd_cnt - 1 
					END IF 
				END IF 
				DISPLAY pa_warehouse[idx].* TO sr_warehouse[scrn].* 

			ON KEY (control-w) 
				CALL kandoohelp("") 
		END DISPLAY 
		IF pa_warehouse[idx].ware_code IS NULL ## IF no LINES in ARRAY 
		OR int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN '' 
		ELSE 
			IF NOT upd_cnt THEN 
				LET msgresp = kandoomsg("I",7044,"") 
				##7044 Warning: No warehouses TO UPDATE
				RETURN '' 
			END IF 
		END IF 
		LET a = 0 
		LET b = 0 
		LET c = 0 
		LET where_text = NULL 
		LET where_text = " " clipped 
		FOR idx = 1 TO arr_count() 
			IF pa_warehouse[idx].upd_flag = '*' THEN 
				LET c = c + 1 
				LET a = (c*3) - 2 
				LET b = c*3 
				LET where_text[a,b] = pa_warehouse[idx].ware_code 
				#LET where_text = where_text , pa_warehouse[idx].ware_code
			END IF 
		END FOR 
		RETURN where_text 
	END IF 
END FUNCTION 


FUNCTION input_mast() 
	DEFINE 
	pr_desc_text LIKE warehouse.desc_text, 
	pr_temp_text CHAR(50) 

	LET msgresp = kandoomsg("I",1038,"") 
	##1038 Enter Master Warehouse code
	SELECT desc_text INTO pr_desc_text 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_mast_code 
	DISPLAY BY NAME pr_desc_text 

	INPUT BY NAME pr_mast_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS2","input-pr_mast_code-1") -- albo kd-505 
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		ON KEY (control-b) 
			LET pr_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
			IF pr_temp_text IS NOT NULL THEN 
				LET pr_mast_code = pr_temp_text 
				NEXT FIELD pr_mast_code 
			END IF 
		AFTER FIELD pr_mast_code 
			CLEAR pr_desc_text 
			IF pr_mast_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9029,"") 
				#9029 Warehouse code must be entered.
				NEXT FIELD pr_mast_code 
			ELSE 
				SELECT desc_text INTO pr_desc_text 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_mast_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9030,"") 
					#9030 Warehouse does NOT exist
					NEXT FIELD pr_mast_code 
				ELSE 
					DISPLAY BY NAME pr_desc_text 

					EXIT INPUT 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION select_attr() 
	DEFINE 
	query_text CHAR(500), 
	pr_prodstatus RECORD LIKE prodstatus.* 

	LET msgresp = kandoomsg("I",1037,"") 
	#1037 Enter price AND cost attributes  F8 - SELECT all TO UPDATE
	INPUT BY NAME upd_list_flag, 
	upd_price1_flag, 
	upd_price2_flag, 
	upd_price3_flag, 
	upd_price4_flag, 
	upd_price5_flag, 
	upd_price6_flag, 
	upd_price7_flag, 
	upd_price8_flag, 
	upd_price9_flag, 
	upd_est_flag, 
	upd_act_flag, 
	upd_for_flag, 
	upd_tax_code, 
	upd_tax_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS2","input-upd_list_flag-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (F8) 
			LET upd_list_flag = 'Y' 
			LET upd_price1_flag = 'Y' 
			LET upd_price2_flag = 'Y' 
			LET upd_price3_flag = 'Y' 
			LET upd_price4_flag = 'Y' 
			LET upd_price5_flag = 'Y' 
			LET upd_price6_flag = 'Y' 
			LET upd_price7_flag = 'Y' 
			LET upd_price8_flag = 'Y' 
			LET upd_price9_flag = 'Y' 
			LET upd_est_flag = 'Y' 
			LET upd_act_flag = 'Y' 
			LET upd_for_flag = 'Y' 
			LET upd_tax_code = 'Y' 
			LET upd_tax_amt = 'Y' 
			DISPLAY BY NAME upd_list_flag, 
			upd_price1_flag, 
			upd_price2_flag, 
			upd_price3_flag, 
			upd_price4_flag, 
			upd_price5_flag, 
			upd_price6_flag, 
			upd_price7_flag, 
			upd_price8_flag, 
			upd_price9_flag, 
			upd_est_flag, 
			upd_act_flag, 
			upd_for_flag, 
			upd_tax_code, 
			upd_tax_amt 

		AFTER FIELD upd_list_flag 
			IF upd_list_flag IS NULL THEN 
				LET upd_list_flag = 'N' 
				DISPLAY BY NAME upd_list_flag 

			END IF 
			##
			## BEFORE FIELD reqd. b/c of Informix 4.12 bug
			##   IF user hits RETURN / F8 on upd_list_flag :
			##   1) AFTER FIELD upd_list_flag executed (DISPLAY upd_list_flag=N)
			##   2) INPUT BY NAME executed *** This clears upd_list_flag ***
			##
		BEFORE FIELD upd_list_flag 
			DISPLAY BY NAME upd_list_flag 

		BEFORE FIELD upd_price1_flag 
			DISPLAY BY NAME upd_list_flag 

		AFTER FIELD upd_price1_flag 
			IF upd_price1_flag IS NULL THEN 
				LET upd_price1_flag = 'N' 
				DISPLAY BY NAME upd_price1_flag 

			END IF 
		AFTER FIELD upd_price2_flag 
			IF upd_price2_flag IS NULL THEN 
				LET upd_price2_flag = 'N' 
				DISPLAY BY NAME upd_price2_flag 

			END IF 
		AFTER FIELD upd_price3_flag 
			IF upd_price3_flag IS NULL THEN 
				LET upd_price3_flag = 'N' 
				DISPLAY BY NAME upd_price3_flag 

			END IF 
		AFTER FIELD upd_price4_flag 
			IF upd_price4_flag IS NULL THEN 
				LET upd_price4_flag = 'N' 
				DISPLAY BY NAME upd_price4_flag 

			END IF 
		AFTER FIELD upd_price5_flag 
			IF upd_price5_flag IS NULL THEN 
				LET upd_price5_flag = 'N' 
				DISPLAY BY NAME upd_price5_flag 

			END IF 
		AFTER FIELD upd_price6_flag 
			IF upd_price6_flag IS NULL THEN 
				LET upd_price6_flag = 'N' 
				DISPLAY BY NAME upd_price6_flag 

			END IF 
		AFTER FIELD upd_price7_flag 
			IF upd_price7_flag IS NULL THEN 
				LET upd_price7_flag = 'N' 
				DISPLAY BY NAME upd_price7_flag 

			END IF 
		AFTER FIELD upd_price8_flag 
			IF upd_price8_flag IS NULL THEN 
				LET upd_price8_flag = 'N' 
				DISPLAY BY NAME upd_price8_flag 

			END IF 
		AFTER FIELD upd_price9_flag 
			IF upd_price9_flag IS NULL THEN 
				LET upd_price9_flag = 'N' 
				DISPLAY BY NAME upd_price9_flag 

			END IF 
		AFTER FIELD upd_est_flag 
			IF upd_est_flag IS NULL THEN 
				LET upd_est_flag = 'N' 
				DISPLAY BY NAME upd_est_flag 

			END IF 
		AFTER FIELD upd_act_flag 
			IF upd_act_flag IS NULL THEN 
				LET upd_act_flag = 'N' 
				DISPLAY BY NAME upd_act_flag 

			END IF 
		AFTER FIELD upd_for_flag 
			IF upd_for_flag IS NULL THEN 
				LET upd_for_flag = 'N' 
				DISPLAY BY NAME upd_for_flag 

			END IF 
		AFTER FIELD upd_tax_code 
			IF upd_tax_code IS NULL THEN 
				LET upd_tax_code = 'N' 
				DISPLAY BY NAME upd_tax_code 

			END IF 
		AFTER FIELD upd_tax_amt 
			IF upd_tax_amt IS NULL THEN 
				LET upd_tax_amt = 'N' 
				DISPLAY BY NAME upd_tax_amt 

			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF upd_list_flag IS NULL THEN 
					LET upd_list_flag = 'N' 
				END IF 
				IF upd_price1_flag IS NULL THEN 
					LET upd_price1_flag = 'N' 
				END IF 
				IF upd_price2_flag IS NULL THEN 
					LET upd_price2_flag = 'N' 
				END IF 
				IF upd_price3_flag IS NULL THEN 
					LET upd_price3_flag = 'N' 
				END IF 
				IF upd_price4_flag IS NULL THEN 
					LET upd_price4_flag = 'N' 
				END IF 
				IF upd_price5_flag IS NULL THEN 
					LET upd_price5_flag = 'N' 
				END IF 
				IF upd_price6_flag IS NULL THEN 
					LET upd_price6_flag = 'N' 
				END IF 
				IF upd_price7_flag IS NULL THEN 
					LET upd_price7_flag = 'N' 
				END IF 
				IF upd_price8_flag IS NULL THEN 
					LET upd_price8_flag = 'N' 
				END IF 
				IF upd_price9_flag IS NULL THEN 
					LET upd_price9_flag = 'N' 
				END IF 
				IF upd_est_flag IS NULL THEN 
					LET upd_est_flag = 'N' 
				END IF 
				IF upd_act_flag IS NULL THEN 
					LET upd_act_flag = 'N' 
				END IF 
				IF upd_for_flag IS NULL THEN 
					LET upd_for_flag = 'N' 
				END IF 
				IF upd_tax_code IS NULL THEN 
					LET upd_tax_code = 'N' 
				END IF 
				IF upd_tax_amt IS NULL THEN 
					LET upd_tax_amt = 'N' 
				END IF 
				DISPLAY BY NAME upd_list_flag, 
				upd_price1_flag, 
				upd_price2_flag, 
				upd_price3_flag, 
				upd_price4_flag, 
				upd_price5_flag, 
				upd_price6_flag, 
				upd_price7_flag, 
				upd_price8_flag, 
				upd_price9_flag, 
				upd_est_flag, 
				upd_act_flag, 
				upd_for_flag, 
				upd_tax_code, 
				upd_tax_amt 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_info() 
	DEFINE 
	query_text CHAR(1400) 

	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter selection criteria - ESC TO continue
	CONSTRUCT BY NAME where1_text ON product.part_code, 
	product.prodgrp_code, 
	product.maingrp_code, 
	product.vend_code, 
	product.cat_code, 
	prodstatus.last_price_date, 
	prodstatus.last_list_date, 
	prodstatus.last_cost_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IS2","construct-product-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET msgresp = kandoomsg("I",1002,"") 
		#1002 Searching database - please wait
		LET query_text = "SELECT prodstatus.*, product.* ", 
		"FROM prodstatus, product ", 
		"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND prodstatus.part_code = product.part_code ", 
		"AND prodstatus.ware_code = '",pr_mast_code,"' ", 
		"AND ",where1_text clipped," ", 
		"ORDER BY product.part_code" 
		PREPARE s_product FROM query_text 
		DECLARE c_product CURSOR with HOLD FOR s_product 
		LET query_text = "SELECT * ", 
		"FROM prodstatus ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND part_code = ? ", 
		"AND ware_code = ? ", 
		"FOR UPDATE " 
		PREPARE s_prodstatus FROM query_text 
		DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION update_price(pr_temp_text) 
	DEFINE 
	pr_tax RECORD LIKE tax.*, 
	pr_temp_text, 
	ps_temp_text CHAR(500), 
	pr_product RECORD LIKE product.*, 
	pr_flex_num INTEGER, 
	pr_class RECORD LIKE class.*, 
	pr_part_code CHAR(16), 
	pr_parent, pr_filler, pr_flex_part LIKE product.part_code, 
	pr_prodstatus, 
	ps_prodstatus, 
	pt_prodstatus RECORD LIKE prodstatus.*, 
	pr_ware_code LIKE warehouse.ware_code, 
	pr_tax_amt LIKE prodstatus.purch_tax_amt, 
	pr_output CHAR(50), 
	err_message CHAR(80), 
	pr_part_len, pr_parent_len LIKE prodstructure.length, 
	pr_segs_ind, pr_update_reqd SMALLINT, 
	err_cnt INTEGER 

	LET glob_rec_kandooreport.report_code = "IS2" 
	CALL kandooreport( glob_rec_kandoouser.cmpy_code, glob_rec_kandooreport.report_code ) 
	RETURNING glob_rec_kandooreport.* 
	##IF glob_rec_kandooreport.header_text IS NULL THEN
	CALL set_defaults() 
	##END IF
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	START REPORT is2_list TO pr_output 
	LET msgresp = kandoomsg("I",1005,"") 
	#1005 Updating Database - pls wait
	--   OPEN WINDOW w1 AT 10,10 with 3 rows,60 columns  -- albo  KD-758
	--      ATTRIBUTE(border)
	LET msgresp = kandoomsg("I",1036,"") 
	#1036 Updating Product:                 AT Warehouse:
	OPEN c_product 
	FOREACH c_product INTO pr_prodstatus.*, 
		pr_product.* 
		LET ps_temp_text = pr_temp_text 
		WHILE ps_temp_text[1,3] != ' ' 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				#8031 Company pricing process interrupted - Confirm TO abort (Y/N)?
				IF kandoomsg("I",8031,"") = 'Y' THEN 
					FINISH REPORT is2_list 
					CALL upd_reports( pr_output, 
					rpt_pageno, 
					glob_rec_kandooreport.width_num, 
					glob_rec_kandooreport.length_num ) 
					--               CLOSE WINDOW w1  -- albo  KD-758
					RETURN err_cnt 
				END IF 
			END IF 
			CALL break_prod(glob_rec_kandoouser.cmpy_code,pr_prodstatus.part_code,pr_product.class_code,1) 
			RETURNING pr_parent, 
			pr_filler, 
			pr_flex_part, 
			pr_flex_num 
			IF pr_parent != pr_prodstatus.part_code THEN 
				CONTINUE FOREACH 
			END IF 
			INITIALIZE pr_class.* TO NULL 
			SELECT * INTO pr_class.* FROM class 
			WHERE cmpy_code = pr_product.cmpy_code 
			AND class_code = pr_product.class_code 

			IF pr_class.price_level_ind IS NULL THEN 
				LET pr_class.price_level_ind = 1 
			END IF 
			IF pr_class.ord_level_ind IS NULL THEN 
				LET pr_class.ord_level_ind = 1 
			END IF 
			IF pr_class.stock_level_ind IS NULL THEN 
				LET pr_class.stock_level_ind = 1 
			END IF 
			# IF product = parent AND structure IS truely segmented (ie NOT
			# 1 1 1 OR 2 2 2 OR 3 3 3 etc) THEN dont UPDATE child prices.

			SELECT sum(p.length) INTO pr_part_len 
			FROM prodstructure p 
			WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND p.class_code = pr_class.class_code 
			IF pr_part_len IS NULL THEN 
				LET pr_part_len = 0 
			END IF 
			SELECT sum(p.length) INTO pr_parent_len 
			FROM prodstructure p 
			WHERE p.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND p.class_code = pr_class.class_code 
			AND p.seq_num <= pr_class.price_level_ind 
			IF pr_parent_len IS NULL THEN 
				LET pr_parent_len = 15 
			END IF 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" 
			AND pr_parent_len < pr_part_len THEN 
				LET pr_part_code = pr_prodstatus.part_code clipped, "*" 
				LET pr_segs_ind = true 
			ELSE 
				LET pr_part_code = pr_prodstatus.part_code 
				LET pr_segs_ind = false 
			END IF 

			#IF pr_class.price_level_ind != pr_class.stock_level_ind THEN
			#LET pr_part_code = pr_prodstatus.part_code clipped, "*"
			#ELSE
			#LET pr_part_code = pr_prodstatus.part_code
			#END IF
			LET pr_ware_code = ps_temp_text[1,3] ## ware_code char(3) 
			LET ps_temp_text = ps_temp_text[4,500] ## get NEXT warehouse 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "Error locking Product (", 
				pr_prodstatus.part_code,")", 
				" AT Warehouse (",pr_ware_code,")", 
				" - Rerun UPDATE" 
				OPEN c_prodstatus USING pr_prodstatus.part_code, 
				pr_ware_code 
				FETCH c_prodstatus INTO ps_prodstatus.* 
				IF sqlca.sqlcode = 0 THEN 
					## A copy of the original prodstatus IS made b/c :
					## 1) reqd. FOR reporting purposes
					## 2) locking OR UPDATE problem will OUTPUT nothing TO REPORT
					LET pt_prodstatus.* = ps_prodstatus.* ## used FOR reporting 
					LET pr_update_reqd = false 
					IF upd_list_flag = 'Y' THEN 
						IF ps_prodstatus.list_amt != pr_prodstatus.list_amt 
						OR ps_prodstatus.list_amt IS NULL THEN 
							LET ps_prodstatus.list_amt = pr_prodstatus.list_amt 
							LET ps_prodstatus.last_price_date = today 
							LET ps_prodstatus.last_list_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price1_flag = 'Y' THEN 
						IF ps_prodstatus.price1_amt != pr_prodstatus.price1_amt 
						OR ps_prodstatus.price1_amt IS NULL THEN 
							LET ps_prodstatus.price1_amt = pr_prodstatus.price1_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price2_flag = 'Y' THEN 
						IF ps_prodstatus.price2_amt != pr_prodstatus.price2_amt 
						OR ps_prodstatus.price2_amt IS NULL THEN 
							LET ps_prodstatus.price2_amt = pr_prodstatus.price2_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price3_flag = 'Y' THEN 
						IF ps_prodstatus.price3_amt != pr_prodstatus.price3_amt 
						OR ps_prodstatus.price3_amt IS NULL THEN 
							LET ps_prodstatus.price3_amt = pr_prodstatus.price3_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price4_flag = 'Y' THEN 
						IF ps_prodstatus.price4_amt != pr_prodstatus.price4_amt 
						OR ps_prodstatus.price4_amt IS NULL THEN 
							LET ps_prodstatus.price4_amt = pr_prodstatus.price4_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price5_flag = 'Y' THEN 
						IF ps_prodstatus.price5_amt != pr_prodstatus.price5_amt 
						OR ps_prodstatus.price5_amt IS NULL THEN 
							LET ps_prodstatus.price5_amt = pr_prodstatus.price5_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price6_flag = 'Y' THEN 
						IF ps_prodstatus.price6_amt != pr_prodstatus.price6_amt 
						OR ps_prodstatus.price6_amt IS NULL THEN 
							LET ps_prodstatus.price6_amt = pr_prodstatus.price6_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price7_flag = 'Y' THEN 
						IF ps_prodstatus.price7_amt != pr_prodstatus.price7_amt 
						OR ps_prodstatus.price7_amt IS NULL THEN 
							LET ps_prodstatus.price7_amt = pr_prodstatus.price7_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price8_flag = 'Y' THEN 
						IF ps_prodstatus.price8_amt != pr_prodstatus.price8_amt 
						OR ps_prodstatus.price8_amt IS NULL THEN 
							LET ps_prodstatus.price8_amt = pr_prodstatus.price8_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_price9_flag = 'Y' THEN 
						IF ps_prodstatus.price9_amt != pr_prodstatus.price9_amt 
						OR ps_prodstatus.price9_amt IS NULL THEN 
							LET ps_prodstatus.price9_amt = pr_prodstatus.price9_amt 
							LET ps_prodstatus.last_price_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_est_flag = 'Y' THEN 
						IF ps_prodstatus.est_cost_amt!=pr_prodstatus.est_cost_amt 
						OR ps_prodstatus.est_cost_amt IS NULL THEN 
							LET ps_prodstatus.est_cost_amt = pr_prodstatus.est_cost_amt 
							LET ps_prodstatus.last_cost_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_act_flag = 'Y' THEN 
						IF ps_prodstatus.act_cost_amt!=pr_prodstatus.act_cost_amt 
						OR ps_prodstatus.act_cost_amt IS NULL THEN 
							LET ps_prodstatus.act_cost_amt = pr_prodstatus.act_cost_amt 
							LET ps_prodstatus.last_cost_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_tax_code = 'Y' THEN 
						IF ps_prodstatus.purch_tax_code!=pr_prodstatus.purch_tax_code 
						OR ps_prodstatus.purch_tax_code IS NULL THEN 
							LET ps_prodstatus.purch_tax_code = pr_prodstatus.purch_tax_code 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_for_flag = 'Y' THEN 
						IF ps_prodstatus.for_cost_amt!=pr_prodstatus.for_cost_amt 
						OR ps_prodstatus.for_curr_code!=pr_prodstatus.for_curr_code 
						OR ps_prodstatus.for_cost_amt IS NULL 
						OR ps_prodstatus.for_curr_code IS NULL THEN 
							LET ps_prodstatus.for_cost_amt = pr_prodstatus.for_cost_amt 
							LET ps_prodstatus.for_curr_code = pr_prodstatus.for_curr_code 
							LET ps_prodstatus.last_cost_date = today 
							LET pr_update_reqd = true 
						END IF 
					END IF 
					IF upd_tax_code = 'Y' 
					OR upd_for_flag = 'Y' THEN 
						SELECT * INTO pr_tax.* FROM tax 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tax_code = ps_prodstatus.purch_tax_code 
						IF status = notfound THEN 
							LET err_message = "Logic Error: Tax Code \"", 
							ps_prodstatus.purch_tax_code,"\" NOT found" 
							GOTO recovery 
						END IF 
						IF pr_tax.calc_method_flag = "I" THEN 
							LET pr_tax_amt = ps_prodstatus.purch_tax_amt 
							LET ps_prodstatus.purch_tax_amt = 
							(ps_prodstatus.for_cost_amt/(1+(pr_tax.tax_per/100))) 
							-ps_prodstatus.for_cost_amt 
							IF pr_tax_amt <> ps_prodstatus.purch_tax_amt THEN 
								LET pr_update_reqd = true 
							END IF 
						END IF 
					END IF 
					IF upd_tax_amt = 'Y' THEN 
						IF ps_prodstatus.purch_tax_amt!=pr_prodstatus.purch_tax_amt 
						OR ps_prodstatus.purch_tax_amt IS NULL THEN 
							SELECT * INTO pr_tax.* FROM tax 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND tax_code = ps_prodstatus.purch_tax_code 
							IF status = notfound THEN 
								LET err_message = "Logic Error: Tax code \"", 
								ps_prodstatus.purch_tax_code,"\" NOT found" 
								GOTO recovery 
							END IF 
							IF pr_tax.calc_method_flag <> "I" THEN 

								LET ps_prodstatus.purch_tax_amt = pr_prodstatus.purch_tax_amt 
								LET pr_update_reqd = true 
							END IF 
						END IF 
					END IF 

					# Display
					DISPLAY " " at 1,21 
					DISPLAY "" at 1,51 
					DISPLAY ps_prodstatus.part_code at 1,21 

					DISPLAY ps_prodstatus.ware_code at 1,51 

					IF pr_update_reqd THEN 
						LET err_message = "Error updating Product (", 
						ps_prodstatus.part_code,")", 
						" AT Warehouse (", 
						ps_prodstatus.ware_code,")", 
						" - Rerun UPDATE" 
						IF pr_segs_ind THEN 
							UPDATE prodstatus 
							SET list_amt = ps_prodstatus.list_amt, 
							price1_amt = ps_prodstatus.price1_amt, 
							price2_amt = ps_prodstatus.price2_amt, 
							price3_amt = ps_prodstatus.price3_amt, 
							price4_amt = ps_prodstatus.price4_amt, 
							price5_amt = ps_prodstatus.price5_amt, 
							price6_amt = ps_prodstatus.price6_amt, 
							price7_amt = ps_prodstatus.price7_amt, 
							price8_amt = ps_prodstatus.price8_amt, 
							price9_amt = ps_prodstatus.price9_amt, 
							price9_amt = ps_prodstatus.price9_amt, 
							last_price_date = ps_prodstatus.last_price_date, 
							last_list_date = ps_prodstatus.last_list_date, 
							est_cost_amt = ps_prodstatus.est_cost_amt, 
							act_cost_amt = ps_prodstatus.act_cost_amt, 
							for_cost_amt = ps_prodstatus.for_cost_amt, 
							for_curr_code = ps_prodstatus.for_curr_code, 
							purch_tax_amt = ps_prodstatus.purch_tax_amt, 
							purch_tax_code = ps_prodstatus.purch_tax_code, 
							last_cost_date = ps_prodstatus.last_cost_date 
							WHERE part_code matches pr_part_code 
							AND ware_code = ps_prodstatus.ware_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code in 
							(SELECT part_code FROM product 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND part_code matches pr_part_code 
							AND class_code = pr_class.class_code) 
						ELSE 
							UPDATE prodstatus 
							SET list_amt = ps_prodstatus.list_amt, 
							price1_amt = ps_prodstatus.price1_amt, 
							price2_amt = ps_prodstatus.price2_amt, 
							price3_amt = ps_prodstatus.price3_amt, 
							price4_amt = ps_prodstatus.price4_amt, 
							price5_amt = ps_prodstatus.price5_amt, 
							price6_amt = ps_prodstatus.price6_amt, 
							price7_amt = ps_prodstatus.price7_amt, 
							price8_amt = ps_prodstatus.price8_amt, 
							price9_amt = ps_prodstatus.price9_amt, 
							price9_amt = ps_prodstatus.price9_amt, 
							last_price_date = ps_prodstatus.last_price_date, 
							last_list_date = ps_prodstatus.last_list_date, 
							est_cost_amt = ps_prodstatus.est_cost_amt, 
							act_cost_amt = ps_prodstatus.act_cost_amt, 
							for_cost_amt = ps_prodstatus.for_cost_amt, 
							for_curr_code = ps_prodstatus.for_curr_code, 
							purch_tax_amt = ps_prodstatus.purch_tax_amt, 
							purch_tax_code = ps_prodstatus.purch_tax_code, 
							last_cost_date = ps_prodstatus.last_cost_date 
							WHERE part_code matches pr_part_code 
							AND ware_code = ps_prodstatus.ware_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
						OUTPUT TO REPORT is2_list(pr_product.*, 
						pt_prodstatus.*, ## original 
						ps_prodstatus.*) ## new 
					END IF 
				END IF 
			COMMIT WORK 
			WHENEVER ERROR stop 
			CONTINUE WHILE 
			LABEL recovery: 
			ROLLBACK WORK 
			LET err_cnt = err_cnt + 1 
			CALL errorlog(err_message) 
		END WHILE 
	END FOREACH 
	FINISH REPORT is2_list 
	CALL upd_reports( pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num ) 
	--   CLOSE WINDOW w1  -- albo  KD-758
	RETURN err_cnt 
END FUNCTION 


REPORT is2_list(pr_product, pr_prodstatus, ps_prodstatus) 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus, 
	ps_prodstatus RECORD LIKE prodstatus.*, 
	pr_change_per FLOAT, 
	pa_line array[4] OF CHAR(132), 
	pr_temp_text CHAR(50), 
	i SMALLINT 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_prodstatus.part_code, 
	ps_prodstatus.ware_code 
	FORMAT 
		PAGE HEADER 
			CALL report_header(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.*,pageno) 
			RETURNING pa_line[1],pa_line[2],pa_line[3],pa_line[4] 
			PRINT COLUMN 01,pa_line[1] 
			PRINT COLUMN 01,pa_line[2] 
			PRINT COLUMN 01,pa_line[3] 
			PRINT COLUMN 01, glob_rec_kandooreport.line1_text clipped 
			PRINT COLUMN 01, glob_rec_kandooreport.line2_text clipped 
			PRINT COLUMN 01,pa_line[3] 

		ON EVERY ROW 
			NEED 6 LINES 
			PRINT COLUMN 1, pr_product.part_code, 
			COLUMN 17, pr_product.desc_text[1,23], 
			COLUMN 41, pr_prodstatus.ware_code, 
			COLUMN 46, pr_product.stock_uom_code, 
			COLUMN 50, pr_prodstatus.list_amt USING "--,---,-$&.&&", 
			COLUMN 65, pr_prodstatus.price1_amt USING "--,---,-$&.&&", 
			COLUMN 80, pr_prodstatus.price2_amt USING "--,---,-$&.&&", 
			COLUMN 95, pr_prodstatus.price3_amt USING "--,---,-$&.&&", 
			COLUMN 110, pr_prodstatus.price4_amt USING "--,---,-$&.&&" 
			PRINT COLUMN 50, pr_prodstatus.price5_amt USING "--,---,-$&.&&", 
			COLUMN 65, pr_prodstatus.price6_amt USING "--,---,-$&.&&", 
			COLUMN 80, pr_prodstatus.price7_amt USING "--,---,-$&.&&", 
			COLUMN 95, pr_prodstatus.price8_amt USING "--,---,-$&.&&", 
			COLUMN 110, pr_prodstatus.price9_amt USING "--,---,-$&.&&" 
			PRINT COLUMN 76, "----- Changed TO -----" 
			IF pr_prodstatus.list_amt = 0 THEN 
				# Percent change WHEN list_price changes FROM 0 TO ? indifferent
				# so force REPORT TO PRINT ***** TO show this
				LET pr_change_per = 99999 
			ELSE 
				LET pr_change_per=(((pr_prodstatus.list_amt - ps_prodstatus.list_amt) 
				/ pr_prodstatus.list_amt) * 100) 
			END IF 
			PRINT COLUMN 50, ps_prodstatus.list_amt USING "--,---,-$&.&&", 
			COLUMN 65, ps_prodstatus.price1_amt USING "--,---,-$&.&&", 
			COLUMN 80, ps_prodstatus.price2_amt USING "--,---,-$&.&&", 
			COLUMN 95, ps_prodstatus.price3_amt USING "--,---,-$&.&&", 
			COLUMN 110, ps_prodstatus.price4_amt USING "--,---,-$&.&&" 
			PRINT COLUMN 50, ps_prodstatus.price5_amt USING "--,---,-$&.&&", 
			COLUMN 65, ps_prodstatus.price6_amt USING "--,---,-$&.&&", 
			COLUMN 80, ps_prodstatus.price7_amt USING "--,---,-$&.&&", 
			COLUMN 95, ps_prodstatus.price8_amt USING "--,---,-$&.&&", 
			COLUMN 110, ps_prodstatus.price9_amt USING "--,---,-$&.&&", 
			COLUMN 124, pr_change_per USING "---&.##" 
			SKIP 1 line 
		ON LAST ROW 
			SKIP 3 LINES 
			PRINT COLUMN 01,pa_line[4] 
			LET i = glob_rec_kandooreport.width_num - 10 
			IF glob_rec_kandooreport.selection_flag = "Y" THEN 
				LET pr_temp_text = kandooword("Selection Criteria:","046") 
				PRINT COLUMN 10, pr_temp_text clipped, 
				COLUMN 25, where1_text clipped wordwrap right margin i 
			END IF 
			LET rpt_pageno = pageno 
END REPORT 


FUNCTION set_defaults() 
	LET glob_rec_kandooreport.header_text = "Company Wide Pricing Report" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "IS2" 
	LET glob_rec_kandooreport.selection_flag = "Y" 
	LET glob_rec_kandooreport.line1_text = "MASTER WAREHOUSE: ",pr_mast_code, 
	" ", 
	" Stock List Level 1", 
	" Level 2 Level 3 Level 4 List %" 
	LET glob_rec_kandooreport.line2_text = "Product Code Description Warehouse", 
	" Unit Level 5 Level 6", 
	" Level 7 Level 8 Level 9 Change" 
	UPDATE kandooreport SET * = glob_rec_kandooreport.* 
	WHERE report_code = glob_rec_kandooreport.report_code 
	AND language_code = glob_rec_kandooreport.language_code 
END FUNCTION 
