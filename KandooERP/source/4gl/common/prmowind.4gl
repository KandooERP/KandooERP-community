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

###########################################################################
# FUNCTION db_prodledg_get_datasource2(p_filter,p_cmpy_code,p_ware_code,p_part_code,p_tran_date)
#
#
###########################################################################
FUNCTION db_prodledg_get_datasource2(p_filter,p_cmpy_code,p_ware_code,p_part_code,p_tran_date)
	DEFINE p_filter BOOLEAN
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE p_ware_code LIKE warehouse.ware_code
	DEFINE p_part_code LIKE product.part_code
	DEFINE p_tran_date LIKE prodledg.tran_date
	DEFINE l_rec_t_prodledg 
		RECORD 
			tran_date LIKE prodledg.tran_date 
		END RECORD
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF  
		RECORD 
			tran_date LIKE prodledg.tran_date, 
			year_num LIKE prodledg.year_num, 
			period_num LIKE prodledg.period_num, 
			trantype_ind LIKE prodledg.trantype_ind, 
			source_text LIKE prodledg.source_text, 
			source_num LIKE prodledg.source_num, 
			tran_qty LIKE prodledg.tran_qty, 
			bal_amt LIKE prodledg.bal_amt 
		END RECORD 
	DEFINE l_arr_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_idx SMALLINT

	IF p_cmpy_code IS NULL THEN
		LET p_cmpy_code = glob_rec_kandoouser.cmpy_code
	END IF

	IF p_ware_code IS NOT NULL THEN 
		LET l_rec_prodledg.ware_code = p_ware_code
	END IF

	IF p_part_code IS NOT NULL THEN 
		LET l_rec_prodledg.part_code = p_part_code
	END IF

	IF p_tran_date != 0 or p_tran_date IS NOT NULL THEN
		LET l_rec_t_prodledg.tran_date = p_tran_date
	ELSE
		LET l_rec_t_prodledg.tran_date = today - 30
	END IF		 
	
	IF p_filter THEN
		MESSAGE kandoomsg2("U",1020,"Ledger")	#1020 Enter Ledger Details
		INPUT BY NAME l_rec_t_prodledg.tran_date WITHOUT DEFAULTS 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","prmowind","input-prodledg") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			CLOSE WINDOW I114 
			LET int_flag = false 
			LET quit_flag = false 
			IF p_tran_date != 0 or p_tran_date IS NOT NULL THEN
				LET l_rec_t_prodledg.tran_date = p_tran_date
			ELSE
				LET l_rec_t_prodledg.tran_date = today - 30
			END IF		
		END IF 

	END IF
	
	DECLARE ledg CURSOR FOR 
	SELECT prodledg.* INTO l_rec_prodledg.* 
	FROM prodledg 
	WHERE prodledg.part_code = l_rec_prodledg.part_code 
	AND prodledg.ware_code = l_rec_prodledg.ware_code 
	AND prodledg.cmpy_code = p_cmpy_code 
	AND prodledg.tran_date >= l_rec_t_prodledg.tran_date 
	ORDER BY prodledg.seq_num 

	LET l_idx = 0 
	FOREACH ledg 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_prodledg[l_idx].tran_date = l_rec_prodledg.tran_date 
		LET l_arr_rec_prodledg[l_idx].year_num = l_rec_prodledg.year_num 
		LET l_arr_rec_prodledg[l_idx].period_num = l_rec_prodledg.period_num 
		LET l_arr_rec_prodledg[l_idx].trantype_ind = l_rec_prodledg.trantype_ind 
		LET l_arr_rec_prodledg[l_idx].source_text = l_rec_prodledg.source_text 
		LET l_arr_rec_prodledg[l_idx].source_num = l_rec_prodledg.source_num 
		LET l_arr_rec_prodledg[l_idx].tran_qty = l_rec_prodledg.tran_qty 
		LET l_arr_rec_prodledg[l_idx].bal_amt = l_rec_prodledg.bal_amt
		
		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)	#9113 l_idx records selected
	
	RETURN l_arr_rec_prodledg	
