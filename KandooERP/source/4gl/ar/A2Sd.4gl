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
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"
GLOBALS "../ar/A2S_GLOBALS.4gl" 
###########################################################################
# FUNCTION display_price() 
#
#
###########################################################################
FUNCTION display_price() 

	IF glob_rec_invoicedetl.part_code IS NOT NULL THEN 
		CASE (glob_rec_invoicedetl.level_code) 
			WHEN "1" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price1_amt 
			WHEN "2" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price2_amt 
			WHEN "3" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price3_amt 
			WHEN "4" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price4_amt 
			WHEN "5" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price5_amt 
			WHEN "6" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price6_amt 
			WHEN "7" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price7_amt 
			WHEN "8" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price8_amt 
			WHEN "9" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.price9_amt 
			WHEN "L" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.list_amt 
			WHEN "C" LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.wgted_cost_amt 
			OTHERWISE 
				LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_prodstatus.list_amt 
		END CASE 
	END IF 

	LET glob_rec_invoicedetl.unit_sale_amt = glob_rec_invoicedetl.unit_sale_amt *	glob_rec_invoicehead.conv_qty 

	IF glob_rec_invoicedetl.unit_sale_amt IS NULL THEN 
		LET glob_rec_invoicedetl.unit_sale_amt = 0 
	END IF 

	DISPLAY BY NAME glob_rec_invoicedetl.unit_sale_amt 
END FUNCTION 
###########################################################################
# END FUNCTION display_price() 
###########################################################################


###########################################################################
# FUNCTION plusln(p_ln_idx) 
#
#
###########################################################################
FUNCTION plusln(p_ln_idx) 
	DEFINE p_ln_idx SMALLINT
	DEFINE l_tax_idx SMALLINT 

	IF glob_arr_rec_st_invoicedetl[p_ln_idx].ext_sale_amt IS NOT NULL THEN 
		LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt +	glob_arr_rec_st_invoicedetl[p_ln_idx].ext_sale_amt 
		LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.total_amt +	glob_arr_rec_st_invoicedetl[p_ln_idx].ext_sale_amt 
	END IF 

	IF glob_arr_rec_st_invoicedetl[p_ln_idx].ext_tax_amt IS NOT NULL THEN 
		CALL find_taxcode(glob_arr_rec_st_invoicedetl[p_ln_idx].tax_code) RETURNING l_tax_idx 

		IF p_ln_idx = 1 THEN 
			LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = 0 
		END IF 

		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt +	glob_arr_rec_st_invoicedetl[p_ln_idx].ext_tax_amt 
		CALL total_tax() 
		LET glob_rec_invoicehead.total_amt = 
			glob_rec_invoicehead.goods_amt + 
			glob_rec_invoicehead.hand_amt + 
			glob_rec_invoicehead.freight_amt + 
			glob_rec_invoicehead.tax_amt 
	END IF 

	IF glob_arr_rec_st_invoicedetl[p_ln_idx].ext_cost_amt IS NOT NULL THEN 
		LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt +	glob_arr_rec_st_invoicedetl[p_ln_idx].ext_cost_amt 
	END IF 
END FUNCTION 
###########################################################################
# END FUNCTION plusln(p_ln_idx) 
###########################################################################


