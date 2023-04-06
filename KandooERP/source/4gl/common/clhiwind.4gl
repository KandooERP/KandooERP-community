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

	Source code beautified by beautify.pl on 2020-01-02 10:35:08	$Id: $
}



# Program/FUNCTION - disp_cm_hist
# Purpose          - displays the customers history FOR a period
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION disp_cm_hist(p_cmpy, p_cust_code, p_hist_year, p_period_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_hist_year LIKE customerhist.year_num
	DEFINE p_period_num LIKE customerhist.period_num
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customerhist RECORD LIKE customerhist.* 

	OPEN WINDOW A115 with FORM "A115" 
	CALL windecoration_a("A115") -- albo kd-752 

	SELECT customer.* INTO l_rec_customer.* FROM customer 
	WHERE customer.cust_code = p_cust_code 
	AND customer.cmpy_code = p_cmpy 
	SELECT customerhist.* INTO l_rec_customerhist.* FROM customerhist 
	WHERE cust_code = p_cust_code 
	AND year_num = p_hist_year 
	AND period_num = p_period_num 
	AND cmpy_code = p_cmpy 
	DISPLAY BY NAME l_rec_customerhist.cust_code, 
	l_rec_customer.name_text, 
	l_rec_customerhist.year_num, 
	l_rec_customerhist.period_num, 
	l_rec_customer.currency_code, 
	l_rec_customerhist.sales_num, 
	l_rec_customerhist.sales_qty, 
	l_rec_customerhist.sale_cost_amt, 
	l_rec_customerhist.cred_qty, 
	l_rec_customerhist.cred_amt, 
	l_rec_customerhist.cred_cost_amt, 
	l_rec_customerhist.cash_qty, 
	l_rec_customerhist.cash_amt, 
	l_rec_customerhist.disc_amt, 
	l_rec_customerhist.gross_per 

	CALL eventsuspend() 
	#LET l_msgresp = kandoomsg("U",1,"")
	#1 Press Any Key TO Continue

	CLOSE WINDOW A115 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


