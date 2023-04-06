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
GLOBALS "../eo/EB4_GLOBALS.4gl" 
###########################################################################
# FUNCTION EB4_main()
#
# EB4 - allows users TO SELECT a product/customer TO peruse
#       product sales information FROM statistics tables.
###########################################################################
FUNCTION EB4_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EB4") -- albo 

	IF get_url_part_code() IS NOT NULL THEN
		CALL prod_custurn(glob_rec_kandoouser.cmpy_code,get_url_part_code(),"") 
	ELSE 
		OPEN WINDOW E224 with FORM "E224" 
		 CALL windecoration_e("E224") -- albo kd-755 

		CALL scan_cust() 
 
		CLOSE WINDOW E224 
	END IF 
END FUNCTION 
###########################################################################
# FUNCTION EB4_main()
###########################################################################


###########################################################################
# FUNCTION select_cust() 
#
#
###########################################################################
FUNCTION db_product_customer_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			part_code, 
			desc_text, 
			maingrp_code, 
			prodgrp_code, 
			cust_code, 
			name_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EB4","construct-part_code-1") -- albo kd-502 
	
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
		 
	MESSAGE kandoomsg2("U",1002,"") 
	LET l_query_text = 
		"SELECT ' ', part_code,", 
		"desc_text,", 
		"maingrp_code,", 
		"prodgrp_code,", 
		"cust_code,", 
		"name_text ", 
		"FROM product, customer ", 
		"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND delete_flag = 'N' ", 
		"AND status_ind != '3' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 2,4,5,6" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer 

	LET l_idx = 1 
	FOREACH c_customer INTO l_arr_rec_customer[l_idx].* 
		SELECT unique 1 FROM statsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_arr_rec_customer[l_idx].cust_code 
		AND type_code = glob_rec_statparms.mth_type_code 
		AND part_code = l_arr_rec_customer[l_idx].part_code 
		AND prodgrp_code = l_arr_rec_customer[l_idx].prodgrp_code 
		AND maingrp_code = l_arr_rec_customer[l_idx].maingrp_code 
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
	LET l_idx = l_idx - 1 #correct idx

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9156,"") 
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
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_product_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer

	MESSAGE kandoomsg2("E",1096,"") #1096 Product/Customer Monthly Turnover - RETURN TO View
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EB4","input-arr-l_arr_rec_customer-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize()) 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		AFTER ROW
			#nothing

		AFTER DISPLAY
			#nothing

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL db_product_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer

		ON ACTION "REFRESH"
			 CALL windecoration_e("E224") 
			CALL l_arr_rec_customer.clear()
			CALL db_product_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD part_code
 			IF (l_idx > 0) AND (l_idx <= l_arr_rec_customer.getSize()) THEN 
				IF l_arr_rec_customer[l_idx].part_code IS NOT NULL THEN 
					CALL prod_custurn(
						glob_rec_kandoouser.cmpy_code,
						l_arr_rec_customer[l_idx].part_code, 
						l_arr_rec_customer[l_idx].cust_code) 
				END IF
			END IF			

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_cust() 
###########################################################################


