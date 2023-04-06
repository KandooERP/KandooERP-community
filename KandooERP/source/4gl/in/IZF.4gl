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

	Source code beautified by beautify.pl on 2020-01-03 09:12:49	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "I_IN_GLOBALS.4gl" 

#   IZF - Warehouse Group Maintenance

GLOBALS 
	DEFINE 
	err_message CHAR(40) 
END GLOBALS 


####################################################################
# MAIN
#
#
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZF") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i647 with FORM "I647" 
	 CALL windecoration_i("I647") -- albo kd-758 

	#   WHILE select_waregrp()
	CALL scan_waregrp() 
	#   END WHILE
	CLOSE WINDOW i647 
END MAIN 


####################################################################
# FUNCTION select_waregrp()
#
#
####################################################################
FUNCTION select_waregrp(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE l_arr_rec_waregrp DYNAMIC ARRAY OF t_rec_waregrp_wc_nt_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("W",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON waregrp_code, 
		name_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","IZF","construct-waregrp_code-1") -- albo kd-505 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("W",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM waregrp ", 
	"WHERE ", l_where_text clipped," ", 
	"AND cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"ORDER BY waregrp_code, cmpy_code" 
	PREPARE s_waregrp FROM l_query_text 
	DECLARE c_waregrp CURSOR FOR s_waregrp 

	LET l_idx = 0 
	FOREACH c_waregrp INTO l_rec_waregrp.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_waregrp[l_idx].waregrp_code = l_rec_waregrp.waregrp_code 
		LET l_arr_rec_waregrp[l_idx].name_text = l_rec_waregrp.name_text 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("W",9021,l_idx) 
			#9021 " First ??? entries Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("W",9024,"") 
		#9024" No entries satisfied selection criteria "
	END IF 

	RETURN l_arr_rec_waregrp 
END FUNCTION 


####################################################################
# FUNCTION scan_waregrp()
#
#
####################################################################
FUNCTION scan_waregrp() 
	#	DEFINE l_rec_waregrp RECORD LIKE waregrp.*
	DEFINE l_arr_rec_waregrp DYNAMIC ARRAY OF t_rec_waregrp_wc_nt_with_scrollflag 
	#	array[100] OF
	#		RECORD
	#			scroll_flag CHAR(1),
	#			waregrp_code LIKE waregrp.waregrp_code,
	#			name_text    LIKE waregrp.name_text
	#      END RECORD
	#	DEFINE l_scroll_flag CHAR(1)
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE x SMALLINT 
	DEFINE msgstr STRING 
	DEFINE l_vcount INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	-----------------
	IF db_waregrp_get_count() > 1000 THEN 
		CALL select_waregrp(true) RETURNING l_arr_rec_waregrp 
	ELSE 
		CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 
	END IF 

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 

	#   CALL set_count(l_idx)
	LET l_msgresp = kandoomsg("W",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_waregrp WITHOUT DEFAULTS FROM sr_waregrp.* attribute(unbuffered, append ROW = false, auto append = false, DELETE ROW = false, INSERT ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZF","input-arr-l_arr_rec_waregrp-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL select_waregrp(true) RETURNING l_arr_rec_waregrp 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#			IF l_idx > 0 THEN
			#				LET l_scroll_flag = l_arr_rec_waregrp[l_idx].scroll_flag
			#			END IF


		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			#         LET l_scroll_flag = l_arr_rec_waregrp[l_idx].scroll_flag
			#         DISPLAY l_arr_rec_waregrp[l_idx].* TO sr_waregrp[scrn].*

		BEFORE FIELD waregrp_code #read only 
			NEXT FIELD scroll_flag 

		BEFORE FIELD name_text #read only 
			NEXT FIELD scroll_flag 

			#ON ACTION "EDIT"
			#		AFTER FIELD scroll_flag
			#         LET l_arr_rec_waregrp[l_idx].scroll_flag = l_scroll_flag
			#         DISPLAY l_arr_rec_waregrp[l_idx].scroll_flag
			#              TO sr_waregrp[scrn].scroll_flag

			#         LET l_rec_waregrp.waregrp_code  = l_arr_rec_waregrp[l_idx].waregrp_code
			#         LET l_rec_waregrp.name_text     = l_arr_rec_waregrp[l_idx].name_text
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_waregrp[l_idx+1].waregrp_code IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET l_msgresp=kandoomsg("W",9001,"")
			#               #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		ON ACTION "EDIT" 
			IF l_arr_rec_waregrp[l_idx].waregrp_code IS NOT NULL THEN 
				IF edit_waregrp(l_arr_rec_waregrp[l_idx].waregrp_code) THEN 
					CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 
				END IF 
			END IF 

			#		BEFORE FIELD waregrp_code
			#         IF l_arr_rec_waregrp[l_idx].waregrp_code IS NOT NULL THEN
			#            LET l_rec_waregrp.waregrp_code = l_arr_rec_waregrp[l_idx].waregrp_code
			#            IF edit_waregrp(l_rec_waregrp.waregrp_code) THEN
			#               SELECT * INTO l_rec_waregrp.* FROM waregrp
			#                WHERE waregrp_code = l_rec_waregrp.waregrp_code
			#                  AND cmpy_code = glob_rec_kandoouser.cmpy_code
			#               LET l_arr_rec_waregrp[l_idx].waregrp_code = l_rec_waregrp.waregrp_code
			#               LET l_arr_rec_waregrp[l_idx].name_text = l_rec_waregrp.name_text
			#            END IF
			#         END IF
			#         OPTIONS INSERT KEY F1,
			#                 DELETE KEY F36
			#         NEXT FIELD scroll_flag
			#
		ON ACTION "NEW" 
			IF edit_waregrp(null) THEN 
				CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 
			END IF 


			#BEFORE INSERT
			#         IF arr_curr() < arr_count() THEN
			#            LET l_curr = arr_curr()
			#            LET l_cnt = arr_count()
			#            LET l_rowid = edit_waregrp("")
			#            OPTIONS INSERT KEY F1,
			#                    DELETE KEY F36
			#            IF l_rowid = 0 THEN
			#               FOR l_idx = l_curr TO l_cnt
			#                  LET l_arr_rec_waregrp[l_idx].* = l_arr_rec_waregrp[l_idx+1].*
			#                  IF scrn <= 8  THEN
			#                     DISPLAY l_arr_rec_waregrp[l_idx].* TO sr_waregrp[scrn].*
			#
			#                     LET scrn = scrn + 1
			#                  END IF
			#               END FOR
			#               INITIALIZE l_arr_rec_waregrp[l_idx].* TO NULL
			#            ELSE
			#               SELECT * INTO l_rec_waregrp.* FROM waregrp
			#                WHERE rowid = l_rowid
			#               LET l_arr_rec_waregrp[l_idx].waregrp_code = l_rec_waregrp.waregrp_code
			#               LET l_arr_rec_waregrp[l_idx].name_text = l_rec_waregrp.name_text
			#            END IF
			#         ELSE
			#            IF l_idx > 1 THEN
			#               LET l_msgresp = kandoomsg("W",9001,"")
			#               #9001 There are no more rows....
			#            END IF
			#         END IF

		AFTER INSERT 
			CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 

		ON KEY (F2) --delete marker 
			FOR i = 1 TO l_arr_rec_waregrp.getlength() 
				IF l_arr_rec_waregrp[i].scroll_flag = "*" THEN 
					LET l_del_cnt = l_del_cnt + 1 
				END IF 
			END FOR 
			IF l_del_cnt < 1 THEN #no ROW selected via checkbox - so CURRENT ROW IS selected AND will be deleted 
				LET msgstr = "Do you want to delete the warehouse group ", trim(l_arr_rec_waregrp[l_idx].waregrp_code), "/", trim(l_arr_rec_waregrp[l_idx].name_text), " ?" 
				IF promptTF("Delete",msgStr,TRUE) THEN 
					DELETE FROM waregrp 
					WHERE waregrp_code = l_arr_rec_waregrp[l_idx].waregrp_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				END IF 
			ELSE 
				LET l_msgresp = kandoomsg("W",8061,l_del_cnt) 
				#8061 "Confirmation TO Delete ",l_del_cnt," Warehouse Group(s)? (Y/N)"
				IF l_msgresp = "Y" THEN 
					FOR l_idx = 1 TO l_arr_rec_waregrp.getlength() 
						IF l_arr_rec_waregrp[l_idx].scroll_flag = "*" THEN 
							DELETE FROM waregrp 
							WHERE waregrp_code = l_arr_rec_waregrp[l_idx].waregrp_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 
			#refresh program array from DB
			CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 

			----------------------

			#         IF l_arr_rec_waregrp[l_idx].scroll_flag IS NULL THEN
			#                  LET l_arr_rec_waregrp[l_idx].scroll_flag = "*"
			#                  LET l_del_cnt = l_del_cnt + 1
			#         ELSE
			#            LET l_arr_rec_waregrp[l_idx].scroll_flag = NULL
			#            LET l_del_cnt = l_del_cnt - 1
			#         END IF
			#         NEXT FIELD scroll_flag

			#      AFTER ROW
			#         DISPLAY l_arr_rec_waregrp[l_idx].*
			#              TO sr_waregrp[scrn].*
			#
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	GOTO bypass 
	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		--AND WHERE was it opened? CLOSE WINDOW W125
		RETURN false 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			#here used to be the AFTER program row delete "*"
		END IF 
	COMMIT WORK 
END FUNCTION 


####################################################################
# FUNCTION edit_waregrp(p_rec_waregrp_code)
#
#
# EDIT and NEW record (NULL argument Is NEW)
####################################################################
FUNCTION edit_waregrp(p_rec_waregrp_code) 
	DEFINE l_rec_s_waregrp RECORD LIKE waregrp.* 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE p_rec_waregrp_code LIKE waregrp.waregrp_code 
	DEFINE l_sqlerrd INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_mode SMALLINT 

	INITIALIZE l_rec_waregrp.* TO NULL 
	IF p_rec_waregrp_code IS NOT NULL THEN #edit 
		SELECT * INTO l_rec_waregrp.* FROM waregrp 
		WHERE waregrp_code = p_rec_waregrp_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_mode = MODE_UPDATE 

	ELSE #new 
		LET l_rec_waregrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_mode = MODE_INSERT 
	END IF 


	OPEN WINDOW i650 with FORM "I650" 
	 CALL windecoration_i("I650") -- albo kd-758 

	DISPLAY BY NAME l_rec_waregrp.waregrp_code, 
	l_rec_waregrp.name_text, 
	l_rec_waregrp.cmpy1_text, 
	l_rec_waregrp.cmpy2_text, 
	l_rec_waregrp.cmpy3_text, 
	l_rec_waregrp.cartage_ind, 
	l_rec_waregrp.conv_uom_ind 

	INPUT BY NAME l_rec_waregrp.waregrp_code, 
	l_rec_waregrp.name_text, 
	l_rec_waregrp.cmpy1_text, 
	l_rec_waregrp.cmpy2_text, 
	l_rec_waregrp.cmpy3_text, 
	l_rec_waregrp.cartage_ind, 
	l_rec_waregrp.conv_uom_ind 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZF","input-l_rec_waregrp-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE FIELD waregrp_code 
			LET l_msgresp = kandoomsg("U",1020,"Warehouse Group") 
			#9365 " Enter Warehouse Group Details  "
			IF p_rec_waregrp_code IS NOT NULL THEN 
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD waregrp_code 
			IF l_rec_waregrp.waregrp_code IS NULL THEN 
				LET l_msgresp = kandoomsg("W",9365,"") 
				#9365 Warehouse Group code must be Entered
				NEXT FIELD waregrp_code 
			END IF 
			SELECT * INTO l_rec_s_waregrp.* FROM waregrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND waregrp_code = l_rec_waregrp.waregrp_code 
			IF status != notfound THEN 
				LET l_msgresp = kandoomsg("W",9366,"") 
				ERROR "#9366 warehouse group already exists" 
				NEXT FIELD waregrp_code 
			END IF 

		AFTER FIELD cartage_ind 
			IF l_rec_waregrp.cartage_ind IS NOT NULL THEN 
				IF l_rec_waregrp.cartage_ind NOT matches "[12]" THEN 
					LET l_msgresp = kandoomsg("W",9369,"") 
					#9369 A Cartage Type must be either 1 OR 2
					NEXT FIELD cartage_ind 
				END IF 
			END IF 

		AFTER FIELD conv_uom_ind 
			IF l_rec_waregrp.conv_uom_ind IS NOT NULL THEN 
				IF l_rec_waregrp.conv_uom_ind NOT matches "[YN]" THEN 
					LET l_msgresp = kandoomsg("W",9371,"") 
					#9371 Convert UOM must be either 'Y' OR 'N'
					NEXT FIELD conv_uom_ind 
				END IF 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_waregrp.waregrp_code IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9365,"") 
					#9365 Warehouse Group code must be Entered
					NEXT FIELD waregrp_code 
				END IF 
				IF l_rec_waregrp.name_text IS NULL THEN 
					LET l_msgresp = kandoomsg("W",9367,"") 
					#9367 A Company Division Name must be entered
					NEXT FIELD name_text 
				END IF 
				IF l_rec_waregrp.cartage_ind NOT matches "[12]" THEN 
					LET l_msgresp = kandoomsg("W",9369,"") 
					#9369 A Cartage Type must be either 1 OR 2
					NEXT FIELD cartage_ind 
				END IF 
				IF l_rec_waregrp.conv_uom_ind NOT matches "[YN]" THEN 
					LET l_msgresp = kandoomsg("W",9371,"") 
					#9371 Convert UOM must be either 'Y' OR 'N'
					NEXT FIELD conv_uom_ind 
				END IF 
			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i650 
		RETURN false 
	END IF 

	GOTO bypass 

	LABEL recovery: 
	IF error_recover(err_message, status) = "N" THEN 
		CLOSE WINDOW i650 
		RETURN false 
	END IF 

	LABEL bypass: 

	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		LET err_message = "IZF - Updating warehouse group" 
		IF l_mode = MODE_INSERT THEN # p_rec_waregrp_code IS NULL THEN 
			INSERT INTO waregrp VALUES (l_rec_waregrp.*) 
			LET l_sqlerrd = sqlca.sqlerrd[6] 
		ELSE 
			UPDATE waregrp 
			SET * = l_rec_waregrp.* 
			WHERE waregrp_code = l_rec_waregrp.waregrp_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_sqlerrd = sqlca.sqlerrd[3] 
		END IF 
	COMMIT WORK 
	CLOSE WINDOW i650 

	RETURN l_sqlerrd 
END FUNCTION 

