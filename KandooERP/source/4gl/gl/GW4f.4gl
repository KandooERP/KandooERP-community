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

	Source code beautified by beautify.pl on 2020-01-03 14:28:58	$Id: $
}


############################################################
#  This module contains the functions needed TO maintain
#  the rptline table.
############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW4_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_tt_rptline RECORD 
	line_id LIKE rptline.line_id, 
	line_type LIKE rptline.line_type, 
	line_desc LIKE descline.line_desc, 
	accum_id LIKE saveline.accum_id, 
	page_break_follow LIKE rptline.page_break_follow, 
	drop_lines LIKE rptline.drop_lines 
END RECORD 


############################################################
# FUNCTION line_updt()
# Description         :   This FUNCTION allows the user TO maintain
#                         rows in the rptline table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   None
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   line_maint
#
############################################################
FUNCTION line_updt() 
	DEFINE l_idx INTEGER 
	DEFINE l_scr INTEGER 
	DEFINE l_exit INTEGER 
	DEFINE l_insert_flag INTEGER 
	DEFINE l_reselect INTEGER 
	DEFINE l_line_uid INTEGER 
	DEFINE l_rows_found INTEGER 
	DEFINE l_ans CHAR(1) 
	--	DEFINE l_rec_mrwitem RECORD LIKE mrwitem.*
	DEFINE l_line_id LIKE rptline.line_id 
	DEFINE l_line_type LIKE rptline.line_type 
	DEFINE l_field CHAR(10) #attribute FOR storing FIELD names. 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_exit = false 
	LET l_reselect = false 
	LET glob_query_2 = NULL 
	CALL rptline_load () 

	WHILE ( NOT l_exit ) 
		LET l_msgresp = kandoomsg("G",1074,"") 
		#1074 F1 TO Add; F2 TO Delete; F7 Analysis...
		IF l_reselect THEN 
			LET l_rows_found = false 
			WHILE ( true ) 
				CLEAR FORM 
				DISPLAY BY NAME glob_rec_rpthead.rpt_id, 
				glob_rec_rpthead.rpt_text 

				#get the users query criteria
				CONSTRUCT glob_query_2 
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
						CALL publish_toolbar("kandoo","GW4f","construct-rptline") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
				END CONSTRUCT 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT WHILE 
				ELSE 
					IF glob_query_2 = " 1=1" THEN 
						LET glob_query_2 = NULL 
					ELSE 
						LET glob_query_2 = "AND ", glob_query_2 clipped 
					END IF 
				END IF 
				CALL disp_line() 
				IF glob_line_cnt = 0 THEN 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 

		ELSE 
			LET glob_query_2 = NULL 
		END IF 

		LET l_insert_flag = false 
		CALL set_count(glob_line_cnt) 

		INPUT ARRAY glob_arr_rec_rptline WITHOUT DEFAULTS FROM sa_rptline.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW4f","inp-arr-rptline") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scr = scr_line() 
				LET l_line_id = glob_arr_rec_rptline[l_idx].line_id 
				LET l_line_type = glob_arr_rec_rptline[l_idx].line_type 
				LET glob_line_cnt = arr_count() 
				IF glob_line_cnt > 2000 THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in that direction
					LET glob_line_cnt = 2000 
					NEXT FIELD line_id 
				END IF 
				#Get the unique line identifier.
				SELECT line_uid INTO l_line_uid FROM rptline 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				AND line_id = l_line_id 
				IF status = NOTFOUND THEN 
					LET l_line_uid = NULL 
				END IF 

			AFTER ROW 
				IF glob_arr_rec_rptline[l_idx].line_type IS NOT NULL THEN 
					#Validate line types.
					CASE 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.gl_line_type 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.calc_line_type 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.under_line_type 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.text_line_type 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.ext_link_line_type 
						OTHERWISE 
							CONTINUE INPUT 
					END CASE 
					#Update ARRAY line information in temp table.
					CALL updt_line(l_idx, l_line_uid) 
				END IF 
			ON KEY (F9) #reselect rows. 
				LET l_reselect = true 
				EXIT INPUT 

			ON KEY (f7) #segment entry OF analysis down type report. 
				CALL seg_anal_down(l_line_id, l_line_uid) 

			ON KEY (F8) #get accumulator. 
				IF glob_arr_rec_rptline[l_idx].line_type != glob_rec_mrwparms.text_line_type THEN 
					CALL accum_maint(l_idx, l_line_uid) 
					DISPLAY glob_arr_rec_rptline[l_idx].accum_id 
					TO sa_rptline[l_scr].accum_id 

				END IF 

			BEFORE INSERT 
				# Increment line_id lines.
				CALL increment_lines(l_line_id, l_idx, l_scr) 
				RETURNING l_line_id 
				LET l_insert_flag = true 

			AFTER DELETE 
				IF l_insert_flag THEN 
					LET l_insert_flag = false 
					LET glob_arr_rec_rptline[l_idx].line_type = l_line_type 
					CALL insert_line (l_line_id, l_idx, l_scr) 
					RETURNING l_line_id, l_line_uid 
				END IF 
				CALL delete_line(l_line_id, l_line_uid, l_idx, l_scr) 

			AFTER FIELD line_type 
				IF l_insert_flag THEN 
					LET l_insert_flag = false 
					IF glob_arr_rec_rptline[l_idx].line_type IS NULL THEN 
						CONTINUE INPUT 
					ELSE 
						CALL insert_line (l_line_id, l_idx, l_scr) 
						RETURNING l_line_id, l_line_uid 
						LET l_line_type = NULL 
					END IF 
				END IF 
				IF l_line_type IS NULL 
				OR l_line_type != glob_arr_rec_rptline[l_idx].line_type THEN 
					IF maintain_line_details(l_idx, l_scr, l_line_uid) THEN 
						NEXT FIELD line_type 
					END IF 
					LET l_field = "" 
				ELSE 
					LET l_field = "line_type" 
				END IF 

			BEFORE FIELD line_desc 
				IF l_field = "line_type" THEN 
					IF maintain_line_details(l_idx, l_scr, l_line_uid) THEN 
						NEXT FIELD line_type 
					END IF 
				END IF 
				LET l_field = "line_desc" 
				DISPLAY glob_arr_rec_rptline[l_idx].line_desc TO sa_rptline[l_scr].line_desc 

				NEXT FIELD accum_id 

			BEFORE FIELD accum_id 
				CASE 
					WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.gl_line_type 
					WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.calc_line_type 
					OTHERWISE 
						NEXT FIELD page_break_follow 
				END CASE 

			AFTER FIELD accum_id 
				IF glob_arr_rec_rptline[l_idx].accum_id IS NOT NULL AND 
				glob_arr_rec_rptline[l_idx].accum_id > 0 THEN 
					CASE 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.gl_line_type 
							CALL accum_line(l_idx, l_line_uid ) 
						WHEN glob_arr_rec_rptline[l_idx].line_type = glob_rec_mrwparms.calc_line_type 
							CALL accum_line(l_idx, l_line_uid ) 
						OTHERWISE 
							LET glob_arr_rec_rptline[l_idx].accum_id = NULL 
					END CASE 
				ELSE 
					LET glob_arr_rec_rptline[l_idx].accum_id = NULL 
				END IF 
				--         DISPLAY glob_arr_rec_rptline[l_idx].accum_id TO sa_rptline[l_scr].accum_id

			AFTER INPUT 
				IF NOT (int_flag AND quit_flag) THEN 
					LET l_exit = true 
				END IF 
				--      ON KEY (control-w)
				--         CALL kandoohelp("")
		END INPUT 

		IF l_reselect = true THEN 
		ELSE 
			LET glob_line_cnt = arr_count() 
			LET l_exit = true 
		END IF 

	END WHILE 

	LET glob_query_2 = NULL 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 



