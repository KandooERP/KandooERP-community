# Purpose - Control-B lookup SCREEN FOR sales orders
GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_orders(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_orderhead ARRAY[1000] OF RECORD 
		order_num LIKE orderhead.order_num, 
		cust_code LIKE orderhead.cust_code, 
		status_ind LIKE orderhead.status_ind, 
		status_desc CHAR(10) 
	END RECORD
	DEFINE l_cnt SMALLINT 
	DEFINE l_reselect SMALLINT 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
 	DEFINE l_formname CHAR(15) 

	OPEN WINDOW w1_m129 with FORM "M129" 
	CALL windecoration_m("M129") -- albo kd-767 

	WHILE true 

		CLEAR FORM 
		LET l_cnt = 1 

		LET l_msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME l_where_part 
		ON order_num, cust_code, status_ind 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","orderwind","construct-orderhead") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET l_query_text = "SELECT order_num, cust_code, status_ind", 
		" FROM orderhead ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ", l_where_part CLIPPED, " ", 
		"ORDER BY order_num" 

		PREPARE sl_stmt1 FROM l_query_text 
		DECLARE c_orderhead CURSOR FOR sl_stmt1 

		FOREACH c_orderhead INTO l_arr_orderhead[l_cnt].* 
			CASE l_arr_orderhead[l_cnt].status_ind 
				WHEN "U" 
					LET l_arr_orderhead[l_cnt].status_desc = "Unshipped" 
				WHEN "P" 
					LET l_arr_orderhead[l_cnt].status_desc = "Partial" 
				WHEN "C" 
					LET l_arr_orderhead[l_cnt].status_desc = "Completed" 
				WHEN "I" 
					LET l_arr_orderhead[l_cnt].status_desc = "Incomplete" 
			END CASE 

			LET l_cnt = l_cnt + 1 

			IF l_cnt > 1000 THEN 
				LET l_msgresp = kandoomsg("M", 9503, "") 
				# ERROR "Only the first 1000 sales orders have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1506, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, ESC SELECT - DEL Exit"

		CALL set_count(l_cnt - 1) 
		LET l_reselect = false 

		DISPLAY ARRAY l_arr_orderhead TO sr_orderhead.* ATTRIBUTE(UNBUFFERED) 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","orderwind","display-arr-orderhead") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (f9) 
				LET l_reselect = true 
				EXIT DISPLAY 

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF NOT l_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m129 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_orderhead[l_cnt].order_num = NULL 
	END IF 

	RETURN l_arr_orderhead[l_cnt].order_num 

END FUNCTION 
