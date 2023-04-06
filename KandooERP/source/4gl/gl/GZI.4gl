
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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_temp_text VARCHAR(200) 
END GLOBALS
############################################################
# MAIN
#
# GZI - Multi-Ledger Relationships
# Note: Requires Ledger Segment Not Set Up
# Run Prior: GZ3 - GL Flexible Structure Code
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GZI") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL db_structure_get_rec_with_type("L") RETURNING glob_rec_structure.* 
	#   SELECT * INTO glob_rec_structure.* FROM structure
	#     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#       AND type_ind = "L"

	IF db_structure_get_type_count("L") < 1 THEN 
		CALL fgl_winmessage("Ledger Segment Not Set Up","Ledger Segment Not Set Up\nRun GZ3 - GL Flexible Structure Code\nEXIT PROGRAM","error") 
		EXIT PROGRAM 
	END IF 



	OPEN WINDOW g450 with FORM "G450" 
	CALL windecoration_g("G450") 

	#   SELECT * INTO glob_rec_structure.* FROM structure
	#     WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#       AND type_ind = "L"
	#   IF STATUS = NOTFOUND THEN
	#      LET l_msgresp = kandoomsg("G",5019,"")
	#      #5019 " Ledger Segment Not Set Up
	#			CALL fgl_winmessage("Ledger Segment Not Set Up","Ledger Segment Not Set Up\nRun GZ3 - GL Flexible Structure Code\nEXIT PROGRAM","error")
	#   ELSE
	WHILE select_ledger() 
		CALL scan_ledger() 
	END WHILE 
	#   END IF
	CLOSE WINDOW g450 
END MAIN 



