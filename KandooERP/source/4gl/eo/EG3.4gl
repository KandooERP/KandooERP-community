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
GLOBALS "../eo/EG_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EG3_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_temp_state_code LIKE salesperson.state_code 
DEFINE modu_temp_start_date DATE
DEFINE modu_temp_end_date DATE
DEFINE modu_temp_l_where_text char(50) 
###########################################################################
# FUNCTION EG3_main()
#
# EG3 - allows users TO SELECT salesperson types TO peruse
#       company daily sales information FROM statistics tables.
###########################################################################
FUNCTION EG3_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EG3") -- albo 

	OPEN WINDOW E265 with FORM "E265" 
	 CALL windecoration_e("E265") -- albo kd-755
 
	WHILE select_sper_type() 
		CALL company_sales(glob_rec_kandoouser.cmpy_code, 
		modu_temp_l_where_text, 
		modu_temp_state_code, 
		modu_temp_start_date, 
		modu_temp_end_date) 
	END WHILE 
	
	CLOSE WINDOW E265 
END FUNCTION 
###########################################################################
# END FUNCTION EG3_main()
###########################################################################


###########################################################################
# FUNCTION select_sper_type() 
#
#
###########################################################################
FUNCTION select_sper_type() 
--	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_pseudo_flag char(1)
	DEFINE l_primary_flag char(1)
	DEFINE l_normal_flag char(1)
	DEFINE l_state_code LIKE salesperson.state_code
	DEFINE l_start_date DATE
	DEFINE l_end_date DATE	
	DEFINE l_where_text char(100) 

	MESSAGE kandoomsg2("E",1137,"") #1137 Company Daily Sales - F9 TO toggle - ESC TO Continue

--	SELECT * INTO l_rec_company.* FROM company 
--	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	DISPLAY BY NAME 
	glob_rec_company.cmpy_code, 
	glob_rec_company.name_text, 
	glob_rec_company.addr1_text, 
	glob_rec_company.addr2_text, 
	glob_rec_company.city_text, 
	glob_rec_company.state_code, 
	glob_rec_company.post_code 

	LET l_pseudo_flag = "*" 
	LET l_primary_flag = "*" 
	LET l_normal_flag = "*" 
	LET l_start_date = mdy(month(today),"1",year(today)) 
	LET l_end_date = l_start_date + 1 units month - 1 units day 

	INPUT 
		l_pseudo_flag, 
		l_primary_flag, 
		l_normal_flag, 
		l_state_code, 
		l_start_date, 
		l_end_date WITHOUT DEFAULTS 
	FROM
		pseudo_flag, 
		primary_flag, 
		normal_flag, 
		state_code, 
		start_date, 
		end_date ATTRIBUTE(UNBUFFERED) 
	
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EG3","input-l_pseudo_flag-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

{

	#textField got replaced with checkBox

		ON KEY (f9) infield(l_pseudo_flag) 
					IF l_pseudo_flag IS NULL THEN 
						LET l_pseudo_flag = "*" 
					ELSE 
						LET l_pseudo_flag = NULL 
					END IF 
					DISPLAY l_pseudo_flag TO pseudo_flag

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(l_primary_flag) 
					IF l_primary_flag IS NULL THEN 
						LET l_primary_flag = "*" 
					ELSE 
						LET l_primary_flag = NULL 
					END IF 
					DISPLAY l_primary_flag TO primary_flag 

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(l_normal_flag) 
					IF l_normal_flag IS NULL THEN 
						LET l_normal_flag = "*" 
					ELSE 
						LET l_normal_flag = NULL 
					END IF 
					DISPLAY l_normal_flag TO normal_flag

					NEXT FIELD pseudo_flag 
}
 
		AFTER FIELD l_start_date 
			IF l_start_date IS NULL THEN 
				NEXT FIELD start_date 
			END IF 

		AFTER FIELD l_end_date 
			IF l_end_date IS NULL THEN 
				NEXT FIELD end_date 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_primary_flag IS NULL 
				AND l_pseudo_flag IS NULL 
				AND l_normal_flag IS NULL THEN 
					ERROR kandoomsg2("E",1132,"") 	#1132 All Salesperson Types have been excluded "
					NEXT FIELD NEXT 
				END IF 

				IF l_pseudo_flag = "*" THEN 
					LET l_where_text = " '1'" 
				END IF 

				IF l_primary_flag = "*" THEN 
					LET l_where_text = l_where_text clipped,",'2'" 
				END IF 

				IF l_normal_flag = "*" THEN 
					LET l_where_text = l_where_text clipped,",'3'" 
				END IF 
				LET l_where_text[1,1] = " " 
				LET l_where_text = "salesperson.sale_type_ind in (", l_where_text clipped,")" 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET modu_temp_l_where_text = l_where_text 
		LET modu_temp_state_code = l_state_code 
		LET modu_temp_start_date = l_start_date 
		LET modu_temp_end_date = l_end_date 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_sper_type() 
