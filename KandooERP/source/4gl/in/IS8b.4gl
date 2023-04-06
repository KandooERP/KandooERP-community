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

	Source code beautified by beautify.pl on 2020-01-03 09:12:41	$Id: $
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module IS8b - Contains the functions TO Update the product price details
#                FROM the Product Quotations previously loaded INTO the
#                prodquote table.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "IS8_GLOBALS.4gl" 
#
# Update Price Load IS the interface used TO capture the necessary criteria
# used TO UPDATE the live inventory product price AND/OR cost details
#

############################################################
# MODULE Scope Variables
############################################################
DEFINE pr_format_5 CHAR(1) 

#Update routines FOR Product Price Loads

FUNCTION update_price_load() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	where_text CHAR(500), 
	pr_temp_text CHAR(50), 
	pr_return SMALLINT, 
	pr_counter INTEGER 

	### IF there are no updatable rows in prodquote indicate now ###
	SELECT count(*) INTO pr_counter 
	FROM prodquote 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF pr_counter = 0 THEN 
		LET msgresp=kandoomsg("I",9257,"") 
		#9257 There no supplier product prices loaded FOR UPDATE
		RETURN false 
	END IF 
	SELECT count(*) INTO pr_counter 
	FROM prodquote 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND format_ind = '5' 
	IF pr_counter = 0 THEN 
		LET pr_format_5 = 'N' 
	ELSE 
		LET pr_format_5 = 'Y' 
	END IF 

	IF pr_format_5 = 'Y' THEN 
		OPEN WINDOW i619 with FORM "I688" 
		 CALL windecoration_i("I688") -- albo kd-758 
	ELSE 
		OPEN WINDOW i619 with FORM "I619" 
		 CALL windecoration_i("I619") -- albo kd-758 
	END IF 
	WHILE true 
		CLEAR FORM 
		LET msgresp=kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT where_text ON product.part_code, 
		product.desc_text, 
		product.prodgrp_code, 
		product.cat_code, 
		product.class_code, 
		product.vend_code, 
		prodquote.vend_code, 
		prodquote.oem_text, 
		prodquote.desc_text, 
		prodquote.barcode_text, 
		prodquote.curr_code, 
		prodquote.expiry_date 
		FROM product.part_code, 
		product.desc_text, 
		product.prodgrp_code, 
		product.cat_code, 
		product.class_code, 
		product.vend_code, 
		prodquote.vend_code, 
		prodquote.oem_text, 
		prodquote.desc_text, 
		prodquote.barcode_text, 
		prodquote.curr_code, 
		prodquote.expiry_date 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IS8b","construct-product-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET pr_return = false 
			EXIT WHILE 
		ELSE 
			IF pr_format_5 = 'Y' THEN 
				LET pr_updparms.ware_code = NULL 
				LET pr_updparms.ans1 = "N" 
				LET pr_updparms.ans3 = "N" 
				LET pr_updparms.ans4 = "N" 
				LET pr_updparms.ans5 = "Y" 
				LET pr_updparms.ans6 = "N" 
				LET pr_updparms.ans7 = "N" 
				IF update_price_cost(where_text) THEN 
				END IF 
				EXIT WHILE 
			END IF 
			### Collect the Default Warehouse Code ###
			### ie: Nominated Warehouse Code       ###
			SELECT mast_ware_code INTO pr_updparms.ware_code 
			FROM inparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = '1' 
			### Set up default VALUES TO answers TO 'N'
			LET pr_updparms.ans1 = "N" 
			LET pr_updparms.ans3 = "N" 
			LET pr_updparms.ans4 = "N" 
			LET pr_updparms.ans5 = "N" 
			LET pr_updparms.ans6 = "N" 
			DISPLAY BY NAME pr_updparms.* 

			LET msgresp=kandoomsg("I",9256,"") 
			#9256 Enter Supplier Quotation Load Details - ESC TO Continue"
			INPUT BY NAME pr_updparms.* 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","IS8b","input-pr_updparms-1") -- albo kd-505 

				ON ACTION "WEB-HELP" -- albo kd-372 
					CALL onlinehelp(getmoduleid(),null) 

				ON KEY (control-b) 
					CASE 
						WHEN infield(ware_code) 
							LET pr_temp_text = show_ware(glob_rec_kandoouser.cmpy_code) 
							IF pr_temp_text IS NOT NULL THEN 
								LET pr_updparms.ware_code = pr_temp_text 
							END IF 
							NEXT FIELD ware_code 
					END CASE 
				AFTER FIELD ans1 
					IF NOT check_answer(1) THEN 
						NEXT FIELD ans1 
					END IF 
				AFTER FIELD ans3 
					IF NOT check_answer(3) THEN 
						NEXT FIELD ans3 
					END IF 
				AFTER FIELD ans4 
					IF NOT check_answer(4) THEN 
						NEXT FIELD ans4 
					END IF 
				AFTER FIELD ans5 
					IF NOT check_answer(5) THEN 
						NEXT FIELD ans5 
					END IF 
				AFTER FIELD ans6 
					IF NOT check_answer(6) THEN 
						NEXT FIELD ans6 
					END IF 
				AFTER FIELD ans7 
					IF NOT check_answer(7) THEN 
						NEXT FIELD ans7 
					END IF 
				AFTER FIELD ware_code 
					IF pr_updparms.ware_code IS NULL THEN 
						LET msgresp=kandoomsg("I",9029,"") 
						#9029 Warehouse must be entered...
						NEXT FIELD ware_code 
					ELSE 
						SELECT * INTO pr_warehouse.* FROM warehouse 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND ware_code = pr_updparms.ware_code 
						IF status = notfound THEN 
							LET msgresp=kandoomsg("I",9030,"") 
							#9030 Warehouse does NOT exist - ...
							NEXT FIELD ware_code 
						ELSE 
							DISPLAY pr_warehouse.desc_text 
							TO warehouse.desc_text 

						END IF 
					END IF 
				AFTER INPUT 
					IF NOT (int_flag OR quit_flag) THEN 
						IF pr_updparms.ware_code IS NULL THEN 
							LET msgresp=kandoomsg("I",9029,"") 
							NEXT FIELD ware_code 
						ELSE 
							SELECT * INTO pr_warehouse.* FROM warehouse 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND ware_code = pr_updparms.ware_code 
							IF status = notfound THEN 
								LET msgresp=kandoomsg("I",9030,"") 
								#9030 Warehouse does NOT exist - ...
								NEXT FIELD ware_code 
							END IF 
						END IF 
						FOR pr_counter = 1 TO 7 
							IF NOT check_answer(pr_counter) THEN 
								CASE pr_counter 
									WHEN 1 NEXT FIELD ans1 
									WHEN 3 NEXT FIELD ans3 
									WHEN 4 NEXT FIELD ans4 
									WHEN 5 NEXT FIELD ans5 
									WHEN 6 NEXT FIELD ans6 
									WHEN 7 NEXT FIELD ans7 
								END CASE 
							END IF 
						END FOR 
						### IF all UPDATE fields VALUES are flagged TO "N"
						### don't process
						IF (pr_updparms.ans3 = "N" AND 
						pr_updparms.ans4 = "N" AND 
						pr_updparms.ans5 = "N" AND 
						pr_updparms.ans6 = "N" AND 
						pr_updparms.ans7 = "N") 
						THEN 
							LET msgresp = kandoomsg("I",9258,"") 
							#9258 There are no Product Price/Cost fields flagged...
							NEXT FIELD ans1 
						END IF 
						IF update_price_cost(where_text) THEN 
							LET pr_return = true 
							EXIT INPUT 
						END IF 
					END IF 
				ON KEY (control-w) 
					CALL kandoohelp("") 
			END INPUT 
			IF int_flag OR quit_flag THEN 
				LET quit_flag = false 
				LET int_flag = false 
			ELSE 
				IF pr_return THEN 
					EXIT WHILE 
				END IF 
			END IF 
		END IF 
	END WHILE 
	CLOSE WINDOW i619 
	RETURN pr_return 
