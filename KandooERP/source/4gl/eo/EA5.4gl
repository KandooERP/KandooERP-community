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
GLOBALS "../eo/EA5_GLOBALS.4gl" 
###########################################################################
# FUNCTION EA5_main()
#
# EA5 - allows users TO SELECT a customer TO which peruse
#       turnover & profit information FROM statistics tables.
###########################################################################
FUNCTION EA5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EA5") -- albo 

	SELECT country.* INTO glob_rec_country.* 
	FROM company, 
	country 
	WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND country.country_code = company.country_code
	 
	IF status = NOTFOUND THEN 
		LET glob_rec_country.post_code_text = "Postal code" 
	END IF 

	IF get_url_cust_code() IS NOT NULL THEN		
		CALL cust_profit(glob_rec_kandoouser.cmpy_code,get_url_cust_code()) 
	ELSE 
	
		OPEN WINDOW E216 with FORM "E216" 
		 CALL windecoration_e("E216") -- albo kd-755 

		CALL scan_cust() 

		CLOSE WINDOW E216 
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION EA5_main()
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
				CALL publish_toolbar("kandoo","EA5","construct-cust_code-1") 
	
			ON ACTION "WEB-HELP" 
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
		 
		SELECT unique 1 FROM statcust 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.mth_type_code 
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
# END FUNCTION EA4_customer_get_datasource(p_filter)
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

	CALL EA4_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
	 
	MESSAGE kandoomsg2("E",1077,"") 
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EA5","input-arr-l_arr_rec_customer-1") -- albo kd-502 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_customer.getSize())
 			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL EA4_customer_get_datasource(TRUE) RETURNING l_arr_rec_customer
	
		ON ACTION "REFRESH"
			 CALL windecoration_e("E216")
			CALL l_arr_rec_customer.clear()
			CALL EA4_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer
	
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD cust_code 
			CALL cust_profit(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code) 
			--NEXT FIELD scroll_flag 

		BEFORE ROW 
			LET l_idx = arr_curr() 


	END DISPLAY

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# FUNCTION scan_cust()
#
#
###########################################################################

