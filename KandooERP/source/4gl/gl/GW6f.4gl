{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6f.4gl
# Purpose - This file contains the functions used in the picklist FOR
#           the table rpthead_group.
# Functions:
#                 pick_rptgrp()
#                 w_query_rptgrp()
#                 w_load_rptgrp()
#                 get_descript_rptgrpation()

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW6_GLOBALS.4gl" 


############################################################
# GLOBAL Scope Variables
############################################################
DEFINE modu_arr_rec_browse_rec DYNAMIC ARRAY OF RECORD #array[200] OF RECORD 
	rptgrp_id LIKE rpthead_group.rptgrp_id, 
	rptgrp_text LIKE rpthead_group.rptgrp_text 
END RECORD 


############################################################
# FUNCTION pick_rptgrp(p_cmpy_code)
#
#
############################################################
FUNCTION pick_rptgrp(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE rpthead_group.cmpy_code 
	DEFINE l_record_count INTEGER 
	DEFINE l_another_selection SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_formname CHAR(15) 

	# WHENEVER ERROR CONTINUE

	OPEN WINDOW w2_pick_rptgrp with FORM "G568" 
	#OPEN WINDOW w2_pick_rptgrp AT 9,22 WITH FORM "w_rptgrp" ## used TO be w_rptgrp
	CALL windecoration_g("G568") 

	WHILE true --- loop until user aborts OR selects a RECORD 

		CLEAR FORM 

		--- Allow user TO use QBE, IF aborted the RETURN NULLS TO calling FUNCTION

		IF w_query_rptgrp(p_cmpy_code) THEN 

			CLOSE WINDOW w2_pick_rptgrp 
			--INITIALIZE modu_arr_rec_browse_rec[1].* TO NULL 
			RETURN modu_arr_rec_browse_rec[1].* 
		END IF 

		LET l_record_count = w_load_rpthead_group() 

		--- IF no records were found THEN DISPLAY a MESSAGE AND LET the user try again

		IF l_record_count = 0 THEN 

			MESSAGE "No records found, please redefine your selection criteria" 

			SLEEP 2 

			CONTINUE WHILE 
		END IF 

		--- IF only one RECORD was found THEN RETURN it TO the calling FUNCTION

		{
		    IF l_record_count = 0 THEN

		        CLOSE WINDOW w2_pick_rptgrp
		        RETURN modu_arr_rec_browse_rec[1].*
		    END IF
		}

		LET l_another_selection = false 

		MESSAGE "[INTERRUPT] TO abort" 


		DISPLAY l_record_count, " Records found" at 2,1 


		CALL set_count(l_record_count) 

		DISPLAY ARRAY modu_arr_rec_browse_rec TO sa_browse_rec.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","GW6f","disp-arr-browse") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F9) ---------- re-query ---------- 

				LET l_another_selection = true 
				EXIT DISPLAY 

				{
				    ON KEY (CONTROL-M) ---- SELECT FROM PICK LIST KEY ---------

				        EXIT DISPLAY
				}

		END DISPLAY 

		LET l_cnt = arr_curr() 

		IF ( int_flag OR quit_flag ) THEN 

			LET int_flag = false 
			LET quit_flag = false 

			OPTIONS MESSAGE line LAST 
			MESSAGE "Current Process Interrupted" 
			SLEEP 1 
			OPTIONS MESSAGE line FIRST 

			INITIALIZE modu_arr_rec_browse_rec[l_cnt].* TO NULL 
		END IF 

		IF l_another_selection THEN 

			CONTINUE WHILE 
		END IF 

		CLOSE WINDOW w2_pick_rptgrp 
		RETURN modu_arr_rec_browse_rec[l_cnt].* 

	END WHILE 

END FUNCTION 
--- pick_rpthead_group()

------------------------------------------------------------------------------


############################################################
# FUNCTION w_query_rptgrp(p_cmpy_code)
#
#
############################################################
FUNCTION w_query_rptgrp(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE rpthead_group.cmpy_code 
	DEFINE l_construct_fields CHAR(200) 
	DEFINE l_win_query_text CHAR(200) 

	LET l_construct_fields = "1=1" 

	MESSAGE "Enter your search criteria, " 


	DISPLAY "[ESC] TO commence search, [INTERRUPT] TO EXIT" at 2,1 


	CONSTRUCT BY NAME l_construct_fields ON rpthead_group.rptgrp_id, 
	rpthead_group.rptgrp_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GW6f","construct-rpthead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF ( int_flag OR quit_flag ) THEN 

		LET int_flag = false 
		LET quit_flag = false 
		OPTIONS MESSAGE line LAST 
		MESSAGE "Current Process Interrupted" 
		SLEEP 1 
		OPTIONS MESSAGE line FIRST 

		RETURN true 
	END IF 

	DISPLAY "" at 2,1 --- CLEAR 2nd line OF MESSAGE 

	MESSAGE "Retrieving Records. Please wait...." 


	LET l_win_query_text = 
	" SELECT rptgrp_id, rptgrp_text ", 
	" FROM rpthead_group", 
	" WHERE ", l_construct_fields clipped, 
	" AND cmpy_code = '", p_cmpy_code, "' ", 
	" ORDER BY rptgrp_id" 

	PREPARE browse_id FROM l_win_query_text 
	DECLARE browse_curs CURSOR FOR browse_id 
	OPEN browse_curs 

	RETURN false 

END FUNCTION 


############################################################
# FUNCTION w_load_rpthead_group()
#
#
############################################################
FUNCTION w_load_rpthead_group() 
	DEFINE l_idx SMALLINT 

	LET l_idx = 1 

	FOREACH browse_curs INTO modu_arr_rec_browse_rec[l_idx].* 

		LET l_idx = l_idx + 1 
		IF l_idx > 200 THEN 

			--- Restrict the selection of records TO 200 as the ARRAY
			--- has been declared as
			--- 200 FOR system rpthead_group reasons

			MESSAGE "Only the first 200 records selected, " 

			DISPLAY "Please limit your selection" at 2,1 


			EXIT FOREACH 
		END IF 

	END FOREACH 

	CLOSE browse_curs 
	FREE browse_id 

	LET l_idx = l_idx -1 
	RETURN l_idx 

END FUNCTION 

-------------------------------------------------------------------------


############################################################
# FUNCTION get_descript_rptgrpation(p_cmpy_code, p_rptgrp_id)
#
#
############################################################
FUNCTION get_descript_rptgrpation(p_cmpy_code, p_rptgrp_id) 
	DEFINE p_cmpy_code LIKE rpthead_group.cmpy_code 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE l_rptgrp_text LIKE rpthead_group.rptgrp_text 

	INITIALIZE l_rptgrp_text TO NULL 

	SELECT rptgrp_text 
	INTO l_rptgrp_text 
	FROM rpthead_group 
	WHERE rptgrp_id = p_rptgrp_id 
	AND cmpy_code = p_cmpy_code 

	IF status = NOTFOUND THEN 

		RETURN "", false 
	END IF 

	RETURN l_rptgrp_text, true 

END FUNCTION 
