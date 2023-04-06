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

	Source code beautified by beautify.pl on 2020-01-02 17:06:15	Source code beautified by beautify.pl on 2020-01-02 17:03:25	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "R_PU_GLOBALS.4gl" 
GLOBALS "R21_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - R11d (R21d !!!)
# Purpose - This FUNCTION adds the goods receipts details


DEFINE 
sum_tax, sum_goods, sum_total money(12,2), 
left_onord DECIMAL(15,3), 
pr_ytd_amt LIKE vendor.ytd_amt 

FUNCTION write_receipt() 
	DEFINE 
	pr_err_cnt,i, idx SMALLINT, 
	pr_jobledger RECORD LIKE jobledger.*, 
	pf_purchdetl RECORD LIKE purchdetl.*, 
	pf_poaudit RECORD LIKE poaudit.*, 
	cu_poaudit RECORD LIKE poaudit.*, 
	cx_poaudit RECORD LIKE poaudit.*, 
	pr_activity RECORD LIKE activity.*, 
	err_message CHAR(40), 
	l_kandoo_log_msg CHAR(200), 
	pr_err_stat, row_id INTEGER, 
	pr_old_onorder_amt LIKE vendor.onorder_amt, 
	pr_new_onorder_amt LIKE vendor.onorder_amt, 
	pr_shipment_line SMALLINT 

	LET sum_tax = 0 
	LET sum_goods = 0 
	LET sum_total = 0 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET msgresp = kandoomsg("U",1005,"") 
		#1005 Updating database; Please wait.
		LET err_message = "R21d - Update Purchasing Parameters" 
		DECLARE c_puparms CURSOR FOR 
		SELECT * FROM puparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_puparms 
		FETCH c_puparms INTO pr_puparms.* 
		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = pr_purchhead.vend_code 
		FOR UPDATE 
		OPEN c_vendor 
		FETCH c_vendor INTO pr_vendor.* 
		LET pr_poaudit.tran_num = pr_puparms.next_receipt_num 
		LET pr_ytd_amt = 0 
		DECLARE c5_purchdetl CURSOR FOR 
		SELECT * FROM t_purchdetl 
		ORDER BY line_num 
		LET pr_old_onorder_amt = 0 
		LET pr_new_onorder_amt = 0 
		LET pr_err_cnt = 0 
		FOREACH c5_purchdetl INTO pf_purchdetl.* 
			LET err_message = "R21d - receipt line addition failed" 
			SELECT * INTO pr_purchdetl.* FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_purchhead.order_num 
			AND line_num = pf_purchdetl.line_num 
			IF status = notfound THEN 
				LET err_message = " Logic Error: Missing PO lIne" 
				GOTO recovery 
			END IF 
			SELECT unique 1 
			FROM shipdetl, shiphead 
			WHERE shipdetl.source_doc_num = pf_purchdetl.order_num 
			AND shipdetl.doc_line_num = pf_purchdetl.line_num 
			AND shipdetl.ship_inv_qty > 0 
			AND shipdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND shipdetl.cmpy_code = shiphead.cmpy_code 
			AND shipdetl.ship_code = shiphead.ship_code 
			AND shiphead.finalised_flag <> "Y" 
			IF status = notfound THEN 
				LET pr_shipment_line = false 
			ELSE 
				LET pr_shipment_line = true 
			END IF 
			IF pf_purchdetl.seq_num != pr_purchdetl.seq_num OR 
			pr_shipment_line THEN 
				LET l_kandoo_log_msg = "Purchase line ", 
				pr_purchdetl.line_num USING "<<<<" clipped, 
				" Purchase ORDER number ",pr_purchdetl.order_num USING "<<<<<<<<" clipped, 
				" Receipt failed." 
				CALL errorlog(l_kandoo_log_msg) 
				LET pr_err_cnt = pr_err_cnt + 1 
			ELSE 
				SELECT * INTO pf_poaudit.* FROM t_poaudit 
				WHERE line_num = pf_purchdetl.line_num 
				LET cu_poaudit.* = pf_poaudit.* 
				### Add poaudit IF received qty IS greater than ORDER qty
				LET err_message = "R21d - receipt line addition failed po_line_info" 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				pr_purchdetl.order_num, 
				pr_purchdetl.line_num) 
				RETURNING cu_poaudit.order_qty, 
				cu_poaudit.received_qty, 
				cu_poaudit.voucher_qty, 
				cu_poaudit.unit_cost_amt, 
				cu_poaudit.ext_cost_amt, 
				cu_poaudit.unit_tax_amt, 
				cu_poaudit.ext_tax_amt, 
				cu_poaudit.line_total_amt 
				LET pr_old_onorder_amt = pr_old_onorder_amt 
				+ ((cu_poaudit.order_qty - cu_poaudit.received_qty) 
				* (cu_poaudit.unit_cost_amt + cu_poaudit.unit_tax_amt)) 
				IF (pf_poaudit.received_qty + cu_poaudit.received_qty) > 
				pf_poaudit.order_qty THEN 
					LET cu_poaudit.order_qty = pf_poaudit.received_qty 
					+ cu_poaudit.received_qty 
					LET err_message = "R21d - receipt line addition failed mod_po_line" 
					CALL mod_po_line(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, pr_purchhead.*, 
					pr_purchdetl.*, 
					cu_poaudit.*) 
					RETURNING pr_err_stat 
					IF pr_err_stat < 0 THEN 
						GO TO recovery 
					END IF 
				END IF 
				LET err_message = "R21d - receipt line addition failed po_line_info2" 
				CALL po_line_info(glob_rec_kandoouser.cmpy_code, 
				pr_purchdetl.order_num, 
				pr_purchdetl.line_num) 
				RETURNING cx_poaudit.order_qty, 
				cx_poaudit.received_qty, 
				cx_poaudit.voucher_qty, 
				cx_poaudit.unit_cost_amt, 
				cx_poaudit.ext_cost_amt, 
				cx_poaudit.unit_tax_amt, 
				cx_poaudit.ext_tax_amt, 
				cx_poaudit.line_total_amt 
				LET pr_new_onorder_amt = pr_new_onorder_amt 
				+ ((cx_poaudit.order_qty - cx_poaudit.received_qty) 
				* (cx_poaudit.unit_cost_amt + cx_poaudit.unit_tax_amt)) 
				LET pr_poaudit.cmpy_code = pr_purchdetl.cmpy_code 
				LET pr_poaudit.vend_code = pr_purchdetl.vend_code 
				LET pr_poaudit.po_num = pr_purchdetl.order_num 
				LET pr_poaudit.line_num = pr_purchdetl.line_num 
				LET pr_poaudit.tran_code = "GR" 
				LET pr_poaudit.tran_date = save_date 
				LET pr_poaudit.order_qty = 0 
				LET pr_poaudit.voucher_qty = 0 
				LET pr_poaudit.posted_flag = "N" 
				LET pr_poaudit.orig_auth_flag = "Y" 
				LET pr_poaudit.now_auth_flag = "Y" 
				IF pf_poaudit.received_qty IS NULL THEN 
					LET pf_poaudit.received_qty = 0 
				END IF 
				LET pr_poaudit.received_qty = pf_poaudit.received_qty 
				IF pf_poaudit.unit_cost_amt IS NULL THEN 
					LET pf_poaudit.unit_cost_amt = 0 
				END IF 
				LET pr_poaudit.unit_cost_amt = pf_poaudit.unit_cost_amt 
				IF pf_poaudit.unit_tax_amt IS NULL THEN 
					LET pf_poaudit.unit_tax_amt = 0 
				END IF 
				LET pr_poaudit.unit_tax_amt = pf_poaudit.unit_tax_amt 
				LET pr_poaudit.desc_text = pf_poaudit.desc_text 
				LET pr_poaudit.ext_cost_amt = pf_poaudit.unit_cost_amt 
				* pf_poaudit.received_qty 
				LET pr_poaudit.ext_tax_amt = pf_poaudit.unit_tax_amt 
				* pf_poaudit.received_qty 
				LET pr_poaudit.line_total_amt = pr_poaudit.ext_tax_amt 
				+ pr_poaudit.ext_cost_amt 
				LET pr_poaudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_poaudit.entry_date = today 
				LET pr_poaudit.year_num = save_year 
				LET pr_poaudit.period_num = save_period 
				LET pr_poaudit.jour_num = 0 
				LET pr_ytd_amt = pr_ytd_amt + pr_poaudit.line_total_amt 
				# up the sequence number in purchdetl
				DECLARE c_purchdetl CURSOR FOR 
				SELECT rowid,seq_num FROM purchdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_poaudit.po_num 
				AND line_num = pr_poaudit.line_num 
				FOR UPDATE 
				OPEN c_purchdetl 
				FETCH c_purchdetl INTO row_id, pr_poaudit.seq_num 
				LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
				LET err_message = "R21d - receipt line UPDATE purchdetl failed " 
				UPDATE purchdetl 
				SET seq_num = pr_poaudit.seq_num 
				WHERE rowid = row_id 
				#  now add the line
				LET err_message = "R21d - receipt line INSERT poaudit failed " 
				INSERT INTO poaudit VALUES (pr_poaudit.*) 
				# now UPDATE the purchhead STATUS TO "P" Partial
				LET pr_purchhead.status_ind = "P" 
				LET err_message = "R21d - receipt line UPDATE purchhead failed " 
				UPDATE purchhead 
				SET status_ind = pr_purchhead.status_ind 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = pr_poaudit.po_num 
				CASE 
					WHEN pr_purchdetl.type_ind = "C" 
						IF pr_poaudit.received_qty != 0 THEN 
							IF NOT write_invent() THEN 
								GOTO recovery 
							END IF 
							DECLARE act_e2 CURSOR FOR 
							SELECT activity.* FROM activity 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND job_code = pr_purchdetl.job_code 
							AND var_code = pr_purchdetl.var_num 
							AND activity_code = pr_purchdetl.activity_code 
							FOR UPDATE 
							OPEN act_e2 
							FETCH act_e2 INTO pr_activity.* 
							LET pr_activity.seq_num = pr_activity.seq_num + 1 
							LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET pr_jobledger.trans_date = pr_poaudit.tran_date 
							LET pr_jobledger.year_num = save_year 
							LET pr_jobledger.period_num = save_period 
							LET pr_jobledger.job_code = pr_purchdetl.job_code 
							LET pr_jobledger.var_code = pr_purchdetl.var_num 
							LET pr_jobledger.activity_code = pr_purchdetl.activity_code 
							LET pr_jobledger.seq_num = pr_activity.seq_num 
							LET pr_jobledger.trans_type_ind = "PU" 
							LET pr_jobledger.trans_source_num = pr_poaudit.po_num 
							LET pr_jobledger.ref_num = pr_poaudit.tran_num 
							LET pr_jobledger.trans_source_text = pr_purchdetl.res_code 
							LET pr_jobledger.trans_amt = pr_poaudit.ext_cost_amt 
							LET pr_jobledger.trans_qty = pr_poaudit.received_qty 
							LET pr_jobledger.charge_amt = pr_purchdetl.charge_amt 
							* pr_jobledger.trans_qty 
							LET pr_jobledger.posted_flag = "N" 
							LET pr_jobledger.desc_text = pr_poaudit.desc_text 
							LET idx = pr_purchdetl.line_num 
							IF pa_jmresource[idx].allocation_ind IS NULL THEN 
								SELECT allocation_ind INTO pa_jmresource[idx].allocation_ind 
								FROM jmresource 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND res_code = pr_purchdetl.res_code 
							END IF 
							LET pr_jobledger.allocation_ind 
							= pa_jmresource[idx].allocation_ind 
							LET err_message = "R21d- receipt line INSERT jobledger failed" 
							INSERT INTO jobledger VALUES ( pr_jobledger.*) 
							LET err_message = "R21d - receipt line UPDATE activity failed" 
							UPDATE activity 
							SET act_cost_amt = act_cost_amt + pr_poaudit.ext_cost_amt, 
							act_cost_qty = act_cost_qty + pr_poaudit.received_qty, 
							post_revenue_amt = post_revenue_amt 
							+ pr_jobledger.charge_amt, 
							seq_num = pr_activity.seq_num 
							WHERE CURRENT OF act_e2 
						END IF 

					WHEN pr_purchdetl.type_ind = "I" 
						AND pr_poaudit.received_qty != 0 
						IF NOT write_invent() THEN 
							GOTO recovery 
						END IF 

					WHEN pr_purchdetl.type_ind = "J" 
						AND pr_poaudit.received_qty != 0 
						DECLARE act_e CURSOR FOR 
						SELECT activity.* FROM activity 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND job_code = pr_purchdetl.job_code 
						AND var_code = pr_purchdetl.var_num 
						AND activity_code = pr_purchdetl.activity_code 
						FOR UPDATE 
						OPEN act_e 
						FETCH act_e INTO pr_activity.* 
						LET pr_activity.seq_num = pr_activity.seq_num + 1 
						LET pr_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pr_jobledger.trans_date = pr_poaudit.tran_date 
						LET pr_jobledger.year_num = save_year 
						LET pr_jobledger.period_num = save_period 
						LET pr_jobledger.job_code = pr_purchdetl.job_code 
						LET pr_jobledger.var_code = pr_purchdetl.var_num 
						LET pr_jobledger.activity_code = pr_purchdetl.activity_code 
						LET pr_jobledger.seq_num = pr_activity.seq_num 
						LET pr_jobledger.trans_type_ind = "PU" 
						LET pr_jobledger.trans_source_num = pr_poaudit.po_num 
						LET pr_jobledger.ref_num = pr_poaudit.tran_num 

						LET pr_jobledger.trans_source_text = pr_purchdetl.res_code 
						LET pr_jobledger.trans_amt = pr_poaudit.ext_cost_amt 
						LET pr_jobledger.trans_qty = pr_poaudit.received_qty 
						LET pr_jobledger.charge_amt = pr_purchdetl.charge_amt 
						* pr_jobledger.trans_qty 
						LET pr_jobledger.posted_flag = "N" 
						LET pr_jobledger.desc_text = pr_poaudit.desc_text 
						LET idx = pr_purchdetl.line_num 
						IF pa_jmresource[idx].allocation_ind IS NULL THEN 
							SELECT allocation_ind INTO pa_jmresource[idx].allocation_ind 
							FROM jmresource 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND res_code = pr_purchdetl.res_code 

						END IF 
						LET pr_jobledger.allocation_ind 
						= pa_jmresource[idx].allocation_ind 
						LET err_message = "R21d - receipt line INSERT jobledger failed " 
						INSERT INTO jobledger VALUES ( pr_jobledger.*) 
						LET err_message = "R21d - receipt line UPDATE activity failed " 
						UPDATE activity 
						SET act_cost_amt = act_cost_amt + pr_poaudit.ext_cost_amt, 
						act_cost_qty = act_cost_qty + pr_poaudit.received_qty, 
						post_revenue_amt = post_revenue_amt 
						+ pr_jobledger.charge_amt, 
						seq_num = pr_activity.seq_num 
						WHERE CURRENT OF act_e 
				END CASE 
			END IF 
		END FOREACH 
		LET status = serial_return('', 'X') 
		LET err_message = "R21d Updating Vendor" 
		LET pr_new_onorder_amt = pr_new_onorder_amt - pr_old_onorder_amt 
		UPDATE vendor 
		SET ytd_amt = ytd_amt + pr_ytd_amt, 
		onorder_amt = onorder_amt + pr_new_onorder_amt 
		WHERE cmpy_code = pr_purchhead.cmpy_code 
		AND vend_code = pr_purchhead.vend_code 
		UPDATE puparms 
		SET next_receipt_num = pr_puparms.next_receipt_num +1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
	COMMIT WORK 
	WHENEVER ERROR stop 
	FOR idx = 1 TO arr_count() 
		LET pa_jmresource[idx].allocation_ind = NULL 
	END FOR 
	RETURN pr_err_cnt 
