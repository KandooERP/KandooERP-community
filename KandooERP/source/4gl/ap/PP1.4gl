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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PP_GROUP_GLOBALS.4gl" 
GLOBALS "../common/postfunc_GLOBALS.4gl" 

DEFINE t_arr_rec_period TYPE AS RECORD 
	year_num LIKE period.year_num, 
	period_num LIKE period.period_num, 
	ap_object CHAR(10),
	approval_status NCHAR(15),
	readiness NCHAR(15),
	objects_count SMALLINT,
	post_req BOOLEAN 
END RECORD 

DEFINE modu_sl_id LIKE kandoouser.sign_on_code 
DEFINE modu_rec_vendorhist RECORD LIKE vendorhist.* 
DEFINE modu_rec_debithead RECORD LIKE debithead.* 
DEFINE modu_rec_bal_rec RECORD 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text 
END RECORD 
DEFINE modu_prev_vend_type LIKE vendor.type_code 

DEFINE t_rec_voucher_basic TYPE AS RECORD 
	ref_num LIKE batchdetl.ref_num, 	# voucher number
	ref_text LIKE batchdetl.ref_text,   # vendor code
	tran_date DATE, 
	currency_code LIKE currency.currency_code, 
	conv_qty LIKE rate_exchange.conv_buy_qty 
END RECORD

DEFINE modu_rec_docdata t_rec_voucher_basic

DEFINE t_rec_vouchedist_detldata TYPE AS RECORD 
	post_acct_code LIKE batchdetl.acct_code, 
	desc_text LIKE batchdetl.desc_text, 
	stats_qty LIKE batchdetl.stats_qty, 
	analysis_text LIKE batchdetl.analysis_text, 
	debit_amt LIKE batchdetl.debit_amt, 
	credit_amt LIKE batchdetl.credit_amt 
END RECORD 
DEFINE modu_rec_vouchedist_detldata t_rec_vouchedist_detldata

DEFINE t_rec_current TYPE AS RECORD
	vend_type LIKE vendor.type_code, 
	pay_acct_code LIKE apparms.pay_acct_code, 
	disc_acct_code LIKE apparms.disc_acct_code, 
	exch_acct_code LIKE apparms.exch_acct_code, 
	bal_acct_code LIKE apparms.pay_acct_code, 
	tran_type_ind LIKE batchdetl.tran_type_ind, 
	disc_amt LIKE debithead.disc_amt, 
	jour_code LIKE batchhead.jour_code, 
	jour_num LIKE batchhead.jour_num, 
	ref_num LIKE batchdetl.ref_num, 
	base_debit_amt LIKE batchdetl.debit_amt, 
	base_credit_amt LIKE batchdetl.credit_amt, 
	currency_code LIKE currency.currency_code, 
	exch_ref_code LIKE exchangevar.ref_code, 
	tax_vend_code LIKE vendortype.tax_vend_code 
END RECORD 
DEFINE modu_rec_current  t_rec_current

DEFINE mod_arr_rec_reports_to_print DYNAMIC ARRAY OF RECORD  # array containing the reports on journal to be printed
	jour_code LIKE batchhead.jour_code,
	jour_num LIKE batchhead.jour_num
END RECORD
DEFINE mdl_report_num SMALLINT    # number of report to print
DEFINE modu_sv_conv_qty LIKE batchdetl.conv_qty 
DEFINE modu_doc_vendor_code LIKE vendor.vend_code 
DEFINE modu_all_ok SMALLINT 
DEFINE modu_flag_cheques SMALLINT 
DEFINE modu_rpt_output NCHAR(80) 
DEFINE modu_try_again CHAR(1) 
DEFINE modu_counter SMALLINT 
DEFINE modu_vouch_code LIKE voucher.vouch_code 
DEFINE modu_debit_num LIKE debithead.debit_num 
DEFINE modu_cheq_code LIKE cheque.cheq_code 
DEFINE modu_bank_acct_code LIKE cheque.bank_acct_code 
DEFINE modu_stat_code LIKE poststatus.status_code -- alch 
DEFINE modu_post_status LIKE poststatus.status_code 
DEFINE modu_select_text STRING
DEFINE modu_rpt_wid SMALLINT 
DEFINE modu_rec_exchangevar RECORD LIKE exchangevar.* 
DEFINE modu_set_retry SMALLINT 
DEFINE modu_rec_postwhtax RECORD LIKE postwhtax.* 
DEFINE modu_rec_wholdtax RECORD LIKE wholdtax.* 
DEFINE modu_rec_postaptrans RECORD LIKE postaptrans.* 
DEFINE modu_option_control_entry_per_voucher BOOLEAN    # do one balance entry on ctrl account per VOUCHER
DEFINE modu_option_control_entry_per_vendtype BOOLEAN    # do one balance entry on ctrl account per vendor type
DEFINE modu_option_control_entry_per_currency BOOLEAN    # do one balance entry on ctrl account per currency

DEFINE modu_rpt_idx SMALLINT  #rmsreps array index
DEFINE modu_sel_text STRING 

DEFINE modu_rec_postrun RECORD like postrun.*    # defined as module scope because of problems if define as local in REPORT

# DEFINE CURSORS AND PREPARED
DEFINE crs_vouchers_status CURSOR
DEFINE crs_vouchers_to_post CURSOR
DEFINE crs_voucherdist_scan CURSOR
DEFINE crs_voucher_dist_ready CURSOR
DEFINE crs_postvoucher_scan_all CURSOR
DEFINE crs_postvoucher_ready CURSOR
DEFINE crs_upd_postdebithead_undo CURSOR  
DEFINE crs_join_posdebithead_vendor CURSOR 
DEFINE crs_join_posdebithead_vendor_ko CURSOR 
DEFINE crs_debithead_notflag_period CURSOR 
DEFINE crs_postvoucher_sums_vendor CURSOR
DEFINE crs_upd_vendorhist CURSOR
DEFINE crs_postdebithead_period CURSOR
DEFINE crs_debitdist_debitcode_vendcode CURSOR
DEFINE crs_postdebithead_scan CURSOR
DEFINE crs_join_cheque_vendor CURSOR
DEFINE cd_curs CURSOR
DEFINE crs_posttemp_uniq_acctcode_currency CURSOR
DEFINE crs_posttemp_acctcode_currency CURSOR

DEFINE prp_insert_postvoucher PREPARED
DEFINE prp_update_voucher_posted PREPARED
DEFINE prp_update_voucher_journum_postdate PREPARED
DEFINE prp_insert_posttemp PREPARED
DEFINE prp_delete_postvoucher_all PREPARED
DEFINE prp_update_jobledger PREPARED
DEFINE prp_update_debithead_unflag PREPARED
DEFINE prp_delete_postdebithead PREPARED
DEFINE prp_insert_postdebithead PREPARED
DEFINE prp_update_debithead_flag PREPARED
DEFINE prp_update_vendorhist PREPARED
DEFINE prp_update_postvoucher PREPARED
DEFINE prp_update_vendorhist_purchase PREPARED
DEFINE prp_update_postdebithead PREPARED
DEFINE pr_update_vendorhist_debit PREPARED
DEFINE prp_update_debithead_journum PREPARED
DEFINE prp_insert_postcheque PREPARED
DEFINE prp_insert_postwhtax PREPARED
DEFINE prp_insert_postaptrans PREPARED
DEFINE prp_update_cheque_flag PREPARED
DEFINE prp_update_postvoucher_journum PREPARED
DEFINE  prp_update_postdebithead_journum PREPARED
DEFINE prp_update_postcheque_journum PREPARED
DEFINE prp_update_postexchvar_journum PREPARED
DEFINE prp_update_postaptrans_journum PREPARED
DEFINE prp_update_batchhead PREPARED

# CONSTANT where_clauses for the tables
CONSTANT CONS_BASE_WHERECLAUSE_VOUCHER_1 = " AND voucher.post_flag = 'N' "
CONSTANT CONS_BASE_WHERECLAUSE_VOUCHER_2 = " AND voucher.approved_code = 'Y' AND voucher.total_amt = voucher.dist_amt "
CONSTANT CONS_BASE_WHERECLAUSE_DEBITHEAD = " AND post_flag = 'N' AND total_amt > 0 "
CONSTANT CONS_BASE_WHERECLAUSE_CHEQUE = " AND post_flag = 'N' "
CONSTANT CONS_BASE_WHERECLAUSE_EXCHANGEVAR = " AND posted_flag = 'N' AND source_ind = 'P' "

############################################################
# FUNCTION PP1_main()
# RETURN VOID
#
# PP1 - Account Payable Posting Process
############################################################
FUNCTION PP1_main() 
--	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_tasks_finished SMALLINT

	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	CALL setModuleId("PP1") 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	# we cease the postatus use as a reference, will just use transactions
	--SELECT * INTO glob_rec_poststatus.* 
	--FROM poststatus 
	--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--AND module_code = "AP" 

--	IF sqlca.sqlcode THEN # 3507 "Status cannot be found - cannot post - ABORTING!"
--		ERROR "System could not find any valid postStatus entries in poststatus for AP and company ",glob_rec_kandoouser.cmpy_code 
--		CALL fgl_winmessage("ERROR",kandoomsg2("U",3507,glob_rec_kandoouser.cmpy_code ),"ERROR") # 3507 "Status cannot be found - cannot post - ABORTING!"
--		ERROR "Possible reason, the Kandoo Database you are using is corrupted" 
--		SLEEP 5 
--		EXIT PROGRAM 
--	END IF 

	LET glob_st_code = glob_rec_poststatus.status_code 
	LET modu_post_status = glob_rec_poststatus.status_code 

	IF glob_rec_poststatus.post_running_flag = "Y" THEN 
		CALL fgl_winmessage("ERROR",kandoomsg2("U",3508,glob_rec_poststatus.user_code),"ERROR") # 3508 "Post IS already running - Cannot run"
		EXIT PROGRAM 
	END IF 

	LET modu_option_control_entry_per_voucher = TRUE  # create on ctrl account entry per voucher
	LET modu_option_control_entry_per_vendtype = FALSE
	LET modu_option_control_entry_per_currency = FALSE
--	IF modu_post_status < 99 THEN 
--		# 3509 Error Has Occurred In Previous Post - Rollback will be commenced"
--		CALL fgl_winmessage("ERROR",kandoomsg2("U",3509,""),"ERROR")
--		CALL disp_poststatus("AP") 
--	END IF 

	LET modu_sl_id = "AP" 
	LET modu_all_ok = 1 
--	LET modu_rpt_wid = "132" 
	#now done it CALL init_p_ap() #init P/AP module
	#SELECT * INTO pr_apparms.* FROM apparms
	#  WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#    AND parm_code = "1"
	#IF sqlca.sqlcode = NOTFOUND THEN
	#   # 3510 " AP Parameters missing "
	#   LET l_msgresp = kandoomsg("P",5016,"")
	#   EXIT PROGRAM
	#END IF
	--SELECT * 
	--INTO glob_rec_glparms.* 
	--FROM glparms 
	--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	--IF sqlca.sqlcode = NOTFOUND THEN 
	--	# 3511 " GL Parameters missing "
	--	ERROR kandoomsg2("G",5007,"") 
	--	EXIT PROGRAM 
	--END IF 

	#  Add a doc_num field TO the posttemp table so as TO uniquely
	#  identify cheques in the posting tables FOR later UPDATE with
	#  the journal number
	#
	IF NOT fgl_find_table("posttemp") THEN	
		CREATE TEMP TABLE posttemp 
		( 
		ref_num INTEGER, 
		ref_text CHAR(10), 
		post_acct_code CHAR(18), 
		desc_text CHAR(40), 
		debit_amt DECIMAL(16,2), 
		credit_amt DECIMAL(16,2), 
		base_debit_amt DECIMAL(16,2), 
		base_credit_amt DECIMAL(16,2), 
		currency_code CHAR(3), 
		conv_qty FLOAT, 
		tran_date DATE, 
		stats_qty DECIMAL(15,3), 
		analysis_text CHAR(16), 
		pay_acct_code CHAR(18), 
		doc_num INTEGER 
		) WITH NO LOG 
		CREATE INDEX posttemp_idx1 ON posttemp(pay_acct_code) 
	END IF

	IF NOT fgl_find_table("posterrors") THEN	
		CREATE TEMP TABLE posterrors(textline CHAR(80)) WITH NO LOG
	END IF 

	OPEN WINDOW P147 with FORM "P147_new" 
	CALL winDecoration_p("P147") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL PP1_init_cursors_and_prepares()	# gather here all cursors and prepares ONCE
	WHILE(TRUE)
		CALL organize_posting_tasks() RETURNING l_tasks_finished
		IF l_tasks_finished THEN
	 		EXIT WHILE
	 	END IF
	END WHILE
	CLOSE WINDOW P147 
END FUNCTION   # PP1_main


FUNCTION PP1_init_cursors_and_prepares()
# This functions prepares all necessary cursors and prepared statements ONCE in the program
# this is an performance optimization best pratice

	DEFINE l_sql_statement STRING
	# Prepare prepared statements

	# Cursors and functions in post_vouchers function
	# function post_vouchers  ( old cursor)
	LET l_sql_statement = "SELECT postvoucher.cmpy_code, ", 
	" postvoucher.vouch_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_date, ", 
	" postvoucher.currency_code, ", 
	" postvoucher.conv_qty, ", 
	" vendor.type_code ", 
	"FROM postvoucher, vendor ", 
	"WHERE postvoucher.cmpy_code = ? ",
	"AND postvoucher.post_flag != 'Y' ", 
	"AND postvoucher.year_num = ? ", 
	"AND postvoucher.period_num = ? ",
	"AND postvoucher.total_amt = postvoucher.dist_amt ", 
	"AND postvoucher.cmpy_code = vendor.cmpy_code ", 
	"AND postvoucher.vend_code = vendor.vend_code ", 
	"ORDER BY postvoucher.cmpy_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_code " 
	CALL crs_postvoucher_ready.Declare(l_sql_statement)

	# New cursor managed by REPORT GROUPs
	# join data between voucher being posted + voucherdist data
	{ are 2 cursors really useful? No I don't think so: keep this one as a backup and directly query on voucher and not postvoucher
	this postvoucher table makes mess if 2 users launch PP1 at the same time, because all selection is mixed in one table ...
	LET l_sql_statement = "SELECT postvoucher.cmpy_code, ", 
	" postvoucher.vouch_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_date, ", 
	" postvoucher.currency_code, ", 
	" postvoucher.conv_qty, ", 
	" vendor.type_code, ",
	" voucherdist.acct_code,",
	" voucherdist.desc_text,",
	" voucherdist.dist_qty,",
	" voucherdist.analysis_text,",
	" voucherdist.dist_amt,",
	" 0 ",
	"FROM postvoucher, vendor ,voucherdist ", 
	"WHERE postvoucher.cmpy_code = ? ",
	"AND postvoucher.post_flag != 'Y' ", 
	"AND postvoucher.year_num = ? ", 
	"AND postvoucher.period_num = ? ",
	"AND postvoucher.total_amt = postvoucher.dist_amt ", 
	"AND postvoucher.cmpy_code = vendor.cmpy_code ", 
	"AND postvoucher.vend_code = vendor.vend_code ", 
	"AND voucherdist.cmpy_code = postvoucher.cmpy_code ",
	"AND voucherdist.vouch_code = postvoucher.vouch_code ",
	"ORDER BY postvoucher.currency_code, ",
	" vendor.type_code, ",
	" postvoucher.vend_code ,",
	" postvoucher.vouch_code " 
	CALL crs_voucher_dist_ready.Declare(l_sql_statement)
	# end of query backup
	}

	--	DECLARE vd_curs CURSOR FOR 
	LET l_sql_statement = " SELECT acct_code,desc_text,dist_qty,analysis_text,dist_amt,0 ",
	" FROM voucherdist ",
	" WHERE cmpy_code = ? ",
	" AND vouch_code = ? ",
	" AND vend_code = ? "
	--CALL crs_voucherdist_scan.Declare(l_sql_statement)   # deprecated

	LET l_sql_statement = " INSERT INTO posttemp VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,0 )"
	CALL prp_insert_posttemp.Prepare(l_sql_statement)

	LET l_sql_statement = "SELECT cmpy_code,vouch_code FROM postvoucher WHERE cmpy_code = ? "
	CALL crs_postvoucher_scan_all.Declare(l_sql_statement)

	LET l_sql_statement = "UPDATE voucher ",
	" SET jour_num = ?, ",
	" post_date = ?, ",
	" post_flag = 'Y' ",
	" WHERE cmpy_code = ? ",
	" AND vouch_code =  ?"
	CALL prp_update_voucher_journum_postdate.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE jobledger ",
	" SET posted_flag = 'N' ", 
	" WHERE jobledger.cmpy_code =  ? ",
	" AND jobledger.posted_flag = 'P' ", 
	" AND jobledger.year_num = ? ",
	" AND jobledger.period_num = ? "
	CALL prp_update_jobledger.Prepare(l_sql_statement)

	LET l_sql_statement = "DELETE FROM postvoucher ",
	" WHERE cmpy_code = ? "
	CALL prp_delete_postvoucher_all.Prepare()

	LET l_sql_statement = "SELECT debit_num ",
	" FROM postdebithead ",
	" WHERE cmpy_code = ? ",
	" FOR UPDATE "
	CALL crs_upd_postdebithead_undo.Declare(l_sql_statement,1,0)		# cursor for update,not with
	# glob_rec_kandoouser.cmpy_code 

	# Cursors and prepares in function post_debithead
	LET l_sql_statement = "UPDATE debithead ",
	" SET post_flag = 'N' ", 
	" WHERE cmpy_code =  ? ",
	" AND debit_num =  ? "
	CALL prp_update_debithead_unflag.Prepare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code
	# modu_debit_num

	LET l_sql_statement = "DELETE FROM postdebithead ",
	" WHERE cmpy_code = ?", 
	" AND debit_num =  ? "
	CALL prp_delete_postdebithead.Prepare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code 
	# modu_debit_num

	LET l_sql_statement = "SELECT * ",
	" FROM debithead ",
	" WHERE debithead.cmpy_code =  ? ",
	" AND debithead.post_flag = 'N' ", 
	" AND debithead.total_amt = debithead.dist_amt ",
	" AND debithead.period_num =  ? ",
	" AND debithead.year_num =  ? "
	CALL crs_debithead_notflag_period.Declare(l_sql_statement,0,1)  # no for update, with hold
	# glob_rec_kandoouser.cmpy_code
	# glob_fisc_period
	# glob_fisc_year

	LET l_sql_statement = "INSERT INTO postdebithead VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
	CALL prp_insert_postdebithead.Prepare(l_sql_statement)
	
	LET l_sql_statement = "UPDATE debithead ",
	" SET post_flag = 'Y' ", 
	"WHERE cmpy_code = ? ",
	" AND debit_num = ? "
	CALL prp_update_debithead_flag.Prepare(l_sql_statement)

	LET l_sql_statement = "SELECT D.cmpy_code, ", 
	" D.debit_num, ", 
	" D.vend_code, ", 
	" D.debit_date, ", 
	" D.currency_code, ", 
	" D.conv_qty, ", 
	" V.type_code, ", 
	" D.disc_amt ", 
	"FROM postdebithead D, vendor V ", 
	"WHERE D.cmpy_code = ? ", 
	"AND D.post_flag != 'Y' ", 
	"AND D.year_num = ? ", 
	"AND D.period_num = ? ", 
	"AND D.total_amt = D.dist_amt ", 
	"AND D.cmpy_code = V.cmpy_code ", 
	"AND D.vend_code = V.vend_code "
	# End of common trunk for this query
	# Now prepare query for successful case
	LET l_sql_statement = l_sql_statement,
	" ORDER BY D.cmpy_code, D.vend_code, D.debit_num "
	CALL crs_join_posdebithead_vendor.Declare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code,
	# glob_fisc_year,
	# glob_fisc_period
	
	# Same cursor for failed statement we take the same base, but add conditions
	# in the function we choose which cursor to use by doing let l_crs_join_posdebithead_vendor = crs_join_posdebithead_vendor(ok or ko)
	LET l_sql_statement = l_sql_statement,
	"AND (D.jour_num = ? OR D.jour_num IS NULL D.jour_num = 0) ", 
	"ORDER BY D.cmpy_code, D.vend_code, D.debit_num " 
	CALL crs_join_posdebithead_vendor_ko.Declare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code,
	# glob_fisc_year,
	# glob_fisc_period,
	# glob_rec_poststatus.jour_num

	# function update_vendorhist
	LET l_sql_statement = "SELECT vend_code, COUNT(*), NVL(SUM(total_amt),0) ",
	" FROM postvoucher ",
	" WHERE cmpy_code = ? ",
	" AND post_flag != 'H' ",
	" AND total_amt = postvoucher.dist_amt ",
	" AND period_num = ? ",
	" AND year_num =  ? ",
	" GROUP BY vend_code "
	CALL crs_postvoucher_sums_vendor.Declare(l_sql_statement,0,1)		# not scroll, with hold

	LET l_sql_statement = "SELECT 1 ", 
	"FROM vendorhist ",
	" WHERE cmpy_code = ? ",
	" AND vend_code = ? ", 
	" AND period_num = ? ", 
	" AND year_num = ? "
	# " FOR UPDATE "
	CALL crs_upd_vendorhist.Declare(l_sql_statement)		# for update
	# glob_rec_kandoouser.cmpy_code
	# modu_doc_vendor_code
	# glob_fisc_period
	# glob_fisc_year
	
	LET l_sql_statement = "UPDATE vendorhist ",
	" SET purchase_num = purchase_num + ?, ", 
	" purchase_amt = purchase_amt + ? ",
	" WHERE cmpy_code = ? ",
	" AND vend_code = ? ", 
	" AND period_num = ? ", 
	" AND year_num = ? "
	CALL prp_update_vendorhist_purchase.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE postvoucher ",
	" SET post_flag = 'H' ", 
	" WHERE cmpy_code = ? ", 
	" AND vend_code =  ? "
	# glob_rec_kandoouser.cmpy_code
	# modu_doc_vendor_code
	CALL prp_update_postvoucher.Prepare(l_sql_statement)

	LET l_sql_statement = "SELECT vend_code, COUNT(*), SUM(total_amt), SUM(disc_amt)", 
	" FROM postdebithead ",
	" WHERE cmpy_code = ? ",
	" AND post_flag != 'H' ", 
	" AND total_amt = dist_amt ",
	" AND period_num = ? ",
	" AND year_num = ? ",
	" GROUP BY vend_code "
	CALL crs_postdebithead_period.Declare(l_sql_statement,0,1)	# not for update, with hold
	# glob_rec_kandoouser.cmpy_code 
	# glob_fisc_period 
	# glob_fisc_year 

	LET l_sql_statement = "UPDATE vendorhist ",
	" SET debit_num = debit_num + ? ,",
	" debit_amt = debit_amt + ? ,", 
	" disc_amt = disc_amt + ? ",
	" WHERE CURRENT OF crs_upd_vendorhist "
	CALL pr_update_vendorhist_debit.Prepare(l_sql_statement)
	# modu_counter, 
	# l_totaller,
	# l_disc_totaller 

	# function post_debithead
	LET l_sql_statement = "UPDATE postdebithead ",
	" SET post_flag = 'H' ", 
	" WHERE cmpy_code = ? ",
	" AND vend_code = ? "
	CALL prp_update_postdebithead.Prepare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code
	# modu_doc_vendor_code  

	LET l_sql_statement =  "SELECT acct_code, ",
	" desc_text, ",
	" dist_qty, ",
	" analysis_text, ",
	" 0, ",
	" dist_amt ",
	" FROM debitdist ",
	" WHERE cmpy_code = ? ",
	" AND debit_code = ? ",
	" AND vend_code = ? "
	CALL crs_debitdist_debitcode_vendcode.Declare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code 
	# modu_rec_docdata.ref_num 
	# modu_rec_docdata.ref_text 

	LET l_sql_statement = "SELECT * ",
	" FROM postdebithead ",
	" WHERE cmpy_code = ? "
	CALL crs_postdebithead_scan.Declare(l_sql_statement)
	# glob_rec_kandoouser.cmpy_code

	LET l_sql_statement = "UPDATE debithead ",
	" SET jour_num = ? ,",
	" post_date = ? ",
	" WHERE cmpy_code = ? ", 
	" AND debit_num = ? "
	CALL prp_update_debithead_journum.Prepare(l_sql_statement)
	# modu_rec_debithead.jour_num, 
	# today
	# modu_rec_debithead.cmpy_code
	# modu_rec_debithead.debit_num 

	
	# function create_gl_batches
	LET l_sql_statement = "SELECT unique posttemp.pay_acct_code, posttemp.currency_code ",
	" FROM posttemp "
	CALL crs_posttemp_uniq_acctcode_currency.Declare(l_sql_statement)

	LET l_sql_statement = "SELECT posttemp.ref_num, ", 
	" posttemp.ref_text, ", 
	" posttemp.doc_num ", 
	"FROM posttemp ", 
	" WHERE posttemp.pay_acct_code = ? ", 
	" AND posttemp.currency_code = ? "
 	CALL crs_posttemp_acctcode_currency.Declare(l_sql_statement)

	LET l_sql_statement = "UPDATE postvoucher ",
	" SET jour_num = ? ",
	" WHERE cmpy_code = ? ",
	" AND vouch_code = ?"
	CALL prp_update_postvoucher_journum.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE postdebithead ",
	" SET jour_num = ? ",
	" WHERE cmpy_code = ? ",
	" AND debit_num = ? "
	CALL prp_update_postdebithead_journum.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE postcheque ",
	" SET jour_num = ? ",
	" WHERE cmpy_code = ? ",
	" AND doc_num = ? "
	CALL prp_update_postcheque_journum.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE postexchvar ",
	" SET jour_num = ? ",
	" WHERE cmpy_code = ?",
	" AND ref1_num = ? ",
	" AND ref2_num = ? "
	CALL prp_update_postexchvar_journum.Prepare(l_sql_statement)

	LET l_sql_statement = "UPDATE postaptrans ",
	" SET jour_num = ? ",
	" WHERE cmpy_code = ? ",
	" AND doc_num = ? "
	CALL prp_update_postaptrans_journum.Prepare(l_sql_statement)

	# report rep_post_voucher
	LET l_sql_statement = "UPDATE batchhead ",
	" SET debit_amt = ? ,",
	" credit_amt = ? ,",
	" for_debit_amt = ? ,",
	" for_credit_amt = ? ",
	" WHERE cmpy_code = ? ",
	" AND jour_code = ? ",
	" AND jour_num = ? "
	CALL prp_update_batchhead.Prepare(l_sql_statement)

