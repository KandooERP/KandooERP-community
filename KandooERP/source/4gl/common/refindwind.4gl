# Purpose - CTRL-B lookup window FOR user defined field types

GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION lookup_refind() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_formname CHAR(15) 
	DEFINE l_arr_ref_ind array[5] OF 
	         RECORD 
					ref_ind CHAR(1), 
					desc_text CHAR(40) 
   			END RECORD 

	OPEN WINDOW w1_m191 with FORM "M191" 
	CALL windecoration_m("M191") -- albo kd-767 

	LET l_msgresp = kandoomsg("M", 1504, "") # MESSAGE "ESC TO SELECT - DEL TO Exit"

	LET l_arr_ref_ind[1].ref_ind = 1 
	LET l_arr_ref_ind[1].desc_text = "Input IS optional with no validation" 
	LET l_arr_ref_ind[2].ref_ind = 2 
	LET l_arr_ref_ind[2].desc_text = "Input IS mandatory with no validation" 
	LET l_arr_ref_ind[3].ref_ind = 3 
	LET l_arr_ref_ind[3].desc_text = "Input IS optional with validation" 
	LET l_arr_ref_ind[4].ref_ind = 4 
	LET l_arr_ref_ind[4].desc_text = "Input IS mandatory with validation" 
	LET l_arr_ref_ind[5].ref_ind = 5 
	LET l_arr_ref_ind[5].desc_text = "Field will be skipped during INPUT" 

	CALL set_count(5) 

	DISPLAY ARRAY l_arr_ref_ind TO sr_ref_ind.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","refindwind","display-arr-ref_ind") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


	END DISPLAY 
	LET l_idx = arr_curr() 

	CLOSE WINDOW w1_m191 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	END IF 

	RETURN l_arr_ref_ind[l_idx].ref_ind 

END FUNCTION 
