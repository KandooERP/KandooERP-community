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
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AW_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AW1_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE glob_rec_aging RECORD 
	current_from LIKE customer.bal_amt, 
	current_to LIKE customer.bal_amt, 
	over1_from LIKE customer.bal_amt, 
	over1_to LIKE customer.bal_amt, 
	over30_from LIKE customer.bal_amt, 
	over30_to LIKE customer.bal_amt, 
	over60_from LIKE customer.bal_amt, 
	over60_to LIKE customer.bal_amt, 
	over90_from LIKE customer.bal_amt, 
	over90_to LIKE customer.bal_amt 
END RECORD 
DEFINE glob_where2_text CHAR(1000) 


#################################################################################
# MAIN
#
#   - Program AW1  - Allows the user TO generate a list of customers
#                    FOR balance write offs
#################################################################################
MAIN 
	DEFER quit 
	DEFER interrupt  

	CALL setModuleId("AW1") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A658 with FORM "A658" 
	CALL windecoration_a("A658") 
	CALL AW1_main()
END MAIN