END FUNCTION #  PP1_init_cursors_and_prepares()


############################################################
# FUNCTION getBatchHead_DataSource(p_filter)
#
#
############################################################
FUNCTION get_period_datasource(p_filter) 
	DEFINE p_filter BOOLEAN 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_sel_text CHAR(2200) 
--	DEFINE l_where_text CHAR(2048) 
	DEFINE l_idx SMALLINT 
	DEFINE l_foundit SMALLINT 
	DEFINE l_posting_needed SMALLINT 
	DEFINE l_per_post SMALLINT 
	DEFINE r_arr_rec_period DYNAMIC ARRAY OF t_arr_rec_period 

		IF p_filter THEN 
			--CLEAR FORM 
			MESSAGE kandoomsg2("P",3524,"") # 3524 "Enter selection - ESC TO search"

			CONSTRUCT BY NAME modu_sel_text ON year_num, period_num 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","PP1","construct-period-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT
			IF int_flag OR quit_flag THEN 
				LET modu_sel_text = " 1=1 " 
			END IF 
		ELSE 
			LET modu_sel_text = " 1=1 " 
		END IF 

		LET l_sel_text = "SELECT unique year_num, ", 
		" period_num ", 
		"FROM period ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",modu_sel_text CLIPPED, " ",
		"ORDER BY year_num, period_num " 

		IF int_flag OR quit_flag THEN 
			RETURN false 
		END IF 

		PREPARE q_period FROM l_sel_text 
		DECLARE c_period CURSOR FOR q_period 

		LET l_idx = 0 

		FOREACH c_period INTO l_rec_period.year_num, l_rec_period.period_num 
			LET l_idx = l_idx + 1 
			LET r_arr_rec_period[l_idx].year_num = l_rec_period.year_num 
			LET r_arr_rec_period[l_idx].post_req = " " 
			LET r_arr_rec_period[l_idx].period_num = l_rec_period.period_num 
			-- IF l_idx > 299 THEN -- alch Do not limit number of displayed rows
			-- 	# 3525 " Only first 300 selected " ATTRIBUTE(yellow)
			-- 	LET l_msgresp = kandoomsg("P",3525,"")
			-- 	SLEEP 4
			-- 	EXIT FOREACH
			-- END IF
		END FOREACH 

		IF l_idx = 0 THEN # 3512 "You must SELECT a VALID year AND period"
			ERROR kandoomsg2("U",3512,"") 
			RETURN FALSE 
		END IF 

		RETURN r_arr_rec_period 
END FUNCTION   # get_period_datasource

#######################################################
# FUNCTION check_for_post_check_for_available_posts
# rewrote check_for_required_post smarter way
#######################################################

FUNCTION check_for_available_posts(p_arr_rec_period)
	DEFINE p_arr_rec_period DYNAMIC ARRAY OF t_arr_rec_period 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_sel_text STRING
	DEFINE l_sql_statement STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_foundit SMALLINT 
	DEFINE l_posting_needed SMALLINT 
	DEFINE l_per_post SMALLINT 

	# 1002 "Searching Database - please wait"
	MESSAGE kandoomsg2("P",1002,"") 

	LET l_idx = 1 
	--FOR l_idx = 1 TO p_arr_rec_period.getsize()--arr_count() 

	LET l_foundit = 0 
	--LET p_arr_rec_period[l_idx].post_req = "N" 
	# We better issue a big UNION query that fetches anything that needs to be posted
	# more exhaustive than fetch first vouchers then nested search for other tables .....
	LET l_sql_statement = "SELECT year_num,period_num, 'Vouchers',",
	" CASE WHEN approved_code = 'Y' THEN 'Approved' ELSE 'WaitForApproval' END, ",
	" CASE WHEN total_amt = dist_amt THEN 'Complete' ELSE 'UNCOMPLETE' END, ",
	" count(*), ",
	" CASE WHEN approved_code = 'Y' AND total_amt = dist_amt THEN 'T' ELSE 'F' END ",
	" FROM voucher ",
	" WHERE cmpy_code = ? ",
	CONS_BASE_WHERECLAUSE_VOUCHER_1,
	" GROUP BY 1,2,3,4,5,7 ",
	" UNION ",
	"SELECT year_num,period_num, 'Debits',",
	" 'Approved','Complete', ",
	" count(*), 'T' ",
	"FROM debithead ",
	" WHERE cmpy_code = ? ",
	CONS_BASE_WHERECLAUSE_DEBITHEAD,
	" GROUP BY 1,2,3,4,5,7 ",
	" UNION ",
	"SELECT year_num,period_num, 'Cheques', ",
	" 'Approved','Complete', ",
	" count(*), 'T' ",
	"FROM cheque ",
	" WHERE cmpy_code = ? ",
	CONS_BASE_WHERECLAUSE_CHEQUE,
	" GROUP BY 1,2,3,4,5,7 ",
	" UNION ",
	"SELECT year_num,period_num, 'ExchangeOps', ",
	" 'Approved','Complete', ",
	" count(*), 'T' ",
	"FROM exchangevar ",
	" WHERE cmpy_code = ? ",
	CONS_BASE_WHERECLAUSE_EXCHANGEVAR,
	" GROUP BY 1,2,3,4,5,7 "
	
	# We think postvoucher and postxxx tables should be empty because we use transactions
	CALL p_arr_rec_period.Clear()
	CALL crs_vouchers_status.Declare(l_sql_statement)
	CALL crs_vouchers_status.Open (glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.cmpy_code,glob_rec_kandoouser.cmpy_code)

	CALL crs_vouchers_status.FetchAll(p_arr_rec_period)
	
	RETURN p_arr_rec_period
END FUNCTION   # check_for_available_posts

# This function is deprecated replaced by check_for_available_posts
FUNCTION check_for_post_required_old(p_arr_rec_period)
	DEFINE p_arr_rec_period DYNAMIC ARRAY OF 
		RECORD 
			year_num LIKE period.year_num, 
			period_num LIKE period.period_num, 
			post_req CHAR(1) 
		END RECORD 

	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_sel_text STRING
--	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_foundit SMALLINT 
	DEFINE l_posting_needed SMALLINT 
	DEFINE l_per_post SMALLINT 

		# 1002 "Searching Database - please wait"
		MESSAGE kandoomsg2("P",1002,"") 

		LET l_idx = 1 
		FOR l_idx = 1 TO p_arr_rec_period.getsize()--arr_count() 

			LET l_foundit = 0 
			LET p_arr_rec_period[l_idx].post_req = "N" 
			DECLARE postvo CURSOR FOR 
				SELECT unique period_num 
				INTO l_per_post 
				FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND post_flag = "N" 
				AND period_num = p_arr_rec_period[l_idx].period_num 
				AND year_num = p_arr_rec_period[l_idx].year_num 

			FOREACH postvo 
				LET p_arr_rec_period[l_idx].post_req = "Y" 
				LET l_foundit = 1 
				EXIT FOREACH 
			END FOREACH 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOR 
			END IF 

			IF l_foundit = 0 THEN 
				DECLARE postdm CURSOR FOR 
					SELECT period_num 
					INTO l_per_post 
					FROM debithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND post_flag = "N" 
					AND total_amt > 0 
					AND period_num = p_arr_rec_period[l_idx].period_num 
					AND year_num = p_arr_rec_period[l_idx].year_num 

				FOREACH postdm 
					LET p_arr_rec_period[l_idx].post_req = "Y" 
					LET l_foundit = 1 
					EXIT FOREACH 
				END FOREACH
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOR 
			END IF 

			IF l_foundit = 0 THEN 
				DECLARE postck CURSOR FOR 
					SELECT period_num 
					INTO l_per_post 
					FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND post_flag = "N" 
					AND period_num = p_arr_rec_period[l_idx].period_num 
					AND year_num = p_arr_rec_period[l_idx].year_num 

				FOREACH postck 
					LET p_arr_rec_period[l_idx].post_req = "Y" 
					LET l_foundit = 1 
					EXIT FOREACH 
				END FOREACH 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOR 
			END IF 

			IF l_foundit = 0 THEN 
				DECLARE postex CURSOR FOR 
					SELECT period_num 
					INTO l_per_post 
					FROM exchangevar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND posted_flag = "N" 
					AND period_num = p_arr_rec_period[l_idx].period_num 
					AND year_num = p_arr_rec_period[l_idx].year_num 
					AND source_ind = "P" 

				FOREACH postex 
					LET p_arr_rec_period[l_idx].post_req = "Y" 
					LET l_foundit = 1 
					EXIT FOREACH 
				END FOREACH 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOR 
			END IF 

			IF l_foundit = 0 THEN 
				LET l_posting_needed = 0 
				SELECT count(*) 
				INTO l_posting_needed 
				FROM postvoucher 
				WHERE postvoucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND (postvoucher.period_num = p_arr_rec_period[l_idx].period_num 
				AND postvoucher.year_num = p_arr_rec_period[l_idx].year_num) 

				IF NOT l_posting_needed THEN 
					SELECT count(*) 
					INTO l_posting_needed 
					FROM postdebithead 
					WHERE postdebithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND (postdebithead.period_num = p_arr_rec_period[l_idx].period_num 
					AND postdebithead.year_num = p_arr_rec_period[l_idx].year_num) 
				END IF 

				IF NOT l_posting_needed THEN 
					SELECT count(*) 
					INTO l_posting_needed 
					FROM postcheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND (postcheque.period_num = p_arr_rec_period[l_idx].period_num 
					AND postcheque.year_num = p_arr_rec_period[l_idx].year_num) 
				END IF 

				IF NOT l_posting_needed THEN 
					SELECT count(*) 
					INTO l_posting_needed 
					FROM postexchvar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND (postexchvar.period_num = p_arr_rec_period[l_idx].period_num 
					AND postexchvar.year_num = p_arr_rec_period[l_idx].year_num) 
				END IF 

				IF l_posting_needed THEN 
					LET p_arr_rec_period[l_idx].post_req = "Y" 
				END IF 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				EXIT FOR 
			END IF 

		END FOR 
		-- LET j = 1
		-- FOR i = ( modu_idx - scrn + 1 ) TO ( ( modu_idx - scrn + 1 ) + 12 - 1 )
		--	FOR l_idx = 1 TO arr_count()
		--		DISPLAY p_arr_rec_period[l_idx].* TO sr_period[l_idx].*
		-- LET j = j + 1
		-- IF glob_arr_rec_period[i+1].year_num = 0 THEN
		-- 	EXIT FOR
		-- END IF
		--	END FOR

	RETURN p_arr_rec_period
END FUNCTION   # check_for_post_required_old
############################################################
# FUNCTION organize_posting_tasks()
#
#
############################################################
FUNCTION organize_posting_tasks() 
	DEFINE l_tmp_year LIKE poststatus.post_year_num 
	DEFINE l_tmp_period LIKE poststatus.post_period_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_tmp_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_operation_status INTEGER
	DEFINE l_arr_rec_period DYNAMIC ARRAY OF t_arr_rec_period 

	CALL l_arr_rec_period.clear()
	--CALL get_period_datasource(false) RETURNING l_arr_rec_period 
	CALL check_for_available_posts(l_arr_rec_period) RETURNING l_arr_rec_period
		

	# 3526 "Press RETURN on line TO post, F10 TO check "
	MESSAGE kandoomsg("U",3526,"") 

	DISPLAY ARRAY l_arr_rec_period TO sr_period.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","PP1","inp-period-1") -- alch UPDATE publish toolbar later 
			CALL dialog.setActionHidden("ACCEPT",TRUE) #hide accept/apply 
			CALL dialog.setActionHidden("INSERT",TRUE) #hide accept/apply
			CALL dialog.setActionHidden("DELETE",TRUE) #hide accept/apply
			CALL dialog.setActionHidden("APPEND",TRUE) #hide accept/apply

			MESSAGE kandoomsg("U",3526,"") # 3526 "Press RETURN on line TO post, F10 TO check " 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			IF l_arr_rec_period[l_idx].post_req = true THEN   # If this line is marked for posting, we can see "Post", else we can't
				CALL dialog.setActionHidden("POST THIS LINE",false)
			ELSE
				CALL dialog.setActionHidden("POST THIS LINE",true)
			END IF

		ON ACTION "FILTER" 
			CALL l_arr_rec_period.clear() -- alch remove AFTER lyc-4793 fix 
			CALL get_period_datasource(true) RETURNING l_arr_rec_period 
			CALL check_for_available_posts(l_arr_rec_period) RETURNING l_arr_rec_period

		ON ACTION ("POST THIS PERIOD","ACCEPT","DOUBLECLICK")
			LET l_idx = arr_curr()
			LET glob_fisc_period = l_arr_rec_period[l_idx].period_num 
			LET glob_fisc_year = l_arr_rec_period[l_idx].year_num 

			IF modu_post_status < 99 THEN 
				SELECT post_year_num,post_period_num INTO l_tmp_year,l_tmp_period 
				FROM poststatus 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AP" 

				IF sqlca.sqlcode = 0 AND (l_tmp_year != glob_fisc_year OR l_tmp_period != glob_fisc_period) THEN 
					LET l_tmp_text = l_tmp_year USING "####"," ", l_tmp_period USING "###" 
					ERROR kandoomsg2("U",3516,l_tmp_text) # 3516 "You must post ",l_tmp_year," ",l_tmp_period 
					CALL fgl_winmessage("You are trying to post vouchers from a period that does not match current period","You must post "|l_tmp_year|" "|l_tmp_period|"\nExit Application","error")
					--SLEEP 2 
					EXIT DISPLAY 
				END IF 
			END IF 

			IF l_arr_rec_period[l_idx].post_req = TRUE THEN
				CALL PP1_post_AP(l_arr_rec_period[l_idx].ap_object,l_arr_rec_period[l_idx].period_num,l_arr_rec_period[l_idx].year_num) 
				RETURNING l_operation_status
				IF l_operation_status <> 0 THEN
					ERROR "This went bad"
				END IF
			ELSE
				ERROR "This line is not ready to be posted, please choose another line"
			END IF

			##  Set the Running Flag off.. but ONLY once posting ends.......
			UPDATE poststatus 
				SET post_running_flag = "N" ,
				post_period_num = NULL,			# 20210126 added by ericv until we understand if we maintain the 'current period' in this table or not
				post_year_num = NULL
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND module_code = "AP" 

			IF modu_all_ok = 0 THEN 
				ERROR kandoomsg2("U",3527,"") # 3527 " SUSPENSE ACCOUNTS USED - press <RETURN>" FOR CHAR glob_doit 
			ELSE 
				MESSAGE kandoomsg2("U",3528,"") # 3528 " Posting complete - PRESS <RETURN>" FOR CHAR glob_doit 
			END IF 

			MESSAGE kandoomsg2("U",3526,"") # 3526 "Press RETURN on line TO post, F10 TO check " 

	END DISPLAY 

--		OPTIONS INSERT KEY f1 
--		OPTIONS DELETE KEY f2 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	END IF 

	RETURN true 
END FUNCTION   # organize_posting_tasks


############################################################
# FUNCTION FUNCTION get_vendortype_accounts()
#
#
############################################################
FUNCTION get_vendortype_accounts(p_vend_type) 
	DEFINE p_vend_type LIKE vendortype.type_code
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendtype_accounts RECORD
		pay_acct_code LIKE vendortype.pay_acct_code,
		disc_acct_code LIKE vendortype.disc_acct_code,
		exch_acct_code LIKE vendortype.exch_acct_code,
		tax_vend_code LIKE vendortype.tax_vend_code
	END RECORD

	# Payables control, discount AND exchange variance posting accounts
	# determined by vendor type. Default TO AP parameters IF NULL
	# Associated Tax Vendor FOR withholding tax also determined by
	# vendortype

	SELECT pay_acct_code, 
	disc_acct_code, 
	exch_acct_code, 
	tax_vend_code 
	INTO l_rec_vendtype_accounts.*
	FROM vendortype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_vend_type

	IF sqlca.sqlcode = NOTFOUND THEN 
		INITIALIZE l_rec_vendtype_accounts.* TO NULL
	END IF 

	IF l_rec_vendtype_accounts.pay_acct_code IS NULL THEN 
		LET l_rec_vendtype_accounts.pay_acct_code = glob_rec_apparms.pay_acct_code 
	END IF 

	IF l_rec_vendtype_accounts.disc_acct_code IS NULL THEN 
		LET l_rec_vendtype_accounts.disc_acct_code = glob_rec_apparms.disc_acct_code 
	END IF 

	IF l_rec_vendtype_accounts.exch_acct_code IS NULL THEN 
		LET l_rec_vendtype_accounts.exch_acct_code = glob_rec_apparms.exch_acct_code 
	END IF 

	LET modu_prev_vend_type = p_vend_type		# FIXME: hmmmm 
	RETURN l_rec_vendtype_accounts.*

END FUNCTION  # get_vendortype_accounts




############################################################
# FUNCTION create_gl_batches()
#
#
############################################################
FUNCTION create_gl_batches() 
	DEFINE l_rec_data RECORD 
		tran_type_ind LIKE batchdetl.tran_type_ind, 
		ref_num LIKE batchdetl.ref_num, 
		ref_text LIKE batchdetl.ref_text, 
		acct_code LIKE batchdetl.acct_code, 
		desc_text LIKE batchdetl.desc_text, 
		for_debit_amt LIKE batchdetl.for_debit_amt, 
		for_credit_amt LIKE batchdetl.for_credit_amt, 
		base_debit_amt LIKE batchdetl.debit_amt, 
		base_credit_amt LIKE batchdetl.credit_amt, 
		currency_code LIKE currency.currency_code, 
		conv_qty LIKE rate_exchange.conv_buy_qty, 
		tran_date DATE, 
		stats_qty LIKE batchdetl.stats_qty, 
		analysis_text LIKE batchdetl.analysis_text 
	END RECORD 
	DEFINE l_posted_some SMALLINT 
	DEFINE l_doc_num INTEGER 
	DEFINE l_upd_sel_text STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_sel_stmt STRING 

	# FIXME: See impact of putting vend_code + vendor invoice # in batchdetl.ref_text 
	# TODO: propose option for AP Balance for the whole batch OR invoice per invoice ...
--	GOTO bypass 
--	LABEL recovery: 

