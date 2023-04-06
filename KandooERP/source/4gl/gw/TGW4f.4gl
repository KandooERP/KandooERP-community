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

	Source code beautified by beautify.pl on 2020-01-03 10:10:05	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW4_GLOBALS.4gl" 

#  This module contains the functions needed TO maintain
#  the rptline table.


DEFINE mr_tt_rptline RECORD 
	line_id LIKE rptline.line_id, 
	line_type LIKE rptline.line_type, 
	line_desc LIKE descline.line_desc, 
	accum_id LIKE rptline.accum_id, 
	page_break_follow LIKE rptline.page_break_follow, 
	drop_lines LIKE rptline.drop_lines 
END RECORD 

FUNCTION line_add() 

	DEFINE fv_idx SMALLINT 

	INITIALIZE gr_rptlinegrp.* TO NULL 
	INITIALIZE gr_rptline.* TO NULL 

	FOR fv_idx = 1 TO 2000 
		INITIALIZE ga_rptline[fv_idx].* TO NULL 
	END FOR 

	CLEAR FORM 

	INPUT BY NAME gr_rptlinegrp.line_code, 
	gr_rptlinegrp.linegrp_desc 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4f","input-line_code-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD line_code 
			IF gr_rptlinegrp.line_code IS NULL THEN 
				ERROR "Line group code must be entered" 
				NEXT FIELD line_code 
			END IF 

			SELECT * FROM rptlinegrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_code = gr_rptlinegrp.line_code 
			IF status <> notfound THEN 
				ERROR "This line code already exists" 
				NEXT FIELD line_code 
			END IF 

		AFTER FIELD linegrp_desc 
			IF gr_rptlinegrp.linegrp_desc IS NULL THEN 
				ERROR "Line group description must be entered" 
				NEXT FIELD linegrp_desc 
			END IF 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	INSERT INTO rptlinegrp VALUES (glob_rec_kandoouser.cmpy_code, 
	gr_rptlinegrp.line_code, 
	gr_rptlinegrp.linegrp_desc) 

	LET gv_line_added = true 

	CALL disp_line() 
	CALL line_updt() 

END FUNCTION 


FUNCTION linegrp_updt() 

	INPUT BY NAME gr_rptlinegrp.linegrp_desc 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW4f","input-linegrp_desc-1") -- albo kd-515 
		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 
		AFTER FIELD linegrp_desc 
			IF gr_rptlinegrp.linegrp_desc IS NULL THEN 
				ERROR "Line group description must be entered" 
				NEXT FIELD linegrp_desc 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		RETURN 
	END IF 

	UPDATE rptlinegrp 
	SET linegrp_desc = gr_rptlinegrp.linegrp_desc 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 

END FUNCTION 

{
FUNCTION            :   line_updt
Description         :   This FUNCTION allows the user TO maintain
                        rows in the rptline table. It performs the appropriate
                        uniqueness AND NOT NULL checks on the VALUES entered
Incoming parameters :   None
RETURN parameters   :   None
Impact GLOBALS      :   None
perform screens     :   line_maint
}

