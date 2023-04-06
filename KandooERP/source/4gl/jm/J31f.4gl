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

	Source code beautified by beautify.pl on 2020-01-02 19:48:04	$Id: $
}




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - J31f - Update tables FROM JM Invoicing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "J31_GLOBALS.4gl" 

DEFINE 
test_cost DECIMAL(10, 2), 
test_sale DECIMAL(10, 2), 
inv1, 
inv2, 
inv3, 
inv4 SMALLINT, 
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
		trans_amt money(16, 2), 
		trans_qty DECIMAL(15, 3), 
		charge_amt money(16, 2), 
		apply_qty DECIMAL(15, 3), 
		apply_amt DECIMAL(16, 2), 
		apply_cos_amt DECIMAL(16, 2), 
		desc_text CHAR(40), 
		prev_apply_qty DECIMAL(15, 3), 
		prev_apply_amt DECIMAL(16, 2), 
		prev_apply_cos_amt DECIMAL(16, 2), 
		allocation_ind LIKE jobledger.allocation_ind, 
		goods_rec_num LIKE jobledger.ref_num, 
		part_code LIKE purchdetl.ref_text, 
		serial_flag LIKE product.serial_flag, 
		stored_qty LIKE resbill.apply_qty 
	END RECORD, 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_sav_invdetl RECORD LIKE invoicedetl.*, 
	pa_invd_chk ARRAY [3000] OF RECORD 
		trans_type_ind CHAR(2), 
		trans_source_text CHAR(8) 
	END RECORD, 
	pa_invd_bill_way_ind ARRAY [3000] OF RECORD 
		bill_way_ind LIKE activity.bill_way_ind 
	END RECORD, 
	line_num LIKE invoicedetl.line_num, 
	fv_cust_code LIKE saleshist.cust_code, 
	pr_araudit RECORD LIKE araudit.*, 
	idx, 
	cnt SMALLINT, 
	note_idx SMALLINT, 
	fr_tax_per DECIMAL(5, 3), 
	la_tax_per DECIMAL(5, 3), 
	tmp_bill_qty LIKE resbill.apply_qty, 
	lock_table_ind CHAR(1), 
	fv_cust_currency LIKE customer.currency_code, 
	fv_base_currency LIKE glparms.base_currency_code, 
	fv_xchange LIKE rate_exchange.conv_buy_qty, 
	fv_use_currency SMALLINT 
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
	GOTO bypass 

	LABEL recovery: 
	LET err_continue = error_recover(err_message, status) 
	IF err_continue != "Y" THEN 
		EXIT program 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		# get tailoring option TO determine whether OR NOT TO lock tables
		LET lock_table_ind = get_kandoooption_feature_state("JM", "01") 
		IF lock_table_ind matches "[Y]" THEN 
			LOCK TABLE activity in share MODE 
			LOCK TABLE invoicedetl in share MODE 
		END IF 
		LET pr_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_INVOICE_IN, pr_job.acct_code) 
		IF pr_invoicehead.inv_num < 0 THEN 
			LET err_message = "J31 - JM invoice number UPDATE " 
			LET status = pr_invoicehead.inv_num 
			GOTO recovery 
		END IF 
		# Invoice currency conversion. We need TO change all money VALUES
		# over TO the customers currency code, AND also get the xchange
		# rate FROM the rate_exchange table.
		SELECT customer.currency_code, 
		rate_exchange.conv_buy_qty INTO fv_cust_currency, 
		fv_xchange 
		FROM customer, 
		rate_exchange 
		WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rate_exchange.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customer.cust_code = pr_invoicehead.cust_code 
		AND customer.currency_code = rate_exchange.currency_code 
		AND rate_exchange.start_date = ( 
		SELECT max(rate_exchange.start_date) 
		FROM rate_exchange 
		WHERE rate_exchange.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customer.currency_code = rate_exchange.currency_code 
		AND rate_exchange.start_date <= today) 
		LET fv_xchange = pr_invoicehead.conv_qty 
		SELECT glparms.base_currency_code INTO fv_base_currency 
		FROM glparms 
		WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND glparms.key_code = "1" 
		LET fv_use_currency = false 
		IF fv_base_currency <> fv_cust_currency THEN 
			LET fv_use_currency = true 
			LET pr_invoicehead.conv_qty = fv_xchange 
		END IF 
		# I convert the invoice total here so we can UPDATE the customer balance
		# with the correct amount. All other money VALUES are converted just
		# before the INSERT INTO the relevant tables. (ie. idetl AND ihead)

		# Customer table UPDATE

		LET err_message = "J31 - Customer Update SELECT" 
		DECLARE cm1_curs CURSOR FOR 
		SELECT * INTO pr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code 
		FOR UPDATE 
		OPEN cm1_curs 
		FETCH cm1_curs 
		LET err_message = "J31 - Customer Rows Updated " 
		LET pr_customer.next_seq_num = pr_customer.next_seq_num + 1 
		# Use foreign currency FOR customer details
		LET pr_customer.bal_amt = pr_customer.bal_amt + (pr_invoicehead.total_amt 
		* fv_xchange) 
		LET pr_customer.curr_amt = pr_customer.curr_amt + ( 
		pr_invoicehead.total_amt * fv_xchange) 





		IF (pr_customer.bal_amt > pr_customer.highest_bal_amt) THEN 
			LET pr_customer.highest_bal_amt = pr_customer.bal_amt 
		END IF 
		LET pr_customer.cred_bal_amt = pr_customer.cred_limit_amt - ( 
		pr_customer.bal_amt + pr_customer.onorder_amt ) 
		IF year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date) THEN 
			LET pr_customer.ytds_amt = 0 
		END IF 
		#  Use FC amount
		LET pr_customer.ytds_amt = pr_customer.ytds_amt + ( 
		pr_invoicehead.total_amt * fv_xchange) 


		IF (month(pr_invoicehead.inv_date) > month(pr_customer.last_inv_date) 
		OR year(pr_invoicehead.inv_date) > year(pr_customer.last_inv_date)) THEN 
			LET pr_customer.mtds_amt = 0 
		END IF 
		#  Use FC amounts
		LET pr_customer.mtds_amt = pr_customer.mtds_amt + ( 
		pr_invoicehead.total_amt * fv_xchange) 



		IF pr_invoicehead.inv_date > pr_customer.last_inv_date THEN #2227 
			LET pr_customer.last_inv_date = pr_invoicehead.inv_date 
		END IF 
		LET err_message = "J31 - Customer Table Actual Update " 
		UPDATE customer 
		SET next_seq_num = pr_customer.next_seq_num, 
		bal_amt = pr_customer.bal_amt, 
		curr_amt = pr_customer.curr_amt, 
		highest_bal_amt = pr_customer.highest_bal_amt , 
		cred_bal_amt = pr_customer.cred_bal_amt , 
		last_inv_date = pr_customer.last_inv_date, 
		ytds_amt = pr_customer.ytds_amt, 
		mtds_amt = pr_customer.mtds_amt 
		WHERE 
		CURRENT OF cm1_curs 
		CLOSE cm1_curs 

		# Araudit INSERT

		LET err_message = "J31 - Unable TO add TO AR log table " 
		LET pr_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET pr_araudit.tran_date = pr_invoicehead.inv_date 
		LET pr_araudit.cust_code = pr_invoicehead.cust_code 
		LET pr_araudit.seq_num = pr_customer.next_seq_num 
		LET pr_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET pr_araudit.source_num = pr_invoicehead.inv_num 
		LET pr_araudit.tran_text = "Enter Invoice" 
		#  Use FC amount
		LET pr_araudit.tran_amt = (pr_invoicehead.total_amt * fv_xchange) 


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

				# Activity UPDATE

				LET err_message = "J31 - Activity SELECT failed" 
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
				LET err_message = "J31 - Activity Actual Update" 
				#Set activity start date
				CALL set_start(pr_activity.job_code, pr_invoicehead.inv_date) 
				IF pr_activity.act_start_date IS NULL 
				OR pr_activity.act_start_date > pr_invoicehead.inv_date THEN 
					# FOR recurring jobs we NEVER accumulate the bill qty
					# instead we SET TO the qty on jobledger cos they
					# can't amend this anyway
					IF pr_job.bill_way_ind = "R" THEN 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pa_inv_line[ cnt ].this_bill_amt , 
						post_cost_amt = pr_activity.post_cost_amt + 
						pa_inv_line[cnt].this_cos_amt , 
						act_bill_qty = pa_inv_line[ cnt ].this_bill_qty , 
						act_start_date = pr_invoicehead.inv_date 
						WHERE CURRENT OF upd_act 
					ELSE 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pa_inv_line[ cnt ].this_bill_amt , 
						post_cost_amt = pr_activity.post_cost_amt + 
						pa_inv_line[cnt].this_cos_amt , 
						act_bill_qty = pr_activity.act_bill_qty 
						+ pa_inv_line[cnt].this_bill_qty, 
						act_start_date = pr_invoicehead.inv_date 
						WHERE CURRENT OF upd_act 
					END IF 
				ELSE 
					# FOR recurring jobs we NEVER accumulate the bill qty
					# instead we SET TO the qty on jobledger cos they
					# can't amend this anyway
					IF pr_job.bill_way_ind = "R" THEN 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pa_inv_line[ cnt ].this_bill_amt , 
						post_cost_amt = pr_activity.post_cost_amt + 
						pa_inv_line[cnt].this_cos_amt , 
						act_bill_qty = pa_inv_line[ cnt ].this_bill_qty 
						WHERE CURRENT OF upd_act 
					ELSE 
						UPDATE activity 
						SET act_bill_amt = pr_activity.act_bill_amt + 
						pa_inv_line[ cnt ].this_bill_amt , 
						post_cost_amt = pr_activity.post_cost_amt + 
						pa_inv_line[cnt].this_cos_amt , 
						act_bill_qty = pr_activity.act_bill_qty 
						+ pa_inv_line[cnt].this_bill_qty 
						WHERE CURRENT OF upd_act 
					END IF 
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
					pa_inv_line [ cnt].bill_way_ind 
					LET pa_invd_ins[pr_inv_line_num].* = pa_invoicedetl[cnt].* 
					LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 
					CALL fix_nulls() 
					LET pa_invd_ins[pr_inv_line_num].inv_num = pr_invoicehead.inv_num 
					LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 
					pa_invd_ins[ pr_inv_line_num ].ext_cost_amt 
					LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 
					pa_invd_ins[ pr_inv_line_num ].ext_sale_amt 
					LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
					LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 
					CALL increment_totals() 
				ELSE 

					# NOT FIXED PRICE JOB

					IF pr_invoicehead.bill_issue_ind IS NULL 

					OR pr_invoicehead.bill_issue_ind NOT matches "[1234]" THEN 

						LET msgresp = kandoomsg("J",8017,0) 
						#ERROR "You have an incorrect bill type, Invoice Aborting"
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
						pa_inv_line [ cnt ].bill_way_ind 
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
					IF pr_invoicedetl.line_text IS NOT NULL 
					AND pr_invoicedetl.line_text != " " THEN 
						LET pa_invd_bill_way_ind[pr_inv_line_num].bill_way_ind = 
						pa_inv_line [ cnt ].bill_way_ind 

						IF pr_invoicehead.bill_issue_ind = "2" OR 
						pr_invoicehead.bill_issue_ind = "4" THEN {detail} 
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
							LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 
						END IF 
						LET pa_invd_ins[pr_inv_line_num].inv_num = pr_invoicehead.inv_num 
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
								pa_invd_ins [ pr_inv_line_num ].ext_cost_amt 
								/ pa_invd_ins[pr_inv_line_num].ship_qty 
								LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 
								pa_invd_ins [ pr_inv_line_num ].ext_sale_amt 
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
						CALL write_resbill(pr_tempbill.*, pa_invd_ins[ 
						pr_inv_line_num ].line_num) 
						#------------------
						#Update serialinfo with invoice number AND customer num
						#Either every serialinfo RECORD FOR the goods receipt
						#OR only those serial numbers selected IF qty differs
						#-------------------
						LET err_message = "J31 - Update Serialinfo - Full" 
						IF pr_tempbill.trans_type_ind = "PU" 
						AND pr_tempbill.serial_flag = "Y" THEN 
							IF pr_tempbill.apply_qty = pr_tempbill.stored_qty THEN 
								UPDATE serialinfo 
								SET ref_num = pr_invoicehead.inv_num, 
								cust_code = pr_invoicehead.cust_code 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pr_tempbill.part_code 
								AND receipt_num = pr_tempbill.goods_rec_num 
								AND ((ref_num = 0 OR ref_num IS null) 
								OR (credit_num != 0 OR credit_num IS NOT null)) 
							ELSE 
								LET err_message = "J31 - Update Serialinfo - Partial" 
								DECLARE c_temp_serial CURSOR FOR 
								SELECT * 
								FROM t_serialinfo 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND part_code = pr_tempbill.part_code 
								FOREACH c_temp_serial INTO pr_serialinfo.* 
									UPDATE serialinfo 
									SET ref_num = pr_invoicehead.inv_num, 
									cust_code = pr_invoicehead.cust_code 
									WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
									AND part_code = pr_serialinfo.part_code 
									AND serial_code = pr_serialinfo.serial_code 
								END FOREACH 
							END IF 
						END IF 
					END FOREACH 
				END IF 
				# note_size IS a count of the total number of note lines
				FOR note_idx = 1 TO note_size 
					IF pa_notes[note_idx].activity_code = pa_inv_line[cnt].activity_code 
					AND pa_notes[note_idx].var_code = pa_inv_line[cnt].var_code THEN 
						LET pr_inv_line_num = pr_inv_line_num + 1 
						LET pa_invd_ins[pr_inv_line_num].* = pa_invoicedetl[cnt].* 
						LET pa_invd_ins[pr_inv_line_num].inv_num = pr_invoicehead.inv_num 
						LET pa_invd_ins[pr_inv_line_num].line_text = 
						pa_notes[ note_idx ].note_code 
						LET pa_invd_ins[pr_inv_line_num].ext_sale_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].line_total_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].ext_cost_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].ship_qty = 0 
						LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 
						LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].unit_tax_amt = 0 
						LET pa_invd_ins[pr_inv_line_num].ext_tax_amt = 0 
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
				x, pa_invd_ins[x].ext_sale_amt, 1, "S", "", "") 
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
			IF pa_invd_ins[x].cust_code IS NULL 
			OR pa_invd_ins[x].cmpy_code IS NULL 
			OR pa_invd_ins[x].inv_num IS NULL 
			OR pa_invd_ins[x].line_num IS NULL THEN 
				CONTINUE FOR 
			END IF 
			IF pa_invd_chk[x].trans_type_ind != "IS" 
			OR pa_invd_chk[x].trans_type_ind IS NULL THEN 





				CALL find_tax(pr_invoicehead.tax_code, 
				pa_invd_chk[x].trans_source_text , 
				pa_invd_ins[x].line_text[16, 18], 
				tot_lines , x, 
				pa_invd_ins[x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", "", "") 
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
			ELSE 
				CALL find_tax(pr_invoicehead.tax_code, 
				pa_invd_ins[x].line_text[1 , 15], 
				pa_invd_ins[x].line_text[16, 18], 
				tot_lines, x, 
				pa_invd_ins [x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", 
				"" , "") 
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
							"J31 - invoice line addition failed (1)" 
							LET pr_invoicedetl.* = pr_summary.* 
							# UPDATE SALES HISTORY TRANS TABLE
							IF pr_invoicehead.org_cust_code IS NULL THEN 
								LET fv_cust_code = pr_invoicehead.cust_code 
							ELSE 
								LET fv_cust_code = pr_invoicehead.org_cust_code 
							END IF 
							#  Convert the detail line amounts here so that the correct VALUES
							#  are used FOR the sales analysis UPDATE.
							IF fv_use_currency THEN 
								LET pr_invoicedetl.ext_cost_amt = 
								pr_invoicedetl.ext_cost_amt * fv_xchange 
								LET pr_invoicedetl.ext_sale_amt = 
								pr_invoicedetl.ext_sale_amt * fv_xchange 
								LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.ext_tax_amt 
								* fv_xchange 
								LET pr_invoicedetl.disc_amt = pr_invoicedetl.disc_amt 
								* fv_xchange 
								LET pr_invoicedetl.unit_sale_amt = 
								pr_invoicedetl.unit_sale_amt * fv_xchange 
								LET pr_invoicedetl.line_total_amt = 
								pr_invoicedetl.line_total_amt * fv_xchange 
								LET pr_invoicedetl.unit_tax_amt = 
								pr_invoicedetl.unit_tax_amt * fv_xchange 
								LET pr_invoicedetl.unit_cost_amt = 
								pr_invoicedetl.unit_cost_amt * fv_xchange 
								LET pr_invoicedetl.comm_amt = pr_invoicedetl.comm_amt 
								* fv_xchange 
								LET pr_invoicedetl.ext_bonus_amt = 
								pr_invoicedetl.ext_bonus_amt * fv_xchange 
								LET pr_invoicedetl.ext_stats_amt = 
								pr_invoicedetl.ext_stats_amt * fv_xchange 
								LET pr_invoicedetl.list_price_amt = 
								pr_invoicedetl.list_price_amt * fv_xchange 
								LET pr_invoicehead.currency_code = fv_cust_currency 
								LET pr_invoicehead.conv_qty = fv_xchange 
							END IF 
							CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "I", fv_cust_code, 
							pr_invoicedetl.cat_code , pr_invoicedetl.part_code, 
							pr_invoicedetl.line_text , pr_invoicedetl.ware_code, 
							pr_invoicehead.sale_code, 
							pr_invoicehead.acct_override_code , 
							pr_invoicehead.year_num , pr_invoicehead.period_num, 
							pr_invoicedetl.ship_qty , pr_invoicehead.conv_qty, 
							pr_invoicedetl.ext_cost_amt , 
							pr_invoicedetl.ext_sale_amt , pr_invoicedetl.ext_tax_amt 
							, pr_invoicedetl.disc_amt) 
							INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
							IF pr_invoicedetl.ext_sale_amt IS NOT NULL 
							AND 
							pr_invoicedetl.ext_sale_amt <> 0 THEN 
								LET inv1 = true 
							END IF 
							IF pr_invoicedetl.ext_cost_amt IS NOT NULL 
							AND 
							pr_invoicedetl.ext_cost_amt <> 0 THEN 
								LET inv1 = true 
							END IF 
							IF pr_invoicedetl.ship_qty IS NOT NULL 
							AND 
							pr_invoicedetl.ship_qty <> 0 THEN 
								LET inv1 = true 
							END IF 
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
						pa_invd_ins [ x].ext_cost_amt 
						LET pr_summary.disc_amt = pr_summary.disc_amt + 
						pa_invd_ins [ x].disc_amt 
						LET pr_summary.ext_sale_amt = pr_summary.ext_sale_amt + 
						pa_invd_ins [ x].ext_sale_amt 
						LET pr_summary.ext_tax_amt = pr_summary.ext_tax_amt + 
						pa_invd_ins [ x].ext_tax_amt 
						LET pr_summary.line_total_amt = pr_summary.line_total_amt + 
						pa_invd_ins[x].line_total_amt 
						LET pr_summary.ship_qty = pr_summary.ship_qty + 
						pa_invd_ins[ x].ship_qty 
						IF pr_summary.activity_code IS NULL THEN 
							LET pr_summary.activity_code = 
							pa_invd_ins[x].activity_code 
						END IF 

						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_cost_amt = pr_summary.ext_cost_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_sale_amt = pr_summary.ext_sale_amt / 
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
					LET err_message = "J31 - invoice line addition failed (2)" 
					LET pr_invoicedetl.* = pa_invd_ins[x].* 
					# UPDATE SALES HISTORY TRANS TABLE
					IF pr_invoicehead.org_cust_code IS NULL THEN 
						LET fv_cust_code = pr_invoicehead.cust_code 
					ELSE 
						LET fv_cust_code = pr_invoicehead.org_cust_code 
					END IF 
					#  Convert the detail line amounts here so that the correct VALUES
					#  are used FOR the sales analysis UPDATE.
					IF fv_use_currency THEN 
						LET pr_invoicedetl.ext_cost_amt = 
						pr_invoicedetl.ext_cost_amt * fv_xchange 
						LET pr_invoicedetl.ext_sale_amt = 
						pr_invoicedetl.ext_sale_amt * fv_xchange 
						LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.ext_tax_amt 
						* fv_xchange 
						LET pr_invoicedetl.disc_amt = pr_invoicedetl.disc_amt * 
						fv_xchange 
						LET pr_invoicedetl.unit_sale_amt = pr_invoicedetl.unit_sale_amt 
						* fv_xchange 
						LET pr_invoicedetl.line_total_amt = pr_invoicedetl.line_total_amt 
						* fv_xchange 
						LET pr_invoicedetl.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
						* fv_xchange 
						LET pr_invoicedetl.unit_cost_amt = pr_invoicedetl.unit_cost_amt 
						* fv_xchange 
						LET pr_invoicedetl.comm_amt = pr_invoicedetl.comm_amt * fv_xchange 
						LET pr_invoicedetl.ext_bonus_amt = pr_invoicedetl.ext_bonus_amt 
						* fv_xchange 
						LET pr_invoicedetl.ext_stats_amt = pr_invoicedetl.ext_stats_amt 
						* fv_xchange 
						LET pr_invoicedetl.list_price_amt = pr_invoicedetl.list_price_amt 
						* fv_xchange 
						LET pr_invoicehead.currency_code = fv_cust_currency 
						LET pr_invoicehead.conv_qty = fv_xchange 
					END IF 

					CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "I", fv_cust_code, 
					pr_invoicedetl.cat_code , pr_invoicedetl.part_code, 
					pr_invoicedetl.line_text , pr_invoicedetl.ware_code, 
					pr_invoicehead.sale_code , 
					pr_invoicehead.acct_override_code , 
					pr_invoicehead.year_num , pr_invoicehead.period_num, 
					pr_invoicedetl.ship_qty , pr_invoicehead.conv_qty, 
					pr_invoicedetl.ext_cost_amt , pr_invoicedetl.ext_sale_amt, 
					pr_invoicedetl.ext_tax_amt, pr_invoicedetl.disc_amt) 

					INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 





					IF pr_invoicedetl.ext_sale_amt IS NOT NULL 
					AND 
					pr_invoicedetl.ext_sale_amt <> 0 THEN 
						LET inv2 = true 
					END IF 
					IF pr_invoicedetl.ext_cost_amt IS NOT NULL 
					AND 
					pr_invoicedetl.ext_cost_amt <> 0 THEN 
						LET inv1 = true 
					END IF 
					IF pr_invoicedetl.ship_qty IS NOT NULL 
					AND 
					pr_invoicedetl.ship_qty <> 0 THEN 
						LET inv1 = true 
					END IF 
				WHEN "3" {summary invoice full PAGE descripion} 
					IF line_num != pa_invd_ins[x].line_num THEN 
						# on change of line number we have a new activity
						# so we INSERT the summary of the previous activity
						# AND SET up the next one
						IF line_num != 0 THEN 
							LET err_message = 
							"J31 - invoice line addition failed (1)" 
							LET pr_invoicedetl.* = pr_summary.* 
							# UPDATE SALES HISTORY TRANS TABLE
							IF pr_invoicehead.org_cust_code IS NULL THEN 
								LET fv_cust_code = pr_invoicehead.cust_code 
							ELSE 
								LET fv_cust_code = pr_invoicehead.org_cust_code 
							END IF 
							# Convert the detail line amounts here so that the correct VALUES
							# are used FOR the sales analysis UPDATE.
							IF fv_use_currency THEN 
								LET pr_invoicedetl.ext_cost_amt = 
								pr_invoicedetl.ext_cost_amt * fv_xchange 
								LET pr_invoicedetl.ext_sale_amt = 
								pr_invoicedetl.ext_sale_amt * fv_xchange 
								LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.ext_tax_amt 
								* fv_xchange 
								LET pr_invoicedetl.disc_amt = pr_invoicedetl.disc_amt 
								* fv_xchange 
								LET pr_invoicedetl.unit_sale_amt = 
								pr_invoicedetl.unit_sale_amt * fv_xchange 
								LET pr_invoicedetl.line_total_amt = 
								pr_invoicedetl.line_total_amt * fv_xchange 
								LET pr_invoicedetl.unit_tax_amt = 
								pr_invoicedetl.unit_tax_amt * fv_xchange 
								LET pr_invoicedetl.unit_cost_amt = 
								pr_invoicedetl.unit_cost_amt * fv_xchange 
								LET pr_invoicedetl.comm_amt = pr_invoicedetl.comm_amt 
								* fv_xchange 
								LET pr_invoicedetl.ext_bonus_amt = 
								pr_invoicedetl.ext_bonus_amt * fv_xchange 
								LET pr_invoicedetl.ext_stats_amt = 
								pr_invoicedetl.ext_stats_amt * fv_xchange 
								LET pr_invoicedetl.list_price_amt = 
								pr_invoicedetl.list_price_amt * fv_xchange 
								LET pr_invoicehead.currency_code = fv_cust_currency 
								LET pr_invoicehead.conv_qty = fv_xchange 
							END IF 
							CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "I", fv_cust_code, 
							pr_invoicedetl.cat_code , pr_invoicedetl.part_code, 
							pr_invoicedetl.line_text , pr_invoicedetl.ware_code, 
							pr_invoicehead.sale_code, 
							pr_invoicehead.acct_override_code , 
							pr_invoicehead.year_num , pr_invoicehead.period_num, 
							pr_invoicedetl.ship_qty , pr_invoicehead.conv_qty, 
							pr_invoicedetl.ext_cost_amt , 
							pr_invoicedetl.ext_sale_amt , pr_invoicedetl.ext_tax_amt 
							, pr_invoicedetl.disc_amt) 
							INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 
							IF pr_invoicedetl.ext_sale_amt IS NOT NULL 
							AND 
							pr_invoicedetl.ext_sale_amt <> 0 THEN 
								LET inv1 = true 
							END IF 
							IF pr_invoicedetl.ext_cost_amt IS NOT NULL 
							AND 
							pr_invoicedetl.ext_cost_amt <> 0 THEN 
								LET inv1 = true 
							END IF 
							IF pr_invoicedetl.ship_qty IS NOT NULL 
							AND 
							pr_invoicedetl.ship_qty <> 0 THEN 
								LET inv1 = true 
							END IF 
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
						pa_invd_ins [ x].ext_cost_amt 
						LET pr_summary.disc_amt = pr_summary.disc_amt + 
						pa_invd_ins [ x].disc_amt 
						LET pr_summary.ext_sale_amt = pr_summary.ext_sale_amt + 
						pa_invd_ins [ x].ext_sale_amt 
						LET pr_summary.ext_tax_amt = pr_summary.ext_tax_amt + 
						pa_invd_ins [ x].ext_tax_amt 
						LET pr_summary.line_total_amt = pr_summary.line_total_amt + 
						pa_invd_ins[x].line_total_amt 
						LET pr_summary.ship_qty = pr_summary.ship_qty + 
						pa_invd_ins[ x].ship_qty 
						IF pr_summary.activity_code IS NULL THEN 
							LET pr_summary.activity_code = 
							pa_invd_ins[x].activity_code 
						END IF 

						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_cost_amt = pr_summary.ext_cost_amt / 
							pr_summary.ship_qty 
						ELSE 
							LET pr_summary.unit_cost_amt = 0 
						END IF 
						IF pr_summary.ship_qty > 0 THEN 
							LET pr_summary.unit_sale_amt = pr_summary.ext_sale_amt / 
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
				WHEN "4" {detailed invoice with full PAGE description} 
					LET err_message = "J31 - invoice line addition failed (2)" 
					LET pr_invoicedetl.* = pa_invd_ins[x].* 
					#UPDATE SALES HISTORY TRANS TABLE
					IF pr_invoicehead.org_cust_code IS NULL THEN 
						LET fv_cust_code = pr_invoicehead.cust_code 
					ELSE 
						LET fv_cust_code = pr_invoicehead.org_cust_code 
					END IF 
					# Convert the detail line amounts here so that the correct VALUES
					# are used FOR the sales analysis UPDATE.
					IF fv_use_currency THEN 
						LET pr_invoicedetl.ext_cost_amt = 
						pr_invoicedetl.ext_cost_amt * fv_xchange 
						LET pr_invoicedetl.ext_sale_amt = 
						pr_invoicedetl.ext_sale_amt * fv_xchange 
						LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.ext_tax_amt 
						* fv_xchange 
						LET pr_invoicedetl.disc_amt = pr_invoicedetl.disc_amt * 
						fv_xchange 
						LET pr_invoicedetl.unit_sale_amt = pr_invoicedetl.unit_sale_amt 
						* fv_xchange 
						LET pr_invoicedetl.line_total_amt = pr_invoicedetl.line_total_amt 
						* fv_xchange 
						LET pr_invoicedetl.unit_tax_amt = pr_invoicedetl.unit_tax_amt 
						* fv_xchange 
						LET pr_invoicedetl.unit_cost_amt = pr_invoicedetl.unit_cost_amt 
						* fv_xchange 
						LET pr_invoicedetl.comm_amt = pr_invoicedetl.comm_amt * fv_xchange 
						LET pr_invoicedetl.ext_bonus_amt = pr_invoicedetl.ext_bonus_amt 
						* fv_xchange 
						LET pr_invoicedetl.ext_stats_amt = pr_invoicedetl.ext_stats_amt 
						* fv_xchange 
						LET pr_invoicedetl.list_price_amt = pr_invoicedetl.list_price_amt 
						* fv_xchange 
						LET pr_invoicehead.currency_code = fv_cust_currency 
						LET pr_invoicehead.conv_qty = fv_xchange 
					END IF 

					CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "I", fv_cust_code, 
					pr_invoicedetl.cat_code , pr_invoicedetl.part_code, 
					pr_invoicedetl.line_text , pr_invoicedetl.ware_code, 
					pr_invoicehead.sale_code , 
					pr_invoicehead.acct_override_code , 
					pr_invoicehead.year_num , pr_invoicehead.period_num, 
					pr_invoicedetl.ship_qty , pr_invoicehead.conv_qty, 
					pr_invoicedetl.ext_cost_amt , pr_invoicedetl.ext_sale_amt, 
					pr_invoicedetl.ext_tax_amt, pr_invoicedetl.disc_amt) 

					INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 





					IF pr_invoicedetl.ext_sale_amt IS NOT NULL 
					AND 
					pr_invoicedetl.ext_sale_amt <> 0 THEN 
						LET inv2 = true 
					END IF 
					IF pr_invoicedetl.ext_cost_amt IS NOT NULL 
					AND 
					pr_invoicedetl.ext_cost_amt <> 0 THEN 
						LET inv1 = true 
					END IF 
					IF pr_invoicedetl.ship_qty IS NOT NULL 
					AND 
					pr_invoicedetl.ship_qty <> 0 THEN 
						LET inv1 = true 
					END IF 
			END CASE 
			CALL increment_tax(pa_invd_ins[x].*) 
		END FOR 

		IF pr_invoicehead.bill_issue_ind = "1" OR 
		pr_invoicehead.bill_issue_ind = "3" 
		AND 
		pr_inv_line_num > 0 THEN 
			LET err_message = "J31 - invoice line addition failed (3)" 
			LET pr_invoicedetl.* = pr_summary.* 
			#UPDATE SALES HISTORY TRANS TABLE
			IF pr_invoicehead.org_cust_code IS NULL THEN 
				LET fv_cust_code = pr_invoicehead.cust_code 
			ELSE 
				LET fv_cust_code = pr_invoicehead.org_cust_code 
			END IF 
			#Convert the detail line amounts here so that the correct VALUES
			#are used FOR the sales analysis UPDATE.
			IF fv_use_currency THEN 
				LET pr_invoicedetl.ext_cost_amt = pr_invoicedetl.ext_cost_amt * 
				fv_xchange 
				LET pr_invoicedetl.ext_sale_amt = pr_invoicedetl.ext_sale_amt * 
				fv_xchange 
				LET pr_invoicedetl.ext_tax_amt = pr_invoicedetl.ext_tax_amt * 
				fv_xchange 
				LET pr_invoicedetl.disc_amt = pr_invoicedetl.disc_amt * 
				fv_xchange 
				LET pr_invoicedetl.unit_sale_amt = pr_invoicedetl.unit_sale_amt * 
				fv_xchange 
				LET pr_invoicedetl.line_total_amt = pr_invoicedetl.line_total_amt 
				* fv_xchange 
				LET pr_invoicedetl.unit_tax_amt = pr_invoicedetl.unit_tax_amt * 
				fv_xchange 
				LET pr_invoicedetl.unit_cost_amt = pr_invoicedetl.unit_cost_amt * 
				fv_xchange 
				LET pr_invoicedetl.comm_amt = pr_invoicedetl.comm_amt * fv_xchange 
				LET pr_invoicedetl.ext_bonus_amt = pr_invoicedetl.ext_bonus_amt * 
				fv_xchange 
				LET pr_invoicedetl.ext_stats_amt = pr_invoicedetl.ext_stats_amt * 
				fv_xchange 
				LET pr_invoicedetl.list_price_amt = pr_invoicedetl.list_price_amt 
				* fv_xchange 
				LET pr_invoicehead.currency_code = fv_cust_currency 
				LET pr_invoicehead.conv_qty = fv_xchange 
			END IF 

			CALL upd_sales_trans(glob_rec_kandoouser.cmpy_code, "I", fv_cust_code, 
			pr_invoicedetl.cat_code , pr_invoicedetl.part_code, 
			pr_invoicedetl.line_text , pr_invoicedetl.ware_code, 
			pr_invoicehead.sale_code , pr_invoicehead.acct_override_code, 
			pr_invoicehead.year_num , pr_invoicehead.period_num, 
			pr_invoicedetl.ship_qty , pr_invoicehead.conv_qty, 
			pr_invoicedetl.ext_cost_amt , pr_invoicedetl.ext_sale_amt, 
			pr_invoicedetl.ext_tax_amt , pr_invoicedetl.disc_amt) 

			INSERT INTO invoicedetl VALUES (pr_invoicedetl.*) 





			IF pr_invoicedetl.ext_sale_amt IS NOT NULL 
			AND 
			pr_invoicedetl.ext_sale_amt <> 0 THEN 
				LET inv1 = true 
			END IF 
			IF pr_invoicedetl.ext_cost_amt IS NOT NULL 
			AND 
			pr_invoicedetl.ext_cost_amt <> 0 THEN 
				LET inv1 = true 
			END IF 
			IF pr_invoicedetl.ship_qty IS NOT NULL 
			AND 
			pr_invoicedetl.ship_qty <> 0 THEN 
				LET inv1 = true 
			END IF 
		END IF 
		# Freight AND Handling tax
		IF pr_invoicehead.freight_amt IS NULL THEN 
			LET pr_invoicehead.freight_amt = 0 
		END IF 
		IF pr_invoicehead.hand_amt IS NULL THEN 
			LET pr_invoicehead.hand_amt = 0 
		END IF 
		IF fr_tax_per IS NULL THEN 
			LET fr_tax_per = 0 
		END IF 
		IF la_tax_per IS NULL THEN 
			LET la_tax_per = 0 
		END IF 







		LET total_pay_amt = total_pay_amt + 
		pr_invoicehead.hand_tax_amt + 
		pr_invoicehead.freight_tax_amt + 
		pr_invoicehead.hand_amt + 
		pr_invoicehead.freight_amt 

		IF (total_tax != pr_invoicehead.tax_amt 
		OR total_tax IS NULL 
		OR pr_invoicehead.tax_amt IS null) THEN 
			LET msgresp = kandoomsg("J",9635,0) 
			#ERROR " Audit on tax figures NOT correct"
			CALL display_error() 
			EXIT program 
		END IF 
		IF total_amt != pr_invoicehead.goods_amt 
		OR total_amt IS NULL 
		OR pr_invoicehead.goods_amt IS NULL THEN 
			LET msgresp = kandoomsg("J",9637,0) 
			#ERROR "Audit on material figures NOT correct"
			CALL errorlog("J31 - material total amount incorrect") 
			CALL display_error() 
			EXIT program 
		END IF 
		IF (total_costs != pr_invoicehead.cost_amt 
		OR total_costs IS NULL 
		OR pr_invoicehead.cost_amt IS null) THEN 
			LET msgresp = kandoomsg("J",9638,0) 
			#ERROR "Audit on cost figures NOT correct"
			CALL errorlog("J31 - material total cost incorrect") 
			CALL display_error() 
			EXIT program 
		END IF 
		IF total_pay_amt != pr_invoicehead.total_amt THEN 
			LET msgresp = kandoomsg("J",9639,0) 
			#ERROR "Audit on total amount figures NOT correct"
			CALL errorlog("J31 - invoice total amount incorrect") 
			CALL display_error() 
			EXIT program 
		END IF 
		LET err_message = "J31 - Unable TO add TO invoice header table" 
		SELECT count(*)INTO cnt 
		FROM invoicehead 
		WHERE inv_num = pr_invoicehead.inv_num 
		AND cmpy_code = pr_invoicehead.cmpy_code 
		IF cnt > 0 THEN 
			LET msgresp = kandoomsg("J",9640,0) 
			#ERROR " Invoice Number already exists, use AZP TO alter"
			ROLLBACK WORK 
			RETURN 
		END IF 
		LET pr_invoicehead.line_num = pr_inv_line_num 
		LET pr_invoicehead.cost_ind = pr_arparms.costings_ind 

		LET pr_invoicehead.acct_override_code = pr_job.acct_code 

		# Invoicehead Insert

		#convert invoiceheader details BEFORE INSERT
		IF fv_use_currency THEN 
			LET pr_invoicehead.goods_amt = pr_invoicehead.goods_amt * fv_xchange 
			LET pr_invoicehead.hand_amt = pr_invoicehead.hand_amt * fv_xchange 
			LET pr_invoicehead.hand_tax_amt = pr_invoicehead.hand_tax_amt * 
			fv_xchange 
			LET pr_invoicehead.freight_amt = pr_invoicehead.freight_amt * 
			fv_xchange 
			LET pr_invoicehead.freight_tax_amt = pr_invoicehead.freight_tax_amt 
			* fv_xchange 
			LET pr_invoicehead.tax_amt = pr_invoicehead.tax_amt * fv_xchange 
			LET pr_invoicehead.disc_amt = pr_invoicehead.disc_amt * fv_xchange 
			LET pr_invoicehead.total_amt = pr_invoicehead.total_amt * fv_xchange 
			LET pr_invoicehead.cost_amt = pr_invoicehead.cost_amt * fv_xchange 
			LET pr_invoicehead.paid_amt = pr_invoicehead.paid_amt * fv_xchange 
			LET pr_invoicehead.disc_taken_amt = pr_invoicehead.disc_taken_amt * 
			fv_xchange 
		END IF 

		LET err_message = "J31f - INSERT INTO invoicehead failed" 
		INSERT INTO invoicehead VALUES (pr_invoicehead.*) 

		SELECT sum(ext_cost_amt), 
		sum(ext_sale_amt)INTO test_cost, 
		test_sale 
		FROM invoicedetl 
		WHERE cmpy_code = pr_invoicehead.cmpy_code 
		AND cust_code = pr_invoicehead.cust_code #2096 
		AND inv_num = pr_invoicehead.inv_num 
		IF test_cost != pr_invoicehead.cost_amt THEN 
			LET msgresp = kandoomsg("J",9641,0) 
			#ERROR "Invoice imbalance between Header AND Lines"
			LET total_costs = test_cost 
			LET total_amt = test_sale 
			ROLLBACK WORK 
			RETURN 
		END IF 
		# IF blank invoice created rollback AND SET
		# glob_password TO be BLKINV
		IF NOT inv1 
		AND NOT inv2 THEN 
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
	pa_invd_ins[pr_inv_line_num].line_total_amt - 
	pa_invd_ins[pr_inv_line_num ].ext_tax_amt 
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

