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
##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

############################################################
#   terrwind.4gl - show_territory
#                  Window FUNCTION FOR finding a Sales territory
#                  FUNCTION will RETURN terr_code TO calling program
############################################################


############################################################
# FUNCTION select_territory(p_filter)
#
#  	RETURN l_arr_rec_territory
############################################################
FUNCTION select_territory(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF t_rec_territorytax_tc_dt_ac_with_scrollflag 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 

		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON terr_code, 
		desc_text, 
		area_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","terrwind","construct-territory") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_territory.terr_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"") #1002 " Searching database - please wait"
	LET l_query_text = "SELECT * FROM territory ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	#                          "AND ",filter_text clipped," ",
	"ORDER BY terr_code" 
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE s_territory FROM l_query_text 
	DECLARE c_territory CURSOR FOR s_territory 

	LET l_idx = 0 
	FOREACH c_territory INTO l_rec_territory.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_territory[l_idx].terr_code = l_rec_territory.terr_code 
		LET l_arr_rec_territory[l_idx].desc_text = l_rec_territory.desc_text 
		LET l_arr_rec_territory[l_idx].area_code = l_rec_territory.area_code

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx)	#9113 "l_idx records selected"
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN l_arr_rec_territory 
END FUNCTION 
############################################################
# END FUNCTION select_territory(p_filter)
############################################################


############################################################
# FUNCTION show_territory(p_cmpy,filter_text)
#
#
############################################################
FUNCTION show_territory(p_cmpy,filter_text)
	DEFINE p_cmpy LIKE company.cmpy_code
	DEFINE filter_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF t_rec_territorytax_tc_dt_ac_with_scrollflag 
	#		RECORD
	#         scroll_flag CHAR(1),
	#         terr_code LIKE territory.terr_code,
	#         desc_text LIKE territory.desc_text,
	#         area_code LIKE territory.area_code
	#      END RECORD
	DEFINE l_idx SMALLINT 

	#	DEFINE filter_text STRING

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW A611 with FORM "A611" 
	CALL windecoration_a("A611") 

	IF db_territory_get_count() > 1000 THEN 
		CALL select_territory(true) RETURNING l_arr_rec_territory 
	ELSE 
		CALL select_territory(false) RETURNING l_arr_rec_territory 
	END IF 


	#	IF l_arr_rec_territory.getLength() = 0 THEN
	#		LET l_idx = 1
	#		INITIALIZE l_arr_rec_territory[1].* TO NULL
	#	END IF


	LET l_msgresp = kandoomsg("U",1006,"") 
	#1006 " ESC on line TO SELECT - F10 TO Add"

	#INPUT ARRAY l_arr_rec_territory WITHOUT DEFAULTS FROM sr_territory.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_territory TO sr_territory.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","terrwind","input-arr-territory") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_idx > 0 THEN 
				LET l_rec_territory.terr_code = l_arr_rec_territory[l_idx].terr_code 
			END IF 

		ON KEY (F10) 
			CALL run_prog("AZT","","","","") 
			CALL select_territory(false) RETURNING l_arr_rec_territory 


	END DISPLAY 
	#########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	CLOSE WINDOW A611 

	RETURN l_rec_territory.terr_code 
END FUNCTION 
############################################################
# FUNCTION show_territory(p_cmpy,filter_text)
############################################################