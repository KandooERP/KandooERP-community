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

	Source code beautified by beautify.pl on 2020-01-02 10:35:39	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

#############################################################
# FUNCTION vinq_subc(p_cmpy_code,p_vend_code)
#
# \brief module - visuwind.4gl Displays subcontractor details
#############################################################
FUNCTION vinq_subc(p_cmpy_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_vendor_tax_no LIKE vendor.tax_text 
	DEFINE l_vendor_tax_text LIKE vendor.tax_text 
	DEFINE l_rec_contractor RECORD LIKE contractor.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	OPEN WINDOW wp157 with FORM "P157" 
	CALL windecoration_p("P157") 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 

	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014 Logic Error: Vendor NOT found
		CLOSE WINDOW wp157 
		RETURN 
	END IF 

	SELECT * INTO l_rec_contractor.* FROM contractor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 

	IF l_rec_contractor.tax_no_text IS NULL THEN 
		DISPLAY l_vendor_tax_no TO contractor.tax_no_text 

	END IF 

	DISPLAY BY NAME l_rec_vendor.name_text, 
	l_rec_contractor.tax_rate_qty, 
	l_rec_contractor.vend_code, 
	l_rec_contractor.start_date, 
	l_rec_contractor.home_phone_text, 
	l_rec_contractor.pager_comp_text, 
	l_rec_contractor.pager_num_text, 
	l_rec_contractor.licence_text, 
	l_rec_contractor.expiry_date, 
	l_rec_contractor.tax_no_text, 
	l_rec_contractor.regist_num_text, 
	l_rec_contractor.tax_code, 
	l_rec_contractor.variation_text, 
	l_rec_contractor.var_start_date, 
	l_rec_contractor.var_exp_date, 
	l_rec_contractor.union_text, 
	l_rec_contractor.union_num_text, 
	l_rec_contractor.union_exp_date, 
	l_rec_contractor.insurance_text, 
	l_rec_contractor.comp_num_text, 
	l_rec_contractor.ins_exp_date 

	CALL donePrompt(NULL,NULL,"ACCEPT") 
	#LET l_msgresp=kandoomsg("U",1,"")
	#1 Any Key TO Continue

	CLOSE WINDOW wp157 

END FUNCTION 


