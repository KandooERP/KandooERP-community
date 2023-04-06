{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - shopordwind.4gl
# Purpose - Control-B lookup SCREEN FOR shop orders

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_shopords(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_shopordhead array[1000] OF RECORD 
		shop_order_num LIKE shopordhead.shop_order_num, 
		suffix_num LIKE shopordhead.suffix_num, 
		order_type_ind LIKE shopordhead.order_type_ind, 
		status_ind LIKE shopordhead.status_ind, 
		part_code LIKE shopordhead.part_code, 
		order_qty LIKE shopordhead.order_qty 
	END RECORD 
	DEFINE l_cnt SMALLINT 
	DEFINE l_reselect SMALLINT
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
 	DEFINE l_formname CHAR(15) 

	OPEN WINDOW w1_m165 with FORM "M165" 
	CALL windecoration_m("M165") -- albo kd-752 
	WHILE TRUE 

		CLEAR FORM 
		LET l_cnt = 1 

		LET l_msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME l_where_part 
		ON shop_order_num, suffix_num, order_type_ind, status_ind, 
		part_code, order_qty 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","shpordwind","construct-shopordhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET l_query_text = "SELECT shop_order_num, suffix_num, ", 
		"order_type_ind, status_ind, part_code, ", 
		"order_qty ", 
		"FROM shopordhead ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ", l_where_part CLIPPED, " ", 
		"ORDER BY shop_order_num, suffix_num" 

		PREPARE sl_stmt1 FROM l_query_text 
		DECLARE c_shopordhead CURSOR FOR sl_stmt1 

		FOREACH c_shopordhead INTO l_arr_shopordhead[l_cnt].* 
			LET l_cnt = l_cnt + 1 

			IF l_cnt > 1000 THEN 
				LET l_msgresp = kandoomsg("M", 9506, "") 
				# ERROR "Only the first 1000 shop orders have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1506, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, ESC SELECT - DEL Exit"

		CALL set_count(l_cnt - 1) 
		LET l_reselect = false 

		DISPLAY ARRAY l_arr_shopordhead TO sr_shopordhead.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","shpordwind","display-arr-shopordhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (f9) 
				LET l_reselect = TRUE 
				EXIT DISPLAY 

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF NOT l_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m165 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_shopordhead[l_cnt].shop_order_num = NULL 
		LET l_arr_shopordhead[l_cnt].suffix_num = NULL 
	END IF 

	RETURN l_arr_shopordhead[l_cnt].shop_order_num, 
	l_arr_shopordhead[l_cnt].suffix_num 

END FUNCTION 
