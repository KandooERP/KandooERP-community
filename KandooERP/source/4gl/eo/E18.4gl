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
# common\orhdwind.4gl
# common/orddfunc.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E18_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_orderhead RECORD LIKE orderhead.* 
DEFINE modu_rec_customer RECORD LIKE customer.* 
DEFINE modu_rec_t_orderhead RECORD LIKE orderhead.* 
DEFINE modu_temp_text char(32) 
DEFINE modu_ref_text LIKE arparms.inv_ref1_text 
DEFINE modu_id_flag SMALLINT
###########################################################################
# FUNCTION E18_main()
#
# E18 - "Order Scan by Date" is used to scan outstanding orders according to a 
# nominated order date. All orders, regardless of their status, will be retrieved 
# and presented from the order date that is entered.  
# This program is for inquiry purposes only - no changes or modifications may be made.
###########################################################################
FUNCTION E18_main()
	DEFINE l_ans char(1) 
 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E18") 

	LET modu_temp_text = glob_rec_arparms.inv_ref1_text clipped, "................" 
	LET modu_ref_text = modu_temp_text 

	OPEN WINDOW E403 with FORM "E403" 
	 CALL windecoration_e("E403") 

	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text


	LET l_ans = "Y" 
--	WHILE l_ans = "Y" 
		CALL E18_order_scan() 
		CLOSE WINDOW E403 
--	END WHILE 
	
END FUNCTION 
###########################################################################
# END FUNCTION E18_main()
###########################################################################


###########################################################################
# FUNCTION db_orderhead_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_orderhead_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		order_date LIKE orderhead.order_date, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind 
	END RECORD 
	DEFINE l_idx SMALLINT
	

	MESSAGE kandoomsg2("E",1186,"")	#1186 Enter Order date; OK TO continue.

	LET modu_rec_t_orderhead.order_date = today - 30 

	IF p_filter THEN
		INPUT modu_rec_t_orderhead.order_date WITHOUT DEFAULTS FROM order_date ATTRIBUTE(UNBUFFERED)
	
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","E18","input-modu_rec_t_orderhead-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END INPUT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET modu_rec_t_orderhead.order_date = today - 30 
		END IF 
	ELSE
		LET modu_rec_t_orderhead.order_date = today - 30
	END IF

	DECLARE c_cust cursor FOR 
	SELECT * INTO modu_rec_orderhead.* FROM orderhead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND order_date >= modu_rec_t_orderhead.order_date 
	ORDER BY order_date 

	LET l_idx = 0 
	FOREACH c_cust 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderhead[l_idx].order_num = modu_rec_orderhead.order_num 
		LET l_arr_rec_orderhead[l_idx].ord_text = modu_rec_orderhead.ord_text 
		LET l_arr_rec_orderhead[l_idx].last_inv_num = modu_rec_orderhead.last_inv_num 
		LET l_arr_rec_orderhead[l_idx].order_date = modu_rec_orderhead.order_date 
		LET l_arr_rec_orderhead[l_idx].cust_code = modu_rec_orderhead.cust_code 
		LET l_arr_rec_orderhead[l_idx].total_amt = modu_rec_orderhead.total_amt 
		LET l_arr_rec_orderhead[l_idx].status_ind = modu_rec_orderhead.status_ind 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 

	RETURN l_arr_rec_orderhead
END FUNCTION
###########################################################################
# FUNCTION db_orderhead_get_datasource(p_filter)
###########################################################################

