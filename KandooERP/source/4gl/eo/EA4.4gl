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
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EA_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EA4_GLOBALS.4gl" 
###########################################################################
# FUNCTION EA4_main()
#
# EA4 - allows users TO SELECT a customer/product TO which peruse
#       product sales information FROM statistics tables.
###########################################################################
FUNCTION EA4_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EA4") -- albo 

--	SELECT * INTO glob_rec_statparms.* 
--	FROM statparms 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	AND parm_code = "1" 
	
	IF get_url_cust_code() IS NOT NULL THEN	
		CALL cust_prodturn(glob_rec_kandoouser.cmpy_code,get_url_cust_code(),"","","") 
	ELSE 
		OPEN WINDOW E220 with FORM "E220" 
		 CALL windecoration_e("E220") -- albo kd-755
 
		CALL scan_cust() 
		 
		CLOSE WINDOW E220 
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION EA4_main()
###########################################################################


###########################################################################
# FUNCTION EA4_customer_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION EA4_customer_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_table_text char(10) 
	DEFINE l_statsale_text STRING 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		short_desc_text LIKE product.short_desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON cust_code, 
		name_text, 
		maingrp_code, 
		prodgrp_code, 
		part_code, 
		desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EA4","construct-cust_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = "1=1" 
		END IF
	ELSE 
		LET l_where_text = "1=1"
	END IF
	
	MESSAGE kandoomsg2("E",1002,"") 
	LET l_query_text = 
		"SELECT '',cust_code,", 
		"name_text,", 
		"maingrp_code,", 
		"prodgrp_code,", 
		"part_code,", 
		"desc_text ", 
		"FROM customer,", 
		"product ", 
		"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.delete_flag = 'N' ", 
		"AND product.cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND product.status_ind = '1' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 2,4,5,6" 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer 

	LET l_idx = 1 
	FOREACH c_customer INTO l_arr_rec_customer[l_idx].*		
		SELECT unique 1 FROM statsale 
		WHERE cmpy_code= glob_rec_kandoouser.cmpy_code 
		AND cust_code= l_arr_rec_customer[l_idx].cust_code 
		AND year_num= glob_rec_statparms.year_num 
		AND type_code= glob_rec_statparms.mth_type_code 
		AND maingrp_code = l_arr_rec_customer[l_idx].maingrp_code 
		AND prodgrp_code = l_arr_rec_customer[l_idx].prodgrp_code 
		AND part_code = l_arr_rec_customer[l_idx].part_code 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_customer[l_idx].stat_flag = NULL 
		ELSE 
			LET l_arr_rec_customer[l_idx].stat_flag = "*" 
		END IF 
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
		LET l_idx = l_idx + 1
	END FOREACH 

	IF l_arr_rec_customer[l_idx].cust_code IS NULL THEN
		CALL l_arr_rec_customer.delete(l_idx)
	END IF
	
	RETURN l_arr_rec_customer 
END FUNCTION 
###########################################################################
# END FUNCTION select_cust()
###########################################################################


###########################################################################
# FUNCTION scan_cust()
#
#
###########################################################################
FUNCTION scan_cust() 
--	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		short_desc_text LIKE product.short_desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL EA4_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
	 
	MESSAGE kandoomsg2("E",1127,"")
	 
	--INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* 
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EA4","input-arr-l_arr_rec_customer-1") 
			CALL dialog.setActionHidden("CANCEL",TRUE) 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize())
		
		BEFORE ROW 
			LET l_idx = arr_curr() 
		
		AFTER ROW
			#nothing

		AFTER DISPLAY 
			#nothing	 			
		ON ACTION "WEB-HELP"
			CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
				
		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL EA4_customer_get_datasource(TRUE) RETURNING l_arr_rec_customer
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize())
				
		ON ACTION "REFRESH"
			 CALL windecoration_e("E220")
			CALL l_arr_rec_customer.clear()
			CALL EA4_customer_get_datasource(TRUE) RETURNING l_arr_rec_customer
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize())
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD cust_code
 			IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN
				IF l_arr_rec_customer[l_idx].cust_code IS NOT NULL THEN 
					CALL cust_prodturn(
						glob_rec_kandoouser.cmpy_code,
						l_arr_rec_customer[l_idx].cust_code, 
						l_arr_rec_customer[l_idx].part_code,"","") 
				END IF
			END IF
			 
		ON ACTION "EXIT"
			EXIT DISPLAY
			
	END DISPLAY
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_cust()
###########################################################################