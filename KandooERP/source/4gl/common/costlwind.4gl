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

	Source code beautified by beautify.pl on 2020-01-02 10:35:09	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module costlwind allows the user TO scan Cost Ledgers.
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_product RECORD LIKE product.* 
DEFINE modu_rec_prodstatus RECORD LIKE prodstatus.* 
DEFINE modu_rec_warehouse RECORD LIKE warehouse.* 
DEFINE modu_rec_costledg RECORD LIKE costledg.* 
#l_msgresp LIKE language.yes_flag,
DEFINE modu_tran_date DATE 
DEFINE modu_tot_valuation DECIMAL(16,2) 
DEFINE modu_idx SMALLINT 

############################################################
# FUNCTION cost_ledger_inquiry(p_cmpy, p_product_part_code, p_warehouse_ware_code)
#
#
############################################################
FUNCTION cost_ledger_inquiry(p_cmpy,p_product_part_code,p_warehouse_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE p_warehouse_ware_code LIKE warehouse.ware_code 
	DEFINE r_value SMALLINT 

	OPEN WINDOW i184 with FORM "I184" 
	CALL windecoration_i("I184") 

	IF p_warehouse_ware_code IS NOT NULL THEN 
		IF cl_disp_product(p_cmpy, p_product_part_code, p_warehouse_ware_code) THEN 
			CALL cl_scan_cost(p_cmpy, p_product_part_code, p_warehouse_ware_code) 
		END IF 
	ELSE 
		IF p_product_part_code IS NOT NULL THEN 
			CALL cl_select_ware(p_cmpy, p_product_part_code) 
			RETURNING r_value, p_warehouse_ware_code 
			IF r_value THEN 
				CALL cl_scan_cost(p_cmpy, p_product_part_code, p_warehouse_ware_code) 
			END IF 
		ELSE 
			CALL cl_select_prod(p_cmpy) 
			RETURNING r_value, p_product_part_code, p_warehouse_ware_code 
			IF r_value THEN 
				CALL cl_scan_cost(p_cmpy,p_product_part_code, p_warehouse_ware_code) 
			END IF 
		END IF 
	END IF 

	CLOSE WINDOW i184 
END FUNCTION 



############################################################
# FUNCTION cl_disp_product(p_cmpy,p_product_part_code, p_warehouse_ware_code)
#
#
############################################################
FUNCTION cl_disp_product(p_cmpy,p_product_part_code,p_warehouse_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE p_warehouse_ware_code LIKE warehouse.ware_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	DISPLAY p_product_part_code, 
	p_warehouse_ware_code 
	TO costledg.part_code, 
	costledg.ware_code 
	SELECT * INTO modu_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product_part_code 
	IF status = notfound THEN 
		LET l_msgresp=kandoomsg("I",5010,p_product_part_code) 
		#5010" Logic error: Product code NOT found ????"
		RETURN FALSE 
	END IF 
	SELECT * INTO modu_rec_warehouse.* FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_warehouse_ware_code 
	IF status = notfound THEN 
		LET l_msgresp=kandoomsg("I",5011,p_warehouse_ware_code) 
		#5010" Logic error: Warehouse code NOT found ????"
		RETURN FALSE 
	END IF 
	DISPLAY modu_rec_product.desc_text, 
	modu_rec_product.desc2_text, 
	modu_rec_warehouse.desc_text 
	TO product.desc_text, 
	product.desc2_text, 
	warehouse.desc_text 
	RETURN TRUE 
END FUNCTION 


############################################################
# FUNCTION cl_select_ware(p_cmpy, p_product_part_code)
#
#
############################################################
FUNCTION cl_select_ware(p_cmpy,p_product_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE l_warehouse_ware_code LIKE warehouse.ware_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	DISPLAY p_product_part_code TO costledg.part_code 
	SELECT * INTO modu_rec_product.* FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product_part_code 
	IF status = notfound THEN 
		LET l_msgresp=kandoomsg("I",5010,p_product_part_code) 
		#5010" Logic error: Product code NOT found ????"
		RETURN FALSE, " " 
	END IF 
	DISPLAY modu_rec_product.desc_text, 
	modu_rec_product.desc2_text 
	TO product.desc_text, 
	product.desc2_text 
	LET l_msgresp = kandoomsg("I",1030,"") 

	#1030 Enter Warehouse Code;  OK TO Continue.
	INPUT l_warehouse_ware_code WITHOUT DEFAULTS 
	FROM costledg.ware_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","costlwind","input-ware_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			CASE 
				WHEN infield (ware_code) 
					LET l_warehouse_ware_code = show_ware(p_cmpy) 
					DISPLAY l_warehouse_ware_code TO costledg.ware_code 
					NEXT FIELD ware_code 
			END CASE 

		AFTER FIELD ware_code 
			SELECT * INTO modu_rec_warehouse.* FROM warehouse 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = l_warehouse_ware_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9030,"") 
				# 9010 "Warehouse does NOT exist - Try window"
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE, " " 
	END IF 
	RETURN TRUE, l_warehouse_ware_code 
END FUNCTION 


############################################################
# FUNCTION cl_select_prod(p_cmpy)
#
#
############################################################
FUNCTION cl_select_prod(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_product_part_code LIKE product.part_code 
	DEFINE l_warehouse_ware_code LIKE warehouse.ware_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	INPUT l_product_part_code, 
	l_warehouse_ware_code WITHOUT DEFAULTS 
	FROM costledg.part_code, 
	costledg.ware_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","costlwind","input-l_product_part_code") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (ware_code) 
			LET l_warehouse_ware_code = show_ware(p_cmpy) 
			DISPLAY l_warehouse_ware_code TO costledg.ware_code 
			NEXT FIELD ware_code 


		AFTER FIELD part_code 
			SELECT * INTO modu_rec_product.* FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_product_part_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9010,"") 
				# 9010 Product does NOT exist - Try window
				NEXT FIELD part_code 
			ELSE 
				DISPLAY modu_rec_product.desc_text, 
				modu_rec_product.desc2_text 
				TO product.desc_text, 
				product.desc2_text 
			END IF 

		AFTER FIELD ware_code 
			SELECT * INTO modu_rec_warehouse.* FROM warehouse 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = l_warehouse_ware_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9030,"") 
				# 9010 "Warehouse does NOT exist - Try window"
				NEXT FIELD ware_code 
			ELSE 
				DISPLAY modu_rec_warehouse.desc_text TO warehouse.desc_text 
			END IF 
			SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = p_cmpy 
			AND part_code = l_product_part_code 
			AND ware_code = l_warehouse_ware_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("I",9081,"") 
				# 9081 Product NOT stocked AT this warehouse
				NEXT FIELD ware_code 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				SELECT * INTO modu_rec_product.* FROM product 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_product_part_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9010,"") 
					# 9010 Product does NOT exist - Try window
					NEXT FIELD part_code 
				ELSE 
					DISPLAY modu_rec_product.desc_text, 
					modu_rec_product.desc2_text 
					TO product.desc_text, 
					product.desc2_text 
				END IF 
				SELECT * INTO modu_rec_warehouse.* FROM warehouse 
				WHERE cmpy_code = p_cmpy 
				AND ware_code = l_warehouse_ware_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9030,"") 
					# 9010 "Warehouse does NOT exist - Try window"
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY modu_rec_warehouse.desc_text 
					TO warehouse.desc_text 
				END IF 
				SELECT * INTO modu_rec_prodstatus.* FROM prodstatus 
				WHERE cmpy_code = p_cmpy 
				AND part_code = l_product_part_code 
				AND ware_code = l_warehouse_ware_code 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("I",9081,"") 
					# 9081 Product NOT stocked AT this warehouse
					NEXT FIELD ware_code 
				END IF 

			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		RETURN FALSE, " ", " " 
	END IF 

	RETURN TRUE, l_product_part_code, l_warehouse_ware_code 
