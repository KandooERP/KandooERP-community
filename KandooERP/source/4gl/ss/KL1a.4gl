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

	Source code beautified by beautify.pl on 2019-12-31 14:28:31	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "K_SS_GLOBALS.4gl" 

GLOBALS "KL1_GLOBALS.4gl" 


FUNCTION update_issue() 
	DEFINE 
	pr_invoicedetl RECORD LIKE invoicedetl.*, 
	ps_invoicedetl RECORD LIKE invoicedetl.*, 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_subcustomer RECORD LIKE subcustomer.*, 
	pr_subaudit RECORD LIKE subaudit.*, 
	pr_substype RECORD LIKE substype.*, 
	pr_term RECORD LIKE term.*, 
	err_message CHAR(60), 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_subproduct RECORD LIKE subproduct.*, 
	pr_inv_qty,pr_float FLOAT, 
	idx SMALLINT 

	IF retry_lock(glob_rec_kandoouser.cmpy_code,0) THEN 
	END IF 
	GOTO bypass 
	LABEL recovery: 
	OUTPUT TO REPORT KL1_rpt_list_excep(err_message,pr_subhead.*) 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		SELECT * INTO pr_customer.* FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_subhead.cust_code 
		SELECT * INTO pr_substype.* FROM substype 
		WHERE type_code = pr_subhead.sub_type_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DECLARE c_label CURSOR FOR 
		SELECT * FROM t_label 
		WHERE sub_num = pr_subhead.sub_num 
		DECLARE c2_subhead CURSOR FOR 
		SELECT * FROM subhead 
		WHERE sub_num = pr_subhead.sub_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		DECLARE c2_subdetl CURSOR FOR 
		SELECT * FROM subdetl 
		WHERE sub_num = pr_label.sub_num 
		AND sub_line_num = pr_label.sub_line_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		DECLARE c2_subschedule CURSOR FOR 
		SELECT * FROM subschedule 
		WHERE sub_num = pr_label.sub_num 
		AND sub_line_num = pr_label.sub_line_num 
		AND issue_num = pr_label.issue_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		INITIALIZE ps_invoicedetl.* TO NULL 
		IF pr_customer.corp_cust_code IS NOT NULL 
		AND pr_customer.corp_cust_ind = "1" THEN 
			LET pr_invoicehead.cust_code = pr_customer.corp_cust_code 
			LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
		ELSE 
		LET pr_invoicehead.cust_code = pr_subhead.cust_code 
		LET pr_invoicehead.org_cust_code = pr_subhead.cust_code 
	END IF 
	DECLARE c_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = pr_invoicehead.cust_code 
	FOR UPDATE 
	OPEN c_customer 
	FETCH c_customer INTO pr_customer.* 
	LET pr_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_invoicehead.ord_num = pr_subhead.sub_num 
	LET pr_invoicehead.purchase_code = pr_subhead.ord_text 
	LET pr_invoicehead.ref_num = pr_subhead.sub_num 
	LET pr_invoicehead.inv_date = pr_issue_date 
	LET pr_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_invoicehead.entry_date = today 
	LET pr_invoicehead.sale_code = pr_subhead.sales_code 
	LET pr_invoicehead.term_code = pr_subhead.term_code 
	LET pr_invoicehead.tax_code = pr_subhead.tax_code 
	SELECT tax_per INTO pr_invoicehead.tax_per FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_invoicehead.tax_code 
	LET pr_invoicehead.goods_amt = 0 
	LET pr_invoicehead.hand_amt = pr_subhead.hand_amt - pr_subhead.hand_inv_amt 
	LET pr_invoicehead.hand_tax_code = pr_subhead.hand_tax_code 
	LET pr_invoicehead.hand_tax_amt = pr_subhead.hand_tax_amt - 
	pr_subhead.hndtax_inv_amt 
	LET pr_invoicehead.freight_amt = pr_subhead.freight_amt - 
	pr_subhead.freight_inv_amt 
	LET pr_invoicehead.freight_tax_code = pr_subhead.freight_tax_code 
	LET pr_invoicehead.freight_tax_amt = pr_subhead.freight_tax_amt - 
	pr_subhead.frttax_inv_amt 
	LET pr_invoicehead.hand_tax_code = pr_subhead.hand_tax_code 
	LET pr_invoicehead.tax_amt = 0 
	LET pr_invoicehead.disc_amt= 0 
	LET pr_invoicehead.total_amt = pr_invoicehead.goods_amt 
	+ pr_invoicehead.tax_amt 
	+ pr_invoicehead.hand_amt 
	+ pr_invoicehead.hand_tax_amt 
	+ pr_invoicehead.freight_amt 
	+ pr_invoicehead.freight_tax_amt 
	LET pr_invoicehead.cost_amt = 0 
	LET pr_invoicehead.paid_amt = 0 
	LET pr_invoicehead.paid_date = NULL 
	LET pr_invoicehead.disc_taken_amt = 0 
	SELECT * INTO pr_term.* FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_invoicehead.term_code 
	CALL get_due_and_discount_date(pr_term.*,pr_invoicehead.inv_date) 
	RETURNING pr_invoicehead.due_date, 
	pr_invoicehead.disc_date 
	LET pr_invoicehead.disc_amt = (pr_invoicehead.total_amt*pr_term.disc_per/100) 
	LET pr_invoicehead.expected_date = NULL 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,pr_invoicehead.inv_date) 
	RETURNING pr_invoicehead.year_num, 
	pr_invoicehead.period_num 
	LET pr_invoicehead.on_state_flag = "N" 
	LET pr_invoicehead.printed_num = 0 
	LET pr_invoicehead.posted_flag = "N" 
	LET pr_invoicehead.seq_num = 0 
	LET pr_invoicehead.printed_num = 0 
	LET pr_invoicehead.story_flag = NULL 
	LET pr_invoicehead.rev_date = today 
	LET pr_invoicehead.rev_num = 0 
	LET pr_invoicehead.ship_code = pr_subhead.ship_code 
	LET pr_invoicehead.name_text = pr_subhead.ship_name_text 
	LET pr_invoicehead.addr1_text = pr_subhead.ship_addr1_text 
	LET pr_invoicehead.addr2_text = pr_subhead.ship_addr2_text 
	LET pr_invoicehead.city_text = pr_subhead.ship_city_text 
	LET pr_invoicehead.state_code = pr_subhead.state_code 
	LET pr_invoicehead.post_code = pr_subhead.post_code 
	LET pr_invoicehead.country_code = pr_subhead.country_code --@db-patch_2020_10_04--
	LET pr_invoicehead.ship1_text = pr_subhead.ship1_text 
	LET pr_invoicehead.ship2_text = pr_subhead.ship2_text 
	LET pr_invoicehead.ship_date = pr_subhead.ship_date 
	LET pr_invoicehead.fob_text = pr_subhead.fob_text 
	LET pr_invoicehead.prepaid_flag = pr_subhead.prepaid_flag 
	LET pr_invoicehead.com1_text = pr_subhead.com1_text 
	LET pr_invoicehead.com2_text = pr_subhead.com2_text 
	LET pr_invoicehead.cost_ind = pr_subhead.cost_ind 
	LET pr_invoicehead.currency_code = pr_subhead.currency_code 
	LET pr_invoicehead.conv_qty = pr_subhead.conv_qty 
	LET pr_invoicehead.inv_ind = "7" 
	LET pr_invoicehead.prev_paid_amt = 0 
	LET pr_invoicehead.acct_override_code =pr_subhead.acct_override_code 
	LET pr_invoicehead.price_tax_flag = pr_subhead.price_tax_flag 
	LET pr_invoicehead.contact_text = pr_subhead.contact_text 
	LET pr_invoicehead.tele_text = pr_subhead.tele_text 
	LET pr_invoicehead.invoice_to_ind = pr_subhead.invoice_to_ind 
	LET pr_invoicehead.territory_code = pr_subhead.territory_code 
	LET pr_invoicehead.mgr_code = pr_subhead.mgr_code 
	LET pr_invoicehead.area_code = pr_subhead.area_code 
	LET pr_invoicehead.cond_code = pr_subhead.cond_code 
	LET pr_invoicehead.scheme_amt = pr_subhead.scheme_amt 
	LET pr_invoicehead.jour_num = NULL 
	LET pr_invoicehead.post_date = NULL 
	LET pr_invoicehead.carrier_code = pr_subhead.carrier_code 
	LET pr_invoicehead.manifest_num = NULL 
	LET pr_invoicehead.stat_date = NULL 
	LET pr_invoicehead.country_code = pr_customer.country_code 
	LET pr_temp_text = "SELECT * FROM prodstatus ", 
	" WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND part_code = ? AND ware_code = ? " 
	PREPARE s_prodstatus FROM pr_temp_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 
	LET pr_temp_text = "SELECT * FROM subcustomer ", 
	"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND cust_code= ? ", 
	"AND ship_code= ? ", 
	"AND sub_type_code = ? ", 
	"AND part_code= ? ", 
	"AND comm_date= ? ", 
	"AND end_date= ? " 
	PREPARE s2_subcustomer FROM pr_temp_text 
	DECLARE c2_subcustomer CURSOR FOR s2_subcustomer 

	#INSERT invoiceDetl Record
	DECLARE c1_invoicedetl CURSOR FOR 
	INSERT INTO invoicedetl VALUES (pr_invoicedetl.*)		
	 
	OPEN c1_invoicedetl 
	DECLARE c_prodledg CURSOR FOR 
	INSERT INTO prodledg VALUES (pr_prodledg.*) 
	OPEN c_prodledg 
	
	DECLARE c_subaudit CURSOR FOR 
	INSERT INTO subaudit VALUES (pr_subaudit.*) 
	OPEN c_subaudit 
	LET err_message = "KL1 - Next invoice number update" 
	LET pr_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,pr_invoicehead.acct_override_code) 
	
	IF pr_invoicehead.inv_num < 0 THEN 
		LET err_message = "KL1 - Error Obtaining Next Trans no." 
		LET status = pr_invoicehead.inv_num 
		RETURN status 
	END IF 
	
	######################################################################
	OPEN c2_subhead 
	FETCH c2_subhead INTO pr_subhead.* 
	LET idx = 0 
	
	FOREACH c_label INTO pr_label.* 
		IF pr_subhead.rev_num <> pr_label.rev_num THEN 
			LET err_message = "Subscription has been modified by another user" 
			LET status = -1 
			GOTO recovery 
		END IF 
		LET idx = idx + 1 
		LET pr_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_invoicedetl.cust_code = pr_invoicehead.cust_code 
		LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 
		LET pr_invoicedetl.line_num = idx 
		LET pr_invoicedetl.part_code = pr_label.part_code 
		LET pr_invoicedetl.ware_code = pr_subdetl.ware_code 
		LET pr_invoicedetl.ship_qty = pr_label.pr_issue_qty 
		LET pr_invoicedetl.unit_sale_amt = pr_subdetl.unit_amt 
		LET pr_invoicedetl.unit_tax_amt = pr_subdetl.unit_tax_amt 
		IF pr_subschedule.desc_text IS NULL THEN 
			LET pr_invoicedetl.line_text = pr_subdetl.line_text 
		ELSE 
		LET pr_invoicedetl.line_text = pr_subschedule.desc_text 
	END IF 
	LET pr_invoicedetl.ext_sale_amt = pr_subdetl.unit_amt * 
	pr_invoicedetl.ship_qty 
	LET pr_invoicedetl.ext_tax_amt = pr_subdetl.unit_tax_amt * 
	pr_invoicedetl.ship_qty 
	LET pr_invoicedetl.line_total_amt = pr_invoicedetl.ext_sale_amt + 
	pr_invoicedetl.ext_tax_amt 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_invoicedetl.part_code 
	LET pr_invoicedetl.cat_code = pr_product.cat_code 
	LET pr_invoicedetl.ser_flag = pr_product.serial_flag 
	IF pr_invoicedetl.line_text IS NULL THEN 
		LET pr_invoicedetl.line_text = pr_product.desc_text 
	END IF 
	LET pr_invoicedetl.uom_code = pr_product.sell_uom_code 
	LET pr_invoicedetl.prodgrp_code = pr_product.prodgrp_code 
	LET pr_invoicedetl.maingrp_code = pr_product.maingrp_code 
	SELECT sale_acct_code INTO pr_invoicedetl.line_acct_code 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_invoicedetl.cat_code 
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_invoicedetl.ware_code 
	AND part_code = pr_invoicedetl.part_code 
	LET pr_invoicedetl.unit_cost_amt = pr_prodstatus.wgted_cost_amt 
	* pr_subhead.conv_qty 
	LET pr_invoicedetl.ext_cost_amt = pr_invoicedetl.unit_cost_amt 
	* pr_invoicedetl.ship_qty 
	LET pr_invoicedetl.list_price_amt = pr_prodstatus.list_amt 
	* pr_subhead.conv_qty 
	IF pr_invoicedetl.list_price_amt = 0 THEN 
		LET pr_invoicedetl.list_price_amt = pr_invoicedetl.unit_sale_amt 
		LET pr_invoicedetl.disc_per = 0 
	END IF 
	IF pr_invoicedetl.disc_per IS NULL THEN 
		## calc disc_per based on price
		LET pr_float = 100 * (pr_invoicedetl.list_price_amt - 
		pr_invoicedetl.unit_sale_amt) / 
		pr_invoicedetl.list_price_amt 
		IF pr_float <= 0 THEN 
			LET pr_invoicedetl.disc_per = 0 
			LET pr_invoicedetl.list_price_amt = pr_invoicedetl.unit_sale_amt 
		ELSE 
		LET pr_invoicedetl.disc_per = pr_float 
	END IF 