FUNCTION line_updt() 

	DEFINE fv_idx, 
	fv_scr, 
	fv_exit, 
	fv_insert, 
	fv_reselect, 
	fv_line_uid, 
	fv_add_on_end, 
	fv_rows_found INTEGER, 
	fv_ans CHAR(1) 

	DEFINE fr_mrwitem RECORD LIKE mrwitem.*, 
	fv_line_id LIKE rptline.line_id, 
	fv_line_type LIKE rptline.line_type, 
	fv_accum_id LIKE rptline.accum_id 

	LET fv_exit = false 
	LET fv_reselect = false 
	LET gv_query_2 = NULL 

	CALL rptline_load () 

	WHILE (not fv_exit) 

		#DISPLAY "" AT 1,1
		#DISPLAY "" AT 2,1
		#DISPLAY "F1 TO add, F2 TO delete, F7 analysis, F8 change accumulator,"
		#        AT 1,1 ATTRIBUTE(yellow)
		#DISPLAY " F9 re-SELECT, ACC TO accept, INT TO cancel"
		#        AT 2,1 ATTRIBUTE(yellow)
		LET msgresp = kandoomsg("G",1607," ") 

		IF fv_reselect THEN 
			LET fv_rows_found = false 

			WHILE (true) 

				CLEAR FORM 

				DISPLAY BY NAME gr_rptlinegrp.line_code, 
				gr_rptlinegrp.linegrp_desc 

				CONSTRUCT gv_query_2 
				ON line_id, 
				line_type, 
				line_desc, 
				accum_id, 
				page_break_follow, 
				drop_lines 
				FROM rptline[1].line_id, 
				rptline[1].line_type, 
				rptline[1].line_desc, 
				rptline[1].accum_id, 
				rptline[1].page_break_follow, 
				rptline[1].drop_lines 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","TGW4f","construct-line_id-1") -- albo kd-515 

					ON ACTION "WEB-HELP" -- albo kd-378 
						CALL onlinehelp(getmoduleid(),null) 

				END CONSTRUCT 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					ERROR "Query aborted" 
					EXIT WHILE 
				ELSE 
					IF gv_query_2 = " 1=1" THEN 
						LET gv_query_2 = NULL 
					ELSE 
						LET gv_query_2 = "AND ", gv_query_2 clipped 
					END IF 
				END IF 

				CALL disp_line() 

				IF gv_line_cnt = 0 THEN 
					ERROR "No records match this criteria." 
				ELSE 
					EXIT WHILE 
				END IF 

			END WHILE 
		ELSE 
			LET gv_query_2 = NULL 
		END IF 
		LET fv_insert = false 

		CALL set_count(gv_line_cnt) 
		INPUT ARRAY ga_rptline 
		WITHOUT DEFAULTS FROM sa_rptline.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","TGW4f","input-arr-ga_rptline-1") -- albo kd-515 

			ON ACTION "WEB-HELP" -- albo kd-378 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET fv_insert = false 
				LET fv_add_on_end = false 
				LET fv_idx = arr_curr() 
				LET fv_scr = scr_line() 
				LET fv_line_id = ga_rptline[fv_idx].line_id 
				LET fv_line_type = ga_rptline[fv_idx].line_type 
				LET fv_accum_id = ga_rptline[fv_idx].accum_id 
				LET gv_line_cnt = arr_count() 
				IF gv_line_cnt > 2000 THEN 
					ERROR "Maximum Number of lines IS 2000" 
					LET gv_line_cnt = 2000 
					NEXT FIELD line_id 
				END IF 
				#Get the unique line identifier.
				SELECT line_uid INTO fv_line_uid 
				FROM rptline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND line_code = gr_rptlinegrp.line_code 
				AND line_id = fv_line_id 

				IF status = notfound THEN 
					LET fv_line_uid = NULL 
				END IF 

			AFTER ROW 
				IF NOT (int_flag OR quit_flag) THEN 
					CALL updt_line(fv_idx, fv_line_uid) 
				END IF 

			ON KEY (F9) #reselect rows. 
				LET fv_reselect = true 
				EXIT INPUT 

			ON KEY (f7) #segment entry OF analysis down type report. 
				IF ga_rptline[fv_idx].line_type <> gr_mrwparms.gl_line_type THEN 
					ERROR "Analysis down only applicable FOR GL lines" 
				ELSE 
					CALL seg_anal_down(fv_line_id, fv_line_uid) 
				END IF 

			ON KEY (F8) #get accumulator. 
				IF ga_rptline[fv_idx].line_type = gr_mrwparms.text_line_type 
				OR ga_rptline[fv_idx].line_type = gr_mrwparms.under_line_type THEN 
					ERROR "Accumulator NOT applicable FOR this line type" 
				ELSE 
					CALL accum_maint(fv_idx, fv_line_uid) 
					DISPLAY ga_rptline[fv_idx].accum_id 
					TO sa_rptline[fv_scr].accum_id 
					LET fv_accum_id = ga_rptline[fv_idx].accum_id 
				END IF 

			BEFORE INSERT 
				LET fv_line_uid = NULL 
				# Increment line_id lines.
				CALL increment_lines(fv_line_id, fv_idx, fv_scr) 
				RETURNING fv_line_id, fv_add_on_end 
				LET fv_insert = true 

			AFTER DELETE 
				CALL delete_line(fv_line_id, fv_line_uid, fv_idx, fv_scr) 
				LET fv_insert = false 

			AFTER FIELD line_type 
				IF (ga_rptline[fv_idx].line_type IS NULL 
				OR ga_rptline[fv_idx].line_type = " ") 
				AND NOT ( (fv_add_on_end AND fgl_lastkey() = fgl_keyval("up")) 
				OR (fgl_lastkey() = fgl_keyval("accept")) ) THEN 
					ERROR "Line type must be entered" 
					NEXT FIELD line_type 
				ELSE 
					IF ga_rptline[fv_idx].line_type IS NOT NULL 
					AND NOT ga_rptline[fv_idx].line_type = " " THEN 
						CASE 
							WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
							WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
							WHEN ga_rptline[fv_idx].line_type 
								= gr_mrwparms.ext_link_line_type 
							WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.under_line_type 
								LET ga_rptline[fv_idx].accum_id = NULL 
								DISPLAY ga_rptline[fv_idx].accum_id 
								TO sa_rptline[fv_scr].accum_id 
							WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.text_line_type 
								LET ga_rptline[fv_idx].accum_id = NULL 
								DISPLAY ga_rptline[fv_idx].accum_id 
								TO sa_rptline[fv_scr].accum_id 
							OTHERWISE 
								ERROR "Invalid line type - please enter another" 
								NEXT FIELD line_type 
						END CASE 
					END IF 
				END IF 

			BEFORE FIELD line_desc 
				IF fv_insert THEN 
					CALL insert_line (fv_line_id, fv_idx, fv_scr) 
					RETURNING fv_line_id, fv_line_uid 
					LET fv_line_type = NULL 
					LET fv_insert = false 
				END IF 

				IF maintain_line_details(fv_idx, fv_scr, fv_line_uid) THEN 
					NEXT FIELD line_type 
				END IF 

				DISPLAY ga_rptline[fv_idx].line_desc TO sa_rptline[fv_scr].line_desc 
				NEXT FIELD accum_id 

			BEFORE FIELD accum_id 
				CASE 
					WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
					WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
					WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.ext_link_line_type 
					OTHERWISE 
						NEXT FIELD page_break_follow 
				END CASE 

			AFTER FIELD accum_id 

				IF ga_rptline[fv_idx].accum_id IS NOT NULL THEN 
					IF ga_rptline[fv_idx].accum_id = 0 THEN 
						ERROR "Accumulator, IF entered, must be > zero" 
						NEXT FIELD accum_id 
					END IF 
				END IF 

				IF ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type THEN 
					SELECT * 
					FROM calcline 
					WHERE line_uid = fv_line_uid 
					AND accum_id = ga_rptline[fv_idx].accum_id 

					IF status <> notfound THEN 
						ERROR "Accumulator must be different FROM any ", 
						"specified as part of calc line" 
						NEXT FIELD accum_id 
					END IF 
				END IF 

				#        IF ga_rptline[fv_idx].accum_id IS NOT NULL AND
				#           ga_rptline[fv_idx].accum_id > 0 THEN
				#           CASE
				#               WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type
				#                  CALL accum_line(fv_accum_id, fv_idx, fv_line_uid)
				#               WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type
				#                  CALL accum_line(fv_accum_id, fv_idx, fv_line_uid)
				#               WHEN ga_rptline[fv_idx].line_type
				#                 = gr_mrwparms.ext_link_line_type
				#                     CALL accum_line(fv_accum_id, fv_idx, fv_line_uid)
				#               OTHERWISE
				#                  LET ga_rptline[fv_idx].accum_id = NULL
				#           END CASE
				#        ELSE
				#           DELETE FROM saveline
				#             WHERE line_uid = fv_line_uid
				#           LET ga_rptline[fv_idx].accum_id = NULL
				#        END IF

				IF NOT (ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
				OR ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
				OR ga_rptline[fv_idx].line_type = gr_mrwparms.ext_link_line_type) THEN 
					LET ga_rptline[fv_idx].accum_id = NULL 
				END IF 

				DISPLAY ga_rptline[fv_idx].accum_id TO sa_rptline[fv_scr].accum_id 
				LET fv_accum_id = ga_rptline[fv_idx].accum_id 

			BEFORE FIELD page_break_follow 
				IF ga_rptline[fv_idx].page_break_follow IS NULL 
				OR ga_rptline[fv_idx].page_break_follow = " " THEN 
					LET ga_rptline[fv_idx].page_break_follow = "N" 
				END IF 

			BEFORE FIELD drop_lines 
				IF ga_rptline[fv_idx].drop_lines IS NULL 
				OR ga_rptline[fv_idx].drop_lines = " " 
				OR ga_rptline[fv_idx].drop_lines = 0 THEN 
					LET ga_rptline[fv_idx].drop_lines = 1 
				END IF 

			AFTER FIELD page_break_follow 
				IF ga_rptline[fv_idx].page_break_follow IS NULL 
				OR ga_rptline[fv_idx].page_break_follow = " " THEN 
					ERROR "Page break must be entered" 
					NEXT FIELD page_break_follow 
				END IF 

				IF NOT ga_rptline[fv_idx].page_break_follow matches "[YN]" THEN 
					ERROR "Page break must be Y OR N" 
					NEXT FIELD page_break_follow 
				END IF 

			AFTER FIELD drop_lines 
				IF ga_rptline[fv_idx].drop_lines IS NULL 
				OR ga_rptline[fv_idx].drop_lines = " " THEN 
					ERROR "Drop lines must be entered" 
					NEXT FIELD drop_lines 
				END IF 

				IF ga_rptline[fv_idx].drop_lines < 1 THEN 
					ERROR "Must drop AT least 1 line" 
					NEXT FIELD drop_lines 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF fv_insert THEN 
						CALL delete_line(fv_line_id, fv_line_uid, fv_idx, fv_scr) 
					END IF 
				END IF 

				IF NOT (int_flag AND quit_flag) THEN 
					LET fv_exit = true 
				END IF 

		END INPUT 

		IF fv_reselect = true THEN 
		ELSE 
			LET gv_line_cnt = arr_count() 
			DISPLAY "" at 1,1 
			DISPLAY "" at 2,1 

			LET fv_exit = true 
		END IF 
	END WHILE 

	LET gv_query_2 = NULL 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 


