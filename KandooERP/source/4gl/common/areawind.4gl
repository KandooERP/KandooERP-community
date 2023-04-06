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
#   areawind.4gl - show_area
#                  Window FUNCTION FOR finding a Sales Area
#                  FUNCTION will RETURN area_code TO calling program
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"  

###########################################################################
# FUNCTION db_salearea_get_datasource(p_filter,p_cmpy)
#
#
###########################################################################
FUNCTION db_salearea_get_datasource(p_filter,p_cmpy)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	IF p_filter THEN 

		MESSAGE kandoomsg2("U",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			area_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","areawind","construct-area") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_salearea.area_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 
		
	MESSAGE kandoomsg2("U",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM salearea ", 
		"WHERE cmpy_code = \"",p_cmpy,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY area_code" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 

	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea CURSOR FOR s_salearea 

	LET l_idx = 0 
	FOREACH c_salearea INTO l_rec_salearea.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code 
		LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH
		 
	MESSAGE kandoomsg2("U",9113,l_idx) #U9113 l_idx RECORDs selected
	RETURN l_arr_rec_salearea
END FUNCTION
###########################################################################
# END FUNCTION db_salearea_get_datasource(p_filter,p_cmpy)
###########################################################################

 
###########################################################################
# FUNCTION show_area(p_cmpy) 
#
#
###########################################################################
FUNCTION show_area(p_cmpy) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD  
		scroll_flag CHAR(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 

	OPEN WINDOW A615 with FORM "A615" 
	CALL winDecoration_a("A615") 

	CALL db_salearea_get_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_salearea
 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	
	MESSAGE kandoomsg2("U",1006,"") 	#1006 " ESC on line TO SELECT - F10 TO Add"
	DISPLAY ARRAY l_arr_rec_salearea TO sr_salearea.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","areawind","input-arr-salearea") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_salearea.area_code = l_arr_rec_salearea[l_idx].area_code
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 
		
		ON ACTION "FILTER"
			CALL l_arr_rec_salearea.clear()
			CALL db_salearea_get_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_salearea

		ON ACTION "REFRESH"
			CALL winDecoration_a("A615")
			CALL l_arr_rec_salearea.clear()
			CALL db_salearea_get_datasource(FALSE,p_cmpy) RETURNING l_arr_rec_salearea

		ON ACTION "F10-AZA" --ON KEY (F10) 
			CALL run_prog ("AZA","","","","") 

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_salearea.area_code = NULL
	END IF 

	CLOSE WINDOW A615 

	RETURN l_rec_salearea.area_code 
END FUNCTION 
###########################################################################
# END FUNCTION show_area(p_cmpy) 
###########################################################################