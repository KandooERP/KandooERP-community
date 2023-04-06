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

	Source code beautified by beautify.pl on 2020-01-03 18:54:41	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module U17 - Memo Facility
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 


#######################################################################
# MAIN
#
#
#######################################################################
MAIN 

	CALL setModuleId("U17") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	CALL create_table("kandoomemoline","f_kandoomemoline","","N") 

	OPEN WINDOW u534 with FORM "U534" 
	CALL windecoration_u("U534") 

	CALL scan_memo() 
	CLOSE WINDOW u534 
END MAIN 



#######################################################################
# FUNCTION scan_memo()
#
#
#######################################################################
FUNCTION scan_memo() 
	DEFINE l_rec_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_arr_rec_kandoomemo DYNAMIC ARRAY OF t_rec_kandoomemo_fc_st_sd_rf_with_scrollflag 
	#	DEFINE l_arr_rec_kandooMemo array[200] OF
	#		RECORD
	#         scroll_flag CHAR(1),
	#         from_code LIKE kandoomemo.from_code,
	#         subject_text LIKE kandoomemo.subject_text,
	#         sent_datetime LIKE kandoomemo.sent_datetime,
	#         read_flag LIKE kandoomemo.read_flag
	#		END RECORD
	DEFINE l_arr_memonum array[200] OF INTEGER 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_del_cnt SMALLINT 
	DEFINE idx SMALLINT 
	#	DEFINE scrn SMALLINT

	DEFINE l_msgresp LIKE language.yes_flag 

	DECLARE c_kandoomemo CURSOR FOR 
	SELECT * FROM kandoomemo 
	WHERE to_code = glob_rec_kandoouser.sign_on_code 
	ORDER BY read_flag, priority_ind, sent_datetime desc 
	LET idx = 0 

	FOREACH c_kandoomemo INTO l_rec_kandoomemo.* 
		LET idx = idx + 1 
		LET l_arr_memonum[idx] = l_rec_kandoomemo.memo_num 
		LET l_arr_rec_kandoomemo[idx].from_code = l_rec_kandoomemo.from_code 
		LET l_arr_rec_kandoomemo[idx].subject_text = l_rec_kandoomemo.subject_text 
		LET l_arr_rec_kandoomemo[idx].sent_datetime = l_rec_kandoomemo.sent_datetime 
		LET l_arr_rec_kandoomemo[idx].read_flag = l_rec_kandoomemo.read_flag 
		#      IF idx = 200 THEN
		#         LET l_msgresp = kandoomsg("U",6100,idx)
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_kandooMemo.getLength()) 

	#9113 idx records selected
	#   CALL set_count(idx)
	LET l_msgresp = kandoomsg("U",1062,"") 
	#1062 TAB TO View Memo; F12 TO Reply TO Sender.
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	#INPUT ARRAY l_arr_rec_kandooMemo WITHOUT DEFAULTS FROM sr_kandoomemo.* ATTRIBUTE(unbuffered,append row = false, auto append = false, delete row = false)
	DISPLAY ARRAY l_arr_rec_kandoomemo TO sr_kandoomemo.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","U17","input-arr-kandoomemo") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE ROW 
			LET idx = arr_curr() 
			IF idx > 0 THEN 
				LET l_scroll_flag = l_arr_rec_kandoomemo[idx].scroll_flag 
			END IF 
			#         LET scrn = scr_line()

			#      BEFORE FIELD scroll_flag
			#         LET l_scroll_flag = l_arr_rec_kandooMemo[idx].scroll_flag
			#         DISPLAY l_arr_rec_kandooMemo[idx].* TO sr_kandoomemo[scrn].*

			#      AFTER FIELD scroll_flag
			#         LET l_arr_rec_kandooMemo[idx].scroll_flag = l_scroll_flag
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#             LET l_msgresp = kandoomsg("U",9001,"")
			#             #9001 There no more rows...
			#             NEXT FIELD scroll_flag
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_kandooMemo[idx+1].from_code IS NULL THEN
			#              LET l_msgresp = kandoomsg("U",9001,"")
			#              #9001 There no more rows...
			#              NEXT FIELD scroll_flag
			#            END IF
			#         END IF
			#         IF fgl_lastkey() = fgl_keyval("nextpage")
			#         AND l_arr_rec_kandooMemo[idx+9].from_code IS NULL THEN
			#            LET l_msgresp = kandoomsg("U",9001,"")
			#            #9001 No more rows in this direction
			#            NEXT FIELD scroll_flag
			#         END IF

		ON ACTION "VIEW" 
			#      BEFORE FIELD from_code
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			IF idx > 0 THEN 
				IF l_arr_rec_kandoomemo[idx].from_code IS NOT NULL THEN 
					IF view_memo(l_arr_memonum[idx]) THEN 
						LET l_arr_rec_kandoomemo[idx].read_flag = "Y" 
					END IF 
				END IF 
			END IF 
			#         OPTIONS INSERT KEY F36,
			#                 DELETE KEY F36
			#         NEXT FIELD scroll_flag

		ON ACTION "NEW" 
			#      ON KEY(F1)
			CALL new_memo() 
			#         OPTIONS INSERT KEY F36,
			#                 DELETE KEY F36

		ON ACTION "DELETE" #set del marker 
			#      ON KEY(F2) #del marker
			IF l_arr_rec_kandoomemo[idx].from_code IS NOT NULL THEN 
				IF l_arr_rec_kandoomemo[idx].scroll_flag IS NULL THEN 
					IF l_arr_rec_kandoomemo[idx].read_flag = "N" THEN 
						LET l_msgresp = kandoomsg("U",9942,"") 
						#9942 Memo has NOT been read
						#NEXT FIELD scroll_flag
					END IF 
					LET l_arr_rec_kandoomemo[idx].scroll_flag = "*" 
					LET l_scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_kandoomemo[idx].scroll_flag = NULL 
					LET l_scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			#NEXT FIELD scroll_flag

		ON ACTION "REPLY" --reply TO memo sender 
			#ON KEY(F12)
			IF idx > 0 THEN 
				IF l_arr_rec_kandoomemo[idx].from_code IS NOT NULL THEN 
					CALL reply_memo(l_arr_memonum[idx]) 
					OPTIONS INSERT KEY f36, 
					DELETE KEY f36 
				END IF 
			END IF 

			#      AFTER ROW
			#         DISPLAY l_arr_rec_kandooMemo[idx].* TO sr_kandoomemo[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	IF l_del_cnt > 0 THEN 
		IF kandoomsg("U",8036,l_del_cnt) = "Y" THEN 
			#8036 Confirm TO Delete ",l_del_cnt," memo(s)? (Y/N)"
			GOTO bypass 
			LABEL recovery: 
			IF error_recover(l_err_message, status) = "N" THEN 
				RETURN 
			END IF 
			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_kandoomemo[idx].scroll_flag = "*" THEN 
						LET l_err_message = "U17 - DELETE FROM kandoomemo" 
						DELETE FROM kandoomemo 
						WHERE memo_num = l_arr_memonum[idx] 
						LET l_err_message = "U17 - DELETE FROM kandoomemoline" 
						DELETE FROM kandoomemoline 
						WHERE memo_num = l_arr_memonum[idx] 
					END IF 
				END FOR 
			COMMIT WORK 
			WHENEVER ERROR stop 
		END IF 
	END IF 
