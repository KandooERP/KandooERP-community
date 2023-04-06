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
GLOBALS "../lc/L_LC_GLOBALS.4gl"
GLOBALS "../lc/LS_GROUP_GLOBALS.4gl" 
GLOBALS "../lc/LS1_GLOBALS.4gl" 
# \brief module LS1c - Posts entries TO prodledg & GL via jourintf AND updates prodstatus & product

#GLOBALS "LS1.4gl" 

DEFINE bal_rec RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	ref_num LIKE batchdetl.ref_num 
END RECORD 
DEFINE pr_shipdetl RECORD LIKE shipdetl.* 
DEFINE pr_prodhist RECORD LIKE prodhist.* 
DEFINE pr_prodledg RECORD LIKE prodledg.* 
DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
DEFINE pr_poaudit RECORD LIKE poaudit.* 
DEFINE pr_purchdetl RECORD LIKE purchdetl.* 
DEFINE pr_jobledger RECORD LIKE jobledger.* 
DEFINE pr_activity RECORD LIKE activity.* 
DEFINE verif, do_update, doit  CHAR(1) --print_option
DEFINE passed_desc LIKE batchdetl.desc_text 
DEFINE pos_qty, tran_qty DECIMAL(10,3) 
DEFINE curr_code LIKE currency.currency_code 
DEFINE tran_ind CHAR(3) 
DEFINE save_1, disc_totaller, totaller money(12,2) 
DEFINE where_part, sel_text STRING 
DEFINE its_ok, cnt INTEGER 
DEFINE mess CHAR(80) 



FUNCTION summary() 
	LET err_message = " Summary Posting information " 
	# get the sum, add back in as ref_num = -1 AND ref_text = zzzcczzzc
	# THEN delete out the original

	DECLARE ps_curs CURSOR FOR 
	SELECT acct_code, tran_type_ind, sum(debit_amt - credit_amt), 
	sum(base_debit_amt - base_credit_amt) 
	INTO pr_data.acct_code, pr_data.tran_type_ind, pr_data.debit_amt, 
	pr_data.base_debit_amt 
	FROM posttemp 
	GROUP BY acct_code, tran_type_ind 

	FOREACH ps_curs 
		LET pr_data.ref_num = -1 
		LET pr_data.ref_text = "zzzcczzc" 
		LET pr_data.desc_text = passed_desc 
		LET pr_data.credit_amt = 0 
		IF pr_data.debit_amt < 0 THEN 
			LET pr_data.credit_amt = 0 - pr_data.debit_amt 
			LET pr_data.debit_amt = 0 
		END IF 
		IF pr_data.base_debit_amt < 0 THEN 
			LET pr_data.base_credit_amt = 0 - pr_data.base_debit_amt 
			LET pr_data.base_debit_amt = 0 
		END IF 
		INSERT INTO posttemp VALUES (pr_data.*) 
	END FOREACH 
	# now delete off detail
	DELETE FROM posttemp 
	WHERE (ref_num != -1 OR ref_num IS null) 
	AND ref_text != "zzzcczzc" 
	#now UPDATE ref_num AND ref_text on those summary left
	UPDATE posttemp 
	SET ref_num = 0, 
	ref_text = "Summary" 
END FUNCTION 

