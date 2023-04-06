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


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JC1a.4gl - FUNCTION JC1_header()
# Purpose - JM credit entry - cull FROM A41f.4gl
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JC1_GLOBALS.4gl" 

FUNCTION JC1_header() 
	DEFINE 
	pr_warehouse RECORD LIKE warehouse.*, 
	pr_glparms RECORD LIKE glparms.*, 
	pr_credreas RECORD LIKE credreas.*, 
	mask_code LIKE account.acct_code, 
	save_conv LIKE credithead.conv_qty, 
	temp_text CHAR(32), 
	ref_text LIKE arparms.credit_ref1_text, 
	pr_structure RECORD LIKE structure.*, 
	enter_seg CHAR(1), 
	i, 
	j, 
	x SMALLINT, 
	acct_override_code LIKE account.acct_code, 
	conv_flag, 
	failed_it SMALLINT, 
	acct_desc_text LIKE coa.desc_text, 
	entry_flag SMALLINT 

	CALL display_customer() 
	LET pr_credithead.currency_code = pr_customer.currency_code 
	DISPLAY BY NAME pr_customer.currency_code 
	attribute (green) 
	IF pv_corp_cust THEN 
		LET pr_credithead.cust_code = pr_customer.corp_cust_code 
		LET pr_credithead.org_cust_code = pr_customer.cust_code 
		LET pr_credithead.currency_code = pr_corp_cust.currency_code 
	ELSE 
		LET pr_credithead.cust_code = pr_customer.cust_code 
		LET pr_credithead.currency_code = pr_customer.currency_code 
	END IF 
	SELECT * INTO pr_arparms.* 
	FROM arparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("A",7005,"") 
		#ERROR "AR Parameters NOT found"
		EXIT program 
	END IF 
	LET temp_text = pr_arparms.credit_ref1_text clipped, 
	"................" 
	LET ref_text = temp_text 
	OPEN WINDOW wa128 with FORM "J200" -- alch kd-747 
	CALL winDecoration_j("J200") -- alch kd-747 
	DISPLAY ref_text TO credit_ref1_text 
	SELECT * INTO pr_salesperson.* 
	FROM salesperson 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND sale_code = pr_credithead.sale_code 
	INITIALIZE pr_tax.* TO NULL 
	SELECT * INTO pr_tax.* 
	FROM tax 
	WHERE tax.tax_code = pr_credithead.tax_code 
	AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT * INTO pr_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_warehouse.ware_code 
	LET save_conv = pr_credithead.conv_qty 
	LET pr_creditdetl.ware_code = pr_warehouse.ware_code 
	DISPLAY BY NAME pr_creditdetl.ware_code, 
	pr_credithead.cred_date, 
	pr_credithead.entry_code, 
	pr_credithead.year_num, 
	pr_credithead.period_num, 
	pr_credithead.conv_qty, 
	pr_credithead.job_code, 
	pr_credithead.cred_text, 
	pr_credithead.sale_code, 
	pr_salesperson.name_text, 
	pr_credithead.tax_code 
	DISPLAY pr_tax.desc_text TO tax.desc_text 
	DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 

	DISPLAY BY NAME pr_credithead.currency_code 
	attribute (green) 
	INPUT BY NAME pr_credithead.cred_date, 
	pr_credithead.year_num, 
	pr_credithead.period_num, 
	pr_credithead.cred_text, 
	pr_credithead.conv_qty, 
	pr_credithead.job_code, 
	pr_credithead.reason_code, 
	pr_credithead.sale_code, 
	pr_credithead.tax_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","JC1a","input-pr_credithead-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield(sale_code) 
					LET pr_credithead.sale_code = show_sale(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_credithead.sale_code 

					NEXT FIELD sale_code 
				WHEN infield(tax_code) 
					LET pr_credithead.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME pr_credithead.tax_code 

					NEXT FIELD tax_code 
				WHEN infield(reason_code) 
					#FUNCTION show_credreas(p_cmpy,p_filter_where2_text,p_def_reason_code)
					LET pr_credithead.reason_code = show_credreas(glob_rec_kandoouser.cmpy_code,NULL,pr_credithead.reason_code) 
					DISPLAY BY NAME pr_credithead.reason_code 

					NEXT FIELD reason_code 
			END CASE 

		ON KEY (control-c) --customer details / customer invoice submenu 
			CALL cinq_clnt(glob_rec_kandoouser.cmpy_code, pr_customer.cust_code) 
			NEXT FIELD job_code 

		AFTER FIELD cred_date --customer details / customer invoice submenu 
			IF pr_credithead.cred_date IS NULL THEN 
				LET msgresp = kandoomsg("J",9458,0) 
				LET pr_credithead.cred_date = today 
				DISPLAY BY NAME pr_credithead.cred_date 

				NEXT FIELD cred_date 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_credithead.cred_date) 
			RETURNING pr_credithead.year_num, 
			pr_credithead.period_num 
			IF conv_flag 
			AND save_conv = pr_credithead.conv_qty THEN 
				CALL get_conv_rate(glob_rec_kandoouser.cmpy_code, pr_credithead.currency_code, 
				pr_credithead.cred_date , "S") 
				RETURNING pr_credithead.conv_qty 
				LET save_conv = pr_credithead.conv_qty 
			END IF 
			DISPLAY BY NAME pr_credithead.year_num, 
			pr_credithead.period_num, 
			pr_credithead.conv_qty 

		AFTER FIELD period_num 
			CALL valid_period(
				glob_rec_kandoouser.cmpy_code, 
				pr_credithead.year_num, 
				pr_credithead.period_num, 
				LEDGER_TYPE_AR ) 
			RETURNING 
				pr_credithead.year_num, 
				pr_credithead.period_num, 
				failed_it 
			IF failed_it = 1 THEN 
				NEXT FIELD year_num 
			END IF 
		
		AFTER FIELD conv_qty 
			SELECT * INTO pr_glparms.* 
			FROM glparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND key_code = "1" 
			IF pr_glparms.base_currency_code = pr_credithead.currency_code 
			AND pr_credithead.conv_qty != 1.0 THEN 
				LET pr_credithead.conv_qty = 1.0 
				DISPLAY BY NAME pr_credithead.conv_qty 

				LET msgresp = kandoomsg("J",9479,"") 
				#ERROR " Rate cannot be altered foreign currency does NOT apply "
				NEXT FIELD conv_qty 
			END IF 
			IF NOT conv_flag 
			AND save_conv != pr_credithead.conv_qty THEN 
				LET pr_credithead.conv_qty = save_conv 
				DISPLAY BY NAME pr_credithead.conv_qty 

				LET msgresp = kandoomsg("J",9478,"") 
				#ERROR " Rate cannot be altered "
				NEXT FIELD conv_qty 
			END IF 
			IF pr_credithead.conv_qty IS NULL THEN 
				LET msgresp = kandoomsg("J",9477,"") 
				#ERROR " Exchange Rate must have a value "
				NEXT FIELD conv_qty 
			END IF 
			IF pr_credithead.conv_qty < 0 THEN 
				#ERROR " Exchange Rate must be greater than zero "
				LET msgresp = kandoomsg("J",9476,"") 
				NEXT FIELD conv_qty 
			END IF 
		AFTER FIELD reason_code 
			IF pr_credithead.reason_code IS NOT NULL THEN 
				SELECT reason_text INTO pr_credreas.reason_text 
				FROM credreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND reason_code = pr_credithead.reason_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp=kandoomsg("A",9058,"") 
					#9058" credit reason do NOT exist "
					NEXT FIELD reason_code 

				END IF 
				DISPLAY BY NAME pr_credithead.reason_code, 
				pr_credreas.reason_text 


			END IF 

		AFTER FIELD sale_code 
			SELECT name_text INTO pr_salesperson.name_text 
			FROM salesperson 
			WHERE sale_code = pr_credithead.sale_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				#ERROR "Salesperson NOT found, try again"
				LET msgresp = kandoomsg("A",9032,"") 
				NEXT FIELD sale_code 
			ELSE 
				DISPLAY BY NAME pr_salesperson.name_text 

			END IF 
			LET ret_flag = ret_flag + 1 
		AFTER FIELD tax_code 
			IF pr_credithead.tax_code IS NULL THEN 
				#ERROR " Must enter a tax code, try window"
				LET msgresp = kandoomsg("A",9128,"") 
				NEXT FIELD tax_code 
			ELSE 
				SELECT * INTO pr_tax.* 
				FROM tax 
				WHERE tax.tax_code = pr_credithead.tax_code 
				AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					#ERROR "Tax Code NOT found, try window"
					LET msgresp = kandoomsg("A",9130,"") 
					NEXT FIELD tax_code 
				END IF 
			END IF 
			DISPLAY BY NAME pr_tax.desc_text 

			LET ret_flag = ret_flag + 1 
		AFTER INPUT 
			IF NOT (int_flag 
			OR quit_flag) THEN 
				IF pr_credithead.cred_date IS NULL THEN 
					LET pr_credithead.cred_date = today 
					CALL db_period_what_period(
						glob_rec_kandoouser.cmpy_code, 
						pr_credithead.cred_date) 
					RETURNING 
						pr_credithead.year_num, 
						pr_credithead.period_num 
				END IF 
				
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					pr_credithead.year_num, 
					pr_credithead.period_num , 
					LEDGER_TYPE_AR) 
				RETURNING 
					pr_credithead.year_num, 
					pr_credithead.period_num, 
					failed_it 
				
				IF failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 
				
				SELECT name_text INTO pr_salesperson.name_text 
				FROM salesperson 
				WHERE sale_code = pr_credithead.sale_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("A",9032,"") 
					#ERROR "Salesperson NOT found, try again"
					NEXT FIELD sale_code 
				ELSE 
					DISPLAY BY NAME pr_salesperson.name_text 

				END IF 
				IF pr_credithead.tax_code IS NULL THEN 
					LET msgresp = kandoomsg("A",9128,"") 
					#ERROR " Must enter a tax code, try window"
					NEXT FIELD tax_code 
				ELSE 
					SELECT * INTO pr_tax.* 
					FROM tax 
					WHERE tax.tax_code = pr_credithead.tax_code 
					AND tax.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("A",9130,"") 
						#ERROR "Tax Code NOT found, try window"
						NEXT FIELD tax_code 
					END IF 
				END IF 
				DISPLAY BY NAME pr_tax.desc_text 

				LET pr_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF f_type = "C" THEN 
					LET pr_credithead.entry_date = today 
				END IF 
				LET pr_credithead.tax_per = pr_tax.tax_per 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = 0 
		LET quit_flag = 0 
		CLOSE WINDOW wa128 

		RETURN false 
	END IF 

	CLOSE WINDOW wa128 

	LET pr_credithead.hand_tax_code = pr_credithead.tax_code 

	LET pr_credithead.freight_tax_code = pr_credithead.tax_code 
	# get default of patch code FROM creditdetl

	LET patch_code = ps_creditdetl[1].line_acct_code 
	WHILE true 
		IF pv_corp_cust THEN 
			SELECT acct_mask_code INTO mask_code 
			FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_corp_cust.type_code 
			IF status = notfound 
			OR mask_code IS NULL 
			OR mask_code = " " THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
				RETURNING mask_code 
			END IF 
		ELSE 
			SELECT acct_mask_code INTO mask_code 
			FROM customertype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = pr_customer.type_code 
			IF status = notfound 
			OR mask_code IS NULL 
			OR mask_code = " " THEN 
				CALL build_mask(glob_rec_kandoouser.cmpy_code, "??????????????????", " ") 
				RETURNING mask_code 
			END IF 
		END IF 
		CALL build_mask(glob_rec_kandoouser.cmpy_code, mask_code, pr_credithead.acct_override_code) 
		RETURNING pr_credithead.acct_override_code 
		SELECT acct_mask_code INTO acct_override_code 
		FROM kandoouser 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sign_on_code = glob_rec_kandoouser.sign_on_code 
		IF status = notfound 
		OR acct_override_code IS NULL 
		OR acct_override_code = " " THEN 
			LET msgresp = kandoomsg("J",7020,"") 
			#ERROR " User account mask code invalid, maintain menu U12"
			EXIT program 
		END IF 
		CALL build_mask(glob_rec_kandoouser.cmpy_code, pr_credithead.acct_override_code, acct_override_code) 
		RETURNING pr_credithead.acct_override_code 
		LET enter_seg = "N" 
		DECLARE struct_cur CURSOR FOR 
		SELECT * INTO pr_structure.* 
		FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND start_num > 0 
		AND type_ind = "S" 
		FOREACH struct_cur 
			LET i = pr_structure.start_num 
			LET j = pr_structure.length_num 
			LET x = 0 
			FOR x = i TO (i + j) 
				IF pr_credithead.acct_override_code[x] = "?" THEN 
					LET enter_seg = "Y" 
					EXIT FOR 
				END IF 
			END FOR 
			IF enter_seg = "Y" THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF enter_seg = "Y" THEN 
			CALL acct_fill(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, "JC1", mask_code, 
			pr_credithead.acct_override_code , 
			4, "Credit Account Mask") 
			RETURNING pr_credithead.acct_override_code, 
			acct_desc_text, 
			entry_flag 
		END IF 
		IF enter_seg = "N" 
		AND pr_arparms.show_seg_flag = "Y" THEN 
			CALL acct_fill(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code, "JC1", pr_credithead.acct_override_code, 
			pr_credithead.acct_override_code , 4, "Credit Account Mask") 
			RETURNING pr_credithead.acct_override_code, 
			acct_desc_text, 
			entry_flag 
		END IF 
		LET patch_code = pr_credithead.acct_override_code 
		IF int_flag 
		OR quit_flag THEN 

			LET int_flag = 0 
			LET quit_flag = 0 
			RETURN false 
		END IF 

		WHENEVER ERROR CONTINUE 
		IF NOT valid_trans_num(glob_rec_kandoouser.cmpy_code, TRAN_TYPE_CREDIT_CR, patch_code) THEN 
			IF status = -284 THEN 
				LET msgresp = kandoomsg("A",9516,"") 
				#ERROR "Invalid numbering - Review Menu GZD"
				EXIT program 
			ELSE 

				WHENEVER ERROR stop 
				# " Invalid Segment FOR Automatic Transaction Numbering "
				LET msgresp = kandoomsg("J",7021,"") 
				EXIT WHILE 
			END IF 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 


	RETURN true 
