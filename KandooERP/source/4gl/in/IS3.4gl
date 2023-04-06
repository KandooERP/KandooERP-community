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

	Source code beautified by beautify.pl on 2020-01-03 09:12:40	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS3 Automatically Adjusts Product Prices

GLOBALS 
	DEFINE 
	pr_inparms RECORD LIKE inparms.*, 
	pr_glparms RECORD LIKE glparms.*, 
	rpt_pageno LIKE rmsreps.page_num, 
	pr_mast_code LIKE inparms.mast_ware_code, 
	where1_text char(800), ## global b/c reqd. FOR REPORT 
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
	upd_price9_flag CHAR(1), 
	default_duty_per LIKE tariff.duty_per, 
	exchange_date DATE 
END GLOBALS 


####################################################################
# MAIN
####################################################################
MAIN 
	DEFINE err_cnt INTEGER 
	#Initial UI Init
	CALL setModuleId("IS3") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",9002,"") 
		##9002 Inventory parameters NOT SET up - Refer IZP
		EXIT program 
	END IF 
	OPEN WINDOW i152 with FORM "I152" 
	 CALL windecoration_i("I152") -- albo kd-758 
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
	LET default_duty_per= 0 
	LET exchange_date = today 
	WHILE NOT ( int_flag OR quit_flag ) 
		IF select_attr() THEN 
			IF scan_info() THEN 
				IF kandoomsg("I",8030,"") = 'Y' THEN 
					LET err_cnt = auto_price_update() 
					IF err_cnt THEN 
						LET msgresp = kandoomsg("I",7045,err_cnt) 
						#7045 Process completed with errors - Refer get_settings_logFile()
					ELSE 
						LET msgresp = kandoomsg("I",7046,"") 
						#7046 Process Completed Successfully
					END IF 
					CALL run_prog("URS","","","","") -- ON ACTION "Print Manager" 
				END IF 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW i152 
	LET int_flag = false 
	LET quit_flag = false 
END MAIN 


