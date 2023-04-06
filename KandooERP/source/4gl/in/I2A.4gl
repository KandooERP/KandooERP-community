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

	Source code beautified by beautify.pl on 2020-01-03 09:12:26	$Id: $
}
# Stock Reclassification
# allows product code TO be changed FOR existing stock items
# A product ledger RECORD IS created FOR both old out,new in
# stock movements. Reclassification prodledg
# entries are NOT posted

# TODO: clean code priority 1 pending ericv
# TODO: clean code priority 2
# TODO: clean code priority 3
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

	DEFINE t_rec_product_new TYPE AS RECORD 
		part_code_new LIKE product.part_code, 
		prod_desc LIKE product.desc_text, 
		prod_desc_new LIKE product.desc_text, 
		desc2_text_new LIKE product.desc2_text, 
		onhand_qty_new LIKE prodstatus.onhand_qty, 
		reserved_new LIKE prodstatus.reserved_qty, 
		onord_new LIKE prodstatus.onord_qty, 
		avail_qty_new LIKE prodstatus.onhand_qty, 
		sell_uom LIKE product.sell_uom_code, 
		sell_uom_new LIKE product.sell_uom_code, 
		stock_qty LIKE prodstatus.onhand_qty, 
		tran3_qty LIKE prodstatus.onhand_qty, 
		stock3_uom_code LIKE product.sell_uom_code, 
		stock3_qty LIKE prodstatus.onhand_qty, 
		sell3_uom_code LIKE product.sell_uom_code 
	END RECORD
	DEFINE modu_rec_inparms RECORD LIKE inparms.* 
	--DEFINE pr_start,pr_length,l_flex,pr_dashlength,i SMALLINT, 
	--pr_part,parent_part,flex_part LIKE product.part_code, 
	--winds_text,filter_text CHAR(200), 
	--ps_product RECORD LIKE product.*, 
	--l_warehouse_desc LIKE warehouse.desc_text, 
	--avail_qty LIKE prodstatus.onhand_qty, 
	--DEFINE err_continue CHAR(1), err_message CHAR(40)
	
--END GLOBALS 

MAIN 
	DEFINE 
	pr_output CHAR(20), 
	i INTEGER 

	#Initial UI Init
	CALL setModuleId("I2A") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 
	
	SELECT * INTO modu_rec_inparms.* 
	FROM inparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF sqlca.sqlcode = notfound THEN 
		LET msgresp = kandoomsg("I",5002,"") 
		# I5002 Inventory parameters NOT SET up, run IZP
		EXIT program 
	END IF 
	OPEN WINDOW i637 with FORM "I637" 
	 CALL windecoration_i("I637") -- albo kd-758 

	CALL I2A_main()
	
END MAIN 

FUNCTION I2A_main ()
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	MENU "I2A"
		COMMAND "Reclass" "Reclass a product / change part code"
			CALL reclass_product() --
			RETURNING l_rec_prodledg.*
			
			IF l_rec_prodledg.part_code IS NOT NULL THEN
				CALL save_reclass(l_rec_prodledg.*)
				RETURNING l_rec_prodledg.source_num
			END IF
--			DISPLAY BY NAME l_rec_prodledg.source_num , 
--				l_rec_prodstatus.onhand_qty, 
--				avail_qty, 
--				l_rec_product_new.onhand_qty_new, 
--				l_rec_product_new.avail_qty_new 

		--LET msgresp = kandoomsg("I",7002,l_rec_prodledg.source_num) 
		#7002 Reclassification no ?? successfully added Any Key TO Continue
			
		COMMAND "Exit" "Exit Program"
			EXIT PROGRAM
	END MENU

END	FUNCTION # I2A_main

