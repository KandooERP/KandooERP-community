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
GLOBALS "../eo/EG5_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_temp_text STRING 
 
###########################################################################
# FUNCTION EG5_main()
#
# EG5 - allows users TO SELECT salesperson types TO peruse
#       company profit information FROM statistics tables.
###########################################################################
FUNCTION EG5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EG5") -- albo 

	OPEN WINDOW E261 with FORM "E261" 
	 CALL windecoration_e("E261") -- albo kd-755 

	WHILE select_sper_type() 
		CALL company_profit(glob_rec_kandoouser.cmpy_code,modu_temp_text) 
	END WHILE 

	CLOSE WINDOW E261 
END FUNCTION 
###########################################################################
# END FUNCTION EG5_main() 
###########################################################################


###########################################################################
# FUNCTION select_sper_type()
#
#
###########################################################################
FUNCTION select_sper_type() 
	DEFINE l_pseudo_flag char(1) 
	DEFINE l_primary_flag char(1) 
	DEFINE l_normal_flag char(1) 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("E",1141,"") #1141 Company Profit Figures - F9 TO toggle - ESC TO Continue
	 
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
	INPUT 
		l_pseudo_flag, 
		l_primary_flag, 
		l_normal_flag WITHOUT DEFAULTS 
	FROM
		pseudo_flag, 
		primary_flag, 
		normal_flag ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","EG5","input-l_pseudo_flag-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

{

	#textField got replaced with checkBox

		ON KEY (f9) infield(pseudo_flag) 
					IF l_pseudo_flag IS NULL THEN 
						LET l_pseudo_flag = "*" 
					ELSE 
						LET l_pseudo_flag = NULL 
					END IF 
					DISPLAY l_pseudo_flag TO pseudo_flag

					NEXT FIELD NEXT 

		ON KEY (f9) infield(primary_flag) 
					IF l_primary_flag IS NULL THEN 
						LET l_primary_flag = "*" 
					ELSE 
						LET l_primary_flag = NULL 
					END IF 
					DISPLAY l_primary_flag TO primary_flag 
					NEXT FIELD NEXT 

		ON KEY (f9) infield(normal_flag) 
					IF l_normal_flag IS NULL THEN 
						LET l_normal_flag = "*" 
					ELSE 
						LET l_normal_flag = NULL 
					END IF 
					DISPLAY l_normal_flag TO normal_flag  
					NEXT FIELD pseudo_flag 
}

		AFTER INPUT
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_primary_flag IS NULL 
				AND l_pseudo_flag IS NULL 
				AND l_normal_flag IS NULL THEN 
					ERROR kandoomsg2("E",1132,"") 				#1132 All Salesperson Types have been excluded "
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
				LET l_where_text = "salesperson.sale_type_ind in (", 
				l_where_text clipped,")" 
			END IF 
			
	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		LET modu_temp_text = l_where_text 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_sper_type()
###########################################################################


###########################################################################
# FUNCTION company_profit(p_cmpy_code,p_where_text)
#
#
###########################################################################
FUNCTION company_profit(p_cmpy_code,p_where_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	DEFINE l_rec_prv_statsper RECORD LIKE statsper.* ## previous year 
	DEFINE l_arr_rec_statsper array[100] OF RECORD 
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
	DEFINE l_arr_totcurgrs_amt array[2] OF decimal(16,2)# CURRENT "" "" ""	# 1->Total    2->YTD
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy_code
	 
	IF status = 0 THEN 
		OPEN WINDOW E263 with FORM "E263" 
		 CALL windecoration_e("E263") -- albo kd-755
 
		LET l_query_text = 
			"SELECT sum(grs_amt),sum(net_amt),sum(cost_amt) ", 
			" FROM statsper, salesperson", 
			" WHERE statsper.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.sale_code = statsper.sale_code", 
			" AND statsper.year_num = ? ", 
			" AND statsper.type_code = ? ", 
			" AND statsper.int_num = ? ", 
			" AND ",p_where_text clipped
		 
		PREPARE s_statsper FROM l_query_text 
		DECLARE c_statsper cursor FOR s_statsper 

		WHILE TRUE 
			CALL l_arr_rec_statsper.clear()  #clear/init main array
			
			MESSAGE kandoomsg2("E",1002,"") 
			CLEAR FORM 
			
			DISPLAY l_rec_company.cmpy_code TO cmpy_code 
			DISPLAY l_rec_company.name_text TO name_text

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
				OPEN c_statsper USING l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
				FETCH c_statsper INTO l_rec_cur_statsper.grs_amt, 
				l_rec_cur_statsper.net_amt, 
				l_rec_cur_statsper.cost_amt 
				
				IF l_rec_cur_statsper.grs_amt IS NULL THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
				END IF 
				
				IF l_rec_cur_statsper.net_amt IS NULL THEN 
					LET l_rec_cur_statsper.net_amt = 0 
				END IF 
				
				IF l_rec_cur_statsper.cost_amt IS NULL THEN 
					LET l_rec_cur_statsper.cost_amt = 0 
				END IF 
			
				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt 
				LET l_arr_rec_statsper[l_idx].prof_amt = l_rec_cur_statsper.net_amt - l_rec_cur_statsper.cost_amt 
			
				IF l_rec_cur_statsper.grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 100 * (1-(l_rec_cur_statsper.net_amt/l_rec_cur_statsper.grs_amt)) 
				END IF 
				LET i = l_rec_statint.year_num - 1 
				
				## obtain previous year grs,net AND disc%
				OPEN c_statsper USING i, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
				FETCH c_statsper INTO l_rec_prv_statsper.grs_amt, 
				l_rec_prv_statsper.net_amt, 
				l_rec_prv_statsper.cost_amt 
				IF l_rec_prv_statsper.grs_amt IS NULL THEN 
					LET l_rec_prv_statsper.grs_amt = 0 
				END IF 
				IF l_rec_prv_statsper.net_amt IS NULL THEN 
					LET l_rec_prv_statsper.net_amt = 0 
				END IF 
				IF l_rec_prv_statsper.cost_amt IS NULL THEN 
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

				IF l_idx = 100 THEN 
					EXIT FOREACH 
				END IF 

			END FOREACH 

			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") 			#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
				
					# calc total current & previous year disc%
					IF l_arr_totcurgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt / l_arr_totcurgrs_amt[i])) 
					END IF 
					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_prv_net_amt / l_arr_totprvgrs_amt[i])) 
					END IF 
					
					# calc profit variance
					IF l_arr_rec_stattotal[i].tot_prv_prof_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_prof_per = 
						100 * ( l_arr_rec_stattotal[i].tot_prof_amt - l_arr_rec_stattotal[i].tot_prv_prof_amt) / l_arr_rec_stattotal[i].tot_prv_prof_amt 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1142,"") 	#1142 Company Profit Figures - F9 Prev - F10 Next
				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EG5","input-l_arr_rec_statsper-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
						--FOR i = 1 TO arr_count() 
						--	INITIALIZE l_arr_rec_statsper[i].* TO NULL 
						--END FOR 						
						EXIT DISPLAY 

					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
						--FOR i = 1 TO arr_count() 
						--	INITIALIZE l_arr_rec_statsper[i].* TO NULL 
						--END FOR 						
						EXIT DISPLAY 
						
				END DISPLAY 

			END IF 

			EXIT WHILE 
 
		END WHILE 
		
		CLOSE WINDOW E263 
		
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
	
END FUNCTION 
###########################################################################
# END FUNCTION company_profit(p_cmpy_code,p_where_text)
###########################################################################