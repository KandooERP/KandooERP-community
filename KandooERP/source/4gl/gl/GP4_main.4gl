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
# \brief module GP4  Create journal batch closing Income AND Expense Account
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

###########################################################################
# MODULE Scope Variables
###########################################################################
	DEFINE modu_rec_coa RECORD LIKE coa.* 
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.* 
	--DEFINE modu_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE modu_rec_period RECORD LIKE period.* 
	DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE modu_rec_account RECORD LIKE account.* 
 
	DEFINE modu_rec_structure RECORD LIKE structure.* 
	DEFINE modu_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE modu_arr_rec_period DYNAMIC ARRAY OF RECORD 
		year_num SMALLINT, 
		period_num SMALLINT 
	END RECORD 
	DEFINE modu_arr_rec_coa DYNAMIC ARRAY OF RECORD 
		flex_code LIKE validflex.flex_code, 
		acct_code LIKE coa.acct_code, 
		desc_text LIKE coa.desc_text 
	END RECORD 
	DEFINE modu_err_message CHAR(40) 
	DEFINE modu_net_worth_acct LIKE account.acct_code
	DEFINE modu_net_worth_flex LIKE validflex.flex_code 
	DEFINE modu_ofs_debit money(15,2)
	DEFINE modu_ofs_credit money(15,2)
	DEFINE modu_fisc_year SMALLINT
	DEFINE modu_idx SMALLINT
	DEFINE modu_tempper SMALLINT	
	DEFINE modu_ledg_cnt SMALLINT
	DEFINE modu_multiledger_ind SMALLINT
	DEFINE modu_start_num SMALLINT
	DEFINE modu_length SMALLINT
	DEFINE modu_sel_text CHAR(800) 

###########################################################################
# MAIN
#
#
###########################################################################
MAIN 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP4") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module

	CALL GP4_main() 
END MAIN
###########################################################################
# END MAIN
###########################################################################