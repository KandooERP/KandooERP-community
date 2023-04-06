#GL Flexible Structure - CHAR(18) Maintenance G126
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

	Source code beautified by beautify.pl on 2020-01-03 14:29:01	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it, hoelzl@querix.com, a.bondar@querix.com
}
# \file
# \brief module GZ3 allows the user TO maintain the GL structure
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_arr_rec_structure DYNAMIC ARRAY OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		default_text LIKE structure.default_text, 
		type_ind LIKE structure.type_ind 
	END RECORD 

	DEFINE glob_err_message CHAR(40) 
	DEFINE glob_structure_map VARCHAR(18) 

END GLOBALS 

DEFINE modu_modified_status SMALLINT 
DEFINE start_arr_count INTEGER 

###################################################################
# MAIN
#
#
###################################################################
MAIN 

	CALL setModuleId("GZ3") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_g_gl() #init g/gl general ledger module #KD-2128

	OPEN WINDOW wg126 with FORM "G126" 
	CALL windecoration_g("G126") 

	OPTIONS INPUT no wrap 
	CALL get_info() 
	OPTIONS INPUT wrap 

	CLOSE WINDOW wg126 
END MAIN 

###################################################################
# FUNCTION map_start_check(p_start)
#
#
###################################################################
FUNCTION map_start_check(p_start) 
	DEFINE p_start SMALLINT 

	IF p_start IS NULL THEN 
		ERROR "Value must be entered" 
		RETURN false 
	END IF 

	IF (p_start < 1) OR (p_start > 18) THEN 
		ERROR "Invalid start position Range: 1-18" 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 

###################################################################
# FUNCTION map_length_check(p_start,p_length)
#
#
###################################################################
FUNCTION map_length_check(p_start,p_length) 
	DEFINE p_start SMALLINT 
	DEFINE p_length SMALLINT 

	IF p_length IS NULL THEN 
		ERROR "Value must be entered" 
		RETURN false 
	END IF 

	IF p_length < 1 THEN 
		ERROR "Length can not be negative or 0" 
		RETURN false 
	END IF 

	IF (p_start + p_length - 1) < 2 OR (p_start + p_length) > 19 THEN 
		ERROR "Invalid length" 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 

###################################################################
# FUNCTION map_default_text(p_arr_curr)
#
#
###################################################################
FUNCTION map_default_text(p_arr_curr) 
	DEFINE 
	p_arr_curr,i SMALLINT 

	IF length(glob_arr_rec_structure[p_arr_curr].default_text) <> glob_arr_rec_structure[p_arr_curr].length_num 
	THEN ERROR "Default text length (mask) must match the length of this section" 
		IF length(glob_arr_rec_structure[p_arr_curr].default_text) > glob_arr_rec_structure[p_arr_curr].length_num 
		THEN LET glob_arr_rec_structure[p_arr_curr].default_text = glob_arr_rec_structure[p_arr_curr].default_text[1,glob_arr_rec_structure[p_arr_curr].length_num] 
		ELSE FOR i = length(glob_arr_rec_structure[p_arr_curr].default_text) TO glob_arr_rec_structure[p_arr_curr].length_num - 1 
			LET glob_arr_rec_structure[p_arr_curr].default_text = glob_arr_rec_structure[p_arr_curr].default_text CLIPPED,"?" 
		END FOR 
	END IF 
END IF 

END FUNCTION 