END FUNCTION 
#
# Check Answer IS a simple FUNCTION that checks the answer TO Yes OR No
# in the above entry SCREEN
#
FUNCTION check_answer(pr_field_num) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_field_num SMALLINT, 
	pr_check_value CHAR(1) 

	CASE pr_field_num 
		WHEN 1 LET pr_check_value = pr_updparms.ans1 
		WHEN 3 LET pr_check_value = pr_updparms.ans3 
		WHEN 4 LET pr_check_value = pr_updparms.ans4 
		WHEN 5 LET pr_check_value = pr_updparms.ans5 
		WHEN 6 LET pr_check_value = pr_updparms.ans6 
		WHEN 7 LET pr_check_value = pr_updparms.ans7 
	END CASE 
	IF pr_check_value NOT matches "[YN]" THEN 
		LET msgresp = kandoomsg("U",1026,"") 
		#1026 Valid VALUES are Y AND N
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
#
# Update Price Cost IS the FUNCTION used TO allow the user TO SELECT
# the OPTIONS TO REPORT OR UPDATE the found supplier product quotations
# that will change the live inventory product prices AND/OR costs
#
FUNCTION update_price_cost(where_text) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	where_text CHAR(500), 
	query_text CHAR(1000), 
	final_query CHAR(1000), 
	pr_counter INTEGER 

	### Body of the SELECT statement used TO collect the information

	IF pr_format_5 = 'Y' THEN 
		LET query_text = "FROM prodquote, product ", 
		"WHERE prodquote.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
		"AND product.cmpy_code = prodquote.cmpy_code ", 
		"AND product.oem_text = prodquote.oem_text ", 
		"AND product.vend_code = prodquote.vend_code ", 
		"AND ", 
		where_text clipped 
	ELSE 
		LET query_text = "FROM prodquote, product ", 
		"WHERE prodquote.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
		"AND product.cmpy_code = prodquote.cmpy_code ", 
		"AND product.part_code = prodquote.part_code ", 
		"AND ", 
		where_text clipped 
		### FROM the default VALUES entered complete query_text
		IF pr_updparms.ans1 = "Y" THEN 
			LET query_text = query_text clipped, 
			" AND prodquote.vend_code = product.vend_code" 
		END IF 
	END IF 
	### Prepare TO count the number of rows TO process
	LET final_query = "SELECT count(*) ", query_text clipped 
	PREPARE s_countselect FROM final_query 
	DECLARE c_countcurs CURSOR FOR s_countselect 
	### Prepare the final query FOR UPDATE processing
	LET query_text = query_text clipped, " ORDER BY prodquote.part_code, ", 
	"expiry_date asc" 
	LET final_query = "SELECT prodquote.rowid, ", 
	"prodquote.*, product.* ", query_text clipped 
	PREPARE s_updateselect FROM final_query 
	DECLARE c_updatecurs CURSOR with HOLD FOR s_updateselect 
	LET msgresp = kandoomsg("U",1002,"") 
	#1002 " Searching database - please wait"
	OPEN c_countcurs 
	FETCH c_countcurs INTO pr_counter 
	IF pr_counter = 0 THEN 
		LET msgresp = kandoomsg("I",9259,"") 
		#9259 There were no Product Quotations found...
		RETURN false 
	END IF 
	MENU " Quotation Review" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","IS8b","menu-Quotation_Review-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Report" " Report on Inventory Price/Cost Update" 
			IF pr_format_5 = 'Y' THEN 
				IF update_prices_5(0) THEN 
					NEXT option "Print Manager" 
				END IF 
			ELSE 
				IF update_prices(0) THEN 
					NEXT option "Print Manager" 
				END IF 
			END IF 

		ON ACTION "Print Manager" 
		COMMAND KEY ("P",f11) "Print" " Print/View Load Report using RMS" 
			CALL run_prog("URS","","","","") 
			NEXT option "Update" 

		COMMAND "Update" " Run Inventory Prices/Costs Update" 
			IF pr_format_5 = 'Y' THEN 
				IF update_prices_5(1) THEN 
					NEXT option "Print Manager" 
				END IF 
			ELSE 
				IF update_prices(1) THEN 
					NEXT option "Print Manager" 
				END IF 
			END IF 
		COMMAND KEY(interrupt,"E")"Exit" " RETURN TO Quotations Menu" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
	RETURN true 
