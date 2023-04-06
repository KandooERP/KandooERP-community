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
GLOBALS "../eo/E15_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_orderhead RECORD LIKE orderhead.* 
DEFINE modu_rec_customer RECORD LIKE customer.*
###########################################################################
# FUNCTION E15_main()
#
# allows the user TO view Order Information
###########################################################################
FUNCTION E15_main() 
	DEFINE l_temp_text char(40) 

	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E15") 
	
	LET l_temp_text = glob_rec_arparms.inv_ref1_text clipped,"................" 
	LET glob_rec_arparms.inv_ref1_text = l_temp_text 


	CALL E15_navigate_with_cursor() 


END FUNCTION 
###########################################################################
# END FUNCTION E15_main()
########################################################################### 


###########################################################################
# FUNCTION db_orderhead_customer_datasource_cursor(p_filter) 
#
# 
###########################################################################
FUNCTION db_orderhead_customer_datasource_cursor(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 

	IF p_filter THEN
		MESSAGE kandoomsg2("U",1001,"") #1001 Enter selection criteria; OK TO continue.
		CONSTRUCT BY NAME l_where_text ON 
			orderhead.cust_code, 
			customer.name_text, 
			orderhead.order_num, 
			orderhead.currency_code, 
			orderhead.goods_amt, 
			orderhead.hand_amt, 
			orderhead.freight_amt, 
			orderhead.tax_amt, 
			orderhead.total_amt, 
			orderhead.cost_amt, 
			orderhead.disc_amt, 
			orderhead.ord_text, 
			orderhead.ship_date, 
			orderhead.last_inv_num, 
			orderhead.status_ind, 
			orderhead.entry_code, 
			orderhead.entry_date, 
			orderhead.com1_text, 
			orderhead.com2_text, 
			orderhead.rev_date, 
			orderhead.rev_num 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E15","construct-orderhead-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF
	ELSE 
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = "SELECT orderhead.*,", 
	"customer.name_text ", 
	"FROM orderhead,", 
	"customer ", 
	"WHERE orderhead.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND customer.cust_code=orderhead.cust_code ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY order_num"
	 
	PREPARE s_orderhead FROM l_query_text 
	DECLARE c_orderhead SCROLL cursor FOR s_orderhead
	 
	OPEN c_orderhead 
	FETCH FIRST c_orderhead INTO 
		modu_rec_orderhead.*, 
		modu_rec_customer.name_text 
	IF status = NOTFOUND THEN 
		RETURN FALSE 
	ELSE 
		CALL disp_order() 
		RETURN TRUE 
	END IF 
 
END FUNCTION 
###########################################################################
# END FUNCTION db_orderhead_customer_datasource_cursor(p_filter)
########################################################################### 


###########################################################################
# FUNCTION E15_navigate_with_cursor() 
#
# 
###########################################################################
FUNCTION E15_navigate_with_cursor() 

	OPEN WINDOW E400 with FORM "E400" 
	 CALL windecoration_e("E400") -- albo kd-755 
	
	DISPLAY BY NAME glob_rec_arparms.inv_ref1_text 
	MENU " Sales orders" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","E15","menu-Sales_Orders-1") -- albo kd-502 
			IF db_orderhead_customer_datasource_cursor(FALSE) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				MESSAGE kandoomsg2("A",9044,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "Refresh"
			 CALL windecoration_e("E400")
			IF db_orderhead_customer_datasource_cursor(FALSE) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				MESSAGE kandoomsg2("A",9044,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
			
		ON ACTION "FILTER" --COMMAND "Query" " Enter selection criteria FOR customer sales orders " 
			IF db_orderhead_customer_datasource_cursor(TRUE) THEN 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "First" 
				SHOW option "Last" 
				SHOW option "Detail" 
			ELSE 
				MESSAGE kandoomsg2("A",9044,"") 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
		
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected customer order" 
			FETCH NEXT c_orderhead INTO modu_rec_orderhead.*, 
			modu_rec_customer.name_text 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9001,"") 
			ELSE 
				CALL disp_order() 
			END IF 
	
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected customer order" 
			FETCH previous c_orderhead INTO 
				modu_rec_orderhead.*, 
				modu_rec_customer.name_text 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9001,"") 
			ELSE 
				CALL disp_order() 
			END IF 

		COMMAND KEY ("D",f20) "Detail" " View customer ORDER details" 
			CALL lordshow(
				glob_rec_kandoouser.cmpy_code,
				modu_rec_orderhead.cust_code,
				modu_rec_orderhead.order_num, 
				NULL) 
			
			LET int_flag = FALSE 
			LET quit_flag = FALSE 

		COMMAND KEY ("F",f18) "First" " DISPLAY first customer ORDER in the selected list" 
			FETCH FIRST c_orderhead INTO 
				modu_rec_orderhead.*, 
				modu_rec_customer.name_text 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9001,"") 
			ELSE 
				CALL disp_order() 
			END IF 

		COMMAND KEY ("L",f22) "Last" " DISPLAY last customer orders in the selected list" 
			FETCH LAST c_orderhead INTO modu_rec_orderhead.*, 
			modu_rec_customer.name_text 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("U",9001,"") 
			ELSE 
				CALL disp_order() 
			END IF 

		ON ACTION "CANCEL" --COMMAND KEY(INTERRUPT,escape,"E") "Exit" " Exit TO menus" 
			EXIT MENU 
	END MENU 

	CLOSE WINDOW E400 
