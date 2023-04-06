GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_linegrps(p_cmpy_code,p_line_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_line_code LIKE rptlinegrp.line_code 
	DEFINE l_formname CHAR(15)
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_arr_rptlinegrp ARRAY[150] OF RECORD 
				line_code LIKE rptlinegrp.line_code, 
				linegrp_desc LIKE rptlinegrp.linegrp_desc 
			 END RECORD 
	DEFINE l_sel_text CHAR(2200)
	DEFINE l_fv_query_text CHAR(2048)
	DEFINE l_query_text CHAR(2048) 
	DEFINE l_scrn SMALLINT
	DEFINE l_cnt SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_try_another CHAR(1) 

	OPEN WINDOW g582 with FORM "G582" 
	CALL windecoration_g("G582") -- albo kd-767 

	LABEL anothergo: 

	# MESSAGE "Enter selection criteria, ACC accept, INT abort"
	#    ATTRIBUTE(yellow)
	LET l_msgresp = kandoomsg("U",1001," ") 

	CONSTRUCT BY NAME l_query_text 
	ON line_code, 
	linegrp_desc 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","gshowline","construct-rptlinegrp-1") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g582 
		RETURN p_line_code 
	END IF 

	LET l_sel_text = 
	"SELECT line_code, linegrp_desc FROM rptlinegrp ", 
	"WHERE cmpy_code = '", p_cmpy_code clipped, "' AND ", 
	l_query_text clipped 

	LABEL anothergo1: 

	PREPARE linegrp_browse FROM l_sel_text 
	DECLARE linegrp_browse_cur CURSOR FOR linegrp_browse 
	OPEN linegrp_browse_cur 

	LET l_idx = 1 

	FOREACH linegrp_browse_cur INTO 
		l_arr_rptlinegrp[l_idx].line_code, 
		l_arr_rptlinegrp[l_idx].linegrp_desc 

		LET l_idx = l_idx + 1 

		IF l_idx > 150 THEN 
			MESSAGE " First 150 only selected "attribute (yellow) 
			EXIT FOREACH 
		END IF 

	END FOREACH 

	LET l_idx = l_idx -1 

	IF l_idx > 0 THEN 
		#MESSAGE "Cursor TO code AND press ACC, F5 menu, F9 re-SELECT, F10 add"
		#  attribute (yellow)
		LET l_msgresp = kandoomsg("G",1610," ") 
	ELSE 
		#MESSAGE "No lines satisfy criteria, F5 menu, F9 re-SELECT F10 add"
		#  attribute (yellow)
		LET l_msgresp = kandoomsg("G",1611," ") 
	END IF 


	LET l_cnt = l_idx 
	CALL set_count(l_idx) 

	LABEL enter_array: 

	INPUT ARRAY l_arr_rptlinegrp WITHOUT DEFAULTS FROM sa_rptlinegrp.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","gshowline","input-arr-rptlinegrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (interrupt) 
			EXIT INPUT 

		ON KEY (F5) 
			CALL run_prog("TOPMENUR", "", "", "", "") 

		ON KEY (F9) 
			CLEAR FORM 
			LET l_try_another = "Y" 
			EXIT INPUT 

		ON KEY (F10) 
			CALL run_prog("GW4", "", "", "", "") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			IF l_idx > l_cnt THEN 
				ERROR "There are no more rows in the direction you are going" 
			END IF 

			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_rptlinegrp[l_idx].* TO sa_rptlinegrp[l_scrn].* 

			END IF 

		AFTER ROW 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_rptlinegrp[l_idx].* TO sa_rptlinegrp[l_scrn].* 

			END IF 

	END INPUT 

	IF l_try_another = "Y" THEN 
		LET l_try_another = "N" 
		#MESSAGE " Enter criteria - press ACC" attribute (yellow)
		LET l_msgresp = kandoomsg("U",1001," ") 

		CONSTRUCT l_fv_query_text 
		ON line_code, 
		linegrp_desc 
		FROM sa_rptlinegrp[1].line_code, 
		sa_rptlinegrp[1].linegrp_desc 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","gshowline","construct-rptlinegrp-2") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW g582 
			RETURN p_line_code 
		END IF 

		LET l_sel_text = 
		"SELECT line_code, linegrp_desc FROM rptlinegrp ", 
		"WHERE cmpy_code = '", p_cmpy_code clipped, "' AND ", 
		l_fv_query_text clipped 

		GOTO anothergo1 

	END IF 

	LET l_idx = arr_curr() 

	IF int_flag THEN 
		INITIALIZE l_arr_rptlinegrp[l_idx].line_code TO NULL 
	END IF 

	LET int_flag = 0 
	LET quit_flag = 0 

	CLOSE WINDOW g582 

	IF l_arr_rptlinegrp[l_idx].line_code IS NULL THEN 
		LET l_arr_rptlinegrp[l_idx].line_code = p_line_code 
	END IF 

	RETURN l_arr_rptlinegrp[l_idx].line_code 

END FUNCTION 
