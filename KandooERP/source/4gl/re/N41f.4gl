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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"   
GLOBALS "../re/N_RE_GLOBALS.4gl"
GLOBALS "../re/N4_GROUP_GLOBALS.4gl"
GLOBALS "../re/N41_GLOBALS.4gl"  

#    N41f Database Update/Insert Routines used by PO Generation

FUNCTION write_purchord() 
	DEFINE 
	pr_reqhead RECORD LIKE reqhead.*, 
	pr_pendhead RECORD LIKE pendhead.*, 
	pr_penddetl RECORD LIKE penddetl.*, 
	pr_reqdetl RECORD LIKE reqdetl.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_vendor RECORD LIKE vendor.*, 
	pr_tax RECORD LIKE tax.*, 
	pr_purchase RECORD 
		vend_code LIKE reqdetl.vend_code, 
		ware_code LIKE reqhead.ware_code, 
		total_po_amt LIKE poaudit.line_total_amt 
	END RECORD, 
	pr_reqpurch RECORD 
		vend_code LIKE reqdetl.vend_code, 
		ware_code LIKE reqhead.ware_code, 
		part_code LIKE reqdetl.part_code, 
		req_num LIKE reqdetl.req_num, 
		line_num LIKE reqdetl.line_num, 
		replenish_ind LIKE reqdetl.replenish_ind, 
		unit_sales_amt LIKE reqdetl.unit_sales_amt, 
		po_qty LIKE poaudit.order_qty, 
		desc_text LIKE reqdetl.desc_text 
	END RECORD, 
	pr_ibthead RECORD LIKE ibthead.*, 
	pr_ibtdetl RECORD LIKE ibtdetl.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_supply RECORD LIKE supply.*, 
	pr_suburb RECORD LIKE suburb.*, 
	pr_acct_mask_code LIKE warehouse.acct_mask_code, 
	err_message CHAR(40), 
	l_kandoo_log_msg CHAR(60), 
	err_continue CHAR(1), 
	pr_tax_tot, pr_received_tot LIKE vendor.onorder_amt, 
	pr_voucher_tot, pr_onord_amt LIKE vendor.onorder_amt, 
	pr_trf_cnt,pr_po_cnt,pr_pnd_cnt, cnt, pr_line_num SMALLINT, 
	pr_first_ponum,pr_last_ponum,pr_first_trfnum,pr_last_trfnum INTEGER, 
	pr_err_cnt SMALLINT, 
	pr_stk_sel_con_qty LIKE product.stk_sel_con_qty 

	LET msgresp=kandoomsg("U",1005,"") 	#1005 Updating Database;  Please wait.
	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pr_po_cnt = 0 
		LET pr_pnd_cnt = 0 
		LET pr_trf_cnt = 0 
		INITIALIZE pr_puparms.cmpy_code TO NULL 
		INITIALIZE glob_rec_reqparms.cmpy_code TO NULL 
		DECLARE c0_reqpurch CURSOR FOR 
		SELECT vend_code, 
		ware_code, 
		sum(po_qty * unit_sales_amt) 
		FROM reqpurch 
		WHERE replenish_ind = 'P' 
		GROUP BY vend_code, 
		ware_code 
		FOREACH c0_reqpurch INTO pr_purchase.* 
			DECLARE c_vendor CURSOR FOR 
			SELECT * FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = pr_purchase.vend_code 
			FOR UPDATE 
			OPEN c_vendor 
			FETCH c_vendor INTO pr_vendor.* 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = pr_purchase.ware_code 
			SELECT * INTO pr_tax.* FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_vendor.tax_code 
			### Only create pending purchase of reqparms pending purchase
			### flag IS SET TO 'Y'
			IF pr_purchase.total_po_amt > pr_reqperson.po_up_limit_amt 
			AND glob_rec_reqparms.pend_purch_flag = 'Y' THEN 
				IF glob_rec_reqparms.cmpy_code IS NULL THEN 
					DECLARE c_reqparms CURSOR FOR 
					SELECT * FROM reqparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
					FOR UPDATE 
					OPEN c_reqparms 
					FETCH c_reqparms INTO glob_rec_reqparms.* 
					LET pr_first_pnnum = glob_rec_reqparms.next_pend_po_num 
				END IF 
				LET pr_pendhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_pendhead.pend_num = glob_rec_reqparms.next_pend_po_num 
				LET pr_pendhead.vend_code = pr_purchase.vend_code 
				LET pr_pendhead.entry_date = today 
				LET pr_pendhead.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_pendhead.year_num = pr_period.year_num 
				LET pr_pendhead.period_num = pr_period.period_num 
				LET pr_pendhead.order_date = today 
				LET pr_pendhead.ware_code = pr_purchase.ware_code 
				LET pr_pendhead.auth_date = NULL 
				LET pr_pendhead.po_num = NULL 
				LET pr_pendhead.auth_code = NULL 
				LET pr_pendhead.cancel_date = NULL 
				LET pr_pendhead.due_date = today 
				DECLARE c1_reqpurch CURSOR FOR 
				SELECT * FROM reqpurch 
				WHERE vend_code = pr_purchase.vend_code 
				AND ware_code = pr_purchase.ware_code 
				AND replenish_ind = 'P' 
				ORDER BY req_num, line_num 
				LET err_message = " N41 - Insert Pending P.O. Details" 
				LET cnt = 0 
				FOREACH c1_reqpurch INTO pr_reqpurch.* 
					SELECT * INTO pr_reqhead.* FROM reqhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_reqpurch.part_code 
					SELECT * INTO pr_reqdetl.* FROM reqdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND line_num = pr_reqpurch.line_num 
					IF ((pr_reqdetl.po_qty + pr_reqpurch.po_qty) 
					> pr_reqdetl.req_qty) THEN 
						LET l_kandoo_log_msg = "Requisition line ", 
						pr_reqdetl.line_num USING "<<<<" clipped," ", 
						"Requisition number ", 
						pr_reqdetl.req_num USING "<<<<<<<<" clipped, 
						" Approval failed." 
						CALL errorlog(l_kandoo_log_msg) 
						LET pr_err_cnt = pr_err_cnt + 1 
						CONTINUE FOREACH 
					END IF 
					LET cnt = cnt + 1 
					LET pr_penddetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_penddetl.pend_num = pr_pendhead.pend_num 
					LET pr_penddetl.line_num = cnt 
					LET pr_penddetl.line_type = "I" 
					LET pr_penddetl.req_num = pr_reqpurch.req_num 
					LET pr_penddetl.req_line_num = pr_reqpurch.line_num 
					LET pr_penddetl.part_code = pr_reqpurch.part_code 
					LET pr_penddetl.oem_text = pr_product.oem_text 
					LET pr_penddetl.job_code = NULL 
					LET pr_penddetl.var_code = NULL 
					LET pr_penddetl.activity_code = NULL 
					LET pr_penddetl.desc_text = pr_reqpurch.desc_text 
					LET pr_penddetl.po_qty = (pr_reqpurch.po_qty 
					/ pr_product.stk_sel_con_qty) 
					/ pr_product.pur_stk_con_qty 
					LET pr_penddetl.auth_po_qty = 0 
					SELECT stock_acct_code INTO pr_penddetl.acct_code FROM category 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND cat_code = pr_product.cat_code 
					SELECT acct_mask_code INTO pr_acct_mask_code FROM warehouse 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_purchase.ware_code 
					LET pr_penddetl.acct_code = build_mask(glob_rec_kandoouser.cmpy_code, 
					pr_acct_mask_code, 
					pr_penddetl.acct_code) 
					INSERT INTO penddetl VALUES (pr_penddetl.*) 
					UPDATE reqdetl 
					SET po_qty = po_qty + pr_reqpurch.po_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND line_num = pr_reqpurch.line_num 
					IF pr_reqhead.stock_ind = '0' THEN 
						SELECT unique 1 FROM reqdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND req_num = pr_reqpurch.req_num 
						AND po_qty = 0 
						IF status = notfound THEN 
							LET pr_reqhead.status_ind = '9' 
						ELSE 
							LET pr_reqhead.status_ind = '2' 
						END IF 
						UPDATE reqhead 
						SET status_ind = pr_reqhead.status_ind 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND req_num = pr_reqpurch.req_num 
					END IF 
				END FOREACH 
				IF cnt > 0 THEN 
					LET err_message = " N41 - Insert Pending P.O. Header" 
					INSERT INTO pendhead VALUES (pr_pendhead.*) 
					LET pr_pnd_cnt = pr_pnd_cnt + 1 
					LET pr_last_pnnum = pr_pendhead.pend_num 
					LET glob_rec_reqparms.next_pend_po_num = glob_rec_reqparms.next_pend_po_num 
					+ 1 
				END IF 
			ELSE 
				IF pr_puparms.cmpy_code IS NULL THEN 
					DECLARE c_puparms CURSOR FOR 
					SELECT * FROM puparms 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND key_code = "1" 
					FOR UPDATE 
					OPEN c_puparms 
					FETCH c_puparms INTO pr_puparms.* 
					LET pr_first_ponum = pr_puparms.next_po_num 
				END IF 
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
					 
				LET pr_purchhead.due_date = today 
				LET pr_purchhead.cancel_date = NULL 
				LET pr_purchhead.status_ind = "O" 
				LET pr_purchhead.printed_flag = "N" 
				LET pr_purchhead.authorise_code = glob_rec_kandoouser.sign_on_code 
				LET pr_purchhead.retention_code = NULL 
				LET pr_purchhead.retention_amt = NULL 
				LET pr_purchhead.del_name_text = pr_warehouse.desc_text 
				LET pr_purchhead.del_addr1_text = pr_warehouse.addr1_text 
				LET pr_purchhead.del_addr2_text = pr_warehouse.addr2_text 
				LET pr_purchhead.del_addr3_text = pr_warehouse.city_text 
				LET pr_purchhead.del_addr4_text = pr_warehouse.state_code, pr_warehouse.post_code 
				LET pr_purchhead.contact_text = pr_warehouse.contact_text 
				LET pr_purchhead.tele_text = pr_warehouse.tele_text 
				LET pr_purchhead.var_num = 0 
				LET pr_purchhead.note_code = NULL 
				
				SELECT country_text INTO pr_purchhead.del_country_code 
				FROM country 
				WHERE country_code = pr_warehouse.country_code 
				LET pr_purchhead.type_ind = pr_puparms.post_method_ind 
				LET pr_purchhead.confirm_ind = "N" 
				LET pr_purchhead.confirm_date = NULL 
				LET pr_purchhead.confirm_text = NULL 
				LET pr_purchhead.com1_text = 
				"Automatic Generation FROM Requisition" 
				LET pr_purchhead.com2_text = NULL 
				LET pr_purchhead.purchtype_code = pr_vendor.purchtype_code 
				DECLARE c2_reqpurch CURSOR FOR 
				SELECT * FROM reqpurch 
				WHERE vend_code = pr_purchase.vend_code 
				AND ware_code = pr_purchase.ware_code 
				AND replenish_ind = 'P' 
				ORDER BY req_num, line_num 
				LET cnt = 0 
				FOREACH c2_reqpurch INTO pr_reqpurch.* 
					SELECT * INTO pr_reqhead.* FROM reqhead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					SELECT * INTO pr_product.* FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_reqpurch.part_code 
					SELECT * INTO pr_reqdetl.* FROM reqdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND line_num = pr_reqpurch.line_num 
					IF ((pr_reqdetl.po_qty + pr_reqpurch.po_qty) 
					> pr_reqdetl.req_qty) THEN 
						LET l_kandoo_log_msg = "Requisition line ", 
						pr_reqdetl.line_num USING "<<<<" clipped," ", 
						"Requisition number ", 
						pr_reqdetl.req_num USING "<<<<<<<<" clipped, 
						" Approval failed." 
						CALL errorlog(l_kandoo_log_msg) 
						LET pr_err_cnt = pr_err_cnt + 1 
						CONTINUE FOREACH 
					END IF 
					LET cnt = cnt + 1 
					SELECT unit_cost_amt INTO pr_poaudit.unit_cost_amt FROM reqdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND line_num = pr_reqpurch.line_num 
					LET pr_poaudit.unit_cost_amt = (pr_poaudit.unit_cost_amt 
					* pr_product.stk_sel_con_qty) 
					* pr_product.pur_stk_con_qty 
					LET pr_purchdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pr_purchdetl.vend_code = pr_purchhead.vend_code 
					LET pr_purchdetl.order_num = pr_purchhead.order_num 
					LET pr_purchdetl.line_num = cnt 
					LET pr_purchdetl.seq_num = 1 
					LET pr_purchdetl.type_ind = "I" 
					LET pr_purchdetl.ref_text = pr_reqpurch.part_code 
					LET pr_purchdetl.req_num = pr_reqpurch.req_num 
					LET pr_purchdetl.req_line_num = pr_reqpurch.line_num 
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
					LET pr_poaudit.order_qty = (pr_reqpurch.po_qty 
					/ pr_product.stk_sel_con_qty) 
					/ pr_product.pur_stk_con_qty 
					LET pr_poaudit.received_qty = 0 
					LET pr_poaudit.voucher_qty = 0 
					LET pr_poaudit.desc_text = pr_reqpurch.desc_text 
					LET pr_poaudit.ext_cost_amt = pr_poaudit.order_qty 
					* pr_poaudit.unit_cost_amt 
					LET pr_poaudit.unit_tax_amt = pr_poaudit.unit_cost_amt 
					* pr_tax.tax_per 
					LET pr_poaudit.ext_tax_amt = pr_poaudit.order_qty 
					* pr_poaudit.unit_tax_amt 
					# Can't calculate by adding extended amounts as definitions do NOT
					# match - ext_cost_amt IS dec(16,4).
					#              LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt
					#                                            + pr_poaudit.ext_tax_amt
					LET pr_poaudit.line_total_amt = pr_poaudit.order_qty * 
					(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt) 
					LET pr_poaudit.jour_num = 0 
					LET pr_poaudit.posted_flag = "N" 
					LET pr_poaudit.year_num = pr_purchhead.year_num 
					LET pr_poaudit.period_num = pr_purchhead.period_num 
					INSERT INTO poaudit VALUES (pr_poaudit.*) 
					DECLARE c_prodstatus CURSOR FOR 
					SELECT * FROM prodstatus 
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
						+ (pr_poaudit.order_qty 
						* pr_product.pur_stk_con_qty 
						* pr_product.stk_sel_con_qty) 
					END IF 
					UPDATE prodstatus 
					SET onord_qty = pr_prodstatus.onord_qty, 
					seq_num = pr_prodstatus.seq_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = pr_prodstatus.part_code 
					AND ware_code = pr_prodstatus.ware_code 
					UPDATE reqdetl 
					SET po_qty = po_qty + pr_reqpurch.po_qty, 
					trans_num = pr_purchdetl.order_num, 
					trans_line_num = pr_purchdetl.line_num 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND line_num = pr_reqpurch.line_num 
					IF pr_reqhead.stock_ind = '0' THEN 
						SELECT unique 1 FROM reqdetl 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND req_num = pr_reqpurch.req_num 
						AND po_qty = 0 
						IF status = notfound THEN 
							LET pr_reqhead.status_ind = '9' 
						ELSE 
							LET pr_reqhead.status_ind = '2' 
						END IF 
						UPDATE reqhead 
						SET status_ind = pr_reqhead.status_ind 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND req_num = pr_reqpurch.req_num 
					END IF 
				END FOREACH 
				IF cnt > 0 THEN 
					LET err_message = " N41 - Insert Purchase Order Header" 
					LET pr_purchhead.rev_num = 1 
					LET pr_purchhead.rev_date = today 
					INSERT INTO purchhead VALUES (pr_purchhead.*) 
					CALL po_head_info(glob_rec_kandoouser.cmpy_code, pr_purchhead.order_num) 
					RETURNING pr_onord_amt, 
					pr_received_tot, 
					pr_voucher_tot, 
					pr_tax_tot 
					UPDATE vendor 
					SET onorder_amt = onorder_amt + pr_onord_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code = pr_purchhead.vend_code 
					LET pr_po_cnt = pr_po_cnt + 1 
					LET pr_last_ponum = pr_purchhead.order_num 
					LET pr_puparms.next_po_num = pr_puparms.next_po_num + 1 
				END IF 
			END IF 
		END FOREACH 
		IF glob_rec_reqparms.cmpy_code IS NOT NULL THEN 
			UPDATE reqparms 
			SET next_pend_po_num = glob_rec_reqparms.next_pend_po_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		END IF 
		IF pr_puparms.cmpy_code IS NOT NULL THEN 
			UPDATE puparms 
			SET next_po_num = pr_puparms.next_po_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
		END IF 
		### Insert Stock Transfer Records
		DECLARE c4_reqpurch CURSOR FOR 
		SELECT vend_code, 
		ware_code, 
		sum(po_qty * unit_sales_amt) 
		FROM reqpurch 
		WHERE replenish_ind = 'S' 
		GROUP BY vend_code,ware_code 
		LET pr_inparms.cmpy_code = NULL 
		FOREACH c4_reqpurch INTO pr_purchase.* 
			IF pr_inparms.cmpy_code IS NULL THEN 
				DECLARE c_inparms CURSOR FOR 
				SELECT * FROM inparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				FOR UPDATE 
				OPEN c_inparms 
				FETCH c_inparms INTO pr_inparms.* 
				LET pr_first_trfnum = pr_inparms.next_trans_num 
			END IF 
			INITIALIZE pr_ibthead.* TO NULL 
			LET pr_ibthead.trans_num = pr_inparms.next_trans_num 
			LET pr_ibthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_ibthead.to_ware_code = pr_purchase.ware_code 
			LET pr_ibthead.from_ware_code = pr_purchase.vend_code 
			LET pr_ibthead.trans_date = today 
			LET pr_ibthead.year_num = pr_period.year_num 
			LET pr_ibthead.period_num = pr_period.period_num 
			LET pr_ibthead.sched_ind = "1" 
			INITIALIZE pr_warehouse.* TO NULL 
			INITIALIZE pr_suburb.* TO NULL 
			INITIALIZE pr_supply.* TO NULL 
			SELECT * INTO pr_warehouse.* FROM warehouse 
			WHERE ware_code = pr_ibthead.to_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DECLARE c_sub CURSOR FOR 
			SELECT * FROM suburb 
			WHERE suburb_text = pr_warehouse.city_text 
			AND state_code = pr_warehouse.state_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			OPEN c_sub 
			FETCH c_sub INTO pr_suburb.* 
			CLOSE c_sub 
			SELECT * INTO pr_supply.* FROM supply 
			WHERE suburb_code = pr_suburb.suburb_code 
			AND ware_code = pr_ibthead.from_ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_ibthead.km_qty = pr_supply.km_qty 
			LET pr_ibthead.cart_area_code = pr_warehouse.cart_area_code 
			LET pr_ibthead.entry_date = today 
			LET pr_ibthead.entry_code = glob_rec_kandoouser.sign_on_code 
			LET pr_ibthead.rev_num = 1 
			LET pr_ibthead.del_num = 0 
			LET pr_ibthead.amend_date = NULL 
			LET pr_ibthead.status_ind = IBTHEAD_STATUS_IND_TRANSFER_UNDELIVERED_U 
			DECLARE c2_ibtdetl CURSOR FOR 
			SELECT * FROM reqpurch 
			WHERE vend_code = pr_purchase.vend_code 
			AND ware_code = pr_purchase.ware_code 
			AND replenish_ind = 'S' 
			ORDER BY line_num 
			LET pr_line_num = 0 
			FOREACH c2_ibtdetl INTO pr_reqpurch.* 
				SELECT * INTO pr_reqhead.* FROM reqhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqpurch.req_num 
				SELECT stk_sel_con_qty INTO pr_stk_sel_con_qty FROM product 
				WHERE part_code = pr_reqpurch.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				SELECT * INTO pr_reqdetl.* FROM reqdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqpurch.req_num 
				AND line_num = pr_reqpurch.line_num 
				IF ((pr_reqdetl.po_qty + pr_reqpurch.po_qty) 
				> pr_reqdetl.req_qty) THEN 
					LET l_kandoo_log_msg = "Requisition line ", 
					pr_reqdetl.line_num USING "<<<<" clipped," ", 
					"Requisition number ", 
					pr_reqdetl.req_num USING "<<<<<<<<" clipped, 
					" Approval failed." 
					CALL errorlog(l_kandoo_log_msg) 
					LET pr_err_cnt = pr_err_cnt + 1 
					CONTINUE FOREACH 
				END IF 
				LET pr_line_num = pr_line_num + 1 
				LET pr_ibtdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_ibtdetl.trans_num = pr_ibthead.trans_num 
				LET pr_ibtdetl.line_num = pr_line_num 
				LET pr_ibtdetl.part_code = pr_reqpurch.part_code 
				LET pr_ibtdetl.req_num = pr_reqpurch.req_num 
				LET pr_ibtdetl.req_line_num = pr_reqpurch.line_num 
				LET pr_ibtdetl.status_ind = IBTDETL_STATUS_IND_NEW_0 
				LET pr_ibtdetl.sched_qty = 0 
				LET pr_ibtdetl.picked_qty = 0 
				LET pr_ibtdetl.rec_qty = 0 
				LET pr_ibtdetl.conf_qty = 0 
				LET pr_ibtdetl.trf_qty = pr_reqpurch.po_qty 
				LET pr_ibtdetl.back_qty = pr_reqpurch.po_qty 
				INSERT INTO ibtdetl VALUES (pr_ibtdetl.*) 
				UPDATE prodstatus 
				SET back_qty = back_qty + pr_ibtdetl.back_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_ibthead.from_ware_code 
				AND part_code = pr_ibtdetl.part_code 
				UPDATE reqdetl 
				SET po_qty = po_qty + pr_reqpurch.po_qty, 
				trans_num = pr_ibtdetl.trans_num, 
				trans_line_num = pr_ibtdetl.line_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND req_num = pr_reqpurch.req_num 
				AND line_num = pr_reqpurch.line_num 
				IF pr_reqhead.stock_ind = '0' THEN 
					SELECT unique 1 FROM reqdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
					AND po_qty = 0 
					IF status = notfound THEN 
						LET pr_reqhead.status_ind = '9' 
					ELSE 
						LET pr_reqhead.status_ind = '2' 
					END IF 
					UPDATE reqhead 
					SET status_ind = pr_reqhead.status_ind 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND req_num = pr_reqpurch.req_num 
				END IF 
			END FOREACH 
			IF pr_line_num > 0 THEN 
				LET err_message = " N41f - Adding Order Header Row" 
				INSERT INTO ibthead VALUES (pr_ibthead.*) 
				LET pr_trf_cnt = pr_trf_cnt + 1 
				LET pr_last_trfnum = pr_ibthead.trans_num 
				LET pr_inparms.next_trans_num = pr_inparms.next_trans_num + 1 
			END IF 
		END FOREACH 
		IF pr_inparms.cmpy_code IS NOT NULL THEN 
			UPDATE inparms 
			SET next_trans_num = pr_inparms.next_trans_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN pr_po_cnt, 
	pr_pnd_cnt, 
	pr_trf_cnt, 
	pr_first_ponum, 
	pr_last_ponum, 
	pr_first_pnnum, 
	pr_last_pnnum, 
	pr_first_trfnum, 
	pr_last_trfnum, 
	pr_err_cnt 
END FUNCTION 
