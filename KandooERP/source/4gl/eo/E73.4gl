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
GLOBALS "../eo/E7_GROUP_GLOBALS.4gl"
GLOBALS "../eo/E73_GLOBALS.4gl"
###########################################################################
# FUNCTION E73_main()
#
# E73 - allows users TO SELECT a sales condition TO peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION E73_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("E73")  

	LET glob_yes_flag = xlate_from("Y") 
	LET glob_no_flag = xlate_from("N") 
	
	OPEN WINDOW E257 with FORM "E257" 
	 CALL windecoration_e("E257")

	CALL scan_condsale() 
	 
	CLOSE WINDOW E257
	 
END FUNCTION 
###########################################################################
# END FUNCTION E73_main()
###########################################################################


###########################################################################
# FUNCTION db_condsale_get_datasource(p_filter)
#
# E73 - allows users TO SELECT a sales condition TO peruse
#       turnover information FROM statistics tables.
###########################################################################
FUNCTION db_condsale_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		scheme_amt LIKE condsale.scheme_amt, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT
	
	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") #" Enter Selection Criteria - ESC TO Continue "
		CONSTRUCT BY NAME l_where_text ON 
			cond_code, 
			desc_text, 
			scheme_amt, 
			prodline_disc_flag 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","E73","construct-cond_code-1") -- albo kd-502 
	
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
	
	MESSAGE kandoomsg2("E",1002,"") #MESSAGE " Searching database - please wait "
	LET l_query_text = "SELECT * ", 
	"FROM condsale ", 
	"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY cmpy_code,", 
	"cond_code" 
	PREPARE s_condsale FROM l_query_text 
	DECLARE c_condsale cursor FOR s_condsale 

	LET l_idx = 0 
	FOREACH c_condsale INTO glob_rec_condsale.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_condsale[l_idx].scroll_flag = NULL 
		LET l_arr_rec_condsale[l_idx].cond_code = glob_rec_condsale.cond_code 
		LET l_arr_rec_condsale[l_idx].desc_text = glob_rec_condsale.desc_text 
		LET l_arr_rec_condsale[l_idx].scheme_amt = glob_rec_condsale.scheme_amt 
		LET l_arr_rec_condsale[l_idx].prodline_disc_flag =	xlate_from(glob_rec_condsale.prodline_disc_flag) 

		SELECT unique 1 FROM statcond 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cond_code = glob_rec_condsale.cond_code 

		IF status = 0 THEN 
			LET l_arr_rec_condsale[l_idx].stat_flag = "*" 
		ELSE 
			LET l_arr_rec_condsale[l_idx].stat_flag = NULL 
		END IF 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 

	IF l_idx = 0 THEN 
		MESSAGE kandoomsg2("E",9036,"") 	#9036 No Sales Conditions Satisfied Selection Criteria "
	ELSE
		MESSAGE l_idx clipped, "conditions selected"
	END IF 	

	RETURN l_arr_rec_condsale 
END FUNCTION 
###########################################################################
# END FUNCTION db_condsale_get_datasource(p_filter)
###########################################################################


###########################################################################
# FUNCTION scan_condsale() 
#
# 
###########################################################################
FUNCTION scan_condsale() 
	DEFINE l_cond_code LIKE condsale.cond_code 
	DEFINE l_scroll_flag char(1) 
	DEFINE l_arr_rec_condsale DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		cond_code LIKE condsale.cond_code, 
		desc_text LIKE condsale.desc_text, 
		scheme_amt LIKE condsale.scheme_amt, 
		prodline_disc_flag LIKE condsale.prodline_disc_flag, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_err_continue char(1) 
	DEFINE l_err_message char(60) 
	DEFINE i SMALLINT
	DEFINE j SMALLINT
	DEFINE l_del_cnt SMALLINT
	DEFINE l_idx SMALLINT

	CALL db_condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale
	
	MESSAGE kandoomsg2("E",1151,"") #1151 " Sales Condition Monthly Turnover - RETURN TO View "
	DISPLAY ARRAY l_arr_rec_condsale TO sr_condsale.*
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","E73","input-arr-l_arr_rec_condsale-1") 
 			CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_condsale.getSize())
 			
		ON ACTION "WEB-HELP"
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_condsale.clear()
			CALL db_condsale_get_datasource(TRUE) RETURNING l_arr_rec_condsale

		ON ACTION "REFRESH"
			 CALL windecoration_e("E257")
			CALL l_arr_rec_condsale.clear()
			CALL db_condsale_get_datasource(FALSE) RETURNING l_arr_rec_condsale
							
		BEFORE ROW 
			LET l_idx = arr_curr() 
			LET l_scroll_flag = l_arr_rec_condsale[l_idx].scroll_flag 
			
		ON ACTION ("ACCEPT","DOUBLECLICK") 
			IF l_idx > 0 THEN 
				CALL cond_turnover(glob_rec_kandoouser.cmpy_code,l_arr_rec_condsale[l_idx].cond_code) 
			END IF
			 
	END DISPLAY 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_condsale() 
