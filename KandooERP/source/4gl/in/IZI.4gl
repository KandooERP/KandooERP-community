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
GLOBALS "I_IN_GLOBALS.4gl" 

#   IZI - IN Load Parameters

GLOBALS 
	DEFINE 
	temp_text CHAR(20) 
END GLOBALS 

####################################################################
# MAIN
####################################################################
MAIN 
	#Initial UI Init
	CALL setModuleId("IZI") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_i_in() --init i/in warehouse inventory management module 

	OPEN WINDOW i673 with FORM "I673" 
	 CALL windecoration_i("I673") -- albo kd-758 

	WHILE select_ldparms() 
		CALL scan_ldparms() 
	END WHILE 
	CLOSE WINDOW i673 
END MAIN 


FUNCTION select_ldparms() 
	DEFINE query_text CHAR(300) 
	DEFINE where_text CHAR(200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("A",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME where_text ON load_ind, 
	desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","IZI","construct-load_ind-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("A",1002,"") 
		#1002 " Searching database - please wait"
		LET query_text = "SELECT * FROM loadparms ", 
		"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
		"AND module_code = 'IN' ", 
		"AND ", where_text clipped," ", 
		"ORDER BY loadparms.load_ind" 
		PREPARE s_loadparms FROM query_text 
		DECLARE c_loadparms CURSOR FOR s_loadparms 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION scan_ldparms() 
	DEFINE pr_loadparms RECORD LIKE loadparms.* 
	DEFINE pa_loadparms array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
	DEFINE pr_scroll_flag CHAR(1) 
	DEFINE pr_curr,pr_cnt,idx,scrn,del_cnt,pr_rowid SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET idx = 0 
	FOREACH c_loadparms INTO pr_loadparms.* 
		LET idx = idx + 1 
		LET pa_loadparms[idx].load_ind = pr_loadparms.load_ind 
		LET pa_loadparms[idx].desc_text = pr_loadparms.desc_text 
		IF idx = 100 THEN 
			LET l_msgresp = kandoomsg("A",9211,idx) 
			#9211 " First ??? Load Indicator Selected Only"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("A",9210,"") 
		#9210 No Load Indicators satisfied selection criteria
		LET idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("A",1003,"") 
	#1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY pa_loadparms WITHOUT DEFAULTS FROM sr_loadparms.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZI","input-arr-pa_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET pr_scroll_flag = pa_loadparms[idx].scroll_flag 
			DISPLAY pa_loadparms[idx].* 
			TO sr_loadparms[scrn].* 

		AFTER FIELD scroll_flag 
			LET pa_loadparms[idx].scroll_flag = pr_scroll_flag 
			DISPLAY pa_loadparms[idx].scroll_flag 
			TO sr_loadparms[scrn].scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF pa_loadparms[idx+1].load_ind IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("A",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
		BEFORE FIELD load_ind 
			IF pa_loadparms[idx].load_ind IS NOT NULL THEN 
				LET pr_loadparms.load_ind = pa_loadparms[idx].load_ind 
				LET pr_loadparms.desc_text = pa_loadparms[idx].desc_text 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				IF edit_loadparms(pr_loadparms.load_ind,"U") THEN 
					SELECT * 
					INTO pr_loadparms.* 
					FROM loadparms 
					WHERE load_ind = pr_loadparms.load_ind 
					AND module_code = 'IN' 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET pa_loadparms[idx].load_ind = pr_loadparms.load_ind 
					LET pa_loadparms[idx].desc_text = pr_loadparms.desc_text 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET pr_curr = arr_curr() 
				LET pr_cnt = arr_count() 
				LET pr_rowid = edit_loadparms("","A") 
				IF pr_rowid = 0 THEN 
					FOR idx = pr_curr TO pr_cnt 
						LET pa_loadparms[idx].* = pa_loadparms[idx+1].* 
						IF scrn <= 10 THEN 
							DISPLAY pa_loadparms[idx].* TO sr_loadparms[scrn].* 

							LET scrn = scrn + 1 
						END IF 
					END FOR 
					INITIALIZE pa_loadparms[idx].* TO NULL 
				ELSE 
					SELECT * 
					INTO pr_loadparms.* 
					FROM loadparms 
					WHERE rowid = pr_rowid 
					LET pa_loadparms[idx].load_ind = pr_loadparms.load_ind 
					LET pa_loadparms[idx].desc_text = pr_loadparms.desc_text 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					LET l_msgresp = kandoomsg("A",9001,"") 
					#9001 There are no more rows....
				END IF 
			END IF 
		ON KEY (F2) 
			IF pa_loadparms[idx].scroll_flag IS NULL THEN 
				LET pa_loadparms[idx].scroll_flag = "*" 
				LET del_cnt = del_cnt + 1 
			ELSE 
				LET pa_loadparms[idx].scroll_flag = NULL 
				LET del_cnt = del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY pa_loadparms[idx].* 
			TO sr_loadparms[scrn].* 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("A",8014,del_cnt) 
			#8014 Confirm TO Delete ",del_cnt," Load Indicator(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF pa_loadparms[idx].scroll_flag = "*" THEN 
						DELETE FROM loadparms 
						WHERE load_ind = pa_loadparms[idx].load_ind 
						AND module_code = 'IN' 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 

FUNCTION edit_loadparms(pr_load_ind,pr_mode) 
	DEFINE ps_loadparms RECORD LIKE loadparms.* 
	DEFINE pr_loadparms RECORD LIKE loadparms.* 
	DEFINE pr_load_ind LIKE loadparms.load_ind 
	DEFINE pr_mode CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW i674 with FORM "I674" 
	 CALL windecoration_i("I674") -- albo kd-758 
	IF pr_mode = "U" THEN {update} 
		SELECT * 
		INTO pr_loadparms.* 
		FROM loadparms 
		WHERE load_ind = pr_load_ind 
		AND module_code = 'IN' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DISPLAY BY NAME pr_loadparms.load_num, 
		pr_loadparms.load_date, 
		pr_loadparms.seq_num 

	ELSE 
		INITIALIZE pr_loadparms.* TO NULL 
		LET pr_loadparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET pr_loadparms.seq_num = 0 
		LET pr_loadparms.entry1_flag = "N" 
		LET pr_loadparms.entry2_flag = "N" 
		LET pr_loadparms.entry3_flag = "N" 
		LET pr_loadparms.module_code = TRAN_TYPE_INVOICE_IN 
	END IF 
	LET ps_loadparms.* = pr_loadparms.* 
	LET l_msgresp = kandoomsg("U",1020,"IN Load Parameter") 
	#U1020" Enter IN Load Parameter Details - OK TO Continue
	DISPLAY BY NAME pr_loadparms.load_ind 

	INPUT BY NAME pr_loadparms.load_ind, 
	pr_loadparms.desc_text, 
	pr_loadparms.file_text, 
	pr_loadparms.path_text, 
	pr_loadparms.format_ind, 
	pr_loadparms.prmpt1_text, 
	pr_loadparms.ref1_text, 
	pr_loadparms.entry1_flag, 
	pr_loadparms.prmpt2_text, 
	pr_loadparms.ref2_text, 
	pr_loadparms.entry2_flag, 
	pr_loadparms.prmpt3_text, 
	pr_loadparms.ref3_text, 
	pr_loadparms.entry3_flag 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","IZI","input-pr_loadparms-1") -- albo kd-505 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD load_ind 
			IF pr_mode = "U" THEN 
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD load_ind 
			IF pr_loadparms.load_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9205,"") 
				#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT unique 1 FROM loadparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = TRAN_TYPE_INVOICE_IN 
				AND load_ind = pr_loadparms.load_ind 
				IF status = 0 THEN 
					LET l_msgresp = kandoomsg("A",9179,"") 
					#A9179 Load indicator already exists. ...
					NEXT FIELD load_ind 
				END IF 
			END IF 
		AFTER FIELD desc_text 
			IF pr_loadparms.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9208,"") 
				#9208  Description must be entered
				NEXT FIELD desc_text 
			END IF 
		AFTER FIELD format_ind 
			IF pr_loadparms.format_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("E",9114,"") 
				#9208  Description must be entered
				NEXT FIELD format_ind 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF pr_loadparms.load_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9208,"") 
					#9208 " Load Indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				IF pr_loadparms.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9212,"") 
					#9212 Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF pr_loadparms.format_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("E",9114,"") 
					#E9114 Format Indictaor must be entered.
					NEXT FIELD format_ind 
				END IF 
			END IF 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW i674 
		RETURN false 
	END IF 
	CASE pr_mode 
		WHEN "U" 
			UPDATE loadparms 
			SET * = pr_loadparms.* 
			WHERE load_ind = pr_load_ind 
			AND module_code = 'IN' 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CLOSE WINDOW i674 
			RETURN sqlca.sqlerrd[3] 
		WHEN "A" 
			INSERT INTO loadparms 
			VALUES (pr_loadparms.*) 
			CLOSE WINDOW i674 
			RETURN sqlca.sqlerrd[6] 
		OTHERWISE 
			ERROR "Logic ERROR " 
			CLOSE WINDOW i674 
			RETURN false 
	END CASE 
END FUNCTION 
