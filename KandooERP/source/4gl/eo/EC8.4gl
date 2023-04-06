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
GLOBALS "../eo/EC_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EC8_GLOBALS.4gl"
###########################################################################
# FUNCTION EC8_main()
#
# EC8 - allows users TO SELECT a salesperson/product TO peruse
#       distribution information FROM statistics tables.
###########################################################################
FUNCTION EC8_main() 
	DEFINE l_arg_sale_code LIKE salesperson.sale_code
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EC8") -- albo 

	LET l_arg_sale_code = get_url_sale_code()
	IF l_arg_sale_code IS NOT NULL THEN
		CALL sper_dist(glob_rec_kandoouser.cmpy_code,l_arg_sale_code,"") 
	ELSE 
		OPEN WINDOW E236 with FORM "E236" 
		 CALL windecoration_e("E236") 
 
		CALL scan_sper() 
		 
		CLOSE WINDOW E236 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EC8_main()
###########################################################################


###########################################################################
# FUNCTION db_salesperson_product_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_salesperson_product_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			maingrp_code, 
			prodgrp_code, 
			part_code, 
			desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EC8","construct-sale_code-1") -- albo kd-502 
	
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
		
		MESSAGE kandoomsg2("E",1002,"") 
		LET l_query_text = 
			"SELECT ' ', sale_code,", 
			"name_text,", 
			"maingrp_code,", 
			"prodgrp_code, ", 
			"part_code,", 
			"desc_text ", 
			"FROM salesperson, product ", 
			"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND salesperson.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND status_ind != '3' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 2,4,5,6" 
		
		PREPARE s_salesperson FROM l_query_text 
		DECLARE c_salesperson cursor FOR s_salesperson 

	LET l_idx = 1 
	FOREACH c_salesperson INTO l_arr_rec_salesperson[l_idx].* 
		SELECT unique 1 FROM distsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_arr_rec_salesperson[l_idx].sale_code 
		AND maingrp_code = l_arr_rec_salesperson[l_idx].maingrp_code 
		AND prodgrp_code = l_arr_rec_salesperson[l_idx].prodgrp_code 
		AND part_code = l_arr_rec_salesperson[l_idx].part_code 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_salesperson[l_idx].stat_flag = NULL 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].stat_flag = "*" 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
		LET l_idx = l_idx + 1		
	END FOREACH 

	RETURN l_arr_rec_salesperson

END FUNCTION 
###########################################################################
# END FUNCTION db_salesperson_product_get_datasource(p_filter)
#
#
###########################################################################


