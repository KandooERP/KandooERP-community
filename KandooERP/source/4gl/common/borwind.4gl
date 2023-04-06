# Purpose - Control-B lookup SCREEN FOR BOR parent products

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_parents(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_fa_parent array[2000] OF RECORD 
		parent_part_code LIKE bor.parent_item_code, 
		desc_text LIKE product.desc_text 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_fv_cnt SMALLINT 
	DEFINE l_l_fv_reselect SMALLINT 
	DEFINE l_fv_where_part CHAR(2048) 
	DEFINE l_fv_query_text CHAR(2200) 
	DEFINE l_formname CHAR(15) 

	OPEN WINDOW w1_m127 with FORM "M127" 
	CALL windecoration_m("M127") -- albo kd-767 

	WHILE true 

		CLEAR FORM 
		LET l_fv_cnt = 1 

		LET l_msgresp = kandoomsg("M",1501,"") 
		# MESSAGE "Enter Selection Criteria - ESC Accept, DEL Exit"

		CONSTRUCT BY NAME l_fv_where_part 
		ON parent_part_code, desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","borwind","construct-part_code") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET l_fv_query_text = "SELECT unique parent_part_code, product.desc_text", 
		" FROM bor, product ", 
		"WHERE bor.cmpy_code = '", p_cmpy, "' ", 
		"AND bor.cmpy_code = product.cmpy_code ", 
		"AND bor.parent_part_code = product.part_code ", 
		"AND ", l_fv_where_part clipped, " ", 
		"ORDER BY bor.parent_part_code" 

		PREPARE sl_stmt1 FROM l_fv_query_text 
		DECLARE c_parent CURSOR FOR sl_stmt1 

		FOREACH c_parent INTO l_arr_fa_parent[l_fv_cnt].* 
			LET l_fv_cnt = l_fv_cnt + 1 

			IF l_fv_cnt > 2000 THEN 
				LET l_msgresp = kandoomsg("M", 9502, "") 
				# ERROR "Only the first 2000 products have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1506, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, ESC SELECT - DEL Exit"

		LET l_l_fv_reselect = false 
		CALL set_count(l_fv_cnt - 1) 

		DISPLAY ARRAY l_arr_fa_parent TO sr_parent.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","borwind","display-arr-parent") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (f9) 
				LET l_l_fv_reselect = true 
				EXIT DISPLAY 

		END DISPLAY 

		LET l_fv_cnt = arr_curr() 

		IF NOT l_l_fv_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m127 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_fa_parent[l_fv_cnt].parent_part_code = NULL 
	END IF 

	RETURN l_arr_fa_parent[l_fv_cnt].parent_part_code 

END FUNCTION 