END IF 
LET pr_invoicedetl.disc_amt = pr_invoicedetl.list_price_amt 
- pr_invoicedetl.unit_sale_amt 
##############################################################
## Adjust product AND create prodledger FOR scheduled product
##############################################################
SELECT * INTO pr_subproduct.* FROM subproduct 
WHERE part_code = pr_invoicedetl.part_code 
AND cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pr_subhead.sub_type_code 
IF pr_invoicedetl.part_code IS NOT NULL 
AND pr_invoicedetl.ship_qty != 0 THEN 
	OPEN c_prodstatus USING pr_invoicedetl.part_code, 
	pr_invoicedetl.ware_code 
	FETCH c_prodstatus INTO pr_prodstatus.* 
	IF pr_prodstatus.stocked_flag = "Y" THEN 
		LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
		LET pr_invoicedetl.seq_num = pr_prodstatus.seq_num 
		IF pr_prodstatus.onhand_qty IS NULL THEN 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 
		LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty 
		- pr_invoicedetl.ship_qty 
		INITIALIZE pr_prodledg.* TO NULL 
		LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_prodledg.part_code = pr_invoicedetl.part_code 
		LET pr_prodledg.ware_code = pr_invoicedetl.ware_code 
		LET pr_prodledg.tran_date = pr_invoicehead.inv_date 
		LET pr_prodledg.seq_num = pr_invoicedetl.seq_num 
		LET pr_prodledg.trantype_ind = "S" 
		LET pr_prodledg.year_num = pr_invoicehead.year_num 
		LET pr_prodledg.period_num = pr_invoicehead.period_num 
		LET pr_prodledg.source_text = pr_invoicedetl.cust_code 
		LET pr_prodledg.source_num = pr_invoicedetl.inv_num 
		LET pr_prodledg.tran_qty = 0 - pr_invoicedetl.ship_qty + 0 
		LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
		LET pr_prodledg.cost_amt = pr_invoicedetl.unit_cost_amt 
		/ pr_invoicehead.conv_qty 
		LET pr_prodledg.sales_amt=pr_invoicedetl.unit_sale_amt 
		/ pr_invoicehead.conv_qty 
		LET pr_prodledg.hist_flag = "N" 
		LET pr_prodledg.post_flag = "N" 
		LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_prodledg.entry_date = today 
		PUT c_prodledg 
	END IF 
	UPDATE prodstatus 
	SET onhand_qty = pr_prodstatus.onhand_qty, 
	reserved_qty = pr_prodstatus.reserved_qty, 
	last_sale_date = pr_invoicehead.inv_date, 
	seq_num = pr_prodstatus.seq_num 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_invoicedetl.part_code 
	AND ware_code = pr_invoicedetl.ware_code 
