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
GLOBALS "../eo/ECA_GLOBALS.4gl"
###########################################################################
# FUNCTION ECA_main()
#
# ECA - allows users TO SELECT a salesperson TO which peruse
#       commission information FROM statistics tables.
###########################################################################
FUNCTION ECA_main() 
	DEFINE l_arg_sale_code LIKE salesperson.sale_code
	
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("ECA") -- albo 

	LET l_arg_sale_code = get_url_sale_code()
	IF l_arg_sale_code IS NOT NULL THEN
		CALL sper_commiss(glob_rec_kandoouser.cmpy_code,l_arg_sale_code) 
	ELSE 
		 
		OPEN WINDOW E184 with FORM "E184" 
		 CALL windecoration_e("E184") -- albo kd-755
 
		CALL scan_sale() 
		
		CLOSE WINDOW E184 
	END IF 
	
END FUNCTION 
###########################################################################
# END FUNCTION ECA_main()
###########################################################################


###########################################################################
# FUNCTION db_salesperson_get_datasource(p_filter)
#
# 
###########################################################################
FUNCTION db_salesperson_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		state_code LIKE salesperson.state_code, 
		mgr_code LIKE salesperson.mgr_code, 
		sale_type_ind LIKE salesperson.sale_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			sale_code, 
			name_text, 
			city_text, 
			state_code, 
			mgr_code, 
			sale_type_ind 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ECA","construct-sale_code-1")  
	
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
		
	MESSAGE kandoomsg2("E",1002,"") #1002 Searching database -please wait
	LET l_query_text = 
		"SELECT * FROM salesperson ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_salesperson FROM l_query_text 
	DECLARE c_salesperson cursor FOR s_salesperson

	LET l_idx = 0 
	FOREACH c_salesperson INTO l_rec_salesperson.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesperson[l_idx].sale_code = l_rec_salesperson.sale_code 
		LET l_arr_rec_salesperson[l_idx].name_text = l_rec_salesperson.name_text 

		IF l_rec_salesperson.city_text IS NOT NULL THEN 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.city_text 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].city_text = l_rec_salesperson.addr2_text 
		END IF 

		LET l_arr_rec_salesperson[l_idx].state_code = l_rec_salesperson.state_code 
		LET l_arr_rec_salesperson[l_idx].mgr_code = l_rec_salesperson.mgr_code 
		LET l_arr_rec_salesperson[l_idx].sale_type_ind = l_rec_salesperson.sale_type_ind 

		SELECT unique 1 FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND sale_code = l_rec_salesperson.sale_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.mth_type_code 
		IF status = 0 THEN 
			LET l_arr_rec_salesperson[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salesperson[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	RETURN l_arr_rec_salesperson		 
END FUNCTION 
###########################################################################
# END FUNCTION db_salesperson_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_sale() 
#
# 
###########################################################################
FUNCTION scan_sale() 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_arr_rec_salesperson DYNAMIC ARRAY OF RECORD
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		name_text LIKE salesperson.name_text, 
		city_text LIKE salesperson.city_text, 
		state_code LIKE salesperson.state_code, 
		mgr_code LIKE salesperson.mgr_code, 
		sale_type_ind LIKE salesperson.sale_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_salesperson_get_datasource(FALSE) RETURNING l_arr_rec_salesperson 

	MESSAGE kandoomsg2("E",1101,"") #1101 Salesperson Commission - RETURN TO View
	DISPLAY ARRAY l_arr_rec_salesperson TO sr_salesperson.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","ECA","input-arr-l_arr_rec_salesperson-1")  
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesperson.clear()	
			CALL db_salesperson_get_datasource(TRUE) RETURNING l_arr_rec_salesperson
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION "REFRESH"
			 CALL windecoration_e("E184")
			CALL l_arr_rec_salesperson.clear()	
			CALL db_salesperson_get_datasource(FALSE) RETURNING l_arr_rec_salesperson
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesperson.getSize())

		ON ACTION ("ACCEPT","-DOUBLECLICK") 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salesperson.getSize()) THEN
				CALL sper_commiss(glob_rec_kandoouser.cmpy_code,l_arr_rec_salesperson[l_idx].sale_code)
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_sale() 
#
# 
###########################################################################


