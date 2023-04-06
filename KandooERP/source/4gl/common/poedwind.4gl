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

	Source code beautified by beautify.pl on 2020-01-02 10:35:26	$Id: $
}



#
# FUNCTION:  poedwind
# Full Name: Purchase Order Edit
# Description: Allows the add/edit of Purchase Order header, lines AND
#              delivery details.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE global_rec_purchhead RECORD LIKE purchhead.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_save_curr LIKE vendor.currency_code 
END GLOBALS 


FUNCTION edit_header(p_mode,p_cmpy,p_po_num) 
	DEFINE p_mode CHAR(4)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_po_num LIKE purchhead.order_num

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_puparms RECORD LIKE puparms.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_pr_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_ps_warehouse RECORD LIKE warehouse.* 
	DEFINE l_voucher_qty LIKE poaudit.voucher_qty 
	DEFINE l_received_qty LIKE poaudit.received_qty 
	DEFINE l_err_continue CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_winds_text CHAR(100) 
	DEFINE l_save_vend LIKE vendor.vend_code 
	DEFINE l_save_ware LIKE purchhead.ware_code 
	DEFINE l_starter DATE 
	DEFINE l_failed_it INTEGER 
	DEFINE l_new_onorder_amt LIKE poaudit.line_total_amt 
	DEFINE l_old_onorder_amt LIKE poaudit.line_total_amt 
	DEFINE l_var_num LIKE purchhead.var_num 
	DEFINE l_save_date LIKE purchhead.order_date 
	DEFINE l_term_code LIKE purchhead.term_code 
	DEFINE l_tax_code LIKE purchhead.tax_code 
	DEFINE l_note_code CHAR(15) 
	DEFINE l_vend_lookup CHAR(1) 

	IF p_mode = "ADD" THEN 
		SELECT * INTO l_rec_glparms.* FROM glparms 
		WHERE cmpy_code = p_cmpy 
		AND key_code = "1" 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp=kandoomsg("U",5107,"")			#5107 General Ledger Parameters Not Setup;  Refer Menu GZP.
			RETURN FALSE 
		END IF 
		SELECT * INTO l_rec_puparms.* FROM puparms 
		WHERE cmpy_code = p_cmpy 
		AND key_code = "1" 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp=kandoomsg("U",5118,"")			#5118 Purchasing Parameters Not Set Up;  Refer Menu RZP.
			RETURN FALSE 
		END IF 
		IF global_rec_purchhead.var_num IS NULL 
		OR global_rec_purchhead.var_num = " " THEN 
			LET global_rec_purchhead.status_ind = "O" 
			LET global_rec_purchhead.var_num = 0 
			LET global_rec_purchhead.printed_flag = "N" 
		END IF 
	ELSE 
		OPEN WINDOW r604 with FORM "R604" 
		CALL windecoration_r("R604") 
		SELECT * INTO global_rec_purchhead.* FROM purchhead 
		WHERE cmpy_code = p_cmpy 
		AND order_num = p_po_num 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",7086,"") 		#7086 Purchase Order Details NOT found.
			CLOSE WINDOW R604 
			RETURN FALSE 
		END IF 
		SELECT * INTO pr_vendor.* FROM vendor 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = global_rec_purchhead.vend_code 
		IF STATUS = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",7087,"") 		#7087 Vendor details NOT found.
			CLOSE WINDOW R604 
			RETURN FALSE 
		END IF 
		LET pr_save_curr = pr_vendor.currency_code 
		DISPLAY BY NAME global_rec_purchhead.note_code 

	END IF 

	LET l_var_num = global_rec_purchhead.var_num 
	LET l_vend_lookup = FALSE 
	LET l_msgresp = kandoomsg("R",1010,"") 
	#1010 Enter PO Information; F8 Vendor Inquiry; Ctrl+N Notes; OK TO Continue.
	INPUT BY NAME global_rec_purchhead.vend_code, 
	global_rec_purchhead.var_num, 
	global_rec_purchhead.ware_code, 
	global_rec_purchhead.authorise_code, 
	global_rec_purchhead.order_text, 
	global_rec_purchhead.salesperson_text, 
	global_rec_purchhead.order_date, 
	global_rec_purchhead.due_date, 
	global_rec_purchhead.cancel_date, 
	global_rec_purchhead.term_code, 
	global_rec_purchhead.tax_code, 
	global_rec_purchhead.conv_qty, 
	global_rec_purchhead.type_ind, 
	global_rec_purchhead.com1_text, 
	global_rec_purchhead.com2_text WITHOUT DEFAULTS attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","poedwind","input-purchhead") 

		ON ACTION "REFRESH"
			CALL windecoration_r("R100")
			 		
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET l_winds_text = show_vend(p_cmpy,global_rec_purchhead.vend_code) 
			IF l_winds_text IS NOT NULL THEN 
				LET global_rec_purchhead.vend_code = l_winds_text 
				IF l_save_vend != global_rec_purchhead.vend_code 
				OR l_save_vend IS NULL THEN 
					LET l_vend_lookup = TRUE 
				END IF 
			END IF 
			DISPLAY BY NAME global_rec_purchhead.vend_code 

			NEXT FIELD vend_code
			 
		ON ACTION "LOOKUP" infield (ware_code) 
			LET l_winds_text = show_ware(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET global_rec_purchhead.ware_code = l_winds_text 
			END IF 
			DISPLAY BY NAME global_rec_purchhead.ware_code 

			NEXT FIELD ware_code 
			
		ON ACTION "LOOKUP" infield (term_code) 
			LET l_winds_text = show_term(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET global_rec_purchhead.term_code = l_winds_text 
			END IF 
			DISPLAY BY NAME global_rec_purchhead.term_code 

			NEXT FIELD term_code 
			
		ON ACTION "LOOKUP" infield (tax_code) 
			LET l_winds_text = show_tax(p_cmpy) 
			IF l_winds_text IS NOT NULL THEN 
				LET global_rec_purchhead.tax_code = l_winds_text 
			END IF 
			DISPLAY BY NAME global_rec_purchhead.tax_code 

			NEXT FIELD tax_code 

		ON KEY (F8) 
			IF global_rec_purchhead.vend_code IS NOT NULL THEN 
				CALL vinq_vend(p_cmpy,global_rec_purchhead.vend_code) 
			END IF 

		ON ACTION "NOTES" infield (line_text) ON KEY (control-n) 
			OPTIONS DELETE KEY f2 
			IF global_rec_purchhead.note_code IS NOT NULL THEN 
				# Need TO reconstruct FORMAT as required by sys_noter
				# due TO hashes being stripped once returned.
				LET l_note_code = "###", 
				global_rec_purchhead.note_code clipped 
			END IF 
			# Now strip leading hashes as don't want TO store hashes
			# FOR note code
			LET l_note_code = sys_noter(p_cmpy,l_note_code) 
			LET global_rec_purchhead.note_code = l_note_code[4,15] 
			DISPLAY BY NAME global_rec_purchhead.note_code 

			OPTIONS DELETE KEY f36 

		BEFORE FIELD vend_code 
			LET l_save_vend = global_rec_purchhead.vend_code 
			LET l_save_ware = global_rec_purchhead.ware_code 
			IF global_rec_purchhead.vend_code IS NOT NULL 
			OR global_rec_purchhead.vend_code != " " THEN 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = global_rec_purchhead.vend_code 
				CALL display_order(p_mode) 
			END IF 

			ON CHANGE vend_code 
			LET l_save_vend = global_rec_purchhead.vend_code 
			LET l_save_ware = global_rec_purchhead.ware_code 
			IF global_rec_purchhead.vend_code IS NOT NULL 
			OR global_rec_purchhead.vend_code != " " THEN 
				SELECT * INTO pr_vendor.* FROM vendor 
				WHERE cmpy_code = p_cmpy 
				AND vend_code = global_rec_purchhead.vend_code 
				CALL display_order(p_mode) 
			END IF 

		AFTER FIELD vend_code 
			IF global_rec_purchhead.vend_code IS NULL 
			OR global_rec_purchhead.vend_code = " " THEN 
				IF p_mode = "EDIT" THEN 
					LET global_rec_purchhead.vend_code = l_save_vend 
				END IF 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD vend_code 
			END IF 
			# Check that the vendor code exists
			# SELECT the rest of vendor data later TO save having TO redisplay
			# vendor details IF we come across the following errors.
			SELECT * INTO pr_vendor.* FROM vendor 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = global_rec_purchhead.vend_code 
			IF STATUS = NOTFOUND THEN 
				IF p_mode = "EDIT" THEN 
					LET global_rec_purchhead.vend_code = l_save_vend 
				END IF 
				LET l_msgresp = kandoomsg("P",9105,"") 
				#9105 Vendor NOT found;  Try Window.
				NEXT FIELD vend_code 
			END IF 
			IF pr_vendor.purchtype_code IS NULL 
			OR pr_vendor.purchtype_code = " " THEN 
				LET l_msgresp = kandoomsg("R",9517,"") 
				#9517 This vendor IS NOT SET up FOR purchase ORDER entry.
				LET global_rec_purchhead.vend_code = l_save_vend 
				NEXT FIELD vend_code 
			END IF 

			IF p_mode = "EDIT" 
			AND global_rec_purchhead.vend_code = l_save_vend THEN 
				## Do NOT redefault all the existing VALUES
				IF pr_vendor.currency_code != pr_save_curr THEN 
					LET l_msgresp = kandoomsg("R",9009,pr_save_curr) 
					#9009 Vendor currency code must be:  pr_save_curr
					LET global_rec_purchhead.vend_code = l_save_vend 
					NEXT FIELD vend_code 
				END IF 
				IF l_vend_lookup THEN 
					LET global_rec_purchhead.term_code = pr_vendor.term_code 
					LET global_rec_purchhead.tax_code = pr_vendor.tax_code 
					LET global_rec_purchhead.salesperson_text = pr_vendor.contact_text 
					LET global_rec_purchhead.curr_code = pr_vendor.currency_code 
					DISPLAY BY NAME global_rec_purchhead.term_code, 
					global_rec_purchhead.tax_code, 
					global_rec_purchhead.salesperson_text 

					DISPLAY BY NAME global_rec_purchhead.curr_code 
					attribute(green) 
				END IF 
			ELSE 
				IF p_mode = "EDIT" THEN 
					LET l_voucher_qty = 0 
					SELECT sum(voucher_qty) INTO l_voucher_qty FROM poaudit 
					WHERE cmpy_code = p_cmpy 
					AND poaudit.po_num = global_rec_purchhead.order_num 
					IF l_voucher_qty > 0 THEN 
						LET l_msgresp = kandoomsg("P",7091,"") 
						#7091 Voucher created during edit.
						LET global_rec_purchhead.vend_code = l_save_vend 
						LET quit_flag = TRUE 
						EXIT INPUT 
					END IF 
					IF global_rec_purchhead.type_ind = "1" THEN 
						LET l_msgresp = kandoomsg("P",9543,"") 
						#9543 Cannot change vendor FOR commitment purchase ORDER.
						LET global_rec_purchhead.vend_code = l_save_vend 
						NEXT FIELD vend_code 
					END IF 
					IF pr_vendor.currency_code != pr_save_curr THEN 
						LET global_rec_purchhead.vend_code = l_save_vend 
						LET l_msgresp = kandoomsg("R",9009,pr_save_curr) 
						#9009 Vendor currency code must be:  pr_save_curr
						NEXT FIELD vend_code 
					END IF 
					LET global_rec_purchhead.purchtype_code = pr_vendor.purchtype_code 
					LET global_rec_purchhead.term_code = pr_vendor.term_code 
					LET global_rec_purchhead.tax_code = pr_vendor.tax_code 
					LET global_rec_purchhead.salesperson_text = pr_vendor.contact_text 
					LET global_rec_purchhead.curr_code = pr_vendor.currency_code 
					DISPLAY BY NAME global_rec_purchhead.term_code, 
					global_rec_purchhead.tax_code, 
					global_rec_purchhead.salesperson_text 

					DISPLAY BY NAME global_rec_purchhead.curr_code 
					attribute(green) 
				END IF 
				IF pr_vendor.hold_code IS NOT NULL 
				AND pr_vendor.hold_code IS NOT NULL THEN #!= "NO" 
					LET l_msgresp = kandoomsg("R",7011,pr_vendor.vend_code) 
					#7011 WARNING: Vendor IS on hold payment STATUS.
				END IF 
				IF pr_vendor.bal_amt > pr_vendor.limit_amt THEN 
					LET l_msgresp = kandoomsg("R",7012,pr_vendor.vend_code) 
					#7012 WARNING: Vendor credit limit has been exceeded.
				END IF 
				IF p_mode = "ADD" THEN 
					IF l_vend_lookup 
					OR l_save_vend != global_rec_purchhead.vend_code 
					OR l_save_vend IS NULL THEN 
						LET global_rec_purchhead.order_date = today 
						LET global_rec_purchhead.due_date = today 
						LET global_rec_purchhead.ware_code = l_rec_puparms.usual_ware_code 
						LET global_rec_purchhead.type_ind = l_rec_puparms.post_method_ind 
						CALL db_period_what_period(p_cmpy,global_rec_purchhead.order_date) 
						RETURNING global_rec_purchhead.year_num, 
						global_rec_purchhead.period_num 
						IF global_rec_purchhead.ware_code != l_save_ware 
						AND l_save_ware IS NOT NULL THEN 
							SELECT * INTO l_rec_pr_warehouse.* FROM warehouse 
							WHERE ware_code = global_rec_purchhead.ware_code 
							AND cmpy_code = p_cmpy 
							IF STATUS = NOTFOUND THEN 
								LET l_msgresp = kandoomsg("I",7034,"") 
								#7043 Warehouse does NOT exist.
								NEXT FIELD vend_code 
							END IF 
							IF recalc_add_lines(global_rec_purchhead.ware_code, 
							l_save_ware,0) THEN 
								LET l_rec_ps_warehouse.* = l_rec_pr_warehouse.* 
								LET global_rec_purchhead.del_name_text = l_rec_pr_warehouse.desc_text 
								LET global_rec_purchhead.del_addr1_text = l_rec_pr_warehouse.addr1_text 
								LET global_rec_purchhead.del_addr2_text = l_rec_pr_warehouse.addr2_text 
								LET global_rec_purchhead.del_addr3_text = l_rec_pr_warehouse.city_text 
								LET global_rec_purchhead.del_addr4_text = l_rec_pr_warehouse.state_code, ", ", l_rec_pr_warehouse.post_code 
								LET global_rec_purchhead.del_country_code = l_rec_pr_warehouse.country_code 
								LET global_rec_purchhead.contact_text = l_rec_pr_warehouse.contact_text 
							ELSE 
								LET global_rec_purchhead.ware_code = l_save_ware 
								SELECT * INTO l_rec_pr_warehouse.* FROM warehouse 
								WHERE ware_code = global_rec_purchhead.ware_code 
								AND cmpy_code = p_cmpy 
								IF STATUS = NOTFOUND THEN 
									LET l_rec_pr_warehouse.desc_text = "" 
								END IF 
								DISPLAY BY NAME l_rec_pr_warehouse.desc_text 

							END IF 
						END IF 
						LET global_rec_purchhead.term_code = pr_vendor.term_code 
						LET global_rec_purchhead.tax_code = pr_vendor.tax_code 
						LET global_rec_purchhead.salesperson_text = pr_vendor.contact_text 
						LET global_rec_purchhead.curr_code = pr_vendor.currency_code 
					END IF 
				END IF 
				LET global_rec_purchhead.conv_qty =	get_conv_rate(
					p_cmpy,
					global_rec_purchhead.curr_code, 
					global_rec_purchhead.order_date,
					CASH_EXCHANGE_BUY) 
				
				CALL display_order(p_mode) 
			END IF 
			
			LET l_vend_lookup = FALSE 

		AFTER FIELD var_num 
			IF global_rec_purchhead.var_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET global_rec_purchhead.var_num = l_var_num 
				NEXT FIELD var_num 
			END IF 
			IF global_rec_purchhead.var_num < 0 THEN 
				LET l_msgresp = kandoomsg("U",9927,"zero") 
				#9012 Value must be greater than zero.
				LET global_rec_purchhead.var_num = l_var_num 
				NEXT FIELD var_num 
			END IF 
			IF global_rec_purchhead.var_num != 0 
			AND global_rec_purchhead.var_num < l_var_num THEN 
				LET l_msgresp = kandoomsg("U",9907,l_var_num) 
				#9907 Value must be greater than OR equal TO l_var_num.
				NEXT FIELD var_num 
			END IF 

		BEFORE FIELD ware_code 
			LET l_save_ware = global_rec_purchhead.ware_code 
			IF p_mode = "EDIT" THEN 
				SELECT sum(received_qty) INTO l_received_qty FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND po_num = global_rec_purchhead.order_num 
				IF l_received_qty > 0 THEN 
					IF fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 
			END IF 
			IF l_save_ware IS NOT NULL THEN 
				SELECT * INTO l_rec_pr_warehouse.* FROM warehouse 
				WHERE warehouse.ware_code = global_rec_purchhead.ware_code 
				AND cmpy_code = p_cmpy 
				IF STATUS = NOTFOUND THEN 
					LET l_rec_pr_warehouse.desc_text = "" 
				END IF 
				DISPLAY l_rec_pr_warehouse.desc_text TO warehouse.desc_text 

			END IF 

		AFTER FIELD ware_code 
			IF global_rec_purchhead.ware_code IS NULL THEN 
				SELECT unique 1 FROM t_purchdetl 
				WHERE type_ind = "I" OR type_ind = "C" 

				IF STATUS = 0 THEN 
					LET l_msgresp = kandoomsg("R",9523,"") 
					#9523 Inventory items exist warehouse must exist
					LET global_rec_purchhead.ware_code = l_save_ware 
					NEXT FIELD ware_code 
				END IF 
				LET l_rec_pr_warehouse.desc_text = NULL 
				DISPLAY l_rec_pr_warehouse.desc_text TO warehouse.desc_text 

			END IF 
			IF global_rec_purchhead.ware_code IS NOT NULL THEN 
				SELECT * INTO l_rec_pr_warehouse.* FROM warehouse 
				WHERE warehouse.ware_code = global_rec_purchhead.ware_code 
				AND cmpy_code = p_cmpy 
				IF STATUS = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("E",9047,"") 
					#9047 Warehouse code does NOT exist;  Try Window.
					NEXT FIELD ware_code 
				END IF 
				DISPLAY l_rec_pr_warehouse.desc_text TO warehouse.desc_text 

				IF l_save_ware != global_rec_purchhead.ware_code 
				AND l_save_ware IS NOT NULL 
				AND p_mode = "ADD" THEN 
					IF NOT recalc_add_lines(global_rec_purchhead.ware_code, 
					l_save_ware,1) THEN 
						LET global_rec_purchhead.ware_code = l_save_ware 
						NEXT FIELD ware_code 
					END IF 
				END IF 
			END IF 

		BEFORE FIELD order_date 
			IF p_mode = "ADD" THEN 
				LET l_save_date = global_rec_purchhead.order_date 
			END IF 

		AFTER FIELD order_date 
			IF global_rec_purchhead.order_date IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET l_save_date = global_rec_purchhead.order_date 
				NEXT FIELD order_date 
			END IF 
			IF global_rec_purchhead.order_date = l_save_date AND p_mode = "ADD" THEN 
				# Don't refault exisiting VALUES
			ELSE 
				IF p_mode = "ADD" THEN 
					LET global_rec_purchhead.conv_qty = get_conv_rate(
						p_cmpy,
						global_rec_purchhead.curr_code, 
						global_rec_purchhead.order_date,
						CASH_EXCHANGE_BUY) 
					
					CALL db_period_what_period(p_cmpy,global_rec_purchhead.order_date) 
					RETURNING 
						global_rec_purchhead.year_num, 
						global_rec_purchhead.period_num 
					
					DISPLAY BY NAME 
					global_rec_purchhead.year_num, 
					global_rec_purchhead.period_num 

					IF NOT valid_period2(
						p_cmpy,
						global_rec_purchhead.year_num, 
						global_rec_purchhead.period_num,
						LEDGER_TYPE_PU) THEN 
						LET l_msgresp = kandoomsg("P",9024,"")					#9024 Accounting year & period IS closed OR NOT SET up.
						NEXT FIELD order_date 
					END IF 
				ELSE 
					SELECT max(start_date) INTO l_starter FROM rate_exchange 
					WHERE cmpy_code = p_cmpy 
					AND currency_code = pr_vendor.currency_code 
					AND start_date <= global_rec_purchhead.order_date 
					IF l_starter IS NULL THEN 
						CALL curr_locate() 
					ELSE 
						SELECT conv_buy_qty INTO global_rec_purchhead.conv_qty 
						FROM rate_exchange 
						WHERE cmpy_code = p_cmpy 
						AND currency_code = pr_vendor.currency_code 
						AND start_date = l_starter 
					END IF 
				END IF 
				DISPLAY BY NAME global_rec_purchhead.conv_qty 

			END IF 

		AFTER FIELD due_date 
			IF global_rec_purchhead.due_date IS NULL THEN 
				LET global_rec_purchhead.due_date = today 
			END IF 
			DISPLAY BY NAME global_rec_purchhead.due_date 

		BEFORE FIELD cancel_date 
			IF p_mode = "ADD" THEN 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right") THEN 
					NEXT FIELD term_code 
				ELSE 
					NEXT FIELD due_date 
				END IF 
			END IF 

		BEFORE FIELD term_code 
			LET l_term_code = global_rec_purchhead.term_code 

		AFTER FIELD term_code 
			IF global_rec_purchhead.term_code IS NULL 
			OR global_rec_purchhead.term_code = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET global_rec_purchhead.term_code = l_term_code 
				NEXT FIELD term_code 
			END IF 
			SELECT term.desc_text INTO pr_term.desc_text FROM term 
			WHERE term.term_code = global_rec_purchhead.term_code 
			AND term.cmpy_code = p_cmpy 
			IF STATUS = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9544,"") 
				#9544 Term Code NOT found;  Try Window.
				NEXT FIELD term_code 
			END IF 
			DISPLAY l_rec_term.desc_text 
			TO term.desc_text 

		BEFORE FIELD tax_code 
			LET l_tax_code = global_rec_purchhead.tax_code 

		AFTER FIELD tax_code 
			IF global_rec_purchhead.tax_code IS NULL 
			OR global_rec_purchhead.tax_code = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET global_rec_purchhead.tax_code = l_tax_code 
				NEXT FIELD tax_code 
			END IF 
			SELECT desc_text INTO pr_tax.desc_text FROM tax 
			WHERE tax.tax_code = global_rec_purchhead.tax_code 
			AND tax.cmpy_code = p_cmpy 
			IF STATUS = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9106,"") 
				#9106 Tax Code NOT found;  Try Window.
				NEXT FIELD tax_code 
			END IF 
			DISPLAY l_rec_tax.desc_text 
			TO tax.desc_text 

		BEFORE FIELD conv_qty 
			IF global_rec_purchhead.curr_code = l_rec_glparms.base_currency_code 
			OR p_mode = "EDIT" THEN 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						NEXT FIELD NEXT 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
				END CASE 
			END IF 

		AFTER FIELD conv_qty 
			IF global_rec_purchhead.conv_qty IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				LET global_rec_purchhead.conv_qty = 0 
				NEXT FIELD conv_qty 
			END IF 
			IF global_rec_purchhead.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9012,"") 
				#9012 Exchange rate must be greater than zero.
				LET global_rec_purchhead.conv_qty = 0 
				NEXT FIELD conv_qty 
			END IF 

		BEFORE FIELD type_ind 
			IF l_rec_puparms.over_meth_flag = "N" 
			OR p_mode = "EDIT" THEN 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("down") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						NEXT FIELD NEXT 
					WHEN fgl_lastkey() = fgl_keyval("up") 
						OR fgl_lastkey() = fgl_keyval("left") 
						NEXT FIELD previous 
				END CASE 
			END IF 

		AFTER FIELD type_ind 
			IF global_rec_purchhead.type_ind IS NULL 
			OR global_rec_purchhead.type_ind = " " THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD type_ind 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				LET l_voucher_qty = 0 
				SELECT sum(voucher_qty) INTO l_voucher_qty FROM poaudit 
				WHERE cmpy_code = p_cmpy 
				AND poaudit.po_num = global_rec_purchhead.order_num 
				IF l_voucher_qty > 0 THEN 
					LET l_msgresp = kandoomsg("P",7091,"") 
					#7091 Voucher created during edit.
					LET quit_flag = TRUE 
					EXIT INPUT 
				END IF 
				IF global_rec_purchhead.due_date IS NULL THEN 
					LET global_rec_purchhead.due_date = today 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD due_date 
				END IF 
				IF global_rec_purchhead.term_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD term_code 
				END IF 
				IF global_rec_purchhead.tax_code IS NULL 
				OR global_rec_purchhead.tax_code = " " THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD tax_code 
				END IF 
				IF global_rec_purchhead.var_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD var_num 
				END IF 
				IF global_rec_purchhead.type_ind IS NULL 
				OR global_rec_purchhead.type_ind = " " THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD type_ind 
				END IF 
				IF p_mode = "ADD" THEN 
					IF NOT valid_period2(
						p_cmpy,
						global_rec_purchhead.year_num, 
						global_rec_purchhead.period_num,
						LEDGER_TYPE_PU) THEN 
						LET l_msgresp = kandoomsg("P",9024,"")		#9024 Accounting year & period IS closed OR NOT SET up.
						NEXT FIELD order_date 
					END IF 
					IF global_rec_purchhead.conv_qty IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"")		#9102 Value must be entered.
						LET global_rec_purchhead.conv_qty = 0 
						NEXT FIELD conv_qty 
					END IF 
					IF global_rec_purchhead.conv_qty <= 0 THEN 
						LET l_msgresp = kandoomsg("P",9012,"")	#9012 Exchange rate must be greater than zero.
						LET global_rec_purchhead.conv_qty = 0 
						NEXT FIELD conv_qty 
					END IF 
					IF global_rec_purchhead.cmpy_code IS NULL 
					OR global_rec_purchhead.cmpy_code = " " THEN 
						LET global_rec_purchhead.cmpy_code = p_cmpy 
						LET global_rec_purchhead.enter_code = glob_rec_kandoouser.sign_on_code 
						LET global_rec_purchhead.entry_date = today 
						LET global_rec_purchhead.confirm_ind = l_rec_puparms.usual_conf_flag 
						LET global_rec_purchhead.purchtype_code = pr_vendor.purchtype_code 
						LET global_rec_purchhead.tele_text = l_rec_pr_warehouse.tele_text 
					END IF 
					IF global_rec_purchhead.ware_code IS NOT NULL 
					AND global_rec_purchhead.ware_code != " " THEN 
						IF (global_rec_purchhead.del_name_text IS NULL 
						OR global_rec_purchhead.del_name_text = " ") 
						AND (global_rec_purchhead.del_addr1_text = " " 
						OR global_rec_purchhead.del_addr1_text IS null) 
						AND (global_rec_purchhead.del_addr2_text = " " 
						OR global_rec_purchhead.del_addr2_text IS null) 
						OR l_save_ware != global_rec_purchhead.ware_code 
						OR l_save_ware IS NULL THEN 
							SELECT * INTO l_rec_pr_warehouse.* FROM warehouse 
							WHERE cmpy_code = p_cmpy 
							AND ware_code = global_rec_purchhead.ware_code 
							LET global_rec_purchhead.del_name_text = l_rec_pr_warehouse.desc_text 
							LET global_rec_purchhead.del_addr1_text = l_rec_pr_warehouse.addr1_text 
							LET global_rec_purchhead.del_addr2_text = l_rec_pr_warehouse.addr2_text 
							LET global_rec_purchhead.del_addr3_text = l_rec_pr_warehouse.city_text 
							LET global_rec_purchhead.del_addr4_text = l_rec_pr_warehouse.state_code, 			", ", l_rec_pr_warehouse.post_code 
							LET global_rec_purchhead.del_country_code = l_rec_pr_warehouse.country_code 
							LET global_rec_purchhead.contact_text = l_rec_pr_warehouse.contact_text 
						END IF 
					ELSE 
						LET global_rec_purchhead.del_name_text = " " 
						LET global_rec_purchhead.del_addr1_text = " " 
						LET global_rec_purchhead.del_addr2_text = " " 
						LET global_rec_purchhead.del_addr3_text = " " 
						LET global_rec_purchhead.del_addr4_text = " " 
						LET global_rec_purchhead.del_country_code = " " 
						LET global_rec_purchhead.contact_text = " " 
					END IF 
					IF NOT edit_delivery("ADD","") THEN 
						CONTINUE INPUT 
					END IF 
				END IF 
			ELSE 
				IF p_mode = "ADD" THEN 
					SELECT unique 1 FROM t_purchdetl 
					IF STATUS = 0 THEN 
						LET l_msgresp = kandoomsg("R",8009,"") 
						#8009 Line items exist.  Confirm TO cancel?
						IF l_msgresp = "N" THEN 
							LET int_flag = FALSE 
							LET quit_flag = FALSE 
							NEXT FIELD vend_code 
						ELSE 
							LET int_flag = TRUE 
						END IF 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		IF p_mode = "EDIT" THEN 
			CLOSE WINDOW r604 
		END IF 
		RETURN FALSE 
	END IF 

	IF p_mode = "EDIT" THEN 
		GOTO bypass 
		LABEL recovery: 
		IF l_failed_it THEN 
			LET l_msgresp = kandoomsg("R",7017,"") 
			#7017 Unable TO change ORDER details, UPDATE NOT performed.
			IF p_mode = "EDIT" THEN 
				CLOSE WINDOW r604 
			END IF 
			RETURN FALSE 
		ELSE 
			LET l_err_continue = error_recover(l_err_message, STATUS) 
			IF l_err_continue != "Y" THEN 
				EXIT program 
			END IF 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		LET l_msgresp = kandoomsg("U",1005,"") 
		#1005 Updating Database;  Please wait.
		BEGIN WORK 
			DECLARE c_vendor CURSOR FOR 
			SELECT * FROM vendor 
			WHERE vend_code = global_rec_purchhead.vend_code 
			AND cmpy_code = p_cmpy 
			FOR UPDATE 
			OPEN c_vendor 
			FETCH c_vendor INTO pr_vendor.* 
			LET l_failed_it = FALSE 
			LET l_err_message = "R14a - Purchhead Update" 
			SELECT * INTO l_rec_purchhead.* FROM purchhead 
			WHERE cmpy_code = p_cmpy 
			AND order_num = global_rec_purchhead.order_num 
			IF l_rec_purchhead.vend_code != global_rec_purchhead.vend_code THEN 
				DECLARE c2_vendor CURSOR FOR 
				SELECT * FROM vendor 
				WHERE vend_code = l_rec_purchhead.vend_code 
				AND cmpy_code = p_cmpy 
				FOR UPDATE 
				OPEN c2_vendor 
				FETCH c2_vendor INTO l_rec_vendor.* 
			END IF 
			LET l_new_onorder_amt = 0 
			LET l_old_onorder_amt = 0 
			IF l_rec_purchhead.vend_code != global_rec_purchhead.vend_code 
			OR l_rec_purchhead.ware_code != global_rec_purchhead.ware_code THEN 
				CALL recalc_lines(global_rec_purchhead.ware_code, 
				l_rec_purchhead.ware_code) 
				RETURNING l_failed_it, 
				l_new_onorder_amt, 
				l_old_onorder_amt 
				IF l_failed_it < 0 THEN 
					GO TO recovery 
				END IF 
				IF l_failed_it THEN 
					ROLLBACK WORK 
					GOTO recovery 
				END IF 
			END IF 
			LET global_rec_purchhead.rev_num = global_rec_purchhead.rev_num + 1 
			LET global_rec_purchhead.rev_date = today 
			UPDATE purchhead 
			SET * = global_rec_purchhead.* 
			WHERE cmpy_code = global_rec_purchhead.cmpy_code 
			AND order_num = global_rec_purchhead.order_num 
			IF global_rec_purchhead.order_date > pr_vendor.last_po_date 
			OR pr_vendor.last_po_date IS NULL THEN 
				LET pr_vendor.last_po_date = global_rec_purchhead.order_date 
			END IF 
			LET l_err_message = "R14a Updating Vendor -last ORDER date" 
			IF l_rec_purchhead.vend_code = global_rec_purchhead.vend_code THEN 
				LET l_new_onorder_amt = l_new_onorder_amt - l_old_onorder_amt 
			END IF 
			UPDATE vendor 
			SET last_po_date = pr_vendor.last_po_date, 
			onorder_amt = onorder_amt + l_new_onorder_amt 
			WHERE cmpy_code = global_rec_purchhead.cmpy_code 
			AND vend_code = global_rec_purchhead.vend_code 
			IF l_rec_purchhead.vend_code != global_rec_purchhead.vend_code THEN 
				UPDATE vendor 
				SET onorder_amt = onorder_amt - l_old_onorder_amt 
				WHERE cmpy_code = global_rec_purchhead.cmpy_code 
				AND vend_code = l_rec_purchhead.vend_code 
				UPDATE poaudit 
				SET vend_code = global_rec_purchhead.vend_code 
				WHERE cmpy_code = p_cmpy 
				AND po_num = global_rec_purchhead.order_num 
				UPDATE purchdetl 
				SET vend_code = global_rec_purchhead.vend_code 
				WHERE cmpy_code = p_cmpy 
				AND order_num = global_rec_purchhead.order_num 
			END IF 
		COMMIT WORK 
		WHENEVER ERROR stop
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	END IF 
	IF p_mode = "EDIT" THEN 
		CLOSE WINDOW r604 
	END IF 
	RETURN TRUE 
