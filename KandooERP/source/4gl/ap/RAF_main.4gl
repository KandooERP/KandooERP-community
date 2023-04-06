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
GLOBALS "../pu/R_PU_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
DEFINE 
pr_options RECORD 
	head_detl_flag, 
	head_deliv_flag, 
	head_notes_flag, 
	line_detl_flag, 
	line_notes_flag, 
	status_flag CHAR(1), 
	sort_flag SMALLINT 
END RECORD, 
pr_purchhead RECORD LIKE purchhead.*, 
pr_order_lines, 
pr_vendor_orders, 
pr_report_orders INTEGER, 
pr_vendor_total, 
pr_report_total, 
pr_order_total FLOAT 

#######################################################################
# MAIN
#
# RAF Purchase Order Detail 2 Report
#######################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("RAF") -- albo 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 
	CALL RAF_main()
END MAIN