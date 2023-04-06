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

	Source code beautified by beautify.pl on 2020-01-03 14:28:57	$Id: $
}



#  This module contains the functions needed TO UPDATE a
#  RECORD in the rptcol table.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "../gl/GW3_GLOBALS.4gl" 

############################################################
# FUNCTION col_updt(p_col_shuffle)
#
# Description         :   This FUNCTION allows the user TO UPDATE an existing
#                         row in the rptcol table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   p_col_shuffle flag SET WHEN inserting columns.
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   col_maint
############################################################
FUNCTION col_updt(p_col_shuffle) 
	DEFINE p_col_shuffle SMALLINT 

	DEFINE l_idx INTEGER 
	DEFINE l_scr INTEGER 
	DEFINE l_cnt INTEGER 
	DEFINE l_col_width INTEGER 
	DEFINE l_width_tot INTEGER 
	DEFINE l_ans CHAR(1) 
	DEFINE l_temp_text CHAR(40) 
	DEFINE l_seq_num LIKE colitem.seq_num 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_col_shuffle != true AND p_col_shuffle != false THEN 
		LET p_col_shuffle = false 
	END IF 

	LET glob_coldesc_cnt = 3 
	INPUT glob_arr_recrptcoldesc[1].col_desc, 
	glob_arr_recrptcoldesc[2].col_desc, 
	glob_arr_recrptcoldesc[3].col_desc, 
	glob_rec_rptcol.width, 
	glob_rec_rptcol.amt_picture WITHOUT DEFAULTS 
	FROM sa_rptcol[1].col_desc, 
	sa_rptcol[2].col_desc, 
	sa_rptcol[3].col_desc, 
	rptcol.width, 
	rptcol.amt_picture 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GW3f","inp-rptcoldesc") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (f7) #segment entry OF analysis across type report. 
			IF glob_rec_rptcol.col_uid IS NULL THEN 
				LET l_msgresp = kandoomsg("G",7005,"") 
				#7005 "Column header details saved be4 entering segment maintenance"
			ELSE 
				CALL seg_anal_across(glob_rec_rptcol.col_uid) 
			END IF 

		BEFORE FIELD width 
			# Default the COLUMN width TO the maximum COLUMN header length.
			LET l_col_width = 0 
			FOR l_idx = 1 TO glob_coldesc_cnt 
				IF length( glob_arr_recrptcoldesc[l_idx].col_desc ) > l_col_width THEN 
					LET l_col_width = length( glob_arr_recrptcoldesc[l_idx].col_desc ) 
				END IF 
			END FOR 
			IF glob_rec_rptcol.width IS NULL THEN 
				IF glob_rec_rptcol.width IS NULL THEN 
					LET glob_rec_rptcol.width = l_col_width + 1 
					DISPLAY BY NAME glob_rec_rptcol.width 

				END IF 
			END IF 

		AFTER FIELD width 
			IF glob_rec_rptcol.width IS NULL THEN 
				LET glob_rec_rptcol.width = l_col_width 
				DISPLAY BY NAME glob_rec_rptcol.width 

			END IF 
			#Check the total width of the REPORT.  Must be less than 232.
			SELECT sum(width) INTO l_width_tot FROM rptcol 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rptcol.rpt_id 
			IF l_width_tot > 232 AND glob_rec_rptcol.width != 0 THEN 
				LET l_msgresp = kandoomsg("G",9168,"") 
				#9168 Total width exceeds 232 FOR all columns in REPORT
				LET glob_rec_rptcol.width = 232 - l_width_tot 
				DISPLAY BY NAME glob_rec_rptcol.width 

				NEXT FIELD rptcol.width 
			ELSE 
				#Check that the COLUMN header description length
				#  does NOT exceed the COLUMN width.
				IF glob_rec_rptcol.width > 0 AND glob_rec_rptcol.width < (l_col_width + 1) THEN 
					LET l_msgresp = kandoomsg("G",9169,"") 
					#9169 Column width IS less than COLUMN description
				END IF 
			END IF 

			#   ON KEY (control-w)
			#      CALL kandoohelp("")
	END INPUT 


	IF NOT (int_flag OR quit_flag) THEN 

		LET int_flag = false 
		LET quit_flag = false 
		#Save added/UPDATE REPORT COLUMN header details.
		CALL save_rptcol(glob_rec_rptcol.col_id, p_col_shuffle) 
		RETURNING glob_rec_rptcol.col_uid 
		CALL set_count(glob_colitem_cnt) 

		INPUT ARRAY glob_arr_reccolitem WITHOUT DEFAULTS FROM sa_colitem.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW3f","inp-arr-colitem") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON KEY (f7) #segment entry OF analysis across type report. 
				CALL seg_anal_across(glob_rec_rptcol.col_uid) 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scr = scr_line() 
				LET l_seq_num = glob_arr_reccolitem[l_idx].seq_num 
				LET glob_colitem_cnt = arr_count() 
				IF glob_colitem_cnt > 20 THEN 
					LET l_msgresp = kandoomsg("U",9046,20) 
					#9046 Value must be less than OR equal TO 20
					LET glob_colitem_cnt = 20 
					NEXT FIELD col_item 
				END IF 

			AFTER ROW 
				#Get the item_type FROM mrwitem table.
				SELECT item_desc INTO glob_arr_reccolitem[l_idx].item_desc FROM mrwitem 
				WHERE item_id = glob_arr_reccolitem[l_idx].col_item 
				IF status = NOTFOUND THEN 
					LET glob_arr_reccolitem[l_idx].item_desc = NULL 
				ELSE 
					DISPLAY glob_arr_reccolitem[l_idx].item_desc 
					TO sa_colitem[l_scr].item_desc 

					#Update ARRAY COLUMN item information in temp table
					UPDATE colitem 
					SET col_item = glob_arr_reccolitem[l_idx].col_item, 
					item_operator = glob_arr_reccolitem[l_idx].item_operator 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rpt_id = glob_rec_rpthead.rpt_id 
					AND col_uid = glob_rec_rptcol.col_uid 
					AND seq_num = glob_arr_reccolitem[l_idx].seq_num 
				END IF 

			ON ACTION "LOOKUP" infield(item_operator) 
				CALL show_operator(glob_arr_reccolitem[l_idx].item_operator) 
				RETURNING glob_arr_reccolitem[l_idx].item_operator 
				DISPLAY glob_arr_reccolitem[l_idx].item_operator 
				TO item_operator 

			ON ACTION "LOOKUP" infield(col_item) 
				CALL show_mrwitem(glob_arr_reccolitem[l_idx].col_item) 
				RETURNING glob_arr_reccolitem[l_idx].col_item 
				SELECT item_desc INTO glob_arr_reccolitem[l_idx].item_desc FROM mrwitem 
				WHERE item_id = glob_arr_reccolitem[l_idx].col_item 

				DISPLAY BY NAME glob_arr_reccolitem[l_idx].col_item, 
				glob_arr_reccolitem[l_idx].item_desc 


			AFTER DELETE 
				# delete seq_num line.
				CALL delete_col(glob_rec_rptcol.col_uid, l_seq_num, l_idx, l_scr) 
			BEFORE INSERT 
				# Increment seq_num lines.
				CALL increment_lines(glob_rec_rptcol.col_uid, l_seq_num, l_idx, l_scr) 
				RETURNING l_seq_num 
			AFTER INSERT 
				IF not(int_flag OR quit_flag) THEN 
					INSERT INTO colitem 
					VALUES ( glob_rec_kandoouser.cmpy_code, 
					glob_rec_rptcol.rpt_id, 
					glob_rec_rptcol.col_uid, 
					glob_arr_reccolitem[l_idx].seq_num, 
					glob_arr_reccolitem[l_idx].col_item, 
					glob_arr_reccolitem[l_idx].item_operator) 
				END IF 
			AFTER FIELD col_item 
				SELECT * INTO glob_rec_mrwitem.* FROM mrwitem 
				WHERE item_id = glob_arr_reccolitem[l_idx].col_item 
				IF status = NOTFOUND THEN 
					INITIALIZE glob_rec_mrwitem.* TO NULL 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD NOT found; Try Window.
					NEXT FIELD col_item 
				END IF 
				IF glob_rec_mrwparms.constant_item_type != glob_rec_mrwitem.item_type THEN 
					IF glob_arr_reccolitem[l_idx].item_operator IS NULL 
					OR glob_arr_reccolitem[l_idx].item_operator = " " THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD item_operator 
					END IF 
				END IF 
			BEFORE FIELD item_desc 
				IF maint_col_details(glob_rec_rptcol.col_uid, l_idx, l_scr) THEN 
					NEXT FIELD col_item 
				END IF 
				NEXT FIELD item_operator 
			AFTER FIELD item_operator 
				#Only allow '+' OR '-' FOR the first ARRAY element.
				IF l_idx = 1 THEN 
					CASE 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.add_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.sub_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = " " 
						WHEN glob_arr_reccolitem[l_idx].item_operator IS NULL 
							LET glob_arr_reccolitem[l_idx].item_operator = " " 
						OTHERWISE 
							LET l_msgresp = kandoomsg("G",9205,"") 
							NEXT FIELD item_operator 
					END CASE 
				ELSE 
					CASE 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.add_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.sub_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.mult_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = glob_rec_mrwparms.div_op 
						WHEN glob_arr_reccolitem[l_idx].item_operator = " " 
						WHEN glob_arr_reccolitem[l_idx].item_operator IS NULL 
							LET glob_arr_reccolitem[l_idx].item_operator = " " 
						OTHERWISE 
							LET l_msgresp = kandoomsg("U",9105,"") 
							#9105 RECORD NOT found; Try Window.
							NEXT FIELD item_operator 
					END CASE 
				END IF 


			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					#Get the item_type FROM mrwitem table.
					SELECT item_desc INTO glob_arr_reccolitem[l_idx].item_desc FROM mrwitem 
					WHERE item_id = glob_arr_reccolitem[l_idx].col_item 
					DISPLAY glob_arr_reccolitem[l_idx].item_desc 
					TO sa_colitem[l_scr].item_desc 

					#Update ARRAY COLUMN item information in temp table
					UPDATE colitem 
					SET col_item = glob_arr_reccolitem[l_idx].col_item, 
					item_operator = glob_arr_reccolitem[l_idx].item_operator 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rpt_id = glob_rec_rpthead.rpt_id 
					AND col_uid = glob_rec_rptcol.col_uid 
					AND seq_num = glob_arr_reccolitem[l_idx].seq_num 
				END IF 
				#      ON KEY (control-w)
				#         CALL kandoohelp("")
		END INPUT 

		LET glob_colitem_cnt = arr_count() 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 


