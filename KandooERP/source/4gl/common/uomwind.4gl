{
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
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


###############################################################
# FUNCTION show_uom(p_cmpy)
#
# RETURN uom_code
#
# show_uom window FUNCTION FOR finding uom records
###############################################################
FUNCTION show_uom(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_uom RECORD LIKE uom.* 
	DEFINE l_arr_uom DYNAMIC ARRAY OF 
		RECORD 
			uom_code LIKE uom.uom_code, 
			desc_text LIKE uom.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW i102 with FORM "I102" 
	CALL windecoration_i("I102") 

	WHILE TRUE 
		CLEAR FORM 
		MESSAGE "Enter Selection Criteria"
		CONSTRUCT BY NAME l_where_text ON uom_code, 
		desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","uomwind","construct-uom") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_rec_uom.uom_code = NULL 
			EXIT WHILE 
		END IF 

		MESSAGE "Searching database - please wait"
		LET l_query_text = "SELECT * FROM uom ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY uom_code" 
		WHENEVER ERROR CONTINUE 
		OPTIONS SQL interrupt ON 
		PREPARE s_uom FROM l_query_text 
		DECLARE c_uom CURSOR FOR s_uom 

		LET l_idx = 0 
		FOREACH c_uom INTO l_rec_uom.* 
			LET l_idx = l_idx + 1 
			LET l_arr_uom[l_idx].uom_code = l_rec_uom.uom_code 
			LET l_arr_uom[l_idx].desc_text = l_rec_uom.desc_text 
		END FOREACH 
		MESSAGE l_idx CLIPPED, " records selected"
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

		MESSAGE "Select Line or F10 TO Add"
		DISPLAY ARRAY l_arr_uom TO sr_uom.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","uomwind","input-arr-uom") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				LET l_rec_uom.uom_code = l_arr_uom[l_idx].uom_code 

			ON KEY (F10) 
				CALL run_prog("IZ8","","","","") 

				         AFTER DISPLAY
				            LET l_rec_uom.uom_code = l_arr_uom[l_idx].uom_code

		END DISPLAY 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW i102 

	RETURN l_rec_uom.uom_code 
END FUNCTION