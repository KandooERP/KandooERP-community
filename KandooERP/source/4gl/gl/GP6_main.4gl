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
# MODULE Scope Variables
############################################################
DEFINE modu_sel_text CHAR(500)
--DEFINE modu_max_year SMALLINT 
DEFINE modu_debit_amt DECIMAL(15,2) 
DEFINE modu_credit_amt DECIMAL(15,2) 
DEFINE modu_acct_bal_amt DECIMAL(15,2) 
DEFINE modu_tot_bal_amt DECIMAL(15,2) 
DEFINE modu_tot_n_debit DECIMAL(15,2) 
DEFINE modu_tot_n_credit DECIMAL(15,2) 
DEFINE modu_bat_debit DECIMAL(15,2) 
DEFINE modu_bat_credit DECIMAL(15,2) 
DEFINE modu_tot_debit DECIMAL(15,2) 
DEFINE modu_tot_credit DECIMAL(15,2) 
DEFINE modu_net_sub DECIMAL(15,2) 
DEFINE modu_net_bat DECIMAL(15,2) 
DEFINE modu_net_unp DECIMAL(15,2) 
DEFINE modu_ledg_var DECIMAL(15,2) 
DEFINE modu_tot_ledg_amt DECIMAL(15,2) 
DEFINE modu_sub_ledg_amt DECIMAL(15,2)
DEFINE modu_tax_debits DECIMAL(15,2)
DEFINE modu_unp_tax_debit DECIMAL(15,2)
DEFINE modu_tax_credits DECIMAL(15,2)
DEFINE modu_unp_tax_credit DECIMAL(15,2) 
DEFINE modu_net_tax DECIMAL(15,2) 
DEFINE modu_tax_vendor LIKE vendortype.tax_vend_code 


###############################################################
# MAIN
#
# GP6    (Menu path GP6)
# This program IS run TO take INTO account all
# exchange variances in outstanding creditors AND debtors
# AND produces a REPORT.
###############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP6") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 
	CALL GP6_main()
END MAIN