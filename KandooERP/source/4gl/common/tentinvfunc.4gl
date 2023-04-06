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
# \brief module - tentinvfunc.4gl
# Purpose - This program IS a combination of injmdfunc.4gl, invdfunc.4gl,
#           ientwind.4gl AND ishpwind.4gl but modified FOR contract
#           tentinvhead AND tentinvdetl tables


###########################################################################
# Requires
# common/note_disp.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"

FUNCTION tnjmlineshow(p_cmpy,p_cust,p_invnum,p_func_type) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_invnum LIKE tentinvhead.inv_num 
	DEFINE p_func_type CHAR(14)
	DEFINE l_formname CHAR(15)
	DEFINE l_rec_tentinvhead RECORD LIKE tentinvhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_job RECORD LIKE job.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tentinvdetl RECORD LIKE tentinvdetl.*
	DEFINE l_arr_tentinvdetl ARRAY [100] OF RECORD 
		line_text LIKE tentinvdetl.line_text, 
		unit_sale_amt LIKE tentinvdetl.unit_sale_amt, 
		ship_qty LIKE tentinvdetl.ship_qty, 
		unit_cost_amt LIKE tentinvdetl.unit_cost_amt 
	END RECORD 
	DEFINE l_arr_temp_line_num ARRAY[100] OF INTEGER 
	DEFINE l_runner CHAR(250) 
	DEFINE l_wr_desc_text LIKE tax.desc_text 
	DEFINE l_flag SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 

	INITIALIZE l_rec_tentinvdetl.* TO NULL 

	SELECT * 
	INTO l_rec_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND inv_num = p_invnum 

	IF STATUS = NOTFOUND THEN 
		ERROR "Invoice header NOT found" 
	END IF 

	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF STATUS = NOTFOUND THEN 
		ERROR "Customer master NOT found" 
	END IF 

	SELECT * 
	INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_tentinvhead.tax_code 

	SELECT * 
	INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = p_cmpy 
	AND term_code = l_rec_tentinvhead.term_code 

	SELECT * 
	INTO l_rec_job.* 
	FROM job 
	WHERE cmpy_code = p_cmpy 
	AND job_code = l_rec_tentinvhead.job_code 

	OPEN WINDOW wa196 with FORM "A196" 
	CALL windecoration_a("A196") -- albo kd-767 
	DECLARE curser_item CURSOR FOR 
	SELECT tentinvdetl.* 
	INTO l_rec_tentinvdetl.* 
	FROM tentinvdetl 
	WHERE inv_num = l_rec_tentinvhead.inv_num 
	AND cust_code = l_rec_tentinvhead.cust_code 
	AND cmpy_code = p_cmpy 

	LET l_idx = 0 

	FOREACH curser_item 
		LET l_idx = l_idx + 1 
		LET l_arr_tentinvdetl[l_idx].line_text = l_rec_tentinvdetl.line_text 
		LET l_arr_tentinvdetl[l_idx].unit_sale_amt = l_rec_tentinvdetl.unit_sale_amt 
		LET l_arr_tentinvdetl[l_idx].ship_qty = l_rec_tentinvdetl.ship_qty 
		LET l_arr_tentinvdetl[l_idx].unit_cost_amt = l_rec_tentinvdetl.unit_cost_amt 
		LET l_arr_temp_line_num[l_idx] = l_rec_tentinvdetl.line_num 

		IF l_idx > 100 THEN 
			EXIT FOREACH 
		END IF 
	END FOREACH 

	CALL set_count(l_idx) 

	LET l_rec_customer.name_text = l_rec_tentinvhead.name_text 
	LET l_wr_desc_text = l_rec_tax.desc_text 

	MESSAGE "DEL TO EXIT, RETURN FOR details, CTRL N FOR notes" 
	attribute(yellow) 

	DISPLAY BY NAME l_rec_tentinvhead.cust_code, 
	l_rec_customer.name_text, 
	l_rec_customer.cred_bal_amt, 
	l_rec_tentinvhead.job_code, 
	l_rec_job.title_text, 
	l_rec_tentinvhead.term_code, 
	l_rec_term.desc_text, 
	l_rec_tentinvhead.tax_code 
   DISPLAY l_wr_desc_text TO wr_desc_text

	DISPLAY BY NAME l_rec_customer.currency_code 
	attribute(green) 

	DISPLAY BY NAME l_rec_tentinvhead.goods_amt, 
	l_rec_tentinvhead.tax_amt, 
	l_rec_tentinvhead.total_amt 
	attribute (magenta) 

	DISPLAY p_func_type TO func 
	attribute(green) 

	INPUT ARRAY l_arr_tentinvdetl WITHOUT DEFAULTS FROM sr_invoicedetl.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","tentinvfunc","input-arr-tentinvdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 

		ON ACTION "NOTES" --ON KEY (control-n) 
			IF l_arr_tentinvdetl[l_idx].line_text[1,3] = "###" 
			AND l_arr_tentinvdetl[l_idx].line_text[16,18] = "###" THEN 
				CALL note_disp(p_cmpy, l_arr_tentinvdetl[l_idx].line_text[4,15]) 
			ELSE 
				ERROR "No notes TO view" 
			END IF 

		BEFORE FIELD line_total_amt 
			SELECT * 
			INTO l_rec_tentinvdetl.* 
			FROM tentinvdetl 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust 
			AND inv_num = p_invnum 
			AND line_num = l_arr_temp_line_num[l_idx] 
			AND ship_qty = l_arr_tentinvdetl[l_idx].ship_qty 

			MENU "Invoice Details" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","tentinvfunc","menu-Invoice_Details-1") -- albo 

				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 

				COMMAND "Line Details" " View Line Details" 
					CALL invoice_show(l_rec_tentinvdetl.activity_code, 
					l_rec_tentinvdetl.var_code, 
					l_rec_tentinvdetl.line_text, 
					l_rec_tentinvdetl.comp_per, 
					l_rec_tentinvdetl.cmpy_code, 
					l_rec_tentinvdetl.line_acct_code) 

					CURRENT WINDOW IS wa196 

				COMMAND "Summary" " Invoice Summary" 
					CALL calc_pcs(l_rec_job.*, l_rec_tentinvhead.*) 

				COMMAND "Activities" " View Activities" 
					IF l_rec_tentinvdetl.activity_code IS NOT NULL THEN 

						LET l_runner = "\" job.job_code = \\\"", 
						l_rec_tentinvhead.job_code clipped, 
						"\\\" AND activity.var_code = \\\"", 
						l_rec_tentinvdetl.var_code, 
						"\\\" AND activity.activity_code = \\\"", 
						l_rec_tentinvdetl.activity_code clipped, 
						"\\\"", 
						"\"" 
						CALL run_prog("J52",l_runner,"","","") 
					END IF 

				COMMAND "Jobs" " View Jobs" 
					CALL run_prog("J12",l_rec_tentinvhead.job_code,"","","") 

				COMMAND KEY (interrupt,"E") "Exit" " SELECT New Job" 
					LET l_flag = true 
					EXIT MENU 

			END MENU 

			IF l_flag THEN 
				LET l_flag = false 
				EXIT INPUT 
			END IF 

			MESSAGE "DEL TO EXIT, RETURN FOR details, CTRL N FOR notes" 
			attribute(yellow) 
			NEXT FIELD line_text 

		BEFORE DELETE 
			ERROR "This IS a DISPLAY FUNCTION only, delete has no affect on data" 

		BEFORE INSERT 
			ERROR "This IS a DISPLAY FUNCTION only, INSERT has no affect on data" 

		AFTER ROW 
			MESSAGE "DEL TO EXIT, RETURN FOR line details, CTRL N FOR notes" 
			attribute (yellow) 

			INITIALIZE l_rec_tentinvdetl.* TO NULL 
			NEXT FIELD line_text 

	END INPUT 

	CLOSE WINDOW wa196 

