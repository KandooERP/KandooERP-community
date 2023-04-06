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

	Source code beautified by beautify.pl on 2020-01-02 19:48:20	$Id: $
}



# Purpose - get_detail() FOR changing credit line detail
#         - alloc() creates tempbill table

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 

DEFINE 
pa_resbill ARRAY [1000] OF RECORD 
	trans_invoice_flag CHAR(1), 
	trans_type_ind LIKE jobledger.trans_type_ind, 
	trans_date LIKE jobledger.trans_date, 
	trans_source_text LIKE jobledger.trans_source_text, 
	apply_qty LIKE resbill.apply_qty, 
	apply_amt LIKE resbill.apply_amt, 
	apply_cos_amt LIKE resbill.apply_cos_amt 
END RECORD, 
pa_seq_num ARRAY [1000] OF LIKE jobledger.seq_num 


FUNCTION alloc(inv_idx, invoice_num, line_num) 
	# Generates a tempbill table rows FOR given glob_rec_kandoouser.cmpy_code, job, var,
	# AND activity AND invoice number.
	# A row IS created in tempbill FOR each invoice line.
	DEFINE 
	pr_resbill RECORD 
		apply_qty LIKE resbill.apply_qty, 
		apply_amt LIKE resbill.apply_amt, 
		apply_cos_amt LIKE resbill.apply_cos_amt 
	END RECORD, 
	pr_line_tot_qty LIKE resbill.apply_qty, 
	pr_line_tot_bill LIKE resbill.apply_amt, 
	pr_line_tot_cos LIKE resbill.apply_cos_amt, 
	inv_idx SMALLINT, 
	invoice_num LIKE invoicedetl.inv_num, 
	line_num LIKE invoicedetl.line_num 

	LET pr_line_tot_qty = 0 
	LET pr_line_tot_bill = 0 
	LET pr_line_tot_cos = 0 
	LET select_text = "SELECT jobledger.*, sum(apply_qty), ", 
	" sum(apply_amt), ", 
	" sum(apply_cos_amt) ", 
	"FROM jobledger, outer resbill ", 
	"WHERE jobledger.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND jobledger.job_code = \"", pr_job.job_code, "\" ", 
	"AND jobledger.var_code = ", 
	pa_cred_line[inv_idx].var_code, " ", 
	"AND jobledger.activity_code = \"", 
	pa_cred_line[inv_idx].activity_code, "\" ", 
	"AND jobledger.allocation_ind != 'Q' ", 
	"AND jobledger.allocation_ind != 'N' ", 
	"AND resbill.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND resbill.job_code = jobledger.job_code ", 
	"AND resbill.var_code = jobledger.var_code ", 
	"AND resbill.activity_code = ", 
	" jobledger.activity_code ", 
	"AND resbill.seq_num = jobledger.seq_num ", 
	"AND resbill.inv_num = ", invoice_num, " ", 
	"AND resbill.line_num >= ", line_num, " ", 
	"group by jobledger.cmpy_code, ", 
	" jobledger.trans_date, ", 
	" jobledger.year_num, ", 
	" jobledger.period_num, ", 
	" jobledger.job_code, ", 
	" jobledger.var_code, ", 
	" jobledger.activity_code, ", 
	" jobledger.seq_num, ", 
	" jobledger.trans_type_ind, ", 
	" jobledger.trans_source_num, ", 
	" jobledger.trans_source_text, ", 
	" jobledger.trans_amt, ", 
	" jobledger.trans_qty, ", 
	" jobledger.charge_amt, ", 
	" jobledger.posted_flag, ", 
	" jobledger.desc_text, ", 
	" jobledger.allocation_ind,", 
	" jobledger.accrual_ind,", 
	" jobledger.reversal_date,", 
	" jobledger.entry_code,", 
	" jobledger.entry_date,", 
	" jobledger.jour_num,", 
	" jobledger.post_date,", 
	" jobledger.ref_num " 

	PREPARE jl_prep 
	FROM select_text 
	DECLARE jl_c CURSOR FOR jl_prep 
	FOREACH jl_c INTO pr_jobledger.*, 
		pr_resbill.apply_qty, 
		pr_resbill.apply_amt, 
		pr_resbill.apply_cos_amt 
		IF pr_resbill.apply_qty IS NULL THEN 
			LET pr_resbill.apply_qty = 0 
		END IF 
		IF pr_resbill.apply_amt IS NULL THEN 
			LET pr_resbill.apply_amt = 0 
		END IF 
		IF pr_resbill.apply_cos_amt IS NULL THEN 
			LET pr_resbill.apply_cos_amt = 0 
		END IF 
		IF pr_job.bill_way_ind = "R" THEN 
			IF pr_resbill.apply_amt = 0 
			AND pr_resbill.apply_cos_amt = 0 THEN 
				CONTINUE FOREACH 
			END IF 
		ELSE 
			IF pr_resbill.apply_qty = 0 
			AND pr_resbill.apply_amt = 0 
			AND pr_resbill.apply_cos_amt = 0 THEN 
				CONTINUE FOREACH 
			END IF 
		END IF 
		LET pr_tempbill.trans_invoice_flag = "*" 
		LET pr_tempbill.trans_date = pr_invoicehead.inv_date 
		LET pr_tempbill.trans_source_num = pr_jobledger.trans_source_num 
		LET pr_tempbill.trans_type_ind = pr_jobledger.trans_type_ind 
		LET pr_tempbill.var_code = pr_jobledger.var_code 
		LET pr_tempbill.activity_code = pr_jobledger.activity_code 
		LET pr_tempbill.trans_source_text = pr_jobledger.trans_source_text 
		LET pr_tempbill.seq_num = pr_jobledger.seq_num 
		LET pr_tempbill.trans_qty = pr_jobledger.trans_qty 
		IF pr_credithead.bill_issue_ind = "2" OR 
		pr_credithead.bill_issue_ind = "4" THEN 
			SELECT invoicedetl.line_num INTO pr_tempbill.line_num 
			FROM invoicedetl, 
			invoicehead 
			WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicehead.cust_code = pr_credithead.cust_code 
			AND invoicehead.inv_num = invoice_num 
			AND invoicehead.job_code = pr_job.job_code 
			AND invoicedetl.cmpy_code = invoicehead.cmpy_code 
			AND invoicedetl.inv_num = invoicehead.inv_num 
			AND invoicedetl.cust_code = invoicehead.cust_code 
			AND invoicedetl.activity_code = pr_jobledger.activity_code 
			AND invoicedetl.var_code = pr_jobledger.var_code 
			AND invoicedetl.jobledger_seq_num = pr_jobledger.seq_num 
			IF status THEN {must be loaded FROM a summary invoice} 
				SELECT invoicedetl.line_num INTO pr_tempbill.line_num 
				FROM invoicedetl, 
				invoicehead 
				WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invoicehead.inv_num = invoice_num 
				AND invoicehead.job_code = pr_job.job_code 
				AND invoicedetl.cmpy_code = invoicehead.cmpy_code 
				AND invoicedetl.inv_num = invoicehead.inv_num 
				AND invoicedetl.cust_code = invoicehead.cust_code 
				AND invoicedetl.activity_code = pr_jobledger.activity_code 
				AND invoicedetl.var_code = pr_jobledger.var_code 
			END IF 
		ELSE 
			LET pr_tempbill.line_num = line_num 
		END IF 
		LET pr_tempbill.trans_amt = pr_jobledger.trans_amt 
		# Set apply quantity
		IF pr_jobledger.allocation_ind = "A" THEN 
			IF pr_job.bill_way_ind = "R" THEN 
				LET pr_tempbill.apply_qty = pr_jobledger.trans_qty 
			ELSE 
				LET pr_tempbill.apply_qty = pr_resbill.apply_qty 
			END IF 
		ELSE # 
			IF pr_jobledger.allocation_ind = "B" THEN 
				LET pr_tempbill.apply_qty = pr_jobledger.trans_qty 
			ELSE 
				LET pr_tempbill.apply_qty = 0 
			END IF 
		END IF 
		# Set cost amount
		IF pr_jobledger.allocation_ind != "R" THEN 
			LET pr_tempbill.apply_cos_amt = pr_resbill.apply_cos_amt 
		ELSE 
			LET pr_tempbill.apply_cos_amt = 0 
		END IF 
		# Set apply amount (bill amount)
		IF pr_jobledger.allocation_ind != "C" THEN 
			IF pa_cred_line[inv_idx].bill_way_ind = "C" THEN 
				LET pr_tempbill.apply_amt = pr_tempbill.apply_cos_amt * (( 
				pr_job.markup_per / 100) + 1) 
			ELSE 
				LET pr_tempbill.apply_amt = pr_resbill.apply_amt 
			END IF 
		ELSE 
			LET pr_tempbill.apply_amt = 0 
		END IF 
		LET pr_tempbill.charge_amt = pr_jobledger.charge_amt 
		IF pr_jobledger.desc_text IS NULL 
		OR pr_jobledger.desc_text = " " THEN 
			SELECT desc_text INTO pr_tempbill.desc_text 
			FROM jmresource 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND res_code = pr_jobledger.trans_source_text 
		ELSE 
			LET pr_tempbill.desc_text = pr_jobledger.desc_text 
		END IF 
		SELECT sum(apply_qty), 
		sum(apply_amt), 
		sum(apply_cos_amt)INTO pr_tempbill.prev_apply_qty, 
		pr_tempbill.prev_apply_amt, 
		pr_tempbill.prev_apply_cos_amt 
		FROM resbill 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND job_code = pr_jobledger.job_code 
		AND var_code = pr_jobledger.var_code 
		AND activity_code = pr_jobledger.activity_code 
		AND seq_num = pr_jobledger.seq_num 
		AND inv_num != invoice_num 
		IF pr_tempbill.prev_apply_qty IS NULL THEN 
			LET pr_tempbill.prev_apply_qty = 0 
		END IF 
		IF pr_tempbill.prev_apply_amt IS NULL THEN 
			LET pr_tempbill.prev_apply_amt = 0 
		END IF 
		IF pr_tempbill.prev_apply_cos_amt IS NULL THEN 
			LET pr_tempbill.prev_apply_cos_amt = 0 
		END IF 







		LET pr_tempbill.arr_line_num = inv_idx 
		LET pr_tempbill.allocation_ind = pr_jobledger.allocation_ind 

		IF pr_tempbill.trans_type_ind = "PU" THEN 
			LET pr_tempbill.goods_rec_num = pr_jobledger.ref_num 
			LET pr_tempbill.stored_qty = pr_tempbill.apply_qty 
			SELECT ref_text 
			INTO pr_tempbill.part_code 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_tempbill.trans_source_num 
			AND desc_text = pr_tempbill.desc_text 
			SELECT serial_flag 
			INTO pr_tempbill.serial_flag 
			FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_tempbill.part_code 
		ELSE 
			LET pr_tempbill.goods_rec_num = 0 
			LET pr_tempbill.stored_qty = 0 
			LET pr_tempbill.part_code = " " 
			LET pr_tempbill.serial_flag = " " 
		END IF 

		INSERT INTO tempbill VALUES (pr_tempbill.*) 
		LET pr_line_tot_qty = pr_line_tot_qty + pr_tempbill.apply_qty 
		LET pr_line_tot_bill = pr_line_tot_bill + pr_tempbill.apply_amt 
		LET pr_line_tot_cos = pr_line_tot_cos + pr_tempbill.apply_cos_amt 
	END FOREACH 
	CASE 
		WHEN pa_cred_line[inv_idx].bill_way_ind = "T" 
			OR pa_cred_line[inv_idx].bill_way_ind = "C" 
			OR pa_cred_line[inv_idx].bill_way_ind = "R" 
			RETURN pr_line_tot_qty, 
			pr_line_tot_bill, 
			pr_line_tot_cos 
		WHEN pa_cred_line[inv_idx].bill_way_ind = "F" 
			RETURN (pa_cred_line[inv_idx].est_comp_per * pa_cred_line[inv_idx] 
			.bdgt_bill_qty / 100), (pa_cred_line[inv_idx].est_comp_per * pa_cred_line 
			[ inv_idx].bdgt_bill_amt / 100), (pa_cred_line[inv_idx].est_comp_per * 
			pa_cred_line [inv_idx].bdgt_cost_amt / 100) 
		OTHERWISE 
			RETURN 0, 
			0, 
			0 
	END CASE 