FUNCTION cust_profit_get_datasource(p_cmpy_code,p_cust_code)
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	--DEFINE l_rec_statparms RECORD LIKE statparms.* replaced by glob_rec_statparms
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statcust RECORD LIKE statcust.* ## CURRENT year 
	DEFINE l_rec_prv_statcust RECORD LIKE statcust.* ## previous year 
	DEFINE l_arr_rec_statcust DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		net_amt LIKE statcust.net_amt, 
		prof_amt LIKE statcust.gross_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statcust.net_amt, 
		prv_prof_amt LIKE statcust.gross_amt, 
		prv_disc_per FLOAT, 
		var_prof_per LIKE statcust.gross_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal ARRAY[2] OF RECORD 
		tot_net_amt LIKE statcust.net_amt, 
		tot_prof_amt LIKE statcust.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statcust.net_amt, 
		tot_prv_prof_amt LIKE statcust.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_prof_per LIKE statcust.gross_amt 
	END RECORD 
	DEFINE l_arr_rec_totprvgrs_amt ARRAY[2] OF decimal(16,2)# previous year gross amt 
	DEFINE l_arr_rec_totcurgrs_amt ARRAY[2] OF decimal(16,2)# CURRENT "" "" "" 
	# 1->Total    2->YTD
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
--	OPTIONS INSERT KEY f36, 
--	DELETE KEY f36 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = p_cust_code 

	IF status = 0 THEN 

		MESSAGE kandoomsg2("E",1002,"") 
		CLEAR FORM 
		
		DISPLAY BY NAME 
			l_rec_customer.cust_code, 
			l_rec_customer.name_text 

		LET i = glob_rec_statparms.year_num - 1 
		DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
		DISPLAY i TO sr_year[2].year_num 

		DECLARE c_statint cursor FOR 
		SELECT * FROM statint 
		WHERE cmpy_code = p_cmpy_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.mth_type_code 
		ORDER BY 1,2,3,4 
		
		FOR i = 1 TO 2 
			LET l_arr_rec_stattotal[i].tot_net_amt = 0 
			LET l_arr_rec_stattotal[i].tot_prof_amt = 0 
			LET l_arr_rec_stattotal[i].tot_disc_per = 0 
			LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
			LET l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 
			LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
			LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
			LET l_arr_rec_totcurgrs_amt[i] = 0 
			LET l_arr_rec_totprvgrs_amt[i] = 0 
		END FOR 
		
		LET l_idx = 0 
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statcust[l_idx].int_text = l_rec_statint.int_text 

			# obtain current year gross,net AND disc%
			SELECT * 
			INTO l_rec_cur_statcust.* 
			FROM statcust 
			WHERE cmpy_code = p_cmpy_code 
			AND cust_code = p_cust_code 
			AND year_num = l_rec_statint.year_num 
			AND type_code = l_rec_statint.type_code 
			AND int_num = l_rec_statint.int_num 
			IF status = NOTFOUND THEN 
				LET l_rec_cur_statcust.gross_amt = 0 
				LET l_rec_cur_statcust.net_amt = 0 
				LET l_rec_cur_statcust.cost_amt = 0 
			END IF 

			LET l_arr_rec_statcust[l_idx].net_amt = l_rec_cur_statcust.net_amt 
			LET l_arr_rec_statcust[l_idx].prof_amt = l_rec_cur_statcust.net_amt	- l_rec_cur_statcust.cost_amt 

			IF l_rec_cur_statcust.gross_amt = 0 THEN 
				LET l_arr_rec_statcust[l_idx].disc_per = 0 
			ELSE 
				LET l_arr_rec_statcust[l_idx].disc_per = 100 * (1-(l_rec_cur_statcust.net_amt/l_rec_cur_statcust.gross_amt)) 
			END IF 

			# obtain previous year gross,net AND disc%
			SELECT * INTO l_rec_prv_statcust.* 
			FROM statcust 
			WHERE cmpy_code = p_cmpy_code 
			AND cust_code = p_cust_code 
			AND year_num = glob_rec_statparms.year_num - 1 
			AND type_code = l_rec_statint.type_code 
			AND int_num = l_rec_statint.int_num 
			IF status = NOTFOUND THEN 
				LET l_rec_prv_statcust.gross_amt = 0 
				LET l_rec_prv_statcust.net_amt = 0 
				LET l_rec_prv_statcust.cost_amt = 0 
			END IF 
			
			LET l_arr_rec_statcust[l_idx].prv_net_amt = l_rec_prv_statcust.net_amt 
			LET l_arr_rec_statcust[l_idx].prv_prof_amt = l_rec_prv_statcust.net_amt	- l_rec_prv_statcust.cost_amt 

			IF l_rec_prv_statcust.gross_amt = 0 THEN 
				LET l_arr_rec_statcust[l_idx].prv_disc_per = 0 
			ELSE 
				LET l_arr_rec_statcust[l_idx].prv_disc_per = 100 *(1-(l_rec_prv_statcust.net_amt/l_rec_prv_statcust.gross_amt)) 
			END IF 

			IF l_arr_rec_statcust[l_idx].prv_prof_amt = 0 THEN 
				LET l_arr_rec_statcust[l_idx].var_prof_per = 0 
			ELSE 
				LET l_arr_rec_statcust[l_idx].var_prof_per = 
					100 *
					(l_arr_rec_statcust[l_idx].prof_amt-l_arr_rec_statcust[l_idx].prv_prof_amt) 
					/ l_arr_rec_statcust[l_idx].prv_prof_amt 
			END IF 

			#### increment totals (AND YTD IF current OR less month)
			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_net_amt = l_arr_rec_stattotal[i].tot_net_amt 	+ l_rec_cur_statcust.net_amt 
				LET l_arr_rec_stattotal[i].tot_prof_amt = l_arr_rec_stattotal[i].tot_prof_amt + l_arr_rec_statcust[l_idx].prof_amt 
				LET l_arr_rec_totcurgrs_amt[i] = l_arr_rec_totcurgrs_amt[i] + l_rec_cur_statcust.gross_amt 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = l_arr_rec_stattotal[i].tot_prv_net_amt + l_rec_prv_statcust.net_amt 
				LET l_arr_rec_stattotal[i].tot_prv_prof_amt = l_arr_rec_stattotal[i].tot_prv_prof_amt + l_arr_rec_statcust[l_idx].prv_prof_amt 
				LET l_arr_rec_totprvgrs_amt[i] = l_arr_rec_totprvgrs_amt[i] + l_rec_prv_statcust.gross_amt 

				IF l_rec_statint.int_num > glob_rec_statparms.mth_num THEN 
					EXIT FOR 
				END IF 
			END FOR 

		END FOREACH 
		
		IF l_idx = 0 THEN 
			ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
			CALL l_arr_rec_statcust.clear()

		ELSE 

			FOR i = 1 TO 2 
				# calc total current & previous year disc%
				IF l_arr_rec_totcurgrs_amt[i] = 0 THEN 
					LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[i].tot_disc_per = 100	* (1-(l_arr_rec_stattotal[i].tot_net_amt/l_arr_rec_totcurgrs_amt[i])) 
				END IF 
				IF l_arr_rec_totprvgrs_amt[i] = 0 THEN 
					LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100	* (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_rec_totprvgrs_amt[i])) 
				END IF 

				# calc profit variance
				IF l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 THEN 
					LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[i].tot_var_prof_per = 
						100 * ( l_arr_rec_stattotal[i].tot_prof_amt 
						- l_arr_rec_stattotal[i].tot_prv_prof_amt) 
						/ l_arr_rec_stattotal[i].tot_prv_prof_amt 
				END IF 
				DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

			END FOR 
		END IF
	END IF
	
	RETURN l_arr_rec_statcust
