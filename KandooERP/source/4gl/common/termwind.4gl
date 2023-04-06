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
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"

###########################################################################
# FUNCTION scan_term(p_filter)
#
#
###########################################################################
FUNCTION scan_term(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_arr_rec_term DYNAMIC ARRAY OF t_rec_term_tc_dt_with_scrollflag 
	DEFINE l_idx SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON term_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","termwind","construct-term") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_term.term_code = NULL 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	MESSAGE kandoomsg2("U",1002,"")	#1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM term ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY term_code" 

	PREPARE s_term FROM l_query_text 
	DECLARE c_term CURSOR FOR s_term 

	LET l_idx = 0 
	FOREACH c_term INTO l_rec_term.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_term[l_idx].term_code = l_rec_term.term_code 
		LET l_arr_rec_term[l_idx].desc_text = l_rec_term.desc_text
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 
	
	MESSAGE kandoomsg2("U",9113,l_idx)	#U9113 l_idx records selected

	RETURN l_arr_rec_term 
END FUNCTION 
###########################################################################
# END FUNCTION scan_term(p_filter)
###########################################################################


###########################################################################
# FUNCTION show_term(p_cmpy_code)
#
#
###########################################################################
FUNCTION show_term(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_arr_rec_term DYNAMIC ARRAY OF t_rec_term_tc_dt_with_scrollflag 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW A103 with FORM "A103" 
	CALL windecoration_a("A103") 

	#   WHILE TRUE

	{
	      CLEAR FORM
	      MESSAGE kandoomsg2("U",1001,"")
	#1001 " Enter Selection Criteria - ESC TO Continue"
	      CONSTRUCT BY NAME l_where_text on term_code,
	                                      desc_text

			BEFORE CONSTRUCT
				CALL publish_toolbar("kandoo","termwind","construct-term")
			ON ACTION "WEB-HELP"
				CALL onlineHelp(getModuleId(),NULL)
				ON ACTION "actToolbarManager"
			 	CALL setupToolbar()
			END CONSTRUCT


	      IF int_flag OR quit_flag THEN
	         LET int_flag = FALSE
	         LET quit_flag = FALSE
	         LET l_rec_term.term_code = NULL
	         EXIT WHILE
	      END IF
	      MESSAGE kandoomsg2("U",1002,"")
	#1002 " Searching database - please wait"
	      LET l_query_text = "SELECT * FROM term ",
	                        "WHERE cmpy_code = '",p_cmpy_code,"' ",
	                          "AND ",l_where_text clipped," ",
	                        "ORDER BY term_code"
	      WHENEVER ERROR CONTINUE
	      OPTIONS sql interrupt on
	      PREPARE s_term FROM l_query_text
	      DECLARE c_term CURSOR FOR s_term
	      LET l_idx = 0
	      FOREACH c_term INTO l_rec_term.*
	         LET l_idx = l_idx + 1
	         LET l_arr_rec_term[l_idx].term_code = l_rec_term.term_code
	         LET l_arr_rec_term[l_idx].desc_text = l_rec_term.desc_text
	      END FOREACH
	      ERROR kandoomsg2("U",9113,l_idx)
	#U9113 l_idx records selected

	}
	IF l_idx = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_term[1].* TO NULL 
	END IF 
 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"

	IF db_term_get_count() > 1000 THEN 
		CALL scan_term(TRUE) RETURNING l_arr_rec_term 
	ELSE 
		CALL scan_term(FALSE) RETURNING l_arr_rec_term 
	END IF 

	#	INPUT ARRAY l_arr_rec_term WITHOUT DEFAULTS FROM sr_term.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_term TO sr_term.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","termwind","input-arr-term") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL scan_term(TRUE) RETURNING l_arr_rec_term 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_term.term_code = l_arr_rec_term[l_idx].term_code 

		ON ACTION "TERM-CODE-MAINTENANCE" --KEY (F10) 
			CALL run_prog("AZ2","","","","") #Term Code Maintenance
			CALL scan_term(FALSE) RETURNING l_arr_rec_term 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW A103 
	CALL comboList_termCode("term_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	RETURN l_rec_term.term_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_term(p_cmpy_code)
###########################################################################