END FUNCTION 



FUNCTION invoice_show(p_part,p_var,p_desc1,p_estper,p_cmpy,p_acct) 
	DEFINE p_part LIKE tentinvdetl.activity_code 
	DEFINE p_var LIKE tentinvdetl.var_code 
	DEFINE p_desc1 LIKE tentinvdetl.line_text 
	DEFINE p_estper LIKE tentinvdetl.comp_per 
	DEFINE p_cmpy LIKE tentinvdetl.cmpy_code
	DEFINE p_acct LIKE tentinvdetl.line_acct_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15)
	DEFINE l_rec_tentinvdetl RECORD LIKE tentinvdetl.* 

	LET l_rec_tentinvdetl.activity_code = p_part 
	LET l_rec_tentinvdetl.var_code = p_var 
	LET l_rec_tentinvdetl.line_text = p_desc1 
	LET l_rec_tentinvdetl.comp_per = p_estper 
	LET l_rec_tentinvdetl.line_acct_code = p_acct 

	OPEN WINDOW wa197 with FORM "A197" 
	CALL windecoration_a("A197") -- albo kd-767 

	DISPLAY BY NAME l_rec_tentinvdetl.activity_code, 
	l_rec_tentinvdetl.line_text, 
	l_rec_tentinvdetl.var_code, 
	l_rec_tentinvdetl.comp_per, 
	l_rec_tentinvdetl.line_acct_code 


	LET l_msgresp = kandoomsg("A",7001,"") 
	# prompt "Any Key TO Continue"
	CLOSE WINDOW wa197 

