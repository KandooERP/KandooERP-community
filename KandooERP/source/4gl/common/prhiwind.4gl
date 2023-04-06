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



#  FUNCTION disp_pr_hist displays product history
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION display_product_history(p_cmpy,p_product,p_warehouse,p_year_value,p_period_value) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_product LIKE product.part_code
	DEFINE p_warehouse LIKE prodhist.ware_code
	DEFINE p_year_value LIKE prodhist.year_num
	DEFINE p_period_value LIKE prodhist.period_num
	DEFINE l_rec_prodhist RECORD LIKE prodhist.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_net_qty LIKE prodhist.sales_qty 
	DEFINE l_net_amt LIKE prodhist.sales_amt 

	SELECT * 
	INTO l_rec_prodhist.* 
	FROM prodhist 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product 
	AND ware_code = p_warehouse 
	AND year_num = p_year_value 
	AND period_num = p_period_value 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Product History") 
		#7001 Logic Error: Product History RECORD NOT found
		RETURN 
	END IF 
	SELECT * 
	INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy 
	AND part_code = p_product 
	
	SELECT * 
	INTO l_rec_warehouse.* 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = p_warehouse 
	LET l_net_qty = l_rec_prodhist.credit_qty + l_rec_prodhist.transin_qty + 
	l_rec_prodhist.pur_qty + l_rec_prodhist.adj_qty - 
	l_rec_prodhist.sales_qty - l_rec_prodhist.transout_qty 
	LET l_net_amt = l_rec_prodhist.credit_amt + l_rec_prodhist.transin_amt + 
	l_rec_prodhist.pur_amt + l_rec_prodhist.adj_amt - 
	l_rec_prodhist.sales_amt - l_rec_prodhist.transout_amt 
	OPEN WINDOW wi111 with FORM "I111" 
	CALL windecoration_i("I111") -- albo kd-758 
	DISPLAY BY NAME l_rec_prodhist.part_code, 
	l_rec_prodhist.ware_code, 
	l_rec_prodhist.year_num, 
	l_rec_prodhist.period_num, 
	l_rec_prodhist.start_qty, 
	l_rec_prodhist.end_qty, 
	l_rec_prodhist.gross_per, 
	l_rec_prodhist.stock_turn_qty, 
	l_rec_prodhist.sales_qty, 
	l_rec_prodhist.sales_amt, 
	l_rec_prodhist.credit_qty, 
	l_rec_prodhist.credit_amt, 
	l_rec_prodhist.pur_qty, 
	l_rec_prodhist.pur_amt, 
	l_rec_prodhist.transin_qty, 
	l_rec_prodhist.transin_amt, 
	l_rec_prodhist.transout_qty, 
	l_rec_prodhist.transout_amt, 
	l_rec_prodhist.adj_qty, 
	l_rec_prodhist.adj_amt 
	DISPLAY l_net_qty,l_net_amt TO net_qty,net_amt  
	DISPLAY l_rec_product.desc_text, 
	l_rec_product.desc2_text, 
	l_rec_warehouse.desc_text 
	TO product.desc_text, 
	product.desc2_text, 
	warehouse.desc_text 

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")

	CLOSE WINDOW wi111 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 


