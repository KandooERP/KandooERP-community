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

	Source code beautified by beautify.pl on 2020-01-02 10:35:36	$Id: $
}



#FUNCTION strucdwind - displays the break up of the general ledger accounts

GLOBALS "../common/glob_GLOBALS.4gl" 
FUNCTION strucdwind(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_structure RECORD LIKE structure.*
	DEFINE l_arr_structure ARRAY[10] OF RECORD 
		start_num LIKE structure.start_num, 
		length_num LIKE structure.length_num, 
		desc_text LIKE structure.desc_text 
	END RECORD 
	DEFINE l_idx, l_scrn INTEGER 
	DEFINE r_start_num LIKE structure.start_num

	OPEN WINDOW wg174 with FORM "G174" 
	--huho attribute (border)
	CALL windecoration_g("G174") --populate WINDOW FORM elements 

	DECLARE structurecurs CURSOR FOR 

	SELECT * INTO l_rec_structure.* FROM structure 
	WHERE cmpy_code = p_cmpy 
	AND start_num > 0 
	AND (type_ind = "S" OR type_ind = "C" OR type_ind = "L") -- albo kd-1216 
	ORDER BY start_num 

	FOR l_idx = 1 TO 10 
		INITIALIZE l_arr_structure[l_idx].* TO NULL 
	END FOR 

	LET l_idx = 0 
	FOREACH structurecurs 
		LET l_idx = l_idx + 1 
		LET l_arr_structure[l_idx].desc_text = l_rec_structure.desc_text 
		LET l_arr_structure[l_idx].start_num = l_rec_structure.start_num 
		LET l_arr_structure[l_idx].length_num = l_rec_structure.length_num 
	END FOREACH 

	IF l_idx > 0 THEN 
		LET l_msgresp = kandoomsg("U",1019,"") 
		#1019 Press OK on line TO SELECT
		CALL set_count(l_idx) 

		INPUT ARRAY l_arr_structure WITHOUT DEFAULTS FROM sr_structure.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","strucdwind","input-arr-structure") 
				--CALL publish_toolbar("kandoo","strucdwind","segmentSearcher") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				
			AFTER ROW 
				IF fgl_lastkey() = fgl_keyval("down") 
				OR fgl_lastkey() = fgl_keyval("RETURN") 
				OR fgl_lastkey() = fgl_keyval("tab") 
				OR fgl_lastkey() = fgl_keyval("right") THEN 
					IF l_arr_structure[l_idx+1].start_num IS NULL 
					OR arr_curr() >= arr_count() THEN 
						LET l_msgresp=kandoomsg("U",9001,"") 
						#9001 There no more rows...
						NEXT FIELD start_num 
					END IF 
				END IF 
				LET r_start_num = l_arr_structure[l_idx].start_num 

		END INPUT 
		
	ELSE 
		LET l_msgresp = kandoomsg("G",9534,"") 
		#9534 GL Account Structure has NOT been defined. Refer TO Menu Option GZ3.
	END IF 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET r_start_num = NULL 
	END IF 
	
	CLOSE WINDOW wg174 
	
	RETURN r_start_num 
END FUNCTION 


