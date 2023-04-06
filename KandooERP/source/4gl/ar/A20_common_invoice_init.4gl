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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A20_GLOBALS.4gl"

############################################################################
# FUNCTION init_rec_invoicedetl()
#
#
############################################################################
FUNCTION init_rec_invoicedetl()
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.*
	
	INITIALIZE l_rec_invoicedetl.* TO NULL

	LET l_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code #company (user company)
	LET l_rec_invoicedetl.cust_code = glob_rec_customer.cust_code #customer
	LET l_rec_invoicedetl.ware_code = glob_rec_warehouse.ware_code #warehouse
	LET l_rec_invoicedetl.tax_code = glob_rec_customer.tax_code #TaxCode from Customer

	LET l_rec_invoicedetl.inv_num = 0 
	LET l_rec_invoicedetl.ord_qty = 0
	LET l_rec_invoicedetl.ship_qty = 0
	LET l_rec_invoicedetl.prev_qty = 0
	LET l_rec_invoicedetl.back_qty = 0
	LET l_rec_invoicedetl.ser_qty = 0
	LET l_rec_invoicedetl.unit_cost_amt = 0
	LET l_rec_invoicedetl.ext_cost_amt = 0
	LET l_rec_invoicedetl.unit_tax_amt = 0
	LET l_rec_invoicedetl.ext_tax_amt = 0
	LET l_rec_invoicedetl.line_total_amt = 0
	LET l_rec_invoicedetl.seq_num = 0
	LET l_rec_invoicedetl.comm_amt = 0
	LET l_rec_invoicedetl.comp_per = 0
	LET l_rec_invoicedetl.order_line_num = 0
	LET l_rec_invoicedetl.order_num = 0
	LET l_rec_invoicedetl.disc_per = 0
	LET l_rec_invoicedetl.sold_qty = 0
	LET l_rec_invoicedetl.bonus_qty = 0
	LET l_rec_invoicedetl.ext_bonus_amt = 0
	LET l_rec_invoicedetl.ext_stats_amt = 0
	LET l_rec_invoicedetl.list_price_amt = 0
	LET l_rec_invoicedetl.var_code = 0
	LET l_rec_invoicedetl.jobledger_seq_num = 0
	LET l_rec_invoicedetl.contract_line_num = 0

	#Warehouse Dependencies				
--	IF l_rec_invoicedetl.ware_code IS NOT NULL THEN #GL account and Tax code will be initialized by Warehouse-Part
--		#so far, I can not think about anything I need to do if I use a warehouse item - warehouse part provides me with all data
--	ELSE #none-warehouse item
		LET l_rec_invoicedetl.line_acct_code = db_category_get_first_sale_acct_code(UI_OFF)   #First available category sales account
		LET l_rec_invoicedetl.tax_code = glob_rec_customer.tax_code
--	END IF
				
	RETURN l_rec_invoicedetl.*
END FUNCTION
############################################################################
# END FUNCTION init_rec_invoicedetl()
############################################################################
