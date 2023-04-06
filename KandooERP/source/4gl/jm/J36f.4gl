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

	Source code beautified by beautify.pl on 2020-01-02 19:48:06	$Id: $
}



# Purpose - Write tables - Invoice Edit


GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 

DEFINE 
test_cost DECIMAL(10,2), 
test_sale DECIMAL(10,2), 
inv1, inv2, inv3, inv4 SMALLINT, 
err_continue CHAR(1), 
err_message CHAR(40), 
total_costs, 
total_tax, 
total_pay_amt, 
total_amt MONEY 

FUNCTION write_inv() 
	#  Tables are updated in this Order
	#     arparms
	#     customer
	#     araudit
	#     activity
	#     invoicedetl
	#     resbill
	#     invoicehead
	DEFINE 
	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date DATE, 
		var_code SMALLINT, 
		activity_code CHAR(8), 
		seq_num INTEGER, 
		line_num SMALLINT, 
		trans_type_ind CHAR(2), 
		trans_source_num INTEGER, 
		trans_source_text CHAR(8), 
		trans_amt money(16,2), 
		trans_qty DECIMAL(15,3), 
		charge_amt money(16,2), 
		apply_qty DECIMAL(15,3), 
		apply_amt DECIMAL(16,2), 
		apply_cos_amt DECIMAL(16,2), 
		desc_text CHAR(40), 
		prev_apply_qty DECIMAL(15,3), 
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_sav_invdetl RECORD LIKE invoicedetl.*, 
	pa_invd_chk array[600] OF RECORD 
		trans_type_ind CHAR(2), 
		trans_source_text CHAR(8) 
	END RECORD, 
	pa_invd_bill_way_ind array[1500] OF RECORD 
		bill_way_ind LIKE activity.bill_way_ind 
	END RECORD, 
	line_num LIKE invoicedetl.line_num, 
	fv_cust_code LIKE saleshist.cust_code, 
	pr_araudit RECORD LIKE araudit.*, 
	idx, cnt SMALLINT, 
	note_idx SMALLINT, 
	fr_tax_per DECIMAL(5,3), 
	la_tax_per DECIMAL(5,3), 
	tmp_bill_qty LIKE resbill.apply_qty, 
	fv_cust_currency LIKE customer.currency_code, 
	fv_base_currency LIKE glparms.base_currency_code, 
	fv_xchange LIKE invoicehead.conv_qty, 
	fv_use_currency SMALLINT 

	IF NOT allow_update THEN 
		LET glob_password = " " 
		ERROR "No changes made TO invoice - view only" 
		SLEEP 2 
		RETURN 
	END IF 

	INITIALIZE pr_araudit.* TO NULL 
	LET total_tax = 0 
	LET total_pay_amt = 0 
	LET total_amt = 0 
	LET total_costs = 0 
	LET pr_inv_line_num = 0 
	LET pr_tax_line_num = 0 
	LET glob_password = " " 
	LET inv1 = 0 
	LET inv2 = 0 
	LET inv3 = 0 
	LET inv4 = 0 

	SELECT customer.currency_code 
	INTO fv_cust_currency 
	FROM customer 
	WHERE customer.cust_code = pr_invoicehead.cust_code 
	AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 

	SELECT glparms.base_currency_code 
	INTO fv_base_currency 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = '1' 

	IF fv_base_currency <> fv_cust_currency THEN 
		LET fv_use_currency = true 
	ELSE 
		LET fv_use_currency = false 
	END IF 


	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		LOCK TABLE activity in share MODE 
		LOCK TABLE invoicedetl in share MODE 


		# Reverse out entrys in customer, araudit, AND activity,
		# invoicehead AND invoicedetl. The resbill table IS NOT
		# reversed instead an edit RECORD IS inserted TO reflect
		# the changes.



		# Customer table reverse out invoice


		LET err_message = "J36 - Customer Reverse SELECT" 
		DECLARE cm2_curs CURSOR FOR 
		SELECT * 
		INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code 
		FOR UPDATE 

		OPEN cm2_curs 
		FETCH cm2_curs 

		#FETCH cm2_curs

		# It IS OK TO work with pr_saved_inv as this IS what the invoice
		#            originally was (in foreign currency).

		LET err_message = "J36 - Customer Rows Reversed " 
		LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
		LET pr_customer.bal_amt = pr_customer.bal_amt - 
		pr_saved_inv.total_amt 
		LET pr_customer.curr_amt = pr_customer.curr_amt - 
		pr_saved_inv.total_amt 
		LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
		- (pr_customer.bal_amt + 
		pr_customer.onorder_amt) 
		LET pr_customer.ytds_amt = pr_customer.ytds_amt - 
		pr_saved_inv.total_amt 
		LET pr_customer.mtds_amt = pr_customer.mtds_amt - 
		pr_saved_inv.total_amt 
		LET err_message = "J36 - Customer Table Actual Reversal " 
		UPDATE customer SET next_seq_num = pr_customer.next_seq_num, 
		bal_amt = pr_customer.bal_amt, 
		curr_amt = pr_customer.curr_amt, 
		cred_bal_amt = pr_customer.cred_bal_amt, 
		ytds_amt = pr_customer.ytds_amt, 
		mtds_amt = pr_customer.mtds_amt 
		WHERE CURRENT OF cm2_curs 
		CLOSE cm2_curs 


		# Araudit INSERT FOR reversal


		LET err_message = "J36 - Unable TO add TO AR log table (1)" 

		LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_araudit.tran_date = pr_invoicehead.inv_date 
		LET pr_araudit.cust_code = pr_invoicehead.cust_code 
		LET pr_araudit.seq_num = pr_customer.next_seq_num 
		LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET pr_araudit.source_num = pr_invoicehead.inv_num 
		LET pr_araudit.tran_text = "Reverse Invoice" 
		LET pr_araudit.tran_amt = (0 - pr_saved_inv.total_amt) 
		LET pr_araudit.sales_code = pr_invoicehead.sale_code 
		LET pr_araudit.bal_amt = pr_customer.bal_amt 
		LET pr_araudit.year_num = pr_invoicehead.year_num 
		LET pr_araudit.period_num = pr_invoicehead.period_num 
		LET pr_araudit.currency_code = pr_customer.currency_code 
		LET pr_araudit.conv_qty = pr_saved_inv.conv_qty 
		LET pr_araudit.entry_date = today 

		INSERT INTO araudit VALUES (pr_araudit.*) 


		# reverse out all activity records

		FOR cnt = 1 TO arr_size 


			# Activity UPDATE

			LET err_message = "J36 - Activity SELECT failed" 

			DECLARE upd_act1 CURSOR FOR 
			SELECT activity.* 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_job.job_code 
			AND var_code = pa_inv_line[cnt].var_code 
			AND activity_code = pa_inv_line[cnt].activity_code 
			FOR UPDATE 

			OPEN upd_act1 
			FETCH upd_act1 INTO pr_activity.* 

			LET err_message = "J36 - Activity Actual Reversal" 

			# FOR recurring jobs we NEVER accumulate
			# OR reverse the bill qty
			# instead we SET TO the qty on jobledger cos they
			# can't amend this anyway
			IF pr_job.bill_way_ind = "R" THEN 
				UPDATE activity 
				SET act_bill_amt = pr_activity.act_bill_amt - 
				ps_activity[cnt].this_bill_amt, 
				post_cost_amt = pr_activity.post_cost_amt - 
				ps_activity[cnt].this_cos_amt 
				WHERE CURRENT OF upd_act1 
			ELSE 
				UPDATE activity 
				SET act_bill_amt = pr_activity.act_bill_amt - 
				ps_activity[cnt].this_bill_amt, 
				post_cost_amt = pr_activity.post_cost_amt - 
				ps_activity[cnt].this_cos_amt, 
				act_bill_qty = pr_activity.act_bill_qty - 
				ps_activity[cnt].this_bill_qty 
				WHERE CURRENT OF upd_act1 
			END IF 
		END FOR 

		# Reverse out all resbills FOR the invoice AND delete all invoicedetl
		# AND the invoicehead RECORD THEN readd LIKE a normal invoice

		FOR cnt = 1 TO arr_size 
			# no resbills are created FOR fixed price jobs
			IF pa_inv_line[cnt].bill_way_ind != "F" THEN 


				# NOT FIXED PRICE JOB


				# SELECT all lines cos we need TO reverse out any lines that
				# were previously being invoiced AND have now been un flagged
				DECLARE c_tmpbill1 CURSOR FOR 
				SELECT tempbill.* 
				FROM tempbill 
				WHERE var_code = pa_inv_line[cnt].var_code 
				AND activity_code = pa_inv_line[cnt].activity_code 

				FOREACH c_tmpbill1 INTO pr_tempbill.* 
					CALL reverse_resbill(pr_tempbill.*) 
				END FOREACH 
			END IF 
		END FOR 


		#
		# Tables updates AND inserts
		#



		# Customer table UPDATE


		LET err_message = "J36 - Customer Update SELECT" 
		DECLARE cm1_curs CURSOR FOR 
		SELECT * 
		INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code 
		FOR UPDATE 

		OPEN cm1_curs 
		FETCH cm1_curs 

		LET err_message = "J36 - Customer Rows Updated " 

		# Convert all currency amounts TO FC before saving in AR

		IF fv_use_currency THEN 
			LET fv_xchange = pr_invoicehead.conv_qty 
		ELSE 
			LET fv_xchange = 1 
		END IF 

		LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
		LET pr_customer.bal_amt = pr_customer.bal_amt + 
		( pr_invoicehead.total_amt * fv_xchange ) 
		#LET pr_customer.bal_amt = pr_customer.bal_amt +
		#                            pr_invoicehead.total_amt
		LET pr_customer.curr_amt = pr_customer.curr_amt + 
		( pr_invoicehead.total_amt * fv_xchange ) 
		#  LET pr_customer.curr_amt = pr_customer.curr_amt +
		#                             pr_invoicehead.total_amt
		IF (pr_customer.bal_amt > pr_customer.highest_bal_amt) THEN 
			LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
		END IF 
		LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt 
		- (pr_customer.bal_amt + 
		pr_customer.onorder_amt) 
		IF year(pr_invoicehead.inv_date) > 
		year(pr_customer.last_inv_date) THEN 
			LET pr_customer.ytds_amt = 0 
		END IF 
		LET pr_customer.ytds_amt = pr_customer.ytds_amt + 
		pr_invoicehead.total_amt 
		IF (month(pr_invoicehead.inv_date) > 
		month(pr_customer.last_inv_date) 
		OR year(pr_invoicehead.inv_date) > 
		year(pr_customer.last_inv_date)) THEN 
			LET pr_customer.mtds_amt = 0 
		END IF 
		LET pr_customer.mtds_amt = pr_customer.mtds_amt + 
		pr_invoicehead.total_amt 
		IF pr_invoicehead.inv_date > pr_customer.last_inv_date THEN 
			LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
		END IF 
		LET err_message = "J36 - Customer Table Actual Update " 
		UPDATE customer SET next_seq_num = pr_customer.next_seq_num, 
		bal_amt = pr_customer.bal_amt, 
		curr_amt = pr_customer.curr_amt, 
		highest_bal_amt = pr_customer.highest_bal_amt, 
		cred_bal_amt = pr_customer.cred_bal_amt, 
		last_inv_date = pr_customer.last_inv_date, 
		ytds_amt = pr_customer.ytds_amt, 
		mtds_amt = pr_customer.mtds_amt 
		WHERE CURRENT OF cm1_curs 
		CLOSE cm1_curs 

		# Araudit INSERT

		LET err_message = "J36 - Unable TO add TO AR log table " 
		LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_araudit.tran_date = pr_invoicehead.inv_date 
		LET pr_araudit.cust_code = pr_invoicehead.cust_code 
		LET pr_araudit.seq_num = pr_customer.next_seq_num 
		LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET pr_araudit.source_num = pr_invoicehead.inv_num 
		LET pr_araudit.tran_text = "Enter Invoice" 
		LET pr_araudit.tran_amt = pr_invoicehead.total_amt * fv_xchange 
		#LET pr_araudit.tran_amt = pr_invoicehead.total_amt
		LET pr_araudit.sales_code = pr_invoicehead.sale_code 
		LET pr_araudit.bal_amt = pr_customer.bal_amt 
		LET pr_araudit.year_num = pr_invoicehead.year_num 
		LET pr_araudit.period_num = pr_invoicehead.period_num 
		LET pr_araudit.currency_code = pr_customer.currency_code 
		LET pr_araudit.conv_qty = pr_invoicehead.conv_qty 
		LET pr_araudit.entry_date = today 
		INSERT INTO araudit VALUES (pr_araudit.*) 

		#
		# The 'for' loop below loads an ARRAY of invoicedetl which are inserted
		# later on
		#

		FOR cnt = 1 TO arr_size 
			IF pa_inv_line[cnt].invoice_flag IS NOT NULL THEN 
				# don't write out any lines with no bill OR cos amounts
				IF pa_inv_line[cnt].this_bill_amt = 0 AND 

				pa_inv_line[cnt].this_cos_amt = 0 AND 
				pa_inv_line[cnt].this_bill_qty = 0 THEN 
					CONTINUE FOR 
				END IF 

				# Activity UPDATE

				LET err_message = "J36 - Activity SELECT failed" 
				DECLARE upd_act CURSOR FOR 
				SELECT activity.* 
				FROM activity 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND job_code = pr_job.job_code 
				AND var_code = pa_invoicedetl[cnt].var_code 
				AND activity_code = pa_invoicedetl[cnt].activity_code 
				FOR UPDATE 
				OPEN upd_act 
				FETCH upd_act INTO pr_activity.* 
				LET err_message = "J36 - Activity Actual Update" 

				# FOR recurring jobs we NEVER accumulate the bill qty
				# instead we SET TO the qty on jobledger cos they
				# can't amend this anyway
				IF pr_job.bill_way_ind = "R" THEN 
					UPDATE activity 
					SET act_bill_amt = pr_activity.act_bill_amt + 
					pa_inv_line[cnt].this_bill_amt, 
					post_cost_amt = pr_activity.post_cost_amt + 
					pa_inv_line[cnt].this_cos_amt, 
					act_bill_qty = pa_inv_line[cnt].this_bill_qty 
					WHERE CURRENT OF upd_act 
				ELSE 
					UPDATE activity 
					SET act_bill_amt = pr_activity.act_bill_amt + 
					pa_inv_line[cnt].this_bill_amt, 
					post_cost_amt = pr_activity.post_cost_amt + 
					pa_inv_line[cnt].this_cos_amt, 
					act_bill_qty = pr_activity.act_bill_qty + 
					pa_inv_line[cnt].this_bill_qty 
					WHERE CURRENT OF upd_act 
				END IF 


				#
				# In the following code the arrays are used as follows :-
				#
				# pa_invoicedetl[x].*  : holds the original activity invoice
				#                        lines FROM the entry SCREEN
				# pa_invd_ins[x]       : holds the lines that are TO be
				#                        inserted INTO invoicedetl
				#

				IF pa_inv_line[cnt].bill_way_ind = "F" THEN 

					# FIXED PRICE JOB

					LET pr_inv_line_num = pr_inv_line_num + 1 
					LET pa_invd_bill_way_ind[pr_inv_line_num].bill_way_ind = 
					pa_inv_line[cnt].bill_way_ind 
					LET pa_invd_ins[pr_inv_line_num].* = pa_invoicedetl[cnt].* 
					LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 
					CALL fix_nulls() 
					LET pa_invd_ins[pr_inv_line_num].inv_num = 
					pr_invoicehead.inv_num 
					LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 
					pa_invd_ins[pr_inv_line_num].ext_cost_amt 
					LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 
					pa_invd_ins[pr_inv_line_num].ext_sale_amt 

					LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
					LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 
					CALL increment_totals() 
				ELSE 

					# NOT FIXED PRICE JOB

					IF pr_invoicehead.bill_issue_ind IS NULL OR 

					pr_invoicehead.bill_issue_ind NOT matches "[1234]" THEN 
						ERROR "You have an incorrect bill type, Invoice Aborting" 
						SLEEP 10 
						EXIT program 
					END IF 
					DECLARE c_tmpbill CURSOR FOR 
					SELECT tempbill.* 
					FROM tempbill 
					WHERE var_code = pa_inv_line[cnt].var_code 
					AND activity_code = pa_inv_line[cnt].activity_code 
					AND trans_invoice_flag = "*" 
					LET pr_invoicedetl.* = pa_invoicedetl[cnt].* 

					# FOR a summary job all detail rows in the ARRAY will
					# have the same line number so they can be summarised
					# later on.
					LET pr_inv_line_num = pr_inv_line_num + 1 

					IF pr_invoicehead.bill_issue_ind = "1" OR 
					pr_invoicehead.bill_issue_ind = "3" THEN {summary} 
						LET pr_invoicedetl.line_num = pr_inv_line_num + 1 
						LET pa_invd_bill_way_ind[pr_inv_line_num].bill_way_ind = 
						pa_inv_line[cnt].bill_way_ind 
					END IF 

					LET pr_invoicedetl.activity_code = NULL 
					LET pr_invoicedetl.ext_sale_amt = 0 
					LET pr_invoicedetl.ext_tax_amt = 0 
					LET pr_invoicedetl.line_total_amt = 0 
					LET pr_invoicedetl.ext_cost_amt = 0 
					LET pr_invoicedetl.ship_qty = 0 
					LET pr_invoicedetl.unit_cost_amt = 0 
					LET pr_invoicedetl.unit_sale_amt = 0 
					LET pr_invoicedetl.inv_num = pr_invoicehead.inv_num 

					# this code inserts a heading zero value invoice line
					IF pr_invoicedetl.line_text IS NOT NULL AND 
					pr_invoicedetl.line_text != " " THEN 
						LET pa_invd_bill_way_ind[pr_inv_line_num].bill_way_ind = 
						pa_inv_line[cnt].bill_way_ind 

						IF pr_invoicehead.bill_issue_ind = "2" OR 
						pr_invoicehead.bill_issue_ind = "4" THEN 
							LET pr_invoicedetl.line_num = pr_inv_line_num 
						END IF 
						LET pa_invd_ins[pr_inv_line_num].* = pr_invoicedetl.* 

						LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
						LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 
					ELSE 
						LET pr_inv_line_num = pr_inv_line_num - 1 
					END IF 

					FOREACH c_tmpbill INTO pr_tempbill.* 
						LET pr_inv_line_num = pr_inv_line_num + 1 
						LET pa_invd_ins[pr_inv_line_num].* = pa_invoicedetl[cnt].* 
						LET pa_invd_ins[pr_inv_line_num].jobledger_seq_num = 
						pr_tempbill.seq_num 
						CALL fix_nulls() 

						IF pr_invoicehead.bill_issue_ind = "1" OR 
						pr_invoicehead.bill_issue_ind = "3" THEN 
							LET pa_invd_ins[pr_inv_line_num].line_num = 
							pr_invoicedetl.line_num 
						ELSE 
							LET pa_invd_ins[pr_inv_line_num].line_num = 
							pr_inv_line_num 
						END IF 
						LET pa_invd_ins[pr_inv_line_num].inv_num = 
						pr_invoicehead.inv_num 
						LET pa_invd_ins[pr_inv_line_num].line_text = 
						pr_tempbill.desc_text 
						LET pa_invd_ins[pr_inv_line_num].ext_sale_amt = 
						pr_tempbill.apply_amt 
						LET pa_invd_ins[pr_inv_line_num].line_total_amt = 
						pr_tempbill.apply_amt 
						LET pa_invd_ins[pr_inv_line_num].ext_cost_amt = 
						pr_tempbill.apply_cos_amt 
						IF pr_tempbill.apply_qty IS NULL THEN 
							LET pa_invd_ins[pr_inv_line_num].ship_qty = 1 
						ELSE 
							LET pa_invd_ins[pr_inv_line_num].ship_qty = 
							pr_tempbill.apply_qty 
						END IF 

						IF pa_invd_ins[pr_inv_line_num].ship_qty IS NOT NULL THEN 
							IF pa_invd_ins[pr_inv_line_num].ship_qty != 0 THEN 
								LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 
								pa_invd_ins[pr_inv_line_num].ext_cost_amt 
								/ pa_invd_ins[pr_inv_line_num].ship_qty 
								LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 
								pa_invd_ins[pr_inv_line_num].ext_sale_amt 
								/ pa_invd_ins[pr_inv_line_num].ship_qty 
							ELSE 
								LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 0 
								LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 0 
							END IF 
						END IF 

						LET pa_invd_chk[pr_inv_line_num].trans_type_ind = 
						pr_tempbill.trans_type_ind 
						LET pa_invd_chk[pr_inv_line_num].trans_source_text = 
						pr_tempbill.trans_source_text 

						CALL increment_totals() 
						# write away the resbill RECORD FOR detail AND summary
						# non fixed price invoices - note the line number will
						# be the same FOR summary jobs AND different FOR the
						# detailed jobs
						CALL write_resbill(pr_tempbill.*, 
						pa_invd_ins[pr_inv_line_num].line_num) 

					END FOREACH 
				END IF 

				# note_size IS a count of the total number of note lines
				FOR note_idx = 1 TO note_size 
					IF pa_notes[note_idx].activity_code = 
					pa_inv_line[cnt].activity_code 
					AND pa_notes[note_idx].var_code = 
					pa_inv_line[cnt].var_code THEN 
						LET pr_inv_line_num = pr_inv_line_num + 1 
						LET pa_invd_ins[pr_inv_line_num].* = pa_invoicedetl[cnt].* 
						LET pa_invd_ins[pr_inv_line_num].inv_num = 
						pr_invoicehead.inv_num 
						LET pa_invd_ins[pr_inv_line_num].line_text = 
						pa_notes[note_idx].note_code 
						LET pa_invd_ins[pr_inv_line_num].ext_sale_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].line_total_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].ext_cost_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].ship_qty = 0 
						LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 
						LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
						LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 
						EXIT FOR 
					END IF 
				END FOR 
			END IF 
		END FOR 

		# process the pa_invd_ins ARRAY TO calculate tax FOR each element
		FOR x = 1 TO pr_inv_line_num 
			IF pa_invd_bill_way_ind[x].bill_way_ind = "F" THEN 
				CALL find_tax(pr_invoicehead.tax_code, 
				" ", # part NOT required 
				" ", # warehouse NOT required 
				pr_inv_line_num, 
				x, 
				pa_invd_ins[x].ext_sale_amt, 
				1, 
				"S", 
				"", 
				"") 
				RETURNING tmp_ext_price_amt, 
				pa_invd_ins[x].unit_tax_amt, 
				pa_invd_ins[x].ext_tax_amt, 
				tmp_line_tot_amt, 
				tmp_tax_code 
				IF pa_invd_ins[x].ext_tax_amt IS NULL THEN 
					LET pa_invd_ins[x].ext_tax_amt = 0 
				END IF 
				LET pa_invd_ins[x].line_total_amt = pa_invd_ins[x].line_total_amt 
				+ pa_invd_ins[x].ext_tax_amt 
				######Add tax code TO invoicedetl table
				LET pa_invd_ins[x].tax_code = tmp_tax_code 
				CONTINUE FOR 
			END IF 
			LET tot_lines = pr_inv_line_num 
			IF tot_lines IS NULL THEN 
				LET tot_lines = 0 
			END IF 
			IF pa_invd_ins[x].cust_code IS NULL OR 
			pa_invd_ins[x].cmpy_code IS NULL OR 
			pa_invd_ins[x].inv_num IS NULL OR 
			pa_invd_ins[x].line_num IS NULL THEN 
				CONTINUE FOR 
			END IF 

			IF pa_invd_chk[x].trans_type_ind != "IS" OR 
			pa_invd_chk[x].trans_type_ind IS NULL THEN 




				CALL find_tax(pr_invoicehead.tax_code, 
				pa_invd_chk[x].trans_source_text, 
				pa_invd_ins[x].line_text[16,18], 
				tot_lines, 
				x, 
				pa_invd_ins[x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", 
				"", 
				"") 
				RETURNING tmp_ext_price_amt, 
				pa_invd_ins[x].unit_tax_amt, 
				pa_invd_ins[x].ext_tax_amt, 
				tmp_line_tot_amt, 
				tmp_tax_code 
				IF pa_invd_ins[x].ext_tax_amt IS NULL THEN 
					LET pa_invd_ins[x].ext_tax_amt = 0 
				END IF 
				LET pa_invd_ins[x].line_total_amt = pa_invd_ins[x].line_total_amt + 
				pa_invd_ins[x].ext_tax_amt 
				######Add tax code TO invoicedetl table
				LET pa_invd_ins[x].tax_code = tmp_tax_code 
			ELSE 
				CALL find_tax(pr_invoicehead.tax_code, 
				pa_invd_ins[x].line_text[1,15], 
				pa_invd_ins[x].line_text[16,18], 
				tot_lines, 
				x, 
				pa_invd_ins[x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", 
				"", 
				"") 
				RETURNING tmp_ext_price_amt, 
				pa_invd_ins[x].unit_tax_amt, 
				pa_invd_ins[x].ext_tax_amt, 
				tmp_line_tot_amt, 
				tmp_tax_code 
				IF pa_invd_ins[x].ext_tax_amt IS NULL THEN 
					LET pa_invd_ins[x].ext_tax_amt = 0 
				END IF 
				LET pa_invd_ins[x].line_total_amt = pa_invd_ins[x].line_total_amt + 
				pa_invd_ins[x].ext_tax_amt 
				######Add tax code TO invoicedetl table
				LET pa_invd_ins[x].tax_code = tmp_tax_code 
			END IF 
			IF pa_invd_ins[x].line_total_amt IS NULL THEN 
				LET pa_invd_ins[x].line_total_amt = 0 
			END IF 
		END FOR 

		#
		# Cycle through all elements in the billing ARRAY AND add invoicedetl
		# rows as follows :-
		# Fixed price jobs - one invoicedetl RECORD per activity ie fixed price
		#                    job customers don't see a breakdown of resource
		#                    charging
		# Other job types (1) Summary - one invoicedetl per activity
		#                 (2) Detailed - one invoicedetl per resource alloc
		#


		# Delete all invoicedetl lines THEN re-add

		# UPDATE SALES HISTORY TRANS TABLE
		DECLARE c_invdetl CURSOR FOR 
		SELECT * 
		INTO pr_invoicedetl.* 
		FROM invoicedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND inv_num = pr_invoicehead.inv_num 
		FOREACH c_invdetl 
			IF pr_invoicehead.org_cust_code IS NULL THEN 
				LET fv_cust_code = pr_invoicehead.cust_code 
			ELSE 
				LET fv_cust_code = pr_invoicehead.org_cust_code 
			END IF 
			# This CALL IS OK because it IS freshly read in FROM Idetl
			#            which IS still in foreign currency.
			CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
			"C", 
			fv_cust_code, 
			pr_invoicedetl.cat_code, 
			pr_invoicedetl.part_code, 
			pr_invoicedetl.line_text, 
			pr_invoicedetl.ware_code, 
			pr_invoicehead.sale_code, 
			pr_invoicehead.acct_override_code, 
			pr_invoicehead.year_num, 
			pr_invoicehead.period_num, 
			pr_invoicedetl.ship_qty, 
			pr_invoicehead.conv_qty, 
			pr_invoicedetl.ext_cost_amt, 
			pr_invoicedetl.ext_sale_amt, 
			pr_invoicedetl.ext_tax_amt, 
			pr_invoicedetl.disc_amt) 
		END FOREACH 


		DELETE FROM invoicedetl WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code 
		AND inv_num = pr_invoicehead.inv_num 
		LET line_num = 0 
		FOR x = 1 TO pr_inv_line_num 
			CASE pr_invoicehead.bill_issue_ind 
				WHEN "1" {summary invoice} 
					IF line_num != pa_invd_ins[x].line_num THEN 
						# on change of line number we have a new activity
						# so we INSERT the summary of the previous activity
						# AND SET up the next one
						IF line_num != 0 THEN 
							LET err_message = 
							"J36 - invoice line addition failed (1)" 
							LET pr_invoicedetl.* = pr_summary.* 
							# UPDATE SALES HISTORY TRANS TABLE
							IF pr_invoicehead.org_cust_code IS NULL THEN 
								LET fv_cust_code = pr_invoicehead.cust_code 
							ELSE 
								LET fv_cust_code = pr_invoicehead.org_cust_code 
							END IF 
							# We need TO convert the new Idetl lines here.
							IF fv_use_currency THEN 
								LET pr_invoicedetl.ext_cost_amt = 
								pr_invoicedetl.ext_cost_amt * fv_xchange 
								LET pr_invoicedetl.ext_sale_amt = 
								pr_invoicedetl.ext_sale_amt * fv_xchange 
								LET pr_invoicedetl.ext_tax_amt = 
								pr_invoicedetl.ext_tax_amt * fv_xchange 
								LET pr_invoicedetl.disc_amt = 
								pr_invoicedetl.disc_amt * fv_xchange 
								LET pr_invoicedetl.unit_sale_amt = 
								pr_invoicedetl.unit_sale_amt * fv_xchange 
								LET pr_invoicedetl.line_total_amt = 
								pr_invoicedetl.line_total_amt * fv_xchange 
								LET pr_invoicedetl.unit_tax_amt = 
								pr_invoicedetl.unit_tax_amt * fv_xchange 
								LET pr_invoicedetl.unit_cost_amt = 
								pr_invoicedetl.unit_cost_amt * fv_xchange 
								LET pr_invoicedetl.comm_amt = 
								pr_invoicedetl.comm_amt * fv_xchange 
								LET pr_invoicedetl.ext_bonus_amt = 
								pr_invoicedetl.ext_bonus_amt * fv_xchange 
								LET pr_invoicedetl.ext_stats_amt = 
								pr_invoicedetl.ext_stats_amt * fv_xchange 
								LET pr_invoicedetl.list_price_amt = 
								pr_invoicedetl.list_price_amt * fv_xchange 
							END IF 
							CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
							"I", 
							fv_cust_code, 
							pr_invoicedetl.cat_code, 
							pr_invoicedetl.part_code, 
							pr_invoicedetl.line_text, 
							pr_invoicedetl.ware_code, 
							pr_invoicehead.sale_code, 
							pr_invoicehead.acct_override_code, 
							pr_invoicehead.year_num, 
							pr_invoicehead.period_num, 
							pr_invoicedetl.ship_qty, 
							pr_invoicehead.conv_qty, 
							pr_invoicedetl.ext_cost_amt, 
							pr_invoicedetl.ext_sale_amt, 
							pr_invoicedetl.ext_tax_amt, 
							pr_invoicedetl.disc_amt) 

							INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
							LET inv1 = true 
						END IF 
						LET pr_summary.* = pa_invd_ins[x].* 
						LET pr_summary.jobledger_seq_num = 0 
						IF pr_summary.unit_cost_amt IS NULL THEN 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ext_cost_amt IS NULL THEN 
							LET pr_summary.ext_cost_amt = 0 
						END IF 
						IF pr_summary.disc_amt IS NULL THEN 
							LET pr_summary.disc_amt = 0 
						END IF 
						IF pr_summary.unit_sale_amt IS NULL THEN 
							LET pr_summary.unit_sale_amt = 0 
						END IF 
						IF pr_summary.ext_sale_amt IS NULL THEN 
							LET pr_summary.ext_sale_amt = 0 
						END IF 
						IF pr_summary.unit_tax_amt IS NULL THEN 
							LET pr_summary.unit_tax_amt = 0 
						END IF 
						IF pr_summary.ext_tax_amt IS NULL THEN 
							LET pr_summary.ext_tax_amt = 0 
						END IF 
						IF pr_summary.line_total_amt IS NULL THEN 
							LET pr_summary.line_total_amt = 0 
						END IF 
						IF pr_summary.ship_qty IS NULL THEN 
							LET pr_summary.ship_qty = 0 
						END IF 
						LET line_num = pa_invd_ins[x].line_num 
					ELSE 
						LET pr_summary.ext_cost_amt = pr_summary.ext_cost_amt + 
						pa_invd_ins[x].ext_cost_amt 
						LET pr_summary.disc_amt = pr_summary.disc_amt + 
						pa_invd_ins[x].disc_amt 
						LET pr_summary.ext_sale_amt = pr_summary.ext_sale_amt + 
						pa_invd_ins[x].ext_sale_amt 
						LET pr_summary.ext_tax_amt = pr_summary.ext_tax_amt + 
						pa_invd_ins[x].ext_tax_amt 
						LET pr_summary.line_total_amt = pr_summary.line_total_amt + 
						pa_invd_ins[x].line_total_amt 
						LET pr_summary.ship_qty = pr_summary.ship_qty + 
						pa_invd_ins[x].ship_qty 
						IF pr_summary.activity_code IS NULL THEN 
							LET pr_summary.activity_code = 
							pa_invd_ins[x].activity_code 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_cost_amt = 
							pr_summary.ext_cost_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_sale_amt = 
							pr_summary.ext_sale_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_sale_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_tax_amt = pr_summary.ext_tax_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_tax_amt = 0 
						END IF 
					END IF 
				WHEN "2" {detailed invoice} 
					LET err_message = "J36 - invoice line addition failed (2)" 
					LET pr_invoicedetl.* = pa_invd_ins[x].* 
					#UPDATE SALES HISTORY TRANS TABLE
					IF pr_invoicehead.org_cust_code IS NULL THEN 
						LET fv_cust_code = pr_invoicehead.cust_code 
					ELSE 
						LET fv_cust_code = pr_invoicehead.org_cust_code 
					END IF 
					#  We need TO convert the new Idetl lines here.
					IF fv_use_currency THEN 
						LET pr_invoicedetl.ext_cost_amt = 
						pr_invoicedetl.ext_cost_amt * fv_xchange 
						LET pr_invoicedetl.ext_sale_amt = 
						pr_invoicedetl.ext_sale_amt * fv_xchange 
						LET pr_invoicedetl.ext_tax_amt = 
						pr_invoicedetl.ext_tax_amt * fv_xchange 
						LET pr_invoicedetl.disc_amt = 
						pr_invoicedetl.disc_amt * fv_xchange 
						LET pr_invoicedetl.unit_sale_amt = 
						pr_invoicedetl.unit_sale_amt * fv_xchange 
						LET pr_invoicedetl.line_total_amt = 
						pr_invoicedetl.line_total_amt * fv_xchange 
						LET pr_invoicedetl.unit_tax_amt = 
						pr_invoicedetl.unit_tax_amt * fv_xchange 
						LET pr_invoicedetl.unit_cost_amt = 
						pr_invoicedetl.unit_cost_amt * fv_xchange 
						LET pr_invoicedetl.comm_amt = 
						pr_invoicedetl.comm_amt * fv_xchange 
						LET pr_invoicedetl.ext_bonus_amt = 
						pr_invoicedetl.ext_bonus_amt * fv_xchange 
						LET pr_invoicedetl.ext_stats_amt = 
						pr_invoicedetl.ext_stats_amt * fv_xchange 
						LET pr_invoicedetl.list_price_amt = 
						pr_invoicedetl.list_price_amt * fv_xchange 
					END IF 
					CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
					"I", 
					fv_cust_code, 
					pr_invoicedetl.cat_code, 
					pr_invoicedetl.part_code, 
					pr_invoicedetl.line_text, 
					pr_invoicedetl.ware_code, 
					pr_invoicehead.sale_code, 
					pr_invoicehead.acct_override_code, 
					pr_invoicehead.year_num, 
					pr_invoicehead.period_num, 
					pr_invoicedetl.ship_qty, 
					pr_invoicehead.conv_qty, 
					pr_invoicedetl.ext_cost_amt, 
					pr_invoicedetl.ext_sale_amt, 
					pr_invoicedetl.ext_tax_amt, 
					pr_invoicedetl.disc_amt) 

					INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
					LET inv2 = true 

				WHEN "3" {summary invoice with full description} 
					IF line_num != pa_invd_ins[x].line_num THEN 
						# on change of line number we have a new activity
						# so we INSERT the summary of the previous activity
						# AND SET up the next one
						IF line_num != 0 THEN 
							LET err_message = 
							"J36 - invoice line addition failed (3)" 
							LET pr_invoicedetl.* = pr_summary.* 
							#UPDATE SALES HISTORY TRANS TABLE
							IF pr_invoicehead.org_cust_code IS NULL THEN 
								LET fv_cust_code = pr_invoicehead.cust_code 
							ELSE 
								LET fv_cust_code = pr_invoicehead.org_cust_code 
							END IF 
							# We need TO convert the new Idetl lines here.
							IF fv_use_currency THEN 
								LET pr_invoicedetl.ext_cost_amt = 
								pr_invoicedetl.ext_cost_amt * fv_xchange 
								LET pr_invoicedetl.ext_sale_amt = 
								pr_invoicedetl.ext_sale_amt * fv_xchange 
								LET pr_invoicedetl.ext_tax_amt = 
								pr_invoicedetl.ext_tax_amt * fv_xchange 
								LET pr_invoicedetl.disc_amt = 
								pr_invoicedetl.disc_amt * fv_xchange 
								LET pr_invoicedetl.unit_sale_amt = 
								pr_invoicedetl.unit_sale_amt * fv_xchange 
								LET pr_invoicedetl.line_total_amt = 
								pr_invoicedetl.line_total_amt * fv_xchange 
								LET pr_invoicedetl.unit_tax_amt = 
								pr_invoicedetl.unit_tax_amt * fv_xchange 
								LET pr_invoicedetl.unit_cost_amt = 
								pr_invoicedetl.unit_cost_amt * fv_xchange 
								LET pr_invoicedetl.comm_amt = 
								pr_invoicedetl.comm_amt * fv_xchange 
								LET pr_invoicedetl.ext_bonus_amt = 
								pr_invoicedetl.ext_bonus_amt * fv_xchange 
								LET pr_invoicedetl.ext_stats_amt = 
								pr_invoicedetl.ext_stats_amt * fv_xchange 
								LET pr_invoicedetl.list_price_amt = 
								pr_invoicedetl.list_price_amt * fv_xchange 
							END IF 
							LET err_message = 
							"J36 - Update Sales Trans failed (3)" 
							CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
							"I", 
							fv_cust_code, 
							pr_invoicedetl.cat_code, 
							pr_invoicedetl.part_code, 
							pr_invoicedetl.line_text, 
							pr_invoicedetl.ware_code, 
							pr_invoicehead.sale_code, 
							pr_invoicehead.acct_override_code, 
							pr_invoicehead.year_num, 
							pr_invoicehead.period_num, 
							pr_invoicedetl.ship_qty, 
							pr_invoicehead.conv_qty, 
							pr_invoicedetl.ext_cost_amt, 
							pr_invoicedetl.ext_sale_amt, 
							pr_invoicedetl.ext_tax_amt, 
							pr_invoicedetl.disc_amt) 
							LET err_message = 
							"J36 - invoice line addition failed2 (3)" 

							INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
							LET inv1 = true 
						END IF 
						LET pr_summary.* = pa_invd_ins[x].* 
						LET pr_summary.jobledger_seq_num = 0 
						IF pr_summary.unit_cost_amt IS NULL THEN 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ext_cost_amt IS NULL THEN 
							LET pr_summary.ext_cost_amt = 0 
						END IF 
						IF pr_summary.disc_amt IS NULL THEN 
							LET pr_summary.disc_amt = 0 
						END IF 
						IF pr_summary.unit_sale_amt IS NULL THEN 
							LET pr_summary.unit_sale_amt = 0 
						END IF 
						IF pr_summary.ext_sale_amt IS NULL THEN 
							LET pr_summary.ext_sale_amt = 0 
						END IF 
						IF pr_summary.unit_tax_amt IS NULL THEN 
							LET pr_summary.unit_tax_amt = 0 
						END IF 
						IF pr_summary.ext_tax_amt IS NULL THEN 
							LET pr_summary.ext_tax_amt = 0 
						END IF 
						IF pr_summary.line_total_amt IS NULL THEN 
							LET pr_summary.line_total_amt = 0 
						END IF 
						IF pr_summary.ship_qty IS NULL THEN 
							LET pr_summary.ship_qty = 0 
						END IF 
						LET line_num = pa_invd_ins[x].line_num 
					ELSE 
						LET pr_summary.ext_cost_amt = pr_summary.ext_cost_amt + 
						pa_invd_ins[x].ext_cost_amt 
						LET pr_summary.disc_amt = pr_summary.disc_amt + 
						pa_invd_ins[x].disc_amt 
						LET pr_summary.ext_sale_amt = pr_summary.ext_sale_amt + 
						pa_invd_ins[x].ext_sale_amt 
						LET pr_summary.ext_tax_amt = pr_summary.ext_tax_amt + 
						pa_invd_ins[x].ext_tax_amt 
						LET pr_summary.line_total_amt = pr_summary.line_total_amt + 
						pa_invd_ins[x].line_total_amt 
						LET pr_summary.ship_qty = pr_summary.ship_qty + 
						pa_invd_ins[x].ship_qty 
						IF pr_summary.activity_code IS NULL THEN 
							LET pr_summary.activity_code = 
							pa_invd_ins[x].activity_code 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_cost_amt = 
							pr_summary.ext_cost_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_sale_amt = 
							pr_summary.ext_sale_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_sale_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_tax_amt = pr_summary.ext_tax_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_tax_amt = 0 
						END IF 
					END IF 
				WHEN "4" {detailed invoice with full description} 
					LET err_message = "J36 - invoice line addition failed (4)" 
					LET pr_invoicedetl.* = pa_invd_ins[x].* 
					#UPDATE SALES HISTORY TRANS TABLE
					IF pr_invoicehead.org_cust_code IS NULL THEN 
						LET fv_cust_code = pr_invoicehead.cust_code 
					ELSE 
						LET fv_cust_code = pr_invoicehead.org_cust_code 
					END IF 
					# We need TO convert the new Idetl lines here.
					IF fv_use_currency THEN 
						LET pr_invoicedetl.ext_cost_amt = 
						pr_invoicedetl.ext_cost_amt * fv_xchange 
						LET pr_invoicedetl.ext_sale_amt = 
						pr_invoicedetl.ext_sale_amt * fv_xchange 
						LET pr_invoicedetl.ext_tax_amt = 
						pr_invoicedetl.ext_tax_amt * fv_xchange 
						LET pr_invoicedetl.disc_amt = 
						pr_invoicedetl.disc_amt * fv_xchange 
						LET pr_invoicedetl.unit_sale_amt = 
						pr_invoicedetl.unit_sale_amt * fv_xchange 
						LET pr_invoicedetl.line_total_amt = 
						pr_invoicedetl.line_total_amt * fv_xchange 
						LET pr_invoicedetl.unit_tax_amt = 
						pr_invoicedetl.unit_tax_amt * fv_xchange 
						LET pr_invoicedetl.unit_cost_amt = 
						pr_invoicedetl.unit_cost_amt * fv_xchange 
						LET pr_invoicedetl.comm_amt = 
						pr_invoicedetl.comm_amt * fv_xchange 
						LET pr_invoicedetl.ext_bonus_amt = 
						pr_invoicedetl.ext_bonus_amt * fv_xchange 
						LET pr_invoicedetl.ext_stats_amt = 
						pr_invoicedetl.ext_stats_amt * fv_xchange 
						LET pr_invoicedetl.list_price_amt = 
						pr_invoicedetl.list_price_amt * fv_xchange 
					END IF 
					CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
					"I", 
					fv_cust_code, 
					pr_invoicedetl.cat_code, 
					pr_invoicedetl.part_code, 
					pr_invoicedetl.line_text, 
					pr_invoicedetl.ware_code, 
					pr_invoicehead.sale_code, 
					pr_invoicehead.acct_override_code, 
					pr_invoicehead.year_num, 
					pr_invoicehead.period_num, 
					pr_invoicedetl.ship_qty, 
					pr_invoicehead.conv_qty, 
					pr_invoicedetl.ext_cost_amt, 
					pr_invoicedetl.ext_sale_amt, 
					pr_invoicedetl.ext_tax_amt, 
					pr_invoicedetl.disc_amt) 

					INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
					LET inv2 = true 

			END CASE 
			CALL increment_tax(pa_invd_ins[x].*) 
		END FOR 

		IF (pr_invoicehead.bill_issue_ind = "1" OR 
		pr_invoicehead.bill_issue_ind = "3") AND 
		pr_inv_line_num > 0 THEN 
			LET err_message = "J36 - invoice line addition failed (3)" 
			LET pr_invoicedetl.* = pr_summary.* 
			# UPDATE SALES HISTORY TRANS TABLE
			IF pr_invoicehead.org_cust_code IS NULL THEN 
				LET fv_cust_code = pr_invoicehead.cust_code 
			ELSE 
				LET fv_cust_code = pr_invoicehead.org_cust_code 
			END IF 
			#  We need TO convert the new Idetl lines here.
			IF fv_use_currency THEN 
				LET pr_invoicedetl.ext_cost_amt = 
				pr_invoicedetl.ext_cost_amt * fv_xchange 
				LET pr_invoicedetl.ext_sale_amt = 
				pr_invoicedetl.ext_sale_amt * fv_xchange 
				LET pr_invoicedetl.ext_tax_amt = 
				pr_invoicedetl.ext_tax_amt * fv_xchange 
				LET pr_invoicedetl.disc_amt = 
				pr_invoicedetl.disc_amt * fv_xchange 
				LET pr_invoicedetl.unit_sale_amt = 
				pr_invoicedetl.unit_sale_amt * fv_xchange 
				LET pr_invoicedetl.line_total_amt = 
				pr_invoicedetl.line_total_amt * fv_xchange 
				LET pr_invoicedetl.unit_tax_amt = 
				pr_invoicedetl.unit_tax_amt * fv_xchange 
				LET pr_invoicedetl.unit_cost_amt = 
				pr_invoicedetl.unit_cost_amt * fv_xchange 
				LET pr_invoicedetl.comm_amt = 
				pr_invoicedetl.comm_amt * fv_xchange 
				LET pr_invoicedetl.ext_bonus_amt = 
				pr_invoicedetl.ext_bonus_amt * fv_xchange 
				LET pr_invoicedetl.ext_stats_amt = 
				pr_invoicedetl.ext_stats_amt * fv_xchange 
				LET pr_invoicedetl.list_price_amt = 
				pr_invoicedetl.list_price_amt * fv_xchange 
			END IF 
			LET err_message = "J36 - Update sales trans2 failed (3)" 
			CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, 
			"I", 
			fv_cust_code, 
			pr_invoicedetl.cat_code, 
			pr_invoicedetl.part_code, 
			pr_invoicedetl.line_text, 
			pr_invoicedetl.ware_code, 
			pr_invoicehead.sale_code, 
			pr_invoicehead.acct_override_code, 
			pr_invoicehead.year_num, 
			pr_invoicehead.period_num, 
			pr_invoicedetl.ship_qty, 
			pr_invoicehead.conv_qty, 
			pr_invoicedetl.ext_cost_amt, 
			pr_invoicedetl.ext_sale_amt, 
			pr_invoicedetl.ext_tax_amt, 
			pr_invoicedetl.disc_amt) 

			LET err_message = "J36 - invoice line addition2 failed (3)" 
			INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
			LET inv1 = true 
		END IF 
		# Freight AND Handling tax
		IF pr_invoicehead.freight_amt IS NULL THEN 
			LET pr_invoicehead.freight_amt = 0 
		END IF 
		IF pr_invoicehead.hand_amt IS NULL THEN 
			LET pr_invoicehead.hand_amt = 0 
		END IF 

		IF fr_tax_per IS NULL THEN LET fr_tax_per = 0 END IF 
			IF la_tax_per IS NULL THEN LET la_tax_per = 0 END IF 






				LET total_pay_amt = total_pay_amt + pr_invoicehead.hand_amt 
				+ pr_invoicehead.freight_amt 
				+ pr_invoicehead.hand_tax_amt 
				+ pr_invoicehead.freight_tax_amt 

				IF (total_tax != pr_invoicehead.tax_amt OR total_tax IS NULL 
				OR pr_invoicehead.tax_amt IS null) THEN 
					ERROR " Audit on tax figures NOT correct" 
					SLEEP 2 
					CALL display_error() 
					SLEEP 5 
					EXIT program 
				END IF 
				IF total_amt != pr_invoicehead.goods_amt OR total_amt IS NULL 
				OR pr_invoicehead.goods_amt IS NULL THEN 
					ERROR "Audit on material figures NOT correct" 
					SLEEP 2 
					CALL errorlog("J36 - material total amount incorrect") 
					CALL display_error() 
					SLEEP 5 
					EXIT program 
				END IF 
				IF (total_costs != pr_invoicehead.cost_amt OR total_costs IS NULL 
				OR pr_invoicehead.cost_amt IS null) THEN 
					ERROR "Audit on cost figures NOT correct" 
					SLEEP 2 
					CALL errorlog("J36 - material total cost incorrect") 
					CALL display_error() 
					SLEEP 5 
					EXIT program 
				END IF 
				IF total_pay_amt != pr_invoicehead.total_amt THEN 
					ERROR "Audit on total amount figures NOT correct" 
					SLEEP 2 
					CALL errorlog("J36 - invoice total amount incorrect") 
					CALL display_error() 
					SLEEP 5 
					EXIT program 
				END IF 
				LET err_message = "J36 - Unable TO add TO invoice header table" 
				LET pr_invoicehead.line_num = pr_inv_line_num 
				LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 
				LET pr_invoicehead.acct_override_code = pr_job.acct_code 

				# Delete invoicehead THEN re-add

				DELETE FROM invoicehead WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = pr_invoicehead.cust_code 
				AND inv_num = pr_invoicehead.inv_num 

				# Invoicehead Insert

				# convert invoiceheader details BEFORE INSERT
				IF fv_use_currency THEN 
					LET pr_invoicehead.goods_amt = pr_invoicehead.goods_amt * fv_xchange 
					LET pr_invoicehead.hand_amt = pr_invoicehead.hand_amt * fv_xchange 
					LET pr_invoicehead.hand_tax_amt = 
					pr_invoicehead.hand_tax_amt * fv_xchange 
					LET pr_invoicehead.freight_amt = pr_invoicehead.freight_amt * fv_xchange 
					LET pr_invoicehead.freight_tax_amt = 
					pr_invoicehead.freight_tax_amt * fv_xchange 
					LET pr_invoicehead.tax_amt = pr_invoicehead.tax_amt * fv_xchange 
					LET pr_invoicehead.disc_amt = pr_invoicehead.disc_amt * fv_xchange 
					LET pr_invoicehead.total_amt = pr_invoicehead.total_amt * fv_xchange 
					LET pr_invoicehead.cost_amt = pr_invoicehead.cost_amt * fv_xchange 
					LET pr_invoicehead.paid_amt = pr_invoicehead.paid_amt * fv_xchange 
					LET pr_invoicehead.disc_taken_amt = 
					pr_invoicehead.disc_taken_amt * fv_xchange 
				END IF 
				LET err_message = "J36f - INSERT INTO invoicehead failed" 
				INSERT INTO invoicehead VALUES (pr_invoicehead.*) 
				# Contractdate UPDATE
				IF pr_invoicehead.contract_code IS NOT NULL THEN 
					UPDATE contractdate 
					SET invoice_total_amt = pr_invoicehead.total_amt 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND contract_code = pr_invoicehead.contract_code 
					AND inv_num = pr_invoicehead.inv_num 
				END IF 
				SELECT sum(ext_cost_amt), 
				sum(ext_sale_amt) 
				INTO test_cost, 
				test_sale 
				FROM invoicedetl 
				WHERE cmpy_code = pr_invoicehead.cmpy_code 
				AND cust_code = pr_invoicehead.cust_code 
				AND inv_num = pr_invoicehead.inv_num 
				IF test_cost != pr_invoicehead.cost_amt THEN 
					ERROR "Invoice imbalance between Header AND Lines" 
					SLEEP 10 
					ERROR "Invoice will be aborted" 
					SLEEP 2 
					ROLLBACK WORK 
				END IF 
				# IF blank invoice created rollback AND SET
				# glob_password TO be BLKINV
				IF NOT inv1 AND NOT inv2 THEN 
					ROLLBACK WORK 
					LET glob_password = "BLKINV" 
				ELSE 
				COMMIT WORK 
			END IF 
			WHENEVER ERROR stop 
