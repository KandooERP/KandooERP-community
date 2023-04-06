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
GLOBALS "../eo/EB_GROUP_GLOBALS.4gl"  
GLOBALS "../eo/EB6_GLOBALS.4gl" 
###########################################################################
# FUNCTION EB6_main()
#
# EB6 - allows users TO SELECT a warehouse TO peruse warehouse
#       sales information FROM statistics tables.
###########################################################################
FUNCTION EB6_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	
	CALL setModuleId("EB6")  

	OPEN WINDOW E446 with FORM "E446" 
	 CALL windecoration_e("E446") 
 
	CALL scan_ware() 
	 
	CLOSE WINDOW E446 

END FUNCTION
###########################################################################
# END FUNCTION EB6_main()
###########################################################################


###########################################################################
# FUNCTION select_ware()
#
#
###########################################################################
FUNCTION db_statware_warehouse_get_datasource(p_filter) 
	DEFINE p_filter BOOLEAN
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_rec_statware RECORD LIKE statware.*
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_statware DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE product.desc_text, 
		part_code LIKE product.part_code, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("E",1001,"") # 1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT BY NAME l_where_text ON 
			s.ware_code, 
			w.desc_text, 
			s.part_code, 
			s.maingrp_code, 
			s.prodgrp_code 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EB6","construct-ware_code-1") -- albo kd-502 
	
			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = "1=1"
		END IF 
	ELSE
		LET l_where_text = "1=1"
	END IF
		 
	LET l_query_text = 
		"SELECT unique s.ware_code,s.part_code,", 
		"s.prodgrp_code,s.maingrp_code ", 
		"FROM statware s,warehouse w ", 
		"WHERE s.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND w.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND w.ware_code = s.ware_code ", 
		"AND s.type_code = '",glob_rec_statparms.mth_type_code,"' ", 
		"AND ",l_where_text clipped 
	PREPARE s_statware FROM l_query_text 
	DECLARE c_statware cursor FOR s_statware 
 
	LET l_idx = 0 
	FOREACH c_statware INTO l_rec_statware.ware_code, 
		l_rec_statware.part_code, 
		l_rec_statware.prodgrp_code, 
		l_rec_statware.maingrp_code 
		LET l_idx = l_idx + 1 

		SELECT * INTO l_rec_warehouse.* 
		FROM warehouse 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND ware_code = l_rec_statware.ware_code 

		LET l_arr_rec_statware[l_idx].ware_code = l_rec_statware.ware_code 
		LET l_arr_rec_statware[l_idx].part_code = l_rec_statware.part_code 
		LET l_arr_rec_statware[l_idx].desc_text = l_rec_warehouse.desc_text 
		LET l_arr_rec_statware[l_idx].maingrp_code = l_rec_statware.maingrp_code 
		LET l_arr_rec_statware[l_idx].prodgrp_code = l_rec_statware.prodgrp_code 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF
	END FOREACH 
	
	IF l_idx = 0 THEN 
		ERROR kandoomsg2("E",9156,"")		#9156 No products satisfied selection criteria.
	END IF 

	RETURN l_arr_rec_statware
END FUNCTION 
###########################################################################
# END FUNCTION select_ware()
###########################################################################


###########################################################################
# FUNCTION scan_ware()
#
#
###########################################################################
FUNCTION scan_ware() 
	DEFINE l_rec_statware RECORD LIKE statware.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_arr_rec_statware DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		ware_code LIKE warehouse.ware_code, 
		desc_text LIKE product.desc_text, 
		part_code LIKE product.part_code, 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_idx SMALLINT 

	CALL db_statware_warehouse_get_datasource(FALSE) RETURNING l_arr_rec_statware
	
	MESSAGE kandoomsg2("E",1083,"")	#1083 Products Monthly Turnover;  ENTER TO View.
	DISPLAY ARRAY l_arr_rec_statware TO sr_statware.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EB6","input-arr-l_arr_rec_statware-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "FILTER"
			CALL l_arr_rec_statware.clear()
			CALL db_statware_warehouse_get_datasource(TRUE) RETURNING l_arr_rec_statware
		
		ON ACTION "REFRESH"
			 CALL windecoration_e("E446")
			CALL l_arr_rec_statware.clear()
			CALL db_statware_warehouse_get_datasource(FALSE) RETURNING l_arr_rec_statware

		BEFORE ROW 
			LET l_idx = arr_curr() 
			
		ON ACTION ("ACCEPT","DOUBLECLICK") --BEFORE FIELD ware_code 
			IF l_arr_rec_statware[l_idx].ware_code IS NOT NULL THEN 
				CALL ware_turnover(glob_rec_kandoouser.cmpy_code,l_arr_rec_statware[l_idx].ware_code, 
				l_arr_rec_statware[l_idx].part_code, 
				l_arr_rec_statware[l_idx].prodgrp_code, 
				l_arr_rec_statware[l_idx].maingrp_code) 
			END IF 

	END DISPLAY 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION select_ware()
