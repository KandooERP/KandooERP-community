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
#  Product Level Pricing:
#  ---------------------
#        This FUNCTION could be executed twice. FOR type_ind = '1' - Selected
#  Customers, read through the pricing table FOR the following situations AND
#  IF match IS made THEN check customer has this offer AND apply the discount
#  in either amount OR percentage FORMAT. IF percentages are TO be used THEN
#  these are TO be taken FROM the pricing.list_level_ind. WHERE no customer
#  offers are found AT all, ie. no matching has occured, the customer
#  receives list_amt (L).
#     - exact part_code matching
#     - match of part_code AND exact matching of class_code
#     - exact prodgrp_code matching
#     - exact maingrp_code matching
#     - part, prodgrp AND maingrp are all NULL (ie. discount FOR all products)
#        The alternative method IF FOR type = '2' All Customers, Simply read
#  through the pricing file FOR the above situations AND IF match IS made,
#  apply the discount in either amount OR percentage FORMAT. Rules are as above
#
###########################################################################

GLOBALS "../common/glob_GLOBALS.4gl" 
--DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
DEFINE modu_rec_product RECORD LIKE product.* 
DEFINE modu_rec_pricing RECORD LIKE pricing.* 
DEFINE modu_offer_code LIKE orderdetl.offer_code 
DEFINE modu_new_list LIKE orderdetl.list_price_amt 
DEFINE modu_rec_product_price LIKE orderdetl.unit_price_amt 
--DEFINE pr_other_price LIKE orderdetl.unit_price_amt 
DEFINE modu_part_match CHAR(30) 
DEFINE modu_error_ind INTEGER 

