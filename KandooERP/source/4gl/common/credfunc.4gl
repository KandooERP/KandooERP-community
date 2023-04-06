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
# Requires
# common/note_disp.4gl
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
--DEFINE modu_rec_company RECORD LIKE company.* 


################################################################################
# FUNCTION linecshow(p_cmpy,p_cust_code,p_crednum,p_func_type)
#
#
################################################################################
FUNCTION linecshow(p_cmpy,p_cust_code,p_crednum,p_func_type) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE p_crednum LIKE credithead.cred_num 
	DEFINE p_func_type CHAR(14)
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_company RECORD LIKE company.* 
	DEFINE l_arr_creditdetl ARRAY [300] OF RECORD 
					part_code LIKE creditdetl.part_code, 
					ship_qty LIKE creditdetl.ship_qty, 
					line_text LIKE creditdetl.line_text, 
					unit_sales_amt LIKE creditdetl.unit_sales_amt, 
					line_total_amt LIKE creditdetl.line_total_amt 
			 END RECORD 
	DEFINE l_arr_temp_line_num ARRAY[300] OF INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_gross_dollar MONEY(12,2) 
	DEFINE l_gross_percent DECIMAL(8,3) 
	DEFINE l_markup_percent DECIMAL(8,3)
	DEFINE l_cre_desc CHAR(7) 
	DEFINE l_idx SMALLINT 

	SELECT * INTO l_rec_company.* FROM company 
	WHERE cmpy_code = p_cmpy 

	INITIALIZE l_rec_creditdetl.* TO NULL 

	SELECT * INTO l_rec_credithead.* FROM credithead 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	AND cred_num = p_crednum 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9108,"") 
		#9108 Credithead NOT found
	END IF 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9109,"") 		# 9109 Customer master NOT found
	END IF 

	#get Account Receivable Parameters Record
	CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*


	IF l_rec_arparms.parm_code IS NULL THEN #notfound 
		ERROR kandoomsg2("A",9107,"") 		# 9107 AR Parameters do NOT exist - Refer Menu AZP
	END IF 

	OPEN WINDOW A131 with FORM "A131" 
	CALL windecoration_a("A131") 

	DECLARE curser_item CURSOR FOR 
	SELECT creditdetl.* INTO l_rec_creditdetl.* 
	FROM creditdetl 
	WHERE cred_num = l_rec_credithead.cred_num 
	AND cust_code = l_rec_credithead.cust_code 
	AND cmpy_code = p_cmpy 

	LET l_idx = 0 
	FOREACH curser_item 
		LET l_idx = l_idx + 1 

		IF l_idx > 300 THEN 
			EXIT FOREACH 
		END IF 

		LET l_arr_creditdetl[l_idx].part_code = l_rec_creditdetl.part_code 
		LET l_arr_creditdetl[l_idx].ship_qty = l_rec_creditdetl.ship_qty 
		LET l_arr_creditdetl[l_idx].line_text = l_rec_creditdetl.line_text 
		LET l_arr_creditdetl[l_idx].unit_sales_amt = l_rec_creditdetl.unit_sales_amt 

		IF l_rec_arparms.show_tax_flag = "Y" THEN 
			LET l_arr_creditdetl[l_idx].line_total_amt = l_rec_creditdetl.line_total_amt 
		ELSE 
			LET l_arr_creditdetl[l_idx].line_total_amt = l_rec_creditdetl.unit_sales_amt * l_rec_creditdetl.ship_qty 
		END IF 

		LET l_arr_temp_line_num[l_idx] = l_rec_creditdetl.line_num 

	END FOREACH 

	CALL set_count(l_idx) 
	ERROR kandoomsg2("A",1019,"") 

	DISPLAY BY NAME l_rec_customer.currency_code ATTRIBUTE(green) 

	IF l_rec_arparms.show_tax_flag = "Y" THEN 
		DISPLAY BY NAME l_rec_credithead.cust_code, 
		l_rec_customer.name_text, 
		l_rec_customer.cred_bal_amt, 
		l_rec_creditdetl.ware_code, 
		l_rec_credithead.tax_code, 
		l_rec_customer.inv_level_ind 

		DISPLAY BY NAME 
			l_rec_credithead.goods_amt, 
			l_rec_credithead.tax_amt, 
			l_rec_credithead.total_amt	ATTRIBUTE (magenta) 
	ELSE 
		DISPLAY BY NAME 
			l_rec_credithead.cust_code, 
			l_rec_customer.name_text, 
			l_rec_creditdetl.ware_code, 
			l_rec_credithead.tax_code, 
			l_rec_customer.inv_level_ind, 
			l_rec_credithead.total_amt 

		DISPLAY BY NAME 
			l_rec_credithead.goods_amt, 
			l_rec_credithead.tax_amt, 
			l_rec_credithead.total_amt 

	END IF 

	DISPLAY p_func_type TO func_type 


	DISPLAY ARRAY l_arr_creditdetl TO sr_creditdetl.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","credfunc","display-arr-creditdelt") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-t) 
			# work out invoice totals
			LET l_cre_desc = "Total" 
			LET l_gross_dollar = l_rec_credithead.goods_amt - l_rec_credithead.cost_amt 
			IF l_rec_credithead.goods_amt = 0 
			OR l_rec_credithead.goods_amt IS NULL THEN 
				LET l_gross_percent = 0 
			ELSE 
				LET l_gross_percent = ((l_gross_dollar * 100)/ l_rec_credithead.goods_amt) 
			END IF 
			IF l_rec_credithead.cost_amt = 0 
			OR l_rec_credithead.cost_amt IS NULL THEN 
				LET l_markup_percent = 0 
			ELSE 
				LET l_markup_percent = ((l_gross_dollar * 100)/ l_rec_credithead.cost_amt) 
			END IF 

			OPEN WINDOW wa167 with FORM "A167" # ATTRIBUTE(border) 
			CALL windecoration_a("A167") 

			DISPLAY l_cre_desc TO cre_type 
			DISPLAY l_gross_dollar TO gp_dollar 
			DISPLAY l_gross_percent TO gp 
			DISPLAY l_markup_percent TO mu 
			DISPLAY l_rec_credithead.goods_amt TO mats 
			DISPLAY l_rec_credithead.cost_amt TO costs 
			
			CALL doneprompt(NULL,NULL,NULL)
			
			CLOSE WINDOW wa167 

		ON ACTION "NOTES" --ON KEY (control-n) #??? 
			LET l_idx = arr_curr() 

			IF l_arr_creditdetl[l_idx].line_text[1,3] = "###" 
			AND l_arr_creditdetl[l_idx].line_text[16,18] = "###" THEN 
				CALL note_disp(p_cmpy,l_arr_creditdetl[l_idx].line_text[4,15]) 
			ELSE 
				LET l_msgresp = kandoomsg("A",7027,"") 
				# 7027 No Notes TO view
			END IF 

		ON KEY (tab) #?? edit ? 
			LET l_idx = arr_curr() 

			SELECT * INTO l_rec_creditdetl.* FROM creditdetl 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust_code 
			AND cred_num = p_crednum 
			AND line_num = l_arr_temp_line_num[l_idx] 
			AND ship_qty = l_arr_creditdetl[l_idx].ship_qty 

			CALL cre_show(
				l_rec_creditdetl.part_code, 
				l_rec_creditdetl.ship_qty, 
				l_rec_creditdetl.line_text, 
				l_rec_creditdetl.unit_sales_amt, 
				l_rec_creditdetl.ware_code, 
				l_rec_creditdetl.uom_code, 
				l_rec_creditdetl.unit_tax_amt, 
				l_rec_creditdetl.line_total_amt, 
				l_rec_creditdetl.reason_code, 
				p_cmpy, 
				l_rec_creditdetl.line_acct_code) 

		ON KEY (RETURN) 
			LET l_idx = arr_curr() 

			SELECT * INTO l_rec_creditdetl.* FROM creditdetl 
			WHERE cmpy_code = p_cmpy 
			AND cust_code = p_cust_code 
			AND cred_num = p_crednum 
			AND line_num = l_arr_temp_line_num[l_idx] 
			AND ship_qty = l_arr_creditdetl[l_idx].ship_qty 

			CALL cre_show(
				l_rec_creditdetl.part_code, 
				l_rec_creditdetl.ship_qty, 
				l_rec_creditdetl.line_text, 
				l_rec_creditdetl.unit_sales_amt, 
				l_rec_creditdetl.ware_code, 
				l_rec_creditdetl.uom_code, 
				l_rec_creditdetl.unit_tax_amt, 
				l_rec_creditdetl.line_total_amt, 
				l_rec_creditdetl.reason_code, 
				p_cmpy, 
				l_rec_creditdetl.line_acct_code) 


	END DISPLAY 
	################
	CLOSE WINDOW A131 

	RETURN 