END FUNCTION 



#######################################################################
# FUNCTION view_memo(p_memo_num)
#
#
#######################################################################
FUNCTION view_memo(p_memo_num) 
	DEFINE p_memo_num LIKE kandoomemo.memo_num 
	DEFINE l_rec_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_rec_kandoomemoline RECORD LIKE kandoomemoline.* 
	DEFINE l_arr_rec_kandoomemoline DYNAMIC ARRAY OF #array[200] OF 
	RECORD 
		memo_text LIKE kandoomemoline.memo_text 
	END RECORD 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_err_message CHAR(60) 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW u537 with FORM "U537" 
	CALL windecoration_u("U537") 

	SELECT * INTO l_rec_kandoomemo.* FROM kandoomemo 
	WHERE memo_num = p_memo_num 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Memo") 
		#7001 Logic Error: Memo RECORD Does Not Exist
		RETURN 
	END IF 
	SELECT * INTO l_rec_kandoouser.* FROM kandoouser 
	WHERE sign_on_code = l_rec_kandoomemo.from_code 
	DISPLAY BY NAME l_rec_kandoomemo.from_code, 
	l_rec_kandoomemo.subject_text, 
	l_rec_kandoomemo.sent_datetime, 
	l_rec_kandoouser.name_text 

	DECLARE c_kandoomemoline CURSOR FOR 
	SELECT * FROM kandoomemoline 
	WHERE memo_num = p_memo_num 
	ORDER BY line_num 

	LET idx = 0 
	FOREACH c_kandoomemoline INTO l_rec_kandoomemoline.* 
		LET idx = idx + 1 
		LET l_arr_rec_kandoomemoline[idx].memo_text = l_rec_kandoomemoline.memo_text 
		IF idx = 200 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx rows selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE l_arr_rec_kandoomemoline[idx].* TO NULL 
	END IF 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN false 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET l_err_message = "Update memo STATUS TO READ" 

		#DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with CURRENT"
		#DISPLAY "see utility/U17.4gl"
		#EXIT PROGRAM (1)

		UPDATE kandoomemo 
		SET read_flag = "Y" 
		--DISABLED	  , read_datetime = CURRENT
		WHERE memo_num = p_memo_num 

	COMMIT WORK 
	WHENEVER ERROR stop 
	LET l_msgresp = kandoomsg("U",1063,"") 

	#1063 F12 TO Reply TO Sender; OK TO Continue.
	CALL set_count(idx) 

	DISPLAY ARRAY l_arr_rec_kandoomemoline TO sr_kandoomemoline.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","U17","display-arr-kandoomemoline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-w) 
			CALL kandoohelp("") 

		ON KEY (F12) 
			CALL reply_memo(p_memo_num) 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW u537 
	RETURN true 
