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




# Purpose - INPUT line items of the invoice
#           Functions :    select_lines
#                        disp_items
#                        calc_pcs .. recalculates payment amount percentages

GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 


DEFINE 
pr_validate_ind CHAR(1), 
tax_ln_num SMALLINT 


FUNCTION select_lines() 
	DEFINE 
	idx, 
	get_markup SMALLINT, 
	where_text CHAR(100), 
	select_text CHAR(1200), 
	pr_sort_text LIKE activity.sort_text, 
	tmp_activity LIKE activity.activity_code, 
	tmp_var LIKE activity.var_code 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	CLEAR FORM 
	DELETE FROM tempbill WHERE 1=1 
	DELETE FROM editbill WHERE 1=1 

	FOR idx = 1 TO arr_size 
		INITIALIZE pa_inv_line[idx].* TO NULL 
		INITIALIZE pa_activity[idx].* TO NULL 
		INITIALIZE ps_activity[idx].* TO NULL 
	END FOR 

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

	CLEAR FORM 
	DISPLAY BY NAME pr_job.job_code, 
	pr_job.title_text, 
	pr_customer.cust_code, 
	pr_customer.name_text 






	LET select_text = "SELECT sort_text, ", 
	" activity.activity_code, ", 
	" activity.var_code, ", 


	" min(line_num) ", 
	"FROM invoicedetl,activity ", 
	"WHERE invoicedetl.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND invoicedetl.cust_code = \"", 
	pr_invoicehead.cust_code,"\" ", 
	"AND invoicedetl.inv_num = ", 
	pr_invoicehead.inv_num," ", 
	"AND activity.cmpy_code = invoicedetl.cmpy_code ", 
	"AND activity.job_code = \"",pr_job.job_code,"\" ", 
	"AND activity.var_code = invoicedetl.var_code ", 

	"AND activity.activity_code = ", 
	" invoicedetl.activity_code ", 
	"group by sort_text, activity.activity_code, ", 

	"activity.var_code ", 
	"ORDER BY sort_text, activity.activity_code, ", 
	"activity.var_code " 

	PREPARE line_sel FROM select_text 
	DECLARE line_curs CURSOR FOR line_sel 

	LET get_markup = true 
	LET arr_size = 0 
	LET idx = 1 
	LET note_size = 0 
	FOREACH line_curs INTO pr_sort_text, 
		pr_invoicedetl.activity_code, 
		pr_invoicedetl.var_code, 
		pr_invoicedetl.line_num 

		LET select_text = "SELECT activity_code,", 
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
		" bill_way_ind, ", 
		" cost_alloc_flag, ", 
		" acct_code ", 
		"FROM activity ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code ,"\" ", 
		"AND job_code = \"", pr_job.job_code , "\" ", 
		"AND wip_acct_code IS NOT NULL ", 
		"AND var_code = ",pr_invoicedetl.var_code," ", 
		"AND activity_code = \"",pr_invoicedetl.activity_code, 
		"\" " 

		PREPARE activity_query FROM select_text 
		DECLARE c_1 CURSOR FOR activity_query 
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
			pa_inv_line[idx].bill_way_ind, 
			pa_inv_line[idx].cost_alloc_flag, 
			pa_inv_line[idx].acct_code 

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
			IF pa_inv_line[idx].bill_way_ind = "C" AND get_markup THEN 
				OPEN WINDOW j130 with FORM "J130" -- alch kd-747 
				CALL winDecoration_j("J130") -- alch kd-747 
				IF pr_job.markup_per IS NULL THEN 
					LET pr_job.markup_per = 0 
				END IF 
				IF pr_job.markup_per = 0 THEN 
					INPUT BY NAME pr_job.markup_per WITHOUT DEFAULTS 
						BEFORE INPUT 
							CALL publish_toolbar("kandoo","J36b","input-pr_job-1") -- alch kd-506 
						ON ACTION "WEB-HELP" -- albo kd-373 
							CALL onlinehelp(getmoduleid(),null) 
					END INPUT 
				ELSE 
					DISPLAY BY NAME pr_job.markup_per attribute(yellow) 
					--                   prompt "Any key TO continue" FOR CHAR ans  -- albo
					CALL eventsuspend() --LET ans = AnyKey("Any key TO continue") -- albo 
				END IF 
				CLOSE WINDOW j130 
				LET get_markup = false 
			END IF 

			# CALL TO alloc TO build tempbill FROM resbill

			CALL alloc(idx,pr_invoicehead.inv_num, 
			pr_invoicedetl.line_num) 
			RETURNING pa_inv_line[idx].this_bill_qty, 
			pa_inv_line[idx].this_bill_amt, 
			pa_inv_line[idx].this_cos_amt 

			IF pr_job.bill_way_ind != "R" THEN 
				IF pa_inv_line[idx].act_bill_qty > 0 THEN 
					LET pa_inv_line[idx].act_bill_qty = 
					pa_inv_line[idx].act_bill_qty - 
					pa_inv_line[idx].this_bill_qty 
				END IF 
			END IF 

			IF pa_inv_line[idx].act_bill_amt > 0 THEN 
				LET pa_inv_line[idx].act_bill_amt = 
				pa_inv_line[idx].act_bill_amt - 
				pa_inv_line[idx].this_bill_amt 
			END IF 

			IF pa_inv_line[idx].post_cost_amt > 0 THEN 
				LET pa_inv_line[idx].post_cost_amt = 
				pa_inv_line[idx].post_cost_amt - 
				pa_inv_line[idx].this_cos_amt 
			END IF 

			LET pa_inv_line[idx].invoice_flag = "*" 
			LET pa_activity[idx].invoice_flag = "*" 
			LET pa_activity[idx].title_text = pa_inv_line[idx].title_text 
			LET pa_activity[idx].this_bill_qty = pa_inv_line[idx].this_bill_qty 
			LET pa_activity[idx].this_bill_amt = pa_inv_line[idx].this_bill_amt 
			LET pa_activity[idx].this_cos_amt = pa_inv_line[idx].this_cos_amt 

			# save the current state of invoice FOR later reversing
			LET ps_activity[idx].* = pa_activity[idx].* 

			LET arr_size = arr_size + 1 
			LET idx = idx + 1 
		END FOREACH 
	END FOREACH 

	# CHECK IF ANY LINES CONTAIN NOTES - IF YES LOAD THEM INto NOTE ARRAY
	DECLARE c_detl_notes CURSOR FOR 
	SELECT * 
	INTO pr_invoicedetl.* 
	FROM invoicedetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND inv_num = pr_invoicehead.inv_num 
	FOREACH c_detl_notes 
		IF pr_invoicedetl.line_text[1,3] = "###" AND 
		pr_invoicedetl.line_text[16,18] = "###" 
		THEN 
			LET note_size = note_size + 1 
			LET pa_notes[note_size].note_code = pr_invoicedetl.line_text 
			LET pa_notes[note_size].var_code = pr_invoicedetl.var_code 
			LET pa_notes[note_size].activity_code = pr_invoicedetl.activity_code 
			SELECT title_text 
			INTO pa_notes[note_size].title_text 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = pr_invoicehead.job_code 
			AND activity_code = pr_invoicedetl.activity_code 
			AND var_code = pr_invoicedetl.var_code 
		END IF 
	END FOREACH 


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

	RETURN true 

