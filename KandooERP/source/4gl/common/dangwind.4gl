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



#
#     dangwind.4gl - show_dangclass
#                    Window FUNCTION FOR finding Dangerous Class Codes
#                    FUNCTION will RETURN a Dangerous Class Code
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_dangclass(p_cmpy,p_filter_text)
#
# Window FUNCTION FOR finding Dangerous Class Codes
# FUNCTION will RETURN a Dangerous Class Code
############################################################
FUNCTION show_dangclass(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_dangerclass RECORD LIKE dangerclass.* 
	DEFINE l_arr_rec_dangerclass array[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					class_code LIKE dangerclass.class_code, 
					desc_text LIKE dangerclass.desc_text 
			   END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(220) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	OPEN WINDOW i655 with FORM "I655" 
	CALL windecoration_i("I655") -- albo kd-758 

	# --------------------------------------------------------------------------------------------------------------------
	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON class_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","dangwind","construct-class") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_dangerclass.class_code = NULL 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * ", 
		"FROM dangerclass ", 
		"WHERE ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY dangerclass.class_code" 

		PREPARE s_dangerclass FROM l_query_text 
		DECLARE c_dangerclass CURSOR FOR s_dangerclass 

		LET l_idx = 0 
		FOREACH c_dangerclass INTO l_rec_dangerclass.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_dangerclass[l_idx].class_code = l_rec_dangerclass.class_code 
			LET l_arr_rec_dangerclass[l_idx].desc_text = l_rec_dangerclass.desc_text 
			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",1505,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("U",1021,"") 
			#1021 No rows satisfied selection criteria
			LET l_idx = 1 
			INITIALIZE l_arr_rec_dangerclass[1].* TO NULL 
		END IF 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		INPUT ARRAY l_arr_rec_dangerclass WITHOUT DEFAULTS FROM sr_dangerclass.* ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","dangwind","input-arr-dangerclass") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#IF l_arr_rec_dangerclass[l_idx].class_code IS NOT NULL THEN
				#   DISPLAY l_arr_rec_dangerclass[l_idx].* TO sr_dangerclass[scrn].*
				#END IF
				NEXT FIELD scroll_flag 

			ON KEY (F10) 
				CALL run_prog("IE1","","","","") 
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_dangerclass[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD class_code 
				LET l_rec_dangerclass.class_code = l_arr_rec_dangerclass[l_idx].class_code 
				EXIT INPUT 

				#AFTER ROW
				#	DISPLAY l_arr_rec_dangerclass[l_idx].* TO sr_dangerclass[scrn].*

			AFTER INPUT 
				LET l_rec_dangerclass.class_code = l_arr_rec_dangerclass[l_idx].class_code 
		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 

	END WHILE 

	CLOSE WINDOW i655 

	RETURN l_rec_dangerclass.class_code 
END FUNCTION 


############################################################
# FUNCTION show_proddanger(p_cmpy,p_filter_text)
#
# Show the Danger Product Codes
############################################################
FUNCTION show_proddanger(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_proddanger RECORD LIKE proddanger.* 
	DEFINE l_arr_rec_proddanger array[100] OF 
				RECORD 
					scroll_flag CHAR(1), 
					dg_code LIKE proddanger.dg_code, 
					tech_text LIKE proddanger.tech_text 
				END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	OPEN WINDOW i656 with FORM "I656" 
	CALL windecoration_i("I656") -- albo kd-758 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON dg_code, tech_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","dangwind","construct-proddanger") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_proddanger.dg_code = NULL 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"") 
		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * ", 
		"FROM proddanger ", 
		"WHERE cmpy_code = \"", p_cmpy, "\" ", 
		"AND ", l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY cmpy_code, dg_code" 

		PREPARE s_proddanger FROM l_query_text 
		DECLARE c_proddanger CURSOR FOR s_proddanger 

		LET l_idx = 0 
		FOREACH c_proddanger INTO l_rec_proddanger.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_proddanger[l_idx].dg_code = l_rec_proddanger.dg_code 
			LET l_arr_rec_proddanger[l_idx].tech_text = l_rec_proddanger.tech_text 

			IF l_idx = 100 THEN 
				LET l_msgresp = kandoomsg("U",1505,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF l_idx = 0 THEN 
			LET l_msgresp = kandoomsg("U",1021,"") 
			#1021 No rows satisfied selection criteria
			LET l_idx = 1 
			INITIALIZE l_arr_rec_proddanger[1].* TO NULL 
		END IF 

		LET l_msgresp = kandoomsg("U",1006,"") 
		#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 

		INPUT ARRAY l_arr_rec_proddanger WITHOUT DEFAULTS FROM sr_proddanger.* 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","dangwind","input-arr-proddanger") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				NEXT FIELD scroll_flag 

			ON KEY (F10) 
				CALL run_prog("IE2","","","","") 
				NEXT FIELD scroll_flag 

			AFTER FIELD scroll_flag 
				LET l_arr_rec_proddanger[l_idx].scroll_flag = NULL 
				IF fgl_lastkey() = fgl_keyval("down") 
				AND arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					NEXT FIELD scroll_flag 
				END IF 

			BEFORE FIELD dg_code 
				LET l_rec_proddanger.dg_code = l_arr_rec_proddanger[l_idx].dg_code 
				EXIT INPUT 

			AFTER INPUT 
				LET l_rec_proddanger.dg_code = l_arr_rec_proddanger[l_idx].dg_code 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW i656 

	RETURN l_rec_proddanger.dg_code 
END FUNCTION 


