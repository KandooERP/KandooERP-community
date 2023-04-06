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

	Source code beautified by beautify.pl on 2020-01-02 10:35:45	$Id: $
}


#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - wtaxcalc

#
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


####################################################################
# FUNCTION wtaxcalc(p_gross_amount, p_tax_per, p_tax_indicator, p_cmpy_code)
#
# Purpose - wtaxcalc calculates net AND tax amounts FOR the given
#           gross amount AND tax percentage, according TO the
#           nominated tax indicator method
#           0 = tax NOT applicable
#           1 = rounded TO two DECIMAL places
#           2 = rounded down TO nearest whole number
#           3 = rounded up TO nearest whole number
####################################################################
FUNCTION wtaxcalc(p_gross_amount,p_tax_per,p_tax_indicator,p_cmpy_code) 
	DEFINE p_gross_amount LIKE cheque.pay_amt 
	DEFINE p_tax_per LIKE tax.tax_per 
	DEFINE p_tax_indicator LIKE vendortype.withhold_tax_ind 
	DEFINE p_cmpy_code LIKE company.cmpy_code #not used 
	DEFINE l_net_amount LIKE cheque.net_pay_amt 
	DEFINE l_tax_amount LIKE cheque.net_pay_amt 
	DEFINE l_amount_text CHAR(17) 

	LET l_tax_amount = p_gross_amount * p_tax_per / 100 
	LET l_amount_text = l_tax_amount USING "&&&&&&&&&&&&&&.&&" 
	CASE p_tax_indicator 
		WHEN ("0") 
			LET l_tax_amount = 0 
		WHEN ("2") 
			LET l_tax_amount = l_amount_text[1,14] 
		WHEN ("3") 
			LET l_tax_amount = l_amount_text[1,14] 
			IF l_amount_text[16,17] != "00" THEN 
				LET l_tax_amount = l_tax_amount + 1 
			END IF 
	END CASE 
	LET l_net_amount = p_gross_amount - l_tax_amount 

	RETURN l_net_amount,l_tax_amount 
END FUNCTION 


