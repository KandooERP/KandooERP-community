{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6d.4gl
# Purpose - This file contains the functions used TO
#           SELECT AND scroll through records AND SELECT one (for
#           updating, display-full SCREEN OR deleting) in the rpthead_group
#           group table.  All these functions must be kept in the
#           same file because they use the same module variables,
#           i.e. the module ARRAY AND the CURSOR.

----------------------------------------------------------------------------}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW6_GLOBALS.4gl" 


############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_arr_rec_rpthead_group DYNAMIC ARRAY OF RECORD # array[100] OF RECORD 
	rptgrp_id LIKE rpthead_group.rptgrp_id, 
	rptgrp_text LIKE rpthead_group.rptgrp_text 
END RECORD 


############################################################
# FUNCTION query_rptgrp()
#
#
############################################################
FUNCTION query_rptgrp() 
	DEFINE l_rec_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE l_query_1 CHAR(400) 
	--	DEFINE l_ca_type_id CHAR(1)
	DEFINE l_select_string CHAR(500) 

	LET int_flag = false 
	LET quit_flag = false 

	# WHENEVER ERROR CONTINUE

	--- Set up the form
	CLEAR FORM 

	MESSAGE "Enter search criteria, [ESC] Accept, [INTERRUPT] Exit" 


	--- Get the users criteria

	INITIALIZE l_query_1 TO NULL 

	CONSTRUCT BY NAME l_query_1 ON rpthead_group.rptgrp_id, 
	rpthead_group.rptgrp_text, 
	rpthead_group.rptgrp_desc2 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GW6d","construct-rpthead") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#thiws makes no sense
			--ON KEY (CONTROL-B) ---------- PICK LISTS ----------
			--
			--ERROR "There IS no browse window available FOR this field"


			#    END CASE

	END CONSTRUCT 

	IF interrupted() THEN 

		RETURN false 
	END IF 

	--- Set up the SELECT statment

	CLEAR FORM 

	LET l_select_string = 
	" SELECT rptgrp_id, rptgrp_text ", 
	" FROM rpthead_group ", 
	" WHERE ", l_query_1 clipped, 
	" AND cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
	" ORDER BY rptgrp_id" 

	PREPARE s_1 FROM l_select_string 

	--- Now DECLARE a CURSOR FOR the relevant info in the rptgrpal govt region table

	DECLARE rptgrpstr_curs CURSOR FOR s_1 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
--- query_rpthead_group()


############################################################
# FUNCTION load_array_rptgrp()
#
#
############################################################
FUNCTION load_array_rptgrp() 
	DEFINE l_pa_totsize SMALLINT 
	DEFINE l_records_count INTEGER 

	LET l_pa_totsize = 100 

	FOR l_records_count = 1 TO l_pa_totsize 

		INITIALIZE modu_arr_rec_rpthead_group[l_records_count].* TO NULL 
	END FOR 

	LET l_records_count = 1 

	FOREACH rptgrpstr_curs INTO modu_arr_rec_rpthead_group[l_records_count].* 

		IF int_flag OR quit_flag THEN 
			EXIT FOREACH 
		END IF 

		--   LET l_records_count = l_records_count + 1
		--CALL huhoNeedsFixing("DISPLAY  AT 1,35","GW6d.4gl")
		--    IF l_records_count > l_pa_totsize THEN
		--
		--       MESSAGE "Only the first 100 records selected, "
		--
		--       DISPLAY "Please limit your selection" AT 2,1
		--
		--
		--        EXIT FOREACH
		--    END IF

	END FOREACH 

	LET l_records_count = l_records_count - 1 

	IF interrupted() THEN 
	END IF 

	RETURN l_records_count 

END FUNCTION 
--- query_rpthead_group()

--------------------------------------------------------------------------


