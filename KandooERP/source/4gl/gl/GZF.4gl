# GZF - Account Group Maintenance G579

{
###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################

	Source code beautified by beautify.pl on 2020-01-03 14:29:03	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GZF - Maintain account groups


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_formname CHAR(15) 
	#DEFINE glob_ans             CHAR(1) not used
	DEFINE glob_acct_length LIKE structure.length_num 
	DEFINE glob_rec_acctgrp RECORD LIKE acctgrp.* 

	DEFINE glob_arr_rec_acctgrp DYNAMIC ARRAY OF RECORD # array[300] OF 
		group_code LIKE acctgrp.group_code, 
		desc_text LIKE acctgrp.desc_text 
	END RECORD 
END GLOBALS 


############################################################
# MAIN
#
#
############################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("GZF") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	CALL fgl_winmessage("Sources partially missing","The sources have been partially missing\nalso missing FROM the manual\nNeeds TO be done when we know more","info") 

	# pv_acct_length IS used TO determine whether an account has been fully entered,
	# WHEN using a FROM-TO account selection.
	SELECT sum(length_num) 
	INTO glob_acct_length 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	OPEN WINDOW g579 with FORM "G579" 
	CALL windecoration_g("G579") 

	CALL formtitleupdate() --huho 
	WHILE true 
		CLEAR FORM 
		CALL acctgrp_maint() 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW g579 

END MAIN 


############################################################
# FUNCTION acctgrp_maint()
#
#
############################################################
FUNCTION acctgrp_maint() 
	DEFINE l_scr SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_cont_loop SMALLINT 
	DEFINE l_added SMALLINT 
	DEFINE l_reselect SMALLINT 
	DEFINE l_where_part CHAR(550) 
	DEFINE l_select_text CHAR(550) 
	DEFINE l_rec_acctgrpdetl RECORD LIKE acctgrpdetl.* 
	DEFINE l_x SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LABEL acctgrp_construct: 

	CLEAR FORM 

	FOR l_idx = 1 TO 300 
		INITIALIZE glob_arr_rec_acctgrp[l_idx].* TO NULL 
	END FOR 

	# "Enter search criteria - ACC TO search"

	LET l_msgresp = kandoomsg("U",1001," ") 

	CONSTRUCT BY NAME l_where_part 
	ON acctgrp.group_code, 
	acctgrp.desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZF","accGroupMaintQuery") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	LET l_select_text = "SELECT * FROM acctgrp WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, 
	"' AND ", l_where_part clipped, 
	" ORDER BY cmpy_code, group_code" 

	PREPARE sel_grps FROM l_select_text 
	DECLARE grp_curs CURSOR FOR sel_grps 

	LET l_x = 0 
	FOREACH grp_curs INTO glob_rec_acctgrp.* 
		LET l_x = l_x + 1 
		#        IF l_x > 300 THEN
		#            LET l_x = 300
		#            ERROR "Only first 300 definitions displayed"
		#            EXIT FOREACH
		#        ELSE
		LET glob_arr_rec_acctgrp[l_x].group_code = glob_rec_acctgrp.group_code 
		LET glob_arr_rec_acctgrp[l_x].desc_text = glob_rec_acctgrp.desc_text 
		#        END IF
	END FOREACH 

	IF l_x = 0 THEN 
		MESSAGE "No account groups meet selection criteria" 

		SLEEP 1 
	END IF 

	#    CALL set_count(l_x)

	MESSAGE "F1 add, F2 delete, RETURN TO UPDATE, F9 Reselect, ", 
	"Ctrl-V View accounts" 


	LET l_reselect = false 


	WHILE true 

		LET l_cont_loop = false 

		INPUT ARRAY glob_arr_rec_acctgrp 
		WITHOUT DEFAULTS 
		FROM sa_acctgrp.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZF","accGroupMaintList") 

			ON ACTION "WEB-HELP" 

				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "EDIT" 
				IF glob_arr_rec_acctgrp[l_idx + 1].group_code IS NULL 
				OR glob_arr_rec_acctgrp[l_idx + 1].group_code = " " THEN 
					IF fgl_lastkey() = fgl_keyval("down") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") THEN 
						ERROR "Use F1 TO INSERT" 
						NEXT FIELD group_code 
					END IF 
				END IF 

				IF glob_arr_rec_acctgrp[l_idx].group_code <> glob_rec_acctgrp.group_code THEN 
					ERROR "You cannot change a group code name" 
					LET glob_arr_rec_acctgrp[l_idx].group_code = glob_rec_acctgrp.group_code 
					DISPLAY glob_arr_rec_acctgrp[l_idx].group_code 
					TO sa_acctgrp[l_scr].group_code 
					NEXT FIELD group_code 
				END IF 

				CALL upd_grp_dtl(MODE_CLASSIC_UPDATE) 
				RETURNING l_added 
				LET glob_arr_rec_acctgrp[l_idx].desc_text = glob_rec_acctgrp.desc_text 
				DISPLAY glob_arr_rec_acctgrp[l_idx].desc_text 
				TO sa_acctgrp[l_scr].desc_text 

				NEXT FIELD group_code 



			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scr = scr_line() 
				LET glob_rec_acctgrp.group_code = glob_arr_rec_acctgrp[l_idx].group_code 
				LET glob_rec_acctgrp.desc_text = glob_arr_rec_acctgrp[l_idx].desc_text 

			BEFORE INSERT 
				CALL upd_grp_dtl(MODE_CLASSIC_ADD) 
				RETURNING l_added 
				IF l_added THEN 
					LET glob_arr_rec_acctgrp[l_idx].group_code = glob_rec_acctgrp.group_code 
					LET glob_arr_rec_acctgrp[l_idx].desc_text = glob_rec_acctgrp.desc_text 
				ELSE 
					INITIALIZE glob_arr_rec_acctgrp[l_idx].* TO NULL 
					INITIALIZE glob_rec_acctgrp.* TO NULL 
				END IF 

				DISPLAY glob_arr_rec_acctgrp[l_idx].group_code, 
				glob_arr_rec_acctgrp[l_idx].desc_text 
				TO sa_acctgrp[l_scr].group_code, 
				sa_acctgrp[l_scr].desc_text 

			BEFORE DELETE 
				SELECT * 
				FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_grp = glob_arr_rec_acctgrp[l_idx].group_code 

				IF status <> NOTFOUND THEN 
					ERROR "This code IS in use by a REPORT header - can't delete" 
					LET l_cont_loop = true 
					EXIT INPUT 
				END IF 

				DELETE FROM acctgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_arr_rec_acctgrp[l_idx].group_code 

				DELETE FROM acctgrpdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_arr_rec_acctgrp[l_idx].group_code 

			ON KEY (accept) 
				EXIT INPUT 

			ON KEY (F9) 
				LET l_reselect = true 
				EXIT INPUT 

			ON KEY (control-v) 
				SELECT * 
				INTO glob_rec_acctgrp.* 
				FROM acctgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_arr_rec_acctgrp[l_idx].group_code 

				IF status = NOTFOUND THEN 
					ERROR "The group code must be defined before using this ", 
					"function" 
				ELSE 
					CALL show_accounts() 
				END IF 

				#!--AFTER FIELD group_code
				#!--  IF glob_arr_rec_acctgrp[l_idx + 1].group_code IS NULL
				#!--    OR glob_arr_rec_acctgrp[l_idx + 1].group_code = " " THEN
				#!--        IF fgl_lastkey() = fgl_keyval("down")
				#!--          OR fgl_lastkey() = fgl_keyval("right")
				#!--          OR fgl_lastkey() = fgl_keyval("tab") THEN
				#!--              ERROR "Use F1 TO INSERT"
				#!--              NEXT FIELD group_code
				#!--        END IF
				#!--  END IF

				IF glob_arr_rec_acctgrp[l_idx].group_code <> glob_rec_acctgrp.group_code THEN 
					ERROR "You cannot change a group code name" 
					LET glob_arr_rec_acctgrp[l_idx].group_code = glob_rec_acctgrp.group_code 
					DISPLAY glob_arr_rec_acctgrp[l_idx].group_code 
					TO sa_acctgrp[l_scr].group_code 
					NEXT FIELD group_code 
				END IF 


			BEFORE FIELD desc_text 

				CALL upd_grp_dtl(MODE_CLASSIC_UPDATE) 
				RETURNING l_added 
				LET glob_arr_rec_acctgrp[l_idx].desc_text = glob_rec_acctgrp.desc_text 
				DISPLAY glob_arr_rec_acctgrp[l_idx].desc_text 
				TO sa_acctgrp[l_scr].desc_text 

				NEXT FIELD group_code 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		IF NOT l_cont_loop THEN 
			EXIT WHILE 
		END IF 

	END WHILE 


	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	IF l_reselect = true THEN 
		GOTO acctgrp_construct 
	END IF 

END FUNCTION 


############################################################
# FUNCTION upd_grp_dtl(p_add_flag)
#
#
############################################################
FUNCTION upd_grp_dtl(p_add_flag) 
	DEFINE p_add_flag CHAR(6) 
	DEFINE l_added SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_scr SMALLINT 
	DEFINE l_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_count_star SMALLINT 
	DEFINE l_count SMALLINT 
	DEFINE l_insert SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_query_text CHAR(550) 
	DEFINE l_rec_acctgrp RECORD LIKE acctgrp.* 
	DEFINE l_rec_acctgrpdetl RECORD LIKE acctgrpdetl.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_x SMALLINT 
	DEFINE l_arr_rec_acctgrpdetl DYNAMIC ARRAY OF RECORD #array[300] 
		id_num LIKE acctgrpdetl.id_num, 
		subid_num LIKE acctgrpdetl.subid_num, 
		sel_type LIKE acctgrpdetl.sel_type, 
		start_pos LIKE acctgrpdetl.start_pos, 
		start_acct LIKE acctgrpdetl.start_acct, 
		end_acct LIKE acctgrpdetl.end_acct 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 


	LET l_added = 0 

	OPEN WINDOW g580 with FORM "G580" 
	CALL windecoration_g("G580") 

	CALL formtitleupdate() --huho 
	LET l_x = 0 

	IF p_add_flag = MODE_CLASSIC_ADD THEN 
		MESSAGE "Enter Account Group details" 


		INPUT BY NAME l_rec_acctgrp.group_code, l_rec_acctgrp.desc_text 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZF","accGroupMaintEdit") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD group_code 
				IF l_rec_acctgrp.group_code IS NULL 
				OR l_rec_acctgrp.group_code = " " THEN 
					ERROR "Account Group code must be entered" 
					NEXT FIELD group_code 
				END IF 

				SELECT * 
				FROM acctgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = l_rec_acctgrp.group_code 

				IF status <> NOTFOUND THEN 
					ERROR "This group code already exists" 
					NEXT FIELD group_code 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			GOTO exit_grp_dtl 
		END IF 
		LET l_rec_acctgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
		INSERT INTO acctgrp 
		VALUES (l_rec_acctgrp.cmpy_code, 
		l_rec_acctgrp.group_code, 
		l_rec_acctgrp.desc_text) 
		LET glob_rec_acctgrp.cmpy_code = l_rec_acctgrp.cmpy_code 
		LET glob_rec_acctgrp.group_code = l_rec_acctgrp.group_code 
		LET glob_rec_acctgrp.desc_text = l_rec_acctgrp.desc_text 
		LET l_added = 1 

	ELSE 
		DISPLAY BY NAME glob_rec_acctgrp.group_code, glob_rec_acctgrp.desc_text 

		DECLARE dtl_curs CURSOR FOR 
		SELECT * 
		FROM acctgrpdetl 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND group_code = glob_rec_acctgrp.group_code 
		ORDER BY id_num, 
		subid_num 

		FOREACH dtl_curs INTO l_rec_acctgrpdetl.* 
			LET l_x = l_x + 1 
			LET l_arr_rec_acctgrpdetl[l_x].id_num = l_rec_acctgrpdetl.id_num 
			LET l_arr_rec_acctgrpdetl[l_x].subid_num = l_rec_acctgrpdetl.subid_num 
			LET l_arr_rec_acctgrpdetl[l_x].sel_type = l_rec_acctgrpdetl.sel_type 
			LET l_arr_rec_acctgrpdetl[l_x].start_pos = l_rec_acctgrpdetl.start_pos 
			LET l_arr_rec_acctgrpdetl[l_x].start_acct = l_rec_acctgrpdetl.start_acct 
			LET l_arr_rec_acctgrpdetl[l_x].end_acct = l_rec_acctgrpdetl.end_acct 
			DISPLAY l_arr_rec_acctgrpdetl[l_x].* 
			TO sa_acctgrpdetl[l_x].* 
		END FOREACH 

		MESSAGE "Enter/change Account Group description" 


		INPUT BY NAME glob_rec_acctgrp.desc_text WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZF","accGroupMaintEdit") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			AFTER FIELD desc_text 
				UPDATE acctgrp 
				SET desc_text = glob_rec_acctgrp.desc_text 
				WHERE group_code = glob_rec_acctgrp.group_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			GOTO exit_grp_dtl 
		END IF 

	END IF 

	CALL set_count(l_x) 
	MESSAGE "F1 add, F2 delete, RETURN TO UPDATE" 


	INPUT ARRAY l_arr_rec_acctgrpdetl WITHOUT DEFAULTS FROM sa_acctgrpdetl.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZF","accGroupMaintEdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scr = scr_line() 
			LET l_insert = false 
			LET l_rec_acctgrpdetl.id_num = l_arr_rec_acctgrpdetl[l_idx].id_num 
			LET l_rec_acctgrpdetl.subid_num = l_arr_rec_acctgrpdetl[l_idx].subid_num 
			LET l_rec_acctgrpdetl.sel_type = l_arr_rec_acctgrpdetl[l_idx].sel_type 
			LET l_rec_acctgrpdetl.start_pos = l_arr_rec_acctgrpdetl[l_idx].start_pos 
			LET l_rec_acctgrpdetl.start_acct = l_arr_rec_acctgrpdetl[l_idx].start_acct 
			LET l_rec_acctgrpdetl.end_acct = l_arr_rec_acctgrpdetl[l_idx].end_acct 

		BEFORE INSERT 
			LET l_arr_rec_acctgrpdetl[l_idx].id_num = next_avail_id() 
			LET l_arr_rec_acctgrpdetl[l_idx].subid_num 
			= next_avail_subid(l_arr_rec_acctgrpdetl[l_idx].id_num) 

			DISPLAY l_arr_rec_acctgrpdetl[l_idx].id_num, 
			l_arr_rec_acctgrpdetl[l_idx].subid_num 
			TO sa_acctgrpdetl[l_scr].id_num, 
			sa_acctgrpdetl[l_scr].subid_num 

			LET l_insert = true 

		BEFORE DELETE 
			DELETE FROM acctgrpdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND group_code = glob_rec_acctgrp.group_code 
			AND id_num = l_arr_rec_acctgrpdetl[l_idx].id_num 
			AND subid_num = l_arr_rec_acctgrpdetl[l_idx].subid_num 

		ON ACTION "LOOKUP" infield (start_pos) 
			CALL lookup_seg(l_arr_rec_acctgrpdetl[l_idx].start_pos) 
			RETURNING l_arr_rec_acctgrpdetl[l_idx].start_pos 
			DISPLAY l_arr_rec_acctgrpdetl[l_idx].start_pos 
			TO sa_acctgrpdetl[l_scr].start_pos 

		AFTER FIELD id_num 
			IF l_arr_rec_acctgrpdetl[l_idx].id_num IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].id_num = " " THEN 
				ERROR "The Id number must be entered" 
				NEXT FIELD id_num 
			END IF 

			IF l_insert <> true 
			AND l_arr_rec_acctgrpdetl[l_idx].id_num <> l_rec_acctgrpdetl.id_num THEN 
				ERROR "You cannot change an id number" 
				LET l_arr_rec_acctgrpdetl[l_idx].id_num = l_rec_acctgrpdetl.id_num 
				DISPLAY l_arr_rec_acctgrpdetl[l_idx].id_num 
				TO sa_acctgrpdetl[l_scr].id_num 
				NEXT FIELD id_num 
			END IF 

			LET l_rec_acctgrpdetl.id_num = l_arr_rec_acctgrpdetl[l_idx].id_num 

		AFTER FIELD subid_num 
			IF l_arr_rec_acctgrpdetl[l_idx].subid_num IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].subid_num = " " THEN 
				ERROR "The Sub id number must be entered" 
				NEXT FIELD subid_num 
			END IF 

			IF l_insert = true THEN 
				SELECT * FROM acctgrpdetl 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_rec_acctgrp.group_code 
				AND id_num = l_arr_rec_acctgrpdetl[l_idx].id_num 
				AND subid_num = l_arr_rec_acctgrpdetl[l_idx].subid_num 
				IF status <> NOTFOUND THEN 
					ERROR "This sub id already exists FOR this id code" 
					NEXT FIELD subid_num 
				END IF 
			ELSE 
				IF l_arr_rec_acctgrpdetl[l_idx].subid_num 
				<> l_rec_acctgrpdetl.subid_num THEN 
					ERROR "You cannot change a sub id number" 
					LET l_arr_rec_acctgrpdetl[l_idx].subid_num 
					= l_rec_acctgrpdetl.subid_num 
					DISPLAY l_arr_rec_acctgrpdetl[l_idx].subid_num 
					TO sa_acctgrpdetl[l_scr].subid_num 
					NEXT FIELD subid_num 
				END IF 
			END IF 


			LET l_rec_acctgrpdetl.subid_num = l_arr_rec_acctgrpdetl[l_idx].subid_num 

		AFTER FIELD sel_type 
			IF l_arr_rec_acctgrpdetl[l_idx].sel_type IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].sel_type = " " THEN 
				ERROR "Selection type must be entered" 
				NEXT FIELD sel_type 
			END IF 

			IF l_arr_rec_acctgrpdetl[l_idx].sel_type NOT matches "[RSM]" THEN 
				ERROR "Valid selection types are S=segment, R=range, M=matches" 
				NEXT FIELD sel_type 
			END IF 

			LET l_rec_acctgrpdetl.sel_type = l_arr_rec_acctgrpdetl[l_idx].sel_type 

			IF l_arr_rec_acctgrpdetl[l_idx].sel_type <> "S" THEN 
				LET l_arr_rec_acctgrpdetl[l_idx].start_pos = NULL 
				DISPLAY l_arr_rec_acctgrpdetl[l_idx].start_pos 
				TO sa_acctgrpdetl[l_scr].start_pos 
				NEXT FIELD start_acct 
			END IF 

		AFTER FIELD start_pos 
			IF l_arr_rec_acctgrpdetl[l_idx].start_pos IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].start_pos = " " THEN 
				ERROR "Start position must be entered FOR this selection type" 
				NEXT FIELD start_pos 
			END IF 

			SELECT * 
			INTO l_rec_structure.* 
			FROM structure 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = l_arr_rec_acctgrpdetl[l_idx].start_pos 
			AND type_ind <> "F" 
			IF status = NOTFOUND THEN 
				ERROR "Not a valid start position - use CTRL-B TO lookup" 
				NEXT FIELD start_pos 
			END IF 

			LET l_rec_acctgrpdetl.start_pos = l_arr_rec_acctgrpdetl[l_idx].start_pos 

		AFTER FIELD start_acct 
			IF l_arr_rec_acctgrpdetl[l_idx].start_acct IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].start_acct = " " THEN 
				ERROR "Start account / Clause must be entered" 
				NEXT FIELD start_acct 
			END IF 

			LET l_rec_acctgrpdetl.start_acct = l_arr_rec_acctgrpdetl[l_idx].start_acct 

			LET l_length = length(l_rec_acctgrpdetl.start_acct) 

			CASE 
				WHEN l_rec_acctgrpdetl.sel_type = "M" 
					OR l_rec_acctgrpdetl.sel_type = "S" 
					LET l_count = 0 
					LET l_count_star = 0 
					FOR l_pos = 1 TO l_length 
						IF l_rec_acctgrpdetl.start_acct[l_pos] matches ":" THEN 
							ERROR "Use END clause FOR range" 
							NEXT FIELD start_acct 
						END IF 

						IF l_rec_acctgrpdetl.start_acct[l_pos] matches "|" THEN 
							ERROR "This clause too complex - add a new Sub id." 
							NEXT FIELD start_acct 
						END IF 

						IF l_rec_acctgrpdetl.start_acct[l_pos] matches "*?" THEN 
							LET l_count = l_count + 1 
						END IF 

						IF l_rec_acctgrpdetl.start_acct[l_pos] = "*" THEN 
							LET l_count_star = l_count_star + 1 
						END IF 
						IF l_count_star > 2 THEN 
							EXIT FOR 
						END IF 
					END FOR 

					IF l_count_star > 2 THEN 
						ERROR "This IS an invalid clause" 
						NEXT FIELD start_acct 
					END IF 

					FOR l_pos = 1 TO l_length 
						IF l_rec_acctgrpdetl.start_acct[l_pos] = " " THEN 
							ERROR "There must be no embedded spaces in clause" 
							NEXT FIELD start_acct 
						END IF 
					END FOR 

					IF l_rec_acctgrpdetl.sel_type = "S" 
					AND l_length > l_rec_structure.length_num THEN 
						ERROR "This clause too long FOR the length ", 
						"of this segment" 
						NEXT FIELD start_pos 
					END IF 

				WHEN l_rec_acctgrpdetl.sel_type = "R" 
					IF l_length < glob_acct_length THEN 
						ERROR "You must enter a whole account ", 
						"FOR this selection type" 
						NEXT FIELD start_acct 
					END IF 

					FOR l_pos = 1 TO glob_acct_length 
						IF l_rec_acctgrpdetl.start_acct[l_pos] = " " THEN 
							ERROR "There must be no embedded spaces in account" 
							NEXT FIELD start_acct 
						END IF 
					END FOR 

					LET l_arr_rec_acctgrpdetl[l_idx].end_acct 
					= l_arr_rec_acctgrpdetl[l_idx].start_acct 
					DISPLAY l_arr_rec_acctgrpdetl[l_idx].end_acct 
					TO sa_acctgrpdetl[l_scr].end_acct 

			END CASE 

		AFTER FIELD end_acct 
			IF l_arr_rec_acctgrpdetl[l_idx].end_acct IS NULL 
			OR l_arr_rec_acctgrpdetl[l_idx].end_acct = " " THEN 
				IF l_arr_rec_acctgrpdetl[l_idx].sel_type = "R" THEN 
					ERROR "END account IS required FOR this selection type" 
					LET l_arr_rec_acctgrpdetl[l_idx].end_acct = " " 
					DISPLAY l_arr_rec_acctgrpdetl[l_idx].end_acct 
					TO sa_acctgrpdetl[l_scr].end_acct 
					NEXT FIELD end_acct 
				END IF 
			ELSE 
				IF l_arr_rec_acctgrpdetl[l_idx].sel_type matches "[RS]" THEN 
					IF l_arr_rec_acctgrpdetl[l_idx].end_acct[1] = " " THEN 
						ERROR "This field must be left-justified" 
						NEXT FIELD end_acct 
					END IF 

					IF l_arr_rec_acctgrpdetl[l_idx].sel_type = "S" THEN 
						LET l_length = length(l_rec_acctgrpdetl.start_acct) 
						FOR l_pos = 1 TO l_length 
							IF l_rec_acctgrpdetl.start_acct[l_pos] 
							matches "[*?]" THEN 
								ERROR "This field NOT required FOR this ", 
								"type of start clause" 
								LET l_arr_rec_acctgrpdetl[l_idx].end_acct = NULL 
								DISPLAY l_arr_rec_acctgrpdetl[l_idx].end_acct 
								TO sa_acctgrpdetl[l_idx].end_acct 
								NEXT FIELD start_acct 
							END IF 
						END FOR 

						LET l_length = length(l_arr_rec_acctgrpdetl[l_idx].end_acct) 
						FOR l_pos = 1 TO l_length 
							IF l_arr_rec_acctgrpdetl[l_idx].end_acct[l_pos] 
							matches "[|*?:]" THEN 
								ERROR "Cannot use masking OPTIONS FOR range" 
								NEXT FIELD end_acct 
							END IF 
						END FOR 

						IF l_length > l_rec_structure.length_num THEN 
							ERROR "This clause too long FOR the length", 
							" of this segment" 
							NEXT FIELD end_acct 
						END IF 
					END IF 

				ELSE 
					ERROR "END clause NOT required FOR this selection type" 
					LET l_arr_rec_acctgrpdetl[l_idx].end_acct = " " 
					DISPLAY l_arr_rec_acctgrpdetl[l_idx].end_acct 
					TO sa_acctgrpdetl[l_scr].end_acct 
					NEXT FIELD end_acct 
				END IF 
			END IF 

			IF l_rec_acctgrpdetl.sel_type matches "[RS]" 
			AND l_arr_rec_acctgrpdetl[l_idx].end_acct IS NOT NULL 
			AND l_arr_rec_acctgrpdetl[l_idx].end_acct <> " " THEN 
				IF l_arr_rec_acctgrpdetl[l_idx].end_acct 
				< l_rec_acctgrpdetl.start_acct THEN 
					ERROR "'FROM' field IS larger than 'To' field" 
					NEXT FIELD start_acct 
				END IF 
			END IF 

			LET l_rec_acctgrpdetl.end_acct = l_arr_rec_acctgrpdetl[l_idx].end_acct 

			# Check validity of selection
			CASE 
				WHEN l_rec_acctgrpdetl.sel_type = "R" 
					LET l_query_text = 
					"SELECT * FROM coa ", 
					"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
					"AND acct_code >= \"", l_rec_acctgrpdetl.start_acct clipped, 
					"\" ", "AND acct_code <= \"", 
					l_rec_acctgrpdetl.end_acct clipped, "\" ", 
					" ORDER BY acct_code" 

				WHEN l_rec_acctgrpdetl.sel_type = "S" 
					LET l_end_pos = l_rec_acctgrpdetl.start_pos 
					+ l_rec_structure.length_num - 1 

					IF l_rec_acctgrpdetl.end_acct IS NULL 
					OR l_rec_acctgrpdetl.end_acct = " " THEN 
						LET l_query_text = "SELECT * FROM coa ", 
						"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
						"AND acct_code[", l_rec_acctgrpdetl.start_pos clipped, 
						",", l_end_pos clipped, "] matches \"", 
						l_rec_acctgrpdetl.start_acct clipped, "\" ", 
						" ORDER BY acct_code" 
					ELSE 
						LET l_query_text = "SELECT * FROM coa ", 
						"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
						"AND acct_code[", l_rec_acctgrpdetl.start_pos clipped, 
						",", l_end_pos clipped, "] >= \"", 
						l_rec_acctgrpdetl.start_acct clipped, "\" ", 
						"AND acct_code[", l_rec_acctgrpdetl.start_pos clipped, ",", 
						l_end_pos clipped, "] <= \"", 
						l_rec_acctgrpdetl.end_acct clipped, "\" ", 
						" ORDER BY acct_code" 
					END IF 

				WHEN l_rec_acctgrpdetl.sel_type = "M" 
					LET l_query_text = "SELECT * FROM coa ", 
					"WHERE cmpy_code = \"", glob_rec_kandoouser.cmpy_code, "\" ", 
					"AND acct_code matches \"", 
					l_rec_acctgrpdetl.start_acct clipped, "\" ", 
					" ORDER BY acct_code" 

			END CASE 

			WHENEVER ERROR CONTINUE 
			PREPARE test_curs FROM l_query_text 
			IF status THEN 
				ERROR "You have entered an invalid clause" 
				NEXT FIELD sel_type 
			END IF 
			WHENEVER ERROR stop 

			IF l_insert = true THEN 
				IF l_arr_rec_acctgrpdetl[l_idx].id_num IS NOT NULL 
				AND l_arr_rec_acctgrpdetl[l_idx].id_num <> " " 
				AND l_arr_rec_acctgrpdetl[l_idx].subid_num IS NOT NULL 
				AND l_arr_rec_acctgrpdetl[l_idx].subid_num <> " " 
				AND l_arr_rec_acctgrpdetl[l_idx].sel_type IS NOT NULL 
				AND l_arr_rec_acctgrpdetl[l_idx].sel_type <> " " 
				AND l_arr_rec_acctgrpdetl[l_idx].start_acct IS NOT NULL 
				AND l_arr_rec_acctgrpdetl[l_idx].start_acct <> " " THEN 
					INSERT INTO acctgrpdetl 
					VALUES (glob_rec_kandoouser.cmpy_code, 
					glob_rec_acctgrp.group_code, 
					l_arr_rec_acctgrpdetl[l_idx].id_num, 
					l_arr_rec_acctgrpdetl[l_idx].subid_num, 
					l_arr_rec_acctgrpdetl[l_idx].sel_type, 
					l_arr_rec_acctgrpdetl[l_idx].start_pos, 
					l_arr_rec_acctgrpdetl[l_idx].start_acct, 
					l_arr_rec_acctgrpdetl[l_idx].end_acct) 
				END IF 
			ELSE 
				UPDATE acctgrpdetl 
				SET sel_type = l_arr_rec_acctgrpdetl[l_idx].sel_type, 
				start_pos = l_arr_rec_acctgrpdetl[l_idx].start_pos, 
				start_acct = l_arr_rec_acctgrpdetl[l_idx].start_acct, 
				end_acct = l_arr_rec_acctgrpdetl[l_idx].end_acct 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = glob_rec_acctgrp.group_code 
				AND id_num = l_arr_rec_acctgrpdetl[l_idx].id_num 
				AND subid_num = l_arr_rec_acctgrpdetl[l_idx].subid_num 

			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

	END INPUT 

	LABEL exit_grp_dtl: 

	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW g580 

	RETURN l_added 

