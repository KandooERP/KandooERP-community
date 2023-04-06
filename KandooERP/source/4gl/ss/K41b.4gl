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

	Source code beautified by beautify.pl on 2019-12-31 14:28:29	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 


FUNCTION lineitem() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	pa_creditdetl ARRAY [100] OF RECORD 
		part_code LIKE creditdetl.part_code, 
		ship_qty LIKE creditdetl.ship_qty, 
		line_text LIKE creditdetl.line_text, 
		unit_sales_amt LIKE creditdetl.unit_sales_amt, 
		line_total_amt LIKE creditdetl.line_total_amt 
	END RECORD, 
	pr_maingrp RECORD LIKE maingrp.*, 
	pr_image_ind, scrn1, scrn, j,acount SMALLINT, 
	pr_subdetl RECORD LIKE subdetl.*, 
	pr_temp_text CHAR(60), 
	pr_save_ship_qty LIKE creditdetl.ship_qty 

	OPTIONS DELETE KEY f36 
	INITIALIZE pr_creditdetl.* TO NULL 
	LET ans = "Y" 
	LET pr_credithead.cust_code = pr_customer.cust_code 
	OPEN WINDOW A131 at 2,3 WITH FORM "K156" 
	attribute(border) 
	DISPLAY BY NAME pr_customer.currency_code 
	attribute(green) 
	IF arr_size = 0 THEN 
		DECLARE c_credithead CURSOR FOR 
		SELECT creditdetl.* 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cred_num = pr_credithead.cred_num 
		AND cust_code = pr_credithead.cust_code 
		LET idx = 0 
		FOREACH c_credithead INTO pr_creditdetl.* 
			LET idx = idx + 1 
			LET pa_creditdetl[idx].part_code = pr_creditdetl.part_code 
			LET pa_creditdetl[idx].ship_qty = pr_creditdetl.ship_qty 
			LET pa_creditdetl[idx].line_text = pr_creditdetl.line_text 
			LET pa_creditdetl[idx].unit_sales_amt = 
			pr_creditdetl.unit_sales_amt 
			LET pa_creditdetl[idx].line_total_amt = 
			pr_creditdetl.line_total_amt 
			LET st_creditdetl[idx].* = pr_creditdetl.* 
			IF idx > 100 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
	ELSE 
	FOR idx = 1 TO arr_size 
		LET pa_creditdetl[idx].part_code = st_creditdetl[idx].part_code 
		LET pa_creditdetl[idx].ship_qty = st_creditdetl[idx].ship_qty 
		LET pa_creditdetl[idx].line_text = st_creditdetl[idx].line_text 
		LET pa_creditdetl[idx].unit_sales_amt = 
		st_creditdetl[idx].unit_sales_amt 
		LET pa_creditdetl[idx].line_total_amt = 
		st_creditdetl[idx].line_total_amt 
	END FOR 
END IF 
DISPLAY BY NAME pr_credithead.cust_code, 
pr_customer.name_text, 
pr_credithead.goods_amt, 
pr_credithead.tax_amt, 
pr_credithead.total_amt, 
pr_warehouse.ware_code, 
pr_customer.inv_level_ind, 
pr_credithead.tax_code, 
pr_tax.desc_text, 
pr_customer.cred_bal_amt 

DISPLAY func_type TO func 
attribute(green) 
LET pr_image_ind = true 
WHILE pr_image_ind 
	LET pr_image_ind = false 
	CALL set_count(idx) 
	IF idx = 0 THEN 
		LET msgresp = kandoomsg("A",1100,"") 
		# " ESC TO Complete Credit Note - CTRL-C Customer Info",
		#        " - F9 Image Invoice" ATTRIBUTE(yellow)
	ELSE 
	LET msgresp = kandoomsg("A",1002,"") 
	#" ESC TO Complete Credit Note - CTRL-C Customer Info"
