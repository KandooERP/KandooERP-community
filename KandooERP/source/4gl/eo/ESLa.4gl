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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/ES_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ESL_GLOBALS.4gl" 

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"


###########################################################################
# FUNCTION get_parameters()  
#
# 
###########################################################################
FUNCTION get_parameters() 

	OPEN WINDOW E450 with FORM "E450" 
	 CALL windecoration_e("E450") -- albo kd-755 
	CALL display_parms() 

	MENU " Order load" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","ESLa","menu-Order_Load-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 
					
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
					
		COMMAND "Load" " Commence load process" 
			IF import_order() THEN 
				CALL load_routine() 
			END IF 

		ON ACTION "Print" 	#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS"
			CALL run_prog ("URS","","","","") 

		COMMAND "Directory" " List entries in a specified directory" 
			CALL show_directory() 

		ON ACTION "CANCEL" #COMMAND KEY(INTERRUPT,"E")"Exit" " Exit Order load" 
			LET quit_flag = TRUE 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW E450 
END FUNCTION 
###########################################################################
# END FUNCTION get_parameters()  
###########################################################################


###########################################################################
# FUNCTION display_parms()   
#
# 
###########################################################################
FUNCTION display_parms() 
	DEFINE l_prmpt1_text LIKE loadparms.prmpt1_text 
	DEFINE l_prmpt2_text LIKE loadparms.prmpt2_text 
	DEFINE l_prmpt3_text LIKE loadparms.prmpt3_text 

	LET l_prmpt1_text = make_prompt( glob_rec_loadparms.prmpt1_text ) 
	LET l_prmpt2_text = make_prompt( glob_rec_loadparms.prmpt2_text ) 
	LET l_prmpt3_text = make_prompt( glob_rec_loadparms.prmpt3_text )
	 
	DISPLAY l_prmpt1_text TO loadparms.prmpt1_text attribute(white)
	DISPLAY l_prmpt2_text TO loadparms.prmpt2_text attribute(white)
	DISPLAY l_prmpt3_text TO loadparms.prmpt3_text attribute(white) 
	
	DISPLAY BY NAME 
		glob_rec_loadparms.load_ind, 
		glob_rec_loadparms.desc_text, 
		glob_rec_loadparms.seq_num, 
		glob_rec_loadparms.load_date, 
		glob_rec_loadparms.load_num, 
		glob_rec_loadparms.file_text, 
		glob_rec_loadparms.path_text, 
		glob_rec_loadparms.ref1_text, 
		glob_rec_loadparms.ref2_text, 
		glob_rec_loadparms.ref3_text 

END FUNCTION 
###########################################################################
# END FUNCTION display_parms()   
###########################################################################


###########################################################################
# FUNCTION make_prompt(l_ref_text)    
#
# 
###########################################################################
FUNCTION make_prompt(l_ref_text) 
	DEFINE l_ref_text LIKE loadparms.ref1_text
	DEFINE l_temp_text LIKE loadparms.ref1_text 

	IF l_ref_text IS NULL THEN 
		RETURN l_ref_text 
	ELSE 
		LET l_temp_text = l_ref_text clipped,"..............." 
		RETURN l_temp_text 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION make_prompt(l_ref_text)    
###########################################################################


