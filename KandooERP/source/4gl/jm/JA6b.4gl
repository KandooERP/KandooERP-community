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




{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module VA6b (Ja6b !!) setup job line items FOR invoicing

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 


DEFINE 
pa_pcs array[3] OF RECORD 
	act_bill_amt, 
	est_bill_amt, 
	bill_pc, 
	act_cost_amt, 
	cost_pc DECIMAL, 
	post_cost_amt, 
	act_p_l_amt, 
	act_p_l_pc DECIMAL(16,2) 
END RECORD, 

pa_activity array[300] OF RECORD 
	invoice_flag CHAR(1), 
	title_text LIKE activity.title_text, 
	this_bill_amt DECIMAL(10,2), 
	this_bill_qty DECIMAL(10,2), 
	this_cos_amt DECIMAL(10,2) 
END RECORD, 

chk_bal_amt LIKE customer.bal_amt, 
chk_orig_amt LIKE customer.bal_amt, 
tax_ln_num SMALLINT, 

# Used in the calc_alloc FUNCTION
pa_resbill array[1000] OF RECORD 
	trans_invoice_flag CHAR(1), 
	trans_type_ind LIKE jobledger.trans_type_ind, 
	trans_date LIKE jobledger.trans_date, 
	trans_source_text LIKE jobledger.trans_source_text, 
	apply_qty LIKE resbill.apply_qty, 
	apply_amt LIKE resbill.apply_amt, 
	apply_cos_amt LIKE resbill.apply_cos_amt 
END RECORD, 
pa_seq_num array[1000] OF LIKE jobledger.seq_num, 
pv_invoice_cnt INTEGER 



FUNCTION job_invoicing() 

	DEFINE 
	idx, 
	get_markup SMALLINT, 
	where_text CHAR(100), 
	select_text CHAR(1200), 
	pr_sort_text LIKE activity.sort_text 


	IF pv_prev_type_code != "J" THEN 
		# first job
		DELETE FROM tempbill WHERE 1=1 

		FOR idx = 1 TO 3 
			LET pa_pcs[idx].act_bill_amt = 0 
			LET pa_pcs[idx].est_bill_amt = 0 
			LET pa_pcs[idx].bill_pc = 0 
			LET pa_pcs[idx].act_cost_amt = 0 
			LET pa_pcs[idx].cost_pc = 0 
			LET pa_pcs[idx].post_cost_amt = 0 
			LET pa_pcs[idx].act_p_l_amt = 0 
			LET pa_pcs[idx].act_p_l_pc = 0 
		END FOR 

		LET arr_size = pv_curr_idx 
	END IF 

	LET pv_curr_job_start_idx = pv_curr_idx + 1 
	LET idx = pv_curr_job_start_idx 

	LET select_text = "SELECT ", 
	" activity_code,", 
	" var_code,", 
	" est_comp_per,", 
	" sort_text,", 
	" title_text,", 
	" est_cost_amt,", 
	" act_cost_amt,", 
	" est_bill_amt,", 
	" act_bill_amt,", 
	" post_cost_amt,", 
	" unit_code,", 
	" est_cost_qty,", 
	" act_cost_qty,", 
	" est_bill_qty,", 
	" act_bill_qty,", 
	" post_revenue_amt,", 
	" bill_way_ind ", 
	" FROM activity ", 
	" WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code ,"\" AND ", 
	" job_code = \"", pr_contractdetl.job_code clipped, 
	"\" AND activity_code = \"", pr_contractdetl.activity_code clipped, 
	"\" AND acct_code IS NOT NULL ", 
	"AND finish_flag != 'Y' ", 
	"ORDER BY sort_text, activity_code, var_code" 

	PREPARE activity_query FROM select_text 
	DECLARE c_1 CURSOR FOR activity_query 

	LET get_markup = true 



	FOREACH c_1 INTO 
		pa_inv_line[idx].activity_code, 
		pa_inv_line[idx].var_code, 
		pa_inv_line[idx].est_comp_per, 
		pr_sort_text, 
		pa_inv_line[idx].title_text, 
		pa_inv_line[idx].est_cost_amt, 
		pa_inv_line[idx].act_cost_amt, 
		pa_inv_line[idx].est_bill_amt, 
		pa_inv_line[idx].act_bill_amt, 
		pa_inv_line[idx].post_cost_amt, 
		pa_inv_line[idx].unit_code, 
		pa_inv_line[idx].est_cost_qty, 
		pa_inv_line[idx].act_cost_qty, 
		pa_inv_line[idx].est_bill_qty, 
		pa_inv_line[idx].act_bill_qty, 
		pa_inv_line[idx].post_revenue_amt, 
		pa_inv_line[idx].bill_way_ind 

		# Exit IF job finished flag = "Y"
		IF pr_job.finish_flag = "Y" THEN 
			EXIT FOREACH 
		END IF 

		IF pa_inv_line[idx].est_bill_qty IS NULL THEN 
			LET pa_inv_line[idx].est_bill_qty = 0 
		END IF 

		IF pa_inv_line[idx].act_bill_qty IS NULL THEN 
			LET pa_inv_line[idx].act_bill_qty = 0 
		END IF 

		IF pa_inv_line[idx].est_cost_amt IS NULL THEN 
			LET pa_inv_line[idx].est_cost_amt = 0 
		END IF 

		IF pa_inv_line[idx].act_cost_amt IS NULL THEN 
			LET pa_inv_line[idx].act_cost_amt = 0 
		END IF 

		IF pa_inv_line[idx].est_bill_amt IS NULL THEN 
			LET pa_inv_line[idx].est_bill_amt = 0 
		END IF 

		IF pa_inv_line[idx].act_bill_amt IS NULL THEN 
			LET pa_inv_line[idx].act_bill_amt = 0 
		END IF 

		IF pa_inv_line[idx].post_cost_amt IS NULL THEN 
			LET pa_inv_line[idx].post_cost_amt = 0 
		END IF 

		LET pa_pcs[1].act_cost_amt = pa_pcs[1].act_cost_amt + 
		pa_inv_line[idx].act_cost_amt 
		LET pa_pcs[1].act_bill_amt = pa_pcs[1].act_bill_amt + 
		pa_inv_line[idx].act_bill_amt 
		LET pa_pcs[1].est_bill_amt = pa_pcs[1].est_bill_amt + 
		pa_inv_line[idx].est_bill_amt 
		LET pa_pcs[1].post_cost_amt = pa_pcs[1].post_cost_amt + 
		pa_inv_line[idx].post_cost_amt 

		IF pa_inv_line[idx].bill_way_ind = "C" AND 
		get_markup THEN 
			OPEN WINDOW j130 with FORM "J130" -- alch kd-747 
			CALL winDecoration_j("J130") -- alch kd-747 
			INPUT BY NAME pr_job.markup_per 
			WITHOUT DEFAULTS 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","JA6b","input-pr_job-1") -- alch kd-506 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

			END INPUT 

			CLOSE WINDOW j130 

			IF pr_job.markup_per IS NULL THEN 
				LET pr_job.markup_per = 0 
			END IF 
			LET get_markup = false 
		END IF 


		CALL calc_alloc(idx) 
		RETURNING pa_inv_line[idx].this_bill_qty, 
		pa_inv_line[idx].this_bill_amt, 
		pa_inv_line[idx].this_cos_amt 


		# Ignore any job lines FOR zero qty, bill_amt, cost_amt
		IF pa_inv_line[idx].this_bill_qty = 0 
		AND pa_inv_line[idx].this_bill_amt = 0 
		AND pa_inv_line[idx].this_cos_amt = 0 THEN 

			DELETE FROM tempbill # DELETE ROW FROM tempbill 
			WHERE line_num = idx # table, setup in calc_alloc 

			CONTINUE FOREACH 
		END IF 


		LET pa_inv_line[idx].invoice_flag = "*" 
		LET pa_activity[idx].invoice_flag = "*" 
		LET pa_activity[idx].title_text = 
		pa_inv_line[idx].title_text 
		LET pa_activity[idx].this_bill_qty = 
		pa_inv_line[idx].this_bill_qty 
		LET pa_activity[idx].this_bill_amt = 
		pa_inv_line[idx].this_bill_amt 
		LET pa_activity[idx].this_cos_amt = 
		pa_inv_line[idx].this_cos_amt 

		LET arr_size = arr_size + 1 
		IF idx = 300 THEN 
			ERROR " Only first 300 activities selected" 
			SLEEP 3 
			EXIT FOREACH 
		ELSE 
			LET idx = idx + 1 
		END IF 

	END FOREACH 






	IF arr_size < pv_curr_job_start_idx THEN 
		ERROR " No activities selected FOR job ", 
		pr_contractdetl.job_code clipped, " - DEL TO Re-SELECT" 
		SLEEP 3 
	END IF 


	IF pa_pcs[1].est_bill_amt = 0 THEN 
		LET pa_pcs[1].bill_pc = 0 
	ELSE 
		LET pa_pcs[1].bill_pc = pa_pcs[1].act_bill_amt / 
		pa_pcs[1].est_bill_amt * 100 
	END IF 

	IF pa_pcs[1].act_bill_amt = 0 THEN 
		LET pa_pcs[1].act_p_l_pc = 0 
	ELSE 
		LET pa_pcs[1].act_p_l_amt = pa_pcs[1].act_bill_amt - 
		pa_pcs[1].post_cost_amt 
		LET pa_pcs[1].act_p_l_pc = pa_pcs[1].act_p_l_amt / 
		pa_pcs[1].act_bill_amt * 100 
	END IF 

	IF pa_pcs[1].act_cost_amt = 0 THEN 
		LET pa_pcs[1].cost_pc = 0 
	ELSE 
		LET pa_pcs[1].cost_pc = pa_pcs[1].act_bill_amt / 
		pa_pcs[1].act_cost_amt * 100 
	END IF 

	LET pa_pcs[3].* = pa_pcs[1].* 
	LET tmp_tax_total = 0 
	LET tax_ln_num = 0 
	LET x = 0 
	LET pv_curr_idx = arr_size 


	FOR idx = pv_curr_job_start_idx TO arr_size 
		IF pa_inv_line[idx].invoice_flag IS NOT NULL THEN 
			LET pa_tentinvdetl[idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pa_tentinvdetl[idx].cust_code = pr_tentinvhead.cust_code 
			LET pa_tentinvdetl[idx].var_code = pa_inv_line[idx].var_code 
			LET pa_tentinvdetl[idx].activity_code = pa_inv_line[idx].activity_code 
			LET pa_tentinvdetl[idx].ware_code = NULL 
			LET pa_tentinvdetl[idx].cat_code = NULL 
			LET pa_tentinvdetl[idx].ord_qty = 0 

			IF pa_inv_line[idx].this_bill_qty IS NOT NULL AND 
			pa_inv_line[idx].this_bill_qty <> 0 THEN 
				LET pa_tentinvdetl[idx].ship_qty = pa_inv_line[idx].this_bill_qty 
			ELSE 
				LET pa_tentinvdetl[idx].ship_qty = 1 
			END IF 

			LET pa_tentinvdetl[idx].prev_qty = 0 
			LET pa_tentinvdetl[idx].back_qty = 0 
			LET pa_tentinvdetl[idx].ser_flag = NULL 
			LET pa_tentinvdetl[idx].line_text = pa_inv_line[idx].title_text 
			LET pa_tentinvdetl[idx].uom_code = NULL 
			LET pa_tentinvdetl[idx].unit_cost_amt = NULL 
			LET pa_tentinvdetl[idx].ext_cost_amt = pa_inv_line[idx].this_cos_amt 
			LET pa_tentinvdetl[idx].disc_amt = 0 
			LET pa_tentinvdetl[idx].unit_sale_amt = NULL 
			LET pa_tentinvdetl[idx].ext_sale_amt = pa_inv_line[idx].this_bill_amt 
			LET pa_tentinvdetl[idx].unit_tax_amt = 0 
			LET pa_tentinvdetl[idx].ext_tax_amt = 0 
			LET pa_tentinvdetl[idx].line_total_amt = pa_inv_line[idx].this_bill_amt 
			LET pa_tentinvdetl[idx].jobledger_seq_num = 0 
			LET pa_tentinvdetl[idx].line_acct_code = pr_job.acct_code 
			LET pa_tentinvdetl[idx].level_code = NULL 
			LET pa_tentinvdetl[idx].comm_amt = 0 
			LET pa_tentinvdetl[idx].comp_per = pa_inv_line[idx].est_comp_per 
			LET pa_tentinvdetl[idx].contract_line_num = pr_contractdetl.line_num 

			LET pr_tentinvhead.goods_amt = pr_tentinvhead.goods_amt + 
			pa_inv_line[idx].this_bill_amt 
			LET pr_tentinvhead.cost_amt = pr_tentinvhead.cost_amt + 
			pa_inv_line[idx].this_cos_amt 
		END IF 

		IF pa_inv_line[idx].invoice_flag IS NOT NULL THEN 
			# IF the job IS Fixed Cost THEN the calculation method
			# flag must be = T OTHERWISE no tax IS calculated.

			IF pa_inv_line[idx].bill_way_ind = "F" THEN 
				IF pr_tax.calc_method_flag = "T" OR "N" THEN 
					LET x = x + 1 
					CALL taxing(pa_inv_line[idx].*,x) 
				END IF 
			ELSE 
				CALL taxing(pa_inv_line[idx].*,0) 
			END IF 
		END IF 
	END FOR 


	LET pr_tentinvhead.tax_amt = pr_tentinvhead.tax_amt + tmp_tax_total 

END FUNCTION 



FUNCTION taxing(fr_inv_line,ln_num) 

	DEFINE 
	fr_inv_line RECORD 
		invoice_flag CHAR(1), 
		activity_code LIKE activity.activity_code, 
		var_code LIKE activity.var_code, 
		title_text LIKE activity.title_text, 
		est_comp_per LIKE activity.est_comp_per, 
		est_cost_amt LIKE activity.est_cost_amt, 
		act_cost_amt LIKE activity.act_cost_amt, 
		diff_act_amt LIKE activity.act_cost_amt, 
		est_bill_amt LIKE activity.est_bill_amt, 
		act_bill_amt LIKE activity.act_bill_amt, 
		diff_bill_amt LIKE activity.act_bill_amt, 
		post_cost_amt LIKE activity.post_cost_amt, 
		diff_post_amt LIKE activity.post_cost_amt, 
		unit_code LIKE activity.unit_code, 
		est_cost_qty LIKE activity.est_cost_qty, 
		act_cost_qty LIKE activity.act_cost_qty, 
		est_bill_qty LIKE activity.est_bill_qty, 
		act_bill_qty LIKE activity.act_bill_qty, 
		diff_bill_qty LIKE activity.act_cost_qty, 
		post_revenue_amt LIKE activity.post_revenue_amt, 
		bill_way_ind LIKE activity.bill_way_ind, 
		cost_alloc_flag LIKE activity.cost_alloc_flag, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL(10,2), 
		this_cos_amt DECIMAL(10,2), 
		acct_code CHAR(18) 
	END RECORD, 

	pr_tmpbill RECORD 
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
		prev_apply_cos_amt DECIMAL(16,2) 
	END RECORD, 
	pr_start_date, pr_end_date DATE, 
	unit_price LIKE invoicedetl.unit_sale_amt, 
	ln_num SMALLINT 


	LET sav_tot_lines = 0 
	LET tot_lines = 0 
	LET x = 0 

	IF pr_job.type_code matches "HY*" THEN 
		CALL cont_inv_range(pr_contracthead.cmpy_code, 
		pr_contracthead.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date) 
		RETURNING pr_start_date, 
		pr_end_date 
	ELSE 
		LET pr_start_date = pr_contractdate.invoice_date 
		LET pr_end_date = pr_contractdate.invoice_date 
	END IF 

	IF fr_inv_line.bill_way_ind != "F" THEN 

		# SELECT total number of lines FOR calculation of total tax
		SELECT count(*) 
		INTO tot_lines 
		FROM tempbill 
		WHERE tempbill.trans_invoice_flag IS NOT NULL 

		# Products issues
		DECLARE iss_cur CURSOR FOR 
		SELECT * 
		INTO pr_tmpbill.* 
		FROM tempbill 
		WHERE trans_type_ind = "IS" 
		AND var_code = fr_inv_line.var_code 
		AND activity_code = fr_inv_line.activity_code 
		AND tempbill.trans_invoice_flag IS NOT NULL 

		FOREACH iss_cur 
			LET tax_ln_num = tax_ln_num + 1 

			IF pr_tmpbill.apply_qty != 0 THEN 
				LET unit_price = pr_tmpbill.apply_amt / pr_tmpbill.apply_qty 
			ELSE 
				LET unit_price = pr_tmpbill.apply_amt 
			END IF 

			CALL find_tax(pr_tentinvhead.tax_code, 
			pr_tmpbill.desc_text[1,15], 
			pr_tmpbill.desc_text[16,18], 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			pr_start_date, 
			pr_end_date) 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_unit_tax_amt IS NULL THEN 
				LET tmp_unit_tax_amt = 0 
			END IF 


		END FOREACH 

		# Non Product Issues AND Non Adjustments
		DECLARE res_cur CURSOR FOR 
		SELECT * 
		INTO pr_tmpbill.* 
		FROM tempbill 
		WHERE (trans_type_ind != "IS" AND 
		trans_type_ind != "AD") 
		AND var_code = fr_inv_line.var_code 
		AND activity_code = fr_inv_line.activity_code 
		AND tempbill.trans_invoice_flag IS NOT NULL 

		FOREACH res_cur 
			LET tax_ln_num = tax_ln_num + 1 

			IF pr_tmpbill.apply_qty != 0 THEN 
				LET unit_price = pr_tmpbill.apply_amt / pr_tmpbill.apply_qty 
			ELSE 
				LET unit_price = pr_tmpbill.apply_amt 
			END IF 

			CALL find_tax(pr_tentinvhead.tax_code, 
			pr_tmpbill.trans_source_text, 
			" ", # ware_code NOT required 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			pr_start_date, 
			pr_end_date) 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_unit_tax_amt IS NULL THEN 
				LET tmp_unit_tax_amt = 0 
			END IF 


		END FOREACH 

		# Adjustments
		# Only do adjustment taxing IF total tax on invoice calc method IS used


		DECLARE adj_cur CURSOR FOR 
		SELECT * 
		INTO pr_tmpbill.* 
		FROM tempbill 
		WHERE trans_type_ind = "AD" 
		AND var_code = fr_inv_line.var_code 
		AND activity_code = fr_inv_line.activity_code 
		AND tempbill.trans_invoice_flag IS NOT NULL 

		FOREACH adj_cur 

			LET tax_ln_num = tax_ln_num + 1 

			IF pr_tmpbill.apply_qty != 0 THEN 
				LET unit_price = pr_tmpbill.apply_amt / pr_tmpbill.apply_qty 
			ELSE 
				LET unit_price = pr_tmpbill.apply_amt 
			END IF 

			CALL find_tax(pr_tentinvhead.tax_code, 
			#pr_tmpbill.trans_source_text,
			" ", #adjustment has no resource OR part_code 
			" ", #ware_code NOT required 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			pr_start_date, 
			pr_end_date) 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_unit_tax_amt IS NULL THEN 
				LET tmp_unit_tax_amt = 0 
			END IF 

		END FOREACH 

	ELSE 
		# Do Taxing FOR Fixed Costs ONLY
		# AND only IF the tax type on the tax code IS total

		IF fr_inv_line.this_bill_qty != 0 THEN 
			LET unit_price = fr_inv_line.this_bill_amt / 
			fr_inv_line.this_bill_qty 
		ELSE 
			LET unit_price = fr_inv_line.this_bill_amt 
			LET fr_inv_line.this_bill_qty = 1 
		END IF 

		IF pr_tax.calc_method_flag = "T" OR "N" THEN 
			CALL find_tax(pr_tentinvhead.tax_code, 
			" ", 
			" ", 
			arr_size, 
			ln_num, 
			unit_price, 
			fr_inv_line.this_bill_qty, 
			"S", 
			pr_start_date, 
			pr_end_date) 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 
			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_unit_tax_amt IS NULL THEN 
				LET tmp_unit_tax_amt = 0 
			END IF 

		END IF 

		IF pv_corp_cust THEN 
			IF pr_corp_cust.onorder_amt IS NULL THEN 
				LET pr_corp_cust.onorder_amt = 0 
			END IF 

			LET chk_bal_amt = pr_customer.bal_amt + pr_customer.onorder_amt 
			LET chk_orig_amt = 0 
		ELSE 
			LET chk_bal_amt = pr_customer.bal_amt + pr_customer.onorder_amt 
		END IF 

		IF chk_bal_amt IS NULL THEN 
			LET chk_bal_amt = 0 
		END IF 

		FOR x = 1 TO arr_size 
			IF pa_inv_line[x].invoice_flag IS NULL THEN 
				CONTINUE FOR 
			END IF 

			LET chk_bal_amt = chk_bal_amt + pa_inv_line[x].this_bill_amt 
			LET chk_orig_amt = chk_orig_amt + pa_inv_line[x].this_bill_amt 

			# NOT a corporate debtor check the jobs debtor
			IF pv_corp_cust THEN 

				# a corporate debtor exists so check their credit AND
				# IF required check the originator as well

				IF chk_bal_amt > pr_corp_cust.cred_limit_amt THEN 
					LET pv_error = true 
					LET pv_error_run = true 
					LET pv_error_text = 
					"Corporate customer will exceed Credit Limit with above billings - ", 
					chk_bal_amt 
					OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
					pr_company.name_text, 
					pr_contractdate.contract_code, 
					pr_contractdate.inv_num, 
					pr_contractdate.invoice_date, 
					pr_contractdate.invoice_total_amt, 
					pv_error_text) 
				END IF 

				IF pr_customer.credit_chk_flag = "O" THEN 
					IF NOT cc_credit_chk(pr_customer.cust_code, 
					pr_customer.corp_cust_code, 
					pr_customer.cred_limit_amt, 
					chk_orig_amt) THEN 
						LET pv_error = true 
						LET pv_error_run = true 
						LET pv_error_text = pr_customer.cust_code, 
						" Customer will exceed Credit with above invoicing - ", 
						chk_orig_amt 
						OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
						pr_company.name_text, 
						pr_contractdate.contract_code, 
						pr_contractdate.inv_num, 
						pr_contractdate.invoice_date, 
						pr_contractdate.invoice_total_amt, 
						pv_error_text) 
					END IF 
				END IF 
			ELSE 
				IF chk_bal_amt > pr_customer.cred_limit_amt THEN 
					LET pv_error = true 
					LET pv_error_run = true 
					LET pv_error_text = pr_customer.cust_code, 
					" Customer will exceed Credit with above invoicing - ", chk_bal_amt 
					OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
					pr_company.name_text, 
					pr_contractdate.contract_code, 
					pr_contractdate.inv_num, 
					pr_contractdate.invoice_date, 
					pr_contractdate.invoice_total_amt, 
					pv_error_text) 
				END IF 
			END IF 
		END FOR 

	END IF 

