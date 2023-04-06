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
GLOBALS "../eo/EA2_GLOBALS.4gl" 
###########################################################################
# FUNCTION EA2_main() 
#
# EA2 - allows users TO SELECT a customer TO which peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION EA2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EA2") -- albo 
	
	IF get_url_cust_code() IS NOT NULL THEN
		CALL cust_turnover(glob_rec_kandoouser.cmpy_code,get_url_cust_code()) 
	ELSE 
{
		SELECT country.* INTO glob_rec_country.* 
		FROM company, 
		country 
		WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND country.country_code = company.country_code 
		IF status = NOTFOUND THEN 
			LET glob_rec_country.post_code_text = "Postal code" 
		END IF 
}
		OPEN WINDOW E216 with FORM "E216" 
		 CALL windecoration_e("E216") -- albo kd-755 

		CALL scan_cust() 
		
		CLOSE WINDOW E216 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EA2_main() 
###########################################################################

###########################################################################
# FUNCTION EA2_customer_get_datasource()
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
		CONSTRUCT BY NAME l_where_text ON cust_code, 
		name_text, 
		city_text, 
		post_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EA2","construct-cust_code-1") -- albo kd-502 
	
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

	MESSAGE kandoomsg2("E",1075,"") 

	--INPUT ARRAY l_arr_rec_customer WITHOUT DEFAULTS FROM sr_customer.* 
	DISPLAY ARRAY l_arr_rec_customer TO sr_customer.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EA2","input-l_arr_rec_customer-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_customer.clear()
			CALL EA2_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer		

		ON ACTION "REFRESH"
			 CALL windecoration_e("E216") -- albo kd-755 		
			CALL l_arr_rec_customer.clear()
			CALL EA2_customer_get_datasource(FALSE) RETURNING l_arr_rec_customer		

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD cust_code 
			CALL cust_turnover(glob_rec_kandoouser.cmpy_code,l_arr_rec_customer[l_idx].cust_code) 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_cust()
###########################################################################


