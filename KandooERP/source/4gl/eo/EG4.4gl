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
GLOBALS "../eo/EG4_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_temp_where_text char(50)
###########################################################################
# FUNCTION EG4_main()
#
# EG4 - allows users TO SELECT salesperson types TO peruse
#       company distribution information FROM statistics tables.
###########################################################################
FUNCTION EG4_main() 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("EG4") -- albo 
	
	OPEN WINDOW E267 with FORM "E267" 
	 CALL windecoration_e("E267") -- albo kd-755
 
	WHILE select_prod() 
		CALL scan_prod(modu_temp_where_text) 
	END WHILE
	 
	CLOSE WINDOW E267 
END FUNCTION 
###########################################################################
# END FUNCTION EG4_main()
###########################################################################


###########################################################################
# FUNCTION select_prod()
#
#
###########################################################################
FUNCTION select_prod() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text STRING 
	DEFINE l_pseudo_flag char(1) 
	DEFINE l_primary_flag char(1) 
	DEFINE l_normal_flag char(1) 
	DEFINE l_where_text2 STRING 

	CLEAR FORM 
	MESSAGE kandoomsg2("E",1139,"") #1139 Company Monthly Distribution - F9 TO toggle - ESC TO Continue
	 
	DISPLAY BY NAME 
		glob_rec_company.cmpy_code, 
		glob_rec_company.name_text 

	WHILE TRUE 
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
				CALL publish_toolbar("kandoo","EG4","input-l_pseudo_flag-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

{

	#textField got replaced with checkBox

			ON KEY (f9) infield(l_pseudo_flag) 
						IF l_pseudo_flag IS NULL THEN 
							LET l_pseudo_flag = "*" 
						ELSE 
							LET l_pseudo_flag = NULL 
						END IF 
						DISPLAY BY NAME l_pseudo_flag 

						NEXT FIELD NEXT
						 
			ON KEY (f9) infield(l_primary_flag) 
						IF l_primary_flag IS NULL THEN 
							LET l_primary_flag = "*" 
						ELSE 
							LET l_primary_flag = NULL 
						END IF 
						DISPLAY BY NAME l_primary_flag 

						NEXT FIELD NEXT
						 
			ON KEY (f9) infield(l_normal_flag) 
						IF l_normal_flag IS NULL THEN 
							LET l_normal_flag = "*" 
						ELSE 
							LET l_normal_flag = NULL 
						END IF 
						DISPLAY BY NAME l_normal_flag 

						NEXT FIELD pseudo_flag 
}

			AFTER INPUT 
			
				IF NOT (int_flag OR quit_flag) THEN 
					IF l_primary_flag IS NULL 
					AND l_pseudo_flag IS NULL 
					AND l_normal_flag IS NULL THEN 
						ERROR kandoomsg2("E",1132,"") 					#1132 All Salesperson Types have been excluded "
						NEXT FIELD NEXT 
					END IF 
					IF l_pseudo_flag = "*" THEN 
						LET l_where_text2 = " '1'" 
					END IF 
					IF l_primary_flag = "*" THEN 
						LET l_where_text2 = l_where_text clipped,",'2'" 
					END IF 
					IF l_normal_flag = "*" THEN 
						LET l_where_text2 = l_where_text clipped,",'3'" 
					END IF 
					LET l_where_text2[1,1] = " " 
					LET l_where_text2 = "salesperson.sale_type_ind in (",		l_where_text2 clipped,")" 
				END IF 

		END INPUT 
		
		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		LET modu_temp_where_text = l_where_text2 
		
		MESSAGE kandoomsg2("E",1001,"") 
		CONSTRUCT BY NAME l_where_text ON 
			maingrp_code, 
			prodgrp_code, 
			part_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","EG4","construct-maingrp_code-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			CONTINUE WHILE 
		ELSE 
			MESSAGE kandoomsg2("E",1002,"") 
			LET l_query_text = 
			"SELECT ' ',maingrp_code,prodgrp_code,part_code,desc_text ", 
			"FROM product ", 
			"WHERE product.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND status_ind != '3' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY 2,3,4" 
			PREPARE s_product FROM l_query_text 
			DECLARE c_product cursor FOR s_product 
			EXIT WHILE 
		END IF 
	END WHILE 
	
	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION select_prod()
###########################################################################


###########################################################################
# FUNCTION scan_prod(l_where_text) 
#
# 
###########################################################################
FUNCTION scan_prod(l_where_text) 
	DEFINE l_arr_rec_product DYNAMIC ARRAY OF RECORD
		scroll_flag char(1), 
		maingrp_code LIKE product.maingrp_code, 
		prodgrp_code LIKE product.prodgrp_code, 
		part_code LIKE product.part_code, 
		desc_text LIKE product.desc_text, 
		stat_flag char(1) 
	END RECORD 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 

	LET l_idx = 1 
	FOREACH c_product INTO l_arr_rec_product[l_idx].* 
		SELECT unique 1 FROM distsper 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND maingrp_code = l_arr_rec_product[l_idx].maingrp_code 
		AND prodgrp_code = l_arr_rec_product[l_idx].prodgrp_code 
		AND part_code = l_arr_rec_product[l_idx].part_code 
		IF status = NOTFOUND THEN 
			LET l_arr_rec_product[l_idx].stat_flag = NULL 
		ELSE 
			LET l_arr_rec_product[l_idx].stat_flag = "*" 
		END IF 
		IF l_idx = 100 THEN 
			ERROR kandoomsg2("E",9157,l_idx) 
			EXIT FOREACH 
		END IF 
		LET l_idx = l_idx + 1 
	END FOREACH 
	CALL set_count(l_idx-1) 

	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 

	MESSAGE kandoomsg2("E",1143,"") #1143 Company Monthly Distribution - RETURN TO View
	DISPLAY ARRAY l_arr_rec_product TO sr_product.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","EG4","input-arr-l_arr_rec_product-1") -- albo kd-502 

		ON ACTION "WEB-HELP" -- albo kd-370 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION ("ACCEPT","DOBLECLICK") --BEFORE FIELD maingrp_code 
			IF l_idx > 0 THEN
				IF l_arr_rec_product[l_idx].maingrp_code IS NOT NULL THEN 
					CALL comp_dist(glob_rec_kandoouser.cmpy_code,l_arr_rec_product[l_idx].part_code,l_where_text) 
				END IF 
			END IF
	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION scan_prod(l_where_text) 
###########################################################################


###########################################################################
# FUNCTION comp_dist(p_cmpy_code,p_part_code,p_sper_where_text)  
#
# 
###########################################################################
FUNCTION comp_dist(p_cmpy_code,p_part_code,p_sper_where_text) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_part_code LIKE product.part_code 
	DEFINE p_sper_where_text char(50) 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_rec_statparms RECORD LIKE statparms.* 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_cur_distsper RECORD LIKE distsper.* ## CURRENT year 
	DEFINE l_rec_prv_distsper RECORD LIKE distsper.* ## previous year 
	DEFINE l_arr_rec_distsper DYNAMIC ARRAY OF RECORD 
		scroll_flag char(1), 
		int_text LIKE statint.int_text, 
		mth_cust_num LIKE distsper.mth_cust_num, 
		mth_net_amt LIKE distsper.mth_net_amt, 
		mth_sales_qty LIKE distsper.mth_sales_qty, 
		prv_mth_cust_num LIKE distsper.mth_cust_num, 
		prv_mth_net_amt LIKE distsper.mth_net_amt, 
		prv_mth_sales_qty LIKE distsper.mth_sales_qty 
	END RECORD 
	DEFINE l_arr_rec_stattotal array[1] OF RECORD 
		tot_mth_net_amt LIKE distsper.mth_net_amt, 
		tot_mth_sales_qty LIKE distsper.mth_sales_qty, 
		tot_prv_mth_net_amt LIKE distsper.mth_net_amt, 
		tot_prv_mth_sales_qty LIKE distsper.mth_sales_qty 
	END RECORD 
	DEFINE l_type_ind char(1) ## 1-> product 2-> prodgrp 3-> MAIN prodgrp 
	DEFINE l_type_code LIKE product.part_code 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_prompt_text char(40)
	DEFINE l_comp_text char(40) 
	DEFINE l_idx SMALLINT 
	DEFINE i SMALLINT
	DEFINE l_msg STRING
	
	OPEN WINDOW E268 with FORM "E268" 
	 CALL windecoration_e("E268") -- albo kd-755 

	SELECT * INTO l_rec_statparms.* 
	FROM statparms 
	WHERE cmpy_code = p_cmpy_code 
	AND parm_code = "1" 

	SELECT * INTO l_rec_product.* 
	FROM product 
	WHERE cmpy_code = p_cmpy_code 
	AND part_code = p_part_code 
	IF status = NOTFOUND THEN 
		ERROR kandoomsg2("I",5010,p_part_code) 	#5010" Logic Error: product NOT found"
		RETURN 
	END IF 

	SELECT * INTO l_rec_company.* 
	FROM company 
	WHERE cmpy_code = p_cmpy_code 
	
	IF status = 0 THEN 
		MENU " Inquiry level" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","EG4","menu-Inquiry_Level-1") -- albo kd-502 

			ON ACTION "WEB-HELP" -- albo kd-370 
				CALL onlinehelp(getmoduleid(),null) 
				
			COMMAND "Product" " Inquiry on product sales" 
				LET l_type_ind = "1" 
				LET l_type_code = l_rec_product.part_code 
				EXIT MENU 
				
			COMMAND "PRODUCT GROUP" " Inquiry on product-group sales" 
				LET l_type_ind = "2" 
				LET l_type_code = l_rec_product.prodgrp_code 
				EXIT MENU 
				
			COMMAND "MAIN GROUP" " Inquiry on main-group sales" 
				LET l_type_ind = "3" 
				LET l_type_code = l_rec_product.maingrp_code 
				EXIT MENU 
				
			COMMAND KEY(INTERRUPT,"E")"Exit" " Exit inquiry" 
				LET quit_flag = TRUE 
				EXIT MENU 

		END MENU 
		
		IF NOT (int_flag OR quit_flag) THEN 
			CASE l_type_ind 

				WHEN "1" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM product 
					WHERE cmpy_code = p_cmpy_code 
					AND part_code = l_type_code 
					LET l_prompt_text = kandooword("Product","1") 
					LET l_where_text = "part_code = '",l_type_code,"'" 

				WHEN "2" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM prodgrp 
					WHERE cmpy_code = p_cmpy_code 
					AND prodgrp_code = l_type_code 
					LET l_prompt_text = kandooword("Product Group","1") 
					LET l_where_text = "part_code IS NULL AND ", 
					"prodgrp_code='",l_type_code,"'" 

				WHEN "3" 
					SELECT desc_text INTO l_rec_product.desc_text 
					FROM maingrp 
					WHERE cmpy_code = p_cmpy_code 
					AND maingrp_code = l_type_code 
					LET l_prompt_text = kandooword("Main Group","1") 
					LET l_where_text ="part_code IS NULL AND ", 
					"prodgrp_code IS NULL AND ", 
					"maingrp_code = '",l_type_code,"'" 
			END CASE 

			LET l_query_text = 
			"SELECT sum(mth_cust_num),sum(mth_net_amt),sum(mth_sales_qty)", 
			" FROM distsper, salesperson", 
			" WHERE distsper.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.cmpy_code = '",p_cmpy_code,"'", 
			" AND salesperson.sale_code = distsper.sale_code", 
			" AND distsper.year_num = ? ", 
			" AND distsper.type_code = ? ", 
			" AND distsper.int_num = ? ", 
			" AND ",l_where_text clipped, 
			" AND ",p_sper_where_text clipped 
			PREPARE s_distsper FROM l_query_text 
			DECLARE c_distsper cursor FOR s_distsper 
			
			LET l_comp_text = kandooword("Company","1") 
			LET l_comp_text = l_comp_text clipped,"........" 
			LET l_prompt_text = l_prompt_text clipped,"........" 
			LET l_rec_product.part_code = l_type_code 
			
			OPTIONS INSERT KEY f36, 
			DELETE KEY f36 
			
			WHILE TRUE #------------------------------------------
				CALL l_arr_rec_distsper.clear() #init/clear dynamic array
				
				ERROR kandoomsg2("E",1002,"") 
				CLEAR FORM
				 
				DISPLAY l_comp_text TO comp_text
				DISPLAY l_prompt_text TO prompt_text
				DISPLAY l_rec_company.cmpy_code TO cmpy_code 
				DISPLAY l_rec_company.name_text TO name_text
				DISPLAY l_rec_product.part_code TO part_code 
				DISPLAY l_rec_product.desc_text TO desc_text 

				LET i = l_rec_statparms.year_num - 1 
				DISPLAY l_rec_statparms.year_num TO sr_year[1].year_num 
				DISPLAY i TO sr_year[2].year_num 

				LET l_arr_rec_stattotal[1].tot_mth_net_amt = 0 
				LET l_arr_rec_stattotal[1].tot_mth_sales_qty = 0 
				LET l_arr_rec_stattotal[1].tot_prv_mth_net_amt = 0 
				LET l_arr_rec_stattotal[1].tot_prv_mth_sales_qty = 0 
				LET l_idx = 0 
				
				DECLARE c_statint cursor FOR 
				SELECT * FROM statint 
				WHERE cmpy_code = p_cmpy_code 
				AND year_num = l_rec_statparms.year_num 
				AND type_code = l_rec_statparms.mth_type_code 
				ORDER BY 1,2,3,4 

				FOREACH c_statint INTO l_rec_statint.* 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_distsper[l_idx].int_text = l_rec_statint.int_text 
					
					## obtain current year gross,net AND disc%
					OPEN c_distsper USING l_rec_statint.year_num, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 
					FETCH c_distsper INTO l_rec_cur_distsper.mth_cust_num, 
					l_rec_cur_distsper.mth_net_amt, 
					l_rec_cur_distsper.mth_sales_qty 
					IF l_rec_cur_distsper.mth_cust_num IS NULL THEN 
						LET l_rec_cur_distsper.mth_cust_num = 0 
					END IF 
					IF l_rec_cur_distsper.mth_net_amt IS NULL THEN 
						LET l_rec_cur_distsper.mth_net_amt = 0 
					END IF 
					IF l_rec_cur_distsper.mth_sales_qty IS NULL THEN 
						LET l_rec_cur_distsper.mth_sales_qty = 0 
					END IF 
					LET l_arr_rec_distsper[l_idx].mth_cust_num = l_rec_cur_distsper.mth_cust_num 
					LET l_arr_rec_distsper[l_idx].mth_net_amt = l_rec_cur_distsper.mth_net_amt 
					LET l_arr_rec_distsper[l_idx].mth_sales_qty = l_rec_cur_distsper.mth_sales_qty 

					## obtain previous year gross,net AND disc%
					LET i = l_rec_statint.year_num - 1 
					OPEN c_distsper USING i, 
					l_rec_statint.type_code, 
					l_rec_statint.int_num 

					FETCH c_distsper INTO 
						l_rec_prv_distsper.mth_cust_num, 
						l_rec_prv_distsper.mth_net_amt, 
						l_rec_prv_distsper.mth_sales_qty 
					IF l_rec_prv_distsper.mth_cust_num IS NULL THEN 
						LET l_rec_prv_distsper.mth_cust_num = 0 
					END IF 
					IF l_rec_prv_distsper.mth_net_amt IS NULL THEN 
						LET l_rec_prv_distsper.mth_net_amt = 0 
					END IF 
					IF l_rec_prv_distsper.mth_sales_qty IS NULL THEN 
						LET l_rec_prv_distsper.mth_sales_qty = 0 
					END IF 
					LET l_arr_rec_distsper[l_idx].prv_mth_cust_num = l_rec_prv_distsper.mth_cust_num 
					LET l_arr_rec_distsper[l_idx].prv_mth_net_amt = l_rec_prv_distsper.mth_net_amt 
					LET l_arr_rec_distsper[l_idx].prv_mth_sales_qty = l_rec_prv_distsper.mth_sales_qty 
					## increment totals
					LET l_arr_rec_stattotal[1].tot_mth_net_amt = l_arr_rec_stattotal[1].tot_mth_net_amt + l_rec_cur_distsper.mth_net_amt 
					LET l_arr_rec_stattotal[1].tot_mth_sales_qty = l_arr_rec_stattotal[1].tot_mth_sales_qty + l_rec_cur_distsper.mth_sales_qty 
					LET l_arr_rec_stattotal[1].tot_prv_mth_net_amt = l_arr_rec_stattotal[1].tot_prv_mth_net_amt + l_rec_prv_distsper.mth_net_amt 
					LET l_arr_rec_stattotal[1].tot_prv_mth_sales_qty = l_arr_rec_stattotal[1].tot_prv_mth_sales_qty + l_rec_prv_distsper.mth_sales_qty 

				END FOREACH 
				
				IF l_arr_rec_distsper.getSize() = 0 THEN 
					LET l_msg =  kandoomsg2("E",7086,"") , "\nExit Program" #7086 No statistical information exists FOR this selection "
					CALL fgl_winmessage("ERROR - No statistical information exists",l_msg,"ERROR") 	
					EXIT WHILE 
				ELSE 
					DISPLAY l_arr_rec_stattotal[1].* TO sr_stattotal[1].* 

					MESSAGE kandoomsg2("E",1140,"") 				#1140 Company Monthly Distribution - F9 Previous - F10 Next
					DISPLAY ARRAY l_arr_rec_distsper TO sr_distsper.* ATTRIBUTE(UNBUFFERED) 
						BEFORE DISPLAY 
							CALL publish_toolbar("kandoo","EG4","input-arr-l_arr_rec_distsper-1") -- albo kd-502 

						ON ACTION "WEB-HELP" -- albo kd-370 
							CALL onlinehelp(getmoduleid(),null) 

						BEFORE ROW 
							LET l_idx = arr_curr() 

						ON ACTION "YEAR-1" --ON KEY (f9) 
							LET l_rec_statparms.year_num = l_rec_statparms.year_num - 1 
							--FOR i = 1 TO arr_count() 
							--	INITIALIZE l_arr_rec_distsper[i].* TO NULL 
							--END FOR 
							EXIT DISPLAY 

						ON ACTION "YEAR+1" --ON KEY (f10) 
							LET l_rec_statparms.year_num = l_rec_statparms.year_num + 1 
							--FOR i = 1 TO arr_count() 
							--	INITIALIZE l_arr_rec_distsper[i].* TO NULL 
							--END FOR 
							EXIT DISPLAY 
					END DISPLAY 

					IF int_flag THEN
						EXIT WHILE
					END IF 
				END IF  --???
				
--				EXIT WHILE

{				IF fgl_lastkey() = fgl_keyval("F9") 
				OR fgl_lastkey() = fgl_keyval("F10") THEN 
					FOR i = 1 TO arr_count() 
						INITIALIZE l_arr_rec_distsper[i].* TO NULL 
					END FOR 
				ELSE 
					EXIT WHILE 
				END IF
 }
 
			END WHILE 
		END IF 
	END IF 
	
	CLOSE WINDOW E268 
	
	LET int_flag = FALSE 
	LET quit_flag = FALSE 
END FUNCTION 
###########################################################################
# END FUNCTION comp_dist(p_cmpy_code,p_part_code,p_sper_where_text)  
###########################################################################