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

	Source code beautified by beautify.pl on 2020-01-02 10:35:18	$Id: $
}



# locfunc.4gl used FOR lookups of locations AND addition of new ones

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION lookup_location(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_falocation ARRAY[60] OF  
             RECORD
		          location_code LIKE falocation.location_code, 
		          location_text LIKE falocation.location_text 
	          END RECORD 
	DEFINE l_idx, l_scrn SMALLINT 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200)
	DEFINE r_location_code LIKE falocation.location_code	

	OPEN WINDOW f117 with FORM "F117" 
	CALL winDecoration_f("F117") -- albo kd-767 

	WHILE TRUE 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria - OK TO Continue
		CONSTRUCT l_where_part ON falocation.location_code, 
		falocation.location_text 
		FROM sr_falocation[1].* 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","locfunc","construct-falocation") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			OPTIONS INSERT KEY f1, 
			DELETE KEY f2 
			CLOSE WINDOW f117 
			RETURN " " 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database - Please Wait.
		LET l_query_text = " SELECT location_code, location_text ", 
		" FROM falocation ", 
		" WHERE cmpy_code = \"", p_cmpy,"\" AND ", 
		l_where_part CLIPPED, 
		" ORDER BY location_code " 
		PREPARE s_falocation FROM l_query_text 
		DECLARE c_falocation CURSOR FOR s_falocation 
		LET l_idx = 1 
		FOREACH c_falocation INTO l_arr_falocation[l_idx].* 
			LET l_idx = l_idx + 1 
			IF l_idx > 50 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx-1) 
				#6100 First l_idx records selected
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_idx = l_idx - 1 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 First l_idx records selected
		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("F",8008,"") 
			#8008 "No loaction satisfied selection criteria - Add (y/n)"
			LET l_msgresp = upshift(l_msgresp) 
			IF l_msgresp = "Y" THEN 
				CALL run_prog("F32","","","","") 
				CONTINUE WHILE 
			END IF 
		ELSE 
			CALL set_count(l_idx) 
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 

			LET l_msgresp = kandoomsg("U",1006,"") 
			#1006 Press OK on line TO SELECT; F10 TO Add.
			INPUT ARRAY l_arr_falocation WITHOUT DEFAULTS FROM sr_falocation.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","locfunc","input-arr-falocation") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON KEY (F10) 
					CALL run_prog("F32","","","","") 
				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_scrn = scr_line() 
					LET r_location_code = l_arr_falocation[l_idx].location_code 
					DISPLAY l_arr_falocation[l_idx].* TO sr_falocation[l_scrn].* 

				AFTER ROW 
					IF fgl_lastkey() = fgl_keyval("down") THEN 
						IF l_arr_falocation[l_idx+1].location_code IS NULL 
						OR arr_curr() >= arr_count() THEN 
							LET l_msgresp=kandoomsg("W",9001,"") 
							#9001 There no more rows...
							NEXT FIELD location_code 
						END IF 
					END IF 
					DISPLAY l_arr_falocation[l_idx].* TO sr_falocation[l_scrn].* 

				BEFORE FIELD location_text 
					NEXT FIELD location_code 

			END INPUT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET r_location_code = " " 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 
	END WHILE 
	OPTIONS INSERT KEY f1, 
	DELETE KEY f2 
	CLOSE WINDOW f117 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	RETURN r_location_code 
END FUNCTION 



