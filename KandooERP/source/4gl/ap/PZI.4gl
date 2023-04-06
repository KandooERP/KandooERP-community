#AP Load File Defaults P229
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:52	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
#   PZI - AP Load Parameters
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("PZI") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_p_ap() #init p/ap module  #PZI configurations is required for PZP

	OPEN WINDOW P229 with FORM "P229" 
	CALL windecoration_p("P229") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_loadparms(l_withquery) 
		LET l_withquery = scan_loadparms() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW P229 

END MAIN 



############################################################
# FUNCTION select_loadparms(p_withQuery)
#
#
############################################################
FUNCTION select_loadparms(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") #1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON load_ind, desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","PZI","construct-load-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM loadparms ", 
	"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
	"AND module_code = 'AP' ", 
	"AND ", l_where_text CLIPPED," ", 
	"ORDER BY loadparms.load_ind" 

	PREPARE s_loadparms FROM l_query_text 
	DECLARE c_loadparms CURSOR FOR s_loadparms 

	RETURN 1 
END FUNCTION 


############################################################
# FUNCTION scan_loadparms()
#
#
############################################################
FUNCTION scan_loadparms() 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_arr_rec_loadparms ARRAY[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx SMALLINT

	LET idx = 0 
	FOREACH c_loadparms INTO l_rec_loadparms.* 
		LET idx = idx + 1 
		LET l_arr_rec_loadparms[idx].load_ind = l_rec_loadparms.load_ind 
		LET l_arr_rec_loadparms[idx].desc_text = l_rec_loadparms.desc_text 
		IF idx = 100 THEN 
			MESSAGE kandoomsg2("U",1022,idx) #9211 " First ??? selected...
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF idx = 0 THEN 
		MESSAGE kandoomsg2("U",1021,"") #9210 No entries satisfied selection criteria
		LET idx = 1 
	END IF 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f36
	CALL set_count(idx) 
	MESSAGE kandoomsg2("U",1003,"") #1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_loadparms WITHOUT DEFAULTS FROM sr_loadparms.* ATTRIBUTE(UNBUFFERED, APPEND ROW =TRUE,INSERT ROW=FALSE,auto APPEND = TRUE)
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZI","inp-arr-loadparms-1") 

		BEFORE ROW 
			LET idx = arr_curr() 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "EDIT" 
			NEXT FIELD load_ind 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_loadparms[idx].scroll_flag 

		AFTER FIELD scroll_flag 
			LET l_arr_rec_loadparms[idx].scroll_flag = l_scroll_flag 

			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_rec_loadparms[idx+1].load_ind IS NULL 
				OR arr_curr() >= arr_count() THEN 
					MESSAGE kandoomsg2("A",9001,"") #9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 



		BEFORE FIELD load_ind 
			IF l_arr_rec_loadparms[idx].load_ind IS NOT NULL THEN 
				LET l_rec_loadparms.load_ind = l_arr_rec_loadparms[idx].load_ind 
				LET l_rec_loadparms.desc_text = l_arr_rec_loadparms[idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				IF edit_loadparms(l_rec_loadparms.load_ind,"U") THEN 
					SELECT * 
					INTO l_rec_loadparms.* 
					FROM loadparms 
					WHERE load_ind = l_rec_loadparms.load_ind 
					AND module_code = 'AP' 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_arr_rec_loadparms[idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			ELSE 
				MESSAGE "Record TO modify does NOT exist" 
			END IF 

			NEXT FIELD scroll_flag 

		BEFORE INSERT 
			IF arr_curr() < arr_count() THEN 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				LET l_rowid = edit_loadparms("","A") 
				IF l_rowid = 0 THEN 
					FOR idx = l_curr TO l_cnt 
						LET l_arr_rec_loadparms[idx].* = l_arr_rec_loadparms[idx+1].* 
					END FOR 
					INITIALIZE l_arr_rec_loadparms[idx].* TO NULL 
				ELSE 
					SELECT * 
					INTO l_rec_loadparms.* 
					FROM loadparms 
					WHERE rowid = l_rowid 
					LET l_arr_rec_loadparms[idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			ELSE 
				IF idx > 1 THEN 
					MESSAGE kandoomsg2("U",9001,"") #9001 There are no more rows....
				END IF 
			END IF 

		ON KEY (F2) #delete marker SET 
			IF l_arr_rec_loadparms[idx].scroll_flag IS NULL THEN 
				LET l_arr_rec_loadparms[idx].scroll_flag = "*" 
				LET l_del_cnt = l_del_cnt + 1 
			ELSE 
				LET l_arr_rec_loadparms[idx].scroll_flag = NULL 
				LET l_del_cnt = l_del_cnt - 1 
			END IF 
			NEXT FIELD scroll_flag 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET l_msgresp = kandoomsg("U",8020,l_del_cnt) 
			#8014 Confirm TO Delete ",l_del_cnt," record(s)? (Y/N)"
			IF l_msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_loadparms[idx].scroll_flag = "*" THEN 
						DELETE FROM loadparms 
						WHERE load_ind = l_arr_rec_loadparms[idx].load_ind 
						AND module_code = 'AP' 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 
	END IF 

END FUNCTION 


############################################################
# FUNCTION edit_loadparms(p_load_ind,p_mode)
#
#
############################################################
FUNCTION edit_loadparms(p_load_ind,p_mode) 
	DEFINE p_load_ind LIKE loadparms.load_ind 
	DEFINE p_mode CHAR(1) 
	DEFINE l_rec_s_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p230 with FORM "P230" 
	CALL windecoration_p("P230") 

	IF p_mode = "U" THEN {update} 
		SELECT * 
		INTO l_rec_loadparms.* 
		FROM loadparms 
		WHERE load_ind = p_load_ind 
		AND module_code = 'AP' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DISPLAY BY NAME l_rec_loadparms.load_num, 
		l_rec_loadparms.load_date, 
		l_rec_loadparms.seq_num 

	ELSE 
		INITIALIZE l_rec_loadparms.* TO NULL 
		LET l_rec_loadparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_loadparms.seq_num = 0 
		LET l_rec_loadparms.entry1_flag = "N" 
		LET l_rec_loadparms.entry2_flag = "N" 
		LET l_rec_loadparms.entry3_flag = "N" 
		LET l_rec_loadparms.module_code = "AP" 
	END IF 

	LET l_rec_s_loadparms.* = l_rec_loadparms.* 
	LET l_msgresp = kandoomsg("U",1020,"Load") 
	#1020" Enter VALUE Details - Esc TO continue
	DISPLAY BY NAME l_rec_loadparms.load_ind 

	INPUT BY NAME l_rec_loadparms.load_ind, 
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
	l_rec_loadparms.entry3_flag 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZI","inp-loadparms-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD load_ind 
			IF p_mode = "U" THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD load_ind 
			IF l_rec_loadparms.load_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9205,"") 
				#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			ELSE 
				SELECT unique 1 FROM loadparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = 'AP' 
				AND load_ind = l_rec_loadparms.load_ind 
				IF status <> NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9177,"") 
					#9177 Load Indicator already exists; Load...
					NEXT FIELD load_ind 
				END IF 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_loadparms.desc_text IS NULL THEN 
				LET l_msgresp = kandoomsg("A",9208,"") 
				#9208  Description must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD path_text 
			IF l_rec_loadparms.path_text IS NOT NULL THEN 
				IF NOT verify_path(l_rec_loadparms.path_text) THEN 
					LET l_msgresp = kandoomsg("U",9107,"") 
					#9107 " Unix file OR directory does NOT exist
					NEXT FIELD path_text 
				END IF 
			END IF 
		AFTER FIELD format_ind 
			IF l_rec_loadparms.format_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9173,"") 
				#9173 Format Indicator must exist
				NEXT FIELD format_ind 
			END IF 
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_loadparms.load_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9205,"") 
					#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				ELSE 
					IF p_mode != "U" THEN 
						SELECT unique 1 FROM loadparms 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND module_code = 'AP' 
						AND load_ind = l_rec_loadparms.load_ind 
						IF status <> NOTFOUND THEN 
							LET l_msgresp = kandoomsg("P",9177,"") 
							#9177 Load Indicator already exists; Load...
							NEXT FIELD load_ind 
						END IF 
					END IF 
				END IF 
				IF l_rec_loadparms.desc_text IS NULL THEN 
					LET l_msgresp = kandoomsg("A",9208,"") 
					#9212 Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF l_rec_loadparms.path_text IS NOT NULL THEN 
					IF NOT verify_path(l_rec_loadparms.path_text) THEN 
						LET l_msgresp = kandoomsg("U",9107,"") 
						#9107 " Unix file OR directory does NOT exist
						NEXT FIELD path_text 
					END IF 
				END IF 
				IF l_rec_loadparms.format_ind IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9173,"") 
					#9173 Format Indicator must exist.
					NEXT FIELD format_ind 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW p230 
		RETURN false 
	END IF 

	CASE p_mode 
		WHEN "U" 
			UPDATE loadparms 
			SET * = l_rec_loadparms.* 
			WHERE module_code = 'AP' 
			AND load_ind = p_load_ind 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CLOSE WINDOW p230 
			RETURN sqlca.sqlerrd[3] 
		WHEN "A" 
			INSERT INTO loadparms 
			VALUES (l_rec_loadparms.*) 
			CLOSE WINDOW p230 
			RETURN sqlca.sqlerrd[6] 
		OTHERWISE 
			CLOSE WINDOW p230 
			RETURN false 
	END CASE 

END FUNCTION 



############################################################
# FUNCTION verify_path(p_path_name)
#
# Verify Load Directory
############################################################
FUNCTION verify_path(p_path_name) 
	DEFINE p_path_name CHAR(50) 

	# huho - changed it TO use OS object 17.10.2017

	#      pr_runner    CHAR(100),
	#      ret_code     INTEGER

	RETURN os.path.exists(p_path_name) 

	#   LET pr_runner = " [ -d ",p_path_name clipped," ] 2>>", trim(get_settings_logFile())
	#   run pr_runner returning ret_code
	#   IF ret_code THEN
	#      RETURN FALSE
	#   END IF
	#   RETURN TRUE
END FUNCTION 


