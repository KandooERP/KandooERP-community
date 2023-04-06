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
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AST_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_tax RECORD LIKE tax.* 
DEFINE modu_rec_term RECORD LIKE term.* 
DEFINE modu_cred_reason LIKE arparms.reason_code 
DEFINE modu_acct_code LIKE prodledg.acct_code 
DEFINE modu_coa_desc_text LIKE coa.desc_text 
DEFINE modu_line_text CHAR(30) 
DEFINE modu_inv_date LIKE invoicehead.inv_date 
DEFINE modu_year_num LIKE invoicehead.year_num 
DEFINE modu_period_num LIKE invoicehead.period_num 
DEFINE modu_com1_text LIKE invoicehead.com1_text 
DEFINE modu_com2_text LIKE invoicehead.com2_text 
DEFINE modu_cust_code LIKE customer.cust_code 
DEFINE modu_next_seq_num LIKE customer.next_seq_num 
DEFINE modu_ytds_amt LIKE customer.ytds_amt 
DEFINE modu_mtds_amt LIKE customer.mtds_amt 
DEFINE modu_cred_bal_amt LIKE customer.cred_bal_amt 
DEFINE modu_temp_curr_amt LIKE customer.curr_amt 
DEFINE modu_temp_over1_amt LIKE customer.over1_amt 
DEFINE modu_temp_over30_amt LIKE customer.over30_amt 
DEFINE modu_temp_over60_amt LIKE customer.over60_amt 
DEFINE modu_temp_over90_amt LIKE customer.over90_amt 
DEFINE modu_temp_bal_amt LIKE customer.bal_amt 


####################################################################
# MAIN
#
#   Program: AST - AR Debtors Take-on Adjustments
#   Description: Allows debtors take-on balances TO be quickly
#                entered INTO system AND creating the necessary
#                supporting transactions.
#
#                Creates an invoice IF adjustment IS positive
#                Creates a credit IF adjustment IS negative
####################################################################
MAIN 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	
	CALL setModuleId("AST") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 
	CALL AST_main()
END MAIN