#
#
###########################################################################


###########################################################################
# FUNCTION company_sales(p_cmpy_code,p_l_where_text,p_state_code,p_start_date,p_end_date) 
#
#
###########################################################################
FUNCTION company_sales(p_cmpy_code,p_l_where_text,p_state_code,p_start_date,p_end_date) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_l_where_text STRING
	DEFINE p_state_code LIKE salesperson.state_code
	DEFINE p_start_date DATE 
	DEFINE p_end_date DATE	
	DEFINE l_query_text STRING
	DEFINE l_state_code char(10) 
--	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
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
	DEFINE l_arr_rec_totprvgrs_amt array[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT	

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1"
	
--	SELECT * INTO l_rec_company.* 
--	FROM company 
--	WHERE cmpy_code = p_cmpy_code
	 
	IF status = 0 THEN 
		OPEN WINDOW E266 with FORM "E266" 
		 CALL windecoration_e("E266") -- albo kd-755 
		IF p_state_code IS NOT NULL THEN 
			LET l_state_code = p_state_code 
			LET p_l_where_text = p_l_where_text clipped,	" AND salesperson.state_code = '",p_state_code,"'" 
		ELSE 
			LET l_state_code = kandooword("National","1") 
		END IF 
		LET l_query_text = 
		"SELECT sum(grs_amt),sum(net_amt),sum(orders_num),", 
		" sum(credits_num),sum(net_cred_amt)", 
		" FROM statsper, salesperson", 
		" WHERE statsper.cmpy_code = '",p_cmpy_code,"'", 
		" AND salesperson.cmpy_code = '",p_cmpy_code,"'", 
		" AND salesperson.sale_code = statsper.sale_code", 
		" AND statsper.year_num = ?", 
		" AND statsper.type_code = ?", 
		" AND statsper.int_num = ?", 
		" AND ",p_l_where_text clipped 
		PREPARE s_statsper FROM l_query_text 
		DECLARE c_statsper cursor FOR s_statsper 

		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY 
				glob_rec_company.cmpy_code, 
				glob_rec_company.name_text, 
				l_state_code, 
				p_start_date, 
				p_end_date 
			TO
				cmpy_code, 
				name_text, 
				state_code, 
				start_date, 
				end_date 
		

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
			AND type_code = l_rec_statparms.day_type_code 
			AND start_date >= p_start_date 
			AND end_date <= p_end_date 
			ORDER BY 1,2,3,4 

			LET l_idx = 0 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsper[l_idx].int_text = l_rec_statint.int_text 

				OPEN c_statsper USING l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 

				FETCH c_statsper INTO 
					l_rec_statsper.grs_amt, 
					l_rec_statsper.net_amt, 
					l_rec_statsper.orders_num, 
					l_rec_statsper.credits_num, 
					l_rec_statsper.net_cred_amt 

				IF l_rec_statsper.grs_amt IS NULL THEN 
					LET l_rec_statsper.grs_amt = 0 
				END IF 
				IF l_rec_statsper.net_amt IS NULL THEN 
					LET l_rec_statsper.net_amt = 0 
				END IF 
				IF l_rec_statsper.orders_num IS NULL THEN 
					LET l_rec_statsper.orders_num = 0 
				END IF 
				IF l_rec_statsper.credits_num IS NULL THEN 
					LET l_rec_statsper.credits_num = 0 
				END IF 
				IF l_rec_statsper.net_cred_amt IS NULL THEN 
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
					LET l_arr_rec_statsper[l_idx].avg_ord_val = l_arr_rec_statsper[l_idx].net_amt / (l_arr_rec_statsper[l_idx].orders_num - l_arr_rec_statsper[l_idx].credits_num) 
				END IF 
				## increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_statsper.grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_statsper.net_amt 
				LET l_arr_rec_stattotal[1].tot_orders_num = l_arr_rec_stattotal[1].tot_orders_num + l_rec_statsper.orders_num 
				LET l_arr_rec_stattotal[1].tot_credits_num = l_arr_rec_stattotal[1].tot_credits_num + l_rec_statsper.credits_num 
				LET l_arr_rec_stattotal[1].tot_net_cred_amt = l_arr_rec_stattotal[1].tot_net_cred_amt + l_rec_statsper.net_cred_amt 
				IF l_rec_statint.int_num <= l_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_statsper.grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_statsper.net_amt 
					LET l_arr_rec_stattotal[2].tot_orders_num = l_arr_rec_stattotal[2].tot_orders_num + l_rec_statsper.orders_num 
					LET l_arr_rec_stattotal[2].tot_credits_num = l_arr_rec_stattotal[2].tot_credits_num + l_rec_statsper.credits_num 
					LET l_arr_rec_stattotal[2].tot_net_cred_amt = l_arr_rec_stattotal[2].tot_net_cred_amt + l_rec_statsper.net_cred_amt 
				END IF 

			END FOREACH 
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") 	#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_net_amt /l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 
						l_arr_rec_stattotal[i].tot_net_amt / (l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1138,"") #1138 Company daily Sales - F8 Enter Dates - F9 Previous - F10 Next
				INPUT ARRAY l_arr_rec_statsper WITHOUT DEFAULTS FROM sr_statsper.* 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","EG3","input-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "F8" ----ON KEY (f8)  #? why another cancel ? 
						EXIT INPUT 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET i = p_end_date - p_start_date 
						LET p_end_date = p_start_date - 1 
						LET p_start_date = p_end_date - i 
						EXIT INPUT 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET i = p_end_date - p_start_date 
						LET p_start_date = p_end_date + 1 
						LET p_end_date = p_start_date + i 
						EXIT INPUT 
						
				END INPUT 
			END IF 

			CASE fgl_lastaction() 

				WHEN "F8" 
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

			FOR i = 1 TO arr_count() 
				INITIALIZE l_arr_rec_statsper[i].* TO NULL 
			END FOR 
		END WHILE 

		CLOSE WINDOW E266 

	END IF 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION company_sales(p_cmpy_code,p_l_where_text,p_state_code,p_start_date,p_end_date) 
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
	INPUT 
		l_start_date, 
		l_end_date WITHOUT DEFAULTS
	FROM 
		start_date,
		end_date ATTRIBUTE(UNBUFFERED)
		
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EG3","input-l_start_date-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER FIELD l_start_date 
			IF l_start_date IS NULL THEN 
				NEXT FIELD start_date 
			END IF 
			
		AFTER FIELD l_end_date 
			IF l_end_date IS NULL THEN 
				NEXT FIELD end_date 
			END IF 

	END INPUT 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN p_start_date, 
		p_end_date 
	ELSE 
		RETURN l_start_date, 
		l_end_date 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_dates(p_start_date,p_end_date)
###########################################################################