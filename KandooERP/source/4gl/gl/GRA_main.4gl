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
	DEFINE glob_rec_coa RECORD LIKE coa.* 
END GLOBALS
 
############################################################
# MODULEL Scope Variables
############################################################
--	DEFINE modu_line1 CHAR(130) 
--	DEFINE modu_line2 CHAR(130) 
	DEFINE modu_rept_curr_code LIKE currency.currency_code 
	DEFINE modu_conv_qty LIKE rate_exchange.conv_sell_qty 
	DEFINE modu_msg_ans CHAR(1) 
--	DEFINE modu_ans CHAR(1) 
	DEFINE modu_q1_text CHAR(500) 
--	DEFINE modu_where_part STRING 
--	DEFINE modu_query_text CHAR(890) 


############################################################
# MAIN
#
# Trial Balance Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRA") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GRA_main()
END MAIN