###########################################################################


###########################################################################
# FUNCTION cond_turnover(p_cmpy_code,p_cond_code) 
#
# 
###########################################################################
FUNCTION cond_turnover(p_cmpy_code,p_cond_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_cond_code LIKE condsale.cond_code 
	DEFINE l_rec_condsale RECORD LIKE condsale.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statcond RECORD LIKE statcond.* ## CURRENT year 
	DEFINE l_rec_prv_statcond RECORD LIKE statcond.* ## previous year 
	DEFINE l_arr_rec_statcond DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		gross_amt LIKE statcond.gross_amt, 
		net_amt LIKE statcond.net_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statcond.net_amt, 
		prv_disc_per FLOAT, 
		var_gross_per LIKE statcond.gross_amt, 
		var_net_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_stattotal ARRAY[2] OF RECORD 
		tot_gross_amt LIKE statcond.gross_amt, 
		tot_net_amt LIKE statcond.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statcond.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_gross_per LIKE statcond.gross_amt, 
		tot_var_net_per FLOAT 
	END RECORD 
	DEFINE l_arr_totprvgross_amt ARRAY[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_condsale.* 
	FROM condsale 
	WHERE cmpy_code = p_cmpy_code 
	AND cond_code = p_cond_code 
	
	IF status = 0 THEN 
		OPEN WINDOW E258 with FORM "E258" 
		 CALL windecoration_e("E258") -- albo kd-755 

		WHILE TRUE 
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY BY NAME 
				l_rec_condsale.cond_code, 
				l_rec_condsale.desc_text 

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
				LET l_arr_rec_statcond[l_idx].int_text = l_rec_statint.int_text 
				## obtain current year gross,net AND disc%
				SELECT sum(gross_amt),sum(net_amt) 
				INTO l_rec_cur_statcond.gross_amt,l_rec_cur_statcond.net_amt 
				FROM statcond 
				WHERE cmpy_code = p_cmpy_code 
				AND cond_code = p_cond_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 

				IF l_rec_cur_statcond.gross_amt IS NULL THEN 
					LET l_rec_cur_statcond.gross_amt = 0 
				END IF 
				IF l_rec_cur_statcond.net_amt IS NULL THEN 
					LET l_rec_cur_statcond.net_amt = 0 
				END IF 
				LET l_arr_rec_statcond[l_idx].gross_amt = l_rec_cur_statcond.gross_amt 
				LET l_arr_rec_statcond[l_idx].net_amt = l_rec_cur_statcond.net_amt 
				IF l_arr_rec_statcond[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statcond[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statcond[l_idx].disc_per = 100 * 
					(1-(l_arr_rec_statcond[l_idx].net_amt/l_arr_rec_statcond[l_idx].gross_amt)) 
				END IF 

				## obtain previous year gross,net AND disc%
				SELECT sum(gross_amt),sum(net_amt) 
				INTO l_rec_prv_statcond.gross_amt,l_rec_prv_statcond.net_amt 
				FROM statcond 
				WHERE cmpy_code = p_cmpy_code 
				AND cond_code = p_cond_code 
				AND year_num = l_rec_statparms.year_num - 1 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 

				IF l_rec_prv_statcond.gross_amt IS NULL THEN 
					LET l_rec_prv_statcond.gross_amt = 0 
				END IF 
				IF l_rec_prv_statcond.net_amt IS NULL THEN 
					LET l_rec_prv_statcond.net_amt = 0 
				END IF 

				LET l_arr_rec_statcond[l_idx].prv_net_amt = l_rec_prv_statcond.net_amt 
				IF l_rec_prv_statcond.gross_amt = 0 THEN 
					LET l_arr_rec_statcond[l_idx].prv_disc_per = 0 
					LET l_arr_rec_statcond[l_idx].var_gross_per = 0 
				ELSE 
					LET l_arr_rec_statcond[l_idx].prv_disc_per = 100	*(1-(l_arr_rec_statcond[l_idx].prv_net_amt/l_rec_prv_statcond.gross_amt)) 
					LET l_arr_rec_statcond[l_idx].var_gross_per = 100 *(l_arr_rec_statcond[l_idx].gross_amt-l_rec_prv_statcond.gross_amt)/ l_rec_prv_statcond.gross_amt 
				END IF 
				IF l_rec_prv_statcond.net_amt = 0 THEN 
					LET l_arr_rec_statcond[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statcond[l_idx].var_net_per = 100 * (l_arr_rec_statcond[l_idx].net_amt 
					-l_arr_rec_statcond[l_idx].prv_net_amt) / l_arr_rec_statcond[l_idx].prv_net_amt 
				END IF
				 
				## increment totals
				LET l_arr_rec_stattotal[1].tot_gross_amt = l_arr_rec_stattotal[1].tot_gross_amt + l_rec_cur_statcond.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statcond.net_amt 
				LET l_arr_totprvgross_amt[1] = l_arr_totprvgross_amt[1] + l_rec_prv_statcond.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = 	l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statcond.net_amt 
				IF l_rec_statint.int_num <= l_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_gross_amt = l_arr_rec_stattotal[2].tot_gross_amt	+ l_rec_cur_statcond.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt	+ l_rec_cur_statcond.net_amt 
					LET l_arr_totprvgross_amt[2] = l_arr_totprvgross_amt[2] + l_rec_prv_statcond.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = 
					l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statcond.net_amt 
				END IF 
			END FOREACH
			 
			IF l_idx = 0 THEN 
				CALL fgl_winmessage("#7086 No statistical information",kandoomsg2("E",7086,""),"ERROR") 		#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
			
				FOR i = 1 TO 2 
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_gross_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_net_amt 
						/l_arr_rec_stattotal[i].tot_gross_amt)) 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_totprvgross_amt[i])) 
					END IF 
					# calc total current & previous year net & gross variance
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 
						100 * ( l_arr_rec_stattotal[i].tot_net_amt 
						- l_arr_rec_stattotal[i].tot_prv_net_amt) 
						/ l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					IF l_arr_totprvgross_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_gross_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_gross_per = 
						100 * (l_arr_rec_stattotal[i].tot_gross_amt-l_arr_totprvgross_amt[i])		/ l_arr_totprvgross_amt[i] 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

--				OPTIONS INSERT KEY f36, 
--				DELETE KEY f36 

				MESSAGE kandoomsg2("E",1152,"") 				#1152 " Sales Condition Monthly Turnover - F9 Previous - F10 Next 
 
				INPUT ARRAY l_arr_rec_statcond WITHOUT DEFAULTS FROM sr_statcond.* 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","E73","input-arr-l_arr_rec_statcond-1") -- albo kd-502 

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
			 
			IF fgl_lastkey() = fgl_keyval("F9") 
			OR fgl_lastkey() = fgl_keyval("F10") THEN 
				FOR i = 1 TO arr_count() 
					INITIALIZE l_arr_rec_statcond[i].* TO NULL 
				END FOR 
			ELSE 
				EXIT WHILE 
			END IF 
		END WHILE 
		
		CLOSE WINDOW E258 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION scan_condsale() 
###########################################################################