############################################################
# FUNCTION plusline() 
#
#
############################################################
FUNCTION plusline() 
	DEFINE l_tax_idx SMALLINT 

	# adjust the invoice header totals

	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt IS NOT NULL THEN 
		IF glob_recalc = "Y" THEN 
			LET glob_rec_invoicehead.goods_amt = 0 
			LET glob_rec_invoicehead.total_amt = 0 
			FOR glob_i = 1 TO glob_tot_lines 
				LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt +	glob_arr_rec_st_invoicedetl[glob_i].ext_sale_amt 
				LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.total_amt +	glob_arr_rec_st_invoicedetl[glob_i].ext_sale_amt 
			END FOR 
		ELSE 
			LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt + glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.total_amt + glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt 
		END IF 
	END IF 

	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_tax_amt IS NOT NULL THEN 
		CALL find_taxcode(glob_arr_rec_st_invoicedetl[glob_idx].tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt +	glob_arr_rec_st_invoicedetl[glob_idx].ext_tax_amt 
		CALL total_tax() 

		IF glob_recalc = "Y" THEN 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt + glob_rec_invoicehead.tax_amt 
		ELSE 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt 
			+ glob_rec_invoicehead.hand_amt 
			+ glob_rec_invoicehead.freight_amt 
			+ glob_rec_invoicehead.tax_amt 
		END IF 
	END IF 
	
	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_cost_amt IS NOT NULL THEN 
		LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt +	glob_arr_rec_st_invoicedetl[glob_idx].ext_cost_amt 
	END IF 
	
	DISPLAY BY NAME 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.total_amt attribute (magenta) 
END FUNCTION 
############################################################
# END FUNCTION plusline() 
############################################################


############################################################
# FUNCTION minusline() 
#
#
############################################################
FUNCTION minusline() 
	DEFINE l_tax_idx SMALLINT 

	# adjust the invoice header totals
	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt IS NOT NULL THEN 
		LET glob_rec_invoicehead.goods_amt = glob_rec_invoicehead.goods_amt - glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt 
		LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.total_amt - glob_arr_rec_st_invoicedetl[glob_idx].ext_sale_amt 
	END IF 
	
	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_tax_amt IS NOT NULL THEN 
		CALL find_taxcode(glob_arr_rec_st_invoicedetl[glob_idx].tax_code) RETURNING l_tax_idx 
		LET glob_arr_rec_taxamt[l_tax_idx].tax_amt = glob_arr_rec_taxamt[l_tax_idx].tax_amt - glob_arr_rec_st_invoicedetl[glob_idx].ext_tax_amt 
		CALL total_tax() 
		IF glob_recalc = "Y" THEN 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt + 	glob_rec_invoicehead.tax_amt 
		ELSE 
			LET glob_rec_invoicehead.total_amt = glob_rec_invoicehead.goods_amt + glob_rec_invoicehead.hand_amt + glob_rec_invoicehead.freight_amt + 	glob_rec_invoicehead.tax_amt 
		END IF 
	END IF 
	
	IF glob_arr_rec_st_invoicedetl[glob_idx].ext_cost_amt IS NOT NULL THEN 
		LET glob_rec_invoicehead.cost_amt = glob_rec_invoicehead.cost_amt - glob_arr_rec_st_invoicedetl[glob_idx].ext_cost_amt 
	END IF 

	DISPLAY BY NAME 
		glob_rec_invoicehead.goods_amt, 
		glob_rec_invoicehead.tax_amt, 
		glob_rec_invoicehead.total_amt attribute (magenta) 
END FUNCTION 
############################################################
# END FUNCTION minusline() 
############################################################


############################################################
# FUNCTION get_acct() 
#
#
############################################################
FUNCTION get_acct() 
	DEFINE l_rec_coa RECORD LIKE coa.*
	DEFINE l_rec_tax RECORD LIKE tax.* 

	LET l_rec_coa.acct_code = glob_rec_invoicedetl.line_acct_code 
	IF glob_rec_invoicehead.tax_code IS NOT NULL THEN 

		OPEN WINDOW A104 with FORM "A104" 
		CALL windecoration_a("A104") 

		DISPLAY BY NAME l_rec_coa.acct_code 

		INPUT l_rec_coa.acct_code WITHOUT DEFAULTS from coa.acct_code ATTRIBUTE(UNBUFFERED) 
			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A2Sd","inp-acct_code-1") 
				DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text
				
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (acct_code) 
						LET l_rec_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME l_rec_coa.acct_code 
						NEXT FIELD acct_code 

		ON CHANGE acct_code
			DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text

			AFTER FIELD acct_code 
				IF l_rec_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required" 
					NEXT FIELD acct_code 
				END IF 

			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					LET int_flag = 0 
					LET quit_flag = 0 
					LET glob_del_yes = "Y" 
					EXIT INPUT 
				END IF 

				CALL verify_acct_code(
					glob_rec_kandoouser.cmpy_code, 
					l_rec_coa.acct_code, 
					glob_rec_invoicehead.year_num, 
					glob_rec_invoicehead.period_num) 
				RETURNING l_rec_coa.* 

				IF l_rec_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required" 
					NEXT FIELD acct_code 
				END IF 
				
				LET glob_del_yes = "N" 

		END INPUT
		 
		CLOSE WINDOW A104 
		LET glob_rec_invoicedetl.line_acct_code = l_rec_coa.acct_code 
		RETURN glob_del_yes 

	ELSE 
		OPEN WINDOW A208 with FORM "A208" 
		CALL windecoration_a("A208") 

		DISPLAY BY NAME l_rec_coa.acct_code,glob_rec_invoicedetl.tax_code 
		INPUT BY NAME l_rec_coa.acct_code,glob_rec_invoicedetl.tax_code WITHOUT DEFAULTS 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","A2Sd","inp-acct_code-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP" infield (acct_code) 
						LET l_rec_coa.acct_code = show_acct(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME l_rec_coa.acct_code 
						NEXT FIELD acct_code 

			ON ACTION "LOOKUP" infield (tax_code) 
						LET glob_rec_invoicedetl.tax_code = show_tax(glob_rec_kandoouser.cmpy_code) 
						DISPLAY BY NAME glob_rec_invoicedetl.tax_code 
						NEXT FIELD tax_code 

				 
			AFTER FIELD acct_code 
				IF l_rec_coa.acct_code IS NULL THEN 
					ERROR " Account Number IS required, try window" 
					NEXT FIELD acct_code 
				END IF
				 
			AFTER FIELD tax_code 
				IF glob_rec_invoicedetl.tax_code IS NULL AND 
				glob_rec_arparms.inven_tax_flag = "3" THEN 
					ERROR " Tax Code IS required, try window" 
					NEXT FIELD tax_code 
				END IF
				 
			AFTER INPUT 
				SELECT * 
				INTO l_rec_coa.* 
				FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = l_rec_coa.acct_code 
				
				IF status = NOTFOUND THEN 
					ERROR " Account NOT found" 
					NEXT FIELD acct_code 
				END IF 
				
				IF glob_rec_invoicedetl.tax_code IS NOT NULL THEN 
					SELECT * 
					INTO l_rec_tax.* 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = glob_rec_invoicedetl.tax_code 
					IF status = NOTFOUND THEN 
						ERROR " Tax code NOT found" 
						NEXT FIELD tax_code 
					END IF 
				END IF 
		END INPUT 
		
		CLOSE WINDOW A208 
	END IF
	 
	LET glob_rec_invoicedetl.line_acct_code = l_rec_coa.acct_code 

	LET glob_del_yes = "N" 
	RETURN glob_del_yes 
END FUNCTION 
############################################################
# END FUNCTION get_acct() 
############################################################