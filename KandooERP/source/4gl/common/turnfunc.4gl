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

	Source code beautified by beautify.pl on 2020-01-02 10:35:38	$Id: $
}



#
#  This FUNCTION Calculates Stockturn Ratios & Reorder Information
#
#  Definition of Parameters
#  - p_prod        : product code TO which calculations apply
#  - p_start_ware     : first warehouse in range which calculation apply
#  - p_end_ware       : last warehouse in range which calculation apply
#  - p_start_date     : start date of analysis period
#  - p_end_date       : END date of analysis period
#  - p_reorder_flag   : calculate reorder point & qty (Y)Yes OR (N)No
#  - p_days_lead      : product.days_lead. Saves a SELECT on product table
#  - p_tran_type_text : This string contains the prodledger transaction
#                      types that are TO be used WHEN selecting sales
#                      transactions
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION calc_turn(p_cmpy,p_prod,p_start_ware,p_end_ware,p_start_date,p_end_date,p_reorder_flag,p_days_lead,p_tran_type_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_prod LIKE prodstatus.part_code 
	DEFINE p_start_ware LIKE prodstatus.ware_code
	DEFINE p_end_ware LIKE prodstatus.ware_code 
	DEFINE p_start_date DATE
	DEFINE p_end_date DATE 
	DEFINE p_reorder_flag CHAR(1) 
	DEFINE p_days_lead LIKE product.days_lead_num 
	DEFINE p_tran_type_text CHAR(120) 
	DEFINE l_rec_calc_turn RECORD 
		stk_turn_qty FLOAT, 
		stk_cost_amt DECIMAL(16,4), 
		stk_sales_amt DECIMAL(16,4), 
		avg_stk_amt DECIMAL(16,4), 
		reorder_point_qty LIKE prodstatus.reorder_point_qty, 
		reorder_qty LIKE prodstatus.reorder_qty 
	END RECORD 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_rec_pr_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_pl_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_sum_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_ord_qty1 LIKE prodledg.tran_qty 
	DEFINE l_ord_qty2 DECIMAL(14,4) 
	DEFINE l_trans_exist SMALLINT 
	DEFINE l_mths SMALLINT 
	DEFINE l_yrs SMALLINT
	DEFINE l_no_of_months SMALLINT
	DEFINE l_no_days INTEGER
	DEFINE l_total_days INTEGER 
	DEFINE l_yr_tran_qty LIKE prodledg.tran_qty 
	DEFINE l_avg_cost LIKE prodledg.cost_amt 
	DEFINE l_stock_val DECIMAL(16,4) 
	DEFINE x DECIMAL(14,4)

	LET l_stock_val = 0 
	LET l_rec_calc_turn.avg_stk_amt = 0 
	LET l_rec_calc_turn.stk_cost_amt = 0 
	LET l_rec_calc_turn.stk_sales_amt = 0 
	LET l_sum_tran_qty = 0 
	# FOR each of the warehouses
	DECLARE c_warehouse CURSOR FOR 
	SELECT * 
	INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code >= p_start_ware 
	AND ware_code <= p_end_ware 
	FOREACH c_warehouse 
		### Calculate the Opening Stock AT start date
		LET l_trans_exist = false 
		DECLARE c1_prodledg CURSOR FOR 
		SELECT prodledg.* 
		FROM prodledg 
		WHERE cmpy_code = p_cmpy 
		AND ware_code = l_rec_warehouse.ware_code 
		AND part_code = p_prod 
		AND tran_date < p_start_date 
		ORDER BY tran_date desc, 
		seq_num desc 
		OPEN c1_prodledg 
		FETCH c1_prodledg INTO l_rec_pl_prodledg.* 
		IF status = notfound THEN 
			LET l_rec_pl_prodledg.bal_amt = 0 
			LET l_rec_pl_prodledg.cost_amt = 0 
		END IF 
		CLOSE c1_prodledg 
		LET l_rec_pl_prodledg.tran_date = p_start_date 
		#####
		#####    Calculate the Value of the Stock On Hand
		#####
		DECLARE c2_prodledg CURSOR FOR 
		SELECT * 
		FROM prodledg 
		WHERE cmpy_code = p_cmpy 
		AND part_code = p_prod 
		AND ware_code = l_rec_warehouse.ware_code 
		AND tran_date >= p_start_date 
		AND tran_date <= p_end_date 
		ORDER BY tran_date, 
		seq_num 
		FOREACH c2_prodledg INTO l_rec_pr_prodledg.* 
			LET l_trans_exist = true 
			LET l_no_days = l_rec_pr_prodledg.tran_date - l_rec_pl_prodledg.tran_date 
			IF l_rec_pr_prodledg.bal_amt < 0 THEN 
				LET l_rec_pr_prodledg.bal_amt = 0 
			END IF 
			LET l_stock_val = l_stock_val + (l_rec_pl_prodledg.bal_amt * 
			l_rec_pl_prodledg.cost_amt * 
			l_no_days) 
			LET l_rec_pl_prodledg.* = l_rec_pr_prodledg.* 
		END FOREACH 
		IF NOT l_trans_exist THEN 
			CONTINUE FOREACH 
		END IF 
		LET l_no_days = p_end_date - l_rec_pl_prodledg.tran_date 
		LET l_stock_val = l_stock_val + (l_rec_pl_prodledg.bal_amt * 
		l_rec_pl_prodledg.cost_amt * 
		l_no_days) 
		#####
		##### Calculate Value of Cost Of Goods Sold (COGS)
		LET l_query_text = 
		"SELECT * ", 
		"FROM prodledg ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND part_code = \"",p_prod,"\" ", 
		"AND ware_code = \"",l_rec_warehouse.ware_code,"\" ", 
		"AND ",p_tran_type_text CLIPPED," ", 
		"AND tran_date <= \"",p_end_date,"\" ", 
		"AND tran_date >= \"",p_start_date,"\" " 
		PREPARE s_prodledg FROM l_query_text 
		DECLARE c3_prodledg CURSOR FOR s_prodledg 
		FOREACH c3_prodledg INTO l_rec_pr_prodledg.* 
			LET l_rec_calc_turn.stk_cost_amt = 
			l_rec_calc_turn.stk_cost_amt 
			+ (l_rec_pr_prodledg.tran_qty * l_rec_pr_prodledg.cost_amt) * -1 
			LET l_rec_calc_turn.stk_sales_amt = 
			l_rec_calc_turn.stk_sales_amt 
			+ (l_rec_pr_prodledg.tran_qty * l_rec_pr_prodledg.sales_amt * -1) 
			LET l_sum_tran_qty = l_sum_tran_qty + (l_rec_pr_prodledg.tran_qty * -1) 
		END FOREACH 
	END FOREACH 
	###
	### Calculates Re Order Values IF Required
	IF p_reorder_flag = "Y" THEN 
		### Calculate l_ord_qty1
		LET l_mths = MONTH(p_end_date - p_start_date) 
		LET l_yrs = YEAR(p_end_date - p_start_date) 
		LET l_no_of_months = l_mths + (l_yrs * 12) 
		IF l_no_of_months = 0 THEN 
			LET l_no_of_months = 1 
		END IF 
		LET l_ord_qty1 = l_sum_tran_qty / l_no_of_months 
		### Calculate l_ord_qty2
		LET l_yr_tran_qty = (l_sum_tran_qty * 12) / l_no_of_months 
		IF l_sum_tran_qty = 0 THEN 
			LET l_avg_cost = 0 
		ELSE 
			LET l_avg_cost = l_rec_calc_turn.stk_cost_amt / l_sum_tran_qty 
		END IF 
		IF l_avg_cost = 0 THEN 
			LET x = 0 
		ELSE 
			LET x = (130 * l_yr_tran_qty) / l_avg_cost 
		END IF 
		IF x <= 0 THEN 
			LET l_ord_qty2 = 0 
		ELSE 
			LET l_ord_qty2 = sqrt_func(x,1) 
		END IF 
		IF l_ord_qty1 > l_ord_qty2 THEN 
			LET l_rec_calc_turn.reorder_qty = l_ord_qty1 
		ELSE 
			LET l_rec_calc_turn.reorder_qty = l_ord_qty2 
		END IF 
		###  Calculate Reorder Point
		LET l_rec_calc_turn.reorder_point_qty = 
		(l_yr_tran_qty * (p_days_lead / 7)) / 52 
	END IF 
	###
	###   Now Calculate the Stock Turn Qty
	LET l_total_days = p_end_date - p_start_date 
	IF l_total_days = 0 
	OR l_stock_val = 0 THEN 
		LET l_rec_calc_turn.stk_turn_qty = 0 
		LET l_rec_calc_turn.avg_stk_amt = 0 
	ELSE 
		LET l_rec_calc_turn.avg_stk_amt = l_stock_val / l_total_days 
		IF l_rec_calc_turn.avg_stk_amt = 0 THEN ## test FOR 0 important 
			LET l_rec_calc_turn.stk_turn_qty = 0 ## as rounding can give 
		ELSE ## divide BY 0 error. 
			LET l_rec_calc_turn.stk_turn_qty = l_rec_calc_turn.stk_cost_amt 
			/ (l_rec_calc_turn.avg_stk_amt 
			* (l_total_days/365)) 
		END IF 
	END IF 

	RETURN l_rec_calc_turn.* 
END FUNCTION 


