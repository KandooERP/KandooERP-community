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
GLOBALS "../eo/EB3_GLOBALS.4gl" 
###########################################################################
# FUNCTION EB3_main()
#
# EB3 - allows users TO SELECT a product TO peruse product
#       sales information FROM statistics tables.
###########################################################################
FUNCTION EB3_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EB3") -- albo 

	IF get_url_part_code() IS NOT NULL THEN 
		CALL prod_boughtsold(glob_rec_kandoouser.cmpy_code,get_url_part_code()) 
	ELSE 
		OPEN WINDOW E223 with FORM "E223" 
		 CALL windecoration_e("E223") -- albo kd-755
 
		CALL scan_prod() 
		
		CLOSE WINDOW E223 
	END IF 
END FUNCTION 


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
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD --rray[100] OF RECORD 
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
				CALL publish_toolbar("kandoo","EB3","construct-part_code-1") -- albo kd-502 
	
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
# END FUNCTION db_product_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_prod()
#
#
###########################################################################
FUNCTION scan_prod() 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD --rray[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		short_desc_text LIKE product.short_desc_text, 
		desc_text LIKE product.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
 
	CALL db_product_get_datasource(FALSE) RETURNING l_arr_rec_product
	
	MESSAGE kandoomsg2("E",1163,"") #1163 Items Bought & Sold Comparison - RETURN TO View
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EB3","input-arr-l_arr_rec_product-1") -- albo kd-502 

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
				CALL prod_boughtsold(glob_rec_kandoouser.cmpy_code,l_arr_rec_product[l_idx].part_code) 
			END IF 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_prod()
###########################################################################


###########################################################################
# FUNCTION prod_boughtsold(p_cmpy_code,p_part_code) 
#
#
###########################################################################
FUNCTION prod_boughtsold(p_cmpy_code,p_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_cur_statint RECORD LIKE statint.* ## CURRENT year 
	DEFINE l_rec_prv_statint RECORD LIKE statint.* ## previous year 
	DEFINE l_rec_cur_statprod RECORD LIKE statprod.* ## CURRENT year 
	DEFINE l_rec_prv_statprod RECORD LIKE statprod.* ## previous year 
	DEFINE l_arr_rec_statprod array[20] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		purch_qty LIKE statprod.sales_qty, 
		sales_qty LIKE statprod.sales_qty, 
		disc_per FLOAT, 
		prv_purch_qty LIKE statprod.sales_qty, 
		prv_sales_qty LIKE statprod.sales_qty, 
		prv_disc_per FLOAT, 
		purch_var_per FLOAT, 
		sales_var_per LIKE statprod.sales_qty 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD # 1-> year total 2-> ytd total 
		tot_purch_qty LIKE statprod.sales_qty, 
		tot_sales_qty LIKE statprod.sales_qty, 
		tot_disc_per FLOAT, 
		tot_prv_purch_qty LIKE statprod.sales_qty, 
		tot_prv_sales_qty LIKE statprod.sales_qty, 
		tot_prv_disc_per FLOAT, 
		tot_purch_var_per FLOAT, 
		tot_sales_var_per LIKE statprod.sales_qty 
	END RECORD 
	DEFINE l_totalamt array[2] OF RECORD # 1-> year total 2-> ytd total 
		cur_grs_amt LIKE statprod.gross_amt, 
		cur_net_amt LIKE statprod.net_amt, 
		prv_grs_amt LIKE statprod.gross_amt, 
		prv_net_amt LIKE statprod.net_amt 
	END RECORD 
	DEFINE l_prompt_text char(40) 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	CALL db_product_get_rec(UI_ON,p_part_code) RETURNING l_rec_product.* 
	IF l_rec_product.part_code IS NULL THEN  
		RETURN 
	END IF 

	OPEN WINDOW E290 with FORM "E290" 
	 CALL windecoration_e("E290") -- albo kd-755
 
	MENU " Inquiry level" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","EB3","menu-Inquiry_Level-1") -- albo kd-502
 
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null)
			 
		COMMAND "Products"	" Inquire upon product sales figures" 
			LET l_prompt_text = kandooword("Product","1") 
			SELECT desc_text INTO l_rec_product.desc_text 
			FROM product 
			WHERE cmpy_code = p_cmpy_code 
			AND part_code = l_rec_product.part_code 
			
			LET l_where_text = "part_code = '",l_rec_product.part_code,"'" 
			LET l_query_text = 
				"SELECT sum(tran_qty) FROM prodledg ", 
				"WHERE cmpy_code='",p_cmpy_code,"' ", 
				"AND part_code = '",l_rec_product.part_code,"' ", 
				"AND tran_date between ? AND ? ", 
				"AND trantype_ind in ('P','R')" 
			EXIT MENU
			 
		COMMAND "PRODUCT GROUP"	" Inquire upon product-group sales figures" 
			LET l_prompt_text = kandooword("Product Group","1") 
			SELECT desc_text INTO l_rec_product.desc_text 
			FROM prodgrp 
			WHERE cmpy_code = p_cmpy_code 
			AND prodgrp_code = l_rec_product.prodgrp_code 
			LET l_where_text =
				"part_code IS NULL AND ", 
				"prodgrp_code='",l_rec_product.prodgrp_code,"'"
			 
			LET l_query_text = 
				"SELECT sum(tran_qty) FROM prodledg,product ", 
				"WHERE product.cmpy_code='",p_cmpy_code,"' ", 
				"AND prodgrp_code='",l_rec_product.prodgrp_code,"' ", 
				"AND prodledg.cmpy_code='",p_cmpy_code,"' ", 
				"AND prodledg.part_code = product.part_code ", 
				"AND tran_date between ? AND ? ", 
				"AND trantype_ind in ('P','R')" 

			#-------------------------------------------------------------
			# store prodgrp in part_code FOR the display
			#-------------------------------------------------------------
			LET l_rec_product.part_code = l_rec_product.prodgrp_code 
			 
		COMMAND "MAIN GROUP"	" Inquire upon main-product-group sales figures" 
			LET l_prompt_text = kandooword("Main Group","1") 
			SELECT desc_text INTO l_rec_product.desc_text 
			FROM maingrp 
			WHERE cmpy_code = p_cmpy_code 
			AND maingrp_code = l_rec_product.maingrp_code 
			LET l_where_text ="part_code IS NULL AND prodgrp_code IS null" 
			LET l_query_text = 
				"SELECT sum(tran_qty) FROM prodledg,product ", 
				"WHERE product.cmpy_code='",p_cmpy_code,"' ", 
				"AND maingrp_code='",l_rec_product.maingrp_code,"' ", 
				"AND prodledg.cmpy_code='",p_cmpy_code,"' ", 
				"AND prodledg.part_code = product.part_code ", 
				"AND tran_date between ? AND ? ", 
				"AND trantype_ind in ('P','R')" 

			#-------------------------------------------------------------
			# store maingrp in part_code FOR the display
			#-------------------------------------------------------------
			LET l_rec_product.part_code = l_rec_product.maingrp_code 
			EXIT MENU 

		ON ACTION "CANCEL" --COMMAND KEY(INTERRUPT,"E")"Exit"	" Exit inquiry" 
			LET quit_flag = TRUE 
			EXIT MENU 
	END MENU 

	IF not(int_flag OR quit_flag) THEN 
		PREPARE s_prodledg FROM l_query_text 
		DECLARE c_prodledg cursor FOR s_prodledg 
		LET l_query_text = 
			"SELECT * FROM statprod ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			"AND maingrp_code='",l_rec_product.maingrp_code,"' ", 
			"AND ",l_where_text clipped 

		PREPARE s_statprod FROM l_query_text 
		DECLARE c_statprod cursor FOR s_statprod 
		LET l_prompt_text = l_prompt_text clipped,"........" 

		WHILE TRUE 
			CALL l_arr_rec_statprod.clear() #Clear/init dynamic array
			
			CLEAR FORM 
			MESSAGE kandoomsg2("E",1002,"") 
			DISPLAY l_prompt_text TO prompt_text
			DISPLAY l_rec_product.part_code TO part_code 
			DISPLAY l_rec_product.desc_text TO desc_text 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_purch_qty = 0 
				LET l_arr_rec_stattotal[i].tot_sales_qty = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_purch_qty = 0 
				LET l_arr_rec_stattotal[i].tot_prv_sales_qty = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_purch_var_per = 0 
				LET l_arr_rec_stattotal[i].tot_sales_var_per = 0 
				LET l_totalamt[i].cur_grs_amt = 0 
				LET l_totalamt[i].cur_net_amt = 0 
				LET l_totalamt[i].prv_grs_amt = 0 
				LET l_totalamt[i].prv_net_amt = 0 
			END FOR 

			LET l_rec_prv_statint.year_num = glob_rec_statparms.year_num - 1 

			DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY l_rec_prv_statint.year_num TO sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 

			ORDER BY 1,2,3,4 
			LET l_idx = 0 

			FOREACH c_statint INTO l_rec_cur_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statprod[l_idx].int_text = l_rec_cur_statint.int_text 

				#-------------------------------------------------------------
				# obtain current year bought,sold, AND disc%
				#-------------------------------------------------------------
				OPEN c_prodledg USING 
					l_rec_cur_statint.start_date, 
					l_rec_cur_statint.end_date 
				FETCH c_prodledg INTO l_arr_rec_statprod[l_idx].purch_qty 

				IF l_arr_rec_statprod[l_idx].purch_qty IS NULL THEN 
					LET l_arr_rec_statprod[l_idx].purch_qty = 0 
				END IF 
				
				OPEN c_statprod USING 
					l_rec_cur_statint.year_num, 
					l_rec_cur_statint.type_code, 
					l_rec_cur_statint.int_num 
				FETCH c_statprod INTO l_rec_cur_statprod.* 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_statprod[l_idx].sales_qty = 0 
					LET l_arr_rec_statprod[l_idx].disc_per = 0 
					LET l_rec_cur_statprod.gross_amt = 0 
					LET l_rec_cur_statprod.net_amt = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].sales_qty = l_rec_cur_statprod.sales_qty 
					IF l_rec_cur_statprod.gross_amt = 0 THEN 
						LET l_arr_rec_statprod[l_idx].disc_per = 0 
					ELSE 
						LET l_arr_rec_statprod[l_idx].disc_per = 100 * 
						(1-(l_rec_cur_statprod.net_amt/l_rec_cur_statprod.gross_amt)) 
					END IF 
				END IF 

				#-------------------------------------------------------------
				# obtain previous year bought,sold, AND disc%
				#-------------------------------------------------------------
				SELECT * INTO l_rec_prv_statint.* 
				FROM statint 
				WHERE cmpy_code = p_cmpy_code 
				AND year_num = l_rec_cur_statint.year_num - 1 
				AND type_code = l_rec_cur_statint.type_code 
				AND int_num = l_rec_cur_statint.int_num 
				
				IF status = NOTFOUND THEN 
					LET l_arr_rec_statprod[l_idx].prv_purch_qty = 0 
					LET l_arr_rec_statprod[l_idx].prv_sales_qty = 0 
					LET l_arr_rec_statprod[l_idx].prv_disc_per = 0 
					LET l_rec_prv_statprod.gross_amt = 0 
					LET l_rec_prv_statprod.net_amt = 0 
				ELSE 
					OPEN c_prodledg USING 
						l_rec_prv_statint.start_date, 
						l_rec_prv_statint.end_date 
					FETCH c_prodledg INTO l_arr_rec_statprod[l_idx].prv_purch_qty 
					IF l_arr_rec_statprod[l_idx].prv_purch_qty IS NULL THEN 
						LET l_arr_rec_statprod[l_idx].prv_purch_qty = 0 
					END IF 
					
					OPEN c_statprod USING 
						l_rec_prv_statint.year_num, 
						l_rec_prv_statint.type_code, 
						l_rec_prv_statint.int_num 
					FETCH c_statprod INTO l_rec_prv_statprod.* 
					
					IF status = NOTFOUND THEN 
						LET l_arr_rec_statprod[l_idx].prv_sales_qty = 0 
						LET l_arr_rec_statprod[l_idx].prv_disc_per = 0 
						LET l_rec_prv_statprod.gross_amt = 0 
						LET l_rec_prv_statprod.net_amt = 0 
					ELSE 
						LET l_arr_rec_statprod[l_idx].prv_sales_qty = l_rec_prv_statprod.sales_qty 
						IF l_rec_prv_statprod.gross_amt = 0 THEN 
							LET l_arr_rec_statprod[l_idx].prv_disc_per = 0 
						ELSE 
							LET l_arr_rec_statprod[l_idx].prv_disc_per = 100 * (1-(l_rec_prv_statprod.net_amt/l_rec_prv_statprod.gross_amt)) 
						END IF 
					END IF 
				END IF 

				IF l_arr_rec_statprod[l_idx].prv_purch_qty = 0 THEN 
					LET l_arr_rec_statprod[l_idx].purch_var_per = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].purch_var_per = 100 * (l_arr_rec_statprod[l_idx].purch_qty-l_arr_rec_statprod[l_idx].prv_purch_qty)	/ l_arr_rec_statprod[l_idx].prv_purch_qty 
				END IF 
				
				IF l_arr_rec_statprod[l_idx].prv_sales_qty = 0 THEN 
					LET l_arr_rec_statprod[l_idx].sales_var_per = 0 
				ELSE 
					LET l_arr_rec_statprod[l_idx].sales_var_per = 100 * (l_arr_rec_statprod[l_idx].sales_qty-l_arr_rec_statprod[l_idx].prv_sales_qty)	/ l_arr_rec_statprod[l_idx].prv_sales_qty 
				END IF

				#-------------------------------------------------------------				 
				# increment totals
				#-------------------------------------------------------------
				FOR i = 1 TO 2 
					LET l_arr_rec_stattotal[i].tot_purch_qty = l_arr_rec_stattotal[i].tot_purch_qty + l_arr_rec_statprod[l_idx].purch_qty 
					LET l_arr_rec_stattotal[i].tot_sales_qty = l_arr_rec_stattotal[i].tot_sales_qty + l_arr_rec_statprod[l_idx].sales_qty 
					LET l_arr_rec_stattotal[i].tot_prv_purch_qty = l_arr_rec_stattotal[i].tot_prv_purch_qty + l_arr_rec_statprod[l_idx].prv_purch_qty 
					LET l_arr_rec_stattotal[i].tot_prv_sales_qty = l_arr_rec_stattotal[i].tot_prv_sales_qty + l_arr_rec_statprod[l_idx].prv_sales_qty 
					LET l_totalamt[i].cur_grs_amt = l_totalamt[i].cur_grs_amt + l_rec_cur_statprod.gross_amt 
					LET l_totalamt[i].cur_net_amt = l_totalamt[i].cur_net_amt + l_rec_cur_statprod.net_amt 
					LET l_totalamt[i].prv_grs_amt = l_totalamt[i].prv_grs_amt + l_rec_prv_statprod.gross_amt 
					LET l_totalamt[i].prv_net_amt = l_totalamt[i].prv_net_amt + l_rec_prv_statprod.net_amt 
					
					IF l_rec_cur_statint.int_num > glob_rec_statparms.mth_num THEN 
						EXIT FOR 
					END IF 
				END FOR 
