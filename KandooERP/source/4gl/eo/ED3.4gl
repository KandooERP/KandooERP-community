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
GLOBALS "../eo/ED3_GLOBALS.4gl"
###########################################################################
# FUNCTION ED3_main()
#
# ED3 - allows users TO SELECT a sales manager/salesperson TO
#               TO peruse sales information FROM statistics tables.
###########################################################################
FUNCTION ED3_main() 
	DEFINE l_salesmgr_mgr_code LIKE salesmgr.mgr_code
	
	DEFER INTERRUPT 
	DEFER QUIT 

	CALL setModuleId("ED3") -- albo 

	LET l_salesmgr_mgr_code = get_url_salesmgr_code() 
	IF l_salesmgr_mgr_code IS NOT NULL THEN
		CALL mgr_sperturn(glob_rec_kandoouser.cmpy_code,l_salesmgr_mgr_code) 
	ELSE 
		OPEN WINDOW E226 with FORM "E226" 
		 CALL windecoration_e("E226") -- albo kd-755 
 
		CALL scan_mgr() 
 
		CLOSE WINDOW E226 
	END IF 
END FUNCTION
 
###########################################################################
# END FUNCTION ED3_main()
###########################################################################


###########################################################################
# FUNCTION db_salesmgr_get_datasource(p_filter) 
#
# 
###########################################################################
FUNCTION db_salesmgr_get_datasource(p_filter)
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
		CONSTRUCT BY NAME l_where_text ON mgr_code,	name_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ED3","construct-mgr_code-1") -- albo kd-502 
	
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
		 
	LET l_query_text = "SELECT * FROM salesmgr ", 
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
# END FUNCTION db_salesmgr_get_datasource(p_filter) 
###########################################################################


