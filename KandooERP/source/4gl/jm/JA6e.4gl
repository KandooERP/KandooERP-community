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
# \brief module Va6e (Ja6e) , Automatic Billing - Invoice general descriptions

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 
GLOBALS "JA6_GLOBALS.4gl" 


DEFINE 
err_continue CHAR(1), 
err_message CHAR(40) 


FUNCTION general_invoicing() 

	LET pv_curr_idx = pv_curr_idx + 1 

	LET pa_tentinvdetl[pv_curr_idx].cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET pa_tentinvdetl[pv_curr_idx].cust_code = pr_tentinvhead.cust_code 
	LET pa_tentinvdetl[pv_curr_idx].tax_code = pr_customer.tax_code 
	LET pa_tentinvdetl[pv_curr_idx].inv_num = pr_tentinvhead.inv_num 
	LET pa_tentinvdetl[pv_curr_idx].part_code = pr_contractdetl.part_code 
	LET pa_tentinvdetl[pv_curr_idx].ware_code = pr_customership.ware_code 
	LET pa_tentinvdetl[pv_curr_idx].line_text = pr_contractdetl.desc_text 
	LET pa_tentinvdetl[pv_curr_idx].cat_code = pr_product.cat_code 

	IF pr_tentinvdetl.ord_qty IS NULL THEN 
		LET pa_tentinvdetl[pv_curr_idx].ord_qty = 1 
	ELSE 
		LET pa_tentinvdetl[pv_curr_idx].ord_qty = pr_contractdetl.bill_qty 
	END IF 

	IF pr_contractdetl.bill_qty IS NULL THEN 
		LET pa_tentinvdetl[pv_curr_idx].ship_qty = 1 
	ELSE 
		LET pa_tentinvdetl[pv_curr_idx].ship_qty = pr_contractdetl.bill_qty 
	END IF 

	LET pa_tentinvdetl[pv_curr_idx].prev_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].back_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].ser_qty = 0 
	LET pa_tentinvdetl[pv_curr_idx].unit_cost_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].ext_cost_amt = 0 
	LET pa_tentinvdetl[pv_curr_idx].disc_amt = 0 

	IF pr_contractdetl.bill_price IS NULL THEN 
		LET pa_tentinvdetl[pv_curr_idx].list_price_amt = 0 
		LET pa_tentinvdetl[pv_curr_idx].unit_sale_amt = 0 
	ELSE 
		LET pa_tentinvdetl[pv_curr_idx].list_price_amt= pr_contractdetl.bill_price 
		LET pa_tentinvdetl[pv_curr_idx].unit_sale_amt = pr_contractdetl.bill_price 
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