END FUNCTION 

FUNCTION calc_pcs(p_rec_job,p_rec_tentinvhead) 
	DEFINE p_rec_job RECORD LIKE job.*
	DEFINE p_rec_tentinvhead RECORD LIKE tentinvhead.*
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15)
	DEFINE l_rec_detail RECORD 
		activity_code LIKE activity.activity_code , 
		var_code LIKE activity.var_code, 
		est_comp_per LIKE activity.est_comp_per, 
		sort_text LIKE activity.sort_text, 
		bdgt_cost_amt LIKE activity.bdgt_cost_amt, 
		act_cost_amt LIKE activity.act_cost_amt, 
		bdgt_bill_amt LIKE activity.bdgt_bill_amt, 
		act_bill_amt LIKE activity.act_bill_amt, 
		act_cos_amt LIKE activity.post_cost_amt, 
		unit_code LIKE activity.unit_code, 
		bdgt_cost_qty LIKE activity.bdgt_cost_qty, 
		act_cost_qty LIKE activity.act_cost_qty, 
		bdgt_bill_qty LIKE activity.bdgt_bill_qty, 
		act_bill_qty LIKE activity.act_bill_qty, 
		post_revenue_amt LIKE activity.post_revenue_amt 
	END RECORD
	DEFINE l_arr_pcs ARRAY[3] OF RECORD 
		act_bill_amt , 
		bdgt_bill_amt, 
		bill_pc, 
		act_cost_amt, 
		cost_pc DECIMAL, 
		act_cos_amt, 
		act_p_l_amt, 
		act_p_l_pc DECIMAL(16,2) 
	END RECORD 
	DEFINE l_cnt SMALLINT 
	DEFINE l_bill_text CHAR(12) 

	OPEN WINDOW wj153 with FORM "J153" 
	CALL windecoration_j("J153") -- albo kd-767 

	CASE p_rec_job.bill_way_ind 
		WHEN "F" 
			LET l_bill_text = "Fixed Price" 

		WHEN "C" 
			LET l_bill_text = "Cost Plus " 

		WHEN "T" 
			LET l_bill_text = "Time & Mtls" 

		OTHERWISE 
			LET l_bill_text = "Unknown" 
	END CASE 

	DISPLAY l_bill_text TO bill_text 


	LET l_cnt = 1 
	LET l_arr_pcs[1].act_bill_amt = 0 
	LET l_arr_pcs[1].bdgt_bill_amt = 0 
	LET l_arr_pcs[1].bill_pc = 0 
	LET l_arr_pcs[1].act_cost_amt = 0 
	LET l_arr_pcs[1].cost_pc = 0 
	LET l_arr_pcs[1].act_cos_amt = 0 
	LET l_arr_pcs[1].act_p_l_amt = 0 
	LET l_arr_pcs[1].act_p_l_pc = 0 
	LET l_arr_pcs[2].act_bill_amt = 0 
	LET l_arr_pcs[2].act_cos_amt = 0 

	DECLARE c_1 CURSOR FOR 
	SELECT activity_code, var_code, 
	est_comp_per,sort_text, 
	bdgt_cost_amt, act_cost_amt, 
	bdgt_bill_amt, act_bill_amt, 
	post_cost_amt, unit_code, 
	bdgt_cost_qty, act_cost_qty, 
	bdgt_bill_qty, act_bill_qty, 
	post_revenue_amt 
	FROM activity 
	WHERE cmpy_code = p_rec_tentinvhead.cmpy_code 
	AND job_code = p_rec_tentinvhead.job_code 
	AND acct_code IS NOT NULL 
	ORDER BY sort_text, activity_code, var_code 

	FOREACH c_1 INTO l_rec_detail.* 

		# accumulate cost TO DATE, billed TO DATE, budget bill AND cost_billed.
		IF l_rec_detail.act_cost_amt IS NULL THEN 
			LET l_rec_detail.act_cost_amt = 0 
		END IF 

		IF l_rec_detail.act_bill_amt IS NULL THEN 
			LET l_rec_detail.act_bill_amt = 0 
		END IF 

		IF l_rec_detail.bdgt_bill_amt IS NULL THEN 
			LET l_rec_detail.bdgt_bill_amt = 0 
		END IF 

		IF l_rec_detail.act_cos_amt IS NULL THEN 
			LET l_rec_detail.act_cos_amt = 0 
		END IF 

		LET l_arr_pcs[1].act_cost_amt = l_arr_pcs[1].act_cost_amt + 
		l_rec_detail.act_cost_amt 
		LET l_arr_pcs[1].act_bill_amt = l_arr_pcs[1].act_bill_amt + 
		l_rec_detail.act_bill_amt 
		LET l_arr_pcs[1].bdgt_bill_amt = l_arr_pcs[1].bdgt_bill_amt + 
		l_rec_detail.bdgt_bill_amt 
		LET l_arr_pcs[1].act_cos_amt = l_arr_pcs[1].act_cos_amt + 
		l_rec_detail.act_cos_amt 
		LET l_cnt = l_cnt + 1 
	END FOREACH 

	# calculate initial VALUES of the percentage SCREEN

	IF l_arr_pcs[1].bdgt_bill_amt = 0 THEN 
		LET l_arr_pcs[1].bill_pc = 0 
	ELSE 
		LET l_arr_pcs[1].bill_pc = l_arr_pcs[1].act_bill_amt /l_arr_pcs[1].bdgt_bill_amt 
		* 100 
	END IF 

	IF l_arr_pcs[1].act_bill_amt = 0 THEN 
		LET l_arr_pcs[1].act_p_l_pc = 0 
	ELSE 
		LET l_arr_pcs[1].act_p_l_amt = l_arr_pcs[1].act_bill_amt - 
		l_arr_pcs[1].act_cos_amt 
		LET l_arr_pcs[1].act_p_l_pc = l_arr_pcs[1].act_p_l_amt / 
		l_arr_pcs[1].act_bill_amt 
		* 100 
	END IF 

	IF l_arr_pcs[1].act_cost_amt = 0 THEN 
		LET l_arr_pcs[1].cost_pc = 0 
	ELSE 
		LET l_arr_pcs[1].cost_pc = l_arr_pcs[1].act_bill_amt / 
		l_arr_pcs[1].act_cost_amt * 100 
	END IF 

	# recalculate total of billed amounts FROM ARRAY
	# the [2].act_bill_amt IS the net value of this invoice, ie the diff
	# between the previous bill amt AND this bill_amt

	LET l_arr_pcs[2].act_bill_amt = p_rec_tentinvhead.goods_amt 
	LET l_arr_pcs[2].act_cos_amt = p_rec_tentinvhead.cost_amt 

	DISPLAY l_arr_pcs[1].act_bill_amt , 
	l_arr_pcs[2].act_bill_amt, 
	l_arr_pcs[1].bdgt_bill_amt, 
	l_arr_pcs[1].bill_pc , 
	l_arr_pcs[1].act_cost_amt , 
	l_arr_pcs[1].cost_pc , 
	l_arr_pcs[1].act_cos_amt , 
	l_arr_pcs[2].act_cos_amt, 
	l_arr_pcs[1].act_p_l_amt , 
	l_arr_pcs[1].act_p_l_pc 
	TO td_act_bill_amt , 
	this_act_bill_amt , 
	td_bdgt_bill_amt , 
	td_bill_pc , 
	td_act_cost_amt , 
	td_cost_pc , 
	td_act_cos_amt , 
	this_act_cos_amt , 
	td_act_p_l_amt , 
	td_act_p_l_pc 


	LET l_msgresp = kandoomsg("A",7001,"") 
	# prompt "Any Key TO Continue"
	CLOSE WINDOW wj153 