FUNCTION inv_line(p_cmpy, net_fob_amt, duty_amt, other_amt, final_date, pr_period_num, pr_year_num,pr_uom_code) 
	DEFINE 
	p_cmpy LIKE shiphead.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	net_fob_amt LIKE shiphead.fob_inv_cost_amt, 
	duty_amt LIKE shiphead.duty_inv_amt, 
	other_amt LIKE shiphead.other_inv_amt, 
	final_date DATE, 
	pr_period_num LIKE prodledg.period_num, 
	pr_year_num LIKE prodledg.year_num, 
	pr_uom_code LIKE purchdetl.uom_code 
	# pr_shipdetl IS global AND SET up in calling FUNCTION

	DECLARE prodh_curs CURSOR FOR 
	SELECT * INTO pr_product.* FROM product 
	WHERE product.cmpy_code = p_cmpy 
	AND product.part_code = pr_shipdetl.part_code 
	FOR UPDATE 
	OPEN prodh_curs 
	FETCH prodh_curs 
	IF status = notfound THEN 
		CALL errorlog ("LS1c - Product missing on live shipment") 
		ERROR "Product missing " 
		SLEEP 3 
		ROLLBACK WORK 
		EXIT program 
	END IF 
	LET err_message = "LS1c - Product UPDATE" 
	UPDATE product 
	SET tariff_code = pr_shipdetl.tariff_code 
	WHERE product.cmpy_code = p_cmpy 
	AND product.part_code = pr_shipdetl.part_code 
	LET err_message = "LS1c - Category SELECT" 
	SELECT * INTO pr_category.* FROM category 
	WHERE category.cmpy_code = p_cmpy 
	AND category.cat_code = pr_product.cat_code 
	IF status = notfound THEN 
		CALL errorlog("LS1c - Product category missing") 
		ERROR "Product category missing" 
		SLEEP 3 
		EXIT program 
	END IF 
	LET err_message = "LS1c - Prodstatus SELECT" 
	DECLARE prods_curs CURSOR FOR 
	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE prodstatus.cmpy_code = p_cmpy 
	AND prodstatus.part_code = pr_shipdetl.part_code 
	AND prodstatus.ware_code = pr_shiphead.ware_code 
	FOR UPDATE 
	LET idx = 0 
	FOREACH prods_curs 
		LET idx = idx + 1 
		IF pr_prodstatus.wgted_cost_amt IS NULL THEN 
			LET pr_prodstatus.wgted_cost_amt = 0 
		END IF 
		IF pr_prodstatus.onhand_qty IS NULL THEN 
			LET pr_prodstatus.onhand_qty = 0 
		END IF 

		IF pr_uom_code IS NULL THEN 
			LET pr_uom_code = pr_product.sell_uom_code 
		END IF 
		CASE 
			WHEN (pr_uom_code = pr_product.pur_uom_code) 
				LET pr_prodledg.tran_qty = pr_shipdetl.ship_rec_qty 
				* pr_product.pur_stk_con_qty 
				* pr_product.stk_sel_con_qty 
				LET pr_prodledg.cost_amt = 
				(pr_shipdetl.landed_cost) 
				/pr_product.pur_stk_con_qty/pr_product.stk_sel_con_qty 
			WHEN (pr_uom_code = pr_product.stock_uom_code) 
				LET pr_prodledg.tran_qty = pr_shipdetl.ship_rec_qty 
				* pr_product.stk_sel_con_qty 
				LET pr_prodledg.cost_amt = 
				(pr_shipdetl.landed_cost) 
				/pr_product.stk_sel_con_qty 
			OTHERWISE #(pr_uom_code = pr_product.sell_uom_code) 
				LET pr_prodledg.tran_qty = pr_shipdetl.ship_rec_qty 
				LET pr_prodledg.cost_amt = pr_shipdetl.landed_cost 
		END CASE 

		IF (pr_prodstatus.onhand_qty + pr_prodledg.tran_qty) = 0 THEN 
			LET pr_prodstatus.wgted_cost_amt = pr_shipdetl.landed_cost 
		ELSE 
			LET pr_prodstatus.wgted_cost_amt = 
			((pr_prodstatus.wgted_cost_amt * pr_prodstatus.onhand_qty) + 
			(pr_shipdetl.landed_cost * pr_prodledg.tran_qty)) / 
			(pr_prodstatus.onhand_qty + pr_prodledg.tran_qty) 
		END IF 
		LET pr_prodstatus.act_cost_amt = pr_shipdetl.landed_cost 
		LET pr_prodstatus.for_cost_amt = pr_shipdetl.fob_unit_ent_amt 
		LET pr_prodstatus.for_curr_code = pr_shiphead.curr_code 
		LET pr_prodstatus.onhand_qty = pr_prodstatus.onhand_qty + 
		pr_prodledg.tran_qty 
		LET pr_prodstatus.onord_qty = pr_prodstatus.onord_qty - 
		pr_prodledg.tran_qty 
		LET pr_prodstatus.last_receipt_date = final_date 
		LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
		LET err_message = "LS1c - Prodstatus UPDATE" 
		UPDATE prodstatus 
		#SET * = pr_prodstatus.*
		SET wgted_cost_amt = pr_prodstatus.wgted_cost_amt, 
		seq_num = pr_prodstatus.seq_num, 
		last_receipt_date = pr_prodstatus.last_receipt_date, 
		onord_qty = pr_prodstatus.onord_qty, 
		onhand_qty = pr_prodstatus.onhand_qty, 
		for_curr_code = pr_prodstatus.for_curr_code, 
		for_cost_amt = pr_prodstatus.for_cost_amt, 
		act_cost_amt = pr_prodstatus.act_cost_amt 
		WHERE prodstatus.cmpy_code = p_cmpy 
		AND prodstatus.part_code = pr_shipdetl.part_code 
		AND prodstatus.ware_code = pr_shiphead.ware_code 
	END FOREACH 
	IF idx = 0 THEN # no prodstatus found 
		ERROR "Product NOT found AT warehouse. Finalise stopped" 
		SLEEP 3 
		ROLLBACK WORK 
		EXIT program 
	END IF 
	LET pr_prodledg.cmpy_code = p_cmpy 
	LET pr_prodledg.part_code = pr_shipdetl.part_code 
	LET pr_prodledg.ware_code = pr_shiphead.ware_code 
	LET pr_prodledg.tran_date = final_date 
	LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
	LET pr_prodledg.trantype_ind = "R" 
	LET pr_prodledg.year_num = pr_year_num 
	LET pr_prodledg.period_num = pr_period_num 
	LET pr_prodledg.source_text = "Shipment" 
	LET pr_prodledg.source_num = pr_shiphead.ship_code 
	LET pr_prodledg.cost_amt = pr_shipdetl.landed_cost 
	LET pr_prodledg.sales_amt = 0 
	LET pr_prodledg.post_flag = "N" 
	IF pr_inparms.hist_flag = "Y" THEN 
		LET pr_prodledg.hist_flag = "N" 
	ELSE 
		LET pr_prodledg.hist_flag = "Y" 
	END IF 
	LET pr_prodledg.jour_num = 0 
	LET pr_prodledg.desc_text = "Shipment Finalise" 
	LET pr_prodledg.acct_code = NULL 
	LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
	LET pr_prodledg.entry_date = today 
	LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
	LET err_message = "LS1c - Prodledg Insert" 
	INSERT INTO prodledg VALUES (pr_prodledg.*) 