FUNCTION select_attr() 
	DEFINE 
	query_text CHAR(500), 
	pr_prodstatus RECORD LIKE prodstatus.* 

	LET msgresp = kandoomsg("I",1041,"") 
	#1041 Enter price attributes  F8 - SELECT all TO UPDATE
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
	default_duty_per, 
	exchange_date WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IS3","input-upd_list_flag-1") -- albo kd-505 

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
			DISPLAY BY NAME upd_list_flag, 
			upd_price1_flag, 
			upd_price2_flag, 
			upd_price3_flag, 
			upd_price4_flag, 
			upd_price5_flag, 
			upd_price6_flag, 
			upd_price7_flag, 
			upd_price8_flag, 
			upd_price9_flag 

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
		AFTER FIELD default_duty_per 
			IF default_duty_per IS NULL THEN 
				LET default_duty_per = 0 
				DISPLAY BY NAME default_duty_per 

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
				DISPLAY BY NAME upd_list_flag, 
				upd_price1_flag, 
				upd_price2_flag, 
				upd_price3_flag, 
				upd_price4_flag, 
				upd_price5_flag, 
				upd_price6_flag, 
				upd_price7_flag, 
				upd_price8_flag, 
				upd_price9_flag 

				IF default_duty_per IS NULL THEN 
					LET default_duty_per = 0 
				END IF 
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
	query_text CHAR(800) 

	LET msgresp = kandoomsg("I",1001,"") 
	#1001 Enter selection criteria - ESC TO continue
	CONSTRUCT BY NAME where1_text ON prodstatus.ware_code, 
	prodstatus.part_code, 
	product.desc_text, 
	product.desc2_text, 
	product.prodgrp_code, 
	product.maingrp_code, 
	product.cat_code, 
	product.oem_text, 
	product.class_code, 
	product.vend_code, 
	prodstatus.last_price_date, 
	prodstatus.last_list_date, 
	prodstatus.last_cost_date 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IS3","construct-prodstatus-1") -- albo kd-505 

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
		LET query_text = "SELECT prodstatus.*, ", 
		"product.* ", 
		"FROM prodstatus, product ", 
		"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND prodstatus.part_code = product.part_code ", 
		"AND product.status_ind <> '3' ", 
		"AND prodstatus.status_ind <> '3' ", 
		"AND product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where1_text clipped," ", 
		"ORDER BY prodstatus.ware_code,", 
		"prodstatus.part_code,", 
		"product.prodgrp_code,", 
		"product.maingrp_code" 
		PREPARE s_prodstatus FROM query_text 
		DECLARE c_prodstatus CURSOR with HOLD FOR s_prodstatus 
		LET query_text = "SELECT * ", 
		"FROM prodstatus ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND part_code = ? ", 
		"AND ware_code = ? ", 
		"FOR UPDATE " 
		PREPARE s1_prodstatus FROM query_text 
		DECLARE c1_prodstatus CURSOR with HOLD FOR s1_prodstatus 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION auto_price_update() 
	DEFINE 
	pr_temp_text, 
	ps_temp_text CHAR(500), 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus, 
	ps_prodstatus, 
	pt_prodstatus RECORD LIKE prodstatus.*, 
	pr_class RECORD LIKE class.*, 
	pr_ware_code LIKE warehouse.ware_code, 
	pr_part_code CHAR(16), 
	pr_parent, pr_filler, pr_flex_part LIKE product.part_code, 
	pr_updated_flag CHAR(1), 
	pr_part_len, pr_parent_len LIKE prodstructure.length, 
	pr_flex_num INTEGER, 
	pr_output CHAR(50), 
	pr_mult_segs SMALLINT, 
	err_message CHAR(80), 
	err_cnt INTEGER 

	LET glob_rec_kandooreport.report_code = "IS3" 
	CALL kandooreport( glob_rec_kandoouser.cmpy_code, glob_rec_kandooreport.report_code ) 
	RETURNING glob_rec_kandooreport.* 
	CALL set_defaults() 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	START REPORT is3_list TO pr_output 
	LET msgresp = kandoomsg("I",1005,"") 
	#1005 Updating Database - pls wait
	--   OPEN WINDOW w1 AT 10,10 with 3 rows,60 columns  -- albo  KD-758
	--      ATTRIBUTE(border,yellow)
	LET msgresp = kandoomsg("I",1036,"") 
	#1036 Updating Product:                 AT Warehouse:
	OPEN c_prodstatus 
	FOREACH c_prodstatus INTO pr_prodstatus.*, 
		pr_product.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			#8033 Auto-price level process interrupted - Confirm TO abort (Y/N)?
			IF kandoomsg("I",8033,"") = 'Y' THEN 
				FINISH REPORT is3_list 
				CALL upd_reports( pr_output, 
				rpt_pageno, 
				glob_rec_kandooreport.width_num, 
				glob_rec_kandooreport.length_num ) 
				--            CLOSE WINDOW w1  -- albo  KD-758
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
		CALL update_pricing( upd_list_flag, 
		upd_price1_flag, 
		upd_price2_flag, 
		upd_price3_flag, 
		upd_price4_flag, 
		upd_price5_flag, 
		upd_price6_flag, 
		upd_price7_flag, 
		upd_price8_flag, 
		upd_price9_flag, 
		pr_prodstatus.*, 
		pr_product.* ) 
		RETURNING pr_prodstatus.*, 
		pr_updated_flag 

		IF pr_updated_flag = 'Y' THEN 
			# Display
			DISPLAY " " at 1,21 
			DISPLAY "" at 1,51 
			DISPLAY pr_prodstatus.part_code at 1,21 

			DISPLAY pr_prodstatus.ware_code at 1,51 

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
				LET pr_mult_segs = true 
			ELSE 
				LET pr_part_code = pr_prodstatus.part_code 
				LET pr_mult_segs = false 
			END IF 

			#IF pr_class.price_level_ind != pr_class.stock_level_ind THEN
			#LET pr_part_code = pr_prodstatus.part_code clipped, "*"
			#ELSE
			#LET pr_part_code = pr_prodstatus.part_code
			#END IF
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				LET err_message = "Error locking Product (", 
				pr_prodstatus.part_code,")", 
				" AT Warehouse (",pr_prodstatus.ware_code,")", 
				" - Rerun UPDATE" 
				OPEN c1_prodstatus USING pr_prodstatus.part_code, 
				pr_prodstatus.ware_code 
				FETCH c1_prodstatus INTO ps_prodstatus.* 
				IF sqlca.sqlcode = 0 THEN 
					LET err_message = "Error updating Product (", 
					pr_prodstatus.part_code,")", 
					" AT Warehouse (", 
					pr_prodstatus.ware_code,")", 
					" - Rerun UPDATE" 
					IF pr_mult_segs THEN 
						UPDATE prodstatus 
						SET list_amt = pr_prodstatus.list_amt, 
						price1_amt = pr_prodstatus.price1_amt, 
						price2_amt = pr_prodstatus.price2_amt, 
						price3_amt = pr_prodstatus.price3_amt, 
						price4_amt = pr_prodstatus.price4_amt, 
						price5_amt = pr_prodstatus.price5_amt, 
						price6_amt = pr_prodstatus.price6_amt, 
						price7_amt = pr_prodstatus.price7_amt, 
						price8_amt = pr_prodstatus.price8_amt, 
						price9_amt = pr_prodstatus.price9_amt, 
						last_list_date = pr_prodstatus.last_list_date, 
						last_price_date = pr_prodstatus.last_price_date 
						WHERE part_code matches pr_part_code 
						AND ware_code = pr_prodstatus.ware_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code in 
						(SELECT part_code FROM product 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code matches pr_part_code 
						AND class_code = pr_class.class_code) 
					ELSE 
						UPDATE prodstatus 
						SET list_amt = pr_prodstatus.list_amt, 
						price1_amt = pr_prodstatus.price1_amt, 
						price2_amt = pr_prodstatus.price2_amt, 
						price3_amt = pr_prodstatus.price3_amt, 
						price4_amt = pr_prodstatus.price4_amt, 
						price5_amt = pr_prodstatus.price5_amt, 
						price6_amt = pr_prodstatus.price6_amt, 
						price7_amt = pr_prodstatus.price7_amt, 
						price8_amt = pr_prodstatus.price8_amt, 
						price9_amt = pr_prodstatus.price9_amt, 
						last_list_date = pr_prodstatus.last_list_date, 
						last_price_date = pr_prodstatus.last_price_date 
						WHERE part_code matches pr_part_code 
						AND ware_code = pr_prodstatus.ware_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
					OUTPUT TO REPORT is3_list( pr_product.*, 
					ps_prodstatus.*, ## original 
					pr_prodstatus.* ) ## latest 
				END IF 
			COMMIT WORK 
			WHENEVER ERROR stop 
			CONTINUE FOREACH 

			LABEL recovery: 
			ROLLBACK WORK 
			LET err_cnt = err_cnt + 1 
			CALL errorlog(err_message) 
		END IF 
	END FOREACH 
	FINISH REPORT is3_list 
	CALL upd_reports( pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num ) 
	--   CLOSE WINDOW w1  -- albo  KD-758
	RETURN err_cnt 