END IF 
LET pr_invoicedetl.line_acct_code = account_patch(glob_rec_kandoouser.cmpy_code, 
pr_invoicedetl.line_acct_code, 
pr_invoicehead.acct_override_code) 
PUT c1_invoicedetl 
OPEN c2_subcustomer USING pr_invoicehead.org_cust_code, 
pr_invoicehead.ship_code, 
pr_subhead.sub_type_code, 
pr_invoicedetl.part_code, 
pr_subhead.start_date, 
pr_subhead.end_date 
FETCH c2_subcustomer INTO pr_subcustomer.* 
IF status = 0 THEN 
	LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
	UPDATE subcustomer 
	SET issue_qty = issue_qty + pr_invoicedetl.ship_qty, 
	last_issue_num = pr_label.issue_num, 
	next_seq_num = pr_subcustomer.next_seq_num 
	WHERE cmpy_code = pr_invoicedetl.cmpy_code 
	AND cust_code = pr_invoicehead.org_cust_code 
	AND ship_code = pr_invoicehead.ship_code 
	AND sub_type_code = pr_subhead.sub_type_code 
	AND part_code = pr_invoicedetl.part_code 
	AND comm_date= pr_subhead.start_date 
	AND end_date= pr_subhead.end_date 
END IF 
LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_subaudit.part_code = pr_invoicedetl.part_code 
LET pr_subaudit.cust_code = pr_invoicehead.org_cust_code 
LET pr_subaudit.ship_code = pr_invoicehead.ship_code 
LET pr_subaudit.start_date = pr_subhead.start_date 
LET pr_subaudit.end_date = pr_subhead.end_date 
LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
LET pr_subaudit.tran_date = pr_invoicehead.inv_date 
LET pr_subaudit.entry_date = today 
LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_subaudit.tran_qty = pr_invoicedetl.ship_qty 
LET pr_subaudit.unit_amt = pr_invoicedetl.unit_sale_amt 
LET pr_subaudit.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
LET pr_subaudit.currency_code = pr_invoicehead.currency_code 
LET pr_subaudit.conv_qty = pr_invoicehead.conv_qty 
LET pr_subaudit.sub_num = pr_subhead.sub_num 
LET pr_subaudit.tran_type_ind = "ISS" 
LET pr_subaudit.source_num = pr_invoicehead.inv_num 
LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
LET pr_subaudit.comm_text = "Issue ",pr_issue_num USING "###",",", 
"Label ",pr_run_type clipped 
INSERT INTO subaudit VALUES (pr_subaudit.*) 
LET pr_inv_qty = 0 
IF pr_substype.inv_ind = "3" THEN 
	LET pr_subcustomer.next_seq_num = pr_subcustomer.next_seq_num + 1 
	UPDATE subcustomer 
	SET inv_qty = inv_qty + pr_invoicedetl.ship_qty, 
	next_seq_num = pr_subcustomer.next_seq_num 
	WHERE cmpy_code = pr_invoicedetl.cmpy_code 
	AND cust_code = pr_invoicehead.org_cust_code 
	AND ship_code = pr_invoicehead.ship_code 
	AND sub_type_code = pr_subhead.sub_type_code 
	AND part_code = pr_invoicedetl.part_code 
	AND comm_date= pr_subhead.start_date 
	AND end_date= pr_subhead.end_date 
	LET pr_subaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_subaudit.part_code = pr_invoicedetl.part_code 
	LET pr_subaudit.cust_code = pr_invoicehead.org_cust_code 
	LET pr_subaudit.ship_code = pr_invoicehead.ship_code 
	LET pr_subaudit.start_date = pr_subhead.start_date 
	LET pr_subaudit.end_date = pr_subhead.end_date 
	LET pr_subaudit.seq_num = pr_subcustomer.next_seq_num 
	LET pr_subaudit.tran_date = pr_invoicehead.inv_date 
	LET pr_subaudit.entry_date = today 
	LET pr_subaudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_subaudit.tran_qty = pr_invoicedetl.ship_qty 
	LET pr_subaudit.unit_amt = pr_invoicedetl.unit_sale_amt 
	LET pr_subaudit.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
	LET pr_subaudit.currency_code = pr_invoicehead.currency_code 
	LET pr_subaudit.conv_qty = pr_invoicehead.conv_qty 
	LET pr_subaudit.sub_num = pr_subhead.sub_num 
	LET pr_subaudit.tran_type_ind = "INV" 
	LET pr_subaudit.source_num = pr_invoicehead.inv_num 
	LET pr_subaudit.sub_type_code = pr_subhead.sub_type_code 
	LET pr_subaudit.comm_text = "Invoice (issue)" 
	INSERT INTO subaudit VALUES (pr_subaudit.*) 
	LET pr_inv_qty = pr_invoicedetl.ship_qty 
