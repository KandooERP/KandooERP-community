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
# FUNCTION ord_stat(p_cmpy,p_cust_code,p_order_num)
#
# # FUNCTION ord_stat shows the user the current ORDER STATUS by line
###########################################################################
FUNCTION ord_stat(p_cmpy,p_cust_code,p_order_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE orderhead.cust_code 
	DEFINE p_order_num LIKE orderhead.order_num 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_orderdetl RECORD LIKE orderdetl.* 
	DEFINE l_arr_rec_orderdetl DYNAMIC ARRAY OF #array[400] OF RECORD 
		RECORD 
			part_code LIKE orderdetl.part_code, 
			order_qty LIKE orderdetl.order_qty, 
			back_qty LIKE orderdetl.back_qty, 
			sched_qty LIKE orderdetl.sched_qty, 
			picked_qty LIKE orderdetl.picked_qty, 
			inv_qty LIKE orderdetl.inv_qty 
		END RECORD 
		DEFINE l_arparms RECORD LIKE arparms.* 
		DEFINE l_ref_text LIKE arparms.inv_ref1_text 
		DEFINE l_temp_text CHAR(32) 
		DEFINE l_idx SMALLINT 
		DEFINE l_msgresp LIKE language.yes_flag 

		SELECT * INTO l_arparms.* 
		FROM arparms 
		WHERE cmpy_code = p_cmpy 
		AND parm_code = "1" 
		LET l_temp_text = l_arparms.inv_ref1_text clipped, "................" 
		LET l_ref_text = l_temp_text 

		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy 
		AND cust_code = p_cust_code 
		IF status = notfound THEN 
			ERROR kandoomsg2("A",9067,p_cust_code) 		#A9067 Logic Error Customer dont exists
			RETURN 
		END IF 

		SELECT * INTO l_rec_orderhead.* 
		FROM orderhead 
		WHERE cmpy_code = p_cmpy 
		AND order_num = p_order_num 
		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"Order") 		#7001 Logic Error: Order RECORD NOT found
			RETURN 
		END IF 

		OPEN WINDOW E408 with FORM "E408" 
		CALL windecoration_e("E408") 

		MESSAGE kandoomsg2("A",1002,"") 		#A1002 Searching database - please wait
		DISPLAY l_ref_text TO inv_ref1_text attribute(white) 
		
		DISPLAY BY NAME 
			l_rec_orderhead.cust_code, 
			l_rec_customer.name_text, 
			l_rec_orderhead.order_num, 
			l_rec_orderhead.order_date, 
			l_rec_orderhead.ord_text 

		DECLARE ordcur CURSOR FOR 

		SELECT * FROM orderdetl 
		WHERE cmpy_code = p_cmpy 
		AND order_num = l_rec_orderhead.order_num 
		ORDER BY order_num,line_num 

		LET l_idx = 0 

		FOREACH ordcur INTO l_rec_orderdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_orderdetl[l_idx].part_code = l_rec_orderdetl.part_code 
			LET l_arr_rec_orderdetl[l_idx].order_qty = l_rec_orderdetl.order_qty 
			LET l_arr_rec_orderdetl[l_idx].back_qty = l_rec_orderdetl.back_qty 
			LET l_arr_rec_orderdetl[l_idx].sched_qty = l_rec_orderdetl.sched_qty 
			LET l_arr_rec_orderdetl[l_idx].picked_qty = l_rec_orderdetl.picked_qty 
			LET l_arr_rec_orderdetl[l_idx].inv_qty = l_rec_orderdetl.inv_qty 
			IF l_idx = 400 THEN 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		MESSAGE kandoomsg2("A",1008,"") 	#A1008 F3/F4 Page back & Forwards

		DISPLAY ARRAY l_arr_rec_orderdetl TO sr_orderdetl.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","orstfunc","display-arr-orderdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		CLOSE WINDOW E408 
		LET int_flag = false 
		LET quit_flag = false 

END FUNCTION 
############################################################
# END FUNCTION ord_stat(p_cmpy,p_cust_code,p_order_num)
############################################################