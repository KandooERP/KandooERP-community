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

#   wcartwin.4gl - cart_area_code
#                  Window FUNCTION FOR finding a cartarea
#                  FUNCTION will RETURN cart_area_code TO calling program
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"


##############################################################
# FUNCTION select_cart_area()
#
#
##############################################################
FUNCTION select_cart_area(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_cartarea RECORD LIKE cartarea.* 
	DEFINE l_arr_rec_cartarea DYNAMIC ARRAY OF t_rec_cart_area_cc_dt_with_scrollflag 
	#	array[100] of
	#		RECORD
	#         scroll_flag CHAR(1),
	#         cart_area_code LIKE cartarea.cart_area_code,
	#         desc_text LIKE cartarea.desc_text
	#      END RECORD
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			cart_area_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","wcartwin","construct-cartarea") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_cartarea.cart_area_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF 

	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM cartarea ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text CLIPPED," ", 
		"ORDER BY cart_area_code" 

	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 
	PREPARE s_cartarea FROM l_query_text 
	DECLARE c_cartarea CURSOR FOR s_cartarea 
	LET l_idx = 0 

	FOREACH c_cartarea INTO l_rec_cartarea.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_cartarea[l_idx].cart_area_code = l_rec_cartarea.cart_area_code 
		LET l_arr_rec_cartarea[l_idx].desc_text = l_rec_cartarea.desc_text

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_arr_rec_cartarea.getLength())	#9113 "l_idx records selected"
	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_cartarea[1].* TO NULL
	#      END IF
	WHENEVER ERROR stop 

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN l_arr_rec_cartarea 
END FUNCTION 
##############################################################
# END FUNCTION select_cart_area()
##############################################################


##############################################################
# FUNCTION show_cart_area(p_cmpy_code)
#
#
##############################################################
FUNCTION show_cart_area(p_cmpy_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_cartarea RECORD LIKE cartarea.* 
	DEFINE l_arr_rec_cartarea DYNAMIC ARRAY OF t_rec_cart_area_cc_dt_with_scrollflag 
	#	array[100] of
	#		RECORD
	#         scroll_flag CHAR(1),
	#         cart_area_code LIKE cartarea.cart_area_code,
	#         desc_text LIKE cartarea.desc_text
	#      END RECORD
	DEFINE l_idx SMALLINT 
	#	DEFINE l_query_text STRING
	#	DEFINE l_where_text STRING

	IF p_cmpy_code IS NULL THEN
		LET p_cmpy_code = glob_rec_kandoouser.cmpy_code
	END IF

	OPEN WINDOW W118 with FORM "W118" 
	CALL windecoration_w("W118") 

	IF db_cartarea_get_count() > 1000 THEN 
		CALL select_cart_area(TRUE) RETURNING l_arr_rec_cartarea 
	ELSE 
		CALL select_cart_area(FALSE) RETURNING l_arr_rec_cartarea 
	END IF 

	LET l_msgresp = kandoomsg("U",1006,"") 
	#1006 " ESC on line TO SELECT

	#INPUT ARRAY l_arr_rec_cartarea WITHOUT DEFAULTS FROM sr_cartarea.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_cartarea TO sr_cartarea.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","wcartwin","input-arr-cartarea") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_cartarea.cart_area_code = l_arr_rec_cartarea[l_idx].cart_area_code 

		ON KEY (F10) 
			CALL run_prog("WZ2","","","","") --huho we have no wz modules/programs :-( 
			CALL select_cart_area(FALSE) RETURNING l_arr_rec_cartarea 

		AFTER DISPLAY 
			LET l_rec_cartarea.cart_area_code = l_arr_rec_cartarea[l_idx].cart_area_code 

	END DISPLAY 
	###########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
	END IF 

	CLOSE WINDOW w118 

	RETURN l_rec_cartarea.cart_area_code 
END FUNCTION 
##############################################################
# END FUNCTION show_cart_area(p_cmpy_code)
##############################################################