--database kandoodb
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

	Source code beautified by beautify.pl on 2020-01-03 09:12:23	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module I21 receives stock (both serial AND non serial)

FUNCTION product_reception_flexcode() 

	DEFINE 
	lr_rec_kandoouser RECORD LIKE kandoouser.*, 
	lr_product RECORD LIKE product.*, 
	ps_product RECORD LIKE product.*,
	lr_prodstatus RECORD LIKE prodstatus.*, 
	pm_prodstatus RECORD LIKE prodstatus.*,
	ps_prodstatus RECORD LIKE prodstatus.*, 
	lr_prodadjtype RECORD LIKE prodadjtype.*,
	pr_prodstructure RECORD LIKE prodstructure.*,
	lr_category RECORD LIKE category.*, 
	lr_serialinfo RECORD LIKE serialinfo.*, 
	lr_class RECORD LIKE class.*,
	lr_prodledg RECORD LIKE prodledg.*, 
	lr_warehouse RECORD LIKE warehouse.*,
	lr_opparms RECORD LIKE opparms.*,
	lr_inparms RECORD LIKE inparms.*
 

	DEFINE
	stck_tran_qty, sell_tran_qty LIKE prodledg.tran_qty, 
	stck_cost_amt, sell_cost_amt LIKE prodledg.cost_amt, 
	avail_qty, availf_qty, avail1_qty LIKE prodstatus.onhand_qty,
	flex_part,orig_part LIKE product.part_code,
	pr_part_code LIKE product.part_code, 
	pr_temp_orig_part LIKE product.part_code, 
	pr_store_part_code LIKE product.part_code, 
	pr_store_ware_code LIKE prodstatus.ware_code
	
	DEFINE
	product_just_created SMALLINT,
	pr_flex,pr_length,pr_start SMALLINT, 
	pr_dashes CHAR(15), 
	dashlength SMALLINT, 
 	seku, puku, stku LIKE product.stock_uom_code, 
	winds_text CHAR(200),
	where_clause STRING, 
	err_continue CHAR(1), 
	err_message CHAR(40), 
	chkqty DECIMAL(15,2), 
 	invalid_per SMALLINT 
	
	DEFINE 
	mask_code CHAR(18), 
	pr_temp_text CHAR(200), 
	pr_lastkey INTEGER, 
	pr_cnt SMALLINT, 
	pr_err_flag CHAR(1), 
	serial_upd_status INTEGER,
	pr_stat_ind, i, pr_part_length, pr_stock_level_len SMALLINT 

	--DECLARE struccur CURSOR FOR  ## ericv 20200603: this cursor is not used!
	--SELECT * FROM prodstructure 
	--WHERE class_code = lr_product.class_code 
	--AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	--ORDER BY seq_num 
	CLEAR FORM 
	LET msgresp = kandoomsg("U","1020","Direct Product Receipt") 
	LET product_just_created = 0 
	LET lr_prodledg.tran_qty = 0 
	LET lr_prodledg.tran_date = today 
	LET flex_part = NULL 
	LET pr_dashes = NULL 
	LET pr_store_part_code = ' **** ' 
	LET pr_store_ware_code = ' # ' 

	DISPLAY BY NAME orig_part,flex_part, 
		lr_prodstatus.ware_code, 
		lr_prodledg.tran_date, 
		lr_prodledg.year_num, 
		lr_prodledg.period_num,
		lr_prodledg.source_code, 
		lr_prodledg.source_text, 
		lr_prodledg.source_num, 
		lr_prodledg.desc_text, 
		lr_prodledg.tran_qty, 
		lr_prodledg.cost_amt 
{
		TO orig_part,flex_part, 
		prodstatus.ware_code, 
		prodledg.tran_date, 
		prodledg.year_num, 
		prodledg.period_num, 
		prodledg.source_text, 
		prodledg.source_num, 
		prodledg.desc_text, 
		prodledg.tran_qty, 
		prodledg.cost_amt 
}
	INPUT BY NAME orig_part, 
		flex_part, 
		lr_prodstatus.ware_code, 
		lr_prodledg.tran_date, 
		lr_prodledg.year_num, 
		lr_prodledg.period_num, 
		lr_prodledg.source_code,
		lr_prodledg.source_text, 
		lr_prodledg.source_num, 
		lr_prodledg.desc_text, 
		lr_prodledg.tran_qty, 
		lr_prodledg.cost_amt 
	WITHOUT DEFAULTS 
{
	FROM orig_part,flex_part, 
		prodstatus.ware_code, 
		prodledg.tran_date, 
		prodledg.year_num, 
		prodledg.period_num, 
		prodledg.source_text, 
		prodledg.source_num, 
		prodledg.desc_text, 
		prodledg.tran_qty, 
		prodledg.cost_amt 
}
		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 
		
		ON ACTION "NOTES" infield(desc_text)   
			LET lr_prodledg.desc_text = sys_noter(glob_rec_kandoouser.cmpy_code,lr_prodledg.desc_text) 
			DISPLAY BY NAME lr_prodledg.desc_text 
			NEXT FIELD prodledg.desc_text  

		ON ACTION "LOOKUP" infield (orig_part)
			LET pr_temp_text = show_part(glob_rec_kandoouser.cmpy_code,"") 
			IF pr_temp_text IS NOT NULL THEN 
				LET lr_prodstatus.part_code = pr_temp_text 
				SELECT * INTO lr_product.* 
				FROM product 
				WHERE part_code = lr_prodstatus.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL break_prod(glob_rec_kandoouser.cmpy_code,lr_prodstatus.part_code,lr_product.class_code,1) 
				RETURNING orig_part,pr_dashes,flex_part,pr_flex 
				DISPLAY BY NAME orig_part,flex_part 
			END IF 
			NEXT FIELD orig_part
			 
		ON ACTION "LOOKUP" infield (flex_part) 
			LET where_clause = "product.part_code matches '", 
			orig_part clipped,"*' " 
			LET winds_text = show_part(glob_rec_kandoouser.cmpy_code,where_clause) 
			IF winds_text IS NOT NULL THEN 
				LET lr_prodstatus.part_code = winds_text clipped 
				SELECT * INTO lr_product.* 
				FROM product 
				WHERE part_code = lr_prodstatus.part_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL break_prod(glob_rec_kandoouser.cmpy_code,lr_prodstatus.part_code,lr_product.class_code,1) 
				RETURNING orig_part,pr_dashes,flex_part,pr_flex 
				DISPLAY BY NAME orig_part,flex_part 

				NEXT FIELD flex_part 
			END IF 
				
		ON ACTION "LOOKUP" infield (ware_code) 
			LET lr_prodstatus.ware_code = show_ware(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME lr_prodstatus.ware_code 
			NEXT FIELD prodstatus.ware_code
			
		ON ACTION "LOOKUP" infield (source_code) 
			LET winds_text = show_adj_type_code(glob_rec_kandoouser.cmpy_code) 
			IF winds_text IS NOT NULL THEN 
				LET lr_prodledg.source_code = winds_text clipped 
				LET lr_prodledg.source_type = "PADJ" #the source is a product adjustement
				SELECT * INTO lr_prodadjtype.* 
				FROM prodadjtype 
				WHERE source_code = lr_prodledg.source_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET lr_prodledg.desc_text = lr_prodadjtype.desc_text 
				LET lr_prodledg.acct_code = lr_prodadjtype.adj_acct_code 
				DISPLAY BY NAME lr_prodledg.source_code 

			END IF 
			DISPLAY lr_prodledg.desc_text TO prodledg.desc_text 

		AFTER FIELD orig_part 
			IF flex_part IS NULL 
			OR orig_part != pr_temp_orig_part THEN 
				LET lr_prodstatus.part_code = orig_part clipped 
				LET pr_temp_orig_part = orig_part 
				LET flex_part = NULL 
			END IF 
			SELECT product.* INTO lr_product.* 
			FROM product 
			WHERE part_code = lr_prodstatus.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9010,"") 
				#9010 Product NOT found - Try Window
				NEXT FIELD orig_part 
			END IF 
			DISPLAY BY NAME lr_product.desc_text,lr_product.desc2_text 

			SELECT * INTO lr_class.* 
			FROM class 
			WHERE class_code = lr_product.class_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF flex_part IS NULL 
			OR orig_part != pr_temp_orig_part THEN 
				LET lr_prodstatus.part_code = orig_part clipped 
				LET pr_temp_orig_part = orig_part 
				LET flex_part = NULL 
			END IF 
			CALL break_prod(glob_rec_kandoouser.cmpy_code,lr_prodstatus.part_code,lr_product.class_code,1) 
			RETURNING orig_part,pr_dashes,flex_part,pr_flex 
			DISPLAY BY NAME orig_part,flex_part 

			IF lr_product.status_ind = "2" THEN 
				#8022 Product IS put on hold - Continue (Y/N)?
				IF kandoomsg("I",8022,"") = "N" THEN 
					NEXT FIELD orig_part 
				END IF 
			END IF 
			IF lr_product.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9511,"") 
				#9511 This product has been deleted
				NEXT FIELD orig_part 
			END IF 
			SELECT category.* INTO lr_category.* 
			FROM category 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cat_code = lr_product.cat_code 
			IF lr_product.serial_flag = "Y" THEN 
				IF pr_store_part_code <> lr_product.part_code THEN 
					LET pr_store_part_code = lr_product.part_code 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, "", "", "") 
				END IF 
			END IF 

		BEFORE FIELD flex_part 
			IF NOT mult_segs(glob_rec_kandoouser.cmpy_code, lr_product.class_code) THEN 
				INITIALIZE flex_part TO NULL 
				IF fgl_lastkey() = fgl_keyval("up") OR 
				fgl_lastkey() = fgl_keyval("left") THEN 
					NEXT FIELD orig_part 
				ELSE 
					NEXT FIELD prodstatus.ware_code 
				END IF 
			END IF 

		AFTER FIELD flex_part 
			IF flex_part IS NOT NULL THEN 
				IF length(flex_part) > pr_flex THEN 
					LET msgresp = kandoomsg("I",9208,pr_flex) 
					#9208 Invalid Segment Length, should be ?? Characters
					NEXT FIELD flex_part 
				END IF 
				LET lr_prodstatus.part_code = orig_part clipped,pr_dashes clipped, 
				flex_part clipped 
			ELSE 
				LET lr_prodstatus.part_code = orig_part clipped, 
				flex_part clipped 
			END IF 
			
			# very heavy 500 bytes everytime, for what ?
			SELECT product.* INTO lr_product.* 
			FROM product 
			WHERE part_code = lr_prodstatus.part_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				# This part code does not exist for this company
				LET msgresp = kandoomsg("I",7047,"") 
				#7047 Product NOT found - Create (Y/N)
				IF msgresp = "Y" THEN 
					# duplicate the product with flex code
					CALL create_new_product(orig_part,flex_part) 
					RETURNING pr_stat_ind, lr_product.part_code 
					IF pr_stat_ind THEN ELSE 
						LET msgresp = kandoomsg("I",9535,"") 
						#9535 Invalid product Flexible Segment value
						NEXT FIELD flex_part 
					END IF 
					SELECT product.* INTO lr_product.* 
					FROM product 
					WHERE part_code = lr_product.part_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlcode = notfound THEN 
						LET msgresp = kandoomsg("I",9535,"") 
						#9535 Invalid product Flexible Segment value
						NEXT FIELD flex_part 
					END IF 
					LET product_just_created = 1 
				ELSE 
					LET product_just_created = 0 
					LET flex_part = NULL 
					NEXT FIELD orig_part 
				END IF 
			ELSE 
				LET product_just_created = 0 
			END IF 
			IF lr_product.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9511,"") 
				#9511 This product has been deleted
				NEXT FIELD orig_part 
			END IF 
			# check that enough segments have been entered.
			IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, lr_prodstatus.part_code, 1) THEN 
				LET msgresp = kandoomsg("I",9536,"") 
				#9536 Must enter up TO Stock receipting segment
				NEXT FIELD orig_part 
			END IF 
			
			# check that child IS really a child of this parent
			IF lr_product.class_code <> lr_class.class_code THEN 
				LET msgresp = kandoomsg("I",9538,"") 
				# I 9538  Child IS NOT the same class as the Parent segment.
				NEXT FIELD orig_part 
			END IF 
			
			LET pr_part_code = lr_prodstatus.part_code 
			IF lr_product.serial_flag = "Y" THEN 
				IF pr_store_part_code <> lr_product.part_code THEN 
					LET pr_store_part_code = lr_product.part_code 
					CALL serial_init(glob_rec_kandoouser.cmpy_code, "", "", "") 
				END IF 
			END IF 

		AFTER FIELD ware_code 
			SELECT warehouse.desc_text INTO lr_warehouse.desc_text 
			FROM warehouse 
			WHERE warehouse.ware_code = lr_prodstatus.ware_code 
				AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9030,"") 
				#9030 Warehouse NOT found - Try Window
				NEXT FIELD prodstatus.ware_code 
			END IF 
			
			# Check the product status for this part code in this warehouse
			SELECT * INTO ps_prodstatus.* 
			FROM prodstatus 
			WHERE part_code = orig_part 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = lr_prodstatus.ware_code 
			
			IF sqlca.sqlcode = notfound THEN 
				LET msgresp = kandoomsg("I",9104,"") 
				#9104 Product does NOT exist AT this warehouse
				LET lr_prodstatus.ware_code = NULL 
				DISPLAY BY NAME lr_prodstatus.ware_code
				MESSAGE "Please input an origin part code" 
				NEXT FIELD orig_part 
			END IF 
			
			LET pm_prodstatus.* = ps_prodstatus.* 
			LET pm_prodstatus.part_code = pr_part_code 
			LET pm_prodstatus.ware_code = lr_prodstatus.ware_code 
			IF product_just_created = 0 THEN 
				SELECT prodstatus.* INTO lr_prodstatus.* 
				FROM prodstatus 
				WHERE prodstatus.part_code = lr_prodstatus.part_code 
					AND prodstatus.ware_code = lr_prodstatus.ware_code 
					AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET product_just_created = 1 
					LET lr_prodstatus.onhand_qty = 0 
					LET lr_prodstatus.reserved_qty = 0 
					LET lr_prodstatus.back_qty = 0 
					LET lr_prodstatus.transit_qty = 0 
					LET lr_prodstatus.onord_qty = 0 
					LET lr_prodstatus.forward_qty = 0 
					LET lr_prodstatus.seq_num = 0 
					LET pm_prodstatus.onhand_qty = 0 
					LET pm_prodstatus.reserved_qty = 0 
					LET pm_prodstatus.back_qty = 0 
					LET pm_prodstatus.onord_qty = 0 
					LET pm_prodstatus.forward_qty = 0 
					LET pm_prodstatus.seq_num = 0 
					LET lr_prodstatus.wgted_cost_amt = pm_prodstatus.wgted_cost_amt 
					LET lr_prodstatus.for_cost_amt = pm_prodstatus.for_cost_amt 
					LET lr_prodstatus.est_cost_amt = pm_prodstatus.est_cost_amt 
					LET lr_prodstatus.act_cost_amt = pm_prodstatus.act_cost_amt 
				END IF 
			ELSE 
				# Get the origin part code
				SELECT prodstatus.* INTO lr_prodstatus.* 
				FROM prodstatus 
				WHERE prodstatus.part_code = orig_part 
					AND prodstatus.ware_code = lr_prodstatus.ware_code 
					AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = notfound THEN 
					LET product_just_created = 1 
				END IF 
				LET lr_prodstatus.onhand_qty = 0 
				LET lr_prodstatus.reserved_qty = 0 
				LET lr_prodstatus.back_qty = 0 
				LET lr_prodstatus.transit_qty = 0 
				LET lr_prodstatus.onord_qty = 0 
				LET lr_prodstatus.forward_qty = 0 
				LET lr_prodstatus.seq_num = 0 
				LET pm_prodstatus.onhand_qty = 0 
				LET pm_prodstatus.reserved_qty = 0 
				LET pm_prodstatus.back_qty = 0 
				LET pm_prodstatus.onord_qty = 0 
				LET pm_prodstatus.forward_qty = 0 
				LET pm_prodstatus.seq_num = 0 
				LET lr_prodstatus.wgted_cost_amt = pm_prodstatus.wgted_cost_amt 
				LET lr_prodstatus.for_cost_amt = pm_prodstatus.for_cost_amt 
				LET lr_prodstatus.est_cost_amt = pm_prodstatus.est_cost_amt 
				LET lr_prodstatus.act_cost_amt = pm_prodstatus.act_cost_amt 
			END IF 
			IF lr_prodstatus.status_ind = "2" THEN 
				#8022 Product IS in this warhouse put on hold - Continue (Y/N)?
				IF kandoomsg("I",8024,"") = "N" THEN 
					NEXT FIELD orig_part 
				END IF 
			END IF 
			IF lr_prodstatus.status_ind = "3" THEN 
				LET msgresp = kandoomsg("I",9510,"") 
				#9510 This product has been deleted AT this warehouse
				NEXT FIELD orig_part 
			END IF 
			IF lr_product.serial_flag = "Y" THEN 
				IF pr_store_ware_code <> lr_prodstatus.ware_code THEN 
					LET pr_store_ware_code = lr_prodstatus.ware_code 
					CALL serial_init(glob_rec_kandoouser.cmpy_code,"", "", "") 
				END IF 
			END IF 
			LET lr_prodledg.source_text = NULL 
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "2" THEN 
				LET lr_prodledg.source_text = 'RECEIPT' 
			END IF 
			LET lr_prodledg.tran_date = today 
			
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
			RETURNING lr_prodledg.year_num, 
			lr_prodledg.period_num 
			DISPLAY BY NAME lr_prodledg.period_num, 
			lr_prodledg.year_num, 
			lr_prodledg.tran_date 

			IF lr_opparms.cal_available_flag = "N" THEN 
				LET avail_qty = lr_prodstatus.onhand_qty - 
				lr_prodstatus.reserved_qty - 
				lr_prodstatus.back_qty 
			ELSE 
				LET avail_qty = lr_prodstatus.onhand_qty 
				- lr_prodstatus.reserved_qty 
			END IF 
			LET availf_qty = avail_qty + lr_prodstatus.onord_qty 
			- lr_prodstatus.forward_qty 
			LET puku = lr_product.pur_uom_code 
			LET stku = lr_product.stock_uom_code 
			LET seku = lr_product.sell_uom_code 
			CASE lr_category.def_cost_ind 
				WHEN "W" 
					LET sell_cost_amt = lr_prodstatus.wgted_cost_amt 
				WHEN "F" 
					LET sell_cost_amt = lr_prodstatus.for_cost_amt 
				WHEN "S" 
					LET sell_cost_amt = lr_prodstatus.est_cost_amt 
				WHEN "L" 
					LET sell_cost_amt = lr_prodstatus.act_cost_amt 
				OTHERWISE 
					LET sell_cost_amt = lr_prodstatus.wgted_cost_amt 
			END CASE 
			LET stck_cost_amt = sell_cost_amt * lr_product.stk_sel_con_qty 
			LET lr_prodledg.cost_amt = sell_cost_amt * 	(lr_product.stk_sel_con_qty * lr_product.pur_stk_con_qty) 
			DISPLAY lr_product.desc_text, 
				lr_product.desc2_text, 
				lr_prodstatus.ware_code, 
				lr_warehouse.desc_text, 
				avail_qty, 
				avail_qty, 
				availf_qty, 
				lr_product.stock_uom_code, 
				lr_product.sell_uom_code, 
				lr_product.pur_uom_code, 
				puku, 
				stku, 
				seku, 
				lr_prodstatus.onhand_qty, 
				lr_prodstatus.back_qty, 
				lr_prodstatus.forward_qty, 
				lr_prodstatus.onord_qty, 
				lr_prodstatus.reserved_qty, 
				lr_prodledg.desc_text, 
				lr_prodledg.tran_date, 
				lr_prodledg.tran_qty, 
				lr_prodledg.cost_amt, 
				lr_prodledg.year_num, 
				lr_prodledg.period_num, 
				lr_prodledg.source_code,
				lr_prodledg.source_text, 
				lr_prodledg.source_num, 
				stck_cost_amt, 
				sell_cost_amt 
			TO product.desc_text, 
				product.desc2_text, 
				prodstatus.ware_code, 
				warehouse.desc_text, 
				avail1_qty, 
				avail_qty, 
				availf_qty, 
				product.stock_uom_code, 
				product.sell_uom_code, 
				product.pur_uom_code, 
				puku, 
				stku, 
				seku, 
				prodstatus.onhand_qty, 
				prodstatus.back_qty, 
				for_ord_qty, 
				prodstatus.onord_qty, 
				prodstatus.reserved_qty, 
				prodledg.desc_text, 
				prodledg.tran_date, 
				prodledg.tran_qty, 
				prodledg.cost_amt, 
				prodledg.year_num, 
				prodledg.period_num, 
				prodledg.source_code,
				prodledg.source_text, 
				prodledg.source_num, 
				formonly.stck_cost_amt, 
				formonly.sell_cost_amt 

		AFTER FIELD tran_date 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, lr_prodledg.tran_date) 
			RETURNING lr_prodledg.year_num, 
				lr_prodledg.period_num 
			DISPLAY BY NAME lr_prodledg.period_num, 
				lr_prodledg.year_num, 
				lr_prodledg.tran_date 

		AFTER FIELD period_num 
			LET invalid_per = 0 
			CALL valid_period(glob_rec_kandoouser.cmpy_code, lr_prodledg.year_num,lr_prodledg.period_num, TRAN_TYPE_INVOICE_IN) 
			RETURNING lr_prodledg.year_num, 
				lr_prodledg.period_num, 
				invalid_per 
			IF invalid_per THEN 
				NEXT FIELD prodledg.year_num 
			END IF 

		BEFORE FIELD tran_qty 
			IF lr_product.serial_flag = "Y" THEN 
				LET pr_lastkey = fgl_lastkey() 
				LET pr_cnt = serial_input(lr_product.part_code, 
				lr_prodstatus.ware_code,pr_cnt) 
				IF pr_cnt < 0 THEN 
					EXIT program 
				ELSE 
					LET lr_prodledg.tran_qty = pr_cnt 
					LET stck_tran_qty = lr_prodledg.tran_qty * 
					lr_product.pur_stk_con_qty 
					LET sell_tran_qty = lr_prodledg.tran_qty * 
					lr_product.stk_sel_con_qty * 
					lr_product.pur_stk_con_qty 
					DISPLAY BY NAME lr_prodledg.tran_qty, 
						stck_tran_qty, 
						sell_tran_qty 

					IF pr_lastkey = fgl_keyval("up") 
					OR pr_lastkey = fgl_keyval("left") THEN 
						NEXT FIELD desc_text 
					ELSE 
						NEXT FIELD cost_amt 
					END IF 
				END IF 
			END IF 

		AFTER FIELD tran_qty 
			#IF lr_prodledg.tran_qty <= 0
			IF lr_prodledg.tran_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9192,"") 
				NEXT FIELD prodledg.tran_qty 
			ELSE 
				LET stck_tran_qty = lr_prodledg.tran_qty * lr_product.pur_stk_con_qty 
				LET sell_tran_qty = lr_prodledg.tran_qty * lr_product.stk_sel_con_qty * lr_product.pur_stk_con_qty 
				DISPLAY stck_tran_qty,sell_tran_qty 
				TO formonly.stck_tran_qty,formonly.sell_tran_qty 
			END IF 

		AFTER FIELD cost_amt 
			IF lr_prodledg.cost_amt < 0 OR lr_prodledg.cost_amt IS NULL THEN 
				LET msgresp = kandoomsg("I",9107,"") 
				NEXT FIELD prodledg.tran_qty 
			ELSE 
				IF lr_product.pur_stk_con_qty = 0 THEN 
					LET stck_cost_amt = 0 
				ELSE 
					LET stck_cost_amt = lr_prodledg.cost_amt/ 
					lr_product.pur_stk_con_qty 
				END IF 
				IF lr_product.pur_stk_con_qty = 0 
				OR lr_product.stk_sel_con_qty = 0 THEN 
					LET sell_cost_amt = 0 
				ELSE 
					LET sell_cost_amt = lr_prodledg.cost_amt/ 
					(lr_product.pur_stk_con_qty 
					* lr_product.stk_sel_con_qty) 
				END IF 
				DISPLAY stck_cost_amt, 
				sell_cost_amt 
				TO formonly.stck_cost_amt, 
				formonly.sell_cost_amt 

			END IF 

		AFTER FIELD source_code 
			# source_text has miscellaneous meanings according to the program it is used in ...
			IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
				# if this parameter is set, source_text is a product adjustement code
				IF lr_prodledg.source_code IS NULL THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD prodledg.source_code 
				END IF 
				SELECT * INTO lr_prodadjtype.* 
				FROM prodadjtype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = lr_prodledg.source_code 
				IF sqlca.sqlcode = notfound THEN 
					LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					NEXT FIELD prodledg.source_code 
				END IF 
				LET lr_prodledg.source_type = "PADJ"			#the source is a product adjustement
				LET lr_prodledg.desc_text = lr_prodadjtype.desc_text 
				LET lr_prodledg.acct_code = lr_prodadjtype.adj_acct_code 
				DISPLAY lr_prodledg.desc_text TO prodledg.desc_text 

			ELSE 
				SELECT * INTO lr_prodadjtype.* 
				FROM prodadjtype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND adj_type_code = lr_prodledg.source_code 
				IF status = 0 THEN 
					LET lr_prodledg.acct_code = lr_prodadjtype.adj_acct_code 
				ELSE 
					LET lr_prodledg.acct_code = lr_category.adj_acct_code 
				END IF 
			END IF 
			
			# check if this product belongs to a category and warehouse that has a budget created
			# mandatory to insert into prodledger 
			SELECT 1 
			FROM account
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = lr_prodledg.acct_code
				AND year_num = lr_prodledg.year_num	
				
			IF sqlca.sqlcode = notfound THEN
				ERROR "No budget created for that category and that year, please check with your accountant"
				NEXT FIELD part_code  
			END IF
			
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF mult_segs(glob_rec_kandoouser.cmpy_code, lr_product.class_code) THEN 
				--IF flex_part IS NOT NULL THEN 
					--LET lr_prodstatus.part_code = orig_part clipped,pr_dashes clipped, 
					--flex_part clipped 
				--ELSE 
					--LET lr_prodstatus.part_code = orig_part clipped, 
					--flex_part clipped 
				--END IF 
				
				--SELECT product.* INTO lr_product.* 
				--FROM product 
				--WHERE part_code = lr_prodstatus.part_code 
					--AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				--IF sqlca.sqlcode = notfound THEN 
					--LET msgresp = kandoomsg("I",7047,"") 
					#7047 Product NOT found - Create (Y/N)
					--IF msgresp = "Y" THEN 
						--CALL create_new_product(orig_part,flex_part) 
						--RETURNING pr_stat_ind, lr_product.part_code 
						--IF pr_stat_ind THEN ELSE 
							--LET msgresp = kandoomsg("I",9535,"") 
							#9535 Invalid product Flexible Segment value
							--NEXT FIELD flex_part 
						--END IF 
						--SELECT product.* INTO lr_product.* 
						--FROM product 
						--WHERE part_code = lr_product.part_code 
							--AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						--IF sqlca.sqlcode = notfound THEN 
							--LET msgresp = kandoomsg("I",9535,"") 
							#9535 Invalid product Flexible Segment value
							--NEXT FIELD flex_part 
						--END IF 
						--LET product_just_created = 1 
					--ELSE 
						--LET product_just_created = 0 
						--LET flex_part = NULL 
						--NEXT FIELD orig_part 
					--END IF 
				--END IF 
				--IF lr_product.status_ind = "3" THEN 
					--LET msgresp = kandoomsg("I",9511,"") 
					#9511 This product has been deleted
					--NEXT FIELD orig_part 
				--END IF 
				--LET pr_part_code = lr_prodstatus.part_code 
				# check that enough segments have been entered.
				--IF NOT validate_receipt_segment(glob_rec_kandoouser.cmpy_code, lr_prodstatus.part_code, 1) THEN 
					--LET msgresp = kandoomsg("I",9536,"") 
					#9536 Must enter up TO Stock receipting segment
					--NEXT FIELD orig_part 
				--END IF 
			END IF 

			--SELECT warehouse.desc_text INTO lr_warehouse.desc_text 
			--FROM warehouse 
			--WHERE warehouse.ware_code = lr_prodstatus.ware_code 
				--AND warehouse.cmpy_code = glob_rec_kandoouser.cmpy_code 
			--IF sqlca.sqlcode = notfound THEN 
				--LET msgresp = kandoomsg("I",9030,"") 
				#9030 Warehouse NOT found - Try Window
				--NEXT FIELD prodstatus.ware_code 
			--END IF 
			--CALL valid_period(glob_rec_kandoouser.cmpy_code, lr_prodledg.year_num,lr_prodledg.period_num, TRAN_TYPE_INVOICE_IN) 
			--RETURNING lr_prodledg.year_num, 
				--lr_prodledg.period_num, 
				--invalid_per 
			--IF invalid_per THEN 
				--NEXT FIELD prodledg.year_num 
			--END IF 
			--IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"PA") = "1" THEN 
				# source_text is in that case the GL account used for product adjustments
				--IF lr_prodledg.source_text IS NULL THEN 
					--LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					--NEXT FIELD prodledg.source_text 
				--END IF 
				--SELECT * INTO lr_prodadjtype.* 
				--FROM prodadjtype 
				--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					--AND source_code = lr_prodledg.source_text 
				--IF sqlca.sqlcode = notfound THEN 
					--LET msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found - Try Window
					--NEXT FIELD prodledg.source_text 
				--END IF 
				--LET lr_prodledg.desc_text = lr_prodadjtype.desc_text 
				--LET lr_prodledg.acct_code = lr_prodadjtype.adj_acct_code 
				--DISPLAY lr_prodledg.desc_text TO prodledg.desc_text 
			--ELSE 
				--SELECT * INTO lr_prodadjtype.* 
				--FROM prodadjtype 
				--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					--AND source_code = lr_prodledg.source_text 
				--IF status = 0 THEN 
					--LET lr_prodledg.acct_code = lr_prodadjtype.adj_acct_code 
				--ELSE 
					--LET lr_prodledg.acct_code = lr_category.adj_acct_code 
				--END IF 
			--END IF 
			IF lr_prodledg.tran_qty IS NULL THEN 
				LET msgresp = kandoomsg("I",9192,"") 
				NEXT FIELD prodledg.tran_qty 
			END IF 
			IF lr_prodledg.cost_amt < 0 THEN 
				LET msgresp = kandoomsg("I",9107,"") 
				NEXT FIELD prodledg.tran_qty 
			END IF 
			IF lr_prodledg.cost_amt IS NULL OR lr_prodledg.cost_amt = 0 THEN 
				--            OPEN WINDOW w1_I21 AT 14,12 with 2 rows,60 columns  -- albo  KD-758
				--               ATTRIBUTE(border)
				MENU " Warning : Product Costs are Zero" 

					BEFORE MENU 
						CALL publish_toolbar("kandoo","I21","menu-Warning-1") -- albo kd-505 

					ON ACTION "WEB-HELP" -- albo kd-372 
						CALL onlinehelp(getmoduleid(),null) 

					COMMAND "Continue" " Continue with Zero Cost Amounts" 
						EXIT MENU 
					COMMAND KEY(interrupt,"E")"Re enter" 
						" Re Enter Product Cost Amounts" 
						LET quit_flag = true 
						EXIT MENU 
					COMMAND KEY (control-w) 
						CALL kandoohelp("") 
				END MENU 
				--            CLOSE WINDOW w1_I21  -- albo  KD-758
			END IF 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				NEXT FIELD prodledg.cost_amt 
			END IF 
			#
			# hold prodledg in selling units
			#
			LET lr_prodledg.tran_qty = sell_tran_qty 
			LET lr_prodledg.cost_amt = sell_cost_amt 
 
			BEGIN WORK 
			SET LOCK MODE TO WAIT 2
			LET err_message = "I21 - Prodstatus UPDATE" 
			IF product_just_created = 0 THEN 
				-- DECLARE psf_curs CURSOR FOR
				SET ISOLATION TO REPEATABLE READ	# put a shared lock on reading prodstatus  
				SELECT prodstatus.* INTO lr_prodstatus.* 
				FROM prodstatus 
				WHERE prodstatus.part_code = lr_prodstatus.part_code 
				AND prodstatus.ware_code = lr_prodstatus.ware_code 
				AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code 
				 
				LET lr_prodstatus.seq_num = lr_prodstatus.seq_num + 1 
				IF lr_prodstatus.stocked_flag = "Y" THEN 
					LET lr_prodstatus.onhand_qty = lr_prodstatus.onhand_qty 
					+ lr_prodledg.tran_qty 
				ELSE 
					LET lr_prodstatus.onhand_qty = 0 
				END IF 
				LET lr_prodstatus.last_receipt_date = lr_prodledg.tran_date 
				LET chkqty = 0 
				#
				# Calculate the quantity on hand
				#
				# there is only one record with that key, select sum makes NO SENSE!
				--SELECT sum(onhand_qty) INTO chkqty 
				--FROM prodstatus 
				--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				--AND part_code = lr_product.part_code 
				--AND ware_code = lr_prodstatus.ware_code
				LET chkqty = lr_prodstatus.onhand_qty
				 
				IF lr_prodledg.cost_amt IS NULL THEN 
					LET lr_prodledg.cost_amt = 0 
				END IF 
				IF lr_prodstatus.wgted_cost_amt IS NULL THEN 
					LET lr_prodstatus.wgted_cost_amt = 0 
				END IF 
				IF lr_prodstatus.act_cost_amt IS NULL THEN 
					LET lr_prodstatus.act_cost_amt = 0 
				END IF 
				IF (lr_prodledg.tran_qty + chkqty) > 0 THEN 
					IF chkqty <= 0 THEN 
						LET lr_prodstatus.wgted_cost_amt = lr_prodledg.cost_amt 
					ELSE 
						LET lr_prodstatus.wgted_cost_amt = 
						((lr_prodstatus.wgted_cost_amt * chkqty) + 
						(lr_prodledg.tran_qty * lr_prodledg.cost_amt)) 
						/ (lr_prodledg.tran_qty + chkqty) 
					END IF 
				END IF 
				#
				# put actual TO latest cost amount
				#
				LET lr_prodstatus.act_cost_amt = lr_prodledg.cost_amt
				 
				WHENEVER SQLERROR CONTINUE
				UPDATE prodstatus 
				SET * = lr_prodstatus.*
				WHERE prodstatus.part_code = lr_prodstatus.part_code 
					AND prodstatus.ware_code = lr_prodstatus.ware_code 
					AND prodstatus.cmpy_code = glob_rec_kandoouser.cmpy_code
				
				IF sqlca.sqlcode <  0 THEN
					ERROR "This transaction could not complete, problem on prodstatus"
					ROLLBACK WORK
					RETURN false
 				END IF
 				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler  
			ELSE 
				# prodstatus does not exist in that warehouse
				LET err_message = "I21 - Prodstatus INSERT" 
				LET lr_prodstatus.* = pm_prodstatus.* 
				LET lr_prodstatus.seq_num = lr_prodstatus.seq_num + 1 
				IF lr_prodstatus.stocked_flag = "Y" THEN 
					LET lr_prodstatus.onhand_qty = lr_prodstatus.onhand_qty	+ lr_prodledg.tran_qty 
				ELSE 
					LET lr_prodstatus.onhand_qty = 0 
				END IF 
				LET lr_prodstatus.last_receipt_date = lr_prodledg.tran_date 
				#
				# Calculate the quantity on hand
				#
				LET chkqty = 0 
				IF lr_prodledg.cost_amt IS NULL THEN 
					LET lr_prodledg.cost_amt = 0 
				END IF 
				IF lr_prodstatus.wgted_cost_amt IS NULL THEN 
					LET lr_prodstatus.wgted_cost_amt = 0 
				END IF 
				IF lr_prodstatus.act_cost_amt IS NULL THEN 
					LET lr_prodstatus.act_cost_amt = 0 
				END IF 
				LET lr_prodstatus.wgted_cost_amt = lr_prodledg.cost_amt 
				#
				# put actual TO latest cost amount
				#
				LET lr_prodstatus.act_cost_amt = lr_prodledg.cost_amt 
				LET lr_prodstatus.last_sale_date = NULL 
				LET lr_prodstatus.last_stcktake_date = NULL 
				LET lr_prodstatus.status_date = today 

				INSERT INTO prodstatus VALUES (lr_prodstatus.*)
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
				IF sqlca.sqlcode <  0 THEN
					ERROR "This transaction could not complete, problem on creating prodstatus"
					ROLLBACK WORK
					RETURN false
				END IF
				WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
			END IF 
				
			SELECT acct_mask_code INTO mask_code 
			FROM warehouse 
			WHERE ware_code = lr_prodstatus.ware_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			CALL build_mask(glob_rec_kandoouser.cmpy_code,mask_code,lr_prodledg.acct_code) 
			RETURNING lr_prodledg.acct_code 
			LET lr_prodledg.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET lr_prodledg.part_code = lr_prodstatus.part_code 
			LET lr_prodledg.ware_code = lr_prodstatus.ware_code 
			LET lr_prodledg.seq_num = lr_prodstatus.seq_num 
			LET lr_prodledg.trantype_ind = "R" 
			LET lr_prodledg.sales_amt = 0 
			LET lr_prodledg.post_flag = "N" 
			IF lr_inparms.hist_flag = "Y" THEN 
				LET lr_prodledg.hist_flag = "N" 
			ELSE 
				LET lr_prodledg.hist_flag = "Y" 
			END IF 
			LET lr_prodledg.jour_num = 0 
			LET lr_prodledg.bal_amt = lr_prodstatus.onhand_qty 
			LET lr_prodledg.entry_code = glob_rec_kandoouser.sign_on_code 
			LET lr_prodledg.entry_date = today 
			LET err_message = "I21 - Itemledg INSERT" 
			
			# insert record into product ledger
			WHENEVER SQLERROR CONTINUE
			INSERT INTO prodledg VALUES (lr_prodledg.*) 
			IF sqlca.sqlcode <  0 THEN
				ERROR "This transaction could not complete, problem on prodleg"
				ROLLBACK WORK
				RETURN false
			END IF
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			#
			# now IF we have serial items THEN get the serial info
			#
			LET pr_err_flag = 'N' 
			IF lr_product.serial_flag = "Y" THEN 
				LET err_message = "I21 - serial_update " 
				LET lr_serialinfo.cmpy_code = lr_prodledg.cmpy_code 
				LET lr_serialinfo.part_code = lr_prodledg.part_code 
				LET lr_serialinfo.ware_code = lr_prodledg.ware_code 
				LET lr_serialinfo.receipt_date = lr_prodledg.tran_date 
				LET lr_serialinfo.receipt_num = lr_prodledg.seq_num 
				LET lr_serialinfo.vend_code = NULL 
				LET lr_serialinfo.trantype_ind = "0" 
				LET serial_upd_status = serial_update(lr_serialinfo.*,pr_cnt, "") 
				IF serial_upd_status < 0 THEN 
					LET pr_err_flag = 'Y' 
				END IF 
			END IF 
			IF pr_err_flag = 'Y' THEN 
				ROLLBACK WORK 
				ERROR "This transaction could not complete, problem on serial number"
			ELSE 
				MESSAGE "The reception of this product has concluded successfully"
				COMMIT WORK 
			END IF 
			WHENEVER ERROR stop 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag 
	OR pr_err_flag = 'Y' THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
