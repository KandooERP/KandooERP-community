# GroupCode GroupInfo Maintenance

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

#Program GZ7   Group codes

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_filter SMALLINT #query ON / off 
	DEFINE l_query STRING 
	CALL setModuleId("GZ7") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_g_gl() #init g/gl general ledger module #KD-2128

	OPEN WINDOW g169 with FORM "G169" 
	CALL windecoration_g("G169") 


	WHILE NOT (int_flag OR quit_flag) 
		CALL scan_group(l_query) 
	END WHILE 

	#   WHILE select_group(l_filter)
	#      CALL scan_group()
	#   END WHILE



	CLOSE WINDOW g169 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION select_group()
#
#
############################################################
FUNCTION select_group(p_filter) 
	DEFINE p_filter SMALLINT # query with OR WITHOUT CONSTRUCT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(400) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter = filter_query_on THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			group_code, 
			desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GZ7","groupInfoQuery") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET p_filter = filter_query_off 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 
	#      LET l_msgresp = kandoomsg("U",1002,"")
	LET l_query_text = 
		"SELECT * FROM groupinfo ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ", l_where_text clipped," " 

	RETURN l_query_text 
END FUNCTION 
############################################################
# END FUNCTION select_group()
############################################################


############################################################
# FUNCTION db_groupinfo_get_datasource()
#
#
############################################################
FUNCTION db_groupinfo_get_datasource(p_query_text) 
	DEFINE p_query_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_groupinfo RECORD LIKE groupinfo.* 
	DEFINE l_arr_rec_groupinfo DYNAMIC ARRAY OF RECORD #[5000] 
		scroll_flag CHAR(1), 
		group_code LIKE groupinfo.group_code, 
		desc_text LIKE groupinfo.desc_text 
	END RECORD 

	IF p_query_text IS NULL THEN 
		CALL fgl_winmessage("Invalid Query","Invalid Query","error") 
		EXIT PROGRAM 
	END IF 

	PREPARE s_groupinfo FROM p_query_text 
	DECLARE c_groupinfo CURSOR FOR s_groupinfo 

	LET l_idx = 0 
	FOREACH c_groupinfo INTO l_rec_groupinfo.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_groupinfo[l_idx].group_code = l_rec_groupinfo.group_code 
		LET l_arr_rec_groupinfo[l_idx].desc_text = l_rec_groupinfo.desc_text 
		#      IF l_idx = 5000 THEN
		#         LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	RETURN l_arr_rec_groupinfo 
END FUNCTION 
############################################################
# END FUNCTION db_groupinfo_get_datasource()
############################################################


