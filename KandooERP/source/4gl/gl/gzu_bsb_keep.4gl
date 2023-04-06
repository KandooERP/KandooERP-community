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

	Source code beautified by beautify.pl on 2020-01-03 14:29:06	$Id: $
}



#   GZU - Bank bics

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS 



############################################################
# MAIN
#
#
############################################################
MAIN 

	CALL setModuleId("GZU") 
	CALL ui_init(0) #initial ui init 
	--	CALL publish_toolbar("kandoo","GZU","global")
	--  CALL ui.Interface.setText(getMenuItemLabel("GZU"))


	DEFER interrupt 
	DEFER quit 
	CALL authenticate("GZU") 

	OPEN WINDOW g534 at 2,8 with FORM "G534" 
	CALL winDecoration("G534") 

	WHILE select_bic() 
		CALL scan_bic() 
	END WHILE 
	CLOSE WINDOW g534 
END MAIN 


############################################################
# FUNCTION select_bic()
#
#
############################################################
FUNCTION select_bic() 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON bic_code, 
	desc_text, 
	post_code, 
	bank_ref 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZU","bankDescriptionQuery") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("G",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM bic ", 
		"WHERE ", l_where_text clipped," ", 
		"ORDER BY bic.bic_code" 
		PREPARE s_bic FROM l_query_text 
		DECLARE c_bic CURSOR FOR s_bic 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION scan_bic()
#
#
############################################################
FUNCTION scan_bic() 
	DEFINE l_rec_bic RECORD LIKE bic.* 
	DEFINE l_arr_rec_bic DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		bic_code LIKE bic.bic_code, 
		desc_text LIKE bic.desc_text, 
		post_code LIKE bic.post_code, 
		bank_ref LIKE bic.bank_ref 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_bic INTO l_rec_bic.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_bic[l_idx].bic_code = l_rec_bic.bic_code 
		LET l_arr_rec_bic[l_idx].desc_text = l_rec_bic.desc_text 
		LET l_arr_rec_bic[l_idx].post_code = l_rec_bic.post_code 
		LET l_arr_rec_bic[l_idx].bank_ref = l_rec_bic.bank_ref 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("G",9166,l_idx) 
			#9166 " First ??? Bank/State/Branchs Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("G",9167,"") 
		#9167" No Bank/State/Branchs satisfied selection criteria "
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_bic WITHOUT DEFAULTS FROM sr_bic.* ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZU","bankDescriptionList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_bic.* TO NULL 
			INITIALIZE l_arr_rec_bic[l_idx].* TO NULL 
			NEXT FIELD bic_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_bic[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_bic[l_idx].* TO sr_bic[scrn].*

			LET l_rec_bic.bic_code = l_arr_rec_bic[l_idx].bic_code 
			LET l_rec_bic.desc_text = l_arr_rec_bic[l_idx].desc_text 
			LET l_rec_bic.post_code = l_arr_rec_bic[l_idx].post_code 
			LET l_rec_bic.bank_ref = l_arr_rec_bic[l_idx].bank_ref 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_bic[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_bic[l_idx].scroll_flag
			#     TO sr_bic[scrn].scroll_flag

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_bic[l_idx+1].bic_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			#BEFORE FIELD bic_code
			#   DISPLAY l_arr_rec_bic[l_idx].* TO sr_bic[scrn].*

		AFTER FIELD bic_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_bic[l_idx].bic_code IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9178,"") 
						#9178 Bank/State/Branchs must NOT be NULL
						NEXT FIELD bic_code 
					ELSE 
						IF l_rec_bic.bic_code IS NULL THEN 
							SELECT unique 1 FROM bic 
							WHERE bic_code = l_arr_rec_bic[l_idx].bic_code 
							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("G",9176,"") 
								# 9176 Bank/State/Branchs already exists, UPDATE no add
								NEXT FIELD bic_code 
							END IF 
							FOR i = 1 TO 100 
								IF i != l_idx THEN 
									IF l_arr_rec_bic[l_idx].bic_code = l_arr_rec_bic[i].bic_code THEN 
										LET l_msgresp = kandoomsg("G",9176,"") 
										# 9176 Bank/State/Branchs already exists
										NEXT FIELD bic_code 
										EXIT FOR 
									END IF 
								END IF 
							END FOR 
						ELSE 
							LET l_arr_rec_bic[l_idx].bic_code = l_rec_bic.bic_code 
							#DISPLAY l_arr_rec_bic[l_idx].bic_code TO sr_bic[scrn].bic_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_bic[l_idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("G",9177,"") 
								#9177 Bank/State/Branchs Description must NOT be NULL
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD bic_code 
			END CASE 

		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_bic[l_idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9177,"") 
						#9177 Bank/State/Branchs Description must NOT be NULL
						NEXT FIELD desc_text 
					ELSE 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							NEXT FIELD scroll_flag 
						ELSE 
							NEXT FIELD NEXT 
						END IF 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD bic_code 
			END CASE 
		AFTER FIELD post_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					NEXT FIELD NEXT 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD bic_code 
			END CASE 

		AFTER FIELD bank_ref 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD bic_code 
			END CASE 

		ON KEY (F2) 
			IF l_arr_rec_bic[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_bic[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_bic[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
			#AFTER ROW
			#   DISPLAY l_arr_rec_bic[l_idx].* TO sr_bic[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF l_rec_bic.bic_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_bic[l_idx].* = l_arr_rec_bic[l_idx+1].* 
							IF scrn <= 12 THEN 
								DISPLAY l_arr_rec_bic[l_idx].* TO sr_bic[scrn].* 

								LET scrn = scrn + 1 
							END IF 
						END FOR 
						INITIALIZE l_arr_rec_bic[l_idx].* TO NULL 
						DISPLAY l_arr_rec_bic[l_idx].* TO sr_bic[scrn].* 

						NEXT FIELD scroll_flag 
					ELSE 
						LET int_flag = false 
						LET quit_flag = false 
						LET l_arr_rec_bic[l_idx].bic_code = l_rec_bic.bic_code 
						LET l_arr_rec_bic[l_idx].desc_text = l_rec_bic.desc_text 
						LET l_arr_rec_bic[l_idx].post_code = l_rec_bic.post_code 
						LET l_arr_rec_bic[l_idx].bank_ref = l_rec_bic.bank_ref 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
			--      ON KEY (control-w)
			--         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_bic[l_idx].bic_code IS NOT NULL THEN 
				LET l_rec_bic.bic_code = l_arr_rec_bic[l_idx].bic_code 
				LET l_rec_bic.desc_text = l_arr_rec_bic[l_idx].desc_text 
				LET l_rec_bic.post_code = l_arr_rec_bic[l_idx].post_code 
				LET l_rec_bic.bank_ref = l_arr_rec_bic[l_idx].bank_ref 
				UPDATE bic 
				SET * = l_rec_bic.* 
				WHERE bic_code = l_rec_bic.bic_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO bic VALUES (l_rec_bic.*) 
				END IF 
			END IF 
		END FOR 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("G",8020,l_del_cnt) 
			#8020 Confirm TO Delete ",l_del_cnt," Bank/State/Branchs(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_bic[l_idx].scroll_flag = "*" THEN 
						DELETE FROM bic 
						WHERE bic_code = l_arr_rec_bic[l_idx].bic_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


