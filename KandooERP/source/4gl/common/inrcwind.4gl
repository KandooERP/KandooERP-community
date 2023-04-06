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
#   inrcwind.4gl - show_reclass
#                  Window FUNCTION FOR showing a product ledger X type
#                  transaction, which IS a product reclassification
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_reclass(p_cmpy,p_part_code,p_ware_code,p_tran_date,p_src_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE p_src_num LIKE prodledg.source_num
	DEFINE l_ware_text LIKE warehouse.desc_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_pr_product RECORD LIKE product.* 
	DEFINE l_rec_ps_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_new RECORD 
				prod2 LIKE product.part_code, 
				prod_text LIKE product.desc_text, 
				desc1 LIKE product.desc_text, 
				desc2 LIKE product.desc2_text, 
				onhand2 LIKE prodstatus.onhand_qty, 
				reserved2 LIKE prodstatus.reserved_qty, 
				onord2 LIKE prodstatus.onord_qty, 
				avail2 LIKE prodstatus.onhand_qty, 
				sell_uom LIKE product.sell_uom_code, 
				sell2_uom LIKE product.sell_uom_code, 
				stock_qty LIKE prodstatus.onhand_qty 
			 END RECORD 
	DEFINE l_rec_ps_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_pt_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 

	SELECT * 
	INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND tran_date = p_tran_date 
	AND source_num = p_src_num 
	AND trantype_ind = "X" 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7033,"") 
		# 7033 Product ledger transaction NOT found
		RETURN 
	END IF 

	IF l_rec_prodledg.tran_qty < 0 THEN #original code 
		SELECT * 
		INTO l_rec_ps_prodledg.* 
		FROM prodledg 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND tran_date = p_tran_date 
		AND source_num = p_src_num 
		AND trantype_ind = "X" 
		AND tran_qty > 0 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7033,"") 
			# 7033 Product ledger transaction NOT found
			RETURN 
		END IF 
	ELSE # > 0 means new code 
		SELECT * 
		INTO l_rec_ps_prodledg.* 
		FROM prodledg 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND tran_date = p_tran_date 
		AND source_num = p_src_num 
		AND trantype_ind = "X" 
		AND tran_qty < 0 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7033,"") 
			# 7033 Product ledger transaction NOT found
			RETURN 
		END IF 

		# Now we want TO make sure that pr RECORD IS original
		LET l_rec_pt_prodledg.* = l_rec_ps_prodledg.* 
		LET l_rec_ps_prodledg.* = l_rec_prodledg.* 
		LET l_rec_prodledg.* = l_rec_pt_prodledg.* 
	END IF 

	SELECT * 
	INTO l_rec_pr_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_prodledg.part_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7032,"") 
		# 7032 Product does NOT exist
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_ps_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_ps_prodledg.part_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7032,"") 
		# 7032 Product does NOT exist
		RETURN 
	END IF 

	SELECT desc_text 
	INTO l_ware_text 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7034,"") 
		# 7034 Warehouse does NOT exist
		LET l_rec_warehouse.desc_text = NULL 
	END IF 


	OPEN WINDOW i638 with FORM "I638" 
	CALL windecoration_i("I638") -- albo kd-758 

	LET l_rec_new.sell_uom = l_rec_pr_product.sell_uom_code 
	LET l_rec_new.prod_text = l_rec_pr_product.desc_text 
	LET l_rec_new.prod2 = l_rec_ps_prodledg.part_code 
	LET l_rec_new.desc1 = l_rec_ps_product.desc_text 
	LET l_rec_new.sell2_uom = l_rec_ps_product.sell_uom_code 
	LET l_rec_new.desc2 = l_rec_ps_product.desc2_text 
	LET l_rec_new.stock_qty = l_rec_ps_prodledg.tran_qty / l_rec_pr_product.stk_sel_con_qty 

	DISPLAY BY NAME l_rec_prodledg.ware_code, 
	l_rec_prodledg.part_code, 
	l_rec_new.prod_text, 
	l_rec_new.prod2, 
	l_rec_new.desc1, 
	l_rec_new.desc2, 
	l_rec_prodledg.tran_date, 
	l_rec_prodledg.year_num, 
	l_rec_prodledg.period_num, 
	l_rec_prodledg.source_text, 
	l_rec_prodledg.desc_text, 
	l_rec_prodledg.source_num, 
	l_rec_ps_prodledg.tran_qty, 
	l_rec_pr_product.stock_uom_code, 
	l_rec_pr_product.sell_uom_code, 
	l_rec_new.stock_qty 
   DISPLAY l_ware_text TO ware_text

	LET l_msgresp = kandoomsg("I",7001,"") 
	# 7001 Any key TO continue
	CLOSE WINDOW i638 
	RETURN 
END FUNCTION 


