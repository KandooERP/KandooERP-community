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
GLOBALS "../eo/EF_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EF4_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# FUNCTION EF4_main()
#
# EF4 - allows users TO SELECT a sales area TO peruse
#       distribution information FROM statistics tables.
###########################################################################
FUNCTION EF4_main()
	DEFINE l_arg_area_code LIKE salearea.area_code 
	 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EF4") 

	#Argument
	LET l_arg_area_code = get_url_area_code()	 
	IF l_arg_area_code IS NOT NULL THEN 
		CALL area_dist(glob_rec_kandoouser.cmpy_code,l_arg_area_code,"") 
	ELSE 
		OPEN WINDOW E243 with FORM "E243" 
		 CALL windecoration_e("E243") 

		CALL scan_area() 
		
		CLOSE WINDOW E243 
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION EF4_main()
###########################################################################


###########################################################################
# FUNCTION salearea_product_get_datasource() 
#
#
###########################################################################
FUNCTION salearea_product_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_salearea RECORD LIKE salearea.*
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			area_code, 
			salearea.desc_text, 
			maingrp_code, 
			prodgrp_code, 
			part_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EF4","construct-area_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE 
		LET l_where_text = " 1=1 "
	END IF
	
	ERROR kandoomsg2("E",1002,"") 
	LET l_query_text = 
		"SELECT ' ', area_code,", 
		"salearea.desc_text,", 
		"maingrp_code,", 
		"prodgrp_code, ", 
		"part_code ", 
		"FROM salearea, product ", 
		"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND salearea.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND status_ind != '3' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 2,4,5,6" 
	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea cursor FOR s_salearea 

	LET l_idx = 1 
	FOREACH c_salearea INTO l_arr_rec_salearea[l_idx].* 
		SELECT unique 1 FROM distterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_arr_rec_salearea[l_idx].area_code 
		AND maingrp_code = l_arr_rec_salearea[l_idx].maingrp_code 
		AND prodgrp_code = l_arr_rec_salearea[l_idx].prodgrp_code 
		AND part_code = l_arr_rec_salearea[l_idx].part_code 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_salearea[l_idx].stat_flag = NULL 
		ELSE 
			LET l_arr_rec_salearea[l_idx].stat_flag = "*" 
		END IF 
 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
		LET l_idx = l_idx + 1
	END FOREACH

	RETURN l_arr_rec_salearea 
END FUNCTION 
###########################################################################
# END FUNCTION salearea_product_get_datasource() 
#
#
###########################################################################


###########################################################################
# FUNCTION salearea_product_get_datasource() 
#
#
###########################################################################
FUNCTION scan_area() 
	DEFINE l_rec_salearea RECORD LIKE salearea.*
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL salearea_product_get_datasource(FALSE) RETURNING l_arr_rec_salearea
 
	MESSAGE kandoomsg2("E",1109,"") #1109 Sales Area Distribution - RETURN TO View
	DISPLAY ARRAY l_arr_rec_salearea TO sr_salearea.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EF4","input-arr-l_arr_rec_salearea-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salearea.clear()
			CALL salearea_product_get_datasource(FALSE) RETURNING l_arr_rec_salearea
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
		
		ON ACTION "REFRESH"
			 CALL windecoration_e("E243")
			CALL l_arr_rec_salearea.clear()
			CALL salearea_product_get_datasource(FALSE) RETURNING l_arr_rec_salearea
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
 
	 
		ON ACTION ("ACCEPT","DOUBLECLICK")
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salearea.getSize()) THEN 
				IF l_arr_rec_salearea[l_idx].area_code IS NOT NULL THEN 
					CALL area_dist(glob_rec_kandoouser.cmpy_code,l_arr_rec_salearea[l_idx].area_code, 	l_arr_rec_salearea[l_idx].part_code) 
				END IF
			END IF

		BEFORE ROW 
			LET l_idx = arr_curr()
						 
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION salearea_product_get_datasource() 
###########################################################################


