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

	Source code beautified by beautify.pl on 2020-01-02 10:35:30	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION rept_curr(p_cmpy, p_base_currency_code)
#
# Displays OPTIONS FOR user TO enter a currency AND rate
# TO be used WHEN printing a REPORT
############################################################
FUNCTION rept_curr(p_cmpy,p_base_currency_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_base_currency_code LIKE glparms.base_currency_code 

	DEFINE l_rec_currency RECORD LIKE currency.* 
	#DEFINE l_rec_rate_exchange RECORD LIKE rate_exchange.*
	DEFINE l_rept_curr_code LIKE currency.currency_code 
	DEFINE l_rate_date DATE 
	DEFINE l_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW g216 with FORM "G216" 
	CALL windecoration_g("G216") 

	LET l_rept_curr_code = p_base_currency_code 
	LET l_rate_date = today 
	LET l_conv_qty = 1.0 

	LET l_msgresp = kandoomsg("G",1010,"") 
	#1010 Enter Report Currency Details; OK TO Continue.
	INPUT 
	l_rept_curr_code, 
	l_rate_date, 
	l_conv_qty 
	WITHOUT DEFAULTS 
	FROM 
	rept_curr_code, 
	rate_date, 
	conv_qty 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","reptcurwind","input-report_currency") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(l_rept_curr_code) 
			LET l_rept_curr_code = show_curr(p_cmpy) 
			DISPLAY l_rept_curr_code TO rept_curr_code 

		AFTER FIELD rept_curr_code 
			IF l_rept_curr_code IS NULL THEN 
				LET l_rept_curr_code = p_base_currency_code 
			END IF 
			SELECT * INTO l_rec_currency.* FROM currency 
			WHERE currency_code = l_rept_curr_code 
			IF status = notfound THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD Not Found; Try Window
				NEXT FIELD _rept_curr_code 
			ELSE 
				CALL get_conv_rate(
					p_cmpy, 
					l_rept_curr_code, 
					l_rate_date, 
					CASH_EXCHANGE_SELL) 
				RETURNING l_conv_qty
				 
				DISPLAY l_rec_currency.desc_text TO desc_text 
				DISPLAY l_conv_qty TO l_conv_qty 

			END IF 

		AFTER FIELD rate_date 
			IF l_rate_date IS NULL THEN 
				LET l_rate_date = today 
			END IF 
			CALL get_conv_rate(
				p_cmpy, 
				l_rept_curr_code, 
				l_rate_date, 
				CASH_EXCHANGE_SELL) 
			RETURNING l_conv_qty 
			
			DISPLAY l_conv_qty TO conv_qty 

		AFTER FIELD conv_qty 
			IF l_rept_curr_code = p_base_currency_code 
			AND l_conv_qty != 1.0 THEN 
				LET l_msgresp = kandoomsg("G",9533,"") 
				#9533 "Base currency selected - Rate cannot be changed"
				NEXT FIELD rept_curr_code 
			END IF 

	END INPUT 

	CLOSE WINDOW g216 
	IF int_flag OR quit_flag THEN 
		RETURN "",0 
	END IF 

	RETURN l_rept_curr_code, l_conv_qty 
END FUNCTION 