END FUNCTION 


FUNCTION display_customer() 
	DEFINE 
	balance_amt, 
	cred_avail_amt LIKE customer.bal_amt, 
	fr_customer RECORD LIKE customer.* 

	IF pv_corp_cust 
	AND pr_customer.inv_addr_flag = "C" THEN 
		LET fr_customer.* = pr_corp_cust.* 
	ELSE 
		LET fr_customer.* = pr_customer.* 
	END IF 
	IF NOT pv_corp_cust THEN 
		SELECT * INTO fr_customer.* 
		FROM customer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_customer.corp_cust_code 
		IF pr_credithead.org_cust_code IS NOT NULL THEN 
			SELECT * INTO pr_corp_cust.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_credithead.org_cust_code 
			IF pr_corp_cust.inv_addr_flag != "C" THEN 
				LET fr_customer.* = pr_corp_cust.* 
			END IF 
		END IF 
	END IF 
	SELECT * INTO pr_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = pr_customer.term_code 
	LET balance_amt = pr_customer.bal_amt 
	LET cred_avail_amt = pr_customer.cred_limit_amt - 
	pr_customer.bal_amt - 
	pr_customer.onorder_amt 
	DISPLAY BY NAME pr_customer.cust_code, 
	fr_customer.name_text, 
	fr_customer.addr1_text, 
	fr_customer.addr2_text, 
	fr_customer.city_text, 
	fr_customer.state_code, 
	fr_customer.post_code, 
	fr_customer.country_code, --@db-patch_2020_10_04--
	pr_customer.curr_amt, 
	pr_customer.over1_amt, 
	pr_customer.over30_amt, 
	pr_customer.over60_amt, 
	pr_customer.over90_amt, 
	pr_customer.bal_amt, 
	pr_customer.cred_limit_amt, 
	balance_amt, 
	pr_customer.onorder_amt, 
	cred_avail_amt, 
	pr_term.desc_text 