--	CALL update_poststatus(NOT_OK,STATUS,"AP") 
--	LABEL bypass: 
--	WHENEVER ERROR GOTO recovery 


	# batch posting details according TO payables control account AND
	# currency code (ie. all entries FOR the same control/balancing
	# account AND currency in one batch)

	#DISPLAY "" AT 1,1

	CALL crs_posttemp_uniq_acctcode_currency.Open()
	LET l_posted_some = false 

	WHILE crs_posttemp_uniq_acctcode_currency.FetchNext(modu_rec_current.bal_acct_code, modu_rec_current.currency_code ) = 0

		LET l_posted_some = true 
		LET modu_rec_bal_rec.acct_code = modu_rec_current.bal_acct_code 

		# This query must be kept as is because statement text is passed to a called function
		LET l_sel_stmt = " SELECT ", " '", modu_rec_current.tran_type_ind clipped, "', ", 
		" posttemp.ref_num, ", 
		" posttemp.ref_text, ", 
		" posttemp.post_acct_code, ", 
		" posttemp.desc_text, ", 
		" posttemp.debit_amt, ", 
		" posttemp.credit_amt, ", 
		" posttemp.base_debit_amt, ", 
		" posttemp.base_credit_amt, ", 
		" posttemp.currency_code, ", 
		" posttemp.conv_qty, ", 
		" posttemp.tran_date, ", 
		" posttemp.stats_qty, ", 
		" posttemp.analysis_text ", 
		" FROM posttemp ", 
		" WHERE posttemp.pay_acct_code = '", modu_rec_bal_rec.acct_code clipped, "' ", 
		" AND posttemp.currency_code = '", modu_rec_current.currency_code clipped, "' ",
		" ORDER BY posttemp.ref_num "    # order by invoice number

		--LET glob_err_text = "CALL TO jourintf" 
		LET glob_err_text = "CALL TO jourintf2" 
{
		LET modu_rec_current.jour_num = jourintf(l_sel_stmt, 
		glob_rec_kandoouser.cmpy_code, 
		modu_sl_id, 
		modu_rec_bal_rec.*, 
		glob_fisc_period, 
		glob_fisc_year, 
		modu_rec_current.jour_code, 
		"P", 
		modu_rec_current.currency_code, 
		modu_rpt_output, 
		"AP") 
}
		LET modu_rec_current.jour_num = 
		jourintf2(modu_rpt_idx,l_sel_stmt,modu_rec_bal_rec.*,glob_fisc_period,glob_fisc_year,modu_rec_current.jour_code, "P", modu_rec_current.currency_code, "AP") 

		IF modu_rec_current.jour_num = 0 THEN {nothing posted} 
			ERROR kandoomsg2("U",3500,modu_rec_current.tran_type_ind) 
			# 3500 "No entries FOR type x posted."
			SLEEP 1 
		END IF 
 
		CALL crs_posttemp_acctcode_currency.Open(modu_rec_bal_rec.acct_code,modu_rec_current.currency_code)

		CASE modu_rec_current.tran_type_ind 
			WHEN "VO" {voucher} 
				WHILE crs_posttemp_acctcode_currency.FetchNext(l_rec_data.ref_num,l_rec_data.ref_text,l_doc_num ) = 0
					CALL prp_update_postvoucher_journum.Execute(glob_posted_journal,glob_rec_kandoouser.cmpy_code,l_rec_data.ref_num) 
				END WHILE # crs_posttemp_acctcode_currency
			WHEN "DM" {debits} 
				WHILE crs_posttemp_acctcode_currency.FetchNext(l_rec_data.ref_num,l_rec_data.ref_text,l_doc_num ) = 0
					CALL prp_update_postdebithead_journum.Execute(glob_posted_journal,glob_rec_kandoouser.cmpy_code,l_rec_data.ref_num) 
				END WHILE # crs_posttemp_acctcode_currency
			WHEN "CH" {cheques} 
				WHILE crs_posttemp_acctcode_currency.FetchNext(l_rec_data.ref_num,l_rec_data.ref_text,l_doc_num ) = 0
					CALL prp_update_postcheque_journum.Execute(glob_posted_journal,glob_rec_kandoouser.cmpy_code,l_rec_data.ref_num) 
				END WHILE # crs_posttemp_acctcode_currency
			WHEN "EXP" {exchange variation} 
				WHILE crs_posttemp_acctcode_currency.FetchNext(l_rec_data.ref_num,l_rec_data.ref_text,l_doc_num ) = 0
					CALL prp_update_postexchvar_journum.Execute(glob_posted_journal,glob_rec_kandoouser.cmpy_code,l_rec_data.ref_num)
				END WHILE # crs_posttemp_acctcode_currency
			WHEN "CCO" {cheque contra amounts} 
				WHILE crs_posttemp_acctcode_currency.FetchNext(l_rec_data.ref_num,l_rec_data.ref_text,l_doc_num ) = 0
					CALL prp_update_postaptrans_journum.Execute(glob_posted_journal,glob_rec_kandoouser.cmpy_code,l_rec_data.ref_num)
				END WHILE # crs_posttemp_acctcode_currency
		END CASE 

		IF glob_posted_journal IS NOT NULL THEN 
			LET glob_posted_journal = NULL 
		END IF 

		# check FOR -ve journal number - indicates an error in posting account
		# within the GL batch

		IF modu_rec_current.jour_num < 0 THEN 
			LET modu_all_ok = 0 
		END IF 

		# DISPLAY GL batches as created


		# Vouchers, Cheques AND Debits need TO be flagged as posted AND
		# updated with the GL batch (journal) code. Cheques are NOT flagged
		# until payments are posted.  Note that any change in the WHERE clause
		# FOR the SELECT statement passed TO jourintf needs TO be added TO
		# the SELECT FROM posttemp in FUNCTION flag_it TO ensure that the
		# same rows are selected FOR UPDATE as were included in the batch.

	END WHILE # crs_posttemp_uniq_acctcode_currency 

	IF NOT l_posted_some THEN 
		# 3501 " No rows found TO post"
		ERROR kandoomsg2("U",3501,"") 
		--SLEEP 1 
	END IF 

END FUNCTION   # create_gl_batches


############################################################
# FUNCTION init_vendorhist()
#
#
############################################################
FUNCTION init_vendorhist() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message STRING 

	GOTO bypass 
	LABEL recovery: 

	CALL update_poststatus(NOT_OK,STATUS,"AP") 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	INITIALIZE modu_rec_vendorhist.* TO NULL 
	SELECT * INTO modu_rec_vendorhist.* 
	FROM vendorhist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vendorhist.vend_code = modu_doc_vendor_code 
		AND period_num = glob_fisc_period 
		AND year_num = glob_fisc_year 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET modu_rec_vendorhist.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET modu_rec_vendorhist.vend_code = modu_doc_vendor_code 
		LET modu_rec_vendorhist.year_num = glob_fisc_year 
		LET modu_rec_vendorhist.period_num = glob_fisc_period 
		LET modu_rec_vendorhist.purchase_num = 0 
		LET modu_rec_vendorhist.purchase_amt = 0 
		LET modu_rec_vendorhist.purchase_loc_amt = 0 
		LET modu_rec_vendorhist.payment_num = 0 
		LET modu_rec_vendorhist.payment_amt = 0 
		LET modu_rec_vendorhist.payment_loc_amt = 0 
		LET modu_rec_vendorhist.debit_num = 0 
		LET modu_rec_vendorhist.debit_amt = 0 
		LET modu_rec_vendorhist.debit_loc_amt = 0 
		LET modu_rec_vendorhist.disc_amt = 0 
		LET l_err_message = " Vendor History INSERT " 
		MESSAGE l_err_message 
		INSERT INTO vendorhist VALUES (modu_rec_vendorhist.*) 
	END IF 
END FUNCTION   # init_vendorhist


############################################################
# FUNCTION update_vendorhist(p_type)
#
#
############################################################
FUNCTION update_vendorhist(p_type) 
	DEFINE p_type CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_disc_totaller DECIMAL(16,2) 
	DEFINE l_totaller DECIMAL(16,2) 

	GOTO bypass 
	LABEL recovery: 

	CALL update_poststatus(NOT_OK,STATUS,"AP") 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	CASE p_type 
		WHEN "V" {vouchers} 
			# UPDATE the purchase history

			LET glob_err_text = "Vendor history UPDATE - voucher" 
			CALL crs_postvoucher_sums_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year)
			--SET LOCK MODE TO WAIT 5 # attempt during 5 seconds to lock the record, else rollback
			WHILE crs_postvoucher_sums_vendor.FetchNext(modu_doc_vendor_code, modu_counter, l_totaller ) = 0
				CALL init_vendorhist() 
				CALL crs_upd_vendorhist.Open(glob_rec_kandoouser.cmpy_code,modu_doc_vendor_code,glob_fisc_period,glob_fisc_year)
				--SET LOCK MODE TO WAIT 5 # attempt during 5 seconds to lock the record, else rollback
				# We display a locking message so that user is aware the row is locked
				# as soon as row available we display NULL
				ERROR "Trying to lock vendorhist record for maximum 5 seconds"
				CALL crs_upd_vendorhist.FetchNext()
				IF sqlca.sqlcode < 0 THEN
					CALL update_poststatus(NOT_OK,sqlca.sqlcode,"AP") 
					ROLLBACK WORK
				ELSE
					ERROR ""
					--SET LOCK MODE TO NOT WAIT
				END IF
				
				--WHENEVER ERROR GOTO recovery 

				CALL prp_update_vendorhist_purchase.Execute(modu_counter,l_totaller,glob_rec_kandoouser.cmpy_code,modu_doc_vendor_code,glob_fisc_period,glob_fisc_year)
				CALL prp_update_postvoucher.Execute(glob_rec_kandoouser.cmpy_code,modu_doc_vendor_code) 
			END WHILE # crs_postvoucher_sums_vendor
			SET LOCK MODE TO NOT WAIT

		WHEN "D" {debits} 
			# UPDATE the debit history
			LET glob_err_text = "Vendor history UPDATE - debit" 

			CALL crs_postdebithead_period.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year) 

			WHILE crs_postdebithead_period.FetchNext(modu_doc_vendor_code, modu_counter, l_totaller, l_disc_totaller) = 0 
			--FOREACH crs_postdebithead_period INTO modu_doc_vendor_code, modu_counter, l_totaller, l_disc_totaller 
				CALL init_vendorhist() 
				CALL crs_upd_vendorhist.Open(glob_rec_kandoouser.cmpy_code,modu_doc_vendor_code,glob_fisc_period,glob_fisc_year)
				--SET LOCK MODE TO WAIT 5
				# We display a locking message so that user is aware the row is locked
				# as soon as row available we display NULL
				ERROR "Trying to lock vendorhist record for maximum 5 seconds"
				CALL crs_upd_vendorhist.FetchNext()
				IF sqlca.sqlcode < 0 THEN
					CALL update_poststatus(NOT_OK,sqlca.sqlcode,"AP") 
					ROLLBACK WORK
				ELSE
					ERROR ""
					SET LOCK MODE TO NOT WAIT
				END IF

				LET glob_err_text = " Vendor History UPDATE - debits " 
				WHENEVER ERROR CONTINUE 
				CALL pr_update_vendorhist_debit.Execute(modu_counter,l_totaller,l_disc_totaller)
				CALL prp_update_postdebithead.Execute(glob_rec_kandoouser.cmpy_code,modu_doc_vendor_code)
			END WHILE # crs_postdebithead_period

		WHEN "C" {cheques} 
			# UPDATE the payment history
			LET glob_err_text = "Vendor history UPDATE - cheque"
			DECLARE cheq1_curs CURSOR with HOLD FOR 
			SELECT vend_code, COUNT(*), SUM(pay_amt), SUM(disc_amt)  
			FROM postcheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND post_flag != "H" 
				AND pay_amt = postcheque.apply_amt 
				AND period_num = glob_fisc_period 
				AND year_num = glob_fisc_year 
			GROUP BY vend_code 

			FOREACH cheq1_curs INTO modu_doc_vendor_code, modu_counter, l_totaller, l_disc_totaller 
				CALL init_vendorhist() 
				DECLARE vhist2_upd CURSOR FOR 
				SELECT * 
				FROM vendorhist 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = modu_doc_vendor_code 
				AND period_num = glob_fisc_period 
				AND year_num = glob_fisc_year 
				FOR UPDATE 
				OPEN vhist2_upd 
				FETCH vhist2_upd INTO modu_rec_vendorhist.* 
				CALL update_poststatus(NOT_OK,modu_stat_code,"AP") 

				UPDATE vendorhist 
				SET payment_num = vendorhist.payment_num + modu_counter, 
				payment_amt = vendorhist.payment_amt + l_totaller, 
				disc_amt = vendorhist.disc_amt + l_disc_totaller 
				WHERE CURRENT OF vhist2_upd 

				UPDATE postcheque SET post_flag = "H" 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = modu_doc_vendor_code 
			END FOREACH # cheq1_curs
	END CASE 

END FUNCTION   # update_vendorhist

############################################################
# FUNCTION update_vendorhist(p_type)
#
# ??? someone dreaming ???? who wrote/did this ? -> had TO rename this FUNCTION because the name "voucher" was causing a
# conflict using Querix with database table "vaucher", WHEN using
# tablename.columnname notation
############################################################

FUNCTION post_vouchers(p_period_num,p_year_num) 
	DEFINE p_period_num LIKE voucher.period_num
	DEFINE p_year_num LIKE voucher.year_num
	DEFINE l_sql_statement STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_account_type LIKE coa.type_ind
	DEFINE l_idx SMALLINT

	# Sorry, but this function is called with "always had an error" status and stops the program
	# I think poststatus will not be necessary or at least less intensively used as we use transactions
	# Base rule: a post is always good and complete, or must be done from scratch, no in between status .... 

	LET glob_err_text = "Commenced voucher post" 

	LET glob_st_code = 1 
	LET glob_post_text = "Commenced INSERT TO postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	IF crs_voucher_dist_ready.GetStatement() IS NULL THEN
		LET l_sql_statement = "SELECT voucher.cmpy_code, ", 
		" voucher.vouch_code, ", 
		" voucher.vend_code, ", 
		" voucher.vouch_date, ", 
		" voucher.currency_code, ", 
		" voucher.conv_qty, ", 
		" vendor.type_code, ",
		" voucherdist.acct_code,",
		" voucherdist.desc_text,",
		" voucherdist.dist_qty,",
		" voucherdist.analysis_text,",
		" voucherdist.dist_amt,",
		" 0, ",
		" coa.type_ind ",
		"FROM voucher, ",
		" vendor ,",
		" voucherdist ,",
		" coa ", 
		"WHERE voucher.cmpy_code = ? ",
		"AND voucher.post_flag != 'Y' ", 
		"AND voucher.year_num = ? ", 
		"AND voucher.period_num = ? ",
		CONS_BASE_WHERECLAUSE_VOUCHER_1,
		CONS_BASE_WHERECLAUSE_VOUCHER_2,
		"AND voucher.total_amt = voucher.dist_amt ", 
		"AND voucher.cmpy_code = vendor.cmpy_code ", 
		"AND voucher.vend_code = vendor.vend_code ", 
		"AND voucherdist.cmpy_code = voucher.cmpy_code ",
		"AND voucherdist.vouch_code = voucher.vouch_code ",
		"AND voucherdist.cmpy_code = coa.cmpy_code ",
		"AND voucherdist.acct_code = coa.acct_code ",
		"ORDER BY voucher.currency_code, ",
		" vendor.type_code, ",
		" voucher.vend_code ,",
		" voucher.vouch_code " 
		CALL crs_voucher_dist_ready.Declare(l_sql_statement)		# main cursor to post vouchers, contains almost all the data including dis


		LET l_sql_statement = "INSERT INTO postvoucher VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
		CALL prp_insert_postvoucher.Prepare(l_sql_statement)

		LET l_sql_statement = "	UPDATE voucher ",
		" SET post_flag = 'Y' ", 
		" WHERE cmpy_code = ? ",
		" AND vend_code = ? ",
		" AND vouch_code = ? "
		CALL prp_update_voucher_posted.Prepare(l_sql_statement)


		LET l_sql_statement = "SELECT * ",
		" FROM voucher ",
		" WHERE cmpy_code = ? ",
		CONS_BASE_WHERECLAUSE_VOUCHER_1,
		CONS_BASE_WHERECLAUSE_VOUCHER_2,
		" AND voucher.period_num = ? ",
		" AND voucher.year_num = ? ",
		" ORDER BY 1,2 "
	END IF
	LET glob_err_text = "Create gl batch - voucher" 
	LET glob_st_code = 2 
	LET glob_post_text = "Completed INSERT TO postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET modu_prev_vend_type = "z" 
	LET modu_rec_current.tran_type_ind = "VO" 
	LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 
	LET modu_rec_current.base_credit_amt = 0 

	# Scan the big cursor of ready vouchers, including distribution details
	CALL crs_voucher_dist_ready.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_year,glob_fisc_period) 

	LET glob_err_text = "FOREACH INTO posttemp - voucher"
	LET modu_rec_bal_rec.tran_type_ind = "VO" 

	START REPORT rep_post_voucher_batch 
	WHILE crs_voucher_dist_ready.FetchNext(l_cmpy_code,modu_rec_docdata.*,modu_rec_current.vend_type,modu_rec_vouchedist_detldata.*,l_account_type) = 0
		#IF use_currency_flag IS 'N' THEN any source documents in foreign
		#currency need TO be converted TO base, AND a base batch created.
		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET modu_rec_vouchedist_detldata.debit_amt = modu_rec_current.base_debit_amt 
			LET modu_sv_conv_qty = 1 
			LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
		ELSE 
			LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
		END IF 

		IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
			IF modu_rec_docdata.conv_qty != 0 THEN 
				LET modu_rec_current.base_debit_amt = modu_rec_vouchedist_detldata.debit_amt / modu_rec_docdata.conv_qty 
			END IF 
		END IF 

		# create posting details FOR each distribution FOR
		# the selected vouchers
		# sending data to the report that will do all calculations,inserts etc
		OUTPUT TO REPORT rep_post_voucher_batch(modu_rec_docdata.*,modu_rec_current.*,modu_rec_vouchedist_detldata.*,l_account_type)  # do calculations and insert into tables
--		OUTPUT TO REPORT COM_jourintf_rpt_list_bd(p_rpt_idx,l_rec_batchdetl.*,	l_rec_company.*)  

	END WHILE  # crs_voucher_dist_ready
	FINISH REPORT rep_post_voucher_batch
	IF sqlca.sqlcode < 0 THEN		# While can fail if rows are locked by other session
		ERROR "Those vouchers are being posted by another session"
		RETURN 1
	END IF
	--FOR l_idx = 1 TO  mod_arr_rec_reports_to_print.getsize()
		--CALL run_report_COM_jourintf_rpt_list_bd(modu_rpt_idx,mod_arr_rec_reports_to_print[l_idx].jour_code,mod_arr_rec_reports_to_print[l_idx].jour_num)
	--END FOR
	LET modu_rec_bal_rec.desc_text = "AP Voucher Balancing Entry" 

	IF modu_post_status = 2 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	--MESSAGE "" 
	# 3502 " Posting vouchers..."
	MESSAGE kandoomsg2("P",3502,"") 
	--SLEEP 1 

--	CALL create_gl_batches()  # replaced by the report

	LET glob_st_code = 3 
	LET glob_post_text = "Commenced UPDATE jour_num FROM postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	{
	IF modu_post_status != 4 THEN 
		# UPDATE vendor history FOR cheques
		CALL update_vendorhist("V") 
		
	# IF the UPDATE does crap out part way this IS NOT a problem
	# we will re UPDATE next time through
	# 20210127 ericv : NICE JOB!!!
		LET glob_err_text = "Update jour_code in postvoucher" 
		CALL crs_postvoucher_scan_all.Open(glob_rec_kandoouser.cmpy_code)
		
		WHILE crs_postvoucher_scan_all.FetchNext(l_rec_voucher.cmpy_code,l_rec_voucher.vouch_code) = 0
			CALL prp_update_voucher_journum_postdate.Execute(l_rec_voucher.jour_num,today,l_rec_voucher.cmpy_code,l_rec_voucher.vouch_code)
		--END IF
		END WHILE #  crs_postvoucher_scan_all
	END IF 

	LET glob_st_code = 4 
	LET glob_post_text = "Commenced DELETE FROM postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postvoucher" 

	CALL prp_delete_postvoucher_all.Execute(glob_rec_kandoouser.cmpy_code)
	}
	LET glob_st_code = 99 
	LET glob_post_text = "Voucher Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	RETURN 0,mod_arr_rec_reports_to_print[1].jour_num		# All OK

END FUNCTION #  post_vouchers() 

{
#FUNCTION post_vouchers_old (p_period_num,p_year_num) 
	DEFINE p_period_num LIKE voucher.period_num
	DEFINE p_year_num LIKE voucher.year_num
	DEFINE l_sql_statement STRING
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 

	--GOTO bypass 
	--LABEL recovery: 

	-- CALL update_poststatus(NOT_OK,STATUS,"AP") 
	# Sorry, but this function is called with "always had an error" status and stops the program
	# I think poststatus will not be necessary or at least less intensively used as we use transactions
	# Base rule: a post is always good and complete, or must be done from scratch, no in between status .... 

	--LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 

	# IF an error has occurred AND it was NOT in this part of the
	# post THEN walk on by ...

	-- WHENEVER SQLERROR CALL kandoo_handle_post_errors
	IF modu_post_status > 4 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced voucher post" 

	LET glob_st_code = 1 
	LET glob_post_text = "Commenced INSERT TO postvoucher" 

	CALL update_poststatus(ALL_OK,0,"AP") 

	--IF modu_post_status = 1 OR modu_post_status = 99 THEN 
		# SELECT the vouchers FOR posting AND INSERT them INTO the postvoucher
		# table THEN UPDATE them as posted so they won't be touched by anyone
		# ELSE

	LET l_sql_statement = "SELECT * ",
	" FROM voucher ",
	" WHERE cmpy_code = ? ",
	CONS_BASE_WHERECLAUSE_VOUCHER_1,
	CONS_BASE_WHERECLAUSE_VOUCHER_2,
	" AND voucher.period_num = ? ",
	" AND voucher.year_num = ? ",
	" ORDER BY 1,2 "
	CALL crs_vouchers_to_post.Declare(l_sql_statement)
	CALL crs_vouchers_to_post.Open(glob_rec_kandoouser.cmpy_code,p_period_num,p_year_num)

	LET glob_err_text = "Voucher FOREACH FOR INSERT" 
	WHILE crs_vouchers_to_post.FetchNext(l_rec_voucher.* ) = 0		
		CALL update_poststatus(ALL_OK,modu_stat_code,"AP") 

		LET glob_err_text = "PP1 - Insert INTO postvoucher" 
		CALL prp_insert_postvoucher.Execute(l_rec_voucher.*)

		LET glob_err_text = "PP1 - Voucher post flag SET" 
		# set this voucher as posted
		CALL prp_update_voucher_posted.Execute(glob_rec_kandoouser.cmpy_code,l_rec_voucher.vend_code,l_rec_voucher.vouch_code)

		IF getModuleState("J11") = true THEN    # i.e if the Job Management Module is enabled
			LET glob_err_text = "PP1 - Jobledger post flag SET " 
			CALL prp_update_jobledger.Execute(glob_rec_kandoouser.cmpy_code,p_year_num,p_period_num)
		END IF
	END WHILE   # crs_vouchers_to_post.FetchNext

	LET glob_err_text = "Create gl batch - voucher" 
	LET glob_st_code = 2 
	LET glob_post_text = "Completed INSERT TO postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET modu_prev_vend_type = "z" 
	LET modu_rec_current.tran_type_ind = "VO" 
	LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 
	LET modu_rec_current.base_credit_amt = 0 

	CALL crs_postvoucher_ready.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_year,glob_fisc_period)

	LET glob_err_text = "FOREACH INTO posttemp - voucher"
	
	WHILE crs_postvoucher_ready.FetchNext(l_cmpy_code,modu_rec_docdata.*,modu_rec_current.vend_type) = 0

		# determine the posting control accounts FOR this vendor type,
		# IF new vendor

		IF modu_rec_current.vend_type != modu_prev_vend_type OR 
		(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT NULL ) OR 
		(modu_rec_current.vend_type IS NOT NULL AND 
		modu_prev_vend_type IS NULL ) THEN 
			CALL get_vendortype_accounts(modu_rec_current.vend_type) 
			RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
		END IF 

		# create posting details FOR each distribution FOR
		# the selected vouchers

		CALL crs_voucherdist_scan.Open(glob_rec_kandoouser.cmpy_code,modu_rec_docdata.ref_num,modu_rec_docdata.ref_text)
		WHILE crs_voucherdist_scan.FetchNext(modu_rec_vouchedist_detldata.* ) = 0
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_debit_amt = modu_rec_vouchedist_detldata.debit_amt / modu_rec_docdata.conv_qty 
				END IF 
			END IF 

			#IF use_currency_flag IS 'N' THEN any source documents in foreign
			#currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_vouchedist_detldata.debit_amt = modu_rec_current.base_debit_amt 
				LET modu_sv_conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 

			CALL prp_insert_posttemp.Execute(
				modu_rec_docdata.ref_num, # voucher number 
				modu_rec_docdata.ref_text, # vendor code 
				modu_rec_vouchedist_detldata.post_acct_code, # voucher dist account 
				modu_rec_vouchedist_detldata.desc_text, # voucher dist desc 
				modu_rec_vouchedist_detldata.debit_amt, # voucher dist amount 
				modu_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
				modu_rec_current.base_debit_amt, # converted debit amount 
				modu_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
				modu_rec_docdata.currency_code, # voucher currency code 
				modu_sv_conv_qty, # voucher curr conversion 
				modu_rec_docdata.tran_date, # voucher DATE 
				modu_rec_vouchedist_detldata.stats_qty, # distribution qty 
				modu_rec_vouchedist_detldata.analysis_text, # analysis text 
				modu_rec_current.pay_acct_code # control account 
			) 
		END WHILE  # crs_voucherdist_scan.FetchNext
	END WHILE  # crs_postvoucher_ready

	LET modu_rec_bal_rec.tran_type_ind = "VO" 
	LET modu_rec_bal_rec.desc_text = "AP Voucher Balancing Entry" 

	IF modu_post_status = 2 THEN 
		LET glob_posted_journal = glob_rec_poststatus.jour_num 
	ELSE 
		LET glob_posted_journal = NULL 
	END IF 

	--MESSAGE "" 
	# 3502 " Posting vouchers..."
	MESSAGE kandoomsg2("P",3502,"") 
	--SLEEP 1 

	CALL create_gl_batches() 

	LET glob_st_code = 3 
	LET glob_post_text = "Commenced UPDATE jour_num FROM postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status != 4 THEN 
		# UPDATE vendor history FOR cheques
		CALL update_vendorhist("V") 
		
	# IF the UPDATE does crap out part way this IS NOT a problem
	# we will re UPDATE next time through
	# 20210127 ericv : NICE JOB!!!
		LET glob_err_text = "Update jour_code in postvoucher" 
		CALL crs_postvoucher_scan_all.Open(glob_rec_kandoouser.cmpy_code)
		
		WHILE crs_postvoucher_scan_all.FetchNext(l_rec_voucher.cmpy_code,l_rec_voucher.vouch_code) = 0
			CALL prp_update_voucher_journum_postdate.Execute(l_rec_voucher.jour_num,today,l_rec_voucher.cmpy_code,l_rec_voucher.vouch_code)
		--END IF
		END WHILE #  crs_postvoucher_scan_all
	END IF 

	LET glob_st_code = 4 
	LET glob_post_text = "Commenced DELETE FROM postvoucher" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postvoucher" 

	CALL prp_delete_postvoucher_all.Execute(glob_rec_kandoouser.cmpy_code)

	LET glob_st_code = 99 
	LET glob_post_text = "Voucher Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 