###########################################################################
# FUNCTION prod_price(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date)
#
#
###########################################################################
FUNCTION prod_price(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code  LIKE orderdetl.part_code 
	DEFINE p_cust_code  LIKE orderdetl.cust_code 
	DEFINE p_ware_code  LIKE orderdetl.ware_code 
	DEFINE p_type_ind   LIKE pricing.type_ind 
	DEFINE p_order_date LIKE ordhead.order_date 

	LET modu_error_ind = FALSE 
	SELECT * INTO modu_rec_product.* FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = p_cmpy 
	LET modu_rec_product_price = 0 
	LET modu_offer_code = NULL 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = p_cmpy 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	IF STATUS != NOTFOUND THEN 
		DECLARE c1_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND part_code = p_part_code 
		AND ware_code = p_ware_code 
		AND cmpy_code = p_cmpy 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		ORDER BY start_date desc, offer_code 

		FOREACH c1_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 

			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 

			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND part_code = p_part_code 
	AND ware_code IS NULL 
	AND cmpy_code = p_cmpy 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	IF STATUS != NOTFOUND THEN 
		DECLARE c2_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND part_code = p_part_code 
		AND ware_code IS NULL 
		AND cmpy_code = p_cmpy 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		ORDER BY start_date desc, offer_code 

		FOREACH c2_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND class_code = modu_rec_product.class_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c3_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND class_code = modu_rec_product.class_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c3_pricing INTO modu_rec_pricing.* 
			LET modu_part_match = modu_rec_pricing.part_code clipped,"*" 
			IF p_part_code matches modu_part_match THEN 
				CALL get_price(p_cmpy, 
				p_order_date, 
				p_part_code, 
				p_cust_code, 
				p_ware_code) 
				IF modu_error_ind THEN 
					RETURN modu_rec_product_price, modu_error_ind 
				END IF 
				IF modu_rec_product_price != 0 THEN 
					RETURN modu_rec_product_price, modu_error_ind 
				END IF 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND class_code = modu_rec_product.class_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c4_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND class_code = modu_rec_product.class_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c4_pricing INTO modu_rec_pricing.* 
			LET modu_part_match = modu_rec_pricing.part_code clipped,"*" 
			IF p_part_code matches modu_part_match THEN 
				CALL get_price(p_cmpy, 
				p_order_date, 
				p_part_code, 
				p_cust_code, 
				p_ware_code) 
				IF modu_error_ind THEN 
					RETURN modu_rec_product_price, modu_error_ind 
				END IF 
				IF modu_rec_product_price != 0 THEN 
					RETURN modu_rec_product_price, modu_error_ind 
				END IF 
			END IF 
		END FOREACH 
	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND prodgrp_code = modu_rec_product.prodgrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c5_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND prodgrp_code = modu_rec_product.prodgrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c5_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 
	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND prodgrp_code = modu_rec_product.prodgrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c6_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND prodgrp_code = modu_rec_product.prodgrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c6_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 
	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND maingrp_code = modu_rec_product.maingrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c7_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND maingrp_code = modu_rec_product.maingrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c7_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND maingrp_code = modu_rec_product.maingrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c8_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND maingrp_code = modu_rec_product.maingrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c8_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND part_code IS NULL 
	AND class_code IS NULL 
	AND prodgrp_code IS NULL 
	AND maingrp_code IS NULL 
	AND ware_code = p_ware_code 
	AND cmpy_code = p_cmpy 
	IF STATUS != NOTFOUND THEN 
		DECLARE c9_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND part_code IS NULL 
		AND class_code IS NULL 
		AND prodgrp_code IS NULL 
		AND maingrp_code IS NULL 
		AND ware_code = p_ware_code 
		AND cmpy_code = p_cmpy 
		ORDER BY start_date desc, offer_code 

		FOREACH c9_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND part_code IS NULL 
	AND prodgrp_code IS NULL 
	AND maingrp_code IS NULL 
	AND ware_code IS NULL 
	AND class_code IS NULL 
	AND cmpy_code = p_cmpy 
	IF STATUS != NOTFOUND THEN 
		DECLARE c10_pricing CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND part_code IS NULL 
		AND prodgrp_code IS NULL 
		AND maingrp_code IS NULL 
		AND ware_code IS NULL 
		AND class_code IS NULL 
		AND cmpy_code = p_cmpy 
		ORDER BY start_date desc, offer_code 

		FOREACH c10_pricing INTO modu_rec_pricing.* 
			CALL get_price(p_cmpy, 
			p_order_date, 
			p_part_code, 
			p_cust_code, 
			p_ware_code) 
			IF modu_error_ind THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
			IF modu_rec_product_price != 0 THEN 
				RETURN modu_rec_product_price, modu_error_ind 
			END IF 
		END FOREACH 

	END IF 
	RETURN modu_rec_product_price, modu_error_ind 
END FUNCTION 
###########################################################################
# END FUNCTION prod_price(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date)
###########################################################################


###########################################################################
# FUNCTION get_price(p_cmpy,p_order_date,p_part_code,p_cust_code,p_ware_code)
#
#
###########################################################################
FUNCTION get_price(p_cmpy,p_order_date,p_part_code,p_cust_code,p_ware_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_order_date LIKE ordhead.order_date 
	DEFINE p_part_code LIKE orderdetl.part_code 
	DEFINE p_cust_code LIKE orderdetl.cust_code 
	DEFINE p_ware_code LIKE orderdetl.ware_code 
	DEFINE l_rec_prodstatus RECORD LIKE prodstatus.* 

	LET modu_error_ind = FALSE 
	IF modu_rec_pricing.type_ind = "1" THEN 
		SELECT UNIQUE 1 FROM custoffer 
		WHERE cust_code = p_cust_code 
		AND offer_code = modu_rec_pricing.offer_code 
		AND effective_date <= p_order_date 
		AND cmpy_code = p_cmpy 
		IF STATUS = NOTFOUND THEN 
			RETURN 
		END IF 
	END IF 

	LET modu_offer_code = modu_rec_pricing.offer_code 

	IF modu_rec_pricing.disc_price_amt IS NOT NULL THEN 
		LET modu_rec_product_price = modu_rec_pricing.disc_price_amt 
		RETURN 
	END IF 

	#    % must exist
	SELECT * INTO l_rec_prodstatus.* FROM prodstatus 
	WHERE part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = p_cmpy 

	CASE (modu_rec_pricing.list_level_ind) 
		WHEN "1" LET modu_new_list = l_rec_prodstatus.price1_amt 
		WHEN "2" LET modu_new_list = l_rec_prodstatus.price2_amt 
		WHEN "3" LET modu_new_list = l_rec_prodstatus.price3_amt 
		WHEN "4" LET modu_new_list = l_rec_prodstatus.price4_amt 
		WHEN "5" LET modu_new_list = l_rec_prodstatus.price5_amt 
		WHEN "6" LET modu_new_list = l_rec_prodstatus.price6_amt 
		WHEN "7" LET modu_new_list = l_rec_prodstatus.price7_amt 
		WHEN "8" LET modu_new_list = l_rec_prodstatus.price8_amt 
		WHEN "9" LET modu_new_list = l_rec_prodstatus.price9_amt 
		WHEN "C" LET modu_new_list = l_rec_prodstatus.wgted_cost_amt 
		WHEN "L" LET modu_new_list = l_rec_prodstatus.list_amt 
		OTHERWISE 
			LET modu_new_list = l_rec_prodstatus.list_amt 
	END CASE 
	
	IF modu_new_list IS NULL THEN 
		LET modu_new_list = 0 
	END IF 
	LET modu_rec_product_price = modu_new_list - ((modu_new_list * modu_rec_pricing.disc_per) / 100) 
END FUNCTION 
###########################################################################
# FUNCTION get_price(p_cmpy,p_order_date,p_part_code,p_cust_code,p_ware_code)
###########################################################################


###########################################################################
# FUNCTION prod_exclude(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date)
#
#
###########################################################################
FUNCTION prod_exclude(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_part_code  LIKE orderdetl.part_code 
	DEFINE p_cust_code  LIKE orderdetl.cust_code 
	DEFINE p_ware_code  LIKE orderdetl.ware_code 
	DEFINE p_type_ind   LIKE pricing.type_ind 
	DEFINE p_order_date LIKE ordhead.order_date 

	SELECT * INTO modu_rec_product.* FROM product 
	WHERE part_code = p_part_code 
	AND cmpy_code = p_cmpy 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND part_code = p_part_code 
	AND ware_code = p_ware_code 
	AND cmpy_code = p_cmpy 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	IF STATUS != NOTFOUND THEN 
		DECLARE c1_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND part_code = p_part_code 
		AND ware_code = p_ware_code 
		AND cmpy_code = p_cmpy 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		ORDER BY start_date desc, offer_code 

		FOREACH c1_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND part_code = p_part_code 
	AND ware_code IS NULL 
	AND cmpy_code = p_cmpy 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	IF STATUS != NOTFOUND THEN 
		DECLARE c2_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND part_code = p_part_code 
		AND ware_code IS NULL 
		AND cmpy_code = p_cmpy 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		ORDER BY start_date desc, offer_code 

		FOREACH c2_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND part_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND class_code = modu_rec_product.class_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c3_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND part_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND class_code = modu_rec_product.class_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c3_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND part_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND class_code = modu_rec_product.class_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c4_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND part_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND class_code = modu_rec_product.class_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c4_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 
	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND prodgrp_code = modu_rec_product.prodgrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c5_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND prodgrp_code = modu_rec_product.prodgrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c5_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND class_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND prodgrp_code = modu_rec_product.prodgrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c6_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND class_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND prodgrp_code = modu_rec_product.prodgrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c6_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code = p_ware_code 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND maingrp_code = modu_rec_product.maingrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c7_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code = p_ware_code 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND maingrp_code = modu_rec_product.maingrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c7_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 
	#
	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND cmpy_code = p_cmpy 
	AND ware_code IS NULL 
	AND class_code IS NULL 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND maingrp_code = modu_rec_product.maingrp_code 
	IF STATUS != NOTFOUND THEN 
		DECLARE c8_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND cmpy_code = p_cmpy 
		AND ware_code IS NULL 
		AND class_code IS NULL 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND maingrp_code = modu_rec_product.maingrp_code 
		ORDER BY start_date desc, offer_code 

		FOREACH c8_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND part_code IS NULL 
	AND prodgrp_code IS NULL 
	AND maingrp_code IS NULL 
	AND class_code IS NULL 
	AND ware_code = p_ware_code 
	AND cmpy_code = p_cmpy 
	IF STATUS != NOTFOUND THEN 
		DECLARE c9_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND part_code IS NULL 
		AND prodgrp_code IS NULL 
		AND maingrp_code IS NULL 
		AND class_code IS NULL 
		AND ware_code = p_ware_code 
		AND cmpy_code = p_cmpy 
		ORDER BY start_date desc, offer_code 

		FOREACH c9_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 

	SELECT UNIQUE 1 FROM pricing 
	WHERE start_date <= p_order_date 
	AND type_ind = p_type_ind 
	AND (end_date IS NULL OR end_date >= p_order_date) 
	AND part_code IS NULL 
	AND prodgrp_code IS NULL 
	AND maingrp_code IS NULL 
	AND ware_code IS NULL 
	AND class_code IS NULL 
	AND cmpy_code = p_cmpy 
	IF STATUS != NOTFOUND THEN 
		DECLARE c10_exclude CURSOR FOR 
		SELECT * FROM pricing 
		WHERE start_date <= p_order_date 
		AND type_ind = p_type_ind 
		AND (end_date IS NULL OR end_date >= p_order_date) 
		AND part_code IS NULL 
		AND prodgrp_code IS NULL 
		AND maingrp_code IS NULL 
		AND ware_code IS NULL 
		AND class_code IS NULL 
		AND cmpy_code = p_cmpy 
		ORDER BY start_date desc, offer_code 

		FOREACH c10_exclude INTO modu_rec_pricing.* 
			IF modu_rec_pricing.type_ind = "5" THEN 
				SELECT UNIQUE 1 FROM custoffer 
				WHERE cust_code = p_cust_code 
				AND offer_code = modu_rec_pricing.offer_code 
				AND effective_date <= p_order_date 
				AND cmpy_code = p_cmpy 
				IF STATUS <> NOTFOUND THEN 
					RETURN TRUE 
				END IF 
			ELSE 
				RETURN TRUE 
			END IF 
		END FOREACH 

	END IF 
	RETURN FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION prod_exclude(p_cmpy,p_part_code,p_cust_code,p_ware_code,p_type_ind,p_order_date)
###########################################################################