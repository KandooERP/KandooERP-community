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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS5_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_custpallet RECORD LIKE custpallet.* 
DEFINE modu_rec_aging RECORD 
	age_date DATE, 
	hold_code LIKE holdreas.hold_code, 
	inactive_hold_code LIKE holdreas.hold_code, 
	inactive_days SMALLINT, 
	over90_amt LIKE customer.bal_amt, 
	over60_amt LIKE customer.bal_amt, 
	over30_amt LIKE customer.bal_amt, 
	over1_amt LIKE customer.bal_amt 
	END RECORD 
DEFINE modu_err_cnt SMALLINT 


#########################################################################
# MAIN
#
# Allows the user TO UPDATE account aging balances in the Customer
#########################################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("AS5") 
	CALL ui_init(0) #initial ui init 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL init_report_ar() #report default data from db-arparms
	CALL AS5_main()
END MAIN