END FUNCTION #  post_vouchers_old() 
}


############################################################
# FUNCTION post_debithead()
#
#
############################################################
FUNCTION post_debithead() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_crs_join_posdebithead_vendor CURSOR

	# IF an error has occurred AND it was NOT in this part of the
	# post THEN walk on by ...
	IF modu_post_status > 8 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced debit post" 
	IF modu_post_status = 5 THEN {error in debit post} 
		# 3518 "Rolling back postdebit AND debit tables"
		MESSAGE kandoomsg2("P",3518,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous debitheads" 

--		IF glob_rec_poststatus.online_ind != "L" THEN 
--			LOCK TABLE postdebithead IN SHARE MODE 
--			LOCK TABLE debithead IN SHARE MODE 
--		END IF 

		LET glob_in_trans = true 
			
		CALL crs_upd_postdebithead_undo.Open(glob_rec_kandoouser.cmpy_code)
		
		WHILE crs_upd_postdebithead_undo.FetchNext(modu_debit_num) = 0
			CALL prp_update_debithead_unflag.Execute(glob_rec_kandoouser.cmpy_code,modu_debit_num)
			CALL prp_delete_postdebithead.Execute(glob_rec_kandoouser.cmpy_code,modu_debit_num) 
		END WHILE # crs_upd_postdebithead_undo 

	END IF  # end of error case, that should simply be resolved by a rollback work and noticing where the issue is ....

	LET glob_st_code = 5 
	LET glob_post_text = "Commenced INSERT TO postdebithead" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status = 5 OR modu_post_status = 99 THEN 
		# SELECT the debitheads FOR posting AND INSERT them INTO
		# the postdebithead table THEN UPDATE them as posted so
		# they won't be touched by anyone ELSE

		SELECT unique 1 
		FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = glob_fisc_year 
		AND period_num = glob_fisc_period 
		AND post_flag = "N" 
		AND total_amt != dist_amt 

		IF sqlca.sqlcode != NOTFOUND THEN 
			ERROR kandoomsg("P",6001,"") 
			# 6001 Debits exist that are NOT fully distributed ",
			#    --    DISPLAY on first line FOR 3 seconds   --
		END IF 

		LET glob_err_text = "Debithead SELECT FOR INSERT" 
		CALL crs_debithead_notflag_period.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year) 

		LET glob_err_text = "Debits FOREACH FOR INSERT" 
--		FOREACH crs_debithead_notflag_period INTO modu_debit_num 
		WHILE crs_debithead_notflag_period.FetchNext(modu_rec_debithead.*) = 0
			--LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
--			WHENEVER ERROR GOTO recovery 
			LET glob_err_text = "PP1 - Insert INTO postdebithead" 
			CALL prp_insert_postdebithead.Execute (modu_rec_debithead.*)

			LET glob_err_text = "PP1 - Debithead post flag SET" 
			CALL prp_update_debithead_flag.Execute(modu_rec_debithead.cmpy_code,modu_rec_debithead.debit_num)
		END WHILE # crs_debithead_notflag_period 
	END IF 

	LET glob_err_text = "Vendor history UPDATE (Debits)" 
	
	LET glob_st_code = 6 
	LET glob_post_text = "Completed INSERT TO postdebithead" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status <= 6 OR modu_post_status = 99 THEN 
		LET modu_prev_vend_type = "z" 
		LET modu_rec_current.tran_type_ind = "DM" 
		LET modu_rec_current.base_debit_amt = 0 
		LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 

		# SELECT all unposted, distributed debits FOR the required period
		IF modu_post_status = 6 THEN {crapped out in gl insert} 
			LET l_crs_join_posdebithead_vendor = crs_join_posdebithead_vendor_ko   # we have declared both crs_join_posdebithead_vendor and crs_join_posdebithead_vendor_ko as module scope, we use local by copy of cursor
			CALL l_crs_join_posdebithead_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_year,glob_fisc_period,glob_rec_poststatus.jour_num)
		ELSE {normal post} 
			LET l_crs_join_posdebithead_vendor = crs_join_posdebithead_vendor
			CALL l_crs_join_posdebithead_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_year,glob_fisc_period)
		END IF

		# CALL l_crs_join_posdebithead_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_year,glob_fisc_period)
		
		LET glob_err_text = "FOREACH INTO posttemp - Debits" 

		WHILE l_crs_join_posdebithead_vendor.FetchNext(modu_rec_docdata.*,modu_rec_current.vend_type,modu_rec_current.disc_amt ) = 0
			IF modu_rec_current.vend_type != modu_prev_vend_type 
			OR (modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) 
			OR (modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 

	# INSERT posting data FOR the Debit discount amount

			IF modu_rec_current.disc_amt IS NOT NULL AND modu_rec_current.disc_amt != 0 THEN 
				IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
					IF modu_rec_docdata.conv_qty != 0 THEN 
						LET modu_rec_current.base_credit_amt = modu_rec_current.disc_amt / modu_rec_docdata.conv_qty 
					END IF 
				END IF 
		
				#IF use_currency_flag IS 'N' THEN any source documents in foreign
				#currency need TO be converted TO base, AND a base batch created.
				IF glob_rec_glparms.use_currency_flag = "N" THEN 
					LET modu_rec_current.disc_amt = modu_rec_current.base_credit_amt 
					LET modu_rec_docdata.conv_qty = 1 
					LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				END IF 

				CALL prp_insert_posttemp.Execute(
				modu_rec_docdata.ref_num, # debit number 
				modu_rec_docdata.ref_text, # vendor code 
				modu_rec_current.disc_acct_code, # discount control account 
				modu_rec_docdata.ref_num, # debit number 
				0, 
				modu_rec_current.disc_amt, # debit discount amount 
				modu_rec_current.base_debit_amt, # zero FOR discounts 
				modu_rec_current.base_credit_amt, # converted credit amt 
				modu_rec_docdata.currency_code, # debit currency code 
				modu_rec_docdata.conv_qty, # debit conversion rate 
				modu_rec_docdata.tran_date, # debit DATE 
				0, # stats qty - NOT yet in use 
				"", # analysis text - NOT in use 
				modu_rec_current.pay_acct_code, # control account 
				0) # doc num - n/a 
			END IF 

	# create posting details FOR the distributions FOR
	# the selected debits

			CALL crs_debitdist_debitcode_vendcode.Open(glob_rec_kandoouser.cmpy_code,modu_rec_docdata.ref_num,modu_rec_docdata.ref_text) 

			WHILE crs_debitdist_debitcode_vendcode.FetchNext(modu_rec_vouchedist_detldata.*) = 0
				IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
					IF modu_rec_docdata.conv_qty != 0 THEN 
						LET modu_rec_current.base_credit_amt = 
						modu_rec_vouchedist_detldata.credit_amt / modu_rec_docdata.conv_qty 
					END IF 
				END IF 

				IF glob_rec_glparms.use_currency_flag = "N" THEN 
					LET modu_rec_vouchedist_detldata.credit_amt = modu_rec_current.base_credit_amt 
					LET modu_sv_conv_qty = 1 
					LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
				ELSE 
					LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
				END IF 

				CALL prp_insert_posttemp.Execute(
				modu_rec_docdata.ref_num, # debit number 
				modu_rec_docdata.ref_text, # vendor code 
				modu_rec_vouchedist_detldata.post_acct_code, # debit distribution account 
				modu_rec_vouchedist_detldata.desc_text, # debit distribution desc 
				modu_rec_vouchedist_detldata.debit_amt, # zero FOR "DM" 
				modu_rec_vouchedist_detldata.credit_amt, # debit distribution amount 
				modu_rec_current.base_debit_amt, # zero FOR "DM" 
				modu_rec_current.base_credit_amt, # converted distribution amt 
				modu_rec_docdata.currency_code, # debit currency code 
				modu_sv_conv_qty, # debit conversion rate 
				modu_rec_docdata.tran_date, # debit DATE 
				modu_rec_vouchedist_detldata.stats_qty, # distribution quantity 
				modu_rec_vouchedist_detldata.analysis_text, # analysis text 
				modu_rec_current.pay_acct_code, # control account 
				0) # doc num - n/a 
			END WHILE # crs_debitdist_debitcode_vendcode 
		END WHILE # l_crs_join_posdebithead_vendor
	
		IF modu_post_status = 6 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
		
		LET modu_rec_bal_rec.tran_type_ind = "DM" 
		LET modu_rec_bal_rec.desc_text = " AP Debit Balancing Entry" 
		
--MESSAGE "" 
# 3503 " Posting debits..."
		MESSAGE kandoomsg2("P",3503,"") 
		--SLEEP 1 
		CALL create_gl_batches() 
	END IF 

	LET glob_st_code = 7 
	LET glob_post_text = "Commence upd jour_num FROM postdebithead" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status != 8 THEN 
		# UPDATE vendor history FOR cheques
		CALL update_vendorhist("D") 
		# IF the UPDATE does crap out part way this IS NOT a problem
		# we will re UPDATE next time through
		LET glob_err_text = "Update jour_code in postdebithead" 
		CALL crs_postdebithead_scan.Open(glob_rec_kandoouser.cmpy_code)
		WHILE crs_postdebithead_scan.FetchNext(modu_rec_debithead.*) = 0 
			CALL prp_update_debithead_journum.Execute(modu_rec_debithead.jour_num,today,modu_rec_debithead.cmpy_code,modu_rec_debithead.debit_num)
		END WHILE # crs_postdebithead_scan 
	END IF 

	LET glob_st_code = 8 
	LET glob_post_text = "Commenced DELETE FROM postdebithead" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	
	LET glob_err_text = "DELETE FROM postdebithead" 

	DELETE FROM postdebithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	LET glob_st_code = 99 
	LET glob_post_text = "Debits Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	
	RETURN 0   # All OK

END FUNCTION   # post_debithead


############################################################
# FUNCTION post_cheques()
#
# ??? someone dreaming ???? who wrote/did this ? -> #had TO rename this FUNCTION because the name "cheque" was causing a
# conflict using Querix with database table "cheque", WHEN using
# tablename.columnname notation
############################################################
FUNCTION post_cheques(p_period_num,p_year_num) 
	DEFINE p_period_num LIKE batchhead.period_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_pay_meth LIKE cheque.pay_meth_ind 
	DEFINE l_desc_text LIKE batchdetl.desc_text 
	DEFINE l_bank_code LIKE cheque.bank_code 
	DEFINE l_vend_code LIKE cheque.vend_code 
	DEFINE l_doc_num INTEGER 
	DEFINE l_sql_statement STRING
	DEFINE l_rec_cheque RECORD LIKE cheque.* 

	IF crs_join_cheque_vendor.getStatement() IS NULL THEN    # prepare all cursors and sql stmts for this function
		LET l_sql_statement = "SELECT cheque.cmpy_code, ", 
		"cheque.cheq_code, ", 
		"cheque.vend_code, ", 
		"cheque.cheq_date, ", 
		"cheque.currency_code, ", 
		"cheque.conv_qty, ", 
		"vendor.type_code, ", 
		"cheque.pay_meth_ind, ", 
		"cheque.bank_acct_code, ", 
		"cheque.cheq_code, ", 
		"0, ", 
		"' ', ", 
		"0, ", 
		"cheque.net_pay_amt, ", 
		"cheque.doc_num ", 
		"FROM cheque ,",
		"vendor ", 
		" WHERE cheque.cmpy_code = ? ",
		"AND cheque.post_flag = 'N' ", 
		" AND cheque.period_num = ? ", 
		" AND cheque.year_num = ? ", 
		" AND cheque.apply_amt > 0 ",
		"AND cheque.cmpy_code = vendor.cmpy_code ", 
		"AND cheque.vend_code = vendor.vend_code ",
		" ORDER BY cheque.cmpy_code, cheque.vend_code, cheque.cheq_code " 
		--CALL crs_join_cheque_vendor.Declare(l_sql_statement)
		--DECLARE cd_curs CURSOR FOR cheq_sel 
		CALL cd_curs.Declare(l_sql_statement)

		# glob_rec_kandoouser.cmpy_code 
		# glob_fisc_period
		# glob_fisc_year

		LET l_sql_statement = "INSERT INTO postcheque VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
		CALL prp_insert_postcheque.Prepare(l_sql_statement)

		LET l_sql_statement = "INSERT INTO postwhtax VALUES (?,?,?,?,?,?,?,?,?,?,?)"
		CALL prp_insert_postwhtax.Prepare(l_sql_statement)

		LET l_sql_statement = "INSERT INTO postaptrans VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
		CALL prp_insert_postaptrans.Prepare(l_sql_statement)

		LET l_sql_statement = "UPDATE cheque ",
		" SET post_flag = 'Y' ", 
		"WHERE vend_code = ? ",
		" AND cheq_code = ? ",
		" AND cmpy_code = ? "
		CALL prp_update_cheque_flag.Prepare(l_sql_statement)
	END IF

	LET glob_err_text = "Commenced cheque post" 
#	# the "rollback manual process" is useless, replaced by BEGIN WORK / COMMIT WORK ericv 20210216

	LET glob_st_code = 9 
	LET glob_post_text = "Commenced INSERT TO postcheque AND postwhtax" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status <= 9 OR modu_post_status = 99 THEN 
		# SELECT the cheques FOR posting AND INSERT them INTO the postcheque
		# table THEN UPDATE them as posted so they won't be touched by anyone
		# ELSE

		LET glob_err_text = "Cheque SELECT FOR INSERT" 

		--CALL crs_join_cheque_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year) 
		LET modu_prev_vend_type = "z" 
		LET glob_err_text = "Cheques FOREACH FOR INSERT" 

		## First browse the cheques 
		## But also browse discounts if discount then create separate batch ( to check if no better though ...)
		{
		WHILE crs_join_cheque_vendor.FetchNext(modu_cheq_code,modu_bank_acct_code,l_pay_meth,modu_rec_current.vend_type,l_vend_code) = 0 
			# reselecting the check is a bit stupid but ...
			SELECT * INTO l_rec_cheque.*
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = modu_cheq_code 
				AND vend_code = l_vend_code

			IF sqlca.sqlcode = 0 THEN
				LET glob_err_text = "PP1 - Insert INTO postcheque" 
				CALL prp_insert_postcheque.Execute(l_rec_cheque.*) 
			END IF
			#
			#  Get all the applicable posting details in this first phase,
			#  including the balancing accounts
			#
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code 
			END IF 
			#
			# IF tax applicable, INSERT details INTO tax posting table
			#
			IF l_rec_cheque.withhold_tax_ind != "0" THEN 
				LET glob_err_text = "PP1 - Insert INTO postwhtax" 
				INITIALIZE modu_rec_postwhtax.* TO NULL 
				LET modu_rec_postwhtax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_postwhtax.tax_vend_code = modu_rec_current.tax_vend_code 
				LET modu_rec_postwhtax.payee_tran_type = "1" 
				LET modu_rec_postwhtax.payee_vend_code = l_rec_cheque.vend_code 
				LET modu_rec_postwhtax.payee_ref_num = l_rec_cheque.cheq_code 
				LET modu_rec_postwhtax.payee_bank_code = l_rec_cheque.bank_code 
				LET modu_rec_postwhtax.tax_amt = l_rec_cheque.tax_amt 
				LET modu_rec_postwhtax.pay_acct_code = modu_rec_current.pay_acct_code 
				LET modu_rec_postwhtax.pay_meth_ind = l_rec_cheque.pay_meth_ind 
				CALL prp_insert_postwhtax.Execute(modu_rec_postwhtax.*)
			END IF 

			#
			# IF contra amounts exist, INSERT details INTO contra posting table
			#
			IF l_rec_cheque.contra_amt != 0 THEN 
				LET glob_err_text = "PP1 - Insert INTO postaptrans - CCO" 
				INITIALIZE modu_rec_postaptrans.* TO NULL 
	
				LET modu_rec_postaptrans.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_postaptrans.type_code = "CCO" # cheque contra 
				LET modu_rec_postaptrans.ref_num = l_rec_cheque.cheq_code 
				LET modu_rec_postaptrans.ref_code = l_rec_cheque.vend_code 
				LET modu_rec_postaptrans.doc_num = l_rec_cheque.doc_num 
				LET modu_rec_postaptrans.post_acct_code = glob_rec_glparms.clear_acct_code 
				LET modu_rec_postaptrans.bal_acct_code = modu_rec_current.pay_acct_code 
				LET modu_rec_postaptrans.desc_text = l_rec_cheque.pay_meth_ind, " ", 
					l_rec_cheque.cheq_code USING "<<<<<<<<<<" clipped, " contra ", 
					l_rec_cheque.contra_trans_num USING "<<<<<<<<<<" 
				LET modu_rec_postaptrans.debit_amt = 0 
				LET modu_rec_postaptrans.credit_amt = l_rec_cheque.contra_amt 
				LET modu_rec_postaptrans.currency_code = l_rec_cheque.currency_code 
				LET modu_rec_postaptrans.conv_qty = l_rec_cheque.conv_qty 
				LET modu_rec_postaptrans.tran_date = l_rec_cheque.cheq_date 
				LET modu_rec_postaptrans.year_num = l_rec_cheque.year_num 
				LET modu_rec_postaptrans.period_num = l_rec_cheque.period_num 
				LET modu_rec_postaptrans.post_status_num = 0 
				LET modu_rec_postaptrans.bank_code = l_rec_cheque.bank_code 
				LET modu_rec_postaptrans.pay_meth_ind = l_rec_cheque.pay_meth_ind 
				LET modu_rec_postaptrans.stats_qty = 0 
				CALL prp_insert_postaptrans.Execute(modu_rec_postaptrans.*) 
			END IF 

			LET glob_err_text = "PP1 - Cheque post flag SET" 
			CALL prp_update_cheque_flag.Execute(l_vend_code,modu_cheq_code,glob_rec_kandoouser.cmpy_code )
		END WHILE # crs_join_cheque_vendor
	END IF 

	LET glob_err_text = "Create gl batch - Cheques" 
	
	LET glob_st_code = 10 
	LET glob_post_text = "Completed INSERT TO postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status <= 10 OR modu_post_status = 99 THEN 
	
		LET modu_prev_vend_type = "z" 
		LET modu_rec_current.tran_type_ind = "CH" 
		LET modu_rec_current.base_debit_amt = 0 
		LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 

# INSERT posting data FOR the Cheque discount amount
# discounts posted in a separate batch TO cheque payments due TO
# differing journal codes
# SELECT only non-zero discounts FOR posting

		LET modu_select_text = 
		"SELECT C.cmpy_code, ", 
		"C.cheq_code, ", 
		"C.vend_code, ", 
		"C.cheq_date, ", 
		"C.currency_code, ", 
		"C.conv_qty, ", 
		"V.type_code, ", 
		"C.pay_meth_ind, ", 
		"' ', ", 
		"C.cheq_code, ", 
		"0, ", 
		"' ', ", 
		"0, ", 
		"C.disc_amt, ", 
		"C.doc_num ", 
		"FROM postcheque C, vendor V ", 
		"WHERE C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND C.post_flag = 'N' ", 
		"AND C.year_num = ",glob_fisc_year," ", 
		"AND C.period_num = ",glob_fisc_period," ", 
		"AND C.disc_amt IS NOT NULL ", 
		"AND C.disc_amt != 0 ", 
		"AND C.cmpy_code = V.cmpy_code ", 
		"AND C.vend_code = V.vend_code" 
		}
		IF modu_post_status = 10 THEN {crapped out in post TO gl} 
			LET modu_select_text = modu_select_text clipped, 
			" AND (C.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"C.jour_num IS NULL OR C.jour_num = 0) ", 
			"ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		END IF 

--		PREPARE cheq_sel FROM modu_select_text 
--		DECLARE cd_curs CURSOR FOR cheq_sel 

		LET glob_err_text = "FOREACH FOR cheque discount" 
		CALL cd_curs.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year)
		WHILE cd_curs.FetchNext(l_cmpy_code,modu_rec_docdata.*,modu_rec_current.vend_type,l_pay_meth,modu_rec_vouchedist_detldata.*,l_doc_num ) = 0
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_vouchedist_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
		
			#IF use_currency_flag IS 'N' THEN any source documents in foreign
			#currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_vouchedist_detldata.credit_amt = modu_rec_current.base_credit_amt 
				LET modu_sv_conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		
			LET l_desc_text = NULL 
			LET l_desc_text = modu_rec_vouchedist_detldata.desc_text 
			LET modu_rec_vouchedist_detldata.desc_text = l_pay_meth, " ", l_desc_text 
			{
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # cheque number 
			modu_rec_docdata.ref_text, # vendor code 
			modu_rec_current.disc_acct_code, # discount control account 
			modu_rec_vouchedist_detldata.desc_text, # cheque number 
			modu_rec_vouchedist_detldata.debit_amt, # zero FOR cheque discounts 
			modu_rec_vouchedist_detldata.credit_amt, # cheque discount amount 
			modu_rec_current.base_debit_amt, # zero FOR cheque discounts 
			modu_rec_current.base_credit_amt, # converted discount amount 
			modu_rec_docdata.currency_code, # cheque currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # cheque DATE 
			modu_rec_vouchedist_detldata.stats_qty, # defaulted TO 0 - NOT impl'ted 
			modu_rec_vouchedist_detldata.analysis_text, # defaulted TO - NOT impl'ted 
			modu_rec_current.pay_acct_code, # control account 
			l_doc_num) # unique cheque doc num 
			}
		END WHILE   #  cd_curs
		LET modu_rec_bal_rec.tran_type_ind = "CH" 
		LET modu_rec_bal_rec.desc_text = " AP Cheque Discount Balancing Entry" 
		
		IF modu_post_status = 10 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

--MESSAGE "" 
# 3505 " Posting cheque disc..."
		MESSAGE kandoomsg2("P",3505,"") 
--		SLEEP 1 
		CALL create_gl_batches() 

		DELETE FROM posttemp WHERE 1 = 1 

