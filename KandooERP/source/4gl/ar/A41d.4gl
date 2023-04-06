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
# \brief module A41d -  Line Item Detailed Entry
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 
 
#################################################################
# MODULE scope variables
#################################################################

###############################################################
# FUNCTION lineitem_entry(p_rowid)
#
#
###############################################################
FUNCTION lineitem_entry(p_rowid) 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_s_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_temp_amt LIKE creditdetl.unit_sales_amt 
	DEFINE l_errmsg CHAR(100) 
	DEFINE l_direction CHAR(1) 
	DEFINE l_cnt SMALLINT 
	DEFINE l_tab_cnt SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_temp_text CHAR(40) 

	CALL fgl_winmessage("Debug - p_rowid=",p_rowid,"info")

	SELECT * INTO l_rec_creditdetl.* 
	FROM t_creditdetl 
	WHERE rowid = p_rowid 

	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 
	##
	## Take snapshot of RECORD TO reinstate IF user presses interrupt
	##
	LET l_rec_s_creditdetl.* = l_rec_creditdetl.* 

	OPEN WINDOW A671 with FORM "A671" 
	CALL windecoration_a("A671") 

	CALL disp_e178_details(l_rec_creditdetl.*) 

	IF l_rec_creditdetl.reason_code IS NOT NULL THEN 
		SELECT reason_text INTO l_rec_credreas.reason_text 
		FROM credreas 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND reason_code = l_rec_creditdetl.reason_code 
		IF status = NOTFOUND THEN 
			LET l_rec_credreas.reason_text = "**********" 
		END IF 

		DISPLAY BY NAME l_rec_credreas.reason_text 

	END IF 
	
	MESSAGE kandoomsg2("A",1087,"")	#1087 F8 Product Inquiry - ESC TO Continue
	INPUT BY NAME 
		l_rec_creditdetl.part_code, 
		l_rec_creditdetl.line_text, 
		l_rec_creditdetl.ship_qty, 
		l_rec_creditdetl.received_qty, 
		l_rec_creditdetl.level_code, 
		l_rec_creditdetl.unit_sales_amt, 
		l_rec_creditdetl.reason_code WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A41d","inp-creditdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (part_code) 
			LET l_temp_text= 
				"status_ind='1' AND exists", 
				"(SELECT 1 FROM prodstatus ", 
				"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
				"AND part_code=product.part_code ", 
				"AND ware_code='",glob_rec_warehouse.ware_code,"' ", 
				"AND status_ind='1')" 

			LET l_temp_text = show_part(glob_rec_kandoouser.cmpy_code,l_temp_text) 

			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_creditdetl.part_code = l_temp_text 
				NEXT FIELD part_code 
			END IF 


		ON ACTION "LOOKUP" infield (reason_code) 
			#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code) 
			LET l_temp_text = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,l_rec_creditdetl.reason_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_creditdetl.reason_code = l_temp_text 
				NEXT FIELD reason_code 
			END IF 

		ON ACTION "NOTES" infield (line_text) --ON KEY (control-n)  infield(line_text) 
				OPTIONS DELETE KEY f2 
				LET l_rec_creditdetl.line_text =sys_noter(glob_rec_kandoouser.cmpy_code,l_rec_creditdetl.line_text) 

				OPTIONS DELETE KEY f36 
				NEXT FIELD line_text 

		ON KEY (F8) 
			CALL pinvwind(glob_rec_kandoouser.cmpy_code,l_rec_creditdetl.part_code) 

		AFTER FIELD part_code 
			IF l_rec_creditdetl.part_code IS NOT NULL THEN 
				#Note:  Done on purpose TO stop users adding products
				#       TO adjustment credits
				IF glob_rec_credithead.cred_ind = "4" THEN 
					LET l_rec_creditdetl.ware_code = " " 
					LET glob_rec_warehouse.ware_code = " " 
				END IF 

				IF NOT valid_part(
					glob_rec_kandoouser.cmpy_code,
					l_rec_creditdetl.part_code, 
					glob_rec_warehouse.ware_code,1,2,0,"","","") THEN 
					NEXT FIELD part_code 
				END IF 
				
				CALL A41_creditdetl_update_line(p_rowid,l_rec_creditdetl.*) 
				RETURNING l_rec_creditdetl.* 
			END IF
			 
			CALL disp_e178_details(l_rec_creditdetl.*) 

		AFTER FIELD ship_qty 
			IF l_rec_creditdetl.ship_qty IS NULL THEN 
				LET l_rec_creditdetl.ship_qty = 0 
				NEXT FIELD ship_qty 
			END IF 

			IF l_rec_creditdetl.part_code IS NOT NULL THEN 
				IF l_rec_creditdetl.ship_qty < 0 THEN 
					ERROR kandoomsg2("E",9134,"")		#9134 Quantity may NOT be negative
					NEXT FIELD ship_qty 
				END IF 
			END IF 

			IF NOT field_touched(received_qty) THEN 
				IF l_rec_creditdetl.received_qty = 0 THEN 
					LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
				END IF 
			END IF 
			CALL disp_e178_details(l_rec_creditdetl.*) 

		BEFORE FIELD received_qty 
			IF l_rec_creditdetl.part_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD ship_qty 
				ELSE 
					NEXT FIELD level_code 
				END IF 
			END IF 

			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_creditdetl.part_code 
			AND serial_flag = 'Y' 
			IF status <> NOTFOUND THEN 
				LET l_tab_cnt = serial_count(l_rec_creditdetl.part_code,l_rec_creditdetl.ware_code) 
				IF l_tab_cnt > l_rec_creditdetl.received_qty THEN 
					IF l_rec_creditdetl.received_qty = 0 THEN 
						ERROR kandoomsg2("I",9278,'') 	#9278 Product / Warehouse combination can only occur 1
						IF fgl_lastkey() = fgl_keyval("up") THEN 
							NEXT FIELD ship_qty 
						ELSE 
							NEXT FIELD level_code 
						END IF 
					ELSE 
						ERROR kandoomsg2("I",9279,'') 	#9279 Error - INPUT Quantity NOT equal OUTPUT Quantity
						LET l_errmsg = "A41d - Qty supplied NOT= table qty ",	l_rec_creditdetl.received_qty , " <> ", l_tab_cnt 
						CALL errorlog(l_errmsg) 
						LET status = -2 
						EXIT PROGRAM 
					END IF 
				END IF 

				IF fgl_lastkey() = fgl_keyval("up") THEN 
					LET l_direction = 'U' 
				ELSE 
					LET l_direction = 'D' 
				END IF 
				
				LET l_cnt = serial_input(
					l_rec_creditdetl.part_code, 
					l_rec_creditdetl.ware_code, 
					l_tab_cnt) 
				
				IF l_cnt < 0 THEN 
					IF l_cnt = -1 THEN 
						NEXT FIELD part_code 
					ELSE 
						CALL errorlog("A21b - Fatal error in serial_input ") 
						EXIT PROGRAM 
					END IF 
				ELSE 
					LET l_rec_creditdetl.received_qty = l_cnt 
					
					IF l_rec_creditdetl.ship_qty < l_rec_creditdetl.received_qty THEN 
						ERROR kandoomsg2("E",7092,"")	#9217 Received qty must be < line qty
					END IF 
				END IF 

				CALL disp_e178_details(l_rec_creditdetl.*)
				
				IF l_direction = 'U' THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD received_qty 
			CASE 
				WHEN l_rec_creditdetl.received_qty IS NULL 
					ERROR kandoomsg2("U",9102,"")				#9102 Qty must be entered
					LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
					NEXT FIELD received_qty 
					
				WHEN l_rec_creditdetl.received_qty < 0 
					ERROR kandoomsg2("E",9134,"")			#9134 Quantity may NOT be negative
					LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
					NEXT FIELD received_qty 
				
				WHEN l_rec_creditdetl.ship_qty < l_rec_creditdetl.received_qty 
					ERROR kandoomsg2("E",7092,"")					#9217 Received qty must be < line qty
			END CASE 
			CALL disp_e178_details(l_rec_creditdetl.*) 

		BEFORE FIELD level_code 
			IF l_rec_creditdetl.part_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD received_qty 
				ELSE 
					NEXT FIELD unit_sales_amt 
				END IF 
			END IF 
			
			LET l_temp_text = l_rec_creditdetl.level_code 

		AFTER FIELD level_code 
			IF l_rec_creditdetl.level_code IS NULL THEN 
				LET l_rec_creditdetl.level_code = l_temp_text 
				NEXT FIELD level_code 
			END IF 
			
			CALL A41_creditdetl_update_line(p_rowid,l_rec_creditdetl.*) 
			RETURNING l_rec_creditdetl.* 
			
			CALL disp_e178_details(l_rec_creditdetl.*) 

		BEFORE FIELD unit_sales_amt 
			LET l_temp_amt = l_rec_creditdetl.unit_sales_amt 

		AFTER FIELD unit_sales_amt 
			IF l_rec_creditdetl.unit_sales_amt < 0 THEN 
				LET l_rec_creditdetl.unit_sales_amt = l_temp_amt 
				ERROR kandoomsg2("U",9907,0)				#9907 Value must be greater than OR equal TO 0
				NEXT FIELD unit_sales_amt 
			END IF 

			IF l_rec_creditdetl.unit_sales_amt IS NULL THEN 
				CALL unit_price(l_rec_creditdetl.part_code,l_rec_creditdetl.level_code) 
				RETURNING l_rec_creditdetl.list_amt,l_rec_creditdetl.unit_sales_amt 
				NEXT FIELD unit_sales_amt 
			END IF 
			
			CALL A41_creditdetl_update_line(p_rowid,l_rec_creditdetl.*) 
			RETURNING l_rec_creditdetl.* 
			
			CALL disp_e178_details(l_rec_creditdetl.*) 

		AFTER FIELD reason_code 
			CLEAR reason_text 
			IF l_rec_creditdetl.reason_code IS NOT NULL THEN 
				SELECT * INTO l_rec_credreas.* 
				FROM credreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND reason_code = l_rec_creditdetl.reason_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9058,"") 					#A9058" credit reason does NOT exist - try window"
					NEXT FIELD reason_code 
				ELSE 
					DISPLAY BY NAME l_rec_credreas.reason_text 
				END IF 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_creditdetl.part_code IS NULL	AND l_rec_creditdetl.unit_sales_amt != 0 THEN 
					LET l_rec_creditdetl.line_acct_code = enter_acct(p_rowid) 
					IF l_rec_creditdetl.line_acct_code IS NULL THEN 
						NEXT FIELD part_code 
					END IF 
				END IF 
			END IF 


	END INPUT 

	CLOSE WINDOW A671 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CALL A41_creditdetl_update_line(p_rowid,l_rec_s_creditdetl.*) 
		RETURNING l_rec_creditdetl.* 
		RETURN false 
	ELSE 
		CALL A41_creditdetl_update_line(p_rowid,l_rec_creditdetl.*) 
		RETURNING l_rec_creditdetl.* 
		RETURN true 
	END IF 

