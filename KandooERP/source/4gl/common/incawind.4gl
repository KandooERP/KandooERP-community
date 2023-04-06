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

	Source code beautified by beautify.pl on 2020-01-02 10:35:14	$Id: $
}



#
#   incawind.4gl - show_cost_adj
#                  Window FUNCTION FOR showing a product ledger U type
#                  transaction, which IS a cost adjustment.
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_cost_adj(p_cmpy,p_part_code,p_ware_code,p_tran_date,p_seq_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE p_seq_num LIKE prodledg.seq_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_lump_amt MONEY 
	DEFINE l_seku LIKE product.sell_uom_code 
	DEFINE l_stku LIKE product.stock_uom_code 
	DEFINE l_stock_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_sell_tran_qty LIKE prodledg.tran_qty
	DEFINE l_stock_cost_amt LIKE prodledg.cost_amt 
	DEFINE l_sell_cost_amt LIKE prodledg.cost_amt
	DEFINE l_avail_qty LIKE prodstatus.onhand_qty
	DEFINE l_availf_qty LIKE prodstatus.onhand_qty	 
	DEFINE l_avail1_qty LIKE prodstatus.onhand_qty
	
	# Select only necessary columns instead of select *
	SELECT desc_text, 
		desc2_text, 
		stock_uom_code, 
		sell_uom_code
	INTO l_rec_product.desc_text, 
		l_rec_product.desc2_text, 
		l_rec_product.stock_uom_code, 
		l_rec_product.sell_uom_code 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("I",7032,"") 
		# 7032 Product does NOT exist
		RETURN 
	END IF 
	
	SELECT * 
	INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND tran_date = p_tran_date 
	AND seq_num = p_seq_num 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("I",7033,"") 
		# 7033 Product ledger transaction NOT found
		RETURN 
	END IF 
	
	SELECT ware_code, 
		onhand_qty, 
		reserved_qty, 
		onord_qty, 
		forward_qty, 
		back_qty
	INTO l_rec_prodstatus.ware_code, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.onord_qty, 
		l_rec_prodstatus.forward_qty, 
		l_rec_prodstatus.back_qty
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("I",7035,"") 
		# 7035 Product STATUS does NOT exist
		RETURN 
	END IF 
	
	SELECT desc_text 
	INTO l_rec_warehouse.desc_text
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("I",7034,"") 
		# 7034 Warehouse does NOT exist
		LET l_rec_warehouse.desc_text = NULL 
	END IF 
	
	SELECT desc_text
	INTO l_rec_coa.desc_text
	FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = l_rec_prodledg.acct_code 
	IF sqlca.sqlcode = notfound THEN 
		LET l_msgresp = kandoomsg("I",7036,"") 
		# 7034 Account code does NOT exist
		LET l_rec_coa.desc_text = NULL 
	END IF 
	
	OPEN WINDOW i122 with FORM "I122" 
	CALL windecoration_i("I122") -- albo kd-758 
	LET l_stku = l_rec_product.stock_uom_code 
	LET l_seku = l_rec_product.sell_uom_code 
	LET l_stock_cost_amt = l_rec_prodledg.cost_amt * l_rec_product.stk_sel_con_qty 
	LET l_sell_cost_amt = l_rec_prodledg.cost_amt 
	LET l_stock_tran_qty = l_rec_prodledg.tran_qty / l_rec_product.stk_sel_con_qty 
	LET l_sell_tran_qty = l_rec_prodledg.tran_qty 
	LET l_avail1_qty = NULL 
	LET l_avail_qty = NULL 
	LET l_availf_qty = NULL 
	LET l_rec_prodstatus.onhand_qty = NULL 
	LET l_rec_prodstatus.reserved_qty = NULL 
	LET l_rec_prodstatus.onord_qty = NULL 
	LET l_rec_prodstatus.forward_qty = NULL 
	LET l_rec_prodstatus.back_qty = NULL 
	LET l_lump_amt = l_rec_prodledg.tran_qty * l_rec_prodledg.cost_amt 
	
	DISPLAY l_rec_prodstatus.part_code, 
		l_rec_product.desc_text, 
		l_rec_product.desc2_text, 
		l_lump_amt, 
		l_rec_prodstatus.ware_code, 
		l_rec_warehouse.desc_text, 
		l_rec_prodstatus.onhand_qty, 
		l_avail1_qty, 
		l_avail_qty, 
		l_availf_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.onord_qty, 
		l_rec_prodstatus.forward_qty, 
		l_rec_prodstatus.back_qty, 
		l_rec_prodledg.tran_date, 
		l_rec_prodledg.year_num, 
		l_rec_prodledg.period_num, 
		l_rec_product.stock_uom_code, 
		l_stku, 
		l_rec_product.sell_uom_code, 
		l_seku, 
		l_rec_prodledg.acct_code, 
		l_rec_coa.desc_text, 
		l_rec_prodledg.source_text, 
		l_rec_prodledg.desc_text, 
		l_rec_prodledg.source_num, 
		l_stock_tran_qty, 
		l_stock_cost_amt, 
		l_sell_tran_qty, 
		l_sell_cost_amt 
	TO prodstatus.part_code, 
		product.desc_text, 
		product.desc2_text, 
		formonly.lump_amt, 
		prodstatus.ware_code, 
		warehouse.desc_text, 
		prodstatus.onhand_qty, 
		formonly.avail1_qty, 
		formonly.avail_qty, 
		formonly.availf_qty, 
		prodstatus.reserved_qty, 
		prodstatus.onord_qty, 
		prodstatus.forward_qty, 
		prodstatus.back_qty, 
		prodledg.tran_date, 
		prodledg.year_num, 
		prodledg.period_num, 
		product.stock_uom_code, 
		formonly.stku, 
		product.sell_uom_code, 
		formonly.seku, 
		prodledg.acct_code, 
		coa.desc_text, 
		prodledg.source_text, 
		prodledg.desc_text, 
		prodledg.source_num, 
		formonly.stock_tran_qty, 
		formonly.stock_cost_amt, 
		formonly.sell_tran_qty, 
		formonly.sell_cost_amt 

	LET l_msgresp = kandoomsg("I",7001,"") 
	# 7001 Any key TO continue
	CLOSE WINDOW i122 
	RETURN 
END FUNCTION  # show_cost_adj


