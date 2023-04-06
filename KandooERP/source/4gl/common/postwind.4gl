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
	Source code beautified by beautify.pl on 2020-01-02 10:35:27	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION pohiwind(p_cmpy_code, p_vend, p_ponum, p_linenum)
#
# brief module - postwind.4gl
#           Get P/O line information
############################################################
FUNCTION po_line_info(p_cmpy_code,p_ponum,p_linenum) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_ponum INTEGER 
	DEFINE p_linenum SMALLINT 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE l_order_total LIKE poaudit.order_qty 
	DEFINE l_received_total LIKE poaudit.received_qty 
	DEFINE l_voucher_total LIKE poaudit.order_qty 
	DEFINE l_s_unit_cost_amt LIKE poaudit.unit_cost_amt 
	DEFINE l_ext_cost_amt LIKE poaudit.ext_cost_amt 
	DEFINE l_s_unit_tax_amt LIKE poaudit.unit_tax_amt 
	DEFINE l_s_ext_tax_amt LIKE poaudit.ext_tax_amt 
	DEFINE l_s_line_total_amt LIKE poaudit.line_total_amt 

	LET l_order_total = 0 
	LET l_received_total = 0 
	LET l_voucher_total = 0 
	LET l_s_unit_cost_amt = 0 
	LET l_ext_cost_amt = 0 
	LET l_s_unit_tax_amt = 0 
	LET l_s_ext_tax_amt = 0 
	LET l_s_line_total_amt = 0 

	DECLARE po_curs CURSOR FOR 
	SELECT * 
	INTO l_rec_poaudit.* 
	FROM poaudit 
	WHERE cmpy_code = p_cmpy_code 
	AND po_num = p_ponum 
	AND line_num = p_linenum 
	ORDER BY po_num, line_num, seq_num 

	FOREACH po_curs 

		# Ignore type "CE" - these are closing reconciliation entries only
		IF l_rec_poaudit.tran_code <> "CE" THEN 
			LET l_order_total = l_order_total + l_rec_poaudit.order_qty 
			LET l_received_total = l_received_total + l_rec_poaudit.received_qty 
			LET l_voucher_total = l_voucher_total + l_rec_poaudit.voucher_qty 
		END IF 

		IF l_rec_poaudit.tran_code = "CQ" OR 
		l_rec_poaudit.tran_code = "AL" OR 
		l_rec_poaudit.tran_code = "AA" OR 
		l_rec_poaudit.tran_code = "CP" 
		THEN 
			LET l_s_unit_cost_amt = l_rec_poaudit.unit_cost_amt 
			LET l_ext_cost_amt = l_rec_poaudit.ext_cost_amt 
			LET l_s_unit_tax_amt = l_rec_poaudit.unit_tax_amt 
			LET l_s_ext_tax_amt = l_rec_poaudit.ext_tax_amt 
			LET l_s_line_total_amt = l_rec_poaudit.line_total_amt 
		END IF 

	END FOREACH 

	IF l_order_total = 0 
	THEN 
		LET l_order_total = 0 
		LET l_received_total = 0 
		LET l_voucher_total = 0 
		LET l_s_unit_cost_amt = 0 
		LET l_ext_cost_amt = 0 
		LET l_s_unit_tax_amt = 0 
		LET l_s_ext_tax_amt = 0 
		LET l_s_line_total_amt = 0 
	END IF 

	RETURN l_order_total, l_received_total, l_voucher_total, 
	l_s_unit_cost_amt, l_ext_cost_amt, l_s_unit_tax_amt, 
	l_s_ext_tax_amt, l_s_line_total_amt 
END FUNCTION 


