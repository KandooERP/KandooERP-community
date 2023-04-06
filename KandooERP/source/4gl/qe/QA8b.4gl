{
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

	Source code beautified by beautify.pl on 2020-01-02 09:16:02	$Id: $
}




#   QA8b - Quotation Print Program - site specific

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "Q_QE_GLOBALS.4gl" 
GLOBALS "QA8a_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# REPORT QA8_list(pr_quotehead,pr_quotedetl)
#
#
#######################################################################
REPORT qa8_list(pr_quotehead,pr_quotedetl) 
	DEFINE 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	pr_product RECORD LIKE product.*, 
	pr_customer RECORD LIKE customer.*, 
	pr_term RECORD LIKE term.*, 
	pr_notes RECORD LIKE notes.*, 
	pr_crry_fwd_text CHAR(6), 
	pr_tot_tax_amt, 
	pr_tot_dis_amt, 
	pr_tot_inv_amt LIKE quotehead.total_amt, 
	pr_freight_charge LIKE quotehead.total_amt, 
	pr_float,pr_tax_per FLOAT 

	OUTPUT 
	left margin 1 
	PAGE length 51 
	top margin 2 
	bottom margin 0 
	ORDER external BY pr_quotehead.cust_code, 
	pr_quotehead.order_num, 
	pr_quotedetl.line_num 
	FORMAT 
		PAGE HEADER 
			SELECT * INTO pr_customer.* 
			FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = pr_quotehead.cust_code 
			SKIP 2 LINES 
			PRINT COLUMN 66, "Proforma Invoice:", 
			COLUMN 84, pr_quotehead.order_num USING "<<<<<<<<" 
			SKIP 1 line 
			PRINT COLUMN 76, pr_quotehead.cust_code 
			SKIP 2 LINES 
			PRINT ascii(pr_printcodes.compress_11), 
			ascii(pr_printcodes.compress_12), 
			ascii(pr_printcodes.compress_13), 
			ascii(pr_printcodes.compress_14), 
			ascii(pr_printcodes.compress_15), 
			ascii(pr_printcodes.compress_16), 
			ascii(pr_printcodes.compress_17), 
			ascii(pr_printcodes.compress_18), 
			ascii(pr_printcodes.compress_19), 
			ascii(pr_printcodes.compress_20), 
			COLUMN 16, "QUOTE" 
			CALL pack_address(pr_quotehead.ship_name_text, 
			pr_quotehead.ship_addr1_text, 
			pr_quotehead.ship_addr2_text, 
			pr_quotehead.ship_city_text, 
			pr_quotehead.state_code, 
			pr_quotehead.post_code, 
			pr_quotehead.country_code) --@db-patch_2020_10_04--
			RETURNING pr_quotehead.ship_name_text, 
			pr_quotehead.ship_addr1_text, 
			pr_quotehead.ship_addr2_text, 
			pr_quotehead.ship_city_text, 
			pr_quotehead.country_code--@db-patch_2020_10_04--

			PRINT COLUMN 5, pr_quotehead.ship_name_text, 
			COLUMN 54,pr_quotehead.com1_text 
			PRINT COLUMN 5, pr_quotehead.ship_addr1_text, 
			COLUMN 54,pr_quotehead.com2_text 
			PRINT COLUMN 5, pr_quotehead.ship_addr2_text, 
			COLUMN 54,pr_quotehead.com3_text 
			PRINT COLUMN 5, pr_quotehead.ship_city_text, 
			COLUMN 54,pr_quotehead.com4_text 
			PRINT COLUMN 5, pr_quotehead.country_code --@db-patch_2020_10_04 report--
			SKIP 3 LINES 
			PRINT COLUMN 2, pr_quotehead.quote_date USING "dd mmm yy", 
			COLUMN 12, pr_quotehead.ord_text USING "##########", 
			COLUMN 23, pr_customer.tax_num_text 
			SKIP 2 LINES 
			PRINT COLUMN 36, "Qty", 
			COLUMN 44, "Price", 
			COLUMN 52, "Disc %", 
			COLUMN 60, "Disc", 
			COLUMN 66, "Tax %", 
			COLUMN 74, "Tax ", 
			COLUMN 80, "Total" 
			PRINT ascii(pr_printcodes.compress_1), 
			ascii(pr_printcodes.compress_2), 
			ascii(pr_printcodes.compress_3), 
			ascii(pr_printcodes.compress_4), 
			ascii(pr_printcodes.compress_5), 
			ascii(pr_printcodes.compress_6), 
			ascii(pr_printcodes.compress_7), 
			ascii(pr_printcodes.compress_8), 
			ascii(pr_printcodes.compress_9), 
			ascii(pr_printcodes.compress_10) 
		BEFORE GROUP OF pr_quotehead.order_num 
			SKIP TO top OF PAGE 
			LET pr_tot_tax_amt = 0 
			LET pr_tot_dis_amt = 0 
			LET pr_tot_inv_amt = 0 
			LET pr_crry_fwd_text = "C/FWD" 
		ON EVERY ROW 
			IF pr_quotedetl.part_code IS NULL THEN 
				INITIALIZE pr_product.* TO NULL 
			ELSE 
				SELECT * INTO pr_product.* 
				FROM product 
				WHERE cmpy_code = pr_quotedetl.cmpy_code 
				AND part_code = pr_quotedetl.part_code 
			END IF 
			IF pr_quotedetl.desc_text[1,3] = "###" 
			AND pr_quotedetl.desc_text[16,18] = "###" THEN 
				LET pr_notes.note_code = pr_quotedetl.desc_text[4,15] 
				IF pr_quotedetl.part_code IS NOT NULL THEN 
					LET pr_quotedetl.desc_text = pr_product.desc_text 
				END IF 
			ELSE 
				INITIALIZE pr_notes.* TO NULL 
			END IF 
			### Print Line
			PRINT COLUMN 02,pr_quotedetl.part_code, 
			COLUMN 22,pr_quotedetl.desc_text[1,36]; 
			IF pr_quotedetl.order_qty = 0 THEN 
				PRINT "" 
			ELSE 
				IF pr_quotedetl.list_price_amt < pr_quotedetl.unit_price_amt 
				OR pr_quotedetl.list_price_amt = 0 THEN 
					LET pr_quotedetl.list_price_amt = pr_quotedetl.unit_price_amt 
					LET pr_quotedetl.disc_per = 0 
					LET pr_quotedetl.disc_amt = 0 
				ELSE 
					LET pr_quotedetl.disc_amt = pr_quotedetl.order_qty 
					* (pr_quotedetl.list_price_amt - pr_quotedetl.unit_price_amt) 
					## use temp float variable TO avoid precision errors
					LET pr_float = 100 
					- ((pr_quotedetl.unit_price_amt/pr_quotedetl.list_price_amt)*100) 
					LET pr_quotedetl.disc_per = pr_float 
				END IF 
				## work backwards TO obtain tax
				IF pr_quotedetl.ext_price_amt = 0 THEN 
					LET pr_tax_per = 0 
				ELSE 
					LET pr_tax_per = 100 
					* (pr_quotedetl.ext_tax_amt/pr_quotedetl.ext_price_amt) 
				END IF 
				### Print line information
				PRINT COLUMN 60, pr_quotedetl.order_qty USING "########", 
				COLUMN 74, pr_quotedetl.list_price_amt USING "-------.&&", 
				COLUMN 90, pr_quotedetl.disc_per USING "##&.&&", 
				COLUMN 100, pr_quotedetl.disc_amt USING "-------.&&", 
				COLUMN 114, pr_tax_per USING "##&.&&", 
				COLUMN 122, pr_quotedetl.ext_tax_amt USING "-------.&&", 
				COLUMN 136, pr_quotedetl.line_tot_amt USING "---------.&&" 
			END IF 
			IF pr_notes.note_code IS NOT NULL THEN 
				### Print line item notes
				DECLARE c_notes CURSOR FOR 
				SELECT * FROM notes 
				WHERE cmpy_code = pr_quotedetl.cmpy_code 
				AND note_code = pr_notes.note_code 
				ORDER BY note_code,note_num 
				FOREACH c_notes INTO pr_notes.* 
					PRINT COLUMN 22,pr_notes.note_text 
				END FOREACH 
			END IF 
			LET pr_tot_dis_amt = pr_tot_dis_amt + pr_quotedetl.disc_amt 
			LET pr_tot_tax_amt = pr_tot_tax_amt + pr_quotedetl.ext_tax_amt 
			LET pr_tot_inv_amt = pr_tot_inv_amt + pr_quotedetl.line_tot_amt 
		AFTER GROUP OF pr_quotehead.order_num 
			NEED 2 LINES 
			LET pr_crry_fwd_text = NULL 
			SKIP 1 line 
			IF pr_quotehead.hand_tax_amt = 0 AND pr_quotehead.freight_tax_amt = 0 THEN 
				LET pr_freight_charge = pr_quotehead.freight_amt 
				+ pr_quotehead.hand_amt 
				PRINT COLUMN 22,"Freight & Handling Surcharge", 
				COLUMN 136,(pr_quotehead.freight_amt+ 
				pr_quotehead.hand_amt) USING "---------.&&" 
			ELSE 
				LET pr_freight_charge = pr_quotehead.freight_amt 
				+ pr_quotehead.freight_tax_amt 
				+ pr_quotehead.hand_amt 
				+ pr_quotehead.hand_tax_amt 
				PRINT COLUMN 22, "Freight & Handling Surcharge", 
				COLUMN 122,(pr_quotehead.freight_tax_amt+ 
				pr_quotehead.hand_tax_amt) USING "-------.&&", 
				COLUMN 136,(pr_quotehead.freight_amt+ 
				pr_quotehead.freight_tax_amt+ 
				pr_quotehead.hand_amt+ 
				pr_quotehead.hand_tax_amt) USING "---------.&&" 
			END IF 
			LET pr_tot_tax_amt = pr_tot_tax_amt + pr_quotehead.freight_tax_amt 
			+ pr_quotehead.hand_tax_amt 
			LET pr_tot_inv_amt = pr_tot_inv_amt + pr_freight_charge 
			PAGE TRAILER 
				SKIP 1 line 
				IF pr_crry_fwd_text IS NOT NULL THEN 
					PRINT COLUMN 140, pr_crry_fwd_text 
				ELSE 
					PRINT COLUMN 98, pr_tot_dis_amt USING "---------.&&", 
					COLUMN 120, pr_tot_tax_amt USING "---------.&&", 
					COLUMN 136, pr_tot_inv_amt USING "---------.&&" 
				END IF 
				SELECT desc_text INTO pr_term.desc_text 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = pr_quotehead.term_code 
				PRINT COLUMN 8 ,"Terms : ",pr_term.desc_text 
				PRINT ascii(pr_printcodes.normal_1), ascii(pr_printcodes.normal_2), 
				ascii(pr_printcodes.normal_3), ascii(pr_printcodes.normal_4), 
				ascii(pr_printcodes.normal_5), ascii(pr_printcodes.normal_6), 
				ascii(pr_printcodes.normal_7), ascii(pr_printcodes.normal_8), 
				ascii(pr_printcodes.normal_9), ascii(pr_printcodes.normal_10) 
				LET rpt_pageno = pageno 
END REPORT 