###########################################################################
# FUNCTION import_order()    
#
# 
###########################################################################
FUNCTION import_order() 
	DEFINE l_s_load_ind LIKE loadparms.load_ind 
	DEFINE l_save_load LIKE loadparms.load_ind 
	DEFINE l_lastkey INTEGER 

	MESSAGE kandoomsg2("U",1020,"Order Load") #1020 Enter Order Load Details; OK TO Continue
	INPUT BY NAME 
	glob_rec_loadparms.load_ind, 
	glob_rec_loadparms.file_text, 
	glob_rec_loadparms.path_text, 
	glob_rec_loadparms.ref1_text, 
	glob_rec_loadparms.ref2_text, 
	glob_rec_loadparms.ref3_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ESLa","input-glob_rec_loadparms-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE FIELD load_ind 
			LET l_save_load = glob_rec_loadparms.load_ind 

		AFTER FIELD load_ind 
			IF glob_rec_loadparms.load_ind IS NULL THEN 
				ERROR kandoomsg2("A",9208,"") 			#9208 Load indicator must be entered
				NEXT FIELD load_ind 
			END IF 
			SELECT * FROM loadparms 
			WHERE load_ind = glob_rec_loadparms.load_ind 
			AND module_code = 'EO' 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9206,"") 			#9206 Invalid Load indicator
				NEXT FIELD load_ind 
			END IF 
			IF l_save_load != glob_rec_loadparms.load_ind THEN 
				SELECT * INTO glob_rec_loadparms.* 
				FROM loadparms 
				WHERE load_ind = glob_rec_loadparms.load_ind 
				AND module_code = 'EO' 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				CALL display_parms() 
			END IF
			 
		AFTER FIELD file_text 
			IF glob_rec_loadparms.file_text IS NULL THEN 
				ERROR kandoomsg2("A",9166,"") 			#9166 File name must be entered
				NEXT FIELD file_text 
			END IF
			 
		AFTER FIELD path_text 
			IF glob_rec_loadparms.path_text IS NULL THEN 
				ERROR kandoomsg2("A",8015,"") 			#8015 Warning: Current directory will be defaulted
			END IF 
			LET l_lastkey = fgl_lastkey()
			 
		BEFORE FIELD ref1_text 
			IF glob_rec_loadparms.entry1_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF
			 
		AFTER FIELD ref1_text 
			IF glob_rec_loadparms.entry1_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref1_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 			#9102 Value must be entered
					NEXT FIELD ref1_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF
			 
		BEFORE FIELD ref2_text 
			IF glob_rec_loadparms.entry2_flag = 'N' THEN 
				CASE 
					WHEN l_lastkey = fgl_keyval("RETURN") 
						OR l_lastkey = fgl_keyval("right") 
						OR l_lastkey = fgl_keyval("tab") 
						OR l_lastkey = fgl_keyval("down") 
						NEXT FIELD NEXT 
					WHEN l_lastkey = fgl_keyval("left") 
						OR l_lastkey = fgl_keyval("up") 
						NEXT FIELD previous 
				END CASE 
			END IF
			 
		AFTER FIELD ref2_text 
			IF glob_rec_loadparms.entry2_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref2_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD ref2_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF
			 
		BEFORE FIELD ref3_text 
			IF glob_rec_loadparms.entry3_flag = 'N' THEN 
				NEXT FIELD NEXT 
			END IF
			 
		AFTER FIELD ref3_text 
			IF glob_rec_loadparms.entry3_flag = 'Y' THEN 
				IF glob_rec_loadparms.ref3_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 				#9102 Value must be entered
					NEXT FIELD ref3_text 
				END IF 
				LET l_lastkey = fgl_lastkey() 
			END IF 
			
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF glob_rec_loadparms.load_ind IS NULL THEN 
					ERROR kandoomsg2("A",9208,"") 				#9208 Load indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				IF glob_rec_loadparms.file_text IS NULL THEN 
					ERROR kandoomsg2("A",9166,"") 				#9166 File name must be entered
					NEXT FIELD file_text 
				END IF 
				IF glob_rec_loadparms.entry1_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref1_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
						NEXT FIELD ref1_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.entry2_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref2_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
						NEXT FIELD ref2_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.entry3_flag = 'Y' THEN 
					IF glob_rec_loadparms.ref3_text IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 					#9102 Value must be entered
						NEXT FIELD ref3_text 
					END IF 
				END IF 
				IF glob_rec_loadparms.path_text IS NULL 
				OR length(glob_rec_loadparms.path_text) = 0 THEN 
					LET glob_rec_loadparms.path_text = "." 
				END IF 
				LET glob_load_file = glob_rec_loadparms.path_text clipped,"/",glob_rec_loadparms.file_text clipped 
				IF NOT file_valid(glob_load_file) THEN 
					ERROR kandoomsg2("U",9107,"") 
					NEXT FIELD file_text 
				END IF 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		RETURN FALSE 
	END IF 
	 
	#8028 Begin Processing Load File records ? (Y/N)
	IF kandoomsg2("U",8028,"") = "N" THEN 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION import_order()    
###########################################################################


###########################################################################
# FUNCTION list_files_to_process(l_path_text, l_file_text)    
#
# 
###########################################################################
FUNCTION list_files_to_process(l_path_text, l_file_text) 
	DEFINE l_path_text LIKE loadparms.path_text 
	DEFINE l_file_text LIKE loadparms.file_text 
	#DEFINE l_file_cnt  SMALLINT
	DEFINE l_runner char(150) 

	WHENEVER ERROR CONTINUE 
	DROP TABLE t_filelist 
	CREATE temp TABLE t_filelist(file_name char(200)) with no LOG 
	IF status <> 0 THEN 
		RETURN FALSE 
	END IF 

	#!!!! runner needs adopting/migrating !!!!	
	IF l_file_text IS NULL THEN 
		LET l_runner = "ls -1 ", l_path_text clipped, "/\*[!tmp] > allfiles ", 
		" 2>>",trim(get_settings_logFile()) 
	ELSE 
		LET l_runner = "ls -1 ", l_path_text clipped, "/", 
		l_file_text clipped, 
		" > allfiles 2>>",trim(get_settings_logFile()) 
	END IF 
	CALL fgl_winmessage("runner needs adopting",l_runner,"info")
	RUN l_runner 
	#!!!! runner needs adopting/migrating !!!!

	LOAD FROM "allfiles" INSERT INTO t_filelist 
	WHENEVER ERROR stop 
	IF status <> 0 THEN 
		RETURN FALSE 
	ELSE 
		#      LET l_file_count = sqlca.sqlerrd[3]
		RETURN TRUE 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION list_files_to_process(l_path_text, l_file_text)    
###########################################################################