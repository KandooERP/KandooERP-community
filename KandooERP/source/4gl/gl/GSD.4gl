{
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

	Source code beautified by beautify.pl on 2020-01-03 14:28:52	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module GSD  Rolls up account history FROM the account ledger
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
END GLOBALS 

############################################################
# MODULE Scope Variables
############################################################

DEFINE modu_rec_coa RECORD LIKE coa.*
DEFINE modu_rec_period RECORD LIKE period.*
DEFINE modu_rec_accounthist RECORD LIKE accounthist.*
DEFINE modu_rec_accounthistcur RECORD LIKE accounthistcur.*
DEFINE modu_query_text CHAR(1200) ### its large but all needed, believe it!! 
DEFINE modu_seg_text CHAR(500)
DEFINE modu_hold_acct LIKE accounthist.acct_code
DEFINE modu_acct_code LIKE accounthist.acct_code

DEFINE modu_period_num LIKE accounthist.period_num
DEFINE modu_cmpy_code LIKE accounthist.cmpy_code
DEFINE modu_sumdeb LIKE accounthist.debit_amt
DEFINE modu_sumcred LIKE accounthist.debit_amt

DEFINE modu_sumstats LIKE accounthist.stats_qty

DEFINE modu_prev_currency LIKE accountledger.currency_code
DEFINE modu_currency_code LIKE accountledger.currency_code

DEFINE modu_sum_base_dr LIKE accounthistcur.debit_amt
DEFINE modu_sum_base_cr LIKE accounthistcur.debit_amt

--	DEFINE modu_sum_rept_dr LIKE accounthistcur.debit_amt
--	DEFINE modu_sum_rept_cr LIKE accounthistcur.debit_amt

DEFINE modu_ah_rowid INTEGER
DEFINE modu_i INTEGER
DEFINE modu_counter INTEGER

DEFINE modu_fisc_year SMALLINT 
DEFINE modu_tm_per SMALLINT 

DEFINE modu_err_message CHAR (40) 


############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	CALL setModuleId("GSD") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",5107,"") 
		#5107 " General Ledger parameters NOT found, see menu GZP"
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g208 with FORM "G208" 
	CALL windecoration_g("G208") 

	LET l_msgresp = kandoomsg("G",1070,"") 
	#1070 Enter Year; OK TO Continue.
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, today) 
	RETURNING modu_fisc_year,modu_tm_per 
	DISPLAY modu_fisc_year TO curr_year_num 

	WHILE get_info() 
		CALL update_them() 
	END WHILE
	 
	CLOSE WINDOW g208
	 
END MAIN 


############################################################
# FUNCTION get_info() 
#
#
############################################################
FUNCTION get_info() 
	DEFINE l_msgresp LIKE language.yes_flag 

	WHILE true 

		INPUT BY NAME modu_rec_period.year_num 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GSD","inp-period") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END INPUT 

		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF
		 
		SELECT * INTO modu_rec_period.* FROM period 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = modu_rec_period.year_num 
		AND period_num = 1
		 
		IF status = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("U",9020,"") 
			#9020 Fiscal Year NOT SET up
		ELSE 
			CALL segment_con(glob_rec_kandoouser.cmpy_code,"account") 
			RETURNING modu_seg_text 
			IF modu_seg_text IS NULL THEN 
				CONTINUE WHILE 
			END IF 
			EXIT WHILE 
		END IF
		 
	END WHILE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET modu_fisc_year = modu_rec_period.year_num 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION update_them()