END FUNCTION 
#
# Report TO show the Products that will be updated/suggested FOR UPDATE
#
REPORT is8_2_list(pr_prodquote,pr_product) 
	DEFINE 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_product RECORD LIKE product.*, 
	pa_line array[4] OF CHAR(132) 

	OUTPUT 
	left margin 0 
	ORDER external BY pr_prodquote.part_code 
	FORMAT 
		PAGE HEADER 
			CALL report_header(glob_rec_kandoouser.cmpy_code,glob_rec_kandooreport.*,pageno) 
			RETURNING pa_line[1],pa_line[2],pa_line[3],pa_line[4] 
			PRINT COLUMN 001, pa_line[1] 
			PRINT COLUMN 001, pa_line[2] 
			PRINT COLUMN 001, pa_line[3] 
			PRINT COLUMN 001, glob_rec_kandooreport.line1_text 
			PRINT COLUMN 001, glob_rec_kandooreport.line2_text 
			PRINT COLUMN 001, pa_line[3] 
			LET rpt_pageno = pageno 
		ON EVERY ROW 
			PRINT COLUMN 002, pr_prodquote.part_code, 
			COLUMN 017, pr_product.desc_text[1,25], 
			COLUMN 043, pr_product.oem_text clipped, 
			COLUMN 074, pr_prodquote.cost_amt USING "########&.&&", 
			COLUMN 086, pr_prodquote.cost_amt USING "########&.&&", 
			COLUMN 100, pr_prodquote.cost_amt USING "########&.&&", 
			COLUMN 113, pr_prodquote.curr_code, 
			COLUMN 121, pr_prodquote.list_amt USING "########&.&&" 
		ON LAST ROW 
			NEED 4 LINES 
			SKIP 1 line 
			IF glob_rec_kandooreport.selection_flag = "Y" THEN 
				#PRINT COLUMN  1, "Selection criteria: ",
				#      COLUMN 25, where_part clipped wordwrap right margin 101
				#skip 1 line
			END IF 
			PRINT COLUMN 50, "**** END OF REPORT ", 
			glob_rec_kandooreport.report_code clipped," ****" 
