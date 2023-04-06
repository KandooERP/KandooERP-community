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
# DISPLAY client general details

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################################
# FUNCTION cinq_dets(p_cmpy,p_cust_code,p_overdue,p_baddue)
############################################################################
FUNCTION cinq_dets(p_cmpy,p_cust_code,p_overdue,p_baddue) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_overdue LIKE customer.over1_amt 
	DEFINE p_baddue LIKE customer.over1_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_customertype RECORD LIKE customertype.* 
	DEFINE l_rec_salesperson RECORD LIKE salesperson.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 

	SELECT * INTO l_rec_customer.* FROM customer 
	WHERE cmpy_code = p_cmpy 
	AND cust_code = p_cust_code 
	
	SELECT * INTO l_rec_customertype.* FROM customertype 
	WHERE cmpy_code = p_cmpy 
	AND type_code = l_rec_customer.type_code

	#get sales person record	 
	CALL db_salesperson_get_rec(UI_OFF,l_rec_customer.sale_code) RETURNING l_rec_salesperson.*
	 
	CALL db_term_get_rec(UI_OFF,l_rec_customer.term_code) RETURNING l_rec_term.*
	 
	SELECT * INTO l_rec_tax.* FROM tax 
	WHERE tax.cmpy_code = p_cmpy 
	AND tax_code = l_rec_customer.tax_code 

	OPEN WINDOW A105 with FORM "A105" 
	CALL windecoration_a("A105") 

	CALL db_country_localize(l_rec_customer.country_code) #Localize

	#IF p_overdue > 0 THEN --huho no idea what this should do
	#END IF
	IF p_overdue > 0 THEN --if bad overdue - red , overdue - yellow OTHERWISE normal 
		IF p_baddue > 0 THEN
			DISPLAY l_rec_customer.cust_code TO customer.cust_code ATTRIBUTE(RED)
			DISPLAY l_rec_customer.name_text TO customer.name_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.addr1_text TO customer.addr1_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.addr2_text TO customer.addr2_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.city_text TO customer.city_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.state_code TO customer.state_code ATTRIBUTE(RED)
			DISPLAY l_rec_customer.post_code TO customer.post_code ATTRIBUTE(RED)
			DISPLAY l_rec_customer.country_code TO customer.country_code ATTRIBUTE(RED)
			DISPLAY db_country_get_country_text(UI_OFF,l_rec_customer.country_code) TO country_text ATTRIBUTE(RED) --@db-patch_2020_10_04--
			DISPLAY l_rec_customer.currency_code TO customer.currency_code ATTRIBUTE(RED)
			DISPLAY l_rec_customer.type_code TO customer.type_code ATTRIBUTE(RED)
			DISPLAY l_rec_customertype.type_text TO customertype.type_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.sale_code TO customer.sale_code ATTRIBUTE(RED)
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.term_code TO customer.term_code ATTRIBUTE(RED)
			DISPLAY l_rec_term.desc_text TO term.desc_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.tax_code TO customer.tax_code ATTRIBUTE(RED)
			DISPLAY l_rec_tax.desc_text TO tax.desc_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.setup_date TO customer.setup_date ATTRIBUTE(RED)
			DISPLAY l_rec_customer.int_chge_flag TO customer.int_chge_flag ATTRIBUTE(RED)
			DISPLAY l_rec_customer.tax_num_text TO customer.tax_num_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.fax_text TO customer.fax_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.contact_text TO customer.contact_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.tele_text TO customer.tele_text ATTRIBUTE(RED)
			DISPLAY l_rec_customer.mobile_phone TO customer.mobile_phone ATTRIBUTE(RED)
			DISPLAY l_rec_customer.registration_num TO customer.registration_num ATTRIBUTE(RED)  --@db-patch_2020_10_04-- #registration_num
			DISPLAY l_rec_customer.vat_code TO customer.vat_code ATTRIBUTE(RED)
		ELSE 
			DISPLAY l_rec_customer.cust_code TO customer.cust_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.name_text TO customer.name_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.addr1_text TO customer.addr1_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.addr2_text TO customer.addr2_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.city_text TO customer.city_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.state_code TO customer.state_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.post_code TO customer.post_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.country_code TO customer.country_code ATTRIBUTE(MAGENTA)
			DISPLAY db_country_get_country_text(UI_OFF,l_rec_customer.country_code) TO country_text ATTRIBUTE(MAGENTA) --@db-patch_2020_10_04--			
			DISPLAY l_rec_customer.currency_code TO customer.currency_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.type_code TO customer.type_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customertype.type_text TO customertype.type_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.sale_code TO customer.sale_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.term_code TO customer.term_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_term.desc_text TO term.desc_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.tax_code TO customer.tax_code ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_tax.desc_text TO tax.desc_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.setup_date TO customer.setup_date ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.int_chge_flag TO customer.int_chge_flag ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.tax_num_text TO customer.tax_num_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.fax_text TO customer.fax_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.contact_text TO customer.contact_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.tele_text TO customer.tele_text ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.mobile_phone TO customer.mobile_phone ATTRIBUTE(MAGENTA)
			DISPLAY l_rec_customer.registration_num TO customer.registration_num ATTRIBUTE(MAGENTA)  --@db-patch_2020_10_04-- #registration_num			
			DISPLAY l_rec_customer.vat_code TO customer.vat_code ATTRIBUTE(MAGENTA)
		END IF 
	ELSE --everthing fine.. no outstanding bad credit 
			DISPLAY l_rec_customer.cust_code TO customer.cust_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.name_text TO customer.name_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.addr1_text TO customer.addr1_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.addr2_text TO customer.addr2_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.city_text TO customer.city_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.state_code TO customer.state_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.post_code TO customer.post_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.country_code TO customer.country_code ATTRIBUTE(GREEN)
			DISPLAY db_country_get_country_text(UI_OFF,l_rec_customer.country_code) TO country_text ATTRIBUTE(GREEN) --@db-patch_2020_10_04--			
			DISPLAY l_rec_customer.currency_code TO customer.currency_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.type_code TO customer.type_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_customertype.type_text TO customertype.type_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.sale_code TO customer.sale_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_salesperson.name_text TO salesperson.name_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.term_code TO customer.term_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_term.desc_text TO term.desc_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.tax_code TO customer.tax_code ATTRIBUTE(GREEN)
			DISPLAY l_rec_tax.desc_text TO tax.desc_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.setup_date TO customer.setup_date ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.int_chge_flag TO customer.int_chge_flag ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.tax_num_text TO customer.tax_num_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.fax_text TO customer.fax_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.contact_text TO customer.contact_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.tele_text TO customer.tele_text ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.mobile_phone TO customer.mobile_phone ATTRIBUTE(GREEN)
			DISPLAY l_rec_customer.registration_num TO customer.registration_num ATTRIBUTE(GREEN)  --@db-patch_2020_10_04-- #registration_num			
			DISPLAY l_rec_customer.vat_code TO customer.vat_code ATTRIBUTE(GREEN)

	END IF 

	CALL eventsuspend() 
	#ERROR kandoomsg2("U",1,"")
	#1 Press Any Key TO Exit
	LET int_flag = false 
	LET quit_flag = false 

	CLOSE WINDOW A105 
END FUNCTION 
############################################################################
# END FUNCTION cinq_dets(p_cmpy,p_cust_code,p_overdue,p_baddue)
############################################################################