#
#
############################################################
FUNCTION update_them() 
	DEFINE l_try_again CHAR(1) 
	DEFINE i SMALLINT
	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover (modu_err_message, status) 
	IF l_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK
	 
		LOCK TABLE account in share MODE 
		LOCK TABLE accounthist in share MODE 
		LOCK TABLE accounthistcur in share MODE 
		LET modu_query_text = 
		"SELECT accountledger.cmpy_code,", 
		"account.acct_code,", 
		"accountledger.period_num,", 
		"sum(accountledger.stats_qty),", 
		"sum(accountledger.debit_amt),", 
		"sum(accountledger.credit_amt) ", 
		"FROM account,", 
		"outer accountledger ", 
		"WHERE account.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND account.cmpy_code = accountledger.cmpy_code ", 
		"AND account.acct_code = accountledger.acct_code ", 
		"AND account.year_num = accountledger.year_num ", 
		"AND account.year_num = \"",modu_fisc_year,"\" ", 
		modu_seg_text clipped," ", 
		"group by accountledger.cmpy_code,", 
		"account.acct_code,", 
		"accountledger.period_num"
		 
		PREPARE s_account FROM modu_query_text 
		DECLARE c_account CURSOR FOR s_account 
		LET modu_hold_acct = " " 

		OPEN WINDOW w1 with FORM "U999" attributes(BORDER) 
		CALL windecoration_u("U999") 

		DISPLAY "Processing Account..." at 1,2
		 
		FOREACH c_account INTO modu_cmpy_code, 
			modu_acct_code, 
			modu_period_num, 
			modu_sumstats, 
			modu_sumdeb, 
			modu_sumcred 
			IF (modu_acct_code <> modu_hold_acct) OR 
			(modu_cmpy_code IS null) THEN 
				LET modu_hold_acct = modu_acct_code 
				CALL add_hist() 
			END IF 
			IF modu_cmpy_code IS NOT NULL THEN 
				IF modu_sumstats IS NULL THEN LET modu_sumstats = 0 END IF 
					IF modu_sumcred IS NULL THEN LET modu_sumcred = 0 END IF 
						IF modu_sumdeb IS NULL THEN LET modu_sumdeb = 0 END IF 
							CALL do_updating() 
						END IF 
					END FOREACH
					 
					CALL check_hist () 
					# Now roll up all the ledger details by currency code
					# INTO the currency history table
					IF glob_rec_glparms.use_currency_flag = "Y" THEN 
						FOR i = 1 TO 494 
							IF modu_seg_text[i,i+6] = "account" THEN 
								LET modu_seg_text = 
								modu_seg_text[1,i-1],"accountcur",modu_seg_text[i+7,500] clipped 
							END IF 
						END FOR 
						CALL roll_curr_ledger() 
						CLEAR WINDOW w1 
					END IF 
				COMMIT WORK 
				WHENEVER ERROR stop 
				DISPLAY "Total Accounts Processed: ",modu_counter at 1,22 
				SLEEP 3 
				CLOSE WINDOW w1
				 
END FUNCTION 


############################################################
# FUNCTION add_hist() 
#
#
############################################################
FUNCTION add_hist() 

	# OK some dont exist, lets put those in
	DECLARE hist_curs CURSOR FOR 
	SELECT period.* INTO modu_rec_period.* FROM period 
	WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period.year_num = modu_fisc_year 
	AND NOT exists (SELECT * FROM accounthist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = period.period_num) 
	LET modu_rec_accounthist.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_accounthist.acct_code = modu_acct_code 
	LET modu_rec_accounthist.year_num = modu_fisc_year 
	LET modu_rec_accounthist.open_amt = 0 
	LET modu_rec_accounthist.debit_amt = 0 
	LET modu_rec_accounthist.credit_amt = 0 
	LET modu_rec_accounthist.close_amt = 0 
	LET modu_rec_accounthist.pre_close_amt = 0 
	LET modu_rec_accounthist.budg1_amt = 0 
	LET modu_rec_accounthist.budg2_amt = 0 
	LET modu_rec_accounthist.budg3_amt = 0 
	LET modu_rec_accounthist.budg4_amt = 0 
	LET modu_rec_accounthist.budg5_amt = 0 
	LET modu_rec_accounthist.budg6_amt = 0 
	LET modu_rec_accounthist.stats_qty = 0 
	LET modu_rec_accounthist.ytd_pre_close_amt = 0 
	LET modu_rec_accounthist.hist_flag = "N" 
	LET modu_err_message = "History INSERT: ", modu_rec_accounthist.acct_code
	 
	FOREACH hist_curs 
		LET modu_rec_accounthist.period_num = modu_rec_period.period_num 
		INSERT INTO accounthist VALUES (modu_rec_accounthist.*) 
	END FOREACH
	 
	SELECT rowid, * 
	INTO modu_ah_rowid, modu_rec_accounthist.* 
	FROM accounthist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_period_num
	 
