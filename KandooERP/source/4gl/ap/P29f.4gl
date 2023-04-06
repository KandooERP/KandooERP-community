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

	Source code beautified by beautify.pl on 2020-01-03 13:41:21	$Id: $
}
############################################################
# \brief module P29f.4gl - New Accounts Payable Voucher Distribution Update
#
#                  - FUNCTION commits voucher/voucherdist info TO database
#                    Updating IS governed by pr_update_ind
#                               (1) = Insert voucher & distributions
#                               (2) = Update voucher & distributions
#                               (3) = Update distributions only
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_batch_num LIKE batch.batch_num 
	DEFINE glob_rec_ordhead RECORD LIKE ordhead.* # only uses order_num 
	DEFINE glob_rec_orderline RECORD LIKE orderline.* 
	DEFINE glob_rec_voucherdist RECORD LIKE voucherdist.* 
END GLOBALS 


############################################################
# Module Scope Variables
############################################################

############################################################
# FUNCTION initialise_orderline(p_cmpy,p_kandoouser_sign_on_code)
#
# variable used in here are defined as FUNCTION GLOBALS
# glob_rec_ordhead,
# glob_rec_orderline,
# glob_rec_voucherdist
############################################################
FUNCTION initialise_orderline(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_mask_code LIKE warehouse.acct_mask_code 
	DEFINE l_addcharge RECORD LIKE addcharge.* 

	INITIALIZE glob_rec_orderline TO NULL 
	LET glob_rec_orderline.cmpy_code = p_cmpy 
	LET glob_rec_orderline.cust_code = glob_rec_ordhead.cust_code 
	LET glob_rec_orderline.order_num = glob_rec_ordhead.order_num 
	LET glob_rec_ordhead.line_num = glob_rec_ordhead.line_num + 1 
	LET glob_rec_orderline.line_num = glob_rec_ordhead.line_num 
	# Get warehouse FOR masking
	LET l_ware_code = NULL 
	LET l_mask_code = NULL 
	IF glob_rec_ordhead.internal_ware_code IS NOT NULL THEN 
		SELECT ware_code,acct_mask_code 
		INTO l_ware_code,l_mask_code 
		FROM warehouse 
		WHERE ware_code = glob_rec_ordhead.internal_ware_code 
		AND cmpy_code = p_cmpy 
	ELSE 
		DECLARE w_whouse CURSOR FOR 
		SELECT ware_code FROM orderline 
		WHERE part_code IS NOT NULL 
		AND order_num = glob_rec_ordhead.order_num 
		FOREACH w_whouse INTO l_ware_code 
			SELECT acct_mask_code 
			INTO l_mask_code 
			FROM warehouse 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = l_ware_code 
			EXIT FOREACH 
		END FOREACH 
	END IF 

	LET glob_rec_orderline.ware_code = l_ware_code 
	LET glob_rec_orderline.desc_text = glob_rec_voucherdist.desc_text 
	CALL get_ordacct(p_cmpy, "addcharge", "rev_acct_code", 
	glob_rec_orderline.desc_text, glob_rec_ordhead.ord_ind) 
	RETURNING l_addcharge.rev_acct_code 
	IF l_addcharge.rev_acct_code IS NULL THEN 
		SELECT * INTO l_addcharge.* FROM addcharge 
		WHERE desc_code = glob_rec_orderline.desc_text 
		AND cmpy_code = p_cmpy 
	END IF 
	LET glob_rec_orderline.unit_cost_amt = 0 
	LET glob_rec_orderline.unit_price_amt = 0 
	LET glob_rec_orderline.order_qty = 0 
	LET glob_rec_orderline.line_tot_amt = 0 
	LET glob_rec_orderline.inv_qty = 0 
	LET glob_rec_orderline.acct_code = build_mask(p_cmpy, 
	l_mask_code, 
	l_addcharge.rev_acct_code) 
	LET glob_rec_orderline.unit_tax_amt = 0 
	LET glob_rec_orderline.autoinsert_flag = "N" 
	LET glob_rec_orderline.disc_allow_flag = "N" 
	LET glob_rec_orderline.cost_ind = "W" 
	LET glob_rec_orderline.disc_amt = 0 
	LET glob_rec_orderline.ext_cost_amt = glob_rec_voucherdist.dist_amt 
	LET glob_rec_orderline.ext_price_amt = 0 
	LET glob_rec_orderline.ext_tax_amt = 0 
	LET glob_rec_orderline.list_price_amt = 0 
	LET glob_rec_orderline.sched_qty = 0 
	LET glob_rec_orderline.back_qty = 0 
	LET glob_rec_orderline.picked_qty = 0 
	LET glob_rec_orderline.conf_qty = 0 
	LET glob_rec_orderline.trade_in_flag = "N" 
	LET glob_rec_orderline.pick_flag = "N" 
	LET glob_rec_orderline.bonus_disc_amt = 0 
	LET glob_rec_orderline.comm_amt = 0 
	LET glob_rec_orderline.status_ind = "C" 
	LET glob_rec_orderline.return_qty = 0 
	LET glob_rec_orderline.entry_code = p_kandoouser_sign_on_code 
	LET glob_rec_orderline.entry_date = today 
END FUNCTION 


############################################################
# FUNCTION update_voucher_related_tables(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher,p_rec_vouchpayee)
#
#
############################################################
FUNCTION update_voucher_related_tables(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_rec_voucher,p_rec_vouchpayee) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_update_ind CHAR(1)
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE p_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_unit_cost_amt LIKE poaudit.unit_cost_amt 
	DEFINE l_calc_cost_amt LIKE poaudit.unit_cost_amt 
	DEFINE l_rec_s_voucher RECORD LIKE voucher.* 
	#DEFINE pr_apparms RECORD LIKE apparms.*
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_cu_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_cx_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_class_ind LIKE shipcosttype.class_ind 
	DEFINE l_cust_code LIKE customer.corp_cust_code 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_price_err_mess CHAR(60) 
	DEFINE l_diff_qty DECIMAL(16,4) 
	DEFINE l_kandoooption LIKE kandoooption.feature_ind 
	DEFINE l_kandoo_log_msg CHAR(240) 
	DEFINE l_lower_limit LIKE poaudit.line_total_amt 
	DEFINE l_upper_limit LIKE poaudit.line_total_amt 
	DEFINE l_calc_line_total_amt LIKE poaudit.line_total_amt 
	DEFINE l_price_change_status SMALLINT 
	DEFINE l_onorder_amt LIKE vendor.onorder_amt 
	DEFINE l_db_status INTEGER 
	DEFINE l_valid_tran CHAR(1) 
	DEFINE l_error_disp_flag CHAR(1) 
	DEFINE l_available_amt LIKE fundsapproved.limit_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("U",1005,"") 
	#1005 Updating Database;  Please wait.
	--GOTO bypass 
	--LABEL recovery: 
	--IF error_recover(l_err_message,status) != "Y" THEN 
	--	RETURN false 
	--END IF 
	LABEL bypass: 
	LET l_err_cnt = 0 
	LET l_error_disp_flag = true 

--	WHENEVER ERROR GOTO recovery 
	# Start the transaction
	BEGIN WORK 
	# In order to garantee that referential constraint don't fail until commit
	EXECUTE immediate "SET CONSTRAINTS ALL deferred" 

	LET l_err_message = "P29 - Locking Vendor FOR Update" 
	DECLARE c_vendor CURSOR FOR 
	SELECT * 
	FROM vendor 
	WHERE cmpy_code = p_rec_voucher.cmpy_code 
	AND vend_code = p_rec_voucher.vend_code 
	FOR UPDATE 
	OPEN c_vendor 
	FETCH c_vendor INTO l_rec_vendor.* 
	DECLARE c_voucher CURSOR FOR 
	SELECT * FROM voucher 
	WHERE cmpy_code = p_rec_voucher.cmpy_code 
	AND vend_code = p_rec_voucher.vend_code 
	AND vouch_code = p_rec_voucher.vouch_code 
	FOR UPDATE 

	CASE p_update_ind 
		WHEN "1" #### new voucher 
			LET l_err_message = "P29 - Locking AP Parameters FOR Update" 
			DECLARE c_apparms CURSOR FOR 
			SELECT * FROM apparms 
			WHERE apparms.parm_code = "1" 
			AND apparms.cmpy_code = p_cmpy 
			FOR UPDATE 
			OPEN c_apparms 
			FETCH c_apparms INTO glob_rec_apparms.* 
			LET p_rec_voucher.vouch_code = glob_rec_apparms.next_vouch_num 
			LET l_err_message = "P29 - Updating AP Parameters FOR Update" 
			UPDATE apparms 
			SET next_vouch_num = glob_rec_apparms.next_vouch_num + 1 
			WHERE cmpy_code = p_cmpy 
			AND parm_code = "1" 
			INITIALIZE l_rec_s_voucher.* TO NULL 
			LET l_rec_s_voucher.total_amt = 0 
		WHEN "2" #### UPDATE voucher 
			LET l_err_message = "P29 - Locking Voucher FOR Update" 
			OPEN c_voucher 
			FETCH c_voucher INTO l_rec_s_voucher.* 
		WHEN "3" #### UPDATE voucher distributions 
			LET l_err_message = "P29 - Locking Voucher FOR Update" 
			OPEN c_voucher 
			FETCH c_voucher INTO p_rec_voucher.* 
			LET l_rec_s_voucher.* = p_rec_voucher.* 
	END CASE 

	# we have existing distributions so drop them
	IF p_rec_voucher.post_flag = "N" THEN 
		DECLARE c_voucherdist CURSOR FOR 
		SELECT * 
		FROM voucherdist 
		WHERE cmpy_code = p_rec_voucher.cmpy_code 
		AND vend_code = p_rec_voucher.vend_code 
		AND vouch_code = p_rec_voucher.vouch_code 


		FOREACH c_voucherdist INTO glob_rec_voucherdist.* 

			CASE glob_rec_voucherdist.type_ind 
				WHEN "P" 
					LET l_err_message = "P29 - Locking P.O. Line FOR Update" 
					DECLARE c_purchdetl CURSOR FOR 
					SELECT * 
					FROM purchdetl 
					WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
					AND order_num = glob_rec_voucherdist.po_num 
					AND line_num = glob_rec_voucherdist.po_line_num 
					FOR UPDATE OF seq_num 
					OPEN c_purchdetl 
					FETCH c_purchdetl INTO l_rec_purchdetl.* 
					IF status = 0 THEN 
						LET l_err_message = "P29 - Insert P.O. Audit Line" 
						LET l_rec_purchdetl.seq_num = l_rec_purchdetl.seq_num + 1 
						CALL po_line_info(glob_rec_voucherdist.cmpy_code,glob_rec_voucherdist.po_num, glob_rec_voucherdist.po_line_num) 
						RETURNING l_rec_poaudit.order_qty, 
							l_rec_poaudit.received_qty, 
							l_rec_poaudit.voucher_qty, 
							l_rec_poaudit.unit_cost_amt, 
							l_rec_poaudit.ext_cost_amt, 
							l_rec_poaudit.unit_tax_amt, 
							l_rec_poaudit.ext_tax_amt, 
							l_rec_poaudit.line_total_amt 
						LET l_rec_poaudit.cmpy_code = l_rec_purchdetl.cmpy_code 
						LET l_rec_poaudit.po_num = l_rec_purchdetl.order_num 
						LET l_rec_poaudit.line_num = l_rec_purchdetl.line_num 
						LET l_rec_poaudit.seq_num = l_rec_purchdetl.seq_num 
						LET l_rec_poaudit.vend_code = p_rec_voucher.vend_code 
						LET l_rec_poaudit.tran_code = "VO" 
						LET l_rec_poaudit.tran_num = p_rec_voucher.vouch_code 
						LET l_rec_poaudit.tran_date = p_rec_voucher.vouch_date 
						LET l_rec_poaudit.entry_date = today 
						LET l_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_poaudit.orig_auth_flag = "N" 
						LET l_rec_poaudit.now_auth_flag = "N" 
						LET l_rec_poaudit.order_qty = 0 
						LET l_rec_poaudit.received_qty = 0 
						LET l_rec_poaudit.desc_text = l_rec_purchdetl.desc_text 
						LET l_rec_poaudit.posted_flag = "N" 
						LET l_rec_poaudit.jour_num = 0 
						LET l_rec_poaudit.year_num = p_rec_voucher.year_num 
						LET l_rec_poaudit.period_num = p_rec_voucher.period_num 
						LET l_rec_poaudit.voucher_qty = 0 - glob_rec_voucherdist.trans_qty 
						LET l_rec_poaudit.line_total_amt = 0 - glob_rec_voucherdist.dist_amt 
						INSERT INTO poaudit VALUES (l_rec_poaudit.*) 
						LET l_err_message = "P29 - Update P.O. Line" 
						UPDATE purchdetl 
						SET seq_num = l_rec_purchdetl.seq_num 
						WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
							AND order_num = glob_rec_voucherdist.po_num 
							AND line_num = glob_rec_voucherdist.po_line_num 
						LET l_err_message = "P29 - Update P.O. Header" 
						UPDATE purchhead 
						SET status_ind = "P" 
						WHERE cmpy_code = p_cmpy 
							AND order_num = l_rec_poaudit.po_num 
							AND vend_code = l_rec_poaudit.vend_code 
						LET l_onorder_amt = glob_rec_voucherdist.trans_qty * (l_rec_poaudit.unit_cost_amt + l_rec_poaudit.unit_tax_amt) 
						UPDATE vendor 
						SET onorder_amt = onorder_amt + l_onorder_amt 
						WHERE cmpy_code = p_cmpy 
							AND vend_code = l_rec_purchdetl.vend_code 

							#Update the revision number on purchhead table
						UPDATE purchhead 
						SET rev_num = rev_num + 1 
						WHERE cmpy_code = p_cmpy 
							AND order_num = l_rec_poaudit.po_num 

						SELECT * INTO l_rec_activity.* 
						FROM activity 
						WHERE cmpy_code = p_cmpy 
							AND job_code = l_rec_purchdetl.job_code 
							AND var_code = l_rec_purchdetl.var_num 
							AND activity_code = l_rec_purchdetl.activity_code 
						UPDATE jobledger 
						SET year_num = p_rec_voucher.year_num, 
							period_num = p_rec_voucher.period_num, 
							posted_flag = "P", 
							ref_num = p_rec_voucher.vouch_code 
						WHERE cmpy_code = p_cmpy 
							AND job_code = l_rec_purchdetl.job_code 
							AND var_code = l_rec_purchdetl.var_num 
							AND activity_code = l_rec_purchdetl.activity_code 
							AND seq_num = l_rec_activity.seq_num 
					END IF 

				WHEN "J" 
					LET l_err_message = "P29 - Locking JM Activity FOR Update" 
					DECLARE c_activity CURSOR FOR 
					SELECT * 
					FROM activity 
					WHERE cmpy_code = p_cmpy 
						AND job_code = glob_rec_voucherdist.job_code 
						AND var_code = glob_rec_voucherdist.var_code 
						AND activity_code = glob_rec_voucherdist.act_code 
						AND finish_flag = "N" 
					FOR UPDATE 
					OPEN c_activity 
					FETCH c_activity INTO l_rec_activity.* 
					IF status = 0 THEN 
						LET l_err_message = "P29 - Insert JM Jobledger " 
						LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
						LET l_rec_jobledger.cmpy_code = p_cmpy 
						LET l_rec_jobledger.trans_date = p_rec_voucher.vouch_date 
						IF p_update_ind = "2" THEN 
							LET l_rec_jobledger.year_num = l_rec_s_voucher.year_num 
							LET l_rec_jobledger.period_num = l_rec_s_voucher.period_num 
						ELSE 
							LET l_rec_jobledger.year_num = p_rec_voucher.year_num 
							LET l_rec_jobledger.period_num = p_rec_voucher.period_num 
						END IF 
						LET l_rec_jobledger.job_code = glob_rec_voucherdist.job_code 
						LET l_rec_jobledger.var_code = glob_rec_voucherdist.var_code 
						LET l_rec_jobledger.allocation_ind = glob_rec_voucherdist.allocation_ind 
						LET l_rec_jobledger.activity_code = glob_rec_voucherdist.act_code 
						LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
						LET l_rec_jobledger.trans_type_ind = "VO" 
						LET l_rec_jobledger.trans_source_num = p_rec_voucher.vouch_code 
						LET l_rec_jobledger.trans_source_text=glob_rec_voucherdist.res_code 
						IF p_rec_voucher.conv_qty != 0 THEN 
							LET l_rec_jobledger.trans_amt = (0 - glob_rec_voucherdist.dist_amt) / l_rec_s_voucher.conv_qty 
						ELSE 
							LET l_rec_jobledger.trans_amt = 0 - glob_rec_voucherdist.dist_amt 
						END IF 
						LET l_rec_jobledger.trans_qty = 0 - glob_rec_voucherdist.trans_qty 
						LET l_rec_jobledger.charge_amt = glob_rec_voucherdist.charge_amt * glob_rec_voucherdist.trans_qty * -1 
						LET l_rec_jobledger.posted_flag = "P" 
						LET l_rec_jobledger.desc_text = glob_rec_voucherdist.desc_text 
						#LET l_rec_jobledger.desc_text = "Voucher Reversal "
						LET l_rec_jobledger.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_jobledger.entry_date = today 
						LET l_rec_jobledger.ref_num = p_rec_voucher.vouch_code 
						
						INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
						
						LET l_err_message = "P29 - Update JM Activity " 
						UPDATE activity 
						SET seq_num = l_rec_activity.seq_num, 
						act_cost_amt = act_cost_amt + l_rec_jobledger.trans_amt, 
						act_cost_qty = act_cost_qty + l_rec_jobledger.trans_qty, 
						post_revenue_amt = post_revenue_amt + l_rec_jobledger.charge_amt 
						WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
							AND job_code = glob_rec_voucherdist.job_code 
							AND var_code = glob_rec_voucherdist.var_code 
							AND activity_code = glob_rec_voucherdist.act_code 
					ELSE 
						LET l_err_message="JM Activity IS closed - No Update Allowed" 
						--GOTO recovery 
					END IF 

				WHEN "S" 
					LET l_err_message = "P29 - Locking Shiphead FOR UPDATE" 
					DECLARE c_shiphead CURSOR FOR 
					SELECT * 
					FROM shiphead 
					WHERE cmpy_code = p_cmpy 
						AND ship_code = glob_rec_voucherdist.job_code 
					FOR UPDATE 
					OPEN c_shiphead 
					FETCH c_shiphead INTO l_rec_shiphead.* 
					IF status = 0 THEN 
						SELECT class_ind INTO l_class_ind 
						FROM shipcosttype 
						WHERE cmpy_code = p_cmpy 
							AND cost_type_code = glob_rec_voucherdist.res_code 
						CASE l_class_ind 
							WHEN '1' 
								LET l_rec_shiphead.fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt - glob_rec_voucherdist.dist_amt 
								LET l_rec_shiphead.fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt - ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '2' 
								LET l_rec_shiphead.duty_inv_amt = l_rec_shiphead.duty_inv_amt - ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '3' 
								LET l_rec_shiphead.other_cost_amt = l_rec_shiphead.other_cost_amt - ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '4' 
								LET l_rec_shiphead.late_cost_amt = l_rec_shiphead.late_cost_amt - ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
						END CASE 

						UPDATE shiphead 
						SET fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt, 
							fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt, 
							duty_inv_amt = l_rec_shiphead.duty_inv_amt, 
							late_cost_amt = l_rec_shiphead.late_cost_amt, 
							other_cost_amt = l_rec_shiphead.other_cost_amt 
						WHERE cmpy_code = p_cmpy 
							AND ship_code = glob_rec_voucherdist.job_code 
					END IF 

				WHEN "W" 
					LET l_err_message = "P29 - Locking Ordhead FOR UPDATE" 
					DECLARE c_ordhead CURSOR FOR 
					SELECT order_num 
					FROM ordhead 
					WHERE cmpy_code = p_cmpy 
						AND order_num = glob_rec_voucherdist.po_num 
					FOR UPDATE 
					OPEN c_ordhead 
					FETCH c_ordhead INTO glob_rec_ordhead.order_num 
					UPDATE ordhead 
					SET export_cost_amt = export_cost_amt - glob_rec_voucherdist.dist_amt 
					WHERE cmpy_code = p_cmpy 
						AND order_num = glob_rec_ordhead.order_num 

					LET l_err_message = "P29 - Locking orderline FOR UPDATE" 
					DECLARE c_orderline CURSOR FOR 
					SELECT order_num,line_num, ext_cost_amt 
					FROM orderline 
					WHERE order_num = glob_rec_voucherdist.po_num 
						AND part_code IS NULL 
						AND desc_text = glob_rec_voucherdist.desc_text 
						AND cmpy_code = p_cmpy 
					FOR UPDATE 
					OPEN c_orderline 
					FETCH c_orderline INTO glob_rec_orderline.order_num, 
					glob_rec_orderline.line_num, 
					glob_rec_orderline.ext_cost_amt 
					IF status != NOTFOUND THEN 
						UPDATE orderline 
						SET ext_cost_amt = ext_cost_amt - glob_rec_voucherdist.dist_amt 
						WHERE order_num = glob_rec_orderline.order_num 
						AND line_num = glob_rec_orderline.line_num 
						AND cmpy_code = p_cmpy 
					END IF 
					CLOSE c_orderline 

				WHEN "A" 
					# AR Updates
					DECLARE c1_customer CURSOR FOR 
					SELECT * 
					FROM customer 
					WHERE cmpy_code = p_cmpy 
						AND cust_code = glob_rec_voucherdist.res_code 
					FOR UPDATE 
					OPEN c1_customer 
					FETCH c1_customer INTO l_rec_customer.* 
					IF db_invoicehead_pk_exists(UI_ON,MODE_SELECT,glob_rec_voucherdist.po_num) THEN
						CALL db_invoicehead_get_rec(UI_ON,glob_rec_voucherdist.po_num) RETURNING  l_rec_invoicehead.*
						INITIALIZE l_rec_araudit.* TO NULL 
						LET l_err_message = "P29 - Customer Update Inv" 
						LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
						LET l_rec_customer.bal_amt = l_rec_customer.bal_amt - l_rec_invoicehead.total_amt 
						LET l_rec_customer.curr_amt = l_rec_customer.curr_amt - l_rec_invoicehead.total_amt 
						LET l_rec_araudit.cmpy_code = p_cmpy 
						LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
						LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
						LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
						LET l_rec_araudit.tran_type_ind = "IN" 
						LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
						LET l_rec_araudit.tran_text = "Adjustment" 
						LET l_rec_araudit.tran_amt = 0 - l_rec_invoicehead.total_amt 
						LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
						LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
						LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
						LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
						LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
						LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
						LET l_rec_araudit.entry_date = today 
						LET l_err_message = "P29 - Unable TO add TO AR log table " 
						INSERT INTO araudit VALUES (l_rec_araudit.*) 
						IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
							LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
						END IF 
						LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt + l_rec_customer.bal_amt 
						IF year(l_rec_invoicehead.inv_date) > year(l_rec_customer.last_inv_date) THEN 
							LET l_rec_customer.ytds_amt = 0 
						END IF 
						LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt - l_rec_invoicehead.total_amt 
						IF (month(l_rec_invoicehead.inv_date) > month(l_rec_customer.last_inv_date) OR year(l_rec_invoicehead.inv_date) > year(l_rec_customer.last_inv_date)) THEN 
							LET l_rec_customer.mtds_amt = 0 
						END IF 
						LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt - l_rec_invoicehead.total_amt 
						LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
						LET l_err_message = "P29 - Custmain actual UPDATE " 
						UPDATE customer 
						SET next_seq_num = l_rec_customer.next_seq_num, 
							bal_amt = l_rec_customer.bal_amt, 
							curr_amt = l_rec_customer.curr_amt, 
							highest_bal_amt = l_rec_customer.highest_bal_amt, 
							cred_bal_amt = l_rec_customer.cred_bal_amt, 
							last_inv_date = l_rec_customer.last_inv_date, 
							ytds_amt = l_rec_customer.ytds_amt, 
							mtds_amt = l_rec_customer.mtds_amt 
						WHERE cmpy_code = p_cmpy 
							AND cust_code = glob_rec_voucherdist.res_code 

						UPDATE invoicehead 
						SET total_amt = 0, 
							goods_amt = 0, 
							paid_amt = 0, 
							hand_amt = 0, 
							hand_amt = 0, 
							tax_amt = 0 
						WHERE cmpy_code = p_cmpy 
							AND inv_num = l_rec_invoicehead.inv_num 

						UPDATE invoicedetl 
						SET line_total_amt = 0, 
							ext_sale_amt = 0, 
							ext_tax_amt = 0, 
							unit_sale_amt = 0, 
							unit_tax_amt = 0 
						WHERE cmpy_code = p_cmpy 
							AND inv_num = l_rec_invoicehead.inv_num 
					END IF 
					################### END AR Updates
			END CASE 


			LET l_err_message = "P29 - Deleting Existing Voucher Lines" 
			DELETE FROM voucherdist 
			WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
				AND vend_code = p_rec_voucher.vend_code 
				AND vouch_code = glob_rec_voucherdist.vouch_code 
				AND line_num = glob_rec_voucherdist.line_num 
		END FOREACH 
	END IF 
	####
	#### Insert/Update Voucher
	####
	IF p_update_ind != "3" THEN 
		CASE 
			WHEN (l_rec_s_voucher.inv_text IS NULL AND p_rec_voucher.inv_text IS null) 
				# Nothing
			WHEN (l_rec_s_voucher.inv_text IS NULL AND p_rec_voucher.inv_text IS NOT null) 
				LET l_err_message = "P29 - Insert Vendor Invoice Entry" 
				LET l_kandoooption = get_kandoooption_feature_state('AP','VI') 
				IF l_kandoooption = 'N' THEN 
					INSERT INTO vendorinvs VALUES (p_cmpy,p_rec_voucher.vend_code,p_rec_voucher.inv_text,p_rec_voucher.vouch_code,p_rec_voucher.entry_date,p_rec_voucher.year_num) 
				ELSE 
					SELECT 1 FROM vendorinvs 
					WHERE cmpy_code = p_cmpy 
						AND vend_code = p_rec_voucher.vend_code 
						AND inv_text = p_rec_voucher.inv_text 
						AND year_num = p_rec_voucher.year_num
					IF sqlca.sqlcode = NOTFOUND THEN 
						INSERT INTO vendorinvs 	VALUES (p_cmpy,p_rec_voucher.vend_code,p_rec_voucher.inv_text,p_rec_voucher.vouch_code,p_rec_voucher.entry_date,p_rec_voucher.year_num) 
					END IF 
				END IF 
			WHEN (l_rec_s_voucher.inv_text IS NOT NULL AND p_rec_voucher.inv_text IS null) 
				LET l_err_message = "P29 - Deleting Vendor Invoice Entry" 
				DELETE FROM vendorinvs 
				WHERE cmpy_code = p_cmpy 
					AND vend_code = p_rec_voucher.vend_code 
					AND inv_text = l_rec_s_voucher.inv_text 
					AND year_num = p_rec_voucher.year_num
			WHEN (l_rec_s_voucher.inv_text != p_rec_voucher.inv_text) 
				LET l_err_message = "P29 - Updating Vendor Invoice Entry" 
				UPDATE vendorinvs 
				SET inv_text = p_rec_voucher.inv_text 
				WHERE cmpy_code = p_cmpy 
					AND vend_code = p_rec_voucher.vend_code 
					AND inv_text = l_rec_s_voucher.inv_text 
					AND year_num = p_rec_voucher.year_num
		END CASE 


		#####Enable DISPLAY the zero total_amt voucher in SCREEN P106 of program P1B
		LET l_err_message = "P29 - Insert AP Audit Line" 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt - l_rec_s_voucher.total_amt 
		LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
		- l_rec_s_voucher.total_amt 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_apaudit.cmpy_code = p_cmpy 
		LET l_rec_apaudit.tran_date = l_rec_s_voucher.vouch_date 
		LET l_rec_apaudit.vend_code = l_rec_s_voucher.vend_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		LET l_rec_apaudit.trantype_ind = "VO" 
		LET l_rec_apaudit.year_num = l_rec_s_voucher.year_num 
		LET l_rec_apaudit.period_num = l_rec_s_voucher.period_num 
		LET l_rec_apaudit.source_num = l_rec_s_voucher.vouch_code 
		LET l_rec_apaudit.tran_text = "Backout Voucher" 
		LET l_rec_apaudit.tran_amt = 0 - l_rec_s_voucher.total_amt 
		LET l_rec_apaudit.entry_code = l_rec_s_voucher.entry_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET l_rec_apaudit.currency_code = l_rec_s_voucher.currency_code 
		LET l_rec_apaudit.conv_qty = l_rec_s_voucher.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt + p_rec_voucher.total_amt 
		LET l_rec_vendor.curr_amt =l_rec_vendor.curr_amt + p_rec_voucher.total_amt 
		LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
		LET l_rec_apaudit.cmpy_code = p_cmpy 
		LET l_rec_apaudit.tran_date = p_rec_voucher.vouch_date 
		LET l_rec_apaudit.vend_code = p_rec_voucher.vend_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		LET l_rec_apaudit.trantype_ind = "VO" 
		LET l_rec_apaudit.year_num = p_rec_voucher.year_num 
		LET l_rec_apaudit.period_num = p_rec_voucher.period_num 
		LET l_rec_apaudit.source_num = p_rec_voucher.vouch_code 
		IF p_update_ind = "1" THEN 
			LET l_rec_apaudit.tran_text = "Voucher Entry" 
		ELSE 
			LET l_rec_apaudit.tran_text = "Voucher Edit" 
		END IF 
		LET l_rec_apaudit.tran_amt = p_rec_voucher.total_amt 
		LET l_rec_apaudit.entry_code = p_rec_voucher.entry_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET l_rec_apaudit.currency_code = p_rec_voucher.currency_code 
		LET l_rec_apaudit.conv_qty = p_rec_voucher.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
			LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
		END IF 
		IF l_rec_vendor.last_vouc_date IS NULL OR p_rec_voucher.vouch_date > l_rec_vendor.last_vouc_date THEN 
			LET l_rec_vendor.last_vouc_date = p_rec_voucher.vouch_date 
		END IF 
		LET p_rec_voucher.goods_amt = p_rec_voucher.total_amt 
		IF p_rec_voucher.withhold_tax_ind IS NULL THEN 
			SELECT withhold_tax_ind INTO p_rec_voucher.withhold_tax_ind 
			FROM vendortype 
			WHERE cmpy_code = p_cmpy 
			AND type_code = l_rec_vendor.type_code 
			IF status = NOTFOUND THEN 
				LET p_rec_voucher.withhold_tax_ind = "0" 
			END IF 
		END IF 
		#now done it CALL init_p_ap() #init P/AP module
		# SELECT * INTO pr_apparms.* FROM apparms
		#  WHERE cmpy_code = p_cmpy
		#    AND parm_code = "1"
		IF glob_rec_apparms.vouch_approve_flag = 'Y' THEN 
			LET p_rec_voucher.approved_code = 'N' 
		ELSE 
			LET p_rec_voucher.approved_code = 'Y' 
		END IF 
		LET p_rec_voucher.approved_date = NULL 
		LET p_rec_voucher.approved_by_code = NULL 
		IF glob_batch_num IS NOT NULL THEN 
			LET p_rec_voucher.batch_num = glob_batch_num 
		END IF 

		LET l_err_message = "P29 - Updating Voucher Header" 
		UPDATE voucher 
		SET * = p_rec_voucher.* 
		WHERE cmpy_code = p_cmpy 
			AND vend_code = p_rec_voucher.vend_code 
			AND vouch_code = p_rec_voucher.vouch_code 
		# try update first, if does not exist => insert
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET l_err_message = "P29 - Inserting Voucher Header" 
			INSERT INTO voucher VALUES (p_rec_voucher.*) 
		END IF 
		LET l_err_message = "P29 - Updating Vendor Header" 
		UPDATE vendor 
		SET bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			highest_bal_amt = l_rec_vendor.highest_bal_amt, 
			last_vouc_date = l_rec_vendor.last_vouc_date, 
			next_seq_num = l_rec_vendor.next_seq_num 
		WHERE cmpy_code = p_cmpy 
			AND vend_code = p_rec_voucher.vend_code 

		SELECT * INTO l_rec_activity.* 
		FROM activity 
		WHERE cmpy_code = p_cmpy 
			AND job_code = l_rec_purchdetl.job_code 
			AND var_code = l_rec_purchdetl.var_num 
			AND activity_code = l_rec_purchdetl.activity_code 
		UPDATE jobledger 
		SET year_num = p_rec_voucher.year_num, 
			period_num = p_rec_voucher.period_num, 
			posted_flag = "P", 
			ref_num = p_rec_voucher.vouch_code 
		WHERE cmpy_code = p_cmpy 
			AND job_code = l_rec_purchdetl.job_code 
			AND var_code = l_rec_purchdetl.var_num 
			AND activity_code = l_rec_purchdetl.activity_code 
			AND seq_num = l_rec_activity.seq_num 
	END IF 
	####
	#### Insert Distributions
	####
	IF p_rec_voucher.post_flag = "N" THEN 
		LET p_rec_voucher.dist_amt = 0 
		LET p_rec_voucher.dist_qty = 0 
		LET p_rec_voucher.line_num = 0 

		DECLARE c1_t_voucherdist CURSOR FOR 
		SELECT * FROM t_voucherdist 
		WHERE acct_code IS NOT NULL 
		ORDER BY line_num 
		FOREACH c1_t_voucherdist INTO glob_rec_voucherdist.* 
			IF glob_rec_voucherdist.dist_amt IS NULL THEN 
				LET glob_rec_voucherdist.dist_amt = 0 
			END IF 
			IF glob_rec_voucherdist.dist_qty IS NULL THEN 
				LET glob_rec_voucherdist.dist_qty = 0 
			END IF 
			IF glob_rec_voucherdist.dist_amt = 0 AND glob_rec_voucherdist.dist_qty = 0 THEN 
				CONTINUE FOREACH 
			END IF 
			LET p_rec_voucher.line_num = p_rec_voucher.line_num + 1 
			LET glob_rec_voucherdist.cmpy_code = p_rec_voucher.cmpy_code 
			LET glob_rec_voucherdist.vend_code = p_rec_voucher.vend_code 
			LET glob_rec_voucherdist.vouch_code = p_rec_voucher.vouch_code 
			LET glob_rec_voucherdist.line_num = p_rec_voucher.line_num 
			LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt 
			+ glob_rec_voucherdist.dist_amt 
			LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty 
			+ glob_rec_voucherdist.dist_qty 


			CASE glob_rec_voucherdist.type_ind 
				WHEN "P" 
					LET l_err_message = 
					"P29 - Locking P.O. Line FOR Update" 
					DECLARE c1_purchdetl CURSOR FOR 
					SELECT * 
					FROM purchdetl 
					WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
						AND order_num = glob_rec_voucherdist.po_num 
						AND line_num = glob_rec_voucherdist.po_line_num 
					FOR UPDATE OF seq_num 
					OPEN c1_purchdetl 
					FETCH c1_purchdetl INTO l_rec_purchdetl.* 
					IF status != 0 THEN 
						LET l_kandoo_log_msg = " " 
						LET l_kandoo_log_msg[001,060] = 
						"Voucher ", glob_rec_voucherdist.vouch_code USING "<<<<<<<<" clipped, 
						" PO ", glob_rec_voucherdist.po_num USING "<<<<<<<<" clipped, 
						" line ", glob_rec_voucherdist.po_line_num USING "<<<<<<<<" clipped, " does NOT exist" 
						CALL errorlog(l_kandoo_log_msg) 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt 
						- glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty 
						- glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT CASE 
					END IF 
					SELECT unique 1 
					FROM shipdetl, shiphead 
					WHERE shipdetl.source_doc_num = l_rec_purchdetl.order_num 
						AND shipdetl.doc_line_num = l_rec_purchdetl.line_num 
						AND shipdetl.ship_inv_qty > 0 
						AND shipdetl.cmpy_code = l_rec_purchdetl.cmpy_code 
						AND shipdetl.cmpy_code = shiphead.cmpy_code 
						AND shipdetl.ship_code = shiphead.ship_code 
						AND shiphead.finalised_flag <> "Y" 
					IF status != NOTFOUND THEN 
						LET l_kandoo_log_msg = " " 
						LET l_kandoo_log_msg[001,060] = 
						"Voucher ", glob_rec_voucherdist.vouch_code USING "<<<<<<<<" clipped, 
						" PO ", glob_rec_voucherdist.po_num USING "<<<<<<<<" clipped, 
						" line ", glob_rec_voucherdist.po_line_num USING "<<<<<<<<" clipped, " on shipment" 
						CALL errorlog(l_kandoo_log_msg) 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt- glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty- glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT CASE 
					END IF 
					LET l_onorder_amt = 0 
					LET l_err_message = "P29 - Inserting P.O. Audit Line" 
					CALL po_line_info(glob_rec_voucherdist.cmpy_code, glob_rec_voucherdist.po_num, glob_rec_voucherdist.po_line_num) 
					RETURNING l_rec_cu_poaudit.order_qty, 
						l_rec_cu_poaudit.received_qty, 
						l_rec_cu_poaudit.voucher_qty, 
						l_rec_cu_poaudit.unit_cost_amt, 
						l_rec_cu_poaudit.ext_cost_amt, 
						l_rec_cu_poaudit.unit_tax_amt, 
						l_rec_cu_poaudit.ext_tax_amt, 
						l_rec_cu_poaudit.line_total_amt 
					LET l_diff_qty = (glob_rec_voucherdist.trans_qty - (l_rec_cu_poaudit.received_qty - l_rec_cu_poaudit.voucher_qty)) 
					IF l_diff_qty > 0 THEN 
						LET l_kandoo_log_msg = " " 
						LET l_kandoo_log_msg[001,060] = 
						"Voucher ", glob_rec_voucherdist.vouch_code USING "<<<<<<<<" clipped, 
						" will overpay PO ", glob_rec_voucherdist.po_num USING "<<<<<<<<" clipped, 
						" line ", glob_rec_voucherdist.po_line_num USING "<<<<<<<<" 
						CALL errorlog(l_kandoo_log_msg) 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt - glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
						EXIT CASE 
					END IF 
					LET l_rec_poaudit.cmpy_code = l_rec_purchdetl.cmpy_code 
					LET l_rec_poaudit.po_num = l_rec_purchdetl.order_num 
					LET l_rec_poaudit.line_num = l_rec_purchdetl.line_num 
					LET l_rec_poaudit.vend_code = p_rec_voucher.vend_code 
					LET l_rec_poaudit.tran_code = "VO" 
					LET l_rec_poaudit.tran_num = p_rec_voucher.vouch_code 
					LET l_rec_poaudit.tran_date = p_rec_voucher.vouch_date 
					LET l_rec_poaudit.entry_date = today 
					LET l_rec_poaudit.entry_code = p_kandoouser_sign_on_code 
					LET l_rec_poaudit.orig_auth_flag = "N" 
					LET l_rec_poaudit.now_auth_flag = "N" 
					LET l_rec_poaudit.order_qty = 0 
					LET l_rec_poaudit.received_qty = 0 
					LET l_rec_poaudit.voucher_qty = glob_rec_voucherdist.trans_qty 
					LET l_rec_poaudit.desc_text = l_rec_purchdetl.desc_text 
					LET l_rec_poaudit.posted_flag = "N" 
					LET l_rec_poaudit.jour_num = 0 
					LET l_rec_poaudit.year_num = p_rec_voucher.year_num 
					LET l_rec_poaudit.period_num = p_rec_voucher.period_num 
					LET l_rec_poaudit.line_total_amt = glob_rec_voucherdist.dist_amt 
					LET l_rec_poaudit.unit_tax_amt = l_rec_cu_poaudit.unit_tax_amt 
					LET l_rec_poaudit.ext_tax_amt = 
					l_rec_poaudit.voucher_qty * l_rec_poaudit.unit_tax_amt 

					#
					# Calculate the total item cost based on the distributed
					# amount AND quantity AND THEN calculate the implied unit cost
					# by subtracting unit tax.  Calculate the expected line total FOR
					# this quantity based on current cost
					#
					LET l_calc_cost_amt = glob_rec_voucherdist.dist_amt / glob_rec_voucherdist.trans_qty 
					LET l_unit_cost_amt = l_calc_cost_amt - l_rec_cu_poaudit.unit_tax_amt 
					LET l_calc_line_total_amt = glob_rec_voucherdist.trans_qty * (l_rec_cu_poaudit.unit_cost_amt + l_rec_cu_poaudit.unit_tax_amt) 
					#
					# IF the resulting line total equals the distribution amount, no
					# price change IS required - this eliminates problems due TO
					# rounding errors in price calculation.  IF the line totals are NOT
					# equal but the calculated unit price equals the current unit price,
					# there must be a discrepancy that IS too small TO be expressed
					# in unit price (eg. one OR two cents).  In this CASE, again there IS
					# no price change.  The VO line total IS SET TO the distributed amount.
					# Any discrepancies between ordered total AND invoiced total that are
					# too small TO be registered as a price change must be resolved in the
					# PO module. IF a price change IS required, calculate the upper AND
					# lower limits within which price changes are allowed.  Pass all the
					# relevant info TO the poaudit INSERT routine AND LET it create the
					# appropriate PU, IN AND JM adjustments.
					#
					#
					IF (l_calc_line_total_amt = glob_rec_voucherdist.dist_amt) OR (l_unit_cost_amt = l_rec_cu_poaudit.unit_cost_amt) THEN 
						LET l_rec_poaudit.unit_cost_amt = l_rec_cu_poaudit.unit_cost_amt 
						LET l_rec_poaudit.ext_cost_amt = l_rec_poaudit.voucher_qty * l_rec_poaudit.unit_cost_amt 
						LET l_price_change_status = 0 
					ELSE 
						LET l_rec_poaudit.unit_cost_amt = l_unit_cost_amt 
						LET l_rec_poaudit.ext_cost_amt = l_rec_poaudit.voucher_qty * l_rec_poaudit.unit_cost_amt 
						LET l_lower_limit = l_calc_line_total_amt * (1 -(l_rec_vendor.po_var_per/100)) 
						LET l_upper_limit = l_calc_line_total_amt * (1 +(l_rec_vendor.po_var_per/100)) 
						IF l_lower_limit < (l_calc_line_total_amt - l_rec_vendor.po_var_amt) THEN 
							LET l_lower_limit = 
							l_calc_line_total_amt - l_rec_vendor.po_var_amt 
						END IF 
						IF l_upper_limit > (l_calc_line_total_amt + l_rec_vendor.po_var_amt) THEN 
							LET l_upper_limit = l_calc_line_total_amt + l_rec_vendor.po_var_amt 
						END IF 
						CALL create_adjustments(l_rec_poaudit.*,l_rec_purchdetl.*,l_rec_cu_poaudit.* ,l_lower_limit,l_upper_limit,p_cmpy,p_kandoouser_sign_on_code) 
						RETURNING l_rec_purchdetl.seq_num, 
						l_db_status, 
						l_price_change_status, 
						l_price_err_mess 
					END IF 
					IF l_price_change_status = -2 THEN 
						LET l_err_message = l_price_err_mess 
						LET status = l_db_status 
						--GOTO recovery 
					END IF 
					IF l_price_change_status = -1 THEN 
						LET l_kandoo_log_msg = " " 
						LET l_kandoo_log_msg[001,065] = 
						"Voucher ", glob_rec_voucherdist.vouch_code USING "<<<<<<<<" clipped, 
						" PO ", glob_rec_voucherdist.po_num USING "<<<<<<<<" clipped, 
						" line ", glob_rec_voucherdist.po_line_num USING "<<<<<<<<" clipped, " price change failed" 
						CALL errorlog(l_kandoo_log_msg) 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt 
						- glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty 
						- glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
					ELSE 
						LET l_err_message = "P29 - Inserting PO Audit line" 
						LET l_rec_purchdetl.seq_num = l_rec_purchdetl.seq_num + 1 
						LET l_rec_poaudit.seq_num = l_rec_purchdetl.seq_num 
						INSERT INTO poaudit VALUES (l_rec_poaudit.*) 
						LET l_err_message = "P29 - Updating P.O. Line" 
						UPDATE purchdetl 
						SET seq_num = l_rec_purchdetl.seq_num 
						WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
							AND order_num = glob_rec_voucherdist.po_num 
							AND line_num = glob_rec_voucherdist.po_line_num 
						LET l_err_message = "P29 - Updating P.O. Header" 
						UPDATE purchhead 
						SET status_ind = "P" 
						WHERE cmpy_code = p_cmpy 
							AND order_num = l_rec_poaudit.po_num 
							AND vend_code = l_rec_poaudit.vend_code 
						LET l_err_message = 
						"P29 - Insert PO Voucher Dist Line" 
						INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
						CALL po_line_info(glob_rec_voucherdist.cmpy_code, glob_rec_voucherdist.po_num, glob_rec_voucherdist.po_line_num) 
						RETURNING l_rec_cx_poaudit.order_qty, 
							l_rec_cx_poaudit.received_qty, 
							l_rec_cx_poaudit.voucher_qty, 
							l_rec_cx_poaudit.unit_cost_amt, 
							l_rec_cx_poaudit.ext_cost_amt, 
							l_rec_cx_poaudit.unit_tax_amt, 
							l_rec_cx_poaudit.ext_tax_amt, 
							l_rec_cx_poaudit.line_total_amt 
						LET l_onorder_amt = l_rec_cu_poaudit.line_total_amt - l_rec_cx_poaudit.line_total_amt + ((l_rec_cx_poaudit.voucher_qty - l_rec_cu_poaudit.voucher_qty) * (l_rec_cx_poaudit.unit_cost_amt + l_rec_cx_poaudit.unit_tax_amt)) 
						UPDATE vendor 
						SET onorder_amt = onorder_amt - l_onorder_amt 
						WHERE cmpy_code = p_rec_voucher.cmpy_code 
						AND vend_code = l_rec_purchdetl.vend_code 
					END IF 
					SELECT * INTO l_rec_activity.* 
					FROM activity 
					WHERE cmpy_code = p_cmpy 
						AND job_code = l_rec_purchdetl.job_code 
						AND var_code = l_rec_purchdetl.var_num 
						AND activity_code = l_rec_purchdetl.activity_code 
					UPDATE jobledger 
					SET year_num = p_rec_voucher.year_num, 
						period_num = p_rec_voucher.period_num, 
						posted_flag = "P", 
						ref_num = p_rec_voucher.vouch_code 
					WHERE cmpy_code = p_cmpy 
						AND job_code = l_rec_purchdetl.job_code 
						AND var_code = l_rec_purchdetl.var_num 
						AND activity_code = l_rec_purchdetl.activity_code 
						AND seq_num = l_rec_activity.seq_num 
				WHEN "J" 
					LET l_err_message = "P29 - Locking JM Activity FOR Update" 
					DECLARE c1_activity CURSOR FOR 
					SELECT * FROM activity 
					WHERE cmpy_code = p_cmpy 
						AND job_code = glob_rec_voucherdist.job_code 
						AND var_code = glob_rec_voucherdist.var_code 
						AND activity_code = glob_rec_voucherdist.act_code 
						AND finish_flag = "N" 
					FOR UPDATE 
					OPEN c1_activity 
					FETCH c1_activity INTO l_rec_activity.* 
					IF status = 0 THEN 
						LET l_err_message = "P29 - Insert JM Jobledger" 
						LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
						LET l_rec_jobledger.cmpy_code = p_cmpy 
						LET l_rec_jobledger.trans_date = p_rec_voucher.vouch_date 
						LET l_rec_jobledger.year_num = p_rec_voucher.year_num 
						LET l_rec_jobledger.period_num = p_rec_voucher.period_num 
						LET l_rec_jobledger.job_code = glob_rec_voucherdist.job_code 
						LET l_rec_jobledger.var_code = glob_rec_voucherdist.var_code 
						LET l_rec_jobledger.activity_code = glob_rec_voucherdist.act_code 
						LET l_rec_jobledger.allocation_ind = glob_rec_voucherdist.allocation_ind 
						LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
						LET l_rec_jobledger.trans_type_ind = "VO" 
						LET l_rec_jobledger.trans_source_num=p_rec_voucher.vouch_code 
						LET l_rec_jobledger.trans_source_text= glob_rec_voucherdist.res_code 
						IF p_rec_voucher.conv_qty != 0 THEN 
							LET l_rec_jobledger.trans_amt = glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty 
						ELSE 
							LET l_rec_jobledger.trans_amt = glob_rec_voucherdist.dist_amt 
						END IF 
						LET l_rec_jobledger.trans_qty = glob_rec_voucherdist.trans_qty 
						LET l_rec_jobledger.charge_amt = glob_rec_voucherdist.charge_amt * glob_rec_voucherdist.trans_qty 
						LET l_rec_jobledger.posted_flag = "P" 
						LET l_rec_jobledger.desc_text = glob_rec_voucherdist.desc_text 
						LET l_rec_jobledger.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_jobledger.entry_date = today 
						LET l_rec_jobledger.ref_num = p_rec_voucher.vouch_code 
						INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
						LET l_err_message = "P29 - Update JM Activity" 
						UPDATE activity 
						SET seq_num = l_rec_activity.seq_num, 
							act_cost_amt = act_cost_amt + l_rec_jobledger.trans_amt, 
							act_cost_qty = act_cost_qty + l_rec_jobledger.trans_qty, 
							post_revenue_amt = post_revenue_amt + l_rec_jobledger.charge_amt 
						WHERE cmpy_code = glob_rec_voucherdist.cmpy_code 
							AND job_code = glob_rec_voucherdist.job_code 
							AND var_code = glob_rec_voucherdist.var_code 
							AND activity_code = glob_rec_voucherdist.act_code 
						LET l_err_message = "P29 - Insert JM Voucher Dist.Lines" 
						INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
					ELSE 
						LET l_kandoo_log_msg = " " 
						LET l_kandoo_log_msg[001,060] = 
						"Voucher ", glob_rec_voucherdist.vouch_code USING "<<<<<<<<" clipped, 
						" line ", glob_rec_voucherdist.line_num USING "<<<<<" clipped, 
						" Job ", glob_rec_voucherdist.job_code clipped, 
						" Activity ", glob_rec_voucherdist.act_code clipped 
						LET l_kandoo_log_msg[061, 075] = " does NOT exist" 
						CALL errorlog(l_kandoo_log_msg) 

						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt - glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
					END IF 

				WHEN "S" 
					LET l_err_message = "P29 - Locking shiphead FOR UPDATE" 
					DECLARE c1_shiphead CURSOR FOR 
					SELECT * 
					FROM shiphead 
					WHERE cmpy_code = p_cmpy 
						AND ship_code = glob_rec_voucherdist.job_code 
					FOR UPDATE 
					OPEN c1_shiphead 
					FETCH c1_shiphead INTO l_rec_shiphead.* 
					IF status = 0 THEN 
						SELECT class_ind INTO l_class_ind 
						FROM shipcosttype 
						WHERE cmpy_code = p_cmpy 
							AND cost_type_code = glob_rec_voucherdist.res_code 
						CASE l_class_ind 
							WHEN '1' 
								LET l_rec_shiphead.fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt + glob_rec_voucherdist.dist_amt 
								LET l_rec_shiphead.fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt + ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '2' 
								LET l_rec_shiphead.duty_inv_amt = l_rec_shiphead.duty_inv_amt + ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '3' 
								LET l_rec_shiphead.other_cost_amt = l_rec_shiphead.other_cost_amt + ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
							WHEN '4' 
								LET l_rec_shiphead.late_cost_amt = l_rec_shiphead.late_cost_amt + ( glob_rec_voucherdist.dist_amt / p_rec_voucher.conv_qty ) 
						END CASE 

						UPDATE shiphead 
						SET voucher_flag = "Y", 
							fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt, 
							fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt, 
							duty_inv_amt = l_rec_shiphead.duty_inv_amt, 
							late_cost_amt = l_rec_shiphead.late_cost_amt, 
							other_cost_amt = l_rec_shiphead.other_cost_amt 
						WHERE cmpy_code = p_cmpy 
						AND ship_code = glob_rec_voucherdist.job_code 

						LET l_err_message = "P29 - Insert Ship Vouch Dist.Lines" 
						INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
					ELSE 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt - glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
					END IF 

				WHEN "W" 
					LET l_err_message = "P29 - Locking Ordhead FOR UPDATE" 
					DECLARE c1_ordhead CURSOR FOR 
					SELECT * 
					FROM ordhead 
					WHERE cmpy_code = p_cmpy 
						AND order_num = glob_rec_voucherdist.po_num 
					FOR UPDATE 
					OPEN c1_ordhead 
					FETCH c1_ordhead INTO glob_rec_ordhead.* 
					IF status != NOTFOUND THEN 
						IF glob_rec_voucherdist.desc_text IS NOT NULL THEN 
							LET l_err_message = "P29 - Locking orderline FOR UPDATE" 
							DECLARE c1_orderline CURSOR FOR 
							SELECT order_num,line_num, ext_cost_amt 
							FROM orderline 
							WHERE order_num = glob_rec_voucherdist.po_num 
								AND part_code IS NULL 
								AND desc_text = glob_rec_voucherdist.desc_text 
								AND cmpy_code = p_cmpy 
							FOR UPDATE 
							OPEN c1_orderline 
							FETCH c1_orderline INTO glob_rec_orderline.order_num, glob_rec_orderline.line_num, glob_rec_orderline.ext_cost_amt 
							IF status != NOTFOUND THEN 
								IF glob_rec_voucherdist.allocation_ind = "Y" THEN 
									LET glob_rec_orderline.status_ind = "C" 
								ELSE 
									LET glob_rec_orderline.status_ind = "0" 
								END IF 
								UPDATE orderline 
								SET ext_cost_amt = ext_cost_amt + glob_rec_voucherdist.dist_amt, 
								status_ind = glob_rec_orderline.status_ind 
								WHERE order_num = glob_rec_orderline.order_num 
									AND line_num = glob_rec_orderline.line_num 
									AND cmpy_code = p_cmpy 

								LET l_err_message = "P29 - Update Ordhead " 
								UPDATE ordhead 
								SET export_cost_amt = export_cost_amt + glob_rec_voucherdist.dist_amt 
								WHERE cmpy_code = p_cmpy 
									AND order_num = glob_rec_ordhead.order_num 
							ELSE 
								# need TO INSERT an ORDER line here
								# Insert orderline FOR new additional charge
								CALL initialise_orderline(p_cmpy,p_kandoouser_sign_on_code) 
								LET l_err_message = "P29 - Insert Orderline " 
								INSERT INTO orderline VALUES (glob_rec_orderline.*) 
								LET l_err_message = "P29 - Update Ordhead " 
								UPDATE ordhead 
								SET export_cost_amt = export_cost_amt + glob_rec_voucherdist.dist_amt, 
								line_num = glob_rec_ordhead.line_num 
								WHERE cmpy_code = p_cmpy 
									AND order_num = glob_rec_ordhead.order_num 
							END IF 
							LET l_err_message = "P29 -Insert WO Voucher Dist.Lines" 
							INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
						ELSE 
							LET l_err_message = "P29 - Update Ordhead " 
							UPDATE ordhead 
							SET export_cost_amt = export_cost_amt + glob_rec_voucherdist.dist_amt, 
							line_num = glob_rec_ordhead.line_num 
							WHERE cmpy_code = p_cmpy 
								AND order_num = glob_rec_ordhead.order_num 
							LET l_err_message = "P29 -Insert WO Voucher Dist.Lines" 
							INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
						END IF 
					ELSE 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt - glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty - glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
					END IF 

				WHEN "A" 
					# AR Updates

					SELECT * INTO l_rec_customer.* 
					FROM customer 
					WHERE cmpy_code = p_cmpy 
						AND cust_code = glob_rec_voucherdist.res_code 
					LET l_rec_invoicehead.total_amt = glob_rec_voucherdist.dist_amt + glob_rec_voucherdist.cost_amt + glob_rec_voucherdist.charge_amt 
					LET l_rec_invoicehead.inv_num = glob_rec_voucherdist.po_num 
					LET l_rec_invoicehead.inv_date = glob_rec_voucherdist.job_code 
					LET l_rec_invoicehead.cust_code = glob_rec_voucherdist.res_code 
					LET l_rec_invoicehead.purchase_code = glob_rec_voucherdist.analysis_text 
					LET l_rec_invoicehead.year_num = p_rec_voucher.year_num 
					LET l_rec_invoicehead.period_num = p_rec_voucher.period_num 
					LET l_rec_invoicehead.tax_code = l_rec_customer.tax_code 
					LET l_rec_invoicehead.term_code = l_rec_customer.term_code 
					LET l_rec_invoicehead.com1_text = glob_rec_voucherdist.desc_text 
					LET l_rec_invoicehead.goods_amt = glob_rec_voucherdist.dist_amt 
					LET l_rec_invoicehead.hand_amt = glob_rec_voucherdist.charge_amt 
					LET l_rec_invoicehead.tax_amt = glob_rec_voucherdist.cost_amt 
					IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
						LET l_cust_code = l_rec_customer.corp_cust_code 
						LET l_rec_invoicehead.org_cust_code = 
						l_rec_invoicehead.cust_code 
					ELSE 
						LET l_cust_code = l_rec_customer.cust_code 
						LET l_rec_invoicehead.org_cust_code = NULL 
					END IF 
					SELECT * INTO l_rec_tax.* 
					FROM tax 
					WHERE tax_code = l_rec_invoicehead.tax_code 
						AND cmpy_code = p_cmpy 
					DECLARE c2_customer CURSOR FOR 
					SELECT * 
					FROM customer 
					WHERE cmpy_code = p_cmpy 
						AND cust_code = l_cust_code 
					FOR UPDATE 
					OPEN c2_customer 
					FETCH c2_customer INTO l_rec_customer.* 
					SELECT * 
					FROM invoicehead 
					WHERE cmpy_code = p_cmpy 
						AND inv_num = glob_rec_voucherdist.po_num 
					IF status = 0 THEN 
						UPDATE invoicehead 
						SET sale_code = l_rec_invoicehead.sale_code, 
						term_code = l_rec_invoicehead.term_code, 
						tax_code = l_rec_invoicehead.tax_code, 
						goods_amt = l_rec_invoicehead.goods_amt, 
						hand_amt = l_rec_invoicehead.hand_amt, 
						tax_amt = l_rec_invoicehead.tax_amt, 
						total_amt = l_rec_invoicehead.total_amt, 
						year_num = l_rec_invoicehead.year_num, 
						period_num = l_rec_invoicehead.period_num, 
						inv_date = l_rec_invoicehead.inv_date, 
						currency_code = l_rec_invoicehead.currency_code, 
						com1_text = l_rec_invoicehead.com1_text, 
						purchase_code = l_rec_invoicehead.purchase_code 
						WHERE cmpy_code = p_cmpy 
							AND inv_num = glob_rec_voucherdist.po_num 
							AND cust_code = glob_rec_voucherdist.res_code 
						UPDATE invoicedetl 
						SET invoicedetl.unit_sale_amt = l_rec_invoicehead.goods_amt, 
							invoicedetl.unit_tax_amt = l_rec_invoicehead.tax_amt, 
							invoicedetl.line_total_amt = l_rec_invoicehead.goods_amt + l_rec_invoicehead.tax_amt, 
							invoicedetl.ext_sale_amt = l_rec_invoicehead.goods_amt, 
							invoicedetl.ext_tax_amt = l_rec_invoicehead.tax_amt, 
							invoicedetl.line_text = l_rec_invoicehead.com1_text 
						WHERE cmpy_code = p_cmpy 
							AND inv_num = glob_rec_voucherdist.po_num 
							AND line_num = 1 
					ELSE 
						LET l_rec_invoicehead.cust_code = l_cust_code 
						LET l_rec_invoicehead.cmpy_code = p_cmpy 
						LET l_rec_invoicehead.ord_num = NULL 
						LET l_rec_invoicehead.job_code = NULL 
						LET l_rec_invoicehead.entry_code = p_kandoouser_sign_on_code 
						LET l_rec_invoicehead.entry_date = today 
						LET l_rec_invoicehead.sale_code = l_rec_customer.sale_code 
						LET l_rec_invoicehead.currency_code = l_rec_customer.currency_code 
						LET l_rec_invoicehead.invoice_to_ind =l_rec_customer.invoice_to_ind 
						LET l_rec_invoicehead.territory_code =l_rec_customer.territory_code 
						LET l_rec_invoicehead.scheme_amt = 0 
						LET l_rec_invoicehead.jour_num = NULL 
						LET l_rec_invoicehead.post_date = NULL 
						LET l_rec_invoicehead.manifest_num = NULL 
						LET l_rec_invoicehead.stat_date = NULL 
						LET l_rec_invoicehead.line_num = 1 
						LET l_rec_invoicehead.rev_date = l_rec_invoicehead.entry_date 
						LET l_rec_invoicehead.name_text = l_rec_customer.name_text 
						LET l_rec_invoicehead.ship_code = l_rec_customer.cust_code 
						LET l_rec_invoicehead.addr1_text = l_rec_customer.addr1_text 
						LET l_rec_invoicehead.addr2_text = l_rec_customer.addr2_text 
						LET l_rec_invoicehead.city_text = l_rec_customer.city_text 
						LET l_rec_invoicehead.state_code = l_rec_customer.state_code 
						LET l_rec_invoicehead.post_code = l_rec_customer.post_code 
						LET l_rec_invoicehead.country_code = l_rec_customer.country_code --@db-patch_2020_10_04-- 
						LET l_rec_invoicehead.contact_text = l_rec_customer.contact_text 
						LET l_rec_invoicehead.tele_text = l_rec_customer.tele_text 
						LET l_rec_invoicehead.hand_tax_amt = 0 
						LET l_rec_invoicehead.freight_amt = 0 
						LET l_rec_invoicehead.freight_tax_amt = 0 
						LET l_rec_invoicehead.tax_per = l_rec_tax.tax_per 
						LET l_rec_invoicehead.disc_amt = 0 
						LET l_rec_invoicehead.paid_amt = 0 
						LET l_rec_invoicehead.paid_date = NULL 
						LET l_rec_invoicehead.disc_taken_amt = 0 
						LET l_rec_invoicehead.disc_per = 0 
						LET l_rec_invoicehead.cost_amt = 0 
						LET l_rec_invoicehead.acct_override_code = glob_rec_voucherdist.acct_code 
						LET l_rec_invoicehead.conv_qty = 
						get_conv_rate(p_cmpy, l_rec_invoicehead.currency_code, 
						l_rec_invoicehead.inv_date,"S") 
						LET l_rec_invoicedetl.tax_code = l_rec_invoicehead.tax_code 

						#==> continue here reformatting 20210124 ericv
						IF l_rec_invoicehead.term_code IS NOT NULL THEN 
						
							CALL db_term_get_rec(UI_OFF,l_rec_invoicehead.term_code) RETURNING l_rec_term.*
							
							CALL get_due_and_discount_date(l_rec_term.*,l_rec_invoicehead.inv_date) 
							RETURNING l_rec_invoicehead.due_date, l_rec_invoicehead.disc_date 

							LET l_rec_invoicehead.disc_per = l_rec_term.disc_per 
						END IF
						 
						LET l_rec_invoicehead.ship_date = l_rec_invoicehead.inv_date 
						LET l_rec_invoicehead.prepaid_flag = "P" 
						LET l_rec_invoicehead.seq_num = 0 
						LET l_rec_invoicehead.on_state_flag = "N" 
						LET l_rec_invoicehead.posted_flag = "N" 
						LET l_rec_invoicehead.inv_ind = "P" 
						LET l_rec_invoicehead.printed_num = 1 
						LET l_rec_invoicedetl.cmpy_code = p_cmpy 
						LET l_rec_invoicedetl.ship_qty = 1 
						LET l_rec_invoicedetl.sold_qty = l_rec_invoicedetl.ship_qty 
						LET l_rec_invoicedetl.line_num = 1 
						LET l_rec_invoicedetl.level_code = 1 
						LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicehead.goods_amt 
						LET l_rec_invoicedetl.unit_tax_amt = l_rec_invoicehead.tax_amt 
						LET l_rec_invoicedetl.ext_sale_amt = l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_sale_amt 
						LET l_rec_invoicedetl.ext_tax_amt = l_rec_invoicedetl.sold_qty * 	l_rec_invoicedetl.unit_tax_amt 
						LET l_rec_invoicedetl.line_total_amt = 	l_rec_invoicedetl.ext_sale_amt + l_rec_invoicedetl.ext_tax_amt 
						LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
						LET l_rec_invoicedetl.order_line_num = NULL 
						LET l_rec_invoicedetl.order_num = NULL 
						LET l_rec_invoicedetl.ord_qty = 1 
						LET l_rec_invoicedetl.back_qty = 0 
						LET l_rec_invoicedetl.prev_qty = 0 
						LET l_rec_invoicedetl.ser_flag = "N" 
						LET l_rec_invoicedetl.ser_qty = 0 
						LET l_rec_invoicedetl.unit_cost_amt = 0 
						LET l_rec_invoicedetl.ext_cost_amt = 0 
						LET l_rec_invoicedetl.disc_amt = 0 
						LET l_rec_invoicedetl.ext_bonus_amt = 0 
						LET l_rec_invoicedetl.ext_stats_amt = 0 
						LET l_rec_invoicedetl.disc_per = 0 
						LET l_rec_invoicedetl.line_text = l_rec_invoicehead.com1_text 
						LET l_rec_invoicedetl.line_acct_code = 
						glob_rec_voucherdist.acct_code 
						LET l_rec_invoicehead.inv_num = next_trans_num(p_cmpy, "IN",l_rec_invoicehead.acct_override_code) 
						IF l_rec_invoicehead.inv_num < 0 THEN 
							LET l_err_message = "P29 - Next invoice number UPDATE" 
							LET status = l_rec_invoicehead.inv_num 
							--GOTO recovery 
						END IF 
						LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
						LET l_err_message = "P29 - invoice line addition failed" 
						INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*) 
						LET l_err_message = 
						"P29 - Unable TO add TO invoice header table" 
						INSERT INTO invoicehead VALUES (l_rec_invoicehead.*) 
					END IF 
					LET l_err_message = "P29 - Customer Update Inv" 
					LET l_rec_customer.next_seq_num = l_rec_customer.next_seq_num + 1 
					LET l_rec_customer.bal_amt = l_rec_customer.bal_amt 
					+ l_rec_invoicehead.total_amt 
					LET l_rec_customer.curr_amt = l_rec_customer.curr_amt + l_rec_invoicehead.total_amt 
					INITIALIZE l_rec_araudit.* TO NULL 
					LET l_rec_araudit.cmpy_code = p_cmpy 
					LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
					LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
					LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num 
					LET l_rec_araudit.tran_type_ind = "IN" 
					LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
					LET l_rec_araudit.tran_text = "Adjustment" 
					LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
					LET l_rec_araudit.entry_code = p_kandoouser_sign_on_code 
					LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
					LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
					LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
					LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
					LET l_rec_araudit.currency_code = l_rec_customer.currency_code 
					LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
					LET l_rec_araudit.entry_date = today 
					LET l_err_message = "P29 - Unable TO add TO AR log table " 
					INSERT INTO araudit VALUES (l_rec_araudit.*) 
					IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
						LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
					END IF 
					LET l_rec_customer.cred_bal_amt = 
					l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
					IF year(l_rec_invoicehead.inv_date) 
					> year(l_rec_customer.last_inv_date) THEN 
						LET l_rec_customer.ytds_amt = 0 
					END IF 
					LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt + l_rec_invoicehead.total_amt 
					IF (month(l_rec_invoicehead.inv_date) > month(l_rec_customer.last_inv_date) OR year(l_rec_invoicehead.inv_date) > year(l_rec_customer.last_inv_date)) THEN 
						LET l_rec_customer.mtds_amt = 0 
					END IF 
					LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt + l_rec_invoicehead.total_amt 
					LET l_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
					LET l_err_message = "P29 - Custmain actual UPDATE " 
					UPDATE customer 
					SET next_seq_num = l_rec_customer.next_seq_num, 
					bal_amt = l_rec_customer.bal_amt, 
					curr_amt = l_rec_customer.curr_amt, 
					highest_bal_amt = l_rec_customer.highest_bal_amt, 
					cred_bal_amt = l_rec_customer.cred_bal_amt, 
					last_inv_date = l_rec_customer.last_inv_date, 
					ytds_amt = l_rec_customer.ytds_amt, 
					mtds_amt = l_rec_customer.mtds_amt 
					WHERE CURRENT OF c2_customer 
					CLOSE c2_customer 
					LET glob_rec_voucherdist.po_num = l_rec_invoicehead.inv_num 
					LET glob_rec_voucherdist.po_line_num = 1 
					LET glob_rec_voucherdist.trans_qty = 1 
					LET l_err_message = "P29 - Insert OE Voucher Dist.Lines" 
					INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 

					###################### END AR Updates
				WHEN "G" 
					LET l_err_message = "P29 - Insert GL Voucher Dist.Lines" 
					CALL check_funds(p_cmpy, 
					glob_rec_voucherdist.acct_code, 
					glob_rec_voucherdist.dist_amt, 
					glob_rec_voucherdist.line_num, 
					p_rec_voucher.year_num, 
					p_rec_voucher.period_num, 
					"P", 
					glob_rec_voucherdist.vouch_code, 
					"N") 
					RETURNING l_valid_tran, l_available_amt 
					IF NOT l_valid_tran THEN 
						IF l_error_disp_flag THEN 
							# Only want TO DISPLAY error MESSAGE once.
							LET l_msgresp = kandoomsg("U",9939,"") 
							#9939 Capital account(s) have insufficient funds ...
							LET l_error_disp_flag = false 
						END IF 
						LET p_rec_voucher.dist_amt = p_rec_voucher.dist_amt 
						- glob_rec_voucherdist.dist_amt 
						LET p_rec_voucher.dist_qty = p_rec_voucher.dist_qty 
						- glob_rec_voucherdist.dist_qty 
						DELETE FROM t_voucherdist 
						WHERE line_num = glob_rec_voucherdist.line_num 
						LET l_err_cnt = l_err_cnt + 1 
					ELSE 
						INSERT INTO voucherdist VALUES (glob_rec_voucherdist.*) 
					END IF 
			END CASE 
			DELETE FROM t_voucherdist 
			WHERE line_num = glob_rec_voucherdist.line_num 
		END FOREACH 
		LET l_err_message = "P29 - Update Voucher Dist. Amounts" 
		UPDATE voucher 
		SET dist_amt = p_rec_voucher.dist_amt, 
		dist_qty = p_rec_voucher.dist_qty, 
		line_num = p_rec_voucher.line_num 
		WHERE cmpy_code = p_rec_voucher.cmpy_code 
		AND vouch_code = p_rec_voucher.vouch_code 
	END IF 
	IF p_rec_vouchpayee.vend_code IS NOT NULL THEN 
		# Need TO UPDATE the voucher payee details FOR a Sundry Vendor
		LET l_err_message = "P29 - Update Voucher Payee Details" 
		UPDATE vouchpayee 
		SET * = p_rec_vouchpayee.* 
		WHERE vend_code = p_rec_vouchpayee.vend_code 
		AND vouch_code = p_rec_vouchpayee.vouch_code 
		AND cmpy_code = p_rec_vouchpayee.cmpy_code 
		IF sqlca.sqlerrd[3] = 0 THEN 
			LET l_err_message = "P29 - Inserting Voucher Payee Details" 
			LET p_rec_vouchpayee.vouch_code = p_rec_voucher.vouch_code 
			INSERT INTO vouchpayee VALUES (p_rec_vouchpayee.*) 
		END IF 
	END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
	## Similar TO batch entry there are three possible states
	##  zero - No UPDATE
	##  pos vouch_num - Voucher/Vendor Update
	##  neg vouch_num - Voucher/Vendor Distributions
	IF l_err_cnt > 0 THEN 
		RETURN (0 - p_rec_voucher.vouch_code) 
	ELSE 
		RETURN p_rec_voucher.vouch_code 
	END IF 