--				IF l_idx = 20 THEN 
--					EXIT FOREACH 
--				END IF 
			END FOREACH 
	
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
				
					#-------------------------------------------------------------
					# calc total current & previous year disc%
					#-------------------------------------------------------------
					IF l_totalamt[i].cur_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 *(1-(l_totalamt[i].cur_net_amt/l_totalamt[i].cur_grs_amt)) 
					END IF 
					
					IF l_totalamt[i].prv_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_totalamt[i].prv_net_amt/l_totalamt[i].prv_grs_amt)) 
					END IF

					#-------------------------------------------------------------					 
					# calc total current & previous year bought & sold variance
					#-------------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_prv_sales_qty = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_sales_var_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_sales_var_per = 100 * (l_arr_rec_stattotal[i].tot_sales_qty - l_arr_rec_stattotal[i].tot_prv_sales_qty) / l_arr_rec_stattotal[i].tot_prv_sales_qty 
					END IF
					 
					IF l_arr_rec_stattotal[i].tot_prv_purch_qty = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_purch_var_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_purch_var_per = 100 * ( l_arr_rec_stattotal[i].tot_purch_qty - l_arr_rec_stattotal[i].tot_prv_purch_qty)	/ l_arr_rec_stattotal[i].tot_prv_purch_qty 
					END IF 
					
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR
				 
				MESSAGE kandoomsg2("E",1164,"")	#1164 Items Bought & Sold - F9 Previous Year - F10 Next Year

				DISPLAY ARRAY l_arr_rec_statprod TO sr_statprod.* 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EB3","input-arr-l_arr_rec_statprod-1") -- albo kd-502 

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

			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statprod.clear()
			ELSE 
				EXIT WHILE 
			END IF 
			
			IF int_flag THEN
				EXIT WHILE 
			END IF 

		END WHILE 

	END IF 
	
	CLOSE WINDOW E290 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION prod_boughtsold(p_cmpy_code,p_part_code) 
###########################################################################