############################################################
# FUNCTION increment_lines(p_line_id, p_idx, p_scr)
#
# FUNCTION:     increment line_id lines
# Description:  This FUNCTION increments the line_id numbers FOR each
#               line in the temp table rptline WHEN inserting new rows.
############################################################
FUNCTION increment_lines(p_line_id, p_idx, p_scr) 
	DEFINE p_line_id INTEGER 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 

	DEFINE l_updt_line INTEGER 
	DEFINE l_num INTEGER 
	DEFINE l_s1 CHAR(500) 

	IF p_line_id = 0 OR p_line_id IS NULL THEN 
		SELECT max(line_id) + 1 INTO p_line_id FROM rptline 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		IF p_line_id IS NULL THEN 
			LET p_line_id = 1 
		END IF 
	END IF 

	DISPLAY p_line_id TO sa_rptline[p_scr].line_id 

	CLEAR line_type[p_scr], 
	line_desc[p_scr], 
	accum_id[p_scr] 

	DECLARE incrl_curs CURSOR FOR 
	SELECT line_id FROM rptline 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	AND line_id >= p_line_id 
	ORDER BY line_id desc 
	FOREACH incrl_curs INTO l_updt_line 
		#Update temp table tt_rptline line_id(s).
		UPDATE tt_rptline 
		SET line_id = line_id + 1 
		WHERE line_id = l_updt_line 
		#Update temp table rptline line_id(s).
		UPDATE rptline 
		SET line_id = line_id + 1 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		AND line_id = l_updt_line 
	END FOREACH 
	LET l_s1 = "SELECT line_id ", 
	"FROM tt_rptline ", 
	"WHERE line_id >= ",p_line_id, 
	glob_query_2 clipped, 
	" ORDER BY line_id" 
	PREPARE s_2 FROM l_s1 
	DECLARE inc_curs CURSOR FOR s_2 

	# Maintain line number ORDER.
	LET p_idx = p_idx + 1 
	FOREACH inc_curs INTO glob_arr_rec_rptline[p_idx].line_id 
		IF p_scr < 10 THEN 
			LET p_scr = p_scr + 1 
			DISPLAY glob_arr_rec_rptline[p_idx].line_id 
			TO sa_rptline[p_scr].line_id 

		END IF 
		LET p_idx = p_idx + 1 
	END FOREACH 

	RETURN p_line_id 

