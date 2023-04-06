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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION show_cond(p_cmpy,p_filter_text)
#
#   condwind.4gl - show_cond
#                  Window FUNCTION FOR finding a Sales Condition record
#                  returns cond_code
############################################################
FUNCTION show_cond(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_arr_condsale DYNAMIC ARRAY OF
		RECORD 
			scroll_flag CHAR(1), 
			cond_code LIKE condsale.cond_code, 
			desc_text LIKE condsale.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048)
 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		IF p_filter_text IS NULL THEN 
			LET p_filter_text = "1=1" 
		END IF 

		OPEN WINDOW e107 with FORM "E107" 
		CALL windecoration_e("E107") 

		WHILE true 
			CLEAR FORM 
			MESSAGE kandoomsg2("U",1001,"")			#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON cond_code, desc_text 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","condwind","construct-condsale") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_condsale.cond_code = NULL 
				EXIT WHILE 
			END IF 

			MESSAGE kandoomsg2("U",1002,"")			#1002 " Searching database - please wait"

			LET l_query_text = "SELECT * FROM condsale ", 
			"WHERE cmpy_code = \"",p_cmpy,"\" ", 
			"AND ",l_where_text CLIPPED," ", 
			"AND ",p_filter_text CLIPPED," ", 
			"ORDER BY cond_code" 

			PREPARE s_condsale FROM l_query_text 
			DECLARE c_condsale CURSOR FOR s_condsale 

			LET l_idx = 0 
			FOREACH c_condsale INTO l_rec_condsale.* 
				LET l_idx = l_idx + 1 
				LET l_arr_condsale[l_idx].cond_code = l_rec_condsale.cond_code 
				LET l_arr_condsale[l_idx].desc_text = l_rec_condsale.desc_text 
			END FOREACH 
			
			ERROR kandoomsg2("U",9113,l_idx)			#U9113 l_idx records selected

			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_condsale[1].* TO NULL 
			END IF 

			MESSAGE kandoomsg2("U",1006,"")		#1006 " ESC on line TO SELECT - F10 TO Add"

			DISPLAY ARRAY l_arr_condsale TO sr_condsale.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","condwind","input-arr-condsale") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_rec_condsale.cond_code = l_arr_condsale[l_idx].cond_code

				ON ACTION "Sales Conditions Maintenance" --ON KEY (F10) 
					CALL run_prog("E71","","","","") 

			END DISPLAY

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 

		CLOSE WINDOW e107 

		RETURN l_rec_condsale.cond_code 
END FUNCTION 
############################################################
# END FUNCTION show_cond(p_cmpy,p_filter_text)
############################################################