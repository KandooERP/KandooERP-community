#Should be replaced by PCFb_rpt.4gl  after program update  
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:42	$Id: $
}{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module PCFb  Remittance Advices
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# REPORT PCF_list(p_rec_cheque)
############################################################
REPORT pcf_list(p_rec_cheque) 
	DEFINE p_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_arr_address ARRAY[5] OF LIKE vendor.addr1_text
	DEFINE l_page_no SMALLINT
	DEFINE i, j SMALLINT

	OUTPUT 
	left margin 1 
	PAGE length 51 
	top margin 1 
	bottom margin 8 
	ORDER external BY p_rec_cheque.bank_code, 
	p_rec_cheque.pay_meth_ind, 
	p_rec_cheque.cheq_code 
	FORMAT 
		PAGE HEADER 
			SELECT * INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND vend_code = p_rec_cheque.vend_code 
			##
			## Following CURSOR determines type of voucher being paid
			##
			DECLARE c_source_ind CURSOR FOR 
			SELECT source_ind, 
			source_text 
			FROM voucher, 
			voucherpays 
			WHERE voucher.cmpy_code = p_rec_cheque.cmpy_code 
			AND voucherpays.cmpy_code = p_rec_cheque.cmpy_code 
			AND voucherpays.pay_type_code = "CH" 
			AND voucherpays.pay_num = p_rec_cheque.cheq_code 
			AND voucherpays.vouch_code = voucher.vouch_code 
			OPEN c_source_ind 
			FETCH c_source_ind INTO l_rec_voucher.source_ind, 
			l_rec_voucher.source_text 
			IF l_rec_voucher.source_ind = "8" THEN 
				### Refund Cheque TO debtor
				SELECT * INTO l_rec_customer.* 
				FROM customer 
				WHERE cmpy_code = l_rec_voucherpays.cmpy_code 
				AND cust_code = l_rec_voucher.source_text 
				CALL pack_address(l_rec_customer.name_text, 
				l_rec_customer.addr1_text, 
				l_rec_customer.addr2_text, 
				l_rec_customer.city_text, 
				l_rec_customer.state_code, 
				l_rec_customer.post_code, 
				l_rec_customer.country_code)  --@db-patch_2020_10_04-- 
				RETURNING l_rec_vendor.name_text, 
				l_arr_address[1], 
				l_arr_address[2], 
				l_arr_address[3], 
				l_arr_address[4] 
			ELSE 
				CALL pack_address(l_rec_vendor.addr1_text, 
				l_rec_vendor.addr2_text, 
				l_rec_vendor.addr3_text, 
				l_rec_vendor.city_text, 
				l_rec_vendor.state_code, 
				l_rec_vendor.post_code, 
				l_rec_vendor.country_code) --@db-patch_2020_10_04-- 
				RETURNING l_arr_address[1], 
				l_arr_address[2], 
				l_arr_address[3], 
				l_arr_address[4], 
				l_arr_address[5] 
			END IF 
			PRINT COLUMN 38, "** REMITTANCE SLIP **" 
			PRINT COLUMN 38, "---------------------" 
			SKIP 1 line 
			LET l_page_no = l_page_no + 1 
			IF l_rec_vendor.contact_text IS NOT NULL THEN 
				PRINT COLUMN 38, "Attn:",l_rec_vendor.contact_text 
				SKIP 1 LINES 
			ELSE 
				SKIP 2 LINES 
			END IF 
			PRINT COLUMN 10, l_rec_vendor.name_text, 
			COLUMN 50, "Period TO:" 
			PRINT COLUMN 10, l_arr_address[1], 
			COLUMN 50, p_rec_cheque.cheq_date USING "dd mmm yy" 
			PRINT COLUMN 10, l_arr_address[2] 
			PRINT COLUMN 10, l_arr_address[3] 
			PRINT COLUMN 10, l_arr_address[4], 
			COLUMN 50, l_page_no USING "Page: <<<<" 
			SKIP 1 line 
			PRINT COLUMN 07, "Date", 
			COLUMN 20, "Details" 
			SKIP 2 LINES 
			PRINT COLUMN 05,"Please receive the enclosed cheque (No.", 
			p_rec_cheque.cheq_code USING "<<<<<<<<<",")" 
			PRINT COLUMN 05,"dated ",p_rec_cheque.cheq_date USING "dd mmm yy", 
			" in payment of :" 
			SKIP 1 line 
		BEFORE GROUP OF p_rec_cheque.cheq_code 
			LET l_page_no = 0 
			SKIP TO top OF PAGE 
		ON EVERY ROW 
			DECLARE c_voucherpays CURSOR FOR 
			SELECT * FROM voucherpays 
			WHERE cmpy_code = p_rec_cheque.cmpy_code 
			AND pay_num = p_rec_cheque.cheq_code 
			AND vend_code = p_rec_cheque.vend_code 
			AND pay_meth_ind = p_rec_cheque.pay_meth_ind 
			AND bank_code = p_rec_cheque.bank_code 
			AND pay_type_code = "CH" 
			AND rev_flag IS NULL 
			FOREACH c_voucherpays INTO l_rec_voucherpays.* 
				SELECT * INTO l_rec_voucher.* 
				FROM voucher 
				WHERE cmpy_code = l_rec_voucherpays.cmpy_code 
				AND vouch_code = l_rec_voucherpays.vouch_code 
				IF l_rec_voucher.source_ind = "8" THEN 
					PRINT COLUMN 5, l_rec_voucher.vouch_date USING "dd mmm yy", 
					COLUMN 18, "Refund TO account ",l_rec_voucher.source_text, 
					COLUMN 48, l_rec_voucherpays.apply_amt USING "--,---,--$.&&" 
				ELSE 
					PRINT COLUMN 5, l_rec_voucher.vouch_date USING "dd mmm yy", 
					COLUMN 18, "Invoice: ",l_rec_voucher.inv_text, 
					COLUMN 48, l_rec_voucherpays.apply_amt USING "--,---,--$.&&" 
				END IF 
			END FOREACH 
		AFTER GROUP OF p_rec_cheque.cheq_code 
			PRINT COLUMN 47, "==============" 
			PRINT COLUMN 18, "Total Payment:", 
			COLUMN 47, p_rec_cheque.pay_amt USING "---,---,--$.&&" 
END REPORT 