END FUNCTION 



FUNCTION get_jm_info() 
	DEFINE 
	idx, 
	get_markup SMALLINT, 
	where_text CHAR(100), 
	select_text CHAR(1200), 
	pr_sort_text LIKE activity.sort_text, 
	save_activity, 
	tmp_activity LIKE activity.activity_code, 
	save_var, 
	tmp_var LIKE activity.var_code 

	IF int_flag 
	OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	DELETE 
	FROM tempbill 
	WHERE 1 = 1 
	FOR idx = 1 TO arr_size 
		INITIALIZE pa_cred_line[idx].* TO NULL 
		INITIALIZE pa_activity[idx].* TO NULL 
		INITIALIZE ps_activity[idx].* TO NULL 
	END FOR 
	LET select_text = "SELECT sort_text, ", 
	" activity.activity_code, ", 
	" activity.var_code, ", 
	" invoicedetl.* ", 
	"FROM invoicedetl, outer activity ", 
	"WHERE invoicedetl.cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
	"AND invoicedetl.cust_code = \"", 
	pr_invoicehead.cust_code, "\" ", 
	"AND invoicedetl.inv_num = ", pr_invoicehead.inv_num, 
	" ", 
	" AND activity.cmpy_code = invoicedetl.cmpy_code ", 
	"AND activity.job_code = \"", pr_job.job_code, "\" ", 
	"AND activity.var_code = invoicedetl.var_code ", 
	"AND activity.activity_code = ", 
	" invoicedetl.activity_code ", 
	"ORDER BY invoicedetl.line_num " 
	PREPARE line_sel 
	FROM select_text 
	DECLARE line_curs CURSOR FOR line_sel 
	LET get_markup = true 
	LET arr_size = 0 
	LET load_idx = 0 
	LET idx = 1 
	LET save_activity = " " 
	LET save_var = -1 
	FOREACH line_curs INTO pr_sort_text, 
		tmp_activity, 
		tmp_var, 
		pr_invoicedetl.* 
		# SET up the ps_creditdetl array
		CALL setup_creditdetl() 
		# don't get financial details FOR heading lines
		IF tmp_activity IS NULL THEN 
			CONTINUE FOREACH 
		END IF 
		# only need TO SET up tempbill once FOR an activity/variation
		# combination
		IF tmp_activity = save_activity 
		AND tmp_var = save_var THEN 
			CONTINUE FOREACH 
		END IF 
		LET save_activity = tmp_activity 
		LET save_var = tmp_var 
		LET arr_size = load_idx 
		LET select_text = "SELECT activity_code,", 
		" var_code,", 
		" est_comp_per,", 
		" sort_text,", 
		" title_text,", 
		" bdgt_cost_amt,", 
		" act_cost_amt,", 
		" bdgt_bill_amt,", 
		" act_bill_amt,", 
		" post_cost_amt,", 
		" unit_code,", 
		" bdgt_cost_qty,", 
		" act_cost_qty,", 
		" bdgt_bill_qty,", 
		" act_bill_qty,", 
		" post_revenue_amt,", 
		" bill_way_ind ", 
		"FROM activity ", 
		"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
		"AND job_code = \"", pr_job.job_code, "\" ", 
		"AND acct_code IS NOT NULL ", 
		"AND var_code = ", pr_invoicedetl.var_code, 
		" ", "AND activity_code = \"", 
		pr_invoicedetl.activity_code, "\" " 
		PREPARE activity_query 
		FROM select_text 
		DECLARE c_1 CURSOR FOR activity_query 
		OPEN c_1 
		FETCH c_1 INTO pa_cred_line[idx].activity_code, 
		pa_cred_line[idx].var_code, 
		pa_cred_line[idx].est_comp_per, 
		pr_sort_text, 
		pa_cred_line[idx].title_text, 
		pa_cred_line[idx].bdgt_cost_amt, 
		pa_cred_line[idx].act_cost_amt, 
		pa_cred_line[idx].bdgt_bill_amt, 
		pa_cred_line[idx].act_bill_amt, 
		pa_cred_line[idx].post_cost_amt, 
		pa_cred_line[idx].unit_code, 
		pa_cred_line[idx].bdgt_cost_qty, 
		pa_cred_line[idx].act_cost_qty, 
		pa_cred_line[idx].bdgt_bill_qty, 
		pa_cred_line[idx].act_bill_qty, 
		pa_cred_line[idx].post_revenue_amt, 
		pa_cred_line[idx].bill_way_ind 
		IF status THEN 
			CONTINUE FOREACH 
		END IF 
		IF pa_cred_line[idx].bdgt_bill_qty IS NULL THEN 
			LET pa_cred_line[idx].bdgt_bill_qty = 0 
		END IF 
		IF pa_cred_line[idx].act_bill_qty IS NULL THEN 
			LET pa_cred_line[idx].act_bill_qty = 0 
		END IF 
		IF pa_cred_line[idx].bdgt_cost_amt IS NULL THEN 
			LET pa_cred_line[idx].bdgt_cost_amt = 0 
		END IF 
		IF pa_cred_line[idx].act_cost_amt IS NULL THEN 
			LET pa_cred_line[idx].act_cost_amt = 0 
		END IF 
		IF pa_cred_line[idx].bdgt_bill_amt IS NULL THEN 
			LET pa_cred_line[idx].bdgt_bill_amt = 0 
		END IF 
		IF pa_cred_line[idx].act_bill_amt IS NULL THEN 
			LET pa_cred_line[idx].act_bill_amt = 0 
		END IF 
		IF pa_cred_line[idx].post_cost_amt IS NULL THEN 
			LET pa_cred_line[idx].post_cost_amt = 0 
		END IF 
		# CALL TO alloc TO build tempbill FROM resbill
		CALL alloc(idx, pr_invoicehead.inv_num, pr_invoicedetl.line_num) 
		RETURNING pa_cred_line[idx].this_bill_qty, 
		pa_cred_line[idx].this_bill_amt, 
		pa_cred_line[idx].this_cos_amt 
		LET pa_cred_line[idx].invoice_flag = "*" 
		LET pa_activity[idx].invoice_flag = "*" 
		LET pa_activity[idx].this_bill_qty = pa_cred_line[idx].this_bill_qty 
		LET pa_activity[idx].this_bill_amt = pa_cred_line[idx].this_bill_amt 
		LET pa_activity[idx].this_cos_amt = pa_cred_line[idx].this_cos_amt 
		# save the current state of credit FOR later reversing
		LET ps_activity[idx].* = pa_activity[idx].* 
		LET arr_size = arr_size + 1 
		LET idx = idx + 1 
	END FOREACH 
	RETURN true 
