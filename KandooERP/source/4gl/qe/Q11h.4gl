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
# \brief module Q11h - Updates Database with new OR Amended Sales Order
#
#                 - N.B. Insert CURSOR's have been used FOR efficiency
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../qe/Q_QE_GLOBALS.4gl"
GLOBALS "../qe/Q1_GROUP_GLOBALS.4gl" 
GLOBALS "../qe/Q11_GLOBALS.4gl" 

DEFINE 
err_message CHAR(40) 

FUNCTION insert_order() 
	DEFINE 
	pt_quotehead RECORD LIKE quotehead.* 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET pt_quotehead.* = pr_quotehead.* 
		SELECT area_code INTO pt_quotehead.area_code 
		FROM territory 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND terr_code = pr_quotehead.territory_code 
		LET pt_quotehead.quote_ind = "2" 
		LET pt_quotehead.goods_amt = 0 
		LET pt_quotehead.hand_amt = 0 
		LET pt_quotehead.hand_tax_amt = 0 
		LET pt_quotehead.freight_amt = 0 
		LET pt_quotehead.freight_tax_amt = 0 
		LET pt_quotehead.tax_amt = 0 
		LET pt_quotehead.disc_amt = 0 
		LET pt_quotehead.total_amt = 0 
		LET pt_quotehead.cost_amt = 0 
		LET pt_quotehead.line_num = 0 
		LET pt_quotehead.status_ind = "I" 
		LET err_message = "Q11 - OE Params Lock" 
		DECLARE c_opparms CURSOR FOR 
		SELECT next_ord_num FROM opparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
		FOR UPDATE 
		OPEN c_opparms 
		FETCH c_opparms INTO pt_quotehead.order_num 
		LET err_message = " Q11 - Adding Order Header Row" 
		INSERT INTO quotehead VALUES (pt_quotehead.*) 
		LET err_message = "Q11 - Update Next Order Number" 
		UPDATE opparms 
		SET next_ord_num = next_ord_num + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_num = "1" 
	COMMIT WORK 
	WHENEVER ERROR CONTINUE 
	LET pr_quotehead.order_num = pt_quotehead.order_num 
	LET pr_quotehead.quote_ind = pt_quotehead.quote_ind 
	LET pr_quotehead.area_code = pt_quotehead.area_code 
	RETURN true 
END FUNCTION 


