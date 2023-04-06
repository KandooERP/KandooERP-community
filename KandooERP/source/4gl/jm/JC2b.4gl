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

	Source code beautified by beautify.pl on 2020-01-02 19:48:21	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JC2b.4gl - FUNCTION lineitem()
# Purpose - JM credit note edit

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC2_GLOBALS.4gl" 

DEFINE 
save_idx CHAR(3) 


FUNCTION lineitem() 
	DEFINE 
	pa_creditdetl ARRAY [300] OF RECORD 
		job_code LIKE creditdetl.job_code, 
		var_code LIKE creditdetl.var_code, 
		activity_code LIKE creditdetl.activity_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD, 
	sv_creditdetl ARRAY [300] OF RECORD 
		job_code LIKE creditdetl.job_code, 
		var_code LIKE creditdetl.var_code, 
		activity_code LIKE creditdetl.activity_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD, 
	cat_codecat RECORD LIKE category.*, 
	which CHAR(3), 
	pr_savedetl RECORD LIKE creditdetl.*, 
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
	pr_prev_goods LIKE creditdetl.line_total_amt, 
	pr_prev_tax LIKE creditdetl.line_total_amt, 
	pr_part_code LIKE purchdetl.ref_text, 
	pr_order_num LIKE purchdetl.order_num 

	OPTIONS DELETE KEY f36 
	INITIALIZE pr_creditdetl.* TO NULL 
	IF pv_corp_cust THEN 
		LET pr_credithead.cust_code = pr_customer.corp_cust_code 
		LET pr_credithead.org_cust_code = pr_customer.cust_code 
	ELSE 
		LET pr_credithead.cust_code = pr_customer.cust_code 
	END IF 
	DISPLAY "" at 2,1 
	DISPLAY "credit num ", pr_credithead.cred_num at 2,1 
	SLEEP 2 
	CALL serial_init(glob_rec_kandoouser.cmpy_code,"C","",pr_credithead.cred_num) 
	OPEN WINDOW wa131 with FORM "J666" -- alch kd-747 
	CALL winDecoration_j("J666") -- alch kd-747 
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
		LET pa_creditdetl[idx].job_code = ps_creditdetl[idx].job_code 
		LET pa_creditdetl[idx].var_code = ps_creditdetl[idx].var_code 
		LET pa_creditdetl[idx].activity_code = ps_creditdetl[idx].activity_code 
		LET pa_creditdetl[idx].ship_qty = ps_creditdetl[idx].ship_qty 
		IF pa_creditdetl[idx].ship_qty = 0 THEN 
			LET pa_creditdetl[idx].ship_qty = NULL 
		END IF 
		LET pa_creditdetl[idx].line_text = ps_creditdetl[idx].line_text 
		LET pa_creditdetl[idx].unit_sales_amt = ps_creditdetl[idx].unit_sales_amt 
		LET pa_creditdetl[idx].line_total_amt = ps_creditdetl[idx].line_total_amt 
		LET sv_creditdetl[idx].* = pa_creditdetl[idx].* 

		SELECT trans_source_num 
		INTO pr_order_num 
		FROM jobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = ps_creditdetl[idx].job_code 
		AND var_code = ps_creditdetl[idx].var_code 
		AND activity_code = ps_creditdetl[idx].activity_code 
		AND seq_num = ps_creditdetl[idx].jobledger_seq_num 
		SELECT unique ref_text 
		INTO pr_part_code 
		FROM purchdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_order_num 
		AND desc_text = ps_creditdetl[idx].line_text 
		IF status = notfound 
		OR pr_kandoooption_sn <> "Y" THEN 
			LET store_extra[idx].part_code = " " 
			LET store_extra[idx].pu = " " 
			LET store_extra[idx].store_qty = 0 
			LET store_extra[idx].serial_flag = " " 
		ELSE 
			LET store_extra[idx].part_code = pr_part_code 
			LET store_extra[idx].pu = "PU" 
			LET store_extra[idx].store_qty = pa_creditdetl[idx].ship_qty 
			SELECT serial_flag 
			INTO store_extra[idx].serial_flag 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
		END IF 

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
	pr_credithead.tax_code, 
	pr_tax.desc_text 


	LET msgresp = kandoomsg("J",1507," ") 
	# MESSAGE "Press ESC TO finish the credit"
	INPUT ARRAY pa_creditdetl WITHOUT DEFAULTS 
	FROM sr_creditdetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC2b","input-pa_creditdetl-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			# SET up ARRAY variables
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET firstime = 1 

		ON KEY (control-c) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) --customer details / customer invoice submenu 

		AFTER FIELD ship_qty 
			IF pr_kandoooption_sn = "Y" 
			AND store_extra[idx].serial_flag = "Y" THEN 
				SELECT count(*) 
				INTO pr_qty_cnt 
				FROM t_serialinfo 
				WHERE part_code = store_extra[idx].part_code 
				LET pr_qty_cnt = serial_input(store_extra[idx].part_code, 
				"",pr_qty_cnt) 
				LET pa_creditdetl[idx].ship_qty = pr_qty_cnt 
			END IF 

		AFTER FIELD unit_sales_amt 
			IF pa_creditdetl[idx].job_code IS NOT NULL 
			AND pa_creditdetl[idx].activity_code IS NOT NULL THEN 
				LET pr_prev_goods = ps_creditdetl[idx].ext_sales_amt 
				LET pr_prev_tax = ps_creditdetl[idx].ext_tax_amt 
				SELECT unique * 
				INTO pr_jobledger.* 
				FROM jobledger 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = ps_creditdetl[idx].job_code 
				AND var_code = ps_creditdetl[idx].var_code 
				AND activity_code = ps_creditdetl[idx].activity_code 
				AND seq_num = ps_creditdetl[idx].jobledger_seq_num 
				AND allocation_ind NOT in ("Q", "N") 
				CALL find_tax(ps_creditdetl[idx].tax_code, 
				pr_jobledger.trans_source_text, 
				" ",arr_size,idx, 
				pa_creditdetl[idx].unit_sales_amt, pa_creditdetl[idx].ship_qty, 
				"S", " ", " ") 
				RETURNING ext_price, unit_tax, ext_tax, line_tot, tmp_tax_code 
				LET px_creditdetl[idx].line_total_amt = ext_price + ext_tax 
				LET px_creditdetl[idx].ext_price = ext_price 
				LET px_creditdetl[idx].ext_tax = ext_tax 

				LET pa_creditdetl[idx].line_total_amt = ext_price + ext_tax 

				LET pr_credithead.goods_amt = pr_credithead.goods_amt 
				- pr_prev_goods 
				+ ext_price 
				LET pr_credithead.tax_amt = pr_credithead.tax_amt 
				- pr_prev_tax 
				+ ext_tax 
				LET pr_credithead.total_amt = pr_credithead.goods_amt 
				+ pr_credithead.tax_amt 
				DISPLAY BY NAME pr_credithead.goods_amt, 
				pr_credithead.tax_amt, 
				pr_credithead.total_amt 

				DISPLAY pa_creditdetl[idx].* TO sr_creditdetl[scrn].* 


				LET ps_creditdetl[idx].ship_qty = pa_creditdetl[idx].ship_qty 
				LET ps_creditdetl[idx].unit_sales_amt 
				= pa_creditdetl[idx].unit_sales_amt 
				LET ps_creditdetl[idx].ext_sales_amt 
				= ext_price 
				LET ps_creditdetl[idx].ext_cost_amt 
				= ps_creditdetl[idx].unit_cost_amt 
				* pa_creditdetl[idx].ship_qty 
				LET ps_creditdetl[idx].unit_tax_amt = unit_tax 
				LET ps_creditdetl[idx].ext_tax_amt = ext_tax 
				LET ps_creditdetl[idx].line_total_amt = ext_price + ext_tax 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("RETURN") THEN 
				IF arr_curr() >= arr_count() 
				OR pa_creditdetl[idx+1].job_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 there are no more rows...
					NEXT FIELD ship_qty 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF pa_creditdetl[idx+7].job_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9001,"") 
					#9001 there are no more rows...
					NEXT FIELD ship_qty 
				END IF 
			END IF 
		AFTER INPUT 
			LET arr_size = arr_count() 
			IF NOT (int_flag 
			OR quit_flag) THEN 
				IF pr_credithead.total_amt > pr_uncredited_amt THEN 
					LET msgresp = kandoomsg("J", 9611, pr_uncredited_amt) 
					#9611 Credit exceeds uncredited invoice amount
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
