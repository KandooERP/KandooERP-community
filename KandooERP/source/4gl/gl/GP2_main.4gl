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
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_coa RECORD LIKE coa.* 
	DEFINE glob_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE glob_rec_batchdetl RECORD LIKE batchdetl.* 
	DEFINE glob_rec_account RECORD LIKE account.* 
	DEFINE glob_rec_accounthist RECORD LIKE accounthist.* 
	DEFINE glob_rec_accountcur RECORD LIKE accountcur.* 
	DEFINE glob_rec_accounthistcur RECORD LIKE accounthistcur.* 
	DEFINE glob_rec_postrun RECORD LIKE postrun.* 
	DEFINE glob_run_total LIKE account.bal_amt 
	DEFINE glob_total_debit LIKE account.bal_amt 
	DEFINE glob_total_credit LIKE account.bal_amt 
	#DEFINE runner, l_where_text CHAR(800)
	#DEFINE l_query_text, runner, l_where_text CHAR(800)
	DEFINE glob_err_message STRING 
	DEFINE glob_autopost char(1) 
	DEFINE glob_fisc_year SMALLINT 
	DEFINE glob_counter SMALLINT 
	DEFINE glob_tempper SMALLINT 
	DEFINE glob_entries_for_batch INTEGER 
	DEFINE glob_start_no INTEGER 
	DEFINE glob_end_no INTEGER 

END GLOBALS 

###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_arr_rec_posting_report DYNAMIC ARRAY OF RECORD 
	jour_code LIKE journal.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	posting_status SMALLINT, #0=posted, 1-9 ERROR id 
	year_num LIKE coa.start_year_num, 
	period_num LIKE coa.start_period_num, 
	total_debit LIKE account.bal_amt, 
	total_credit LIKE account.bal_amt, 
	post_amt LIKE account.bal_amt, 
	post_flag boolean #double status - this one IS only FOR checkbox true/false status true = checked.. anything ELSE IS NOT checked.
END RECORD 

DEFINE modu_rep_idx SMALLINT

###########################################################################
# MAIN
#
# Purpose :  Posts batches TO the account ledger,
#                                 account currency,
#                                 account currency history,
#                                 account history,
#                         AND the account table.
#
###########################################################################
MAIN 
	DEFINE l_run_arg STRING

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GP2") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL GP2_main()
END MAIN
###########################################################################
# END MAIN
###########################################################################