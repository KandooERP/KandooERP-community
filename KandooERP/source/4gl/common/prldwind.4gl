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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION db_prodledg_get_datasource(p_filter,p_cmpy,p_prod_part_code)
#
# prldwind allows the user TO look AT product ledger
############################################################
FUNCTION db_prodledg_get_datasource(p_filter,p_cmpy,p_prod_part_code)
	DEFINE p_filter BOOLEAN 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_prod_part_code LIKE product.part_code 
 
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF # array[200] OF RECORD  
		RECORD  
			tran_date LIKE prodledg.tran_date, 
			year_num LIKE prodledg.year_num, 
			period_num LIKE prodledg.period_num, 
			trantype_ind LIKE prodledg.trantype_ind,
			source_code LIKE prodledg.source_code, 
			source_text LIKE prodledg.source_text, 
			source_num LIKE prodledg.source_num, 
			tran_qty LIKE prodledg.tran_qty, 
			cost_amt LIKE prodledg.cost_amt, 
			sales_amt LIKE prodledg.sales_amt 
		END RECORD 
	DEFINE l_rec_t_prodledg 
		RECORD 
			tran_date LIKE prodledg.tran_date 
		END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_idx SMALLINT 

		LET l_rec_prodledg.part_code = p_prod_part_code


		LET l_rec_t_prodledg.tran_date = today - 30 
		MESSAGE kandoomsg2("U",1001,"") 		#1001 Enter Selection Criteria;  OK TO Continue
		INPUT  
			l_rec_prodledg.ware_code,			
			l_rec_t_prodledg.tran_date WITHOUT DEFAULTS #was l_rec_t_prodledg.tran_date WITHOUT DEFAULTS which is in the array
		FROM
			prodledg.ware_code,
			filter_tran_date
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","prldwind","input-prodledg") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (ware_code) 
				LET l_rec_prodledg.ware_code = show_ware(p_cmpy) 
				DISPLAY BY NAME l_rec_prodledg.ware_code 

				NEXT FIELD ware_code 

			AFTER FIELD ware_code 
				SELECT desc_text INTO l_rec_warehouse.desc_text FROM warehouse 
				WHERE ware_code = l_rec_prodledg.ware_code 
				AND cmpy_code = p_cmpy 
				IF status = notfound THEN 
					ERROR kandoomsg2("U",9105,"") 					#9104 RECORD Not Found, Try Window
					NEXT FIELD ware_code 
				ELSE 
					DISPLAY l_rec_warehouse.desc_text TO warehouse.desc_text 

				END IF 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CLOSE WINDOW I112 
			RETURN 
		END IF 
		
		DECLARE ledg CURSOR FOR 
		SELECT prodledg.* INTO l_rec_prodledg.* 
		FROM prodledg 
		WHERE part_code = l_rec_prodledg.part_code 
		AND ware_code = l_rec_prodledg.ware_code 
		AND cmpy_code = p_cmpy 
		AND tran_date >= l_rec_t_prodledg.tran_date 
		ORDER BY seq_num 

		LET l_idx = 0 
		FOREACH ledg 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_prodledg[l_idx].tran_date = l_rec_prodledg.tran_date 
			LET l_arr_rec_prodledg[l_idx].year_num = l_rec_prodledg.year_num 
			LET l_arr_rec_prodledg[l_idx].period_num = l_rec_prodledg.period_num 
			LET l_arr_rec_prodledg[l_idx].trantype_ind = l_rec_prodledg.trantype_ind
			LET l_arr_rec_prodledg[l_idx].source_code = l_rec_prodledg.source_code 
			LET l_arr_rec_prodledg[l_idx].source_text = l_rec_prodledg.source_text 
			LET l_arr_rec_prodledg[l_idx].source_num = l_rec_prodledg.source_num 
			LET l_arr_rec_prodledg[l_idx].tran_qty = l_rec_prodledg.tran_qty 
			LET l_arr_rec_prodledg[l_idx].cost_amt = l_rec_prodledg.cost_amt 
			LET l_arr_rec_prodledg[l_idx].sales_amt = l_rec_prodledg.sales_amt 

			IF l_idx = glob_rec_settings.maxListArraySize THEN
				MESSAGE kandoomsg2("U",6100,l_idx)
				EXIT FOREACH
			END IF	
		END FOREACH 

		MESSAGE kandoomsg2("U",9113,l_idx)		#9113 l_idx records selected

	RETURN l_arr_rec_prodledg