END FUNCTION 


FUNCTION disp_lineitems() 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	cont, 
	idx, scrn SMALLINT, 



	chk_bal_amt LIKE customer.bal_amt, 
	chk_orig_amt LIKE customer.bal_amt 
	LET msgresp = kandoomsg("J",1423,"") 
	# MESSAGE" ESC Invoice - RETURN Edit Line - F5 Foreign Currency",
	#" F7 Line Toggle - F8 Add Line - F10 Info"
	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	OPTIONS INSERT KEY f36 
	WHENEVER ERROR stop 

	WHILE (true) 
		CALL set_count (arr_size) 
		LET cont = false 
		INPUT ARRAY pa_activity WITHOUT DEFAULTS FROM sr_activity.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","J36b","input_arr-pa_activity-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
			BEFORE ROW 
				LET idx = arr_curr() 
				LET scrn = scr_line() 
				IF pa_inv_line[idx].activity_code IS NULL THEN 
					ERROR " No further Invoice lines Available " 
					NEXT FIELD invoice_flag 
				END IF 
				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

				CALL disp_line_detail(idx, scrn) 
			ON KEY (F5) 
				CALL view_currency(idx,pr_customer.cust_code,pr_invoicehead.conv_qty) 
			ON KEY (F7) 
				IF pa_activity[idx].invoice_flag IS NULL THEN 
					LET pa_activity[idx].invoice_flag = "*" 
				ELSE 
					LET pa_activity[idx].invoice_flag = NULL 
				END IF 
				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 


			ON KEY (F8) 
				# allow selection of lines NOT in this invoice FOR
				# inclusion IF required.
				LET max_array = arr_count() 

				IF get_new_line() THEN 
					LET cont = true 
					EXIT INPUT 
				ELSE 
					NEXT FIELD invoice_flag 
				END IF 

			ON KEY (f10) 
				CALL display_info(idx) 
				MESSAGE" ESC Invoice - RETURN Edit Line -", 
				" F7 Invoice Line Toggle - F10 Information" 
				attribute(yellow) 

			ON ACTION "NOTES"  --	ON KEY (control-n) 
				CALL scan_notes(idx) 

			BEFORE FIELD title_text 
				IF edit_alloc(idx) THEN 
					LET pa_activity[idx].this_bill_qty = 
					pa_inv_line[idx].this_bill_qty 
					LET pa_activity[idx].this_bill_amt = 
					pa_inv_line[idx].this_bill_amt 
					LET pa_activity[idx].this_cos_amt = 
					pa_inv_line[idx].this_cos_amt 
				ELSE 
					LET pa_inv_line[idx].this_bill_qty = 
					pa_activity[idx].this_bill_qty 
					LET pa_inv_line[idx].this_bill_amt = 
					pa_activity[idx].this_bill_amt 
					LET pa_inv_line[idx].this_cos_amt = 
					pa_activity[idx].this_cos_amt 
				END IF 
				DISPLAY pa_activity[idx].* TO sr_activity[scrn].* 

				CALL disp_line_detail(idx, scrn) 
				NEXT FIELD invoice_flag 
			AFTER ROW 
				LET pa_inv_line[idx].invoice_flag = 
				pa_activity[idx].invoice_flag 
				DISPLAY pa_activity[idx].* 
				TO sr_activity[scrn].* 


			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					# get original invoice value AND subtract FROM balance
					#         TO be checked
					LET orig_inv_amt = pr_invoicehead.total_amt 
					# check IF the customers credit limit will be exceeded
					IF pv_corp_cust THEN 

						LET chk_bal_amt = pr_corp_cust.bal_amt + pr_corp_cust.onorder_amt 
						- orig_inv_amt 
						LET chk_orig_amt = 0 
					ELSE 

						LET chk_bal_amt = pr_customer.bal_amt + pr_customer.onorder_amt 
						- orig_inv_amt 
					END IF 
					IF chk_bal_amt IS NULL THEN 
						LET chk_bal_amt = 0 
					END IF 
					FOR x = 1 TO arr_size 
						LET chk_bal_amt = chk_bal_amt + pa_inv_line[x].this_bill_amt 
						LET chk_orig_amt = chk_orig_amt + pa_inv_line[x].this_bill_amt 
						# NOT a corporate debtor check the jobs debtor
						IF NOT pv_corp_cust THEN 
							IF chk_bal_amt > pr_customer.cred_limit_amt THEN 
								ERROR "Customer will exceed Credit with above invoicing" 
								NEXT FIELD invoice_flag 
							END IF 
							# a corporate debtor exists so check their credit AND
							# IF required check the originator as well
						ELSE 
							IF chk_bal_amt > pr_corp_cust.cred_limit_amt THEN 
								ERROR "Corporate customer will exceed Credit Limit with", 
								" above billings" 
								NEXT FIELD invoice_flag 
							END IF 
							IF pr_customer.credit_chk_flag = "O" THEN 
								IF NOT cc_credit_chk(pr_customer.cust_code, 
								pr_customer.corp_cust_code, 
								pr_customer.cred_limit_amt, 
								chk_orig_amt) THEN 
									ERROR "Customer will exceed Credit with above invoicing" 
									NEXT FIELD invoice_flag 
								END IF 
							END IF 
						END IF 
					END FOR 
					EXIT INPUT 
				ELSE 
					EXIT INPUT 
				END IF 
			ON KEY (control-w) 
				CALL kandoohelp("") 
		END INPUT 

		IF cont THEN 
			LET cont = false 
			CONTINUE WHILE 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		RETURN false 
	END IF 

	LET pr_invoicehead.goods_amt = 0 
	LET pr_invoicehead.cost_amt = 0 

	# Check calculation method flag on tax code.
	SELECT * 
	INTO pr_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_invoicehead.tax_code 


	LET tmp_tax_total = 0 
	LET x = 0 
	LET tax_ln_num = 0 
	FOR idx = 1 TO arr_size 
		IF pa_inv_line[idx].invoice_flag IS NOT NULL THEN 
			LET pa_invoicedetl[idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pa_invoicedetl[idx].cust_code = pr_invoicehead.cust_code 
			LET pa_invoicedetl[idx].var_code = pa_inv_line[idx].var_code 
			LET pa_invoicedetl[idx].activity_code = 
			pa_inv_line[idx].activity_code 
			LET pa_invoicedetl[idx].ware_code = NULL 
			LET pa_invoicedetl[idx].cat_code = NULL 
			LET pa_invoicedetl[idx].ord_qty = 0 
			IF pa_inv_line[idx].this_bill_qty IS NOT NULL THEN 
				LET pa_invoicedetl[idx].ship_qty = 
				pa_inv_line[idx].this_bill_qty 
			ELSE 
				LET pa_invoicedetl[idx].ship_qty = 1 
			END IF 
			LET pa_invoicedetl[idx].prev_qty = 0 
			LET pa_invoicedetl[idx].back_qty = 0 
			LET pa_invoicedetl[idx].ser_flag = NULL 
			LET pa_invoicedetl[idx].line_text = pa_inv_line[idx].title_text 
			LET pa_invoicedetl[idx].uom_code = NULL 
			LET pa_invoicedetl[idx].unit_cost_amt = NULL 
			LET pa_invoicedetl[idx].ext_cost_amt = 
			pa_inv_line[idx].this_cos_amt 
			LET pa_invoicedetl[idx].disc_amt = 0 
			LET pa_invoicedetl[idx].unit_sale_amt = NULL 
			LET pa_invoicedetl[idx].ext_sale_amt = 
			pa_inv_line[idx].this_bill_amt 
			LET pa_invoicedetl[idx].unit_tax_amt = 0 
			LET pa_invoicedetl[idx].ext_tax_amt = 0 
			LET pa_invoicedetl[idx].line_total_amt = 
			pa_inv_line[idx].this_bill_amt 
			LET pa_invoicedetl[idx].jobledger_seq_num = 0 





			LET pa_invoicedetl[idx].line_acct_code = pa_inv_line[idx].acct_code 



			LET pa_invoicedetl[idx].level_code = NULL 
			LET pa_invoicedetl[idx].comm_amt = 0 
			LET pa_invoicedetl[idx].comp_per = 
			pa_inv_line[idx].est_comp_per 
			LET pr_invoicehead.goods_amt = pr_invoicehead.goods_amt + 
			pa_inv_line[idx].this_bill_amt 
			LET pr_invoicehead.cost_amt = pr_invoicehead.cost_amt + 
			pa_inv_line[idx].this_cos_amt 
		END IF 

		# Only do taxing on selected lines FOR invoicing.
		IF pa_inv_line[idx].invoice_flag IS NOT NULL THEN 

			# IF the job IS Fixed Cost THEN the calculation method
			# flag must be = T OTHERWISE no tax IS calculated.
			IF pa_inv_line[idx].bill_way_ind = "F" THEN 
				IF pr_tax.calc_method_flag = "T" THEN 
					LET x = x + 1 
					CALL taxing(pa_inv_line[idx].*,x) 
				ELSE 
					IF pr_tax.calc_method_flag = "N" THEN 
						LET x = x + 1 
						CALL taxing(pa_inv_line[idx].*,x) 
					END IF 
				END IF 
			ELSE 
				CALL taxing(pa_inv_line[idx].*,0) 
			END IF 
		END IF 
	END FOR 

	RETURN true 

END FUNCTION 


FUNCTION disp_line_detail(idx, scrn) 
	DEFINE 
	pr_tot_bill_amt, 
	pr_tot_bill_qty, 
	pr_tot_cos_amt DECIMAL(16,2), 
	pr_bill_text CHAR(12), 
	idx, scrn SMALLINT 

	CASE pa_inv_line[idx].bill_way_ind 
		WHEN "F" 
			LET pr_bill_text = "Fixed Price" 
		WHEN "C" 
			LET pr_bill_text = "Cost Plus " 
		WHEN "T" 
			LET pr_bill_text = "Time & Mtls" 
		WHEN "R" 
			LET pr_bill_text = "Recurring" 
		OTHERWISE 
			LET pr_bill_text = "Unknown" 
	END CASE 
	DISPLAY pr_bill_text TO bill_text 

	LET pr_tot_bill_amt = pa_inv_line[idx].this_bill_amt 
	+ pa_inv_line[idx].act_bill_amt 
	LET pr_tot_cos_amt = pa_inv_line[idx].this_cos_amt 
	+ pa_inv_line[idx].post_cost_amt 

	IF pr_job.bill_way_ind = "R" THEN 
		LET pr_tot_bill_qty = pa_inv_line[idx].this_bill_qty 
	ELSE 
		LET pr_tot_bill_qty = pa_inv_line[idx].this_bill_qty 
		+ pa_inv_line[idx].act_bill_qty 
	END IF 
	DISPLAY BY NAME 
	pa_inv_line[idx].activity_code, 
	pa_inv_line[idx].var_code, 
	pa_inv_line[idx].est_comp_per, 
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
	pa_inv_line[idx].post_revenue_amt 

	DISPLAY pr_tot_bill_amt, 
	pr_tot_cos_amt, 
	pr_tot_bill_qty 
	TO tot_bill_amt, 
	tot_cos_amt, 
	tot_bill_qty 

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
	unit_price LIKE invoicedetl.unit_sale_amt, 
	ln_num SMALLINT 



	LET sav_tot_lines = 0 
	LET tot_lines = 0 
	LET x = 0 


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

			CALL find_tax(pr_invoicehead.tax_code, 
			pr_tmpbill.desc_text[1,15], 
			pr_tmpbill.desc_text[16,18], 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			"", 
			"") 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
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

			CALL find_tax(pr_invoicehead.tax_code, 
			pr_tmpbill.trans_source_text, 
			" ", # ware_code NOT required 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			"", 
			"") 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
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

			CALL find_tax(pr_invoicehead.tax_code, 
			pr_tmpbill.trans_source_text, 
			" ", #ware_code NOT required 
			tot_lines, 
			tax_ln_num, 
			unit_price, 
			pr_tmpbill.apply_qty, 
			"S", 
			"", 
			"") 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 

			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
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
			CALL find_tax(pr_invoicehead.tax_code, 
			" ", 
			" ", 
			arr_size, 
			ln_num, 
			unit_price, 
			fr_inv_line.this_bill_qty, 
			"S", 
			"", 
			"") 
			RETURNING tmp_ext_price_amt, 
			tmp_unit_tax_amt, 
			tmp_ext_tax_amt, 
			tmp_line_tot_amt, 
			tmp_tax_code 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 
			LET tmp_tax_total = tmp_tax_total + tmp_ext_tax_amt 
			IF tmp_ext_tax_amt IS NULL THEN 
				LET tmp_ext_tax_amt = 0 
			END IF 

		END IF 
	END IF 
END FUNCTION 



FUNCTION display_info(inv_idx) 
	DEFINE 
	pr_menunames RECORD LIKE menunames.*, 
	runner CHAR(200), 
	inv_idx, cnt SMALLINT 
	MENU "Information" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J36b","menu-info-2") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Job Detail " 
			" DISPLAY Details of this Job" 
			CALL run_prog("J12",pr_job.job_code,"","","") 
			NEXT option "Exit" 
		COMMAND "Activity Detail " 
			" DISPLAY Details of this Activity" 
			IF pa_inv_line[inv_idx].activity_code IS NOT NULL THEN 
				LET runner = " job.job_code = '", pr_job.job_code clipped, 
				"' AND activity.var_code = '", 
				pa_inv_line[inv_idx].var_code, 
				"' AND activity.activity_code = '", 
				pa_inv_line[inv_idx].activity_code clipped,"'" 
				CALL run_prog("J52",runner,"","","") 
			END IF 
			NEXT option "Exit" 
		COMMAND "Invoice Summary " 
			" DISPLAY Summary of Activity Financials" 
			CALL calc_pcs(inv_idx) 
			NEXT option "Exit" 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Invoicing" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 

FUNCTION calc_pcs(inv_idx) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE 
	ans CHAR(1), 
	inv_idx, cnt SMALLINT 
	OPEN WINDOW j129 with FORM "J129" -- alch kd-747 
	CALL winDecoration_j("J129") -- alch kd-747 
	LET pa_pcs[2].act_bill_amt = 0 
	LET pa_pcs[3].act_bill_amt = 0 
	LET pa_pcs[2].post_cost_amt = 0 
	LET pa_pcs[3].post_cost_amt = 0 
	FOR cnt = 1 TO arr_size 
		IF pa_inv_line[cnt].this_bill_amt IS NULL THEN 
			LET pa_inv_line[cnt].this_bill_amt =0 
		ELSE 
			LET pa_pcs[2].act_bill_amt = pa_pcs[2].act_bill_amt + 
			pa_inv_line[cnt].this_bill_amt 
		END IF 
		IF pa_inv_line[cnt].this_cos_amt IS NULL THEN 
			LET pa_inv_line[cnt].this_cos_amt = 0 
		ELSE 
			LET pa_pcs[2].post_cost_amt = pa_pcs[2].post_cost_amt + 
			pa_inv_line[cnt].this_cos_amt 
		END IF 
		# recalculate new total billed including this invoice
		LET pa_pcs[3].act_bill_amt = pa_pcs[1].act_bill_amt 
		+ pa_pcs[2].act_bill_amt 
		# recalculate new total cost of sales including this invoice
		LET pa_pcs[3].post_cost_amt = pa_pcs[1].post_cost_amt 
		+ pa_pcs[2].post_cost_amt 
	END FOR 
	# recalculate percentages
	# Profit AND Profit %
	# profit = billed_amt - cos_amt,
	LET pa_pcs[3].act_p_l_amt = pa_pcs[3].act_bill_amt - 
	pa_pcs[3].post_cost_amt 
	IF pa_pcs[3].est_bill_amt = 0 THEN 
		LET pa_pcs[3].bill_pc = 0 
	ELSE 
		LET pa_pcs[3].bill_pc = pa_pcs[3].act_bill_amt / 
		pa_pcs[3].est_bill_amt * 100 
	END IF 
	IF pa_pcs[3].act_bill_amt = 0 THEN 
		LET pa_pcs[3].act_p_l_pc = 0 
	ELSE 
		# profit % = profit / billed amt * 100
		LET pa_pcs[3].act_p_l_pc = pa_pcs[3].act_p_l_amt / 
		pa_pcs[3].act_bill_amt * 100 
	END IF 
	IF pa_pcs[3].act_cost_amt = 0 THEN 
		LET pa_pcs[3].cost_pc = 0 
	ELSE 
		LET pa_pcs[3].cost_pc = pa_pcs[3].act_bill_amt / 
		pa_pcs[3].act_cost_amt * 100 
	END IF 
	DISPLAY 
	pa_pcs[1].act_bill_amt, 
	pa_pcs[2].act_bill_amt, 
	pa_pcs[3].act_bill_amt, 
	pa_pcs[1].est_bill_amt, 
	pa_pcs[3].est_bill_amt, 
	pa_pcs[1].bill_pc, 
	pa_pcs[3].bill_pc, 
	pa_pcs[1].act_cost_amt, 
	pa_pcs[3].act_cost_amt, 
	pa_pcs[1].cost_pc, 
	pa_pcs[3].cost_pc, 
	pa_pcs[1].post_cost_amt, 
	pa_pcs[2].post_cost_amt, 
	pa_pcs[3].post_cost_amt, 
	pa_pcs[1].act_p_l_amt, 
	pa_pcs[3].act_p_l_amt, 
	pa_pcs[1].act_p_l_pc, 
	pa_pcs[3].act_p_l_pc 
	TO td_act_bill_amt, 
	this_act_bill_amt, 
	fcst_act_bill_amt, 
	td_bdgt_bill_amt, 
	fcst_bdgt_bill_amt, 
	td_bill_pc, 
	fcst_bill_pc, 
	td_act_cost_amt, 
	fcst_act_cost_amt, 
	td_cost_pc, 
	fcst_cost_pc, 
	td_act_cos_amt, 
	this_act_cos_amt, 
	fcst_act_cos_amt, 
	td_act_p_l_amt, 
	fcst_act_p_l_amt, 
	td_act_p_l_pc, 
	fcst_act_p_l_pc 

	#2706   prompt " Any key TO continue" FOR CHAR ans
	LET msgresp = kandoomsg("U",0001," ") 
	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW j129 
END FUNCTION 


FUNCTION scan_notes(inv_idx) 
	DEFINE 
	idx, 
	scrn, 
	inv_idx, 
	last_note, 
	note_exists SMALLINT 

	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f1 
	WHENEVER ERROR stop 
	FOR idx = 1 TO note_size 
		IF pa_notes[idx].activity_code = pa_inv_line[inv_idx].activity_code 
		AND pa_notes[idx].var_code = pa_inv_line[inv_idx].var_code THEN 
			LET note_exists = true 
			EXIT FOR 
		ELSE 
			LET note_exists = false 
		END IF 
	END FOR 
	OPEN WINDOW j173 with FORM "J173" -- alch kd-747 
	CALL winDecoration_j("J173") -- alch kd-747 
	CALL set_count(note_size) 
	INPUT ARRAY pa_notes WITHOUT DEFAULTS FROM sr_notes.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J36b","input_arr-pa_notes-1") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_notes[idx].note_code IS NULL 
			AND idx != 1 THEN 
				ERROR " There are no more rows in this direction" 
				LET last_note = true 
			ELSE 
				LET last_note = false 
				DISPLAY pa_notes[idx].* TO sr_notes[scrn].* 

				IF note_exists THEN 
					MESSAGE " RETURN TO Edit - ESC TO Continue" 
					attribute(yellow) 
				ELSE 
					MESSAGE " RETURN TO Edit - F1 TO Add - ESC TO Continue" 
					attribute(yellow) 
				END IF 
			END IF 
		BEFORE FIELD var_code 
			IF NOT last_note THEN 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pa_notes[idx].note_code) 
				RETURNING pa_notes[idx].note_code 
				DISPLAY pa_notes[idx].* TO sr_notes[scrn].* 

			END IF 
			NEXT FIELD note_code 
		BEFORE INSERT 
			IF NOT note_exists 
			OR NOT last_note THEN 
				CALL sys_noter(glob_rec_kandoouser.cmpy_code, pa_notes[idx].note_code) 
				RETURNING pa_notes[idx].note_code 
				IF pa_notes[idx].note_code IS NOT NULL THEN 
					LET pa_notes[idx].var_code = 
					pa_inv_line[inv_idx].var_code 
					LET pa_notes[idx].activity_code = 
					pa_inv_line[inv_idx].activity_code 
					LET pa_notes[idx].title_text = 
					pa_inv_line[inv_idx].title_text 
					DISPLAY pa_notes[idx].* TO sr_notes[scrn].* 

					LET note_exists = true 
					MESSAGE " RETURN TO Edit - ESC TO Continue" 
					attribute(yellow) 
				ELSE 
					LET note_exists = false 
					INITIALIZE pa_notes[idx].* TO NULL 
				END IF 
			END IF 
			NEXT FIELD note_code 
		AFTER ROW 
			DISPLAY pa_notes[idx].* TO sr_notes[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	LET note_size = arr_count() 
	CLOSE WINDOW j173 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36 
	WHENEVER ERROR stop 
END FUNCTION 

FUNCTION view_currency( fv_idx, fv_cust, fv_xchange ) 
	DEFINE msgresp LIKE language.yes_flag 
	DEFINE fv_idx SMALLINT, 
	fv_loop SMALLINT, 

	fv_cust LIKE customer.cust_code, 
	fv_currency LIKE customer.currency_code, 
	fv_xchange LIKE rate_exchange.conv_buy_qty, 

	fa_fc_activity array[600] OF RECORD 
		invoice_flag CHAR(1), 
		title_text LIKE activity.title_text, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL( 010, 002 ), 
		this_cos_amt DECIMAL( 010, 002 ) 
	END RECORD, 

	fv_est_cost_amt LIKE activity.est_cost_amt, 
	fv_act_cost_amt LIKE activity.act_cost_amt, 
	fv_est_bill_amt LIKE activity.est_bill_amt, 
	fv_act_bill_amt LIKE activity.act_bill_amt, 
	fv_post_cost_amt LIKE activity.post_cost_amt, 
	fv_post_revenue_amt LIKE activity.post_revenue_amt, 
	fv_tot_bill_amt DECIMAL( 010, 002 ), 
	fv_tot_cos_amt DECIMAL( 010, 002 ) 



	# - First get FC code AND current exchange rate.

	SELECT customer.currency_code 
	INTO fv_currency 
	FROM customer 
	WHERE customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND customer.cust_code = fv_cust 

	# - Now calculate the foreign currency amounts FOR the money fields
	#   as displayed on the currenct SCREEN.

	FOR fv_loop = 001 TO 600 
		IF pa_activity[fv_loop].title_text IS NULL THEN 
			EXIT FOR 
		END IF 
		LET fa_fc_activity[fv_loop].* = pa_activity[fv_loop].* 
		LET fa_fc_activity[fv_loop].this_bill_amt = 
		( pa_activity[fv_loop].this_bill_amt * fv_xchange ) 
		LET fa_fc_activity[fv_loop].this_cos_amt = 
		( pa_activity[fv_loop].this_cos_amt * fv_xchange ) 
	END FOR 

	LET fv_est_cost_amt = ( pa_inv_line[fv_idx].est_cost_amt * fv_xchange ) 
	LET fv_act_cost_amt = ( pa_inv_line[fv_idx].act_cost_amt * fv_xchange ) 
	LET fv_est_bill_amt = ( pa_inv_line[fv_idx].est_bill_amt * fv_xchange ) 
	LET fv_act_bill_amt = ( pa_inv_line[fv_idx].act_bill_amt * fv_xchange ) 
	LET fv_post_cost_amt = ( pa_inv_line[fv_idx].post_cost_amt * fv_xchange ) 
	LET fv_post_revenue_amt = 
	( pa_inv_line[fv_idx].post_revenue_amt * fv_xchange ) 
	LET fv_tot_bill_amt = ( pa_inv_line[fv_idx].this_bill_amt + 
	pa_inv_line[fv_idx].act_bill_amt ) * fv_xchange 

	LET fv_tot_cos_amt = ( pa_inv_line[fv_idx].this_cos_amt + 
	pa_inv_line[fv_idx].post_cost_amt ) * fv_xchange 

	# - Now DISPLAY these FC VALUES TO the form.

	LET msgresp = kandoomsg("J",1424,fv_currency) 
	# MESSAGE 'Foreign Currency View in ', fv_currency clipped,
	#'.    ABORT TO quit' ATTRIBUTE ( YELLOW )


	DISPLAY fv_est_cost_amt, fv_act_cost_amt, fv_est_bill_amt, fv_act_bill_amt, 
	fv_post_cost_amt, fv_post_revenue_amt, fv_tot_bill_amt, fv_tot_cos_amt 
	TO est_cost_amt, act_cost_amt, est_bill_amt, act_bill_amt, 
	post_cost_amt, post_revenue_amt, tot_bill_amt, tot_cos_amt 

	DISPLAY ARRAY fa_fc_activity TO sr_activity.* 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","J31b","display-arr-activity") -- alch kd-506

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	# - Now put the old VALUES back

	LET fv_est_cost_amt = pa_inv_line[fv_idx].est_cost_amt 
	LET fv_act_cost_amt = pa_inv_line[fv_idx].act_cost_amt 
	LET fv_est_bill_amt = pa_inv_line[fv_idx].est_bill_amt 
	LET fv_act_bill_amt = pa_inv_line[fv_idx].act_bill_amt 
	LET fv_post_cost_amt = pa_inv_line[fv_idx].post_cost_amt 
	LET fv_post_revenue_amt = pa_inv_line[fv_idx].post_revenue_amt 

	LET fv_tot_bill_amt = pa_inv_line[fv_idx].this_bill_amt + 
	pa_inv_line[fv_idx].act_bill_amt 

	LET fv_tot_cos_amt = pa_inv_line[fv_idx].this_cos_amt + 
	pa_inv_line[fv_idx].post_cost_amt 

	DISPLAY fv_est_cost_amt, fv_act_cost_amt, fv_est_bill_amt, fv_act_bill_amt, 
	fv_post_cost_amt, fv_post_revenue_amt, fv_tot_bill_amt, fv_tot_cos_amt 
	TO est_cost_amt, act_cost_amt, est_bill_amt, act_bill_amt, 
	post_cost_amt, post_revenue_amt, tot_bill_amt, tot_cos_amt 

	FOR fv_loop = 001 TO 005 
		DISPLAY pa_activity[fv_loop].* TO sr_activity[fv_loop].* 
	END FOR 

END FUNCTION 