############################################################
# FUNCTION display_error()
#
#
############################################################
FUNCTION display_error() 
	DEFINE ans CHAR(1) 
	DEFINE runner CHAR(120) 
	DEFINE l_output_path STRING
	LET l_output_path = trim(get_settings_logFile()) 
	LET runner = "echo ' Error Occurred in Invoice Number :", 
	pr_invoicehead.inv_num, "'>> ", l_output_path
	RUN runner 
	LET runner = "echo ' Invoice Tax :", pr_invoicehead.tax_amt, "'>>", l_output_path 
	RUN runner 
	LET runner = "echo ' Audit Check Tax :", total_tax, "'>>", l_output_path
	RUN runner 
	LET runner = "echo ' Invoice Materials :", pr_invoicehead.goods_amt, "'>>", l_output_path
	RUN runner 
	LET runner = "echo ' Audit Check Materials :", total_amt, "'>>", l_output_path
	RUN runner 
	LET runner = "echo ' Audit Check Total :", total_pay_amt, "'>>", l_output_path 
	RUN runner 
	LET runner = "echo ' Invoice Costs :", pr_invoicehead.cost_amt, "'>>", l_output_path
	RUN runner 
	LET runner = "echo ' Audit Check Costs :", total_costs, "'>>", l_output_path
	RUN runner 
	LET msgresp = kandoomsg("J",7023,"") 
	# An Audit Check Error has Occurred - Check ", get_settings_logFile()
	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 

