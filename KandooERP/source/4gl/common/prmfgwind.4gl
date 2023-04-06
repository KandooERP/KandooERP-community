{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - prodmfgwind.4gl
# Purpose - Control-B lookup SCREEN FOR mfg products

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_mfgprods(p_cmpy,p_type) 
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE p_type CHAR(3)

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_prodmfg ARRAY[1000] OF RECORD 
		part_code LIKE prodmfg.part_code, 
		desc_text LIKE product.desc_text, 
		part_type_ind LIKE prodmfg.part_type_ind, 
		part_type_text CHAR(12) 
	END RECORD 
	DEFINE l_cnt SMALLINT 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_runner CHAR(10) 
	DEFINE l_reselect SMALLINT 

	OPEN WINDOW w1_m126 with FORM "M126" 
	CALL windecoration_m("M126") -- albo kd-767 

	WHILE true 

		CLEAR FORM 

		LET l_msgresp = kandoomsg("M",1500,"") 
		# MESSAGE "Enter Selection Criteria - ESC TO Accept, DEL TO Exit"

		IF p_type IS NULL THEN 
			CONSTRUCT BY NAME l_where_part 
			ON prodmfg.part_code, desc_text, part_type_ind 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","prmfgwind","construct-product-1") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 
		ELSE 
			CONSTRUCT BY NAME l_where_part 
			ON prodmfg.part_code, desc_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","prmfgwind","construct-product-2") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 
		END IF 

		LET l_cnt = 1 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		IF p_type IS NULL THEN 
			LET l_query_text = "SELECT prodmfg.part_code, desc_text, ", 
			"part_type_ind ", 
			"FROM prodmfg, product ", 
			"WHERE prodmfg.cmpy_code = '", p_cmpy, "' ", 
			"AND prodmfg.cmpy_code = product.cmpy_code ", 
			"AND prodmfg.part_code = product.part_code ", 
			"AND ", l_where_part clipped, " ", 
			"ORDER BY prodmfg.part_code" 
		ELSE 
			LET l_query_text = "SELECT prodmfg.part_code, desc_text, ", 
			"part_type_ind ", 
			"FROM prodmfg, product ", 
			"WHERE prodmfg.cmpy_code = '", p_cmpy, "' ", 
			"AND prodmfg.cmpy_code = product.cmpy_code ", 
			"AND prodmfg.part_code = product.part_code ", 
			"AND prodmfg.part_type_ind matches '[", 
			p_type, "]' ", 
			"AND ", l_where_part clipped, " ", 
			"ORDER BY prodmfg.part_code" 
		END IF 

		PREPARE sl_stmt1 FROM l_query_text 
		DECLARE c_prodmfg CURSOR FOR sl_stmt1 

		FOREACH c_prodmfg INTO l_arr_prodmfg[l_cnt].* 

			CASE l_arr_prodmfg[l_cnt].part_type_ind 
				WHEN "G" 
					LET l_arr_prodmfg[l_cnt].part_type_text = "Generic" 
				WHEN "M" 
					LET l_arr_prodmfg[l_cnt].part_type_text = "Manufactured" 
				WHEN "P" 
					LET l_arr_prodmfg[l_cnt].part_type_text = "Phantom" 
				WHEN "R" 
					LET l_arr_prodmfg[l_cnt].part_type_text = "Raw Material" 
			END CASE 

			LET l_cnt = l_cnt + 1 

			IF l_cnt > 1000 THEN 
				LET l_msgresp = kandoomsg("M", 9500, "") 
				# ERROR "Only the first 1000 products have been selected"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("M", 1503, "") 
		# MESSAGE "F3 Fwd, F4 Bwd, F9 Reselect, F10 Add, ESC SELECT - DEL Exit"

		LET l_reselect = false 
		CALL set_count(l_cnt - 1) 

		DISPLAY ARRAY l_arr_prodmfg TO sr_prodmfg.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","prmfgwind","display-arr-job_prodmfg") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (f9) 
				LET l_reselect = true 
				EXIT DISPLAY 

			ON KEY (f10) 
				LET l_runner = "fglgo I11" 
				RUN l_runner 

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF NOT l_reselect THEN 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW w1_m126 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_prodmfg[l_cnt].part_code = NULL 
	END IF 

	RETURN l_arr_prodmfg[l_cnt].part_code 

END FUNCTION 
