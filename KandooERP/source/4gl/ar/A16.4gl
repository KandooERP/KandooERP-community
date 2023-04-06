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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A1_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A11_GLOBALS.4gl" 
GLOBALS "../ar/A16_GLOBALS.4gl" 
############################################################
# FUNCTION A16_main()
#
#
############################################################
FUNCTION A16_main()
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("A16") 
	
	CALL create_table("stnd_custgrp","t1_stnd_custgrp","","N") 

	LET glob_update_order_hold = false 
	LET glob_grp_cust_inv = NULL 

	OPEN WINDOW A109 with FORM "A109" 
	CALL windecoration_a("A109") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL scan_cust() 
	
	CLOSE WINDOW A109 
END FUNCTION
############################################################
# END FUNCTION A16_main()
############################################################


############################################################
# FUNCTION get_datasource_customer(p_filter)
#
#
############################################################
FUNCTION get_datasource_customer(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(300) 

	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		bal_amt LIKE customer.bal_amt, 
		onorder_amt LIKE customer.onorder_amt, 
		avg_cred_day_num LIKE customer.avg_cred_day_num, 
		hold_code LIKE customer.hold_code 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 

		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			cred_limit_amt, 
			bal_amt, 
			onorder_amt, 
			avg_cred_day_num, 
			hold_code 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A16","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") 

	LET l_query_text = 
		"SELECT * FROM customer ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND delete_flag = 'N' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cust_code" 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR FOR s_customer 

	LET l_idx = 0 

	MESSAGE kandoomsg2("U",1002,"") 
	FOREACH c_customer INTO glob_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].scroll_flag = NULL 
		LET l_arr_rec_customer[l_idx].cust_code = glob_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].cred_limit_amt = glob_rec_customer.cred_limit_amt 
		LET l_arr_rec_customer[l_idx].bal_amt = glob_rec_customer.bal_amt 
		LET l_arr_rec_customer[l_idx].onorder_amt = glob_rec_customer.onorder_amt 
		LET l_arr_rec_customer[l_idx].avg_cred_day_num = glob_rec_customer.avg_cred_day_num 
		LET l_arr_rec_customer[l_idx].hold_code = glob_rec_customer.hold_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	RETURN l_arr_rec_customer 
END FUNCTION 
############################################################
# ERROR FUNCTION get_datasource_customer(p_filter)
############################################################


############################################################
# FUNCTION scan_cust()
#
#
############################################################
FUNCTION scan_cust() 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customer.cust_code, 
		cred_limit_amt LIKE customer.cred_limit_amt, 
		bal_amt LIKE customer.bal_amt, 
		onorder_amt LIKE customer.onorder_amt, 
		avg_cred_day_num LIKE customer.avg_cred_day_num, 
		hold_code LIKE customer.hold_code 
	END RECORD 
	DEFINE l_cred_avail_amt LIKE customer.bal_amt 
	DEFINE l_idx SMALLINT --,scrn 

	CALL l_arr_rec_customer.clear() 
	CALL get_datasource_customer(false) RETURNING l_arr_rec_customer 

	MESSAGE kandoomsg2("A",1013,"") 	#1013 F3/F4 TO Page F'ward/B'ward - RETURN on Line TO Edit"
	--   INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A16","inp-arr-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL l_arr_rec_customer.clear() 
			CALL get_datasource_customer(true) RETURNING l_arr_rec_customer 

		ON ACTION "REFRESH" 
			CALL l_arr_rec_customer.clear() 
			CALL get_datasource_customer(false) RETURNING l_arr_rec_customer
			CALL windecoration_a("A109") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("EDIT","doubleClick","ACCEPT") 
			CALL INITIALIZE_globals(MODE_CLASSIC_EDIT,l_arr_rec_customer[l_idx].cust_code) 
			IF customer_edit_3(MODE_CLASSIC_EDIT) THEN 
				IF update_customer(MODE_CLASSIC_EDIT) THEN 
					LET l_arr_rec_customer[l_idx].cred_limit_amt = glob_rec_customer.cred_limit_amt 
					LET l_arr_rec_customer[l_idx].hold_code = glob_rec_customer.hold_code 
				END IF 
			END IF 
			MESSAGE kandoomsg2("A",1013,"") 		#1013 F3/F4 TO Page F'ward/B'ward - RETURN on Line TO Edit"
			--         NEXT FIELD scroll_flag


			--      BEFORE FIELD cust_code
			--         CALL INITIALIZE_globals(MODE_CLASSIC_EDIT,l_arr_rec_customer[l_idx].cust_code)
			--         IF customer_edit_3(MODE_CLASSIC_EDIT) THEN
			--            IF update_customer(MODE_CLASSIC_EDIT) THEN
			--               LET l_arr_rec_customer[l_idx].cred_limit_amt = glob_rec_customer.cred_limit_amt
			--               LET l_arr_rec_customer[l_idx].hold_code = glob_rec_customer.hold_code
			--            END IF
			--         END IF
			--         MESSAGE kandoomsg2("A",1013,"")  #1013 F3/F4 TO Page F'ward/B'ward - RETURN on Line TO Edit"
			--         NEXT FIELD scroll_flag

	END DISPLAY 	#-------------------------------------

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 
############################################################
# END FUNCTION scan_cust()
############################################################