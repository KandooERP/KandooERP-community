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
	Source code beautified by beautify.pl on 2020-01-02 10:35:10	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_description(p_cmpy)
#
#       descwind.4gl - window FUNCTION show_description
#                      TO find product description
############################################################
FUNCTION show_description(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_jmpo_desc RECORD LIKE jmpo_description.* 
	DEFINE l_arr_rec_jmpo_desc ARRAY[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					po_description CHAR(40) 
				END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT 
	DEFINE l_query_text CHAR (2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 


	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW r608 with FORM "R608" 
	CALL winDecoration_r("R608") -- albo kd-756 
	WHILE true 
		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"") 
		#1001 " Enter criteria - press ESC TO continue"
		CONSTRUCT BY NAME l_where_text ON po_description 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","descwind","construct-jmpo_description") 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 



		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_jmpo_desc.po_description = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp=kandoomsg("U",1002,"") 
		LET l_query_text = "SELECT jmpo_description.* FROM jmpo_description ", 
		"WHERE cmpy_code = ","'",p_cmpy,"'", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY 1,2" 
		LET l_idx = 0 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_description FROM l_query_text 
		DECLARE c_description CURSOR FOR s_description 
		FOREACH c_description INTO l_rec_jmpo_desc.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_jmpo_desc[l_idx].po_description = l_rec_jmpo_desc.po_description 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("R",9506,"100") 
				#9506 " Only first 100 lines selected only"
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp=kandoomsg("U",9113,l_idx) 
		#9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("R",9002,"") 
			#9002 No rows satisfied selection criteria
			LET l_idx = 1 
			INITIALIZE l_arr_rec_jmpo_desc[1].* TO NULL 
		END IF 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("U",1006,"") 
		#U1006 "Esc on line TO SELECT - F10 TO add"
		INPUT ARRAY l_arr_rec_jmpo_desc WITHOUT DEFAULTS FROM sr_jmpo_desc.* ATTRIBUTE(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","descwind","input-arr-jmpo_desc") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON KEY (F10) 
				CALL run_prog("RZ5","","","","") 
			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_idx <= arr_count() THEN 
					DISPLAY l_arr_rec_jmpo_desc[l_idx].* TO sr_jmpo_desc[l_scrn].* 

				END IF 
			AFTER FIELD scroll_flag 
				LET l_arr_rec_jmpo_desc[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 
			BEFORE FIELD po_description 
				LET l_rec_jmpo_desc.po_description = l_arr_rec_jmpo_desc[l_idx].po_description 
				EXIT INPUT 
			AFTER ROW 
				DISPLAY l_arr_rec_jmpo_desc[l_idx].* TO sr_jmpo_desc[l_scrn].* 


		END INPUT 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			LET l_rec_jmpo_desc.po_description = l_arr_rec_jmpo_desc[l_idx].po_description 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW r608 

	RETURN l_rec_jmpo_desc.po_description 
END FUNCTION 