###########################################################################
# FUNCTION sper_commiss(p_cmpy_code,p_sale_code)  
#
# 
###########################################################################
FUNCTION sper_commiss(p_cmpy_code,p_sale_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		disc_per FLOAT, 
		orders_num LIKE statsper.orders_num, 
		credits_num LIKE statsper.credits_num, 
		comm_amt LIKE statsper.comm_amt, 
		avg_ord_val LIKE statsper.net_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_grs_amt LIKE statsper.grs_amt, 
		tot_net_amt LIKE statsper.net_amt, 
		tot_disc_per FLOAT, 
		tot_orders_num LIKE statsper.orders_num, 
		tot_credits_num LIKE statsper.credits_num, 
		tot_comm_amt LIKE statsper.comm_amt, 
		tot_avg_ord_val LIKE statsper.net_amt 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	

	SELECT * INTO l_rec_salesperson.* 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy_code 
	AND sale_code = p_sale_code
	 
	IF status = 0 THEN 
		OPEN WINDOW E238 with FORM "E238" 
		 CALL windecoration_e("E238") -- albo kd-755 

		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 

			DISPLAY BY NAME l_rec_salesperson.sale_code 
			DISPLAY BY NAME l_rec_salesperson.name_text 
			DISPLAY BY NAME glob_rec_statparms.year_num 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_orders_num = 0 
				LET l_arr_rec_stattotal[i].tot_credits_num = 0 
				LET l_arr_rec_stattotal[i].tot_comm_amt = 0 
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
				
				#------------------------------------------------
				# obtain current year grs,net AND disc%
				SELECT * INTO l_rec_cur_statsper.* 
				FROM statsper 
				WHERE cmpy_code = p_cmpy_code 
				AND sale_code = p_sale_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
					LET l_rec_cur_statsper.net_amt = 0 
					LET l_rec_cur_statsper.orders_num = 0 
					LET l_rec_cur_statsper.credits_num = 0 
					LET l_rec_cur_statsper.comm_amt = 0 
				END IF 
				LET l_arr_rec_statsper[l_idx].grs_amt = l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt
				 
				IF l_arr_rec_statsper[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 100 *	(1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
				END IF
				 
				LET l_arr_rec_statsper[l_idx].orders_num = l_rec_cur_statsper.orders_num 
				LET l_arr_rec_statsper[l_idx].credits_num = l_rec_cur_statsper.credits_num 
				LET l_arr_rec_statsper[l_idx].comm_amt = l_rec_cur_statsper.comm_amt
				 
				IF (l_arr_rec_statsper[l_idx].orders_num - l_arr_rec_statsper[l_idx].credits_num) = 0 THEN 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].avg_ord_val = l_arr_rec_statsper[l_idx].net_amt / (l_arr_rec_statsper[l_idx].orders_num - l_arr_rec_statsper[l_idx].credits_num) 
				END IF 
				
				#------------------------------------------------
				# increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statsper.net_amt 
				LET l_arr_rec_stattotal[1].tot_orders_num = l_arr_rec_stattotal[1].tot_orders_num + l_rec_cur_statsper.orders_num 
				LET l_arr_rec_stattotal[1].tot_credits_num = l_arr_rec_stattotal[1].tot_credits_num + l_rec_cur_statsper.credits_num 
				LET l_arr_rec_stattotal[1].tot_comm_amt = l_arr_rec_stattotal[1].tot_comm_amt + l_rec_cur_statsper.comm_amt 

				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statsper.grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statsper.net_amt 
					LET l_arr_rec_stattotal[2].tot_orders_num = l_arr_rec_stattotal[2].tot_orders_num + l_rec_cur_statsper.orders_num 
					LET l_arr_rec_stattotal[2].tot_credits_num = l_arr_rec_stattotal[2].tot_credits_num + l_rec_cur_statsper.credits_num 
					LET l_arr_rec_stattotal[2].tot_comm_amt = l_arr_rec_stattotal[2].tot_comm_amt + l_rec_cur_statsper.comm_amt 
				END IF 

			END FOREACH 

			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") #7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
					#------------------------------------------------
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt	/ l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_stattotal[i].tot_orders_num - l_arr_rec_stattotal[i].tot_credits_num = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_avg_ord_val = l_arr_rec_stattotal[i].tot_net_amt	/ (l_arr_rec_stattotal[i].tot_orders_num	- l_arr_rec_stattotal[i].tot_credits_num) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				MESSAGE kandoomsg2("E",1102,"")	#1102 Salesperson Commission - F9 Previous Year - F10 Next Year
 
				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED)
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","ECA","input-arr-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
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
			
			IF int_flag THEN
				EXIT WHILE 
			END IF 
		
		END WHILE 

		CLOSE WINDOW E238 

	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_commiss(p_cmpy_code,p_sale_code)  
###########################################################################