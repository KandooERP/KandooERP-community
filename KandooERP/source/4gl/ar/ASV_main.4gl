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
GLOBALS "../ar/ASV_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
--DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
--DEFINE modu_rec_araudit RECORD LIKE araudit.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_sum_amt money(12,2) 
DEFINE modu_sum_cost money(12,2) 
DEFINE modu_sum_tax money(12,2) 
DEFINE modu_sum_paid money(12,2) 
DEFINE modu_sum_dist money(12,2) 
DEFINE modu_sum_app money(12,2) 
DEFINE modu_sum_cash money(12,2) 
DEFINE modu_sum_cred money(12,2) 
DEFINE modu_lab_percentage DECIMAL(5,2) 
DEFINE modu_frt_percentage DECIMAL(5,2) 
DEFINE modu_line_info CHAR(131) 
DEFINE modu_last_num INTEGER 
DEFINE modu_last_cust CHAR(8) 
DEFINE modu_cnt SMALLINT 
DEFINE modu_problem SMALLINT 
DEFINE modu_ans CHAR(1) 
##########################################################################
# MAIN
#
#
##########################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CALL setModuleId("ASV") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL ASV_main()
END MAIN