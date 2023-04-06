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
GLOBALS "../eo/ED_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/ED5_GLOBALS.4gl"
###########################################################################
# FUNCTION ED5_main()
#
# ED5 - allows users TO SELECT a sales manager TO peruse
#       profit information FROM statistics tables.
###########################################################################
FUNCTION ED5_main() 
	DEFINE l_salesmgr_mgr_code LIKE salesmgr.mgr_code
	
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ED5") -- albo 

	LET l_salesmgr_mgr_code = get_url_salesmgr_code() 
	IF l_salesmgr_mgr_code IS NOT NULL THEN
		CALL mgr_profit(glob_rec_kandoouser.cmpy_code,l_salesmgr_mgr_code) 
	ELSE 

		OPEN WINDOW E226 with FORM "E226" 
		 CALL windecoration_e("E226") -- albo kd-755
 
		CALL scan_mgr() 
	
		CLOSE WINDOW E226 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION ED5_main()
###########################################################################


###########################################################################
# FUNCTION salesmgr_get_datasource()
#
# ED5 - allows users TO SELECT a sales manager TO peruse
#       profit information FROM statistics tables.
###########################################################################
FUNCTION salesmgr_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_arr_rec_salesmgr DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON mgr_code, name_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ED5","construct-mgr_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
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
		"SELECT * FROM salesmgr ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_salesmgr FROM l_query_text 
	DECLARE c_salesmgr cursor FOR s_salesmgr 

	LET l_idx = 0 
	FOREACH c_salesmgr INTO l_rec_salesmgr.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salesmgr[l_idx].mgr_code = l_rec_salesmgr.mgr_code 
		LET l_arr_rec_salesmgr[l_idx].name_text = l_rec_salesmgr.name_text 
		SELECT unique 1 FROM statsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND mgr_code = l_rec_salesmgr.mgr_code 
		AND sale_code IS NULL 
		IF status = 0 THEN 
			LET l_arr_rec_salesmgr[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salesmgr[l_idx].stat_flag = NULL 
		END IF 		

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH
	 
	IF l_arr_rec_salesmgr.getSize() = 0 THEN 
		ERROR kandoomsg2("A",9082,"") 
	END IF

	RETURN l_arr_rec_salesmgr 
 
END FUNCTION 
###########################################################################
# END FUNCTION salesmgr_get_datasource()
###########################################################################


###########################################################################
# FUNCTION scan_mgr()
#
# ED5 - allows users TO SELECT a sales manager TO peruse
#       profit information FROM statistics tables.
###########################################################################
FUNCTION scan_mgr() 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_arr_rec_salesmgr DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		mgr_code LIKE salesmgr.mgr_code, 
		name_text LIKE salesmgr.name_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr	 
 
	MESSAGE kandoomsg2("E",1094,"") 	#1094 " Sales Manager Profit Figures - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_salesmgr TO sr_salesmgr.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","ED5","input-arr-l_arr_rec_salesmgr-1") 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesmgr.clear()
			CALL salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())

		ON ACTION "REFRESH"
			 CALL windecoration_e("E226") 
			CALL l_arr_rec_salesmgr.clear()
			CALL salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())
 
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD mgr_code
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salesmgr.getSize()) THEN
				CALL mgr_profit(glob_rec_kandoouser.cmpy_code,l_arr_rec_salesmgr[l_idx].mgr_code) 
			END IF
			
		BEFORE ROW 
			LET l_idx = arr_curr() 
 
	END DISPLAY
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE
	 
END FUNCTION 
###########################################################################
# END FUNCTION scan_mgr()
###########################################################################

