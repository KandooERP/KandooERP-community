#Flex Codes Setup G128
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
# \file
# \brief module - GZ4
# Purpose - Allows the user to enter AND maintain valid flex code entries
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GZ4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_g_gl() #init g/gl general ledger module #KD-2128

	OPTIONS INPUT no wrap 

	OPEN WINDOW G128 with FORM "G128" 
	CALL windecoration_g("G128") 
	
	WHILE get_info() 
		CLOSE WINDOW G128 
	END WHILE 
	
	OPTIONS INPUT wrap 

END MAIN 
############################################################
# END MAIN
############################################################

###################################################################
# FUNCTION coa_exists_check(p_flex_code)
#
#
###################################################################
FUNCTION coa_exists_check(p_start_num,p_allow_length,p_flex_code) 
	DEFINE p_start_num LIKE validflex.start_num
	DEFINE p_allow_length SMALLINT
	DEFINE p_flex_code LIKE validflex.flex_code
	DEFINE l_flexbuild LIKE account.acct_code 
	DEFINE l_starter SMALLINT 
	DEFINE l_ender SMALLINT 
	DEFINE l_cnt INTEGER 

	LET l_flexbuild = "??????????????????" 
	
	SELECT max(start_num) INTO l_starter FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	SELECT length_num INTO l_ender FROM structure 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	start_num = l_starter 
	
	LET l_ender = l_starter + l_ender 
	IF l_ender <= 18 THEN 
		LET l_flexbuild[l_ender,18] = " " 
	END IF 
	
	LET l_starter = p_start_num 
	LET l_ender = l_starter + p_allow_length - 1 
	LET l_flexbuild[l_starter, l_ender] = p_flex_code 

	SELECT count(*) INTO l_cnt FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	acct_code matches l_flexbuild 

	IF l_cnt > 0 THEN 
		ERROR kandoomsg2("G",9515,"")	#9515 "COA exists with this segment code, no deletion allowed"
		RETURN false 
	ELSE RETURN true 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION get_info()
