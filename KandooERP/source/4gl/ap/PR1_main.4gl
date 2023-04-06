{
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:44	$Id: $
}
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module : PR1
# Purpose : Detailed Account Aging

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PR1_GLOBALS.4gl"

############################################################
# Module Scope Variables
############################################################


############################################################
# Module Scope Variables
############################################################
{
DEFINE modu_agedate DATE 
DEFINE modu_conv_ind CHAR(1) 
DEFINE modu_tot_unpaid DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_o30 DECIMAL(16,2) 
DEFINE modu_tot_o60 DECIMAL(16,2) 
DEFINE modu_tot_o90 DECIMAL(16,2) 
DEFINE modu_tot_plus DECIMAL(16,2) 
DEFINE modu_pr_notes_flag CHAR(1) 
}
############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PR1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CREATE temp TABLE shuffle (tm_vend CHAR(8), 
	tm_name CHAR(30), 
	tm_cury CHAR(3), 
	tm_tele CHAR(12), 
	tm_date DATE, 
	tm_type CHAR(2), 
	tm_doc INTEGER, 
	tm_refer CHAR(20), 
	tm_late INTEGER, 
	tm_conv_qty FLOAT, 
	tm_amount decimal(16,2), 
	tm_unpaid decimal(16,2), 
	tm_cur decimal(16,2), 
	tm_o30 decimal(16,2), 
	tm_o60 decimal(16,2), 
	tm_o90 decimal(16,2), 
	tm_plus decimal(16,2)) with no LOG	 
	CREATE INDEX i_shuffle ON shuffle(tm_vend,tm_date, tm_doc)

	CALL ap_pr0(TRUE)
END MAIN 