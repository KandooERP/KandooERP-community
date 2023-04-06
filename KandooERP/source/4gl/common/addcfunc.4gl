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

###########################################################################
# FUNCTION add_acct_code(p_cmpy, p_account_code)
#
#
###########################################################################
FUNCTION add_acct_code(p_cmpy, p_account_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_account_code LIKE coa.acct_code #char(18) 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_validflex RECORD LIKE validflex.* 
	DEFINE l_arr_rec_structure DYNAMIC ARRAY OF #array[10] OF 
	RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text, 
		flex_code LIKE account.acct_code 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.* 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_not_right SMALLINT 
	DEFINE l_start_pos SMALLINT 
	DEFINE l_end_pos SMALLINT 
	DEFINE l_pos_cnt SMALLINT 

	DEFINE l_chart_start SMALLINT 
	DEFINE l_cnt SMALLINT 

	#scrn SMALLINT
	DEFINE l_msgresp LIKE language.yes_flag 

	WHENEVER ERROR CONTINUE 

	OPTIONS DELETE KEY f36, 
	INSERT KEY f35 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	LABEL next_shot: 

	# first off check TO see IF the coa IS valid, IF so RETURN
	# IF no period OR year_num entered the dont check
	SELECT * INTO l_rec_coa.* FROM coa 
	WHERE cmpy_code = p_cmpy 
	AND acct_code = p_account_code 
	IF status != notfound THEN #if found -it already exists ! 
		ERROR kandoomsg2("U",9104,"") 	#9104 RECORD already exists
		LET p_account_code = "zzzzzzzzzzzzzzzzzz" 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		RETURN (p_account_code) 
	END IF 
	# IF problem THEN should we read & DISPLAY the valid flex codes... probably
	# also put the account code thru a reformatter which will
	# be improved with time....
	#LET p_account_code = reformatter(p_account_code)
	OPEN WINDOW structurewind with FORM "G147" --huho attribute (border) 
	CALL winDecoration_g("G147") 

	IF get_debug() THEN 
		DISPLAY "##############################" 
		DISPLAY "p_cmpy=", p_cmpy 
		DISPLAY "##############################" 
	END IF 

	DECLARE structurecurs CURSOR FOR 
	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND type_ind != "F" 
	ORDER BY start_num 

	LET l_pos_cnt = 1 

	LET l_idx = 0 
	FOREACH structurecurs 
		LET l_idx = l_idx + 1 
		IF l_rec_structure.type_ind = "C" THEN 
			LET l_chart_start = l_rec_structure.start_num 
		END IF 

		IF get_debug() THEN 
			DISPLAY "l_rec_structure.cmpy_code=", trim(l_rec_structure.cmpy_code) 
			DISPLAY "l_rec_structure.start_num=", trim(l_rec_structure.start_num) 
			DISPLAY "l_rec_structure.length_num=", trim(l_rec_structure.length_num) 
			DISPLAY "l_rec_structure.desc_text=", trim(l_rec_structure.desc_text) 
			DISPLAY "l_rec_structure.default_text=", trim(l_rec_structure.default_text) 
			DISPLAY "l_rec_structure.type_ind=", trim(l_rec_structure.type_ind) 
		END IF 

		LET l_arr_rec_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_rec_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_rec_structure[l_idx].length_num = l_rec_structure.length_num 
		LET l_pos_cnt = l_rec_structure.start_num 
		LET l_end_pos = l_pos_cnt + l_rec_structure.length_num 
		LET l_arr_rec_structure[l_idx].flex_code = p_account_code[l_pos_cnt, l_end_pos-1] 
	END FOREACH 

	LET l_cnt = l_idx 

	#   CALL set_count(l_idx)
	MESSAGE kandoomsg2("G",1058,"") #1058 F10 Add Flex Code - ESC TO Continue
	#INPUT ARRAY l_arr_rec_structure WITHOUT DEFAULTS FROM sr_structure.*


	DISPLAY ARRAY l_arr_rec_structure TO sr_structure.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","addcfunc","input-arr-structure1") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#         LET scrn = scr_line()
			#         IF l_idx <= l_cnt THEN
			#            DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*
			#
			#         END IF
			IF l_arr_rec_structure[l_idx].desc_text IS NULL 
			OR l_arr_rec_structure[l_idx].start_num < 0 THEN 
				EXIT DISPLAY 
			END IF 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			LET l_arr_rec_structure[l_idx].flex_code = show_flex(p_cmpy, l_arr_rec_structure[l_idx].start_num) 
			#         DISPLAY l_arr_rec_structure[l_idx].flex_code TO sr_structure[scrn].flex_code
			#
			#         NEXT FIELD flex_code

		ON KEY (F10) 
			CALL run_prog_with_url_arg("GZ4","ARGINT1", l_arr_rec_structure[l_idx].start_num, "", "", "", "", "", "") 
			#CALL run_prog("GZ4",l_arr_rec_structure[l_idx].start_num,"","","")

			#      AFTER ROW
			#         DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			#AFTER FIELD flex_code
			# Check the individuals AFTER every row
			# FROM validflex AND the complete AT the end
			# FROM the coa
			IF l_arr_rec_structure[l_idx].start_num = l_chart_start THEN 
				MESSAGE "equal l_arr_rec_structure[l_idx].start_num = l_chart_start " 
				EXIT DISPLAY 
			ELSE 
				SELECT * INTO l_rec_validflex.* FROM validflex 
				WHERE cmpy_code = p_cmpy 
				AND start_num = l_arr_rec_structure[l_idx].start_num 
				AND flex_code = l_arr_rec_structure[l_idx].flex_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9105,"") 	#9105 "Record Not Found - Try Window"
					CONTINUE DISPLAY 
					#               NEXT FIELD flex_code
				END IF 
				#            IF l_idx <= l_cnt THEN
				#               DISPLAY l_arr_rec_structure[l_idx].* TO sr_structure[scrn].*
				#
				#            END IF
			END IF 
			#         IF NOT (fgl_lastkey() = fgl_keyval("accept"))
			#         AND NOT (fgl_lastkey() = fgl_keyval("up"))
			#         AND NOT (fgl_lastkey() = fgl_keyval("left"))
			#         AND (l_arr_rec_structure[l_idx+1].desc_text IS NULL
			#         OR l_arr_rec_structure[l_idx+1].start_num < 0) THEN
			#            ERROR kandoomsg2("U",9001,"")	#            #9001 No more rows in this direction
			#            NEXT FIELD flex_code
			#         END IF

		AFTER DISPLAY 
			IF int_flag OR quit_flag THEN 
			ELSE 
				LET l_not_right = 0 
				FOR i=1 TO arr_count() 
					# Check the individuals AFTER every row
					# FROM validflex AND the complete AT the end
					# FROM the coa
					IF l_arr_rec_structure[i].start_num = l_chart_start THEN 
					ELSE 
						SELECT * INTO l_rec_validflex.* FROM validflex 
						WHERE cmpy_code = p_cmpy 
						AND start_num = l_arr_rec_structure[i].start_num 
						AND flex_code = l_arr_rec_structure[i].flex_code 
						IF status = notfound THEN 
							ERROR kandoomsg2("G",9528,i) 					#9528 Can NOT find flex code on line i
							LET l_not_right = 1 
						END IF 
					END IF 
				END FOR 
			END IF 

	END DISPLAY 

	LET l_idx = arr_curr() 
	CLOSE WINDOW structurewind 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET p_account_code = "zzzzzzzzzzzzzzzzzz" #this strange zzzz..char(18) RETURN value will be validated BY the calling FUNCTION 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		RETURN(p_account_code) 
	END IF 

	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num = 0 

	LET p_account_code = l_rec_structure.default_text 
	FOR l_idx = 1 TO arr_count() 
		LET l_end_pos = l_arr_rec_structure[l_idx].start_num + l_arr_rec_structure[l_idx].length_num - 1 
		LET l_start_pos = l_arr_rec_structure[l_idx].start_num 
		LET p_account_code[l_start_pos,l_end_pos] = l_arr_rec_structure[l_idx].flex_code 
	END FOR 

	IF l_not_right = 1 THEN 
		GOTO next_shot 
	END IF 

	CALL db_coa_get_rec(ui_off,p_account_code) RETURNING l_rec_coa.* 
	#SELECT * INTO l_rec_coa.* FROM coa
	# WHERE cmpy_code = p_cmpy
	#   AND acct_code = p_account_code
	IF l_rec_coa.* IS NOT NULL THEN #status != notfound THEN 
		ERROR kandoomsg2("U",9104,"") 	#9104 RECORD already exists
		LET p_account_code = "zzzzzzzzzzzzzzzzzz" 
		OPTIONS DELETE KEY f2, 
		INSERT KEY f1 
		RETURN (p_account_code) 
	END IF 

	OPTIONS DELETE KEY f2, 
	INSERT KEY f1 

	RETURN (p_account_code) 
END FUNCTION 
###########################################################################
# END FUNCTION add_acct_code(p_cmpy, p_account_code)
###########################################################################