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
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EZ_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EZI_GLOBALS.4gl"
############################################################
# FUNCTION EZI_main()
#
# EZI - Order Load Parameters
############################################################
FUNCTION EZI_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EZI") -- albo 

	OPEN WINDOW E448 with FORM "E448" 
	 CALL windecoration_e("E448") -- albo kd-755 

--	WHILE select_ldparms() 
	CALL scan_ldparms() 
--	END WHILE 
	
	CLOSE WINDOW E448
	 
END FUNCTION 
############################################################
# END FUNCTION EZI_main()
############################################################


############################################################
# FUNCTION select_ldparms(p_filter)
#
#
############################################################
FUNCTION select_ldparms(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_arr_rec_loadparms DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
--	DEFINE l_scroll_flag char(1) 
--	DEFINE l_curr SMALLINT 
--	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			load_ind, 
			desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EZI","construct-load_ind-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = "1=1" 
		END IF

	ELSE
		LET l_where_text = "1=1"
	END IF
	 
	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM loadparms ", 
		"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
		"AND module_code = 'EO' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY loadparms.load_ind" 
	PREPARE s_loadparms FROM l_query_text 
	DECLARE c_loadparms cursor FOR s_loadparms 

	LET l_idx = 0 
	FOREACH c_loadparms INTO l_rec_loadparms.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
		LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		 
	END FOREACH 
	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected.

	RETURN l_arr_rec_loadparms 
END FUNCTION 
############################################################
# END FUNCTION select_ldparms(p_filter)
############################################################


############################################################
# FUNCTION scan_ldparms()
#
#
############################################################
FUNCTION scan_ldparms() 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_arr_rec_loadparms DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 	
	DEFINE l_del_cnt SMALLINT
	DEFINE l_rowid SMALLINT
	
--	IF l_idx = 0 THEN 
--		LET l_idx = 1 
--		INITIALIZE l_arr_rec_loadparms[l_idx].* TO NULL 
--	END IF 

	CALL select_ldparms(FALSE) RETURNING l_arr_rec_loadparms

	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
--	CALL set_count(l_idx)
 
	MESSAGE kandoomsg2("U",1003,"") #1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_loadparms WITHOUT DEFAULTS FROM sr_loadparms.* ATTRIBUTE(UNBUFFERED,INSERT ROW = FALSE,AUTO APPEND = FALSE,DELETE ROW = FALSE) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EZI","input-l_arr_rec_loadparms-1") -- albo kd-502 
 			CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_loadparms.getSize()) CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_loadparms.getSize()) CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_loadparms.getSize())
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_loadparms.clear()
			CALL select_ldparms(TRUE) RETURNING l_arr_rec_loadparms		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E448") 
			CALL l_arr_rec_loadparms.clear()
			CALL select_ldparms(FALSE) RETURNING l_arr_rec_loadparms		

		BEFORE ROW
			LET l_idx = arr_curr()
			
		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
--			LET scrn = scr_line() 
			LET l_scroll_flag = l_arr_rec_loadparms[l_idx].scroll_flag 