END IF 
OPEN c2_subdetl 
FETCH c2_subdetl INTO pr_subdetl.* 
UPDATE subdetl 
SET issue_qty = issue_qty + pr_invoicedetl.ship_qty, 
inv_qty = inv_qty + pr_inv_qty 
WHERE sub_num = pr_label.sub_num 
AND sub_line_num = pr_label.sub_line_num 
AND cmpy_code = glob_rec_kandoouser.cmpy_code 
OPEN c2_subschedule 
FETCH c2_subschedule INTO pr_subschedule.* 
IF pr_inv_qty > 0 THEN 
	LET pr_subschedule.inv_date = pr_issue_date 
END IF 
UPDATE subschedule 
SET issue_qty = issue_qty + pr_invoicedetl.ship_qty, 
inv_qty = inv_qty + pr_inv_qty, 
issue_date = pr_issue_date, 
inv_date = pr_subschedule.inv_date 
WHERE sub_num = pr_label.sub_num 
AND sub_line_num = pr_label.sub_line_num 
AND issue_num = pr_label.issue_num 
AND cmpy_code = glob_rec_kandoouser.cmpy_code 
UPDATE subissues 
SET last_issue_num = pr_label.issue_num 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pr_subhead.sub_type_code 
AND part_code = pr_subdetl.part_code 
AND start_date = pr_subhead.start_date 
AND last_issue_num < pr_label.issue_num 
UPDATE subissues 
SET act_iss_date = pr_issue_date 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND type_code = pr_subhead.sub_type_code 
AND part_code = pr_subdetl.part_code 
AND start_date = pr_subhead.start_date 
AND issue_num = pr_label.issue_num 
AND act_iss_date IS NULL 
END FOREACH 
FLUSH c1_invoicedetl 
IF pr_substype.inv_ind <> "3" THEN 
IF idx > 0 THEN 
	LET idx = idx + 1 
	LET pr_invoicehead.hand_amt = 0 
	LET pr_invoicehead.hand_tax_amt = 0 
	LET pr_invoicehead.freight_amt = 0 
	LET pr_invoicehead.freight_tax_amt = 0 
	LET pr_invoicehead.on_state_flag = "Y" 
	LET pr_invoicehead.printed_num = 1 
	LET pr_invoicedetl.part_code = NULL 
	LET pr_invoicedetl.ware_code = NULL 
	LET pr_invoicedetl.line_text = "Subscription Liability Balancing entry" 
	LET pr_invoicedetl.ship_qty = -1 
	LET pr_invoicedetl.line_num = idx 
	SELECT sum(ext_sale_amt), 
	sum(ext_tax_amt), 
	sum(ext_cost_amt) 
	INTO pr_invoicedetl.unit_sale_amt, 
	pr_invoicedetl.unit_tax_amt, 
	pr_invoicedetl.unit_cost_amt 
	FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_invoicehead.inv_num 
	LET pr_invoicedetl.ext_sale_amt = pr_invoicedetl.unit_sale_amt 
	* pr_invoicedetl.ship_qty 
	LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.unit_tax_amt 
	* pr_invoicedetl.ship_qty 
	LET pr_invoicedetl.line_total_amt = pr_invoicedetl.ext_sale_amt 
	+ pr_invoicedetl.ext_tax_amt 
	LET pr_invoicedetl.ext_cost_amt = pr_invoicedetl.unit_cost_amt 
	* pr_invoicedetl.ship_qty 
	IF pr_substype.subacct_code IS NOT NULL THEN 
		LET pr_invoicedetl.line_acct_code = pr_substype.subacct_code 
	ELSE 
	SELECT sub_acct_code INTO pr_invoicedetl.line_acct_code 
	FROM ssparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
