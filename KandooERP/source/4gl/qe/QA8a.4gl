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
GLOBALS "Q_QE_GLOBALS.4gl" 
GLOBALS "QA8a_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# REPORT QA8_list(pr_quotehead,pr_quotedetl)
#
#   QA8a - Quotation Print Program
#######################################################################
REPORT qa8_list(pr_quotehead,pr_quotedetl) 
	DEFINE 
	pr_quotehead RECORD LIKE quotehead.*, 
	pr_quotedetl RECORD LIKE quotedetl.*, 
	sub_head_ind CHAR(1), 
	in_file CHAR(100), 
	checkfile CHAR(210), 
	exists_flag SMALLINT 

	OUTPUT 
	left margin 1 
	PAGE length 64 
	top margin 2 
	bottom margin 2 
	ORDER external BY pr_quotehead.cust_code, 
	pr_quotedetl.order_num, 
	pr_quotedetl.line_num 
	FORMAT 
		PAGE HEADER 
			SELECT name_text INTO pr_quotehead.ship_name_text 
			FROM customer 
			WHERE cmpy_code = pr_quotehead.cmpy_code 
			AND cust_code = pr_quotehead.cust_code 
			PRINT COLUMN 52, "Quotation:", 
			COLUMN 65, pr_quotedetl.order_num USING "&&&&&&&" 
			PRINT COLUMN 1, "Client Id:", 
			COLUMN 13, pr_quotedetl.cust_code, 
			COLUMN 27, pr_quotehead.ship_name_text 
			SKIP 1 line 
			LET sub_head_ind = "Y" 
		ON EVERY ROW 
			NEED 2 LINES 
			IF sub_head_ind = "Y" THEN 
				PRINT COLUMN 1, "Item", 
				COLUMN 7, "Description", 
				COLUMN 36, "Qty", 
				COLUMN 43, "Price", 
				COLUMN 54, "Total" 
				PRINT COLUMN 8, "Part No.", 
				COLUMN 43, "Each", 
				COLUMN 54, "Price" 
				PRINT COLUMN 44, pr_quotehead.currency_code, 
				COLUMN 55, pr_quotehead.currency_code 
				PRINT "----------------------------------------", 
				"--------------------------------" 
				LET sub_head_ind = "N" 
			END IF 
			PRINT COLUMN 1, pr_quotedetl.line_num USING "###", 
			COLUMN 6, pr_quotedetl.desc_text 
			IF ((pr_quotedetl.unit_price_amt + pr_quotedetl.unit_tax_amt != 0) AND 
			(pr_quotedetl.ext_price_amt + pr_quotedetl.ext_tax_amt != 0)) THEN 
				PRINT COLUMN 8, pr_quotedetl.part_code, 
				COLUMN 32, pr_quotedetl.order_qty USING "########", 
				COLUMN 40, pr_quotedetl.unit_price_amt + 
				pr_quotedetl.unit_tax_amt USING "------$.&&", 
				COLUMN 51, pr_quotedetl.ext_price_amt + 
				pr_quotedetl.ext_tax_amt USING "------$.&&" 
				PRINT COLUMN 01, "Availability: ", 
				pr_quotedetl.quote_lead_text clipped," ", 
				pr_quotedetl.quote_lead_text2 
			ELSE 
				IF ((pr_quotedetl.unit_price_amt + pr_quotedetl.unit_tax_amt = 0) AND 
				(pr_quotedetl.ext_price_amt + pr_quotedetl.ext_tax_amt = 0)) THEN 
					PRINT COLUMN 8, pr_quotedetl.part_code, 
					COLUMN 32, pr_quotedetl.order_qty USING "########" 
					PRINT COLUMN 01, "Availability: ", 
					pr_quotedetl.quote_lead_text clipped," ", 
					pr_quotedetl.quote_lead_text2 
				ELSE 
					IF (pr_quotedetl.unit_price_amt + pr_quotedetl.unit_tax_amt = 0) THEN 
						PRINT COLUMN 8, pr_quotedetl.part_code, 
						COLUMN 32, pr_quotedetl.order_qty USING "########", 
						COLUMN 51, pr_quotedetl.ext_price_amt + 
						pr_quotedetl.ext_tax_amt USING "------$.&&" 
						PRINT COLUMN 01, "Availability: ", 
						pr_quotedetl.quote_lead_text clipped," ", 
						pr_quotedetl.quote_lead_text2 
					ELSE 
						IF (pr_quotedetl.ext_price_amt + pr_quotedetl.ext_tax_amt = 0) THEN 
							PRINT COLUMN 08, pr_quotedetl.part_code, 
							COLUMN 32, pr_quotedetl.order_qty USING "########", 
							COLUMN 40, pr_quotedetl.unit_price_amt + 
							pr_quotedetl.unit_tax_amt USING "------$.&&" 
							PRINT COLUMN 01, "Availability: ", 
							pr_quotedetl.quote_lead_text clipped," ", 
							pr_quotedetl.quote_lead_text2 
						END IF 
					END IF 
				END IF 
			END IF 
		BEFORE GROUP OF pr_quotedetl.order_num 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, pr_quotehead.com1_text, 
			COLUMN 34, pr_arparms.inv_ref1_text clipped, ":", 
			COLUMN 52, pr_quotehead.ord_text 
			PRINT COLUMN 1, pr_quotehead.com2_text, 
			COLUMN 52, pr_quotehead.entry_code 
			PRINT COLUMN 1, pr_quotehead.com3_text, 
			COLUMN 42, "Revision:", 
			COLUMN 52, pr_quotehead.rev_num USING "####" 
			IF pr_quotehead.rev_date IS NULL THEN 
				PRINT COLUMN 1, pr_quotehead.com4_text, 
				COLUMN 42, "Date:", 
				COLUMN 52, pr_quotehead.quote_date USING "dd/mm/yy" 
			ELSE 
				PRINT COLUMN 1, pr_quotehead.com4_text, 
				COLUMN 42, "Date:", 
				COLUMN 52, pr_quotehead.rev_date USING "dd/mm/yy" 
			END IF 
			SKIP 1 line 
			IF glob_rec_qpparms.quote_std_text IS NOT NULL THEN 
				LET in_file = glob_rec_qpparms.quote_std_text clipped, 
				"/q", pr_quotedetl.order_num USING "&&&&&&&", ".let" 
				LET checkfile = "[ -f ",in_file clipped," ] && EXIT 0 || EXIT 1;" 
				RUN checkfile RETURNING exists_flag 
				# this routine check IF a file exists AND returns
				# 0 - IF the file exists
				# 1 - IF the file does NOT exist
				IF exists_flag = 0 THEN 
					PRINT file in_file 
					SKIP TO top OF PAGE 
				END IF 
			END IF 
		AFTER GROUP OF pr_quotedetl.order_num 
			IF pr_quotehead.freight_amt = 0 AND pr_quotehead.hand_amt = 0 THEN 
				PRINT COLUMN 49, "------------" 
				PRINT COLUMN 37, "Total:", 
				COLUMN 49, GROUP sum(pr_quotedetl.ext_price_amt) + 
				GROUP sum(pr_quotedetl.ext_tax_amt) USING "--------$.&&" 
			ELSE 
				PRINT COLUMN 50, "------------" 
				PRINT COLUMN 49, GROUP sum(pr_quotedetl.ext_price_amt) + 
				GROUP sum(pr_quotedetl.ext_tax_amt) USING "--------$.&&" 
				IF pr_quotehead.freight_amt > 0 THEN 
					PRINT COLUMN 37, "Freight:", 
					COLUMN 51, pr_quotehead.freight_amt USING "------$.&&" 
				END IF 
				IF pr_quotehead.hand_amt > 0 THEN 
					PRINT COLUMN 37, "Insurance:", 
					COLUMN 51, pr_quotehead.hand_amt USING "------$.&&" 
				END IF 
				PRINT COLUMN 49, "-------------" 
				PRINT COLUMN 37, "Total:", 
				COLUMN 49, GROUP sum (pr_quotedetl.ext_price_amt) + 
				GROUP sum (pr_quotedetl.ext_tax_amt) + 
				pr_quotehead.freight_amt + 
				pr_quotehead.hand_amt USING "--------$.&&" 
			END IF 
			PAGE TRAILER 
				PRINT COLUMN 1, glob_rec_qpparms.footer1_text 
				PRINT COLUMN 1, glob_rec_qpparms.footer2_text 
				PRINT COLUMN 1, glob_rec_qpparms.footer3_text 
				SKIP 1 line 
				PRINT COLUMN 29, "Page", 
				COLUMN 34, pageno USING "####" 
END REPORT 