END FUNCTION 


############################################################
# FUNCTION cl_scan_cost(p_cmpy,p_product_part_code, p_warehouse_ware_code)
#
#
############################################################
FUNCTION cl_scan_cost(p_cmpy,p_product_part_code,p_warehouse_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_product_part_code LIKE product.part_code 
	DEFINE p_warehouse_ware_code LIKE warehouse.ware_code 
	DEFINE l_msgresp LIKE language.yes_flag 

DEFINE l_arr_rec_costledg DYNAMIC ARRAY OF #array[500] OF RECORD 
	RECORD 
		tran_date LIKE costledg.tran_date, 
		onhand_qty DECIMAL(16,2), 
		curr_cost_amt DECIMAL(16,2), 
		orig_cost_amt DECIMAL(16,2), 
		current_valuation DECIMAL(16,2) 
	END RECORD


	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database;  Please Wait;
	DECLARE c_costledg CURSOR FOR 
	SELECT * INTO modu_rec_costledg.* FROM costledg 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product_part_code 
	AND ware_code = p_warehouse_ware_code 
	AND onhand_qty != 0 
	ORDER BY costledg.tran_date 

	LET modu_idx = 0 
	FOREACH c_costledg 
		LET modu_idx = modu_idx + 1 
		LET l_arr_rec_costledg[modu_idx].tran_date = modu_rec_costledg.tran_date 
		LET l_arr_rec_costledg[modu_idx].onhand_qty = modu_rec_costledg.onhand_qty 
		LET l_arr_rec_costledg[modu_idx].curr_cost_amt = modu_rec_costledg.curr_cost_amt 
		LET l_arr_rec_costledg[modu_idx].orig_cost_amt = modu_rec_costledg.curr_cost_amt + 
		modu_rec_costledg.curr_wo_amt + 
		modu_rec_costledg.prev_wo_amt 
		LET l_arr_rec_costledg[modu_idx].current_valuation = modu_rec_costledg.onhand_qty * 
		modu_rec_costledg.curr_cost_amt 
		IF modu_idx > 500 THEN 
			LET l_msgresp = kandoomsg("I",9105,"500") 
			# 9105 "First 500 cost ledgers selected only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF modu_idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9106,"") 
		# 9105 " No Cost ledgers satisfied the selection criteria"
		RETURN 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	LET modu_tot_valuation = NULL 
	SELECT sum(onhand_qty * curr_cost_amt) INTO modu_tot_valuation FROM costledg 
	WHERE cmpy_code = p_cmpy 
	AND part_code = modu_rec_costledg.part_code 
	AND ware_code = modu_rec_costledg.ware_code 
	DISPLAY modu_tot_valuation TO tot_valuation 

	CALL set_count(modu_idx) 
	LET l_msgresp = kandoomsg("I",1008,"") 

	# F3/F4 TO page forward/backward ESC TO Continue
	INPUT ARRAY l_arr_rec_costledg WITHOUT DEFAULTS FROM sr_costledg.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","costlwind","input-arr-costledg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD tran_date 
			LET modu_idx = arr_curr() 
			#         LET scrn = scr_line()
			LET modu_tran_date = l_arr_rec_costledg[modu_idx].tran_date 
			#         DISPLAY l_arr_rec_costledg[modu_idx].* TO sr_costledg[scrn].*

		AFTER FIELD tran_date 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_costledg[modu_idx+1].tran_date IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("I",9001,"") 
					# There are no more rows in the direction you are going "
					NEXT FIELD tran_date 
				END IF 
			END IF 

		BEFORE FIELD onhand_qty 
			NEXT FIELD tran_date 

		AFTER ROW 
			LET l_arr_rec_costledg[modu_idx].tran_date = modu_tran_date 
			#         DISPLAY l_arr_rec_costledg[modu_idx].* TO sr_costledg[scrn].*

	END INPUT 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	CLEAR FORM 


	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
END FUNCTION 