END FUNCTION 


FUNCTION recalc_lines(p_ware_code,p_from_ware_code) 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_from_ware_code LIKE warehouse.ware_code 

	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_pr_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_st_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_dquote RECORD LIKE prodquote.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_cost LIKE poaudit.unit_cost_amt 
	DEFINE l_price_curr_code LIKE prodstatus.for_curr_code 
	DEFINE l_base_curr_code LIKE glparms.base_currency_code 
	DEFINE l_err_stat INTEGER 
	DEFINE l_order_qty LIKE poaudit.order_qty 
	DEFINE r_failed_it INTEGER
	DEFINE r_new_onorder_amt LIKE poaudit.line_total_amt
	DEFINE r_old_onorder_amt LIKE poaudit.line_total_amt

	SELECT base_currency_code INTO l_base_curr_code 
	FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	GOTO bypass1 
	LABEL recovery1: 
	LET l_err_stat = STATUS 
	RETURN l_err_stat,0,0 
	LABEL bypass1: 
	WHENEVER ERROR GOTO recovery1 
	LET l_rec_pr_poaudit.tran_date = today 
	LET l_rec_pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_pr_poaudit.po_num = global_rec_purchhead.order_num 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, l_rec_pr_poaudit.tran_date) 
	RETURNING l_rec_pr_poaudit.year_num, 
	l_rec_pr_poaudit.period_num 
	DECLARE c6_purchdetl CURSOR FOR 
	SELECT * FROM purchdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = global_rec_purchhead.order_num 
	LET r_old_onorder_amt = 0 
	LET r_new_onorder_amt = 0 
	LET r_failed_it = FALSE 
	FOREACH c6_purchdetl INTO l_rec_purchdetl.* 
		CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
		l_rec_purchdetl.order_num, 
		l_rec_purchdetl.line_num) 
		RETURNING l_rec_st_poaudit.order_qty, 
		l_rec_st_poaudit.received_qty, 
		l_rec_st_poaudit.voucher_qty, 
		l_rec_st_poaudit.unit_cost_amt, 
		l_rec_st_poaudit.ext_cost_amt, 
		l_rec_st_poaudit.unit_tax_amt, 
		l_rec_st_poaudit.ext_tax_amt, 
		l_rec_st_poaudit.line_total_amt 
		LET r_old_onorder_amt = r_old_onorder_amt 
		+ (l_rec_st_poaudit.order_qty 
		* (l_rec_st_poaudit.unit_cost_amt + l_rec_st_poaudit.unit_tax_amt)) 
		IF p_ware_code != p_from_ware_code THEN 
			IF l_rec_st_poaudit.received_qty > 0 THEN 
				LET r_failed_it = TRUE 
				EXIT FOREACH 
			END IF 
			### Only change price FOR inventory items

			IF l_rec_purchdetl.type_ind matches "IC" THEN 
				IF NOT valid_part(glob_rec_kandoouser.cmpy_code, 
				l_rec_purchdetl.ref_text, 
				p_ware_code,1,1,0,"","","") THEN 
					LET r_failed_it = TRUE 
					EXIT FOREACH 
				END IF 
				DECLARE c_prodquote SCROLL CURSOR FOR 
				SELECT * FROM prodquote 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_purchdetl.ref_text 
				AND vend_code = l_rec_purchdetl.vend_code 
				AND status_ind = "1" 
				AND expiry_date >= today 
				ORDER BY cost_amt 
				OPEN c_prodquote 
				FETCH c_prodquote INTO l_rec_dquote.* 
				IF STATUS = NOTFOUND THEN 
					SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_purchdetl.ref_text 
					AND ware_code = global_rec_purchhead.ware_code 
					LET l_cost = l_rec_prodstatus.for_cost_amt 
					* l_rec_product.pur_stk_con_qty 
					* l_rec_product.stk_sel_con_qty 
					LET l_price_curr_code = 
					l_rec_prodstatus.for_curr_code 
				ELSE 
					LET l_cost = l_rec_dquote.cost_amt 
					* l_rec_product.pur_stk_con_qty 
					* l_rec_product.stk_sel_con_qty 
					LET l_price_curr_code = l_rec_dquote.curr_code 
				END IF 
				CASE 
					WHEN l_price_curr_code = pr_vendor.currency_code 
						LET l_rec_pr_poaudit.unit_cost_amt = l_cost 
					WHEN pr_vendor.currency_code = l_base_curr_code 
						LET l_rec_pr_poaudit.unit_cost_amt = 
						conv_currency(l_cost, 
						glob_rec_kandoouser.cmpy_code, 
						l_price_curr_code, 
						"F", 
						global_rec_purchhead.order_date, 
						"B") 
					WHEN l_price_curr_code = l_base_curr_code 
						LET l_rec_pr_poaudit.unit_cost_amt = 
						conv_currency(l_cost, 
						glob_rec_kandoouser.cmpy_code, 
						pr_vendor.currency_code, 
						"T", 
						global_rec_purchhead.order_date, 
						"B") 
					OTHERWISE 
						LET l_rec_pr_poaudit.unit_cost_amt = 
						conv_currency(l_cost, 
						glob_rec_kandoouser.cmpy_code, 
						l_price_curr_code, 
						"F", 
						global_rec_purchhead.order_date, 
						"B") 
						LET l_rec_pr_poaudit.unit_cost_amt = 
						conv_currency(l_rec_pr_poaudit.unit_cost_amt, 
						glob_rec_kandoouser.cmpy_code, 
						pr_vendor.currency_code, 
						"T", 
						global_rec_purchhead.order_date, 
						"B") 
				END CASE 
				CLOSE c_prodquote 
				LET l_rec_purchdetl.vend_code = global_rec_purchhead.vend_code 
				LET l_rec_pr_poaudit.line_num = l_rec_purchdetl.line_num 
				LET l_rec_pr_poaudit.order_qty = l_rec_st_poaudit.order_qty 
				LET l_rec_pr_poaudit.unit_tax_amt = l_rec_st_poaudit.unit_tax_amt 
				IF l_rec_pr_poaudit.unit_cost_amt != l_rec_st_poaudit.unit_cost_amt THEN 
					CALL mod_po_line(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, global_rec_purchhead.*, 
					l_rec_purchdetl.*, l_rec_pr_poaudit.*) 
					RETURNING l_err_stat 
					IF l_err_stat < 0 THEN 
						RETURN l_err_stat,0,0 
					END IF 
				END IF 
				LET l_order_qty = (l_rec_pr_poaudit.order_qty 
				* l_rec_product.pur_stk_con_qty) 
				* l_rec_product.stk_sel_con_qty 
				UPDATE prodstatus 
				SET onord_qty = onord_qty - l_order_qty 
				WHERE part_code = l_rec_purchdetl.ref_text 
				AND ware_code = p_from_ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				UPDATE prodstatus 
				SET onord_qty = onord_qty + l_order_qty 
				WHERE part_code = l_rec_purchdetl.ref_text 
				AND ware_code = p_ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
		END IF 
		CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
		l_rec_purchdetl.order_num, 
		l_rec_purchdetl.line_num) 
		RETURNING l_rec_st_poaudit.order_qty, 
		l_rec_st_poaudit.received_qty, 
		l_rec_st_poaudit.voucher_qty, 
		l_rec_st_poaudit.unit_cost_amt, 
		l_rec_st_poaudit.ext_cost_amt, 
		l_rec_st_poaudit.unit_tax_amt, 
		l_rec_st_poaudit.ext_tax_amt, 
		l_rec_st_poaudit.line_total_amt 
		LET r_new_onorder_amt = r_new_onorder_amt 
		+ (l_rec_st_poaudit.order_qty 
		* (l_rec_st_poaudit.unit_cost_amt + l_rec_st_poaudit.unit_tax_amt)) 
		UPDATE purchdetl 
		SET vend_code = l_rec_purchdetl.vend_code, 
		list_cost_amt = l_rec_st_poaudit.unit_cost_amt, 
		disc_per = 0 
		WHERE cmpy_code = l_rec_purchdetl.cmpy_code 
		AND order_num = l_rec_purchdetl.order_num 
		AND line_num = l_rec_purchdetl.line_num 
		LET r_failed_it = FALSE 
	END FOREACH 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN r_failed_it,r_new_onorder_amt,r_old_onorder_amt 
