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
GLOBALS "../ar/AW_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AW4_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_rec_arparmext RECORD LIKE arparmext.* 
DEFINE modu_rec_tentarbal RECORD LIKE tentarbal.* 
DEFINE modu_rec_coa RECORD LIKE coa.* 
DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
DEFINE modu_rec_credreas RECORD LIKE credreas.* 
--DEFINE modu_query_text CHAR(300) 
######################################################################################
# MAIN
#
#   - Program AW4  - generates appropriate transactions TO write off
#                    customer balances
######################################################################################
MAIN 
	DEFINE l_continue CHAR(1) 

	DEFER quit 
	DEFER interrupt
	
	CALL setModuleId("AW4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL AW4_main()
	
END MAIN