END REPORT 



REPORT is8_3_list(pr_prodquote) 
	DEFINE 
	pr_prodquote RECORD LIKE prodquote.*, 
	rpt_note LIKE rmsreps.report_text, 
	rpt_width LIKE rmsreps.report_width_num, 
	pr_name_text LIKE company.name_text, 
	offset1, offset2 SMALLINT, 
	rpt_date DATE, 
	line1, line2 CHAR(80) 

	OUTPUT 
	left margin 1 

	FORMAT 
		PAGE HEADER 
			SELECT name_text INTO pr_name_text 
			FROM company 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET rpt_note = "IN - Price Load Report " 
			LET rpt_width = 80 
			LET rpt_date = today 
			LET line1 = glob_rec_kandoouser.cmpy_code, 2 spaces, 
			pr_name_text clipped 
			LET line2 = rpt_note clipped, " (Menu IS8)" 
			LET offset1 = (rpt_width - length(line1))/2 
			LET offset2 = (rpt_width - length(line2))/2 
			PRINT COLUMN 01, rpt_date, COLUMN offset1, line1 clipped, 
			COLUMN 70, "Page :", pageno USING "####" 
			PRINT COLUMN 01, time, COLUMN offset2, line2 clipped 
			PRINT COLUMN 01, "---------------------------------------------", 
			"----------------------------------" 
			PRINT COLUMN 01, "Product", 
			COLUMN 17, "Description", 
			COLUMN 47, "Currency", 
			COLUMN 57, " Cost", 
			COLUMN 69, " Date" 
			PRINT COLUMN 01, "--------------------------------------------------", 
			"-----------------------------" 

		ON EVERY ROW 
			PRINT COLUMN 01, pr_prodquote.part_code, 
			COLUMN 17, pr_prodquote.desc_text, 
			COLUMN 50, pr_prodquote.curr_code, 
			COLUMN 57, pr_prodquote.cost_amt USING "########.##", 
			COLUMN 69, pr_prodquote.expiry_date USING "dd/mm/yy" 


		ON LAST ROW 
			LET rpt_pageno = pageno 
			SKIP 1 line 
			PRINT COLUMN 30, "***** END OF REPORT IS8 3 *****" 
