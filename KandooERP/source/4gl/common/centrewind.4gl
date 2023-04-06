# Purpose - Control-B lookup SCREEN FOR work centre codes

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_centres(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cnt SMALLINT 
	DEFINE l_reselect SMALLINT 
	DEFINE l_runner CHAR(10) 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_formname CHAR(15) 
	DEFINE l_arr_centre ARRAY[1000] OF RECORD 
		work_centre_code LIKE workcentre.work_centre_code, 
		desc_text LIKE workcentre.desc_text, 
		processing_ind LIKE workcentre.processing_ind, 
		time_qty LIKE workcentre.time_qty, 
		time_unit_ind LIKE workcentre.time_unit_ind, 
		unit_uom_code LIKE workcentre.unit_uom_code 
	END RECORD 

	OPEN WINDOW w1_m116 with FORM "M116" 
	CALL windecoration_m("M116") -- albo kd-767 

	WHILE true 

		CLEAR FORM 

		LET l_msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		CONSTRUCT BY NAME l_where_part 
		ON work_centre_code, desc_text, processing_ind, time_qty, 
		time_unit_ind, unit_uom_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","centrewind","construct-workcentre") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		LET l_cnt = 1 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET l_query_text = "SELECT work_centre_code, desc_text, ", 
		"processing_ind, time_qty, time_unit_ind, ", 
		"unit_uom_code ", 
		"FROM workcentre ", 
		"WHERE cmpy_code = '", p_cmpy CLIPPED, "' ", 
		"AND ", l_where_part CLIPPED, " ", 
		"ORDER BY work_centre_code" 

		PREPARE sl_stmt1 FROM l_query_text 
		DECLARE c_centre CURSOR FOR sl_stmt1 

		FOREACH c_centre INTO l_arr_centre[l_cnt].* 
			LET l_cnt = l_cnt + 1 

			IF l_cnt > 1000 THEN 
				LET l_msgresp = kandoomsg("M", 9501, "") 
				# ERROR "Only the first 1000 work centres have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1503, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, F10 Add, ESC SELECT - DEL Exit"

		LET l_reselect = false 
		CALL set_count(l_cnt - 1) 

		DISPLAY ARRAY l_arr_centre TO sr_centre.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","centrewind","display-arr-centre") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (f9) 
				LET l_reselect = true 
				EXIT DISPLAY 

			ON KEY (f10) 
				LET l_runner = "fglgo MZ1" 
				RUN l_runner 

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF NOT l_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m116 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_centre[l_cnt].work_centre_code = NULL 
	END IF 

	RETURN l_arr_centre[l_cnt].work_centre_code 

END FUNCTION 
