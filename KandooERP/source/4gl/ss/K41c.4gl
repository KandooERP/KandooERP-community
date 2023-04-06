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
GLOBALS "K_SS_GLOBALS.4gl" 
GLOBALS "K41_GLOBALS.4gl" 

DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.* 


FUNCTION unit_price(pr_ware_code,pr_part_code,pr_level_ind) 
	DEFINE 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_part_code LIKE prodstatus.part_code, 
	pr_level_ind LIKE customer.inv_level_ind, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_price_amt DECIMAL (10,2), 
	pr_list_amt LIKE prodstatus.list_amt, 
	pr_disc_per LIKE creditdetl.disc_amt 

	SELECT * INTO pr_prodstatus.* FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_ware_code 
	AND part_code = pr_part_code 
	IF status = notfound THEN 
		LET pr_price_amt = modu_rec_creditdetl.unit_sales_amt 
		LET pr_disc_per = modu_rec_creditdetl.unit_tax_amt 
	ELSE 
	CASE pr_level_ind 
		WHEN "1" LET pr_price_amt = pr_prodstatus.price1_amt 
		WHEN "2" LET pr_price_amt = pr_prodstatus.price2_amt 
		WHEN "3" LET pr_price_amt = pr_prodstatus.price3_amt 
		WHEN "4" LET pr_price_amt = pr_prodstatus.price4_amt 
		WHEN "5" LET pr_price_amt = pr_prodstatus.price5_amt 
		WHEN "6" LET pr_price_amt = pr_prodstatus.price6_amt 
		WHEN "7" LET pr_price_amt = pr_prodstatus.price7_amt 
		WHEN "8" LET pr_price_amt = pr_prodstatus.price8_amt 
		WHEN "9" LET pr_price_amt = pr_prodstatus.price9_amt 
		WHEN "L" LET pr_price_amt = pr_prodstatus.list_amt 
		WHEN "C" LET pr_price_amt = pr_prodstatus.wgted_cost_amt 
		OTHERWISE LET pr_price_amt = pr_prodstatus.list_amt 
	END CASE 
	LET pr_price_amt = 
	conv_currency(pr_price_amt,glob_rec_kandoouser.cmpy_code,pr_customer.currency_code,"T", 
	pr_credithead.cred_date,"L") 
	LET pr_list_amt = 
	conv_currency(pr_prodstatus.list_amt,glob_rec_kandoouser.cmpy_code,pr_customer.currency_code,"T", 
	pr_credithead.cred_date,"L") 
	IF pr_price_amt = 0 THEN 
		LET pr_disc_per = 0 
	ELSE 
	LET pr_disc_per = ((pr_list_amt - pr_price_amt)/pr_list_amt) * 100 
END IF 
END IF 
RETURN pr_price_amt, pr_disc_per 
END FUNCTION 


FUNCTION unit_disc(pr_ware_code,pr_part_code,pr_price_amt) 
	DEFINE 
	pr_ware_code LIKE prodstatus.ware_code, 
	pr_part_code LIKE prodstatus.part_code, 
	pr_level_ind LIKE customer.inv_level_ind, 
	pr_price_amt DECIMAL (10,2), 
	pr_list_amt LIKE prodstatus.list_amt, 
	pr_disc_per LIKE creditdetl.disc_amt 

	SELECT list_amt INTO pr_list_amt FROM prodstatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND ware_code = pr_ware_code 
	AND part_code = pr_part_code 
	IF status = notfound THEN 
		LET pr_disc_per = 0 
	ELSE 
	LET pr_list_amt = 
	conv_currency(pr_list_amt,glob_rec_kandoouser.cmpy_code,pr_customer.currency_code,"T", 
	pr_credithead.cred_date,"L") 
	IF pr_price_amt = 0 THEN 
		LET pr_disc_per = 0 
	ELSE 
	LET pr_disc_per = ((pr_list_amt - pr_price_amt)/pr_list_amt) * 100 
END IF 
END IF 
RETURN pr_disc_per 
END FUNCTION 


FUNCTION unit_tax(pr_ware_code,pr_part_code,pr_unit_price_amt,pr_taxcode) 
	DEFINE 
	pr_ware_code LIKE invoicedetl.ware_code, 
	pr_part_code LIKE invoicedetl.part_code, 
	pr_tax RECORD LIKE tax.*, 
	pr_prodstatus RECORD LIKE prodstatus.*, 
	pr_unit_price_amt LIKE invoicedetl.unit_sale_amt, 
	pr_unit_tax_amt LIKE invoicedetl.unit_tax_amt, 
	pr_taxcode LIKE invoicedetl.tax_code 

	SELECT * INTO pr_tax.* FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = pr_credithead.tax_code 
	CASE pr_tax.calc_method_flag 
		WHEN "P" 
			IF pr_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
			SELECT * INTO pr_prodstatus.* FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND ware_code = pr_ware_code 
			SELECT * INTO pr_tax.* FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = pr_prodstatus.sale_tax_code 
			IF pr_tax.calc_method_flag = "D" THEN 
				LET pr_unit_tax_amt = pr_prodstatus.sale_tax_amt 
			ELSE { use product tax code percentage} 
			IF pr_tax.tax_per IS NULL THEN 
				LET pr_tax.tax_per = 0 
			END IF 
			LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_price_amt / 100 
		END IF 
		LET pr_taxcode = pr_prodstatus.sale_tax_code 
	END IF 
		WHEN "D" {product based tax - tax amount} 
			IF pr_part_code IS NULL THEN 
				LET pr_unit_tax_amt = 0 
			ELSE 
			SELECT sale_tax_amt INTO pr_unit_tax_amt FROM prodstatus 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND ware_code = pr_ware_code 
		END IF 
		WHEN "N" ## % FROM tax TABLE - line based 
			LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_price_amt / 100 
		WHEN "T" ## % FROM tax TABLE - inv based 
			SELECT unique 1 FROM product 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND part_code = pr_part_code 
			AND total_tax_flag = "Y" 
			IF sqlca.sqlcode = 0 THEN 
				LET pr_unit_tax_amt = pr_tax.tax_per * pr_unit_price_amt / 100 
			ELSE 
			LET pr_unit_tax_amt = 0 
		END IF 
		OTHERWISE 
			LET pr_unit_tax_amt = 0 
	END CASE 
	RETURN pr_unit_tax_amt, pr_taxcode 