END IF 
INPUT ARRAY pa_creditdetl WITHOUT DEFAULTS FROM sr_creditdetl.* 

	ON ACTION "WEB-HELP" -- albo kd-374 
		CALL onlinehelp(getmoduleid(),null) 

	BEFORE ROW 
		LET idx = arr_curr() 
		LET scrn = scr_line() 
		IF f_type = "J" THEN {edit} 
			LET pr_save_ship_qty = pa_creditdetl[idx].ship_qty 
		ELSE 
		LET pr_save_ship_qty = 0 
	END IF 
	ON KEY (control-b) 
		IF infield(part_code) THEN 
			LET pr_temp_text = "type_code = '",pr_subhead.sub_type_code,"'" 
			LET pa_creditdetl[idx].part_code = show_subproduct(glob_rec_kandoouser.cmpy_code, 
			pr_temp_text) 
			NEXT FIELD part_code 
		END IF 

	ON KEY (F5) --customer details / customer invoice submenu 
		CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) --customer details / customer invoice submenu 
		NEXT FIELD part_code 

	ON KEY (F9) 
		IF arr_count() = 1 # no parts displayed 
		AND f_type = "C" THEN # AND invoice entry FUNCTION 
			IF inv_image() THEN 
				FOR i = 1 TO idx 
					LET pa_creditdetl[i].part_code = 
					st_creditdetl[i].part_code 
					LET px_creditdetl[i].ship_qty = 
					st_creditdetl[i].ship_qty 
					LET st_creditdetl[i].ship_qty = 0 
					LET pa_creditdetl[i].ship_qty = 0 
					LET pa_creditdetl[i].line_text = 
					st_creditdetl[i].line_text 
					LET pa_creditdetl[i].unit_sales_amt = 
					st_creditdetl[i].unit_sales_amt 
					LET pa_creditdetl[i].line_total_amt = 
					st_creditdetl[i].line_total_amt 
				END FOR 
				LET pr_image_ind = true 
				EXIT INPUT 
			END IF 
		END IF 
	BEFORE FIELD part_code 
		DISPLAY pa_creditdetl[idx].* TO sr_creditdetl[scrn].* 
		LET pr_creditdetl.* = st_creditdetl[idx].* 
		LET arr_size = arr_count() 
		CALL total_box() 
	AFTER FIELD part_code 
		IF fgl_lastkey() <> fgl_keyval("up") 
		OR pa_creditdetl[idx].ship_qty IS NOT NULL THEN 
			IF pa_creditdetl[idx].part_code IS NULL THEN 
				LET msgresp = kandoomsg("K",9122,"") 
				#9122  " Must enter a valid subproduct product "
				NEXT FIELD part_code 
			END IF 
			IF st_creditdetl[idx].part_code IS NOT NULL THEN 
				IF pa_creditdetl[idx].part_code IS NULL 
				OR pa_creditdetl[idx].part_code !=pr_creditdetl.part_code THEN 
					LET pa_creditdetl[idx].part_code = pr_creditdetl.part_code 
					NEXT FIELD part_code 
				END IF 
			ELSE 
			LET pr_creditdetl.part_code = pa_creditdetl[idx].part_code 
		END IF 
	END IF 
	BEFORE FIELD ship_qty 
		IF st_creditdetl[idx].part_code IS NULL 
		AND st_creditdetl[idx].ware_code IS NULL 
		AND imaging_used THEN 
			LET pa_creditdetl[idx].part_code = NULL 
			DISPLAY pa_creditdetl[idx].* TO sr_creditdetl[scrn].* 
			NEXT FIELD part_code 
		END IF 
		SELECT * 
		INTO pr_product.* 
		FROM product 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = pa_creditdetl[idx].part_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("A",9119,"") 
			#9119" Product NOT found - Try Window "
			NEXT FIELD part_code 
		END IF 
		SELECT * INTO pr_maingrp.* 
		FROM maingrp 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND maingrp_code = pr_product.maingrp_code 
		LET pr_creditdetl.proddept_code = pr_maingrp.dept_code 
		SELECT * INTO pr_subproduct.* 
		FROM subproduct 
		WHERE subproduct.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND subproduct.part_code = pa_creditdetl[idx].part_code 
		AND subproduct.type_code = pr_subhead.sub_type_code 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("U",9105,"") 
			#error" Subscription NOT found - Try Window "
			#INITIALIZE pa_creditdetl[idx].* TO NULL
			NEXT FIELD part_code 
		END IF 
		SELECT * INTO pr_subcustomer.* 
		FROM subcustomer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		AND ship_code = pr_subhead.ship_code 
		AND part_code = pa_creditdetl[idx].part_code 
		AND sub_type_code = pr_subhead.sub_type_code 
		AND comm_date = pr_subhead.start_date 
		AND end_date = pr_subhead.end_date 
		IF status = notfound THEN 
			LET msgresp = kandoomsg("K",9123,"") 
			#9123 " Customer has NOT subscribed TO this product "
			NEXT FIELD part_code 
		END IF 
		SELECT sum(sub_qty),sum(issue_qty),sum(return_qty) 
		INTO pr_subdetl.sub_qty, 
		pr_subdetl.issue_qty, 
		pr_subdetl.return_qty 
		FROM subdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sub_num = pr_subhead.sub_num 
		AND part_code = pa_creditdetl[idx].part_code 
		IF pr_subdetl.sub_qty IS NULL THEN 
			LET msgresp = kandoomsg("K",9123,"") 
			#9123 " Customer has NOT subscribed TO this product "
			NEXT FIELD part_code 
		END IF 
		IF st_creditdetl[idx].part_code IS NULL THEN ### add inv 
			LET pa_creditdetl[idx].ship_qty = 0 
			LET pa_creditdetl[idx].line_text = pr_product.desc_text 
			#LET pa_creditdetl[idx].unit_sales_amt =
			CALL unit_price(pr_warehouse.ware_code, 
			pr_creditdetl.part_code, 
			pr_customer.inv_level_ind) 
			RETURNING pa_creditdetl[idx].unit_sales_amt, 
			pr_creditdetl.disc_amt 
			LET pa_creditdetl[idx].line_total_amt = 0 
			LET pr_creditdetl.part_code = pa_creditdetl[idx].part_code 
			LET pr_creditdetl.ship_qty = pa_creditdetl[idx].ship_qty 
			LET pr_creditdetl.line_text = pa_creditdetl[idx].line_text 
			LET pr_creditdetl.unit_sales_amt = 
			pa_creditdetl[idx].unit_sales_amt 
			CALL set_creditdetl(idx,pr_creditdetl.*) 
			RETURNING pr_creditdetl.* 
		ELSE #### edit inv 
		LET pa_creditdetl[idx].part_code = pr_creditdetl.part_code 
		LET pa_creditdetl[idx].ship_qty = pr_creditdetl.ship_qty 
		LET pa_creditdetl[idx].line_text = pr_creditdetl.line_text 
		LET pa_creditdetl[idx].unit_sales_amt = 
		pr_creditdetl.unit_sales_amt 
		LET pa_creditdetl[idx].line_total_amt = 
		pr_creditdetl.line_total_amt 
	END IF 
	DISPLAY pa_creditdetl[idx].* 
	TO sr_creditdetl[scrn].* 
	AFTER FIELD ship_qty 
		IF pa_creditdetl[idx].ship_qty IS NULL THEN 
			LET pa_creditdetl[idx].ship_qty = pr_creditdetl.ship_qty 
			NEXT FIELD ship_qty 
		END IF 
		IF pa_creditdetl[idx].ship_qty < 0 THEN 
			LET pa_creditdetl[idx].ship_qty = pr_creditdetl.ship_qty 
			NEXT FIELD ship_qty 
		END IF 
		IF pa_creditdetl[idx].ship_qty > px_creditdetl[idx].ship_qty THEN 
			LET msgresp = kandoomsg("K",9124,"") 
			#9124 "Returning more than invoiced - Quantity adjusted"
			LET pr_creditdetl.ship_qty = px_creditdetl[idx].ship_qty 
			NEXT FIELD ship_qty 
		END IF 
		IF (pa_creditdetl[idx].ship_qty - pr_save_ship_qty) 
		> (pr_subdetl.issue_qty - pr_subdetl.return_qty) THEN 
			LET msgresp = kandoomsg("K",9125,"") 
			#9125 "Returning more than issued "
			NEXT FIELD ship_qty 
		END IF 
		CASE 
			WHEN fgl_lastkey() = fgl_keyval("right") 
				OR fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("accept") 
				LET pr_creditdetl.ship_qty = pa_creditdetl[idx].ship_qty 
				CALL unit_tax(pr_warehouse.ware_code, 
				pr_creditdetl.part_code, 
				pr_creditdetl.unit_sales_amt, 
				pr_creditdetl.tax_code) 
				RETURNING 
				pr_creditdetl.unit_tax_amt, 
				pr_creditdetl.tax_code 
				LET pr_creditdetl.line_total_amt = pr_creditdetl.ship_qty * 
				(pr_creditdetl.unit_sales_amt + pr_creditdetl.unit_tax_amt) 
				LET pa_creditdetl[idx].line_total_amt = 
				pr_creditdetl.line_total_amt 
				LET pr_creditdetl.seq_num = 
				stat_res(glob_rec_kandoouser.cmpy_code,st_creditdetl[idx].ware_code, 
				st_creditdetl[idx].part_code, 
				st_creditdetl[idx].ship_qty,"OUT") 
				LET pr_creditdetl.seq_num = 
				stat_res(glob_rec_kandoouser.cmpy_code,pr_warehouse.ware_code, 
				pr_creditdetl.part_code, 
				pr_creditdetl.ship_qty,TRAN_TYPE_INVOICE_IN) 
				DISPLAY pa_creditdetl[idx].* TO 
				sr_creditdetl[scrn].* 
				CALL set_creditdetl(idx,pr_creditdetl.*) 
				RETURNING pr_creditdetl.* 
				CALL total_box() 
				NEXT FIELD unit_sales_amt 
			WHEN fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") 
				NEXT FIELD previous 
			OTHERWISE 
				NEXT FIELD ship_qty 
		END CASE 
	ON KEY (F2) 
		LET pr_creditdetl.seq_num = 
		stat_res(glob_rec_kandoouser.cmpy_code,st_creditdetl[idx].ware_code, 
		st_creditdetl[idx].part_code, 
		st_creditdetl[idx].ship_qty, "OUT") 
		LET acount = arr_count() 
		LET pr_creditdetl.* = st_creditdetl[idx+1].* 
		FOR j = idx TO (acount - 1) 
			LET st_creditdetl[j].* = st_creditdetl[j+1].* 
			LET pa_creditdetl[j].* = pa_creditdetl[j+1].* 
			LET px_creditdetl[j].* = px_creditdetl[j+1].* 
		END FOR 
		INITIALIZE st_creditdetl[acount].* TO NULL 
		INITIALIZE pa_creditdetl[acount].* TO NULL 
		INITIALIZE px_creditdetl[acount].* TO NULL 
		CALL set_count(acount - 1) 
		LET scrn1 = scrn 
		FOR i = idx TO idx + (7 - scrn) 
			DISPLAY pa_creditdetl[i].* 
			TO sr_creditdetl[scrn1].* 
			LET scrn1 = scrn1 + 1 
		END FOR 
		CALL total_box() 
	AFTER FIELD unit_sales_amt 
		IF pa_creditdetl[idx].unit_sales_amt IS NULL THEN 
			LET pa_creditdetl[idx].unit_sales_amt = 
			pr_creditdetl.unit_sales_amt 
			NEXT FIELD unit_sales_amt 
		END IF 
		IF pa_creditdetl[idx].unit_sales_amt < 0 THEN 
			LET pa_creditdetl[idx].unit_sales_amt = 
			pr_creditdetl.unit_sales_amt 
			NEXT FIELD unit_sales_amt 
		END IF 
		CASE 
			WHEN fgl_lastkey() = fgl_keyval("right") 
				OR fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("accept") 
				LET pr_creditdetl.unit_sales_amt = 
				pa_creditdetl[idx].unit_sales_amt 
				CALL unit_tax(pr_warehouse.ware_code, 
				pr_creditdetl.part_code, 
				pr_creditdetl.unit_sales_amt, 
				pr_creditdetl.tax_code) 
				RETURNING 
				pr_creditdetl.unit_tax_amt, 
				pr_creditdetl.tax_code 
				LET pr_creditdetl.line_total_amt = pr_creditdetl.ship_qty * 
				(pr_creditdetl.unit_sales_amt + pr_creditdetl.unit_tax_amt) 
				LET pa_creditdetl[idx].line_total_amt = 
				pr_creditdetl.line_total_amt 
				DISPLAY pa_creditdetl[idx].* TO 
				sr_creditdetl[scrn].* 
				CALL set_creditdetl(idx,pr_creditdetl.*) 
				RETURNING pr_creditdetl.* 
				CALL total_box() 
				NEXT FIELD NEXT 
			WHEN fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") 
				NEXT FIELD ship_qty 
			OTHERWISE 
				NEXT FIELD unit_sales_amt 
		END CASE 
	BEFORE INSERT 
		LET acount = arr_count() 
		IF acount != 100 THEN 
			FOR j = acount TO idx step -1 
				LET st_creditdetl[j+1].* = st_creditdetl[j].* 
				LET px_creditdetl[j+1].* = px_creditdetl[j].* 
			END FOR 
			INITIALIZE st_creditdetl[idx].* TO NULL 
			INITIALIZE px_creditdetl[idx].* TO NULL 
		END IF 
		INITIALIZE pr_creditdetl.* TO NULL 
	AFTER INPUT 
		LET arr_size = arr_count() 
		IF arr_size > 0 THEN 
			WHILE (pa_creditdetl[arr_size].part_code IS NULL 
				AND pa_creditdetl[arr_size].line_text IS NULL 
				AND (pa_creditdetl[arr_size].line_total_amt = 0 OR 
				pa_creditdetl[arr_size].line_total_amt IS null)) 
				LET arr_size = arr_size - 1 
				IF arr_size = 0 THEN 
					EXIT WHILE 
				END IF 
			END WHILE 
		END IF 
		IF arr_size = 0 AND not(int_flag OR quit_flag) THEN 
			LET msgresp = kandoomsg("A",9113,"") 
			#9113" Credit must have lines TO continue"
			LET int_flag = true 
		END IF 
	ON KEY (control-w) 
		CALL kandoohelp("") 
