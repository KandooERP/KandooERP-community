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
# \file
# \brief module : A27
# Purpose : allows the user TO edit  Accounts Receivable Invoices
#           updating inventory
#
#
#   Some invoices can be edited AND some cannot.
#
#   InvInd  Source Allowed  Notes
#   ---------------------------------------------------------------------
#   1       AR A21  Yes     Normal AR invoice
#   2       OE O54  No      No longer used.
#   3       JM J31  No      Use Job Mgt Module
#   4       AR A2A  Yes     Debtor Adjustment
#   5       EO E53  Yes     Not recommended but no real reason why NOT.
#   6       EO E53  Yes     Not recommended but no real reason why NOT.
#   7       SS K11  No      Use Subscriptions module
#   8       AR A2R  No      Debtors Refund. Invoice must match voucher.
#   9       AR A21  Yes     AR Sundry Charge/Interest Charge
#   P       AP P29  No      AP Charge Thru Expense. Inv must equal voucher
#   X       AR ASL  Yes     Depends on invoice source. Needed TO fix probs.
#   S       WO W91  No      Check Building Products Module
#   L       WO W91  No      Check Building Products Module
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A2_GROUP_GLOBALS.4gl"  
GLOBALS "../ar/A27_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("A27") 
	CALL ui_init(0) #Initial UI Init

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	CALL A27_main() 
END MAIN 
############################################################
# END MAIN
############################################################