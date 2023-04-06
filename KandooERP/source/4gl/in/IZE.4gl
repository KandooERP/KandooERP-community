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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "I_IN_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_glparms RECORD LIKE glparms.* 
DEFINE modu_prod_list CHAR(1) 
DEFINE modu_continue CHAR(1) 

####################################################################
# MAIN
# Product Surcharge Maintainence Program
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZE") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	LET modu_prod_list = "1" 
	SELECT * INTO modu_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	OPEN WINDOW i639 with FORM "I639" 
	 CALL windecoration_i("I639") -- albo kd-758 

	WHILE input_product_list() 
		WHILE build_products_list() 
			CALL scan_products_list() 
		END WHILE 
	END WHILE 
	CLOSE WINDOW i639 

END MAIN 


FUNCTION input_product_list() 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	#LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	INPUT modu_prod_list 
	WITHOUT DEFAULTS
	FROM pr_prod_list

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZE","input-modu_prod_list-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	RETURN TRUE 

END FUNCTION 	# input_product_list


FUNCTION build_products_list() 
	DEFINE query_text STRING 
	DEFINE where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	DISPLAY modu_prod_list
	TO pr_prod_list 

	CONSTRUCT BY NAME where_text ON 
	product.part_code, 
	product.desc_text, 
	product.prodgrp_code, 
	product.maingrp_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZE","construct-part_code-1") -- albo kd-505 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	END IF 

	IF modu_prod_list = "2" THEN 
		#LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM product ", 
		"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",where_text CLIPPED," ", 
		"ORDER BY product.part_code" 
	ELSE 
		LET query_text = "SELECT product.* FROM product, prodsurcharge ", 
		"WHERE prodsurcharge.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND product.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND prodsurcharge.part_code = product.part_code ", 
		"AND ",where_text CLIPPED," ",
		"ORDER BY product.part_code"
	END IF 

	PREPARE s_product FROM query_text 
	DECLARE crs_product_scan CURSOR FOR s_product 

	RETURN TRUE 

END FUNCTION 		# build_products_list


