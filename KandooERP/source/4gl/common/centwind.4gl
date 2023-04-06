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

	Source code beautified by beautify.pl on 2020-01-02 10:35:06	$Id: $
}



#
#        centwind.4gl - FUNCTION show_cred_entry()
#                       Credits Entry details Display
#
GLOBALS "../common/glob_GLOBALS.4gl" 


########################################################################
# FUNCTION show_cred_entry(p_cmpy, p_cred_num)
########################################################################
FUNCTION show_cred_entry(p_cmpy, p_cred_num) 
	DEFINE p_cmpy LIKE customer.cmpy_code 
	DEFINE p_cred_num LIKE credithead.cred_num 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_rec_warehouse RECORD LIKE warehouse.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_ref_text LIKE arparms.credit_ref1_text 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_temp_text CHAR(30) 

	SELECT credit_ref1_text 
	INTO l_ref_text 
	FROM arparms 
	WHERE cmpy_code = p_cmpy 
	AND parm_code = "1" 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9107,"") 
		# 9107 AR Parameters do NOT Exist - Refer Menu AZP
		EXIT program 
	ELSE 
		LET l_temp_text = l_ref_text clipped,"..........." 
		LET l_ref_text = l_temp_text 
	END IF 

	SELECT * 
	INTO l_rec_credithead.* 
	FROM credithead 
	WHERE cmpy_code = p_cmpy 
	AND cred_num = p_cred_num 

	IF status = notfound THEN 
		LET l_msgresp = kandoomsg("A",9108,"") 
		# 9108 Credithead does NOT Exist
		RETURN 
	END IF 

	SELECT warehouse.ware_code, 
	warehouse.desc_text 
	INTO l_rec_creditdetl.ware_code, 
	l_rec_warehouse.desc_text 
	FROM warehouse, 
	creditdetl 
	WHERE warehouse.cmpy_code = p_cmpy 
	AND creditdetl.cmpy_code = p_cmpy 
	AND creditdetl.cred_num = l_rec_credithead.cred_num 
	AND creditdetl.line_num = 1 
	AND creditdetl.ware_code = warehouse.ware_code 

	SELECT reason_text 
	INTO l_rec_credreas.reason_text 
	FROM credreas 
	WHERE cmpy_code = p_cmpy 
	AND reason_code = l_rec_credithead.reason_code 

	SELECT name_text 
	INTO l_rec_salesperson.name_text 
	FROM salesperson 
	WHERE cmpy_code = p_cmpy 
	AND sale_code = l_rec_credithead.sale_code 

	SELECT desc_text 
	INTO l_rec_tax.desc_text 
	FROM tax 
	WHERE cmpy_code = p_cmpy 
	AND tax_code = l_rec_credithead.tax_code 

	OPEN WINDOW A128 with FORM "A128" #attribute(border, MESSAGE line first) 
	CALL windecoration_a("A128") 

	DISPLAY l_ref_text TO credit_ref1_text 
	DISPLAY BY NAME l_rec_creditdetl.ware_code, 
	l_rec_credithead.entry_code, 
	l_rec_credithead.cred_date, 
	l_rec_credithead.conv_qty, 
	l_rec_credithead.currency_code, 
	l_rec_credithead.reason_code, 
	l_rec_credreas.reason_text, 
	l_rec_credithead.sale_code, 
	l_rec_salesperson.name_text, 
	l_rec_credithead.tax_code, 
	l_rec_credithead.cred_text, 
	l_rec_credithead.year_num, 
	l_rec_credithead.period_num 

	DISPLAY l_rec_tax.desc_text, 
	l_rec_warehouse.desc_text 
	TO tax.desc_text, 
	warehouse.desc_text 

	LET l_msgresp = kandoomsg("A",7001,"") 
	# 7001 Any Key TO Continue

	CLOSE WINDOW A128 
END FUNCTION 