###########################################################################
# FUNCTION prod_custurn(p_cmpy_code,p_part_code,p_cust_code)  
#
#
###########################################################################
FUNCTION prod_custurn(p_cmpy_code,p_part_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsale RECORD LIKE statsale.* ## CURRENT year 
	DEFINE l_rec_prv_statsale RECORD LIKE statsale.* ## previous year 
	DEFINE l_arr_rec_statsale DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		year_num LIKE statint.year_num, 
		sales_qty LIKE statsale.sales_qty, 
		grs_amt LIKE statsale.gross_amt, 
		net_amt LIKE statsale.net_amt, 
		disc_per FLOAT, 
		var_net_per LIKE statsale.net_amt, 
		prv_year_num LIKE statint.year_num, 
		prv_sales_qty LIKE statsale.sales_qty, 
		prv_grs_amt LIKE statsale.gross_amt, 
		prv_net_amt LIKE statsale.net_amt, 
		prv_disc_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_year_num LIKE statint.year_num, 
		tot_sales_qty LIKE statsale.sales_qty, 
		tot_grs_amt LIKE statsale.gross_amt, 
		tot_net_amt LIKE statsale.net_amt, 
		tot_disc_per FLOAT, 
		tot_var_net_per LIKE statsale.net_amt, 
		tot_prv_year_num LIKE statint.year_num, 
		tot_prv_sales_qty LIKE statsale.sales_qty, 
		tot_prv_grs_amt LIKE statsale.gross_amt, 
		tot_prv_net_amt LIKE statsale.net_amt, 
		tot_prv_disc_per FLOAT 
	END RECORD 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_cust_text char(40) 
	DEFINE l_prompt_text char(40) 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 

	OPEN WINDOW E219 with FORM "E219" 
	 CALL windecoration_e("E219") 

	CALL db_product_get_rec(UI_ON,p_part_code) RETURNING l_rec_product.* 
	IF l_rec_product.part_code IS NULL THEN  
		RETURN 
	END IF 

	WHILE TRUE 
		MENU " Inquiry level" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","EB4","menu-Inquiry Level-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Product" " Inquiry on customer/product sales" 
				LET l_type_ind = "1" 
				LET l_type_code = l_rec_product.part_code 
				EXIT MENU 

			COMMAND "PRODUCT GROUP" " Inquiry on customer/product-group sales" 
				LET l_type_ind = "2" 
				LET l_type_code = l_rec_product.prodgrp_code 
				EXIT MENU 

			COMMAND "MAIN GROUP" " Inquiry on customer/main-group sales" 
				LET l_type_ind = "3" 
				LET l_type_code = l_rec_product.maingrp_code 
				EXIT MENU 

			COMMAND KEY(INTERRUPT,"E")"Exit" " Exit inquiry" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 

		IF NOT (int_flag OR quit_flag) THEN 
			
			IF p_cust_code IS NULL THEN 
				LET p_cust_code = show_clnt(p_cmpy_code) 
				IF p_cust_code IS NULL THEN 
					CONTINUE WHILE 
				END IF 
			END IF 
			
		END IF
		 
		EXIT WHILE 
	END WHILE  #------------ END WHILE ----------------------------------------------------
	
	IF not(int_flag OR quit_flag) THEN 
		LET l_cust_text = kandooword("Customer","1") 

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
				SELECT desc_text 
				INTO l_rec_product.desc_text 
				FROM maingrp 
				WHERE cmpy_code = p_cmpy_code 
				AND maingrp_code = l_type_code 
				
				LET l_prompt_text = kandooword("Main Group","1") 
				LET l_where_text =
					"part_code IS NULL AND ", 
					"prodgrp_code IS NULL AND ", 
					"maingrp_code = '",l_type_code,"'" 
		END CASE 

		SELECT * INTO l_rec_customer.* 
		FROM customer 
		WHERE cmpy_code = p_cmpy_code 
		AND cust_code = p_cust_code
		 
		LET l_query_text =
			"SELECT * FROM statsale ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND cust_code = '",p_cust_code,"' ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			"AND ",l_where_text clipped 
		PREPARE s_statsale FROM l_query_text 
		DECLARE c_statsale cursor FOR s_statsale
		 
		LET l_cust_text = l_cust_text clipped,"........" 
		LET l_prompt_text = l_prompt_text clipped,"........" 
		LET l_rec_product.part_code = l_type_code 
		
		WHILE TRUE 
			CALL l_arr_rec_statsale.clear() #init/clear dynamic array

			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			
			DISPLAY l_cust_text TO cust_text
			DISPLAY l_prompt_text TO prompt_text
			 
			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text, 
				l_rec_product.part_code, 
				l_rec_product.desc_text 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_year_num = glob_rec_statparms.year_num 
				LET l_arr_rec_stattotal[i].tot_sales_qty = 0 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_year_num = glob_rec_statparms.year_num - 1 
				LET l_arr_rec_stattotal[i].tot_prv_sales_qty = 0 
				LET l_arr_rec_stattotal[i].tot_prv_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
			END FOR
			 
			LET l_idx = 0 
			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4
			 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsale[l_idx].int_text = l_rec_statint.int_text
				#------------------------------------------------------------ 
				# obtain current year gross,net AND disc%
				#------------------------------------------------------------
				OPEN c_statsale USING 
					l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num
				 
				LET l_arr_rec_statsale[l_idx].sales_qty = 0 
				LET l_arr_rec_statsale[l_idx].grs_amt = 0 
				LET l_arr_rec_statsale[l_idx].net_amt = 0
				 
				FOREACH c_statsale INTO l_rec_cur_statsale.* 
					IF l_rec_cur_statsale.sales_qty IS NULL THEN 
						LET l_rec_cur_statsale.sales_qty = 0 
					END IF 

					IF l_rec_cur_statsale.gross_amt IS NULL THEN 
						LET l_rec_cur_statsale.gross_amt = 0 
					END IF 

					IF l_rec_cur_statsale.net_amt IS NULL THEN 
						LET l_rec_cur_statsale.net_amt = 0 
					END IF 

					LET l_arr_rec_statsale[l_idx].sales_qty = l_rec_cur_statsale.sales_qty + l_arr_rec_statsale[l_idx].sales_qty 
					LET l_arr_rec_statsale[l_idx].grs_amt = l_rec_cur_statsale.gross_amt + l_arr_rec_statsale[l_idx].grs_amt 
					LET l_arr_rec_statsale[l_idx].net_amt = l_rec_cur_statsale.net_amt + l_arr_rec_statsale[l_idx].net_amt 
				END FOREACH 

				LET l_arr_rec_statsale[l_idx].year_num = glob_rec_statparms.year_num 

				IF l_arr_rec_statsale[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].disc_per = 100 * (1-(l_arr_rec_statsale[l_idx].net_amt/l_arr_rec_statsale[l_idx].grs_amt)) 
				END IF 
				
				#------------------------------------------------------------
				# obtain previous year gross,net AND disc%
				#------------------------------------------------------------
				LET i = glob_rec_statparms.year_num-1 
				OPEN c_statsale USING 
					i, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
				
				LET l_arr_rec_statsale[l_idx].prv_sales_qty = 0 
				LET l_arr_rec_statsale[l_idx].prv_grs_amt = 0 
				LET l_arr_rec_statsale[l_idx].prv_net_amt = 0
				 
				FOREACH c_statsale INTO l_rec_prv_statsale.* 
					IF l_rec_prv_statsale.sales_qty IS NULL THEN 
						LET l_rec_prv_statsale.sales_qty = 0 
					END IF 
					IF l_rec_prv_statsale.gross_amt IS NULL THEN 
						LET l_rec_prv_statsale.gross_amt = 0 
					END IF 
					IF l_rec_prv_statsale.net_amt IS NULL THEN 
						LET l_rec_prv_statsale.net_amt = 0 
					END IF 
					
					LET l_arr_rec_statsale[l_idx].prv_sales_qty = l_rec_prv_statsale.sales_qty + l_arr_rec_statsale[l_idx].prv_sales_qty 
					LET l_arr_rec_statsale[l_idx].prv_grs_amt = l_rec_prv_statsale.gross_amt + l_arr_rec_statsale[l_idx].prv_grs_amt 
					LET l_arr_rec_statsale[l_idx].prv_net_amt = l_rec_prv_statsale.net_amt + l_arr_rec_statsale[l_idx].prv_net_amt 
				END FOREACH
				 
				LET l_arr_rec_statsale[l_idx].prv_year_num = glob_rec_statparms.year_num - 1 

				IF l_arr_rec_statsale[l_idx].prv_grs_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statsale[l_idx].prv_net_amt/l_arr_rec_statsale[l_idx].prv_grs_amt)) 
				END IF 
				
				IF l_arr_rec_statsale[l_idx].prv_net_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].var_net_per = 100 * (l_arr_rec_statsale[l_idx].net_amt - l_arr_rec_statsale[l_idx].prv_net_amt) / l_arr_rec_statsale[l_idx].prv_net_amt 
				END IF
				
				#------------------------------------------------------------ 
				# increment totals
				#------------------------------------------------------------
				LET l_arr_rec_stattotal[1].tot_sales_qty = l_arr_rec_stattotal[1].tot_sales_qty + l_arr_rec_statsale[l_idx].sales_qty 
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_arr_rec_statsale[l_idx].grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_arr_rec_statsale[l_idx].net_amt 
				LET l_arr_rec_stattotal[1].tot_prv_sales_qty = l_arr_rec_stattotal[1].tot_prv_sales_qty + l_arr_rec_statsale[l_idx].prv_sales_qty 
				LET l_arr_rec_stattotal[1].tot_prv_grs_amt = l_arr_rec_stattotal[1].tot_prv_grs_amt + l_arr_rec_statsale[l_idx].prv_grs_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_arr_rec_statsale[l_idx].prv_net_amt
				 
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_sales_qty = l_arr_rec_stattotal[2].tot_sales_qty	+ l_arr_rec_statsale[l_idx].sales_qty 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_arr_rec_statsale[l_idx].grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_arr_rec_statsale[l_idx].net_amt 
					LET l_arr_rec_stattotal[2].tot_prv_sales_qty = l_arr_rec_stattotal[2].tot_prv_sales_qty + l_arr_rec_statsale[l_idx].prv_sales_qty 
					LET l_arr_rec_stattotal[2].tot_prv_grs_amt = l_arr_rec_stattotal[2].tot_prv_grs_amt + l_arr_rec_statsale[l_idx].prv_grs_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = l_arr_rec_stattotal[2].tot_prv_net_amt + l_arr_rec_statsale[l_idx].prv_net_amt 
				END IF 

			END FOREACH #---------------- END FOR EACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "		
				SLEEP 2
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2
					#------------------------------------------------------------ 
					# calc total current & previous year disc%
					#------------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 
							100 * (1-(l_arr_rec_stattotal[i].tot_net_amt /l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF
					 
					IF l_arr_rec_stattotal[i].tot_prv_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 
							100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt /l_arr_rec_stattotal[i].tot_prv_grs_amt)) 
					END IF
					
					#------------------------------------------------------------ 
					# calc total net variance
					#------------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 100 * ( l_arr_rec_stattotal[i].tot_net_amt - l_arr_rec_stattotal[i].tot_prv_net_amt) / l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				
				MESSAGE kandoomsg2("E",1080,"")	#Product Monthly Turnover - F9 Previous Year - F10 Next Year

				DISPLAY ARRAY l_arr_rec_statsale TO sr_statsale.* 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EB4","input-arr-l_arr_rec_statsale-1") 

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
				CALL l_arr_rec_statsale.clear()
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		
	END IF 
	
	CLOSE WINDOW E219 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION prod_custurn(p_cmpy_code,p_part_code,p_cust_code)  
###########################################################################