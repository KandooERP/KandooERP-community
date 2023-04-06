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

	Source code beautified by beautify.pl on 2020-01-03 09:12:48	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 

#   IZA - Product Adjustment Type Maintenance

GLOBALS 
	#	DEFINE temp_text CHAR(20)
	DEFINE glob_winds_text CHAR(20) 
	DEFINE glob_year_num LIKE batchhead.year_num 
	DEFINE glob_period_num LIKE batchhead.period_num 
END GLOBALS 

####################################################################
# MAIN
#
#
####################################################################
MAIN 
	DEFINE ret SMALLINT 
	#Initial UI Init
	CALL setModuleId("IZA") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,today) 
	RETURNING glob_year_num, glob_period_num 
	OPEN WINDOW i629 with FORM "I629" 
	 CALL windecoration_i("I629") -- albo kd-758 

	WHILE true 
		LET ret = scan_prodadjtype() 
		IF ret = ret_cancel OR int_flag = true THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	#   WHILE select_prodadjtype()
	#      WHILE scan_prodadjtype() <> RET_CANCEL
	#      END WHILE
	#   END WHILE
	CLOSE WINDOW i629 
END MAIN 


####################################################################
# FUNCTION select_prodadjtype(p_return_query_type)
# CONSTRUCT
# RETURN l_query_text OR l_where_text
####################################################################
FUNCTION select_prodadjtype(p_return_query_type) 
	DEFINE p_return_query_type SMALLINT 

	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("I",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON source_code, 
	desc_text, 
	adj_acct_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZA","construct-source_code-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 

		LET l_query_text = "SELECT source_code,desc_text,adj_acct_code FROM prodadjtype ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		#"AND ", l_where_text clipped," ",
		"ORDER BY prodadjtype.adj_type_code" 
	ELSE 
		LET l_msgresp = kandoomsg("I",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT source_code,desc_text,adj_acct_code FROM prodadjtype ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY prodadjtype.adj_type_code" 
	END IF 

	IF p_return_query_type = filter_query_select THEN 
		RETURN l_query_text 
	ELSE 
		RETURN l_where_text 
	END IF 
END FUNCTION 



####################################################################
# FUNCTION scan_prodadjtype()
#
#
####################################################################
FUNCTION scan_prodadjtype() 
	DEFINE l_rec_prodadjtype RECORD LIKE prodadjtype.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_arr_rec_prodadjtype DYNAMIC ARRAY OF t_rec_prodadjtype_ac_dt_ac_with_scrollflag 
	#	array[100] OF
	#		RECORD
	#         scroll_flag CHAR(1),
	#         source_code LIKE prodadjtype.adj_type_code,
	#         desc_text LIKE prodadjtype.desc_text,
	#         adj_acct_code LIKE prodadjtype.adj_acct_code
	#
	#		END RECORD
	DEFINE l_pr_scroll_flag CHAR(1) 
	DEFINE i SMALLINT 
	DEFINE idx SMALLINT 
	#	DEFINE scrn SMALLINT
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msgstr STRING 
	DEFINE l_filter_where STRING 
	DEFINE l_mode SMALLINT 

	IF db_prodadjtype_get_count() > 1000 THEN 
		LET l_filter_where = select_prodadjtype(filter_query_where) 
		IF l_filter_where IS NULL THEN 
			LET l_filter_where = " 1=1 " 
		END IF 
		CALL db_prodadjtype_get_arr_rec_ac_dt_ac_with_scrollflag(filter_query_where,l_filter_where) RETURNING l_arr_rec_prodadjtype 
	ELSE 
		LET l_filter_where = " 1=1 " 
		CALL db_prodadjtype_get_arr_rec_ac_dt_ac_with_scrollflag(filter_query_off,null) RETURNING l_arr_rec_prodadjtype 
	END IF 



	#   LET idx = 0
	#   FOREACH c_prodadjtype INTO l_rec_prodadjtype.*
	#      LET idx = idx + 1
	#      LET l_arr_rec_prodadjtype[idx].source_code = l_rec_prodadjtype.adj_type_code
	#      LET l_arr_rec_prodadjtype[idx].desc_text = l_rec_prodadjtype.desc_text
	#      LET l_arr_rec_prodadjtype[idx].adj_acct_code = l_rec_prodadjtype.adj_acct_code
	#      IF idx = 100 THEN
	#         LET l_msgresp = kandoomsg("I",9021,idx)
	#         #9021 " First ??? entries Selected Only"
	#         EXIT FOREACH
	#      END IF
	#   END FOREACH
	IF l_arr_rec_prodadjtype.getlength() < 1 THEN 
		LET l_msgresp = kandoomsg("I",9069,"") 
		#9069" No entries satisfied selection criteria "
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	#   CALL set_count(idx)
	LET l_msgresp = kandoomsg("I",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_prodadjtype WITHOUT DEFAULTS FROM sr_prodadjtype.* attribute(unbuffered, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZA","input-l_arr_rec_prodadjtype-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER" 
			CALL db_prodadjtype_get_arr_rec_ac_dt_ac_with_scrollflag(filter_query_where,select_prodadjtype(filter_query_where)) RETURNING l_arr_rec_prodadjtype 


		BEFORE ROW 
			DISPLAY "BEFORE ROW" 
			LET l_mode = MODE_UPDATE 
			LET idx = arr_curr() 
			#         LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			DISPLAY "BEFORE INSERT" 
			LET l_mode = MODE_INSERT 
			DISPLAY "idx=", idx 
			LET idx = arr_curr() 
			DISPLAY "idx=", idx 

			INITIALIZE l_rec_prodadjtype.* TO NULL 
			INITIALIZE l_arr_rec_prodadjtype[idx].* TO NULL 
			NEXT FIELD source_code 

		AFTER INSERT 
			DISPLAY "AFTER INSERT" 



		AFTER ROW 
			DISPLAY "AFTER ROW" 
			#DISPLAY "idx=", idx
			# LET idx = arr_curr()
			#DISPLAY "idx=", idx

			IF db_prodadjtype_rec_validation(ui_on,l_mode,l_arr_rec_prodadjtype[idx].*) < 0 THEN 
				NEXT FIELD scroll_flag --continue INSERT 
			END IF 
			LET l_mode = MODE_UPDATE 

		BEFORE FIELD scroll_flag 
			LET l_pr_scroll_flag = l_arr_rec_prodadjtype[idx].scroll_flag 
			#         DISPLAY l_arr_rec_prodadjtype[idx].* TO sr_prodadjtype[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_prodadjtype[idx].scroll_flag = l_pr_scroll_flag 
			#         DISPLAY l_arr_rec_prodadjtype[idx].scroll_flag
			#              TO sr_prodadjtype[scrn].scroll_flag

			LET l_rec_prodadjtype.adj_type_code = l_arr_rec_prodadjtype[idx].source_code 
			LET l_rec_prodadjtype.desc_text = l_arr_rec_prodadjtype[idx].desc_text 
			LET l_rec_prodadjtype.adj_acct_code = l_arr_rec_prodadjtype[idx].adj_acct_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_prodadjtype[idx+1].source_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("I",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			#BEFORE FIELD source_code
			#   DISPLAY l_arr_rec_prodadjtype[idx].* TO sr_prodadjtype[scrn].*

		AFTER FIELD source_code 
			#      	DISPLAY "fgl_lastkey()=", fgl_lastkey()
			#      	DISPLAY "fgl_keyname(fgl_lastkey())=", fgl_keyname(fgl_lastkey())
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_prodadjtype[idx].source_code IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9167,"") 
						#9167 Adjustment Type must be entered
						NEXT FIELD source_code 
					ELSE 
						IF l_rec_prodadjtype.adj_type_code IS NULL THEN 
							SELECT unique 1 FROM prodadjtype 
							WHERE source_code = l_arr_rec_prodadjtype[idx].source_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status != notfound THEN 
								LET l_msgresp = kandoomsg("I",9168,"") 
								# 9168 Adjustment Type already exists
								NEXT FIELD source_code 
							ELSE 
								FOR i = 1 TO arr_count() 
									IF i <> idx THEN 
										IF l_arr_rec_prodadjtype[idx].source_code = 
										l_arr_rec_prodadjtype[i].source_code THEN 
											LET l_msgresp = kandoomsg("I",9168,"") 
											# 9168 Adjustment Type already exists
											NEXT FIELD source_code 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							LET l_arr_rec_prodadjtype[idx].source_code 
							= l_rec_prodadjtype.adj_type_code 
							#                     DISPLAY l_arr_rec_prodadjtype[idx].source_code
							#                          TO sr_prodadjtype[scrn].source_code

						END IF 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_prodadjtype[idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("I",9169,"") 
								#9169 A description must be entered
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					IF fgl_lastkey() = fgl_keyval("left") OR 
					fgl_lastkey() = fgl_keyval("up") THEN 
						IF l_arr_rec_prodadjtype[idx].source_code IS NULL THEN 
							NEXT FIELD scroll_flag 
						END IF 
					END IF 
					NEXT FIELD source_code 
			END CASE 
		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_prodadjtype[idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("I",9169,"") 
						#9169 A description must be entered
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
					NEXT FIELD desc_text 
			END CASE 
		AFTER FIELD adj_acct_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_prodadjtype[idx].adj_acct_code IS NOT NULL THEN 
						CALL verify_acct_code(glob_rec_kandoouser.cmpy_code,l_arr_rec_prodadjtype[idx].adj_acct_code, glob_year_num, glob_period_num) 
						RETURNING l_rec_coa.* 
						IF l_rec_coa.acct_code IS NULL THEN 
							LET l_msgresp = kandoomsg("I",7036,"") 
							#7036 Account Code must be a valid account code
							NEXT FIELD adj_acct_code 
						END IF 
						IF l_arr_rec_prodadjtype[idx].adj_acct_code != l_rec_coa.acct_code THEN 
							LET l_arr_rec_prodadjtype[idx].adj_acct_code = l_rec_coa.acct_code 
							LET l_msgresp = kandoomsg("I",7036,"") 
							#9063 Revenue Account Code must be a valid account code
							NEXT FIELD adj_acct_code 
						END IF 
						IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"") THEN 
							LET l_msgresp = kandoomsg("I",7036,"") 
							#9063 Revenue Account Code must be a valid account code
							NEXT FIELD adj_acct_code 
						END IF 
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
					NEXT FIELD adj_acct_code 
			END CASE 


		ON KEY (control-b) infield (adj_acct_code) 
			LET glob_winds_text = NULL 
			LET glob_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_arr_rec_prodadjtype[idx].adj_acct_code = glob_winds_text 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE acct_code = l_arr_rec_prodadjtype[idx].adj_acct_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				#                  DISPLAY l_arr_rec_prodadjtype[idx].adj_acct_code TO
				#                                  sr_prodadjtype[scrn].adj_acct_code

			END IF 
			NEXT FIELD adj_acct_code 

		ON ACTION "DELETE" 
			CALL db_prodadjtype_delete(ui_on,l_arr_rec_prodadjtype[idx].source_code) 
			CALL db_prodadjtype_get_arr_rec_ac_dt_ac_with_scrollflag(filter_query_where,l_filter_where) RETURNING l_arr_rec_prodadjtype 

			#      ON KEY(F2) #Marker i.e. for delete
			#       CASE
			#        WHEN infield(scroll_flag)
			#         IF l_arr_rec_prodadjtype[idx].scroll_flag IS NULL THEN
			#            LET l_arr_rec_prodadjtype[idx].scroll_flag = "*"
			#            LET l_del_cnt = l_del_cnt + 1
			#         ELSE
			#            LET l_arr_rec_prodadjtype[idx].scroll_flag = NULL
			#            LET l_del_cnt = l_del_cnt - 1
			#         END IF
			#         NEXT FIELD scroll_flag
			#       END CASE
			#      AFTER ROW
			#        DISPLAY l_arr_rec_prodadjtype[idx].* TO sr_prodadjtype[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN #check, IF use started adding a new row, but may have NOT completed it 
					IF l_rec_prodadjtype.adj_type_code IS NULL THEN 
						FOR idx = arr_curr() TO arr_count() 
							LET l_arr_rec_prodadjtype[idx].* = l_arr_rec_prodadjtype[idx+1].* 
							#                     IF scrn <= 10 THEN
							#                        DISPLAY l_arr_rec_prodadjtype[idx].* TO sr_prodadjtype[scrn].*
							#
							#                        LET scrn = scrn + 1
							#                     END IF
						END FOR 
						INITIALIZE l_arr_rec_prodadjtype[idx].* TO NULL 
						#                  LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_prodadjtype[idx].source_code 
						= l_rec_prodadjtype.adj_type_code 
						LET l_arr_rec_prodadjtype[idx].desc_text 
						= l_rec_prodadjtype.desc_text 
						LET l_arr_rec_prodadjtype[idx].adj_acct_code 
						= l_rec_prodadjtype.adj_acct_code 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN ret_cancel 
	ELSE 
		FOR idx = 1 TO arr_count() 
			IF l_arr_rec_prodadjtype[idx].scroll_flag IS NULL THEN #update 

				IF l_arr_rec_prodadjtype[idx].source_code IS NOT NULL THEN 
					LET l_rec_prodadjtype.cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_rec_prodadjtype.adj_type_code = l_arr_rec_prodadjtype[idx].source_code 
					LET l_rec_prodadjtype.desc_text = l_arr_rec_prodadjtype[idx].desc_text 
					LET l_rec_prodadjtype.adj_acct_code = l_arr_rec_prodadjtype[idx].adj_acct_code 
					UPDATE prodadjtype 
					SET * = l_rec_prodadjtype.* 
					WHERE source_code = l_rec_prodadjtype.adj_type_code AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF sqlca.sqlerrd[3] = 0 THEN 
						INSERT INTO prodadjtype VALUES (l_rec_prodadjtype.*) 
					END IF 
				END IF 
			ELSE #delete 
				CASE l_arr_rec_prodadjtype[idx].scroll_flag #could be expanded TO support different operations 
					WHEN "*" 
						#						LET l_msgresp = kandoomsg("I",8014,l_del_cnt)
						#						#8014 Confirm TO Delete ",l_del_cnt," Adjustment Codes(s)? (Y/N)"
						#						IF l_msgresp = "Y" THEN
						#							FOR idx = 1 TO arr_count()
						#								IF l_arr_rec_prodadjtype[idx].scroll_flag = "*" THEN
						CALL db_prodadjtype_delete(ui_on,l_arr_rec_prodadjtype[idx].source_code) 
						#									IF db_prodadjtype_delete(UI_ON,l_arr_rec_prodadjtype[idx].source_code) < 0 THEN
						#										LET l_msgStr = "Could not delete Product Adjustment Type ", trim(), " !"
						#										CALL fgl_winmessage("Error when trying to delete",l_msgStr,"error")
						#									END IF
						#DELETE FROM prodadjtype
						#WHERE source_code = l_arr_rec_prodadjtype[idx].source_code
						#AND cmpy_code = glob_rec_kandoouser.cmpy_code
						#								END IF
						#							END FOR
						#						END IF
				END CASE 
			END IF 
		END FOR 

		#      IF l_del_cnt > 0 THEN
		#         LET l_msgresp = kandoomsg("I",8014,l_del_cnt)
		#         #8014 Confirm TO Delete ",l_del_cnt," Adjustment Codes(s)? (Y/N)"
		#         IF l_msgresp = "Y" THEN
		#            FOR idx = 1 TO arr_count()
		#               IF l_arr_rec_prodadjtype[idx].scroll_flag = "*" THEN
		#                  DELETE FROM prodadjtype
		#                    WHERE source_code = l_arr_rec_prodadjtype[idx].source_code
		#                      AND cmpy_code = glob_rec_kandoouser.cmpy_code
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
	END IF 

END FUNCTION 