###################################################################
# FUNCTION map_type_ind_check(p_arr_count,p_arr_curr,p_type_ind)
#
#
###################################################################
FUNCTION map_type_ind_check(p_arr_count,p_arr_curr,p_type_ind) 
	DEFINE p_arr_count INTEGER 
	DEFINE p_arr_curr SMALLINT 
	DEFINE p_type_ind LIKE structure.type_ind 
	DEFINE l_idx SMALLINT 
	DEFINE i INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_type_ind IS NULL THEN 
		ERROR "Value must be entered" 
		RETURN false 
	END IF 

	LET l_idx = p_arr_curr 
	IF glob_arr_rec_structure[l_idx].type_ind != "S" AND 
	glob_arr_rec_structure[l_idx].type_ind != "C" AND 
	glob_arr_rec_structure[l_idx].type_ind != "F" AND 
	glob_arr_rec_structure[l_idx].type_ind != "L" THEN 
		LET l_msgresp = kandoomsg("U",9112,"Type") 
		#9112 Invalid Type
		RETURN false 
	END IF 

	IF glob_arr_rec_structure[l_idx].type_ind = "C" THEN 
		FOR i = 1 TO p_arr_count 
			IF i = l_idx THEN 
			ELSE 
				IF glob_arr_rec_structure[i].type_ind = "C" THEN 
					LET l_msgresp = kandoomsg("G",9098,"Chart") 
					#9098 " Chart type already exists FOR this account code"
					RETURN false --> NEXT FIELD type_ind 
				END IF 
			END IF 
		END FOR 
	END IF 

	IF glob_arr_rec_structure[l_idx].type_ind = "L" THEN 
		FOR i = 1 TO p_arr_count 
			IF i = l_idx THEN 
			ELSE 
				IF glob_arr_rec_structure[i].type_ind = "L" THEN 
					LET l_msgresp = kandoomsg("G",9098,"Ledger") 
					#9098 "Ledger type already exists FOR this account code"
					RETURN false --> NEXT FIELD type_ind 
				END IF 
			END IF 
		END FOR 
	END IF 

	RETURN true 

END FUNCTION 

###################################################################
# FUNCTION map_get_startPosition()
#
#
###################################################################
FUNCTION map_get_startposition(p_arr_count) 
	DEFINE 
	p_arr_count INTEGER, 
	l_startposition,i SMALLINT 

	LET l_startposition = 0 
	FOR i = 1 TO arr_count() 
		LET l_startposition = l_startposition + nvl(glob_arr_rec_structure[i].length_num,0) 
	END FOR 
	LET l_startposition = l_startposition + 1 

	IF l_startposition > 18 
	THEN ERROR "You can not add more segements" 
		RETURN -1 
	ELSE RETURN l_startposition 
	END IF 

END FUNCTION 

###################################################################
# FUNCTION map_delete(p_arr_count,p_start)
#
#
###################################################################
FUNCTION map_delete(p_arr_count,p_arr_curr,p_start) 
	DEFINE p_arr_count INTEGER 
	DEFINE p_arr_curr INTEGER 
	DEFINE p_start SMALLINT 
	DEFINE l_chart_flag SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_structure_map VARCHAR(18) 
	DEFINE i SMALLINT 

	FOR i = p_arr_curr TO p_arr_count 
		IF glob_arr_rec_structure[i].type_ind = "C" THEN 
			LET l_chart_flag = true 
		END IF 
	END FOR 
	IF l_chart_flag THEN 
		LET l_msgresp = kandoomsg("G",9107,"") 
		#9107 "There must be AT least one chart structure (Type = C)"
		RETURN false 
	END IF 

	IF p_start < 1 OR p_start > 18 THEN 
		ERROR "Invalid start position Range: 1-18" 
		RETURN false 
	END IF 

	LET l_structure_map = glob_structure_map 

	FOR i = p_start TO sizeof(l_structure_map) 
		LET l_structure_map[i] = " " 
	END FOR 

	LET glob_structure_map = l_structure_map 
	DISPLAY glob_structure_map TO lb_structure_map 

	RETURN true 
END FUNCTION 