{ FUNCTION:     increment line_id lines
  Description:  This FUNCTION increments the line_id numbers FOR each
                line in the temp table rptline WHEN inserting new rows.
}
FUNCTION increment_lines(fv_line_id, fv_idx, fv_scr) 

	DEFINE fv_line_id, 
	fv_updt_line, 
	fv_num, 
	fv_idx, 
	fv_add_on_end, 
	fv_scr INTEGER, 
	fv_s1 CHAR(500) 

	LET fv_add_on_end = false 
	IF fv_line_id = 0 OR fv_line_id IS NULL THEN 

		SELECT max(line_id) + 1 INTO fv_line_id 
		FROM rptline 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND line_code = gr_rptlinegrp.line_code 

		IF fv_line_id IS NULL THEN 
			LET fv_line_id = 1 
		ELSE 
			LET fv_add_on_end = true 
		END IF 

	END IF 

	DISPLAY fv_line_id TO sa_rptline[fv_scr].line_id 
	CLEAR line_type[fv_scr], 
	line_desc[fv_scr], 
	accum_id[fv_scr] 

	DECLARE incrl_curs CURSOR FOR 
	SELECT line_id 
	FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 
	AND line_id >= fv_line_id 
	ORDER BY line_id desc 

	FOREACH incrl_curs INTO fv_updt_line 
		UPDATE tt_rptline 
		SET line_id = line_id + 1 
		WHERE line_id = fv_updt_line 

		#Update temp table rptline line_id(s).
		UPDATE rptline 
		SET line_id = line_id + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND line_code = gr_rptlinegrp.line_code 
		AND line_id = fv_updt_line 

	END FOREACH 

	LET fv_s1 = "SELECT line_id ", 
	"FROM tt_rptline ", 
	"WHERE line_id >= ",fv_line_id, 
	gv_query_2 clipped, 
	" ORDER BY line_id" 

	PREPARE s_2 FROM fv_s1 
	DECLARE inc_curs CURSOR FOR s_2 

	# Maintain line number ORDER.
	LET fv_idx = fv_idx + 1 
	FOREACH inc_curs INTO ga_rptline[fv_idx].line_id 
		IF fv_scr < 10 THEN 
			LET fv_scr = fv_scr + 1 
			DISPLAY ga_rptline[fv_idx].line_id 
			TO sa_rptline[fv_scr].line_id 
		END IF 
		LET fv_idx = fv_idx + 1 
	END FOREACH 

	RETURN fv_line_id, fv_add_on_end 