FUNCTION write_order(pr_cancel) 
	DEFINE 
	ps_quotehead RECORD LIKE quotehead.*, 
	pt_quotehead RECORD LIKE quotehead.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pt_quotedetl RECORD LIKE quotedetl.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_customertype RECORD LIKE customertype.*, 
	pr_araudit RECORD LIKE araudit.*, 
	pr_orderoffer RECORD LIKE orderoffer.*, 
	pr_cancel SMALLINT 

	GOTO bypass 
	LABEL recovery: 
	LET pr_quotehead.* = ps_quotehead.* 
	IF error_recover(err_message,status) != "Y" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET ps_quotehead.* = pr_quotehead.* 
		IF pr_cancel THEN 
			LET err_message = "Q1A - Locking Quote Line Detail Records" 
			DECLARE c2_quotedetl CURSOR FOR 
			SELECT * FROM quotedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND order_num = pr_quotehead.order_num 
			FOR UPDATE 
			DELETE FROM t_quotedetl 
			WHERE 1=1 
			FOREACH c2_quotedetl INTO pr_quotedetl.* 
				IF pr_quotedetl.reserved_qty > 0 THEN 
					UPDATE prodstatus 
					SET reserved_qty = reserved_qty - pr_quotedetl.reserved_qty 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND ware_code = pr_quotedetl.ware_code 
					AND part_code = pr_quotedetl.part_code 
					AND stocked_flag = "Y" 
				END IF 
				LET pr_quotedetl.reserved_qty = 0 
				LET pr_quotedetl.sold_qty = 0 
				LET pr_quotedetl.order_qty = 0 
				LET pr_quotedetl.status_ind = "D" 
				INSERT INTO t_quotedetl VALUES (pr_quotedetl.*) 
			END FOREACH 
			LET pr_quotehead.goods_amt = 0 
			LET pr_quotehead.tax_amt = 0 
			LET pr_quotehead.disc_amt = 0 
			LET pr_quotehead.total_amt = 0 
			LET pr_quotehead.freight_amt = 0 
			LET pr_quotehead.freight_tax_amt = 0 
			LET pr_quotehead.hand_amt = 0 
			LET pr_quotehead.hand_tax_amt = 0 
			LET pr_quotehead.hold_code = NULL 
		END IF 
		INITIALIZE pr_quotedetl.* TO NULL 
		## Declare Insert Cursor's
		## Quotedetl
		DECLARE c_quotedetl CURSOR FOR 
		INSERT INTO quotedetl VALUES (pr_quotedetl.*) 
		OPEN c_quotedetl 
		## Orderoffer
		DECLARE c_orderoffer CURSOR FOR 
		INSERT INTO orderoffer VALUES (pr_orderoffer.*) 
		OPEN c_orderoffer 
		##
		LET err_message = "Q11 - Locking Order Header Record" 
		DECLARE c_quotehead CURSOR FOR 
		SELECT * FROM quotehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_quotehead.order_num 
		FOR UPDATE 
		OPEN c_quotehead 
		FETCH c_quotehead INTO pt_quotehead.* 
		IF pt_quotehead.rev_num != pr_quotehead.rev_num THEN 
			LET err_message = "Q11 - Sales Order has changed during Edit" 
			GOTO recovery 
		END IF 
		LET err_message = "Q11 - Removing Existing Order Line Items" 
		DELETE FROM t3_quotedetl 
		WHERE 1=1 
		DECLARE c1_quotedetl CURSOR FOR 
		SELECT * FROM quotedetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = pr_quotehead.cust_code 
		AND order_num = pr_quotehead.order_num 
		FOR UPDATE 
		FOREACH c1_quotedetl INTO pr_quotedetl.* 
			INSERT INTO t3_quotedetl VALUES (pr_quotedetl.*) 
			IF pr_quotedetl.reserved_qty > 0 
			AND NOT pr_cancel THEN 
				UPDATE prodstatus 
				SET reserved_qty = reserved_qty - pr_quotedetl.reserved_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_quotedetl.ware_code 
				AND part_code = pr_quotedetl.part_code 
				AND stocked_flag = "Y" 
			END IF 
			DELETE FROM quotedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_quotehead.cust_code 
			AND order_num = pr_quotehead.order_num 
			AND line_num = pr_quotedetl.line_num 
		END FOREACH 
		LET pr_quotehead.line_num = 0 
		DECLARE c_t_quotedetl CURSOR FOR 
		SELECT * FROM t_quotedetl 
		ORDER BY line_num 
		FOREACH c_t_quotedetl INTO pr_quotedetl.* 
			LET pr_quotehead.line_num = pr_quotehead.line_num + 1 
			LET pr_quotedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_quotedetl.cust_code = pr_quotehead.cust_code 
			LET pr_quotedetl.order_num = pr_quotehead.order_num 
			LET pr_quotedetl.line_num = pr_quotehead.line_num 
			IF pr_quotedetl.ext_tax_amt IS NULL THEN 
				LET pr_quotedetl.ext_tax_amt = 0 
			END IF 
			IF pr_quotedetl.ext_price_amt IS NULL THEN 
				LET pr_quotedetl.ext_price_amt = 0 
			END IF 
			IF pr_quotedetl.ext_cost_amt IS NULL THEN 
				LET pr_quotedetl.ext_cost_amt = 0 
			END IF 
			LET pr_quotedetl.job_code = NULL 
			LET pr_quotedetl.acct_code = 
			build_mask(glob_rec_kandoouser.cmpy_code,pr_quotehead.acct_override_code, 
			pr_quotedetl.acct_code ) 
			IF pr_quotedetl.reserved_qty > 0 
			AND NOT pr_cancel THEN 
				UPDATE prodstatus 
				SET reserved_qty = reserved_qty + pr_quotedetl.reserved_qty 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND ware_code = pr_quotedetl.ware_code 
				AND part_code = pr_quotedetl.part_code 
				AND stocked_flag = "Y" 
			END IF 
			LET err_message = "Q11 - Order Line Item Insert" 
			INITIALIZE pt_quotedetl.* TO NULL 
			PUT c_quotedetl 
		END FOREACH 
		CLOSE c_quotedetl 
		LET pr_quotehead.rev_num = pr_quotehead.rev_num + 1 
		LET pr_quotehead.rev_date = today 
		LET pr_quotehead.cost_ind = pr_arparms.costings_ind 
		LET err_message = "Q11 - Update Sales Order Header Record" 
		IF pr_quotehead.line_num = 0 THEN 
			## No lines exist THEN ORDER IS cancelled
			LET pr_quotehead.status_ind = "C" 
		ELSE 
			## No lines shipped THEN ORDER IS unshipped
			LET pr_quotehead.status_ind = "U" 
		END IF 
		IF pr_cancel THEN 
			LET pr_quotehead.status_ind = "D" 
		END IF 
		IF pr_quotehead.sales_code IS NULL THEN 
			LET pr_quotehead.sales_code = pr_customer.sale_code 
		END IF 
		IF pr_quotehead.territory_code IS NULL THEN 
			LET pr_quotehead.territory_code = pr_customer.territory_code 
		END IF 
		IF pr_quotehead.delivery_ind IS NULL THEN 
			LET pr_quotehead.delivery_ind = "1" 
		END IF 
		UPDATE quotehead 
		SET * = pr_quotehead.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_quotehead.order_num 
		IF pt_quotehead.status_ind = "I" THEN 
			LET pt_quotehead.cond_code = pr_customer.cond_code 
			LET pt_quotehead.sales_code = pr_customer.sale_code 
			LET pt_quotehead.territory_code = pr_customer.territory_code 
		END IF 
		LET err_message = "Q11 - Delete Order Offer Rows" 
		DELETE FROM orderoffer 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = pr_quotehead.order_num 
		LET err_message = "Q11 - Insert Order Offer Rows" 
		DECLARE c_orderpart CURSOR FOR 
		SELECT "", 
		"", 
		offer_code, 
		disc_ind, 
		offer_qty, 
		disc_per, 
		bonus_amt 
		FROM t_orderpart 
		WHERE offer_qty > 0 AND offer_code != "###" 
		FOREACH c_orderpart INTO pr_orderoffer.* 
			LET pr_orderoffer.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET pr_orderoffer.order_num = pr_quotehead.order_num 
			IF pr_orderoffer.disc_per IS NULL THEN 
				LET pr_orderoffer.disc_per = 0 
			END IF 
			IF pr_orderoffer.bonus_amt IS NULL THEN 
				LET pr_orderoffer.bonus_amt = 0 
			END IF 
			SELECT sum(order_qty*list_price_amt), 
			sum(sold_qty* unit_price_amt) 
			INTO pr_orderoffer.gross_amt, 
			pr_orderoffer.net_amt 
			FROM t_quotedetl 
			WHERE offer_code = pr_orderoffer.offer_code 
			PUT c_orderoffer 
		END FOREACH 
		CLOSE c_orderoffer 
	COMMIT WORK 
	WHENEVER ERROR stop 
	RETURN pr_quotehead.order_num 
END FUNCTION 