END FUNCTION 


############################################################
# FUNCTION increment_lines(p_line_id, p_idx, p_scr)
#
# FUNCTION:     decrement line_id lines
# Description:  This FUNCTION decrements the line_id numbers FOR each
#               line in the temp table rptline WHEN deleting rows.
############################################################
FUNCTION decrement_lines(p_line_id, p_idx, p_scr) 
	DEFINE p_line_id INTEGER 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 

	DEFINE l_num INTEGER 
	DEFINE l_s1 CHAR(500) 

	#Update temp table tt_rptline line_id(s).
	UPDATE tt_rptline 
	SET line_id = line_id - 1 
	WHERE line_id > p_line_id 

	#Update rptline
	UPDATE rptline 
	SET line_id = line_id - 1 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	AND line_id > p_line_id 
	LET l_s1 = "SELECT line_id ", 
	"FROM tt_rptline ", 
	"WHERE line_id >= ",p_line_id, 
	glob_query_2 clipped, 
	" ORDER BY line_id" 
	PREPARE s_3 FROM l_s1 
	DECLARE dec_curs CURSOR FOR s_3 
	# Maintain line number ORDER.
	FOREACH dec_curs INTO glob_arr_rec_rptline[p_idx].line_id 
		IF p_scr <= 10 THEN 
			DISPLAY glob_arr_rec_rptline[p_idx].line_id 
			TO sa_rptline[p_scr].line_id 

			LET p_scr = p_scr + 1 
		END IF 
		LET p_idx = p_idx + 1 
	END FOREACH 

	# Null the last line_id member of the array.
	LET glob_arr_rec_rptline[p_idx].line_id = NULL 
	LET glob_arr_rec_rptline[p_idx].line_type = NULL 

END FUNCTION 