END FUNCTION 



#######################################################################
# FUNCTION new_memo()
#
#
#######################################################################
FUNCTION new_memo() 
	DEFINE l_rec_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_user_code CHAR(2500) 
	DEFINE l_winds_text CHAR(2500) 
	DEFINE l_send_user CHAR(2500) 

	DEFINE l_user_code2 CHAR(8) 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_num_user SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DELETE FROM f_kandoomemoline 
	WHERE 1=1 
	INITIALIZE l_rec_kandoomemo.* TO NULL 

	OPEN WINDOW u535 with FORM "U535" 
	CALL winDecoration_U("U535") 

	LET l_rec_kandoomemo.priority_ind = "1" 
	WHILE true 
		LET l_msgresp = kandoomsg("U",1020,"Memo") 
		#1020 Enter Memo Details; OK TO Continue.

		INPUT 
		l_user_code, 
		l_rec_kandoomemo.subject_text, 
		l_rec_kandoomemo.priority_ind WITHOUT DEFAULTS 
		FROM 
		user_code, 
		subject_text, 
		priority_ind 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","U17","input-kandoomemo") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			ON ACTION "LOOKUP" infield(user_code) 
				LET l_winds_text = show_user() 
				IF l_winds_text IS NOT NULL THEN 
					LET l_user_code = l_winds_text 
					LET l_send_user = l_user_code 
					LET l_num_user = 0 
					LET l_user_code2 = NULL 
					LET j = 0 
					FOR i = 1 TO 2498 
						LET j = j + 1 
						LET l_user_code2[j] = l_user_code[i] 
						IF l_user_code[i+1] = " " THEN 
							SELECT unique 1 FROM kandoouser 
							WHERE sign_on_code = l_user_code2 
							AND passwd_ind != "0" 
							IF status = notfound THEN 
								LET l_msgresp = kandoomsg("U",9105,"") 
								#9105 RECORD NOT found; Try Window
								NEXT FIELD user_code 
							END IF 
							LET l_num_user = l_num_user + 1 
							LET j = 0 
							IF l_user_code[i+2] = " " THEN 
								EXIT FOR 
							END IF 
							LET l_user_code2 = NULL 
							LET i = i + 1 
						END IF 
					END FOR 
					IF l_num_user = 1 THEN 
						SELECT * INTO l_rec_kandoouser.* FROM kandoouser 
						WHERE sign_on_code = l_user_code 
						DISPLAY BY NAME l_rec_kandoouser.name_text 

					ELSE 
						LET l_rec_kandoouser.name_text = l_user_code 
						LET l_user_code = "Multiple" 
						DISPLAY l_user_code TO user_code 
						DISPLAY l_rec_kandoouser.name_text TO name_text 

					END IF 
				END IF 


				#                  NEXT FIELD user_code

				#         ON KEY (control-w)
				#            CALL kandoohelp("")

			AFTER FIELD user_code 
				IF l_user_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD user_code 
				END IF 
				--------------------------
				 {                  IF l_winds_text IS NOT NULL THEN
				                     LET l_user_code = l_winds_text
				                     LET l_send_user = l_user_code
				                     LET l_num_user = 0
				                     LET l_user_code2 = NULL
				                     LET j = 0
				                     FOR i = 1 TO 2498
				                        LET j = j + 1
				                        LET l_user_code2[j] = l_user_code[i]
				                        IF l_user_code[i+1] = " " THEN
				                           SELECT unique 1 FROM kandoouser
				                            WHERE sign_on_code = l_user_code2
				                              AND passwd_ind != "0"
				                           IF STATUS = NOTFOUND THEN
				                              LET l_msgresp = kandoomsg("U",9105,"")
				#9105 RECORD NOT found; Try Window
				                              NEXT FIELD user_code
				                           END IF
				                           LET l_num_user = l_num_user + 1
				                           LET j = 0
				                           IF l_user_code[i+2] = " " THEN
				                              EXIT FOR
				                           END IF
				                           LET l_user_code2 = NULL
				                           LET i = i + 1
				                        END IF
				                     END FOR
				                     IF l_num_user = 1 THEN
				                        SELECT * INTO l_rec_kandoouser.* FROM kandoouser
				                         WHERE sign_on_code = l_user_code
				                        DISPLAY BY NAME l_rec_kandoouser.name_text

				                     ELSE
				                        LET l_rec_kandoouser.name_text = l_user_code
				                        LET l_user_code = "Multiple"
				                        DISPLAY l_user_code TO user_code
				                        DISPLAY l_rec_kandoouser.name_text TO name_text

				                     END IF
				                  END IF
				 }
				--------------------------

				IF l_user_code = "Multiple" THEN 
					LET l_user_code = l_send_user 
				END IF 
				LET l_num_user = 0 
				LET l_user_code2 = NULL 
				LET j = 0 

				FOR i = 1 TO 2498 
					LET j = j + 1 
					LET l_user_code2[j] = l_user_code[i] 
					IF l_user_code[i+1] = " " THEN 
						SELECT unique 1 FROM kandoouser 
						WHERE sign_on_code = l_user_code2 
						AND passwd_ind != "0" 
						IF status = notfound THEN 
							LET l_msgresp = kandoomsg("U",9105,"") 
							#9105 RECORD NOT found; Try Window
							NEXT FIELD user_code 
						END IF 
						LET l_num_user = l_num_user + 1 
						LET i = i + 1 
						LET j = 0 
						IF l_user_code[i+2] = " " THEN 
							EXIT FOR 
						END IF 
						LET l_user_code2 = NULL 
					END IF 
				END FOR 

				LET l_send_user = l_user_code 
				IF l_num_user = 1 THEN 
					SELECT * INTO l_rec_kandoouser.* FROM kandoouser 
					WHERE sign_on_code = l_user_code 
					DISPLAY BY NAME l_rec_kandoouser.name_text 

				ELSE 
					LET l_rec_kandoouser.name_text = l_user_code 
					LET l_user_code = "Multiple" 
					DISPLAY BY NAME l_user_code, 
					l_rec_kandoouser.name_text 

				END IF 

			AFTER FIELD subject_text 
				IF l_rec_kandoomemo.subject_text IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD subject_text 
				END IF 

			AFTER FIELD priority_ind 
				IF l_rec_kandoomemo.priority_ind = "0" THEN 
					CALL get_kandoo_user() 
					RETURNING l_rec_kandoouser.* 
					IF l_rec_kandoouser.memo_pri_ind = "1" THEN 
						LET l_msgresp = kandoomsg("U",9943,"") 
						#9943 User NOT authorized TO send type 0 memos
						NEXT FIELD priority_ind 
					END IF 
				END IF 

			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF l_rec_kandoomemo.subject_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD subject_text 
					END IF 
				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW u535 
			RETURN 
		END IF 

		IF enter_memolines(0) THEN 
			CALL save_memo(l_send_user, l_rec_kandoomemo.*) 
		ELSE 
			CONTINUE WHILE 
		END IF 

		EXIT WHILE 

	END WHILE 

	CLOSE WINDOW u535 
