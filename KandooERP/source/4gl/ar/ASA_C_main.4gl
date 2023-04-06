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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASA_C_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_where_part CHAR(700) 
DEFINE modu_where_part2 CHAR(700) 
DEFINE modu_query_text CHAR(700) 
DEFINE modu_report_path CHAR(100) 
DEFINE modu_runtext CHAR(100) 
DEFINE modu_time CHAR(10) 
DEFINE modu_retcode INTEGER 
--DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
##############################################################################
# MAIN
#
# \brief module ASA Allows the user TO PRINT mailing labels FOR Customers
# AND optionally exclude customers based on existing subscriptions
##############################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("ASA_C") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASA_C_main()
END MAIN