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
# FUNCTION ctrywind_whenever_sqlerror ()
#
#
###########################################################################
FUNCTION ctrywind_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
###########################################################################
# END FUNCTION ctrywind_whenever_sqlerror ()
###########################################################################
 
 
#######################################################################
# FUNCTION show_country()
#
#    ctrywind.4gl - show_country
#                   window FUNCTION FOR finding country record
#                   returns country_code
#######################################################################
FUNCTION show_country() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_arr_country DYNAMIC ARRAY OF RECORD  
					country_code LIKE country.country_code, 
					country_text LIKE country.country_text, 
					language_code LIKE country.language_code 
			 END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW G193 with FORM "G193" 
	CALL windecoration_g("G193") 

	WHILE true 
		CLEAR FORM 

		LET l_msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
			country_code, 
			country_text, 
			language_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ctrywind","construct-country") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_country.country_code = NULL 
			EXIT WHILE 
		END IF 
		LET l_msgresp = kandoomsg("U",1002,"")		#1002 " Searching database - please wait"

		LET l_query_text = "SELECT * FROM country ", 
		"WHERE ",l_where_text CLIPPED," ", 
		"ORDER BY country_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_country FROM l_query_text 
		DECLARE c_country CURSOR FOR s_country 

		LET l_idx = 0 
		FOREACH c_country INTO l_rec_country.* 
			LET l_idx = l_idx + 1 
			LET l_arr_country[l_idx].country_code = l_rec_country.country_code 
			LET l_arr_country[l_idx].country_text = l_rec_country.country_text 
			LET l_arr_country[l_idx].language_code = l_rec_country.language_code 
		END FOREACH 

		LET l_msgresp=kandoomsg("U",9113,l_idx) 	#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_country[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		OPTIONS SQL interrupt off 

		LET l_msgresp = kandoomsg("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
 
		DISPLAY ARRAY l_arr_country TO sr_country.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","ctrywind","input-arr-country") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_country.country_code = l_arr_country[l_idx].country_code

			ON KEY (F10) 
				CALL run_prog("U1M","","","","") 
				NEXT FIELD country_code 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CALL combolist_country("country_code",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
	CLOSE WINDOW G193 

	RETURN l_rec_country.country_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_country()
#######################################################################