END FUNCTION 


FUNCTION display_order(p_mode) 
	DEFINE p_mode CHAR(4)

	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_temp_text CHAR(20)
 
	SELECT desc_text INTO l_rec_tax.desc_text FROM tax 
	WHERE tax.tax_code = global_rec_purchhead.tax_code 
	AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT desc_text INTO l_rec_term.desc_text FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = global_rec_purchhead.term_code 
	SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = global_rec_purchhead.ware_code 
	SELECT * INTO pr_vendor.* FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = global_rec_purchhead.vend_code 
	DISPLAY BY NAME global_rec_purchhead.curr_code 
	attribute(green) 
	IF p_mode = "ADD" THEN 
		CALL pack_address(pr_vendor.addr1_text, 
		pr_vendor.addr2_text, 
		pr_vendor.addr3_text, 
		pr_vendor.city_text, 
		pr_vendor.state_code, 
		pr_vendor.post_code, 
		pr_vendor.country_code) --@db-patch_2020_10_04--
		RETURNING pr_vendor.addr1_text, 
		pr_vendor.addr2_text, 
		pr_vendor.addr3_text, 
		l_temp_text, 
		l_temp_text 
	END IF 
	DISPLAY BY NAME global_rec_purchhead.vend_code, 
	pr_vendor.name_text, 
	pr_vendor.addr1_text, 
	pr_vendor.addr2_text, 
	pr_vendor.addr3_text, 
	global_rec_purchhead.order_date, 
	global_rec_purchhead.type_ind, 
	global_rec_purchhead.salesperson_text, 
	global_rec_purchhead.term_code, 
	global_rec_purchhead.tax_code, 
	global_rec_purchhead.var_num, 
	global_rec_purchhead.ware_code, 
	l_rec_warehouse.desc_text, 
	global_rec_purchhead.conv_qty, 
	global_rec_purchhead.authorise_code, 
	global_rec_purchhead.due_date, 
	global_rec_purchhead.cancel_date, 
	global_rec_purchhead.year_num, 
	global_rec_purchhead.period_num, 
	global_rec_purchhead.status_ind, 
	global_rec_purchhead.printed_flag, 
	global_rec_purchhead.com1_text, 
	global_rec_purchhead.com2_text 

	DISPLAY l_rec_tax.desc_text, 
	l_rec_term.desc_text 
	TO tax.desc_text, 
	term.desc_text 