END FUNCTION
############################################################
# FUNCTION db_prodledg_get_datasource(p_filter,p_cmpy,p_prod_part_code)
#
# prldwind allows the user TO look AT product ledger
############################################################
FUNCTION prldwind(p_cmpy,p_prod_part_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_prod_part_code LIKE product.part_code 
	DEFINE l_arr_rec_prodledg DYNAMIC ARRAY OF # array[200] OF RECORD  
		RECORD  
			tran_date LIKE prodledg.tran_date, 
			year_num LIKE prodledg.year_num, 
			period_num LIKE prodledg.period_num, 
			trantype_ind LIKE prodledg.trantype_ind,
			source_code LIKE prodledg.source_code, 
			source_text LIKE prodledg.source_text, 
			source_num LIKE prodledg.source_num, 
			tran_qty LIKE prodledg.tran_qty, 
			cost_amt LIKE prodledg.cost_amt, 
			sales_amt LIKE prodledg.sales_amt 
		END RECORD 
	DEFINE l_rec_t_prodledg 
		RECORD 
			tran_date LIKE prodledg.tran_date 
		END RECORD 
	DEFINE l_rec_product RECORD LIKE product.* 
	DEFINE l_rec_prodledg RECORD LIKE prodledg.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_idx SMALLINT 

		LET l_rec_prodledg.part_code = p_prod_part_code
		 
		SELECT desc_text, desc2_text 
		INTO l_rec_product.desc_text, l_rec_product.desc2_text 
		FROM product 
		WHERE part_code = l_rec_prodledg.part_code 
		AND cmpy_code = p_cmpy 
		IF status = notfound THEN 
			ERROR kandoomsg2("U",7001,"Product") 			#7001 Product RECORD NOT found
			RETURN 
		END IF 

		OPEN WINDOW I112 with FORM "I112" 
		CALL windecoration_i("I112") 

		DISPLAY l_rec_product.desc_text TO product.desc_text 
		DISPLAY l_rec_product.desc2_text TO product.desc2_text 

		DISPLAY BY NAME l_rec_prodledg.part_code 

	CALL db_prodledg_get_datasource(TRUE,p_cmpy,p_prod_part_code) RETURNING l_arr_rec_prodledg

		MESSAGE kandoomsg2("U",1008,"") 	#1008 F3/F4 TO Page Fwd/Bwd; OK TO Continue
		DISPLAY ARRAY l_arr_rec_prodledg TO sr_prodledg.* ATTRIBUTE(UNBUFFERED) 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","prldwind","display-arr-prodledg") 

			ON ACTION "FILTER"
				CALL l_arr_rec_prodledg.clear()
				CALL db_prodledg_get_datasource(TRUE,p_cmpy,p_prod_part_code) RETURNING l_arr_rec_prodledg

			ON ACTION "REFRESH"
				CALL windecoration_i("I112")  
				CALL l_arr_rec_prodledg.clear()
				CALL db_prodledg_get_datasource(FALSE,p_cmpy,p_prod_part_code) RETURNING l_arr_rec_prodledg
			
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END DISPLAY 

		LET int_flag = false 
		LET quit_flag = false 

		CLOSE WINDOW I112 

END FUNCTION 
############################################################
# END FUNCTION prldwind(p_cmpy, p_prod_part_code)
############################################################