############################################################
# FUNCTION scan_group()
#
#
############################################################
FUNCTION scan_group(p_query_text) 
	DEFINE p_query_text STRING 
	DEFINE l_query STRING 
	DEFINE l_filter SMALLINT 
	DEFINE l_rec_groupinfo RECORD LIKE groupinfo.* 
	DEFINE l_arr_rec_groupinfo DYNAMIC ARRAY OF RECORD #[5000] 
		scroll_flag CHAR(1), 
		group_code LIKE groupinfo.group_code, 
		desc_text LIKE groupinfo.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF db_groupinfo_get_count() > 1000 THEN 
		LET l_filter = filter_query_on 
	ELSE 
		LET l_filter = filter_query_off 
	END IF 

	LET l_query = select_group(l_filter) 
	CALL db_groupinfo_get_datasource(l_query) RETURNING l_arr_rec_groupinfo 


	#	select_group(p_filter)
	#	CALL db_groupinfo_get_datasource() RETURNING 	l_arr_rec_groupinfo


	#   LET l_idx = 0
	#   FOREACH c_groupinfo INTO l_rec_groupinfo.*
	#      LET l_idx = l_idx + 1
	#      LET l_arr_rec_groupinfo[l_idx].group_code = l_rec_groupinfo.group_code
	#      LET l_arr_rec_groupinfo[l_idx].desc_text = l_rec_groupinfo.desc_text
	#      IF l_idx = 5000 THEN
	#         LET l_msgresp = kandoomsg("U",6100,l_idx)
	#         EXIT FOREACH
	#      END IF
	#   END FOREACH
	IF l_arr_rec_groupinfo.getlength() = 0 THEN 
		#IF l_idx = 0 THEN
		LET l_idx = 1 
		INITIALIZE l_arr_rec_groupinfo[l_idx].* TO NULL 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	#CALL set_count(l_idx)
	LET l_msgresp = kandoomsg("U",1003,"") 

	INPUT ARRAY l_arr_rec_groupinfo WITHOUT DEFAULTS FROM sr_groupinfo.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ7","groupInfoList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			LET l_filter = filter_query_on 
			LET l_query = select_group(l_filter) 
			IF l_query IS NULL THEN 
				LET l_filter = filter_query_off 
			ELSE 
				CALL db_groupinfo_get_datasource(l_query) RETURNING l_arr_rec_groupinfo 
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_groupinfo.* TO NULL 
			#INITIALIZE l_arr_rec_groupinfo[l_idx].* TO NULL
			NEXT FIELD group_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_groupinfo[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_groupinfo[l_idx].* TO sr_groupinfo[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_groupinfo[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_groupinfo[l_idx].scroll_flag
			#     TO sr_groupinfo[scrn].scroll_flag

			LET l_rec_groupinfo.group_code = l_arr_rec_groupinfo[l_idx].group_code 
			LET l_rec_groupinfo.desc_text = l_arr_rec_groupinfo[l_idx].desc_text 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_groupinfo[l_idx+1].group_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("I",9001,"") 
					# There are no more rows in the direction you are going.
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD group_code 
			#DISPLAY l_arr_rec_groupinfo[l_idx].* TO sr_groupinfo[scrn].*

			IF l_arr_rec_groupinfo[l_idx].group_code IS NOT NULL THEN 
				IF l_rec_groupinfo.group_code IS NOT NULL THEN 
					NEXT FIELD desc_text 
				END IF 
			END IF 

		AFTER FIELD group_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_groupinfo[l_idx].group_code IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9026,"Group code") 
						NEXT FIELD group_code 
					ELSE 
						IF l_rec_groupinfo.group_code IS NULL THEN 
							SELECT unique 1 FROM groupinfo 
							WHERE group_code = l_arr_rec_groupinfo[l_idx].group_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								NEXT FIELD group_code 
							ELSE 
								FOR i = 1 TO arr_count() 
									IF i <> l_idx THEN 
										IF l_arr_rec_groupinfo[l_idx].group_code = 
										l_arr_rec_groupinfo[i].group_code THEN 
											LET l_msgresp = kandoomsg("U",9104,"") 
											NEXT FIELD group_code 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							LET l_arr_rec_groupinfo[l_idx].group_code = l_rec_groupinfo.group_code 
							#DISPLAY l_arr_rec_groupinfo[l_idx].group_code
							#     TO sr_groupinfo[scrn].group_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_groupinfo[l_idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("A",9101,"") 
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					NEXT FIELD group_code 
			END CASE 

		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_groupinfo[l_idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("A",9101,"") 
						NEXT FIELD desc_text 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD desc_text 
			END CASE 

		ON ACTION "DELETE" #delete marker 
			#ON KEY (F2) #Delete Marker
			#         CASE
			#            WHEN infield(scroll_flag)
			IF l_arr_rec_groupinfo[l_idx].scroll_flag IS NULL 
			AND l_arr_rec_groupinfo[l_idx].group_code IS NOT NULL THEN 
				LET l_arr_rec_groupinfo[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				IF l_arr_rec_groupinfo[l_idx].scroll_flag = "*" THEN 
					LET l_arr_rec_groupinfo[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
			#         END CASE
			#AFTER ROW
			#   DISPLAY l_arr_rec_groupinfo[l_idx].* TO sr_groupinfo[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_groupinfo.group_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_groupinfo[l_idx].* = l_arr_rec_groupinfo[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_groupinfo[l_idx].* TO NULL 
							END IF 
							#IF scrn <= 8 THEN
							#   DISPLAY l_arr_rec_groupinfo[l_idx].* TO sr_groupinfo[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_groupinfo[l_idx].group_code = l_rec_groupinfo.group_code 
						LET l_arr_rec_groupinfo[l_idx].desc_text = l_rec_groupinfo.desc_text 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 
			#ON KEY (control-w)
			#   CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		#EXIT PROGRAM - in_flag is read by outer control while loop
		#LET int_flag = FALSE
		#LET quit_flag = FALSE
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_groupinfo[l_idx].group_code IS NOT NULL THEN 
				LET l_rec_groupinfo.group_code = l_arr_rec_groupinfo[l_idx].group_code 
				LET l_rec_groupinfo.desc_text = l_arr_rec_groupinfo[l_idx].desc_text 
				LET l_rec_groupinfo.cmpy_code = glob_rec_kandoouser.cmpy_code 

				UPDATE groupinfo 
				SET * = l_rec_groupinfo.* 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND group_code = l_rec_groupinfo.group_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO groupinfo VALUES (l_rec_groupinfo.*) 
				END IF 

			END IF 
		END FOR 

		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("U",8020,l_del_cnt) 
			IF l_msgresp = "Y" THEN 

				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_groupinfo[l_idx].scroll_flag = "*" THEN 
						DELETE FROM groupinfo 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND group_code = l_arr_rec_groupinfo[l_idx].group_code 
					END IF 
				END FOR 

			END IF 
		END IF 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION scan_group()
############################################################