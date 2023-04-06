# Purpose - Control-B lookup SCREEN FOR Departments

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_mfg_dept(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_dept ARRAY[500] OF 
		RECORD 
			dept_code LIKE mfgdept.dept_code, 
			desc_text LIKE mfgdept.desc_text, 
			wip_acct_code LIKE mfgdept.wip_acct_code 
		END RECORD 
	DEFINE l_cnt SMALLINT 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_runner CHAR(10) 
	DEFINE l_reselect SMALLINT 
	DEFINE l_formname CHAR(15) 

	OPEN WINDOW w1_m171 with FORM "M171" 
	CALL windecoration_m("M171") -- albo kd-767 

	WHILE TRUE 

		CLEAR FORM 

		LET l_msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME l_where_part 
		ON dept_code, desc_text, wip_acct_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","mfgdptwind","construct-mfgdept") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		LET l_cnt = 1 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET l_query_text = "SELECT dept_code, desc_text, wip_acct_code ", 
		"FROM mfgdept ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND ", l_where_part CLIPPED, " ", 
		"ORDER BY dept_code" 

		PREPARE sl_stmt1 FROM l_query_text 
		DECLARE c_mfgdept CURSOR FOR sl_stmt1 

		FOREACH c_mfgdept INTO l_arr_dept[l_cnt].* 

			LET l_cnt = l_cnt + 1 

			IF l_cnt > 500 THEN 
				LET l_msgresp = kandoomsg("M", 9504, "") 
				# ERROR "Only the first 500 departments have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1503, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, F10 Add, ESC SELECT - DEL Exit"

		LET l_reselect = FALSE 
		CALL set_count(l_cnt - 1) 

		DISPLAY ARRAY l_arr_dept TO sr_mfgdept.* ATTRIBUTE(UNBUFFERED) 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","mfgdptwind","display-arr-dept") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 



			ON KEY (f9) 
				LET l_reselect = TRUE 
				EXIT DISPLAY 

			ON KEY (f10) 
				LET l_runner = "fglgo MZ4" 
				RUN l_runner 

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF NOT l_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m171 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET l_arr_dept[l_cnt].dept_code = NULL 
	END IF 

	RETURN l_arr_dept[l_cnt].dept_code 

END FUNCTION 
