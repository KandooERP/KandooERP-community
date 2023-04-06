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
# GLOBAL SCOPE VARIABLES
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 

############################################################
# MODULE SCOPE VARIABLES
############################################################
	--DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE modu_query_text1 CHAR(1500) 
	DEFINE modu_query_text2 CHAR(1500) 
	DEFINE modu_where_part CHAR(1500) 
	DEFINE modu_len SMALLINT 
	DEFINE modu_s SMALLINT 
	DEFINE modu_col SMALLINT 
	DEFINE modu_sel_cnt INTEGER 
	DEFINE modu_cmpy_head CHAR(80) 
	DEFINE modu_rep_type CHAR(1) 
	DEFINE modu_year_num1 LIKE period.year_num 
	DEFINE modu_year_num2 LIKE period.year_num 
	DEFINE modu_part_level LIKE invoicedetl.level_code 
	DEFINE modu_period_num1 LIKE period.period_num 
	DEFINE modu_period_num2 LIKE period.period_num 
	DEFINE modu_nilval CHAR(1) 
	DEFINE modu_report_tot1 LIKE invoicedetl.line_total_amt 
	DEFINE modu_report_tot2 LIKE invoicedetl.line_total_amt 
	DEFINE modu_pagebr CHAR(1) 
#####################################################################
# MAIN
#
# Sales Margin by Item Report
# CALL security ("S1D") - IS this actually S1D ??? (s1d.4gl/mk does NOT l_exist)
#####################################################################
MAIN 
	DEFER interrupt 
	DEFER quit 
	
	CALL setModuleId("AEF") 
	CALL ui_init(0) #Initial UI Init
	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 
	CALL AEF_main()
END MAIN