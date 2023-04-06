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
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
--GLOBALS 
--	DEFINE glob_base_currency LIKE glparms.base_currency_code 
--	DEFINE glob_bank RECORD LIKE bank.* 
--	DEFINE glob_where CHAR(2048) 
--END GLOBALS 

############################################################
# MAIN
# PC1 Cheque Reports
#
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PC1") 
	CALL ui_init(0) #Initial UI Init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL PC1_main()
END MAIN

