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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################################
# FUNCTION dispgpfunc(p_currency_code,p_cost_amt,p_sale_amt)
#
# FUNCTION disp_profit - Called by most line item entry screens.
# This logic used TO exist (AND still does) in each transaction
# entry program.  A central FUNCTION has been implemented FOR ease
# of maintanence.
############################################################################
FUNCTION dispgpfunc(p_currency_code,p_cost_amt,p_sale_amt) 
	DEFINE p_currency_code LIKE currency.currency_code 
	DEFINE p_sale_amt LIKE orderdetl.ext_price_amt 
	DEFINE p_cost_amt LIKE orderdetl.ext_cost_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arr_display RECORD 
		currency_code LIKE currency.currency_code, 
		ext_price_amt LIKE orderdetl.ext_price_amt, 
		ext_cost_amt LIKE orderdetl.ext_cost_amt, 
		profit_amt LIKE orderdetl.unit_price_amt, 
		profit_per FLOAT, ## do NOT ALTER data types. 
		markup_per FLOAT ## FLOAT IS necessary due TO possible VALUES 
	END RECORD 
	DEFINE l_float FLOAT 

	LET l_arr_display.currency_code = p_currency_code 
	
	IF p_cost_amt IS NULL THEN 
		LET l_arr_display.ext_cost_amt = 0 
	ELSE 
		LET l_arr_display.ext_cost_amt = p_cost_amt 
	END IF 
	
	IF p_sale_amt IS NULL THEN 
		LET l_arr_display.ext_price_amt = 0 
	ELSE 
		LET l_arr_display.ext_price_amt = p_sale_amt 
	END IF 
	
	LET l_arr_display.profit_amt = l_arr_display.ext_price_amt - l_arr_display.ext_cost_amt
	 
	IF l_arr_display.ext_price_amt = 0 THEN 
		LET l_float = 0 
	ELSE 
		LET l_float = 100 * (l_arr_display.profit_amt/l_arr_display.ext_price_amt) 
	END IF
	 
	LET l_arr_display.profit_per = l_float
	 
	IF l_arr_display.ext_cost_amt = 0 THEN 
		LET l_float = 0 
	ELSE 
		LET l_float = 100 * (l_arr_display.profit_amt/l_arr_display.ext_cost_amt) 
	END IF 
	
	LET l_arr_display.markup_per = l_float 

	#huho form A641 was missing
	OPEN WINDOW A641 with FORM "A641" 
	CALL windecoration_a("A641") 

	DISPLAY BY NAME l_arr_display.*	attribute(yellow) 
	DISPLAY BY NAME l_arr_display.currency_code	attribute(green) 

	--ERROR kandoomsg2("U",0001,"") 
	CALL eventsuspend()
	CLOSE WINDOW A641 

END FUNCTION 
############################################################################
# END FUNCTION dispgpfunc(p_currency_code,p_cost_amt,p_sale_amt)
############################################################################