END FUNCTION 


############################################################
# FUNCTION next_avail_id()
#
#
############################################################
FUNCTION next_avail_id() 
	DEFINE l_next_id LIKE acctgrpdetl.id_num 

	SELECT max(id_num) 
	INTO l_next_id 
	FROM acctgrpdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND group_code = glob_rec_acctgrp.group_code 

	IF status = NOTFOUND 
	OR l_next_id IS NULL THEN 
		LET l_next_id = 1 
	ELSE 
		LET l_next_id = l_next_id + 1 
	END IF 

	RETURN l_next_id 

END FUNCTION 


############################################################
# FUNCTION next_avail_subid(p_id_num)
#
#
############################################################
FUNCTION next_avail_subid(p_id_num) 
	DEFINE p_id_num LIKE acctgrpdetl.id_num 
	DEFINE l_next_subid LIKE acctgrpdetl.subid_num 

	SELECT max(subid_num) 
	INTO l_next_subid 
	FROM acctgrpdetl 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND group_code = glob_rec_acctgrp.group_code 
	AND id_num = p_id_num 

	IF status = NOTFOUND 
	OR l_next_subid IS NULL THEN 
		LET l_next_subid = "a" 
	ELSE 
		CASE 
			WHEN l_next_subid = "a" 
				LET l_next_subid = "b" 
			WHEN l_next_subid = "b" 
				LET l_next_subid = "c" 
			WHEN l_next_subid = "c" 
				LET l_next_subid = "d" 
			WHEN l_next_subid = "d" 
				LET l_next_subid = "e" 
			WHEN l_next_subid = "e" 
				LET l_next_subid = "f" 
			WHEN l_next_subid = "f" 
				LET l_next_subid = "g" 
			WHEN l_next_subid = "g" 
				LET l_next_subid = "h" 
			WHEN l_next_subid = "h" 
				LET l_next_subid = "i" 
			WHEN l_next_subid = "i" 
				LET l_next_subid = "j" 
			WHEN l_next_subid = "j" 
				LET l_next_subid = "k" 
			WHEN l_next_subid = "k" 
				LET l_next_subid = "l" 
			WHEN l_next_subid = "l" 
				LET l_next_subid = "m" 
			WHEN l_next_subid = "m" 
				LET l_next_subid = "n" 
			WHEN l_next_subid = "n" 
				LET l_next_subid = "o" 
			WHEN l_next_subid = "o" 
				LET l_next_subid = "p" 
			WHEN l_next_subid = "p" 
				LET l_next_subid = "q" 
			WHEN l_next_subid = "q" 
				LET l_next_subid = "r" 
			WHEN l_next_subid = "r" 
				LET l_next_subid = "s" 
			WHEN l_next_subid = "s" 
				LET l_next_subid = "t" 
			WHEN l_next_subid = "t" 
				LET l_next_subid = "u" 
			WHEN l_next_subid = "u" 
				LET l_next_subid = "v" 
			WHEN l_next_subid = "v" 
				LET l_next_subid = "w" 
			WHEN l_next_subid = "w" 
				LET l_next_subid = "x" 
			WHEN l_next_subid = "x" 
				LET l_next_subid = "y" 
			WHEN l_next_subid = "y" 
				LET l_next_subid = "z" 
		END CASE 
	END IF 

	RETURN l_next_subid 

