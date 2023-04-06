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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A4_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A41_GLOBALS.4gl" 

#################################################################
# MODULE scope variables
#################################################################

#################################################################
# FUNCTION backout_credit()
#
#
#################################################################
FUNCTION backout_credit() 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_t_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_onhand_qty  LIKE prodstatus.onhand_qty 
	DEFINE l_idx SMALLINT 

	WHENEVER ERROR GOTO recovery 
	IF glob_rec_credithead.cred_ind != "4" THEN 
		LET glob_temp_text = "A41 - Locking customer RECORD FOR credit UPDATE" 

		DECLARE c1_stattrig CURSOR FOR 
		SELECT * FROM stattrig 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tran_type_ind = TRAN_TYPE_CREDIT_CR 
		AND trans_num = glob_rec_credithead.cred_num 
		FOR UPDATE 

		OPEN c1_stattrig 
		FETCH c1_stattrig 

		IF sqlca.sqlcode != 0 THEN 
			LET glob_temp_text = "A41 - Credit has been posted TO statistics" 
			GOTO recovery 
		END IF 

		LET glob_temp_text = "A41 - Locking credit header RECORD FOR reversal" 
	END IF 
	
	DECLARE c1_credithead CURSOR FOR 
	SELECT * FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = glob_rec_credithead.cred_num 
	FOR UPDATE 
	OPEN c1_credithead 
	FETCH c1_credithead INTO l_rec_t_credithead.* 
	
	IF l_rec_t_credithead.rev_num != glob_rec_credithead.rev_num THEN 
		RETURN false 
	END IF 

	IF l_rec_t_credithead.appl_amt != glob_rec_credithead.appl_amt THEN 
		RETURN false 
	END IF 

	LET glob_temp_text = "A41 - Locking customer RECORD FOR credit reversal" 
	
	DECLARE c1_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = l_rec_t_credithead.cust_code 
	FOR UPDATE 

	OPEN c1_customer 
	FETCH c1_customer INTO glob_rec_customer.* 
	
	LET glob_temp_text = "A41 - Insert AR audit RECORD FOR credit reversal" 
	LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_araudit.tran_date = l_rec_t_credithead.cred_date 
	LET l_rec_araudit.cust_code = l_rec_t_credithead.cust_code 
	LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num + 1 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET l_rec_araudit.source_num = l_rec_t_credithead.cred_num 
	LET l_rec_araudit.tran_text = "Credit Reversal" 
	LET l_rec_araudit.tran_amt = l_rec_t_credithead.total_amt 
	LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_araudit.sales_code = l_rec_t_credithead.sale_code 
	LET l_rec_araudit.year_num = l_rec_t_credithead.year_num 
	LET l_rec_araudit.period_num = l_rec_t_credithead.period_num 
	LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt + l_rec_t_credithead.total_amt 
	LET l_rec_araudit.currency_code = l_rec_t_credithead.currency_code 
	LET l_rec_araudit.conv_qty = l_rec_t_credithead.conv_qty 
	LET l_rec_araudit.entry_date = today 
	
	INSERT INTO araudit VALUES (l_rec_araudit.*) 

	LET glob_temp_text = "A41 - Updating customer RECORD FOR credit reversal" 
	LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
	LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt + l_rec_t_credithead.total_amt 
	LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt + l_rec_t_credithead.total_amt 
	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt - glob_rec_customer.bal_amt 
	LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt + l_rec_t_credithead.total_amt 
	LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt + l_rec_t_credithead.total_amt 
	
	UPDATE customer 
	SET 
		next_seq_num = glob_rec_customer.next_seq_num, 
		bal_amt = glob_rec_customer.bal_amt, 
		curr_amt = glob_rec_customer.curr_amt, 
		highest_bal_amt = glob_rec_customer.highest_bal_amt, 
		cred_bal_amt = glob_rec_customer.cred_bal_amt, 
		ytds_amt = glob_rec_customer.ytds_amt, 
		mtds_amt = glob_rec_customer.mtds_amt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = l_rec_t_credithead.cust_code 
	
	FOR l_idx = 1 TO l_rec_t_credithead.line_num 
		SELECT * INTO l_rec_creditdetl.* 
		FROM creditdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_t_credithead.cust_code 
		AND cred_num = l_rec_t_credithead.cred_num 
		AND line_num = l_idx 
		
		IF l_rec_creditdetl.part_code IS NOT NULL 
		AND l_rec_creditdetl.ship_qty > 0 THEN 
			LET glob_temp_text = "A41 - Locking product STATUS FOR credit reversal" 
			DECLARE c1_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_creditdetl.ware_code 
			AND part_code = l_rec_creditdetl.part_code 
			FOR UPDATE 
			OPEN c1_prodstatus 
			FETCH c1_prodstatus INTO l_rec_prodstatus.* 

			LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 

			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				LET l_onhand_qty  = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty	- l_rec_creditdetl.ship_qty 
			END IF 
			
			LET glob_temp_text = "A41 - Inserting product ledger FOR credit reversal" 
			LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_prodledg.part_code = l_rec_creditdetl.part_code 
			LET l_rec_prodledg.ware_code = l_rec_creditdetl.ware_code 
			LET l_rec_prodledg.tran_date = glob_rec_credithead.cred_date 
			LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
			LET l_rec_prodledg.trantype_ind = "C" 
			LET l_rec_prodledg.year_num = glob_rec_credithead.year_num 
			LET l_rec_prodledg.period_num = glob_rec_credithead.period_num 
			LET l_rec_prodledg.source_text = l_rec_creditdetl.cust_code 
			LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
			LET l_rec_prodledg.source_num = l_rec_creditdetl.cred_num 
			LET l_rec_prodledg.tran_qty = (0 - l_rec_creditdetl.ship_qty) + 0 
			IF glob_rec_credithead.conv_qty > 0 THEN 
				LET l_rec_prodledg.cost_amt = l_rec_creditdetl.unit_cost_amt	/ glob_rec_credithead.conv_qty 
				LET l_rec_prodledg.sales_amt = l_rec_creditdetl.unit_sales_amt	/ glob_rec_credithead.conv_qty 
			END IF 
			
			LET l_rec_prodledg.hist_flag = "N" 
			LET l_rec_prodledg.post_flag = "N" 
			LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_prodledg.entry_date = today 
			LET l_rec_prodledg.acct_code = NULL 
			
			INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
			
			IF l_rec_creditdetl.received_qty != l_rec_creditdetl.ship_qty THEN 
				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
				IF l_rec_prodstatus.stocked_flag = "Y" THEN 
					LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty 
					+ ( l_rec_creditdetl.ship_qty 
					- l_rec_creditdetl.received_qty) 
				END IF 
				LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
				LET l_rec_prodledg.trantype_ind = "A" 
				LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodledg.tran_qty = l_rec_creditdetl.ship_qty - l_rec_creditdetl.received_qty 

				SELECT adj_acct_code INTO l_rec_prodledg.acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_rec_creditdetl.cat_code 
				IF status = NOTFOUND THEN 
					LET l_rec_prodledg.acct_code = NULL ## posting TO use suspense 
				END IF 

				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

			END IF 
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
					LET l_rec_prodstatus.wgted_cost_amt = 0 
				END IF 

				IF l_rec_prodstatus.onhand_qty > 0 THEN 
					LET l_rec_prodstatus.wgted_cost_amt = 
					( ( l_rec_prodstatus.wgted_cost_amt * l_onhand_qty  ) 
					+ ( l_rec_creditdetl.unit_cost_amt 
					* ( l_rec_prodstatus.onhand_qty - l_onhand_qty  ))) 
					/ l_rec_prodstatus.onhand_qty 
				END IF 
			END IF 
			
			LET glob_temp_text = "A41 - Updating product STATUS FOR credit reversal" 
			UPDATE prodstatus 
			SET 
				onhand_qty = l_rec_prodstatus.onhand_qty, 
				wgted_cost_amt = l_rec_prodstatus.wgted_cost_amt, 
				seq_num = l_rec_prodstatus.seq_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_creditdetl.ware_code 
			AND part_code = l_rec_creditdetl.part_code 
		END IF 
	END FOR 
	
	LET glob_temp_text = "A41 - Deleting old credit lines FOR credit reversal" 
	
	DELETE FROM creditdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = l_rec_t_credithead.cred_num 

	LET glob_temp_text = "A41 - Updating credit header FOR credit reversal" 
	LET l_rec_t_credithead.rev_num = l_rec_t_credithead.rev_num + 1 
	LET l_rec_t_credithead.rev_date = today 
	LET l_rec_t_credithead.line_num = 0 
	LET l_rec_t_credithead.goods_amt = 0 
	LET l_rec_t_credithead.tax_amt = 0 
	LET l_rec_t_credithead.hand_amt = 0 
	LET l_rec_t_credithead.hand_tax_amt = 0 
	LET l_rec_t_credithead.freight_amt = 0 
	LET l_rec_t_credithead.freight_tax_amt = 0 
	LET l_rec_t_credithead.total_amt = 0 
	LET l_rec_t_credithead.cost_amt = 0 
	LET l_rec_t_credithead.appl_amt = 0 
	LET l_rec_t_credithead.disc_amt = 0 

	UPDATE credithead 
	SET * = l_rec_t_credithead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = l_rec_t_credithead.cred_num 
	AND cust_code = l_rec_t_credithead.cust_code 

	RETURN true 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LABEL recovery: 
	RETURN sqlca.sqlcode 
