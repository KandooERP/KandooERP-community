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
GLOBALS "../ar/AS7_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl"
############################################################
# Module Scope Variables
############################################################
DEFINE modu_sl_id LIKE kandoouser.sign_on_code 
DEFINE modu_rec_journal RECORD LIKE journal.* 
DEFINE modu_rec_period RECORD LIKE period.* 
DEFINE modu_rec_customerhist RECORD LIKE customerhist.* 
DEFINE modu_rec_invoicedetl RECORD LIKE invoicedetl.* 
DEFINE modu_rec_credithead RECORD LIKE credithead.* 
DEFINE modu_rec_creditdetl RECORD LIKE creditdetl.* 
DEFINE modu_rec_cashreceipt RECORD LIKE cashreceipt.* 
DEFINE modu_passed_desc LIKE batchdetl.desc_text 

DEFINE modu_rec_bal 
RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text 
END RECORD 

--DEFINE modu_arr_rec_period DYNAMIC ARRAY OF #array[400] OF
--	RECORD
--		year_num SMALLINT,
--		period_num SMALLINT,
--		post_req CHAR(1)
--	END RECORD

#DEFINE glob_fisc_year SMALLINT
#DEFINE glob_fisc_period was fisc_per SMALLINT
DEFINE modu_foundit SMALLINT 
DEFINE modu_all_ok SMALLINT 
DEFINE modu_i SMALLINT 
--DEFINE modu_idx SMALLINT

#DEFINE modu_rec_customertype RECORD LIKE customertype.* #not used
DEFINE modu_prev_cust_type LIKE customer.type_code 
DEFINE modu_prev_ord_ind LIKE ordhead.ord_ind 

DEFINE modu_rec_docdata 
RECORD 
	ref_num LIKE batchdetl.ref_num, 
	ref_text LIKE batchdetl.ref_text, 
	tran_date DATE, 
	currency_code LIKE batchdetl.currency_code, 
	conv_qty LIKE batchdetl.conv_qty 
END RECORD 

DEFINE modu_rec_detldata 
RECORD 
	post_acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	debit_amt LIKE batchdetl.debit_amt, 
	credit_amt LIKE batchdetl.credit_amt 
END RECORD 

DEFINE modu_rec_detltax 
RECORD 
	tax_code LIKE invoicedetl.tax_code, 
	ext_tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 

DEFINE modu_rec_taxtemp 
RECORD 
	tax_acct_code LIKE batchdetl.acct_code, 
	tax_amt LIKE invoicedetl.ext_tax_amt 
END RECORD 

DEFINE modu_rec_current 
RECORD 
	cust_type LIKE customer.type_code, 
	ar_acct_code LIKE arparms.ar_acct_code, 
	freight_acct_code LIKE arparms.freight_acct_code, 
	lab_acct_code LIKE arparms.lab_acct_code, 
	tax_acct_code LIKE arparms.tax_acct_code, 
	disc_acct_code LIKE arparms.disc_acct_code, 
	exch_acct_code LIKE arparms.exch_acct_code, 
	bal_acct_code LIKE arparms.ar_acct_code, 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	freight_amt LIKE invoicehead.freight_amt, 
	freight_tax_code LIKE invoicehead.freight_tax_code, 
	freight_tax_amt LIKE invoicehead.freight_tax_amt, 
	hand_amt LIKE invoicehead.hand_amt, 
	hand_tax_code LIKE invoicehead.hand_tax_code, 
	hand_tax_amt LIKE invoicehead.hand_tax_amt, 
	disc_amt LIKE invoicehead.disc_amt, 
	jour_code LIKE batchhead.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	ref_num LIKE batchdetl.ref_num, 
	base_debit_amt LIKE batchdetl.debit_amt, 
	base_credit_amt LIKE batchdetl.credit_amt, 
	currency_code LIKE currency.currency_code, 
	exch_ref_code LIKE exchangevar.ref_code 
END RECORD 

DEFINE modu_counter SMALLINT --scrn, 
DEFINE modu_per_post SMALLINT 
DEFINE modu_doit CHAR(1) 
DEFINE modu_try_again CHAR(1) 
DEFINE modu_sel_text CHAR(900) 
DEFINE modu_where_text STRING #char(900) 
DEFINE modu_client_cust_code LIKE customer.cust_code 
#DEFINE glob_rpt_date date #not used
DEFINE modu_rpt_time char(10) #only used in one LET statement... may be NOT really used.. 
DEFINE modu_its_ok INTEGER 
DEFINE modu_err_message CHAR(80) 
DEFINE modu_totaller money(15,2) 
DEFINE modu_cost_totaller money(15,2) 
DEFINE modu_disc_totaller money(15,2) 
#DEFINE glob_post_text CHAR(80)
#DEFINE glob_err_text CHAR(80)
DEFINE modu_inv_num LIKE invoicehead.inv_num 
DEFINE modu_cash_num LIKE cashreceipt.cash_num 
DEFINE modu_cred_num LIKE credithead.cred_num 
#DEFINE modu_rec_tmp_poststatus RECORD LIKE poststatus.* #not used
#DEFINE glob_rec_poststatus RECORD LIKE poststatus.*
DEFINE modu_stat_code LIKE poststatus.status_code 
#DEFINE modu_ans CHAR(1) #not used
#DEFINE glob_in_trans SMALLINT
DEFINE modu_posting_needed SMALLINT 
DEFINE modu_post_status LIKE poststatus.status_code 
#DEFINE glob_posted_journal LIKE batchhead.jour_num
DEFINE modu_select_text CHAR(3000) 
DEFINE modu_tran_type1_ind LIKE exchangevar.tran_type1_ind 
DEFINE modu_ref1_num LIKE exchangevar.ref1_num 
DEFINE modu_tran_type2_ind LIKE exchangevar.tran_type2_ind 
DEFINE modu_ref2_num LIKE exchangevar.ref2_num 
DEFINE modu_rec_exchangevar RECORD LIKE exchangevar.* 
#DEFINE glob_one_trans SMALLINT
DEFINE modu_set_retry SMALLINT 
#DEFINE glob_st_code SMALLINT
DEFINE modu_tmp_text CHAR(8) 
DEFINE modu_conv_qty LIKE invoicehead.conv_qty 
DEFINE modu_sv_conv_qty LIKE invoicehead.conv_qty 
DEFINE modu_again SMALLINT 



#######################################################
# MAIN
#
# \brief module : AS7.4gl
# Purpose : Customer History AND General Ledger Post Program
#######################################################
MAIN 
	DEFER quit 
	DEFER interrupt 
 
	CALL setModuleId("AS7") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	CALL AS7_main()
END MAIN