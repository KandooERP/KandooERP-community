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

	Source code beautified by beautify.pl on 2020-01-02 10:35:15	$Id: $
}



#
#   iniswind.4gl - show_inv_transf
#                  Window FUNCTION FOR showing a product ledger T type
#                  transaction, which IS an warehouse transfer.
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_inv_transf(p_cmpy,p_part_code,p_ware_code,p_tran_date,p_seq_num) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE p_tran_date LIKE prodledg.tran_date 
	DEFINE p_seq_num LIKE prodledg.seq_num
	DEFINE l_arr_ibtdetl DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		line_num LIKE ibtdetl.line_num, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		trf_qty LIKE ibtdetl.trf_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD 
	DEFINE l_arr_prledger DYNAMIC ARRAY OF RECORD LIKE prodledg.* 
	DEFINE l_arr_prodledg DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stock_tran_qty LIKE prodledg.tran_qty, 
		stock_uom_code LIKE product.stock_uom_code, 
		sell_tran_qty LIKE prodledg.tran_qty, 
		sell_uom_code LIKE product.stock_uom_code 
	END RECORD 
	DEFINE l_source_text LIKE prodledg.source_text 
	DEFINE l_source_num LIKE prodledg.source_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_pr_ibthead RECORD LIKE ibthead.* 
	DEFINE l_rec_pr_ibtdetl RECORD LIKE ibtdetl.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_ware LIKE warehouse.ware_code 
	DEFINE l_ddesc_text LIKE warehouse.desc_text 
	DEFINE l_idx SMALLINT
	DEFINE l_scrn SMALLINT
	DEFINE l_s_avail LIKE prodstatus.onhand_qty
	DEFINE l_d_avail LIKE prodstatus.onhand_qty
	DEFINE j SMALLINT		 

	SELECT * INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7032,"") 
		# 7032 Product does NOT exist
		RETURN 
	END IF 
	SELECT * INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND tran_date = p_tran_date 
	AND seq_num = p_seq_num 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7033,"") 
		# 7033 Product ledger transaction NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("I",7035,"") 
		# 7035 Product STATUS does NOT exist
		RETURN 
	END IF 
	IF l_rec_prodledg.tran_qty < 0 THEN 
		LET l_ware = l_rec_prodledg.source_text 
		SELECT desc_text INTO l_ddesc_text 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = l_ware 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7034,"") 
			# 7034 Warehouse does NOT exist
			LET l_ddesc_text = NULL 
		END IF 
		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7034,"") 
			# 7034 Warehouse does NOT exist
			LET l_rec_warehouse.desc_text = NULL 
		END IF 
	ELSE 
		LET l_ware = p_ware_code 
		SELECT desc_text INTO l_ddesc_text 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy 
			AND ware_code = p_ware_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7034,"") 
			# 7034 Warehouse does NOT exist
			LET l_ddesc_text = NULL 
		END IF 
		LET l_rec_prodstatus.ware_code = l_rec_prodledg.source_text 
		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy 
			AND ware_code = l_rec_prodstatus.ware_code 
		IF status = notfound THEN 
			LET l_msgresp = kandoomsg("I",7034,"") 
			# 7034 Warehouse does NOT exist
			LET l_rec_warehouse.desc_text = NULL 
		END IF 
	END IF 
	INITIALIZE l_rec_pr_ibthead.* TO NULL 
	SELECT * INTO l_rec_pr_ibthead.* 
	FROM ibthead 
	WHERE cmpy_code = p_cmpy 
		AND trans_num = l_rec_prodledg.source_num 

	OPEN WINDOW i669 with FORM "I669" 
	CALL windecoration_i("I669") -- albo kd-758 
	LET l_msgresp = kandoomsg("I",1008,"") 
	# 1008  F3/F4 TO Page Fwd/Bwd;  OK TO Continue.

	CALL l_arr_ibtdetl.Clear() 
	CALL l_arr_prledger.Clear()
	CALL l_arr_prodledg.Clear() 
 
	DECLARE crs_all_ibtdetl CURSOR FOR 
	SELECT * 
	FROM ibtdetl 
	WHERE cmpy_code = p_cmpy 
		AND trans_num = l_rec_prodledg.source_num 
		AND part_code = l_rec_prodledg.part_code 
	
	LET l_idx = 0 
	
	# TODO: instead of selection into a record, then assign values to array element, do DIRECTLY FOREACH cursor INTO array_element
	FOREACH crs_all_ibtdetl INTO l_rec_pr_ibtdetl.* 
		LET l_idx = l_idx + 1 
		
		--SELECT * INTO l_rec_product.*   
		## SELECT ONLY necessary columns, product is a wide table ....  ericv 2020-09-20
 		SELECT desc_text,
 			stock_uom_code,
 			stk_sel_con_qty,
 			sell_uom_code
 		INTO l_rec_product.desc_text,
 			l_rec_product.stock_uom_code,
 			l_rec_product.stk_sel_con_qty,
 			l_rec_product.sell_uom_code
 			
		FROM product 
		WHERE part_code = l_rec_pr_ibtdetl.part_code 
			AND cmpy_code = p_cmpy 

		
		LET l_arr_ibtdetl[l_idx].line_num = l_rec_pr_ibtdetl.line_num 
		LET l_arr_ibtdetl[l_idx].part_code = l_rec_pr_ibtdetl.part_code 
		LET l_arr_ibtdetl[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_ibtdetl[l_idx].stock_uom_code = l_rec_product.stock_uom_code 
		LET l_arr_ibtdetl[l_idx].trf_qty = l_rec_pr_ibtdetl.trf_qty 
		/ l_rec_product.stk_sel_con_qty 
		LET l_arr_ibtdetl[l_idx].sell_tran_qty = l_rec_pr_ibtdetl.trf_qty 
		IF l_arr_ibtdetl[l_idx].trf_qty < 0 THEN 
			LET l_arr_ibtdetl[l_idx].trf_qty = l_arr_ibtdetl[l_idx].trf_qty * -1 
		END IF 
		IF l_arr_ibtdetl[l_idx].sell_tran_qty < 0 THEN 
			LET l_arr_ibtdetl[l_idx].sell_tran_qty = l_arr_ibtdetl[l_idx].sell_tran_qty * -1 
		END IF 
		LET l_arr_ibtdetl[l_idx].sell_uom_code = l_rec_product.sell_uom_code 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	CALL set_count(l_idx) 

	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = l_rec_prodstatus.ware_code 
	IF l_rec_prodstatus.onord_qty IS NULL THEN 
		LET l_rec_prodstatus.onord_qty = 0 
	END IF 
	IF l_rec_prodstatus.reserved_qty IS NULL THEN 
		LET l_rec_prodstatus.reserved_qty = 0 
	END IF 

	LET l_s_avail = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.back_qty - l_rec_prodstatus.reserved_qty 

	DISPLAY l_rec_prodstatus.ware_code, 
		l_rec_warehouse.desc_text, 
		l_ware, 
		l_ddesc_text, 
		l_rec_pr_ibthead.sched_ind, 
		l_rec_prodledg.tran_date, 
		l_rec_prodledg.year_num, 
		l_rec_prodledg.period_num, 
		l_rec_prodledg.desc_text, 
		l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_rec_prodstatus.back_qty, 
		l_s_avail 
	TO from_ware_code, 
		sr_desc_text[1].ware_text, 
		to_ware_code, 
		sr_desc_text[2].ware_text, 
		sched_ind, 
		trans_date, 
		year_num, 
		period_num, 
		desc_text, 
		sr_status[1].onhand_qty, 
		sr_status[1].reserved_qty, 
		sr_status[1].back_qty, 
		sr_status[1].avail_qty 


	SELECT * INTO l_rec_prodstatus.* 
	FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
		AND part_code = p_part_code 
		AND ware_code = l_ware 

	IF l_rec_prodstatus.onord_qty IS NULL THEN 
		LET l_rec_prodstatus.onord_qty = 0 
	END IF 
	IF l_rec_prodstatus.reserved_qty IS NULL THEN 
		LET l_rec_prodstatus.reserved_qty = 0 
	END IF 
	LET l_d_avail = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.back_qty	- l_rec_prodstatus.reserved_qty 
	DISPLAY l_rec_prodstatus.onhand_qty, 
		l_rec_prodstatus.back_qty, 
		l_rec_prodstatus.reserved_qty, 
		l_d_avail 
	TO sr_status[2].onhand_qty, 
		sr_status[2].back_qty, 
		sr_status[2].reserved_qty, 
		sr_status[2].avail_qty 

--	INPUT ARRAY l_arr_ibtdetl WITHOUT DEFAULTS FROM sr_ibtdetl.*
# This is a DISPLAY ARRAY, not an INPUT ARRAY 	
	DISPLAY ARRAY l_arr_ibtdetl 
	TO sr_ibtdetl.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","intrwind","input-arr-ibtdetl") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

# delete block 'controlling' array navigation: useless  ericv 2020-09-20

	END DISPLAY

	CLOSE WINDOW i669 
	RETURN 
END FUNCTION 		# show_inv_transf