END FUNCTION 



FUNCTION edit_alloc(inv_idx) 
	DEFINE 
	pr_trans_source_text CHAR(8), 
	bill_idx, 
	idx, 
	scrn, 
	cnt, 
	inv_idx SMALLINT 

	DECLARE ea_c CURSOR FOR 
	SELECT tempbill.* 
	FROM tempbill 
	WHERE var_code = ps_creditdetl[inv_idx].var_code 
	AND activity_code = ps_creditdetl[inv_idx].activity_code 
	ORDER BY seq_num 
	LET bill_idx = 0 
	FOREACH ea_c INTO pr_tempbill.* 
		LET bill_idx = bill_idx + 1 
		LET pa_resbill[bill_idx].trans_invoice_flag = 
		pr_tempbill.trans_invoice_flag 
		LET pa_resbill[bill_idx].trans_type_ind = pr_tempbill.trans_type_ind 
		LET pa_resbill[bill_idx].trans_date = pr_tempbill.trans_date 
		LET pa_resbill[bill_idx].trans_source_text = pr_tempbill.trans_source_text 

		IF pr_kandoooption_sn = "Y" 
		AND pr_tempbill.trans_type_ind = "PU" THEN 
			LET pa_resbill[bill_idx].trans_source_text 
			= pr_tempbill.goods_rec_num USING "<<<<<<<&" 
		END IF 

		LET pa_resbill[bill_idx].apply_qty = pr_tempbill.apply_qty 
		LET pa_resbill[bill_idx].apply_cos_amt = pr_tempbill.apply_cos_amt 
		LET pa_resbill[bill_idx].apply_amt = pr_tempbill.apply_amt 
		LET pa_seq_num[bill_idx] = pr_tempbill.seq_num 
		IF bill_idx = 1000 THEN 
			ERROR 
			" First 1000 Outstanding Transactions Selected FOR this Activity " 
			SLEEP 2 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF bill_idx = 0 THEN 
		LET msgresp = kandoomsg("J",7507,"") 
		#ERROR " No Outstanding Transactions exist FOR this Activity"
		RETURN false 
	END IF 
	OPEN WINDOW j154 with FORM "J154" -- alch kd-747 
	CALL winDecoration_j("J154") -- alch kd-747 
	LET msgresp = kandoomsg("J",9473,bill_idx) 
	# First bill_idx Outstanding Transactions selected FOR thsi activity
	DISPLAY ps_creditdetl[inv_idx].ship_qty, 
	ps_creditdetl[inv_idx].ext_sales_amt, 
	ps_creditdetl[inv_idx].ext_cost_amt 
	TO this_bill_qty, 
	this_bill_amt, 
	this_cos_amt 

	LET msgresp = kandoomsg("J",1430,"") 
	#MESSAGE " RETURN TO Edit Billing - F7 Toggle Transaction FOR Invoice"

	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	CALL set_count(bill_idx) 
	INPUT ARRAY pa_resbill WITHOUT DEFAULTS 
	FROM sr_tempbill.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC1g","input_arr-pa_resbill-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_resbill[idx].* TO sr_tempbill[scrn].* 

		BEFORE FIELD trans_type_ind 
			IF get_detail(ps_creditdetl[inv_idx].var_code, 
			ps_creditdetl[inv_idx].activity_code , 
			pa_seq_num[idx]) THEN 
				LET pa_resbill[idx].apply_qty = pr_tempbill.apply_qty 
				LET pa_resbill[idx].apply_amt = pr_tempbill.apply_amt 
				LET pa_resbill[idx].apply_cos_amt = pr_tempbill.apply_cos_amt 
				DISPLAY "" at 2,1 
				DISPLAY "qty/cost/sale ", pr_tempbill.apply_qty, 
				" ", pr_tempbill.apply_amt, 
				" ", pr_tempbill.apply_cos_amt at 2,1 
				SLEEP 2 
				DISPLAY pa_resbill[idx].apply_qty, 
				pa_resbill[idx].apply_amt, 
				pa_resbill[idx].apply_cos_amt 
				TO sr_tempbill[scrn].apply_qty, 
				sr_tempbill[scrn].apply_amt, 
				sr_tempbill[scrn].apply_cos_amt 
				CALL evaluate_totals(bill_idx) 
				RETURNING ps_creditdetl[inv_idx].ship_qty, 
				ps_creditdetl[inv_idx].ext_sales_amt, 
				ps_creditdetl[inv_idx].ext_cost_amt 
				DISPLAY "" at 2,1 
				DISPLAY "** qty/cost/sale ", ps_creditdetl[inv_idx].ship_qty, 
				" ", ps_creditdetl[inv_idx].ext_sales_amt, 
				" ", ps_creditdetl[inv_idx].ext_cost_amt at 2,1 
				SLEEP 2 

				IF ps_creditdetl[inv_idx].ship_qty > 0 THEN 
					LET ps_creditdetl[inv_idx].unit_sales_amt = 
					ps_creditdetl[inv_idx].ext_sales_amt / 
					ps_creditdetl[inv_idx].ship_qty 
				ELSE 
					LET ps_creditdetl[inv_idx].unit_sales_amt = 0 
				END IF 
				IF ps_creditdetl[inv_idx].ship_qty > 0 THEN 
					LET ps_creditdetl[inv_idx].unit_cost_amt = 
					ps_creditdetl[inv_idx].ext_cost_amt / 
					ps_creditdetl[ inv_idx].ship_qty 
				ELSE 
					LET ps_creditdetl[inv_idx].unit_cost_amt = 0 
				END IF 
			ELSE 
				DISPLAY "" at 2,1 
				DISPLAY "problem" at 2,1 
				SLEEP 2 
			END IF 
			NEXT FIELD trans_invoice_flag 
		BEFORE INSERT 
			LET msgresp = kandoomsg("J",9472,"") 
			#ERROR " No Further Transactions"
		AFTER ROW 
			DISPLAY pa_resbill[idx].* TO sr_tempbill[scrn].* 

		ON KEY (f7) 
			IF pa_resbill[idx].trans_invoice_flag IS NULL THEN 
				LET pa_resbill[idx].trans_invoice_flag = "*" 
			ELSE 
				LET pa_resbill[idx].trans_invoice_flag = NULL 
			END IF 
			DISPLAY pa_resbill[idx].trans_invoice_flag TO 
			sr_tempbill[scrn].trans_invoice_flag 

			CALL evaluate_totals(bill_idx) 
			RETURNING ps_creditdetl[inv_idx].ship_qty, 
			ps_creditdetl[inv_idx].ext_sales_amt, 
			ps_creditdetl[inv_idx].ext_cost_amt 
			IF ps_creditdetl[inv_idx].ship_qty > 0 THEN 
				LET ps_creditdetl[inv_idx].unit_sales_amt = 
				ps_creditdetl[inv_idx].ext_sales_amt / 
				ps_creditdetl[ inv_idx].ship_qty 
			ELSE 
				LET ps_creditdetl[inv_idx].unit_sales_amt = 0 
			END IF 
			IF ps_creditdetl[inv_idx].ship_qty > 0 THEN 
				LET ps_creditdetl[inv_idx].unit_cost_amt = 
				ps_creditdetl[inv_idx].ext_cost_amt / 
				ps_creditdetl[ inv_idx].ship_qty 
			ELSE 
				LET ps_creditdetl[inv_idx].unit_cost_amt = 0 
			END IF 
			NEXT FIELD trans_invoice_flag 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	CLOSE WINDOW j154 
	IF int_flag 
	OR quit_flag THEN 
		LET msgresp = kandoomsg("J",9471,"") 
		#ERROR " Invoice Reverted TO previous VALUES"
		RETURN false 
	END IF 
	FOR idx = 1 TO bill_idx 
		UPDATE tempbill 
		SET (trans_invoice_flag, apply_qty, apply_amt, apply_cos_amt) = 
		(pa_resbill[idx].trans_invoice_flag, 
		pa_resbill[idx].apply_qty, 
		pa_resbill[idx].apply_amt , 
		pa_resbill[idx].apply_cos_amt) 
		WHERE var_code = ps_creditdetl[inv_idx].var_code 
		AND activity_code = ps_creditdetl[inv_idx].activity_code 
		AND seq_num = pa_seq_num[idx] 
	END FOR 

	RETURN true 