END IF 
LET pr_invoicedetl.cat_code = NULL 
LET pr_invoicedetl.ser_flag = NULL 
LET pr_invoicedetl.uom_code = NULL 
LET pr_invoicedetl.prodgrp_code = NULL 
LET pr_invoicedetl.maingrp_code = NULL 
PUT c1_invoicedetl 
FLUSH c1_invoicedetl 
END IF 
END IF 
LET pr_invoicehead.line_num = idx 
SELECT sum(ext_sale_amt), 
sum(ext_tax_amt), 
sum(ext_cost_amt) 
INTO pr_invoicehead.goods_amt, 
pr_invoicehead.tax_amt, 
pr_invoicehead.cost_amt 
FROM invoicedetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND inv_num = pr_invoicehead.inv_num 
LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 
LET pr_invoicehead.total_amt = pr_invoicehead.tax_amt 
+ pr_invoicehead.goods_amt 
+ pr_invoicehead.freight_amt 
+ pr_invoicehead.freight_tax_amt 
+ pr_invoicehead.hand_amt 
+ pr_invoicehead.hand_tax_amt 



#INSERT invoicehead Record
IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,pr_invoicehead.*) THEN
	INSERT INTO invoicehead VALUES (pr_invoicehead.*)			
ELSE
	DISPLAY pr_invoicehead.*
	CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