END FUNCTION 


FUNCTION total_box() 
	DEFINE 
	i SMALLINT 

	LET pr_credithead.goods_amt = 0 
	LET pr_credithead.tax_amt = 0 
	LET pr_credithead.cost_amt = 0 
	LET pr_credithead.total_amt = 0 
	FOR i = 1 TO arr_size 
		IF st_creditdetl[i].ext_sales_amt IS NOT NULL THEN 
			LET pr_credithead.goods_amt = pr_credithead.goods_amt 
			+ st_creditdetl[i].ext_sales_amt 
		END IF 
		IF st_creditdetl[i].ext_tax_amt IS NOT NULL THEN 
			LET pr_credithead.tax_amt = pr_credithead.tax_amt 
			+ st_creditdetl[i].ext_tax_amt 
		END IF 
		IF st_creditdetl[i].ext_cost_amt IS NOT NULL THEN 
			LET pr_credithead.cost_amt = pr_credithead.cost_amt 
			+ st_creditdetl[i].ext_cost_amt 
		END IF 
	END FOR 
	LET pr_credithead.total_amt = pr_credithead.goods_amt 
	+ pr_credithead.tax_amt 
	DISPLAY BY NAME pr_credithead.goods_amt, 
	pr_credithead.tax_amt, 
	pr_credithead.total_amt 
	attribute(magenta) 
END FUNCTION 


FUNCTION stat_res(p_cmpy,pr_ware_code,pr_part_code,pr_ship_qty,pr_direction) 
	# a FUNCTION TO handle all warehouse STATUS changes TO be used
	# WHERE ever AND WHEN ever required..
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE pr_ware_code LIKE warehouse.ware_code 
	DEFINE pr_part_code LIKE product.part_code 
	DEFINE pr_ship_qty LIKE creditdetl.ship_qty 
	DEFINE pr_direction CHAR(3) 
	DEFINE pr_prodstatus RECORD LIKE prodstatus.* 
	DEFINE l_sequence INTEGER 
	DEFINE err_continue CHAR(1) 
	DEFINE err_message CHAR(30) 

	IF pr_part_code IS NOT NULL AND pr_ship_qty > 0 THEN 
		GOTO bypass 
		LABEL recovery: 
		LET err_message = "A41_C Itemstat update" 
		LET err_continue = error_recover(err_message, status) 
		IF err_continue != "Y" THEN 
			CALL errorlog("A41_C Itemstat Adjustment NOT done") 
			EXIT program 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 
			DECLARE c_prodstatus CURSOR FOR 
			SELECT * 
			FROM prodstatus 
			WHERE cmpy_code = p_cmpy 
			AND ware_code = pr_ware_code 
			AND part_code = pr_part_code 
			FOR UPDATE 

			FOREACH c_prodstatus INTO pr_prodstatus.* 
				LET pr_prodstatus.seq_num = pr_prodstatus.seq_num + 1 
				LET l_sequence = pr_prodstatus.seq_num 

				IF pr_prodstatus.reserved_qty IS NULL THEN 
					LET pr_prodstatus.reserved_qty = 0 
				END IF 

				# do NOT adjust onhnd VALUES FOR non-stocked inventory items
				IF pr_prodstatus.stocked_flag = "Y" THEN 
					IF pr_direction = TRAN_TYPE_INVOICE_IN THEN 
						LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty - pr_ship_qty 
					ELSE 
					LET pr_prodstatus.reserved_qty = pr_prodstatus.reserved_qty + pr_ship_qty 
				END IF 
			END IF 
			
			UPDATE prodstatus 
			SET 
				reserved_qty = pr_prodstatus.reserved_qty, 
				seq_num = pr_prodstatus.seq_num 
			WHERE CURRENT OF c_prodstatus 
		END FOREACH 
		
		# INSERT INTO statab FOR backout purposes
		IF back_out = 0 THEN 
			INSERT INTO statab VALUES (
				p_cmpy, 
				pr_ware_code, 
				pr_part_code, 
				pr_ship_qty, 
				pr_direction) 
		END IF 
	COMMIT WORK 
	WHENEVER ERROR stop 
END IF 
RETURN l_sequence 
END FUNCTION 