END FUNCTION 



#######################################################################
# FUNCTION enter_memolines(p_memo_num)
#
#
#######################################################################
FUNCTION enter_memolines(p_memo_num) 
	DEFINE p_memo_num LIKE kandoomemo.memo_num 
	DEFINE l_rec_kandoomemoline RECORD LIKE kandoomemoline.* 
	DEFINE l_arr_rec_kandoomemoline array[200] OF 
	RECORD 
		memo_text LIKE kandoomemoline.memo_text 
	END RECORD 
	DEFINE l_query_text STRING 
	DEFINE idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_memo_num = 0 THEN 
		LET l_query_text = "SELECT * FROM f_kandoomemoline ", 
		" ORDER BY line_num " 
		PREPARE s_kandoomemoline FROM l_query_text 
		DECLARE c2_kandoomemoline CURSOR FOR s_kandoomemoline 
		LET idx = 0 
		FOREACH c2_kandoomemoline INTO l_rec_kandoomemoline.* 
			LET idx = idx + 1 
			LET l_arr_rec_kandoomemoline[idx].memo_text = l_rec_kandoomemoline.memo_text 
			IF idx = 200 THEN 
				LET l_msgresp = kandoomsg("U",6100,idx) 
				#6100 First idx rows selected
				EXIT FOREACH 
			END IF 
		END FOREACH 
	END IF 

	DELETE FROM f_kandoomemoline 
	WHERE 1=1 

	IF p_memo_num = 0 THEN 
		LET l_msgresp = kandoomsg("U",1065,"") 
		#1065 Enter Memo Text; F1/F2/TAB New Line
	ELSE 
		LET l_msgresp = kandoomsg("U",1066,"") 
		#1066 Enter Reply Text; F1/F2/TAB New Line
	END IF 

	CALL set_count(idx) 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 

	INPUT ARRAY l_arr_rec_kandoomemoline WITHOUT DEFAULTS FROM sr_kandoomemoline.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U17","input-arr-kandoomemoline") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-w) 
			CALL kandoohelp("") 

		AFTER INPUT 
			IF (int_flag OR quit_flag) THEN 
				LET int_flag = false 
				LET quit_flag = false 
				IF p_memo_num != 0 THEN 
					IF kandoomsg("U",8037,"") = "N" THEN 
						#8037 Confirm TO discard reply?
						CONTINUE INPUT 
					ELSE 
						LET int_flag = true 
						EXIT INPUT 
					END IF 
				ELSE 
					FOR idx = 1 TO arr_count() 
						LET l_rec_kandoomemoline.memo_num = 0 
						LET l_rec_kandoomemoline.line_num = idx 
						LET l_rec_kandoomemoline.memo_text = l_arr_rec_kandoomemoline[idx].memo_text 
						INSERT INTO f_kandoomemoline VALUES (l_rec_kandooMemoline.*) 
					END FOR 
					LET int_flag = true 
					EXIT INPUT 
				END IF 
			ELSE 
				IF kandoomsg("U",8035,"") = "N" THEN 
					#8035 Confirm TO send memo?
					IF p_memo_num != 0 THEN 
						CONTINUE INPUT 
					ELSE 
						FOR idx = 1 TO arr_count() 
							LET l_rec_kandoomemoline.memo_num = 0 
							LET l_rec_kandoomemoline.line_num = idx 
							LET l_rec_kandoomemoline.memo_text = l_arr_rec_kandoomemoline[idx].memo_text 
							INSERT INTO f_kandoomemoline VALUES (l_rec_kandooMemoline.*) 
						END FOR 
						LET int_flag = true 
						EXIT INPUT 
					END IF 
				ELSE 
					FOR idx = 1 TO arr_count() 
						LET l_rec_kandoomemoline.memo_num = 0 
						LET l_rec_kandoomemoline.line_num = idx 
						LET l_rec_kandoomemoline.memo_text = l_arr_rec_kandoomemoline[idx].memo_text 
						INSERT INTO f_kandoomemoline VALUES (l_rec_kandooMemoline.*) 
					END FOR 
				END IF 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 
	RETURN true 
