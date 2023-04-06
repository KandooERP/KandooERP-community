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

#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

##########################################################
# FUNCTION vinq_dets(p_cmpy_code,p_vend_code)
#
# \brief module - vigdwind.4gl Displays vendor general details
##########################################################
FUNCTION vinq_dets(p_cmpy_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_country RECORD LIKE country.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_temp_prompt_text CHAR(34) 
	DEFINE l_state_code_text CHAR(17) 
	DEFINE l_post_code_text CHAR(17) 
	DEFINE l_temp_post_code LIKE vendor.post_code 
	DEFINE l_temp_state_code LIKE vendor.state_code 
	DEFINE l_pr_acct_text CHAR(13) 
	DEFINE l_pr_bic_text CHAR(6) 


	OPEN WINDOW wp176 with FORM "P176" 
	CALL windecoration_p("P176") 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 

	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014 Logic Error: Vendor NOT found
		CLOSE WINDOW wp176 
		RETURN 
	END IF 

	#INITIALIZE l_rec_vendortype.* TO NULL

	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE cmpy_code = l_rec_vendor.cmpy_code 
	AND type_code = l_rec_vendor.type_code 

	#INITIALIZE l_rec_term.* TO NULL

	SELECT desc_text INTO l_rec_term.desc_text FROM term 
	WHERE cmpy_code = l_rec_vendor.cmpy_code 
	AND term_code = l_rec_vendor.term_code 

	#INITIALIZE l_rec_currency.* TO NULL

	SELECT desc_text INTO l_rec_currency.desc_text FROM currency 
	WHERE currency_code = l_rec_vendor.currency_code 

	#INITIALIZE l_rec_tax.* TO NULL

	SELECT desc_text INTO l_rec_tax.desc_text FROM tax 
	WHERE cmpy_code = l_rec_vendor.cmpy_code 
	AND tax_code = l_rec_vendor.tax_code 

	#INITIALIZE l_rec_country.* TO NULL

	SELECT country.* INTO l_rec_country.* FROM country, company 
	WHERE company.cmpy_code = l_rec_vendor.cmpy_code 
	AND country.country_code = company.country_code 


--	IF STATUS = NOTFOUND THEN 
--		LET l_state_code_text = "State............." 
--		LET l_post_code_text = "Postal Code......." 
--	ELSE 
--		LET l_temp_prompt_text = l_rec_country.state_code_text clipped, 
--		".................." 
--		LET l_state_code_text = l_temp_prompt_text 
--		LET l_temp_prompt_text = l_rec_country.post_code_text clipped, 
--		".................." 
--		LET l_post_code_text = l_temp_prompt_text 
--	END IF 

	# huho 2.9.2019 - vendor.bank_acct_code is nchar(18)... so, the [20] makes no sense.. also, the bank acount assumption =-6/7-20 does not support multi country bank/account code usage
	#	IF l_rec_vendor.bank_acct_code.getLength() >= 6 THEN
	#		LET l_pr_bic_text = l_rec_vendor.bank_acct_code[1,6]
	#	END IF
	#
	#	IF l_rec_vendor.bank_acct_code.getLength() >= 20 THEN
	#		LET l_pr_acct_text = l_rec_vendor.bank_acct_code[8,20]
	#	END IF

	CALL db_country_localize(l_rec_vendor.country_code) #Localize	
	--DISPLAY	l_state_code_text TO state_code_text 
	--DISPLAY	l_post_code_text TO post_code_text 

	DISPLAY BY NAME l_rec_vendor.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_vendor.addr1_text, 
	l_rec_vendor.addr2_text, 
	l_rec_vendor.addr3_text, 
	l_rec_vendor.city_text, 
	l_rec_vendor.state_code, 
	l_rec_vendor.post_code, 
	l_rec_vendor.country_code, 
--@db-patch_2020_10_04--	l_rec_country.country_text, 
	l_rec_vendor.our_acct_code, 
	l_rec_vendor.contact_text, 
	l_rec_vendor.tele_text, 
	l_rec_vendor.extension_text, 
	l_rec_vendor.fax_text, 
	l_rec_vendor.type_code, 
	l_rec_vendortype.type_text, 
	l_rec_vendor.term_code, 
	l_rec_vendor.tax_code, 
	l_rec_vendor.vat_code, 
	l_rec_vendor.tax_incl_flag 

	DISPLAY l_rec_vendor.currency_code TO currency_code 
	DISPLAY db_currency_get_desc_text(UI_OFF,l_rec_vendor.currency_code) TO currency.desc_text
	DISPLAY db_coa_get_desc_text(UI_OFF,l_rec_vendor.our_acct_code) TO coa.desc_text
	DISPLAY l_rec_term.desc_text TO term.desc_text 
	DISPLAY l_rec_tax.desc_text TO tax.desc_text 

	CALL donePrompt(NULL,NULL,"ACCEPT") 

	#LET l_msgresp=kandoomsg("U",1,"")
	#1 Any Key TO Continue

	CLOSE WINDOW wp176 

END FUNCTION