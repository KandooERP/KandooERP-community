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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/po_common_globals.4gl" 
#GLOBALS "../common/po_mod.4gl"

#GLOBALS
#	DEFINE glob_rec_purchdetl RECORD LIKE purchdetl.*
#	DEFINE glob_rec_poaudit RECORD LIKE poaudit.*
#	DEFINE glob_rec_vendor RECORD LIKE vendor.*
#	DEFINE glob_rec_purchhead RECORD LIKE purchhead.*
#	DEFINE glob_rec_jobledger RECORD LIKE jobledger.* #not used ?
#	DEFINE glob_rec_jmresource RECORD LIKE jmresource.* #not used ?
#	DEFINE glob_onorder_total LIKE vendor.onorder_amt
#END GLOBALS


############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_min_mod_qty LIKE poaudit.order_qty 
DEFINE modu_st_poaudit RECORD LIKE poaudit.* 
DEFINE modu_ship_inv_qty LIKE shipdetl.ship_inv_qty 
DEFINE modu_ship_rec_qty LIKE shipdetl.ship_rec_qty 
DEFINE modu_ship_part_code LIKE shipdetl.part_code 
DEFINE modu_save_list_cost LIKE purchdetl.list_cost_amt 
DEFINE modu_save_disc_per LIKE purchdetl.disc_per 
############################################################
# \brief module - po_chng.4gl
# Purpose - Allows the user TO modify lines AFTER ORDER has been entered.
############################################################
# FUNCTION po_chng(p_cmpy, p_kandoouser_sign_on_code, p_ponum, p_linenum)
#
#
############################################################
FUNCTION po_chng(p_cmpy,p_kandoouser_sign_on_code,p_ponum,p_linenum) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code #huho NOT used 
	DEFINE p_ponum LIKE poaudit.po_num 
	DEFINE p_linenum LIKE poaudit.line_num 

	DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_jobvars RECORD LIKE jobvars.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_prodquote RECORD LIKE prodquote.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_charge_amt DECIMAL (16,2) 
	DEFINE l_res_code CHAR(8) 
	DEFINE l_pu_cost LIKE poaudit.line_total_amt 
	DEFINE l_price_curr_code LIKE prodstatus.for_curr_code 
	#DEFINE l_temp_tax LIKE poaudit.unit_cost_amt #not used ?
	DEFINE l_save_date LIKE poaudit.tran_date 
	DEFINE l_save_curr_code LIKE purchdetl.res_code 
	DEFINE l_save_ref_code LIKE purchdetl.ref_text 
	DEFINE l_save_acct_code LIKE purchdetl.acct_code 
	DEFINE l_save_job_code LIKE purchdetl.job_code 
	DEFINE l_tp_desc_text LIKE coa.desc_text 
	DEFINE l_save_desc_text LIKE coa.desc_text 
	DEFINE l_unit_cost_amt LIKE poaudit.ext_cost_amt 
	DEFINE l_base_curr_code LIKE glparms.base_currency_code 
	DEFINE l_new_line SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_filter_text CHAR(400) 
	DEFINE l_error_msg CHAR(100) 
	DEFINE l_temp_order_qty LIKE poaudit.order_qty 
	DEFINE l_outer_flag SMALLINT 
	DEFINE l_invalid_period SMALLINT 
	DEFINE l_limit_amt INTEGER 
	DEFINE l_pr_initial_amt INTEGER 
	DEFINE l_amt_int INTEGER 
	#DEFINE l_limit_amt INTEGER
	#DEFINE l_pr_initial_amt INTEGER
	#DEFINE l_amt_int INTEGER
	DEFINE l_low_amt CHAR(17) 
	DEFINE l_high_amt CHAR(17) 
	DEFINE l_message_text CHAR(40) 
	DEFINE l_warn_message CHAR(30) 
	DEFINE l_amt_flt FLOAT 
	DEFINE l_conv_rate FLOAT 
	DEFINE l_list_total FLOAT 
	DEFINE l_note_code CHAR(15) 
	DEFINE l_acct_mask_code LIKE warehouse.acct_mask_code 
	DEFINE l_valid_tran LIKE language.yes_flag 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_temp_amt LIKE purchdetl.list_cost_amt 
	DEFINE l_opt_enabled CHAR(1) 
	DEFINE l_save_year_num LIKE purchhead.year_num 
	DEFINE l_save_period_num LIKE purchhead.period_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT base_currency_code INTO l_base_curr_code 
	FROM glparms 
	WHERE cmpy_code = p_cmpy 
	AND key_code = "1" 
	SELECT * INTO glob_rec_purchhead.* FROM purchhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = p_ponum 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Purchase Order Header") 
		#7001 Logic Error: Purchase Order Header RECORD NOT found.
		RETURN FALSE 
	END IF 
	SELECT * INTO glob_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = glob_rec_purchhead.vend_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("P",9060,glob_rec_purchhead.vend_code) 
		#9060 Logic Error: Vendor XXXXX does NOT exist.
		RETURN FALSE 
	END IF 
	SELECT desc_text INTO l_tp_desc_text FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = glob_rec_purchdetl.acct_code 
	IF status = notfound THEN 
		LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
	END IF 
	LET l_opt_enabled = get_kandoooption_feature_state('GL','FA') 
	CALL po_line_info(p_cmpy, 
	glob_rec_purchdetl.order_num, 
	glob_rec_purchdetl.line_num) 
	RETURNING l_rec_cu_poaudit.order_qty, 
	l_rec_cu_poaudit.received_qty, 
	l_rec_cu_poaudit.voucher_qty, 
	l_rec_cu_poaudit.unit_cost_amt, 
	l_rec_cu_poaudit.ext_cost_amt, 
	l_rec_cu_poaudit.unit_tax_amt, 
	l_rec_cu_poaudit.ext_tax_amt, 
	l_rec_cu_poaudit.line_total_amt 
	### Not permitted TO change qty below received OR vouchered qty
	IF l_rec_cu_poaudit.received_qty > l_rec_cu_poaudit.voucher_qty THEN 
		LET modu_min_mod_qty = l_rec_cu_poaudit.received_qty 
	ELSE 
		LET modu_min_mod_qty = l_rec_cu_poaudit.voucher_qty 
	END IF 
	IF glob_rec_poaudit.tran_date IS NULL THEN 
		LET glob_rec_poaudit.tran_date = today 
		CALL db_period_what_period(p_cmpy, glob_rec_poaudit.tran_date) 
		RETURNING glob_rec_poaudit.year_num, 
		glob_rec_poaudit.period_num 
	END IF 
	### Cannot allow a price change IF the item IS on a shipment AND
	### has already been receipted
	LET modu_ship_part_code = NULL 
	SELECT shipdetl.part_code, 
	shipdetl.ship_inv_qty, 
	shipdetl.ship_rec_qty 
	INTO modu_ship_part_code, modu_ship_inv_qty, modu_ship_rec_qty 
	FROM shipdetl, shiphead 
	WHERE shipdetl.source_doc_num = glob_rec_purchdetl.order_num 
	AND shipdetl.doc_line_num = glob_rec_purchdetl.line_num 
	AND shipdetl.ship_inv_qty > 0 
	AND shipdetl.cmpy_code = p_cmpy 
	AND shipdetl.cmpy_code = shiphead.cmpy_code 
	AND shipdetl.ship_code = shiphead.ship_code 
	AND shiphead.finalised_flag <> "Y" 
	IF status = notfound THEN 
		LET modu_ship_inv_qty = 0 
		LET modu_ship_rec_qty = 0 
	END IF 
	LET modu_st_poaudit.* = glob_rec_poaudit.* 
	LET modu_save_list_cost = glob_rec_purchdetl.list_cost_amt 
	LET modu_save_disc_per = glob_rec_purchdetl.disc_per 
	CASE glob_rec_purchdetl.type_ind 
		WHEN "G" 
			LET l_unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
			OPEN WINDOW r143 with FORM "R143" 
			CALL windecoration_r("R143") -- albo kd-756 
			DISPLAY BY NAME glob_rec_purchhead.curr_code 
			attribute(green) 
			DISPLAY BY NAME glob_rec_purchdetl.due_date 

			DISPLAY glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.uom_code 
			TO rec_uom_code, 
			vou_uom_code 

			IF calc_totals() THEN 
			END IF 
			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.note_code, 
			glob_rec_purchdetl.acct_code, 
			l_tp_desc_text, 
			glob_rec_poaudit.received_qty, 
			glob_rec_poaudit.voucher_qty 

			IF l_opt_enabled 
			AND (glob_rec_purchdetl.acct_code IS NOT null) THEN 
				LET l_msgresp = kandoomsg("U",1533,"") 
				#1533 Checking available funds;  Please wait.
				CALL check_funds(p_cmpy, 
				glob_rec_purchdetl.acct_code, 
				glob_rec_poaudit.line_total_amt, 
				glob_rec_purchdetl.line_num, 
				glob_rec_poaudit.year_num, 
				glob_rec_poaudit.period_num, 
				"R", 
				glob_rec_purchdetl.order_num, 
				"N") 
				RETURNING l_valid_tran, l_available_amt 
				DISPLAY BY NAME l_available_amt 

			END IF 
			LET l_msgresp = kandoomsg("R",1017,"") 
			#1017 Enter line details; F5 Product Inquiry; CTRL-N Note; OK TO ...
			INPUT BY NAME glob_rec_poaudit.tran_date, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num, 
			glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.due_date, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.acct_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.list_cost_amt, 
			glob_rec_purchdetl.disc_per, 
			glob_rec_poaudit.unit_tax_amt 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","po_chng","input-poaudit-1") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "LOOKUP" infield(acct_code) 
						LET glob_rec_purchdetl.acct_code = show_acct(p_cmpy) 
						DISPLAY BY NAME glob_rec_purchdetl.acct_code 

						NEXT FIELD acct_code 

				ON ACTION "NOTES" --ON KEY (control-n) 
					IF glob_rec_purchdetl.note_code IS NOT NULL THEN 
						# Need TO reconstruct FORMAT as required by sys_noter
						# due TO hashes being stripped once returned.
						LET l_note_code = "###", 
						glob_rec_purchdetl.note_code clipped 
					END IF 
					# Now strip leading hashes as don't want TO store hashes
					# FOR note code
					LET l_note_code = sys_noter(p_cmpy,l_note_code) 
					LET glob_rec_purchdetl.note_code = l_note_code[4,15] 
					DISPLAY BY NAME glob_rec_purchdetl.note_code 

				ON KEY (F8) 
					CALL vinq_vend(p_cmpy,glob_rec_purchhead.vend_code) 
				BEFORE FIELD tran_date 
					LET l_save_date = glob_rec_poaudit.tran_date 
				AFTER FIELD tran_date 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						LET glob_rec_poaudit.tran_date = today 
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.tran_date != l_save_date THEN 
						CALL db_period_what_period(p_cmpy, glob_rec_poaudit.tran_date) 
						RETURNING glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						DISPLAY glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						TO year_num, 
						period_num 

					END IF 
				BEFORE FIELD year_num 
					LET l_save_year_num = glob_rec_poaudit.year_num 
				AFTER FIELD year_num 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
				BEFORE FIELD period_num 
					LET l_save_period_num = glob_rec_poaudit.period_num 
				AFTER FIELD period_num 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting year & period NOT SET up.
						NEXT FIELD year_num 
					END IF 
					IF l_opt_enabled 
					AND glob_rec_purchdetl.acct_code IS NOT NULL 
					AND (l_save_year_num != glob_rec_poaudit.year_num 
					OR l_save_period_num != glob_rec_poaudit.period_num) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.line_total_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						LET l_msgresp = kandoomsg("R",1017,"") 
						#1017 Enter line details; F5 Product Inquiry; CTRL+N ...
						DISPLAY BY NAME l_available_amt 

					END IF 
				AFTER FIELD order_qty 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
				AFTER FIELD list_cost_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD list_cost_amt 
					END IF 
				AFTER FIELD disc_per 
					IF NOT valid_totals() THEN 
						NEXT FIELD disc_per 
					END IF 
				AFTER FIELD unit_tax_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD unit_tax_amt 
					END IF 
				BEFORE FIELD acct_code 
					LET l_save_acct_code = glob_rec_purchdetl.acct_code 
					LET l_save_desc_text = l_tp_desc_text 
				AFTER FIELD acct_code 
					IF l_save_acct_code != glob_rec_purchdetl.acct_code THEN 
						CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num) 
						RETURNING l_rec_coa.* 
						LET l_tp_desc_text = l_rec_coa.desc_text 
						LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					END IF 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD acct_code 
					END IF 
					WHILE glob_rec_purchdetl.acct_code = " " 
						CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num) 
						RETURNING l_rec_coa.* 
						LET l_tp_desc_text = l_rec_coa.desc_text 
						LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					END WHILE 
					DISPLAY BY NAME glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					IF (glob_rec_poaudit.received_qty != 0 
					OR glob_rec_poaudit.voucher_qty != 0) AND 
					(glob_rec_purchdetl.acct_code != l_save_acct_code OR 
					l_save_acct_code IS null) THEN 
						LET l_msgresp = kandoomsg("P",9523,"") 
						#9523 WARNING: Stock already received OR vouchered.
					END IF 
					IF l_opt_enabled 
					AND (glob_rec_purchdetl.acct_code != l_save_acct_code 
					OR l_save_acct_code IS null) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.line_total_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						LET l_msgresp = kandoomsg("R",1017,"") 
						#1017 Enter line details; F5 Product Inquiry; CTRL+N ...
						DISPLAY BY NAME l_available_amt 

					END IF 
				AFTER INPUT 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					END IF 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting year & period NOT SET up.
						NEXT FIELD year_num 
					END IF 
					###  FUNCTION valid totals does the intergrity tests on ORDER qty,
					###  list price, discount AND tax.  Only one CALL needed in the
					###  AFTER INPUT section.
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					IF modu_ship_inv_qty > 0 AND 
					(glob_rec_purchdetl.list_cost_amt != modu_save_list_cost OR 
					glob_rec_purchdetl.disc_per != modu_save_disc_per OR 
					glob_rec_poaudit.unit_tax_amt != l_rec_cu_poaudit.unit_tax_amt) THEN 
						LET l_msgresp = kandoomsg("R",6000,"") 
						#6000 WARNING: ...Shipment price has NOT been changed
					END IF 
					LET l_save_acct_code = glob_rec_purchdetl.acct_code 
					LET l_save_desc_text = l_tp_desc_text 
					CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num) 
					RETURNING l_rec_coa.* 
					LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 A value must be entered
						NEXT FIELD acct_code 
					END IF 
					CALL check_funds(p_cmpy, 
					glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.line_total_amt, 
					glob_rec_purchdetl.line_num, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num, 
					"R", 
					glob_rec_purchdetl.order_num, 
					"Y") 
					RETURNING l_valid_tran, l_available_amt 
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						LET l_msgresp = kandoomsg("R",1017,"") 
						#1017 Enter line details; F5 Product Inquiry; CTRL-N Note;...
						NEXT FIELD acct_code 
					END IF 

			END INPUT 
			CLOSE WINDOW r143 
		WHEN "I" 
			LET l_save_ref_code = glob_rec_purchdetl.ref_text 
			LET l_unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
			LET l_new_line = FALSE 
			IF glob_rec_poaudit.tran_date IS NULL THEN 
				LET glob_rec_poaudit.tran_date = glob_rec_purchhead.order_date 
				CALL db_period_what_period(p_cmpy,glob_rec_poaudit.tran_date) 
				RETURNING glob_rec_poaudit.year_num, 
				glob_rec_poaudit.period_num 
			END IF 
			IF glob_rec_purchdetl.ref_text IS NOT NULL THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = glob_rec_purchdetl.ref_text 
				AND cmpy_code = p_cmpy 
			END IF 
			SELECT desc_text INTO l_tp_desc_text FROM coa 
			WHERE cmpy_code = p_cmpy 
			AND acct_code = glob_rec_purchdetl.acct_code 
			OPEN WINDOW i211 with FORM "I211" 
			CALL windecoration_i("I211") -- albo kd-756 
			DISPLAY BY NAME glob_rec_purchhead.curr_code 
			attribute(green) 
			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.oem_text, 
			l_rec_product.pur_uom_code, 
			l_rec_product.sell_uom_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.note_code, 
			glob_rec_purchdetl.acct_code, 
			l_tp_desc_text, 
			glob_rec_poaudit.received_qty, 
			glob_rec_poaudit.voucher_qty, 
			glob_rec_purchhead.ware_code 

			IF calc_totals() THEN 
			END IF 
			CALL calc_sell_uom(p_cmpy) 
			CALL display_stockstatus(p_cmpy,glob_rec_purchdetl.ref_text, 
			glob_rec_purchhead.ware_code) 
			IF l_opt_enabled 
			AND glob_rec_purchdetl.acct_code IS NOT NULL THEN 
				CALL check_funds(p_cmpy, 
				glob_rec_purchdetl.acct_code, 
				glob_rec_poaudit.line_total_amt, 
				glob_rec_purchdetl.line_num, 
				glob_rec_poaudit.year_num, 
				glob_rec_poaudit.period_num, 
				"R", 
				glob_rec_purchdetl.order_num, 
				"N") 
				RETURNING l_valid_tran, l_available_amt 
				DISPLAY BY NAME l_available_amt 

			END IF 
			LET l_msgresp = kandoomsg("R",1016,"") 
			#1016 Enter line details; F5 Part Inquiry; F8 Vendor Inquiry ...
			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.acct_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.list_cost_amt, 
			glob_rec_purchdetl.disc_per, 
			glob_rec_poaudit.unit_tax_amt, 
			glob_rec_poaudit.tran_date, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num 

			INPUT BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.acct_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.list_cost_amt, 
			glob_rec_purchdetl.disc_per, 
			glob_rec_poaudit.unit_tax_amt, 
			glob_rec_poaudit.tran_date, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","po_chng","input-poaudit-2") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON ACTION "LOOKUP" infield(ref_text) 
							LET l_filter_text= "status_ind ='1' AND part_code in ", 
							"(SELECT part_code FROM prodstatus ", 
							"WHERE cmpy_code='",p_cmpy,"' ", 
							"AND ware_code='",glob_rec_purchhead.ware_code,"' ", 
							"AND part_code=product.part_code ", 
							"AND status_ind = '1' ) " 
							LET glob_rec_purchdetl.ref_text = show_part(p_cmpy,l_filter_text) 
							DISPLAY BY NAME glob_rec_purchdetl.ref_text 

							NEXT FIELD ref_text
							 
				ON ACTION "LOOKUP" infield(acct_code) 
							LET glob_rec_purchdetl.acct_code = show_acct(p_cmpy) 
							DISPLAY BY NAME glob_rec_purchdetl.acct_code 

							NEXT FIELD acct_code 

				ON KEY (F9) 
					IF infield(ref_text) 
					AND glob_rec_purchdetl.ref_text IS NOT NULL 
					AND glob_rec_purchdetl.ref_text != " " THEN 
						SELECT * INTO l_rec_product.* FROM product 
						WHERE part_code = glob_rec_purchdetl.ref_text 
						AND cmpy_code = p_cmpy 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9010,"") 
							#9010 Product code does NOT exist;  Try Window.
							NEXT FIELD ref_text 
						END IF 
						CALL sim_warehouse(p_cmpy, 
						l_rec_product.*, 
						glob_rec_purchhead.ware_code) 
						RETURNING l_error_msg 
					END IF 
				
				ON ACTION "NOTES" --ON KEY (control-n) 
					IF glob_rec_purchdetl.note_code IS NOT NULL THEN 
						# Need TO reconstruct FORMAT as required by sys_noter
						# due TO hashes being stripped once returned.
						LET l_note_code = "###", 
						glob_rec_purchdetl.note_code clipped 
					END IF 
					# Now strip leading hashes as don't want TO store hashes
					# FOR note code
					LET l_note_code = sys_noter(p_cmpy,l_note_code) 
					LET glob_rec_purchdetl.note_code = l_note_code[4,15] 
					DISPLAY BY NAME glob_rec_purchdetl.note_code 

				ON KEY (F5) 
					IF glob_rec_purchdetl.ref_text IS NOT NULL THEN 
						CALL pinvwind(p_cmpy,glob_rec_purchdetl.ref_text) 
					END IF 
				ON KEY (F8) 
					CALL vinq_vend(p_cmpy,glob_rec_purchhead.vend_code) 
				BEFORE FIELD tran_date 
					LET l_save_date = glob_rec_poaudit.tran_date 
				AFTER FIELD tran_date 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET glob_rec_poaudit.tran_date = today 
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.tran_date != l_save_date THEN 
						CALL db_period_what_period(p_cmpy, glob_rec_poaudit.tran_date) 
						RETURNING glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						DISPLAY glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						TO year_num, 
						period_num 

					END IF 
				BEFORE FIELD year_num 
					LET l_save_year_num = glob_rec_poaudit.year_num 
				AFTER FIELD year_num 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
				BEFORE FIELD period_num 
					LET l_save_period_num = glob_rec_poaudit.period_num 
				AFTER FIELD period_num 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting period IS closed OR NOT SET up.
						NEXT FIELD year_num 
					END IF 
					IF l_opt_enabled 
					AND (fgl_lastkey() = fgl_keyval("up") 
					OR fgl_lastkey() = fgl_keyval("left")) 
					AND (l_save_year_num != glob_rec_poaudit.year_num 
					OR l_save_period_num != glob_rec_poaudit.period_num) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.line_total_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						LET l_msgresp = kandoomsg("R",1016,"") 
						#1016 Enter line details; F5 Part Inquiry; F8 Vendor ...
						DISPLAY BY NAME l_available_amt 

					END IF 
				AFTER FIELD ref_text 
					IF l_save_ref_code != glob_rec_purchdetl.ref_text THEN 
						IF modu_min_mod_qty > 0 THEN 
							LET l_msgresp = kandoomsg("P",9524,"") 
							#9524 "Cannot change product FOR a partially..."
							LET glob_rec_purchdetl.ref_text = l_save_ref_code 
							NEXT FIELD ref_text 
						END IF 
						IF modu_ship_part_code IS NOT NULL AND 
						glob_rec_purchdetl.ref_text != modu_ship_part_code THEN 
							LET l_msgresp = kandoomsg("R",9018,"") 
							#9018 "Product IS on a shipment..."
							LET glob_rec_purchdetl.ref_text = l_save_ref_code 
							NEXT FIELD ref_text 
						END IF 
						LET l_new_line = TRUE 
					END IF 
					IF l_new_line THEN 
						SELECT * INTO l_rec_product.* FROM product 
						WHERE product.part_code = glob_rec_purchdetl.ref_text 
						AND product.cmpy_code = p_cmpy 
						IF l_rec_product.super_part_code IS NOT NULL THEN 
							LET l_idx = 0 
							WHILE l_rec_product.super_part_code IS NOT NULL 
								LET l_idx = l_idx + 1 
								IF l_idx > 20 THEN 
									LET l_msgresp = kandoomsg("E",9183,"") 
									#9183 Session limit exceeded during replacement ...
									LET glob_rec_purchdetl.ref_text = NULL 
								END IF 
								IF NOT valid_part(p_cmpy,l_rec_product.super_part_code, 
								glob_rec_purchhead.ware_code, 
								1,2,0,"","","") THEN 
									NEXT FIELD ref_text 
									LET glob_rec_purchdetl.ref_text = NULL 
								END IF 
								SELECT * INTO l_rec_product.* FROM product 
								WHERE cmpy_code = p_cmpy 
								AND part_code = l_rec_product.super_part_code 
							END WHILE 
							LET l_msgresp = kandoomsg("E",7060,l_rec_product.part_code) 
							#7060 Product replaced by superseded product.
							LET glob_rec_purchdetl.ref_text = l_rec_product.part_code 
							DISPLAY BY NAME glob_rec_purchdetl.ref_text 

						ELSE 
							IF NOT valid_part(p_cmpy, 
							glob_rec_purchdetl.ref_text, 
							glob_rec_purchhead.ware_code, 
							1,1,0,"","","") THEN 
								NEXT FIELD ref_text 
							END IF 
						END IF 
						SELECT category.* INTO l_rec_category.* FROM category 
						WHERE cmpy_code = p_cmpy 
						AND cat_code = l_rec_product.cat_code 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9521,"") 
							#9521 WARNING: Product category FOR product does NOT exist.
							NEXT FIELD ref_text 
						END IF 
						DECLARE c_prodquote SCROLL CURSOR FOR 
						SELECT * FROM prodquote 
						WHERE cmpy_code = p_cmpy 
						AND part_code = glob_rec_purchdetl.ref_text 
						AND vend_code = glob_rec_purchdetl.vend_code 
						AND status_ind = "1" 
						AND expiry_date >= today 
						ORDER BY cost_amt 
						OPEN c_prodquote 
						FETCH c_prodquote INTO l_rec_prodquote.* 
						IF status = notfound THEN 
							SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
							WHERE cmpy_code = p_cmpy 
							AND part_code = glob_rec_purchdetl.ref_text 
							AND ware_code = glob_rec_purchhead.ware_code 
							LET l_pu_cost = l_rec_prodstatus.for_cost_amt 
							* l_rec_product.pur_stk_con_qty 
							* l_rec_product.stk_sel_con_qty 
							LET l_price_curr_code = 
							l_rec_prodstatus.for_curr_code 
						ELSE 
							LET l_pu_cost = l_rec_prodquote.cost_amt 
							* l_rec_product.pur_stk_con_qty 
							* l_rec_product.stk_sel_con_qty 
							LET l_price_curr_code = l_rec_prodquote.curr_code 
						END IF 
						CASE 
							WHEN l_price_curr_code = glob_rec_vendor.currency_code 
								LET glob_rec_purchdetl.list_cost_amt = l_pu_cost 
							WHEN glob_rec_vendor.currency_code = l_base_curr_code 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								l_price_curr_code, 
								"F", 
								glob_rec_purchhead.order_date, 
								"B") 
							WHEN l_price_curr_code = l_base_curr_code 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								glob_rec_vendor.currency_code, 
								"T", 
								glob_rec_purchhead.order_date, 
								"B") 
							OTHERWISE 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								l_price_curr_code, 
								"F", 
								glob_rec_purchhead.order_date, 
								"B") 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(glob_rec_purchdetl.list_cost_amt, 
								p_cmpy, 
								glob_rec_vendor.currency_code, 
								"T", 
								glob_rec_purchhead.order_date, 
								"B") 
						END CASE 
						CLOSE c_prodquote 
						LET glob_rec_purchdetl.uom_code = l_rec_product.pur_uom_code 
						LET l_unit_cost_amt = glob_rec_purchdetl.list_cost_amt 
						LET glob_rec_purchdetl.desc_text = l_rec_product.desc_text 
						LET glob_rec_purchdetl.desc2_text = l_rec_product.desc2_text 
						LET glob_rec_purchdetl.oem_text = l_rec_product.oem_text 
						SELECT acct_mask_code INTO l_acct_mask_code FROM warehouse 
						WHERE cmpy_code = p_cmpy 
						AND ware_code = glob_rec_purchhead.ware_code 
						LET glob_rec_purchdetl.acct_code = build_mask(p_cmpy, 
						l_acct_mask_code, 
						l_rec_category.stock_acct_code) 
					END IF 
					SELECT desc_text INTO l_tp_desc_text FROM coa 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = glob_rec_purchdetl.acct_code 
					IF status = notfound THEN 
						LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
					END IF 
					CALL display_stockstatus(p_cmpy,glob_rec_purchdetl.ref_text, 
					glob_rec_purchhead.ware_code) 
					IF calc_totals() THEN 
					END IF 
					CALL calc_sell_uom(p_cmpy) 
					DISPLAY BY NAME glob_rec_purchdetl.oem_text, 
					l_rec_product.pur_uom_code, 
					l_rec_product.sell_uom_code, 
					glob_rec_purchdetl.desc_text, 
					glob_rec_purchdetl.desc2_text, 
					glob_rec_purchdetl.list_cost_amt, 
					glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					IF l_new_line 
					AND l_opt_enabled 
					AND glob_rec_purchdetl.acct_code IS NOT NULL THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.line_total_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						DISPLAY BY NAME l_available_amt 

						LET l_msgresp = kandoomsg("R",1016,"") 
						#1016 Enter line details; F5 Part Inquiry; F8 Vendor ...
					END IF 
				AFTER FIELD order_qty 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					### Outer quantity test
					LET l_outer_flag = FALSE 
					SELECT * INTO l_rec_product.* FROM product 
					WHERE cmpy_code = p_cmpy 
					AND part_code = glob_rec_purchdetl.ref_text 
					IF l_rec_product.min_ord_qty IS NOT NULL 
					AND l_rec_product.min_ord_qty != 0 THEN 
						IF glob_rec_poaudit.order_qty < l_rec_product.min_ord_qty THEN 
							LET l_outer_flag = TRUE 
							LET l_msgresp=kandoomsg("N",7014,l_rec_product.min_ord_qty) 
							#7014 Requested quantity IS less than...
						END IF 
					END IF 
					IF NOT l_outer_flag THEN 
						IF glob_rec_poaudit.order_qty != 0 
						AND (l_rec_product.outer_qty != 0 
						AND l_rec_product.outer_qty IS NOT null) THEN 
							LET l_amt_int = glob_rec_poaudit.order_qty 
							/ l_rec_product.outer_qty 
							LET l_amt_flt = glob_rec_poaudit.order_qty 
							/ l_rec_product.outer_qty 
							IF (l_amt_flt - l_amt_int) > 0 
							AND (glob_rec_poaudit.order_qty < l_rec_product.outer_qty) THEN 
								LET l_msgresp = kandoomsg("N",9061,l_rec_product.outer_qty) 
								#9061 Quantity IS NOT a multiple of the pack size.
							END IF 
							IF (l_amt_flt - l_amt_int) > 0 
							AND (glob_rec_poaudit.order_qty > l_rec_product.outer_qty) THEN 
								LET l_limit_amt = l_rec_product.outer_qty * l_amt_int 
								LET l_low_amt = l_limit_amt USING "<<<<<<<<&" 
								LET l_pr_initial_amt = l_limit_amt + l_rec_product.outer_qty 
								LET l_high_amt = l_pr_initial_amt USING "<<<<<<<<&" 
								LET l_message_text = l_low_amt clipped," OR ", 
								l_high_amt clipped 
								LET l_msgresp = kandoomsg("N",9061,l_MESSAGE_text) 
								#9061 Quantity IS NOT a multiple of the pack size.
							END IF 
						END IF 
					END IF 
					CALL calc_sell_uom(p_cmpy) 
				AFTER FIELD list_cost_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD list_cost_amt 
					END IF 
					CALL calc_sell_uom(p_cmpy) 
				AFTER FIELD disc_per 
					IF NOT valid_totals() THEN 
						NEXT FIELD disc_per 
					END IF 
					CALL calc_sell_uom(p_cmpy) 
				AFTER FIELD unit_tax_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD unit_tax_amt 
					END IF 
					CALL calc_sell_uom(p_cmpy) 
				BEFORE FIELD acct_code 
					LET l_save_acct_code = glob_rec_purchdetl.acct_code 
					LET l_save_desc_text = l_tp_desc_text 
				AFTER FIELD acct_code 
					IF l_save_acct_code != glob_rec_purchdetl.acct_code THEN 
						CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num) 
						RETURNING l_rec_coa.* 
						LET l_tp_desc_text = l_rec_coa.desc_text 
						LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					END IF 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD acct_code 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					IF (glob_rec_poaudit.received_qty != 0 OR 
					glob_rec_poaudit.voucher_qty != 0) AND 
					(glob_rec_purchdetl.acct_code != l_save_acct_code OR 
					l_save_acct_code IS null) THEN 
						LET l_msgresp = kandoomsg("P",9523,"") 
						#9523 Warning - Stock already received OR vouchered.
					END IF 
					IF l_opt_enabled 
					AND (glob_rec_purchdetl.acct_code != l_save_acct_code 
					OR l_save_acct_code IS null) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						glob_rec_poaudit.line_total_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						DISPLAY BY NAME l_available_amt 

						LET l_msgresp = kandoomsg("R",1016,"") 
						#1016 Enter line details; F5 Part Inquiry; F8 Vendor ...
					END IF 
				AFTER INPUT 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					END IF 
					###  FUNCTION valid totals does the integrity tests on ORDER qty,
					###  list price, discount AND tax.  Only one CALL needed in the
					###  AFTER INPUT section.
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					IF modu_ship_inv_qty > 0 AND 
					(glob_rec_purchdetl.list_cost_amt != modu_save_list_cost OR 
					glob_rec_purchdetl.disc_per != modu_save_disc_per OR 
					glob_rec_poaudit.unit_tax_amt != l_rec_cu_poaudit.unit_tax_amt) THEN 
						LET l_msgresp = kandoomsg("R",6000,"") 
						#6000 WARNING: ...Shipment price has NOT been changed
					END IF 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting year & period NOT SET up.
						NEXT FIELD year_num 
					END IF 
					LET l_save_acct_code = glob_rec_purchdetl.acct_code 
					LET l_save_desc_text = l_tp_desc_text 
					CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num) 
					RETURNING l_rec_coa.* 
					LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD acct_code 
					END IF 
					CALL check_funds(p_cmpy, 
					glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.line_total_amt, 
					glob_rec_purchdetl.line_num, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num, 
					"R", 
					glob_rec_purchdetl.order_num, 
					"Y") 
					RETURNING l_valid_tran, l_available_amt 
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						LET l_msgresp = kandoomsg("R",1016,"") 
						#1016 Enter line details; F5 Part Inquiry; F8 Vendor ...
						NEXT FIELD acct_code 
					END IF 

			END INPUT 
			CLOSE WINDOW i211 
		WHEN "J" 
			LET l_save_curr_code = glob_rec_purchdetl.res_code 
			LET l_save_acct_code = glob_rec_purchdetl.acct_code 
			LET l_save_job_code = glob_rec_purchdetl.job_code 
			LET l_save_desc_text = l_tp_desc_text 
			OPEN WINDOW j177 with FORM "J177" 
			CALL windecoration_j("J177") -- albo kd-756 
			DISPLAY BY NAME glob_rec_purchhead.curr_code 
			attribute(green) 
			DISPLAY BY NAME glob_rec_purchdetl.due_date 

			DISPLAY glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.uom_code 
			TO rec_uom_code, 
			vou_uom_code 

			SELECT title_text, wip_acct_code 
			INTO l_rec_job.title_text, l_rec_job.wip_acct_code 
			FROM job 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			SELECT jobvars.title_text INTO l_rec_jobvars.title_text FROM jobvars 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			SELECT activity.title_text INTO l_rec_activity.title_text FROM activity 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			AND activity_code = glob_rec_purchdetl.activity_code 
			SELECT jmresource.* INTO glob_rec_jmresource.* FROM jmresource 
			WHERE cmpy_code = p_cmpy 
			AND res_code = l_save_curr_code 
			LET glob_rec_jmresource.unit_bill_amt =glob_rec_purchdetl.charge_amt 
			LET glob_rec_jmresource.res_code = glob_rec_purchdetl.res_code 
			DISPLAY BY NAME glob_rec_purchdetl.oem_text, 
			glob_rec_jmresource.res_code, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.note_code, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_jmresource.unit_code, 
			glob_rec_jmresource.unit_bill_amt, 
			glob_rec_purchdetl.activity_code, 
			glob_rec_purchdetl.acct_code, 
			l_tp_desc_text, 
			glob_rec_poaudit.received_qty, 
			glob_rec_poaudit.voucher_qty 

			DISPLAY l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text 
			TO job.title_text, 
			jobvars.title_text, 
			activity.title_text 

			IF calc_totals() THEN 
			END IF 
			CALL calc_jm_totals() 
			RETURNING glob_rec_jmresource.unit_cost_amt, 
			glob_rec_jobledger.trans_amt, 
			glob_rec_jobledger.charge_amt 
			IF l_opt_enabled 
			AND glob_rec_purchdetl.acct_code IS NOT NULL THEN 
				LET l_temp_amt = glob_rec_purchdetl.list_cost_amt 
				* glob_rec_poaudit.order_qty 
				LET l_msgresp = kandoomsg("U",1533,"") 
				#1533 Checking available funds;  Please wait.
				CALL check_funds(p_cmpy, 
				glob_rec_purchdetl.acct_code, 
				l_temp_amt, 
				glob_rec_purchdetl.line_num, 
				glob_rec_poaudit.year_num, 
				glob_rec_poaudit.period_num, 
				"R", 
				glob_rec_purchdetl.order_num, 
				"N") 
				RETURNING l_valid_tran, l_available_amt 
				DISPLAY BY NAME l_available_amt 

			END IF 
			LET l_msgresp = kandoomsg("R",1017,"") 
			#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; OK TO ...
			INPUT BY NAME glob_rec_poaudit.tran_date, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num, 
			glob_rec_jmresource.res_code, 
			glob_rec_purchdetl.due_date, 
			glob_rec_purchdetl.oem_text, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_purchdetl.activity_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.list_cost_amt, 
			glob_rec_purchdetl.disc_per, 
			glob_rec_jmresource.unit_bill_amt, 
			glob_rec_purchdetl.acct_code 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","po_chng","input-poaudit-3") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON ACTION "LOOKUP" infield(res_code) 
							LET glob_rec_jmresource.res_code = show_res(p_cmpy) 
							DISPLAY BY NAME glob_rec_jmresource.res_code 


				ON ACTION "LOOKUP" infield(job_code) 
							LET glob_rec_purchdetl.job_code = show_job(p_cmpy) 
							DISPLAY BY NAME glob_rec_purchdetl.job_code 

				ON ACTION "LOOKUP" infield(var_num) 
							LET glob_rec_purchdetl.var_num = 
							show_jobvars(p_cmpy, glob_rec_purchdetl.job_code) 
							DISPLAY BY NAME glob_rec_purchdetl.var_num 

				ON ACTION "LOOKUP"  infield(activity_code) 
							LET glob_rec_purchdetl.activity_code = 
							show_activity(p_cmpy, glob_rec_purchdetl.job_code, 
							glob_rec_purchdetl.var_num) 
							DISPLAY BY NAME glob_rec_purchdetl.activity_code 

				ON ACTION "LOOKUP" infield(acct_code) 
							LET glob_rec_purchdetl.acct_code = show_acct(p_cmpy) 
							DISPLAY BY NAME glob_rec_purchdetl.acct_code 

							NEXT FIELD acct_code 
					
				ON ACTION "NOTES" --ON KEY (control-n) 
					IF glob_rec_purchdetl.note_code IS NOT NULL THEN 
						# Need TO reconstruct FORMAT as required by sys_noter
						# due TO hashes being stripped once returned.
						LET l_note_code = "###", 
						glob_rec_purchdetl.note_code clipped 
					END IF 
					# Now strip leading hashes as don't want TO store hashes
					# FOR note code
					LET l_note_code = sys_noter(p_cmpy,l_note_code) 
					LET glob_rec_purchdetl.note_code = l_note_code[4,15] 
					DISPLAY BY NAME glob_rec_purchdetl.note_code 

				ON KEY (F8) 
					CALL vinq_vend(p_cmpy,glob_rec_purchhead.vend_code) 
					
				BEFORE FIELD tran_date 
					LET l_save_date = glob_rec_poaudit.tran_date 
					
				AFTER FIELD tran_date 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						LET glob_rec_poaudit.tran_date = today 
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.tran_date != l_save_date THEN 
						CALL db_period_what_period(p_cmpy, glob_rec_poaudit.tran_date) 
						RETURNING glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						DISPLAY glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						TO year_num, 
						period_num 

					END IF 
					
				BEFORE FIELD year_num 
					LET l_save_year_num = glob_rec_poaudit.year_num 
					
				AFTER FIELD year_num 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
					
				BEFORE FIELD period_num 
					LET l_save_period_num = glob_rec_poaudit.period_num 
					
				AFTER FIELD period_num 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting period IS closed OR NOT SET up.
						NEXT FIELD period_num 
					END IF 
					IF l_opt_enabled 
					AND glob_rec_purchdetl.acct_code IS NOT NULL 
					AND (l_save_year_num != glob_rec_poaudit.year_num 
					OR l_save_period_num != glob_rec_poaudit.period_num) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						l_temp_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						DISPLAY BY NAME l_available_amt 

						LET l_msgresp = kandoomsg("R",1017,"") 
						#1017 Enter line details; F5 Product Inquiry; CTRL+N Notes;
					END IF 
					
				AFTER FIELD res_code 
					IF l_save_curr_code != glob_rec_jmresource.res_code 
					OR l_save_curr_code IS NULL 
					OR glob_rec_jmresource.res_code IS NULL THEN 
						IF modu_min_mod_qty > 0 THEN 
							LET l_msgresp = kandoomsg("P",9525,"") 
							#9525 Cannot change resource on a receipted ...
							LET glob_rec_jmresource.res_code = l_save_curr_code 
							NEXT FIELD res_code 
						END IF 
						LET l_new_line = TRUE 
					END IF 
					
					SELECT * INTO glob_rec_jmresource.* FROM jmresource 
					WHERE cmpy_code = p_cmpy 
					AND res_code = glob_rec_jmresource.res_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try window"
						NEXT FIELD res_code 
					END IF 

					IF l_save_curr_code != glob_rec_jmresource.res_code THEN 
						LET glob_rec_purchdetl.desc_text = glob_rec_jmresource.desc_text 
						LET glob_rec_purchdetl.acct_code = glob_rec_jmresource.exp_acct_code 
						CALL build_mask(p_cmpy, glob_rec_purchdetl.acct_code, 
						l_rec_job.wip_acct_code) 
						RETURNING glob_rec_purchdetl.acct_code 
					END IF 
					
					SELECT desc_text INTO l_tp_desc_text FROM coa 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = glob_rec_purchdetl.acct_code 
					IF status = notfound THEN 
						LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
					END IF 
					
					IF NOT l_new_line THEN 
						LET glob_rec_jmresource.unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
						LET glob_rec_jmresource.unit_bill_amt = glob_rec_purchdetl.charge_amt 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.desc_text, 
					glob_rec_poaudit.order_qty, 
					glob_rec_jmresource.unit_code, 
					glob_rec_jmresource.unit_bill_amt, 
					glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					LET l_temp_amt = glob_rec_purchdetl.list_cost_amt 
					* glob_rec_poaudit.order_qty 
					IF l_new_line THEN 
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						l_temp_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"Y") 
						RETURNING l_valid_tran, l_available_amt 
					END IF 
					LET l_msgresp = kandoomsg("R",1017,"") 
					#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; ...
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						NEXT FIELD res_code 
					END IF 
					IF calc_totals() THEN 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 

				AFTER FIELD job_code 
					IF glob_rec_purchdetl.job_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD job_code 
					END IF 
					SELECT * INTO l_rec_job.* FROM job 
					WHERE job.cmpy_code = p_cmpy 
					AND job.job_code = glob_rec_purchdetl.job_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try Window"
						NEXT FIELD job_code 
					ELSE 

						IF l_save_curr_code[1,8] != glob_rec_jmresource.res_code 
						OR l_save_job_code != glob_rec_purchdetl.job_code THEN 
							LET glob_rec_purchdetl.acct_code = glob_rec_jmresource.exp_acct_code 
							CALL build_mask(p_cmpy, glob_rec_purchdetl.acct_code, 
							l_rec_job.wip_acct_code) 
							RETURNING glob_rec_purchdetl.acct_code 
							SELECT desc_text INTO l_tp_desc_text FROM coa 
							WHERE cmpy_code = p_cmpy 
							AND acct_code = glob_rec_purchdetl.acct_code 
							IF status = notfound THEN 
								LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
							END IF 
							LET l_save_job_code = glob_rec_purchdetl.job_code 
						END IF 
						DISPLAY BY NAME l_rec_job.title_text, 
						glob_rec_purchdetl.acct_code, 
						l_tp_desc_text 

					END IF 
				AFTER FIELD var_num 
					IF glob_rec_purchdetl.var_num IS NULL THEN 
						LET glob_rec_purchdetl.var_num = 0 
						DISPLAY BY NAME glob_rec_purchdetl.var_num 

					END IF 
					SELECT title_text INTO l_rec_jobvars.title_text FROM jobvars 
					WHERE jobvars.cmpy_code = p_cmpy 
					AND jobvars.job_code = glob_rec_purchdetl.job_code 
					AND jobvars.var_code = glob_rec_purchdetl.var_num 
					IF status = notfound 
					AND glob_rec_purchdetl.var_num != 0 THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try Window"
						NEXT FIELD job_code 
					ELSE 
						DISPLAY l_rec_jobvars.title_text 
						TO jobvars.title_text 

					END IF 
				AFTER FIELD activity_code 
					IF glob_rec_purchdetl.activity_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD activity_code 
					END IF 
					SELECT * INTO l_rec_activity.* FROM activity 
					WHERE activity.cmpy_code = p_cmpy 
					AND activity.job_code = glob_rec_purchdetl.job_code 
					AND activity.var_code = glob_rec_purchdetl.var_num 
					AND activity.activity_code = glob_rec_purchdetl.activity_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("J",9512,"") 
						#9512 "Activity NOT found FOR this Job & Variation"
						NEXT FIELD job_code 
					END IF 
					IF l_rec_activity.finish_flag = "Y" THEN 
						LET l_msgresp = kandoomsg("J",9513,"") 
						#9513 "This Activity IS finished - No Costs..."
						NEXT FIELD job_code 
					END IF 
					DISPLAY l_rec_activity.title_text 
					TO activity.title_text 

				AFTER FIELD order_qty 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					LET glob_rec_jobledger.trans_amt = glob_rec_poaudit.order_qty * 
					l_unit_cost_amt 
					LET glob_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty * 
					glob_rec_jmresource.unit_bill_amt 
					DISPLAY BY NAME glob_rec_poaudit.order_qty, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 

					IF calc_totals() THEN 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				AFTER FIELD list_cost_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD list_cost_amt 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				AFTER FIELD disc_per 
					IF NOT valid_totals() THEN 
						NEXT FIELD disc_per 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				BEFORE FIELD unit_bill_amt 
					IF glob_rec_jmresource.bill_ind = "2" THEN 
						EXIT INPUT 
					END IF 
				AFTER FIELD unit_bill_amt 
					IF glob_rec_jmresource.unit_bill_amt IS NULL THEN 
						LET glob_rec_jmresource.unit_bill_amt = 0 
					END IF 
					LET glob_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty * 
					glob_rec_jmresource.unit_bill_amt 
					DISPLAY BY NAME glob_rec_jobledger.charge_amt 

				AFTER INPUT 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					END IF 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting year & period NOT SET up.
						NEXT FIELD year_num 
					END IF 
					IF glob_rec_jmresource.res_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD res_code 
					END IF 
					IF glob_rec_purchdetl.job_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD job_code 
					END IF 
					IF glob_rec_purchdetl.var_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD var_num 
					END IF 
					IF glob_rec_purchdetl.activity_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9105 "Value must be entered"
						NEXT FIELD activity_code 
					END IF 
					SELECT title_text INTO l_rec_jobvars.title_text FROM jobvars 
					WHERE jobvars.cmpy_code = p_cmpy 
					AND jobvars.job_code = glob_rec_purchdetl.job_code 
					AND jobvars.var_code = glob_rec_purchdetl.var_num 
					IF status = notfound 
					AND glob_rec_purchdetl.var_num != 0 THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD NOT found;  Try Window.
						NEXT FIELD job_code 
					END IF 
					SELECT * INTO l_rec_activity.* FROM activity 
					WHERE activity.cmpy_code = p_cmpy 
					AND activity.job_code = glob_rec_purchdetl.job_code 
					AND activity.var_code = glob_rec_purchdetl.var_num 
					AND activity.activity_code = glob_rec_purchdetl.activity_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("J",9512,"") 
						#9512 This activity NOT found FOR this job/variation.
						NEXT FIELD job_code 
					END IF 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					IF modu_ship_inv_qty > 0 AND 
					(glob_rec_purchdetl.list_cost_amt != modu_save_list_cost OR 
					glob_rec_purchdetl.disc_per != modu_save_disc_per OR 
					glob_rec_poaudit.unit_tax_amt != l_rec_cu_poaudit.unit_tax_amt) THEN 
						LET l_msgresp = kandoomsg("R",6000,"") 
						#6000 WARNING: ...Shipment price has NOT been changed
					END IF 
					CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num) 
					RETURNING l_rec_coa.* 
					LET l_tp_desc_text = l_rec_coa.desc_text 
					LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD acct_code 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					LET l_temp_amt = glob_rec_purchdetl.list_cost_amt 
					* glob_rec_poaudit.order_qty 
					CALL check_funds(p_cmpy, 
					glob_rec_purchdetl.acct_code, 
					l_temp_amt, 
					glob_rec_purchdetl.line_num, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num, 
					"R", 
					glob_rec_purchdetl.order_num, 
					"Y") 
					RETURNING l_valid_tran, l_available_amt 
					LET l_msgresp = kandoomsg("R",1017,"") 
					#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; ...
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						NEXT FIELD order_qty 
					END IF 

			END INPUT 
			LET glob_rec_purchdetl.res_code = glob_rec_jmresource.res_code 
			LET glob_rec_purchdetl.charge_amt = glob_rec_jmresource.unit_bill_amt 
			LET glob_rec_poaudit.ext_cost_amt = glob_rec_jobledger.trans_amt 
			LET glob_rec_poaudit.line_total_amt = glob_rec_jobledger.trans_amt 
			LET glob_rec_poaudit.unit_cost_amt = glob_rec_jmresource.unit_cost_amt 
			LET glob_rec_poaudit.unit_tax_amt = 0 
			LET glob_rec_poaudit.ext_tax_amt = 0 
			LET glob_rec_poaudit.desc_text = glob_rec_purchdetl.desc_text 
			CLOSE WINDOW j177 
		WHEN "C" 
			LET l_save_curr_code = glob_rec_purchdetl.res_code 
			LET l_save_ref_code = glob_rec_purchdetl.ref_text 
			LET l_save_acct_code = glob_rec_purchdetl.acct_code 
			LET l_save_job_code = glob_rec_purchdetl.job_code 
			LET l_save_desc_text = l_tp_desc_text 
			OPEN WINDOW j177 with FORM "J177a" 
			CALL windecoration_j("J177a") -- albo kd-756 
			DISPLAY BY NAME glob_rec_purchhead.curr_code 
			attribute(green) 
			DISPLAY BY NAME glob_rec_purchdetl.due_date 

			DISPLAY glob_rec_purchdetl.uom_code, 
			glob_rec_purchdetl.uom_code 
			TO rec_uom_code, 
			vou_uom_code 

			IF glob_rec_purchdetl.ref_text IS NOT NULL THEN 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE part_code = glob_rec_purchdetl.ref_text 
				AND cmpy_code = p_cmpy 
			END IF 
			SELECT title_text, wip_acct_code 
			INTO l_rec_job.title_text, l_rec_job.wip_acct_code 
			FROM job 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			SELECT jobvars.title_text INTO l_rec_jobvars.title_text FROM jobvars 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			SELECT activity.title_text INTO l_rec_activity.title_text FROM activity 
			WHERE cmpy_code = p_cmpy 
			AND job_code = glob_rec_purchdetl.job_code 
			AND var_code = glob_rec_purchdetl.var_num 
			AND activity_code = glob_rec_purchdetl.activity_code 
			SELECT jmresource.* INTO glob_rec_jmresource.* FROM jmresource 
			WHERE cmpy_code = p_cmpy 
			AND res_code = l_save_curr_code 
			LET glob_rec_jmresource.unit_bill_amt =glob_rec_purchdetl.charge_amt 
			LET glob_rec_jmresource.res_code = glob_rec_purchdetl.res_code 
			DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
			glob_rec_jmresource.res_code, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.note_code, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_jmresource.unit_code, 
			glob_rec_jmresource.unit_bill_amt, 
			glob_rec_purchdetl.activity_code, 
			glob_rec_purchdetl.acct_code, 
			l_tp_desc_text, 
			glob_rec_poaudit.received_qty, 
			glob_rec_poaudit.voucher_qty 

			DISPLAY l_rec_job.title_text, 
			l_rec_jobvars.title_text, 
			l_rec_activity.title_text 
			TO job.title_text, 
			jobvars.title_text, 
			activity.title_text 

			IF calc_totals() THEN 
			END IF 
			CALL calc_jm_totals() 
			RETURNING glob_rec_jmresource.unit_cost_amt, 
			glob_rec_jobledger.trans_amt, 
			glob_rec_jobledger.charge_amt 
			IF l_opt_enabled 
			AND glob_rec_purchdetl.acct_code IS NOT NULL THEN 
				LET l_temp_amt = glob_rec_purchdetl.list_cost_amt 
				* glob_rec_poaudit.order_qty 
				LET l_msgresp = kandoomsg("U",1533,"") 
				#1533 Checking available funds;  Please wait.
				CALL check_funds(p_cmpy, 
				glob_rec_purchdetl.acct_code, 
				l_temp_amt, 
				glob_rec_purchdetl.line_num, 
				glob_rec_poaudit.year_num, 
				glob_rec_poaudit.period_num, 
				"R", 
				glob_rec_purchdetl.order_num, 
				"N") 
				RETURNING l_valid_tran, l_available_amt 
				DISPLAY BY NAME l_available_amt 

			END IF 
			LET l_msgresp = kandoomsg("R",1017,"") 
			#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; OK TO ...
			INPUT BY NAME glob_rec_poaudit.tran_date, 
			glob_rec_poaudit.year_num, 
			glob_rec_poaudit.period_num, 
			glob_rec_jmresource.res_code, 
			glob_rec_purchdetl.due_date, 
			glob_rec_purchdetl.ref_text, 
			glob_rec_purchdetl.desc_text, 
			glob_rec_purchdetl.desc2_text, 
			glob_rec_purchdetl.job_code, 
			glob_rec_purchdetl.var_num, 
			glob_rec_purchdetl.activity_code, 
			glob_rec_poaudit.order_qty, 
			glob_rec_purchdetl.list_cost_amt, 
			glob_rec_purchdetl.disc_per, 
			glob_rec_jmresource.unit_bill_amt, 
			glob_rec_purchdetl.acct_code 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","po_chng","input-poaudit-4") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON ACTION "LOOKUP" infield(ref_text) 
							LET l_filter_text= "status_ind ='1' AND part_code in ", 
							"(SELECT part_code FROM prodstatus ", 
							"WHERE cmpy_code='",p_cmpy,"' ", 
							"AND ware_code='",glob_rec_purchhead.ware_code,"' ", 
							"AND part_code=product.part_code ", 
							"AND status_ind = '1' ) " 
							LET glob_rec_purchdetl.ref_text = show_part(p_cmpy,l_filter_text) 
							DISPLAY BY NAME glob_rec_purchdetl.ref_text 

				ON ACTION "LOOKUP" infield(res_code) 
							LET glob_rec_jmresource.res_code = show_res(p_cmpy) 
							DISPLAY BY NAME glob_rec_jmresource.res_code 

				ON ACTION "LOOKUP" infield(job_code) 
							LET glob_rec_purchdetl.job_code = show_job(p_cmpy) 
							DISPLAY BY NAME glob_rec_purchdetl.job_code 

				ON ACTION "LOOKUP" infield(var_num) 
							LET glob_rec_purchdetl.var_num = 
							show_jobvars(p_cmpy, glob_rec_purchdetl.job_code) 
							DISPLAY BY NAME glob_rec_purchdetl.var_num 

				ON ACTION "LOOKUP" infield(activity_code) 
							LET glob_rec_purchdetl.activity_code = 
							show_activity(p_cmpy, glob_rec_purchdetl.job_code, 
							glob_rec_purchdetl.var_num) 
							DISPLAY BY NAME glob_rec_purchdetl.activity_code 

				ON ACTION "LOOKUP" infield(acct_code) 
							LET glob_rec_purchdetl.acct_code = show_acct(p_cmpy) 
							DISPLAY BY NAME glob_rec_purchdetl.acct_code 
							NEXT FIELD acct_code 

				ON ACTION "NOTES" --ON KEY (control-n) 
					IF glob_rec_purchdetl.note_code IS NOT NULL THEN 
						# Need TO reconstruct FORMAT as required by sys_noter
						# due TO hashes being stripped once returned.
						LET l_note_code = "###", 
						glob_rec_purchdetl.note_code clipped 
					END IF 
					# Now strip leading hashes as don't want TO store hashes
					# FOR note code
					LET l_note_code = sys_noter(p_cmpy,l_note_code) 
					LET glob_rec_purchdetl.note_code = l_note_code[4,15] 
					DISPLAY BY NAME glob_rec_purchdetl.note_code 

				ON KEY (F9) 
					IF infield(ref_text) 
					AND glob_rec_purchdetl.ref_text IS NOT NULL 
					AND glob_rec_purchdetl.ref_text != " " THEN 
						SELECT * INTO l_rec_product.* FROM product 
						WHERE part_code = glob_rec_purchdetl.ref_text 
						AND cmpy_code = p_cmpy 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9010,"") 
							#9010 Product code does NOT exist;  Try Window.
							NEXT FIELD ref_text 
						END IF 
						CALL sim_warehouse(p_cmpy, 
						l_rec_product.*, 
						glob_rec_purchhead.ware_code) 
						RETURNING l_error_msg 
					END IF 
				ON KEY (F5) 
					IF glob_rec_purchdetl.ref_text IS NOT NULL THEN 
						CALL pinvwind(p_cmpy,glob_rec_purchdetl.ref_text) 
					END IF 
				ON KEY (F8) 
					CALL vinq_vend(p_cmpy,glob_rec_purchhead.vend_code) 
				BEFORE FIELD tran_date 
					LET l_save_date = glob_rec_poaudit.tran_date 
				AFTER FIELD tran_date 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						LET glob_rec_poaudit.tran_date = today 
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.tran_date != l_save_date THEN 
						CALL db_period_what_period(p_cmpy, glob_rec_poaudit.tran_date) 
						RETURNING glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						DISPLAY glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num 
						TO year_num, 
						period_num 

					END IF 
				BEFORE FIELD year_num 
					LET l_save_year_num = glob_rec_poaudit.year_num 
				AFTER FIELD year_num 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD year_num 
					END IF 
				BEFORE FIELD period_num 
					LET l_save_period_num = glob_rec_poaudit.period_num 
				AFTER FIELD period_num 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting period IS closed OR NOT SET up.
						NEXT FIELD period_num 
					END IF 
					IF l_opt_enabled 
					AND glob_rec_purchdetl.acct_code IS NOT NULL 
					AND (l_save_year_num != glob_rec_poaudit.year_num 
					OR l_save_period_num != glob_rec_poaudit.period_num) THEN 
						LET l_msgresp = kandoomsg("U",1533,"") 
						#1533 Checking available funds;  Please wait.
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						l_temp_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"N") 
						RETURNING l_valid_tran, l_available_amt 
						DISPLAY BY NAME l_available_amt 

						LET l_msgresp = kandoomsg("R",1017,"") 
						#1017 Enter line details; F5 Product Inquiry; CTRL+N Notes;
					END IF 
				AFTER FIELD res_code 
					IF l_save_curr_code != glob_rec_jmresource.res_code 
					OR l_save_curr_code IS NULL 
					OR glob_rec_jmresource.res_code IS NULL THEN 
						IF modu_min_mod_qty > 0 THEN 
							LET l_msgresp = kandoomsg("P",9525,"") 
							#9525 Cannot change resource on a receipted ...
							LET glob_rec_jmresource.res_code = l_save_curr_code 
							NEXT FIELD res_code 
						END IF 
						LET l_new_line = TRUE 
					END IF 
					SELECT * INTO glob_rec_jmresource.* FROM jmresource 
					WHERE cmpy_code = p_cmpy 
					AND res_code = glob_rec_jmresource.res_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try window"
						NEXT FIELD res_code 
					END IF 

					IF l_save_curr_code != glob_rec_jmresource.res_code THEN 
						LET glob_rec_purchdetl.desc2_text = glob_rec_jmresource.desc_text 
					END IF 
					LET glob_rec_purchdetl.acct_code = glob_rec_jmresource.exp_acct_code 
					CALL build_mask(p_cmpy, glob_rec_purchdetl.acct_code, 
					l_rec_job.wip_acct_code) 
					RETURNING glob_rec_purchdetl.acct_code 
					SELECT desc_text INTO l_tp_desc_text FROM coa 
					WHERE cmpy_code = p_cmpy 
					AND acct_code = glob_rec_purchdetl.acct_code 
					IF status = notfound THEN 
						LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
					END IF 
					IF NOT l_new_line THEN 
						LET glob_rec_jmresource.unit_cost_amt = glob_rec_poaudit.unit_cost_amt 
						LET glob_rec_jmresource.unit_bill_amt = glob_rec_purchdetl.charge_amt 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.desc2_text, 
					glob_rec_poaudit.order_qty, 
					glob_rec_jmresource.unit_code, 

					glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					IF l_new_line THEN 
						CALL check_funds(p_cmpy, 
						glob_rec_purchdetl.acct_code, 
						l_temp_amt, 
						glob_rec_purchdetl.line_num, 
						glob_rec_poaudit.year_num, 
						glob_rec_poaudit.period_num, 
						"R", 
						glob_rec_purchdetl.order_num, 
						"Y") 
						RETURNING l_valid_tran, l_available_amt 
					END IF 
					LET l_msgresp = kandoomsg("R",1017,"") 
					#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; ...
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						NEXT FIELD res_code 
					END IF 

				AFTER FIELD ref_text 
					IF l_save_ref_code != glob_rec_purchdetl.ref_text THEN 
						IF modu_min_mod_qty > 0 THEN 
							LET l_msgresp = kandoomsg("P",9524,"") 
							#9524 "Cannot change product FOR a partially..."
							LET glob_rec_purchdetl.ref_text = l_save_ref_code 
							NEXT FIELD ref_text 
						END IF 
						IF modu_ship_part_code IS NOT NULL AND 
						glob_rec_purchdetl.ref_text != modu_ship_part_code THEN 
							LET l_msgresp = kandoomsg("R",9018,"") 
							#9018 "Product IS on a shipment..."
							LET glob_rec_purchdetl.ref_text = l_save_ref_code 
							NEXT FIELD ref_text 
						END IF 
						LET l_new_line = TRUE 
					END IF 
					IF l_new_line THEN 
						SELECT * INTO l_rec_product.* FROM product 
						WHERE product.part_code = glob_rec_purchdetl.ref_text 
						AND product.cmpy_code = p_cmpy 
						IF l_rec_product.super_part_code IS NOT NULL THEN 
							LET l_idx = 0 
							WHILE l_rec_product.super_part_code IS NOT NULL 
								LET l_idx = l_idx + 1 
								IF l_idx > 20 THEN 
									LET l_msgresp = kandoomsg("E",9183,"") 
									#9183 Session limit exceeded during replacement ...
									LET glob_rec_purchdetl.ref_text = NULL 
								END IF 
								IF NOT valid_part(p_cmpy,l_rec_product.super_part_code, 
								glob_rec_purchhead.ware_code, 
								1,2,0,"","","") THEN 
									NEXT FIELD ref_text 
									LET glob_rec_purchdetl.ref_text = NULL 
								END IF 
								SELECT * INTO l_rec_product.* FROM product 
								WHERE cmpy_code = p_cmpy 
								AND part_code = l_rec_product.super_part_code 
							END WHILE 
							LET l_msgresp = kandoomsg("E",7060,l_rec_product.part_code) 
							#7060 Product replaced by superseded product.
							LET glob_rec_purchdetl.ref_text = l_rec_product.part_code 
							DISPLAY BY NAME glob_rec_purchdetl.ref_text 

						ELSE 
							IF NOT valid_part(p_cmpy, 
							glob_rec_purchdetl.ref_text, 
							glob_rec_purchhead.ware_code, 
							1,1,0,"","","") THEN 
								NEXT FIELD ref_text 
							END IF 
						END IF 
						SELECT category.* INTO l_rec_category.* FROM category 
						WHERE cmpy_code = p_cmpy 
						AND cat_code = l_rec_product.cat_code 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("I",9521,"") 
							#9521 WARNING: Product category FOR product does NOT exist.
							NEXT FIELD ref_text 
						END IF 
						DECLARE c_prodquote2 SCROLL CURSOR FOR 
						SELECT * FROM prodquote 
						WHERE cmpy_code = p_cmpy 
						AND part_code = glob_rec_purchdetl.ref_text 
						AND vend_code = glob_rec_purchhead.vend_code 
						AND status_ind = "1" 
						AND expiry_date >= today 
						ORDER BY cost_amt 
						OPEN c_prodquote2 
						FETCH c_prodquote2 INTO l_rec_prodquote.* 
						IF status = notfound THEN 
							SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
							WHERE cmpy_code = p_cmpy 
							AND part_code = glob_rec_purchdetl.ref_text 
							AND ware_code = glob_rec_purchhead.ware_code 
							LET l_pu_cost = l_rec_prodstatus.for_cost_amt 
							* l_rec_product.pur_stk_con_qty 
							* l_rec_product.stk_sel_con_qty 
							LET l_price_curr_code = 
							l_rec_prodstatus.for_curr_code 
						ELSE 
							LET l_pu_cost = l_rec_prodquote.cost_amt 
							* l_rec_product.pur_stk_con_qty 
							* l_rec_product.stk_sel_con_qty 
							LET l_price_curr_code = l_rec_prodquote.curr_code 
						END IF 
						CASE 
							WHEN l_price_curr_code = glob_rec_vendor.currency_code 
								LET glob_rec_purchdetl.list_cost_amt = l_pu_cost 
							WHEN glob_rec_vendor.currency_code = l_base_curr_code 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								l_price_curr_code, 
								"F", 
								glob_rec_purchhead.order_date, 
								"B") 
							WHEN l_price_curr_code = l_base_curr_code 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								glob_rec_vendor.currency_code, 
								"T", 
								glob_rec_purchhead.order_date, 
								"B") 
							OTHERWISE 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(l_pu_cost, 
								p_cmpy, 
								l_price_curr_code, 
								"F", 
								glob_rec_purchhead.order_date, 
								"B") 
								LET glob_rec_purchdetl.list_cost_amt = 
								conv_currency(glob_rec_purchdetl.list_cost_amt, 
								p_cmpy, 
								glob_rec_vendor.currency_code, 
								"T", 
								glob_rec_purchhead.order_date, 
								"B") 
						END CASE 
						CLOSE c_prodquote2 
						LET glob_rec_jmresource.unit_bill_amt = l_rec_prodstatus.list_amt 
						LET glob_rec_purchdetl.uom_code = l_rec_product.pur_uom_code 
						LET l_unit_cost_amt = glob_rec_purchdetl.list_cost_amt 
						LET glob_rec_purchdetl.desc_text = l_rec_product.desc_text 
					END IF 
					IF calc_totals() THEN 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.ref_text, 
					glob_rec_purchdetl.desc_text, 
					glob_rec_purchdetl.desc2_text, 
					glob_rec_purchdetl.list_cost_amt, 
					glob_rec_jmresource.unit_bill_amt 

				AFTER FIELD job_code 
					IF glob_rec_purchdetl.job_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD job_code 
					END IF 
					SELECT * INTO l_rec_job.* FROM job 
					WHERE job.cmpy_code = p_cmpy 
					AND job.job_code = glob_rec_purchdetl.job_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try Window"
						NEXT FIELD job_code 
					ELSE 

						IF l_save_curr_code[1,8] != glob_rec_jmresource.res_code 
						OR l_save_job_code != glob_rec_purchdetl.job_code THEN 
							LET glob_rec_purchdetl.acct_code = glob_rec_jmresource.exp_acct_code 
							CALL build_mask(p_cmpy, glob_rec_purchdetl.acct_code, 
							l_rec_job.wip_acct_code) 
							RETURNING glob_rec_purchdetl.acct_code 
							SELECT desc_text INTO l_tp_desc_text FROM coa 
							WHERE cmpy_code = p_cmpy 
							AND acct_code = glob_rec_purchdetl.acct_code 
							IF status = notfound THEN 
								LET l_tp_desc_text = " *** ACCOUNT NOT ON TABLE ***" 
							END IF 
							LET l_save_job_code = glob_rec_purchdetl.job_code 
						END IF 
						DISPLAY BY NAME l_rec_job.title_text, 
						glob_rec_purchdetl.acct_code, 
						l_tp_desc_text 

					END IF 
				AFTER FIELD var_num 
					IF glob_rec_purchdetl.var_num IS NULL THEN 
						LET glob_rec_purchdetl.var_num = 0 
						DISPLAY BY NAME glob_rec_purchdetl.var_num 

					END IF 
					SELECT title_text INTO l_rec_jobvars.title_text FROM jobvars 
					WHERE jobvars.cmpy_code = p_cmpy 
					AND jobvars.job_code = glob_rec_purchdetl.job_code 
					AND jobvars.var_code = glob_rec_purchdetl.var_num 
					IF status = notfound 
					AND glob_rec_purchdetl.var_num != 0 THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 "Record NOT found - Try Window"
						NEXT FIELD job_code 
					ELSE 
						DISPLAY l_rec_jobvars.title_text 
						TO jobvars.title_text 

					END IF 
				AFTER FIELD activity_code 
					IF glob_rec_purchdetl.activity_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD activity_code 
					END IF 
					SELECT * INTO l_rec_activity.* FROM activity 
					WHERE activity.cmpy_code = p_cmpy 
					AND activity.job_code = glob_rec_purchdetl.job_code 
					AND activity.var_code = glob_rec_purchdetl.var_num 
					AND activity.activity_code = glob_rec_purchdetl.activity_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("J",9512,"") 
						#9512 "Activity NOT found FOR this Job & Variation"
						NEXT FIELD job_code 
					END IF 
					IF l_rec_activity.finish_flag = "Y" THEN 
						LET l_msgresp = kandoomsg("J",9513,"") 
						#9513 "This Activity IS finished - No Costs..."
						NEXT FIELD job_code 
					END IF 
					DISPLAY l_rec_activity.title_text 
					TO activity.title_text 

				AFTER FIELD order_qty 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					LET glob_rec_jobledger.trans_amt = glob_rec_poaudit.order_qty * 
					l_unit_cost_amt 
					LET glob_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty * 
					glob_rec_jmresource.unit_bill_amt 
					DISPLAY BY NAME glob_rec_poaudit.order_qty, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 

					IF calc_totals() THEN 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				AFTER FIELD list_cost_amt 
					IF NOT valid_totals() THEN 
						NEXT FIELD list_cost_amt 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				AFTER FIELD disc_per 
					IF NOT valid_totals() THEN 
						NEXT FIELD disc_per 
					END IF 
					CALL calc_jm_totals() 
					RETURNING glob_rec_jmresource.unit_cost_amt, 
					glob_rec_jobledger.trans_amt, 
					glob_rec_jobledger.charge_amt 
				BEFORE FIELD unit_bill_amt 
					IF glob_rec_jmresource.bill_ind = "2" THEN 
						EXIT INPUT 
					END IF 
				AFTER FIELD unit_bill_amt 
					IF glob_rec_jmresource.unit_bill_amt IS NULL THEN 
						LET glob_rec_jmresource.unit_bill_amt = 0 
					END IF 
					LET glob_rec_jobledger.charge_amt = glob_rec_poaudit.order_qty * 
					glob_rec_jmresource.unit_bill_amt 
					DISPLAY BY NAME glob_rec_jobledger.charge_amt 

				AFTER INPUT 
					IF int_flag OR quit_flag THEN 
						EXIT INPUT 
					END IF 
					IF glob_rec_poaudit.tran_date IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD tran_date 
					END IF 
					IF glob_rec_poaudit.year_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					IF glob_rec_poaudit.period_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD period_num 
					END IF 
					SELECT unique 1 FROM period 
					WHERE cmpy_code = p_cmpy 
					AND year_num = glob_rec_poaudit.year_num 
					AND period_num = glob_rec_poaudit.period_num 
					AND pu_flag = "Y" 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("P",9024,"") 
						#9024 Accounting year & period NOT SET up.
						NEXT FIELD year_num 
					END IF 
					IF glob_rec_jmresource.res_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD res_code 
					END IF 
					IF glob_rec_purchdetl.ref_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered.
						NEXT FIELD ref_text 
					END IF 
					IF valid_part(p_cmpy,glob_rec_purchdetl.ref_text,"", 
					TRUE,3,0,"","","") THEN 
					ELSE 
						NEXT FIELD ref_text 
					END IF 
					IF glob_rec_purchdetl.job_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD job_code 
					END IF 
					IF glob_rec_purchdetl.var_num IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 "Value must be entered"
						NEXT FIELD var_num 
					END IF 
					IF glob_rec_purchdetl.activity_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9105 "Value must be entered"
						NEXT FIELD activity_code 
					END IF 
					SELECT title_text INTO l_rec_jobvars.title_text FROM jobvars 
					WHERE jobvars.cmpy_code = p_cmpy 
					AND jobvars.job_code = glob_rec_purchdetl.job_code 
					AND jobvars.var_code = glob_rec_purchdetl.var_num 
					IF status = notfound 
					AND glob_rec_purchdetl.var_num != 0 THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD NOT found;  Try Window.
						NEXT FIELD job_code 
					END IF 
					SELECT * INTO l_rec_activity.* FROM activity 
					WHERE activity.cmpy_code = p_cmpy 
					AND activity.job_code = glob_rec_purchdetl.job_code 
					AND activity.var_code = glob_rec_purchdetl.var_num 
					AND activity.activity_code = glob_rec_purchdetl.activity_code 
					IF status = notfound THEN 
						LET l_msgresp = kandoomsg("J",9512,"") 
						#9512 This activity NOT found FOR this job/variation.
						NEXT FIELD job_code 
					END IF 
					IF NOT valid_totals() THEN 
						NEXT FIELD order_qty 
					END IF 
					IF modu_ship_inv_qty > 0 AND 
					(glob_rec_purchdetl.list_cost_amt != modu_save_list_cost OR 
					glob_rec_purchdetl.disc_per != modu_save_disc_per OR 
					glob_rec_poaudit.unit_tax_amt != l_rec_cu_poaudit.unit_tax_amt) THEN 
						LET l_msgresp = kandoomsg("R",6000,"") 
						#6000 WARNING: ...Shipment price has NOT been changed
					END IF 
					CALL verify_acct_code(p_cmpy,glob_rec_purchdetl.acct_code, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num) 
					RETURNING l_rec_coa.* 
					LET l_tp_desc_text = l_rec_coa.desc_text 
					LET glob_rec_purchdetl.acct_code = l_rec_coa.acct_code 
					IF glob_rec_purchdetl.acct_code IS NULL THEN 
						LET glob_rec_purchdetl.acct_code = l_save_acct_code 
						LET l_tp_desc_text = l_save_desc_text 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD acct_code 
					END IF 
					DISPLAY BY NAME glob_rec_purchdetl.acct_code, 
					l_tp_desc_text 

					LET l_temp_amt = glob_rec_purchdetl.list_cost_amt 
					* glob_rec_poaudit.order_qty 
					CALL check_funds(p_cmpy, 
					glob_rec_purchdetl.acct_code, 
					l_temp_amt, 
					glob_rec_purchdetl.line_num, 
					glob_rec_poaudit.year_num, 
					glob_rec_poaudit.period_num, 
					"R", 
					glob_rec_purchdetl.order_num, 
					"Y") 
					RETURNING l_valid_tran, l_available_amt 
					LET l_msgresp = kandoomsg("R",1017,"") 
					#1017 Enter line details; F5 Product Inquiry; Ctrl-N Note; ...
					IF l_opt_enabled THEN 
						DISPLAY BY NAME l_available_amt 

					END IF 
					IF NOT l_valid_tran THEN 
						NEXT FIELD order_qty 
					END IF 

			END INPUT 
			LET glob_rec_purchdetl.res_code = glob_rec_jmresource.res_code 
			LET glob_rec_purchdetl.charge_amt = glob_rec_jmresource.unit_bill_amt 
			LET glob_rec_poaudit.ext_cost_amt = glob_rec_jobledger.trans_amt 
			LET glob_rec_poaudit.line_total_amt = glob_rec_jobledger.trans_amt 
			LET glob_rec_poaudit.unit_cost_amt = glob_rec_jmresource.unit_cost_amt 
			LET glob_rec_poaudit.unit_tax_amt = 0 
			LET glob_rec_poaudit.ext_tax_amt = 0 
			LET glob_rec_poaudit.desc_text = glob_rec_purchdetl.desc_text 
			CLOSE WINDOW j177 
	END CASE 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 
	RETURN TRUE 