END IF 

SELECT unique 1 FROM subdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND (inv_qty != 0 OR issue_qty != 0) 
IF sqlca.sqlcode = notfound THEN 

## No lines shipped THEN sub IS unshipped
LET pr_subhead.status_ind = "U" 
ELSE 
SELECT unique 1 FROM subdetl 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
AND (inv_qty != sub_qty OR inv_qty != issue_qty 
OR issue_qty != sub_qty) 
IF sqlca.sqlcode = 0 THEN 
## Incomplete lines exists so sub IS partial shipped
LET pr_subhead.status_ind = "P" 
ELSE 
LET pr_subhead.status_ind = "C" 
END IF 
END IF 
UPDATE subhead 
SET last_inv_num = pr_invoicehead.inv_num, 
hand_inv_amt = hand_inv_amt + pr_invoicehead.hand_amt, 
hndtax_inv_amt = hndtax_inv_amt + pr_invoicehead.hand_tax_amt, 
freight_inv_amt = freight_inv_amt + pr_invoicehead.freight_amt, 
frttax_inv_amt = frttax_inv_amt + pr_invoicehead.freight_tax_amt, 
status_ind = pr_subhead.status_ind 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND sub_num = pr_subhead.sub_num 
################################################
## Now TO UPDATE customer
################################################
LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
LET pr_customer.bal_amt = pr_customer.bal_amt 
+ pr_invoicehead.total_amt 
LET err_message = "KL1 - Unable TO add TO AR log table " 
INITIALIZE pr_araudit.* TO NULL 
LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
LET pr_araudit.tran_date = pr_invoicehead.inv_date 
LET pr_araudit.cust_code = pr_invoicehead.cust_code 
LET pr_araudit.seq_num = pr_customer.next_seq_num 
LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
LET pr_araudit.source_num = pr_invoicehead.inv_num 
LET pr_araudit.tran_text = "Invoice (issue)" 
LET pr_araudit.tran_amt = pr_invoicehead.total_amt 
LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
LET pr_araudit.sales_code = pr_invoicehead.sale_code 
LET pr_araudit.year_num = pr_invoicehead.year_num 
LET pr_araudit.period_num = pr_invoicehead.period_num 
LET pr_araudit.bal_amt = pr_customer.bal_amt 
LET pr_araudit.currency_code = pr_customer.currency_code 
LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
LET pr_araudit.entry_date = today 
INSERT INTO araudit VALUES (pr_araudit.*) 
LET pr_customer.curr_amt = pr_customer.curr_amt 
+ pr_invoicehead.total_amt 
IF pr_customer.bal_amt > pr_customer.highest_bal_amt THEN 
LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
END IF 
LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
- pr_customer.bal_amt 
IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
LET pr_customer.ytds_amt = 0 
LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.ytds_amt = pr_customer.ytds_amt 
+ pr_invoicehead.total_amt 
IF month(pr_invoicehead.inv_date)>month(pr_customer.last_inv_date) THEN 
LET pr_customer.mtds_amt = 0 
END IF 
LET pr_customer.mtds_amt = pr_customer.mtds_amt 
+ pr_invoicehead.total_amt 
LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
LET err_message = "KL1 - Customer actual UPDATE " 
UPDATE customer 
SET next_seq_num = pr_customer.next_seq_num, 
bal_amt = pr_customer.bal_amt, 
curr_amt = pr_customer.curr_amt, 
highest_bal_amt = pr_customer.highest_bal_amt, 
cred_bal_amt = pr_customer.cred_bal_amt, 
last_inv_date = pr_customer.last_inv_date, 
ytds_amt = pr_customer.ytds_amt, 
mtds_amt = pr_customer.mtds_amt 
WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
AND cust_code = pr_customer.cust_code 
COMMIT WORK 
WHENEVER ERROR stop 

