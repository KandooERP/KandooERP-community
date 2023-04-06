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

	Source code beautified by beautify.pl on 2020-01-03 09:12:24	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
GLOBALS "I27_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I27 which allows the user TO adjustment products FROM inventory



DEFINE 
pr_product RECORD LIKE product.*, 
pr_prodstatus RECORD LIKE prodstatus.*, 
pr_prodadjtype RECORD LIKE prodadjtype.*, 
pr_direction CHAR(1), 
pr_prodledg RECORD LIKE prodledg.*, 
pr_category RECORD LIKE category.*, 
winds_text CHAR(200), 
pr_coa RECORD LIKE coa.*, 
pr_warehouse RECORD LIKE warehouse.*, 
adjustment_text CHAR(8), 
try_again CHAR(1), 
err_message CHAR(40), 
stock_tran_qty LIKE prodledg.tran_qty, 
stock_cost_amt LIKE prodledg.cost_amt, 
sell_tran_qty LIKE prodledg.tran_qty, 
sell_cost_amt LIKE prodledg.cost_amt, 
mask_code LIKE warehouse.acct_mask_code, 
chng_qty DECIMAL(12,2), 
avail_qty, availf_qty LIKE prodstatus.onhand_qty, 
failed_it, adjusted, bacheq_code SMALLINT, 
pr_opparms RECORD LIKE opparms.* 

DEFINE pr_inparms RECORD LIKE inparms.* 
DEFINE pr_reedit CHAR(1) 
DEFINE ans CHAR(1)

MAIN 
	#Initial UI Init
	CALL setModuleId("I27") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 


	SELECT * INTO pr_inparms.* FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = notfound THEN 
		LET msgresp = kandoomsg("I","5002","") 
		#5002 Inventory Parameters are NOT Set Up;  Refer Menu IZP.
		EXIT program 
	END IF 

	SELECT * INTO pr_opparms.* FROM opparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_num = "1" 
	IF status = notfound THEN 
		LET pr_opparms.cal_available_flag = "N" 
	END IF 

	LET adjustment_text = "ADJUST" 
	LET adjusted = 0 
	LET ans = "Y" 
	WHILE ans = "Y" 
		IF pr_inparms.cost_ind matches "[FL]" THEN 
			CALL doit() 
		ELSE 
			CALL getitem() 
			CLOSE WINDOW wi123 
		END IF 
	END WHILE 
END MAIN 