END FUNCTION 


{ FUNCTION:     decrement line_id lines
  Description:  This FUNCTION decrements the line_id numbers FOR each
                line in the temp table rptline WHEN deleting rows.
}
FUNCTION decrement_lines(fv_line_id, fv_idx, fv_scr) 

	DEFINE fv_line_id, 
	fv_idx, 
	fv_num, 
	fv_scr INTEGER, 
	fv_s1 CHAR(500) 

	#Update temp table tt_rptline line_id(s).
	UPDATE tt_rptline 
	SET line_id = line_id - 1 
	WHERE line_id > fv_line_id 

	UPDATE rptline 
	SET line_id = line_id - 1 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND line_code = gr_rptlinegrp.line_code 
	AND line_id > fv_line_id 

	IF fv_line_id IS NOT NULL THEN 
		LET fv_s1 = "SELECT line_id ", 
		"FROM tt_rptline ", 
		"WHERE line_id >= ",fv_line_id, 
		gv_query_2 clipped, 
		" ORDER BY line_id" 

		PREPARE s_3 FROM fv_s1 
		DECLARE dec_curs CURSOR FOR s_3 

		# Maintain line number ORDER.
		FOREACH dec_curs INTO ga_rptline[fv_idx].line_id 
			IF fv_scr <= 10 THEN 
				DISPLAY ga_rptline[fv_idx].line_id 
				TO sa_rptline[fv_scr].line_id 
				LET fv_scr = fv_scr + 1 
			END IF 
			LET fv_idx = fv_idx + 1 
		END FOREACH 

	END IF 

	# Null the last line_id member of the array.

	LET ga_rptline[fv_idx].line_id = NULL 
	LET ga_rptline[fv_idx].line_type = NULL 

