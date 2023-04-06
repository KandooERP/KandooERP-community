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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASS_J_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_err_message CHAR(40)
--DEFINE modu_winds_text CHAR(40)
DEFINE modu_start_date DATE 
DEFINE modu_end_date DATE 
DEFINE modu_where_text CHAR(600) 
DEFINE modu_query_text CHAR(600) 
DEFINE modu_rec_jmj_impresttran RECORD LIKE jmj_impresttran.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
####################################################################
# MAIN
#
#
####################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		
	CALL setModuleId("ASS") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASS_J_main()
END MAIN