END FUNCTION 



FUNCTION tnarlineshow (p_cmpy,p_cust,p_invnum,p_func_type) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_invnum LIKE tentinvhead.inv_num 
	DEFINE p_func_type CHAR(14)
	DEFINE l_rec_tentinvhead RECORD LIKE tentinvhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_tentinvdetl RECORD LIKE tentinvdetl.* 
	DEFINE pr_customership RECORD LIKE customership.* 
	DEFINE l_arr_tentinvdetl ARRAY [300] OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE tentinvdetl.line_num, 
		part_code LIKE tentinvdetl.part_code, 
		line_text LIKE tentinvdetl.line_text, 
		ship_qty LIKE tentinvdetl.ship_qty, 
		unit_sale_amt LIKE tentinvdetl.unit_sale_amt, 
		line_total_amt LIKE tentinvdetl.line_total_amt 
	END RECORD 
	DEFINE l_arr_temp_line_num ARRAY[300] OF INTEGER 
	DEFINE l_gross_dollar MONEY(12,2) 
	DEFINE l_gross_percent DECIMAL(8,3) 
	DEFINE l_markup_percent DECIMAL(8,3) 
	DEFINE l_inv_desc CHAR(7) 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
 	DEFINE l_formname CHAR(15)
	DEFINE j SMALLINT 	

	SELECT * 
	INTO l_rec_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 
	AND inv_num = p_invnum 

	IF STATUS = NOTFOUND THEN 
		error" Invoice Details do NOT Exist" 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust 

	IF STATUS = NOTFOUND THEN 
		ERROR " Invoiced Customer Details NOT found" 
	END IF 

	IF l_rec_tentinvhead.ship_code IS NOT NULL THEN 
		IF l_rec_tentinvhead.org_cust_code IS NOT NULL THEN 
			SELECT * 
			INTO pr_customership.* 
			FROM customership 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_tentinvhead.org_cust_code 
			AND ship_code = l_rec_tentinvhead.ship_code 

			IF STATUS = NOTFOUND THEN 
				ERROR " Customer Shipping NOT found" 
			END IF 
		ELSE 
			SELECT * 
			INTO pr_customership.* 
			FROM customership 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = l_rec_tentinvhead.cust_code 
			AND ship_code = l_rec_tentinvhead.ship_code 

			IF STATUS = NOTFOUND THEN 
				ERROR " Customer Shipping NOT found" 
			END IF 
		END IF 
	END IF 

	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		ERROR "Arparms RECORD NOT found" 
	END IF 

	LET l_rec_tentinvdetl.ware_code = pr_customership.ware_code 

	OPEN WINDOW A144 with FORM "A144" 
	CALL windecoration_a("A144") -- albo kd-767 

	DECLARE c_invdetl CURSOR FOR 
	SELECT * 
	INTO l_rec_tentinvdetl.* 
	FROM tentinvdetl 
	WHERE inv_num = l_rec_tentinvhead.inv_num 
	AND cust_code = l_rec_tentinvhead.cust_code 
	AND cmpy_code = p_cmpy 

	LET l_idx = 0 

	FOREACH c_invdetl 
		LET l_idx = l_idx + 1 

		IF l_idx = 300 THEN 
			EXIT FOREACH 
		END IF 

		LET l_arr_tentinvdetl[l_idx].part_code = l_rec_tentinvdetl.part_code 
		LET l_arr_tentinvdetl[l_idx].ship_qty = l_rec_tentinvdetl.ship_qty 
		LET l_arr_tentinvdetl[l_idx].line_text = l_rec_tentinvdetl.line_text 
		LET l_arr_tentinvdetl[l_idx].unit_sale_amt = l_rec_tentinvdetl.unit_sale_amt 
		LET l_arr_tentinvdetl[l_idx].line_num = l_rec_tentinvdetl.line_num 


		IF l_rec_tentinvdetl.activity_code IS NOT NULL THEN 
			LET l_arr_tentinvdetl[l_idx].part_code = l_rec_tentinvdetl.activity_code 
		END IF 


		IF l_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_tentinvdetl[l_idx].line_total_amt = 
			l_rec_tentinvdetl.line_total_amt 
		ELSE 
			LET l_arr_tentinvdetl[l_idx].line_total_amt = l_rec_tentinvdetl.ext_sale_amt 
		END IF 

		LET l_arr_temp_line_num[l_idx] = l_rec_tentinvdetl.line_num 
	END FOREACH 

	CALL set_count(l_idx) 
	LET l_rec_customer.name_text = l_rec_tentinvhead.name_text 

	MESSAGE " RETURN FOR line details - CTRL N FOR Notes" 
	attribute(yellow) 

	IF l_rec_tentinvhead.org_cust_code IS NOT NULL THEN 
		DISPLAY l_rec_tentinvhead.org_cust_code TO cust_code 
	ELSE 
		DISPLAY BY NAME l_rec_tentinvhead.cust_code 
	END IF 

	DISPLAY BY NAME l_rec_customer.name_text, 
	l_rec_tentinvdetl.ware_code 


	DISPLAY BY NAME l_rec_customer.currency_code 
	attribute(green) 

	DISPLAY BY NAME l_rec_tentinvhead.goods_amt, 
	l_rec_tentinvhead.tax_amt, 
	l_rec_tentinvhead.total_amt 
	attribute (magenta) 

	INPUT ARRAY l_arr_tentinvdetl WITHOUT DEFAULTS FROM sr_invoicedetl.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","tentinvfunc","input-l_arr_tentinvdetl-1") 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 

		ON KEY (control-t) 
			# work out invoice totals
			LET l_inv_desc = "Total" 
			LET l_gross_dollar = l_rec_tentinvhead.goods_amt -l_rec_tentinvhead.cost_amt 

			IF l_rec_tentinvhead.goods_amt = 0 
			OR l_rec_tentinvhead.goods_amt IS NULL THEN 
				LET l_gross_percent = 0 
			ELSE 
				LET l_gross_percent = ((l_gross_dollar * 100)/ 
				l_rec_tentinvhead.goods_amt) 
			END IF 

			IF l_rec_tentinvhead.cost_amt = 0 
			OR l_rec_tentinvhead.cost_amt IS NULL THEN 
				LET l_markup_percent = 0 
			ELSE 
				LET l_markup_percent = ((l_gross_dollar * 100)/ 
				l_rec_tentinvhead.cost_amt) 
			END IF 

			OPEN WINDOW A142 with FORM "A142" 
			CALL windecoration_a("A142") -- albo kd-767 

			DISPLAY l_inv_desc TO inv_type 
			DISPLAY l_gross_dollar TO gp_dollar 
			DISPLAY l_gross_percent TO gp 
			DISPLAY l_markup_percent TO mu 
			DISPLAY l_rec_tentinvhead.goods_amt TO mats 
			DISPLAY l_rec_tentinvhead.cost_amt TO costs 

			CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 
			CLOSE WINDOW A142 

		ON ACTION "NOTES"  --ON KEY (control-n) 
			IF l_arr_tentinvdetl[l_idx].line_text[1,3] = "###" 
			AND l_arr_tentinvdetl[l_idx].line_text[16,18] = "###" THEN 
				CALL note_disp(p_cmpy,l_arr_tentinvdetl[l_idx].line_text[4,15]) 
			ELSE 
				ERROR "No notes TO view" 
			END IF 

		ON KEY (control-p) 
			SELECT * 
			INTO l_rec_tentinvdetl.* 
			FROM tentinvdetl 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust 
			AND inv_num = p_invnum 
			AND line_num = l_arr_temp_line_num[l_idx] 
			AND ship_qty = l_arr_tentinvdetl[l_idx].ship_qty 

			LET l_inv_desc = "Line" 
			LET l_gross_dollar = l_rec_tentinvdetl.ext_sale_amt - 
			l_rec_tentinvdetl.ext_cost_amt 

			IF l_rec_tentinvdetl.ext_sale_amt = 0 
			OR l_rec_tentinvdetl.ext_sale_amt IS NULL THEN 
				LET l_gross_percent = 0 
			ELSE 
				LET l_gross_percent = ((l_gross_dollar * 100)/ 
				l_rec_tentinvdetl.ext_sale_amt) 
			END IF 

			IF l_rec_tentinvdetl.ext_cost_amt = 0 
			OR l_rec_tentinvdetl.ext_cost_amt IS NULL THEN 
				LET l_markup_percent = 0 
			ELSE 
				LET l_markup_percent = ((l_gross_dollar * 100)/ 
				l_rec_tentinvdetl.ext_cost_amt) 
			END IF 

			OPEN WINDOW wa1421 with FORM "A142" 
			CALL windecoration_a("A142") -- albo kd-767 

			DISPLAY l_inv_desc TO inv_type 
			DISPLAY l_gross_dollar TO gp_dollar 
			DISPLAY l_gross_percent TO gp 
			DISPLAY l_markup_percent TO mu 
			DISPLAY l_rec_tentinvdetl.ext_sale_amt TO mats 
			DISPLAY l_rec_tentinvdetl.ext_cost_amt TO costs 

			CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 
			# prompt "Any Key TO Continue"
			CLOSE WINDOW wa1421 

		BEFORE FIELD line_num 
			SELECT * 
			INTO l_rec_tentinvdetl.* 
			FROM tentinvdetl 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust 
			AND inv_num = p_invnum 
			AND line_num = l_arr_temp_line_num[l_idx] 
			AND ship_qty = l_arr_tentinvdetl[l_idx].ship_qty 

			# pop up the window AND show the info...

			CALL ar_inv_show(l_rec_tentinvdetl.part_code, 
			l_rec_tentinvdetl.ship_qty, 
			l_rec_tentinvdetl.line_text, 
			l_rec_tentinvdetl.unit_sale_amt, 
			l_rec_tentinvdetl.ware_code, 
			l_rec_tentinvdetl.uom_code, 
			l_rec_tentinvdetl.unit_tax_amt, 
			l_rec_tentinvdetl.line_total_amt, 
			p_cmpy, 
			l_rec_tentinvdetl.line_acct_code) 
			NEXT FIELD scroll_flag 

		BEFORE DELETE 
			ERROR "This IS a DISPLAY FUNCTION only, delete has no affect on data" 

		BEFORE INSERT 
			ERROR "This IS a DISPLAY FUNCTION only, INSERT has no affect on data" 

		AFTER ROW 
			MESSAGE "DEL TO EXIT, RETURN FOR line details, CTRL N FOR notes" 
			attribute (yellow) 
			INITIALIZE l_rec_tentinvdetl.* TO NULL 


	END INPUT 

	CLOSE WINDOW A144 
	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 

