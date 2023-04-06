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
GLOBALS "../eo/EC3_GLOBALS.4gl" 
###########################################################################
# FUNCTION sper_mthsales(p_cmpy_code,p_sale_code,p_year_num) 
#
# EC2a (Ec3a !!!0 - allows users TO SELECT a salesperson TO which peruse
#                sale information FROM statistics tables.
###########################################################################
FUNCTION sper_mthsales(p_cmpy_code,p_sale_code,p_year_num) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE p_year_num LIKE statparms.year_num 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE glob_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_statsper RECORD LIKE statsper.* 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD  
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
	DEFINE l_arr_totprvgrs_amt array[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE i SMALLINT 
	DEFINE l_idx SMALLINT
	 
	IF p_year_num IS NOT NULL THEN 
		LET glob_rec_statparms.year_num = p_year_num 
	END IF
	
	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,p_sale_code) RETURNING l_rec_salesperson.*		 

	IF l_rec_salesperson.sale_code IS NULL THEN 
		OPEN WINDOW E186 with FORM "E186" 
		 CALL windecoration_e("E186") 
 

		WHILE TRUE #------------------------------------------------------------------- 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY l_rec_salesperson.sale_code TO sale_code 
			DISPLAY l_rec_salesperson.name_text TO name_text 
			DISPLAY glob_rec_statparms.year_num TO year_num 

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
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
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
					LET l_arr_rec_statsper[l_idx].disc_per = 100 * (1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
				END IF
				 
				LET l_arr_rec_statsper[l_idx].orders_num = l_rec_statsper.orders_num 
				LET l_arr_rec_statsper[l_idx].credits_num = l_rec_statsper.credits_num 
				LET l_arr_rec_statsper[l_idx].net_cred_amt = l_rec_statsper.net_cred_amt
				 
				IF l_arr_rec_statsper[l_idx].orders_num - l_arr_rec_statsper[l_idx].credits_num = 0 THEN 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = l_arr_rec_statsper[l_idx].net_amt	/ (l_arr_rec_statsper[l_idx].orders_num - l_arr_rec_statsper[l_idx].credits_num) 
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
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 	* (1-(l_arr_rec_stattotal[i].tot_net_amt /l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = l_arr_rec_stattotal[i].tot_net_amt	/ (l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				ERROR kandoomsg2("E",1125,"") 		#1123 Monthly Sales - RETURN Day Sales - F9 Prev F10 Next
 
				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EC3a","input-arr-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD int_text
						IF l_idx > 0 THEN 
							IF l_arr_rec_statsper[l_idx].int_text IS NOT NULL THEN 
								DECLARE c1_statint cursor FOR 
								SELECT * FROM statint 
								WHERE cmpy_code = p_cmpy_code 
								AND year_num = glob_rec_statparms.year_num 
								AND type_code = glob_rec_statparms.mth_type_code 
								AND int_text = l_arr_rec_statsper[l_idx].int_text 
								OPEN c1_statint 
								FETCH c1_statint INTO l_rec_statint.* 
								IF status = 0 THEN 
									CALL sper_daysales(p_cmpy_code,p_sale_code,l_rec_statint.start_date, l_rec_statint.end_date) 
								END IF 
								CLOSE c1_statint 
							END IF 
						END IF

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
						EXIT DISPLAY 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
						EXIT DISPLAY 

				END DISPLAY 

			END IF
			 
			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statsper.clear()
			ELSE 
				EXIT WHILE 
			END IF  
		END WHILE 
		CLOSE WINDOW E186 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION sper_mthsales(p_cmpy_code,p_sale_code,p_year_num) 
###########################################################################