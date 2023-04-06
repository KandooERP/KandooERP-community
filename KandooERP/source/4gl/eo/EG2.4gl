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
GLOBALS "../eo/EG2_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_temp_text char(50) 
###########################################################################
# FUNCTION EG2_main()
#
# EG2 - allows users TO SELECT salesperson types TO peruse
#       company targets information FROM statistics tables.
###########################################################################
FUNCTION EG2_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EG2") -- albo 

	OPEN WINDOW E261 with FORM "E261" 
	 CALL windecoration_e("E261") -- albo kd-755
 
--	WHILE select_sper_type() 
	CALL company_targets(glob_rec_kandoouser.cmpy_code) 
--	END WHILE
	 
	CLOSE WINDOW E261 
END FUNCTION 
###########################################################################
# END FUNCTION EG2_main()
###########################################################################


###########################################################################
# FUNCTION select_sper_type()
#
#
###########################################################################
FUNCTION select_sper_type(p_filter,p_cmpy_code)
	DEFINE p_filter BOOLEAN 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE modu_pseudo_flag char(1) 
	DEFINE modu_primary_flag char(1) 
	DEFINE modu_normal_flag char(1) 
	DEFINE l_where_text STRING
	DEFINE l_query_text STRING 
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
	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	DEFINE l_rec_statint RECORD LIKE statint.*
	DEFINE l_rec_company RECORD LIKE company.*
	DEFINE i SMALLINT
	DEFINE l_idx SMALLINT
	
	MESSAGE kandoomsg2("E",1135,"") #1135 Company Monthly Sales Vs Targets - F9 TO toggle - ESC TO Continue

	DISPLAY BY NAME 
		glob_rec_company.cmpy_code, 
		glob_rec_company.name_text, 
		glob_rec_company.addr1_text, 
		glob_rec_company.addr2_text, 
		glob_rec_company.city_text, 
		glob_rec_company.state_code, 
		glob_rec_company.post_code 

	LET modu_pseudo_flag = "*" 
	LET modu_primary_flag = "*" 
	LET modu_normal_flag = "*" 

	IF p_filter THEN
		INPUT 
			modu_pseudo_flag, 
			modu_primary_flag, 
			modu_normal_flag WITHOUT DEFAULTS
		FROM
			pseudo_flag, 
			primary_flag, 
			normal_flag ATTRIBUTE(UNBUFFERED)
		 
	
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","EG2","input-modu_pseudo_flag-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
{

	#textField got replaced with checkBox

		ON KEY (f9) infield(pseudo_flag) 
					IF modu_pseudo_flag IS NULL THEN 
						LET modu_pseudo_flag = "*" 
					ELSE 
						LET modu_pseudo_flag = NULL 
					END IF 
					DISPLAY modu_pseudo_flag TO pseudo_flag

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(primary_flag) 
					IF modu_primary_flag IS NULL THEN 
						LET modu_primary_flag = "*" 
					ELSE 
						LET modu_primary_flag = NULL 
					END IF 
					DISPLAY modu_primary_flag TO primary_flag

					NEXT FIELD NEXT
					 
		ON KEY (f9) infield(normal_flag) 
					IF modu_normal_flag IS NULL THEN 
						LET modu_normal_flag = "*" 
					ELSE 
						LET modu_normal_flag = NULL 
					END IF 
					DISPLAY modu_normal_flag TO normal_flag

					NEXT FIELD pseudo_flag 
 }
			AFTER INPUT 
				IF NOT (int_flag OR quit_flag) THEN 
					IF modu_primary_flag IS NULL 
					AND modu_pseudo_flag IS NULL 
					AND modu_normal_flag IS NULL THEN 
						ERROR kandoomsg2("E",1132,"") 		#1132 All Salesperson Types have been excluded "
						NEXT FIELD NEXT 
					END IF 
				END IF 
	
		END INPUT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET modu_pseudo_flag = "*"
			LET modu_primary_flag = "*"
			LET modu_normal_flag = "*"
		END IF
	ELSE
			LET modu_pseudo_flag = "*"
			LET modu_primary_flag = "*"
			LET modu_normal_flag = "*"
	END IF

	IF modu_pseudo_flag = "*" THEN 
		LET l_where_text = " '1'" 
	END IF 
	IF modu_primary_flag = "*" THEN 
		LET l_where_text = l_where_text clipped,",'2'" 
	END IF 
	IF modu_normal_flag = "*" THEN 
		LET l_where_text = l_where_text clipped,",'3'" 
	END IF 
	
	LET l_where_text[1,1] = " " 
	LET l_where_text = "salesperson.sale_type_ind in (", l_where_text clipped,")"  

	--LET modu_temp_text = l_where_text
			
	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy_code 
	IF status = 0 THEN 
		OPEN WINDOW E264 with FORM "E264" 
		 CALL windecoration_e("E264") -- albo kd-755 
		LET l_query_text = 
			"SELECT sum(grs_amt),sum(net_amt) FROM statsper, salesperson", 
			" WHERE statsper.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.sale_code = statsper.sale_code", 
			" AND statsper.year_num = ? ", 
			" AND statsper.type_code = ? ", 
			" AND statsper.int_num = ? ", 
			" AND ",l_where_text clipped 
		PREPARE s_statsper FROM l_query_text 
		DECLARE c_statsper cursor FOR s_statsper 
		
		ERROR kandoomsg2("E",1002,"") 
		CLEAR FORM 
		DISPLAY l_rec_company.cmpy_code TO cmpy_code 
		DISPLAY l_rec_company.name_text TO name_text  
		DISPLAY glob_rec_statparms.year_num TO year_num 

		FOR i = 1 TO 2 
			LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
			LET l_arr_rec_stattotal[i].tot_net_amt = 0 
			LET l_arr_rec_stattotal[i].tot_disc_per = 0 
			LET l_arr_rec_stattotal[i].tot_bdgt_amt = 0 
			LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
		END FOR
		 
		DECLARE c_statint cursor FOR 
		SELECT * FROM statint 
		WHERE cmpy_code = p_cmpy_code 
		AND year_num = glob_rec_statparms.year_num 
		AND type_code = glob_rec_statparms.mth_type_code 
		ORDER BY 1,2,3,4 

		#----------------------------- FOREACH -----------------------------------------
		LET l_idx = 0 
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statsper[l_idx].int_text = l_rec_statint.int_text
			 
			## obtain current year grs,net AND disc%
			OPEN c_statsper USING 
				l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
			FETCH c_statsper INTO 
				l_rec_cur_statsper.grs_amt,	
				l_rec_cur_statsper.net_amt 

			IF l_rec_cur_statsper.grs_amt IS NULL THEN 
				LET l_rec_cur_statsper.grs_amt = 0 
			END IF 

			IF l_rec_cur_statsper.net_amt IS NULL THEN 
				LET l_rec_cur_statsper.net_amt = 0 
			END IF 

			LET l_arr_rec_statsper[l_idx].grs_amt = l_rec_cur_statsper.grs_amt 
			LET l_arr_rec_statsper[l_idx].net_amt = l_rec_cur_statsper.net_amt 

			IF l_arr_rec_statsper[l_idx].grs_amt = 0 THEN 
				LET l_arr_rec_statsper[l_idx].disc_per = 0 
			ELSE 
				LET l_arr_rec_statsper[l_idx].disc_per = 100 * (1-(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].grs_amt)) 
			END IF 

			SELECT sum(bdgt_amt) 
			INTO l_arr_rec_statsper[l_idx].bdgt_amt 
			FROM stattarget 
			WHERE cmpy_code = p_cmpy_code 
			AND bdgt_type_ind = "4" 
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
				LET l_arr_rec_statsper[l_idx].achieve_per = 100 *	(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].bdgt_amt) 
			END IF 
			
			## increment totals
			LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statsper.grs_amt 
			LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statsper.net_amt 
			LET l_arr_rec_stattotal[1].tot_bdgt_amt = l_arr_rec_stattotal[1].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 

			IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
				LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statsper.net_amt 
				LET l_arr_rec_stattotal[2].tot_bdgt_amt = l_arr_rec_stattotal[2].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 
			END IF 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF
		
		END FOREACH #------------------------------- 

		IF l_idx = 0 OR l_arr_rec_statsper.getSize() = 0 THEN 
			CALL fgl_winmessage("#7086 ERROR",kandoomsg2("E",7086,""),"ERROR") 			#7086 No statistical information exists FOR this selection "
			RETURN NULL #Exit
		ELSE
			FOR i = 1 TO 2 
				# calc total current & previous year disc%
				IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
					LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[i].tot_disc_per = 100 
					* (1-(l_arr_rec_stattotal[i].tot_net_amt 
					/l_arr_rec_stattotal[i].tot_grs_amt)) 
				END IF 
				IF l_arr_rec_stattotal[i].tot_bdgt_amt = 0 THEN 
					LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
				ELSE 
					LET l_arr_rec_stattotal[i].tot_achieve_per = 100 * 
					(l_arr_rec_stattotal[i].tot_net_amt/l_arr_rec_stattotal[i].tot_bdgt_amt) 
				END IF 
				DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

			END FOR		
		END IF 

	END IF
	RETURN l_arr_rec_statsper