--			DISPLAY l_arr_rec_loadparms[l_idx].*	TO sr_loadparms[scrn].* 

		ON ACTION ("EDIT","DOUBLECLICK")
		--BEFORE FIELD load_ind 
			IF l_arr_rec_loadparms[l_idx].load_ind IS NOT NULL THEN 
				LET l_rec_loadparms.load_ind = l_arr_rec_loadparms[l_idx].load_ind 
				LET l_rec_loadparms.desc_text = l_arr_rec_loadparms[l_idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				
				IF edit_loadparms(l_rec_loadparms.load_ind,"U") THEN 
					SELECT * INTO l_rec_loadparms.* FROM loadparms 
					WHERE load_ind = l_rec_loadparms.load_ind 
					AND module_code = 'EO' 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			END IF 
			
			NEXT FIELD scroll_flag 
			
		BEFORE INSERT
			IF l_arr_rec_loadparms[l_idx].load_ind IS NULL THEN
			--IF l_idx < 1 THEN  --array will be auto init with first row 
			--IF l_arr_rec_loadparms.getSize() = 0 THEN
			--IF arr_curr() < arr_count() THEN 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				LET l_rowid = edit_loadparms("",MODE_CLASSIC1_ADD) 
				IF l_rowid = 0 THEN 
					FOR l_idx = l_curr TO l_cnt 
						LET l_arr_rec_loadparms[l_idx].* = l_arr_rec_loadparms[l_idx+1].* 
--						IF scrn <= 10 THEN 
--							DISPLAY l_arr_rec_loadparms[l_idx].* TO sr_loadparms[scrn].* 
--
--							LET scrn = scrn + 1 
--						END IF 
					END FOR 
					INITIALIZE l_arr_rec_loadparms[l_idx].* TO NULL 
				ELSE 
					SELECT * INTO l_rec_loadparms.* FROM loadparms 
					WHERE rowid = l_rowid 
					LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			ELSE 
				IF l_idx > 1 THEN 
					ERROR kandoomsg2("U",9001,"") 		#9001 There are no more rows....
				END IF 
			END IF
			 
		ON ACTION "DELETE" --ON KEY (f2)
			IF l_idx > 0 THEN
				DELETE FROM loadparms 
				WHERE load_ind = l_arr_rec_loadparms[l_idx].load_ind 
				AND module_code = 'EO' 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code
			END IF 

{
			IF l_arr_rec_loadparms[l_idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_loadparms[l_idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_loadparms[l_idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
	}		
--		AFTER ROW 
--			DISPLAY l_arr_rec_loadparms[l_idx].* TO sr_loadparms[scrn].* 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
	END IF 
{	ELSE 
		IF l_del_cnt > 0 THEN 			
			IF kandoomsg2("U",8000,l_del_cnt) = "Y" THEN #8014 Confirm TO Delete ",l_del_cnt," Load Indicator(s)? (Y/N)"
				FOR l_idx = 1 TO l_arr_rec_loadparms.getSize() --arr_count() 
					IF l_arr_rec_loadparms[l_idx].scroll_flag = "*" THEN 
						DELETE FROM loadparms 
						WHERE load_ind = l_arr_rec_loadparms[l_idx].load_ind 
						AND module_code = 'EO' 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF
} 
END FUNCTION 
############################################################
# END FUNCTION scan_ldparms()
############################################################


############################################################
# FUNCTION edit_loadparms(p_load_ind,p_mode)
#
#
############################################################
FUNCTION edit_loadparms(p_load_ind,p_mode) 
	DEFINE p_load_ind LIKE loadparms.load_ind 
	DEFINE p_mode char(1) 

	DEFINE l_rec_s_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 

	OPEN WINDOW E449 with FORM "E449" 
	 CALL windecoration_e("E449") -- albo kd-755 

	IF p_mode = MODE_CLASSIC1_UPDATE THEN {update} 
		SELECT * INTO l_rec_loadparms.* FROM loadparms 
		WHERE load_ind = p_load_ind 
		AND module_code = 'EO' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DISPLAY BY NAME 
			l_rec_loadparms.format_ind, 
			l_rec_loadparms.load_num, 
			l_rec_loadparms.load_date, 
			l_rec_loadparms.seq_num 

	ELSE 
		INITIALIZE l_rec_loadparms.* TO NULL 
		LET l_rec_loadparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_loadparms.seq_num = 0 
		LET l_rec_loadparms.format_ind = "1" 
		LET l_rec_loadparms.entry1_flag = "N" 
		LET l_rec_loadparms.entry2_flag = "N" 
		LET l_rec_loadparms.entry3_flag = "N" 
		LET l_rec_loadparms.module_code = "EO"
		 
		DISPLAY BY NAME l_rec_loadparms.format_ind 

	END IF 
	LET l_rec_s_loadparms.* = l_rec_loadparms.* 
	MESSAGE kandoomsg2("U",1020,"Load")	#1052" Enter Load Details - Esc TO continue

	DISPLAY BY NAME l_rec_loadparms.load_ind 

	INPUT BY NAME 
		l_rec_loadparms.load_ind, 
		l_rec_loadparms.desc_text, 
		l_rec_loadparms.file_text, 
		l_rec_loadparms.path_text, 
		l_rec_loadparms.format_ind, 
		l_rec_loadparms.prmpt1_text, 
		l_rec_loadparms.ref1_text, 
		l_rec_loadparms.entry1_flag, 
		l_rec_loadparms.prmpt2_text, 
		l_rec_loadparms.ref2_text, 
		l_rec_loadparms.entry2_flag, 
		l_rec_loadparms.prmpt3_text, 
		l_rec_loadparms.ref3_text, 
		l_rec_loadparms.entry3_flag WITHOUT DEFAULTS 

		BEFORE FIELD load_ind 
			IF p_mode = MODE_CLASSIC1_UPDATE THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD load_ind 
			IF l_rec_loadparms.load_ind IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered.
				NEXT FIELD load_ind 
			END IF 
			SELECT unique 1 FROM loadparms 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND load_ind = l_rec_loadparms.load_ind 
			IF status != NOTFOUND THEN 
				ERROR kandoomsg2("U",9104,"") #9104 RECORD already exists
				NEXT FIELD load_ind 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_loadparms.desc_text IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") #9102 Value must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_loadparms.format_ind IS NULL THEN 
				ERROR kandoomsg2("E",9114,"") #9114  Description must be entered
				NEXT FIELD format_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_loadparms.load_ind IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 		#9102 Value must be entered
					NEXT FIELD load_ind 
				END IF 
				IF l_rec_loadparms.desc_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
					NEXT FIELD desc_text 
				END IF 
				IF l_rec_loadparms.format_ind IS NULL THEN 
					ERROR kandoomsg2("E",9114,"") 			#9114  Description must be entered
					NEXT FIELD format_ind 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		CLOSE WINDOW E449 
		RETURN FALSE 
	END IF 
	
	CASE p_mode 

		WHEN MODE_CLASSIC1_UPDATE 
			UPDATE loadparms 
			SET * = l_rec_loadparms.* 
			WHERE load_ind = p_load_ind 
			AND module_code = 'EO' 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CLOSE WINDOW E449 
			RETURN sqlca.sqlerrd[3] 
			
		WHEN MODE_CLASSIC1_ADD 
			INSERT INTO loadparms VALUES (l_rec_loadparms.*) 
			CLOSE WINDOW E449 
			RETURN sqlca.sqlerrd[6] 

		OTHERWISE 
			ERROR "Logic ERROR " 
			CLOSE WINDOW E449 
			RETURN FALSE 
	END CASE
	 
END FUNCTION
############################################################
# END FUNCTION edit_loadparms(p_load_ind,p_mode)
############################################################