END FUNCTION 

FUNCTION increment_tax(fr_invd_ins) 
	DEFINE 
	fr_invd_ins RECORD LIKE invoicedetl.* 
	IF fr_invd_ins.ext_tax_amt IS NULL THEN 
		LET fr_invd_ins.ext_tax_amt = 0 
	END IF 

	LET total_tax = total_tax + fr_invd_ins.ext_tax_amt 
	LET total_pay_amt = total_pay_amt + fr_invd_ins.ext_tax_amt 
END FUNCTION 

FUNCTION increment_totals() 
	LET total_amt = total_amt + pa_invd_ins[pr_inv_line_num].ext_sale_amt 
	LET total_pay_amt = total_pay_amt + 
	pa_invd_ins[pr_inv_line_num].line_total_amt 
	- pa_invd_ins[pr_inv_line_num].ext_tax_amt 
	LET total_costs = total_costs + pa_invd_ins[pr_inv_line_num].ext_cost_amt 
END FUNCTION 

FUNCTION fix_nulls() 
	IF pa_invd_ins[pr_inv_line_num].ext_tax_amt IS NULL THEN 
		LET pa_invd_ins[pr_inv_line_num].ext_tax_amt = 0 
	END IF 
	IF pa_invd_ins[pr_inv_line_num].ext_sale_amt IS NULL THEN 
		LET pa_invd_ins[pr_inv_line_num].ext_sale_amt = 0 
	END IF 
	IF pa_invd_ins[pr_inv_line_num].line_total_amt IS NULL THEN 
		LET pa_invd_ins[pr_inv_line_num].line_total_amt = 0 
	END IF 
	IF pa_invd_ins[pr_inv_line_num].ext_cost_amt IS NULL THEN 
		LET pa_invd_ins[pr_inv_line_num].ext_cost_amt = 0 
	END IF 