END FUNCTION 
###########################################################################
# END FUNCTION select_sper_type()
###########################################################################


###########################################################################
# FUNCTION company_targets(p_cmpy_code)
#
#
###########################################################################
FUNCTION company_targets(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING 
	--DEFINE l_rec_company RECORD LIKE company.* 
--	DEFINE glob_rec_statparms RECORD LIKE statparms.*
--	DEFINE l_rec_statint RECORD LIKE statint.* 
--	DEFINE l_rec_cur_statsper RECORD LIKE statsper.* ## CURRENT year 
	DEFINE l_arr_rec_statsper DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		grs_amt LIKE statsper.grs_amt, 
		net_amt LIKE statsper.net_amt, 
		disc_per FLOAT, 
		bdgt_amt LIKE stattarget.bdgt_amt, 
		achieve_per FLOAT 
	END RECORD 
--	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
--		tot_grs_amt LIKE statsper.grs_amt, 
--		tot_net_amt LIKE statsper.net_amt, 
--		tot_disc_per FLOAT, 
--		tot_bdgt_amt LIKE stattarget.bdgt_amt, 
--		tot_achieve_per FLOAT 
--	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

{
	CALL select_sper_type() RETURNING p_where_text 

	IF p_where_text IS NULL THEN
		EXIT PROGRAM
	
	
--	SELECT * INTO glob_rec_statparms.* 
--	FROM statparms 
--	WHERE cmpy_code = p_cmpy_code 
--	AND parm_code = "1" 
	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy_code 
	IF status = 0 THEN 
		OPEN WINDOW e264 with FORM "E264" 
		 CALL windecoration_e("E264") -- albo kd-755 
		LET l_query_text = 
		"SELECT sum(grs_amt),sum(net_amt) FROM statsper, salesperson", 
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
			ERROR kandoomsg2("E",1002,"") 
			CLEAR FORM 
			DISPLAY l_rec_company.cmpy_code TO cmpy_code 
			DISPLAY l_rec_company.name_text TO name_text  
			DISPLAY glob_rec_statparms.year_num TO year_num 

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_bdgt_amt = 0 
				LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
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
				 
				## obtain current year grs,net AND disc%
				OPEN c_statsper USING l_rec_statint.year_num, 
				l_rec_statint.type_code, 
				l_rec_statint.int_num 
				FETCH c_statsper INTO l_rec_cur_statsper.grs_amt, 
				l_rec_cur_statsper.net_amt 
				IF l_rec_cur_statsper.grs_amt IS NULL THEN 
					LET l_rec_cur_statsper.grs_amt = 0 
				END IF 
				IF l_rec_cur_statsper.net_amt IS NULL THEN 
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

				SELECT sum(bdgt_amt) 
				INTO l_arr_rec_statsper[l_idx].bdgt_amt 
				FROM stattarget 
				WHERE cmpy_code = p_cmpy_code 
				AND bdgt_type_ind = "4" 
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
					LET l_arr_rec_statsper[l_idx].achieve_per = 100 * 
					(l_arr_rec_statsper[l_idx].net_amt/l_arr_rec_statsper[l_idx].bdgt_amt) 
				END IF 
				
				## increment totals
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statsper.grs_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statsper.net_amt 
				LET l_arr_rec_stattotal[1].tot_bdgt_amt = l_arr_rec_stattotal[1].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statsper.grs_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statsper.net_amt 
					LET l_arr_rec_stattotal[2].tot_bdgt_amt = l_arr_rec_stattotal[2].tot_bdgt_amt + l_arr_rec_statsper[l_idx].bdgt_amt 
				END IF 

			END FOREACH #------------------------------- 
}			
--			IF l_idx = 0 THEN 
--				MESSAGE kandoomsg2("E",7086,"") 			#7086 No statistical information exists FOR this selection "
--				EXIT WHILE 
--			ELSE 
{
				FOR i = 1 TO 2 
					# calc total current & previous year disc%
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_net_amt 
						/l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 
					IF l_arr_rec_stattotal[i].tot_bdgt_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_achieve_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_achieve_per = 100 * 
						(l_arr_rec_stattotal[i].tot_net_amt/l_arr_rec_stattotal[i].tot_bdgt_amt) 
					END IF 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 
}

				CALL select_sper_type(TRUE,p_cmpy_code) RETURNING l_arr_rec_statsper
				MESSAGE kandoomsg2("E",1136,"") 			#1136 Company Sales Vs Targets - F9 Previous - F10 Next Year
 
				DISPLAY ARRAY l_arr_rec_statsper TO sr_statsper.* ATTRIBUTE(UNBUFFERED) 
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EG2","input-l_arr_rec_statsper_flag-1") -- albo kd-502 

					ON ACTION "WEB-HELP" -- albo kd-370 
						CALL onlinehelp(getmoduleid(),null)
						 
					ON ACTION "FILTER"
						CALL l_arr_rec_statsper.clear()
						CALL select_sper_type(TRUE,p_cmpy_code) RETURNING l_arr_rec_statsper
						
					ON ACTION "REFRESH"
						CALL l_arr_rec_statsper.clear()
						CALL select_sper_type(FALSE,p_cmpy_code) RETURNING l_arr_rec_statsper

					BEFORE ROW 
						LET l_idx = arr_curr() 

					ON ACTION "YEAR-1" --ON KEY (f9) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1
						CALL l_arr_rec_statsper.clear()
						CALL select_sper_type(FALSE,p_cmpy_code) RETURNING l_arr_rec_statsper 
						--FOR i = 1 TO arr_count() 
						--	INITIALIZE l_arr_rec_statsper[i].* TO NULL 
						--END FOR 
						--EXIT DISPLAY 
						
					ON ACTION "YEAR+1" --ON KEY (f10) 
						LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1
						CALL l_arr_rec_statsper.clear()
						CALL select_sper_type(FALSE,p_cmpy_code) RETURNING l_arr_rec_statsper 
						--FOR i = 1 TO arr_count() 
						--	INITIALIZE l_arr_rec_statsper[i].* TO NULL 
						--END FOR 
						--EXIT DISPLAY 
						
				END DISPLAY 
				
--			END IF 
--
--			EXIT WHILE 
 
--		END WHILE 
		
		CLOSE WINDOW E264 
--	END IF
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION company_targets(p_cmpy_code)
###########################################################################