END FUNCTION 


FUNCTION jm_line(p_cmpy, net_fob_amt, duty_amt, other_amt, 
	final_date, pr_period_num, pr_year_num) 
	DEFINE 
	p_cmpy LIKE shiphead.cmpy_code, 
	net_fob_amt LIKE shiphead.fob_inv_cost_amt, 
	duty_amt LIKE shiphead.duty_inv_amt, 
	other_amt LIKE shiphead.other_inv_amt, 
	pr_period_num LIKE prodledg.period_num, 
	final_date DATE, 
	pr_year_num LIKE prodledg.year_num 

	# OPEN AND lock activity FOR this activity - FOR seq_num's
	DECLARE c_5 CURSOR FOR 
	SELECT * FROM activity 
	WHERE activity.cmpy_code = p_cmpy 
	AND activity.job_code = pr_shipdetl.job_code 
	AND activity.var_code = pr_shipdetl.var_code 
	AND activity.activity_code = pr_shipdetl.activity_code 
	FOR UPDATE 
	OPEN c_5 
	FETCH c_5 INTO pr_activity.* 
	LET pr_activity.seq_num = pr_activity.seq_num + 1 
	IF pr_shipdetl.landed_cost IS NOT NULL THEN 
		LET pr_jobledger.cmpy_code = p_cmpy 
		LET pr_jobledger.trans_date = today 
		LET pr_jobledger.year_num = pr_year_num 
		LET pr_jobledger.period_num = pr_period_num 
		LET pr_jobledger.job_code = pr_shipdetl.job_code 
		LET pr_jobledger.var_code = pr_shipdetl.var_code 
		LET pr_jobledger.seq_num = pr_activity.seq_num 
		LET pr_jobledger.activity_code = pr_shipdetl.activity_code 
		LET pr_jobledger.trans_type_ind = "VO" 
		DECLARE v1_curs CURSOR FOR 
		SELECT vouch_code 
		FROM voucherdist 
		WHERE cmpy_code = p_cmpy 
		AND job_code = pr_shipdetl.ship_code 
		AND type_ind = 'S' 
		OPEN v1_curs 
		FETCH v1_curs INTO pr_jobledger.trans_source_num 
		CLOSE v1_curs 
		SELECT * INTO pr_purchdetl.* 
		FROM purchdetl 
		WHERE cmpy_code = p_cmpy 
		AND order_num = pr_shipdetl.source_doc_num 
		AND line_num = pr_shipdetl.doc_line_num 
		LET pr_jobledger.trans_source_text = pr_purchdetl.ref_text[1,8] 
		LET pr_jobledger.trans_amt = pr_shipdetl.landed_cost 
		* pr_shipdetl.ship_rec_qty 
		LET pr_jobledger.trans_qty = pr_shipdetl.ship_rec_qty 
		LET pr_jobledger.charge_amt = pr_purchdetl.charge_amt 
		USING "&&&&&&&&&&.&&&&" 
		LET pr_jobledger.charge_amt = pr_jobledger.charge_amt 
		* pr_shipdetl.ship_rec_qty 
		# we SET as posted cause we do postings in this program
		# - the above comment IS blatantly untrue - leave FOR
		#              historical interest
		LET pr_jobledger.posted_flag = "N" 
		LET pr_jobledger.desc_text = pr_shipdetl.ship_code USING "&&&&&&&&", 
		" ", pr_shipdetl.desc_text clipped 
		LET err_message = "J27 - Insert INTO Jobledger" 
		INSERT INTO jobledger VALUES (pr_jobledger.*) 
		LET err_message = "J27 - Activity Update" 
		IF pr_jobledger.trans_amt IS NOT NULL THEN 
			LET pr_activity.act_cost_amt = pr_activity.act_cost_amt 
			+ pr_jobledger.trans_amt 
		END IF 
		IF pr_jobledger.trans_qty IS NOT NULL THEN 
			LET pr_activity.act_cost_qty = pr_activity.act_cost_qty 
			+ pr_jobledger.trans_qty 
		END IF 
		IF pr_jobledger.charge_amt IS NOT NULL THEN 
			LET pr_activity.post_revenue_amt = pr_activity.post_revenue_amt 
			+ pr_jobledger.charge_amt 
		END IF 
		UPDATE activity 
		SET (act_cost_amt, act_cost_qty, post_revenue_amt, seq_num) = 
		(pr_activity.act_cost_amt, pr_activity.act_cost_qty, 
		pr_activity.post_revenue_amt, pr_activity.seq_num) 
		WHERE activity.cmpy_code = p_cmpy 
		AND activity.job_code = pr_shipdetl.job_code 
		AND activity.var_code = pr_shipdetl.var_code 
		AND activity.activity_code = pr_shipdetl.activity_code 
	END IF 