############################################################
# FUNCTION write_resbill(pr_tempbill, pr_resbill_line_num) 
#
#
############################################################
FUNCTION write_resbill(pr_tempbill, pr_resbill_line_num) 
	DEFINE 
	pr_tempbill RECORD 
		trans_invoice_flag CHAR(1), 
		trans_date DATE, 
		var_code LIKE activity.var_code, 
		activity_code CHAR(8), 
		seq_num INTEGER, 
		line_num SMALLINT, 
		trans_type_ind CHAR(2), 
		trans_source_num INTEGER, 
		trans_source_text CHAR(8), 
		trans_amt LIKE jobledger.trans_amt, 
		trans_qty LIKE jobledger.trans_qty, 
		charge_amt LIKE jobledger.charge_amt, 
		apply_qty LIKE resbill.apply_qty, 
		apply_amt LIKE resbill.apply_amt, 
		apply_cos_amt LIKE resbill.apply_cos_amt, 
		desc_text CHAR(40), 
		prev_apply_qty LIKE resbill.apply_qty, 
		prev_apply_amt LIKE resbill.apply_amt, 
		prev_apply_cos_amt LIKE resbill.apply_cos_amt, 
		allocation_ind LIKE jobledger.allocation_ind, 
		goods_rec_num LIKE jobledger.ref_num, 
		part_code LIKE purchdetl.ref_text, 
		serial_flag LIKE product.serial_flag, 
		stored_qty LIKE resbill.apply_qty 
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
	LET err_message = "J31 - Insert Resbill Rows" 
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
