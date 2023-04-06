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
#        salewind.4gl - show_sale
#                       window FUNCTION TO find salesperson records
#                       returns sale_code
###########################################################################
# FUNCTION select_salesperson_list(p_filter)
#
###########################################################################
FUNCTION select_salesperson_list(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF t_rec_salesperson_sc_nt_tc_with_scrollflag 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	CALL errorlog("*** Filter = " + p_filter + "***") 

	IF p_filter THEN 
		CLEAR FORM 
		LET l_msgresp = kandoomsg("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			terri_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","salewind","construct-salesperson")
				 
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),NULL)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 


		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 

			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY sale_code" 

	WHENEVER ERROR CONTINUE 

	OPTIONS SQL interrupt ON 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson CURSOR FOR s_salesperson 

	LET l_idx = 0 
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
		LET l_arr_rec_salesperson[l_idx].name_text = l_rec_salesperson.name_text 
		LET l_arr_rec_salesperson[l_idx].terri_code = l_rec_salesperson.terri_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	LET l_msgresp=kandoomsg("U",9113,l_arr_rec_salesperson.getLength())	#U9113 l_idx records selected

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN l_arr_rec_salesperson 

END FUNCTION 
###########################################################################
# END FUNCTION select_salesperson_list(p_filter)
###########################################################################


###########################################################################
# FUNCTION show_sale(p_cmpy)
#
#
###########################################################################
FUNCTION show_sale(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF t_rec_salesperson_sc_nt_tc_with_scrollflag 
	#	DEFINE l_arr_rec_salesperson array[100] of record
	#         scroll_flag CHAR(1),
	#         sale_code LIKE salesperson.sale_code,
	#         name_text LIKE salesperson.name_text,
	#         terri_code LIKE salesperson.terri_code
	#      END RECORD,
	DEFINE l_idx SMALLINT 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	OPEN WINDOW A160 with FORM "A160" 
	CALL windecoration_a("A160") 


	IF db_salesperson_get_count() > 1000 THEN 
		CALL select_salesperson_list(true) RETURNING l_arr_rec_salesperson 
	ELSE 
		CALL select_salesperson_list(false) RETURNING l_arr_rec_salesperson 
	END IF 

	#      IF l_idx = 0 THEN
	#         LET l_idx = 1
	#         INITIALIZE l_arr_rec_salesperson[1].* TO NULL
	#      END IF

	LET l_msgresp = kandoomsg("U",1006,"") #1006 " ESC on line TO SELECT - F10 TO Add"
	#      INPUT ARRAY l_arr_rec_salesperson WITHOUT DEFAULTS FROM sr_salesperson.*
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","salewind","input-arr-salesperson") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_salesperson.sale_code = l_arr_rec_salesperson[l_idx].sale_code 

		ON KEY (F10) 
			CALL run_prog("AZ3","","","","") 
			CALL select_salesperson_list(false) RETURNING l_arr_rec_salesperson 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
	END DISPLAY 

	IF int_flag THEN 
		LET int_flag = false 
	END IF 

	CLOSE WINDOW A160 

	RETURN l_rec_salesperson.sale_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_sale(p_cmpy)
###########################################################################