###########################################################################
# FUNCTION E18_order_scan()
#
#
###########################################################################
FUNCTION E18_order_scan() 
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD --array[300] OF RECORD 
		order_date LIKE orderhead.order_date, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind 
	END RECORD 
	DEFINE l_idx SMALLINT

	CALL db_orderhead_get_datasource(FALSE) RETURNING l_arr_rec_orderhead 
	
	DISPLAY ARRAY l_arr_rec_orderhead TO sr_orderhead.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E18","input-l_arr_rec_orderhead-1") -- albo kd-502
			CALL dialog.setActionHidden("ACCEPT",TRUE) #only edit or cancel
			IF l_arr_rec_orderhead.getSize() = 0 THEN
				CALL dialog.setActionHidden("EDIT",TRUE)
			END IF
			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "REFRESH"
			 CALL windecoration_e("E403")
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_get_datasource(FALSE) RETURNING l_arr_rec_orderhead
			IF l_arr_rec_orderhead.getSize() = 0 THEN
				CALL dialog.setActionHidden("EDIT",TRUE)
			END IF

		ON ACTION "FILTER"
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_get_datasource(FALSE) RETURNING l_arr_rec_orderhead
			IF l_arr_rec_orderhead.getSize() = 0 THEN
				CALL dialog.setActionHidden("EDIT",TRUE)
			END IF
	
		BEFORE ROW  
			LET l_idx = arr_curr() 

			LET modu_rec_orderhead.order_date = l_arr_rec_orderhead[l_idx].order_date 
			LET modu_rec_orderhead.order_num = l_arr_rec_orderhead[l_idx].order_num 
			LET modu_rec_orderhead.ord_text = l_arr_rec_orderhead[l_idx].ord_text 
			LET modu_rec_orderhead.last_inv_num = l_arr_rec_orderhead[l_idx].last_inv_num 
			LET modu_rec_orderhead.order_date = l_arr_rec_orderhead[l_idx].order_date 
			LET modu_rec_orderhead.cust_code = l_arr_rec_orderhead[l_idx].cust_code 
			LET modu_rec_orderhead.total_amt = l_arr_rec_orderhead[l_idx].total_amt 
			LET modu_rec_orderhead.status_ind = l_arr_rec_orderhead[l_idx].status_ind 
			LET modu_id_flag = 0 
	
		AFTER ROW #AFTER FIELD order_date #do we really need this ?
			LET l_arr_rec_orderhead[l_idx].order_date = modu_rec_orderhead.order_date 
			IF modu_rec_orderhead.order_date = 0 THEN 
				LET l_arr_rec_orderhead[l_idx].order_date = NULL 
			END IF 

		ON ACTION ("EDIT","DOUBLECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_orderhead.getSize()) THEN
				IF (modu_rec_orderhead.order_date != 0 AND modu_rec_orderhead.order_num !=0) THEN
					CALL scanner()
				END IF 
			END IF
			 
	END DISPLAY
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION E18_order_scan()
###########################################################################


###########################################################################
# FUNCTION scanner() 
#
#
###########################################################################
FUNCTION scanner() 
	DEFINE l_dummy_money money(10,2) 
	DEFINE l_wrk_ship_amt LIKE orderhead.goods_amt  
	DEFINE l_wrk_out_amt LIKE orderhead.goods_amt  
	DEFINE l_wrk_ship_tax_amt LIKE orderhead.goods_amt  
	DEFINE l_wrk_out_tax_amt LIKE orderhead.goods_amt  
	DEFINE l_scrn_ship_amt LIKE orderhead.goods_amt 
	DEFINE l_scrn_out_amt LIKE orderhead.goods_amt 
	DEFINE l_func_type char(14) 

	OPEN WINDOW E400 with FORM "E400" 
	 CALL windecoration_e("E400") -- albo kd-755 
	DISPLAY modu_ref_text TO inv_ref1_text 

	SELECT o.*, c.* 
	INTO modu_rec_orderhead.*, modu_rec_customer.* 
	FROM orderhead o, customer c 
	WHERE o.order_num = modu_rec_orderhead.order_num 
	AND c.cust_code = modu_rec_orderhead.cust_code 
	AND o.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND c.cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF modu_rec_orderhead.tax_code = "T" THEN 

		SELECT sum(inv_qty * unit_price_amt), 
		sum(order_qty * unit_price_amt) 
		INTO l_wrk_ship_amt, l_wrk_out_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND order_num = modu_rec_orderhead.order_num 
		
		IF l_wrk_ship_amt != 0 THEN 
			CALL find_tax(modu_rec_orderhead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			l_wrk_ship_amt, 
			1, 
			"S", 
			"", 
			"") 
			RETURNING l_dummy_money, 
			l_wrk_ship_tax_amt, 
			l_dummy_money, 
			l_dummy_money, 
			modu_rec_orderhead.tax_code 
		END IF 


		IF l_wrk_out_amt != 0 THEN 
			CALL find_tax(modu_rec_orderhead.tax_code, 
			" ", 
			" ", 
			0, 
			0, 
			l_wrk_out_amt, 
			1, 
			"S", 
			"", 
			"") 
			RETURNING l_dummy_money, 
			l_wrk_out_tax_amt, 
			l_dummy_money, 
			l_dummy_money, 
			modu_rec_orderhead.tax_code 

		END IF 

		LET l_scrn_out_amt = 0 
		LET l_scrn_ship_amt = 0 

		IF l_wrk_out_amt IS NOT NULL THEN 
			IF l_wrk_out_tax_amt IS NOT NULL THEN 
				LET l_scrn_out_amt = l_wrk_out_amt + l_wrk_out_tax_amt 
			END IF 
		END IF 

		IF l_wrk_ship_amt IS NOT NULL THEN 
			IF l_wrk_ship_tax_amt IS NOT NULL THEN 
				LET l_scrn_ship_amt = l_wrk_ship_amt + l_wrk_ship_tax_amt 
			END IF 
		END IF 

	ELSE 

		SELECT sum(inv_qty * (unit_price_amt + unit_tax_amt)), 
		sum(order_qty * (unit_price_amt + unit_tax_amt)) 
		INTO l_scrn_ship_amt,l_scrn_out_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND	order_num = modu_rec_orderhead.order_num 

		LET l_scrn_out_amt = l_scrn_out_amt - l_scrn_ship_amt 

	END IF 

	DISPLAY BY NAME 
		modu_rec_orderhead.cust_code, 
		modu_rec_orderhead.order_num, 
		modu_rec_customer.name_text, 
		modu_rec_orderhead.currency_code, 
		modu_rec_orderhead.goods_amt, 
		modu_rec_orderhead.hand_amt, 
		modu_rec_orderhead.freight_amt, 
		modu_rec_orderhead.tax_amt, 
		modu_rec_orderhead.total_amt, 
		modu_rec_orderhead.disc_amt, 
		modu_rec_orderhead.cost_amt, 
		modu_rec_orderhead.entry_code, 
		modu_rec_orderhead.entry_date, 
		modu_rec_orderhead.ord_text, 
		modu_rec_orderhead.ship_date, 
		modu_rec_orderhead.last_inv_num, 
		modu_rec_orderhead.status_ind, 
		modu_rec_orderhead.com1_text, 
		modu_rec_orderhead.rev_date, 
		modu_rec_orderhead.com2_text, 
		modu_rec_orderhead.rev_num 

	DISPLAY l_scrn_ship_amt TO ship_amt 
	DISPLAY l_scrn_out_amt TO out_amt 

	IF promptTF("View Line Details",kandoomsg2("A",8010,""),1) THEN  #8010 View line details? (Y/N):
		LET l_func_type = "View order" 
		CALL lordshow(
			glob_rec_kandoouser.cmpy_code, 
			modu_rec_orderhead.cust_code, 
			modu_rec_orderhead.order_num, 
			l_func_type) 
	END IF 
	
	CLOSE WINDOW E400 
	RETURN 
END FUNCTION 
###########################################################################
# END FUNCTION scanner() 
###########################################################################