END FUNCTION 


FUNCTION curr_locate() 
	DEFINE l_ans CHAR(1) 
	DEFINE l_prompt_mess CHAR(80) 

	--   OPEN WINDOW w1 AT 10,7 with 1 rows, 70 columns  -- albo  KD-756
	--      ATTRIBUTE(border)
	--   prompt " Rate NOT found: \"",global_rec_purchhead.curr_code, -- albo
	--          "\" dated: ",global_rec_purchhead.order_date using "dd/mm/yyyy",
	--          " - Refer Menu GZ8 TO Add. "
	--   FOR CHAR l_ans  -- albo
	LET l_prompt_mess = " Rate NOT found: \"",global_rec_purchhead.curr_code, -- albo 
	"\" dated: ",global_rec_purchhead.order_date using "dd/mm/yyyy", 
	" - Refer Menu GZ8 TO Add. " 
	LET l_ans = promptInput(l_prompt_mess,"",1) -- albo 
	--   CLOSE WINDOW w1  -- albo  KD-756
END FUNCTION 

# This FUNCTION recalculates the purchase ORDER lines WHEN the warehouse code
# has been changed.  This only happends WHEN mode = "ADD".
FUNCTION recalc_add_lines(p_ware_code,p_from_ware_code,p_verbose_ind) 
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE p_from_ware_code LIKE warehouse.ware_code
	DEFINE p_verbose_ind SMALLINT

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_list_cost_amt LIKE purchdetl.list_cost_amt 
	DEFINE l_rec_prodquote RECORD LIKE prodquote.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_cost LIKE poaudit.unit_cost_amt 
	DEFINE l_base_curr_code LIKE arparms.currency_code 
	DEFINE l_pr_conv_rate FLOAT 

	IF p_ware_code IS NULL 
	OR p_from_ware_code IS NULL THEN 
		# Should NOT happen
		RETURN FALSE 
	END IF 
	DECLARE c7_purchdetl CURSOR FOR 
	SELECT * FROM t_purchdetl 
	WHERE type_ind = "I" 
	OR type_ind = "C" 
	# Check prodstatus exists FOR new warehouse
	FOREACH c7_purchdetl INTO l_rec_purchdetl.* 
		SELECT unique(1) FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_purchdetl.ref_text 
		AND ware_code = p_ware_code 
		IF STATUS = NOTFOUND THEN 
			IF p_verbose_ind THEN 
				LET l_msgresp = kandoomsg("I",9104,"") 
				#9104 Product IS NOT stocked AT this warehouse.
				LET l_msgresp = kandoomsg("R",7017,"") 
				#7017 Unable TO change ORDER details, UPDATE NOT performed.
				LET global_rec_purchhead.ware_code = p_from_ware_code 
			END IF 
			RETURN FALSE 
		END IF 
	END FOREACH 
	FOREACH c7_purchdetl INTO l_rec_purchdetl.* 
		### Only change price FOR inventory items

		IF l_rec_purchdetl.type_ind matches "IC" THEN 
			IF NOT valid_part(glob_rec_kandoouser.cmpy_code, 
			l_rec_purchdetl.ref_text, 
			p_ware_code,1,1,0,"","","") THEN 
				EXIT FOREACH 
			END IF 
			SELECT * INTO l_rec_product.* FROM product 
			WHERE product.part_code = l_rec_purchdetl.ref_text 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			DECLARE c_prodquote2 SCROLL CURSOR FOR 
			SELECT * FROM prodquote 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_purchdetl.ref_text 
			AND vend_code = l_rec_purchdetl.vend_code 
			AND status_ind = "1" 
			AND expiry_date >= today 
			ORDER BY cost_amt 
			OPEN c_prodquote2 
			FETCH c_prodquote2 INTO l_rec_prodquote.* 
			IF STATUS = NOTFOUND THEN 
				SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_purchdetl.ref_text 
				AND ware_code = p_ware_code 
				LET l_cost = l_rec_prodstatus.for_cost_amt 
				* l_rec_product.pur_stk_con_qty 
				* l_rec_product.stk_sel_con_qty 
				IF l_rec_prodstatus.for_curr_code = pr_vendor.currency_code THEN 
					LET l_list_cost_amt = l_cost 
				ELSE 
					SELECT currency_code INTO l_base_curr_code FROM arparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND parm_code = "1" 
					IF pr_vendor.currency_code = l_base_curr_code THEN 
						LET l_list_cost_amt = 
						conv_currency(l_cost, 
						glob_rec_kandoouser.cmpy_code, 
						l_rec_prodstatus.for_curr_code, 
						"F", 
						global_rec_purchhead.order_date, 
						"B") 
					ELSE 
						IF l_rec_prodstatus.for_curr_code = 
						l_base_curr_code THEN 
							LET l_list_cost_amt = 
							conv_currency(l_cost, 
							glob_rec_kandoouser.cmpy_code, 
							pr_vendor.currency_code, 
							"T", 
							global_rec_purchhead.order_date, 
							"B") 
						ELSE 
							LET l_list_cost_amt = 
							conv_currency(l_cost, 
							glob_rec_kandoouser.cmpy_code, 
							l_rec_prodstatus.for_curr_code, 
							"F", 
							global_rec_purchhead.order_date, 
							"B") 
							LET l_list_cost_amt = 
							conv_currency(l_list_cost_amt, 
							glob_rec_kandoouser.cmpy_code, 
							pr_vendor.currency_code, 
							"T", 
							global_rec_purchhead.order_date, 
							"B") 
						END IF 
					END IF 
				END IF 
			ELSE 
				LET l_pr_conv_rate = get_conv_rate(
					glob_rec_kandoouser.cmpy_code,
					global_rec_purchhead.curr_code,
					today,
					CASH_EXCHANGE_SELL) 
				
				LET l_cost = l_rec_prodquote.cost_amt	/ l_pr_conv_rate 
				LET l_list_cost_amt = l_cost 	* l_rec_product.pur_stk_con_qty	* l_rec_product.stk_sel_con_qty 
			END IF 
			
			CLOSE c_prodquote2 
		END IF
		 
		UPDATE t_purchdetl 
		SET vend_code = global_rec_purchhead.vend_code, 
		list_cost_amt = l_list_cost_amt 
		WHERE line_num = l_rec_purchdetl.line_num 
		UPDATE t_poaudit 
		SET line_total_amt = l_list_cost_amt 
		* t_poaudit.order_qty 
		WHERE line_num = l_rec_purchdetl.line_num 
	END FOREACH 
	RETURN TRUE 
