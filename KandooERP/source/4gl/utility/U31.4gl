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

	Source code beautified by beautify.pl on 2020-01-03 18:54:44	$Id: $
}



#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U31 - Maintainence program FOR Message Library
#

#    TO maintain the integrity of the Message Library there
#    are three(3) MESSAGEs that MUST exist FOR each language
#
#       i.        source_ind = "U",
#                 msg_num = 1,
#                 msg1_text = "",
#                 msg2_text = "",
#                 msg_ind = "7",
#
#       ii.       source_ind = "U",
#                 msg_num = 2,
#                 msg1_text = "Any Key TO Continue", #Words TO this effect
#                 msg2_text = "",
#
#       iii.      source_ind = "U",
#                 msg_num = 3,
#                 msg1_text = "Please Answer (Y)es OR (N)o.",
#                           #Words TO this effect
#                 msg2_text = "",
#                 msg_ind = "9",
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

	DEFINE modu_rec_language RECORD LIKE language.* 
	DEFINE modu_arr_rec_formathelp array[9] OF RECORD 
		scroll_num CHAR(1), 
		desc_text CHAR(40) 
	END RECORD 
	DEFINE modu_arr_rec_actionhelp array[9] OF RECORD 
		scroll_num CHAR(1), 
		desc_text CHAR(40) 
	END RECORD 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_operation_status SMALLINT
	
	CALL setModuleId("U31") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	OPEN WINDOW u200 with FORM "U200" 
	CALL windecoration_u("U200") 

	CALL init_help() 
	--WHILE select_lang() 
	MENU 
		BEFORE MENU
			HIDE OPTION "Scan and Edit messages"

		COMMAND "Select a language"
			CALL select_lang() RETURNING l_operation_status
			IF l_operation_status = TRUE THEN
				SHOW OPTION "Scan and Edit messages"
			END IF

		COMMAND "Scan and Edit messages"
			CALL scan_kandoomsg() 

		COMMAND "Exit"
			EXIT PROGRAM
			CLOSE WINDOW u200 
	END MENU 
	
END MAIN 


###################################################################
# FUNCTION select_lang()
#
#
###################################################################
FUNCTION select_lang()
	DEFINE l_msgresp LIKE language.yes_flag
	 
	CLEAR FORM 
	IF modu_rec_language.language_code IS NULL THEN 
		LET modu_rec_language.language_code = glob_rec_kandoouser.language_code 
	END IF 
	INPUT BY NAME modu_rec_language.language_code 
	WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U31","input-language") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			LET modu_rec_language.language_code = show_language() 
			DISPLAY BY NAME modu_rec_language.language_code 

			NEXT FIELD language_code 

		AFTER FIELD language_code 
			SELECT * INTO modu_rec_language.* 
			FROM language 
			WHERE language_code = modu_rec_language.language_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 "Record NOT found - Try Window"
				CLEAR language_text 
				NEXT FIELD language_code 
			ELSE 
				DISPLAY BY NAME modu_rec_language.language_text 

			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION scan_kandoomsg()
