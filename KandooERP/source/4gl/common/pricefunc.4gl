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

	Source code beautified by beautify.pl on 2020-01-02 10:35:28	$Id: $
}



#
# Name   : pricefunc
# Description : Calculates price.
# Pre    : pr_price_flag - the indication of the pricing level TO be updated
#        : pr_prodstatus - the prodstatus record
#        : pr_cat_code   - the category code
#        : pr_tariff_code - the product tariff code
#        : pr_duty_per_default - the tariff default duty
#        : pr_exchange_date - the exchange date
# Post   : The price amount IS returned.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
--	DEFINE pr_glparms RECORD LIKE glparms.* 
END GLOBALS 

FUNCTION calculate_price(p_price_flag,p_rec_prodstatus,p_cat_code,p_tariff_code,p_duty_per_default,p_exchange_date) 
	DEFINE p_price_flag CHAR(1) 
	DEFINE p_rec_prodstatus RECORD LIKE prodstatus.* 
	DEFINE p_cat_code LIKE category.cat_code 
	DEFINE p_tariff_code LIKE product.tariff_code
	DEFINE p_duty_per_default LIKE tariff.duty_per
	DEFINE p_exchange_date DATE

	DEFINE l_rec_category RECORD LIKE category.* 
	DEFINE l_prod_src_ind LIKE category.price9_ind 
	DEFINE l_cat_src_ind LIKE category.price9_ind 
	DEFINE l_src_ind LIKE category.price9_ind 
	DEFINE l_prod_src_per LIKE prodstatus.price9_per 
	DEFINE l_cat_src_per LIKE prodstatus.price9_per 
	DEFINE l_src_per LIKE prodstatus.price9_per 
	DEFINE l_oth_cost_per LIKE category.oth_cost_fact_per 
	DEFINE l_duty LIKE prodstatus.wgted_cost_amt 
	DEFINE l_duty_rate LIKE tariff.duty_per 
	DEFINE l_std_cost LIKE prodstatus.list_amt 
	DEFINE l_cost_fact_amt LIKE prodstatus.list_amt 
	DEFINE l_conv_rate LIKE rate_exchange.conv_sell_qty 
	DEFINE l_rec_glparms RECORD LIKE glparms.*
	DEFINE r_price_amt LIKE prodstatus.list_amt

	SELECT * INTO l_rec_category.* 
	FROM category 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cat_code = p_cat_code 

	CASE p_price_flag 
		WHEN 'L' 
			LET l_prod_src_ind = p_rec_prodstatus.pricel_ind 
			LET l_prod_src_per = p_rec_prodstatus.pricel_per 
			LET l_cat_src_ind = l_rec_category.cost_list_ind 
			LET l_cat_src_per = l_rec_category.std_cost_mrkup_per 
		WHEN '1' 
			LET l_prod_src_ind = p_rec_prodstatus.price1_ind 
			LET l_prod_src_per = p_rec_prodstatus.price1_per 
			LET l_cat_src_ind = l_rec_category.price1_ind 
			LET l_cat_src_per = l_rec_category.price1_per 
		WHEN '2' 
			LET l_prod_src_ind = p_rec_prodstatus.price2_ind 
			LET l_prod_src_per = p_rec_prodstatus.price2_per 
			LET l_cat_src_ind = l_rec_category.price2_ind 
			LET l_cat_src_per = l_rec_category.price2_per 
		WHEN '3' 
			LET l_prod_src_ind = p_rec_prodstatus.price3_ind 
			LET l_prod_src_per = p_rec_prodstatus.price3_per 
			LET l_cat_src_ind = l_rec_category.price3_ind 
			LET l_cat_src_per = l_rec_category.price3_per 
		WHEN '4' 
			LET l_prod_src_ind = p_rec_prodstatus.price4_ind 
			LET l_prod_src_per = p_rec_prodstatus.price4_per 
			LET l_cat_src_ind = l_rec_category.price4_ind 
			LET l_cat_src_per = l_rec_category.price4_per 
		WHEN '5' 
			LET l_prod_src_ind = p_rec_prodstatus.price5_ind 
			LET l_prod_src_per = p_rec_prodstatus.price5_per 
			LET l_cat_src_ind = l_rec_category.price5_ind 
			LET l_cat_src_per = l_rec_category.price5_per 
		WHEN '6' 
			LET l_prod_src_ind = p_rec_prodstatus.price6_ind 
			LET l_prod_src_per = p_rec_prodstatus.price6_per 
			LET l_cat_src_ind = l_rec_category.price6_ind 
			LET l_cat_src_per = l_rec_category.price6_per 
		WHEN '7' 
			LET l_prod_src_ind = p_rec_prodstatus.price7_ind 
			LET l_prod_src_per = p_rec_prodstatus.price7_per 
			LET l_cat_src_ind = l_rec_category.price7_ind 
			LET l_cat_src_per = l_rec_category.price7_per 
		WHEN '8' 
			LET l_prod_src_ind = p_rec_prodstatus.price8_ind 
			LET l_prod_src_per = p_rec_prodstatus.price8_per 
			LET l_cat_src_ind = l_rec_category.price8_ind 
			LET l_cat_src_per = l_rec_category.price8_per 
		WHEN '9' 
			LET l_prod_src_ind = p_rec_prodstatus.price9_ind 
			LET l_prod_src_per = p_rec_prodstatus.price9_per 
			LET l_cat_src_ind = l_rec_category.price9_ind 
			LET l_cat_src_per = l_rec_category.price9_per 
	END CASE 
	IF l_prod_src_ind IS NOT NULL THEN 
		LET l_src_ind = l_prod_src_ind 
		LET l_src_per = l_prod_src_per 
	ELSE 
		IF l_cat_src_ind IS NOT NULL THEN 
			LET l_src_ind = l_cat_src_ind 
			LET l_src_per = l_cat_src_per 
		ELSE 
			##
			## Manually maintained price
			##
			CASE p_price_flag 
				WHEN 'L' 
					RETURN p_rec_prodstatus.list_amt 
				WHEN '1' 
					RETURN p_rec_prodstatus.price1_amt 
				WHEN '2' 
					RETURN p_rec_prodstatus.price2_amt 
				WHEN '3' 
					RETURN p_rec_prodstatus.price3_amt 
				WHEN '4' 
					RETURN p_rec_prodstatus.price4_amt 
				WHEN '5' 
					RETURN p_rec_prodstatus.price5_amt 
				WHEN '6' 
					RETURN p_rec_prodstatus.price6_amt 
				WHEN '7' 
					RETURN p_rec_prodstatus.price7_amt 
				WHEN '8' 
					RETURN p_rec_prodstatus.price8_amt 
				WHEN '9' 
					RETURN p_rec_prodstatus.price9_amt 
			END CASE 
		END IF 
	END IF 
	LET l_oth_cost_per = l_rec_category.oth_cost_fact_per 
	CASE l_src_ind 
		WHEN 'L' 
			LET r_price_amt = p_rec_prodstatus.list_amt 
			LET l_oth_cost_per = 0 
		WHEN 'S' 
			LET r_price_amt = p_rec_prodstatus.est_cost_amt 
		WHEN 'W' 
			LET r_price_amt = p_rec_prodstatus.wgted_cost_amt 
		WHEN 'A' 
			LET r_price_amt = p_rec_prodstatus.act_cost_amt 
		WHEN 'F' 
			LET r_price_amt = p_rec_prodstatus.for_cost_amt 
	END CASE 
	#
	# The cost_fact_per will now be included in the calculation FOR
	# all cost-based amounts.
	#
	LET l_cost_fact_amt = r_price_amt * ( l_oth_cost_per / 100 ) 
	#
	# Get exchange rate AND calculate duty FOR prices based on
	# free-on-board cost
	#
	IF p_exchange_date IS NULL THEN 
		LET p_exchange_date = TODAY 
	END IF 

	IF l_src_ind = 'F' THEN 
		LET l_conv_rate = get_conv_rate( 
			glob_rec_kandoouser.cmpy_code, 
			p_rec_prodstatus.for_curr_code, 
			p_exchange_date, 
			CASH_EXCHANGE_SELL )
		 
		IF p_duty_per_default IS NULL THEN 
			LET p_duty_per_default = 0 
		END IF 

		IF p_rec_prodstatus.for_curr_code = l_rec_glparms.base_currency_code THEN 
			LET l_conv_rate = 1 
			LET l_duty_rate = 0 
		ELSE 
			IF p_tariff_code IS NULL THEN 
				LET l_duty_rate = p_duty_per_default 
			ELSE 
				SELECT duty_per INTO l_duty_rate 
				FROM tariff 
				WHERE tariff_code = p_tariff_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF STATUS = NOTFOUND THEN 
					LET l_duty_rate = p_duty_per_default 
				END IF 
			END IF 
		END IF 
		LET l_duty = r_price_amt * ( l_duty_rate / 100 ) 
	END IF 
	CASE l_src_ind 
		WHEN 'L' 
			LET r_price_amt = r_price_amt * ( l_src_per / 100 ) 
		WHEN 'F' 
			LET l_std_cost = 
			( l_duty + l_cost_fact_amt + r_price_amt ) / l_conv_rate 
			LET r_price_amt = l_std_cost + 
			( l_std_cost * ( l_src_per / 100 ) ) 
		OTHERWISE 
			LET l_std_cost = r_price_amt + l_cost_fact_amt 
			LET r_price_amt = l_std_cost + 
			( l_std_cost * ( l_src_per / 100 ) ) 
	END CASE 
	# Round the price as setup in IZ1 - Product Category Maintenance
	LET r_price_amt = roundit(r_price_amt,l_rec_category.rounding_factor, 
	l_rec_category.rounding_ind) 

	RETURN r_price_amt 
END FUNCTION 