FUNCTION ar_inv_show(p_part,p_qshi,p_desc1,p_unpr,p_ware,p_uoms,p_untax,p_ltot,p_cmpy,p_acct) 
	DEFINE p_part LIKE tentinvdetl.part_code 
	DEFINE p_qshi LIKE tentinvdetl.ship_qty 
	DEFINE p_desc1 LIKE tentinvdetl.line_text 
	DEFINE p_unpr LIKE tentinvdetl.unit_sale_amt 
	DEFINE p_ware LIKE tentinvdetl.ware_code 
	DEFINE p_uoms LIKE tentinvdetl.uom_code 
	DEFINE p_untax LIKE tentinvdetl.unit_tax_amt 
	DEFINE p_ltot LIKE tentinvdetl.line_total_amt 
	DEFINE p_cmpy LIKE tentinvdetl.cmpy_code
	DEFINE p_acct LIKE tentinvdetl.line_acct_code 
 	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_tentinvdetl RECORD LIKE tentinvdetl.* 
	DEFINE l_formname CHAR(15)

	LET l_rec_tentinvdetl.part_code = p_part 
	LET l_rec_tentinvdetl.ship_qty = p_qshi 
	LET l_rec_tentinvdetl.line_text = p_desc1 
	LET l_rec_tentinvdetl.unit_sale_amt = p_unpr 
	LET l_rec_tentinvdetl.ware_code = p_ware 
	LET l_rec_tentinvdetl.uom_code = p_uoms 
	LET l_rec_tentinvdetl.unit_tax_amt = p_untax 
	LET l_rec_tentinvdetl.line_total_amt = p_ltot 
	LET l_rec_tentinvdetl.line_acct_code = p_acct 

	SELECT * 
	INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part 
	AND ware_code = p_ware 

	SELECT * 
	INTO l_rec_arparms.* 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		ERROR "Arparms RECORD NOT found" 
	END IF 

	OPEN WINDOW A145 with FORM "A145" 
	CALL windecoration_a("A145") -- albo kd-767 

	IF l_rec_arparms.show_tax_flag = "Y" THEN 
		DISPLAY BY NAME l_rec_tentinvdetl.part_code, 
		l_rec_tentinvdetl.ship_qty, 
		l_rec_tentinvdetl.line_text, 
		l_rec_tentinvdetl.level_code, 
		l_rec_tentinvdetl.unit_sale_amt, 
		l_rec_tentinvdetl.unit_tax_amt, 
		l_rec_tentinvdetl.line_total_amt 

		DISPLAY l_rec_prodstatus.list_amt TO 
		list_price_amt 

	ELSE 
		DISPLAY BY NAME l_rec_tentinvdetl.part_code, 
		l_rec_tentinvdetl.ship_qty, 
		l_rec_tentinvdetl.line_text, 
		l_rec_tentinvdetl.level_code, 
		l_rec_tentinvdetl.unit_sale_amt, 
		l_rec_tentinvdetl.line_total_amt 

		DISPLAY l_rec_prodstatus.list_amt TO 
		list_price_amt 

	END IF 

	DISPLAY BY NAME l_rec_tentinvdetl.ware_code 
	attribute(yellow) 

	OPEN WINDOW A104 with FORM "A104" 
	CALL windecoration_a("A104") -- albo kd-767 

	LET l_rec_coa.acct_code = l_rec_tentinvdetl.line_acct_code 
	DISPLAY l_rec_coa.acct_code TO coa.acct_code
	DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text 


	CALL eventsuspend() # LET ans = kandoomsg("U",1,"") 
	# prompt "Any Key TO Continue"
	CLOSE WINDOW A104 
	CLOSE WINDOW A145 

