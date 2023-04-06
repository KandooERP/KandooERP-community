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

	Source code beautified by beautify.pl on 2020-01-02 10:35:32	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - saleanalwind
# Purpose - Sale Analysis functions
#              upd_sale_trans()
#              upd_sale_hist()
#

GLOBALS "../common/glob_GLOBALS.4gl" 

#IF p_trans_ind = "I" VALUES will be added
#                = "C" VALUES will be subtracted
FUNCTION upd_sales_trans(p_cmpy,p_trans_ind,p_cust_code,p_cat_code,p_part_code,p_line_text,p_ware_code,p_sale_code,p_acct_code,p_year_num,p_period_num,p_ship_qty,p_conv_qty,p_cost_amt,p_price_amt,p_tax_amt,p_disc_amt) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_trans_ind CHAR(1) # (I)nvoice OR (C)redit
	DEFINE p_cust_code LIKE saleshist.cust_code
	DEFINE p_cat_code  LIKE saleshist.cat_code
	DEFINE p_part_code LIKE saleshist.part_code
	DEFINE p_line_text LIKE saleshist.line_text
	DEFINE p_ware_code LIKE saleshist.ware_code
	DEFINE p_sale_code LIKE saleshist.sale_code
	DEFINE p_acct_code LIKE saleshist.acct_override_code
	DEFINE p_year_num LIKE saleshist.year_num
	DEFINE p_period_num LIKE saleshist.period_num
	DEFINE p_ship_qty LIKE saleshist.ship_qty
	DEFINE p_conv_qty LIKE invoicehead.conv_qty
	DEFINE p_cost_amt LIKE saleshist.base_cost_amt
	DEFINE p_price_amt LIKE saleshist.base_price_amt
	DEFINE p_tax_amt LIKE saleshist.base_tax_amt
	DEFINE p_disc_amt LIKE saleshist.base_disc_amt
	DEFINE l_rec_salestrans RECORD LIKE salestrans.* 
	DEFINE l_corp_cust LIKE customer.corp_cust_code 
	DEFINE l_anly_flag LIKE customer.sales_anly_flag 

	INITIALIZE l_rec_salestrans.* TO NULL 

	LET l_rec_salestrans.serial_key = 0 
	LET l_rec_salestrans.cmpy_code = p_cmpy 

	SELECT type_code , 
	corp_cust_code, 
	sales_anly_flag 
	INTO l_rec_salestrans.type_code , 
	l_corp_cust, 
	l_anly_flag 
	FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF l_corp_cust IS NULL THEN 
		LET l_rec_salestrans.cust_code = p_cust_code 
	ELSE 
		IF l_anly_flag = "C" THEN 
			LET l_rec_salestrans.cust_code = l_corp_cust 
		ELSE 
			LET l_rec_salestrans.cust_code = p_cust_code 
		END IF 
	END IF 

	LET l_rec_salestrans.name_text = NULL 

	IF p_cat_code IS NOT NULL THEN 
		LET l_rec_salestrans.cat_code = p_cat_code 
	END IF 

	IF p_part_code IS NULL THEN 
		IF l_rec_salestrans.cat_code IS NULL THEN 
			LET l_rec_salestrans.cat_code = "zzz" 
		END IF 
		LET l_rec_salestrans.line_text = p_line_text 
	ELSE 
		LET l_rec_salestrans.part_code = p_part_code 
		IF l_rec_salestrans.cat_code IS NULL THEN 
			SELECT cat_code 
			INTO l_rec_salestrans.cat_code 
			FROM product 
			WHERE cmpy_code = p_cmpy 
			AND part_code = p_part_code 
		END IF 
		LET l_rec_salestrans.line_text = NULL 
	END IF 

	IF p_part_code IS NULL AND 
	p_line_text IS NULL 
	THEN 
		# kandooword required
		LET p_line_text = "No Description" 
	END IF 

	IF p_ware_code IS NULL THEN 
		SELECT ware_code 
		INTO l_rec_salestrans.ware_code 
		FROM salesperson 
		WHERE cmpy_code = p_cmpy 
		AND sale_code = p_sale_code 
	ELSE 
		LET l_rec_salestrans.ware_code = p_ware_code 
	END IF 

	LET l_rec_salestrans.sale_code = p_sale_code 

	SELECT terri_code 
	INTO l_rec_salestrans.terri_code 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = p_sale_code 

	LET l_rec_salestrans.acct_override_code = p_acct_code 
	LET l_rec_salestrans.year_num = p_year_num 
	LET l_rec_salestrans.period_num = p_period_num 

	IF p_conv_qty = 0 THEN 
		LET p_conv_qty = 1 
	END IF 

	IF p_trans_ind = "I" THEN 
		IF p_conv_qty <> 1 THEN 
			LET l_rec_salestrans.base_cost_amt = (p_cost_amt/p_conv_qty) 
			LET l_rec_salestrans.base_price_amt = (p_price_amt/p_conv_qty) 
			LET l_rec_salestrans.base_tax_amt = (p_tax_amt/p_conv_qty) 
			LET l_rec_salestrans.base_disc_amt = (p_disc_amt/p_conv_qty) 
		ELSE 
			LET l_rec_salestrans.base_cost_amt = p_cost_amt 
			LET l_rec_salestrans.base_price_amt = p_price_amt 
			LET l_rec_salestrans.base_tax_amt = p_tax_amt 
			LET l_rec_salestrans.base_disc_amt = p_disc_amt 
		END IF 

		LET l_rec_salestrans.ship_qty = p_ship_qty 
		LET l_rec_salestrans.for_cost_amt = p_cost_amt 
		LET l_rec_salestrans.for_price_amt = p_price_amt 
		LET l_rec_salestrans.for_tax_amt = p_tax_amt 
		LET l_rec_salestrans.for_disc_amt = p_disc_amt 
	ELSE 
		IF p_conv_qty <> 1 THEN 
			LET l_rec_salestrans.base_cost_amt = (0-(p_cost_amt/p_conv_qty)) 
			LET l_rec_salestrans.base_price_amt = (0-(p_price_amt/p_conv_qty)) 
			LET l_rec_salestrans.base_tax_amt = (0-(p_tax_amt/p_conv_qty)) 
			LET l_rec_salestrans.base_disc_amt = (0-(p_disc_amt/p_conv_qty)) 
		ELSE 
			LET l_rec_salestrans.base_cost_amt = (0-p_cost_amt) 
			LET l_rec_salestrans.base_price_amt = (0-p_price_amt) 
			LET l_rec_salestrans.base_tax_amt = (0-p_tax_amt) 
			LET l_rec_salestrans.base_disc_amt = (0-p_disc_amt) 
		END IF 

		LET l_rec_salestrans.ship_qty = (0-p_ship_qty) 
		LET l_rec_salestrans.for_cost_amt = (0-p_cost_amt) 
		LET l_rec_salestrans.for_price_amt = (0-p_price_amt) 
		LET l_rec_salestrans.for_tax_amt = (0-p_tax_amt) 
		LET l_rec_salestrans.for_disc_amt = (0-p_disc_amt) 
	END IF 

	#THIS CODE IN THEORY SHOULD NEVER BE EXECUTED
	IF l_rec_salestrans.type_code IS NULL THEN 
		LET l_rec_salestrans.type_code = "zzz" 
	END IF 
	IF l_rec_salestrans.cat_code IS NULL THEN 
		LET l_rec_salestrans.cat_code = "zzz" 
	END IF 
	IF l_rec_salestrans.sale_code IS NULL THEN 
		LET l_rec_salestrans.sale_code = "zzz" 
	END IF 
	IF l_rec_salestrans.terri_code IS NULL THEN 
		LET l_rec_salestrans.terri_code = "zzz" 
	END IF 

	INSERT INTO salestrans VALUES (l_rec_salestrans.*) 

