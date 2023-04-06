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




# Purpose - Invoice edit - allow selection of additional lines

GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J36_GLOBALS.4gl" 


DEFINE 
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
y SMALLINT, 
add_arr_size SMALLINT 


FUNCTION get_new_line() 

	DEFINE 
	pa_select array[600] OF RECORD 
		invoice_flag CHAR(1), 
		title_text LIKE activity.title_text, 
		this_bill_amt DECIMAL(10,2), 
		this_bill_qty DECIMAL(10,2), 
		this_cos_amt DECIMAL(10,2) 
	END RECORD, 

	get_markup SMALLINT, 
	where_text CHAR(100), 
	select_text CHAR(1200), 
	pr_sort_text LIKE activity.sort_text, 
	tmp_idx, 
	add_idx, scrn SMALLINT, 

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
	cont SMALLINT 
	OPEN WINDOW j182 with FORM "J182" -- alch kd-747 
	CALL winDecoration_j("J182") -- alch kd-747 
	DELETE FROM addbill WHERE 1=1; 

	CLEAR FORM 

	LET add_arr_size = arr_size 

	FOR add_idx = 1 TO add_arr_size 
		INITIALIZE pa_select[add_idx].* TO NULL 
	END FOR 

	WHILE true 
		CLEAR FORM 
		DISPLAY BY NAME pr_job.job_code, 
		pr_job.title_text, 
		pr_customer.cust_code, 
		pr_customer.name_text 
		MESSAGE " Enter Activity Selection Criteria - ESC TO continue" 
		attribute(yellow) 
		CONSTRUCT BY NAME where_text ON 
		activity.var_code, 
		activity.activity_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","J36c","const_activity-1") -- alch kd-506 
			ON ACTION "WEB-HELP" -- albo kd-373 
				CALL onlinehelp(getmoduleid(),null) 
		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW j182 
			RETURN false 
		END IF 

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
		"AND acct_code IS NOT NULL ", 
		"AND ",where_text clipped, 
		"ORDER BY sort_text, activity_code, var_code " 

		PREPARE activity_query FROM select_text 
		DECLARE c_1 CURSOR FOR activity_query 

		LET get_markup = true 
		LET add_arr_size = 0 
		LET add_idx = 1 

		FOREACH c_1 INTO 
			pa_inv_select[add_idx].activity_code, 
			pa_inv_select[add_idx].var_code, 
			pa_inv_select[add_idx].est_comp_per, 
			pr_sort_text, 
			pa_inv_select[add_idx].title_text, 
			pa_inv_select[add_idx].est_cost_amt, 
			pa_inv_select[add_idx].act_cost_amt, 
			pa_inv_select[add_idx].est_bill_amt, 
			pa_inv_select[add_idx].act_bill_amt, 
			pa_inv_select[add_idx].post_cost_amt, 
			pa_inv_select[add_idx].unit_code, 
			pa_inv_select[add_idx].est_cost_qty, 
			pa_inv_select[add_idx].act_cost_qty, 
			pa_inv_select[add_idx].est_bill_qty, 
			pa_inv_select[add_idx].act_bill_qty, 
			pa_inv_select[add_idx].post_revenue_amt, 
			pa_inv_select[add_idx].bill_way_ind, 
			pa_inv_select[add_idx].cost_alloc_flag, 
			pa_inv_select[add_idx].acct_code 
			IF pa_inv_select[add_idx].est_bill_qty IS NULL THEN 
				LET pa_inv_select[add_idx].est_bill_qty = 0 
			END IF 
			IF pa_inv_select[add_idx].act_bill_qty IS NULL THEN 
				LET pa_inv_select[add_idx].act_bill_qty = 0 
			END IF 
			IF pa_inv_select[add_idx].est_cost_amt IS NULL THEN 
				LET pa_inv_select[add_idx].est_cost_amt = 0 
			END IF 
			IF pa_inv_select[add_idx].act_cost_amt IS NULL THEN 
				LET pa_inv_select[add_idx].act_cost_amt = 0 
			END IF 
			IF pa_inv_select[add_idx].est_bill_amt IS NULL THEN 
				LET pa_inv_select[add_idx].est_bill_amt = 0 
			END IF 
			IF pa_inv_select[add_idx].act_bill_amt IS NULL THEN 
				LET pa_inv_select[add_idx].act_bill_amt = 0 
			END IF 
			IF pa_inv_select[add_idx].post_cost_amt IS NULL THEN 
				LET pa_inv_select[add_idx].post_cost_amt = 0 
			END IF 

			CALL add_alloc(add_idx) RETURNING 
			pa_inv_select[add_idx].this_bill_qty, 
			pa_inv_select[add_idx].this_bill_amt, 
			pa_inv_select[add_idx].this_cos_amt 

			IF pr_job.bill_way_ind = "R" THEN 
				IF pa_inv_select[add_idx].this_bill_amt = 0 AND 
				pa_inv_select[add_idx].this_cos_amt = 0 THEN 
					INITIALIZE pa_inv_select[add_idx].* TO NULL 
					CONTINUE FOREACH 
				END IF 
			ELSE 
				IF pa_inv_select[add_idx].this_bill_qty = 0 AND 
				pa_inv_select[add_idx].this_bill_amt = 0 AND 
				pa_inv_select[add_idx].this_cos_amt = 0 THEN 
					INITIALIZE pa_inv_select[add_idx].* TO NULL 
					CONTINUE FOREACH 
				END IF 
			END IF 

			LET pa_inv_select[add_idx].invoice_flag = "*" 
			LET pa_select[add_idx].invoice_flag = "*" 
			LET pa_select[add_idx].title_text = 
			pa_inv_select[add_idx].title_text 
			LET pa_select[add_idx].this_bill_qty = 
			pa_inv_select[add_idx].this_bill_qty 
			LET pa_select[add_idx].this_bill_amt = 
			pa_inv_select[add_idx].this_bill_amt 
			LET pa_select[add_idx].this_cos_amt = 
			pa_inv_select[add_idx].this_cos_amt 

			LET add_arr_size = add_arr_size + 1 
			IF add_idx = 600 THEN 
				ERROR " Only first 600 activities selected" 
				SLEEP 5 
				EXIT FOREACH 
			ELSE 
				LET add_idx = add_idx + 1 
			END IF 
		END FOREACH 

		IF add_arr_size = 0 THEN 
			error" No Activities Selected - DEL TO Re-SELECT" 
			SLEEP 5 
		END IF 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	MESSAGE "F7 SELECT Invoice - F10 Information" attribute(yellow) 

	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	OPTIONS INSERT KEY f36 
	WHENEVER ERROR stop 

	CALL set_count (add_arr_size) 

	INPUT ARRAY pa_select WITHOUT DEFAULTS FROM sr_activity.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J36c","input_arr-pa_select-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET add_idx = arr_curr() 
			LET scrn = scr_line() 
			IF pa_inv_select[add_idx].activity_code IS NULL THEN 
				ERROR " No further Invoice lines Available " 
				NEXT FIELD invoice_flag 
			END IF 
			DISPLAY pa_select[add_idx].* TO sr_activity[scrn].* 

			CALL disp_line_detail1(add_idx, scrn) 

		ON KEY (F7) 
			IF pa_select[add_idx].invoice_flag IS NULL THEN 
				LET pa_select[add_idx].invoice_flag = "*" 
			ELSE 
				LET pa_select[add_idx].invoice_flag = NULL 
			END IF 
			DISPLAY pa_select[add_idx].* TO sr_activity[scrn].* 


		ON KEY (F10) 
			CALL display_info1(add_idx) 
			MESSAGE "RETURN FOR more info ", 
			"F7 SELECT Invoice - F10 Information" attribute(yellow) 

		BEFORE FIELD title_text 
			IF show_alloc(add_idx) THEN 
				LET pa_select[add_idx].this_bill_qty = 
				pa_inv_select[add_idx].this_bill_qty 
				LET pa_select[add_idx].this_bill_amt = 
				pa_inv_select[add_idx].this_bill_amt 
				LET pa_select[add_idx].this_cos_amt = 
				pa_inv_select[add_idx].this_cos_amt 
			ELSE 
				LET pa_inv_select[add_idx].this_bill_qty = 
				pa_select[add_idx].this_bill_qty 
				LET pa_inv_select[add_idx].this_bill_amt = 
				pa_select[add_idx].this_bill_amt 
				LET pa_inv_select[add_idx].this_cos_amt = 
				pa_select[add_idx].this_cos_amt 
			END IF 
			DISPLAY pa_select[add_idx].* TO sr_activity[scrn].* 

			CALL disp_line_detail1(add_idx, scrn) 
			NEXT FIELD invoice_flag 

		AFTER ROW 
			LET pa_inv_select[add_idx].invoice_flag = 
			pa_select[add_idx].invoice_flag 
			DISPLAY pa_select[add_idx].* 
			TO sr_activity[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW j182 
		RETURN false 
	END IF 

	# include pa_inv_select ARRAY INTO the pa_inv_line array

	LET tmp_idx = max_array + 1 

	FOR x = 1 TO add_arr_size 

		IF pa_inv_select[x].invoice_flag IS NULL THEN 
			CONTINUE FOR 
		END IF 

		# check IF the line IS already on the invoice
		# AND IF so THEN add TO the existing line

		LET cont = false 

		FOR y = 1 TO max_array 
			IF pa_inv_select[x].activity_code = 
			pa_inv_line[y].activity_code AND 
			pa_inv_select[x].var_code = pa_inv_line[y].var_code THEN 
				# SELECT all addbills FOR the existing line AND add them
				# INTO the line



























				LET pa_inv_line[y].this_bill_amt = 
				pa_inv_line[y].this_bill_amt + 
				pa_inv_select[x].this_bill_amt 
				LET pa_inv_line[y].this_bill_qty = 
				pa_inv_line[y].this_bill_qty + 
				pa_inv_select[x].this_bill_qty 
				LET pa_inv_line[y].this_cos_amt = pa_inv_line[y].this_cos_amt + 
				pa_inv_select[x].this_cos_amt 

				LET pa_activity[y].this_bill_qty = 
				pa_activity[y].this_bill_qty + 
				pa_inv_select[x].this_bill_qty 
				LET pa_activity[y].this_bill_amt = 
				pa_activity[y].this_bill_amt + 
				pa_inv_select[x].this_bill_amt 
				LET pa_activity[y].this_cos_amt = 
				pa_activity[y].this_cos_amt + 
				pa_inv_select[x].this_cos_amt 

				LET pa_inv_line[y].acct_code = pa_inv_select[x].acct_code 









				DECLARE add_curs1 CURSOR FOR 
				SELECT * 
				FROM addbill 
				WHERE activity_code = pa_inv_select[x].activity_code 
				AND var_code = pa_inv_select[x].var_code 
				AND trans_invoice_flag IS NOT NULL 

				FOREACH add_curs1 INTO pr_addbill.* 

					INSERT INTO tempbill VALUES (pr_addbill.*) 

					LET pr_addbill.trans_invoice_flag = NULL 
					INSERT INTO editbill VALUES (pr_addbill.*) 

				END FOREACH 

				LET cont = true 
				EXIT FOR 

			END IF 
		END FOR 

		IF cont THEN 
			LET cont = false 
			CONTINUE FOR 
		END IF 

		DECLARE add_curs CURSOR FOR 
		SELECT * 
		FROM addbill 
		WHERE activity_code = pa_inv_select[x].activity_code 
		AND var_code = pa_inv_select[x].var_code 
		AND trans_invoice_flag IS NOT NULL 

		FOREACH add_curs INTO pr_addbill.* 

			INSERT INTO tempbill VALUES (pr_addbill.*) 

			LET pr_addbill.trans_invoice_flag = NULL 
			INSERT INTO editbill VALUES (pr_addbill.*) 

		END FOREACH 

		# code FROM here on adds completely new lines TO the array

		LET pa_inv_select[x].invoice_flag = NULL 

		LET pa_inv_line[tmp_idx].* = pa_inv_select[x].* 

		IF pa_inv_line[tmp_idx].est_bill_qty IS NULL THEN 
			LET pa_inv_line[tmp_idx].est_bill_qty = 0 
		END IF 
		IF pa_inv_line[tmp_idx].act_bill_qty IS NULL THEN 
			LET pa_inv_line[tmp_idx].act_bill_qty = 0 
		END IF 
		IF pa_inv_line[tmp_idx].est_cost_amt IS NULL THEN 
			LET pa_inv_line[tmp_idx].est_cost_amt = 0 
		END IF 
		IF pa_inv_line[tmp_idx].act_cost_amt IS NULL THEN 
			LET pa_inv_line[tmp_idx].act_cost_amt = 0 
		END IF 
		IF pa_inv_line[tmp_idx].est_bill_amt IS NULL THEN 
			LET pa_inv_line[tmp_idx].est_bill_amt = 0 
		END IF 
		IF pa_inv_line[tmp_idx].act_bill_amt IS NULL THEN 
			LET pa_inv_line[tmp_idx].act_bill_amt = 0 
		END IF 
		IF pa_inv_line[tmp_idx].post_cost_amt IS NULL THEN 
			LET pa_inv_line[tmp_idx].post_cost_amt = 0 
		END IF 

		LET pa_pcs[1].act_cost_amt = pa_pcs[1].act_cost_amt + 
		pa_inv_line[tmp_idx].act_cost_amt 
		LET pa_pcs[1].act_bill_amt = pa_pcs[1].act_bill_amt + 
		pa_inv_line[tmp_idx].act_bill_amt 
		LET pa_pcs[1].est_bill_amt = pa_pcs[1].est_bill_amt + 
		pa_inv_line[tmp_idx].est_bill_amt 
		LET pa_pcs[1].post_cost_amt = pa_pcs[1].post_cost_amt + 
		pa_inv_line[tmp_idx].post_cost_amt 

		LET pa_activity[tmp_idx].invoice_flag = NULL 
		LET pa_activity[tmp_idx].title_text = pa_inv_line[tmp_idx].title_text 
		LET pa_activity[tmp_idx].this_bill_qty = 
		pa_inv_line[tmp_idx].this_bill_qty 
		LET pa_activity[tmp_idx].this_bill_amt = 
		pa_inv_line[tmp_idx].this_bill_amt 
		LET pa_activity[tmp_idx].this_cos_amt = 
		pa_inv_line[tmp_idx].this_cos_amt 

		# save the current state of invoice FOR later reversing
		LET ps_activity[tmp_idx].* = pa_activity[tmp_idx].* 
		LET ps_activity[tmp_idx].this_bill_amt = 0 
		LET ps_activity[tmp_idx].this_bill_qty = 0 
		LET ps_activity[tmp_idx].this_cos_amt = 0 

		LET arr_size = arr_size + 1 
		LET idx = idx + 1 
		LET tmp_idx = tmp_idx + 1 

	END FOR 

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

	DELETE FROM addbill WHERE 1=1; 

	CLOSE WINDOW j182 

	RETURN true 

END FUNCTION 


FUNCTION disp_line_detail1(idx, scrn) 
	DEFINE 
	pr_tot_bill_amt, 
	pr_tot_bill_qty, 
	pr_tot_cos_amt DECIMAL(16,2), 
	pr_bill_text CHAR(12), 
	idx, scrn SMALLINT 

	CASE pa_inv_select[idx].bill_way_ind 
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
	DISPLAY BY NAME 
	pa_inv_select[idx].activity_code, 
	pa_inv_select[idx].var_code, 
	pa_inv_select[idx].est_comp_per 
END FUNCTION 


FUNCTION display_info1(inv_idx) 
	DEFINE 
	pr_menunames RECORD LIKE menunames.*, 
	runner CHAR(200), 
	inv_idx, cnt SMALLINT 

	MENU "Information" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","J36c","menu-info-3") -- alch kd-506 
		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 
		COMMAND "Job Detail " " DISPLAY Details of this Job" 
			CALL run_prog("J12",pr_job.job_code,"","","") 
			NEXT option "Exit" 
		COMMAND "Activity Detail " " DISPLAY Details of this Activity" 
			IF pa_inv_line[inv_idx].activity_code IS NOT NULL THEN 
				LET runner = " job.job_code = '", pr_job.job_code clipped, 
				"' AND activity.var_code = '", 
				pa_inv_line[inv_idx].var_code, 
				"' AND activity.activity_code = '", 
				pa_inv_line[inv_idx].activity_code clipped,"'" 
				CALL run_prog("J52",runner,"","","") 
			END IF 
			NEXT option "Exit" 
		COMMAND "Invoice Summary " " DISPLAY Summary of Activity Financials" 
			CALL calc_pcs(inv_idx) 
			NEXT option "Exit" 
		COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Invoicing" 
			EXIT MENU 
		COMMAND KEY (control-w) 
			CALL kandoohelp("") 
	END MENU 
END FUNCTION 


FUNCTION add_alloc(inv_idx) 
	# Generates a tempbill table rows FOR given glob_rec_kandoouser.cmpy_code, job, var,
	# AND activity.
	# A row IS created in tempbill FOR each unpaid transaction.
	# An unpaid transaction IS a jobledger row WHERE the sum of
	# resbill qty's are NOT equal TO the jobledger trans_qty.
	# Is only Used FOR T&M AND Cost Plus but IS created FOR all
	# Fixed Price use the table as an inquiry facility.
	DEFINE 
	pr_resbill RECORD 
		apply_qty DECIMAL(15,3), 
		apply_amt DECIMAL(16,2), 
		apply_cos_amt DECIMAL(16,2) 
	END RECORD, 
	pr_line_tot_qty DECIMAL(15,3), 
	pr_line_tot_bill DECIMAL(16,2), 
	pr_line_tot_cos DECIMAL(16,2), 
	fv_cost LIKE activity.post_cost_amt, 
	inv_idx SMALLINT, 
	str CHAR (300) 

	LET pr_line_tot_qty = 0 
	LET pr_line_tot_bill = 0 
	LET pr_line_tot_cos = 0 



	DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with OUTER" 
	DISPLAY "see jm/J36c.4gl" 
	EXIT program (1) 



	LET str = 
	" SELECT jobledger.*, sum(apply_qty), ", 
	" sum(apply_amt), ", 
	" sum(apply_cos_amt) ", 
	" FROM jobledger, ", 
	" outer resbill ", 
	" WHERE jobledger.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
	" AND jobledger.job_code = ", pr_job.job_code, 
	" AND jobledger.var_code = ", pa_inv_select[inv_idx].var_code, 
	" AND jobledger.activity_code = ", 
	pa_inv_select[inv_idx].activity_code, 
	" AND resbill.cmpy_code = ", glob_rec_kandoouser.cmpy_code, 
	" AND resbill.job_code = jobledger.job_code ", 
	" AND resbill.var_code = jobledger.var_code ", 
	" AND resbill.activity_code = jobledger.activity_code ", 
	" AND resbill.seq_num = jobledger.seq_num ", 
	" group by jobledger.cmpy_code, ", 
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
	" jobledger.allocation_ind " 

	PREPARE bfr FROM str 
	DECLARE jl_c CURSOR FOR bfr 

	FOREACH jl_c INTO pr_jobledger.*, pr_resbill.apply_qty, 
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















		IF (pr_resbill.apply_qty != pr_jobledger.trans_qty) OR 
		(pr_job.bill_way_ind = "R" AND 
		(pr_resbill.apply_amt != pr_jobledger.charge_amt OR 
		pr_resbill.apply_cos_amt != pr_jobledger.trans_amt))then 
			LET pr_addbill.trans_invoice_flag = "*" 
			LET pr_addbill.trans_date = pr_jobledger.trans_date 
			LET pr_addbill.trans_source_num = 
			pr_jobledger.trans_source_num 
			LET pr_addbill.trans_type_ind = pr_jobledger.trans_type_ind 
			LET pr_addbill.var_code = pr_jobledger.var_code 
			LET pr_addbill.activity_code = pr_jobledger.activity_code 
			LET pr_addbill.trans_source_text = 
			pr_jobledger.trans_source_text 
			LET pr_addbill.seq_num = pr_jobledger.seq_num 
			LET pr_addbill.trans_qty = pr_jobledger.trans_qty 
			LET pr_addbill.line_num = NULL 
			LET pr_addbill.trans_amt = pr_jobledger.trans_amt 

			IF pr_job.bill_way_ind = "R" THEN 
				LET pr_addbill.apply_qty = pr_jobledger.trans_qty 
			ELSE 
				LET pr_addbill.apply_qty = pr_jobledger.trans_qty 
				- pr_resbill.apply_qty 
			END IF 
			LET pr_addbill.apply_cos_amt = pr_jobledger.trans_amt 
			- pr_resbill.apply_cos_amt 
			IF pa_inv_select[inv_idx].bill_way_ind = "C" THEN 
				LET pr_addbill.apply_amt = pr_addbill.apply_cos_amt 
				* ((pr_job.markup_per/100) + 1) 
			ELSE 
				LET pr_addbill.apply_amt = pr_jobledger.charge_amt 
				- pr_resbill.apply_amt 
			END IF 
			LET pr_addbill.charge_amt = pr_jobledger.charge_amt 
			IF pr_jobledger.desc_text IS NULL 
			OR pr_jobledger.desc_text = " " THEN 
				SELECT desc_text 
				INTO pr_addbill.desc_text 
				FROM jmresource 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND res_code = pr_jobledger.trans_source_text 
			ELSE 
				LET pr_addbill.desc_text = pr_jobledger.desc_text 
			END IF 

			IF pr_job.bill_way_ind = "R" THEN 
				IF pr_resbill.apply_qty > 0 THEN 
					LET pr_addbill.prev_apply_qty = pr_addbill.apply_qty 
				ELSE 
					LET pr_addbill.prev_apply_qty = 0 
				END IF 
			ELSE 
				LET pr_addbill.prev_apply_qty = pr_resbill.apply_qty 
			END IF 
			LET pr_addbill.prev_apply_amt = pr_resbill.apply_amt 
			LET pr_addbill.prev_apply_cos_amt = 
			pr_resbill.apply_cos_amt 

			# don't want TO add the same res billing twice
			SELECT * 
			FROM tempbill 
			WHERE var_code = pr_addbill.var_code 
			AND activity_code = pr_addbill.activity_code 
			AND seq_num = pr_addbill.seq_num 
			IF NOT status THEN 
				CONTINUE FOREACH 
			END IF 

			INSERT INTO addbill VALUES (pr_addbill.*) 

			LET pr_line_tot_qty = pr_line_tot_qty 
			+ pr_addbill.apply_qty 
			LET pr_line_tot_bill = pr_line_tot_bill 
			+ pr_addbill.apply_amt 
			LET pr_line_tot_cos = pr_line_tot_cos 
			+ pr_addbill.apply_cos_amt 
		END IF 
	END FOREACH 
	CASE 
		WHEN pa_inv_select[inv_idx].bill_way_ind = "T" 
			OR pa_inv_select[inv_idx].bill_way_ind = "C" 

			OR pa_inv_select[inv_idx].bill_way_ind = "R" 
			RETURN pr_line_tot_qty, 
			pr_line_tot_bill, 
			pr_line_tot_cos 
		WHEN pa_inv_select[inv_idx].bill_way_ind = "F" 
			# Add cost allocation processing
			CASE (pa_inv_select[inv_idx].cost_alloc_flag) 
				WHEN "1" 
					LET fv_cost = ((pa_inv_select[inv_idx].est_comp_per * 
					pa_inv_select[inv_idx].est_cost_amt /100) - 
					pa_inv_select[inv_idx].post_cost_amt) 

				WHEN "2" 
					LET fv_cost = ((pa_inv_select[inv_idx].est_comp_per * 
					pa_inv_select[inv_idx].est_cost_amt /100) - 
					pa_inv_select[inv_idx].post_cost_amt) 
					IF pa_inv_select[inv_idx].est_comp_per = 100 THEN 
						LET fv_cost = pa_inv_select[inv_idx].act_cost_amt - 
						pa_inv_select[inv_idx].post_cost_amt 
					END IF 

				WHEN "3" 
					LET fv_cost = ((pa_inv_select[inv_idx].est_comp_per * 
					pa_inv_select[inv_idx].act_cost_amt /100) - 
					pa_inv_select[inv_idx].post_cost_amt) 
				WHEN "4" 
					LET fv_cost = pa_inv_select[inv_idx].act_cost_amt - 
					pa_inv_select[inv_idx].post_cost_amt 

				WHEN "5" 
					LET fv_cost = 0 

				OTHERWISE 
					LET fv_cost = 0 
			END CASE 
			return((pa_inv_select[inv_idx].est_comp_per * 
			pa_inv_select[inv_idx].est_bill_qty /100) - 
			pa_inv_select[inv_idx].act_bill_qty), 
			((pa_inv_select[inv_idx].est_comp_per * 
			pa_inv_select[inv_idx].est_bill_amt /100) - 
			pa_inv_select[inv_idx].act_bill_amt), 
			fv_cost 



		OTHERWISE 
			RETURN 0,0,0 
	END CASE 
END FUNCTION 



FUNCTION show_alloc(inv_idx) 

	DEFINE 
	pr_trans_source_text CHAR(8), 
	bill_idx, idx, scrn, cnt, 
	inv_idx SMALLINT 

	DECLARE ea_c1 CURSOR FOR 
	SELECT addbill.* 
	FROM addbill 
	WHERE var_code = pa_inv_select[inv_idx].var_code 
	AND activity_code = pa_inv_select[inv_idx].activity_code 
	ORDER BY seq_num 

	LET bill_idx = 0 
	FOREACH ea_c1 INTO pr_addbill.* 
		LET bill_idx = bill_idx + 1 
		LET pa_resbill[bill_idx].trans_invoice_flag = 
		pr_addbill.trans_invoice_flag 
		LET pa_resbill[bill_idx].trans_type_ind = 
		pr_addbill.trans_type_ind 
		LET pa_resbill[bill_idx].trans_date = pr_addbill.trans_date 
		LET pa_resbill[bill_idx].trans_source_text = 
		pr_addbill.trans_source_text 
		LET pa_resbill[bill_idx].apply_qty = pr_addbill.apply_qty 
		LET pa_resbill[bill_idx].apply_cos_amt = pr_addbill.apply_cos_amt 
		LET pa_resbill[bill_idx].apply_amt = pr_addbill.apply_amt 
		LET pa_seq_num[bill_idx] = pr_addbill.seq_num 
		IF bill_idx = 1000 THEN 
			error" First 1000 Outstanding Transactions Selected FOR this Activity " 
			SLEEP 2 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF bill_idx = 0 THEN 
		error" No Outstanding Transactions exist FOR this Activity" 
		SLEEP 3 
		RETURN false 
	END IF 
	OPEN WINDOW j154 with FORM "J154" -- alch kd-747 
	CALL winDecoration_j("J154") -- alch kd-747 
	DISPLAY pa_inv_select[inv_idx].this_bill_qty, 
	pa_inv_select[inv_idx].this_bill_amt, 
	pa_inv_select[inv_idx].this_cos_amt 
	TO this_bill_qty, 
	this_bill_amt, 
	this_cos_amt 

	MESSAGE " RETURN TO Edit Billing - F7 Toggle Transaction FOR Invoice" 
	attribute(yellow) 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	CALL set_count(bill_idx) 
	INPUT ARRAY pa_resbill WITHOUT DEFAULTS FROM sr_tempbill.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J36c","input_arr-pa_resbill-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY pa_resbill[idx].* 
			TO sr_tempbill[scrn].* 

		BEFORE FIELD trans_type_ind 
			IF get_detail1(pa_seq_num[idx], inv_idx) THEN 
				LET pa_resbill[idx].apply_qty = pr_addbill.apply_qty 
				LET pa_resbill[idx].apply_amt = pr_addbill.apply_amt 
				LET pa_resbill[idx].apply_cos_amt = 
				pr_addbill.apply_cos_amt 
				DISPLAY pa_resbill[idx].apply_qty, 
				pa_resbill[idx].apply_amt, 
				pa_resbill[idx].apply_cos_amt 
				TO sr_tempbill[scrn].apply_qty, 
				sr_tempbill[scrn].apply_amt, 
				sr_tempbill[scrn].apply_cos_amt 
				CALL evaluate_totals1(bill_idx) 
				RETURNING pa_inv_select[inv_idx].this_bill_qty, 
				pa_inv_select[inv_idx].this_bill_amt, 
				pa_inv_select[inv_idx].this_cos_amt 
			END IF 
			NEXT FIELD trans_invoice_flag 
		BEFORE INSERT 
			ERROR " No Further Transactions" 
		AFTER ROW 
			DISPLAY pa_resbill[idx].* 
			TO sr_tempbill[scrn].* 

		ON KEY (F7) 
			IF pa_resbill[idx].trans_invoice_flag IS NULL THEN 
				LET pa_resbill[idx].trans_invoice_flag = "*" 
			ELSE 
				LET pa_resbill[idx].trans_invoice_flag = NULL 
			END IF 
			DISPLAY pa_resbill[idx].trans_invoice_flag 
			TO sr_tempbill[scrn].trans_invoice_flag 

			CALL evaluate_totals1(bill_idx) 
			RETURNING pa_inv_select[inv_idx].this_bill_qty, 
			pa_inv_select[inv_idx].this_bill_amt, 
			pa_inv_select[inv_idx].this_cos_amt 
			NEXT FIELD trans_invoice_flag 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j154 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		error" Invoice Reverted TO previous VALUES" 
		RETURN false 
	END IF 
	IF pa_inv_select[inv_idx].bill_way_ind = "F" THEN 
		ERROR " Fixed Price Activity - Billing Edits Ignored" 
		RETURN false 
	END IF 
	FOR idx = 1 TO bill_idx 
		UPDATE addbill 
		SET (trans_invoice_flag, 
		apply_qty, 
		apply_amt, 
		apply_cos_amt) 
		= 
		(pa_resbill[idx].trans_invoice_flag, 
		pa_resbill[idx].apply_qty, 
		pa_resbill[idx].apply_amt, 
		pa_resbill[idx].apply_cos_amt) 
		WHERE var_code = pa_inv_select[inv_idx].var_code 
		AND activity_code = pa_inv_select[inv_idx].activity_code 
		AND seq_num = pa_seq_num[idx] 
	END FOR 
	RETURN true 
END FUNCTION 


FUNCTION evaluate_totals1(idx) 
	DEFINE 
	pr_this_bill_amt DECIMAL(16,2), 
	pr_this_cos_amt DECIMAL(16,2), 
	pr_this_bill_qty DECIMAL(15,3), 
	cnt, idx SMALLINT 

	LET pr_this_bill_amt = 0 
	LET pr_this_bill_qty = 0 
	LET pr_this_cos_amt = 0 
	FOR cnt = 1 TO idx 
		IF pa_resbill[cnt].trans_invoice_flag = "*" THEN 
			LET pr_this_bill_qty = pr_this_bill_qty + 
			pa_resbill[cnt].apply_qty 
			LET pr_this_bill_amt = pr_this_bill_amt + 
			pa_resbill[cnt].apply_amt 
			LET pr_this_cos_amt = pr_this_cos_amt + 
			pa_resbill[cnt].apply_cos_amt 
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


FUNCTION get_detail1(pr_seq_num, inv_idx) 
	DEFINE 
	pr_seq_num INTEGER, 
	inv_idx SMALLINT, 
	pr_tran_total RECORD 
		tot_apply_qty LIKE resbill.apply_qty, 
		tot_apply_amt LIKE resbill.apply_amt, 
		tot_apply_cos_amt LIKE resbill.apply_cos_amt 
	END RECORD 

	SELECT addbill.* 
	INTO pr_addbill.* 
	FROM addbill 
	WHERE var_code = pa_inv_select[inv_idx].var_code 
	AND activity_code = pa_inv_select[inv_idx].activity_code 
	AND seq_num = pr_seq_num 
	IF pr_tempbill.desc_text IS NULL 
	OR (pr_tempbill.desc_text clipped = " ") THEN 
		SELECT desc_text 
		INTO pr_tempbill.desc_text 
		FROM jmresource 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND res_code = pr_tempbill.trans_source_text 
	END IF 
	OPEN WINDOW j155 with FORM "J155" -- alch kd-747 
	CALL winDecoration_j("J155") -- alch kd-747 
	DISPLAY BY NAME pr_addbill.seq_num, 
	pr_addbill.trans_date, 
	pr_addbill.trans_type_ind, 
	pr_addbill.trans_source_num, 
	pr_addbill.desc_text, 
	pr_addbill.trans_source_text, 
	pr_addbill.trans_qty, 
	pr_addbill.charge_amt, 
	pr_addbill.trans_amt, 
	pr_addbill.apply_qty, 
	pr_addbill.apply_amt, 
	pr_addbill.apply_cos_amt, 
	pr_addbill.prev_apply_qty, 
	pr_addbill.prev_apply_amt, 
	pr_addbill.prev_apply_cos_amt 


	IF pr_job.bill_way_ind = "R" THEN 
		LET pr_tran_total.tot_apply_qty = pr_addbill.apply_qty 
	ELSE 
		LET pr_tran_total.tot_apply_qty = pr_addbill.prev_apply_qty 
		+ pr_addbill.apply_qty 
	END IF 
	LET pr_tran_total.tot_apply_amt = pr_addbill.prev_apply_amt 
	+ pr_addbill.apply_amt 
	LET pr_tran_total.tot_apply_cos_amt = pr_addbill.prev_apply_cos_amt 
	+ pr_addbill.apply_cos_amt 
	DISPLAY BY NAME pr_tran_total.tot_apply_qty, 
	pr_tran_total.tot_apply_amt, 
	pr_tran_total.tot_apply_cos_amt 

	INPUT BY NAME pr_addbill.desc_text, 
	pr_addbill.apply_qty, 
	pr_addbill.apply_amt, 
	pr_addbill.apply_cos_amt 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J36c","input-pr_addbill-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD desc_text 

			IF pr_invoicehead.bill_issue_ind = "2" OR 
			pr_invoicehead.bill_issue_ind = "4" THEN 
				MESSAGE 
				" Edit the Transaction Description FOR Invoice Printing" 
				attribute(yellow) 
			ELSE 
				MESSAGE "Enter New Billing - ESC TO Accept - DEL TO Exit" 
				attribute(yellow) 
				NEXT FIELD apply_qty 
			END IF 
		AFTER FIELD desc_text 
			MESSAGE "Enter New Billing - ESC TO Accept - DEL TO Exit" 
			attribute(yellow) 

		BEFORE FIELD apply_qty 
			IF pr_job.bill_way_ind = "R" THEN 
				NEXT FIELD apply_amt 
			END IF 
		AFTER FIELD apply_qty 
			LET pr_tran_total.tot_apply_qty = pr_addbill.prev_apply_qty 
			+ pr_addbill.apply_qty 
			DISPLAY BY NAME pr_tran_total.tot_apply_qty 


		BEFORE FIELD apply_amt 
			IF pr_job.bill_way_ind = "C" THEN 
				NEXT FIELD apply_cos_amt 
			END IF 

		AFTER FIELD apply_amt 
			LET pr_tran_total.tot_apply_amt = pr_addbill.prev_apply_amt 
			+ pr_addbill.apply_amt 
			DISPLAY BY NAME pr_tran_total.tot_apply_amt 


		AFTER FIELD apply_cos_amt 
			IF pr_job.bill_way_ind = "C" THEN 
				LET pr_tempbill.apply_amt = pr_addbill.apply_cos_amt 
				* ((pr_job.markup_per/100) + 1) 
				DISPLAY BY NAME pr_addbill.apply_amt 
				LET pr_tran_total.tot_apply_amt = pr_addbill.prev_apply_amt 
				+ pr_addbill.apply_amt 
				DISPLAY BY NAME pr_tran_total.tot_apply_amt 

			END IF 
			LET pr_tran_total.tot_apply_cos_amt = 
			pr_tempbill.prev_apply_cos_amt 
			+ pr_tempbill.apply_cos_amt 
			DISPLAY BY NAME pr_tran_total.tot_apply_cos_amt 

			LET pr_tran_total.tot_apply_cos_amt = 
			pr_addbill.prev_apply_cos_amt 
			+ pr_addbill.apply_cos_amt 
			DISPLAY BY NAME pr_tran_total.tot_apply_cos_amt 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CLOSE WINDOW j155 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		ERROR " Transaction Reverted TO previous value" 
		RETURN false 
	END IF 

	IF pr_invoicehead.bill_issue_ind = "2" OR 
	pr_invoicehead.bill_issue_ind = "4" THEN 
		UPDATE addbill 
		SET desc_text = pr_addbill.desc_text 
		WHERE var_code = pa_inv_line[inv_idx].var_code 
		AND activity_code = pa_inv_line[inv_idx].activity_code 
		AND seq_num = pr_seq_num 
	END IF 
	RETURN true 
END FUNCTION 