END FUNCTION 

FUNCTION show_inv_entry(p_cmpy,p_inv_num) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_inv_num LIKE tentinvhead.inv_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15)
	DEFINE l_rec_tentinvhead RECORD LIKE tentinvhead.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_temp_text CHAR(30) 

	SELECT inv_ref1_text 
	INTO l_ref_text 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		ERROR " AR Parameters do NOT Exist - Refer Menu AZP " 
		SLEEP 4 
		EXIT program 
	ELSE 
		LET l_temp_text = l_ref_text clipped,"..........." 
		LET l_ref_text = l_temp_text 
	END IF 

	SELECT * 
	INTO l_rec_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 

	IF STATUS = NOTFOUND THEN 
		ERROR " Invoice Details do NOT Exist " 
		SLEEP 2 
		RETURN 
	END IF 

	SELECT warehouse.ware_code, warehouse.desc_text 
	INTO l_rec_warehouse.ware_code, l_rec_warehouse.desc_text 
	FROM warehouse, customership 
	WHERE warehouse.cmpy_code = p_cmpy 
	AND customership.cmpy_code = p_cmpy 
	AND customership.ware_code = warehouse.ware_code 
	AND customership.ship_code = l_rec_tentinvhead.ship_code 

	SELECT name_text 
	INTO l_rec_salesperson.name_text 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = l_rec_tentinvhead.sale_code 

	SELECT desc_text 
	INTO l_rec_term.desc_text 
	FROM term 
	WHERE cmpy_code = p_cmpy 
	AND term_code = l_rec_tentinvhead.term_code 

	SELECT desc_text 
	INTO l_rec_tax.desc_text 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_tentinvhead.tax_code 

	OPEN WINDOW A139 with FORM "A139" 
	CALL windecoration_a("A139") -- albo kd-767 

	DISPLAY l_ref_text TO inv_ref1_text 
	DISPLAY BY NAME l_rec_tentinvhead.purchase_code, 
	l_rec_tentinvhead.entry_code, 
	l_rec_tentinvhead.inv_date, 
	l_rec_tentinvhead.conv_qty, 
	l_rec_tentinvhead.currency_code, 
	l_rec_warehouse.ware_code, 
	l_rec_tentinvhead.sale_code, 
	l_rec_salesperson.name_text, 
	l_rec_tentinvhead.term_code, 
	l_rec_tentinvhead.tax_code, 
	l_rec_tentinvhead.job_code, 
	l_rec_tentinvhead.year_num, 
	l_rec_tentinvhead.period_num 


	DISPLAY l_rec_warehouse.desc_text, 
	l_rec_term.desc_text, 
	l_rec_tax.desc_text 
	TO warehouse.desc_text, 
	term.desc_text, 
	tax.desc_text 


	LET l_msgresp = kandoomsg("A",7001,"") 
	# prompt "Any Key TO Continue"
	CLOSE WINDOW A139 