END FUNCTION 



#######################################################################
# FUNCTION save_memo(p_send_user, l_rec_kandooMemo)
#
#
#######################################################################
FUNCTION save_memo(p_send_user, l_rec_kandoomemo) 
	DEFINE p_send_user CHAR(2500) 
	DEFINE l_rec_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_rec_kandoomemoline RECORD LIKE kandoomemoline.* 
	DEFINE l_memo_num LIKE kandoomemo.memo_num 
	DEFINE l_user_code2 CHAR(8) 
	DEFINE l_err_message CHAR(60) 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message, status) = "N" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		LET l_user_code2 = NULL 
		LET j = 0 

		FOR i = 1 TO 2498 
			LET j = j + 1 
			LET l_user_code2[j] = p_send_user[i] 
			IF p_send_user[i+1] = " " THEN 
				SELECT unique 1 FROM kandoouser 
				WHERE sign_on_code = l_user_code2 
				AND passwd_ind != "0" 
				IF status = notfound THEN 
					LET l_msgresp = kandoomsg("U",7001,"User") 
					#7001 Logic Error: User RECORD NOT found
					ROLLBACK WORK 
					WHENEVER ERROR stop 
					RETURN 
				END IF 
				LET j = 0 
				LET l_rec_kandoomemo.memo_num = 0 
				LET l_rec_kandoomemo.to_code = l_user_code2 
				LET l_rec_kandoomemo.from_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_kandoomemo.sent_datetime = CURRENT 
				LET l_rec_kandoomemo.read_flag = "N" 
				LET l_err_message = "U17 - Insert Into kandoomemo" 
				INSERT INTO kandoomemo VALUES (l_rec_kandooMemo.*) 
				LET l_memo_num = sqlca.sqlerrd[2] 
				DECLARE c3_kandoomemoline CURSOR with HOLD FOR 
				SELECT * FROM f_kandoomemoline 
				ORDER BY line_num 
				FOREACH c3_kandoomemoline INTO l_rec_kandoomemoline.* 
					LET l_rec_kandoomemoline.memo_num = l_memo_num 
					LET l_err_message = "U17 - Insert Into kandoomemoline" 
					INSERT INTO kandoomemoline VALUES (l_rec_kandooMemoline.*) 
				END FOREACH 
				IF p_send_user[i+2] = " " THEN 
					EXIT FOR 
				END IF 
				LET i = i + 1 
				LET l_user_code2 = NULL 
			END IF 

		END FOR 

	COMMIT WORK 
	WHENEVER ERROR stop 