END INPUT 
END WHILE 
IF int_flag OR quit_flag THEN 
OPEN WINDOW w1 at 10,4 WITH 1 ROWS, 70 COLUMNS 
attribute(border,reverse) 
LET msgresp = kandoomsg("A",8011,"") 
#8011 " Do you wish TO hold line information (y/n) "
LET int_flag = false 
LET quit_flag = false 
CLOSE WINDOW w1 
LET ans = msgresp 
IF ans = "Y" THEN 
	LET ans = "C" 
ELSE 
LET imaging_used = false 
LET ans = "N" 
END IF 
END IF 
CLOSE WINDOW A131 
END FUNCTION 


FUNCTION set_creditdetl(idx,pr_creditdetl) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	idx SMALLINT, 
	pr_creditdetl RECORD LIKE creditdetl.*, 
	pr_product RECORD LIKE product.* 

	SELECT * 
	INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_creditdetl.part_code 
	SELECT * 
	INTO pr_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_warehouse.ware_code 
	AND part_code = pr_creditdetl.part_code 
	LET pr_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_creditdetl.cust_code = pr_credithead.cust_code 
	LET pr_creditdetl.ware_code = pr_warehouse.ware_code 
	IF pr_creditdetl.cat_code IS NULL THEN 
		LET pr_creditdetl.cat_code = pr_product.cat_code 
	END IF 
	IF pr_creditdetl.part_code IS NOT NULL 
	AND pr_creditdetl.uom_code IS NULL THEN 
		LET pr_creditdetl.uom_code = pr_product.sell_uom_code 
	END IF 
	IF pr_creditdetl.part_code IS NOT NULL THEN 
		LET pr_creditdetl.unit_cost_amt = 
		conv_currency(pr_prodstatus.wgted_cost_amt,glob_rec_kandoouser.cmpy_code, 
		pr_customer.currency_code, "T", 
		pr_credithead.cred_date,"L") 
	ELSE 
	LET pr_creditdetl.unit_cost_amt = 0 
