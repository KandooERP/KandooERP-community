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
#        ref_wind.4gl - show_ref
#                       windows functions TO show userref table
#                       returns ref_code
###########################################################################

###########################################################################
# FUNCTION show_ref(p_cmpy,p_source_ind,p_number_ind) 
#
#
###########################################################################
FUNCTION show_ref(p_cmpy,p_source_ind,p_number_ind) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_source_ind LIKE userref.source_ind 
	DEFINE p_number_ind LIKE userref.ref_ind 
	DEFINE l_rec_userref RECORD LIKE userref.* 
	DEFINE l_arr_userref DYNAMIC ARRAY OF RECORD
			scroll_flag CHAR(1), 
			ref_code LIKE userref.ref_code, 
			ref_desc_text LIKE userref.ref_desc_text 
		END RECORD 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_header_text_text CHAR(20) 
	DEFINE l_prompt_text CHAR(20) 
	DEFINE l_idx,l_scrn SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CASE p_source_ind 
		WHEN "A" 
			LET l_query_text = "SELECT ref",p_number_ind,"_text ", 
			"FROM arparms ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND parm_code = \"1\" " 
		WHEN "I" 
			LET l_query_text = "SELECT ref",p_number_ind,"_text ", 
			"FROM inparms ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND parm_code = \"1\" " 
		WHEN "W" 
			LET l_query_text = "SELECT ref",p_number_ind,"_text ", 
			"FROM mbparms ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" " 
		OTHERWISE 
			RETURN "" 
	END CASE 
	
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s1_userref FROM l_query_text 
	DECLARE c1_userref CURSOR FOR s1_userref 

	OPEN c1_userref 
	FETCH c1_userref INTO l_prompt_text 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	IF status < 0 THEN 
		RETURN "" 
	END IF 
	IF l_prompt_text IS NULL THEN 
		LET l_prompt_text = "Report Code #",p_number_ind 
	END IF 
	LET l_idx = 21 - length(l_prompt_text) 
	LET l_header_text_text[l_idx,20] = l_prompt_text CLIPPED 

	OPEN WINDOW U139 with FORM "U139" 
	CALL windecoration_u("U139") -- albo kd-758 
	WHILE true 
		CLEAR FORM 
		DISPLAY l_prompt_text, l_header_text_text 
		TO prompt_text, heading_text 

		LET l_msgresp=kandoomsg("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON ref_code,	ref_desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ref_wind","construct-userref") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_idx = 1 
			INITIALIZE l_arr_userref[1].* TO NULL 
			EXIT WHILE 
		END IF 
		LET l_query_text = "SELECT * FROM userref ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND source_ind = \"",p_source_ind,"\" ", 
		"AND ref_ind = \"",p_number_ind,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY ref_code" 
		
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON
		 
		PREPARE s2_userref FROM l_query_text 
		DECLARE c2_userref CURSOR FOR s2_userref 
		LET l_idx = 0 
		FOREACH c2_userref INTO l_rec_userref.* 
			LET l_idx = l_idx + 1 
			LET l_arr_userref[l_idx].ref_code = l_rec_userref.ref_code 
			LET l_arr_userref[l_idx].ref_desc_text = l_rec_userref.ref_desc_text 
			IF l_idx = 200 THEN 
				LET l_msgresp=kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		
		LET l_msgresp = kandoomsg("U",9113,l_idx)		#U9113 l_idx records selected
		IF l_idx=0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_userref[1].* TO NULL 
		END IF 

		CALL set_count(l_idx) 
		LET l_msgresp=kandoomsg("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"
		INPUT ARRAY l_arr_userref WITHOUT DEFAULTS FROM sr_userref.* 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ref_wind","input-arr-userref") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_scrn = scr_line() 
				IF l_arr_userref[l_idx].ref_code IS NOT NULL THEN 
					DISPLAY l_arr_userref[l_idx].* TO sr_userref[l_scrn].* 

				END IF 
				NEXT FIELD scroll_flag
				 
			ON KEY (F10) 
				CALL run_prog("U1D","","","","") 
				NEXT FIELD scroll_flag
				 
			AFTER FIELD scroll_flag 
				LET l_arr_userref[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF
				 
			BEFORE FIELD ref_code 
				LET l_rec_userref.ref_code = l_arr_userref[l_idx].ref_code 
				EXIT INPUT
				 
			AFTER ROW 
				DISPLAY l_arr_userref[l_idx].* TO sr_userref[l_scrn].* 

			AFTER INPUT 
				LET l_rec_userref.ref_code = l_arr_userref[l_idx].ref_code 

		END INPUT
		 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	
	CLOSE WINDOW U139 
	RETURN l_rec_userref.ref_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_ref(p_cmpy,p_source_ind,p_number_ind) 
###########################################################################