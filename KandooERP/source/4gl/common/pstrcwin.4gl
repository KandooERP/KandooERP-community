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

	Source code beautified by beautify.pl on 2020-01-02 10:35:30	$Id: $
}



#
#   pstrcwin.4gl - part_code
#                  FUNCTION FOR Structuring a Product Code
#                  FUNCTION will RETURN part_code TO calling program
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION form_part_code(p_cmpy,p_orig_class_code,p_orig_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_orig_class_code LIKE class.class_code
	DEFINE p_orig_part_code LIKE product.part_code

	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_class_code LIKE class.class_code 
	DEFINE l_part_code LIKE product.part_code 
	DEFINE l_rec_prodstructure RECORD LIKE prodstructure.* 
	DEFINE l_arr_segment array[99] OF RECORD 
		scroll_flag CHAR(1), 
		start_num LIKE prodstructure.start_num, 
		length LIKE prodstructure.length, 
		desc_text LIKE prodstructure.desc_text, 
		flex_code LIKE prodflex.flex_code 
	END RECORD 
	DEFINE l_arr_prodstructure array[99] OF RECORD 
		seq_num LIKE prodstructure.seq_num, 
		type_ind LIKE prodstructure.type_ind, 
		valid_flag LIKE prodstructure.valid_flag 
	END RECORD 
	DEFINE l_part_length LIKE prodstructure.length 
	DEFINE l_dashs CHAR(15) 
	DEFINE l_start_num LIKE prodstructure.start_num 
	DEFINE l_length LIKE prodstructure.length 
	DEFINE l_last_seq_num LIKE prodstructure.seq_num 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_blank_found SMALLINT 
	DEFINE l_winds_text CHAR(40) 
	DEFINE l_idx,l_scrn SMALLINT
	DEFINE x SMALLINT	 

	OPEN WINDOW w169 with FORM "W169" 
	CALL windecoration_w("W169") -- albo kd-758 
	LET l_part_code = p_orig_part_code 
	LET l_class_code = class_input(p_cmpy, p_orig_class_code) 
	IF l_class_code IS NULL THEN 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW w169 
			RETURN p_orig_class_code, l_part_code 
		ELSE 
			CLOSE WINDOW w169 
			RETURN "", "" 
		END IF 
	END IF 
	SELECT * INTO l_rec_class.* FROM class 
	WHERE class_code = l_class_code 
	AND cmpy_code = p_cmpy 
	LET l_msgresp = kandoomsg("I",1002,"") 
	#1002 " Searching database - please wait"
	DECLARE c_prodstructure CURSOR FOR 
	SELECT * FROM prodstructure 
	WHERE cmpy_code = p_cmpy 
	AND class_code = l_rec_class.class_code 
	ORDER BY seq_num 
	FOR l_idx = 1 TO 99 
		INITIALIZE l_arr_segment[l_idx].* TO NULL 
	END FOR 
	LET l_idx = 0 
	FOREACH c_prodstructure INTO l_rec_prodstructure.* 
		IF l_rec_prodstructure.type_ind = "S" THEN 
			LET l_idx = l_idx + 1 
			LET l_arr_segment[l_idx].start_num = l_rec_prodstructure.start_num 
			LET l_arr_segment[l_idx].length = l_rec_prodstructure.length 
			LET l_arr_segment[l_idx].desc_text = l_rec_prodstructure.desc_text 
			LET l_arr_prodstructure[l_idx].seq_num = l_rec_prodstructure.seq_num 
			LET l_arr_prodstructure[l_idx].type_ind = l_rec_prodstructure.type_ind 
			LET l_arr_prodstructure[l_idx].valid_flag = l_rec_prodstructure.valid_flag 
			IF l_part_code IS NOT NULL 
			AND l_class_code = p_orig_class_code THEN 
				LET l_start_num = l_rec_prodstructure.start_num 
				LET l_length = l_rec_prodstructure.length 
				LET l_part_length = length(l_part_code) 
				IF (l_start_num + l_length) > l_part_length THEN 
					IF l_start_num <= l_part_length THEN 
						LET l_arr_segment[l_idx].flex_code 
						= l_part_code[l_start_num, l_part_length] 
					END IF 
				ELSE 
					LET l_arr_segment[l_idx].flex_code 
					= l_part_code[l_start_num, l_start_num + l_length - 1] 
				END IF 
			ELSE 
				LET l_arr_segment[l_idx].flex_code = NULL 
			END IF 
		END IF 
	END FOREACH 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("I",1307,"") 
	#1307 Enter Product Flex Details
	INPUT ARRAY l_arr_segment WITHOUT DEFAULTS FROM sr_segment.* ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","pstrcwin","input-arr-segment") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(flex_code) 
					LET l_winds_text = NULL 
					LET l_winds_text = show_flex_code(p_cmpy, l_rec_class.class_code, 
					l_arr_segment[l_idx].start_num) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_arr_segment[l_idx].flex_code = l_winds_text 
						DISPLAY l_arr_segment[l_idx].flex_code 
						TO sr_segment[l_scrn].flex_code 

					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD flex_code 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			NEXT FIELD scroll_flag 
		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_segment[l_idx].scroll_flag 
			DISPLAY l_arr_segment[l_idx].* TO sr_segment[l_scrn].* 

			NEXT FIELD flex_code 
		BEFORE FIELD flex_code 
			DISPLAY l_arr_segment[l_idx].flex_code TO sr_segment[l_scrn].flex_code 

		AFTER FIELD flex_code 
			IF l_arr_segment[l_idx].flex_code IS NULL THEN 
			ELSE 
				LET l_arr_segment[l_idx].scroll_flag = NULL 
				DISPLAY l_arr_segment[l_idx].scroll_flag 
				TO sr_segment[l_scrn].scroll_flag 

				IF length(l_arr_segment[l_idx].flex_code) > l_arr_segment[l_idx].length 
				THEN 
					LET l_msgresp = kandoomsg("I",9160,l_arr_segment[l_idx].length) 
					#9160 Product Flex Code must NOT be greater than ??? chars
					NEXT FIELD flex_code 
				END IF 
			END IF 
			CASE 
				WHEN fgl_lastkey() = fgl_keyval("RETURN") 
					OR fgl_lastkey() = fgl_keyval("right") 
					OR fgl_lastkey() = fgl_keyval("tab") 
					OR fgl_lastkey() = fgl_keyval("down") 
					IF l_arr_segment[l_idx+1].start_num IS NULL THEN 
						NEXT FIELD NEXT 
					END IF 
				WHEN fgl_lastkey() = fgl_keyval("left") 
					OR fgl_lastkey() = fgl_keyval("up") 
					NEXT FIELD previous 
				WHEN fgl_lastkey() = fgl_keyval("accept") 
				OTHERWISE 
					NEXT FIELD flex_code 
			END CASE 
		AFTER ROW 
			DISPLAY l_arr_segment[l_idx].* TO sr_segment[l_scrn].* 

		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
			ELSE 
				LET l_blank_found = false 
				LET l_last_seq_num = 0 
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_segment[l_idx].flex_code IS NOT NULL THEN 
						LET l_last_seq_num = l_arr_prodstructure[l_idx].seq_num 
						IF l_blank_found THEN 
							LET l_msgresp = kandoomsg("I",9217,"") 
							#9217 No embeded Flex Codes permmited
							NEXT FIELD flex_code 
						END IF 
					ELSE 
						LET l_blank_found = true 
					END IF 
				END FOR 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_part_code = p_orig_part_code 
	ELSE 
		LET l_part_code = NULL 
		LET l_dashs = "---------------" 
		DECLARE c_prodstructure2 CURSOR FOR 
		SELECT * FROM prodstructure 
		WHERE cmpy_code = p_cmpy 
		AND class_code = l_class_code 
		ORDER BY seq_num 
		OPEN c_prodstructure2 
		FETCH c_prodstructure2 INTO l_rec_prodstructure.* 
		IF status != notfound THEN 
			IF l_rec_prodstructure.seq_num <= l_last_seq_num THEN 
				IF l_rec_prodstructure.type_ind = "F" THEN 
					LET l_length = l_rec_prodstructure.length 
					LET l_part_code = l_dashs[1,l_length] 
					LET l_part_length = l_length 
				ELSE 
					FOR l_idx = 1 TO 99 
						IF l_rec_prodstructure.seq_num = l_arr_prodstructure[l_idx].seq_num 
						THEN 
							LET l_part_code = l_arr_segment[l_idx].flex_code 
							LET l_part_length = l_rec_prodstructure.length 
						END IF 
					END FOR 
				END IF 
			END IF 
			WHILE true 
				FETCH c_prodstructure2 INTO l_rec_prodstructure.* 
				IF status != notfound THEN 
					IF l_rec_prodstructure.seq_num <= l_last_seq_num THEN 
						IF l_rec_prodstructure.type_ind = "F" THEN 
							LET l_length = l_rec_prodstructure.length 
							LET l_part_code = l_part_code[1,l_part_length], 
							l_dashs[1,l_length] 
							LET l_part_length = l_part_length + l_length 
						ELSE 
							FOR l_idx = 1 TO 99 
								IF l_rec_prodstructure.seq_num 
								= l_arr_prodstructure[l_idx].seq_num 
								THEN 
									LET l_part_code = l_part_code[1,l_part_length], 
									l_arr_segment[l_idx].flex_code 
									LET l_part_length 
									= l_part_length + l_arr_segment[l_idx].length 
								END IF 
							END FOR 
						END IF 
					END IF 
				ELSE 
					EXIT WHILE 
				END IF 
			END WHILE 
		END IF 
	END IF 
	CLOSE WINDOW w169 
	RETURN l_rec_class.class_code, l_part_code 
END FUNCTION 

FUNCTION class_input(p_cmpy,p_class_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_class_code LIKE class.class_code 
	DEFINE l_msgresp LIKE language.yes_flag
	DEFINE l_rec_class RECORD LIKE class.* 
	DEFINE l_winds_text CHAR(40) 

	INITIALIZE l_rec_class.* TO NULL 
	IF p_class_code IS NOT NULL THEN 
		SELECT * INTO l_rec_class.* FROM class 
		WHERE class_code = p_class_code 
		AND p_cmpy = cmpy_code 
	END IF 
	DISPLAY p_class_code, 
	l_rec_class.desc_text 
	TO class_code, 
	class_desc 

	INPUT BY NAME l_rec_class.class_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","pstrcwin","input-class_code") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" #ON KEY (control-b) 
			CASE 
				WHEN infield(class_code) 
					LET l_winds_text = NULL 
					LET l_winds_text = show_pcls(p_cmpy) 
					IF l_winds_text IS NOT NULL THEN 
						LET l_rec_class.class_code = l_winds_text 
						DISPLAY BY NAME l_rec_class.class_code 

					END IF 
					OPTIONS INSERT KEY f1, 
					DELETE KEY f36 
					NEXT FIELD class_code 
			END CASE 
		AFTER FIELD class_code 
			IF l_rec_class.class_code IS NULL THEN 
			ELSE 
				SELECT * INTO l_rec_class.* FROM class 
				WHERE cmpy_code = p_cmpy 
				AND class_code = l_rec_class.class_code 
				IF status = notfound THEN 
					LET l_msgresp=kandoomsg("I",9041,"") 
					#9041 "Inventory Class NOT found - Try Window"
					NEXT FIELD class_code 
				ELSE 
					DISPLAY l_rec_class.desc_text 
					TO class_desc 

				END IF 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET l_rec_class.class_code = NULL 
	END IF 
	RETURN l_rec_class.class_code 
END FUNCTION 