END FUNCTION 


############################################################
# FUNCTION add_curr_hist()  
#
#
############################################################
FUNCTION add_curr_hist() 
	# Ensure a history row exists FOR each defined period FOR
	# this account/currency combination
	DECLARE curr_hist_curs CURSOR FOR 
	SELECT period.* INTO modu_rec_period.* FROM period 
	WHERE period.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND period.year_num = modu_fisc_year 
	AND NOT exists (SELECT * FROM accounthistcur 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = period.period_num 
	AND currency_code = modu_currency_code) 
	LET modu_rec_accounthistcur.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET modu_rec_accounthistcur.acct_code = modu_acct_code 
	LET modu_rec_accounthistcur.year_num = modu_fisc_year 
	LET modu_rec_accounthistcur.currency_code = modu_currency_code 
	LET modu_rec_accounthistcur.open_amt = 0 
	LET modu_rec_accounthistcur.debit_amt = 0 
	LET modu_rec_accounthistcur.credit_amt = 0 
	LET modu_rec_accounthistcur.close_amt = 0 
	LET modu_rec_accounthistcur.pre_close_amt = 0 
	LET modu_rec_accounthist.ytd_pre_close_amt = 0 
	LET modu_rec_accounthistcur.base_open_amt = 0 
	LET modu_rec_accounthistcur.base_debit_amt = 0 
	LET modu_rec_accounthistcur.base_credit_amt = 0 
	LET modu_rec_accounthistcur.base_close_amt = 0 
	LET modu_err_message = " Curr History INSERT: ", modu_rec_accounthist.acct_code
	 
	FOREACH curr_hist_curs 
		LET modu_rec_accounthistcur.period_num = modu_rec_period.period_num 
		INSERT INTO accounthistcur 
		VALUES (modu_rec_accounthistcur.*) 
	END FOREACH
	 
	SELECT rowid, * 
	INTO modu_ah_rowid, modu_rec_accounthistcur.* 
	FROM accounthistcur 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_period_num 
	AND currency_code = modu_currency_code
	 
END FUNCTION 


############################################################
# FUNCTION check_hist ()  
#
#
############################################################
FUNCTION check_hist () 
	#
	# FOR each account history period FOR the year that has no matching
	# accountledger row SET the account history VALUES TO zero except FOR budgets.
	#
	DECLARE no_ledger CURSOR FOR 
	SELECT rowid, * INTO modu_ah_rowid, modu_rec_accounthist.* FROM accounthist h 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_fisc_year 
	AND NOT exists (SELECT * FROM accountledger l 
	WHERE l.cmpy_code = h.cmpy_code 
	AND l.acct_code = h.acct_code 
	AND l.year_num = h.year_num 
	AND l.period_num = h.period_num)
	 
	FOREACH no_ledger 
		LET modu_rec_accounthist.open_amt = 0 
		LET modu_rec_accounthist.debit_amt = 0 
		LET modu_rec_accounthist.credit_amt = 0 
		LET modu_rec_accounthist.close_amt = 0 
		LET modu_rec_accounthist.pre_close_amt = 0 
		LET modu_rec_accounthist.stats_qty = 0 
		LET modu_rec_accounthist.ytd_pre_close_amt = 0 
		LET modu_rec_accounthist.hist_flag = "N" 
		LET modu_err_message = "History UPDATE: ",modu_rec_accounthist.acct_code 
		UPDATE accounthist 
		SET * = modu_rec_accounthist.* 
		WHERE rowid = modu_ah_rowid 
	END FOREACH
	 
END FUNCTION # check_hist () 