FUNCTION reclass_product() 
	DEFINE l_rec_product_old RECORD LIKE product.*
	DEFINE l_rec_product_temp RECORD LIKE product.*
	DEFINE l_rec_product_new t_rec_product_new 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_prodstatus_temp RECORD LIKE prodstatus.*
	DEFINE l_rec_prodstatus_new RECORD LIKE prodstatus.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_prodadjtype RECORD LIKE prodadjtype.*
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_rec_category RECORD LIKE category.*, 
	invalid_period INTEGER
	DEFINE l_conv_qty LIKE uomconv.conversion_qty
	DEFINE l_avail_qty LIKE prodstatus.onhand_qty
	DEFINE l_parent_part LIKE product.part_code
	DEFINE l_warehouse_desc LIKE warehouse.desc_text
	DEFINE l_dashes LIKE product.part_code
	DEFINE l_flex_part LIKE product.part_code
	DEFINE l_flex SMALLINT
	--pr_part_length , pr_stock_level_len LIKE prodstructure.length, 
	DEFINE pr_stat_ind SMALLINT 
	DEFINE l_winds_text STRING
	DEFINE l_where_clause STRING

	# cursor declared, but never used , why ??? ericv 2020-09-29
	--DECLARE struccur CURSOR FOR 
	--SELECT * FROM prodstructure 
	--WHERE class_code = l_rec_product_old.class_code 
	--	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	-- ORDER BY seq_num 
	INITIALIZE l_rec_prodledg.* TO NULL 
	INITIALIZE l_rec_product_old.* TO NULL 
	INITIALIZE l_rec_product_temp.* TO NULL 
	INITIALIZE l_rec_prodstatus.* TO NULL 
	INITIALIZE l_rec_prodstatus_temp.* TO NULL 
	INITIALIZE l_rec_product_new.* TO NULL 
	CLEAR FORM 
	LET l_rec_prodledg.tran_date = today 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_prodledg.tran_date) 
	RETURNING l_rec_prodledg.year_num, 
	l_rec_prodledg.period_num 
	LET msgresp = kandoomsg("I",1308,"") 
	# I1308 Enter Reclassification details - Esc TO Continue
	INPUT BY NAME l_rec_prodledg.ware_code, 
		l_rec_prodledg.part_code, 
		l_rec_product_new.part_code_new, 
		l_rec_prodledg.tran_date, 
		l_rec_prodledg.year_num, 
		l_rec_prodledg.period_num, 
		l_rec_prodledg.source_code,
		l_rec_prodledg.source_text, 
		l_rec_prodledg.desc_text, 
		l_rec_product_new.stock_qty, 
		l_rec_prodledg.tran_qty 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","I2A","input-l_rec_prodledg-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Lookup"
			CASE 
				WHEN infield(ware_code) 
					LET l_winds_text = show_wlocn(glob_rec_kandoouser.cmpy_code) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_prodledg.ware_code = l_winds_text clipped 
					END IF 
					NEXT FIELD ware_code 
				WHEN infield(part_code) 
					LET l_winds_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_prodledg.part_code = l_winds_text clipped 
					END IF 
					NEXT FIELD part_code 
				WHEN infield(part_code_new) 
					LET l_where_clause = "product.cat_code = '", 
					l_rec_product_old.cat_code,"' ", 
					" AND product.class_code = '", 
					l_rec_product_old.class_code,"' " 
					LET l_winds_text = show_part(glob_rec_kandoouser.cmpy_code,l_where_clause) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_product_new.part_code_new = l_winds_text clipped 
					END IF 
					NEXT FIELD part_code_new 
				WHEN infield (source_code) 
					LET l_winds_text = show_adj_type_code(glob_rec_kandoouser.cmpy_code) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_prodledg.source_code = l_winds_text clipped 
						LET l_rec_prodledg.source_type = "PADJ"			#the source is a product adjustement
						SELECT * INTO l_rec_prodadjtype.* 
						FROM prodadjtype 
						WHERE source_code = l_rec_prodledg.source_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						LET l_rec_prodledg.desc_text = l_rec_prodadjtype.desc_text 
						LET l_rec_prodledg.acct_code = l_rec_prodadjtype.adj_acct_code 
						DISPLAY BY NAME l_rec_prodledg.source_code 

					END IF 
					DISPLAY l_rec_prodledg.desc_text TO prodledg.desc_text 

					NEXT FIELD prodledg.source_code 
			END CASE 
		ON ACTION "Notes"
			IF infield(desc_text) THEN 
				LET l_rec_prodledg.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code, l_rec_prodledg.desc_text) 
				NEXT FIELD desc_text 
			END IF 

		ON CHANGE ware_code 
			IF l_rec_prodledg.ware_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9029,"") 
				#9029 Warehouse must be entered
				NEXT FIELD ware_code 
			ELSE 
				SELECT desc_text INTO l_warehouse_desc 
				FROM warehouse 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = l_rec_prodledg.ware_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9030,"") 
					#9030 warehouse IS NOT found, try window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_warehouse_desc TO warehouse_desc
				END IF 
			END IF 
			# Setup the product combo with products handled by this warehouse
			CALL combolist_prodstatus_productcode_in_warehouse("part_code",l_rec_prodledg.ware_code,	COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --warehouse existing products 

		ON CHANGE part_code 
			IF l_rec_prodledg.part_code IS NULL THEN 
				LET msgresp = kandoomsg("I",9186,"") 
				#9186 Old Product Code must be entered
				NEXT FIELD part_code 
			ELSE 
				SELECT * INTO l_rec_product_old.* 
				FROM product 
				WHERE part_code = l_rec_prodledg.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9188,"") 
					# 9188 Old Product IS NOT found, try window
					NEXT FIELD part_code 
				END IF 
				
				SELECT * INTO l_rec_prodstatus.* 
				FROM prodstatus 
				WHERE part_code = l_rec_prodledg.part_code 
				AND ware_code = l_rec_prodledg.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9191,"") 
					# 9191 Product Does Not Exist AT This Warehouse
					NEXT FIELD part_code 
				END IF 
				IF l_rec_product_old.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9511,"") 
					#9511 This product has been deleted
					NEXT FIELD part_code 
				END IF 
				IF l_rec_prodstatus.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9510,"") 
					#9510 Product does NOT exist AT this warehouse
					NEXT FIELD part_code 
				END IF 
				# check that enough segments have been entered.
				IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, l_rec_prodledg.part_code, true) THEN 
					LET msgresp = kandoomsg("I",9536,"") 
					#9536 Must enter up TO Stock receipting segment
					NEXT FIELD part_code 
				END IF 
				IF l_rec_prodstatus.reserved_qty IS NULL THEN 
					LET l_rec_prodstatus.reserved_qty = 0 
				END IF 
				LET l_rec_product_new.sell_uom = l_rec_product_old.sell_uom_code 
				LET l_rec_product_new.prod_desc = l_rec_product_old.desc_text 
				LET l_avail_qty = l_rec_prodstatus.onhand_qty - l_rec_prodstatus.reserved_qty - l_rec_prodstatus.onord_qty 
				
				DISPLAY BY NAME l_rec_prodstatus.onhand_qty, 
					l_rec_product_new.sell_uom, 
					l_rec_prodstatus.reserved_qty, 
					l_rec_prodstatus.onord_qty, 
					l_rec_product_new.prod_desc, 
					l_rec_product_old.stock_uom_code, 
					l_rec_product_old.sell_uom_code, 
					l_rec_product_old.desc2_text
					
					DISPLAY l_avail_qty TO avail_qty
			END IF 
		
		ON CHANGE part_code_new 
			IF l_rec_product_new.part_code_new IS NULL THEN 
				LET msgresp = kandoomsg("I",9187,"") 
				#9187 New Product Code must be entered
				NEXT FIELD part_code_new 
			ELSE 
				IF l_rec_product_new.part_code_new = l_rec_prodledg.part_code THEN 
					LET msgresp = kandoomsg("I",9218,"") 
					#9218 New Product Code must NOT be the same as Original
					NEXT FIELD part_code_new 
				END IF 
				
				SELECT * INTO l_rec_class.* 
				FROM class 
				WHERE class_code = l_rec_product_old.class_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				# check if new product is parent
				CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product_new.part_code_new,l_rec_product_old.class_code,1) 
				RETURNING l_parent_part,l_dashes,l_flex_part,l_flex 
				
				SELECT * INTO l_rec_product_temp.* 
				FROM product 
				WHERE part_code = l_parent_part 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					IF psep_mult_segs(glob_rec_kandoouser.cmpy_code, l_rec_product_old.class_code) THEN 
						LET msgresp = kandoomsg("I",9211,"") 
						# 9211 Parent Product Not Found
					ELSE 
						LET msgresp = kandoomsg("I",9010,"") 
						# 9010 Product Not Found
					END IF 
					NEXT FIELD part_code_new 
				END IF 
				
				SELECT * INTO l_rec_prodstatus_new.* 
				FROM prodstatus 
				WHERE part_code = l_parent_part 
				AND ware_code = l_rec_prodledg.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9209,"") 
					# 9209 Parent Product Does Not Exist AT This Warehouse
					NEXT FIELD part_code_new 
				END IF 

				# check that enough segments have been entered.
				IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, l_rec_product_new.part_code_new,1) THEN 
					LET msgresp = kandoomsg("I",9536,"") 
					#9536 Must enter up TO Stock receipting segment
					NEXT FIELD part_code_new 
				END IF 

				SELECT * INTO l_rec_product_temp.* 
				FROM product 
				WHERE part_code = l_rec_product_new.part_code_new 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",7047,"") 
					# 7047 new Product IS NOT found, create
					IF msgresp = "Y" THEN 
						SELECT * INTO l_rec_product_temp.* 
						FROM product 
						WHERE part_code = l_rec_product_new.part_code_new 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status != notfound THEN 
							LET msgresp = kandoomsg("I",9507,"") 
							#This product was just written TO the database
							INITIALIZE l_rec_product_new.part_code_new TO NULL 
							NEXT FIELD part_code_new 
						END IF 
						CALL create_prod(l_rec_product_new.part_code_new, l_parent_part,l_flex_part) 
						RETURNING pr_stat_ind, l_rec_product_temp.part_code 
						IF pr_stat_ind THEN ELSE 
							LET msgresp = kandoomsg("I",9535,"") 
							#9535 Invalid product Flexible Segment value
							NEXT FIELD part_code_new 
						END IF 
						
						SELECT * INTO l_rec_product_temp.* 
						FROM product 
						WHERE part_code = l_rec_product_temp.part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF sqlca.sqlcode = notfound THEN 
							LET msgresp = kandoomsg("I",9535,"") 
							#9535 Invalid product Flexible Segment value
							NEXT FIELD part_code_new 
						END IF 
					ELSE 
						NEXT FIELD part_code_new 
					END IF 
				END IF 
				
				IF l_rec_product_temp.cat_code <> l_rec_product_old.cat_code OR l_rec_product_temp.class_code <> l_rec_product_old.class_code THEN 
					LET msgresp = kandoomsg("I",9210,"") 
					# 9210 new Product must be same class & category as old product
					NEXT FIELD part_code_new 
				END IF 
				
				SELECT * INTO l_rec_prodstatus_temp.* 
				FROM prodstatus 
				WHERE part_code = l_rec_product_new.part_code_new 
				AND ware_code = l_rec_prodledg.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("I",9191,"") 
					# 9191 Product Does Not Exist AT This Warehouse
					NEXT FIELD part_code_new 
				END IF 
				IF l_rec_product_temp.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9511,"") 
					#9511 This product has been deleted
					NEXT FIELD part_code_new 
				END IF 
				IF l_rec_prodstatus_temp.status_ind = "3" THEN 
					LET msgresp = kandoomsg("I",9510,"") 
					#9510 Product does NOT exist AT this warehouse
					NEXT FIELD part_code_new 
				END IF 
				IF l_rec_prodstatus_temp.reserved_qty IS NULL THEN 
					LET l_rec_prodstatus_temp.reserved_qty = 0 
				END IF 
				
				SELECT * INTO  l_rec_category.* 
				FROM category 
				WHERE cat_code = l_rec_product_old.cat_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_product_new.stock3_uom_code = l_rec_product_temp.stock_uom_code 
				LET l_rec_product_new.sell3_uom_code = l_rec_product_temp.sell_uom_code 
				LET l_rec_product_new.prod_desc = l_rec_product_temp.desc_text 
				LET l_rec_product_new.sell_uom_new = l_rec_product_temp.sell_uom_code 
				LET l_rec_product_new.desc2_text_new = l_rec_product_temp.desc2_text 
				LET l_rec_product_new.onhand_qty_new = l_rec_prodstatus_temp.onhand_qty 
				LET l_rec_product_new.reserved_new = l_rec_prodstatus_temp.reserved_qty 
				LET l_rec_product_new.onord_new = l_rec_prodstatus_temp.onord_qty 
				LET l_rec_product_new.avail_qty_new = l_rec_prodstatus_temp.onhand_qty - l_rec_prodstatus_temp.reserved_qty - l_rec_prodstatus_temp.onord_qty 

				DISPLAY BY NAME l_rec_product_new.onhand_qty_new, 
				l_rec_product_new.sell_uom_new, 
				l_rec_product_new.reserved_new, 
				l_rec_product_new.onord_new, 
				l_rec_product_new.avail_qty_new, 
				l_rec_product_new.prod_desc, 
				l_rec_product_new.desc2_text_new, 
				l_rec_product_new.stock3_uom_code, 
				l_rec_product_new.sell3_uom_code 
			END IF 
		
		ON CHANGE source_code 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
				IF l_rec_prodledg.source_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9190,"") 
					#9190 Source ID  must be entered
					NEXT FIELD source_code 
				END IF 
				SELECT * INTO l_rec_prodadjtype.* 
				FROM prodadjtype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = l_rec_prodledg.source_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD source_code 
				END IF 
				LET l_rec_prodledg.acct_code = l_rec_prodadjtype.adj_acct_code 
				LET l_rec_prodledg.desc_text = l_rec_prodadjtype.desc_text 
				DISPLAY l_rec_prodledg.desc_text TO prodledg.desc_text 
			ELSE 
				SELECT * INTO l_rec_prodadjtype.* 
				FROM prodadjtype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = l_rec_prodledg.source_code 
				IF status = 0 THEN 
					LET l_rec_prodledg.acct_code = l_rec_prodadjtype.adj_acct_code 
					LET l_rec_prodledg.desc_text = l_rec_prodadjtype.desc_text 
				ELSE 
					LET l_rec_prodledg.acct_code =  l_rec_category.adj_acct_code 
				END IF 
			END IF 
		
		BEFORE FIELD tran_date 
			IF l_rec_prodledg.tran_date IS NULL THEN 
				LET l_rec_prodledg.tran_date = today 
			END IF 
			-- LET l_rec_prodledg.tran_date = l_rec_prodledg.tran_date  ???
		
		ON CHANGE tran_date 
			IF l_rec_prodledg.tran_date != l_rec_prodledg.tran_date THEN 
				CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,l_rec_prodledg.tran_date) 
				RETURNING l_rec_prodledg.year_num, l_rec_prodledg.period_num 
				DISPLAY BY NAME l_rec_prodledg.period_num, 
					l_rec_prodledg.year_num 
			END IF 

		ON CHANGE period_num 
			CALL valid_period(glob_rec_kandoouser.cmpy_code,l_rec_prodledg.year_num, l_rec_prodledg.period_num,TRAN_TYPE_INVOICE_IN) 
			RETURNING l_rec_prodledg.year_num,l_rec_prodledg.period_num, invalid_period 
			IF invalid_period THEN 
				NEXT FIELD year_num 
			END IF 

		ON CHANGE stock_qty 
			IF l_rec_product_new.stock_qty IS NULL THEN 
				LET l_rec_product_new.stock_qty = 0 
			END IF 
			LET l_rec_prodledg.tran_qty = l_rec_product_new.stock_qty * l_rec_product_old.stk_sel_con_qty 
			LET l_conv_qty = get_prod_conv(l_rec_prodledg.part_code,l_parent_part, 	l_rec_product_old.sell_uom_code, l_rec_product_new.sell3_uom_code) 
			IF l_conv_qty = -1 THEN 
				NEXT FIELD stock_qty 
			ELSE 
				LET l_rec_product_new.tran3_qty = l_rec_prodledg.tran_qty/l_conv_qty 
			END IF 
			LET l_conv_qty = get_prod_conv(l_rec_prodledg.part_code,l_parent_part,l_rec_product_old.stock_uom_code, l_rec_product_new.stock3_uom_code) 
			IF l_conv_qty = -1 THEN 
				NEXT FIELD stock_qty 
			ELSE 
				LET l_rec_product_new.stock3_qty = l_rec_product_new.stock_qty/l_conv_qty 
			END IF 
			DISPLAY BY NAME l_rec_prodledg.tran_qty, 
				l_rec_product_new.stock_qty, 
				l_rec_product_new.tran3_qty, 
				l_rec_product_new.stock3_qty 

		ON CHANGE tran_qty 
			IF l_rec_prodledg.tran_qty IS NULL OR 
			l_rec_prodledg.tran_qty <= 0 THEN 
				LET msgresp = kandoomsg("I",9192,"") 
				#9192  Qty Must Be greater than zero
				NEXT FIELD tran_qty 
			END IF 
			IF l_rec_prodledg.tran_qty > l_avail_qty THEN 
				LET msgresp = kandoomsg("I",8034,"") 
				#8034  Qty More Than Available. Continue Anyway? (Y/N)
				IF msgresp = "N" THEN 
					LET l_rec_prodledg.tran_qty = 0 
					NEXT FIELD ware_code 
				END IF 
			END IF 
			LET l_rec_product_new.stock_qty = 
			l_rec_prodledg.tran_qty / l_rec_product_old.stk_sel_con_qty 
			LET l_conv_qty = get_prod_conv(l_rec_prodledg.part_code,l_parent_part,	l_rec_product_old.sell_uom_code, l_rec_product_new.sell3_uom_code) 
			IF l_conv_qty = -1 THEN 
				NEXT FIELD tran_qty 
			ELSE 
				LET l_rec_product_new.tran3_qty = l_rec_prodledg.tran_qty/l_conv_qty 
			END IF 
			LET l_conv_qty = get_prod_conv(l_rec_prodledg.part_code,l_parent_part,l_rec_product_old.stock_uom_code, l_rec_product_new.stock3_uom_code) 
			IF l_conv_qty = -1 THEN 
				NEXT FIELD tran_qty 
			ELSE 
				LET l_rec_product_new.stock3_qty = l_rec_product_new.stock_qty/l_conv_qty 
			END IF 
			DISPLAY BY NAME l_rec_prodledg.tran_qty, 
				l_rec_product_new.stock_qty, 
				l_rec_product_new.tran3_qty, 
				l_rec_product_new.stock3_qty 

		AFTER INPUT 
			IF NOT int_flag THEN 
				IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
					IF l_rec_prodledg.source_code IS NULL THEN 
						LET msgresp = kandoomsg("I",9190,"") 
						#9190 Source ID must be entered
						NEXT FIELD source_code 
					END IF 
					SELECT * INTO l_rec_prodadjtype.* 
					FROM prodadjtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = l_rec_prodledg.source_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp = kandoomsg("U",9105,"") 
						#9105 RECORD NOT found - Try Window
						NEXT FIELD source_code 
					END IF 
					LET l_rec_prodledg.acct_code = l_rec_prodadjtype.adj_acct_code 
					LET l_rec_prodledg.desc_text = l_rec_prodadjtype.desc_text 
				ELSE 
					SELECT * INTO l_rec_prodadjtype.* 
					FROM prodadjtype 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = l_rec_prodledg.source_code 
					IF status = 0 THEN 
						LET l_rec_prodledg.acct_code = l_rec_prodadjtype.adj_acct_code 
					ELSE 
						LET l_rec_prodledg.acct_code =  l_rec_category.adj_acct_code 
					END IF 
				END IF 
				IF l_rec_prodledg.part_code IS NULL THEN 
					LET msgresp = kandoomsg("I",9186,"") 
					#9186 Old Product Code must be entered
					NEXT FIELD part_code 
				END IF 
				
				IF l_rec_product_new.part_code_new IS NULL THEN 
					LET msgresp = kandoomsg("I",9187,"") 
					#9187 new Product Code must be entered
					NEXT FIELD part_code_new 
				END IF 
				IF l_rec_prodledg.tran_qty IS NULL OR l_rec_prodledg.tran_qty <= 0 THEN 
					LET msgresp = kandoomsg("I",9192,"") 
					#9192  Qty Must Be Valid Amount
					NEXT FIELD tran_qty 
				END IF 
				CALL valid_period(glob_rec_kandoouser.cmpy_code,l_rec_prodledg.year_num, l_rec_prodledg.period_num,TRAN_TYPE_INVOICE_IN) 
				RETURNING l_rec_prodledg.year_num, l_rec_prodledg.period_num, invalid_period 
				IF invalid_period THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		LET l_rec_prodledg.source_num = save_reclass(l_rec_prodledg.*) 
		DISPLAY BY NAME l_rec_prodledg.source_num , 
			l_rec_prodstatus.onhand_qty, 
			l_avail_qty, 
			l_rec_product_new.onhand_qty_new, 
			l_rec_product_new.avail_qty_new 

		LET msgresp = kandoomsg("I",7002,l_rec_prodledg.source_num) 
		#7002 Reclassification no ?? successfully added Any Key TO Continue
		RETURN l_rec_prodledg.*
		
	END IF 