END FUNCTION 



############################################################
# FUNCTION lookup_seg(p_start_num)
#
#
############################################################
FUNCTION lookup_seg(p_start_num) 
	DEFINE p_start_num LIKE structure.start_num 
	DEFINE l_idx INTEGER 
	#DEFINE #l_scrn        INTEGER
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_arr_rec_structure array[10] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text 
	END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW wg174 with FORM "G174" 
	CALL windecoration_g("G174") 

	CALL formtitleupdate() --huho 

	DECLARE structurecurs CURSOR FOR 
	SELECT * 
	INTO l_rec_structure.* 
	FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num > 0 
	AND type_ind <> "F" 
	ORDER BY start_num 

	FOR l_idx = 1 TO 10 
		INITIALIZE l_arr_rec_structure[l_idx].* TO NULL 
	END FOR 

	LET l_idx = 0 

	FOREACH structurecurs 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
	END FOREACH 

	IF l_idx > 0 THEN 
		# "Cursor TO Segment code AND press ACC"

		LET l_msgresp = kandoomsg("G",1609," ") 
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_structure WITHOUT DEFAULTS FROM sr_structure.* attribute(UNBUFFERED, append ROW = false, auto append = false) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZF","structure1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET l_scrn = scr_line()

				IF arr_curr() >= arr_count() THEN 
					ERROR "No more rows in the direction you are going" 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET quit_flag = false 
			LET int_flag = false 
		ELSE 
			LET p_start_num = l_arr_rec_structure[l_idx].start_num 
		END IF 
	ELSE 
		# MESSAGE "No Structures current - INT TO EXIT"
		# MESSAGE "No Structures current - ACC TO EXIT"

		LET l_msgresp = kandoomsg("G",1608," ") 
		SLEEP 1 
	END IF 

	CLOSE WINDOW wg174 
	RETURN p_start_num 