END FUNCTION

###########################################################################
# FUNCTION cust_profit(p_cmpy_code,p_cust_code) 
#
#
###########################################################################
FUNCTION cust_profit(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	--DEFINE l_rec_statparms RECORD LIKE statparms.* replaced by glob_rec_statparms
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statcust RECORD LIKE statcust.* ## CURRENT year 
	DEFINE l_rec_prv_statcust RECORD LIKE statcust.* ## previous year 
	DEFINE l_arr_rec_statcust DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		net_amt LIKE statcust.net_amt, 
		prof_amt LIKE statcust.gross_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statcust.net_amt, 
		prv_prof_amt LIKE statcust.gross_amt, 
		prv_disc_per FLOAT, 
		var_prof_per LIKE statcust.gross_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal ARRAY[2] OF RECORD 
		tot_net_amt LIKE statcust.net_amt, 
		tot_prof_amt LIKE statcust.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statcust.net_amt, 
		tot_prv_prof_amt LIKE statcust.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_prof_per LIKE statcust.gross_amt 
	END RECORD 
	DEFINE l_arr_rec_totprvgrs_amt ARRAY[2] OF decimal(16,2)# previous year gross amt 
	DEFINE l_arr_rec_totcurgrs_amt ARRAY[2] OF decimal(16,2)# CURRENT "" "" "" 
	# 1->Total    2->YTD
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
{	
--	OPTIONS INSERT KEY f36, 
--	DELETE KEY f36 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = p_cust_code 
	IF status = 0 THEN 
	
		OPEN WINDOW E221 with FORM "E221" 
		 CALL windecoration_e("E221") -- albo kd-755 

		WHILE TRUE #------ WHILE BEGIN -----------------------------------------
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			
			DISPLAY BY NAME 
				l_rec_customer.cust_code, 
				l_rec_customer.name_text 

			LET i = glob_rec_statparms.year_num - 1 
			DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY i TO sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 
			
			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prof_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
				LET l_arr_rec_totcurgrs_amt[i] = 0 
				LET l_arr_rec_totprvgrs_amt[i] = 0 
			END FOR 
			
			LET l_idx = 0 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statcust[l_idx].int_text = l_rec_statint.int_text 

				# obtain current year gross,net AND disc%
				SELECT * 
				INTO l_rec_cur_statcust.* 
				FROM statcust 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = p_cust_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statcust.gross_amt = 0 
					LET l_rec_cur_statcust.net_amt = 0 
					LET l_rec_cur_statcust.cost_amt = 0 
				END IF 

				LET l_arr_rec_statcust[l_idx].net_amt = l_rec_cur_statcust.net_amt 
				LET l_arr_rec_statcust[l_idx].prof_amt = l_rec_cur_statcust.net_amt	- l_rec_cur_statcust.cost_amt 

				IF l_rec_cur_statcust.gross_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].disc_per = 100 * (1-(l_rec_cur_statcust.net_amt/l_rec_cur_statcust.gross_amt)) 
				END IF 

				# obtain previous year gross,net AND disc%
				SELECT * INTO l_rec_prv_statcust.* 
				FROM statcust 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = p_cust_code 
				AND year_num = glob_rec_statparms.year_num - 1 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statcust.gross_amt = 0 
					LET l_rec_prv_statcust.net_amt = 0 
					LET l_rec_prv_statcust.cost_amt = 0 
				END IF 
				
				LET l_arr_rec_statcust[l_idx].prv_net_amt = l_rec_prv_statcust.net_amt 
				LET l_arr_rec_statcust[l_idx].prv_prof_amt = l_rec_prv_statcust.net_amt	- l_rec_prv_statcust.cost_amt 

				IF l_rec_prv_statcust.gross_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].prv_disc_per = 100 *(1-(l_rec_prv_statcust.net_amt/l_rec_prv_statcust.gross_amt)) 
				END IF 

				IF l_arr_rec_statcust[l_idx].prv_prof_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].var_prof_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].var_prof_per = 
						100 *
						(l_arr_rec_statcust[l_idx].prof_amt-l_arr_rec_statcust[l_idx].prv_prof_amt) 
						/ l_arr_rec_statcust[l_idx].prv_prof_amt 
				END IF 

				#### increment totals (AND YTD IF current OR less month)
				FOR i = 1 TO 2 
					LET l_arr_rec_stattotal[i].tot_net_amt = l_arr_rec_stattotal[i].tot_net_amt 	+ l_rec_cur_statcust.net_amt 
					LET l_arr_rec_stattotal[i].tot_prof_amt = l_arr_rec_stattotal[i].tot_prof_amt + l_arr_rec_statcust[l_idx].prof_amt 
					LET l_arr_rec_totcurgrs_amt[i] = l_arr_rec_totcurgrs_amt[i] + l_rec_cur_statcust.gross_amt 
					LET l_arr_rec_stattotal[i].tot_prv_net_amt = l_arr_rec_stattotal[i].tot_prv_net_amt + l_rec_prv_statcust.net_amt 
					LET l_arr_rec_stattotal[i].tot_prv_prof_amt = l_arr_rec_stattotal[i].tot_prv_prof_amt + l_arr_rec_statcust[l_idx].prv_prof_amt 
					LET l_arr_rec_totprvgrs_amt[i] = l_arr_rec_totprvgrs_amt[i] + l_rec_prv_statcust.gross_amt 
					IF l_rec_statint.int_num > glob_rec_statparms.mth_num THEN 
						EXIT FOR 
					END IF 
				END FOR 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
				EXIT WHILE 

			ELSE 

				FOR i = 1 TO 2 
					# calc total current & previous year disc%
					IF l_arr_rec_totcurgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100	* (1-(l_arr_rec_stattotal[i].tot_net_amt/l_arr_rec_totcurgrs_amt[i])) 
					END IF 
					IF l_arr_rec_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100	* (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_rec_totprvgrs_amt[i])) 
					END IF 

					# calc profit variance
					IF l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 
						100 * ( l_arr_rec_stattotal[i].tot_prof_amt 
						- l_arr_rec_stattotal[i].tot_prv_prof_amt) 
						/ l_arr_rec_stattotal[i].tot_prv_prof_amt 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
}

	OPEN WINDOW E221 with FORM "E221" 
	 CALL windecoration_e("E221") -- albo kd-755 


	CALL cust_profit_get_datasource(p_cmpy_code,p_cust_code) RETURNING l_arr_rec_statcust 

	MESSAGE kandoomsg2("E",1081,"")			#1081 Customer Profit Figures - F9 Prev - F10 Next
