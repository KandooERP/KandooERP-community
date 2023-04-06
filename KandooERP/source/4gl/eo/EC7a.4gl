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
GLOBALS "../eo/EC7_GLOBALS.4gl"
###########################################################################
# FUNCTION sper_yr_offer(p_cmpy_code,p_sale_code) 
#
# EC3a (Ec7a !!!)- allows users TO peruse special offer information
#                  FROM statistics tables.
###########################################################################
FUNCTION sper_yr_offer(p_cmpy_code,p_sale_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	--DEFINE glob_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_rec_statoffer DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		offer_code LIKE statoffer.sale_code, 
		desc_text LIKE offersale.desc_text, 
		gross_amt LIKE statoffer.gross_amt, 
		net_amt LIKE statoffer.net_amt, 
		disc_per FLOAT, 
		cust_num INTEGER, 
		sales_qty LIKE statoffer.sales_qty 
	END RECORD 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT	

	OPEN WINDOW E188 with FORM "E188" 
	 CALL windecoration_e("E188") -- albo kd-755
 
	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*		 

	DISPLAY BY NAME l_rec_salesperson.sale_code 
	DISPLAY BY NAME l_rec_salesperson.name_text 
	DISPLAY BY NAME glob_rec_statparms.year_num 

	MESSAGE kandoomsg2("E",1001,"") 
	CONSTRUCT BY NAME l_where_text ON offer_code, desc_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","EC7a","construct-offer_code-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

	END CONSTRUCT 

	IF not(int_flag OR quit_flag) THEN 
		LET l_query_text =
			"SELECT * FROM offersale ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND end_date >= ? ", 
			"AND start_date <= ? ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 1,2" 
		PREPARE s_offersale FROM l_query_text 
		DECLARE c_offersale cursor FOR s_offersale 
		
		LET l_query_text = 
			"SELECT sum(gross_amt),", 
			"sum(net_amt),", 
			"sum(sales_qty),", 
			"count(*) ", 
			"FROM statoffer ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND sale_code = '",p_sale_code,"' ", 
			"AND offer_code = ? ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			"group by cmpy_code,", 
			"offer_code,", 
			"sale_code,", 
			"year_num,", 
			"type_code,", 
			"int_num" 
		PREPARE s_statoffer FROM l_query_text 
		DECLARE c_statoffer cursor FOR s_statoffer
		 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 	#1002 Searching database - please wait
			CLEAR FORM
			 
			DISPLAY BY NAME l_rec_salesperson.sale_code 
			DISPLAY BY NAME l_rec_salesperson.name_text 
			DISPLAY BY NAME glob_rec_statparms.year_num 

			SELECT * INTO l_rec_statint.* 
			FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.year_type_code 
			AND int_num = 1 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",7087,glob_rec_statparms.year_num) 		#7087 No Year information exists FOR this selection "
				EXIT WHILE 
			END IF 
			
			LET l_idx = 0 
			OPEN c_offersale USING l_rec_statint.start_date,	l_rec_statint.end_date 
			FOREACH c_offersale INTO l_rec_offersale.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statoffer[l_idx].offer_code = l_rec_offersale.offer_code 
				LET l_arr_rec_statoffer[l_idx].desc_text = l_rec_offersale.desc_text
				 
				OPEN c_statoffer USING 
					l_rec_offersale.offer_code, 
					l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
				FETCH c_statoffer INTO 
					l_arr_rec_statoffer[l_idx].gross_amt, 
					l_arr_rec_statoffer[l_idx].net_amt, 
					l_arr_rec_statoffer[l_idx].sales_qty, 
					l_arr_rec_statoffer[l_idx].cust_num 
				IF status = NOTFOUND THEN 
					LET l_arr_rec_statoffer[l_idx].gross_amt = 0 
					LET l_arr_rec_statoffer[l_idx].net_amt = 0 
					LET l_arr_rec_statoffer[l_idx].sales_qty = 0 
					LET l_arr_rec_statoffer[l_idx].cust_num = 0 
				END IF 
				
				IF l_arr_rec_statoffer[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statoffer[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statoffer[l_idx].disc_per = 100 *(1-(l_arr_rec_statoffer[l_idx].net_amt/l_arr_rec_statoffer[l_idx].gross_amt)) 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")	#7086 No statistical information exists FOR this selection "
				SLEEP 2
				LET l_idx = 1 
			END IF 
			
			MESSAGE kandoomsg2("E",1129,"")	#1129 Yearly Special Offer Results - RETURN Weekly
 
			DISPLAY ARRAY l_arr_rec_statoffer TO sr_statsper.* 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","EC7a","input-arr-l_arr_rec_statoffer-1") -- albo kd-502 

				ON ACTION "WEB-HELP" -- albo kd-370 
					CALL onlinehelp(getmoduleid(),null) 

				BEFORE ROW 
					LET l_idx = arr_curr() 

				ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD offer_code 
					IF l_arr_rec_statoffer[l_idx].offer_code IS NOT NULL THEN 
						CALL sper_wk_offer(
							p_cmpy_code,
							l_rec_salesperson.sale_code, 
							l_arr_rec_statoffer[l_idx].offer_code, 
							glob_rec_statparms.year_num) 
					END IF 

				ON ACTION "YEAR-1" --ON KEY (f9) 
					LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
					EXIT DISPLAY
					 
				ON ACTION "YEAR+1" --ON KEY (f10) 
					LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
					EXIT DISPLAY
					 
			END DISPLAY 

			IF int_flag THEN
				EXIT WHILE		 
			END IF 
			
		END WHILE 
	END IF
	 
	CLOSE WINDOW E188
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_yr_offer(p_cmpy_code,p_sale_code) 
###########################################################################