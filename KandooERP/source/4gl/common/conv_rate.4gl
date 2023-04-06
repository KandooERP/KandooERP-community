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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# FUNCTION get_conv_rate(p_cmpy_parm, p_currency_parm, p_start_parm, p_conv_ind)
#
# get_conv_rate returns the conversion quantity dependent
# upon the parameters
############################################################
FUNCTION get_conv_rate(p_cmpy_parm, p_currency_parm, p_start_parm, p_conv_ind) 
	DEFINE p_cmpy_parm LIKE company.cmpy_code 
	DEFINE p_currency_parm LIKE rate_exchange.currency_code 
	DEFINE p_start_parm, conv_date LIKE rate_exchange.start_date 
	DEFINE p_conv_ind CHAR(1) 
	DEFINE l_ans CHAR(1) 
	DEFINE l_mesg_text CHAR(20) 
	DEFINE l_err_message CHAR(240) 
	DEFINE l_exch_rate LIKE rate_exchange.conv_buy_qty 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
	
	# The IS NOT NULL clause in the SELECT IS TO trap data LET through
	# by an old version of GZ8 (rate exchange maintenance).  This error
	# has now been corrected in GZ8.

	SELECT max(start_date) INTO conv_date FROM rate_exchange 
	WHERE cmpy_code = p_cmpy_parm 
	AND currency_code = p_currency_parm 
	AND start_date <= p_start_parm 
	AND conv_buy_qty IS NOT NULL 
	AND conv_sell_qty IS NOT NULL 

	IF conv_date IS NULL OR status = notfound THEN 
		LET l_mesg_text = p_currency_parm,", date ",p_start_parm 
		LET l_msgresp = kandoomsg("U", 9524, l_mesg_text) 
		LET l_err_message[001,080]="conv_rate - Valid exchange rate NOT found - 1.0 used" 
		LET l_err_message[081,160]=" Currency code : ",p_currency_parm 
		LET l_err_message[161,240]=" Date : ",p_start_parm 

		CALL errorlog(l_err_message) 

		RETURN "1.0" 
	END IF 

	LET l_exch_rate = exchange_rate(
		p_cmpy_parm, 
		p_currency_parm, 
		conv_date, 
		p_conv_ind) 
	RETURN 
		l_exch_rate 
END FUNCTION 
############################################################
# END FUNCTION get_conv_rate(p_cmpy_parm, p_currency_parm, p_start_parm, p_conv_ind)
############################################################

{
############################################################
# FUNCTION get_conv_rate2(p_cmpy_code, p_currency_code, p_trans_date, p_conv_ind)
#
# FUNCTION get_conv_rate2 returns the conversion quantity dependent
# upon the parameters, without displaying a MESSAGE TO the SCREEN
# IF no rate AT all can be found. get_settings_logFile() MESSAGEs are still created.
############################################################
FUNCTION get_conv_rate2(p_cmpy_code,p_currency_code,p_trans_date,p_conv_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_currency_code LIKE rate_exchange.currency_code 
	DEFINE p_trans_date LIKE rate_exchange.start_date
	DEFINE p_conv_ind CHAR(1) 
	DEFINE l_start_date LIKE rate_exchange.start_date 
	DEFINE l_err_message CHAR(240) 
	DEFINE l_exch_rate LIKE rate_exchange.conv_buy_qty 

	SELECT max(start_date) INTO l_start_date FROM rate_exchange 
	WHERE cmpy_code = p_cmpy_code 
	AND currency_code = p_currency_code 
	AND start_date <= p_trans_date 
	AND conv_buy_qty IS NOT NULL 
	AND conv_sell_qty IS NOT NULL 

	IF l_start_date IS NULL OR status = notfound THEN 
		LET l_err_message[001,080] = "get_conv_rate - Valid exchange rate NOT found - 1.0 used" 
		LET l_err_message[081,160]=" Currency code : ",p_currency_code 
		LET l_err_message[161,240]=" Date : ",p_trans_date 
		CALL errorlog(l_err_message) 
		RETURN 1.0 
	END IF 

	LET l_exch_rate = exchange_rate(
		p_cmpy_code, 
		p_currency_code, 
		l_start_date, 
		p_conv_ind) 
		
	RETURN l_exch_rate 
END FUNCTION 
############################################################
# END FUNCTION get_conv_rate2(p_cmpy_code, p_currency_code, p_trans_date, p_conv_ind)
############################################################
}

############################################################
# FUNCTION exchange_rate(p_cmpy_code, p_currency_code, p_start_date, p_conv_ind)
#
# FUNCTION exchange_rate - returns the exchange rate FOR the
#                          given date AND type
############################################################
FUNCTION exchange_rate(p_cmpy_code,p_currency_code,p_start_date,p_conv_ind) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_currency_code LIKE rate_exchange.currency_code 
	DEFINE p_start_date LIKE rate_exchange.start_date 
	DEFINE p_conv_ind CHAR(1) 
	DEFINE l_rec_rate_exchange RECORD LIKE rate_exchange.* 

	SELECT * INTO l_rec_rate_exchange.* 
	FROM rate_exchange 
	WHERE cmpy_code = p_cmpy_code 
	AND currency_code = p_currency_code 
	AND start_date = p_start_date 
	IF status = notfound THEN 
		RETURN 1 
	END IF 

	CASE p_conv_ind 
		WHEN ("B") 
			IF l_rec_rate_exchange.conv_buy_qty IS NULL OR l_rec_rate_exchange.conv_buy_qty = 0 THEN 
				LET l_rec_rate_exchange.conv_buy_qty = 1.0 
			END IF 
			RETURN l_rec_rate_exchange.conv_buy_qty 
			
		WHEN ("S") 
			IF l_rec_rate_exchange.conv_sell_qty IS NULL OR l_rec_rate_exchange.conv_sell_qty = 0 THEN 
				LET l_rec_rate_exchange.conv_sell_qty = 1.0 
			END IF 
			
			RETURN l_rec_rate_exchange.conv_sell_qty
			 
		OTHERWISE 
			IF l_rec_rate_exchange.conv_budg_qty IS NULL OR l_rec_rate_exchange.conv_budg_qty = 0 THEN 
				LET l_rec_rate_exchange.conv_budg_qty = 1.0 
			END IF 
			
			RETURN l_rec_rate_exchange.conv_budg_qty 
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION exchange_rate(p_cmpy_code, p_currency_code, p_start_date, p_conv_ind)
############################################################