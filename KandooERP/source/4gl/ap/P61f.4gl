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
# \brief module P61f.4gl - New Accounts Payable Debit Distribution Update
#
#                  - FUNCTION commits debithead/debitdist info TO database
#                    Updating IS governed by p_update_ind
#                               (1) = Insert Debit & distributions
#                               (2) = Update Debit & distributions
#                               (3) = Update distributions only
#
############################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P61_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
GLOBALS 
	DEFINE glob_rec_ordhead RECORD LIKE ordhead.* # only uses order_num 
	DEFINE glob_rec_orderline RECORD LIKE orderline.* 
	DEFINE glob_rec_debitdist RECORD LIKE debitdist.* 
END GLOBALS 

############################################################
# FUNCTION P61_initialise_orderline(p_cmpy,p_kandoouser_sign_on_code)
#
# variable used in here are defined as FUNCTION modulars
# glob_rec_ordhead,
# glob_rec_orderline,
# glob_rec_debitdist
############################################################
FUNCTION p61_initialise_orderline(p_cmpy,p_kandoouser_sign_on_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE l_rec_addcharge RECORD LIKE addcharge.* 
	DEFINE l_ware_code LIKE warehouse.ware_code 
	DEFINE l_mask_code LIKE warehouse.acct_mask_code 

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
	LET glob_rec_orderline.desc_text = glob_rec_debitdist.desc_text 
	CALL get_ordacct(p_cmpy, "addcharge", "rev_acct_code", 
	glob_rec_orderline.desc_text, glob_rec_ordhead.ord_ind) 
	RETURNING l_rec_addcharge.rev_acct_code 
	IF l_rec_addcharge.rev_acct_code IS NULL THEN 
		SELECT * INTO l_rec_addcharge.* FROM addcharge 
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
	l_rec_addcharge.rev_acct_code) 
	LET glob_rec_orderline.unit_tax_amt = 0 
	LET glob_rec_orderline.autoinsert_flag = "N" 
	LET glob_rec_orderline.disc_allow_flag = "N" 
	LET glob_rec_orderline.cost_ind = "W" 
	LET glob_rec_orderline.disc_amt = 0 
	LET glob_rec_orderline.ext_cost_amt = 0 - glob_rec_debitdist.dist_amt 
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
# FUNCTION update_debit(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_recDebithead)
#
#
############################################################
FUNCTION update_debit(p_cmpy,p_kandoouser_sign_on_code,p_update_ind,p_recdebithead) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_update_ind CHAR(1) 
	DEFINE p_recdebithead RECORD LIKE debithead.* 
	DEFINE l_rec_shiphead RECORD LIKE shiphead.* 
	DEFINE l_rec_s_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_activity RECORD LIKE activity.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_class_ind LIKE shipcosttype.class_ind 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT

	LET l_msgresp=kandoomsg("P",1005,"") 
	#1005 Updating database - please wait
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	LET l_err_cnt = 0 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET l_err_message = "P61f - Locking Debithead FOR Update" 

		DECLARE c_vendor CURSOR FOR 
		SELECT * FROM vendor 
		WHERE cmpy_code = p_recdebithead.cmpy_code 
		AND vend_code = p_recdebithead.vend_code 
		FOR UPDATE 
		OPEN c_vendor 
		FETCH c_vendor INTO l_rec_vendor.* 
		DECLARE c_debithead CURSOR FOR 
		SELECT * FROM debithead 
		WHERE cmpy_code = p_recdebithead.cmpy_code 
		AND vend_code = p_recdebithead.vend_code 
		AND debit_num = p_recdebithead.debit_num 
		FOR UPDATE 

		CASE p_update_ind 
			WHEN "1" #### new debit 
				DECLARE c_apparms CURSOR FOR 
				SELECT * FROM apparms 
				WHERE apparms.parm_code = "1" 
				AND apparms.cmpy_code = p_cmpy 
				FOR UPDATE 
				OPEN c_apparms 
				FETCH c_apparms INTO glob_rec_apparms.* 
				LET p_recdebithead.debit_num = glob_rec_apparms.next_deb_num 
				UPDATE apparms 
				SET next_deb_num = glob_rec_apparms.next_deb_num + 1 
				WHERE cmpy_code = p_cmpy 
				AND parm_code = "1" 
				INITIALIZE l_rec_s_debithead.* TO NULL 
				LET l_rec_s_debithead.total_amt = 0 
			WHEN "2" #### UPDATE debit 
				OPEN c_debithead 
				FETCH c_debithead INTO l_rec_s_debithead.* 
			WHEN "3" #### UPDATE debit distributions 
				OPEN c_debithead 
				FETCH c_debithead INTO p_recdebithead.* 
				LET l_rec_s_debithead.* = p_recdebithead.* 
		END CASE 

		IF p_recdebithead.conv_qty IS NULL OR 
		p_recdebithead.conv_qty = 0 THEN 
			LET p_recdebithead.conv_qty = 1 
		END IF 

		IF p_recdebithead.dist_amt > 0 
		AND p_recdebithead.post_flag = "N" THEN 
			DECLARE c_debitdist CURSOR FOR 
			SELECT * FROM debitdist 
			WHERE cmpy_code = p_recdebithead.cmpy_code 
			AND vend_code = p_recdebithead.vend_code 
			AND debit_code = p_recdebithead.debit_num 

			FOREACH c_debitdist INTO glob_rec_debitdist.* 
				CASE 
					WHEN glob_rec_debitdist.type_ind = "J" 
						LET l_err_message = "P61 - Locking JM Activity FOR Update" 
						DECLARE c_activity CURSOR FOR 
						SELECT * FROM activity 
						WHERE cmpy_code = p_cmpy 
						AND job_code = glob_rec_debitdist.job_code 
						AND var_code = glob_rec_debitdist.var_code 
						AND activity_code = glob_rec_debitdist.act_code 
						AND finish_flag = "N" 
						FOR UPDATE 
						OPEN c_activity 
						FETCH c_activity INTO l_rec_activity.* 
						IF status = 0 THEN 
							LET l_err_message = "P61 - Insert JM Jobledger " 
							LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
							LET l_rec_jobledger.cmpy_code = p_cmpy 
							LET l_rec_jobledger.trans_date = p_recdebithead.debit_date 
							LET l_rec_jobledger.year_num = p_recdebithead.year_num 
							LET l_rec_jobledger.period_num = p_recdebithead.period_num 
							LET l_rec_jobledger.job_code = glob_rec_debitdist.job_code 
							LET l_rec_jobledger.var_code = glob_rec_debitdist.var_code 
							LET l_rec_jobledger.activity_code = glob_rec_debitdist.act_code 
							LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
							LET l_rec_jobledger.trans_type_ind = "DB" 
							LET l_rec_jobledger.trans_source_num = p_recdebithead.debit_num 
							LET l_rec_jobledger.trans_source_text=glob_rec_debitdist.res_code 
							LET l_rec_jobledger.allocation_ind=glob_rec_debitdist.allocation_ind 
							LET l_rec_jobledger.trans_amt = glob_rec_debitdist.dist_amt 
							/ l_rec_s_debithead.conv_qty 
							LET l_rec_jobledger.trans_qty = glob_rec_debitdist.trans_qty 
							LET l_rec_jobledger.charge_amt = glob_rec_debitdist.charge_amt 
							* glob_rec_debitdist.trans_qty 
							LET l_rec_jobledger.posted_flag = "N" 
							LET l_rec_jobledger.desc_text = glob_rec_debitdist.desc_text 
							LET l_rec_jobledger.entry_code = p_kandoouser_sign_on_code 
							LET l_rec_jobledger.entry_date = today 
							INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
							LET l_err_message = "P61 - Update JM Activity " 
							UPDATE activity 
							SET seq_num = l_rec_activity.seq_num, 
							act_cost_amt = act_cost_amt 
							+ l_rec_jobledger.trans_amt, 
							act_cost_qty = act_cost_qty 
							+ glob_rec_debitdist.trans_qty, 
							post_revenue_amt = post_revenue_amt 
							+ l_rec_jobledger.charge_amt 
							WHERE cmpy_code = glob_rec_debitdist.cmpy_code 
							AND job_code = glob_rec_debitdist.job_code 
							AND var_code = glob_rec_debitdist.var_code 
							AND activity_code = glob_rec_debitdist.act_code 
						ELSE 
							LET l_err_message="JM Activity IS closed - No Update Allowed" 
							GOTO recovery 
						END IF 

					WHEN glob_rec_debitdist.type_ind = "S" 
						LET l_err_message = "P61 - Locking Shiphead FOR UPDATE" 
						DECLARE c_shiphead CURSOR FOR 
						SELECT * FROM shiphead 
						WHERE cmpy_code = p_cmpy 
						AND ship_code = glob_rec_debitdist.job_code 
						FOR UPDATE 
						OPEN c_shiphead 
						FETCH c_shiphead INTO l_rec_shiphead.* 
						IF status = 0 THEN 
							SELECT class_ind INTO l_class_ind 
							FROM shipcosttype 
							WHERE cmpy_code = p_cmpy 
							AND cost_type_code = glob_rec_debitdist.res_code 
							CASE l_class_ind 
								WHEN '1' 
									LET l_rec_shiphead.fob_curr_cost_amt 
									= l_rec_shiphead.fob_curr_cost_amt 
									+ glob_rec_debitdist.dist_amt 
									LET l_rec_shiphead.fob_inv_cost_amt 
									= l_rec_shiphead.fob_inv_cost_amt 
									+ ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
								WHEN '2' 
									LET l_rec_shiphead.duty_inv_amt 
									= l_rec_shiphead.duty_inv_amt 
									+ ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
								WHEN '3' 
									LET l_rec_shiphead.other_cost_amt 
									= l_rec_shiphead.other_cost_amt 
									+ ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
								WHEN '4' 
									LET l_rec_shiphead.late_cost_amt 
									= l_rec_shiphead.late_cost_amt 
									+ ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
							END CASE 

							UPDATE shiphead 
							SET fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt, 
							fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt, 
							duty_inv_amt = l_rec_shiphead.duty_inv_amt, 
							late_cost_amt = l_rec_shiphead.late_cost_amt, 
							other_cost_amt = l_rec_shiphead.other_cost_amt 
							WHERE cmpy_code = p_cmpy 
							AND ship_code = glob_rec_debitdist.job_code 
							CLOSE c_shiphead 
						END IF 

					WHEN glob_rec_debitdist.type_ind = "W" 
						LET l_err_message = "P61f - Locking Ordhead FOR UPDATE" 
						DECLARE c_ordhead CURSOR FOR 
						SELECT order_num FROM ordhead 
						WHERE cmpy_code = p_cmpy 
						AND order_num = glob_rec_debitdist.po_num 
						FOR UPDATE 
						OPEN c_ordhead 
						FETCH c_ordhead INTO glob_rec_ordhead.order_num 
						UPDATE ordhead SET export_cost_amt = export_cost_amt + 
						glob_rec_debitdist.dist_amt 
						WHERE cmpy_code = p_cmpy 
						AND order_num = glob_rec_ordhead.order_num 
						CLOSE c_ordhead 

						LET l_err_message = "P61f - Locking orderline FOR UPDATE" 
						DECLARE c_orderline CURSOR FOR 
						SELECT order_num,line_num, ext_cost_amt FROM orderline 
						WHERE order_num = glob_rec_debitdist.po_num 
						AND part_code IS NULL 
						AND desc_text = glob_rec_debitdist.desc_text 
						AND cmpy_code = p_cmpy 
						FOR UPDATE 
						OPEN c_orderline 
						FETCH c_orderline INTO glob_rec_orderline.order_num, 
						glob_rec_orderline.line_num, 
						glob_rec_orderline.ext_cost_amt 
						IF status != NOTFOUND THEN 
							UPDATE orderline SET ext_cost_amt = ext_cost_amt + 
							glob_rec_debitdist.dist_amt 
							WHERE order_num = glob_rec_orderline.order_num 
							AND line_num = glob_rec_orderline.line_num 
							AND cmpy_code = p_cmpy 
						END IF 
						CLOSE c_orderline 
				END CASE 

				DELETE FROM debitdist 
				WHERE cmpy_code = glob_rec_debitdist.cmpy_code 
				AND vend_code = p_recdebithead.vend_code 
				AND debit_code = glob_rec_debitdist.debit_code 
				AND line_num = glob_rec_debitdist.line_num 
			END FOREACH 
		END IF 
		####
		#### Insert/Update Debit
		####
		IF p_update_ind != "3" THEN 
			IF p_recdebithead.total_amt != l_rec_s_debithead.total_amt THEN 
				IF l_rec_s_debithead.total_amt != 0 THEN 
					LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
					+ l_rec_s_debithead.total_amt 
					LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
					+ l_rec_s_debithead.total_amt 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
					LET l_rec_apaudit.tran_date = l_rec_s_debithead.debit_date 
					LET l_rec_apaudit.vend_code = l_rec_s_debithead.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "DB" 
					LET l_rec_apaudit.year_num = l_rec_s_debithead.year_num 
					LET l_rec_apaudit.period_num = l_rec_s_debithead.period_num 
					LET l_rec_apaudit.source_num = l_rec_s_debithead.debit_num 
					LET l_rec_apaudit.tran_text = "Backout Debit" 
					LET l_rec_apaudit.tran_amt = l_rec_s_debithead.total_amt 
					LET l_rec_apaudit.entry_code = l_rec_s_debithead.entry_code 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = l_rec_s_debithead.currency_code 
					LET l_rec_apaudit.conv_qty = l_rec_s_debithead.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
				IF p_recdebithead.total_amt != 0 THEN 
					LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
					- p_recdebithead.total_amt 
					LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
					- p_recdebithead.total_amt 
					LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
					LET l_rec_apaudit.tran_date = p_recdebithead.debit_date 
					LET l_rec_apaudit.vend_code = p_recdebithead.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "DB" 
					LET l_rec_apaudit.year_num = p_recdebithead.year_num 
					LET l_rec_apaudit.period_num = p_recdebithead.period_num 
					LET l_rec_apaudit.source_num = p_recdebithead.debit_num 
					IF p_update_ind = "1" THEN 
						LET l_rec_apaudit.tran_text = "Debit Entry" 
					ELSE 
						LET l_rec_apaudit.tran_text = "Debit Edit" 
					END IF 
					LET l_rec_apaudit.tran_amt = 0 - p_recdebithead.total_amt 
					LET l_rec_apaudit.entry_code = p_recdebithead.entry_code 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = p_recdebithead.currency_code 
					LET l_rec_apaudit.conv_qty = p_recdebithead.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
				IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
					LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
				END IF 
			END IF 
			UPDATE debithead 
			SET * = p_recdebithead.* 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = p_recdebithead.vend_code 
			AND debit_num = p_recdebithead.debit_num 
			IF sqlca.sqlerrd[3] = 0 THEN 
				INSERT INTO debithead VALUES (p_recDebithead.*) 
			END IF 
			UPDATE vendor 
			SET bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			highest_bal_amt = l_rec_vendor.highest_bal_amt, 
			next_seq_num = l_rec_vendor.next_seq_num 
			WHERE cmpy_code = p_cmpy 
			AND vend_code = p_recdebithead.vend_code 
		END IF 
		####
		#### Insert Distributions
		####
		IF p_recdebithead.post_flag = "N" THEN 
			LET p_recdebithead.dist_amt = 0 
			LET p_recdebithead.dist_qty = 0 
			LET i = 0 
			DECLARE c1_t_debitdist CURSOR FOR 
			SELECT * FROM t_debitdist 
			WHERE acct_code IS NOT NULL 
			ORDER BY line_num 
			FOREACH c1_t_debitdist INTO glob_rec_debitdist.* 
				IF glob_rec_debitdist.dist_amt IS NULL THEN 
					LET glob_rec_debitdist.dist_amt = 0 
				END IF 
				IF glob_rec_debitdist.dist_qty IS NULL THEN 
					LET glob_rec_debitdist.dist_qty = 0 
				END IF 
				IF glob_rec_debitdist.dist_amt = 0 
				AND glob_rec_debitdist.dist_qty = 0 THEN 
					CONTINUE FOREACH 
				END IF 
				LET i = i + 1 
				LET glob_rec_debitdist.cmpy_code = p_recdebithead.cmpy_code 
				LET glob_rec_debitdist.vend_code = p_recdebithead.vend_code 
				LET glob_rec_debitdist.debit_code = p_recdebithead.debit_num 
				LET glob_rec_debitdist.line_num = i 
				LET p_recdebithead.dist_amt = p_recdebithead.dist_amt 
				+ glob_rec_debitdist.dist_amt 
				LET p_recdebithead.dist_qty = p_recdebithead.dist_qty 
				+ glob_rec_debitdist.dist_qty 
				IF p_recdebithead.dist_amt <= p_recdebithead.total_amt THEN 
					CASE glob_rec_debitdist.type_ind 
						WHEN "J" 
							LET l_err_message = "P61 - Locking JM Activity FOR Update" 
							DECLARE c1_activity CURSOR FOR 
							SELECT * FROM activity 
							WHERE cmpy_code = p_cmpy 
							AND job_code = glob_rec_debitdist.job_code 
							AND var_code = glob_rec_debitdist.var_code 
							AND activity_code = glob_rec_debitdist.act_code 
							AND finish_flag = "N" 
							FOR UPDATE 
							OPEN c1_activity 
							FETCH c1_activity INTO l_rec_activity.* 
							IF status = 0 THEN 
								LET l_err_message = "P61 - Insert JM Jobledger" 
								LET l_rec_activity.seq_num = l_rec_activity.seq_num + 1 
								LET l_rec_jobledger.cmpy_code = p_cmpy 
								LET l_rec_jobledger.trans_date = p_recdebithead.debit_date 
								LET l_rec_jobledger.year_num = p_recdebithead.year_num 
								LET l_rec_jobledger.period_num = p_recdebithead.period_num 
								LET l_rec_jobledger.job_code = glob_rec_debitdist.job_code 
								LET l_rec_jobledger.var_code = glob_rec_debitdist.var_code 
								LET l_rec_jobledger.activity_code = glob_rec_debitdist.act_code 
								LET l_rec_jobledger.seq_num = l_rec_activity.seq_num 
								LET l_rec_jobledger.trans_type_ind = "DB" 
								LET l_rec_jobledger.trans_source_num=p_recdebithead.debit_num 
								LET l_rec_jobledger.allocation_ind= 
								glob_rec_debitdist.allocation_ind 
								LET l_rec_jobledger.trans_source_text= 
								glob_rec_debitdist.res_code 
								LET l_rec_jobledger.trans_amt = 0 - (glob_rec_debitdist.dist_amt 
								/ p_recdebithead.conv_qty) 
								LET l_rec_jobledger.trans_qty = 0 - glob_rec_debitdist.trans_qty 
								LET l_rec_jobledger.charge_amt = 0 - 
								(glob_rec_debitdist.charge_amt * 
								glob_rec_debitdist.trans_qty) 
								LET l_rec_jobledger.posted_flag = "N" 
								LET l_rec_jobledger.entry_code = p_kandoouser_sign_on_code 
								LET l_rec_jobledger.entry_date = today 
								LET l_rec_jobledger.desc_text = glob_rec_debitdist.desc_text 
								INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
								LET l_err_message = "P61 - Update JM Activity" 
								UPDATE activity 
								SET seq_num = l_rec_activity.seq_num, 
								act_cost_amt = act_cost_amt 
								+ l_rec_jobledger.trans_amt, 
								act_cost_qty = act_cost_qty 
								+ l_rec_jobledger.trans_qty, 
								post_revenue_amt = post_revenue_amt 
								+ l_rec_jobledger.charge_amt 
								WHERE cmpy_code = glob_rec_debitdist.cmpy_code 
								AND job_code = glob_rec_debitdist.job_code 
								AND var_code = glob_rec_debitdist.var_code 
								AND activity_code = glob_rec_debitdist.act_code 
								LET l_err_message = "P61 - Insert JM Debit Dist.Lines" 
								INSERT INTO debitdist VALUES (glob_rec_debitdist.*) 
							ELSE 
								LET p_recdebithead.dist_amt = p_recdebithead.dist_amt 
								- glob_rec_debitdist.dist_amt 
								LET p_recdebithead.dist_qty = p_recdebithead.dist_qty 
								- glob_rec_debitdist.dist_qty 
								DELETE FROM t_debitdist 
								WHERE line_num = glob_rec_debitdist.line_num 
								LET l_err_cnt = l_err_cnt + 1 
							END IF 

						WHEN "S" 
							LET l_err_message = "P61 - Locking shiphead FOR UPDATE" 
							DECLARE c1_shiphead CURSOR FOR 
							SELECT * FROM shiphead 
							WHERE cmpy_code = p_cmpy 
							AND ship_code = glob_rec_debitdist.job_code 
							FOR UPDATE 
							OPEN c1_shiphead 
							FETCH c1_shiphead INTO l_rec_shiphead.* 
							IF status = 0 THEN 
								SELECT class_ind INTO l_class_ind 
								FROM shipcosttype 
								WHERE cmpy_code = p_cmpy 
								AND cost_type_code = glob_rec_debitdist.res_code 
								CASE l_class_ind 
									WHEN '1' 
										LET l_rec_shiphead.fob_curr_cost_amt 
										= l_rec_shiphead.fob_curr_cost_amt 
										- glob_rec_debitdist.dist_amt 
										LET l_rec_shiphead.fob_inv_cost_amt 
										= l_rec_shiphead.fob_inv_cost_amt 
										- ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
									WHEN '2' 
										LET l_rec_shiphead.duty_inv_amt 
										= l_rec_shiphead.duty_inv_amt 
										- ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
									WHEN '3' 
										LET l_rec_shiphead.other_cost_amt 
										= l_rec_shiphead.other_cost_amt 
										- ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
									WHEN '4' 
										LET l_rec_shiphead.late_cost_amt 
										= l_rec_shiphead.late_cost_amt 
										- ( glob_rec_debitdist.dist_amt / p_recdebithead.conv_qty ) 
								END CASE 

								UPDATE shiphead 
								SET voucher_flag = "Y", 
								fob_curr_cost_amt = l_rec_shiphead.fob_curr_cost_amt, 
								fob_inv_cost_amt = l_rec_shiphead.fob_inv_cost_amt, 
								duty_inv_amt = l_rec_shiphead.duty_inv_amt, 
								late_cost_amt = l_rec_shiphead.late_cost_amt, 
								other_cost_amt = l_rec_shiphead.other_cost_amt 
								WHERE cmpy_code = p_cmpy 
								AND ship_code = glob_rec_debitdist.job_code 
								CLOSE c1_shiphead 
								LET l_err_message = "P61 - Insert Ship Debit Dist.Lines" 
								INSERT INTO debitdist VALUES (glob_rec_debitdist.*) 
							ELSE 
								LET p_recdebithead.dist_amt = p_recdebithead.dist_amt 
								- glob_rec_debitdist.dist_amt 
								LET p_recdebithead.dist_qty = p_recdebithead.dist_qty 
								- glob_rec_debitdist.dist_qty 
								DELETE FROM t_debitdist 
								WHERE line_num = glob_rec_debitdist.line_num 
								LET l_err_cnt = l_err_cnt + 1 
							END IF 

						WHEN "W" 
							LET l_err_message = "P61f - Locking Ordhead FOR UPDATE" 
							DECLARE c1_ordhead CURSOR FOR 
							SELECT * FROM ordhead 
							WHERE cmpy_code = p_cmpy 
							AND order_num = glob_rec_debitdist.po_num 
							FOR UPDATE 
							OPEN c1_ordhead 
							FETCH c1_ordhead INTO glob_rec_ordhead.* 
							IF status != NOTFOUND THEN 
								IF glob_rec_debitdist.desc_text IS NOT NULL THEN 
									LET l_err_message = "P61f - Locking orderline FOR UPDATE" 
									DECLARE c1_orderline CURSOR FOR 
									SELECT order_num,line_num, ext_cost_amt FROM orderline 
									WHERE order_num = glob_rec_debitdist.po_num 
									AND part_code IS NULL 
									AND desc_text = glob_rec_debitdist.desc_text 
									AND cmpy_code = p_cmpy 
									FOR UPDATE 
									OPEN c1_orderline 
									FETCH c1_orderline INTO glob_rec_orderline.order_num, 
									glob_rec_orderline.line_num, 
									glob_rec_orderline.ext_cost_amt 
									IF status != NOTFOUND THEN 
										IF glob_rec_debitdist.allocation_ind = "Y" THEN 
											LET glob_rec_orderline.status_ind = "C" 
										ELSE 
											LET glob_rec_orderline.status_ind = "0" 
										END IF 
										UPDATE orderline SET ext_cost_amt = ext_cost_amt - 
										glob_rec_debitdist.dist_amt, 
										status_ind = glob_rec_orderline.status_ind 
										WHERE order_num = glob_rec_orderline.order_num 
										AND line_num = glob_rec_orderline.line_num 
										AND cmpy_code = p_cmpy 
										CLOSE c1_orderline 
										LET l_err_message = "P61f - Update Ordhead " 
										UPDATE ordhead SET export_cost_amt = export_cost_amt 
										- glob_rec_debitdist.dist_amt 
										WHERE cmpy_code = p_cmpy 
										AND order_num = glob_rec_ordhead.order_num 
										CLOSE c1_ordhead 
									ELSE 
										# need TO INSERT an ORDER line here
										# Insert orderline FOR new additional charge
										CALL p61_initialise_orderline(p_cmpy,p_kandoouser_sign_on_code) 
										LET l_err_message = "P61f - Insert Orderline " 
										INSERT INTO orderline VALUES (glob_rec_orderline.*) 
										LET l_err_message = "P61f - Update Ordhead " 
										UPDATE ordhead SET export_cost_amt = export_cost_amt 
										- glob_rec_debitdist.dist_amt, 
										line_num = glob_rec_ordhead.line_num 
										WHERE cmpy_code = p_cmpy 
										AND order_num = glob_rec_ordhead.order_num 
										CLOSE c1_ordhead 
									END IF 
									LET l_err_message = "P61f -Insert WO debithead Dist.Lines" 
									INSERT INTO debitdist VALUES (glob_rec_debitdist.*) 
								ELSE 
									LET l_err_message = "P61f - Update Ordhead " 
									UPDATE ordhead SET export_cost_amt = export_cost_amt 
									- glob_rec_debitdist.dist_amt, 
									line_num = glob_rec_ordhead.line_num 
									WHERE cmpy_code = p_cmpy 
									AND order_num = glob_rec_ordhead.order_num 
									CLOSE c1_ordhead 
									LET l_err_message = "P61f -Insert WO debithead Dist.Lines2" 
									INSERT INTO debitdist VALUES (glob_rec_debitdist.*) 
								END IF 
							ELSE 
								LET p_recdebithead.dist_amt = p_recdebithead.dist_amt 
								- glob_rec_debitdist.dist_amt 
								LET p_recdebithead.dist_qty = p_recdebithead.dist_qty 
								- glob_rec_debitdist.dist_qty 
								DELETE FROM t_debitdist 
								WHERE line_num = glob_rec_debitdist.line_num 
								LET l_err_cnt = l_err_cnt + 1 
							END IF 
						OTHERWISE 
							INSERT INTO debitdist VALUES (glob_rec_debitdist.*) 
					END CASE 
				ELSE 
					LET p_recdebithead.dist_amt = p_recdebithead.dist_amt 
					- glob_rec_debitdist.dist_amt 
					LET p_recdebithead.dist_qty = p_recdebithead.dist_qty 
					- glob_rec_debitdist.dist_qty 
					DELETE FROM t_debitdist 
					WHERE line_num = glob_rec_debitdist.line_num 
					LET l_err_cnt = l_err_cnt + 1 
				END IF 
			END FOREACH 
			UPDATE debithead 
			SET dist_amt = p_recdebithead.dist_amt, 
			dist_qty = p_recdebithead.dist_qty 
			WHERE cmpy_code = p_recdebithead.cmpy_code 
			AND debit_num = p_recdebithead.debit_num 
		END IF 

	COMMIT WORK 

	WHENEVER ERROR stop 

	IF l_err_cnt > 0 THEN 
		RETURN false 
	ELSE 
		RETURN p_recdebithead.debit_num 
	END IF 
END FUNCTION 


