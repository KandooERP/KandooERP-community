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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - JA1glob - Contract add
# Purpose - Global variables used in JA1 & JA2

GLOBALS 

	DEFINE 
	pr_contracthead RECORD LIKE contracthead.*, 
	pr_contractdetl RECORD LIKE contractdetl.*, 
	pr_contractdate RECORD LIKE contractdate.*, 
	pr_product RECORD LIKE product.*, 
	pr_customership RECORD LIKE customership.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_job RECORD LIKE job.*, 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_activity RECORD LIKE activity.*, 
	pr_jmparms RECORD LIKE jmparms.*, 
	pa_dates array[1000] OF RECORD 
		invoice_date LIKE contractdate.invoice_date, 
		inv_num LIKE contractdate.inv_num, 
		invoice_total_amt LIKE contractdate.invoice_total_amt, 
		inv_ind CHAR(7) 
	END RECORD, 
	ps_dates array[1000] OF RECORD 
		invoice_date LIKE contractdate.invoice_date, 
		inv_num LIKE contractdate.inv_num, 
		invoice_total_amt LIKE contractdate.invoice_total_amt, 
		inv_ind CHAR(7) 
	END RECORD, 
	pa_contractdate array[1000] OF 
	RECORD LIKE contractdate.*, 
		pa_details array[1000] OF RECORD 
			type_code LIKE contractdetl.type_code, 
			desc_text LIKE contractdetl.desc_text 
		END RECORD, 
		pa_detls_copy array[1000] OF RECORD 
			type_code LIKE contractdetl.type_code, 
			desc_text LIKE contractdetl.desc_text 
		END RECORD, 
		pa_contractdetl array[1000] OF 
		RECORD LIKE contractdetl.*, 
			pa_cntrdtl_copy array[1000] OF RECORD LIKE contractdetl.*, 
			pa_contracthead array[500] OF RECORD 
				contract_code LIKE contracthead.contract_code, 
				cust_code LIKE contracthead.cust_code, 
				status_code LIKE contracthead.status_code, 
				desc_text LIKE contracthead.desc_text 
			END RECORD, 
			idx SMALLINT, 
			scrn SMALLINT, 
			arr_size SMALLINT, 
			formname CHAR(15), 
			err_continue CHAR(1), 
			err_message CHAR(40), 
			query_text CHAR(500), 
			where_part CHAR(500), 

			pv_stock_acct_code LIKE category.stock_acct_code, 
			pv_ref_code LIKE userref.ref_code, 
			pv_contract_total LIKE contracthead.contract_value_amt, 

			pv_finish_add SMALLINT, 
			pv_add SMALLINT, 
			pv_details_flag SMALLINT, 
			pv_idx_hold SMALLINT, 
			pv_ship_count SMALLINT, 
			pv_invdte_cnt SMALLINT, 
			pv_dtllne_cnt SMALLINT 

END GLOBALS 