END FUNCTION 



############################################################
# FUNCTION show_accounts()
#
#
############################################################
FUNCTION show_accounts() 
	DEFINE l_dtls_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp CHAR(1) 
	DEFINE l_select_text CHAR(100) 
	DEFINE l_rec_tempcoa 
	RECORD 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text, 
		type_ind LIKE coa.type_ind 
	END RECORD 

	DEFINE l_arr_rec_coa array[300] OF 
	RECORD 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text, 
		type_ind LIKE coa.type_ind 
	END RECORD 

	OPEN WINDOW g581 with FORM "G581" 
	CALL windecoration_g("G581") 

	CALL formtitleupdate() --huho 
	MESSAGE "Selecting accounts, please wait" 


	CALL build_coa(glob_rec_kandoouser.cmpy_code, glob_rec_acctgrp.group_code) 
	RETURNING l_dtls_cnt 

	IF l_dtls_cnt = 0 THEN 
		LET l_select_text 
		= "SELECT acct_code, desc_text, type_ind ", 
		"FROM coa ", 
		"WHERE cmpy_code = ", glob_rec_kandoouser.cmpy_code 
	ELSE 
		LET l_select_text 
		= "SELECT * FROM tempcoa" 
	END IF 

	PREPARE coa_select FROM l_select_text 

	DECLARE coa_curs 
	CURSOR FOR coa_select 

	LET l_idx = 0 

	FOREACH coa_curs INTO l_rec_tempcoa.* 

		#      IF l_idx = 300 THEN
		#         LET l_msgresp = kandoomsg("G",9605,"")
		#         EXIT FOREACH
		#      END IF

		LET l_idx = l_idx + 1 

		LET l_arr_rec_coa[l_idx].acct_code = l_rec_tempcoa.acct_code 
		LET l_arr_rec_coa[l_idx].desc_text = l_rec_tempcoa.desc_text 
		LET l_arr_rec_coa[l_idx].type_ind = l_rec_tempcoa.type_ind 

	END FOREACH 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW g581 
		RETURN 
	END IF 

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("G",9606,"") 
	ELSE 
		# MESSAGE "INT TO Exit"

		LET l_msgresp = kandoomsg("U",1512," ") 
		#       CALL set_count (l_idx)
		DISPLAY ARRAY l_arr_rec_coa TO sr_coa.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","GZF","disp-arr-coa") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

	END IF 

	CLOSE WINDOW g581 

	WHENEVER ERROR CONTINUE 
	IF fgl_find_table("tempcoa") THEN
		DROP TABLE tempcoa 
	END IF	
	WHENEVER ERROR stop 

	LET int_flag = false 
	LET quit_flag = false 

END FUNCTION 