END FUNCTION 
#################################################################
# FUNCTION backout_credit()
#################################################################


#################################################################
# FUNCTION insert_credit())
#
#
#################################################################
FUNCTION insert_credit() 
	DEFINE l_rec_t_credithead RECORD LIKE credithead.* 

	WHENEVER ERROR GOTO recovery 
	LET glob_rec_credithead.cred_num = next_trans_num(
		glob_rec_kandoouser.cmpy_code,
		TRAN_TYPE_CREDIT_CR,
		glob_rec_credithead.acct_override_code) 

	IF glob_rec_credithead.cred_num < 0 THEN 
		LET glob_temp_text = "A41 - Auto Transaction Number Generation " 
		RETURN glob_rec_credithead.cred_num 
	END IF 

	LET l_rec_t_credithead.* = glob_rec_credithead.* 
	LET l_rec_t_credithead.line_num = 0 
	LET l_rec_t_credithead.goods_amt = 0 
	LET l_rec_t_credithead.tax_amt = 0 
	LET l_rec_t_credithead.hand_amt = 0 
	LET l_rec_t_credithead.hand_tax_amt = 0 
	LET l_rec_t_credithead.freight_amt = 0 
	LET l_rec_t_credithead.freight_tax_amt = 0 
	LET l_rec_t_credithead.total_amt = 0 
	LET l_rec_t_credithead.cost_amt = 0 
	LET l_rec_t_credithead.appl_amt = 0 
	LET l_rec_t_credithead.disc_amt = 0 
	LET glob_temp_text = "A41 - Inserting new credit RECORD " 
	
	INSERT INTO credithead VALUES (l_rec_t_credithead.*) 
	
	IF glob_rec_credheadaddr.addr1_text IS NOT NULL 
	OR glob_rec_credheadaddr.addr2_text IS NOT NULL 
	OR glob_rec_credheadaddr.city_text IS NOT NULL 
	OR glob_rec_credheadaddr.ship_text IS NOT NULL 
	OR glob_rec_credheadaddr.state_code IS NOT NULL 
	OR glob_rec_credheadaddr.post_code IS NOT NULL 
	THEN 
		LET glob_rec_credheadaddr.cred_num = glob_rec_credithead.cred_num 

		INSERT INTO credheadaddr VALUES (glob_rec_credheadaddr.*) 

	END IF 
	
	INSERT INTO stattrig VALUES (glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,glob_rec_credithead.cred_num, glob_rec_credithead.cred_date) 
	
	RETURN true 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	LABEL recovery: 
	
	RETURN sqlca.sqlcode 
