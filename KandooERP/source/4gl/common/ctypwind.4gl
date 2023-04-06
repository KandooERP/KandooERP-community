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
#    ctypwind.4gl - show_ctyp
#                   window FUNCTION FOR finding customertype record
#                   returns type_code
###########################################################################

###########################################################################
# FUNCTION show_ctyp(p_cmpy)
#
#
###########################################################################
FUNCTION show_ctyp(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_arr_customertype DYNAMIC ARRAY OF RECORD 
					scroll_flag CHAR(1), 
					type_code LIKE customertype.type_code, 
					type_text LIKE customertype.type_text 
			 END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_scrn SMALLINT
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPEN WINDOW A162 with FORM "A162" 
	CALL windecoration_a("A162") 

	WHILE true 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"")		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON type_code,		type_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ctywind","construct-type") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_customertype.type_code = NULL 
			EXIT WHILE 
		END IF 
		
		LET l_msgresp = kandoomsg("U",1002,"")		#1002 " Searching database - please wait"
		LET l_query_text = "SELECT * FROM customertype ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY type_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_customertype FROM l_query_text 
		DECLARE c_customertype CURSOR FOR s_customertype 

		LET l_idx = 0 
		FOREACH c_customertype INTO l_rec_customertype.* 
			LET l_idx = l_idx + 1 
			LET l_arr_customertype[l_idx].type_code = l_rec_customertype.type_code 
			LET l_arr_customertype[l_idx].type_text = l_rec_customertype.type_text 
		END FOREACH 

		LET l_msgresp=kandoomsg("U",9113,l_idx)	#U9113 l_idx records selected
		IF l_idx = 0 THEN 
			LET l_idx = 1 
			INITIALIZE l_arr_customertype[1].* TO NULL 
		END IF 

		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		LET l_msgresp = kandoomsg("U",1006,"")	#1006 " ESC on line TO SELECT - F10 TO Add"
 
		DISPLAY ARRAY l_arr_customertype TO sr_customertype.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","ctypwind","input-arr-customertype") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_customertype.type_code = l_arr_customertype[l_idx].type_code
				
			ON KEY (F10) 
				CALL run_prog("AZ4","","","","") 
				NEXT FIELD scroll_flag 

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW A162 

	RETURN l_rec_customertype.type_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_ctyp(p_cmpy)
###########################################################################
