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

	Source code beautified by beautify.pl on 2020-01-02 10:35:44	$Id: $
}



#        wshorwin.4gl - show_mborders
#                       Ordhead Lookup with attached Inquiry (mbordwin)
#                       returns order_num
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_mborders(p_cmpy,p_filter_text)
#
#
############################################################
FUNCTION show_mborders(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(100) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_ordhead RECORD LIKE ordhead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_ordhead DYNAMIC ARRAY OF #array[800] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			order_num LIKE ordhead.order_num, 
			ord_ind LIKE ordhead.ord_ind, 
			cust_code LIKE ordhead.cust_code, 
			order_date LIKE ordhead.order_date, 
			ord_pallet_qty LIKE ordhead.ord_pallet_qty, 
			out_pallet_qty LIKE ordhead.out_pallet_qty 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		OPEN WINDOW w245 with FORM "W245" 
		CALL winDecoration_w("W245") -- albo kd-752 

		WHILE TRUE 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON order_num, 
			ordhead.ord_ind, 
			ordhead.cust_code, 
			order_date, 
			ord_pallet_qty, 
			out_pallet_qty, 
			name_text, 
			ship_addr1_text, 
			ship_addr2_text, 
			ship_city_text, 
			ship_state_code, 
			ship_post_code, 
			map_reference 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","wshorwin","construct-ordhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rec_ordhead.order_num = NULL 
				EXIT WHILE 
			END IF 
			IF p_filter_text IS NULL THEN 
				LET p_filter_text = "1=1" 
			END IF 

			LET l_msgresp=kandoomsg("U",1002,"") 
			#U1002 "Searching database - please wait"
			LET l_query_text = "SELECT ordhead.* FROM ordhead,customer ", 
			"WHERE ordhead.cmpy_code = \"",p_cmpy,"\" ", 
			"AND customer.cmpy_code = \"",p_cmpy,"\" ", 
			"AND customer.cust_code = ordhead.cust_code ", 
			"AND ordhead.status_ind != 'R' ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_text CLIPPED," ", 
			"ORDER BY order_num desc" 
			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 
			PREPARE s_ordhead FROM l_query_text 
			DECLARE c_ordhead CURSOR FOR s_ordhead 

			LET l_idx = 0 
			FOREACH c_ordhead INTO l_rec_ordhead.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_ordhead[l_idx].scroll_flag = NULL 
				LET l_arr_rec_ordhead[l_idx].order_num = l_rec_ordhead.order_num 
				LET l_arr_rec_ordhead[l_idx].ord_ind = l_rec_ordhead.ord_ind 
				LET l_arr_rec_ordhead[l_idx].cust_code = l_rec_ordhead.cust_code 
				LET l_arr_rec_ordhead[l_idx].order_date = l_rec_ordhead.order_date 
				LET l_arr_rec_ordhead[l_idx].ord_pallet_qty = l_rec_ordhead.ord_pallet_qty 
				LET l_arr_rec_ordhead[l_idx].out_pallet_qty = l_rec_ordhead.out_pallet_qty 
				#         IF l_idx = 800 THEN
				#            LET l_msgresp = kandoomsg("U",6100,l_idx)
				#            EXIT FOREACH
				#         END IF
			END FOREACH 

			LET l_msgresp = kandoomsg("U",9113,l_idx) 
			#U9113 "l_idx records selected"
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_ordhead[1].* TO NULL 
			END IF 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

			LET l_msgresp = kandoomsg("W",1080,"") 
			#1080 "F6 ORDER inquiry - ESC TO continue"
			CALL set_count(l_idx) 

			INPUT ARRAY l_arr_rec_ordhead WITHOUT DEFAULTS FROM sr_ordhead.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","wordwin","input-arr-ordhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				BEFORE ROW 
					LET l_idx = arr_curr() 
					#            LET scrn = scr_line()
					IF l_arr_rec_ordhead[l_idx].order_num IS NOT NULL THEN 
						INITIALIZE l_rec_customer.* TO NULL 
						SELECT * INTO l_rec_customer.* FROM customer 
						WHERE cmpy_code = p_cmpy 
						AND cust_code = l_arr_rec_ordhead[l_idx].cust_code 
						INITIALIZE l_rec_ordhead.* TO NULL 
						SELECT * INTO l_rec_ordhead.* FROM ordhead 
						WHERE cmpy_code = p_cmpy 
						AND order_num = l_arr_rec_ordhead[l_idx].order_num 
						DISPLAY BY NAME l_rec_customer.name_text, 
						l_rec_ordhead.ship_addr1_text, 
						l_rec_ordhead.ship_addr2_text, 
						l_rec_ordhead.ship_city_text, 
						l_rec_ordhead.ship_state_code, 
						l_rec_ordhead.ship_post_code, 
						l_rec_ordhead.map_reference 

						#               DISPLAY l_arr_rec_ordhead[l_idx].* TO sr_ordhead[scrn].*

					END IF 
					NEXT FIELD scroll_flag 

				AFTER FIELD scroll_flag 
					LET l_arr_rec_ordhead[l_idx].scroll_flag = NULL 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						NEXT FIELD scroll_flag 
					END IF 

				BEFORE FIELD order_num 
					LET l_rec_ordhead.order_num = l_arr_rec_ordhead[l_idx].order_num 
					EXIT INPUT 

				ON KEY (F6) 
					IF l_arr_rec_ordhead[l_idx].order_num IS NOT NULL THEN 
						CALL ord_clnt(p_cmpy, l_arr_rec_ordhead[l_idx].order_num, 0) 
					END IF 
					#         AFTER ROW
					#            DISPLAY l_arr_rec_ordhead[l_idx].* TO sr_ordhead[scrn].*

				AFTER INPUT 
					LET l_rec_ordhead.order_num = l_arr_rec_ordhead[l_idx].order_num 

			END INPUT 
			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		CLOSE WINDOW w245 
		RETURN l_rec_ordhead.order_num 
END FUNCTION 