END FUNCTION    # reclass_product


FUNCTION get_prod_conv(pr_old_part,pr_new_part,pr_from,pr_to) 
	DEFINE 
	pr_uomconv RECORD LIKE uomconv.*, 
	pr_uomconv1 RECORD LIKE uomconv.*, 
	pr_uomconv2 RECORD LIKE uomconv.*, 
	pr_old_part LIKE product.part_code, 
	pr_new_part LIKE product.part_code, 
	pr_from LIKE uomconv.uom_code, 
	pr_to LIKE uomconv.uom_code, 
	pr_from_qty LIKE uomconv.conversion_qty, 
	pr_to_qty LIKE uomconv.conversion_qty, 
	pr_msg CHAR(40) 

	INITIALIZE pr_uomconv1.* TO NULL 
	INITIALIZE pr_uomconv2.* TO NULL 
	CALL get_uomconv(glob_rec_kandoouser.cmpy_code,pr_old_part,pr_from) RETURNING pr_uomconv1.* 
	IF pr_uomconv1.conversion_qty != -1 THEN 
		CALL get_uomconv(glob_rec_kandoouser.cmpy_code,pr_new_part,pr_to) RETURNING pr_uomconv2.* 
		IF pr_uomconv2.conversion_qty != -1 THEN 
			CALL get_ratio(glob_rec_kandoouser.cmpy_code,pr_old_part,pr_uomconv1.*) 
			RETURNING pr_from_qty,pr_msg 
			IF pr_from_qty != -1 THEN 
				CALL get_ratio(glob_rec_kandoouser.cmpy_code,pr_new_part,pr_uomconv2.*) 
				RETURNING pr_to_qty,pr_msg 
				IF pr_to_qty != -1 THEN 
					IF pr_uomconv2.uom_type = "Q" THEN 
						LET pr_uomconv.conversion_qty = pr_from_qty/pr_to_qty 
					ELSE 
						LET pr_uomconv.conversion_qty = (pr_from_qty/pr_to_qty) 
					END IF 
				ELSE 
					LET pr_uomconv.conversion_qty = -1 
				END IF 
			ELSE 
				LET pr_uomconv.conversion_qty = -1 
			END IF 
		ELSE 
			LET pr_uomconv.conversion_qty = -1 
		END IF 
	ELSE 
		LET pr_uomconv.conversion_qty = -1 
	END IF 
	IF pr_uomconv.conversion_qty = -1 THEN 
		IF pr_uomconv1.conversion_qty = -1 THEN 
			LET msgresp = kandoomsg("U",9701,pr_from) 
			#9701 UOM failed - ",pr_from has NOT been SET up"
			#No conversion factor found
		END IF 
		IF pr_uomconv2.conversion_qty = -1 THEN 
			LET msgresp = kandoomsg("U",9701,pr_to) 
			#9701 UOM failed - ",pr_from has NOT been SET up"
			#No conversion factor found
		END IF 
		IF pr_from_qty = -1 THEN 
			#Conversion factor error found
			ERROR pr_msg 
		END IF 
		IF pr_to_qty = -1 THEN 
			#Conversion factor error found
			ERROR pr_msg 
		END IF 
		LET pr_uomconv.conversion_qty = -1 
		RETURN pr_uomconv.conversion_qty 
	END IF 
	RETURN pr_uomconv.conversion_qty 
