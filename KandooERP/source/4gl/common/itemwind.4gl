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
# FUNCTION db_product_get_datasource(p_filter,p_cmpy_code)
#
#
###########################################################################
FUNCTION db_product_get_datasource(p_filter,p_cmpy_code)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		oem_text LIKE product.oem_text 
	END RECORD 
	DEFINE l_idx SMALLINT 	
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE "Enter selection criteria - Apply TO continue"
		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			desc_text, 
			oem_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","itemwind","construct-product") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_rec_product.part_code = NULL 
			LET l_where_text = " 1=1 " 
		END IF
	ELSE
		LET l_where_text = " 1=1 "
	END IF 

	MESSAGE "Searching database - plese wait"
	LET l_query_text = 
		"SELECT * FROM product ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND status_ind <> '3' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY part_code" 

	WHENEVER ERROR CONTINUE 
	OPTIONS SQL interrupt ON 
	PREPARE s_product FROM l_query_text 
	DECLARE c_product CURSOR FOR s_product 

	LET l_idx = 0 
	FOREACH c_product INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[l_idx].oem_text = l_rec_product.oem_text

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF			 
	END FOREACH 

	MESSAGE l_idx CLIPPED, " records selected"

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	RETURN l_arr_rec_product
END FUNCTION
###########################################################################
# END FUNCTION db_product_get_datasource(p_filter,p_cmpy_code)
###########################################################################

 
############################################################
# FUNCTION show_item(p_cmpy_code)
#
#       itemwind.4gl - show_item
#                      window FUNCTION TO find product records
#                      returns part_code
############################################################
FUNCTION show_item(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
--	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		oem_text LIKE product.oem_text 
	END RECORD 
	DEFINE l_idx SMALLINT 
--	DEFINE l_scrn SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

	OPEN WINDOW I104 with FORM "I104" 
	CALL winDecoration_i("I104") 

	CALL db_product_get_datasource(FALSE,p_cmpy_code) RETURNING l_arr_rec_product 	

	MESSAGE "SELECT, Cancel or Add (F10)"
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","itemwind","input-arr-product") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_product.clear()	
			CALL db_product_get_datasource(TRUE,p_cmpy_code) RETURNING l_arr_rec_product

		ON ACTION "REFRESH"
			CALL winDecoration_i("I104")
			CALL l_arr_rec_product.clear()	
			CALL db_product_get_datasource(FALSE,p_cmpy_code) RETURNING l_arr_rec_product

		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_rec_product.part_code = l_arr_rec_product[l_idx].part_code
			
		ON ACTION "I11-Product Addition" --ON KEY (F10) 
			CALL run_prog("I11","","","","") 
			CALL l_arr_rec_product.clear()	
			CALL db_product_get_datasource(FALSE,p_cmpy_code) RETURNING l_arr_rec_product

	END DISPLAY 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF

	CLOSE WINDOW I104 

	RETURN l_rec_product.part_code 
END FUNCTION 
############################################################
# END FUNCTION show_item(p_cmpy_code)
############################################################