############################################################
# FUNCTION increment_lines(p_col_uid, p_seq_num, p_idx, p_scr)
#
# FUNCTION:     increment seq_num lines
# Description:  This FUNCTION increments the seq_num numbers FOR each
#                line in the temp table colitem WHEN inserting new rows.
############################################################
FUNCTION increment_lines(p_col_uid, p_seq_num, p_idx, p_scr) 
	DEFINE p_seq_num INTEGER 
	DEFINE p_col_uid INTEGER 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE l_updt_seq INTEGER 

	--	DEFINE l_num INTEGER

	IF p_seq_num = 0 OR p_seq_num IS NULL THEN 
		SELECT max(seq_num) + 1 INTO p_seq_num FROM colitem 
		WHERE col_uid = p_col_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF p_seq_num IS NULL THEN 
			LET p_seq_num = 1 
		END IF 
	END IF 

	INITIALIZE glob_arr_reccolitem[p_idx].* TO NULL 
	LET glob_arr_reccolitem[p_idx].seq_num = p_seq_num 
	DISPLAY glob_arr_reccolitem[p_idx].seq_num TO sa_colitem[p_scr].seq_num 

	CLEAR item_operator[p_scr], 
	col_item[p_scr], 
	id_col_id[p_scr], 
	item_desc[p_scr] 

	DECLARE inc_udpt_curs CURSOR FOR 
	SELECT seq_num FROM colitem 
	WHERE col_uid = p_col_uid 
	AND seq_num >= p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY seq_num desc 

	FOREACH inc_udpt_curs INTO l_updt_seq 

		UPDATE colitem 
		SET seq_num = seq_num + 1 
		WHERE col_uid = p_col_uid 
		AND seq_num >= l_updt_seq 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		UPDATE colitemval 
		SET seq_num = seq_num + 1 
		WHERE col_uid = p_col_uid 
		AND seq_num >= l_updt_seq 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		UPDATE colitemdetl 
		SET seq_num = seq_num + 1 
		WHERE col_uid = p_col_uid 
		AND seq_num >= l_updt_seq 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		UPDATE colitemcolid 
		SET seq_num = seq_num + 1 
		WHERE col_uid = p_col_uid 
		AND seq_num >= l_updt_seq 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END FOREACH 

	DECLARE inc_curs CURSOR FOR 
	SELECT seq_num FROM colitem 
	WHERE col_uid = p_col_uid 
	AND seq_num >= p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY seq_num 

	# Maintain line number ORDER.
	LET p_idx = p_idx + 1 
	FOREACH inc_curs INTO glob_arr_reccolitem[p_idx].seq_num 

		IF p_scr < 5 THEN 
			LET p_scr = p_scr + 1 
			DISPLAY glob_arr_reccolitem[p_idx].seq_num 
			TO sa_colitem[p_scr].seq_num 

		END IF 
		LET p_idx = p_idx + 1 
	END FOREACH 



	RETURN p_seq_num 

