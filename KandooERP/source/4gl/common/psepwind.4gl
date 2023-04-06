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
# break_prod                - Break Product segments
# get_uom_conversion_factor                  - UOM Convesrions
# validate_order_segment    - Validate that upto the ORDER segment has
#                             been entered
# validate_despatch_segment - Validate that upto the despatch segment has
#                             been entered
# validate_receipt_segment  - Validate that upto the receipt segment has
#                             been entered
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_product RECORD LIKE product.* 

###########################################################################
# FUNCTION break_prod(p_cmpy,p_part,p_class_code,p_verbose_ind)
#
#
###########################################################################
FUNCTION break_prod(p_cmpy,p_part,p_class_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE product.cmpy_code 
	DEFINE p_part LIKE product.part_code 
	DEFINE p_class_code LIKE product.class_code 
	DEFINE p_verbose_ind SMALLINT 

	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_pr_done SMALLINT 
	DEFINE l_part_length SMALLINT 
	DEFINE l_last_seq SMALLINT 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_dashlength SMALLINT 
	DEFINE l_flex SMALLINT 
	DEFINE l_start SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_orig_part LIKE product.part_code 
	DEFINE l_flex_part LIKE product.part_code 
	DEFINE l_dashes LIKE product.part_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	IF p_part IS NULL THEN 
		IF p_verbose_ind = 1 THEN 
			LET l_msgresp = kandoomsg("I",9213,"")		#9213 Invalid Part Code
			RETURN p_part,"","",0 
		ELSE 
			RETURN p_part,"","",-1 
		END IF 
	END IF 
	IF p_class_code IS NULL THEN 
		SELECT class_code INTO p_class_code FROM product 
		WHERE part_code = p_part 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			IF p_verbose_ind = 1 THEN 
				LET l_msgresp = kandoomsg("I",9213,"") 
				#9213 Invalid Part Code
				RETURN p_part,"","",0 
			ELSE 
				RETURN p_part,"","",-1 
			END IF 
		END IF 
	END IF 

	DECLARE structcur CURSOR FOR 
	SELECT * FROM prodstructure 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 
	ORDER BY class_code,seq_num,cmpy_code 

	SELECT * INTO l_rec_class.* FROM class 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 

	LET l_flex = 0 
	LET l_length = 0 
	LET l_start = 0 
	LET l_part_length = length(p_part) 
	LET l_pr_done = 0 

	FOREACH structcur INTO l_rec_prodstructure.* 
		LET l_length = l_length + l_rec_prodstructure.length 
		IF l_rec_prodstructure.seq_num = l_rec_class.price_level_ind THEN 
			LET l_start = l_rec_prodstructure.start_num 
			+ l_rec_prodstructure.length 
		END IF 
		IF l_rec_prodstructure.seq_num > l_rec_class.price_level_ind THEN 
			LET l_flex = l_flex + l_rec_prodstructure.length 
		END IF 
		IF l_pr_done = 0 THEN 
			IF l_length > l_part_length THEN 
				LET l_last_seq = l_rec_prodstructure.seq_num 
				LET l_pr_done = 1 
			END IF 
		END IF 
		IF l_pr_done = 0 THEN 
			LET l_last_seq = l_rec_prodstructure.seq_num 
		END IF 
	END FOREACH 

	LET l_dashes = NULL 

	SELECT * INTO l_rec_prodstructure.* FROM prodstructure 
	WHERE class_code = l_rec_class.class_code 
	AND seq_num = l_rec_class.price_level_ind + 1 
	AND cmpy_code = p_cmpy 

	IF status = notfound THEN 
	ELSE 
		IF l_rec_prodstructure.type_ind = "F" THEN 
			FOR i = 1 TO l_rec_prodstructure.length 
				LET l_dashes[i,i] = l_rec_prodstructure.desc_text clipped 
			END FOR 
			LET l_start = l_start + l_rec_prodstructure.length 
			LET l_flex = l_flex - l_rec_prodstructure.length 
		END IF 
	END IF 

	IF l_start > 0 THEN 
		SELECT * INTO l_rec_prodstructure.* FROM prodstructure 
		WHERE class_code = l_rec_class.class_code 
		AND seq_num = l_last_seq 
		AND cmpy_code = p_cmpy 
		IF l_rec_prodstructure.type_ind = "F" THEN 
			FOR i = l_rec_prodstructure.start_num TO 
				(l_rec_prodstructure.start_num + (l_rec_prodstructure.length - 1)) 
				LET p_part[i,i] = " " 
			END FOR 
		END IF 
	END IF 
	LET l_dashlength = length(l_dashes) 

	IF l_length > 0 THEN 
		IF l_start > 1 THEN 
			LET l_orig_part = p_part[1,(l_start-1) - l_dashlength] 
			IF l_flex > 0 THEN 
				LET l_flex_part = p_part[l_start,15] 
			ELSE 
				LET l_flex_part = NULL 
			END IF 
		ELSE 
			LET l_orig_part = NULL 
			LET l_flex_part = p_part 
		END IF 
	ELSE 
		LET l_orig_part = p_part 
		LET l_flex_part = NULL 
	END IF 

	IF length(l_flex_part) = 0 THEN 
		LET l_flex_part = NULL 
	END IF 

	RETURN l_orig_part,l_dashes,l_flex_part,l_flex 
END FUNCTION 
###########################################################################
# END FUNCTION break_prod(p_cmpy,p_part,p_class_code,p_verbose_ind)
###########################################################################


###########################################################################
# FUNCTION get_uom_conversion_factor(p_cmpy, p_part_code, p_from_code, p_to_code,p_verbose_ind)
# Happy to know this is a function!!! thanks for removing the doubt!   ericv 2020-11-17
# This function operates a conversion of Units of Measure (UOM) from a source product to a target product
###########################################################################
FUNCTION get_uom_conversion_factor(p_cmpy,p_part_code,p_from_code,p_to_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE uomconv.part_code 
	DEFINE p_from_code LIKE uomconv.uom_code 
	DEFINE p_to_code LIKE uomconv.uom_code 
	DEFINE p_verbose_ind SMALLINT 

	DEFINE l_from_qty FLOAT 
	DEFINE l_to_qty FLOAT 
	DEFINE l_rec_uomconv RECORD LIKE uomconv.* 
	DEFINE l_rec_uomconv1 RECORD LIKE uomconv.* 
	DEFINE l_rec_uomconv2 RECORD LIKE uomconv.* 
	DEFINE l_err_message CHAR(70) 
	DEFINE l_msg CHAR(70) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_from_code = p_to_code THEN 
		RETURN 1 
	END IF 

	INITIALIZE l_rec_uomconv1.* TO NULL 
	INITIALIZE l_rec_uomconv2.* TO NULL 

	CALL get_uomconv(p_cmpy,p_part_code,p_from_code) RETURNING l_rec_uomconv1.* 

	IF l_rec_uomconv1.conversion_qty != -1 THEN 
		CALL get_uomconv(p_cmpy,p_part_code,p_to_code) RETURNING l_rec_uomconv2.* 

		IF l_rec_uomconv2.conversion_qty != -1 THEN 
			CALL get_ratio(p_cmpy,p_part_code,l_rec_uomconv1.*) RETURNING l_from_qty,l_msg 

			IF l_from_qty != -1 THEN 
				CALL get_ratio(p_cmpy,p_part_code,l_rec_uomconv2.*) RETURNING l_to_qty,	l_msg 

				IF l_to_qty != -1 THEN 
					IF l_rec_uomconv2.uom_type = "Q" THEN 
						LET l_rec_uomconv.conversion_qty = l_from_qty/l_to_qty 
					ELSE 
						LET l_rec_uomconv.conversion_qty = (l_from_qty/l_to_qty) 
					END IF 

				ELSE 
					LET l_rec_uomconv.conversion_qty = -1 
				END IF 

			ELSE 
				LET l_rec_uomconv.conversion_qty = -1 
			END IF 

		ELSE 
			LET l_rec_uomconv.conversion_qty = -1 
		END IF 

	ELSE 
		LET l_rec_uomconv.conversion_qty = -1 
	END IF 

	IF l_rec_uomconv.conversion_qty = -1 AND p_verbose_ind = 1 THEN 
		IF l_rec_uomconv1.conversion_qty = -1 THEN 
			#No conversion factor found
			LET l_err_message = "UOM conversion failed - ", 
			"UOM ",p_from_code clipped," has NOT been SET up" 
			LET l_msgresp = kandoomsg("U",8,l_err_message) 
		END IF 

		IF l_rec_uomconv2.conversion_qty = -1 THEN 
			#No conversion factor found
			LET l_err_message = "UOM conversion failed - ", 
			"UOM ",p_to_code clipped," has NOT been SET up" 
			LET l_msgresp = kandoomsg("U",8,l_err_message) 
		END IF 

		IF l_from_qty = -1 THEN 
			#Conversion Factor Error Found
			LET l_msgresp = kandoomsg("U",8,l_msg) 
		END IF 

		IF l_to_qty = -1 THEN 
			#Conversion Factor Error Found
			LET l_msgresp = kandoomsg("U",8,l_msg) 
		END IF 
		LET l_rec_uomconv.conversion_qty = -1 

		RETURN l_rec_uomconv.conversion_qty 
	END IF 

	IF l_rec_uomconv.conversion_qty = -1 AND p_verbose_ind = 2 THEN 
		LET l_rec_uomconv.conversion_qty = -1 
		RETURN l_rec_uomconv.conversion_qty 
	END IF 

	RETURN l_rec_uomconv.conversion_qty 
END FUNCTION 
###########################################################################
# END FUNCTION get_uom_conversion_factor(p_cmpy, p_part_code, p_from_code, p_to_code,p_verbose_ind)
###########################################################################


###########################################################################
# FUNCTION get_uomconv(p_cmpy, p_part_code, p_from)
#
#
###########################################################################
FUNCTION get_uomconv(p_cmpy,p_part_code,p_from) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE uomconv.part_code 
	DEFINE p_from LIKE uomconv.uom_code 
	DEFINE l_rec_uomconv RECORD LIKE uomconv.* 
	DEFINE l_rec_uomconv2 RECORD LIKE uomconv.* 
	DEFINE l_part_match CHAR(30) 

	IF p_part_code != modu_rec_product.part_code 
	OR modu_rec_product.part_code IS NULL THEN 
		SELECT * INTO modu_rec_product.* FROM product 
		WHERE part_code = p_part_code 
		AND cmpy_code = p_cmpy 
	END IF 

	INITIALIZE l_rec_uomconv.* TO NULL 
	DECLARE c1_uomconv CURSOR FOR 

	SELECT * INTO l_rec_uomconv.* FROM uomconv 
	WHERE cmpy_code = p_cmpy 
	AND uom_code = p_from 
	AND conversion_qty > 0 
	AND ((part_code = p_part_code 
	OR prodgrp_code = modu_rec_product.prodgrp_code 
	OR maingrp_code = modu_rec_product.maingrp_code) 
	OR (part_code IS NULL 
	AND prodgrp_code IS NULL 
	AND maingrp_code IS null)) 
	ORDER BY part_code desc, prodgrp_code desc, maingrp_code desc 

	OPEN c1_uomconv 
	FETCH c1_uomconv INTO l_rec_uomconv.* 
	CLOSE c1_uomconv 

	IF l_rec_uomconv.part_code IS NULL THEN 
		DECLARE c2_uomconv CURSOR FOR 
		SELECT * FROM uomconv 
		WHERE cmpy_code = p_cmpy 
		AND uom_code = p_from 
		AND (part_code IS NOT NULL 
		AND class_code = modu_rec_product.class_code) 
		AND conversion_qty > 0 
		
		FOREACH c2_uomconv INTO l_rec_uomconv2.* 
			LET l_part_match = l_rec_uomconv2.part_code clipped, "*" 
			IF p_part_code matches l_part_match THEN 
				LET l_rec_uomconv.* = l_rec_uomconv2.* 
				RETURN l_rec_uomconv.* 
			END IF 
		END FOREACH
		 
	END IF
	 
	IF l_rec_uomconv.uom_code IS NULL THEN 
		LET l_rec_uomconv.conversion_qty = -1 
	END IF
	 
	RETURN l_rec_uomconv.* 
END FUNCTION
###########################################################################
# END FUNCTION get_uomconv(p_cmpy, p_part_code, p_from)
###########################################################################


###########################################################################
# FUNCTION get_ratio(p_cmpy,p_part_code,p_rec_uomconv)
#
#
###########################################################################
FUNCTION get_ratio(p_cmpy,p_part_code,p_rec_uomconv) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_rec_uomconv RECORD LIKE uomconv.* 
	DEFINE l_ratio FLOAT 
	DEFINE l_msg CHAR(60) 

	LET l_msg = "" 
	IF p_part_code != modu_rec_product.part_code 
	OR modu_rec_product.part_code IS NULL THEN 
		SELECT * INTO modu_rec_product.* FROM product 
		WHERE part_code = p_part_code 
		AND cmpy_code = p_cmpy 
	END IF 

	CASE p_rec_uomconv.uom_type 
		WHEN "Q" 
			LET l_ratio = 1 / p_rec_uomconv.conversion_qty 
			RETURN l_ratio,l_msg 

		WHEN "A" 
			IF modu_rec_product.area_qty <= 0 
			OR modu_rec_product.area_qty IS NULL THEN 
				LET l_ratio = -1 
				LET l_msg = "Product area quantity IS 0 OR less than 0" 
			ELSE 
				LET l_ratio = modu_rec_product.area_qty / p_rec_uomconv.conversion_qty 
			END IF 
			RETURN l_ratio,l_msg 

		WHEN "L" 
			IF modu_rec_product.length_qty <= 0 
			OR modu_rec_product.length_qty IS NULL THEN 
				LET l_ratio = -1 
				LET l_msg = "Product length value IS 0 OR less than 0" 
			ELSE 
				LET l_ratio = modu_rec_product.length_qty / p_rec_uomconv.conversion_qty 
			END IF 
			RETURN l_ratio,l_msg 

		WHEN "W" 
			IF modu_rec_product.weight_qty <= 0 
			OR modu_rec_product.weight_qty IS NULL THEN 
				LET l_ratio = -1 
				LET l_msg = "Product weight value IS 0 OR less than 0" 
			ELSE 
				LET l_ratio = modu_rec_product.weight_qty / p_rec_uomconv.conversion_qty 
			END IF 
			RETURN l_ratio,l_msg 

		WHEN "V" 
			IF modu_rec_product.cubic_qty <= 0 
			OR modu_rec_product.cubic_qty IS NULL THEN 
				LET l_ratio = -1 
				LET l_msg = "Product volume IS 0 OR less than 0" 
			ELSE 
				LET l_ratio = modu_rec_product.cubic_qty / p_rec_uomconv.conversion_qty 
			END IF 
			RETURN l_ratio,l_msg 

		WHEN "P" 
			IF modu_rec_product.pack_qty <= 0 
			OR modu_rec_product.pack_qty IS NULL THEN 
				LET l_ratio = -1 
				LET l_msg = "Product pack/pallet quantity IS 0 OR less than 0" 
			ELSE 
				LET l_ratio = 1 / modu_rec_product.pack_qty 
			END IF 
			RETURN l_ratio,l_msg 
	END CASE 

END FUNCTION 
###########################################################################
# END FUNCTION get_ratio(p_cmpy,p_part_code,p_rec_uomconv)
###########################################################################


############################################################
# FUNCTION valid_pallet(p_cmpy,p_kandoouser_sign_on_code,p_cust_code,p_ware_code,p_verbose_ind)
#
#
############################################################
FUNCTION valid_pallet(p_cmpy,p_kandoouser_sign_on_code,p_cust_code,p_ware_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_ware_code LIKE location.ware_code 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE l_rec_mbparms RECORD LIKE mbparms.* 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE l_rec_location RECORD LIKE location.* 
	DEFINE l_pallet_price LIKE ordhead.pallet_price_amt 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_mbparms.* FROM mbparms 
	WHERE cmpy_code = p_cmpy 

	IF p_ware_code IS NULL THEN 
		SELECT * INTO l_rec_userlocn.* FROM userlocn 
		WHERE cmpy_code = p_cmpy 
		AND sign_on_code = p_kandoouser_sign_on_code 
		SELECT * INTO l_rec_location.* FROM location 
		WHERE cmpy_code = p_cmpy 
		AND locn_code = l_rec_userlocn.locn_code 
		LET p_ware_code = l_rec_location.ware_code 
	END IF 

	IF l_rec_mbparms.pallet_part_code IS NULL AND p_verbose_ind = 1 THEN 
		LET l_msgresp = kandoomsg("W",5008,"WZP")	#5008 Pallet Product NOT SET up - Refer Menu WZP"
		RETURN false 
	END IF 

	IF l_rec_mbparms.pallet_part_code IS NULL AND p_verbose_ind = 1 THEN 
		RETURN false 
	END IF 

	SELECT unique 1 FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_mbparms.pallet_part_code 
	IF status = notfound THEN 
		IF p_verbose_ind = 1 THEN 
			LET l_msgresp = kandoomsg("W",5008,"I11")		#5008 Pallet Product NOT SET up - Refer Menu I11"
			RETURN false 
		ELSE 
			RETURN false 
		END IF 
	END IF 

	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = p_cmpy 
	AND part_code = l_rec_mbparms.pallet_part_code 
	AND ware_code = p_ware_code 
	IF status = notfound THEN 
		IF p_verbose_ind = 1 THEN 
			LET l_msgresp = kandoomsg("W",5009,"I16")	#5009 Pallet Pricing unavailable - Refer Menu I16"
			RETURN false 
		ELSE 
			RETURN false 
		END IF 
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	CASE (l_rec_customer.inv_level_ind) 
		WHEN "1" LET l_pallet_price = l_rec_prodstatus.price1_amt 
		WHEN "2" LET l_pallet_price = l_rec_prodstatus.price2_amt 
		WHEN "3" LET l_pallet_price = l_rec_prodstatus.price3_amt 
		WHEN "4" LET l_pallet_price = l_rec_prodstatus.price4_amt 
		WHEN "5" LET l_pallet_price = l_rec_prodstatus.price5_amt 
		WHEN "6" LET l_pallet_price = l_rec_prodstatus.price6_amt 
		WHEN "7" LET l_pallet_price = l_rec_prodstatus.price7_amt 
		WHEN "8" LET l_pallet_price = l_rec_prodstatus.price8_amt 
		WHEN "9" LET l_pallet_price = l_rec_prodstatus.price9_amt 
		WHEN "C" LET l_pallet_price = l_rec_prodstatus.wgted_cost_amt 
		WHEN "L" LET l_pallet_price = l_rec_prodstatus.list_amt 
		OTHERWISE 
			LET l_pallet_price = l_rec_prodstatus.list_amt 
	END CASE 

	IF l_pallet_price IS NULL THEN 
		LET l_pallet_price = 0 
	END IF 
	RETURN l_pallet_price 
END FUNCTION 
############################################################
# END FUNCTION valid_pallet(p_cmpy,p_kandoouser_sign_on_code,p_cust_code,p_ware_code,p_verbose_ind)
############################################################


############################################################
# FUNCTION validate_order_segment(p_cmpy, p_part_code, p_class_code, p_verbose_ind)
#
#
############################################################
FUNCTION validate_order_segment(p_cmpy,p_part_code,p_class_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_ord_level_ind LIKE class.ord_level_ind 
	DEFINE l_part_len LIKE prodstructure.length 
	DEFINE l_min_ord_level_len LIKE prodstructure.length 

	SELECT ord_level_ind INTO l_ord_level_ind FROM class 
	WHERE cmpy_code = p_cmpy 
	AND class_code = p_class_code 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" AND psep_mult_segs(p_cmpy,p_class_code) THEN 
		SELECT start_num INTO l_min_ord_level_len FROM prodstructure 
		WHERE cmpy_code = p_cmpy 
		AND class_code = p_class_code 
		AND seq_num = l_ord_level_ind 
		IF status = notfound 
		OR l_min_ord_level_len IS NULL THEN 
			LET l_min_ord_level_len = 15 
		END IF 
		LET l_part_len = length(p_part_code) 
		IF l_part_len < l_min_ord_level_len THEN 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION validate_order_segment(p_cmpy, p_part_code, p_class_code, p_verbose_ind)
############################################################


############################################################
# FUNCTION validate_receipt_segment(p_cmpy, p_part_code, p_verbose_ind)
#
#
############################################################
FUNCTION validate_receipt_segment(p_cmpy,p_part_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_verbose_ind SMALLINT 
	DEFINE l_class_code LIKE class.class_code 
	DEFINE l_stock_level_ind LIKE class.stock_level_ind 
	DEFINE l_part_len LIKE prodstructure.length 
	DEFINE l_min_stock_level_len LIKE prodstructure.length 

	SELECT c.class_code, c.stock_level_ind INTO l_class_code, l_stock_level_ind 
	FROM class c, product p 
	WHERE c.cmpy_code = p_cmpy 
	AND p.cmpy_code = p_cmpy 
	AND p.class_code = c.class_code 
	AND p.part_code = p_part_code 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" 
	AND psep_mult_segs(p_cmpy,l_class_code) THEN 
		SELECT (p.start_num) INTO l_min_stock_level_len 
		FROM prodstructure p 
		WHERE p.cmpy_code = p_cmpy 
		AND p.class_code = l_class_code 
		AND p.seq_num = l_stock_level_ind 

		IF status = notfound 
		OR l_min_stock_level_len IS NULL THEN 
			LET l_min_stock_level_len = 15 
		END IF 

		LET l_part_len = length(p_part_code) 

		IF l_part_len < l_min_stock_level_len THEN 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION validate_receipt_segment(p_cmpy, p_part_code, p_verbose_ind)
############################################################


############################################################
# FUNCTION validate_receipt_segment(p_cmpy, p_part_code, p_verbose_ind)
#
#
############################################################
FUNCTION validate_despatch_segment(p_cmpy,p_part_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_verbose_ind SMALLINT 

	DEFINE l_cpart_code LIKE product.part_code 
	DEFINE l_class_code LIKE class.class_code 
	DEFINE l_seq_num LIKE prodstructure.seq_num 
	DEFINE l_maxresp CHAR(1) 
	DEFINE l_part_len LIKE prodstructure.length 
	DEFINE l_class_length LIKE prodstructure.length 
	DEFINE l_min_len LIKE prodstructure.length 

	LET l_cpart_code = p_part_code clipped 
	SELECT class_code INTO l_class_code 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_part_code 

	IF get_kandoooption_feature_state(TRAN_TYPE_INVOICE_IN,"FS") = "Y" AND psep_mult_segs(p_cmpy,l_class_code) THEN 
		SELECT sum(p.length) INTO l_class_length 
		FROM prodstructure p 
		WHERE p.cmpy_code = p_cmpy 
		AND p.class_code = l_class_code 
		IF status = notfound THEN 

			IF p_verbose_ind THEN 
				LET l_maxresp = kandoomsg("I",5012,l_class_code) 
			END IF 
			RETURN false 
		END IF 

		IF l_class_length IS NULL THEN 
			LET l_class_length = 15 
		END IF 

		SELECT max(seq_num) INTO l_seq_num 
		FROM prodstructure 
		WHERE cmpy_code = p_cmpy 
		AND class_code = l_class_code 

		IF status = notfound THEN 

			IF p_verbose_ind THEN 
				LET l_maxresp = kandoomsg("I",5012,l_class_code) 
			END IF 
			RETURN false 
		END IF 

		IF l_seq_num IS NULL THEN 
			LET l_seq_num = 1 
		END IF 

		IF l_seq_num = 1 THEN 
			LET l_min_len = 1 
		ELSE 
			SELECT sum(p.length) + 1 INTO l_min_len 
			FROM prodstructure p 
			WHERE p.cmpy_code = p_cmpy 
			AND p.class_code = l_class_code 
			AND p.seq_num < l_seq_num 

			IF l_min_len IS NULL 
			OR l_min_len = 0 THEN 
				LET l_min_len = 1 
			END IF 
		END IF 
		LET l_part_len = length(l_cpart_code) 
	
		IF l_part_len < l_min_len	OR l_part_len > l_class_length THEN 
			RETURN false 
		ELSE 
			RETURN true 
		END IF 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 
############################################################
# END FUNCTION validate_receipt_segment(p_cmpy, p_part_code, p_verbose_ind)
############################################################


############################################################
# FUNCTION psep_mult_segs(p_cmpy,p_class_code)
#
#
############################################################
FUNCTION psep_mult_segs(p_cmpy,p_class_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_segment_cnt SMALLINT 

	SELECT count(*) INTO l_segment_cnt FROM prodstructure 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 

	IF l_segment_cnt < 2 THEN 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION matrix_break_prod(p_cmpy,p_part_code,p_class_code,p_verbose_ind)
#
#
############################################################
FUNCTION matrix_break_prod(p_cmpy,p_part_code,p_class_code,p_verbose_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_class_code LIKE product.class_code 
	DEFINE p_verbose_ind SMALLINT 

	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_parent_code LIKE product.part_code 
	DEFINE l_horizontal_code LIKE product.part_code 
	DEFINE l_vertical_code LIKE product.part_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 

	IF p_part_code IS NULL THEN 
		IF p_verbose_ind = 1 THEN 
			LET l_msgresp = kandoomsg("I",9213,"")	#9213 Invalid Part Code
			RETURN p_part_code,"","",0 
		ELSE 
			RETURN p_part_code,"","",0 
		END IF 
	END IF 

	IF p_class_code IS NULL THEN 
		SELECT class_code INTO p_class_code FROM product 
		WHERE part_code = p_part_code 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			IF p_verbose_ind = 1 THEN 
				LET l_msgresp = kandoomsg("I",9213,"")	#9213 Invalid Part Code
				RETURN p_part_code,"","",0 
			ELSE 
				RETURN p_part_code,"","",0 
			END IF 
		END IF 
	END IF 

	SELECT * INTO l_rec_class.* FROM class 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 

	SELECT unique 1 FROM prodstructure 
	WHERE type_ind = "H" 
	AND cmpy_code = p_cmpy 
	AND class_code = l_rec_class.class_code 

	IF status = notfound THEN 
		RETURN p_part_code,"","",0 
	END IF 

	DECLARE c_structcur1 CURSOR FOR 
	SELECT * FROM prodstructure 
	WHERE class_code = p_class_code 
	AND cmpy_code = p_cmpy 
	ORDER BY class_code,seq_num,cmpy_code 
	
	LET l_parent_code = NULL 
	LET l_vertical_code = NULL 
	LET l_horizontal_code = NULL 

	FOREACH c_structcur1 INTO l_rec_prodstructure.* 
		IF l_rec_prodstructure.seq_num = l_rec_class.price_level_ind THEN 
			LET i = l_rec_prodstructure.start_num	+ l_rec_prodstructure.length - 1 
			LET l_parent_code = p_part_code[1,i] 
		END IF 
		
		IF l_rec_prodstructure.type_ind = "H" THEN 
			LET i = l_rec_prodstructure.start_num 
			LET j = l_rec_prodstructure.start_num	+ l_rec_prodstructure.length - 1 
			LET l_horizontal_code = p_part_code[i, j] 
		END IF 
		
		IF l_rec_prodstructure.type_ind = "V" THEN 
			LET i = l_rec_prodstructure.start_num 
			LET j = l_rec_prodstructure.start_num	+ l_rec_prodstructure.length - 1 
			LET l_vertical_code = p_part_code[i, j] 
		END IF 
	END FOREACH 

	RETURN l_parent_code, l_horizontal_code, l_vertical_code, 1 
END FUNCTION 
############################################################
# END FUNCTION psep_mult_segs(p_cmpy,p_class_code)
############################################################