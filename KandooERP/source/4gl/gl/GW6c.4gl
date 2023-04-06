{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - GW6c.4gl
# Purpose - This file contains the functions used TO
#           SELECT AND scroll through records AND SELECT one (for
#           updating, display-full SCREEN OR deleting) in the rpthead
#           table.  All these functions must be kept in the
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
DEFINE modu_arr_rec_rpt DYNAMIC ARRAY OF RECORD #array[100] OF RECORD 
	rpt_id LIKE rpthead.rpt_id, 
	rpt_text LIKE rpthead.rpt_text 
END RECORD 

--------------------------------------------------------------------------

############################################################
# FUNCTION query_rpt(p_rptgrp_id)
#
#
############################################################
FUNCTION query_rpt(p_rptgrp_id) 

	DEFINE p_rptgrp_id LIKE rpthead_group.rptgrp_id 
	DEFINE lr_dummy RECORD LIKE rpthead_group.* 
	DEFINE lv_ca_type_id CHAR(1) 
	DEFINE lv_select_string CHAR(500) 

	# WHENEVER ERROR CONTINUE

	--- Set up the form
	# CLEAR FORM


	--- Set up the SELECT statment

	# CLEAR FORM

	LET lv_select_string = 

	"SELECT UNIQUE rpthead.rpt_id, ", 
	" rpthead.rpt_text ", 
	" FROM rpthead_struct, rpthead ", 
	" WHERE rpthead_struct.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code), "' ", 
	" AND rpthead_struct.rptgrp_id = '", trim(p_rptgrp_id), "' ", 
	" AND rpthead.cmpy_code = rpthead_struct.cmpy_code ", 
	" AND rpthead.rpt_id = rpthead_struct.rpt_id " 


	PREPARE s_2 FROM lv_select_string 

	--- Now DECLARE a CURSOR FOR the relevant info in the rptgrpal govt region table

	DECLARE brrptgrp_curs CURSOR FOR s_2 

	IF error_trap(status) THEN 

		RETURN false 
	END IF 

	RETURN true 

END FUNCTION 
--- query_rpthead_group()

------------------------------------------------------------------------------

############################################################
# FUNCTION load_array_rpt()
#
#
############################################################
FUNCTION load_array_rpt() 
	DEFINE l_pa_totsize SMALLINT 
	DEFINE l_records_count INTEGER 

	LET l_pa_totsize = 100 

	FOR l_records_count = 1 TO l_pa_totsize 

		INITIALIZE modu_arr_rec_rpt[l_records_count].* TO NULL 
	END FOR 

	LET l_records_count = 1 

	FOREACH brrptgrp_curs INTO modu_arr_rec_rpt[l_records_count].* 

		IF int_flag OR quit_flag THEN 
			EXIT FOREACH 
		END IF 

		LET l_records_count = l_records_count + 1 

		IF l_records_count > l_pa_totsize THEN 

			MESSAGE "Only the first 100 records selected, " 

			DISPLAY "Please limit your selection" TO lblabel2 -- 2,1 


			EXIT FOREACH 
		END IF 

	END FOREACH 

	LET l_records_count = l_records_count - 1 

	IF interrupted() THEN 
	END IF 

	RETURN l_records_count 

END FUNCTION 
--- query_rpthead_group()

--------------------------------------------------------------------------

############################################################
# FUNCTION scroll_rpt(p_records_count, p_rpthead_group)
#
#
############################################################
FUNCTION scroll_rpt(p_records_count, p_rpthead_group) 
	DEFINE p_records_count INTEGER 
	DEFINE p_rpthead_group RECORD LIKE rpthead_group.* 

	#DEFINE lv_scrn                SMALLINT
	DEFINE l_cnt SMALLINT 
	--DEFINE l_forcnt              SMALLINT
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_cnt SMALLINT 
	DEFINE l_flag CHAR(3) 
	--DEFINE l_copy                LIKE rpthead_group.rptgrp_id
	DEFINE l_last_key INTEGER 
	--DEFINE l_error_flag          SMALLINT
	--DEFINE l_delete_success_flg  SMALLINT
	DEFINE l_found_flag INTEGER 
	DEFINE l_pa_totsize SMALLINT 
	DEFINE l_counter SMALLINT 
	--DEFINE l_mesgno              CHAR(1)
	DEFINE l_copy RECORD 

		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text 

	END RECORD 

	LET l_pa_totsize = 100 
	LET l_flag = NULL 
	--LET l_forcnt = "0"

	CREATE temp TABLE tmp_rpthead 
	( 
	cmpy_code CHAR(2), 
	rptgrp_id CHAR(10), 
	rpt_id CHAR(10) 
	) 

	OPEN WINDOW w1_rpt with FORM "G567" ### used TO be w_rptbrw 
	CALL windecoration_g("G567") 

	CALL set_options() 

	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 

	--CALL huhoNeedsFixing("DISPLAY  AT 2,1","GW6c.4gl")

	--DISPLAY "  INPUT" AT 4, 9


	#MESSAGE "[CTRL-B]=brwse,[ESC]=accpt,[F2]=del,[F1]=ins"


	#DISPLAY p_records_count, " Records found" AT 2,1
	MESSAGE trim(p_records_count), " Records found" 




	#CALL SET_COUNT(p_records_count)

	INPUT ARRAY modu_arr_rec_rpt WITHOUT DEFAULTS FROM sa_browse_rec.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW6c","inp-arr-rpt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD rpt_id ---------- AFTER FIELD section --------- 

			LET l_idx = arr_curr() 
			#LET lv_scrn = scr_line()

			#   LET l_cnt = "0"
			#   LET l_found_flag = FALSE
			LET l_arr_cnt = l_idx 

			FOR l_idx = 1 TO arr_count() 

				IF l_idx != l_arr_cnt 
				AND modu_arr_rec_rpt[l_idx].rpt_id IS NOT NULL THEN 

					IF modu_arr_rec_rpt[l_idx].rpt_id = modu_arr_rec_rpt[l_arr_cnt].rpt_id THEN 

						ERROR "This REPORT has already been selected" 


						NEXT FIELD rpt_id 
					END IF 
				END IF 
			END FOR 

			LET l_idx = l_arr_cnt 

			IF modu_arr_rec_rpt[l_idx].rpt_id IS NOT NULL THEN 

				CALL valid_rpt(modu_arr_rec_rpt[l_idx].*) 
				RETURNING modu_arr_rec_rpt[l_idx].*, l_found_flag 

				IF l_found_flag THEN 

					LET l_found_flag = false 
					NEXT FIELD rpt_id 
				END IF 
			END IF 

			#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*


			LET l_last_key = fgl_lastkey() 

			LET p_records_count = arr_count() 

			IF (l_idx >= p_records_count AND l_last_key = FGL_KEYVAL("DOWN")) 
			OR (l_idx >= p_records_count - 5 --- (= screen ARRAY size-1) 
			AND l_last_key= fgl_keyval("NEXTPAGE")) THEN 

				ERROR " There are no more rows in the direction you are going " 


				NEXT FIELD previous 
			END IF 


		BEFORE FIELD rpt_text 
			NEXT FIELD NEXT 

			---------- BROWSE KEY ----------
		ON ACTION "LOOKUP" infield(rpt_id) 
			LET l_idx = arr_curr() 
			DELETE FROM tmp_rpthead 

			FOR l_cnt = 1 TO arr_count() 
				IF modu_arr_rec_rpt[l_cnt].rpt_id IS NULL THEN 
					LET modu_arr_rec_rpt[l_cnt].rpt_id = "###" 
				END IF 
				INSERT INTO tmp_rpthead 
				VALUES 
				(glob_cmpy_code,p_rpthead_group.rptgrp_id,modu_arr_rec_rpt[l_cnt].rpt_id) 
			END FOR 

			LET l_copy.* = modu_arr_rec_rpt[l_idx].* 

			CALL pick_rpt(p_rpthead_group.rptgrp_id) 
			RETURNING modu_arr_rec_rpt[l_idx].*, l_found_flag 

			CURRENT WINDOW IS w1_rpt 

			IF l_found_flag THEN 

				LET modu_arr_rec_rpt[l_idx].* = l_copy.* 

			END IF 

			CALL set_count(p_records_count) 

			#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*


			--CALL SET_COUNT(p_records_count)



		ON KEY (DELETE) --------- DELETE KEY ---------- 

			LET l_idx = arr_curr() 
			#LET lv_scrn = SCR_LINE()

			IF p_records_count <= 1 THEN 

				--INITIALIZE modu_arr_rec_rpt[1].* TO NULL 
				--DISPLAY modu_arr_rec_rpt[1].* TO sa_browse_rec[1].* 

			ELSE 

				LET p_records_count = arr_count() 

				FOR l_counter = arr_curr() TO (p_records_count -1) 

					LET modu_arr_rec_rpt[l_counter].* = modu_arr_rec_rpt[l_counter+1].* 
				END FOR 

				INITIALIZE modu_arr_rec_rpt[p_records_count].* TO NULL 

				LET p_records_count = p_records_count - 1 

				IF l_idx > p_records_count THEN 

					LET l_idx = l_idx -1 
					#LET lv_scrn = lv_scrn -1
				END IF 

				IF l_idx = 0 THEN 
					EXIT INPUT 
				END IF 

				#DISPLAY p_records_count, " Records found" AT 2,1
				MESSAGE trim(p_records_count), " Records found" 


				CALL set_count(p_records_count) 

				LET p_records_count = arr_count() 

				#FOR l_counter = SCR_LINE() TO 6 --- SCREEN ARRAY size
				#
				#                 DISPLAY modu_arr_rec_rpt[l_idx + l_counter - lv_scrn].*
				#                      TO sa_browse_rec[l_counter].*
				#
				#             END FOR

				#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*

			END IF 


			NEXT FIELD previous 


		BEFORE ROW ---------------------- section ---------------------- 

			LET l_idx = arr_curr() 
			#LET lv_scrn = scr_line()
			LET p_records_count = arr_count() 

			#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*


		AFTER ROW ---------------------- section ---------------------- 

			LET l_idx = arr_curr() 
			#LET lv_scrn = scr_line()
			LET p_records_count = arr_count() 

			#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*



		BEFORE INSERT 
			INITIALIZE modu_arr_rec_rpt[l_idx].* TO NULL 

			#DISPLAY modu_arr_rec_rpt[l_idx].* TO sa_browse_rec[lv_scrn].*



		AFTER INPUT 

			CALL set_options() 

			IF interrupted() THEN 
				LET l_flag = "ESC" 
				EXIT INPUT 
			END IF 


			DELETE FROM rpthead_struct 
			WHERE rpthead_struct.rptgrp_id = p_rpthead_group.rptgrp_id 
			AND rpthead_struct.cmpy_code = glob_cmpy_code 


			FOR l_idx = 1 TO arr_count() 

				IF modu_arr_rec_rpt[l_idx].rpt_id IS NOT NULL THEN 

					LET l_cnt = "0" 

					SELECT count(*) 
					INTO l_cnt 
					FROM rpthead_struct 
					WHERE rpthead_struct.cmpy_code = glob_cmpy_code 
					AND rpthead_struct.rptgrp_id = p_rpthead_group.rptgrp_id 
					AND rpthead_struct.rpt_id = modu_arr_rec_rpt[l_idx].rpt_id 

					IF l_cnt <= "0" THEN 

						INSERT INTO rpthead_struct 
						VALUES (glob_cmpy_code, p_rpthead_group.rptgrp_id, modu_arr_rec_rpt[l_idx].rpt_id ) 
					END IF 


				END IF 

			END FOR 

			EXIT INPUT 


	END INPUT 

	CLOSE WINDOW w1_rpt 

	IF fgl_find_table("tmp_rpthead") THEN
		DROP TABLE tmp_rpthead 
	END IF	


	IF l_flag IS NULL THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 

END FUNCTION 


############################################################
# FUNCTION valid_rpt(p_rec_rpt)
#
#
############################################################
FUNCTION valid_rpt(p_rec_rpt) 
	DEFINE p_rec_rpt RECORD 
		rpt_id LIKE rpthead.rpt_id, 
		rpt_text LIKE rpthead.rpt_text 
	END RECORD 

	SELECT unique rpthead.rpt_id, rpthead.rpt_text 
	INTO p_rec_rpt.rpt_id, 
	p_rec_rpt.rpt_text 
	FROM rpthead, rptcolgrp 
	WHERE rpthead.rpt_id = p_rec_rpt.rpt_id 
	AND rpthead.cmpy_code = glob_cmpy_code 
	AND rptcolgrp.colrptg_type in ("AA", "AD") 
	AND rpthead.col_code = rptcolgrp.col_code 
	AND rpthead.cmpy_code = rptcolgrp.cmpy_code 

	IF status = NOTFOUND THEN 

		ERROR "This REPORT does NOT exist in the database" 


		RETURN p_rec_rpt.rpt_id, 
		p_rec_rpt.rpt_text, 
		true 
	ELSE 

		RETURN p_rec_rpt.rpt_id, 
		p_rec_rpt.rpt_text, 
		false 

	END IF 

END FUNCTION 


############################################################
# FUNCTION init_array_rpt()
#
#
############################################################
FUNCTION init_array_rpt() 

	DEFINE l_idx INTEGER 
	DEFINE l_arr_size INTEGER 

	LET l_arr_size = "100" 

	FOR l_idx = 1 TO l_arr_size 
		INITIALIZE modu_arr_rec_rpt[l_idx].* TO NULL 
	END FOR 

END FUNCTION 


############################################################
# FUNCTION close_cursor_rpt()
#
#
############################################################
FUNCTION close_cursor_rpt() 

	CLOSE brrptgrp_curs 

	FREE s_2 

END FUNCTION 

------------------------------------------------------------------------------
