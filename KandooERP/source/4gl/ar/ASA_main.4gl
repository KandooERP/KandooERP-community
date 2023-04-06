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
GLOBALS "../ar/ASA_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_where_part CHAR(1200) 
DEFINE modu_query_text CHAR(2000) 
--DEFINE modu_answer CHAR(1) 
--DEFINE modu_ans CHAR(1) 
--DEFINE modu_id_flag SMALLINT 
--DEFINE modu_cnt SMALLINT 
--DEFINE modu_idx SMALLINT 
--DEFINE modu_err_flag SMALLINT 
--DEFINE modu_mrow SMALLINT 
--DEFINE modu_chosen SMALLINT 
##############################################################################
# MAIN
#
# \brief module ASA Allows the user TO PRINT mailing labels FOR Customers
##############################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("ASA") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASA_main()
END MAIN