###########################################################################


###########################################################################
# FUNCTION ware_turnover(p_cmpy_code,p_ware_code,p_part_code,p_prodgrp_code,p_maingrp_code) 
#
#
###########################################################################
FUNCTION ware_turnover(p_cmpy_code,p_ware_code,p_part_code,p_prodgrp_code,p_maingrp_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ware_code LIKE warehouse.ware_code 
	DEFINE p_part_code LIKE statware.part_code 
	DEFINE p_prodgrp_code LIKE statware.prodgrp_code 
	DEFINE p_maingrp_code LIKE statware.maingrp_code 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_statware RECORD LIKE statware.* ## CURRENT year 
	DEFINE l_rec_prv_statware RECORD LIKE statware.* ## previous year 
	DEFINE l_arr_rec_statware DYNAMIC ARRAY OF RECORD --array[100] OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		gross_amt LIKE statware.gross_amt, 
		net_amt LIKE statware.net_amt, 
		disc_per FLOAT, 
		prv_net_amt LIKE statware.net_amt, 
		prv_disc_per FLOAT, 
		var_grs_per LIKE statware.gross_amt, 
		var_net_per LIKE statware.net_amt 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[2] OF RECORD 
		tot_grs_amt LIKE statware.gross_amt, 
		tot_net_amt LIKE statware.net_amt, 
		tot_disc_per FLOAT, 
		tot_prv_net_amt LIKE statware.net_amt, 
		tot_prv_disc_per FLOAT, 
		tot_var_grs_per LIKE statware.gross_amt, 
		tot_var_net_per LIKE statware.net_amt 
	END RECORD 
	DEFINE l_arr_totprvgrs_amt array[2] OF decimal(16,2)# 1->year total 2->ytd total 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code #??? this is so confusing.. why ???
	DEFINE l_prompt_text char(40) 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT 
	
	CALL db_warehouse_get_rec(UI_ON,p_ware_code) RETURNING l_rec_warehouse.*

	IF l_rec_warehouse.ware_code IS NULL THEN 
		ERROR kandoomsg2("I",5010,p_ware_code) 	#5010 Logic Error: Product Code does NOT Exist.
		RETURN 
	END IF 

	OPEN WINDOW E227 with FORM "E227" 
	 CALL windecoration_e("E227") 

	IF NOT (int_flag OR quit_flag) THEN 
		SELECT desc_text INTO l_rec_product.desc_text 
		FROM warehouse 
		WHERE cmpy_code = p_cmpy_code 
		AND ware_code = p_ware_code 
		LET l_rec_product.part_code = p_ware_code 
		LET l_prompt_text = kandooword("Warehouse","1") 

		IF p_maingrp_code IS NOT NULL THEN 
			SELECT desc_text INTO l_rec_product.desc_text 
			FROM maingrp 
			WHERE cmpy_code = p_cmpy_code 
			AND maingrp_code = p_maingrp_code 

			LET l_rec_product.part_code = p_maingrp_code 
			LET l_prompt_text = kandooword("Main Group","1") 
			LET l_where_text = l_where_text clipped," ", 
				"AND maingrp_code = '",p_maingrp_code,"' " 
		ELSE 
			LET l_where_text = l_where_text clipped," ", "AND maingrp_code IS NULL " 
		END IF 
		
		IF p_prodgrp_code IS NOT NULL THEN 
			SELECT desc_text INTO l_rec_product.desc_text FROM prodgrp 
			WHERE cmpy_code = p_cmpy_code 
			AND prodgrp_code = p_prodgrp_code 

			LET l_rec_product.part_code = p_prodgrp_code 
			LET l_prompt_text = kandooword("Product Group","1") 
			LET l_where_text = l_where_text clipped," ", 
				"AND prodgrp_code = '",p_prodgrp_code,"' " 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
				"AND prodgrp_code IS NULL " 
		END IF
		 
		IF p_part_code IS NOT NULL THEN 
			SELECT desc_text INTO l_rec_product.desc_text FROM product 
			WHERE cmpy_code = p_cmpy_code 
			AND part_code = p_part_code 

			LET l_rec_product.part_code = p_part_code 
			LET l_prompt_text = kandooword("Product","1") 
			LET l_where_text = l_where_text clipped," ", 
				"AND part_code = '",p_part_code,"' " 
		ELSE 
			LET l_where_text = l_where_text clipped," ", 
				"AND part_code IS NULL " 
		END IF
		 
		LET l_prompt_text = l_prompt_text clipped,"........" 
		LET l_query_text = 
			"SELECT * FROM statware ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND ware_code = '",p_ware_code,"' ", 
			"AND year_num = ? ", 
			"AND type_code = ? ", 
			"AND int_num = ? ", 
			" ",l_where_text clipped 
		PREPARE s1_statware FROM l_query_text 
		DECLARE c1_statware cursor FOR s1_statware 

		WHILE TRUE
			CALL l_arr_rec_statware.clear() #clear data array
			 
			MESSAGE kandoomsg2("E",1002,"") 		#1002 Searching database;  Please wait.
			CLEAR FORM 
			DISPLAY l_prompt_text TO prompt_text 
			DISPLAY l_rec_product.part_code TO part_code 
			DISPLAY l_rec_product.desc_text TO desc_text  

			FOR i = 1 TO 2 
				LET l_arr_rec_stattotal[i].tot_grs_amt = 0 
				LET l_arr_rec_stattotal[i].tot_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_prv_net_amt = 0 
				LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
				LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
				LET l_arr_totprvgrs_amt[i] = 0 
			END FOR 
			LET i = glob_rec_statparms.year_num - 1
			 
			DISPLAY glob_rec_statparms.year_num TO sr_year[1].year_num 
			DISPLAY i TO  sr_year[2].year_num 

			DECLARE c_statint cursor FOR 
			SELECT * FROM statint 
			WHERE cmpy_code = p_cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = glob_rec_statparms.mth_type_code 
			ORDER BY 1,2,3,4 
			LET l_idx = 0 

			FOREACH c_statint INTO l_rec_statint.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_statware[l_idx].int_text = l_rec_statint.int_text
				 
				#------------------------------------------------------------
				# obtain current year gross,net AND disc%
				#------------------------------------------------------------
				OPEN c1_statware USING 
					l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
				FETCH c1_statware INTO l_rec_cur_statware.* 
				IF status = NOTFOUND THEN 
					LET l_rec_cur_statware.gross_amt = 0 
					LET l_rec_cur_statware.net_amt = 0 
				END IF 
				
				LET l_arr_rec_statware[l_idx].gross_amt = l_rec_cur_statware.gross_amt 
				LET l_arr_rec_statware[l_idx].net_amt = l_rec_cur_statware.net_amt 
				
				IF l_arr_rec_statware[l_idx].gross_amt = 0 THEN 
					LET l_arr_rec_statware[l_idx].disc_per = 0 
				ELSE 
					LET l_arr_rec_statware[l_idx].disc_per = 100 * (1-(l_arr_rec_statware[l_idx].net_amt/l_arr_rec_statware[l_idx].gross_amt)) 
				END IF 
				
				#------------------------------------------------------------
				# obtain previous year gross,net AND disc%
				#------------------------------------------------------------
				OPEN c1_statware USING 
					i, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
				FETCH c1_statware INTO l_rec_prv_statware.* 
				IF status = NOTFOUND THEN 
					LET l_rec_prv_statware.gross_amt = 0 
					LET l_rec_prv_statware.net_amt = 0 
				END IF 
				
				LET l_arr_rec_statware[l_idx].prv_net_amt = l_rec_prv_statware.net_amt 

				IF l_rec_prv_statware.gross_amt = 0 THEN 
					LET l_arr_rec_statware[l_idx].prv_disc_per = 0 
					LET l_arr_rec_statware[l_idx].var_grs_per = 0 
				ELSE 
					LET l_arr_rec_statware[l_idx].prv_disc_per = 100 *(1-(l_arr_rec_statware[l_idx].prv_net_amt/l_rec_prv_statware.gross_amt)) 
					LET l_arr_rec_statware[l_idx].var_grs_per = 100 *(l_arr_rec_statware[l_idx].gross_amt-l_rec_prv_statware.gross_amt)	/ l_rec_prv_statware.gross_amt 
				END IF 

				IF l_rec_prv_statware.net_amt = 0 THEN 
					LET l_arr_rec_statware[l_idx].var_net_per = 0 
				ELSE 
					LET l_arr_rec_statware[l_idx].var_net_per = 100 * (l_arr_rec_statware[l_idx].net_amt - l_arr_rec_statware[l_idx].prv_net_amt)	/ l_arr_rec_statware[l_idx].prv_net_amt 
				END IF 

				#------------------------------------------------------------
				# increment totals
				#------------------------------------------------------------
				LET l_arr_rec_stattotal[1].tot_grs_amt = l_arr_rec_stattotal[1].tot_grs_amt + l_rec_cur_statware.gross_amt 
				LET l_arr_rec_stattotal[1].tot_net_amt = l_arr_rec_stattotal[1].tot_net_amt + l_rec_cur_statware.net_amt 
				LET l_arr_totprvgrs_amt[1] = l_arr_totprvgrs_amt[1] + l_rec_prv_statware.gross_amt 
				LET l_arr_rec_stattotal[1].tot_prv_net_amt = l_arr_rec_stattotal[1].tot_prv_net_amt + l_rec_prv_statware.net_amt
				 
				IF l_rec_statint.int_num <= glob_rec_statparms.mth_num THEN 
					LET l_arr_rec_stattotal[2].tot_grs_amt = l_arr_rec_stattotal[2].tot_grs_amt + l_rec_cur_statware.gross_amt 
					LET l_arr_rec_stattotal[2].tot_net_amt = l_arr_rec_stattotal[2].tot_net_amt + l_rec_cur_statware.net_amt 
					LET l_arr_totprvgrs_amt[2] = l_arr_totprvgrs_amt[2] + l_rec_prv_statware.gross_amt 
					LET l_arr_rec_stattotal[2].tot_prv_net_amt = l_arr_rec_stattotal[2].tot_prv_net_amt + l_rec_prv_statware.net_amt 
				END IF 
 
			END FOREACH 
			
			IF l_idx = 0 THEN 
				ERROR kandoomsg2("E",7086,"") 			#7086 No Statistical Information exists FOR this selection.
				EXIT WHILE 
			ELSE 
				FOR i = 1 TO 2 

					#------------------------------------------------------------
					# calc total current & previous year disc%
					#------------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_grs_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_disc_per = 100 * (1-(l_arr_rec_stattotal[i].tot_net_amt / l_arr_rec_stattotal[i].tot_grs_amt)) 
					END IF 

					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_prv_disc_per = 100 
						* (1-(l_arr_rec_stattotal[i].tot_prv_net_amt/l_arr_totprvgrs_amt[i])) 
					END IF
					
					#------------------------------------------------------------ 
					# calc total current & previous year net & gross variance
					#------------------------------------------------------------
					IF l_arr_rec_stattotal[i].tot_prv_net_amt = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_net_per = 100 * ( l_arr_rec_stattotal[i].tot_net_amt	- l_arr_rec_stattotal[i].tot_prv_net_amt) / l_arr_rec_stattotal[i].tot_prv_net_amt 
					END IF 
					
					IF l_arr_totprvgrs_amt[i] = 0 THEN 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 0 
					ELSE 
						LET l_arr_rec_stattotal[i].tot_var_grs_per = 100 * (l_arr_rec_stattotal[i].tot_grs_amt-l_arr_totprvgrs_amt[i]) / l_arr_totprvgrs_amt[i] 
					END IF
					 
					DISPLAY l_arr_rec_stattotal[i].* TO sr_stattotal[i].* 

				END FOR 

				MESSAGE kandoomsg2("E",1080,"") #1080 Inventory Monthly Turnover;  F9 Previour;  F10 Next.
 
				DISPLAY ARRAY l_arr_rec_statware TO sr_statprod.*
					BEFORE DISPLAY 
						CALL publish_toolbar("kandoo","EB6","input-arr-l_arr_rec_statware-1") -- albo kd-502 

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

			IF int_flag THEN  #user cancel
				EXIT WHILE 
			END IF 
		END WHILE
		 
	END IF
	 
	CLOSE WINDOW E227
	 
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION
###########################################################################
# END FUNCTION ware_turnover(p_cmpy_code,p_ware_code,p_part_code,p_prodgrp_code,p_maingrp_code) 
###########################################################################