END FUNCTION 


FUNCTION po_line(p_cmpy, net_fob_amt, duty_amt, other_amt, 
	final_date, pr_period_num, pr_year_num) 
	DEFINE 
	p_cmpy LIKE shiphead.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	net_fob_amt LIKE shiphead.fob_inv_cost_amt, 
	duty_amt LIKE shiphead.duty_inv_amt, 
	other_amt LIKE shiphead.other_inv_amt, 
	pr_period_num LIKE prodledg.period_num, 
	pr_year_num LIKE prodledg.year_num, 
	pp_poaudit RECORD LIKE poaudit.*, # po state prior TO this trans 
	final_date DATE, 
	row_id INTEGER, 
	pr_stat_flag SMALLINT 

	LET pr_stat_flag = false 
	SELECT * INTO pr_purchdetl.* 
	FROM purchdetl 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_shipdetl.source_doc_num 
	AND line_num = pr_shipdetl.doc_line_num 
	IF status = notfound THEN ELSE 
		LET pr_stat_flag = true 
	END IF 
	CASE 
		WHEN pr_shipdetl.part_code IS NOT NULL 
			CALL inv_line(p_cmpy, net_fob_amt, duty_amt, other_amt, 
			final_date, pr_period_num, pr_year_num, 
			pr_purchdetl.uom_code) 
		WHEN pr_shipdetl.job_code IS NOT NULL 
			CALL jm_line(p_cmpy, net_fob_amt, duty_amt, other_amt, 
			final_date, pr_period_num, pr_year_num) 
	END CASE 
	IF pr_stat_flag THEN 
		# check existing po unit costs. IF different THEN
		# reverse old ones enter new ones.  This IS TO keep
		# this in line with other po functions
		CALL po_line_info(p_cmpy, pr_shipdetl.source_doc_num, 
		pr_shipdetl.doc_line_num) 
		RETURNING pp_poaudit.order_qty, 
		pp_poaudit.received_qty, 
		pp_poaudit.voucher_qty, 
		pp_poaudit.unit_cost_amt, 
		pp_poaudit.ext_cost_amt, 
		pp_poaudit.unit_tax_amt, 
		pp_poaudit.ext_tax_amt, 
		pp_poaudit.line_total_amt 
		IF pp_poaudit.unit_cost_amt != pr_shipdetl.fob_unit_ent_amt THEN 
			CALL modify_po(p_cmpy, pp_poaudit.*, pr_shipdetl.*, 
			pr_year_num, pr_period_num) 
		END IF 
		LET pr_poaudit.cmpy_code = p_cmpy 
		LET pr_poaudit.po_num = pr_shipdetl.source_doc_num 
		LET pr_poaudit.line_num = pr_shipdetl.doc_line_num 
		DECLARE seq_curs CURSOR FOR 
		SELECT rowid, seq_num 
		INTO row_id, pr_poaudit.seq_num 
		FROM purchdetl 
		WHERE cmpy_code = p_cmpy 
		AND order_num = pr_shipdetl.source_doc_num 
		AND line_num = pr_shipdetl.doc_line_num 
		FOR UPDATE 
		FOREACH seq_curs # their should only be 1 
			LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
			UPDATE purchdetl 
			SET seq_num = pr_poaudit.seq_num 
			WHERE rowid = row_id 
		END FOREACH 
		LET pr_poaudit.vend_code = pr_shiphead.vend_code 
		LET pr_poaudit.tran_code = "VO" 
		DECLARE v2_curs CURSOR FOR 
		SELECT vouch_code FROM voucherdist 
		WHERE cmpy_code = p_cmpy 
		AND job_code = pr_shipdetl.ship_code 
		AND type_ind = 'S' 
		OPEN v2_curs 
		FETCH v2_curs INTO pr_poaudit.tran_num 
		LET pr_poaudit.tran_date = today 
		LET pr_poaudit.entry_date = today 
		LET pr_poaudit.entry_code = "Shipment" 
		LET pr_poaudit.orig_auth_flag = "Y" 
		LET pr_poaudit.now_auth_flag = "Y" 
		LET pr_poaudit.order_qty = 0 
		LET pr_poaudit.received_qty = 0 
		LET pr_poaudit.voucher_qty = pr_shipdetl.ship_rec_qty 
		LET pr_poaudit.desc_text = pr_shipdetl.desc_text 
		LET pr_poaudit.unit_cost_amt = pr_shipdetl.fob_unit_ent_amt 
		LET pr_poaudit.ext_cost_amt = pr_shipdetl.fob_unit_ent_amt * 
		pr_shipdetl.ship_rec_qty 
		LET pr_poaudit.unit_tax_amt = 0 
		LET pr_poaudit.ext_tax_amt = 0 
		LET pr_poaudit.line_total_amt = pr_shipdetl.fob_unit_ent_amt * 
		pr_shipdetl.ship_rec_qty 
		LET pr_poaudit.posted_flag = "Y" 
		LET pr_poaudit.jour_num = 0 
		LET pr_poaudit.year_num = pr_year_num 
		LET pr_poaudit.period_num = pr_period_num 
		LET err_message = "LS1 - INSERT poaudit" 
		INSERT INTO poaudit VALUES (pr_poaudit.*) 
	END IF 