END FUNCTION   # get_prod_conv


FUNCTION save_reclass(p_rec_prodledg) 
	DEFINE p_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_inparms RECORD LIKE inparms.*
	DEFINE l_rec_prodledg RECORD LIKE prodledg.*
	DEFINE l_rec_src_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_dst_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_product_new t_rec_product_new 
	DEFINE l_rec_prodadjtype RECORD LIKE prodadjtype.*
	DEFINE l_mask_code LIKE kandoomask.acct_mask_code
	DEFINE l_avail_qty LIKE prodstatus.onhand_qty
	DEFINE l_dashes LIKE product.part_code
	DEFINE l_created SMALLINT
	DEFINE l_temp_text STRING

		BEGIN WORK 
		SET LOCK MODE TO WAIT 2		# Allow 2 seconds of timeout for lock detection
		# Implement a better and safer method to update inparms ericv 2020-09-29
		# 1) immediately update inparms by incrementing next_class_num: this row will be locked till the end of the transaction
		# 2) SELECT the new value from the table: it will for sure be the right value
		UPDATE inparms 
		SET next_class_num = next_class_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		
		SELECT * INTO l_rec_inparms.*
		FROM inparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND parm_code = "1" 
		
		## Old Code
		SELECT * INTO l_rec_src_prodstatus.* 
		FROM prodstatus 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = p_rec_prodledg.ware_code 
		AND part_code = p_rec_prodledg.part_code 

		LET l_rec_src_prodstatus.seq_num = l_rec_src_prodstatus.seq_num + 1 
		IF l_rec_src_prodstatus.stocked_flag = "Y" THEN 
			LET l_rec_src_prodstatus.onhand_qty = l_rec_src_prodstatus.onhand_qty - p_rec_prodledg.tran_qty 
		ELSE 
			LET l_rec_src_prodstatus.onhand_qty = 0 
		END IF 
		
		LET l_temp_text = "I2A - Product Ledger Entry" 
		
		INITIALIZE l_rec_prodledg.* TO NULL 
		
		LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_prodledg.part_code = p_rec_prodledg.part_code 
		LET l_rec_prodledg.ware_code = p_rec_prodledg.ware_code 
		
		SELECT acct_mask_code INTO l_mask_code 
		FROM warehouse 
		WHERE ware_code = l_rec_prodledg.ware_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		CALL build_mask(glob_rec_kandoouser.cmpy_code,l_mask_code, p_rec_prodledg.acct_code) 
			RETURNING l_rec_prodledg.acct_code
			 
		LET l_rec_prodledg.tran_date = p_rec_prodledg.tran_date 
		LET l_rec_prodledg.seq_num = l_rec_src_prodstatus.seq_num 
		LET l_rec_prodledg.trantype_ind = "X" 
		LET l_rec_prodledg.year_num = p_rec_prodledg.year_num 
		LET l_rec_prodledg.period_num = p_rec_prodledg.period_num 
		LET l_rec_prodledg.source_text = p_rec_prodledg.source_text 
		LET l_rec_prodledg.source_num = l_rec_inparms.next_class_num 
		LET l_rec_prodledg.tran_qty = 0 - p_rec_prodledg.tran_qty 
		LET l_rec_prodledg.desc_text = p_rec_prodledg.desc_text 
		LET l_rec_prodledg.bal_amt = l_rec_src_prodstatus.onhand_qty 
		LET l_rec_prodledg.cost_amt = l_rec_src_prodstatus.wgted_cost_amt 
		LET l_rec_prodledg.sales_amt = 0 
		
		IF l_rec_inparms.hist_flag = "Y" THEN 
			LET l_rec_prodledg.hist_flag = "N" 
		ELSE 
			LET l_rec_prodledg.hist_flag = "Y" 
		END IF 
		
		LET l_rec_prodledg.post_flag = "N" 
		LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_prodledg.entry_date = today 

		# Insert old product records
		INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
		
		UPDATE prodstatus 
		SET seq_num = l_rec_src_prodstatus.seq_num, 
			onhand_qty = l_rec_src_prodstatus.onhand_qty 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = p_rec_prodledg.part_code 
			AND ware_code = p_rec_prodledg.ware_code 

		# Tricky part, mixing variable scopes ....  ericv 2020-09-29: when are pr_prodstatus values set ?
		--LET pr_prodstatus.onhand_qty = l_rec_src_prodstatus.onhand_qty 
		--LET avail_qty = pr_prodstatus.onhand_qty - pr_prodstatus.reserved_qty - pr_prodstatus.onord_qty => probably an error, should be from the _src_ record
		-- LET l_rec_prodstatus.onhand_qty = l_rec_src_prodstatus.onhand_qty  # useless
		LET l_avail_qty = l_rec_src_prodstatus.onhand_qty - l_rec_src_prodstatus.reserved_qty - l_rec_src_prodstatus.onord_qty 

		### Setting data for the New Code
		SELECT * INTO l_rec_dst_prodstatus.* 
		FROM prodstatus 
		WHERE prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_product_new.prod2 
			AND ware_code = p_rec_prodledg.ware_code 

		IF l_rec_dst_prodstatus.wgted_cost_amt IS NULL THEN 
			LET l_rec_dst_prodstatus.wgted_cost_amt = 0 
		END IF 
		IF l_rec_dst_prodstatus.act_cost_amt IS NULL THEN 
			LET l_rec_dst_prodstatus.act_cost_amt = 0 
		END IF 
		
		IF (l_rec_dst_prodstatus.onhand_qty + p_rec_prodledg.tran_qty) > 0 THEN 
			LET l_rec_dst_prodstatus.wgted_cost_amt = 
			( ( l_rec_dst_prodstatus.wgted_cost_amt * l_rec_dst_prodstatus.onhand_qty) + ( p_rec_prodledg.tran_qty * l_rec_src_prodstatus.wgted_cost_amt)) /(p_rec_prodledg.tran_qty+l_rec_dst_prodstatus.onhand_qty) 
		END IF 
		LET l_rec_dst_prodstatus.act_cost_amt = l_rec_src_prodstatus.wgted_cost_amt 
		LET l_rec_dst_prodstatus.seq_num = l_rec_dst_prodstatus.seq_num + 1 
		INITIALIZE l_rec_prodledg.* TO NULL 
		LET l_rec_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_prodledg.part_code = l_rec_product_new.part_code_new 
		LET l_rec_prodledg.ware_code = p_rec_prodledg.ware_code 
		
		SELECT acct_mask_code INTO l_mask_code 
		FROM warehouse 
		WHERE ware_code = l_rec_prodledg.ware_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		CALL build_mask(glob_rec_kandoouser.cmpy_code,l_mask_code, p_rec_prodledg.acct_code) 
			RETURNING l_rec_prodledg.acct_code 

		LET l_rec_prodledg.tran_date = p_rec_prodledg.tran_date 
		LET l_rec_prodledg.seq_num = l_rec_dst_prodstatus.seq_num 
		LET l_rec_prodledg.trantype_ind = "X" 
		LET l_rec_prodledg.year_num = p_rec_prodledg.year_num 
		LET l_rec_prodledg.period_num = p_rec_prodledg.period_num 
		LET l_rec_prodledg.source_text = p_rec_prodledg.source_text 
		LET l_rec_prodledg.source_num = l_rec_inparms.next_class_num 
		LET l_rec_prodledg.tran_qty = p_rec_prodledg.tran_qty 
		LET l_rec_prodledg.desc_text = p_rec_prodledg.desc_text 
		LET l_rec_prodledg.bal_amt = l_rec_dst_prodstatus.onhand_qty + p_rec_prodledg.tran_qty 
		LET l_rec_prodledg.cost_amt = l_rec_dst_prodstatus.wgted_cost_amt 
		LET l_rec_prodledg.sales_amt = 0 
		IF l_rec_inparms.hist_flag = "Y" THEN 
			LET l_rec_prodledg.hist_flag = "N" 
		ELSE 
			LET l_rec_prodledg.hist_flag = "Y" 
		END IF 
		LET l_rec_prodledg.post_flag = "N" 
		LET l_rec_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_prodledg.entry_date = today 
		
		# insert the prodledg for new record
	WHENEVER ERROR CONTINUE
		INSERT INTO prodledg VALUES (l_rec_prodledg.*) 
		IF sqlca.sqlcode < 0 THEN
			CALL display_error_and_decide("insert product ledger",sqlerrmessage,"locks") 
			ROLLBACK WORK
			SET LOCK MODE TO NOT WAIT
			RETURN 0
		END IF
		UPDATE prodstatus 
		SET seq_num = l_rec_dst_prodstatus.seq_num, 
			onhand_qty = l_rec_dst_prodstatus.onhand_qty + p_rec_prodledg.tran_qty, 
			wgted_cost_amt = l_rec_dst_prodstatus.wgted_cost_amt, 
			act_cost_amt = l_rec_dst_prodstatus.act_cost_amt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = l_rec_dst_prodstatus.part_code 
			AND ware_code = l_rec_dst_prodstatus.ware_code 
		IF sqlca.sqlcode < 0 THEN
			CALL display_error_and_decide("UPDATE product status",sqlerrmessage,"") 
			SET LOCK MODE TO NOT WAIT
			ROLLBACK WORK
			RETURN 0
		END IF
		LET l_rec_product_new.onhand_qty_new = l_rec_dst_prodstatus.onhand_qty + p_rec_prodledg.tran_qty 
		LET l_rec_product_new.avail_qty_new = l_rec_product_new.onhand_qty_new - l_rec_product_new.reserved_new - l_rec_product_new.onord_new 
	COMMIT WORK 
	IF sqlca.sqlcode < 0 THEN
		CALL display_error_and_decide("COMMIT transaction",sqlerrmessage,"locks") 
		ROLLBACK WORK
		RETURN 0
	END IF
	SET LOCK MODE TO NOT WAIT
	WHENEVER ERROR stop 
	RETURN l_rec_prodledg.source_num 