END FUNCTION  # update_voucher_related_tables


############################################################
# FUNCTION create_adjustments(p_rec_poaudit,
#                            p_rec_purchdetl,
#                            p_rec_cu_poaudit,
#                            p_lower_limit,
#                            p_upper_limit,
#                            p_cmpy,
#                            p_whom)
#
# new poaudit UPDATE AND INSERT routine
############################################################
FUNCTION create_adjustments(p_rec_poaudit,p_rec_purchdetl,p_rec_cu_poaudit,p_lower_limit,p_upper_limit,p_cmpy,p_whom) 
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE p_rec_cu_poaudit RECORD LIKE poaudit.* 
	DEFINE p_lower_limit LIKE poaudit.line_total_amt 
	DEFINE p_upper_limit LIKE poaudit.line_total_amt 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE l_rec_t_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_cs_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_activity_seq_num LIKE activity.seq_num 
	DEFINE l_trans_amt_out LIKE jobledger.trans_amt 
	DEFINE l_trans_amt_in LIKE jobledger.trans_amt 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_db_status INTEGER 
	DEFINE l_prod_status SMALLINT 
	DEFINE l_old_onorder_amt LIKE vendor.onorder_amt 
	DEFINE l_new_onorder_amt LIKE vendor.onorder_amt 

	GOTO bypass 
	LABEL recovery: 
	RETURN 0, status, -2, l_err_message 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	#
	# Price change cannot be allowed IF the value IS outside the acceptable
	# range FOR the vendor OR IF the item has been invoiced by another
	# user WHILE the INPUT phase was in progress.
	#
	IF p_rec_poaudit.line_total_amt < p_lower_limit OR 
	p_rec_poaudit.line_total_amt > p_upper_limit OR 
	p_rec_cu_poaudit.voucher_qty > 0 THEN 
		RETURN 0, 0, -1, "" 
	END IF 
	#
	# IF the price change meets the constraints, we need the following
	# additional poaudit transactions:
	# CP with -ve ORDER quantity AT original price, TO reverse any
	# prior commitment account postings.
	# CP with +ve ORDER quantity TO reflect the new price AND post TO the
	# commitment account.
	# GA with -ve received quantity AT the original price, TO reverse the
	# goods on ORDER posting.
	# GA with +ve received quantity TO reflect the new price in the goods
	# on ORDER account.
	# Note: p_rec_cu_poaudit holds current VALUES of price AND quantity,
	# p_rec_poaudit holds the new voucher totals
	#
	LET l_old_onorder_amt = 0 
	LET l_new_onorder_amt = 0 
	LET l_rec_t_poaudit.* = p_rec_poaudit.* 
	LET l_rec_t_poaudit.tran_num = 0 
	LET l_rec_t_poaudit.orig_auth_flag = "Y" 
	LET l_rec_t_poaudit.now_auth_flag = "Y" 
	LET l_err_message = "P29 - inserting CP PO audit line" 
	LET l_rec_t_poaudit.tran_code = "CP" 
	LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
	LET l_rec_t_poaudit.seq_num = p_rec_purchdetl.seq_num 
	LET l_rec_t_poaudit.order_qty = 0 - p_rec_cu_poaudit.order_qty 
	LET l_rec_t_poaudit.received_qty = 0 
	LET l_rec_t_poaudit.voucher_qty = 0 
	LET l_rec_t_poaudit.unit_cost_amt = p_rec_cu_poaudit.unit_cost_amt 
	LET l_rec_t_poaudit.ext_cost_amt = 
	l_rec_t_poaudit.unit_cost_amt * l_rec_t_poaudit.order_qty 
	LET l_rec_t_poaudit.unit_tax_amt = p_rec_cu_poaudit.unit_tax_amt 
	LET l_rec_t_poaudit.ext_tax_amt = 
	l_rec_t_poaudit.unit_tax_amt * l_rec_t_poaudit.order_qty 
	LET l_rec_t_poaudit.line_total_amt = 
	l_rec_t_poaudit.ext_cost_amt + l_rec_t_poaudit.ext_tax_amt 
	INSERT INTO poaudit VALUES (l_rec_t_poaudit.*) 
	# Now UPDATE the list cost amount FOR purchase detail
	LET l_err_message = "P29 - updating PO line list cost amount" 
	LET p_rec_purchdetl.list_cost_amt 
	= p_rec_poaudit.unit_cost_amt / (1 - (p_rec_purchdetl.disc_per / 100)) 
	UPDATE purchdetl 
	SET list_cost_amt = p_rec_purchdetl.list_cost_amt 
	WHERE cmpy_code = l_rec_t_poaudit.cmpy_code 
	AND order_num = l_rec_t_poaudit.po_num 
	AND line_num = l_rec_t_poaudit.line_num 
	LET l_err_message = "P29 - inserting 2nd CP PO audit line" 
	LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
	LET l_rec_t_poaudit.seq_num = p_rec_purchdetl.seq_num 
	LET l_rec_t_poaudit.order_qty = p_rec_cu_poaudit.order_qty 
	LET l_rec_t_poaudit.received_qty = 0 
	LET l_rec_t_poaudit.voucher_qty = 0 
	LET l_rec_t_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
	LET l_rec_t_poaudit.ext_cost_amt = 
	l_rec_t_poaudit.unit_cost_amt * l_rec_t_poaudit.order_qty 
	LET l_rec_t_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt 
	LET l_rec_t_poaudit.ext_tax_amt = 
	l_rec_t_poaudit.unit_tax_amt * l_rec_t_poaudit.order_qty 
	LET l_rec_t_poaudit.line_total_amt = 
	l_rec_t_poaudit.ext_cost_amt + l_rec_t_poaudit.ext_tax_amt 
	INSERT INTO poaudit VALUES (l_rec_t_poaudit.*) 
	LET l_err_message = "P29 - inserting GA PO audit line" 
	LET l_rec_t_poaudit.tran_code = "GA" 
	LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
	LET l_rec_t_poaudit.seq_num = p_rec_purchdetl.seq_num 
	LET l_rec_t_poaudit.order_qty = 0 
	LET l_rec_t_poaudit.received_qty = 0 - p_rec_cu_poaudit.received_qty 
	LET l_rec_t_poaudit.voucher_qty = 0 
	LET l_rec_t_poaudit.unit_cost_amt = p_rec_cu_poaudit.unit_cost_amt 
	LET l_rec_t_poaudit.ext_cost_amt 
	= l_rec_t_poaudit.unit_cost_amt * l_rec_t_poaudit.received_qty 
	LET l_rec_t_poaudit.unit_tax_amt = p_rec_cu_poaudit.unit_tax_amt 
	LET l_rec_t_poaudit.ext_tax_amt 
	= l_rec_t_poaudit.unit_tax_amt * l_rec_t_poaudit.received_qty 
	LET l_rec_t_poaudit.line_total_amt 
	= l_rec_t_poaudit.ext_cost_amt + l_rec_t_poaudit.ext_tax_amt 
	INSERT INTO poaudit VALUES (l_rec_t_poaudit.*) 
	LET p_rec_purchdetl.seq_num = p_rec_purchdetl.seq_num + 1 
	LET l_rec_t_poaudit.seq_num = p_rec_purchdetl.seq_num 
	LET l_rec_t_poaudit.order_qty = 0 
	LET l_rec_t_poaudit.received_qty = p_rec_cu_poaudit.received_qty 
	LET l_rec_t_poaudit.voucher_qty = 0 
	LET l_rec_t_poaudit.unit_cost_amt = p_rec_poaudit.unit_cost_amt 
	LET l_rec_t_poaudit.ext_cost_amt 
	= l_rec_t_poaudit.unit_cost_amt * l_rec_t_poaudit.received_qty 
	LET l_rec_t_poaudit.unit_tax_amt = p_rec_poaudit.unit_tax_amt 
	LET l_rec_t_poaudit.ext_tax_amt 
	= l_rec_t_poaudit.unit_tax_amt * l_rec_t_poaudit.received_qty 
	LET l_rec_t_poaudit.line_total_amt 
	= l_rec_t_poaudit.ext_cost_amt + l_rec_t_poaudit.ext_tax_amt 
	INSERT INTO poaudit VALUES (l_rec_t_poaudit.*) 
	CALL po_line_info(p_rec_poaudit.cmpy_code, 
	p_rec_purchdetl.order_num, 
	p_rec_purchdetl.line_num) 
	RETURNING l_rec_cs_poaudit.order_qty, 
	l_rec_cs_poaudit.received_qty, 
	l_rec_cs_poaudit.voucher_qty, 
	l_rec_cs_poaudit.unit_cost_amt, 
	l_rec_cs_poaudit.ext_cost_amt, 
	l_rec_cs_poaudit.unit_tax_amt, 
	l_rec_cs_poaudit.ext_tax_amt, 
	l_rec_cs_poaudit.line_total_amt 
	#
	# IF the purchase ORDER line IS a Job Management type, the job ledger
	# entries need TO be reversed AND re-entered AT the new price AND the
	# activity RECORD updated
	#
	IF p_rec_purchdetl.type_ind = "J" OR p_rec_purchdetl.type_ind = "C" THEN 
		DECLARE c2_activity CURSOR FOR 
		SELECT seq_num 
		FROM activity 
		WHERE cmpy_code = p_cmpy 
		AND job_code = p_rec_purchdetl.job_code 
		AND var_code = p_rec_purchdetl.var_num 
		AND activity_code = p_rec_purchdetl.activity_code 
		FOR UPDATE 
		OPEN c2_activity 
		FETCH c2_activity INTO l_activity_seq_num 
		LET l_err_message = "P29 - inserting job ledger line" 
		LET l_activity_seq_num = l_activity_seq_num + 1 
		LET l_rec_jobledger.cmpy_code = p_cmpy 
		LET l_rec_jobledger.trans_date = p_rec_poaudit.tran_date 
		LET l_rec_jobledger.year_num = p_rec_poaudit.year_num 
		LET l_rec_jobledger.period_num = p_rec_poaudit.period_num 
		LET l_rec_jobledger.job_code = p_rec_purchdetl.job_code 
		LET l_rec_jobledger.var_code = p_rec_purchdetl.var_num 
		LET l_rec_jobledger.activity_code = p_rec_purchdetl.activity_code 
		LET l_rec_jobledger.seq_num = l_activity_seq_num 
		LET l_rec_jobledger.trans_type_ind = "PU" 
		LET l_rec_jobledger.trans_source_num = p_rec_poaudit.po_num 
		LET l_rec_jobledger.trans_source_text = p_rec_purchdetl.res_code 
		LET l_rec_jobledger.trans_qty = 0 - p_rec_cu_poaudit.received_qty 
		LET l_rec_jobledger.trans_amt = l_rec_jobledger.trans_qty * 
		p_rec_cu_poaudit.unit_cost_amt 
		LET l_trans_amt_out = l_rec_jobledger.trans_amt 
		LET l_rec_jobledger.charge_amt = p_rec_purchdetl.charge_amt 
		* l_rec_jobledger.trans_qty 
		LET l_rec_jobledger.posted_flag = "P" 
		LET l_rec_jobledger.desc_text = p_rec_poaudit.desc_text 

		SELECT * 
		INTO l_rec_jmresource.* 
		FROM jmresource 
		WHERE cmpy_code = l_rec_jobledger.cmpy_code 
		AND res_code = p_rec_purchdetl.res_code 

		LET l_rec_jobledger.allocation_ind = l_rec_jmresource.allocation_ind 

		LET l_rec_jobledger.entry_code = p_whom 
		LET l_rec_jobledger.entry_date = today 
		INSERT INTO jobledger VALUES ( l_rec_jobledger.*) 
		LET l_activity_seq_num = l_activity_seq_num + 1 
		LET l_rec_jobledger.seq_num = l_activity_seq_num 
		LET l_rec_jobledger.trans_qty = p_rec_cu_poaudit.received_qty 
		LET l_rec_jobledger.trans_amt = l_rec_jobledger.trans_qty * 
		p_rec_poaudit.unit_cost_amt 
		LET l_trans_amt_in = l_rec_jobledger.trans_amt 
		LET l_rec_jobledger.charge_amt = p_rec_purchdetl.charge_amt 
		* l_rec_jobledger.trans_qty 
		INSERT INTO jobledger VALUES ( l_rec_jobledger.*) 
		LET l_err_message = "P29 - updating job activity" 
		UPDATE activity 
		SET act_cost_amt = act_cost_amt + l_trans_amt_out + 
		l_trans_amt_in, 
		seq_num = l_activity_seq_num 
		WHERE cmpy_code = p_cmpy 
		AND job_code = p_rec_purchdetl.job_code 
		AND var_code = p_rec_purchdetl.var_num 
		AND activity_code = p_rec_purchdetl.activity_code 
	END IF 
	IF p_rec_purchdetl.type_ind = "I" OR p_rec_purchdetl.type_ind = "C" THEN 
		CALL adjust_prodledg(p_whom, 
		p_rec_purchdetl.*, 
		p_rec_poaudit.*, 
		p_rec_cu_poaudit.*) 
		RETURNING l_db_status, l_prod_status, l_err_message 
		IF l_prod_status = -2 THEN ## db ERROR 
			LET status = l_db_status 
			GOTO recovery 
		END IF 
	END IF 

	RETURN p_rec_purchdetl.seq_num, 0, 0, "" 