END FUNCTION 


############################################################
# FUNCTION decrement_lines(p_seq_num, p_col_uid, p_idx, p_scr)
#
# FUNCTION:     decrement seq_num lines
# Description:  This FUNCTION decrements the seq_num numbers FOR each
#               line in the temp table colitem WHEN deleting rows.
############################################################
FUNCTION decrement_lines(p_seq_num, p_col_uid, p_idx, p_scr) 
	DEFINE p_seq_num INTEGER 
	DEFINE p_col_uid INTEGER 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	--	DEFINE l_s1 CHAR(500)
	--	DEFINE l_num INTEGER


	#Update temp table colitem seq_num(s).
	UPDATE colitem 
	SET seq_num = seq_num - 1 
	WHERE col_uid = p_col_uid 
	AND seq_num > p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	UPDATE colitemval 
	SET seq_num = seq_num - 1 
	WHERE col_uid = p_col_uid 
	AND seq_num > p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	UPDATE colitemdetl 
	SET seq_num = seq_num - 1 
	WHERE col_uid = p_col_uid 
	AND seq_num > p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	UPDATE colitemcolid 
	SET seq_num = seq_num - 1 
	WHERE col_uid = p_col_uid 
	AND seq_num > p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DECLARE dec_curs CURSOR FOR 
	SELECT seq_num FROM colitem 
	WHERE col_uid = p_col_uid 
	AND seq_num >= p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	ORDER BY seq_num 

	# Maintain line number ORDER.
	FOREACH dec_curs INTO glob_arr_reccolitem[p_idx].seq_num 
		IF p_scr < 5 THEN 
			DISPLAY glob_arr_reccolitem[p_idx].seq_num 
			TO sa_colitem[p_scr].seq_num 

			LET p_scr = p_scr + 1 
		END IF 
		LET p_idx = p_idx + 1 
	END FOREACH 


	# Null the last seq_num member of the array.

	LET glob_arr_reccolitem[p_idx].seq_num = NULL 
	LET glob_arr_reccolitem[p_idx].col_item = NULL 

