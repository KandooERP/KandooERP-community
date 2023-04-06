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
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EA_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EA4_GLOBALS.4gl" 
###########################################################################
# FUNCTION cust_prodturn(p_cmpy_code,p_cust_code,p_type_code,p_type_ind,p_year_num)
#
# Salesperson Inquiries
###########################################################################
FUNCTION cust_prodturn(p_cmpy_code,p_cust_code,p_type_code,p_type_ind,p_year_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_type_code LIKE product.part_code
	DEFINE p_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE p_year_num SMALLINT
	 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
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
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_cust_text char(40) 
	DEFINE l_prompt_text char(40) 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = p_cust_code 

	IF p_type_ind IS NULL THEN 

		SELECT * INTO l_rec_product.* 
		FROM product 
		WHERE cmpy_code = p_cmpy_code 
		AND part_code = p_type_code 

		MENU " Inquiry level" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","EA4a","menu-Inquiry_Level-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Product" " Inquiry on customer/product sales" 
				LET p_type_ind = "1" 
				IF p_type_code IS NULL THEN 
					LET p_type_code = show_part(p_cmpy_code,"status_ind = '1'") 
				END IF 
				IF p_type_code IS NOT NULL THEN 
					EXIT MENU 
				END IF 

			COMMAND "PRODUCT GROUP" " Inquiry on customer/product-group sales"  --"PRODUCT GROUP" " Inquiry on customer/product-group sales" 
				LET p_type_ind = "2" 
				IF p_type_code IS NULL THEN 
					LET p_type_code = show_prodgrp(p_cmpy_code,"") 
					IF p_type_code IS NOT NULL THEN 
						EXIT MENU 
					END IF 
				ELSE 
					LET p_type_code = l_rec_product.prodgrp_code 
				END IF 
				IF p_type_code IS NOT NULL THEN 
					EXIT MENU 
				END IF 

			COMMAND "MAIN GROUP" " Inquiry on customer/main-group sales" --"MAIN GROUP" " Inquiry on customer/main-group sales" 
				LET p_type_ind = "3" 
				IF p_type_code IS NULL THEN 
					LET p_type_code = show_maingrp(p_cmpy_code,"") 
					IF p_type_code IS NOT NULL THEN 
						EXIT MENU 
					END IF 
				ELSE 
					LET p_type_code = l_rec_product.maingrp_code 
				END IF 
				IF p_type_code IS NOT NULL THEN 
					EXIT MENU 
				END IF 

			COMMAND KEY(INTERRUPT,"E")"Exit" " Exit inquiry" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 

	END IF 

	IF not(int_flag OR quit_flag) THEN 
		LET l_cust_text = kandooword("Customer","1") 

		CASE p_type_ind 
			WHEN "1" 
				LET l_prompt_text = kandooword("Product","1") 
				SELECT desc_text INTO l_rec_product.desc_text 
				FROM product 
				WHERE cmpy_code = p_cmpy_code 
				AND part_code = p_type_code 
				LET l_where_text = "part_code = '",p_type_code,"'" 

			WHEN "2" 
				SELECT desc_text INTO l_rec_product.desc_text 
				FROM prodgrp 
				WHERE cmpy_code = p_cmpy_code 
				AND prodgrp_code = p_type_code 
				LET l_prompt_text = kandooword("Product Group","1") 
				LET l_where_text ="part_code IS NULL ", 
				"AND prodgrp_code='",p_type_code,"'" 

			WHEN "3" 
				SELECT desc_text INTO l_rec_product.desc_text 
				FROM maingrp 
				WHERE cmpy_code = p_cmpy_code 
				AND maingrp_code = p_type_code 
				LET l_prompt_text = kandooword("Main Group","1") 
				LET l_where_text ="part_code IS NULL AND prodgrp_code IS NULL ", 
				"AND maingrp_code ='",p_type_code,"'" 
		END CASE 

		LET l_query_text ="SELECT * FROM statsale ", 
		"WHERE cmpy_code='",p_cmpy_code,"' ", 
		"AND cust_code='",p_cust_code,"' ", 
		"AND year_num = ? ", 
		"AND type_code = ? ", 
		"AND int_num = ? ", 
		"AND ",l_where_text clipped 
		PREPARE s_statsale FROM l_query_text 
		DECLARE c_statsale cursor FOR s_statsale 

		LET l_cust_text = l_cust_text clipped,"........" 
		LET l_prompt_text = l_prompt_text clipped,"........" 
		LET l_rec_product.part_code = p_type_code 
		IF p_year_num IS NOT NULL THEN 
			LET l_rec_statparms.year_num = p_year_num 
		END IF 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		WHILE TRUE 

			CLEAR FORM 
			MESSAGE kandoomsg2("E",1002,"")
			 
			DISPLAY l_cust_text TO cust_text 
			DISPLAY l_prompt_text TO prompt_text 
			DISPLAY l_rec_customer.cust_code TO cust_code 
			DISPLAY l_rec_customer.name_text TO name_text  
			DISPLAY l_rec_product.part_code TO part_code 
			DISPLAY l_rec_product.desc_text TO desc_text 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_year_num = l_rec_statparms.year_num 
				LET l_arr_rec_stattotal[i].tot_sales_qty = 0 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_year_num = l_rec_statparms.year_num - 1 
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
			AND year_num = l_rec_statparms.year_num 
			AND type_code = l_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4
			 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsale[l_idx].int_text = l_rec_statint.int_text 

				## obtain current year gross,net AND disc%
				OPEN c_statsale USING l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
				FETCH c_statsale INTO l_rec_cur_statsale.* 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statsale.gross_amt = 0 
					LET l_rec_cur_statsale.net_amt = 0 
					LET l_rec_cur_statsale.sales_qty = 0 
				END IF 

				LET l_arr_rec_statsale[l_idx].year_num = l_rec_statparms.year_num 
				LET l_arr_rec_statsale[l_idx].sales_qty = l_rec_cur_statsale.sales_qty 
				LET l_arr_rec_statsale[l_idx].grs_amt = l_rec_cur_statsale.gross_amt 
				LET l_arr_rec_statsale[l_idx].net_amt = l_rec_cur_statsale.net_amt 
				IF l_arr_rec_statsale[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].disc_per = 100 * 
					(1-(l_arr_rec_statsale[l_idx].net_amt/l_arr_rec_statsale[l_idx].grs_amt)) 
				END IF 

				## obtain previous year gross,net AND disc%
				LET i = l_rec_statparms.year_num-1 
				OPEN c_statsale USING i,l_rec_statint.type_code,l_rec_statint.int_num 
				FETCH c_statsale INTO l_rec_prv_statsale.* 

				IF status = NOTFOUND THEN 
					LET l_rec_prv_statsale.gross_amt = 0 
					LET l_rec_prv_statsale.net_amt = 0 
					LET l_rec_prv_statsale.sales_qty = 0 
				END IF 

				LET l_arr_rec_statsale[l_idx].prv_year_num = l_rec_statparms.year_num - 1 
				LET l_arr_rec_statsale[l_idx].prv_sales_qty = l_rec_prv_statsale.sales_qty 
				LET l_arr_rec_statsale[l_idx].prv_grs_amt = l_rec_prv_statsale.gross_amt 
				LET l_arr_rec_statsale[l_idx].prv_net_amt = l_rec_prv_statsale.net_amt 

				IF l_rec_prv_statsale.gross_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 100 
					*(1-(l_arr_rec_statsale[l_idx].prv_net_amt/l_rec_prv_statsale.gross_amt)) 
				END IF 

				IF l_rec_prv_statsale.net_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].var_net_per = 100 
					* (l_arr_rec_statsale[l_idx].net_amt 
					-l_arr_rec_statsale[l_idx].prv_net_amt) 
					/ l_arr_rec_statsale[l_idx].prv_net_amt 
				END IF 

				## increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statsale.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statsale.net_amt 
				LET l_arr_rec_stattotal[1].tot_prv_grs_amt = l_arr_rec_stattotal[1].tot_prv_grs_amt + l_rec_prv_statsale.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statsale.net_amt 
				IF l_rec_statint.int_num <= l_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statsale.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statsale.net_amt 
					LET l_arr_rec_stattotal[2].tot_prv_grs_amt = l_arr_rec_stattotal[2].tot_prv_grs_amt + l_rec_prv_statsale.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statsale.net_amt 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
				
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt 	/l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_stattotal[i].tot_prv_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt /l_arr_rec_stattotal[i].tot_prv_grs_amt)) 
					END IF 
					
					# calc total net variance
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 100 * ( l_arr_rec_stattotal[i].tot_net_amt - l_arr_rec_stattotal[i].tot_prv_net_amt) / l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1080,"") 
				INPUT ARRAY l_arr_rec_statsale WITHOUT DEFAULTS FROM sr_statsale.* 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","EA4a","input-arr-l_arr_rec_statsale-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
						EXIT INPUT 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
						EXIT INPUT 
				END INPUT
				 
			END IF 
			IF fgl_lastkey() = fgl_keyval("F9") 
			OR fgl_lastkey() = fgl_keyval("F10") THEN 
				FOR i = 1 TO arr_count() 
					INITIALIZE l_arr_rec_statsale[i].* TO NULL 
				END FOR 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
	END IF 
	
	#CLOSE WINDOW E219
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION cust_prodturn(p_cmpy_code,p_cust_code,p_type_code,p_type_ind,p_year_num)
###########################################################################