END FUNCTION 


FUNCTION modify_po(p_cmpy, pp_poaudit, pr_shipdetl, pr_year_num, 
	pr_period_num) 
	DEFINE 
	p_cmpy LIKE company.cmpy_code, 
	pp_poaudit RECORD LIKE poaudit.*, 
	pr_poaudit RECORD LIKE poaudit.*, 
	pr_shipdetl RECORD LIKE shipdetl.*, 
	row_id INTEGER, 
	pr_year_num LIKE period.year_num, 
	pr_period_num LIKE period.period_num, 
	pr_purchhead RECORD LIKE purchhead.*, 
	pr_purchdetl RECORD LIKE purchdetl.* 

	DECLARE head_curs CURSOR FOR 
	SELECT * FROM purchhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_shipdetl.source_doc_num 
	FOR UPDATE 
	OPEN head_curs 
	FETCH head_curs INTO pr_purchhead.* 
	SELECT * INTO pr_purchdetl.* FROM purchdetl 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_shipdetl.source_doc_num 
	AND line_num = pr_shipdetl.doc_line_num 
	LET pr_poaudit.cmpy_code = p_cmpy 
	LET pr_poaudit.po_num = pr_shipdetl.source_doc_num 
	LET pr_poaudit.line_num = pr_shipdetl.doc_line_num 
	DECLARE seq2_curs CURSOR FOR 
	SELECT rowid, seq_num 
	INTO row_id, pr_poaudit.seq_num 
	FROM purchdetl 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_shipdetl.source_doc_num 
	AND line_num = pr_shipdetl.doc_line_num 
	FOR UPDATE 
	FOREACH seq2_curs # their should only be 1 
		IF pp_poaudit.order_qty > 0 THEN # reverse old INSERT new 
			LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
			LET pr_poaudit.vend_code = pr_shiphead.vend_code 
			LET pr_poaudit.tran_code = "CP" 
			LET pr_poaudit.tran_num = 0 
			LET pr_poaudit.tran_date = today 
			LET pr_poaudit.entry_date = today 
			LET pr_poaudit.entry_code = "Shipment" 
			LET pr_poaudit.orig_auth_flag = "Y" 
			LET pr_poaudit.now_auth_flag = "Y" 
			LET pr_poaudit.order_qty = pp_poaudit.order_qty * -1 
			LET pr_poaudit.received_qty = 0 
			LET pr_poaudit.voucher_qty = 0 
			LET pr_poaudit.desc_text = "Price Change" 
			LET pr_poaudit.unit_cost_amt = pp_poaudit.unit_cost_amt 
			LET pr_poaudit.ext_cost_amt = pp_poaudit.unit_cost_amt * 
			pr_poaudit.order_qty 
			LET pr_poaudit.unit_tax_amt = pp_poaudit.unit_tax_amt 
			LET pr_poaudit.ext_tax_amt = pp_poaudit.unit_tax_amt * 
			pr_poaudit.order_qty 
			LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt + 
			pr_poaudit.ext_tax_amt 
			LET pr_poaudit.posted_flag = "Y" 
			LET pr_poaudit.jour_num = 0 
			LET pr_poaudit.year_num = pr_year_num 
			LET pr_poaudit.period_num = pr_period_num 
			## Temporary fix
			#           LET pr_poaudit.amend_num = pr_purchhead.var_num
			LET err_message = "LS1 - INSERT poaudit rev 1" 
			INSERT INTO poaudit VALUES (pr_poaudit.*) 
			# Now UPDATE the list cost amount FOR purchase detail
			LET pr_purchdetl.list_cost_amt 
			= pr_shipdetl.fob_unit_ent_amt / (1 - (pr_purchdetl.disc_per / 100)) 
			UPDATE purchdetl 
			SET list_cost_amt = pr_purchdetl.list_cost_amt 
			WHERE cmpy_code = p_cmpy 
			AND order_num = pr_shipdetl.source_doc_num 
			AND line_num = pr_shipdetl.doc_line_num 
			# new cost structures
			LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
			LET pr_poaudit.order_qty = pp_poaudit.order_qty 
			LET pr_poaudit.received_qty = 0 
			LET pr_poaudit.voucher_qty = 0 
			LET pr_poaudit.desc_text = "Price Change" 
			LET pr_poaudit.unit_cost_amt = pr_shipdetl.fob_unit_ent_amt 
			LET pr_poaudit.ext_cost_amt = pr_shipdetl.fob_unit_ent_amt 
			* pr_poaudit.order_qty 
			LET pr_poaudit.unit_tax_amt = 0 
			LET pr_poaudit.ext_tax_amt = 0 
			LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt 
			+ pr_poaudit.ext_tax_amt 
			LET err_message = "LS1 - INSERT poaudit rev 2" 
			## Temporary fix
			#           LET pr_poaudit.amend_num = pr_purchhead.var_num
			INSERT INTO poaudit VALUES (pr_poaudit.*) 
		END IF 
		IF pp_poaudit.received_qty > 0 THEN # reverse old INSERT new 
			LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
			LET pr_poaudit.vend_code = pr_shiphead.vend_code 
			LET pr_poaudit.tran_code = "GA" 
			LET pr_poaudit.tran_num = 0 
			LET pr_poaudit.tran_date = today 
			LET pr_poaudit.entry_date = today 
			LET pr_poaudit.entry_code = "Shipment" 
			LET pr_poaudit.orig_auth_flag = "Y" 
			LET pr_poaudit.now_auth_flag = "Y" 
			LET pr_poaudit.order_qty = 0 
			LET pr_poaudit.received_qty = pp_poaudit.received_qty * -1 
			LET pr_poaudit.voucher_qty = 0 
			LET pr_poaudit.desc_text = "Price Change" 
			LET pr_poaudit.unit_cost_amt = pp_poaudit.unit_cost_amt 
			LET pr_poaudit.ext_cost_amt = pp_poaudit.unit_cost_amt * 
			pr_poaudit.received_qty 
			LET pr_poaudit.unit_tax_amt = pp_poaudit.unit_tax_amt 
			LET pr_poaudit.ext_tax_amt = pp_poaudit.unit_tax_amt * 
			pr_poaudit.received_qty 
			LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt 
			+ pr_poaudit.ext_tax_amt 
			LET pr_poaudit.posted_flag = "Y" 
			LET pr_poaudit.jour_num = 0 
			LET pr_poaudit.year_num = pr_year_num 
			LET pr_poaudit.period_num = pr_period_num 
			LET err_message = "LS1 - INSERT poaudit rev 3" 
			## Temporary fix
			#           LET pr_poaudit.amend_num = pr_purchhead.var_num
			INSERT INTO poaudit VALUES (pr_poaudit.*) 
			# new cost structures
			LET pr_poaudit.seq_num = pr_poaudit.seq_num + 1 
			LET pr_poaudit.order_qty = 0 
			LET pr_poaudit.received_qty = pr_poaudit.received_qty * -1 
			LET pr_poaudit.voucher_qty = 0 
			LET pr_poaudit.desc_text = "Price Change" 
			LET pr_poaudit.unit_cost_amt = pr_shipdetl.fob_unit_ent_amt 
			LET pr_poaudit.ext_cost_amt = pr_shipdetl.fob_unit_ent_amt * 
			pr_poaudit.received_qty 
			LET pr_poaudit.unit_tax_amt = 0 
			LET pr_poaudit.ext_tax_amt = 0 
			LET pr_poaudit.line_total_amt = pr_poaudit.ext_cost_amt 
			+ pr_poaudit.ext_tax_amt 
			LET err_message = "LS1 - INSERT poaudit rev 4" 
			## Temporary fix
			#           LET pr_poaudit.amend_num = pr_purchhead.var_num
			INSERT INTO poaudit VALUES (pr_poaudit.*) 
		END IF 
		UPDATE purchdetl 
		SET seq_num = pr_poaudit.seq_num 
		WHERE rowid = row_id 
	END FOREACH 
	UPDATE purchhead 
	SET rev_num = rev_num + 1 
	WHERE cmpy_code = p_cmpy 
	AND order_num = pr_shipdetl.source_doc_num 
