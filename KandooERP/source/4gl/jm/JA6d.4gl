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
# \brief module Va6d (Ja6d !!!), Automatic Billing - Invoice inventory

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 


DEFINE 
err_continue CHAR(1), 
err_message CHAR(40) 


FUNCTION invent_invoicing() 

	LET pv_curr_idx = pv_curr_idx + 1 

	SELECT * 
	INTO pr_product.* 
	FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND part_code = pr_contractdetl.part_code 

	IF status = 0 THEN 
		# do nothing
	ELSE 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = pr_contractdetl.part_code, " part code NOT found" 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 












	LET pa_tentinvdetl[pv_curr_idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pa_tentinvdetl[pv_curr_idx].cust_code = pr_tentinvhead.cust_code 
	LET pa_tentinvdetl[pv_curr_idx].tax_code = pr_customer.tax_code 
	LET pa_tentinvdetl[pv_curr_idx].inv_num = pr_tentinvhead.inv_num 
	LET pa_tentinvdetl[pv_curr_idx].ware_code = pr_customership.ware_code 
	LET pa_tentinvdetl[pv_curr_idx].part_code = pr_contractdetl.part_code 
	LET pa_tentinvdetl[pv_curr_idx].line_text = pr_product.desc_text 
	LET pa_tentinvdetl[pv_curr_idx].uom_code = pr_product.sell_uom_code 


	SELECT * 
	INTO pr_category.* 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = pr_product.cat_code 

	IF status = 0 THEN 
		# do nothing
	ELSE 
		LET pv_error = true 
		LET pv_error_run = true 
		LET pv_error_text = pr_product.cat_code, " category code NOT found" 

		OUTPUT TO REPORT autobill(glob_rec_kandoouser.cmpy_code, 
		pr_company.name_text, 
		pr_contractdate.contract_code, 
		pr_contractdate.inv_num, 
		pr_contractdate.invoice_date, 
		pr_contractdate.invoice_total_amt, 
		pv_error_text) 
	END IF 












































	LET pa_tentinvdetl[pv_curr_idx].cat_code = pr_product.cat_code 

	IF pr_contractdetl.bill_qty IS NULL THEN 
		LET pa_tentinvdetl[pv_curr_idx].ord_qty = 1 
		LET pa_tentinvdetl[pv_curr_idx].ship_qty = 1 
	ELSE 
		LET pa_tentinvdetl[pv_curr_idx].ord_qty = pr_contractdetl.bill_qty 
		LET pa_tentinvdetl[pv_curr_idx].ship_qty = pr_contractdetl.bill_qty 
	END IF 

	LET pa_tentinvdetl[pv_curr_idx].prev_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].back_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].ser_flag = pr_product.serial_flag 
	LET pa_tentinvdetl[pv_curr_idx].ser_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].unit_cost_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].ext_cost_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].disc_amt = 0 

	IF pr_contractdetl.bill_price IS NULL THEN 
		LET pa_tentinvdetl[pv_curr_idx].unit_sale_amt = 0 
		LET pa_tentinvdetl[pv_curr_idx].list_price_amt = 0 
	ELSE 
		LET pa_tentinvdetl[pv_curr_idx].unit_sale_amt = pr_contractdetl.bill_price 
		LET pa_tentinvdetl[pv_curr_idx].list_price_amt =pr_contractdetl.bill_price 
	END IF 

	LET pa_tentinvdetl[pv_curr_idx].ext_sale_amt = 
	pa_tentinvdetl[pv_curr_idx].unit_sale_amt 
	* pa_tentinvdetl[pv_curr_idx].ship_qty 
	LET pa_tentinvdetl[pv_curr_idx].line_acct_code = 
	pr_contractdetl.revenue_acct_code 
	LET pa_tentinvdetl[pv_curr_idx].level_code = pr_customer.inv_level_ind 
	LET pa_tentinvdetl[pv_curr_idx].order_line_num = 0 
	LET pa_tentinvdetl[pv_curr_idx].order_num = 0 
	LET pa_tentinvdetl[pv_curr_idx].seq_num = 0 
	LET pa_tentinvdetl[pv_curr_idx].comm_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].comp_per = 0 
	LET pa_tentinvdetl[pv_curr_idx].disc_per = 0 
	LET pa_tentinvdetl[pv_curr_idx].ext_bonus_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].ext_stats_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].jobledger_seq_num = 0 
	LET array_size = pv_curr_idx 


END FUNCTION 



FUNCTION invgen_inv_write() 
	DEFINE 
	pr_start_date, pr_end_date DATE 


	IF pr_job.type_code matches "HY*" THEN 
		CALL cont_inv_range(pr_tentinvhead.cmpy_code, 
		pr_tentinvhead.contract_code, 
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

		LOCK TABLE tentinvdetl in share MODE 

		LET err_message = "JA6d - Error inserting tentinvdetl record" 

		FOR idx = 1 TO array_size 
			CALL find_tax(pr_customer.tax_code, 
			pa_tentinvdetl[idx].part_code, 
			pr_contractdetl.ship_code, 
			array_size, 
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

			LET pr_tentinvhead.goods_amt = 

			pr_tentinvhead.goods_amt + (pa_tentinvdetl[idx].line_total_amt 
			- pa_tentinvdetl[idx].ext_tax_amt) 
			LET pr_tentinvhead.total_amt = 
			pr_tentinvhead.total_amt + pa_tentinvdetl[idx].line_total_amt 
			LET pr_tentinvhead.tax_amt = 
			pr_tentinvhead.tax_amt + pa_tentinvdetl[idx].ext_tax_amt 
		END FOR 

		LET err_message = "JA6d - Error inserting tentinvhead record" 
		LET pr_tentinvhead.line_num = array_size 

		INSERT INTO tentinvhead VALUES (pr_tentinvhead.*) 

	COMMIT WORK 

	LET pv_invoice_present = false 

	LET pv_cnt = pv_cnt + 1 
	LET pv_run_total = pv_run_total + pr_tentinvhead.total_amt 
	LET pa_tentinvrun[pv_cnt].inv_num = pr_tentinvhead.inv_num 
	LET pa_tentinvrun[pv_cnt].contract_code = pr_tentinvhead.contract_code 
	LET pa_tentinvrun[pv_cnt].desc_text = pr_contracthead.desc_text 
	LET pa_tentinvrun[pv_cnt].total_amt = pr_tentinvhead.total_amt 


END FUNCTION 