END FUNCTION
###########################################################################
# END FUNCTION db_prodledg_get_datasource2(p_filter,p_cmpy_code,p_ware_code,p_part_code,p_tran_date)
###########################################################################


############################################################
# FUNCTION prmowind(p_cmpy_code, p_ware_code, p_prod_part_code)
#
# Displays the previous movements
############################################################
FUNCTION prmowind(p_cmpy_code,p_ware_code,p_prod_part_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_prod_part_code LIKE product.part_code 
	DEFINE p_ware_code LIKE prodstatus.ware_code 
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF  
		RECORD 
			tran_date LIKE prodledg.tran_date, 
			year_num LIKE prodledg.year_num, 
			period_num LIKE prodledg.period_num, 
			trantype_ind LIKE prodledg.trantype_ind, 
			source_text LIKE prodledg.source_text, 
			source_num LIKE prodledg.source_num, 
			tran_qty LIKE prodledg.tran_qty, 
			bal_amt LIKE prodledg.bal_amt 
		END RECORD 
	DEFINE l_arr_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_t_prodledg 
		RECORD 
			tran_date LIKE prodledg.tran_date 
		END RECORD 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_idx SMALLINT 
 

		OPEN WINDOW I114 with FORM "I114" 
		CALL windecoration_i("I114") 

		LET l_rec_prodledg.part_code = p_prod_part_code 
		LET l_rec_prodledg.ware_code = p_ware_code 
		SELECT product.desc_text INTO l_arr_rec_product.desc_text FROM product 
		WHERE product.part_code = l_rec_prodledg.part_code 
		AND product.cmpy_code = p_cmpy_code 
		IF status = notfound THEN 
			CALL fgl_winmessage("ERROR",kandoomsg2("U",7001,"Product"),"ERROR")	#7001 "Product RECORD NOT found "
			CLOSE WINDOW I114 
			RETURN 
		END IF 
		
		DISPLAY l_arr_rec_product.desc_text TO product.desc_text 
		DISPLAY l_arr_rec_product.desc2_text TO product.desc2_text 

		SELECT warehouse.desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
		WHERE warehouse.ware_code = l_rec_prodledg.ware_code 
		AND warehouse.cmpy_code = p_cmpy_code 
		IF status = notfound THEN 
			CALL fgl_winmessage("ERROR - Warehouse not found",kandoomsg2("U",7001,"Warehouse"),"ERROR")	#7001 "Warehouse RECORD NOT found "
			CLOSE WINDOW I114 
			RETURN 
		END IF 

		DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 
		DISPLAY BY NAME 
			l_rec_prodledg.part_code, 
			l_rec_prodledg.ware_code 

		CALL db_prodledg_get_datasource2(TRUE,p_cmpy_code,p_ware_code,p_prod_part_code,today()-30) RETURNING l_arr_rec_prodledg
	
		MESSAGE kandoomsg2("U",1008,"")	#1008 F3/F4 TO Page Fwd/Bwd; OK TO Continue
		DISPLAY ARRAY l_arr_rec_prodledg TO sr_prodledg.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","prmowind","display-arr-prodledg") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
				CALL l_arr_rec_prodledg.clear()
				CALL db_prodledg_get_datasource2(TRUE,p_cmpy_code,p_ware_code,p_prod_part_code,today()-30) RETURNING l_arr_rec_prodledg			

			ON ACTION "REFRESH"
				CALL windecoration_i("I114")	
				CALL l_arr_rec_prodledg.clear()
				CALL db_prodledg_get_datasource2(FALSE,p_cmpy_code,p_ware_code,p_prod_part_code,today()-30) RETURNING l_arr_rec_prodledg			

		END DISPLAY 

		LET int_flag = false 
		LET quit_flag = false
		 
		CLOSE WINDOW I114
		 
END FUNCTION 
############################################################
# END FUNCTION prmowind(p_cmpy_code, p_ware_code, p_prod_part_code)
############################################################