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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
############################################################
# MOPDULE Scope Variables
############################################################
DEFINE modu_rec_structure RECORD LIKE structure.* 
DEFINE modu_rpt_note LIKE rmsreps.report_text 
--DEFINE glob_rec_rmsreps.report_width_num LIKE rmsreps.report_width_num 
--DEFINE glob_rec_rmsreps.page_length_num LIKE rmsreps.page_length_num 
--DEFINE glob_rec_rmsreps.page_num LIKE rmsreps.page_num 
DEFINE modu_where_text CHAR(400) 
DEFINE modu_temp_text CHAR(20) 
############################################################
# MAIN
#
# GRJ - Consolidation Reporting Codes Report
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GRJ") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GRJ_main()
END MAIN