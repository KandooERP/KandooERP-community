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
#       shipwind.4gl - show_ship
#                      Window FUNCTION FOR finding customership records
#                      returns ship_code
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_ship(p_cmpy,p_cust_code)
#
#
############################################################
FUNCTION show_ship(p_cmpy,p_cust_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code #CHAR(8) 
	DEFINE l_rec_customership RECORD LIKE customership.*
	DEFINE l_arr_customership DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customership.name_text, 
		addr_text LIKE customership.addr_text, 
		city_text LIKE customership.city_text 
	END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arg STRING
	
	OPEN WINDOW A120 with FORM "A120" 
	CALL windecoration_a("A120") -- albo kd-755 

	WHILE TRUE 
		CLEAR FORM 
		ERROR kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			ship_code, 
			name_text, 
			addr_text, 
			city_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","shipwind","construct-customership-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_customership.ship_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM customership ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND cust_code = '",p_cust_code,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY ship_code" 
		
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON
		 
		PREPARE s_customership FROM l_query_text 
		DECLARE c_customership CURSOR FOR s_customership
		 
		LET l_idx = 0 
		FOREACH c_customership INTO l_rec_customership.* 
			LET l_idx = l_idx + 1 
			LET l_arr_customership[l_idx].ship_code = l_rec_customership.ship_code 
			LET l_arr_customership[l_idx].name_text = l_rec_customership.name_text 
			LET l_arr_customership[l_idx].addr_text = l_rec_customership.addr_text 
			LET l_arr_customership[l_idx].city_text = l_rec_customership.city_text 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected
		
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
		DISPLAY ARRAY l_arr_customership TO sr_customership.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","shipwind","input-arr-customership-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_customership.ship_code = l_arr_customership[l_idx].ship_code

			ON ACTION "SHIPPING ADDRESSES" #ON KEY (F10)
				IF p_cust_code IS NOT NULL THEN
					LET l_arg = "CUST_CODE=",trim(p_cust_code)
				END IF 
				CALL run_prog("A17",l_arg,"","","")--manage shipping addresses OF CURRENT customer 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW A120 

	RETURN l_rec_customership.ship_code 
END FUNCTION 
############################################################
# END FUNCTION show_ship(p_cmpy,p_cust_code)
############################################################


############################################################
# FUNCTION show_cust_ship(p_cmpy)
#
#
############################################################
FUNCTION show_cust_ship(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_rec_customership RECORD LIKE customership.* 
	DEFINE l_arr_customership DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		cust_code LIKE customership.cust_code, 
		ship_code LIKE customership.ship_code, 
		name_text LIKE customership.name_text, 
		addr_text LIKE customership.addr_text, 
		city_text LIKE customership.city_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_arg STRING

	OPEN WINDOW E457 with FORM "E457" 
	CALL winDecoration_e("E457") -- albo kd-755 

	WHILE TRUE 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			ship_code, 
			name_text, 
			addr_text, 
			city_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","shipwind","construct-customership-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_customership.ship_code = NULL 
			LET l_rec_customership.cust_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"
		LET l_query_text = 
			"SELECT * FROM customership ", 
			"WHERE cmpy_code = '",p_cmpy,"' ", 
			"AND ",l_where_text CLIPPED," ", 
			"ORDER BY ship_code" 

		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		
		PREPARE s2_customership FROM l_query_text 
		DECLARE c2_customership CURSOR FOR s2_customership 

		LET l_idx = 0 
		FOREACH c2_customership INTO l_rec_customership.* 
			LET l_idx = l_idx + 1 
			LET l_arr_customership[l_idx].cust_code = l_rec_customership.cust_code 
			LET l_arr_customership[l_idx].ship_code = l_rec_customership.ship_code 
			LET l_arr_customership[l_idx].name_text = l_rec_customership.name_text 
			LET l_arr_customership[l_idx].addr_text = l_rec_customership.addr_text 
			LET l_arr_customership[l_idx].city_text = l_rec_customership.city_text 
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"
		INPUT ARRAY l_arr_customership WITHOUT DEFAULTS FROM sr_customership.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","shipwind","input-arr-customership-2") 
 				CALL dialog.setActionHidden("ACCEPT",NOT l_arr_customership.getSize())
 									
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_customership.ship_code = l_arr_customership[l_idx].ship_code 
				LET l_rec_customership.cust_code = l_arr_customership[l_idx].cust_code 

			ON ACTION "SHIPPING ADDRESSES" #ON KEY (F10)
				IF l_arr_customership[l_idx].cust_code IS NOT NULL THEN
					LET l_arg = "CUST_CODE=",trim(l_arr_customership[l_idx].cust_code)
				END IF 
				CALL run_prog("A17",l_arg,"","","")--manage shipping addresses OF CURRENT customer 

			BEFORE FIELD cust_code 
				EXIT INPUT 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW E457 

	RETURN l_rec_customership.cust_code, l_rec_customership.ship_code 
END FUNCTION 
############################################################
# END FUNCTION show_cust_ship(p_cmpy)
############################################################