END FUNCTION 




FUNCTION cc_credit_chk(fv_cust_code,fv_corp_cust, fv_cred_limit, fv_extra) 

	DEFINE fv_cust_code LIKE customer.cust_code, 
	fv_corp_cust LIKE customer.cust_code, 
	fv_cred_limit LIKE customer.cred_limit_amt, 
	fv_inv_tot LIKE customer.cred_limit_amt, 
	fv_cred_tot LIKE customer.cred_limit_amt, 
	# fv_extra records the extra credit requested
	fv_extra LIKE customer.bal_amt 

	# This FUNCTION assumes that fv_cust_code has the original customer information
	# AND that fv_corp_cust has the corporate customer information

	SELECT sum(total_amt - paid_amt) 
	INTO fv_inv_tot 
	FROM invoicehead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = fv_corp_cust 
	AND org_cust_code = fv_cust_code 
	AND total_amt != paid_amt 

	IF fv_inv_tot IS NULL THEN 
		LET fv_inv_tot = 0 
	END IF 

	# Do this here TO save having TO check credits
	IF (fv_inv_tot + fv_extra) < fv_cred_limit THEN 
		RETURN true 
	END IF 

	SELECT sum(total_amt - appl_amt) 
	INTO fv_cred_tot 
	FROM credithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cust_code = fv_corp_cust 
	AND org_cust_code = fv_cust_code 
	AND total_amt != appl_amt 

	IF fv_cred_tot IS NULL THEN 
		LET fv_cred_tot = 0 
	END IF 

	LET fv_inv_tot = fv_inv_tot - fv_cred_tot 

	RETURN ( (fv_inv_tot + fv_extra) < fv_cred_limit ) 

