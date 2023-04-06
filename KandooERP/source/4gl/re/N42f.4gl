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
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N42_GLOBALS.4gl"  
#    N42f Database Update/Insert Routines used by PO Authorization

FUNCTION write_purchord() 
	DEFINE 
	pr_reqaudit RECORD LIKE reqaudit.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_term RECORD LIKE term.*, 
	pr_tax RECORD LIKE tax.*, 
	pr_acct_mask_code LIKE warehouse.acct_mask_code, 
	pr_purchase RECORD 
		vend_code LIKE reqdetl.vend_code, 
		ware_code LIKE reqhead.ware_code 
	END RECORD, 
	pr_reqpurch RECORD 
		pend_num LIKE pendhead.pend_num, 
		vend_code LIKE pendhead.vend_code, 
		ware_code LIKE pendhead.ware_code, 
		part_code LIKE penddetl.part_code, 
		req_num INTEGER, 
		req_line_num INTEGER, 
		po_qty DECIMAL(12,4), 
		unit_cost_amt DECIMAL(10,2), 
		desc_text CHAR(40), 
		auth_ind SMALLINT, 
		req_alt_ind SMALLINT 
	END RECORD, 
	pr_save_req_qty LIKE reqdetl.req_qty, 
	pr_total_cost_amt LIKE reqhead.total_cost_amt, 
	err_continue CHAR(1), 
	pr_po_cnt, cnt SMALLINT 
	DEFINE l_err_message STRING 

	#OPEN WINDOW w1_N42 AT 2,3 with 1 rows,33 columns
	#ATTRIBUTE(border,reverse)
	LET msgresp = kandoomsg("U",1005,"") 
	#1005 Updating Database;  Please wait.
	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(l_err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_po_cnt = 0 
		DECLARE c1_reqpurch CURSOR FOR 
		SELECT * 
		FROM reqpurch 
		WHERE req_alt_ind = 1 
		FOREACH c1_reqpurch INTO pr_reqpurch.* 
			LET l_err_message = "N42 - Pending Order Detail Update" 
			DECLARE c1_penddetl CURSOR FOR 
			SELECT penddetl.* 
			FROM penddetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pend_num = pr_reqpurch.pend_num 
			AND req_num = pr_reqpurch.req_num 
			AND req_line_num = pr_reqpurch.req_line_num 
			FOR UPDATE 
			OPEN c1_penddetl 
			FETCH c1_penddetl INTO pr_penddetl.* 
			LET pr_save_req_qty = pr_penddetl.po_qty 
			UPDATE penddetl 
			SET po_qty = pr_reqpurch.po_qty 
			WHERE CURRENT OF c1_penddetl 
			LET l_err_message = "N42 - Requisition Detail Update" 
			DECLARE c1_reqdetl CURSOR FOR 
			SELECT reqdetl.* 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
			AND line_num = pr_reqpurch.req_line_num 
			FOR UPDATE 
			OPEN c1_reqdetl 
			FETCH c1_reqdetl INTO pr_reqdetl.* 
			LET pr_reqdetl.unit_cost_amt = pr_reqpurch.unit_cost_amt 
			LET pr_reqdetl.unit_sales_amt = pr_reqpurch.unit_cost_amt 
			LET pr_reqdetl.req_qty = pr_reqdetl.req_qty 
			- pr_save_req_qty 
			+ pr_reqpurch.po_qty 
			LET pr_reqdetl.back_qty = pr_reqdetl.back_qty 
			- pr_save_req_qty 
			+ pr_reqpurch.po_qty 
			LET pr_reqdetl.po_qty = pr_reqdetl.po_qty 
			- pr_save_req_qty 
			+ pr_reqpurch.po_qty 
			LET pr_reqdetl.seq_num = pr_reqdetl.seq_num + 1 
			UPDATE reqdetl 
			SET * = pr_reqdetl.* 
			WHERE CURRENT OF c1_reqdetl 
			#LET pr_reqaudit.cmpy_code = glob_rec_kandoouser.cmpy_code
			#LET pr_reqaudit.req_num = pr_reqdetl.req_num
			#LET pr_reqaudit.line_num = pr_reqdetl.line_num
			#LET pr_reqaudit.seq_num = pr_reqdetl.seq_num
			#LET pr_reqaudit.tran_type_ind = "ER"
			#LET pr_reqaudit.tran_date = today
			#LET pr_reqaudit.entry_code = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty = pr_reqdetl.req_qty
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET l_err_message = "N14 - Requisition Header Update" 
			SELECT sum(unit_cost_amt * req_qty) 
			INTO pr_total_cost_amt 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
			AND req_qty IS NOT NULL 
			AND unit_sales_amt IS NOT NULL 
			IF pr_total_cost_amt IS NULL THEN 
				LET pr_total_cost_amt = 0 
			END IF 
			UPDATE reqhead 
			SET total_cost_amt = pr_total_cost_amt, 
			total_sales_amt = pr_total_cost_amt, 
			last_mod_code = glob_rec_kandoouser.sign_on_code, 
			last_mod_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
		END FOREACH 
		DECLARE c_puparms CURSOR FOR 
		SELECT * 
		FROM puparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_puparms 
		FETCH c_puparms INTO pr_puparms.* 
		DECLARE c2_reqpurch CURSOR FOR 
		SELECT vend_code, 
		ware_code 
		FROM reqpurch 
		WHERE auth_ind = 1 
		GROUP BY vend_code, 
		ware_code 
		FOREACH c2_reqpurch INTO pr_purchase.* 
			SELECT * 
			INTO pr_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchase.vend_code 
			SELECT * 
			INTO pr_warehouse.* 
			FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_purchase.ware_code 
			SELECT * 
			INTO pr_term.* 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = pr_vendor.term_code 
			SELECT * 
			INTO pr_tax.* 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_vendor.tax_code 
			LET pr_purchhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_purchhead.order_num = pr_puparms.next_po_num 
			LET pr_purchhead.vend_code = pr_purchase.vend_code 
			LET pr_purchhead.year_num = pr_period.year_num 
			LET pr_purchhead.period_num = pr_period.period_num 
			LET pr_purchhead.var_num = NULL 
			LET pr_purchhead.order_text = NULL 
			LET pr_purchhead.enter_code = glob_rec_kandoouser.sign_on_code 
			LET pr_purchhead.entry_date = today 
			LET pr_purchhead.order_date = today 
			LET pr_purchhead.salesperson_text = NULL 
			LET pr_purchhead.term_code = pr_vendor.term_code 
			LET pr_purchhead.tax_code = pr_vendor.tax_code 
			LET pr_purchhead.ware_code = pr_purchase.ware_code 
			LET pr_purchhead.curr_code = pr_vendor.currency_code 
			LET pr_purchhead.conv_qty = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				pr_purchhead.curr_code,
				today,
				CASH_EXCHANGE_SELL) 
			
			LET pr_purchhead.due_date = today + pr_term.due_day_num 
			LET pr_purchhead.cancel_date = NULL 
			LET pr_purchhead.status_ind = "O" 
			LET pr_purchhead.printed_flag = "N" 
			LET pr_purchhead.authorise_code = glob_rec_kandoouser.sign_on_code 
			LET pr_purchhead.retention_code = NULL 
			LET pr_purchhead.retention_amt = NULL 
			LET pr_purchhead.del_name_text = pr_warehouse.contact_text 
			LET pr_purchhead.del_addr1_text = pr_warehouse.addr1_text 
			LET pr_purchhead.del_addr2_text = pr_warehouse.addr2_text 
			LET pr_purchhead.del_addr3_text = pr_warehouse.city_text 
			LET pr_purchhead.del_addr4_text = pr_warehouse.state_code,pr_warehouse.post_code 
			LET pr_purchhead.contact_text = pr_warehouse.contact_text 
			LET pr_purchhead.tele_text = pr_warehouse.tele_text 
			LET pr_purchhead.var_num = 0 
			LET pr_purchhead.note_code = NULL 
			
			SELECT country_text 
			INTO pr_purchhead.del_country_code 
			FROM country 
			WHERE country_code = pr_warehouse.country_code 
			
			LET pr_purchhead.type_ind = "I" 
			LET pr_purchhead.confirm_ind = NULL 
			LET pr_purchhead.confirm_date = NULL 
			LET pr_purchhead.confirm_text = NULL 
			LET pr_purchhead.com1_text = "Automatic Generation FROM Requisition" 
			LET pr_purchhead.com2_text = NULL 
			LET pr_purchhead.purchtype_code = pr_vendor.purchtype_code 
			
			DECLARE c3_reqpurch CURSOR FOR 
			SELECT * 
			FROM reqpurch 
			WHERE vend_code = pr_purchase.vend_code 
			AND ware_code = pr_purchase.ware_code 
			AND auth_ind = 1 
			ORDER BY req_num, 
			req_line_num 
			LET cnt = 0 
			FOREACH c3_reqpurch INTO pr_reqpurch.* 
				SELECT * 
				INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = pr_reqpurch.part_code 
				LET cnt = cnt + 1 
				LET pr_purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_purchdetl.vend_code = pr_purchhead.vend_code 
				LET pr_purchdetl.order_num = pr_purchhead.order_num 
				LET pr_purchdetl.line_num = cnt 
				LET pr_purchdetl.seq_num = 1 
				LET pr_purchdetl.type_ind = "I" 
				LET pr_purchdetl.ref_text = pr_reqpurch.part_code 
				LET pr_purchdetl.oem_text = pr_product.oem_text 
				LET pr_purchdetl.job_code = NULL 
				LET pr_purchdetl.var_num = NULL 
				LET pr_purchdetl.activity_code = NULL 
				LET pr_purchdetl.desc_text = pr_reqpurch.desc_text 
				LET pr_purchdetl.uom_code = pr_product.pur_uom_code 
				LET pr_purchdetl.list_cost_amt = pr_poaudit.unit_cost_amt 
				LET pr_purchdetl.disc_per = 0 
				LET pr_purchdetl.note_code = NULL 
				SELECT stock_acct_code INTO pr_purchdetl.acct_code FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = pr_product.cat_code 
				SELECT acct_mask_code INTO pr_acct_mask_code FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_purchase.ware_code 
				LET pr_purchdetl.acct_code = build_mask(glob_rec_kandoouser.cmpy_code, 
				pr_acct_mask_code, 
				pr_purchdetl.acct_code) 
				INSERT INTO purchdetl VALUES (pr_purchdetl.*) 
				LET pr_poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_poaudit.po_num = pr_purchhead.order_num 
				LET pr_poaudit.line_num = cnt 
				LET pr_poaudit.seq_num = 1 
				LET pr_poaudit.vend_code = pr_purchhead.vend_code 
				LET pr_poaudit.tran_code = "AA" 
				LET pr_poaudit.tran_num = 1 
				LET pr_poaudit.tran_date = today 
				LET pr_poaudit.entry_date = today 
				LET pr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_poaudit.orig_auth_flag = "N" 
				LET pr_poaudit.now_auth_flag = "N" 
				LET pr_poaudit.order_qty = pr_reqpurch.po_qty 
				LET pr_poaudit.received_qty = 0 
				LET pr_poaudit.voucher_qty = 0 
				LET pr_poaudit.desc_text = pr_reqpurch.desc_text 
				LET pr_poaudit.unit_cost_amt = pr_reqpurch.unit_cost_amt 
				LET pr_poaudit.ext_cost_amt = pr_poaudit.order_qty 
				* pr_poaudit.unit_cost_amt 
				LET pr_poaudit.unit_tax_amt = pr_poaudit.unit_cost_amt 
				* pr_tax.tax_per 
				LET pr_poaudit.ext_tax_amt = pr_poaudit.order_qty 
				* pr_poaudit.unit_tax_amt 
				# Can't calculate by adding extended amounts as definitions do NOT
				# match - ext_cost_amt IS dec(16,4).
				#           LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt
				#                                         + pr_poaudit.ext_tax_amt
				LET pr_poaudit.line_total_amt = pr_poaudit.order_qty * 
				(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt) 
				LET pr_poaudit.jour_num = 0 
				LET pr_poaudit.posted_flag = "N" 
				LET pr_poaudit.year_num = pr_purchhead.year_num 
				LET pr_poaudit.period_num = pr_purchhead.period_num 
				INSERT INTO poaudit VALUES (pr_poaudit.*) 
				DECLARE c_prodstatus CURSOR FOR 
				SELECT * 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_reqpurch.ware_code 
				AND part_code = pr_reqpurch.part_code 
				FOR UPDATE 
				OPEN c_prodstatus 
				FETCH c_prodstatus INTO pr_prodstatus.* 
				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				IF pr_prodstatus.onord_qty IS NULL THEN 
					LET pr_prodstatus.onord_qty = 0 
				END IF 
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					LET pr_prodstatus.onord_qty = pr_prodstatus.onord_qty 
					+ pr_poaudit.order_qty 
				END IF 
				UPDATE prodstatus 
				SET onord_qty = pr_prodstatus.onord_qty, 
				seq_num = pr_prodstatus.seq_num 
				WHERE CURRENT OF c_prodstatus 
				UPDATE penddetl 
				SET auth_po_qty = auth_po_qty + pr_reqpurch.po_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND pend_num = pr_reqpurch.pend_num 
				AND req_num = pr_reqpurch.req_num 
				AND req_line_num = pr_reqpurch.req_line_num 
			END FOREACH 
			LET l_err_message = " N42 - Insert Purchase Order Header" 
			INSERT INTO purchhead VALUES (pr_purchhead.*) 
			LET pr_po_cnt = pr_po_cnt + 1 
			LET l_err_message = " N42 - Update Pending Order Header" 
			UPDATE pendhead 
			SET auth_date = today, 
			po_num = pr_purchhead.order_num, 
			auth_code = glob_rec_kandoouser.sign_on_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pend_num = pr_reqpurch.pend_num 
			LET pr_puparms.next_po_num = pr_puparms.next_po_num + 1 
		END FOREACH 
		##########################
		### The following Code zeros out req & pend detl lines that
		### have NOT been authorized but are part of an authorized ORDER
		DECLARE c4_reqpurch CURSOR FOR 
		SELECT x.* 
		FROM reqpurch x 
		WHERE x.auth_ind = 0 
		AND exists (SELECT 1 FROM reqpurch y 
		WHERE y.pend_num = x.pend_num 
		AND y.auth_ind = 1 ) 
		ORDER BY x.pend_num, 
		x.req_num, 
		x.req_line_num 
		FOREACH c4_reqpurch INTO pr_reqpurch.* 
			LET l_err_message = "N42 - Pending Order Detail Zero" 
			UPDATE penddetl 
			SET po_qty = 0 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND pend_num = pr_reqpurch.pend_num 
			AND req_num = pr_reqpurch.req_num 
			AND req_line_num = pr_reqpurch.req_line_num 
			LET l_err_message = "N42 - Requisition Detail Zero " 
			DECLARE c2_reqdetl CURSOR FOR 
			SELECT reqdetl.* 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
			AND line_num = pr_reqpurch.req_line_num 
			FOR UPDATE 
			OPEN c2_reqdetl 
			FETCH c2_reqdetl INTO pr_reqdetl.* 
			LET pr_reqdetl.req_qty = pr_reqdetl.req_qty 
			- pr_reqpurch.po_qty 
			LET pr_reqdetl.back_qty = pr_reqdetl.back_qty 
			- pr_reqpurch.po_qty 
			LET pr_reqdetl.po_qty = pr_reqdetl.po_qty 
			- pr_reqpurch.po_qty 
			LET pr_reqdetl.seq_num = pr_reqdetl.seq_num + 1 
			UPDATE reqdetl 
			SET * = pr_reqdetl.* 
			WHERE CURRENT OF c2_reqdetl 
			#LET pr_reqaudit.cmpy_code = glob_rec_kandoouser.cmpy_code
			#LET pr_reqaudit.req_num = pr_reqdetl.req_num
			#LET pr_reqaudit.line_num = pr_reqdetl.line_num
			#LET pr_reqaudit.seq_num = pr_reqdetl.seq_num
			#LET pr_reqaudit.tran_type_ind = "ER"
			#LET pr_reqaudit.tran_date = today
			#LET pr_reqaudit.entry_code = glob_rec_kandoouser.sign_on_code
			#LET pr_reqaudit.unit_cost_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.unit_tax_amt = 0
			#LET pr_reqaudit.unit_sales_amt = pr_reqdetl.unit_sales_amt
			#LET pr_reqaudit.tran_qty = pr_reqdetl.req_qty
			#INSERT INTO reqaudit VALUES(pr_reqaudit.*)
			LET l_err_message = "N14 - 2nd Requisition Header Update" 
			SELECT sum(unit_cost_amt * req_qty) 
			INTO pr_total_cost_amt 
			FROM reqdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
			AND req_qty IS NOT NULL 
			AND unit_sales_amt IS NOT NULL 
			IF pr_total_cost_amt IS NULL THEN 
				LET pr_total_cost_amt = 0 
			END IF 
			UPDATE reqhead 
			SET total_cost_amt = pr_total_cost_amt, 
			total_sales_amt = pr_total_cost_amt, 
			last_mod_code = glob_rec_kandoouser.sign_on_code, 
			last_mod_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND req_num = pr_reqpurch.req_num 
		END FOREACH 
		### This code may be temporary.
		##########################
		UPDATE puparms 
		SET next_po_num = pr_puparms.next_po_num 
		WHERE CURRENT OF c_puparms 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN pr_po_cnt 
END FUNCTION 