###########################################################################
# FUNCTION scan_mgr()  
#
# 
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

	CALL db_salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr
	 
	MESSAGE kandoomsg2("E",1095,"") #1095 " Salesperson Turnover Vs Target - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_salesmgr TO sr_salesmgr.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","ED3","input-arr-l_arr_rec_salesmgr-1") -- albo kd-502 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salesmgr.clear()
			CALL db_salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())
			
		ON ACTION "REFRESH"
			 CALL windecoration_e("E226")
			CALL l_arr_rec_salesmgr.clear()
			CALL db_salesmgr_get_datasource(FALSE) RETURNING l_arr_rec_salesmgr
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salesmgr.getSize())

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD mgr_code 
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salesmgr.getSize()) THEN
				IF l_arr_rec_salesmgr[l_idx].mgr_code IS NOT NULL THEN 
					CALL mgr_sperturn(glob_rec_kandoouser.cmpy_code,l_arr_rec_salesmgr[l_idx].mgr_code) 
				END IF 
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
# FUNCTION mgr_sperturn(p_cmpy_code,p_mgr_code)  
#
# 
###########################################################################
FUNCTION mgr_sperturn(p_cmpy_code,p_mgr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_mgr_code LIKE salesmgr.mgr_code 
	DEFINE l_rec_salesmgr RECORD LIKE salesmgr.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	--DEFINE l_int_text LIKE statint.int_text 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		sale_code LIKE salesperson.sale_code, 
		sale_name LIKE salesperson.name_text, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		disc_per FLOAT, 
		bdgt_amt LIKE stattarget.bdgt_amt, 
		achieve_per FLOAT 
	END RECORD 
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_year_num decimal(4,0) 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	OPEN WINDOW E233 with FORM "E233" 
	 CALL windecoration_e("E233") -- albo kd-755
 
 
	SELECT * INTO l_rec_salesmgr.* 
	FROM salesmgr 
	WHERE cmpy_code = p_cmpy_code 
	AND mgr_code = p_mgr_code 
	IF not(int_flag OR quit_flag) THEN 
		LET l_query_text ="SELECT * FROM statsper ", 
		"WHERE cmpy_code = '",p_cmpy_code,"' ", 
		"AND mgr_code = '",p_mgr_code,"' ", 
		"AND year_num = ? ", 
		"AND type_code = ? ", 
		"AND sale_code = ? ", 
		"AND int_num = ? " 
		PREPARE s_statsper FROM l_query_text 
		DECLARE c_statsper cursor FOR s_statsper
		 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36
		 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM
			 
			SELECT * INTO l_rec_statint.* FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = l_rec_statparms.year_num 
			AND type_code = l_rec_statparms.mth_type_code 
			AND int_num = l_rec_statparms.mth_num 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("E",7086,"") 		#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			END IF 

			DISPLAY BY NAME l_rec_salesmgr.mgr_code 
			DISPLAY BY NAME l_rec_salesmgr.name_text 
			DISPLAY BY NAME l_rec_statint.int_text 
			DISPLAY BY NAME l_rec_statparms.year_num 

			LET l_idx = 0 
			DECLARE c_salesperson cursor FOR 
			SELECT * FROM salesperson 
			WHERE cmpy_code = p_cmpy_code 
			AND mgr_code = p_mgr_code 

			FOREACH c_salesperson INTO l_rec_salesperson.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsper[l_idx].sale_code = l_rec_salesperson.sale_code 
				LET l_arr_rec_statsper[l_idx].sale_name = l_rec_salesperson.name_text 
				
				#-------------------------------------------------------------------
				# obtain current year grs,net AND disc%
				OPEN c_statsper USING l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_salesperson.sale_code, 
				l_rec_statint.int_num 
				FETCH c_statsper INTO l_rec_cur_statsper.* 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
					LET l_rec_cur_statsper.net_amt = 0 
				END IF
				 
				LET l_arr_rec_statsper[l_idx].grs_amt = l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt 
				IF l_arr_rec_statsper[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 100 * 
					(1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
				END IF
				 
				SELECT bdgt_amt 
				INTO l_arr_rec_statsper[l_idx].bdgt_amt 
				FROM stattarget 
				WHERE cmpy_code = p_cmpy_code 
				AND bdgt_type_ind = "4" 
				AND bdgt_type_code = l_rec_salesperson.sale_code 
				AND bdgt_ind = "1" 
				AND year_num = l_rec_statparms.year_num 
				AND type_code = l_rec_statparms.mth_type_code 
				AND int_num = l_rec_statparms.mth_num 
				IF l_arr_rec_statsper[l_idx].bdgt_amt IS NULL THEN 
					LET l_arr_rec_statsper[l_idx].bdgt_amt = 0 
				END IF 
				IF l_arr_rec_statsper[l_idx].bdgt_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].achieve_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].achieve_per = 100 * 
					(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].bdgt_amt) 
				END IF 
				IF l_idx = 100 THEN 
					EXIT FOREACH 
				END IF 
			END FOREACH 
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") 			#7086 No statistical information exists FOR this selection "
			ELSE 
				MESSAGE kandoomsg2("E",1091,"") 			#1091 Monthly Turnover - RETURN TO View - F8 SELECT Year
				#-------------------------------------------------------------------
				#                      - F9 Previous Month - F10 Next Month
				CALL set_count(l_idx) 
				INPUT ARRAY l_arr_rec_statsper WITHOUT DEFAULTS FROM sr_statsper.* 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","ED3","input-arr-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					BEFORE FIELD sale_code 
						CALL sper_targets(p_cmpy_code,l_arr_rec_statsper[l_idx].sale_code, 
						l_rec_statparms.year_num) 
						NEXT FIELD scroll_flag 

					ON ACTION "BY YEAR" #ON KEY (f8) 
						LET l_rec_statparms.year_num = enter_year(l_rec_statparms.year_num) 
						EXIT INPUT 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						SELECT year_num,int_num 
						INTO l_rec_statparms.year_num, l_rec_statparms.mth_num 
						FROM statint 
						WHERE cmpy_code = p_cmpy_code 
						AND end_date = l_rec_statint.start_date - 1 
						AND type_code = l_rec_statparms.mth_type_code 
						EXIT INPUT 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						SELECT year_num,int_num 
						INTO l_rec_statparms.year_num, l_rec_statparms.mth_num 
						FROM statint 
						WHERE cmpy_code = p_cmpy_code 
						AND start_date = l_rec_statint.end_date + 1 
						AND type_code = l_rec_statparms.mth_type_code 
						EXIT INPUT 
				END INPUT 
			END IF 

			CASE fgl_lastaction() 
				WHEN "by year" --fgl_keyval("F8") 
					LET l_rec_statparms.year_num = enter_year(l_rec_statparms.year_num) 

				WHEN "year-1" --fgl_keyval("F9") 
					SELECT year_num,int_num 
					INTO l_rec_statparms.year_num, l_rec_statparms.mth_num 
					FROM statint 
					WHERE cmpy_code = p_cmpy_code 
					AND end_date = l_rec_statint.start_date - 1 
					AND type_code = l_rec_statparms.mth_type_code 

				WHEN "year+1" --fgl_keyval("F10") 
					SELECT year_num,int_num 
					INTO l_rec_statparms.year_num, l_rec_statparms.mth_num 
					FROM statint 
					WHERE cmpy_code = p_cmpy_code 
					AND start_date = l_rec_statint.end_date + 1 
					AND type_code = l_rec_statparms.mth_type_code 

				OTHERWISE 
					EXIT WHILE 
			END CASE 

			CALL l_arr_rec_statsper.clear()
--			FOR i = 1 TO arr_count() 
--				INITIALIZE l_arr_rec_statsper[i].* TO NULL 
--			END FOR 
		END WHILE 

	END IF 

	CLOSE WINDOW E233 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION mgr_sperturn(p_cmpy_code,p_mgr_code)  
###########################################################################


###########################################################################
# FUNCTION enter_year(p_curr_year_num)  
#
# 
###########################################################################
FUNCTION enter_year(p_curr_year_num) 
	DEFINE p_curr_year_num decimal(4,0)
	DEFINE l_year_num decimal(4,0) 
	
	LET l_year_num = p_curr_year_num 
	INPUT l_year_num WITHOUT DEFAULTS FROM year_num 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ED3","input-arr-l_year_num-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_year_num IS NULL THEN 
					ERROR kandoomsg2("E",9210,"") 		#9210 Year number invalid
					LET l_year_num = glob_rec_statparms.year_num 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT
	 
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN p_curr_year_num 
	ELSE 
		RETURN l_year_num 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION enter_year(p_curr_year_num)  
###########################################################################