###################################################################
# FUNCTION dataSource()
#
#
###################################################################
FUNCTION datasource() 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_rec_structure RECORD LIKE structure.* 

	LET glob_structure_map = NULL 

	DECLARE c_structure CURSOR FOR 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code --"01" 
	AND start_num > 0 
	ORDER BY start_num 
	LET l_idx = 0 
	FOREACH c_structure INTO l_rec_structure.* 
		LET l_idx = l_idx + 1 
		LET glob_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET glob_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET glob_arr_rec_structure[l_idx].desc_text = trim(l_rec_structure.desc_text) 
		LET glob_arr_rec_structure[l_idx].default_text = trim(l_rec_structure.default_text) 
		LET glob_arr_rec_structure[l_idx].type_ind = l_rec_structure.type_ind 

		FOR i = l_rec_structure.start_num TO l_rec_structure.start_num + l_rec_structure.length_num - 1 
			LET glob_structure_map[i] = trim(l_rec_structure.type_ind) 
		END FOR 

		IF get_debug() = true THEN 
			DISPLAY "l_rec_structure.start_num=", l_rec_structure.start_num 
			DISPLAY "glob_arr_rec_structure[",l_idx,"].start_num=", glob_arr_rec_structure[l_idx].start_num 
			DISPLAY "l_rec_structure.length_num=", l_rec_structure.length_num 
			DISPLAY "glob_arr_rec_structure[",l_idx,"].length_num=", glob_arr_rec_structure[l_idx].length_num 
			DISPLAY "l_rec_structure.desc_text=", l_rec_structure.desc_text 
			DISPLAY "glob_arr_rec_structure[",l_idx,"].desc_tex=", glob_arr_rec_structure[l_idx].desc_text 
			DISPLAY "l_rec_structure.default_text=", l_rec_structure.default_text 
			DISPLAY "glob_arr_rec_structure[",l_idx,"].default_text=", glob_arr_rec_structure[l_idx].default_text 
			DISPLAY "l_rec_structure.type_ind=", l_rec_structure.type_ind 
			DISPLAY "glob_arr_rec_structure[",l_idx,"].type_ind=", glob_arr_rec_structure[l_idx].type_ind 

		END IF 
	END FOREACH 

END FUNCTION 