############################################################
# FUNCTION select_ledger()
#
#
############################################################
FUNCTION select_ledger() 
	DEFINE l_query_text CHAR(300) 
	DEFINE l_where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("G",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME l_where_text ON flex1_code, 
	acct1_code, 
	flex2_code, 
	acct2_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","GZI","multLedgRelQuery") 

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
		LET l_query_text = "SELECT * FROM ledgerreln ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 2,4,3" 
		PREPARE s_ledgerreln FROM l_query_text 
		DECLARE c_ledgerreln CURSOR FOR s_ledgerreln 
		RETURN true 
	END IF 
END FUNCTION 



############################################################
# FUNCTION scan_ledger()
#
#
############################################################
FUNCTION scan_ledger() 
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_arr_rec_ledgerreln DYNAMIC ARRAY OF #array[50] 
	RECORD 
		scroll_flag CHAR(1), 
		flex1_code LIKE ledgerreln.flex1_code, 
		acct1_code LIKE ledgerreln.acct1_code, 
		flex2_code LIKE ledgerreln.flex2_code, 
		acct2_code LIKE ledgerreln.acct2_code 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE del_cnt SMALLINT 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_ledgerreln INTO l_rec_ledgerreln.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_ledgerreln[l_idx].flex1_code = l_rec_ledgerreln.flex1_code 
		LET l_arr_rec_ledgerreln[l_idx].acct1_code = l_rec_ledgerreln.acct1_code 
		LET l_arr_rec_ledgerreln[l_idx].flex2_code = l_rec_ledgerreln.flex2_code 
		LET l_arr_rec_ledgerreln[l_idx].acct2_code = l_rec_ledgerreln.acct2_code 
		IF l_idx = 50 THEN 
			LET l_msgresp = kandoomsg("G",9109,l_idx) 
			#9109 " First ??? Ledgers Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("G",9110,"") 
		#9110" No ledgers satisfied selection criteria "
		LET l_idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_ledgerreln WITHOUT DEFAULTS FROM sr_ledgerreln.* attribute(UNBUFFERED, append ROW = false, auto append = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZI","multLedgRelList") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#ON ACTION/KEY
		ON ACTION "EDIT" 
			IF l_arr_rec_ledgerreln[l_idx].flex1_code IS NOT NULL THEN 
				LET l_rec_ledgerreln.flex1_code = l_arr_rec_ledgerreln[l_idx].flex1_code 
				LET l_rec_ledgerreln.acct1_code = l_arr_rec_ledgerreln[l_idx].acct1_code 
				LET l_rec_ledgerreln.flex2_code = l_arr_rec_ledgerreln[l_idx].flex2_code 
				LET l_rec_ledgerreln.acct2_code = l_arr_rec_ledgerreln[l_idx].acct2_code 
				CALL edit_ledger(l_rec_ledgerreln.*) 
				RETURNING l_rec_ledgerreln.* 
				LET l_arr_rec_ledgerreln[l_idx].flex1_code = l_rec_ledgerreln.flex1_code 
				LET l_arr_rec_ledgerreln[l_idx].acct1_code = l_rec_ledgerreln.acct1_code 
				LET l_arr_rec_ledgerreln[l_idx].flex2_code = l_rec_ledgerreln.flex2_code 
				LET l_arr_rec_ledgerreln[l_idx].acct2_code = l_rec_ledgerreln.acct2_code 
			END IF 


		ON KEY (F2) #delete marker 
			IF l_arr_rec_ledgerreln[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_ledgerreln[l_idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET l_arr_rec_ledgerreln[l_idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

			#Field Logic
		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_scroll_flag = l_arr_rec_ledgerreln[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_ledgerreln[l_idx].*
			#     TO sr_ledgerreln[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_ledgerreln[l_idx].scroll_flag = l_scroll_flag 
			#DISPLAY l_arr_rec_ledgerreln[l_idx].scroll_flag
			#     TO sr_ledgerreln[scrn].scroll_flag

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("G",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

		BEFORE FIELD flex1_code 
			IF l_arr_rec_ledgerreln[l_idx].flex1_code IS NOT NULL THEN 
				LET l_rec_ledgerreln.flex1_code = l_arr_rec_ledgerreln[l_idx].flex1_code 
				LET l_rec_ledgerreln.acct1_code = l_arr_rec_ledgerreln[l_idx].acct1_code 
				LET l_rec_ledgerreln.flex2_code = l_arr_rec_ledgerreln[l_idx].flex2_code 
				LET l_rec_ledgerreln.acct2_code = l_arr_rec_ledgerreln[l_idx].acct2_code 
				CALL edit_ledger(l_rec_ledgerreln.*) 
				RETURNING l_rec_ledgerreln.* 
				LET l_arr_rec_ledgerreln[l_idx].flex1_code = l_rec_ledgerreln.flex1_code 
				LET l_arr_rec_ledgerreln[l_idx].acct1_code = l_rec_ledgerreln.acct1_code 
				LET l_arr_rec_ledgerreln[l_idx].flex2_code = l_rec_ledgerreln.flex2_code 
				LET l_arr_rec_ledgerreln[l_idx].acct2_code = l_rec_ledgerreln.acct2_code 
			END IF 
			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			LET l_idx = arr_curr() 
			IF arr_curr() <= arr_count() THEN 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				CALL add_ledger() 
				RETURNING l_rec_ledgerreln.* 
				IF l_rec_ledgerreln.flex1_code IS NULL THEN 
					FOR l_idx = l_curr TO l_cnt 
						LET l_arr_rec_ledgerreln[l_idx].* = l_arr_rec_ledgerreln[l_idx+1].* 
						#IF scrn <= 14 THEN
						#   DISPLAY l_arr_rec_ledgerreln[l_idx].*
						#        TO sr_ledgerreln[scrn].*
						#
						#   LET scrn = scrn + 1
						#END IF
					END FOR 
					INITIALIZE l_arr_rec_ledgerreln[l_idx].* TO NULL 
				ELSE 
					LET l_arr_rec_ledgerreln[l_idx].flex1_code = l_rec_ledgerreln.flex1_code 
					LET l_arr_rec_ledgerreln[l_idx].acct1_code = l_rec_ledgerreln.acct1_code 
					LET l_arr_rec_ledgerreln[l_idx].flex2_code = l_rec_ledgerreln.flex2_code 
					LET l_arr_rec_ledgerreln[l_idx].acct2_code = l_rec_ledgerreln.acct2_code 
				END IF 
			ELSE 
				IF l_idx > 1 THEN 
					LET l_msgresp = kandoomsg("G",9001,"") 
					#9001There are no more rows in the direction you are going
				END IF 
			END IF 

			#AFTER ROW
			#   DISPLAY l_arr_rec_ledgerreln[l_idx].*
			#        TO sr_ledgerreln[scrn].*


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("G",8011,del_cnt) 
			#8011 Confirm TO Delete ",del_cnt," Ledger Relationship(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_ledgerreln[l_idx].scroll_flag = "*" THEN 
						DELETE FROM ledgerreln 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND flex1_code = l_arr_rec_ledgerreln[l_idx].flex1_code 
						AND flex2_code = l_arr_rec_ledgerreln[l_idx].flex2_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 



############################################################
# FUNCTION edit_ledger(p_rec_ledgerreln)
#
#
############################################################
FUNCTION edit_ledger(p_rec_ledgerreln) 
	DEFINE p_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_s_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_acct1_desc LIKE coa.desc_text 
	DEFINE l_acct2_desc LIKE coa.desc_text 

	DEFINE l_flex1_desc LIKE validflex.desc_text 
	DEFINE l_flex2_desc LIKE validflex.desc_text 

	DEFINE i SMALLINT 
	DEFINE l_start_num SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g451 with FORM "G451" 
	CALL windecoration_g("G451") 

	LET l_msgresp = kandoomsg("G",1030,"") 
	#1030 " Enter Ledger Relationship - ESC TO Continue"
	LET l_rec_s_ledgerreln.* = p_rec_ledgerreln.* 
	SELECT desc_text INTO l_acct1_desc FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_rec_ledgerreln.acct1_code 
	SELECT desc_text INTO l_acct2_desc FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = p_rec_ledgerreln.acct2_code 
	SELECT desc_text INTO l_flex1_desc FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = glob_rec_structure.start_num 
	AND flex_code = p_rec_ledgerreln.flex1_code 
	SELECT desc_text INTO l_flex2_desc FROM validflex 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND start_num = glob_rec_structure.start_num 
	AND flex_code = p_rec_ledgerreln.flex2_code 

	DISPLAY 
	p_rec_ledgerreln.flex1_code, 
	l_flex1_desc, 
	p_rec_ledgerreln.acct1_code, 
	l_acct1_desc, 
	p_rec_ledgerreln.flex2_code, 
	l_flex2_desc, 
	p_rec_ledgerreln.acct2_code, 
	l_acct2_desc 
	TO 
	p_rec_ledgerreln.flex1_code, 
	flex1_desc, 
	p_rec_ledgerreln.acct1_code, 
	acct1_desc, 
	p_rec_ledgerreln.flex2_code, 
	flex2_desc, 
	p_rec_ledgerreln.acct2_code, 
	acct2_desc 


	INPUT BY NAME p_rec_ledgerreln.acct1_code, 
	p_rec_ledgerreln.acct2_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZI","multLedgRel") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (acct1_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_ledgerreln.acct1_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME p_rec_ledgerreln.acct1_code 

			NEXT FIELD acct1_code 

		ON ACTION "LOOKUP" infield (acct2_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET p_rec_ledgerreln.acct2_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME p_rec_ledgerreln.acct2_code 

			NEXT FIELD acct2_code 


		AFTER FIELD acct1_code 
			IF p_rec_ledgerreln.acct1_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9113,"") 
				#9113 Account code must NOT be NULL - Try Window
				NEXT FIELD acct1_code 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_ledgerreln.acct1_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist - Try Window
				NEXT FIELD acct1_code 
			END IF 
			SELECT unique 1 FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_coa.acct_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9111,"") 
				#9111 Bank Account codes must NOT be used
				NEXT FIELD acct1_code 
			END IF 
			LET l_start_num = glob_rec_structure.start_num 
			LET l_length = glob_rec_structure.start_num 
			+ glob_rec_structure.length_num 
			- 1 
			IF p_rec_ledgerreln.acct1_code[l_start_num,l_length] != 
			p_rec_ledgerreln.flex1_code THEN 
				LET l_msgresp=kandoomsg("G",9117,"") 
				#9117 Invalid Ledger in Account - Try Window
				NEXT FIELD acct1_code 
			END IF 
			IF l_rec_coa.type_ind = "A" 
			OR l_rec_coa.type_ind = "L" THEN 
				LET l_acct1_desc = l_rec_coa.desc_text 
				DISPLAY l_acct1_desc TO acct1_desc 
			ELSE 
				LET l_msgresp=kandoomsg("G",9142,"") 
				#9142 Account type must be an (A)sset OR (L)iablity - Try Window
				NEXT FIELD acct1_code 
			END IF 

		AFTER FIELD acct2_code 
			IF p_rec_ledgerreln.acct2_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9113,"") 
				#9113 Account code must NOT be NULL - Try Window
				NEXT FIELD acct2_code 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = p_rec_ledgerreln.acct2_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist - Try Window
				NEXT FIELD acct2_code 
			END IF 
			SELECT unique 1 FROM bank 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_coa.acct_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9111,"") 
				#9111 Bank Account codes must NOT be used
				NEXT FIELD acct2_code 
			END IF 
			IF p_rec_ledgerreln.acct2_code[l_start_num,l_length] != 
			p_rec_ledgerreln.flex2_code THEN 
				LET l_msgresp=kandoomsg("G",9117,"") 
				#9117 Invalid Ledger in Account - Try Window
				NEXT FIELD acct2_code 
			END IF 
			IF l_rec_coa.type_ind = "A" 
			OR l_rec_coa.type_ind = "L" THEN 
				LET l_acct2_desc = l_rec_coa.desc_text 
				DISPLAY l_acct2_desc TO acct2_desc 
			ELSE 
				LET l_msgresp=kandoomsg("G",9142,"") 
				#9142 Account type must be an (A)sset OR (L)iablity - Try Window
				NEXT FIELD acct2_code 
			END IF 

		AFTER INPUT 

			IF NOT (int_flag OR quit_flag) THEN 
				IF p_rec_ledgerreln.acct1_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct1_code 
				END IF 
				IF p_rec_ledgerreln.acct2_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct2_code 
				END IF 
			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW g451 
		RETURN l_rec_s_ledgerreln.* 
	ELSE 
		UPDATE ledgerreln 
		SET ledgerreln.* = p_rec_ledgerreln.* 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND flex1_code = p_rec_ledgerreln.flex1_code 
		AND flex2_code = p_rec_ledgerreln.flex2_code 
		CLOSE WINDOW g451 
		RETURN p_rec_ledgerreln.* 
	END IF 

END FUNCTION 


############################################################
# FUNCTION add_ledger()
#
#
############################################################
FUNCTION add_ledger() 
	DEFINE l_rec_ledgerreln RECORD LIKE ledgerreln.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_acct1_desc LIKE coa.desc_text 
	DEFINE l_acct2_desc LIKE coa.desc_text 

	DEFINE l_flex1_desc LIKE validflex.desc_text 
	DEFINE l_flex2_desc LIKE validflex.desc_text 

	DEFINE i SMALLINT 
	DEFINE l_start_num SMALLINT 
	DEFINE l_length SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g451 with FORM "G451" 
	CALL windecoration_g("G451") 

	LET l_msgresp = kandoomsg("G",1030,"") 
	#1030 " Enter Ledger Relationship - ESC TO Continue"
	INITIALIZE l_rec_ledgerreln.* TO NULL 
	LET l_rec_ledgerreln.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT BY NAME l_rec_ledgerreln.flex1_code, 
	l_rec_ledgerreln.acct1_code, 
	l_rec_ledgerreln.flex2_code, 
	l_rec_ledgerreln.acct2_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZI","multLedgRelEdit") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (acct1_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_ledgerreln.acct1_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME l_rec_ledgerreln.acct1_code 

			NEXT FIELD acct1_code 

		ON ACTION "LOOKUP" infield (acct2_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_ledgerreln.acct2_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME l_rec_ledgerreln.acct2_code 

			NEXT FIELD acct2_code 

		ON ACTION "LOOKUP" infield (flex1_code) 
			LET glob_temp_text = show_flex(glob_rec_kandoouser.cmpy_code, 
			glob_rec_structure.start_num) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_ledgerreln.flex1_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME l_rec_ledgerreln.flex1_code 
			NEXT FIELD flex1_code 

		ON ACTION "LOOKUP" infield (flex2_code) 
			LET glob_temp_text = show_flex(glob_rec_kandoouser.cmpy_code, 
			glob_rec_structure.start_num) 
			IF glob_temp_text IS NOT NULL THEN 
				LET l_rec_ledgerreln.flex2_code = glob_temp_text 
			END IF 
			DISPLAY BY NAME l_rec_ledgerreln.flex2_code 
			NEXT FIELD flex2_code 

		AFTER FIELD flex1_code 
			IF l_rec_ledgerreln.flex1_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9114,"") 
				#9114 Ledger code must NOT be NULL - Try Window
				NEXT FIELD flex1_code 
			END IF 
			SELECT * INTO l_rec_validflex.* FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = glob_rec_structure.start_num 
			AND flex_code = l_rec_ledgerreln.flex1_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9115,"") 
				#9115 Ledger code does NOT exist - Try Window
				NEXT FIELD flex1_code 
			ELSE 
				LET l_flex1_desc = l_rec_validflex.desc_text 
				DISPLAY l_flex1_desc TO flex1_desc 
			END IF 

		AFTER FIELD acct1_code 
			IF l_rec_ledgerreln.acct1_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9113,"") 
				#9113 Account code must NOT be NULL - Try Window
				NEXT FIELD acct1_code 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_ledgerreln.acct1_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist - Try Window
				NEXT FIELD acct1_code 
			END IF 
			LET l_start_num = glob_rec_structure.start_num 
			LET l_length = glob_rec_structure.start_num 
			+ glob_rec_structure.length_num 
			- 1 
			IF l_rec_ledgerreln.acct1_code[l_start_num,l_length] != 
			l_rec_ledgerreln.flex1_code THEN 
				LET l_msgresp=kandoomsg("G",9117,"") 
				#9117 Account code does NOT exist FOR this Ledger - Try Window
				NEXT FIELD acct1_code 
			END IF 
			IF l_rec_coa.type_ind = "A" 
			OR l_rec_coa.type_ind = "L" THEN 
				LET l_acct1_desc = l_rec_coa.desc_text 
				DISPLAY l_acct1_desc TO acct1_desc 
			ELSE 
				LET l_msgresp=kandoomsg("G",9142,"") 
				#9142 Account type must be an (A)sset OR (L)iablity - Try Window
				NEXT FIELD acct1_code 
			END IF 

		AFTER FIELD flex2_code 
			IF l_rec_ledgerreln.flex2_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9114,"") 
				#9114 Ledger code must NOT be NULL - Try Window
				NEXT FIELD flex2_code 
			END IF 
			SELECT * INTO l_rec_validflex.* FROM validflex 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND start_num = glob_rec_structure.start_num 
			AND flex_code = l_rec_ledgerreln.flex2_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9115,"") 
				#9115 Ledger code does NOT exist - Try Window
				NEXT FIELD flex2_code 
			END IF 
			SELECT unique 1 FROM ledgerreln 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex1_code = l_rec_ledgerreln.flex1_code 
			AND flex2_code = l_rec_ledgerreln.flex2_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9118,"") 
				#9118 Ledger Relationship already exists  - Try Window
				NEXT FIELD flex2_code 
			END IF 
			SELECT unique 1 FROM ledgerreln 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND flex1_code = l_rec_ledgerreln.flex2_code 
			AND flex2_code = l_rec_ledgerreln.flex1_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9118,"") 
				#9118 Ledger Relationship already exists - Try Window
				NEXT FIELD flex2_code 
			END IF 
			IF l_rec_ledgerreln.flex2_code = l_rec_ledgerreln.flex1_code THEN 
				LET l_msgresp=kandoomsg("G",9128,"") 
				#9128 Relationship Ledger must NOT equal the first
				NEXT FIELD flex2_code 
			ELSE 
				LET l_flex2_desc = l_rec_validflex.desc_text 
				DISPLAY l_flex2_desc TO flex2_desc 
			END IF 

		AFTER FIELD acct2_code 
			IF l_rec_ledgerreln.acct2_code IS NULL THEN 
				LET l_msgresp=kandoomsg("G",9113,"") 
				#9113 Account code must NOT be NULL - Try Window
				NEXT FIELD acct2_code 
			END IF 
			SELECT * INTO l_rec_coa.* FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = l_rec_ledgerreln.acct2_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist - Try Window
				NEXT FIELD acct2_code 
			END IF 
			IF l_rec_ledgerreln.acct2_code[l_start_num,l_length] != 
			l_rec_ledgerreln.flex2_code THEN 
				LET l_msgresp=kandoomsg("G",9117,"") 
				#9117 Account code does NOT exist FOR this Ledger - Try Window
				NEXT FIELD acct2_code 
			END IF 
			IF l_rec_coa.type_ind = "A" 
			OR l_rec_coa.type_ind = "L" THEN 
				LET l_acct2_desc = l_rec_coa.desc_text 
				DISPLAY l_acct2_desc TO acct2_desc 
			ELSE 
				LET l_msgresp=kandoomsg("G",9142,"") 
				#9142 Account type must be an (A)sset OR (L)iablity - Try Window
				NEXT FIELD acct2_code 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_ledgerreln.acct1_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct1_code 
				END IF 
				IF l_rec_ledgerreln.acct2_code IS NULL THEN 
					LET l_msgresp=kandoomsg("G",9113,"") 
					#9113 Account code must NOT be NULL - Try Window
					NEXT FIELD acct2_code 
				END IF 
			END IF 
			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		INITIALIZE l_rec_ledgerreln.* TO NULL 
	ELSE 
		INSERT INTO ledgerreln VALUES (l_rec_ledgerreln.*) 
	END IF 

	CLOSE WINDOW g451 

	RETURN l_rec_ledgerreln.* 
END FUNCTION 