############################################################
# FUNCTION check_curr_hist()   
#
#
############################################################
FUNCTION check_curr_hist() 
	#
	# FOR each account currency history period FOR the year that has no
	# matching accountledger row, SET the account currency history VALUES
	# TO zero except FOR budgets.
	#
	DECLARE no_curr_ledger CURSOR FOR 
	SELECT rowid, * INTO modu_ah_rowid, modu_rec_accounthistcur.* FROM accounthistcur h 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = modu_fisc_year 
	AND NOT exists (SELECT * FROM accountledger l 
	WHERE l.cmpy_code = h.cmpy_code 
	AND l.acct_code = h.acct_code 
	AND l.year_num = h.year_num 
	AND l.period_num = h.period_num 
	AND l.currency_code = h.currency_code) 

	FOREACH no_curr_ledger 
		LET modu_rec_accounthistcur.open_amt = 0 
		LET modu_rec_accounthistcur.debit_amt = 0 
		LET modu_rec_accounthistcur.credit_amt = 0 
		LET modu_rec_accounthistcur.close_amt = 0 
		LET modu_rec_accounthistcur.base_open_amt = 0 
		LET modu_rec_accounthistcur.base_debit_amt = 0 
		LET modu_rec_accounthistcur.base_credit_amt = 0 
		LET modu_rec_accounthistcur.base_close_amt = 0 
		LET modu_rec_accounthistcur.pre_close_amt = 0 
		LET modu_rec_accounthistcur.ytd_pre_close_amt = 0 
		LET modu_err_message = "History UPDATE: ", modu_rec_accounthist.acct_code 

		UPDATE accounthistcur 
		SET * = modu_rec_accounthistcur.* 
		WHERE rowid = modu_ah_rowid 
	END FOREACH 

END FUNCTION 


############################################################
# FUNCTION do_updating()  
#
#
############################################################
FUNCTION do_updating() 
	DEFINE l_msgresp LIKE language.yes_flag 

	DISPLAY modu_acct_code at 1,22 

	SELECT * INTO modu_rec_coa.* FROM coa 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",7004,modu_acct_code) 
		#7004 "General Ledger account NOT found"
		EXIT PROGRAM 
	END IF 

	SELECT rowid, * INTO modu_ah_rowid, modu_rec_accounthist.* FROM accounthist 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_period_num 
	# This FUNCTION should NOT need TO be called FROM here as all accounts are
	#    checked TO ensure that all the accounthist records are present FOR all
	#    established periods
	IF status = NOTFOUND THEN 
		CALL add_hist () 
	END IF
	 
	LET modu_rec_accounthist.stats_qty = modu_sumstats 
	LET modu_rec_accounthist.debit_amt = modu_sumdeb 
	LET modu_rec_accounthist.credit_amt = modu_sumcred 
	LET modu_rec_accounthist.close_amt = modu_rec_accounthist.open_amt + modu_sumdeb - modu_sumcred
	 
	SELECT sum(debit_amt),sum(credit_amt),sum(stats_qty) 
	INTO modu_sumdeb, modu_sumcred, modu_sumstats 
	FROM accountledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	acct_code = modu_acct_code AND 
	year_num = modu_fisc_year AND 
	period_num = modu_period_num AND 
	tran_type_ind != "CL" 
	IF modu_sumstats IS NULL THEN LET modu_sumstats = 0 END IF 
		IF modu_sumcred IS NULL THEN LET modu_sumcred = 0 END IF 
			IF modu_sumdeb IS NULL THEN LET modu_sumdeb = 0 END IF 
				LET modu_rec_accounthist.pre_close_amt = modu_sumdeb - modu_sumcred 
				UPDATE accounthist 
				SET * = modu_rec_accounthist.* 
				WHERE rowid = modu_ah_rowid 
				LET modu_counter = modu_counter + 1 
END FUNCTION 


