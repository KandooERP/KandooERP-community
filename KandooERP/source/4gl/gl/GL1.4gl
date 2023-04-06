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

	Source code beautified by beautify.pl on 2020-01-03 14:28:45	$Id: $
}



#   GL1 - Report Header Maintenance

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GL1") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 


	OPEN WINDOW g543 with FORM "G543" 
	CALL windecoration_g("G543") 

	WHILE select_rephead() 
		CALL scan_rephead() 
	END WHILE 
	CLOSE WINDOW g543 
END MAIN 

###################################################################
# FUNCTION select_rephead()
#
#
###################################################################
FUNCTION select_rephead() 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON rept_code, 
	desc_text 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GL1","construct-rept") 

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
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM glrephead ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY rept_code" 

		PREPARE s_rephead FROM l_query_text 
		DECLARE c_rephead CURSOR FOR s_rephead 

		RETURN true 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION scan_rephead()
#
#
###################################################################
FUNCTION scan_rephead() 
	DEFINE l_rept_code LIKE glrephead.rept_code 
	DEFINE l_rec_glrephead RECORD LIKE glrephead.* 
	DEFINE l_arr_rec_glrephead DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag CHAR(1), 
		rept_code LIKE glrephead.rept_code, 
		desc_text LIKE glrephead.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 

	FOREACH c_rephead INTO l_rec_glrephead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_glrephead[l_idx].rept_code = l_rec_glrephead.rept_code 
		LET l_arr_rec_glrephead[l_idx].desc_text = l_rec_glrephead.desc_text 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",9100,l_idx) 
			#9100 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET l_idx=1 
		LET l_msgresp = kandoomsg("U",9101,"") 
		#9101" No records satisfied selection criteria "
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