END FUNCTION 
###############################################################
# END FUNCTION lineitem_entry(p_rowid)
###############################################################


###############################################################
# FUNCTION disp_E178_details(p_rec_creditdetl)
#
#
###############################################################
FUNCTION disp_e178_details(p_rec_creditdetl) 
	DEFINE p_rec_creditdetl RECORD LIKE creditdetl.* 

	LET p_rec_creditdetl.ext_sales_amt = p_rec_creditdetl.ship_qty * p_rec_creditdetl.unit_sales_amt 
	LET p_rec_creditdetl.ext_tax_amt = p_rec_creditdetl.ship_qty * p_rec_creditdetl.unit_tax_amt 
	LET p_rec_creditdetl.line_total_amt = p_rec_creditdetl.ext_sales_amt + p_rec_creditdetl.ext_tax_amt 
	
	DISPLAY BY NAME 
		p_rec_creditdetl.line_text, 
		p_rec_creditdetl.received_qty, 
		p_rec_creditdetl.uom_code, 
		p_rec_creditdetl.unit_sales_amt, 
		p_rec_creditdetl.ext_sales_amt, 
		p_rec_creditdetl.unit_tax_amt, 
		p_rec_creditdetl.ext_tax_amt, 
		p_rec_creditdetl.line_total_amt, 
		p_rec_creditdetl.list_amt 

	DISPLAY BY NAME glob_rec_credithead.currency_code #HuHo: attribute(GREEN) #why with color / green ? I'll remove it

	IF p_rec_creditdetl.part_code IS NULL THEN 
		CLEAR list_amt 
	END IF 