#
#
###################################################################
FUNCTION get_info() 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_validflex DYNAMIC ARRAY OF RECORD 
		delete_flag CHAR(1), 
		flex_code LIKE validflex.flex_code, 
		desc_text LIKE validflex.desc_text, 
		group_code LIKE validflex.group_code 
	END RECORD
	DEFINE l_modified_status SMALLINT 
	DEFINE l_allow_length SMALLINT 
	DEFINE l_mode SMALLINT 
	DEFINE l_start_arr_count INTEGER 
	DEFINE l_idx INTEGER
	DEFINE l_cnt INTEGER 
	DEFINE i INTEGER 

	MESSAGE kandoomsg2("G",1500,"") #1500 "Enter Starting position of GL Code required"
	LET l_allow_length = 0 
	INPUT l_rec_validflex.start_num FROM main_input.start_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ4","flexInput") 

		BEFORE FIELD start_num 
			IF get_argint1_set() THEN 
				LET l_rec_validflex.start_num = get_url_int1() 
			END IF 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" 
			LET l_rec_validflex.start_num = strucdwind(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME l_rec_validflex.start_num 
			NEXT FIELD start_num 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN 
				# "Apply" action activated
				SELECT structure.* INTO l_rec_structure.* FROM structure 
				WHERE 
					structure.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					structure.start_num = l_rec_validflex.start_num AND 
					structure.type_ind <> "D" 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("G",9509,"")					#9509 " Starting position NOT found, try again "
					NEXT FIELD start_num 
				END IF 

				IF l_rec_structure.type_ind = "F" THEN 
					ERROR kandoomsg2("G",9510,"")					#9510 "This IS a filler, no entry allowed "
					NEXT FIELD start_num 
				END IF 
				LET l_allow_length = l_rec_structure.length_num 
			END IF 

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 
	THEN # "Cancel" ACTION activated 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	IF l_rec_validflex.flex_code IS NULL THEN 
		LET l_rec_validflex.flex_code = " " 
	END IF 

	DECLARE c_validflex CURSOR FOR 
	SELECT * INTO l_rec_validflex.* FROM validflex 
	WHERE 
		validflex.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
		validflex.start_num = l_rec_validflex.start_num 
	ORDER BY start_num, flex_code 

	LET l_idx = 0 
	FOREACH c_validflex 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_validflex[l_idx].delete_flag = "" 
		LET l_arr_rec_validflex[l_idx].flex_code = l_rec_validflex.flex_code 
		LET l_arr_rec_validflex[l_idx].desc_text = l_rec_validflex.desc_text 
		LET l_arr_rec_validflex[l_idx].group_code = l_rec_validflex.group_code 
	END FOREACH 

--	CALL set_count(l_idx) 
	MESSAGE kandoomsg2("U",1003,"")	#1003 F1 TO Add; F2 TO Delete; ENTER TO Edit.
	LET l_mode = MODE_UPDATE 
	INPUT ARRAY l_arr_rec_validflex WITHOUT DEFAULTS FROM sr_validflex.* attributes(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GZ4","flexList") 
			LET l_modified_status = 0 
			LET l_start_arr_count = arr_count() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_validflex.flex_code = l_arr_rec_validflex[l_idx].flex_code 
			LET l_rec_validflex.desc_text = l_arr_rec_validflex[l_idx].desc_text 
			LET l_rec_validflex.group_code = l_arr_rec_validflex[l_idx].group_code 

		BEFORE INSERT 
			LET l_mode = MODE_INSERT 
			LET l_idx = arr_curr() 
			LET l_rec_validflex.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_validflex.flex_code = l_arr_rec_validflex[l_idx].flex_code 
			LET l_rec_validflex.desc_text = l_arr_rec_validflex[l_idx].desc_text 
			LET l_rec_validflex.group_code = l_arr_rec_validflex[l_idx].group_code 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "DELETE" 
			LET l_idx = arr_curr() 
			IF l_mode = MODE_INSERT 
			THEN # deleting the temporary ROW OF a program ARRAY 
				CALL l_arr_rec_validflex.delete(l_idx) 
			ELSE # deleting CURRENT ROW OF a program ARRAY 
				IF NOT promptTF("","Are you sure you want to delete? ",TRUE) 
				THEN CONTINUE INPUT 
				END IF 
				# Checking for the existence of this segment code in the table 'coa'
				IF NOT coa_exists_check(l_rec_validflex.start_num,l_allow_length,l_arr_rec_validflex[l_idx].flex_code) 
				THEN CONTINUE INPUT 
				ELSE CALL l_arr_rec_validflex.delete(l_idx) 
				END IF 
			END IF 
			LET l_mode = MODE_UPDATE 

		AFTER FIELD flex_code 
			LET l_idx = arr_curr() 
			IF nvl(l_arr_rec_validflex[l_idx].flex_code, " ") <> NVL(l_rec_validflex.flex_code," ") THEN 
				# Checking for the existence of this segment code in the table 'coa'
				IF NOT coa_exists_check(l_rec_validflex.start_num,l_allow_length,l_rec_validflex.flex_code) 
				THEN ERROR kandoomsg2("G",9511,"")		#9511 " Code IS still active "
					LET l_arr_rec_validflex[l_idx].flex_code = l_rec_validflex.flex_code 
					NEXT FIELD flex_code 
				END IF 
			END IF 

			IF l_arr_rec_validflex[l_idx].flex_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 	#9102 Value must be entered
				NEXT FIELD flex_code 
			END IF 

			IF length(l_arr_rec_validflex[l_idx].flex_code) < l_allow_length THEN 
				ERROR "A valid code must contain three characters." 
				NEXT FIELD flex_code 
			END IF 
			IF length(l_arr_rec_validflex[l_idx].flex_code) > l_allow_length THEN 
				ERROR "A valid code must contain three characters." 
				LET l_arr_rec_validflex[l_idx].flex_code = l_arr_rec_validflex[l_idx].flex_code[1,l_allow_length] 
			END IF 

			IF nvl(l_arr_rec_validflex[l_idx].flex_code, " ") <> NVL(l_rec_validflex.flex_code," ") THEN 
				SELECT count(*) INTO l_cnt FROM validflex 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
				start_num = l_rec_validflex.start_num AND 
				flex_code = l_arr_rec_validflex[l_idx].flex_code 
				IF l_cnt > 0 THEN 
					ERROR kandoomsg2("U",9104,"")		#9104 This RECORD already exists
					--               LET l_arr_rec_validflex[l_idx].flex_code = l_rec_validflex.flex_code
					NEXT FIELD flex_code 
				END IF 
			END IF 

		AFTER INSERT 
			LET l_mode = MODE_UPDATE 
			LET l_modified_status = l_modified_status + field_touched(sr_validflex.*) 

		AFTER ROW 
			LET l_modified_status = l_modified_status + field_touched(sr_validflex.*) 
			LET l_idx = arr_curr() 
			IF int_flag = 0 AND quit_flag = 0 THEN 
				# "Apply" action activated
				IF l_arr_rec_validflex[l_idx].desc_text IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 	#9102 "Value must be entered"
					NEXT FIELD desc_text 
				END IF 
				
				IF l_arr_rec_validflex[l_idx].group_code IS NOT NULL THEN 
					SELECT count(*) INTO l_cnt 
					FROM groupinfo 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					group_code = l_arr_rec_validflex[l_idx].group_code 
					IF l_cnt = 0 THEN 
						ERROR kandoomsg2("U",9910,"")		#9105 RECORD NOT found; Try Window.
						NEXT FIELD group_code 
					END IF 
				END IF 
			END IF 

		AFTER INPUT 
			IF get_debug() = true THEN 
				DISPLAY "int_flag=",int_flag 
				DISPLAY "quit_flag=",quit_flag 
				DISPLAY "l_start_arr_count=",l_start_arr_count 
				DISPLAY "arr_count()=",arr_count() 
				DISPLAY "l_modified_status=",l_modified_status 
			END IF 

			IF l_start_arr_count <> arr_count() 
			THEN LET l_modified_status = l_modified_status + 1 
			END IF 

			IF int_flag = 1 OR quit_flag = 1 
			THEN # "Cancel" ACTION activated 
				IF l_modified_status <> 0 
				THEN #check, IF anything has changed... 
					IF promptTF("Exit ?","Do you want to exit ?\nAll changes will be lost !",TRUE) 
					THEN RETURN true 
					ELSE LET int_flag = false 
						LET quit_flag = false 
						CONTINUE INPUT 
					END IF 
				ELSE RETURN true 
				END IF 
			ELSE # "Apply" ACTION activated 
				IF l_modified_status <> 0 
				THEN #check, IF anything has changed... 
					IF promptTF("Save and exit.","Do you want to save data ?",TRUE) 
					THEN WHENEVER ERROR stop 
						BEGIN WORK 
							DELETE FROM validflex WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
							start_num = l_rec_validflex.start_num 
							FOR i = 1 TO l_arr_rec_validflex.getlength() 
								INSERT INTO validflex VALUES (glob_rec_kandoouser.cmpy_code,l_rec_validflex.start_num,l_arr_rec_validflex[i].flex_code,l_arr_rec_validflex[i].desc_text,l_arr_rec_validflex[i].group_code) 
							END FOR 
						COMMIT WORK 
						--                        CALL msgContinue("","Data has been saved.\n Press OK to continue.")
						WHENEVER ERROR stop 
						RETURN true 
					ELSE LET int_flag = false 
						LET quit_flag = false 
						RETURN true 
					END IF 
				ELSE RETURN true 
				END IF 
			END IF 

	END INPUT 

END FUNCTION
###################################################################
# END FUNCTION get_info()
###################################################################