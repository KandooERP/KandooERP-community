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
DEFINE modu_err_message char(60)#, 
# l_temp_text CHAR(400)

###########################################################################
# FUNCTION define_cursors(p_cmpy_code)
#
#  This FUNCTION confirms AND invoices one of the following
#
#     1. valid picking slip (incl. any non-inventory, non-stocked lines)
#        check cust & ORDER hold codes, credit limits
#     2. a sales ORDER made up only of non-invent, non-stocked lines
#        check cust & ORDER hold codes, credit limits
#     3. a sales ORDER made up only of pre-delivered lines
#        always invoice despite hold codes & credit limits
#
#    NB: Database i/o IS done using cursors WHERE possible FOR
#        efficiency reasons.  All cursors are declared before
#        locking TO minimize lock time.
#
# Dynamic cursors are now declared FOR SQL statements used in
# the transaction TO make UPDATE as efficent as possible.
# Insert cursors NOT done here as they must be within transaction
###########################################################################
FUNCTION define_cursors(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_temp_text char(400) 

	## orderhead SELECT
	LET l_temp_text = "SELECT * FROM orderhead ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND order_num = ? ", 
	" FOR update" 
	PREPARE s5_ordhead FROM l_temp_text 
	DECLARE c5_ordhead cursor FOR s5_ordhead 
	##
	## orderdetail SELECT
	LET l_temp_text = 
	"SELECT t_inv_detl.offer_code, ", 
	"sum(t_inv_detl.picked_qty*orderdetl.list_price_amt), ", 
	"sum(t_inv_detl.sold_qty*orderdetl.unit_price_amt) ", 
	"FROM t_inv_detl, ", 
	"orderdetl ", 
	"WHERE t_inv_detl.inv_rowid = ? ", 
	"AND t_inv_detl.order_num = ? ", 
	"AND orderdetl.cmpy_code = '",p_cmpy_code, "' ", 
	"AND orderdetl.order_num = ? ", 
	"AND orderdetl.line_num = t_inv_detl.order_line_num ", 
	"group by 1 " 
	PREPARE s3_tinvdetl FROM l_temp_text 
	DECLARE c3_tinvdetl cursor FOR s3_tinvdetl 

	##
	## orderdetail SELECT
	LET l_temp_text = "SELECT * FROM orderdetl ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND order_num = ? ", 
	"AND line_num = ? " 
	PREPARE s11_orderdetl FROM l_temp_text 
	DECLARE c11_orderdetl cursor FOR s11_orderdetl 

	##
	## prodstatus SELECT with locking
	LET l_temp_text = "SELECT * FROM prodstatus ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND part_code = ? ", 
	"AND ware_code = ? ", 
	"FOR UPDATE " 
	PREPARE s1_prodstatus FROM l_temp_text 
	DECLARE c1_prodstatus cursor FOR s1_prodstatus 

	##
	## prodstatus UPDATE
	LET l_temp_text = "UPDATE prodstatus ", 
	"SET onhand_qty = onhand_qty - ?,", 
	"reserved_qty = reserved_qty - ?,", 
	"back_qty = back_qty + ?,", 
	"last_sale_date = ?,", 
	"seq_num = seq_num + 1 ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND part_code = ? ", 
	"AND ware_code = ? " 
	PREPARE s_prodstatus FROM l_temp_text 

	##
	## orderdetl UPDATE
	LET l_temp_text = "UPDATE orderdetl ", 
	"SET inv_qty = inv_qty + ?,", 
	"back_qty = back_qty + ?,", 
	"sched_qty = sched_qty - ?,", 
	"picked_qty = picked_qty - ?,", 
	"conf_qty = conf_qty - ? ", 
	"WHERE cmpy_code= '",p_cmpy_code,"' ", 
	"AND order_num= ? ", 
	"AND line_num = ? " 
	PREPARE c_orderdetl FROM l_temp_text 

	##
	## picking slip SELECT
	LET l_temp_text = "SELECT * FROM pickdetl ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND pick_num = ? ", 
	"AND ware_code = ? ", 
	"AND order_num = ? ", 
	"AND order_line_num = ? " 
	PREPARE s_pickdetl FROM l_temp_text 
	DECLARE c_pickdetl cursor FOR s_pickdetl 

	##
	## despatchdetl SELECT TO UPDATE invoice with connote details
	## AND vice versa
	LET l_temp_text = "SELECT * FROM despatchdetl ", 
	" WHERE cmpy_code = '",p_cmpy_code,"' ", 
	" AND despatch_code = ? ", 
	" AND carrier_code = ? " 
	PREPARE s_despatchdetl FROM l_temp_text 
	DECLARE c_despatchdetl cursor FOR s_despatchdetl 

	##
	## orderdetl SELECT FOR uninvoiced lines
	LET l_temp_text = 
	"SELECT unique 1 FROM orderdetl ", 
	"WHERE cmpy_code = '",p_cmpy_code, "' ", 
	"AND order_num = ? ", 
	"AND order_qty != 0 ", 
	"AND inv_qty != order_qty " 
	PREPARE s1_ordetl FROM l_temp_text 
	DECLARE c1_ordetl cursor FOR s1_ordetl 

	##
	## UPDATE orderhead
	LET l_temp_text = 
	"UPDATE orderhead ", 
	"SET status_ind = ?,", 
	"last_inv_num =?,", 
	"last_inv_date=?,", 
	"first_inv_num=?,", 
	"freight_inv_amt=?,", 
	"hand_inv_amt =? ", 
	"WHERE cmpy_code='",p_cmpy_code,"' ", 
	"AND order_num=?" 
	PREPARE s1_ordhead FROM l_temp_text 
END FUNCTION 
###########################################################################
# END FUNCTION define_cursors(p_cmpy_code)
###########################################################################


###########################################################################
# FUNCTION generate_inv(p_cmpy_code,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind)
#
# This FUNCTION generates an invoice FOR one row in the
# "t_inv_head" table.
# Arguments passed TO this FUNCTION are...
#
# p_rowid      : unique reference TO the proposed_invoice table.
#               : (t_inv_head - SET up in prior FUNCTION)
#
# p_verbose_ind: indicates the destination of MESSAGEs
#                 TRUE  -> MESSAGEs go TO SCREEN
#                 FALSE -> MESSAGEs go TO deliv_msg table
#
###########################################################################
FUNCTION generate_inv(p_cmpy_code,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind) 
	DEFINE l_temp_text char(400) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_rowid INTEGER 
	DEFINE p_verbose_ind char(1) 
--	DEFINE l_order_num LIKE orderhead.order_num 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_2_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_despatchdetl RECORD LIKE despatchdetl.* 
	DEFINE l_rec_orderoffer RECORD LIKE orderoffer.* 
	DEFINE l_rec_pickhead RECORD LIKE pickhead.* 
	DEFINE l_rec_pickdetl RECORD LIKE pickdetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_outstg_freight LIKE orderhead.freight_amt 
	DEFINE l_outstg_hand LIKE orderhead.hand_amt 
	DEFINE l_rec_inv_head RECORD 
		ware_code char(3), 
		pick_num INTEGER, 
		invoice_ind SMALLINT, 
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
		last_inv_num INTEGER, 
		order_date DATE, 
		part_code char(15), 
		picked_qty FLOAT, 
		sold_qty FLOAT, 
		offer_code char(3), 
		reduce_inv_flag char(1) 
	END RECORD
	DEFINE l_freight_onord_amt LIKE orderhead.freight_amt 
	DEFINE l_hand_onord_amt LIKE orderhead.freight_amt 
	DEFINE l_unpicked_qty LIKE invoicedetl.ship_qty ## qty OF short pick 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_offer_disc_per FLOAT 
	DEFINE l_inv_text char(200) 
	DEFINE l_taxable_amt, l_round_err, l_tax_amt, l_tax_amt2 decimal(16,2) 
	DEFINE l_rec_tax2 RECORD LIKE tax.*
	DEFINE l_cnt SMALLINT 
	DEFINE l_errmsg STRING #error message string

	SELECT * INTO l_rec_inv_head.* 
	FROM t_inv_head 
	WHERE rowid = p_rowid 
	IF sqlca.sqlcode = NOTFOUND THEN 
		RETURN 0 
	END IF 
	CALL calc_chrgqty(p_cmpy_code,p_rowid) 

	IF NOT valid_period2(p_cmpy_code,l_rec_inv_head.year_num,	l_rec_inv_head.period_num,"OE") THEN 
		CALL get_fiscal_year_period_for_date(p_cmpy_code,l_rec_inv_head.inv_date) 
			RETURNING l_rec_inv_head.year_num, l_rec_inv_head.period_num 

		IF NOT valid_period2(p_cmpy_code,l_rec_inv_head.year_num,	l_rec_inv_head.period_num,"OE") THEN 
			LET modu_err_message = ": ",l_rec_inv_head.year_num,	"/",l_rec_inv_head.period_num 
			CALL error_msg(p_cmpy_code,7051,modu_err_message,p_verbose_ind) #7051 Year & Perod NOT SET up 
			RETURN FALSE 
		END IF 
	END IF 

	CALL define_cursors(p_cmpy_code) 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 
		LET modu_err_message = "setting up INSERT buffers" 

		## invoice line INSERT
		DECLARE s3_invoicedetl cursor FOR INSERT INTO invoicedetl 
		VALUES (l_rec_invoicedetl.*) 
		OPEN s3_invoicedetl 

		## product ledger INSERT
		DECLARE s1_prodledg cursor FOR INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
		OPEN s1_prodledg 

		## invoice header INSERT
		DECLARE s2_invhead cursor FOR INSERT INTO invoicehead 
		VALUES (l_rec_invoicehead.*) 
		OPEN s2_invhead 

		## istatistics trigger INSERT
		DECLARE s1_stattrig cursor FOR INSERT INTO stattrig 
		VALUES (p_cmpy_code,TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.inv_num, 
		l_rec_invoicehead.inv_date) 
		OPEN s1_stattrig 

		## AR audit entry INSERT
		DECLARE s1_araudit cursor FOR INSERT INTO araudit VALUES (l_rec_araudit.*) 
		OPEN s1_araudit 
		######### END of Insert Cursor Declaration

		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_inv_head.cust_code 
		AND delete_flag = "N" 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ROLLBACK WORK 
			CALL error_msg("E",7052,l_rec_inv_head.cust_code,p_verbose_ind) #7052 sales ORDER customer IS invalid
			RETURN 0 
		END IF 

		IF l_rec_customer.corp_cust_code IS NOT NULL AND l_rec_customer.corp_cust_ind = "1" THEN 
			LET l_rec_invoicehead.cust_code = l_rec_customer.corp_cust_code 
			LET l_rec_invoicehead.org_cust_code = l_rec_customer.cust_code 
		ELSE 
			LET l_rec_invoicehead.cust_code = l_rec_customer.cust_code 
			LET l_rec_invoicehead.org_cust_code = "" 
		END IF 

		DECLARE c_customer cursor FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_invoicehead.cust_code 
		AND delete_flag = "N" 
		FOR UPDATE 
		OPEN c_customer 
		FETCH c_customer INTO l_rec_customer.* 
		IF sqlca.sqlcode = NOTFOUND THEN 
			ROLLBACK WORK 			
			CALL error_msg("E",7052,l_rec_invoicehead.cust_code,p_verbose_ind) #7052 customer does NOT exists
			RETURN FALSE 
		END IF 

		## cred limit check does NOT apply TO pre-delivered orders
		IF NOT valid_cust(
			p_cmpy_code,
			p_rowid,
			p_verbose_ind, 
			l_rec_inv_head.invoice_ind, 
			l_rec_invoicehead.cust_code, 
			l_rec_invoicehead.org_cust_code) THEN 
			ROLLBACK WORK 
			RETURN FALSE 
		END IF 

		SELECT * INTO l_rec_orderhead.* 
		FROM orderhead 
		WHERE cmpy_code = p_cmpy_code 
		AND order_num = l_rec_inv_head.order_num 

		IF l_rec_inv_head.invoice_ind = 1 THEN 
			## obtain group VALUES FROM picking slip
			LET modu_err_message = "retreiving picking slip details FROM database" 
			DECLARE c_pickhead cursor FOR 
			SELECT * FROM pickhead 
			WHERE cmpy_code = p_cmpy_code 
			AND ware_code = l_rec_inv_head.ware_code 
			AND pick_num = l_rec_inv_head.pick_num 
			AND status_ind = "0" 
			FOR UPDATE 
			OPEN c_pickhead 
			FETCH c_pickhead INTO l_rec_pickhead.* 

			IF sqlca.sqlcode = NOTFOUND THEN 
				ROLLBACK WORK 
				#7053 picking slip no longer current
				CALL error_msg(p_cmpy_code,7053,l_rec_inv_head.pick_num,p_verbose_ind) 
				RETURN 0 
			END IF 
		END IF 

		####
		##   other invoice header fields
		LET modu_err_message = "setting up invoice information" 
		LET l_rec_invoicehead.cmpy_code = p_cmpy_code 
		LET l_rec_invoicehead.ord_num = l_rec_inv_head.order_num 
		LET l_rec_invoicehead.purchase_code = l_rec_orderhead.ord_text 
		LET l_rec_invoicehead.inv_date = l_rec_inv_head.inv_date 
		LET l_rec_invoicehead.entry_code= l_rec_orderhead.entry_code 
		LET l_rec_invoicehead.entry_date= l_rec_orderhead.entry_date 
		LET l_rec_invoicehead.sale_code = l_rec_orderhead.sales_code 
		LET l_rec_invoicehead.ref_num = l_rec_pickhead.pick_num 


		#get sales person record	 
		CALL db_salesperson_get_rec(UI_OFF,l_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.*
		
		#-----------------------------------------
		# payment terms & settlement discount date
		LET modu_err_message = "retreiving payment term information" 
		LET l_rec_invoicehead.term_code = l_rec_orderhead.term_code
		 
		SELECT * INTO l_rec_term.* 
		FROM term 
		WHERE cmpy_code = l_rec_invoicehead.cmpy_code 
		AND term_code = l_rec_invoicehead.term_code 
		IF sqlca.sqlcode = 0 THEN 
			CALL get_due_and_discount_date(l_rec_term.*,l_rec_invoicehead.inv_date) 
			RETURNING l_rec_invoicehead.due_date, 
			l_rec_invoicehead.disc_date 
			LET l_rec_invoicehead.disc_per = l_rec_term.disc_per 
		ELSE 
			LET l_rec_invoicehead.disc_per = 0 
			LET l_rec_invoicehead.due_date = l_rec_orderhead.order_date 
			LET l_rec_invoicehead.disc_date = l_rec_orderhead.order_date 
		END IF
		 
		##   tax codes & amounts (incl. freight & handling)
		LET modu_err_message = "calculating freight & handling" 
		LET l_rec_invoicehead.tax_amt = 0 
		LET l_rec_invoicehead.hand_amt = l_rec_inv_head.hand_amt 
		LET l_rec_invoicehead.freight_amt = l_rec_inv_head.freight_amt 
		LET l_rec_invoicehead.tax_code = l_rec_orderhead.tax_code 
		LET l_rec_invoicehead.hand_tax_code = l_rec_orderhead.hand_tax_code 
		LET l_rec_invoicehead.freight_tax_code=l_rec_orderhead.freight_tax_code
		 
		SELECT * INTO l_rec_tax.* 
		FROM tax 
		WHERE cmpy_code = p_cmpy_code 
		AND tax_code = l_rec_invoicehead.tax_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_tax.tax_per = 0 
			LET l_rec_tax.hand_per = 0 
			LET l_rec_tax.freight_per = 0 
		END IF 
		LET l_rec_invoicehead.tax_per = l_rec_tax.tax_per 
		LET l_rec_invoicehead.tax_amt = 0 
		LET l_rec_invoicehead.hand_tax_amt = l_rec_tax.hand_per	* l_rec_inv_head.hand_amt/100 
		LET l_rec_invoicehead.freight_tax_amt = l_rec_tax.freight_per	* l_rec_inv_head.freight_amt/100 
		LET l_rec_invoicehead.goods_amt = 0 
		LET l_rec_invoicehead.total_amt = 0 
		LET l_rec_invoicehead.cost_amt = 0 
		LET l_rec_invoicehead.paid_amt = 0 
		LET l_rec_invoicehead.paid_date = NULL 
		LET l_rec_invoicehead.disc_taken_amt = 0 
		LET l_rec_invoicehead.expected_date = l_rec_invoicehead.due_date 
		LET l_rec_invoicehead.year_num = l_rec_inv_head.year_num 
		LET l_rec_invoicehead.period_num = l_rec_inv_head.period_num 
		LET l_rec_invoicehead.on_state_flag = "N" 
		LET l_rec_invoicehead.posted_flag = "N" 
		LET l_rec_invoicehead.seq_num = 0 
		LET l_rec_invoicehead.line_num = 0 
		LET l_rec_invoicehead.printed_num = 0 
		LET l_rec_invoicehead.story_flag = "N" 
		LET l_rec_invoicehead.rev_date = l_rec_orderhead.rev_date 
		LET l_rec_invoicehead.rev_num = l_rec_orderhead.rev_num 
		LET l_rec_invoicehead.ship_code = l_rec_orderhead.ship_code 
		LET l_rec_invoicehead.name_text = l_rec_orderhead.ship_name_text 
		LET l_rec_invoicehead.addr1_text = l_rec_orderhead.ship_addr1_text 
		LET l_rec_invoicehead.addr2_text = l_rec_orderhead.ship_addr2_text 
		LET l_rec_invoicehead.city_text = l_rec_orderhead.ship_city_text 
		LET l_rec_invoicehead.state_code = l_rec_orderhead.state_code 
		LET l_rec_invoicehead.post_code = l_rec_orderhead.post_code 
		LET l_rec_invoicehead.country_code = l_rec_orderhead.country_code --@db-patch_2020_10_04--
		LET l_rec_invoicehead.ship1_text = l_rec_orderhead.ship1_text 
		LET l_rec_invoicehead.ship2_text = l_rec_orderhead.ship2_text 
		LET l_rec_invoicehead.ship_date = l_rec_inv_head.ship_date 
		LET l_rec_invoicehead.fob_text = l_rec_orderhead.fob_text 
		LET l_rec_invoicehead.prepaid_flag = l_rec_orderhead.prepaid_flag 
		LET l_rec_invoicehead.com1_text = l_rec_inv_head.com1_text 
		LET l_rec_invoicehead.com2_text = l_rec_inv_head.com2_text 
		LET l_rec_invoicehead.cost_ind = l_rec_orderhead.cost_ind 
		LET l_rec_invoicehead.currency_code = l_rec_orderhead.currency_code 
		LET l_rec_invoicehead.conv_qty = l_rec_orderhead.conv_qty 

		IF l_rec_inv_head.invoice_ind = "3" THEN 
			LET l_rec_invoicehead.inv_ind = "5" ## pre-delivered 
		ELSE 
			LET l_rec_invoicehead.inv_ind = "6" ## TO be delivered 
		END IF 

		LET l_rec_invoicehead.prev_paid_amt = 0 
		LET l_rec_invoicehead.acct_override_code=l_rec_orderhead.acct_override_code 
		LET l_rec_invoicehead.price_tax_flag = l_rec_orderhead.price_tax_flag 
		LET l_rec_invoicehead.contact_text = l_rec_orderhead.contact_text 
		LET l_rec_invoicehead.tele_text = l_rec_orderhead.tele_text 
		LET l_rec_invoicehead.mobile_phone = l_rec_orderhead.mobile_phone		
		LET l_rec_invoicehead.email = l_rec_orderhead.email		
		LET l_rec_invoicehead.invoice_to_ind = l_rec_orderhead.invoice_to_ind 
		LET l_rec_invoicehead.territory_code = l_rec_orderhead.territory_code 
		LET l_rec_invoicehead.mgr_code = l_rec_orderhead.mgr_code 
		LET l_rec_invoicehead.area_code = l_rec_orderhead.area_code 
		LET l_rec_invoicehead.cond_code = l_rec_orderhead.cond_code 
		LET l_rec_invoicehead.scheme_amt = l_rec_orderhead.scheme_amt 
		LET l_rec_invoicehead.carrier_code = l_rec_orderhead.carrier_code 
		LET l_rec_invoicehead.stat_date = NULL 
		LET l_rec_invoicehead.post_date = NULL 
		LET l_rec_invoicehead.manifest_num = NULL 
		LET modu_err_message = "retreiving line item information" 
		LET l_freight_onord_amt = 0 
		LET l_hand_onord_amt = 0 

		############################
		## New Invoice Number
		## allocated AT last possible moment TO minimize nextnumber locking
		LET l_rec_invoicehead.inv_num = next_trans_num(p_cmpy_code,TRAN_TYPE_INVOICE_IN,l_rec_orderhead.acct_override_code)
			IF l_rec_invoicehead.inv_num < 0 THEN 
			LET modu_err_message = "error occurred generating next invoice number" 
			LET status = l_rec_invoicehead.inv_num 
			GOTO recovery 
		END IF
		 
		#############################
		DECLARE c_orderhead cursor FOR 
		SELECT unique order_num FROM t_inv_detl 
		WHERE inv_rowid = p_rowid
		 
		FOREACH c_orderhead INTO l_rec_orderhead.order_num 
			LET modu_err_message = "Locking Order record" 
			OPEN c5_ordhead USING l_rec_orderhead.order_num 
			FETCH c5_ordhead INTO l_rec_orderhead.*
			 
			IF l_rec_orderhead.status_ind = "X" THEN 
				LET modu_err_message = "Order Locked by another process" 
				GOTO recovery 
			END IF
			 
			CALL serial_init(p_cmpy_code,'1','1',l_rec_orderhead.order_num) 
			LET modu_err_message = "Locking Order record-2"
			 
			OPEN c3_tinvdetl USING p_rowid, 
			l_rec_orderhead.order_num, 
			l_rec_orderhead.order_num 
			
			FOREACH c3_tinvdetl INTO l_rec_orderoffer.offer_code, 
				l_rec_orderoffer.gross_amt, 
				l_rec_orderoffer.net_amt 
				IF l_rec_orderoffer.offer_code IS NULL THEN 
					LET l_temp_text = "offer_code IS null" 
					LET l_offer_disc_per = 0 
				ELSE 
					IF l_rec_orderoffer.gross_amt != 0 THEN 
						LET l_offer_disc_per = l_rec_orderoffer.net_amt	/ l_rec_orderoffer.gross_amt 
					ELSE 
						LET l_offer_disc_per = 0 
					END IF 
					LET l_temp_text = "offer_code='",l_rec_orderoffer.offer_code,"'" 
				END IF
				 
				LET l_temp_text = 
					"SELECT * FROM t_inv_detl ", 
					"WHERE inv_rowid='",p_rowid,"' ", 
					"AND order_num='",l_rec_orderhead.order_num,"' ", 
					"AND ",l_temp_text clipped," ", 
					"ORDER BY order_line_num" 

				PREPARE s_inv_detl FROM l_temp_text 
				DECLARE c_inv_detl cursor FOR s_inv_detl
				 
				LET l_taxable_amt = 0 
				LET l_tax_amt2 = 0 
				
				FOREACH c_inv_detl INTO p_rowid,	l_rec_inv_detl.* 

					OPEN c11_orderdetl USING l_rec_inv_detl.order_num, l_rec_inv_detl.order_line_num 
					FETCH c11_orderdetl INTO l_rec_orderdetl.* 

					LET l_rec_invoicehead.line_num = l_rec_invoicehead.line_num + 1 
					LET l_rec_invoicedetl.cmpy_code = p_cmpy_code 
					LET l_rec_invoicedetl.cust_code = l_rec_invoicehead.cust_code 
					LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
					LET l_rec_invoicedetl.line_num = l_rec_invoicehead.line_num 
					LET l_rec_invoicedetl.part_code = l_rec_orderdetl.part_code 
					LET l_rec_invoicedetl.ware_code = l_rec_inv_detl.ware_code 
					LET l_rec_invoicedetl.cat_code = l_rec_orderdetl.cat_code 
					LET l_rec_invoicedetl.ord_qty = l_rec_orderdetl.order_qty 
					LET l_rec_invoicedetl.ship_qty = l_rec_inv_detl.picked_qty 
					LET l_rec_invoicedetl.sold_qty = l_rec_inv_detl.sold_qty 
					LET l_rec_invoicedetl.bonus_qty = l_rec_inv_detl.picked_qty	- l_rec_inv_detl.sold_qty 
					LET l_rec_invoicedetl.prev_qty = l_rec_orderdetl.inv_qty 
					LET l_rec_invoicedetl.back_qty = l_rec_orderdetl.order_qty - l_rec_orderdetl.inv_qty	- l_rec_invoicedetl.ship_qty 
					LET l_rec_invoicedetl.ser_flag = l_rec_orderdetl.serial_flag 
					LET l_rec_invoicedetl.line_text = l_rec_orderdetl.desc_text 
					LET l_rec_invoicedetl.uom_code = l_rec_orderdetl.uom_code 
					LET l_rec_invoicedetl.unit_cost_amt = l_rec_orderdetl.unit_cost_amt 
					LET l_rec_invoicedetl.ext_cost_amt = l_rec_invoicedetl.ship_qty * l_rec_invoicedetl.unit_cost_amt 
					LET l_rec_invoicedetl.unit_sale_amt = l_rec_orderdetl.unit_price_amt 
					LET l_rec_invoicedetl.ext_sale_amt = l_rec_invoicedetl.sold_qty * l_rec_invoicedetl.unit_sale_amt 
					LET l_rec_invoicedetl.unit_tax_amt = l_rec_orderdetl.unit_tax_amt 
					LET l_rec_invoicedetl.ext_tax_amt = l_rec_invoicedetl.sold_qty * l_rec_orderdetl.unit_tax_amt 
					LET l_rec_invoicedetl.line_total_amt = l_rec_invoicedetl.ext_sale_amt	+ l_rec_invoicedetl.ext_tax_amt 
					LET l_rec_invoicedetl.seq_num = 0 
					LET l_rec_invoicedetl.line_acct_code = l_rec_orderdetl.acct_code 
					LET l_rec_invoicedetl.level_code = l_rec_orderdetl.level_ind 
					LET l_rec_invoicedetl.comp_per = 0 
					LET l_rec_invoicedetl.tax_code = l_rec_orderdetl.tax_code 
					LET l_rec_invoicedetl.order_num = l_rec_orderdetl.order_num 
					LET l_rec_invoicedetl.order_line_num = l_rec_orderdetl.line_num 
					LET l_rec_invoicedetl.disc_amt = l_rec_orderdetl.disc_per 
					LET l_rec_invoicedetl.disc_per = l_rec_orderdetl.disc_per 
					LET l_rec_invoicedetl.offer_code = l_rec_orderdetl.offer_code 
					LET l_rec_invoicedetl.list_price_amt = l_rec_orderdetl.list_price_amt 
					LET l_rec_invoicedetl.ext_bonus_amt = l_rec_invoicedetl.bonus_qty * l_rec_invoicedetl.list_price_amt 
					LET l_rec_invoicedetl.ext_stats_amt = l_offer_disc_per 	* l_rec_invoicedetl.ship_qty	* l_rec_invoicedetl.list_price_amt 

					IF l_rec_invoicedetl.ext_stats_amt IS NULL	OR l_rec_invoicedetl.ext_stats_amt = 0 THEN 
						LET l_rec_invoicedetl.ext_stats_amt = l_rec_invoicedetl.ext_sale_amt 
					END IF
					 
					LET l_rec_invoicedetl.comm_amt = 
					calc_comm(p_cmpy_code,l_rec_invoicehead.sale_code, 
					l_rec_salesperson.comm_per, 
					l_rec_salesperson.comm_ind, 
					l_rec_invoicehead.cond_code, 
					l_rec_invoicedetl.*)
					 
					LET l_rec_invoicedetl.prodgrp_code = l_rec_orderdetl.prodgrp_code 
					LET l_rec_invoicedetl.maingrp_code = l_rec_orderdetl.maingrp_code 
					LET modu_err_message = "updating ORDER detail line items" 
					LET l_unpicked_qty = 0 
					LET l_rec_pickdetl.picked_qty = 0
					 
					CASE 
						WHEN l_rec_orderdetl.status_ind = "1" 
							## Pre-delivered
							EXECUTE c_orderdetl USING 
								l_rec_invoicedetl.ship_qty, 
								"0", ## back_qty 
								"0", ## sched_qty 
								"0", ## picked_qty 
								l_rec_invoicedetl.ship_qty , 
								l_rec_orderdetl.order_num , 
								l_rec_orderdetl.line_num 
							
						WHEN l_rec_orderdetl.pick_flag = "Y" 
							## Picked Line
							OPEN c_pickdetl USING l_rec_pickhead.pick_num, 
							l_rec_pickhead.ware_code, 
							l_rec_inv_detl.order_num, 
							l_rec_inv_detl.order_line_num 
							FETCH c_pickdetl INTO l_rec_pickdetl.* 
							IF status = 0 THEN 
								IF l_rec_pickdetl.picked_qty != l_rec_invoicedetl.ship_qty THEN 
									LET l_unpicked_qty = l_rec_pickdetl.picked_qty - l_rec_invoicedetl.ship_qty 
								END IF 
								
								IF l_rec_inv_detl.reduce_inv_flag IS NOT NULL 
								AND l_rec_inv_detl.reduce_inv_flag != 'Y' THEN 
									EXECUTE c_orderdetl USING 
										l_rec_invoicedetl.ship_qty, 
										l_unpicked_qty, 
										"0", ## sched_qty 
										l_rec_pickdetl.picked_qty, 
										"0", ## conf_qty 
										l_rec_orderdetl.order_num, 
										l_rec_orderdetl.line_num 
								ELSE 
									EXECUTE c_orderdetl USING 
										l_rec_invoicedetl.ship_qty, 
										"0", 
										"0", ## sched_qty 
										l_rec_pickdetl.picked_qty, 
										"0", ## conf_qty 
										l_rec_orderdetl.order_num, 
										l_rec_orderdetl.line_num 
									
									UPDATE orderdetl 
									SET order_qty = order_qty - l_unpicked_qty 
									WHERE cmpy_code = p_cmpy_code 
									AND order_num = l_rec_orderdetl.order_num 
									AND line_num = l_rec_orderdetl.line_num 
									
									SELECT * INTO l_rec_2_orderdetl.* FROM orderdetl 
									WHERE order_num = l_rec_orderdetl.order_num 
									AND line_num = l_rec_orderdetl.line_num 
									AND cmpy_code = p_cmpy_code 
									
									IF l_unpicked_qty != 0 THEN 
										IF NOT insert_line_log(p_cmpy_code,p_kandoouser_sign_on_code, 
										l_rec_orderdetl.order_num, 
										l_rec_orderdetl.part_code, 
										l_rec_orderdetl.line_num, 
										l_rec_orderdetl.*, 
										l_rec_2_orderdetl.*) THEN 
											LET modu_err_message = "Line log failed" 
											GOTO recovery 
										END IF 
									END IF 

									LET l_rec_invoicedetl.ord_qty = l_rec_2_orderdetl.order_qty 
									LET l_rec_invoicedetl.back_qty = l_rec_2_orderdetl.order_qty - l_rec_2_orderdetl.inv_qty 
								END IF 

								IF l_rec_pickhead.con_status_ind = "1" THEN 
									OPEN c_despatchdetl USING l_rec_pickdetl.despatch_code, 	l_rec_pickhead.carrier_code 
									FETCH c_despatchdetl INTO l_rec_despatchdetl.* 
									IF status = 0 THEN 
										LET modu_err_message = " E53b - Updating despatchdetl" 
										LET l_rec_invoicehead.manifest_num = l_rec_despatchdetl.manifest_num 
										UPDATE despatchdetl 
										SET invoice_num = l_rec_invoicehead.inv_num 
										WHERE cmpy_code = p_cmpy_code 
										AND despatch_code=l_rec_despatchdetl.despatch_code 
										AND carrier_code = l_rec_despatchdetl.carrier_code 
									END IF 
									CLOSE c_despatchdetl 
								END IF 
							END IF 
							
						OTHERWISE 
							## Non-picked OR Non_inventory line
							EXECUTE c_orderdetl USING 
								l_rec_invoicedetl.ship_qty, 
								"0", ## back_qty 
								l_rec_invoicedetl.ship_qty, 
								"0",## picked_qty 
								"0",## conf_qty 
								l_rec_orderdetl.order_num, 
								l_rec_orderdetl.line_num 
					END CASE
					 
					####
					## UPDATE product STATUS
					IF l_rec_invoicedetl.part_code IS NOT NULL THEN 
						LET modu_err_message = " E56 - Locking & Updating prodstatus" 
						OPEN c1_prodstatus USING l_rec_invoicedetl.part_code, l_rec_invoicedetl.ware_code 
						FETCH c1_prodstatus INTO l_rec_prodstatus.* 
						IF sqlca.sqlcode = 0 THEN 
							IF l_rec_prodstatus.stocked_flag = "Y" THEN 
								IF l_rec_invoicedetl.ship_qty != 0 THEN # adjust stock 
									LET l_rec_pickdetl.picked_qty = l_rec_invoicedetl.ship_qty + l_unpicked_qty 
									IF l_rec_inv_detl.reduce_inv_flag IS NOT NULL AND l_rec_inv_detl.reduce_inv_flag != 'Y' THEN 
										EXECUTE s_prodstatus USING 
											l_rec_invoicedetl.ship_qty, 
											l_rec_pickdetl.picked_qty, 
											l_unpicked_qty, 
											l_rec_invoicehead.inv_date, 
											l_rec_invoicedetl.part_code, 
											l_rec_invoicedetl.ware_code 
									ELSE 
										EXECUTE s_prodstatus USING 
											l_rec_invoicedetl.ship_qty, 
											l_rec_pickdetl.picked_qty, 
											"0", 
											l_rec_invoicehead.inv_date, 
											l_rec_invoicedetl.part_code, 
											l_rec_invoicedetl.ware_code 
									END IF 
								ELSE 

									EXECUTE s_prodstatus USING 
										"0", 
										l_rec_pickdetl.picked_qty, 
										l_unpicked_qty, 
										l_rec_prodstatus.last_sale_date, 
										l_rec_invoicedetl.part_code, 
										l_rec_invoicedetl.ware_code 
								END IF 
							ELSE 
								EXECUTE s_prodstatus USING 
									"0",
									"0",
									"0", 
									l_rec_invoicehead.inv_date, 
									l_rec_invoicedetl.part_code, 
									l_rec_invoicedetl.ware_code 
							END IF
							 
							IF l_rec_invoicedetl.ship_qty != 0 THEN # adjust stock &generate prodledg 
								LET modu_err_message = "Calculating product ledger entry" 
								
								INITIALIZE l_rec_prodledg.* TO NULL 
								
								LET l_rec_prodledg.cmpy_code = p_cmpy_code 
								LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
								LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
								LET l_rec_prodledg.tran_date = l_rec_invoicehead.inv_date 
								LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num + 1 
								LET l_rec_prodledg.trantype_ind = "S" 
								LET l_rec_prodledg.year_num = l_rec_invoicehead.year_num 
								LET l_rec_prodledg.period_num = l_rec_invoicehead.period_num 
								LET l_rec_prodledg.source_text = l_rec_invoicehead.cust_code 
								LET l_rec_prodledg.source_num = l_rec_invoicehead.inv_num 
								LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty + 0 
								LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt / l_rec_invoicehead.conv_qty 
								LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt / l_rec_invoicehead.conv_qty 
								LET l_rec_prodledg.hist_flag = "N" 
								LET l_rec_prodledg.post_flag = "N" 
								LET l_rec_prodledg.acct_code = NULL 
								LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty - l_rec_invoicedetl.ship_qty 
								LET l_rec_prodledg.entry_code = p_kandoouser_sign_on_code 
								LET l_rec_prodledg.entry_date = today 
								
								LET modu_err_message = "Storing product ledger entry" 
								
								PUT s1_prodledg 

							END IF 
						END IF 

						SELECT unique 1 FROM product 
						WHERE part_code = l_rec_orderdetl.part_code 
						AND cmpy_code = p_cmpy_code 
						AND serial_flag = 'Y' 
						IF status <> NOTFOUND THEN 
							LET l_cnt = serial_count(l_rec_inv_detl.part_code, 
							l_rec_inv_detl.ware_code) 
							IF l_cnt <> l_rec_inv_detl.picked_qty THEN 
								LET modu_err_message = "E53b Serial Details changed",		" - Transaction Aborted " 
								GOTO recovery 
								ROLLBACK WORK 
							END IF 

							LET modu_err_message = "E53b - serial_update " 
							LET l_rec_serialinfo.cmpy_code = p_cmpy_code 
							LET l_rec_serialinfo.part_code = l_rec_orderdetl.part_code 
							LET l_rec_serialinfo.ware_code = l_rec_orderhead.ware_code 
							LET l_rec_serialinfo.trans_num = l_rec_invoicehead.inv_num 
							LET l_rec_serialinfo.ship_date = l_rec_invoicehead.inv_date 
							LET l_rec_serialinfo.trantype_ind = "S" 

							LET status = serial_update(l_rec_serialinfo.*,1, "") 

							IF status <> 0 THEN 
								GOTO recovery
								LET l_errmsg = "Serial Update status = ", trim(status)
								CALL fgl_winmessage("ERROR",l_errmsg,"ERROR") 								 
								EXIT PROGRAM 
							END IF 
						END IF 

					END IF 
					LET l_rec_invoicehead.cost_amt = l_rec_invoicehead.cost_amt + l_rec_invoicedetl.ext_cost_amt 
					LET l_rec_invoicehead.goods_amt = l_rec_invoicehead.goods_amt + l_rec_invoicedetl.ext_sale_amt 
					LET l_round_err = 0 
					
					INITIALIZE l_rec_tax.* TO NULL 
					LET l_tax_amt = 0 
					SELECT * INTO l_rec_tax.* FROM tax 
					WHERE cmpy_code = p_cmpy_code 
					AND tax_code = l_rec_invoicehead.tax_code
					 
					IF l_rec_tax.calc_method_flag = "T" THEN 
						INITIALIZE l_rec_tax2.* TO NULL 
						SELECT * INTO l_rec_tax2.* FROM tax 
						WHERE cmpy_code = p_cmpy_code 
						AND tax_code = l_rec_invoicedetl.tax_code 
						IF l_rec_tax2.calc_method_flag != "X" THEN 
							LET l_taxable_amt = l_taxable_amt	+ l_rec_invoicedetl.ext_sale_amt 
							CALL calc_total_tax(p_cmpy_code, "T", 
							l_taxable_amt, 
							l_rec_tax.tax_code) 
							RETURNING l_tax_amt 
							LET l_tax_amt2 = l_tax_amt2 + l_rec_invoicedetl.ext_tax_amt 
							IF l_tax_amt != l_tax_amt2 THEN 
								LET l_round_err = l_tax_amt2 - l_tax_amt 
							END IF 
							IF l_round_err != 0 THEN 
								LET l_tax_amt2 = l_tax_amt2 - l_rec_invoicedetl.ext_tax_amt 
								LET l_rec_invoicedetl.ext_tax_amt =	l_rec_invoicedetl.ext_tax_amt -	l_round_err 
								LET l_tax_amt2 = l_tax_amt2 + l_rec_invoicedetl.ext_tax_amt 
							END IF 
						END IF 
					END IF
					 
					LET l_rec_invoicehead.tax_amt = l_rec_invoicehead.tax_amt		+ l_rec_invoicedetl.ext_tax_amt 
					LET modu_err_message = "Storing invoice line items TO the database" 
					PUT s3_invoicedetl 
				END FOREACH 
			END FOREACH
			 
			LET modu_err_message = "E53b - serial return" 
			LET status = serial_return("","0") 
			LET modu_err_message = "updating the sales ORDER information"
			 
			IF l_rec_orderhead.status_ind = "U" THEN 
				LET l_rec_orderhead.status_ind = "P" 
				LET l_rec_orderhead.first_inv_num = l_rec_invoicehead.inv_num 
			END IF
			 
			OPEN c1_ordetl USING l_rec_orderhead.order_num 
			FETCH c1_ordetl 
			IF sqlca.sqlcode = NOTFOUND THEN 
				## IF there IS no partial delivered THEN ORDER IS fully delivered
				LET l_rec_orderhead.status_ind = "C" 
			END IF
			 
			IF l_rec_orderhead.order_num = l_rec_invoicehead.ord_num THEN 
				LET l_outstg_freight = l_rec_orderhead.freight_amt 
				- l_rec_orderhead.freight_inv_amt 
				LET l_outstg_hand = l_rec_orderhead.hand_amt 
				- l_rec_orderhead.hand_inv_amt 
				IF l_outstg_freight IS NULL 
				OR l_outstg_freight < 0 THEN 
					LET l_outstg_freight = 0 
				END IF 
				IF l_outstg_hand IS NULL 
				OR l_outstg_hand < 0 THEN 
					LET l_outstg_hand = 0 
				END IF
				 
				IF l_rec_orderhead.status_ind = "C" THEN 
					LET l_freight_onord_amt = l_outstg_freight 
					LET l_hand_onord_amt = l_outstg_hand 
				ELSE 
					IF l_rec_invoicehead.freight_amt > 0 THEN 
						IF l_rec_invoicehead.freight_amt <= l_outstg_freight THEN 
							LET l_freight_onord_amt = l_rec_invoicehead.freight_amt 
						ELSE 
							LET l_freight_onord_amt = l_outstg_freight 
						END IF 
					END IF 
					IF l_rec_invoicehead.hand_amt > 0 THEN 
						IF l_rec_invoicehead.hand_amt <= l_outstg_hand THEN 
							LET l_hand_onord_amt = l_rec_invoicehead.hand_amt 
						ELSE 
							LET l_hand_onord_amt = l_outstg_hand 
						END IF 
					END IF 
				END IF 
				LET l_rec_orderhead.hand_inv_amt = l_rec_orderhead.hand_inv_amt	+ l_rec_invoicehead.hand_amt 
				LET l_rec_orderhead.freight_inv_amt = l_rec_orderhead.freight_inv_amt	+ l_rec_invoicehead.freight_amt 
			END IF 
			
			EXECUTE s1_ordhead USING l_rec_orderhead.status_ind, 
			l_rec_invoicehead.inv_num, 
			l_rec_invoicehead.inv_date, 
			l_rec_orderhead.first_inv_num, 
			l_rec_orderhead.freight_inv_amt, 
			l_rec_orderhead.hand_inv_amt, 
			l_rec_orderhead.order_num 
			IF l_rec_customer.pay_ind = "5" THEN 
				INSERT INTO t_cashreceipt 
				SELECT * FROM cashreceipt 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = l_rec_invoicehead.cust_code 
				AND order_num = l_rec_orderhead.order_num 
				AND applied_amt < cash_amt 
				AND cash_amt > 0 
			END IF 
		END FOREACH
		 
		IF l_rec_inv_head.pick_num IS NOT NULL THEN 
			LET modu_err_message = "UPDATE picking slip details" 
			UPDATE pickhead SET status_ind = "1", 
			inv_num = l_rec_invoicehead.inv_num 
			WHERE cmpy_code = p_cmpy_code 
			AND ware_code = l_rec_inv_head.ware_code 
			AND pick_num = l_rec_inv_head.pick_num 
		END IF
		 
		LET modu_err_message = "calculating the total amounts of the invoice" 
		LET l_rec_invoicehead.total_amt = l_rec_invoicehead.goods_amt 
		+ l_rec_invoicehead.tax_amt 
		+ l_rec_invoicehead.hand_amt 
		+ l_rec_invoicehead.hand_tax_amt 
		+ l_rec_invoicehead.freight_amt 
		+ l_rec_invoicehead.freight_tax_amt 
		LET modu_err_message = "calculating settlement discount of the invoice" 
		LET l_rec_invoicehead.disc_amt = ( l_rec_invoicehead.disc_per/100) 	* l_rec_invoicehead.total_amt 
		LET modu_err_message = "Storing invoice information TO the database" 
		PUT s2_invhead 
		LET modu_err_message = "Storing statistics information TO the database" 
		PUT s1_stattrig 
		LET modu_err_message = "Storing customer AR audit entry TO the database" 
		INITIALIZE l_rec_araudit.* TO NULL 
		
		LET l_rec_araudit.cmpy_code = p_cmpy_code 
		LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = l_rec_customer.next_seq_num + 1 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Invoice (order)" 
		LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = l_rec_invoicehead.entry_code 
		LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
		LET l_rec_araudit.bal_amt = l_rec_customer.bal_amt + l_rec_invoicehead.total_amt 
		LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
		LET l_rec_araudit.currency_code = l_rec_invoicehead.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today
		 
		PUT s1_araudit 
		#####
		## Update customer(s)
		LET modu_err_message = "Updating the customer master file" 
		IF l_rec_invoicehead.due_date > l_rec_invoicehead.inv_date THEN 
			LET l_rec_customer.curr_amt = l_rec_customer.curr_amt 
			+ l_rec_invoicehead.total_amt 
		END IF 
		LET l_rec_customer.bal_amt = l_rec_customer.bal_amt + l_rec_invoicehead.total_amt 
		IF l_rec_customer.bal_amt > l_rec_customer.highest_bal_amt THEN 
			LET l_rec_customer.highest_bal_amt = l_rec_customer.bal_amt 
		END IF 
		IF year(l_rec_invoicehead.inv_date) > year(l_rec_customer.last_inv_date) THEN 
			LET l_rec_customer.ytds_amt = 0 
			LET l_rec_customer.mtds_amt = 0 
		END IF 
		LET l_rec_customer.ytds_amt = l_rec_customer.ytds_amt 
		+ l_rec_invoicehead.total_amt 
		IF month(l_rec_invoicehead.inv_date) > month(l_rec_customer.last_inv_date) THEN 
			LET l_rec_customer.mtds_amt = 0 
		END IF 
		LET l_rec_customer.mtds_amt = l_rec_customer.mtds_amt 
		+ l_rec_invoicehead.total_amt 
		IF l_rec_invoicehead.org_cust_code IS NULL THEN 
			LET l_rec_customer.onorder_amt = l_rec_customer.onorder_amt 
			- l_rec_invoicehead.goods_amt 
			- l_rec_invoicehead.tax_amt 
			- l_freight_onord_amt 
			- l_hand_onord_amt 
		ELSE 
			UPDATE customer 
			SET onorder_amt = onorder_amt - l_rec_invoicehead.goods_amt 
			- l_rec_invoicehead.tax_amt 
			- l_freight_onord_amt 
			- l_hand_onord_amt 
			WHERE cmpy_code = p_cmpy_code 
			AND cust_code = l_rec_invoicehead.org_cust_code 
		END IF 
		UPDATE customer 
		SET next_seq_num = l_rec_customer.next_seq_num + 1, 
		bal_amt = l_rec_customer.bal_amt, 
		curr_amt = l_rec_customer.curr_amt, 
		highest_bal_amt = l_rec_customer.highest_bal_amt, 
		cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt, 
		last_inv_date = l_rec_invoicehead.inv_date, 
		ytds_amt = l_rec_customer.ytds_amt, 
		mtds_amt = l_rec_customer.mtds_amt, 
		onorder_amt = l_rec_customer.onorder_amt 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		## Can we apply any receipts FOR CBD orders
		LET modu_err_message = "Committing all changes TO database" 

	COMMIT WORK 
	WHENEVER ERROR stop 
	
	IF l_rec_customer.pay_ind = "5" THEN 
		DECLARE c_cashreceipt cursor with hold FOR 
		SELECT unique cash_num INTO l_rec_cashreceipt.cash_num 
		FROM t_cashreceipt 
		FOREACH c_cashreceipt 
			LET l_inv_text = "inv_num = ",l_rec_invoicehead.inv_num 
			CALL auto_cash_apply(p_cmpy_code, 
			p_kandoouser_sign_on_code, 
			l_rec_cashreceipt.cash_num, 
			l_inv_text) 
		END FOREACH 
	END IF 

	DELETE FROM t_cashreceipt WHERE 1=1 
	RETURN l_rec_invoicehead.inv_num 

	LABEL recovery: 
	ROLLBACK WORK 
	CALL error_msg(p_cmpy_code,7050,modu_err_message,p_verbose_ind)
	 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION generate_inv(p_cmpy_code,p_kandoouser_sign_on_code,p_rowid,p_verbose_ind)
###########################################################################


###########################################################################
# FUNCTION valid_cust(p_cmpy_code,p_rowid,p_verbose_ind,p_inv_ind,p_cust_code,p_orig_code)
#
# Customer attribute checking IS NOT done FOR pre-delivered orders
# However we still need TO validate IF the pre-delivered ORDER has been
# editted OR invoiced.  Pre-delivered invoices are inv_ind = "3"
###########################################################################
FUNCTION valid_cust(p_cmpy_code,p_rowid,p_verbose_ind,p_inv_ind,p_cust_code,p_orig_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rowid INTEGER 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE p_inv_ind SMALLINT 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_orig_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_origcust RECORD LIKE customer.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_invoice_amt LIKE invoicehead.total_amt 
	DEFINE l_temp_text STRING 

	#   SELECT * INTO l_rec_customer.* FROM customer
	#    WHERE cmpy_code = p_cmpy_code
	#      AND cust_code = p_cust_code
	LET l_temp_text = "SELECT * FROM orderhead ", 
	"WHERE cmpy_code = '",p_cmpy_code,"' ", 
	"AND order_num = ? ", 
	"AND rev_num = ? " 
	PREPARE s3_ordhead FROM l_temp_text 
	DECLARE c3_ordhead cursor FOR s3_ordhead 
	# IF p_inv_ind != "3" THEN
	#    IF l_rec_customer.hold_code IS NOT NULL THEN
	#       SELECT reason_text INTO modu_err_message
	#         FROM holdreas
	#        WHERE cmpy_code = p_cmpy_code
	#          AND hold_code = l_rec_customer.hold_code
	#       LET modu_err_message = p_cust_code,":",modu_err_message clipped
	#       #7054 customer IS on hold
	#       CALL error_msg(p_cmpy_code,7054,modu_err_message,p_verbose_ind)
	#       RETURN FALSE
	#    END IF
	#    LET l_temp_text =
	#       "SELECT sum(x.sold_qty*(y.unit_price_amt+unit_tax_amt)) ",
	#         "FROM t_inv_detl x, ",
	#              "orderdetl y ",
	#        "WHERE x.inv_rowid =  ? ",
	#        "AND y.cmpy_code = '",p_cmpy_code,"' ",
	#        "AND y.order_num = ? ",
	#        "AND x.order_num = ? ",
	#        "AND y.line_num  = x.order_line_num "
	#    PREPARE s1_tdetl FROM l_temp_text
	#    DECLARE c1_tdetl CURSOR FOR s1_tdetl
	# END IF
	DECLARE c_revsion_chk cursor FOR 
	SELECT unique order_num,order_rev_num 
	FROM t_inv_detl 
	WHERE inv_rowid = p_rowid 
	GROUP BY 1,2 
	LET l_invoice_amt = 0
	 
	FOREACH c_revsion_chk INTO l_rec_orderhead.order_num,	l_rec_orderhead.rev_num 
		OPEN c3_ordhead USING l_rec_orderhead.order_num,	l_rec_orderhead.rev_num 
		FETCH c3_ordhead INTO l_rec_orderhead.*
		 
		IF sqlca.sqlcode = NOTFOUND THEN 
			## sales ORDER has changed since being picked
			LET modu_err_message = ": no.",l_rec_orderhead.order_num 
			CALL error_msg(p_cmpy_code,7056,modu_err_message,p_verbose_ind) 
			RETURN FALSE 
		END IF 
		
		IF l_rec_orderhead.hold_code IS NOT NULL THEN 
			SELECT reason_text INTO modu_err_message 
			FROM holdreas 
			WHERE cmpy_code = p_cmpy_code 
			AND hold_code = l_rec_orderhead.hold_code 
			## sales ORDER has been put on-hold since being picked
			LET modu_err_message = p_cust_code,":",modu_err_message clipped 
			CALL error_msg(p_cmpy_code,7055,modu_err_message,p_verbose_ind) 
			RETURN FALSE 
		END IF 
		#  IF p_inv_ind != 3 THEN
		#     OPEN c1_tdetl using p_rowid,
		#                         l_rec_orderhead.order_num,
		#                         l_rec_orderhead.order_num
		#     FETCH c1_tdetl INTO l_rec_orderhead.total_amt
		#     LET l_invoice_amt = l_invoice_amt + l_rec_orderhead.total_amt
		#  END IF
	END FOREACH 
	#   IF p_inv_ind != 3 THEN
	#      IF l_rec_customer.cred_override_ind = 0 THEN
	#         LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt -
	#                                        l_rec_customer.bal_amt
	#         IF l_invoice_amt > l_rec_customer.cred_bal_amt THEN
	#            ### Customer has exceeded credit limit
	#            CALL error_msg(p_cmpy_code,7057,l_rec_customer.cust_code,p_verbose_ind)
	#            RETURN FALSE
	#         END IF
	#      END IF
	#      IF p_orig_code IS NOT NULL THEN
	#         SELECT * INTO l_rec_origcust.*
	#           FROM customer
	#          WHERE cmpy_code = p_cmpy_code
	#            AND cust_code = p_orig_code
	#         IF l_rec_origcust.hold_code IS NOT NULL THEN
	#            SELECT reason_text INTO modu_err_message
	#              FROM holdreas
	#             WHERE cmpy_code = p_cmpy_code
	#               AND hold_code = l_rec_origcust.hold_code
	#            LET modu_err_message = p_orig_code,":",modu_err_message clipped
	#            #7058 original customer IS on hold
	#            CALL error_msg(p_cmpy_code,7058,modu_err_message,p_verbose_ind)
	#            RETURN FALSE
	#         END IF
	#         IF l_rec_origcust.cred_override_ind = 0 THEN
	#            SELECT sum(total_amt - paid_amt)
	#              INTO l_rec_origcust.bal_amt
	#              FROM invoicehead
	#             WHERE cmpy_code = p_cmpy_code
	#               AND cust_code = p_cust_code
	#               AND org_cust_code = p_orig_code
	#               AND total_amt != paid_amt
	#            IF l_rec_origcust.bal_amt IS NULL THEN
	#               LET l_rec_origcust.bal_amt = 0
	#            END IF
	#            IF (l_rec_origcust.bal_amt+l_invoice_amt)>l_rec_origcust.cred_limit_amt THEN
	#               SELECT sum(total_amt - appl_amt)
	#                 INTO l_rec_origcust.cred_bal_amt
	#                 FROM credithead
	#                WHERE cmpy_code = p_cmpy_code
	#                  AND cust_code = p_cust_code
	#                  AND org_cust_code = p_orig_code
	#                  AND total_amt != appl_amt
	#               IF l_rec_origcust.cred_bal_amt IS NULL THEN
	#                  LET l_rec_origcust.cred_bal_amt = 0
	#               END IF
	#               LET l_rec_origcust.bal_amt = l_rec_origcust.bal_amt
	#                                       - l_rec_origcust.cred_bal_amt
	#               IF (l_rec_origcust.bal_amt + l_invoice_amt)
	#                                       > l_rec_origcust.cred_limit_amt THEN
	#                  ## original customer has exceeded credit limit
	#                  CALL error_msg(p_cmpy_code,7059,p_orig_code,p_verbose_ind)
	#                  RETURN FALSE
	#               END IF
	#            END IF
	#         END IF
	#      END IF
	#   END IF
	RETURN TRUE 
END FUNCTION 
###########################################################################
# END FUNCTION valid_cust(p_cmpy_code,p_rowid,p_verbose_ind,p_inv_ind,p_cust_code,p_orig_code)
###########################################################################


###########################################################################
# FUNCTION error_msg(p_cmpy_code,p_msg_num,p_msg_text,p_verbose_ind)
#
#
###########################################################################
FUNCTION error_msg(p_cmpy_code,p_msg_num,p_msg_text,p_verbose_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_msg_num INTEGER 
	DEFINE p_msg_text char(60) 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE l_time LIKE delivmsg.msg_time 
	DEFINE l_event_text LIKE delivmsg.event_text 

	IF p_verbose_ind THEN 
		LET p_msg_text = kandoomsg("E",p_msg_num,p_msg_text) 
	ELSE 
		LET l_event_text = "Error during generating invoice/credit note" 
		LET l_time = time
		 
		INSERT INTO delivmsg VALUES (p_cmpy_code, 
		0, 
		"", 
		today, 
		l_time, 
		l_event_text, 
		p_msg_num, 
		p_msg_text) 
	END IF 
	
END FUNCTION
###########################################################################
# END FUNCTION error_msg(p_cmpy_code,p_msg_num,p_msg_text,p_verbose_ind)
###########################################################################
