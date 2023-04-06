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

	Source code beautified by beautify.pl on 2020-01-03 14:29:05	$Id: $
}




# GL Translation Maintenance Functions

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GZM_GLOBALS.4gl" 


############################################################
# FUNCTION select_accounts()
#
#
############################################################
FUNCTION select_accounts() 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(400) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	DISPLAY glob_header_text TO header_text 


	LET l_msgresp = kandoomsg("U",1001,"") 
	CONSTRUCT BY NAME l_where_text ON ext_acct_code, 
	int_acct_code 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZJ","acctxLateQuery") 

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
		LET l_msgresp = kandoomsg("U",1002,"") 
		IF glob_account_arg = 'L' THEN 
			LET l_query_text = "SELECT *, rowid FROM acctxlate ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND type_ind = 'L' ", 
			"AND ", l_where_text clipped," " 
		ELSE 
			LET l_query_text = "SELECT *, rowid FROM acctxlate ", 
			"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND type_ind = 'C' ", 
			"AND ", l_where_text clipped," " 
		END IF 
		PREPARE s_accounts FROM l_query_text 
		DECLARE c_accounts CURSOR FOR s_accounts 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# FUNCTION FUNCTION scan_accounts()
#
#
############################################################
FUNCTION scan_accounts() 
	DEFINE l_rec_acctxlate RECORD LIKE acctxlate.* 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_start_num SMALLINT 
	DEFINE l_length_num SMALLINT 

	DEFINE l_arr_rec_acctxlate array[1000] OF 
	RECORD 
		scroll_flag CHAR(1), 
		ext_acct_code CHAR(18), 
		int_acct_code CHAR(18) 
	END RECORD 
	DEFINE l_arr_rec_row array[1000] OF 
	RECORD 
		rowid INTEGER 
	END RECORD 
	DEFINE l_int_acct_code LIKE acctxlate.int_acct_code 
	# DEFINE l_ext_acct_code LIKE acctxlate.ext_acct_code #not used
	DEFINE l_scroll_flag CHAR(1) 
	#DEFINE l_error_MESSAGE CHAR(40) #not used
	DEFINE l_rowid INTEGER 
	DEFINE l_query_text2 CHAR(200) 
	DEFINE l_cnt SMALLINT 
	DEFINE l_curr SMALLINT 
	DEFINE i SMALLINT 
	DEFINE x SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 


	IF glob_account_arg = 'C' THEN 
		SELECT * INTO l_rec_structure.* FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = 'C' 
		LET l_start_num = l_rec_structure.start_num 
		LET l_length_num = (l_start_num + l_rec_structure.length_num) - 1 
	END IF 

	LET l_idx = 0 
	FOREACH c_accounts INTO l_rec_acctxlate.*, l_rowid 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_row[l_idx].rowid = l_rowid 
		LET l_arr_rec_acctxlate[l_idx].ext_acct_code = l_rec_acctxlate.ext_acct_code 
		LET l_arr_rec_acctxlate[l_idx].int_acct_code = l_rec_acctxlate.int_acct_code 
		IF l_idx = 1000 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_acctxlate[l_idx].* TO NULL 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1003,"") 

	INPUT ARRAY l_arr_rec_acctxlate WITHOUT DEFAULTS FROM sr_acctxlate.* attribute(UNBUFFERED, append ROW = false,auto append=false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZJ","acctxLateList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			LET l_cnt = arr_count() 
			LET l_curr = arr_curr() 
			FOR x = arr_count() TO l_idx step -1 
				LET l_arr_rec_row[x+1].rowid = l_arr_rec_row[x].rowid 
			END FOR 
			INITIALIZE l_rec_acctxlate.* TO NULL 
			INITIALIZE l_arr_rec_acctxlate[l_idx].* TO NULL 
			INITIALIZE l_arr_rec_row[l_idx].* TO NULL 
			NEXT FIELD ext_acct_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_acctxlate[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_acctxlate[l_idx].* TO sr_acctxlate[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_acctxlate[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_acctxlate[l_idx].scroll_flag
			#     TO sr_acctxlate[scrn].scroll_flag

			LET l_rec_acctxlate.ext_acct_code = l_arr_rec_acctxlate[l_idx].ext_acct_code 
			LET l_rec_acctxlate.int_acct_code = l_arr_rec_acctxlate[l_idx].int_acct_code 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_acctxlate[l_idx+1].ext_acct_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD ext_acct_code 
			#DISPLAY l_arr_rec_acctxlate[l_idx].* TO sr_acctxlate[scrn].*

			IF l_arr_rec_acctxlate[l_idx].ext_acct_code IS NOT NULL THEN 
				IF l_rec_acctxlate.ext_acct_code IS NOT NULL THEN 
					NEXT FIELD int_acct_code 
				END IF 
			END IF 

		AFTER FIELD ext_acct_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_acctxlate[l_idx].ext_acct_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						NEXT FIELD ext_acct_code 
					ELSE 
						SELECT unique 1 FROM acctxlate 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND type_ind = glob_account_arg 
						AND ext_acct_code = l_arr_rec_acctxlate[l_idx].ext_acct_code 
						IF status != NOTFOUND THEN 
							LET l_msgresp = kandoomsg("U",9104,"") 
							NEXT FIELD ext_acct_code 
						END IF 
						FOR x = 1 TO arr_count() 
							IF x != l_idx THEN 
								IF l_arr_rec_acctxlate[x].ext_acct_code = 
								l_arr_rec_acctxlate[l_idx].ext_acct_code THEN 
									LET l_msgresp = kandoomsg("U",9104,"") 
									NEXT FIELD ext_acct_code 
								END IF 
							END IF 
						END FOR 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_acctxlate[l_idx].int_acct_code IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								NEXT FIELD int_acct_code 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
				OTHERWISE 
					NEXT FIELD ext_acct_code 
			END CASE 


		AFTER FIELD int_acct_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_acctxlate[l_idx].int_acct_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						NEXT FIELD int_acct_code 
					ELSE 
						LET l_int_acct_code = l_arr_rec_acctxlate[l_idx].int_acct_code 
						IF glob_account_arg = "L" THEN 
						END IF 
						IF glob_account_arg = 'C' THEN 
							LET l_query_text2 = 
							"SELECT unique 1 FROM coa ", 
							" WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
							" AND acct_code[",l_start_num,",", 
							l_length_num,"] = ","'",l_arr_rec_acctxlate[l_idx].int_acct_code, 
							"'" 
							PREPARE s_coa FROM l_query_text2 
							DECLARE c_coa CURSOR FOR s_coa 
							OPEN c_coa 
							FETCH c_coa 
							IF status = NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9910,"") 
								NEXT FIELD int_acct_code 
							END IF 
						END IF 
					END IF 
					LET l_arr_rec_acctxlate[l_idx].int_acct_code = l_int_acct_code 
					NEXT FIELD scroll_flag 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				OTHERWISE 
					NEXT FIELD scroll_flag 
			END CASE 

		ON KEY (F2) infield (scroll_flag) 
			IF l_arr_rec_acctxlate[l_idx].scroll_flag IS NULL 
			AND l_arr_rec_acctxlate[l_idx].ext_acct_code IS NOT NULL THEN 
				LET l_arr_rec_acctxlate[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				IF l_arr_rec_acctxlate[l_idx].scroll_flag = "*" THEN 
					LET l_arr_rec_acctxlate[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_rec_acctxlate[l_idx].* TO sr_acctxlate[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_acctxlate.ext_acct_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_row[l_idx].* = l_arr_rec_row[l_idx+1].* 
							LET l_arr_rec_acctxlate[l_idx].* = l_arr_rec_acctxlate[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_acctxlate[l_idx].* TO NULL 
							END IF 
							#IF scrn <= 12 THEN
							#   DISPLAY l_arr_rec_acctxlate[l_idx].* TO sr_acctxlate[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_acctxlate[l_idx].ext_acct_code = 
						l_rec_acctxlate.ext_acct_code 
						LET l_arr_rec_acctxlate[l_idx].int_acct_code = 
						l_rec_acctxlate.int_acct_code 
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
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_acctxlate[l_idx].ext_acct_code IS NOT NULL THEN 
				LET l_rowid = l_arr_rec_row[l_idx].rowid 
				LET l_rec_acctxlate.ext_acct_code = l_arr_rec_acctxlate[l_idx].ext_acct_code 
				LET l_rec_acctxlate.int_acct_code = l_arr_rec_acctxlate[l_idx].int_acct_code 
				LET l_rec_acctxlate.type_ind = glob_account_arg 
				LET l_rec_acctxlate.cmpy_code = glob_rec_kandoouser.cmpy_code 
				UPDATE acctxlate 
				SET * = l_rec_acctxlate.* 
				WHERE rowid = l_rowid 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO acctxlate VALUES (l_rec_acctxlate.*) 
				END IF 
			END IF 
		END FOR 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("U",8000,l_del_cnt) 
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_acctxlate[l_idx].scroll_flag = "*" THEN 
						DELETE FROM acctxlate 
						WHERE rowid = l_arr_rec_row[l_idx].rowid 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