END FUNCTION 


FUNCTION evaluate_totals(idx) 
	DEFINE 
	pr_this_bill_amt LIKE activity.act_bill_amt, 
	pr_this_cos_amt LIKE activity.act_cost_amt, 
	pr_this_bill_qty LIKE resbill.apply_qty, 
	cnt, 
	idx SMALLINT 

	LET pr_this_bill_amt = 0 
	LET pr_this_bill_qty = 0 
	LET pr_this_cos_amt = 0 
	FOR cnt = 1 TO idx 
		IF pa_resbill[cnt].trans_invoice_flag = "*" THEN 
			LET pr_this_bill_qty = pr_this_bill_qty + pa_resbill[cnt].apply_qty 
			LET pr_this_bill_amt = pr_this_bill_amt + pa_resbill[cnt].apply_amt 
			LET pr_this_cos_amt = pr_this_cos_amt + pa_resbill[cnt].apply_cos_amt 
		END IF 
	END FOR 
	DISPLAY pr_this_bill_qty, 
	pr_this_bill_amt, 
	pr_this_cos_amt 
	TO this_bill_qty, 
	this_bill_amt, 
	this_cos_amt 

	RETURN pr_this_bill_qty, 
	pr_this_bill_amt, 
	pr_this_cos_amt 
END FUNCTION 


