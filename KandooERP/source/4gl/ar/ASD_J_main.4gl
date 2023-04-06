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
GLOBALS "../ar/ASD_J_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_s_output CHAR(25) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_err_message CHAR(100) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_jmj_cust_cnt INTEGER 
DEFINE modu_kandoo_cust_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER # -> meta-errors (eg. db updates,etc.) 
DEFINE modu_err_cnt INTEGER # -> RECORD level errors 
DEFINE modu_verbose_ind SMALLINT 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
#########################################################################
# MAIN
#
# ASD_J - Debtor Load
# valid_load_file(get_url_load_file()) returning modu_load_file
#
# Not completed.. program can be called with multiple file names as argumnents... need to add tokenizer or remove this feture
#########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt  

	CALL setModuleId("ASD_J") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASD_J_main()
END MAIN