###########################################################################
# FUNCTION area_dist(p_cmpy_code,p_area_code,p_part_code)
#
#
###########################################################################
FUNCTION area_dist(p_cmpy_code,p_area_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_area_code LIKE salearea.area_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_area_desc LIKE salearea.desc_text 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_distterr RECORD LIKE distterr.* ## CURRENT year 
	DEFINE l_rec_prv_distterr RECORD LIKE distterr.* ## previous year 
	DEFINE l_arr_rec_distterr DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		mth_cust_num LIKE distterr.mth_cust_num, 
		mth_net_amt LIKE distterr.mth_net_amt, 
		mth_sales_qty LIKE distterr.mth_sales_qty, 
		prv_mth_cust_num LIKE distterr.mth_cust_num, 
		prv_mth_net_amt LIKE distterr.mth_net_amt, 
		prv_mth_sales_qty LIKE distterr.mth_sales_qty 
	END RECORD 
	DEFINE l_arr_rec_stattotal_1 array[1] OF RECORD #why why why...
		tot_mth_net_amt LIKE distterr.mth_net_amt, 
		tot_mth_sales_qty LIKE distterr.mth_sales_qty, 
		tot_prv_mth_net_amt LIKE distterr.mth_net_amt, 
		tot_prv_mth_sales_qty LIKE distterr.mth_sales_qty 
	END RECORD 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_prompt_text char(40)
	DEFINE l_area_text char(40)
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	OPEN WINDOW E244 with FORM "E244" 
	 CALL windecoration_e("E244") -- albo kd-755 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 
	IF p_part_code IS NOT NULL THEN 
		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = p_cmpy_code 
		AND part_code = p_part_code 
		IF status = NOTFOUND THEN 
			ERROR kandoomsg2("I",5010,p_part_code) 	#5010" Logic Error: product NOT found"
			RETURN 
		END IF 
	END IF 

	SELECT * INTO l_rec_salearea.* 
	FROM salearea 
	WHERE cmpy_code = p_cmpy_code 
	AND area_code = p_area_code 
	LET l_area_desc = l_rec_salearea.desc_text 
	IF status = 0 THEN 
		MENU " Inquiry level" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","EF4","menu-Inquiry_Level-1") -- albo kd-502 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Product" " Inquiry on product sales" 
				LET l_type_ind = "1" 
				IF p_part_code IS NOT NULL THEN 
					LET l_type_code = l_rec_product.part_code 
					EXIT MENU 
				ELSE 
					LET l_type_code = show_part(p_cmpy_code, 
					"(status_ind='1' OR status_ind='4')") 
					IF l_type_code IS NOT NULL THEN 
						EXIT MENU 
					END IF 
				END IF 

			COMMAND "PRODUCT GROUP" " Inquiry on product-group sales" 
				LET l_type_ind = "2" 
				IF p_part_code IS NOT NULL THEN 
					LET l_type_code = l_rec_product.prodgrp_code 
					EXIT MENU 
				ELSE 
					LET l_type_code = show_prodgrp(p_cmpy_code,"") 
					IF l_type_code IS NOT NULL THEN 
						EXIT MENU 
					END IF 
				END IF 

			COMMAND "MAIN GROUP" " Inquiry on main-group sales" 
				LET l_type_ind = "3" 
				IF p_part_code IS NOT NULL THEN 
					LET l_type_code = l_rec_product.maingrp_code 
					EXIT MENU 
				ELSE 
					LET l_type_code = show_maingrp(p_cmpy_code,"") 
					IF l_type_code IS NOT NULL THEN 
						EXIT MENU 
					END IF 
				END IF 

			ON ACTION "CANCEL" --COMMAND KEY(INTERRUPT,"E")"Exit" " Exit inquiry" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 
		
		IF NOT (int_flag OR quit_flag) THEN 
			CASE l_type_ind 

				WHEN "1" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM product 
					WHERE cmpy_code = p_cmpy_code 
					AND part_code = l_type_code 
					LET l_prompt_text = kandooword("Product","1") 
					LET l_where_text = "part_code = '",l_type_code CLIPPED,"'" 

				WHEN "2" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM prodgrp 
					WHERE cmpy_code = p_cmpy_code 
					AND prodgrp_code = l_type_code 
					LET l_prompt_text = kandooword("Product Group","1") 
					LET l_where_text = "part_code IS NULL AND prodgrp_code='",l_type_code  CLIPPED,"'" 

				WHEN "3" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM maingrp 
					WHERE cmpy_code = p_cmpy_code 
					AND maingrp_code = l_type_code 
					LET l_prompt_text = kandooword("Main Group","1") 
					LET l_where_text ="part_code IS NULL AND ", 
					"prodgrp_code IS NULL AND ", 
					"maingrp_code = '",l_type_code CLIPPED,"'" 
			END CASE 

			LET l_query_text ="SELECT * FROM distterr ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND area_code = '",p_area_code,"' ", 
			"AND terr_code IS NULL ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			"AND ",l_where_text clipped 
			PREPARE s_distterr FROM l_query_text 
			DECLARE c_distterr cursor FOR s_distterr 

			LET l_area_text = kandooword("Sales Area","1") 
			LET l_area_text = l_area_text clipped,"........" 
			LET l_prompt_text = l_prompt_text clipped,"........" 
			LET l_rec_product.part_code = l_type_code 

			WHILE TRUE 
				MESSAGE kandoomsg2("E",1002,"") 
				CLEAR FORM 
				DISPLAY l_area_text TO area_text
				DISPLAY l_prompt_text TO prompt_text 
				DISPLAY l_rec_salearea.area_code TO area_code 
				DISPLAY l_area_desc TO area_desc 
				DISPLAY l_rec_product.part_code TO part_code 
				DISPLAY l_rec_product.desc_text TO desc_text

				LET i = l_rec_statparms.year_num - 1 
				DISPLAY l_rec_statparms.year_num TO sr_year[1].year_num 
				DISPLAY i TO sr_year[2].year_num 

				LET l_arr_rec_stattotal_1[1].tot_mth_net_amt = 0 
				LET l_arr_rec_stattotal_1[1].tot_mth_sales_qty = 0 
				LET l_arr_rec_stattotal_1[1].tot_prv_mth_net_amt = 0 
				LET l_arr_rec_stattotal_1[1].tot_prv_mth_sales_qty = 0 
				LET l_idx = 0 

				DECLARE c_statint cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = p_cmpy_code 
				AND year_num = l_rec_statparms.year_num 
				AND type_code = l_rec_statparms.mth_type_code 
				ORDER BY 1,2,3,4 

				FOREACH c_statint INTO l_rec_statint.* 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_distterr[l_idx].int_text = l_rec_statint.int_text 

					## obtain current year gross,net AND disc%
					OPEN c_distterr USING l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
					FETCH c_distterr INTO l_rec_cur_distterr.* 
					IF status = NOTFOUND THEN 
						LET l_rec_cur_distterr.mth_cust_num = 0 
						LET l_rec_cur_distterr.mth_net_amt = 0 
						LET l_rec_cur_distterr.mth_sales_qty = 0 
					END IF 
					LET l_arr_rec_distterr[l_idx].mth_cust_num = l_rec_cur_distterr.mth_cust_num 
					LET l_arr_rec_distterr[l_idx].mth_net_amt = l_rec_cur_distterr.mth_net_amt 
					LET l_arr_rec_distterr[l_idx].mth_sales_qty =	l_rec_cur_distterr.mth_sales_qty 

					#-------------------------------------------------------
					# obtain previous year gross,net AND disc%
					OPEN c_distterr USING i, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
					FETCH c_distterr INTO l_rec_prv_distterr.* 
					IF status = NOTFOUND THEN 
						LET l_rec_prv_distterr.mth_cust_num = 0 
						LET l_rec_prv_distterr.mth_net_amt = 0 
						LET l_rec_prv_distterr.mth_sales_qty = 0 
					END IF 
					LET l_arr_rec_distterr[l_idx].prv_mth_cust_num = l_rec_prv_distterr.mth_cust_num 
					LET l_arr_rec_distterr[l_idx].prv_mth_net_amt = l_rec_prv_distterr.mth_net_amt 
					LET l_arr_rec_distterr[l_idx].prv_mth_sales_qty = l_rec_prv_distterr.mth_sales_qty 
					
					#-------------------------------------------------------
					# increment totals
					LET l_arr_rec_stattotal_1[1].tot_mth_net_amt = l_arr_rec_stattotal_1[1].tot_mth_net_amt + l_rec_cur_distterr.mth_net_amt 
					LET l_arr_rec_stattotal_1[1].tot_mth_sales_qty = l_arr_rec_stattotal_1[1].tot_mth_sales_qty + l_rec_cur_distterr.mth_sales_qty 
					LET l_arr_rec_stattotal_1[1].tot_prv_mth_net_amt = l_arr_rec_stattotal_1[1].tot_prv_mth_net_amt + l_rec_prv_distterr.mth_net_amt 
					LET l_arr_rec_stattotal_1[1].tot_prv_mth_sales_qty = l_arr_rec_stattotal_1[1].tot_prv_mth_sales_qty + l_rec_prv_distterr.mth_sales_qty 

				END FOREACH 

				IF l_idx = 0 THEN 
					ERROR kandoomsg2("E",7086,"") 	#7086 No statistical information exists FOR this selection "
					EXIT WHILE 
				ELSE 

					DISPLAY l_arr_rec_stattotal_1[1].* TO sr_stattotal[1].* 

					MESSAGE kandoomsg2("E",1110,"") 		#Sales Area Distribution - F9 Previous Year - F10 Next Year
 
					DISPLAY ARRAY l_arr_rec_distterr TO sr_distterr.* 
						BEFORE DISPLAY 
							CALL publish_toolbar("kandoo","EF4","input-arr-l_arr_rec_distterr-1")  

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						BEFORE ROW 
							LET l_idx = arr_curr() 

						ON ACTION "YEAR-1" --ON KEY (f9) 
							LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
							FOR i = 1 TO arr_count() 
								INITIALIZE l_arr_rec_distterr[i].* TO NULL 
							END FOR 
							EXIT DISPLAY 

						ON ACTION "YEAR+1" --ON KEY (f10) 
							LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
							FOR i = 1 TO arr_count() 
								INITIALIZE l_arr_rec_distterr[i].* TO NULL 
							END FOR 
							EXIT DISPLAY 
							
					END DISPLAY
					 
				END IF 
				
				IF int_flag THEN
					EXIT WHILE
				END IF
 
			END WHILE 

		END IF 

	END IF
	 
	CLOSE WINDOW E244
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION area_dist(p_cmpy_code,p_area_code,p_part_code)
###########################################################################