END FUNCTION 



############################################################
# FUNCTION adjust_prodledg(p_whom,
#                         p_rec_purchdetl,
#                         p_rec_poaudit,
#                         p_rec_cu_poaudit)
#
# new poaudit UPDATE AND INSERT routine
############################################################
FUNCTION adjust_prodledg(p_whom,p_rec_purchdetl,p_rec_poaudit,p_rec_cu_poaudit) 
	DEFINE p_whom LIKE kandoouser.sign_on_code 
	DEFINE p_rec_purchdetl RECORD LIKE purchdetl.* 
	DEFINE p_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE p_rec_cu_poaudit RECORD LIKE poaudit.* 
	#DEFINE l_currency_code LIKE vendor.currency_code
	DEFINE l_rec_inparms RECORD LIKE inparms.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_po_calc_method LIKE tax.calc_method_flag 
	DEFINE l_error_msg CHAR(60) 
	DEFINE l_adj_qty LIKE prodstatus.onhand_qty 
	DEFINE l_curr_wsale_tax DECIMAL(12,4) 
	DEFINE l_new_wsale_tax DECIMAL(12,4) 
	DEFINE l_adj_tax DECIMAL(12,4) 
	DEFINE l_curr_cost LIKE prodledg.cost_amt 
	DEFINE l_new_cost LIKE prodledg.cost_amt 
	DEFINE l_adj_cost LIKE prodledg.cost_amt 
	DEFINE l_trans_qty LIKE prodledg.tran_qty 
	DEFINE l_conv_qty LIKE rate_exchange.conv_buy_qty 

	GOTO bypass 
	LABEL recovery: 
	RETURN status, -2, l_error_msg 
	LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 
	LET l_error_msg = "P29 - Prodledg adjustment setup"
	
	CALL db_inparms_get_rec(UI_OFF,"1") RETURNING l_rec_inparms.* 