END FUNCTION 

FUNCTION edit_delivery(p_mode,p_order_num) 
	DEFINE p_mode CHAR(4)
	DEFINE p_order_num LIKE purchhead.order_num

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(40)
	DEFINE l_err_continue CHAR(1) 

	IF p_mode = "EDIT" THEN 
		SELECT * INTO global_rec_purchhead.* ### SELECT here TO get up TO DATE data 
		FROM purchhead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = p_order_num 
	END IF 
	OPEN WINDOW r106 with FORM "R106" 
	CALL windecoration_r("R106") -- albo kd-756 
	LET l_msgresp = kandoomsg("R",1011,"") 
	#1011 Enter Delivery Address;  OK TO Continue.
	INPUT BY NAME global_rec_purchhead.del_name_text, 
	global_rec_purchhead.del_addr1_text, 
	global_rec_purchhead.del_addr2_text, 
	global_rec_purchhead.del_addr3_text, 
	global_rec_purchhead.del_addr4_text, 
	global_rec_purchhead.del_country_code, 
	global_rec_purchhead.contact_text, 
	global_rec_purchhead.tele_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","poedwind","input-global_rec_purchhead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	CLOSE WINDOW r106 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	IF p_mode = "ADD" THEN 
		RETURN TRUE 
	END IF 
	WHENEVER ERROR GOTO recovery3 
	GOTO bypass3 
	LABEL recovery3: 
	LET l_err_continue = error_recover(l_err_message, STATUS) 
	IF l_err_continue != "Y" THEN 
		RETURN FALSE 
	END IF 
	LABEL bypass3: 
	LET l_err_message = "R14a Delivery Address Update" 
	UPDATE purchhead 
	SET del_name_text = global_rec_purchhead.del_name_text, 
	del_addr1_text = global_rec_purchhead.del_addr1_text, 
	del_addr2_text = global_rec_purchhead.del_addr2_text, 
	del_addr3_text = global_rec_purchhead.del_addr3_text, 
	del_addr4_text = global_rec_purchhead.del_addr4_text, 
	del_country_code = global_rec_purchhead.del_country_code, 
	contact_text = global_rec_purchhead.contact_text, 
	tele_text = global_rec_purchhead.tele_text, 
	rev_num = rev_num + 1, 
	rev_date = today 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_num = global_rec_purchhead.order_num 
	RETURN TRUE 
END FUNCTION 
