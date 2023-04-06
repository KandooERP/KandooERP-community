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

####################################################################
# FUNCTION jourwind_whenever_sqlerror ()
#
#
####################################################################
FUNCTION jourwind_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
####################################################################
# END FUNCTION jourwind_whenever_sqlerror ()
####################################################################


####################################################################
# FUNCTION db_journal_get_datasource(p_filter,p_cmpy_code)
#
#
####################################################################
FUNCTION db_journal_get_datasource(p_filter,p_cmpy_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_arr_rec_journal DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		jour_code LIKE journal.jour_code, 
		desc_text LIKE journal.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
			
	IF p_filter THEN	
		MESSAGE kandoomsg2("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON jour_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","jourwind","construct-journal") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_journal.jour_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = "1=1" #without filter CONSTRUCT 
	END IF 

	MESSAGE kandoomsg2("U",1002,"")		#1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM journal ", 
		"WHERE cmpy_code = '",p_cmpy_code CLIPPED,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY jour_code" 

		PREPARE s_journal FROM l_query_text 
		DECLARE c_journal CURSOR FOR s_journal 

		LET l_idx = 0 
		FOREACH c_journal INTO l_rec_journal.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_journal[l_idx].jour_code = l_rec_journal.jour_code 
			LET l_arr_rec_journal[l_idx].desc_text = l_rec_journal.desc_text 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF

		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)		#U9113 l_idx records selected

	RETURN l_arr_rec_journal	 
END FUNCTION
####################################################################
# END FUNCTION db_journal_get_datasource(p_filter,p_cmpy_code)
####################################################################


####################################################################
# FUNCTION show_jour(p_cmpy)
# RETURN l_rec_journal.jour_code
#           jourwind.4gl - show_jour
#                          window FUNCTION that finds journal records
#                          returns jour_code
####################################################################
FUNCTION show_jour(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_arr_rec_journal DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		jour_code LIKE journal.jour_code, 
		desc_text LIKE journal.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
 

	OPEN WINDOW G125 with FORM "G125" 
	CALL windecoration_g("G125") 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL db_journal_get_datasource(FALSE,glob_rec_company.cmpy_code) RETURNING l_arr_rec_journal

	MESSAGE kandoomsg2("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_rec_journal TO sr_journal.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","jourwind","input-arr-journal") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_journal.jour_code = l_arr_rec_journal[l_idx].jour_code 

		ON ACTION "FILTER" 
			CALL l_arr_rec_journal.clear()
			CALL db_journal_get_datasource(TRUE,glob_rec_company.cmpy_code) RETURNING l_arr_rec_journal 

		ON ACTION "REFRESH"
			CALL windecoration_g("G125")  
			CALL l_arr_rec_journal.clear()
			CALL db_journal_get_datasource(FALSE,glob_rec_company.cmpy_code) RETURNING l_arr_rec_journal 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "GZ2 - DATA MANAGER" --ON KEY (F10) 
			CALL run_prog("GZ2","","","","") 

	END DISPLAY 
	############################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false
		LET l_rec_journal.jour_code = NULL
	END IF 

	CLOSE WINDOW G125 

	RETURN l_rec_journal.jour_code 
END FUNCTION 
####################################################################
# END FUNCTION show_jour(p_cmpy)
####################################################################