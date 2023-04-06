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

##############################################################
#     wrgrpwin.4gl - show_waregrp
#                    Window FUNCTION FOR finding waregrp records
#                    FUNCTION will RETURN waregrp_code TO calling program
##############################################################

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

##############################################################
# show_waregrp(p_cmpy,filter_text)
#
#
##############################################################
FUNCTION select_waregrp(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE l_arr_rec_waregrp DYNAMIC ARRAY OF t_rec_waregrp_wc_nt_with_scrollflag 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			waregrp_code, 
			name_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wgrpwin","construct-waregrp") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_waregrp.waregrp_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM waregrp ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY waregrp_code" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE s_waregrp FROM l_query_text 

	DECLARE c_waregrp CURSOR FOR s_waregrp 

	LET l_idx = 0 
	FOREACH c_waregrp INTO l_rec_waregrp.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_waregrp[l_idx].waregrp_code = l_rec_waregrp.waregrp_code 
		LET l_arr_rec_waregrp[l_idx].name_text = l_rec_waregrp.name_text 
		--IF l_idx = 100 THEN 
		--	LET l_msgresp = kandoomsg("U",6100,l_idx) 
		--	EXIT FOREACH 
		--END IF 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_waregrp.getLength())	#9113 l_idx records selected
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_waregrp[1].* TO NULL 
	END IF 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN l_arr_rec_waregrp 
END FUNCTION 
##############################################################
# END show_waregrp(p_cmpy,filter_text)
##############################################################


##############################################################
# FUNCTION show_waregrp()
#
#
##############################################################
FUNCTION show_waregrp()
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_waregrp RECORD LIKE waregrp.* 
	DEFINE l_arr_rec_waregrp DYNAMIC ARRAY OF t_rec_waregrp_wc_nt_with_scrollflag 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW W339 with FORM "W339" 
	CALL windecoration_w("W339") -- albo kd-758 

	IF db_waregrp_get_count() > 1000 THEN 
		CALL select_waregrp(true) RETURNING l_arr_rec_waregrp 
	ELSE 
		CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 
	END IF 

	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_waregrp[1].* TO NULL
	#      END IF
	#
	LET l_msgresp = kandoomsg("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"
	#      CALL set_count(l_idx)

	#	INPUT ARRAY l_arr_rec_waregrp WITHOUT DEFAULTS FROM sr_waregrp.*
	DISPLAY ARRAY l_arr_rec_waregrp TO sr_waregrp.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wordwin","input-arr-waregrp") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_waregrp.* = l_arr_rec_waregrp[l_idx].* 

		ON KEY (F10) 
			CALL run_prog("IZF","","","","") 
			CALL select_waregrp(false) RETURNING l_arr_rec_waregrp 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW E339 

	RETURN l_rec_waregrp.waregrp_code 
END FUNCTION
##############################################################
# FUNCTION show_waregrp()
##############################################################