END FUNCTION 
################################################################################
# END FUNCTION linecshow(p_cmpy,p_cust_code,p_crednum,p_func_type)
################################################################################


################################################################################
# FUNCTION cre_show(p_part_code, p_ship_qty, p_line_text, p_unit_sales_amt,
#                  p_ware_code, p_uom_code, p_unit_tax_amt, p_line_total_amt,
#                  p_reason_code, p_cmpy, p_line_acct_code)
#
################################################################################
FUNCTION cre_show(p_part_code, p_ship_qty, p_line_text, p_unit_sales_amt, 
	p_ware_code, p_uom_code, p_unit_tax_amt, p_line_total_amt, 
	p_reason_code, p_cmpy, p_line_acct_code) 
	DEFINE p_part_code LIKE creditdetl.part_code 
	DEFINE p_ship_qty LIKE creditdetl.ship_qty 
	DEFINE p_line_text LIKE creditdetl.line_text 
	DEFINE p_unit_sales_amt LIKE creditdetl.unit_sales_amt 
	DEFINE p_ware_code LIKE creditdetl.ware_code 
	DEFINE p_uom_code LIKE creditdetl.uom_code 
	DEFINE p_unit_tax_amt LIKE creditdetl.unit_tax_amt 
	DEFINE p_line_total_amt LIKE creditdetl.line_total_amt 
	DEFINE p_reason_code LIKE creditdetl.reason_code 
	DEFINE p_cmpy LIKE creditdetl.cmpy_code 
	DEFINE p_line_acct_code LIKE creditdetl.line_acct_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 

	LET l_rec_creditdetl.part_code = p_part_code 
	LET l_rec_creditdetl.ship_qty = p_ship_qty 
	LET l_rec_creditdetl.line_text = p_line_text 
	LET l_rec_creditdetl.unit_sales_amt = p_unit_sales_amt 
	LET l_rec_creditdetl.ware_code = p_ware_code 
	LET l_rec_creditdetl.uom_code = p_uom_code 
	LET l_rec_creditdetl.unit_tax_amt = p_unit_tax_amt 
	LET l_rec_creditdetl.reason_code = p_reason_code 

	IF l_rec_arparms.show_tax_flag = "Y" THEN 
		LET l_rec_creditdetl.line_total_amt = p_line_total_amt 
	ELSE 
		LET l_rec_creditdetl.line_total_amt = p_unit_sales_amt * p_ship_qty 
	END IF 

	LET l_rec_creditdetl.cmpy_code = p_cmpy 
	LET l_rec_creditdetl.line_acct_code = p_line_acct_code 

	OPEN WINDOW wa132b with FORM "A132" #ATTRIBUTE(border) 
	CALL windecoration_a("A132") 

	SELECT reason_text INTO l_rec_credreas.reason_text 
	FROM credreas 
	WHERE cmpy_code = p_cmpy 
	AND reason_code = l_rec_creditdetl.reason_code 

	IF status = notfound THEN 
		LET l_rec_credreas.reason_text = NULL 
	END IF 

	DISPLAY BY NAME 
		l_rec_creditdetl.part_code, 
		l_rec_creditdetl.ship_qty, 
		l_rec_creditdetl.line_text, 
		l_rec_creditdetl.uom_code, 
		l_rec_creditdetl.level_code, 
		l_rec_creditdetl.unit_sales_amt, 
		l_rec_creditdetl.reason_code, 
		l_rec_credreas.reason_text, 
		l_rec_creditdetl.unit_tax_amt, 
		l_rec_creditdetl.unit_sales_amt, 
		l_rec_creditdetl.line_total_amt 

	DISPLAY l_rec_creditdetl.ware_code TO st_ware ATTRIBUTE(yellow) 

	LET l_rec_coa.acct_code = l_rec_creditdetl.line_acct_code 

	OPEN WINDOW wa104 with FORM "A104" #ATTRIBUTEs (border) 
	CALL windecoration_a("A104") -- albo kd-767 

	DISPLAY l_rec_coa.acct_code TO coa.acct_code
	DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_coa.acct_code) TO coa.desc_text 

	LET l_msgresp = kandoomsg("A",7001,"") 
	# 7001 Any Key TO Continue

	CLOSE WINDOW wa104 
	CLOSE WINDOW wa132b 

END FUNCTION 
################################################################################
# END FUNCTION cre_show(p_part_code, p_ship_qty, p_line_text, p_unit_sales_amt,
#                  p_ware_code, p_uom_code, p_unit_tax_amt, p_line_total_amt,
#                  p_reason_code, p_cmpy, p_line_acct_code)
################################################################################