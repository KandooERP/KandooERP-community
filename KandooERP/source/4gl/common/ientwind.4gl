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

	Source code beautified by beautify.pl on 2020-01-02 10:35:14	$Id: $
}



#
#        ientwind.4gl - FUNCTION show_inv_entry()
#                       Invoice Entry details Display
#
GLOBALS "../common/glob_GLOBALS.4gl" 
DEFINE 
msgresp LIKE language.yes_flag 

###################################################################
# FUNCTION show_inv_entry(p_cmpy, p_inv_num)
###################################################################
FUNCTION show_inv_entry(p_cmpy,p_inv_num) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_inv_num LIKE invoicehead.inv_num 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_ref_text LIKE arparms.inv_ref1_text 
	DEFINE l_temp_text CHAR(30) 

	SELECT inv_ref1_text INTO l_ref_text 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF STATUS = NOTFOUND THEN 
		LET msgresp = kandoomsg("A",7005,"") 
		#7005 "AR Parameters do NOT Exist - Refer Menu AZP"
		EXIT program 
	ELSE 
		LET l_temp_text = l_ref_text clipped,"..........." 
		LET l_ref_text = l_temp_text 
	END IF 

	SELECT * INTO l_rec_invoicehead.* 
	FROM invoicehead 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 

	IF STATUS = NOTFOUND THEN 
		LET msgresp = kandoomsg("U",7001,"Invoice Header") 
		#7001 Logic Error: Invoice Header RECORD NOT found
		RETURN 
	END IF 

	SELECT ware_code INTO l_rec_warehouse.ware_code 
	FROM invoicedetl 
	WHERE cmpy_code = p_cmpy 
	AND inv_num = p_inv_num 
	AND line_num = 1 

	SELECT desc_text INTO l_rec_warehouse.desc_text 
	FROM warehouse 
	WHERE cmpy_code = p_cmpy 
	AND ware_code = l_rec_warehouse.ware_code 

	CALL db_salesperson_get_name_text(UI_OFF,l_rec_invoicehead.sale_code) RETURNING l_rec_salesperson.name_text

	SELECT desc_text INTO l_rec_term.desc_text 
	FROM term 
	WHERE cmpy_code = p_cmpy 
	AND term_code = l_rec_invoicehead.term_code 

	SELECT desc_text INTO l_rec_tax.desc_text 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_invoicehead.tax_code 

	OPEN WINDOW A139 with FORM "A139" 
	CALL windecoration_a("A139") 

	DISPLAY l_ref_text TO inv_ref1_text 

	DISPLAY BY NAME l_rec_invoicehead.purchase_code, 
	l_rec_invoicehead.entry_code, 
	l_rec_invoicehead.inv_date, 
	l_rec_invoicehead.conv_qty, 
	l_rec_invoicehead.currency_code, 
	l_rec_warehouse.ware_code, 
	l_rec_invoicehead.sale_code, 
	l_rec_salesperson.name_text, 
	l_rec_invoicehead.term_code, 
	l_rec_invoicehead.tax_code, 
	l_rec_invoicehead.job_code, 
	l_rec_invoicehead.year_num, 
	l_rec_invoicehead.period_num 

	DISPLAY l_rec_warehouse.desc_text, 
	l_rec_term.desc_text, 
	l_rec_tax.desc_text 
	TO warehouse.desc_text, 
	term.desc_text, 
	tax.desc_text 

	CALL eventsuspend() # LET msgresp=kandoomsg("U",1,"") 

	CLOSE WINDOW A139 

END FUNCTION 