############################################################
# FUNCTION maintain_line_details(p_idx, p_scr, p_line_uid)
#
# FUNCTION TO CALL the correct line information FOR each line type.
############################################################
FUNCTION maintain_line_details(p_idx, p_scr, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE p_line_uid INTEGER 
	DEFINE l_desc_cnt INTEGER 
	DEFINE l_line_id INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Check IF there are any description columns.
	SELECT count(*) INTO l_desc_cnt FROM colitem, mrwitem 
	WHERE colitem.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND colitem.rpt_id = glob_rec_rptline.rpt_id 
	AND mrwitem.item_id = colitem.col_item 
	AND mrwitem.item_type = glob_rec_mrwparms.constant_item_type 


	CASE 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.gl_line_type 
			CALL glline_maint(p_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_desc_cnt > 0 THEN 
					CALL desc_maint(p_idx, p_line_uid) 
					DISPLAY glob_arr_rec_rptline[p_idx].line_desc 
					TO sa_rptline[p_scr].line_desc 

				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.calc_line_type 
			CALL calcline_maint(p_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_desc_cnt > 0 THEN 
					CALL desc_maint(p_idx, p_line_uid) 
					DISPLAY glob_arr_rec_rptline[p_idx].line_desc 
					TO sa_rptline[p_scr].line_desc 

				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.under_line_type 
			CALL underline_maint(p_idx, p_line_uid) 
			DISPLAY glob_arr_rec_rptline[p_idx].line_desc 
			TO sa_rptline[p_scr].line_desc 

		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.text_line_type 
			IF l_desc_cnt > 0 THEN 
				CALL txt_maint(p_idx, p_line_uid) 
				DISPLAY glob_arr_rec_rptline[p_idx].line_desc 
				TO sa_rptline[p_scr].line_desc 

			ELSE 
				LET l_msgresp = kandoomsg("G",9211,"") 
				#9211 "There are No defined description columns FOR this REPORT."
				RETURN true 
			END IF 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.ext_link_line_type 
			CALL extline_maint(glob_arr_rec_rptline[p_idx].line_id, p_line_uid) 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_desc_cnt > 0 THEN 
					CALL desc_maint(p_idx, p_line_uid) 
					DISPLAY glob_arr_rec_rptline[p_idx].line_desc 
					TO sa_rptline[p_scr].line_desc 

				END IF 
			ELSE 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
		WHEN glob_arr_rec_rptline[p_idx].line_type IS NULL 
		WHEN glob_arr_rec_rptline[p_idx].line_type = " " 
		OTHERWISE 
			LET l_msgresp = kandoomsg("U",9112,"Line Type") 
			#9112 "Invalid Line type.  Please try again."
			RETURN true 
	END CASE 
	RETURN false 
END FUNCTION 


############################################################
# FUNCTION insert_line(p_line_id, p_idx, p_scr)
#
# FUNCTION:        insert_line
# Description:     Insert INTO REPORT line table AND temp table.
############################################################
FUNCTION insert_line(p_line_id, p_idx, p_scr) 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE p_line_id INTEGER 
	DEFINE l_line_uid INTEGER 

	LET glob_arr_rec_rptline[p_idx].line_id = p_line_id 
	IF glob_arr_rec_rptline[p_idx].accum_id = 0 THEN 
		LET glob_arr_rec_rptline[p_idx].accum_id = NULL 
	END IF 

	INSERT INTO tt_rptline 
	VALUES ( glob_arr_rec_rptline[p_idx].line_id, 
	glob_arr_rec_rptline[p_idx].line_type, 
	glob_arr_rec_rptline[p_idx].line_desc, 
	glob_arr_rec_rptline[p_idx].accum_id, 
	glob_arr_rec_rptline[p_idx].page_break_follow, 
	glob_arr_rec_rptline[p_idx].drop_lines) 

	#Default rptline information FOR this INSERT.
	LET glob_rec_rptline.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET glob_rec_rptline.rpt_id = glob_rec_rpthead.rpt_id 
	LET glob_rec_rptline.line_id = glob_arr_rec_rptline[p_idx].line_id 
	LET glob_rec_rptline.line_uid = 0 
	LET glob_rec_rptline.line_type = glob_arr_rec_rptline[p_idx].line_type 
	LET glob_rec_rptline.accum_id = NULL 
	LET glob_rec_rptline.page_break_follow = "N" 
	LET glob_rec_rptline.drop_lines = "1" 
	INSERT INTO rptline VALUES ( glob_rec_rptline.* ) 
	LET l_line_uid = sqlca.sqlerrd[2] 
	RETURN p_line_id, l_line_uid 

END FUNCTION 


############################################################
# FUNCTION updt_line(p_idx, p_line_uid)
#
# FUNCTION:        updt_line
# Description:     Updates REPORT line table AND temp table.
############################################################
FUNCTION updt_line(p_idx, p_line_uid) 
	DEFINE p_idx INTEGER 
	DEFINE p_line_uid INTEGER 

	IF glob_arr_rec_rptline[p_idx].accum_id = 0 THEN 
		LET glob_arr_rec_rptline[p_idx].accum_id = NULL 
	END IF 

	#Update temp table rptline
	UPDATE tt_rptline 
	SET line_type = glob_arr_rec_rptline[p_idx].line_type, 
	line_desc = glob_arr_rec_rptline[p_idx].line_desc, 
	accum_id = glob_arr_rec_rptline[p_idx].accum_id, 
	page_break_follow = glob_arr_rec_rptline[p_idx].page_break_follow, 
	drop_lines = glob_arr_rec_rptline[p_idx].drop_lines 
	WHERE line_id = glob_arr_rec_rptline[p_idx].line_id 

	#Only UPDATE line IF there are no nulls in the following fields.
	IF glob_arr_rec_rptline[p_idx].line_type IS NOT NULL AND 
	glob_arr_rec_rptline[p_idx].page_break_follow IS NOT NULL AND 
	glob_arr_rec_rptline[p_idx].drop_lines IS NOT NULL THEN 

		#Update table rptline
		UPDATE rptline 
		SET line_type = glob_arr_rec_rptline[p_idx].line_type, 
		line_desc = glob_arr_rec_rptline[p_idx].line_desc, 
		accum_id = glob_arr_rec_rptline[p_idx].accum_id, 
		page_break_follow = glob_arr_rec_rptline[p_idx].page_break_follow, 
		drop_lines = glob_arr_rec_rptline[p_idx].drop_lines 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

END FUNCTION 


############################################################
# FUNCTION delete_line(p_line_id, p_line_uid, p_idx, p_scr)
#
# FUNCTION:        delete_line
# Description:     Deletes FROM REPORT line table AND temp table.
############################################################
FUNCTION delete_line(p_line_id, p_line_uid, p_idx, p_scr) 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE p_line_id INTEGER 
	DEFINE p_line_uid INTEGER 

	# Delete row FROM temp table.
	DELETE FROM tt_rptline 
	WHERE line_id = p_line_id 

	IF p_line_uid IS NOT NULL THEN 
		# Delete row FROM rptline table.
		DELETE FROM rptline 
		WHERE line_uid = p_line_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		CALL delete_line_types(p_idx, p_line_uid) 
	END IF 

	# decrement line_id lines.
	CALL decrement_lines(p_line_id, p_idx, p_scr) 

END FUNCTION 


############################################################
# FUNCTION delete_line_types(p_idx, p_line_uid)
#
# FUNCTION:        delete_line
# Description:     Deletes FROM REPORT line table AND temp table.
############################################################
FUNCTION delete_line_types(p_idx, p_line_uid) 
	DEFINE p_line_uid INTEGER 
	DEFINE p_idx INTEGER 

	CASE 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.gl_line_type 
			#delete any gl lines
			DELETE FROM glline 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM gllinedetl 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.calc_line_type 
			#delete any calculation lines
			DELETE FROM calchead 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			DELETE FROM calcline 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.under_line_type 
			#delete any text lines
			DELETE FROM txtline 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		WHEN glob_arr_rec_rptline[p_idx].line_type = glob_rec_mrwparms.ext_link_line_type 
			DELETE FROM extline 
			WHERE line_uid = p_line_uid 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END CASE 

	#delete any accumulators
	DELETE FROM saveline 
	WHERE line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	#delete any description lines.
	DELETE FROM descline 
	WHERE line_uid = p_line_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

END FUNCTION 