#
#
###################################################################
FUNCTION scan_kandoomsg() 
	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_arr_rec_kandoomsg DYNAMIC ARRAY OF #array[1000] OF 
	RECORD 
		delete_flag CHAR(1), 
		source_ind LIKE kandoomsg.source_ind, 
		msg_num LIKE kandoomsg.msg_num, 
		msg1_text LIKE kandoomsg.msg1_text 
	END RECORD 
	DEFINE l_where_text STRING 
	DEFINE l_string STRING 
	DEFINE l_query_text STRING 
	DEFINE l_text CHAR(50) 
	DEFINE l_delete_flag CHAR(1) 
	DEFINE l_ans CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_message STRING
	
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue
	CONSTRUCT BY NAME l_where_text ON source_ind, 
	msg_num, 
	msg1_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","U31","construct-kandoomsg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching Database - Please Wait
	LET l_query_text = "SELECT * FROM kandoomsg ", 
	"WHERE language_code = \"",modu_rec_language.language_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY source_ind,msg_num,language_code" 
	PREPARE s_kandoomsg FROM l_query_text 
	DECLARE c_kandoomsg CURSOR FOR s_kandoomsg 
	LET idx = 0 
	FOREACH c_kandoomsg INTO l_rec_kandoomsg.* 
		LET l_string = l_rec_kandoomsg.msg1_text clipped, " ", l_rec_kandoomsg.msg2_text 
		# 65 chars maximum
		# .. denotes more info
		IF length(l_string) > 62 THEN 
			LET l_string = l_string[1,62],".." 
		END IF 
		LET idx = idx + 1 
		LET l_arr_rec_kandoomsg[idx].delete_flag = NULL 
		LET l_arr_rec_kandoomsg[idx].source_ind = l_rec_kandoomsg.source_ind 
		LET l_arr_rec_kandoomsg[idx].msg_num = l_rec_kandoomsg.msg_num 
		LET l_arr_rec_kandoomsg[idx].msg1_text = l_string 
		#      IF idx = 1000 THEN
		#         LET l_msgresp = kandoomsg("U",6100,idx)
		#         #6100 First idx records selected
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
	END IF 

	WHENEVER ERROR CONTINUE 
	OPTIONS DELETE KEY f36 
	WHENEVER ERROR stop 

	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("U",1106,"") 

	#1106 "F1 TO Add - F2 TO Delete - F9 TO Test..."
	INPUT ARRAY l_arr_rec_kandoomsg WITHOUT DEFAULTS FROM sr_kandoomsg.* attributes(append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U31","input-arr-kandoomsg") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 

		ON KEY (F9) --test MESSAGE 
			IF l_arr_rec_kandoomsg[idx].source_ind IS NOT NULL THEN 
				SELECT * INTO l_rec_kandoomsg.* 
				FROM kandoomsg 
				WHERE source_ind = l_arr_rec_kandoomsg[idx].source_ind 
				AND msg_num = l_arr_rec_kandoomsg[idx].msg_num 
				IF l_rec_kandoomsg.msg_ind = "4" THEN 
					LET l_text = "TEST|VALUE" 
					LET l_ans = kandoomsg(l_arr_rec_kandoomsg[idx].source_ind, 
					l_arr_rec_kandoomsg[idx].msg_num, 
					l_text) 
				ELSE 
					LET l_ans = kandoomsg(l_arr_rec_kandoomsg[idx].source_ind, 
					l_arr_rec_kandoomsg[idx].msg_num, 
					"VALUE") 
				END IF 
				IF fgl_keyval("F9") = fgl_lastkey() THEN 
					CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
				END IF 

				#            DISPLAY "" AT 1,1
				#            DISPLAY "" AT 2,1
				DISPLAY " F1 TO Add - F2 TO Delete - RETURN TO Edit - F9 TO Test " 
				TO lbinfo1 

			END IF 

		BEFORE FIELD delete_flag 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			LET l_delete_flag = l_arr_rec_kandoomsg[idx].delete_flag 
			#         DISPLAY l_arr_rec_kandoomsg[idx].*
			#              TO sr_kandoomsg[scrn].*

		AFTER FIELD delete_flag 
			LET l_arr_rec_kandoomsg[idx].delete_flag = l_delete_flag 
			#         DISPLAY l_arr_rec_kandoomsg[idx].delete_flag
			#              TO sr_kandoomsg[scrn].delete_flag

		BEFORE FIELD source_ind 
			IF l_arr_rec_kandoomsg[idx].source_ind IS NOT NULL THEN 
				IF change_messge(l_arr_rec_kandoomsg[idx].source_ind, 
				l_arr_rec_kandoomsg[idx].msg_num) THEN 
					SELECT * INTO l_rec_kandoomsg.* FROM kandoomsg 
					WHERE source_ind = l_arr_rec_kandoomsg[idx].source_ind 
					AND msg_num = l_arr_rec_kandoomsg[idx].msg_num 
					AND language_code = modu_rec_language.language_code 
					LET l_string = l_rec_kandoomsg.msg1_text clipped, 
					" ", l_rec_kandoomsg.msg2_text 
					# 65 chars maximum
					# .. denotes more info
					IF length(l_string) > 62 THEN 
						LET l_arr_rec_kandoomsg[idx].msg1_text = l_string[1,63],".." 
					ELSE 
						LET l_arr_rec_kandoomsg[idx].msg1_text = l_rec_kandoomsg.msg1_text 
					END IF 
				END IF 
			END IF 
			NEXT FIELD delete_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				IF idx > 1 THEN 
					LET i = idx-1 
				ELSE 
					LET i = idx+1 
				END IF 
				CALL add_message(l_arr_rec_kandoomsg[i].source_ind) 
				RETURNING l_arr_rec_kandoomsg[idx].source_ind, 
				l_arr_rec_kandoomsg[idx].msg_num, 
				l_arr_rec_kandoomsg[idx].msg1_text 
				LET l_string = l_arr_rec_kandoomsg[idx].msg1_text 
				# 65 chars maximum
				# .. denotes more info
				IF length(l_string) > 62 THEN 
					LET l_arr_rec_kandoomsg[idx].msg1_text = l_string[1,63],".." 
				END IF 
				IF l_arr_rec_kandoomsg[idx].source_ind IS NULL THEN 
					FOR idx = arr_curr() TO arr_count() 
						LET l_arr_rec_kandoomsg[idx].* = l_arr_rec_kandoomsg[idx+1].* 
						#                  IF scrn <= 12 THEN
						#                     IF l_arr_rec_kandoomsg[idx].source_ind IS NULL THEN
						#                        CLEAR sr_kandoomsg[scrn].*
						#                        INITIALIZE l_arr_rec_kandoomsg[idx].* TO NULL
						#                     ELSE
						#                        DISPLAY l_arr_rec_kandoomsg[idx].*
						#                             TO sr_kandoomsg[scrn].*
						#
						#                     END IF
						#                     LET scrn = scrn + 1
						#                  END IF
						IF idx > arr_count() THEN 
							EXIT FOR 
						END IF 
					END FOR 
					INITIALIZE l_arr_rec_kandoomsg[idx].* TO NULL 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 "There are no more rows in the direction you are going "
				END IF 
			END IF 
			NEXT FIELD delete_flag 

		ON KEY (F2) #delete marker 
			IF l_arr_rec_kandoomsg[idx].source_ind IS NOT NULL THEN 
				IF l_arr_rec_kandoomsg[idx].delete_flag IS NULL THEN 
					LET l_arr_rec_kandoomsg[idx].delete_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_kandoomsg[idx].delete_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 

			NEXT FIELD delete_flag 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt != 0 THEN 
			LET l_ans = kandoomsg("U",8000,l_del_cnt) 
			### Confirm TO Delete ",l_del_cnt," Message(s)? (Y/N)"
			IF l_ans = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_kandoomsg[idx].delete_flag = "*" THEN 
						DELETE FROM kandoomsg 
						WHERE source_ind = l_arr_rec_kandoomsg[idx].source_ind 
						AND msg_num = l_arr_rec_kandoomsg[idx].msg_num 
						AND language_code = modu_rec_language.language_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

	OPTIONS DELETE KEY f2 

END FUNCTION 


###################################################################
# FUNCTION change_messge(p_source_ind,p_msg_num)
#
#
###################################################################
FUNCTION change_messge(p_source_ind,p_msg_num) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE p_msg_num LIKE kandoomsg.msg_num 
	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_temp_ind LIKE kandoomsg.msg_ind 
	DEFINE l_last_char CHAR(1) 
	DEFINE l_warning CHAR(7) 
	DEFINE l_length SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_formonly RECORD
		temp_text CHAR(40),
		action_text CHAR(40),
		format_text CHAR(40)
	END RECORD
	
	OPEN WINDOW u201 with FORM "U201" 
	CALL windecoration_u("U201") 

	SELECT kandoomsg.* 
	INTO l_rec_kandoomsg.* 
	FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND msg_num = p_msg_num 
	AND language_code = modu_rec_language.language_code 
	LET i = l_rec_kandoomsg.msg_ind 
	LET l_rec_formonly.action_text = modu_arr_rec_actionhelp[i].desc_text 
	LET i = l_rec_kandoomsg.format_ind 
	LET l_rec_formonly.format_text = modu_arr_rec_formathelp[i].desc_text 

	DISPLAY BY NAME l_rec_kandoomsg.msg_num, 
	l_rec_kandoomsg.source_ind, 
	l_rec_kandoomsg.msg1_text, 
	l_rec_kandoomsg.msg2_text, 
	l_rec_kandoomsg.btn1_text, 
	l_rec_kandoomsg.btn2_text, 
	l_rec_kandoomsg.msg_ind, 
	l_rec_kandoomsg.format_ind, 
	l_rec_kandoomsg.help_num, 
	l_rec_formonly.action_text, 
	l_rec_formonly.format_text 

	INPUT BY NAME l_rec_kandoomsg.msg1_text, 
	l_rec_kandoomsg.msg2_text, 
	l_rec_kandoomsg.btn1_text, 
	l_rec_kandoomsg.btn2_text, 
	l_rec_kandoomsg.msg_ind, 
	l_rec_kandoomsg.format_ind, 
	l_rec_kandoomsg.help_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U31","input-kandoomsg-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			CASE 
				WHEN infield(msg_ind) 
					LET l_temp_ind = l_rec_kandoomsg.msg_ind 
					LET l_rec_formonly.temp_text = l_rec_formonly.action_text 
					CALL show_ind("ACTION") 
					RETURNING l_rec_kandoomsg.msg_ind, 
					l_rec_formonly.action_text 
					IF l_rec_kandoomsg.msg_ind IS NULL 
					AND l_rec_formonly.action_text IS NULL THEN 
						LET l_rec_kandoomsg.msg_ind = l_temp_ind 
						LET l_rec_formonly.action_text = l_rec_formonly.temp_text 
					ELSE 
						DISPLAY BY NAME l_rec_kandoomsg.msg_ind, 
						l_rec_formonly.action_text 

					END IF 

				WHEN infield(format_ind) 
					LET l_temp_ind = l_rec_kandoomsg.format_ind 
					LET l_rec_formonly.temp_text = l_rec_formonly.format_text 
					CALL show_ind("FORMAT") 
					RETURNING l_rec_kandoomsg.format_ind, 
					l_rec_formonly.format_text 
					IF l_rec_kandoomsg.format_ind IS NULL 
					AND l_rec_formonly.format_text IS NULL THEN 
						LET l_rec_kandoomsg.format_ind = l_temp_ind 
						LET l_rec_formonly.format_text = l_rec_formonly.temp_text 
					ELSE 
						DISPLAY BY NAME l_rec_kandoomsg.format_ind, 
						l_rec_formonly.format_text 

					END IF 
			END CASE 

		AFTER FIELD msg_ind 
			IF l_rec_kandoomsg.msg_ind IS NOT NULL THEN 
				IF l_rec_kandoomsg.msg_ind >= "1" 
				AND l_rec_kandoomsg.msg_ind <= "9" THEN 
					LET i = l_rec_kandoomsg.msg_ind 
					LET l_rec_formonly.action_text = modu_arr_rec_actionhelp[i].desc_text 
					DISPLAY BY NAME l_rec_formonly.action_text 

				END IF 
				IF l_rec_kandoomsg.msg_ind = "4" THEN 
					LET l_rec_kandoomsg.format_ind = "5" 
				END IF 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_kandoomsg.format_ind IS NOT NULL THEN 
				IF l_rec_kandoomsg.msg_ind = "4" THEN 
					LET l_rec_kandoomsg.format_ind = "5" 
				END IF 
				IF l_rec_kandoomsg.format_ind >= "1" 
				AND l_rec_kandoomsg.format_ind <= "9" THEN 
					LET i = l_rec_kandoomsg.format_ind 
					LET l_rec_formonly.format_text = modu_arr_rec_formathelp[i].desc_text 
					DISPLAY BY NAME l_rec_formonly.format_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_kandoomsg.msg2_text IS NULL THEN 
					LET l_length = length(l_rec_kandoomsg.msg1_text) 
					IF l_length != 0 THEN 
						LET l_last_char = l_rec_kandoomsg.msg1_text[l_length] 
					END IF 
				ELSE 
					LET l_length = length(l_rec_kandoomsg.msg2_text) 
					IF l_length != 0 THEN 
						LET l_last_char = l_rec_kandoomsg.msg2_text[l_length] 
					END IF 
				END IF 
				LET l_warning = l_rec_kandoomsg.msg1_text[1,7] 
				CASE 
					WHEN l_rec_kandoomsg.msg_ind = "4" 
						OR l_rec_kandoomsg.msg_ind = "8" 
						IF l_last_char != "?" THEN 
							LET l_msgresp = kandoomsg("U",9918,"") 
							#9918 This MESSAGE must END with a "?"
							NEXT FIELD msg1_text 
						END IF 
						LET l_warning = upshift(l_warning) 
						IF l_warning = "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9921,"") 
							#9921 This MESSAGE cannot begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
					WHEN l_rec_kandoomsg.msg_ind = "6" 
						IF l_last_char != "." 
						AND l_last_char != ":" 
						AND l_last_char != "!" THEN 
							LET l_msgresp = kandoomsg("U",9919,"") 
							#9919 This field must END with "." ":" OR "!"
							NEXT FIELD msg1_text 
						END IF 
						IF l_warning != "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9920,"") 
							#9920 This MESSAGE must begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
					OTHERWISE 
						IF l_last_char != "." 
						AND l_last_char != ":" 
						AND l_last_char != "!" THEN 
							LET l_msgresp = kandoomsg("U",9919,"") 
							#9919 This field must END with "." ":" OR "!"
							NEXT FIELD msg1_text 
						END IF 
						LET l_warning = upshift(l_warning) 
						IF l_warning = "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9921,"") 
							#9921 This MESSAGE cannot begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
				END CASE 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	CLOSE WINDOW u201 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN false 
	ELSE 
		UPDATE kandoomsg 
		SET kandoomsg.* = l_rec_kandoomsg.* 
		WHERE source_ind = p_source_ind 
		AND msg_num = p_msg_num 
		AND language_code = modu_rec_language.language_code 
		RETURN true 
	END IF 
END FUNCTION 



###################################################################
# FUNCTION add_MESSAGE(p_source_ind)
#
#
###################################################################
FUNCTION add_message(p_source_ind) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_temp_ind LIKE kandoomsg.msg_ind 
	DEFINE l_last_char CHAR(1) 
	DEFINE l_warning CHAR(7) 
	DEFINE l_length SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_formonly RECORD
		temp_text CHAR(40),
		action_text CHAR(40),
		format_text CHAR(40)
	END RECORD

	
	OPEN WINDOW u201 with FORM "U201" 
	CALL windecoration_u("U201") 

	LET l_rec_kandoomsg.source_ind = p_source_ind 
	SELECT max(msg_num) 
	INTO l_rec_kandoomsg.msg_num 
	FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND language_code = modu_rec_language.language_code 
	LET l_rec_kandoomsg.msg_num = l_rec_kandoomsg.msg_num + 1 
	LET l_rec_kandoomsg.msg_ind = "9" 
	LET l_rec_kandoomsg.format_ind = "9" 

	INPUT BY NAME l_rec_kandoomsg.msg_num, 
	l_rec_kandoomsg.source_ind, 
	l_rec_kandoomsg.msg1_text, 
	l_rec_kandoomsg.msg2_text, 
	l_rec_kandoomsg.msg_ind, 
	l_rec_kandoomsg.format_ind, 
	l_rec_kandoomsg.help_num 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U31","input-kandoomsg-2") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			CASE 
				WHEN infield(msg_ind) 
					LET l_temp_ind = l_rec_kandoomsg.msg_ind 
					LET l_rec_formonly.temp_text = l_rec_formonly.action_text 
					CALL show_ind("ACTION") 
					RETURNING l_rec_kandoomsg.msg_ind, 
					l_rec_formonly.action_text 
					IF l_rec_kandoomsg.msg_ind IS NULL 
					AND l_rec_formonly.action_text IS NULL THEN 
						LET l_rec_kandoomsg.msg_ind = l_temp_ind 
						LET l_rec_formonly.action_text = l_rec_formonly.temp_text 
					ELSE 
						DISPLAY BY NAME l_rec_kandoomsg.msg_ind, 
						l_rec_formonly.action_text 

					END IF 

				WHEN infield(format_ind) 
					LET l_temp_ind = l_rec_kandoomsg.format_ind 
					LET l_rec_formonly.temp_text = l_rec_formonly.format_text 
					CALL show_ind("FORMAT") 
					RETURNING l_rec_kandoomsg.format_ind, 
					l_rec_formonly.format_text 
					IF l_rec_kandoomsg.format_ind IS NULL 
					AND l_rec_formonly.format_text IS NULL THEN 
						LET l_rec_kandoomsg.format_ind = l_temp_ind 
						LET l_rec_formonly.format_text = l_rec_formonly.temp_text 
					ELSE 
						DISPLAY BY NAME l_rec_kandoomsg.format_ind, 
						l_rec_formonly.format_text 

					END IF 
			END CASE 

		AFTER FIELD msg_ind 
			IF l_rec_kandoomsg.msg_ind IS NOT NULL THEN 
				IF l_rec_kandoomsg.msg_ind >= "1" 
				AND l_rec_kandoomsg.msg_ind <= "9" THEN 
					LET i = l_rec_kandoomsg.msg_ind 
					LET l_rec_formonly.action_text = modu_arr_rec_actionhelp[i].desc_text 
					DISPLAY BY NAME l_rec_formonly.action_text

				END IF 
				IF l_rec_kandoomsg.msg_ind = "4" THEN 
					LET l_rec_kandoomsg.format_ind = "5" 
				END IF 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_kandoomsg.msg_ind = "4" THEN 
				LET l_rec_kandoomsg.format_ind = "5" 
			END IF 
			IF l_rec_kandoomsg.format_ind IS NOT NULL THEN 
				IF l_rec_kandoomsg.format_ind >= "1" 
				AND l_rec_kandoomsg.format_ind <= "9" THEN 
					LET i = l_rec_kandoomsg.format_ind 
					LET l_rec_formonly.format_text = modu_arr_rec_formathelp[i].desc_text 
					DISPLAY BY NAME l_rec_formonly.format_text 

				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT unique 1 
				FROM kandoomsg 
				WHERE source_ind = l_rec_kandoomsg.source_ind 
				AND msg_num = l_rec_kandoomsg.msg_num 
				AND language_code = modu_rec_language.language_code 
				IF sqlca.sqlcode = 0 THEN 
					LET l_msgresp = kandoomsg("U",9104,"") 
					#9104 "Record Already Exists"
					NEXT FIELD msg_num 
				END IF 
				IF l_rec_kandoomsg.msg2_text IS NULL THEN 
					LET l_length = length(l_rec_kandoomsg.msg1_text) 
					IF l_length != 0 THEN 
						LET l_last_char = l_rec_kandoomsg.msg1_text[l_length] 
					END IF 
				ELSE 
					LET l_length = length(l_rec_kandoomsg.msg2_text) 
					IF l_length != 0 THEN 
						LET l_last_char = l_rec_kandoomsg.msg2_text[l_length] 
					END IF 
				END IF 
				LET l_warning = l_rec_kandoomsg.msg1_text[1,7] 
				CASE 
					WHEN l_rec_kandoomsg.msg_ind = "4" 
						OR l_rec_kandoomsg.msg_ind = "8" 
						IF l_last_char != "?" THEN 
							LET l_msgresp = kandoomsg("U",9918,"") 
							#9918 This MESSAGE must END with a "?"
							NEXT FIELD msg1_text 
						END IF 
						LET l_warning = upshift(l_warning) 
						IF l_warning = "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9921,"") 
							#9921 This MESSAGE cannot begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
					WHEN l_rec_kandoomsg.msg_ind = "6" 
						IF l_last_char != "." 
						AND l_last_char != ":" 
						AND l_last_char != "!" THEN 
							LET l_msgresp = kandoomsg("U",9919,"") 
							#9919 This field must END with "." ":" OR "!"
							NEXT FIELD msg1_text 
						END IF 
						IF l_warning != "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9920,"") 
							#9920 This MESSAGE must begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
					OTHERWISE 
						IF l_last_char != "." 
						AND l_last_char != ":" 
						AND l_last_char != "!" THEN 
							LET l_msgresp = kandoomsg("U",9919,"") 
							#9919 This field must END with "." ":" OR "!"
							NEXT FIELD msg1_text 
						END IF 
						LET l_warning = upshift(l_warning) 
						IF l_warning = "WARNING" THEN 
							LET l_msgresp = kandoomsg("U",9921,"") 
							#9921 This MESSAGE cannot begin with the word "WARNING"
							NEXT FIELD msg1_text 
						END IF 
				END CASE 
			END IF 

		ON KEY (control-w) 
			CALL kandoohelp("") 

	END INPUT 

	CLOSE WINDOW u201 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		RETURN "","","" 
	ELSE 
		LET l_rec_kandoomsg.language_code = modu_rec_language.language_code 
		INSERT INTO kandoomsg VALUES (l_rec_kandoomsg.*) 
		RETURN l_rec_kandoomsg.source_ind, 
		l_rec_kandoomsg.msg_num, 
		l_rec_kandoomsg.msg1_text 
	END IF 
END FUNCTION 



###################################################################
# FUNCTION show_ind(p_mode)
#
#
###################################################################
FUNCTION show_ind(p_mode) 
	DEFINE p_mode CHAR(6) 
	DEFINE l_help_ind CHAR(1) 
	DEFINE l_help_text CHAR(40) 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	OPEN WINDOW u202 with FORM "U202" 
	CALL windecoration_u("U202") 

	CALL set_count(10) 
	IF p_mode = "ACTION" THEN 
		LET l_msgresp = kandoomsg("U",1107,"Action") 
		DISPLAY "Message Action Indicators" TO lbinfo2 

		DISPLAY ARRAY modu_arr_rec_actionhelp TO sr_type.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","U31","display_arr-modu_arr_rec_actionhelp-1") -- albo kd-511 

			ON KEY (RETURN,escape,interrupt) 
				EXIT DISPLAY 
				#				ON KEY (control-w)
				#					CALL kandoohelp("")
		END DISPLAY 

		LET i = arr_curr() 
		LET l_help_ind = modu_arr_rec_actionhelp[i].scroll_num 
		LET l_help_text= modu_arr_rec_actionhelp[i].desc_text 

	ELSE 

		LET l_msgresp = kandoomsg("U",1107,"Format") 
		DISPLAY "Message Format Indicators" TO lbinfo2 

		DISPLAY ARRAY modu_arr_rec_formathelp TO sr_type.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","U31","display_arr-pa_formathelp-1") -- albo kd-511 

			ON KEY (RETURN,escape,interrupt) 
				EXIT DISPLAY 

				#			ON KEY (control-w)
				#				CALL kandoohelp("")

		END DISPLAY 

		LET i = arr_curr() 
		LET l_help_ind = modu_arr_rec_formathelp[i].scroll_num 
		LET l_help_text= modu_arr_rec_formathelp[i].desc_text 
	END IF 

	CLOSE WINDOW u202 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "","" 
	END IF 
	RETURN l_help_ind, 
	l_help_text 
END FUNCTION 


###################################################################
# FUNCTION init_help()
#
#
###################################################################
FUNCTION init_help() 
	DEFINE i SMALLINT 

	FOR i = 1 TO 9 
		LET modu_arr_rec_formathelp[i].scroll_num = i 
		LET modu_arr_rec_actionhelp[i].scroll_num = i 
	END FOR 

	LET modu_arr_rec_actionhelp[1].desc_text = "DISPLAY on form lines 1 & 2. :No window" 
	LET modu_arr_rec_actionhelp[2].desc_text = "DISPLAY & sleep 3 seconds. :No window" 
	LET modu_arr_rec_actionhelp[3].desc_text = "DISPLAY & 'Any Key TO Cont..' :No window" 
	LET modu_arr_rec_actionhelp[4].desc_text = "DISPLAY & prompt 'Supply|Choices' window" 
	LET modu_arr_rec_actionhelp[5].desc_text = "DISPLAY & sleep 10 seconds. :With window" 
	LET modu_arr_rec_actionhelp[6].desc_text = "WARNING: Requiring user acknowledgement " 
	LET modu_arr_rec_actionhelp[7].desc_text = "DISPLAY & 'Any Key TO Cont.':With window" 
	LET modu_arr_rec_actionhelp[8].desc_text = "DISPLAY & prompt (Y)es/(N)o.:With window" 
	LET modu_arr_rec_actionhelp[9].desc_text = "DISPLAY on error line with warning bell." 
	LET modu_arr_rec_formathelp[1].desc_text = "DISPLAY <VALUE> AT start of first line. " 
	LET modu_arr_rec_formathelp[2].desc_text = "DISPLAY <VALUE> AT END of first line. " 
	LET modu_arr_rec_formathelp[3].desc_text = "DISPLAY <VALUE> AT start of second line." 
	LET modu_arr_rec_formathelp[4].desc_text = "DISPLAY <VALUE> AT END of second line." 
	LET modu_arr_rec_formathelp[5].desc_text = "No Format allocated" 
	LET modu_arr_rec_formathelp[6].desc_text = "No Format allocated" 
	LET modu_arr_rec_formathelp[7].desc_text = "No Format allocated" 
	LET modu_arr_rec_formathelp[8].desc_text = "No Format allocated" 
	LET modu_arr_rec_formathelp[9].desc_text = "DISPLAY <VALUE> best fit. (append lines)" 
END FUNCTION 