IF pr_substype.inv_ind = "3" THEN 
	OUTPUT TO REPORT KL1_rpt_list_invoice(1,pr_invoicehead.*) 
ELSE 
	OUTPUT TO REPORT KL1_rpt_list_invoice(2,pr_invoicehead.*) 
END IF 

RETURN true 
END FUNCTION 


REPORT KL1_rpt_list_excep(p_rpt_idx,err_message,pr_subhead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_subhead RECORD LIKE subhead.*, 
	err_message CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(132), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 

	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = "KL1 Subscription Issue Error log" 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 
			PRINT COLUMN 1, rpt_date, 
			COLUMN offset1, line1 clipped, 
			COLUMN 120, "Page: ", pageno USING "####" 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Subscription", 
			COLUMN 25,"Error message" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
		ON EVERY ROW 
			PRINT COLUMN 1, pr_subhead.cust_code, 
			COLUMN 10,pr_subhead.sub_num USING "#########", 
			COLUMN 25,err_message clipped 
		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KL1 ERROR LOG *****" 
END REPORT 


REPORT KL1_rpt_list_invoice(p_rpt_idx,pr_inv_type,pr_invoicehead) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE 
	pr_invoicehead RECORD LIKE invoicehead.*, 
	pr_inv_type SMALLINT, 
	pr_desc CHAR(60), 
	line1, line2 CHAR(132), 
	rpt_note CHAR(60), 
	offset1, offset2 SMALLINT, 
	len, s INTEGER 

	OUTPUT 
	left margin 0 
	FORMAT 
		PAGE HEADER 
			LET line1 = pr_company.cmpy_code, 2 spaces, pr_company.name_text clipped 
			LET rpt_note = "KL1 Subscription Issue Invoice log" 
			LET line2 = rpt_note clipped 
			LET offset1 = (rpt_wid - length(line1))/2 
			LET offset2 = (rpt_wid - length(line2))/2 
			PRINT COLUMN 1, rpt_date, 
			COLUMN offset1, line1 clipped, 
			COLUMN 120, "Page: ", pageno USING "####" 
			PRINT COLUMN 1, time, 
			COLUMN offset2, line2 clipped 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
			PRINT COLUMN 1, "Customer", 
			COLUMN 10,"Invoice", 
			COLUMN 25,"Description", 
			COLUMN 90,"Total" 
			PRINT COLUMN 1, "----------------------------------------", 
			"----------------------------------------", 
			"----------------------------------------", 
			"-----------" 
		ON EVERY ROW 
			IF pr_inv_type = 1 THEN 
				LET pr_desc = "Invoice on despatch" 
			ELSE 
			LET pr_desc = "Subscription Liability Balancing entry" 
		END IF 
		PRINT COLUMN 1, pr_invoicehead.cust_code, 
		COLUMN 10,pr_invoicehead.inv_num USING "#########", 
		COLUMN 25,pr_desc clipped, 
		COLUMN 85,pr_invoicehead.total_amt USING "---,---,--&.&&" 
		ON LAST ROW 
			LET rpt_pageno = pageno 
			NEED 5 LINES 
			SKIP 2 LINES 
			SKIP 3 LINES 
			PRINT COLUMN 20, "***** END OF REPORT KL1 INVOICE LOG *****" 
END REPORT 