############################################################
# FUNCTION roll_curr_ledger() 
#
#
############################################################
FUNCTION roll_curr_ledger()
 
	DISPLAY " Updating multi-currency ledger..." at 1,2 
	LET modu_query_text = 
	"SELECT accountledger.cmpy_code,", 
	"accountcur.acct_code,", 
	"accountcur.currency_code,", 
	"accountledger.period_num,", 
	"sum(accountledger.debit_amt),", 
	"sum(accountledger.credit_amt),", 
	"sum(accountledger.for_debit_amt),", 
	"sum(accountledger.for_credit_amt) ", 
	"FROM accountcur accountcur,", 
	"outer accountledger accountledger ", 
	"WHERE accountcur.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND accountcur.year_num = \"",modu_fisc_year,"\" ", 
	"AND accountcur.cmpy_code = accountledger.cmpy_code ", 
	"AND accountcur.acct_code = accountledger.acct_code ", 
	"AND accountcur.year_num = accountledger.year_num ", 
	"AND accountcur.currency_code = accountledger.currency_code ", 
	modu_seg_text clipped," ", 
	"group by accountledger.cmpy_code,", 
	"accountcur.acct_code,", 
	"accountcur.currency_code,", 
	"accountledger.period_num ", 
	"ORDER BY accountcur.acct_code,", 
	"accountcur.currency_code,", 
	"accountledger.period_num" 
	PREPARE s_acctcur FROM modu_query_text 
	DECLARE c_acctcur CURSOR FOR s_acctcur 
	LET modu_hold_acct = " " 
	LET modu_prev_currency = " " 
	FOREACH c_acctcur INTO modu_cmpy_code, 
		modu_acct_code, 
		modu_currency_code, 
		modu_period_num, 
		modu_sum_base_dr, 
		modu_sum_base_cr, 
		modu_sumdeb, 
		modu_sumcred
		 
		IF (modu_acct_code != modu_hold_acct) OR 
		(modu_currency_code != modu_prev_currency) OR 
		(modu_cmpy_code IS null) THEN 
			LET modu_hold_acct = modu_acct_code 
			LET modu_prev_currency = modu_currency_code 
			CALL add_curr_hist() 
		END IF
		 
		# IF the company code IS NOT NULL, ledger entries must exist
		# FOR this account/currency/period
		IF modu_cmpy_code IS NOT NULL THEN 
			CALL update_curr_hist() 
		END IF 
	END FOREACH
	 
	CALL check_curr_hist()
	 
END FUNCTION 


############################################################
# FUNCTION update_curr_hist()  
#
#
############################################################
FUNCTION update_curr_hist() 
	DISPLAY "" at 1,2 
	DISPLAY "Account: ",modu_acct_code, " Currency: ", modu_currency_code at 1,2
	 
	SELECT rowid, * 
	INTO modu_ah_rowid, modu_rec_accounthistcur.* 
	FROM accounthistcur 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_period_num 
	AND currency_code = modu_currency_code 
	# This FUNCTION should NOT need TO be called FROM here as all
	# accounts are checked TO ensure that all the accounthistcur
	# records are present FOR all established periods
	IF status = NOTFOUND THEN 
		CALL add_curr_hist() 
	END IF 
	LET modu_rec_accounthistcur.debit_amt = modu_sumdeb 
	LET modu_rec_accounthistcur.credit_amt = modu_sumcred 
	LET modu_rec_accounthistcur.base_debit_amt = modu_sum_base_dr 
	LET modu_rec_accounthistcur.base_credit_amt = modu_sum_base_cr 
	LET modu_rec_accounthistcur.close_amt = modu_rec_accounthistcur.open_amt + modu_sumdeb - modu_sumcred 
	LET modu_rec_accounthistcur.base_close_amt = modu_rec_accounthistcur.base_open_amt + modu_sum_base_dr - modu_sum_base_cr
	 
	SELECT sum(for_debit_amt), 
	sum(for_credit_amt) 
	INTO modu_sumdeb, 
	modu_sumcred 
	FROM accountledger 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND acct_code = modu_acct_code 
	AND year_num = modu_fisc_year 
	AND period_num = modu_period_num 
	AND currency_code = modu_currency_code 
	AND tran_type_ind != "CL" 
	IF modu_sumcred IS NULL THEN LET modu_sumcred = 0 END IF 
	IF modu_sumdeb IS NULL THEN LET modu_sumdeb = 0 END IF 

	LET modu_rec_accounthistcur.pre_close_amt = modu_sumdeb - modu_sumcred 
	UPDATE accounthistcur 
	SET * = modu_rec_accounthistcur.* 
	WHERE rowid = modu_ah_rowid 
	LET modu_counter = modu_counter + 1 

END FUNCTION