FUNCTION getitem() 
	DEFINE 
	pr_serialinfo RECORD LIKE serialinfo.*, 
	pr_sto_part_code LIKE prodstatus.part_code, 
	pr_sto_ware_code LIKE prodstatus.ware_code, 
	pr_sto_sell_tran_qty LIKE prodledg.tran_qty, 
	pr_sto_source_text LIKE prodledg.source_text,
	pr_sto_adj_type_code LIKE prodledg.source_code, 
	pr_lastkey INTEGER, 
	pr_cnt INTEGER, 
	pr_pos_adj CHAR(1) 


	OPEN WINDOW wi123 with FORM "I123" 
	 CALL windecoration_i("I123") 

	LET msgresp = kandoomsg("I","1504","") 
	#1504 Enter Product Adjustment details; OK TO continue.
	LET pr_prodledg.tran_date = today 
	LET pr_prodledg.tran_qty = 0 
	LET pr_prodledg.cost_amt = 0 
	LET stock_tran_qty = 0 
	LET stock_cost_amt = 0 
	LET sell_tran_qty = 0 
	LET sell_cost_amt = 0 
	LET chng_qty = 0 
	LET pr_prodledg.source_num = 0 
	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "2" THEN 
		LET pr_prodledg.source_text = "Adjust" 
	END IF 
	CALL serial_init(glob_rec_kandoouser.cmpy_code,'','','') 
	LET pr_cnt = 0 
	LET pr_pos_adj = 'Y' 

	DISPLAY pr_prodstatus.part_code, 
	pr_prodstatus.ware_code, 
	pr_prodledg.tran_date, 
	pr_prodledg.year_num, 
	pr_prodledg.period_num, 
	pr_prodledg.source_text, 
	pr_prodledg.source_num, 
	pr_prodledg.desc_text, 
	pr_prodledg.acct_code, 
	stock_tran_qty, 
	stock_cost_amt, 
	sell_tran_qty, 
	sell_cost_amt 
	TO prodstatus.part_code, 
	prodstatus.ware_code, 
	prodledg.tran_date, 
	prodledg.year_num, 
	prodledg.period_num, 
	prodledg.source_text, 
	prodledg.source_num, 
	prodledg.desc_text, 
	prodledg.acct_code, 
	stock_tran_qty, 
	stock_cost_amt, 
	sell_tran_qty, 
	sell_cost_amt 


	INPUT pr_prodstatus.part_code, 
	pr_prodstatus.ware_code, 
	pr_prodledg.tran_date, 
	pr_prodledg.year_num, 
	pr_prodledg.source_code,
	pr_prodledg.source_text, 
	pr_prodledg.desc_text, 
	pr_prodledg.acct_code, 
	pr_prodledg.period_num, 
	pr_prodledg.source_num, 
	stock_tran_qty, 
	sell_tran_qty WITHOUT DEFAULTS 
	FROM prodstatus.part_code, 
	prodstatus.ware_code, 
	prodledg.tran_date, 
	prodledg.year_num, 
	prodledg.source_code,
	prodledg.source_text, 
	prodledg.desc_text, 
	prodledg.acct_code, 
	prodledg.period_num, 
	prodledg.source_num, 
	stock_tran_qty, 
	sell_tran_qty 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I27","input-pr_prodstatus-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON KEY (control-b) 
			CASE 
				WHEN infield (part_code) 
					LET winds_text = show_item(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_prodstatus.part_code = winds_text clipped 
					END IF 
					DISPLAY BY NAME pr_prodstatus.part_code 

					NEXT FIELD prodstatus.part_code 
				WHEN infield (acct_code) 
					LET winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_prodledg.acct_code = winds_text clipped 
					END IF 
					DISPLAY BY NAME pr_prodledg.acct_code 

					NEXT FIELD prodledg.acct_code 
				WHEN infield (ware_code) 
					LET winds_text = show_ware(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_prodstatus.ware_code = winds_text clipped 
					END IF 
					DISPLAY BY NAME pr_prodstatus.ware_code 

					NEXT FIELD prodstatus.ware_code 
				WHEN infield (source_text) 
					LET winds_text = show_adj_type_code(glob_rec_kandoouser.cmpy_code) 
					IF winds_text IS NOT NULL THEN 
						LET pr_prodledg.source_text = winds_text clipped 
						SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
						WHERE source_code = pr_prodledg.source_text 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code
						LET pr_prodledg.source_type = "PADJ" 
						LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
						DISPLAY BY NAME pr_prodledg.source_text, 
						pr_prodledg.acct_code 

						DISPLAY pr_prodledg.desc_text TO prodledg.desc_text 

					END IF 
					NEXT FIELD prodledg.source_text 
			END CASE 
		ON KEY (control-n) 
			IF infield(desc_text) THEN 
				LET pr_prodledg.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code, pr_prodledg.desc_text) 
				NEXT FIELD prodledg.desc_text 
			END IF 

		BEFORE FIELD part_code 
			LET pr_sto_part_code = pr_prodstatus.part_code 

		AFTER FIELD part_code 
			IF pr_sto_part_code <> pr_prodstatus.part_code THEN 
				CALL serial_init(glob_rec_kandoouser.cmpy_code,'','','') 
				LET pr_cnt = 0 
				LET pr_pos_adj = 'Y' 
			END IF 
			SELECT product.* INTO pr_product.* FROM product 
			WHERE product.part_code = pr_prodstatus.part_code 
			AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("A",9119,"") 
				#9119 Product NOT found;  Try Window.
				NEXT FIELD prodstatus.part_code 
			END IF 
			DISPLAY pr_product.desc_text, 
			pr_product.desc2_text 
			TO product.desc_text, 
			product.desc2_text 

			# check that enough segments have been entered.
			IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, pr_prodstatus.part_code, 1) THEN 
				LET msgresp = kandoomsg("I",9536,"") 
				#9536 Must enter up TO Stock receipting segment
				NEXT FIELD prodstatus.part_code 
			END IF 
			IF pr_product.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9511,"") 
				#9511 This product has been deleted
				NEXT FIELD prodstatus.part_code 
			END IF 
			SELECT * INTO pr_category.* FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cat_code = pr_product.cat_code 
			IF status = notfound THEN 
				LET try_again = error_recover("Category NOT found", status) 
				EXIT program 
			END IF 
			IF pr_prodledg.acct_code IS NULL 
			OR (pr_sto_part_code IS NULL 
			OR pr_sto_part_code != pr_prodstatus.part_code) THEN 
				# DISPLAY default GL adjustments account FROM the category table
				SELECT adj_acct_code INTO pr_prodledg.acct_code 
				FROM category 
				WHERE cmpy_code = pr_product.cmpy_code 
				AND cat_code = pr_product.cat_code 
				SELECT acct_mask_code INTO mask_code FROM warehouse 
				WHERE ware_code = pr_prodstatus.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound OR mask_code IS NULL OR mask_code = " " THEN 
					CALL build_mask(glob_rec_kandoouser.cmpy_code, 
					"??????????????????", 
					" ") 
					RETURNING mask_code 
				END IF 
				SELECT desc_text INTO pr_coa.desc_text FROM coa 
				WHERE coa.acct_code = pr_prodledg.acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET pr_coa.desc_text = NULL 
				END IF 
				LET pr_prodledg.acct_code = build_mask(glob_rec_kandoouser.cmpy_code, 
				mask_code, 
				pr_prodledg.acct_code) 
				DISPLAY pr_prodledg.acct_code, pr_coa.desc_text 
				TO prodledg.acct_code, coa.desc_text 

				SELECT * INTO pr_category.* FROM category 
				WHERE cat_code = pr_product.cat_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

		BEFORE FIELD ware_code 
			LET pr_sto_ware_code = pr_prodstatus.ware_code 

		AFTER FIELD ware_code 
			IF pr_sto_ware_code <> pr_prodstatus.ware_code 
			AND pr_pos_adj = 'N' then 
				CALL serial_init(glob_rec_kandoouser.cmpy_code,'','','') 
				LET pr_cnt = 0 
				LET pr_pos_adj = 'Y' 
			END IF 
			SELECT prodstatus.* INTO pr_prodstatus.* FROM prodstatus 
			WHERE prodstatus.part_code = pr_prodstatus.part_code 
			AND prodstatus.ware_code = pr_prodstatus.ware_code 
			AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				LET msgresp = kandoomsg("A",9126,"") 
				#9126 Product NOT stocked AT this warehouse.
				NEXT FIELD prodstatus.part_code 
			END IF 
			IF pr_prodstatus.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9510,"") 
				NEXT FIELD prodstatus.part_code 
			END IF 
			SELECT warehouse.desc_text INTO pr_warehouse.desc_text FROM warehouse 
			WHERE warehouse.ware_code = pr_prodstatus.ware_code 
			AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = notfound) THEN 
				LET msgresp = kandoomsg("A",9091,"") 
				#9091 Warehouse NOT found;  Try Window.
				NEXT FIELD prodstatus.part_code 
			END IF 
			DISPLAY pr_warehouse.desc_text TO warehouse.desc_text 


			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING pr_prodledg.year_num, pr_prodledg.period_num 

			DISPLAY BY NAME pr_prodledg.period_num, 
			pr_prodledg.year_num, 
			pr_prodledg.tran_date 


			IF pr_opparms.cal_available_flag = "N" THEN 
				LET avail_qty = pr_prodstatus.onhand_qty - 
				pr_prodstatus.reserved_qty - 
				pr_prodstatus.back_qty 
			ELSE 
				LET avail_qty = pr_prodstatus.onhand_qty - 
				pr_prodstatus.reserved_qty 
			END IF 
			LET availf_qty = avail_qty + 
			pr_prodstatus.onord_qty - 
			pr_prodstatus.forward_qty 


			DISPLAY pr_prodstatus.part_code, 
			pr_product.desc_text, 
			pr_product.desc2_text, 
			pr_prodstatus.ware_code, 
			pr_warehouse.desc_text, 
			avail_qty, 
			avail_qty, 
			availf_qty, 
			pr_product.stock_uom_code, 
			pr_product.sell_uom_code, 
			pr_product.stock_uom_code, 
			pr_product.sell_uom_code, 
			pr_prodstatus.onhand_qty, 
			pr_prodstatus.back_qty, 
			pr_prodstatus.forward_qty, 
			pr_prodstatus.onord_qty, 
			pr_prodstatus.reserved_qty, 
			pr_prodledg.desc_text, 
			pr_prodledg.tran_date, 
			pr_prodledg.year_num, 
			pr_prodledg.period_num, 
			pr_prodledg.source_text, 
			pr_prodledg.source_num 
			TO prodstatus.part_code, 
			product.desc_text, 
			product.desc2_text, 
			prodstatus.ware_code, 
			warehouse.desc_text, 
			avail_qty, 
			avail1_qty, 
			availf_qty, 
			product.stock_uom_code, 
			product.sell_uom_code, 
			stku, 
			seku, 
			prodstatus.onhand_qty, 
			prodstatus.back_qty, 
			prodstatus.forward_qty, 
			prodstatus.onord_qty, 
			prodstatus.reserved_qty, 
			prodledg.desc_text, 
			prodledg.tran_date, 
			prodledg.year_num, 
			prodledg.period_num, 
			prodledg.source_text, 
			prodledg.source_num 

			CASE 
				WHEN pr_inparms.cost_ind = "W" 
					LET sell_cost_amt = pr_prodstatus.wgted_cost_amt 

				OTHERWISE 
					LET sell_cost_amt = pr_prodstatus.wgted_cost_amt 
			END CASE 
			LET stock_cost_amt = sell_cost_amt * pr_product.stk_sel_con_qty 
			DISPLAY stock_cost_amt, 
			sell_cost_amt 
			TO stock_cost_amt, 
			sell_cost_amt 

		AFTER FIELD tran_date 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, pr_prodledg.tran_date) 
			RETURNING pr_prodledg.year_num, pr_prodledg.period_num 

			DISPLAY BY NAME pr_prodledg.period_num, 
			pr_prodledg.year_num, 
			pr_prodledg.tran_date 

		AFTER FIELD year_num 
			IF pr_prodledg.year_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be enetred.
				NEXT FIELD year_num 
			END IF 
		AFTER FIELD period_num 
			IF pr_prodledg.period_num IS NULL THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be enetred.
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_prodledg.year_num, 
			pr_prodledg.period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING pr_prodledg.year_num, 
			pr_prodledg.period_num, 
			failed_it 
			IF failed_it = 1 THEN 
				NEXT FIELD prodledg.year_num 
			END IF 
			
		BEFORE FIELD source_code 
			LET pr_sto_source_text = pr_prodledg.source_code 
		
		AFTER FIELD source_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
				IF pr_prodledg.source_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9167,"") 
					#9167 Adjustment type code must be entered.
					NEXT FIELD prodledg.source_code 
				END IF 
				SELECT * INTO pr_prodadjtype.* FROM prodadjtype 
				WHERE source_code = pr_prodledg.source_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("I",9166,"") 
					#9166 Adjustment Type Not Found - Try Window
					NEXT FIELD prodledg.source_code 
				END IF 
				IF pr_prodledg.source_code IS NULL THEN 
					LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
				END IF 
				LET pr_prodledg.source_type = "PADJ" 
				IF pr_sto_source_text IS NULL 
				OR pr_sto_source_text != pr_prodledg.source_code THEN 
					LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
					LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
				END IF 
				IF pr_prodledg.acct_code IS NULL THEN 
					SELECT acct_mask_code INTO mask_code FROM warehouse 
					WHERE ware_code = pr_prodstatus.ware_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound OR mask_code IS NULL 
					OR mask_code = " " THEN 
						CALL build_mask(glob_rec_kandoouser.cmpy_code, 
						"??????????????????", 
						" ") 
						RETURNING mask_code 
					END IF 
					LET pr_prodledg.acct_code = build_mask(glob_rec_kandoouser.cmpy_code, 
					mask_code, pr_prodadjtype.adj_acct_code) 
				END IF 
			ELSE 
				IF pr_sto_source_text IS NULL 
				OR pr_sto_source_text != pr_prodledg.source_code THEN 
					SELECT * INTO pr_prodadjtype.* 
					FROM prodadjtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = pr_prodledg.source_code 
					IF status != notfound THEN 
						LET pr_prodledg.acct_code = pr_prodadjtype.adj_acct_code 
						LET pr_prodledg.desc_text = pr_prodadjtype.desc_text 
					END IF 
				END IF 
				IF pr_prodledg.acct_code IS NULL THEN 
					LET pr_prodledg.acct_code = pr_category.adj_acct_code 
				END IF 
			END IF 
			SELECT desc_text INTO pr_coa.desc_text 
			FROM coa 
			WHERE coa.acct_code = pr_prodledg.acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET pr_coa.desc_text = NULL 
			END IF 
			DISPLAY pr_prodledg.source_text, 
			pr_prodledg.desc_text, 
			pr_prodledg.acct_code, 
			pr_coa.desc_text 
			TO prodledg.source_text, 
			prodledg.desc_text, 
			prodledg.acct_code, 
			coa.desc_text 

		AFTER FIELD acct_code 
			SELECT coa.* INTO pr_coa.* FROM coa 
			WHERE coa.acct_code = pr_prodledg.acct_code 
			AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = notfound THEN 
				LET msgresp = kandoomsg("G",9112,"") 
				#9112  Account code does NOT exist;  Try Window.
				NEXT FIELD prodledg.acct_code 
			ELSE 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 
			END IF 
			DISPLAY pr_coa.desc_text TO coa.desc_text 

		BEFORE FIELD source_num 
			IF fgl_lastkey() = fgl_keyval("up") THEN 
				LET pr_direction = "U" 
			ELSE 
				LET pr_direction = "D" 
			END IF 
			IF pr_inparms.auto_adjust_flag = "Y" THEN 
				IF pr_direction = "U" THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		BEFORE FIELD stock_tran_qty 
			IF pr_product.serial_flag = 'Y' THEN 
				IF fgl_lastkey() = fgl_keyval("up") 
				OR fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD stock_tran_qty 
			IF stock_tran_qty = 0 THEN 
				LET sell_tran_qty = 0 
				DISPLAY sell_tran_qty TO sell_tran_qty 

				NEXT FIELD sell_tran_qty 
			ELSE 
				LET sell_tran_qty = stock_tran_qty * pr_product.stk_sel_con_qty 
				DISPLAY sell_tran_qty TO sell_tran_qty 

			END IF 

		BEFORE FIELD sell_tran_qty 
			LET pr_sto_sell_tran_qty = sell_tran_qty 

		AFTER FIELD sell_tran_qty 
			IF sell_tran_qty IS NULL 
			OR sell_tran_qty = 0 THEN 
				LET msgresp = kandoomsg("U",9102,"") 
				#9102      Value must be entered
				NEXT FIELD sell_tran_qty 
			ELSE 
				IF pr_product.stk_sel_con_qty <> 0 THEN 
					LET stock_tran_qty = sell_tran_qty / pr_product.stk_sel_con_qty 
					DISPLAY stock_tran_qty TO stock_tran_qty 
				END IF 
			END IF 

			IF pr_product.serial_flag = 'Y' THEN 
				IF sell_tran_qty > 0 
				AND pr_sto_sell_tran_qty < 0 THEN 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, '', '', '' ) 
					LET pr_cnt = 0 
					LET pr_pos_adj = 'Y' 
				END IF 
				IF sell_tran_qty < 0 
				AND ( pr_sto_sell_tran_qty > 0 
				OR pr_pos_adj = 'Y' ) THEN 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, '', '0', '' ) 
					LET pr_cnt = 0 
					LET pr_pos_adj = 'N' 
				END IF 

				LET pr_lastkey = fgl_lastkey() 
				LET pr_cnt = serial_input(pr_product.part_code, 
				pr_prodstatus.ware_code,pr_cnt) 
				IF pr_cnt < 0 THEN 
					EXIT program 
				ELSE 
					IF sell_tran_qty > 0 THEN 
						IF pr_cnt <> sell_tran_qty THEN 
							LET msgresp = kandoomsg("I",9299,"") 
							#9299 Number of Serial codes entered needs TO = Quant
							NEXT FIELD sell_tran_qty 
						END IF 
					ELSE 
						IF pr_cnt <> ( -1 * sell_tran_qty ) THEN 
							LET msgresp = kandoomsg("I",9299,"") 
							#9299 Number of Serial codes entered needs TO = Quant
							NEXT FIELD sell_tran_qty 
						END IF 
					END IF 
					IF pr_lastkey = fgl_keyval("up") 
					OR pr_lastkey = fgl_keyval("left") THEN 
						NEXT FIELD sell_tran_qty 
					ELSE 
						NEXT FIELD tran_date 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF int_flag != 0 OR quit_flag != 0 THEN 
				EXIT program 
			ELSE 
				SELECT warehouse.desc_text INTO pr_warehouse.desc_text 
				FROM warehouse 
				WHERE warehouse.ware_code = pr_prodstatus.ware_code 
				AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("A",9091,"") 
					#9091  Warehouse NOT found;  Try Window.ma/kandoomsg
					NEXT FIELD prodstatus.ware_code 
				END IF 
				
				SELECT prodstatus.* INTO pr_prodstatus.* 
				FROM prodstatus 
				WHERE prodstatus.part_code = pr_prodstatus.part_code 
				AND prodstatus.ware_code = pr_prodstatus.ware_code 
				AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF (status = notfound) THEN 
					LET msgresp = kandoomsg("A",9126,"") 
					#9126 Product NOT stocked AT this warehouse.
					NEXT FIELD prodstatus.part_code 
				END IF 
				IF pr_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9510,"") 
					NEXT FIELD prodstatus.part_code 
				END IF 
				
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
					IF pr_prodledg.source_text IS NULL THEN 
						LET msgresp = kandoomsg("I",9167,"") 
						#9167 Adjustment type code must be entered.
						NEXT FIELD prodledg.source_text 
					END IF 
					SELECT * INTO pr_prodadjtype.* 
					FROM prodadjtype 
					WHERE source_code = pr_prodledg.source_text 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status = notfound THEN 
						LET msgresp = kandoomsg("I",9166,"") 
						#9166 Adjustment Type Not Found - Try Window
						NEXT FIELD source_text 
					END IF 
				END IF 
				SELECT coa.* INTO pr_coa.* 
				FROM coa 
				WHERE coa.acct_code = pr_prodledg.acct_code 
				AND coa.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status = notfound THEN 
					LET msgresp = kandoomsg("G",9112,"") 
					#9112  Account code does NOT exist;  Try Window.
					NEXT FIELD prodledg.acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,pr_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD acct_code 
				END IF 

				# OPEN WINDOW w1_I27 AT 10,7 with 3 rows,52 columns
				#   ATTRIBUTE(border, menu line 2)
				LET pr_reedit = 'N' 
				MENU " Quantity Adjustment " 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","I27","menu-Quantity-1") -- albo kd-505 

					ON ACTION "WEB-HELP" -- albo kd-372 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Save" " Save Adjustment TO Database" 
						EXIT MENU 
					COMMAND KEY("E",Interrupt)"Exit" 
						" RETURN TO editting Adjustment" 
						LET pr_reedit = 'Y' 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				# CLOSE WINDOW w1_I27
				IF pr_reedit = 'Y' THEN 
					NEXT FIELD tran_date 
				END IF 

				# hold all movements in sell qtys
				LET pr_prodledg.tran_qty = sell_tran_qty 
				LET pr_prodledg.cost_amt = sell_cost_amt 
				IF pr_prodledg.tran_qty != 0 THEN 
					SELECT product.* INTO pr_product.* 
					FROM product 
					WHERE product.part_code = pr_prodstatus.part_code 
					AND product.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF (status = notfound) THEN 
						LET msgresp = kandoomsg("A",9119,"") 
						#9119 Product NOT found;  Try Window.
						NEXT FIELD prodstatus.part_code 
					END IF 
					CALL valid_period(glob_rec_kandoouser.cmpy_code, pr_prodledg.year_num,pr_prodledg.period_num, TRAN_TYPE_INVOICE_IN) 
					RETURNING pr_prodledg.year_num,pr_prodledg.period_num,failed_it 
					IF failed_it = 1 THEN 
						NEXT FIELD prodledg.year_num 
					END IF 

					GOTO bypass 
					LABEL recovery: 
					LET try_again = error_recover(err_message, status) 
					IF try_again != "Y" THEN 
						EXIT program 
					END IF 
					LABEL bypass: 
					WHENEVER ERROR GOTO recovery 

					BEGIN WORK 
						LET err_message = "I27 - Prod Status UPDATE" 
						SELECT * INTO pr_inparms.* 
						FROM inparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND parm_code = "1" 
						IF pr_inparms.auto_adjust_flag = "Y" THEN 
							LET pr_inparms.next_adjust_num = pr_inparms.next_adjust_num + 1 
							UPDATE inparms 
							SET next_adjust_num = pr_inparms.next_adjust_num 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND parm_code = "1" 
							LET pr_prodledg.source_num = pr_inparms.next_adjust_num 
						END IF 

						DECLARE ps_curs CURSOR FOR 
						SELECT prodstatus.* INTO pr_prodstatus.* 
						FROM prodstatus 
						WHERE prodstatus.part_code = pr_prodstatus.part_code 
						AND prodstatus.ware_code = pr_prodstatus.ware_code 
						AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
						FOR UPDATE 
						FOREACH ps_curs 
							LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
							LET chng_qty = 0 
							IF pr_prodstatus.stocked_flag = "Y" THEN 
								LET pr_prodstatus.onhand_qty = 
								pr_prodstatus.onhand_qty + pr_prodledg.tran_qty 
							ELSE 
								LET pr_prodstatus.onhand_qty = 0 
							END IF 

							UPDATE prodstatus 
							SET seq_num = pr_prodstatus.seq_num, 
							onhand_qty = pr_prodstatus.onhand_qty 
							WHERE CURRENT OF ps_curs 
						END FOREACH 

						LET pr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET pr_prodledg.part_code = pr_prodstatus.part_code 
						LET pr_prodledg.ware_code = pr_prodstatus.ware_code 
						LET pr_prodledg.seq_num = pr_prodstatus.seq_num 
						LET pr_prodledg.trantype_ind = "A" 
						LET pr_prodledg.sales_amt = 0 
						LET pr_prodledg.tran_qty = pr_prodledg.tran_qty 
						IF pr_inparms.hist_flag = "Y" THEN 
							LET pr_prodledg.hist_flag = "N" 
						ELSE 
							LET pr_prodledg.hist_flag = "Y" 
						END IF 
						LET pr_prodledg.post_flag = "N" 
						LET pr_prodledg.bal_amt = pr_prodstatus.onhand_qty 
						LET pr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
						LET pr_prodledg.entry_date = today 
						LET err_message = "I27 - Product ledger INSERT" 
						INSERT INTO prodledg VALUES (pr_prodledg.*) 

						IF pr_product.serial_flag = "Y" THEN 
							IF sell_tran_qty < 0 THEN 
								LET err_message = "I27 - serial_update (del)" 
								LET pr_serialinfo.cmpy_code = pr_prodledg.cmpy_code 
								LET pr_serialinfo.part_code = pr_prodledg.part_code 
								LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
								LET pr_serialinfo.trantype_ind = "X" 
								LET status = serial_update(pr_serialinfo.*, 
								sell_tran_qty, "") 
								IF status <> 0 THEN 
									GOTO recovery 
									EXIT program 
								END IF 
							ELSE 
								LET err_message = "I27 - serial_update " 
								LET pr_serialinfo.cmpy_code = pr_prodledg.cmpy_code 
								LET pr_serialinfo.part_code = pr_prodledg.part_code 
								LET pr_serialinfo.ware_code = pr_prodledg.ware_code 
								LET pr_serialinfo.receipt_date = pr_prodledg.tran_date 
								LET pr_serialinfo.receipt_num = pr_prodledg.seq_num 
								LET pr_serialinfo.vend_code = NULL 
								LET pr_serialinfo.trantype_ind = "0" 
								LET status = serial_update(pr_serialinfo.*, 
								sell_tran_qty, "") 
								IF status <> 0 THEN 
									GOTO recovery 
									EXIT program 
								END IF 
							END IF 
						END IF 
					COMMIT WORK 
					LET msgresp = kandoomsg("I",7048,pr_prodledg.source_num) 
					#7048 Successful Adjustment ,source_num
					LET adjusted = 1 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
END FUNCTION 