END FUNCTION 
###############################################################
# FUNCTION disp_E178_details(p_rec_creditdetl)
###############################################################


###############################################################
# FUNCTION enter_acct(p_rowid)
#
#
###############################################################
FUNCTION enter_acct(p_rowid) 
	DEFINE p_rowid INTEGER 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_save_acct_code LIKE coa.acct_code 
	DEFINE l_temp_text CHAR(40) 

	SELECT line_acct_code INTO l_rec_coa.acct_code 
	FROM t_creditdetl 
	WHERE rowid = p_rowid 
	LET l_save_acct_code = l_rec_coa.acct_code 

	OPEN WINDOW A672 with FORM "A672" 
	CALL windecoration_a("A672") 

	MESSAGE kandoomsg2("E",1025,"") #1025 Enter G.L. Account - ESC TO Continue
	INPUT BY NAME l_rec_coa.acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","A41d","inp-acct_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 

			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_coa.acct_code = l_temp_text 
			END IF 
			
			NEXT FIELD acct_code 

		AFTER FIELD acct_code 
			IF l_rec_coa.acct_code IS NULL THEN 
				ERROR kandoomsg2("E",9077,"")				#9077" Account Code IS required FOR Non-Inventory Lines"
				NEXT FIELD acct_code 
			ELSE 
				SELECT unique 1 FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 

				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("E",9078,"")					#9078" Line Account code NOT found"
					NEXT FIELD acct_code 
				END IF 

				IF NOT acct_type(
					glob_rec_kandoouser.cmpy_code,
					l_rec_coa.acct_code,
					COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,
					"Y") THEN 

					NEXT FIELD acct_code 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW A672 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN l_save_acct_code 
	ELSE 
		RETURN l_rec_coa.acct_code 
	END IF 
