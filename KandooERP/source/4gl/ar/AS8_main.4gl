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
GLOBALS "../ar/AS8_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_arparmext RECORD LIKE arparmext.* 
DEFINE modu_rec_coa RECORD LIKE coa.* 
DEFINE modu_aging RECORD 
	age_date DATE, 
	service_fee DECIMAL(16,2), 
	over90_amt LIKE customer.bal_amt, 
	over60_amt LIKE customer.bal_amt, 
	over30_amt LIKE customer.bal_amt, 
	over1_amt LIKE customer.bal_amt, 
	current_amt LIKE customer.bal_amt, 
	current_per DECIMAL(6,2), 
	over1_per DECIMAL(6,2), 
	over30_per DECIMAL(6,2), 
	over60_per DECIMAL(6,2), 
	over90_per DECIMAL(6,2), 
	inv_date LIKE invoicehead.inv_date, 
	line_text LIKE invoicedetl.line_text, 
	com1_text LIKE invoicehead.com1_text, 
	com2_text LIKE invoicehead.com2_text, 
	year_num LIKE invoicehead.year_num, 
	period_num LIKE invoicehead.period_num, 
	int_acct_code LIKE arparmext.int_acct_code 
END RECORD 
DEFINE c LIKE rmsreps.page_num 
DEFINE modu_where_text CHAR(300)
DEFINE modu_query_text CHAR(300)


##############################################################################
# MAIN
#
#   - Program AS8  - Allows the user TO generate service fees
#                    FOR overdue accounts
##############################################################################
MAIN 
	DEFER quit 
	DEFER interrupt  

	CALL setModuleId("AS8") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL AS8_main()
END MAIN