END FUNCTION 

# FUNCTION TO CALL the correct line information FOR each line type.
FUNCTION maintain_line_details(fv_idx, fv_scr, fv_line_uid) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_line_uid, 
	fv_desc_cnt, 
	fv_line_id INTEGER 

	CASE 
		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
			CALL glline_maint(fv_idx, fv_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				CALL desc_maint(fv_idx, fv_line_uid) 
				IF NOT (int_flag OR quit_flag) THEN 
					DISPLAY ga_rptline[fv_idx].line_desc 
					TO sa_rptline[fv_scr].line_desc 
				ELSE 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN true 
				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN true 
			END IF 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
			CALL calcline_maint(fv_idx, fv_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				CALL desc_maint(fv_idx, fv_line_uid) 
				IF NOT (int_flag OR quit_flag) THEN 
					DISPLAY ga_rptline[fv_idx].line_desc 
					TO sa_rptline[fv_scr].line_desc 
				ELSE 
					LET int_flag = false 
					LET quit_flag = false 
					RETURN true 
				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN true 
			END IF 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.under_line_type 
			CALL underline_maint(fv_idx, fv_line_uid) 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN true 
			ELSE 
				DISPLAY ga_rptline[fv_idx].line_desc 
				TO sa_rptline[fv_scr].line_desc 
			END IF 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.text_line_type 
			CALL txt_maint(fv_idx, fv_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				DISPLAY ga_rptline[fv_idx].line_desc 
				TO sa_rptline[fv_scr].line_desc 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN true 
			END IF 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.ext_link_line_type 
			CALL extline_maint(ga_rptline[fv_idx].line_id, fv_line_uid) 
			RETURNING fv_desc_cnt 
			IF NOT (int_flag OR quit_flag) THEN 
				IF fv_desc_cnt > 0 THEN 
					CALL desc_maint(fv_idx, fv_line_uid) 
					IF NOT (int_flag OR quit_flag) THEN 
						DISPLAY ga_rptline[fv_idx].line_desc 
						TO sa_rptline[fv_scr].line_desc 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
						RETURN true 
					END IF 
				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
				RETURN true 
			END IF 

		WHEN ga_rptline[fv_idx].line_type IS NULL 
		WHEN ga_rptline[fv_idx].line_type = " " 
		OTHERWISE 
			ERROR "Invalid Line type. Please try again." 
			RETURN true 
	END CASE 

	RETURN false 
END FUNCTION 


{ FUNCTION:        insert_line
  Description:     Insert INTO REPORT line table AND temp table.
}
FUNCTION insert_line(fv_line_id, fv_idx, fv_scr) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_line_id, 
	fv_line_uid INTEGER 

	LET ga_rptline[fv_idx].line_id = fv_line_id 
	IF ga_rptline[fv_idx].accum_id = 0 THEN 
		LET ga_rptline[fv_idx].accum_id = NULL 
	END IF 

	INSERT INTO tt_rptline 
	VALUES (ga_rptline[fv_idx].line_id, 
	ga_rptline[fv_idx].line_type, 
	ga_rptline[fv_idx].line_desc, 
	ga_rptline[fv_idx].accum_id, 
	ga_rptline[fv_idx].page_break_follow, 
	ga_rptline[fv_idx].drop_lines) 

	#Default rptline information FOR this INSERT.
	LET gr_rptline.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET gr_rptline.line_code = gr_rptlinegrp.line_code 
	LET gr_rptline.line_id = ga_rptline[fv_idx].line_id 
	LET gr_rptline.line_uid = 0 
	LET gr_rptline.line_type = ga_rptline[fv_idx].line_type 
	LET gr_rptline.accum_id = NULL 
	LET gr_rptline.page_break_follow = "N" 
	LET gr_rptline.drop_lines = "1" 

	INSERT INTO rptline VALUES (gr_rptline.*) 

	LET fv_line_uid = sqlca.sqlerrd[2] 

	RETURN fv_line_id, fv_line_uid 

END FUNCTION 

{ FUNCTION:        updt_line
  Description:     Updates REPORT line table AND temp table.
}
FUNCTION updt_line(fv_idx, fv_line_uid) 

	DEFINE fv_idx, 
	fv_line_uid INTEGER 

	IF ga_rptline[fv_idx].accum_id = 0 THEN 
		LET ga_rptline[fv_idx].accum_id = NULL 
	END IF 

	UPDATE tt_rptline 
	SET line_type = ga_rptline[fv_idx].line_type, 
	line_desc = ga_rptline[fv_idx].line_desc, 
	accum_id = ga_rptline[fv_idx].accum_id, 
	page_break_follow = ga_rptline[fv_idx].page_break_follow, 
	drop_lines = ga_rptline[fv_idx].drop_lines 
	WHERE line_id = ga_rptline[fv_idx].line_id 

	#Only UPDATE line IF there are no nulls in the following fields.
	IF ga_rptline[fv_idx].line_type IS NOT NULL AND 
	ga_rptline[fv_idx].page_break_follow IS NOT NULL AND 
	ga_rptline[fv_idx].drop_lines IS NOT NULL THEN 

		#Update table rptline
		UPDATE rptline 
		SET line_type = ga_rptline[fv_idx].line_type, 
		line_desc = ga_rptline[fv_idx].line_desc, 
		accum_id = ga_rptline[fv_idx].accum_id, 
		page_break_follow = ga_rptline[fv_idx].page_break_follow, 
		drop_lines = ga_rptline[fv_idx].drop_lines 
		WHERE line_uid = fv_line_uid 
	END IF 

	CALL dlt_redund_lines(fv_idx, fv_line_uid) 

END FUNCTION 



{ FUNCTION:        delete_line
  Description:     Deletes FROM REPORT line table AND temp table.
}
FUNCTION delete_line(fv_line_id, fv_line_uid, fv_idx, fv_scr) 

	DEFINE fv_idx, 
	fv_scr, 
	fv_line_id, 
	fv_line_uid INTEGER 

	DELETE FROM tt_rptline 
	WHERE line_id = fv_line_id 

	IF fv_line_uid IS NOT NULL THEN 
		DELETE FROM rptline 
		WHERE line_uid = fv_line_uid 

		CALL delete_line_types(fv_idx, fv_line_uid) 
	END IF 

	CALL decrement_lines(fv_line_id, fv_idx, fv_scr) 

END FUNCTION 


{ FUNCTION:        delete_line
  Description:     Deletes FROM REPORT line table AND temp table.
}
FUNCTION delete_line_types(fv_idx, fv_line_uid) 

	DEFINE fv_line_uid, 
	fv_idx INTEGER 

	CASE 
		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
			#delete any gl lines
			DELETE FROM glline 
			WHERE line_uid = fv_line_uid 

			DELETE FROM gllinedetl 
			WHERE line_uid = fv_line_uid 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
			#delete any calculation lines
			DELETE FROM calchead 
			WHERE line_uid = fv_line_uid 

			DELETE FROM calcline 
			WHERE line_uid = fv_line_uid 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.under_line_type 
			#delete any text lines
			DELETE FROM txtline 
			WHERE line_uid = fv_line_uid 

		WHEN ga_rptline[fv_idx].line_type = gr_mrwparms.ext_link_line_type 
			DELETE FROM extline 
			WHERE line_uid = fv_line_uid 

	END CASE 

	#delete any accumulators
	#DELETE FROM saveline
	#  WHERE line_uid = fv_line_uid

	#delete any description lines.
	DELETE FROM descline 
	WHERE line_uid = fv_line_uid 

END FUNCTION 


FUNCTION dlt_redund_lines(fv_idx, fv_line_uid) 

	#  This FUNCTION deletes any records that aren't applicable TO the line type;
	#  eg IF a line has been changed FROM a GL line TO a Title line, the glline,
	#  gllinedetl AND segline records can be deleted

	DEFINE fv_idx, 
	fv_line_uid SMALLINT 

	CASE 
		WHEN NOT ga_rptline[fv_idx].line_type = gr_mrwparms.gl_line_type 
			DELETE FROM glline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

			DELETE FROM gllinedetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

			DELETE FROM segline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

		WHEN NOT ga_rptline[fv_idx].line_type = gr_mrwparms.calc_line_type 
			DELETE FROM calchead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

			DELETE FROM calcline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

		WHEN NOT ga_rptline[fv_idx].line_type = gr_mrwparms.ext_link_line_type 
			DELETE FROM exthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

			DELETE FROM extline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

		WHEN NOT ga_rptline[fv_idx].line_type = gr_mrwparms.under_line_type 
			DELETE FROM txtline 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND line_uid = fv_line_uid 

	END CASE 

END FUNCTION 