END IF 
IF pr_creditdetl.ship_qty IS NULL THEN 
	LET pr_creditdetl.ship_qty = 0 
END IF 
IF pr_creditdetl.unit_tax_amt IS NULL THEN 
	LET pr_creditdetl.unit_tax_amt = 0 
END IF 
IF pr_creditdetl.unit_sales_amt IS NULL THEN 
	LET pr_creditdetl.unit_sales_amt = 0 
END IF 
IF pr_creditdetl.unit_cost_amt IS NULL THEN 
	LET pr_creditdetl.unit_cost_amt = 0 
END IF 
IF pr_creditdetl.disc_amt IS NULL THEN 
	LET pr_creditdetl.disc_amt = 0 
END IF 
IF pr_credithead.tax_amt IS NULL THEN 
	LET pr_credithead.tax_amt = 0 
END IF 
LET pr_creditdetl.ext_sales_amt = pr_creditdetl.unit_sales_amt 
* pr_creditdetl.ship_qty 
LET pr_creditdetl.ext_tax_amt = pr_creditdetl.ship_qty 
* pr_creditdetl.unit_tax_amt 
LET pr_creditdetl.ext_cost_amt = pr_creditdetl.unit_cost_amt 
* pr_creditdetl.ship_qty 
IF pr_creditdetl.part_code IS NOT NULL 
AND pr_creditdetl.line_acct_code IS NULL THEN 
	SELECT sale_acct_code 
	INTO pr_creditdetl.line_acct_code 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_creditdetl.cat_code 
