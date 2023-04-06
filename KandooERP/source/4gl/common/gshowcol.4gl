GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_colgrps(p_cmpy_code,p_col_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_col_code LIKE rptcolgrp.col_code 
   DEFINE l_formname CHAR(15)
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_arr_rptcolgrp array[150] OF RECORD 
					col_code LIKE rptcolgrp.col_code, 
					colgrp_desc LIKE rptcolgrp.colgrp_desc, 
					colrptg_type LIKE rptcolgrp.colrptg_type 
			 END RECORD 
	DEFINE l_sel_text CHAR(2200)
	DEFINE l_fv_query_text CHAR(2048)
	DEFINE l_query_text CHAR(2048)
	DEFINE l_scrn SMALLINT 
	DEFINE l_cnt SMALLINT
	DEFINE l_idx SMALLINT
	DEFINE l_try_another CHAR(1)

	OPEN WINDOW g583 with FORM "G583" 
	CALL windecoration_g("G583") -- albo kd-767 

	LABEL anothergo: 

	# MESSAGE "Enter selection criteria, ACC accept, INT abort"
	#    ATTRIBUTE(yellow)
	LET l_msgresp = kandoomsg("U",1001," ") 

	CONSTRUCT BY NAME l_query_text 
	ON col_code, 
	colgrp_desc, 
	colrptg_type 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","gshowcol","construct-rptcolgrp-1") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g583 
		RETURN p_col_code 
	END IF 

	LET l_sel_text = 
	"SELECT col_code, colgrp_desc, colrptg_type FROM rptcolgrp ", 
	"WHERE cmpy_code = '", p_cmpy_code clipped, "' AND ", l_query_text clipped 

	LABEL anothergo1: 

	PREPARE colgrp_browse FROM l_sel_text 
	DECLARE colgrp_browse_cur CURSOR FOR colgrp_browse 
	OPEN colgrp_browse_cur 

	LET l_idx = 1 

	FOREACH colgrp_browse_cur INTO 
		l_arr_rptcolgrp[l_idx].col_code, 
		l_arr_rptcolgrp[l_idx].colgrp_desc, 
		l_arr_rptcolgrp[l_idx].colrptg_type 

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
		#MESSAGE "No columns satisfy criteria, F5 menu, F9 re-SELECT, F10 add"
		#  attribute (yellow)
		LET l_msgresp = kandoomsg("G",1611," ") 
	END IF 


	LET l_cnt = l_idx 
	CALL set_count(l_idx) 

	LABEL enter_array: 

	INPUT ARRAY l_arr_rptcolgrp WITHOUT DEFAULTS FROM sa_rptcolgrp.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","gshowcol","input-arr-rptcolgrp") 

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
			CALL run_prog("GW3", "", "", "", "") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			IF l_idx > l_cnt THEN 
				ERROR "There are no more rows in the direction you are going" 
			END IF 

			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_rptcolgrp[l_idx].* TO sa_rptcolgrp[l_scrn].* 

			END IF 

		AFTER ROW 
			IF l_idx <= l_cnt THEN 
				DISPLAY l_arr_rptcolgrp[l_idx].* TO sa_rptcolgrp[l_scrn].* 

			END IF 

	END INPUT 

	IF l_try_another = "Y" THEN 
		LET l_try_another = "N" 
		#MESSAGE " Enter criteria - press ACC" attribute (yellow)
		LET l_msgresp = kandoomsg("U",1001," ") 

		CONSTRUCT l_fv_query_text 
		ON col_code, 
		colgrp_desc, 
		colrptg_type 
		FROM sa_rptcolgrp[1].col_code, 
		sa_rptcolgrp[1].colgrp_desc, 
		sa_rptcolgrp[1].colrptg_type 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","gshowcol","construct-rptcolgrp-2") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW g583 
			RETURN p_col_code 
		END IF 

		LET l_sel_text = 
		"SELECT col_code, colgrp_desc, colrptg_type FROM rptcolgrp ", 
		"WHERE cmpy_code = '", p_cmpy_code clipped, "' AND ", 
		l_fv_query_text clipped 

		GOTO anothergo1 

	END IF 

	LET l_idx = arr_curr() 

	IF int_flag THEN 
		INITIALIZE l_arr_rptcolgrp[l_idx].col_code TO NULL 
	END IF 

	LET int_flag = 0 
	LET quit_flag = 0 

	CLOSE WINDOW g583 

	IF l_arr_rptcolgrp[l_idx].col_code IS NULL THEN 
		LET l_arr_rptcolgrp[l_idx].col_code = p_col_code 
	END IF 

	RETURN l_arr_rptcolgrp[l_idx].col_code 

END FUNCTION 
