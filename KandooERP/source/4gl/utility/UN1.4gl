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

	Source code beautified by beautify.pl on 2020-01-03 18:54:47	$Id: $
}



#
#  UN1.4gl  Note Maintanence Program FOR the Notes
#           used in Invoics, Orders, Quotes, Vouchers etc...
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
#GLOBALS
#	DEFINE arr_size SMALLINT


#	DEFINE pr_deletion_text LIKE notes.note_text
#END GLOBALS


###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("UN1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u146 with FORM "U146" 
	CALL windecoration_u("U146") 

	#   LET pr_deletion_text = "     **** NOTE DELETED ****"
	#   WHILE select_notes()
	CALL scan_notes() 
	#   END WHILE
	CLOSE WINDOW u146 
END MAIN 


###################################################################
# FUNCTION select_notes()
#
#
###################################################################
FUNCTION select_notes(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_arr_rec_note_scan DYNAMIC ARRAY OF #array[400] OF RECORD 
		RECORD 
			note_code LIKE notes.note_code, 
			note_text LIKE notes.note_text 
		END RECORD 
		DEFINE l_arr_rec_notes DYNAMIC ARRAY OF #array[200] OF RECORD 
			RECORD 
				note_text LIKE notes.note_text 
			END RECORD 
			DEFINE l_rec_notes RECORD LIKE notes.* 
			DEFINE l_where_text STRING 
			DEFINE l_query_text STRING 
			DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
			IF p_filter THEN 
				CLEAR FORM 
				LET l_msgresp = kandoomsg("U",1001,"") 
				#1001 Enter Selection Criteria - OK TO Continue
				CONSTRUCT l_where_text ON note_code, 
				note_text 
				FROM sr_note_scan[1].* 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","UN1","construct-notes-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_where_text = " 1=1 " 
				END IF 

			ELSE 
				LET l_where_text = " 1=1 " 
			END IF 


			LET l_query_text = 
			"SELECT cmpy_code,", 
			"note_code,", 
			"note_text ", 
			"FROM notes ", 
			"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
			"AND ",l_where_text clipped," ", 
			"AND note_num = 1", 
			"ORDER BY cmpy_code,", 
			"note_code" 
			PREPARE s_notes FROM l_query_text 
			DECLARE c1_notes CURSOR FOR s_notes 

			#      LET arr_size = 0
			LET idx = 1 
			FOREACH c1_notes INTO l_rec_notes.cmpy_code, 
				l_arr_rec_note_scan[idx].* 
				#         LET arr_size = arr_size + 1
				#         IF idx = 400 THEN
				#            LET l_msgresp = kandoomsg("U",6100,idx)
				#            EXIT FOREACH
				#         END IF
				LET idx = idx + 1 
			END FOREACH 
			IF idx > 1 THEN 
				CALL l_arr_rec_note_scan.delete(idx) #remove the additional empty ROW (dynamic array) 
			END IF 
			#      IF arr_size != 0 THEN
			#         LET l_msgresp = kandoomsg("U",9113,idx)
			#         EXIT WHILE
			#      END IF
			IF l_arr_rec_note_scan.getlength() < 1 THEN 
				LET l_msgresp = kandoomsg("U",9101,idx) 
				#9101 No records satisfied Criteria
			END IF 


			RETURN l_arr_rec_note_scan,l_arr_rec_notes 
END FUNCTION 


###################################################################
# FUNCTION scan_notes()
#
#
###################################################################
FUNCTION scan_notes() 
	DEFINE idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_arr_rec_note_scan DYNAMIC ARRAY OF	RECORD 
			note_code LIKE notes.note_code, 
			note_text LIKE notes.note_text 
		END RECORD 
		DEFINE l_arr_rec_notes DYNAMIC ARRAY OF RECORD 
				note_text LIKE notes.note_text 
			END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
				
			LET l_msgresp = kandoomsg("H",1001,"") 
			#1001 F1 F2 F9 TO View
			WHENEVER ERROR CONTINUE 
			OPTIONS DELETE KEY f36 
			WHENEVER ERROR stop 

			CALL select_notes(false) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 

			#   CALL set_count(arr_size)
			#INPUT ARRAY l_arr_rec_note_scan WITHOUT DEFAULTS FROM sr_note_scan.* ATTRIBUTES(UNBUFFERED, auto append = false, append row = false, delte row = false, insert row = false)
			DISPLAY ARRAY l_arr_rec_note_scan TO sr_note_scan.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","UN1","input-arr-note_scan-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "FILTER" 
					CALL select_notes(true) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 

				BEFORE ROW 
					LET idx = arr_curr() 
					#         LET scrn = scr_line()
					#         IF arr_curr() <= arr_count() THEN
					#            DISPLAY l_arr_rec_note_scan[idx].* TO sr_note_scan[scrn].*
					#
					#         ELSE
					#            LET l_msgresp = kandoomsg("U",9001,"")
					#            #9001 There are no more rows in the direction you are going
					#         END IF

				ON ACTION "EDIT" 
					#			BEFORE FIELD note_text #EDIT
					IF idx > 0 THEN 
						CALL display_note(MODE_CLASSIC_EDIT,l_arr_rec_note_scan[idx].note_code) 
						RETURNING l_arr_rec_note_scan[idx].* 
						CALL select_notes(false) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 
					END IF 
					#         DISPLAY l_arr_rec_note_scan[idx].* TO sr_note_scan[scrn].*

					#        NEXT FIELD note_code
					#      AFTER ROW
					#         LET arr_size = arr_count()
					#         DISPLAY l_arr_rec_note_scan[idx].* TO sr_note_scan[scrn].*

				ON ACTION "NEW" 
					#      BEFORE INSERT
					#         IF idx > arr_size THEN
					#            LET l_msgresp = kandoomsg("U",9001,"")
					#            #9001 There are no more rows in the direction you are going
					#         ELSE
					CALL add_note(l_arr_rec_notes) RETURNING l_arr_rec_note_scan[idx].* 
					#            DISPLAY l_arr_rec_note_scan[idx].* TO sr_note_scan[scrn].*
					#
					#            NEXT FIELD note_code
					#         END IF
					CALL select_notes(false) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 

				ON ACTION "DELETE" 
					IF idx > 0 AND idx <= arr_count() THEN 
						#IF l_arr_rec_note_scan[idx].note_text = pr_deletion_text THEN
						DELETE FROM notes 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND note_code = l_arr_rec_note_scan[idx].note_code 
						CALL select_notes(false) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 
					END IF 

					#      ON KEY(F2) #delete marker
					#         CALL display_note("DELT",l_arr_rec_note_scan[idx].note_code)
					#            RETURNING l_arr_rec_note_scan[idx].*
					#					CALL select_notes(FALSE) RETURNING l_arr_rec_note_scan
					#         DISPLAY l_arr_rec_note_scan[idx].* TO sr_note_scan[scrn].*
					#
					#         NEXT FIELD note_code

				ON ACTION ("ACCEPT","DOUBLECLICK") 
					#ON KEY(F9)
					CALL display_note("VIEW",l_arr_rec_note_scan[idx].note_code) 
					RETURNING l_arr_rec_note_scan[idx].* 
					CALL select_notes(false) RETURNING l_arr_rec_note_scan,l_arr_rec_notes 
					#         NEXT FIELD note_code

					#      AFTER INPUT
					#         LET arr_size = arr_count()

					#      ON KEY (control-w)
					#         CALL kandoohelp("")

			END DISPLAY 

			#   FOR idx = 1 TO arr_size
			#      IF l_arr_rec_note_scan[idx].note_text = pr_deletion_text THEN
			#         DELETE FROM notes
			#            WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			#              AND note_code = l_arr_rec_note_scan[idx].note_code
			#      END IF
			#   END FOR

			LET int_flag = false 
			LET quit_flag = false 

END FUNCTION 


###################################################################
# FUNCTION display_note(p_option, p_note_code)
#
#
###################################################################
FUNCTION display_note(p_option, p_note_code) 
	DEFINE p_option CHAR(4) 
	DEFINE p_note_code LIKE notes.note_code 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF RECORD 
			note_text LIKE notes.note_text 
		END RECORD 
		DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
		IF p_note_code IS NULL 
		OR p_note_code = " " THEN 
			RETURN p_note_code, 
			l_arr_rec_notes[1].note_text 
		END IF 
		OPEN WINDOW u147 with FORM "U147" 
		CALL windecoration_u("U147") 

		WHENEVER ERROR CONTINUE 
		OPTIONS DELETE KEY f2 
		WHENEVER ERROR stop 
		DISPLAY p_note_code TO note_code 

		DECLARE c2_notes CURSOR FOR 
		SELECT * FROM notes 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND note_code = p_note_code 
		ORDER BY cmpy_code, 
		note_code, 
		note_num 
		LET idx = 0 
		FOREACH c2_notes INTO l_rec_notes.* 
			LET idx = idx + 1 
			LET l_arr_rec_notes[idx].note_text = l_rec_notes.note_text 
		END FOREACH 

		#   CALL set_count(idx)

		CASE p_option 
			WHEN "VIEW" 
				LET l_msgresp = kandoomsg("U",1008,"") 
				# F3/F4 OK TO Cont
				DISPLAY ARRAY l_arr_rec_notes TO sr_note_scan.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","UN1","display-arr-notes-1") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END DISPLAY 


			WHEN MODE_CLASSIC_EDIT 
				LET l_msgresp = kandoomsg("U",1047,"Note") 

				INPUT ARRAY l_arr_rec_notes WITHOUT DEFAULTS FROM sr_note_scan.* 


					BEFORE INPUT 
						CALL publish_toolbar("kandoo","UN1","input-arr-notes") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END INPUT 

				IF not(int_flag OR quit_flag) THEN 
					DELETE FROM notes 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND note_code = p_note_code 

					FOR idx = 1 TO arr_count() 
						INSERT INTO notes VALUES ( glob_rec_kandoouser.cmpy_code, 
						p_note_code, 
						idx, 
						l_arr_rec_notes[idx].note_text) 
					END FOR 

				END IF 

				#      WHEN "DELT"
				#         FOR idx = 1 TO 12 ### 12 IS scrn ARRAY size in U147 ###
				#            DISPLAY l_arr_rec_notes[idx].note_text
				#                 TO sr_note_scan[idx].note_text
				#
				#         END FOR
				#
				#         MENU " Note Deletion "
				#      	BEFORE MENU
				#      	 	CALL publish_toolbar("kandoo","UN1","menu-note_deletion")
				#
				#				ON ACTION "WEB-HELP"
				#			CALL onlineHelp(getModuleId(),NULL)
				#
				#			ON ACTION "actToolbarManager"
				#				 	CALL setupToolbar()
				#
				#
				#            command"Yes"
				#               LET l_arr_rec_notes[1].note_text = pr_deletion_text
				#               EXIT MENU
				#            command"No"
				#               EXIT MENU
				#            COMMAND KEY (control-w)
				#               CALL kandoohelp("")
				#         END MENU
				#
		END CASE 

		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW u147 

		WHENEVER ERROR CONTINUE 
		OPTIONS DELETE KEY f36 
		WHENEVER ERROR stop 

		RETURN p_note_code, 
		l_arr_rec_notes[1].note_text 
END FUNCTION 


###################################################################
# FUNCTION add_note(FUNCTION add_note(p_arr_rec_notes))
#
#
###################################################################
FUNCTION add_note(p_arr_rec_notes) 
	DEFINE p_arr_rec_notes DYNAMIC ARRAY OF RECORD 
			note_text LIKE notes.note_text 
		END RECORD 
		DEFINE l_note_count SMALLINT 
		DEFINE l_time CHAR(8) 
		DEFINE l_rec_notes RECORD LIKE notes.* 
		DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
		OPEN WINDOW u147 with FORM "U147" 
		CALL windecoration_u("U147") 

		WHILE true 
			INPUT BY NAME l_rec_notes.note_code WITHOUT DEFAULTS 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","UN1","input-note_code-1") -- albo kd-511 

				BEFORE FIELD note_code 
					LET l_note_count = 0 
					LET l_msgresp = kandoomsg("U",1038,"") 
					#1038 Note Addition - CTRL-I TO Image Existing Note
					LET l_time = time 
					LET l_rec_notes.note_code = today USING "yymmdd", 
					l_time[1,2],l_time[4,5],l_time[7,8] 
					WHILE note_exists(l_rec_notes.note_code) 
						LET l_rec_notes.note_code = l_rec_notes.note_code - 1 
					END WHILE 

				ON KEY (control-b) 
					CALL show_note(glob_rec_kandoouser.cmpy_code) RETURNING p_arr_rec_notes 
					#LET l_rec_notes.note_code = show_note(glob_rec_kandoouser.cmpy_code)
					#DISPLAY BY NAME l_rec_notes.note_code

					NEXT FIELD note_code 

				ON KEY (F9) 
					CALL image_note() RETURNING p_arr_rec_notes 
					#returning l_rec_notes.note_code,
					#          l_note_count
					IF p_arr_rec_notes.getlength() < 1 THEN 
						#IF l_rec_notes.note_code IS NULL THEN
						NEXT FIELD note_code 
					END IF 
					#            DISPLAY BY NAME l_rec_notes.note_code

					EXIT INPUT 

				AFTER FIELD note_code 
					IF l_rec_notes.note_code IS NULL 
					OR l_rec_notes.note_code = " " THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered"
						NEXT FIELD note_code 
					END IF 
					IF note_exists(l_rec_notes.note_code) THEN 
						LET l_msgresp = kandoomsg("U",9104,"") 
						#9104 RECORD Already Exists "
						NEXT FIELD note_code 
					END IF 

					#         ON KEY (control-w)
					#            CALL kandoohelp("")

			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CLOSE WINDOW u147 
				RETURN " ", 
				" " 
			END IF 

			WHENEVER ERROR CONTINUE 
			OPTIONS DELETE KEY f2 
			WHENEVER ERROR stop 

			LET l_msgresp = kandoomsg("U",1020,"Note") 
			#      CALL set_count(l_note_count)

			INPUT ARRAY p_arr_rec_notes WITHOUT DEFAULTS FROM sr_note_scan.* attributes(UNBUFFERED) 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","UN1","input-arr-notes-2") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END INPUT 

			LET l_note_count = arr_count() 
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		FOR idx = 1 TO arr_count() 
			INSERT INTO notes VALUES (glob_rec_kandoouser.cmpy_code, 
			l_rec_notes.note_code, 
			idx, 
			p_arr_rec_notes[idx].note_text) 
		END FOR 

		CLOSE WINDOW u147 

		WHENEVER ERROR CONTINUE 
		OPTIONS DELETE KEY f36 
		WHENEVER ERROR stop 

		RETURN l_rec_notes.note_code, 
		p_arr_rec_notes[1].note_text 
END FUNCTION 



###################################################################
# FUNCTION show_note(p_cmpy)
#
# RETURN l_arr_rec_notes
###################################################################
FUNCTION show_note(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF #array[50] OF 
	RECORD 
		note_code LIKE notes.note_code, 
		note_text LIKE notes.note_text 
	END RECORD 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE idx SMALLINT 
	#      scrn SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u123 with FORM "U123" 
	CALL windecoration_u("U123") 

	LET l_msgresp = kandoomsg("U",1001,"") 
	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW u123 
		LET int_flag = false 
		LET quit_flag = false 
		#LET l_arr_rec_notes[1].note_code = NULL
		LET l_arr_rec_notes = NULL 
		#RETURN l_arr_rec_notes[1].note_code
		RETURN l_arr_rec_notes 
	END IF 

	CONSTRUCT l_where_text ON note_code, 
	note_text 
	FROM sr_notes[1].* 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","UN1","construct-notes-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW u123 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_arr_rec_notes = NULL 
		RETURN l_arr_rec_notes 
		#LET l_arr_rec_notes[1].note_code = NULL
		#RETURN l_arr_rec_notes[1].note_code
	END IF 
	LET l_query_text = 
	"SELECT * ", 
	"FROM notes ", 
	"WHERE ",l_where_text clipped," ", 
	"AND cmpy_code = \"",p_cmpy,"\" ", 
	"ORDER BY cmpy_code,", 
	"note_code,", 
	"note_num" 
	PREPARE note FROM l_query_text 
	DECLARE c3_notes CURSOR FOR note 

	LET idx = 0 
	FOREACH c3_notes INTO l_rec_notes.* 
		LET idx = idx + 1 
		LET l_arr_rec_notes[idx].note_code = l_rec_notes.note_code 
		LET l_arr_rec_notes[idx].note_text = l_rec_notes.note_text 
		#      IF idx = 50 THEN
		#         LET l_msgresp = kandoomsg("U",6100,idx)
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,idx) 

	#   CALL set_count(idx)

	INPUT ARRAY l_arr_rec_notes WITHOUT DEFAULTS FROM sr_notes.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","UN1","input-arr-notes-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			#         IF idx <= arr_count() THEN
			#            DISPLAY l_arr_rec_notes[idx].* TO sr_notes[scrn].*

			#         END IF
		BEFORE FIELD note_text 
			EXIT INPUT 
			#      AFTER ROW
			#         DISPLAY l_arr_rec_notes[idx].* TO sr_notes[scrn].*

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	LET idx = arr_curr() 

	IF int_flag OR quit_flag THEN 
		LET l_arr_rec_notes = NULL 
		#LET l_arr_rec_notes[idx].note_code = NULL
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW u123 

	#RETURN l_arr_rec_notes[idx].note_code
	RETURN l_arr_rec_notes 
END FUNCTION 



###################################################################
# FUNCTION image_note()
#
#
###################################################################
FUNCTION image_note() 
	DEFINE l_rec_notes RECORD LIKE notes.* 
	DEFINE l_time CHAR(8) 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE l_arr_rec_notes DYNAMIC ARRAY OF RECORD 
			note_text LIKE notes.note_text 
		END RECORD 
	DEFINE l_msgresp LIKE language.yes_flag
			
		LET l_msgresp = kandoomsg("U",1020,"Note Code") 
		#1020 Enter note code Details
		INPUT BY NAME l_rec_notes.note_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","UN1","input-note_code-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (control-b) 
				CALL show_note(glob_rec_kandoouser.cmpy_code) RETURNING l_arr_rec_notes 
				# LET l_rec_notes.note_code = show_note(glob_rec_kandoouser.cmpy_code)
				#DISPLAY BY NAME l_rec_notes.note_code

				NEXT FIELD note_code 

			AFTER FIELD note_code 
				IF l_rec_notes.note_code IS NULL 
				OR l_rec_notes.note_code = "" THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9007 "Value must ber entered"
					NEXT FIELD note_code 
				END IF 
				IF NOT note_exists( l_rec_notes.note_code) THEN 
					LET l_msgresp = kandoomsg("U",9104,"") 
					#9025 "Note already exists
					NEXT FIELD note_code 
				END IF 

				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_notes.note_code = NULL 
			RETURN l_rec_notes.note_code, 0 
		END IF 

		DECLARE c4_notes CURSOR FOR 
		SELECT * 
		FROM notes 
		WHERE notes.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND notes.note_code = l_rec_notes.note_code 
		ORDER BY cmpy_code, 
		note_code, 
		note_num 
		LET idx = 0 
		FOREACH c4_notes INTO l_rec_notes.* 
			LET idx = idx + 1 
			LET l_arr_rec_notes[idx].note_text = l_rec_notes.note_text 
		END FOREACH 

		CALL set_count(idx) 
		LET l_msgresp = kandoomsg("U",1020,"Note") 
		#1020 " Enter Note Drtails  - OK TO Continue
		DISPLAY ARRAY l_arr_rec_notes TO sr_note_scan.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","UN1","display-arr-notes-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_notes.note_code = NULL 
			RETURN l_rec_notes.note_code, 0 
		END IF 
		LET l_time = time 
		LET l_rec_notes.note_code = today USING "yymmdd", 
		l_time[1,2],l_time[4,5],l_time[7,8] 
		WHILE note_exists(l_rec_notes.note_code) 
			LET l_rec_notes.note_code = l_rec_notes.note_code - 1 
		END WHILE 

		LET l_msgresp = kandoomsg("U",1020,"Note Code") 
		INPUT BY NAME l_rec_notes.note_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","UN1","input-note_code-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "LOOKUP" infield (note_code) 
				CALL show_note(glob_rec_kandoouser.cmpy_code) RETURNING l_arr_rec_notes 
				#LET l_rec_notes.note_code = show_note(glob_rec_kandoouser.cmpy_code)
				DISPLAY BY NAME l_rec_notes.note_code 

				NEXT FIELD note_code 

			AFTER FIELD note_code 
				IF l_rec_notes.note_code IS NULL 
				OR l_rec_notes.note_code = "" THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					NEXT FIELD note_code 
				END IF 

				IF note_exists(l_rec_notes.note_code) THEN 
					LET l_msgresp = kandoomsg("U",9104,"") 
					NEXT FIELD note_code 
				END IF 

				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_notes.note_code = NULL 
			#RETURN l_rec_notes.note_code, 0
			#   ELSE
			#RETURN l_rec_notes.note_code,idx
		END IF 
		RETURN l_arr_rec_notes 
END FUNCTION 



###################################################################
# FUNCTION note_exists(p_note_code)
#
#
###################################################################
FUNCTION note_exists(p_note_code) 
	DEFINE p_note_code LIKE notes.note_code 
	DEFINE l_cnt SMALLINT 

	SELECT count(*) INTO l_cnt FROM notes 
	WHERE notes.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND notes.note_code = p_note_code 

	RETURN l_cnt 
END FUNCTION 


