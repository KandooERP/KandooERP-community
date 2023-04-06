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

	Source code beautified by beautify.pl on 2020-01-02 10:35:26	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION po_line_detail(p_cmpy_code, p_ponum, p_linenum, p_seqnum)
#
# FUNCTION po_line_detail displays the the audit trail info
############################################################
FUNCTION po_line_detail(p_cmpy_code,p_ponum,p_linenum,p_seqnum) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	#DEFINE l_rec_cust LIKE vendor.vend_code
	DEFINE p_ponum LIKE poaudit.po_num 
	DEFINE p_linenum LIKE poaudit.line_num 
	DEFINE p_seqnum LIKE poaudit.seq_num 
	#DEFINE l_ans CHAR(1)
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_poaudit.* FROM poaudit 
	WHERE cmpy_code = p_cmpy_code 
	AND po_num = p_ponum 
	AND line_num = p_linenum 
	AND seq_num = p_seqnum 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"P.O. Audit") 
		#7001 Logic Error: P.O. Audit RECORD NOT found
		RETURN 
	END IF 
	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE vendor.vend_code = l_rec_poaudit.vend_code 
	AND vendor.cmpy_code = p_cmpy_code 
	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("U",7001,"Vendor") 
		#7001 Logic Error: Vendor RECORD NOT found
		RETURN 
	END IF 

	OPEN WINDOW wr140 with FORM "R140" 
	CALL winDecoration_r("R140") 

	DISPLAY BY NAME l_rec_poaudit.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_poaudit.po_num, 
	l_rec_poaudit.line_num, 
	l_rec_poaudit.tran_code, 
	l_rec_poaudit.tran_num, 
	l_rec_poaudit.seq_num, 
	l_rec_poaudit.entry_date, 
	l_rec_poaudit.entry_code, 
	l_rec_poaudit.orig_auth_flag, 
	l_rec_poaudit.now_auth_flag, 
	l_rec_poaudit.order_qty, 
	l_rec_poaudit.received_qty, 
	l_rec_poaudit.voucher_qty, 
	l_rec_poaudit.desc_text, 
	l_rec_poaudit.unit_cost_amt, 
	l_rec_poaudit.ext_cost_amt, 
	l_rec_poaudit.unit_tax_amt, 
	l_rec_poaudit.ext_tax_amt, 
	l_rec_poaudit.line_total_amt, 
	l_rec_poaudit.posted_flag, 
	l_rec_poaudit.jour_num, 
	l_rec_poaudit.year_num, 
	l_rec_poaudit.period_num 

	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 
	#1 Press any key TO continue

	CLOSE WINDOW wr140 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

	RETURN 
END FUNCTION 