END FUNCTION 



#######################################################################
# FUNCTION reply_memo(p_memo_num)
#
#
#######################################################################
FUNCTION reply_memo(p_memo_num) 
	DEFINE p_memo_num LIKE kandoomemo.memo_num 
	DEFINE l_rec_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_rec_s_kandoomemo RECORD LIKE kandoomemo.* 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_user_code LIKE kandoouser.sign_on_code 
	DEFINE l_length SMALLINT 
	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DELETE FROM f_kandoomemoline 
	WHERE 1=1 
	OPEN WINDOW u538 at 3,4 with FORM "U538" 
	CALL windecoration_u("U538") 

	INITIALIZE l_rec_kandoomemo.* TO NULL 
	INITIALIZE l_rec_s_kandoomemo.* TO NULL 
	SELECT * INTO l_rec_s_kandoomemo.* FROM kandoomemo 
	WHERE memo_num = p_memo_num 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Memo") 
		#7001 Memo RECORD NOT found
		RETURN 
	END IF 
	LET l_length = length(l_rec_s_kandoomemo.subject_text) 

	IF l_length > 0 THEN 
		LET j = 4 
		LET l_rec_kandoomemo.subject_text = "RE: " 
		FOR i = 1 TO l_length 
			LET j = j + 1 
			LET l_rec_kandoomemo.subject_text[j] = l_rec_s_kandoomemo.subject_text[i] 
			IF j = 40 THEN 
				EXIT FOR 
			END IF 
		END FOR 
	END IF 

	LET l_user_code = l_rec_s_kandoomemo.from_code 
	LET l_rec_kandoomemo.priority_ind = "1" 
	INITIALIZE l_rec_kandoouser.* TO NULL 

	SELECT * INTO l_rec_kandoouser.* FROM kandoouser 
	WHERE sign_on_code = l_user_code 

	DISPLAY l_user_code TO user_code 
	DISPLAY l_rec_kandoouser.name_text TO name_text 
	DISPLAY l_rec_kandoomemo.subject_text TO subject_text 

	IF enter_memolines(p_memo_num) THEN 
		CALL save_memo(l_user_code, l_rec_kandoomemo.*) 
	END IF 

	CLOSE WINDOW u538 

END FUNCTION 


