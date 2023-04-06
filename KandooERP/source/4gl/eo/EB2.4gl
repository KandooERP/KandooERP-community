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
GLOBALS "../eo/EB_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EB2_GLOBALS.4gl" 
###########################################################################
# FUNCTION EB2_main()
#
# EB2 - allows users TO SELECT a product TO peruse product
#       sales information FROM statistics tables.
###########################################################################
FUNCTION EB2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EB2")  

	IF get_url_part_code() IS NOT NULL THEN 
		CALL prod_turnover(glob_rec_kandoouser.cmpy_code,get_url_part_code()) 
	ELSE 
		OPEN WINDOW E223 with FORM "E223" 
		 CALL windecoration_e("E223") 
 
		CALL scan_prod() 
 
		CLOSE WINDOW E223 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EB2_main()
###########################################################################


###########################################################################
# FUNCTION db_product_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION db_product_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		short_desc_text LIKE product.short_desc_text, 
		desc_text LIKE product.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			short_desc_text, 
			desc_text, 
			maingrp_code, 
			prodgrp_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EB2","construct-part_code-1") -- albo kd-502 
	
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
	
	LET l_query_text = 
		"SELECT * FROM product ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"AND status_ind != '3' " 
	PREPARE s_product FROM l_query_text 
	DECLARE c_product cursor FOR s_product 

	LET l_idx = 0 
	FOREACH c_product INTO l_rec_product.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_product[l_idx].part_code = l_rec_product.part_code 
		LET l_arr_rec_product[l_idx].short_desc_text = l_rec_product.short_desc_text 
		LET l_arr_rec_product[l_idx].desc_text = l_rec_product.desc_text 
		LET l_arr_rec_product[l_idx].maingrp_code = l_rec_product.maingrp_code 
		LET l_arr_rec_product[l_idx].prodgrp_code = l_rec_product.prodgrp_code
		 
		SELECT unique 1 FROM statprod 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND part_code = l_rec_product.part_code 
		AND maingrp_code = l_rec_product.maingrp_code 
		AND prodgrp_code = l_rec_product.prodgrp_code 
		AND type_code = glob_rec_statparms.mth_type_code 
		IF status = 0 THEN 
			LET l_arr_rec_product[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_product[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
		
	END FOREACH
	 
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9156,"") 
	END IF 

	RETURN l_arr_rec_product
END FUNCTION 
###########################################################################
# END FUNCTION select_prod() 
###########################################################################


###########################################################################
# FUNCTION scan_prod() 
#
#
###########################################################################
FUNCTION scan_prod() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		short_desc_text LIKE product.short_desc_text, 
		desc_text LIKE product.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_count SMALLINT
	DEFINE l_filter_switch BOOLEAN

	SELECT COUNT(*) INTO l_count FROM product 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	
	AND status_ind != '3'

	IF l_count < glob_rec_settings.maxListArraySizeSwitch THEN
		LET l_filter_switch = FALSE
	END IF
	
	CALL db_product_get_datasource(l_filter_switch) RETURNING l_arr_rec_product
	
	MESSAGE kandoomsg2("E",1083,"") 	#1083 Products Monthly Turnover - RETURN TO View
	DISPLAY ARRAY l_arr_rec_product TO sr_product.*

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EB2","input-arr-l_arr_rec_product-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_product.clear()
			CALL db_product_get_datasource(TRUE) RETURNING l_arr_rec_product
			
		ON ACTION "REFRESH"
			 CALL windecoration_e("E223")
			CALL l_arr_rec_product.clear()
			CALL db_product_get_datasource(FALSE) RETURNING l_arr_rec_product
		
		BEFORE ROW 
			LET l_idx = arr_curr() 
	 
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD part_code 
			IF l_arr_rec_product[l_idx].part_code IS NOT NULL THEN 
				CALL prod_turnover(glob_rec_kandoouser.cmpy_code,l_arr_rec_product[l_idx].part_code) 
			END IF 

	END DISPLAY
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_prod() 
###########################################################################


###########################################################################
# FUNCTION prod_turnover(p_cmpy_code,p_part_code)
#
#
###########################################################################
FUNCTION prod_turnover(p_cmpy_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statprod RECORD LIKE statprod.* ## CURRENT year 
	DEFINE l_rec_prv_statprod RECORD LIKE statprod.* ## previous year 
	DEFINE l_arr_rec_statprod DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		gross_amt LIKE statprod.gross_amt, 
		net_amt LIKE statprod.net_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statprod.net_amt, 
		prv_disc_per FLOAT, 
		var_grs_per LIKE statprod.gross_amt, 
		var_net_per LIKE statprod.net_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal ARRAY[2] OF RECORD 
		tot_grs_amt LIKE statprod.gross_amt, 
		tot_net_amt LIKE statprod.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statprod.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_grs_per LIKE statprod.gross_amt, 
		tot_var_net_per LIKE statprod.net_amt 
	END RECORD 
	DEFINE l_arr_totprvgrs_amt ARRAY[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code 
	DEFINE l_prompt_text char(40) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
 
	CALL db_product_get_rec(UI_ON,p_part_code) RETURNING l_rec_product.* 
	IF l_rec_product.part_code IS NULL THEN  
		RETURN 
	END IF 
	
	OPEN WINDOW E227 with FORM "E227" 
	 CALL windecoration_e("E227") 
 
	MENU " Inquiry level" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","EB2","menu-Inquiry_Level-1")  

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Products" " Inquire upon product sales figures" 
			LET l_type_ind = "1" 
			LET l_type_code = l_rec_product.part_code 
			EXIT MENU 

		COMMAND "PRODUCT GROUP" " Inquire upon product-group sales figures" 
			LET l_type_ind = "2" 
			LET l_type_code = l_rec_product.prodgrp_code 
			EXIT MENU 

		COMMAND "MAIN GROUP"		" Inquire upon main-product-group sales figures" 
			LET l_type_ind = "3" 
			LET l_type_code = l_rec_product.maingrp_code 
			EXIT MENU 
			
		COMMAND KEY(INTERRUPT,"E")"Exit"	" Exit inquiry" 
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
					"maingrp_code='",l_type_code,"'" 

		END CASE
		 
		LET l_prompt_text = l_prompt_text clipped,"........" 
		LET l_rec_product.part_code = l_type_code
		 
		LET l_query_text = 
			"SELECT * FROM statprod ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			"AND ",l_where_text clipped 
		PREPARE s_statprod FROM l_query_text 
		DECLARE c_statprod cursor FOR s_statprod 
		
		WHILE TRUE 
			CALL l_arr_rec_statprod.clear() #clear/init dynamic array

			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 

			DISPLAY l_prompt_text TO prompt_text
			DISPLAY l_rec_product.part_code TO part_code
			DISPLAY l_rec_product.desc_text TO desc_text 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
				LET l_arr_totprvgrs_amt[i] = 0 
			END FOR 
			
			LET i = glob_rec_statparms.year_num - 1 
			
			DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num
			DISPLAY i TO sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			
			ORDER BY 1,2,3,4 
			LET l_idx = 0 
			
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statprod[l_idx].int_text = l_rec_statint.int_text
				 
				#--------------------------------------------------------
				# obtain current year gross,net AND disc%
				#--------------------------------------------------------
				OPEN c_statprod USING 
					l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
				FETCH c_statprod INTO l_rec_cur_statprod.* 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statprod.gross_amt = 0 
					LET l_rec_cur_statprod.net_amt = 0 
				END IF 
				
				LET l_arr_rec_statprod[l_idx].gross_amt = l_rec_cur_statprod.gross_amt 
				LET l_arr_rec_statprod[l_idx].net_amt = l_rec_cur_statprod.net_amt 
				IF l_arr_rec_statprod[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statprod[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].disc_per = 100 * (1-(l_arr_rec_statprod[l_idx].net_amt/l_arr_rec_statprod[l_idx].gross_amt)) 
				END IF 
				
				#--------------------------------------------------------
				# obtain previous year gross,net AND disc%
				#--------------------------------------------------------
				OPEN c_statprod USING 
					i, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 

				FETCH c_statprod INTO l_rec_prv_statprod.* 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statprod.gross_amt = 0 
					LET l_rec_prv_statprod.net_amt = 0 
				END IF 

				LET l_arr_rec_statprod[l_idx].prv_net_amt = l_rec_prv_statprod.net_amt 
				
				IF l_rec_prv_statprod.gross_amt = 0 THEN 
					LET l_arr_rec_statprod[l_idx].prv_disc_per = 0 
					LET l_arr_rec_statprod[l_idx].var_grs_per = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statprod[l_idx].prv_net_amt/l_rec_prv_statprod.gross_amt)) 
					LET l_arr_rec_statprod[l_idx].var_grs_per = 100*(l_arr_rec_statprod[l_idx].gross_amt-l_rec_prv_statprod.gross_amt) / l_rec_prv_statprod.gross_amt 
				END IF 

				IF l_rec_prv_statprod.net_amt = 0 THEN 
					LET l_arr_rec_statprod[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].var_net_per = 100	* (l_arr_rec_statprod[l_idx].net_amt - l_arr_rec_statprod[l_idx].prv_net_amt)	/ l_arr_rec_statprod[l_idx].prv_net_amt 
				END IF
				
				#-------------------------------------------------------- 
				# increment totals
				#--------------------------------------------------------
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statprod.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statprod.net_amt 
				LET l_arr_totprvgrs_amt[1] = l_arr_totprvgrs_amt[1] + l_rec_prv_statprod.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statprod.net_amt 

				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statprod.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statprod.net_amt 
					LET l_arr_totprvgrs_amt[2] = l_arr_totprvgrs_amt[2] + l_rec_prv_statprod.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statprod.net_amt 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")		#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2
					
					#-------------------------------------------------------- 
					# calc total current & previous year disc%
					#--------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt /l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					
					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_totprvgrs_amt[i])) 
					END IF
					
					#-------------------------------------------------------- 
					# calc total current & previous year net & gross variance
					#--------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 100 * ( l_arr_rec_stattotal[i].tot_net_amt	- l_arr_rec_stattotal[i].tot_prv_net_amt) / l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					
					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 100 * (l_arr_rec_stattotal[i].tot_grs_amt-l_arr_totprvgrs_amt[i])	/ l_arr_totprvgrs_amt[i] 
					END IF 
					
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1080,"")			#1080 Inventory Monthly Turnover - F9 Previous Year - F10 Next Year

				DISPLAY ARRAY l_arr_rec_statprod TO sr_statprod.* 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EB2","input-arr-l_arr_rec_statprod-1") 

					ON ACTION "WEB-HELP" 
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

			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statprod.clear()
			ELSE 
				EXIT WHILE 
			END IF 

			IF int_flag THEN  --user cancel
				EXIT WHILE 
			END IF 

		END WHILE 

	END IF 
	
	CLOSE WINDOW E227 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION prod_turnover(p_cmpy_code,p_part_code)
###########################################################################