END FUNCTION 

FUNCTION display_error() 
	CLEAR screen 
	DISPLAY "Error occurred" at 2,3 
	DISPLAY "Invoice Total ",pr_invoicehead.total_amt at 3,3 
	DISPLAY "Check Amt", total_pay_amt at 4,3 
	DISPLAY "Invoice Tax ",pr_invoicehead.tax_amt at 5,3 
	DISPLAY "Check Tax", total_tax at 6,3 
	DISPLAY "Invoice Materials ", pr_invoicehead.goods_amt at 7,3 
	DISPLAY "Check Materials", total_amt at 8,3 
	DISPLAY "Invoice Costs ", pr_invoicehead.cost_amt at 9,3 
	DISPLAY "Check Costs", total_costs at 10,3 
	SLEEP 15 
END FUNCTION 

FUNCTION reverse_resbill(pr_tempbill) 
	DEFINE 
	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date DATE, 
		var_code SMALLINT, 
		activity_code CHAR(8), 
		seq_num INTEGER, 
		line_num SMALLINT, 
		trans_type_ind CHAR(2), 
		trans_source_num INTEGER, 
		trans_source_text CHAR(8), 
		trans_amt money(16,2), 
		trans_qty DECIMAL(15,3), 
		charge_amt money(16,2), 
		apply_qty DECIMAL(15,3), # application this invoice line 
		apply_amt DECIMAL(16,2), 
		apply_cos_amt DECIMAL(16,2), 
		desc_text CHAR(40), 
		prev_apply_qty DECIMAL(15,3), # applys FROM prev inv's 
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_resbill RECORD LIKE resbill.* 
	LET err_message = "J36 - Insert Resbill Rows" 
	LET pr_resbill.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_resbill.job_code = pr_job.job_code 
	LET pr_resbill.var_code = pr_tempbill.var_code 
	LET pr_resbill.activity_code = pr_tempbill.activity_code 
	LET pr_resbill.res_code = pr_tempbill.trans_source_text 
	LET pr_resbill.seq_num = pr_tempbill.seq_num 
	LET pr_resbill.inv_num = pr_invoicehead.inv_num 
	LET pr_resbill.line_num = pr_tempbill.line_num 
	LET pr_resbill.desc_text = pr_tempbill.desc_text 
	LET pr_resbill.tran_date = pr_invoicehead.inv_date 
	LET pr_resbill.tran_type_ind = "1" 
	LET pr_resbill.orig_inv_num = NULL 
	# Get the editbill line AND adjust the amounts AND quantities
	# TO reflect the edit part only
	SELECT * 
	INTO pr_editbill.* 
	FROM editbill 
	WHERE var_code = pr_tempbill.var_code 
	AND activity_code = pr_tempbill.activity_code 
	AND seq_num = pr_tempbill.seq_num 
	IF NOT status THEN 
		IF pr_editbill.trans_invoice_flag = "*" THEN 
			# this line was in previous invoice therefore has a resbill
			# RECORD which will now be reversed
			LET pr_resbill.apply_qty = (0 - pr_editbill.apply_qty) 
			LET pr_resbill.apply_amt = (0 - pr_editbill.apply_amt) 
			LET pr_resbill.apply_cos_amt = (0 - pr_editbill.apply_cos_amt) 
		END IF 
		IF pr_editbill.trans_invoice_flag IS NULL THEN 
			# this line was NOT being invoiced AT all previously
			# therefore it does NOT need TO be reversed FROM resbill
			RETURN 
		END IF 
	ELSE 
		# no editbill RECORD (this should NOT happen)
		ERROR "I cannot find the edit RECORD FOR a billing line" 
		SLEEP 2 
		ERROR "Please tell system administrator - Ref : Resbill Reverse" 
		SLEEP 5 
		RETURN 
	END IF 
	INSERT INTO resbill VALUES (pr_resbill.*) 

