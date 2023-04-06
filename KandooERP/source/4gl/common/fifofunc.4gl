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

	Source code beautified by beautify.pl on 2020-01-02 10:35:11	$Id: $
}



GLOBALS "../common/glob_GLOBALS.4gl" 

#
# FUNCTION fifo_lifo_issue
#
# This routine processes cost ledger entries FOR inventory
# issues (eg. sales OR -ve adjustments). It reads through the
# cost ledger entries FOR the nominated part AND warehouse in
# FIFO OR LIFO ORDER, depending on the cost indicator AND
# calculates the average FIFO/LIFO cost per unit.
# IF run in UPDATE mode, it will also reduce the on-hand quantities
# on the cost ledger entries.
#
# Parameters: p_cmpy          = the calling company code
#             p_part_code     = the product code of the associated
#                                product ledger entry
#             p_ware_code     = the warehouse code of the associated
#                                product ledger entry
#             p_tran_date     = the transaction date of the associated
#                                product ledger entry
#             p_seq_num       = the sequence number of the associated
#                                product ledger entry
#             p_trantype_ind  = the tran type indicator of the
#                                associated product ledger entry
#             p_issue_qty     = the quantity issued (+ve value)
#             p_cost_ind      = "F" FOR FIFO, "L" FOR LIFO
#             p_update_ind    = TRUE TO UPDATE ledgers, FALSE OTHERWISE
#
FUNCTION fifo_lifo_issue(p_cmpy,p_part_code,p_ware_code,p_tran_date,p_seq_num,p_trantype_ind,p_issue_qty,p_cost_ind,p_update_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE p_seq_num LIKE prodledg.seq_num 
	DEFINE p_trantype_ind LIKE prodledg.trantype_ind 
	DEFINE p_issue_qty LIKE prodledg.tran_qty 
	DEFINE p_cost_ind CHAR(1) 
	DEFINE p_update_ind SMALLINT 
	DEFINE l_remain_qty LIKE prodledg.tran_qty 
	DEFINE l_cost_qty LIKE prodledg.tran_qty 
	DEFINE l_total_cost LIKE prodledg.cost_amt 
	DEFINE l_cost_amt LIKE prodledg.cost_amt
	DEFINE l_act_cost_amt LIKE prodstatus.act_cost_amt 
	DEFINE l_rec_costledg RECORD LIKE costledg.* 
	DEFINE l_onhand_qty LIKE costledg.onhand_qty 
	DEFINE l_curr_cost_amt LIKE costledg.curr_cost_amt 
	DEFINE l_cost_tran_date LIKE costledg.tran_date 
	DEFINE l_rowid INTEGER 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_order_text CHAR(20) 
	DEFINE l_err_message CHAR(80) 

	GOTO fifo_bypass1 
	LABEL fifo_status1: 
	RETURN FALSE, STATUS, 0 
	LABEL fifo_bypass1: 
	WHENEVER ERROR GOTO fifo_status1 

	LET l_total_cost = 0 
	LET l_remain_qty = p_issue_qty 
	IF p_cost_ind = "F" THEN 
		LET l_order_text = "tran_date" 
	ELSE 
		LET l_order_text = "tran_date desc" 
	END IF 
	LET l_query_text = 
	"SELECT onhand_qty, curr_cost_amt, tran_date, rowid", 
	" FROM costledg", 
	" WHERE cmpy_code = '", p_cmpy, "'", 
	" AND part_code = '", p_part_code, "'", 
	" AND ware_code = '", p_ware_code, "'", 
	" AND onhand_qty > 0", 
	" ORDER BY ", l_order_text CLIPPED 
	PREPARE s1_costledg FROM l_query_text 
	DECLARE c1_costledg CURSOR FOR s1_costledg 
	FOREACH c1_costledg INTO l_onhand_qty, 
		l_curr_cost_amt, 
		l_cost_tran_date, 
		l_rowid 
		#
		# IF in UPDATE mode, FETCH the quantity AND cost details again,
		# simultaneously locking the row FOR UPDATE
		#
		IF p_update_ind THEN 
			DECLARE c2_costledg CURSOR FOR 
			SELECT onhand_qty, curr_cost_amt 
			FROM costledg 
			WHERE rowid = l_rowid 
			FOR UPDATE 
			OPEN c2_costledg 
			FETCH c2_costledg INTO l_onhand_qty, l_curr_cost_amt 
		END IF 
		IF l_remain_qty < l_onhand_qty THEN 
			LET l_cost_qty = l_remain_qty 
		ELSE 
			LET l_cost_qty = l_onhand_qty 
		END IF 
		LET l_total_cost = l_total_cost + 
		(l_curr_cost_amt * l_cost_qty) 
		LET l_remain_qty = l_remain_qty - l_cost_qty 
		IF p_update_ind THEN 
			LET l_err_message = "FUNCTION fifo_lifo_issue - UPDATE costledg" 
			UPDATE costledg 
			SET onhand_qty = l_onhand_qty - l_cost_qty 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part_code 
			AND ware_code = p_ware_code 
			AND rowid = l_rowid 
		END IF 
		IF l_remain_qty = 0 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	# IF there IS a mismatch between the fifo/lifo quantity records
	# AND the quantity issued, value the remaining quantity AT current
	# actual cost AND, IF in UPDATE mode, INSERT a cost ledger entry
	# TO reflect this.

	IF l_remain_qty > 0 THEN 
		SELECT act_cost_amt 
		INTO l_act_cost_amt 
		FROM prodstatus 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = p_ware_code 
		LET l_total_cost = l_total_cost + 
		(l_remain_qty * l_act_cost_amt) 
		IF p_update_ind THEN 
			INITIALIZE l_rec_costledg.* TO NULL 
			LET l_rec_costledg.cmpy_code = p_cmpy 
			LET l_rec_costledg.part_code = p_part_code 
			LET l_rec_costledg.ware_code = p_ware_code 
			LET l_rec_costledg.tran_date = p_tran_date 
			LET l_rec_costledg.seq_num = p_seq_num 
			LET l_rec_costledg.trantype_ind = p_trantype_ind 
			LET l_rec_costledg.received_qty = l_remain_qty * -1 
			LET l_rec_costledg.onhand_qty = l_remain_qty * -1 
			LET l_rec_costledg.curr_cost_amt = l_act_cost_amt 
			LET l_rec_costledg.act_cost_amt = l_act_cost_amt 
			LET l_rec_costledg.tax_cost_amt = l_act_cost_amt 
			LET l_rec_costledg.curr_wo_amt = 0 
			LET l_rec_costledg.prev_wo_amt = 0 
			LET l_rec_costledg.tax_wo_amt = 0 
			LET l_rec_costledg.prev_tax_wo_amt = 0 
			LET l_rec_costledg.pre85_tax_wo_amt = 0 
			LET l_rec_costledg.curr_tot_wo_amt = 0 
			LET l_rec_costledg.prev_tot_wo_amt = 0 
			LET l_rec_costledg.tax_tot_wo_amt = 0 
			LET l_rec_costledg.prv_tot_tax_wo_amt = 0 
			LET l_rec_costledg.p85_tot_tax_wo_amt = 0 
			LET l_rec_costledg.last_cost_date = p_tran_date 
			LET l_rec_costledg.last_tax_date = p_tran_date 
			LET l_err_message = "FUNCTION fifo_lifo_issue - INSERT cost ledger" 
			INSERT INTO costledg VALUES (l_rec_costledg.*) 
		END IF 
	END IF 
	IF p_issue_qty <> 0 THEN 
		LET l_cost_amt = l_total_cost / p_issue_qty 
	ELSE 
		LET l_cost_amt = l_total_cost 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true, 0, l_cost_amt 
END FUNCTION 

#
# FUNCTION fifo_lifo_receipt
#
# This routine processes cost ledger entries FOR inventory
# receipts (eg. receipts, sales OR +ve adjustments). It reads through
# the cost ledger entries FOR the nominated part AND warehouse in
# FIFO OR LIFO ORDER, depending on the cost indicator AND
# either restores the onhand quantity in entries WHERE the quantity IS
# less than zero OR inserts a new entry FOR the received quantity
#
# Parameters: p_cmpy          = the calling company code
#             p_part_code     = the product code of the associated
#                                product ledger entry
#             p_ware_code     = the warehouse code of the associated
#                                product ledger entry
#             p_tran_date     = the transaction date of the associated
#                                product ledger entry
#             p_seq_num       = the sequence number of the associated
#                                product ledger entry
#             p_trantype_ind  = the tran type indicator of the
#                                associated product ledger entry
#             pr_issue_qty     = the quantity issued (+ve value)
#             p_cost_ind      = "F" FOR FIFO, "L" FOR LIFO
#             p_cost_amt      = the unit cost of the receipt
#
FUNCTION fifo_lifo_receipt(p_cmpy,p_part_code,p_ware_code,p_tran_date,p_seq_num,p_trantype_ind,p_receipt_qty,p_cost_ind,p_cost_amt)
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE p_seq_num LIKE prodledg.seq_num 
	DEFINE p_trantype_ind LIKE prodledg.trantype_ind 
	DEFINE p_receipt_qty LIKE prodledg.tran_qty 
	DEFINE p_cost_ind CHAR(1) 
	DEFINE p_cost_amt LIKE prodledg.cost_amt 
	DEFINE l_remain_qty LIKE prodledg.tran_qty 
	DEFINE l_correction_qty LIKE prodledg.tran_qty
	DEFINE l_rec_costledg RECORD LIKE costledg.* 
	DEFINE l_onhand_qty LIKE costledg.onhand_qty 
	DEFINE l_cost_tran_date LIKE costledg.tran_date 
	DEFINE l_rowid INTEGER 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_order_text CHAR(20) 
	DEFINE l_err_message CHAR(80) 

	GOTO fifo_bypass2 
	LABEL fifo_status2: 
	RETURN FALSE, STATUS 
	LABEL fifo_bypass2: 
	WHENEVER ERROR GOTO fifo_status2 

	LET l_remain_qty = p_receipt_qty 
	IF p_cost_ind = "F" THEN 
		LET l_order_text = "tran_date" 
	ELSE 
		LET l_order_text = "tran_date desc" 
	END IF 
	LET l_query_text = 
	"SELECT onhand_qty, tran_date, rowid", 
	" FROM costledg", 
	" WHERE cmpy_code = '", p_cmpy, "'", 
	" AND part_code = '", p_part_code, "'", 
	" AND ware_code = '", p_ware_code, "'", 
	" AND onhand_qty < 0", 
	" ORDER BY ", l_order_text CLIPPED 
	PREPARE s3_costledg FROM l_query_text 
	DECLARE c3_costledg CURSOR FOR s3_costledg 
	FOREACH c3_costledg INTO l_onhand_qty, 
		l_cost_tran_date, 
		l_rowid 
		#
		# Fetch the quantity details again, simultaneously locking
		# the row FOR UPDATE
		#
		DECLARE c4_costledg CURSOR FOR 
		SELECT onhand_qty 
		FROM costledg 
		WHERE rowid = l_rowid 
		FOR UPDATE 
		OPEN c4_costledg 
		FETCH c4_costledg INTO l_onhand_qty 
		#
		# IF the absolute value of the cost ledger on hand quantity IS
		# less than OR equal TO the receipt quantity, THEN adjust the
		# on hand quantity by the full value, thus resettting it TO zero.
		# Reduce the remaining quantity TO be received by the adjustment amount.
		# IF the remaining receipt IS less than the absolute value (ie. the
		# receipt does NOT fully resupply the -ve entry) THEN simply adjust
		# the onhand quantity by the remaining receipt amount.
		#
		LET l_correction_qty = 0 - l_onhand_qty 
		IF l_remain_qty < l_correction_qty THEN 
			LET l_correction_qty = l_remain_qty 
		END IF 
		LET l_err_message = "FUNCTION fifo_lifo_receipt - UPDATE costledg" 
		UPDATE costledg 
		SET onhand_qty = l_onhand_qty + l_correction_qty 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = p_ware_code 
		AND rowid = l_rowid 
		LET l_remain_qty = l_remain_qty - l_correction_qty 
		IF l_remain_qty <= 0 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	# IF the receipt was NOT fully absorbed by correcting -ve on hand
	# quantities, add a new cost ledger entry FOR this receipt.

	IF l_remain_qty > 0 THEN 
		INITIALIZE l_rec_costledg.* TO NULL 
		LET l_rec_costledg.cmpy_code = p_cmpy 
		LET l_rec_costledg.part_code = p_part_code 
		LET l_rec_costledg.ware_code = p_ware_code 
		LET l_rec_costledg.tran_date = p_tran_date 
		LET l_rec_costledg.seq_num = p_seq_num 
		LET l_rec_costledg.trantype_ind = p_trantype_ind 
		LET l_rec_costledg.received_qty = l_remain_qty 
		LET l_rec_costledg.onhand_qty = l_remain_qty 
		LET l_rec_costledg.curr_cost_amt = p_cost_amt 
		LET l_rec_costledg.act_cost_amt = p_cost_amt 
		LET l_rec_costledg.tax_cost_amt = p_cost_amt 
		LET l_rec_costledg.curr_wo_amt = 0 
		LET l_rec_costledg.prev_wo_amt = 0 
		LET l_rec_costledg.tax_wo_amt = 0 
		LET l_rec_costledg.prev_tax_wo_amt = 0 
		LET l_rec_costledg.pre85_tax_wo_amt = 0 
		LET l_rec_costledg.curr_tot_wo_amt = 0 
		LET l_rec_costledg.prev_tot_wo_amt = 0 
		LET l_rec_costledg.tax_tot_wo_amt = 0 
		LET l_rec_costledg.prv_tot_tax_wo_amt = 0 
		LET l_rec_costledg.p85_tot_tax_wo_amt = 0 
		LET l_rec_costledg.last_cost_date = p_tran_date 
		LET l_rec_costledg.last_tax_date = p_tran_date 
		LET l_err_message = "FUNCTION fifo_lifo_issue - INSERT cost ledger" 
		INSERT INTO costledg VALUES (l_rec_costledg.*) 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true, 0 
END FUNCTION 

#
# FUNCTION fifo_lifo_xfer
#
# This routine processes cost ledger entries FOR inventory
# transfers. It reads through the cost ledger entries FOR the
# nominated part AND source warehouse in FIFO OR LIFO ORDER,
# depending on the cost indicator AND calculates the average
# FIFO/LIFO cost per unit.  It will also reduce the on-hand
# quantities on the source warehouse cost ledger entries AND
# create a receipt in the destination warehouse FOR each
# cost/quantity combination encountered.
#
# Parameters: p_cmpy           = the calling company code
#             p_part_code      = the product code of the associated
#                                 product ledger entry
#             p_dest_ware_code = the warehouse code of the destination
#                                 product ledger entry
#             p_dest_tran_date = the transaction date of the
#                                 destination product ledger entry
#             p_dest_seq_num   = the sequence number of the destination
#                                 product ledger entry
#             p_trantype_ind   = the tran type indicator of the
#                                 transfer product ledger entry
#             p_xfer_qty       = the quantity transferred (+ve value)
#             p_cost_ind       = "F" FOR FIFO, "L" FOR LIFO
#             p_src_ware_code  = the source warehouse code
#
FUNCTION fifo_lifo_xfer(p_cmpy,p_part_code,p_dest_ware_code,p_dest_tran_date,p_dest_seq_num,p_trantype_ind,p_xfer_qty,p_cost_ind,p_src_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_dest_ware_code LIKE warehouse.ware_code 
 	DEFINE p_dest_tran_date LIKE prodledg.tran_date 
	DEFINE p_dest_seq_num LIKE prodledg.seq_num 
	DEFINE p_trantype_ind LIKE prodledg.trantype_ind 
	DEFINE p_xfer_qty LIKE prodledg.tran_qty 
	DEFINE p_cost_ind CHAR(1) 
	DEFINE p_src_ware_code LIKE prodledg.source_text
	DEFINE l_remain_qty LIKE prodledg.tran_qty 
	DEFINE l_cost_qty LIKE prodledg.tran_qty 
	DEFINE l_total_cost LIKE prodledg.cost_amt 
	DEFINE l_cost_amt LIKE prodledg.cost_amt
	DEFINE l_act_cost_amt LIKE prodstatus.act_cost_amt 
	DEFINE l_rec_costledg RECORD LIKE costledg.* 
	DEFINE l_onhand_qty LIKE costledg.onhand_qty 
	DEFINE l_curr_cost_amt LIKE costledg.curr_cost_amt 
	DEFINE l_cost_tran_date LIKE costledg.tran_date 
	DEFINE l_db_status INTEGER 
	DEFINE l_rowid INTEGER
	DEFINE l_call_status SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_order_text CHAR(20) 
	DEFINE l_err_message CHAR(80)

	GOTO fifo_bypass3 
	LABEL fifo_status3: 
	RETURN FALSE, STATUS, 0 
	LABEL fifo_bypass3: 
	WHENEVER ERROR GOTO fifo_status3 

	LET l_total_cost = 0 
	LET l_remain_qty = p_xfer_qty 
	IF p_cost_ind = "F" THEN 
		LET l_order_text = "tran_date" 
	ELSE 
		LET l_order_text = "tran_date desc" 
	END IF 
	LET l_query_text = 
	"SELECT onhand_qty, curr_cost_amt, tran_date, rowid", 
	" FROM costledg", 
	" WHERE cmpy_code = '", p_cmpy, "'", 
	" AND part_code = '", p_part_code, "'", 
	" AND ware_code = '", p_src_ware_code, "'", 
	" AND onhand_qty > 0", 
	" ORDER BY ", l_order_text CLIPPED 
	PREPARE s5_costledg FROM l_query_text 
	DECLARE c5_costledg CURSOR FOR s5_costledg 
	FOREACH c5_costledg INTO l_onhand_qty, 
		l_curr_cost_amt, 
		l_cost_tran_date, 
		l_rowid 
		#
		# Fetch the quantity AND cost details again, simultaneously locking
		# the row FOR UPDATE
		#
		DECLARE c6_costledg CURSOR FOR 
		SELECT onhand_qty, curr_cost_amt 
		FROM costledg 
		WHERE rowid = l_rowid 
		FOR UPDATE 
		OPEN c6_costledg 
		FETCH c6_costledg INTO l_onhand_qty, l_curr_cost_amt 
		IF l_remain_qty < l_onhand_qty THEN 
			LET l_cost_qty = l_remain_qty 
		ELSE 
			LET l_cost_qty = l_onhand_qty 
		END IF 
		LET l_total_cost = l_total_cost + 
		(l_curr_cost_amt * l_cost_qty) 
		LET l_remain_qty = l_remain_qty - l_cost_qty 
		LET l_err_message = "FUNCTION fifo_lifo_xfer - UPDATE src costledg" 
		UPDATE costledg 
		SET onhand_qty = l_onhand_qty - l_cost_qty 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = p_src_ware_code 
		AND rowid = l_rowid 
		#
		# Create the corresponding receipt AT the destination warehouse
		#
		CALL fifo_lifo_receipt(p_cmpy, 
		p_part_code, 
		p_dest_ware_code, 
		p_dest_tran_date, 
		p_dest_seq_num, 
		p_trantype_ind, 
		l_cost_qty, 
		p_cost_ind, 
		l_curr_cost_amt) 
		RETURNING l_call_status, l_db_status 
		IF l_call_status = FALSE THEN 
			LET STATUS = l_db_status 
			GOTO fifo_status3 
		END IF 
		IF l_remain_qty = 0 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	# IF there IS a mismatch between the fifo/lifo quantity records
	# AND the quantity transferred, value the remaining quantity AT current
	# actual cost AND INSERT a negative cost ledger entry AT the source
	# warehouse TO reflect this, in addition TO the destination warehouse
	# receipt

	IF l_remain_qty > 0 THEN 
		SELECT act_cost_amt 
		INTO l_act_cost_amt 
		FROM prodstatus 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = p_src_ware_code 
		LET l_total_cost = l_total_cost + 
		(l_remain_qty * l_act_cost_amt) 
		INITIALIZE l_rec_costledg.* TO NULL 
		LET l_rec_costledg.cmpy_code = p_cmpy 
		LET l_rec_costledg.part_code = p_part_code 
		LET l_rec_costledg.ware_code = p_src_ware_code 
		LET l_rec_costledg.tran_date = p_dest_tran_date 
		LET l_rec_costledg.seq_num = p_dest_seq_num 
		LET l_rec_costledg.trantype_ind = p_trantype_ind 
		LET l_rec_costledg.received_qty = l_remain_qty * -1 
		LET l_rec_costledg.onhand_qty = l_remain_qty * -1 
		LET l_rec_costledg.curr_cost_amt = l_act_cost_amt 
		LET l_rec_costledg.act_cost_amt = l_act_cost_amt 
		LET l_rec_costledg.tax_cost_amt = l_act_cost_amt 
		LET l_rec_costledg.curr_wo_amt = 0 
		LET l_rec_costledg.prev_wo_amt = 0 
		LET l_rec_costledg.tax_wo_amt = 0 
		LET l_rec_costledg.prev_tax_wo_amt = 0 
		LET l_rec_costledg.pre85_tax_wo_amt = 0 
		LET l_rec_costledg.curr_tot_wo_amt = 0 
		LET l_rec_costledg.prev_tot_wo_amt = 0 
		LET l_rec_costledg.tax_tot_wo_amt = 0 
		LET l_rec_costledg.prv_tot_tax_wo_amt = 0 
		LET l_rec_costledg.p85_tot_tax_wo_amt = 0 
		LET l_rec_costledg.last_cost_date = p_dest_tran_date 
		LET l_rec_costledg.last_tax_date = p_dest_tran_date 
		LET l_err_message = "FUNCTION fifo_lifo_xfer - INSERT cost ledger" 
		INSERT INTO costledg VALUES (l_rec_costledg.*) 

		CALL fifo_lifo_receipt(p_cmpy, 
		p_part_code, 
		p_dest_ware_code, 
		p_dest_tran_date, 
		p_dest_seq_num, 
		p_trantype_ind, 
		l_remain_qty, 
		p_cost_ind, 
		l_act_cost_amt) 
		RETURNING l_call_status, l_db_status 
		IF l_call_status = FALSE THEN 
			LET STATUS = l_db_status 
			GOTO fifo_status3 
		END IF 
	END IF 
	IF p_xfer_qty <> 0 THEN 
		LET l_cost_amt = l_total_cost / p_xfer_qty 
	ELSE 
		LET l_cost_amt = l_total_cost 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true, 0, l_cost_amt 
END FUNCTION 