# INSERT posting data FOR the Cheque payment amounts

		LET modu_select_text = 
		"SELECT C.cmpy_code, ", 
		"C.cheq_code, ", 
		"C.vend_code, ", 
		"C.cheq_date, ", 
		"C.currency_code, ", 
		"C.conv_qty, ", 
		"V.type_code, ", 
		"C.pay_meth_ind, ", 
		"C.bank_acct_code, ", 
		"C.cheq_code, ", 
		"0, ", 
		"' ', ", 
		"0, ", 
		"C.net_pay_amt, ", 
		"C.doc_num ", 
		"FROM postcheque C, vendor V ", 
		"WHERE C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND C.post_flag = 'N' ", 
		"AND C.year_num = ",glob_fisc_year," ", 
		"AND C.period_num = ",glob_fisc_period," ", 
		"AND C.cmpy_code = V.cmpy_code ", 
		"AND C.vend_code = V.vend_code "
 
		IF modu_post_status = 10 THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (C.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"C.jour_num IS NULL OR C.jour_num = 0) ", 
			"ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		END IF 

		PREPARE ch_sel FROM modu_select_text 
		DECLARE ch_curs CURSOR FOR ch_sel 
		
		LET glob_err_text = "FOREACH FOR cheques" 

		FOREACH ch_curs INTO l_cmpy_code, 
			modu_rec_docdata.*, 
			modu_rec_current.vend_type, 
			l_pay_meth, 
			modu_rec_vouchedist_detldata.*, 
			l_doc_num 
		
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_vouchedist_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
		
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_vouchedist_detldata.credit_amt = modu_rec_current.base_credit_amt 
				LET modu_sv_conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		
			LET l_desc_text = NULL 
			LET l_desc_text = modu_rec_vouchedist_detldata.desc_text 
			LET modu_rec_vouchedist_detldata.desc_text = l_pay_meth, " ", l_desc_text 
			
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # cheque number 
			modu_rec_docdata.ref_text, # vendor code 
			modu_rec_vouchedist_detldata.post_acct_code, # cheque bank gl account 
			modu_rec_vouchedist_detldata.desc_text, # cheque number 
			modu_rec_vouchedist_detldata.debit_amt, # zero FOR "CH" 
			modu_rec_vouchedist_detldata.credit_amt, # cheque net payment amount 
			modu_rec_current.base_debit_amt, # zero FOR "CH" 
			modu_rec_current.base_credit_amt, # converted payment amount 
			modu_rec_docdata.currency_code, # cheque currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # cheque DATE 
			modu_rec_vouchedist_detldata.stats_qty, # defaulted TO 0 - NOT impl'ted 
			modu_rec_vouchedist_detldata.analysis_text, # defaulted TO - NOT impl'ted 
			modu_rec_current.pay_acct_code, # control account 
			l_doc_num) # unique cheque doc num 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "CH" 
		LET modu_rec_bal_rec.desc_text = " AP Cheques Balancing Entry" 
		LET modu_rec_current.jour_code = glob_rec_apparms.chq_jour_code 
		
		LET modu_flag_cheques = true 
		
		IF modu_post_status = 10 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

		MESSAGE "" 
# 3504 " Posting cheques..."
		MESSAGE kandoomsg2("P",3504,"") 
--		SLEEP 1 
		CALL create_gl_batches() 
	
	END IF 

	LET glob_st_code = 11 
	LET glob_post_text = "Commenced UPDATE jour_num FROM postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status != 12 THEN 
# UPDATE vendor history FOR cheques
		CALL update_vendorhist("C") 

# IF the UPDATE does crap out part way this IS NOT a problem
# we will re UPDATE next time through
		LET glob_err_text = "Update jour_code in postcheque" 
		DECLARE update_jour1 CURSOR with HOLD FOR 
			SELECT * 
			FROM postcheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH update_jour1 INTO l_rec_cheque.* 
			IF NOT glob_one_trans THEN 
				BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			UPDATE cheque 
			SET jour_num = l_rec_cheque.jour_num, 
			post_date = today 
			WHERE cmpy_code = l_rec_cheque.cmpy_code 
			AND cheq_code = l_rec_cheque.cheq_code 
			AND vend_code = l_rec_cheque.vend_code 
			AND bank_acct_code = l_rec_cheque.bank_acct_code 
			AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
			IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 

	LET glob_st_code = 12 
	LET glob_post_text = "Commenced DELETE FROM postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postcheque" 
--	IF NOT glob_one_trans THEN 
--		BEGIN WORK 
--		LET glob_in_trans = true 
--	END IF 
--	IF glob_rec_poststatus.online_ind != "L" THEN 
--		LOCK TABLE postcheque in share MODE 
--	END IF 
	DELETE FROM postcheque WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	IF NOT glob_one_trans THEN 
--		COMMIT WORK 
--		LET glob_in_trans = false 
--	END IF 

	LET glob_st_code = 99 
	LET glob_post_text = "Cheque Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	RETURN 0

END FUNCTION  # post_cheques



############################################################
# FUNCTION post_exchangevar()
#
#
############################################################
FUNCTION post_exchangevar() 
	DEFINE l_rowid INTEGER 
	DEFINE l_rowid_num INTEGER 
	DEFINE l_ref2_num LIKE exchangevar.ref2_num 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_tran_type2_ind LIKE exchangevar.tran_type2_ind 
	DEFINE l_ref1_num LIKE exchangevar.ref1_num 
	DEFINE l_tran_type1_ind LIKE exchangevar.tran_type1_ind 
	
	GOTO bypass 
	LABEL recovery: 
	
	CALL update_poststatus(NOT_OK,STATUS,"AP") 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 


	# IF an error has occurred AND it was NOT in this part of the post
	# THEN 'baby walk on by, just walk on by (etc)'
	IF modu_post_status > 16 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced exchange post" 
	IF modu_post_status = 13 THEN {error in exchangevar post} 
		# 3520 "Rolling back postexchvar AND exchangevar tables"
		ERROR kandoomsg2("P",3520,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous vouchers" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 
			LET glob_in_trans = true 
		END IF 

		IF glob_rec_poststatus.online_ind != "L" THEN 
			LOCK TABLE postexchvar in share MODE 
			LOCK TABLE exchangevar in share MODE 
		END IF 

		LET glob_in_trans = true 
		DECLARE exch_undo CURSOR FOR 
			SELECT rowid, #the rowid FROM postexchvar 
			rowid_num, #the rowid FROM exchangevar 
			tran_type1_ind, 
			ref1_num, 
			tran_type2_ind, 
			ref2_num 
			FROM postexchvar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

		FOREACH exch_undo 
			INTO l_rowid, #the rowid FROM postexchvar 
			l_rowid_num, #the rowid FROM exchangevar 
			l_tran_type1_ind, 
			l_ref1_num, 
			l_tran_type2_ind, 
			l_ref2_num 

			UPDATE exchangevar 
			SET posted_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rowid = l_rowid_num 

			DELETE FROM postexchvar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rowid = l_rowid 

		END FOREACH 
		IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 

	LET glob_st_code = 13 
	LET glob_post_text = "Commenced INSERT INTO postexchvar" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status = 13 OR modu_post_status = 99 THEN 
		# SELECT the exchangevars FOR posting AND INSERT them INTO the
		# postvoucher table THEN UPDATE them as posted so they won't be touched
		# by anyone.
		LET glob_err_text = "Exchangevar SELECT FOR INSERT" 
		DECLARE exch_curs CURSOR with HOLD FOR 
			SELECT rowid, #the rowid FROM exchangevar 
			tran_type1_ind, 
			ref1_num, 
			tran_type2_ind, 
			ref2_num 
			FROM exchangevar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND posted_flag = "N" 
			AND period_num = glob_fisc_period 
			AND year_num = glob_fisc_year 
			AND source_ind = "P" 

		LET glob_err_text = "Exchangevar FOREACH FOR INSERT" 
		FOREACH exch_curs INTO l_rowid, 
			l_tran_type1_ind, 
			l_ref1_num, 
			l_tran_type2_ind, 
			l_ref2_num 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
					LET glob_in_trans = true 
				END IF 
				WHENEVER ERROR CONTINUE 

				DECLARE insert4_curs CURSOR FOR 
					SELECT * 
					FROM exchangevar 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND rowid = l_rowid 
					FOR UPDATE 

				LET glob_err_text = "Exchangevar lock FOR INSERT" 
				OPEN insert4_curs 
				FETCH insert4_curs INTO modu_rec_exchangevar.* 
				LET modu_stat_code = status 
	
				IF modu_stat_code THEN 
					IF modu_stat_code = NOTFOUND THEN 
						IF NOT glob_one_trans THEN 
							COMMIT WORK 
							LET glob_in_trans = false 
						END IF 
						CONTINUE FOREACH 
					END IF 
			
					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Exchvar INSERT", 
							modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(NOT_OK,modu_stat_code,"AP") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(NOT_OK,modu_stat_code,"AP") 
						END IF 
					ELSE 
						IF NOT glob_one_trans THEN 
							COMMIT WORK 
							LET glob_in_trans = false 
						END IF 
						CONTINUE WHILE 
					END IF 
				END IF 
				EXIT WHILE 
			END WHILE 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

			WHENEVER ERROR GOTO recovery 

			LET glob_err_text = "PP1 - Post Exchangevar INSERT" 
			INSERT INTO postexchvar VALUES (modu_rec_exchangevar.*, l_rowid) 
		
			LET glob_err_text = "PP1 - Exchangevar post flag SET" 
			UPDATE exchangevar SET posted_flag = "Y" 
			WHERE CURRENT OF insert4_curs 

			IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 

	LET glob_err_text = "Create gl batch - exchangevar" 
	LET glob_st_code = 14 
	CALL update_poststatus(ALL_OK,0,"AP") 
	
	IF modu_post_status <= 14 OR modu_post_status = 99 THEN 
	
		LET modu_prev_vend_type = "z" 
		LET modu_rec_current.tran_type_ind = "EXP" 
		LET modu_rec_current.jour_code = glob_rec_apparms.chq_jour_code 

# INSERT posting data FOR the Payables exchange variances
# first debits

		IF modu_post_status = 14 THEN {post crapped out in ap vars} 
			LET modu_select_text = 
			"SELECT E.ref1_num, ", 
			" E.ref2_num, ", 
			" E.tran_date, ", 
			" E.currency_code, ", 
			" 1, ", 
			" E.ref_code, ", 
			" E.exchangevar_amt, ", 
			" V.type_code ", 
			"FROM postexchvar E, vendor V ", 
			"WHERE E.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND E.posted_flag = 'N' ", 
			"AND E.year_num = ",glob_fisc_year," ", 
			"AND E.period_num = ",glob_fisc_period," ", 
			"AND E.source_ind = 'P' ", 
			"AND E.cmpy_code = V.cmpy_code ", 
			"AND E.ref_code = V.vend_code ", 
			"AND E.exchangevar_amt > 0 ", 
			"AND (E.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			" E.jour_num IS NULL OR", 
			" E.jour_num = 0) ", 
			"ORDER BY E.ref_code " 
		ELSE {normal post} 
			LET modu_select_text = 
			"SELECT E.ref1_num, ", 
			" E.ref2_num, ", 
			" E.tran_date, ", 
			" E.currency_code, ", 
			" 1, ", 
			" E.ref_code, ", 
			" E.exchangevar_amt, ", 
			" V.type_code ", 
			"FROM postexchvar E, vendor V ", 
			"WHERE E.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND E.posted_flag = 'N' ", 
			"AND E.year_num = ",glob_fisc_year," ", 
			"AND E.period_num = ",glob_fisc_period," ", 
			"AND E.source_ind = 'P' ", 
			"AND E.cmpy_code = V.cmpy_code ", 
			"AND E.ref_code = V.vend_code ", 
			"AND E.exchangevar_amt > 0 ", 
			"ORDER BY E.ref_code " 
		END IF 

		PREPARE exch_sel FROM modu_select_text 
		DECLARE exd_curs CURSOR FOR exch_sel 
		
		LET glob_err_text = "FOREACH AP (+ve) exchangevar" 
		FOREACH exd_curs INTO modu_rec_docdata.*, 
			modu_rec_current.exch_ref_code, 
			modu_rec_current.base_debit_amt, 
			modu_rec_current.vend_type 
		
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # exch var ref 1 
			modu_rec_docdata.ref_text, # exch var ref 2 
			modu_rec_current.exch_acct_code, # exchange control account 
			modu_rec_current.exch_ref_code, # vendor code FOR source_ind "P" 
			modu_rec_current.base_debit_amt, # exchange var foreign amt - always in base currency 
			0, 
			modu_rec_current.base_debit_amt, # exch var amount IF +ve, 
			0, 
			glob_rec_glparms.base_currency_code, # base currency code 
			modu_rec_docdata.conv_qty, # exch var conversion rate 
			modu_rec_docdata.tran_date, # exch var DATE 
			0, # stats qty - NOT yet in use 
			"", # analysis text NOT yet in use 
			modu_rec_current.pay_acct_code, # control account 
			0) # doc num - n/a 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "EXP" 
		LET modu_rec_bal_rec.desc_text = " AP Exch Var Balancing Entry" 
		
		IF modu_post_status = 14 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

--MESSAGE "" 
# 3506 " Posting exch var..."
		MESSAGE kandoomsg2("P",3506,"") 
		SLEEP 1 
		CALL create_gl_batches() 

		DELETE FROM posttemp WHERE 1 = 1 
		
		LET glob_st_code = 15 
		LET glob_post_text = "Commenced second exchangevar post" 
		CALL update_poststatus(ALL_OK,0,"AP") 

		IF modu_post_status = 15 THEN {post crapped out here} 
			LET modu_select_text = 
			"SELECT E.ref1_num, ", 
			" E.ref2_num, ", 
			" E.tran_date, ", 
			" E.currency_code, ", 
			" 1, ", 
			" E.ref_code, ", 
			" E.exchangevar_amt, ", 
			" V.type_code ", 
			"FROM postexchvar E, vendor V ", 
			"WHERE E.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND E.posted_flag = 'N' ", 
			"AND E.year_num = ",glob_fisc_year," ", 
			"AND E.period_num = ",glob_fisc_period," ", 
			"AND E.source_ind = 'P' ", 
			"AND E.cmpy_code = V.cmpy_code ", 
			"AND E.ref_code = V.vend_code ", 
			"AND E.exchangevar_amt < 0 ", 
			"AND (E.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			" E.jour_num IS NULL OR ", 
			" E.jour_num = 0)", 
			"ORDER BY E.ref_code " 
		ELSE {normal post} 
			LET modu_select_text = 
			"SELECT E.ref1_num, ", 
			" E.ref2_num, ", 
			" E.tran_date, ", 
			" E.currency_code, ", 
			" 1, ", 
			" E.ref_code, ", 
			" E.exchangevar_amt, ", 
			" V.type_code ", 
			"FROM postexchvar E, vendor V ", 
			"WHERE E.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
			"AND E.posted_flag = 'N' ", 
			"AND E.year_num = ",glob_fisc_year," ", 
			"AND E.period_num = ",glob_fisc_period," ", 
			"AND E.source_ind = 'P' ", 
			"AND E.cmpy_code = V.cmpy_code ", 
			"AND E.ref_code = V.vend_code ", 
			"AND E.exchangevar_amt < 0 ", 
			"ORDER BY E.ref_code " 
		END IF 

		PREPARE exc_sel FROM modu_select_text 
		DECLARE exc_curs CURSOR FOR exc_sel 

		LET glob_err_text = "FOREACH AP (-ve) exch variation" 
		FOREACH exc_curs INTO modu_rec_docdata.*, 
			modu_rec_current.exch_ref_code, 
			modu_rec_current.base_credit_amt, 
			modu_rec_current.vend_type 
		
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			LET modu_rec_current.base_credit_amt = 0 - modu_rec_current.base_credit_amt - 0 
		
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # exch var ref 1 
			modu_rec_docdata.ref_text, # exch var ref 2 
			modu_rec_current.exch_acct_code, # exchange control account 
			modu_rec_current.exch_ref_code, # vendor code FOR source_ind "P" 
			0, 
			modu_rec_current.base_credit_amt, # foreign amt 
			0, 
			modu_rec_current.base_credit_amt, # exch var amount 
			# IF -ve (sign reversed)
			glob_rec_glparms.base_currency_code, # base currency code 
			modu_rec_docdata.conv_qty, # exch var conversion rate 
			modu_rec_docdata.tran_date, # exch var DATE 
			0, # stats qty - NOT yet in use 
			"", # analysis text NOT yet in use 
			modu_rec_current.pay_acct_code, # control account 
			0) # doc num - n/a 
		
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "EXP" 
		LET modu_rec_bal_rec.desc_text = " AP Exch Var Balancing Entry" 

		IF modu_post_status = 15 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

		MESSAGE "" 
# 3506 " Posting exch var..." AT 1,1
		MESSAGE kandoomsg2("P",3506,"") 
--		SLEEP 1 
		CALL create_gl_batches() 
	END IF 


	LET glob_st_code = 16 
	LET glob_post_text = "Commenced upd jour_num FROM postexchvar" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status != 17 THEN 
		LET glob_err_text = "Update jour_num in exchangevar" 
		DECLARE update_exchvar CURSOR with HOLD FOR 
			SELECT * #including rowid_num, e.g. the rowid FROM exchangevar 
			FROM postexchvar 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH update_exchvar INTO modu_rec_exchangevar.*, l_rowid_num 
			IF NOT glob_one_trans THEN 
				BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			UPDATE exchangevar 
			SET jour_num = modu_rec_exchangevar.jour_num, 
			post_date = today 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rowid = l_rowid_num 

			IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 

	LET glob_st_code = 17 
	LET glob_post_text = "Commenced DELETE FROM postexchvar" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postexchvar" 
--	IF NOT glob_one_trans THEN 
--		BEGIN WORK 
--		LET glob_in_trans = true 
--	END IF 
--	IF glob_rec_poststatus.online_ind != "L" THEN 
--		LOCK TABLE postexchvar in share MODE 
--	END IF 
	DELETE FROM postexchvar WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	IF NOT glob_one_trans THEN 
--		COMMIT WORK 
--		LET glob_in_trans = false 
--	END IF 

	LET glob_st_code = 99 
	LET glob_post_text = "Exchange var posting completed correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	RETURN 0

END FUNCTION    #  post_exchangevar


############################################################
# FUNCTION flag_all_tables_as_posted()
#
#
############################################################
FUNCTION flag_all_tables_as_posted() 

	GOTO bypass 
	LABEL recovery: 

	CALL update_poststatus(NOT_OK,STATUS,"AP") 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	# flag each document in the current period as posted (history only)

	# history UPDATE - vouchers
	CALL update_vendorhist("V") 

	LET glob_err_text = " Voucher post flag reset "
 
	UPDATE voucher 
	SET post_flag = "Y" 
	#   WHERE  voucher.cmpy_code = glob_rec_kandoouser.cmpy_code
	WHERE @cmpy_code = glob_rec_kandoouser.cmpy_code 
	#   AND    voucher.post_flag = "N"
	AND @post_flag = "N" 
	#   AND    voucher.total_amt = voucher.dist_amt
	AND @total_amt = voucher.dist_amt 
	#   AND    voucher.period_num = glob_fisc_period
	AND @period_num = glob_fisc_period 
	#   AND    voucher.year_num = glob_fisc_year
	AND @year_num = glob_fisc_year 

	# history UPDATE - cheques
	CALL update_vendorhist("C") 

	LET glob_err_text = " Cheque post flag reset " 

	UPDATE cheque 
	SET post_flag = "Y" 
	WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cheque.post_flag = "N" 
	AND cheque.period_num = glob_fisc_period 
	AND cheque.year_num = glob_fisc_year 

	# history UPDATE - debits
	CALL update_vendorhist("D") 

	LET glob_err_text = " Debit post flag reset " 

	UPDATE debithead 
	SET post_flag = "Y" 
	WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND debithead.post_flag = "N" 
	AND debithead.total_amt = debithead.dist_amt 
	AND debithead.period_num = glob_fisc_period 
	AND debithead.year_num = glob_fisc_year 

	LET glob_err_text = " Exchange Variance post flag reset " 

	UPDATE exchangevar 
	SET posted_flag = "Y" 
	WHERE exchangevar.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND exchangevar.posted_flag = "N" 
	AND exchangevar.year_num = glob_fisc_year 
	AND exchangevar.period_num = glob_fisc_period 
	AND exchangevar.source_ind = "P" 

END FUNCTION   # flag_all_tables_as_posted


############################################################
# FUNCTION post_wholdtax()
#
#
############################################################
FUNCTION post_wholdtax() 
	DEFINE l_total_tax_amt LIKE voucher.total_amt 
	DEFINE l_doc_count SMALLINT 
	DEFINE l_spaces CHAR(240) 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 

	CALL update_poststatus(NOT_OK,STATUS,"AP") 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 

	IF modu_post_status > 20 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_st_code = 18 
	LET glob_post_text = "Commenced w/tax voucher creation FROM postwhtax" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	MESSAGE kandoomsg2("P", 3001, "") #3001 Posting withholding tax

	#  Create a tax voucher OR debit FOR the total amount of tax FOR each
	#  combination of Tax Vendor AND distribution account, flagging the
	#  details with the associated voucher OR debit number AND tran type
	#  COMMIT WORK TO the database AT the successful completion of each
	#  document AND recording of the reference number

	IF modu_post_status <= 18 OR modu_post_status = 99 THEN 
--		IF NOT glob_one_trans THEN 
--			BEGIN WORK 
--			LET glob_in_trans = true 
--		END IF 

		DECLARE c1_wtax CURSOR FOR 
			SELECT tax_vend_code, pay_acct_code, SUM(tax_amt) 
			FROM postwhtax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_ref_num IS NULL 
			GROUP BY tax_vend_code, pay_acct_code 

		FOREACH c1_wtax INTO modu_rec_postwhtax.tax_vend_code, 
				modu_rec_postwhtax.pay_acct_code, 
				l_total_tax_amt 
				# No need FOR zero vouchers
			IF l_total_tax_amt = 0 THEN 
				CONTINUE FOREACH 
			END IF 
			IF l_total_tax_amt < 0 THEN 
				LET glob_err_text = "Creating Tax debit FOR ", modu_rec_postwhtax.tax_vend_code 
				LET modu_rec_postwhtax.tax_ref_num = 
				create_tax_debit(glob_rec_kandoouser.cmpy_code,modu_sl_id, modu_rec_postwhtax.tax_vend_code, l_total_tax_amt, modu_rec_postwhtax.pay_acct_code,glob_fisc_year, glob_fisc_period) 

				# Need TO force a rollback IF any error in creating the debit
				IF modu_rec_postwhtax.tax_ref_num IS NULL THEN 
					LET l_spaces = 
					" Logic Error - Tax Vendor Not Found.", 47 spaces, 
					" Tax Vendor = ", modu_rec_postwhtax.tax_vend_code 
					CALL errorlog(l_spaces) 
					CALL update_poststatus(NOT_OK,0,"AP") 
				END IF 

				UPDATE postwhtax 
				SET tax_tran_type = "2", 
				tax_ref_num = modu_rec_postwhtax.tax_ref_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_vend_code = modu_rec_postwhtax.tax_vend_code 
				AND pay_acct_code = modu_rec_postwhtax.pay_acct_code 
			ELSE 
				LET glob_err_text = "Creating Tax voucher FOR ", modu_rec_postwhtax.tax_vend_code 
				LET modu_rec_postwhtax.tax_ref_num = 
				create_tax_voucher(glob_rec_kandoouser.cmpy_code,modu_sl_id, modu_rec_postwhtax.tax_vend_code, l_total_tax_amt, modu_rec_postwhtax.pay_acct_code, glob_fisc_year, glob_fisc_period) 
				# Need TO force a rollback IF any error in creating the debit
				IF modu_rec_postwhtax.tax_ref_num IS NULL THEN 
					LET l_spaces = 
					" Logic Error - Tax Vendor Not Found.", 47 spaces, 
					" Tax Vendor = ", modu_rec_postwhtax.tax_vend_code 
					CALL errorlog(l_spaces) 
					CALL update_poststatus(NOT_OK,0,"AP") 
				END IF 
				UPDATE postwhtax 
				SET tax_tran_type = "1", 
				tax_ref_num = modu_rec_postwhtax.tax_ref_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tax_vend_code = modu_rec_postwhtax.tax_vend_code 
				AND pay_acct_code = modu_rec_postwhtax.pay_acct_code 
			END IF 
		END FOREACH 