END FUNCTION 


FUNCTION calc_alloc(inv_idx) 

	DEFINE 
	fr_services RECORD LIKE services.*, 
	fv_trans_amt LIKE jobledger.trans_amt, 
	fv_trans_qty LIKE jobledger.trans_qty, 
	fv_charge_amt LIKE jobledger.charge_amt, 
	fv_freq SMALLINT, 
	pr_line_tot_qty DECIMAL(15,3), 
	pr_line_tot_bill DECIMAL(16,2), 
	pr_line_tot_cos DECIMAL(16,2), 
	inv_idx SMALLINT, 
	tmp_est_amt1, 
	tmp_est_amt2 LIKE activity.post_cost_amt 

	LET pr_line_tot_qty = 0 
	LET pr_line_tot_bill = 0 
	LET pr_line_tot_cos = 0 

	DECLARE sv_c CURSOR FOR 
	SELECT services.* 
	FROM services 
	WHERE services.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND services.contract_code = pr_contractdetl.contract_code 
	AND services.contract_line_num = pr_contractdetl.line_num 
	AND services.bill_type_ind in ("R","C","Q","B","A", "D") 
	AND services.status_code = "A" 
	ORDER BY services.service_line_num 

	FOREACH sv_c INTO fr_services.* 

		IF fr_services.qty IS NULL THEN 
			LET fr_services.qty = 0 
		END IF 
		IF fr_services.charge_amt IS NULL THEN 
			LET fr_services.charge_amt = 0 
		END IF 
		IF fr_services.cost_amt IS NULL THEN 
			LET fr_services.cost_amt = 0 
		END IF 

		## Calculations
		LET fv_trans_amt = 0 
		LET fv_trans_qty = 0 
		LET fv_charge_amt = 0 
		IF pr_contracthead.bill_type_code = "A" OR 
		pr_contracthead.bill_type_code = "D" THEN 
			LET fv_freq = 1 
		ELSE 
			LET fv_freq = (12/pr_contracthead.bill_int_ind) 
		END IF 
		CASE 
			WHEN fr_services.bill_type_ind = "R" 
				LET fv_trans_amt = fr_services.cost_amt 
				LET fv_trans_qty = fr_services.qty 
				LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

			WHEN fr_services.bill_type_ind = "C" 
				LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
				LET fv_trans_qty = fr_services.qty 
				LET fv_charge_amt = fr_services.charge_amt 

			WHEN fr_services.bill_type_ind = "Q" 
				LET fv_trans_amt = fr_services.cost_amt 
				LET fv_trans_qty = (fr_services.qty/fv_freq) 
				LET fv_charge_amt = fr_services.charge_amt 

			WHEN fr_services.bill_type_ind = "B" 
				LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
				LET fv_trans_qty = fr_services.qty 
				LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

			WHEN fr_services.bill_type_ind = "A" 
				LET fv_trans_amt = (fr_services.cost_amt/fv_freq) 
				LET fv_trans_qty = (fr_services.qty/fv_freq) 
				LET fv_charge_amt = (fr_services.charge_amt/fv_freq) 

			WHEN fr_services.bill_type_ind = "D" 
				LET fv_trans_amt = fr_services.cost_amt 
				LET fv_trans_qty = fr_services.qty 
				LET fv_charge_amt = fr_services.charge_amt 

		END CASE 


		LET pr_tempbill.trans_invoice_flag = "*" 
		LET pr_tempbill.trans_date = today 
		LET pr_tempbill.trans_source_num = NULL 
		LET pr_tempbill.trans_type_ind = "RE" 
		LET pr_tempbill.var_code = pr_contractdetl.var_code 
		LET pr_tempbill.activity_code = pr_contractdetl.activity_code 
		LET pr_tempbill.trans_source_text = fr_services.service_code 
		LET pr_tempbill.seq_num = 0 
		LET pr_tempbill.trans_qty = fv_trans_qty 
		LET pr_tempbill.line_num = fr_services.service_line_num 
		LET pr_tempbill.trans_amt = fv_trans_amt 

		# Set apply quantity
		IF fr_services.bill_type_ind = "A" THEN 
			IF pr_job.bill_way_ind = "R" THEN 
				LET pr_tempbill.apply_qty = fv_trans_qty 
			ELSE 
				LET pr_tempbill.apply_qty = fv_trans_qty 
			END IF 
		ELSE 
			LET pr_tempbill.apply_qty = 0 
		END IF 

		# Set cost amount
		IF fr_services.bill_type_ind != "R" THEN 
			LET pr_tempbill.apply_cos_amt = fv_trans_amt 
		ELSE 
			IF fr_services.bill_type_ind = "B" THEN 
				LET pr_tempbill.apply_cos_amt = 0 
			ELSE 
				LET pr_tempbill.apply_cos_amt = 0 
			END IF 
		END IF 

		# Set apply amount (bill amount)
		IF fr_services.bill_type_ind != "C" THEN 
			IF pa_inv_line[inv_idx].bill_way_ind = "C" THEN 
				LET pr_tempbill.apply_amt = pr_tempbill.apply_cos_amt 
				* ((pr_job.markup_per/100) + 1) 
			ELSE 
				LET pr_tempbill.apply_amt = fv_charge_amt 
			END IF 
		ELSE 
			LET pr_tempbill.apply_amt = 0 
		END IF 

		LET pr_tempbill.charge_amt = fv_charge_amt 

		LET pr_tempbill.desc_text = fr_services.desc_text 

		IF pr_job.bill_way_ind = "R" THEN 
			LET pr_tempbill.prev_apply_qty = pr_tempbill.apply_qty 
		ELSE 
			LET pr_tempbill.prev_apply_qty = "0" 
		END IF 

		LET pr_tempbill.prev_apply_amt = "0" 
		LET pr_tempbill.prev_apply_cos_amt = "0" 
		LET pr_tempbill.allocation_ind = fr_services.bill_type_ind 

		SELECT count(*) 
		INTO pv_invoice_cnt 
		FROM contractdate 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND contract_code = pr_contracthead.contract_code 
		AND inv_num IS NULL 

		IF fr_services.bill_type_ind = "B" THEN 
			LET pr_tempbill.apply_qty = fv_trans_qty 
		ELSE 
			LET pr_tempbill.apply_qty = pr_tempbill.apply_qty/pv_invoice_cnt 
		END IF 

		LET pr_tempbill.apply_amt = pr_tempbill.apply_amt/pv_invoice_cnt 
		LET pr_tempbill.apply_cos_amt = pr_tempbill.apply_cos_amt / 
		pv_invoice_cnt 

		LET pr_tempbill.apply_qty = pr_tempbill.trans_qty 
		LET pr_tempbill.apply_amt = pr_tempbill.charge_amt 
		LET pr_tempbill.apply_cos_amt = pr_tempbill.trans_amt 

		INSERT INTO tempbill VALUES (pr_tempbill.*) 

		LET pr_line_tot_qty = pr_line_tot_qty + pr_tempbill.apply_qty 
		LET pr_line_tot_bill = pr_line_tot_bill + pr_tempbill.apply_amt 
		LET pr_line_tot_cos = pr_line_tot_cos + pr_tempbill.apply_cos_amt 
	END FOREACH 

	CASE 
		WHEN pa_inv_line[inv_idx].bill_way_ind = "T" 
			OR pa_inv_line[inv_idx].bill_way_ind = "C" 
			OR pa_inv_line[inv_idx].bill_way_ind = "R" 
			RETURN pr_line_tot_qty, 
			pr_line_tot_bill, 
			pr_line_tot_cos 

		WHEN pa_inv_line[inv_idx].bill_way_ind = "F" 
			LET tmp_est_amt1 = (pa_inv_line[inv_idx].est_comp_per/100 * 
			pa_inv_line[inv_idx].est_cost_amt) 
			LET tmp_est_amt2 = (tmp_est_amt1 - 
			pa_inv_line[inv_idx].post_cost_amt) 
			return((pa_inv_line[inv_idx].est_comp_per/100 * 
			pa_inv_line[inv_idx].est_bill_qty ) - 
			pa_inv_line[inv_idx].act_bill_qty), 
			((pa_inv_line[inv_idx].est_comp_per/100 * 
			pa_inv_line[inv_idx].est_bill_amt) - 
			pa_inv_line[inv_idx].act_bill_amt), 
			tmp_est_amt2 
		OTHERWISE 
			RETURN 0,0,0 
	END CASE 

END FUNCTION {calc_alloc} 

