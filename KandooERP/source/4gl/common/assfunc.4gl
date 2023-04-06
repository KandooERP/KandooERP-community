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

	Source code beautified by beautify.pl on 2020-01-02 10:35:04	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module : assfunc.4gl
# Purpose : used FOR lookups of asset codes AND addition of new ones
#
GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION lookup_famast(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE r_arr_pa_famast array[50] OF RECORD 
		asset_code LIKE famast.asset_code, 
		add_on_code LIKE famast.add_on_code, 
		desc_text LIKE famast.desc_text 
	END RECORD 
	#l_msgresp LIKE language.yes_flag,
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 

	OPEN WINDOW wf107 with FORM "F107" 
	CALL winDecoration_f("F107") -- albo kd-767 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 Enter selection criteria - ESC TO Continue
		CONSTRUCT BY NAME l_where_part ON famast.asset_code, 
		famast.add_on_code, 
		famast.desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","assfunc","construct-asset") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 Searching Database - Please Wait
		LET l_query_text = "SELECT asset_code, add_on_code, desc_text", 
		" FROM famast", 
		" WHERE cmpy_code = \"", p_cmpy,"\"", 
		" AND ", l_where_part clipped, 
		" ORDER BY asset_code " 
		PREPARE choice1 FROM l_query_text 
		DECLARE selcurs1 CURSOR FOR choice1 
		LET l_idx = 1 
		FOREACH selcurs1 INTO r_arr_pa_famast[l_idx].* 
			LET l_idx = l_idx + 1 
			IF l_idx > 50 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx-1) 
				#6100 First l_idx RECORDs selected only
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_idx = l_idx - 1 
		LET l_msgresp = kandoomsg("U",9113,l_idx) 
		#9113 l_idx RECORDs selected
		IF l_idx > 0 THEN 
			LET l_cnt = l_idx 
			CALL set_count(l_idx) 
			LET l_msgresp = kandoomsg("U",1019,"") 

			#1019 Press ESC on line TO SELECT
			INPUT ARRAY r_arr_pa_famast WITHOUT DEFAULTS FROM sr_famast.* 

				BEFORE INPUT 
					CALL publish_toolbar("kandoo","assfunc","input-arr-famast") 


				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_scrn = scr_line() 
				BEFORE FIELD desc_text 
					NEXT FIELD asset_code 

			END INPUT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	LET l_idx = arr_curr() 
	CLOSE WINDOW wf107 
	IF l_idx > 0 THEN 
		RETURN r_arr_pa_famast[l_idx].asset_code, r_arr_pa_famast[l_idx].add_on_code 
	ELSE 
		RETURN " "," " 
	END IF 
END FUNCTION 