END FUNCTION 


############################################################
# FUNCTION valid_totals()
#
#  This FUNCTION performs the common validation tests on ORDER
#  quantity, list price, discount AND tax AND displays the extended
#  cost VALUES via calc_totals.
############################################################
FUNCTION valid_totals() 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF glob_rec_poaudit.order_qty IS NULL THEN 
		LET glob_rec_poaudit.order_qty = modu_st_poaudit.order_qty 
		LET l_msgresp = kandoomsg("U",9102,"") 
		#9102 Value must be entered.
		RETURN FALSE 
	END IF 
	IF glob_rec_poaudit.order_qty <= 0 THEN 
		LET glob_rec_poaudit.order_qty = modu_st_poaudit.order_qty 
		LET l_msgresp = kandoomsg("U",9927,"0") 
		#9927 Value must be greater than 0.
		RETURN FALSE 
	END IF 
	IF modu_min_mod_qty > 0 AND glob_rec_poaudit.order_qty < modu_min_mod_qty THEN 
		LET l_msgresp = kandoomsg("P",9526,"") 
		#9526 "Order line quantity cannot be less than voucher OR receipted qty"
		LET glob_rec_poaudit.order_qty = modu_st_poaudit.order_qty 
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.list_cost_amt IS NULL THEN 
		LET glob_rec_purchdetl.list_cost_amt = modu_save_list_cost 
		LET l_msgresp = kandoomsg("U",9102,"") 
		#9102 Value must be entered.
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.list_cost_amt < 0 THEN 
		LET glob_rec_purchdetl.list_cost_amt = modu_save_list_cost 
		LET l_msgresp = kandoomsg("U",9907,"0") 
		#9907 Value must be greater than OR equal TO 0.
		RETURN FALSE 
	END IF 
	IF modu_ship_rec_qty > 0 AND 
	glob_rec_purchdetl.list_cost_amt != modu_save_list_cost THEN 
		LET glob_rec_purchdetl.list_cost_amt = modu_save_list_cost 
		LET l_msgresp = kandoomsg("R",9017,"") 
		#9017 Shipment receipts exist; cannot alter price.
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.list_cost_amt != modu_save_list_cost 
	AND glob_rec_poaudit.voucher_qty > 0 THEN 
		LET glob_rec_purchdetl.list_cost_amt = modu_save_list_cost 
		LET l_msgresp = kandoomsg("P",9527,"") 
		#9527 "Cannot change costs AFTER a voucher has been issued"
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.disc_per IS NULL THEN 
		LET glob_rec_purchdetl.disc_per = modu_save_disc_per 
		LET l_msgresp = kandoomsg("U",9102,"") 
		#9102 Value must be entered.
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.disc_per < 0 THEN 
		LET glob_rec_purchdetl.disc_per = modu_save_disc_per 
		LET l_msgresp = kandoomsg("U",9907,"0") 
		#9907 Value must NOT be less than 0.
		RETURN FALSE 
	END IF 
	IF modu_ship_rec_qty > 0 AND 
	glob_rec_purchdetl.disc_per != modu_save_disc_per THEN 
		LET glob_rec_purchdetl.disc_per = modu_save_disc_per 
		LET l_msgresp = kandoomsg("R",9017,"") 
		#9017 Shipment receipts exist; cannot alter price.
		RETURN FALSE 
	END IF 
	IF glob_rec_purchdetl.disc_per != modu_save_disc_per 
	AND glob_rec_poaudit.voucher_qty > 0 THEN 
		LET glob_rec_purchdetl.disc_per = modu_save_disc_per 
		LET l_msgresp = kandoomsg("P",9527,"") 
		#9527 "Cannot change costs AFTER a voucher has been issued"
		RETURN FALSE 
	END IF 
	IF glob_rec_poaudit.unit_tax_amt IS NULL THEN 
		LET glob_rec_poaudit.unit_tax_amt = modu_st_poaudit.unit_tax_amt 
		LET l_msgresp = kandoomsg("U",9102,"") 
		#9102 Value must be entered.
		RETURN FALSE 
	END IF 
	IF glob_rec_poaudit.unit_tax_amt < 0 THEN 
		LET glob_rec_poaudit.unit_tax_amt = modu_st_poaudit.unit_tax_amt 
		LET l_msgresp = kandoomsg("U",9907,"0") 
		#9907 Value must NOT be less than 0.
		RETURN FALSE 
	END IF 
	IF modu_ship_rec_qty > 0 AND 
	glob_rec_poaudit.unit_tax_amt != modu_st_poaudit.unit_tax_amt THEN 
		LET glob_rec_poaudit.unit_tax_amt = modu_st_poaudit.unit_tax_amt 
		LET l_msgresp = kandoomsg("R",9017,"") 
		#9017 Shipment receipts exist; cannot alter price.
		RETURN FALSE 
	END IF 
	IF glob_rec_poaudit.unit_tax_amt != modu_st_poaudit.unit_tax_amt 
	AND glob_rec_poaudit.voucher_qty > 0 THEN 
		LET glob_rec_poaudit.unit_tax_amt = modu_st_poaudit.unit_tax_amt 
		LET l_msgresp = kandoomsg("P",9527,"") 
		#9527 "Cannot change costs AFTER a voucher has been issued"
		RETURN FALSE 
	END IF 

	LET glob_rec_poaudit.ext_tax_amt = glob_rec_poaudit.order_qty 
	* glob_rec_poaudit.unit_tax_amt 
	LET glob_rec_poaudit.ext_cost_amt = glob_rec_poaudit.order_qty 
	* glob_rec_poaudit.unit_cost_amt 
	LET glob_rec_poaudit.line_total_amt = glob_rec_poaudit.order_qty 
	* ( glob_rec_poaudit.unit_cost_amt 
	+ glob_rec_poaudit.unit_tax_amt) 
	IF glob_rec_purchdetl.type_ind != "J" AND 
	glob_rec_poaudit.line_total_amt > 99999999.99 THEN 
		LET l_msgresp = kandoomsg("R",9511,"") 
		#9511 "Purchase Order Value too large - Split Quantity"
		RETURN FALSE 
	END IF 
	IF calc_totals() THEN 
		RETURN TRUE 
	ELSE 
		RETURN FALSE 
	END IF 
END FUNCTION 


