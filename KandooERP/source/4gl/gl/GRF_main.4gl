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
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_q1_text STRING 
	DEFINE glob_where_part STRING -- CHAR(800) 
	DEFINE glob_query_text STRING -- CHAR(890) 
	DEFINE glob_debit_amt LIKE accounthist.debit_amt 
	DEFINE glob_credit_amt LIKE accounthist.credit_amt 
	DEFINE glob_open_amt LIKE account.open_amt 
	DEFINE glob_open_drcr LIKE account.open_amt 
	DEFINE glob_rept_curr_code LIKE batchdetl.currency_code 
	DEFINE glob_conv_qty LIKE rate_exchange.conv_sell_qty 
END GLOBALS 
############################################################
# MAIN
#
# Trial Balance - Pre-close amounts
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GRF") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GRF_main()
END MAIN