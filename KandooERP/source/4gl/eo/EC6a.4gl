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
GLOBALS "../eo/EC6_GLOBALS.4gl"

###########################################################################
# FUNCTION sper_targets(p_cmpy,l_sale_code,l_rec_year_num) 
#
#
###########################################################################
FUNCTION sper_targets(p_cmpy,l_sale_code,l_rec_year_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE l_sale_code LIKE salesperson.sale_code 
	DEFINE l_rec_year_num LIKE statparms.year_num 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		disc_per FLOAT, 
		bdgt_amt LIKE stattarget.bdgt_amt, 
		achieve_per FLOAT 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_grs_amt LIKE statsper.grs_amt, 
		tot_net_amt LIKE statsper.net_amt, 
		tot_disc_per FLOAT, 
		tot_bdgt_amt LIKE stattarget.bdgt_amt, 
		tot_achieve_per FLOAT 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	
	IF l_rec_year_num IS NOT NULL THEN 
		
		#----------------------------------------------
		#ie year was passed FROM 'Sales Manager Turnover by Salesperson'
		LET glob_rec_statparms.year_num = l_rec_year_num 
	END IF 
	
	#get sales person record
	CALL db_salesperson_get_rec(UI_OFF,l_sale_code) RETURNING l_rec_salesperson.*		 

	IF l_rec_salesperson.sale_code IS NULL THEN 
		OPEN WINDOW E239 with FORM "E239" 
		 CALL windecoration_e("E239") -- albo kd-755
 
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
				LET l_arr_rec_stattotal[i].tot_bdgt_amt = 0 
				LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
			END FOR
			 
			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 
			LET l_idx = 0 
			
			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statsper[l_idx].int_text = l_rec_statint.int_text
				 
				#----------------------------------------------
				# obtain current year grs,net AND disc%
				SELECT sum(grs_amt), 
				sum(net_amt) 
				INTO 
					l_rec_cur_statsper.grs_amt, 
					l_rec_cur_statsper.net_amt 
				FROM statsper 
				WHERE cmpy_code = p_cmpy 
				AND sale_code = l_sale_code 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
					LET l_rec_cur_statsper.net_amt = 0 
				END IF
				 
				LET l_arr_rec_statsper[l_idx].grs_amt = l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt
				 
				IF l_arr_rec_statsper[l_idx].grs_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].disc_per = 100 * (1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
				END IF 
				
				SELECT bdgt_amt 
				INTO l_arr_rec_statsper[l_idx].bdgt_amt 
				FROM stattarget 
				WHERE cmpy_code = p_cmpy 
				AND bdgt_type_ind = "4" 
				AND bdgt_type_code = l_sale_code 
				AND bdgt_ind = "1" 
				AND year_num = l_rec_statint.year_num 
				AND type_code = l_rec_statint.type_code 
				AND int_num = l_rec_statint.int_num 
				
				IF l_arr_rec_statsper[l_idx].bdgt_amt IS NULL THEN 
					LET l_arr_rec_statsper[l_idx].bdgt_amt = 0 
				END IF 
				IF l_arr_rec_statsper[l_idx].bdgt_amt = 0 THEN 
					LET l_arr_rec_statsper[l_idx].achieve_per = 0 
				ELSE 
					LET l_arr_rec_statsper[l_idx].achieve_per = 100 * (l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].bdgt_amt) 
				END IF 
				
				#----------------------------------------------
				# increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statsper.net_amt 
				LET l_arr_rec_stattotal[1].tot_bdgt_amt = l_arr_rec_stattotal[1].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 
				
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statsper.grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statsper.net_amt 
					LET l_arr_rec_stattotal[2].tot_bdgt_amt = l_arr_rec_stattotal[2].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 
				END IF 

			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") 		#7086 No statistical information exists FOR this selection "
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 
					
					#----------------------------------------------
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt / l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					
					IF l_arr_rec_stattotal[i].tot_bdgt_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_achieve_per = 100 * (l_arr_rec_stattotal[i].tot_net_amt/l_arr_rec_stattotal[i].tot_bdgt_amt) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1105,"") 		#1105 RETURN TO View Weekly Targets - F9 Previous - F10 Next Year
				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EC6a","input-arr-l_arr_rec_statsper-1") -- albo kd-502
						CALL dialog.setActionHidden("ACCEPT",NOT l_arr_rec_statsper.getSize()) 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null) 

					BEFORE ROW 
						LET l_idx = arr_curr() 
					 
					ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD int_text 
						CALL sper_wtargets(p_cmpy,l_sale_code, glob_rec_statparms.year_num) 
						NEXT FIELD scroll_flag

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

		CLOSE WINDOW E239 
	END IF 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION sper_targets(p_cmpy,l_sale_code,l_rec_year_num) 
###########################################################################