###########################################################################
# FUNCTION cust_turnover(p_cmpy_code,p_cust_code)
#
# 
###########################################################################
FUNCTION cust_turnover(p_cmpy_code,p_cust_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statcust RECORD LIKE statcust.* ## CURRENT year 
	DEFINE l_rec_prv_statcust RECORD LIKE statcust.* ## previous year 
	DEFINE l_arr_rec_statcust DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		gross_amt LIKE statcust.gross_amt, 
		net_amt LIKE statcust.net_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statcust.net_amt, 
		prv_disc_per FLOAT, 
		var_grs_per LIKE statcust.gross_amt, 
		var_net_per LIKE statcust.net_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_grs_amt LIKE statcust.gross_amt, 
		tot_net_amt LIKE statcust.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statcust.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_grs_per LIKE statcust.gross_amt, 
		tot_var_net_per LIKE statcust.net_amt 
	END RECORD 
	DEFINE l_arr_rec_totprvgrs_amt array[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_customer.* 
	FROM customer 
	WHERE cmpy_code = p_cmpy_code 
	AND cust_code = p_cust_code 
	IF status = 0 THEN 
		OPEN WINDOW E217 with FORM "E217" 
		 CALL windecoration_e("E217") -- albo kd-755
 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY BY NAME l_rec_customer.cust_code, 
			l_rec_customer.name_text 

			LET i = l_rec_statparms.year_num - 1 
			DISPLAY l_rec_statparms.year_num, 
			i 
			TO sr_year[1].year_num, 
			sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = l_rec_statparms.year_num 
			AND type_code = l_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
				LET l_arr_rec_totprvgrs_amt[i] = 0 
			END FOR 

			LET l_idx = 0 

			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statcust[l_idx].int_text = l_rec_statint.int_text 

				## obtain current year gross,net AND disc%
				SELECT * INTO l_rec_cur_statcust.* 
				FROM statcust 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = p_cust_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statcust.gross_amt = 0 
					LET l_rec_cur_statcust.net_amt = 0 
				END IF 
				LET l_arr_rec_statcust[l_idx].gross_amt = l_rec_cur_statcust.gross_amt 
				LET l_arr_rec_statcust[l_idx].net_amt = l_rec_cur_statcust.net_amt 
				IF l_arr_rec_statcust[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].disc_per = 100 * 
					(1-(l_arr_rec_statcust[l_idx].net_amt/l_arr_rec_statcust[l_idx].gross_amt)) 
				END IF 

				## obtain previous year gross,net AND disc%
				SELECT * INTO l_rec_prv_statcust.* 
				FROM statcust 
				WHERE cmpy_code = p_cmpy_code 
				AND cust_code = p_cust_code 
				AND year_num = l_rec_statparms.year_num - 1 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statcust.gross_amt = 0 
					LET l_rec_prv_statcust.net_amt = 0 
				END IF 
				LET l_arr_rec_statcust[l_idx].prv_net_amt = l_rec_prv_statcust.net_amt 
				IF l_rec_prv_statcust.gross_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].prv_disc_per = 0 
					LET l_arr_rec_statcust[l_idx].var_grs_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statcust[l_idx].prv_net_amt/l_rec_prv_statcust.gross_amt)) 
					LET l_arr_rec_statcust[l_idx].var_grs_per = 100 *(l_arr_rec_statcust[l_idx].gross_amt-l_rec_prv_statcust.gross_amt)	/ l_rec_prv_statcust.gross_amt 
				END IF 
				IF l_rec_prv_statcust.net_amt = 0 THEN 
					LET l_arr_rec_statcust[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statcust[l_idx].var_net_per = 100	* (l_arr_rec_statcust[l_idx].net_amt 
					- l_arr_rec_statcust[l_idx].prv_net_amt)	/ l_arr_rec_statcust[l_idx].prv_net_amt 
				END IF
				 
				## increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt 
				+ l_rec_cur_statcust.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt 
				+ l_rec_cur_statcust.net_amt 
				LET l_arr_rec_totprvgrs_amt[1] = l_arr_rec_totprvgrs_amt[1] + l_rec_prv_statcust.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statcust.net_amt 
				IF l_rec_statint.int_num <= l_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt 	+ l_rec_cur_statcust.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt 	+ l_rec_cur_statcust.net_amt 
					LET l_arr_rec_totprvgrs_amt[2] = l_arr_rec_totprvgrs_amt[2] + l_rec_prv_statcust.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = 	l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statcust.net_amt 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")		#7086 No statistical information exists FOR this selection "
				SLEEP 2
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 

					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_net_amt 
						/l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_rec_totprvgrs_amt[i])) 
					END IF 

					# calc total current & previous year net & gross variance
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 
						100 * ( l_arr_rec_stattotal[i].tot_net_amt 
						- l_arr_rec_stattotal[i].tot_prv_net_amt) 
						/ l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					IF l_arr_rec_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 
						100 * (l_arr_rec_stattotal[i].tot_grs_amt-l_arr_rec_totprvgrs_amt[i])				/ l_arr_rec_totprvgrs_amt[i] 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				MESSAGE kandoomsg2("E",1074,"") 

--				CALL set_count(l_idx) 
				--INPUT ARRAY l_arr_rec_statcust WITHOUT DEFAULTS FROM sr_statcust.* 
				DISPLAY ARRAY l_arr_rec_statcust TO sr_statcust.*
					BEFORE DISPLAY
						CALL publish_toolbar("kandoo","EA2","input-l_arr_rec_statcust-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
						EXIT DISPLAY 
						
					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
						EXIT DISPLAY
						 
				END DISPLAY 

			END IF 

			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statcust.clear()
			ELSE 
				EXIT WHILE 
			END IF  
		END WHILE 

		CLOSE WINDOW E217 

	END IF 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION cust_turnover(p_cmpy_code,p_cust_code)
###########################################################################