END FUNCTION 


############################################################
# FUNCTION maint_col_details(p_col_uid, p_idx, p_scr)
#
# FUNCTION TO CALL the correct line information FOR each line type.
############################################################
FUNCTION maint_col_details(p_col_uid, p_idx, p_scr) 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE p_col_uid INTEGER 
	DEFINE l_seq_num INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Get the item_type FROM mrwitem table.
	SELECT mrwitem.* INTO glob_rec_mrwitem.* FROM mrwitem 
	WHERE item_id = glob_arr_reccolitem[p_idx].col_item 

	LET glob_arr_reccolitem[p_idx].id_col_id = NULL 
	LET glob_arr_reccolitem[p_idx].item_desc = glob_rec_mrwitem.item_desc 

	DISPLAY glob_arr_reccolitem[p_idx].item_desc TO sa_colitem[p_scr].item_desc 


	# Check the item type against the mrwparms table.
	CASE 
		WHEN glob_rec_mrwparms.time_item_type = glob_rec_mrwitem.item_type 
			CALL time_maint(glob_arr_reccolitem[p_idx].seq_num, p_col_uid) 

		WHEN glob_rec_mrwparms.column_item_type = glob_rec_mrwitem.item_type 
			CALL column_maint(glob_arr_reccolitem[p_idx].seq_num, p_col_uid) 
			DISPLAY glob_arr_reccolitem[p_idx].id_col_id TO sa_colitem[p_scr].id_col_id 


		WHEN glob_rec_mrwparms.value_item_type = glob_rec_mrwitem.item_type 
			CALL value_maint(glob_arr_reccolitem[p_idx].seq_num, p_col_uid) 

		WHEN glob_rec_mrwparms.constant_item_type = glob_rec_mrwitem.item_type 
		WHEN glob_rec_mrwitem.item_type = "O" #temporarily hard coded (see gw1d) 
		WHEN glob_arr_reccolitem[p_idx].col_item IS NULL 
			RETURN true 

		OTHERWISE 
			LET l_msgresp = kandoomsg("E",9029,"") 
			#9029 "Invalid Line type."
			RETURN true 
	END CASE 

	RETURN false 