END IF 
LET pr_creditdetl.level_code = pr_customer.inv_level_ind 
LET pr_creditdetl.km_qty = 0 
LET pr_creditdetl.price_uom_code = pr_product.sell_uom_code 
LET pr_creditdetl.prodgrp_code = pr_product.prodgrp_code 
LET pr_creditdetl.maingrp_code = pr_product.maingrp_code 
LET st_creditdetl[idx].* = pr_creditdetl.* 
RETURN pr_creditdetl.* 
END FUNCTION 


FUNCTION inv_image() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	where_part, query_text CHAR(600), 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_category RECORD LIKE category.*, 
	pa_invoicehead array[300] OF RECORD 
		inv_num LIKE invoicehead.inv_num, 
		inv_date LIKE invoicehead.inv_date, 
		year_num LIKE invoicehead.year_num, 
		period_num LIKE invoicehead.period_num, 
		purchase_code LIKE invoicehead.purchase_code, 
		ord_num LIKE invoicehead.ord_num 
	END RECORD 

	OPEN WINDOW A634 WITH FORM "A634" 


	LET msgresp=kandoomsg("A",1001,"") 
	CONSTRUCT BY NAME where_part ON invoicehead.inv_num, 
	invoicehead.inv_date, 
	invoicehead.year_num, 
	invoicehead.period_num, 
	invoicehead.purchase_code, 
	invoicehead.ord_num 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW A634 
		RETURN false 
	END IF 
	LET query_text = "SELECT * FROM invoicehead WHERE ", 
	where_part clipped, 
	" AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND cust_code = '",pr_customer.cust_code,"'", 
	" AND ref_num = ",pr_subhead.sub_num," ", 
	" AND inv_ind = '7'" 

	LET idx = 0 
	PREPARE ledger FROM query_text 
	DECLARE c_cust CURSOR FOR ledger 
	FOREACH c_cust INTO pr_invoicehead.* 
		LET idx = idx + 1 
		LET pa_invoicehead[idx].inv_num = pr_invoicehead.inv_num 
		LET pa_invoicehead[idx].inv_date = pr_invoicehead.inv_date 
		LET pa_invoicehead[idx].year_num = pr_invoicehead.year_num 
		LET pa_invoicehead[idx].period_num = pr_invoicehead.period_num 
		LET pa_invoicehead[idx].purchase_code = pr_invoicehead.purchase_code 
		LET pa_invoicehead[idx].ord_num = pr_invoicehead.ord_num 
		IF idx > 290 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (idx) 

	LET msgresp = kandoomsg("A",1047,"") 
	#1047 " ESC TO SELECT

	INPUT ARRAY pa_invoicehead WITHOUT DEFAULTS FROM sr_invoicehead.* 

		ON ACTION "WEB-HELP" -- albo kd-374 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_invoicehead.inv_num = pa_invoicehead[idx].inv_num 
			LET pr_invoicehead.inv_date = pa_invoicehead[idx].inv_date 
			LET pr_invoicehead.year_num = pa_invoicehead[idx].year_num 
			LET pr_invoicehead.period_num = pa_invoicehead[idx].period_num 
			LET pr_invoicehead.purchase_code = pa_invoicehead[idx].purchase_code 
			LET pr_invoicehead.ord_num = pa_invoicehead[idx].ord_num 
			LET id_flag = 0 
			IF idx > arr_count() THEN 
				LET msgresp = kandoomsg("A",9001,"") 
				#9001 "There are no more invoices in the direction you are going"
			END IF 

		BEFORE FIELD inv_date 
			NEXT FIELD inv_num 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW A634 
		RETURN false 
	END IF 
	LET pr_credithead.rma_num = pr_invoicehead.inv_num 
	DECLARE c_inv CURSOR FOR 
	SELECT invoicedetl.* FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_invoicehead.inv_num 
	AND cust_code = pr_customer.cust_code 
	LET idx = 0 
	FOREACH c_inv INTO pr_invoicedetl.* 
		LET idx = idx + 1 
		SELECT * INTO pr_product.* FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = pr_invoicedetl.part_code 
		LET pr_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_creditdetl.part_code = pr_invoicedetl.part_code 
		IF pr_creditdetl.part_code IS NOT NULL THEN 
			SELECT sale_acct_code INTO pr_creditdetl.line_acct_code 
			FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
		END IF 
		LET pr_creditdetl.cust_code = pr_customer.cust_code 
		LET pr_creditdetl.ware_code = pr_warehouse.ware_code 
		LET pr_creditdetl.ship_qty = pr_invoicedetl.ship_qty 
		LET pr_creditdetl.line_text = pr_invoicedetl.line_text 
		LET pr_creditdetl.unit_sales_amt = pr_invoicedetl.unit_sale_amt 
		LET pr_creditdetl.level_code = pr_invoicedetl.level_code 
		LET pr_creditdetl.cat_code = pr_product.cat_code 
		LET pr_creditdetl.line_total_amt = 0 
		LET pr_creditdetl.disc_amt = 0 
		LET pr_credithead.tax_amt = 0 
		LET pr_creditdetl.ext_sales_amt = 0 
		LET pr_creditdetl.ser_ind = "N" 
		LET pr_creditdetl.ext_tax_amt = 0 
		LET pr_creditdetl.ext_cost_amt = 0 
		LET pr_creditdetl.unit_cost_amt = 0 
		LET st_creditdetl[idx].* = pr_creditdetl.* 
	END FOREACH 
	CLOSE WINDOW A634 
	LET imaging_used = true 
	RETURN true 
END FUNCTION 
