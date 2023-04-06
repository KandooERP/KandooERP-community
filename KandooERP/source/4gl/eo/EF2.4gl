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
GLOBALS "../eo/EF_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EF2_GLOBALS.4gl"
###########################################################################
# FUNCTION EF2_main()
#
# EF2 - allows users TO SELECT a sales area TO peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION EF2_main() 
	DEFINE l_arg_area_code LIKE salearea.area_code 
	
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EF2") -- albo 
	
	#Argument
	LET l_arg_area_code = get_url_area_code()	 
	IF l_arg_area_code IS NOT NULL THEN 
		CALL area_turnover(glob_rec_kandoouser.cmpy_code,l_arg_area_code) 
	ELSE 
		OPEN WINDOW E240 with FORM "E240" 
		 CALL windecoration_e("E240") -- albo kd-755 

		CALL scan_area() 
	
		CLOSE WINDOW E240 
	END IF 
	
END FUNCTION
###########################################################################
# END FUNCTION EF2_main()
###########################################################################


###########################################################################
# FUNCTION salearea_get_datasource(p_filter)
#
#
###########################################################################
FUNCTION salearea_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		ERROR kandoomsg2("A",1001,"") #1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON area_code, desc_text 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EF2","construct-area_code-1") -- albo kd-502 
	
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
		"SELECT * FROM salearea ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"area_code" 
	
	PREPARE s_salearea FROM l_query_text 
	DECLARE c_salearea cursor FOR s_salearea 
		
	LET l_idx = 0 

	FOREACH c_salearea INTO l_rec_salearea.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_salearea[l_idx].scroll_flag = NULL 
		LET l_arr_rec_salearea[l_idx].area_code = l_rec_salearea.area_code 
		LET l_arr_rec_salearea[l_idx].desc_text = l_rec_salearea.desc_text
		 
		SELECT unique 1 FROM statterr 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND area_code = l_rec_salearea.area_code 
		IF status = 0 THEN 
			LET l_arr_rec_salearea[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_salearea[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF		
	END FOREACH 
	
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9086,"") 
	END IF 

	RETURN l_arr_rec_salearea 
END FUNCTION 
###########################################################################
# END FUNCTION salearea_get_datasource()
###########################################################################


###########################################################################
# FUNCTION scan_area()
#
#
###########################################################################
FUNCTION scan_area() 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
	DEFINE l_arr_rec_salearea DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		area_code LIKE salearea.area_code, 
		desc_text LIKE salearea.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	
	CALL salearea_get_datasource(FALSE) RETURNING l_arr_rec_salearea
	
	ERROR kandoomsg2("E",1107,"") #1107 " Sales Area Monthly Turnover - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_salearea TO sr_salearea.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EF2","input-arr-l_arr_rec_salearea-1") -- albo kd-502 
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_salearea.clear()
			CALL salearea_get_datasource(TRUE) RETURNING l_arr_rec_salearea
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())
				
		ON ACTION "RERESH"
			 CALL windecoration_e("E240")
			CALL l_arr_rec_salearea.clear()
			CALL salearea_get_datasource(FALSE) RETURNING l_arr_rec_salearea
			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_salearea.getSize())

		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD area_code
			IF (l_idx > 0) AND (l_idx <= l_arr_rec_salearea.getSize()) THEN 
				CALL area_turnover(glob_rec_kandoouser.cmpy_code, l_arr_rec_salearea[l_idx].area_code)
			END IF 

		BEFORE ROW 
			LET l_idx = arr_curr() 

	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

END FUNCTION 
###########################################################################
# END FUNCTION scan_area()
###########################################################################


