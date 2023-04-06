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
#     holdwind.4gl - show_hold
#                    Window FUNCTION FOR finding hold sales reason.
#                    FUNCTION will RETURN hold_code TO calling program
# 1) p4gl extracted only first parameter
# 2) comment IS garbage
#
# id_package     .
# module_name    holdwind.4gl
# function_name  show_hold
# item_num       0
# var_name       p_cmpy
# data_type      LIKE company.cmpy_code
# comments       `W@`W@--
#
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION show_hold(p_cmpy,p_filter_text)
#
#
###########################################################################
FUNCTION show_hold(p_cmpy,p_filter_text) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_filter_text CHAR(300)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 
	DEFINE l_arr_holdreas array[100] OF RECORD 
		scroll_flag CHAR(1), 
		hold_code LIKE holdreas.hold_code, 
		reason_text LIKE holdreas.reason_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
 
	IF p_filter_text IS NULL THEN 
		LET p_filter_text = "1=1" 
	END IF 

	OPEN WINDOW A604 with FORM "A604" 
	CALL windecoration_a("A604") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON hold_code, reason_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","holdwind","construct-holdreas") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_holdreas.hold_code = NULL 
			EXIT WHILE 
		END IF 

		LET l_msgresp = kandoomsg("U",1002,"")		#1002 " Searching database - please wait"

		LET l_query_text = "SELECT * FROM holdreas ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text CLIPPED," ", 
		"AND ",p_filter_text CLIPPED," ", 
		"ORDER BY hold_code" 
		WHENEVER ERROR CONTINUE 

		OPTIONS SQL interrupt ON 
		PREPARE s_holdreas FROM l_query_text 
		DECLARE c_holdreas CURSOR FOR s_holdreas 
		
		LET l_idx = 0 
		FOREACH c_holdreas INTO l_rec_holdreas.* 
			LET l_idx = l_idx + 1 
			LET l_arr_holdreas[l_idx].hold_code = l_rec_holdreas.hold_code 
			LET l_arr_holdreas[l_idx].reason_text = l_rec_holdreas.reason_text 
			IF l_idx = 100 THEN 
				LET l_msgresp=kandoomsg("U",6100,l_idx) 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		LET l_msgresp = kandoomsg("U",9113,l_idx)	#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_holdreas[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		 
		LET l_msgresp = kandoomsg("U",1006,"") 	#1006 " ESC on line TO SELECT - F10 TO Add"
		CALL set_count(l_idx) 
		DISPLAY ARRAY l_arr_holdreas TO sr_holdreas.* 
			BEFORE DISPLAY
				CALL publish_toolbar("kandoo","holdwind","input-arr-holdreas") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_holdreas.hold_code = l_arr_holdreas[l_idx].hold_code				

			ON ACTION "Hold Sales Reason"		--ON KEY (F10) 
				CALL run_prog("AZH","","","","") 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	CLOSE WINDOW A604 

	RETURN l_rec_holdreas.hold_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_hold(p_cmpy,p_filter_text)
###########################################################################