END FUNCTION   # save_reclass


FUNCTION create_prod(p_new_part, p_master_part,p_new_segment) 
	DEFINE l_rec_product_new t_rec_product_new
	DEFINE p_new_part, p_master_part,p_new_segment LIKE product.part_code
	DEFINE l_rec_product RECORD LIKE product.*
	DEFINE l_rec_product_for_create RECORD LIKE product.*
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.*
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_rec_class RECORD LIKE class.*
	DEFINE l_rec_prodflex RECORD LIKE prodflex.*
	DEFINE l_char_string CHAR(30)
	DEFINE l_remain_segment LIKE product.part_code
	DEFINE l_flex_code LIKE prodflex.flex_code
	DEFINE l_dashes LIKE product.part_code	 
	DEFINE l_skip SMALLINT 
	DEFINE l_x_pos, l_y_pos, i SMALLINT 
	DEFINE l_created SMALLINT
	DEFINE l_seg_len LIKE prodstructure.length 

	SELECT * INTO l_rec_product.* 
	FROM product 
	WHERE part_code = p_master_part 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	LET l_rec_product_for_create.* = l_rec_product.* 

	SELECT * INTO l_rec_class.* 
	FROM class 
	WHERE class_code = l_rec_product.class_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 


	CALL break_prod(glob_rec_kandoouser.cmpy_code,l_rec_product_new.part_code_new,l_rec_product.class_code,1) 
	RETURNING l_rec_product_for_create.part_code,l_dashes,p_new_segment,l_flex_code 

	LET l_x_pos = 1 
	LET l_skip = true 
	LET l_seg_len = length(p_new_segment) 
	LET l_rec_product_for_create.part_code = p_master_part 
	
	DECLARE crs_prodstructure CURSOR FOR 
	SELECT * 
	FROM prodstructure 
	WHERE class_code = l_rec_class.class_code 
	AND seq_num > l_rec_class.price_level_ind 
	--WR0123and seq_num = l_rec_class.ord_level_ind + 1
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	FOREACH crs_prodstructure INTO l_rec_prodstructure.* 
		IF l_rec_prodstructure.type_ind = "F" THEN 
			LET l_rec_product_for_create.part_code = l_rec_product_for_create.part_code clipped, 
			l_rec_prodstructure.desc_text 
			IF l_skip = true THEN 
				LET l_skip = false 
			ELSE 
				LET l_x_pos = l_x_pos + 1 
			END IF 
		ELSE 
			LET l_y_pos = l_x_pos + l_rec_prodstructure.length - 1 
			IF l_seg_len >= l_x_pos THEN 
				LET l_remain_segment = p_new_segment[l_x_pos, l_seg_len] clipped 
			ELSE 
				LET l_remain_segment = "" 
			END IF 
			IF (l_rec_prodstructure.seq_num > l_rec_class.stock_level_ind 
			AND length(l_remain_segment) > 0 ) 
			OR l_rec_prodstructure.seq_num <= l_rec_class.stock_level_ind THEN 
				LET l_char_string = p_new_segment[l_x_pos, l_y_pos] 
				IF validate_string(l_char_string, l_rec_prodstructure.length, 
				l_rec_prodstructure.length, false) THEN ELSE 
					RETURN false, " " 
				END IF 
				IF l_rec_prodstructure.valid_flag = "Y" THEN 
					LET l_flex_code = p_new_segment[l_x_pos, l_y_pos] 
					SELECT * INTO l_rec_prodflex.* 
					FROM prodflex 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND class_code = l_rec_prodstructure.class_code 
					AND start_num = l_rec_prodstructure.start_num 
					AND flex_code = l_flex_code 
					IF sqlca.sqlcode = notfound THEN 
						RETURN FALSE," " 
					END IF 
				END IF 
			END IF 
			LET l_rec_product_for_create.part_code = l_rec_product_for_create.part_code clipped, p_new_segment[l_x_pos, l_y_pos] 
			LET l_x_pos = l_x_pos + l_rec_prodstructure.length 
		END IF 
	END FOREACH 
	LET l_rec_product_for_create.oem_text = l_rec_product_for_create.part_code 
	LET l_rec_product_for_create.short_desc_text = l_rec_product_for_create.part_code 
	LET l_rec_prodstatus.part_code = l_rec_product_for_create.part_code 
	LET l_rec_prodstatus.onhand_qty = 0 
	LET l_rec_prodstatus.reserved_qty = 0 
	LET l_rec_prodstatus.back_qty = 0 
	LET l_rec_prodstatus.forward_qty = 0 
	LET l_rec_prodstatus.onord_qty = 0 
	LET l_rec_prodstatus.seq_num = 0 
	
	# BEGIN WORK useless here, removed ( ericv 2020-09-29)
	--LET err_message = "I21 - Product Create" 
	INSERT INTO product VALUES (l_rec_product_for_create.*) 
	--LET err_message = "I21 - Prodstatus Create" 
	INSERT INTO prodstatus VALUES (l_rec_prodstatus.*) 
	IF sqlca.sqlcode < 0 THEN
		ERROR "UPDATE prodstatus returned an ERROR ",sqlca.sqlcode
		SET LOCK MODE TO NOT WAIT
		ROLLBACK WORK
		RETURN 0
	END IF 

	LET l_created = 1 

	RETURN true, l_rec_product_for_create.part_code 

END FUNCTION 	# create_prod