END FUNCTION 



FUNCTION show_inv_ship(p_cmpy,p_inv_num) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_inv_num LIKE tentinvhead.inv_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_formname CHAR(15)
	DEFINE l_rec_tentinvhead RECORD LIKE tentinvhead.* 

	SELECT * 
	INTO l_rec_tentinvhead.* 
	FROM tentinvhead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 

	IF STATUS = NOTFOUND THEN 
		error" Invoice Details do NOT Exist " 
		SLEEP 2 
		RETURN 
	END IF 

	OPEN WINDOW A212 with FORM "A212" 
	CALL windecoration_a("A212") -- albo kd-767 

	DISPLAY BY NAME l_rec_tentinvhead.ship_code, 
	l_rec_tentinvhead.name_text, 
	l_rec_tentinvhead.addr1_text, 
	l_rec_tentinvhead.addr2_text, 
	l_rec_tentinvhead.city_text, 
	l_rec_tentinvhead.state_code, 
	l_rec_tentinvhead.post_code, 
	l_rec_tentinvhead.country_code, --@db-patch_2020_10_04--
	l_rec_tentinvhead.fob_text, 
	l_rec_tentinvhead.prepaid_flag, 
	l_rec_tentinvhead.contact_text, 
	l_rec_tentinvhead.tele_text, 
	l_rec_tentinvhead.ship1_text, 
	l_rec_tentinvhead.ship2_text 

	DISPLAY l_rec_tentinvhead.ship_date TO 
	despatch_date 


	LET l_msgresp = kandoomsg("A",7001,"") 
	# prompt "Any Key TO Continue"
	CLOSE WINDOW A212 

END FUNCTION 