--	SELECT * 
--	INTO l_rec_inparms.* 
--	FROM inparms 
--WHERE cmpy_code = p_rec_purchdetl.cmpy_code <--- ??????? hmmm.. sure ?
--	AND parm_code = "1" 
	SELECT * 
	INTO l_rec_purchhead.* 
	FROM purchhead 
	WHERE order_num = p_rec_purchdetl.order_num 
	AND cmpy_code = p_rec_purchdetl.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_error_msg = "Purchase Order NOT found FOR ", 
		p_rec_purchdetl.order_num USING "<<<<<<<<" 
		CALL errorlog(l_error_msg) 
		# Force a DB error TO roll back the transactions already affected
		RETURN 0, -2, l_error_msg 
	END IF 
	SELECT calc_method_flag 
	INTO l_po_calc_method 
	FROM tax 
	WHERE tax_code = l_rec_purchhead.tax_code 
	AND cmpy_code = l_rec_purchhead.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_po_calc_method = " " 
	END IF 
	SELECT * 
	INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_rec_purchdetl.cmpy_code 
	AND part_code = p_rec_purchdetl.ref_text 
	IF status = NOTFOUND THEN 
		LET l_error_msg = "Product Details NOT found FOR ", 
		p_rec_purchdetl.ref_text clipped 
		CALL errorlog(l_error_msg) 
		# Force a DB error TO roll back the transactions already affected
		RETURN 0, -2, l_error_msg 
	END IF 
	#
	#  Set up the received quantity FOR which the product ledger AND
	#  weighted average cost are TO be adjusted as the transaction qty.
	#  Set up the current cost as the value currently recorded in the
	#  purchase ORDER AND the new cost as the value calculated by this
	#  voucher distribution.
	#
	LET l_trans_qty = p_rec_cu_poaudit.received_qty 
	LET l_curr_cost = p_rec_cu_poaudit.unit_cost_amt + p_rec_cu_poaudit.unit_tax_amt 
	LET l_new_cost = p_rec_poaudit.unit_cost_amt + p_rec_poaudit.unit_tax_amt 
	#
	#  Convert trans qty, current AND new cost according the the UOM
	#  FOR the product, IF required
	#
	CASE 
		WHEN (p_rec_purchdetl.uom_code = l_rec_product.pur_uom_code) 
			LET l_trans_qty = l_trans_qty 
			* l_rec_product.pur_stk_con_qty 
			* l_rec_product.stk_sel_con_qty 
			LET l_curr_cost = l_curr_cost 
			/ l_rec_product.pur_stk_con_qty 
			/ l_rec_product.stk_sel_con_qty 
			LET l_new_cost = l_new_cost 
			/ l_rec_product.pur_stk_con_qty 
			/ l_rec_product.stk_sel_con_qty 
		WHEN (p_rec_purchdetl.uom_code = l_rec_product.stock_uom_code) 
			LET l_trans_qty = l_trans_qty * l_rec_product.stk_sel_con_qty 
			LET l_curr_cost = l_curr_cost / l_rec_product.stk_sel_con_qty 
			LET l_new_cost = l_new_cost / l_rec_product.stk_sel_con_qty 
	END CASE 
	#
	#  Convert costs TO base currency
	#
	CALL get_conv_rate(p_rec_purchdetl.cmpy_code, 
	l_rec_purchhead.curr_code, 
	p_rec_poaudit.tran_date, 
	"B") 
	RETURNING l_conv_qty 
	LET l_curr_cost = l_curr_cost / l_conv_qty 
	LET l_new_cost = l_new_cost / l_conv_qty 
	#
	#  Set up product ledger static details
	#
	LET l_rec_prodledg.cmpy_code = p_rec_purchdetl.cmpy_code 
	LET l_rec_prodledg.part_code = p_rec_purchdetl.ref_text 
	LET l_rec_prodledg.ware_code = l_rec_purchhead.ware_code 
	LET l_rec_prodledg.tran_date = p_rec_poaudit.tran_date 
	LET l_rec_prodledg.trantype_ind = "P" 
	LET l_rec_prodledg.year_num = p_rec_poaudit.year_num 
	LET l_rec_prodledg.period_num = p_rec_poaudit.period_num 
	LET l_rec_prodledg.source_text = "PO C Adj" 
	LET l_rec_prodledg.source_num = 0 # no single reference FOR adjustments 
	LET l_rec_prodledg.sales_amt = 0 
	IF l_rec_inparms.hist_flag = "Y" THEN 
		LET l_rec_prodledg.hist_flag = "N" 
	ELSE 
		LET l_rec_prodledg.hist_flag = "Y" 
	END IF 
	LET l_rec_prodledg.post_flag = "N" 
	LET l_rec_prodledg.desc_text = "PO Price Change" 
	LET l_rec_prodledg.jour_num = 0 
	LET l_rec_prodledg.acct_code = NULL 
	LET l_rec_prodledg.entry_code = p_whom 
	LET l_rec_prodledg.entry_date = today 
	#
	# Lock the prodstatus RECORD FOR UPDATE
	#
	LET l_error_msg = "P29 - prodstatus UPDATE" 
	DECLARE c_prodstatus CURSOR FOR 
	SELECT prodstatus.* 
	FROM prodstatus 
	WHERE prodstatus.part_code = l_rec_prodledg.part_code 
	AND prodstatus.ware_code = l_rec_prodledg.ware_code 
	AND prodstatus.cmpy_code = l_rec_purchhead.cmpy_code 
	FOR UPDATE 
	OPEN c_prodstatus 
	FETCH c_prodstatus INTO l_rec_prodstatus.* 
	#
	# Retrieve the product tax information
	#
	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE tax_code = l_rec_prodstatus.purch_tax_code 
	AND cmpy_code = l_rec_prodstatus.cmpy_code 
	IF l_rec_tax.uplift_per IS NULL THEN 
		LET l_rec_tax.uplift_per = 0 
	END IF 
	#
	# First INSERT a reversing entry FOR the receipt AT the current cost
	#
	LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
	LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
	LET l_rec_prodledg.tran_qty = 0 - l_trans_qty 
	LET l_rec_prodledg.cost_amt = l_curr_cost 
	LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty - l_trans_qty 
	LET l_error_msg = "P29 - Product Ledger INSERT 1" 
	INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
	#
	# Calculate the wholesale tax component of the current cost IF required
	# Note that wholesakle tax only applies IF both the product AND the
	# purchase ORDER tax codes are wholsesale tax methods.
	#
	IF l_rec_tax.calc_method_flag = "W" AND 
	l_po_calc_method = "W" THEN 
		LET l_curr_wsale_tax = 0 
	END IF 
	#
	# Insert a new entry FOR the receipt AT the new cost
	#
	LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
	LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
	LET l_rec_prodledg.tran_qty = l_trans_qty 
	LET l_rec_prodledg.cost_amt = l_new_cost 
	# Note: on hand qty has NOT changed, only cost in AND out
	LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
	LET l_error_msg = "P29 - Product Ledger INSERT 2" 
	INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
	#
	# Calculate the wholesale tax component of the new cost IF required
	#
	IF l_rec_tax.calc_method_flag = "W" AND 
	l_po_calc_method = "W" THEN 
		LET l_new_wsale_tax = 0 
	END IF 
	#
	# Weighted average cost recalculation:
	# IF the receipt quantity being revalued exceeds the current
	# quantity on hand (ie. some OR all of the receipted stock has
	# already been issued) THEN weighted average cost becomes the
	# latest actual cost ie. the new cost. FOR products using the
	# wholesale tax method, the tax component IS included in the
	# weighted cost AND the product tax IS recalculated.
	# IF NOT, first calculate the adjusted weighted cost of the
	# on hand quantity less this receipt.  FOR products using the
	# wholesale tax method, this includes that old tax.
	# The adjusted cost IS THEN used TO revalue the current stock
	# AND the receipt IS included again AT the new price TO recalculate
	# weighted average.
	#
	IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
		LET l_rec_prodstatus.wgted_cost_amt = 0 
	END IF 
	#
	IF l_rec_prodstatus.onhand_qty <= l_trans_qty THEN 
		IF l_rec_tax.calc_method_flag = "W" AND 
		l_po_calc_method = "W" THEN 
			LET l_rec_prodstatus.wgted_cost_amt = 
			l_new_cost + l_new_wsale_tax 
			LET l_rec_prodstatus.purch_tax_amt = l_new_wsale_tax 
		ELSE 
			LET l_rec_prodstatus.wgted_cost_amt = l_new_cost 
			LET l_rec_prodstatus.purch_tax_amt = 0 
		END IF 
	ELSE 
		LET l_adj_qty = l_rec_prodstatus.onhand_qty - l_trans_qty 
		IF l_rec_tax.calc_method_flag = "W" AND 
		l_po_calc_method = "W" THEN 
			LET l_adj_cost = 
			((l_rec_prodstatus.onhand_qty * l_rec_prodstatus.wgted_cost_amt) 
			- (l_trans_qty * (l_curr_cost + l_curr_wsale_tax))) 
			/ l_adj_qty 
			LET l_rec_prodstatus.wgted_cost_amt = 
			((l_adj_qty * l_adj_cost) 
			+ (l_trans_qty * (l_new_cost + l_new_wsale_tax))) 
			/ l_rec_prodstatus.onhand_qty 
			LET l_adj_tax = 
			((l_rec_prodstatus.onhand_qty * l_rec_prodstatus.purch_tax_amt) 
			- (l_trans_qty * l_curr_wsale_tax)) / l_adj_qty 
			LET l_rec_prodstatus.purch_tax_amt = 
			((l_adj_qty * l_adj_tax) 
			+ (l_trans_qty * l_new_wsale_tax)) 
			/ l_rec_prodstatus.onhand_qty 
		ELSE 
			LET l_adj_cost = ((l_rec_prodstatus.onhand_qty * 
			l_rec_prodstatus.wgted_cost_amt) - 
			(l_trans_qty * l_curr_cost)) / l_adj_qty 
			LET l_rec_prodstatus.wgted_cost_amt = ((l_adj_qty * l_adj_cost) 
			+ (l_trans_qty * l_new_cost)) 
			/ l_rec_prodstatus.onhand_qty 
			LET l_rec_prodstatus.purch_tax_amt = 0 
		END IF 
	END IF 
	#
	# Update the latest cost TO be the new cost, AND UPDATE the
	# supplier cost TO the new cost IF required
	#
	LET l_rec_prodstatus.act_cost_amt = l_new_cost 
	IF get_kandoooption_feature_state("IN","SC") = "0" THEN 
		IF l_rec_purchhead.vend_code = l_rec_product.vend_code THEN 
			LET l_rec_prodstatus.for_cost_amt = 
			((p_rec_poaudit.unit_cost_amt / l_rec_product.pur_stk_con_qty) 
			/ l_rec_product.stk_sel_con_qty) 
		ELSE 
			LET l_rec_prodstatus.for_cost_amt = p_rec_poaudit.unit_cost_amt 
		END IF 
		LET l_rec_prodstatus.for_curr_code = l_rec_purchhead.curr_code 
	END IF 

	UPDATE prodstatus 
	SET wgted_cost_amt = l_rec_prodstatus.wgted_cost_amt, 
	purch_tax_amt = l_rec_prodstatus.purch_tax_amt, 
	act_cost_amt = l_rec_prodstatus.act_cost_amt, 
	for_cost_amt = l_rec_prodstatus.for_cost_amt, 
	for_curr_code = l_rec_prodstatus.for_curr_code, 
	seq_num = l_rec_prodstatus.seq_num 
	WHERE cmpy_code = l_rec_prodstatus.cmpy_code 
	AND part_code = l_rec_prodstatus.part_code 
	AND ware_code = l_rec_prodstatus.ware_code 
	CLOSE c_prodstatus 

	RETURN 0,0,"" 
END FUNCTION 



