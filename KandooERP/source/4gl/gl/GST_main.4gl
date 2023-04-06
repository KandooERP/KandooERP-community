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
	DEFINE modu_rec_batchhead RECORD LIKE batchhead.*
	DEFINE modu_rec_batchdetl RECORD LIKE batchdetl.*
	DEFINE modu_rec_bdimport RECORD 
		cmpy_code CHAR(2), #company id 
		jour_code CHAR(3), #journal type 
		jour_num INTEGER, #batch number 
		seq_num INTEGER, #sequence number 
		tran_type_ind CHAR(3), #transaction type 
		analysis_text CHAR(16), #analysis text entered 
		tran_date DATE, #date 
		ref_text CHAR(10), #reference OR source id 
		ref_num INTEGER, #reference document 
		acct_code CHAR(18), #account code can join coa_key 
		desc_text CHAR(30), #description 
		debit_amt DECIMAL(12,2), #debit amount 
		credit_amt DECIMAL(12,2), #credit amount 
		currency_code CHAR(3), #item currency code 
		conv_qty FLOAT, #currency conversion rate 
		for_debit_amt DECIMAL(14,2), #foreign currency debit val 
		for_credit_amt DECIMAL(14,2), #foreign currency credit val 
		stats_qty decimal(15,3) # quantity amount IF used 
	END RECORD 
	DEFINE modu_prev_jour_num LIKE batchhead.jour_num
	DEFINE modu_prev_jour_code LIKE batchhead.jour_code
	DEFINE modu_rec_period RECORD LIKE period.*
	DEFINE modu_arr_rec_period array[310] OF RECORD 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD
	DEFINE modu_seq_number SMALLINT
	DEFINE modu_idx SMALLINT
	DEFINE modu_sel_text CHAR(800)
	DEFINE modu_runner CHAR(800)
	DEFINE modu_where_part CHAR(800)
	DEFINE modu_err_message CHAR(60)
	DEFINE modu_query_text CHAR(900)
	DEFINE modu_msgresp CHAR(1)
	DEFINE modu_try_again CHAR(1)
	DEFINE modu_fisc_year SMALLINT 
	DEFINE modu_tempper SMALLINT 

############################################################
# MAIN
#
# \brief module GST consolidates batches TO another machine, OUTPUT via RMS
############################################################
MAIN 
	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("GST") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	CALL GST_main()
END MAIN