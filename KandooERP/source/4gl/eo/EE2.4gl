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
GLOBALS "../eo/EE_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EE2_GLOBALS.4gl"
###########################################################################
# FUNCTION EE2_main() 
#
# EE2 - allows users TO SELECT a sales territory TO peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION EE2_main()  
	DEFINE l_terr_code LIKE territory.terr_code
	
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EE2") -- albo 

	LET l_terr_code = get_url_terr_code()
	IF l_terr_code IS NOT NULL THEN 
		CALL terr_turnover(glob_rec_kandoouser.cmpy_code,l_terr_code) 
	ELSE 

		OPEN WINDOW E247 with FORM "E247" 
		 CALL windecoration_e("E247") -- albo kd-755 

		CALL scan_territory() 
 
		CLOSE WINDOW E247 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION EE2_main() 
###########################################################################


###########################################################################
# FUNCTION territory_get_datasource()
#
#
###########################################################################
FUNCTION territory_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code, 
		sale_code LIKE territory.sale_code, 
		terr_type_ind LIKE territory.terr_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			terr_code, 
			desc_text, 
			area_code, 
			sale_code, 
			terr_type_ind 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EE2","construct-terr_code-1") -- albo kd-502 
	
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
 
	MESSAGE kandoomsg2("A",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * ", 
		"FROM territory ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,2" 
	PREPARE s_territory FROM l_query_text 
	DECLARE c_territory cursor FOR s_territory 

	LET l_idx = 0 
	FOREACH c_territory INTO l_rec_territory.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_territory[l_idx].terr_code = l_rec_territory.terr_code 
		LET l_arr_rec_territory[l_idx].desc_text = l_rec_territory.desc_text 
		LET l_arr_rec_territory[l_idx].area_code = l_rec_territory.area_code 
		LET l_arr_rec_territory[l_idx].sale_code = l_rec_territory.sale_code 
		LET l_arr_rec_territory[l_idx].terr_type_ind = l_rec_territory.terr_type_ind 

		SELECT unique 1 FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_rec_territory.area_code 
		AND terr_code = l_rec_territory.terr_code 
		IF status = 0 THEN 
			LET l_arr_rec_territory[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_territory[l_idx].stat_flag = NULL 
		END IF
		 
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 
	
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9081,"") 	#9081" No Sales Territories Satsified Selection Criteria "
	END IF

	RETURN l_arr_rec_territory
END FUNCTION 
###########################################################################
# END FUNCTION territory_get_datasource()
#
#
###########################################################################


###########################################################################
# FUNCTION scan_territory()
#
#
###########################################################################
FUNCTION scan_territory() 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_arr_rec_territory DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		terr_code LIKE territory.terr_code, 
		desc_text LIKE territory.desc_text, 
		area_code LIKE territory.area_code, 
		sale_code LIKE territory.sale_code, 
		terr_type_ind LIKE territory.terr_type_ind, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT	

	CALL territory_get_datasource(FALSE) RETURNING l_arr_rec_territory

	MESSAGE kandoomsg2("E",1116,"")	#" Sales Territory Monthly Turnover - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_territory TO sr_territory.* ATTRIBUTE(UNBUFFERED)
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EE2","input-arr-l_arr_rec_territory-1") -- albo kd-502 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_territory.getSize())
			
		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_territory.clear()
			CALL territory_get_datasource(TRUE) RETURNING l_arr_rec_territory		

		ON ACTION "REFRESH"
			CALL l_arr_rec_territory.clear()
			CALL territory_get_datasource(FALSE) RETURNING l_arr_rec_territory		
			 CALL windecoration_e("E247")
			
		BEFORE ROW 
			LET l_idx = arr_curr() 
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD terr_code 
			IF l_idx > 0 THEN
				CALL terr_turnover(glob_rec_kandoouser.cmpy_code, l_arr_rec_territory[l_idx].terr_code)
			END IF 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_territory()
###########################################################################


###########################################################################
# FUNCTION terr_turnover(p_cmpy_code,p_terr_code)
#
#
###########################################################################
FUNCTION terr_turnover(p_cmpy_code,p_terr_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_terr_code LIKE territory.terr_code 
	DEFINE l_rec_territory RECORD LIKE territory.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statterr RECORD LIKE statterr.* ## CURRENT year 
	DEFINE l_rec_prv_statterr RECORD LIKE statterr.* ## previous year 
	DEFINE l_arr_rec_statterr DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		gross_amt LIKE statterr.gross_amt, 
		net_amt LIKE statterr.net_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statterr.net_amt, 
		prv_disc_per FLOAT, 
		var_gross_per LIKE statterr.gross_amt, 
		var_net_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_gross_amt LIKE statterr.gross_amt, 
		tot_net_amt LIKE statterr.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statterr.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_gross_per LIKE statterr.gross_amt, 
		tot_var_net_per FLOAT 
	END RECORD 
	DEFINE l_arr_totprvgross_amt array[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36
	 
	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1"
	 
	SELECT * INTO l_rec_territory.* 
	FROM territory 
	WHERE cmpy_code = p_cmpy_code 
	AND terr_code = p_terr_code
	 
	IF status = 0 THEN 
		OPEN WINDOW E250 with FORM "E250" 
		 CALL windecoration_e("E250") -- albo kd-755
 
		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY BY NAME l_rec_territory.terr_code
			DISPLAY BY NAME l_rec_territory.desc_text 

			LET i = l_rec_statparms.year_num - 1
			 
			DISPLAY l_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY i TO sr_year[2].year_num 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_gross_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_gross_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
				LET l_arr_totprvgross_amt[i] = 0 
			END FOR
			 
			DECLARE c_statint cursor FOR 
			
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = l_rec_statparms.year_num 
			AND type_code = l_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 
			LET l_idx = 0
			 
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statterr[l_idx].int_text = l_rec_statint.int_text 
				
				## obtain current year gross,net AND disc%
				SELECT * INTO l_rec_cur_statterr.* 
				FROM statterr 
				WHERE cmpy_code = p_cmpy_code 
				AND terr_code = p_terr_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statterr.gross_amt = 0 
					LET l_rec_cur_statterr.net_amt = 0 
				END IF
				 
				LET l_arr_rec_statterr[l_idx].gross_amt = l_rec_cur_statterr.gross_amt 
				LET l_arr_rec_statterr[l_idx].net_amt = l_rec_cur_statterr.net_amt
				 
				IF l_arr_rec_statterr[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statterr[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statterr[l_idx].disc_per = 100 *	(1-(l_arr_rec_statterr[l_idx].net_amt/l_arr_rec_statterr[l_idx].gross_amt)) 
				END IF
				 
				## obtain previous year gross,net AND disc%
				SELECT * INTO l_rec_prv_statterr.* 
				FROM statterr 
				WHERE cmpy_code = p_cmpy_code 
				AND terr_code = p_terr_code 
				AND year_num = l_rec_statparms.year_num - 1 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statterr.gross_amt = 0 
					LET l_rec_prv_statterr.net_amt = 0 
				END IF 
				
				LET l_arr_rec_statterr[l_idx].prv_net_amt = l_rec_prv_statterr.net_amt 
				IF l_rec_prv_statterr.gross_amt = 0 THEN 
					LET l_arr_rec_statterr[l_idx].prv_disc_per = 0 
					LET l_arr_rec_statterr[l_idx].var_gross_per = 0 
				ELSE 
					LET l_arr_rec_statterr[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statterr[l_idx].prv_net_amt/l_rec_prv_statterr.gross_amt)) 
					LET l_arr_rec_statterr[l_idx].var_gross_per = 100 *(l_arr_rec_statterr[l_idx].gross_amt-l_rec_prv_statterr.gross_amt)	/ l_rec_prv_statterr.gross_amt 
				END IF 
				IF l_rec_prv_statterr.net_amt = 0 THEN 
					LET l_arr_rec_statterr[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statterr[l_idx].var_net_per = 100 
					* (l_arr_rec_statterr[l_idx].net_amt - l_arr_rec_statterr[l_idx].prv_net_amt) / l_arr_rec_statterr[l_idx].prv_net_amt 
				END IF
				 
				## increment totals
				LET l_arr_rec_stattotal[1].tot_gross_amt = l_arr_rec_stattotal[1].tot_gross_amt	+ l_rec_cur_statterr.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statterr.net_amt 
				LET l_arr_totprvgross_amt[1] = l_arr_totprvgross_amt[1] + l_rec_prv_statterr.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statterr.net_amt 
				IF l_rec_statint.int_num <= l_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_gross_amt = l_arr_rec_stattotal[2].tot_gross_amt	+ l_rec_cur_statterr.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statterr.net_amt 
					LET l_arr_totprvgross_amt[2] = l_arr_totprvgross_amt[2] + l_rec_prv_statterr.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statterr.net_amt 
				END IF 
			END FOREACH 
			
			IF l_idx = 0 THEN 
				CALL fgl_winmessage("ERROR",kandoomsg2("E",7086,""),"ERROR") 			#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
				
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_gross_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt /l_arr_rec_stattotal[i].tot_gross_amt)) 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_totprvgross_amt[i])) 
					END IF 
					
					# calc total current & previous year net & gross variance
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per =	100 * ( l_arr_rec_stattotal[i].tot_net_amt 
						- l_arr_rec_stattotal[i].tot_prv_net_amt) 	/ l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_gross_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_gross_per = 
						100 * (l_arr_rec_stattotal[i].tot_gross_amt-l_arr_totprvgross_amt[i])	/ l_arr_totprvgross_amt[i] 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
				
				MESSAGE kandoomsg2("E",1117,"")		#1117 " Sales Territory Monthly Turnover - F9 Previous - F10 Next

				CALL set_count(l_idx) 
				INPUT ARRAY l_arr_rec_statterr WITHOUT DEFAULTS FROM sr_statterr.* 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","EE2","input-arr-l_arr_rec_statterr-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
						EXIT INPUT 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
						EXIT INPUT 

				END INPUT 
			END IF

			IF fgl_lastaction() = "year-1" OR fgl_lastaction() = "year+1" THEN
				CALL l_arr_rec_statterr.clear()
			ELSE 
				EXIT WHILE 
			END IF 
						 
		END WHILE 

		CLOSE WINDOW E250
		
	END IF
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE
END FUNCTION 
###########################################################################
# END FUNCTION terr_turnover(p_cmpy_code,p_terr_code)
###########################################################################