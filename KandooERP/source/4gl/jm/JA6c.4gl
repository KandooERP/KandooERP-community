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

	Source code beautified by beautify.pl on 2020-01-02 19:48:18	$Id: $
}




# VA6c (Ja6c!!!)  Job Management write tentinvoice details
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 


DEFINE 
test_cost LIKE tentinvdetl.ext_cost_amt, 
inv1, inv2, inv3, inv4, cnt SMALLINT, 
err_continue CHAR(1), 
err_message CHAR(40), 
total_costs, 
total_tax, 
total_pay_amt, 
total_amt MONEY 


FUNCTION job_inv_write() 

	#  Tables are updated in this Order
	#     tentinvdetl
	#     tentinvhead

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
	pr_start_date, pr_end_date DATE, 
	pr_sav_invdetl RECORD LIKE tentinvdetl.*, 
	pa_invd_chk array[900] OF RECORD 
		trans_type_ind CHAR(2), 
		trans_source_text CHAR(8) 
	END RECORD, 
	line_num LIKE tentinvdetl.line_num, 

	idx, cnt SMALLINT, 
	note_idx SMALLINT, 
	fr_tax_per DECIMAL(5,3), 
	la_tax_per DECIMAL(5,3) 


	LET total_tax = 0 
	LET total_pay_amt = 0 
	LET total_amt = 0 
	LET total_costs = 0 
	LET pr_tax_line_num = 0 
	LET glob_password = " " 
	LET inv1 = 0 
	LET inv2 = 0 
	LET inv3 = 0 
	LET inv4 = 0 

	IF pv_job_start_idx >= 1 THEN 
		LET pr_inv_line_num = pv_job_start_idx - 1 
	ELSE 
		LET pr_inv_line_num = 0 
	END IF 


	IF pr_job.type_code matches "HY*" THEN 
		CALL cont_inv_range(pr_contracthead.cmpy_code, 
		pr_contracthead.contract_code, 
		pr_tentinvhead.inv_num, 
		pr_tentinvhead.inv_date) 
		RETURNING pr_start_date, 
		pr_end_date 
	ELSE 
		LET pr_start_date = pr_tentinvhead.inv_date 
		LET pr_end_date = pr_tentinvhead.inv_date 
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
		LOCK TABLE tentinvdetl in share MODE 


		#
		# The 'for' loop below loads an ARRAY of tentinvdetl which are inserted
		# later on
		#



		FOR cnt = pv_job_start_idx TO arr_size 
			IF pa_inv_line[cnt].invoice_flag IS NOT NULL THEN 


				#
				# In the following code the arrays are used as follows :-
				#
				# pa_tentinvdetl[x].*  : holds the original activity invoice
				#                        lines FROM the entry SCREEN
				# pa_invd_ins[x]       : holds the lines that are TO be
				#                        inserted INTO tentinvdetl
				#


				IF pa_inv_line[cnt].bill_way_ind = "F" THEN 

					# FIXED PRICE JOB

					LET pr_inv_line_num = pr_inv_line_num + 1 

					LET pa_invd_ins[pr_inv_line_num].* = pa_tentinvdetl[cnt].* 
					LET pa_invd_ins[pr_inv_line_num].line_num = pr_inv_line_num 

					CALL fix_nulls() 

					LET pa_invd_ins[pr_inv_line_num].inv_num = 
					pr_tentinvhead.inv_num 

					LET pa_invd_ins[pr_inv_line_num].unit_cost_amt = 
					pa_invd_ins[pr_inv_line_num].ext_cost_amt 
					LET pa_invd_ins[pr_inv_line_num].unit_sale_amt = 
					pa_invd_ins[pr_inv_line_num].ext_sale_amt 

					LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
					LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 

					CALL increment_totals() 
				ELSE 

					# NOT FIXED PRICE JOB

					IF pr_tentinvhead.bill_issue_ind IS NULL OR 

					pr_tentinvhead.bill_issue_ind NOT matches "[1234]" THEN 
						ERROR "You have an incorrect bill type, Invoice Aborting" 
						SLEEP 4 
						EXIT program 
					END IF 

					DECLARE c_tmpbill CURSOR FOR 
					SELECT tempbill.* 
					FROM tempbill 
					WHERE var_code = pa_inv_line[cnt].var_code 
					AND activity_code = pa_inv_line[cnt].activity_code 
					AND trans_invoice_flag = "*" 

					LET pr_tentinvdetl.* = pa_tentinvdetl[cnt].* 


					# FOR a summary job all detail rows in the ARRAY will
					# have the same line number so they can be summarised
					# later on.

					IF pr_tentinvhead.bill_issue_ind = "1" OR 
					pr_tentinvhead.bill_issue_ind = "3" THEN {summary} 
						LET pr_tentinvdetl.line_num = pr_inv_line_num + 1 
					END IF 

					IF pr_tentinvhead.bill_issue_ind = "2" OR 
					pr_tentinvhead.bill_issue_ind = "4" THEN 
						LET pr_tentinvdetl.activity_code = NULL 
					END IF 

					LET pr_tentinvdetl.ext_sale_amt = 0 
					LET pr_tentinvdetl.ext_tax_amt = 0 
					LET pr_tentinvdetl.line_total_amt = 0 
					LET pr_tentinvdetl.ext_cost_amt = 0 
					LET pr_tentinvdetl.ship_qty = 0 
					LET pr_tentinvdetl.unit_cost_amt = 0 
					LET pr_tentinvdetl.unit_sale_amt = 0 
					LET pr_tentinvdetl.inv_num = pr_tentinvhead.inv_num 

					# this code inserts a heading zero value invoice line
					IF pr_tentinvdetl.line_text IS NOT NULL AND 
					pr_tentinvdetl.line_text != " " THEN 

						LET pr_inv_line_num = pr_inv_line_num + 1 


						IF pr_tentinvhead.bill_issue_ind = "2" OR 
						pr_tentinvhead.bill_issue_ind = "4" THEN 
							LET pr_tentinvdetl.line_num = pr_inv_line_num 
						END IF 

						LET pa_invd_ins[pr_inv_line_num].* = pr_tentinvdetl.* 
						LET pa_invd_chk[pr_inv_line_num].trans_type_ind = NULL 
						LET pa_invd_chk[pr_inv_line_num].trans_source_text = NULL 
					END IF 

					FOREACH c_tmpbill INTO pr_tempbill.* 




						LET pr_inv_line_num = pr_inv_line_num + 1 
						LET pa_invd_ins[pr_inv_line_num].* = pa_tentinvdetl[cnt].* 
						LET pa_invd_ins[pr_inv_line_num].jobledger_seq_num = 
						pr_tempbill.seq_num 

						## Simply bringing across the service line_num FOR committing invoices VA9sgs.
						## pr_tempbill.line_num contains the service line num - check VA6bsgs!
						IF pa_invd_ins[pr_inv_line_num].order_num IS NULL THEN 
							LET pa_invd_ins[pr_inv_line_num].order_num = 
							pr_tempbill.line_num 
						END IF 

						CALL fix_nulls() 

						IF pr_tentinvhead.bill_issue_ind = "1" OR 
						pr_tentinvhead.bill_issue_ind = "3" THEN 
							LET pa_invd_ins[pr_inv_line_num].line_num = 
							pr_tentinvdetl.line_num 
						ELSE 
							LET pa_invd_ins[pr_inv_line_num].line_num = 
							pr_inv_line_num 
						END IF 

						LET pa_invd_ins[pr_inv_line_num].inv_num = 
						pr_tentinvhead.inv_num 
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
					END FOREACH 
				END IF 
			END IF 
		END FOR 

		# process the pa_invd_ins ARRAY TO calculate tax FOR each element

		FOR x = pv_job_start_idx TO pr_inv_line_num 

			#calculate tax FOR FP jobs only IF tax type IS 'T'

			IF pr_job.bill_way_ind = "F" THEN 
				CALL find_tax(pr_tentinvhead.tax_code, 
				" ", # part NOT required 
				" ", # warehouse NOT required 
				pr_inv_line_num, 
				x, 
				pa_invd_ins[x].ext_sale_amt, 
				1, 
				"S", 
				pr_start_date, 
				pr_end_date) 
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





				CALL find_tax(pr_tentinvhead.tax_code, 
				pa_invd_chk[x].trans_source_text, 
				pa_invd_ins[x].line_text[16,18], 
				tot_lines, 
				x, 
				pa_invd_ins[x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", 
				pr_start_date, 
				pr_end_date) 
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
			ELSE 
				CALL find_tax(pr_tentinvhead.tax_code, 
				pa_invd_ins[x].line_text[1,15], 
				pa_invd_ins[x].line_text[16,18], 
				tot_lines, 
				x, 
				pa_invd_ins[x].unit_sale_amt, 
				pa_invd_ins[x].ship_qty, 
				"S", 
				pr_start_date, 
				pr_end_date) 
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
			END IF 

			IF pa_invd_ins[x].line_total_amt IS NULL THEN 
				LET pa_invd_ins[x].line_total_amt = 0 
			END IF 
		END FOR 


		#
		# Cycle through all elements in the billing ARRAY AND add tentinvdetl
		# rows as follows :-
		# Fixed price jobs - one tentinvdetl RECORD per activity ie fixed price
		# Other job types (1) Summary - one tentinvdetl per activity
		#                 (2) Detailed - one tentinvdetl per resource alloc
		#


		LET line_num = 0 


		# Load any general invoice lines, inventory lines FOR corporate type
		# invoices

		IF pr_contracthead.cons_inv_flag = "Y" 
		AND pv_job_start_idx > 1 THEN 
			LET cnt = pv_job_start_idx - 1 

			FOR idx = 1 TO cnt 
				CALL find_tax(pr_customer.tax_code, 
				pa_tentinvdetl[idx].part_code, 
				pr_contractdetl.ship_code, 
				cnt, 
				idx, 
				pa_tentinvdetl[idx].unit_sale_amt, 
				pa_tentinvdetl[idx].ship_qty, 
				"S", 
				pr_start_date, 
				pr_end_date) 
				RETURNING tmp_ext_price_amt, 
				pa_tentinvdetl[idx].unit_tax_amt, 
				pa_tentinvdetl[idx].ext_tax_amt, 
				pa_tentinvdetl[idx].line_total_amt, 
				tmp_tax_code 

				LET pr_tentinvdetl.* = pa_tentinvdetl[idx].* 
				LET pr_tentinvdetl.line_num = idx 
				LET pr_tentinvdetl.seq_num = idx 

				INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 

				LET pr_tentinvhead.goods_amt = pr_tentinvhead.goods_amt + 
				(pa_tentinvdetl[idx].line_total_amt 
				- pa_tentinvdetl[idx].ext_tax_amt) 
				LET pr_tentinvhead.total_amt = pr_tentinvhead.total_amt + 
				pa_tentinvdetl[idx].line_total_amt 
				LET pr_tentinvhead.tax_amt = pr_tentinvhead.tax_amt + 
				pa_tentinvdetl[idx].ext_tax_amt 
			END FOR 

			LET line_num = cnt 
		END IF 



		FOR x = pv_job_start_idx TO pr_inv_line_num 

			CASE pr_tentinvhead.bill_issue_ind 
				WHEN "1" {summary invoice} 
					IF line_num != pa_invd_ins[x].line_num THEN 
						# on change of line number we have a new activity
						# so we INSERT the summary of the previous activity
						# AND SET up the next one

						IF (pr_contracthead.cons_inv_flag = "N" AND line_num != 0) 
						OR pr_contracthead.cons_inv_flag = "Y" 
						AND line_num >= pv_job_start_idx THEN 
							LET err_message = 
							"JA6 - invoice line addition failed (1)" 
							LET pr_tentinvdetl.* = pr_summary.* 

							INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 







							IF pr_tentinvdetl.ext_sale_amt IS NOT NULL AND 
							pr_tentinvdetl.ext_sale_amt <> 0 THEN 
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
					LET err_message = "JA6 - invoice line addition failed (2)" 
					LET pr_tentinvdetl.* = pa_invd_ins[x].* 

					INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 






					IF pr_tentinvdetl.ext_sale_amt IS NOT NULL AND 
					pr_tentinvdetl.ext_sale_amt <> 0 THEN 
						LET inv2 = true 
					END IF 



				WHEN "3" {summary invoice with description} 
					IF line_num != pa_invd_ins[x].line_num THEN 
						# on change of line number we have a new activity
						# so we INSERT the summary of the previous activity
						# AND SET up the next one

						IF (pr_contracthead.cons_inv_flag = "N" AND line_num != 0) 
						OR pr_contracthead.cons_inv_flag = "Y" 
						AND line_num >= pv_job_start_idx THEN 
							LET err_message = 
							"JA6 - invoice line addition failed (3)" 
							LET pr_tentinvdetl.* = pr_summary.* 

							INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 







							IF pr_tentinvdetl.ext_sale_amt IS NOT NULL AND 
							pr_tentinvdetl.ext_sale_amt <> 0 THEN 
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

				WHEN "4" {detailed invoice with description} 
					LET err_message = "JA6 - invoice line addition failed (4)" 
					LET pr_tentinvdetl.* = pa_invd_ins[x].* 

					INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 






					IF pr_tentinvdetl.ext_sale_amt IS NOT NULL AND 
					pr_tentinvdetl.ext_sale_amt <> 0 THEN 
						LET inv2 = true 
					END IF 

			END CASE 

			CALL increment_tax(pa_invd_ins[x].*) 
		END FOR 


		IF (pr_tentinvhead.bill_issue_ind = "1" OR 
		pr_tentinvhead.bill_issue_ind = "3") AND 
		pr_inv_line_num > 0 THEN 
			LET err_message = "JA6 - invoice line addition failed (a)" 
			LET pr_tentinvdetl.* = pr_summary.* 

			INSERT INTO tentinvdetl VALUES (pr_tentinvdetl.*) 






			IF pr_tentinvdetl.ext_sale_amt IS NOT NULL AND 
			pr_tentinvdetl.ext_sale_amt <> 0 THEN 
				LET inv1 = true 
			END IF 
		END IF 

		# Freight AND Handling tax
		IF pr_tentinvhead.freight_amt IS NULL THEN 
			LET pr_tentinvhead.freight_amt = 0 
		END IF 

		IF pr_tentinvhead.hand_amt IS NULL THEN 
			LET pr_tentinvhead.hand_amt = 0 
		END IF 

		IF fr_tax_per IS NULL THEN 
			LET fr_tax_per = 0 
		END IF 

		IF la_tax_per IS NULL THEN 
			LET la_tax_per = 0 
		END IF 

		IF pr_tentinvhead.freight_tax_amt IS NOT NULL THEN 
			LET total_tax = total_tax + pr_tentinvhead.freight_tax_amt 
		END IF 

		IF pr_tentinvhead.hand_tax_amt IS NOT NULL THEN 
			LET total_tax = total_tax + pr_tentinvhead.hand_tax_amt 
		END IF 

		LET total_pay_amt = total_pay_amt + 
		pr_tentinvhead.hand_tax_amt + 
		pr_tentinvhead.freight_tax_amt + 
		pr_tentinvhead.hand_amt + 
		pr_tentinvhead.freight_amt 

		LET err_message = "JA6 - Unable TO add TO invoice header table" 
		SELECT count(*) 
		INTO cnt 
		FROM tentinvhead 
		WHERE inv_num = pr_tentinvhead.inv_num 
		AND cmpy_code = pr_tentinvhead.cmpy_code 

		IF cnt > 0 THEN 
			ERROR " Tentative invoice number already exists, try again" 
			SLEEP 3 
		END IF 

		LET pr_tentinvhead.line_num = pr_inv_line_num 
		LET pr_tentinvhead.cost_ind = pr_arparms.costings_ind 
		LET pr_tentinvhead.acct_override_code = pr_job.acct_code 


		# tentinvhead Insert


		IF pr_tentinvhead.goods_amt IS NULL THEN 
			LET pr_tentinvhead.goods_amt = 0 
		END IF 

		IF pr_tentinvhead.tax_amt IS NULL THEN 
			LET pr_tentinvhead.tax_amt = 0 
		END IF 

		LET pr_tentinvhead.total_amt = pr_tentinvhead.goods_amt + 
		pr_tentinvhead.tax_amt 

		LET err_message = "JA6 - Insert INTO tentinvhead failed" 
		INSERT INTO tentinvhead VALUES (pr_tentinvhead.*) 

		SELECT sum(ext_cost_amt) 
		INTO test_cost 
		FROM tentinvdetl 
		WHERE cmpy_code = pr_tentinvhead.cmpy_code 
		AND inv_num = pr_tentinvhead.inv_num 

		IF test_cost != pr_tentinvhead.cost_amt THEN 
			LET msgresp = kandoomsg("A",7512,"") 
			# MESSAGE "Invoice imbalance between header & lines - Invoice will be
			#          aborted"
			ROLLBACK WORK 
		ELSE 

			IF pr_tentinvhead.total_amt = 0 THEN 
				LET msgresp = kandoomsg("A",7512,"") 
				# MESSAGE "Invoice IS FOR 0 total amount - Invoice will be aborted"
				ROLLBACK WORK 
			ELSE 

			COMMIT WORK 
		END IF 
	END IF 










	WHENEVER ERROR stop 

	LET pv_invoice_present = false 

	LET pv_cnt = pv_cnt + 1 
	LET pv_run_total = pv_run_total + pr_tentinvhead.total_amt 
	LET pa_tentinvrun[pv_cnt].inv_num = pr_tentinvhead.inv_num 
	LET pa_tentinvrun[pv_cnt].contract_code = pr_tentinvhead.contract_code 
	LET pa_tentinvrun[pv_cnt].desc_text = pr_contracthead.desc_text 
	LET pa_tentinvrun[pv_cnt].total_amt = pr_tentinvhead.total_amt 


END FUNCTION 


FUNCTION increment_tax(fr_invd_ins) 

	DEFINE 
	fr_invd_ins RECORD LIKE tentinvdetl.* 


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
	DISPLAY "Invoice Total ",pr_tentinvhead.total_amt at 3,3 
	DISPLAY "Check Amt", total_pay_amt at 4,3 
	DISPLAY "Invoice Tax ",pr_tentinvhead.tax_amt at 5,3 
	DISPLAY "Check Tax", total_tax at 6,3 
	DISPLAY "Invoice Materials ", pr_tentinvhead.goods_amt at 7,3 
	DISPLAY "Check Materials", total_amt at 8,3 
	DISPLAY "Invoice Costs ", pr_tentinvhead.cost_amt at 9,3 
	DISPLAY "Check Costs", total_costs at 10,3 

	SLEEP 10 

END FUNCTION 