--	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",9521,"") 

	#9521" F1 TO Add - F2 TO Delete - F6 TO view Detail - F8 TO sort"
	INPUT ARRAY l_arr_rec_glrephead WITHOUT DEFAULTS FROM sr_glrephead.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL1","inp-arr-glrephead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			INITIALIZE l_rec_glrephead.* TO NULL 
			INITIALIZE l_arr_rec_glrephead[l_idx].* TO NULL 
			NEXT FIELD rept_code 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_glrephead[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_glrephead[l_idx].* TO sr_glrephead[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_glrephead[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_glrephead[l_idx].scroll_flag TO sr_glrephead[scrn].scroll_flag

			LET l_rec_glrephead.rept_code = l_arr_rec_glrephead[l_idx].rept_code 
			LET l_rec_glrephead.desc_text = l_arr_rec_glrephead[l_idx].desc_text 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_glrephead[l_idx+1].rept_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF l_arr_rec_glrephead[l_idx+8].desc_text IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There are no more rows....
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD rept_code 
			#DISPLAY l_arr_rec_glrephead[l_idx].* TO sr_glrephead[scrn].*

			IF l_arr_rec_glrephead[l_idx].rept_code IS NOT NULL THEN 
				IF l_rec_glrephead.rept_code IS NOT NULL THEN 
					NEXT FIELD desc_text 
				END IF 
			END IF 

		AFTER FIELD rept_code 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrephead[l_idx].rept_code IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD rept_code 
					ELSE 
						IF l_rec_glrephead.rept_code IS NULL THEN 
							SELECT unique 1 FROM glrephead 
							WHERE rept_code = l_arr_rec_glrephead[l_idx].rept_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								# 9104 RECORD already exists
								NEXT FIELD rept_code 
							ELSE 
								FOR l_i = 1 TO arr_count() 
									IF l_i <> l_idx THEN 
										IF l_arr_rec_glrephead[l_idx].rept_code = 
										l_arr_rec_glrephead[l_i].rept_code THEN 
											LET l_msgresp = kandoomsg("U",9104,"") 
											# 9104 RECORD already exists
											NEXT FIELD rept_code 
										END IF 
									END IF 
								END FOR 
							END IF 
						ELSE 
							LET l_arr_rec_glrephead[l_idx].rept_code = l_rec_glrephead.rept_code 
							#DISPLAY l_arr_rec_glrephead[l_idx].rept_code
							#     TO sr_glrephead[scrn].rept_code

						END IF 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrephead[l_idx].desc_text IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A value must be entered
								NEXT FIELD desc_text 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 

						NEXT FIELD NEXT 
					END IF 

				OTHERWISE 
					NEXT FIELD rept_code 
			END CASE 

		AFTER FIELD desc_text 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("down") 

					IF l_arr_rec_glrephead[l_idx].desc_text IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 A value must be entered
						NEXT FIELD desc_text 
					ELSE 
						UPDATE glrephead 
						SET desc_text = l_arr_rec_glrephead[l_idx].desc_text 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND rept_code = l_arr_rec_glrephead[l_idx].rept_code 

						IF sqlca.sqlerrd[3] = 0 THEN 
							LET l_rec_glrephead.cmpy_code = glob_rec_kandoouser.cmpy_code 
							LET l_rec_glrephead.rept_code = l_arr_rec_glrephead[l_idx].rept_code 
							LET l_rec_glrephead.desc_text = l_arr_rec_glrephead[l_idx].desc_text 
							INSERT INTO glrephead VALUES (l_rec_glrephead.*) 
						END IF 

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

		ON KEY (f6) infield (scroll_flag) --report details 

			LET l_rec_glrephead.rept_code = l_arr_rec_glrephead[l_idx].rept_code 

			OPEN WINDOW g544 with FORM "G544" 
			CALL windecoration_g("G544") 

			CALL disp_glrepdetl(glob_rec_kandoouser.cmpy_code,l_rec_glrephead.rept_code) 
			CLOSE WINDOW g544 
			CALL set_toolbar("kandoo","GL1","inp-arr-glrephead") --for toolbarmanagereditor 

		ON KEY (f8) infield (scroll_flag) --report GROUP ORDER 
			LET l_rec_glrephead.rept_code = l_arr_rec_glrephead[l_idx].rept_code 

			OPEN WINDOW g546 with FORM "G546" 
			CALL windecoration_g("G546") 

			CALL disp_glrepgroup(glob_rec_kandoouser.cmpy_code,l_rec_glrephead.rept_code) 
			CLOSE WINDOW g546 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f36 
			CALL set_toolbar("kandoo","GL1","inp-arr-glrephead") --for toolbarmanagereditor 

		ON KEY (F2) infield (scroll_flag) --delete 
			IF l_arr_rec_glrephead[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_glrephead[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_glrephead[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_rec_glrephead[l_idx].* TO sr_glrephead[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_glrephead.rept_code IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_glrephead[l_idx].* = l_arr_rec_glrephead[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_glrephead[l_idx].* TO NULL 
							END IF 
							#IF scrn <= 8 THEN
							#   DISPLAY l_arr_rec_glrephead[l_idx].* TO sr_glrephead[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_glrephead[l_idx].rept_code = l_rec_glrephead.rept_code 
						LET l_arr_rec_glrephead[l_idx].desc_text = l_rec_glrephead.desc_text 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

--		ON KEY (control-w) --help 
--			CALL kandoohelp("") 
--			CALL set_toolbar("kandoo","GL1","inp-arr-glrephead") --for toolbarmanagereditor 

	END INPUT 
	##############################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_glrephead[l_idx].rept_code IS NOT NULL THEN 
				LET l_rec_glrephead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_glrephead.rept_code = l_arr_rec_glrephead[l_idx].rept_code 
				LET l_rec_glrephead.desc_text = l_arr_rec_glrephead[l_idx].desc_text 
				UPDATE glrephead 
				SET * = l_rec_glrephead.* 
				WHERE rept_code = l_rec_glrephead.rept_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO glrephead VALUES (l_rec_glrephead.*) 
				END IF 
			END IF 
		END FOR 

		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("U",9903,l_del_cnt) 
			#9903 Confirm TO Delete ",l_del_cnt," REPORT headings? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_glrephead[l_idx].scroll_flag = "*" THEN 
						DELETE FROM glrephead 
						WHERE rept_code = l_arr_rec_glrephead[l_idx].rept_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						DELETE FROM glrepdetl 
						WHERE rept_code = l_arr_rec_glrephead[l_idx].rept_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						DELETE FROM glrepgroup 
						WHERE rept_code = l_arr_rec_glrephead[l_idx].rept_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION disp_glrepdetl(p_cmpy,p_rept_code)
#
#
###################################################################
FUNCTION disp_glrepdetl(p_cmpy,p_rept_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rept_code LIKE glrephead.rept_code 
	DEFINE l_rec_glrephead RECORD LIKE glrephead.* 
	DEFINE l_rec_glrepdetl RECORD LIKE glrepdetl.*
	DEFINE l_rec_glrepsubgrp RECORD LIKE glrepsubgrp.* 
	DEFINE l_rec_glrepgroup RECORD LIKE glrepgroup.* 
	DEFINE l_arr_rec_glrepdetl DYNAMIC ARRAY OF RECORD --ARRAY [2000] OF RECORD 
		scroll_flag CHAR (1), 
		chart_code LIKE glrepdetl.chart_code, 
		ref_ind LIKE glrepdetl.ref_ind, 
		group_code LIKE glrepdetl.group_code 
	END RECORD
	DEFINE l_scroll_flag CHAR (1) 
	DEFINE l_sel_text CHAR (20) 
	DEFINE l_winds_text CHAR (40)
	DEFINE l_where_text CHAR(200) 
	DEFINE l_query_text CHAR(400) 
	DEFINE l_mode CHAR(4) 
	DEFINE l_i SMALLINT 
	DEFINE l_del_cnt SMALLINT
	--DEFINE l_j SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	WHILE true 
		CLEAR FORM 
		SELECT * INTO l_rec_glrephead.* FROM glrephead 
		WHERE rept_code = p_rept_code 
		AND cmpy_code = p_cmpy 
		DISPLAY BY NAME l_rec_glrephead.rept_code, 
		l_rec_glrephead.desc_text 

		LET l_msgresp = kandoomsg("U",1001,"") 

		#1002 " Searching database - please wait"
		CONSTRUCT BY NAME l_where_text ON chart_code,	ref_ind, group_code 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","GL1","construct-chart") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM glrepdetl ", 
		"WHERE cmpy_code = '", p_cmpy, "' ", 
		"AND rept_code = '", p_rept_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY chart_code,ref_ind,group_code" 
		LET l_idx = 0 
		LET l_del_cnt = 0 

		PREPARE s_glrepdetl FROM l_query_text 
		DECLARE c_glrepdetl CURSOR FOR s_glrepdetl 

		FOREACH c_glrepdetl INTO l_rec_glrepdetl.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_glrepdetl[l_idx].scroll_flag = NULL 
			LET l_arr_rec_glrepdetl[l_idx].chart_code = l_rec_glrepdetl.chart_code 
			LET l_arr_rec_glrepdetl[l_idx].ref_ind = l_rec_glrepdetl.ref_ind 
			LET l_arr_rec_glrepdetl[l_idx].group_code = l_rec_glrepdetl.group_code 
			IF l_idx = 2000 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		LET l_msgresp = kandoomsg("U",9113,l_idx) 

		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_rec_glrepdetl[l_idx].* TO NULL 
		END IF 

		CALL set_count(l_idx) 
		LET l_msgresp = kandoomsg("G",1004,"") 


		#1004" F1 TO Add - F2 TO Delete - ESC TO Continue "
		INPUT ARRAY l_arr_rec_glrepdetl WITHOUT DEFAULTS FROM sr_glrepdetl.* attributes(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GL1","inp-arr-glrepdetl") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				NEXT FIELD scroll_flag 

			BEFORE INSERT 
				INITIALIZE l_rec_glrepdetl.* TO NULL 
				INITIALIZE l_arr_rec_glrepdetl[l_idx].* TO NULL 
				LET l_mode = MODE_CLASSIC_ADD 
				NEXT FIELD chart_code 

			BEFORE FIELD scroll_flag 
				INITIALIZE l_mode TO NULL 
				LET l_scroll_flag = l_arr_rec_glrepdetl[l_idx].scroll_flag 
				#DISPLAY l_arr_rec_glrepdetl[l_idx].* TO sr_glrepdetl[scrn].*

			AFTER FIELD scroll_flag 
				LET l_arr_rec_glrepdetl[l_idx].scroll_flag = l_scroll_flag 
				#DISPLAY l_arr_rec_glrepdetl[l_idx].scroll_flag TO sr_glrepdetl[scrn].scroll_flag

				LET l_rec_glrepdetl.chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
				LET l_rec_glrepdetl.ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 
				LET l_rec_glrepdetl.group_code = l_arr_rec_glrepdetl[l_idx].group_code 

				IF fgl_lastkey() = fgl_keyval("down") THEN 
					IF l_arr_rec_glrepdetl[l_idx+1].chart_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp=kandoomsg("W",9001,"") 
						#9001 There are no rows...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

				IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
					IF l_arr_rec_glrepdetl[l_idx+8].group_code IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("W",9001,"") 
						#9001 There are no more rows....
						NEXT FIELD scroll_flag 
					END IF 
				END IF 

			BEFORE FIELD chart_code 
				IF l_arr_rec_glrepdetl[l_idx].chart_code IS NULL 
				AND l_mode IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 
				IF (fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right")) 
				AND l_mode IS NULL THEN 
					NEXT FIELD scroll_flag 
				END IF 

			AFTER FIELD chart_code 
				IF l_arr_rec_glrepdetl[l_idx].chart_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD chart_code 
				END IF 

				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("down") 
						IF l_rec_glrepdetl.chart_code IS NULL THEN 
							LET l_sel_text = "*", l_arr_rec_glrepdetl[l_idx].chart_code clipped 
							SELECT unique 1 FROM coa 
							WHERE cmpy_code = p_cmpy 
							AND acct_code matches l_sel_text 
							IF status = NOTFOUND THEN 
								LET l_msgresp = kandoomsg("G",9518,"") 
								#9518 Chart code NOT found
								NEXT FIELD chart_code 
							END IF 
						ELSE 
							LET l_arr_rec_glrepdetl[l_idx].chart_code = l_rec_glrepdetl.chart_code 
							#DISPLAY l_arr_rec_glrepdetl[l_idx].chart_code
							#     TO sr_glrepdetl[scrn].chart_code

						END IF 

						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrepdetl[l_idx].ref_ind IS NULL THEN 
								LET l_msgresp = kandoomsg("G",9523,"") 
								#9523 Enter Line Type (Q)uantity / (V)alue
								NEXT FIELD ref_ind 
							END IF 
							IF l_arr_rec_glrepdetl[l_idx].group_code IS NULL THEN 
								LET l_msgresp = kandoomsg("G",9522,"") 
								#9522 Group code NOT found - Try window
								NEXT FIELD group_code 
							END IF 

							SELECT * FROM glrepdetl 
							WHERE cmpy_code = p_cmpy 
							AND rept_code = p_rept_code 
							AND chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
							AND group_code = l_arr_rec_glrepdetl[l_idx].group_code 
							AND ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 

							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								#9104 RECORD already exists
								NEXT FIELD chart_code 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 

						NEXT FIELD NEXT 

					OTHERWISE 
						NEXT FIELD chart_code 
				END CASE 

			AFTER FIELD ref_ind 
				IF l_arr_rec_glrepdetl[l_idx].ref_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("G",9523,"") 
					#9523 Enter Line Type (Q)uantity / (V)alue
					NEXT FIELD ref_ind 
				END IF 

				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					IF l_arr_rec_glrepdetl[l_idx].group_code IS NULL THEN 
						LET l_msgresp = kandoomsg("G",9522,"") 
						#9522 Group code NOT found - Try window
						NEXT FIELD group_code 
					END IF 
					SELECT * FROM glrepdetl 
					WHERE cmpy_code = p_cmpy 
					AND rept_code = p_rept_code 
					AND chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
					AND group_code = l_arr_rec_glrepdetl[l_idx].group_code 
					AND ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 
					IF status != NOTFOUND THEN 
						LET l_msgresp = kandoomsg("U",9104,"") 
						#9104 RECORD already exists
						NEXT FIELD ref_ind 
					END IF 
					NEXT FIELD scroll_flag 
				END IF 

				IF fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("right") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("down") THEN 
					NEXT FIELD NEXT 
				ELSE 
					NEXT FIELD previous 
				END IF 

			ON ACTION "LOOKUP" infield (group_code) 
				LET l_winds_text = NULL 
				LET l_winds_text = show_group_code(p_cmpy) 
				OPTIONS INSERT KEY f1, 
				DELETE KEY f36 
				IF l_winds_text IS NOT NULL THEN 
					LET l_arr_rec_glrepdetl[l_idx].group_code = l_winds_text 
				END IF 
				NEXT FIELD group_code 

			AFTER FIELD group_code 
				CASE 
					WHEN fgl_lastkey() = fgl_keyval("accept") 
						OR fgl_lastkey() = fgl_keyval("RETURN") 
						OR fgl_lastkey() = fgl_keyval("tab") 
						OR fgl_lastkey() = fgl_keyval("right") 
						OR fgl_lastkey() = fgl_keyval("down") 
						IF l_arr_rec_glrepdetl[l_idx].group_code IS NULL THEN 
							LET l_msgresp = kandoomsg("G",9522,"") 
							#9522 Group code NOT found - Try window
							NEXT FIELD group_code 
						ELSE 
							SELECT unique 1 FROM glrepsubgrp 
							WHERE cmpy_code = p_cmpy 
							AND group_code = l_arr_rec_glrepdetl[l_idx].group_code 
							IF status = NOTFOUND THEN 
								LET l_msgresp = kandoomsg("G",9518,"") 
								#9518 Chart code NOT found
								NEXT FIELD group_code 
							END IF 
							SELECT * FROM glrepdetl 
							WHERE cmpy_code = p_cmpy 
							AND rept_code = p_rept_code 
							AND chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
							AND group_code = l_arr_rec_glrepdetl[l_idx].group_code 
							AND ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 
							IF status != NOTFOUND THEN 
								LET l_msgresp = kandoomsg("U",9104,"") 
								#9104 RECORD already exists
								NEXT FIELD group_code 
							END IF 
						END IF 

					WHEN fgl_lastkey() = fgl_keyval("left") 
						OR fgl_lastkey() = fgl_keyval("up") 
						NEXT FIELD previous 

					OTHERWISE 
						NEXT FIELD group_code 

				END CASE 

				LET l_rec_glrepdetl.cmpy_code = p_cmpy 
				LET l_rec_glrepdetl.chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
				LET l_rec_glrepdetl.rept_code = p_rept_code 
				LET l_rec_glrepdetl.ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 
				LET l_rec_glrepdetl.group_code = l_arr_rec_glrepdetl[l_idx].group_code 

				INSERT INTO glrepdetl VALUES (l_rec_glrepdetl.*) 

				SELECT * INTO l_rec_glrepsubgrp.* FROM glrepsubgrp 
				WHERE group_code = l_rec_glrepdetl.group_code 
				AND cmpy_code = p_cmpy 

				SELECT * INTO l_rec_glrepgroup.* FROM glrepgroup 
				WHERE maingrp_code = l_rec_glrepsubgrp.maingrp_code 
				AND rept_code = p_rept_code 
				AND cmpy_code = p_cmpy 

				IF status = NOTFOUND THEN 
					LET l_rec_glrepgroup.cmpy_code = p_cmpy 
					LET l_rec_glrepgroup.maingrp_code = l_rec_glrepsubgrp.maingrp_code 
					LET l_rec_glrepgroup.rept_code = p_rept_code 
					INSERT INTO glrepgroup VALUES (l_rec_glrepgroup.*) 
				END IF 

				NEXT FIELD scroll_flag 

			ON KEY (F2) infield (scroll_flag) --delete multiple SELECT 

				IF l_arr_rec_glrepdetl[l_idx].scroll_flag IS NULL 
				AND l_arr_rec_glrepdetl[l_idx].chart_code IS NOT NULL THEN 
					LET l_arr_rec_glrepdetl[l_idx].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					IF l_arr_rec_glrepdetl[l_idx].scroll_flag = "*" THEN 
						LET l_arr_rec_glrepdetl[l_idx].scroll_flag = NULL 
						LET l_del_cnt = l_del_cnt - 1 
					END IF 
				END IF 
				NEXT FIELD scroll_flag 


				#AFTER ROW
				#   DISPLAY l_arr_rec_glrepdetl[l_idx].* TO sr_glrepdetl[scrn].*

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					IF NOT (infield(scroll_flag)) THEN 
						IF l_rec_glrepdetl.chart_code IS NULL THEN 

							FOR l_idx = arr_curr() TO arr_count() 
								LET l_arr_rec_glrepdetl[l_idx].* = l_arr_rec_glrepdetl[l_idx+1].* 
								IF l_idx = arr_count() THEN 
									INITIALIZE l_arr_rec_glrepdetl[l_idx].* TO NULL 
								END IF 
								#IF scrn <= 8 THEN
								#   DISPLAY l_arr_rec_glrepdetl[l_idx].* TO sr_glrepdetl[scrn].*
								#
								#   LET scrn = scrn + 1
								#END IF
							END FOR 

							#LET scrn = scr_line()
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 

						ELSE 

							LET l_arr_rec_glrepdetl[l_idx].chart_code = l_rec_glrepdetl.chart_code 
							LET l_arr_rec_glrepdetl[l_idx].ref_ind = l_rec_glrepdetl.ref_ind 
							LET l_arr_rec_glrepdetl[l_idx].group_code = l_rec_glrepdetl.group_code 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD scroll_flag 
						END IF 

					END IF 

				END IF 

				IF l_del_cnt > 0 THEN 
					LET l_msgresp = kandoomsg("U",9903,l_del_cnt) 
					#9903 Confirm TO Delete ",l_del_cnt," detail heading? (Y/N)"
					IF l_msgresp = "Y" THEN 
						FOR l_idx = 1 TO arr_count() 
							IF l_arr_rec_glrepdetl[l_idx].scroll_flag = "*" THEN 
								DELETE FROM glrepdetl 
								WHERE chart_code = l_arr_rec_glrepdetl[l_idx].chart_code 
								AND rept_code = p_rept_code 
								AND group_code = l_arr_rec_glrepdetl[l_idx].group_code 
								AND ref_ind = l_arr_rec_glrepdetl[l_idx].ref_ind 
								AND cmpy_code = p_cmpy 
							END IF 
						END FOR 
					END IF 
				END IF 

		END INPUT 

	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION disp_glrepgroup(p_cmpy_code,p_rept_code)
#
#
###################################################################
FUNCTION disp_glrepgroup(p_cmpy_code,p_rept_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_rept_code LIKE glrephead.rept_code
	
	DEFINE l_rec_glrephead RECORD LIKE glrephead.* 
	DEFINE l_rec_glrepdetl RECORD LIKE glrepdetl.*
	DEFINE l_rec_glrepsubgrp RECORD LIKE glrepsubgrp.*
	DEFINE l_rec_glrepmaingrp RECORD LIKE glrepmaingrp.* 
	DEFINE l_rec_glrepgroup RECORD LIKE glrepgroup.* 
	DEFINE l_arr_rec_glrepgroup DYNAMIC ARRAY OF RECORD --ARRAY [800] OF RECORD 
		scroll_flag CHAR (1), 
		maingrp_code LIKE glrepgroup.maingrp_code, 
		repmaingrp_desc_text LIKE glrepmaingrp.desc_text, 
		rept_order LIKE glrepgroup.rept_order 
	END RECORD 
	DEFINE l_repmain_text LIKE glrepmaingrp.desc_text 
	DEFINE l_maingrp LIKE glrepsubgrp.maingrp_code
	DEFINE l_maingrp_code LIKE glrepmaingrp.maingrp_code 
	DEFINE l_scroll_flag CHAR (1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_glrephead.* FROM glrephead 
	WHERE rept_code = p_rept_code 
	AND cmpy_code = p_cmpy_code 

	DECLARE c_glrepgroup CURSOR FOR 
	SELECT * FROM glrepdetl d,glrepsubgrp g 
	WHERE d.rept_code = p_rept_code 
	AND d.cmpy_code = p_cmpy_code 
	AND g.group_code = d.group_code 
	AND g.cmpy_code = d.cmpy_code 
	ORDER BY g.maingrp_code 

	DISPLAY BY NAME l_rec_glrephead.rept_code, 
	l_rec_glrephead.desc_text 

	LET l_maingrp = NULL 
	LET l_idx = 0 

	FOREACH c_glrepgroup INTO l_rec_glrepgroup.*,l_rec_glrepsubgrp.* 
		IF l_maingrp_code IS NULL OR 
		l_maingrp_code <> l_rec_glrepsubgrp.maingrp_code THEN 
			LET l_maingrp_code = l_rec_glrepsubgrp.maingrp_code 
			LET l_idx = l_idx + 1 

			SELECT * INTO l_rec_glrepgroup.* FROM glrepgroup 
			WHERE rept_code = p_rept_code 
			AND maingrp_code = l_rec_glrepsubgrp.maingrp_code 
			AND cmpy_code = p_cmpy_code 

			IF status = 0 THEN 
				LET l_arr_rec_glrepgroup[l_idx].scroll_flag = NULL 
				LET l_arr_rec_glrepgroup[l_idx].maingrp_code = l_rec_glrepgroup.maingrp_code 
				LET l_arr_rec_glrepgroup[l_idx].rept_order = l_rec_glrepgroup.rept_order 
				SELECT desc_text INTO l_repmain_text FROM glrepmaingrp 
				WHERE maingrp_code = l_rec_glrepsubgrp.maingrp_code 
				AND cmpy_code = p_cmpy_code 
				LET l_arr_rec_glrepgroup[l_idx].repmaingrp_desc_text = l_repmain_text 
			ELSE 
				LET l_arr_rec_glrepgroup[l_idx].scroll_flag = NULL 
				LET l_arr_rec_glrepgroup[l_idx].maingrp_code = l_rec_glrepsubgrp.maingrp_code 
				LET l_arr_rec_glrepgroup[l_idx].rept_order = "0" 
				SELECT desc_text INTO l_repmain_text FROM glrepmaingrp 
				WHERE maingrp_code = l_rec_glrepsubgrp.maingrp_code 
				AND cmpy_code = p_cmpy_code 
				LET l_arr_rec_glrepgroup[l_idx].repmaingrp_desc_text = l_repmain_text 
			END IF 

			IF l_idx = 800 THEN 
				LET l_msgresp = kandoomsg("W",6100,l_idx) 
				EXIT FOREACH 
			END IF 

		END IF 

	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected

	IF l_idx = 0 THEN 
		LET l_idx = 1 
	END IF 

	CALL set_count(l_idx) 

	OPTIONS INSERT KEY f38, 
	DELETE KEY f36 
	LET l_msgresp = kandoomsg("G",1035,"") 

	#1035" RETURN TO Line Edit  - ESC TO Continue "
	INPUT ARRAY l_arr_rec_glrepgroup WITHOUT DEFAULTS FROM sr_glrepgroup.* attributes(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GL1","inp-arr-glrepgroup") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_glrepgroup[l_idx].scroll_flag 
			INITIALIZE l_rec_glrepgroup.* TO NULL 
			#DISPLAY l_arr_rec_glrepgroup[l_idx].* TO sr_glrepgroup[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_glrepgroup[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_glrepgroup[l_idx].scroll_flag
			#        TO sr_glrepgroup[scrn].scroll_flag

			LET l_rec_glrepgroup.cmpy_code = p_cmpy_code 
			LET l_rec_glrepgroup.rept_order = l_arr_rec_glrepgroup[l_idx].rept_order 
			LET l_rec_glrepgroup.maingrp_code = l_arr_rec_glrepgroup[l_idx].maingrp_code 
			LET l_repmain_text = l_arr_rec_glrepgroup[l_idx].repmaingrp_desc_text 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_glrepgroup[l_idx+1].maingrp_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There are no rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF l_arr_rec_glrepgroup[l_idx+8].maingrp_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There are no rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

			#BEFORE FIELD rept_order
			#   DISPLAY l_arr_rec_glrepgroup[l_idx].* TO sr_glrepgroup[scrn].*

		AFTER FIELD rept_order 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
					OR fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_rec_glrepgroup[l_idx].rept_order IS NULL THEN 
						LET l_msgresp = kandoomsg("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD rept_order 
					ELSE 
						IF fgl_lastkey() = fgl_keyval("accept") THEN 
							IF l_arr_rec_glrepgroup[l_idx].rept_order IS NULL THEN 
								LET l_msgresp = kandoomsg("U",9102,"") 
								#9102 A Value must be entered
								NEXT FIELD rept_order 
							END IF 
							NEXT FIELD scroll_flag 
						END IF 
						NEXT FIELD NEXT 
					END IF 
			END CASE 

			#AFTER ROW
			#   DISPLAY l_arr_rec_glrepgroup[l_idx].* TO sr_glrepgroup[scrn].*

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_glrepgroup.rept_order IS NULL THEN 
						FOR l_idx = arr_curr() TO arr_count() 
							LET l_arr_rec_glrepgroup[l_idx].* = l_arr_rec_glrepgroup[l_idx+1].* 
							IF l_idx = arr_count() THEN 
								INITIALIZE l_arr_rec_glrepgroup[l_idx].* TO NULL 
							END IF 
							#IF scrn <= 8 THEN
							#   DISPLAY l_arr_rec_glrepgroup[l_idx].* TO sr_glrepgroup[scrn].*
							#
							#   LET scrn = scrn + 1
							#END IF
						END FOR 
						#LET scrn = scr_line()
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_glrepgroup[l_idx].maingrp_code = 
						l_rec_glrepgroup.maingrp_code 
						LET l_arr_rec_glrepgroup[l_idx].repmaingrp_desc_text = 
						l_repmain_text 
						LET l_arr_rec_glrepgroup[l_idx].rept_order = 
						l_rec_glrepgroup.rept_order 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

	END INPUT 
	##################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 

		BEGIN WORK 
			DELETE FROM glrepgroup 
			WHERE rept_code = p_rept_code 
			AND cmpy_code = p_cmpy_code 

			FOR l_idx = 1 TO arr_count() 
				IF l_arr_rec_glrepgroup[l_idx].rept_order IS NOT NULL THEN 
					LET l_rec_glrepgroup.cmpy_code = p_cmpy_code 
					LET l_rec_glrepgroup.rept_code = p_rept_code 
					LET l_rec_glrepgroup.maingrp_code = l_arr_rec_glrepgroup[l_idx].maingrp_code 
					LET l_rec_glrepgroup.rept_order = l_arr_rec_glrepgroup[l_idx].rept_order 
					INSERT INTO glrepgroup VALUES (l_rec_glrepgroup.*) 
				END IF 
			END FOR 

		COMMIT WORK 

	END IF 

END FUNCTION