END FUNCTION 
#################################################################
# END FUNCTION insert_credit())
#################################################################


#################################################################
# FUNCTION update_credit()
#
#
#################################################################
FUNCTION update_credit() 

	DEFINE glob_rec_customer RECORD LIKE customer.* 

	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_onhand_qty  LIKE prodstatus.onhand_qty 

	WHENEVER ERROR GOTO recovery 

	LET glob_temp_text = "A41 - Locking customer RECORD FOR credit UPDATE" 

	DECLARE c2_customer CURSOR FOR 
	SELECT * FROM customer 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_credithead.cust_code 
	FOR UPDATE 
	OPEN c2_customer 
	FETCH c2_customer INTO glob_rec_customer.* 

	DECLARE c_creditdetl CURSOR FOR 
	SELECT * INTO l_rec_creditdetl.* 
	FROM t_creditdetl 
	ORDER BY line_num 

	LET glob_rec_credithead.goods_amt = 0 
	LET glob_rec_credithead.cost_amt = 0 
	LET glob_rec_credithead.tax_amt = 0 
	LET glob_rec_credithead.line_num = 0 

	FOREACH c_creditdetl INTO l_rec_creditdetl.* 
		LET l_rec_creditdetl.cmpy_code = glob_rec_credithead.cmpy_code 
		LET l_rec_creditdetl.cust_code = glob_rec_credithead.cust_code 
		LET l_rec_creditdetl.cred_num = glob_rec_credithead.cred_num 
		LET l_rec_creditdetl.line_num = glob_rec_credithead.line_num + 1 
		LET l_rec_creditdetl.ware_code = glob_rec_warehouse.ware_code 

		IF l_rec_creditdetl.part_code IS NOT NULL THEN 
			LET l_rec_creditdetl.line_acct_code = build_mask( 
				glob_rec_kandoouser.cmpy_code, 
				glob_rec_credithead.acct_override_code, 
				l_rec_creditdetl.line_acct_code ) 
		END IF
		 
		IF l_rec_creditdetl.part_code IS NOT NULL	AND l_rec_creditdetl.ship_qty > 0 THEN 
			LET glob_temp_text = "A41 - Locking product STATUS RECORD FOR UPDATE" 
			DECLARE c2_prodstatus CURSOR FOR 
			SELECT * FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_creditdetl.ware_code 
			AND part_code = l_rec_creditdetl.part_code 
			FOR UPDATE 
			OPEN c2_prodstatus 
			FETCH c2_prodstatus INTO l_rec_prodstatus.*
			 
			LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				LET l_onhand_qty  = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty	+ l_rec_creditdetl.ship_qty 
			END IF 

			LET glob_temp_text = "A41 - Inserting product ledger RECORD " 
			LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_prodledg.part_code = l_rec_creditdetl.part_code 
			LET l_rec_prodledg.ware_code = l_rec_creditdetl.ware_code 
			LET l_rec_prodledg.tran_date = glob_rec_credithead.cred_date 
			LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
			LET l_rec_prodledg.trantype_ind = "C" 
			LET l_rec_prodledg.year_num = glob_rec_credithead.year_num 
			LET l_rec_prodledg.period_num = glob_rec_credithead.period_num 
			LET l_rec_prodledg.source_text = l_rec_creditdetl.cust_code 
			LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
			LET l_rec_prodledg.source_num = l_rec_creditdetl.cred_num 
			LET l_rec_prodledg.tran_qty = l_rec_creditdetl.ship_qty 

			IF glob_rec_credithead.conv_qty > 0 THEN 
				LET l_rec_prodledg.cost_amt = l_rec_creditdetl.unit_cost_amt	/ glob_rec_credithead.conv_qty 
				LET l_rec_prodledg.sales_amt = l_rec_creditdetl.unit_sales_amt	/ glob_rec_credithead.conv_qty 
			END IF 
			
			LET l_rec_prodledg.hist_flag = "N" 
			LET l_rec_prodledg.post_flag = "N" 
			LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_prodledg.entry_date = today 
			LET l_rec_prodledg.acct_code = NULL 

			INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

			IF l_rec_creditdetl.received_qty != l_rec_creditdetl.ship_qty THEN 

				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
				IF l_rec_prodstatus.stocked_flag = "Y" THEN 
					LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty 
						- ( l_rec_creditdetl.ship_qty - l_rec_creditdetl.received_qty) 
				END IF 

				LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
				LET l_rec_prodledg.trantype_ind = "A" 
				LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodledg.tran_qty = 0 - ( l_rec_creditdetl.ship_qty	- l_rec_creditdetl.received_qty) 

				SELECT adj_acct_code INTO l_rec_prodledg.acct_code 
				FROM category 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = l_rec_creditdetl.cat_code 
				
				IF status = NOTFOUND THEN 
					LET l_rec_prodledg.acct_code = NULL ## posting TO use suspense 
				END IF 

				INSERT INTO prodledg VALUES (l_rec_prodledg.*) 

			END IF 
			
			IF l_rec_prodstatus.stocked_flag = "Y" THEN 
				IF l_rec_prodstatus.wgted_cost_amt IS NULL THEN 
					LET l_rec_prodstatus.wgted_cost_amt = 0 
				END IF 

				IF l_rec_prodstatus.onhand_qty > 0 THEN 
					LET l_rec_prodstatus.wgted_cost_amt =	( 
					( l_rec_prodstatus.wgted_cost_amt * l_onhand_qty  ) 
					+ ( l_rec_creditdetl.unit_cost_amt * ( l_rec_prodstatus.onhand_qty - l_onhand_qty  ))
					) 
					/ l_rec_prodstatus.onhand_qty 
				END IF 

			END IF 

			LET glob_temp_text = "A41 - Updating product STATUS RECORD " 
			UPDATE prodstatus 
			SET 
				onhand_qty = l_rec_prodstatus.onhand_qty, 
				wgted_cost_amt = l_rec_prodstatus.wgted_cost_amt, 
				seq_num = l_rec_prodstatus.seq_num 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND ware_code = l_rec_creditdetl.ware_code 
			AND part_code = l_rec_creditdetl.part_code 
		END IF 
		
		LET glob_temp_text = "A41 - Inserting credit line items" 
		
		INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
		
		LET glob_rec_credithead.line_num = glob_rec_credithead.line_num + 1 
		LET glob_rec_credithead.goods_amt = glob_rec_credithead.goods_amt	+ l_rec_creditdetl.ext_sales_amt 
		LET glob_rec_credithead.cost_amt = glob_rec_credithead.cost_amt + l_rec_creditdetl.ext_cost_amt 
		LET glob_rec_credithead.tax_amt = glob_rec_credithead.tax_amt + l_rec_creditdetl.ext_tax_amt 

		SELECT unique 1 FROM product 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_creditdetl.part_code 
		AND serial_flag = 'Y' 

		IF status <> NOTFOUND THEN 
			LET glob_temp_text = "A41f - serial_update " 
			LET l_rec_serialinfo.cmpy_code = l_rec_prodledg.cmpy_code 
			LET l_rec_serialinfo.part_code = l_rec_prodledg.part_code 
			LET l_rec_serialinfo.ware_code = l_rec_prodledg.ware_code 
			LET l_rec_serialinfo.credit_num = l_rec_creditdetl.cred_num 
			LET l_rec_serialinfo.cust_code = glob_rec_credithead.cust_code 
			LET l_rec_serialinfo.trantype_ind = "0" 
			LET status = serial_update(l_rec_serialinfo.*,l_rec_creditdetl.received_qty, '') 
			IF status <> 0 THEN 
				GOTO recovery 
				EXIT PROGRAM 
			END IF 
		END IF 
	END FOREACH 

	LET glob_temp_text = "A41 - Removing old serial info " 
	LET status = serial_return('','S') 

	LET glob_temp_text = "A41 - Updating credit header RECORD " 
	LET glob_rec_credithead.total_amt = 
		glob_rec_credithead.goods_amt 
		+ glob_rec_credithead.tax_amt 
		+ glob_rec_credithead.freight_amt 
		+ glob_rec_credithead.freight_tax_amt 
		+ glob_rec_credithead.hand_amt 
		+ glob_rec_credithead.hand_tax_amt 

	LET glob_temp_text = "A41 - Inserting AR audit reccord FOR credit UPDATE" 
	LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_araudit.tran_date = glob_rec_credithead.cred_date 
	LET l_rec_araudit.cust_code = glob_rec_credithead.cust_code 
	LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num + 1 
	LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
	LET l_rec_araudit.source_num = glob_rec_credithead.cred_num 

	IF glob_rec_credithead.cred_ind = "4" THEN 
		LET l_rec_araudit.tran_text = "Adjustment" 
	ELSE 
		LET l_rec_araudit.tran_text = "Credit Entry" 
	END IF 

	LET l_rec_araudit.tran_amt = 0 - glob_rec_credithead.total_amt 
	LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
	LET l_rec_araudit.sales_code = glob_rec_credithead.sale_code 
	LET l_rec_araudit.year_num = glob_rec_credithead.year_num 
	LET l_rec_araudit.period_num = glob_rec_credithead.period_num 
	LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt - glob_rec_credithead.total_amt 
	LET l_rec_araudit.currency_code = glob_rec_credithead.currency_code 
	LET l_rec_araudit.conv_qty = glob_rec_credithead.conv_qty 
	LET l_rec_araudit.entry_date = today 
	
	INSERT INTO araudit VALUES (l_rec_araudit.*) 

	LET glob_temp_text = "A41 - Updating customer RECORD FOR credit UPDATE" 
	LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
	LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt - glob_rec_credithead.total_amt 
	LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt - glob_rec_credithead.total_amt 
	LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt - glob_rec_customer.bal_amt 
	LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt - glob_rec_credithead.total_amt 
	LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt - glob_rec_credithead.total_amt 
	
	UPDATE customer 
	SET 
		next_seq_num = glob_rec_customer.next_seq_num, 
		bal_amt = glob_rec_customer.bal_amt, 
		curr_amt = glob_rec_customer.curr_amt, 
		highest_bal_amt = glob_rec_customer.highest_bal_amt, 
		cred_bal_amt = glob_rec_customer.cred_bal_amt, 
		ytds_amt = glob_rec_customer.ytds_amt, 
		mtds_amt = glob_rec_customer.mtds_amt 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = glob_rec_credithead.cust_code 

	UPDATE credithead 
	SET * = glob_rec_credithead.* 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cred_num = glob_rec_credithead.cred_num 
	AND cust_code = glob_rec_credithead.cust_code 

	RETURN glob_rec_credithead.cred_num 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LABEL recovery: 

	RETURN sqlca.sqlcode 
END FUNCTION 
#################################################################
# END FUNCTION update_credit()
#################################################################