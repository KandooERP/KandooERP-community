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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC5_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_rec_globalrec RECORD 
		bank_code LIKE bank.bank_code, 
		name_acct_text LIKE bank.name_acct_text, 
		iban LIKE bank.iban, 
		acct_code LIKE bank.acct_code, 
		bank_currency_code LIKE bank.currency_code, 
		sheet_num LIKE bank.sheet_num, 
		sheet_date LIKE banking.bk_bankdt, 
		cb_bal_amt LIKE bank.state_base_bal_amt, 
		cb_close_amt LIKE bank.state_base_bal_amt, 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num, 
		end_date LIKE period.end_date, 
		gl_bal_amt LIKE bank.state_base_bal_amt, 
		gl_close_amt LIKE bank.state_base_bal_amt, 
		coa_text LIKE coa.desc_text, 
		detail_flag char(1) 
	END RECORD 
END GLOBALS 
###########################################################################
# MODULE Scope Variables
###########################################################################

###########################################################################
# MAIN
#
# GC5 Reconciliation Report
###########################################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GC5") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL GC5_main()
	
END MAIN
###########################################################################
# END MAIN
###########################################################################