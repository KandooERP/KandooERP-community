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

	Source code beautified by beautify.pl on 2020-01-02 10:35:25	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/po_common_globals.4gl" 
#GLOBALS "../common/po_mod.4gl"

#GLOBALS
#	DEFINE glob_rec_poaudit RECORD LIKE poaudit.*
#	DEFINE glob_rec_purchdetl RECORD LIKE purchdetl.*
#	DEFINE glob_rec_jmresource RECORD LIKE jmresource.*
#END GLOBALS


############################################################
# FUNCTION display_stockstatus(p_cmpy_code, p_ref_text, p_ware_code)
#
# Displays the stockstatus information
############################################################
FUNCTION display_stockstatus(p_cmpy_code,p_ref_text,p_ware_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ref_text LIKE purchdetl.ref_text 
	DEFINE p_ware_code LIKE purchhead.ware_code 
	DEFINE l_display_val SMALLINT 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_fut_avail LIKE prodstatus.onhand_qty 
	DEFINE l_available LIKE prodstatus.onhand_qty 

	IF p_ref_text IS NOT NULL THEN 
		SELECT ps.*, p.* 
		INTO l_rec_prodstatus.*, 
		l_rec_product.* 
		FROM prodstatus ps, 
		product p 
		WHERE ps.part_code = p_ref_text 
		AND ps.ware_code = p_ware_code 
		AND ps.cmpy_code = p_cmpy_code 
		AND p.cmpy_code = ps.cmpy_code 
		AND p.part_code = ps.part_code 
		IF l_rec_prodstatus.onhand_qty IS NULL THEN 
			LET l_rec_prodstatus.onhand_qty = 0 
		END IF 
		IF l_rec_prodstatus.onord_qty IS NULL THEN 
			LET l_rec_prodstatus.onord_qty = 0 
		END IF 
		IF l_rec_prodstatus.reserved_qty IS NULL THEN 
			LET l_rec_prodstatus.reserved_qty = 0 
		END IF 
		IF l_rec_prodstatus.back_qty IS NULL THEN 
			LET l_rec_prodstatus.back_qty = 0 
		END IF 
		LET l_available = l_rec_prodstatus.onhand_qty 
		- l_rec_prodstatus.reserved_qty 
		- l_rec_prodstatus.back_qty 
		LET l_fut_avail = l_available 
		+ l_rec_prodstatus.onord_qty 
	ELSE 
		INITIALIZE l_rec_prodstatus.* TO NULL 
		LET l_fut_avail = NULL 
		LET l_available = NULL 
	END IF 
	DISPLAY BY NAME l_rec_prodstatus.onhand_qty, 
	l_rec_prodstatus.back_qty, 
	l_rec_prodstatus.reserved_qty, 
	l_rec_prodstatus.onord_qty, 
	l_rec_prodstatus.reorder_point_qty, 
	l_rec_prodstatus.reorder_qty, 
	l_rec_prodstatus.max_qty, 
	l_rec_prodstatus.critical_qty, 
	l_rec_product.min_ord_qty, 
	l_fut_avail, 
	l_available, 
	l_rec_prodstatus.abc_ind 

END FUNCTION 


############################################################
# FUNCTION disp_po_totals()
#
# Displays the Purchase Order Line cost AND associated details
############################################################
FUNCTION disp_po_totals() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_list_total FLOAT 
	DEFINE l_line_num LIKE purchdetl.line_num 
	DEFINE l_order_num LIKE purchdetl.order_num 
	DEFINE l_cmpy_code LIKE company.cmpy_code 

	DISPLAY glob_rec_poaudit.order_qty, 
	glob_rec_purchdetl.list_cost_amt, 
	glob_rec_purchdetl.disc_per, 
	glob_rec_poaudit.received_qty, 
	glob_rec_poaudit.voucher_qty 
	TO poaudit.order_qty, 
	purchdetl.list_cost_amt, 
	purchdetl.disc_per, 
	poaudit.received_qty, 
	poaudit.voucher_qty 

	IF glob_rec_purchdetl.type_ind = "I" THEN 
		DISPLAY glob_rec_poaudit.unit_cost_amt, 
		glob_rec_poaudit.unit_tax_amt, 
		glob_rec_poaudit.line_total_amt 
		TO unit_cost_amt, 
		poaudit.unit_tax_amt, 
		poaudit.line_total_amt 

	ELSE 
		IF glob_rec_purchdetl.type_ind = "G" THEN 
			LET l_list_total = glob_rec_poaudit.order_qty 
			* glob_rec_purchdetl.list_cost_amt 
			DISPLAY BY NAME l_list_total, 
			glob_rec_poaudit.ext_cost_amt, 
			glob_rec_poaudit.unit_cost_amt, 
			glob_rec_poaudit.unit_tax_amt, 
			glob_rec_poaudit.ext_tax_amt, 
			glob_rec_poaudit.line_total_amt 

		ELSE 
			LET l_list_total = glob_rec_poaudit.order_qty 
			* glob_rec_jmresource.unit_cost_amt 
			DISPLAY glob_rec_poaudit.unit_cost_amt, 
			l_list_total 
			TO jmresource.unit_cost_amt, 
			jobledger.charge_amt 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION display_sell_uom(p_cmpy_code)
#
#
############################################################
FUNCTION display_sell_uom(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_order_qty LIKE poaudit.order_qty 
	DEFINE l_unit_cost_amt LIKE poaudit.unit_cost_amt 
	DEFINE l_unit_tax_amt LIKE poaudit.unit_tax_amt 
	DEFINE l_list_total_amt LIKE purchdetl.list_cost_amt 

	LET l_order_qty = 0 
	LET l_unit_cost_amt = 0 
	LET l_unit_tax_amt = 0 
	SELECT * INTO l_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = glob_rec_purchdetl.ref_text 
	IF glob_rec_poaudit.order_qty > 0 THEN 
		LET l_order_qty = (glob_rec_poaudit.order_qty 
		* l_rec_product.pur_stk_con_qty) 
		* l_rec_product.stk_sel_con_qty 
	END IF 
	IF glob_rec_purchdetl.list_cost_amt > 0 THEN 
		LET l_list_total_amt = (glob_rec_purchdetl.list_cost_amt 
		/ l_rec_product.pur_stk_con_qty) 
		/ l_rec_product.stk_sel_con_qty 
		LET l_unit_cost_amt = (glob_rec_poaudit.unit_cost_amt 
		/ l_rec_product.pur_stk_con_qty) 
		/ l_rec_product.stk_sel_con_qty 
	ELSE 
		LET l_unit_cost_amt = 0 
	END IF 
	IF glob_rec_poaudit.unit_tax_amt > 0 THEN 
		LET l_unit_tax_amt = (glob_rec_poaudit.unit_tax_amt 
		/ l_rec_product.pur_stk_con_qty) 
		/ l_rec_product.stk_sel_con_qty 
	ELSE 
		LET l_unit_tax_amt = 0 
	END IF 
	DISPLAY BY NAME l_order_qty, 
	l_unit_cost_amt, 
	l_list_total_amt, 
	l_unit_tax_amt 

END FUNCTION 


############################################################
# FUNCTION calc_jm_totals()
#
#
############################################################
FUNCTION calc_jm_totals() 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_list_total LIKE purchdetl.list_cost_amt 

	LET glob_rec_jmresource.unit_cost_amt = glob_rec_purchdetl.list_cost_amt 
	- ((glob_rec_purchdetl.list_cost_amt 
	* (glob_rec_purchdetl.disc_per / 100))) 
	LET l_list_total = glob_rec_purchdetl.list_cost_amt * glob_rec_poaudit.order_qty 
	LET l_rec_jobledger.trans_amt = glob_rec_jmresource.unit_cost_amt 
	* glob_rec_poaudit.order_qty 
	LET l_rec_jobledger.charge_amt = glob_rec_jmresource.unit_bill_amt 
	* glob_rec_poaudit.order_qty 
	DISPLAY BY NAME glob_rec_jmresource.unit_cost_amt, 
	l_list_total, 
	l_rec_jobledger.trans_amt, 
	l_rec_jobledger.charge_amt 

	RETURN glob_rec_jmresource.unit_cost_amt, 
	l_rec_jobledger.trans_amt, 
	l_rec_jobledger.charge_amt 
END FUNCTION 


