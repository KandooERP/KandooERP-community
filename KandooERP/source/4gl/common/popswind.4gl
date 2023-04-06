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
# FUNCTION po_head_info(p_cmpy_code,p_order_num )
#
#
############################################################
FUNCTION po_head_info(p_cmpy_code,p_order_num ) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_order_num INTEGER 
	DEFINE l_rec_poaudit RECORD LIKE poaudit.* 
	DEFINE r_order_amt LIKE poaudit.line_total_amt 
	DEFINE r_tax_amt LIKE poaudit.line_total_amt 
	DEFINE r_recpt_amt LIKE poaudit.line_total_amt 
	DEFINE r_vouch_amt LIKE poaudit.line_total_amt 

	LET r_order_amt = 0 
	LET r_tax_amt = 0 
	LET r_recpt_amt = 0 
	LET r_vouch_amt = 0 

	DECLARE c_poaudit CURSOR FOR 
	SELECT * FROM poaudit 
	WHERE cmpy_code = p_cmpy_code 
	AND po_num = p_order_num 

	WHENEVER ERROR CONTINUE 

	FOREACH c_poaudit INTO l_rec_poaudit.* 
		CASE 
			WHEN l_rec_poaudit.order_qty <> 0 
				LET r_order_amt = r_order_amt + l_rec_poaudit.line_total_amt 
				LET r_tax_amt = r_tax_amt + l_rec_poaudit.ext_tax_amt 
			WHEN l_rec_poaudit.received_qty <> 0 
				LET r_recpt_amt = r_recpt_amt + l_rec_poaudit.line_total_amt 
			WHEN l_rec_poaudit.voucher_qty <> 0 
				LET r_vouch_amt = r_vouch_amt + l_rec_poaudit.line_total_amt 
		END CASE 
	END FOREACH 

	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	RETURN r_order_amt, 
	r_recpt_amt, 
	r_vouch_amt, 
	r_tax_amt 
END FUNCTION 