END FUNCTION 
###########################################################################
# END FUNCTION E15_navigate_with_cursor() 
########################################################################### 


###########################################################################
# FUNCTION disp_order() 
#
# 
###########################################################################
FUNCTION disp_order() 
	DEFINE l_dummy money(10,2) 
	DEFINE l_wrk_ship_amt LIKE orderhead.goods_amt 
	DEFINE l_wrk_out_amt LIKE orderhead.goods_amt 
	DEFINE l_wrk_ship_tax_amt LIKE orderhead.goods_amt 
	DEFINE l_wrk_out_tax_amt LIKE orderhead.goods_amt 
	DEFINE l_scrn_ship_amt LIKE orderhead.goods_amt 
	DEFINE l_scrn_out_amt LIKE orderhead.goods_amt 

	IF modu_rec_orderhead.tax_code = "T" THEN 
		SELECT sum(inv_qty * unit_price_amt), 
		sum(order_qty * unit_price_amt) 
		INTO l_wrk_ship_amt, l_wrk_out_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND order_num = modu_rec_orderhead.order_num 
		
		IF l_wrk_ship_amt != 0 THEN 
			CALL find_tax(modu_rec_orderhead.tax_code," "," ",0,0,l_wrk_ship_amt,1,"S", "","") 
			RETURNING l_dummy,l_wrk_ship_tax_amt,l_dummy,l_dummy,modu_rec_orderhead.tax_code 
		END IF
		 
		IF l_wrk_out_amt != 0 THEN 
			CALL find_tax(modu_rec_orderhead.tax_code," "," ",0,0,l_wrk_out_amt,1,"S", "","") 
			RETURNING l_dummy,l_wrk_out_tax_amt,l_dummy,l_dummy,modu_rec_orderhead.tax_code 
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
		SELECT sum(inv_qty *(unit_price_amt+unit_tax_amt)), 
		sum(order_qty*(unit_price_amt + unit_tax_amt)) 
		INTO l_scrn_ship_amt, 
		l_scrn_out_amt 
		FROM orderdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND order_num = modu_rec_orderhead.order_num 
		
		LET l_scrn_out_amt = l_scrn_out_amt - l_scrn_ship_amt 
	END IF 

	DISPLAY BY NAME 
		modu_rec_orderhead.cust_code, 
		modu_rec_customer.name_text, 
		modu_rec_orderhead.order_num, 
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
		modu_rec_orderhead.status_ind, 
		modu_rec_orderhead.last_inv_num, 
		modu_rec_orderhead.com1_text, 
		modu_rec_orderhead.rev_date, 
		modu_rec_orderhead.com2_text, 
		modu_rec_orderhead.rev_num 

	DISPLAY l_scrn_ship_amt TO ship_amt
	DISPLAY l_scrn_out_amt TO out_amt

END FUNCTION
###########################################################################
# END FUNCTION disp_order() 
###########################################################################