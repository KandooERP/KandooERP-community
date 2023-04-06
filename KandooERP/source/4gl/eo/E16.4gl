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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/E1_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E16_GLOBALS.4gl"
###########################################################################
# FUNCTION E16_main()
#
# allows the user TO Scan Sales Orders
###########################################################################
FUNCTION E16_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E16") 

 	CALL E16_scan_order() 

END FUNCTION 
###########################################################################
# END FUNCTION E16_main()
########################################################################### 

###########################################################################
# FUNCTION db_orderhead_datasource(where_text) 
#
# 
###########################################################################
FUNCTION db_orderhead_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_order_text STRING
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind 
	END RECORD 
	DEFINE l_idx SMALLINT
	DEFINE l_url_customer_code LIKE customer.cust_code 

	LET l_url_customer_code = get_url_cust_code() 
	IF l_url_customer_code IS NOT NULL THEN
		LET l_where_text = "cust_code = '",trim(l_url_customer_code),"' AND status_ind!='C' "  #We only use the url/argument WHERE clause ONCE
		LET l_order_text = "cust_code, order_num"
	ELSE 
		LET l_order_text = " order_num "
		IF p_filter THEN
	
			CLEAR FORM 
			DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text attribute(white)
			DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text attribute(white)
			 
			IF l_where_text IS NULL THEN 
				MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter selection criteria AND press ESC TO begin search"
				CONSTRUCT BY NAME l_where_text ON 
					order_num, 
					cust_code, 
					ord_text, 
					last_inv_num, 
					order_date, 
					total_amt, 
					status_ind 
		
					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","E16","construct-order_num-1") -- albo kd-502 
		
					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
		
				END CONSTRUCT 

			END IF 
		
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_where_text = " 1=1 "
				LET l_order_text = "order_num"
			END IF 
		ELSE
			LET l_where_text = " 1=1 "
			LET l_order_text = "order_num"
		END IF
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") 
	LET l_query_text = 
		"SELECT * FROM orderhead ", 
		"WHERE cmpy_code= '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY ", l_order_text clipped
	 
	PREPARE s_orderhead FROM l_query_text 
	DECLARE c_orderhead cursor FOR s_orderhead 

	LET l_idx = 0 
	FOREACH c_orderhead INTO l_rec_orderhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_orderhead[l_idx].order_num = l_rec_orderhead.order_num 
		LET l_arr_rec_orderhead[l_idx].cust_code = l_rec_orderhead.cust_code 
		LET l_arr_rec_orderhead[l_idx].ord_text = l_rec_orderhead.ord_text 
		LET l_arr_rec_orderhead[l_idx].last_inv_num = l_rec_orderhead.last_inv_num 
		LET l_arr_rec_orderhead[l_idx].order_date = l_rec_orderhead.order_date 
		LET l_arr_rec_orderhead[l_idx].total_amt = l_rec_orderhead.total_amt 
		LET l_arr_rec_orderhead[l_idx].status_ind = l_rec_orderhead.status_ind 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	CALL set_url_cust_code(NULL) #We only use the url/argumnet WHERE clause ONCE 
	
	RETURN l_arr_rec_orderhead
END FUNCTION 
###########################################################################
# END FUNCTION db_orderhead_datasource(where_text)
########################################################################### 


###########################################################################
# FUNCTION E16_scan_order() 
#
# 
###########################################################################
FUNCTION E16_scan_order() 
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_arr_rec_orderhead DYNAMIC ARRAY OF RECORD 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		ord_text LIKE orderhead.ord_text, 
		last_inv_num LIKE orderhead.last_inv_num, 
		order_date LIKE orderhead.order_date, 
		total_amt LIKE orderhead.total_amt, 
		status_ind LIKE orderhead.status_ind 
	END RECORD 
	DEFINE l_idx SMALLINT
	DEFINE l_where_text STRING 

	OPEN WINDOW E401 with FORM "E401" 
	 CALL windecoration_e("E401") 

	CALL db_orderhead_datasource(FALSE) RETURNING l_arr_rec_orderhead
	DISPLAY glob_rec_arparms.inv_ref2a_text TO inv_ref2a_text attribute(white)
	DISPLAY glob_rec_arparms.inv_ref2b_text TO inv_ref2b_text attribute(white)

	MESSAGE kandoomsg2("U",9113,l_idx) SLEEP 2 #why have we got 2 messages here ?
	MESSAGE kandoomsg2("U",1007,l_idx) #1007 " Cursor TO ORDER AND press RETURN TO view more detail"

	DISPLAY ARRAY l_arr_rec_orderhead TO sr_orderhead.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E16","display-arr-orderhead") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			CALL dialog.setActionHidden("DETAIL",NOT l_arr_rec_orderhead.getSize())			
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Refresh"
			 CALL windecoration_e("E161")
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_datasource(FALSE) RETURNING l_arr_rec_orderhead
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_orderhead.getSize())

		ON ACTION "FILTER"
			CALL l_arr_rec_orderhead.clear()
			CALL db_orderhead_datasource(TRUE) RETURNING l_arr_rec_orderhead
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_orderhead.getSize())
			
		ON ACTION ("DETAIL","DOUBLECLICK","ACCEPT") #ON KEY (tab) 
			LET l_idx = arr_curr() 
			IF l_arr_rec_orderhead[l_idx].cust_code IS NOT NULL THEN 
				CALL disc_amtp_head(glob_rec_kandoouser.cmpy_code,l_arr_rec_orderhead[l_idx].cust_code, 				l_arr_rec_orderhead[l_idx].order_num) 
			END IF 

#Looks to me like copy paste... I'll comment it
--		ON KEY (return) 
--			LET l_idx = arr_curr() 
--			IF l_arr_rec_orderhead[l_idx].cust_code IS NOT NULL THEN 
--				CALL disc_amtp_head(glob_rec_kandoouser.cmpy_code,l_arr_rec_orderhead[l_idx].cust_code, 
--				l_arr_rec_orderhead[l_idx].order_num) 
--			END IF 

	END DISPLAY

	CLOSE WINDOW E401
		 
	LET int_flag = 0 
	LET quit_flag = 0 
END FUNCTION
###########################################################################
# END FUNCTION E16_scan_order()
###########################################################################