END FUNCTION 



FUNCTION setup_creditdetl() 
	LET load_idx = load_idx + 1 
	LET ps_creditdetl[load_idx].cmpy_code = pr_invoicedetl.cmpy_code 
	LET ps_creditdetl[load_idx].cust_code = pr_invoicedetl.cust_code 
	LET ps_creditdetl[load_idx].line_num = pr_invoicedetl.line_num 
	LET ps_creditdetl[load_idx].activity_code = pr_invoicedetl.activity_code 

	LET ps_creditdetl[load_idx].ware_code = pr_invoicedetl.ware_code 
	LET ps_creditdetl[load_idx].cat_code = pr_invoicedetl.cat_code 
	LET ps_creditdetl[load_idx].ship_qty = pr_invoicedetl.ship_qty 
	LET ps_creditdetl[load_idx].line_text = pr_invoicedetl.line_text 
	LET ps_creditdetl[load_idx].uom_code = pr_invoicedetl.uom_code 
	LET ps_creditdetl[load_idx].unit_cost_amt = pr_invoicedetl.unit_cost_amt 
	LET ps_creditdetl[load_idx].ext_cost_amt = pr_invoicedetl.ext_cost_amt 
	LET ps_creditdetl[load_idx].disc_amt = pr_invoicedetl.disc_amt 
	LET ps_creditdetl[load_idx].unit_sales_amt = pr_invoicedetl.unit_sale_amt 
	LET ps_creditdetl[load_idx].ext_sales_amt = pr_invoicedetl.ext_sale_amt 
	LET ps_creditdetl[load_idx].unit_tax_amt = pr_invoicedetl.unit_tax_amt 
	LET ps_creditdetl[load_idx].ext_tax_amt = pr_invoicedetl.ext_tax_amt 
	LET ps_creditdetl[load_idx].line_total_amt = pr_invoicedetl.line_total_amt 
	LET ps_creditdetl[load_idx].jobledger_seq_num = 
	pr_invoicedetl.jobledger_seq_num 
	LET ps_creditdetl[load_idx].line_acct_code = pr_invoicedetl.line_acct_code 
	LET ps_creditdetl[load_idx].level_code = pr_invoicedetl.level_code 
	LET ps_creditdetl[load_idx].comm_amt = pr_invoicedetl.comm_amt 
	LET ps_creditdetl[load_idx].tax_code = pr_invoicedetl.tax_code 
	LET ps_creditdetl[load_idx].var_code = pr_invoicedetl.var_code 
	LET ps_creditdetl[load_idx].invoice_num = pr_invoicehead.inv_num 
	LET ps_creditdetl[load_idx].inv_line_num = pr_invoicedetl.line_num 

END FUNCTION 

