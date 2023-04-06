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

	Source code beautified by beautify.pl on 2020-01-02 10:35:14	$Id: $
}



#     gundshow.4gl - show_txttype
#                    window FUNCTION FOR finding txttype records
#                    returns txttype_id
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


FUNCTION show_txttype(p_txttype_id) 
	DEFINE p_txttype_id LIKE txttype.txttype_id 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_txttype RECORD LIKE txttype.* 
	DEFINE l_arr_txttype array[100] OF RECORD 
				scroll_flag CHAR(1), 
				txttype_id LIKE txttype.txttype_id, 
				txttype_desc LIKE txttype.txttype_desc 
			 END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW g508 with FORM "G508" 
	CALL windecoration_g("G525") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON txttype_id, 
		txttype_desc 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","gundshow","construct-txttype") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_txttype.txttype_id = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM txttype ", 
		"WHERE ",l_where_text CLIPPED," ", 
		"ORDER BY txttype_id" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_txttype FROM l_query_text 
		DECLARE c_txttype CURSOR FOR s_txttype 
		LET l_idx = 0 
		FOREACH c_txttype INTO l_rec_txttype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_txttype[l_idx].txttype_id = l_rec_txttype.txttype_id 
			LET l_arr_txttype[l_idx].txttype_desc = l_rec_txttype.txttype_desc 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_txttype[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		LET l_msgresp = kandoomsg("U",1019,"") 
		#1019 "Press ESC on line TO SELECT"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_txttype WITHOUT DEFAULTS FROM sr_txttype.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","gundshow","input-arr-txttype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_txttype[l_idx].txttype_id IS NOT NULL THEN 
					DISPLAY l_arr_txttype[l_idx].* TO sr_txttype[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag 
			AFTER FIELD scroll_flag 
				LET l_arr_txttype[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD txttype_id 
				LET l_rec_txttype.txttype_id = l_arr_txttype[l_idx].txttype_id 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_txttype[l_idx].* TO sr_txttype[l_scrn].* 

			AFTER INPUT 
				LET l_rec_txttype.txttype_id = l_arr_txttype[l_idx].txttype_id 

		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW g508 
	RETURN l_rec_txttype.txttype_id 
END FUNCTION 


