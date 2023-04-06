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
############################################################
# Module Scope Variables
############################################################
DEFINE modu_intrate DECIMAL(10,2) 
DEFINE modu_interest_rate DECIMAL(9,1) 
DEFINE modu_proposed_date DATE 
DEFINE modu_days INTEGER 
DEFINE modu_header_text CHAR(40) 
DEFINE modu_input_year SMALLINT 
DEFINE modu_input_period SMALLINT 
DEFINE modu_report_type CHAR(1) 
####################################################################################
# MAIN
#
#
####################################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ASY_J") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASY_J_main()
END MAIN