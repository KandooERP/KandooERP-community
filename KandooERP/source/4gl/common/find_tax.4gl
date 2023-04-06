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
# Module  : find_tax.4gl
# Purpose : Calculates AND returns unit AND line tax amounts
#         : AND line totals
#
# How TO use find_tax:
#
# You must feed find_tax a taxcode, a unit_price, a qty AND a type
# valid types as follows:
#
#  F = freight tax, calculate AND RETURN based on amt
#  H = handling tax, calculate AND RETURN based on amt
#  P = ordinary purchase line
#  S = ordinary sales line
#
# Note: That you should also feed find_tax a part AND warehouse OR resource
#       code so that it can determine whether TO include this line in a total
#       tax calculation IF no product OR resource IS feed THEN the line IS
#       assumed TO be included in total tax calculations


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

--GLOBALS 
--	DEFINE 
--	pr_tax RECORD LIKE tax.* 
--END GLOBALS 

############################################################
# FUNCTION find_tax(p_taxcode,p_part,p_ware,p_num_lines,p_line_num,p_unit_price,p_qty,p_type,p_start_date,p_end_date)
#
#
############################################################
FUNCTION find_tax(p_taxcode,p_part,p_ware,p_num_lines,p_line_num,p_unit_price,p_qty,p_type,p_start_date,p_end_date) 
	DEFINE p_taxcode LIKE tax.tax_code 
	DEFINE p_part LIKE product.part_code 
	DEFINE p_ware LIKE warehouse.ware_code 
	DEFINE p_num_lines SMALLINT
	DEFINE p_line_num SMALLINT 
	DEFINE p_unit_price LIKE orderdetl.unit_price_amt 
	DEFINE p_qty LIKE orderdetl.order_qty 
	DEFINE p_type CHAR(1) 
	DEFINE p_start_date DATE
	DEFINE p_end_date DATE 
	DEFINE l_unit_tax LIKE orderdetl.unit_tax_amt 
	DEFINE l_line_tot LIKE orderdetl.line_tot_amt 
	DEFINE l_ext_tax LIKE orderdetl.ext_tax_amt 
	DEFINE l_ext_price LIKE orderdetl.ext_price_amt 
	DEFINE l_diff LIKE orderdetl.ext_tax_amt
	DEFINE l_actual_tax LIKE orderdetl.ext_tax_amt
	DEFINE l_true_tax LIKE orderdetl.ext_tax_amt 
	DEFINE l_prod_tax LIKE prodstatus.purch_tax_code 
	DEFINE l_prod_amt LIKE prodstatus.purch_tax_amt 
	DEFINE l_tax_flag LIKE tax.calc_method_flag 
	DEFINE l_tax_percentage LIKE tax.tax_per 
	DEFINE l_msgresp CHAR(1)
	DEFINE l_total_flag CHAR(1) 
	DEFINE l_tax_days INTEGER
	DEFINE l_service_days INTEGER 
	DEFINE l_tax_ratio DECIMAL(16,4) 
  DEFINE l_total_amt LIKE orderdetl.line_tot_amt 
	DEFINE l_tax_amt DYNAMIC ARRAY OF MONEY(16,4)
	DEFINE x SMALLINT
	DEFINE l_rec_tax RECORD LIKE tax.* 

	IF p_type NOT matches '[lfhps]' THEN 
		LET l_msgresp = kandoomsg("U",7052,"")	#7052 Logic Error: Type does NOT exist.
		RETURN 0, 0, 0, 0, "" 
	END IF 
	
	# variable initialisation
	LET l_ext_price = 0 
	LET l_unit_tax = 0 
	LET l_ext_tax = 0 
	LET l_line_tot = 0 
	IF l_total_amt IS NULL THEN 
		LET l_total_amt = 0 
	END IF
	 
	IF l_true_tax IS NULL THEN 
		LET l_true_tax = 0 
	END IF
	 
	IF l_diff IS NULL THEN 
		LET l_diff = 0 
	END IF
	 
	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = p_taxcode
	 
	IF p_type = "F" THEN 
		LET l_unit_tax = l_rec_tax.freight_per * p_unit_price / 100 
	ELSE 
		IF p_type = "H" THEN 
			LET l_unit_tax = l_rec_tax.hand_per * p_unit_price / 100 
		ELSE 
			IF p_type = "P" THEN 
				SELECT prodstatus.purch_tax_code, prodstatus.purch_tax_amt 
				INTO l_prod_tax, l_prod_amt 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_part 
				AND ware_code = p_ware 
			ELSE 
				SELECT prodstatus.sale_tax_code, prodstatus.sale_tax_amt 
				INTO l_prod_tax, l_prod_amt 
				FROM prodstatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND part_code = p_part 
				AND ware_code = p_ware 
			END IF 

			CASE 

				WHEN (l_rec_tax.calc_method_flag = "P") {product based tax - tax code} 
					IF l_prod_tax IS NULL THEN 
						SELECT jmresource.tax_code, jmresource.tax_amt 
						INTO l_prod_tax, l_prod_amt 
						FROM jmresource 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND res_code = part 
						IF l_prod_tax IS NULL THEN 
							LET l_prod_tax = l_rec_tax.tax_code 
							LET l_prod_amt = p_unit_price 
						END IF 
					END IF 
					SELECT calc_method_flag, tax_per 
					INTO l_tax_flag, l_tax_percentage 
					FROM tax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_code = l_prod_tax 
					IF l_tax_percentage IS NULL THEN 
						LET l_tax_percentage = 0 
					END IF 

					CASE 
						WHEN (l_tax_flag = "D") {use product dollar tax amount} 
							LET l_ext_price = p_unit_price * p_qty 
							LET l_unit_tax = l_prod_amt 
							LET l_ext_tax = l_unit_tax * p_qty 
							LET l_line_tot = (p_unit_price + l_unit_tax) * p_qty 
						OTHERWISE {use product tax code percentage} 
							LET l_ext_price = p_unit_price * p_qty 
							LET l_unit_tax = l_tax_percentage * p_unit_price / 100 
							LET l_ext_tax = l_unit_tax * p_qty 
							LET l_line_tot = (p_unit_price + l_unit_tax) * p_qty 
					END CASE 
					LET p_taxcode = l_prod_tax 

				WHEN (l_rec_tax.calc_method_flag = "D") {prod based tax - tax amount} 
					IF l_prod_tax IS NULL THEN 
						SELECT jmresource.tax_code, 
						jmresource.tax_amt INTO l_prod_tax, 
						l_prod_amt 
						FROM jmresource 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND res_code = p_part 
						IF l_prod_tax IS NULL THEN 
							LET l_prod_tax = l_rec_tax.tax_code 
							LET l_prod_amt = p_unit_price 
						END IF 
					END IF 
					LET l_ext_price = p_unit_price * p_qty 
					LET l_unit_tax = l_prod_amt 
					LET l_ext_tax = l_unit_tax * p_qty 
					LET l_line_tot = (p_unit_price + l_unit_tax) * p_qty 

				WHEN (l_rec_tax.calc_method_flag = "N") {% FROM tax TABLE - line based} 
					LET l_ext_price = p_unit_price * p_qty 
					LET l_unit_tax = l_rec_tax.tax_per * p_unit_price / 100 
					LET l_ext_tax = l_unit_tax * p_qty 
					LET l_line_tot = (p_unit_price + l_unit_tax) * p_qty 

				WHEN (l_rec_tax.calc_method_flag = "T") {% FROM tax TABLE - inv based} 
					# check IF the product should be included in the tax calculation
					LET l_tax_ratio = 1 
					SELECT total_tax_flag INTO l_total_flag 
					FROM product 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND part_code = p_part 
					IF status = notfound THEN 
						SELECT total_tax_flag INTO l_total_flag 
						FROM jmresource 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND res_code = p_part 
					END IF 

					# IF no product IS passed THEN assume this line
					# IS included in total tax calc - this IS used FOR
					# JM fixed price jobs which have tax calculated independant
					# of the products OR resources allocated TO the job.
					IF p_part IS NULL OR p_part = " " THEN 
						LET l_total_flag = "Y" 
					END IF 

					IF l_total_flag = "N" THEN 
						LET l_ext_price = p_unit_price * p_qty 
						LET l_unit_tax = 0 
						LET l_ext_tax = 0 
						LET l_line_tot = p_unit_price * p_qty 
					ELSE 
						IF l_rec_tax.start_date IS NOT NULL 
						AND l_rec_tax.start_date != "31/12/1899" 
						AND p_start_date IS NOT NULL 
						AND p_start_date != "31/12/1899" 
						AND p_end_date IS NOT NULL 
						AND p_end_date != "31/12/1899" THEN 
							IF l_rec_tax.start_date <= p_start_date THEN 
								LET l_tax_ratio = 1 
							ELSE 
								IF l_rec_tax.start_date > p_end_date THEN 
									LET l_tax_ratio = 0 
								ELSE 
									LET l_service_days = (p_end_date - p_start_date) + 1 
									LET l_tax_days = (p_end_date - l_rec_tax.start_date) + 1 
									LET l_tax_ratio = l_tax_days/l_service_days 
								END IF 
							END IF 
						ELSE 
							LET l_tax_ratio = 1 
						END IF 

						IF p_line_num = 0 THEN 
							LET l_ext_price = p_unit_price * p_qty 
							LET l_unit_tax = (l_rec_tax.tax_per * p_unit_price / 100) 
							* l_tax_ratio 
							LET l_ext_tax = l_unit_tax * p_qty 
							LET l_line_tot = l_ext_price + l_ext_tax 

						ELSE 

							IF p_line_num = 1 THEN 
								LET l_total_amt = 0 
								LET l_true_tax = 0 
								LET l_diff = 0 
								FOR x = 1 TO 800 
									LET l_tax_amt[x] = 0 
								END FOR 
							END IF 

							LET l_total_amt = l_total_amt + (p_unit_price * p_qty) 
							LET l_tax_amt[p_line_num] = (p_unit_price * p_qty * l_rec_tax.tax_per / 100 ) * l_tax_ratio 
							LET l_true_tax = (l_rec_tax.tax_per / 100 * l_total_amt) * l_tax_ratio 
							LET l_actual_tax = 0 

							FOR x = 1 TO p_num_lines 
								IF l_tax_amt[x]is NULL THEN 
									LET l_tax_amt[x] = 0 
								END IF 
								LET l_actual_tax = l_actual_tax + l_tax_amt[x] 
							END FOR 
							LET l_diff = l_actual_tax - l_true_tax 
							LET l_tax_amt[p_line_num] = l_tax_amt[p_line_num] - l_diff 
							LET l_unit_tax = (p_unit_price * l_rec_tax.tax_per / 100) * l_tax_ratio 
							LET l_ext_price = p_unit_price * p_qty 
							LET l_ext_tax = l_tax_amt[p_line_num] 
							LET l_line_tot = ((p_unit_price * p_qty * l_rec_tax.tax_per / 100) * l_tax_ratio) + (p_unit_price * p_qty) 
						END IF 
					END IF 

				OTHERWISE 
					LET l_ext_price = p_unit_price * p_qty 
					LET l_unit_tax = 0 
					LET l_ext_tax = 0 
					LET l_line_tot = (p_unit_price + l_unit_tax) * p_qty 

			END CASE #-------------------------------------------------------------------------------------------- 

		END IF 
	END IF
	 
	IF l_line_tot != (l_ext_price + l_ext_tax) THEN 
		LET l_diff = l_line_tot - (l_ext_price + l_ext_tax) 
		LET l_line_tot = l_line_tot - l_diff 
	END IF 
	
	RETURN l_ext_price, 
	l_unit_tax, 
	l_ext_tax, 
	l_line_tot, 
	p_taxcode 
END FUNCTION 
############################################################
# END FUNCTION find_tax(p_taxcode,p_part,p_ware,p_num_lines,p_line_num,p_unit_price,p_qty,p_type,p_start_date,p_end_date)
############################################################