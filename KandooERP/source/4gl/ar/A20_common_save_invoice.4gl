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
# \brief module - A21f.4gl
# Purpose - Writes details TO UPDATE tables FOR invoices.
#@#####################################################################
#
# FUNCTION write_inv() - Saves the invoice TO the database.
#
#  Database UPDATE works in the following manner
#
#  0.  Lock customer
#  1.  IF edit THEN
#  3.     - UPDATE prodstatus
#  4.     - INSERT neg prodledg
#  2.     - delete line items
#  6.     - UPDATE customer
#  7.     - INSERT audit
#  8.  END IF
#  9.  IF add THEN
#  10.    - get next invoice number
#  11. END IF
#  12. INSERT line items
#  13. UPDATE prodstatus
#  14. INSERT prodledg
#  15. IF add THEN
#  16.    - INSERT header
#  17. ELSE
#  18.    - UPDATE header
#  19. END IF
#  20. UPDATE customer
#  21. INSERT audit
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A21_GLOBALS.4gl" 
########################################################################
# FUNCTION write_invoice(p_mode)
#
#
########################################################################
FUNCTION write_invoice(p_mode) 
	DEFINE p_mode STRING 
	DEFINE l_err_message CHAR(40) 
	#DEFINE glob_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_serialinfo RECORD LIKE serialinfo.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_tax_amt LIKE invoicedetl.unit_tax_amt 
	DEFINE l_query_text VARCHAR(500) --huho try TO move variable FROM global TO local scope 
	#	DEFINE l_cnt      SMALLINT #not used

	##
	## Declare dynamic cursors
	##
	DECLARE c_t_invoicedetl CURSOR FOR 
	SELECT * FROM t_invoicedetl ORDER BY line_num 
	--   LET glob_temp_text = "SELECT * FROM prodstatus WHERE cmpy_code ='",trim(glob_rec_kandoouser.cmpy_code),"' ",
	--                      " AND part_code = ? AND ware_code = ? "
	LET l_query_text = 
		"SELECT * FROM prodstatus WHERE cmpy_code ='",trim(glob_rec_kandoouser.cmpy_code),"' ", 
		" AND part_code = ? AND ware_code = ? " 
	--DISPLAY  "glob_temp_text=", trim(glob_temp_text)
	#DISPLAY  "l_query_text=", trim(l_query_text)
	PREPARE s_prodstatus FROM l_query_text 
	DECLARE c_prodstatus CURSOR FOR s_prodstatus 

	GOTO bypass 

	LABEL recovery: 
	IF error_recover(l_err_message, status) != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with INSERT CURSOR"
		#DISPLAY "see ar/A21f.4gl"
		#EXIT PROGRAM (1)

		DECLARE c1_invoicedetl CURSOR FOR 
		INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*) #INSERT INTO invoicedetl

		OPEN c1_invoicedetl 

		DECLARE c_prodledg CURSOR FOR 
		INSERT INTO prodledg VALUES (l_rec_prodledg.*) #INSERT INTO prodledg

		OPEN c_prodledg 

		DECLARE c_customer CURSOR FOR 
		SELECT * FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = glob_rec_invoicehead.cust_code 
		FOR UPDATE 

		OPEN c_customer 
		FETCH c_customer INTO glob_rec_customer.* 

		IF p_mode = MODE_CLASSIC_ADD THEN #!!! NEW INVOICE !!! 
			LET l_err_message = "A21 - Next invoice number UPDATE" 
			
			LET glob_rec_invoicehead.inv_num = next_trans_num(
				glob_rec_kandoouser.cmpy_code,
				TRAN_TYPE_INVOICE_IN,
				glob_rec_invoicehead.acct_override_code)
				 
			IF glob_rec_invoicehead.inv_num < 0 THEN 
				LET status = glob_rec_invoicehead.inv_num 
				GOTO recovery 
			END IF 
		ELSE #!!! EDIT INVOICE !!! 
			#----------------------------------------------------------
			# Obtain existing invoicehead TO ensure no second edit OR posting has occurred.
			
			DECLARE c_invoicehead CURSOR FOR 
			SELECT * FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
			FOR UPDATE 
			OPEN c_invoicehead 
			FETCH c_invoicehead INTO l_rec_invoicehead.* 

			IF l_rec_invoicehead.rev_num != glob_rec_invoicehead.rev_num THEN 
				LET l_err_message = "A21 - Attempt TO concurrently edit Invoice" 
				GOTO recovery 
			END IF 

			IF l_rec_invoicehead.posted_flag = "Y" THEN 
				LET l_err_message = "A21 - Invoice has been posted during edit" 
				GOTO recovery 
			END IF 

			LET glob_rec_invoicehead.paid_amt = l_rec_invoicehead.paid_amt 
			LET glob_rec_invoicehead.posted_flag = l_rec_invoicehead.posted_flag 
			LET glob_rec_invoicehead.story_flag = l_rec_invoicehead.posted_flag 
			LET glob_rec_invoicehead.rev_date = today 
			LET glob_rec_invoicehead.rev_num = l_rec_invoicehead.rev_num + 1 
			LET l_err_message = "A21 - Customer backout " 
			
			#---------------------------------------------------------------------
			## Undo stock STATUS UPDATE
			##
			DECLARE c_invoicedetl CURSOR FOR 
			SELECT * FROM invoicedetl 
			WHERE cmpy_code=glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
			AND part_code IS NOT NULL 
			AND ship_qty != 0 

			FOREACH c_invoicedetl INTO l_rec_invoicedetl.* 
				OPEN c_prodstatus USING 
					l_rec_invoicedetl.part_code, 
					l_rec_invoicedetl.ware_code 
				FETCH c_prodstatus INTO l_rec_prodstatus.* 
				
				IF l_rec_prodstatus.onhand_qty IS NULL THEN 
					LET l_rec_prodstatus.onhand_qty = 0 
				END IF 

				LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 

				IF l_rec_prodstatus.stocked_flag = "Y" THEN 
					LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty					+ l_rec_invoicedetl.ship_qty 
				END IF 
				
				LET l_err_message = "A21 - Product ledger INSERT failed" 
				LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
				LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
				LET l_rec_prodledg.tran_date = today 
				LET l_rec_prodledg.seq_num = l_rec_prodstatus.seq_num 
				LET l_rec_prodledg.trantype_ind = "S" 
				LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
				LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
				LET l_rec_prodledg.source_text = l_rec_invoicedetl.cust_code 
				LET l_rec_prodledg.source_num = l_rec_invoicedetl.inv_num 
				LET l_rec_prodledg.tran_qty = l_rec_invoicedetl.ship_qty 
				LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
				LET l_rec_prodledg.hist_flag = "N" 
				LET l_rec_prodledg.post_flag = "N" 
				LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_prodledg.entry_date = today 
				LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt	/ glob_rec_invoicehead.conv_qty 
				LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt / glob_rec_invoicehead.conv_qty 
				
				PUT c_prodledg 
				UPDATE prodstatus 
				SET 
					onhand_qty = l_rec_prodstatus.onhand_qty, 
					seq_num = l_rec_prodstatus.seq_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = l_rec_prodstatus.part_code 
				AND ware_code = l_rec_prodstatus.ware_code
				 
			END FOREACH 

			#---------------------------------------
			# Delete the invoice lines
			#
			LET l_err_message = "A21 - Invoice line deletion failed" 

			DELETE FROM invoicedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
			
			LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt	- l_rec_invoicehead.total_amt 
			LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 

			INITIALIZE l_rec_araudit.* TO NULL 

			LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_araudit.tran_date = today 
			LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
			LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
			LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
			LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
			LET l_rec_araudit.tran_text = "Backout Invoice" 
			LET l_rec_araudit.tran_amt= (0 - l_rec_invoicehead.total_amt) 
			LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
			LET l_rec_araudit.sales_code = l_rec_invoicehead.sale_code 
			LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
			LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
			LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
			LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
			LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
			LET l_rec_araudit.entry_date = today 
			LET l_err_message = "A21 - Unable TO add TO AR log table " 
			
			INSERT INTO araudit VALUES (l_rec_araudit.*) 
			
			LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt	- l_rec_invoicehead.total_amt 
			LET glob_rec_customer.cred_bal_amt = glob_rec_customer.cred_limit_amt	- glob_rec_customer.bal_amt 
			LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt - l_rec_invoicehead.total_amt 
			LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt - l_rec_invoicehead.total_amt 
		END IF 

		#--------------------------------------------------
		## INITIALIZE the sum-of-lines header fields
		##
		LET glob_rec_invoicehead.cost_amt = 0 
		LET l_tax_amt = 0 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.goods_amt = 0 
		LET glob_rec_invoicehead.line_num = 0 
		LET l_err_message = "A21 - invoice line addition failed" 

		OPEN c_t_invoicedetl 

		FOREACH c_t_invoicedetl INTO l_rec_invoicedetl.* 
			LET glob_rec_invoicehead.line_num = glob_rec_invoicehead.line_num + 1 
			LET l_rec_invoicedetl.cmpy_code = glob_rec_invoicehead.cmpy_code 
			LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
			LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
			LET l_rec_invoicedetl.line_num = glob_rec_invoicehead.line_num 
			
			IF l_rec_invoicedetl.ext_tax_amt IS NULL THEN 
				LET l_rec_invoicedetl.ext_tax_amt = 0 
			END IF 
			
			IF l_rec_invoicedetl.ext_sale_amt IS NULL THEN 
				LET l_rec_invoicedetl.ext_sale_amt = 0 
			END IF 
			
			IF l_rec_invoicedetl.line_total_amt IS NULL THEN 
				LET l_rec_invoicedetl.line_total_amt = 0 
			END IF 
			
			IF l_rec_invoicedetl.ext_cost_amt IS NULL THEN 
				LET l_rec_invoicedetl.ext_cost_amt = 0 
			END IF 
			
			IF l_rec_invoicedetl.part_code IS NOT NULL AND l_rec_invoicedetl.ship_qty != 0 THEN 
				OPEN c_prodstatus USING 
					l_rec_invoicedetl.part_code, 
					l_rec_invoicedetl.ware_code 
				FETCH c_prodstatus INTO l_rec_prodstatus.* 

				IF l_rec_prodstatus.stocked_flag = "Y" THEN 
					LET l_rec_prodstatus.seq_num = l_rec_prodstatus.seq_num + 1 
					LET l_rec_invoicedetl.seq_num = l_rec_prodstatus.seq_num 

					IF l_rec_prodstatus.onhand_qty IS NULL THEN 
						LET l_rec_prodstatus.onhand_qty = 0 
					END IF 

					LET l_rec_prodstatus.onhand_qty = l_rec_prodstatus.onhand_qty - l_rec_invoicedetl.ship_qty
					  
					INITIALIZE l_rec_prodledg.* TO NULL 

					LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_prodledg.part_code = l_rec_invoicedetl.part_code 
					LET l_rec_prodledg.ware_code = l_rec_invoicedetl.ware_code 
					LET l_rec_prodledg.tran_date = glob_rec_invoicehead.inv_date 
					LET l_rec_prodledg.seq_num = l_rec_invoicedetl.seq_num 
					LET l_rec_prodledg.trantype_ind = "S" 
					LET l_rec_prodledg.year_num = glob_rec_invoicehead.year_num 
					LET l_rec_prodledg.period_num = glob_rec_invoicehead.period_num 
					LET l_rec_prodledg.source_text = l_rec_invoicedetl.cust_code 
					LET l_rec_prodledg.source_num = l_rec_invoicedetl.inv_num 
					LET l_rec_prodledg.tran_qty = 0 - l_rec_invoicedetl.ship_qty + 0 
					LET l_rec_prodledg.bal_amt = l_rec_prodstatus.onhand_qty 
					LET l_rec_prodledg.cost_amt = l_rec_invoicedetl.unit_cost_amt / glob_rec_invoicehead.conv_qty
					 
					LET l_rec_prodledg.sales_amt = l_rec_invoicedetl.unit_sale_amt / glob_rec_invoicehead.conv_qty
					 
					LET l_rec_prodledg.hist_flag = "N" 
					LET l_rec_prodledg.post_flag = "N" 
					LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
					LET l_rec_prodledg.entry_date = today 
					PUT c_prodledg 
				END IF 

				UPDATE prodstatus 
				SET 
					onhand_qty = l_rec_prodstatus.onhand_qty, 
					last_sale_date = glob_rec_invoicehead.inv_date, 
					seq_num = l_rec_prodstatus.seq_num 
				WHERE 
					cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = l_rec_invoicedetl.part_code 
					AND ware_code = l_rec_invoicedetl.ware_code 
			END IF 

			IF l_rec_invoicedetl.part_code IS NOT NULL THEN 
				LET l_rec_invoicedetl.line_acct_code = account_patch(
					glob_rec_kandoouser.cmpy_code,
					l_rec_invoicedetl.line_acct_code, 
					glob_rec_invoicehead.acct_override_code) 
			END IF 

			PUT c1_invoicedetl 

			LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt + l_rec_invoicedetl.ext_cost_amt 
			LET l_tax_amt = l_tax_amt + l_rec_invoicedetl.unit_tax_amt 
			LET glob_rec_invoicehead.tax_amt = glob_rec_invoicehead.tax_amt + l_rec_invoicedetl.ext_tax_amt 
			LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt + l_rec_invoicedetl.ext_sale_amt 

			#Now allocate the serial numbers as required
			SELECT unique (1) FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_invoicedetl.part_code 
			AND serial_flag = 'Y' 

			IF status <> NOTFOUND THEN 
				LET l_err_message = "A21f - serial_update " 
				LET l_rec_serialinfo.cmpy_code = l_rec_prodledg.cmpy_code 
				LET l_rec_serialinfo.part_code = l_rec_prodledg.part_code 
				LET l_rec_serialinfo.ware_code = l_rec_prodledg.ware_code 
				LET l_rec_serialinfo.trans_num = l_rec_invoicedetl.inv_num 
				LET l_rec_serialinfo.cust_code = glob_rec_invoicehead.cust_code 
				LET l_rec_serialinfo.trantype_ind = "S" 
				LET status = serial_update(
					l_rec_serialinfo.*, 
					l_rec_invoicedetl.ship_qty, 
					'') 

				IF status <> 0 THEN 
					GOTO recovery 
					EXIT PROGRAM 
				END IF 
			END IF 

		END FOREACH 

		#huho 27.3.2020 Had issues with disc_amt IS NULL
		IF glob_rec_invoicehead.disc_amt IS NULL THEN 
			LET glob_rec_invoicehead.disc_amt = 0 
		END IF
		
		LET status = serial_return('', '0') 
		LET glob_rec_invoicehead.cost_ind = glob_rec_arparms.costings_ind 
		LET glob_rec_invoicehead.total_amt = 
			glob_rec_invoicehead.tax_amt 
			+ glob_rec_invoicehead.goods_amt 
			+ glob_rec_invoicehead.freight_amt 
			+ glob_rec_invoicehead.freight_tax_amt 
			+ glob_rec_invoicehead.hand_amt 
			+ glob_rec_invoicehead.hand_tax_amt 

		IF p_mode = MODE_CLASSIC_EDIT THEN 
			UPDATE invoicehead 
			SET * = glob_rec_invoicehead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND inv_num = glob_rec_invoicehead.inv_num 
		ELSE 
			LET l_err_message = "A21 - Unable TO add TO invoice header table"

			#INSERT invoicehead Record
			IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
				INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*) #INSERT INTO invoicehead
			ELSE
				DISPLAY glob_rec_invoicehead.*
				CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
			END IF 
			
			SELECT unique 1 FROM statparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			IF status != NOTFOUND THEN 
				LET l_err_message = "A21f - Unable TO INSERT stattrig " 
				INSERT INTO stattrig VALUES (
					glob_rec_kandoouser.cmpy_code, 
					TRAN_TYPE_INVOICE_IN, 
					glob_rec_invoicehead.inv_num, 
					glob_rec_invoicehead.inv_date) 
			END IF 
		END IF 

		##
		## Now TO UPDATE customer
		##

		LET glob_rec_customer.next_seq_num = glob_rec_customer.next_seq_num + 1 
		LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt + glob_rec_invoicehead.total_amt 
		 
		LET l_err_message = "A21 - Unable TO add TO AR log table " 
		
		INITIALIZE l_rec_araudit.* TO NULL 
		
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_araudit.seq_num = glob_rec_customer.next_seq_num 
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "Enter Invoice" 
		LET l_rec_araudit.tran_amt = glob_rec_invoicehead.total_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = glob_rec_invoicehead.sale_code 
		LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = glob_rec_customer.bal_amt 
		LET l_rec_araudit.currency_code = glob_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = today 

		INSERT INTO araudit VALUES (l_rec_araudit.*) #INSERT INTO araudit

		LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt + glob_rec_invoicehead.total_amt 
		 
		IF glob_rec_customer.bal_amt > glob_rec_customer.highest_bal_amt THEN 
			LET glob_rec_customer.highest_bal_amt = glob_rec_customer.bal_amt 
		END IF 
		
		LET glob_rec_customer.cred_bal_amt = 
			glob_rec_customer.cred_limit_amt 
			- glob_rec_customer.bal_amt 
			- glob_rec_customer.onorder_amt 

		IF year(glob_rec_invoicehead.inv_date) > year(glob_rec_customer.last_inv_date) THEN 
			LET glob_rec_customer.ytds_amt = 0 
			LET glob_rec_customer.mtds_amt = 0 
		END IF 
		
		LET glob_rec_customer.ytds_amt = glob_rec_customer.ytds_amt + glob_rec_invoicehead.total_amt 
		 
		IF month(glob_rec_invoicehead.inv_date)>month(glob_rec_customer.last_inv_date) THEN 
			LET glob_rec_customer.mtds_amt = 0 
		END IF 

		LET glob_rec_customer.mtds_amt = glob_rec_customer.mtds_amt + glob_rec_invoicehead.total_amt 
		 
		LET glob_rec_customer.last_inv_date = glob_rec_invoicehead.inv_date 
		LET l_err_message = "A21 - Customer actual UPDATE " 

		UPDATE customer SET #Update customer with credit status etc.
			next_seq_num = glob_rec_customer.next_seq_num, 
			bal_amt = glob_rec_customer.bal_amt, 
			curr_amt = glob_rec_customer.curr_amt, 
			highest_bal_amt = glob_rec_customer.highest_bal_amt, 
			cred_bal_amt = glob_rec_customer.cred_bal_amt, 
			last_inv_date = glob_rec_customer.last_inv_date, 
			ytds_amt = glob_rec_customer.ytds_amt, 
			mtds_amt = glob_rec_customer.mtds_amt 
		WHERE 
			cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = glob_rec_customer.cust_code 

	COMMIT WORK 

	RETURN glob_rec_invoicehead.inv_num 
END FUNCTION 
########################################################################
# END FUNCTION write_invoice(p_mode)
########################################################################