###################################################################
# FUNCTION get_info()
#
#
###################################################################
FUNCTION get_info() 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_err_flag SMALLINT 
	DEFINE l_chart_flag SMALLINT 
	DEFINE l_last_end SMALLINT 
	DEFINE l_this_end SMALLINT 
	DEFINE l_ender SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_length_str SMALLINT 
	DEFINE structure_map CHAR(18) 
	DEFINE i SMALLINT 
	DEFINE l_mode SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_idx SMALLINT 
	DEFINE l_cnt INTEGER 
	DEFINE msg STRING 

	LET l_mode = MODE_UPDATE 

	CALL datasource() 

	DISPLAY glob_structure_map TO lb_structure_map 

	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("G",1003,"") 
	#1003 F1 TO Add - F2 TO Delete - RETURN on line TO Edit

	WHILE true 

		INPUT ARRAY glob_arr_rec_structure WITHOUT DEFAULTS FROM sr_structure.* attributes(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GZ3","flexInputArr") 
				LET modu_modified_status = 0 
				LET start_arr_count = arr_count() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_structure.start_num = glob_arr_rec_structure[l_idx].start_num 
				LET l_rec_structure.length_num = glob_arr_rec_structure[l_idx].length_num 
				LET l_rec_structure.desc_text = trim(glob_arr_rec_structure[l_idx].desc_text) 
				LET l_rec_structure.default_text = trim(glob_arr_rec_structure[l_idx].default_text) 
				LET l_rec_structure.type_ind = glob_arr_rec_structure[l_idx].type_ind 
				NEXT FIELD start_num 

			BEFORE INSERT 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				LET l_mode = MODE_INSERT 
				IF map_get_startposition(l_cnt) = -1 
				THEN CANCEL INSERT 
				ELSE LET glob_arr_rec_structure[l_idx].start_num = map_get_startposition(l_cnt) 
				END IF 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "DELETE" 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				IF l_mode = MODE_INSERT 
				THEN # deleting the temporary ROW OF a program ARRAY 
					CALL glob_arr_rec_structure.delete(l_idx) 
				ELSE # deleting all ROWS OF a program array, starting FROM a ROW l_idx 
					LET msg = "All segments starting from the Start Position ",glob_arr_rec_structure[l_idx].start_num USING "<<<<<<"," will be deleted.","\n", 
					" Are you sure you want to delete? " 
					IF NOT promptTF("",msg,TRUE) 
					THEN CONTINUE INPUT 
					END IF 
					IF map_delete(l_cnt,l_idx,glob_arr_rec_structure[l_idx].start_num) THEN 
						CALL glob_arr_rec_structure.delete(l_idx,glob_arr_rec_structure.getlength()) 
					END IF 
				END IF 
				LET l_mode = MODE_UPDATE 

			AFTER FIELD start_num 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				IF NOT map_start_check(glob_arr_rec_structure[l_idx].start_num) THEN 
					NEXT FIELD start_num 
				END IF 
				# Now check that this combination does NOT interfere with
				# what IS already added
				FOR i = 1 TO l_cnt 
					IF i = l_idx THEN 
					ELSE 
						IF (glob_arr_rec_structure[i].start_num >= glob_arr_rec_structure[l_idx].start_num 
						AND glob_arr_rec_structure[i].start_num < glob_arr_rec_structure[l_idx].start_num 
						+ glob_arr_rec_structure[l_idx].length_num) 
						OR (glob_arr_rec_structure[i].start_num + glob_arr_rec_structure[i].length_num > 
						glob_arr_rec_structure[l_idx].start_num 
						AND glob_arr_rec_structure[i].start_num + glob_arr_rec_structure[i].length_num 
						< glob_arr_rec_structure[l_idx].start_num + 
						glob_arr_rec_structure[l_idx].length_num) THEN 
							LET l_msgresp = kandoomsg("G",9097,"") 
							#9097 "This entry will interfere with current entries "
							NEXT FIELD start_num 
						END IF 
					END IF 
				END FOR 

			AFTER FIELD length_num 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				IF NOT map_length_check(glob_arr_rec_structure[l_idx].start_num,glob_arr_rec_structure[l_idx].length_num) THEN 
					NEXT FIELD length_num 
				END IF 
				IF length(glob_arr_rec_structure[l_idx].default_text) <> glob_arr_rec_structure[l_idx].length_num 
				THEN CALL map_default_text(l_idx) 
				END IF 
				# display of "Flexible Structure Preview" to field lb_structure_map
				LET glob_structure_map = "" 
				FOR l_idx = 1 TO l_cnt 
					FOR i = glob_arr_rec_structure[l_idx].start_num TO glob_arr_rec_structure[l_idx].start_num + glob_arr_rec_structure[l_idx].length_num - 1 
						LET glob_structure_map[i] = trim(glob_arr_rec_structure[l_idx].type_ind) 
					END FOR 
				END FOR 
				DISPLAY glob_structure_map TO lb_structure_map 

			AFTER FIELD default_text 
				LET l_idx = arr_curr() 
				CALL map_default_text(l_idx) 

			AFTER FIELD type_ind 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				IF NOT map_type_ind_check(l_cnt,l_idx,glob_arr_rec_structure[l_idx].type_ind) 
				THEN NEXT FIELD type_ind 
				ELSE IF map_type_ind_check(l_cnt,l_idx,glob_arr_rec_structure[l_idx].type_ind) = -1 
					THEN NEXT FIELD start_num 
					END IF 
				END IF 

			AFTER INSERT 
				LET l_cnt = arr_count() 
				LET l_idx = arr_curr() 
				IF NOT map_start_check(glob_arr_rec_structure[l_idx].start_num) THEN 
					NEXT FIELD start_num 
				END IF 
				IF NOT map_length_check(glob_arr_rec_structure[l_idx].start_num,glob_arr_rec_structure[l_idx].length_num) THEN 
					NEXT FIELD length_num 
				END IF 
				CALL map_default_text(l_idx) 
				IF NOT map_type_ind_check(l_cnt,l_idx,glob_arr_rec_structure[l_idx].type_ind) THEN 
					NEXT FIELD type_ind 
				END IF 
				LET l_mode = MODE_UPDATE 
				LET modu_modified_status = modu_modified_status + field_touched(sr_structure.*) 
				# display of "Flexible Structure Preview" to field lb_structure_map
				LET glob_structure_map = "" 
				FOR l_idx = 1 TO l_cnt 
					FOR i = glob_arr_rec_structure[l_idx].start_num TO glob_arr_rec_structure[l_idx].start_num + glob_arr_rec_structure[l_idx].length_num - 1 
						LET glob_structure_map[i] = trim(glob_arr_rec_structure[l_idx].type_ind) 
					END FOR 
				END FOR 
				DISPLAY glob_structure_map TO lb_structure_map 

			AFTER ROW 
				LET modu_modified_status = modu_modified_status + field_touched(sr_structure.*) 

			AFTER INPUT 
				IF get_debug() = true THEN 
					DISPLAY "int_flag=",int_flag 
					DISPLAY "quit_flag=",quit_flag 
					DISPLAY "modu_modified_status=",modu_modified_status 
					DISPLAY "field_touched(sr_structure.*)=",field_touched(sr_structure.*) 
					DISPLAY "start_arr_count=",start_arr_count 
					DISPLAY "arr_count()=",arr_count() 
				END IF 

				IF start_arr_count <> arr_count() 
				THEN LET modu_modified_status = modu_modified_status + 1 
				END IF 

				IF modu_modified_status = 0 
				THEN #check, IF anything has changed... 
					RETURN false 
				END IF 

				IF int_flag = 1 OR quit_flag = 1 
				THEN # "Cancel" ACTION activated 
					IF modu_modified_status <> 0 
					THEN #check, IF anything has changed... 
						IF promptTF("Exit ?","Do you want to exit the program ?\n All changes will be lost!",TRUE) 
						THEN RETURN false 
						ELSE LET int_flag = false 
							LET quit_flag = false 
							CONTINUE INPUT 
						END IF 
					END IF 
				ELSE # "Apply" ACTION activated 
					IF modu_modified_status <> 0 
					THEN #check, IF anything has changed... 
						IF promptTF("Save and exit.","Do you want to save data ?",TRUE) 
						THEN 
						ELSE LET int_flag = false 
							LET quit_flag = false 
							CONTINUE INPUT 
						END IF 
					END IF 
				END IF 

		END INPUT 

		# now final checks on array
		# first check FOR contiguity
		# bung them out TO a temp table, SELECT them in ORDER of start
		# AND check that END of this IS start of next
		CALL write_inp_array_data_to_temp_table() 

		DECLARE check_1 CURSOR FOR 
		SELECT *, start_num + length_num FROM t_structure 
		ORDER BY start_num 

		LET l_last_end = 0 
		LET l_err_flag = false 
		LET l_chart_flag = false 
		LET l_idx = 0 

		FOREACH check_1 INTO l_rec_structure.*, l_this_end 
			LET l_idx = l_idx + 1 
			LET glob_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
			LET glob_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
			LET glob_arr_rec_structure[l_idx].desc_text = trim(l_rec_structure.desc_text) 
			LET glob_arr_rec_structure[l_idx].default_text = trim(l_rec_structure.default_text) 
			LET glob_arr_rec_structure[l_idx].type_ind = l_rec_structure.type_ind 

			IF glob_arr_rec_structure[l_idx].type_ind = "C" THEN 
				LET l_chart_flag = true 
			END IF 

			IF l_last_end = 0 THEN #the FIRST time round 
				IF l_rec_structure.start_num <> 1 THEN 
					LET l_msgresp = kandoomsg("G",9099,"") 
					#9099 " First structure code must have start position of 1"
					LET l_err_flag = true 
					EXIT FOREACH 
				END IF 
			ELSE 
				IF l_rec_structure.start_num <> l_last_end THEN 
					LET l_msgresp = kandoomsg("G",9106,"") 
					#9106 "Structures must be continuous."
					LET l_err_flag = true 
					EXIT FOREACH 
				END IF 
			END IF 
			LET l_last_end = l_this_end 

		END FOREACH 

		#Check that there are no errors AND AT least one (C)hart IS defined
		IF l_err_flag THEN 
			CONTINUE WHILE 
		END IF 

		IF NOT l_chart_flag THEN 
			LET l_msgresp = kandoomsg("G",9107,"") 
			#9107 "There must be AT least one chart structure (Type = C)"
			CONTINUE WHILE 
		END IF 

		#RETURN TRUE #EXIT WHILE
		EXIT WHILE 
	END WHILE 

	GOTO bypass 
	LABEL recovery: 

	LET l_msgresp = error_recover(glob_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	BEGIN WORK 

		WHENEVER ERROR GOTO recovery 

		LET glob_err_message = " GZ3- Deleting FROM structure" 
		DELETE FROM structure WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_err_message = " GZ3- Inserting INTO structure" 

		FOR i = 1 TO glob_arr_rec_structure.getlength() 
			INSERT INTO structure VALUES (glob_rec_kandoouser.cmpy_code, glob_arr_rec_structure[i].*) 
		END FOR 

		LET l_rec_structure.default_text = " " 
		FOR i = 1 TO arr_count() -- albo kd-1190 
			LET l_start_pos = glob_arr_rec_structure[i].start_num 
			LET l_length_str = glob_arr_rec_structure[i].length_num 
			LET l_rec_structure.default_text = l_rec_structure.default_text clipped, -- albo kd-1190 
			glob_arr_rec_structure[i].default_text[1, l_length_str] 
		END FOR 

		LET l_rec_structure.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_structure.start_num = 0 
		LET l_rec_structure.length_num = l_ender 
		LET l_rec_structure.desc_text = "Default Code" 
		LET l_rec_structure.default_text = l_rec_structure.default_text 
		LET l_rec_structure.type_ind = "D" 
		INSERT INTO structure VALUES (l_rec_structure.*) 

	COMMIT WORK 
	--   CALL msgContinue("","Data has been saved.\n Press OK to continue.")

	WHENEVER ERROR stop 

	RETURN true 
END FUNCTION 

###################################################################
# FUNCTION write_inp_array_data_to_temp_table()
#
# Very good choice of a function name.. we need to rename this...
###################################################################
FUNCTION write_inp_array_data_to_temp_table() 
	DEFINE i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHENEVER ERROR CONTINUE 
	IF fgl_find_table("t_structure") THEN
		DROP TABLE t_structure 
	END IF	

	GOTO bypass 
	LABEL recovery: 

	LET l_msgresp = error_recover(glob_err_message, status) 
	IF l_msgresp != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	BEGIN WORK 
		WHENEVER ERROR GOTO recovery 

		LET glob_err_message = " GZ3- creating temp table" 
		CREATE temp TABLE t_structure (cmpy_code nchar(2), 
		start_num SMALLINT, 
		length_num SMALLINT, 
		desc_text NVARCHAR(20), 
		default_text NVARCHAR(18), 
		type_ind nchar(1)) with no LOG 
		DELETE FROM t_structure 
		FOR i = 1 TO glob_arr_rec_structure.getlength() 
			INSERT INTO t_structure VALUES (glob_rec_kandoouser.cmpy_code, glob_arr_rec_structure[i].* ) 
		END FOR 

	COMMIT WORK 

	WHENEVER ERROR stop 
END FUNCTION 