###########################################################################
# FUNCTION scan_sper()
#
#
###########################################################################
FUNCTION scan_sper() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD -- array[100] OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_salesperson_product_get_datasource(FALSE) RETURNING l_arr_rec_salesperson 

	MESSAGE kandoomsg2("E",1099,"") #1099 Salesperson Distribution - RETURN TO View
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EC8","input-arr-l_arr_rec_salesperson-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesperson.clear()	
			CALL db_salesperson_product_get_datasource(TRUE) RETURNING l_arr_rec_salesperson
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION "REFRESH"
			 CALL windecoration_e("E184")
			CALL l_arr_rec_salesperson.clear()	
			CALL db_salesperson_product_get_datasource(FALSE) RETURNING l_arr_rec_salesperson
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION ("ACCEPT","DOUBLECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salesperson.getSize()) THEN
				IF l_arr_rec_salesperson[l_idx].sale_code IS NOT NULL THEN 
					CALL sper_dist(
						glob_rec_kandoouser.cmpy_code,
						l_arr_rec_salesperson[l_idx].sale_code, 
						l_arr_rec_salesperson[l_idx].part_code) 
				END IF 
			END IF
					
		BEFORE ROW 
			LET l_idx = arr_curr() 
						 
	END DISPLAY 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_sper()
#
#
###########################################################################


###########################################################################
# FUNCTION sper_dist(p_cmpy_code,p_sale_code,p_part_code)
#
#
###########################################################################
FUNCTION sper_dist(p_cmpy_code,p_sale_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_distsper RECORD LIKE distsper.* ## CURRENT year 
	DEFINE l_rec_prv_distsper RECORD LIKE distsper.* ## previous year 
	DEFINE l_arr_rec_distsper DYNAMIC ARRAY OF RECORD
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		mth_cust_num LIKE distsper.mth_cust_num, 
		mth_net_amt LIKE distsper.mth_net_amt, 
		mth_sales_qty LIKE distsper.mth_sales_qty, 
		prv_mth_cust_num LIKE distsper.mth_cust_num, 
		prv_mth_net_amt LIKE distsper.mth_net_amt, 
		prv_mth_sales_qty LIKE distsper.mth_sales_qty 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[1] OF RECORD 
		tot_mth_net_amt LIKE distsper.mth_net_amt, 
		tot_mth_sales_qty LIKE distsper.mth_sales_qty, 
		tot_prv_mth_net_amt LIKE distsper.mth_net_amt, 
		tot_prv_mth_sales_qty LIKE distsper.mth_sales_qty 
	END RECORD 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_prompt_text char(40)
	DEFINE l_sale_text char(40)
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 
	
	OPEN WINDOW E237 with FORM "E237" 
	 CALL windecoration_e("E237") 
 
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

	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*		 

	IF l_rec_salesperson.sale_code IS NOT NULL THEN 

		MENU " Inquiry level" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","EC8","menu-Inquiry_Level-1") -- albo kd-502 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Product" " Inquiry on product sales" 
				LET l_type_ind = "1" 
				IF p_part_code IS NOT NULL THEN 
					LET l_type_code = l_rec_product.part_code 
					EXIT MENU 
				ELSE 
					LET l_type_code = show_part(p_cmpy_code,"status_ind = '1'") 
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

			COMMAND KEY(INTERRUPT,"E")"Exit" " Exit inquiry" 
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
					LET l_where_text = "part_code = '",l_type_code,"'" 

				WHEN "2" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM prodgrp 
					WHERE cmpy_code = p_cmpy_code 
					AND prodgrp_code = l_type_code 
					LET l_prompt_text = kandooword("Product Group","1") 
					LET l_where_text = 
						"part_code IS NULL AND ", 
						"prodgrp_code='",l_type_code,"'" 

				WHEN "3" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM maingrp 
					WHERE cmpy_code = p_cmpy_code 
					AND maingrp_code = l_type_code 
					LET l_prompt_text = kandooword("Main Group","1") 
					LET l_where_text =
						"part_code IS NULL AND ", 
						"prodgrp_code IS NULL AND ", 
						"maingrp_code = '",l_type_code,"'" 

			END CASE 

			LET l_query_text =
				"SELECT * FROM distsper ", 
				"WHERE cmpy_code = '",p_cmpy_code,"' ", 
				"AND sale_code = '",p_sale_code,"' ", 
				"AND year_num = ? ", 
				"AND type_code = ? ", 
				"AND int_num = ? ", 
				"AND ",l_where_text clipped 
			PREPARE s_distsper FROM l_query_text 
			DECLARE c_distsper cursor FOR s_distsper 

			LET l_sale_text = kandooword("Salesperson","1") 
			LET l_sale_text = l_sale_text clipped,"........" 
			LET l_prompt_text = l_prompt_text clipped,"........" 
			LET l_rec_product.part_code = l_type_code 
			
			WHILE TRUE 
				MESSAGE kandoomsg2("E",1002,"") 

				CLEAR FORM 

				DISPLAY l_sale_text TO sale_text
				DISPLAY l_prompt_text TO prompt_text 
				DISPLAY BY NAME l_rec_salesperson.sale_code 
				DISPLAY BY NAME l_rec_salesperson.name_text 
				DISPLAY BY NAME l_rec_product.part_code 
				DISPLAY BY NAME l_rec_product.desc_text 

				LET i = glob_rec_statparms.year_num - 1 
				DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
				DISPLAY i TO sr_year[2].year_num 

				LET l_arr_rec_stattotal[1].tot_mth_net_amt = 0 
				LET l_arr_rec_stattotal[1].tot_mth_sales_qty = 0 
				LET l_arr_rec_stattotal[1].tot_prv_mth_net_amt = 0 
				LET l_arr_rec_stattotal[1].tot_prv_mth_sales_qty = 0
				 
				LET l_idx = 0 
				DECLARE c_statint cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = p_cmpy_code 
				AND year_num = glob_rec_statparms.year_num 
				AND type_code = glob_rec_statparms.mth_type_code 
				ORDER BY 1,2,3,4 

				FOREACH c_statint INTO l_rec_statint.* 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_distsper[l_idx].int_text = l_rec_statint.int_text
					
					#------------------------------------------------------- 
					# obtain current year gross,net AND disc%
					OPEN c_distsper USING 
						l_rec_statint.year_num, 
						l_rec_statint.type_code, 
						l_rec_statint.int_num 
					FETCH c_distsper INTO l_rec_cur_distsper.* 

					IF status = NOTFOUND THEN 
						LET l_rec_cur_distsper.mth_cust_num = 0 
						LET l_rec_cur_distsper.mth_net_amt = 0 
						LET l_rec_cur_distsper.mth_sales_qty = 0 
					END IF 

					LET l_arr_rec_distsper[l_idx].mth_cust_num = l_rec_cur_distsper.mth_cust_num 
					LET l_arr_rec_distsper[l_idx].mth_net_amt = l_rec_cur_distsper.mth_net_amt 
					LET l_arr_rec_distsper[l_idx].mth_sales_qty =	l_rec_cur_distsper.mth_sales_qty 

					#-------------------------------------------------------
					# obtain previous year gross,net AND disc%
					OPEN c_distsper USING 
						i, 
						l_rec_statint.type_code, 
						l_rec_statint.int_num 
					FETCH c_distsper INTO l_rec_prv_distsper.* 
					IF status = NOTFOUND THEN 
						LET l_rec_prv_distsper.mth_cust_num = 0 
						LET l_rec_prv_distsper.mth_net_amt = 0 
						LET l_rec_prv_distsper.mth_sales_qty = 0 
					END IF 

					LET l_arr_rec_distsper[l_idx].prv_mth_cust_num = l_rec_prv_distsper.mth_cust_num 
					LET l_arr_rec_distsper[l_idx].prv_mth_net_amt = l_rec_prv_distsper.mth_net_amt 
					LET l_arr_rec_distsper[l_idx].prv_mth_sales_qty = l_rec_prv_distsper.mth_sales_qty 

					#-------------------------------------------------------
					# increment totals
					LET l_arr_rec_stattotal[1].tot_mth_net_amt = l_arr_rec_stattotal[1].tot_mth_net_amt +	l_rec_cur_distsper.mth_net_amt 
					LET l_arr_rec_stattotal[1].tot_mth_sales_qty = l_arr_rec_stattotal[1].tot_mth_sales_qty +	l_rec_cur_distsper.mth_sales_qty 
					LET l_arr_rec_stattotal[1].tot_prv_mth_net_amt = l_arr_rec_stattotal[1].tot_prv_mth_net_amt +	l_rec_prv_distsper.mth_net_amt 
					LET l_arr_rec_stattotal[1].tot_prv_mth_sales_qty = l_arr_rec_stattotal[1].tot_prv_mth_sales_qty + l_rec_prv_distsper.mth_sales_qty 
				END FOREACH 

				IF l_idx = 0 THEN 
					MESSAGE kandoomsg2("E",7086,"")		#7086 No statistical information exists FOR this selection "
					EXIT WHILE 
				ELSE 
					DISPLAY l_arr_rec_stattotal[1].* TO sr_stattotal[1].* 

					MESSAGE kandoomsg2("E",1100,"") #Salesperson Distribution - F9 Previous Year - F10 Next Year

					DISPLAY ARRAY l_arr_rec_distsper TO sr_distsper.* ATTRIBUTE(UNBUFFERED) 
						BEFORE DISPLAY 
							CALL publish_toolbar("kandoo","EC8","input-arr-l_arr_rec_distsper-1") -- albo kd-502 

						ON ACTION "WEB-HELP" -- albo kd-370 
							CALL onlinehelp(getmoduleid(),null) 

						BEFORE ROW 
							LET l_idx = arr_curr() 

						ON ACTION "YEAR-1" --ON KEY (f9) 
							LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
							EXIT DISPLAY 

						ON ACTION "YEAR+1" --ON KEY (f10) 
							LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
							EXIT DISPLAY 

					END DISPLAY 

				END IF 

				IF int_flag THEN
					EXIT WHILE 
				END IF 
				
			END WHILE 

		END IF 
	END IF 
	
	CLOSE WINDOW E237
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_dist(p_cmpy_code,p_sale_code,p_part_code)
###########################################################################