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
GLOBALS 
	DEFINE glob_rec_s_kandooreport RECORD LIKE kandooreport.* 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_s_output CHAR(50) 
DEFINE modu_load_file CHAR(100) 
DEFINE modu_err_message CHAR(110) 
--DEFINE l_query_text CHAR(400) 
DEFINE modu_err_text CHAR(250) 
DEFINE modu_kandoo_ar_cnt INTEGER 
DEFINE modu_kandoo_in_cnt INTEGER 
DEFINE modu_kandoo_rc_cnt INTEGER 
DEFINE modu_load_cnt INTEGER 
DEFINE modu_loadfile_cnt INTEGER 
DEFINE modu_rerun_cnt INTEGER 
DEFINE modu_err2_cnt INTEGER 
DEFINE modu_err_cnt INTEGER 
DEFINE modu_loadfile_ind SMALLINT 
DEFINE modu_unload_ind SMALLINT 
DEFINE modu_verbose_ind SMALLINT 
--DEFINE modu_rec_kandoouser RECORD LIKE kandoouser.* 
DEFINE modu_total_invoice_amt LIKE invoicehead.total_amt 
DEFINE modu_total_rec_amt LIKE invoicehead.total_amt 
DEFINE modu_load_ar_cnt INTEGER 
DEFINE modu_load_rc_cnt INTEGER 
DEFINE modu_load_in_cnt INTEGER 
DEFINE modu_tot_ar_cnt INTEGER 
DEFINE modu_process_cnt INTEGER 
DEFINE modu_ap_per DECIMAL(6,3) 
DEFINE modu_path_text LIKE loadparms.file_text 
DEFINE modu_load_ind LIKE loadparms.load_ind 


##########################################################################
# MAIN
#
# ASW - External AR Invoice/Receipt Load
##########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("ASW") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASW_main()
END MAIN