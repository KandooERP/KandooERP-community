{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6e.4gl
# Purpose - Manegement REPORT Groups Maintenance
# Purpose - This file contains the functions used in the picklist FOR
#           the table rpthead.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW6_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_arr_rec_browse_rec DYNAMIC ARRAY OF RECORD #array[100] OF record# 
	rpt_id LIKE rpthead.rpt_id, 
	rpt_text LIKE rpthead.rpt_text 
END RECORD 

-----------------------------------------------------------------------------
############################################################
# FUNCTION pick_rpt(p_rptgrp_id)
#
#
############################################################
FUNCTION pick_rpt(p_rptgrp_id) 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE l_record_count INTEGER 
	DEFINE l_another_selection SMALLINT 
	DEFINE l_cnt SMALLINT 

	# WHENEVER ERROR CONTINUE

	OPEN WINDOW w2_pick_rpt with FORM "G567" ### used TO be w_rptbrw 
	#OPEN WINDOW w2_pick_rpt AT 10,24 WITH FORM "MRW02"	### Used TO be w_rptbrw
	#     ATTRIBUTE (BORDER, WHITE)
	CALL windecoration_g("G567") 

	WHILE true --- loop until user aborts OR selects a RECORD 

		CLEAR FORM 

		--- Allow user TO use QBE, IF aborted the RETURN NULLS TO calling FUNCTION

		IF w_query_rpt(p_rptgrp_id) THEN 

			CLOSE WINDOW w2_pick_rpt 
			--INITIALIZE modu_arr_rec_browse_rec[1].* TO NULL 
			RETURN modu_arr_rec_browse_rec[1].*, true 
		END IF 

		LET l_record_count = w_load_rpt() 

		--- IF no records were found THEN DISPLAY a MESSAGE AND LET the user try again

		IF l_record_count = 0 THEN 

			MESSAGE "No records found, please redefine your selection criteria" 


			CONTINUE WHILE 
		END IF 

		--- IF only one RECORD was found THEN RETURN it TO the calling FUNCTION

		IF l_record_count = 1 THEN 

			CLOSE WINDOW w2_pick_rpt 
			RETURN modu_arr_rec_browse_rec[1].*, false 
		END IF 

		LET l_another_selection = false 

		MESSAGE "[ESC] TO SELECT, [INTERRUPT] TO abort" 


		DISPLAY l_record_count, " Records found" at 2,1 


		CALL set_count(l_record_count) 

		DISPLAY ARRAY modu_arr_rec_browse_rec TO sa_browse_rec.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","GW6e","disp-arr-browse") 

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

		IF interrupted() THEN --- make the FUNCTION RETURN nulls 

			INITIALIZE modu_arr_rec_browse_rec[l_cnt].* TO NULL 
			CLOSE WINDOW w2_pick_rpt 
			RETURN modu_arr_rec_browse_rec[l_cnt].*, true 
		END IF 

		IF l_another_selection THEN 

			CONTINUE WHILE 
		END IF 

		CLOSE WINDOW w2_pick_rpt 
		RETURN modu_arr_rec_browse_rec[l_cnt].*, false 

	END WHILE 

END FUNCTION 
--- pick_rpthead()

------------------------------------------------------------------------------


############################################################
# FUNCTION w_query_rpt(p_rptgrp_id)
#
#
############################################################
FUNCTION w_query_rpt(p_rptgrp_id) 
	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE l_construct_fields, lv_win_query_text CHAR(600) 

	LET l_construct_fields = "1=1" 

	MESSAGE "Enter your search criteria, " 

	DISPLAY "[ESC] TO commence search, [INTERRUPT] TO EXIT" at 2,1 


	CONSTRUCT BY NAME l_construct_fields ON rpthead.rpt_id, 
	rpthead.rpt_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GW6e","construct-rpthead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF interrupted() THEN 

		RETURN true 
	END IF 

	DISPLAY "" at 2,1 --- CLEAR 2nd line OF qbe-2line MESSAGE 

	MESSAGE "Retrieving Records. Please wait...." 


	LET lv_win_query_text = 
	" SELECT UNIQUE rpt_id, rpt_text ", 
	" FROM rpthead, rptcolgrp", 
	" WHERE ", l_construct_fields clipped, 
	" AND rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND rpthead.col_code = rptcolgrp.col_code ", 
	" AND rpthead.cmpy_code = rptcolgrp.cmpy_code ", 
	" AND colrptg_type IN ('AA', 'AD') ", 
	" AND rpthead.rpt_id NOT IN ( ", 
	" SELECT tmp_rpthead.rpt_id ", 
	" FROM tmp_rpthead ", 
	" WHERE tmp_rpthead.cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" AND tmp_rpthead.rptgrp_id = '", p_rptgrp_id ,"' ) ", 

	" ORDER BY rpt_id" 


	PREPARE browse_id FROM lv_win_query_text 
	DECLARE browse_curs CURSOR FOR browse_id 
	OPEN browse_curs 

	RETURN false 

END FUNCTION 
--- w_query_rpthead()

------------------------------------------------------------------------------


############################################################
# FUNCTION w_load_rpt()
#
#
############################################################
FUNCTION w_load_rpt() 
	DEFINE l_idx SMALLINT 

	LET l_idx = 1 

	FOREACH browse_curs INTO modu_arr_rec_browse_rec[l_idx].* 

		LET l_idx = l_idx + 1 
		IF l_idx > 100 THEN 

			--- Restrict the selection of records TO 100 as the ARRAY
			--- has been declared as
			--- 100 FOR system rpthead reasons


			MESSAGE "Only the first 100 records selected, " 

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

{ ###############

FUNCTION get_descript_rpt(pv_loc_code)

DEFINE pv_loc_code          LIKE rpthead.rpt_id
DEFINE pv_loc_desc          LIKE rpthead.rpt_text

INITIALIZE pv_loc_desc TO NULL

SELECT rpt_text
  INTO pv_loc_desc
  FROM rpthead
 WHERE rpt_id = pv_loc_code
   AND cmpy_code = glob_cmpy_code

IF STATUS = NOTFOUND THEN

    RETURN "", FALSE
END IF

IF error_trap(STATUS) THEN

    RETURN "", FALSE
END IF

RETURN pv_loc_desc, TRUE

END FUNCTION

############### }