--		IF NOT glob_one_trans THEN 
--			COMMIT WORK 
--			LET glob_in_trans = false 
--		END IF 
	END IF 

	#  WHEN complete, OUTPUT a cross-reference entry FOR each cheque detail
	LET glob_st_code = 19 
	LET glob_post_text = "Commenced wholdtax INSERT FROM postwhtax" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET l_doc_count = 0 
	IF modu_post_status != 20 THEN 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
			LET glob_in_trans = true 
		END IF 
		DECLARE c2_wtax CURSOR FOR 
			SELECT cmpy_code, 
			tax_vend_code, 
			tax_tran_type, 
			tax_ref_num, 
			payee_tran_type, 
			payee_vend_code, 
			payee_ref_num, 
			payee_bank_code, 
			pay_meth_ind 
			FROM postwhtax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_ref_num IS NOT NULL 

		FOREACH c2_wtax INTO modu_rec_wholdtax.cmpy_code, 
			modu_rec_wholdtax.tax_vend_code, 
			modu_rec_wholdtax.tax_tran_type, 
			modu_rec_wholdtax.tax_ref_num, 
			modu_rec_wholdtax.payee_tran_type, 
			modu_rec_wholdtax.payee_vend_code, 
			modu_rec_wholdtax.payee_ref_num, 
			modu_rec_wholdtax.payee_bank_code, 
			modu_rec_wholdtax.pay_meth_ind 
			INSERT INTO wholdtax VALUES (modu_rec_wholdtax.*) 
			LET l_doc_count = l_doc_count + 1 
		END FOREACH 

--		IF NOT glob_one_trans THEN 
---			COMMIT WORK 
--			LET glob_in_trans = false 
--		END IF 
	END IF 

	IF l_doc_count = 0 THEN 
		ERROR kandoomsg2("U",3501,"") 
		#3501 No rows found TO post
	END IF 

	#  Now DELETE FROM the posting table
	LET glob_st_code = 20 
	LET glob_post_text = "Commenced DELETE FROM postwhtax" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF NOT glob_one_trans THEN 
		BEGIN WORK 
		LET glob_in_trans = true 
	END IF 
	DELETE FROM postwhtax WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	IF NOT glob_one_trans THEN 
--		COMMIT WORK 
--		LET glob_in_trans = false 
--	END IF 

	LET glob_st_code = 99 
	LET glob_post_text = "Withhold Tax Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	RETURN 0
END FUNCTION  # post_wholdtax

############################################################
# FUNCTION post_cheque_amounts()
#
#
############################################################
FUNCTION post_cheque_amounts() 
	DEFINE l_credit_amt LIKE batchdetl.credit_amt 
	DEFINE l_currency_code LIKE batchhead.currency_code 
	DEFINE l_conv_qty LIKE batchhead.conv_qty 
	DEFINE l_msgresp LIKE language.yes_flag 

	GOTO bypass 
	LABEL recovery: 
	
	CALL update_poststatus(NOT_OK,STATUS,"AP") 
	
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	
	IF modu_post_status > 22 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_st_code = 21 
	LET glob_post_text = "Commenced cheque contra posting FROM postaptrans" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	MESSAGE kandoomsg2("P",3507,"") 
	#3507 Posting Contra Amounts
	#
	# Separate positive AND negative contra amounts INTO different
	# journal batches TO ensure correct multi-ledger postings,
	# starting with the positive VALUES
	#
	IF modu_post_status <= 21 OR modu_post_status = 99 THEN 
		LET glob_err_text = "Create GL batch - Contra cheque amounts (+ve)" 
		LET modu_rec_current.tran_type_ind = "CCO" 
		LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 
		LET modu_select_text = 
		"SELECT * FROM postaptrans ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND type_code = 'CCO' ", 
		"AND credit_amt > 0 " 
		#
		# Add a further selection criteria in CASE the batch was partly
		# created
		#
		IF modu_post_status = 21 THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"jour_num IS NULL OR jour_num = 0) " 
		END IF 

		PREPARE s1_postaptrans FROM modu_select_text 
		DECLARE c1_postaptrans CURSOR FOR s1_postaptrans 
		LET glob_err_text = "Posting positive Contras" 
		FOREACH c1_postaptrans INTO modu_rec_postaptrans.* 
			IF modu_rec_postaptrans.conv_qty IS NOT NULL THEN 
				IF modu_rec_postaptrans.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = 
					modu_rec_postaptrans.credit_amt / modu_rec_postaptrans.conv_qty 
				END IF 
			END IF 
			#
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			#
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_credit_amt = modu_rec_current.base_credit_amt 
				LET l_conv_qty = 1 
				LET l_currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET l_credit_amt = modu_rec_postaptrans.credit_amt 
				LET l_conv_qty = modu_rec_postaptrans.conv_qty 
				LET l_currency_code = modu_rec_postaptrans.currency_code 
			END IF 
			INSERT INTO posttemp VALUES 
			(modu_rec_postaptrans.ref_num, # cheque number 
			modu_rec_postaptrans.ref_code, # vendor code 
			modu_rec_postaptrans.post_acct_code, # contra clearing account 
			modu_rec_postaptrans.desc_text, # description 
			0, # zero FOR contra postings 
			l_credit_amt, # contra amt in batch curr. 
			0, # zero FOR contra postings 
			modu_rec_current.base_credit_amt, # converted contra amount 
			l_currency_code, # batch currency code 
			l_conv_qty, # batch exchange rate 
			modu_rec_postaptrans.tran_date, # cheque DATE 
			modu_rec_postaptrans.stats_qty, # defaulted TO 0 
			modu_rec_postaptrans.analysis_text, # defaulted TO NULL 
			modu_rec_postaptrans.bal_acct_code, # control account 
			modu_rec_postaptrans.doc_num) # unique doc num 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "CCO" 
		LET modu_rec_bal_rec.desc_text = " AP Contra Balancing Entry" 
		LET modu_rec_current.jour_code = glob_rec_apparms.chq_jour_code 

		IF modu_post_status = 21 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
		CALL create_gl_batches() 

		DELETE FROM posttemp WHERE 1 = 1 

		#
		# Insert posting data FOR the Cheque contra amounts negative VALUES
		#
		LET glob_err_text = "Create GL batch - Contra cheque amounts (-ve)" 
		LET modu_select_text = 
		"SELECT * FROM postaptrans ", 
		"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND type_code = 'CCO' ", 
		"AND credit_amt < 0 " 
		#
		# Add a further selection criteria in CASE the batch was partly
		# created
		#
		IF modu_post_status = 21 THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"jour_num IS NULL OR jour_num = 0) " 
		END IF 

		PREPARE s2_postaptrans FROM modu_select_text 
		DECLARE c2_postaptrans CURSOR FOR s2_postaptrans 
		LET glob_err_text = "Posting negative Contras" 
		FOREACH c2_postaptrans INTO modu_rec_postaptrans.* 
			IF modu_rec_postaptrans.conv_qty IS NOT NULL THEN 
				IF modu_rec_postaptrans.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = 
					modu_rec_postaptrans.credit_amt / modu_rec_postaptrans.conv_qty 
				END IF 
			END IF 
			#
			# IF use_currency_flag IS 'N' THEN any source documents in foreign
			# currency need TO be converted TO base, AND a base batch created.
			#
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET l_credit_amt = modu_rec_current.base_credit_amt 
				LET l_conv_qty = 1 
				LET l_currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET l_credit_amt = modu_rec_postaptrans.credit_amt 
				LET l_conv_qty = modu_rec_postaptrans.conv_qty 
				LET l_currency_code = modu_rec_postaptrans.currency_code 
			END IF 

			INSERT INTO posttemp VALUES 
			(modu_rec_postaptrans.ref_num, # cheque number 
			modu_rec_postaptrans.ref_code, # vendor code 
			modu_rec_postaptrans.post_acct_code, # contra clearing account 
			modu_rec_postaptrans.desc_text, # description 
			0, # zero FOR contra postings 
			l_credit_amt, # contra amt in batch curr. 
			0, # zero FOR contra postings 
			modu_rec_current.base_credit_amt, # converted contra amount 
			l_currency_code, # batch currency code 
			l_conv_qty, # batch exchange rate 
			modu_rec_postaptrans.tran_date, # cheque DATE 
			modu_rec_postaptrans.stats_qty, # defaulted TO 0 
			modu_rec_postaptrans.analysis_text, # defaulted TO NULL 
			modu_rec_postaptrans.bal_acct_code, # control account 
			modu_rec_postaptrans.doc_num) # unique doc num 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "CCO" 
		LET modu_rec_bal_rec.desc_text = " AP Contra Balancing Entry" 
		LET modu_rec_current.jour_code = glob_rec_apparms.chq_jour_code 

		IF modu_post_status = 21 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 
		CALL create_gl_batches() 
	END IF 

	LET glob_st_code = 22 
	LET glob_post_text = "Commenced DELETE FROM postaptrans" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postaptrans" 
	IF NOT glob_one_trans THEN 
		BEGIN WORK 
		LET glob_in_trans = true 
	END IF 
	IF glob_rec_poststatus.online_ind != "L" THEN 
		LOCK TABLE postaptrans in share MODE 
	END IF 
	DELETE FROM postaptrans WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF NOT glob_one_trans THEN 
		COMMIT WORK 
		LET glob_in_trans = false 
	END IF 

	LET glob_st_code = 99 
	LET glob_post_text = "Contra Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 
END FUNCTION  # post_cheque_amounts



############################################################
# FUNCTION PP1_post_AP(p_object,p_period_num,p_year_num)
#
#
############################################################
FUNCTION PP1_post_AP(p_object,p_period_num,p_year_num) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE p_object CHAR(10)
	DEFINE p_period_num LIKE voucher.period_num
	DEFINE p_year_num LIKE voucher.year_num

	DEFINE l_rec_journal RECORD LIKE journal.* 
	DEFINE l_err_message STRING 
	DEFINE l_operation_status INTEGER
	DEFINE l_jour_num LIKE batchhead.jour_num

--	CALL upd_rms(glob_rec_kandoouser.cmpy_code, 
--	glob_rec_kandoouser.sign_on_code, 
--	glob_rec_kandoouser.security_ind, 
--	glob_rec_rmsreps.report_width_num, 
--	"PP1", 
--	"AP Posting Report") 
--	RETURNING modu_rpt_output 

	#------------------------------------------------------------
	#rmsreps entries
	LET glob_rec_rpt_selector.sel_text = modu_sel_text
	LET glob_rec_rpt_selector.ref1_num = glob_fisc_period
	LET glob_rec_rpt_selector.ref2_num = glob_fisc_year
	
	LET glob_rec_rpt_selector.ref1_code = modu_rec_current.jour_code
	LET glob_rec_rpt_selector.ref2_code = modu_rec_current.currency_code
	LET glob_rec_rpt_selector.ref3_code = modu_rec_bal_rec.acct_code
	LET glob_rec_rpt_selector.ref4_code = modu_rec_bal_rec.tran_type_ind #LIKE batchdetl.tran_type_ind #nchar(3)

	LET glob_rec_rpt_selector.ref2_text = modu_rec_bal_rec.desc_text #LIKE batchdetl.desc_text
				
	LET glob_rec_rpt_selector.ref1_amt = modu_sl_id
	#------------------------------------------------------------
	LET modu_rpt_idx = rpt_start(getmoduleid(),"COM_jourintf_rpt_list_bd",modu_sel_text, RPT_SHOW_RMS_DIALOG)
	IF modu_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT COM_jourintf_rpt_list_bd TO rpt_get_report_file_with_path2(1)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].page_length_num ,
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].top_margin,
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].bottom_margin,
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].left_margin,
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[modu_rpt_idx].report_width_num

	#------------------------------------------------------------

	# IF this IS a properly configured online site (ie correct # locks)
	# THEN they may still wish TO run one big transaction.
	# ericv => IDS is correctly configured so yes, transaction ( see if eventually 1 transaction per period)
	LET glob_one_trans = TRUE  #  No way we continue without transaction 
	--IF glob_rec_poststatus.online_ind = "Y" OR 
	--glob_rec_poststatus.online_ind = "L" THEN 
	

	# see if we keep that in the future...
	--UPDATE poststatus		# set post as running 
	--SET post_running_flag = "Y" 
	--WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	--AND module_code = "AP" 
 

	# All the rows read will hold a shared lock, preventing anyone to change those rows
	# start transaction here: one post num per object (voucher, cheque etc)
	BEGIN WORK
	SET ISOLATION TO REPEATABLE READ
	SET LOCK MODE TO WAIT 5

--		START REPORT rpt_list_bdt TO modu_rpt_output 
	IF glob_rec_apparms.gl_flag = "Y" THEN 
		SELECT * INTO l_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_apparms.pur_jour_code 
		
		IF sqlca.sqlcode = NOTFOUND THEN 
			# 3521 "Purchases Journal NOT found"
			ERROR kandoomsg2("P",3521,"") 
			RETURN 
		END IF 

		SELECT * INTO l_rec_journal.* 
		FROM journal 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jour_code = glob_rec_apparms.chq_jour_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			# 3522 " Cash Payments Journal NOT found "
			ERROR kandoomsg2("P",3522,"") 
			RETURN 
		END IF 
	END IF 

	LET glob_rec_apparms.last_post_date = today 
	LET l_err_message = " Parameter table UPDATE " 
	
	# get last post_run_num from glparms ( REPEATABLE keeps is impossible to modify by another session)
	LET glob_rec_glparms.next_post_num = get_next_incremented_value ("GL","next_post_num","REPEATABLE")
	INITIALIZE modu_rec_postrun.* TO NULL
	WHENEVER SQLERROR CONTINUE
	--SELECT *
	--INTO glob_rec_glparms.* 
	--FROM glparms
	--WHERE cmpy_code = glob_rec_company.cmpy_code 
	--	AND glparms.key_code = "1" 
	IF sqlca.sqlcode < 0 THEN
		CALL fgl_winmessage("Post vouchers","Other posting task is pending, please retry later", "info") 
		ROLLBACK WORK
	END IF

	# Then get last end_total_amt that will be start_total_amt for the new postrun record
	SELECT end_total_amt 
	INTO modu_rec_postrun.start_total_amt
	FROM postrun
	WHERE cmpy_code = glob_rec_company.cmpy_code 
		AND post_run_num = glob_rec_glparms.next_post_num
	CASE
		WHEN sqlca.sqlcode < 0
			CALL fgl_winmessage("Post vouchers","Other posting task is pending, please retry later", "info") 
			ROLLBACK WORK
			RETURN FALSE
		WHEN sqlca.sqlcode = NOTFOUND
			ERROR "postrun and glparams are out of sync"
			ROLLBACK WORK
			RETURN FALSE
	END CASE	

	# UPDATE glparms replaced by set_next_incremented_value (ericv)
	# Then SET  new value for next_post_num
	LET glob_rec_glparms.next_post_num = set_next_incremented_value ("GL","next_post_num")
	IF glob_rec_glparms.next_post_num < 0 THEN
		CALL fgl_winmessage("Post vouchers","Other posting task is pending, please retry later", "info") 
		ROLLBACK WORK
	END IF

	LET modu_rec_postrun.cmpy_code = glob_rec_glparms.cmpy_code
	LET modu_rec_postrun.post_run_num = glob_rec_glparms.next_post_num
	LET modu_rec_postrun.post_date  = today
	LET modu_rec_postrun.post_by_text = glob_rec_kandoouser.sign_on_code
	INSERT INTO postrun VALUES (modu_rec_postrun.*)
	MESSAGE l_err_message 
	# FIXME: transaction should begin here ....

# TODO: do this on last row
	--	UPDATE apparms 
--	SET last_post_date = glob_rec_apparms.last_post_date 
--	WHERE parm_code = "1" 
--	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF glob_rec_apparms.gl_flag = "Y" THEN 
		LET modu_flag_cheques = false 
		CASE
			WHEN p_object = "Vouchers"
				CALL post_vouchers(p_period_num,p_year_num) RETURNING l_operation_status,l_jour_num
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "Vouchers posted successfully"

				ELSE
					ROLLBACK WORK
					ERROR "Vouchers posted WITH ERRORS, please check"
					RETURN 1
				END IF

			WHEN p_object = "Debits"
				CALL post_debithead() RETURNING l_operation_status
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "Debits posted successfully"
				ELSE
					ROLLBACK WORK
					ERROR "Debits posted WITH ERRORS, please check"
					RETURN 2
				END IF

			WHEN p_object = "Cheques"
				CALL post_cheques(p_period_num,p_year_num) RETURNING l_operation_status,l_jour_num
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "Cheques posted successfully"
				ELSE
					ROLLBACK WORK
					ERROR "Cheques posted WITH ERRORS, please check"
					RETURN 3
				END IF

			WHEN p_object = "ExchangeVar"
				CALL post_exchangevar() RETURNING l_operation_status
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "ExchangeVar posted successfully"
				ELSE
					ROLLBACK WORK
					ERROR "ExchangeVar posted WITH ERRORS, please check"
					RETURN 4
				END IF

			WHEN p_object = "WitholdTax"
				CALL post_wholdtax() RETURNING l_operation_status
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "WitholdTax posted successfully"
				ELSE
					ROLLBACK WORK
					ERROR "WitholdTax posted WITH ERRORS, please check"
					RETURN 5
				END IF

			WHEN p_object = "ChequeAmounts"
				CALL post_cheque_amounts() RETURNING l_operation_status
				IF l_operation_status = 0 THEN
					COMMIT WORK
					ERROR "ChequeAmounts posted successfully"
				ELSE
					ROLLBACK WORK
					ERROR "ChequeAmounts posted WITH ERRORS, please check"
					RETURN 6
				END IF
		END CASE
	ELSE 
		# UPDATE all documents as posted (so as TO flag that history
		# IS complete)
		CALL flag_all_tables_as_posted() 
	END IF 

	#------------------------------------------------------------

	CALL do_report_for_journal(modu_rpt_idx,glob_rec_apparms.pur_jour_code ,l_jour_num)
	FINISH REPORT COM_jourintf_rpt_list_bd
	CALL rpt_finish("COM_jourintf_rpt_list_bd")
	#------------------------------------------------------------
	RETURN 0

END FUNCTION  # PP1_post_AP

# THis function is a specific function to handle posting errors, called by whenever sqlerror
FUNCTION kandoo_handle_post_errors()
	IF sqlca.sqlcode < 0 THEN   # watch out: sqlerror can also mean error on some 4gl statements
		LET glob_error_msg = sqlerrmessage
		ERROR glob_err_text,"Problem: Rollback Post"
		ROLLBACK WORK
		CALL update_poststatus(NOT_OK,STATUS,"AP")
	END IF
END FUNCTION # kandoo_handle_post_errors()

### Report functions used to calculate batches etc ... replace the so complex and slow original functions (jourintf)
# this report replaces jourintf2 and consecutive updates and inserts ericv 20210210
REPORT rep_post_voucher_batch(p_rec_voucher_basic,p_rec_current,p_rec_vouchedist_detldata,p_account_type)
	DEFINE p_cmpy_code LIKE voucher.cmpy_code
	DEFINE p_rec_current t_rec_current
	DEFINE p_rec_voucher_basic t_rec_voucher_basic
	DEFINE p_rec_vouchedist_detldata t_rec_vouchedist_detldata 
	DEFINE p_account_type LIKE coa.type_ind     # type of the account (in ALIEN) we sum up Expenses for vendorhist
	DEFINE l_vend_text LIKE vendor.name_text
	DEFINE l_acct_code LIKE coa.acct_code
	DEFINE l_jour_num LIKE batchhead.jour_num
	DEFINE l_group_debit_total,l_group_credit_total LIKE batchdetl.debit_amt
	DEFINE l_new_vouchers_count INTEGER
	DEFINE l_new_vouchers_amount_sum LIKE batchdetl.debit_amt
	DEFINE l_post_flag LIKE voucher.post_flag
	DEFINE l_post_date LIKE voucher.post_date
	DEFINE l_group_for_debit_total,l_group_for_credit_total LIKE batchdetl.for_debit_amt
	DEFINE l_next_post_num LIKE glparms.next_post_num
	DEFINE l_start_total_amt LIKE postrun.start_total_amt
	DEFINE l_previous_end_total_amt LIKE postrun.start_total_amt
	DEFINE l_vendor_expenses_sum LIKE batchdetl.debit_amt