###########################################################################
# FUNCTION mgr_profit(p_cmpy_code,p_mgr_code)
#
# ED5 - allows users TO SELECT a sales manager TO peruse
#       profit information FROM statistics tables.
###########################################################################
FUNCTION mgr_profit(p_cmpy_code,p_mgr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_mgr_code LIKE salesmgr.mgr_code 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	DEFINE l_rec_prv_statsper RECORD LIKE statsper.* ## previous year 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		net_amt LIKE statsper.net_amt, 
		prof_amt LIKE statsper.grs_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statsper.net_amt, 
		prv_prof_amt LIKE statsper.grs_amt, 
		prv_disc_per FLOAT, 
		var_prof_per LIKE statsper.grs_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_net_amt LIKE statsper.net_amt, 
		tot_prof_amt LIKE statsper.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statsper.net_amt, 
		tot_prv_prof_amt LIKE statsper.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_prof_per LIKE statsper.grs_amt 
	END RECORD 
	DEFINE l_arr_totprvgrs_amt array[2] OF decimal(16,2)# previous year gross amt 
	DEFINE l_arr_totcurgrs_amt array[2] OF decimal(16,2)# CURRENT "" "" "" 
	# 1->Total    2->YTD
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	 
	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1"
	 
	SELECT * INTO l_rec_salesmgr.* 
	FROM salesmgr 
	WHERE cmpy_code = p_cmpy_code 
	AND mgr_code = p_mgr_code
	 
	IF status = 0 THEN 
		OPEN WINDOW E230 with FORM "E230" 
		 CALL windecoration_e("E230") -- albo kd-755
 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			
			DISPLAY BY NAME l_rec_salesmgr.mgr_code 
			DISPLAY BY NAME l_rec_salesmgr.name_text 

			LET i = l_rec_statparms.year_num - 1 
			DISPLAY l_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY i TO sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = l_rec_statparms.year_num 
			AND type_code = l_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 
			
			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prof_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
				LET l_arr_totcurgrs_amt[i] = 0 
				LET l_arr_totprvgrs_amt[i] = 0 
			END FOR 
			
			LET l_idx = 0 
			
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsper[l_idx].int_text = l_rec_statint.int_text 
				## obtain current year grs,net AND disc%
				SELECT * INTO l_rec_cur_statsper.* 
				FROM statsper 
				WHERE cmpy_code = p_cmpy_code 
				AND mgr_code = p_mgr_code 
				AND sale_code IS NULL 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
					LET l_rec_cur_statsper.net_amt = 0 
					LET l_rec_cur_statsper.cost_amt = 0 
				END IF 

				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt 
				LET l_arr_rec_statsper[l_idx].prof_amt = l_rec_cur_statsper.net_amt - l_rec_cur_statsper.cost_amt 

				IF l_rec_cur_statsper.grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 100 * (1-(l_rec_cur_statsper.net_amt/l_rec_cur_statsper.grs_amt)) 
				END IF 
				
				## obtain previous year grs,net AND disc%
				SELECT * INTO l_rec_prv_statsper.* 
				FROM statsper 
				WHERE cmpy_code = p_cmpy_code 
				AND mgr_code = p_mgr_code 
				AND sale_code IS NULL 
				AND year_num = l_rec_statparms.year_num - 1 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statsper.grs_amt = 0 
					LET l_rec_prv_statsper.net_amt = 0 
					LET l_rec_prv_statsper.cost_amt = 0 
				END IF 
				
				LET l_arr_rec_statsper[l_idx].prv_net_amt = l_rec_prv_statsper.net_amt 
				LET l_arr_rec_statsper[l_idx].prv_prof_amt = l_rec_prv_statsper.net_amt - l_rec_prv_statsper.cost_amt 
				IF l_rec_prv_statsper.grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].prv_disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].prv_disc_per = 100 *(1-(l_rec_prv_statsper.net_amt/l_rec_prv_statsper.grs_amt)) 
				END IF 
				IF l_arr_rec_statsper[l_idx].prv_prof_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].var_prof_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].var_prof_per = 100 
					*(l_arr_rec_statsper[l_idx].prof_amt-l_arr_rec_statsper[l_idx].prv_prof_amt) / l_arr_rec_statsper[l_idx].prv_prof_amt 
				END IF 
				
				#### increment totals (AND YTD IF current OR less month)
				FOR i = 1 TO 2 
					LET l_arr_rec_stattotal[i].tot_net_amt = l_arr_rec_stattotal[i].tot_net_amt + l_rec_cur_statsper.net_amt 
					LET l_arr_rec_stattotal[i].tot_prof_amt = l_arr_rec_stattotal[i].tot_prof_amt + l_arr_rec_statsper[l_idx].prof_amt 
					LET l_arr_totcurgrs_amt[i] = l_arr_totcurgrs_amt[i] + l_rec_cur_statsper.grs_amt 
					LET l_arr_rec_stattotal[i].tot_prv_net_amt = l_arr_rec_stattotal[i].tot_prv_net_amt + l_rec_prv_statsper.net_amt 
					LET l_arr_rec_stattotal[i].tot_prv_prof_amt = l_arr_rec_stattotal[i].tot_prv_prof_amt + l_arr_rec_statsper[l_idx].prv_prof_amt 
					LET l_arr_totprvgrs_amt[i] = l_arr_totprvgrs_amt[i] + l_rec_prv_statsper.grs_amt 
					IF l_rec_statint.int_num > l_rec_statparms.mth_num THEN 
						EXIT FOR 
					END IF 
				END FOR 

			END FOREACH 

			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"")		#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
					# calc total current & previous year disc%
					IF l_arr_totcurgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 	* (1-(l_arr_rec_stattotal[i].tot_net_amt/l_arr_totcurgrs_amt[i])) 
					END IF 
					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_totprvgrs_amt[i])) 
					END IF 
					# calc profit variance
					IF l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 100 * ( l_arr_rec_stattotal[i].tot_prof_amt 
						- l_arr_rec_stattotal[i].tot_prv_prof_amt) / l_arr_rec_stattotal[i].tot_prv_prof_amt 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				
				MESSAGE kandoomsg2("E",1088,"") 		#1088 Sales Manager Profit Figures - F9 Prev - F10 Next
 
				DISPLAY ARRAY l_arr_rec_statsper TO  sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","ED5","input-arr-l_arr_rec_statsper-1") -- albo kd-502 

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
			 
{			IF fgl_lastkey() = fgl_keyval("F9")	OR fgl_lastkey() = fgl_keyval("F10") THEN 
				FOR i = 1 TO arr_count() 
					INITIALIZE l_arr_rec_statsper[i].* TO NULL 
				END FOR 
			ELSE 
				EXIT WHILE 
			END IF 
	}
			IF int_flag THEN
				EXIT WHILE 
			END IF 
					
		END WHILE
	 
		CLOSE WINDOW E230 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION mgr_profit(p_cmpy_code,p_mgr_code)
###########################################################################