############################################################
# FUNCTION scroll_rptgrp(p_records_count)
#
#
############################################################
FUNCTION scroll_rptgrp(p_records_count) 
	DEFINE p_records_count INTEGER 

	--	DEFINE lv_scrn                SMALLINT
	DEFINE lv_idx SMALLINT 
	DEFINE l_copy LIKE rpthead_group.rptgrp_id 
	DEFINE l_last_key INTEGER 
	--	DEFINE l_error_flag          SMALLINT
	DEFINE l_delete_success_flg SMALLINT 
	DEFINE l_found_flag INTEGER 
	DEFINE l_rec_rpthead_group RECORD LIKE rpthead_group.* 
	--	DEFINE l_pa_totsize          SMALLINT
	DEFINE l_counter SMALLINT 

	#OPTIONS ACCEPT KEY F31

	--LET l_pa_totsize = 100

	IF p_records_count = 1 THEN 

		#    OPTIONS ACCEPT KEY ESCAPE

		CALL get_rptgrp(modu_arr_rec_rpthead_group[1].rptgrp_id) 
		RETURNING l_rec_rpthead_group.rptgrp_id, 
		l_rec_rpthead_group.rptgrp_text, 
		l_rec_rpthead_group.rptgrp_desc1, 
		l_rec_rpthead_group.rptgrp_desc2, 
		l_found_flag 


		CALL modify_rptgrp(l_rec_rpthead_group.*) 
		RETURNING modu_arr_rec_rpthead_group[1].*, 
		l_rec_rpthead_group.rptgrp_desc2 

		RETURN 
	END IF 

	OPEN WINDOW w1_rptgrpstr with FORM "G568" 
	CALL windecoration_g("G568") 

	MESSAGE "[ESC]=UPDATE,[INTERRUPT]=abort,[F2]=delete" 


	MESSAGE p_records_count, " Records found" --at 2,1 


	CALL set_count(p_records_count) 

	#OPTIONS INSERT KEY F28,
	#        ACCEPT KEY F31

	INPUT ARRAY modu_arr_rec_rpthead_group WITHOUT DEFAULTS FROM sa_browse_rec.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW6d","inp-rpthead_group") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD rptgrp_id -------------- section ------------- 

			--- stop user FROM overtyping the field

			LET l_copy = modu_arr_rec_rpthead_group[lv_idx].rptgrp_id 

		AFTER FIELD rptgrp_id ---------- AFTER FIELD section --------- 

			--- stop user FROM overtyping the field AND accessing blank lines

			LET modu_arr_rec_rpthead_group[lv_idx].rptgrp_id = l_copy 

			#DISPLAY modu_arr_rec_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*


			LET l_last_key = fgl_lastkey() 

			IF (lv_idx >= p_records_count AND l_last_key = FGL_KEYVAL("DOWN")) 
			OR (lv_idx >= p_records_count - 5 --- (= screen ARRAY size-1) 
			AND l_last_key= fgl_keyval("NEXTPAGE")) THEN 

				ERROR " There are no more rows in the direction you are going " 


				NEXT FIELD rptgrp_id 
			END IF 

		BEFORE FIELD rptgrp_text -------- BEFORE FIELD section --------- 

			--- stop user FROM accessing other fields

			NEXT FIELD previous 

		ON KEY (ESCAPE) ---------- accept KEY ---------- 

			#OPTIONS ACCEPT KEY ESCAPE

			CALL get_rptgrp(modu_arr_rec_rpthead_group[lv_idx].rptgrp_id) 
			RETURNING l_rec_rpthead_group.rptgrp_id, 
			l_rec_rpthead_group.rptgrp_text, 
			l_rec_rpthead_group.rptgrp_desc1, 
			l_rec_rpthead_group.rptgrp_desc2, 
			l_found_flag 

			CALL modify_rptgrp(l_rec_rpthead_group.*) 
			RETURNING modu_arr_rec_rpthead_group[lv_idx].*, 
			l_rec_rpthead_group.rptgrp_desc2 

			#    CALL display_rpthead_group(modu_arr_rec_rpthead_group[lv_idx].*)

			#OPTIONS ACCEPT KEY F31

			CURRENT WINDOW IS w1_rptgrpstr 

			#DISPLAY modu_arr_rec_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*


		ON KEY (F2) --------- DELETE KEY ---------- 

			#OPTIONS ACCEPT KEY ESCAPE

			CALL get_rptgrp(modu_arr_rec_rpthead_group[lv_idx].rptgrp_id) 
			RETURNING l_rec_rpthead_group.rptgrp_id, 
			l_rec_rpthead_group.rptgrp_text, 
			l_rec_rpthead_group.rptgrp_desc1, 
			l_rec_rpthead_group.rptgrp_desc2, 
			l_found_flag 

			LET l_delete_success_flg = remove_rptgrp(l_rec_rpthead_group.*) 

			#OPTIONS ACCEPT KEY F31

			CURRENT WINDOW IS w1_rptgrpstr 

			IF l_delete_success_flg THEN 

				IF p_records_count = 1 THEN 

					--INITIALIZE modu_arr_rec_rpthead_group[1].* TO NULL 
					--DISPLAY modu_arr_rec_rpthead_group[1].* TO sa_browse_rec[1].* 

				ELSE 

					FOR l_counter = arr_curr() TO (p_records_count -1) 

						LET modu_arr_rec_rpthead_group[l_counter].* = modu_arr_rec_rpthead_group[l_counter+1].* 
					END FOR 

					INITIALIZE modu_arr_rec_rpthead_group[p_records_count].* TO NULL 

					LET p_records_count = p_records_count - 1 

					IF lv_idx > p_records_count THEN 

						LET lv_idx = lv_idx -1 
						#LET lv_scrn = lv_scrn -1
					END IF 

					IF lv_idx = 0 THEN 
						EXIT INPUT 
					END IF 

					DISPLAY p_records_count, " Records found" at 2,1 


					CALL set_count(p_records_count) 

					#FOR l_counter = SCR_LINE() TO 6 --- SCREEN ARRAY size
					#
					#                DISPLAY modu_arr_rec_rpthead_group[lv_idx + l_counter - lv_scrn].*
					#                     TO sa_browse_rec[l_counter].*
					#
					#            END FOR

					#DISPLAY modu_arr_rec_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*

				END IF 

				OPTIONS MESSAGE line LAST 
				MESSAGE "Record Deleted Successfully" 
				SLEEP 1 
				OPTIONS MESSAGE line FIRST 

			END IF 

			NEXT FIELD rptgrp_id 

		BEFORE ROW ---------------------- section ---------------------- 

			LET lv_idx = arr_curr() 
			#LET lv_scrn = scr_line()

			#DISPLAY modu_arr_rec_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*


			#AFTER ROW ---------------------- SECTION ----------------------

			#DISPLAY modu_arr_rec_rpthead_group[lv_idx].* TO sa_browse_rec[lv_scrn].*



	END INPUT 

	CALL set_options() 

	CLOSE WINDOW w1_rptgrpstr 

END FUNCTION 
--- scroll_rpthead_group(p_records_count)

------------------------------------------------------------------------------

FUNCTION close_cursor_rptgrp() 

	CLOSE rptgrpstr_curs 

	FREE s_1 

END FUNCTION 
--- close_cursor_rpthead_group()

------------------------------------------------------------------------------
