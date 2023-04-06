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
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../eo/E_EO_GLOBALS.4gl"
GLOBALS "../eo/EC_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EC2_GLOBALS.4gl" 
###########################################################################
# FUNCTION sper_daysales(p_cmpy_code,p_sale_code,p_start_date,p_end_date)
#
# EC2a - allows users TO SELECT a salesperson TO which peruse
#        sale information FROM statistics tables.
###########################################################################
FUNCTION sper_daysales(p_cmpy_code,p_sale_code,p_start_date,p_end_date) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_start_date DATE 
	DEFINE p_end_date DATE
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD --array[400] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		disc_per FLOAT, 
		orders_num LIKE statsper.orders_num, 
		credits_num LIKE statsper.credits_num, 
		net_cred_amt LIKE statsper.net_cred_amt, 
		avg_ord_val LIKE statsper.net_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_grs_amt LIKE statsper.grs_amt, 
		tot_net_amt LIKE statsper.net_amt, 
		tot_disc_per FLOAT, 
		tot_orders_num LIKE statsper.orders_num, 
		tot_credits_num LIKE statsper.credits_num, 
		tot_net_cred_amt LIKE statsper.net_cred_amt, 
		tot_avg_ord_val LIKE statsper.net_amt 
	END RECORD 
	DEFINE l_arr_totprvgrs_amt array[2] OF decimal(16,2) # 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	IF p_start_date IS NULL THEN 
		LET p_start_date = mdy(month(today),"1",year(today)) 
		LET p_end_date = p_start_date + 1 units month - 1 units day 
	END IF 

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*	
	IF l_rec_salesperson.sale_code IS NULL THEN
		OPEN WINDOW E185 with FORM "E185" 
		 CALL windecoration_e("E185") 

		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 

			DISPLAY l_rec_salesperson.sale_code TO sale_code 
			DISPLAY l_rec_salesperson.name_text TO name_text 
			DISPLAY p_start_date TO start_date 
			DISPLAY p_end_date TO end_date

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_orders_num = 0 
				LET l_arr_rec_stattotal[i].tot_credits_num = 0 
				LET l_arr_rec_stattotal[i].tot_net_cred_amt = 0 
				LET l_arr_rec_stattotal[i].tot_avg_ord_val = 0 
			END FOR 
			
			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND type_code = glob_rec_statparms.day_type_code 
			AND start_date >= p_start_date 
			AND end_date <= p_end_date 
			ORDER BY 1,2,3,4 

			LET l_idx = 0 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsper[l_idx].int_text = l_rec_statint.int_text 
				SELECT 
					sum(grs_amt), 
					sum(net_amt), 
					sum(orders_num), 
					sum(credits_num), 
					sum(net_cred_amt) 
				INTO 
					l_rec_statsper.grs_amt, 
					l_rec_statsper.net_amt, 
					l_rec_statsper.orders_num, 
					l_rec_statsper.credits_num, 
					l_rec_statsper.net_cred_amt 
				FROM statsper 
				WHERE cmpy_code = p_cmpy_code 
				AND sale_code = p_sale_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 

				IF status = NOTFOUND THEN 
					LET l_rec_statsper.grs_amt = 0 
					LET l_rec_statsper.net_amt = 0 
					LET l_rec_statsper.orders_num = 0 
					LET l_rec_statsper.credits_num = 0 
					LET l_rec_statsper.net_cred_amt = 0 
				END IF 

				LET l_arr_rec_statsper[l_idx].grs_amt = l_rec_statsper.grs_amt 
				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_statsper.net_amt 
				
				IF l_arr_rec_statsper[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 
						100 * (1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
				END IF 
				
				LET l_arr_rec_statsper[l_idx].orders_num = l_rec_statsper.orders_num 
				LET l_arr_rec_statsper[l_idx].credits_num = l_rec_statsper.credits_num 
				LET l_arr_rec_statsper[l_idx].net_cred_amt = l_rec_statsper.net_cred_amt
				 
				IF l_arr_rec_statsper[l_idx].orders_num -	l_arr_rec_statsper[l_idx].credits_num = 0 THEN 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = 
						l_arr_rec_statsper[l_idx].net_amt	/ (l_arr_rec_statsper[l_idx].orders_num	- l_arr_rec_statsper[l_idx].credits_num) 
				END IF 

				## increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_statsper.grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_statsper.net_amt 
				LET l_arr_rec_stattotal[1].tot_orders_num = l_arr_rec_stattotal[1].tot_orders_num + l_rec_statsper.orders_num 
				LET l_arr_rec_stattotal[1].tot_credits_num = l_arr_rec_stattotal[1].tot_credits_num + l_rec_statsper.credits_num 
				LET l_arr_rec_stattotal[1].tot_net_cred_amt = l_arr_rec_stattotal[1].tot_net_cred_amt + l_rec_statsper.net_cred_amt 
				
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_statsper.grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_statsper.net_amt 
					LET l_arr_rec_stattotal[2].tot_orders_num = l_arr_rec_stattotal[2].tot_orders_num + l_rec_statsper.orders_num 
					LET l_arr_rec_stattotal[2].tot_credits_num = l_arr_rec_stattotal[2].tot_credits_num + l_rec_statsper.credits_num 
					LET l_arr_rec_stattotal[2].tot_net_cred_amt = l_arr_rec_stattotal[2].tot_net_cred_amt + l_rec_statsper.net_cred_amt 
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
						LET l_arr_rec_stattotal[i].tot_disc_per = 
							100 * (1-(l_arr_rec_stattotal[i].tot_net_amt / l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 

					IF l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 
							l_arr_rec_stattotal[i].tot_net_amt / (l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR
				 
				MESSAGE kandoomsg2("E",1118,"")	#1118 Salesperson Commission - F9 Previous Year - F10 Next Year

				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EC2a","input-arr-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "BY DATES" #KEY (f8) 
					CALL enter_dates(p_start_date,p_end_date) RETURNING p_start_date,	p_end_date
						EXIT DISPLAY 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
						EXIT DISPLAY 
						
					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
						EXIT DISPLAY 
{						
					ON KEY (f9) 
						LET i = p_end_date - p_start_date 
						LET p_end_date = p_start_date - 1 
						LET p_start_date = p_end_date - i

						EXIT DISPLAY 

					ON KEY (f10) 
						LET i = p_end_date - p_start_date 
						LET p_start_date = p_end_date + 1 
						LET p_end_date = p_start_date + i 

						EXIT DISPLAY
} 
				END DISPLAY 

			END IF 

			CASE fgl_lastaction() 
				WHEN "by dates"  
					CALL enter_dates(p_start_date,p_end_date) 
					RETURNING p_start_date, 
					p_end_date
					 
				WHEN "year-1" 
					LET i = p_end_date - p_start_date 
					LET p_end_date = p_start_date - 1 
					LET p_start_date = p_end_date - i
					 
				WHEN "year+1" 
					LET i = p_end_date - p_start_date 
					LET p_start_date = p_end_date + 1 
					LET p_end_date = p_start_date + i 
				OTHERWISE 
					EXIT WHILE 
			END CASE 
			CALL l_arr_rec_statsper.clear()
		END WHILE 

		CLOSE WINDOW E185 

	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_daysales(p_cmpy_code,p_sale_code,l_start_date,l_end_date)
###########################################################################


###########################################################################
# FUNCTION enter_dates(p_start_date,p_end_date)
#
#
###########################################################################
FUNCTION enter_dates(p_start_date,p_end_date) 
	DEFINE p_start_date DATE 
	DEFINE p_end_date DATE
	DEFINE l_start_date DATE 
	DEFINE l_end_date DATE	
	
	LET l_start_date = p_start_date 
	LET l_end_date = p_end_date
	 
	MESSAGE kandoomsg2("E",1001,"")	#10  Enter date range of inquiry
	INPUT l_start_date, l_end_date WITHOUT DEFAULTS
	FROM start_date, end_date ATTRIBUTE(UNBUFFERED) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EC2a","input-l_start_date-1")

		ON ACTION "WEB-HELP"
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD start_date 
			IF l_start_date IS NULL THEN 
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD end_date 
			IF l_end_date IS NULL THEN 
				NEXT FIELD end_date 
			END IF 
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN p_start_date,p_end_date 
	ELSE 
		RETURN l_start_date,l_end_date 
	END IF 
END FUNCTION
###########################################################################
# END FUNCTION enter_dates(p_start_date,p_end_date)
###########################################################################