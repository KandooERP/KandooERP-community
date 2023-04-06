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
#  Note: This program was NOT modified FOR EFT's
#        Needs a day worth of corrections - Suspect NOT Used
# must NOT alter allocation
# of cheques AFTER this has been sent up , ELSE run them all again.
# Once the REPORT IS produced a cheque may be un-allocated, AND THEN
# allocated TO another voucher...potential FOR confusion eh?
# IF there IS cheque allocation TO a voucher which pays off a PO, AND
# the value of the allocation overpays the value of goods received on
# that PO, THEN we cannot dissect the amount TO an account, an error
# row IS written on the REPORT AND the cheque allocation details are printed.
# only works on fully paid vouchers
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
############################################################
# MAIN
#
# PC8 - Treasury REPORT
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("PC8") 
	CALL ui_init(0) #Initial UI Init
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL PC8_main()
END MAIN
