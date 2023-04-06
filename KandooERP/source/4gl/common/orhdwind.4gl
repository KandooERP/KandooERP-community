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
# Requires
# common/orhdwind.4gl
# common/orddfunc.4gl
###########################################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION disc_amtp_head(p_cmpy,p_cust,p_ord_num)
#
# disc_amtp_head() displays ORDER header details with the option
# TO view ORDER line details
############################################################
FUNCTION disc_amtp_head(p_cmpy,p_cust,p_ord_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust LIKE customer.cust_code 
	DEFINE p_ord_num LIKE orderhead.order_num 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_arparms 
		RECORD 
			inv_ref1_text LIKE arparms.inv_ref1_text 
		END RECORD 
	DEFINE l_temp_text CHAR(32) 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_func_type CHAR(14) 
	DEFINE l_ans CHAR(1) 

	SELECT inv_ref1_text INTO l_rec_arparms.inv_ref1_text FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	LET l_temp_text = l_rec_arparms.inv_ref1_text clipped, "................" 
	LET l_ref_text = l_temp_text 

	SELECT orderhead.* INTO l_rec_orderhead.* FROM orderhead 
	WHERE cmpy_code = p_cmpy 
	AND order_num = p_ord_num 
	IF status = notfound THEN 
		ERROR kandoomsg2("U",7001,"Order")	#7001 Logic Error: Order NOT found
		SLEEP 2
		RETURN 
	END IF 

	SELECT customer.* INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = l_rec_orderhead.cust_code 
	IF status = notfound THEN 
		ERROR kandoomsg2("A",9067,l_rec_orderhead.cust_code) 
		SLEEP 2
		RETURN 
	END IF 

	OPEN WINDOW E400 with FORM "E400" 
	CALL windecoration_e("E400") 

	DISPLAY l_ref_text TO inv_ref1_text 
	
	DISPLAY BY NAME 
		l_rec_orderhead.cust_code, 
		l_rec_customer.name_text, 
		l_rec_orderhead.order_num, 
		l_rec_orderhead.goods_amt, 
		l_rec_orderhead.hand_amt, 
		l_rec_orderhead.freight_amt, 
		l_rec_orderhead.tax_amt, 
		l_rec_orderhead.total_amt, 
		l_rec_orderhead.disc_amt, 
		l_rec_orderhead.currency_code,
		l_rec_orderhead.entry_code, 
		l_rec_orderhead.entry_date, 
		l_rec_orderhead.ord_text, 
		l_rec_orderhead.ship_date, 
		l_rec_orderhead.cost_amt, 
		l_rec_orderhead.last_inv_num, 
		l_rec_orderhead.status_ind, 
		l_rec_orderhead.com1_text, 
		l_rec_orderhead.rev_date, 
		l_rec_orderhead.com2_text, 
		l_rec_orderhead.rev_num 

	MENU
		BEFORE MENU 
			CALL publish_toolbar("kandoo","orhdwind","menu-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
							
		ON ACTION "DETAIL"
			LET l_func_type = "View Order" 
			CALL lordshow(
				p_cmpy, 
				l_rec_orderhead.cust_code, 
				l_rec_orderhead.order_num,	
				l_func_type) 

		ON ACTION "CANCEL"
			EXIT MENU	
	END MENU
--	IF kandoomsg("A",8010,"") = "Y" THEN #8010 "View line details (y/n) "
--		LET l_func_type = "View Order" 
--		CALL lordshow(p_cmpy, l_rec_orderhead.cust_code, l_rec_orderhead.order_num,	l_func_type) 
--	END IF
	 
	CLOSE WINDOW E400
	 
	LET int_flag = 0 
	LET quit_flag = 0 

END FUNCTION 
############################################################
# END FUNCTION disc_amtp_head(p_cmpy,p_cust,p_ord_num)
############################################################