FUNCTION get_detail(tmp_var, tmp_act, tmp_seq) 
	DEFINE 
	tmp_var LIKE activity.var_code, 
	tmp_act LIKE activity.activity_code, 
	tmp_seq LIKE jobledger.seq_num, 
	pr_seq_num INTEGER, 
	inv_idx SMALLINT, 
	pr_unit_sale LIKE creditdetl.unit_sales_amt, 
	pr_unit_cost LIKE creditdetl.unit_cost_amt, 
	pr_qty_cnt SMALLINT 

	SELECT tempbill.* INTO pr_tempbill.* 
	FROM tempbill 
	WHERE var_code = tmp_var 
	AND activity_code = tmp_act 
	AND seq_num = tmp_seq 
	IF status THEN 
		LET msgresp = kandoomsg("J",9470,"") 
		#ERROR "No outstanding resources TO be credited"
		RETURN false 
	END IF 
	IF pr_tempbill.desc_text IS NULL 
	OR (pr_tempbill.desc_text clipped = " ") THEN 
		SELECT desc_text INTO pr_tempbill.desc_text 
		FROM jmresource 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND res_code = pr_tempbill.trans_source_text 
	END IF 
	OPEN WINDOW j321 with FORM "J321" -- alch kd-747 
	CALL winDecoration_j("J321") -- alch kd-747 
	LET pr_unit_sale = pr_tempbill.apply_amt / pr_tempbill.trans_qty 
	LET pr_unit_cost = pr_tempbill.apply_cos_amt / pr_tempbill.trans_qty 

	DISPLAY BY NAME pr_tempbill.seq_num, 
	pr_tempbill.trans_date, 
	pr_tempbill.trans_type_ind, 
	pr_tempbill.trans_source_num, 
	pr_tempbill.desc_text, 
	pr_tempbill.trans_source_text, 
	pr_tempbill.trans_qty, 
	pr_tempbill.charge_amt, 
	pr_tempbill.trans_amt, 
	pr_tempbill.apply_qty, 
	pr_tempbill.apply_amt, 
	pr_tempbill.apply_cos_amt 

	INPUT BY NAME pr_tempbill.desc_text, 
	pr_tempbill.apply_qty, 
	pr_tempbill.apply_amt, 
	pr_tempbill.apply_cos_amt WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC1g","input-pr_tempbill-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD desc_text 
			IF pr_credithead.bill_issue_ind = "2" OR 
			pr_credithead.bill_issue_ind = "4" THEN 
				LET msgresp = kandoomsg("J",1021,"") 
				#MESSAGE " Edit the Transaction Description FOR Invoice Printing"
			ELSE 
				LET msgresp = kandoomsg("J",1022,"") 
				# MESSAGE "Enter New Billing - ESC TO Accept - DEL TO Exit"
				NEXT FIELD apply_qty 
			END IF 
		AFTER FIELD desc_text 
			LET msgresp = kandoomsg("J",1022,"") 
			#MESSAGE "Enter New Billing - ESC TO Accept - DEL TO Exit"
		BEFORE FIELD apply_qty 
			IF pr_job.bill_way_ind = "R" 
			OR pr_tempbill.allocation_ind != "A" THEN 
				NEXT FIELD apply_amt 
			END IF 
		AFTER FIELD apply_qty 
			LET pr_tempbill.apply_amt = pr_unit_sale * pr_tempbill.apply_qty 
			LET pr_tempbill.apply_cos_amt = pr_unit_cost * pr_tempbill.apply_qty 
			DISPLAY BY NAME pr_tempbill.apply_amt, 
			pr_tempbill.apply_cos_amt 
		BEFORE FIELD apply_amt 
			IF pr_job.bill_way_ind = "C" 
			OR pr_tempbill.allocation_ind = "C" THEN 
				NEXT FIELD apply_cos_amt 
			END IF 
		BEFORE FIELD apply_cos_amt 
			IF pr_tempbill.allocation_ind = "R" THEN 
				EXIT INPUT 
			END IF 
		AFTER INPUT 
			IF pr_tempbill.trans_type_ind = "PU" 
			AND pr_tempbill.apply_qty <> pr_tempbill.stored_qty 
			AND pr_tempbill.serial_flag = "Y" THEN 
				SELECT count(*) 
				INTO pr_qty_cnt 
				FROM t_serialinfo 
				WHERE part_code = pr_tempbill.part_code 
				LET pr_qty_cnt = serial_input(pr_tempbill.part_code,"",pr_qty_cnt) 
				LET pr_tempbill.apply_qty = pr_qty_cnt 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF pr_job.bill_way_ind = "C" THEN 
		LET pr_tempbill.apply_amt = pr_tempbill.apply_cos_amt * 
		((pr_job.markup_per / 100) + 1) 
		DISPLAY BY NAME pr_tempbill.apply_amt 
	END IF 

	CLOSE WINDOW j321 
	IF int_flag 
	OR quit_flag THEN 
		LET msgresp = kandoomsg("J",9469,"") 
		#ERROR " Transaction Reverted TO previous value"
		RETURN false 
	END IF 
	IF pr_credithead.bill_issue_ind = "2" OR 
	pr_credithead.bill_issue_ind = "4" THEN 
		UPDATE tempbill 
		SET desc_text = pr_tempbill.desc_text, 
		apply_amt = pr_tempbill.apply_amt, 
		apply_qty = pr_tempbill.apply_qty, 
		apply_cos_amt = pr_tempbill.apply_cos_amt 
		WHERE var_code = tmp_var 
		AND activity_code = tmp_act 
		AND seq_num = tmp_seq 
	END IF 

	RETURN true 
END FUNCTION 
