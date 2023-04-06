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
GLOBALS "../eo/EA3_GLOBALS.4gl"  
GLOBALS "../eo/EA4_GLOBALS.4gl" 
###########################################################################
# FUNCTION EA3_main()
#
# EA3 - allows users TO SELECT a customer TO which peruse
#       product sales information FROM statistics tables.
###########################################################################
FUNCTION EA3_main() 
	DEFER QUIT 
	DEFER INTERRUPT
	
	CALL setModuleId("EA3") -- albo 

	IF get_url_cust_code() IS NOT NULL THEN	
		CALL cust_partsale(glob_rec_kandoouser.cmpy_code,get_url_cust_code()) 
	ELSE 
{	
		SELECT country.* INTO glob_rec_country.* 
		FROM company, 
		country 
		WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND country.country_code = company.country_code
		 
		IF glob_rec_country.post_code_text IS NULL THEN 
			LET glob_rec_country.post_code_text = "Postal code" 
		END IF
		 }
		OPEN WINDOW E216 with FORM "E216" 
		 CALL windecoration_e("E216") 
 
		CALL scan_cust() 
		
		CLOSE WINDOW E216 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTIONM EA3_main()
###########################################################################


###########################################################################
# FUNCTION EA2_customer_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION EA2_customer_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_rec_customer DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		city_text LIKE customer.city_text, 
		post_code LIKE customer.post_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		DISPLAY BY NAME glob_rec_country.post_code_text
		 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			cust_code, 
			name_text, 
			city_text, 
			post_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EA3","construct-cust_code-1") -- albo kd-502 
	
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
		"SELECT * FROM customer ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"AND delete_flag='N' ", 
		"ORDER BY 1,2" 

	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer cursor FOR s_customer 

	LET l_idx = 0 
	FOREACH c_customer INTO l_rec_customer.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_customer[l_idx].cust_code = l_rec_customer.cust_code 
		LET l_arr_rec_customer[l_idx].name_text = l_rec_customer.name_text 

		IF l_rec_customer.city_text IS NOT NULL THEN 
			LET l_arr_rec_customer[l_idx].city_text = l_rec_customer.city_text 
		ELSE 
			LET l_arr_rec_customer[l_idx].city_text = l_rec_customer.addr2_text 
		END IF 

		LET l_arr_rec_customer[l_idx].post_code = l_rec_customer.post_code 

		SELECT unique 1 FROM statsale 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.year_type_code 
		IF status = 0 THEN 
			LET l_arr_rec_customer[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_customer[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

 
	RETURN l_arr_rec_customer
END FUNCTION 
###########################################################################
# END FUNCTION EA2_customer_get_datasource()
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
		cust_code LIKE customer.cust_code, 
		name_text LIKE customer.name_text, 
		city_text LIKE customer.city_text, 
		post_code LIKE customer.post_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 


	CALL EA2_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
--	CALL set_count(l_idx) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("E",1076,"") 
	--INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* 
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EA3","input-arr-l_arr_rec_customer-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL EA2_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer

		ON ACTION "RERESH"
			 CALL windecoration_e("E216")
			CALL l_arr_rec_customer.clear()
			CALL EA2_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
		
		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD cust_code 
			IF l_arr_rec_customer[l_idx].cust_code IS NOT NULL THEN 
				CALL cust_partsale(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code) 
			END IF 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_cust()
###########################################################################


###########################################################################
# FUNCTION cust_partsale(p_cmpy_code,p_cust_code)
#
#
###########################################################################
FUNCTION cust_partsale(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
--	DEFINE l_rec_statparms RECORD LIKE statparms.*  #changed to glob_rec_statparms 
--	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsale RECORD LIKE statsale.* ## CURRENT year 
	DEFINE l_rec_prv_statsale RECORD LIKE statsale.* ## previous year 
	DEFINE l_arr_rec_statsale DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		maingrp_code LIKE statsale.maingrp_code, 
		prodgrp_code LIKE statsale.prodgrp_code, 
		part_code LIKE statsale.part_code, 
		year_num LIKE statint.year_num, 
		sales_qty LIKE statsale.sales_qty, 
		grs_amt LIKE statsale.gross_amt, 
		net_amt LIKE statsale.net_amt, 
		disc_per FLOAT, 
		prv_year_num LIKE statint.year_num, 
		prv_sales_qty LIKE statsale.sales_qty, 
		prv_grs_amt LIKE statsale.gross_amt, 
		prv_net_amt LIKE statsale.net_amt, 
		prv_disc_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_desc DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		desc_text LIKE product.desc_text, 
		first_date DATE 
	END RECORD 
	DEFINE l_prompt_text char(20) 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING
	DEFINE l_idx SMALLINT 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36
	 
	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = p_cust_code
	 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("A",9067,p_cust_code)	#A 9067" Logic Error: Customer NOT found"
		RETURN 
	END IF 
	
	OPEN WINDOW E218 with FORM "E218" 
	 CALL windecoration_e("E218") -- albo kd-755
 
	LET l_prompt_text = kandooword("Customer","1") 
	LET l_prompt_text = l_prompt_text clipped,"........"
	 
	DISPLAY l_prompt_text TO prompt_text
	DISPLAY BY NAME l_rec_customer.cust_code, 
	l_rec_customer.name_text 

	MENU " Inquiry level" 
		BEFORE MENU 
			CALL publish_toolbar("kandoo","EA3","menu-Inquiry_Level-1") -- albo kd-502
 
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null)
			 
		COMMAND "Products"		" Inquire upon product/customer sales figures" 
			MESSAGE kandoomsg2("E",1001,"") 

			CONSTRUCT BY NAME l_where_text ON maingrp_code, 
			prodgrp_code, 
			part_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","EA3","construct-maingrp_code-1") -- albo kd-502 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 

			EXIT MENU 

		COMMAND "PRODUCT GROUP"		" Inquire upon product-group/customer sales figures" 
			MESSAGE kandoomsg2("E",1001,"") 

			CONSTRUCT BY NAME l_where_text ON maingrp_code, 
			prodgrp_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","EA3","construct-maingrp_code-2") -- albo kd-502 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 

			LET l_where_text = l_where_text clipped," AND part_code IS null" 
			EXIT MENU 

		COMMAND "MAIN GROUP" 	" Inquire upon main-product-group/customer sales figures" 
			MESSAGE kandoomsg2("E",1001,"") 

			CONSTRUCT BY NAME l_where_text ON maingrp_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","EA3","construct-maingrp_code-3") -- albo kd-502 
				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 

			LET l_where_text = l_where_text clipped, 
			" AND prodgrp_code IS NULL AND part_code IS null" 
			EXIT MENU 
			
		COMMAND KEY(INTERRUPT,"E")"Exit"	" Exit inquiry" 
			LET quit_flag = TRUE 
			EXIT MENU
			 
	END MENU 

	IF not(int_flag OR quit_flag) THEN 
		LET l_query_text = "SELECT * FROM statsale ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND cust_code = '",p_cust_code,"' ", 
		"AND year_num = ? ", 
		"AND type_code = '",glob_rec_statparms.year_type_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2,3,4,5,6,7,8" 

		PREPARE s_statsale FROM l_query_text 
		DECLARE c_statsale cursor FOR s_statsale 

		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			LET l_idx = 0 

			OPEN c_statsale USING glob_rec_statparms.year_num 

			FOREACH c_statsale INTO l_rec_cur_statsale.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsale[l_idx].maingrp_code = l_rec_cur_statsale.maingrp_code 
				LET l_arr_rec_statsale[l_idx].prodgrp_code = l_rec_cur_statsale.prodgrp_code 
				LET l_arr_rec_statsale[l_idx].part_code = l_rec_cur_statsale.part_code 
				LET l_arr_rec_statsale[l_idx].year_num = glob_rec_statparms.year_num 
				LET l_arr_rec_statsale[l_idx].sales_qty = l_rec_cur_statsale.sales_qty 
				LET l_arr_rec_statsale[l_idx].grs_amt = l_rec_cur_statsale.gross_amt 
				LET l_arr_rec_statsale[l_idx].net_amt = l_rec_cur_statsale.net_amt 

				IF l_arr_rec_statsale[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].disc_per = 100 * 
					(1-(l_arr_rec_statsale[l_idx].net_amt/l_arr_rec_statsale[l_idx].grs_amt)) 
				END IF 

				LET l_where_text = "1=1" 
				CASE 
					WHEN l_rec_cur_statsale.part_code IS NOT NULL 
						LET l_where_text = l_where_text clipped, 
						" AND part_code = '",l_rec_cur_statsale.part_code,"'" 
						SELECT desc_text INTO l_arr_rec_desc[l_idx].desc_text 
						FROM product 
						WHERE cmpy_code = p_cmpy_code 
						AND part_code = l_rec_cur_statsale.part_code 
						
					WHEN l_rec_cur_statsale.prodgrp_code IS NOT NULL 
						LET l_where_text = l_where_text clipped," AND part_code IS NULL ", 
						"AND prodgrp_code='",l_rec_cur_statsale.prodgrp_code,"'" 
						SELECT desc_text INTO l_arr_rec_desc[l_idx].desc_text 
						FROM prodgrp 
						WHERE cmpy_code = p_cmpy_code 
						AND prodgrp_code = l_rec_cur_statsale.prodgrp_code 

					OTHERWISE 
						LET l_where_text = l_where_text clipped," ", 
						"AND part_code IS NULL AND prodgrp_code IS NULL " 
						SELECT desc_text INTO l_arr_rec_desc[l_idx].desc_text 
						FROM maingrp 
						WHERE cmpy_code = p_cmpy_code 
						AND maingrp_code = l_rec_cur_statsale.maingrp_code 
				END CASE 

				LET l_arr_rec_desc[l_idx].first_date = l_rec_cur_statsale.first_date 

				LET l_query_text = 
				"SELECT * FROM statsale ", 
				"WHERE cmpy_code= '",p_cmpy_code,"'", 
				"AND cust_code= '",p_cust_code,"'", 
				"AND year_num = '",(glob_rec_statparms.year_num - 1),"'", 
				"AND type_code= '",glob_rec_statparms.year_type_code,"'", 
				"AND int_num = '",l_rec_cur_statsale.int_num,"'", 
				"AND maingrp_code = '",l_rec_cur_statsale.maingrp_code,"'", 
				"AND ",l_where_text clipped,"" 
				PREPARE s_prv_statsale FROM l_query_text 
				DECLARE c_prv_statsale cursor FOR s_prv_statsale 

				OPEN c_prv_statsale 
				FETCH c_prv_statsale INTO l_rec_prv_statsale.* 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statsale.sales_qty = 0 
					LET l_rec_prv_statsale.gross_amt = 0 
					LET l_rec_prv_statsale.net_amt = 0 
				END IF 
				CLOSE c_prv_statsale 

				LET l_arr_rec_statsale[l_idx].prv_year_num = glob_rec_statparms.year_num - 1 
				LET l_arr_rec_statsale[l_idx].prv_sales_qty = l_rec_prv_statsale.sales_qty 
				LET l_arr_rec_statsale[l_idx].prv_grs_amt = l_rec_prv_statsale.gross_amt 
				LET l_arr_rec_statsale[l_idx].prv_net_amt = l_rec_prv_statsale.net_amt 
				IF l_arr_rec_statsale[l_idx].prv_grs_amt = 0 THEN 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_statsale[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statsale[l_idx].prv_net_amt/l_arr_rec_statsale[l_idx].prv_grs_amt)) 
				END IF 

			END FOREACH 

			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				MESSAGE kandoomsg2("E",1079,"") 

				INPUT ARRAY l_arr_rec_statsale WITHOUT DEFAULTS FROM sr_statsale.* 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","EA3","input-arr-l_arr_rec_statsale-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 
						DISPLAY l_arr_rec_desc[l_idx].* TO sr_desc.* 

					AFTER FIELD scroll_flag 
						LET l_arr_rec_statsale[l_idx].scroll_flag = NULL 
						IF fgl_lastkey() = fgl_keyval("down") 
						AND arr_curr() = arr_count() THEN 
							MESSAGE kandoomsg2("E",9001,"") 
							NEXT FIELD scroll_flag 
						END IF 

					BEFORE FIELD maingrp_code 
						CASE 

							WHEN l_arr_rec_statsale[l_idx].part_code IS NOT NULL 
								CALL cust_prodturn(p_cmpy_code,p_cust_code, 
								l_arr_rec_statsale[l_idx].part_code,"1", 
								glob_rec_statparms.year_num) 

							WHEN l_arr_rec_statsale[l_idx].prodgrp_code IS NOT NULL 
								CALL cust_prodturn(p_cmpy_code,p_cust_code, 
								l_arr_rec_statsale[l_idx].prodgrp_code,"2", 
								glob_rec_statparms.year_num) 

							OTHERWISE 
								CALL cust_prodturn(p_cmpy_code,p_cust_code, 
								l_arr_rec_statsale[l_idx].maingrp_code,"3", 
								glob_rec_statparms.year_num) 
						END CASE 
						NEXT FIELD scroll_flag 


					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
						EXIT INPUT 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
						EXIT INPUT 

				END INPUT 

			END IF 

			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statsale.clear()
			ELSE 
				EXIT WHILE 
			END IF 

			
--			IF fgl_lastkey() = fgl_keyval("F9") 
--			OR fgl_lastkey() = fgl_keyval("F10") THEN 
--				FOR l_idx = 1 TO arr_count() 
--					INITIALIZE l_arr_rec_statsale[l_idx].* TO NULL 
--				END FOR 
--			ELSE 
--				EXIT WHILE 
--			END IF 

		END WHILE 

	END IF
	 
	CLOSE WINDOW E218
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE
	 
END FUNCTION 
###########################################################################
# END FUNCTION cust_partsale(p_cmpy_code,p_cust_code)
###########################################################################