--	DEFINE modu_rec_postrun RECORD like postrun.*

	DEFINE l_operation_status INTEGER
	DEFINE l_seq_num SMALLINT
	DEFINE a CHAR(1)

	OUTPUT 
	left margin 0 
	ORDER BY EXTERNAL p_rec_voucher_basic.currency_code,p_rec_current.vend_type,p_rec_voucher_basic.ref_text,p_rec_voucher_basic.ref_num

	FORMAT 
	FIRST PAGE HEADER 

	BEFORE GROUP OF p_rec_voucher_basic.currency_code
		# increment next journal num by 1 for each currency
		UPDATE glparms 
		SET next_jour_num = next_jour_num + 1 
		WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 

		SELECT next_jour_num INTO l_jour_num
		FROM glparms
		WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 

		CALL create_batchhead_entry(glob_fisc_period,glob_fisc_year,p_rec_current.jour_code,l_jour_num,"P",p_rec_voucher_basic.currency_code,modu_rec_postrun.post_run_num,"AP")
		LET mdl_report_num = mdl_report_num + 1
		LET mod_arr_rec_reports_to_print[mdl_report_num].jour_code=p_rec_current.jour_code
		LET mod_arr_rec_reports_to_print[mdl_report_num].jour_num=l_jour_num
		LET a="a"

	BEFORE GROUP OF p_rec_current.vend_type
		# determine the posting control accounts FOR this vendor type,
		# IF new vendor 
		CALL get_vendortype_accounts(p_rec_current.vend_type) 
		RETURNING p_rec_current.pay_acct_code,p_rec_current.disc_acct_code,p_rec_current.exch_acct_code,p_rec_current.tax_vend_code
		# Reset modu_rec_current just in case
		LET modu_rec_current.* = p_rec_current.*
		LET a="a"

	BEFORE GROUP OF p_rec_voucher_basic.ref_text     #i.e before group of vendor
		SELECT name_text INTO l_vend_text 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				vend_code = p_rec_voucher_basic.ref_text     # in fact, this is the vendor code ...
		# Reinitialize number of vouchers and total of expenses for this vendor 
		LET l_new_vouchers_count = 0 
		LET l_vendor_expenses_sum = 0

	BEFORE GROUP OF p_rec_voucher_basic.ref_num		# i.e before group of voucher num
		LET a="a"

	ON EVERY ROW 
		# each row of vouchdetail only contains the credit part of the entry, the credit part will be inserted after group with aggregate sum of debits
		LET p_rec_vouchedist_detldata.desc_text = 'Voucher # ',p_rec_voucher_basic.ref_num," " ,p_rec_voucher_basic.ref_text
		CALL prp_insert_posttemp.Execute(
			p_rec_voucher_basic.ref_num, # voucher number 
			p_rec_voucher_basic.ref_text, # vendor code 
			p_rec_vouchedist_detldata.post_acct_code, # voucher dist account 
			p_rec_vouchedist_detldata.desc_text, # voucher dist desc 
			p_rec_vouchedist_detldata.debit_amt, # voucher dist amount 
			p_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
			p_rec_current.base_debit_amt, # converted debit amount 
			p_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
			p_rec_voucher_basic.currency_code, # voucher currency code 
			p_rec_voucher_basic.conv_qty, # voucher curr conversion 
			p_rec_voucher_basic.tran_date, # voucher DATE 
			p_rec_vouchedist_detldata.stats_qty, # distribution qty 
			p_rec_vouchedist_detldata.analysis_text, # analysis text 
			p_rec_current.pay_acct_code # control account 
			) 
		LET l_seq_num = l_seq_num + 1
		CALL create_batchdetl_entry(p_rec_current.jour_code,l_jour_num,l_seq_num,"VO",p_rec_voucher_basic.*,p_rec_vouchedist_detldata.*)
		RETURNING l_operation_status
		IF p_account_type = "E"  THEN   # we sum up Expenses accounts (ALIEN)
			LET l_vendor_expenses_sum = l_vendor_expenses_sum + p_rec_vouchedist_detldata.debit_amt
		END IF
		LET a="a"

	AFTER GROUP OF p_rec_voucher_basic.ref_num		#i.e after group of voucher number
		IF modu_option_control_entry_per_voucher = TRUE THEN      # create on ctrl account entry per voucher
			LET p_rec_vouchedist_detldata.desc_text = 'Voucher # ',p_rec_voucher_basic.ref_num," " ,p_rec_voucher_basic.ref_text
			LET p_rec_vouchedist_detldata.debit_amt = 0
			LET p_rec_vouchedist_detldata.credit_amt = GROUP SUM (p_rec_vouchedist_detldata.debit_amt)
			LET p_rec_vouchedist_detldata.post_acct_code = p_rec_current.pay_acct_code
			LET l_seq_num = l_seq_num + 1
			# create balancing entry for this voucher
			CALL create_batchdetl_entry(p_rec_current.jour_code,l_jour_num,l_seq_num,"VO",p_rec_voucher_basic.*,p_rec_vouchedist_detldata.*)
			RETURNING l_operation_status
			LET l_post_flag = "Y"
			LET l_post_date = today
			CALL prp_update_voucher_journum_postdate.Execute(l_jour_num,l_post_date,glob_rec_kandoouser.cmpy_code,p_rec_voucher_basic.ref_num)
		END IF
		LET l_new_vouchers_count = l_new_vouchers_count + 1
		LET a = "a"

	AFTER GROUP OF p_rec_voucher_basic.ref_text     #i.e after group of vendor
		# update vendor's history for this period
		LET l_new_vouchers_amount_sum = l_vendor_expenses_sum 
		CALL prp_update_vendorhist_purchase.Execute(l_new_vouchers_count,l_vendor_expenses_sum,glob_rec_kandoouser.cmpy_code,p_rec_voucher_basic.ref_text,glob_fisc_period,glob_fisc_year)	

	AFTER GROUP OF p_rec_current.vend_type		
		LET a = "a"

	AFTER GROUP OF p_rec_voucher_basic.currency_code		
		# get sum of debit_amt,credit_amt,for_debit_amt and for_credit amt from batchdetl rather than voucher data (no credit until the balancing entry is written in batchdetl)
		SELECT sum(debit_amt),sum(credit_amt),sum(for_debit_amt),sum(for_credit_amt)
		INTO l_group_debit_total,l_group_credit_total,l_group_for_debit_total,l_group_for_credit_total
		FROM batchdetl
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND jour_code = p_rec_current.jour_code
			AND jour_num = l_jour_num
		
		CALL prp_update_batchhead.Execute (
			l_group_credit_total,
			l_group_debit_total,
			l_group_for_debit_total,
			l_group_for_credit_total,
			glob_rec_kandoouser.cmpy_code,
			p_rec_current.jour_code,
			l_jour_num
		)
		LET a = "a"

		ON LAST ROW 
			# Create postrun entry
			LET modu_rec_postrun.post_amt = SUM(p_rec_vouchedist_detldata.debit_amt)
         	LET modu_rec_postrun.end_total_amt   =  modu_rec_postrun.start_total_amt + modu_rec_postrun.post_amt
			UPDATE postrun
			SET post_amt = modu_rec_postrun.post_amt,
			end_total_amt = modu_rec_postrun.end_total_amt
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				AND post_run_num = modu_rec_postrun.post_run_num

			NEED 3 LINES 
			SKIP 2 LINES 

			
END REPORT  # rep_post_voucher_batch

REPORT rep_post_cheques_batch(p_rec_voucher_basic,p_rec_current,p_rec_vouchedist_detldata,p_account_type)
	DEFINE p_cmpy_code LIKE voucher.cmpy_code
	DEFINE p_rec_current t_rec_current
	DEFINE p_rec_voucher_basic t_rec_voucher_basic
	DEFINE p_rec_vouchedist_detldata t_rec_vouchedist_detldata 
	DEFINE p_account_type LIKE coa.type_ind     # type of the account (in ALIEN) we sum up Expenses for vendorhist
	DEFINE l_vend_text LIKE vendor.name_text
	DEFINE l_acct_code LIKE coa.acct_code
	DEFINE l_jour_num LIKE batchhead.jour_num
	DEFINE l_group_debit_total,l_group_credit_total LIKE batchdetl.debit_amt
	DEFINE l_new_vouchers_count INTEGER
	DEFINE l_new_vouchers_amount_sum LIKE batchdetl.debit_amt
	DEFINE l_post_flag LIKE voucher.post_flag
	DEFINE l_post_date LIKE voucher.post_date
	DEFINE l_group_for_debit_total,l_group_for_credit_total LIKE batchdetl.for_debit_amt
	DEFINE l_next_post_num LIKE glparms.next_post_num
	DEFINE l_start_total_amt LIKE postrun.start_total_amt
	DEFINE l_previous_end_total_amt LIKE postrun.start_total_amt
	DEFINE l_vendor_expenses_sum LIKE batchdetl.debit_amt
--	DEFINE modu_rec_postrun RECORD like postrun.*

	DEFINE l_operation_status INTEGER
	DEFINE l_seq_num SMALLINT
	DEFINE a CHAR(1)

	OUTPUT 
	left margin 0 
	ORDER BY EXTERNAL p_rec_voucher_basic.currency_code,p_rec_current.vend_type,p_rec_voucher_basic.ref_text,p_rec_voucher_basic.ref_num

	FORMAT 
	FIRST PAGE HEADER 

	BEFORE GROUP OF p_rec_voucher_basic.currency_code
		# increment next journal num by 1 for each currency
		UPDATE glparms 
		SET next_jour_num = next_jour_num + 1 
		WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 

		SELECT next_jour_num INTO l_jour_num
		FROM glparms
		WHERE glparms.cmpy_code = glob_rec_company.cmpy_code 
			AND glparms.key_code = "1" 

		CALL create_batchhead_entry(glob_fisc_period,glob_fisc_year,p_rec_current.jour_code,l_jour_num,"P",p_rec_voucher_basic.currency_code,modu_rec_postrun.post_run_num,"AP")
		LET mdl_report_num = mdl_report_num + 1
		LET mod_arr_rec_reports_to_print[mdl_report_num].jour_code=p_rec_current.jour_code
		LET mod_arr_rec_reports_to_print[mdl_report_num].jour_num=l_jour_num
		LET a="a"

	BEFORE GROUP OF p_rec_current.vend_type
		# determine the posting control accounts FOR this vendor type,
		# IF new vendor 
		CALL get_vendortype_accounts(p_rec_current.vend_type) 
		RETURNING p_rec_current.pay_acct_code,p_rec_current.disc_acct_code,p_rec_current.exch_acct_code,p_rec_current.tax_vend_code
		# Reset modu_rec_current just in case
		LET modu_rec_current.* = p_rec_current.*
		LET a="a"

	BEFORE GROUP OF p_rec_voucher_basic.ref_text     #i.e before group of vendor
		SELECT name_text INTO l_vend_text 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				vend_code = p_rec_voucher_basic.ref_text     # in fact, this is the vendor code ...
		# Reinitialize number of vouchers and total of expenses for this vendor 
		LET l_new_vouchers_count = 0 
		LET l_vendor_expenses_sum = 0

	BEFORE GROUP OF p_rec_voucher_basic.ref_num		# i.e before group of voucher num
		LET a="a"

	ON EVERY ROW 
		# each row of vouchdetail only contains the credit part of the entry, the credit part will be inserted after group with aggregate sum of debits
		LET p_rec_vouchedist_detldata.desc_text = 'Voucher # ',p_rec_voucher_basic.ref_num," " ,p_rec_voucher_basic.ref_text
		CALL prp_insert_posttemp.Execute(
			p_rec_voucher_basic.ref_num, # voucher number 
			p_rec_voucher_basic.ref_text, # vendor code 
			p_rec_vouchedist_detldata.post_acct_code, # voucher dist account 
			p_rec_vouchedist_detldata.desc_text, # voucher dist desc 
			p_rec_vouchedist_detldata.debit_amt, # voucher dist amount 
			p_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
			p_rec_current.base_debit_amt, # converted debit amount 
			p_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
			p_rec_voucher_basic.currency_code, # voucher currency code 
			p_rec_voucher_basic.conv_qty, # voucher curr conversion 
			p_rec_voucher_basic.tran_date, # voucher DATE 
			p_rec_vouchedist_detldata.stats_qty, # distribution qty 
			p_rec_vouchedist_detldata.analysis_text, # analysis text 
			p_rec_current.pay_acct_code # control account 
			) 
		LET l_seq_num = l_seq_num + 1
		CALL create_batchdetl_entry(p_rec_current.jour_code,l_jour_num,l_seq_num,"VO",p_rec_voucher_basic.*,p_rec_vouchedist_detldata.*)
		RETURNING l_operation_status
		IF p_account_type = "E"  THEN   # we sum up Expenses accounts (ALIEN)
			LET l_vendor_expenses_sum = l_vendor_expenses_sum + p_rec_vouchedist_detldata.debit_amt
		END IF
		LET a="a"

	AFTER GROUP OF p_rec_voucher_basic.ref_num		#i.e after group of voucher number
		IF modu_option_control_entry_per_voucher = TRUE THEN      # create on ctrl account entry per voucher
			LET p_rec_vouchedist_detldata.desc_text = 'Voucher # ',p_rec_voucher_basic.ref_num," " ,p_rec_voucher_basic.ref_text
			LET p_rec_vouchedist_detldata.debit_amt = 0
			LET p_rec_vouchedist_detldata.credit_amt = GROUP SUM (p_rec_vouchedist_detldata.debit_amt)
			LET p_rec_vouchedist_detldata.post_acct_code = p_rec_current.pay_acct_code
			LET l_seq_num = l_seq_num + 1
			# create balancing entry for this voucher
			CALL create_batchdetl_entry(p_rec_current.jour_code,l_jour_num,l_seq_num,"VO",p_rec_voucher_basic.*,p_rec_vouchedist_detldata.*)
			RETURNING l_operation_status
			LET l_post_flag = "Y"
			LET l_post_date = today
			CALL prp_update_voucher_journum_postdate.Execute(l_jour_num,l_post_date,glob_rec_kandoouser.cmpy_code,p_rec_voucher_basic.ref_num)
		END IF
		LET l_new_vouchers_count = l_new_vouchers_count + 1
		LET a = "a"

	AFTER GROUP OF p_rec_voucher_basic.ref_text     #i.e after group of vendor
		# update vendor's history for this period
		LET l_new_vouchers_amount_sum = l_vendor_expenses_sum 
		CALL prp_update_vendorhist_purchase.Execute(l_new_vouchers_count,l_vendor_expenses_sum,glob_rec_kandoouser.cmpy_code,p_rec_voucher_basic.ref_text,glob_fisc_period,glob_fisc_year)	

	AFTER GROUP OF p_rec_current.vend_type		
		LET a = "a"

	AFTER GROUP OF p_rec_voucher_basic.currency_code		
		# get sum of debit_amt,credit_amt,for_debit_amt and for_credit amt from batchdetl rather than voucher data (no credit until the balancing entry is written in batchdetl)
		SELECT sum(debit_amt),sum(credit_amt),sum(for_debit_amt),sum(for_credit_amt)
		INTO l_group_debit_total,l_group_credit_total,l_group_for_debit_total,l_group_for_credit_total
		FROM batchdetl
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
			AND jour_code = p_rec_current.jour_code
			AND jour_num = l_jour_num
		
		CALL prp_update_batchhead.Execute (
			l_group_credit_total,
			l_group_debit_total,
			l_group_for_debit_total,
			l_group_for_credit_total,
			glob_rec_kandoouser.cmpy_code,
			p_rec_current.jour_code,
			l_jour_num
		)
		LET a = "a"

		ON LAST ROW 
			# Create postrun entry
			LET modu_rec_postrun.post_amt = SUM(p_rec_vouchedist_detldata.debit_amt)
         	LET modu_rec_postrun.end_total_amt   =  modu_rec_postrun.start_total_amt + modu_rec_postrun.post_amt
			UPDATE postrun
			SET post_amt = modu_rec_postrun.post_amt,
			end_total_amt = modu_rec_postrun.end_total_amt
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
				AND post_run_num = modu_rec_postrun.post_run_num

			NEED 3 LINES 
			SKIP 2 LINES 

			
END REPORT  # rep_post_cheques_batch

# deprecated functions
-----------------------------------------------------------------------------------------------------------
FUNCTION post_vouchers_old() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 

	--GOTO bypass 
	--LABEL recovery: 

	-- CALL update_poststatus(NOT_OK,STATUS,"AP") 
	# Sorry, but this function is called with "always had an error" status and stops the program
	# I think poststatus will not be necessary or at least less intensively used as we use transactions
	# Base rule: a post is always good and complete, or must be done from scratch, no in between status .... 

	--LABEL bypass: 
	--WHENEVER ERROR GOTO recovery 

	# IF an error has occurred AND it was NOT in this part of the
	# post THEN walk on by ...
	IF modu_post_status > 4 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 

	LET glob_err_text = "Commenced voucher post" 

	# ericv there will be no error, so we flag the next block
	{
		IF modu_post_status = 1 THEN # error in voucher post
		#FIXME: a voucher in error should simply not be committed
		# 3517 "Rolling back postvoucher AND voucher tables"
		ERROR kandoomsg2("P",3517,"") 
		SLEEP 2 
		LET glob_err_text = "Reversing previous vouchers" 

		IF NOT glob_one_trans THEN 
			BEGIN WORK 
			LET glob_in_trans = true 
		END IF 

		IF glob_rec_poststatus.online_ind != "L" THEN 
			LOCK TABLE postvoucher in share MODE 
			LOCK TABLE voucher in share MODE 
		END IF 

		LET glob_in_trans = true 
		DECLARE vouch_undo CURSOR FOR 
			SELECT vouch_code 
			FROM postvoucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

		FOREACH vouch_undo INTO modu_vouch_code 

			UPDATE voucher SET post_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = modu_vouch_code 

			DELETE FROM postvoucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = modu_vouch_code 

		END FOREACH 
		IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END IF 
	} # end of block flag

	LET glob_st_code = 1 
	LET glob_post_text = "Commenced INSERT TO postvoucher" 

	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status = 1 OR modu_post_status = 99 THEN 
		# SELECT the vouchers FOR posting AND INSERT them INTO the postvoucher
		# table THEN UPDATE them as posted so they won't be touched by anyone
		# ELSE

		SELECT unique 1 
		FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = glob_fisc_year 
		AND period_num = glob_fisc_period 
		AND post_flag = "N" 
		AND total_amt != dist_amt 

		IF STATUS != NOTFOUND THEN 
			ERROR kandoomsg2("P",6000,"") 
			# 6000 " Vouchers exists that are NOT fully distibuted
			#    --    DISPLAY on first line FOR 3 seconds   --
		END IF 

		LET glob_err_text = "Voucher SELECT FOR INSERT" 
		DECLARE voucher_curs CURSOR with HOLD FOR 
		SELECT vouch_code 
		FROM voucher 
		#        WHERE  voucher.cmpy_code  = glob_rec_kandoouser.cmpy_code
		WHERE @cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND voucher.post_flag = "N" 
		AND voucher.approved_code = "Y" 
		AND voucher.total_amt = voucher.dist_amt 
		AND voucher.period_num = glob_fisc_period 
		AND voucher.year_num = glob_fisc_year 

		LET glob_err_text = "Voucher FOREACH FOR INSERT" 
		FOREACH voucher_curs INTO modu_vouch_code 
			LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 
			WHILE (true) 
				IF NOT glob_one_trans THEN 
					BEGIN WORK 
						LET glob_in_trans = true 
					END IF 

					WHENEVER ERROR CONTINUE 

					DECLARE insert_curs CURSOR FOR 
						SELECT * 
						FROM voucher 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vouch_code = modu_vouch_code 
						FOR UPDATE 

					LET glob_err_text = "Voucher lock FOR INSERT" 

					OPEN insert_curs 
					FETCH insert_curs INTO l_rec_voucher.* 

					LET modu_stat_code = status 
					IF modu_stat_code THEN 
						IF modu_stat_code = NOTFOUND THEN 
							IF NOT glob_one_trans THEN 
							COMMIT WORK 
							LET glob_in_trans = false 
						END IF 
						CONTINUE FOREACH 
					END IF 

					LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,modu_stat_code) 
					IF modu_set_retry <= 0 THEN 
						# one transaction users cannot retry since
						# we cannot resurrect the transaction which
						# has been rolled back
						IF NOT glob_one_trans THEN 
							LET modu_try_again = error_recover("Voucher INSERT",modu_stat_code) 
							IF modu_try_again != "Y" THEN 
								LET glob_in_trans = false 
								CALL update_poststatus(NOT_OK,modu_stat_code,"AP") 
							ELSE 
								ROLLBACK WORK 
								CONTINUE WHILE 
							END IF 
						ELSE 
							CALL update_poststatus(NOT_OK,modu_stat_code,"AP") 
						END IF 
					ELSE 
						IF NOT glob_one_trans THEN 
						COMMIT WORK 
						LET glob_in_trans = false 
					END IF 
					CONTINUE WHILE 
				END IF 
			END IF 
			EXIT WHILE 
		END WHILE 
		LET modu_set_retry = retry_lock(glob_rec_kandoouser.cmpy_code,0) 

		WHENEVER ERROR GOTO recovery 

		LET glob_err_text = "PP1 - Insert INTO postvoucher" 
		CALL prp_insert_postvoucher.Execute(l_rec_voucher.*)

		LET glob_err_text = "PP1 - Voucher post flag SET" 
		UPDATE voucher SET post_flag = "Y" 
		WHERE CURRENT OF insert_curs 

		LET glob_err_text = "PP1 - Jobledger post flag SET " 
		UPDATE jobledger SET posted_flag = "N" 
		WHERE jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND jobledger.posted_flag = "P" 
		AND jobledger.year_num = glob_fisc_year 
		AND jobledger.period_num = glob_fisc_period 

END FOREACH 
END IF 

LET glob_err_text = "Create gl batch - voucher" 
LET glob_st_code = 2 
LET glob_post_text = "Completed INSERT TO postvoucher" 
CALL update_poststatus(ALL_OK,0,"AP") 

IF modu_post_status <= 2 OR modu_post_status = 99 THEN 

LET modu_prev_vend_type = "z" 
LET modu_rec_current.tran_type_ind = "VO" 
LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 
LET modu_rec_current.base_credit_amt = 0 

# FIXME: complex machinery just because there is no referential integrity.....

IF modu_post_status = 2 THEN {crapped out in gl insert} 
	LET modu_select_text = 
	"SELECT postvoucher.cmpy_code, ", 
	" postvoucher.vouch_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_date, ", 
	" postvoucher.currency_code, ", 
	" postvoucher.conv_qty, ", 
	" vendor.type_code ", 
	"FROM postvoucher, vendor ", 
	"WHERE postvoucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND postvoucher.post_flag != 'Y' ", 
	"AND postvoucher.year_num = ",glob_fisc_year," ", 
	"AND postvoucher.period_num = ",glob_fisc_period," ", 
	"AND postvoucher.total_amt = postvoucher.dist_amt ", 
	"AND postvoucher.cmpy_code = vendor.cmpy_code ", 
	"AND postvoucher.vend_code = vendor.vend_code ", 
	"AND (postvoucher.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
	" postvoucher.jour_num IS NULL OR ", 
	" postvoucher.jour_num = 0) ", 
	"ORDER BY postvoucher.cmpy_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_code " 
ELSE {normal post} 
	LET modu_select_text = 
	"SELECT postvoucher.cmpy_code, ", 
	" postvoucher.vouch_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_date, ", 
	" postvoucher.currency_code, ", 
	" postvoucher.conv_qty, ", 
	" vendor.type_code ", 
	"FROM postvoucher, vendor ", 
	"WHERE postvoucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND postvoucher.post_flag != 'Y' ", 
	"AND postvoucher.year_num = ",glob_fisc_year," ", 
	"AND postvoucher.period_num = ",glob_fisc_period," ", 
	"AND postvoucher.total_amt = postvoucher.dist_amt ", 
	"AND postvoucher.cmpy_code = vendor.cmpy_code ", 
	"AND postvoucher.vend_code = vendor.vend_code ", 
	"ORDER BY postvoucher.cmpy_code, ", 
	" postvoucher.vend_code, ", 
	" postvoucher.vouch_code " 
END IF 

PREPARE vouch_sel FROM modu_select_text 
DECLARE crs_postvoucher_ready_old CURSOR FOR vouch_sel 

LET glob_err_text = "FOREACH INTO posttemp - voucher"
 
FOREACH crs_postvoucher_ready_old INTO l_cmpy_code, 
	modu_rec_docdata.*, 
	modu_rec_current.vend_type 

	# determine the posting control accounts FOR this vendor type,
	# IF new vendor

	IF modu_rec_current.vend_type != modu_prev_vend_type OR 
	(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT NULL ) OR 
	(modu_rec_current.vend_type IS NOT NULL AND 
	modu_prev_vend_type IS NULL ) THEN 
		CALL get_vendortype_accounts(modu_rec_current.vend_type) 
		RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
	END IF 

	# create posting details FOR each distribution FOR
	# the selected vouchers


	DECLARE vd_curs_old CURSOR FOR 
	SELECT acct_code, 
	desc_text, 
	dist_qty, 
	analysis_text, 
	dist_amt, 
	0 
	FROM voucherdist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vouch_code = modu_rec_docdata.ref_num 
	AND vend_code = modu_rec_docdata.ref_text 



	FOREACH vd_curs_old INTO modu_rec_vouchedist_detldata.* 

		IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
			IF modu_rec_docdata.conv_qty != 0 THEN 
				LET modu_rec_current.base_debit_amt = modu_rec_vouchedist_detldata.debit_amt / 
				modu_rec_docdata.conv_qty 
			END IF 
		END IF 

		#IF use_currency_flag IS 'N' THEN any source documents in foreign
		#currency need TO be converted TO base, AND a base batch created.
		IF glob_rec_glparms.use_currency_flag = "N" THEN 
			LET modu_rec_vouchedist_detldata.debit_amt = modu_rec_current.base_debit_amt 
			LET modu_sv_conv_qty = 1 
			LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
		ELSE 
			LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
		END IF 

		INSERT INTO posttemp VALUES 
		(modu_rec_docdata.ref_num, # voucher number 
		modu_rec_docdata.ref_text, # vendor code 
		modu_rec_vouchedist_detldata.post_acct_code, # voucher dist account 
		modu_rec_vouchedist_detldata.desc_text, # voucher dist desc 
		modu_rec_vouchedist_detldata.debit_amt, # voucher dist amount 
		modu_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
		modu_rec_current.base_debit_amt, # converted debit amount 
		modu_rec_vouchedist_detldata.credit_amt, # zero FOR "VO" 
		modu_rec_docdata.currency_code, # voucher currency code 
		modu_sv_conv_qty, # voucher curr conversion 
		modu_rec_docdata.tran_date, # voucher DATE 
		modu_rec_vouchedist_detldata.stats_qty, # distribution qty 
		modu_rec_vouchedist_detldata.analysis_text, # analysis text 
		modu_rec_current.pay_acct_code, # control account 
		0) # doc num - n/a 
	END FOREACH 