END REPORT 
#
# Calculate the Conversion value found with the price TO be converted
#
FUNCTION calc_conversion(pr_amount, pr_convrate, pr_calc_method) 
	DEFINE 
	pr_amount, pr_ret_amount DECIMAL(16,2), 
	pr_convrate FLOAT, 
	pr_calc_method CHAR(1) 

	### X = Multiply the VALUES
	### D = Divide the VALUES
	CASE pr_calc_method 
		WHEN "X" 
			LET pr_ret_amount = pr_amount * pr_convrate 
		WHEN "D" 
			LET pr_ret_amount = pr_amount/pr_convrate 
	END CASE 
	RETURN pr_ret_amount 

END FUNCTION 



#
# Update Prices FUNCTION IS used TO either REPORT on OR UPDATE the
#
FUNCTION update_prices(pr_update) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_update SMALLINT, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_tobeupd SMALLINT, 
	pr_convrate FLOAT, 
	pr_currcode LIKE currency.currency_code, 
	pr_temp_amt LIKE prodstatus.list_amt, 
	pr_err_message CHAR(60), 
	pr_rowid, pr_updcount INTEGER 

	### (pr_updparms) Update Parameters are :
	### ans1 - match on product.vend_code = prodquote.vend_code
	### ware_code  - UPDATE prices FROM prodquote WHERE part_code in warehouse
	### ans3 - UPDATE list price    FROM prodquote
	### ans4 - UPDATE standard cost FROM prodquote
	### ans5 - UPDATE FOB Cost      FROM prodquote
	### ans6 - UPDATE latest cost   FROM prodquote
	### ans7 - UPDATE oem_text      FROM prodquote
	### Collect the base currency code ###
	SELECT * INTO pr_glparms.* 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	### Prepare the defaults FOR the IS8 Update Price Report
	IF pr_update THEN 
		CALL set_defaults(2) 
	ELSE 
		CALL set_defaults(3) 
	END IF 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	LET pr_updcount = 0 
	LET pr_convrate = 1 
	LET pr_currcode = NULL 
	START REPORT is8_2_list TO pr_output 
	--   OPEN WINDOW process_win AT 12,20  -- albo  KD-758
	--      with 3 rows, 50 columns
	--      ATTRIBUTE(border)
	DISPLAY "Processing product: " at 2,1 
	FOREACH c_updatecurs INTO pr_rowid, 
		pr_prodquote.*, 
		pr_product.* 
		DISPLAY pr_prodquote.part_code at 2,21 
		### Update the product prices as suggested by the client
		SELECT * INTO pr_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_prodquote.part_code 
		AND ware_code = pr_updparms.ware_code 
		IF status = notfound THEN 
			### Possible error trapping TO REPORT needed here GREGM
			CONTINUE FOREACH 
		ELSE 
			### Process each of the fields required/flagged FOR UPDATE ###
			LET pr_tobeupd = false 
			### Collect the conv_qty FOR the diff b/w base currency AND
			### prodquote currency
			IF pr_currcode != pr_prodquote.curr_code THEN 
				LET pr_currcode = pr_prodquote.curr_code 
				IF pr_glparms.base_currency_code != pr_currcode THEN 
					### Get the latest conversion rate ###
					LET pr_convrate = get_conv_rate(
						glob_rec_kandoouser.cmpy_code, 
						pr_currcode, 
						today, 
						CASH_EXCHANGE_BUY) 
				ELSE 
					LET pr_convrate = 1 
				END IF 
			END IF 

			### Update list price
			IF pr_updparms.ans3 = "Y" THEN 
				### Important that a list amount of 0 IS NOT processed
				### even IF the user indicates
				IF pr_prodquote.list_amt > 0 THEN 
					LET pr_temp_amt = 
					calc_conversion(pr_prodquote.list_amt, 
					pr_convrate, 
					"X") 
					IF pr_prodstatus.list_amt <> pr_temp_amt THEN 
						LET pr_prodstatus.list_amt = pr_temp_amt 
						LET pr_prodstatus.last_price_date = today 
						LET pr_prodstatus.last_list_date = today 
						LET pr_tobeupd = true 
					END IF 
				END IF 
			END IF 
			### Update Standard Cost
			IF pr_updparms.ans4 = "Y" THEN 
				LET pr_temp_amt = 
				calc_conversion(pr_prodquote.cost_amt, 
				pr_convrate, 
				"X") 
				IF pr_prodstatus.est_cost_amt <> pr_temp_amt THEN 
					LET pr_prodstatus.est_cost_amt = pr_temp_amt 
					LET pr_prodstatus.last_cost_date = today 
					LET pr_tobeupd = true 
				END IF 
			END IF 
			### Update FOB Cost
			IF pr_updparms.ans5 = "Y" THEN 
				IF pr_prodstatus.for_curr_code <> pr_prodquote.curr_code 
				OR pr_prodstatus.for_cost_amt <> pr_prodquote.cost_amt THEN 
					LET pr_prodstatus.for_cost_amt = pr_prodquote.cost_amt 
					LET pr_prodstatus.last_cost_date = today 
					LET pr_prodstatus.for_curr_code = pr_prodquote.curr_code 
					LET pr_tobeupd = true 
				END IF 
			END IF 
			### Update Latest Cost
			IF pr_updparms.ans6 = "Y" THEN 
				LET pr_temp_amt = 
				calc_conversion(pr_prodquote.cost_amt, 
				pr_convrate, 
				"X") 
				IF pr_prodstatus.act_cost_amt <> pr_temp_amt THEN 
					LET pr_prodstatus.act_cost_amt = pr_temp_amt 
					LET pr_prodstatus.last_cost_date = today 
					LET pr_tobeupd = true 
				END IF 
			END IF 
			IF pr_update AND pr_tobeupd THEN 
				LET pr_updcount = pr_updcount + 1 
				GOTO bypass 
				LABEL recovery: 
				IF error_recover(pr_err_message, status) = "N" THEN 
					--               CLOSE WINDOW process_win  -- albo  KD-758
					RETURN false 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					### Update the product STATUS record
					UPDATE prodstatus 
					SET list_amt = pr_prodstatus.list_amt, 
					est_cost_amt = pr_prodstatus.est_cost_amt, 
					for_cost_amt = pr_prodstatus.for_cost_amt, 
					act_cost_amt = pr_prodstatus.act_cost_amt, 
					last_cost_date = pr_prodstatus.last_cost_date, 
					last_price_date = pr_prodstatus.last_price_date, 
					last_list_date = pr_prodstatus.last_list_date, 
					for_curr_code = pr_prodstatus.for_curr_code 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_prodquote.part_code 
					AND ware_code = pr_updparms.ware_code 
					### IF the OEM text IS TO be updated on product record
					IF pr_updparms.ans7 = "Y" THEN 
						UPDATE product 
						SET oem_text = pr_prodquote.oem_text 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND part_code = pr_prodquote.part_code 
					END IF 
				COMMIT WORK 
			END IF 
			### Only OUTPUT the rows that will/suggested TO be updated ###
			IF pr_tobeupd THEN 
				OUTPUT TO REPORT is8_2_list(pr_prodquote.*, 
				pr_product.*) 
			END IF 
			IF int_flag OR quit_flag THEN 
				#8021 Cancel Supplier Product Price/Cost Update?
				IF kandoomsg("U",8021,"") = "Y" THEN 
					#8022 WARNING: The Supplier Product Price/Cost UPDATE ..
					LET msgresp=kandoomsg("U",8022,"") 
					EXIT FOREACH 
				END IF 
			END IF 
		END IF 
	END FOREACH 
	FINISH REPORT is8_2_list 
	CALL upd_reports(pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num) 
	--   CLOSE WINDOW process_win  -- albo  KD-758
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF pr_update THEN 
			LET msgresp=kandoomsg("U",8024,pr_updcount) 
			#8024 999 rows successfully updated (Any Key)
		END IF 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION update_prices_5(pr_update) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pr_update SMALLINT, 
	pr_prodquote RECORD LIKE prodquote.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_tobeupd SMALLINT, 
	pr_convrate FLOAT, 
	pr_currcode LIKE currency.currency_code, 
	pr_temp_amt LIKE prodstatus.list_amt, 
	pr_query CHAR(400), 
	pr_err_message CHAR(60), 
	pr_rowid, pr_updcount INTEGER 

	SELECT * INTO pr_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	### Prepare the defaults FOR the IS8 Update Price Report
	IF pr_update THEN 
		CALL set_defaults(2) 
	ELSE 
		CALL set_defaults(3) 
	END IF 
	LET pr_output = init_report(glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.sign_on_code,glob_rec_kandooreport.header_text) 
	LET pr_updcount = 0 
	LET pr_convrate = 1 
	LET pr_currcode = NULL 
	START REPORT is8_3_list TO pr_output 
	--   OPEN WINDOW process_win AT 12,20  -- albo  KD-758
	--      with 3 rows, 50 columns
	--      ATTRIBUTE(border)
	DISPLAY "Processing product: " at 2,1 
	FOREACH c_updatecurs INTO pr_rowid, 
		pr_prodquote.*, 
		pr_product.* 
		LET pr_prodquote.part_code = pr_product.part_code 
		OUTPUT TO REPORT is8_3_list(pr_prodquote.*) 
		LET pr_query = "SELECT * FROM prodstatus ", 
		"WHERE prodstatus.cmpy_code = '",glob_rec_kandoouser.cmpy_code, "' ", 
		" AND part_code in (SELECT part_code FROM product ", 
		" WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, 
		"' AND vend_code = '", pr_prodquote.vend_code, 
		"' AND oem_text IS NOT NULL ", 
		" AND oem_text = '", pr_prodquote.oem_text, "' )" 
		PREPARE s_prodstatcurs FROM pr_query 
		DECLARE c_prodstatcurs CURSOR with HOLD FOR s_prodstatcurs 
		FOREACH c_prodstatcurs INTO pr_prodstatus.* 

			LET pr_tobeupd = false 

			### Update FOB Cost
			IF pr_prodstatus.for_curr_code <> pr_prodquote.curr_code 
			OR pr_prodstatus.for_cost_amt <> pr_prodquote.cost_amt THEN 
				LET pr_prodstatus.for_cost_amt = pr_prodquote.cost_amt 
				LET pr_prodstatus.last_cost_date = today 
				LET pr_prodstatus.for_curr_code = pr_prodquote.curr_code 
				LET pr_tobeupd = true 
			END IF 

			IF pr_update AND pr_tobeupd THEN 
				LET pr_updcount = pr_updcount + 1 
				GOTO bypass 
				LABEL recovery: 
				IF error_recover(pr_err_message, status) = "N" THEN 
					--               CLOSE WINDOW process_win  -- albo  KD-758
					RETURN false 
				END IF 
				LABEL bypass: 
				WHENEVER ERROR GOTO recovery 
				BEGIN WORK 
					### Update the product STATUS record
					UPDATE prodstatus 
					SET for_cost_amt = pr_prodquote.cost_amt, 
					for_curr_code = pr_prodquote.curr_code, 
					last_cost_date = pr_prodstatus.last_cost_date 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_prodstatus.part_code 
					AND ware_code = pr_prodstatus.ware_code 
				COMMIT WORK 
			END IF 
			IF int_flag OR quit_flag THEN 
				#8021 Cancel Supplier Product Price/Cost Update?
				IF kandoomsg("U",8021,"") = "Y" THEN 
					#8022 WARNING: The Supplier Product Price/Cost UPDATE ..
					LET msgresp=kandoomsg("U",8022,"") 
					EXIT FOREACH 
				END IF 
			END IF 
		END FOREACH 
	END FOREACH 
	FINISH REPORT is8_3_list 
	CALL upd_reports(pr_output, 
	rpt_pageno, 
	glob_rec_kandooreport.width_num, 
	glob_rec_kandooreport.length_num) 
	--   CLOSE WINDOW process_win  -- albo  KD-758
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF pr_update THEN 
			LET msgresp=kandoomsg("U",8024,pr_updcount) 
			#8024 999 rows successfully updated (Any Key)
		END IF 
		RETURN true 
	END IF 
END FUNCTION 

