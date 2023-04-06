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
# FUNCTION sper_wk_offer(p_cmpy_code,p_sale_code,p_offer_code,p_year_num) 
#
# EC7b - allows users TO peruse weekly special offer information
#        FROM statistics tables.
###########################################################################
FUNCTION sper_wk_offer(p_cmpy_code,p_sale_code,p_offer_code,p_year_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_offer_code LIKE statoffer.offer_code 
	DEFINE p_year_num LIKE statparms.year_num 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_offersale RECORD LIKE offersale.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_arr_rec_statoffer DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		start_date LIKE statint.start_date, 
		grs_amt LIKE statoffer.gross_amt, 
		net_amt LIKE statoffer.net_amt, 
		disc_per FLOAT, 
		cust_num INTEGER, 
		sales_qty LIKE statoffer.sales_qty 
	END RECORD 
	DEFINE l_rec_stattotal RECORD 
		tot_grs_amt LIKE statoffer.gross_amt, 
		tot_net_amt LIKE statoffer.net_amt, 
		tot_disc_per FLOAT, 
		tot_sales_qty LIKE statoffer.sales_qty 
	END RECORD 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 

	IF p_year_num IS NOT NULL THEN 
		LET glob_rec_statparms.year_num = p_year_num 
	END IF 

	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*		 

	SELECT * INTO l_rec_offersale.* 
	FROM offersale 
	WHERE cmpy_code = p_cmpy_code 
	AND offer_code = p_offer_code 
	
	OPEN WINDOW E187 with FORM "E187" 
	 CALL windecoration_e("E187")  

	LET l_query_text = 
		"SELECT sum(gross_amt),", 
		"sum(net_amt),", 
		"sum(sales_qty),", 
		"count(*) ", 
		"FROM statoffer ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND sale_code = '",p_sale_code,"' ", 
		"AND offer_code = '",p_offer_code,"' ", 
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
		DISPLAY BY NAME 
			l_rec_salesperson.sale_code, 
			l_rec_salesperson.name_text, 
			l_rec_offersale.offer_code, 
			l_rec_offersale.desc_text, 
			l_rec_offersale.start_date, 
			l_rec_offersale.end_date, 
			glob_rec_statparms.year_num 

		DECLARE c_statint cursor FOR 
		SELECT * FROM statint 
		WHERE cmpy_code = p_cmpy_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.week_type_code 
		AND start_date <= l_rec_offersale.end_date 
		AND end_date >= l_rec_offersale.start_date 
		ORDER BY 1,2,3,4 

		LET l_idx = 0 
		LET l_rec_stattotal.tot_grs_amt = 0 
		LET l_rec_stattotal.tot_net_amt = 0 
		LET l_rec_stattotal.tot_sales_qty = 0
		 
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statoffer[l_idx].int_text = l_rec_statint.int_text 
			LET l_arr_rec_statoffer[l_idx].start_date = l_rec_statint.start_date 

			OPEN c_statoffer USING 
				l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
			FETCH c_statoffer INTO 
				l_arr_rec_statoffer[l_idx].grs_amt, 
				l_arr_rec_statoffer[l_idx].net_amt, 
				l_arr_rec_statoffer[l_idx].sales_qty, 
				l_arr_rec_statoffer[l_idx].cust_num 
			IF status = NOTFOUND THEN 
				LET l_arr_rec_statoffer[l_idx].grs_amt = 0 
				LET l_arr_rec_statoffer[l_idx].net_amt = 0 
				LET l_arr_rec_statoffer[l_idx].sales_qty = 0 
				LET l_arr_rec_statoffer[l_idx].cust_num = 0 
			END IF 

			CLOSE c_statoffer 

			IF l_arr_rec_statoffer[l_idx].grs_amt = 0 THEN 
				LET l_arr_rec_statoffer[l_idx].disc_per = 0 
			ELSE 
				LET l_arr_rec_statoffer[l_idx].disc_per = 100 * 
				(1-(l_arr_rec_statoffer[l_idx].net_amt/l_arr_rec_statoffer[l_idx].grs_amt)) 
			END IF 

			## increment totals
			LET l_rec_stattotal.tot_grs_amt = l_rec_stattotal.tot_grs_amt	+ l_arr_rec_statoffer[l_idx].grs_amt 
			LET l_rec_stattotal.tot_net_amt = l_rec_stattotal.tot_net_amt	+ l_arr_rec_statoffer[l_idx].net_amt 
			LET l_rec_stattotal.tot_sales_qty = l_rec_stattotal.tot_sales_qty	+ l_arr_rec_statoffer[l_idx].sales_qty 
		END FOREACH 

		IF l_idx = 0 THEN 
			ERROR kandoomsg2("E",7088,glob_rec_statparms.year_num) #7088 No Weekly intervals exists FOR this selection "
		ELSE 

			# calc total current & previous year disc%
			IF l_rec_stattotal.tot_grs_amt = 0 THEN 
				LET l_rec_stattotal.tot_disc_per = 0 
			ELSE 
				LET l_rec_stattotal.tot_disc_per = 100 * (1-(l_rec_stattotal.tot_net_amt/l_rec_stattotal.tot_grs_amt)) 
			END IF 
			DISPLAY l_rec_stattotal.* TO sr_stattotal.* 

		END IF 
		
		MESSAGE kandoomsg2("E",1131,"") 	#1131 Week Spec Offer Results - F9 Previous - F10 Next
		DISPLAY ARRAY l_arr_rec_statoffer TO sr_statoffer.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","EC7b","input-arr-l_arr_rec_statoffer-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

			BEFORE ROW 
				LET l_idx = arr_curr() 

			ON ACTION "YEAR-1" --ON KEY (f9) 
				IF year(l_rec_offersale.start_date) < glob_rec_statparms.year_num THEN 
					LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
					EXIT DISPLAY 
				ELSE 
					ERROR kandoomsg2("E",7086,"")	#7086 - no statistics"
				END IF 
				
			ON ACTION "YEAR+1" --ON KEY (f10) 
				IF year(l_rec_offersale.end_date) > glob_rec_statparms.year_num THEN 
					LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
					EXIT DISPLAY 
				ELSE 
					ERROR kandoomsg2("E",7086,"")	#7086 - no statistics"
				END IF 

		END DISPLAY
		 
		IF int_flag THEN
			EXIT WHILE 
		END IF
		 
	END WHILE 
	
	CLOSE WINDOW E187
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_wk_offer(p_cmpy_code,p_sale_code,p_offer_code,p_year_num) 
###########################################################################