END FUNCTION {upd_sales_trans} 



FUNCTION upd_sales_hist(p_cmpy,p_year_num,p_period_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_year_num LIKE saleshist.year_num 
	DEFINE p_period_num LIKE saleshist.period_num 
	DEFINE l_rec_salestrans RECORD LIKE salestrans.* 
	DEFINE l_rec_saleshist RECORD LIKE saleshist.* 

	DECLARE c_salestrans CURSOR FOR 
	SELECT * 
	INTO l_rec_salestrans.* 
	FROM salestrans 
	WHERE cmpy_code = p_cmpy 
	AND year_num = p_year_num 
	AND period_num = p_period_num 

	FOREACH c_salestrans 

		INITIALIZE l_rec_saleshist.* TO NULL 

		IF l_rec_salestrans.part_code IS NULL THEN 
			SELECT * 
			INTO l_rec_saleshist.* 
			FROM saleshist 
			WHERE cmpy_code = p_cmpy 
			AND year_num = l_rec_salestrans.year_num 
			AND period_num = l_rec_salestrans.period_num 
			AND cust_code = l_rec_salestrans.cust_code 
			AND type_code = l_rec_salestrans.type_code 
			AND cat_code = l_rec_salestrans.cat_code 
			AND ware_code = l_rec_salestrans.ware_code 
			AND line_text = l_rec_salestrans.line_text 
			AND sale_code = l_rec_salestrans.sale_code 
			AND terri_code = l_rec_salestrans.terri_code 
			AND acct_override_code = l_rec_salestrans.acct_override_code 
		ELSE 
			SELECT * 
			INTO l_rec_saleshist.* 
			FROM saleshist 
			WHERE cmpy_code = p_cmpy 
			AND year_num = l_rec_salestrans.year_num 
			AND period_num = l_rec_salestrans.period_num 
			AND cust_code = l_rec_salestrans.cust_code 
			AND type_code = l_rec_salestrans.type_code 
			AND cat_code = l_rec_salestrans.cat_code 
			AND ware_code = l_rec_salestrans.ware_code 
			AND part_code = l_rec_salestrans.part_code 
			AND sale_code = l_rec_salestrans.sale_code 
			AND terri_code = l_rec_salestrans.terri_code 
			AND acct_override_code = l_rec_salestrans.acct_override_code 
		END IF 

		IF (status=notfound) THEN 
			LET l_rec_saleshist.cmpy_code = l_rec_salestrans.cmpy_code 
			LET l_rec_saleshist.type_code = l_rec_salestrans.type_code 
			LET l_rec_saleshist.cust_code = l_rec_salestrans.cust_code 
			LET l_rec_saleshist.name_text = l_rec_salestrans.name_text 
			LET l_rec_saleshist.cat_code = l_rec_salestrans.cat_code 
			LET l_rec_saleshist.part_code = l_rec_salestrans.part_code 
			LET l_rec_saleshist.ware_code = l_rec_salestrans.ware_code 
			LET l_rec_saleshist.line_text = l_rec_salestrans.line_text 
			LET l_rec_saleshist.sale_code = l_rec_salestrans.sale_code 
			LET l_rec_saleshist.terri_code = l_rec_salestrans.terri_code 
			LET l_rec_saleshist.year_num = l_rec_salestrans.year_num 
			LET l_rec_saleshist.period_num = l_rec_salestrans.period_num 
			LET l_rec_saleshist.ship_qty = l_rec_salestrans.ship_qty 
			LET l_rec_saleshist.acct_override_code = 
			l_rec_salestrans.acct_override_code 
			LET l_rec_saleshist.base_cost_amt = l_rec_salestrans.base_cost_amt 
			LET l_rec_saleshist.base_price_amt = l_rec_salestrans.base_price_amt 
			LET l_rec_saleshist.base_tax_amt = l_rec_salestrans.base_tax_amt 
			LET l_rec_saleshist.base_disc_amt = l_rec_salestrans.base_disc_amt 
			LET l_rec_saleshist.for_cost_amt = l_rec_salestrans.for_cost_amt 
			LET l_rec_saleshist.for_price_amt = l_rec_salestrans.for_price_amt 
			LET l_rec_saleshist.for_tax_amt = l_rec_salestrans.for_tax_amt 
			LET l_rec_saleshist.for_disc_amt = l_rec_salestrans.for_disc_amt 

			INSERT INTO saleshist VALUES (l_rec_saleshist.*) 
		ELSE 
			#UPDATE existing row
			LET l_rec_saleshist.ship_qty = 
			l_rec_saleshist.ship_qty + l_rec_salestrans.ship_qty 

			LET l_rec_saleshist.base_cost_amt = 
			l_rec_saleshist.base_cost_amt + l_rec_salestrans.base_cost_amt 
			LET l_rec_saleshist.base_price_amt = 
			l_rec_saleshist.base_price_amt + l_rec_salestrans.base_price_amt 
			LET l_rec_saleshist.base_tax_amt = 
			l_rec_saleshist.base_tax_amt + l_rec_salestrans.base_tax_amt 
			LET l_rec_saleshist.base_disc_amt = 
			l_rec_saleshist.base_disc_amt + l_rec_salestrans.base_disc_amt 

			LET l_rec_saleshist.for_cost_amt = 
			l_rec_saleshist.for_cost_amt + l_rec_salestrans.for_cost_amt 
			LET l_rec_saleshist.for_price_amt = 
			l_rec_saleshist.for_price_amt + l_rec_salestrans.for_price_amt 
			LET l_rec_saleshist.for_tax_amt = 
			l_rec_saleshist.for_tax_amt + l_rec_salestrans.for_tax_amt 
			LET l_rec_saleshist.for_disc_amt = 
			l_rec_saleshist.for_disc_amt + l_rec_salestrans.for_disc_amt 

			IF l_rec_salestrans.part_code IS NULL THEN 
				UPDATE saleshist 
				SET * = l_rec_saleshist.* 
				WHERE cmpy_code = l_rec_salestrans.cmpy_code 
				AND year_num = l_rec_salestrans.year_num 
				AND period_num = l_rec_salestrans.period_num 
				AND type_code = l_rec_salestrans.type_code 
				AND cust_code = l_rec_salestrans.cust_code 
				AND cat_code = l_rec_salestrans.cat_code 
				AND ware_code = l_rec_salestrans.ware_code 
				AND line_text = l_rec_salestrans.line_text 
				AND sale_code = l_rec_salestrans.sale_code 
				AND terri_code = l_rec_salestrans.terri_code 
				AND acct_override_code = l_rec_salestrans.acct_override_code 
			ELSE 
				UPDATE saleshist 
				SET * = l_rec_saleshist.* 
				WHERE cmpy_code = l_rec_salestrans.cmpy_code 
				AND year_num = l_rec_salestrans.year_num 
				AND period_num = l_rec_salestrans.period_num 
				AND type_code = l_rec_salestrans.type_code 
				AND cust_code = l_rec_salestrans.cust_code 
				AND cat_code = l_rec_salestrans.cat_code 
				AND ware_code = l_rec_salestrans.ware_code 
				AND part_code = l_rec_salestrans.part_code 
				AND sale_code = l_rec_salestrans.sale_code 
				AND terri_code = l_rec_salestrans.terri_code 
				AND acct_override_code = l_rec_salestrans.acct_override_code 
			END IF 
		END IF 

		DELETE FROM salestrans 
		WHERE serial_key = l_rec_salestrans.serial_key 

	END FOREACH 

END FUNCTION {upd_sales_hist} 


