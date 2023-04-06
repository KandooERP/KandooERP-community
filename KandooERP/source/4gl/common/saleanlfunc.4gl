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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION sales_anly(p_type,p_add)
#
#
###########################################################################
FUNCTION sales_anly(p_type,p_add) 
	DEFINE p_type CHAR(1)
	DEFINE p_add SMALLINT
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.*
	DEFINE l_rec_salesanly RECORD LIKE salesanly.*
	# This FUNCTION assumes that the pr_customer, l_rec_invoicehead/detl
	# AND l_rec_credithead/detl are SET up ( as GLOBALS ).
	# It INSERT/updates a sales anaylsis RECORD FOR all invoice/credit lines.

	LET l_rec_salesanly.cmpy_code = glob_rec_kandoouser.cmpy_code 

	# Set up the RECORD VALUES

	IF p_type = "I" THEN # invoice 
		LET l_rec_salesanly.cust_code = l_rec_invoicehead.cust_code 
		LET l_rec_salesanly.part_code = l_rec_invoicedetl.part_code 
		LET l_rec_salesanly.ware_code = l_rec_invoicedetl.ware_code 
		LET l_rec_salesanly.year_num = l_rec_invoicehead.year_num 
		LET l_rec_salesanly.period_num = l_rec_invoicehead.period_num 
		LET l_rec_salesanly.inv_qty = l_rec_invoicedetl.ship_qty 
		LET l_rec_salesanly.cost_amt = l_rec_invoicedetl.ext_cost_amt 
		LET l_rec_salesanly.price_amt = l_rec_invoicedetl.line_total_amt 
		LET l_rec_salesanly.disc_amt = l_rec_invoicedetl.disc_amt 

		IF l_rec_invoicehead.org_cust_code IS NOT NULL THEN 
			SELECT * 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_invoicehead.org_cust_code 
			AND sales_anly_flag = "C" 
			IF status = notfound THEN 
				LET l_rec_salesanly.cust_code = l_rec_invoicehead.org_cust_code 
			END IF 
		END IF 

	ELSE # credit 

		LET l_rec_salesanly.cust_code = l_rec_credithead.cust_code 
		LET l_rec_salesanly.part_code = l_rec_creditdetl.part_code 
		LET l_rec_salesanly.ware_code = l_rec_creditdetl.ware_code 
		LET l_rec_salesanly.year_num = l_rec_credithead.year_num 
		LET l_rec_salesanly.period_num = l_rec_credithead.period_num 
		LET l_rec_salesanly.inv_qty = l_rec_creditdetl.ship_qty * -1 
		LET l_rec_salesanly.cost_amt = l_rec_creditdetl.ext_cost_amt * -1 
		LET l_rec_salesanly.price_amt = l_rec_creditdetl.line_total_amt * -1 
		LET l_rec_salesanly.disc_amt = l_rec_creditdetl.disc_amt * -1 

		IF l_rec_credithead.org_cust_code IS NOT NULL THEN 
			SELECT * 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_credithead.org_cust_code 
			AND sales_anly_flag = "C" 
			IF status = notfound THEN 
				LET l_rec_salesanly.cust_code = l_rec_credithead.org_cust_code 
			END IF 
		END IF 
	END IF 

	# Check FOR any Nulls

	IF l_rec_salesanly.inv_qty IS NULL THEN 
		LET l_rec_salesanly.inv_qty = 0 
	END IF 

	IF l_rec_salesanly.cost_amt IS NULL THEN 
		LET l_rec_salesanly.cost_amt = 0 
	END IF 

	IF l_rec_salesanly.price_amt IS NULL THEN 
		LET l_rec_salesanly.price_amt = 0 
	END IF 

	IF l_rec_salesanly.disc_amt IS NULL THEN 
		LET l_rec_salesanly.disc_amt = 0 
	END IF 

	# IF a delete THEN reverse the figures

	IF NOT p_add THEN 
		LET l_rec_salesanly.inv_qty = l_rec_salesanly.inv_qty * -1 
		LET l_rec_salesanly.cost_amt = l_rec_salesanly.cost_amt * -1 
		LET l_rec_salesanly.price_amt = l_rec_salesanly.price_amt * -1 
		LET l_rec_salesanly.disc_amt = l_rec_salesanly.disc_amt * -1 
	END IF 

	# Do the INSERT/UPDATE.

	IF l_rec_salesanly.part_code IS NULL THEN 
		LET l_rec_salesanly.part_code = " " 
	END IF 
	IF l_rec_salesanly.ware_code IS NULL THEN 
		LET l_rec_salesanly.ware_code = " " 
	END IF 

	SELECT * 
	FROM salesanly 
	WHERE glob_rec_kandoouser.cmpy_code = l_rec_salesanly.cmpy_code 
	AND cust_code = l_rec_salesanly.cust_code 
	AND part_code = l_rec_salesanly.part_code 
	AND ware_code = l_rec_salesanly.ware_code 
	AND year_num = l_rec_salesanly.year_num 
	AND period_num = l_rec_salesanly.period_num 

	IF status = notfound THEN 
		INSERT INTO salesanly VALUES (l_rec_salesanly.*) 
	ELSE 
		UPDATE salesanly 
		SET 
			inv_qty = inv_qty + l_rec_salesanly.inv_qty, 
			cost_amt = cost_amt + l_rec_salesanly.cost_amt , 
			price_amt = price_amt + l_rec_salesanly.price_amt, 
			disc_amt = disc_amt + l_rec_salesanly.disc_amt 
		WHERE glob_rec_kandoouser.cmpy_code = l_rec_salesanly.cmpy_code 
		AND cust_code = l_rec_salesanly.cust_code 
		AND part_code = l_rec_salesanly.part_code 
		AND ware_code = l_rec_salesanly.ware_code 
		AND year_num = l_rec_salesanly.year_num 
		AND period_num = l_rec_salesanly.period_num 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION sales_anly(p_type,p_add)
###########################################################################