END FUNCTION 


FUNCTION update_pricing( upd_list_flag, upd_price1_flag, upd_price2_flag, 
	upd_price3_flag, upd_price4_flag, upd_price5_flag, 
	upd_price6_flag, upd_price7_flag, upd_price8_flag, 
	upd_price9_flag, pr_prodstatus, pr_product) 
	DEFINE 
	upd_list_flag, 
	upd_price1_flag, 
	upd_price2_flag, 
	upd_price3_flag, 
	upd_price4_flag, 
	upd_price5_flag, 
	upd_price6_flag, 
	upd_price7_flag, 
	upd_price8_flag, 
	upd_price9_flag CHAR(1), 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_product RECORD LIKE product.*, 
	pr_updated_flag CHAR(1), 
	pr_category RECORD LIKE category.*, 
	pr_tmp_amt LIKE prodstatus.list_amt 

	LET pr_updated_flag = 'N' 

	SELECT * INTO pr_category.* 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 

	IF upd_list_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('L', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.list_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.list_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_prodstatus.last_list_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price1_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('1', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price1_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price1_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price2_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('2', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price2_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price2_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price3_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('3', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price3_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price3_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price4_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('4', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price4_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price4_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price5_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('5', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price5_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price5_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price6_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('6', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price6_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price6_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price7_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('7', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price7_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price7_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price8_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price('8', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price8_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price8_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 

	IF upd_price9_flag = 'Y' THEN 
		LET pr_tmp_amt = calculate_price( '9', pr_prodstatus.*, 
		pr_category.cat_code, 
		pr_product.tariff_code, 
		default_duty_per, exchange_date) 
		IF pr_prodstatus.price9_amt <> pr_tmp_amt THEN 
			LET pr_prodstatus.price9_amt = pr_tmp_amt 
			LET pr_prodstatus.last_price_date = today 
			LET pr_updated_flag = 'Y' 
		END IF 
	END IF 
	RETURN pr_prodstatus.*, pr_updated_flag 
END FUNCTION 


REPORT is3_list(pr_product, pr_prodstatus, ps_prodstatus) 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus, 
	ps_prodstatus RECORD LIKE prodstatus.*, 
	pr_change_per DECIMAL(8,2), 
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
	LET glob_rec_kandooreport.header_text = "Auto-price Level Update Report" 
	LET glob_rec_kandooreport.width_num = 132 
	LET glob_rec_kandooreport.length_num = 66 
	LET glob_rec_kandooreport.menupath_text = "IS3" 
	LET glob_rec_kandooreport.selection_flag = "Y" 
	LET glob_rec_kandooreport.line1_text = " ", 
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
