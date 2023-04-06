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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E5_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E53_GLOBALS.4gl" 
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_err_message char(60)
###########################################################################
# FUNCTION generate_cred(p_cmpy,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind)
#
#  This FUNCTION produces a credit note FOR ALL negative sale ORDER
#  line items.
#              ie: 't_inv_head' lines with invtype_ind = 4
#
# p_rowid      : unique reference TO the proposed_cred table.
#               : (t_inv_head - SET up in prior FUNCTION)
#
# p_verbose_ind: indicates the destination of MESSAGEs
#                 TRUE  -> MESSAGEs go TO SCREEN
#                 FALSE -> MESSAGEs go TO deliv_msg table
#
###########################################################################
FUNCTION generate_cred(p_cmpy,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code
	DEFINE p_rowid INTEGER
	DEFINE p_verbose_ind char(1)

	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_orderhead RECORD LIKE orderhead.*
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.*
	DEFINE l_rec_credithead RECORD LIKE credithead.*
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_credheadaddr RECORD LIKE credheadaddr.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_arparms RECORD LIKE arparms.*
	DEFINE l_rec_araudit RECORD LIKE araudit.*
	DEFINE l_rec_tax RECORD LIKE tax.*
	DEFINE l_outstg_freight LIKE credithead.freight_amt
	DEFINE l_outstg_hand LIKE credithead.hand_amt
	DEFINE l_rec_inv_head RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		cred_ind SMALLINT, 
		cust_code char(8), 
		order_num INTEGER, 
		pick_date DATE, 
		hold_code char(3), 
		calc_freight_amt decimal(16,2), 
		freight_amt decimal(16,2), 
		calc_hand_amt decimal(16,2), 
		hand_amt decimal(16,2), 
		ship_date DATE, 
		inv_date DATE, 
		year_num SMALLINT, 
		period_num SMALLINT, 
		com1_text char(30), 
		com2_text char(30) 
	END RECORD 
	DEFINE l_rec_inv_detl RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		order_num INTEGER, 
		order_line_num INTEGER, 
		order_rev_num INTEGER, 
		last_cred_num INTEGER, 
		order_date DATE, 
		part_code char(15), 
		picked_qty FLOAT, 
		sold_qty FLOAT, 
		offer_code char(3), 
		reduce_inv_flag char(1) 
	END RECORD 

	SELECT * INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 
	SELECT * INTO l_rec_inv_head.* 
	FROM t_inv_head 
	WHERE rowid = p_rowid 
	IF sqlca.sqlcode = NOTFOUND THEN 
		error" Temp error msg - propsed credd cred NOT found" 
		RETURN 0 
	END IF 

	IF NOT valid_period2(p_cmpy,l_rec_inv_head.year_num,	l_rec_inv_head.period_num,"OE") THEN 
		CALL get_fiscal_year_period_for_date(p_cmpy,l_rec_inv_head.inv_date) 
		RETURNING l_rec_inv_head.year_num, 
		l_rec_inv_head.period_num 
		IF NOT valid_period2(p_cmpy,l_rec_inv_head.year_num, 
		l_rec_inv_head.period_num,"OE") THEN 
			LET modu_err_message = ": ",l_rec_inv_head.year_num, 
			"/",l_rec_inv_head.period_num 
			CALL error_msg(p_cmpy,7051,modu_err_message,p_verbose_ind) 
			RETURN 0 
		END IF 
	END IF 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		####
		##   the credithead IS SET up in field ORDER
		####
		LET l_rec_credithead.cmpy_code = p_cmpy 
		##   SET up the customer(s)
		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_inv_head.cust_code 
		AND delete_flag = "N" 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ROLLBACK WORK 
			#7052 sales ORDER customer IS invalid
			CALL error_msg("E",7052,l_rec_inv_head.cust_code,p_verbose_ind) 
			RETURN 0 
		END IF 
		IF l_rec_customer.corp_cust_code IS NOT NULL AND 
		l_rec_customer.corp_cust_ind = "1" THEN 
			LET l_rec_credithead.cust_code = l_rec_customer.corp_cust_code 
			LET l_rec_credithead.org_cust_code = l_rec_customer.cust_code 
		ELSE 
			LET l_rec_credithead.cust_code = l_rec_customer.cust_code 
			LET l_rec_credithead.org_cust_code = "" 
		END IF 

		DECLARE c_customer cursor FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = l_rec_credithead.cust_code 
		AND delete_flag = "N" 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ROLLBACK WORK 
			#7052 customer does NOT exists
			CALL error_msg("E",7052,l_rec_credithead.cust_code,p_verbose_ind) 
			RETURN 0 
		END IF 

		IF NOT valid_cust(p_cmpy,p_rowid,p_verbose_ind, 
		l_rec_inv_head.cred_ind, 
		l_rec_credithead.cust_code, 
		l_rec_credithead.org_cust_code) THEN 
			ROLLBACK WORK 
			RETURN 0 
		END IF 

		SELECT * INTO l_rec_orderhead.* 
		FROM orderhead 
		WHERE cmpy_code = p_cmpy 
		AND order_num = l_rec_inv_head.order_num 

		##   the new cred number
		LET l_rec_credithead.cred_num = 
		next_trans_num(p_cmpy,TRAN_TYPE_CREDIT_CR,l_rec_orderhead.acct_override_code) 
		IF l_rec_credithead.cred_num < 0 THEN 
			LET modu_err_message = "Error occurred generating next cred number" 
			LET status = l_rec_credithead.cred_num 
			GOTO recovery 
		END IF 
		####
		##   other credit header fields
		LET modu_err_message = "setting up credit information" 
		LET l_rec_credithead.rma_num = l_rec_inv_head.order_num 
		LET l_rec_credithead.cred_text = l_rec_orderhead.ord_text 
		LET l_rec_credithead.entry_code= l_rec_orderhead.entry_code 
		LET l_rec_credithead.entry_date= l_rec_orderhead.entry_date 
		LET l_rec_credithead.cred_date = l_rec_inv_head.inv_date 
		LET l_rec_credithead.sale_code = l_rec_orderhead.sales_code 
		LET l_rec_credheadaddr.cred_num = l_rec_credithead.cred_num 
		LET l_rec_credheadaddr.cmpy_code = p_cmpy 
		LET l_rec_credheadaddr.addr1_text = l_rec_orderhead.ship_addr1_text 
		LET l_rec_credheadaddr.addr2_text = l_rec_orderhead.ship_addr1_text 
		LET l_rec_credheadaddr.city_text = l_rec_orderhead.ship_city_text 
		LET l_rec_credheadaddr.state_code = l_rec_orderhead.state_code 
		LET l_rec_credheadaddr.post_code = l_rec_orderhead.post_code 
		####
		##   tax codes & amounts
		LET modu_err_message = "calculating freight & handling" 
		LET l_rec_credithead.hand_amt = l_rec_inv_head.hand_amt 
		LET l_rec_credithead.freight_amt = l_rec_inv_head.freight_amt 
		LET l_rec_credithead.tax_code = l_rec_orderhead.tax_code 
		LET l_rec_credithead.hand_tax_code = l_rec_orderhead.hand_tax_code 
		LET l_rec_credithead.freight_tax_code = l_rec_orderhead.freight_tax_code 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE cmpy_code = p_cmpy 
		AND tax_code = l_rec_credithead.tax_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_tax.tax_per = 0 
			LET l_rec_tax.hand_per = 0 
			LET l_rec_tax.freight_per = 0 
		END IF 
		LET l_rec_credithead.tax_per = l_rec_tax.tax_per 
		LET l_rec_credithead.hand_tax_amt = l_rec_tax.hand_per 	* l_rec_inv_head.hand_amt/100 
		LET l_rec_credithead.freight_tax_amt = l_rec_tax.freight_per 	* l_rec_inv_head.freight_amt/100 
		LET l_rec_credithead.tax_amt = 0 
		####
		##   remaining credit fields
		LET modu_err_message = "setting up credit information" 
		LET l_rec_credithead.total_amt = 0 
		LET l_rec_credithead.goods_amt = 0 
		LET l_rec_credithead.cost_amt = 0 
		LET l_rec_credithead.appl_amt = 0 
		LET l_rec_credithead.disc_amt = 0 
		LET l_rec_credithead.year_num = l_rec_inv_head.year_num 
		LET l_rec_credithead.period_num = l_rec_inv_head.period_num 
		LET l_rec_credithead.on_state_flag = "N" 
		LET l_rec_credithead.posted_flag = "N" 
		LET l_rec_credithead.next_num = 0 
		LET l_rec_credithead.line_num = 0 
		LET l_rec_credithead.printed_num = 0 
		LET l_rec_credithead.com1_text = l_rec_inv_head.com1_text 
		LET l_rec_credithead.com2_text = l_rec_inv_head.com2_text 
		LET l_rec_credithead.rev_date = today 
		LET l_rec_credithead.rev_num = 0 
		LET l_rec_credithead.cost_ind = l_rec_orderhead.cost_ind 
		LET l_rec_credithead.currency_code = l_rec_orderhead.currency_code 
		LET l_rec_credithead.conv_qty = l_rec_orderhead.conv_qty 
		LET l_rec_credithead.cred_ind = "5" ### negative sales ORDER confirmation 
		LET l_rec_credithead.acct_override_code = l_rec_orderhead.acct_override_code 
		LET l_rec_credithead.price_tax_flag = l_rec_orderhead.price_tax_flag 
		LET l_rec_credithead.reason_code = l_rec_arparms.reason_code 
		LET modu_err_message = "retreiving line item information"
		 
		DECLARE c_inv_detl cursor FOR 
		SELECT * FROM t_inv_detl 
		WHERE inv_rowid = p_rowid 
		ORDER BY order_num, 
		order_line_num
		 
		FOREACH c_inv_detl INTO p_rowid, 
			l_rec_inv_detl.* 
			SELECT * INTO l_rec_orderdetl.* 
			FROM orderdetl 
			WHERE cmpy_code = p_cmpy 
			AND order_num = l_rec_inv_detl.order_num 
			AND line_num = l_rec_inv_detl.order_line_num 
			LET l_rec_credithead.line_num = l_rec_credithead.line_num + 1 
			LET l_rec_creditdetl.cmpy_code = p_cmpy 
			LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
			LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
			LET l_rec_creditdetl.line_num = l_rec_credithead.line_num 
			LET l_rec_creditdetl.part_code = l_rec_orderdetl.part_code 
			LET l_rec_creditdetl.ware_code = l_rec_inv_detl.ware_code 
			LET l_rec_creditdetl.cat_code = l_rec_orderdetl.cat_code 
			LET l_rec_creditdetl.ship_qty = 0 - l_rec_inv_detl.picked_qty 
			LET l_rec_creditdetl.ser_ind = l_rec_orderdetl.serial_flag 
			LET l_rec_creditdetl.line_text = l_rec_orderdetl.desc_text 
			LET l_rec_creditdetl.uom_code = l_rec_orderdetl.uom_code 

			SELECT wgted_cost_amt INTO l_rec_prodstatus.wgted_cost_amt 
			FROM prodstatus 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = l_rec_creditdetl.ware_code 
			AND part_code = l_rec_creditdetl.part_code 
			IF sqlca.sqlcode = 0 AND l_rec_credithead.conv_qty > 0 THEN 
				LET l_rec_creditdetl.unit_cost_amt = l_rec_prodstatus.wgted_cost_amt	* l_rec_credithead.conv_qty 
			ELSE 
				LET l_rec_creditdetl.unit_cost_amt = l_rec_orderdetl.unit_cost_amt 
			END IF 
			
			LET l_rec_creditdetl.ext_cost_amt = l_rec_creditdetl.ship_qty	* l_rec_creditdetl.unit_cost_amt 
			LET l_rec_creditdetl.unit_sales_amt = l_rec_orderdetl.unit_price_amt 
			LET l_rec_creditdetl.ext_sales_amt = l_rec_creditdetl.ship_qty			* l_rec_creditdetl.unit_sales_amt 
			LET l_rec_creditdetl.unit_tax_amt = l_rec_orderdetl.unit_tax_amt 
			LET l_rec_creditdetl.ext_tax_amt = l_rec_creditdetl.ship_qty 	* l_rec_orderdetl.unit_tax_amt 
			LET l_rec_creditdetl.line_total_amt = l_rec_creditdetl.ext_sales_amt			+ l_rec_creditdetl.ext_tax_amt 
			LET l_rec_creditdetl.seq_num = 0 
			LET l_rec_creditdetl.line_acct_code = l_rec_orderdetl.acct_code 
			LET l_rec_creditdetl.level_code = l_rec_orderdetl.level_ind 
			LET l_rec_creditdetl.comm_amt = 0 
			LET l_rec_creditdetl.tax_code = l_rec_orderdetl.tax_code 
			LET l_rec_creditdetl.reason_code = l_rec_arparms.reason_code 
			LET l_rec_creditdetl.received_qty = l_rec_creditdetl.ship_qty 
			LET l_rec_creditdetl.invoice_num = 0 
			LET l_rec_creditdetl.inv_line_num = 0 

			####
			## UPDATE product STATUS
			IF l_rec_creditdetl.ship_qty != 0 THEN # generate prodledg 
				LET modu_err_message = "locking & updating the Product status" 
				DECLARE c_prodstatus cursor FOR
				 
				SELECT * FROM prodstatus 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_rec_creditdetl.part_code 
				AND ware_code = l_rec_creditdetl.ware_code 
				FOR UPDATE 
				OPEN c_prodstatus 
				FETCH c_prodstatus INTO l_rec_prodstatus.* 
				
				IF sqlca.sqlcode = 0 THEN 
					IF l_rec_prodstatus.stocked_flag = "Y" THEN 
						UPDATE prodstatus 
						SET onhand_qty = onhand_qty 
						+ l_rec_creditdetl.ship_qty, 
						seq_num = seq_num + 1 
						WHERE cmpy_code = p_cmpy 
						AND part_code = l_rec_creditdetl.part_code 
						AND ware_code = l_rec_creditdetl.ware_code 
					ELSE 
						UPDATE prodstatus 
						SET seq_num = seq_num + 1 
						WHERE cmpy_code = p_cmpy 
						AND part_code = l_rec_creditdetl.part_code 
						AND ware_code = l_rec_creditdetl.ware_code 
					END IF 
					LET modu_err_message = "Calculating product ledger entry" 
					INITIALIZE l_rec_prodledg.* TO NULL 
					LET l_rec_prodledg.cmpy_code = p_cmpy 
					LET l_rec_prodledg.part_code = l_rec_creditdetl.part_code 
					LET l_rec_prodledg.ware_code = l_rec_creditdetl.ware_code 
					LET l_rec_prodledg.tran_date = l_rec_credithead.cred_date 
					LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num + 1 
					LET l_rec_prodledg.trantype_ind = "C" 
					LET l_rec_prodledg.year_num = l_rec_credithead.year_num 
					LET l_rec_prodledg.period_num = l_rec_credithead.period_num 
					LET l_rec_prodledg.source_text = l_rec_credithead.cust_code 
					LET l_rec_prodledg.source_num = l_rec_credithead.cred_num 
					LET l_rec_prodledg.tran_qty = l_rec_creditdetl.ship_qty 
					LET l_rec_prodledg.cost_amt = l_rec_creditdetl.unit_cost_amt 	/ l_rec_credithead.conv_qty 
					LET l_rec_prodledg.sales_amt = l_rec_creditdetl.unit_sales_amt	/ l_rec_credithead.conv_qty 
					
					SELECT unique 1 FROM inparms 
					WHERE cmpy_code = p_cmpy 
					AND parm_code = "1" 
					AND hist_flag = "Y" 
					IF sqlca.sqlcode = 0 THEN 
						LET l_rec_prodledg.hist_flag = "N" 
					ELSE 
						LET l_rec_prodledg.hist_flag = "Y" 
					END IF
					 
					LET l_rec_prodledg.post_flag = "N" 
					LET l_rec_prodledg.acct_code = NULL 
					LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty + l_rec_creditdetl.ship_qty 
					LET modu_err_message = "Storing product ledger entry" 
					INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
				END IF 
			END IF 
			LET modu_err_message = "Updating ORDER detail Line items"
			 
			#### Updating orderdetl quantities (ALL qty's are < 0)
			IF l_rec_orderdetl.status_ind = "1" THEN 
				UPDATE orderdetl 
				SET inv_qty = inv_qty - l_rec_creditdetl.ship_qty, 
				conf_qty = conf_qty + l_rec_creditdetl.ship_qty 
				WHERE cmpy_code = l_rec_orderdetl.cmpy_code 
				AND order_num = l_rec_orderdetl.order_num 
				AND line_num = l_rec_orderdetl.line_num 
			ELSE 
				UPDATE orderdetl 
				SET inv_qty = inv_qty - l_rec_creditdetl.ship_qty, 
				sched_qty = sched_qty + l_rec_creditdetl.ship_qty 
				WHERE cmpy_code = l_rec_orderdetl.cmpy_code 
				AND order_num = l_rec_orderdetl.order_num 
				AND line_num = l_rec_orderdetl.line_num 
			END IF 
			LET modu_err_message = "Storing cred line items TO the database" 
			
			INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
			
			LET l_rec_credithead.cost_amt = l_rec_credithead.cost_amt 	+ l_rec_creditdetl.ext_cost_amt 
			LET l_rec_credithead.goods_amt = l_rec_credithead.goods_amt	+ l_rec_creditdetl.ext_sales_amt 
			LET l_rec_credithead.tax_amt = l_rec_credithead.tax_amt		+ l_rec_creditdetl.ext_tax_amt 
		END FOREACH
		 
		LET modu_err_message = "calculating the total amounts of the credit" 
		LET l_rec_credithead.total_amt = l_rec_credithead.goods_amt 
		+ l_rec_credithead.tax_amt 
		+ l_rec_credithead.hand_amt 
		+ l_rec_credithead.hand_tax_amt 
		+ l_rec_credithead.freight_amt 
		+ l_rec_credithead.freight_tax_amt 
		LET modu_err_message = "Storing credit information TO the database" 
		
		INSERT INTO credithead VALUES (l_rec_credithead.*) 
		
		IF l_rec_credheadaddr.addr1_text IS NOT NULL 
		OR l_rec_credheadaddr.addr2_text IS NOT NULL 
		OR l_rec_credheadaddr.city_text IS NOT NULL 
		OR l_rec_credheadaddr.state_code IS NOT NULL 
		OR l_rec_credheadaddr.post_code IS NOT NULL THEN 
			INSERT INTO credheadaddr VALUES (l_rec_credheadaddr.*) 
		END IF 
		
		INSERT INTO stattrig VALUES (p_cmpy,TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_num, 
		l_rec_credithead.cred_date) 
		LET modu_err_message = "Updating the sales ORDER information" 
		IF l_rec_orderhead.status_ind = "U" THEN 
			LET l_rec_orderhead.status_ind = "P" 
		END IF
		 
		SELECT unique 1 FROM orderdetl 
		WHERE cmpy_code = p_cmpy 
		AND order_num = l_rec_orderhead.order_num 
		AND order_qty != 0 
		AND inv_qty != order_qty 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_orderhead.status_ind = "C" 
		END IF 
		LET modu_err_message = "UPDATE sales ORDER information"
		 
		UPDATE orderhead 
		SET status_ind = l_rec_orderhead.status_ind 
		WHERE cmpy_code = p_cmpy 
		AND order_num = l_rec_orderhead.order_num 
		LET modu_err_message = "Storing customer AR audit entry TO the database"
		 
		INITIALIZE l_rec_araudit.* TO NULL 
		LET l_rec_araudit.cmpy_code = p_cmpy 
		LET l_rec_araudit.tran_date = l_rec_credithead.cred_date 
		LET l_rec_araudit.cust_code = l_rec_credithead.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
		LET l_rec_araudit.tran_text = "Stock Trade in" 
		LET l_rec_araudit.tran_amt = 0 - l_rec_credithead.total_amt 
		LET l_rec_araudit.entry_code = l_rec_credithead.entry_code 
		LET l_rec_araudit.sales_code = l_rec_credithead.sale_code 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt 
		- l_rec_credithead.total_amt 
		LET l_rec_araudit.year_num = l_rec_credithead.year_num 
		LET l_rec_araudit.period_num = l_rec_credithead.period_num 
		LET l_rec_araudit.currency_code = l_rec_credithead.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
		LET l_rec_araudit.entry_date = today 
		
		INSERT INTO araudit VALUES (l_rec_araudit.*)
		 
		#####
		## Update customer(s)
		LET modu_err_message = "Updating the customer master file" 
		LET l_rec_customer.curr_amt = l_rec_customer.curr_amt	- l_rec_credithead.total_amt 
		IF year(l_rec_credithead.cred_date)>year(l_rec_customer.last_inv_date) THEN 
			LET l_rec_customer.ytds_amt = 0 
			LET l_rec_customer.mtds_amt = 0 
		END IF 
		LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt	- l_rec_credithead.total_amt 
		IF month(l_rec_credithead.cred_date)>month(l_rec_customer.last_inv_date) THEN 
			LET l_rec_customer.mtds_amt = 0 
		END IF 
		LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt	- l_rec_credithead.total_amt 
		LET l_outstg_freight = 0 
		LET l_outstg_hand = 0 
		IF l_rec_orderhead.status_ind = "C" THEN 
			LET l_outstg_freight = l_rec_orderhead.freight_amt- l_rec_orderhead.freight_inv_amt 
			LET l_outstg_hand = l_rec_orderhead.hand_amt - l_rec_orderhead.hand_inv_amt 
			IF l_outstg_freight IS NULL 
			OR l_outstg_freight < 0 THEN 
				LET l_outstg_freight = 0 
			END IF 
			IF l_outstg_hand IS NULL 
			OR l_outstg_hand < 0 THEN 
				LET l_outstg_hand = 0 
			END IF 
		END IF
		 
		# IF the ORDER IS complete THEN reduce the remainder of f&h
		IF l_rec_credithead.org_cust_code IS NULL THEN 
			LET l_rec_customer.onorder_amt = l_rec_customer.onorder_amt 
			+ l_rec_credithead.goods_amt 
			+ l_rec_credithead.tax_amt 
			- l_outstg_freight 
			- l_outstg_hand 
		ELSE 
			UPDATE customer 
			SET onorder_amt = onorder_amt + l_rec_credithead.goods_amt 
			+ l_rec_credithead.tax_amt 
			- l_outstg_freight 
			- l_outstg_hand 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_credithead.org_cust_code 
		END IF
		 
		UPDATE customer 
		SET next_seq_num = l_rec_customer.next_seq_num + 1, 
		bal_amt = l_rec_customer.bal_amt - l_rec_credithead.total_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		cred_bal_amt = l_rec_customer.cred_limit_amt 
		- l_rec_customer.bal_amt, 
		ytds_amt = l_rec_customer.ytds_amt, 
		mtds_amt = l_rec_customer.mtds_amt, 
		onorder_amt = l_rec_customer.onorder_amt 
		WHERE cust_code = l_rec_customer.cust_code 
		AND cmpy_code = p_cmpy
		 
	COMMIT WORK
	 
	WHENEVER ERROR stop 
	RETURN l_rec_credithead.cred_num
	 
	LABEL recovery: 
	ROLLBACK WORK 
	
	CALL error_msg(p_cmpy,7050,modu_err_message,p_verbose_ind) 
	RETURN 0 
END FUNCTION
###########################################################################
# END FUNCTION generate_cred(p_cmpy,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind)
###########################################################################