END FOREACH 

LET modu_rec_bal_rec.tran_type_ind = "VO" 
LET modu_rec_bal_rec.desc_text = " AP Voucher Balancing Entry" 

IF modu_post_status = 2 THEN 
	LET glob_posted_journal = glob_rec_poststatus.jour_num 
ELSE 
	LET glob_posted_journal = NULL 
END IF 

--MESSAGE "" 
# 3502 " Posting vouchers..."
MESSAGE kandoomsg2("P",3502,"") 
--SLEEP 1 
CALL create_gl_batches() 
END IF 


LET glob_st_code = 3 
LET glob_post_text = "Commenced UPDATE jour_num FROM postvoucher" 
CALL update_poststatus(ALL_OK,0,"AP") 

IF modu_post_status != 4 THEN 
# UPDATE vendor history FOR cheques
	CALL update_vendorhist("V") 
	
# IF the UPDATE does crap out part way this IS NOT a problem
# we will re UPDATE next time through
	LET glob_err_text = "Update jour_code in postvoucher" 
	DECLARE update_jour_old CURSOR with HOLD FOR 
		SELECT * 
		FROM postvoucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	
	FOREACH update_jour_old INTO l_rec_voucher.* 
		IF NOT glob_one_trans THEN 
			BEGIN WORK 
			LET glob_in_trans = true 
		END IF 
	
		UPDATE voucher 
		SET jour_num = l_rec_voucher.jour_num, 
		post_date = today 
		WHERE cmpy_code = l_rec_voucher.cmpy_code 
		AND vouch_code = l_rec_voucher.vouch_code 
	
		IF NOT glob_one_trans THEN 
			COMMIT WORK 
			LET glob_in_trans = false 
		END IF 
	END FOREACH 
END IF 

LET glob_st_code = 4 
LET glob_post_text = "Commenced DELETE FROM postvoucher" 
CALL update_poststatus(ALL_OK,0,"AP") 

LET glob_err_text = "DELETE FROM postvoucher" 
IF NOT glob_one_trans THEN 
	BEGIN WORK 
	LET glob_in_trans = true 
END IF
 
IF glob_rec_poststatus.online_ind != "L" THEN 
	LOCK TABLE postvoucher in share MODE 
END IF 

DELETE FROM postvoucher WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
IF NOT glob_one_trans THEN 
	COMMIT WORK 
	LET glob_in_trans = false 
END IF 

LET glob_st_code = 99 
LET glob_post_text = "Voucher Posting Completed Correctly" 
CALL update_poststatus(ALL_OK,0,"AP") 

END FUNCTION #  post_vouchers_old() 

FUNCTION post_cheques_old(p_period_num,p_year_num) 
	DEFINE p_period_num LIKE batchhead.period_num
	DEFINE p_year_num LIKE batchhead.year_num
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cmpy_code LIKE company.cmpy_code 
	DEFINE l_pay_meth LIKE cheque.pay_meth_ind 
	DEFINE l_desc_text LIKE batchdetl.desc_text 
	DEFINE l_bank_code LIKE cheque.bank_code 
	DEFINE l_vend_code LIKE cheque.vend_code 
	DEFINE l_doc_num INTEGER 
	DEFINE l_sql_statement STRING
	DEFINE l_rec_cheque RECORD LIKE cheque.* 

	# IF an error has occurred AND it was NOT in this part of the
	# post THEN walk on by ...
	IF modu_post_status > 12 AND modu_post_status < 99 THEN 
		RETURN 
	END IF 
	IF crs_join_cheque_vendor.getStatement() IS NULL THEN    # prepare all cursors and sql stmts for this function
		LET l_sql_statement = "SELECT cheque.cheq_code, ",
		" cheque.bank_acct_code, ",
		" cheque.pay_meth_ind, ",
		" vendor.type_code, ",
		" cheque.vend_code ",
		" FROM cheque, vendor ",
		" WHERE cheque.cmpy_code = ? ",
		" AND cheque.cheq_code != 0 ",
		" AND cheque.cheq_code IS NOT NULL ",
		" AND cheque.post_flag = 'N' ", 
		" AND cheque.period_num = ? ", 
		" AND cheque.year_num = ? ", 
		" AND cheque.cmpy_code = vendor.cmpy_code ",
		" AND cheque.vend_code = vendor.vend_code "
		CALL crs_join_cheque_vendor.Declare(l_sql_statement)
		# glob_rec_kandoouser.cmpy_code 
		# glob_fisc_period
		# glob_fisc_year

		LET l_sql_statement = "INSERT INTO postcheque VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
	--	CALL prp_insert_postcheque.Prepare(l_sql_statement)

		LET l_sql_statement = "INSERT INTO postwhtax VALUES (?,?,?,?,?,?,?,?,?,?,?)"
	--	CALL prp_insert_postwhtax.Prepare(l_sql_statement)

		LET l_sql_statement = "INSERT INTO postaptrans VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) "
	--	CALL prp_insert_postaptrans.Prepare(l_sql_statement)

		LET l_sql_statement = "UPDATE cheque ",
		" SET post_flag = 'Y' ", 
		"WHERE vend_code = ? ",
		" AND cheq_code = ? ",
		" AND cmpy_code = ? "
	--	CALL prp_update_cheque_flag.Prepare(l_sql_statement)
	END IF

	LET glob_err_text = "Commenced cheque post" 
#	# the "rollback manual process" is useless, replaced by BEGIN WORK / COMMIT WORK ericv 20210216
{
	IF modu_post_status = 9 THEN # error in cheque post
		# ericv case not possible because we use transactions
		# 3519 "Rolling back postcheque AND cheque tables"
		ERROR kandoomsg("P",3519,"") 
		LET glob_err_text = "Reversing previous cheques" 

		LET glob_in_trans = true 
		DECLARE cheque_undo CURSOR FOR 
			SELECT cheq_code, 
			bank_acct_code, 
			pay_meth_ind, 
			bank_code, 
			vend_code 
			FROM postcheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 

		FOREACH cheque_undo INTO modu_cheq_code, 
			modu_bank_acct_code, 
			l_pay_meth, 
			l_bank_code, 
			l_vend_code 

			UPDATE cheque SET post_flag = "N" 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = modu_cheq_code 
			AND bank_acct_code = modu_bank_acct_code 
			AND pay_meth_ind = l_pay_meth 

			DELETE FROM postcheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheq_code = modu_cheq_code 
			AND bank_acct_code = modu_bank_acct_code 
			AND pay_meth_ind = l_pay_meth 

			DELETE FROM postwhtax 
			WHERE payee_ref_num = modu_cheq_code 
			AND payee_bank_code = l_bank_code 
			AND pay_meth_ind = l_pay_meth 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND payee_tran_type = "1" 

			DELETE FROM postaptrans 
			WHERE ref_num = modu_cheq_code 
			AND ref_code = l_vend_code 
			AND type_code = "CCO" # contra amount 
			AND bank_code = l_bank_code 
			AND pay_meth_ind = l_pay_meth 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		END FOREACH 

	END IF 
}
	LET glob_st_code = 9 
	LET glob_post_text = "Commenced INSERT TO postcheque AND postwhtax" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status <= 9 OR modu_post_status = 99 THEN 
		# SELECT the cheques FOR posting AND INSERT them INTO the postcheque
		# table THEN UPDATE them as posted so they won't be touched by anyone
		# ELSE

		LET glob_err_text = "Cheque SELECT FOR INSERT" 

		CALL crs_join_cheque_vendor.Open(glob_rec_kandoouser.cmpy_code,glob_fisc_period,glob_fisc_year) 
		LET modu_prev_vend_type = "z" 
		LET glob_err_text = "Cheques FOREACH FOR INSERT" 

		WHILE crs_join_cheque_vendor.FetchNext(modu_cheq_code,modu_bank_acct_code,l_pay_meth,modu_rec_current.vend_type,l_vend_code) = 0 
			# reselecting the check is a bit stupid but ...
			SELECT * INTO l_rec_cheque.*
			FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheq_code = modu_cheq_code 
				AND vend_code = l_vend_code

			IF sqlca.sqlcode = 0 THEN
				LET glob_err_text = "PP1 - Insert INTO postcheque" 
				CALL prp_insert_postcheque.Execute(l_rec_cheque.*) 
			END IF
			#
			#  Get all the applicable posting details in this first phase,
			#  including the balancing accounts
			#
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code 
			END IF 
			#
			# IF tax applicable, INSERT details INTO tax posting table
			#
			IF l_rec_cheque.withhold_tax_ind != "0" THEN 
				LET glob_err_text = "PP1 - Insert INTO postwhtax" 
				INITIALIZE modu_rec_postwhtax.* TO NULL 
				LET modu_rec_postwhtax.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_postwhtax.tax_vend_code = modu_rec_current.tax_vend_code 
				LET modu_rec_postwhtax.payee_tran_type = "1" 
				LET modu_rec_postwhtax.payee_vend_code = l_rec_cheque.vend_code 
				LET modu_rec_postwhtax.payee_ref_num = l_rec_cheque.cheq_code 
				LET modu_rec_postwhtax.payee_bank_code = l_rec_cheque.bank_code 
				LET modu_rec_postwhtax.tax_amt = l_rec_cheque.tax_amt 
				LET modu_rec_postwhtax.pay_acct_code = modu_rec_current.pay_acct_code 
				LET modu_rec_postwhtax.pay_meth_ind = l_rec_cheque.pay_meth_ind 
				CALL prp_insert_postwhtax.Execute(modu_rec_postwhtax.*)
			END IF 

			#
			# IF contra amounts exist, INSERT details INTO contra posting table
			#
			IF l_rec_cheque.contra_amt != 0 THEN 
				LET glob_err_text = "PP1 - Insert INTO postaptrans - CCO" 
				INITIALIZE modu_rec_postaptrans.* TO NULL 
	
				LET modu_rec_postaptrans.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET modu_rec_postaptrans.type_code = "CCO" # cheque contra 
				LET modu_rec_postaptrans.ref_num = l_rec_cheque.cheq_code 
				LET modu_rec_postaptrans.ref_code = l_rec_cheque.vend_code 
				LET modu_rec_postaptrans.doc_num = l_rec_cheque.doc_num 
				LET modu_rec_postaptrans.post_acct_code = glob_rec_glparms.clear_acct_code 
				LET modu_rec_postaptrans.bal_acct_code = modu_rec_current.pay_acct_code 
				LET modu_rec_postaptrans.desc_text = l_rec_cheque.pay_meth_ind, " ", 
					l_rec_cheque.cheq_code USING "<<<<<<<<<<" clipped, " contra ", 
					l_rec_cheque.contra_trans_num USING "<<<<<<<<<<" 
				LET modu_rec_postaptrans.debit_amt = 0 
				LET modu_rec_postaptrans.credit_amt = l_rec_cheque.contra_amt 
				LET modu_rec_postaptrans.currency_code = l_rec_cheque.currency_code 
				LET modu_rec_postaptrans.conv_qty = l_rec_cheque.conv_qty 
				LET modu_rec_postaptrans.tran_date = l_rec_cheque.cheq_date 
				LET modu_rec_postaptrans.year_num = l_rec_cheque.year_num 
				LET modu_rec_postaptrans.period_num = l_rec_cheque.period_num 
				LET modu_rec_postaptrans.post_status_num = 0 
				LET modu_rec_postaptrans.bank_code = l_rec_cheque.bank_code 
				LET modu_rec_postaptrans.pay_meth_ind = l_rec_cheque.pay_meth_ind 
				LET modu_rec_postaptrans.stats_qty = 0 
				CALL prp_insert_postaptrans.Execute(modu_rec_postaptrans.*) 
			END IF 

			LET glob_err_text = "PP1 - Cheque post flag SET" 
			CALL prp_update_cheque_flag.Execute(l_vend_code,modu_cheq_code,glob_rec_kandoouser.cmpy_code )
		END WHILE # crs_join_cheque_vendor
	END IF 

	LET glob_err_text = "Create gl batch - Cheques" 
	
	LET glob_st_code = 10 
	LET glob_post_text = "Completed INSERT TO postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status <= 10 OR modu_post_status = 99 THEN 
	
		LET modu_prev_vend_type = "z" 
		LET modu_rec_current.tran_type_ind = "CH" 
		LET modu_rec_current.base_debit_amt = 0 
		LET modu_rec_current.jour_code = glob_rec_apparms.pur_jour_code 

# INSERT posting data FOR the Cheque discount amount
# discounts posted in a separate batch TO cheque payments due TO
# differing journal codes
# SELECT only non-zero discounts FOR posting

		LET modu_select_text = 
		"SELECT C.cmpy_code, ", 
		"C.cheq_code, ", 
		"C.vend_code, ", 
		"C.cheq_date, ", 
		"C.currency_code, ", 
		"C.conv_qty, ", 
		"V.type_code, ", 
		"C.pay_meth_ind, ", 
		"' ', ", 
		"C.cheq_code, ", 
		"0, ", 
		"' ', ", 
		"0, ", 
		"C.disc_amt, ", 
		"C.doc_num ", 
		"FROM postcheque C, vendor V ", 
		"WHERE C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND C.post_flag = 'N' ", 
		"AND C.year_num = ",glob_fisc_year," ", 
		"AND C.period_num = ",glob_fisc_period," ", 
		"AND C.disc_amt IS NOT NULL ", 
		"AND C.disc_amt != 0 ", 
		"AND C.cmpy_code = V.cmpy_code ", 
		"AND C.vend_code = V.vend_code" 

		IF modu_post_status = 10 THEN {crapped out in post TO gl} 
			LET modu_select_text = modu_select_text clipped, 
			" AND (C.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"C.jour_num IS NULL OR C.jour_num = 0) ", 
			"ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		END IF 

		PREPARE cheq_sel FROM modu_select_text 
		DECLARE cd_curs_old CURSOR FOR cheq_sel 

		LET glob_err_text = "FOREACH FOR cheque discount" 

		FOREACH cd_curs_old INTO l_cmpy_code, 
			modu_rec_docdata.*, 
			modu_rec_current.vend_type, 
			l_pay_meth, 
			modu_rec_vouchedist_detldata.*, 
			l_doc_num 
		
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_vouchedist_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
		
			#IF use_currency_flag IS 'N' THEN any source documents in foreign
			#currency need TO be converted TO base, AND a base batch created.
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_vouchedist_detldata.credit_amt = modu_rec_current.base_credit_amt 
				LET modu_sv_conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		
			LET l_desc_text = NULL 
			LET l_desc_text = modu_rec_vouchedist_detldata.desc_text 
			LET modu_rec_vouchedist_detldata.desc_text = l_pay_meth, " ", l_desc_text 

			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # cheque number 
			modu_rec_docdata.ref_text, # vendor code 
			modu_rec_current.disc_acct_code, # discount control account 
			modu_rec_vouchedist_detldata.desc_text, # cheque number 
			modu_rec_vouchedist_detldata.debit_amt, # zero FOR cheque discounts 
			modu_rec_vouchedist_detldata.credit_amt, # cheque discount amount 
			modu_rec_current.base_debit_amt, # zero FOR cheque discounts 
			modu_rec_current.base_credit_amt, # converted discount amount 
			modu_rec_docdata.currency_code, # cheque currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # cheque DATE 
			modu_rec_vouchedist_detldata.stats_qty, # defaulted TO 0 - NOT impl'ted 
			modu_rec_vouchedist_detldata.analysis_text, # defaulted TO - NOT impl'ted 
			modu_rec_current.pay_acct_code, # control account 
			l_doc_num) # unique cheque doc num 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "CH" 
		LET modu_rec_bal_rec.desc_text = " AP Cheque Discount Balancing Entry" 
		
		IF modu_post_status = 10 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

--MESSAGE "" 
# 3505 " Posting cheque disc..."
		MESSAGE kandoomsg2("P",3505,"") 
		SLEEP 1 
		CALL create_gl_batches() 

		DELETE FROM posttemp WHERE 1 = 1 

# INSERT posting data FOR the Cheque payment amounts

		LET modu_select_text = 
		"SELECT C.cmpy_code, ", 
		"C.cheq_code, ", 
		"C.vend_code, ", 
		"C.cheq_date, ", 
		"C.currency_code, ", 
		"C.conv_qty, ", 
		"V.type_code, ", 
		"C.pay_meth_ind, ", 
		"C.bank_acct_code, ", 
		"C.cheq_code, ", 
		"0, ", 
		"' ', ", 
		"0, ", 
		"C.net_pay_amt, ", 
		"C.doc_num ", 
		"FROM postcheque C, vendor V ", 
		"WHERE C.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND C.post_flag = 'N' ", 
		"AND C.year_num = ",glob_fisc_year," ", 
		"AND C.period_num = ",glob_fisc_period," ", 
		"AND C.cmpy_code = V.cmpy_code ", 
		"AND C.vend_code = V.vend_code "
 
		IF modu_post_status = 10 THEN 
			LET modu_select_text = modu_select_text clipped, 
			" AND (C.jour_num = ",glob_rec_poststatus.jour_num," OR ", 
			"C.jour_num IS NULL OR C.jour_num = 0) ", 
			"ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		ELSE 
			LET modu_select_text = modu_select_text clipped, 
			" ORDER BY C.cmpy_code, C.vend_code, C.cheq_code " 
		END IF 

		PREPARE ch_sel FROM modu_select_text 
		DECLARE ch_curs_old CURSOR FOR ch_sel 
		
		LET glob_err_text = "FOREACH FOR cheques" 

		FOREACH ch_curs_old INTO l_cmpy_code, 
			modu_rec_docdata.*, 
			modu_rec_current.vend_type, 
			l_pay_meth, 
			modu_rec_vouchedist_detldata.*, 
			l_doc_num 
		
			IF modu_rec_current.vend_type != modu_prev_vend_type OR 
			(modu_rec_current.vend_type IS NULL AND modu_prev_vend_type IS NOT null) OR 
			(modu_rec_current.vend_type IS NOT NULL AND modu_prev_vend_type IS null) THEN 
				CALL get_vendortype_accounts(modu_rec_current.vend_type) 
				RETURNING modu_rec_current.pay_acct_code,modu_rec_current.disc_acct_code,modu_rec_current.exch_acct_code,modu_rec_current.tax_vend_code
			END IF 
		
			IF modu_rec_docdata.conv_qty IS NOT NULL THEN 
				IF modu_rec_docdata.conv_qty != 0 THEN 
					LET modu_rec_current.base_credit_amt = modu_rec_vouchedist_detldata.credit_amt / 
					modu_rec_docdata.conv_qty 
				END IF 
			END IF 
		
			IF glob_rec_glparms.use_currency_flag = "N" THEN 
				LET modu_rec_vouchedist_detldata.credit_amt = modu_rec_current.base_credit_amt 
				LET modu_sv_conv_qty = 1 
				LET modu_rec_docdata.currency_code = glob_rec_glparms.base_currency_code 
			ELSE 
				LET modu_sv_conv_qty = modu_rec_docdata.conv_qty 
			END IF 
		
			LET l_desc_text = NULL 
			LET l_desc_text = modu_rec_vouchedist_detldata.desc_text 
			LET modu_rec_vouchedist_detldata.desc_text = l_pay_meth, " ", l_desc_text 
			
			INSERT INTO posttemp VALUES 
			(modu_rec_docdata.ref_num, # cheque number 
			modu_rec_docdata.ref_text, # vendor code 
			modu_rec_vouchedist_detldata.post_acct_code, # cheque bank gl account 
			modu_rec_vouchedist_detldata.desc_text, # cheque number 
			modu_rec_vouchedist_detldata.debit_amt, # zero FOR "CH" 
			modu_rec_vouchedist_detldata.credit_amt, # cheque net payment amount 
			modu_rec_current.base_debit_amt, # zero FOR "CH" 
			modu_rec_current.base_credit_amt, # converted payment amount 
			modu_rec_docdata.currency_code, # cheque currency code 
			modu_sv_conv_qty, 
			modu_rec_docdata.tran_date, # cheque DATE 
			modu_rec_vouchedist_detldata.stats_qty, # defaulted TO 0 - NOT impl'ted 
			modu_rec_vouchedist_detldata.analysis_text, # defaulted TO - NOT impl'ted 
			modu_rec_current.pay_acct_code, # control account 
			l_doc_num) # unique cheque doc num 
		END FOREACH 

		LET modu_rec_bal_rec.tran_type_ind = "CH" 
		LET modu_rec_bal_rec.desc_text = " AP Cheques Balancing Entry" 
		LET modu_rec_current.jour_code = glob_rec_apparms.chq_jour_code 
		
		LET modu_flag_cheques = true 
		
		IF modu_post_status = 10 THEN 
			LET glob_posted_journal = glob_rec_poststatus.jour_num 
		ELSE 
			LET glob_posted_journal = NULL 
		END IF 

		MESSAGE "" 
# 3504 " Posting cheques..."
		MESSAGE kandoomsg2("P",3504,"") 
--		SLEEP 1 
		CALL create_gl_batches() 
	
	END IF 

	LET glob_st_code = 11 
	LET glob_post_text = "Commenced UPDATE jour_num FROM postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	IF modu_post_status != 12 THEN 
# UPDATE vendor history FOR cheques
		CALL update_vendorhist("C") 

# IF the UPDATE does crap out part way this IS NOT a problem
# we will re UPDATE next time through
		LET glob_err_text = "Update jour_code in postcheque" 
		DECLARE update_jour1_old CURSOR with HOLD FOR 
			SELECT * 
			FROM postcheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

		FOREACH update_jour1_old INTO l_rec_cheque.* 
			IF NOT glob_one_trans THEN 
				BEGIN WORK 
				LET glob_in_trans = true 
			END IF 
			UPDATE cheque 
			SET jour_num = l_rec_cheque.jour_num, 
			post_date = today 
			WHERE cmpy_code = l_rec_cheque.cmpy_code 
			AND cheq_code = l_rec_cheque.cheq_code 
			AND vend_code = l_rec_cheque.vend_code 
			AND bank_acct_code = l_rec_cheque.bank_acct_code 
			AND pay_meth_ind = l_rec_cheque.pay_meth_ind 
			IF NOT glob_one_trans THEN 
				COMMIT WORK 
				LET glob_in_trans = false 
			END IF 
		END FOREACH 
	END IF 

	LET glob_st_code = 12 
	LET glob_post_text = "Commenced DELETE FROM postcheque" 
	CALL update_poststatus(ALL_OK,0,"AP") 

	LET glob_err_text = "DELETE FROM postcheque" 
--	IF NOT glob_one_trans THEN 
--		BEGIN WORK 
--		LET glob_in_trans = true 
--	END IF 
--	IF glob_rec_poststatus.online_ind != "L" THEN 
--		LOCK TABLE postcheque in share MODE 
--	END IF 
	DELETE FROM postcheque WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
--	IF NOT glob_one_trans THEN 
--		COMMIT WORK 
--		LET glob_in_trans = false 
--	END IF 

	LET glob_st_code = 99 
	LET glob_post_text = "Cheque Posting Completed Correctly" 
	CALL update_poststatus(ALL_OK,0,"AP") 
	RETURN 0

END FUNCTION  # post_cheques_old