END FUNCTION 

FUNCTION write_resbill(pr_tempbill, pr_resbill_line_num) 
	DEFINE 
	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date DATE, 
		var_code SMALLINT, 
		activity_code CHAR(8), 
		seq_num INTEGER, 
		line_num SMALLINT, 
		trans_type_ind CHAR(2), 
		trans_source_num INTEGER, 
		trans_source_text CHAR(8), 
		trans_amt money(16,2), 
		trans_qty DECIMAL(15,3), 
		charge_amt money(16,2), 
		apply_qty DECIMAL(15,3), # application this invoice line 
		apply_amt DECIMAL(16,2), 
		apply_cos_amt DECIMAL(16,2), 
		desc_text CHAR(40), 
		prev_apply_qty DECIMAL(15,3), # applys FROM prev inv's 
		prev_apply_amt DECIMAL(16,2), 
		prev_apply_cos_amt DECIMAL(16,2), 
		allocation_ind LIKE jobledger.allocation_ind 
	END RECORD, 
	pr_resbill RECORD LIKE resbill.*, 
	pr_resbill_line_num SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	LET err_message = "J36 - Insert Resbill Rows" 
	LET pr_resbill.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pr_resbill.job_code = pr_job.job_code 
	LET pr_resbill.var_code = pr_tempbill.var_code 
	LET pr_resbill.activity_code = pr_tempbill.activity_code 
	LET pr_resbill.res_code = pr_tempbill.trans_source_text 
	LET pr_resbill.seq_num = pr_tempbill.seq_num 
	LET pr_resbill.inv_num = pr_invoicehead.inv_num 
	LET pr_resbill.line_num = pr_resbill_line_num 
	LET pr_resbill.apply_qty = pr_tempbill.apply_qty 
	LET pr_resbill.apply_amt = pr_tempbill.apply_amt 
	LET pr_resbill.apply_cos_amt = pr_tempbill.apply_cos_amt 
	LET pr_resbill.desc_text = pr_tempbill.desc_text 
	LET pr_resbill.tran_type_ind = "1" 
	LET pr_resbill.tran_date = pr_invoicehead.inv_date 
	LET pr_resbill.orig_inv_num = NULL 
	INSERT INTO resbill VALUES (pr_resbill.*) 
END FUNCTION 