--				CALL set_count(l_idx) 
	DISPLAY ARRAY l_arr_rec_statcust TO sr_statcust.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EA5","input-arr-l_arr_rec_statcust-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "YEAR-1" --ON KEY (f9) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1
			CALL l_arr_rec_statcust.clear()
			CALL cust_profit_get_datasource(p_cmpy_code,p_cust_code) RETURNING l_arr_rec_statcust 
			--EXIT DISPLAY 

		ON ACTION "YEAR+1" --ON KEY (f10) 
			LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1
			CALL l_arr_rec_statcust.clear()
			CALL cust_profit_get_datasource(p_cmpy_code,p_cust_code) RETURNING l_arr_rec_statcust
			 
			--EXIT DISPLAY
			 
	END DISPLAY 

{
			END IF 

			IF (fgl_lastaction() = "YEAR-1") OR (fgl_lastaction() = "YEAR+1") THEN 
			--IF fgl_lastkey() = fgl_keyval("F9") OR fgl_lastkey() = fgl_keyval("F10") THEN 
				FOR i = 1 TO arr_count() 
					INITIALIZE l_arr_rec_statcust[i].* TO NULL 
				END FOR 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE #-------------- END WHILE 
}
	CLOSE WINDOW E221 
 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION cust_profit(p_cmpy_code,p_cust_code) 
###########################################################################