END FUNCTION 


############################################################
# FUNCTION  save_rptcol(p_col_id, p_col_shuffle)
#
# function:        save REPORT COLUMN header details.
# description:     This FUNCTION saves the REPORT COLUMN header details
#                  plus also shuffles any columns along IF needed.
############################################################
FUNCTION save_rptcol(p_col_id, p_col_shuffle) 
	DEFINE p_col_id INTEGER 
	DEFINE p_col_shuffle INTEGER 

	DEFINE l_updt_id INTEGER 
	DEFINE l_idx INTEGER 
	DEFINE l_col_uid INTEGER 

	IF p_col_shuffle THEN 
		DECLARE shuf_cur CURSOR FOR 
		SELECT col_id FROM rptcol 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND rpt_id = glob_rec_rpthead.rpt_id 
		AND col_id >= p_col_id 
		ORDER BY col_id desc 
		FOREACH shuf_cur INTO l_updt_id 
			UPDATE rptcol 
			SET col_id = col_id + 1 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = glob_rec_rpthead.rpt_id 
			AND col_id = l_updt_id 
		END FOREACH 
	END IF 

	#Get the unique rptcol identifier.
	SELECT col_uid INTO l_col_uid FROM rptcol 
	WHERE glob_rec_kandoouser.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rpt_id = glob_rec_rpthead.rpt_id 
	AND col_id = p_col_id 
	IF status = NOTFOUND THEN 
		INSERT INTO rptcol VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		glob_rec_rptcol.col_id, 
		0, 
		glob_rec_rptcol.width, 
		glob_rec_rptcol.amt_picture ) 

		LET l_col_uid = sqlca.sqlerrd[2] 
	ELSE 
		UPDATE rptcol 
		SET width = glob_rec_rptcol.width, 
		amt_picture = glob_rec_rptcol.amt_picture 
		WHERE col_uid = l_col_uid 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	END IF 

	#Remove the old description lines TO INSERT the new.
	DELETE FROM rptcoldesc 
	WHERE col_uid = l_col_uid 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	FOR l_idx = 1 TO 3 #fixed number OF REPORT descriptions. 

		INSERT INTO rptcoldesc VALUES ( glob_rec_kandoouser.cmpy_code, 
		glob_rec_rpthead.rpt_id, 
		l_col_uid, 
		l_idx, 
		glob_arr_recrptcoldesc[l_idx].col_desc) 
	END FOR 

	RETURN l_col_uid 

END FUNCTION 




############################################################
# FUNCTION delete_col(p_col_uid, p_seq_num, p_seq_num, p_scr)
#
# FUNCTION:        delete_col
# Description:     Deletes FROM REPORT COLUMN item table.
############################################################
FUNCTION delete_col(p_col_uid, p_seq_num, p_idx, p_scr) 
	DEFINE p_idx INTEGER 
	DEFINE p_scr INTEGER 
	DEFINE p_seq_num INTEGER 
	DEFINE p_col_uid INTEGER 

	IF p_col_uid IS NOT NULL THEN 

		# Delete row FROM rptcol table.
		DELETE FROM colitem 
		WHERE col_uid = p_col_uid 
		AND seq_num = p_seq_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		CALL delete_col_types(p_seq_num, p_col_uid) 
	END IF 

	# decrement line_id lines.
	CALL decrement_lines(p_seq_num, p_col_uid, p_idx, p_scr) 

END FUNCTION 


############################################################
# FUNCTION delete_col_types(p_seq_num, p_col_uid)
#
# FUNCTION:        delete COLUMN types
# Description:     Deletes FROM REPORT columns tables as shown in code.
############################################################
FUNCTION delete_col_types(p_seq_num, p_col_uid) 
	DEFINE p_col_uid INTEGER 
	DEFINE p_seq_num INTEGER 

	DELETE FROM colitemval 
	WHERE col_uid = p_col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DELETE FROM colitemdetl 
	WHERE col_uid = p_col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	DELETE FROM colitemcolid 
	WHERE col_uid = p_col_uid 
	AND seq_num = p_seq_num 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

END FUNCTION 