FUNCTION scan_products_list() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		prodgrp_code LIKE product.prodgrp_code, 
		maingrp_code LIKE product.maingrp_code 
	END RECORD 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_mode CHAR(4) 
	DEFINE l_found,l_deletable SMALLINT 
	DEFINE l_arr_count,l_arr_curr,l_scr_line SMALLINT
	DEFINE l_cnt SMALLINT
	DEFINE l_msg_err STRING
	DEFINE l_idx SMALLINT

	LET l_idx = 0 
	FOREACH crs_product_scan INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].prodgrp_code = l_rec_product.prodgrp_code 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[l_idx].maingrp_code = l_rec_product.maingrp_code 
	END FOREACH 
	
	IF l_idx = 0 THEN
		ERROR "No product matching criteria"
		RETURN
	END IF
	
	CALL set_count(l_idx) 

	#LET l_msgresp = kandoomsg("U",1003,"") 
	INPUT ARRAY l_arr_rec_product WITHOUT DEFAULTS 
	FROM sr_product.* 
	ATTRIBUTE(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE, AUTO APPEND = FALSE, DELETE ROW = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZE","input-arr-l_arr_rec_product-1") -- albo kd-505 
			CALL fgl_dialog_setactionlabel("INSERT","Add\nSurcharges","{CONTEXT}/public/querix/icon/svg/24/ic_add_box_24px.svg",4,FALSE,"Add Surcharges to Product")
			CALL fgl_dialog_setactionlabel("EDIT","Edit\nSurcharges","{CONTEXT}/public/querix/icon/svg/24/ic_edit_24px.svg",5,FALSE,"Edit Surcharges of Product")
			CALL fgl_dialog_setactionlabel("DELETE","Delete\nSurcharges","{CONTEXT}/public/querix/icon/svg/24/ic_delete_24px.svg",6,FALSE,"Delete all Surcharges from Product")

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION ("INSERT") -- albo kd-1075 
			LET l_mode = "ADD" 
			LET l_arr_count = arr_count()
			LET l_arr_curr = arr_curr()
			LET l_part_code = edit_surcharge("",l_mode) 

		ON ACTION ("EDIT") 
			LET l_mode = "EDIT"
			LET l_arr_curr = arr_curr()
			IF l_arr_rec_product[l_arr_curr].part_code IS NOT NULL THEN 
				LET l_part_code = edit_surcharge(l_arr_rec_product[l_arr_curr].part_code,l_mode) 
			END IF 
			
		ON ACTION "DELETE" 
			LET l_arr_curr = arr_curr()
			SELECT COUNT(*) INTO l_deletable 
			FROM prodsurcharge 
			WHERE prodsurcharge.part_code = l_arr_rec_product[l_arr_curr].part_code 
			AND prodsurcharge.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF l_deletable = 0 THEN 
				#LET l_msgresp = kandoomsg("I",9519,"") 
				#9519 Product has no surcharges TO delete
				LET l_msg_err = "Product ",l_arr_rec_product[l_arr_curr].part_code CLIPPED," has no surcharges to delete."
				CALL msgerror("",l_msg_err)  
 			ELSE
				#LET l_msgresp = kandoomsg("I",8042,l_arr_rec_product[l_arr_curr].part_code) 
				#LET l_msgresp = upshift(l_msgresp) 
				LET l_msg_err = "Confirmation to delete product ",l_arr_rec_product[l_arr_curr].part_code CLIPPED," surcharges?" 
				IF promptTF("",l_msg_err,TRUE) THEN 
					DELETE FROM prodsurcharge 
					WHERE prodsurcharge.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND prodsurcharge.part_code = l_arr_rec_product[l_arr_curr].part_code 
				END IF
			END IF

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

END FUNCTION 		# scan_products_list


FUNCTION edit_surcharge(p_part_code,p_mode) 
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_mode CHAR(4)
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodsurcharge RECORD LIKE prodsurcharge.* 
	DEFINE l_arr_rec_prodsurcharge DYNAMIC ARRAY OF RECORD
		low_qty LIKE prodsurcharge.low1_qty, 
		up_qty LIKE prodsurcharge.up1_qty, 
		sur_amt LIKE prodsurcharge.sur1_amt 
	END RECORD 
	DEFINE query_text STRING
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_tot_sur_amt LIKE prodsurcharge.sur1_amt
	DEFINE l_arr_curr SMALLINT
	DEFINE l_row_exists BOOLEAN
	DEFINE i SMALLINT

	OPEN WINDOW i640 with FORM "I640" 
	 CALL windecoration_i("I640") -- albo kd-758 
	#LET l_msgresp = kandoomsg("I",1318,"") 

	IF p_mode = "ADD" THEN 
		INPUT BY NAME l_rec_product.part_code WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","IZE","input-l_rec_product-1") -- albo kd-505
				CALL DIALOG.SetActionHidden("ADD", TRUE) 
				CALL DIALOG.SetActionHidden("INSERT", TRUE)

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			ON KEY (control-b) 
				CASE 
					WHEN infield(part_code) 
						LET l_winds_text = show_item(glob_rec_kandoouser.cmpy_code) 
						IF l_winds_text IS NOT NULL THEN 
							LET l_rec_product.part_code = l_winds_text 
						END IF 
						NEXT FIELD part_code 
				END CASE 

			AFTER FIELD part_code 
				IF l_rec_product.part_code IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD part_code 
				END IF 

				LET p_part_code = l_rec_product.part_code 
				SELECT * INTO l_rec_product.* FROM product 
				WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND product.part_code = p_part_code 
				IF STATUS = NOTFOUND THEN 
					ERROR kandoomsg2("U",9105,"") 
					#9105 RECORD NOT found - Try window
					NEXT FIELD part_code 
				END IF 

				SELECT COUNT(*) INTO i FROM prodsurcharge 
				WHERE prodsurcharge.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND prodsurcharge.part_code = l_rec_product.part_code 
				IF i <> 0 THEN 
					ERROR kandoomsg2("I",9518,"") 
					#9518 Surcharges FOR this product already exist
					NEXT FIELD part_code 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			CLOSE WINDOW i640 
			RETURN "" 
		END IF 
	ELSE 
		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE product.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND product.part_code = p_part_code 
	END IF 
	DISPLAY BY NAME l_rec_product.part_code, 
	l_rec_product.desc_text 

	DISPLAY l_rec_product.sell_uom_code, 
	l_rec_product.sell_uom_code, 
	modu_rec_glparms.base_currency_code 
	TO sr_uom[1].sell_uom_code, 
	sr_uom[2].sell_uom_code, 
	glparms.base_currency_code 

	CALL l_arr_rec_prodsurcharge.clear()
	INITIALIZE l_rec_prodsurcharge.* TO NULL

	SELECT 
	nvl(low1_qty,0),nvl(up1_qty,0),nvl(sur1_amt,0), 
	nvl(low2_qty,0),nvl(up2_qty,0),nvl(sur2_amt,0),
	nvl(low3_qty,0),nvl(up3_qty,0),nvl(sur3_amt,0),
	nvl(low4_qty,0),nvl(up4_qty,0),nvl(sur4_amt,0),
	nvl(low5_qty,0),nvl(up5_qty,0),nvl(sur5_amt,0),
	nvl(low6_qty,0),nvl(up6_qty,0),nvl(sur6_amt,0),
	nvl(low7_qty,0),nvl(up7_qty,0),nvl(sur7_amt,0),
	nvl(low8_qty,0),nvl(up8_qty,0),nvl(sur8_amt,0) 
	INTO 
	l_rec_prodsurcharge.low1_qty,l_rec_prodsurcharge.up1_qty,l_rec_prodsurcharge.sur1_amt, 
	l_rec_prodsurcharge.low2_qty,l_rec_prodsurcharge.up2_qty,l_rec_prodsurcharge.sur2_amt,
	l_rec_prodsurcharge.low3_qty,l_rec_prodsurcharge.up3_qty,l_rec_prodsurcharge.sur3_amt,
	l_rec_prodsurcharge.low4_qty,l_rec_prodsurcharge.up4_qty,l_rec_prodsurcharge.sur4_amt,
	l_rec_prodsurcharge.low5_qty,l_rec_prodsurcharge.up5_qty,l_rec_prodsurcharge.sur5_amt,
	l_rec_prodsurcharge.low6_qty,l_rec_prodsurcharge.up6_qty,l_rec_prodsurcharge.sur6_amt,
	l_rec_prodsurcharge.low7_qty,l_rec_prodsurcharge.up7_qty,l_rec_prodsurcharge.sur7_amt,
	l_rec_prodsurcharge.low8_qty,l_rec_prodsurcharge.up8_qty,l_rec_prodsurcharge.sur8_amt
	FROM prodsurcharge 
	WHERE prodsurcharge.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND prodsurcharge.part_code = p_part_code

	IF STATUS = NOTFOUND THEN
		LET l_row_exists = FALSE
		LET i = 0
	ELSE	
		LET l_row_exists = TRUE
		IF l_rec_prodsurcharge.low1_qty <> 0 OR l_rec_prodsurcharge.up1_qty <> 0 OR l_rec_prodsurcharge.sur1_amt <> 0 THEN
			LET i = 1
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low1_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up1_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur1_amt
		END IF			
		IF l_rec_prodsurcharge.low2_qty <> 0 OR l_rec_prodsurcharge.up2_qty <> 0 OR l_rec_prodsurcharge.sur2_amt <> 0 THEN
			LET i = 2
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low2_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up2_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur2_amt
		END IF
		IF l_rec_prodsurcharge.low3_qty <> 0 OR l_rec_prodsurcharge.up3_qty <> 0 OR l_rec_prodsurcharge.sur3_amt <> 0 THEN
			LET i = 3
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low3_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up3_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur3_amt
		END IF
		IF l_rec_prodsurcharge.low4_qty <> 0 OR l_rec_prodsurcharge.up4_qty <> 0 OR l_rec_prodsurcharge.sur4_amt <> 0 THEN
			LET i = 4
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low4_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up4_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur4_amt
		END IF
		IF l_rec_prodsurcharge.low5_qty <> 0 OR l_rec_prodsurcharge.up5_qty <> 0 OR l_rec_prodsurcharge.sur5_amt <> 0 THEN
			LET i = 5
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low5_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up5_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur5_amt
		END IF
		IF l_rec_prodsurcharge.low6_qty <> 0 OR l_rec_prodsurcharge.up6_qty <> 0 OR l_rec_prodsurcharge.sur6_amt <> 0 THEN
			LET i = 6
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low6_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up6_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur6_amt
		END IF
		IF l_rec_prodsurcharge.low7_qty <> 0 OR l_rec_prodsurcharge.up7_qty <> 0 OR l_rec_prodsurcharge.sur7_amt <> 0 THEN
			LET i = 7
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low7_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up7_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur7_amt
		END IF
		IF l_rec_prodsurcharge.low8_qty <> 0 OR l_rec_prodsurcharge.up8_qty <> 0 OR l_rec_prodsurcharge.sur8_amt <> 0 THEN
			LET i = 8
			LET l_arr_rec_prodsurcharge[i].low_qty = l_rec_prodsurcharge.low8_qty
			LET l_arr_rec_prodsurcharge[i].up_qty =  l_rec_prodsurcharge.up8_qty
			LET l_arr_rec_prodsurcharge[i].sur_amt = l_rec_prodsurcharge.sur8_amt
		END IF
	END IF 

	CALL set_count(i)
	LET l_tot_sur_amt = 0
	INPUT ARRAY l_arr_rec_prodsurcharge WITHOUT DEFAULTS FROM sr_prodsurcharge.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZE","input-arr-l_arr_rec_prodsurcharge-1") -- albo kd-505 
			CALL DIALOG.SetActionHidden("INSERT", TRUE)

		BEFORE INSERT	
			LET l_arr_curr = arr_curr()
			IF l_arr_curr > 8 THEN
				ERROR "A maximum of 8 surcharges can be entered for product."
				CANCEL INSERT
			END IF

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT
			# do sum of sur_amt to determine if amounts have been input
			LET l_tot_sur_amt = 0
			FOR i = 1 TO arr_count() 
				LET l_tot_sur_amt = l_tot_sur_amt + l_arr_rec_prodsurcharge[i].sur_amt
			END FOR

	END INPUT 
	CLOSE WINDOW i640 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	ELSE 
		IF l_tot_sur_amt > 0.00 THEN
			IF l_row_exists = FALSE THEN
				INSERT INTO prodsurcharge VALUES (
				glob_rec_kandoouser.cmpy_code,
				p_part_code,
				l_arr_rec_prodsurcharge[1].*,
				l_arr_rec_prodsurcharge[2].*,
				l_arr_rec_prodsurcharge[3].*,
				l_arr_rec_prodsurcharge[4].*,
				l_arr_rec_prodsurcharge[5].*,
				l_arr_rec_prodsurcharge[6].*,
				l_arr_rec_prodsurcharge[7].*,
				l_arr_rec_prodsurcharge[8].*
				)
			ELSE
				UPDATE prodsurcharge 
				SET (
				low1_qty, 
				up1_qty,             
				sur1_amt,            				            
				low2_qty,
				up2_qty,           
				sur2_amt,            
				low3_qty,            
				up3_qty,             
				sur3_amt,            
				low4_qty,            
				up4_qty,             
				sur4_amt,            
				low5_qty,            
				up5_qty,             
				sur5_amt,            
				low6_qty,            
				up6_qty,             
				sur6_amt,            
				low7_qty,            
				up7_qty,             
				sur7_amt,            
				low8_qty,            
				up8_qty,             
				sur8_amt
				)            
				= (l_arr_rec_prodsurcharge[1].*,
				l_arr_rec_prodsurcharge[2].*,
				l_arr_rec_prodsurcharge[3].*,
				l_arr_rec_prodsurcharge[4].*,
				l_arr_rec_prodsurcharge[5].*,
				l_arr_rec_prodsurcharge[6].*,
				l_arr_rec_prodsurcharge[7].*,
				l_arr_rec_prodsurcharge[8].* )
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				AND part_code = p_part_code
			END IF
		ELSE 
			# If the sum of the surcharges l_tot_sur_amt = 0, then we delete the surcharge for this product. 			
			DELETE FROM prodsurcharge 
			WHERE prodsurcharge.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND prodsurcharge.part_code = p_part_code 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN "" 
	END IF 

	RETURN p_part_code 

END FUNCTION 		# edit_surcharge