END FUNCTION 


FUNCTION post_journal(p_cmpy, pr_ship_code, net_fob_amt, duty_amt, 
	other_amt, final_date, pr_period_num, pr_year_num) 
	DEFINE 
	p_cmpy LIKE shiphead.cmpy_code, 
	pr_ship_code LIKE shiphead.ship_code, 
	net_fob_amt LIKE shiphead.fob_inv_cost_amt, 
	duty_amt LIKE shiphead.duty_inv_amt, 
	other_amt LIKE shiphead.other_inv_amt, 
	final_date DATE, 
	pr_period_num LIKE prodledg.period_num, 
	pr_year_num LIKE prodledg.year_num 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	# SET glob_rec_kandoouser.sign_on_code TO LC so GL knows WHERE it came FROM
	#LET glob_rec_kandoouser.sign_on_code = "LC"
	LET its_ok = 0 
	LET all_ok = 1 
 
	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(err_message,status) 
	IF try_again != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start("LCJRINTF-1","LCJRINTF_rpt_list_bdt","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT LCJRINTF_rpt_list_bdt TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
	 
	LET err_message = "LS1c - Shipdetl SELECT" 
	DECLARE detl_curs CURSOR FOR 
	SELECT * INTO pr_shipdetl.* FROM shipdetl 
	WHERE shipdetl.cmpy_code = p_cmpy 
	AND shipdetl.ship_code = pr_ship_code 
	AND shipdetl.ship_rec_qty > 0 
	ORDER BY cmpy_code, ship_code, line_num 
	LET err_message = "LS1c - Product SELECT"
	 
	FOREACH detl_curs 
		CASE 
			WHEN pr_shipdetl.source_doc_num IS NOT NULL 
				CALL po_line(p_cmpy, net_fob_amt, duty_amt, other_amt, final_date, pr_period_num, pr_year_num) 
			WHEN pr_shipdetl.part_code IS NOT NULL 
				CALL inv_line(p_cmpy, net_fob_amt, duty_amt, other_amt, final_date, pr_period_num, pr_year_num,"") 
		END CASE 
	END FOREACH 

	IF pr_inparms.gl_del_flag = "N" THEN 
		LET passed_desc = "Summary Landed Cost ", pr_shiphead.ship_code 
		CALL summary() 
	END IF 

	# OK now we have the temp table SET up we CALL jourintf TO
	# do its good work
	LET bal_rec.tran_type_ind = "CL" 

	# SET up balancing entry as the GL goods in transit account
	# as everything should balance......
	LET pr_data.acct_code = pr_smparms.git_acct_code 
	LET bal_rec.acct_code = pr_smparms.git_acct_code 
	LET bal_rec.desc_text = "Shipment: ", 
	pr_shiphead.ship_code clipped, 
	" finalise balancing entry " 
	LET bal_rec.ref_num = pr_shiphead.ship_code USING "&&&&&&&&" 

	LET sel_text = " SELECT *", 
	" FROM posttemp ", 
	" WHERE 1 =1 " 
	
	LET its_ok = lcjourintf(l_rpt_idx,
	sel_text, 
	p_cmpy, 
	glob_rec_kandoouser.sign_on_code, 
	bal_rec.*, 
	pr_period_num, 
	pr_year_num, 
	"LJ", 
	"LC", 
	pr_glparms.base_currency_code)
	 
	# see IF there IS a problem, IF so save
	# jourintf now returns (+/-) jour_num
	IF its_ok < 0 THEN 
		LET all_ok = 0 
	END IF 
	# now delete all FROM the table
	DELETE FROM posttemp WHERE 1=1 
	
	#------------------------------------------------------------
	FINISH REPORT LCJRINTF_rpt_list_bdt
	CALL rpt_finish("LCJRINTF_rpt_list_bdt")
	#------------------------------------------------------------

	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF   
END FUNCTION 

