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
# FUNCTION currwind_whenever_sqlerror ()
#
#
###########################################################################
FUNCTION currwind_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION
###########################################################################
# END FUNCTION currwind_whenever_sqlerror ()
###########################################################################


############################################################
# FUNCTION db_currency_filter_dataSource(p_filter)
#
#
############################################################
FUNCTION db_currency_filter_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_arr_rec_currency DYNAMIC ARRAY OF t_rec_currency_cd_dt_st 
	DEFINE l_rec_currency t_rec_currency_cd_dt_st 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_filter = true THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			currency_code, 
			desc_text, 
			symbol_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","currwind","construct-currency") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_currency.currency_code = NULL 

		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM currency ", 
		"WHERE ",l_where_text CLIPPED," ", 
		"ORDER BY currency_code" 
	
	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON
	 
	PREPARE s_currency FROM l_query_text 
	DECLARE c_currency CURSOR FOR s_currency 

	CALL l_arr_rec_currency.clear() 
	LET l_idx = 0 
	FOREACH c_currency INTO l_rec_currency.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_currency[l_idx].currency_code = l_rec_currency.currency_code 
		LET l_arr_rec_currency[l_idx].desc_text = l_rec_currency.desc_text 
		LET l_arr_rec_currency[l_idx].symbol_text = l_rec_currency.symbol_text 
		#huho changed TO dynamicArray
		#IF l_idx = 100 THEN
		#   LET l_msgresp = kandoomsg("U",6100,l_idx)
		#   EXIT FOREACH
		#END IF
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH
	 
	LET l_msgresp=kandoomsg("U",9113,l_idx)	#U9113 l_idx records selected

	RETURN l_arr_rec_currency 
END FUNCTION 
############################################################
# END FUNCTION db_currency_filter_dataSource(p_filter)
############################################################


#######################################################################
# FUNCTION show_curr(p_cmpy)
#
#      currwind.4gl - show_curr
#                     window FUNCTION FOR finding currency record
#                     returns currency_code
#######################################################################
FUNCTION show_curr(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code #not used 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_arr_rec_currency DYNAMIC ARRAY OF t_rec_currency_cd_dt_st 
	#		RECORD  --huho array[100] of record
	#			currency_code LIKE currency.currency_code,
	#			desc_text LIKE currency.desc_text,
	#			symbol_text LIKE currency.symbol_text
	#	END RECORD
	DEFINE l_idx SMALLINT 
	#	DEFINE l_query_text  CHAR(800)
	#	DEFINE l_where_text  CHAR(400)
	DEFINE l_msgresp LIKE language.yes_flag 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW G132 with FORM "G132" 
	CALL windecoration_g("G132") 

	IF db_currency_get_count() > 1000 THEN 
		CALL db_currency_filter_datasource(true) RETURNING l_arr_rec_currency 
	ELSE 
		CALL db_currency_filter_datasource(false) RETURNING l_arr_rec_currency 
	END IF 

	#   WHILE TRUE

	IF l_arr_rec_currency.getlength() = 0 THEN 
		LET l_idx = 1 
		INITIALIZE l_arr_rec_currency[1].* TO NULL 
	END IF 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	LET l_msgresp = kandoomsg("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"

	#INPUT ARRAY l_arr_rec_currency WITHOUT DEFAULTS FROM sr_currency.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_currency TO sr_currency.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","currwind","input-arr-currency") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL db_currency_filter_datasource(true) RETURNING l_arr_rec_currency 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_currency.currency_code = l_arr_rec_currency[l_idx].currency_code 
			#LET scrn = scr_line()
			#IF l_arr_rec_currency[l_idx].currency_code IS NOT NULL THEN
			#   DISPLAY l_arr_rec_currency[l_idx].* TO sr_currency[scrn].*
			#
			#END IF
			# NEXT FIELD currency_code
		ON KEY (F10) 
			CALL run_prog("GZ8","","","","") 
			CALL db_currency_filter_datasource(false) RETURNING l_arr_rec_currency 
			#NEXT FIELD currency_code
			#         AFTER FIELD currency_code
			#            IF  fgl_lastkey() = fgl_keyval("down")
			#            AND arr_curr() >= arr_count() THEN
			#               LET l_msgresp = kandoomsg("U",9001,"")
			#               NEXT FIELD currency_code
			#            END IF
			#         BEFORE FIELD desc_text
			#            LET l_rec_currency.currency_code = l_arr_rec_currency[l_idx].currency_code
			#            EXIT INPUT
			#AFTER ROW
			#   DISPLAY l_arr_rec_currency[l_idx].* TO sr_currency[scrn].*

		AFTER DISPLAY 
			LET l_rec_currency.currency_code = l_arr_rec_currency[l_idx].currency_code 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		#      ELSE
		#         EXIT WHILE
	END IF 
	#   END WHILE

	CLOSE WINDOW G132 
	#Update comboList on parent window
	CALL comboList_currency("currency_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	RETURN l_rec_currency.currency_code 
END FUNCTION 
#######################################################################
# END FUNCTION show_curr(p_cmpy)
#######################################################################