END FUNCTION 


FUNCTION write_invent() 
	DEFINE 
	pr_product RECORD LIKE product.*, 
	pr_prodledg RECORD LIKE prodledg.*, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_wsale_tax LIKE prodstatus.purch_tax_amt, 
	pr_save_qty FLOAT 


	WHENEVER ERROR GOTO recovery 
	SELECT * INTO pr_product.* FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_purchdetl.ref_text 

	IF pr_product.serial_flag = "Y" THEN 
		LET err_message = "R21d - serial_update " 
		LET pr_serialinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_serialinfo.part_code = pr_product.part_code 
		LET pr_serialinfo.ware_code = pr_purchhead.ware_code 
		LET pr_serialinfo.po_num = pr_poaudit.po_num 
		LET pr_serialinfo.receipt_date = pr_poaudit.tran_date 
		LET pr_serialinfo.receipt_num = pr_poaudit.tran_num 
		LET pr_serialinfo.vend_code = pr_purchhead.vend_code 
		LET pr_serialinfo.trantype_ind = "0" 
		LET status = serial_update(pr_serialinfo.*, 1, "") 
		IF status <> 0 THEN 
			LET err_message = "R21d - write_invent serial_update error" 
			GOTO recovery 
			EXIT program 
		END IF 
	END IF 

	IF pr_poaudit.received_qty = 0 THEN 
		RETURN true 
	END IF 

	DECLARE c_prodstatus CURSOR FOR 
	SELECT * FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_product.part_code 
	AND ware_code = pr_purchhead.ware_code 
	FOR UPDATE 
	OPEN c_prodstatus 
	FETCH c_prodstatus INTO pr_prodstatus.* 
	IF status = notfound THEN 
		CLOSE c_prodstatus 
		LET err_message = "R21d - write_invent prodstatus RECORD dosn't exist" 
		RETURN false 
	END IF 
	LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
	LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_prodledg.part_code = pr_prodstatus.part_code 
	LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
	LET pr_prodledg.tran_date = pr_poaudit.tran_date 
	LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
	LET pr_prodledg.trantype_ind = "P" 
	LET pr_prodledg.year_num = save_year 
	LET pr_prodledg.period_num = save_period 
	LET pr_prodledg.source_text = pr_purchhead.vend_code 
	LET pr_prodledg.source_num = pr_poaudit.tran_num 
	IF pr_purchdetl.uom_code IS NULL THEN 
		LET err_message = "R21d - Null UOM code on Purchase Order " 
		RETURN false 
	END IF 
	CASE 
		WHEN (pr_purchdetl.uom_code = pr_product.pur_uom_code) 
			LET pr_prodledg.tran_qty = pr_poaudit.received_qty 
			* pr_product.pur_stk_con_qty 
			* pr_product.stk_sel_con_qty 
			LET pr_prodledg.cost_amt = 
			(pr_poaudit.unit_cost_amt + pr_poaudit.unit_tax_amt) 
			/pr_product.pur_stk_con_qty/pr_product.stk_sel_con_qty 
		WHEN (pr_purchdetl.uom_code = pr_product.stock_uom_code) 
			LET pr_prodledg.tran_qty = pr_poaudit.received_qty 
			* pr_product.stk_sel_con_qty 
			LET pr_prodledg.cost_amt = 
			(pr_poaudit.unit_cost_amt+pr_poaudit.unit_tax_amt) 
			/pr_product.stk_sel_con_qty 
		WHEN (pr_purchdetl.uom_code = pr_product.sell_uom_code) 
			LET pr_prodledg.tran_qty = pr_poaudit.received_qty 
			LET pr_prodledg.cost_amt = pr_poaudit.unit_cost_amt 
			+ pr_poaudit.unit_tax_amt 
	END CASE 
	LET pr_prodledg.cost_amt = conv_currency(pr_prodledg.cost_amt,glob_rec_kandoouser.cmpy_code, 
	pr_vendor.currency_code,"F", 
	pr_poaudit.tran_date, "B") 
	LET pr_prodstatus.act_cost_amt = pr_prodledg.cost_amt 
	LET pr_prodledg.sales_amt = 0 
	LET pr_prodledg.hist_flag = "N" 
	LET pr_prodledg.post_flag = "N" 
	LET pr_prodledg.jour_num = NULL 
	LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
	+ pr_prodledg.tran_qty 
	LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
	LET pr_prodledg.entry_date = today 
	INSERT INTO prodledg VALUES (pr_prodledg.*) 
	### Now Calculate Prodstatus Values
	IF pr_prodstatus.stocked_flag = "Y" THEN 
		LET pr_wsale_tax = 0 
		IF (pr_prodstatus.onhand_qty+pr_prodledg.tran_qty)<= 0 THEN 
			LET pr_prodstatus.wgted_cost_amt = pr_prodledg.cost_amt 
			LET pr_prodstatus.purch_tax_amt = 0 
		ELSE 
			LET pr_save_qty = pr_prodstatus.onhand_qty 
			IF pr_save_qty < 0 THEN 
				LET pr_save_qty = 0 
			END IF 
			LET pr_prodstatus.wgted_cost_amt = 
			( (pr_prodstatus.wgted_cost_amt * pr_save_qty) 
			+ (pr_prodledg.tran_qty *(pr_prodledg.cost_amt+pr_wsale_tax))) 
			/ (pr_save_qty + pr_prodledg.tran_qty) 
			IF pr_wsale_tax > 0 THEN 
				LET pr_prodstatus.purch_tax_amt = 
				( (pr_prodstatus.purch_tax_amt * pr_save_qty) 
				+ (pr_prodledg.tran_qty * pr_wsale_tax)) 
				/ (pr_save_qty + pr_prodledg.tran_qty) 
				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET pr_prodledg.part_code = pr_prodstatus.part_code 
				LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
				LET pr_prodledg.tran_date = pr_poaudit.tran_date 
				LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
				LET pr_prodledg.trantype_ind = "W" 
				LET pr_prodledg.year_num = save_year 
				LET pr_prodledg.period_num = save_period 
				LET pr_prodledg.source_text = pr_purchhead.vend_code 
				LET pr_prodledg.source_num = pr_poaudit.tran_num 
				LET pr_prodledg.cost_amt = pr_wsale_tax 
				LET pr_prodledg.sales_amt = 0 
				LET pr_prodledg.hist_flag = "N" 
				LET pr_prodledg.post_flag = "N" 
				LET pr_prodledg.jour_num = NULL 
				LET pr_prodledg.desc_text = "Wholesale Tax Loading" 
				LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
				+ pr_prodledg.tran_qty 
				LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET pr_prodledg.entry_date = today 
				INSERT INTO prodledg VALUES (pr_prodledg.*) 
			END IF 
		END IF 
		LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty 
		+ pr_prodledg.tran_qty 
	ELSE 
		LET pr_prodstatus.onhand_qty = 0 
	END IF 
	LET pr_prodstatus.last_receipt_date = pr_prodledg.tran_date 
	IF pr_prodstatus.wgted_cost_amt IS NULL THEN 
		LET pr_prodstatus.wgted_cost_amt = 0 
	END IF 
	IF pr_prodstatus.act_cost_amt IS NULL THEN 
		LET pr_prodstatus.act_cost_amt = 0 
	END IF 
	IF pr_prodstatus.wgted_cost_amt < 0 THEN 
		LET pr_prodstatus.wgted_cost_amt = pr_prodledg.cost_amt 
	END IF 
	LET pr_prodstatus.last_cost_date = pr_prodledg.tran_date 
	# save foreign cost as well IF required
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"SC") = "0" THEN 
		LET pr_prodstatus.for_cost_amt = ((pr_poaudit.unit_cost_amt 
		/pr_product.pur_stk_con_qty) 
		/pr_product.stk_sel_con_qty) 
		LET pr_prodstatus.for_curr_code = pr_vendor.currency_code 
	END IF 
	LET pr_prodstatus.onord_qty = pr_prodstatus.onord_qty 
	- pr_prodledg.tran_qty 
	UPDATE prodstatus 
	SET seq_num=pr_prodstatus.seq_num, 
	onhand_qty=pr_prodstatus.onhand_qty, 
	onord_qty=pr_prodstatus.onord_qty, 
	wgted_cost_amt=pr_prodstatus.wgted_cost_amt, 
	purch_tax_amt=pr_prodstatus.purch_tax_amt, 
	last_receipt_date=pr_prodstatus.last_receipt_date, 
	last_cost_date=pr_prodstatus.last_cost_date, 
	act_cost_amt=pr_prodstatus.act_cost_amt, 
	for_cost_amt=pr_prodstatus.for_cost_amt, 
	for_curr_code=pr_prodstatus.for_curr_code 
	WHERE part_code = pr_prodstatus.part_code 
	AND ware_code = pr_prodstatus.ware_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	CLOSE c_prodstatus 
	RETURN true 
	LABEL recovery: RETURN false 
	WHENEVER ERROR stop 
END FUNCTION 