###########################################################################
# FUNCTION area_turnover(p_cmpy_code,p_area_code)
#
#
###########################################################################
FUNCTION area_turnover(p_cmpy_code,p_area_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_area_code LIKE salearea.area_code 
	DEFINE l_rec_salearea RECORD LIKE salearea.* 
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
	DEFINE l_arr_rec_stattotal_2 array[2] OF RECORD 
		tot_gross_amt LIKE statterr.gross_amt, 
		tot_net_amt LIKE statterr.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statterr.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_gross_per LIKE statterr.gross_amt, 
		tot_var_net_per FLOAT 
	END RECORD 
	DEFINE l_arr_totprvgross_amt array[2] OF decimal(16,2) # 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	SELECT * INTO l_rec_salearea.* 
	FROM salearea 
	WHERE cmpy_code = p_cmpy_code 
	AND area_code = p_area_code 

	IF status = 0 THEN 
		OPEN WINDOW E242 with FORM "E242" 
		 CALL windecoration_e("E242") -- albo kd-755 

		WHILE TRUE 
			ERROR kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY BY NAME l_rec_salearea.area_code 
			DISPLAY BY NAME l_rec_salearea.desc_text 

			LET i = glob_rec_statparms.year_num - 1 
			DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY i TO sr_year[2].year_num 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal_2[i].tot_gross_amt = 0 
				LET l_arr_rec_stattotal_2[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal_2[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal_2[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal_2[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal_2[i].tot_var_gross_per = 0 
				LET l_arr_rec_stattotal_2[i].tot_var_net_per = 0 
				LET l_arr_totprvgross_amt[i] = 0 
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
				LET l_arr_rec_statterr[l_idx].int_text = l_rec_statint.int_text 
				
				#--------------------------------------------
				# obtain current year gross,net AND disc%
				SELECT * INTO l_rec_cur_statterr.* 
				FROM statterr 
				WHERE cmpy_code = p_cmpy_code 
				AND area_code = p_area_code 
				AND terr_code IS NULL 
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
					LET l_arr_rec_statterr[l_idx].disc_per = 100 * (1-(l_arr_rec_statterr[l_idx].net_amt/l_arr_rec_statterr[l_idx].gross_amt)) 
				END IF 

				#--------------------------------------------
				# obtain previous year gross,net AND disc%
				SELECT * INTO l_rec_prv_statterr.* 
				FROM statterr 
				WHERE cmpy_code = p_cmpy_code 
				AND area_code = p_area_code 
				AND terr_code IS NULL 
				AND year_num = glob_rec_statparms.year_num - 1 
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
					LET l_arr_rec_statterr[l_idx].var_gross_per = 100 *(l_arr_rec_statterr[l_idx].gross_amt-l_rec_prv_statterr.gross_amt) / l_rec_prv_statterr.gross_amt 
				END IF 

				IF l_rec_prv_statterr.net_amt = 0 THEN 
					LET l_arr_rec_statterr[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statterr[l_idx].var_net_per = 100 * (l_arr_rec_statterr[l_idx].net_amt 
					-l_arr_rec_statterr[l_idx].prv_net_amt) / l_arr_rec_statterr[l_idx].prv_net_amt 
				END IF 

				#--------------------------------------------
				# increment totals
				LET l_arr_rec_stattotal_2[1].tot_gross_amt = l_arr_rec_stattotal_2[1].tot_gross_amt +  l_rec_cur_statterr.gross_amt 
				LET l_arr_rec_stattotal_2[1].tot_net_amt = l_arr_rec_stattotal_2[1].tot_net_amt + l_rec_cur_statterr.net_amt 
				LET l_arr_totprvgross_amt[1] = l_arr_totprvgross_amt[1] + l_rec_prv_statterr.gross_amt 
				LET l_arr_rec_stattotal_2[1].tot_prv_net_amt = l_arr_rec_stattotal_2[1].tot_prv_net_amt + l_rec_prv_statterr.net_amt 
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal_2[2].tot_gross_amt = l_arr_rec_stattotal_2[2].tot_gross_amt + l_rec_cur_statterr.gross_amt 
					LET l_arr_rec_stattotal_2[2].tot_net_amt = l_arr_rec_stattotal_2[2].tot_net_amt + l_rec_cur_statterr.net_amt 
					LET l_arr_totprvgross_amt[2] = l_arr_totprvgross_amt[2] + l_rec_prv_statterr.gross_amt 
					LET l_arr_rec_stattotal_2[2].tot_prv_net_amt = l_arr_rec_stattotal_2[2].tot_prv_net_amt + l_rec_prv_statterr.net_amt 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				CALL fgl_winmessage("ERROR",kandoomsg2("E",7086,""),"ERROR") #7086 No statistical information exists FOR this selection "
				CLOSE WINDOW E242 
				RETURN --EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 

					#--------------------------------------------
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal_2[i].tot_gross_amt = 0 THEN 
						LET l_arr_rec_stattotal_2[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal_2[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal_2[i].tot_net_amt /l_arr_rec_stattotal_2[i].tot_gross_amt)) 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal_2[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal_2[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal_2[i].tot_prv_net_amt/l_arr_totprvgross_amt[i])) 
					END IF 

					#--------------------------------------------
					# calc total current & previous year net & gross variance
					IF l_arr_rec_stattotal_2[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal_2[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal_2[i].tot_var_net_per =	100 * ( l_arr_rec_stattotal_2[i].tot_net_amt 
						- l_arr_rec_stattotal_2[i].tot_prv_net_amt) / l_arr_rec_stattotal_2[i].tot_prv_net_amt 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal_2[i].tot_var_gross_per = 0 
					ELSE 
						LET l_arr_rec_stattotal_2[i].tot_var_gross_per = 
						100 * (l_arr_rec_stattotal_2[i].tot_gross_amt-l_arr_totprvgross_amt[i]) / l_arr_totprvgross_amt[i] 
					END IF 
					DISPLAY l_arr_rec_stattotal_2[i].* TO sr_stattotal[i].* 

				END FOR 
				
				MESSAGE kandoomsg2("E",1130,"") 	#1108 " Sales Area Monthly Turnover - F9 Previous - F10 Next Year
				CALL set_count(l_idx) 
				DISPLAY ARRAY l_arr_rec_statterr TO sr_statterr.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EF2","input-arr-l_arr_rec_statterr-1") -- albo kd-502 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
						FOR i = 1 TO arr_count() 
							INITIALIZE l_arr_rec_statterr[i].* TO NULL 
						END FOR 
						EXIT DISPLAY 
						
					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
						FOR i = 1 TO arr_count() 
							INITIALIZE l_arr_rec_statterr[i].* TO NULL 
						END FOR 
						EXIT DISPLAY
						 
				END DISPLAY 

			END IF 

			IF int_flag THEN
				EXIT WHILE
			END IF
		
		END WHILE 
		CLOSE WINDOW E242 
	END IF
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION area_turnover(p_cmpy_code,p_area_code)
###########################################################################