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

	Source code beautified by beautify.pl on 2020-01-02 19:48:20	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JC1b.4gl - FUNCTION lineitem()
# Purpose - JM credit entry

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 

DEFINE 
save_idx CHAR(3) 


FUNCTION lineitem(invoice_num) 
	DEFINE 
	invoice_num LIKE invoicedetl.inv_num, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pa_creditdetl ARRAY [300] OF RECORD 
		activity_code LIKE creditdetl.activity_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD, 
	sv_creditdetl ARRAY [300] OF RECORD 
		activity_code LIKE creditdetl.activity_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD, 
	cat_codecat RECORD LIKE category.*, 
	which CHAR(3), 
	pr_savedetl RECORD LIKE creditdetl.*, 
	save_ware LIKE creditdetl.ware_code, 
	scrn1, 
	last_window, 
	scrn, 
	id_flag, 
	j SMALLINT, 
	acount, 
	ins_flag, 
	del_flag, 
	tax_idx SMALLINT, 
	pos, 
	start_idx, 
	x SMALLINT, 
	saved_tot LIKE credithead.total_amt, 
	recalc_tax SMALLINT, 
	tx_idx, 
	tot_lines SMALLINT, 
	tmp_return LIKE creditdetl.unit_tax_amt, 
	tmp_tax_code LIKE credithead.tax_code, 
	pr_ext_tax_amt LIKE creditdetl.ext_tax_amt, 
	ln_num LIKE resbill.line_num, 
	unit_price LIKE creditdetl.unit_sales_amt, 
	ext_price LIKE creditdetl.ext_sales_amt, 
	unit_tax LIKE creditdetl.unit_tax_amt, 
	ext_tax LIKE creditdetl.ext_tax_amt, 
	line_tot LIKE creditdetl.line_total_amt, 
	cost_price LIKE creditdetl.unit_cost_amt 

	OPTIONS DELETE KEY f36 
	INITIALIZE pr_creditdetl.* TO NULL 
	IF pv_corp_cust THEN 
		LET pr_credithead.cust_code = pr_customer.corp_cust_code 
		LET pr_credithead.org_cust_code = pr_customer.cust_code 
	ELSE 
		LET pr_credithead.cust_code = pr_customer.cust_code 
	END IF 


	CALL serial_init(glob_rec_kandoouser.cmpy_code,"","C","") 
	DECLARE c_serialinfo CURSOR FOR 
	SELECT * 
	FROM serialinfo 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ref_num = invoice_num 
	FOREACH c_serialinfo INTO pr_serialinfo.* 
		INSERT INTO t_serialinfo VALUES (pr_serialinfo.*) 
	END FOREACH 
	OPEN WINDOW wa131 with FORM "A131" -- alch kd-747 
	CALL winDecoration_a("A131") -- alch kd-747 
	DISPLAY BY NAME pr_customer.currency_code 
	attribute (green) 
	IF NOT pv_corp_cust 
	AND sav_cust_code IS NOT NULL THEN 
		LET pr_credithead.cust_code = sav_cust_code 
	END IF 
	FOR idx = 1 TO load_idx 
		LET save_idx = idx 
		IF idx > 300 THEN 
			EXIT FOR 
		END IF 
		LET pa_creditdetl[idx].activity_code = ps_creditdetl[idx].activity_code 
		LET pa_creditdetl[idx].ship_qty = ps_creditdetl[idx].ship_qty 
		IF pa_creditdetl[idx].ship_qty = 0 THEN 
			LET pa_creditdetl[idx].ship_qty = NULL 
		END IF 
		LET pa_creditdetl[idx].line_text = ps_creditdetl[idx].line_text 
		LET pa_creditdetl[idx].unit_sales_amt = ps_creditdetl[idx].unit_sales_amt 
		IF pr_arparms.show_tax_flag = "Y" THEN 
			LET pa_creditdetl[idx].line_total_amt = 
			ps_creditdetl[idx].line_total_amt 
		ELSE 
			LET pa_creditdetl[idx].line_total_amt = 
			ps_creditdetl[idx].unit_sales_amt * 
			ps_creditdetl[idx].ship_qty 
		END IF 
		LET st_creditdetl[idx].* = ps_creditdetl[idx].* 
		LET sv_creditdetl[idx].* = pa_creditdetl[idx].* 
	END FOR 
	IF save_idx IS NULL THEN 
		LET save_idx = 0 
	END IF 
	CALL set_count(idx) 
	DISPLAY BY NAME pr_customer.cust_code, 
	pr_customer.name_text, 
	pr_credithead.goods_amt, 
	pr_credithead.tax_amt, 
	pr_credithead.total_amt, 
	pr_creditdetl.ware_code, 
	pr_customer.inv_level_ind, 
	pr_credithead.tax_code, 
	pr_tax.desc_text 


	DISPLAY func_type TO func 
	attribute (green) 
	LET msgresp = kandoomsg("J",1507," ") 
	# MESSAGE "Press ESC TO finish the credit"
	INPUT ARRAY pa_creditdetl WITHOUT DEFAULTS 
	FROM sr_creditdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC1b","input_arr-pa_creditdetl-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			# SET up ARRAY variables
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET firstime = 1 

		ON KEY (control-c) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) --customer details / customer invoice submenu 
			NEXT FIELD part_code 

		BEFORE FIELD ship_qty 
			LET recalc_tax = false 
			IF pr_credithead.bill_issue_ind = "2" OR 
			pr_credithead.bill_issue_ind = "4" THEN {detail} 
				IF get_detail(ps_creditdetl[idx].var_code, 
				ps_creditdetl[idx].activity_code , 
				ps_creditdetl[idx].jobledger_seq_num) THEN 
					LET recalc_tax = true 
				END IF 
			ELSE 
				IF edit_alloc(idx) THEN 
					LET recalc_tax = true 
				END IF 
			END IF 
			IF int_flag 
			OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT FIELD part_code 
			END IF 
			IF recalc_tax 
			AND pr_tax.calc_method_flag != "T" THEN 
				LET recalc_tax = false 
				# calculate tax FOR each tempbill line
				LET pr_credithead.goods_amt = 0 
				LET pr_credithead.tax_amt = 0 


				LET tot_lines = 0 
				SELECT count(*)INTO tot_lines 
				FROM tempbill 
				WHERE trans_invoice_flag = "*" 
				DECLARE tax_curs CURSOR FOR 
				SELECT * 
				FROM tempbill 

				FOREACH tax_curs INTO pr_tempbill.* 
					IF pr_credithead.bill_issue_ind = "1" OR 
					pr_credithead.bill_issue_ind = "3" THEN 
						LET ln_num = pr_tempbill.arr_line_num 
					ELSE 
						LET ln_num = pr_tempbill.line_num 
					END IF 
					LET ps_creditdetl[ln_num].ship_qty = 0 
					LET ps_creditdetl[ln_num].unit_tax_amt = 0 
					LET ps_creditdetl[ln_num].ext_tax_amt = 0 
					LET ps_creditdetl[ln_num].unit_sales_amt = 0 
					LET ps_creditdetl[ln_num].ext_sales_amt = 0 
					LET ps_creditdetl[ln_num].line_total_amt = 0 
					LET ps_creditdetl[ln_num].unit_cost_amt = 0 
					LET ps_creditdetl[ln_num].ext_cost_amt = 0 
				END FOREACH 
				LET tx_idx = 0 
				FOREACH tax_curs INTO pr_tempbill.* 
					IF pr_tempbill.trans_invoice_flag IS NULL THEN 
						CONTINUE FOREACH 
					END IF 
					IF pr_credithead.bill_issue_ind = "1" OR 
					pr_credithead.bill_issue_ind = "3" THEN 
						LET ln_num = pr_tempbill.arr_line_num 
					ELSE 
						LET ln_num = pr_tempbill.line_num 
					END IF 
					LET tx_idx = tx_idx + 1 
					IF pr_tempbill.apply_qty > 0 THEN 
						LET unit_price = pr_tempbill.apply_amt 
						/ pr_tempbill.apply_qty 
						LET cost_price = pr_tempbill.apply_cos_amt 
						/ pr_tempbill.apply_qty 
						IF unit_price IS NULL THEN 
							LET unit_price = 0 
						END IF 
						IF cost_price IS NULL THEN 
							LET cost_price = 0 
						END IF 
					ELSE 
						LET unit_price = 0 
						LET cost_price = 0 
					END IF 

					LET pr_credithead.goods_amt = pr_credithead.goods_amt + 
					pr_tempbill.apply_amt 
					IF pr_tempbill.trans_type_ind != "IS" 
					OR pr_tempbill.trans_type_ind IS NULL THEN 
						CALL find_tax(pr_invoicehead.tax_code, 
						pr_tempbill.trans_source_text , {resource} " ", tot_lines, 
						tx_idx , unit_price, pr_tempbill.apply_qty, "S", "", "") 
						RETURNING ext_price, 
						unit_tax, 
						ext_tax, 
						line_tot, 
						tmp_tax_code 
						IF ext_price IS NULL THEN 
							LET ext_price = 0 
						END IF 
						IF unit_tax IS NULL THEN 
							LET unit_tax = 0 
						END IF 
						IF ext_tax IS NULL THEN 
							LET ext_tax = 0 
						END IF 
						IF line_tot IS NULL THEN 
							LET line_tot = 0 
						END IF 
						LET ps_creditdetl[ln_num].unit_sales_amt = unit_price 
						LET ps_creditdetl[ln_num].ext_sales_amt = ext_price 
						LET ps_creditdetl[ln_num].unit_tax_amt = unit_tax 
						LET ps_creditdetl[ln_num].ext_tax_amt = ext_tax 
						LET ps_creditdetl[ln_num].line_total_amt = line_tot 
						LET ps_creditdetl[ln_num].unit_cost_amt = cost_price 
						LET ps_creditdetl[ln_num].ext_cost_amt = cost_price 
						* pr_tempbill.apply_qty 
						LET ps_creditdetl[ln_num].ship_qty = pr_tempbill.apply_qty 
						LET pr_credithead.tax_amt = pr_credithead.tax_amt 
						+ ps_creditdetl[ln_num].ext_tax_amt 
					ELSE {inventory line} 





						CALL find_tax(pr_invoicehead.tax_code, 
						pr_tempbill.desc_text[1, 15 ], 
						{product code} pr_tempbill.desc_text[16, 18],
						tot_lines 
						, tx_idx, pr_tempbill.apply_amt, 1, "S", "", "") 
						RETURNING ext_price, 
						unit_tax, 
						ext_tax, 
						line_tot, 
						tmp_tax_code 
						IF ext_price IS NULL THEN 
							LET ext_price = 0 
						END IF 
						IF unit_tax IS NULL THEN 
							LET unit_tax = 0 
						END IF 
						IF ext_tax IS NULL THEN 
							LET ext_tax = 0 
						END IF 
						IF line_tot IS NULL THEN 
							LET line_tot = 0 
						END IF 
						LET ps_creditdetl[ln_num].unit_sales_amt = unit_price 
						LET ps_creditdetl[ln_num].ext_sales_amt = ext_price 
						LET ps_creditdetl[ln_num].unit_tax_amt = unit_tax 
						LET ps_creditdetl[ln_num].ext_tax_amt = ext_tax 
						LET ps_creditdetl[ln_num].line_total_amt = line_tot 
						LET ps_creditdetl[ln_num].ship_qty = pr_tempbill.apply_qty 
						LET pr_credithead.tax_amt = pr_credithead.tax_amt 
						+ ps_creditdetl[ ln_num].ext_tax_amt 
						LET ps_creditdetl[ln_num].unit_cost_amt = cost_price 
						LET ps_creditdetl[ln_num].ext_cost_amt = cost_price 
						* pr_tempbill.apply_qty 
					END IF 
				END FOREACH 
				LET pa_creditdetl[idx].line_text = ps_creditdetl[idx].line_text 
				LET pa_creditdetl[idx].ship_qty = ps_creditdetl[idx].ship_qty 
				LET pa_creditdetl[idx].unit_sales_amt = 
				ps_creditdetl[idx].unit_sales_amt 
				IF pr_arparms.show_tax_flag = "Y" THEN 
					LET pa_creditdetl[idx].line_total_amt = 
					ps_creditdetl[idx].line_total_amt 
				ELSE 
					LET pa_creditdetl[idx].line_total_amt = 
					ps_creditdetl[idx].ext_sales_amt 
				END IF 
				DISPLAY pa_creditdetl[idx].* TO sr_creditdetl[scrn].* 

			END IF 
			LET pr_credithead.total_amt = pr_credithead.goods_amt + 
			pr_credithead.tax_amt 
			DISPLAY BY NAME pr_credithead.goods_amt, 
			pr_credithead.tax_amt, 
			pr_credithead.total_amt 

			NEXT FIELD part_code 
		AFTER INPUT 
			LET arr_size = arr_count() 
			IF NOT (int_flag 
			OR quit_flag) THEN 
				IF pr_credithead.total_amt > pr_uncredited_amt THEN 
					LET msgresp = kandoomsg("J", 9611, pr_uncredited_amt) 
					#9611 Credit exceeds uncredited invoice amount
					NEXT FIELD part_code 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	# has interrupt OR quit been hit

	OPTIONS DELETE KEY f36 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW wa131 
		RETURN false 
	ELSE 
		IF pr_credithead.total_amt = 0 THEN 
			IF msgresp = kandoomsg("J", 8009, "") = "N" THEN 
				CLOSE WINDOW wa131 
				RETURN false 
			END IF 
		END IF 
		CLOSE WINDOW wa131 
		RETURN true 
	END IF 
END FUNCTION 
