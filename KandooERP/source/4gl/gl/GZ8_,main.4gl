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
#Currency Maintenance
# \brief module - GZ8
# Purpose - Currency Conversion Rates
###########################################################################
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_arr_rec_currency DYNAMIC ARRAY OF RECORD #array[250] OF 
		currency_code LIKE currency.currency_code, 
		desc_text LIKE currency.desc_text, 
		symbol_text LIKE currency.symbol_text 
	END RECORD 
	DEFINE glob_rec_rate_exchange RECORD LIKE rate_exchange.* 
	DEFINE glob_base_curr_code LIKE glparms.base_currency_code 
	#DEFINE counter SMALLINT
	#DEFINE l_idx SMALLINT
	#DEFINE cnt  SMALLINT
	#DEFINE err_flag  SMALLINT
	#DEFINE ans CHAR(1)
END GLOBALS 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	CALL setModuleId("GZ8") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 
	CALL authenticate(getmoduleid()) #authenticate
	--CALL init_g_gl() #init g/gl general ledger module # is not required for Currency Codes Maint. KD-2128 

	CALL GZ8_main()
	 
END MAIN 
###########################################################################
# END MAIN
###########################################################################
