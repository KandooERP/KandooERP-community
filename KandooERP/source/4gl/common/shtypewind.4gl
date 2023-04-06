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

	Source code beautified by beautify.pl on 2020-01-02 10:35:35	$Id: $
}



# show_type - window FUNCTION FOR Shipment Type Code

GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION show_type(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_shiptype ARRAY[100] OF RECORD 
		ship_type_code LIKE shiptype.ship_type_code, 
		desc_text LIKE shiptype.desc_text 
	END RECORD 
	DEFINE l_idx, l_cnt, l_scrn SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 

	OPEN WINDOW l133 with FORM "L133" 
	CALL windecoration_l("L133") -- albo kd-752 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 "Enter Selection Criteria; OK TO Continue
	CONSTRUCT l_where_text ON ship_type_code, 
	desc_text 
	FROM sr_shiptype[1].* 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","shtypewind","construct-ship_type_code") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
	END CONSTRUCT 


	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW l133 
		RETURN "" 
	END IF 
	LET l_query_text = "SELECT ship_type_code, desc_text ", 
	" FROM shiptype WHERE ", 
	" cmpy_code = '", p_cmpy, "' AND ", 
	l_where_text CLIPPED, 
	" ORDER BY ship_type_code " 
	PREPARE s_shiptype FROM l_query_text 
	DECLARE c_shiptype CURSOR FOR s_shiptype 
	LET l_idx = 1 
	FOREACH c_shiptype INTO l_arr_shiptype[l_idx].* 
		LET l_idx = l_idx + 1 
		IF l_idx = 100 THEN 
			LET l_msgresp = kandoomsg("U",6100,l_idx) 
			#6100 First l_idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	LET l_cnt = l_idx 
	CALL set_count(l_idx) 
	LET l_msgresp = kandoomsg("U",1006,"") 
	#1006 Press OK on Line TO SELECT; F10 TO Add.
	INPUT ARRAY l_arr_shiptype WITHOUT DEFAULTS FROM sr_shiptype.* 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","shtypewind","input-arr-shiptype") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F10) 
			CALL run_prog("LZ3","","","","") 
		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scrn = scr_line() 
			DISPLAY l_arr_shiptype[l_idx].* TO sr_shiptype[l_scrn].* 

		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_shiptype[l_idx+1].ship_type_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD ship_type_code 
				END IF 
			END IF 
			DISPLAY l_arr_shiptype[l_idx].* TO sr_shiptype[l_scrn].* 


	END INPUT 
	LET l_idx = arr_curr() 
	CLOSE WINDOW l133 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN "" 
	END IF 
	RETURN l_arr_shiptype[l_idx].ship_type_code 
END FUNCTION 


