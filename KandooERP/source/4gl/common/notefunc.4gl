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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_notes RECORD LIKE notes.* 
DEFINE modu_arr_rec_notes DYNAMIC ARRAY OF #array[200] OF RECORD 
	RECORD 
		note_text LIKE notes.note_text 
	END RECORD 

#DEFINE trying_to CHAR(6)

############################################################
# FUNCTION sys_noter(p_cmpy, p_pass_note_code)
#
# FUNCTION notes allows the user TO enter AND maintain notes on desc fields
############################################################
FUNCTION sys_noter(p_cmpy,p_pass_note_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_pass_note_code CHAR(30) 
	DEFINE l_short_note_code CHAR(12) 
	DEFINE l_temp_note_code CHAR(12) 
	DEFINE l_trying_to CHAR(6) 

	IF p_pass_note_code[1,3] = "###" THEN 
		LET l_short_note_code = p_pass_note_code[4,15] 
	ELSE 
		LET l_short_note_code = NULL 
	END IF 
	LET l_temp_note_code = NULL 


	MENU " Notes " 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","notefunc","menu-Notes-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Add " " Add a note TO the system" 
			LET l_trying_to = MODE_INSERT 
			LET l_short_note_code = sys_notes(p_cmpy, l_short_note_code,MODE_INSERT) 
			NEXT option "Exit" 

		COMMAND "Modify " " Modify a note on the system" 
			LET l_trying_to = MODE_UPDATE 
			LET l_short_note_code = sys_notes(p_cmpy, l_short_note_code,MODE_UPDATE) 
			NEXT option "Exit" 

		COMMAND "Find " " Find a note on the system" 
			LET l_trying_to = MODE_FIND 
			LET l_temp_note_code = show_note(p_cmpy) 
			IF l_temp_note_code IS NOT NULL THEN 
				LET l_short_note_code = l_temp_note_code 
			END IF 
			NEXT option "Exit" 

		COMMAND "Delete " " Delete a note on the system" 
			LET l_trying_to = MODE_DELETE 
			LET l_short_note_code = sys_notes(p_cmpy, l_short_note_code,MODE_DELETE) 
			NEXT option "Exit" 

		COMMAND "Image " " Image Contents of an Existing Note" 
			LET l_short_note_code = image_note(p_cmpy, l_short_note_code) 
			NEXT option "Exit" 

		COMMAND KEY(interrupt,"E")"Exit" " Exit TO program" 
			EXIT MENU 

	END MENU 

	IF l_short_note_code = " " THEN 
		LET p_pass_note_code = NULL 
	END IF 
	IF l_short_note_code != " " THEN 
		LET p_pass_note_code = "###",l_short_note_code,"###" 
	END IF 
	RETURN(p_pass_note_code) 
END FUNCTION 
############################################################
# END FUNCTION sys_noter(p_cmpy, p_pass_note_code)
############################################################


############################################################
# FUNCTION sys_notes(p_cmpy, p_short_note_code,p_trying_to)
#
#
############################################################
FUNCTION sys_notes(p_cmpy,p_short_note_code,p_trying_to) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_short_note_code CHAR(12) 
	DEFINE p_trying_to SMALLINT --CHAR(6) 
	DEFINE l_time CHAR(8) 
	DEFINE l_null_note SMALLINT 
	DEFINE l_note_count SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	OPEN WINDOW U122 with FORM "U122" 
	CALL winDecoration_u("U122") 

	MESSAGE kandoomsg2("W",1161,"") #1161 "Enter Note Details; OK TO Continue."
	IF p_trying_to = MODE_INSERT THEN 
		LET l_time = time 
		LET modu_rec_notes.note_code = today USING "yymmdd", 
		l_time[1,2],l_time[4,5],l_time[7,8] 
		WHILE note_exists(p_cmpy, modu_rec_notes.note_code) 
			LET modu_rec_notes.note_code = modu_rec_notes.note_code - 1 
		END WHILE 
	ELSE 
		LET modu_rec_notes.note_code = p_short_note_code 
	END IF 

	INPUT BY NAME modu_rec_notes.note_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","notefunc","input-note_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			IF infield (note_code) THEN 
				LET modu_rec_notes.note_code = show_note(p_cmpy) 
				DISPLAY BY NAME modu_rec_notes.note_code 

				NEXT FIELD note_code 
			END IF 
		AFTER FIELD note_code 
			IF modu_rec_notes.note_code IS NULL 
			OR modu_rec_notes.note_code = " " THEN 
				ERROR kandoomsg2("U",9102,"")				#9102 Value must be entered
				NEXT FIELD note_code 
			END IF 
			IF NOT note_exists(p_cmpy, modu_rec_notes.note_code) 
			AND (p_trying_to = MODE_UPDATE OR p_trying_to = MODE_DELETE) THEN 
				ERROR kandoomsg2("U",9105,"")		#Record NOT found; Try Window
				NEXT FIELD note_code 
			END IF 
			IF note_exists(p_cmpy, modu_rec_notes.note_code) 
			AND p_trying_to = MODE_INSERT THEN 
				ERROR kandoomsg2("U",9104,"")	#Record already exists.
				NEXT FIELD note_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW u122 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_short_note_code = NULL 
		RETURN (p_short_note_code) 
	END IF 

	LET p_short_note_code = modu_rec_notes.note_code 

	DECLARE c_note1 CURSOR FOR 
	SELECT * 
	FROM notes 
	WHERE notes.cmpy_code = p_cmpy 
	AND notes.note_code = modu_rec_notes.note_code 
	ORDER BY 
		cmpy_code, 
		note_code, 
		note_num 

	LET l_idx = 0 
	FOREACH c_note1 INTO modu_rec_notes.* 
		LET l_idx = l_idx + 1 
		LET modu_arr_rec_notes[l_idx].note_text = modu_rec_notes.note_text 
	END FOREACH 

	LET l_note_count = l_idx 
	CALL set_count(l_note_count) 
	IF p_trying_to = MODE_DELETE THEN 
		DISPLAY ARRAY modu_arr_rec_notes TO sr_notes.* ATTRIBUTE(UNBUFFERED) 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","notefunc","display-arr-notes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


		END DISPLAY 

	ELSE 
		MESSAGE kandoomsg2("W",1161,"")	#1161 F1 TO Add; F2 TO Delete; OK TO Continue.
		OPTIONS DELETE KEY f2 
		INPUT ARRAY modu_arr_rec_notes WITHOUT DEFAULTS FROM sr_notes.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","notefunc","input-arr-notes-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END INPUT 

		LET l_note_count = arr_count() 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_short_note_code = NULL 
	ELSE 
		LET modu_rec_notes.cmpy_code = p_cmpy 
		
		# delete off all notes FOR that note_code
		DELETE 
		FROM notes 
		WHERE notes.cmpy_code = p_cmpy 
		AND notes.note_code = modu_rec_notes.note_code 

		CASE 
			#MODE_INSERT MODE_UPDATE 
			WHEN p_trying_to = MODE_INSERT OR p_trying_to = MODE_UPDATE 

				LET l_null_note = true 
				FOR i = 1 TO l_note_count 
					IF modu_arr_rec_notes[i].note_text IS NOT NULL THEN 
						LET l_null_note = false 
					END IF 
				END FOR 
				IF l_null_note = true THEN 
					IF p_trying_to = MODE_INSERT THEN 
						LET p_short_note_code = NULL 
					ELSE 
						LET p_short_note_code = " " 
					END IF 
				END IF
				 
				# add them back on again
				FOR i = 1 TO l_note_count 
					INSERT 
					INTO notes 
					VALUES (
						p_cmpy, 
						modu_rec_notes.note_code, 
						i, 
						modu_arr_rec_notes[i].note_text) 
				END FOR 

			#MODE_DELETE
			WHEN p_trying_to = MODE_DELETE 
				LET p_short_note_code = " " 
		END CASE 
	END IF 

	CLOSE WINDOW U122 

	RETURN (p_short_note_code) 
END FUNCTION 
############################################################
# # FUNCTION sys_notes(p_cmpy, p_short_note_code,p_trying_to)
############################################################


############################################################
# FUNCTION show_note(p_cmpy)
#
#
############################################################
FUNCTION show_note(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF #array[51] OF 
	RECORD 
		note_code LIKE notes.note_code, 
		note_text LIKE notes.note_text 
	END RECORD 
	#DEFINE l_note_num LIKE notes.note_num #huho seems NOT TO be used
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_query_text, l_where_text CHAR(200) 
	DEFINE l_ans LIKE language.yes_flag 

	OPEN WINDOW U146 with FORM "U146" 
	CALL windecoration_u("U146") 

	WHILE true 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 "Enter Selection Criteria; ESC TO Continue"
		LET l_ans = kandoomsg("U",8005,"") 	#8005 DISPLAY first line only?

		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW U146 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_arr_rec_notes[1].note_code = NULL 
			RETURN l_arr_rec_notes[1].note_code 
		END IF 

		CONSTRUCT l_where_text ON 
			note_code, 
			note_text 
		FROM sr_note_scan[1].* 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","notefunc","construct-notes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW u146 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_arr_rec_notes[1].note_code = NULL 
			RETURN l_arr_rec_notes[1].note_code 
		END IF 

		IF upshift(l_ans) = "Y" THEN 
			LET l_where_text = l_where_text CLIPPED," AND note_num = 1" 
		END IF 

		LET l_query_text = 
		"SELECT * ", 
		"FROM notes ", 
		"WHERE ", l_where_text CLIPPED," ", 
		"AND cmpy_code = \"",p_cmpy,"\" ", 
		"ORDER BY cmpy_code,", 
		"note_code,", 
		"note_num" 
		PREPARE note FROM l_query_text 
		DECLARE c_note2 CURSOR FOR note 

		LET l_idx = 0 
		FOREACH c_note2 INTO modu_rec_notes.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_notes[l_idx].note_code = modu_rec_notes.note_code 
			LET l_arr_rec_notes[l_idx].note_text = modu_rec_notes.note_text 
		END FOREACH 

		ERROR kandoomsg2("U",9113,l_idx)		#9113 l_idx records selected
		LET l_cnt = l_idx 

		MESSAGE kandoomsg2("U",1008,"")	#1008 F3/F4 TO page Fwd/Bwdl; OK TO Continue.
		#INPUT ARRAY l_arr_rec_notes WITHOUT DEFAULTS FROM sr_note_scan.* 
		DISPLAY ARRAY l_arr_rec_notes TO sr_note_scan.*
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","notefunc","input-arr-notes-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW U146 
	RETURN l_arr_rec_notes[l_idx].note_code 
END FUNCTION 
############################################################
# END FUNCTION show_note(p_cmpy)
############################################################


############################################################
# FUNCTION image_note(p_cmpy, p_short_note_code)
#
#
############################################################
FUNCTION image_note(p_cmpy,p_short_note_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_short_note_code LIKE notes.note_code 
	DEFINE l_time CHAR(8) 
	DEFINE i SMALLINT
	DEFINE l_idx SMALLINT
	
	OPEN WINDOW U122 with FORM "U122" 
	CALL windecoration_u("U122") 

	MESSAGE kandoomsg2("U",1035,"")	#1035 "Enter Source Note Code; OK TO Continue"
	LET modu_rec_notes.note_code = p_short_note_code 
	INPUT BY NAME modu_rec_notes.note_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","notefunc","input-note_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (note_code) #ON KEY (control-b) 
			LET modu_rec_notes.note_code = show_note(p_cmpy) 
			DISPLAY BY NAME modu_rec_notes.note_code 

			NEXT FIELD note_code 

		AFTER FIELD note_code 
			IF modu_rec_notes.note_code IS NULL	OR modu_rec_notes.note_code = "" THEN 
				NEXT FIELD note_code 
			END IF 
			
			IF NOT note_exists(p_cmpy, modu_rec_notes.note_code) THEN 
				ERROR kandoomsg2("U",9105,"")		#Record NOT found; Try Window
				NEXT FIELD note_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW U122 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_short_note_code = NULL 
		RETURN p_short_note_code 
	ELSE 
		LET p_short_note_code = modu_rec_notes.note_code 
		DECLARE c_note3 CURSOR FOR 
		SELECT * 
		FROM notes 
		WHERE notes.cmpy_code = p_cmpy 
		AND notes.note_code = modu_rec_notes.note_code 
		ORDER BY 
			cmpy_code, 
			note_code, 
			note_num 

		LET l_idx = 0 

		FOREACH c_note3 INTO modu_rec_notes.* 
			LET l_idx = l_idx + 1 
			LET modu_arr_rec_notes[l_idx].note_text = modu_rec_notes.note_text 
		END FOREACH 

		MESSAGE kandoomsg2("U",1008,"") 	#1008 F3/F4 TO Page Fwd/Bwd; OK TO Continue.
		DISPLAY ARRAY modu_arr_rec_notes TO sr_notes.* ATTRIBUTE(UNBUFFERED) 

			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","notefunc","display-arr-notes") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW U122 
			LET int_flag = false 
			LET quit_flag = false 
			LET p_short_note_code = NULL 
			RETURN p_short_note_code 
		END IF 
	END IF 

	LET l_time = time 
	LET modu_rec_notes.note_code = today USING "yymmdd",	l_time[1,2],l_time[4,5],l_time[7,8] 

	WHILE note_exists(p_cmpy, modu_rec_notes.note_code) 
		LET modu_rec_notes.note_code = modu_rec_notes.note_code - 1 
	END WHILE 

	MESSAGE kandoomsg2("U",1036,"")	#1036 "Enter Target Note Code; OK TO Continue"
	INPUT BY NAME modu_rec_notes.note_code WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","notefunc","input-note_code-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
	
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" --ON KEY (control-b) 
			IF infield (note_code) THEN 
				LET modu_rec_notes.note_code = show_note(p_cmpy) 
				DISPLAY BY NAME modu_rec_notes.note_code 
--				NEXT FIELD note_code 
			END IF 

		AFTER FIELD note_code 
			IF modu_rec_notes.note_code IS NULL 
			OR modu_rec_notes.note_code = "" THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered
--				NEXT FIELD note_code 
			END IF 
			
			IF note_exists(p_cmpy, modu_rec_notes.note_code) THEN 
				ERROR kandoomsg2("U",9104,"")	#9104 RECORD already exists
--				NEXT FIELD note_code 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW U122 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_short_note_code = NULL 
		RETURN p_short_note_code 
	END IF 

	INPUT ARRAY modu_arr_rec_notes WITHOUT DEFAULTS FROM sr_notes.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","notefunc","input-arr-notes-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW U122 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_short_note_code = NULL 
		RETURN p_short_note_code 
	END IF
	 
	FOR i = 1 TO modu_arr_rec_notes.getSize() 

		INSERT INTO notes 
		VALUES (
			p_cmpy, 
			modu_rec_notes.note_code, 
			i, 
			modu_arr_rec_notes[i].note_text) 

	END FOR 

	CLOSE WINDOW U122 

	RETURN(modu_rec_notes.note_code) 
END FUNCTION 
############################################################
# FUNCTION image_note(p_cmpy, p_short_note_code)
############################################################


############################################################
# FUNCTION note_exists(p_cmpy, p_note_code)
#
#
############################################################
FUNCTION note_exists(p_cmpy, p_note_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_note_code LIKE notes.note_code 
	DEFINE r_cnt SMALLINT 

	SELECT count(*) 
	INTO r_cnt 
	FROM notes 
	WHERE notes.cmpy_code = p_cmpy 
	AND notes.note_code = p_note_code
	 
	RETURN r_cnt 
END FUNCTION 
############################################################
# END FUNCTION note_exists(p_cmpy, p_note_code)
############################################################