END FUNCTION 
###############################################################
# END FUNCTION enter_acct(p_rowid)
###############################################################


###############################################################
# FUNCTION unit_price(p_part_code,p_level_code)
#
#
###############################################################
FUNCTION unit_price(p_part_code,p_level_code) 
	DEFINE p_part_code LIKE prodstatus.part_code 
	DEFINE p_level_code LIKE customer.inv_level_ind 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rate_per FLOAT 

	LET l_rate_per = glob_rec_credithead.conv_qty 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = glob_rec_warehouse.ware_code 
	AND part_code = p_part_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN 0,0 
	ELSE 

		CASE p_level_code 
	WHEN "1" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price1_amt*l_rate_per) 
	WHEN "2" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price2_amt*l_rate_per) 
	WHEN "3" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price3_amt*l_rate_per) 
	WHEN "4" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price4_amt*l_rate_per) 
	WHEN "5" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price5_amt*l_rate_per) 
	WHEN "6" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price6_amt*l_rate_per) 
	WHEN "7" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price7_amt*l_rate_per) 
	WHEN "8" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price8_amt*l_rate_per) 
	WHEN "9" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.price9_amt*l_rate_per) 
	WHEN "L" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.list_amt*l_rate_per) 
	WHEN "C" RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.wgted_cost_amt*l_rate_per) 
	OTHERWISE RETURN l_rec_prodstatus.list_amt, 
		(l_rec_prodstatus.list_amt*l_rate_per) 
		END CASE 

	END IF 

END FUNCTION 
###############################################################
# END FUNCTION unit_price(p_part_code,p_level_code)
###############################################################